-- PalletStudio (LocalScript): StarterPlayer > StarterPlayerScripts に入れる (これ1個だけで動く)
-- 検出: Workspace直下に自動生成される「<自分のUserId>_SpawnedInToys」フォルダの中の参照だけを「板1, 板2…」として出す
--       (他プレイヤーのフォルダ/板は構造的に見えない)。専用フォルダがまだ無い瞬間は、共有フォルダを OwnerUserId で直接確認する保険あり。
-- 起動時に必ず、サーバー用コードを CodeLoader (ServerScriptService) へ送る。サーバー側が無ければ、この画面だけに直接反映する。
-- 「その他」タブの中: 視野 / 軽量化(マップだけ・1項目ずつ順番に実行・OFFで元に戻る) / UI設定(透明度・大きさ・テーマ色・背景アニメ)
-- 板を切り替えた時は、スライダー/トグルの表示だけを初期位置へ戻す(板そのものは「元に戻す」ボタンの時だけ戻る)。
-- 起動時、右下に make by aino の演出が出て、終わると開閉ボタンが現れる。

local RS_ = game:GetService("ReplicatedStorage")
local SERVER_CODE = [=====[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FOLDER_NAME = "tntnmziSpawnedInToys"
local folder = workspace:FindFirstChild(FOLDER_NAME)
if not folder then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = workspace
end

-- プレイヤーが参加したら、Workspace直下に「<UserId>_SpawnedInToys」フォルダを自動生成する。
-- 実体の板(Model)は本体(SpawnToyServer)の管理どおり tntnmziSpawnedInToys から動かさない
-- (個数制限などSpawnToyServer側の挙動を壊さないため)。代わりに、このフォルダの中には
-- 本人の板を指す ObjectValue(参照)だけを置く。クライアントはこの参照先だけを「自分の板」として扱うので、
-- 他プレイヤーのフォルダ/板は構造的に見えない。
local function playerFolderName(player)
	return tostring(player.UserId) .. "_SpawnedInToys"
end

local function getPlayerFolder(player)
	local name = playerFolderName(player)
	local f = workspace:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = workspace
	end
	return f
end

local function refKey(model)
	return "ref_" .. model:GetDebugId()
end

local function unlinkBoard(model)
	local owner = model:GetAttribute("OwnerUserId")
	if not owner then return end
	local player = Players:GetPlayerByUserId(owner)
	if not player then return end
	local pf = workspace:FindFirstChild(playerFolderName(player))
	if not pf then return end
	local ref = pf:FindFirstChild(refKey(model))
	if ref then ref:Destroy() end
end

local function linkBoard(model)
	if not model:IsA("Model") or model.Name ~= "PalletLightBrown" then return end
	local owner = model:GetAttribute("OwnerUserId")
	if not owner then return end
	local player = Players:GetPlayerByUserId(owner)
	if not player then return end
	local pf = getPlayerFolder(player)
	local key = refKey(model)
	if pf:FindFirstChild(key) then return end
	local ref = Instance.new("ObjectValue")
	ref.Name = key
	ref.Value = model
	ref.Parent = pf
end

for _, p in ipairs(Players:GetPlayers()) do
	getPlayerFolder(p)
end
Players.PlayerAdded:Connect(getPlayerFolder)

for _, c in ipairs(folder:GetChildren()) do
	linkBoard(c)
end
folder.ChildAdded:Connect(linkBoard)
folder.ChildRemoved:Connect(unlinkBoard)
-- OwnerUserId がまだ付いていない瞬間に板が追加されることがあるので、少し待って再試行する
folder.ChildAdded:Connect(function(model)
	task.delay(0.5, function()
		if model.Parent == folder then linkBoard(model) end
	end)
end)
local MATERIAL_SET = {}
for _, n in ipairs({ "Plastic", "SmoothPlastic", "Wood", "WoodPlanks", "Metal", "DiamondPlate", "Foil", "Neon", "Glass", "Ice", "Marble", "Granite", "Slate", "Concrete", "Brick", "Cobblestone", "Sand", "Fabric", "ForceField" }) do MATERIAL_SET[n] = true end

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

local orig = setmetatable({}, { __mode = "k" })
local stateOf = setmetatable({}, { __mode = "k" })
local rainbowSet = {}
local rainbowParts = setmetatable({}, { __mode = "k" })   -- レインボー対象のパーツ一覧キャッシュ

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
	if not orig[p] then orig[p] = { p.Color, p.Material, p.Reflectance, p.Transparency } end
	return orig[p]
end

local function glowHost(model)
	return model:FindFirstChild("SoundPart") or model.PrimaryPart
end

local function paint(model, parts, c)
	local s = st(model)
	s.base = c
	local amt = s.variance or 0
	local h, sa, v = c:ToHSV()
	for i, p in ipairs(parts) do
		remember(p)
		if amt > 0 then
			local r = ((i * 37) % 17) / 16 - 0.5
			p.Color = Color3.fromHSV(h, sa, math.clamp(v + r * amt * 0.6, 0, 1))
		else
			p.Color = c
		end
	end
end

local function setGlow(model, color, brightness, range)
	local h = glowHost(model)
	if not h then return end
	local l = h:FindFirstChild("SkinGlow")
	if brightness <= 0 then
		if l then l:Destroy() end
		return
	end
	if not l then
		l = Instance.new("PointLight")
		l.Name = "SkinGlow"
		l.Shadows = false
		l.Parent = h
	end
	l.Color = color
	l.Brightness = brightness
	l.Range = range or l.Range
end

local function setSparkle(model, on, rate, size)
	local h = glowHost(model)
	if not h then return end
	local e = h:FindFirstChild("SkinSparkle")
	if not on then
		if e then e:Destroy() end
		return
	end
	if not e then
		e = Instance.new("ParticleEmitter")
		e.Name = "SkinSparkle"
		e.Lifetime = NumberRange.new(1, 2)
		e.Speed = NumberRange.new(1, 3)
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		e.LightEmission = 1
		e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		e.EmissionDirection = Enum.NormalId.Top
		e.Shape = Enum.ParticleEmitterShape.Box
		e.Rate = 25
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = h
	end
	if rate then e.Rate = rate end
	if size then e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) }) end
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

