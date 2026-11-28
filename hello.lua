-- PalletStudio (LocalScript): StarterPlayer > StarterPlayerScripts に入れる (これ1個だけで動く)
-- 検出: Workspace の「<自分の@ID(ユーザー名)>SpawnedInToys」フォルダの直下にある PalletLightBrown だけを「板1, 板2…」として出す。
--       他のフォルダ・他プレイヤーのフォルダの板は見ない。フォルダの自動作成はしない (サーバー側も同じ条件の板しか受け付けない)。
-- 起動時に必ず、サーバー用コードを CodeLoader (ServerScriptService) へ送る。サーバー側が無ければ、この画面だけに直接反映する。
-- タブ: ホーム / 色(単色・2〜3色グラデ・流れるグラデ) / 素材(分類・色と光はそのまま・ツートン) / プリセット(見た目一式・おまかせ・他の板へコピー) / 質感(質感セット12種・ツヤ8種・映り込む空6種・光が走る・角の輝き・経年劣化5種) / 光(光のレシピ12種・色の動き・明滅10種・深さ/波・夜だけ・スポット幅・オーラ) / 効果(レインボー・炎・煙・雪・桜・ほたる・あわ・火の粉) / その他(視野・軽量化・UI設定)
-- 反射・ツヤは、素材やテクスチャを変えずに、光の帯と空の映り込みを重ねて出す。明滅・色の動き・光の走り・レインボー・グラデの流れは、この画面で毎フレームなめらかに動く(この画面を入れていない人には、止まった見た目で出る)。
-- 📌 永久保存: 押すと保存、もう一度押すと解除。保存中は、これから出す板に自動でまとめて反映する。
--       板が出た同じ瞬間に、色・素材・反射などの軽い設定が付く。グラデ/ツヤの重ね貼りは、数を絞って1フレームに少しずつ作る(数フレーム=約0.05秒で出来あがる)ので、出現がカクつかない。
--       ※サーバー側のコードは1回だけ読み込まれるので、更新した時は Studio の Play をやり直して(サーバーを作り直して)ください。
-- 板を切り替えた時は、スライダー/トグルの表示だけを初期位置へ戻す(板そのものは「元に戻す」ボタンの時だけ戻る)。
-- ホーム: 「ヘルプ」= 別の窓が開いて、各ページ→各機能の説明を読める(閉じると元の画面にもどる) / 「プレビュー」= 左に小さな窓が開いて、ふつうの見た目の板の3Dモデルが回る。
--   本体で色や素材を変えると、プレビューの板だけが変わる(本物の板・サーバーには送らない)。ドラッグで360度まわせる(さわっている間と10秒は自動回転を止める)。
--   プレビューを閉じると、本体のスライダー/ボタンは初期の位置にもどる。「💾 メイン保存」で、左の「その他」の下に「プリセットN」が出て、押すと一瞬でその見た目になる。
-- ☁ GitHub保存: 設定だけ(永久保存の板の見た目・プリセット・UI設定・軽量化の選択)を、プレイヤーごとに自分の GitHub へ自動で保存して、次に起動した時にそのまま反映する。
--   保存先は「<フォルダ>/<プレイヤーのID>.json」(1人1ファイル・読める文字のJSON)。画面側(LocalScript)は Roblox の決まりで通信できないので、通信は、このファイルに入っているサーバー側のコードが受け持つ(新しいスクリプトは増えない)。
--   トークンはサーバー側だけが読む(画面側へは来ない)。下の GITHUB の repo が空の間は、何もしない。使い方は下の「GitHub保存の設定」を見てね。
-- 起動時、右下に make by aino の演出が出て、終わると開閉ボタンが現れる。


-- ===== GitHub保存の設定 (ここだけ書きかえる) =====
--  ① GitHub で、保存用のリポジトリを作る (Private がおすすめ。「Add a README file」にチェックを入れて作ると簡単)
--  ② GitHub の Settings > Developer settings > Personal access tokens > Fine-grained tokens で、そのリポジトリだけを選び、
--     Repository permissions の「Contents」を「Read and write」にしたトークンを作る (他の権限はいらない)
--  ③ Studio の Home > Game Settings > Security > 「Allow HTTP Requests」をON
--  ④ ServerStorage に StringValue を1個作り、名前を PalletStudioGitHubToken、Value に ②のトークンを貼る (Studioで試す時)
--     ※本番のサーバーでは、Creator Hub の Secrets に「PalletStudioGitHub」という名前でトークンを入れると、そちらを先に使う
--  ⑤ 下の repo を「ユーザー名/リポジトリ名」にする → Studio の Play をやり直す
--  ※トークンは人に見せない・このファイルには書かない。CodeLoader は「最初に送ってきたコード」を動かす作りなので、公開ゲームではトークンを使わない方が安全。
local GITHUB = {
	repo = "",   -- 例: "aino/pallet-saves"  (空のままなら、この機能は動かない)
	branch = "", -- 空なら、リポジトリの標準のブランチ
	folder = "PalletStudio", -- この中に「プレイヤーのID.json」を作る
}

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
local RunService = game:GetService("RunService")
local ANIM_TAG = "PalletStudioAnim"   -- 動きのある板に付ける目印 (この画面のアニメ担当が見つける)

local orig = setmetatable({}, { __mode = "k" })
local stateOf = setmetatable({}, { __mode = "k" })

-- ===== 板の「元の姿」の見本 =====
-- 板を最初にさわる直前の姿を、1つだけ控えておく (見た目に関係ない物は外す)。プレビューが「ふつうの板」を見せるのに使う。
-- サーバーで動いている時は ReplicatedStorage に置く (各自の画面から読めるように)。この画面だけで動いている時は、この中に持つ。
local TPL_NAME = "PalletStudioTemplate"
local tplRef = nil   -- nil = まだ / false = 試したが出来なかった / 板 = 控えた見本
local function stripClone(model)
	local ok, c = pcall(function() return model:Clone() end)
	if not ok or not c then return nil end
	local drop = {}
	for _, d in ipairs(c:GetDescendants()) do
		if not (d:IsA("BasePart") or d:IsA("DataModelMesh") or d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Model") or d:IsA("Folder")) then
			drop[#drop + 1] = d   -- スクリプト・音・ライト・粒・拘束・GUI など、見た目に関係ない物
		end
	end
	for _, d in ipairs(drop) do pcall(function() d:Destroy() end) end
	return c
end
local function captureTemplate(model)
	if tplRef ~= nil then return end
	tplRef = false   -- 失敗しても、試すのは1回だけ
	pcall(function()
		if model:GetAttribute("PS_Preview") == true then return end   -- プレビュー用の複製は見本にしない
		local RS = game:GetService("ReplicatedStorage")
		if RS:FindFirstChild(TPL_NAME) then return end
		local c = stripClone(model)
		if not c then return end
		c.Name = TPL_NAME
		if RunService:IsServer() then c.Parent = RS end
		tplRef = c
	end)
end

local function st(model)
	local s = stateOf[model]
	if not s then
		s = {}
		stateOf[model] = s
		captureTemplate(model)   -- まだ何も変えていない今のうちに、元の姿を控える
	end
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

local function lerpC(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

-- 経年劣化の種類 (1 = 汚れ: 下の式でくすませる)。{ 近づける色, 強さ, 高さの効き(+1=上ほど / -1=下ほど / 0=一様), 暗くする量 }
local WEATHER_KINDS = {
	false,
	{ Color3.fromRGB(160, 74, 30), 0.85, 0, 0.1 },     -- 2 さび
	{ Color3.fromRGB(66, 112, 40), 0.8, -1, 0.08 },    -- 3 こけ (下ほど濃い)
	{ Color3.fromRGB(246, 250, 255), 0.95, 1, 0 },     -- 4 雪 (上ほど濃い)
	{ Color3.fromRGB(24, 18, 14), 0.9, 0, 0 },         -- 5 焦げ
}
local WEATHER_N = #WEATHER_KINDS

-- 1枚ごとの色。色ムラ(variance)と経年劣化(weather)をここでまとめて掛ける
local function tint(s, i, c)
	local amt, wt = s.variance or 0, s.weather or 0
	if amt <= 0 and wt <= 0 then return c end
	local h, sa, v = c:ToHSV()
	if amt > 0 then
		v = v + (((i * 37) % 17) / 16 - 0.5) * amt * 0.6
	end
	local wk = wt > 0 and WEATHER_KINDS[s.wkind or 1] or false
	local d = 0.35 + 0.65 * (((i * 53 + 7) % 13) / 12)   -- 板ごとに汚れ方を変える
	if wt > 0 and not wk then
		v = v * (1 - 0.5 * wt * d)
		sa = sa * (1 - 0.4 * wt * d)
	end
	local out = Color3.fromHSV(h, math.clamp(sa, 0, 1), math.clamp(v, 0, 1))
	if wk then   -- さび / こけ / 雪 / 焦げ: 色を目的の色へ近づける (板ごとにムラ。高さに応じて濃さも変わる)
		local hw = s.wh and s.wh[i] or 0.5
		local hk = (wk[3] == 0) and 1 or (wk[3] > 0 and (0.2 + 0.8 * hw) or (0.2 + 0.8 * (1 - hw)))
		out = lerpC(out, wk[1], math.clamp(wt * d * wk[2] * hk, 0, 1))
		if wk[4] > 0 then
			local k = 1 - wk[4] * wt * d
			out = Color3.new(out.R * k, out.G * k, out.B * k)
		end
	end
	return out
end

-- 板の一部だけ別の素材にする「ツートン」: s.two = { set = {パーツ = true}, prev = {パーツ = 元の素材}, col = 色 or nil }
local function paint(model, parts, c)
	local s = st(model)
	s.base = c
	local two = s.two
	for i, p in ipairs(parts) do
		remember(p)
		local cc = c
		if two and two.col and two.set[p] then cc = two.col end
		setCol(p, tint(s, i, cc))
	end
end

-- 動き(レインボー / 明滅 / グラデーションの流れ)の設定を、板の「属性」に書く。
-- 動かすのは各自の画面側 (なめらかに動くように)。サーバーは設定を書くだけで、毎フレーム更新はしない。
local ANIM_ATTRS = { "PS_Rb", "PS_RbSpeed", "PS_RbSat", "PS_RbSpread", "PS_Pulse", "PS_PulseStyle", "PS_PulseBody", "PS_Flow",
	"PS_GA", "PS_GB", "PS_GC", "PS_GRev", "PS_GMid", "PS_GStripes", "PS_GlowB", "PS_GlowCol",
	"PS_PulseDepth", "PS_PulseWave", "PS_GMode", "PS_GlowCol2", "PS_GSpeed", "PS_Night", "PS_Sheen", "PS_FId" }
local function syncAnim(model)
	local s = st(model)
	local g = s.grad
	local flow = g and (g.flow or 0) or 0
	local gm = s.gmode or "Solid"
	-- 動かすものが1つでもあれば、動かす担当(各自の画面)に見つけてもらう目印を付ける
	local on = (s.rainbow == true) or (s.pulse or 0) > 0 or flow > 0 or (s.sheen or 0) > 0 or s.night == true
		or (gm ~= "Solid" and (s.glowB or 0) > 0)
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
	model:SetAttribute("PS_FId", (g and flow > 0) and g.id or nil)   -- 流れの色の「識別番号」(変わったら、各自の画面が色の表を作り直す)
	model:SetAttribute("PS_PulseDepth", s.pdepth or 1)
	model:SetAttribute("PS_PulseWave", s.pwave or 0)
	model:SetAttribute("PS_GMode", gm)
	model:SetAttribute("PS_GlowCol2", s.gcol2)
	model:SetAttribute("PS_GSpeed", s.gspeed or 0.3)
	model:SetAttribute("PS_Night", s.night == true)
	model:SetAttribute("PS_Sheen", s.sheen or 0)
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
		syncAnim(model)   -- 光の色の動き / 夜だけ光る は、光がある間だけ動かす
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
		l.Angle = s.spot or 120
	end
	l.Color = color
	l.Brightness = brightness
	l.Range = range or l.Range
	model:SetAttribute("PS_GlowB", brightness)
	model:SetAttribute("PS_GlowCol", color)
	syncAnim(model)
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
	local f = st(model).ofill or 0   -- 縁取りの内側を光らせる量 (オーラ)
	o.FillColor = o.OutlineColor
	o.FillTransparency = f > 0 and (1 - 0.7 * f) or 1
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

-- ツートンを解除する: 別の素材にしていた部分を元の素材に戻す。recolor=true なら、色も板の基準色へ戻す
local function twoOff(model, parts, recolor)
	local s = st(model)
	local two = s.two
	if not two then return end
	s.two = nil
	local back = {}
	for i, p in ipairs(parts) do
		if two.set[p] then
			local pm = two.prev[p]
			if pm then p.Material = pm end
			back[#back + 1] = p
			if recolor then
				local c = s.base or (orig[p] and orig[p][1])
				if c then setCol(p, tint(s, i, c)) end
			end
		end
	end
	if s.texUser ~= false then setTexture(back, true) end   -- 板全体の木目を外していなければ、この部分の木目も戻す
end

---------------------------------------------------------------------
-- 反射(ツヤ) / グラデーション / ネオン / 明滅 / 効果
---------------------------------------------------------------------
local SK = {}
SK.stripClone = stripClone   -- (a2_base) 見た目に関係ない物を外した複製
function SK.template()       -- 控えておいた「元の姿」の板 (無ければ nil)
	if tplRef then return tplRef end
	local ok, t = pcall(function() return game:GetService("ReplicatedStorage"):FindFirstChild(TPL_NAME) end)
	return ok and t or nil
end
-- 控えがまだ無い時に、まだ何もさわっていない板から、今のうちに控える (さわったことのある板からは控えない)
function SK.capture(model)
	if SK.template() then return SK.template() end
	if typeof(model) == "Instance" and model.Parent and stateOf[model] == nil then captureTemplate(model) end
	return SK.template()
end
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

	-- ===== 流れるグラデーション用の「ぐるっと回るパレット」 =====
	-- A→C→B→A… とつなぎ目なく回る (Cが無ければ A→B→A)。区間ごとにゆるやかに混ぜるので、色の変わり目も角が立たない。
	-- x は 0〜1 で1周。rev なら逆まわり。
	local function ease(x) return x * x * (3 - 2 * x) end
	local function cycAt(cfg, x)
		x = x % 1
		if cfg.rev then x = 1 - x end
		local a, b, c = cfg.a, cfg.b, cfg.c
		if c then
			local pc, pb = cfg.mid * (2 / 3), 2 / 3   -- C の位置は「中間の位置」で動く
			if x < pc then return mix(a, c, ease(x / pc)) end
			if x < pb then return mix(c, b, ease((x - pc) / (pb - pc))) end
			return mix(b, a, ease((x - pb) / (1 - pb)))
		end
		local pb = cfg.mid
		if x < pb then return mix(a, b, ease(x / pb)) end
		return mix(b, a, ease((x - pb) / (1 - pb)))
	end
	SK.cycAt = cycAt
	-- 1周ぶんを先に256個の色にしておく (毎フレームの色は、ここから選んで混ぜるだけ。重い計算をしない)
	local LUTN = 256
	function SK.cycLUT(cfg)
		local lut = {}
		for i = 0, LUTN - 1 do lut[i + 1] = cycAt(cfg, i / LUTN) end
		lut[LUTN + 1] = lut[1]
		lut[LUTN + 2] = lut[1]   -- (x が -1e-17 のような時、x % 1 が 1.0 ちょうどになることがあるので、もう1つ余分に)
		-- 色の変わり目 (A・C・B がちょうど出る位置とその色)。面の色の並びにここへ必ず点を打つ (打たないと、流れるたびに頂点の色が丸まって、鮮やかさが脈打つ)
		local kn
		if cfg.c then
			kn = { { 0, cfg.a }, { cfg.mid * (2 / 3), cfg.c }, { 2 / 3, cfg.b } }
		else
			kn = { { 0, cfg.a }, { cfg.mid, cfg.b } }
		end
		if cfg.rev then
			for _, k in ipairs(kn) do k[1] = (1 - k[1]) % 1 end
		end
		lut.knots = kn
		return lut
	end
	-- 位置 x (0〜1で1周) の色。となりの2色をなめらかに混ぜるので、遅い流れでも階段にならない
	function SK.lutAt(lut, x)
		local f = (x % 1) * LUTN
		if f ~= f then f = 0 end
		local i = math.floor(f)
		local k = f - i
		local c1, c2 = lut[i + 1], lut[i + 2]
		return Color3.new(c1.R + (c2.R - c1.R) * k, c1.G + (c2.G - c1.G) * k, c1.B + (c2.B - c1.B) * k)
	end
	-- 1つの面に等間隔で打つ点の数 (面が周期の何割を占めるかで決める。多いほど滑らか。最大14。このほか、色の変わり目(A・C・Bの位置)にも点を足す)
	function SK.flowKeys(ts)
		return math.clamp(math.ceil(math.abs(ts) * 12) + 4, 5, 14)
	end
	-- 向き(角度, 度)から、板の座標系での単位ベクトル。上から見て斜めも含めて、どの向きにも流せる
	function SK.flowVec(ang)
		local r = math.rad(ang or 0)
		return Vector3.new(math.cos(r), 0, math.sin(r))
	end
	local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

	-- 流れの色。stripes があれば くっきり帯 (境目で急に切り替わる)、なければ ぐるっと回るなめらかなパレット (lut)
	function SK.flowCol(cfg, lut, x)
		if cfg.stripes > 1 then
			x = x % 1
			if cfg.rev then x = 1 - x end
			local k = math.min(math.floor(x * cfg.stripes), cfg.stripes - 1)
			if cfg.c then
				local m = k % 3
				return (m == 0 and cfg.a) or (m == 1 and cfg.c) or cfg.b
			end
			return (k % 2 == 0) and cfg.a or cfg.b
		end
		if lut then return SK.lutAt(lut, x) end
		return cycAt(cfg, x)
	end
	-- 1つの面の色の並び (ColorSequence)。面の中の位置 u(0〜1) は、板全体の位置 tc + (u-0.5)*ts にあたる。phase は、流れが進んだ量 (1 = 1周)
	-- なめらかな時は点を多めに打ち、くっきり帯の時は境目の前後に点を打つ。ts=0 (この向きでは色が変わらない面) は1色
	-- (毎フレーム・面ごとに呼ばれるので、作業用の表は使い回して、ごみを出さない)
	local KU, KC = {}, {}   -- 作業用: 点の位置 / 色 (cnt 個だけ有効)
	function SK.flowSeq(cfg, lut, tc, ts, phase)
		if ts < 0.004 then
			return ColorSequence.new(SK.flowCol(cfg, lut, tc - phase))
		end
		local keys = {}
		if cfg.stripes > 1 then
			local n = cfg.stripes
			local x0, x1 = tc - 0.5 * ts - phase, tc + 0.5 * ts - phase
			keys[1] = ColorSequenceKeypoint.new(0, SK.flowCol(cfg, lut, x0 + 1e-5))
			for m = math.ceil(x0 * n), math.floor(x1 * n) do
				local u = (m / n - x0) / ts
				if u > 0.004 and u < 0.996 and #keys < 18 then
					keys[#keys + 1] = ColorSequenceKeypoint.new(u - 0.002, SK.flowCol(cfg, lut, m / n - 1e-5))
					keys[#keys + 1] = ColorSequenceKeypoint.new(u + 0.002, SK.flowCol(cfg, lut, m / n + 1e-5))
				end
			end
			keys[#keys + 1] = ColorSequenceKeypoint.new(1, SK.flowCol(cfg, lut, x1 - 1e-5))
		else
			local n = SK.flowKeys(ts)
			local x0 = tc - 0.5 * ts - phase   -- 面の左(上)はしの、パレット上の位置
			local cnt = 0                      -- (色の変わり目は、色が分かっているのでそのまま入れる)
			local kn = lut and lut.knots
			if kn then
				for q = 1, #kn do
					local k = kn[q]
					for j = math.floor(x0 - k[1]), math.ceil(x0 + ts - k[1]) do
						local u = (k[1] + j - x0) / ts
						if u > 0.003 and u < 0.997 then
							cnt = cnt + 1
							KU[cnt], KC[cnt] = u, k[2]
						end
					end
				end
			end
			local nk = cnt
			KU[cnt + 1], KC[cnt + 1] = 0, SK.flowCol(cfg, lut, x0)
			KU[cnt + 2], KC[cnt + 2] = 1, SK.flowCol(cfg, lut, x0 + ts)
			cnt = cnt + 2
			for i = 1, n - 2 do
				local u = i / (n - 1)
				local near = false
				for q = 1, nk do
					if math.abs(KU[q] - u) < 0.012 then near = true break end
				end
				if not near then
					cnt = cnt + 1
					KU[cnt], KC[cnt] = u, SK.flowCol(cfg, lut, x0 + u * ts)
				end
			end
			-- 位置の小さい順に並べる (最大でも20個ほどで、ほぼ順番に並んでいるので、挿入ソートがいちばん軽い)
			for i = 2, cnt do
				local u, c = KU[i], KC[i]
				local j = i - 1
				while j >= 1 and KU[j] > u do
					KU[j + 1], KC[j + 1] = KU[j], KC[j]
					j = j - 1
				end
				KU[j + 1], KC[j + 1] = u, c
			end
			local last = -1
			for i = 1, cnt do
				if KU[i] > last + 1e-4 and #keys < 20 then
					keys[#keys + 1] = ColorSequenceKeypoint.new(KU[i], KC[i])
					last = KU[i]
				end
			end
			if keys[#keys].Time < 1 then keys[#keys] = ColorSequenceKeypoint.new(1, keys[#keys].Value) end
		end
		return ColorSequence.new(keys)
	end
	-- 「色を流す」を選んだ時に1回だけ決める向き (度)。7割は斜め寄り、3割は完全にランダム。途中で変わることはない
	local function pickFlowAngle()
		if math.random() < 0.7 then
			return (45 + 90 * math.random(0, 3) + math.random(-26, 26)) % 360
		end
		return math.random() * 360
	end
	SK.pickFlowAngle = pickFlowAngle
	-- 流れの進み具合 (1 = 1周)。サーバー時刻で決まるので、見ている人どうしでそろう
	function SK.flowPhase(speed)
		local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
		if not ok or type(t) ~= "number" then t = os.clock() end
		return (t * speed) % 1
	end

	-- 面ごとの GUI の向き (外から見て 右 / 上 が、パーツのどの向きか)
	local FACES = {
		{ "Front", Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Back", Vector3.new(1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Left", Vector3.new(0, 0, 1), Vector3.new(0, 1, 0) },
		{ "Right", Vector3.new(0, 0, -1), Vector3.new(0, 1, 0) },
		{ "Top", Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0) },
	}
	-- 作る順番: 上 → 前後 → 左右。上から見ることが多いので、見える所から先に出来上がる
	local FORDER = { FACES[5], FACES[1], FACES[2], FACES[3], FACES[4] }
	SK.FACES = FACES   -- (プレビューが、面の向きを同じ決まりで読むため)

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

	-- ----- 斜めの向き用 (axisInfo / faceWindow の「好きな向き」版) -----
	local function dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
	-- 板全体を向き D (板の座標系の単位ベクトル) に沿って 0〜1 に見たとき、各パーツが占める範囲 ta〜tb。lo/hi は板の端
	local function dirInfo(model, parts, D)
		local pv = model:GetPivot()
		local ex, lo, hi = {}, math.huge, -math.huge
		for i, p in ipairs(parts) do
			local rel = pv:ToObjectSpace(p.CFrame)
			local sz = p.Size
			local h = 0.5 * (math.abs(dot(D, rel.RightVector)) * sz.X + math.abs(dot(D, rel.UpVector)) * sz.Y + math.abs(dot(D, rel.LookVector)) * sz.Z)
			local c = dot(D, rel.Position)
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
		return ex, span, lo
	end
	-- 面 f (パーツ p) の上で、向き D の「位置」がどう変わるか。
	-- 戻り値: 角度(度。UIGradient.Rotation) / 面の真ん中の位置 tc / 面のはしからはしまでで変わる量 ts (どれも板全体=1 の単位)。向きが面と直角なら ts=0
	local function faceDir(e, f, p, D, span, lo, topFlip)
		local fr, fu = f[2], f[3]
		if f[1] == "Top" and topFlip then fr, fu = -fr, -fu end   -- 上面だけ向きが逆に見える時の保険 (axisInfo版と同じ)
		local z = p.Size
		local w = math.abs(fr.X) * z.X + math.abs(fr.Y) * z.Y + math.abs(fr.Z) * z.Z
		local h = math.abs(fu.X) * z.X + math.abs(fu.Y) * z.Y + math.abs(fu.Z) * z.Z
		local R = e.rel:VectorToWorldSpace(fr)
		local U = e.rel:VectorToWorldSpace(fu)
		local a, b = dot(D, R), dot(D, U)
		-- 面の外向きの向き = 右 × 上。面の中心は、パーツの中心から厚みの半分だけ外へ
		local n = Vector3.new(fr.Y * fu.Z - fr.Z * fu.Y, fr.Z * fu.X - fr.X * fu.Z, fr.X * fu.Y - fr.Y * fu.X)
		local half = 0.5 * (math.abs(n.X) * z.X + math.abs(n.Y) * z.Y + math.abs(n.Z) * z.Z)
		local tc = (e.c + dot(D, e.rel:VectorToWorldSpace(n)) * half - lo) / span
		local len = math.sqrt(a * a + b * b)
		if len < 0.03 then return 0, tc, 0 end
		local ang = math.deg(atan2(-b, a))   -- 画面は下が +y なので、上向き成分(b)は符号を反転
		local rad = math.rad(ang)
		local ext = w * math.abs(math.cos(rad)) + h * math.abs(math.sin(rad))
		return ang, tc, len * ext / span
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
		{ bands = { { 0.16, 0.05, 0.92 }, { 0.30, 0.025, 0.8 }, { 0.50, 0.07, 0.72 }, { 0.72, 0.03, 0.88 }, { 0.88, 0.05, 0.6 } }, sky = 0.5 },    -- 5 ウェット (濡れたように、小さな光がたくさん)
		{ bands = { { 0.20, 0.17, 0.5 }, { 0.54, 0.2, 0.46 }, { 0.86, 0.15, 0.5 } }, sky = 0.3, irid = 1.7 },                                      -- 6 パール (虹色のやさしい光沢)
		{ bands = { { 0.30, 0.012, 1 }, { 0.345, 0.05, 0.34 }, { 0.72, 0.015, 0.92 } }, sky = 0.12 },                                               -- 7 ニス (細くて鋭い光 + うすい映り込み)
		{ bands = { { 0.14, 0.07, 0.95 }, { 0.32, 0.045, 0.7 }, { 0.5, 0.09, 0.95 }, { 0.68, 0.045, 0.7 }, { 0.86, 0.07, 0.95 } }, sky = 0.22, irid = 0.9 }, -- 8 ダイヤ (虹色にきらめく面)
	}
	SK.GLOSS_STYLES = #GLOSS_STYLES
	-- 映り込む空 (環境)。sky=空の色 / hi=光の帯の色 / a=映り込みの濃さの倍率
	local SKIES = {
		{ sky = Color3.fromRGB(205, 228, 255), hi = Color3.new(1, 1, 1), a = 1 },                 -- 1 昼の空
		{ sky = Color3.fromRGB(255, 186, 140), hi = Color3.fromRGB(255, 236, 205), a = 1.15 },    -- 2 夕焼け
		{ sky = Color3.fromRGB(70, 92, 196), hi = Color3.fromRGB(205, 220, 255), a = 1.3 },       -- 3 夜
		{ sky = Color3.fromRGB(255, 96, 214), hi = Color3.fromRGB(255, 214, 250), a = 1.15 },     -- 4 ネオン
		{ sky = Color3.fromRGB(86, 236, 192), hi = Color3.fromRGB(218, 255, 240), a = 1.15 },     -- 5 オーロラ
		{ sky = Color3.new(1, 1, 1), hi = Color3.new(1, 1, 1), a = 0.7 },                         -- 6 スタジオ (白)
	}
	SK.SKIES = #SKIES
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

	-- 光の帯の「点を打つ位置」(0〜1)。帯のふちと真ん中に点を置く。20点を超えたら、間を1つおきに間引く
	local function bandKeys(style, t0, t1)
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
		while #keys > 20 do
			local nk = {}
			for i, u in ipairs(keys) do
				if i == 1 or i == #keys or i % 2 == 1 then nk[#nk + 1] = u end
			end
			keys = nk
		end
		return keys
	end

	-- ツヤの層は1枚だけ: 「空の映り込み」の上に「光の帯」を重ねた結果を、色と透明度の1本ずつにまとめる。
	-- (同じ見た目を、Frame と UIGradient 各1個で出せるので、2枚重ねるより軽い)
	-- env = 映り込む空 (SKIES の1つ)。style.irid があるスタイルは、帯が虹色にうつろう
	local function glossSeqs(style, k, t0, t1, top, env)
		local sky, hi = env.sky, env.hi
		local sa = math.min(0.95, style.sky * env.a * k * (top and 0.8 or 0.5))   -- 空の映り込みの濃さ (上の面は一様に少し濃く)
		local cks, nks = {}, {}
		for _, u in ipairs(bandKeys(style, t0, t1)) do
			local tt = t0 + (t1 - t0) * u
			local b = bandAlpha(style.bands, tt) * k   -- 光の帯の濃さ
			local a = 1 - (1 - b) * (1 - sa)           -- 2つを重ねた全体の濃さ
			local col = Color3.new(1, 1, 1)
			if a > 1e-4 then
				local wb, ws = b / a, (1 - b) * sa / a   -- 帯の色と空色の割合 (足すと1)
				local hc = hi
				if style.irid then
					local ic = Color3.fromHSV((tt * style.irid) % 1, 0.5, 1)
					hc = Color3.new((hi.R + ic.R) / 2, (hi.G + ic.G) / 2, (hi.B + ic.B) / 2)
				end
				col = Color3.new(wb * hc.R + ws * sky.R, wb * hc.G + ws * sky.G, wb * hc.B + ws * sky.B)
			end
			cks[#cks + 1] = ColorSequenceKeypoint.new(u, col)
			nks[#nks + 1] = NumberSequenceKeypoint.new(u, 1 - a)
		end
		return ColorSequence.new(cks), NumberSequence.new(nks)
	end

	-- 光が走る帯 (Sheen) と、角のハイライト (Edge) の見た目
	-- 帯は真ん中だけ不透明で、ふちはなめらかに消える。動かすのは各自の画面(アニメ担当)で、ここでは「画面の外」に置いておく
	local SHEEN_TILT = 24
	local SHEEN_HIDE = -1.3
	local function sheenSeqs(id)
		local nks = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.33, 1), NumberSequenceKeypoint.new(0.44, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(0.56, 0.55), NumberSequenceKeypoint.new(0.67, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		local cs
		if id == 2 then
			cs = ColorSequence.new(Color3.fromRGB(255, 224, 140))
		elseif id == 3 then
			cs = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 120, 220)),
				ColorSequenceKeypoint.new(0.42, Color3.fromRGB(120, 205, 255)), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.58, Color3.fromRGB(255, 236, 120)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(150, 255, 170)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
			})
		else
			cs = ColorSequence.new(Color3.new(1, 1, 1))
		end
		return cs, nks
	end
	local EDGE_COL = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(236, 241, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(150, 154, 170)), ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 36, 48)),
	})

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

	-- ===== 重ね貼り (SurfaceGui) のしくみ =====
	-- ・色 / 素材 / 反射の数値などの「軽い設定」は、呼ばれたその場(同じフレーム)で反映する。
	-- ・重ね貼りは数が多くて重いので、Heartbeat で「1フレームに数ミリ秒ぶん」ずつ作る。
	--   板はそれまでに平均色になっているので、できあがるまでの数フレームも色が付いて見える。板が出る瞬間にカクつかない。
	-- ・1面につき SurfaceGui は1枚。中の層(Frame)は G=グラデーション(下) と Gloss=ツヤ(上) の最大2枚。
	-- ・小さな面・小さな部品には重ねない (見た目にほとんど出ないのに、数だけ増えるため)。
	-- ・SurfaceGui の下絵(CanvasSize)は小さくする。色の帯だけなので十分きれいで、画像のメモリが約30分の1になる。
	-- ・できた面は作り直さず、中身(Color / Transparency)だけ書き換える → 設定を動かしてもちらつかない。
	-- ・「いまの設定」から毎回やることを決め直す方式なので、途中で設定が変わっても、リセットしても、必ず最新の見た目に落ち着く。
	local OVC = { budget = 0.004, maxJobs = 60, areaMin = 0.12, partMin = 0.01, maxFaces = 220, canvas = 128, maxSheen = 24, edgeMin = 20 }
	SK.OVC = OVC
	local OV = { list = {}, conn = nil }
	local FSIG = setmetatable({}, { __mode = "k" })   -- 面ごとに「層の中身を、どの設定で作ったか」を覚える (同じなら書き換えない)

	local function findFace(p, name)
		local want = Enum.NormalId[name]
		for _, c in ipairs(p:GetChildren()) do
			if c.Name == "SkinFace" and c.Face == want then return c end
		end
		return nil
	end
	-- 面の下絵の大きさ: 面の縦横の比に合わせる (長い辺が canvas px)。縁取りの線や光の帯が、面のどこでも同じ太さ・同じ角度に見える。小さいのでメモリも軽い
	local FACE_BY = {}
	for _, f in ipairs(FACES) do FACE_BY[f[1]] = f end
	local function faceCanvas(p, name)
		local f = FACE_BY[name]
		local z, r, u = p.Size, f[2], f[3]
		local w = math.abs(r.X) * z.X + math.abs(r.Y) * z.Y + math.abs(r.Z) * z.Z
		local h = math.abs(u.X) * z.X + math.abs(u.Y) * z.Y + math.abs(u.Z) * z.Z
		local m = math.max(w, h, 1e-3)
		local c = OVC.canvas
		return math.max(8, math.floor(c * w / m + 0.5)), math.max(8, math.floor(c * h / m + 0.5))
	end
	local function newFaceGui(name, cw, ch)
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SkinFace"
		sg.Face = Enum.NormalId[name]
		sg.LightInfluence = 1
		sg.AlwaysOnTop = false
		pcall(function() sg.Active = false end)
		pcall(function() sg.MaxDistance = 250 end)
		pcall(function() sg.CanvasSize = Vector2.new(cw or OVC.canvas, ch or OVC.canvas) end)
		return sg
	end
	local function makeLayer(name, z)
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.ZIndex = z
		local g = Instance.new("UIGradient")
		g.Parent = f
		return f, g
	end

	-- グラデの重ね貼りの透け具合 = 板の透明度。ただし「木目テクスチャ」をONにしている時は、木目が見えるよう 0.55 以上に透かす。
	-- さらに「素材を選んだ板」は、素材の模様(石目・木目・レンガなど)が重ね貼りの下から見えるよう、素材ごとに少し透かす
	-- (透かさないと、上や横の面はグラデが覆って模様が見えず、重ねていない下の面にだけ模様が出てしまう)
	local WOOD_SEE = 0.55
	local MAT_SEE = {   -- 素材 → 重ね貼りを透かす量 (模様がはっきりした素材ほど多め。つるつる・光る・透明系は 0)
		Plastic = 0, SmoothPlastic = 0, Neon = 0, Glass = 0, ForceField = 0, Foil = 0.18, Metal = 0.28, Rubber = 0.2,
		Wood = 0.44, WoodPlanks = 0.44, Marble = 0.4, Granite = 0.42, Slate = 0.4, Concrete = 0.38, Brick = 0.46, Cobblestone = 0.46,
		Basalt = 0.42, Pebble = 0.42, Limestone = 0.4, Sandstone = 0.4, Plaster = 0.3, CeramicTiles = 0.36, Sand = 0.4, Mud = 0.4,
		Snow = 0.3, Ice = 0.28, Glacier = 0.28, Fabric = 0.36, Carpet = 0.4, Leather = 0.38, Cardboard = 0.4, DiamondPlate = 0.46,
		CorrodedMetal = 0.46, CrackedLava = 0.44, Grass = 0.4, Ground = 0.4, Rock = 0.42, Asphalt = 0.4, Pavement = 0.4, Salt = 0.34,
		LeafyGrass = 0.4,
	}
	local MAT_SEE_DEFAULT = 0.3
	local function effGTr(s, p)
		local tr = p.Transparency
		if s.texUser == true and tr < WOOD_SEE then tr = WOOD_SEE end
		local sm = s.seeMat
		if sm == true or (type(sm) == "table" and sm[p]) then   -- 素材を選んだ板(部品)だけ (何も選んでいない板は、今までどおり色がくっきり)
			local ok, nm = pcall(function() return p.Material.Name end)
			local see = MAT_SEE[ok and nm or ""]
			if see == nil then see = MAT_SEE_DEFAULT end
			if tr < see then tr = see end
		end
		return tr
	end
	-- 光る素材 (ネオン・フォースフィールド) の上の重ね貼りは、明るさを環境光に左右されないようにする (素材が暗い場所で沈まないように)
	local function effLI(p)
		local ok, nm = pcall(function() return p.Material.Name end)
		if ok and (nm == "Neon" or nm == "ForceField") then return 0 end
		return 1
	end

	-- いまの設定から「どの面に、何を作る/更新するか」の作業表を作る
	local function ovPlan(model, s, ov)
		local parts = partsOf(model)
		local plan = {}
		local g = s.grad
		if g and g.smooth then
			if g.flow > 0 and g.ang then   -- 流れる時: 面ごとに「いまの色の並び」を作る。動かすのは各自の画面 (anim.lua) が、毎フレーム色の並びを書き換える
				local D = SK.flowVec(g.ang)
				local ex, span, lo = dirInfo(model, parts, D)
				if span > 1e-3 then plan.g = { cfg = g, flow = true, D = D, ex = ex, span = span, lo = lo, lut = SK.cycLUT(g) } end
			elseif g.flow <= 0 then
				local ex, span = axisInfo(model, parts, AXIS[g.axis])
				if span > 1e-3 then plan.g = { cfg = g, ax = AXIS[g.axis], ex = ex } end
			end
		end
		local k = glossK(s.refl or 0)
		if k > 0 then
			local trMax = 0   -- 板が透けているほど、ツヤの帯も薄くする (透けた板に不透明な白い帯が浮かないように)
			for _, p in ipairs(parts) do
				if p.Transparency > trMax then trMax = p.Transparency end
			end
			local id = GLOSS_STYLES[s.glossStyle or 1] and (s.glossStyle or 1) or 1
			local ax = AXIS[s.glossAxis or "X"] or 1
			local ex = axisInfo(model, parts, ax)
			local sid = SKIES[s.sky or 1] and (s.sky or 1) or 1
			plan.gl = { k = k * (1 - 0.6 * trMax), id = id, style = GLOSS_STYLES[id], ax = ax, ex = ex, flip = (g and g.topFlip) == true, sky = sid, env = SKIES[sid] }
		end
		if (s.sheen or 0) > 0 then plan.sh = { col = (s.sheenCol == 2 or s.sheenCol == 3) and s.sheenCol or 1 } end   -- 光が走る帯
		if (s.edge or 0) > 0 then plan.ed = { k = math.clamp(s.edge, 0, 1) } end                                      -- 角のハイライト
		-- 部品ごとの面の大きさ。大きな面だけに重ねる
		local areas, amax = {}, 0
		for i, p in ipairs(parts) do
			local z = p.Size
			local xy, zy, xz = z.X * z.Y, z.Z * z.Y, z.X * z.Z
			areas[i] = { Front = xy, Back = xy, Left = zy, Right = zy, Top = xz, max = math.max(xy, zy, xz) }
			if areas[i].max > amax then amax = areas[i].max end
		end
		local jobs, wanted, count, nSheen = {}, {}, 0, 0
		if plan.g or plan.gl or plan.sh or plan.ed then
			for _, f in ipairs(FORDER) do
				for i, p in ipairs(parts) do
					local a = areas[i]
					if count < OVC.maxFaces and a.max >= OVC.partMin * amax and a[f[1]] >= OVC.areaMin * a.max then
						local jg, jgl, jsh, jed
						local cw, ch = faceCanvas(p, f[1])
						if plan.g then
							if plan.g.flow then
								local ang, tc, ts = faceDir(plan.g.ex[i], f, p, plan.g.D, plan.g.span, plan.g.lo, plan.g.cfg.topFlip)
								jg = { flow = true, ang = ang, tc = tc, ts = ts }
							else
								local t0, t1, vert = faceWindow(plan.g.ex[i], f, plan.g.ax, plan.g.cfg.topFlip)
								if t0 then jg = { t0 = t0, t1 = t1, vert = vert } end
							end
						end
						if plan.gl then
							local e = plan.gl.ex[i]
							local t0, t1, vert = faceWindow(e, f, plan.gl.ax, plan.gl.flip)
							if not t0 then
								t0 = (e.ta + e.tb) / 2   -- 軸に沿わない面は、一定の濃さ
								t1, vert = t0, false
							end
							jgl = { t0 = t0, t1 = t1, vert = vert }
						end
						if plan.sh and f[1] == "Top" and nSheen < OVC.maxSheen and math.min(cw, ch) >= 8 then   -- 光が走るのは上の面だけ (動かす数を抑える)
							jsh = true
							nSheen = nSheen + 1
						end
						if plan.ed and cw >= OVC.edgeMin and ch >= OVC.edgeMin then jed = true end   -- 細すぎる面には線を引かない
						if jg or jgl or jsh or jed then
							count = count + 1
							jobs[#jobs + 1] = { p = p, face = f[1], i = i, g = jg, gl = jgl, sh = jsh, ed = jed, cw = cw, ch = ch }
							wanted[p] = wanted[p] or {}
							wanted[p][f[1]] = true
						end
					end
				end
			end
		end
		-- いらなくなった面は先に片づける (軽い仕事。古い見た目が残らないように)
		local work = {}
		for i, p in ipairs(parts) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fname = c.Face and c.Face.Name
					if not (fname and wanted[p] and wanted[p][fname]) then
						work[#work + 1] = { p = p, face = fname, i = i, sg = c }
					end
				end
			end
		end
		for _, j in ipairs(jobs) do work[#work + 1] = j end
		ov.plan, ov.jobs, ov.i = plan, work, 1
	end

	-- 1つの面を、作業表のとおりにする (なければ作る / あれば中身だけ書き換える / いらなければ消す)
	-- 層 (下から): G=グラデーション / Gloss=ツヤ / Sheen=光が走る帯 / Edge=角のハイライト。いらない層はその面から消す
	local function ovFace(model, s, plan, job)
		local p = job.p
		if p.Parent ~= model then return end
		local jg, jgl, jsh, jed = job.g, job.gl, job.sh, job.ed
		local sg = job.sg or findFace(p, job.face)
		if not jg and not jgl and not jsh and not jed then
			if sg then sg:Destroy() end
			return
		end
		local fresh = false
		if not sg then
			sg = newFaceGui(job.face, job.cw, job.ch)
			fresh = true
		end
		local rec = FSIG[sg]
		if not rec then rec = {} FSIG[sg] = rec end
		local cvs = job.cw .. "x" .. job.ch   -- 面の形が変わっていたら、下絵の大きさも合わせる (ふつうは変わらない)
		if fresh then
			rec.cv = cvs
		elseif rec.cv ~= cvs then
			pcall(function() sg.CanvasSize = Vector2.new(job.cw, job.ch) end)
			rec.cv = cvs
			rec.sh, rec.ed = nil, nil
		end

		-- G: グラデーション (下の層)
		local fG = sg:FindFirstChild("G")
		if jg then
			local gg
			if fG then
				gg = fG:FindFirstChildOfClass("UIGradient")
			else
				fG, gg = makeLayer("G", 1)
				rec.g = nil
			end
			if not gg then
				gg = Instance.new("UIGradient")
				gg.Parent = fG
				rec.g = nil
			end
			local cfg = plan.g.cfg
			if jg.flow then
				-- 流れる面: ここでは「いまの時刻の色の並び」を1回だけ書く (動かさない人にも、止まった状態で正しく見える)。
				-- 位置(tc)と幅(ts)は属性に残し、各自の画面 (anim.lua) が毎フレーム色の並びを書き換えて流す。速さが変わっても、ここは作り直さない
				local sig = string.format("F%d|%.5f|%.5f|%.2f", cfg.id, jg.tc, jg.ts, jg.ang)
				if rec.g ~= sig then
					gg.Rotation = jg.ang
					gg.Color = SK.flowSeq(cfg, plan.g.lut, jg.tc, jg.ts, SK.flowPhase(cfg.flow))
					fG:SetAttribute("PS_tc", jg.tc)
					fG:SetAttribute("PS_ts", jg.ts)
					rec.g = sig
				end
			else
				local sig = string.format("%d|%d|%.3f|%.3f|%d|%.5f|%.5f|%d", cfg.id, job.i, s.variance or 0, s.weather or 0, s.wkind or 1, jg.t0, jg.t1, jg.vert and 1 or 0)
				if rec.g ~= sig then
					local i = job.i
					gg.Color = buildSeq(cfg, jg.t0, jg.t1, function(c) return tint(s, i, c) end)
					gg.Rotation = jg.vert and 90 or 0
					if fG:GetAttribute("PS_tc") ~= nil then   -- 流れていた面が、止まった面になった
						fG:SetAttribute("PS_tc", nil)
						fG:SetAttribute("PS_ts", nil)
					end
					rec.g = sig
				end
			end
			local tr = effGTr(s, p)   -- 板の透明度に合わせる (重ね貼りだけ不透明に残らないように)
			if fG.BackgroundTransparency ~= tr then fG.BackgroundTransparency = tr end
			local li = effLI(p)
			if sg.LightInfluence ~= li then sg.LightInfluence = li end
			if fG.Parent ~= sg then fG.Parent = sg end
		elseif fG then
			fG:Destroy()
			rec.g = nil
		end

		-- Gloss: ツヤ
		local fL = sg:FindFirstChild("Gloss")
		if jgl then
			local gl = plan.gl
			local top = (job.face == "Top")
			local lg
			if fL then
				lg = fL:FindFirstChildOfClass("UIGradient")
			else
				fL, lg = makeLayer("Gloss", 2)
				rec.gl = nil
			end
			if not lg then
				lg = Instance.new("UIGradient")
				lg.Parent = fL
				rec.gl = nil
			end
			local sig = string.format("%d|%d|%d|%.5f|%.5f|%.5f|%d", gl.id, gl.sky, top and 1 or 0, gl.k, jgl.t0, jgl.t1, jgl.vert and 1 or 0)
			if rec.gl ~= sig then
				lg.Color, lg.Transparency = glossSeqs(gl.style, gl.k, jgl.t0, jgl.t1, top, gl.env)
				lg.Rotation = jgl.vert and 90 or 0
				rec.gl = sig
			end
			if fL.Parent ~= sg then fL.Parent = sg end
			s.hasGloss = true
		elseif fL then
			fL:Destroy()
			rec.gl = nil
		end

		-- Sheen: 光が走る帯。ふだんは面の外に置いておき、動かすのは各自の画面 (anim.lua)。長い辺に沿って走る
		local fS = sg:FindFirstChild("Sheen")
		if jsh then
			local sgd
			if fS then
				sgd = fS:FindFirstChildOfClass("UIGradient")
			else
				fS, sgd = makeLayer("Sheen", 3)
				rec.sh = nil
			end
			if not sgd then
				sgd = Instance.new("UIGradient")
				sgd.Parent = fS
				rec.sh = nil
			end
			local vert = job.ch > job.cw * 1.2
			local sig = string.format("%d|%d", plan.sh.col, vert and 1 or 0)
			if rec.sh ~= sig then
				sgd.Color, sgd.Transparency = sheenSeqs(plan.sh.col)
				sgd.Rotation = vert and (90 - SHEEN_TILT) or SHEEN_TILT
				sgd.Offset = vert and Vector2.new(0, SHEEN_HIDE) or Vector2.new(SHEEN_HIDE, 0)
				rec.sh = sig
			end
			if fS.Parent ~= sg then fS.Parent = sg end
			s.hasSheen = true
		elseif fS then
			fS:Destroy()
			rec.sh = nil
		end

		-- Edge: 角のハイライト。面のふちから少し内側に、左上は白く・右下は暗い細い線を引く (ふちが立体的に見える)
		local fE = sg:FindFirstChild("Edge")
		if jed then
			local k = plan.ed.k
			local es, eg
			if fE then
				es = fE:FindFirstChildOfClass("UIStroke")
			else
				fE = Instance.new("Frame")
				fE.Name = "Edge"
				fE.BackgroundTransparency = 1
				fE.BorderSizePixel = 0
				fE.ZIndex = 4
				rec.ed = nil
			end
			if not es then
				es = Instance.new("UIStroke")
				pcall(function() es.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
				es.Parent = fE
				eg = Instance.new("UIGradient")
				eg.Rotation = 45
				eg.Color = EDGE_COL
				eg.Parent = es
				rec.ed = nil
			end
			local sig = string.format("%.3f|%s", k, cvs)
			if rec.ed ~= sig then
				local inset = 2 + 1.5 * k
				fE.Position = UDim2.fromOffset(inset, inset)
				fE.Size = UDim2.new(1, -2 * inset, 1, -2 * inset)
				es.Thickness = 1 + 1.6 * k
				es.Transparency = 1 - 0.85 * k
				rec.ed = sig
			end
			if fE.Parent ~= sg then fE.Parent = sg end
			s.hasEdge = true
		elseif fE then
			fE:Destroy()
			rec.ed = nil
		end

		if fresh then sg.Parent = p end   -- 中身を全部つくってから、最後に板へ付ける (1面ぶんが1回でまとまって届く)
	end

	-- 1フレームぶんの作業。noLimit=true なら時間を気にせず全部終わらせる (テスト・確認用)
	local function ovStep(noLimit)
		local list = OV.list
		local t0, n = os.clock(), 0
		while #list > 0 do
			local ov = list[1]
			local model, s = ov.model, ov.s
			if stateOf[model] ~= s or not model.Parent then   -- リセットされた / 消えた板の分は、やめる
				ov.queued, ov.model, ov.plan, ov.jobs = false, nil, nil, nil
				table.remove(list, 1)
			else
				if not ov.jobs then
					local ok, err = pcall(ovPlan, model, s, ov)
					if not ok then
						ov.plan, ov.jobs, ov.i = {}, {}, 1
						if not ov.warned then ov.warned = true pcall(warn, "PalletStudio plan: " .. tostring(err)) end
					end
				end
				local job = ov.jobs[ov.i]
				if not job then
					ov.queued, ov.model, ov.plan, ov.jobs = false, nil, nil, nil
					table.remove(list, 1)
				else
					ov.i = ov.i + 1
					local ok, err = pcall(ovFace, model, s, ov.plan, job)
					if not ok and not ov.warned then ov.warned = true pcall(warn, "PalletStudio face: " .. tostring(err)) end
					n = n + 1
					if not ov.jobs[ov.i] then   -- いまのが最後の1つだった → その場で終わりにする (次のフレームまで待たない)
						ov.queued, ov.model, ov.plan, ov.jobs = false, nil, nil, nil
						table.remove(list, 1)
					end
					if not noLimit and (n >= OVC.maxJobs or os.clock() - t0 >= OVC.budget) then break end
				end
			end
		end
		if #list == 0 and OV.conn then
			OV.conn:Disconnect()
			OV.conn = nil
		end
	end
	function SK.ovFlush()   -- 作業待ちを全部、いますぐ終わらせる (テスト・確認用)
		local guard = 0
		while #OV.list > 0 and guard < 100000 do
			guard = guard + 1
			ovStep(true)
		end
	end
	function SK.ovPending() return #OV.list end

	-- 重ね貼りの中身が変わる設定をした時に呼ぶ: 次のフレームから、最新の設定で作り直し/更新する
	local function ovTouch(model)
		local s = st(model)
		local ov = s.ov
		if not ov then
			ov = { s = s, i = 1 }   -- (板そのものは、作業待ちの間だけ持つ。ずっと持つと、消えた板がメモリに残ってしまう)
			s.ov = ov
		end
		ov.jobs = nil
		ov.i = 1
		if not ov.queued then
			ov.queued = true
			ov.model = model
			OV.list[#OV.list + 1] = ov
			if not OV.conn then
				OV.conn = RunService.Heartbeat:Connect(function()
					local ok, err = pcall(ovStep, false)
					if not ok then   -- 想定外のエラーでも、毎フレーム止まり続けないように、先頭の1件を捨てて先へ進む
						pcall(warn, "PalletStudio overlay: " .. tostring(err))
						local bad = table.remove(OV.list, 1)
						if bad then bad.queued, bad.model, bad.plan, bad.jobs = false, nil, nil, nil end
					end
				end)
			end
		end
	end
	-- 消す側の操作の後に呼ぶ: 作りかけの古い作業表を捨てる (消したものを、あとから作ってしまわないように)
	local function ovInvalidate(model)
		local ov = st(model).ov
		if ov and ov.queued then
			ov.jobs = nil
			ov.i = 1
		end
	end

	-- 重ね貼りの層を、板の全パーツから消す (すぐ消える。消すのは軽い)
	local function dropLayers(model, names)
		for _, p in ipairs(partsOf(model)) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					for _, n in ipairs(names) do
						local f = c:FindFirstChild(n)
						if f then f:Destroy() end
					end
					if #c:GetChildren() == 0 then c:Destroy() end
				end
			end
		end
	end

	function SK.clearGloss(model)
		local s = st(model)
		if s.hasGloss then
			dropLayers(model, { "Gloss", "Sky", "Band" })   -- 古い版の Sky / Band も片づける
			s.hasGloss = nil
		end
		ovInvalidate(model)
	end

	-- ツヤの重ね貼りを、いまの反射の強さ(s.refl)に合わせる (作る/更新は次のフレームから少しずつ)
	function SK.gloss(model, parts)
		local s = st(model)
		if glossK(s.refl or 0) <= 0 then
			SK.clearGloss(model)
		else
			ovTouch(model)
		end
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

	-- いま流れているグラデーションの向き (度)。流れていなければ nil (プリセットに向きまで保存するため)
	function SK.flowAng(model)
		local s = stateOf[model]
		local g = s and s.grad
		if g and (g.flow or 0) > 0 then return g.ang end
		return nil
	end

	function SK.clearGrad(model)
		local s = st(model)
		local old = s.grad
		if not old then return end
		s.grad = nil
		dropLayers(model, { "G" })
		if old.topFlip and glossK(s.refl or 0) > 0 then
			ovTouch(model)   -- 上面の向きの反転がなくなるので、ツヤの向きも元に戻す
		else
			ovInvalidate(model)
		end
		syncAnim(model)
	end

	-- 板についている重ね貼りを全部消す (元に戻す時用。古い版の SkinGrad も消す)
	function SK.dropAll(model)
		for _, p in ipairs(partsOf(model)) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" or c.Name == "SkinGrad" then c:Destroy() end
			end
		end
		ovInvalidate(model)
	end

	function SK.refreshGradTr(model, parts)
		local s = st(model)
		for _, p in ipairs(parts) do
			local tr = effGTr(s, p)
			local li = effLI(p)
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fr = c:FindFirstChild("G")
					if fr and fr.BackgroundTransparency ~= tr then fr.BackgroundTransparency = tr end
					if c.LightInfluence ~= li then c.LightInfluence = li end
				end
			end
		end
	end

	-- ===== グラデーション (2色/3色を混ぜる。cfg.flow > 0 なら色が流れる) =====
	-- v = { a, b, c(なくても可), axis, rev, mid=0.1~0.9, smooth, stripes=0~8, topFlip, flow=0~2 }
	-- 流れる時 (flow > 0): 向きは「流すを選んだ時に1回だけ」ランダムに決まり (cfg.ang, 度)、流している間は変わらない。
	--   色の変え方・速さを動かしても、向きはそのまま。いったんOFFにして、もう一度ONにすると、新しい向きになる。
	--   向きは板の上から見た水平の向きなので、斜めにも流れる (X/Y/Z の「混ぜる向き」は、流れない時だけ効く)。
	local gradSerial = 0
	local function cfgSig(c)
		local function col(x) return x and string.format("%.4f,%.4f,%.4f", x.R, x.G, x.B) or "-" end
		return table.concat({ col(c.a), col(c.b), col(c.c), c.axis, c.rev and 1 or 0, string.format("%.3f", c.mid), c.stripes,
			c.smooth and 1 or 0, c.topFlip and 1 or 0, c.flow > 0 and string.format("%.2f", c.ang or 0) or "s" }, "|")
	end
	function SK.gradient(model, parts, v, keepTex)
		if typeof(v) ~= "table" or typeof(v.a) ~= "Color3" or typeof(v.b) ~= "Color3" or not AXIS[v.axis] then return false end
		local s = st(model)
		local old = s.grad
		local cfg = {
			a = v.a, b = v.b, c = (typeof(v.c) == "Color3") and v.c or nil, axis = v.axis, rev = v.rev == true,
			smooth = v.smooth ~= false, topFlip = v.topFlip == true,
			mid = isNum(v.mid) and math.clamp(v.mid, 0.1, 0.9) or 0.5,
			stripes = isNum(v.stripes) and math.clamp(math.floor(v.stripes), 0, 8) or 0,
			flow = isNum(v.flow) and math.clamp(v.flow, 0, 2) or 0,
		}
		if cfg.flow > 0 then
			if old and (old.flow or 0) > 0 and old.ang then
				cfg.ang = old.ang   -- すでに流れている: 向きはそのまま
			elseif isNum(v.ang) then
				cfg.ang = v.ang % 360   -- 保存したプリセットから呼ばれた時: その時の向きをそのまま使う
			else
				cfg.ang = pickFlowAngle()   -- 流し始め: ここで1回だけ決める
			end
		end
		cfg.sig = cfgSig(cfg)
		if old and old.sig == cfg.sig then
			cfg.id = old.id   -- 見た目が同じなら、面の作り直しはしない
		else
			gradSerial = gradSerial + 1
			cfg.id = gradSerial
		end
		s.rainbow = nil
		s.userCol = true   -- 自分で選んだ色 (このあと素材を選んでも、色は残す)
		if not keepTex then
			s.texUser = false
			setTexture(parts, false)   -- 木目が上に残ると色が見えないので、外す
		end
		s.grad = cfg
		s.base = gradAt(cfg, 0.5)
		-- 板そのものの色 (軽い設定): まず部品ごとの平均色にして、その場で反映する。重ね貼りができるまでの間も、色が付いて見える
		local span
		if cfg.flow > 0 then
			local ex, sp = dirInfo(model, parts, SK.flowVec(cfg.ang))
			span = sp
			local lut = SK.cycLUT(cfg)
			for i, p in ipairs(parts) do
				remember(p)
				local e = ex[i]
				local tc = (e.ta + e.tb) / 2
				setCol(p, tint(s, i, SK.flowCol(cfg, lut, tc)))   -- 流れない人の画面・重ね貼りしない面・流れの元の色は、この平均色
				p:SetAttribute("PS_T", tc)
			end
		else
			local ex, sp = axisInfo(model, parts, AXIS[cfg.axis])
			span = sp
			for i, p in ipairs(parts) do
				remember(p)
				local e = ex[i]
				local tc = (e.ta + e.tb) / 2
				setCol(p, tint(s, i, gradAt(cfg, tc)))   -- 重ね貼りしない面(裏・端)の色は、この平均色
				p:SetAttribute("PS_T", tc)
			end
		end
		syncAnim(model)
		if cfg.smooth and span > 1e-3 then
			ovTouch(model)   -- なめらかな重ね貼りは、次のフレームから少しずつ作る / 更新する (すでにあれば、作り直さず色だけ変える)
		else
			dropLayers(model, { "G" })   -- 重ね貼りしない設定 (くっきり): いまある分は、すぐ消す
			ovInvalidate(model)
		end
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

	-- 「光の波」「光が走る帯」の時間差用: 板の長い方向での位置を、パーツごとに 0〜1 で属性 PS_W に書く (PS_T とは別。グラデの向きに左右されない)
	function SK.assignW(model, parts)
		local exX, spX = axisInfo(model, parts, 1)
		local exZ, spZ = axisInfo(model, parts, 3)
		local ex = (spX >= spZ) and exX or exZ
		for i, p in ipairs(parts) do
			p:SetAttribute("PS_W", (ex[i].ta + ex[i].tb) / 2)
		end
	end

	-- 経年劣化の「雪(上ほど)」「こけ(下ほど)」用: パーツごとの高さ 0(下)〜1(上) を、設定に覚えておく
	function SK.setHeights(model, parts)
		local s = st(model)
		local ex, span = axisInfo(model, parts, 2)
		local wh = {}
		for i = 1, #parts do
			wh[i] = (span > 1e-3) and (ex[i].ta + ex[i].tb) / 2 or 0.5
		end
		s.wh = wh
	end

	-- ツートン: 板の一部を選ぶ。mode = Top 上の段 / Bottom 下の段 / Half1 前半 / Half2 後半 / Stripe しましま / Outer 外側 / Random ランダム
	-- 戻り値: { [パーツ] = true }。パーツが2つ以上あれば、必ず「一部だけ」(すべて・ゼロにならない)。不正な mode は nil
	local TWO_MODE = { Top = true, Bottom = true, Half1 = true, Half2 = true, Stripe = true, Outer = true, Random = true }
	function SK.groupParts(model, parts, mode)
		if not TWO_MODE[mode] then return nil end
		local n = #parts
		local exY, spY = axisInfo(model, parts, 2)
		local exX, spX = axisInfo(model, parts, 1)
		local exZ, spZ = axisInfo(model, parts, 3)
		local long = (spX >= spZ) and exX or exZ
		local function cen(e) return (e.ta + e.tb) / 2 end
		local score = {}   -- 大きいものから順に選ぶ (同点はパーツの順番)
		local sel = {}     -- 基準で直接決まる時は、ここに true を入れる
		local direct = false
		if mode == "Top" or mode == "Bottom" then
			local ex = (spY > 1e-3) and exY or long   -- 高さに差がない板は、長い方向で分ける
			local top = (mode == "Top")
			for i = 1, n do
				local t = cen(ex[i])
				sel[i] = top and t >= 0.66 or (not top and t <= 0.34)
				score[i] = top and t or -t
			end
			direct = true
		elseif mode == "Half1" or mode == "Half2" then
			for i = 1, n do
				local t = cen(long[i])
				sel[i] = (mode == "Half1") and t < 0.5 or (mode == "Half2" and t >= 0.5)
				score[i] = (mode == "Half2") and t or -t
			end
			direct = true
		elseif mode == "Stripe" then
			local order = {}
			for i = 1, n do order[i] = i end
			table.sort(order, function(a, b)
				local ca, cb = cen(long[a]), cen(long[b])
				if ca ~= cb then return ca < cb end
				return a < b
			end)
			for r, i in ipairs(order) do
				sel[i] = (r % 2 == 0)
				score[i] = sel[i] and 1 or 0
			end
			direct = true
		elseif mode == "Outer" then
			for i = 1, n do
				local dx = (spX > 1e-3) and math.abs(cen(exX[i]) - 0.5) or 0
				local dz = (spZ > 1e-3) and math.abs(cen(exZ[i]) - 0.5) or 0
				score[i] = math.max(dx, dz) + i * 1e-6
			end
		else   -- Random: パーツの番号から決める (毎回同じ結果になる)
			for i = 1, n do score[i] = ((i * 7919 + 13) % 101) / 101 end
		end
		local set, c = {}, 0
		if direct then
			for i = 1, n do
				if sel[i] then set[parts[i]] = true c = c + 1 end
			end
		end
		if (not direct or c == 0 or c >= n) and n >= 2 then   -- 基準だけでは決まらない / 全部・ゼロになった時は、点数の上から半分
			set, c = {}, 0
			local order = {}
			for i = 1, n do order[i] = i end
			table.sort(order, function(a, b)
				if score[a] ~= score[b] then return score[a] > score[b] end
				return a < b
			end)
			for r = 1, math.max(1, math.floor(n / 2)) do set[parts[order[r]]] = true end
		end
		return set
	end

	-- 光が走る帯 (Sheen) を付ける / 外す。speed=0 で外す。走る速さは各自の画面側(anim.lua)が属性から読む
	function SK.sheen(model, parts, speed)
		local s = st(model)
		local was = (s.sheen or 0) > 0
		if speed > 0 then
			s.sheen = speed
			SK.assignW(model, parts)
			if not was then ovTouch(model) end   -- 付けたばかりの時だけ、層を作る (速さだけ変える時は作り直さない)
		else
			s.sheen = nil
			if s.hasSheen then
				dropLayers(model, { "Sheen" })
				s.hasSheen = nil
			end
			ovInvalidate(model)
		end
		syncAnim(model)
	end
	-- 角のハイライト (Edge) を付ける / 外す。v=0 で外す
	function SK.edge(model, parts, v)
		local s = st(model)
		if v > 0 then
			s.edge = v
			ovTouch(model)
		else
			s.edge = nil
			if s.hasEdge then
				dropLayers(model, { "Edge" })
				s.hasEdge = nil
			end
			ovInvalidate(model)
		end
	end
	function SK.relayer(model) ovTouch(model) end   -- 重ね貼りの設定を変えた時に、作り直し/更新を頼む
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
		SK.refreshGradTr(model, parts)   -- 素材が変わると、重ね貼りの透け具合の決まりも変わる (ネオンは透かさない)
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
	-- 光・動き・質感まわりの追加設定も、いったん初期に戻す (画面のスイッチ類も同時に初期へ戻るので、合わせておく)
	s.pdepth, s.pwave, s.gmode, s.gcol2, s.gspeed, s.night, s.spot, s.ofill, s.lightShape = nil, nil, nil, nil, nil, nil, nil, nil, nil
	s.sky, s.wkind, s.wh, s.glossAxis, s.variance, s.weather = nil, nil, nil, nil, nil, nil
	twoOff(model, parts, false)
	SK.sheen(model, parts, 0)
	SK.edge(model, parts, 0)
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
	s.userCol = true     -- プリセットの色は、自分で選んだ色として扱う (このあと素材を選んでも色は残る)
	s.seeMat = true      -- 素材の模様が、グラデの下から見える
	s.glowLook = nil
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

local PULSE_STYLES = { Sine = true, Beat = true, Flicker = true, Strobe = true, Breath = true, Lightning = true, Neon = true, Saw = true, Steps = true, SOS = true }
local MAX_BATCH = 100
local applySkin
function applySkin(model, kind, value)
	local parts = partsOf(model)
	if #parts == 0 then return "板の部品が見つかりません" end
	local s = st(model)
	-- 素材ボタン (Look): 自分で色(単色・グラデ・レインボー)を選んでいる板では、色は消さずに素材だけ変える (smart)。
	-- まだ色を選んでいない板は、今までどおり素材の色になる。素材の色にしたい時は LookRaw
	local smart = (kind == "Look" and s.userCol == true)
	if s.two and (kind == "Look" or kind == "LookKeep" or kind == "LookRaw" or kind == "Material" or kind == "Preset") then s.two = nil end   -- 素材を丸ごと入れ替える操作は、ツートンをやめる
	-- 色を直接変える操作・レインボーONの時は、重ね貼りしているグラデーションを先に外す。色を決める操作はレインボーも止める
	local recolor = kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "LookRaw" or (kind == "Look" and not smart) or kind == "Preset"
	if recolor or (kind == "Rainbow" and value == true) then
		SK.clearGrad(model)
	end
	if recolor then
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
		s.userCol = true
		paint(model, parts, value)
		return "色を変えました"
	elseif kind == "HSV" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		s.userCol = true
		paint(model, parts, Color3.fromHSV(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "RGB" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		s.userCol = true
		paint(model, parts, Color3.new(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "Material" then
		if typeof(value) ~= "string" or not MATERIAL_SET[value] then return "素材が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Material = Enum.Material[value] end
		s.seeMat = true
		SK.refreshGradTr(model, parts)   -- 素材の模様が、グラデの下から見えるように
		return "素材を「" .. value .. "」にしました"
	elseif kind == "Look" or kind == "LookRaw" then
		local lk = typeof(value) == "string" and LOOKS[value] or nil
		if not lk then return "素材が不正です" end
		s.neon, s.neonSaved = nil, nil
		s.texUser = false
		setTexture(parts, false)
		if smart then   -- 自分で選んだ色は残して、素材とその質感(反射・透け)だけ変える。光は、素材で付いた光なら入れ替え、自分で決めた光なら残す
			for _, p in ipairs(parts) do
				remember(p)
				p.Material = Enum.Material[lk[2]]
				p.Transparency = lk[4]
			end
			SK.reflect(model, parts, lk[3])
			s.seeMat = true
			SK.refreshGradTr(model, parts)
			if s.glowLook or (s.glowB or 0) <= 0 then
				setGlow(model, s.glowColor or s.base or lk[1], lk[5], 10)
				s.glowLook = lk[5] > 0 or nil
			end
			return "素材「" .. value .. "」にしました (色はそのまま)"
		end
		s.glowColor = nil
		s.userCol = false
		s.seeMat = true
		paint(model, parts, lk[1])
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[lk[2]]
			p.Transparency = lk[4]
		end
		SK.reflect(model, parts, lk[3])
		setGlow(model, lk[1], lk[5], 10)
		s.glowLook = lk[5] > 0 or nil
		return "素材「" .. value .. "」にしました"
	elseif kind == "LookKeep" then   -- 色・光はそのままで、素材とその質感(反射・透け)だけ変える
		local lk = typeof(value) == "string" and LOOKS[value] or nil
		if not lk then return "素材が不正です" end
		s.neon, s.neonSaved = nil, nil
		s.texUser = false
		setTexture(parts, false)
		for _, p in ipairs(parts) do
			remember(p)
			p.Material = Enum.Material[lk[2]]
			p.Transparency = lk[4]
		end
		SK.reflect(model, parts, lk[3])
		s.seeMat = true
		SK.refreshGradTr(model, parts)
		return "素材「" .. value .. "」だけ変えました"
	elseif kind == "LookClear" then   -- 素材ボタンをもう一度押した時: 素材・質感を元の板に戻す (自分で選んだ色は残す。素材の色だった時は、元の色へ)
		local oc
		for i, p in ipairs(parts) do
			local o = orig[p]
			if o then
				p.Material, p.Reflectance, p.Transparency = o[2], o[3], o[4]
				if not s.userCol then setCol(p, tint(s, i, o[1])) end
				oc = oc or o[1]
			end
		end
		if not s.userCol and oc then s.base = oc end
		s.refl = 0
		for _, p in ipairs(parts) do
			if p.Reflectance > s.refl then s.refl = p.Reflectance end
		end
		SK.gloss(model, parts)
		s.seeMat = nil
		s.neon, s.neonSaved = nil, nil
		if not s.grad then
			s.texUser = nil
			setTexture(parts, true)
		end
		if s.glowLook then
			s.glowLook = nil
			setGlow(model, Color3.new(1, 1, 1), 0, nil)
		end
		SK.refreshGradTr(model, parts)
		return "素材を元に戻しました"
	elseif kind == "TwoTone" then   -- 板の一部だけ別の素材 (と色) にする
		if typeof(value) ~= "table" or typeof(value.mat) ~= "string" or not MATERIAL_SET[value.mat] then return "素材が不正です" end
		local set = SK.groupParts(model, parts, value.mode)
		if not set then return "分け方が不正です" end
		local plain = not s.grad and not s.rainbow   -- グラデ・レインボー中は、色はそちらに従う
		twoOff(model, parts, plain)   -- 前のツートンの素材と色は元に戻してから、新しく分ける
		local prev, back = {}, {}
		for _, p in ipairs(parts) do
			if set[p] then
				remember(p)
				prev[p] = p.Material
				p.Material = Enum.Material[value.mat]
				back[#back + 1] = p
			end
		end
		setTexture(back, false)   -- 木目が残ると、新しい素材が見えない
		local col
		if value.same ~= true then
			col = (typeof(value.col) == "Color3") and value.col or (LOOKS[value.mat] and LOOKS[value.mat][1]) or nil
		end
		s.two = { set = set, prev = prev, col = col }
		if s.seeMat ~= true then   -- 別の素材にした部分だけ、模様をグラデの下から見せる
			local sm = type(s.seeMat) == "table" and s.seeMat or {}
			for _, p in ipairs(parts) do sm[p] = set[p] or nil end
			s.seeMat = sm
		end
		SK.refreshGradTr(model, parts)
		if plain then
			for i, p in ipairs(parts) do
				if set[p] then
					local c = col or s.base
					if c then setCol(p, tint(s, i, c)) end
				end
			end
		end
		return "一部を「" .. value.mat .. "」にしました"
	elseif kind == "TwoToneClear" then
		if s.two then
			twoOff(model, parts, not s.grad and not s.rainbow)
		end
		if type(s.seeMat) == "table" then s.seeMat = nil end
		SK.refreshGradTr(model, parts)
		return "ツートンをやめました"
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
	elseif kind == "WeatherKind" then   -- 経年劣化の種類: 1 汚れ / 2 さび / 3 こけ / 4 雪 / 5 焦げ
		if not isNum(value) then return "値が不正です" end
		s.wkind = math.clamp(math.floor(value + 0.5), 1, WEATHER_N)
		SK.setHeights(model, parts)
		if s.grad then SK.gradient(model, parts, s.grad, true) else paint(model, parts, s.base or parts[1].Color) end
		return "経年劣化の種類を変えました"
	elseif kind == "GlossSky" then   -- 映り込む空: 1 昼 / 2 夕焼け / 3 夜 / 4 ネオン / 5 オーロラ / 6 スタジオ
		if not isNum(value) then return "値が不正です" end
		s.sky = math.clamp(math.floor(value + 0.5), 1, SK.SKIES)
		SK.gloss(model, parts)
		return "映り込む空を変えました"
	elseif kind == "Sheen" then   -- 光が走る帯 (0 で止める)
		if not isNum(value) then return "値が不正です" end
		SK.sheen(model, parts, math.clamp(value, 0, 1))
		return value > 0 and "光が走ります" or "光の走りを止めました"
	elseif kind == "SheenColor" then
		if not isNum(value) then return "値が不正です" end
		s.sheenCol = math.clamp(math.floor(value + 0.5), 1, 3)
		if (s.sheen or 0) > 0 then SK.relayer(model) end
		return "光の色を変えました"
	elseif kind == "Edge" then   -- 角のハイライト
		if not isNum(value) then return "値が不正です" end
		SK.edge(model, parts, math.clamp(value, 0, 1))
		return "角のハイライトを変えました"
	elseif kind == "Texture" then
		s.texUser = (value == true)
		setTexture(parts, value == true)
		if s.grad then SK.refreshGradTr(model, parts) end   -- グラデが木目を隠さないよう、透け具合を合わせる
		return value == true and "テクスチャON" or "テクスチャOFF"
	elseif kind == "Glow" then
		if not isNum(value) then return "値が不正です" end
		s.glowLook = nil   -- 自分で決めた光
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
		s.glowLook = nil
		s.glowColor = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then l.Color = s.glowColor end
		model:SetAttribute("PS_GlowCol", s.glowColor)
		return "発光の色を変えました"
	elseif kind == "Rainbow" then
		if value == true then s.userCol = true end
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
	elseif kind == "PulseDepth" then   -- 明滅の深さ: 1 = 完全に暗くなる / 0 = ほとんど変わらない
		if not isNum(value) then return "値が不正です" end
		s.pdepth = math.clamp(value, 0, 1)
		syncAnim(model)
		return "明滅の深さを変えました"
	elseif kind == "PulseWave" then   -- 板の端から端へ、明滅がずれて走る (板も一緒に明滅している時)
		if not isNum(value) then return "値が不正です" end
		s.pwave = math.clamp(value, 0, 1)
		if s.pwave > 0 then SK.assignW(model, parts) end
		syncAnim(model)
		return "光の波を変えました"
	elseif kind == "GlowMode" then   -- 光の色の動き: Solid 単色 / Blend 2色を往復 / Alt 2色を交互 / Hue 虹色
		if value ~= "Solid" and value ~= "Blend" and value ~= "Alt" and value ~= "Hue" then return "値が不正です" end
		s.gmode = value
		syncAnim(model)
		return "光の色の動きを変えました"
	elseif kind == "GlowHue2" then
		if not isNum(value) then return "値が不正です" end
		s.gcol2 = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		syncAnim(model)
		return "2つ目の光の色を変えました"
	elseif kind == "GlowSpeed" then
		if not isNum(value) then return "値が不正です" end
		s.gspeed = math.clamp(value, 0.05, 1.5)
		syncAnim(model)
		return "色が変わる速さを変えました"
	elseif kind == "NightGlow" then
		s.night = (value == true)
		syncAnim(model)
		return value == true and "夜だけ光ります" or "いつでも光ります"
	elseif kind == "SpotAngle" then
		if not isNum(value) then return "値が不正です" end
		s.spot = math.clamp(value, 10, 120)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l and l.ClassName == "SpotLight" then l.Angle = s.spot end
		return "スポットの広さを変えました"
	elseif kind == "OutlineFill" then   -- 縁取りの内側を光らせる (オーラ)
		if not isNum(value) then return "値が不正です" end
		s.ofill = math.clamp(value, 0, 1)
		if s.ofill > 0 or model:FindFirstChild("SkinOutline") then setOutline(model, true) end
		return "オーラの強さを変えました"
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
			p:SetAttribute("PS_W", nil)
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
---------------------------------------------------------------------
-- GitHub保存 (サーバー側)
--  画面側 (LocalScript) は Roblox の決まりで通信できないので、ここが代わりに GitHub の API と話す。
--  1人1ファイル「<フォルダ>/<IDの名前>.json」に、設定だけ (永久保存の見た目・プリセット・UI設定・軽量化の選択) を預かる。
--  ・トークンは、Secrets (名前: PalletStudioGitHub) か、ServerStorage の StringValue「PalletStudioGitHubToken」から読む。画面側へは絶対に送らない。
--  ・受け付けるのは「呼んだ本人のファイル」だけ。中身は形と大きさを検査して、決まった項目だけを書く。
--  ・書き込みは、変更が止まってから (6秒) まとめて1回。同じ内容なら書かない。全員ぶんをあわせて 1.5秒に1回までに抑える。
--  ・読み込みに成功するまでは保存しない (読めなかったのに、空の設定で前の保存を上書きしてしまうのを防ぐ)。
---------------------------------------------------------------------
do
	local HttpService = game:GetService("HttpService")
	local ServerStorage = game:GetService("ServerStorage")

	-- 設定 (画面側のファイルの先頭で決めた値)。形がおかしい時は「オフ」にする (URL に混ぜるので、使える文字だけにする)
	local REPO = type(GH_REPO) == "string" and GH_REPO or ""
	local BRANCH = type(GH_BRANCH) == "string" and GH_BRANCH or ""
	local DIR = type(GH_DIR) == "string" and GH_DIR or ""
	if not REPO:match("^[%w%-_%.]+/[%w%-_%.]+$") then REPO = "" end
	if not BRANCH:match("^[%w%-_%./]*$") or BRANCH:find("..", 1, true) then BRANCH = "" end
	DIR = (DIR:gsub("^/+", ""))
	DIR = (DIR:gsub("/+$", ""))
	if not DIR:match("^[%w%-_%./]*$") or DIR:find("..", 1, true) or DIR:find("//", 1, true) then DIR = "PalletStudio" end

	local MAX_JSON = 300000   -- 1人ぶんのファイルの大きさの上限 (文字)
	local DEBOUNCE = 6        -- 最後の保存依頼から、この秒数だけ静かなら書く
	local PLAYER_GAP = 10     -- 同じ人の書き込みは、この秒数以上あける
	local GLOBAL_GAP = 1.5    -- だれの分でも、GitHub への書き込みはこの秒数以上あける
	local API = "https://api.github.com/repos/" .. REPO

	local cloudRF = ReplicatedStorage:FindFirstChild("PalletStudioCloud_v1")
	if not cloudRF then
		cloudRF = Instance.new("RemoteFunction")
		cloudRF.Name = "PalletStudioCloud_v1"
		cloudRF.Parent = ReplicatedStorage
	end
	local cloudEv = ReplicatedStorage:FindFirstChild("PalletStudioCloudEvt_v1")
	if not cloudEv then
		cloudEv = Instance.new("RemoteEvent")
		cloudEv.Name = "PalletStudioCloudEvt_v1"
		cloudEv.Parent = ReplicatedStorage
	end

	---------------------------------------------------------------
	-- base64 (GitHub は、ファイルの中身を base64 でやりとりする)
	---------------------------------------------------------------
	local B64C, B64V = {}, {}
	do
		local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		for i = 1, 64 do
			local ch = chars:sub(i, i)
			B64C[i - 1] = ch
			B64V[ch:byte()] = i - 1
		end
	end
	local function b64enc(s)
		local out, n, len = {}, 0, #s
		local i = 1
		while i + 2 <= len do
			local a, b, c = s:byte(i, i + 2)
			local v = a * 65536 + b * 256 + c
			n = n + 1
			out[n] = B64C[math.floor(v / 262144)] .. B64C[math.floor(v / 4096) % 64] .. B64C[math.floor(v / 64) % 64] .. B64C[v % 64]
			i = i + 3
		end
		local rem = len - i + 1
		if rem == 1 then
			local v = s:byte(i) * 65536
			n = n + 1
			out[n] = B64C[math.floor(v / 262144)] .. B64C[math.floor(v / 4096) % 64] .. "=="
		elseif rem == 2 then
			local a, b = s:byte(i, i + 1)
			local v = a * 65536 + b * 256
			n = n + 1
			out[n] = B64C[math.floor(v / 262144)] .. B64C[math.floor(v / 4096) % 64] .. B64C[math.floor(v / 64) % 64] .. "="
		end
		return table.concat(out)
	end
	local function b64dec(s)
		s = (s:gsub("[^%w%+/]", ""))   -- 改行や「=」は取りのぞく
		local out, n, len = {}, 0, #s
		local i = 1
		while i + 3 <= len do
			local a, b, c, d = s:byte(i, i + 3)
			local v = B64V[a] * 262144 + B64V[b] * 4096 + B64V[c] * 64 + B64V[d]
			n = n + 1
			out[n] = string.char(math.floor(v / 65536), math.floor(v / 256) % 256, v % 256)
			i = i + 4
		end
		local rem = len - i + 1
		if rem == 2 then
			local v = B64V[s:byte(i)] * 262144 + B64V[s:byte(i + 1)] * 4096
			n = n + 1
			out[n] = string.char(math.floor(v / 65536))
		elseif rem == 3 then
			local v = B64V[s:byte(i)] * 262144 + B64V[s:byte(i + 1)] * 4096 + B64V[s:byte(i + 2)] * 64
			n = n + 1
			out[n] = string.char(math.floor(v / 65536), math.floor(v / 256) % 256)
		end
		return table.concat(out)
	end

	---------------------------------------------------------------
	-- 読みやすい JSON (キーは名前順。短い物は1行に。GitHub 上で見やすく、変更の差分も小さくなる)
	---------------------------------------------------------------
	local function jstr(s)
		return '"' .. (s:gsub('[%c"\\]', function(c)
			if c == '"' then return '\\"' end
			if c == "\\" then return "\\\\" end
			if c == "\n" then return "\\n" end
			if c == "\r" then return "\\r" end
			if c == "\t" then return "\\t" end
			return string.format("\\u%04x", string.byte(c))
		end)) .. '"'
	end
	local function jnum(n)
		if n ~= n or n == math.huge or n == -math.huge then return "null" end
		if n == math.floor(n) and math.abs(n) < 1e15 then
			if n == 0 then return "0" end
			return string.format("%.0f", n)
		end
		return (string.format("%.10g", n))
	end
	local function scalarJ(v)
		local t = type(v)
		if t == "string" then return jstr(v) end
		if t == "number" then return jnum(v) end
		if t == "boolean" then return v and "true" or "false" end
		return nil
	end
	-- 並べる順番を決める: 配列なら 1,2,3… / 辞書なら名前順。2つめの戻り値は「配列か」
	local function keysOf(v)
		local n, max, arr = 0, 0, true
		for k in pairs(v) do
			n = n + 1
			if type(k) == "number" and k >= 1 and k == math.floor(k) then
				if k > max then max = k end
			else
				arr = false
			end
		end
		local keys = {}
		if arr and max == n then
			for i = 1, n do keys[i] = i end
			return keys, true
		end
		for k in pairs(v) do
			if type(k) == "string" then keys[#keys + 1] = k end
		end
		table.sort(keys)
		return keys, false
	end
	-- 1行で書ける (長さ room 以内) なら、その文字。だめなら nil
	local function inlineJ(v, room)
		local s = scalarJ(v)
		if s then return (#s <= room) and s or nil end
		if type(v) ~= "table" then return "null" end
		local keys, arr = keysOf(v)
		if #keys == 0 then return "[]" end
		if #keys > 12 then return nil end
		local parts, used = {}, 4
		for i, k in ipairs(keys) do
			local sv = inlineJ(v[k], room - used)
			if not sv then return nil end
			parts[i] = arr and sv or (jstr(k) .. ": " .. sv)
			used = used + #parts[i] + 2
			if used > room then return nil end
		end
		local line = table.concat(parts, ", ")
		return arr and ("[" .. line .. "]") or ("{ " .. line .. " }")
	end
	local function prettyJ(v, ind, out)
		local one = inlineJ(v, 92 - #ind)
		if one then
			out[#out + 1] = one
			return
		end
		local keys, arr = keysOf(v)
		local pad = ind .. "  "
		out[#out + 1] = arr and "[\n" or "{\n"
		for i, k in ipairs(keys) do
			out[#out + 1] = pad
			if not arr then out[#out + 1] = jstr(k) .. ": " end
			prettyJ(v[k], pad, out)
			out[#out + 1] = (i < #keys) and ",\n" or "\n"
		end
		out[#out + 1] = ind .. (arr and "]" or "}")
	end
	local function toJson(v)
		local out = {}
		prettyJ(v, "", out)
		return table.concat(out) .. "\n"
	end

	---------------------------------------------------------------
	-- 検査: 画面から届いた物 / ファイルから読んだ物を、決まった形だけに作り直す
	--  (数字・文字・true/false・配列・辞書だけ。深さ・個数・文字数に上限。関数や Instance などは捨てる)
	---------------------------------------------------------------
	local function cleanV(v, depth, st)
		local t = type(v)
		if t == "number" then
			if v ~= v or v == math.huge or v == -math.huge then return nil end
			return v
		elseif t == "boolean" then
			return v
		elseif t == "string" then
			if #v > 120 or utf8.len(v) == nil then return nil end
			return v
		elseif t == "table" then
			if depth > 8 then st.bad = true return nil end
			local out, cnt = {}, 0
			for k, x in pairs(v) do
				cnt = cnt + 1
				st.items = st.items + 1
				if cnt > 600 or st.items > 80000 then st.bad = true return nil end
				local ck
				if type(k) == "number" then
					if k ~= math.floor(k) or k < 1 or k > 600 then st.bad = true return nil end
					ck = k
				elseif type(k) == "string" and #k <= 40 and not k:find("%c") then
					ck = k
				else
					st.bad = true
					return nil
				end
				local cv = cleanV(x, depth + 1, st)
				if st.bad then return nil end
				if cv ~= nil then out[ck] = cv end
			end
			return out
		end
		return nil
	end
	local TOP_KEYS = { "perm", "presets", "ui", "opt" }
	local function sanitize(data)
		if type(data) ~= "table" then return nil, "bad" end
		local st = { items = 0 }
		local out = { v = 1 }
		for _, key in ipairs(TOP_KEYS) do
			if data[key] ~= nil then
				local c = cleanV(data[key], 1, st)
				if st.bad then return nil, "big" end
				if c ~= nil then out[key] = c end
			end
		end
		return out
	end

	---------------------------------------------------------------
	-- GitHub との通信
	---------------------------------------------------------------
	-- トークン: Secrets (本番サーバー) → ServerStorage の StringValue (Studio のテスト用) の順に探す。見つからなければ nil
	local function authValue()
		local ok, sec = pcall(function() return HttpService:GetSecret("PalletStudioGitHub") end)
		if ok and sec then
			local ok2, withPrefix = pcall(function() return sec:AddPrefix("Bearer ") end)
			if ok2 and withPrefix then return withPrefix end
		end
		local v = ServerStorage:FindFirstChild("PalletStudioGitHubToken")
		if v and v:IsA("StringValue") then
			local tok = ((v.Value or ""):gsub("%s", ""))
			if tok ~= "" then return "Bearer " .. tok end
		end
		return nil
	end
	local function hdr(res, name)
		local h = res.Headers
		if type(h) ~= "table" then return nil end
		if h[name] ~= nil then return h[name] end
		for k, x in pairs(h) do
			if type(k) == "string" and k:lower() == name then return x end
		end
		return nil
	end
	-- 1回の通信。戻り値: 応答の表 / (nil, エラーの種類)。エラーの種類: no_token / http_off / net
	local function http(method, url, bodyTable)
		local auth = authValue()
		if not auth then return nil, "no_token" end
		local headers = { Authorization = auth, Accept = "application/vnd.github+json", ["X-GitHub-Api-Version"] = "2022-11-28" }
		local body
		if bodyTable then
			headers["Content-Type"] = "application/json"
			body = HttpService:JSONEncode(bodyTable)
		end
		local ok, res = pcall(function()
			return HttpService:RequestAsync({ Url = url, Method = method, Headers = headers, Body = body })
		end)
		if not ok then
			if tostring(res):lower():find("not enabled", 1, true) then return nil, "http_off" end
			return nil, "net"
		end
		if type(res) ~= "table" then return nil, "net" end
		return res
	end
	-- 失敗した応答の種類。2つめの戻り値は、待つ秒数 (回数制限の時だけ)
	local function classify(res)
		local c = res.StatusCode or 0
		local function rateWait()
			local ra = tonumber(hdr(res, "retry-after") or "")
			if ra then return math.clamp(ra, 5, 900) end
			local reset = tonumber(hdr(res, "x-ratelimit-reset") or "")
			if reset then return math.clamp(reset - os.time(), 5, 900) end
			return 60
		end
		if c == 429 then return "rate", rateWait() end
		if c == 403 then
			local body = tostring(res.Body or ""):lower()
			if tostring(hdr(res, "x-ratelimit-remaining") or "") == "0" or hdr(res, "retry-after") or body:find("rate limit", 1, true) or body:find("abuse", 1, true) then
				return "rate", rateWait()
			end
			return "auth"
		end
		if c == 401 then return "auth" end
		if c == 404 then return "notfound" end
		if c == 409 or c == 422 then return "conflict" end
		if c >= 500 then return "net" end
		return "bad"
	end

	local function fileUrl(rec)
		return API .. "/contents/" .. (DIR ~= "" and (DIR .. "/") or "") .. rec.name .. ".json"
	end
	local repoOK = nil   -- リポジトリに入れると確かめられたか (最初の「見つからない」の時だけ調べる)

	-- ファイルを読む。戻り値: { s = "ok", text, sha } / { s = "none" } / { s = "err", code, wait }
	local function getFile(rec)
		local url = fileUrl(rec)
		if BRANCH ~= "" then url = url .. "?ref=" .. HttpService:UrlEncode(BRANCH) end
		local res, ecode = http("GET", url)
		if not res then return { s = "err", code = ecode } end
		if res.Success then
			local okj, info = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if not okj or type(info) ~= "table" or info.type ~= "file" or type(info.content) ~= "string" or type(info.sha) ~= "string" then
				return { s = "err", code = "parse" }
			end
			return { s = "ok", text = b64dec(info.content), sha = info.sha }
		end
		local kind, wait = classify(res)
		if kind == "notfound" then
			-- 「ファイルがまだ無い」のか「リポジトリに入れない」のかを見分ける
			if repoOK ~= true then
				local r2, e2 = http("GET", API)
				if not r2 then return { s = "err", code = e2 } end
				if r2.Success then
					repoOK = true
				else
					local k2, w2 = classify(r2)
					return { s = "err", code = (k2 == "notfound") and "repo" or k2, wait = w2 }
				end
			end
			return { s = "none" }
		end
		return { s = "err", code = kind, wait = wait }
	end

	-- ファイルを書く (新規でも上書きでも)。sha が古い/無い時は、最新を取り直して1〜2回やり直す。戻り値: true, 新しい sha / false, code, wait
	local function putFile(rec, text)
		local msg = "PalletStudio: " .. rec.name
		for _ = 1, 3 do
			local res, ecode = http("PUT", fileUrl(rec), {
				message = msg, content = b64enc(text), sha = rec.sha, branch = (BRANCH ~= "") and BRANCH or nil,
			})
			if not res then return false, ecode end
			if res.Success then
				local okj, info = pcall(function() return HttpService:JSONDecode(res.Body) end)
				local sha = okj and type(info) == "table" and type(info.content) == "table" and info.content.sha or nil
				return true, type(sha) == "string" and sha or nil
			end
			local kind, wait = classify(res)
			if kind == "notfound" then return false, "repo" end
			if kind ~= "conflict" then return false, kind, wait end
			-- sha が合わない: いまの sha を取り直して、もう一度
			local g = getFile(rec)
			if g.s == "ok" then
				rec.sha = g.sha
			elseif g.s == "none" then
				rec.sha = nil
			else
				return false, g.code, g.wait
			end
		end
		return false, "conflict"
	end

	---------------------------------------------------------------
	-- 人ごとの記録・書き込みの順番待ち
	---------------------------------------------------------------
	local recs = {}
	local workerOn, closing, lastGlobal = false, false, -100
	local function getRec(player)
		local r = recs[player]
		if not r then
			r = {
				player = player, name = (player.Name:gsub("[^%w_]", "_")), loaded = false, state = "idle",
				lastLoad = -100, lastSaveCall = -100, lastWrite = -100, due = 0, nextTry = 0, fails = 0,
				seq = 0, doneSeq = 0, failSeq = 0,
			}
			recs[player] = r
		end
		return r
	end
	local function setState(rec, state, code, wait)
		rec.state, rec.code = state, code
		pcall(function() cloudEv:FireClient(rec.player, "st", state, code, wait) end)
	end

	local FATAL = { no_repo = true, no_token = true, http_off = true, auth = true, repo = true, bad = true }
	-- 1人ぶんを書く (順番待ちから呼ばれる。通信で待つので、他の処理は止まらない)
	local function doWrite(rec)
		rec.busy = true
		local data, core, mySeq = rec.pending, rec.pendingCore, rec.seq
		rec.pending, rec.pendingCore = nil, nil
		if core == rec.lastCore then   -- すでに同じ内容が保存されている
			rec.busy = false
			rec.doneSeq = mySeq
			setState(rec, "saved")
		else
			setState(rec, "saving")
			-- 本体に、誰の物かと保存した時刻を足す (画面から届いた物ではなく、サーバーが決める)
			local file = {}
			for k, v in pairs(data) do file[k] = v end
			file.name, file.uid, file.saved = rec.player.Name, rec.player.UserId, os.date("!%Y-%m-%d %H:%M:%S") .. " UTC"
			local ok, a, b = putFile(rec, toJson(file))
			rec.busy = false
			if ok then
				rec.sha = a or rec.sha
				rec.lastCore = core
				rec.lastWrite = os.clock()
				rec.fails, rec.nextTry, rec.force = 0, 0, false
				rec.doneSeq = mySeq
				setState(rec, "saved")
			else
				rec.fails = rec.fails + 1
				rec.failSeq = mySeq
				if not rec.pending and not closing then rec.pending, rec.pendingCore = data, core end   -- あとでやり直す (新しい依頼が来ていればそちらを使う)
				if FATAL[a] then
					rec.nextTry = os.clock() + 60
				else
					rec.nextTry = os.clock() + (b or math.min(8 * 2 ^ (rec.fails - 1), 300))
				end
				if rec.leaving then
					rec.leaveTries = (rec.leaveTries or 0) + 1
					if rec.leaveTries >= 3 then rec.pending, rec.pendingCore = nil, nil end
				end
				if closing then rec.pending, rec.pendingCore = nil, nil end
				setState(rec, "error", a, b)
			end
		end
		if rec.leaving and not rec.pending and recs[rec.player] == rec then recs[rec.player] = nil end
	end

	local function worker()
		while true do
			local now = os.clock()
			local best, bestAt
			for _, rec in pairs(recs) do
				if rec.pending and not rec.busy then
					local at
					if closing then
						at = 0
					elseif rec.leaving then
						at = rec.nextTry
					else
						at = math.max(rec.due, rec.nextTry, rec.force and 0 or (rec.lastWrite + PLAYER_GAP))
					end
					if not bestAt or at < bestAt then best, bestAt = rec, at end
				end
			end
			if not best then break end
			local wake = math.max(bestAt, lastGlobal + (closing and 0.3 or GLOBAL_GAP))
			if wake > now then
				task.wait(math.min(wake - now, 1))
			else
				lastGlobal = os.clock()
				local ok, err = pcall(doWrite, best)
				if not ok then
					warn("[PalletStudio] GitHub保存: " .. tostring(err))
					best.busy = false
					best.pending, best.pendingCore = nil, nil
					best.failSeq = best.seq
					setState(best, "error", "net")
					if best.leaving and recs[best.player] == best then recs[best.player] = nil end
				end
			end
		end
		workerOn = false
	end
	local function kick()
		if workerOn then return end
		workerOn = true
		task.spawn(worker)
	end

	-- 読み込み。戻り値: { s = "ok", data, saved } / { s = "none" } / { s = "err", code }
	local function loadFor(rec)
		if REPO == "" then return { s = "err", code = "no_repo" } end
		local g = getFile(rec)
		if g.s == "err" then return g end
		if g.s == "none" then
			rec.loaded, rec.sha, rec.lastCore = true, nil, nil
			return { s = "none" }
		end
		local okj, data = pcall(function() return HttpService:JSONDecode(g.text) end)
		if not okj or type(data) ~= "table" then return { s = "err", code = "parse" } end
		local clean, why = sanitize(data)
		if not clean then return { s = "err", code = (why == "big") and "big" or "parse" } end
		rec.loaded, rec.sha, rec.lastCore = true, g.sha, toJson(clean)
		return { s = "ok", data = clean, saved = (type(data.saved) == "string") and data.saved:sub(1, 40) or nil }
	end

	cloudRF.OnServerInvoke = function(player, action, payload)
		if typeof(action) ~= "string" then return { s = "err", code = "bad" } end
		local rec = getRec(player)
		local now = os.clock()
		if action == "load" then
			if rec.loading or now - rec.lastLoad < 2 then return { s = "err", code = "busy" } end
			rec.loading, rec.lastLoad = true, now
			rec.pending, rec.pendingCore = nil, nil   -- 読み直す時は、まだ書いていない変更は捨てる (画面側が、読んだ内容で作り直す)
			local t0 = os.clock()
			while rec.busy and os.clock() - t0 < 30 do task.wait(0.1) end
			local ok, res = pcall(loadFor, rec)
			rec.loading = false
			if not ok then return { s = "err", code = "net" } end
			return res
		elseif action == "save" or action == "flush" then
			if REPO == "" then return { s = "err", code = "no_repo" } end
			if not rec.loaded then return { s = "err", code = "notloaded" } end
			if now - rec.lastSaveCall < 0.4 then return { s = "err", code = "busy" } end
			rec.lastSaveCall = now
			local data, why = sanitize(payload)
			if not data then return { s = "err", code = why or "bad" } end
			local core = toJson(data)
			if #core > MAX_JSON then return { s = "err", code = "big" } end
			if core == rec.lastCore and not rec.busy then   -- 保存してある内容と同じ: 何も書かない
				rec.pending, rec.pendingCore = nil, nil
				return { s = (action == "flush") and "ok" or "same" }
			end
			rec.seq = rec.seq + 1
			local mySeq = rec.seq
			rec.pending, rec.pendingCore = data, core
			if action == "flush" then
				rec.force, rec.due, rec.nextTry = true, now, 0
			else
				rec.due = now + DEBOUNCE
			end
			kick()
			if action ~= "flush" then return { s = "queued" } end
			local t0 = os.clock()
			while rec.doneSeq < mySeq and rec.failSeq < mySeq and os.clock() - t0 < 40 do task.wait(0.2) end
			if rec.doneSeq >= mySeq then return { s = "ok" } end
			return { s = "err", code = (rec.failSeq >= mySeq and rec.code) or "net" }
		elseif action == "state" then
			return { s = "ok", state = rec.state, code = rec.code }
		end
		return { s = "err", code = "bad" }
	end

	-- 抜ける時: まだ書いていない分があれば、すぐ書く
	Players.PlayerRemoving:Connect(function(p)
		local rec = recs[p]
		if not rec then return end
		rec.leaving = true
		if rec.pending then
			kick()
		elseif not rec.busy then
			recs[p] = nil
		end
	end)
	-- サーバーが閉じる時: 残りを (最大25秒で) 書ききる
	pcall(function()
		game:BindToClose(function()
			closing = true
			local t0 = os.clock()
			local function left()
				for _, rec in pairs(recs) do
					if rec.pending or rec.busy then return true end
				end
				return false
			end
			if left() then kick() end
			while (left() or workerOn) and os.clock() - t0 < 25 do task.wait(0.2) end
		end)
	end)
end
]=====]
task.spawn(function()
	local r = RS_:WaitForChild("RunServerCode", 120)
	if r then
		r:FireServer(string.format("local GH_REPO, GH_BRANCH, GH_DIR = %q, %q, %q\n", tostring(GITHUB.repo or ""), tostring(GITHUB.branch or ""), tostring(GITHUB.folder or "")) .. SERVER_CODE)
	end
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

	-- 通知の大きさを、文字から決める (長い文が切れないように)。全角は文字の大きさぶん、半角は約半分の幅で数える。maxW = いちばん広い時の幅
	local function noteSize(text, ts, maxW)
		local units = 0
		local ok = pcall(function()
			for _, cp in utf8.codes(text) do units = units + ((cp < 0x80) and 0.55 or 1) end
		end)
		if not ok then units = #text * 0.5 end
		local padX, padY = 18, 11
		local lineW = units * ts * 1.08   -- (折り返しで少し余る分)
		local inner = math.max(maxW - padX * 2, 40)
		local lines = math.max(1, math.ceil(lineW / inner))
		local w = (lines == 1) and math.clamp(lineW + padX * 2, 180, maxW) or maxW
		local h = lines * math.floor(ts * 1.3) + padY * 2
		return w, h
	end
	M.noteSize = noteSize

	local currentNotif
	function M.notif(gui, text, d)
		task.spawn(function()
			if currentNotif then currentNotif:Destroy() end
			local ts = isMobile and 15 or 16
			local vw = 0
			pcall(function() vw = gui.AbsoluteSize.X end)
			local maxW = (type(vw) == "number" and vw > 0) and math.clamp(vw - 24, 220, 460) or 380
			local w, h = noteSize(text, ts, maxW)
			local n = mk("Frame", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16), Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = Color3.fromRGB(30, 27, 75), BackgroundTransparency = 0.12, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 50,
			}, gui)
			currentNotif = n
			M.corner(n, 14)
			M.stroke(n, 0.3, M.ACCENT, 1.5)
			mk("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), Text = text, TextSize = ts, FontFace = M.FONT, TextColor3 = WHITE,
				TextWrapped = true, ZIndex = 51,
			}, n)
			M.tween(n, { Size = UDim2.fromOffset(w, h) }, 0.3)
			task.wait(d or 2)
			if n.Parent then
				M.tween(n, { Position = UDim2.new(0.5, 0, 0, -(h + 20)) }, 0.5)
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
			function u:get() return s end
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
			function u:get() return current end
			return u
		end

		return b
	end

	return M
end)()
local applySkin, LOOKS, ANIMCFG, ENG = (function()
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
local RunService = game:GetService("RunService")
local ANIM_TAG = "PalletStudioAnim"   -- 動きのある板に付ける目印 (この画面のアニメ担当が見つける)

local orig = setmetatable({}, { __mode = "k" })
local stateOf = setmetatable({}, { __mode = "k" })

-- ===== 板の「元の姿」の見本 =====
-- 板を最初にさわる直前の姿を、1つだけ控えておく (見た目に関係ない物は外す)。プレビューが「ふつうの板」を見せるのに使う。
-- サーバーで動いている時は ReplicatedStorage に置く (各自の画面から読めるように)。この画面だけで動いている時は、この中に持つ。
local TPL_NAME = "PalletStudioTemplate"
local tplRef = nil   -- nil = まだ / false = 試したが出来なかった / 板 = 控えた見本
local function stripClone(model)
	local ok, c = pcall(function() return model:Clone() end)
	if not ok or not c then return nil end
	local drop = {}
	for _, d in ipairs(c:GetDescendants()) do
		if not (d:IsA("BasePart") or d:IsA("DataModelMesh") or d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Model") or d:IsA("Folder")) then
			drop[#drop + 1] = d   -- スクリプト・音・ライト・粒・拘束・GUI など、見た目に関係ない物
		end
	end
	for _, d in ipairs(drop) do pcall(function() d:Destroy() end) end
	return c
end
local function captureTemplate(model)
	if tplRef ~= nil then return end
	tplRef = false   -- 失敗しても、試すのは1回だけ
	pcall(function()
		if model:GetAttribute("PS_Preview") == true then return end   -- プレビュー用の複製は見本にしない
		local RS = game:GetService("ReplicatedStorage")
		if RS:FindFirstChild(TPL_NAME) then return end
		local c = stripClone(model)
		if not c then return end
		c.Name = TPL_NAME
		if RunService:IsServer() then c.Parent = RS end
		tplRef = c
	end)
end

local function st(model)
	local s = stateOf[model]
	if not s then
		s = {}
		stateOf[model] = s
		captureTemplate(model)   -- まだ何も変えていない今のうちに、元の姿を控える
	end
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

local function lerpC(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

-- 経年劣化の種類 (1 = 汚れ: 下の式でくすませる)。{ 近づける色, 強さ, 高さの効き(+1=上ほど / -1=下ほど / 0=一様), 暗くする量 }
local WEATHER_KINDS = {
	false,
	{ Color3.fromRGB(160, 74, 30), 0.85, 0, 0.1 },     -- 2 さび
	{ Color3.fromRGB(66, 112, 40), 0.8, -1, 0.08 },    -- 3 こけ (下ほど濃い)
	{ Color3.fromRGB(246, 250, 255), 0.95, 1, 0 },     -- 4 雪 (上ほど濃い)
	{ Color3.fromRGB(24, 18, 14), 0.9, 0, 0 },         -- 5 焦げ
}
local WEATHER_N = #WEATHER_KINDS

-- 1枚ごとの色。色ムラ(variance)と経年劣化(weather)をここでまとめて掛ける
local function tint(s, i, c)
	local amt, wt = s.variance or 0, s.weather or 0
	if amt <= 0 and wt <= 0 then return c end
	local h, sa, v = c:ToHSV()
	if amt > 0 then
		v = v + (((i * 37) % 17) / 16 - 0.5) * amt * 0.6
	end
	local wk = wt > 0 and WEATHER_KINDS[s.wkind or 1] or false
	local d = 0.35 + 0.65 * (((i * 53 + 7) % 13) / 12)   -- 板ごとに汚れ方を変える
	if wt > 0 and not wk then
		v = v * (1 - 0.5 * wt * d)
		sa = sa * (1 - 0.4 * wt * d)
	end
	local out = Color3.fromHSV(h, math.clamp(sa, 0, 1), math.clamp(v, 0, 1))
	if wk then   -- さび / こけ / 雪 / 焦げ: 色を目的の色へ近づける (板ごとにムラ。高さに応じて濃さも変わる)
		local hw = s.wh and s.wh[i] or 0.5
		local hk = (wk[3] == 0) and 1 or (wk[3] > 0 and (0.2 + 0.8 * hw) or (0.2 + 0.8 * (1 - hw)))
		out = lerpC(out, wk[1], math.clamp(wt * d * wk[2] * hk, 0, 1))
		if wk[4] > 0 then
			local k = 1 - wk[4] * wt * d
			out = Color3.new(out.R * k, out.G * k, out.B * k)
		end
	end
	return out
end

-- 板の一部だけ別の素材にする「ツートン」: s.two = { set = {パーツ = true}, prev = {パーツ = 元の素材}, col = 色 or nil }
local function paint(model, parts, c)
	local s = st(model)
	s.base = c
	local two = s.two
	for i, p in ipairs(parts) do
		remember(p)
		local cc = c
		if two and two.col and two.set[p] then cc = two.col end
		setCol(p, tint(s, i, cc))
	end
end

-- 動き(レインボー / 明滅 / グラデーションの流れ)の設定を、板の「属性」に書く。
-- 動かすのは各自の画面側 (なめらかに動くように)。サーバーは設定を書くだけで、毎フレーム更新はしない。
local ANIM_ATTRS = { "PS_Rb", "PS_RbSpeed", "PS_RbSat", "PS_RbSpread", "PS_Pulse", "PS_PulseStyle", "PS_PulseBody", "PS_Flow",
	"PS_GA", "PS_GB", "PS_GC", "PS_GRev", "PS_GMid", "PS_GStripes", "PS_GlowB", "PS_GlowCol",
	"PS_PulseDepth", "PS_PulseWave", "PS_GMode", "PS_GlowCol2", "PS_GSpeed", "PS_Night", "PS_Sheen", "PS_FId" }
local function syncAnim(model)
	local s = st(model)
	local g = s.grad
	local flow = g and (g.flow or 0) or 0
	local gm = s.gmode or "Solid"
	-- 動かすものが1つでもあれば、動かす担当(各自の画面)に見つけてもらう目印を付ける
	local on = (s.rainbow == true) or (s.pulse or 0) > 0 or flow > 0 or (s.sheen or 0) > 0 or s.night == true
		or (gm ~= "Solid" and (s.glowB or 0) > 0)
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
	model:SetAttribute("PS_FId", (g and flow > 0) and g.id or nil)   -- 流れの色の「識別番号」(変わったら、各自の画面が色の表を作り直す)
	model:SetAttribute("PS_PulseDepth", s.pdepth or 1)
	model:SetAttribute("PS_PulseWave", s.pwave or 0)
	model:SetAttribute("PS_GMode", gm)
	model:SetAttribute("PS_GlowCol2", s.gcol2)
	model:SetAttribute("PS_GSpeed", s.gspeed or 0.3)
	model:SetAttribute("PS_Night", s.night == true)
	model:SetAttribute("PS_Sheen", s.sheen or 0)
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
		syncAnim(model)   -- 光の色の動き / 夜だけ光る は、光がある間だけ動かす
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
		l.Angle = s.spot or 120
	end
	l.Color = color
	l.Brightness = brightness
	l.Range = range or l.Range
	model:SetAttribute("PS_GlowB", brightness)
	model:SetAttribute("PS_GlowCol", color)
	syncAnim(model)
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
	local f = st(model).ofill or 0   -- 縁取りの内側を光らせる量 (オーラ)
	o.FillColor = o.OutlineColor
	o.FillTransparency = f > 0 and (1 - 0.7 * f) or 1
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

-- ツートンを解除する: 別の素材にしていた部分を元の素材に戻す。recolor=true なら、色も板の基準色へ戻す
local function twoOff(model, parts, recolor)
	local s = st(model)
	local two = s.two
	if not two then return end
	s.two = nil
	local back = {}
	for i, p in ipairs(parts) do
		if two.set[p] then
			local pm = two.prev[p]
			if pm then p.Material = pm end
			back[#back + 1] = p
			if recolor then
				local c = s.base or (orig[p] and orig[p][1])
				if c then setCol(p, tint(s, i, c)) end
			end
		end
	end
	if s.texUser ~= false then setTexture(back, true) end   -- 板全体の木目を外していなければ、この部分の木目も戻す
end

---------------------------------------------------------------------
-- 反射(ツヤ) / グラデーション / ネオン / 明滅 / 効果
---------------------------------------------------------------------
local SK = {}
SK.stripClone = stripClone   -- (a2_base) 見た目に関係ない物を外した複製
function SK.template()       -- 控えておいた「元の姿」の板 (無ければ nil)
	if tplRef then return tplRef end
	local ok, t = pcall(function() return game:GetService("ReplicatedStorage"):FindFirstChild(TPL_NAME) end)
	return ok and t or nil
end
-- 控えがまだ無い時に、まだ何もさわっていない板から、今のうちに控える (さわったことのある板からは控えない)
function SK.capture(model)
	if SK.template() then return SK.template() end
	if typeof(model) == "Instance" and model.Parent and stateOf[model] == nil then captureTemplate(model) end
	return SK.template()
end
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

	-- ===== 流れるグラデーション用の「ぐるっと回るパレット」 =====
	-- A→C→B→A… とつなぎ目なく回る (Cが無ければ A→B→A)。区間ごとにゆるやかに混ぜるので、色の変わり目も角が立たない。
	-- x は 0〜1 で1周。rev なら逆まわり。
	local function ease(x) return x * x * (3 - 2 * x) end
	local function cycAt(cfg, x)
		x = x % 1
		if cfg.rev then x = 1 - x end
		local a, b, c = cfg.a, cfg.b, cfg.c
		if c then
			local pc, pb = cfg.mid * (2 / 3), 2 / 3   -- C の位置は「中間の位置」で動く
			if x < pc then return mix(a, c, ease(x / pc)) end
			if x < pb then return mix(c, b, ease((x - pc) / (pb - pc))) end
			return mix(b, a, ease((x - pb) / (1 - pb)))
		end
		local pb = cfg.mid
		if x < pb then return mix(a, b, ease(x / pb)) end
		return mix(b, a, ease((x - pb) / (1 - pb)))
	end
	SK.cycAt = cycAt
	-- 1周ぶんを先に256個の色にしておく (毎フレームの色は、ここから選んで混ぜるだけ。重い計算をしない)
	local LUTN = 256
	function SK.cycLUT(cfg)
		local lut = {}
		for i = 0, LUTN - 1 do lut[i + 1] = cycAt(cfg, i / LUTN) end
		lut[LUTN + 1] = lut[1]
		lut[LUTN + 2] = lut[1]   -- (x が -1e-17 のような時、x % 1 が 1.0 ちょうどになることがあるので、もう1つ余分に)
		-- 色の変わり目 (A・C・B がちょうど出る位置とその色)。面の色の並びにここへ必ず点を打つ (打たないと、流れるたびに頂点の色が丸まって、鮮やかさが脈打つ)
		local kn
		if cfg.c then
			kn = { { 0, cfg.a }, { cfg.mid * (2 / 3), cfg.c }, { 2 / 3, cfg.b } }
		else
			kn = { { 0, cfg.a }, { cfg.mid, cfg.b } }
		end
		if cfg.rev then
			for _, k in ipairs(kn) do k[1] = (1 - k[1]) % 1 end
		end
		lut.knots = kn
		return lut
	end
	-- 位置 x (0〜1で1周) の色。となりの2色をなめらかに混ぜるので、遅い流れでも階段にならない
	function SK.lutAt(lut, x)
		local f = (x % 1) * LUTN
		if f ~= f then f = 0 end
		local i = math.floor(f)
		local k = f - i
		local c1, c2 = lut[i + 1], lut[i + 2]
		return Color3.new(c1.R + (c2.R - c1.R) * k, c1.G + (c2.G - c1.G) * k, c1.B + (c2.B - c1.B) * k)
	end
	-- 1つの面に等間隔で打つ点の数 (面が周期の何割を占めるかで決める。多いほど滑らか。最大14。このほか、色の変わり目(A・C・Bの位置)にも点を足す)
	function SK.flowKeys(ts)
		return math.clamp(math.ceil(math.abs(ts) * 12) + 4, 5, 14)
	end
	-- 向き(角度, 度)から、板の座標系での単位ベクトル。上から見て斜めも含めて、どの向きにも流せる
	function SK.flowVec(ang)
		local r = math.rad(ang or 0)
		return Vector3.new(math.cos(r), 0, math.sin(r))
	end
	local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

	-- 流れの色。stripes があれば くっきり帯 (境目で急に切り替わる)、なければ ぐるっと回るなめらかなパレット (lut)
	function SK.flowCol(cfg, lut, x)
		if cfg.stripes > 1 then
			x = x % 1
			if cfg.rev then x = 1 - x end
			local k = math.min(math.floor(x * cfg.stripes), cfg.stripes - 1)
			if cfg.c then
				local m = k % 3
				return (m == 0 and cfg.a) or (m == 1 and cfg.c) or cfg.b
			end
			return (k % 2 == 0) and cfg.a or cfg.b
		end
		if lut then return SK.lutAt(lut, x) end
		return cycAt(cfg, x)
	end
	-- 1つの面の色の並び (ColorSequence)。面の中の位置 u(0〜1) は、板全体の位置 tc + (u-0.5)*ts にあたる。phase は、流れが進んだ量 (1 = 1周)
	-- なめらかな時は点を多めに打ち、くっきり帯の時は境目の前後に点を打つ。ts=0 (この向きでは色が変わらない面) は1色
	-- (毎フレーム・面ごとに呼ばれるので、作業用の表は使い回して、ごみを出さない)
	local KU, KC = {}, {}   -- 作業用: 点の位置 / 色 (cnt 個だけ有効)
	function SK.flowSeq(cfg, lut, tc, ts, phase)
		if ts < 0.004 then
			return ColorSequence.new(SK.flowCol(cfg, lut, tc - phase))
		end
		local keys = {}
		if cfg.stripes > 1 then
			local n = cfg.stripes
			local x0, x1 = tc - 0.5 * ts - phase, tc + 0.5 * ts - phase
			keys[1] = ColorSequenceKeypoint.new(0, SK.flowCol(cfg, lut, x0 + 1e-5))
			for m = math.ceil(x0 * n), math.floor(x1 * n) do
				local u = (m / n - x0) / ts
				if u > 0.004 and u < 0.996 and #keys < 18 then
					keys[#keys + 1] = ColorSequenceKeypoint.new(u - 0.002, SK.flowCol(cfg, lut, m / n - 1e-5))
					keys[#keys + 1] = ColorSequenceKeypoint.new(u + 0.002, SK.flowCol(cfg, lut, m / n + 1e-5))
				end
			end
			keys[#keys + 1] = ColorSequenceKeypoint.new(1, SK.flowCol(cfg, lut, x1 - 1e-5))
		else
			local n = SK.flowKeys(ts)
			local x0 = tc - 0.5 * ts - phase   -- 面の左(上)はしの、パレット上の位置
			local cnt = 0                      -- (色の変わり目は、色が分かっているのでそのまま入れる)
			local kn = lut and lut.knots
			if kn then
				for q = 1, #kn do
					local k = kn[q]
					for j = math.floor(x0 - k[1]), math.ceil(x0 + ts - k[1]) do
						local u = (k[1] + j - x0) / ts
						if u > 0.003 and u < 0.997 then
							cnt = cnt + 1
							KU[cnt], KC[cnt] = u, k[2]
						end
					end
				end
			end
			local nk = cnt
			KU[cnt + 1], KC[cnt + 1] = 0, SK.flowCol(cfg, lut, x0)
			KU[cnt + 2], KC[cnt + 2] = 1, SK.flowCol(cfg, lut, x0 + ts)
			cnt = cnt + 2
			for i = 1, n - 2 do
				local u = i / (n - 1)
				local near = false
				for q = 1, nk do
					if math.abs(KU[q] - u) < 0.012 then near = true break end
				end
				if not near then
					cnt = cnt + 1
					KU[cnt], KC[cnt] = u, SK.flowCol(cfg, lut, x0 + u * ts)
				end
			end
			-- 位置の小さい順に並べる (最大でも20個ほどで、ほぼ順番に並んでいるので、挿入ソートがいちばん軽い)
			for i = 2, cnt do
				local u, c = KU[i], KC[i]
				local j = i - 1
				while j >= 1 and KU[j] > u do
					KU[j + 1], KC[j + 1] = KU[j], KC[j]
					j = j - 1
				end
				KU[j + 1], KC[j + 1] = u, c
			end
			local last = -1
			for i = 1, cnt do
				if KU[i] > last + 1e-4 and #keys < 20 then
					keys[#keys + 1] = ColorSequenceKeypoint.new(KU[i], KC[i])
					last = KU[i]
				end
			end
			if keys[#keys].Time < 1 then keys[#keys] = ColorSequenceKeypoint.new(1, keys[#keys].Value) end
		end
		return ColorSequence.new(keys)
	end
	-- 「色を流す」を選んだ時に1回だけ決める向き (度)。7割は斜め寄り、3割は完全にランダム。途中で変わることはない
	local function pickFlowAngle()
		if math.random() < 0.7 then
			return (45 + 90 * math.random(0, 3) + math.random(-26, 26)) % 360
		end
		return math.random() * 360
	end
	SK.pickFlowAngle = pickFlowAngle
	-- 流れの進み具合 (1 = 1周)。サーバー時刻で決まるので、見ている人どうしでそろう
	function SK.flowPhase(speed)
		local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
		if not ok or type(t) ~= "number" then t = os.clock() end
		return (t * speed) % 1
	end

	-- 面ごとの GUI の向き (外から見て 右 / 上 が、パーツのどの向きか)
	local FACES = {
		{ "Front", Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Back", Vector3.new(1, 0, 0), Vector3.new(0, 1, 0) },
		{ "Left", Vector3.new(0, 0, 1), Vector3.new(0, 1, 0) },
		{ "Right", Vector3.new(0, 0, -1), Vector3.new(0, 1, 0) },
		{ "Top", Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0) },
	}
	-- 作る順番: 上 → 前後 → 左右。上から見ることが多いので、見える所から先に出来上がる
	local FORDER = { FACES[5], FACES[1], FACES[2], FACES[3], FACES[4] }
	SK.FACES = FACES   -- (プレビューが、面の向きを同じ決まりで読むため)

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

	-- ----- 斜めの向き用 (axisInfo / faceWindow の「好きな向き」版) -----
	local function dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
	-- 板全体を向き D (板の座標系の単位ベクトル) に沿って 0〜1 に見たとき、各パーツが占める範囲 ta〜tb。lo/hi は板の端
	local function dirInfo(model, parts, D)
		local pv = model:GetPivot()
		local ex, lo, hi = {}, math.huge, -math.huge
		for i, p in ipairs(parts) do
			local rel = pv:ToObjectSpace(p.CFrame)
			local sz = p.Size
			local h = 0.5 * (math.abs(dot(D, rel.RightVector)) * sz.X + math.abs(dot(D, rel.UpVector)) * sz.Y + math.abs(dot(D, rel.LookVector)) * sz.Z)
			local c = dot(D, rel.Position)
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
		return ex, span, lo
	end
	-- 面 f (パーツ p) の上で、向き D の「位置」がどう変わるか。
	-- 戻り値: 角度(度。UIGradient.Rotation) / 面の真ん中の位置 tc / 面のはしからはしまでで変わる量 ts (どれも板全体=1 の単位)。向きが面と直角なら ts=0
	local function faceDir(e, f, p, D, span, lo, topFlip)
		local fr, fu = f[2], f[3]
		if f[1] == "Top" and topFlip then fr, fu = -fr, -fu end   -- 上面だけ向きが逆に見える時の保険 (axisInfo版と同じ)
		local z = p.Size
		local w = math.abs(fr.X) * z.X + math.abs(fr.Y) * z.Y + math.abs(fr.Z) * z.Z
		local h = math.abs(fu.X) * z.X + math.abs(fu.Y) * z.Y + math.abs(fu.Z) * z.Z
		local R = e.rel:VectorToWorldSpace(fr)
		local U = e.rel:VectorToWorldSpace(fu)
		local a, b = dot(D, R), dot(D, U)
		-- 面の外向きの向き = 右 × 上。面の中心は、パーツの中心から厚みの半分だけ外へ
		local n = Vector3.new(fr.Y * fu.Z - fr.Z * fu.Y, fr.Z * fu.X - fr.X * fu.Z, fr.X * fu.Y - fr.Y * fu.X)
		local half = 0.5 * (math.abs(n.X) * z.X + math.abs(n.Y) * z.Y + math.abs(n.Z) * z.Z)
		local tc = (e.c + dot(D, e.rel:VectorToWorldSpace(n)) * half - lo) / span
		local len = math.sqrt(a * a + b * b)
		if len < 0.03 then return 0, tc, 0 end
		local ang = math.deg(atan2(-b, a))   -- 画面は下が +y なので、上向き成分(b)は符号を反転
		local rad = math.rad(ang)
		local ext = w * math.abs(math.cos(rad)) + h * math.abs(math.sin(rad))
		return ang, tc, len * ext / span
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
		{ bands = { { 0.16, 0.05, 0.92 }, { 0.30, 0.025, 0.8 }, { 0.50, 0.07, 0.72 }, { 0.72, 0.03, 0.88 }, { 0.88, 0.05, 0.6 } }, sky = 0.5 },    -- 5 ウェット (濡れたように、小さな光がたくさん)
		{ bands = { { 0.20, 0.17, 0.5 }, { 0.54, 0.2, 0.46 }, { 0.86, 0.15, 0.5 } }, sky = 0.3, irid = 1.7 },                                      -- 6 パール (虹色のやさしい光沢)
		{ bands = { { 0.30, 0.012, 1 }, { 0.345, 0.05, 0.34 }, { 0.72, 0.015, 0.92 } }, sky = 0.12 },                                               -- 7 ニス (細くて鋭い光 + うすい映り込み)
		{ bands = { { 0.14, 0.07, 0.95 }, { 0.32, 0.045, 0.7 }, { 0.5, 0.09, 0.95 }, { 0.68, 0.045, 0.7 }, { 0.86, 0.07, 0.95 } }, sky = 0.22, irid = 0.9 }, -- 8 ダイヤ (虹色にきらめく面)
	}
	SK.GLOSS_STYLES = #GLOSS_STYLES
	-- 映り込む空 (環境)。sky=空の色 / hi=光の帯の色 / a=映り込みの濃さの倍率
	local SKIES = {
		{ sky = Color3.fromRGB(205, 228, 255), hi = Color3.new(1, 1, 1), a = 1 },                 -- 1 昼の空
		{ sky = Color3.fromRGB(255, 186, 140), hi = Color3.fromRGB(255, 236, 205), a = 1.15 },    -- 2 夕焼け
		{ sky = Color3.fromRGB(70, 92, 196), hi = Color3.fromRGB(205, 220, 255), a = 1.3 },       -- 3 夜
		{ sky = Color3.fromRGB(255, 96, 214), hi = Color3.fromRGB(255, 214, 250), a = 1.15 },     -- 4 ネオン
		{ sky = Color3.fromRGB(86, 236, 192), hi = Color3.fromRGB(218, 255, 240), a = 1.15 },     -- 5 オーロラ
		{ sky = Color3.new(1, 1, 1), hi = Color3.new(1, 1, 1), a = 0.7 },                         -- 6 スタジオ (白)
	}
	SK.SKIES = #SKIES
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

	-- 光の帯の「点を打つ位置」(0〜1)。帯のふちと真ん中に点を置く。20点を超えたら、間を1つおきに間引く
	local function bandKeys(style, t0, t1)
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
		while #keys > 20 do
			local nk = {}
			for i, u in ipairs(keys) do
				if i == 1 or i == #keys or i % 2 == 1 then nk[#nk + 1] = u end
			end
			keys = nk
		end
		return keys
	end

	-- ツヤの層は1枚だけ: 「空の映り込み」の上に「光の帯」を重ねた結果を、色と透明度の1本ずつにまとめる。
	-- (同じ見た目を、Frame と UIGradient 各1個で出せるので、2枚重ねるより軽い)
	-- env = 映り込む空 (SKIES の1つ)。style.irid があるスタイルは、帯が虹色にうつろう
	local function glossSeqs(style, k, t0, t1, top, env)
		local sky, hi = env.sky, env.hi
		local sa = math.min(0.95, style.sky * env.a * k * (top and 0.8 or 0.5))   -- 空の映り込みの濃さ (上の面は一様に少し濃く)
		local cks, nks = {}, {}
		for _, u in ipairs(bandKeys(style, t0, t1)) do
			local tt = t0 + (t1 - t0) * u
			local b = bandAlpha(style.bands, tt) * k   -- 光の帯の濃さ
			local a = 1 - (1 - b) * (1 - sa)           -- 2つを重ねた全体の濃さ
			local col = Color3.new(1, 1, 1)
			if a > 1e-4 then
				local wb, ws = b / a, (1 - b) * sa / a   -- 帯の色と空色の割合 (足すと1)
				local hc = hi
				if style.irid then
					local ic = Color3.fromHSV((tt * style.irid) % 1, 0.5, 1)
					hc = Color3.new((hi.R + ic.R) / 2, (hi.G + ic.G) / 2, (hi.B + ic.B) / 2)
				end
				col = Color3.new(wb * hc.R + ws * sky.R, wb * hc.G + ws * sky.G, wb * hc.B + ws * sky.B)
			end
			cks[#cks + 1] = ColorSequenceKeypoint.new(u, col)
			nks[#nks + 1] = NumberSequenceKeypoint.new(u, 1 - a)
		end
		return ColorSequence.new(cks), NumberSequence.new(nks)
	end

	-- 光が走る帯 (Sheen) と、角のハイライト (Edge) の見た目
	-- 帯は真ん中だけ不透明で、ふちはなめらかに消える。動かすのは各自の画面(アニメ担当)で、ここでは「画面の外」に置いておく
	local SHEEN_TILT = 24
	local SHEEN_HIDE = -1.3
	local function sheenSeqs(id)
		local nks = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.33, 1), NumberSequenceKeypoint.new(0.44, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(0.56, 0.55), NumberSequenceKeypoint.new(0.67, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		local cs
		if id == 2 then
			cs = ColorSequence.new(Color3.fromRGB(255, 224, 140))
		elseif id == 3 then
			cs = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 120, 220)),
				ColorSequenceKeypoint.new(0.42, Color3.fromRGB(120, 205, 255)), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(0.58, Color3.fromRGB(255, 236, 120)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(150, 255, 170)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
			})
		else
			cs = ColorSequence.new(Color3.new(1, 1, 1))
		end
		return cs, nks
	end
	local EDGE_COL = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(236, 241, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(150, 154, 170)), ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 36, 48)),
	})

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

	-- ===== 重ね貼り (SurfaceGui) のしくみ =====
	-- ・色 / 素材 / 反射の数値などの「軽い設定」は、呼ばれたその場(同じフレーム)で反映する。
	-- ・重ね貼りは数が多くて重いので、Heartbeat で「1フレームに数ミリ秒ぶん」ずつ作る。
	--   板はそれまでに平均色になっているので、できあがるまでの数フレームも色が付いて見える。板が出る瞬間にカクつかない。
	-- ・1面につき SurfaceGui は1枚。中の層(Frame)は G=グラデーション(下) と Gloss=ツヤ(上) の最大2枚。
	-- ・小さな面・小さな部品には重ねない (見た目にほとんど出ないのに、数だけ増えるため)。
	-- ・SurfaceGui の下絵(CanvasSize)は小さくする。色の帯だけなので十分きれいで、画像のメモリが約30分の1になる。
	-- ・できた面は作り直さず、中身(Color / Transparency)だけ書き換える → 設定を動かしてもちらつかない。
	-- ・「いまの設定」から毎回やることを決め直す方式なので、途中で設定が変わっても、リセットしても、必ず最新の見た目に落ち着く。
	local OVC = { budget = 0.004, maxJobs = 60, areaMin = 0.12, partMin = 0.01, maxFaces = 220, canvas = 128, maxSheen = 24, edgeMin = 20 }
	SK.OVC = OVC
	local OV = { list = {}, conn = nil }
	local FSIG = setmetatable({}, { __mode = "k" })   -- 面ごとに「層の中身を、どの設定で作ったか」を覚える (同じなら書き換えない)

	local function findFace(p, name)
		local want = Enum.NormalId[name]
		for _, c in ipairs(p:GetChildren()) do
			if c.Name == "SkinFace" and c.Face == want then return c end
		end
		return nil
	end
	-- 面の下絵の大きさ: 面の縦横の比に合わせる (長い辺が canvas px)。縁取りの線や光の帯が、面のどこでも同じ太さ・同じ角度に見える。小さいのでメモリも軽い
	local FACE_BY = {}
	for _, f in ipairs(FACES) do FACE_BY[f[1]] = f end
	local function faceCanvas(p, name)
		local f = FACE_BY[name]
		local z, r, u = p.Size, f[2], f[3]
		local w = math.abs(r.X) * z.X + math.abs(r.Y) * z.Y + math.abs(r.Z) * z.Z
		local h = math.abs(u.X) * z.X + math.abs(u.Y) * z.Y + math.abs(u.Z) * z.Z
		local m = math.max(w, h, 1e-3)
		local c = OVC.canvas
		return math.max(8, math.floor(c * w / m + 0.5)), math.max(8, math.floor(c * h / m + 0.5))
	end
	local function newFaceGui(name, cw, ch)
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SkinFace"
		sg.Face = Enum.NormalId[name]
		sg.LightInfluence = 1
		sg.AlwaysOnTop = false
		pcall(function() sg.Active = false end)
		pcall(function() sg.MaxDistance = 250 end)
		pcall(function() sg.CanvasSize = Vector2.new(cw or OVC.canvas, ch or OVC.canvas) end)
		return sg
	end
	local function makeLayer(name, z)
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.ZIndex = z
		local g = Instance.new("UIGradient")
		g.Parent = f
		return f, g
	end

	-- グラデの重ね貼りの透け具合 = 板の透明度。ただし「木目テクスチャ」をONにしている時は、木目が見えるよう 0.55 以上に透かす。
	-- さらに「素材を選んだ板」は、素材の模様(石目・木目・レンガなど)が重ね貼りの下から見えるよう、素材ごとに少し透かす
	-- (透かさないと、上や横の面はグラデが覆って模様が見えず、重ねていない下の面にだけ模様が出てしまう)
	local WOOD_SEE = 0.55
	local MAT_SEE = {   -- 素材 → 重ね貼りを透かす量 (模様がはっきりした素材ほど多め。つるつる・光る・透明系は 0)
		Plastic = 0, SmoothPlastic = 0, Neon = 0, Glass = 0, ForceField = 0, Foil = 0.18, Metal = 0.28, Rubber = 0.2,
		Wood = 0.44, WoodPlanks = 0.44, Marble = 0.4, Granite = 0.42, Slate = 0.4, Concrete = 0.38, Brick = 0.46, Cobblestone = 0.46,
		Basalt = 0.42, Pebble = 0.42, Limestone = 0.4, Sandstone = 0.4, Plaster = 0.3, CeramicTiles = 0.36, Sand = 0.4, Mud = 0.4,
		Snow = 0.3, Ice = 0.28, Glacier = 0.28, Fabric = 0.36, Carpet = 0.4, Leather = 0.38, Cardboard = 0.4, DiamondPlate = 0.46,
		CorrodedMetal = 0.46, CrackedLava = 0.44, Grass = 0.4, Ground = 0.4, Rock = 0.42, Asphalt = 0.4, Pavement = 0.4, Salt = 0.34,
		LeafyGrass = 0.4,
	}
	local MAT_SEE_DEFAULT = 0.3
	local function effGTr(s, p)
		local tr = p.Transparency
		if s.texUser == true and tr < WOOD_SEE then tr = WOOD_SEE end
		local sm = s.seeMat
		if sm == true or (type(sm) == "table" and sm[p]) then   -- 素材を選んだ板(部品)だけ (何も選んでいない板は、今までどおり色がくっきり)
			local ok, nm = pcall(function() return p.Material.Name end)
			local see = MAT_SEE[ok and nm or ""]
			if see == nil then see = MAT_SEE_DEFAULT end
			if tr < see then tr = see end
		end
		return tr
	end
	-- 光る素材 (ネオン・フォースフィールド) の上の重ね貼りは、明るさを環境光に左右されないようにする (素材が暗い場所で沈まないように)
	local function effLI(p)
		local ok, nm = pcall(function() return p.Material.Name end)
		if ok and (nm == "Neon" or nm == "ForceField") then return 0 end
		return 1
	end

	-- いまの設定から「どの面に、何を作る/更新するか」の作業表を作る
	local function ovPlan(model, s, ov)
		local parts = partsOf(model)
		local plan = {}
		local g = s.grad
		if g and g.smooth then
			if g.flow > 0 and g.ang then   -- 流れる時: 面ごとに「いまの色の並び」を作る。動かすのは各自の画面 (anim.lua) が、毎フレーム色の並びを書き換える
				local D = SK.flowVec(g.ang)
				local ex, span, lo = dirInfo(model, parts, D)
				if span > 1e-3 then plan.g = { cfg = g, flow = true, D = D, ex = ex, span = span, lo = lo, lut = SK.cycLUT(g) } end
			elseif g.flow <= 0 then
				local ex, span = axisInfo(model, parts, AXIS[g.axis])
				if span > 1e-3 then plan.g = { cfg = g, ax = AXIS[g.axis], ex = ex } end
			end
		end
		local k = glossK(s.refl or 0)
		if k > 0 then
			local trMax = 0   -- 板が透けているほど、ツヤの帯も薄くする (透けた板に不透明な白い帯が浮かないように)
			for _, p in ipairs(parts) do
				if p.Transparency > trMax then trMax = p.Transparency end
			end
			local id = GLOSS_STYLES[s.glossStyle or 1] and (s.glossStyle or 1) or 1
			local ax = AXIS[s.glossAxis or "X"] or 1
			local ex = axisInfo(model, parts, ax)
			local sid = SKIES[s.sky or 1] and (s.sky or 1) or 1
			plan.gl = { k = k * (1 - 0.6 * trMax), id = id, style = GLOSS_STYLES[id], ax = ax, ex = ex, flip = (g and g.topFlip) == true, sky = sid, env = SKIES[sid] }
		end
		if (s.sheen or 0) > 0 then plan.sh = { col = (s.sheenCol == 2 or s.sheenCol == 3) and s.sheenCol or 1 } end   -- 光が走る帯
		if (s.edge or 0) > 0 then plan.ed = { k = math.clamp(s.edge, 0, 1) } end                                      -- 角のハイライト
		-- 部品ごとの面の大きさ。大きな面だけに重ねる
		local areas, amax = {}, 0
		for i, p in ipairs(parts) do
			local z = p.Size
			local xy, zy, xz = z.X * z.Y, z.Z * z.Y, z.X * z.Z
			areas[i] = { Front = xy, Back = xy, Left = zy, Right = zy, Top = xz, max = math.max(xy, zy, xz) }
			if areas[i].max > amax then amax = areas[i].max end
		end
		local jobs, wanted, count, nSheen = {}, {}, 0, 0
		if plan.g or plan.gl or plan.sh or plan.ed then
			for _, f in ipairs(FORDER) do
				for i, p in ipairs(parts) do
					local a = areas[i]
					if count < OVC.maxFaces and a.max >= OVC.partMin * amax and a[f[1]] >= OVC.areaMin * a.max then
						local jg, jgl, jsh, jed
						local cw, ch = faceCanvas(p, f[1])
						if plan.g then
							if plan.g.flow then
								local ang, tc, ts = faceDir(plan.g.ex[i], f, p, plan.g.D, plan.g.span, plan.g.lo, plan.g.cfg.topFlip)
								jg = { flow = true, ang = ang, tc = tc, ts = ts }
							else
								local t0, t1, vert = faceWindow(plan.g.ex[i], f, plan.g.ax, plan.g.cfg.topFlip)
								if t0 then jg = { t0 = t0, t1 = t1, vert = vert } end
							end
						end
						if plan.gl then
							local e = plan.gl.ex[i]
							local t0, t1, vert = faceWindow(e, f, plan.gl.ax, plan.gl.flip)
							if not t0 then
								t0 = (e.ta + e.tb) / 2   -- 軸に沿わない面は、一定の濃さ
								t1, vert = t0, false
							end
							jgl = { t0 = t0, t1 = t1, vert = vert }
						end
						if plan.sh and f[1] == "Top" and nSheen < OVC.maxSheen and math.min(cw, ch) >= 8 then   -- 光が走るのは上の面だけ (動かす数を抑える)
							jsh = true
							nSheen = nSheen + 1
						end
						if plan.ed and cw >= OVC.edgeMin and ch >= OVC.edgeMin then jed = true end   -- 細すぎる面には線を引かない
						if jg or jgl or jsh or jed then
							count = count + 1
							jobs[#jobs + 1] = { p = p, face = f[1], i = i, g = jg, gl = jgl, sh = jsh, ed = jed, cw = cw, ch = ch }
							wanted[p] = wanted[p] or {}
							wanted[p][f[1]] = true
						end
					end
				end
			end
		end
		-- いらなくなった面は先に片づける (軽い仕事。古い見た目が残らないように)
		local work = {}
		for i, p in ipairs(parts) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fname = c.Face and c.Face.Name
					if not (fname and wanted[p] and wanted[p][fname]) then
						work[#work + 1] = { p = p, face = fname, i = i, sg = c }
					end
				end
			end
		end
		for _, j in ipairs(jobs) do work[#work + 1] = j end
		ov.plan, ov.jobs, ov.i = plan, work, 1
	end

	-- 1つの面を、作業表のとおりにする (なければ作る / あれば中身だけ書き換える / いらなければ消す)
	-- 層 (下から): G=グラデーション / Gloss=ツヤ / Sheen=光が走る帯 / Edge=角のハイライト。いらない層はその面から消す
	local function ovFace(model, s, plan, job)
		local p = job.p
		if p.Parent ~= model then return end
		local jg, jgl, jsh, jed = job.g, job.gl, job.sh, job.ed
		local sg = job.sg or findFace(p, job.face)
		if not jg and not jgl and not jsh and not jed then
			if sg then sg:Destroy() end
			return
		end
		local fresh = false
		if not sg then
			sg = newFaceGui(job.face, job.cw, job.ch)
			fresh = true
		end
		local rec = FSIG[sg]
		if not rec then rec = {} FSIG[sg] = rec end
		local cvs = job.cw .. "x" .. job.ch   -- 面の形が変わっていたら、下絵の大きさも合わせる (ふつうは変わらない)
		if fresh then
			rec.cv = cvs
		elseif rec.cv ~= cvs then
			pcall(function() sg.CanvasSize = Vector2.new(job.cw, job.ch) end)
			rec.cv = cvs
			rec.sh, rec.ed = nil, nil
		end

		-- G: グラデーション (下の層)
		local fG = sg:FindFirstChild("G")
		if jg then
			local gg
			if fG then
				gg = fG:FindFirstChildOfClass("UIGradient")
			else
				fG, gg = makeLayer("G", 1)
				rec.g = nil
			end
			if not gg then
				gg = Instance.new("UIGradient")
				gg.Parent = fG
				rec.g = nil
			end
			local cfg = plan.g.cfg
			if jg.flow then
				-- 流れる面: ここでは「いまの時刻の色の並び」を1回だけ書く (動かさない人にも、止まった状態で正しく見える)。
				-- 位置(tc)と幅(ts)は属性に残し、各自の画面 (anim.lua) が毎フレーム色の並びを書き換えて流す。速さが変わっても、ここは作り直さない
				local sig = string.format("F%d|%.5f|%.5f|%.2f", cfg.id, jg.tc, jg.ts, jg.ang)
				if rec.g ~= sig then
					gg.Rotation = jg.ang
					gg.Color = SK.flowSeq(cfg, plan.g.lut, jg.tc, jg.ts, SK.flowPhase(cfg.flow))
					fG:SetAttribute("PS_tc", jg.tc)
					fG:SetAttribute("PS_ts", jg.ts)
					rec.g = sig
				end
			else
				local sig = string.format("%d|%d|%.3f|%.3f|%d|%.5f|%.5f|%d", cfg.id, job.i, s.variance or 0, s.weather or 0, s.wkind or 1, jg.t0, jg.t1, jg.vert and 1 or 0)
				if rec.g ~= sig then
					local i = job.i
					gg.Color = buildSeq(cfg, jg.t0, jg.t1, function(c) return tint(s, i, c) end)
					gg.Rotation = jg.vert and 90 or 0
					if fG:GetAttribute("PS_tc") ~= nil then   -- 流れていた面が、止まった面になった
						fG:SetAttribute("PS_tc", nil)
						fG:SetAttribute("PS_ts", nil)
					end
					rec.g = sig
				end
			end
			local tr = effGTr(s, p)   -- 板の透明度に合わせる (重ね貼りだけ不透明に残らないように)
			if fG.BackgroundTransparency ~= tr then fG.BackgroundTransparency = tr end
			local li = effLI(p)
			if sg.LightInfluence ~= li then sg.LightInfluence = li end
			if fG.Parent ~= sg then fG.Parent = sg end
		elseif fG then
			fG:Destroy()
			rec.g = nil
		end

		-- Gloss: ツヤ
		local fL = sg:FindFirstChild("Gloss")
		if jgl then
			local gl = plan.gl
			local top = (job.face == "Top")
			local lg
			if fL then
				lg = fL:FindFirstChildOfClass("UIGradient")
			else
				fL, lg = makeLayer("Gloss", 2)
				rec.gl = nil
			end
			if not lg then
				lg = Instance.new("UIGradient")
				lg.Parent = fL
				rec.gl = nil
			end
			local sig = string.format("%d|%d|%d|%.5f|%.5f|%.5f|%d", gl.id, gl.sky, top and 1 or 0, gl.k, jgl.t0, jgl.t1, jgl.vert and 1 or 0)
			if rec.gl ~= sig then
				lg.Color, lg.Transparency = glossSeqs(gl.style, gl.k, jgl.t0, jgl.t1, top, gl.env)
				lg.Rotation = jgl.vert and 90 or 0
				rec.gl = sig
			end
			if fL.Parent ~= sg then fL.Parent = sg end
			s.hasGloss = true
		elseif fL then
			fL:Destroy()
			rec.gl = nil
		end

		-- Sheen: 光が走る帯。ふだんは面の外に置いておき、動かすのは各自の画面 (anim.lua)。長い辺に沿って走る
		local fS = sg:FindFirstChild("Sheen")
		if jsh then
			local sgd
			if fS then
				sgd = fS:FindFirstChildOfClass("UIGradient")
			else
				fS, sgd = makeLayer("Sheen", 3)
				rec.sh = nil
			end
			if not sgd then
				sgd = Instance.new("UIGradient")
				sgd.Parent = fS
				rec.sh = nil
			end
			local vert = job.ch > job.cw * 1.2
			local sig = string.format("%d|%d", plan.sh.col, vert and 1 or 0)
			if rec.sh ~= sig then
				sgd.Color, sgd.Transparency = sheenSeqs(plan.sh.col)
				sgd.Rotation = vert and (90 - SHEEN_TILT) or SHEEN_TILT
				sgd.Offset = vert and Vector2.new(0, SHEEN_HIDE) or Vector2.new(SHEEN_HIDE, 0)
				rec.sh = sig
			end
			if fS.Parent ~= sg then fS.Parent = sg end
			s.hasSheen = true
		elseif fS then
			fS:Destroy()
			rec.sh = nil
		end

		-- Edge: 角のハイライト。面のふちから少し内側に、左上は白く・右下は暗い細い線を引く (ふちが立体的に見える)
		local fE = sg:FindFirstChild("Edge")
		if jed then
			local k = plan.ed.k
			local es, eg
			if fE then
				es = fE:FindFirstChildOfClass("UIStroke")
			else
				fE = Instance.new("Frame")
				fE.Name = "Edge"
				fE.BackgroundTransparency = 1
				fE.BorderSizePixel = 0
				fE.ZIndex = 4
				rec.ed = nil
			end
			if not es then
				es = Instance.new("UIStroke")
				pcall(function() es.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
				es.Parent = fE
				eg = Instance.new("UIGradient")
				eg.Rotation = 45
				eg.Color = EDGE_COL
				eg.Parent = es
				rec.ed = nil
			end
			local sig = string.format("%.3f|%s", k, cvs)
			if rec.ed ~= sig then
				local inset = 2 + 1.5 * k
				fE.Position = UDim2.fromOffset(inset, inset)
				fE.Size = UDim2.new(1, -2 * inset, 1, -2 * inset)
				es.Thickness = 1 + 1.6 * k
				es.Transparency = 1 - 0.85 * k
				rec.ed = sig
			end
			if fE.Parent ~= sg then fE.Parent = sg end
			s.hasEdge = true
		elseif fE then
			fE:Destroy()
			rec.ed = nil
		end

		if fresh then sg.Parent = p end   -- 中身を全部つくってから、最後に板へ付ける (1面ぶんが1回でまとまって届く)
	end

	-- 1フレームぶんの作業。noLimit=true なら時間を気にせず全部終わらせる (テスト・確認用)
	local function ovStep(noLimit)
		local list = OV.list
		local t0, n = os.clock(), 0
		while #list > 0 do
			local ov = list[1]
			local model, s = ov.model, ov.s
			if stateOf[model] ~= s or not model.Parent then   -- リセットされた / 消えた板の分は、やめる
				ov.queued, ov.model, ov.plan, ov.jobs = false, nil, nil, nil
				table.remove(list, 1)
			else
				if not ov.jobs then
					local ok, err = pcall(ovPlan, model, s, ov)
					if not ok then
						ov.plan, ov.jobs, ov.i = {}, {}, 1
						if not ov.warned then ov.warned = true pcall(warn, "PalletStudio plan: " .. tostring(err)) end
					end
				end
				local job = ov.jobs[ov.i]
				if not job then
					ov.queued, ov.model, ov.plan, ov.jobs = false, nil, nil, nil
					table.remove(list, 1)
				else
					ov.i = ov.i + 1
					local ok, err = pcall(ovFace, model, s, ov.plan, job)
					if not ok and not ov.warned then ov.warned = true pcall(warn, "PalletStudio face: " .. tostring(err)) end
					n = n + 1
					if not ov.jobs[ov.i] then   -- いまのが最後の1つだった → その場で終わりにする (次のフレームまで待たない)
						ov.queued, ov.model, ov.plan, ov.jobs = false, nil, nil, nil
						table.remove(list, 1)
					end
					if not noLimit and (n >= OVC.maxJobs or os.clock() - t0 >= OVC.budget) then break end
				end
			end
		end
		if #list == 0 and OV.conn then
			OV.conn:Disconnect()
			OV.conn = nil
		end
	end
	function SK.ovFlush()   -- 作業待ちを全部、いますぐ終わらせる (テスト・確認用)
		local guard = 0
		while #OV.list > 0 and guard < 100000 do
			guard = guard + 1
			ovStep(true)
		end
	end
	function SK.ovPending() return #OV.list end

	-- 重ね貼りの中身が変わる設定をした時に呼ぶ: 次のフレームから、最新の設定で作り直し/更新する
	local function ovTouch(model)
		local s = st(model)
		local ov = s.ov
		if not ov then
			ov = { s = s, i = 1 }   -- (板そのものは、作業待ちの間だけ持つ。ずっと持つと、消えた板がメモリに残ってしまう)
			s.ov = ov
		end
		ov.jobs = nil
		ov.i = 1
		if not ov.queued then
			ov.queued = true
			ov.model = model
			OV.list[#OV.list + 1] = ov
			if not OV.conn then
				OV.conn = RunService.Heartbeat:Connect(function()
					local ok, err = pcall(ovStep, false)
					if not ok then   -- 想定外のエラーでも、毎フレーム止まり続けないように、先頭の1件を捨てて先へ進む
						pcall(warn, "PalletStudio overlay: " .. tostring(err))
						local bad = table.remove(OV.list, 1)
						if bad then bad.queued, bad.model, bad.plan, bad.jobs = false, nil, nil, nil end
					end
				end)
			end
		end
	end
	-- 消す側の操作の後に呼ぶ: 作りかけの古い作業表を捨てる (消したものを、あとから作ってしまわないように)
	local function ovInvalidate(model)
		local ov = st(model).ov
		if ov and ov.queued then
			ov.jobs = nil
			ov.i = 1
		end
	end

	-- 重ね貼りの層を、板の全パーツから消す (すぐ消える。消すのは軽い)
	local function dropLayers(model, names)
		for _, p in ipairs(partsOf(model)) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					for _, n in ipairs(names) do
						local f = c:FindFirstChild(n)
						if f then f:Destroy() end
					end
					if #c:GetChildren() == 0 then c:Destroy() end
				end
			end
		end
	end

	function SK.clearGloss(model)
		local s = st(model)
		if s.hasGloss then
			dropLayers(model, { "Gloss", "Sky", "Band" })   -- 古い版の Sky / Band も片づける
			s.hasGloss = nil
		end
		ovInvalidate(model)
	end

	-- ツヤの重ね貼りを、いまの反射の強さ(s.refl)に合わせる (作る/更新は次のフレームから少しずつ)
	function SK.gloss(model, parts)
		local s = st(model)
		if glossK(s.refl or 0) <= 0 then
			SK.clearGloss(model)
		else
			ovTouch(model)
		end
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

	-- いま流れているグラデーションの向き (度)。流れていなければ nil (プリセットに向きまで保存するため)
	function SK.flowAng(model)
		local s = stateOf[model]
		local g = s and s.grad
		if g and (g.flow or 0) > 0 then return g.ang end
		return nil
	end

	function SK.clearGrad(model)
		local s = st(model)
		local old = s.grad
		if not old then return end
		s.grad = nil
		dropLayers(model, { "G" })
		if old.topFlip and glossK(s.refl or 0) > 0 then
			ovTouch(model)   -- 上面の向きの反転がなくなるので、ツヤの向きも元に戻す
		else
			ovInvalidate(model)
		end
		syncAnim(model)
	end

	-- 板についている重ね貼りを全部消す (元に戻す時用。古い版の SkinGrad も消す)
	function SK.dropAll(model)
		for _, p in ipairs(partsOf(model)) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" or c.Name == "SkinGrad" then c:Destroy() end
			end
		end
		ovInvalidate(model)
	end

	function SK.refreshGradTr(model, parts)
		local s = st(model)
		for _, p in ipairs(parts) do
			local tr = effGTr(s, p)
			local li = effLI(p)
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local fr = c:FindFirstChild("G")
					if fr and fr.BackgroundTransparency ~= tr then fr.BackgroundTransparency = tr end
					if c.LightInfluence ~= li then c.LightInfluence = li end
				end
			end
		end
	end

	-- ===== グラデーション (2色/3色を混ぜる。cfg.flow > 0 なら色が流れる) =====
	-- v = { a, b, c(なくても可), axis, rev, mid=0.1~0.9, smooth, stripes=0~8, topFlip, flow=0~2 }
	-- 流れる時 (flow > 0): 向きは「流すを選んだ時に1回だけ」ランダムに決まり (cfg.ang, 度)、流している間は変わらない。
	--   色の変え方・速さを動かしても、向きはそのまま。いったんOFFにして、もう一度ONにすると、新しい向きになる。
	--   向きは板の上から見た水平の向きなので、斜めにも流れる (X/Y/Z の「混ぜる向き」は、流れない時だけ効く)。
	local gradSerial = 0
	local function cfgSig(c)
		local function col(x) return x and string.format("%.4f,%.4f,%.4f", x.R, x.G, x.B) or "-" end
		return table.concat({ col(c.a), col(c.b), col(c.c), c.axis, c.rev and 1 or 0, string.format("%.3f", c.mid), c.stripes,
			c.smooth and 1 or 0, c.topFlip and 1 or 0, c.flow > 0 and string.format("%.2f", c.ang or 0) or "s" }, "|")
	end
	function SK.gradient(model, parts, v, keepTex)
		if typeof(v) ~= "table" or typeof(v.a) ~= "Color3" or typeof(v.b) ~= "Color3" or not AXIS[v.axis] then return false end
		local s = st(model)
		local old = s.grad
		local cfg = {
			a = v.a, b = v.b, c = (typeof(v.c) == "Color3") and v.c or nil, axis = v.axis, rev = v.rev == true,
			smooth = v.smooth ~= false, topFlip = v.topFlip == true,
			mid = isNum(v.mid) and math.clamp(v.mid, 0.1, 0.9) or 0.5,
			stripes = isNum(v.stripes) and math.clamp(math.floor(v.stripes), 0, 8) or 0,
			flow = isNum(v.flow) and math.clamp(v.flow, 0, 2) or 0,
		}
		if cfg.flow > 0 then
			if old and (old.flow or 0) > 0 and old.ang then
				cfg.ang = old.ang   -- すでに流れている: 向きはそのまま
			elseif isNum(v.ang) then
				cfg.ang = v.ang % 360   -- 保存したプリセットから呼ばれた時: その時の向きをそのまま使う
			else
				cfg.ang = pickFlowAngle()   -- 流し始め: ここで1回だけ決める
			end
		end
		cfg.sig = cfgSig(cfg)
		if old and old.sig == cfg.sig then
			cfg.id = old.id   -- 見た目が同じなら、面の作り直しはしない
		else
			gradSerial = gradSerial + 1
			cfg.id = gradSerial
		end
		s.rainbow = nil
		s.userCol = true   -- 自分で選んだ色 (このあと素材を選んでも、色は残す)
		if not keepTex then
			s.texUser = false
			setTexture(parts, false)   -- 木目が上に残ると色が見えないので、外す
		end
		s.grad = cfg
		s.base = gradAt(cfg, 0.5)
		-- 板そのものの色 (軽い設定): まず部品ごとの平均色にして、その場で反映する。重ね貼りができるまでの間も、色が付いて見える
		local span
		if cfg.flow > 0 then
			local ex, sp = dirInfo(model, parts, SK.flowVec(cfg.ang))
			span = sp
			local lut = SK.cycLUT(cfg)
			for i, p in ipairs(parts) do
				remember(p)
				local e = ex[i]
				local tc = (e.ta + e.tb) / 2
				setCol(p, tint(s, i, SK.flowCol(cfg, lut, tc)))   -- 流れない人の画面・重ね貼りしない面・流れの元の色は、この平均色
				p:SetAttribute("PS_T", tc)
			end
		else
			local ex, sp = axisInfo(model, parts, AXIS[cfg.axis])
			span = sp
			for i, p in ipairs(parts) do
				remember(p)
				local e = ex[i]
				local tc = (e.ta + e.tb) / 2
				setCol(p, tint(s, i, gradAt(cfg, tc)))   -- 重ね貼りしない面(裏・端)の色は、この平均色
				p:SetAttribute("PS_T", tc)
			end
		end
		syncAnim(model)
		if cfg.smooth and span > 1e-3 then
			ovTouch(model)   -- なめらかな重ね貼りは、次のフレームから少しずつ作る / 更新する (すでにあれば、作り直さず色だけ変える)
		else
			dropLayers(model, { "G" })   -- 重ね貼りしない設定 (くっきり): いまある分は、すぐ消す
			ovInvalidate(model)
		end
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

	-- 「光の波」「光が走る帯」の時間差用: 板の長い方向での位置を、パーツごとに 0〜1 で属性 PS_W に書く (PS_T とは別。グラデの向きに左右されない)
	function SK.assignW(model, parts)
		local exX, spX = axisInfo(model, parts, 1)
		local exZ, spZ = axisInfo(model, parts, 3)
		local ex = (spX >= spZ) and exX or exZ
		for i, p in ipairs(parts) do
			p:SetAttribute("PS_W", (ex[i].ta + ex[i].tb) / 2)
		end
	end

	-- 経年劣化の「雪(上ほど)」「こけ(下ほど)」用: パーツごとの高さ 0(下)〜1(上) を、設定に覚えておく
	function SK.setHeights(model, parts)
		local s = st(model)
		local ex, span = axisInfo(model, parts, 2)
		local wh = {}
		for i = 1, #parts do
			wh[i] = (span > 1e-3) and (ex[i].ta + ex[i].tb) / 2 or 0.5
		end
		s.wh = wh
	end

	-- ツートン: 板の一部を選ぶ。mode = Top 上の段 / Bottom 下の段 / Half1 前半 / Half2 後半 / Stripe しましま / Outer 外側 / Random ランダム
	-- 戻り値: { [パーツ] = true }。パーツが2つ以上あれば、必ず「一部だけ」(すべて・ゼロにならない)。不正な mode は nil
	local TWO_MODE = { Top = true, Bottom = true, Half1 = true, Half2 = true, Stripe = true, Outer = true, Random = true }
	function SK.groupParts(model, parts, mode)
		if not TWO_MODE[mode] then return nil end
		local n = #parts
		local exY, spY = axisInfo(model, parts, 2)
		local exX, spX = axisInfo(model, parts, 1)
		local exZ, spZ = axisInfo(model, parts, 3)
		local long = (spX >= spZ) and exX or exZ
		local function cen(e) return (e.ta + e.tb) / 2 end
		local score = {}   -- 大きいものから順に選ぶ (同点はパーツの順番)
		local sel = {}     -- 基準で直接決まる時は、ここに true を入れる
		local direct = false
		if mode == "Top" or mode == "Bottom" then
			local ex = (spY > 1e-3) and exY or long   -- 高さに差がない板は、長い方向で分ける
			local top = (mode == "Top")
			for i = 1, n do
				local t = cen(ex[i])
				sel[i] = top and t >= 0.66 or (not top and t <= 0.34)
				score[i] = top and t or -t
			end
			direct = true
		elseif mode == "Half1" or mode == "Half2" then
			for i = 1, n do
				local t = cen(long[i])
				sel[i] = (mode == "Half1") and t < 0.5 or (mode == "Half2" and t >= 0.5)
				score[i] = (mode == "Half2") and t or -t
			end
			direct = true
		elseif mode == "Stripe" then
			local order = {}
			for i = 1, n do order[i] = i end
			table.sort(order, function(a, b)
				local ca, cb = cen(long[a]), cen(long[b])
				if ca ~= cb then return ca < cb end
				return a < b
			end)
			for r, i in ipairs(order) do
				sel[i] = (r % 2 == 0)
				score[i] = sel[i] and 1 or 0
			end
			direct = true
		elseif mode == "Outer" then
			for i = 1, n do
				local dx = (spX > 1e-3) and math.abs(cen(exX[i]) - 0.5) or 0
				local dz = (spZ > 1e-3) and math.abs(cen(exZ[i]) - 0.5) or 0
				score[i] = math.max(dx, dz) + i * 1e-6
			end
		else   -- Random: パーツの番号から決める (毎回同じ結果になる)
			for i = 1, n do score[i] = ((i * 7919 + 13) % 101) / 101 end
		end
		local set, c = {}, 0
		if direct then
			for i = 1, n do
				if sel[i] then set[parts[i]] = true c = c + 1 end
			end
		end
		if (not direct or c == 0 or c >= n) and n >= 2 then   -- 基準だけでは決まらない / 全部・ゼロになった時は、点数の上から半分
			set, c = {}, 0
			local order = {}
			for i = 1, n do order[i] = i end
			table.sort(order, function(a, b)
				if score[a] ~= score[b] then return score[a] > score[b] end
				return a < b
			end)
			for r = 1, math.max(1, math.floor(n / 2)) do set[parts[order[r]]] = true end
		end
		return set
	end

	-- 光が走る帯 (Sheen) を付ける / 外す。speed=0 で外す。走る速さは各自の画面側(anim.lua)が属性から読む
	function SK.sheen(model, parts, speed)
		local s = st(model)
		local was = (s.sheen or 0) > 0
		if speed > 0 then
			s.sheen = speed
			SK.assignW(model, parts)
			if not was then ovTouch(model) end   -- 付けたばかりの時だけ、層を作る (速さだけ変える時は作り直さない)
		else
			s.sheen = nil
			if s.hasSheen then
				dropLayers(model, { "Sheen" })
				s.hasSheen = nil
			end
			ovInvalidate(model)
		end
		syncAnim(model)
	end
	-- 角のハイライト (Edge) を付ける / 外す。v=0 で外す
	function SK.edge(model, parts, v)
		local s = st(model)
		if v > 0 then
			s.edge = v
			ovTouch(model)
		else
			s.edge = nil
			if s.hasEdge then
				dropLayers(model, { "Edge" })
				s.hasEdge = nil
			end
			ovInvalidate(model)
		end
	end
	function SK.relayer(model) ovTouch(model) end   -- 重ね貼りの設定を変えた時に、作り直し/更新を頼む
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
		SK.refreshGradTr(model, parts)   -- 素材が変わると、重ね貼りの透け具合の決まりも変わる (ネオンは透かさない)
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
	-- 光・動き・質感まわりの追加設定も、いったん初期に戻す (画面のスイッチ類も同時に初期へ戻るので、合わせておく)
	s.pdepth, s.pwave, s.gmode, s.gcol2, s.gspeed, s.night, s.spot, s.ofill, s.lightShape = nil, nil, nil, nil, nil, nil, nil, nil, nil
	s.sky, s.wkind, s.wh, s.glossAxis, s.variance, s.weather = nil, nil, nil, nil, nil, nil
	twoOff(model, parts, false)
	SK.sheen(model, parts, 0)
	SK.edge(model, parts, 0)
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
	s.userCol = true     -- プリセットの色は、自分で選んだ色として扱う (このあと素材を選んでも色は残る)
	s.seeMat = true      -- 素材の模様が、グラデの下から見える
	s.glowLook = nil
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

local PULSE_STYLES = { Sine = true, Beat = true, Flicker = true, Strobe = true, Breath = true, Lightning = true, Neon = true, Saw = true, Steps = true, SOS = true }
local MAX_BATCH = 100
local applySkin
function applySkin(model, kind, value)
	local parts = partsOf(model)
	if #parts == 0 then return "板の部品が見つかりません" end
	local s = st(model)
	-- 素材ボタン (Look): 自分で色(単色・グラデ・レインボー)を選んでいる板では、色は消さずに素材だけ変える (smart)。
	-- まだ色を選んでいない板は、今までどおり素材の色になる。素材の色にしたい時は LookRaw
	local smart = (kind == "Look" and s.userCol == true)
	if s.two and (kind == "Look" or kind == "LookKeep" or kind == "LookRaw" or kind == "Material" or kind == "Preset") then s.two = nil end   -- 素材を丸ごと入れ替える操作は、ツートンをやめる
	-- 色を直接変える操作・レインボーONの時は、重ね貼りしているグラデーションを先に外す。色を決める操作はレインボーも止める
	local recolor = kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "LookRaw" or (kind == "Look" and not smart) or kind == "Preset"
	if recolor or (kind == "Rainbow" and value == true) then
		SK.clearGrad(model)
	end
	if recolor then
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
		s.userCol = true
		paint(model, parts, value)
		return "色を変えました"
	elseif kind == "HSV" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		s.userCol = true
		paint(model, parts, Color3.fromHSV(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "RGB" then
		if typeof(value) ~= "table" or not isNum(value[1]) or not isNum(value[2]) or not isNum(value[3]) then return "値が不正です" end
		s.userCol = true
		paint(model, parts, Color3.new(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1)))
		return "色を調整しました"
	elseif kind == "Material" then
		if typeof(value) ~= "string" or not MATERIAL_SET[value] then return "素材が不正です" end
		for _, p in ipairs(parts) do remember(p) p.Material = Enum.Material[value] end
		s.seeMat = true
		SK.refreshGradTr(model, parts)   -- 素材の模様が、グラデの下から見えるように
		return "素材を「" .. value .. "」にしました"
	elseif kind == "Look" or kind == "LookRaw" then
		local lk = typeof(value) == "string" and LOOKS[value] or nil
		if not lk then return "素材が不正です" end
		s.neon, s.neonSaved = nil, nil
		s.texUser = false
		setTexture(parts, false)
		if smart then   -- 自分で選んだ色は残して、素材とその質感(反射・透け)だけ変える。光は、素材で付いた光なら入れ替え、自分で決めた光なら残す
			for _, p in ipairs(parts) do
				remember(p)
				p.Material = Enum.Material[lk[2]]
				p.Transparency = lk[4]
			end
			SK.reflect(model, parts, lk[3])
			s.seeMat = true
			SK.refreshGradTr(model, parts)
			if s.glowLook or (s.glowB or 0) <= 0 then
				setGlow(model, s.glowColor or s.base or lk[1], lk[5], 10)
				s.glowLook = lk[5] > 0 or nil
			end
			return "素材「" .. value .. "」にしました (色はそのまま)"
		end
		s.glowColor = nil
		s.userCol = false
		s.seeMat = true
		paint(model, parts, lk[1])
		for _, p in ipairs(parts) do
			p.Material = Enum.Material[lk[2]]
			p.Transparency = lk[4]
		end
		SK.reflect(model, parts, lk[3])
		setGlow(model, lk[1], lk[5], 10)
		s.glowLook = lk[5] > 0 or nil
		return "素材「" .. value .. "」にしました"
	elseif kind == "LookKeep" then   -- 色・光はそのままで、素材とその質感(反射・透け)だけ変える
		local lk = typeof(value) == "string" and LOOKS[value] or nil
		if not lk then return "素材が不正です" end
		s.neon, s.neonSaved = nil, nil
		s.texUser = false
		setTexture(parts, false)
		for _, p in ipairs(parts) do
			remember(p)
			p.Material = Enum.Material[lk[2]]
			p.Transparency = lk[4]
		end
		SK.reflect(model, parts, lk[3])
		s.seeMat = true
		SK.refreshGradTr(model, parts)
		return "素材「" .. value .. "」だけ変えました"
	elseif kind == "LookClear" then   -- 素材ボタンをもう一度押した時: 素材・質感を元の板に戻す (自分で選んだ色は残す。素材の色だった時は、元の色へ)
		local oc
		for i, p in ipairs(parts) do
			local o = orig[p]
			if o then
				p.Material, p.Reflectance, p.Transparency = o[2], o[3], o[4]
				if not s.userCol then setCol(p, tint(s, i, o[1])) end
				oc = oc or o[1]
			end
		end
		if not s.userCol and oc then s.base = oc end
		s.refl = 0
		for _, p in ipairs(parts) do
			if p.Reflectance > s.refl then s.refl = p.Reflectance end
		end
		SK.gloss(model, parts)
		s.seeMat = nil
		s.neon, s.neonSaved = nil, nil
		if not s.grad then
			s.texUser = nil
			setTexture(parts, true)
		end
		if s.glowLook then
			s.glowLook = nil
			setGlow(model, Color3.new(1, 1, 1), 0, nil)
		end
		SK.refreshGradTr(model, parts)
		return "素材を元に戻しました"
	elseif kind == "TwoTone" then   -- 板の一部だけ別の素材 (と色) にする
		if typeof(value) ~= "table" or typeof(value.mat) ~= "string" or not MATERIAL_SET[value.mat] then return "素材が不正です" end
		local set = SK.groupParts(model, parts, value.mode)
		if not set then return "分け方が不正です" end
		local plain = not s.grad and not s.rainbow   -- グラデ・レインボー中は、色はそちらに従う
		twoOff(model, parts, plain)   -- 前のツートンの素材と色は元に戻してから、新しく分ける
		local prev, back = {}, {}
		for _, p in ipairs(parts) do
			if set[p] then
				remember(p)
				prev[p] = p.Material
				p.Material = Enum.Material[value.mat]
				back[#back + 1] = p
			end
		end
		setTexture(back, false)   -- 木目が残ると、新しい素材が見えない
		local col
		if value.same ~= true then
			col = (typeof(value.col) == "Color3") and value.col or (LOOKS[value.mat] and LOOKS[value.mat][1]) or nil
		end
		s.two = { set = set, prev = prev, col = col }
		if s.seeMat ~= true then   -- 別の素材にした部分だけ、模様をグラデの下から見せる
			local sm = type(s.seeMat) == "table" and s.seeMat or {}
			for _, p in ipairs(parts) do sm[p] = set[p] or nil end
			s.seeMat = sm
		end
		SK.refreshGradTr(model, parts)
		if plain then
			for i, p in ipairs(parts) do
				if set[p] then
					local c = col or s.base
					if c then setCol(p, tint(s, i, c)) end
				end
			end
		end
		return "一部を「" .. value.mat .. "」にしました"
	elseif kind == "TwoToneClear" then
		if s.two then
			twoOff(model, parts, not s.grad and not s.rainbow)
		end
		if type(s.seeMat) == "table" then s.seeMat = nil end
		SK.refreshGradTr(model, parts)
		return "ツートンをやめました"
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
	elseif kind == "WeatherKind" then   -- 経年劣化の種類: 1 汚れ / 2 さび / 3 こけ / 4 雪 / 5 焦げ
		if not isNum(value) then return "値が不正です" end
		s.wkind = math.clamp(math.floor(value + 0.5), 1, WEATHER_N)
		SK.setHeights(model, parts)
		if s.grad then SK.gradient(model, parts, s.grad, true) else paint(model, parts, s.base or parts[1].Color) end
		return "経年劣化の種類を変えました"
	elseif kind == "GlossSky" then   -- 映り込む空: 1 昼 / 2 夕焼け / 3 夜 / 4 ネオン / 5 オーロラ / 6 スタジオ
		if not isNum(value) then return "値が不正です" end
		s.sky = math.clamp(math.floor(value + 0.5), 1, SK.SKIES)
		SK.gloss(model, parts)
		return "映り込む空を変えました"
	elseif kind == "Sheen" then   -- 光が走る帯 (0 で止める)
		if not isNum(value) then return "値が不正です" end
		SK.sheen(model, parts, math.clamp(value, 0, 1))
		return value > 0 and "光が走ります" or "光の走りを止めました"
	elseif kind == "SheenColor" then
		if not isNum(value) then return "値が不正です" end
		s.sheenCol = math.clamp(math.floor(value + 0.5), 1, 3)
		if (s.sheen or 0) > 0 then SK.relayer(model) end
		return "光の色を変えました"
	elseif kind == "Edge" then   -- 角のハイライト
		if not isNum(value) then return "値が不正です" end
		SK.edge(model, parts, math.clamp(value, 0, 1))
		return "角のハイライトを変えました"
	elseif kind == "Texture" then
		s.texUser = (value == true)
		setTexture(parts, value == true)
		if s.grad then SK.refreshGradTr(model, parts) end   -- グラデが木目を隠さないよう、透け具合を合わせる
		return value == true and "テクスチャON" or "テクスチャOFF"
	elseif kind == "Glow" then
		if not isNum(value) then return "値が不正です" end
		s.glowLook = nil   -- 自分で決めた光
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
		s.glowLook = nil
		s.glowColor = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l then l.Color = s.glowColor end
		model:SetAttribute("PS_GlowCol", s.glowColor)
		return "発光の色を変えました"
	elseif kind == "Rainbow" then
		if value == true then s.userCol = true end
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
	elseif kind == "PulseDepth" then   -- 明滅の深さ: 1 = 完全に暗くなる / 0 = ほとんど変わらない
		if not isNum(value) then return "値が不正です" end
		s.pdepth = math.clamp(value, 0, 1)
		syncAnim(model)
		return "明滅の深さを変えました"
	elseif kind == "PulseWave" then   -- 板の端から端へ、明滅がずれて走る (板も一緒に明滅している時)
		if not isNum(value) then return "値が不正です" end
		s.pwave = math.clamp(value, 0, 1)
		if s.pwave > 0 then SK.assignW(model, parts) end
		syncAnim(model)
		return "光の波を変えました"
	elseif kind == "GlowMode" then   -- 光の色の動き: Solid 単色 / Blend 2色を往復 / Alt 2色を交互 / Hue 虹色
		if value ~= "Solid" and value ~= "Blend" and value ~= "Alt" and value ~= "Hue" then return "値が不正です" end
		s.gmode = value
		syncAnim(model)
		return "光の色の動きを変えました"
	elseif kind == "GlowHue2" then
		if not isNum(value) then return "値が不正です" end
		s.gcol2 = Color3.fromHSV(math.clamp(value, 0, 1), 0.8, 1)
		syncAnim(model)
		return "2つ目の光の色を変えました"
	elseif kind == "GlowSpeed" then
		if not isNum(value) then return "値が不正です" end
		s.gspeed = math.clamp(value, 0.05, 1.5)
		syncAnim(model)
		return "色が変わる速さを変えました"
	elseif kind == "NightGlow" then
		s.night = (value == true)
		syncAnim(model)
		return value == true and "夜だけ光ります" or "いつでも光ります"
	elseif kind == "SpotAngle" then
		if not isNum(value) then return "値が不正です" end
		s.spot = math.clamp(value, 10, 120)
		local h = glowHost(model)
		local l = h and h:FindFirstChild("SkinGlow")
		if l and l.ClassName == "SpotLight" then l.Angle = s.spot end
		return "スポットの広さを変えました"
	elseif kind == "OutlineFill" then   -- 縁取りの内側を光らせる (オーラ)
		if not isNum(value) then return "値が不正です" end
		s.ofill = math.clamp(value, 0, 1)
		if s.ofill > 0 or model:FindFirstChild("SkinOutline") then setOutline(model, true) end
		return "オーラの強さを変えました"
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
			p:SetAttribute("PS_W", nil)
		end
		CollectionService:RemoveTag(model, ANIM_TAG)   -- 動かす担当には、最後に伝える (色は上で元に戻し済み)
		for _, n in ipairs(ANIM_ATTRS) do model:SetAttribute(n, nil) end
		return "元に戻しました"
	end
	return "不明な操作です"
end
---------------------------------------------------------------------
-- 動き (レインボー / 明滅 / 光の色の動き / 夜だけ光る / グラデーションの流れ / 光が走る帯) を、この画面でなめらかに動かす担当
-- サーバーは「設定」を板の属性に書くだけ。毎フレームの色・明るさの更新はここ(各自の画面)で行うので、
-- 通信の細かさに左右されず、画面の更新ごとに滑らかに動く。動きの基準はサーバー時刻なので、見ている人どうしでそろう。
-- (このスクリプトを入れている人の画面で動く。入れていない人には、止まった状態で見える)
---------------------------------------------------------------------
-- 動きの軽さの設定 (その他 > 軽量化 から変える。この画面だけの設定)
--   flowMul : 流れの色を書き換える間隔の倍率 (1=ふつう / 2=半分の回数 / 3=3分の1)
--   flowFar : これより遠い板は、流れを止める (studs)
--   flowFace: false なら、流れは板のパーツごとの色だけ (面のなめらかな色の並びは書き換えない。いちばん軽い)
--   sheenFar: これより遠い板は、光の走りを止める (studs)
local ANIMCFG = { flowMul = 1, flowFar = 300, flowFace = true, sheenFar = 160, nearN = 6 }
do
	local RunService = game:GetService("RunService")
	local CS = game:GetService("CollectionService")
	local Lighting = game:GetService("Lighting")
	local active = {}   -- 板 -> 状態

	local function smooth(x)
		x = math.clamp(x, 0, 1)
		return x * x * (3 - 2 * x)
	end
	local noise = math.noise or function(x, y, z) return math.sin(x * 12.9898 + (y or 0) * 78.233 + (z or 0) * 37.719) * 0.5 end
	local function hash(n)   -- 0〜1 の、番号から決まる疑似乱数 (同じ番号なら、みんな同じ値)
		local v = math.sin(n * 127.1 + 311.7) * 43758.5453
		return v - math.floor(v)
	end
	local function lerpC(a, b, k)
		return Color3.new(a.R + (b.R - a.R) * k, a.G + (b.G - a.G) * k, a.B + (b.B - a.B) * k)
	end
	-- モールス信号 SOS (・・・ ーーー ・・・) の「点く時間」(単位時間の中の 始まり, 終わり)。全体は34単位
	local SOS_ON = { { 0, 1 }, { 2, 3 }, { 4, 5 }, { 8, 11 }, { 12, 15 }, { 16, 19 }, { 22, 23 }, { 24, 25 }, { 26, 27 } }
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
		Breath = function(t, sp)   -- すぅっと明るくなって、ゆっくり暗くなる (呼吸)
			local ph = (t * sp) % 1
			local v = (ph < 0.4) and smooth(ph / 0.4) or smooth(1 - (ph - 0.4) / 0.6)
			return 0.08 + 0.92 * v
		end,
		Lightning = function(t, sp)   -- 雷: ふだんは暗く、ときどきバリッと2〜3回光る (光る位置は毎回ちがう)
			local x = t * sp
			local d = (x % 1) - (0.12 + 0.5 * hash(math.floor(x)))
			local v = 0
			if d >= 0 then
				v = math.exp(-(d / 0.012) ^ 2) + 0.7 * math.exp(-((d - 0.07) / 0.02) ^ 2) + 0.45 * math.exp(-((d - 0.17) / 0.03) ^ 2) + 0.18 * math.exp(-d / 0.09)
			end
			return 0.05 + 0.95 * math.min(1, v)
		end,
		Neon = function(t, sp)   -- 切れかけのネオン: ジジッと暗くなったり戻ったりする
			local n1 = noise(t * sp * 2.4, 1.9, 0.3)
			local n2 = noise(t * sp * 9.7, 4.1, 0.8)
			local off = smooth((n1 - 0.12) / 0.2)
			local buzz = 0.86 + 0.14 * math.clamp(n2 * 2, -1, 1)
			local low = 0.1 + 0.2 * math.clamp(n2 * 2 + 0.5, 0, 1)
			return buzz + (low - buzz) * off
		end,
		Saw = function(t, sp)   -- だんだん明るくなって、パッと消える (警報)
			local ph = (t * sp) % 1
			return 0.08 + 0.92 * ph ^ 1.6
		end,
		Steps = function(t, sp)   -- 4段階で明るくなっていく (階段)
			local x = ((t * sp) % 1) * 4
			local k = math.floor(x)
			local e = smooth((x - k) / 0.12)
			local prev, cur = ((k + 3) % 4) / 3, k / 3
			return 0.1 + 0.9 * (prev + (cur - prev) * e)
		end,
		SOS = function(t, sp)   -- ・・・ーーー・・・ (SOS)
			local u = (t * sp / 0.12) % 34
			local v = 0
			for _, iv in ipairs(SOS_ON) do
				local k = smooth((u - iv[1]) / 0.2) * smooth((iv[2] - u) / 0.2)
				if k > v then v = k end
			end
			return 0.06 + 0.94 * v
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
	-- 夜の度合い 0(昼)〜1(夜)。夜0時からの時間の近さで決める (19時〜5時 = 1、7時〜17時 = 0、その間はなめらか)
	local function nightK()
		local ok, c = pcall(function() return Lighting.ClockTime end)
		if not ok or typeof(c) ~= "number" then return 0 end
		local d = math.min(math.abs(c), math.abs(24 - c))
		return smooth((7 - d) / 2)
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

	-- カメラからの距離 (0.3秒ごとに測り直す。毎フレームは測らない)
	local function camDist(m, a, t)
		if a.pv then return 0 end   -- プレビューの板は、いつも「いちばん近い」あつかい (小さな窓の中なので、遠くても止めない)
		if a.dT and t - a.dT < 0.3 then return a.dist or 0 end
		a.dT = t
		local d = 0
		local cam = workspace.CurrentCamera
		if cam then
			local ok, v = pcall(function() return (cam.CFrame.Position - m:GetPivot().Position).Magnitude end)
			if ok and type(v) == "number" then d = v end
		end
		a.dist = d
		return d
	end

	-- ===== 見えない面は動かさない =====
	-- 面の重ね貼り (SurfaceGui) は、前からしか見えない。カメラが面の裏側にいる時は、その面の色を毎フレーム書き換えても誰にも見えないので、書き換えない。
	-- 見えるかどうかは、カメラの位置だけで決まる (向きを変えても変わらない)。0.12秒ごとに測り直し、面の手前 1.5 studs までは念のため見える扱いにする。
	local FACE_N = { Front = Vector3.new(0, 0, -1), Back = Vector3.new(0, 0, 1), Left = Vector3.new(-1, 0, 0), Right = Vector3.new(1, 0, 0), Top = Vector3.new(0, 1, 0) }
	local FACE_AX = { Front = "Z", Back = "Z", Left = "X", Right = "X", Top = "Y" }
	local VIS_EVERY, VIS_MARGIN = 0.12, 1.5
	local PHASE_MIN = 1 / 1000   -- 流れの位置がこれ(1周の割合)より進んでいない間は、面の色を書き換えない
	local function faceSee(p, sg, cp)
		local ok, res = pcall(function()
			local fname = sg.Face.Name
			local n = FACE_N[fname]
			if not n then return true end
			local cf, sz = p.CFrame, p.Size
			local nw = cf:VectorToWorldSpace(n)
			local c = cf.Position + nw * (sz[FACE_AX[fname]] * 0.5)
			return nw:Dot(cp - c) > -VIS_MARGIN
		end)
		return (not ok) or res
	end
	local function refreshVis(a, t)
		a.visT = t
		local cp
		if not a.pv then
			local cam = workspace.CurrentCamera
			if cam then
				local ok, v = pcall(function() return cam.CFrame.Position end)
				if ok and typeof(v) == "Vector3" then cp = v end
			end
		end
		local newlyShown = false
		for _, list in ipairs({ a.fl or {}, a.sh or {} }) do
			for _, e in ipairs(list) do
				local v = (cp == nil) or faceSee(e.p, e.sg, cp)
				if v and e.vis == false then newlyShown = true end
				e.vis = v
			end
		end
		if newlyShown then a.lastPh = nil end   -- 見えるようになった面は、すぐに今の色へ (流れの位置が同じでも書き直す)
	end

	-- 光が走る帯: 板の上の面にある Sheen の UIGradient を集めておく (作りかけの面があるので、ときどき探し直す)
	local function scanSheen(m, a, t)
		local list = {}
		for _, p in ipairs(a.parts) do
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local f = c:FindFirstChild("Sheen")
					local g = f and f:FindFirstChildOfClass("UIGradient")
					if g then list[#list + 1] = { g = g, w = p:GetAttribute("PS_W") or 0, vert = g.Rotation > 45, x = nil, p = p, sg = c } end
				end
			end
		end
		a.sh = list
		a.shT = t
		a.visT = nil   -- 探し直したら、見えるかも測り直す
	end
	local function stepSheen(m, a, t, sp)
		if not a.sh or t - (a.shT or -9) > 0.5 then scanSheen(m, a, t) end
		if not a.pv and t - (a.visT or -9) > VIS_EVERY then refreshVis(a, t) end
		local f = 0.12 + 0.5 * sp   -- 1秒あたりに走る回数
		for _, e in ipairs(a.sh) do
			if e.g.Parent and e.vis ~= false then
				local u = (t * f - e.w * 0.3) % 1   -- 板の端から端へ、少しずつ遅れて光る
				local x = (u < 0.45) and (-1.2 + 2.4 * (u / 0.45)) or -1.3
				if e.x ~= x then
					e.x = x
					e.g.Offset = e.vert and Vector2.new(0, x) or Vector2.new(x, 0)
				end
			end
		end
	end

	-- 流れる色: 板の面ごとに「色の並び」を作って流す。パーツごとの1色だけだと、パーツの境目で色が階段になってしまうため。
	--  ・面(重ね貼りの G 層)の UIGradient の Color を、毎フレーム「いまの流れの位置」の色の並びに書き換える
	--  ・流れの位置 = サーバー時刻 × 速さ。色の表(1周ぶん)は先に作っておき、毎フレームは選んで混ぜるだけ
	--  ・パーツ自身の色も、同じ流れの色にする (重ね貼りがない面・遠くから見た時用)
	local function scanFlow(m, a, t)
		local list, pt = {}, {}
		for i, p in ipairs(a.parts) do
			pt[i] = p:GetAttribute("PS_T") or 0
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "SkinFace" then
					local f = c:FindFirstChild("G")
					local tc = f and f:GetAttribute("PS_tc")
					if tc then
						local g = f:FindFirstChildOfClass("UIGradient")
						if g then list[#list + 1] = { g = g, tc = tc, ts = f:GetAttribute("PS_ts") or 0, p = p, sg = c } end
					end
				end
			end
		end
		a.fl, a.pt, a.flT, a.flId = list, pt, t, a.fid
		a.visT = nil     -- 探し直したら、見えるかも測り直す
		a.lastPh = nil   -- 新しく出来た面にも、すぐ今の色を書く
	end
	-- 流れを何フレームに1回書き換えるか (0 = 止める)。近い板ほど細かく、遠い板は粗く / 止める。順位は 0.3 秒ごとに付け直す
	local function flowLod(a)
		local r = a.rank or 1
		local lod
		if a.pv then
			lod = 1
		elseif (a.dist or 0) > ANIMCFG.flowFar then
			lod = 0
		elseif r <= ANIMCFG.nearN then
			lod = 1
		elseif r <= ANIMCFG.nearN * 2 then
			lod = 2
		elseif r <= ANIMCFG.nearN * 5 then
			lod = 3
		else
			lod = 5   -- 数が多い時の、いちばん後ろの板は 5フレームに1回 (止めると、近くで固まって見えるので止めない)
		end
		if lod > 0 then lod = lod * ANIMCFG.flowMul end
		return lod
	end

	local frameNo, nightNo, nightV = 0, -1, 0
	local function nightNow()   -- 夜の度合い。夜だけ光る板がある時だけ、1フレームに1回だけ測る
		if nightNo ~= frameNo then
			nightNo = frameNo
			nightV = nightK()
		end
		return nightV
	end
	local function step(m, a, t)
		local rb = m:GetAttribute("PS_Rb") == true
		local pul = m:GetAttribute("PS_Pulse") or 0
		local flow = m:GetAttribute("PS_Flow") or 0
		local body = m:GetAttribute("PS_PulseBody") == true
		local speed = m:GetAttribute("PS_RbSpeed") or 0.15
		local sat = m:GetAttribute("PS_RbSat") or 0.85
		local depth = m:GetAttribute("PS_PulseDepth") or 1
		local wave = m:GetAttribute("PS_PulseWave") or 0
		local gmode = m:GetAttribute("PS_GMode") or "Solid"
		local onlyNight = m:GetAttribute("PS_Night") == true
		if not a.parts then a.parts = partsOf(m) end
		local fn, pm = nil, 1
		if pul > 0 then
			fn = PULSE[m:GetAttribute("PS_PulseStyle") or "Sine"] or PULSE.Sine
			pm = 1 - depth * (1 - fn(t, pul))
		end

		-- 板の色: レインボー / グラデーションの流れ / 板も一緒に明滅 (光の波なら、板ごとに少しずつ遅れて)
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
				local fid = m:GetAttribute("PS_FId") or 0
				if a.fid ~= fid or not a.lut then
					a.fid = fid
					a.lut = SK.cycLUT(cfg)
					a.pt = nil
				end
				if not a.pt or a.flId ~= a.fid then scanFlow(m, a, t) end
			end
		end
		local bodyPulse = fn ~= nil and body
		local doFlow, phase = false, 0
		if cfg then
			if a.ffSeen ~= ANIMCFG.flowFace then   -- 「面も書き換える」の設定が変わった直後は、すぐ今の色に合わせる
				a.ffSeen = ANIMCFG.flowFace
				a.lastPh = nil
			end
			a.fc = (a.fc or 0) + 1
			local lod = flowLod(a)
			doFlow = lod > 0 and (a.fc % lod == 0)
			phase = (t * flow) % 1
			if doFlow then
				-- ゆっくり流れる時は、1周の 1/1000 も進んでいない間は書き換えない (面の上で 1ピクセルも動かない変化なので、書き換えても無駄)
				local lp = a.lastPh
				if lp then
					local d = math.abs(phase - lp)
					if d > 0.5 then d = 1 - d end
					if d < PHASE_MIN then doFlow = false end
				end
				if doFlow then a.lastPh = phase end
			end
		end
		if rb or bodyPulse or doFlow then
			local spread = m:GetAttribute("PS_RbSpread") or 0
			local bm = bodyPulse and (0.4 + 0.6 * pm) or 1
			local lut = a.lut
			for i, p in ipairs(a.parts) do
				if p.Parent then
					local c
					if rb then
						local T = p:GetAttribute("PS_T") or 0
						c = Color3.fromHSV((t * speed + spread * T) % 1, sat, 1)
					elseif cfg then
						c = SK.flowCol(cfg, lut, (a.pt[i] or 0) - phase)
					else
						c = p:GetAttribute("PS_Col")
					end
					if c then
						local k = bm
						if bodyPulse and wave > 0 then
							local W = p:GetAttribute("PS_W") or 0
							k = 0.4 + 0.6 * (1 - depth * (1 - fn(t - wave * W / pul, pul)))
						end
						if k ~= 1 then c = Color3.new(c.R * k, c.G * k, c.B * k) end
						p.Color = c
					end
				end
			end
			a.colored = true
		elseif not cfg then
			restoreColors(a)
		end
		if doFlow and ANIMCFG.flowFace then
			if not a.fl or t - (a.flT or -9) > 0.35 then scanFlow(m, a, t) end
			if not a.pv and t - (a.visT or -9) > VIS_EVERY then refreshVis(a, t) end
			for _, e in ipairs(a.fl) do
				if e.g.Parent and e.vis ~= false then e.g.Color = SK.flowSeq(cfg, a.lut, e.tc, e.ts, phase) end
			end
		end

		-- ライト: 明るさ (明滅 / 夜だけ光る) と 色 (レインボー / 2色の動き)
		local l = lightOf(m)
		if l then
			local gb = m:GetAttribute("PS_GlowB") or 0
			if gb > 0 and (fn ~= nil or onlyNight) then
				l.Brightness = gb * pm * (onlyNight and nightNow() or 1)
				a.litB = true
			elseif a.litB then
				restoreLight(m, a, "B")
			end
			if rb then
				l.Color = Color3.fromHSV((t * speed) % 1, sat, 1)
				a.litC = true
			elseif gmode ~= "Solid" and gb > 0 then
				local ca = m:GetAttribute("PS_GlowCol")
				if ca then
					local sp = m:GetAttribute("PS_GSpeed") or 0.3
					local c
					if gmode == "Hue" then
						local h, sa = ca:ToHSV()
						c = Color3.fromHSV((h + t * sp) % 1, math.max(sa, 0.6), 1)
					else
						local cb = m:GetAttribute("PS_GlowCol2")
						if not cb then
							local h, sa, v = ca:ToHSV()
							cb = Color3.fromHSV((h + 0.5) % 1, sa, v)   -- 2つ目の色を決めていなければ、反対の色
						end
						if gmode == "Blend" then
							c = lerpC(ca, cb, 0.5 - 0.5 * math.cos(t * sp * 6.2832))
						else
							c = lerpC(ca, cb, smooth(0.5 + 2.5 * math.sin(t * sp * 6.2832)))
						end
					end
					l.Color = c
					a.litC = true
				end
			elseif a.litC then
				restoreLight(m, a, "C")
			end
		end

		-- 光が走る帯 (遠くの板は動かさない。見えないのに更新しない)
		local sh = m:GetAttribute("PS_Sheen") or 0
		if sh > 0 then
			if (a.dist or 0) < ANIMCFG.sheenFar then
				a.shRest = nil
				stepSheen(m, a, t, sh)
			elseif not a.shRest and a.sh then
				-- 遠くで止める時は、光の帯が途中で止まって見えないよう、帯のない位置にもどしてから止める
				a.shRest = true
				for _, e in ipairs(a.sh) do
					if e.g.Parent and e.x ~= -1.3 then
						e.x = -1.3
						e.g.Offset = e.vert and Vector2.new(0, -1.3) or Vector2.new(-1.3, 0)
					end
				end
			end
		elseif a.sh then
			a.sh = nil
			a.shRest = nil
		end
	end

	local remove   -- (下で定義。毎フレームの処理から呼ぶので、先に宣言しておく)
	local addNo = 0
	local conn = nil
	local lastRank = -9
	-- 流れている板を、カメラに近い順に並べて、順位をつける (近い板ほど細かく動かすため)
	local function rankFlow(t)
		lastRank = t
		local list = {}
		for m, a in pairs(active) do
			camDist(m, a, t)
			if not a.pv and (m:GetAttribute("PS_Flow") or 0) > 0 then list[#list + 1] = a end
		end
		table.sort(list, function(x, y)
			local dx, dy = x.dist or 0, y.dist or 0
			if dx ~= dy then return dx < dy end
			return (x.n or 0) < (y.n or 0)   -- 同じ距離の時は、出てきた順 (順位が毎回入れ替わって、細かさがちらつかないように)
		end)
		for i, a in ipairs(list) do a.rank = i end
	end
	local function onFrame()
		local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
		if not ok then t = os.clock() end
		local clk = os.clock()
		frameNo = frameNo + 1
		if clk - lastRank > 0.3 then rankFlow(clk) end
		for m, a in pairs(active) do
			if m.Parent then
				camDist(m, a, clk)
				if not pcall(step, m, a, t) then remove(m) end   -- 何かで失敗した板は外す (エラーが毎フレーム出続けないように)
			else
				remove(m)
			end
		end
	end
	-- 動かす板が1枚もない間は、毎フレームの処理をつながない (何もしない = 軽い)
	local function sync()
		if next(active) ~= nil then
			if not conn then conn = RunService.RenderStepped:Connect(onFrame) end
		elseif conn then
			conn:Disconnect()
			conn = nil
		end
	end
	local function add(m)
		if active[m] or typeof(m) ~= "Instance" or not m:IsA("Model") then return end
		local a = {}
		active[m] = a
		addNo = addNo + 1
		a.n = addNo
		a.pv = (m:GetAttribute("PS_Preview") == true)
		a.c1 = m.ChildAdded:Connect(function() a.parts = nil a.sh = nil a.pt = nil end)
		a.c2 = m.ChildRemoved:Connect(function() a.parts = nil a.sh = nil a.pt = nil end)
		sync()
	end
	function remove(m)
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
		sync()
	end

	for _, m in ipairs(CS:GetTagged(ANIM_TAG)) do add(m) end
	CS:GetInstanceAddedSignal(ANIM_TAG):Connect(add)
	CS:GetInstanceRemovedSignal(ANIM_TAG):Connect(remove)
end
	return applySkin, LOOKS, ANIMCFG, SK
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

	M.ORDER = { "shadow", "light", "fx", "decal", "glass", "post", "bloom", "sky", "terrain", "deco", "gui", "sound", "pbr", "mesh", "material", "quality" }
	M.LABEL = {
		shadow = "影を消す", light = "ライトを切る", fx = "粒・炎・軌跡を止める", decal = "デカール消し",
		glass = "半透明の物を消す", post = "ぼかし系を切る", bloom = "ブルーム・色補正を切る", sky = "雲・大気・星を消す", terrain = "水・草を軽く",
		deco = "草・地形の飾りを消す", gui = "看板・名札(3D表示)を消す", sound = "ループ音(BGM)を止める", pbr = "高画質テクスチャを外す",
		mesh = "メッシュを簡単に", material = "素材を単純化", quality = "画質を最低にする",
	}
	M.onStatus = nil   -- function(text, 0~1) 進行状況をUIに出すための窓口
	M.onChange = nil   -- function(key, wantOn) ON/OFFの選択が変わった時に呼ばれる窓口 (GitHub保存が使う)

	local FX_CLASS = { ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true, Trail = true, Beam = true, Highlight = true }
	local POST_CLASS = { BlurEffect = true, DepthOfFieldEffect = true, SunRaysEffect = true }   -- ブルームは板のネオンのために残す (「ブルーム・色補正を切る」を選んだ時だけ切る)
	local BLOOM_CLASS = { BloomEffect = true, ColorCorrectionEffect = true }

	-- 元の値の保管庫 (消えた物はGCされるように弱参照)
	local function weak() return setmetatable({}, { __mode = "k" }) end
	local store = { shadow = weak(), light = weak(), fx = weak(), decal = weak(), post = weak(), mat = weak(), refl = weak(), gui = weak(), sound = weak(),
		glass = weak(), bloom = weak(), mesh = weak() }
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

	-- ブルーム(光のにじみ)と色補正。板のネオンの光のにじみも消えるので、「ぼかし系を切る」とは別にしてある
	ITEMS.bloom = {
		one = function(inst)
			if BLOOM_CLASS[inst.ClassName] and inst.Enabled then
				store.bloom[inst] = true
				inst.Enabled = false
			end
		end,
		apply = function()
			for _, c in ipairs(Lighting:GetChildren()) do pcall(ITEMS.bloom.one, c) end
			local cam = workspace.CurrentCamera
			if cam then
				for _, c in ipairs(cam:GetChildren()) do pcall(ITEMS.bloom.one, c) end
			end
		end,
		revert = function() restore(store.bloom, function(inst) inst.Enabled = true end) end,
	}

	-- 半透明の部品 (ガラスなど。重なって描くので重い)。見えなくするだけで、当たり判定は変わらない
	ITEMS.glass = {
		one = function(inst)
			if inst:IsA("BasePart") then
				local t = inst.Transparency
				if type(t) == "number" and t > 0 and t < 1 then
					store.glass[inst] = t
					inst.Transparency = 1
				end
			end
		end,
		apply = function(label) walk(ITEMS.glass.one, label) end,
		revert = function() restore(store.glass, function(inst, t) inst.Transparency = t end) end,
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

	-- 地形の飾り (草など) を描かない
	ITEMS.deco = {
		apply = function()
			local T = workspace.Terrain
			if saves.deco == nil then
				local ok, v = pcall(function() return T.Decoration end)
				if ok then saves.deco = { v } end
			end
			setp(T, "Decoration", false)
		end,
		revert = function()
			if saves.deco then
				setp(workspace.Terrain, "Decoration", saves.deco[1])
				saves.deco = nil
			end
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

	-- メッシュの細かさ (RenderFidelity) を「軽さ優先」にする。遠くの形が少し荒くなる
	ITEMS.mesh = {
		one = function(inst)
			if inst:IsA("MeshPart") then
				local ok, rf = pcall(function() return inst.RenderFidelity end)
				if ok and rf ~= Enum.RenderFidelity.Performance then
					store.mesh[inst] = rf
					inst.RenderFidelity = Enum.RenderFidelity.Performance
				end
			end
		end,
		apply = function(label) walk(ITEMS.mesh.one, label) end,
		revert = function() restore(store.mesh, function(inst, rf) inst.RenderFidelity = rf end) end,
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

	-- 画質の段階を最低にする (この端末のゲーム内の画質)。OFFで元の段階へ戻す。変えられない端末では何もしない
	ITEMS.quality = {
		apply = function()
			local ok0, cur = pcall(function() return settings().Rendering.QualityLevel end)
			if not ok0 then
				report("この端末では画質を変えられませんでした", true)
				return
			end
			if saves.quality == nil then saves.quality = { cur } end
			local ok1 = pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
			if not ok1 then
				saves.quality = nil
				report("この端末では画質を変えられませんでした", true)
			end
		end,
		revert = function()
			if saves.quality then
				local q = saves.quality[1]
				saves.quality = nil
				pcall(function() settings().Rendering.QualityLevel = q end)
			end
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
		local before = desired[key] == true
		desired[key] = wantOn and true or false
		if before ~= (desired[key] == true) and M.onChange then pcall(M.onChange, key, desired[key]) end
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
-- (プリセットのボタンが増えても入るように、たてにスクロールできる)
local side = mk("ScrollingFrame", { Name = "Side", ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = isMobile and 0 or 3, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.45, ElasticBehavior = Enum.ElasticBehavior.Never, Position = UDim2.fromOffset(12, 68), Size = UDim2.fromOffset(SIDE_W, H - 68 - 58) }, win)
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
local UIs = { set = {}, pv = {}, mk = {}, touch = function() end }   -- ページをまたいで触るUI部品 (質感ページのトグル・スライダーなど)。set[命令の種類] = その値に画面の表示を合わせる関数
-- pv = プレビューの状態 (pv.model = プレビュー中の板) / mk = 「選んだボタンの印」を付け外しする関数の置き場 (mk.look(i) など。0 で印を消す)
-- touch(名前) = 「GitHubに保存する物が変わった」と知らせる窓口 ("perm" 永久保存 / "presets" プリセット / "ui" UI設定 / "opt" 軽量化)。後ろの GitHub保存 が本物に差し替える
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
local spinOn = true
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
-- いま操作の対象になる板。プレビュー中は「プレビューの板」、そうでなければ選んでいる本物の板
local function targetModel()
	local pm = UIs.pv.model
	if pm then return pm.Parent and pm or nil end
	return selected and seenMap[selected] or nil
end

-- 検出するのは「Workspace/<自分の@ID(ユーザー名)>SpawnedInToys」の直下にある PalletLightBrown (Model) だけ。
-- 他のフォルダ・他プレイヤーのフォルダ・フォルダの外にある板は見ない。フォルダの自動作成もしない。
local function myFolder()
	return workspace:FindFirstChild(toyFolderName())
end

-- この板は、自分のフォルダの直下にあるか (板が出た時の処理で使う)
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
		if not UIs.pv.model then   -- (プレビュー中は、画面の表示はプレビューの板のものなので、そのまま)
			for _, fn in ipairs(resetters) do pcall(fn) end
		end
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
	if model == UIs.pv.model then   -- プレビューの板は、この画面の中だけで反映する (サーバーには送らない)
		local ok, res = pcall(applySkin, model, kind, value)
		if UIs.pv.changed then pcall(UIs.pv.changed) end
		if ok and type(res) == "string" and not quiet then Lib.notif(gui, res, 1.2) end
		return
	end
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

-- 操作を送る前に、画面側の状態を合わせる (1つずつ送る時も、まとめて送る時も同じ)
local function noteKind(kind, value)
	if UIs.onKind then pcall(UIs.onKind, kind, value) end   -- 「選んだボタンの印」を、いまの状態に合わせる
	if kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" or kind == "GradientClear" or kind == "Reset" or (kind == "Rainbow" and value == true) then
		gradLive = false   -- サーバー側でグラデーションが外れる操作
		if UIs.refHint then UIs.refHint() end
	end
	if UIs.rbT and (kind == "Color" or kind == "HSV" or kind == "RGB" or kind == "Look" or kind == "Preset" or kind == "Gradient") then
		UIs.rbT:set(false)   -- サーバー側でレインボーが止まるので、スイッチの表示も合わせる
	end
end
local function send(kind, value, quiet)
	local idx = selected
	local model = targetModel()
	if not model or not model.Parent then
		Lib.notif(gui, "板を選んでください", 1.8)
		return
	end
	if not UIs.pv.model then dirty[idx] = (kind ~= "Reset") or nil end
	noteKind(kind, value)
	record(model, kind, value)
	selVisuals()
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

-- 「選んだボタン」の印をつける部品。mark(i) で i番を光らせる (0 で全部消す)。click(i, 押した時, 解除する時) は、
-- すでに光っているボタンをもう一度押したら「解除」、そうでなければ「選ぶ」。ボタンは add(b) で登録する (style: "card" か "swatch")
local function markGroup(style)
	local g = { btns = {}, sel = 0 }
	function g.add(b)
		local sw = (style == "swatch")
		mk("TextLabel", {
			Name = "Check", BackgroundTransparency = 1, Text = "✔", TextSize = sw and 18 or 15, FontFace = FONT, TextColor3 = WHITE, TextTransparency = 1,
			TextStrokeTransparency = 1, TextStrokeColor3 = Color3.new(0, 0, 0), AnchorPoint = sw and Vector2.new(0.5, 0.5) or Vector2.new(1, 0),
			Position = sw and UDim2.fromScale(0.5, 0.5) or UDim2.new(1, -6, 0, 3), Size = UDim2.fromOffset(20, 20), ZIndex = 5,
		}, b)
		g.btns[#g.btns + 1] = b
		return #g.btns
	end
	local shown = {}   -- ボタンごとの「いま光っているか」。最初は不明 (1回目は全部そろえる)。2回目からは、変わったボタンだけ動かす (数十個を毎回動かさない)
	function g.mark(i)
		g.sel = i
		for j, b in ipairs(g.btns) do
			local on = (j == i)
			if shown[b] ~= on then
				shown[b] = on
				local stk = b:FindFirstChildOfClass("UIStroke")
				local ck = b:FindFirstChild("Check")
				if style == "swatch" then
					if stk then Lib.tween(stk, { Thickness = on and 3.5 or 1.5, Transparency = on and 0 or 0.3 }, 0.2) end
				else
					Lib.tween(b, { BackgroundColor3 = on and Lib.ACCENT or WHITE, BackgroundTransparency = on and 0.2 or 0.84 }, 0.2)
					if stk then Lib.tween(stk, { Thickness = on and 2.5 or 1, Transparency = on and 0 or 0.58, Color = on and WHITE or Lib.GRAY }, 0.2) end
				end
				if ck then Lib.tween(ck, { TextTransparency = on and 0 or 1, TextStrokeTransparency = (on and style == "swatch") and 0.35 or 1 }, 0.2) end
			end
		end
	end
	function g.click(i, onPick, onRelease)
		if g.sel == i and onRelease then
			g.mark(0)
			onRelease(i)
		else
			g.mark(i)
			onPick(i)
		end
	end
	if style ~= "swatch" then
		Lib.onTheme(function(a) local b = g.btns[g.sel] if b then b.BackgroundColor3 = a end end)
	end
	return g
end

-- 選択ボタン (1つだけ選ばれる) を、perRow 個ずつ折り返して並べる。行をまたいでも1つだけ。選ぶ関数 mark(i) を返す
-- rel を渡すと、いま光っているボタンをもう一度押した時に、rel番(ふつうは初期の番号。0 なら「どれも選ばない」)に戻る (解除)。onPick(番号, 解除で戻ったか)
local function chipsGrid(e, labels, perRow, onPick, initial, rel)
	local btns, sel = {}, initial
	local shown = {}   -- ボタンごとの「いま光っているか」。変わったボタンだけ動かす
	local function mark(i)
		sel = i
		for j, b in ipairs(btns) do
			local active = (j == i)
			if shown[b] ~= active then
				shown[b] = active
				Lib.tween(b, { BackgroundColor3 = active and Lib.ACCENT or WHITE, BackgroundTransparency = active and 0.15 or 0.88 }, 0.2)
			end
		end
	end
	local n = #labels
	local i = 0
	for _ = 1, math.ceil(n / perRow) do
		local r = e:row(isMobile and 34 or 32)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, r)
		for _ = 1, math.min(perRow, n - i) do
			i = i + 1
			local k = i
			local b = mk("TextButton", { AutoButtonColor = false, Text = labels[k], TextSize = isMobile and 12 or 14, FontFace = FONT, TextColor3 = WHITE, TextWrapped = true, LayoutOrder = k, Size = UDim2.new(1 / perRow, -5, 1, 0) }, r)
			Lib.glass(b, 0.88, 10)
			Lib.juice(b)
			b.MouseButton1Click:Connect(function()
				if rel ~= nil and sel == k and k ~= rel then   -- 光っているボタンをもう一度 = 解除 (初期に戻す)
					mark(rel)
					onPick(rel, true)
				else
					mark(k)
					onPick(k)
				end
			end)
			btns[k] = b
		end
	end
	mark(initial)
	Lib.onTheme(function(a) if btns[sel] then btns[sel].BackgroundColor3 = a end end)
	return mark
end
local function chipsRow(e, labels, onPick, initial, rel)
	return chipsGrid(e, labels, #labels, onPick, initial, rel)
end
-- 命令の値に合わせて、画面のスライダーやボタンの表示を動かす (板には何も送らない)
local function syncUI(ops)
	for _, op in ipairs(ops) do
		local f = UIs.set[op[1]]
		if f then pcall(f, op[2]) end
	end
end
-- 押すとその場で何かが起きるカードを並べる (選んだ状態は持たない)。items = { {名前, 色1, 色2}, ... } / onPick(番号)
-- 並べた行と、カードのボタン一覧を返す
-- onRelease を渡すと、押したカードが光り (選んだ印)、光っているカードをもう一度押すと onRelease(番号) で解除になる
local function cardGrid(e, items, cols, cw, ch, onPick, onRelease)
	local row = e:row(gridHeight(#items, cols, ch, 8))
	grid(row, cw, ch, 8, 8)
	local btns = {}
	local grp = onRelease and markGroup("card") or nil
	for i, it in ipairs(items) do
		local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i, Visible = true }, row)
		Lib.glass(b, 0.84, 14)
		local pad = 0
		if it[2] then
			local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(ch - 12, ch - 12) }, b)
			corner(sw, 10)
			local c1 = it[2]
			mk("UIGradient", { Rotation = 35, Color = ColorSequence.new(c1, it[3] or Color3.new(c1.R * 0.5, c1.G * 0.5, c1.B * 0.5)) }, sw)
			pad = ch - 6
		end
		local lbl = text(b, it[1], isMobile and 12 or 14, UDim2.fromOffset(pad + 6, 0), UDim2.new(1, -(pad + 8), 1, 0), Enum.TextXAlignment.Left)
		lbl.TextWrapped = true
		Lib.juice(b)
		if grp then
			grp.add(b)
			b.MouseButton1Click:Connect(function() grp.click(i, onPick, onRelease) end)
		else
			b.MouseButton1Click:Connect(function() onPick(i) end)
		end
		btns[i] = b
	end
	return row, btns, grp
end
-- 選んでいる板に、操作をまとめて1回で送る (ワンタップのセット用)。画面の表示も合わせる。成功したら true
local function sendBatch(ops)
	local idx = selected
	local model = targetModel()
	if not model or not model.Parent then
		Lib.notif(gui, "板を選んでください", 1.8)
		return false
	end
	if not UIs.pv.model then dirty[idx] = true end
	for _, op in ipairs(ops) do noteKind(op[1], op[2]) end
	sendMany(model, ops, true)
	syncUI(ops)
	selVisuals()
	return true
end
-- 選んだボタンの解除: 指定した種類の操作を履歴から外して、板を「元に戻す + 残りの操作をもう一度」で作り直す
-- (ほかの操作の結果は、そのまま残る。作り直しは1回の通信にまとめて送る)
UIs.replay = function(kinds)
	local model = targetModel()
	if not model or not model.Parent then
		Lib.notif(gui, "板を選んでください", 1.8)
		return false
	end
	local keep = {}
	for _, op in ipairs(recipe[model] or {}) do
		if not kinds[op[1]] then keep[#keep + 1] = { op[1], op[2] } end
	end
	for _, fn in ipairs(resetters) do pcall(fn) end   -- 画面の表示も、いったん初期へ (残った操作のぶんは、下で合わせ直す)
	local ops = { { "Reset" } }
	for _, op in ipairs(keep) do ops[#ops + 1] = op end
	return sendBatch(ops)
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
		local swGrp, swCols = markGroup("swatch"), {}
		UIs.mk.swatch = swGrp.mark
		for i, c in ipairs(colors) do
			local col = Color3.fromRGB(c[1], c[2], c[3])
			swCols[i] = col
			local s = mk("TextButton", { AutoButtonColor = false, BorderSizePixel = 0, Text = "", BackgroundColor3 = col, LayoutOrder = i }, row)
			corner(s, 11)
			stroke(s, 0.3, WHITE, 1.5)
			Lib.juice(s)
			swGrp.add(s)
			-- 色のボタン: 押すと色がつき、印が出る。もう一度押すと、その色をやめる (その前の見た目に戻る)
			s.MouseButton1Click:Connect(function()
				swGrp.click(i, function() send("Color", col) swGrp.mark(i) end, function()
					UIs.replay({ Color = true })
				end)
			end)
		end
		UIs.set.Color = function(c)   -- 色が決まった時 (まとめて送った時も) 同じ色のボタンに印をつける。なければ印を消す
			local hit = 0
			if typeof(c) == "Color3" then
				for i, x in ipairs(swCols) do
					if math.abs(x.R - c.R) + math.abs(x.G - c.G) + math.abs(x.B - c.B) < 0.004 then hit = i break end
				end
			end
			swGrp.mark(hit)
		end
		onResettable(function() swGrp.mark(0) end)
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
		local gGrp = markGroup("card")
		UIs.mk.gradp = gGrp.mark
		onResettable(function() gGrp.mark(0) end)
		UIs.gradMatch = function(v)   -- 送ったグラデーションが、おすすめのどれと同じか (同じ色の組み合わせ)
			local function same(x, y) return (x == nil and y == nil) or (x ~= nil and y ~= nil and math.abs(x.R - y.R) + math.abs(x.G - y.G) + math.abs(x.B - y.B) < 0.004) end
			for i, g in ipairs(GRADS) do
				if type(v) == "table" and same(v.a, g[2]) and same(v.b, g[3]) and same(v.c, g[4]) then return i end
			end
			return 0
		end
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
			gGrp.add(b)
			b.MouseButton1Click:Connect(function()
				gGrp.click(i, function()
					gA, gB, gC = g[2], g[3], g[4]
					gMid = 0.5
					if midS then midS:set(0.5) end
					showPreview()
					sendGrad(true)
					gGrp.mark(i)   -- (送ると、手で調整したことになって印が消えるので、おすすめを押した時はつけ直す)
				end, function()   -- もう一度押した = やめる (グラデーションをつける前の見た目に戻る)
					gFlowOn = false
					flowT:set(false)
					gradLive = false
					UIs.replay({ Gradient = true, GradientClear = true })
				end)
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
	-- まとめて送った時 (おまかせ・保存したプリセットなど) に、グラデーションの画面も合わせる
	UIs.set.Gradient = function(v)
		if type(v) ~= "table" then return end
		gA, gB, gC = v.a or gA, v.b or gB, v.c
		gAxis, gRev, gMid = v.axis or "X", v.rev == true, v.mid or 0.5
		gStripes, gTopFlip = v.stripes or 0, v.topFlip == true
		gFlowOn, gFlowSpeed = (v.flow or 0) > 0, (v.flow or 0) > 0 and v.flow or gFlowSpeed
		hueA:set((gA:ToHSV())) hueB:set((gB:ToHSV())) hueC:set(gC and (gC:ToHSV()) or 0.33)
		axisMark(({ X = 1, Y = 2, Z = 3 })[gAxis] or 1)
		revT:set(gRev) midS:set(gMid) topT:set(gTopFlip)
		stripeMark(({ [0] = 1, [2] = 2, [3] = 3, [4] = 4, [6] = 5, [8] = 6 })[gStripes] or 1)
		flowT:set(gFlowOn) flowS:set(gFlowSpeed)
		gradLive = true
		showPreview()
		if UIs.mk.gradp then UIs.mk.gradp(UIs.gradMatch and UIs.gradMatch(v) or 0) end
	end
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
	local perRow = isMobile and 3 or 4
	local matCols = isMobile and 2 or 3
	local matCW = isMobile and 124 or 154
	-- 素材の入れ方: 1 いまの色を残す (Look) / 2 素材の色にする (LookRaw) / 3 素材だけ・色も光もそのまま (LookKeep)
	local lookMode = 1
	local LOOK_KIND = { "Look", "LookRaw", "LookKeep" }
	local curMat = nil    -- いま印がついている素材の名前
	local matGrp          -- 素材カードの印 (下でカードを作る時に入る)
	local function matIndex(name)
		for i, m in ipairs(mats) do
			if m[1] == name then return i end
		end
		return 0
	end
	local function pickLook(name)
		curMat = name
		send(LOOK_KIND[lookMode], name)
		if UIs.afterLook then UIs.afterLook(true) end
	end
	local function releaseLook()   -- 印がついた素材をもう一度押した: 素材と質感を元に戻す (自分で決めた色は残る)
		curMat = nil
		send("LookClear", nil)
		if UIs.afterLook then UIs.afterLook(false) end
		if UIs.texT and not gradLive then UIs.texT:set(true) end
	end
	-- 分類 (1つの素材が、いくつかの分類に入ってもよい): 2 自然 / 3 石・土 / 4 金属 / 5 ガラス・氷 / 6 日用品 / 7 光る
	local inCat = {}
	for c, names in pairs({
		[2] = { "Wood", "WoodPlanks", "Sand", "Mud", "Snow" },
		[3] = { "Marble", "Granite", "Slate", "Concrete", "Brick", "Cobblestone", "Basalt", "Pebble", "Limestone", "Sandstone", "Plaster", "CeramicTiles" },
		[4] = { "Metal", "DiamondPlate", "Foil", "CorrodedMetal" },
		[5] = { "Glass", "Ice", "Glacier", "ForceField" },
		[6] = { "Plastic", "SmoothPlastic", "Fabric", "Carpet", "Leather", "Rubber", "Cardboard" },
		[7] = { "Neon", "CrackedLava", "ForceField" },
	}) do
		for _, nm in ipairs(names) do
			inCat[nm] = inCat[nm] or {}
			inCat[nm][c] = true
		end
	end

	e:title("素材の入れ方")
	local MODE_TEXT = {
		"🎨 色は残す: 自分で決めた色・グラデーションはそのままで、素材と質感だけ変わります。色をまだ決めていない板は、素材の色になります。",
		"🧱 素材の色に: 素材ごとの色・質感・光にします。いまの色・グラデーションは消えます。",
		"🔒 素材だけ: 色も光もそのまま、素材の模様と質感だけ変わります。",
	}
	local modeNote = e:row(isMobile and 70 or 46)
	local modeLbl = text(modeNote, MODE_TEXT[1], isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	modeLbl.TextWrapped = true
	local modeMark = chipsRow(e, { "🎨 色は残す", "🧱 素材の色に", "🔒 素材だけ" }, function(i)
		lookMode = i
		modeLbl.Text = MODE_TEXT[i]
		if curMat then pickLook(curMat) end   -- もう素材を選んでいたら、新しい入れ方でやり直す
	end, 1)
	local cards, matRow
	local function showCat(c)
		local n = 0
		for i, m in ipairs(mats) do
			local ok = (c == 1) or (inCat[m[1]] ~= nil and inCat[m[1]][c] == true)
			cards[i].Visible = ok
			if ok then n = n + 1 end
		end
		matRow.Size = UDim2.new(1, 0, 0, n > 0 and gridHeight(n, matCols, 56, 8) or 0)
	end
	local catMark = chipsGrid(e, { "すべて", "🌲 自然", "🪨 石・土", "⚙️ 金属", "🔮 ガラス・氷", "🧴 日用品", "💡 光る" }, perRow, showCat, 1)
	e:button("🎲 ランダムな素材にする", function()
		local pool = {}
		for i, m in ipairs(mats) do
			if cards[i].Visible then pool[#pool + 1] = m[1] end
		end
		if #pool > 0 then
			local nm = pool[math.random(#pool)]
			pickLook(nm)
			if matGrp then matGrp.mark(matIndex(nm)) end
		end
	end, ACCENT)
	local items = {}
	for i, m in ipairs(mats) do items[i] = { m[2], m[3] } end
	matRow, cards, matGrp = cardGrid(e, items, matCols, matCW, 56, function(i) pickLook(mats[i][1]) matGrp.mark(i) end, releaseLook)
	UIs.mk.look = function(i) matGrp.mark(i) if i == 0 then curMat = nil end end
	local function setLookMark(v) curMat = v matGrp.mark(matIndex(v)) end   -- まとめて送った時に、素材の印を合わせる
	UIs.set.Look, UIs.set.LookRaw, UIs.set.LookKeep = setLookMark, setLookMark, setLookMark
	UIs.set.LookClear = function() curMat = nil matGrp.mark(0) end

	-- ツートン: 板の一部だけ、別の素材 (と色) にする
	e:title("ツートン (板の一部だけ別の素材に)")
	local TWO_MODES = { "Top", "Bottom", "Half1", "Half2", "Stripe", "Outer", "Random" }
	local twoMode, twoSame, twoMat = 1, false, nil
	local function sendTwo()
		if not twoMat then return end
		send("TwoTone", { mat = twoMat, mode = TWO_MODES[twoMode], same = twoSame or nil })
	end
	local twoMark = chipsGrid(e, { "⬆ 上", "⬇ 下", "◀ 前半", "▶ 後半", "▥ 1本おき", "▣ まわり", "🎲 ランダム" }, perRow, function(i)
		twoMode = i
		sendTwo()
	end, 1)
	local twoColMark = chipsRow(e, { "その素材の色", "今の色のまま" }, function(i)
		twoSame = (i == 2)
		sendTwo()
	end, 1)
	e:title("↓ 素材を押すと、選んだ部分だけ変わります")
	do
		local twoItems = {}
		for _, nm in ipairs({ "Metal", "Glass", "Neon", "Marble", "Foil", "Ice", "Rubber", "Leather", "Brick", "Granite", "DiamondPlate", "CrackedLava" }) do
			for i, m in ipairs(mats) do
				if m[1] == nm then twoItems[#twoItems + 1] = { items[i], m[1] } end
			end
		end
		if #twoItems > 0 then
			local list = {}
			for i, t in ipairs(twoItems) do list[i] = t[1] end
			local _, _, tg = cardGrid(e, list, matCols, matCW, 56, function(i)
				twoMat = twoItems[i][2]
				sendTwo()
			end, function()   -- もう一度押した = ツートンをやめる
				twoMat = nil
				send("TwoToneClear", nil)
			end)
			UIs.mk.two = tg.mark
			UIs.set.TwoTone = function(v)   -- まとめて送った時
				if type(v) ~= "table" then return end
				twoMat = v.mat
				local hit = 0
				for i, t in ipairs(twoItems) do
					if t[2] == v.mat then hit = i end
				end
				tg.mark(hit)
				for i, nm in ipairs(TWO_MODES) do
					if nm == v.mode then twoMode = i twoMark(i) end
				end
				twoSame = (v.same == true)
				twoColMark(twoSame and 2 or 1)
			end
		end
	end
	e:button("ツートンをやめる (ぜんぶ同じ素材に戻す)", function()
		twoMat = nil
		if UIs.mk.two then UIs.mk.two(0) end
		send("TwoToneClear", nil)
	end)
	local mtip = e:row(isMobile and 58 or 40)
	local mtipLbl = text(mtip, "素材のあとに色を変えても大丈夫です (素材は残ります)。光っているボタンをもう一度押すと、その素材をやめられます。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	mtipLbl.TextWrapped = true

	UIs.set.TwoToneClear = function() twoMat = nil if UIs.mk.two then UIs.mk.two(0) end end
	onResettable(function()
		lookMode = 1
		modeMark(1)
		modeLbl.Text = MODE_TEXT[1]
		curMat = nil
		matGrp.mark(0)
		if UIs.mk.two then UIs.mk.two(0) end
		catMark(1)
		showCat(1)
		twoMode, twoSame, twoMat = 1, false, nil
		twoMark(1)
		twoColMark(1)
	end)
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
	local pGrp, pIdOf, pIdx = markGroup("card"), {}, {}   -- プリセットの印 (「見た目一式」と「基本」を通して、1つだけ)
	UIs.mk.preset = pGrp.mark
	UIs.set.Preset = function(id) pGrp.mark(pIdx[id] or 0) end
	onResettable(function() pGrp.mark(0) end)
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
			local at = pGrp.add(b)
			pIdx[p[1]] = at
			pIdOf[at] = p[1]
			b.MouseButton1Click:Connect(function()
				pGrp.click(at, function()
					if p[5] then for _, fn in ipairs(resetters) do pcall(fn) end end   -- 一式は光・効果も入れ替わるので、画面の表示も初期位置へ
					send("Preset", p[1])
					if UIs.afterLook then UIs.afterLook(p[5] == true) end
					pGrp.mark(at)   -- (画面を初期へ戻した時に印も消えるので、つけ直す)
				end, function()   -- もう一度押した = そのプリセットをやめる (つける前の見た目に戻る)
					UIs.replay({ Preset = true })
				end)
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
		ops[#ops + 1] = { "GlossStyle", rnd(8) }
		ops[#ops + 1] = { "GlossSky", rnd(6) }
		if rnd() < 0.4 then
			ops[#ops + 1] = { "SheenColor", rnd(3) }
			ops[#ops + 1] = { "Sheen", 0.2 + rnd() * 0.6 }
		end
		if rnd() < 0.5 then ops[#ops + 1] = { "Edge", 0.3 + rnd() * 0.6 } end
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
			if rnd() < 0.35 then
				ops[#ops + 1] = { "GlowHue2", rnd() }
				ops[#ops + 1] = { "GlowMode", pick({ "Blend", "Alt", "Hue" }) }
				ops[#ops + 1] = { "GlowSpeed", 0.2 + rnd() * 0.7 }
			end
			if rnd() < 0.5 then
				ops[#ops + 1] = { "Pulse", 0.25 + rnd() * 1.2 }
				ops[#ops + 1] = { "PulseStyle", pick({ "Sine", "Beat", "Flicker", "Breath", "Neon", "Saw", "Steps" }) }   -- (ピカピカ・雷・SOS は、急に強く光るので、おまかせには入れない)
				ops[#ops + 1] = { "PulseDepth", 0.4 + rnd() * 0.6 }
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
		local m = targetModel()
		if not m or not m.Parent then
			Lib.notif(gui, "板を選んでください", 1.8)
			return
		end
		for _, fn in ipairs(resetters) do pcall(fn) end
		local ops = randomOps()
		sendMany(m, ops, true)
		syncUI(ops)   -- 画面のスライダーやボタンも、決まった値に合わせる
		if not UIs.pv.model then dirty[selected] = true end
		selVisuals()
		Lib.notif(gui, "おまかせスタイルにしました 🎲 (気に入らなければ、もう一度)", 2)
		if UIs.afterLook then UIs.afterLook(true) end
	end, ACCENT)
	e:button("📋 この板の見た目を、ほかの全部の板にコピー", function()
		if UIs.pv.model then
			Lib.notif(gui, "プレビュー中は使えません。プレビューを閉じてから押してね", 2)
			return
		end
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
	local perRow = isMobile and 3 or 4
	local curRefl, wthVal = 0, 0
	local refS, traS, varS, wthS, texT, quickMark, glossMark, axisMark
	local skyMark, sheenS, scMark, edgeS, wkMark, updateHint
	local envOrig = nil   -- 「空の映り込み」を強くする前の値 (この画面だけの設定)
	-- 反射の量に合うチップを光らせる (どれにも当てはまらなければ、どれも光らない)
	local function qm()
		if not quickMark then return end
		quickMark(curRefl <= 0 and 1 or (math.abs(curRefl - 0.35) < 0.005 and 2) or (curRefl >= 0.995 and 3) or 0)
	end

	-- 質感のセット: 素材・色・木目はそのまま。ツヤ・映り込み・光の走り・角・経年だけを、一式で切り替える
	-- refl 反射 / gs ツヤの種類 / sky 空 / sheen 光の走り / sc その色 / edge 角 / var 色ムラ / wea 経年 / wk 経年の種類
	do
		local DEF = { refl = 0, gs = 1, sky = 1, sheen = 0, sc = 1, edge = 0, var = 0, wea = 0, wk = 1 }
		local function C(r, g, b) return Color3.fromRGB(r, g, b) end
		local SETS = {
			{ "🪞 鏡面ミラー", C(235, 240, 250), C(120, 140, 170), { refl = 1, gs = 1, sky = 1, edge = 0.3 } },
			{ "💧 ウェット", C(150, 210, 255), C(40, 90, 150), { refl = 0.7, gs = 5, sky = 1 } },
			{ "🍬 キャンディ", C(255, 150, 205), C(255, 230, 245), { refl = 0.55, gs = 7, sky = 6, sheen = 0.3, edge = 0.25 } },
			{ "🫧 パール", C(245, 240, 255), C(190, 170, 230), { refl = 0.6, gs = 6, sky = 1, sheen = 0.35, edge = 0.35 } },
			{ "💎 ダイヤ", C(200, 240, 255), C(255, 200, 250), { refl = 0.85, gs = 8, sky = 6, sheen = 0.6, sc = 3, edge = 0.9 } },
			{ "🌃 ネオンナイト", C(255, 90, 210), C(40, 30, 110), { refl = 0.7, gs = 1, sky = 4, sheen = 0.5, sc = 3, edge = 0.8 } },
			{ "🌅 夕焼けミラー", C(255, 170, 110), C(120, 80, 170), { refl = 0.8, gs = 2, sky = 2, sheen = 0.2, sc = 2 } },
			{ "🔩 ブラッシュ金属", C(200, 205, 215), C(100, 106, 120), { refl = 0.55, gs = 4, sky = 6, edge = 0.4 } },
			{ "🧽 つや消し", C(170, 170, 175), C(90, 90, 100), { refl = 0, gs = 2 } },
			{ "🧪 さびてボロボロ", C(190, 110, 60), C(80, 50, 35), { refl = 0, gs = 2, var = 0.4, wea = 0.8, wk = 2 } },
			{ "🌿 こけむす", C(110, 170, 70), C(40, 80, 40), { refl = 0, gs = 2, var = 0.3, wea = 0.7, wk = 3 } },
			{ "❄️ 雪化粧", C(250, 252, 255), C(170, 200, 235), { refl = 0.1, gs = 2, var = 0.1, wea = 0.7, wk = 4 } },
		}
		e:title("質感のセット (素材・色はそのまま。押すだけ)")
		local items = {}
		for i, st in ipairs(SETS) do items[i] = { st[1], st[2], st[3] } end
		local function setOps(v)
			return {
				{ "Reflectance", v.refl }, { "GlossStyle", v.gs }, { "GlossSky", v.sky }, { "SheenColor", v.sc }, { "Sheen", v.sheen },
				{ "Edge", v.edge }, { "Variance", v.var }, { "WeatherKind", v.wk }, { "Weather", v.wea },
			}
		end
		local _, _, sg = cardGrid(e, items, isMobile and 2 or 3, isMobile and 124 or 154, 48, function(i)
			local v = {}
			for k, d in pairs(DEF) do v[k] = d end
			for k, x in pairs(SETS[i][4]) do v[k] = x end
			if sendBatch(setOps(v)) then
				Lib.notif(gui, SETS[i][1] .. " にしました", 1.4)
			end
		end, function(i)   -- もう一度押した = このセットをやめる (ツヤ・映り込み・光の走り・角・経年が、初期にもどる。素材・色はそのまま)
			if sendBatch(setOps(DEF)) then
				Lib.notif(gui, SETS[i][1] .. " をやめました", 1.4)
			end
		end)
		onResettable(function() sg.mark(0) end)
	end

	e:title("反射・ツヤ (素材や木目はそのまま)")
	local reflNote = e:row(isMobile and 78 or 54)
	local reflLbl = text(reflNote, "", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	reflLbl.TextWrapped = true
	updateHint = function()
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
	end, 1, 1)
	e:title("ツヤの種類 (8種類)")
	glossMark = chipsGrid(e, { "くっきり", "やわらか", "ガラス", "メタル", "ウェット", "パール", "ニス", "ダイヤ" }, perRow, function(i)
		send("GlossStyle", i)
	end, 1, 1)
	e:title("ツヤの向き")
	axisMark = chipsRow(e, { "横 (X)", "高さ (Y)", "奥 (Z)" }, function(i)
		send("GlossAxis", ({ "X", "Y", "Z" })[i])
	end, 1, 1)
	e:title("映り込む空")
	skyMark = chipsGrid(e, { "☀️ 昼", "🌇 夕焼け", "🌙 夜", "🌃 ネオン街", "🌌 オーロラ", "💡 スタジオ" }, 3, function(i)
		send("GlossSky", i)
	end, 1, 1)
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

	e:title("光が走る・角のきらめき")
	sheenS = e:slider("光の走り", 0, 1, function(v, r) sendThrottled("Sheen", v, r) end, 0, Color3.fromRGB(70, 80, 190), Color3.fromRGB(255, 255, 255))
	scMark = chipsRow(e, { "白い光", "金色の光", "虹色の光" }, function(i) send("SheenColor", i) end, 1, 1)
	edgeS = e:slider("角の輝き", 0, 1, function(v, r) sendThrottled("Edge", v, r) end, 0, Color3.fromRGB(70, 80, 190), Color3.fromRGB(255, 255, 255))

	e:title("見た目")
	traS = e:slider("透明度", 0, 0.9, function(v, r) sendThrottled("Transparency", v, r) end, 0)
	varS = e:slider("色ムラ", 0, 1, function(v, r) sendThrottled("Variance", v, r) end, 0, Color3.fromRGB(99, 102, 241), PINK)
	wthS = e:slider("経年劣化", 0, 1, function(v, r)
		wthVal = v
		sendThrottled("Weather", v, r)
	end, 0, Color3.fromRGB(120, 100, 70), Color3.fromRGB(60, 50, 40))
	wkMark = chipsRow(e, { "汚れ", "さび", "こけ", "雪", "焦げ" }, function(i, released)
		if not released and wthVal <= 0 then   -- 経年劣化が0だと違いが見えないので、自動で少し付ける
			wthVal = 0.5
			wthS:set(0.5)
			send("Weather", 0.5, true)
		end
		send("WeatherKind", i)
	end, 1, 1)
	e:title("テクスチャ")
	texT = e:toggle("元の木目テクスチャ", function(sv) send("Texture", sv) end, true)

	-- 素材/プリセットを押したあと: 板の本当の値を読み直してスライダーに合わせる (表示と見た目をずらさない)
	local function syncFromBoard()
		local m = targetModel()
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

	-- まとめて送った時 (セット・おまかせ) に、画面の表示を合わせる
	local S = UIs.set
	S.Reflectance = function(v) curRefl = v refS:set(v) qm() updateHint() end
	S.GlossStyle = function(v) glossMark(v) end
	S.GlossAxis = function(v) axisMark(({ X = 1, Y = 2, Z = 3 })[v] or 1) end
	S.GlossSky = function(v) skyMark(v) end
	S.Sheen = function(v) sheenS:set(v) end
	S.SheenColor = function(v) scMark(v) end
	S.Edge = function(v) edgeS:set(v) end
	S.Transparency = function(v) traS:set(v) end
	S.Variance = function(v) varS:set(v) end
	S.Weather = function(v) wthVal = v wthS:set(v) end
	S.WeatherKind = function(v) wkMark(v) end
	S.Texture = function(v) texT:set(v == true) end

	onResettable(function()
		curRefl, wthVal = 0, 0
		refS:set(0) traS:set(0) varS:set(0) wthS:set(0) texT:set(true)
		glossMark(1) axisMark(1) skyMark(1) scMark(1) wkMark(1)
		sheenS:set(0) edgeS:set(0)
		qm()
		updateHint()
	end)
end

-- 5: 光
do
	local e = Lib.element(pages[5])
	local glowVal, pulseVal, bodyOn = 0, 0, false
	local glowS, rangeS, glowHueS, hue2S, gspS, modeMark, pulseS, tempoMark, styleMark, depthS, bodyT, waveS, nightT
	local shapeMark, spotS, neonT, ot, outHueS, auraS, shadowT
	local PULSE_IDS = { "Sine", "Beat", "Flicker", "Strobe", "Breath", "Lightning", "Neon", "Saw", "Steps", "SOS" }
	local MODE_IDS = { "Solid", "Blend", "Alt", "Hue" }
	local SHAPE_IDS = { "Point", "Down", "Up" }
	local function idxOf(list, v)
		for i, x in ipairs(list) do
			if x == v then return i end
		end
		return 1
	end
	-- 光が0だと見えない動きを触った時は、自動で光をつける
	local function ensureGlow()
		if glowVal <= 0 then
			glowVal = 1.5
			glowS:set(1.5)
			send("Glow", 1.5, true)
		end
	end
	local function pulseTo(v, r)
		pulseVal = v
		if v > 0 then ensureGlow() end
		sendThrottled("Pulse", v, r)
	end

	-- 光のレシピ: 光の設定を一式で切り替える (縁取りは ol がある時だけ)
	-- g 強さ / rg 範囲 / h 色 / h2 2つ目の色 / gm 色の動き(1単色 2ゆっくり 3パッと 4虹) / gs 色の速さ / p 明滅の速さ / ps 明滅の型(1〜10)
	-- pd 深さ / pb 板も明滅 / pw 波 / n 夜だけ / sh 向き(1全方向 2下 3上) / sp スポット幅 / ol 縁取りの色 / of オーラ
	do
		local DEF = { g = 0, rg = 8, h = 0.58, h2 = 0.08, gm = 1, gs = 0.3, p = 0, ps = 1, pd = 1, pb = false, pw = 0, n = false, sh = 1, sp = 120 }
		local function C(r, g, b) return Color3.fromRGB(r, g, b) end
		local RECIPES = {
			{ "🕯 キャンドル", C(255, 200, 90), C(255, 120, 30), { g = 1.6, rg = 11, h = 0.09, p = 1.4, ps = 3, pd = 0.4 } },
			{ "🔥 たいまつ", C(255, 150, 40), C(220, 50, 20), { g = 2.8, rg = 14, h = 0.07, h2 = 0.13, gm = 2, gs = 0.9, p = 2.2, ps = 3, pd = 0.55 } },
			{ "💓 ハートビート", C(255, 90, 140), C(190, 20, 70), { g = 2.4, rg = 12, h = 0.97, p = 1.1, ps = 2, pd = 0.85, pb = true } },
			{ "🚨 パトランプ", C(255, 60, 60), C(60, 110, 255), { g = 3.4, rg = 18, h = 0, h2 = 0.62, gm = 3, gs = 1.2 } },
			{ "🌃 ネオンサイン", C(255, 80, 220), C(60, 230, 255), { g = 3, rg = 14, h = 0.88, h2 = 0.5, gm = 2, gs = 0.45, p = 0.8, ps = 7, pd = 0.8, ol = 0.88, of = 0.25 } },
			{ "🌌 オーロラ", C(90, 255, 180), C(170, 90, 255), { g = 2.2, rg = 20, h = 0.42, h2 = 0.78, gm = 2, gs = 0.22, p = 0.35, ps = 5, pd = 0.5 } },
			{ "🌈 レインボー", C(255, 90, 90), C(90, 140, 255), { g = 2.4, rg = 14, gm = 4, gs = 0.35 } },
			{ "🪩 ディスコ", C(255, 120, 230), C(120, 255, 255), { g = 3.4, rg = 16, gm = 4, gs = 1.1, p = 2.4, ps = 9, pd = 0.7, pb = true, pw = 1 } },
			{ "⚡ 雷雲", C(200, 220, 255), C(90, 100, 200), { g = 4.2, rg = 26, h = 0.6, p = 0.9, ps = 6 } },
			{ "🔦 スポットライト", C(255, 236, 170), C(255, 200, 80), { g = 3.6, rg = 24, h = 0.14, sh = 2, sp = 40 } },
			{ "🌙 夜のランプ", C(255, 214, 150), C(60, 50, 110), { g = 1.5, rg = 13, h = 0.11, p = 0.4, ps = 5, pd = 0.25, n = true } },
			{ "🧊 氷のゆらめき", C(190, 235, 255), C(90, 150, 235), { g = 2.2, rg = 14, h = 0.54, h2 = 0.64, gm = 2, gs = 0.3, p = 0.5, ps = 5, pd = 0.4, ol = 0.56, of = 0.2 } },
		}
		e:title("光のレシピ (押すだけで、光り方が一式で変わる)")
		local items = {}
		for i, r in ipairs(RECIPES) do items[i] = { r[1], r[2], r[3] } end
		local function recipeOps(v)
			local ops = {
				{ "Glow", v.g }, { "GlowRange", v.rg }, { "GlowHue", v.h }, { "GlowHue2", v.h2 }, { "GlowSpeed", v.gs }, { "GlowMode", MODE_IDS[v.gm] },
				{ "Pulse", v.p }, { "PulseStyle", PULSE_IDS[v.ps] }, { "PulseDepth", v.pd }, { "PulseBody", v.pb }, { "PulseWave", v.pw },
				{ "NightGlow", v.n }, { "LightShape", SHAPE_IDS[v.sh] }, { "SpotAngle", v.sp },
			}
			if v.ol then
				ops[#ops + 1] = { "Outline", true }
				ops[#ops + 1] = { "OutlineHue", v.ol }
				ops[#ops + 1] = { "OutlineFill", v.of or 0 }
			end
			return ops
		end
		local _, _, rg = cardGrid(e, items, isMobile and 2 or 3, isMobile and 124 or 154, 48, function(i)
			local v = {}
			for k, d in pairs(DEF) do v[k] = d end
			for k, x in pairs(RECIPES[i][4]) do v[k] = x end
			if sendBatch(recipeOps(v)) then
				Lib.notif(gui, RECIPES[i][1] .. " にしました", 1.4)
			end
		end, function(i)   -- もう一度押した = このレシピをやめる (光が消えて、光り方も初期にもどる)
			local ops = recipeOps(DEF)
			if RECIPES[i][4].ol then   -- 縁取りがあるレシピは、縁取りも消す
				ops[#ops + 1] = { "Outline", false }
				ops[#ops + 1] = { "OutlineFill", 0 }
			end
			if sendBatch(ops) then
				Lib.notif(gui, RECIPES[i][1] .. " をやめました", 1.4)
			end
		end)
		onResettable(function() rg.mark(0) end)
	end

	e:title("発光")
	glowS = e:slider("発光の強さ", 0, 5, function(v, r) glowVal = v sendThrottled("Glow", v, r) end, 0, Color3.fromRGB(120, 80, 20), Color3.fromRGB(255, 240, 120))
	rangeS = e:slider("発光の範囲", 4, 30, function(v, r) sendThrottled("GlowRange", v, r) end, 8)
	glowHueS = e:slider("発光の色", 0, 1, function(v, r) sendThrottled("GlowHue", v, r) end, 0.58, nil, nil, hueSeq())
	e:title("光の色の動き")
	modeMark = chipsGrid(e, { "単色", "2色ゆっくり", "2色パッと", "虹色" }, isMobile and 2 or 4, function(i)
		if i > 1 then ensureGlow() end
		send("GlowMode", MODE_IDS[i])
	end, 1, 1)
	hue2S = e:slider("2つ目の色", 0, 1, function(v, r) sendThrottled("GlowHue2", v, r) end, 0.08, nil, nil, hueSeq())
	gspS = e:slider("色の速さ", 0.05, 1.5, function(v, r) sendThrottled("GlowSpeed", v, r) end, 0.3)

	e:title("光り方 (明滅はなめらかに動きます)")
	pulseS = e:slider("明滅の速さ", 0, 4, pulseTo, 0, Color3.fromRGB(99, 102, 241), CYAN)
	tempoMark = chipsRow(e, { "ゆっくり", "ふつう", "はやい", "超はやい" }, function(i)
		local v = ({ 0.5, 1.2, 2.4, 4 })[i] or 0   -- (光っているボタンをもう一度押した時は i=0 → 明滅を止める)
		pulseS:set(v)
		pulseTo(v, true)
	end, 0, 0)
	styleMark = chipsGrid(e, { "なめらか", "ドクン", "ゆらぎ", "ピカピカ", "呼吸", "雷", "ネオン管", "のこぎり", "階段", "SOS" }, isMobile and 4 or 5, function(i)
		send("PulseStyle", PULSE_IDS[i])
	end, 1, 1)
	depthS = e:slider("明滅の深さ", 0, 1, function(v, r) sendThrottled("PulseDepth", v, r) end, 1)
	bodyT = e:toggle("板も一緒に明滅 (板の明るさも変わる)", function(sv)
		bodyOn = sv
		send("PulseBody", sv)
	end, false)
	waveS = e:slider("光の波", 0, 1, function(v, r)
		if v > 0 then   -- 波は「板も一緒に明滅」している時だけ見える。明滅も止まっていたら、ゆっくり動かす
			if not bodyOn then
				bodyOn = true
				bodyT:set(true)
				send("PulseBody", true, true)
			end
			if pulseVal <= 0 then
				pulseS:set(0.8)
				pulseTo(0.8, true)
			end
		end
		sendThrottled("PulseWave", v, r)
	end, 0, Color3.fromRGB(99, 102, 241), CYAN)
	nightT = e:toggle("夜だけ光る", function(sv)
		if sv then
			ensureGlow()
			Lib.notif(gui, "ゲームの時刻が夜の間だけ光ります (昼はなめらかに消えます)", 2.4)
		end
		send("NightGlow", sv)
	end, false)
	shapeMark = chipsRow(e, { "全方向", "下を照らす", "上を照らす" }, function(i)
		send("LightShape", SHAPE_IDS[i])
	end, 1, 1)
	spotS = e:slider("スポット幅", 10, 120, function(v, r) sendThrottled("SpotAngle", v, r) end, 120)
	neonT = e:toggle("ネオン発光 (素材をネオンに)", function(sv)
		UIs.neonOn = sv
		send("Neon", sv)
	end, false)
	e:title("縁取り・オーラ")
	ot = e:toggle("縁取り", function(sv) send("Outline", sv) end, false)
	outHueS = e:slider("縁取りの色", 0, 1, function(v, r) ot:set(true) sendThrottled("OutlineHue", v, r) end, 0.55, nil, nil, hueSeq())
	auraS = e:slider("オーラ", 0, 1, function(v, r) ot:set(true) sendThrottled("OutlineFill", v, r) end, 0)
	e:title("影")
	shadowT = e:toggle("板が影を落とす", function(sv) send("Shadow", sv) end, true)

	-- まとめて送った時 (レシピ・おまかせ) に、画面の表示を合わせる
	local S = UIs.set
	S.Glow = function(v) glowVal = v glowS:set(v) end
	S.GlowRange = function(v) rangeS:set(v) end
	S.GlowHue = function(v) glowHueS:set(v) end
	S.GlowHue2 = function(v) hue2S:set(v) end
	S.GlowSpeed = function(v) gspS:set(v) end
	S.GlowMode = function(v) modeMark(idxOf(MODE_IDS, v)) end
	S.Pulse = function(v) pulseVal = v pulseS:set(v) tempoMark(0) end
	S.PulseStyle = function(v) styleMark(idxOf(PULSE_IDS, v)) end
	S.PulseDepth = function(v) depthS:set(v) end
	S.PulseBody = function(v) bodyOn = (v == true) bodyT:set(v == true) end
	S.PulseWave = function(v) waveS:set(v) end
	S.NightGlow = function(v) nightT:set(v == true) end
	S.LightShape = function(v) shapeMark(idxOf(SHAPE_IDS, v)) end
	S.SpotAngle = function(v) spotS:set(v) end
	S.Outline = function(v) ot:set(v == true) end
	S.OutlineHue = function(v) outHueS:set(v) end
	S.OutlineFill = function(v) auraS:set(v) end
	S.Neon = function(v) UIs.neonOn = (v == true) neonT:set(v == true) end
	S.Shadow = function(v) shadowT:set(v == true) end

	onResettable(function()
		glowVal, pulseVal, bodyOn = 0, 0, false
		glowS:set(0) rangeS:set(8) glowHueS:set(0.58) ot:set(false) outHueS:set(0.55) auraS:set(0)
		modeMark(1) hue2S:set(0.08) gspS:set(0.3)
		pulseS:set(0) tempoMark(0) styleMark(1) depthS:set(1) bodyT:set(false) waveS:set(0) nightT:set(false)
		shapeMark(1) spotS:set(120) neonT:set(false) shadowT:set(true)
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
	local fireMark = chipsRow(e, { "通常", "青", "緑", "紫", "ピンク" }, function(i, released)
		if not released then fireT:set(true) end
		send("FireColor", i)
	end, 1, 1)
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

-- 「選んだボタンの印」を、板に送った操作に合わせて付け外しする (どのボタンから送っても、同じ決まりで動く)
-- userCol = いま色 (単色・グラデーション・レインボー・プリセット) を自分で選んでいる状態か。素材の「色は残す」が効く状態と同じ
do
	local userCol = false
	local function clr(...)
		for _, n in ipairs({ ... }) do
			local f = UIs.mk[n]
			if f then pcall(f, 0) end
		end
	end
	UIs.onKind = function(kind, value)
		if kind == "Reset" then
			userCol = false
			clr("swatch", "gradp", "look", "preset", "two")
		elseif kind == "Color" then
			userCol = true
			clr("gradp")
			if UIs.set.Color then UIs.set.Color(value) end   -- 同じ色のボタンに印をつける (なければ印を消す)
		elseif kind == "HSV" or kind == "RGB" or kind == "Gradient" then
			userCol = true
			clr("swatch", "gradp")
		elseif kind == "GradientClear" then
			clr("gradp")
		elseif kind == "Rainbow" then
			if value == true then
				userCol = true
				clr("swatch", "gradp")
			end
		elseif kind == "Preset" then
			userCol = true
			clr("swatch", "gradp", "look")
		elseif kind == "LookRaw" or (kind == "Look" and not userCol) then
			userCol = false
			clr("swatch", "gradp", "preset")
		elseif kind == "Look" or kind == "LookKeep" then
			clr("preset")
		end
	end
	onResettable(function() userCol = false end)
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
	local tip = e:row(isMobile and 150 or 96)
	local tipLbl = text(tip, "「ぼかし系を切る」はブルーム(光のにじみ)を残すので、板のネオンの光り方は変わりません。「ブルーム・色補正を切る」を選ぶと、ネオンのにじみも消えます。「半透明の物を消す」「素材を単純化」「高画質テクスチャを外す」「メッシュを簡単に」「看板・名札を消す」「ループ音を止める」「画質を最低にする」は、見た目や音がだいぶ変わります。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	tipLbl.TextWrapped = true

	-- このスクリプト自身の動き (板の色の流れ・光の帯) を、この画面だけ軽くする。板そのものは変えない
	e:title("板の動きを軽くする (この画面だけ)")
	local animDef = { flowMul = ANIMCFG.flowMul, flowFar = ANIMCFG.flowFar, sheenFar = ANIMCFG.sheenFar, nearN = ANIMCFG.nearN, flowFace = ANIMCFG.flowFace }
	local animOn = { eco = false, still = false, noSheen = false }
	local function applyAnimCfg()
		ANIMCFG.flowMul = animOn.eco and 2 or animDef.flowMul
		ANIMCFG.nearN = animOn.eco and 3 or animDef.nearN
		ANIMCFG.flowFar = animOn.eco and 120 or animDef.flowFar
		ANIMCFG.sheenFar = animOn.noSheen and 0 or (animOn.eco and 60 or animDef.sheenFar)
		ANIMCFG.flowFace = (not animOn.still) and animDef.flowFace or false
	end
	local ecoT = e:toggle("流れ・光の更新を控えめに", function(sv) animOn.eco = sv applyAnimCfg() UIs.touch("opt") end, false)
	local stillT = e:toggle("流れる色を止める (いちばん軽い)", function(sv) animOn.still = sv applyAnimCfg() UIs.touch("opt") end, false)
	local sheenT = e:toggle("光の帯を止める", function(sv) animOn.noSheen = sv applyAnimCfg() UIs.touch("opt") end, false)
	local tip2 = e:row(isMobile and 92 or 60)
	local tip2Lbl = text(tip2, "「控えめに」は、遠い板や数の多い板の流れ・光の更新を減らします。「流れる色を止める」は、流れる色が止まって見えます (板は元のまま)。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
	tip2Lbl.TextWrapped = true

	-- GitHub保存用: 選んでいる項目の取り出し / 保存してあった選択の反映 (画面のスイッチも合わせる。反映した分は、順番に1個ずつ実行される)
	UIs.optIO = {
		get = function()
			local items = {}
			for _, key in ipairs(Opt.ORDER) do
				if Opt.isWanted(key) then items[#items + 1] = key end
			end
			return { items = items, eco = animOn.eco, still = animOn.still, noSheen = animOn.noSheen }
		end,
		set = function(t)
			local want = {}
			if type(t.items) == "table" then
				for _, key in ipairs(t.items) do
					if type(key) == "string" and Opt.LABEL[key] then want[key] = true end
				end
			end
			for _, key in ipairs(Opt.ORDER) do
				local w = want[key] == true
				togs[key]:set(w)
				if Opt.isWanted(key) ~= w then Opt.set(key, w) end
			end
			animOn.eco, animOn.still, animOn.noSheen = (t.eco == true), (t.still == true), (t.noSheen == true)
			ecoT:set(animOn.eco) stillT:set(animOn.still) sheenT:set(animOn.noSheen)
			applyAnimCfg()
		end,
	}
end

-- 9: UI設定 (「その他」タブの中の3つめ)
do
	local e = Lib.element(pages[9])
	e:title("透明度・大きさ")
	local alphaS = e:slider("透明度", 0, 0.6, function(v)
		uiCfg.alpha = v
		if isOpen then win.GroupTransparency = v end
		UIs.touch("ui")
	end, 0)
	local bgAlphaS = e:slider("背景透け", 0, 0.85, function(v)
		uiCfg.bgAlpha = v
		bg.BackgroundTransparency = v
		UIs.touch("ui")
	end, 0)
	-- 大きさは、動かしている最中に画面が拡大縮小すると操作しにくいので、離した時に反映する
	local sizeS = e:slider("大きさ", 0.6, 1.4, function(v, released)
		uiCfg.size = v
		UIs.touch("ui")
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
	local amountS = e:slider("量", 0, 1, function(v) UIFX.setAmount(v) UIs.touch("ui") end, 0.6, Color3.fromRGB(99, 102, 241), CYAN)
	local speedS = e:slider("速さ", 0.3, 2.5, function(v) UIFX.setSpeed(v) UIs.touch("ui") end, 1, Color3.fromRGB(99, 102, 241), CYAN)

	e:title("動き")
	local blobT = e:toggle("ふわふわ光", function(s)
		blobEnabled = s
		blobsOn(isOpen)
		UIs.touch("ui")
	end, true)
	local spinT = e:toggle("回転アニメ", function(s)
		spinOn = s
		for k, t in ipairs(spinTw) do
			if not s then t:Pause() elseif k == 1 or isOpen then t:Play() end   -- (タイトルの回転は、窓が開いている間だけ)
		end
		UIs.touch("ui")
	end, true)
	local juiceT = e:toggle("ぽよぽよ拡大", function(s) Lib.juiceOn = s UIs.touch("ui") end, true)

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
		spinOn = true
		for k, t in ipairs(spinTw) do
			if k == 1 or isOpen then t:Play() end
		end
		juiceT:set(true) Lib.juiceOn = true
		blobsOn(isOpen)
		UIs.touch("ui")
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
		UIs.touch("ui")
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
		UIs.touch("ui")
	end
	mark()
	-- GitHub保存用: UI設定の取り出し / 保存してあった値の反映 (形と範囲を確かめた値だけ使う。足りない項目は、いまのまま)
	UIs.uiIO = {
		get = function()
			return {
				alpha = uiCfg.alpha, bgAlpha = uiCfg.bgAlpha, size = uiCfg.size,
				accent = accIdx, hue = hueS:get(), style = styleIdx,
				amount = amountS:get(), speed = speedS:get(),
				blobs = blobT:get(), spin = spinT:get(), juice = juiceT:get(),
			}
		end,
		set = function(t)
			local function num(v, lo, hi)
				if type(v) ~= "number" or v ~= v then return nil end
				return math.clamp(v, lo, hi)
			end
			local v = num(t.alpha, 0, 0.6)
			if v then
				uiCfg.alpha = v
				alphaS:set(v)
				if isOpen then win.GroupTransparency = v end
			end
			v = num(t.bgAlpha, 0, 0.85)
			if v then
				uiCfg.bgAlpha = v
				bgAlphaS:set(v)
				bg.BackgroundTransparency = v
			end
			v = num(t.size, 0.6, 1.4)
			if v then
				uiCfg.size = v
				sizeS:set(v)
				if isOpen then
					fit()
					Lib.tween(winScale, { Scale = fitScale }, 0.35)
				end
			end
			local hue = num(t.hue, 0, 1)
			if hue then hueS:set(hue) end
			local ai = num(t.accent, 0, #ACCENTS)
			if ai then
				ai = math.floor(ai)
				if ai > 0 then
					applyAccent(ai)
				else
					local h = hue or 0.58
					applyAccent(0, Color3.fromHSV(h, 0.55, 1), Color3.fromHSV((h + 0.12) % 1, 0.6, 1))
				end
			end
			local si = num(t.style, 1, #STYLES)
			if si then applyStyle(math.floor(si)) end
			v = num(t.amount, 0, 1)
			if v then amountS:set(v) UIFX.setAmount(v) end
			v = num(t.speed, 0.3, 2.5)
			if v then speedS:set(v) UIFX.setSpeed(v) end
			if type(t.blobs) == "boolean" then
				blobT:set(t.blobs)
				blobEnabled = t.blobs
				blobsOn(isOpen)
			end
			if type(t.spin) == "boolean" then
				spinT:set(t.spin)
				spinOn = t.spin
				for k, tw in ipairs(spinTw) do
					if not t.spin then tw:Pause() elseif k == 1 or isOpen then tw:Play() end
				end
			end
			if type(t.juice) == "boolean" then
				juiceT:set(t.juice)
				Lib.juiceOn = t.juice
			end
		end,
	}

	-- ☁ GitHub保存の欄 (設定だけを、自分の GitHub に自動で保存して、次に起動した時にそのまま反映する。動き本体は、後ろの GitHub保存 の部分が受け持つ)
	e:title("☁ GitHub保存 (設定だけ・自動)")
	do
		local KCOL = {
			off = Color3.fromRGB(148, 163, 184), wait = Color3.fromRGB(250, 204, 21), load = Color3.fromRGB(250, 204, 21),
			save = Color3.fromRGB(56, 189, 248), ok = Color3.fromRGB(52, 211, 153), err = Color3.fromRGB(244, 63, 94),
		}
		local box = e:glass(isMobile and 96 or 72)
		local dot = mk("Frame", { BackgroundColor3 = KCOL.off, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(12, 12) }, box)
		corner(dot, 6)
		local lbl = text(box, "準備中…", isMobile and 13 or 14, UDim2.fromOffset(32, 6), UDim2.new(1, -44, 1, -12))
		lbl.TextWrapped = true
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		local autoT
		UIs.cloudUI = {
			status = function(txt, kind)
				lbl.Text = txt
				dot.BackgroundColor3 = KCOL[kind] or KCOL.off
			end,
			setAuto = function(v) autoT:set(v) end,
		}
		autoT = e:toggle("自動で保存する", function(sv) if UIs.cloud then UIs.cloud.setAuto(sv) end end, true)
		e:button("💾 いま保存する", function() if UIs.cloud then UIs.cloud.saveNow() end end)
		local armedAt = 0
		e:button("⬇ GitHubの保存を読み直して反映", function()
			if not UIs.cloud then return end
			if os.clock() - armedAt < 3 then
				armedAt = 0
				UIs.cloud.reload()
			else
				armedAt = os.clock()
				Lib.notif(gui, "もう一度押すと、いまの設定を GitHub の保存で置きかえます", 2.4)
			end
		end)
		local repoName = (type(GITHUB) == "table" and tostring(GITHUB.repo or "") ~= "") and tostring(GITHUB.repo) or nil
		local where = repoName and (repoName .. " の " .. ((GITHUB.folder or "") ~= "" and (tostring(GITHUB.folder) .. "/") or "") .. lp.Name .. ".json") or "(まだ未設定)"
		local tip = e:row(isMobile and 190 or 118)
		local tipLbl = text(tip, "保存するのは設定だけ (永久保存の見た目・プリセット・UI設定・軽量化の選択)。変えてから数秒で自動で保存され、次に起動した時に、そのまま反映されます。\n保存先: " .. where .. "\n使うには、このファイルの先頭の GITHUB に repo を書き、サーバー側にトークンを置きます (ファイルの先頭の説明を見てね)。", isMobile and 12 or 13, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), nil, SOFT)
		tipLbl.TextWrapped = true
		tipLbl.TextYAlignment = Enum.TextYAlignment.Top
	end
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

-- 10: ホーム (プレイヤーのアイコンと @ID / 見るフォルダ / プレビュー・ヘルプのボタン)
do
	local e = Lib.element(pages[10])
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

	e:title("板の検出")
	local r = e:glass(isMobile and 40 or 36)
	text(r, "見るフォルダ", isMobile and 13 or 14, UDim2.fromOffset(12, 0), UDim2.new(0.38, 0, 1, 0), nil, SOFT)
	local vFolder = text(r, toyFolderName(), isMobile and 13 or 14, UDim2.new(0.38, 0, 0, 0), UDim2.new(0.62, -12, 1, 0), Enum.TextXAlignment.Right)
	vFolder.TextTruncate = Enum.TextTruncate.AtEnd
	homeInfo = function() vFolder.Text = toyFolderName() end

	-- プレビュー と ヘルプ の大きなボタン (中身は、下で作る Preview / Help が受け持つ)
	e:title("つかう")
	local brow = e:row(isMobile and 96 or 100)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, brow)
	local function bigBtn(order, icon, name, sub, cb)
		local b = mk("TextButton", { Name = name, AutoButtonColor = false, Text = "", LayoutOrder = order, Size = UDim2.new(0.5, -5, 1, 0) }, brow)
		Lib.glass(b, 0.8, 16)
		local grad = mk("UIGradient", { Rotation = 35, Color = ColorSequence.new(Lib.ACCENT, Lib.ACCENT2), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.82) }) }, b)
		Lib.onTheme(function(x, y) grad.Color = ColorSequence.new(x, y) end)
		text(b, icon, isMobile and 28 or 32, UDim2.fromOffset(12, 8), UDim2.fromOffset(44, 40), Enum.TextXAlignment.Center)
		local nameLbl = text(b, name, isMobile and 16 or 18, UDim2.fromOffset(isMobile and 12 or 58, isMobile and 50 or 12), UDim2.new(1, isMobile and -20 or -66, 0, 26))
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		local subLbl = text(b, sub, isMobile and 11 or 12, UDim2.fromOffset(12, isMobile and 72 or 56), UDim2.new(1, -24, 0, isMobile and 20 or 38), nil, SOFT)
		subLbl.TextWrapped = true
		subLbl.TextYAlignment = Enum.TextYAlignment.Top
		Lib.juice(b)
		b.MouseButton1Click:Connect(function() pcall(cb) end)
		return nameLbl
	end
	local pvName = bigBtn(1, "👁", "プレビュー", "板の3Dモデルを見ながら、色や素材を試せます", function() if UIs.togglePreview then UIs.togglePreview() end end)
	bigBtn(2, "❓", "ヘルプ", "各ページの説明と、ボタンひとつずつの使い方", function() if UIs.openHelp then UIs.openHelp() end end)
	UIs.homePreviewLabel = function(open) pvName.Text = open and "プレビューを閉じる" or "プレビュー" end
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
		if spinOn and spinTw[2] then spinTw[2]:Play() end
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
				if spinTw[2] then spinTw[2]:Pause() end   -- 窓が閉じている間は、タイトルの回転も止める
			end
		end)
	end
end

Lib.drag(toggle, toggle, function() if UIs.helpOpen then return end setOpen(not isOpen) end)
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

-- 永久保存の「保存する / 解除する」。📌ボタンと、GitHubからの復元で、同じ処理を使う
UIs.permIO = {
	get = function() return permanentOps end,   -- (読むだけに使う)
	release = function()
		permanentOps = nil
		permServer = false
		updatePerm()
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
	end,
	hold = function(copy, toBoards)
		permanentOps = copy
		permServer = false
		updatePerm()
		-- サーバーに預けておくと、板が出たのと同じ瞬間にサーバーが付けてくれる (ここから送り直すより速い)。預けられるまでは、この画面から送る
		local pr = RS:FindFirstChild("PalletStudioPerm_v3")
		if pr then
			task.spawn(function()
				local ok, res = pcall(function() return pr:InvokeServer(copy) end)
				if ok and res == "saved" and permanentOps == copy then permServer = true end
			end)
		end
		if toBoards then   -- いま出ている板にも付ける (起動時の復元用。これから出る板には、上の仕組みが付ける)
			for _, m in ipairs(myPallets()) do
				local ops = {}
				for k, op in ipairs(copy) do ops[k] = { op[1], op[2] } end
				sendMany(m, ops, true)
			end
		end
	end,
}

permBtn.MouseButton1Click:Connect(function()
	if permanentOps then   -- 保存中にもう一度押すと解除
		UIs.permIO.release()
		UIs.touch("perm")
		Lib.notif(gui, "永久保存を解除しました (これから出す板には反映しません)", 2.2)
		return
	end
	if UIs.pv.model then   -- プレビュー中のプレビューの板は、本物の板ではないので、永久保存にはできない
		Lib.notif(gui, "プレビュー中は永久保存できません (プレビューを閉じてから押してね)", 2.2)
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
	UIs.permIO.hold(copy)
	UIs.touch("perm")
	Lib.notif(gui, "永久保存しました 📌 これから出す板に自動で反映します (もう一度押すと解除)", 2.6)
end)

ringGrad.Rotation = 0
spinTw[1] = TweenService:Create(ringGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
spinTw[2] = TweenService:Create(titleGrad, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
spinTw[1]:Play()   -- (リングは、開閉ボタンのまわりでいつも回る。タイトルの回転は、窓を開いた時に始める)

-- 板が出た時の処理 (永久保存している設定を、出た板に反映する)
local function onBoardAdded(m)
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
end
-- 見張るのは「自分の板のフォルダの直下」だけ (Workspace 全体の増減は見ない。ゲームの中で物が増えても、この画面は何もしない)
local folderConns, watchedFolder = {}, nil
local function unwatchFolder()
	for _, c in ipairs(folderConns) do pcall(function() c:Disconnect() end) end
	folderConns, watchedFolder = {}, nil
end
local function watchFolder(f)
	unwatchFolder()
	if not f then return end
	watchedFolder = f
	folderConns[1] = f.ChildAdded:Connect(onBoardAdded)
	folderConns[2] = f.ChildRemoved:Connect(function(m)
		if isOpen and m.Name == "PalletLightBrown" then task.delay(0.1, refresh) end
	end)
end
watchFolder(myFolder())
-- 自分のフォルダ自体が出来た/消えた時も一覧を更新する (フォルダは自動では作らない。ゲーム側が作った物を待つだけ)
workspace.ChildAdded:Connect(function(c)
	if c.Name ~= toyFolderName() then return end
	watchFolder(c)
	for _, m in ipairs(c:GetChildren()) do onBoardAdded(m) end   -- 板が入ったままフォルダが出来た時も、取りこぼさない
	if isOpen then task.delay(0.3, refresh) end
end)
workspace.ChildRemoved:Connect(function(c)
	if c.Name ~= toyFolderName() then return end
	if c == watchedFolder then unwatchFolder() end
	if isOpen then task.delay(0.1, refresh) end
end)

showTab(1)
local HELP_DATA = (function()
-- ヘルプの中身 (ページごとの説明 → 機能ひとつずつの説明)
-- { id, icon, name, sum(一覧に出る短い説明), intro = { 段落, ... }, groups = { { 見出し, { { 名前, 説明 }, ... } }, ... } }
-- 「その他」(視野・軽量化・UI設定) は、ヘルプに入れない。
return {
	{ id = "start", icon = "🔰", name = "はじめに", sum = "基本の使いかたと、画面の見かた",
		intro = {
			"このスクリプトは、あなたの板 (PalletLightBrown) の見た目を、ボタンやスライダーで自由に変えるためのものです。",
			"使いかたは3ステップ。①下のバーで板を選ぶ → ②左のページを選ぶ → ③ボタンやスライダーを動かす。動かした瞬間に、板へ反映されます。",
			"ボタンを押すと、そのボタンが光ります (選んだ印)。もう一度同じボタンを押すと、その設定をやめられます。",
		},
		groups = {
			{ "画面の見かた", {
				{ "🎨 丸いボタン", "押すと、この画面が開きます。もう一度押すと閉じます。ドラッグすると、好きな場所へ動かせます。" },
				{ "上のバー (— と ✕)", "どちらも画面を閉じます。板の見た目は変わりません。バーをドラッグすると、画面ごと動かせます。「選択中: 板○」は、いま選んでいる板です。" },
				{ "左のページ一覧", "ホーム / 色 / 素材 / プリセット / 質感 / 光 / 効果 / その他 を切り替えます。「その他」の中に、視野・軽量化・UI設定があります。" },
				{ "左の「プリセット1・2…」", "プレビューの「メイン保存」で保存した見た目が、「その他」の下に並びます。押すと、選んでいる板がその見た目になります。" },
			} },
			{ "下のバー", {
				{ "板1・板2…", "出している板が、出した順に並びます。押すと、その板が選ばれて、板のまわりに青い枠が一瞬光ります。変える前に、必ず板を選んでください。別の板を選ぶと、スライダーやボタンの表示だけ初期の位置に戻ります (板そのものは変わりません)。" },
				{ "↺ 元に戻す", "選んでいる板を、何も変えていない最初の見た目に戻します。画面のスライダーやボタンも初期の位置に戻ります。" },
				{ "📌 永久保存", "押すと「永久保存中」(緑) になり、いまの板の設定が、これから出す板にも自動で付きます。もう一度押すと解除です。先に色や素材を変えてから押してください。" },
				{ "💾 保存", "板を変えると右に出るボタンです。押すと「保存しました」となり、青い枠が消えます。板の見た目は、押す前からすでに反映されています。" },
			} },
			{ "選んだボタンと、もう一度押す解除", {
				{ "光ったボタン", "素材・色・プリセット・質感のセット・光のレシピなどのボタンは、押すと光って「いま選んでいるもの」が分かります。" },
				{ "もう一度押す", "光っているボタンをもう一度押すと、その設定をやめて、つける前の見た目に戻ります。切り替えのボタン (ツヤの種類など) は、もう一度押すと初期の設定に戻ります。" },
			} },
		} },

	{ id = "home", icon = "🏠", name = "ホーム", sum = "プロフィール・プレビュー・ヘルプ",
		intro = {
			"いちばん最初に開くページです。あなたの情報と、プレビュー・ヘルプのボタンがあります。",
		},
		groups = {
			{ "プロフィール", {
				{ "アイコン・名前・@ID・UserId", "あなたの Roblox のアイコンと表示名、@ID (ユーザー名)、UserId を表示します。アイコンは、読み込めるまで頭文字が出ます。" },
			} },
			{ "板の検出", {
				{ "見るフォルダ", "このスクリプトが板を探すフォルダの名前です。Workspace の「@ID + SpawnedInToys」フォルダの直下にある PalletLightBrown だけが、「板1・板2…」として出ます。他の人のフォルダや、フォルダの外の板は見ません。" },
			} },
			{ "つかう", {
				{ "プレビュー", "押すと、画面の左に小さなウィンドウが開いて、板の3Dモデルが表示されます。本体の画面は閉じません。本体で色や素材を変えると、プレビューの板に反映されます (本物の板は変わりません)。もう一度押すと閉じます。くわしくは「プレビュー」の説明を見てください。" },
				{ "ヘルプ", "いま見ているこの画面です。押すと本体が閉じて、ヘルプが開きます。ヘルプを閉じると、本体が自動でもう一度開きます。" },
			} },
		} },

	{ id = "color", icon = "🎨", name = "色", sum = "単色・2〜3色のグラデーション・流れる色",
		intro = {
			"板全体の色を決めるページです。単色 (パレット・HSV・RGB・16進数) と、2〜3色を混ぜるグラデーションがあります。",
			"色を決めたあとに素材を選んでも、色は消えません (素材の入れ方が「色は残す」の時)。色のボタンも、もう一度押すと、その色をやめられます。",
		},
		groups = {
			{ "カラー", {
				{ "カラー (24色のパレット)", "押すと、板全体がその色の単色になります。押した色には✔の印が出ます。もう一度押すと、その色をやめて、つける前の見た目に戻ります。グラデーションやレインボーが付いていた時は、先に外れます。" },
			} },
			{ "色を調整 (HSV)", {
				{ "色相", "色あいを、赤→黄→緑→水色→青→紫→赤の順に選びます。" },
				{ "彩度", "色の鮮やかさです。左に動かすほど白っぽく、右ほど鮮やかになります。" },
				{ "明度", "色の明るさです。左に動かすほど暗く、右ほど明るくなります。" },
			} },
			{ "色を調整 (RGB)", {
				{ "赤 R", "赤の量です。0 から 1 まで動かせます。" },
				{ "緑 G", "緑の量です。0 から 1 まで動かせます。" },
				{ "青 B", "青の量です。0 から 1 まで動かせます。" },
			} },
			{ "16進数", {
				{ "16進数 (#RRGGBB) と 適用", "「#FF8800」のような色のコードを入れて「適用」を押すと、その色の単色になります。# は付けても付けなくても大丈夫です。形が違うと、直すようにお知らせが出ます。" },
			} },
			{ "🌈 グラデーション (2〜3色を混ぜる)", {
				{ "見本の帯", "いま設定している色の並びを見せる帯です。板に付ける前の確認用で、板は変わりません。" },
				{ "おすすめのグラデーション (押すとすぐ付く)", "夕焼け / 海 / オーロラ / 炎 / 桜 / ミント / 宇宙 / 信号 / キャンディ / モノクロ の10種類です。押すとすぐ板に付き、色A・B・C の設定も、その色に変わります。もう一度押すと、グラデーションをやめます。" },
				{ "色A (はじまり)", "グラデーションの始まりの色です。パレットを押すか「色A の色相」を動かして決めます。適用したあとなら、動かすたびに板へ反映されます。" },
				{ "色B (おわり)", "グラデーションの終わりの色です。「色B の色相」で決めます。" },
				{ "色C (まんなか。なくてもOK)", "A と B のあいだに入れる、3つめの色です。「色C の色相」で決めます。使わない時は、すぐ下の「色C を使わない (2色にもどす)」を押します。" },
				{ "色C を使わない (2色にもどす)", "色C をなくして、A と B の2色にします。" },
				{ "混ぜる向き (板の向きでの 横 / 高さ / 奥行)", "板のどの向きに色を並べるかを、「X方向」「Y方向 (高さ)」「Z方向」から選びます。X方向は横、Y方向は高さ、Z方向は奥行きです。「色を流す」がONの間は、向きは流れ用の斜めの向きになります。" },
				{ "向きを反転 (A と B を入れ替え)", "A と B の位置を入れ替えます。" },
				{ "中間の位置 (色C の位置)", "色C の位置です。3色の時は C がどこに来るか、2色の時は色の変わり目の位置を決めます。" },
				{ "模様 (なめらか / 2本 / 3本 / 4本 / 6本 / 8本)", "「なめらか」は色がじわっと変わります。「2本」〜「8本」は、色がはっきり切り替わる縞模様になります。" },
				{ "なめらかに塗る (重ね貼り)", "ONだと、板の面ごとになめらかな色の並びを重ねて、きれいに見えます。OFFだと、パーツごとに1色ずつで軽くなります。" },
				{ "上面の向きを反転 (上面だけ逆に見える時)", "板の上の面だけ、グラデーションの向きが逆に見える時に押します。" },
			} },
			{ "流れるアニメーション", {
				{ "色を流す (なめらかに動く)", "ONにすると、色が板の上をなめらかに流れます。流れる向きは、ONにした時に1回だけランダムに決まり (斜めも含みます)、流している間は変わりません。OFFにして、もう一度ONにすると、新しい向きになります。" },
				{ "流れる速さ", "色が流れる速さです。動かすと自動でONになります。速さを変えても、向きは変わりません。" },
				{ "✨ グラデーションを板に適用", "いま設定している色・向き・模様を、板に付けます。" },
				{ "単色に戻す (グラデーションを外す)", "グラデーションを外して、1色に戻します。" },
			} },
		} },

	{ id = "material", icon = "🧱", name = "素材", sum = "素材34種・入れ方・ツートン",
		intro = {
			"板の素材 (木・金属・ガラス・石など) を変えるページです。押すと、素材の模様・質感・反射が変わります。",
			"押した素材のボタンは光ります。もう一度押すと、その素材をやめて元に戻ります。「素材の入れ方」で、色をどうするか選べます。",
		},
		groups = {
			{ "素材の入れ方", {
				{ "🎨 色は残す", "自分で決めた色・グラデーションはそのままで、素材と質感だけ変わります。色をまだ決めていない板は、素材の色になります。" },
				{ "🧱 素材の色に", "素材ごとの色・質感・光にします。いまの色・グラデーションは消えます。" },
				{ "🔒 素材だけ", "色も光もそのままで、素材の模様と質感だけ変わります。" },
			} },
			{ "分類 (絞りこみ)", {
				{ "すべて", "34種類ぜんぶを出します。" },
				{ "🌲 自然", "木・板木・砂・泥・雪を出します。" },
				{ "🪨 石・土", "大理石・花崗岩・スレート・コンクリ・レンガ・石畳・玄武岩・小石・石灰岩・砂岩・しっくい・タイルを出します。" },
				{ "⚙️ 金属", "金属・ダイヤ板・ホイル・さび金属を出します。" },
				{ "🔮 ガラス・氷", "ガラス・氷・氷河・フォースフィールドを出します。" },
				{ "🧴 日用品", "プラスチック・つるつる・布・カーペット・革・ゴム・段ボールを出します。" },
				{ "💡 光る", "ネオン・溶岩・フォースフィールドを出します。" },
				{ "🎲 ランダムな素材にする", "いま出ている素材の中から、ランダムに1つ選んで付けます。" },
			} },
			{ "素材 (押すとその素材の見た目になる)", {
				{ "プラスチック", "ふつうのプラスチック。ほどよい質感の青い板になります。" },
				{ "つるつる", "表面がなめらかで、少しだけツヤのある白い板です。" },
				{ "木", "木目のある茶色い板です。" },
				{ "板木", "板を並べたような木目の、明るい茶色の板です。" },
				{ "金属", "グレーの金属で、反射があります。" },
				{ "ダイヤ板", "ひし形の凹凸がある、鉄板のような素材です。" },
				{ "ホイル", "アルミホイルのような、ピカピカした銀色です。" },
				{ "ネオン", "自分で光る素材です。水色に光ります。" },
				{ "ガラス", "透明感のあるガラスで、反射があります。" },
				{ "氷", "青白くて半透明の氷です。" },
				{ "大理石", "白くて、石の模様と少しのツヤがあります。" },
				{ "花崗岩", "ざらざらした、グレーの石です。" },
				{ "スレート", "暗い灰色の、平らな石板です。" },
				{ "コンクリ", "コンクリートの灰色です。" },
				{ "レンガ", "赤茶色のレンガの模様です。" },
				{ "石畳", "丸い石を敷き詰めたような模様です。" },
				{ "砂", "さらさらした砂の色と質感です。" },
				{ "布", "布のあらい織り目の質感です。" },
				{ "フォース", "フォースフィールド。うすく光る、バリアのような素材です。" },
				{ "氷河", "青みのある、厚い氷のような素材です。" },
				{ "雪", "ふわっとした白い雪です。" },
				{ "泥", "こげ茶色の泥です。" },
				{ "ゴム", "黒くてマットな、ゴムの質感です。" },
				{ "革", "茶色い革の質感です。" },
				{ "しっくい", "かべのような、ざらっとしたクリーム色です。" },
				{ "タイル", "つるっとした白いタイルです。" },
				{ "カーペット", "赤いカーペットの毛足の質感です。" },
				{ "段ボール", "段ボールの紙の質感です。" },
				{ "玄武岩", "黒っぽい、火山の石です。" },
				{ "小石", "小さな石が集まったような質感です。" },
				{ "石灰岩", "うすいクリーム色の、やわらかな石です。" },
				{ "砂岩", "黄土色の、砂が固まった石です。" },
				{ "さび金属", "さびて、茶色くなった金属です。" },
				{ "溶岩", "ひび割れから、オレンジ色の光がもれる岩です。" },
			} },
			{ "ツートン (板の一部だけ別の素材に)", {
				{ "⬆ 上", "板の上がわのパーツだけを、別の素材にします。" },
				{ "⬇ 下", "板の下がわのパーツだけを、別の素材にします。" },
				{ "◀ 前半", "板の前半分のパーツだけを、別の素材にします。" },
				{ "▶ 後半", "板の後ろ半分のパーツだけを、別の素材にします。" },
				{ "▥ 1本おき", "パーツを1本おきに、別の素材にします。縞模様のようになります。" },
				{ "▣ まわり", "板のまわり (ふち) のパーツだけを、別の素材にします。" },
				{ "🎲 ランダム", "ランダムに選んだパーツを、別の素材にします。" },
				{ "その素材の色", "別の素材にした部分を、その素材らしい色にします。" },
				{ "今の色のまま", "別の素材にした部分も、いまの色のままにします。" },
				{ "↓ 素材を押すと、選んだ部分だけ変わります", "ツートンの素材のボタンの上に出る見出しです。部分を決めてから、下の素材を押すと、選んだ部分だけが、その素材になります。" },
				{ "ツートンの素材のボタン", "金属・ガラス・ネオン・大理石・ホイル・氷・ゴム・革・レンガ・花崗岩・ダイヤ板・溶岩の12種類です。部分を決めてから素材を押すと、その部分だけ変わります。押した素材をもう一度押すと、ツートンをやめます。" },
				{ "ツートンをやめる (ぜんぶ同じ素材に戻す)", "ツートンをやめて、ぜんぶ同じ素材に戻します。" },
			} },
		} },

	{ id = "preset", icon = "✨", name = "プリセット", sum = "おまかせ・コピー・見た目一式30種",
		intro = {
			"ボタンひとつで、色・素材・光などをまとめて決めるページです。押したプリセットは光ります。もう一度押すと、そのプリセットをやめて、つける前の見た目に戻ります。",
		},
		groups = {
			{ "かんたん", {
				{ "🎲 おまかせスタイル (ぜんぶランダム)", "色・素材・ツヤ・光・効果を、ランダムにぜんぶ決めて付けます。気に入らなければ、もう一度押すと別のスタイルになります。" },
				{ "📋 この板の見た目を、ほかの全部の板にコピー", "選んでいる板の見た目を、出ているほかの板ぜんぶにコピーします。先に、この板の色や素材を変えておいてください。" },
			} },
			{ "✨ 見た目一式 (光・動き・効果つき)", {
				{ "オーロラ", "緑・青・紫の3色が、ゆっくり流れます。ツヤと、やさしい光つきです。" },
				{ "ギャラクシー", "濃い紺から紫へ、ゆっくり流れる宇宙の色です。キラキラと、ゆっくりした明滅つきです。" },
				{ "クローム", "鏡のようにピカピカの、銀色の金属です。" },
				{ "ホログラム", "半透明で、虹色にゆっくり変わる色です。ツヤと、やさしい明滅つきです。" },
				{ "溶岩フロー", "赤から黄色へ流れる、燃える溶岩です。炎・火の粉・ゆらぐ光つきです。" },
				{ "氷結", "つめたい色の氷です。雪が舞います。" },
				{ "桜吹雪", "うすいピンクの板に、桜の花びらが舞います。" },
				{ "サイバー", "黒い金属に、水色の光と縁取りがあります。ドクンと明滅します。" },
				{ "ほたるの夜", "暗い緑の板に、黄緑のほたるが飛びます。ゆらぐ光つきです。" },
				{ "キャンディツヤ", "ピンクから白へのグラデーションに、強いツヤとキラキラがつきます。" },
				{ "夕焼け空", "オレンジ・ピンク・紫が、上から下へ重なる夕焼けです。" },
				{ "海", "深い青から水色へ流れる色です。あわが上がります。" },
			} },
			{ "基本のプリセット", {
				{ "ネオンブルー", "水色に光るネオンです。" },
				{ "ネオンピンク", "ピンクに光るネオンです。" },
				{ "ネオングリーン", "緑に光るネオンです。" },
				{ "サンセット", "オレンジに光るネオンです。" },
				{ "ゴールド", "金色の金属です。" },
				{ "シルバー", "銀色の金属です。" },
				{ "アイス", "青白く、半透明の氷です。" },
				{ "ガラス", "半透明のガラスです。" },
				{ "大理石", "白い大理石です。" },
				{ "ラバ", "オレンジ色に強く光る、溶岩のネオンです。" },
				{ "黒曜石", "黒く光る、ガラスのような石です。" },
				{ "キャンディ", "ピンクの、つるつるした素材です。" },
				{ "森", "緑の布の素材です。" },
				{ "ゴースト", "うす白くて半透明の、ふわっと光るバリアです。" },
				{ "さくら", "うすいピンクで、ほんのり光ります。" },
				{ "トキシック", "毒のような黄緑に光るネオンです。" },
				{ "ロイヤル", "濃い紫の、ガラスのような素材です。" },
				{ "ローズゴールド", "ピンクがかった金色の金属です。" },
			} },
		} },

	{ id = "texture", icon = "💎", name = "質感", sum = "ツヤ・映り込み・光の走り・経年劣化",
		intro = {
			"板の「ツヤ」や「よごれ」を決めるページです。素材や色、木目はそのままで、反射・光の帯・角の輝きなどを重ねます。",
			"「質感のセット」は、押すだけで一式が決まります。押したセットは光り、もう一度押すと、ツヤなどが初期にもどります。",
		},
		groups = {
			{ "質感のセット (素材・色はそのまま。押すだけ)", {
				{ "鏡面ミラー", "反射100%の、鏡のようにツルツルな板です。角が少し輝きます。" },
				{ "ウェット", "雨にぬれたような、小さな光がたくさんあるツヤです。" },
				{ "キャンディ", "ニスをぬったような、あまいツヤです。光の帯と、角の輝きもつきます。" },
				{ "パール", "真珠のような、虹色のやさしい光沢です。" },
				{ "ダイヤ", "虹色に、きらめく面です。光の帯が走り、角が強く輝きます。" },
				{ "ネオンナイト", "ネオン街の空を映して、虹色の光が走ります。角もよく輝きます。" },
				{ "夕焼けミラー", "夕焼けの空を映す、鏡のようなツヤです。" },
				{ "ブラッシュ金属", "ブラシをかけた金属のような、すじのあるツヤです。" },
				{ "つや消し", "反射をなくして、マットにします。" },
				{ "さびてボロボロ", "色ムラと、さびの経年劣化をつけます。" },
				{ "こけむす", "色ムラと、下のほうに濃いこけをつけます。" },
				{ "雪化粧", "上のほうに、白い雪がつもったようにします。" },
			} },
			{ "反射・ツヤ (素材や木目はそのまま)", {
				{ "反射・ツヤ", "右へ動かすほど、ツルツル・テカテカになります。100%で鏡のようになります。素材や木目は変わりません。" },
				{ "マット 0%", "反射をなくします。" },
				{ "ツヤ 35%", "ほどよいツヤにします。" },
				{ "ミラー 100%", "いちばんテカテカの、鏡のような反射にします。" },
			} },
			{ "ツヤの種類 (8種類)", {
				{ "くっきり", "はっきりした光の帯が走る、ふつうの鏡のようなツヤです。" },
				{ "やわらか", "ぼんやりした、やさしいツヤです。" },
				{ "ガラス", "細い光の線が何本も走る、ガラスのようなツヤです。" },
				{ "メタル", "等間隔の帯が並ぶ、金属のようなツヤです。" },
				{ "ウェット", "ぬれたように、小さな光がたくさん出ます。" },
				{ "パール", "虹色にうつろう、真珠のようなツヤです。" },
				{ "ニス", "細くて鋭い光と、うすい映り込みの、ニスのようなツヤです。" },
				{ "ダイヤ", "虹色に、きらきらきらめくツヤです。" },
			} },
			{ "ツヤの向き", {
				{ "横 (X)", "光の帯が、横方向に並びます。" },
				{ "高さ (Y)", "光の帯が、高さの方向に並びます。" },
				{ "奥 (Z)", "光の帯が、奥行きの方向に並びます。" },
			} },
			{ "映り込む空", {
				{ "☀️ 昼", "昼の空を映します。" },
				{ "🌇 夕焼け", "夕焼けの空を映します。" },
				{ "🌙 夜", "夜の空を映します。" },
				{ "🌃 ネオン街", "ネオンのピンク色を映します。" },
				{ "🌌 オーロラ", "オーロラの緑色を映します。" },
				{ "💡 スタジオ", "白いスタジオの光を映します。" },
				{ "空の映り込みを最大に (この画面だけ)", "ONにすると、ゲーム全体の空の映り込みを最大にして、反射がよく見えるようにします。この画面だけの設定で、他の人には影響しません。" },
			} },
			{ "光が走る・角のきらめき", {
				{ "光の走り", "板の上を、光の帯がすーっと走ります。右へ動かすほど強く、はやくなります。0で止まります。" },
				{ "白い光 / 金色の光 / 虹色の光", "走る光の色を選びます。" },
				{ "角の輝き", "板の角 (ふち) が、きらっと輝きます。" },
			} },
			{ "見た目", {
				{ "透明度", "板を透明にします。右へ動かすほど透けます。" },
				{ "色ムラ", "板1枚ごとに、色を少しずつ変えます。" },
				{ "経年劣化", "古びたよごれを、板につけます。右へ動かすほど、ひどくなります。" },
				{ "汚れ", "全体が、くすんだようになります。" },
				{ "さび", "茶色いさびがつきます。" },
				{ "こけ", "下のほうに、緑のこけがつきます。" },
				{ "雪", "上のほうに、白い雪がつもります。" },
				{ "焦げ", "黒く焦げたようになります。" },
			} },
			{ "テクスチャ", {
				{ "元の木目テクスチャ", "ONだと、元の板の木目が見えます。OFFにすると、木目が消えて、色がはっきり出ます。素材を選ぶと、自動でOFFになります。" },
			} },
		} },

	{ id = "light", icon = "💡", name = "光", sum = "光るレシピ・明滅・色の動き・縁取り",
		intro = {
			"板が光る (まわりを照らす) ようにするページです。光の強さ・色・明滅のしかたを決められます。",
			"「光のレシピ」は、押すだけで一式が決まります。押したレシピは光り、もう一度押すと、光がやみます。",
		},
		groups = {
			{ "光のレシピ (押すだけで、光り方が一式で変わる)", {
				{ "キャンドル", "あたたかい色で、ろうそくのようにゆらぎます。" },
				{ "たいまつ", "オレンジから赤へ変わる炎の色が、はげしくゆらぎます。" },
				{ "ハートビート", "ドクン、ドクンと、板ごと脈打ちます。" },
				{ "パトランプ", "赤と青が、パッと交互に切り替わります。" },
				{ "ネオンサイン", "ピンクと水色が変わり、切れかけたネオン管のようにちらつきます。縁取りもつきます。" },
				{ "オーロラ", "緑と紫が、ゆっくり変わります。" },
				{ "レインボー", "光の色が、虹色に変わり続けます。" },
				{ "ディスコ", "虹色が、はやく変わります。明滅と、光の波もつきます。" },
				{ "雷雲", "ふだんは暗く、ときどきバリッと強く光ります。" },
				{ "スポットライト", "下を、せまい範囲で明るく照らします。" },
				{ "夜のランプ", "ゲームの時刻が夜の間だけ、ほんのり光ります。" },
				{ "氷のゆらめき", "うす青く、ゆらゆら光ります。縁取りもつきます。" },
			} },
			{ "発光", {
				{ "発光の強さ", "光の強さです。0で光りません。" },
				{ "発光の範囲", "光がとどく広さです。" },
				{ "発光の色", "光の色を、色あいで決めます。" },
			} },
			{ "光の色の動き", {
				{ "単色", "光の色が変わらず、ずっと同じ色です。" },
				{ "2色ゆっくり", "「発光の色」と「2つ目の色」のあいだを、ゆっくり行き来します。" },
				{ "2色パッと", "2つの色が、パッと交互に切り替わります。" },
				{ "虹色", "光の色が、虹色に変わり続けます。" },
				{ "2つ目の色", "2色の動きで使う、もうひとつの色です。" },
				{ "色の速さ", "色が変わる速さです。" },
			} },
			{ "光り方 (明滅はなめらかに動きます)", {
				{ "明滅の速さ", "光がつく・消えるを、くり返す速さです。0で止まります。" },
				{ "ゆっくり", "ゆっくり明滅します。" },
				{ "ふつう", "ふつうの速さで明滅します。" },
				{ "はやい", "はやく明滅します。" },
				{ "超はやい", "とてもはやく明滅します。" },
				{ "なめらか", "なめらかに、強くなったり弱くなったりします。" },
				{ "ドクン", "心臓のように、ドクン、ドクンと光ります。" },
				{ "ゆらぎ", "ろうそくのように、ゆらゆらします。" },
				{ "ピカピカ", "ピカッ、ピカッと、はっきり光ります。" },
				{ "呼吸", "すぅっと明るくなって、ゆっくり暗くなります。" },
				{ "雷", "ふだんは暗く、ときどきバリッと光ります。" },
				{ "ネオン管", "切れかけのネオン管のように、ジジッとちらつきます。" },
				{ "のこぎり", "だんだん明るくなって、パッと消えます。" },
				{ "階段", "4段階で、だんだん明るくなります。" },
				{ "SOS", "モールス信号の「SOS」の長さで光ります。" },
				{ "明滅の深さ", "明滅の強さです。1で完全に暗くなり、0でほとんど変わりません。" },
				{ "板も一緒に明滅 (板の明るさも変わる)", "ONにすると、光だけでなく、板そのものの明るさも一緒に明滅します。" },
				{ "光の波", "板の端から端へ、明滅がずれて走ります。「板も一緒に明滅」がONの時に見えます (動かすと自動でONになります)。" },
				{ "夜だけ光る", "ゲームの時刻が夜の間だけ光ります。昼はなめらかに消えます。" },
				{ "全方向", "光が、まわり全体に広がります。" },
				{ "下を照らす", "光が、下だけを照らします。" },
				{ "上を照らす", "光が、上だけを照らします。" },
				{ "スポット幅", "「下を照らす」「上を照らす」の時の、光の広がりの角度です。小さいほど細い光になります。" },
				{ "ネオン発光 (素材をネオンに)", "ONにすると、板の素材がネオンになって、自分でも光ります。OFFで元の素材にもどります。" },
			} },
			{ "縁取り・オーラ", {
				{ "縁取り", "板のまわりに、色つきの線を出します。" },
				{ "縁取りの色", "縁取りの色です。動かすと自動でONになります。" },
				{ "オーラ", "縁取りの内側を、ぼんやり光らせます。動かすと自動で縁取りがONになります。" },
			} },
			{ "影", {
				{ "板が影を落とす", "OFFにすると、板の影が出なくなります。" },
			} },
		} },

	{ id = "fx", icon = "🌈", name = "効果", sum = "レインボー・炎・雪・桜・キラキラなど",
		intro = {
			"板に、動く色や、粒の効果 (炎・雪・桜など) をつけるページです。スイッチをONにすると、すぐ出ます。",
		},
		groups = {
			{ "🌈 レインボー (なめらかに動きます)", {
				{ "レインボー", "ONにすると、板の色が虹色に、なめらかに変わり続けます。色やグラデーションを決めると、自動でOFFになります。" },
				{ "虹の速さ", "虹色が変わる速さです。動かすと自動でONになります。" },
				{ "鮮やかさ", "虹色の鮮やかさです。左へ動かすほど、うすい色になります。" },
				{ "虹の波", "板の端から端へ、色がずれて並びます。0だと、板ぜんぶが同じ色で変わります。" },
			} },
			{ "✨ キラキラ", {
				{ "キラキラ", "ONにすると、板のまわりにキラキラの粒が出ます。" },
				{ "キラキラの量", "粒の数です。動かすと自動でONになります。" },
				{ "キラキラの大きさ", "粒の大きさです。" },
			} },
			{ "🔥 炎 (板の向きに関係なく、必ず上へ昇ります)", {
				{ "炎", "ONにすると、板から炎が上へ昇ります。" },
				{ "炎の大きさ", "炎の大きさです。動かすと自動でONになります。" },
				{ "通常 / 青 / 緑 / 紫 / ピンク", "炎の色です。" },
			} },
			{ "💨 煙・紙吹雪", {
				{ "煙", "ONにすると、板から煙が上へ昇ります。" },
				{ "紙吹雪", "ONにすると、カラフルな紙吹雪が舞います。" },
			} },
			{ "🌸 ふわふわ", {
				{ "❄️ 雪", "ONにすると、雪が舞います。" },
				{ "🌸 桜", "ONにすると、桜の花びらが舞います。" },
				{ "✨ ほたる", "ONにすると、ほたるのような光が飛びます。" },
				{ "🫧 あわ", "ONにすると、あわが上へ昇ります。" },
				{ "🔥 火の粉", "ONにすると、火の粉が上へ飛びます。" },
				{ "効果の量 (全部)", "雪・桜・ほたる・あわ・火の粉・煙・紙吹雪など、すべての粒の量をまとめて変えます。" },
			} },
		} },

	{ id = "preview", icon = "👁", name = "プレビュー", sum = "3Dの板で見ながら試して、保存する",
		intro = {
			"ホームの「プレビュー」を押すと、画面の左に、小さなウィンドウが開きます。何も変えていない、ふつうの板の3Dモデルが、ゆっくり左まわりに回ります。",
			"本体は開いたままです。本体で色や素材などを変えると、プレビューの板だけが変わります (本物の板は変わりません)。気に入ったら「メイン保存」で保存できます。",
		},
		groups = {
			{ "見かた・動かしかた", {
				{ "ドラッグで回す", "プレビューの板を指やマウスでドラッグすると、ぐるっと360度、好きな角度から見られます。さわっている間は、自動の回転が止まります。10秒なにもしないと、また回りはじめます。" },
				{ "＋ / －", "プレビューの板を、大きく / 小さく表示します。" },
				{ "↺ 左まわり / ↻ 右まわり", "自動で回る向きを切り替えます。" },
				{ "🎯 視点をもどす", "見る角度と大きさを、はじめの状態に戻します。" },
				{ "プレビューでの見え方", "光や炎・雪などの粒、縁取りは、近い見た目でまねして出します。ゲーム本物の見え方とは少し違うことがあります。" },
			} },
			{ "保存する", {
				{ "💾 メイン保存", "プレビューの板の、いまの見た目を保存します。左のページ一覧の「その他」の下に、「プリセット1」のようなボタンが出ます。プリセットのボタンを押すと、選んでいる板が、その見た目になります。" },
				{ "プリセット1・2…", "押すと、選んでいる板が、保存した見た目に一瞬でなります。右上の ✕ で、そのプリセットを消せます。ゲームをやめると消えます。" },
				{ "プレビューを閉じる", "✕ か、ホームの「プレビューを閉じる」を押します。閉じると、本体のスライダーやボタンが、初期の位置に戻って、ふつうに板を設定できます。" },
			} },
		} },
}
end)()
---------------------------------------------------------------------
-- ヘルプ (本体とは別のウィンドウ)
--  開くと本体の画面は閉じて、ヘルプを閉じると本体が自動でもう一度開く。
--  3段階: ① ページ一覧 → ② そのページの説明 (+「機能をひとつずつ見る」ボタン) → ③ 機能ひとつずつの説明
--  文章は help_data.lua (HELP_DATA)。「その他」(視野・軽量化・UI設定) はヘルプに入れない。
---------------------------------------------------------------------
do
	local HELP = HELP_DATA
	local hOpen = false
	local view = { level = 0, sec = 0, gi = nil }   -- いま何段目の、どのページか
	local FS_BODY = isMobile and 13 or 14

	-- ウィンドウ -----------------------------------------------------
	local hw = mk("CanvasGroup", { Name = "HelpWindow", BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, Active = true, AnchorPoint = winAnchor, Position = win.Position, Size = UDim2.fromOffset(W, H) }, gui)
	corner(hw, 22)
	local hStroke = stroke(hw, 0.35, WHITE, 1.5)
	mk("UIGradient", { Rotation = 90, Color = winStrokeGrad.Color }, hStroke)
	local hScale = mk("UIScale", {}, hw)
	-- 後ろの3D世界へ操作が抜けないようにする受け止め板 (本体と同じ)
	mk("TextButton", { Name = "InputSink", AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 0, Active = true }, hw)
	local hBg = mk("Frame", { Name = "Bg", BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, hw)
	local hBgGrad = mk("UIGradient", { Rotation = 35, Color = bgGrad.Color }, hBg)
	local hFx = mk("Frame", { Name = "Fx", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, hBg)
	local hb1 = mk("Frame", { BackgroundColor3 = blob1.BackgroundColor3, BackgroundTransparency = 0.8, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.88, 0.1), Size = UDim2.fromOffset(300, 300) }, hFx)
	corner(hb1, 150)
	local hb2 = mk("Frame", { BackgroundColor3 = blob2.BackgroundColor3, BackgroundTransparency = 0.82, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.1, 0.95), Size = UDim2.fromOffset(320, 320) }, hFx)
	corner(hb2, 160)

	-- 上のバー: タイトル / もどる / とじる
	local top = mk("Frame", { Name = "TopBar", Active = true, Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(W - 24, 50) }, hw)
	Lib.glass(top, 0.86, 16)
	local BACK_W = isMobile and 40 or 96
	local titleW = UDim2.new(1, -(16 + 42 + 8 + BACK_W + 8), 0, 30)
	local hTitle = text(top, "❓ ヘルプ", isMobile and 18 or 24, UDim2.fromOffset(16, isMobile and 10 or 2), titleW)
	hTitle.TextTruncate = Enum.TextTruncate.AtEnd
	local hCrumb = nil
	if not isMobile then
		hCrumb = text(top, "", 12, UDim2.fromOffset(17, 31), UDim2.new(1, -(16 + 42 + 8 + BACK_W + 8), 0, 16), nil, SOFT)
		hCrumb.TextTruncate = Enum.TextTruncate.AtEnd
	end
	local closeH = mk("TextButton", { Name = "Close", AutoButtonColor = false, Text = "✕", TextSize = 16, FontFace = FONT, TextColor3 = WHITE, Position = UDim2.new(1, -42, 0.5, -16), Size = UDim2.fromOffset(32, 32) }, top)
	Lib.glass(closeH, 0.75, 16)
	Lib.juice(closeH)
	local backH = mk("TextButton", { Name = "Back", AutoButtonColor = false, Text = isMobile and "‹" or "‹ もどる", TextSize = isMobile and 22 or 15, FontFace = FONT, TextColor3 = WHITE, Position = UDim2.new(1, -(42 + 8 + BACK_W), 0.5, -16), Size = UDim2.fromOffset(BACK_W, 32), Visible = false }, top)
	Lib.glass(backH, 0.75, 16)
	Lib.juice(backH)

	-- 中身 (縦にスクロール)
	local body = mk("Frame", { Name = "Body", Position = UDim2.fromOffset(12, 68), Size = UDim2.fromOffset(W - 24, H - 68 - 12) }, hw)
	Lib.glass(body, 0.9, 16)
	local scroll = mk("ScrollingFrame", { Name = "Scroll", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, body)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14) }, scroll)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	-- 部品 -----------------------------------------------------------
	-- ガラスの箱 (中身に合わせて縦に伸びる)。asButton なら、押せる箱
	local function box(order, tr, asButton, parent)
		local f = mk(asButton and "TextButton" or "Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = tr or 0.88, BorderSizePixel = 0, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent or scroll)
		if asButton then
			f.AutoButtonColor = false
			f.Text = ""
			Lib.juice(f)
		end
		corner(f, 10)
		mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, f)
		mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, f)
		return f
	end
	local function para(parent, t, size, color, order)
		return mk("TextLabel", { BackgroundTransparency = 1, Text = t, TextSize = size, FontFace = FONT, TextColor3 = color or WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, LineHeight = 1.12, LayoutOrder = order or 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent)
	end
	local function titleBar(order, t)
		local f = mk("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 28) }, scroll)
		Lib.glass(f, 0.7, 13)
		local l = mk("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), Text = t, TextSize = 15, FontFace = FONT, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.AtEnd }, f)
		return f
	end
	local function bigButton(order, t, cb)
		local b = mk("TextButton", { AutoButtonColor = false, Text = t, TextSize = isMobile and 15 or 16, FontFace = FONT, TextColor3 = WHITE, LayoutOrder = order, Size = UDim2.new(1, 0, 0, isMobile and 48 or 44) }, scroll)
		Lib.glass(b, 0.3, 14)
		mk("UIGradient", { Rotation = 20, Color = ColorSequence.new(Lib.ACCENT, Lib.ACCENT2) }, b)
		Lib.juice(b)
		b.MouseButton1Click:Connect(function() pcall(cb) end)
		return b
	end
	local function countOf(s)
		local n = 0
		for _, g in ipairs(s.groups) do n = n + #g[2] end
		return n
	end

	local render   -- (下で定義)
	local function go(level, sec, gi)
		view.level, view.sec, view.gi = level, sec or view.sec, gi
		render(true)
	end

	-- ① ページ一覧 ----------------------------------------------------
	local function renderRoot()
		hTitle.Text = "❓ ヘルプ"
		if hCrumb then hCrumb.Text = "知りたいページを選んでください" end
		backH.Visible = false
		local c = box(1, 0.82)
		para(c, "知りたいページを選ぶと、そのページの説明が出ます。説明の中の「❓ 機能をひとつずつ見る」を押すと、ボタンやスライダー1つずつの使いかたが見られます。ヘルプを閉じると、本体の画面が自動でもう一度開きます。", FS_BODY, SOFT, 1)
		local gridF = mk("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, scroll)
		mk("UIGridLayout", { CellSize = isMobile and UDim2.new(1, 0, 0, 62) or UDim2.new(0.5, -4, 0, 62), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, gridF)
		for i, s in ipairs(HELP) do
			local b = mk("TextButton", { Name = "Sec_" .. s.id, AutoButtonColor = false, Text = "", LayoutOrder = i }, gridF)
			Lib.glass(b, 0.84, 14)
			mk("UIGradient", { Rotation = 35, Color = ColorSequence.new(Lib.ACCENT, Lib.ACCENT2), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.9) }) }, b)
			text(b, s.icon, 28, UDim2.fromOffset(8, 0), UDim2.fromOffset(46, 62), Enum.TextXAlignment.Center)
			local nm = text(b, s.name, isMobile and 16 or 18, UDim2.fromOffset(58, 9), UDim2.new(1, -92, 0, 24))
			nm.TextTruncate = Enum.TextTruncate.AtEnd
			local sm = text(b, s.sum, isMobile and 11 or 12, UDim2.fromOffset(58, 35), UDim2.new(1, -92, 0, 18), nil, SOFT)
			sm.TextTruncate = Enum.TextTruncate.AtEnd
			text(b, "›", 28, UDim2.new(1, -34, 0, 0), UDim2.fromOffset(26, 62), Enum.TextXAlignment.Center, SOFT)
			Lib.juice(b)
			b.MouseButton1Click:Connect(function() go(1, i) end)
		end
	end

	-- ② そのページの説明 ------------------------------------------------
	local function renderSection(si)
		local s = HELP[si]
		hTitle.Text = s.icon .. " " .. s.name
		if hCrumb then hCrumb.Text = "ページの説明" end
		backH.Visible = true
		local n = countOf(s)
		local head = mk("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 68) }, scroll)
		Lib.glass(head, 0.8, 14)
		mk("UIGradient", { Rotation = 35, Color = ColorSequence.new(Lib.ACCENT, Lib.ACCENT2), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.88) }) }, head)
		text(head, s.icon, 34, UDim2.fromOffset(8, 0), UDim2.fromOffset(54, 68), Enum.TextXAlignment.Center)
		local nm = text(head, s.name, isMobile and 19 or 22, UDim2.fromOffset(66, 8), UDim2.new(1, -78, 0, 28))
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		local sm = text(head, s.sum, isMobile and 12 or 13, UDim2.fromOffset(66, 38), UDim2.new(1, -78, 0, 22), nil, SOFT)
		sm.TextTruncate = Enum.TextTruncate.AtEnd
		bigButton(2, "❓ 機能をひとつずつ見る (" .. n .. "個)", function() go(2, si) end)
		for k, t in ipairs(s.intro) do
			local c = box(10 + k, 0.88)
			para(c, t, FS_BODY, WHITE, 1)
		end
		titleBar(40, "このページの中身 (押すと、その部分の説明へ)")
		for gi, g in ipairs(s.groups) do
			local names = {}
			for _, f in ipairs(g[2]) do names[#names + 1] = f[1] end
			local c = box(40 + gi, 0.86, true)
			para(c, g[1] .. "  (" .. #g[2] .. ")", 15, CYAN, 1)
			para(c, table.concat(names, "・"), isMobile and 12 or 13, SOFT, 2)
			c.MouseButton1Click:Connect(function() go(2, si, gi) end)
		end
		bigButton(100, "❓ 機能をひとつずつ見る (" .. n .. "個)", function() go(2, si) end)
	end

	-- ③ 機能ひとつずつの説明 -----------------------------------------------
	local hdrs = {}
	local function jumpTo(gi)
		local fr = hdrs[gi]
		if not fr then return end
		task.delay(0.08, function()   -- 並びが決まるのを少し待ってから、その見出しの位置までスクロール
			if not fr.Parent then return end
			local ok, y = pcall(function()
				local sc = math.max(hScale.Scale, 0.05)
				return (fr.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / sc + scroll.CanvasPosition.Y - 6
			end)
			if ok and type(y) == "number" then
				Lib.tween(scroll, { CanvasPosition = Vector2.new(0, math.max(0, y)) }, 0.5)
			end
		end)
	end
	local function renderFeatures(si, gi)
		local s = HELP[si]
		hTitle.Text = s.icon .. " " .. s.name .. " ・ ひとつずつ"
		if hCrumb then hCrumb.Text = "機能 " .. countOf(s) .. " 個の説明" end
		backH.Visible = true
		hdrs = {}
		if #s.groups > 1 then   -- 見出しへ飛ぶボタン
			local row = mk("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, scroll)
			mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
			for k, g in ipairs(s.groups) do
				local chip = mk("TextButton", { AutoButtonColor = false, Text = g[1], TextSize = isMobile and 12 or 13, FontFace = FONT, TextColor3 = WHITE, LayoutOrder = k, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X }, row)
				Lib.glass(chip, 0.82, 14)
				mk("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, chip)
				Lib.juice(chip)
				chip.MouseButton1Click:Connect(function() jumpTo(k) end)
			end
		end
		for k, g in ipairs(s.groups) do
			hdrs[k] = titleBar(k * 100, g[1] .. "  (" .. #g[2] .. ")")
			for fi, f in ipairs(g[2]) do
				local c = box(k * 100 + fi, 0.88)
				local nameL = para(c, f[1], 15, CYAN, 1)
				nameL.LineHeight = 1
				para(c, f[2], FS_BODY, WHITE, 2)
			end
		end
		if gi then jumpTo(gi) end
	end

	local function clear()
		for _, c in ipairs(scroll:GetChildren()) do
			if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
		end
	end
	render = function(animate)
		clear()
		scroll.CanvasPosition = Vector2.new(0, 0)
		if view.level == 0 then
			renderRoot()
		elseif view.level == 1 then
			renderSection(view.sec)
		else
			renderFeatures(view.sec, view.gi)
		end
		if animate then   -- 横からふわっと入ってくる
			scroll.Position = UDim2.fromOffset(18, 0)
			Lib.tween(scroll, { Position = UDim2.fromOffset(0, 0) }, 0.4)
		end
	end

	backH.MouseButton1Click:Connect(function()
		if view.level >= 2 then go(1, view.sec) elseif view.level == 1 then go(0, 0) end
	end)

	-- 開く / 閉じる ----------------------------------------------------
	local blobTw = {}
	local function blobsRun(on)
		for _, t in ipairs(blobTw) do t:Cancel() end
		blobTw = {}
		local show = blobEnabled and blobStyleOn
		hb1.Visible, hb2.Visible = show, show
		if not on or not show then return end
		for _, e in ipairs({ { hb1, UDim2.fromScale(0.7, 0.24), 7 }, { hb2, UDim2.fromScale(0.22, 0.8), 8 } }) do
			local tw = TweenService:Create(e[1], TweenInfo.new(e[3], Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = e[2] })
			tw:Play()
			blobTw[#blobTw + 1] = tw
		end
	end

	function UIs.openHelp()
		if hOpen then return end
		hOpen = true
		UIs.helpOpen = true
		if UIs.pv.hideForHelp then pcall(UIs.pv.hideForHelp, true) end   -- プレビューの小さな窓は、ヘルプの間だけ隠す
		toggle.Visible = false
		view.level, view.sec, view.gi = 0, 0, nil
		hBgGrad.Color = bgGrad.Color   -- 本体と同じ背景の色・光にそろえる
		hb1.BackgroundColor3 = blob1.BackgroundColor3
		hb2.BackgroundColor3 = blob2.BackgroundColor3
		hw.Position = win.Position
		fit()
		render(false)
		setOpen(false)   -- 本体は閉じる
		hw.Visible = true
		hScale.Scale = 0.9 * fitScale
		hw.GroupTransparency = 1
		Lib.tween(hScale, { Scale = fitScale }, 0.6)
		Lib.tween(hw, { GroupTransparency = uiCfg.alpha }, 0.4)
		blobsRun(true)
	end

	function UIs.closeHelp()
		if not hOpen then return end
		hOpen = false
		UIs.helpOpen = false
		blobsRun(false)
		Lib.tween(hScale, { Scale = 0.9 * fitScale }, 0.4)
		local t = Lib.tween(hw, { GroupTransparency = 1 }, 0.3)
		t.Completed:Connect(function()
			if not hOpen then hw.Visible = false end
		end)
		toggle.Visible = toggleRevealed
		setOpen(true)   -- 本体を、もう一度開く
		if UIs.pv.hideForHelp then pcall(UIs.pv.hideForHelp, false) end
	end
	closeH.MouseButton1Click:Connect(function() UIs.closeHelp() end)
	Lib.drag(top, hw)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if hOpen then
			fit()
			Lib.tween(hScale, { Scale = fitScale }, 0.3)
		end
	end)
	-- テストや点検のための窓口 (画面の動きには関係しない)
	UIs.helpDbg = { go = go, view = view, data = HELP, win = hw, scroll = scroll }
end
---------------------------------------------------------------------
-- プレビュー (画面の左に開く、小さなウィンドウ)
--  ふつうの見た目の板の3Dモデル (見本の複製) を ViewportFrame に入れて、ゆっくり左まわりに回して見せる。
--  本体で色・素材などを変えると、その操作は「プレビューの板」に送られる (本物の板は変わらない・サーバーにも送らない)。
--  ドラッグで360度まわせる (さわっている間と、そのあと10秒は自動の回転を止める)。
--  ViewportFrame には、重ね貼り(SurfaceGui)・粒・ライト・縁取りが出せないので、近い見た目を別の方法でまねる:
--    ・重ね貼り (グラデ・ツヤ・光の走り) → 面の上に薄い板を敷きつめ、色と透明度を重ねて決める (計算は pvmath)
--    ・角の輝き → 面のふちに細い板 / 光 → うしろのにじみ / 縁取り → 窓のふち / 炎・雪などの粒 → 窓の上の2Dの粒
--  「💾 メイン保存」で、いまの見た目を「プリセットN」として、左のページ一覧の「その他」の下に保存する (押すと一瞬でその見た目になる)。
---------------------------------------------------------------------
-- (専用の関数の中に入れてある: メインのローカル変数が増えないように)
(function()
	local PVM = (function()
---------------------------------------------------------------------
-- プレビュー用の「数字だけ」の計算 (Roblox の部品は使わない。テストしやすいように、画面の部品と分けてある)
--  ・グラデーション(色・透明度の並び)を、板の面の上の位置から読む
--  ・面を何×何のマス(薄い板)に分けるか / 全体の数の配分
--  ・見る位置(カメラ)の回りかた
--  ・プレビューの中に出す「まねっこの粒」(炎・雪・桜など) の動き
---------------------------------------------------------------------
local PVM = {}

-- 並び keys = { {t, 値}, ... } (tは小さい順) を、位置 t で読む。範囲の外は端の値
function PVM.num(keys, t)
	local n = #keys
	if n == 0 then return 0 end
	if t ~= t then t = 0 end
	if t <= keys[1][1] then return keys[1][2] end
	if t >= keys[n][1] then return keys[n][2] end
	for i = 2, n do
		local k1 = keys[i]
		if t <= k1[1] then
			local k0 = keys[i - 1]
			local span = k1[1] - k0[1]
			if span <= 1e-9 then return k1[2] end
			return k0[2] + (k1[2] - k0[2]) * ((t - k0[1]) / span)
		end
	end
	return keys[n][2]
end

-- 色の並び keys = { {t, r, g, b}, ... } を、位置 t で読む → r, g, b
function PVM.col(keys, t)
	local n = #keys
	if n == 0 then return 1, 1, 1 end
	if t ~= t then t = 0 end
	if t <= keys[1][1] then local k = keys[1] return k[2], k[3], k[4] end
	if t >= keys[n][1] then local k = keys[n] return k[2], k[3], k[4] end
	for i = 2, n do
		local k1 = keys[i]
		if t <= k1[1] then
			local k0 = keys[i - 1]
			local span = k1[1] - k0[1]
			if span <= 1e-9 then return k1[2], k1[3], k1[4] end
			local u = (t - k0[1]) / span
			return k0[2] + (k1[2] - k0[2]) * u, k0[3] + (k1[3] - k0[3]) * u, k0[4] + (k1[4] - k0[4]) * u
		end
	end
	local k = keys[n]
	return k[2], k[3], k[4]
end

-- UIGradient の「位置 t」。(px, py) は面の真ん中を原点にした位置 (px=右, py=下。単位は面と同じ)、W×H は面の大きさ、
-- deg は Rotation(度)、(ox, oy) は Offset (面の大きさに対する割合)。0 = はじ / 1 = 反対のはじ
function PVM.faceT(px, py, W, H, deg, ox, oy)
	local r = math.rad(deg or 0)
	local c, s = math.cos(r), math.sin(r)
	local L = W * math.abs(c) + H * math.abs(s)
	if L < 1e-9 then return 0.5 end
	return 0.5 + ((px - (ox or 0) * W) * c + (py - (oy or 0) * H) * s) / L
end

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end
PVM.clamp = clamp

-- 面 (W×H) を、マス目 nu(横) × nv(縦) に分ける。cap は使ってよいマスの数。グラデの向きが横か縦なら、その方向だけに細かく分ける
function PVM.layout(W, H, deg, cap, maxAxis, maxCell)
	cap = math.max(1, math.floor(cap or 1))
	maxAxis = maxAxis or 40
	maxCell = maxCell or 12
	if W <= 1e-6 or H <= 1e-6 then return 1, 1 end
	local r = math.rad(deg or 0)
	local c, s = math.abs(math.cos(r)), math.abs(math.sin(r))
	if s < 0.06 then return clamp(cap, 1, maxAxis), 1 end
	if c < 0.06 then return 1, clamp(cap, 1, maxAxis) end
	local nu = clamp(math.floor(math.sqrt(cap * W / H) + 0.5), 1, maxCell)
	local nv = clamp(math.floor(cap / nu), 1, maxCell)
	while nu * nv > cap and (nu > 1 or nv > 1) do
		if nu >= nv and nu > 1 then nu = nu - 1 else nv = nv - 1 end
	end
	return nu, nv
end

-- 全体で total 個までの中で、重み(面の広さ)に比例してマスの数を配る。lo〜hi の範囲。足りなければ、みんな lo 以下になる
function PVM.alloc(weights, total, lo, hi)
	local n = #weights
	local out = {}
	if n == 0 then return out end
	lo, hi = lo or 1, hi or 48
	if n > total then   -- 面が予算より多い: 広い面から 1マスずつだけ配って、残りは 0 (その面は出さない)
		local order = {}
		for i = 1, n do order[i] = i end
		table.sort(order, function(a, b)
			if weights[a] ~= weights[b] then return weights[a] > weights[b] end
			return a < b
		end)
		for i = 1, n do out[i] = 0 end
		for r = 1, math.max(0, math.floor(total)) do out[order[r]] = 1 end
		return out
	end
	local sum = 0
	for i = 1, n do sum = sum + math.max(weights[i], 1e-9) end
	for i = 1, n do
		local share = math.floor(total * math.max(weights[i], 1e-9) / sum + 0.5)
		out[i] = clamp(share, lo, hi)
	end
	local used = 0
	for i = 1, n do used = used + out[i] end
	-- 多すぎたら、大きいところから 1つずつ減らす (下限までは減らす。それでも多ければ、下限も割る)
	local guard = 0
	while used > total and guard < 100000 do
		guard = guard + 1
		local bi, bv = nil, 0
		for i = 1, n do
			if out[i] > bv then bi, bv = i, out[i] end
		end
		if not bi or bv <= 1 then break end
		out[bi] = out[bi] - 1
		used = used - 1
	end
	return out
end

-- カメラの位置。中心 (cx,cy,cz) のまわりを、向き yaw(横) と高さ pitch(上下) で、距離 dist の所へ回す。yaw=0, pitch=0 は +Z がわ
function PVM.orbit(cx, cy, cz, yaw, pitch, dist)
	local cp = math.cos(pitch)
	return cx + dist * cp * math.sin(yaw), cy + dist * math.sin(pitch), cz + dist * cp * math.cos(yaw)
end
-- 見る高さは真上・真下の手前までにする
PVM.PITCH_MAX = 1.4
function PVM.clampPitch(p) return clamp(p, -PVM.PITCH_MAX, PVM.PITCH_MAX) end
-- 板が半径 radius の球に収まる時の、画面いっぱいになる距離
function PVM.fitDist(radius, fovDeg, margin)
	local half = math.rad((fovDeg or 40) / 2)
	return radius / math.sin(half) * (margin or 1)
end
-- 自動で回る角度 (カメラの向き) を進める。dir=1: 角度が増える (カメラが右へまわるので、板は右まわりに見える) / dir=-1: 減る (板は左まわりに見える)
function PVM.spin(yaw, dt, speed, dir)
	return (yaw + dt * speed * dir) % (math.pi * 2)
end
-- 何もしていない時間が idle 秒を超えたら、自動で回る
function PVM.autoSpin(now, lastTouch, idle, dragging)
	return (not dragging) and (now - lastTouch >= idle)
end

---------------------------------------------------------------------
-- まねっこの粒 (プレビューの窓の中だけで出す、2Dの粒)
--  位置 x,y は窓に対する割合 (0〜1, yは下が大きい)。大きさ s はピクセル。速さは「1秒に窓の高さの何割」
--  rnd = 0〜1 の乱数を返す関数
---------------------------------------------------------------------
local FXK = {
	fire = { life = { 0.7, 1.3 }, s0 = 13, s1 = 3, a0 = 0.35, a1 = 1, round = true },
	smoke = { life = { 2.4, 3.6 }, s0 = 8, s1 = 26, a0 = 0.6, a1 = 1, round = true },
	sparkle = { life = { 1, 2 }, s0 = 4, s1 = 0, a0 = 0, a1 = 1, round = true },
	confetti = { life = { 1.6, 2.6 }, s0 = 6, s1 = 6, a0 = 0, a1 = 0.9, round = false },
	snow = { life = { 3.5, 5.5 }, s0 = 4, s1 = 3, a0 = 0.15, a1 = 1, round = true },
	sakura = { life = { 3.5, 5.5 }, s0 = 7, s1 = 5, a0 = 0.15, a1 = 1, round = false },
	firefly = { life = { 3, 5 }, s0 = 5, s1 = 5, a0 = 0.9, a1 = 1, round = true },
	bubbles = { life = { 2, 3.5 }, s0 = 6, s1 = 14, a0 = 0.6, a1 = 1, round = true },
	embers = { life = { 1.4, 2.8 }, s0 = 3.5, s1 = 1, a0 = 0.1, a1 = 1, round = true },
}
PVM.FXK = FXK
PVM.FX_NAMES = { "fire", "smoke", "sparkle", "confetti", "snow", "sakura", "firefly", "bubbles", "embers" }

local function rr(rnd, a, b) return a + (b - a) * rnd() end

-- 新しい粒を1つ作る。kind は効果の名前。戻り値は { kind, x, y, vx, vy, ax, ay, age, life, s0, s1, a0, a1, rot, vr, hue }
function PVM.spawn(kind, rnd)
	local k = FXK[kind]
	if not k then return nil end
	local p = {
		kind = kind, age = 0, life = rr(rnd, k.life[1], k.life[2]), s0 = k.s0, s1 = k.s1, a0 = k.a0, a1 = k.a1, round = k.round,
		x = 0.5, y = 0.6, vx = 0, vy = 0, ax = 0, ay = 0, rot = 0, vr = 0, hue = rnd(), wob = rnd() * 6.28,
	}
	if kind == "fire" then
		p.x, p.y = rr(rnd, 0.38, 0.62), rr(rnd, 0.56, 0.64)
		p.vx, p.vy = rr(rnd, -0.03, 0.03), rr(rnd, -0.38, -0.55)
	elseif kind == "smoke" then
		p.x, p.y = rr(rnd, 0.38, 0.62), rr(rnd, 0.5, 0.58)
		p.vx, p.vy = rr(rnd, -0.02, 0.04), rr(rnd, -0.1, -0.16)
	elseif kind == "sparkle" then
		p.x, p.y = rr(rnd, 0.22, 0.78), rr(rnd, 0.3, 0.7)
		p.vx, p.vy = rr(rnd, -0.02, 0.02), rr(rnd, -0.08, -0.02)
	elseif kind == "confetti" then
		p.x, p.y = rr(rnd, 0.42, 0.58), rr(rnd, 0.52, 0.6)
		p.vx, p.vy = rr(rnd, -0.3, 0.3), rr(rnd, -0.75, -0.45)
		p.ay = 1.5
		p.rot, p.vr = rnd() * 360, rr(rnd, -300, 300)
	elseif kind == "snow" then
		p.x, p.y = rr(rnd, 0.12, 0.88), rr(rnd, 0.02, 0.1)
		p.vx, p.vy = rr(rnd, -0.02, 0.02), rr(rnd, 0.1, 0.16)
	elseif kind == "sakura" then
		p.x, p.y = rr(rnd, 0.12, 0.88), rr(rnd, 0.02, 0.1)
		p.vx, p.vy = rr(rnd, -0.03, 0.03), rr(rnd, 0.07, 0.12)
		p.rot, p.vr = rnd() * 360, rr(rnd, -120, 120)
	elseif kind == "firefly" then
		p.x, p.y = rr(rnd, 0.2, 0.8), rr(rnd, 0.3, 0.8)
		p.vx, p.vy = rr(rnd, -0.03, 0.03), rr(rnd, -0.03, 0.02)
	elseif kind == "bubbles" then
		p.x, p.y = rr(rnd, 0.28, 0.72), rr(rnd, 0.62, 0.72)
		p.vx, p.vy = rr(rnd, -0.02, 0.02), rr(rnd, -0.14, -0.2)
	elseif kind == "embers" then
		p.x, p.y = rr(rnd, 0.3, 0.7), rr(rnd, 0.58, 0.66)
		p.vx, p.vy = rr(rnd, -0.05, 0.05), rr(rnd, -0.2, -0.38)
	end
	return p
end

-- 1つの粒を dt 秒ぶん進める。まだ生きていれば true
function PVM.step(p, dt)
	p.age = p.age + dt
	if p.age >= p.life then return false end
	p.vx = p.vx + p.ax * dt
	p.vy = p.vy + p.ay * dt
	local drift = 0
	if p.kind == "snow" or p.kind == "sakura" then
		drift = math.sin(p.age * 1.8 + p.wob) * 0.045
	elseif p.kind == "firefly" or p.kind == "bubbles" then
		drift = math.sin(p.age * 1.3 + p.wob) * 0.03
	end
	p.x = p.x + (p.vx + drift) * dt
	p.y = p.y + p.vy * dt
	p.rot = p.rot + p.vr * dt
	return true
end

-- 粒の「いま」の見た目: 大きさ(px), 透明度(0=はっきり〜1=見えない), 0〜1の進み具合
function PVM.look(p)
	local u = math.min(1, math.max(0, p.age / p.life))
	local size = p.s0 + (p.s1 - p.s0) * u
	local a
	if p.kind == "firefly" then
		a = 0.15 + 0.55 * (0.5 + 0.5 * math.sin(p.age * 3.2 + p.wob))
		if u < 0.15 then a = 1 - (1 - a) * (u / 0.15) elseif u > 0.85 then a = 1 - (1 - a) * ((1 - u) / 0.15) end
	elseif p.kind == "sparkle" then
		local tw = math.sin(u * math.pi)
		a = 1 - tw
	else
		-- ふわっと出て、終わりに消える。a0 = いちばんはっきりした時の透明度
		local fin = math.min(1, u / 0.12)
		local fout = u > 0.6 and (1 - (u - 0.6) / 0.4) or 1
		a = 1 - fin * fout * (1 - p.a0)
	end
	return size, math.min(1, math.max(0, a)), u
end


---------------------------------------------------------------------
-- 面の上の「マス」 (プレビューは、重ね貼りの SurfaceGui を直接は出せないので、面の上に薄い板を敷きつめて見せる)
---------------------------------------------------------------------
-- 面の座標系。c = { x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 } (CFrame:GetComponents() の並び) / size = { X, Y, Z } /
-- r, u = 面の「右」「上」 (パーツの座標系での向き。エンジンの面の表 FACES と同じ決まり)
-- 戻り値: 面の中心 cx,cy,cz / 世界での 右 rx,ry,rz / 上 ux,uy,uz / 外向き nx,ny,nz / 面の大きさ w(横) h(縦)
function PVM.faceBasis(c, size, r, u)
	local function toWorld(lx, ly, lz)
		return c[4] * lx + c[5] * ly + c[6] * lz, c[7] * lx + c[8] * ly + c[9] * lz, c[10] * lx + c[11] * ly + c[12] * lz
	end
	local nx = r[2] * u[3] - r[3] * u[2]   -- 外向き = 右 × 上 (パーツの座標系)
	local ny = r[3] * u[1] - r[1] * u[3]
	local nz = r[1] * u[2] - r[2] * u[1]
	local sx, sy, sz = size[1], size[2], size[3]
	local b = {}
	b.w = math.abs(r[1]) * sx + math.abs(r[2]) * sy + math.abs(r[3]) * sz
	b.h = math.abs(u[1]) * sx + math.abs(u[2]) * sy + math.abs(u[3]) * sz
	local half = 0.5 * (math.abs(nx) * sx + math.abs(ny) * sy + math.abs(nz) * sz)
	local ox, oy, oz = toWorld(nx * half, ny * half, nz * half)
	b.cx, b.cy, b.cz = c[1] + ox, c[2] + oy, c[3] + oz
	b.rx, b.ry, b.rz = toWorld(r[1], r[2], r[3])
	b.ux, b.uy, b.uz = toWorld(u[1], u[2], u[3])
	b.nx, b.ny, b.nz = toWorld(nx, ny, nz)
	return b
end

-- マス (i 列目 / j 行目。左上が 1,1) の真ん中。戻り値: 世界の位置 x,y,z と、面の中心から見た位置 px(右), py(下) (面の単位)
function PVM.cellPos(b, nu, nv, i, j)
	local px = ((i - 0.5) / nu - 0.5) * b.w
	local py = ((j - 0.5) / nv - 0.5) * b.h
	return b.cx + b.rx * px - b.ux * py, b.cy + b.ry * px - b.uy * py, b.cz + b.rz * px - b.uz * py, px, py
end

-- 1枚の層 L の、位置 (px, py) での 色 r,g,b と 濃さ a (0=見えない〜1=不透明)。
-- L = { r, g, b (背景色), bgT (背景の透明度), rot, ox, oy (UIGradient の Rotation / Offset), ck (色の並び), nk (透明度の並び) }
function PVM.layerAt(L, px, py, W, H)
	local t = PVM.faceT(px, py, W, H, L.rot, L.ox, L.oy)
	local r, g, b = L.r, L.g, L.b
	if L.ck then
		local cr, cg, cb = PVM.col(L.ck, t)
		r, g, b = r * cr, g * cg, b * cb
	end
	local gt = L.nk and PVM.num(L.nk, t) or 0
	return r, g, b, (1 - L.bgT) * (1 - gt)
end

-- 下の層から順に重ねた結果を、1枚の板 (色 + 濃さ) にまとめる。下の板の上に重ねた見た目が、重ねた順に1枚ずつ重ねた時と同じになる。
-- 戻り値: r, g, b, a  (a = 1 - ぜんぶの層の「透けている割合」の積。a が 0 のときの色は意味がない)
function PVM.blend(layers, px, py, W, H)
	local pr, pg, pb, T = 0, 0, 0, 1
	for i = 1, #layers do
		local r, g, b, a = PVM.layerAt(layers[i], px, py, W, H)
		if a > 0.0005 then
			pr = pr * (1 - a) + r * a
			pg = pg * (1 - a) + g * a
			pb = pb * (1 - a) + b * a
			T = T * (1 - a)
		end
	end
	local A = 1 - T
	if A < 0.0005 then return 1, 1, 1, 0 end
	return pr / A, pg / A, pb / A, A
end

-- 光 (SkinGlow) のにじみ: 明るさ 0〜(5くらい) → 濃さ 0〜1 / 広さ (Range 4〜60) → プレビューの窓に対する大きさ
function PVM.haloK(brightness)
	if brightness ~= brightness or brightness <= 0.01 then return 0 end
	return clamp(brightness / 3.5, 0, 1)
end
function PVM.haloSize(range)
	if range ~= range then range = 8 end
	return clamp(0.5 + range / 40, 0.55, 1.5)
end
-- にじみの輪 (外から内へ 4枚)。k = 濃さ 0〜1 → 各輪の「見えにくさ」(1 = 見えない)
function PVM.haloRings(k)
	return { 1 - 0.1 * k, 1 - 0.16 * k, 1 - 0.24 * k, 1 - 0.34 * k }
end

return PVM
	end)()

	local pv = UIs.pv
	local CS_W, CS_H = 292, 410                 -- 窓の大きさ (スマホは UIScale で小さくする)
	local ST_W, ST_H = CS_W - 20, 250           -- 3D を出す部分
	local SPIN_SPEED, IDLE_SEC, FOV = 0.3, 10, 38
	local CELLS_TOTAL = isMobile and 240 or 420 -- 重ね貼りのまねに使う板の数 (全部あわせて)
	local EDGE_FACES = isMobile and 10 or 24    -- 角の輝きの線を引く面の数
	local MAX_SPRITES = isMobile and 22 or 36   -- 窓の上に出す粒の数 (全部あわせて)
	local ANIM_HZ = isMobile and 20 or 30       -- 動く重ね貼り (流れる色・光の走り) を塗り直す回数 (1秒に)
	local HOME_YAW, HOME_PITCH = 0.55, 0.42
	local FACE_AX = {}                          -- エンジンの面の表 → 数字だけの向き
	for _, f in ipairs(ENG.FACES) do
		FACE_AX[f[1]] = { { f[2].X, f[2].Y, f[2].Z }, { f[3].X, f[3].Y, f[3].Z } }
	end
	local FX_BASE = {                           -- 粒の色 (板に付いている粒の色が読めた時は、そちらを使う)
		fire = Color3.fromRGB(255, 150, 50), smoke = Color3.fromRGB(130, 130, 140), sparkle = Color3.fromRGB(255, 244, 170),
		confetti = Color3.fromRGB(255, 120, 200), snow = Color3.fromRGB(240, 248, 255), sakura = Color3.fromRGB(255, 170, 200),
		firefly = Color3.fromRGB(205, 255, 120), bubbles = Color3.fromRGB(170, 225, 255), embers = Color3.fromRGB(255, 120, 40),
	}

	local UI        -- ウィンドウの部品 (最初に開いた時に作って、あとは使いまわす)
	local P         -- 開いている間の状態 (閉じたら nil)
	local presets = {}   -- 保存したプリセット { n = 番号, ops = { {種類, 値}, ... }, btn = ボタン }
	local wireUI, savePreset, wired   -- (下で作る。ボタンの接続は、最初にプレビューを開いた時に1回だけ)

	local function touch() if P then P.lastTouch = os.clock() end end
	local SAVE_TEXT = "💾 メイン保存"

	---------------------------------------------------------------------
	-- ウィンドウ
	---------------------------------------------------------------------
	local function buildWindow()
		local u = {}
		u.win = mk("CanvasGroup", { Name = "PreviewWindow", BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, Active = true, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 24, 0.5, 0), Size = UDim2.fromOffset(CS_W, CS_H) }, gui)
		corner(u.win, 20)
		local st = stroke(u.win, 0.35, WHITE, 1.5)
		mk("UIGradient", { Rotation = 90, Color = winStrokeGrad.Color }, st)
		u.scale = mk("UIScale", {}, u.win)
		mk("TextButton", { Name = "InputSink", AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 0, Active = true }, u.win)
		local bg = mk("Frame", { Name = "Bg", BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, u.win)
		u.bgGrad = mk("UIGradient", { Rotation = 35, Color = bgGrad.Color }, bg)

		u.top = mk("Frame", { Name = "TopBar", Active = true, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(CS_W - 20, 34) }, u.win)
		Lib.glass(u.top, 0.86, 14)
		text(u.top, "👁 プレビュー", 17, UDim2.fromOffset(12, 0), UDim2.new(1, -60, 1, 0))
		u.close = mk("TextButton", { Name = "Close", AutoButtonColor = false, Text = "✕", TextSize = 14, FontFace = FONT, TextColor3 = WHITE, Position = UDim2.new(1, -34, 0.5, -13), Size = UDim2.fromOffset(26, 26) }, u.top)
		Lib.glass(u.close, 0.75, 13)
		Lib.juice(u.close)

		-- 3D を出す部分 (うしろ: 背景 → 光のにじみ / 3D / 粒 / 縁取り / ドラッグを受ける透明ボタン)
		u.stage = mk("Frame", { Name = "Stage", BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true, Position = UDim2.fromOffset(10, 48), Size = UDim2.fromOffset(ST_W, ST_H) }, u.win)
		corner(u.stage, 14)
		stroke(u.stage, 0.45, WHITE, 1)
		mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(44, 50, 96), Color3.fromRGB(8, 10, 24)) }, u.stage)
		u.halo = {}
		for k = 1, 4 do
			local c = mk("Frame", { Name = "Halo" .. k, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(10, 10) }, u.stage)
			mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, c)
			u.halo[k] = c
		end
		u.vp = mk("ViewportFrame", { Name = "View", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Ambient = Color3.fromRGB(128, 132, 156), LightColor = Color3.fromRGB(255, 246, 232), LightDirection = Vector3.new(-0.45, -1, -0.6) }, u.stage)
		u.fx = mk("Frame", { Name = "Fx", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, u.stage)
		u.sprites = {}
		for k = 1, MAX_SPRITES do
			local f = mk("Frame", { Name = "Sprite", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Size = UDim2.fromOffset(6, 6) }, u.fx)
			mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
			u.sprites[k] = f
		end
		u.ring = mk("Frame", { Name = "Outline", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, u.stage)
		corner(u.ring, 14)
		u.ringStroke = mk("UIStroke", { Color = WHITE, Thickness = 3, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, u.ring)
		u.grab = mk("TextButton", { Name = "Grab", AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 5, Active = true }, u.stage)

		-- 操作ボタン: － ＋ ↺ ↻ 🎯
		local bw = math.floor((ST_W - 4 * 6) / 5)
		local bx = 10 + math.floor((ST_W - (5 * bw + 4 * 6)) / 2)
		local function pbtn(k, name, label)
			local b = mk("TextButton", { Name = name, AutoButtonColor = false, Text = label, TextSize = 17, FontFace = FONT, TextColor3 = WHITE, Position = UDim2.fromOffset(bx + (k - 1) * (bw + 6), 306), Size = UDim2.fromOffset(bw, 30) }, u.win)
			Lib.glass(b, 0.84, 10)
			Lib.juice(b)
			return b
		end
		u.bOut, u.bIn = pbtn(1, "Zoom－", "－"), pbtn(2, "Zoom＋", "＋")
		u.bLeft, u.bRight, u.bHome = pbtn(3, "Spin↺", "↺"), pbtn(4, "Spin↻", "↻"), pbtn(5, "Home", "🎯")
		u.status = text(u.win, "", 12, UDim2.fromOffset(10, 340), UDim2.fromOffset(CS_W - 20, 16), Enum.TextXAlignment.Center, SOFT)
		u.save = mk("TextButton", { Name = "メイン保存", AutoButtonColor = false, Text = SAVE_TEXT, TextSize = 16, FontFace = FONT, TextColor3 = WHITE, Position = UDim2.fromOffset(10, 362), Size = UDim2.fromOffset(CS_W - 20, 34), ClipsDescendants = true }, u.win)
		Lib.glass(u.save, 0.1, 12)
		u.save.BackgroundColor3 = WHITE
		mk("UIGradient", { Rotation = 20, Color = ColorSequence.new(Color3.fromRGB(16, 185, 129), Color3.fromRGB(56, 189, 248)) }, u.save)
		Lib.juice(u.save)
		return u
	end

	-- 窓の位置と大きさ: PC は本体の反対がわ (左) に / スマホは左上に小さく (ドラッグで動かせる)
	local function place()
		local vpS = gui.AbsoluteSize
		local s
		if isMobile then   -- 左上に、画面のよこ半分までの大きさで (ドラッグで動かせる)
			s = math.clamp(math.min(vpS.X * 0.5 / CS_W, (vpS.Y - 24) / CS_H), 0.55, 0.9)
			UI.win.AnchorPoint = Vector2.new(0, 0)
			UI.win.Position = UDim2.new(0, 8, 0, 8)
		else   -- 本体は右はしに開くので、左の空いている所に出す (空きが足りなければ小さくする)
			local free = vpS.X - W * fitScale - 24 - 24 - 12
			s = math.clamp(math.min(free / CS_W, (vpS.Y - 32) / CS_H, 1), 0.6, 1)
			UI.win.AnchorPoint = Vector2.new(0, 0.5)
			UI.win.Position = UDim2.new(0, 24, 0.5, 0)
		end
		return s
	end

	---------------------------------------------------------------------
	-- 重ね貼りのまねっこ (面の上に薄い板を敷きつめる)
	---------------------------------------------------------------------
	local Mir = {}
	local V3 = Vector3.new
	local function readLayer(sg, name)
		local fr = sg:FindFirstChild(name)
		if not fr then return nil end
		local gr = fr:FindFirstChildOfClass("UIGradient")
		local bc = fr.BackgroundColor3
		local L = { fr = fr, gr = gr, r = bc.R, g = bc.G, b = bc.B, bgT = fr.BackgroundTransparency, rot = 0, ox = 0, oy = 0 }
		if gr then
			L.rot = gr.Rotation
			local off = gr.Offset
			L.ox, L.oy = off.X, off.Y
			local ck, nk = {}, {}
			for _, k in ipairs(gr.Color.Keypoints) do
				local v = k.Value
				ck[#ck + 1] = { k.Time, v.R, v.G, v.B }
			end
			for _, k in ipairs(gr.Transparency.Keypoints) do nk[#nk + 1] = { k.Time, k.Value } end
			L.ck, L.nk = ck, nk
		end
		return L
	end

	local function newPlate(folder)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Transparency = 1
		p.Parent = folder
		return p
	end
	local function plateAt(p, b, fx, fy, sx, sy, th, off)   -- 面の上 (中心から 右へ fx / 上へ fy) に、大きさ sx × sy の板を置く
		p.Size = V3(math.max(sx, 1e-3), math.max(sy, 1e-3), th)
		p.CFrame = CFrame.fromMatrix(V3(b.cx + b.rx * fx + b.ux * fy + b.nx * off, b.cy + b.ry * fx + b.uy * fy + b.ny * off, b.cz + b.rz * fx + b.uz * fy + b.nz * off), V3(b.rx, b.ry, b.rz), V3(b.ux, b.uy, b.uz))
	end
	local EDGE_LIGHT, EDGE_DARK = Color3.new(0.97, 0.98, 1), Color3.new(0.36, 0.37, 0.43)

	-- 角の輝きの線 (4本)。細すぎる面や、数の上限を超えた面には引かない
	local function buildEdge(rec, off, th)
		for _, s in ipairs(rec.strips) do s:Destroy() end
		rec.strips = {}
		local fe = rec.sg:FindFirstChild("Edge")
		local es = fe and fe:FindFirstChildOfClass("UIStroke")
		if not es or P.edgeLeft <= 0 then return end
		P.edgeLeft = P.edgeLeft - 1
		local b = rec.b
		local cv = rec.sg.CanvasSize
		local k = math.max(b.w, b.h) / math.max(cv.X, cv.Y, 1)   -- 画面の点 → 板の大きさ
		local inset, t = fe.Position.X.Offset * k, math.max(es.Thickness * k, 0.01)
		local tr = es.Transparency
		local function strip(fx, fy, sx, sy, col)
			local p = newPlate(P.folder)
			plateAt(p, b, fx, fy, sx, sy, th, off * 2)
			p.Color = col
			p.Transparency = tr
			rec.strips[#rec.strips + 1] = p
		end
		local hw, hh = b.w / 2 - inset - t / 2, b.h / 2 - inset - t / 2
		strip(0, hh, b.w - 2 * inset, t, EDGE_LIGHT)
		strip(-hw, 0, t, b.h - 2 * inset - 2 * t, EDGE_LIGHT)
		strip(0, -hh, b.w - 2 * inset, t, EDGE_DARK)
		strip(hw, 0, t, b.h - 2 * inset - 2 * t, EDGE_DARK)
	end

	-- 面ひとつぶんの板を、いまの重ね貼りの中身に合わせて塗る (変わったマスだけ書く)
	local function paintRec(rec)
		local Ls, n, b = rec.layers, rec.nu * rec.nv, rec.b
		local cache = rec.cache
		for i = 1, n do
			local r, g, bl, a = PVM.blend(Ls, rec.pxs[i], rec.pys[i], b.w, b.h)
			local c = cache[i]
			if not c then
				c = { -1, -1, -1, -1 }
				cache[i] = c
			end
			if math.abs(c[1] - r) > 0.004 or math.abs(c[2] - g) > 0.004 or math.abs(c[3] - bl) > 0.004 or math.abs(c[4] - a) > 0.004 then
				c[1], c[2], c[3], c[4] = r, g, bl, a
				local pl = rec.plates[i]
				pl.Color = Color3.new(r, g, bl)
				pl.Transparency = 1 - a
			end
		end
	end

	-- 板の上の SurfaceGui (重ね貼り) を読み直して、板 (マス) を作る/直す/消す。形が同じ面は、板を作り直さずに色だけ直す
	function Mir.sync()
		local pm = P.pm
		local recs, list = {}, {}
		for _, part in ipairs(pm:GetChildren()) do
			if part:IsA("BasePart") then
				for _, sg in ipairs(part:GetChildren()) do
					if sg.Name == "SkinFace" and sg:IsA("SurfaceGui") then
						local ax = FACE_AX[sg.Face.Name]
						if ax then
							local comps = { part.CFrame:GetComponents() }
							local sz = part.Size
							local rec = P.recs[sg] or { sg = sg, plates = {}, cache = {}, pxs = {}, pys = {}, strips = {}, nu = 0, nv = 0 }
							rec.part = part
							rec.b = PVM.faceBasis(comps, { sz.X, sz.Y, sz.Z }, ax[1], ax[2])
							local Ls = {}
							rec.G, rec.Gloss, rec.Sheen = readLayer(sg, "G"), readLayer(sg, "Gloss"), readLayer(sg, "Sheen")
							for _, L in ipairs({ rec.G or false, rec.Gloss or false, rec.Sheen or false }) do
								if L then Ls[#Ls + 1] = L end
							end
							rec.layers = Ls
							recs[sg] = rec
							list[#list + 1] = rec
						end
					end
				end
			end
		end
		-- なくなった面の板は片づける
		for sg, rec in pairs(P.recs) do
			if not recs[sg] then
				for _, pl in ipairs(rec.plates) do pl:Destroy() end
				for _, pl in ipairs(rec.strips) do pl:Destroy() end
			end
		end
		P.recs = recs
		-- 広い面ほど多くのマスをあげる
		local want, weights = {}, {}
		for _, rec in ipairs(list) do
			if #rec.layers > 0 then
				want[#want + 1] = rec
				weights[#weights + 1] = rec.b.w * rec.b.h
			end
		end
		local caps = PVM.alloc(weights, CELLS_TOTAL, 2, 48)
		local off = P.eps
		local th = P.eps * 0.4
		local isWant = {}
		for k, rec in ipairs(want) do
			isWant[rec] = true
			local L = rec.G or rec.Gloss or rec.Sheen
			local nu, nv = 0, 0
			if caps[k] > 0 then nu, nv = PVM.layout(rec.b.w, rec.b.h, L.rot, caps[k]) end
			if nu ~= rec.nu or nv ~= rec.nv then   -- 形が変わった: 板を作り直す
				for _, pl in ipairs(rec.plates) do pl:Destroy() end
				rec.plates, rec.cache, rec.pxs, rec.pys = {}, {}, {}, {}
				rec.nu, rec.nv = nu, nv
				local i = 0
				for j = 1, nv do
					for ii = 1, nu do
						i = i + 1
						local _, _, _, px, py = PVM.cellPos(rec.b, nu, nv, ii, j)
						local pl = newPlate(P.folder)
						plateAt(pl, rec.b, px, -py, rec.b.w / nu, rec.b.h / nv, th, off)
						rec.plates[i], rec.pxs[i], rec.pys[i] = pl, px, py
					end
				end
			end
			if nu > 0 then paintRec(rec) end
		end
		for _, rec in ipairs(list) do
			if not isWant[rec] and #rec.plates > 0 then   -- 重ねるものが無くなった面
				for _, pl in ipairs(rec.plates) do pl:Destroy() end
				rec.plates, rec.cache, rec.pxs, rec.pys, rec.nu, rec.nv = {}, {}, {}, {}, 0, 0
			end
		end
		-- 角の輝き (大きい面から数を決めて)
		P.edgeLeft = EDGE_FACES
		table.sort(list, function(x, y) return x.b.w * x.b.h > y.b.w * y.b.h end)
		for _, rec in ipairs(list) do buildEdge(rec, off, th) end
		-- 毎フレーム動かす面を覚える (流れる色 / 光が走る帯)
		local anim = {}
		local sheen = (pm:GetAttribute("PS_Sheen") or 0) > 0
		for _, rec in ipairs(list) do
			if rec.nu > 0 then
				local flow = rec.G and rec.G.fr:GetAttribute("PS_tc") ~= nil
				local sh = sheen and rec.Sheen ~= nil
				if flow or sh then anim[#anim + 1] = { rec = rec, flow = flow, sheen = sh } end
			end
		end
		P.anim = anim
	end

	-- 動く面だけ、動く層を読み直して塗り直す (流れる色の並び / 光の帯の位置)
	function Mir.animate()
		for _, e in ipairs(P.anim) do
			local rec = e.rec
			if rec.sg.Parent then
				if e.flow then
					local L = readLayer(rec.sg, "G")
					if L then
						rec.G = L
						local Ls = {}
						for _, x in ipairs({ rec.G or false, rec.Gloss or false, rec.Sheen or false }) do
							if x then Ls[#Ls + 1] = x end
						end
						rec.layers = Ls
					end
				end
				if e.sheen and rec.Sheen and rec.Sheen.gr then
					local off = rec.Sheen.gr.Offset
					rec.Sheen.ox, rec.Sheen.oy = off.X, off.Y
				end
				paintRec(rec)
			end
		end
	end

	---------------------------------------------------------------------
	-- 光のにじみ / 縁取り / 粒 (3Dの外がわの飾りでまねる)
	---------------------------------------------------------------------
	local function scanLook(pm)
		local look = { fx = {} }
		local host = pm:FindFirstChild("SoundPart") or pm.PrimaryPart
		local l = host and host:FindFirstChild("SkinGlow")
		if l then look.glow = l end
		look.outline = pm:FindFirstChild("SkinOutline")
		for _, part in ipairs(pm:GetChildren()) do
			if part:IsA("BasePart") then
				for _, c in ipairs(part:GetChildren()) do
					local nm = c.Name
					if nm:sub(1, 7) == "SkinFx_" and c:IsA("ParticleEmitter") and c.Enabled and c.Rate > 0 then
						local kind = nm:sub(8)
						local e = look.fx[kind]
						if not e then
							e = { rate = 0 }
							look.fx[kind] = e
						end
						e.rate = e.rate + c.Rate
						e.em = c
					end
				end
			end
		end
		return look
	end

	local function setHalo(col, k, size)
		local rings = PVM.haloRings(k)
		local base = math.min(ST_W, ST_H) * size
		for i, f in ipairs(UI.halo) do
			f.BackgroundColor3 = col
			f.BackgroundTransparency = rings[i]
			local d = base * (1.05 - 0.2 * (i - 1))   -- 外 → 内
			f.Size = UDim2.fromOffset(d, d)
		end
	end

	-- 板のいまの様子 (光・縁取り・粒) を、窓の飾りに反映する。0.1秒に1回
	local function updateLook(dt)
		local pm = P.pm
		if P.lookAcc >= 0.1 or P.need then
			P.lookAcc = 0
			P.look = scanLook(pm)
		end
		local look = P.look
		-- 光のにじみ (明るさ・色は、動き (明滅・色の動き) のたびに読む)
		local g = look.glow
		local gk, gc, gsz = 0, WHITE, 0.8
		if g and g.Parent and g.Enabled ~= false then
			gk, gc, gsz = PVM.haloK(g.Brightness), g.Color, PVM.haloSize(g.Range)
		end
		local o = look.outline
		local ok_, oc = 0, WHITE
		if o and o.Parent and o.Enabled ~= false then
			oc = o.OutlineColor
			UI.ringStroke.Color = oc
			UI.ringStroke.Transparency = o.OutlineTransparency
			ok_ = math.clamp(1 - o.FillTransparency, 0, 1) / 0.7   -- オーラ
		else
			UI.ringStroke.Transparency = 1
		end
		if ok_ > 0 and gk < ok_ * 0.5 then gk, gc, gsz = ok_ * 0.5, oc, 0.9 end   -- オーラは、縁取りの色のにじみで表す
		if P.hk ~= gk or P.hc ~= gc or P.hs ~= gsz then
			P.hk, P.hc, P.hs = gk, gc, gsz
			setHalo(gc, gk, gsz)
		end
		-- 粒: 出す量・色を決める (出す・動かすのは毎フレーム)
		for kind, e in pairs(look.fx) do
			local s = P.fxk[kind]
			if not s then
				s = { acc = 0 }
				P.fxk[kind] = s
			end
			s.rate = math.clamp(e.rate * 0.3, 1.5, 22)
			s.on = true
			local col = FX_BASE[kind]
			local ok2, kc = pcall(function() return e.em.Color.Keypoints[1].Value end)
			if ok2 and kc then col = kc end
			s.col = col
		end
		for kind, s in pairs(P.fxk) do
			if not look.fx[kind] then s.on = false end
		end
	end

	local function updateSprites(dt)
		local list = P.sprites
		for kind, s in pairs(P.fxk) do
			if s.on then
				s.acc = s.acc + dt * s.rate
				while s.acc >= 1 do
					s.acc = s.acc - 1
					if #list < MAX_SPRITES then
						local sp = PVM.spawn(kind, math.random)
						if sp then
							sp.col = (kind == "confetti") and Color3.fromHSV(sp.hue, 0.75, 1) or s.col
							list[#list + 1] = sp
						end
					end
				end
			end
		end
		for i = #list, 1, -1 do
			if not PVM.step(list[i], dt) then table.remove(list, i) end
		end
		local pool = UI.sprites
		for i, sp in ipairs(list) do
			local f = pool[i]
			local size, tr = PVM.look(sp)
			f.Visible = true
			f.Position = UDim2.fromScale(sp.x, sp.y)
			f.Size = UDim2.fromOffset(size, sp.round and size or size * 1.5)
			f.BackgroundColor3 = sp.col or WHITE
			f.BackgroundTransparency = tr
			f.Rotation = sp.rot
		end
		for i = #list + 1, P.shown do pool[i].Visible = false end
		P.shown = #list
	end

	---------------------------------------------------------------------
	-- 毎フレーム
	---------------------------------------------------------------------
	local function frame(dt)
		local now = os.clock()
		-- 自動で左まわり。さわっている間と、さわったあと10秒は止める
		local spin = PVM.autoSpin(now, P.lastTouch, IDLE_SEC, P.dragging)
		if spin then
			local d = dt * SPIN_SPEED * P.dir
			P.yaw = (P.yaw + d) % (2 * math.pi)
			P.yawT = (P.yawT + d) % (2 * math.pi)
		end
		if P.spinning ~= spin then
			P.spinning = spin
			UI.status.Text = spin and "ゆっくり回っています (ドラッグで回せます)" or "観察中… 10秒さわらないと、また回ります"
		end
		-- ゆっくり目標へ (ドラッグ中は目標 = いまの値なので、そのまま追いかける)
		local k = 1 - math.exp(-dt * 10)
		P.zoom = P.zoom + (P.zoomT - P.zoom) * k
		P.pitch = P.pitch + (P.pitchT - P.pitch) * k
		local dyaw = ((P.yawT - P.yaw + math.pi) % (2 * math.pi)) - math.pi
		P.yaw = (P.yaw + dyaw * k) % (2 * math.pi)
		local c = P.center
		local x, y, z = PVM.orbit(c.X, c.Y, c.Z, P.yaw, P.pitch, P.dist / P.zoom)
		P.cam.CFrame = CFrame.lookAt(V3(x, y, z), c)

		-- 重ね貼りのまねっこ: 設定が変わったら、できあがりを待って作り直す / 動くものは30回/秒
		P.lookAcc = P.lookAcc + dt
		-- (変えている最中でも、最初の変更から 0.5秒たったら、いったん作り直す。止まったままにならないように)
		if P.need and (ENG.ovPending() == 0 and now - P.dirtyAt > 0.06 or now - P.firstDirty > 0.5) and now - P.lastSync > 0.12 then
			P.need = false
			P.lastSync = now
			Mir.sync()
		end
		P.animAcc = P.animAcc + dt
		if P.animAcc >= 1 / ANIM_HZ then
			P.animAcc = 0
			if #P.anim > 0 then Mir.animate() end
		end
		updateLook(dt)
		updateSprites(dt)
	end

	---------------------------------------------------------------------
	-- 開く / 閉じる
	---------------------------------------------------------------------
	local closePreview
	local function setDirMarks()
		local on, off = Lib.ACCENT, WHITE
		Lib.tween(UI.bLeft, { BackgroundColor3 = P.dir == -1 and on or off, BackgroundTransparency = P.dir == -1 and 0.2 or 0.84 }, 0.2)
		Lib.tween(UI.bRight, { BackgroundColor3 = P.dir == 1 and on or off, BackgroundTransparency = P.dir == 1 and 0.2 or 0.84 }, 0.2)
	end

	local function openPreview()
		if P then return end
		if UIs.helpOpen then return end
		local tpl = ENG.template()
		if not tpl then
			local b = selected and seenMap[selected] or myPallets()[1]
			if b then tpl = ENG.capture(b) end
		end
		if not tpl then
			Lib.notif(gui, "先に板を出してね (見本にする板がありません)", 2)
			return
		end
		if not UI then UI = buildWindow() end
		if not wired then
			wired = true
			wireUI()
			UI.save.MouseButton1Click:Connect(function() savePreset() end)
		end
		local okc, pm = pcall(function() return tpl:Clone() end)
		if not okc or not pm then
			Lib.notif(gui, "プレビューを開けませんでした", 2)
			return
		end
		pm.Name = "PalletLightBrown"
		pm:SetAttribute("PS_Preview", true)   -- 見本にしない・動きは「いちばん近い」あつかいにする目印
		local state = { pm = pm, conns = {}, recs = {}, anim = {}, sprites = {}, fxk = {}, shown = 0, look = { fx = {} },
			lookAcc = 1, animAcc = 0, lastSync = 0, dirtyAt = os.clock(), firstDirty = os.clock(), need = true, edgeLeft = 0, lastTouch = -1e9, dragging = false,
			dir = -1, yaw = HOME_YAW, yawT = HOME_YAW, pitch = HOME_PITCH, pitchT = HOME_PITCH, zoom = 1, zoomT = 1 }
		local ok = pcall(function()
			pm:PivotTo(CFrame.new(0, 0, 0))
			local vp = UI.vp
			pm.Parent = vp
			local cf, size = pm:GetBoundingBox()
			state.center = cf.Position
			local radius = math.max(size.Magnitude * 0.5, 0.5)
			state.dist = PVM.fitDist(radius, FOV, 0.95)
			state.eps = math.clamp(radius * 0.0035, 0.008, 0.03)
			local cam = Instance.new("Camera")
			cam.FieldOfView = FOV
			cam.Parent = vp
			vp.CurrentCamera = cam
			state.cam = cam
			state.folder = Instance.new("Folder")
			state.folder.Name = "PvMirror"
			state.folder.Parent = vp
			-- 床の丸い板 (回しても向きが分かるように)
			local floor = Instance.new("Part")
			floor.Anchored, floor.CanCollide, floor.CanQuery, floor.CastShadow = true, false, false, false
			floor.Shape = Enum.PartType.Cylinder
			floor.Material = Enum.Material.SmoothPlastic
			floor.Color = Color3.fromRGB(34, 38, 70)
			floor.Transparency = 0.25
			floor.Size = V3(0.06, radius * 3.2, radius * 3.2)
			floor.CFrame = CFrame.new(state.center.X, cf.Position.Y - size.Y * 0.5 - 0.05, state.center.Z) * CFrame.Angles(0, 0, math.pi / 2)
			floor.Parent = state.folder
		end)
		if not ok then
			pcall(function() pm:Destroy() end)
			if state.folder then pcall(function() state.folder:Destroy() end) end
			if state.cam then pcall(function() state.cam:Destroy() end) end
			Lib.notif(gui, "プレビューを開けませんでした", 2)
			return
		end
		P = state
		pv.model = pm
		for _, fn in ipairs(resetters) do pcall(fn) end   -- 画面のスライダーやボタンは、プレビューの板 (何も変えていない板) に合わせて初期へ
		if UIs.homePreviewLabel then UIs.homePreviewLabel(true) end

		-- 窓を出す
		UI.bgGrad.Color = bgGrad.Color
		local s = place()
		UI.win.Visible = true
		UI.scale.Scale = 0.9 * s
		UI.win.GroupTransparency = 1
		Lib.tween(UI.scale, { Scale = s }, 0.6)
		Lib.tween(UI.win, { GroupTransparency = uiCfg.alpha }, 0.4)
		P.scaleNow = s
		setDirMarks()
		UI.status.Text = ""
		UI.save.Text = SAVE_TEXT
		P.spinning = nil
		for i = 1, #UI.sprites do UI.sprites[i].Visible = false end
		setHalo(WHITE, 0, 0.8)
		UI.ringStroke.Transparency = 1
		P.conns[#P.conns + 1] = RunService.RenderStepped:Connect(function(dt)
			if not P or P.hidden or not P.pm.Parent then return end
			local ok2, err = pcall(frame, math.min(dt, 0.1))
			if not ok2 then
				P.errs = (P.errs or 0) + 1
				if P.errs == 1 then pcall(warn, "PalletStudio preview: " .. tostring(err)) end
				if P.errs >= 5 then closePreview() end
			end
		end)
		P.conns[#P.conns + 1] = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if P and UI.win.Visible then Lib.tween(UI.scale, { Scale = place() }, 0.3) end
		end)
		selVisuals()
	end

	closePreview = function()
		if not P then return end
		local Pc = P
		P = nil
		pv.model = nil
		for _, c in ipairs(Pc.conns) do pcall(function() c:Disconnect() end) end
		if Pc.dragConns then
			for _, c in ipairs(Pc.dragConns) do pcall(function() c:Disconnect() end) end
		end
		pcall(function() Pc.pm:Destroy() end)
		pcall(function() Pc.folder:Destroy() end)
		pcall(function() Pc.cam:Destroy() end)
		pcall(function() UI.vp.CurrentCamera = nil end)
		for i = 1, #UI.sprites do UI.sprites[i].Visible = false end
		Lib.tween(UI.scale, { Scale = 0.9 * (Pc.scaleNow or 1) }, 0.4)
		local t = Lib.tween(UI.win, { GroupTransparency = 1 }, 0.3)
		t.Completed:Connect(function()
			if not P then UI.win.Visible = false end
		end)
		for _, fn in ipairs(resetters) do pcall(fn) end   -- 本体のスライダーやボタンを、初期の位置へ戻す (ふつうに板を設定できるように)
		if UIs.homePreviewLabel then UIs.homePreviewLabel(false) end
		selVisuals()
	end

	function UIs.togglePreview()
		if P then
			closePreview()
		else
			if UIs.helpOpen then
				Lib.notif(gui, "ヘルプを閉じてから押してね", 1.8)
				return
			end
			openPreview()
		end
	end
	pv.changed = function()
		if P then
			local now = os.clock()
			if not P.need then P.firstDirty = now end
			P.need = true
			P.dirtyAt = now
		end
	end
	-- ヘルプが開いている間だけ、プレビューの窓を隠す (ヘルプを閉じたらもどす)
	pv.hideForHelp = function(on)
		if not P then return end
		P.hidden = on
		UI.win.Visible = not on
	end

	---------------------------------------------------------------------
	-- ボタン・ドラッグ
	---------------------------------------------------------------------
	wireUI = function()
		UI.close.MouseButton1Click:Connect(function() closePreview() end)
		UI.bIn.MouseButton1Click:Connect(function()
			if not P then return end
			P.zoomT = math.clamp(P.zoomT * 1.18, 0.5, 2.6)
			touch()
		end)
		UI.bOut.MouseButton1Click:Connect(function()
			if not P then return end
			P.zoomT = math.clamp(P.zoomT / 1.18, 0.5, 2.6)
			touch()
		end)
		UI.bLeft.MouseButton1Click:Connect(function()
			if not P then return end
			P.dir = -1
			setDirMarks()
			P.lastTouch = -1e9   -- 向きを選んだら、すぐ回りはじめる
		end)
		UI.bRight.MouseButton1Click:Connect(function()
			if not P then return end
			P.dir = 1
			setDirMarks()
			P.lastTouch = -1e9
		end)
		UI.bHome.MouseButton1Click:Connect(function()
			if not P then return end
			P.yawT, P.pitchT, P.zoomT = HOME_YAW, HOME_PITCH, 1
			touch()
		end)
		-- ドラッグで360度まわす (横 = ぐるっと / 縦 = 上から・下から)
		UI.grab.InputBegan:Connect(function(i)
			if not P or P.dragging then return end
			local t = i.UserInputType
			if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
			local d = { i = i, x = i.Position.X, y = i.Position.Y }
			P.dragging = true
			P.yawT, P.pitchT = P.yaw, P.pitch
			local Pd = P
			local function stop()
				if Pd.dragConns then
					for _, c in ipairs(Pd.dragConns) do pcall(function() c:Disconnect() end) end
					Pd.dragConns = nil
				end
				Pd.dragging = false
				Pd.lastTouch = os.clock()
			end
			Pd.dragConns = {
				UIS.InputChanged:Connect(function(m)
					local mt = m.UserInputType
					if mt == Enum.UserInputType.MouseMovement or (mt == Enum.UserInputType.Touch and m == d.i) then
						local dx, dy = m.Position.X - d.x, m.Position.Y - d.y
						d.x, d.y = m.Position.X, m.Position.Y
						Pd.yaw = (Pd.yaw - dx * 0.011) % (2 * math.pi)
						Pd.yawT = Pd.yaw
						Pd.pitch = PVM.clampPitch(Pd.pitch + dy * 0.009)
						Pd.pitchT = Pd.pitch
					end
				end),
				UIS.InputEnded:Connect(function(e)
					if e == d.i or (d.i.UserInputType == Enum.UserInputType.MouseButton1 and e.UserInputType == Enum.UserInputType.MouseButton1) then stop() end
				end),
			}
		end)
		UI.grab.MouseWheelForward:Connect(function()
			if not P then return end
			P.zoomT = math.clamp(P.zoomT * 1.1, 0.5, 2.6)
			touch()
		end)
		UI.grab.MouseWheelBackward:Connect(function()
			if not P then return end
			P.zoomT = math.clamp(P.zoomT / 1.1, 0.5, 2.6)
			touch()
		end)
		Lib.drag(UI.top, UI.win)
	end

	---------------------------------------------------------------------
	-- プリセット (💾 メイン保存 → 左のページ一覧の「その他」の下に「プリセットN」)
	---------------------------------------------------------------------
	local function copyOp(op)
		local v = op[2]
		if type(v) == "table" then
			local c = {}
			for k, x in pairs(v) do c[k] = x end
			v = c
		end
		return { op[1], v }
	end

	local function applyPreset(pr)
		local m = targetModel()
		if not m or not m.Parent then
			Lib.notif(gui, "板を選んでください", 1.8)
			return
		end
		for _, fn in ipairs(resetters) do pcall(fn) end   -- 画面の表示も、いったん初期へ (下で、板に送った内容に合わせ直す)
		local ops = { { "Reset" } }
		for _, op in ipairs(pr.ops) do ops[#ops + 1] = copyOp(op) end
		if sendBatch(ops) then
			if UIs.afterLook then pcall(UIs.afterLook, true) end
			Lib.notif(gui, (UIs.pv.model and "プレビューの板を「" or "「") .. "プリセット" .. pr.n .. "」にしました ⭐", 1.8)
		end
	end

	local function removePreset(pr)
		for i, x in ipairs(presets) do
			if x == pr then table.remove(presets, i) break end
		end
		if pr.btn then
			local b = pr.btn
			pr.btn = nil
			local sc = b:FindFirstChildOfClass("UIScale")
			if sc then Lib.tween(sc, { Scale = 0.01 }, 0.25) end
			Lib.tween(b, { BackgroundTransparency = 1 }, 0.25)
			task.delay(0.28, function() b:Destroy() end)
		end
		UIs.touch("presets")
	end

	local function addPresetButton(pr, quiet)
		local H = isMobile and 48 or 34
		local b = mk("TextButton", { Name = "Preset" .. pr.n, AutoButtonColor = false, Text = "", LayoutOrder = 100 + pr.n, Size = UDim2.new(1, 0, 0, H) }, side)
		Lib.glass(b, 0.8, 13)
		mk("UIGradient", { Rotation = 30, Color = ColorSequence.new(Lib.ACCENT, Lib.ACCENT2), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.85) }) }, b)
		local lab = text(b, isMobile and ("⭐" .. pr.n) or ("⭐ プリセット" .. pr.n), isMobile and 16 or 15, UDim2.fromOffset(isMobile and 0 or 12, 0), UDim2.new(1, isMobile and 0 or -38, 1, 0), isMobile and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left)
		lab.TextTruncate = Enum.TextTruncate.AtEnd
		Lib.juice(b)
		-- ✕ (1回目で赤くなり、2.5秒以内にもう1回押すと消える)
		local x = mk("TextButton", { Name = "Del", AutoButtonColor = false, Text = "✕", TextSize = isMobile and 11 or 13, FontFace = FONT, TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(244, 63, 94), BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, isMobile and 0 or 0.5), Position = isMobile and UDim2.new(1, -1, 0, 1) or UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(isMobile and 18 or 24, isMobile and 18 or 24), ZIndex = 3 }, b)
		mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, x)
		local armed = 0
		x.TextTransparency = 0.35
		x.MouseButton1Click:Connect(function()
			if armed > 0 and os.clock() - armed < 2.5 then
				removePreset(pr)
				return
			end
			armed = os.clock()
			Lib.tween(x, { BackgroundTransparency = 0.1, TextTransparency = 0 }, 0.15)
			Lib.notif(gui, "もう一度 ✕ を押すと、プリセット" .. pr.n .. " を消します", 1.8)
			task.delay(2.5, function()
				if x.Parent and os.clock() - armed >= 2.45 then
					armed = 0
					Lib.tween(x, { BackgroundTransparency = 1, TextTransparency = 0.35 }, 0.2)
				end
			end)
		end)
		b.MouseButton1Click:Connect(function() applyPreset(pr) end)
		pr.btn = b
		if quiet then return end   -- (GitHubからの復元: 静かに並べるだけ)
		-- ぽんっと出る
		local sc = b:FindFirstChildOfClass("UIScale")
		if sc then
			sc.Scale = 0.5
			TweenService:Create(sc, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
		task.delay(0.1, function()   -- 新しいボタンが見えるところまで、リストを下げる
			pcall(function() side.CanvasPosition = Vector2.new(0, 100000) end)
		end)
	end

	savePreset = function()
		if not P then return end
		local r = recipe[P.pm]
		if not r or #r == 0 then
			Lib.notif(gui, "先に色や素材を変えてから押してね", 1.8)
			return
		end
		if #presets >= 30 then
			Lib.notif(gui, "プリセットは30個までです。いらないものを ✕ で消してね", 2.2)
			return
		end
		local n = 1
		local used = {}
		for _, x in ipairs(presets) do used[x.n] = true end
		while used[n] do n = n + 1 end
		local ops = {}
		for i, op in ipairs(r) do ops[i] = copyOp(op) end
		local ang = ENG.flowAng(P.pm)   -- 流れる色の向き (ランダムで決まった向き) も一緒に保存して、同じ向きで流す
		if ang then
			for _, op in ipairs(ops) do
				if op[1] == "Gradient" and type(op[2]) == "table" and (op[2].flow or 0) > 0 then op[2].ang = ang end
			end
		end
		local pr = { n = n, ops = ops }
		presets[#presets + 1] = pr
		table.sort(presets, function(a, b) return a.n < b.n end)
		addPresetButton(pr)
		UIs.touch("presets")
		Lib.notif(gui, "プリセット" .. n .. " に保存しました ⭐ (左の「その他」の下に出ます)", 2.4)
		-- ボタンの文字も、ちょっとだけ「保存したよ」に変わる
		UI.save.Text = "✔ プリセット" .. n .. " に保存しました"
		P.saveFlash = (P.saveFlash or 0) + 1
		local id = P.saveFlash
		task.delay(1.6, function()
			if P and P.saveFlash == id and UI and UI.save then UI.save.Text = SAVE_TEXT end
		end)
	end

	-- GitHub保存用: プリセット一覧の取り出し / 入れ替え (入れ替えは、いまのボタンを全部消して、渡された一覧で静かに作り直す)
	pv.getPresets = function()
		local list = {}
		for i, pr in ipairs(presets) do
			local ops = {}
			for k, op in ipairs(pr.ops) do ops[k] = copyOp(op) end
			list[i] = { n = pr.n, ops = ops }
		end
		return list
	end
	pv.setPresets = function(list)
		for i = #presets, 1, -1 do
			local pr = presets[i]
			if pr.btn then
				pcall(function() pr.btn:Destroy() end)
				pr.btn = nil
			end
			presets[i] = nil
		end
		local used = {}
		for _, src in ipairs(list) do
			local n = math.floor(tonumber(src.n) or 0)
			if #presets < 30 and n >= 1 and n <= 999 and not used[n] and type(src.ops) == "table" and #src.ops > 0 then
				used[n] = true
				local ops = {}
				for k, op in ipairs(src.ops) do ops[k] = copyOp(op) end
				presets[#presets + 1] = { n = n, ops = ops }
			end
		end
		table.sort(presets, function(a, b) return a.n < b.n end)
		for _, pr in ipairs(presets) do addPresetButton(pr, true) end
	end

	-- テストや点検のための窓口
	UIs.pvDbg = { presets = presets, save = function() savePreset() end, apply = applyPreset, state = function() return P end, ui = function() return UI end, math = PVM, mir = Mir }
end)()
---------------------------------------------------------------------
-- GitHub保存 (画面側)
--  設定だけ (永久保存の板の見た目・プリセット・UI設定・軽量化の選択) を、サーバー側の「GitHub係」に預けて、1人1ファイルで GitHub に残す。
--  ・起動時に1回、保存してあった内容を読み込んで、そのまま反映する。そのあとは、変えるたびに (止まってから数秒後に) 自動で保存する。
--  ・GITHUB.repo が空の間は、何もしない (通信もしない・待ち時間もない)。
--  ・画面 (LocalScript) は Roblox の決まりで通信できないので、通信はサーバー側が受け持つ。トークンは画面側へは来ない。
--  ・読み込みに成功するまでは、保存しない (読めなかったのに、初期の設定で前の保存を上書きしないため)。
--  ・「保存する物が変わった」は、UIs.touch(名前) で知らせてもらう (見張りの繰り返しは無いので、何もしていない時の負担は 0)。
---------------------------------------------------------------------
-- (do ... end の中に入れてある: メインのローカル変数が増えないように。前の部分が「)()」で終わっているので、「(」で始めると呼び出しとつながってしまう)
do
	local C = { auto = true, ready = false, loading = false, restoring = false, changed = false }
	UIs.cloud = C

	local repo = (type(GITHUB) == "table") and tostring(GITHUB.repo or "") or ""
	local ENABLED = repo ~= ""
	local DEBOUNCE, MAXWAIT = 2, 10   -- 変えるのが止まって2秒たったら送る (変え続けていても、10秒たったら送る)。サーバー側は、さらに数秒まとめてから GitHub へ書く
	local SECTIONS = { "perm", "presets", "ui", "opt" }

	local ERR = {
		no_repo = "未設定です (ファイルの先頭の GITHUB の repo を書いてね)",
		no_token = "トークンが見つかりません (ServerStorage に PalletStudioGitHubToken を作ってね)",
		http_off = "HTTPリクエストが許可されていません (Game Settings → Security → Allow HTTP Requests)",
		auth = "トークンが使えません (期限切れか、権限が足りません)",
		repo = "リポジトリが見つかりません (名前と、トークンの権限を確かめてね)",
		rate = "GitHubの回数制限にかかりました",
		net = "GitHubにつながりません",
		conflict = "GitHub上のファイルと食い違いました",
		parse = "保存ファイルが読めません (GitHub上で壊れているかも)。上書きはしません",
		big = "保存する内容が大きすぎます",
		bad = "保存する内容の形がおかしいです",
		busy = "混み合っています",
		notloaded = "まだ読み込めていないので、保存は止めています",
	}
	local function errText(code) return ERR[code] or ("エラー (" .. tostring(code) .. ")") end
	local SETUP_ERR = { no_repo = true, no_token = true, http_off = true, auth = true, repo = true, parse = true }   -- 設定のやり直しが要るエラー (自動では直らない)

	---------------------------------------------------------------
	-- 状態の表示
	---------------------------------------------------------------
	local notified = {}
	local function render()
		local t = C.text or ""
		if not C.auto then t = t .. "\n(自動で保存する は OFF です。いまの変更は GitHub に保存されません)" end
		if UIs.cloudUI then pcall(UIs.cloudUI.status, t, C.kind or "off") end
	end
	local function setStatus(kind, text)
		C.kind, C.text = kind, text
		render()
	end
	-- 設定のやり直しが要るエラーは、最初の1回だけ画面の上にも出す (状態の欄には、いつも出る)
	local function tellOnce(code)
		if SETUP_ERR[code] and not notified[code] then
			notified[code] = true
			Lib.notif(gui, "GitHub保存: " .. errText(code), 3.6)
		end
	end

	---------------------------------------------------------------
	-- 値の変換 (Color3 などは、JSON にできる形にして保存する。読み込む時に、もとの形に戻す)
	---------------------------------------------------------------
	local function enc(v, depth)
		local t = typeof(v)
		if t == "number" then
			if v ~= v or v == math.huge or v == -math.huge then return nil, false end
			return v, true
		elseif t == "string" or t == "boolean" then
			return v, true
		elseif t == "Color3" then
			return { ["$"] = "c", r = v.R, g = v.G, b = v.B }, true
		elseif t == "Vector3" then
			return { ["$"] = "v3", x = v.X, y = v.Y, z = v.Z }, true
		elseif t == "table" then
			if depth > 6 then return nil, false end
			local out = {}
			for k, x in pairs(v) do
				local kt = type(k)
				if kt ~= "number" and kt ~= "string" then return nil, false end
				local e, ok = enc(x, depth + 1)
				if not ok then return nil, false end
				out[k] = e
			end
			return out, true
		end
		return nil, false
	end
	local function dec(v, depth)
		local t = type(v)
		if t == "number" then
			if v ~= v then return nil end
			return v
		elseif t == "string" or t == "boolean" then
			return v
		elseif t ~= "table" or depth > 6 then
			return nil
		end
		local tag = v["$"]
		if tag == "c" then
			if type(v.r) == "number" and type(v.g) == "number" and type(v.b) == "number" then
				return Color3.new(math.clamp(v.r, 0, 1), math.clamp(v.g, 0, 1), math.clamp(v.b, 0, 1))
			end
			return nil
		elseif tag == "v3" then
			if type(v.x) == "number" and type(v.y) == "number" and type(v.z) == "number" then
				return Vector3.new(v.x, v.y, v.z)
			end
			return nil
		end
		local out = {}
		for k, x in pairs(v) do
			local d = dec(x, depth + 1)
			if d ~= nil then out[k] = d end
		end
		return out
	end
	-- 操作のリスト { {種類, 値}, ... } ⇔ 保存用 [ [種類, 値], ... ]
	local function encodeOps(ops)
		local out = {}
		for _, op in ipairs(ops) do
			if type(op) == "table" and type(op[1]) == "string" then
				if op[2] == nil then
					out[#out + 1] = { op[1] }
				else
					local e, ok = enc(op[2], 1)
					if ok then out[#out + 1] = { op[1], e } end
				end
			end
		end
		return out
	end
	local function decodeOps(list)
		local out = {}
		if type(list) ~= "table" then return out end
		for _, op in ipairs(list) do
			if #out >= 200 then break end
			if type(op) == "table" and type(op[1]) == "string" and #op[1] <= 40 then
				if op[2] == nil then
					out[#out + 1] = { op[1] }
				else
					local v = dec(op[2], 1)
					if v ~= nil then out[#out + 1] = { op[1], v } end
				end
			end
		end
		return out
	end

	---------------------------------------------------------------
	-- 保存する内容を集める (変わった所だけ作り直す。ほかは前のを使う)
	---------------------------------------------------------------
	local dirtySec, cache = {}, {}
	local function invalidate()
		for _, k in ipairs(SECTIONS) do dirtySec[k] = true end
	end
	invalidate()
	local function section(name)
		if not dirtySec[name] and cache[name] then return cache[name].v end
		local v
		if name == "perm" then
			local ops = UIs.permIO and UIs.permIO.get()
			if ops and #ops > 0 then v = { ops = encodeOps(ops) } end
		elseif name == "presets" then
			v = {}
			for i, pr in ipairs(UIs.pv.getPresets and UIs.pv.getPresets() or {}) do
				v[i] = { n = pr.n, ops = encodeOps(pr.ops) }
			end
		elseif name == "ui" then
			v = UIs.uiIO and UIs.uiIO.get()
		elseif name == "opt" then
			v = UIs.optIO and UIs.optIO.get()
		end
		cache[name] = { v = v }
		dirtySec[name] = false
		return v
	end
	local function snapshot()
		local s = {}
		for _, name in ipairs(SECTIONS) do
			local v = section(name)
			if v ~= nil then s[name] = v end
		end
		return s
	end

	---------------------------------------------------------------
	-- 保存してあった内容を反映する。失敗した数を返す (1つでも失敗したら、上書きを防ぐために保存を止める)
	---------------------------------------------------------------
	local function restore(d)
		local fails = 0
		local function try(name, fn)
			local ok, err = pcall(fn)
			if not ok then
				fails = fails + 1
				warn("[PalletStudio] GitHub保存: " .. name .. " の反映でエラー: " .. tostring(err))
			end
		end
		try("永久保存", function()
			local ops = (type(d.perm) == "table") and decodeOps(d.perm.ops) or {}
			if #ops > 0 then
				UIs.permIO.hold(ops, true)   -- これから出る板 (サーバーが付ける) と、いま出ている板に付ける
			elseif UIs.permIO.get() then
				UIs.permIO.release()
			end
		end)
		try("プリセット", function()
			local list = {}
			if type(d.presets) == "table" then
				for _, pr in ipairs(d.presets) do
					if #list >= 30 then break end
					if type(pr) == "table" and type(pr.n) == "number" then
						local ops = decodeOps(pr.ops)
						if #ops > 0 then list[#list + 1] = { n = pr.n, ops = ops } end
					end
				end
			end
			UIs.pv.setPresets(list)
		end)
		try("UI設定", function()
			if type(d.ui) == "table" then UIs.uiIO.set(d.ui) end
		end)
		try("軽量化", function()
			UIs.optIO.set(type(d.opt) == "table" and d.opt or {})
		end)
		return fails
	end

	---------------------------------------------------------------
	-- サーバー側の GitHub係 との通信
	---------------------------------------------------------------
	local function invoke(action, payload)
		local rf = C.rf
		if not rf then return { s = "err", code = "net" } end
		local ok, res = pcall(function() return rf:InvokeServer(action, payload) end)
		if not ok or type(res) ~= "table" then return { s = "err", code = "net" } end
		return res
	end

	local timerOn, firstAt, lastAt, sending = false, 0, 0, false
	local sendSave
	local function schedule()
		local now = os.clock()
		lastAt = now
		if timerOn then return end
		timerOn, firstAt = true, now
		task.spawn(function()
			while true do
				local t = os.clock()
				local w = math.min(lastAt + DEBOUNCE - t, firstAt + MAXWAIT - t)
				if w <= 0 then break end
				task.wait(w)
			end
			timerOn = false
			if C.ready and C.auto and C.changed and not sending then sendSave(false) end
		end)
	end

	-- force = true: すぐ GitHub に書いて、終わるまで待つ (「いま保存」)
	sendSave = function(force)
		if not C.ready or sending then return end
		sending = true
		C.changed = false
		local snap = snapshot()
		if force then setStatus("save", "GitHubへ保存中…") end
		task.spawn(function()
			local res = invoke(force and "flush" or "save", snap)
			sending = false
			if res.s == "queued" then
				setStatus("save", "保存待ち… (変更が止まったら、GitHubへ書きます)")
			elseif res.s == "same" then
				setStatus("ok", "保存済みです (内容は前と同じ)")
			elseif res.s == "ok" then
				C.savedAt = os.date("%H:%M:%S")
				setStatus("ok", "GitHubに保存しました ✔ " .. C.savedAt)
				if force then Lib.notif(gui, "GitHubに保存しました ✔", 1.8) end
			else
				local code = res.code
				if code == "busy" then
					C.changed = true   -- 少し待って、もう一度
				elseif code == "notloaded" then
					C.ready = false
					C.changed = true
					if not C.loading then C.load() end
				else
					setStatus("err", errText(code))
					tellOnce(code)
					if force then Lib.notif(gui, "GitHub保存: " .. errText(code), 3) end
				end
			end
			if C.changed and C.auto and C.ready then schedule() end
		end)
	end

	-- 保存する物が変わった (名前 = "perm" / "presets" / "ui" / "opt")。反映中の変更は、保存してあった内容そのものなので数えない
	function C.touch(sec)
		if C.restoring then return end
		if sec then dirtySec[sec] = true else invalidate() end
		C.changed = true
		if C.ready and C.auto then schedule() end
	end

	function C.setAuto(v)
		C.auto = v and true or false
		render()
		if C.auto and C.ready and C.changed then schedule() end
	end

	function C.saveNow()
		if not ENABLED then
			Lib.notif(gui, "GitHub保存は未設定です (ファイルの先頭の GITHUB の repo を書いてね)", 2.6)
			return
		end
		if not C.ready then
			Lib.notif(gui, "まだ GitHub の保存を読み込めていません。読み込めたら、保存できます", 2.6)
			if C.rf and not C.loading then C.load() end
			return
		end
		if sending then
			C.changed = true   -- 送っている最中: 終わったら、続けて送る
			return
		end
		sendSave(true)
	end

	-- 読み込み → 反映。ネットの不調・回数制限・混み合いの時は、間をあけて数回やり直す
	function C.load(manual)
		if C.loading or not C.rf then return end
		C.loading = true
		task.spawn(function()
			local tries = 0
			while true do
				setStatus("load", manual and "GitHubから読み直し中…" or "GitHubから設定を読み込み中…")
				local res = invoke("load")
				if res.s == "ok" and type(res.data) == "table" then
					C.restoring = true
					local fails = restore(res.data)
					C.restoring = false
					invalidate()
					C.changed = false
					if fails == 0 then
						C.ready = true
						local when = (type(res.saved) == "string" and res.saved ~= "") and (" (保存した日時: " .. res.saved .. ")") or ""
						setStatus("ok", "GitHubの保存を反映しました ✔" .. when)
						Lib.notif(gui, "GitHubに保存してあった設定を反映しました ☁", 2.2)
					else
						C.ready = false   -- 一部だけ反映された状態で保存すると、GitHubの内容を壊すので、保存は止める
						setStatus("err", "保存してあった設定の一部を反映できませんでした。GitHubの内容は上書きしません")
					end
					break
				elseif res.s == "none" then
					C.ready = true
					setStatus("ok", "保存データはまだありません。設定を変えると、自動で保存を始めます")
					if C.changed and C.auto then schedule() end   -- 読み込み中に変えた分は、そのまま最初の保存にする
					break
				else
					local code = res.code
					tries = tries + 1
					if (code == "net" or code == "rate" or code == "busy" or code == "conflict") and tries <= 4 then
						local w = (code == "rate" and tonumber(res.wait)) or (10 * 2 ^ (tries - 1))
						w = math.clamp(w, 3, 120)
						setStatus("err", errText(code) .. " (約" .. math.ceil(w) .. "秒後に、もう一度読み込みます)")
						task.wait(w)
					else
						setStatus("err", errText(code))
						tellOnce(code)
						break
					end
				end
			end
			C.loading = false
		end)
	end

	-- 「読み直して反映」ボタン: いまの設定を、GitHubの保存で置きかえる
	function C.reload()
		if not ENABLED or not C.rf then
			Lib.notif(gui, "GitHub保存は、まだ使える状態ではありません", 2.4)
			return
		end
		if C.loading then return end
		C.ready = false   -- 読み直しが終わるまでは、保存しない
		C.load(true)
	end

	-- サーバー側からの知らせ (保存中 / 保存した / エラー)。変えた分を、あとからまとめて書くので、画面で待つ必要は無い
	local function onEvent(kind, state, code, wait)
		if kind ~= "st" then return end
		if state == "saving" then
			setStatus("save", "GitHubへ保存中…")
		elseif state == "saved" then
			C.savedAt = os.date("%H:%M:%S")
			setStatus("ok", "GitHubに保存しました ✔ " .. C.savedAt)
		elseif state == "error" then
			local w = tonumber(wait)
			setStatus("err", errText(code) .. (w and (" (約" .. math.ceil(w) .. "秒後に、やり直します)") or " (あとで自動でやり直します)"))
			tellOnce(code)
		end
	end

	-- テストや点検のための窓口
	C.dbg = { snapshot = snapshot, restore = restore, enc = enc, dec = dec, encodeOps = encodeOps, decodeOps = decodeOps, invalidate = invalidate }

	---------------------------------------------------------------
	-- 起動
	---------------------------------------------------------------
	if not ENABLED then
		C.kind, C.text = "off", "未設定です。ファイルの先頭の GITHUB の repo に「ユーザー名/リポジトリ名」を書くと、使えるようになります (書くまでは、何もしません)"
		render()
	else
		UIs.touch = function(sec) C.touch(sec) end
		Opt.onChange = function() C.touch("opt") end
		setStatus("wait", "サーバー側を待っています…")
		task.spawn(function()
			local rf = RS:WaitForChild("PalletStudioCloud_v1", 90)
			if not rf then
				setStatus("err", "サーバー側が見つかりません (Studio の Play を止めて、もう一度始めてね。それでも出る時は、CodeLoader が動いているか確かめてね)")
				return
			end
			C.rf = rf
			local ev = RS:WaitForChild("PalletStudioCloudEvt_v1", 5)
			if ev then ev.OnClientEvent:Connect(onEvent) end
			C.load()
		end)
	end
end
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
