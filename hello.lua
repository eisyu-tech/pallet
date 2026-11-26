-- PalletStudio (LocalScript): StarterPlayer > StarterPlayerScripts に入れる (これ1個だけで動く)
-- 検出: Workspace の「<自分の@ID(ユーザー名)>SpawnedInToys」フォルダの直下にある PalletLightBrown だけを「板1, 板2…」として出す。
--       他のフォルダ・他プレイヤーのフォルダの板は見ない。フォルダの自動作成はしない (サーバー側も同じ条件の板しか受け付けない)。
-- 起動時に必ず、サーバー用コードを CodeLoader (ServerScriptService) へ送る。サーバー側が無ければ、この画面だけに直接反映する。
-- タブ: ホーム / 色(単色・2〜3色グラデ・流れるグラデ) / 素材 / プリセット(見た目一式・おまかせ・他の板へコピー) / 質感(反射・ツヤ) / 光(明滅の種類) / 効果(レインボー・炎・煙・雪・桜・ほたる・あわ・火の粉) / その他(視野・軽量化・UI設定)
-- 反射・ツヤは、素材やテクスチャを変えずに、光の帯と空の映り込みを重ねて出す。明滅・レインボー・グラデの流れは、この画面で毎フレームなめらかに動く。
-- 📌 永久保存: 押すと保存、もう一度押すと解除。保存中は、これから出す板に自動でまとめて反映する。
-- 板を切り替えた時は、スライダー/トグルの表示だけを初期位置へ戻す(板そのものは「元に戻す」ボタンの時だけ戻る)。
-- 起動時、右下に make by aino の演出が出て、終わると開閉ボタンが現れる。