local function applySkin(model, kind, value)
	local parts = partsOf(model)
	if #parts == 0 then return "板の部品が見つかりません" end
	local s = st(model)

	if kind == "Color" then
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
		rainbowSet[model] = nil
		s.glowColor = nil
		setTexture(parts, false)
		paint(model, parts, lk[1])
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[lk[2]]
			p.Reflectance = lk[3]
			p.Transparency = lk[4]
		end
		setGlow(model, lk[1], lk[5], 10)
		return "素材「" .. value .. "」にしました"
	elseif kind == "Preset" then
		local pr = typeof(value) == "string" and PRESETS[value] or nil
		if not pr then return "プリセットが不正です" end
		rainbowSet[model] = nil
		paint(model, parts, pr.Color)
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[pr.Material]
			p.Reflectance = pr.Reflectance
			p.Transparency = pr.Transparency
		end
		s.glowColor = nil
		setGlow(model, pr.Color, pr.Glow, pr.Range)
		return "プリセット「" .. value .. "」を適用しました"
	elseif kind == "Reflectance" then
		if not isNum(value) then return "値が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Reflectance = math.clamp(value, 0, 1) end
		return "反射を変えました"
	elseif kind == "Transparency" then
		if not isNum(value) then return "値が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Transparency = math.clamp(value, 0, 0.9) end
		return "透明度を変えました"
	elseif kind == "Variance" then
		if not isNum(value) then return "値が不正です" end
		s.variance = math.clamp(value, 0, 1)
		paint(model, parts, s.base or parts[1].Color)
		return "色ムラを変えました"
	elseif kind == "Texture" then
		setTexture(parts, value == true)
		return value == true and "テクスチャON" or "テクスチャOFF"
	elseif kind == "Glow" then
		if not isNum(value) then return "値が不正です" end
		setGlow(model, s.glowColor or s.base or parts[1].Color, math.clamp(value, 0, 5), nil)
		return "発光を変えました"
	elseif kind == "GlowRange" then
		if not isNum(value) then return "値が不正です" end
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		setGlow(model, s.glowColor or s.base or parts[1].Color, l and l.Brightness or 1, math.clamp(value, 4, 30))
		return "発光の範囲を変えました"
	elseif kind == "GlowHue" then
		if not isNum(value) then return "値が不正です" end
		s.glowColor = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then l.Color = s.glowColor end
		return "発光の色を変えました"
	elseif kind == "Rainbow" then
		rainbowSet[model] = (value == true) or nil
		rainbowParts[model] = nil
		return value == true and "レインボーON" or "レインボーOFF"
	elseif kind == "RainbowSpeed" then
		if not isNum(value) then return "値が不正です" end
		s.rbSpeed = math.clamp(value, 0.02, 1)
		return "レインボーの速さを変えました"
	elseif kind == "RainbowSat" then
		if not isNum(value) then return "値が不正です" end
		s.rbSat = math.clamp(value, 0, 1)
		return "レインボーの鮮やかさを変えました"
	elseif kind == "Sparkle" then
		setSparkle(model, value == true)
		return value == true and "キラキラON" or "キラキラOFF"
	elseif kind == "SparkleRate" then
		if not isNum(value) then return "値が不正です" end
		setSparkle(model, true, math.clamp(value, 1, 120), nil)
		return "キラキラの量を変えました"
	elseif kind == "SparkleSize" then
		if not isNum(value) then return "値が不正です" end
		setSparkle(model, true, nil, math.clamp(value, 0.05, 2))
		return "キラキラの大きさを変えました"
	elseif kind == "Outline" then
		setOutline(model, value == true)
		return value == true and "縁取りON" or "縁取りOFF"
	elseif kind == "OutlineHue" then
		if not isNum(value) then return "値が不正です" end
		setOutline(model, true, Color3.fromHSV(math.clamp(value, 0, 1), 0.75, 1))
		return "縁取りの色を変えました"
	elseif kind == "Reset" then
		rainbowSet[model] = nil
		stateOf[model] = nil
		setGlow(model, Color3.new(1, 1, 1), 0, nil)
		setSparkle(model, false)
		setOutline(model, false)
		setTexture(parts, true)
		for _, p in ipairs(parts) do
			local o = orig[p]
			if o then
				p.Color, p.Material, p.Reflectance, p.Transparency = o[1], o[2], o[3], o[4]
			end
		end
		return "元に戻しました"
	end
	return "不明な操作です"
end

-- レインボーは毎フレーム更新 (Heartbeat) で滑らかに。パーツ一覧はキャッシュして毎回は数え直さない。
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
	if next(rainbowSet) == nil then return end
	local now = os.clock()
	for m in pairs(rainbowSet) do
		if m.Parent then
			local s = st(m)
			local col = Color3.fromHSV((now * (s.rbSpeed or 0.15)) % 1, s.rbSat or 0.85, 1)
			local parts = rainbowParts[m]
			if not parts then
				parts = partsOf(m)
				rainbowParts[m] = parts
			end
			for _, p in ipairs(parts) do
				if p.Parent then p.Color = col end
			end
			local h = glowHost(m)
			local l = h and h:FindFirstChild("SkinGlow")
			if l then l.Color = col end
		else
			rainbowSet[m] = nil
			rainbowParts[m] = nil
		end
	end
end)
local remote = ReplicatedStorage:FindFirstChild("PalletStudioApply_v2")
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "PalletStudioApply_v2"
	remote.Parent = ReplicatedStorage
end
-- 操作してきたプレイヤー本人の板かどうか。SpawnToyServer が板に付けている OwnerUserId Attribute を正とする。
-- 古い板など Attribute が無い場合だけ PlayerValue (あれば) で判定し、何も無ければ許可する。
local function isOwnedBy(model, player)
	local owner = model:GetAttribute("OwnerUserId")
	if owner ~= nil then return owner == player.UserId end
	local pv = model:FindFirstChild("PlayerValue")
	if not pv or not pv:IsA("ValueBase") then return true end
	local v = pv.Value
	if typeof(v) == "Instance" then return v == player end
	if typeof(v) == "string" then return v == player.Name or v == player.DisplayName or v == tostring(player.UserId) end
	if typeof(v) == "number" then return v == player.UserId end
	return true
end

local last = {}
remote.OnServerInvoke = function(player, kind, target, value)
	if typeof(kind) ~= "string" or typeof(target) ~= "Instance" then return nil end
	if not target:IsA("Model") or target.Name ~= "PalletLightBrown" or not target:IsDescendantOf(folder) then return nil end
	if not isOwnedBy(target, player) then return "他のプレイヤーの板は変更できません" end
	local now = os.clock()
	if (last[player] or 0) + 0.03 > now then return nil end
	last[player] = now
	local ok, msg = pcall(applySkin, target, kind, value)
	if ok then return msg end
	return "エラーが発生しました"