local RS_ = game:GetService("ReplicatedStorage")
local SERVER_CODE = [=====[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- この Roblox に存在しない素材名は黙って飛ばす (新しい素材は古い版に無いことがあるため)
local function hasMat(n) return (pcall(function() return Enum.Material[n] end)) end
local MATERIAL_SET = {}
for _, n in ipairs({ "Plastic", "SmoothPlastic", "Wood", "WoodPlanks", "Metal", "DiamondPlate", "Foil", "Neon", "Glass", "Ice", "Marble", "Granite", "Slate", "Concrete", "Brick", "Cobblestone", "Sand", "Fabric", "ForceField",
	"Glacier", "Snow", "Mud", "Rubber", "Leather", "Plaster", "CeramicTiles", "Carpet", "Cardboard", "Basalt", "Pebble", "Limestone", "Sandstone", "CorrodedMetal", "CrackedLava" }) do
	if hasMat(n) then MATERIAL_SET[n] = true end
end

local PRESETS = {
	NeonBlue = { Color = Color3.fromRGB(56, 189, 248), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	NeonPink = { Color = Color3.fromRGB(255, 70, 190), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	NeonGreen = { Color = Color3.fromRGB(60, 255, 130), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	Sunset = { Color = Color3.fromRGB(255, 120, 40), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 1.5, Range = 12 },
	Gold = { Color = Color3.fromRGB(255, 200, 60), Material = "Metal", Reflectance = 0.35, Transparency = 0, Glow = 0, Range = 10 },
	Silver = { Color = Color3.fromRGB(200, 205, 215), Material = "Metal", Reflectance = 0.45, Transparency = 0, Glow = 0, Range = 10 },
	Ice = { Color = Color3.fromRGB(175, 225, 255), Material = "Ice", Reflectance = 0.2, Transparency = 0.3, Glow = 0, Range = 10 },
	Glass = { Color = Color3.fromRGB(200, 235, 255), Material = "Glass", Reflectance = 0.1, Transparency = 0.5, Glow = 0, Range = 10 },
	Marble = { Color = Color3.fromRGB(235, 235, 240), Material = "Marble", Reflectance = 0.15, Transparency = 0, Glow = 0, Range = 10 },
	Lava = { Color = Color3.fromRGB(255, 90, 20), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2.5, Range = 16 },
	Obsidian = { Color = Color3.fromRGB(20, 18, 28), Material = "Glass", Reflectance = 0.3, Transparency = 0, Glow = 0, Range = 10 },
	Candy = { Color = Color3.fromRGB(255, 150, 200), Material = "SmoothPlastic", Reflectance = 0.1, Transparency = 0, Glow = 0, Range = 10 },
	Forest = { Color = Color3.fromRGB(50, 130, 60), Material = "Fabric", Reflectance = 0, Transparency = 0, Glow = 0, Range = 10 },
	Ghost = { Color = Color3.fromRGB(230, 240, 255), Material = "ForceField", Reflectance = 0, Transparency = 0.2, Glow = 1, Range = 12 },
	Sakura = { Color = Color3.fromRGB(255, 183, 205), Material = "SmoothPlastic", Reflectance = 0.05, Transparency = 0, Glow = 0.6, Range = 10 },
	Toxic = { Color = Color3.fromRGB(170, 255, 0), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	Royal = { Color = Color3.fromRGB(88, 60, 200), Material = "Glass", Reflectance = 0.25, Transparency = 0.15, Glow = 1, Range = 12 },
	RoseGold = { Color = Color3.fromRGB(236, 160, 150), Material = "Metal", Reflectance = 0.4, Transparency = 0, Glow = 0, Range = 10 },
}

local LOOKS = {
	Plastic = { Color3.fromRGB(70, 130, 230), "Plastic", 0, 0, 0 },
	SmoothPlastic = { Color3.fromRGB(245, 245, 250), "SmoothPlastic", 0.05, 0, 0 },
	Wood = { Color3.fromRGB(150, 100, 60), "Wood", 0, 0, 0 },
	WoodPlanks = { Color3.fromRGB(190, 140, 85), "WoodPlanks", 0, 0, 0 },
	Metal = { Color3.fromRGB(150, 158, 170), "Metal", 0.32, 0, 0 },
	DiamondPlate = { Color3.fromRGB(120, 125, 135), "DiamondPlate", 0.2, 0, 0 },
	Foil = { Color3.fromRGB(215, 220, 230), "Foil", 0.5, 0, 0 },
	Neon = { Color3.fromRGB(60, 255, 200), "Neon", 0, 0, 1.5 },
	Glass = { Color3.fromRGB(190, 225, 240), "Glass", 0.1, 0.45, 0 },
	Ice = { Color3.fromRGB(170, 220, 255), "Ice", 0.15, 0.25, 0 },
	Marble = { Color3.fromRGB(236, 236, 240), "Marble", 0.12, 0, 0 },
	Granite = { Color3.fromRGB(125, 120, 118), "Granite", 0, 0, 0 },
	Slate = { Color3.fromRGB(75, 82, 95), "Slate", 0, 0, 0 },
	Concrete = { Color3.fromRGB(160, 160, 158), "Concrete", 0, 0, 0 },
	Brick = { Color3.fromRGB(170, 70, 55), "Brick", 0, 0, 0 },
	Cobblestone = { Color3.fromRGB(130, 125, 120), "Cobblestone", 0, 0, 0 },
	Sand = { Color3.fromRGB(225, 200, 140), "Sand", 0, 0, 0 },
	Fabric = { Color3.fromRGB(90, 120, 200), "Fabric", 0, 0, 0 },
	ForceField = { Color3.fromRGB(120, 200, 255), "ForceField", 0, 0.2, 1 },
}
-- 追加の素材 (存在するものだけ)。{ 色, 素材名, 反射, 透明度, 発光 }
for n, lk in pairs({
	Glacier = { Color3.fromRGB(190, 230, 245), "Glacier", 0.1, 0, 0 },
	Snow = { Color3.fromRGB(245, 248, 252), "Snow", 0, 0, 0 },
	Mud = { Color3.fromRGB(95, 70, 50), "Mud", 0, 0, 0 },
	Rubber = { Color3.fromRGB(40, 40, 46), "Rubber", 0, 0, 0 },
	Leather = { Color3.fromRGB(125, 72, 46), "Leather", 0, 0, 0 },
	Plaster = { Color3.fromRGB(232, 225, 212), "Plaster", 0, 0, 0 },
	CeramicTiles = { Color3.fromRGB(236, 240, 242), "CeramicTiles", 0.08, 0, 0 },
	Carpet = { Color3.fromRGB(150, 60, 72), "Carpet", 0, 0, 0 },
	Cardboard = { Color3.fromRGB(192, 152, 102), "Cardboard", 0, 0, 0 },
	Basalt = { Color3.fromRGB(62, 64, 70), "Basalt", 0, 0, 0 },
	Pebble = { Color3.fromRGB(150, 140, 130), "Pebble", 0, 0, 0 },
	Limestone = { Color3.fromRGB(222, 214, 192), "Limestone", 0, 0, 0 },
	Sandstone = { Color3.fromRGB(202, 162, 112), "Sandstone", 0, 0, 0 },
	CorrodedMetal = { Color3.fromRGB(132, 100, 80), "CorrodedMetal", 0, 0, 0 },
	CrackedLava = { Color3.fromRGB(255, 120, 40), "CrackedLava", 0, 0, 0.8 },
}) do
	if hasMat(n) then LOOKS[n] = lk end
end

-- 追加プリセット (見た目一式)。Full = 今ついている光・動き・効果を先に消してから反映する
-- Grad = グラデーション / GlossStyle = ツヤの種類(1やわらか 2くっきり 3ガラス 4メタル) / Pulse = {速さ, 型, 板も明滅}
-- Rainbow = {速さ, 鮮やかさ, 波の幅} / Fx = 出す効果の名前 / FireSize / FireColor / Sparkle / OutlineHue / GlowColor
do
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local function add(name, t)
		if not hasMat(t.Material) then t.Material = "SmoothPlastic" end
		t.Full = true
		t.Range = t.Range or 12
		t.Transparency = t.Transparency or 0
		t.Glow = t.Glow or 0
		PRESETS[name] = t
	end
	add("Aurora", { Color = C(60, 230, 180), Material = "SmoothPlastic", Reflectance = 0.55, GlossStyle = 2, Glow = 1.2,
		Grad = { a = C(40, 235, 160), c = C(70, 130, 255), b = C(190, 80, 255), axis = "X", flow = 0.12 }, Pulse = { 0.25, "Sine" } })
	add("Galaxy", { Color = C(60, 40, 140), Material = "SmoothPlastic", Reflectance = 0.3, GlossStyle = 3, Glow = 1,
		Grad = { a = C(15, 10, 60), c = C(110, 50, 190), b = C(20, 60, 140), axis = "X", flow = 0.06 }, Sparkle = { 40, 0.3 }, Pulse = { 0.35, "Sine" } })
	add("Chrome", { Color = C(214, 220, 232), Material = "Metal", Reflectance = 1, GlossStyle = 1 })
	add("Hologram", { Color = C(120, 220, 255), Material = "Glass", Reflectance = 0.8, GlossStyle = 3, Transparency = 0.3, Glow = 1.2,
		Rainbow = { 0.08, 0.55, 1 }, Pulse = { 0.3, "Sine" } })
	add("LavaFlow", { Color = C(255, 110, 20), Material = "Neon", Reflectance = 0, Glow = 2.2, Range = 16,
		Grad = { a = C(255, 40, 0), c = C(255, 140, 20), b = C(255, 230, 70), axis = "X", flow = 0.3 }, Pulse = { 0.8, "Flicker" },
		Fx = { "fire", "embers" }, FireSize = 4 })
	add("Frozen", { Color = C(170, 225, 255), Material = "Ice", Reflectance = 0.75, GlossStyle = 3, Transparency = 0.2, Glow = 0.8,
		GlowColor = C(210, 240, 255), Fx = { "snow" } })
	add("SakuraStorm", { Color = C(255, 170, 200), Material = "SmoothPlastic", Reflectance = 0.45, GlossStyle = 2, Glow = 0.8,
		GlowColor = C(255, 170, 205), Fx = { "sakura" } })
	add("Cyber", { Color = C(20, 24, 40), Material = "Metal", Reflectance = 0.7, GlossStyle = 4, Glow = 1.4, GlowColor = C(0, 255, 230),
		OutlineHue = 0.5, Pulse = { 1.2, "Beat" } })
	add("Fireflies", { Color = C(20, 50, 36), Material = "SmoothPlastic", Reflectance = 0.2, Glow = 0.8, GlowColor = C(190, 255, 120),
		Fx = { "firefly" }, Pulse = { 0.35, "Flicker" } })
	add("CandyGloss", { Color = C(255, 150, 205), Material = "SmoothPlastic", Reflectance = 0.9, GlossStyle = 1,
		Grad = { a = C(255, 150, 205), b = C(255, 245, 250), axis = "Y" }, Sparkle = { 30, 0.3 } })
	add("SunsetSky", { Color = C(255, 110, 70), Material = "SmoothPlastic", Reflectance = 0.5, GlossStyle = 2, Glow = 0.8, GlowColor = C(255, 160, 90),
		Grad = { a = C(255, 110, 40), c = C(255, 90, 150), b = C(110, 60, 200), axis = "Y" } })
	add("Ocean", { Color = C(20, 130, 200), Material = "SmoothPlastic", Reflectance = 0.7, GlossStyle = 3, Glow = 0.6, GlowColor = C(80, 200, 255),
		Grad = { a = C(10, 40, 120), c = C(20, 130, 200), b = C(90, 230, 230), axis = "X", flow = 0.1 }, Fx = { "bubbles" } })
end

local CollectionService = game:GetService("CollectionService")
local ANIM_TAG = "PalletStudioAnim"   -- 動きのある板に付ける目印 (この画面のアニメ担当が見つける)

local orig = setmetatable({}, { __mode = "k" })
local stateOf = setmetatable({}, { __mode = "k" })

local function st(model)
	local s = stateOf[model]
	if not s then s = {} stateOf[model] = s end
	return s
end

local function isNum(v)
	return typeof(v) == "number" and v == v and v > -math.huge and v < math.huge
end

local function partsOf(model)
	local parts = {}
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "Main" and p.Name ~= "SoundPart" then
			parts[#parts + 1] = p
		end
	end
	return parts
end

local function remember(p)
	if not orig[p] then orig[p] = { p.Color, p.Material, p.Reflectance, p.Transparency, p.CastShadow } end
	return orig[p]
end

local function glowHost(model)
	return model:FindFirstChild("SoundPart") or model.PrimaryPart
end

-- パーツの色を変える。「動きを止めた時にここへ戻す」ための基準色も属性に残す
local function setCol(p, c)
	p.Color = c
	p:SetAttribute("PS_Col", c)
end

-- 1枚ごとの色。色ムラ(variance)と経年劣化(weather)をここでまとめて掛ける
local function tint(s, i, c)
	local amt, wt = s.variance or 0, s.weather or 0
	if amt <= 0 and wt <= 0 then return c end
	local h, sa, v = c:ToHSV()
	if amt > 0 then
		v = v + (((i * 37) % 17) / 16 - 0.5) * amt * 0.6
	end
	if wt > 0 then
		local d = 0.35 + 0.65 * (((i * 53 + 7) % 13) / 12)   -- 板ごとに汚れ方を変える
		v = v * (1 - 0.5 * wt * d)
		sa = sa * (1 - 0.4 * wt * d)
	end
	return Color3.fromHSV(h, math.clamp(sa, 0, 1), math.clamp(v, 0, 1))
end

local function paint(model, parts, c)
	local s = st(model)
	s.base = c
	for i, p in ipairs(parts) do
		remember(p)
		setCol(p, tint(s, i, c))
	end
end

-- 動き(レインボー / 明滅 / グラデーションの流れ)の設定を、板の「属性」に書く。
-- 動かすのは各自の画面側 (なめらかに動くように)。サーバーは設定を書くだけで、毎フレーム更新はしない。
local ANIM_ATTRS = { "PS_Rb", "PS_RbSpeed", "PS_RbSat", "PS_RbSpread", "PS_Pulse", "PS_PulseStyle", "PS_PulseBody", "PS_Flow",
	"PS_GA", "PS_GB", "PS_GC", "PS_GRev", "PS_GMid", "PS_GStripes", "PS_GlowB", "PS_GlowCol" }
local function syncAnim(model)
	local s = st(model)
	local g = s.grad
	local flow = g and (g.flow or 0) or 0
	local on = (s.rainbow == true) or (s.pulse or 0) > 0 or flow > 0
	model:SetAttribute("PS_Rb", s.rainbow == true)
	model:SetAttribute("PS_RbSpeed", s.rbSpeed or 0.15)
	model:SetAttribute("PS_RbSat", s.rbSat or 0.85)
	model:SetAttribute("PS_RbSpread", s.rbSpread or 0)
	model:SetAttribute("PS_Pulse", s.pulse or 0)
	model:SetAttribute("PS_PulseStyle", s.pulseStyle or "Sine")
	model:SetAttribute("PS_PulseBody", s.pulseBody == true)
	model:SetAttribute("PS_Flow", flow)
	model:SetAttribute("PS_GA", g and g.a or nil)
	model:SetAttribute("PS_GB", g and g.b or nil)
	model:SetAttribute("PS_GC", g and g.c or nil)
	model:SetAttribute("PS_GRev", g and g.rev or nil)
	model:SetAttribute("PS_GMid", g and g.mid or nil)
	model:SetAttribute("PS_GStripes", g and g.stripes or nil)
	if on then
		CollectionService:AddTag(model, ANIM_TAG)
	else
		CollectionService:RemoveTag(model, ANIM_TAG)
	end
end

-- 光の形: Point=全方向 / Down=下向きスポット / Up=上向きスポット
local LIGHT_CLASS = { Point = "PointLight", Down = "SpotLight", Up = "SpotLight" }
local function setGlow(model, color, brightness, range)
	local h = glowHost(model)
	if not h then return end
	local s = st(model)
	local l = h:FindFirstChild("SkinGlow")
	if brightness <= 0 then
		s.glowB = 0
		model:SetAttribute("PS_GlowB", 0)
		if l then l:Destroy() end
		return
	end
	s.glowB = brightness
	local shape = s.lightShape or "Point"
	local cls = LIGHT_CLASS[shape]
	if l and l.ClassName ~= cls then
		l:Destroy()
		l = nil
	end
	if not l then
		l = Instance.new(cls)
		l.Name = "SkinGlow"
		l.Shadows = false
		l.Parent = h
	end
	if cls == "SpotLight" then
		l.Face = (shape == "Up") and Enum.NormalId.Top or Enum.NormalId.Bottom
		l.Angle = 120
	end
	l.Color = color
	l.Brightness = brightness
	l.Range = range or l.Range
	model:SetAttribute("PS_GlowB", brightness)
	model:SetAttribute("PS_GlowCol", color)
end

local function setOutline(model, on, color)
	local o = model:FindFirstChild("SkinOutline")
	if not on then
		if o then o:Destroy() end
		return
	end
	if not o then
		o = Instance.new("Highlight")
		o.Name = "SkinOutline"
		o.FillTransparency = 1
		o.OutlineColor = Color3.fromRGB(56, 189, 248)
		o.OutlineTransparency = 0
		o.Parent = model
	end
	if color then o.OutlineColor = color end
end

local function setTexture(parts, show)
	for _, p in ipairs(parts) do
		local o = remember(p)
		if not show then
			if p:IsA("MeshPart") and p.TextureID ~= "" then
				o.tex = o.tex or p.TextureID
				p.TextureID = ""
			end
			for _, c in ipairs(p:GetChildren()) do
				if c:IsA("SurfaceAppearance") or c:IsA("Texture") or c:IsA("Decal") then
					o.hold = o.hold or {}
					o.hold[#o.hold + 1] = c
					c.Parent = nil
				end
			end
		else
			if o.tex then p.TextureID = o.tex o.tex = nil end
			if o.hold then
				for _, c in ipairs(o.hold) do c.Parent = p end
				o.hold = nil
			end
		end
	end
end

---------------------------------------------------------------------
-- 反射(ツヤ) / グラデーション / ネオン / 明滅 / 効果
---------------------------------------------------------------------
local SK = {}
do
	local AXIS = { X = 1, Y = 2, Z = 3 }
	local function comp(v, ax) return ax == 1 and v.X or (ax == 2 and v.Y or v.Z) end
	local function mix(a, b, t)   -- 暗く沈まないよう、光の強さ(リニア)の空間で混ぜる
		local function m(x, y) return (x ^ 2.2 * (1 - t) + y ^ 2.2 * t) ^ (1 / 2.2) end
		return Color3.new(m(a.R, b.R), m(a.G, b.G), m(a.B, b.B))
	end
	-- 2色 (cfg.c があれば3色: 真ん中の色が mid の位置に来る)。t は 0〜1
	local function gradAt(cfg, t)
		t = math.clamp(t, 0, 1)
		if cfg.rev then t = 1 - t end
		if cfg.stripes > 1 then
			local k = math.min(math.floor(t * cfg.stripes), cfg.stripes - 1)
			if cfg.c then
				local m = k % 3
				return (m == 0 and cfg.a) or (m == 1 and cfg.c) or cfg.b
			end
			return (k % 2 == 0) and cfg.a or cfg.b
		end
		if cfg.c then
			if t <= cfg.mid then return mix(cfg.a, cfg.c, t / cfg.mid) end
			return mix(cfg.c, cfg.b, (t - cfg.mid) / (1 - cfg.mid))
		end
		return mix(cfg.a, cfg.b, t ^ (math.log(0.5) / math.log(cfg.mid)))   -- mid の位置でちょうど半分の色になる
	end
	SK.gradAt = gradAt

	-- 面ごとの GUI の向き (外から見て 右 / 上 が、パーツのどの向きか)
	local FACES = {
		{ "Front", Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Back", Vector3.new(1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Left", Vector3.new(0, 0, 1), Vector3.new(0, 1, 0) },
		{ "Right", Vector3.new(0, 0, -1), Vector3.new(0, 1, 0) },
		{ "Top", Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0) },
	}

	-- 板全体を軸 ax に沿って 0〜1 に見たとき、各パーツが占める範囲 (ta〜tb)
	local function axisInfo(model, parts, ax)
		local pv = model:GetPivot()
		local ex, lo, hi = {}, math.huge, -math.huge
		for i, p in ipairs(parts) do
			local rel = pv:ToObjectSpace(p.CFrame)
			local sz = p.Size
			local h = 0.5 * (math.abs(comp(rel.RightVector, ax)) * sz.X + math.abs(comp(rel.UpVector, ax)) * sz.Y + math.abs(comp(rel.LookVector, ax)) * sz.Z)
			local c = comp(rel.Position, ax)
			ex[i] = { rel = rel, c = c, h = h }
			if c - h < lo then lo = c - h end
			if c + h > hi then hi = c + h end
		end
		local span = hi - lo
		for _, e in ipairs(ex) do
			if span > 1e-3 then
				e.ta, e.tb = (e.c - e.h - lo) / span, (e.c + e.h - lo) / span
			else
				e.ta, e.tb = 0.5, 0.5
			end
		end
		return ex, span
	end
	-- 面 f の「左(上)→右(下)」が軸のどこからどこまでか。軸に沿わない面は nil
	local function faceWindow(e, f, ax, topFlip)
		local fr, fu = f[2], f[3]
		if f[1] == "Top" and topFlip then fr, fu = -fr, -fu end   -- 上面だけ向きが逆に見える時の保険
		local dr = comp(e.rel:VectorToWorldSpace(fr), ax)
		local du = comp(e.rel:VectorToWorldSpace(fu), ax)
		if math.abs(dr) > 0.9 then
			if dr > 0 then return e.ta, e.tb, false end
			return e.tb, e.ta, false
		elseif math.abs(du) > 0.9 then
			if du > 0 then return e.tb, e.ta, true end
			return e.ta, e.tb, true
		end
		return nil
	end

	-- 面ごとに GUI を1つだけ作り、その中に「層(Frame)」を重ねる: G=グラデーション / Sky,Band=ツヤ
	-- (同じ面に SurfaceGui を何枚も重ねると描画が不安定になるので、1面1枚にまとめる)
	local function faceGui(p, face)
		local want = Enum.NormalId[face]
		for _, c in ipairs(p:GetChildren()) do
			if c.Name == "SkinFace" and c.Face == want then return c end
		end
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SkinFace"
		sg.Face = want
		sg.LightInfluence = 1
		sg.AlwaysOnTop = false
		pcall(function() sg.MaxDistance = 250 end)
		sg.Parent = p
		return sg
	end
	local function layer(sg, name, z)
		local f = sg:FindFirstChild(name)
		if f then return f end
		f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.ZIndex = z
		f.Parent = sg
		return f
	end
	local function dropLayer(p, name)
		for _, c in ipairs(p:GetChildren()) do
			if c.Name == "SkinFace" then
				local f = c:FindFirstChild(name)
				if f then f:Destroy() end
				if #c:GetChildren() == 0 then c:Destroy() end
			end
		end
	end
	local function gradOf(f)
		local g = f:FindFirstChildOfClass("UIGradient")
		if not g then
			g = Instance.new("UIGradient")
			g.Parent = f
		end
		return g
	end

	-- ===== 反射 / ツヤ =====
	-- 板の素材やテクスチャには一切さわらない。
	--  (1) Part.Reflectance をそのまま変える (空を映す。プラスチック/つるつる/ガラスで特によく見える)
	--  (2) 面の上に「光の帯(ハイライト)」と「空の映り込み」を薄く重ねる → どの素材でも、100%でツルツルテカテカに見える
	local GLOSS_STYLES = {
		{ bands = { { 0.26, 0.10, 0.95 }, { 0.43, 0.03, 0.90 }, { 0.70, 0.17, 0.42 } }, sky = 0.38 },                                 -- 1 くっきり(鏡) ← 標準
		{ bands = { { 0.30, 0.20, 0.60 }, { 0.62, 0.09, 0.32 } }, sky = 0.26 },                                                       -- 2 やわらか
		{ bands = { { 0.18, 0.035, 0.90 }, { 0.24, 0.014, 0.95 }, { 0.60, 0.05, 0.55 }, { 0.66, 0.02, 0.6 } }, sky = 0.2 },            -- 3 ガラス
		{ bands = { { 0.10, 0.11, 0.55 }, { 0.30, 0.11, 0.55 }, { 0.50, 0.11, 0.55 }, { 0.70, 0.11, 0.55 }, { 0.90, 0.11, 0.55 } }, sky = 0.28 }, -- 4 メタル
	}
	SK.GLOSS_STYLES = #GLOSS_STYLES
	local function bandAlpha(bands, t)
		local a = 0
		for _, b in ipairs(bands) do
			local d = math.abs(t - b[1]) / b[2]
			if d < 1 then
				local k = 1 - d
				k = k * k * (3 - 2 * k)
				a = 1 - (1 - a) * (1 - b[3] * k)
			end
		end
		return a
	end
	local function glossK(v) return math.clamp((v - 0.12) / 0.88, 0, 1) ^ 0.85 end
	SK.glossK = glossK
	local function bandSeq(style, k, t0, t1)
		local us = { 0, 1 }
		if math.abs(t1 - t0) > 1e-6 then
			for _, b in ipairs(style.bands) do
				for _, d in ipairs({ -1, -0.5, 0, 0.5, 1 }) do
					local u = (b[1] + d * b[2] - t0) / (t1 - t0)
					if u > 0.003 and u < 0.997 then us[#us + 1] = u end
				end
			end
		end
		table.sort(us)
		local keys, last = {}, -1
		for _, u in ipairs(us) do
			if u > last + 1e-4 then
				keys[#keys + 1] = u
				last = u
			end
		end
		while #keys > 20 do   -- 点が多すぎる時は、間を1つおきに間引く (両端は残す)
			local nk = {}
			for i, u in ipairs(keys) do
				if i == 1 or i == #keys or i % 2 == 1 then nk[#nk + 1] = u end
			end
			keys = nk
		end
		local out = {}
		for _, u in ipairs(keys) do
			local t = t0 + (t1 - t0) * u
			out[#out + 1] = NumberSequenceKeypoint.new(u, 1 - bandAlpha(style.bands, t) * k)
		end
		return NumberSequence.new(out)
	end
	local function skySeq(style, k, top)   -- 空の映り込み: 横の面は上が濃く下へ薄く / 上の面は一様
		local a = style.sky * k
		if top then
			return NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - a * 0.8), NumberSequenceKeypoint.new(1, 1 - a * 0.8) })
		end
		return NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - a), NumberSequenceKeypoint.new(0.55, 1 - a * 0.35), NumberSequenceKeypoint.new(1, 1 - a * 0.1) })
	end

	function SK.clearGloss(model)
		local s = st(model)
		if s.gloss then
			for _, p in ipairs(partsOf(model)) do
				dropLayer(p, "Sky")
				dropLayer(p, "Band")
			end
		end
		s.gloss = nil
	end

	-- ツヤの重ね貼りを、いまの反射の強さ(s.refl)に合わせて作る/更新する
	function SK.gloss(model, parts)
		local s = st(model)
		local k = glossK(s.refl or 0)
		if k <= 0 then
			SK.clearGloss(model)
			return
		end
		local trMax = 0   -- 板が透けているほど、ツヤの帯も薄くする (透けた板に不透明な白い帯が浮かないように)
		for _, p in ipairs(parts) do
			if p.Transparency > trMax then trMax = p.Transparency end
		end
		k = k * (1 - 0.6 * trMax)
		local style = GLOSS_STYLES[s.glossStyle or 1] or GLOSS_STYLES[1]
		local axisName = s.glossAxis or "X"
		local flip = (s.grad and s.grad.topFlip) == true
		local key = tostring(s.glossStyle or 1) .. axisName .. tostring(flip) .. "#" .. #parts
		local G = s.gloss
		if G and G.key == key then   -- 作り直さず、濃さだけ更新 (スライダーを動かしている間はこちら)
			for _, f in ipairs(G.faces) do
				if f.band.Parent then
					f.skyG.Transparency = skySeq(style, k, f.top)
					f.bandG.Transparency = bandSeq(style, k, f.t0, f.t1)
				end
			end
			return
		end
		SK.clearGloss(model)
		local ax = AXIS[axisName] or 1
		local ex = axisInfo(model, parts, ax)
		local faces, made = {}, 0
		for i, p in ipairs(parts) do
			local e = ex[i]
			for _, f in ipairs(FACES) do
				if made >= 150 then break end
				local t0, t1, vertical = faceWindow(e, f, ax, flip)
				if not t0 then
					t0 = (e.ta + e.tb) / 2   -- 軸に沿わない面は、一定の濃さ
					t1, vertical = t0, false
				end
				local top = (f[1] == "Top")
				local sg = faceGui(p, f[1])
				local sky = layer(sg, "Sky", 2)
				sky.BackgroundColor3 = Color3.fromRGB(205, 228, 255)
				sky.BackgroundTransparency = 0
				local skyG = gradOf(sky)
				skyG.Rotation = 90
				skyG.Transparency = skySeq(style, k, top)
				local band = layer(sg, "Band", 3)
				band.BackgroundTransparency = 0
				local bandG = gradOf(band)
				bandG.Rotation = vertical and 90 or 0
				bandG.Transparency = bandSeq(style, k, t0, t1)
				faces[#faces + 1] = { band = band, skyG = skyG, bandG = bandG, t0 = t0, t1 = t1, top = top }
				made = made + 1
			end
		end
		s.gloss = { key = key, faces = faces }
	end

	function SK.reflect(model, parts, v)
		local s = st(model)
		v = math.clamp(v, 0, 1)
		s.refl = v
		for _, p in ipairs(parts) do
			remember(p)
			p.Reflectance = v
		end
		SK.gloss(model, parts)
	end

	-- ===== グラデーション (2色/3色を混ぜる。cfg.flow > 0 なら色が流れる) =====
	-- t0(左/上) → t1(右/下) の ColorSequence を作る。ストライプの時は境目を急に切り替える
	local function buildSeq(cfg, t0, t1, tf)
		local us = {}
		if cfg.stripes > 1 then
			us[#us + 1] = 0
			for k = 1, cfg.stripes - 1 do
				local u = (k / cfg.stripes - t0) / ((t1 - t0 == 0) and 1e-9 or (t1 - t0))
				if u > 0.004 and u < 0.996 then
					us[#us + 1] = u - 0.002
					us[#us + 1] = u + 0.002
				end
			end
			us[#us + 1] = 1
			table.sort(us)
		else
			for i = 0, 10 do us[#us + 1] = i / 10 end
			if cfg.c and t1 ~= t0 then   -- 3色の時は、真ん中の色の位置にも必ず点を置く (角が丸まらないように)
				local tm = cfg.rev and (1 - cfg.mid) or cfg.mid
				local um = (tm - t0) / (t1 - t0)
				if um > 0.004 and um < 0.996 then us[#us + 1] = um end
			end
			table.sort(us)
		end
		local keys, last = {}, -1
		for _, u in ipairs(us) do
			if u > last + 1e-4 then
				keys[#keys + 1] = ColorSequenceKeypoint.new(u, tf(gradAt(cfg, t0 + (t1 - t0) * u)))
				last = u
			end
		end
		return ColorSequence.new(keys)
	end
	local function addGradLayer(p, face, seq, vertical, tr)
		local sg = faceGui(p, face)
		local old = sg:FindFirstChild("G")
		if old then old:Destroy() end
		local f = layer(sg, "G", 1)
		f.BackgroundTransparency = tr or 0   -- 板の透明度に合わせる (重ね貼りだけ不透明に残らないように)
		local g = gradOf(f)
		g.Color = seq
		g.Rotation = vertical and 90 or 0
	end

	function SK.clearGrad(model)
		local s = st(model)
		if not s.grad then return end
		s.grad = nil
		for _, p in ipairs(partsOf(model)) do dropLayer(p, "G") end
		syncAnim(model)
	end

	-- 板についている重ね貼りを全部消す (元に戻す時用。古い版の SkinGrad も消す)
	function SK.dropAll(model)
		for _, p in ipairs(partsOf(model)) do
			dropLayer(p, "G")
			dropLayer(p, "Sky")
			dropLayer(p, "Band")
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinGrad" then c:Destroy() end
			end
		end
	end

	function SK.syncGradTr(parts, tr)
		for _, p in ipairs(parts) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fr = c:FindFirstChild("G")
					if fr then fr.BackgroundTransparency = tr end
				end
			end
		end
	end
	-- グラデの重ね貼りの透け具合 = 板の透明度。ただし「木目テクスチャ」をONにしている時は、木目が見えるよう 0.55 以上に透かす
	local WOOD_SEE = 0.55
	function SK.refreshGradTr(model, parts)
		local see = st(model).texUser == true
		for _, p in ipairs(parts) do
			local tr = p.Transparency
			if see and tr < WOOD_SEE then tr = WOOD_SEE end
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fr = c:FindFirstChild("G")
					if fr then fr.BackgroundTransparency = tr end
				end
			end
		end
	end

	-- v = { a, b, c(なくても可), axis, rev, mid=0.1~0.9, smooth, stripes=0~8, topFlip, flow=0~2 }
	function SK.gradient(model, parts, v, keepTex)
		if typeof(v) ~= "table" or typeof(v.a) ~= "Color3" or typeof(v.b) ~= "Color3" or not AXIS[v.axis] then return false end
		local cfg = {
			a = v.a, b = v.b, c = (typeof(v.c) == "Color3") and v.c or nil, axis = v.axis, rev = v.rev == true,
			smooth = v.smooth ~= false, topFlip = v.topFlip == true,
			mid = isNum(v.mid) and math.clamp(v.mid, 0.1, 0.9) or 0.5,
			stripes = isNum(v.stripes) and math.clamp(math.floor(v.stripes), 0, 8) or 0,
			flow = isNum(v.flow) and math.clamp(v.flow, 0, 2) or 0,
		}
		local s = st(model)
		s.rainbow = nil
		SK.clearGrad(model)
		if not keepTex then
			s.texUser = false
			setTexture(parts, false)   -- 木目が上に残ると色が見えないので、外す
		end
		s.grad = cfg
		s.base = gradAt(cfg, 0.5)
		local ax = AXIS[cfg.axis]
		local ex, span = axisInfo(model, parts, ax)
		local made = 0
		for i, p in ipairs(parts) do
			remember(p)
			local e = ex[i]
			local function tf(c) return tint(s, i, c) end
			local tc = (e.ta + e.tb) / 2
			setCol(p, tf(gradAt(cfg, tc)))   -- 重ね貼りしない面(裏・端)や、流れる時の元の色は、この平均色
			p:SetAttribute("PS_T", tc)
			if cfg.smooth and cfg.flow <= 0 and span > 1e-3 and made < 160 then   -- 流れる時は重ね貼りしない (重ねると動きが隠れる)
				for _, f in ipairs(FACES) do
					local t0, t1, vertical = faceWindow(e, f, ax, cfg.topFlip)
					if t0 then
						addGradLayer(p, f[1], buildSeq(cfg, t0, t1, tf), vertical, p.Transparency)
						made = made + 1
					end
				end
			end
		end
		syncAnim(model)
		if keepTex and s.texUser then SK.refreshGradTr(model, parts) end   -- 木目を見せたままの時は、重ね貼りを透かす
		SK.gloss(model, parts)   -- 上面の向きを反転した時は、ツヤの向きも合わせる
		return true
	end

	-- レインボーの「波」用: 板の長い方向 (X か Z) での位置を、パーツごとに 0〜1 で属性に書く
	function SK.assignT(model, parts)
		local exX, spX = axisInfo(model, parts, 1)
		local exZ, spZ = axisInfo(model, parts, 3)
		local ex = (spX >= spZ) and exX or exZ
		for i, p in ipairs(parts) do
			p:SetAttribute("PS_T", (ex[i].ta + ex[i].tb) / 2)
		end
	end
end

do
	-- ===== ネオン発光 (素材をネオンにする。OFFで元の素材に戻る) =====
	function SK.neon(model, parts, on)
		local s = st(model)
		if on then
			s.neonSaved = s.neonSaved or {}
			for _, p in ipairs(parts) do
				remember(p)
				if s.neonSaved[p] == nil then s.neonSaved[p] = p.Material end
				p.Material = Enum.Material.Neon
			end
			s.neon = true
		else
			if s.neonSaved then
				for _, p in ipairs(parts) do
					local m = s.neonSaved[p]
					if m ~= nil and p.Material == Enum.Material.Neon then p.Material = m end
				end
			end
			s.neonSaved = nil
			s.neon = nil
		end
	end

	-- ===== レインボー (色を変えるのは各自の画面。ここでは設定を属性に書くだけ) =====
	function SK.rainbow(model, parts, on)
		local s = st(model)
		if on then
			SK.clearGrad(model)
			for _, p in ipairs(parts) do
				remember(p)
				if p:GetAttribute("PS_Col") == nil then p:SetAttribute("PS_Col", p.Color) end   -- 止めた時に戻す色
			end
			SK.assignT(model, parts)
			s.rainbow = true
		else
			s.rainbow = nil
		end
		syncAnim(model)
	end
end

---------------------------------------------------------------------
-- 効果 (炎・煙・キラキラ・紙吹雪・雪・桜・ほたる・あわ・火の粉) — すべて ParticleEmitter
-- Acceleration は「世界の上下」で効くので、板がどんな向きでも、炎や煙は必ず上へ昇る。
-- 板の大きいパーツ(最大3つ)に付けるので、小さな音用パーツの向きに引っ張られない。
---------------------------------------------------------------------
local FX = {}
local FX_NAMES = { "fire", "smoke", "sparkle", "confetti", "snow", "sakura", "firefly", "bubbles", "embers" }
local FX_TEX = {
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	spark = "rbxasset://textures/particles/sparkles_main.dds",
}
-- 炎の色: { 芯, 中, 外, 消える頃 }
local FIRE_COLORS = {
	{ Color3.fromRGB(255, 240, 170), Color3.fromRGB(255, 150, 40), Color3.fromRGB(225, 60, 20), Color3.fromRGB(50, 20, 15) },
	{ Color3.fromRGB(200, 235, 255), Color3.fromRGB(70, 150, 255), Color3.fromRGB(30, 70, 220), Color3.fromRGB(10, 15, 50) },
	{ Color3.fromRGB(220, 255, 200), Color3.fromRGB(80, 255, 120), Color3.fromRGB(20, 170, 70), Color3.fromRGB(5, 40, 20) },
	{ Color3.fromRGB(240, 215, 255), Color3.fromRGB(180, 100, 255), Color3.fromRGB(110, 40, 200), Color3.fromRGB(25, 10, 50) },
	{ Color3.fromRGB(255, 225, 240), Color3.fromRGB(255, 110, 190), Color3.fromRGB(210, 40, 130), Color3.fromRGB(50, 10, 35) },
}
local function seqN(list)
	local k = {}
	for _, a in ipairs(list) do k[#k + 1] = NumberSequenceKeypoint.new(a[1], a[2]) end
	return NumberSequence.new(k)
end
local function seqC(list)
	local k = {}
	for _, a in ipairs(list) do k[#k + 1] = ColorSequenceKeypoint.new(a[1], a[2]) end
	return ColorSequence.new(k)
end
local function trySet(o, k, v) pcall(function() o[k] = v end) end
local function mul(s) return s.fxMul or 1 end

FX.fire = function(e, s, n)
	local sc = (s.fireSize or 6) / 6
	local pal = FIRE_COLORS[s.fireColor or 1] or FIRE_COLORS[1]
	e.Texture = FX_TEX.fire
	e.Color = seqC({ { 0, pal[1] }, { 0.25, pal[2] }, { 0.65, pal[3] }, { 1, pal[4] } })
	e.LightEmission = 1
	trySet(e, "LightInfluence", 0)
	e.Size = seqN({ { 0, 0.5 * sc }, { 0.2, 1.6 * sc }, { 1, 0.1 * sc } })
	e.Transparency = seqN({ { 0, 1 }, { 0.12, 0.25 }, { 0.7, 0.55 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(0.7, 1.3)
	e.Speed = NumberRange.new(0, 0.8)
	e.Acceleration = Vector3.new(0, 4 + 1.2 * sc, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-45, 45)
	e.Rate = (28 + 10 * sc) * mul(s) / n
end
FX.smoke = function(e, s, n)
	local sc = (s.fireSize or 6) / 6
	e.Texture = FX_TEX.smoke
	e.Color = seqC({ { 0, Color3.fromRGB(120, 120, 126) }, { 1, Color3.fromRGB(205, 205, 212) } })
	e.LightEmission = 0
	trySet(e, "LightInfluence", 0.6)
	e.Size = seqN({ { 0, 0.8 * sc }, { 1, 3.2 * sc } })
	e.Transparency = seqN({ { 0, 1 }, { 0.15, 0.55 }, { 0.7, 0.8 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(2.2, 3.8)
	e.Speed = NumberRange.new(0, 0.6)
	e.Acceleration = Vector3.new(0, 1.2 + 0.35 * sc, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-25, 25)
	e.Rate = (7 + 3 * sc) * mul(s) / n
end
FX.embers = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = seqC({ { 0, Color3.fromRGB(255, 220, 140) }, { 0.5, Color3.fromRGB(255, 120, 30) }, { 1, Color3.fromRGB(120, 30, 10) } })
	e.LightEmission = 1
	e.Size = seqN({ { 0, 0.28 }, { 0.3, 0.2 }, { 1, 0 } })
	e.Transparency = seqN({ { 0, 0.1 }, { 0.8, 0.3 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(1.4, 3)
	e.Speed = NumberRange.new(0.5, 2.5)
	e.Acceleration = Vector3.new(0, 3.2, 0)
	trySet(e, "Drag", 0.8)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Rate = 14 * mul(s) / n
end
FX.sparkle = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(1, 3)
	e.Acceleration = Vector3.new(0, 0.6, 0)
	e.Transparency = seqN({ { 0, 0 }, { 1, 1 } })
	e.LightEmission = 1
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.Size = seqN({ { 0, s.sparkSize or 0.35 }, { 1, 0 } })
	e.Rate = (s.sparkRate or 25) * mul(s) / n
end
FX.confetti = function(e, s, n)
	e.Rate = 40 * mul(s) / n
	e.Lifetime = NumberRange.new(1.6, 2.6)
	e.Speed = NumberRange.new(8, 16)
	e.SpreadAngle = Vector2.new(60, 60)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -22, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-240, 240)
	e.LightEmission = 0.2
	e.Size = NumberSequence.new(0.35)
	e.Transparency = seqN({ { 0, 0 }, { 0.8, 0 }, { 1, 1 } })
	local keys = {}
	for i = 0, 6 do keys[#keys + 1] = { i / 6, Color3.fromHSV(i / 6, 0.85, 1) } end
	e.Color = seqC(keys)
end
FX.snow = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.5
	e.Size = seqN({ { 0, 0.22 }, { 1, 0.16 } })
	e.Transparency = seqN({ { 0, 1 }, { 0.1, 0.1 }, { 0.85, 0.2 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(1, 3)
	e.Acceleration = Vector3.new(0, -1.6, 0)
	trySet(e, "Drag", 0.9)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Rate = 18 * mul(s) / n
end
FX.sakura = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 200))
	e.LightEmission = 0.1
	e.Size = seqN({ { 0, 0.4 }, { 1, 0.3 } })
	e.Transparency = seqN({ { 0, 1 }, { 0.1, 0.1 }, { 0.85, 0.2 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(1, 3)
	e.Acceleration = Vector3.new(0, -0.9, 0)
	trySet(e, "Drag", 0.8)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Rate = 12 * mul(s) / n
end
FX.firefly = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = ColorSequence.new(Color3.fromRGB(210, 255, 120))
	e.LightEmission = 1
	e.Size = seqN({ { 0, 0 }, { 0.2, 0.4 }, { 0.8, 0.4 }, { 1, 0 } })
	e.Transparency = seqN({ { 0, 1 }, { 0.2, 0.15 }, { 0.8, 0.15 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(0.4, 1.2)
	e.Acceleration = Vector3.new(0, 0.3, 0)
	trySet(e, "Drag", 1.2)
	e.Rate = 5 * mul(s) / n
end
FX.bubbles = function(e, s, n)
	e.Texture = FX_TEX.smoke
	e.Color = ColorSequence.new(Color3.fromRGB(190, 235, 255))
	e.LightEmission = 0.3
	e.Size = seqN({ { 0, 0.2 }, { 1, 0.6 } })
	e.Transparency = seqN({ { 0, 0.55 }, { 0.8, 0.65 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(2, 3.5)
	e.Speed = NumberRange.new(0.3, 1.2)
	e.Acceleration = Vector3.new(0, 1.8, 0)
	trySet(e, "Drag", 0.6)
	e.Rate = 7 * mul(s) / n
end

local function fxHosts(model, n)
	local list = partsOf(model)
	table.sort(list, function(a, b)
		local va, vb = a.Size.X * a.Size.Y * a.Size.Z, b.Size.X * b.Size.Y * b.Size.Z
		if va ~= vb then return va > vb end
		return a.Name < b.Name
	end)
	local out = {}
	for i = 1, math.min(n, #list) do out[i] = list[i] end
	return out
end

-- 効果を付ける / 外す。すでに付いていれば、作り直さずに設定だけ更新する (滑らかに変わる)
local function setFx(model, name, on)
	local s = st(model)
	s.fx = s.fx or {}
	local en = "SkinFx_" .. name
	if not on then
		s.fx[name] = nil
		for _, p in ipairs(partsOf(model)) do
			local e = p:FindFirstChild(en)
			if e then e:Destroy() end
		end
		return
	end
	s.fx[name] = true
	local hosts = fxHosts(model, 3)
	local keep = {}
	for _, p in ipairs(hosts) do
		keep[p] = true
		local e = p:FindFirstChild(en)
		if e then
			FX[name](e, s, #hosts)
		else
			e = Instance.new("ParticleEmitter")
			e.Name = en
			FX[name](e, s, #hosts)
			e.Parent = p
		end
	end
	for _, p in ipairs(partsOf(model)) do   -- パーツが増減した時に、付ける先から外れたものを片づける
		if not keep[p] then
			local e = p:FindFirstChild(en)
			if e then e:Destroy() end
		end
	end
end
local function refreshFx(model)
	local s = st(model)
	if not s.fx then return end
	local names = {}
	for name in pairs(s.fx) do names[#names + 1] = name end
	for _, name in ipairs(names) do setFx(model, name, true) end
end
local function clearFx(model)
	for _, n in ipairs(FX_NAMES) do setFx(model, n, false) end
	-- 古い版が付けた物も片づける
	local h = glowHost(model)
	if h then
		for _, n in ipairs({ "SkinFire", "SkinSmoke", "SkinConfetti", "SkinSparkle" }) do
			local o = h:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end
end

-- プリセット(Full)を付ける前に、いまの光・動き・効果を全部消す
function SK.resetExtras(model, parts)
	local s = st(model)
	clearFx(model)
	s.sparkRate, s.sparkSize, s.fireSize, s.fireColor, s.fxMul = nil, nil, nil, nil, nil
	s.pulse, s.pulseStyle, s.pulseBody = nil, nil, nil
	s.rainbow, s.rbSpread = nil, nil
	s.glowColor = nil
	SK.clearGrad(model)
	setOutline(model, false)
	syncAnim(model)
end

-- プリセットを反映する。Full のものは、いまの光・動き・効果を先に全部消してから見た目一式を付ける
local function applyPreset(model, parts, pr)
	local s = st(model)
	if pr.Full then
		SK.resetExtras(model, parts)
		s.texUser = false
		setTexture(parts, false)
	end
	s.rainbow = nil
	s.neon, s.neonSaved = nil, nil
	paint(model, parts, pr.Color)
	for _, p in ipairs(parts) do
		remember(p)
		p.Material = Enum.Material[pr.Material]
		p.Transparency = pr.Transparency
	end
	s.glossStyle = pr.GlossStyle or (pr.Full and 1 or s.glossStyle)
	SK.reflect(model, parts, pr.Reflectance)
	s.glowColor = pr.GlowColor
	setGlow(model, pr.GlowColor or pr.Color, pr.Glow, pr.Range)
	if pr.Grad then
		local g = pr.Grad
		SK.gradient(model, parts, { a = g.a, b = g.b, c = g.c, axis = g.axis, mid = g.mid, stripes = g.stripes, flow = g.flow, smooth = true })
	end
	if pr.Rainbow then
		s.rbSpeed, s.rbSat, s.rbSpread = pr.Rainbow[1], pr.Rainbow[2], pr.Rainbow[3]
		SK.rainbow(model, parts, true)
	end
	if pr.Pulse then
		s.pulse, s.pulseStyle, s.pulseBody = pr.Pulse[1], pr.Pulse[2], pr.Pulse[3] == true
	end
	if pr.FireSize then s.fireSize = pr.FireSize end
	if pr.FireColor then s.fireColor = pr.FireColor end
	if pr.Sparkle then
		s.sparkRate, s.sparkSize = pr.Sparkle[1], pr.Sparkle[2]
		setFx(model, "sparkle", true)
	end
	if pr.Fx then
		for _, n in ipairs(pr.Fx) do setFx(model, n, true) end
	end
	if pr.OutlineHue then setOutline(model, true, Color3.fromHSV(pr.OutlineHue, 0.75, 1)) end
	syncAnim(model)
end

local PULSE_STYLES = { Sine = true, Beat = true, Flicker = true, Strobe = true }
local MAX_BATCH = 60
local applySkin
function applySkin(model, kind, value)
	local parts = partsOf(model)
	if #parts == 0 then return "板の部品が見つかりません" end
	local s = st(model)
	-- 色を直接変える操作・レインボーONの時は、重ね貼りしているグラデーションを先に外す。色を決める操作はレインボーも止める
	if kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" or (kind == "Rainbow" and value == true) then
		SK.clearGrad(model)
	end
	if kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" then
		if s.rainbow then
			s.rainbow = nil
			syncAnim(model)
		end
	end

	if kind == "Batch" then   -- 複数の操作を1回の通信でまとめて反映 (永久保存・コピー・おまかせ用)
		if typeof(value) ~= "table" then return "値が不正です" end
		local n = 0
		for i, op in ipairs(value) do
			if i > MAX_BATCH then break end
			if typeof(op) == "table" and typeof(op[1]) == "string" and op[1] ~= "Batch" then
				local ok, res = pcall(applySkin, model, op[1], op[2])
				if ok and typeof(res) == "string" and not (res:find("不正") or res:find("不明") or res:find("見つかりません")) then n = n + 1 end
			end
		end
		return n .. "件の設定を反映しました"
	elseif kind == "Color" then
		if typeof(value) ~= "Color3" then return "色が不正です" end
		paint(model, parts, value)
		return "色を変えました"
	elseif kind == "HSV" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		paint(model, parts, Color3.fromHSV(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "RGB" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		paint(model, parts, Color3.new(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "Material" then
		if typeof(value) ~= "string" or not MATERIAL_SET[value] then return "素材が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Material = Enum.Material[value] end
		return "素材を「" .. value .. "」にしました"
	elseif kind == "Look" then
		local lk = typeof(value) == "string" and LOOKS[value] or nil
		if not lk then return "素材が不正です" end
		s.glowColor = nil
		s.neon, s.neonSaved = nil, nil
		s.texUser = false
		setTexture(parts, false)
		paint(model, parts, lk[1])
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[lk[2]]
			p.Transparency = lk[4]
		end
		SK.reflect(model, parts, lk[3])
		setGlow(model, lk[1], lk[5], 10)
		return "素材「" .. value .. "」にしました"
	elseif kind == "Preset" then
		local pr = typeof(value) == "string" and PRESETS[value] or nil
		if not pr then return "プリセットが不正です" end
		applyPreset(model, parts, pr)
		return "プリセット「" .. value .. "」を適用しました"
	elseif kind == "Reflectance" then
		if not isNum(value) then return "値が不正です" end
		SK.reflect(model, parts, value)   -- 素材やテクスチャは変えない
		return "反射を変えました"
	elseif kind == "GlossStyle" then
		if not isNum(value) then return "値が不正です" end
		s.glossStyle = math.clamp(math.floor(value + 0.5), 1, SK.GLOSS_STYLES)
		SK.gloss(model, parts)
		return "ツヤの種類を変えました"
	elseif kind == "GlossAxis" then
		if value ~= "X" and value ~= "Y" and value ~= "Z" then return "値が不正です" end
		s.glossAxis = value
		SK.gloss(model, parts)
		return "ハイライトの向きを変えました"
	elseif kind == "Transparency" then
		if not isNum(value) then return "値が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Transparency = math.clamp(value, 0, 0.9) end
		SK.refreshGradTr(model, parts)
		SK.gloss(model, parts)   -- 透け具合に合わせて、ツヤの濃さも更新する
		return "透明度を変えました"
	elseif kind == "Variance" then
		if not isNum(value) then return "値が不正です" end
		s.variance = math.clamp(value, 0, 1)
		if s.grad then SK.gradient(model, parts, s.grad, true) else paint(model, parts, s.base or parts[1].Color) end
		return "色ムラを変えました"
	elseif kind == "Weather" then
		if not isNum(value) then return "値が不正です" end
		s.weather = math.clamp(value, 0, 1)
		if s.grad then SK.gradient(model, parts, s.grad, true) else paint(model, parts, s.base or parts[1].Color) end
		return "経年劣化を変えました"
	elseif kind == "Texture" then
		s.texUser = (value == true)
		setTexture(parts, value == true)
		if s.grad then SK.refreshGradTr(model, parts) end   -- グラデが木目を隠さないよう、透け具合を合わせる
		return value == true and "テクスチャON" or "テクスチャOFF"
	elseif kind == "Glow" then
		if not isNum(value) then return "値が不正です" end
		setGlow(model, s.glowColor or s.base or parts[1].Color, math.clamp(value, 0, 5), nil)
		return "発光を変えました"
	elseif kind == "GlowRange" then
		if not isNum(value) then return "値が不正です" end
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		setGlow(model, s.glowColor or s.base or parts[1].Color, l and (s.glowB or l.Brightness) or 1, math.clamp(value, 4, 30))
		return "発光の範囲を変えました"
	elseif kind == "GlowHue" then
		if not isNum(value) then return "値が不正です" end
		s.glowColor = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then l.Color = s.glowColor end
		model:SetAttribute("PS_GlowCol", s.glowColor)
		return "発光の色を変えました"
	elseif kind == "Rainbow" then
		SK.rainbow(model, parts, value == true)
		return value == true and "レインボーON" or "レインボーOFF"
	elseif kind == "RainbowSpeed" then
		if not isNum(value) then return "値が不正です" end
		s.rbSpeed = math.clamp(value, 0.02, 1)
		SK.rainbow(model, parts, true)
		return "レインボーの速さを変えました"
	elseif kind == "RainbowSat" then
		if not isNum(value) then return "値が不正です" end
		s.rbSat = math.clamp(value, 0, 1)
		syncAnim(model)
		return "レインボーの鮮やかさを変えました"
	elseif kind == "RainbowSpread" then
		if not isNum(value) then return "値が不正です" end
		s.rbSpread = math.clamp(value, 0, 1)
		SK.rainbow(model, parts, true)
		return "虹の波の幅を変えました"
	elseif kind == "Sparkle" then
		setFx(model, "sparkle", value == true)
		return value == true and "キラキラON" or "キラキラOFF"
	elseif kind == "SparkleRate" then
		if not isNum(value) then return "値が不正です" end
		s.sparkRate = math.clamp(value, 1, 120)
		setFx(model, "sparkle", true)
		return "キラキラの量を変えました"
	elseif kind == "SparkleSize" then
		if not isNum(value) then return "値が不正です" end
		s.sparkSize = math.clamp(value, 0.05, 2)
		setFx(model, "sparkle", true)
		return "キラキラの大きさを変えました"
	elseif kind == "Outline" then
		setOutline(model, value == true)
		return value == true and "縁取りON" or "縁取りOFF"
	elseif kind == "OutlineHue" then
		if not isNum(value) then return "値が不正です" end
		setOutline(model, true, Color3.fromHSV(math.clamp(value, 0, 1), 0.75, 1))
		return "縁取りの色を変えました"
	elseif kind == "Gradient" then
		if not SK.gradient(model, parts, value) then return "グラデーションの値が不正です" end
		return "グラデーションを適用しました"
	elseif kind == "GradientClear" then
		SK.clearGrad(model)
		paint(model, parts, s.base or parts[1].Color)
		return "グラデーションを外しました"
	elseif kind == "Neon" then
		SK.neon(model, parts, value == true)
		return value == true and "ネオン発光ON" or "ネオン発光OFF"
	elseif kind == "Pulse" then
		if not isNum(value) then return "値が不正です" end
		s.pulse = math.clamp(value, 0, 4)
		syncAnim(model)
		return value > 0 and "明滅の速さを変えました" or "明滅OFF"
	elseif kind == "PulseStyle" then
		if typeof(value) ~= "string" or not PULSE_STYLES[value] then return "値が不正です" end
		s.pulseStyle = value
		syncAnim(model)
		return "明滅のしかたを変えました"
	elseif kind == "PulseBody" then
		s.pulseBody = (value == true)
		syncAnim(model)
		return value == true and "板も一緒に明滅" or "光だけ明滅"
	elseif kind == "LightShape" then
		if value ~= "Point" and value ~= "Down" and value ~= "Up" then return "値が不正です" end
		s.lightShape = value
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then setGlow(model, l.Color, s.glowB or l.Brightness, l.Range) end
		return "光の向きを変えました"
	elseif kind == "Shadow" then
		for _, p in ipairs(parts) do remember(p) p.CastShadow = (value == true) end
		return value == true and "影を落とす" or "影を落とさない"
	elseif kind == "Fire" then
		setFx(model, "fire", value == true)
		return value == true and "炎ON" or "炎OFF"
	elseif kind == "FireSize" then
		if not isNum(value) then return "値が不正です" end
		s.fireSize = math.clamp(value, 2, 30)
		setFx(model, "fire", true)
		refreshFx(model)   -- 煙も炎の大きさに合わせる
		return "炎の大きさを変えました"
	elseif kind == "FireColor" then
		if not isNum(value) then return "値が不正です" end
		s.fireColor = math.clamp(math.floor(value + 0.5), 1, #FIRE_COLORS)
		setFx(model, "fire", true)
		return "炎の色を変えました"
	elseif kind == "Smoke" then
		setFx(model, "smoke", value == true)
		return value == true and "煙ON" or "煙OFF"
	elseif kind == "Confetti" then
		setFx(model, "confetti", value == true)
		return value == true and "紙吹雪ON" or "紙吹雪OFF"
	elseif kind == "Snow" or kind == "Sakura" or kind == "Firefly" or kind == "Bubbles" or kind == "Embers" then
		setFx(model, string.lower(kind), value == true)
		return value == true and (kind .. "ON") or (kind .. "OFF")
	elseif kind == "FxAmount" then
		if not isNum(value) then return "値が不正です" end
		s.fxMul = math.clamp(value, 0.2, 3)
		refreshFx(model)
		return "効果の量を変えました"
	elseif kind == "Reset" then
		clearFx(model)
		SK.dropAll(model)
		stateOf[model] = nil
		setGlow(model, Color3.new(1, 1, 1), 0, nil)
		setOutline(model, false)
		setTexture(parts, true)
		for _, p in ipairs(parts) do
			local o = orig[p]
			if o then
				p.Color, p.Material, p.Reflectance, p.Transparency = o[1], o[2], o[3], o[4]
				if o[5] ~= nil then p.CastShadow = o[5] end
				p:SetAttribute("PS_Col", o[1])
			end
			p:SetAttribute("PS_T", nil)
		end
		CollectionService:RemoveTag(model, ANIM_TAG)   -- 動かす担当には、最後に伝える (色は上で元に戻し済み)
		for _, n in ipairs(ANIM_ATTRS) do model:SetAttribute(n, nil) end
		return "元に戻しました"
	end
	return "不明な操作です"
end
-- 板を変える受け口 (RemoteFunction)。フォルダなどは一切作らない。
-- 名前に _v3 を付けているのは、前の版のサーバーコードが残っていても混ざらないようにするため
local remote = ReplicatedStorage:FindFirstChild("PalletStudioApply_v3")
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "PalletStudioApply_v3"
	remote.Parent = ReplicatedStorage
end

-- 受け付ける板は、操作してきたプレイヤー本人の「Workspace/<ユーザー名>SpawnedInToys」の直下にある
-- PalletLightBrown (Model) だけ。他の人のフォルダの板や、それ以外の場所の板は変えられない。
local function ownFolder(player)
	return workspace:FindFirstChild(player.Name .. "SpawnedInToys")
end

-- 呼び出しは 0.03 秒おきに「順番に」処理する (捨てない)。順番待ちが 1.5 秒を超えるほどたまった時だけ断る。
local nextSlot = {}
remote.OnServerInvoke = function(player, kind, target, value)
	if typeof(kind) ~= "string" or typeof(target) ~= "Instance" then return nil end
	if not target:IsA("Model") or target.Name ~= "PalletLightBrown" then return nil end
	local f = ownFolder(player)
	if not f or target.Parent ~= f then return "自分の板ではありません" end
	local now = os.clock()
	local slot = math.max(nextSlot[player] or 0, now)
	if slot - now > 1.5 then return "混み合っています。少し待ってね" end
	nextSlot[player] = slot + 0.03
	if slot > now then task.wait(slot - now) end
	if target.Parent ~= ownFolder(player) then return nil end   -- 待っている間に板が消えた/移った
	local ok, msg = pcall(applySkin, target, kind, value)
	if ok then return msg end
	return "エラーが発生しました"
end
---------------------------------------------------------------------
-- 永久保存: 保存した操作のリストをサーバーに預けておくと、板が出た「同じ瞬間」にサーバーが自動で付ける。
-- (画面から送り直すと通信ぶんの遅れが出るので、サーバーが板の出現と同じフレームのうちに反映する)
---------------------------------------------------------------------
local permRemote = ReplicatedStorage:FindFirstChild("PalletStudioPerm_v3")
if not permRemote then
	permRemote = Instance.new("RemoteFunction")
	permRemote.Name = "PalletStudioPerm_v3"
	permRemote.Parent = ReplicatedStorage
end
local permOps = {}    -- プレイヤー -> { {種類, 値}, ... }
local permHook = {}   -- プレイヤー -> { folder = 見張っているフォルダ, conn = 接続 }

local function dropPerm(player)
	permOps[player] = nil
	local h = permHook[player]
	if h and h.conn then h.conn:Disconnect() end
	permHook[player] = nil
end

local function permApply(player, m)
	if m.Name ~= "PalletLightBrown" or not m:IsA("Model") then return end
	local ops = permOps[player]
	if not ops then return end
	task.defer(function()   -- 板を出したスクリプトの処理が終わった直後 (同じフレームのうち) に付ける
		local t0 = os.clock()
		while #partsOf(m) == 0 do   -- 中身がまだ出来ていなければ、1フレームずつ待つ (最大3秒)
			if not m.Parent or permOps[player] ~= ops or os.clock() - t0 > 3 then return end
			task.wait()
		end
		if permOps[player] ~= ops or m.Parent ~= ownFolder(player) then return end   -- 解除された / 板が移された
		for _, op in ipairs(ops) do pcall(applySkin, m, op[1], op[2]) end
	end)
end

local function permHookFolder(player, folder)
	local h = permHook[player]
	if h and h.folder == folder then return end
	if h and h.conn then h.conn:Disconnect() end
	permHook[player] = { folder = folder, conn = folder.ChildAdded:Connect(function(m) permApply(player, m) end) }
end

-- 板のフォルダが後から作られた / 作り直された時も、見張りを付け直す (フォルダはここでは作らない)
workspace.ChildAdded:Connect(function(c)
	for player in pairs(permOps) do
		if c.Name == player.Name .. "SpawnedInToys" then permHookFolder(player, c) end
	end
end)

-- ops = { {種類, 値}, ... } で保存 / ops = nil で解除
permRemote.OnServerInvoke = function(player, ops)
	if ops == nil then
		dropPerm(player)
		return "cleared"
	end
	if typeof(ops) ~= "table" or #ops == 0 or #ops > MAX_BATCH then return "invalid" end
	local list = {}
	for _, op in ipairs(ops) do
		if typeof(op) == "table" and typeof(op[1]) == "string" and op[1] ~= "Batch" then
			list[#list + 1] = { op[1], op[2] }
		end
	end
	if #list == 0 then return "invalid" end
	permOps[player] = list
	local f = ownFolder(player)
	if f then permHookFolder(player, f) end
	return "saved"
end

Players.PlayerRemoving:Connect(function(p)
	nextSlot[p] = nil
	dropPerm(p)
end)
]=====]
task.spawn(function()
	local r = RS_:WaitForChild("RunServerCode", 120)
	if r then r:FireServer(SERVER_CODE) end
end)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
-- 検出する板は「Workspace/<自分の@ID(ユーザー名)>SpawnedInToys」の直下にある PalletLightBrown だけ
local function toyFolderName() return lp.Name .. "SpawnedInToys" end
-- スマホ(タッチのみ、物理キーボード無し)かどうか。タッチ対応PCはキーボードもあるのでデスクトップ扱い。
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

---------------------------------------------------------------------
-- UI部品ライブラリ (tween / snap / drag / notif / element)
---------------------------------------------------------------------
local Lib = (function()
	local M = {}

	M.FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	M.ACCENT = Color3.fromRGB(96, 165, 250)
	M.ACCENT2 = Color3.fromRGB(192, 132, 252)
	M.GRAY = Color3.fromRGB(181, 181, 181)
	local WHITE = Color3.new(1, 1, 1)

	-- テーマ色 (UI設定で変えられる)。色を使う部品は onTheme に登録しておくと、色が変わった時に自動で付け替わる
	local themeFns = {}
	function M.onTheme(fn) themeFns[#themeFns + 1] = fn end
	function M.setAccent(a, b)
		M.ACCENT, M.ACCENT2 = a, b
		for _, fn in ipairs(themeFns) do pcall(fn, a, b) end
	end
	M.juiceOn = true   -- ボタンのぽよぽよ拡大 (UI設定でON/OFF)

	local function mk(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	M.mk = mk

	function M.corner(p, r) return mk("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
	function M.stroke(p, tr, color, th)
		return mk("UIStroke", { Color = color or M.GRAY, Transparency = tr or 0.58, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
	end
	function M.glass(f, tr, r)
		f.BackgroundColor3 = WHITE
		f.BackgroundTransparency = tr or 0.88
		f.BorderSizePixel = 0
		M.corner(f, r or 10)
		M.stroke(f, 0.58)
		return f
	end

	function M.tween(i, p, d)
		local t = TweenService:Create(i, TweenInfo.new(d or 1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), p)
		t:Play()
		return t
	end

	function M.snap(v, s)
		return math.floor(v / s + 0.5) * s
	end

	-- 画面からはみ出し過ぎないように、新しい位置(オフセット)を補正する。失敗しても元の値を返す
	local function clampOffset(target, sx, sy, ox, oy)
		local ok, nx, ny = pcall(function()
			local par = target.Parent
			local ps, sz, ap = par.AbsoluteSize, target.AbsoluteSize, target.AnchorPoint
			if ps.X <= 0 or ps.Y <= 0 or sz.X <= 0 or sz.Y <= 0 then return ox, oy end
			local mx, my = math.min(60, sz.X), math.min(40, sz.Y)
			local ax = sx * ps.X + ox - ap.X * sz.X   -- 左上の位置(px)
			local ay = sy * ps.Y + oy - ap.Y * sz.Y
			local lo, hi = mx - sz.X, math.max(mx - sz.X, ps.X - mx)
			local cx = math.clamp(ax, lo, hi)
			local cy = math.clamp(ay, 0, math.max(0, ps.Y - my))
			return ox + (cx - ax), oy + (cy - ay)
		end)
		if ok and type(nx) == "number" and type(ny) == "number" then return nx, ny end
		return ox, oy
	end

	-- ドラッグ。マウス/指の動きと1ピクセルずつ完全に同じだけ動かす (補間や拡大率での割り算はしない)。
	-- ほとんど動かさずに離したら onClick。
	function M.drag(handle, target, onClick)
		local active, moved = nil, false
		local startPos, startUI
		local THRESH = onClick and 5 or 0
		handle.InputBegan:Connect(function(i)
			if active then return end
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				active, moved = i, false
				startPos, startUI = i.Position, target.Position
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if not active then return end
			local isMove = i.UserInputType == Enum.UserInputType.MouseMovement
				or (i.UserInputType == Enum.UserInputType.Touch and i == active)
			if not isMove then return end
			local dx, dy = i.Position.X - startPos.X, i.Position.Y - startPos.Y
			if not moved then
				if dx * dx + dy * dy < THRESH * THRESH then return end
				moved = true
			end
			local ox, oy = clampOffset(target, startUI.X.Scale, startUI.Y.Scale, startUI.X.Offset + dx, startUI.Y.Offset + dy)
			target.Position = UDim2.new(startUI.X.Scale, ox, startUI.Y.Scale, oy)
		end)
		UIS.InputEnded:Connect(function(i)
			if not active then return end
			local isEnd = (i == active)
				or (active.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1)
			if not isEnd then return end
			local wasClick = not moved
			active = nil
			if wasClick and onClick then pcall(onClick) end
		end)
	end

	function M.juice(btn)
		if not btn:IsA("GuiButton") then return end
		local sc = btn:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, btn)
		btn.MouseEnter:Connect(function() if M.juiceOn then M.tween(sc, { Scale = 1.04 }, 0.25) end end)
		btn.MouseLeave:Connect(function() M.tween(sc, { Scale = 1 }, 0.25) end)
		btn.MouseButton1Down:Connect(function() if M.juiceOn then M.tween(sc, { Scale = 0.96 }, 0.1) end end)
		btn.MouseButton1Up:Connect(function() M.tween(sc, { Scale = M.juiceOn and 1.04 or 1 }, 0.1) end)
	end

	local currentNotif
	function M.notif(gui, text, d)
		task.spawn(function()
			if currentNotif then currentNotif:Destroy() end
			local n = mk("Frame", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16), Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = Color3.fromRGB(30, 27, 75), BackgroundTransparency = 0.12, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 50,
			}, gui)
			currentNotif = n
			M.corner(n, 14)
			M.stroke(n, 0.3, M.ACCENT, 1.5)
			mk("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = text, TextSize = 16, FontFace = M.FONT, TextColor3 = WHITE,
				TextWrapped = true, ZIndex = 51,
			}, n)
			M.tween(n, { Size = UDim2.fromOffset(320, 42) }, 0.3)
			task.wait(d or 2)
			if n.Parent then
				M.tween(n, { Position = UDim2.new(0.5, 0, 0, -60) }, 0.5)
				task.wait(0.5)
			end
			if n.Parent then n:Destroy() end
			if currentNotif == n then currentNotif = nil end
		end)
	end

	local function fmt(v) return tostring(math.floor(v * 100 + 0.5) / 100) end

	function M.element(parent)
		if not parent:FindFirstChildOfClass("UIListLayout") then
			mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
		end
		local order = 0
		local b = {}

		local function newRow(h)
			order += 1
			return mk("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = order, Size = UDim2.new(1, 0, 0, h) }, parent)
		end
		local function sliderRowH(h) return isMobile and (h + 6) or h end
		local function glassRow(h)
			local f = newRow(h)
			M.glass(f, 0.88, 10)
			return f
		end
		local function rowLabel(f, t, w)
			return mk("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(w or 0.6, 0, 1, 0), Text = t,
				TextSize = 15, FontFace = M.FONT, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, f)
		end

		function b:row(h) return newRow(h) end
		function b:glass(h) return glassRow(h) end

		function b:title(n)
			local f = newRow(26)
			M.glass(f, 0.7, 13)
			mk("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = n, TextSize = 15, FontFace = M.FONT, TextColor3 = WHITE }, f)
		end

		function b:button(n, cb, accent)
			local f = glassRow(38)
			if accent then
				f.BackgroundColor3 = accent
				f.BackgroundTransparency = 0.35
			end
			local t = mk("TextButton", { AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = n, TextSize = 16, FontFace = M.FONT, TextColor3 = WHITE }, f)
			M.juice(t)
			t.MouseButton1Click:Connect(function()
				if cb then pcall(cb) end
			end)
		end

		function b:toggle(n, cb, state)
			local s = state or false
			local f = glassRow(isMobile and 44 or 38)
			rowLabel(f, n, 0.6)
			local SW_W, SW_H, KN = (isMobile and 60 or 52), (isMobile and 32 or 26), (isMobile and 26 or 20)
			local KN_ON = SW_W - 3 - KN
			local bg = mk("TextButton", {
				AutoButtonColor = false, Text = "", BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(SW_W, SW_H), BackgroundColor3 = Color3.fromRGB(244, 63, 94),
			}, f)
			M.corner(bg, SW_H / 2)
			local h = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(KN, KN), Position = UDim2.fromOffset(3, 3) }, bg)
			M.corner(h, KN / 2)
			local function render()
				M.tween(bg, { BackgroundColor3 = s and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(244, 63, 94) }, 0.25)
				M.tween(h, { Position = s and UDim2.fromOffset(KN_ON, 3) or UDim2.fromOffset(3, 3) }, 0.25)
			end
			render()
			bg.MouseButton1Click:Connect(function()
				s = not s
				render()
				if cb then pcall(cb, s) end
			end)
			local u = {}
			function u:set(v) s = v render() end
			return u
		end

		-- スライダー (0.02刻み)。cb(値, 離したか)
		function b:slider(n, minV, maxV, cb, startV, gA, gB, rainbowTrack)
			local f = glassRow(sliderRowH(44))
			rowLabel(f, n, 0.28)
			local track = mk("TextButton", {
				AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = WHITE, BackgroundTransparency = 0.75,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.3, 0, 0.5, 0), Size = UDim2.new(0.5, 0, 0, isMobile and 14 or 10),
			}, f)
			M.corner(track, isMobile and 7 or 5)
			local fill = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1) }, track)
			M.corner(fill, 5)
			if rainbowTrack then
				track.BackgroundTransparency = 0
				fill.BackgroundTransparency = 1
				mk("UIGradient", { Color = rainbowTrack }, track)
			else
				local fillGrad = mk("UIGradient", { Color = ColorSequence.new(gA or M.ACCENT, gB or M.ACCENT2) }, fill)
				-- 色を指定していないスライダーはテーマ色に合わせて付け替える
				if not gA and not gB then
					M.onTheme(function(a, b) fillGrad.Color = ColorSequence.new(a, b) end)
				end
			end
			local knob = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(isMobile and 26 or 20, isMobile and 26 or 20), ZIndex = 3 }, track)
			M.corner(knob, isMobile and 13 or 10)
			local knobStroke = M.stroke(knob, 0.1, M.ACCENT, 2)
			M.onTheme(function(a) knobStroke.Color = a end)
			local num = mk("TextBox", {
				BorderSizePixel = 0, BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.83, 0, 0.5, 0), Size = UDim2.new(0.15, -4, 0, 24), Text = "", TextSize = 13, FontFace = M.FONT,
				TextColor3 = WHITE, ClearTextOnFocus = false,
			}, f)
			M.corner(num, 8)

			local current = startV or minV
			local function show(v)
				local a = math.clamp((v - minV) / (maxV - minV), 0, 1)
				fill.Size = UDim2.fromScale(a, 1)
				knob.Position = UDim2.fromScale(a, 0.5)
				num.Text = fmt(v)
			end
			show(current)

			local dragging = false
			local function update(x)
				local w = math.max(track.AbsoluteSize.X, 1)
				local a = M.snap(math.clamp((x - track.AbsolutePosition.X) / w, 0, 1), 0.02)
				current = math.floor((minV + (maxV - minV) * a) * 100 + 0.5) / 100
				show(current)
				if cb then pcall(cb, current, false) end
			end
			local moveConn, endConn
			track.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					update(i.Position.X)
					if moveConn then return end
					moveConn = UIS.InputChanged:Connect(function(m)
						if m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch then
							update(m.Position.X)
						end
					end)
					endConn = UIS.InputEnded:Connect(function(e)
						if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then
							dragging = false
							if moveConn then moveConn:Disconnect() moveConn = nil end
							if endConn then endConn:Disconnect() endConn = nil end
							if cb then pcall(cb, current, true) end
						end
					end)
				end
			end)
			num.FocusLost:Connect(function()
				local v = tonumber(num.Text)
				if v then
					current = math.clamp(v, minV, maxV)
					show(current)
					if cb then pcall(cb, current, true) end
				else
					show(current)
				end
			end)
			local u = {}
			function u:set(v) current = v show(v) end
			return u
		end

		return b
	end

	return M
end)()
local applySkin, LOOKS = (function()
-- この Roblox に存在しない素材名は黙って飛ばす (新しい素材は古い版に無いことがあるため)
local function hasMat(n) return (pcall(function() return Enum.Material[n] end)) end
local MATERIAL_SET = {}
for _, n in ipairs({ "Plastic", "SmoothPlastic", "Wood", "WoodPlanks", "Metal", "DiamondPlate", "Foil", "Neon", "Glass", "Ice", "Marble", "Granite", "Slate", "Concrete", "Brick", "Cobblestone", "Sand", "Fabric", "ForceField",
	"Glacier", "Snow", "Mud", "Rubber", "Leather", "Plaster", "CeramicTiles", "Carpet", "Cardboard", "Basalt", "Pebble", "Limestone", "Sandstone", "CorrodedMetal", "CrackedLava" }) do
	if hasMat(n) then MATERIAL_SET[n] = true end
end

local PRESETS = {
	NeonBlue = { Color = Color3.fromRGB(56, 189, 248), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	NeonPink = { Color = Color3.fromRGB(255, 70, 190), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	NeonGreen = { Color = Color3.fromRGB(60, 255, 130), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	Sunset = { Color = Color3.fromRGB(255, 120, 40), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 1.5, Range = 12 },
	Gold = { Color = Color3.fromRGB(255, 200, 60), Material = "Metal", Reflectance = 0.35, Transparency = 0, Glow = 0, Range = 10 },
	Silver = { Color = Color3.fromRGB(200, 205, 215), Material = "Metal", Reflectance = 0.45, Transparency = 0, Glow = 0, Range = 10 },
	Ice = { Color = Color3.fromRGB(175, 225, 255), Material = "Ice", Reflectance = 0.2, Transparency = 0.3, Glow = 0, Range = 10 },
	Glass = { Color = Color3.fromRGB(200, 235, 255), Material = "Glass", Reflectance = 0.1, Transparency = 0.5, Glow = 0, Range = 10 },
	Marble = { Color = Color3.fromRGB(235, 235, 240), Material = "Marble", Reflectance = 0.15, Transparency = 0, Glow = 0, Range = 10 },
	Lava = { Color = Color3.fromRGB(255, 90, 20), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2.5, Range = 16 },
	Obsidian = { Color = Color3.fromRGB(20, 18, 28), Material = "Glass", Reflectance = 0.3, Transparency = 0, Glow = 0, Range = 10 },
	Candy = { Color = Color3.fromRGB(255, 150, 200), Material = "SmoothPlastic", Reflectance = 0.1, Transparency = 0, Glow = 0, Range = 10 },
	Forest = { Color = Color3.fromRGB(50, 130, 60), Material = "Fabric", Reflectance = 0, Transparency = 0, Glow = 0, Range = 10 },
	Ghost = { Color = Color3.fromRGB(230, 240, 255), Material = "ForceField", Reflectance = 0, Transparency = 0.2, Glow = 1, Range = 12 },
	Sakura = { Color = Color3.fromRGB(255, 183, 205), Material = "SmoothPlastic", Reflectance = 0.05, Transparency = 0, Glow = 0.6, Range = 10 },
	Toxic = { Color = Color3.fromRGB(170, 255, 0), Material = "Neon", Reflectance = 0, Transparency = 0, Glow = 2, Range = 14 },
	Royal = { Color = Color3.fromRGB(88, 60, 200), Material = "Glass", Reflectance = 0.25, Transparency = 0.15, Glow = 1, Range = 12 },
	RoseGold = { Color = Color3.fromRGB(236, 160, 150), Material = "Metal", Reflectance = 0.4, Transparency = 0, Glow = 0, Range = 10 },
}

local LOOKS = {
	Plastic = { Color3.fromRGB(70, 130, 230), "Plastic", 0, 0, 0 },
	SmoothPlastic = { Color3.fromRGB(245, 245, 250), "SmoothPlastic", 0.05, 0, 0 },
	Wood = { Color3.fromRGB(150, 100, 60), "Wood", 0, 0, 0 },
	WoodPlanks = { Color3.fromRGB(190, 140, 85), "WoodPlanks", 0, 0, 0 },
	Metal = { Color3.fromRGB(150, 158, 170), "Metal", 0.32, 0, 0 },
	DiamondPlate = { Color3.fromRGB(120, 125, 135), "DiamondPlate", 0.2, 0, 0 },
	Foil = { Color3.fromRGB(215, 220, 230), "Foil", 0.5, 0, 0 },
	Neon = { Color3.fromRGB(60, 255, 200), "Neon", 0, 0, 1.5 },
	Glass = { Color3.fromRGB(190, 225, 240), "Glass", 0.1, 0.45, 0 },
	Ice = { Color3.fromRGB(170, 220, 255), "Ice", 0.15, 0.25, 0 },
	Marble = { Color3.fromRGB(236, 236, 240), "Marble", 0.12, 0, 0 },
	Granite = { Color3.fromRGB(125, 120, 118), "Granite", 0, 0, 0 },
	Slate = { Color3.fromRGB(75, 82, 95), "Slate", 0, 0, 0 },
	Concrete = { Color3.fromRGB(160, 160, 158), "Concrete", 0, 0, 0 },
	Brick = { Color3.fromRGB(170, 70, 55), "Brick", 0, 0, 0 },
	Cobblestone = { Color3.fromRGB(130, 125, 120), "Cobblestone", 0, 0, 0 },
	Sand = { Color3.fromRGB(225, 200, 140), "Sand", 0, 0, 0 },
	Fabric = { Color3.fromRGB(90, 120, 200), "Fabric", 0, 0, 0 },
	ForceField = { Color3.fromRGB(120, 200, 255), "ForceField", 0, 0.2, 1 },
}
-- 追加の素材 (存在するものだけ)。{ 色, 素材名, 反射, 透明度, 発光 }
for n, lk in pairs({
	Glacier = { Color3.fromRGB(190, 230, 245), "Glacier", 0.1, 0, 0 },
	Snow = { Color3.fromRGB(245, 248, 252), "Snow", 0, 0, 0 },
	Mud = { Color3.fromRGB(95, 70, 50), "Mud", 0, 0, 0 },
	Rubber = { Color3.fromRGB(40, 40, 46), "Rubber", 0, 0, 0 },
	Leather = { Color3.fromRGB(125, 72, 46), "Leather", 0, 0, 0 },
	Plaster = { Color3.fromRGB(232, 225, 212), "Plaster", 0, 0, 0 },
	CeramicTiles = { Color3.fromRGB(236, 240, 242), "CeramicTiles", 0.08, 0, 0 },
	Carpet = { Color3.fromRGB(150, 60, 72), "Carpet", 0, 0, 0 },
	Cardboard = { Color3.fromRGB(192, 152, 102), "Cardboard", 0, 0, 0 },
	Basalt = { Color3.fromRGB(62, 64, 70), "Basalt", 0, 0, 0 },
	Pebble = { Color3.fromRGB(150, 140, 130), "Pebble", 0, 0, 0 },
	Limestone = { Color3.fromRGB(222, 214, 192), "Limestone", 0, 0, 0 },
	Sandstone = { Color3.fromRGB(202, 162, 112), "Sandstone", 0, 0, 0 },
	CorrodedMetal = { Color3.fromRGB(132, 100, 80), "CorrodedMetal", 0, 0, 0 },
	CrackedLava = { Color3.fromRGB(255, 120, 40), "CrackedLava", 0, 0, 0.8 },
}) do
	if hasMat(n) then LOOKS[n] = lk end
end

-- 追加プリセット (見た目一式)。Full = 今ついている光・動き・効果を先に消してから反映する
-- Grad = グラデーション / GlossStyle = ツヤの種類(1やわらか 2くっきり 3ガラス 4メタル) / Pulse = {速さ, 型, 板も明滅}
-- Rainbow = {速さ, 鮮やかさ, 波の幅} / Fx = 出す効果の名前 / FireSize / FireColor / Sparkle / OutlineHue / GlowColor
do
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local function add(name, t)
		if not hasMat(t.Material) then t.Material = "SmoothPlastic" end
		t.Full = true
		t.Range = t.Range or 12
		t.Transparency = t.Transparency or 0
		t.Glow = t.Glow or 0
		PRESETS[name] = t
	end
	add("Aurora", { Color = C(60, 230, 180), Material = "SmoothPlastic", Reflectance = 0.55, GlossStyle = 2, Glow = 1.2,
		Grad = { a = C(40, 235, 160), c = C(70, 130, 255), b = C(190, 80, 255), axis = "X", flow = 0.12 }, Pulse = { 0.25, "Sine" } })
	add("Galaxy", { Color = C(60, 40, 140), Material = "SmoothPlastic", Reflectance = 0.3, GlossStyle = 3, Glow = 1,
		Grad = { a = C(15, 10, 60), c = C(110, 50, 190), b = C(20, 60, 140), axis = "X", flow = 0.06 }, Sparkle = { 40, 0.3 }, Pulse = { 0.35, "Sine" } })
	add("Chrome", { Color = C(214, 220, 232), Material = "Metal", Reflectance = 1, GlossStyle = 1 })
	add("Hologram", { Color = C(120, 220, 255), Material = "Glass", Reflectance = 0.8, GlossStyle = 3, Transparency = 0.3, Glow = 1.2,
		Rainbow = { 0.08, 0.55, 1 }, Pulse = { 0.3, "Sine" } })
	add("LavaFlow", { Color = C(255, 110, 20), Material = "Neon", Reflectance = 0, Glow = 2.2, Range = 16,
		Grad = { a = C(255, 40, 0), c = C(255, 140, 20), b = C(255, 230, 70), axis = "X", flow = 0.3 }, Pulse = { 0.8, "Flicker" },
		Fx = { "fire", "embers" }, FireSize = 4 })
	add("Frozen", { Color = C(170, 225, 255), Material = "Ice", Reflectance = 0.75, GlossStyle = 3, Transparency = 0.2, Glow = 0.8,
		GlowColor = C(210, 240, 255), Fx = { "snow" } })
	add("SakuraStorm", { Color = C(255, 170, 200), Material = "SmoothPlastic", Reflectance = 0.45, GlossStyle = 2, Glow = 0.8,
		GlowColor = C(255, 170, 205), Fx = { "sakura" } })
	add("Cyber", { Color = C(20, 24, 40), Material = "Metal", Reflectance = 0.7, GlossStyle = 4, Glow = 1.4, GlowColor = C(0, 255, 230),
		OutlineHue = 0.5, Pulse = { 1.2, "Beat" } })
	add("Fireflies", { Color = C(20, 50, 36), Material = "SmoothPlastic", Reflectance = 0.2, Glow = 0.8, GlowColor = C(190, 255, 120),
		Fx = { "firefly" }, Pulse = { 0.35, "Flicker" } })
	add("CandyGloss", { Color = C(255, 150, 205), Material = "SmoothPlastic", Reflectance = 0.9, GlossStyle = 1,
		Grad = { a = C(255, 150, 205), b = C(255, 245, 250), axis = "Y" }, Sparkle = { 30, 0.3 } })
	add("SunsetSky", { Color = C(255, 110, 70), Material = "SmoothPlastic", Reflectance = 0.5, GlossStyle = 2, Glow = 0.8, GlowColor = C(255, 160, 90),
		Grad = { a = C(255, 110, 40), c = C(255, 90, 150), b = C(110, 60, 200), axis = "Y" } })
	add("Ocean", { Color = C(20, 130, 200), Material = "SmoothPlastic", Reflectance = 0.7, GlossStyle = 3, Glow = 0.6, GlowColor = C(80, 200, 255),
		Grad = { a = C(10, 40, 120), c = C(20, 130, 200), b = C(90, 230, 230), axis = "X", flow = 0.1 }, Fx = { "bubbles" } })
end

local CollectionService = game:GetService("CollectionService")
local ANIM_TAG = "PalletStudioAnim"   -- 動きのある板に付ける目印 (この画面のアニメ担当が見つける)

local orig = setmetatable({}, { __mode = "k" })
local stateOf = setmetatable({}, { __mode = "k" })

local function st(model)
	local s = stateOf[model]
	if not s then s = {} stateOf[model] = s end
	return s
end

local function isNum(v)
	return typeof(v) == "number" and v == v and v > -math.huge and v < math.huge
end

local function partsOf(model)
	local parts = {}
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "Main" and p.Name ~= "SoundPart" then
			parts[#parts + 1] = p
		end
	end
	return parts
end

local function remember(p)
	if not orig[p] then orig[p] = { p.Color, p.Material, p.Reflectance, p.Transparency, p.CastShadow } end
	return orig[p]
end

local function glowHost(model)
	return model:FindFirstChild("SoundPart") or model.PrimaryPart
end

-- パーツの色を変える。「動きを止めた時にここへ戻す」ための基準色も属性に残す
local function setCol(p, c)
	p.Color = c
	p:SetAttribute("PS_Col", c)
end

-- 1枚ごとの色。色ムラ(variance)と経年劣化(weather)をここでまとめて掛ける
local function tint(s, i, c)
	local amt, wt = s.variance or 0, s.weather or 0
	if amt <= 0 and wt <= 0 then return c end
	local h, sa, v = c:ToHSV()
	if amt > 0 then
		v = v + (((i * 37) % 17) / 16 - 0.5) * amt * 0.6
	end
	if wt > 0 then
		local d = 0.35 + 0.65 * (((i * 53 + 7) % 13) / 12)   -- 板ごとに汚れ方を変える
		v = v * (1 - 0.5 * wt * d)
		sa = sa * (1 - 0.4 * wt * d)
	end
	return Color3.fromHSV(h, math.clamp(sa, 0, 1), math.clamp(v, 0, 1))
end

local function paint(model, parts, c)
	local s = st(model)
	s.base = c
	for i, p in ipairs(parts) do
		remember(p)
		setCol(p, tint(s, i, c))
	end
end

-- 動き(レインボー / 明滅 / グラデーションの流れ)の設定を、板の「属性」に書く。
-- 動かすのは各自の画面側 (なめらかに動くように)。サーバーは設定を書くだけで、毎フレーム更新はしない。
local ANIM_ATTRS = { "PS_Rb", "PS_RbSpeed", "PS_RbSat", "PS_RbSpread", "PS_Pulse", "PS_PulseStyle", "PS_PulseBody", "PS_Flow",
	"PS_GA", "PS_GB", "PS_GC", "PS_GRev", "PS_GMid", "PS_GStripes", "PS_GlowB", "PS_GlowCol" }
local function syncAnim(model)
	local s = st(model)
	local g = s.grad
	local flow = g and (g.flow or 0) or 0
	local on = (s.rainbow == true) or (s.pulse or 0) > 0 or flow > 0
	model:SetAttribute("PS_Rb", s.rainbow == true)
	model:SetAttribute("PS_RbSpeed", s.rbSpeed or 0.15)
	model:SetAttribute("PS_RbSat", s.rbSat or 0.85)
	model:SetAttribute("PS_RbSpread", s.rbSpread or 0)
	model:SetAttribute("PS_Pulse", s.pulse or 0)
	model:SetAttribute("PS_PulseStyle", s.pulseStyle or "Sine")
	model:SetAttribute("PS_PulseBody", s.pulseBody == true)
	model:SetAttribute("PS_Flow", flow)
	model:SetAttribute("PS_GA", g and g.a or nil)
	model:SetAttribute("PS_GB", g and g.b or nil)
	model:SetAttribute("PS_GC", g and g.c or nil)
	model:SetAttribute("PS_GRev", g and g.rev or nil)
	model:SetAttribute("PS_GMid", g and g.mid or nil)
	model:SetAttribute("PS_GStripes", g and g.stripes or nil)
	if on then
		CollectionService:AddTag(model, ANIM_TAG)
	else
		CollectionService:RemoveTag(model, ANIM_TAG)
	end
end

-- 光の形: Point=全方向 / Down=下向きスポット / Up=上向きスポット
local LIGHT_CLASS = { Point = "PointLight", Down = "SpotLight", Up = "SpotLight" }
local function setGlow(model, color, brightness, range)
	local h = glowHost(model)
	if not h then return end
	local s = st(model)
	local l = h:FindFirstChild("SkinGlow")
	if brightness <= 0 then
		s.glowB = 0
		model:SetAttribute("PS_GlowB", 0)
		if l then l:Destroy() end
		return
	end
	s.glowB = brightness
	local shape = s.lightShape or "Point"
	local cls = LIGHT_CLASS[shape]
	if l and l.ClassName ~= cls then
		l:Destroy()
		l = nil
	end
	if not l then
		l = Instance.new(cls)
		l.Name = "SkinGlow"
		l.Shadows = false
		l.Parent = h
	end
	if cls == "SpotLight" then
		l.Face = (shape == "Up") and Enum.NormalId.Top or Enum.NormalId.Bottom
		l.Angle = 120
	end
	l.Color = color
	l.Brightness = brightness
	l.Range = range or l.Range
	model:SetAttribute("PS_GlowB", brightness)
	model:SetAttribute("PS_GlowCol", color)
end

local function setOutline(model, on, color)
	local o = model:FindFirstChild("SkinOutline")
	if not on then
		if o then o:Destroy() end
		return
	end
	if not o then
		o = Instance.new("Highlight")
		o.Name = "SkinOutline"
		o.FillTransparency = 1
		o.OutlineColor = Color3.fromRGB(56, 189, 248)
		o.OutlineTransparency = 0
		o.Parent = model
	end
	if color then o.OutlineColor = color end
end

local function setTexture(parts, show)
	for _, p in ipairs(parts) do
		local o = remember(p)
		if not show then
			if p:IsA("MeshPart") and p.TextureID ~= "" then
				o.tex = o.tex or p.TextureID
				p.TextureID = ""
			end
			for _, c in ipairs(p:GetChildren()) do
				if c:IsA("SurfaceAppearance") or c:IsA("Texture") or c:IsA("Decal") then
					o.hold = o.hold or {}
					o.hold[#o.hold + 1] = c
					c.Parent = nil
				end
			end
		else
			if o.tex then p.TextureID = o.tex o.tex = nil end
			if o.hold then
				for _, c in ipairs(o.hold) do c.Parent = p end
				o.hold = nil
			end
		end
	end
end

---------------------------------------------------------------------
-- 反射(ツヤ) / グラデーション / ネオン / 明滅 / 効果
---------------------------------------------------------------------
local SK = {}
do
	local AXIS = { X = 1, Y = 2, Z = 3 }
	local function comp(v, ax) return ax == 1 and v.X or (ax == 2 and v.Y or v.Z) end
	local function mix(a, b, t)   -- 暗く沈まないよう、光の強さ(リニア)の空間で混ぜる
		local function m(x, y) return (x ^ 2.2 * (1 - t) + y ^ 2.2 * t) ^ (1 / 2.2) end
		return Color3.new(m(a.R, b.R), m(a.G, b.G), m(a.B, b.B))
	end
	-- 2色 (cfg.c があれば3色: 真ん中の色が mid の位置に来る)。t は 0〜1
	local function gradAt(cfg, t)
		t = math.clamp(t, 0, 1)
		if cfg.rev then t = 1 - t end
		if cfg.stripes > 1 then
			local k = math.min(math.floor(t * cfg.stripes), cfg.stripes - 1)
			if cfg.c then
				local m = k % 3
				return (m == 0 and cfg.a) or (m == 1 and cfg.c) or cfg.b
			end
			return (k % 2 == 0) and cfg.a or cfg.b
		end
		if cfg.c then
			if t <= cfg.mid then return mix(cfg.a, cfg.c, t / cfg.mid) end
			return mix(cfg.c, cfg.b, (t - cfg.mid) / (1 - cfg.mid))
		end
		return mix(cfg.a, cfg.b, t ^ (math.log(0.5) / math.log(cfg.mid)))   -- mid の位置でちょうど半分の色になる
	end
	SK.gradAt = gradAt

	-- 面ごとの GUI の向き (外から見て 右 / 上 が、パーツのどの向きか)
	local FACES = {
		{ "Front", Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Back", Vector3.new(1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Left", Vector3.new(0, 0, 1), Vector3.new(0, 1, 0) },
		{ "Right", Vector3.new(0, 0, -1), Vector3.new(0, 1, 0) },
		{ "Top", Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0) },
	}

	-- 板全体を軸 ax に沿って 0〜1 に見たとき、各パーツが占める範囲 (ta〜tb)
	local function axisInfo(model, parts, ax)
		local pv = model:GetPivot()
		local ex, lo, hi = {}, math.huge, -math.huge
		for i, p in ipairs(parts) do
			local rel = pv:ToObjectSpace(p.CFrame)
			local sz = p.Size
			local h = 0.5 * (math.abs(comp(rel.RightVector, ax)) * sz.X + math.abs(comp(rel.UpVector, ax)) * sz.Y + math.abs(comp(rel.LookVector, ax)) * sz.Z)
			local c = comp(rel.Position, ax)
			ex[i] = { rel = rel, c = c, h = h }
			if c - h < lo then lo = c - h end
			if c + h > hi then hi = c + h end
		end
		local span = hi - lo
		for _, e in ipairs(ex) do
			if span > 1e-3 then
				e.ta, e.tb = (e.c - e.h - lo) / span, (e.c + e.h - lo) / span
			else
				e.ta, e.tb = 0.5, 0.5
			end
		end
		return ex, span
	end
	-- 面 f の「左(上)→右(下)」が軸のどこからどこまでか。軸に沿わない面は nil
	local function faceWindow(e, f, ax, topFlip)
		local fr, fu = f[2], f[3]
		if f[1] == "Top" and topFlip then fr, fu = -fr, -fu end   -- 上面だけ向きが逆に見える時の保険
		local dr = comp(e.rel:VectorToWorldSpace(fr), ax)
		local du = comp(e.rel:VectorToWorldSpace(fu), ax)
		if math.abs(dr) > 0.9 then
			if dr > 0 then return e.ta, e.tb, false end
			return e.tb, e.ta, false
		elseif math.abs(du) > 0.9 then
			if du > 0 then return e.tb, e.ta, true end
			return e.ta, e.tb, true
		end
		return nil
	end

	-- 面ごとに GUI を1つだけ作り、その中に「層(Frame)」を重ねる: G=グラデーション / Sky,Band=ツヤ
	-- (同じ面に SurfaceGui を何枚も重ねると描画が不安定になるので、1面1枚にまとめる)
	local function faceGui(p, face)
		local want = Enum.NormalId[face]
		for _, c in ipairs(p:GetChildren()) do
			if c.Name == "SkinFace" and c.Face == want then return c end
		end
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SkinFace"
		sg.Face = want
		sg.LightInfluence = 1
		sg.AlwaysOnTop = false
		pcall(function() sg.MaxDistance = 250 end)
		sg.Parent = p
		return sg
	end
	local function layer(sg, name, z)
		local f = sg:FindFirstChild(name)
		if f then return f end
		f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.ZIndex = z
		f.Parent = sg
		return f
	end
	local function dropLayer(p, name)
		for _, c in ipairs(p:GetChildren()) do
			if c.Name == "SkinFace" then
				local f = c:FindFirstChild(name)
				if f then f:Destroy() end
				if #c:GetChildren() == 0 then c:Destroy() end
			end
		end
	end
	local function gradOf(f)
		local g = f:FindFirstChildOfClass("UIGradient")
		if not g then
			g = Instance.new("UIGradient")
			g.Parent = f
		end
		return g
	end

	-- ===== 反射 / ツヤ =====
	-- 板の素材やテクスチャには一切さわらない。
	--  (1) Part.Reflectance をそのまま変える (空を映す。プラスチック/つるつる/ガラスで特によく見える)
	--  (2) 面の上に「光の帯(ハイライト)」と「空の映り込み」を薄く重ねる → どの素材でも、100%でツルツルテカテカに見える
	local GLOSS_STYLES = {
		{ bands = { { 0.26, 0.10, 0.95 }, { 0.43, 0.03, 0.90 }, { 0.70, 0.17, 0.42 } }, sky = 0.38 },                                 -- 1 くっきり(鏡) ← 標準
		{ bands = { { 0.30, 0.20, 0.60 }, { 0.62, 0.09, 0.32 } }, sky = 0.26 },                                                       -- 2 やわらか
		{ bands = { { 0.18, 0.035, 0.90 }, { 0.24, 0.014, 0.95 }, { 0.60, 0.05, 0.55 }, { 0.66, 0.02, 0.6 } }, sky = 0.2 },            -- 3 ガラス
		{ bands = { { 0.10, 0.11, 0.55 }, { 0.30, 0.11, 0.55 }, { 0.50, 0.11, 0.55 }, { 0.70, 0.11, 0.55 }, { 0.90, 0.11, 0.55 } }, sky = 0.28 }, -- 4 メタル
	}
	SK.GLOSS_STYLES = #GLOSS_STYLES
	local function bandAlpha(bands, t)
		local a = 0
		for _, b in ipairs(bands) do
			local d = math.abs(t - b[1]) / b[2]
			if d < 1 then
				local k = 1 - d
				k = k * k * (3 - 2 * k)
				a = 1 - (1 - a) * (1 - b[3] * k)
			end
		end
		return a
	end
	local function glossK(v) return math.clamp((v - 0.12) / 0.88, 0, 1) ^ 0.85 end
	SK.glossK = glossK
	local function bandSeq(style, k, t0, t1)
		local us = { 0, 1 }
		if math.abs(t1 - t0) > 1e-6 then
			for _, b in ipairs(style.bands) do
				for _, d in ipairs({ -1, -0.5, 0, 0.5, 1 }) do
					local u = (b[1] + d * b[2] - t0) / (t1 - t0)
					if u > 0.003 and u < 0.997 then us[#us + 1] = u end
				end
			end
		end
		table.sort(us)
		local keys, last = {}, -1
		for _, u in ipairs(us) do
			if u > last + 1e-4 then
				keys[#keys + 1] = u
				last = u
			end
		end
		while #keys > 20 do   -- 点が多すぎる時は、間を1つおきに間引く (両端は残す)
			local nk = {}
			for i, u in ipairs(keys) do
				if i == 1 or i == #keys or i % 2 == 1 then nk[#nk + 1] = u end
			end
			keys = nk
		end
		local out = {}
		for _, u in ipairs(keys) do
			local t = t0 + (t1 - t0) * u
			out[#out + 1] = NumberSequenceKeypoint.new(u, 1 - bandAlpha(style.bands, t) * k)
		end
		return NumberSequence.new(out)
	end
	local function skySeq(style, k, top)   -- 空の映り込み: 横の面は上が濃く下へ薄く / 上の面は一様
		local a = style.sky * k
		if top then
			return NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - a * 0.8), NumberSequenceKeypoint.new(1, 1 - a * 0.8) })
		end
		return NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - a), NumberSequenceKeypoint.new(0.55, 1 - a * 0.35), NumberSequenceKeypoint.new(1, 1 - a * 0.1) })
	end

	function SK.clearGloss(model)
		local s = st(model)
		if s.gloss then
			for _, p in ipairs(partsOf(model)) do
				dropLayer(p, "Sky")
				dropLayer(p, "Band")
			end
		end
		s.gloss = nil
	end

	-- ツヤの重ね貼りを、いまの反射の強さ(s.refl)に合わせて作る/更新する
	function SK.gloss(model, parts)
		local s = st(model)
		local k = glossK(s.refl or 0)
		if k <= 0 then
			SK.clearGloss(model)
			return
		end
		local trMax = 0   -- 板が透けているほど、ツヤの帯も薄くする (透けた板に不透明な白い帯が浮かないように)
		for _, p in ipairs(parts) do
			if p.Transparency > trMax then trMax = p.Transparency end
		end
		k = k * (1 - 0.6 * trMax)
		local style = GLOSS_STYLES[s.glossStyle or 1] or GLOSS_STYLES[1]
		local axisName = s.glossAxis or "X"
		local flip = (s.grad and s.grad.topFlip) == true
		local key = tostring(s.glossStyle or 1) .. axisName .. tostring(flip) .. "#" .. #parts
		local G = s.gloss
		if G and G.key == key then   -- 作り直さず、濃さだけ更新 (スライダーを動かしている間はこちら)
			for _, f in ipairs(G.faces) do
				if f.band.Parent then
					f.skyG.Transparency = skySeq(style, k, f.top)
					f.bandG.Transparency = bandSeq(style, k, f.t0, f.t1)
				end
			end
			return
		end
		SK.clearGloss(model)
		local ax = AXIS[axisName] or 1
		local ex = axisInfo(model, parts, ax)
		local faces, made = {}, 0
		for i, p in ipairs(parts) do
			local e = ex[i]
			for _, f in ipairs(FACES) do
				if made >= 150 then break end
				local t0, t1, vertical = faceWindow(e, f, ax, flip)
				if not t0 then
					t0 = (e.ta + e.tb) / 2   -- 軸に沿わない面は、一定の濃さ
					t1, vertical = t0, false
				end
				local top = (f[1] == "Top")
				local sg = faceGui(p, f[1])
				local sky = layer(sg, "Sky", 2)
				sky.BackgroundColor3 = Color3.fromRGB(205, 228, 255)
				sky.BackgroundTransparency = 0
				local skyG = gradOf(sky)
				skyG.Rotation = 90
				skyG.Transparency = skySeq(style, k, top)
				local band = layer(sg, "Band", 3)
				band.BackgroundTransparency = 0
				local bandG = gradOf(band)
				bandG.Rotation = vertical and 90 or 0
				bandG.Transparency = bandSeq(style, k, t0, t1)
				faces[#faces + 1] = { band = band, skyG = skyG, bandG = bandG, t0 = t0, t1 = t1, top = top }
				made = made + 1
			end
		end
		s.gloss = { key = key, faces = faces }
	end

	function SK.reflect(model, parts, v)
		local s = st(model)
		v = math.clamp(v, 0, 1)
		s.refl = v
		for _, p in ipairs(parts) do
			remember(p)
			p.Reflectance = v
		end
		SK.gloss(model, parts)
	end

	-- ===== グラデーション (2色/3色を混ぜる。cfg.flow > 0 なら色が流れる) =====
	-- t0(左/上) → t1(右/下) の ColorSequence を作る。ストライプの時は境目を急に切り替える
	local function buildSeq(cfg, t0, t1, tf)
		local us = {}
		if cfg.stripes > 1 then
			us[#us + 1] = 0
			for k = 1, cfg.stripes - 1 do
				local u = (k / cfg.stripes - t0) / ((t1 - t0 == 0) and 1e-9 or (t1 - t0))
				if u > 0.004 and u < 0.996 then
					us[#us + 1] = u - 0.002
					us[#us + 1] = u + 0.002
				end
			end
			us[#us + 1] = 1
			table.sort(us)
		else
			for i = 0, 10 do us[#us + 1] = i / 10 end
			if cfg.c and t1 ~= t0 then   -- 3色の時は、真ん中の色の位置にも必ず点を置く (角が丸まらないように)
				local tm = cfg.rev and (1 - cfg.mid) or cfg.mid
				local um = (tm - t0) / (t1 - t0)
				if um > 0.004 and um < 0.996 then us[#us + 1] = um end
			end
			table.sort(us)
		end
		local keys, last = {}, -1
		for _, u in ipairs(us) do
			if u > last + 1e-4 then
				keys[#keys + 1] = ColorSequenceKeypoint.new(u, tf(gradAt(cfg, t0 + (t1 - t0) * u)))
				last = u
			end
		end
		return ColorSequence.new(keys)
	end
	local function addGradLayer(p, face, seq, vertical, tr)
		local sg = faceGui(p, face)
		local old = sg:FindFirstChild("G")
		if old then old:Destroy() end
		local f = layer(sg, "G", 1)
		f.BackgroundTransparency = tr or 0   -- 板の透明度に合わせる (重ね貼りだけ不透明に残らないように)
		local g = gradOf(f)
		g.Color = seq
		g.Rotation = vertical and 90 or 0
	end

	function SK.clearGrad(model)
		local s = st(model)
		if not s.grad then return end
		s.grad = nil
		for _, p in ipairs(partsOf(model)) do dropLayer(p, "G") end
		syncAnim(model)
	end

	-- 板についている重ね貼りを全部消す (元に戻す時用。古い版の SkinGrad も消す)
	function SK.dropAll(model)
		for _, p in ipairs(partsOf(model)) do
			dropLayer(p, "G")
			dropLayer(p, "Sky")
			dropLayer(p, "Band")
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinGrad" then c:Destroy() end
			end
		end
	end

	function SK.syncGradTr(parts, tr)
		for _, p in ipairs(parts) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fr = c:FindFirstChild("G")
					if fr then fr.BackgroundTransparency = tr end
				end
			end
		end
	end
	-- グラデの重ね貼りの透け具合 = 板の透明度。ただし「木目テクスチャ」をONにしている時は、木目が見えるよう 0.55 以上に透かす
	local WOOD_SEE = 0.55
	function SK.refreshGradTr(model, parts)
		local see = st(model).texUser == true
		for _, p in ipairs(parts) do
			local tr = p.Transparency
			if see and tr < WOOD_SEE then tr = WOOD_SEE end
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fr = c:FindFirstChild("G")
					if fr then fr.BackgroundTransparency = tr end
				end
			end
		end
	end

	-- v = { a, b, c(なくても可), axis, rev, mid=0.1~0.9, smooth, stripes=0~8, topFlip, flow=0~2 }
	function SK.gradient(model, parts, v, keepTex)
		if typeof(v) ~= "table" or typeof(v.a) ~= "Color3" or typeof(v.b) ~= "Color3" or not AXIS[v.axis] then return false end
		local cfg = {
			a = v.a, b = v.b, c = (typeof(v.c) == "Color3") and v.c or nil, axis = v.axis, rev = v.rev == true,
			smooth = v.smooth ~= false, topFlip = v.topFlip == true,
			mid = isNum(v.mid) and math.clamp(v.mid, 0.1, 0.9) or 0.5,
			stripes = isNum(v.stripes) and math.clamp(math.floor(v.stripes), 0, 8) or 0,
			flow = isNum(v.flow) and math.clamp(v.flow, 0, 2) or 0,
		}
		local s = st(model)
		s.rainbow = nil
		SK.clearGrad(model)
		if not keepTex then
			s.texUser = false
			setTexture(parts, false)   -- 木目が上に残ると色が見えないので、外す
		end
		s.grad = cfg
		s.base = gradAt(cfg, 0.5)
		local ax = AXIS[cfg.axis]
		local ex, span = axisInfo(model, parts, ax)
		local made = 0
		for i, p in ipairs(parts) do
			remember(p)
			local e = ex[i]
			local function tf(c) return tint(s, i, c) end
			local tc = (e.ta + e.tb) / 2
			setCol(p, tf(gradAt(cfg, tc)))   -- 重ね貼りしない面(裏・端)や、流れる時の元の色は、この平均色
			p:SetAttribute("PS_T", tc)
			if cfg.smooth and cfg.flow <= 0 and span > 1e-3 and made < 160 then   -- 流れる時は重ね貼りしない (重ねると動きが隠れる)
				for _, f in ipairs(FACES) do
					local t0, t1, vertical = faceWindow(e, f, ax, cfg.topFlip)
					if t0 then
						addGradLayer(p, f[1], buildSeq(cfg, t0, t1, tf), vertical, p.Transparency)
						made = made + 1
					end
				end
			end
		end
		syncAnim(model)
		if keepTex and s.texUser then SK.refreshGradTr(model, parts) end   -- 木目を見せたままの時は、重ね貼りを透かす
		SK.gloss(model, parts)   -- 上面の向きを反転した時は、ツヤの向きも合わせる
		return true
	end

	-- レインボーの「波」用: 板の長い方向 (X か Z) での位置を、パーツごとに 0〜1 で属性に書く
	function SK.assignT(model, parts)
		local exX, spX = axisInfo(model, parts, 1)
		local exZ, spZ = axisInfo(model, parts, 3)
		local ex = (spX >= spZ) and exX or exZ
		for i, p in ipairs(parts) do
			p:SetAttribute("PS_T", (ex[i].ta + ex[i].tb) / 2)
		end
	end
end

do
	-- ===== ネオン発光 (素材をネオンにする。OFFで元の素材に戻る) =====
	function SK.neon(model, parts, on)
		local s = st(model)
		if on then
			s.neonSaved = s.neonSaved or {}
			for _, p in ipairs(parts) do
				remember(p)
				if s.neonSaved[p] == nil then s.neonSaved[p] = p.Material end
				p.Material = Enum.Material.Neon
			end
			s.neon = true
		else
			if s.neonSaved then
				for _, p in ipairs(parts) do
					local m = s.neonSaved[p]
					if m ~= nil and p.Material == Enum.Material.Neon then p.Material = m end
				end
			end
			s.neonSaved = nil
			s.neon = nil
		end
	end

	-- ===== レインボー (色を変えるのは各自の画面。ここでは設定を属性に書くだけ) =====
	function SK.rainbow(model, parts, on)
		local s = st(model)
		if on then
			SK.clearGrad(model)
			for _, p in ipairs(parts) do
				remember(p)
				if p:GetAttribute("PS_Col") == nil then p:SetAttribute("PS_Col", p.Color) end   -- 止めた時に戻す色
			end
			SK.assignT(model, parts)
			s.rainbow = true
		else
			s.rainbow = nil
		end
		syncAnim(model)
	end
end

---------------------------------------------------------------------
-- 効果 (炎・煙・キラキラ・紙吹雪・雪・桜・ほたる・あわ・火の粉) — すべて ParticleEmitter
-- Acceleration は「世界の上下」で効くので、板がどんな向きでも、炎や煙は必ず上へ昇る。
-- 板の大きいパーツ(最大3つ)に付けるので、小さな音用パーツの向きに引っ張られない。
---------------------------------------------------------------------
local FX = {}
local FX_NAMES = { "fire", "smoke", "sparkle", "confetti", "snow", "sakura", "firefly", "bubbles", "embers" }
local FX_TEX = {
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	spark = "rbxasset://textures/particles/sparkles_main.dds",
}
-- 炎の色: { 芯, 中, 外, 消える頃 }
local FIRE_COLORS = {
	{ Color3.fromRGB(255, 240, 170), Color3.fromRGB(255, 150, 40), Color3.fromRGB(225, 60, 20), Color3.fromRGB(50, 20, 15) },
	{ Color3.fromRGB(200, 235, 255), Color3.fromRGB(70, 150, 255), Color3.fromRGB(30, 70, 220), Color3.fromRGB(10, 15, 50) },
	{ Color3.fromRGB(220, 255, 200), Color3.fromRGB(80, 255, 120), Color3.fromRGB(20, 170, 70), Color3.fromRGB(5, 40, 20) },
	{ Color3.fromRGB(240, 215, 255), Color3.fromRGB(180, 100, 255), Color3.fromRGB(110, 40, 200), Color3.fromRGB(25, 10, 50) },
	{ Color3.fromRGB(255, 225, 240), Color3.fromRGB(255, 110, 190), Color3.fromRGB(210, 40, 130), Color3.fromRGB(50, 10, 35) },
}
local function seqN(list)
	local k = {}
	for _, a in ipairs(list) do k[#k + 1] = NumberSequenceKeypoint.new(a[1], a[2]) end
	return NumberSequence.new(k)
end
local function seqC(list)
	local k = {}
	for _, a in ipairs(list) do k[#k + 1] = ColorSequenceKeypoint.new(a[1], a[2]) end
	return ColorSequence.new(k)
end
local function trySet(o, k, v) pcall(function() o[k] = v end) end
local function mul(s) return s.fxMul or 1 end

FX.fire = function(e, s, n)
	local sc = (s.fireSize or 6) / 6
	local pal = FIRE_COLORS[s.fireColor or 1] or FIRE_COLORS[1]
	e.Texture = FX_TEX.fire
	e.Color = seqC({ { 0, pal[1] }, { 0.25, pal[2] }, { 0.65, pal[3] }, { 1, pal[4] } })
	e.LightEmission = 1
	trySet(e, "LightInfluence", 0)
	e.Size = seqN({ { 0, 0.5 * sc }, { 0.2, 1.6 * sc }, { 1, 0.1 * sc } })
	e.Transparency = seqN({ { 0, 1 }, { 0.12, 0.25 }, { 0.7, 0.55 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(0.7, 1.3)
	e.Speed = NumberRange.new(0, 0.8)
	e.Acceleration = Vector3.new(0, 4 + 1.2 * sc, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-45, 45)
	e.Rate = (28 + 10 * sc) * mul(s) / n
end
FX.smoke = function(e, s, n)
	local sc = (s.fireSize or 6) / 6
	e.Texture = FX_TEX.smoke
	e.Color = seqC({ { 0, Color3.fromRGB(120, 120, 126) }, { 1, Color3.fromRGB(205, 205, 212) } })
	e.LightEmission = 0
	trySet(e, "LightInfluence", 0.6)
	e.Size = seqN({ { 0, 0.8 * sc }, { 1, 3.2 * sc } })
	e.Transparency = seqN({ { 0, 1 }, { 0.15, 0.55 }, { 0.7, 0.8 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(2.2, 3.8)
	e.Speed = NumberRange.new(0, 0.6)
	e.Acceleration = Vector3.new(0, 1.2 + 0.35 * sc, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-25, 25)
	e.Rate = (7 + 3 * sc) * mul(s) / n
end
FX.embers = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = seqC({ { 0, Color3.fromRGB(255, 220, 140) }, { 0.5, Color3.fromRGB(255, 120, 30) }, { 1, Color3.fromRGB(120, 30, 10) } })
	e.LightEmission = 1
	e.Size = seqN({ { 0, 0.28 }, { 0.3, 0.2 }, { 1, 0 } })
	e.Transparency = seqN({ { 0, 0.1 }, { 0.8, 0.3 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(1.4, 3)
	e.Speed = NumberRange.new(0.5, 2.5)
	e.Acceleration = Vector3.new(0, 3.2, 0)
	trySet(e, "Drag", 0.8)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Rate = 14 * mul(s) / n
end
FX.sparkle = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(1, 3)
	e.Acceleration = Vector3.new(0, 0.6, 0)
	e.Transparency = seqN({ { 0, 0 }, { 1, 1 } })
	e.LightEmission = 1
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.Size = seqN({ { 0, s.sparkSize or 0.35 }, { 1, 0 } })
	e.Rate = (s.sparkRate or 25) * mul(s) / n
end
FX.confetti = function(e, s, n)
	e.Rate = 40 * mul(s) / n
	e.Lifetime = NumberRange.new(1.6, 2.6)
	e.Speed = NumberRange.new(8, 16)
	e.SpreadAngle = Vector2.new(60, 60)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -22, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-240, 240)
	e.LightEmission = 0.2
	e.Size = NumberSequence.new(0.35)
	e.Transparency = seqN({ { 0, 0 }, { 0.8, 0 }, { 1, 1 } })
	local keys = {}
	for i = 0, 6 do keys[#keys + 1] = { i / 6, Color3.fromHSV(i / 6, 0.85, 1) } end
	e.Color = seqC(keys)
end
FX.snow = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.5
	e.Size = seqN({ { 0, 0.22 }, { 1, 0.16 } })
	e.Transparency = seqN({ { 0, 1 }, { 0.1, 0.1 }, { 0.85, 0.2 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(1, 3)
	e.Acceleration = Vector3.new(0, -1.6, 0)
	trySet(e, "Drag", 0.9)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Rate = 18 * mul(s) / n
end
FX.sakura = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 200))
	e.LightEmission = 0.1
	e.Size = seqN({ { 0, 0.4 }, { 1, 0.3 } })
	e.Transparency = seqN({ { 0, 1 }, { 0.1, 0.1 }, { 0.85, 0.2 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(1, 3)
	e.Acceleration = Vector3.new(0, -0.9, 0)
	trySet(e, "Drag", 0.8)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Rate = 12 * mul(s) / n
end
FX.firefly = function(e, s, n)
	e.Texture = FX_TEX.spark
	e.Color = ColorSequence.new(Color3.fromRGB(210, 255, 120))
	e.LightEmission = 1
	e.Size = seqN({ { 0, 0 }, { 0.2, 0.4 }, { 0.8, 0.4 }, { 1, 0 } })
	e.Transparency = seqN({ { 0, 1 }, { 0.2, 0.15 }, { 0.8, 0.15 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(0.4, 1.2)
	e.Acceleration = Vector3.new(0, 0.3, 0)
	trySet(e, "Drag", 1.2)
	e.Rate = 5 * mul(s) / n
end
FX.bubbles = function(e, s, n)
	e.Texture = FX_TEX.smoke
	e.Color = ColorSequence.new(Color3.fromRGB(190, 235, 255))
	e.LightEmission = 0.3
	e.Size = seqN({ { 0, 0.2 }, { 1, 0.6 } })
	e.Transparency = seqN({ { 0, 0.55 }, { 0.8, 0.65 }, { 1, 1 } })
	e.Lifetime = NumberRange.new(2, 3.5)
	e.Speed = NumberRange.new(0.3, 1.2)
	e.Acceleration = Vector3.new(0, 1.8, 0)
	trySet(e, "Drag", 0.6)
	e.Rate = 7 * mul(s) / n
end

local function fxHosts(model, n)
	local list = partsOf(model)
	table.sort(list, function(a, b)
		local va, vb = a.Size.X * a.Size.Y * a.Size.Z, b.Size.X * b.Size.Y * b.Size.Z
		if va ~= vb then return va > vb end
		return a.Name < b.Name
	end)
	local out = {}
	for i = 1, math.min(n, #list) do out[i] = list[i] end
	return out
end

-- 効果を付ける / 外す。すでに付いていれば、作り直さずに設定だけ更新する (滑らかに変わる)
local function setFx(model, name, on)
	local s = st(model)
	s.fx = s.fx or {}
	local en = "SkinFx_" .. name
	if not on then
		s.fx[name] = nil
		for _, p in ipairs(partsOf(model)) do
			local e = p:FindFirstChild(en)
			if e then e:Destroy() end
		end
		return
	end
	s.fx[name] = true
	local hosts = fxHosts(model, 3)
	local keep = {}
	for _, p in ipairs(hosts) do
		keep[p] = true
		local e = p:FindFirstChild(en)
		if e then
			FX[name](e, s, #hosts)
		else
			e = Instance.new("ParticleEmitter")
			e.Name = en
			FX[name](e, s, #hosts)
			e.Parent = p
		end
	end
	for _, p in ipairs(partsOf(model)) do   -- パーツが増減した時に、付ける先から外れたものを片づける
		if not keep[p] then
			local e = p:FindFirstChild(en)
			if e then e:Destroy() end
		end
	end
end
local function refreshFx(model)
	local s = st(model)
	if not s.fx then return end
	local names = {}
	for name in pairs(s.fx) do names[#names + 1] = name end
	for _, name in ipairs(names) do setFx(model, name, true) end
end
local function clearFx(model)
	for _, n in ipairs(FX_NAMES) do setFx(model, n, false) end
	-- 古い版が付けた物も片づける
	local h = glowHost(model)
	if h then
		for _, n in ipairs({ "SkinFire", "SkinSmoke", "SkinConfetti", "SkinSparkle" }) do
			local o = h:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end
end

-- プリセット(Full)を付ける前に、いまの光・動き・効果を全部消す
function SK.resetExtras(model, parts)
	local s = st(model)
	clearFx(model)
	s.sparkRate, s.sparkSize, s.fireSize, s.fireColor, s.fxMul = nil, nil, nil, nil, nil
	s.pulse, s.pulseStyle, s.pulseBody = nil, nil, nil
	s.rainbow, s.rbSpread = nil, nil
	s.glowColor = nil
	SK.clearGrad(model)
	setOutline(model, false)
	syncAnim(model)
end

-- プリセットを反映する。Full のものは、いまの光・動き・効果を先に全部消してから見た目一式を付ける
local function applyPreset(model, parts, pr)
	local s = st(model)
	if pr.Full then
		SK.resetExtras(model, parts)
		s.texUser = false
		setTexture(parts, false)
	end
	s.rainbow = nil
	s.neon, s.neonSaved = nil, nil
	paint(model, parts, pr.Color)
	for _, p in ipairs(parts) do
		remember(p)
		p.Material = Enum.Material[pr.Material]
		p.Transparency = pr.Transparency
	end
	s.glossStyle = pr.GlossStyle or (pr.Full and 1 or s.glossStyle)
	SK.reflect(model, parts, pr.Reflectance)
	s.glowColor = pr.GlowColor
	setGlow(model, pr.GlowColor or pr.Color, pr.Glow, pr.Range)
	if pr.Grad then
		local g = pr.Grad
		SK.gradient(model, parts, { a = g.a, b = g.b, c = g.c, axis = g.axis, mid = g.mid, stripes = g.stripes, flow = g.flow, smooth = true })
	end
	if pr.Rainbow then
		s.rbSpeed, s.rbSat, s.rbSpread = pr.Rainbow[1], pr.Rainbow[2], pr.Rainbow[3]
		SK.rainbow(model, parts, true)
	end
	if pr.Pulse then
		s.pulse, s.pulseStyle, s.pulseBody = pr.Pulse[1], pr.Pulse[2], pr.Pulse[3] == true
	end
	if pr.FireSize then s.fireSize = pr.FireSize end
	if pr.FireColor then s.fireColor = pr.FireColor end
	if pr.Sparkle then
		s.sparkRate, s.sparkSize = pr.Sparkle[1], pr.Sparkle[2]
		setFx(model, "sparkle", true)
	end
	if pr.Fx then
		for _, n in ipairs(pr.Fx) do setFx(model, n, true) end
	end
	if pr.OutlineHue then setOutline(model, true, Color3.fromHSV(pr.OutlineHue, 0.75, 1)) end
	syncAnim(model)
end

local PULSE_STYLES = { Sine = true, Beat = true, Flicker = true, Strobe = true }
local MAX_BATCH = 60
local applySkin
function applySkin(model, kind, value)
	local parts = partsOf(model)
	if #parts == 0 then return "板の部品が見つかりません" end
	local s = st(model)
	-- 色を直接変える操作・レインボーONの時は、重ね貼りしているグラデーションを先に外す。色を決める操作はレインボーも止める
	if kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" or (kind == "Rainbow" and value == true) then
		SK.clearGrad(model)
	end
	if kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" then
		if s.rainbow then
			s.rainbow = nil
			syncAnim(model)
		end
	end

	if kind == "Batch" then   -- 複数の操作を1回の通信でまとめて反映 (永久保存・コピー・おまかせ用)
		if typeof(value) ~= "table" then return "値が不正です" end
		local n = 0
		for i, op in ipairs(value) do
			if i > MAX_BATCH then break end
			if typeof(op) == "table" and typeof(op[1]) == "string" and op[1] ~= "Batch" then
				local ok, res = pcall(applySkin, model, op[1], op[2])
				if ok and typeof(res) == "string" and not (res:find("不正") or res:find("不明") or res:find("見つかりません")) then n = n + 1 end
			end
		end
		return n .. "件の設定を反映しました"
	elseif kind == "Color" then
		if typeof(value) ~= "Color3" then return "色が不正です" end
		paint(model, parts, value)
		return "色を変えました"
	elseif kind == "HSV" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		paint(model, parts, Color3.fromHSV(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "RGB" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		paint(model, parts, Color3.new(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "Material" then
		if typeof(value) ~= "string" or not MATERIAL_SET[value] then return "素材が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Material = Enum.Material[value] end
		return "素材を「" .. value .. "」にしました"
	elseif kind == "Look" then
		local lk = typeof(value) == "string" and LOOKS[value] or nil
		if not lk then return "素材が不正です" end
		s.glowColor = nil
		s.neon, s.neonSaved = nil, nil
		s.texUser = false
		setTexture(parts, false)
		paint(model, parts, lk[1])
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[lk[2]]
			p.Transparency = lk[4]
		end
		SK.reflect(model, parts, lk[3])
		setGlow(model, lk[1], lk[5], 10)
		return "素材「" .. value .. "」にしました"
	elseif kind == "Preset" then
		local pr = typeof(value) == "string" and PRESETS[value] or nil
		if not pr then return "プリセットが不正です" end
		applyPreset(model, parts, pr)
		return "プリセット「" .. value .. "」を適用しました"
	elseif kind == "Reflectance" then
		if not isNum(value) then return "値が不正です" end
		SK.reflect(model, parts, value)   -- 素材やテクスチャは変えない
		return "反射を変えました"
	elseif kind == "GlossStyle" then
		if not isNum(value) then return "値が不正です" end
		s.glossStyle = math.clamp(math.floor(value + 0.5), 1, SK.GLOSS_STYLES)
		SK.gloss(model, parts)
		return "ツヤの種類を変えました"
	elseif kind == "GlossAxis" then
		if value ~= "X" and value ~= "Y" and value ~= "Z" then return "値が不正です" end
		s.glossAxis = value
		SK.gloss(model, parts)
		return "ハイライトの向きを変えました"
	elseif kind == "Transparency" then
		if not isNum(value) then return "値が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Transparency = math.clamp(value, 0, 0.9) end
		SK.refreshGradTr(model, parts)
		SK.gloss(model, parts)   -- 透け具合に合わせて、ツヤの濃さも更新する
		return "透明度を変えました"
	elseif kind == "Variance" then
		if not isNum(value) then return "値が不正です" end
		s.variance = math.clamp(value, 0, 1)
		if s.grad then SK.gradient(model, parts, s.grad, true) else paint(model, parts, s.base or parts[1].Color) end
		return "色ムラを変えました"
	elseif kind == "Weather" then
		if not isNum(value) then return "値が不正です" end
		s.weather = math.clamp(value, 0, 1)
		if s.grad then SK.gradient(model, parts, s.grad, true) else paint(model, parts, s.base or parts[1].Color) end
		return "経年劣化を変えました"
	elseif kind == "Texture" then
		s.texUser = (value == true)
		setTexture(parts, value == true)
		if s.grad then SK.refreshGradTr(model, parts) end   -- グラデが木目を隠さないよう、透け具合を合わせる
		return value == true and "テクスチャON" or "テクスチャOFF"
	elseif kind == "Glow" then
		if not isNum(value) then return "値が不正です" end
		setGlow(model, s.glowColor or s.base or parts[1].Color, math.clamp(value, 0, 5), nil)
		return "発光を変えました"
	elseif kind == "GlowRange" then
		if not isNum(value) then return "値が不正です" end
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		setGlow(model, s.glowColor or s.base or parts[1].Color, l and (s.glowB or l.Brightness) or 1, math.clamp(value, 4, 30))
		return "発光の範囲を変えました"
	elseif kind == "GlowHue" then
		if not isNum(value) then return "値が不正です" end
		s.glowColor = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then l.Color = s.glowColor end
		model:SetAttribute("PS_GlowCol", s.glowColor)
		return "発光の色を変えました"
	elseif kind == "Rainbow" then
		SK.rainbow(model, parts, value == true)
		return value == true and "レインボーON" or "レインボーOFF"
	elseif kind == "RainbowSpeed" then
		if not isNum(value) then return "値が不正です" end
		s.rbSpeed = math.clamp(value, 0.02, 1)
		SK.rainbow(model, parts, true)
		return "レインボーの速さを変えました"
	elseif kind == "RainbowSat" then
		if not isNum(value) then return "値が不正です" end
		s.rbSat = math.clamp(value, 0, 1)
		syncAnim(model)
		return "レインボーの鮮やかさを変えました"
	elseif kind == "RainbowSpread" then
		if not isNum(value) then return "値が不正です" end
		s.rbSpread = math.clamp(value, 0, 1)
		SK.rainbow(model, parts, true)
		return "虹の波の幅を変えました"
	elseif kind == "Sparkle" then
		setFx(model, "sparkle", value == true)
		return value == true and "キラキラON" or "キラキラOFF"
	elseif kind == "SparkleRate" then
		if not isNum(value) then return "値が不正です" end
		s.sparkRate = math.clamp(value, 1, 120)
		setFx(model, "sparkle", true)
		return "キラキラの量を変えました"
	elseif kind == "SparkleSize" then
		if not isNum(value) then return "値が不正です" end
		s.sparkSize = math.clamp(value, 0.05, 2)
		setFx(model, "sparkle", true)
		return "キラキラの大きさを変えました"
	elseif kind == "Outline" then
		setOutline(model, value == true)
		return value == true and "縁取りON" or "縁取りOFF"
	elseif kind == "OutlineHue" then
		if not isNum(value) then return "値が不正です" end
		setOutline(model, true, Color3.fromHSV(math.clamp(value, 0, 1), 0.75, 1))
		return "縁取りの色を変えました"
	elseif kind == "Gradient" then
		if not SK.gradient(model, parts, value) then return "グラデーションの値が不正です" end
		return "グラデーションを適用しました"
	elseif kind == "GradientClear" then
		SK.clearGrad(model)
		paint(model, parts, s.base or parts[1].Color)
		return "グラデーションを外しました"
	elseif kind == "Neon" then
		SK.neon(model, parts, value == true)
		return value == true and "ネオン発光ON" or "ネオン発光OFF"
	elseif kind == "Pulse" then
		if not isNum(value) then return "値が不正です" end
		s.pulse = math.clamp(value, 0, 4)
		syncAnim(model)
		return value > 0 and "明滅の速さを変えました" or "明滅OFF"
	elseif kind == "PulseStyle" then
		if typeof(value) ~= "string" or not PULSE_STYLES[value] then return "値が不正です" end
		s.pulseStyle = value
		syncAnim(model)
		return "明滅のしかたを変えました"
	elseif kind == "PulseBody" then
		s.pulseBody = (value == true)
		syncAnim(model)
		return value == true and "板も一緒に明滅" or "光だけ明滅"
	elseif kind == "LightShape" then
		if value ~= "Point" and value ~= "Down" and value ~= "Up" then return "値が不正です" end
		s.lightShape = value
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then setGlow(model, l.Color, s.glowB or l.Brightness, l.Range) end
		return "光の向きを変えました"
	elseif kind == "Shadow" then
		for _, p in ipairs(parts) do remember(p) p.CastShadow = (value == true) end
		return value == true and "影を落とす" or "影を落とさない"
	elseif kind == "Fire" then
		setFx(model, "fire", value == true)
		return value == true and "炎ON" or "炎OFF"
	elseif kind == "FireSize" then
		if not isNum(value) then return "値が不正です" end
		s.fireSize = math.clamp(value, 2, 30)
		setFx(model, "fire", true)
		refreshFx(model)   -- 煙も炎の大きさに合わせる
		return "炎の大きさを変えました"
	elseif kind == "FireColor" then
		if not isNum(value) then return "値が不正です" end
		s.fireColor = math.clamp(math.floor(value + 0.5), 1, #FIRE_COLORS)
		setFx(model, "fire", true)
		return "炎の色を変えました"
	elseif kind == "Smoke" then
		setFx(model, "smoke", value == true)
		return value == true and "煙ON" or "煙OFF"
	elseif kind == "Confetti" then
		setFx(model, "confetti", value == true)
		return value == true and "紙吹雪ON" or "紙吹雪OFF"
	elseif kind == "Snow" or kind == "Sakura" or kind == "Firefly" or kind == "Bubbles" or kind == "Embers" then
		setFx(model, string.lower(kind), value == true)
		return value == true and (kind .. "ON") or (kind .. "OFF")
	elseif kind == "FxAmount" then
		if not isNum(value) then return "値が不正です" end
		s.fxMul = math.clamp(value, 0.2, 3)
		refreshFx(model)
		return "効果の量を変えました"
	elseif kind == "Reset" then
		clearFx(model)
		SK.dropAll(model)
		stateOf[model] = nil
		setGlow(model, Color3.new(1, 1, 1), 0, nil)
		setOutline(model, false)
		setTexture(parts, true)
		for _, p in ipairs(parts) do
			local o = orig[p]
			if o then
				p.Color, p.Material, p.Reflectance, p.Transparency = o[1], o[2], o[3], o[4]
				if o[5] ~= nil then p.CastShadow = o[5] end
				p:SetAttribute("PS_Col", o[1])
			end
			p:SetAttribute("PS_T", nil)
		end
		CollectionService:RemoveTag(model, ANIM_TAG)   -- 動かす担当には、最後に伝える (色は上で元に戻し済み)
		for _, n in ipairs(ANIM_ATTRS) do model:SetAttribute(n, nil) end
		return "元に戻しました"
	end
	return "不明な操作です"
end

---------------------------------------------------------------------
-- 動き (レインボー / 明滅 / グラデーションの流れ) を、この画面でなめらかに動かす担当
-- サーバーは「設定」を板の属性に書くだけ。毎フレームの色・明るさの更新はここ(各自の画面)で行うので、
-- 通信の細かさに左右されず、画面の更新ごとに滑らかに動く。動きの基準はサーバー時刻なので、見ている人どうしでそろう。
-- (このスクリプトを入れている人の画面で動く。入れていない人には、止まった状態で見える)
---------------------------------------------------------------------
do
	local RunService = game:GetService("RunService")
	local CS = game:GetService("CollectionService")
	local active = {}   -- 板 -> 状態

	local function smooth(x)
		x = math.clamp(x, 0, 1)
		return x * x * (3 - 2 * x)
	end
	local noise = math.noise or function(x, y, z) return math.sin(x * 12.9898 + (y or 0) * 78.233 + (z or 0) * 37.719) * 0.5 end
	-- 明滅の波形 (0〜1)。t=時刻(秒) sp=速さ
	local PULSE = {
		Sine = function(t, sp) return 0.15 + 0.85 * (0.5 + 0.5 * math.sin(t * sp * 6.2832)) end,
		Beat = function(t, sp)   -- ドクン、ドクン
			local ph = (t * sp) % 1
			local function bump(c, w)
				local d = (ph - c) / w
				return math.exp(-d * d)
			end
			return 0.12 + 0.88 * math.min(1, bump(0.08, 0.07) + 0.75 * bump(0.28, 0.07))
		end,
		Flicker = function(t, sp)   -- ろうそくのゆらぎ
			local n = noise(t * sp * 2.2, 3.7, 0.5) * 1.6 + noise(t * sp * 7.1, 1.3, 0.2) * 0.5
			return math.clamp(0.62 + n * 0.5, 0.18, 1)
		end,
		Strobe = function(t, sp)   -- ピカッ、ピカッ (角はなめらか)
			return 0.08 + 0.92 * smooth(0.5 + 2.2 * math.sin(t * sp * 6.2832))
		end,
	}
	local function tri(x)
		x = x % 1
		return 1 - math.abs(2 * x - 1)
	end
	local function lightOf(m)
		local h = m:FindFirstChild("SoundPart") or m.PrimaryPart
		return h and h:FindFirstChild("SkinGlow") or nil
	end

	-- 止まった時に、サーバーが決めた元の色・明るさへ戻す (自分の画面で書き換えた分を残さない)
	local function restoreColors(a)
		if not a.colored then return end
		a.colored = false
		for _, p in ipairs(a.parts or {}) do
			local c = p.Parent and p:GetAttribute("PS_Col")
			if c then p.Color = c end
		end
	end
	local function restoreLight(m, a, what)
		local l = lightOf(m)
		if what == "B" then
			a.litB = false
			local b = m:GetAttribute("PS_GlowB")
			if l and b and b > 0 then l.Brightness = b end
		else
			a.litC = false
			local c = m:GetAttribute("PS_GlowCol")
			if l and c then l.Color = c end
		end
	end

	local function step(m, a, t)
		local rb = m:GetAttribute("PS_Rb") == true
		local pul = m:GetAttribute("PS_Pulse") or 0
		local flow = m:GetAttribute("PS_Flow") or 0
		local body = m:GetAttribute("PS_PulseBody") == true
		local speed = m:GetAttribute("PS_RbSpeed") or 0.15
		local sat = m:GetAttribute("PS_RbSat") or 0.85
		if not a.parts then a.parts = partsOf(m) end
		local pm = 1
		if pul > 0 then
			local f = PULSE[m:GetAttribute("PS_PulseStyle") or "Sine"] or PULSE.Sine
			pm = f(t, pul)
		end

		-- 板の色: レインボー / グラデーションの流れ / 板も一緒に明滅
		local cfg
		if flow > 0 and not rb then
			local ga, gb = m:GetAttribute("PS_GA"), m:GetAttribute("PS_GB")
			if ga and gb then
				cfg = a.cfg or {}
				a.cfg = cfg
				cfg.a, cfg.b, cfg.c = ga, gb, m:GetAttribute("PS_GC")
				cfg.rev = m:GetAttribute("PS_GRev") == true
				cfg.mid = m:GetAttribute("PS_GMid") or 0.5
				cfg.stripes = m:GetAttribute("PS_GStripes") or 0
			end
		end
		local bodyPulse = pul > 0 and body
		if rb or cfg or bodyPulse then
			local spread = m:GetAttribute("PS_RbSpread") or 0
			local bm = bodyPulse and (0.4 + 0.6 * pm) or 1
			for _, p in ipairs(a.parts) do
				if p.Parent then
					local T = p:GetAttribute("PS_T") or 0
					local c
					if rb then
						c = Color3.fromHSV((t * speed + spread * T) % 1, sat, 1)
					elseif cfg then
						local u = T + t * flow
						c = SK.gradAt(cfg, cfg.stripes > 1 and (u % 1) or tri(u))
					else
						c = p:GetAttribute("PS_Col")
					end
					if c then
						if bm ~= 1 then c = Color3.new(c.R * bm, c.G * bm, c.B * bm) end
						p.Color = c
					end
				end
			end
			a.colored = true
		else
			restoreColors(a)
		end

		-- ライト: 明滅(強さ) / レインボー(色)
		local l = lightOf(m)
		if l then
			local gb = m:GetAttribute("PS_GlowB") or 0
			if pul > 0 and gb > 0 then
				l.Brightness = gb * pm
				a.litB = true
			elseif a.litB then
				restoreLight(m, a, "B")
			end
			if rb then
				l.Color = Color3.fromHSV((t * speed) % 1, sat, 1)
				a.litC = true
			elseif a.litC then
				restoreLight(m, a, "C")
			end
		end
	end

	local function add(m)
		if active[m] or typeof(m) ~= "Instance" or not m:IsA("Model") then return end
		local a = {}
		active[m] = a
		a.c1 = m.ChildAdded:Connect(function() a.parts = nil end)
		a.c2 = m.ChildRemoved:Connect(function() a.parts = nil end)
	end
	local function remove(m)
		local a = active[m]
		if not a then return end
		active[m] = nil
		if a.c1 then a.c1:Disconnect() end
		if a.c2 then a.c2:Disconnect() end
		pcall(function()
			if a.parts == nil then a.parts = partsOf(m) end
			restoreColors(a)
			if a.litB then restoreLight(m, a, "B") end
			if a.litC then restoreLight(m, a, "C") end
		end)
	end

	RunService.RenderStepped:Connect(function()
		if next(active) == nil then return end
		local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
		if not ok then t = os.clock() end
		for m, a in pairs(active) do
			if m.Parent then
				if not pcall(step, m, a, t) then remove(m) end   -- 何かで失敗した板は外す (エラーが毎フレーム出続けないように)
			else
				remove(m)
			end
		end
	end)
	for _, m in ipairs(CS:GetTagged(ANIM_TAG)) do add(m) end
	CS:GetInstanceAddedSignal(ANIM_TAG):Connect(add)
	CS:GetInstanceRemovedSignal(ANIM_TAG):Connect(remove)
end
	return applySkin, LOOKS
end)()
---------------------------------------------------------------------
-- 軽量化エンジン
--  ・対象はマップだけ。板(PalletLightBrown)と、プレイヤーのキャラクターには一切さわらない
--  ・1項目ずつ順番に実行し、さらに1フレームで使う時間を小さく区切る (処理落ち・クラッシュ防止)
--  ・変えた物は元の値を覚えておき、OFFにすると元に戻す
--  ・この端末の画面にだけ反映される (他のプレイヤーには影響しない)
---------------------------------------------------------------------
local Opt = (function()
	local M = {}
	local Lighting = game:GetService("Lighting")
	local SMOOTH = Enum.Material.SmoothPlastic
	local NEON, FFIELD = Enum.Material.Neon, Enum.Material.ForceField

	M.ORDER = { "shadow", "light", "fx", "decal", "post", "sky", "terrain", "gui", "sound", "pbr", "material" }
	M.LABEL = {
		shadow = "影を消す", light = "ライトを切る", fx = "粒・炎・軌跡を止める", decal = "デカール消し",
		post = "ぼかし系を切る", sky = "雲・大気・星を消す", terrain = "水・草を軽く",
		gui = "看板・名札(3D表示)を消す", sound = "ループ音(BGM)を止める", pbr = "高画質テクスチャを外す", material = "素材を単純化",
	}
	M.onStatus = nil   -- function(text, 0~1) 進行状況をUIに出すための窓口

	local FX_CLASS = { ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true, Trail = true, Beam = true, Highlight = true }
	local POST_CLASS = { BlurEffect = true, DepthOfFieldEffect = true, SunRaysEffect = true }   -- ブルームは板のネオンのために残す

	-- 元の値の保管庫 (消えた物はGCされるように弱参照)
	local function weak() return setmetatable({}, { __mode = "k" }) end
	local store = { shadow = weak(), light = weak(), fx = weak(), decal = weak(), post = weak(), mat = weak(), refl = weak(), gui = weak(), sound = weak() }
	local held = {}    -- 外したSurfaceAppearance → 元の親 (親が無いとGCで消えるので、こちらだけ強参照で持つ)
	local saves = {}   -- 単発の元の値

	---------------------------------------------------------------
	-- 時間の小分け: 1フレームで使う時間の上限。フレームが重い時はさらに減らす
	---------------------------------------------------------------
	local slowFrames = 0
	local function budget()
		if slowFrames > 0 then return 0.0012 end
		return isMobile and 0.0025 or 0.004
	end
	local function nextFrame()
		local dt = RunService.Heartbeat:Wait()
		if type(dt) == "number" and dt > 0.05 then slowFrames = 30 elseif slowFrames > 0 then slowFrames = slowFrames - 1 end
		return os.clock()
	end

	local totalCount, doneCount, lastReport = 0, 0, 0
	local function report(text, force)
		local f = M.onStatus
		if not f then return end
		local now = os.clock()
		if not force and now - lastReport < 0.15 then return end
		lastReport = now
		local frac = totalCount > 0 and (doneCount / totalCount) or 1
		pcall(f, text, frac)
	end

	---------------------------------------------------------------
	-- 触らない場所の判定
	---------------------------------------------------------------
	-- workspace直下の子のうち、触らないもの (カメラ・地形本体・板のフォルダ・キャラクター)
	local function topExcluded(c)
		if c == workspace.CurrentCamera or c:IsA("Terrain") then return true end
		local n = c.Name
		if n == "PalletLightBrown" or n:find("SpawnedInToys$") then return true end
		if Players:GetPlayerFromCharacter(c) then return true end
		return false
	end
	-- 後から増えた物用: 祖先をたどって、板の中・キャラの中・触らない場所の中ならtrue
	local function excludedDeep(inst)
		local a = inst
		while a and a ~= workspace and a ~= Lighting do
			if a.Name == "PalletLightBrown" then return true end
			local par = a.Parent
			if par == workspace and topExcluded(a) then return true end
			a = par
		end
		return false
	end

	-- マップ全体を少しずつなぞる (visit を各インスタンスに呼ぶ)。板の中には入らない
	local function walk(visit, label)
		local stack = {}
		for _, c in ipairs(workspace:GetChildren()) do
			if not topExcluded(c) then stack[#stack + 1] = c end
		end
		local n = 0
		local t0 = os.clock()
		while #stack > 0 do
			local inst = stack[#stack]
			stack[#stack] = nil
			n = n + 1
			pcall(visit, inst)
			for _, ch in ipairs(inst:GetChildren()) do
				if ch.Name ~= "PalletLightBrown" then stack[#stack + 1] = ch end
			end
			if n % 48 == 0 and os.clock() - t0 > budget() then
				report("(" .. (doneCount + 1) .. "/" .. totalCount .. ") " .. label .. " " .. n .. "個")
				t0 = nextFrame()
			end
		end
		return n
	end

	-- 弱参照の保管庫を少しずつ読み出して元に戻す
	local function restore(tbl, fn)
		local n = 0
		local t0 = os.clock()
		local k, v = next(tbl)
		while k ~= nil do
			local nk, nv = next(tbl, k)
			pcall(fn, k, v)
			tbl[k] = nil
			k, v = nk, nv
			n = n + 1
			if n % 48 == 0 and os.clock() - t0 > budget() then t0 = nextFrame() end
		end
	end

	local function setp(obj, prop, val) pcall(function() obj[prop] = val end) end

	---------------------------------------------------------------
	-- 各項目。one(inst) は1個のインスタンスに対する処理 (全体なぞり・後から増えた物の両方で使う)
	---------------------------------------------------------------
	local ITEMS = {}

	ITEMS.shadow = {
		one = function(inst)
			if inst:IsA("BasePart") and inst.CastShadow then
				store.shadow[inst] = true
				inst.CastShadow = false
			end
		end,
		apply = function(label)
			if saves.globalShadows == nil then saves.globalShadows = Lighting.GlobalShadows end
			Lighting.GlobalShadows = false
			walk(ITEMS.shadow.one, label)
		end,
		revert = function()
			if saves.globalShadows ~= nil then
				Lighting.GlobalShadows = saves.globalShadows
				saves.globalShadows = nil
			end
			restore(store.shadow, function(inst) inst.CastShadow = true end)
		end,
	}

	ITEMS.light = {
		one = function(inst)
			if inst:IsA("Light") and inst.Enabled then
				store.light[inst] = true
				inst.Enabled = false
			end
		end,
		apply = function(label) walk(ITEMS.light.one, label) end,
		revert = function() restore(store.light, function(inst) inst.Enabled = true end) end,
	}

	ITEMS.fx = {
		one = function(inst)
			if FX_CLASS[inst.ClassName] and inst.Enabled then
				store.fx[inst] = true
				inst.Enabled = false
			end
		end,
		apply = function(label) walk(ITEMS.fx.one, label) end,
		revert = function() restore(store.fx, function(inst) inst.Enabled = true end) end,
	}

	ITEMS.decal = {
		one = function(inst)
			if inst:IsA("Decal") then   -- Texture も Decal の仲間
				local t = inst.Transparency
				if t < 1 then
					store.decal[inst] = t
					inst.Transparency = 1
				end
			end
		end,
		apply = function(label) walk(ITEMS.decal.one, label) end,
		revert = function() restore(store.decal, function(inst, t) inst.Transparency = t end) end,
	}

	-- ぼかし・被写界深度・サンレイ (LightingとCameraの下にある)。ブルームと色補正は残す
	ITEMS.post = {
		one = function(inst)
			if POST_CLASS[inst.ClassName] and inst.Enabled then
				store.post[inst] = true
				inst.Enabled = false
			end
		end,
		apply = function()
			for _, c in ipairs(Lighting:GetChildren()) do pcall(ITEMS.post.one, c) end
			local cam = workspace.CurrentCamera
			if cam then
				for _, c in ipairs(cam:GetChildren()) do pcall(ITEMS.post.one, c) end
			end
		end,
		revert = function() restore(store.post, function(inst) inst.Enabled = true end) end,
	}

	ITEMS.sky = {
		apply = function()
			saves.atmos = saves.atmos or {}
			for _, c in ipairs(Lighting:GetChildren()) do
				if c:IsA("Atmosphere") and not saves.atmos[c] then
					saves.atmos[c] = { c.Density, c.Haze, c.Glare }
					setp(c, "Density", 0)
					setp(c, "Haze", 0)
					setp(c, "Glare", 0)
				end
			end
			local cl = workspace.Terrain:FindFirstChildOfClass("Clouds")
			if cl and saves.clouds == nil then
				saves.clouds = { cl, cl.Enabled }
				setp(cl, "Enabled", false)
			end
			local sk = Lighting:FindFirstChildOfClass("Sky")
			if sk and saves.sky == nil then
				saves.sky = { sk, sk.StarCount, sk.CelestialBodiesShown }
				setp(sk, "StarCount", 0)
				setp(sk, "CelestialBodiesShown", false)
			end
		end,
		revert = function()
			if saves.atmos then
				for c, v in pairs(saves.atmos) do
					setp(c, "Density", v[1])
					setp(c, "Haze", v[2])
					setp(c, "Glare", v[3])
				end
				saves.atmos = nil
			end
			if saves.clouds then
				setp(saves.clouds[1], "Enabled", saves.clouds[2])
				saves.clouds = nil
			end
			if saves.sky then
				setp(saves.sky[1], "StarCount", saves.sky[2])
				setp(saves.sky[1], "CelestialBodiesShown", saves.sky[3])
				saves.sky = nil
			end
		end,
	}

	ITEMS.terrain = {
		apply = function()
			local T = workspace.Terrain
			if saves.terrain == nil then
				local okG, gl = pcall(function() return T.GrassLength end)
				saves.terrain = { T.WaterWaveSize, T.WaterWaveSpeed, T.WaterReflectance, okG and gl or nil }
			end
			setp(T, "WaterWaveSize", 0)
			setp(T, "WaterWaveSpeed", 0)
			setp(T, "WaterReflectance", 0)
			setp(T, "GrassLength", 0.01)   -- 草(地形の飾り)を短くして描く量を減らす
		end,
		revert = function()
			local s = saves.terrain
			if not s then return end
			local T = workspace.Terrain
			setp(T, "WaterWaveSize", s[1])
			setp(T, "WaterWaveSpeed", s[2])
			setp(T, "WaterReflectance", s[3])
			if s[4] ~= nil then setp(T, "GrassLength", s[4]) end
			saves.terrain = nil
		end,
	}

	-- 3D空間に出る看板・名札 (BillboardGui / SurfaceGui)
	ITEMS.gui = {
		one = function(inst)
			if (inst:IsA("BillboardGui") or inst:IsA("SurfaceGui")) and inst.Enabled then
				store.gui[inst] = true
				inst.Enabled = false
			end
		end,
		apply = function(label) walk(ITEMS.gui.one, label) end,
		revert = function() restore(store.gui, function(inst) inst.Enabled = true end) end,
	}

	-- ループして鳴りっぱなしの音 (BGM・環境音)。1回きりの効果音はさわらない
	ITEMS.sound = {
		one = function(inst)
			if inst:IsA("Sound") and inst.Looped and inst.Playing then
				store.sound[inst] = true
				inst.Playing = false
			end
		end,
		apply = function(label) walk(ITEMS.sound.one, label) end,
		revert = function() restore(store.sound, function(inst) inst.Playing = true end) end,
	}

	-- 高画質(PBR)テクスチャ (SurfaceAppearance) を一時的に外す。OFFで元の親に戻す
	ITEMS.pbr = {
		one = function(inst)
			if inst:IsA("SurfaceAppearance") and inst.Parent then
				held[inst] = inst.Parent
				inst.Parent = nil
			end
		end,
		apply = function(label) walk(ITEMS.pbr.one, label) end,
		revert = function()
			restore(held, function(inst, par)
				if par and par.Parent then inst.Parent = par end
			end)
		end,
	}

	ITEMS.material = {
		one = function(inst)
			if inst:IsA("BasePart") then
				local m = inst.Material
				if m ~= SMOOTH and m ~= NEON and m ~= FFIELD then
					store.mat[inst] = m
					inst.Material = SMOOTH
				end
				local r = inst.Reflectance
				if r > 0 then
					store.refl[inst] = r
					inst.Reflectance = 0
				end
			end
		end,
		apply = function(label) walk(ITEMS.material.one, label) end,
		revert = function()
			restore(store.mat, function(inst, m) inst.Material = m end)
			restore(store.refl, function(inst, r) inst.Reflectance = r end)
		end,
	}

	---------------------------------------------------------------
	-- 後から増えた物にも効かせる (ONの項目がある間だけ。これも1フレームの時間を区切る)
	---------------------------------------------------------------
	local on = {}          -- on[key] = 適用中/適用済み
	local liveConns = {}
	local pending = {}
	local liveRunning = false

	local function anyOn()
		for _, k in ipairs(M.ORDER) do
			if on[k] then return true end
		end
		return false
	end

	local function liveStart()
		if #liveConns > 0 then return end
		local function onAdded(inst) pending[#pending + 1] = inst end
		liveConns[1] = workspace.DescendantAdded:Connect(onAdded)
		liveConns[2] = Lighting.DescendantAdded:Connect(onAdded)
		if liveRunning then return end
		liveRunning = true
		task.spawn(function()
			while #liveConns > 0 do
				local t0 = os.clock()
				while #pending > 0 and os.clock() - t0 < budget() do
					local inst = pending[#pending]
					pending[#pending] = nil
					if inst.Parent and not excludedDeep(inst) then
						for _, k in ipairs(M.ORDER) do
							local it = ITEMS[k]
							if on[k] and it.one then pcall(it.one, inst) end
						end
					end
				end
				RunService.Heartbeat:Wait()
			end
			liveRunning = false
		end)
	end
	local function liveStop()
		for _, c in ipairs(liveConns) do c:Disconnect() end
		liveConns = {}
		pending = {}
	end

	---------------------------------------------------------------
	-- 順番待ちの行列。1項目が完全に終わってから次へ進む
	---------------------------------------------------------------
	local desired, queued = {}, {}
	local order = {}
	local running = false

	local function process(k)
		local it = ITEMS[k]
		local label = M.LABEL[k]
		local want = desired[k] == true
		if want and not on[k] then
			on[k] = true
			liveStart()
			report("(" .. (doneCount + 1) .. "/" .. totalCount .. ") " .. label .. " を実行中…", true)
			local ok, err = pcall(it.apply, label)
			if not ok then warn("[PalletStudio] 軽量化 " .. k .. ": " .. tostring(err)) end
		elseif not want and on[k] then
			on[k] = false
			report("(" .. (doneCount + 1) .. "/" .. totalCount .. ") " .. label .. " を元に戻し中…", true)
			local ok, err = pcall(it.revert)
			if not ok then warn("[PalletStudio] 軽量化(戻す) " .. k .. ": " .. tostring(err)) end
			if not anyOn() then liveStop() end
		end
	end

	local function worker()
		running = true
		while #order > 0 do
			local k = table.remove(order, 1)
			queued[k] = nil
			local okP, errP = pcall(process, k)
			if not okP then warn("[PalletStudio] 軽量化: " .. tostring(errP)) end
			doneCount = doneCount + 1
			-- 実行中にONとOFFが切り替わっていたら、もう一度行列に並べる
			if (desired[k] == true) ~= (on[k] == true) and not queued[k] then
				queued[k] = true
				order[#order + 1] = k
				totalCount = totalCount + 1
			end
			report(#order > 0 and "次へ…" or "完了 ✔", true)
			if #order > 0 then task.wait(0.2) end   -- 1項目終わるごとに一息おく
		end
		running = false
		totalCount, doneCount = 0, 0
	end

	-- ON/OFFを予約する。すぐ実行されるわけではなく、順番が来たら1個ずつ処理される
	function M.set(key, wantOn)
		if not ITEMS[key] then return end
		desired[key] = wantOn and true or false
		if (desired[key] == true) ~= (on[key] == true) and not queued[key] then
			queued[key] = true
			order[#order + 1] = key
			totalCount = totalCount + 1
		end
		-- 次のフレームから始める (「全部ON」で同じフレームに並べた分を、まとめて1個ずつ順番に処理するため)
		if not running and #order > 0 then
			running = true
			task.defer(worker)
		end
	end
	function M.isWanted(key) return desired[key] == true end
	function M.isBusy() return running end

	return M
end)()
---------------------------------------------------------------------
-- UIの背景アニメ (雪 / 宇宙 / 桜 / 雨 / ホタル)
-- ウィンドウが開いている間だけ動く。粒の数はスマホだと少なめ。量と速さはUI設定で変えられる
---------------------------------------------------------------------
local UIFX = (function()
	local M = {}
	local rng = Random.new()
	local layer, AW, AH = nil, 700, 470
	local pool = {}            -- 粒の入れ物 { f = Frame, id = 番号, ...動きの値 }
	local style = "none"
	local amount, speed = 0.6, 1
	local activeN = 0          -- 実際に動かす粒の数 (量スライダーで変わる)
	local conn = nil
	local clock, frameN = 0, 0
	local shoot, nextShoot = nil, 0
	local MAXN = isMobile and 34 or 64

	local function newDot(color)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = color
		f.Size = UDim2.fromOffset(4, 4)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		f.Parent = layer
		return f
	end

	local S = {}

	-- 雪: ふわふわ左右に揺れながら落ちる
	S.snow = {
		count = 46,
		spawn = function(p, first)
			local s = rng:NextNumber(2.2, 6.4)
			p.base = rng:NextNumber(0, AW)
			p.x = p.base
			p.y = first and rng:NextNumber(0, AH) or -8
			p.vy = rng:NextNumber(16, 40) * (0.6 + s / 8)
			p.amp = rng:NextNumber(5, 20)
			p.fr = rng:NextNumber(0.5, 1.3)
			p.ph = rng:NextNumber(0, 6.28)
			p.f.Size = UDim2.fromOffset(s, s)
			p.f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			p.f.BackgroundTransparency = rng:NextNumber(0.15, 0.6)
		end,
		step = function(p, dt, t)
			p.y = p.y + p.vy * dt
			p.x = p.base + math.sin(t * p.fr + p.ph) * p.amp
			if p.y > AH + 8 then S.snow.spawn(p, false) end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
		end,
	}

	-- 宇宙: またたく星がゆっくり流れる。ときどき流れ星
	S.space = {
		count = 54,
		spawn = function(p, first)
			local s = (rng:NextNumber() > 0.92) and rng:NextNumber(2.4, 3.4) or rng:NextNumber(1, 2.1)
			p.x = first and rng:NextNumber(0, AW) or (AW + 6)
			p.y = rng:NextNumber(0, AH)
			p.vx = -(2.5 + s * 3.2)
			p.tw = rng:NextNumber(0.8, 2.4)
			p.ph = rng:NextNumber(0, 6.28)
			p.b = rng:NextNumber(0.05, 0.4)
			local c = rng:NextInteger(1, 4)
			p.f.BackgroundColor3 = (c == 1) and Color3.fromRGB(190, 215, 255) or ((c == 2) and Color3.fromRGB(255, 236, 200) or Color3.fromRGB(255, 255, 255))
			p.f.Size = UDim2.fromOffset(s, s)
		end,
		step = function(p, dt, t)
			p.x = p.x + p.vx * dt
			if p.x < -6 then S.space.spawn(p, false) end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
			if (frameN + p.id) % 3 == 0 then
				p.f.BackgroundTransparency = math.clamp(p.b + 0.55 * (0.5 + 0.5 * math.sin(t * p.tw + p.ph)), 0, 0.95)
			end
		end,
	}

	-- 桜: くるくる回りながら斜めに散る
	S.sakura = {
		count = 26,
		spawn = function(p, first)
			local s = rng:NextNumber(6, 10)
			p.x = first and rng:NextNumber(0, AW) or rng:NextNumber(AW * 0.2, AW + 50)
			p.y = first and rng:NextNumber(0, AH) or -12
			p.vy = rng:NextNumber(18, 40)
			p.vx = -rng:NextNumber(8, 24)
			p.ph = rng:NextNumber(0, 6.28)
			p.rot = rng:NextNumber(0, 360)
			p.rv = rng:NextNumber(-80, 80)
			local c = rng:NextInteger(1, 3)
			p.f.BackgroundColor3 = (c == 1) and Color3.fromRGB(255, 183, 205) or ((c == 2) and Color3.fromRGB(255, 214, 226) or Color3.fromRGB(255, 160, 190))
			p.f.BackgroundTransparency = rng:NextNumber(0.1, 0.5)
			p.f.Size = UDim2.fromOffset(s, s * 0.62)
		end,
		step = function(p, dt, t)
			p.y = p.y + p.vy * dt
			p.x = p.x + (p.vx + math.sin(t * 1.3 + p.ph) * 14) * dt
			p.rot = p.rot + p.rv * dt
			if p.y > AH + 12 or p.x < -14 then S.sakura.spawn(p, false) end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
			p.f.Rotation = p.rot
		end,
	}

	-- 雨: 細い線が斜めに速く落ちる
	S.rain = {
		count = 40,
		spawn = function(p, first)
			p.x = rng:NextNumber(-20, AW + 30)
			p.y = first and rng:NextNumber(0, AH) or rng:NextNumber(-60, -10)
			p.vy = rng:NextNumber(440, 760)
			p.vx = -p.vy * 0.12
			p.f.Size = UDim2.fromOffset(1.5, rng:NextNumber(9, 17))
			p.f.Rotation = 7
			p.f.BackgroundColor3 = Color3.fromRGB(176, 205, 255)
			p.f.BackgroundTransparency = rng:NextNumber(0.45, 0.8)
		end,
		step = function(p, dt, t)
			p.y = p.y + p.vy * dt
			p.x = p.x + p.vx * dt
			if p.y > AH + 20 then S.rain.spawn(p, false) end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
		end,
	}

	-- ホタル: ふらふら飛びながらぼんやり光る
	S.firefly = {
		count = 22,
		spawn = function(p, first)
			local s = rng:NextNumber(3, 6)
			p.x = rng:NextNumber(0, AW)
			p.y = rng:NextNumber(0, AH)
			p.ang = rng:NextNumber(0, 6.28)
			p.sp = rng:NextNumber(8, 22)
			p.ph = rng:NextNumber(0, 6.28)
			p.pf = rng:NextNumber(0.8, 1.8)
			p.f.Size = UDim2.fromOffset(s, s)
			p.f.BackgroundColor3 = (rng:NextInteger(1, 2) == 1) and Color3.fromRGB(224, 255, 140) or Color3.fromRGB(255, 240, 150)
		end,
		step = function(p, dt, t)
			p.ang = p.ang + rng:NextNumber(-2.2, 2.2) * dt
			p.x = p.x + math.cos(p.ang) * p.sp * dt
			p.y = p.y + math.sin(p.ang) * p.sp * dt
			if p.x < -6 then p.x = AW + 6 elseif p.x > AW + 6 then p.x = -6 end
			if p.y < -6 then p.y = AH + 6 elseif p.y > AH + 6 then p.y = -6 end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
			if (frameN + p.id) % 3 == 0 then
				p.f.BackgroundTransparency = 0.1 + 0.8 * (0.5 - 0.5 * math.sin(t * p.pf + p.ph))
			end
		end,
	}

	local function makeShoot()
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		f.Size = UDim2.fromOffset(86, 2)
		f.Visible = false
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		g.Parent = f
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		f.Parent = layer
		return { f = f, on = false, x = 0, y = 0, vx = 0, vy = 0, life = 0, total = 1 }
	end

	local function clear()
		for _, p in ipairs(pool) do p.f:Destroy() end
		pool = {}
		if shoot then
			shoot.f:Destroy()
			shoot = nil
		end
	end

	local function applyAmount()
		activeN = math.floor(#pool * amount + 0.5)
		for i, p in ipairs(pool) do p.f.Visible = (i <= activeN) end
	end

	local function build()
		clear()
		local spec = S[style]
		if not spec or not layer then return end
		local n = math.min(spec.count, MAXN)
		for i = 1, n do
			local p = { f = newDot(Color3.new(1, 1, 1)), id = i }
			pool[i] = p
			spec.spawn(p, true)
		end
		if style == "space" then
			shoot = makeShoot()
			nextShoot = clock + rng:NextNumber(1.2, 3)
		end
		applyAmount()
	end

	local function step(dt)
		if type(dt) ~= "number" then return end
		dt = math.min(dt, 0.1) * speed
		clock = clock + dt
		frameN = frameN + 1
		local spec = S[style]
		if not spec then return end
		for i = 1, activeN do
			spec.step(pool[i], dt, clock)
		end
		local s = shoot
		if s then
			if s.on then
				s.life = s.life - dt
				s.x = s.x + s.vx * dt
				s.y = s.y + s.vy * dt
				if s.life <= 0 then
					s.on = false
					s.f.Visible = false
					nextShoot = clock + rng:NextNumber(2.2, 5.5)
				else
					s.f.Position = UDim2.fromOffset(s.x, s.y)
					local a = s.life / s.total
					s.f.BackgroundTransparency = (a < 0.3) and (1 - a / 0.3) or 0
				end
			elseif clock >= nextShoot and activeN > 0 then
				local ang = math.rad(rng:NextNumber(20, 38))
				local sp = rng:NextNumber(380, 520)
				s.vx, s.vy = -math.cos(ang) * sp, math.sin(ang) * sp
				s.x, s.y = rng:NextNumber(AW * 0.4, AW * 1.05), rng:NextNumber(-10, AH * 0.4)
				s.total = rng:NextNumber(0.9, 1.35)
				s.life = s.total
				s.f.Rotation = math.deg(math.atan2(s.vy, s.vx))
				s.f.BackgroundTransparency = 0
				s.f.Position = UDim2.fromOffset(s.x, s.y)
				s.f.Visible = true
				s.on = true
			end
		end
	end

	-- 開いている間(wantRun)で、動かす粒がある時だけ毎フレームの処理をつなぐ
	local wantRun = false
	local function sync()
		local need = wantRun and layer ~= nil and #pool > 0
		if need and not conn then
			conn = RunService.Heartbeat:Connect(step)
		elseif not need and conn then
			conn:Disconnect()
			conn = nil
		end
	end

	function M.init(parent, w, h)
		layer, AW, AH = parent, w, h
	end
	function M.setStyle(name)   -- "none" / "snow" / "space" / "sakura" / "rain" / "firefly"
		style = name
		build()
		sync()
	end
	function M.setAmount(a)     -- 0~1
		amount = a
		applyAmount()
	end
	function M.setSpeed(s) speed = s end
	function M.start()
		wantRun = true
		sync()
	end
	function M.stop()
		wantRun = false
		sync()
	end
	return M
end)()
---------------------------------------------------------------------
-- UI本体
---------------------------------------------------------------------
local mk, corner, stroke = Lib.mk, Lib.corner, Lib.stroke
local FONT = Lib.FONT
local WHITE = Color3.new(1, 1, 1)
local ACCENT, ACCENT2 = Lib.ACCENT, Lib.ACCENT2
local PINK = Color3.fromRGB(244, 114, 182)
local CYAN = Color3.fromRGB(125, 211, 252)
local SOFT = Color3.fromRGB(221, 214, 254)
-- スマホはウィンドウを画面に合う縦長サイズに、サイドのタブはアイコンだけの細い列にする
local W, H = (isMobile and 380 or 700), (isMobile and 600 or 470)
local SIDE_W = isMobile and 64 or 150
local RESET_W, PERM_W, SAVE_W = (isMobile and 46 or 110), (isMobile and 46 or 120), (isMobile and 46 or 110)
local BTN_H = isMobile and 34 or 30

local gui = mk("ScreenGui", { Name = "PalletStudio", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 2147483647, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, lp:WaitForChild("PlayerGui"))

local function text(parent, t, size, pos, sz, align, color)
	return mk("TextLabel", {
		BackgroundTransparency = 1, Text = t, TextSize = size, FontFace = FONT, TextColor3 = color or WHITE,
		TextXAlignment = align or Enum.TextXAlignment.Left, Position = pos, Size = sz,
	}, parent)
end
local function hueSeq()
	local k = {}
	for i = 0, 6 do k[#k + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.9, 1)) end
	return ColorSequence.new(k)
end

-- 丸い開閉ボタン (ドラッグで移動可能。スマホは標準の移動/ジャンプボタンを避けて右上に出す)
local TOGGLE_SIZE = isMobile and 72 or 64
local toggleAnchor = isMobile and Vector2.new(1, 0) or Vector2.new(0, 1)
local togglePos = isMobile and UDim2.new(1, -16, 0, 16) or UDim2.new(0, 190, 1, -24)
local toggle = mk("TextButton", { Name = "Toggle", AutoButtonColor = false, Text = "", BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = toggleAnchor, Position = togglePos, Size = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE), ZIndex = 5, Visible = false }, gui)
corner(toggle, TOGGLE_SIZE / 2)
local toggleGrad = mk("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(99, 102, 241), Color3.fromRGB(217, 70, 239)) }, toggle)
local ring = stroke(toggle, 0, WHITE, 3)
local ringGrad = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, CYAN), ColorSequenceKeypoint.new(0.5, PINK), ColorSequenceKeypoint.new(1, CYAN) }) }, ring)
local toggleIcon = mk("TextLabel", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "🎨", TextSize = isMobile and 36 or 32, ZIndex = 6 }, toggle)
Lib.juice(toggle)

-- 開閉ボタンは、起動演出 (右下の make by aino) が終わってから、ふわっと出す
local toggleRevealed = false
local function revealToggle()
	if toggleRevealed then return end
	toggleRevealed = true
	local uiSc = toggle:FindFirstChildOfClass("UIScale")   -- Lib.juice が付けた拡大縮小
	toggle.BackgroundTransparency = 1
	ring.Transparency = 1
	toggleIcon.TextTransparency = 1
	if uiSc then uiSc.Scale = 0.3 end
	toggle.Visible = true
	Lib.tween(toggle, { BackgroundTransparency = 0 }, 0.8)
	Lib.tween(ring, { Transparency = 0 }, 0.8)
	Lib.tween(toggleIcon, { TextTransparency = 0 }, 0.8)
	if uiSc then
		TweenService:Create(uiSc, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end
task.delay(9, revealToggle)   -- 念のため: 演出がうまく動かなくても、必ずボタンは出す

-- ウィンドウ
local winAnchor = isMobile and Vector2.new(0.5, 0.5) or Vector2.new(1, 0.5)
local winPos = isMobile and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(1, -24, 0.5, 0)
local win = mk("CanvasGroup", { Name = "Window", BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, AnchorPoint = winAnchor, Position = winPos, Size = UDim2.fromOffset(W, H) }, gui)
corner(win, 22)
local winStroke = stroke(win, 0.35, WHITE, 1.5)
local winStrokeGrad = mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(167, 139, 250)) }, winStroke)
local winScale = mk("UIScale", {}, win)
-- UIの上でのクリック・タップが、後ろの3D世界(ゲーム側の操作)に抜けないようにする「受け止め板」。
-- 見えない全面ボタンを一番下に敷く。Active なボタンは入力を飲み込むので、ウィンドウ上の操作は世界に届かない。
win.Active = true
local inputSink = mk("TextButton", { Name = "InputSink", AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 0, Active = true }, win)

-- 背景 (グラデーションは子のFrameに付ける)
local bg = mk("Frame", { Name = "Bg", BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, win)
local bgGrad = mk("UIGradient", { Rotation = 35, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 27, 90)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(88, 28, 160)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 90, 160)) }) }, bg)
local blob1 = mk("Frame", { BackgroundColor3 = PINK, BackgroundTransparency = 0.78, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.9, 0.08), Size = UDim2.fromOffset(320, 320) }, bg)
corner(blob1, 160)
local blob2 = mk("Frame", { BackgroundColor3 = Color3.fromRGB(56, 189, 248), BackgroundTransparency = 0.8, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.06, 0.98), Size = UDim2.fromOffset(340, 340) }, bg)
corner(blob2, 170)
local blob3 = mk("Frame", { BackgroundColor3 = Color3.fromRGB(167, 139, 250), BackgroundTransparency = 0.86, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.55, 0.5), Size = UDim2.fromOffset(220, 220) }, bg)
corner(blob3, 110)
-- 雪・宇宙などの背景アニメは、この層の中に粒を出す
local fxLayer = mk("Frame", { Name = "Fx", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, bg)
UIFX.init(fxLayer, W, H)
local blobTweens = {}
local blobEnabled = true     -- UI設定の「ふわふわ光」
local blobStyleOn = true     -- 背景スタイルが光を使うか
local function blobsOn(on)   -- on = ウィンドウが開いているか
	for _, t in ipairs(blobTweens) do t:Cancel() end
	blobTweens = {}
	local show = blobEnabled and blobStyleOn
	blob1.Visible, blob2.Visible, blob3.Visible = show, show, show
	if not on or not show then return end
	local function loop(b, to, t)
		local tw = TweenService:Create(b, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = to })
		tw:Play()
		blobTweens[#blobTweens + 1] = tw
	end
	loop(blob1, UDim2.fromScale(0.74, 0.2), 7)
	loop(blob2, UDim2.fromScale(0.2, 0.82), 8)
	loop(blob3, UDim2.fromScale(0.4, 0.62), 9)
end

-- 上のバー
local topbar = mk("Frame", { Name = "TopBar", Active = true, Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(W - 24, 50) }, win)
Lib.glass(topbar, 0.86, 16)
local title = text(topbar, "PALLET STUDIO", isMobile and 18 or 26, UDim2.fromOffset(16, isMobile and 10 or 2), UDim2.fromOffset(isMobile and 150 or 260, 30))
local titleGrad = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.5, CYAN), ColorSequenceKeypoint.new(1, WHITE) }) }, title)
if not isMobile then
	text(topbar, "板をカスタマイズ", 12, UDim2.fromOffset(17, 31), UDim2.fromOffset(200, 16), nil, SOFT)
end
local badge = mk("TextLabel", { Name = "Badge", BackgroundTransparency = 0.7, BackgroundColor3 = WHITE, BorderSizePixel = 0, Text = "板を出してね", TextSize = isMobile and 12 or 14, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, isMobile and -84 or -92, 0.5, 0), Size = UDim2.fromOffset(isMobile and 86 or 120, 28) }, topbar)
corner(badge, 14)
stroke(badge, 0.5, WHITE, 1)

local function roundBtn(name, t, x)
	local b = mk("TextButton", { Name = name, AutoButtonColor = false, Text = t, TextSize = 16, FontFace = FONT, TextColor3 = WHITE, Position = UDim2.new(1, x, 0.5, -16), Size = UDim2.fromOffset(32, 32) }, topbar)
	Lib.glass(b, 0.75, 16)
	Lib.juice(b)
	return b
end
local minBtn = roundBtn("Minimize", "–", -80)
local closeBtn = roundBtn("Close", "✕", -42)

-- 左のページ一覧 (スマホはアイコンだけの細い列)
local side = mk("Frame", { Name = "Side", Position = UDim2.fromOffset(12, 68), Size = UDim2.fromOffset(SIDE_W, H - 68 - 58) }, win)
Lib.glass(side, 0.88, 16)
mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, side)
mk("UIListLayout", { Padding = UDim.new(0, isMobile and 6 or 5), SortOrder = Enum.SortOrder.LayoutOrder }, side)

-- 右の中身
local content = mk("Frame", { Name = "Content", Position = UDim2.fromOffset(12 + SIDE_W + 8, 68), Size = UDim2.fromOffset(W - 24 - SIDE_W - 8, H - 68 - 58) }, win)
Lib.glass(content, 0.9, 16)

-- 下のバー (板の選択 / 元に戻す / 保存)
local bottom = mk("Frame", { Name = "Bottom", Position = UDim2.fromOffset(12, H - 50), Size = UDim2.fromOffset(W - 24, 40) }, win)
Lib.glass(bottom, 0.85, 14)
-- 保存ボタンが出たときに一番幅を取る状態を基準に、チップ欄の幅を確保しておく
local RESERVE_W = SAVE_W + 12 + RESET_W + 6 + PERM_W + 12
local CHIP_W = math.max(80, W - 24 - 16 - RESERVE_W)
local chipRow = mk("ScrollingFrame", { Name = "Chips", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 0, Position = UDim2.fromOffset(8, 5), Size = UDim2.fromOffset(CHIP_W, 30) }, bottom)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, chipRow)
local emptyLbl = text(bottom, "板を出してね", 14, UDim2.fromOffset(12, 0), UDim2.fromOffset(CHIP_W, 40), Enum.TextXAlignment.Left, SOFT)
local resetBtn = mk("TextButton", { Name = "Reset", AutoButtonColor = false, Text = isMobile and "↺" or "↺ 元に戻す", TextSize = 15, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(RESET_W, BTN_H) }, bottom)
Lib.glass(resetBtn, 0.55, 12)
resetBtn.BackgroundColor3 = Color3.fromRGB(244, 63, 94)
Lib.juice(resetBtn)
local permBtn = mk("TextButton", { Name = "Perm", AutoButtonColor = false, Text = isMobile and "📌" or "📌 永久保存", TextSize = 15, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(RESET_W + 12), 0.5, 0), Size = UDim2.fromOffset(PERM_W, BTN_H) }, bottom)
Lib.glass(permBtn, 0.45, 12)
permBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
Lib.juice(permBtn)
local saveBtn = mk("TextButton", { Name = "Save", AutoButtonColor = false, Text = isMobile and "💾" or "💾 保存", TextSize = 16, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(0, BTN_H), Visible = false, ClipsDescendants = true, ZIndex = 4 }, bottom)
Lib.glass(saveBtn, 0.1, 12)
saveBtn.BackgroundColor3 = WHITE
mk("UIGradient", { Rotation = 20, Color = ColorSequence.new(Color3.fromRGB(16, 185, 129), Color3.fromRGB(56, 189, 248)) }, saveBtn)
Lib.juice(saveBtn)

-- 状態
local selected = nil
local uiSel = nil          -- UI(スライダー等)が今どの板用になっているか。変わったらUIだけ初期位置へ戻す
local chips = {}
local isOpen = false
local fitScale = 1
local fit   -- 開閉のところで定義する(UI設定ページからも呼ぶので先に宣言)
local homeInfo   -- ホームの表示を今の状態に更新する関数 (ホームページの所で定義。板の一覧が変わるたびに呼ぶ)
local UIs = {}   -- ページをまたいで触るUI部品 (質感ページのトグル・スライダーなど)
local gradLive = false   -- グラデーションを適用中か (色タブの設定を変えたら自動で付け直す)
local dirty = {}
local resetters = {}   -- 板ごとに、UIを初期状態へ戻す関数のリスト
local function onResettable(fn) resetters[#resetters + 1] = fn end
local recipe = setmetatable({}, { __mode = "k" })   -- 板ごとの操作ログ
local permanentOps = nil                             -- 永久保存した設定 (これから出す板に自動で反映)
local permServer = false                           -- 永久保存を、サーバーが板の出現と同時に自動で反映してくれる状態か (サーバーに預けられた時だけ true)
local flashUntil = 0
local saveShown = false
local highlight = mk("Highlight", { FillColor = ACCENT, FillTransparency = 0.88, OutlineColor = ACCENT, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false }, gui)
Lib.onTheme(function(a) highlight.FillColor = a highlight.OutlineColor = a end)

-- UI設定 (全部この画面だけの設定。板には関係しない)
local uiCfg = { alpha = 0, bgAlpha = 0, size = 1 }
local spinTw = {}                   -- リング/タイトルの回転アニメ (UI設定でON/OFF)
local applyAccent, applyStyle, resetUISettings   -- UI設定ページの中で定義する
-- テーマ色 { 名前, 色1, 色2 }
local ACCENTS = {
	{ "ブルー", Color3.fromRGB(96, 165, 250), Color3.fromRGB(192, 132, 252) },
	{ "ピンク", Color3.fromRGB(244, 114, 182), Color3.fromRGB(251, 146, 60) },
	{ "グリーン", Color3.fromRGB(52, 211, 153), Color3.fromRGB(56, 189, 248) },
	{ "オレンジ", Color3.fromRGB(251, 146, 60), Color3.fromRGB(250, 204, 21) },
	{ "レッド", Color3.fromRGB(244, 63, 94), Color3.fromRGB(251, 146, 60) },
	{ "パープル", Color3.fromRGB(168, 85, 247), Color3.fromRGB(236, 72, 153) },
	{ "ゴールド", Color3.fromRGB(250, 204, 21), Color3.fromRGB(251, 146, 60) },
	{ "モノ", Color3.fromRGB(226, 232, 240), Color3.fromRGB(148, 163, 184) },
}
-- 背景スタイル: bg=ウィンドウ背景の3色 / blobs={{色, 透明度} x3} (nilなら光を出さない) / fx=背景アニメの種類
local STYLES = {
	{ name = "標準", icon = "🌌", fx = "none",
		bg = { Color3.fromRGB(30, 27, 90), Color3.fromRGB(88, 28, 160), Color3.fromRGB(12, 90, 160) },
		blobs = { { Color3.fromRGB(244, 114, 182), 0.78 }, { Color3.fromRGB(56, 189, 248), 0.8 }, { Color3.fromRGB(167, 139, 250), 0.86 } } },
	{ name = "宇宙", icon = "🪐", fx = "space",
		bg = { Color3.fromRGB(2, 3, 16), Color3.fromRGB(20, 10, 52), Color3.fromRGB(4, 22, 62) },
		blobs = { { Color3.fromRGB(120, 60, 220), 0.82 }, { Color3.fromRGB(40, 110, 230), 0.84 }, { Color3.fromRGB(220, 70, 170), 0.9 } } },
	{ name = "雪", icon = "❄️", fx = "snow",
		bg = { Color3.fromRGB(12, 30, 64), Color3.fromRGB(32, 72, 124), Color3.fromRGB(70, 128, 178) },
		blobs = { { Color3.fromRGB(200, 230, 255), 0.86 }, { Color3.fromRGB(150, 200, 255), 0.88 }, { Color3.fromRGB(255, 255, 255), 0.92 } } },
	{ name = "桜", icon = "🌸", fx = "sakura",
		bg = { Color3.fromRGB(58, 18, 60), Color3.fromRGB(132, 44, 108), Color3.fromRGB(214, 116, 156) },
		blobs = { { Color3.fromRGB(255, 183, 205), 0.8 }, { Color3.fromRGB(255, 140, 180), 0.84 }, { Color3.fromRGB(255, 220, 235), 0.88 } } },
	{ name = "雨", icon = "🌧️", fx = "rain",
		bg = { Color3.fromRGB(10, 16, 28), Color3.fromRGB(28, 42, 66), Color3.fromRGB(18, 30, 48) },
		blobs = { { Color3.fromRGB(90, 130, 190), 0.88 }, { Color3.fromRGB(60, 100, 160), 0.9 }, { Color3.fromRGB(120, 160, 210), 0.92 } } },
	{ name = "オーロラ", icon = "🌠", fx = "none",
		bg = { Color3.fromRGB(4, 16, 32), Color3.fromRGB(8, 44, 64), Color3.fromRGB(30, 20, 70) },
		blobs = { { Color3.fromRGB(52, 235, 160), 0.74 }, { Color3.fromRGB(56, 189, 248), 0.78 }, { Color3.fromRGB(168, 85, 247), 0.8 } } },
	{ name = "ホタル", icon = "✨", fx = "firefly",
		bg = { Color3.fromRGB(8, 20, 16), Color3.fromRGB(16, 44, 30), Color3.fromRGB(10, 30, 40) },
		blobs = { { Color3.fromRGB(190, 230, 90), 0.88 }, { Color3.fromRGB(80, 200, 140), 0.9 }, { Color3.fromRGB(230, 240, 140), 0.92 } } },
	{ name = "シンプル", icon = "▫️", fx = "none",
		bg = { Color3.fromRGB(24, 24, 34), Color3.fromRGB(34, 34, 48), Color3.fromRGB(24, 24, 34) },
		blobs = nil },
}
local curBg = STYLES[1].bg    -- 今の背景グラデ (スタイル切り替えのなめらかな補間用)
local bgFadeId = 0

local function setSave(v)
	if v == saveShown then return end
	saveShown = v
	if v then
		saveBtn.Visible = true
		saveBtn.Size = UDim2.fromOffset(0, BTN_H)
		Lib.tween(saveBtn, { Size = UDim2.fromOffset(SAVE_W, BTN_H) }, 0.5)
	else
		local t = Lib.tween(saveBtn, { Size = UDim2.fromOffset(0, BTN_H) }, 0.3)
		t.Completed:Connect(function()
			if not saveShown then saveBtn.Visible = false end
		end)
	end
	local x = v and -(SAVE_W + 12) or -6
	Lib.tween(resetBtn, { Position = UDim2.new(1, x, 0.5, 0) }, 0.45)
	Lib.tween(permBtn, { Position = UDim2.new(1, x - (RESET_W + 6), 0.5, 0) }, 0.45)
end

local slotOf = setmetatable({}, { __mode = "k" })
local seenMap = {}

-- 検出するのは「Workspace/<自分の@ID(ユーザー名)>SpawnedInToys」の直下にある PalletLightBrown (Model) だけ。
-- 他のフォルダ・他プレイヤーのフォルダ・フォルダの外にある板は見ない。フォルダの自動作成もしない。
local function myFolder()
	return workspace:FindFirstChild(toyFolderName())
end

-- この板は、自分のフォルダの直下にあるか (DescendantAdded などで使う)
local function isMyBoard(m)
	if m.Name ~= "PalletLightBrown" or not m:IsA("Model") then return false end
	local f = myFolder()
	return f ~= nil and m.Parent == f
end

local function myPallets()
	local list = {}
	local f = myFolder()
	if f then
		for _, m in ipairs(f:GetChildren()) do
			if m.Name == "PalletLightBrown" and m:IsA("Model") then
				list[#list + 1] = m
			end
		end
	end
	-- 消えた板の番号は空くので、新しい板は一番小さい空き番号をもらう
	local used = {}
	for _, m in ipairs(list) do
		local n = slotOf[m]
		if n then used[n] = true end
	end
	for _, m in ipairs(list) do
		if not slotOf[m] then
			local n = 1
			while used[n] do n = n + 1 end
			slotOf[m] = n
			used[n] = true
		end
	end
	table.sort(list, function(a, b) return slotOf[a] < slotOf[b] end)
	return list
end

-- 枠(青)と保存ボタンの表示だけ更新 (軽い)
local function selVisuals()
	local selModel = selected and seenMap[selected] or nil
	local show = isOpen and selModel ~= nil and (dirty[selected] == true or os.clock() < flashUntil)
	highlight.Adornee = selModel
	highlight.Enabled = show
	setSave(isOpen and selModel ~= nil and dirty[selected] == true)
	badge.Text = selected and ("選択中: 板" .. selected) or "板を出してね"
end

local refresh
local function makeChip(i)
	local b = mk("TextButton", { Name = "Chip" .. i, AutoButtonColor = false, Text = "板" .. i, TextSize = 15, FontFace = FONT, TextColor3 = WHITE, LayoutOrder = i, Size = UDim2.fromOffset(66, 28) }, chipRow)
	Lib.glass(b, 0.85, 14)
	Lib.juice(b)
	b.MouseButton1Click:Connect(function()
		selected = i
		flashUntil = os.clock() + 1.2   -- どの板か分かるように一瞬だけ枠を出す
		task.delay(1.25, selVisuals)
		refresh()
	end)
	chips[i] = { btn = b }
end

refresh = function()
	local list = myPallets()
	local seen = {}
	for _, m in ipairs(list) do
		local i = slotOf[m]
		seen[i] = m
		if chips[i] and chips[i].model ~= m then dirty[i] = nil end
		if not chips[i] then makeChip(i) end
		chips[i].model = m
	end
	for i, c in pairs(chips) do
		if not seen[i] then
			c.btn:Destroy()
			chips[i] = nil
			dirty[i] = nil
		end
	end
	if selected and not seen[selected] then selected = nil end
	if not selected and #list > 0 then selected = slotOf[list[#list]] end
	seenMap = seen
	-- 別の板に移ったら、スライダーやトグルだけ初期位置へ戻す。板そのものは戻さない
	-- (板を元に戻すのは「元に戻す」ボタンを押した時だけ)
	if selected ~= uiSel then
		uiSel = selected
		for _, fn in ipairs(resetters) do pcall(fn) end
	end
	for i, c in pairs(chips) do
		local active = (i == selected)
		if c.active ~= active then
			c.active = active
			Lib.tween(c.btn, { BackgroundColor3 = active and Lib.ACCENT or WHITE, BackgroundTransparency = active and 0.1 or 0.85 }, 0.25)
		end
	end
	emptyLbl.Visible = (#list == 0)
	selVisuals()
	if homeInfo then pcall(homeInfo) end
end

-- 板に反映 (サーバーの受け口があればサーバーへ、無い/失敗ならこの画面に直接)
local lastSend = 0
local function doApply(model, kind, value, quiet)
	local remote = RS:FindFirstChild("PalletStudioApply_v3")
	task.spawn(function()
		local msg
		if remote then
			local ok, res = pcall(function() return remote:InvokeServer(kind, model, value) end)
			if ok then msg = res else remote = nil end
		end
		if not remote then
			local ok, res = pcall(applySkin, model, kind, value)
			msg = ok and res or "エラーが発生しました"
		end
		if msg and not quiet then Lib.notif(gui, msg, 1.6) end
	end)
end

local function updatePerm()
	permBtn.Text = isMobile and "📌" or (permanentOps and "📌 永久保存中" or "📌 永久保存")
	Lib.tween(permBtn, { BackgroundColor3 = permanentOps and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(99, 102, 241) }, 0.3)
end

local function record(model, kind, value)
	if kind == "Reset" then
		recipe[model] = nil   -- (永久保存は「📌 永久保存」ボタンをもう一度押した時だけ解除する)
		return
	end
	local r = recipe[model] or {}
	for k = #r, 1, -1 do
		if r[k][1] == kind then table.remove(r, k) end
	end
	r[#r + 1] = { kind, value }
	recipe[model] = r
end

local function send(kind, value, quiet)
	local idx = selected
	local model = idx and seenMap[idx]
	if not model or not model.Parent then
		Lib.notif(gui, "板を選んでください", 1.8)
		return
	end
	dirty[idx] = (kind ~= "Reset") or nil
	if kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" or kind == "GradientClear" or kind == "Reset" or (kind == "Rainbow" and value == true) then
		gradLive = false   -- サーバー側でグラデーションが外れる操作
		if UIs.refHint then UIs.refHint() end
	end
	record(model, kind, value)
	selVisuals()
	if UIs.rbT and (kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" or kind == "Gradient") then
		UIs.rbT:set(false)   -- サーバー側でレインボーが止まるので、スイッチの表示も合わせる
	end
	doApply(model, kind, value, quiet)
end
-- 複数の操作を、1回の通信にまとめて送る (おまかせ・コピー・永久保存用)。履歴には1つずつ記録する
local function sendMany(model, ops, quiet)
	for _, op in ipairs(ops) do record(model, op[1], op[2]) end
	for i = 1, #ops, 50 do
		local chunk = {}
		for k = i, math.min(i + 49, #ops) do chunk[#chunk + 1] = { ops[k][1], ops[k][2] } end
		doApply(model, "Batch", chunk, quiet)
	end
end
local function sendThrottled(kind, value, released)
	local now = os.clock()
	if released or now - lastSend > 0.1 then
		lastSend = now
		send(kind, value, not released)
	end
end

-- ページ
local function newPage()
	local p = mk("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Size = UDim2.fromScale(1, 1), Visible = false }, content)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, p)
	return p
end
local function grid(row, cw, ch, px, py)
	mk("UIGridLayout", { CellSize = UDim2.fromOffset(cw, ch), CellPadding = UDim2.fromOffset(px, py), SortOrder = Enum.SortOrder.LayoutOrder }, row)
end
local function gridHeight(n, per, ch, py)
	local rows = math.ceil(n / per)
	return rows * ch + (rows - 1) * py
end

-- 横に並ぶ選択ボタン (1つだけ選ばれる)。選ぶ関数 mark(i) を返す
local function chipsRow(e, labels, onPick, initial)
	local r = e:row(isMobile and 34 or 32)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, r)
	local btns, sel = {}, initial
	local function mark(i)
		sel = i
		for j, b in ipairs(btns) do
			local active = (j == i)
			Lib.tween(b, { BackgroundColor3 = active and Lib.ACCENT or WHITE, BackgroundTransparency = active and 0.15 or 0.88 }, 0.2)
		end
	end
	for i, nm in ipairs(labels) do
		local b = mk("TextButton", { AutoButtonColor = false, Text = nm, TextSize = isMobile and 12 or 14, FontFace = FONT, TextColor3 = WHITE, LayoutOrder = i, Size = UDim2.new(1 / #labels, -5, 1, 0) }, r)
		Lib.glass(b, 0.88, 10)
		Lib.juice(b)
		b.MouseButton1Click:Connect(function()
			mark(i)
			onPick(i)
		end)
		btns[i] = b
	end
	mark(initial)
	Lib.onTheme(function(a) if btns[sel] then btns[sel].BackgroundColor3 = a end end)
	return mark
end

local pages = {}
for i = 1, 10 do pages[i] = newPage() end   -- 1〜6 各タブ / 7〜9 その他の中 / 10 ホーム
-- 7〜9 は「その他」タブの中。上に切り替えバーを置くので、その分だけ下げる
for k = 7, 9 do
	pages[k].Position = UDim2.fromOffset(0, 46)
	pages[k].Size = UDim2.new(1, 0, 1, -46)
end

-- 1: 色
do
	local e = Lib.element(pages[1])
	do   -- 単色の部分 (ここのローカル変数はここで終わり)
		e:title("カラー")
		local colors = {
			{239, 68, 68}, {249, 115, 22}, {250, 204, 21}, {132, 204, 22}, {52, 211, 153}, {20, 184, 166}, {56, 189, 248}, {59, 130, 246},
			{129, 140, 248}, {168, 85, 247}, {236, 72, 153}, {244, 63, 94}, {120, 72, 40}, {244, 245, 248}, {120, 126, 140}, {20, 22, 28},
			{255, 183, 205}, {253, 224, 71}, {190, 242, 100}, {110, 231, 183}, {147, 197, 253}, {196, 181, 253}, {251, 146, 60}, {148, 163, 184},
		}
		local colCols = isMobile and 4 or 8
		local row = e:row(gridHeight(#colors, colCols, 34, 8))
		grid(row, 53, 34, 8, 8)
		for i, c in ipairs(colors) do
			local col = Color3.fromRGB(c[1], c[2], c[3])
			local s = mk("TextButton", { AutoButtonColor = false, BorderSizePixel = 0, Text = "", BackgroundColor3 = col, LayoutOrder = i }, row)
			corner(s, 11)
			stroke(s, 0.3, WHITE, 1.5)
			Lib.juice(s)
			s.MouseButton1Click:Connect(function() send("Color", col) end)
		end
		e:title("色を調整 (HSV)")
		local hsv = { 0.58, 0.7, 1 }
		local hsvDefault = { hsv[1], hsv[2], hsv[3] }
		local hS = e:slider("色相", 0, 1, function(v, r) hsv[1] = v sendThrottled("HSV", { hsv[1], hsv[2], hsv[3] }, r) end, hsv[1], nil, nil, hueSeq())
		local sS = e:slider("彩度", 0, 1, function(v, r) hsv[2] = v sendThrottled("HSV", { hsv[1], hsv[2], hsv[3] }, r) end, hsv[2], WHITE, Color3.fromRGB(99, 102, 241))
		local vS = e:slider("明度", 0, 1, function(v, r) hsv[3] = v sendThrottled("HSV", { hsv[1], hsv[2], hsv[3] }, r) end, hsv[3], Color3.fromRGB(20, 20, 30), WHITE)
		e:title("色を調整 (RGB)")
		local rgb = { 1, 1, 1 }
		local function rgbSend(r) sendThrottled("RGB", { rgb[1], rgb[2], rgb[3] }, r) end
		local rS = e:slider("赤 R", 0, 1, function(v, r) rgb[1] = v rgbSend(r) end, 1, Color3.fromRGB(60, 10, 10), Color3.fromRGB(255, 70, 70))
		local gS = e:slider("緑 G", 0, 1, function(v, r) rgb[2] = v rgbSend(r) end, 1, Color3.fromRGB(10, 50, 20), Color3.fromRGB(70, 255, 110))
		local bS = e:slider("青 B", 0, 1, function(v, r) rgb[3] = v rgbSend(r) end, 1, Color3.fromRGB(10, 20, 60), Color3.fromRGB(70, 140, 255))
		onResettable(function()
			hsv[1], hsv[2], hsv[3] = hsvDefault[1], hsvDefault[2], hsvDefault[3]
			hS:set(hsvDefault[1]) sS:set(hsvDefault[2]) vS:set(hsvDefault[3])
			rgb[1], rgb[2], rgb[3] = 1, 1, 1
			rS:set(1) gS:set(1) bS:set(1)
		end)
		e:title("16進数")
		local hr = e:row(40)
		local box = mk("TextBox", { PlaceholderText = "#RRGGBB", PlaceholderColor3 = SOFT, Text = "", TextSize = 15, FontFace = FONT, TextColor3 = WHITE, ClearTextOnFocus = false, Size = UDim2.new(1, -100, 1, 0) }, hr)
		Lib.glass(box, 0.85, 12)
		local ap = mk("TextButton", { AutoButtonColor = false, Text = "適用", TextSize = 16, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(92, 40) }, hr)
		Lib.glass(ap, 0.3, 12)
		ap.BackgroundColor3 = ACCENT
		Lib.onTheme(function(a) ap.BackgroundColor3 = a end)
		Lib.juice(ap)
		ap.MouseButton1Click:Connect(function()
			local t = box.Text:gsub("%s", ""):gsub("^#", "")
			if #t ~= 6 or not t:match("^%x+$") then
				Lib.notif(gui, "#RRGGBB の形式で入力してください", 1.8)
				return
			end
			send("Color", Color3.fromHex(t))
		end)
	end

	-- ===== グラデーション: 2〜3色を混ぜる (流れるアニメも選べる) =====
	e:title("🌈 グラデーション (2〜3色を混ぜる)")
	local gA, gB, gC = Color3.fromRGB(239, 68, 68), Color3.fromRGB(59, 130, 246), nil   -- 赤 → 青 (Cは無し)
	local gAxis, gRev, gMid, gStripes, gSmooth, gTopFlip = "X", false, 0.5, 0, true, false
	local gFlowOn, gFlowSpeed = false, 0.25
	local midS, stripeMark, flowT, flowS, axisMark   -- 下で作る部品 (おすすめボタンから触るので先に宣言)
	local function mixLin(a, b, t)   -- 暗く沈まないよう、光の強さ(リニア)で混ぜる (サーバーと同じ式)
		local function m(x, y) return (x ^ 2.2 * (1 - t) + y ^ 2.2 * t) ^ (1 / 2.2) end
		return Color3.new(m(a.R, b.R), m(a.G, b.G), m(a.B, b.B))
	end
	local function colAt(t)   -- 位置 t(0〜1) の色
		if gRev then t = 1 - t end
		if gC then
			if t <= gMid then return mixLin(gA, gC, t / gMid) end
			return mixLin(gC, gB, (t - gMid) / (1 - gMid))
		end
		return mixLin(gA, gB, t ^ (math.log(0.5) / math.log(gMid)))
	end
	-- 見本の帯
	local prevRow = e:glass(34)
	local prevBar = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -12) }, prevRow)
	corner(prevBar, 8)
	local prevGrad = mk("UIGradient", {}, prevBar)
	local function previewSeq()
		local keys = {}
		if gStripes > 1 then
			local pal = gC and { gA, gC, gB } or { gA, gB }
			for k = 0, gStripes - 1 do
				local band = gRev and (gStripes - 1 - k) or k
				local c = pal[(band % #pal) + 1]
				keys[#keys + 1] = ColorSequenceKeypoint.new(k == 0 and 0 or (k / gStripes + 0.002), c)
				keys[#keys + 1] = ColorSequenceKeypoint.new(k == gStripes - 1 and 1 or ((k + 1) / gStripes - 0.002), c)
			end
		else
			local us = {}
			for i = 0, 10 do us[#us + 1] = i / 10 end
			if gC then us[#us + 1] = gRev and (1 - gMid) or gMid end   -- 真ん中の色の位置にも点を置く
			table.sort(us)
			local last = -1
			for _, u in ipairs(us) do
				if u > last + 1e-4 then
					keys[#keys + 1] = ColorSequenceKeypoint.new(u, colAt(u))
					last = u
				end
			end
		end
		return ColorSequence.new(keys)
	end
	local function showPreview() prevGrad.Color = previewSeq() end
	showPreview()

	-- 板へ送る。ドラッグ中は軽い版(パーツごとの色だけ)、離した時/ボタンの時に、なめらかな重ね貼りまで送る
	local function sendGrad(final)
		gradLive = true
		local v = { a = gA, b = gB, c = gC, axis = gAxis, rev = gRev, mid = gMid, smooth = (gSmooth and final) and true or false, stripes = gStripes, topFlip = gTopFlip, flow = gFlowOn and gFlowSpeed or 0 }
		if final then send("Gradient", v) else sendThrottled("Gradient", v, false) end
		if UIs.texT then UIs.texT:set(false) end   -- グラデーションは木目を外す
	end
	local function changed(final)
		showPreview()
		if gradLive then sendGrad(final) end
	end

	do
		-- おすすめ (押すとすぐ板に付く)。{ 名前, 色A, 色B, 色C(なくてもOK) }
		e:title("おすすめのグラデーション (押すとすぐ付く)")
		local GRADS = {
			{ "夕焼け", Color3.fromRGB(255, 110, 40), Color3.fromRGB(110, 60, 200), Color3.fromRGB(255, 80, 150) },
			{ "海", Color3.fromRGB(10, 40, 120), Color3.fromRGB(90, 230, 230), Color3.fromRGB(20, 130, 200) },
			{ "オーロラ", Color3.fromRGB(40, 235, 160), Color3.fromRGB(190, 80, 255), Color3.fromRGB(70, 130, 255) },
			{ "炎", Color3.fromRGB(255, 40, 0), Color3.fromRGB(255, 230, 70), Color3.fromRGB(255, 140, 20) },
			{ "桜", Color3.fromRGB(255, 190, 215), Color3.fromRGB(255, 120, 170) },
			{ "ミント", Color3.fromRGB(160, 255, 220), Color3.fromRGB(40, 180, 170) },
			{ "宇宙", Color3.fromRGB(15, 10, 60), Color3.fromRGB(20, 60, 140), Color3.fromRGB(110, 50, 190) },
			{ "信号", Color3.fromRGB(255, 60, 60), Color3.fromRGB(60, 120, 255), Color3.fromRGB(60, 255, 120) },
			{ "キャンディ", Color3.fromRGB(255, 150, 205), Color3.fromRGB(255, 245, 250) },
			{ "モノクロ", Color3.fromRGB(20, 22, 28), Color3.fromRGB(244, 245, 248) },
		}
		local gCols = isMobile and 2 or 3
		local gCW = isMobile and 124 or 154
		local grow = e:row(gridHeight(#GRADS, gCols, 44, 8))
		grid(grow, gCW, 44, 8, 8)
		for i, g in ipairs(GRADS) do
			local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i }, grow)
			Lib.glass(b, 0.84, 12)
			local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(34, 34) }, b)
			corner(sw, 8)
			local ks = g[4] and { ColorSequenceKeypoint.new(0, g[2]), ColorSequenceKeypoint.new(0.5, g[4]), ColorSequenceKeypoint.new(1, g[3]) }
				or { ColorSequenceKeypoint.new(0, g[2]), ColorSequenceKeypoint.new(1, g[3]) }
			mk("UIGradient", { Rotation = 45, Color = ColorSequence.new(ks) }, sw)
			text(b, g[1], isMobile and 12 or 14, UDim2.fromOffset(44, 0), UDim2.new(1, -46, 1, 0), Enum.TextXAlignment.Left)
			Lib.juice(b)
			b.MouseButton1Click:Connect(function()
				gA, gB, gC = g[2], g[3], g[4]
				gMid = 0.5
				if midS then midS:set(0.5) end
				showPreview()
				sendGrad(true)
			end)
		end
	end

	-- 色A / 色B / 色C を選ぶ (パレット + 色相スライダー)
	local pal = {
		Color3.fromRGB(239, 68, 68), Color3.fromRGB(250, 204, 21), Color3.fromRGB(52, 211, 153), Color3.fromRGB(56, 189, 248),
		Color3.fromRGB(59, 130, 246), Color3.fromRGB(168, 85, 247), Color3.fromRGB(244, 245, 248), Color3.fromRGB(20, 22, 28),
	}
	local palCols = isMobile and 4 or 8
	local function colorPicker(label, sliderName, setC, hueStart)
		e:title(label)
		local prow = e:row(gridHeight(#pal, palCols, 30, 8))
		grid(prow, 53, 30, 8, 8)
		for i, col in ipairs(pal) do
			local sw = mk("TextButton", { AutoButtonColor = false, BorderSizePixel = 0, Text = "", BackgroundColor3 = col, LayoutOrder = i }, prow)
			corner(sw, 10)
			stroke(sw, 0.3, WHITE, 1.5)
			Lib.juice(sw)
			sw.MouseButton1Click:Connect(function()
				setC(col)
				changed(true)
			end)
		end
		return e:slider(sliderName, 0, 1, function(v, r)
			setC(Color3.fromHSV(v, 0.9, 1))
			changed(r)
		end, hueStart, nil, nil, hueSeq())
	end
	local hueA = colorPicker("色A (はじまり)", "色A の色相", function(c) gA = c end, 0)
	local hueB = colorPicker("色B (おわり)", "色B の色相", function(c) gB = c end, 0.61)
	local hueC = colorPicker("色C (まんなか。なくてもOK)", "色C の色相", function(c) gC = c end, 0.33)
	e:button("色C を使わない (2色にもどす)", function()
		gC = nil
		changed(true)
	end)

	-- 向き・混ざり方
	e:title("混ぜる向き (板の向きでの 横 / 高さ / 奥行)")
	axisMark = chipsRow(e, { "X方向", "Y方向 (高さ)", "Z方向" }, function(i)
		gAxis = ({ "X", "Y", "Z" })[i]
		changed(true)
	end, 1)
	local revT = e:toggle("向きを反転 (A と B を入れ替え)", function(sv)
		gRev = sv
		changed(true)
	end, false)
	midS = e:slider("中間の位置 (色C の位置)", 0.1, 0.9, function(v, r)
		gMid = v
		changed(r)
	end, 0.5, Color3.fromRGB(99, 102, 241), PINK)
	e:title("模様")
	stripeMark = chipsRow(e, { "なめらか", "2本", "3本", "4本", "6本", "8本" }, function(i)
		gStripes = ({ 0, 2, 3, 4, 6, 8 })[i]
		changed(true)
	end, 1)
	local smoothT = e:toggle("なめらかに塗る (重ね貼り)", function(sv)
		gSmooth = sv
		changed(true)
	end, true)
	local topT = e:toggle("上面の向きを反転 (上面だけ逆に見える時)", function(sv)
		gTopFlip = sv
		changed(true)
	end, false)
	e:title("流れるアニメーション")
	flowT = e:toggle("色を流す (なめらかに動く)", function(sv)
		gFlowOn = sv
		if sv then sendGrad(true) else changed(true) end
	end, false)
	flowS = e:slider("流れる速さ", 0.05, 1, function(v, r)
		gFlowSpeed = v
		gFlowOn = true
		flowT:set(true)
		sendGrad(r)
	end, 0.25, Color3.fromRGB(99, 102, 241), CYAN)
	e:button("✨ グラデーションを板に適用", function() sendGrad(true) end, ACCENT)
	e:button("単色に戻す (グラデーションを外す)", function()
		send("GradientClear", nil)
	end)
	local gnote = e:row(isMobile and 98 or 72)
	local gnoteLbl = text(gnote, "2〜3色が、板の向きに沿って混ざります。適用したあとに色や向きを変えると、すぐ反映されます。「色を流す」をONにすると、色がなめらかに流れます (流れる間は、板ごとの色になります)。レインボーとは同時に使えません。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	gnoteLbl.TextWrapped = true
	onResettable(function()
		gA, gB, gC = Color3.fromRGB(239, 68, 68), Color3.fromRGB(59, 130, 246), nil
		gAxis, gRev, gMid, gStripes, gSmooth, gTopFlip = "X", false, 0.5, 0, true, false
		gFlowOn, gFlowSpeed = false, 0.25
		hueA:set(0) hueB:set(0.61) hueC:set(0.33)
		axisMark(1) stripeMark(1)
		revT:set(false) smoothT:set(true) topT:set(false) midS:set(0.5)
		flowT:set(false) flowS:set(0.25)
		gradLive = false
		showPreview()
	end)
end

-- 2: 素材 (押すと、その素材らしい色・質感・反射にして、元のテクスチャも外す)
do
	local e = Lib.element(pages[2])
	e:title("素材 (押すとその素材の見た目になる)")
	local mats = {
		{"Plastic", "🧴 プラスチック", Color3.fromRGB(70, 130, 230)}, {"SmoothPlastic", "🫧 つるつる", Color3.fromRGB(245, 245, 250)}, {"Wood", "🪵 木", Color3.fromRGB(150, 100, 60)},
		{"WoodPlanks", "📏 板木", Color3.fromRGB(190, 140, 85)}, {"Metal", "⚙️ 金属", Color3.fromRGB(150, 158, 170)}, {"DiamondPlate", "🔷 ダイヤ板", Color3.fromRGB(120, 125, 135)},
		{"Foil", "🪞 ホイル", Color3.fromRGB(215, 220, 230)}, {"Neon", "💡 ネオン", Color3.fromRGB(60, 255, 200)}, {"Glass", "🔮 ガラス", Color3.fromRGB(190, 225, 240)},
		{"Ice", "🧊 氷", Color3.fromRGB(170, 220, 255)}, {"Marble", "🏛 大理石", Color3.fromRGB(236, 236, 240)}, {"Granite", "🪨 花崗岩", Color3.fromRGB(125, 120, 118)},
		{"Slate", "⬛ スレート", Color3.fromRGB(75, 82, 95)}, {"Concrete", "🏗 コンクリ", Color3.fromRGB(160, 160, 158)}, {"Brick", "🧱 レンガ", Color3.fromRGB(170, 70, 55)},
		{"Cobblestone", "🛣 石畳", Color3.fromRGB(130, 125, 120)}, {"Sand", "🏖 砂", Color3.fromRGB(225, 200, 140)}, {"Fabric", "🧵 布", Color3.fromRGB(90, 120, 200)},
		{"ForceField", "🛡 フォース", Color3.fromRGB(120, 200, 255)},
		{"Glacier", "🏔 氷河", Color3.fromRGB(190, 230, 245)}, {"Snow", "☃️ 雪", Color3.fromRGB(245, 248, 252)}, {"Mud", "🟤 泥", Color3.fromRGB(95, 70, 50)},
		{"Rubber", "⚫ ゴム", Color3.fromRGB(40, 40, 46)}, {"Leather", "👜 革", Color3.fromRGB(125, 72, 46)}, {"Plaster", "🧱 しっくい", Color3.fromRGB(232, 225, 212)},
		{"CeramicTiles", "🚿 タイル", Color3.fromRGB(236, 240, 242)}, {"Carpet", "🟥 カーペット", Color3.fromRGB(150, 60, 72)}, {"Cardboard", "📦 段ボール", Color3.fromRGB(192, 152, 102)},
		{"Basalt", "🌋 玄武岩", Color3.fromRGB(62, 64, 70)}, {"Pebble", "⚪ 小石", Color3.fromRGB(150, 140, 130)}, {"Limestone", "🦴 石灰岩", Color3.fromRGB(222, 214, 192)},
		{"Sandstone", "🏜 砂岩", Color3.fromRGB(202, 162, 112)}, {"CorrodedMetal", "🦀 さび金属", Color3.fromRGB(132, 100, 80)}, {"CrackedLava", "🔥 溶岩", Color3.fromRGB(255, 120, 40)},
	}
	do   -- この Roblox に無い素材は出さない
		local have = {}
		for _, m in ipairs(mats) do
			if pcall(function() return Enum.Material[m[1]] end) then have[#have + 1] = m end
		end
		mats = have
	end
	local function pickLook(name)
		send("Look", name)
		if UIs.afterLook then UIs.afterLook(true) end
	end
	e:button("🎲 ランダムな素材にする", function() pickLook(mats[math.random(#mats)][1]) end, ACCENT)
	local matCols = isMobile and 2 or 3
	local matCW = isMobile and 124 or 154
	local row = e:row(gridHeight(#mats, matCols, 56, 8))
	grid(row, matCW, 56, 8, 8)
	for i, m in ipairs(mats) do
		local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i }, row)
		Lib.glass(b, 0.84, 14)
		local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(44, 44) }, b)
		corner(sw, 10)
		mk("UIGradient", { Rotation = 35, Color = ColorSequence.new(m[3], Color3.new(m[3].R * 0.5, m[3].G * 0.5, m[3].B * 0.5)) }, sw)
		local matLbl = text(b, m[2], isMobile and 12 or 14, UDim2.fromOffset(56, 0), UDim2.new(1, -58, 1, 0), Enum.TextXAlignment.Left)
		matLbl.TextWrapped = true
		Lib.juice(b)
		b.MouseButton1Click:Connect(function() pickLook(m[1]) end)
	end
	e:title("素材のあとに色を変えても大丈夫")
end

-- 3: プリセット
do
	local e = Lib.element(pages[3])
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	-- { ID, 名前, 色1, 色2(なければ暗い色1), 見た目一式か }  一式のものは、いまの光・動き・効果を消してから付く
	local fullSets = {
		{ "Aurora", "オーロラ", C(40, 235, 160), C(190, 80, 255), true }, { "Galaxy", "ギャラクシー", C(110, 50, 190), C(15, 10, 60), true },
		{ "Chrome", "クローム", C(235, 240, 248), C(120, 130, 150), true }, { "Hologram", "ホログラム", C(120, 220, 255), C(255, 120, 230), true },
		{ "LavaFlow", "溶岩フロー", C(255, 230, 70), C(255, 40, 0), true }, { "Frozen", "氷結", C(210, 240, 255), C(110, 180, 240), true },
		{ "SakuraStorm", "桜吹雪", C(255, 190, 215), C(255, 120, 170), true }, { "Cyber", "サイバー", C(0, 255, 230), C(20, 24, 40), true },
		{ "Fireflies", "ほたるの夜", C(190, 255, 120), C(20, 50, 36), true }, { "CandyGloss", "キャンディツヤ", C(255, 150, 205), C(255, 245, 250), true },
		{ "SunsetSky", "夕焼け空", C(255, 110, 40), C(110, 60, 200), true }, { "Ocean", "海", C(90, 230, 230), C(10, 40, 120), true },
	}
	local basics = {
		{"NeonBlue", "ネオンブルー", C(56, 189, 248)}, {"NeonPink", "ネオンピンク", C(255, 70, 190)}, {"NeonGreen", "ネオングリーン", C(60, 255, 130)},
		{"Sunset", "サンセット", C(255, 120, 40)}, {"Gold", "ゴールド", C(255, 200, 60)}, {"Silver", "シルバー", C(200, 205, 215)},
		{"Ice", "アイス", C(175, 225, 255)}, {"Glass", "ガラス", C(200, 235, 255)}, {"Marble", "大理石", C(235, 235, 240)},
		{"Lava", "ラバ", C(255, 90, 20)}, {"Obsidian", "黒曜石", C(60, 50, 90)}, {"Candy", "キャンディ", C(255, 150, 200)},
		{"Forest", "森", C(50, 150, 70)}, {"Ghost", "ゴースト", C(230, 240, 255)}, {"Sakura", "さくら", C(255, 183, 205)},
		{"Toxic", "トキシック", C(170, 255, 0)}, {"Royal", "ロイヤル", C(88, 60, 200)}, {"RoseGold", "ローズゴールド", C(236, 160, 150)},
	}
	local presetCols = isMobile and 2 or 3
	local presetCW = isMobile and 124 or 154
	local function addGrid(list, title)
		e:title(title)
		local row = e:row(gridHeight(#list, presetCols, 84, 8))
		grid(row, presetCW, 84, 8, 8)
		for i, p in ipairs(list) do
			local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i }, row)
			Lib.glass(b, 0.84, 14)
			local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 44) }, b)
			corner(sw, 10)
			local c2 = p[4] or Color3.new(p[3].R * 0.45, p[3].G * 0.45, p[3].B * 0.45)
			mk("UIGradient", { Rotation = 25, Color = ColorSequence.new(p[3], c2) }, sw)
			text(b, p[2], isMobile and 12 or 14, UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 24), Enum.TextXAlignment.Center)
			Lib.juice(b)
			b.MouseButton1Click:Connect(function()
				if p[5] then for _, fn in ipairs(resetters) do pcall(fn) end end   -- 一式は光・効果も入れ替わるので、画面の表示も初期位置へ
				send("Preset", p[1])
				if UIs.afterLook then UIs.afterLook(p[5] == true) end
			end)
		end
	end

	-- おまかせ: ランダムに見た目をぜんぶ決める
	local function randomOps()
		local rnd = math.random
		local function pick(list) return list[rnd(#list)] end
		local h = rnd()
		local ops = { { "Reset" } }
		local looks = {}
		for _, n in ipairs({ "SmoothPlastic", "Plastic", "Metal", "Glass", "Ice", "Marble", "Foil", "Neon", "Wood", "Fabric" }) do
			if LOOKS[n] then looks[#looks + 1] = n end
		end
		if #looks > 0 then ops[#ops + 1] = { "Look", pick(looks) } end
		ops[#ops + 1] = { "Reflectance", 0.3 + rnd() * 0.7 }
		ops[#ops + 1] = { "GlossStyle", rnd(4) }
		if rnd() < 0.75 then
			local a = Color3.fromHSV(h, 0.75 + rnd() * 0.25, 1)
			local b = Color3.fromHSV((h + 0.12 + rnd() * 0.5) % 1, 0.75 + rnd() * 0.25, 1)
			local c = rnd() < 0.5 and Color3.fromHSV((h + 0.4 + rnd() * 0.3) % 1, 0.8, 1) or nil
			ops[#ops + 1] = { "Gradient", { a = a, b = b, c = c, axis = pick({ "X", "X", "Y", "Z" }), rev = false, mid = 0.5, smooth = true, stripes = 0, topFlip = false, flow = rnd() < 0.35 and (0.06 + rnd() * 0.3) or 0 } }
		else
			ops[#ops + 1] = { "Color", Color3.fromHSV(h, 0.7 + rnd() * 0.3, 1) }
		end
		if rnd() < 0.6 then
			ops[#ops + 1] = { "Glow", 0.8 + rnd() * 1.8 }
			ops[#ops + 1] = { "GlowHue", rnd() }
			if rnd() < 0.5 then
				ops[#ops + 1] = { "Pulse", 0.25 + rnd() * 1.2 }
				ops[#ops + 1] = { "PulseStyle", pick({ "Sine", "Beat", "Flicker" }) }
			end
		end
		if rnd() < 0.25 then
			ops[#ops + 1] = { "Outline", true }
			ops[#ops + 1] = { "OutlineHue", rnd() }
		end
		if rnd() < 0.55 then ops[#ops + 1] = { pick({ "Sparkle", "Snow", "Sakura", "Firefly", "Bubbles", "Embers" }), true } end
		return ops
	end

	e:title("かんたん")
	e:button("🎲 おまかせスタイル (ぜんぶランダム)", function()
		local m = selected and seenMap[selected]
		if not m or not m.Parent then
			Lib.notif(gui, "板を選んでください", 1.8)
			return
		end
		for _, fn in ipairs(resetters) do pcall(fn) end
		sendMany(m, randomOps(), true)
		dirty[selected] = true
		selVisuals()
		Lib.notif(gui, "おまかせスタイルにしました 🎲 (気に入らなければ、もう一度)", 2)
		if UIs.afterLook then UIs.afterLook(true) end
	end, ACCENT)
	e:button("📋 この板の見た目を、ほかの全部の板にコピー", function()
		local src = selected and seenMap[selected]
		local r = src and recipe[src]
		if not r or #r == 0 then
			Lib.notif(gui, "先にこの板の色や素材を変えてね", 1.8)
			return
		end
		local n = 0
		for idx, m in pairs(seenMap) do
			if m ~= src and m.Parent then
				local ops = { { "Reset" } }
				for _, op in ipairs(r) do ops[#ops + 1] = { op[1], op[2] } end
				sendMany(m, ops, true)
				dirty[idx] = true
				n = n + 1
			end
		end
		selVisuals()
		Lib.notif(gui, n > 0 and ("ほかの " .. n .. " 枚にコピーしました 📋") or "ほかの板がありません", 2)
	end)
	addGrid(fullSets, "✨ 見た目一式 (光・動き・効果つき)")
	addGrid(basics, "基本のプリセット")
end

-- 4: 質感
do
	local e = Lib.element(pages[4])
	local curRefl = 0
	local refS, traS, varS, wthS, texT, quickMark, glossMark, axisMark
	local envOrig = nil   -- 「空の映り込み」を強くする前の値 (この画面だけの設定)
	-- 反射の量に合うチップを光らせる (どれにも当てはまらなければ、どれも光らない)
	local function qm()
		if not quickMark then return end
		quickMark(curRefl <= 0 and 1 or (math.abs(curRefl - 0.35) < 0.005 and 2) or (curRefl >= 0.995 and 3) or 0)
	end

	e:title("反射・ツヤ (素材や木目はそのまま)")
	local reflNote = e:row(isMobile and 78 or 54)
	local reflLbl = text(reflNote, "", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	reflLbl.TextWrapped = true
	local function updateHint()
		local t
		if curRefl <= 0 then
			t = "いまはマット(反射なし)。右へ動かすほど、ツルツルでテカテカになります。素材・色・木目はそのままです。"
		elseif curRefl >= 0.95 then
			t = "反射 100% ✔ 鏡みたいにツルツル。空の映り込みと光の帯を板の上に重ねています (素材・木目は変わりません)。"
		else
			t = "反射 " .. math.floor(curRefl * 100 + 0.5) .. "% ✔ 素材・木目はそのまま。光の帯と空の映り込みでツヤを出しています。"
		end
		reflLbl.Text = t
	end
	refS = e:slider("反射・ツヤ", 0, 1, function(v, r)
		curRefl = v
		qm()
		updateHint()
		sendThrottled("Reflectance", v, r)
	end, 0)
	local function setRefl(v)
		curRefl = v
		refS:set(v)
		updateHint()
		send("Reflectance", v)
	end
	quickMark = chipsRow(e, { "マット 0%", "ツヤ 35%", "ミラー 100%" }, function(i)
		setRefl(({ 0, 0.35, 1 })[i])
	end, 1)
	e:title("ツヤの種類・向き")
	glossMark = chipsRow(e, { "くっきり", "やわらか", "ガラス", "メタル" }, function(i)
		send("GlossStyle", i)
	end, 1)
	axisMark = chipsRow(e, { "横 (X)", "高さ (Y)", "奥 (Z)" }, function(i)
		send("GlossAxis", ({ "X", "Y", "Z" })[i])
	end, 1)
	local envT = e:toggle("空の映り込みを最大に (この画面だけ)", function(sv)
		local L = game:GetService("Lighting")
		if sv then
			if envOrig == nil then
				local ok, v = pcall(function() return L.EnvironmentSpecularScale end)
				envOrig = ok and v or 1
			end
			pcall(function() L.EnvironmentSpecularScale = 1 end)
		elseif envOrig ~= nil then
			pcall(function() L.EnvironmentSpecularScale = envOrig end)
			envOrig = nil
		end
	end, false)

	e:title("見た目")
	traS = e:slider("透明度", 0, 0.9, function(v, r) sendThrottled("Transparency", v, r) end, 0)
	varS = e:slider("色ムラ", 0, 1, function(v, r) sendThrottled("Variance", v, r) end, 0, Color3.fromRGB(99, 102, 241), PINK)
	wthS = e:slider("経年劣化", 0, 1, function(v, r) sendThrottled("Weather", v, r) end, 0, Color3.fromRGB(120, 100, 70), Color3.fromRGB(60, 50, 40))
	e:title("テクスチャ")
	texT = e:toggle("元の木目テクスチャ", function(sv) send("Texture", sv) end, true)

	-- 素材/プリセットを押したあと: 板の本当の値を読み直してスライダーに合わせる (表示と見た目をずらさない)
	local function syncFromBoard()
		local m = selected and seenMap[selected]
		if not m then return end
		local refl, tra = 0, 0
		for _, c in ipairs(m:GetChildren()) do
			if c:IsA("BasePart") and c.Name ~= "Main" and c.Name ~= "SoundPart" then
				refl = math.max(refl, c.Reflectance)
				tra = math.max(tra, c.Transparency)
			end
		end
		curRefl = refl
		refS:set(refl)
		traS:set(tra)
		qm()
		updateHint()
	end
	UIs.texT, UIs.refS, UIs.refHint = texT, refS, updateHint
	UIs.afterLook = function(texOff)
		if texOff then texT:set(false) end
		task.delay(0.7, function() pcall(syncFromBoard) end)
	end
	updateHint()
	onResettable(function()
		curRefl = 0
		refS:set(0) traS:set(0) varS:set(0) wthS:set(0) texT:set(true)
		glossMark(1) axisMark(1)
		qm()
		updateHint()
	end)
end

-- 5: 光
do
	local e = Lib.element(pages[5])
	local glowVal = 0
	e:title("発光")
	local glowS = e:slider("発光の強さ", 0, 5, function(v, r) glowVal = v sendThrottled("Glow", v, r) end, 0, Color3.fromRGB(120, 80, 20), Color3.fromRGB(255, 240, 120))
	local rangeS = e:slider("発光の範囲", 4, 30, function(v, r) sendThrottled("GlowRange", v, r) end, 8)
	local glowHueS = e:slider("発光の色", 0, 1, function(v, r) sendThrottled("GlowHue", v, r) end, 0.58, nil, nil, hueSeq())
	e:title("光り方 (明滅はなめらかに動きます)")
	local pulseS = e:slider("明滅の速さ", 0, 4, function(v, r)
		if v > 0 and glowVal <= 0 then   -- 光が0だと明滅が見えないので、自動で光をつける
			glowVal = 1.5
			glowS:set(1.5)
			send("Glow", 1.5, true)
		end
		sendThrottled("Pulse", v, r)
	end, 0, Color3.fromRGB(99, 102, 241), CYAN)
	local pulseMark = chipsRow(e, { "なめらか", "ドクン", "ゆらぎ", "ピカピカ" }, function(i)
		send("PulseStyle", ({ "Sine", "Beat", "Flicker", "Strobe" })[i])
	end, 1)
	local bodyT = e:toggle("板も一緒に明滅 (板の明るさも変わる)", function(sv) send("PulseBody", sv) end, false)
	local shapeMark = chipsRow(e, { "全方向", "下を照らす", "上を照らす" }, function(i)
		send("LightShape", ({ "Point", "Down", "Up" })[i])
	end, 1)
	local neonT = e:toggle("ネオン発光 (素材をネオンに)", function(sv)
		UIs.neonOn = sv
		send("Neon", sv)
	end, false)
	e:title("縁取り")
	local ot = e:toggle("縁取り", function(sv) send("Outline", sv) end, false)
	local outHueS = e:slider("縁取りの色", 0, 1, function(v, r) ot:set(true) sendThrottled("OutlineHue", v, r) end, 0.55, nil, nil, hueSeq())
	e:title("影")
	local shadowT = e:toggle("板が影を落とす", function(sv) send("Shadow", sv) end, true)
	onResettable(function()
		glowVal = 0
		glowS:set(0) rangeS:set(8) glowHueS:set(0.58) ot:set(false) outHueS:set(0.55)
		pulseS:set(0) pulseMark(1) bodyT:set(false) shapeMark(1) neonT:set(false) shadowT:set(true)
		UIs.neonOn = false
	end)
end

-- 6: 効果
do
	local e = Lib.element(pages[6])
	e:title("🌈 レインボー (なめらかに動きます)")
	local rt = e:toggle("レインボー", function(sv) send("Rainbow", sv) end, false)
	UIs.rbT = rt
	local rbSpeedS = e:slider("虹の速さ", 0.02, 1, function(v, r) rt:set(true) sendThrottled("RainbowSpeed", v, r) end, 0.15)
	local rbSatS = e:slider("鮮やかさ", 0, 1, function(v, r) sendThrottled("RainbowSat", v, r) end, 0.85, WHITE, PINK)
	local rbSpreadS = e:slider("虹の波", 0, 1, function(v, r) rt:set(true) sendThrottled("RainbowSpread", v, r) end, 0, Color3.fromRGB(99, 102, 241), PINK)
	e:title("✨ キラキラ")
	local st_ = e:toggle("キラキラ", function(sv) send("Sparkle", sv) end, false)
	local spRateS = e:slider("キラキラの量", 1, 120, function(v, r) st_:set(true) sendThrottled("SparkleRate", v, r) end, 25, Color3.fromRGB(99, 102, 241), CYAN)
	local spSizeS = e:slider("キラキラの大きさ", 0.05, 2, function(v, r) st_:set(true) sendThrottled("SparkleSize", v, r) end, 0.35, Color3.fromRGB(99, 102, 241), CYAN)
	e:title("🔥 炎 (板の向きに関係なく、必ず上へ昇ります)")
	local fireT = e:toggle("炎", function(sv) send("Fire", sv) end, false)
	local fireSizeS = e:slider("炎の大きさ", 2, 30, function(v, r) fireT:set(true) sendThrottled("FireSize", v, r) end, 6, Color3.fromRGB(120, 40, 10), Color3.fromRGB(255, 190, 60))
	local fireMark = chipsRow(e, { "通常", "青", "緑", "紫", "ピンク" }, function(i)
		fireT:set(true)
		send("FireColor", i)
	end, 1)
	e:title("💨 煙・紙吹雪")
	local smokeT = e:toggle("煙", function(sv) send("Smoke", sv) end, false)
	local confT = e:toggle("紙吹雪", function(sv) send("Confetti", sv) end, false)
	e:title("🌸 ふわふわ")
	local snowT = e:toggle("❄️ 雪", function(sv) send("Snow", sv) end, false)
	local sakuraT = e:toggle("🌸 桜", function(sv) send("Sakura", sv) end, false)
	local fireflyT = e:toggle("✨ ほたる", function(sv) send("Firefly", sv) end, false)
	local bubbleT = e:toggle("🫧 あわ", function(sv) send("Bubbles", sv) end, false)
	local emberT = e:toggle("🔥 火の粉", function(sv) send("Embers", sv) end, false)
	local amountS = e:slider("効果の量 (全部)", 0.2, 3, function(v, r) sendThrottled("FxAmount", v, r) end, 1, Color3.fromRGB(99, 102, 241), CYAN)
	onResettable(function()
		rt:set(false) rbSpeedS:set(0.15) rbSatS:set(0.85) rbSpreadS:set(0)
		st_:set(false) spRateS:set(25) spSizeS:set(0.35)
		fireT:set(false) fireSizeS:set(6) fireMark(1) smokeT:set(false) confT:set(false)
		snowT:set(false) sakuraT:set(false) fireflyT:set(false) bubbleT:set(false) emberT:set(false) amountS:set(1)
	end)
end

-- 7: 視野 (「その他」タブの中の1つめ)
do
	local e = Lib.element(pages[7])
	e:title("視野 (FOV)")
	local cam = workspace.CurrentCamera
	local startFov = cam and math.clamp(math.floor(cam.FieldOfView + 0.5), 70, 120) or 70
	local fovS
	local function setFov(v)
		local cm = workspace.CurrentCamera
		if cm then cm.FieldOfView = v end
	end
	fovS = e:slider("視野 FOV", 70, 120, function(v) setFov(v) end, startFov, Color3.fromRGB(99, 102, 241), CYAN)
	e:button("FOVを70に戻す", function() fovS:set(70) setFov(70) end)
end

-- 8: 軽量化 (「その他」タブの中の2つめ)
do
	local e = Lib.element(pages[8])
	e:title("マップを軽くする")
	local note = e:row(isMobile and 70 or 44)
	local noteLbl = text(note, "マップだけを軽くします。板・キャラにはさわりません。1個ずつ順番に実行するので重くなりにくく、OFFで元に戻ります。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	noteLbl.TextWrapped = true
	-- 進行状況
	local prog = e:glass(isMobile and 58 or 52)
	local progLbl = text(prog, "待機中", isMobile and 13 or 14, UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 22))
	progLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local barBg = mk("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, Position = UDim2.new(0, 12, 1, -16), Size = UDim2.new(1, -24, 0, 6) }, prog)
	corner(barBg, 3)
	local barFill = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, barBg)
	corner(barFill, 3)
	local barGrad = mk("UIGradient", { Color = ColorSequence.new(Lib.ACCENT, Lib.ACCENT2) }, barFill)
	Lib.onTheme(function(a, b) barGrad.Color = ColorSequence.new(a, b) end)
	Opt.onStatus = function(txt, frac)
		progLbl.Text = txt
		if frac then Lib.tween(barFill, { Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1) }, 0.3) end
	end

	e:title("項目 (ONにした順に1個ずつ実行)")
	local togs = {}
	for _, key in ipairs(Opt.ORDER) do
		togs[key] = e:toggle(Opt.LABEL[key], function(s) Opt.set(key, s) end, false)
	end
	e:title("まとめて")
	e:button("▶ 全部ON (順番に実行)", function()
		for _, key in ipairs(Opt.ORDER) do
			togs[key]:set(true)
			Opt.set(key, true)
		end
	end, Lib.ACCENT)
	e:button("⏹ 全部OFF (元に戻す)", function()
		for i = #Opt.ORDER, 1, -1 do
			local key = Opt.ORDER[i]
			togs[key]:set(false)
			Opt.set(key, false)
		end
	end)
	local tip = e:row(isMobile and 110 or 72)
	local tipLbl = text(tip, "ぼかし系はブルーム(光のにじみ)を残すので、板のネオンの光り方は変わりません。「素材を単純化」「高画質テクスチャを外す」「看板・名札を消す」「ループ音を止める」は見た目や音がだいぶ変わります。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	tipLbl.TextWrapped = true
end

-- 9: UI設定 (「その他」タブの中の3つめ)
do
	local e = Lib.element(pages[9])
	e:title("透明度・大きさ")
	local alphaS = e:slider("透明度", 0, 0.6, function(v)
		uiCfg.alpha = v
		if isOpen then win.GroupTransparency = v end
	end, 0)
	local bgAlphaS = e:slider("背景透け", 0, 0.85, function(v)
		uiCfg.bgAlpha = v
		bg.BackgroundTransparency = v
	end, 0)
	-- 大きさは、動かしている最中に画面が拡大縮小すると操作しにくいので、離した時に反映する
	local sizeS = e:slider("大きさ", 0.6, 1.4, function(v, released)
		uiCfg.size = v
		if released and isOpen then
			fit()
			Lib.tween(winScale, { Scale = fitScale }, 0.35)
		end
	end, 1)

	e:title("テーマ色")
	local accCols = isMobile and 4 or 8
	local accRow = e:row(gridHeight(#ACCENTS, accCols, 34, 8))
	grid(accRow, 53, 34, 8, 8)
	local accStrokes = {}
	for i, a in ipairs(ACCENTS) do
		local b = mk("TextButton", { AutoButtonColor = false, BorderSizePixel = 0, Text = "", BackgroundColor3 = WHITE, LayoutOrder = i }, accRow)
		corner(b, 11)
		mk("UIGradient", { Rotation = 35, Color = ColorSequence.new(a[2], a[3]) }, b)
		accStrokes[i] = stroke(b, 0.55, WHITE, 1.5)
		Lib.juice(b)
		b.MouseButton1Click:Connect(function() applyAccent(i) end)
	end
	local lastHue = 0
	local hueS = e:slider("好きな色", 0, 1, function(v, released)
		local now = os.clock()
		if released or now - lastHue > 0.08 then
			lastHue = now
			applyAccent(0, Color3.fromHSV(v, 0.55, 1), Color3.fromHSV((v + 0.12) % 1, 0.6, 1))
		end
	end, 0.58, nil, nil, hueSeq())

	e:title("背景スタイル")
	local stCols = isMobile and 2 or 4
	local stCW = isMobile and 124 or 118
	local stRow = e:row(gridHeight(#STYLES, stCols, 66, 8))
	grid(stRow, stCW, 66, 8, 8)
	local styleStrokes = {}
	for i, st in ipairs(STYLES) do
		local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i }, stRow)
		Lib.glass(b, 0.84, 14)
		styleStrokes[i] = b:FindFirstChildOfClass("UIStroke")
		local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 32) }, b)
		corner(sw, 8)
		mk("UIGradient", { Rotation = 20, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, st.bg[1]), ColorSequenceKeypoint.new(0.55, st.bg[2]), ColorSequenceKeypoint.new(1, st.bg[3]) }) }, sw)
		text(b, st.icon .. " " .. st.name, isMobile and 12 or 13, UDim2.fromOffset(0, 40), UDim2.new(1, 0, 0, 22), Enum.TextXAlignment.Center)
		Lib.juice(b)
		b.MouseButton1Click:Connect(function() applyStyle(i) end)
	end
	local amountS = e:slider("量", 0, 1, function(v) UIFX.setAmount(v) end, 0.6, Color3.fromRGB(99, 102, 241), CYAN)
	local speedS = e:slider("速さ", 0.3, 2.5, function(v) UIFX.setSpeed(v) end, 1, Color3.fromRGB(99, 102, 241), CYAN)

	e:title("動き")
	local blobT = e:toggle("ふわふわ光", function(s)
		blobEnabled = s
		blobsOn(isOpen)
	end, true)
	local spinT = e:toggle("回転アニメ", function(s)
		for _, t in ipairs(spinTw) do
			if s then t:Play() else t:Pause() end
		end
	end, true)
	local juiceT = e:toggle("ぽよぽよ拡大", function(s) Lib.juiceOn = s end, true)

	e:button("UI設定を初期に戻す", function() resetUISettings() end)

	-- 初期に戻す (板には関係しない)
	resetUISettings = function()
		uiCfg.alpha, uiCfg.bgAlpha, uiCfg.size = 0, 0, 1
		alphaS:set(0) bgAlphaS:set(0) sizeS:set(1)
		if isOpen then
			win.GroupTransparency = 0
			fit()
			Lib.tween(winScale, { Scale = fitScale }, 0.35)
		end
		bg.BackgroundTransparency = 0
		applyAccent(1)
		hueS:set(0.58)
		applyStyle(1)
		amountS:set(0.6) UIFX.setAmount(0.6)
		speedS:set(1) UIFX.setSpeed(1)
		blobT:set(true) blobEnabled = true
		spinT:set(true)
		for _, t in ipairs(spinTw) do t:Play() end
		juiceT:set(true) Lib.juiceOn = true
		blobsOn(isOpen)
	end

	-- 選択中のテーマ色・背景スタイルに枠をつける
	local accIdx, styleIdx = 1, 1
	local function mark()
		for i, st in ipairs(accStrokes) do
			st.Transparency = (i == accIdx) and 0 or 0.55
			st.Thickness = (i == accIdx) and 3 or 1.5
		end
		for i, st in ipairs(styleStrokes) do
			st.Transparency = (i == styleIdx) and 0 or 0.58
			st.Color = (i == styleIdx) and Lib.ACCENT or Lib.GRAY
			st.Thickness = (i == styleIdx) and 2.5 or 1
		end
	end
	Lib.onTheme(function() mark() end)
	-- テーマ色: i=0 のときは色を直接指定 (好きな色スライダー)
	applyAccent = function(i, a, b)
		accIdx = i
		if i > 0 then
			a, b = ACCENTS[i][2], ACCENTS[i][3]
		end
		Lib.setAccent(a, b)
		mark()
	end
	applyStyle = function(i)
		styleIdx = i
		local st = STYLES[i]
		-- 背景のグラデーションを、なめらかに次の色へ
		bgFadeId = bgFadeId + 1
		local myId = bgFadeId
		local from = curBg
		local to = st.bg
		task.spawn(function()
			local t0 = os.clock()
			while myId == bgFadeId do
				local k = math.clamp((os.clock() - t0) / 0.8, 0, 1)
				local ease = 1 - (1 - k) ^ 3
				curBg = { from[1]:Lerp(to[1], ease), from[2]:Lerp(to[2], ease), from[3]:Lerp(to[3], ease) }
				bgGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, curBg[1]), ColorSequenceKeypoint.new(0.55, curBg[2]), ColorSequenceKeypoint.new(1, curBg[3]) })
				if k >= 1 then break end
				RunService.Heartbeat:Wait()
			end
		end)
		blobStyleOn = st.blobs ~= nil
		if st.blobs then
			local bl = { blob1, blob2, blob3 }
			for k = 1, 3 do
				Lib.tween(bl[k], { BackgroundColor3 = st.blobs[k][1], BackgroundTransparency = st.blobs[k][2] }, 0.8)
			end
		end
		blobsOn(isOpen)
		UIFX.setStyle(st.fx)
		mark()
	end
	mark()
end

-- ページ切り替え
-- { アイコン, 名前, ページ番号 } (その他は 0 = 中の3ページを切り替える)
local tabs = { {"🏠", "ホーム", 10}, {"🎨", "色", 1}, {"🧱", "素材", 2}, {"✨", "プリセット", 3}, {"💎", "質感", 4}, {"💡", "光", 5}, {"🌈", "効果", 6}, {"⚙️", "その他", 0} }
local OTHER = 8
local tabBtns = {}

-- 「その他」タブの中: 上の切り替えバーで 視野 / 軽量化 / UI設定 を行き来する
local navBar = mk("Frame", { Name = "SubNav", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -22, 0, 32), Visible = false }, content)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, navBar)
local subBtns = {}
local curTab, curSub = 1, 1

-- 10: ホーム (プレイヤーのアイコンと @ID / 板の検出状況 / FPS・Ping)
do
	local e = Lib.element(pages[10])
	local OK_GREEN, BAD_RED = Color3.fromRGB(52, 211, 153), Color3.fromRGB(251, 113, 133)
	local CARD_H = isMobile and 96 or 108
	local card = e:row(CARD_H)
	Lib.glass(card, 0.82, 18)
	local AV = isMobile and 68 or 80
	local avFrame = mk("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.75, BorderSizePixel = 0, Position = UDim2.fromOffset(14, (CARD_H - AV) / 2), Size = UDim2.fromOffset(AV, AV) }, card)
	corner(avFrame, AV / 2)
	local avStroke = stroke(avFrame, 0, ACCENT, 3)
	Lib.onTheme(function(a) avStroke.Color = a end)
	-- アイコンが読み込めるまでは、名前の頭文字を出しておく
	local initial = text(avFrame, string.upper(string.sub(lp.Name, 1, 1)), math.floor(AV * 0.45), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	local avImg = mk("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, ImageTransparency = 1 }, avFrame)
	corner(avImg, AV / 2)
	local nameX = 14 + AV + 14
	local dispLbl = text(card, lp.DisplayName, isMobile and 19 or 23, UDim2.fromOffset(nameX, isMobile and 14 or 18), UDim2.new(1, -nameX - 12, 0, 30))
	dispLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local idLbl = text(card, "@" .. lp.Name, isMobile and 15 or 17, UDim2.fromOffset(nameX, isMobile and 44 or 50), UDim2.new(1, -nameX - 12, 0, 22), nil, CYAN)
	idLbl.TextTruncate = Enum.TextTruncate.AtEnd
	text(card, "UserId " .. tostring(lp.UserId), 12, UDim2.fromOffset(nameX, isMobile and 68 or 76), UDim2.new(1, -nameX - 12, 0, 18), nil, SOFT)
	task.spawn(function()
		for _ = 1, 6 do
			local ok, img, ready = pcall(function()
				return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok and type(img) == "string" and img ~= "" then
				avImg.Image = img
				Lib.tween(avImg, { ImageTransparency = 0 }, 0.6)
				Lib.tween(initial, { TextTransparency = 1 }, 0.4)
				if ready ~= false then break end
			end
			task.wait(1.5)
		end
	end)

	-- 1行ぶんの「ラベル … 値」。値のTextLabelを返す
	local function infoRow(label)
		local r = e:glass(isMobile and 40 or 36)
		text(r, label, isMobile and 13 or 14, UDim2.fromOffset(12, 0), UDim2.new(0.38, 0, 1, 0), nil, SOFT)
		local v = text(r, "-", isMobile and 13 or 14, UDim2.new(0.38, 0, 0, 0), UDim2.new(0.62, -12, 1, 0), Enum.TextXAlignment.Right)
		v.TextTruncate = Enum.TextTruncate.AtEnd
		return v
	end
	e:title("板の検出")
	local vFolder = infoRow("見るフォルダ")
	local vFound = infoRow("フォルダの状態")
	local vCount = infoRow("見つけた板")
	local vSel = infoRow("選択中の板")
	local vSrv = infoRow("サーバー連携")
	local note = e:row(isMobile and 70 or 50)
	local noteLbl = text(note, "検出するのは、Workspace の「@ID + SpawnedInToys」フォルダの直下にある PalletLightBrown だけです。他のフォルダや他の人の板は見ません。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	noteLbl.TextWrapped = true
	e:button("🔄 板を探し直す", function()
		refresh()
		if homeInfo then homeInfo() end
		Lib.notif(gui, "探し直しました", 1.2)
	end)
	e:title("いまの状態")
	local vFps = infoRow("FPS")
	local vPing = infoRow("Ping")

	homeInfo = function()
		local f = myFolder()
		vFolder.Text = toyFolderName()
		vFound.Text = f and "✔ 見つかった" or "✖ まだ無い"
		vFound.TextColor3 = f and OK_GREEN or BAD_RED
		local n = 0
		for _ in pairs(chips) do n = n + 1 end
		vCount.Text = n .. " 枚"
		vSel.Text = selected and ("板" .. selected) or "なし"
		local hasRemote = RS:FindFirstChild("PalletStudioApply_v3") ~= nil
		vSrv.Text = hasRemote and "✔ つながっている" or "✖ 未接続 (この画面だけ)"
		vSrv.TextColor3 = hasRemote and OK_GREEN or BAD_RED
	end
	homeInfo()

	-- FPS と Ping は、ホームを開いている間だけ0.5秒ごとに更新する
	local frames = 0
	RunService.Heartbeat:Connect(function() frames = frames + 1 end)
	task.spawn(function()
		local t0 = os.clock()
		while true do
			task.wait(0.5)
			local now = os.clock()
			local fps = frames / math.max(now - t0, 0.001)
			frames, t0 = 0, now
			if isOpen and curTab == 1 then
				vFps.Text = tostring(math.floor(fps + 0.5))
				local ok, ping = pcall(function() return lp:GetNetworkPing() end)
				vPing.Text = (ok and type(ping) == "number") and (tostring(math.floor(ping * 1000 + 0.5)) .. " ms") or "-"
			end
		end
	end)
end
local function showSub(k)
	curSub = k
	for j = 1, 3 do
		pages[6 + j].Visible = (curTab == OTHER and j == k)
		local active = (j == k)
		Lib.tween(subBtns[j], { BackgroundColor3 = active and Lib.ACCENT or WHITE, BackgroundTransparency = active and 0.15 or 0.88 }, 0.25)
	end
end
for j, nm in ipairs({ "👁 視野", "🚀 軽量化", "🎨 UI設定" }) do
	local b = mk("TextButton", { Name = "Sub" .. j, AutoButtonColor = false, Text = nm, TextSize = isMobile and 13 or 15, FontFace = FONT, TextColor3 = WHITE, LayoutOrder = j, Size = UDim2.new(1 / 3, -4, 1, 0) }, navBar)
	Lib.glass(b, 0.88, 10)
	Lib.juice(b)
	b.MouseButton1Click:Connect(function() showSub(j) end)
	subBtns[j] = b
end

local PAGE_TABS = { 1, 2, 3, 4, 5, 6, 10 }
local function showTab(i)
	local changed = (curTab ~= i)
	curTab = i
	local want = tabs[i][3]
	for _, j in ipairs(PAGE_TABS) do pages[j].Visible = (j == want) end
	navBar.Visible = (i == OTHER)
	showSub(curSub)
	if want > 0 and changed then
		-- ページがふわっと横から入ってくる
		local pg = pages[want]
		pg.Position = UDim2.fromOffset(18, 0)
		Lib.tween(pg, { Position = UDim2.fromOffset(0, 0) }, 0.4)
	end
	if i == 1 and homeInfo then pcall(homeInfo) end
	for j, b in ipairs(tabBtns) do
		local active = (j == i)
		Lib.tween(b, { BackgroundColor3 = active and Lib.ACCENT or WHITE, BackgroundTransparency = active and 0.15 or 0.9 }, 0.3)
	end
end

-- テーマ色が変わったら、色を使っている部品を付け替える
Lib.onTheme(function(a, b)
	toggleGrad.Color = ColorSequence.new(a:Lerp(Color3.new(0, 0, 0), 0.25), b:Lerp(Color3.new(0, 0, 0), 0.1))
	ringGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, a:Lerp(WHITE, 0.4)), ColorSequenceKeypoint.new(0.5, b:Lerp(WHITE, 0.2)), ColorSequenceKeypoint.new(1, a:Lerp(WHITE, 0.4)) })
	titleGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.5, a:Lerp(WHITE, 0.3)), ColorSequenceKeypoint.new(1, WHITE) })
	winStrokeGrad.Color = ColorSequence.new(WHITE, b)
	for j, tb in ipairs(tabBtns) do
		if j == curTab then tb.BackgroundColor3 = a end
	end
	for j, sb in ipairs(subBtns) do
		if j == curSub then sb.BackgroundColor3 = a end
	end
	for _, c in pairs(chips) do
		if c.active then c.btn.BackgroundColor3 = a end
	end
end)
for i, t in ipairs(tabs) do
	local tabText = isMobile and t[1] or (t[1] .. "  " .. t[2])
	local b = mk("TextButton", { Name = "Tab" .. i, AutoButtonColor = false, Text = tabText, TextSize = isMobile and 22 or 16, FontFace = FONT, TextColor3 = WHITE, TextXAlignment = isMobile and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left, LayoutOrder = i, Size = UDim2.new(1, 0, 0, isMobile and 48 or 34) }, side)
	Lib.glass(b, 0.9, 13)
	if not isMobile then
		mk("UIPadding", { PaddingLeft = UDim.new(0, 14) }, b)
	end
	Lib.juice(b)
	b.MouseButton1Click:Connect(function() showTab(i) end)
	tabBtns[i] = b
end

-- 開閉
fit = function()
	local vp = gui.AbsoluteSize
	local base = math.clamp(math.min((vp.X - 48) / W, (vp.Y - 48) / H), 0.4, 1)
	local cap = math.max(math.min((vp.X - 16) / W, (vp.Y - 16) / H), base)   -- 画面に収まる最大
	fitScale = math.clamp(base * uiCfg.size, 0.3, cap)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if isOpen then
		fit()
		Lib.tween(winScale, { Scale = fitScale }, 0.3)
	end
end)

local function setOpen(open)
	if open == isOpen then return end
	isOpen = open
	if open then
		fit()
		refresh()
		win.Visible = true
		winScale.Scale = 0.9 * fitScale
		blobsOn(true)
		UIFX.start()
		Lib.tween(winScale, { Scale = fitScale }, 0.6)
		Lib.tween(win, { GroupTransparency = uiCfg.alpha }, 0.4)
	else
		selVisuals()
		Lib.tween(winScale, { Scale = 0.9 * fitScale }, 0.4)
		local t = Lib.tween(win, { GroupTransparency = 1 }, 0.3)
		t.Completed:Connect(function()
			if not isOpen then
				win.Visible = false
				blobsOn(false)
				UIFX.stop()
			end
		end)
	end
end

Lib.drag(toggle, toggle, function() setOpen(not isOpen) end)
Lib.drag(topbar, win)
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
minBtn.MouseButton1Click:Connect(function() setOpen(false) end)
resetBtn.MouseButton1Click:Connect(function()
	send("Reset", nil)
	for _, fn in ipairs(resetters) do pcall(fn) end
end)
saveBtn.MouseButton1Click:Connect(function()
	local idx = selected
	if not idx then return end
	dirty[idx] = nil
	flashUntil = 0
	selVisuals()
	Lib.notif(gui, "保存しました ✔", 1.6)
end)

permBtn.MouseButton1Click:Connect(function()
	if permanentOps then   -- 保存中にもう一度押すと解除
		permanentOps = nil
		permServer = false
		updatePerm()
		Lib.notif(gui, "永久保存を解除しました (これから出す板には反映しません)", 2.2)
		local pr = RS:FindFirstChild("PalletStudioPerm_v3")
		if pr then   -- サーバーに預けていた分も、確実に解除する (失敗したら少し待って、もう一度)
			task.spawn(function()
				for _ = 1, 3 do
					local ok = pcall(function() return pr:InvokeServer(nil) end)
					if ok or permanentOps then return end
					task.wait(0.5)
				end
			end)
		end
		return
	end
	local model = selected and seenMap[selected]
	local r = model and recipe[model]
	if not r or #r == 0 then
		Lib.notif(gui, "先に色や素材を変えてから押してね", 1.8)
		return
	end
	local copy = {}
	for k, op in ipairs(r) do copy[k] = { op[1], op[2] } end
	permanentOps = copy
	permServer = false
	updatePerm()
	Lib.notif(gui, "永久保存しました 📌 これから出す板に自動で反映します (もう一度押すと解除)", 2.6)
	-- サーバーに預けておくと、板が出たのと同じ瞬間にサーバーが付けてくれる (ここから送り直すより速い)。預けられるまでは、この画面から送る
	local pr = RS:FindFirstChild("PalletStudioPerm_v3")
	if pr then
		task.spawn(function()
			local ok, res = pcall(function() return pr:InvokeServer(copy) end)
			if ok and res == "saved" and permanentOps == copy then permServer = true end
		end)
	end
end)

ringGrad.Rotation = 0
spinTw[1] = TweenService:Create(ringGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
spinTw[2] = TweenService:Create(titleGrad, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
for _, t in ipairs(spinTw) do t:Play() end

workspace.DescendantAdded:Connect(function(m)
	if not isMyBoard(m) then return end
	-- 板の中身が出そろうのを少し待って、一覧を更新し直す
	if isOpen then
		task.delay(0.5, refresh)
		task.delay(1.5, refresh)
	end
	if permanentOps then
		local function copyOps()
			local ops = {}
			for k, op in ipairs(permanentOps) do ops[k] = { op[1], op[2] } end
			return ops
		end
		if permServer then
			-- サーバーが、板が出たのと同じ瞬間に付けてくれる。この画面は、履歴(recipe)だけ合わせておく
			recipe[m] = copyOps()
		else
			task.spawn(function()
				-- 待たずに、板の中身が出たらすぐ送る (出ていなければ1フレームずつ見る)
				local t0 = os.clock()
				while not m:FindFirstChildWhichIsA("BasePart") do
					if not m.Parent or os.clock() - t0 > 3 then return end
					RunService.Heartbeat:Wait()
				end
				if not RS:FindFirstChild("PalletStudioApply_v3") then task.wait(0.15) end   -- サーバーが無い時だけ: この画面に直接付けるので、中身が出そろうのを少し待つ
				if not permanentOps or not m.Parent or not isMyBoard(m) then return end   -- 待っている間に解除された/消えた
				if permServer then   -- 待っている間にサーバーへ預け終わった: サーバーが付けるので、送らない
					recipe[m] = copyOps()
					return
				end
				sendMany(m, copyOps(), true)
			end)
		end
	end
end)
workspace.DescendantRemoving:Connect(function(m)
	if isOpen and m.Name == "PalletLightBrown" then task.delay(0.1, refresh) end
end)
-- 自分のフォルダ自体が出来た/消えた時も一覧を更新する (フォルダは自動では作らない。ゲーム側が作った物を待つだけ)
workspace.ChildAdded:Connect(function(c)
	if isOpen and c.Name == toyFolderName() then task.delay(0.3, refresh) end
end)
workspace.ChildRemoved:Connect(function(c)
	if isOpen and c.Name == toyFolderName() then task.delay(0.1, refresh) end
end)

showTab(1)
-- 起動時: 右下に "make by aino" を表示する。丸いエンブレムがポンと出て、横にのびて文字が下からせり上がる。
-- 終わったら丸に戻って右へ消え、そのあと開閉ボタンが出る (revealToggle)。
local function playCredit()
	local TextService = game:GetService("TextService")
	local EXP, QUINT, SINE, LINEAR = Enum.EasingStyle.Exponential, Enum.EasingStyle.Quint, Enum.EasingStyle.Sine, Enum.EasingStyle.Linear
	local OUT, IN, INOUT = Enum.EasingDirection.Out, Enum.EasingDirection.In, Enum.EasingDirection.InOut
	local function tw(o, t, props, style, dir)
		local x = TweenService:Create(o, TweenInfo.new(t, style or QUINT, dir or OUT), props)
		x:Play()
		return x
	end

	local cg = mk("ScreenGui", { Name = "PalletStudioCredit", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 2147483646, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, lp:WaitForChild("PlayerGui"))
	local creditY = isMobile and -110 or -28   -- スマホはジャンプボタンと重ならない高さ
	local MARGIN = 28
	local PH, EMB, FS = 56, 56, 22             -- ピルの高さ / 右端のエンブレム領域 / 文字サイズ
	local str = "make by aino"

	-- 1文字ずつの幅を測って、全体の幅を決める
	local widths, textW = {}, 0
	for i = 1, #str do
		local ch = str:sub(i, i)
		local w = 7
		if ch ~= " " then
			local ok, sz = pcall(function() return TextService:GetTextSize(ch, FS, Enum.Font.FredokaOne, Vector2.new(200, 30)) end)
			w = (ok and sz) and (math.ceil(sz.X) + 1) or 13
		end
		widths[i] = w
		textW = textW + w
	end
	local PW = 22 + textW + 4 + EMB

	-- ピル本体: 最初は丸(エンブレムだけ)の大きさ。右端を基準に左へのびる
	local pill = mk("CanvasGroup", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 50, 1, creditY + 8), Size = UDim2.fromOffset(PH, PH), BackgroundTransparency = 1, GroupTransparency = 1, BorderSizePixel = 0 }, cg)
	corner(pill, PH / 2)
	local edge = stroke(pill, 0.15, WHITE, 1.6)
	local edgeGrad = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.35, PINK), ColorSequenceKeypoint.new(0.7, CYAN), ColorSequenceKeypoint.new(1, WHITE) }) }, edge)
	local sc = mk("UIScale", { Scale = 0.7 }, pill)
	local bgf = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, pill)
	local bgGrad = mk("UIGradient", { Rotation = 20, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 27, 90)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(101, 31, 190)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 100, 180)) }) }, bgf)

	-- 右端のエンブレム (くるっと回って止まる)
	local emb = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -EMB / 2, 0.5, 0), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = WHITE, BackgroundTransparency = 0.82, BorderSizePixel = 0 }, pill)
	corner(emb, 19)
	stroke(emb, 0.55, WHITE, 1)
	local star = mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Text = "✦", TextSize = 24, FontFace = FONT, TextColor3 = WHITE, Rotation = -180 }, emb)
	mk("UIGradient", { Color = ColorSequence.new(PINK, CYAN), Rotation = 45 }, star)

	-- 文字: 1文字ずつ枠で切って、下からせり上がらせる
	local holder = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(EMB + 2), 0.5, 0), Size = UDim2.fromOffset(textW, 30) }, pill)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, holder)
	local letters = {}
	local nAino = 4   -- "aino" の4文字だけ色グラデーション
	for i = 1, #str do
		local ch = str:sub(i, i)
		local wrap = mk("Frame", { BackgroundTransparency = 1, LayoutOrder = i, Size = UDim2.fromOffset(widths[i], 30), ClipsDescendants = true }, holder)
		local lb = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 30), Size = UDim2.fromScale(1, 1), Text = ch, TextSize = FS, FontFace = FONT, TextColor3 = SOFT, TextTransparency = 0.6 }, wrap)
		local k = i - (#str - nAino)
		if k >= 1 then
			lb.TextColor3 = WHITE
			mk("UIGradient", { Color = ColorSequence.new(PINK:Lerp(CYAN, (k - 1) / nAino), PINK:Lerp(CYAN, k / nAino)), Rotation = 0 }, lb)
		end
		letters[i] = lb
	end

	-- 光が横切る / 下の細い線がのびる
	local shine = mk("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.2, 0, 0.5, 0), Size = UDim2.fromOffset(30, 110), Rotation = 20, ZIndex = 5 }, pill)
	mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, shine)
	local line = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(0, 0, 0, 3), ZIndex = 4 }, pill)
	mk("UIGradient", { Color = ColorSequence.new(PINK, CYAN) }, line)

	-- 火花: ピルの外まで飛ぶので、ピルではなく画面側に置く
	local function burst()
		local cx, cy = -(MARGIN + EMB / 2), creditY - PH / 2
		for i = 1, 8 do
			local ang = (i / 8) * math.pi * 2 + math.random() * 0.5
			local d = 26 + math.random() * 16
			local dot = mk("Frame", { BackgroundColor3 = (i % 2 == 0) and PINK or CYAN, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, cx, 1, cy), Size = UDim2.fromOffset(5, 5) }, cg)
			corner(dot, 3)
			tw(dot, 0.8, { Position = UDim2.new(1, cx + math.cos(ang) * d, 1, cy + math.sin(ang) * d), BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1) }, EXP, OUT)
			task.delay(0.9, function() dot:Destroy() end)
		end
	end

	-- 1) 登場: 丸が右下からふわっと出てくる
	tw(pill, 0.9, { Position = UDim2.new(1, -MARGIN, 1, creditY) }, EXP, OUT)
	tw(pill, 0.5, { GroupTransparency = 0 }, QUINT, OUT)
	tw(sc, 0.9, { Scale = 1 }, EXP, OUT)
	tw(star, 1.3, { Rotation = 0 }, EXP, OUT)
	TweenService:Create(edgeGrad, TweenInfo.new(2.4, LINEAR, IN, -1), { Rotation = 360 }):Play()
	TweenService:Create(bgGrad, TweenInfo.new(6, LINEAR, IN, -1), { Rotation = 380 }):Play()
	task.delay(0.35, burst)
	-- 2) 横にのびる
	task.delay(0.55, function() tw(pill, 0.95, { Size = UDim2.fromOffset(PW, PH) }, QUINT, OUT) end)
	-- 3) 文字が1つずつせり上がる
	for i, lb in ipairs(letters) do
		task.delay(0.95 + i * 0.045, function()
			if lb.Parent then tw(lb, 0.7, { Position = UDim2.fromOffset(0, 0), TextTransparency = 0 }, EXP, OUT) end
		end)
	end
	-- 4) 光が横切り、下の線がのびていく
	task.delay(1.0, function()
		if line.Parent then tw(line, 2.2, { Size = UDim2.new(1, 0, 0, 3) }, LINEAR, OUT) end
	end)
	task.delay(1.7, function()
		if shine.Parent then tw(shine, 1.0, { Position = UDim2.new(1.2, 0, 0.5, 0) }, SINE, INOUT) end
	end)
	task.wait(3.4)

	-- 5) 退場: 文字が上へ抜ける → 丸に戻る → 右へ消える
	for i = #letters, 1, -1 do
		local lb = letters[i]
		task.delay((#letters - i) * 0.02, function()
			if lb.Parent then tw(lb, 0.35, { Position = UDim2.fromOffset(0, -30), TextTransparency = 1 }, QUINT, IN) end
		end)
	end
	tw(line, 0.3, { BackgroundTransparency = 1 }, QUINT, OUT)
	task.wait(0.35)
	tw(pill, 0.55, { Size = UDim2.fromOffset(PH, PH) }, QUINT, INOUT)
	task.wait(0.45)
	tw(pill, 0.6, { Position = UDim2.new(1, 60, 1, creditY), GroupTransparency = 1 }, QUINT, IN)
	tw(sc, 0.6, { Scale = 0.75 }, QUINT, IN)
	task.wait(0.65)
	cg:Destroy()
end

-- 演出が終わったら (途中でエラーになっても) 開閉ボタンを出す
task.spawn(function()
	local ok, err = pcall(playCredit)
	if not ok then warn("[PalletStudio] 起動演出でエラー: " .. tostring(err)) end
	revealToggle()
end)