end
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
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
local FOLDER = "tntnmziSpawnedInToys"
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

	-- ドラッグ (動かさずに離したら onClick)
	function M.drag(handle, target, onClick, scaleObj)
		local dragging, moved = false, false
		local startPos, startUI, lastInput
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging, moved = true, false
				startPos, startUI = i.Position, target.Position
				i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then
						if dragging and not moved and onClick then onClick() end
						dragging = false
					end
				end)
			end
		end)
		handle.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
				lastInput = i
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if i == lastInput and dragging then
				local k = scaleObj and scaleObj.Scale or 1
				local d = (i.Position - startPos) / math.max(k, 0.01)
				if not moved and d.Magnitude < 6 then return end
				moved = true
				M.tween(target, { Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y) }, 0.15)
			end
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
local MATERIAL_SET = {}
for _, n in ipairs({ "Plastic", "SmoothPlastic", "Wood", "WoodPlanks", "Metal", "DiamondPlate", "Foil", "Neon", "Glass", "Ice", "Marble", "Granite", "Slate", "Concrete", "Brick", "Cobblestone", "Sand", "Fabric", "ForceField" }) do MATERIAL_SET[n] = true end

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

local orig = setmetatable({}, { __mode = "k" })
local stateOf = setmetatable({}, { __mode = "k" })
local rainbowSet = {}
local rainbowParts = setmetatable({}, { __mode = "k" })   -- レインボー対象のパーツ一覧キャッシュ

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
	if not orig[p] then orig[p] = { p.Color, p.Material, p.Reflectance, p.Transparency } end
	return orig[p]
end

local function glowHost(model)
	return model:FindFirstChild("SoundPart") or model.PrimaryPart
end

local function paint(model, parts, c)
	local s = st(model)
	s.base = c
	local amt = s.variance or 0
	local h, sa, v = c:ToHSV()
	for i, p in ipairs(parts) do
		remember(p)
		if amt > 0 then
			local r = ((i * 37) % 17) / 16 - 0.5
			p.Color = Color3.fromHSV(h, sa, math.clamp(v + r * amt * 0.6, 0, 1))
		else
			p.Color = c
		end
	end
end

local function setGlow(model, color, brightness, range)
	local h = glowHost(model)
	if not h then return end
	local l = h:FindFirstChild("SkinGlow")
	if brightness <= 0 then
		if l then l:Destroy() end
		return
	end
	if not l then
		l = Instance.new("PointLight")
		l.Name = "SkinGlow"
		l.Shadows = false
		l.Parent = h
	end
	l.Color = color
	l.Brightness = brightness
	l.Range = range or l.Range
end

local function setSparkle(model, on, rate, size)
	local h = glowHost(model)
	if not h then return end
	local e = h:FindFirstChild("SkinSparkle")
	if not on then
		if e then e:Destroy() end
		return
	end
	if not e then
		e = Instance.new("ParticleEmitter")
		e.Name = "SkinSparkle"
		e.Lifetime = NumberRange.new(1, 2)
		e.Speed = NumberRange.new(1, 3)
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		e.LightEmission = 1
		e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		e.EmissionDirection = Enum.NormalId.Top
		e.Shape = Enum.ParticleEmitterShape.Box
		e.Rate = 25
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = h
	end
	if rate then e.Rate = rate end
	if size then e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) }) end
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

local function applySkin(model, kind, value)
	local parts = partsOf(model)
	if #parts == 0 then return "板の部品が見つかりません" end
	local s = st(model)

	if kind == "Color" then
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
		rainbowSet[model] = nil
		s.glowColor = nil
		setTexture(parts, false)
		paint(model, parts, lk[1])
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[lk[2]]
			p.Reflectance = lk[3]
			p.Transparency = lk[4]
		end
		setGlow(model, lk[1], lk[5], 10)
		return "素材「" .. value .. "」にしました"
	elseif kind == "Preset" then
		local pr = typeof(value) == "string" and PRESETS[value] or nil
		if not pr then return "プリセットが不正です" end
		rainbowSet[model] = nil
		paint(model, parts, pr.Color)
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[pr.Material]
			p.Reflectance = pr.Reflectance
			p.Transparency = pr.Transparency
		end
		s.glowColor = nil
		setGlow(model, pr.Color, pr.Glow, pr.Range)
		return "プリセット「" .. value .. "」を適用しました"
	elseif kind == "Reflectance" then
		if not isNum(value) then return "値が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Reflectance = math.clamp(value, 0, 1) end
		return "反射を変えました"
	elseif kind == "Transparency" then
		if not isNum(value) then return "値が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Transparency = math.clamp(value, 0, 0.9) end
		return "透明度を変えました"
	elseif kind == "Variance" then
		if not isNum(value) then return "値が不正です" end
		s.variance = math.clamp(value, 0, 1)
		paint(model, parts, s.base or parts[1].Color)
		return "色ムラを変えました"
	elseif kind == "Texture" then
		setTexture(parts, value == true)
		return value == true and "テクスチャON" or "テクスチャOFF"
	elseif kind == "Glow" then
		if not isNum(value) then return "値が不正です" end
		setGlow(model, s.glowColor or s.base or parts[1].Color, math.clamp(value, 0, 5), nil)
		return "発光を変えました"
	elseif kind == "GlowRange" then
		if not isNum(value) then return "値が不正です" end
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		setGlow(model, s.glowColor or s.base or parts[1].Color, l and l.Brightness or 1, math.clamp(value, 4, 30))
		return "発光の範囲を変えました"
	elseif kind == "GlowHue" then
		if not isNum(value) then return "値が不正です" end
		s.glowColor = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then l.Color = s.glowColor end
		return "発光の色を変えました"
	elseif kind == "Rainbow" then
		rainbowSet[model] = (value == true) or nil
		rainbowParts[model] = nil
		return value == true and "レインボーON" or "レインボーOFF"
	elseif kind == "RainbowSpeed" then
		if not isNum(value) then return "値が不正です" end
		s.rbSpeed = math.clamp(value, 0.02, 1)
		return "レインボーの速さを変えました"
	elseif kind == "RainbowSat" then
		if not isNum(value) then return "値が不正です" end
		s.rbSat = math.clamp(value, 0, 1)
		return "レインボーの鮮やかさを変えました"
	elseif kind == "Sparkle" then
		setSparkle(model, value == true)
		return value == true and "キラキラON" or "キラキラOFF"
	elseif kind == "SparkleRate" then
		if not isNum(value) then return "値が不正です" end
		setSparkle(model, true, math.clamp(value, 1, 120), nil)
		return "キラキラの量を変えました"
	elseif kind == "SparkleSize" then
		if not isNum(value) then return "値が不正です" end
		setSparkle(model, true, nil, math.clamp(value, 0.05, 2))
		return "キラキラの大きさを変えました"
	elseif kind == "Outline" then
		setOutline(model, value == true)
		return value == true and "縁取りON" or "縁取りOFF"
	elseif kind == "OutlineHue" then
		if not isNum(value) then return "値が不正です" end
		setOutline(model, true, Color3.fromHSV(math.clamp(value, 0, 1), 0.75, 1))
		return "縁取りの色を変えました"
	elseif kind == "Reset" then
		rainbowSet[model] = nil
		stateOf[model] = nil
		setGlow(model, Color3.new(1, 1, 1), 0, nil)
		setSparkle(model, false)
		setOutline(model, false)
		setTexture(parts, true)
		for _, p in ipairs(parts) do
			local o = orig[p]
			if o then
				p.Color, p.Material, p.Reflectance, p.Transparency = o[1], o[2], o[3], o[4]
			end
		end
		return "元に戻しました"
	end
	return "不明な操作です"
end

-- レインボーは毎フレーム更新 (Heartbeat) で滑らかに。パーツ一覧はキャッシュして毎回は数え直さない。
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
	if next(rainbowSet) == nil then return end
	local now = os.clock()
	for m in pairs(rainbowSet) do
		if m.Parent then
			local s = st(m)
			local col = Color3.fromHSV((now * (s.rbSpeed or 0.15)) % 1, s.rbSat or 0.85, 1)
			local parts = rainbowParts[m]
			if not parts then
				parts = partsOf(m)
				rainbowParts[m] = parts
			end
			for _, p in ipairs(parts) do
				if p.Parent then p.Color = col end
			end
			local h = glowHost(m)
			local l = h and h:FindFirstChild("SkinGlow")
			if l then l.Color = col end
		else
			rainbowSet[m] = nil
			rainbowParts[m] = nil
		end
	end
end)
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

	M.ORDER = { "shadow", "light", "fx", "decal", "post", "sky", "terrain", "material" }
	M.LABEL = {
		shadow = "影を消す", light = "ライトを切る", fx = "粒エフェクト停止", decal = "デカール消し",
		post = "ぼかし系を切る", sky = "雲・大気を消す", terrain = "水・草を軽く", material = "素材を単純化",
	}
	M.onStatus = nil   -- function(text, 0~1) 進行状況をUIに出すための窓口

	local FX_CLASS = { ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true, Trail = true, Beam = true }
	local POST_CLASS = { BlurEffect = true, DepthOfFieldEffect = true, SunRaysEffect = true }   -- ブルームは板のネオンのために残す

	-- 元の値の保管庫 (消えた物はGCされるように弱参照)
	local function weak() return setmetatable({}, { __mode = "k" }) end
	local store = { shadow = weak(), light = weak(), fx = weak(), decal = weak(), post = weak(), mat = weak(), refl = weak() }
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
		if n == FOLDER or n == "PalletLightBrown" or n:find("_SpawnedInToys$") then return true end
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
		end,
	}

	ITEMS.terrain = {
		apply = function()
			local T = workspace.Terrain
			if saves.terrain == nil then
				local okD, dec = pcall(function() return T.Decoration end)
				saves.terrain = { T.WaterWaveSize, T.WaterWaveSpeed, T.WaterReflectance, okD and dec or nil }
			end
			setp(T, "WaterWaveSize", 0)
			setp(T, "WaterWaveSpeed", 0)
			setp(T, "WaterReflectance", 0)
			setp(T, "Decoration", false)
		end,
		revert = function()
			local s = saves.terrain
			if not s then return end
			local T = workspace.Terrain
			setp(T, "WaterWaveSize", s[1])
			setp(T, "WaterWaveSpeed", s[2])
			setp(T, "WaterReflectance", s[3])
			if s[4] ~= nil then setp(T, "Decoration", s[4]) end
			saves.terrain = nil
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
			process(k)
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
		if not running and #order > 0 then task.spawn(worker) end
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
local topbar = mk("Frame", { Name = "TopBar", Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(W - 24, 50) }, win)
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
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)

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
local dirty = {}
local resetters = {}   -- 板ごとに、UIを初期状態へ戻す関数のリスト
local function onResettable(fn) resetters[#resetters + 1] = fn end
local recipe = setmetatable({}, { __mode = "k" })   -- 板ごとの操作ログ
local permanentOps = nil                             -- 永久保存した設定 (これから出す板に自動で反映)
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

-- 自分の板かどうか。本体(SpawnToyServer)は板に OwnerUserId という Attribute を付けて持ち主を記録しているので、
-- まずそれを見る。古い板など Attribute が無い場合だけ、PlayerValue (あれば) で判定し、何も無ければ自分の板として扱う。
local function isMine(m)
	local owner = m:GetAttribute("OwnerUserId")
	if owner ~= nil then return owner == lp.UserId end
	local pv = m:FindFirstChild("PlayerValue")
	if not pv or not pv:IsA("ValueBase") then return true end
	local v = pv.Value
	if typeof(v) == "Instance" then return v == lp end
	if typeof(v) == "string" then return v == lp.Name or v == lp.DisplayName or v == tostring(lp.UserId) end
	if typeof(v) == "number" then return v == lp.UserId end
	return true
end

-- サーバー側が自動生成する「<自分のUserId>_SpawnedInToys」フォルダ(Workspace直下)。
-- 中身は本物の板への参照(ObjectValue)で、自分の板だけが入っているので、他人の板は原理的に検出されない。
local function myFolderName()
	return tostring(lp.UserId) .. "_SpawnedInToys"
end

local function myPallets()
	local list = {}
	local seenModel = {}
	local pf = workspace:FindFirstChild(myFolderName())
	if pf then
		for _, ref in ipairs(pf:GetChildren()) do
			if ref:IsA("ObjectValue") then
				local m = ref.Value
				if m and m.Parent and m:IsA("Model") and m.Name == "PalletLightBrown" and not seenModel[m] then
					seenModel[m] = true
					list[#list + 1] = m
				end
			end
		end
	end
	-- 保険: 専用フォルダがまだ反映されていない瞬間用に、共有フォルダを OwnerUserId で直接確認
	if #list == 0 then
		local f = workspace:FindFirstChild(FOLDER)
		if f then
			for _, m in ipairs(f:GetChildren()) do
				if m.Name == "PalletLightBrown" and m:IsA("Model") and isMine(m) and not seenModel[m] then
					seenModel[m] = true
					list[#list + 1] = m
				end
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
end

-- 板に反映 (サーバーの受け口があればサーバーへ、無い/失敗ならこの画面に直接)
local lastSend = 0
local function doApply(model, kind, value, quiet)
	local remote = RS:FindFirstChild("PalletStudioApply_v2")
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
		recipe[model] = nil
		if permanentOps then
			permanentOps = nil
			updatePerm()
		end
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
	record(model, kind, value)
	selVisuals()
	doApply(model, kind, value, quiet)
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

local pages = {}
for i = 1, 9 do pages[i] = newPage() end
-- 7〜9 は「その他」タブの中。上に切り替えバーを置くので、その分だけ下げる
for k = 7, 9 do
	pages[k].Position = UDim2.fromOffset(0, 46)
	pages[k].Size = UDim2.new(1, 0, 1, -46)
end

-- 1: 色
do
	local e = Lib.element(pages[1])
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
	}
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
		b.MouseButton1Click:Connect(function() send("Look", m[1]) end)
	end
	e:title("素材のあとに色を変えても大丈夫")
end

-- 3: プリセット
do
	local e = Lib.element(pages[3])
	e:title("プリセット")
	local presets = {
		{"NeonBlue", "ネオンブルー", Color3.fromRGB(56, 189, 248)}, {"NeonPink", "ネオンピンク", Color3.fromRGB(255, 70, 190)}, {"NeonGreen", "ネオングリーン", Color3.fromRGB(60, 255, 130)},
		{"Sunset", "サンセット", Color3.fromRGB(255, 120, 40)}, {"Gold", "ゴールド", Color3.fromRGB(255, 200, 60)}, {"Silver", "シルバー", Color3.fromRGB(200, 205, 215)},
		{"Ice", "アイス", Color3.fromRGB(175, 225, 255)}, {"Glass", "ガラス", Color3.fromRGB(200, 235, 255)}, {"Marble", "大理石", Color3.fromRGB(235, 235, 240)},
		{"Lava", "ラバ", Color3.fromRGB(255, 90, 20)}, {"Obsidian", "黒曜石", Color3.fromRGB(60, 50, 90)}, {"Candy", "キャンディ", Color3.fromRGB(255, 150, 200)},
		{"Forest", "森", Color3.fromRGB(50, 150, 70)}, {"Ghost", "ゴースト", Color3.fromRGB(230, 240, 255)}, {"Sakura", "さくら", Color3.fromRGB(255, 183, 205)},
		{"Toxic", "トキシック", Color3.fromRGB(170, 255, 0)}, {"Royal", "ロイヤル", Color3.fromRGB(88, 60, 200)}, {"RoseGold", "ローズゴールド", Color3.fromRGB(236, 160, 150)},
	}
	local presetCols = isMobile and 2 or 3
	local presetCW = isMobile and 124 or 154
	local row = e:row(gridHeight(#presets, presetCols, 84, 8))
	grid(row, presetCW, 84, 8, 8)
	for i, p in ipairs(presets) do
		local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i }, row)
		Lib.glass(b, 0.84, 14)
		local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 44) }, b)
		corner(sw, 10)
		mk("UIGradient", { Rotation = 25, Color = ColorSequence.new(p[3], Color3.new(p[3].R * 0.45, p[3].G * 0.45, p[3].B * 0.45)) }, sw)
		text(b, p[2], isMobile and 12 or 14, UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 24), Enum.TextXAlignment.Center)
		Lib.juice(b)
		b.MouseButton1Click:Connect(function() send("Preset", p[1]) end)
	end
end

-- 4: 質感
do
	local e = Lib.element(pages[4])
	e:title("質感")
	local refS = e:slider("反射", 0, 1, function(v, r) sendThrottled("Reflectance", v, r) end, 0)
	local traS = e:slider("透明度", 0, 0.9, function(v, r) sendThrottled("Transparency", v, r) end, 0)
	local varS = e:slider("色ムラ", 0, 1, function(v, r) sendThrottled("Variance", v, r) end, 0, Color3.fromRGB(99, 102, 241), PINK)
	e:title("テクスチャ")
	local texT = e:toggle("元の木目テクスチャ", function(s) send("Texture", s) end, true)
	onResettable(function()
		refS:set(0) traS:set(0) varS:set(0) texT:set(true)
	end)
end

-- 5: 光
do
	local e = Lib.element(pages[5])
	e:title("発光")
	local glowS = e:slider("発光の強さ", 0, 5, function(v, r) sendThrottled("Glow", v, r) end, 0, Color3.fromRGB(120, 80, 20), Color3.fromRGB(255, 240, 120))
	local rangeS = e:slider("発光の範囲", 4, 30, function(v, r) sendThrottled("GlowRange", v, r) end, 8)
	local glowHueS = e:slider("発光の色", 0, 1, function(v, r) sendThrottled("GlowHue", v, r) end, 0.58, nil, nil, hueSeq())
	e:title("縁取り")
	local ot = e:toggle("縁取り", function(s) send("Outline", s) end, false)
	local outHueS = e:slider("縁取りの色", 0, 1, function(v, r) ot:set(true) sendThrottled("OutlineHue", v, r) end, 0.55, nil, nil, hueSeq())
	onResettable(function()
		glowS:set(0) rangeS:set(8) glowHueS:set(0.58) ot:set(false) outHueS:set(0.55)
	end)
end

-- 6: 効果
do
	local e = Lib.element(pages[6])
	e:title("レインボー")
	local rt = e:toggle("レインボー", function(s) send("Rainbow", s) end, false)
	local rbSpeedS = e:slider("速さ", 0.02, 1, function(v, r) rt:set(true) sendThrottled("RainbowSpeed", v, r) end, 0.15)
	local rbSatS = e:slider("鮮やかさ", 0, 1, function(v, r) sendThrottled("RainbowSat", v, r) end, 0.85, WHITE, PINK)
	e:title("キラキラ")
	local st_ = e:toggle("キラキラ", function(s) send("Sparkle", s) end, false)
	local spRateS = e:slider("量", 1, 120, function(v, r) st_:set(true) sendThrottled("SparkleRate", v, r) end, 25, Color3.fromRGB(99, 102, 241), CYAN)
	local spSizeS = e:slider("大きさ", 0.05, 2, function(v, r) st_:set(true) sendThrottled("SparkleSize", v, r) end, 0.35, Color3.fromRGB(99, 102, 241), CYAN)
	onResettable(function()
		rt:set(false) rbSpeedS:set(0.15) rbSatS:set(0.85)
		st_:set(false) spRateS:set(25) spSizeS:set(0.35)
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
	local tip = e:row(isMobile and 84 or 56)
	local tipLbl = text(tip, "ぼかし系はブルーム(光のにじみ)を残すので、板のネオンの光り方は変わりません。素材の単純化は見た目がだいぶ変わります。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
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
local tabs = { {"🎨", "色"}, {"🧱", "素材"}, {"✨", "プリセット"}, {"💎", "質感"}, {"💡", "光"}, {"🌈", "効果"}, {"⚙️", "その他"} }
local tabBtns = {}

-- 「その他」タブの中: 上の切り替えバーで 視野 / 軽量化 / UI設定 を行き来する
local navBar = mk("Frame", { Name = "SubNav", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -22, 0, 32), Visible = false }, content)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, navBar)
local subBtns = {}
local curTab, curSub = 1, 1
local function showSub(k)
	curSub = k
	for j = 1, 3 do
		pages[6 + j].Visible = (curTab == 7 and j == k)
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

local function showTab(i)
	curTab = i
	for j = 1, 6 do pages[j].Visible = (j == i) end
	navBar.Visible = (i == 7)
	showSub(curSub)
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
	local b = mk("TextButton", { Name = "Tab" .. i, AutoButtonColor = false, Text = tabText, TextSize = isMobile and 22 or 17, FontFace = FONT, TextColor3 = WHITE, TextXAlignment = isMobile and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left, LayoutOrder = i, Size = UDim2.new(1, 0, 0, isMobile and 48 or 40) }, side)
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
Lib.drag(topbar, win, nil, winScale)
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
	local model = selected and seenMap[selected]
	local r = model and recipe[model]
	if not r or #r == 0 then
		Lib.notif(gui, "先に色や素材を変えてから押してね", 1.8)
		return
	end
	local copy = {}
	for k, op in ipairs(r) do copy[k] = { op[1], op[2] } end
	permanentOps = copy
	updatePerm()
	Lib.notif(gui, "永久保存しました 📌 これから出す板に自動で反映します", 2.2)
end)

ringGrad.Rotation = 0
spinTw[1] = TweenService:Create(ringGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
spinTw[2] = TweenService:Create(titleGrad, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
for _, t in ipairs(spinTw) do t:Play() end

workspace.DescendantAdded:Connect(function(m)
	if m.Name ~= "PalletLightBrown" or not m:IsA("Model") then return end
	if m.Parent ~= workspace:FindFirstChild(FOLDER) then return end
	-- PlayerValue がまだ入っていない瞬間がありうるので、少し待って2回更新し直す
	if isOpen then
		task.delay(0.5, refresh)
		task.delay(1.5, refresh)
	end
	if permanentOps then
		task.spawn(function()
			local t0 = os.clock()
			repeat task.wait(0.1) until (m:FindFirstChild("PlayerValue") and m:FindFirstChild("Part")) or os.clock() - t0 > 3 or not m.Parent
			if not m.Parent or not isMine(m) then return end
			local copy = {}
			for k, op in ipairs(permanentOps) do
				copy[k] = { op[1], op[2] }
				doApply(m, op[1], op[2], true)
				task.wait()
			end
			recipe[m] = copy
		end)
	end
end)
workspace.DescendantRemoving:Connect(function(m)
	if isOpen and m.Name == "PalletLightBrown" then task.delay(0.1, refresh) end
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
