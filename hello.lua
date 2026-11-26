-- PalletStudio (LocalScript): StarterPlayer > StarterPlayerScripts に入れる (これ1個だけで動く)
-- 検出: tntnmziSpawnedInToys の中の PalletLightBrown (Model) を直接見つけて「板1, 板2…」と出す。
-- 起動時に必ず、サーバー用コードを CodeLoader (ServerScriptService) へ送る。サーバー側が無ければ、この画面だけに直接反映する。
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

task.spawn(function()
	while true do
		if next(rainbowSet) == nil then
			task.wait(0.5)
		else
			task.wait(0.12)
			for m in pairs(rainbowSet) do
				if m.Parent then
					local s = st(m)
					local col = Color3.fromHSV((os.clock() * (s.rbSpeed or 0.15)) % 1, s.rbSat or 0.85, 1)
					local parts = partsOf(m)
					for _, p in ipairs(parts) do p.Color = col end
					local h = glowHost(m)
					local l = h and h:FindFirstChild("SkinGlow")
					if l then l.Color = col end
				else
					rainbowSet[m] = nil
				end
			end
		end
	end
end)

local remote = ReplicatedStorage:FindFirstChild("PalletStudioApply_v2")
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = "PalletStudioApply_v2"
	remote.Parent = ReplicatedStorage
end
local last = {}
remote.OnServerInvoke = function(player, kind, target, value)
	if typeof(kind) ~= "string" or typeof(target) ~= "Instance" then return nil end
	if not target:IsA("Model") or target.Name ~= "PalletLightBrown" or not target:IsDescendantOf(folder) then return nil end
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
		local sc = btn:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, btn)
		btn.MouseEnter:Connect(function() M.tween(sc, { Scale = 1.04 }, 0.25) end)
		btn.MouseLeave:Connect(function() M.tween(sc, { Scale = 1 }, 0.25) end)
		btn.MouseButton1Down:Connect(function() M.tween(sc, { Scale = 0.96 }, 0.1) end)
		btn.MouseButton1Up:Connect(function() M.tween(sc, { Scale = 1.04 }, 0.1) end)
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
			M.juice(f)
			t.MouseButton1Click:Connect(function()
				if cb then pcall(cb) end
			end)
		end

		function b:toggle(n, cb, state)
			local s = state or false
			local f = glassRow(38)
			rowLabel(f, n, 0.7)
			local bg = mk("TextButton", {
				AutoButtonColor = false, Text = "", BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(52, 26), BackgroundColor3 = Color3.fromRGB(244, 63, 94),
			}, f)
			M.corner(bg, 13)
			local h = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3) }, bg)
			M.corner(h, 10)
			local function render()
				M.tween(bg, { BackgroundColor3 = s and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(244, 63, 94) }, 0.25)
				M.tween(h, { Position = s and UDim2.fromOffset(29, 3) or UDim2.fromOffset(3, 3) }, 0.25)
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
			local f = glassRow(44)
			rowLabel(f, n, 0.28)
			local track = mk("TextButton", {
				AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = WHITE, BackgroundTransparency = 0.75,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.3, 0, 0.5, 0), Size = UDim2.new(0.5, 0, 0, 10),
			}, f)
			M.corner(track, 5)
			local fill = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1) }, track)
			M.corner(fill, 5)
			if rainbowTrack then
				track.BackgroundTransparency = 0
				fill.BackgroundTransparency = 1
				mk("UIGradient", { Color = rainbowTrack }, track)
			else
				mk("UIGradient", { Color = ColorSequence.new(gA or M.ACCENT, gB or M.ACCENT2) }, fill)
			end
			local knob = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(20, 20), ZIndex = 3 }, track)
			M.corner(knob, 10)
			M.stroke(knob, 0.1, M.ACCENT, 2)
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

---------------------------------------------------------------------
-- 板の見た目変更 (この画面用。サーバーの受け口が無いときに使う)
---------------------------------------------------------------------
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

task.spawn(function()
	while true do
		if next(rainbowSet) == nil then
			task.wait(0.5)
		else
			task.wait(0.12)
			for m in pairs(rainbowSet) do
				if m.Parent then
					local s = st(m)
					local col = Color3.fromHSV((os.clock() * (s.rbSpeed or 0.15)) % 1, s.rbSat or 0.85, 1)
					local parts = partsOf(m)
					for _, p in ipairs(parts) do p.Color = col end
					local h = glowHost(m)
					local l = h and h:FindFirstChild("SkinGlow")
					if l then l.Color = col end
				else
					rainbowSet[m] = nil
				end
			end
		end
	end
end)

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
local W, H = 700, 470

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

-- 丸い開閉ボタン (左下・ドラッグ可能)
local toggle = mk("TextButton", { Name = "Toggle", AutoButtonColor = false, Text = "", BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 190, 1, -24), Size = UDim2.fromOffset(64, 64), ZIndex = 5 }, gui)
corner(toggle, 32)
mk("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(99, 102, 241), Color3.fromRGB(217, 70, 239)) }, toggle)
local ring = stroke(toggle, 0, WHITE, 3)
local ringGrad = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, CYAN), ColorSequenceKeypoint.new(0.5, PINK), ColorSequenceKeypoint.new(1, CYAN) }) }, ring)
mk("TextLabel", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "🎨", TextSize = 32, ZIndex = 6 }, toggle)
Lib.juice(toggle)

-- ウィンドウ
local win = mk("CanvasGroup", { Name = "Window", BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0), Size = UDim2.fromOffset(W, H) }, gui)
corner(win, 22)
local winStroke = stroke(win, 0.35, WHITE, 1.5)
mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(167, 139, 250)) }, winStroke)
local winScale = mk("UIScale", {}, win)

-- 背景 (グラデーションは子のFrameに付ける)
local bg = mk("Frame", { Name = "Bg", BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, win)
mk("UIGradient", { Rotation = 35, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 27, 90)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(88, 28, 160)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 90, 160)) }) }, bg)
local blob1 = mk("Frame", { BackgroundColor3 = PINK, BackgroundTransparency = 0.78, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.9, 0.08), Size = UDim2.fromOffset(320, 320) }, bg)
corner(blob1, 160)
local blob2 = mk("Frame", { BackgroundColor3 = Color3.fromRGB(56, 189, 248), BackgroundTransparency = 0.8, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.06, 0.98), Size = UDim2.fromOffset(340, 340) }, bg)
corner(blob2, 170)
local blob3 = mk("Frame", { BackgroundColor3 = Color3.fromRGB(167, 139, 250), BackgroundTransparency = 0.86, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.55, 0.5), Size = UDim2.fromOffset(220, 220) }, bg)
corner(blob3, 110)
local blobTweens = {}
local function blobsOn(on)
	for _, t in ipairs(blobTweens) do t:Cancel() end
	blobTweens = {}
	if not on then return end
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
local title = text(topbar, "PALLET STUDIO", 26, UDim2.fromOffset(16, 2), UDim2.fromOffset(260, 30))
local titleGrad = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.5, CYAN), ColorSequenceKeypoint.new(1, WHITE) }) }, title)
text(topbar, "板をカスタマイズ", 12, UDim2.fromOffset(17, 31), UDim2.fromOffset(200, 16), nil, SOFT)
local badge = mk("TextLabel", { Name = "Badge", BackgroundTransparency = 0.7, BackgroundColor3 = WHITE, BorderSizePixel = 0, Text = "板を出してね", TextSize = 14, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -92, 0.5, 0), Size = UDim2.fromOffset(120, 28) }, topbar)
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

-- 左のページ一覧
local side = mk("Frame", { Name = "Side", Position = UDim2.fromOffset(12, 68), Size = UDim2.fromOffset(150, H - 68 - 58) }, win)
Lib.glass(side, 0.88, 16)
mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, side)
mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)

-- 右の中身
local content = mk("Frame", { Name = "Content", Position = UDim2.fromOffset(170, 68), Size = UDim2.fromOffset(W - 182, H - 68 - 58) }, win)
Lib.glass(content, 0.9, 16)

-- 下のバー (板の選択 / 元に戻す / 保存)
local bottom = mk("Frame", { Name = "Bottom", Position = UDim2.fromOffset(12, H - 50), Size = UDim2.fromOffset(W - 24, 40) }, win)
Lib.glass(bottom, 0.85, 14)
local CHIP_W = W - 24 - 16 - 126 - 126 - 120
local chipRow = mk("ScrollingFrame", { Name = "Chips", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 0, Position = UDim2.fromOffset(8, 5), Size = UDim2.fromOffset(CHIP_W, 30) }, bottom)
mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, chipRow)
local emptyLbl = text(bottom, "板を出してね", 14, UDim2.fromOffset(12, 0), UDim2.fromOffset(CHIP_W, 40), Enum.TextXAlignment.Left, SOFT)
local resetBtn = mk("TextButton", { Name = "Reset", AutoButtonColor = false, Text = "↺ 元に戻す", TextSize = 15, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(110, 30) }, bottom)
Lib.glass(resetBtn, 0.55, 12)
resetBtn.BackgroundColor3 = Color3.fromRGB(244, 63, 94)
Lib.juice(resetBtn)
local permBtn = mk("TextButton", { Name = "Perm", AutoButtonColor = false, Text = "📌 永久保存", TextSize = 15, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -122, 0.5, 0), Size = UDim2.fromOffset(120, 30) }, bottom)
Lib.glass(permBtn, 0.45, 12)
permBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
Lib.juice(permBtn)
local saveBtn = mk("TextButton", { Name = "Save", AutoButtonColor = false, Text = "💾 保存", TextSize = 16, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(0, 30), Visible = false, ClipsDescendants = true, ZIndex = 4 }, bottom)
Lib.glass(saveBtn, 0.1, 12)
saveBtn.BackgroundColor3 = WHITE
mk("UIGradient", { Rotation = 20, Color = ColorSequence.new(Color3.fromRGB(16, 185, 129), Color3.fromRGB(56, 189, 248)) }, saveBtn)
Lib.juice(saveBtn)

-- 状態
local selected = nil
local chips = {}
local isOpen = false
local fitScale = 1
local dirty = {}
local recipe = setmetatable({}, { __mode = "k" })   -- 板ごとの操作ログ
local permanentOps = nil                             -- 永久保存した設定 (これから出す板に自動で反映)
local flashUntil = 0
local saveShown = false
local highlight = mk("Highlight", { FillColor = ACCENT, FillTransparency = 0.88, OutlineColor = ACCENT, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false }, gui)

local function setSave(v)
	if v == saveShown then return end
	saveShown = v
	if v then
		saveBtn.Visible = true
		saveBtn.Size = UDim2.fromOffset(0, 30)
		Lib.tween(saveBtn, { Size = UDim2.fromOffset(110, 30) }, 0.5)
	else
		local t = Lib.tween(saveBtn, { Size = UDim2.fromOffset(0, 30) }, 0.3)
		t.Completed:Connect(function()
			if not saveShown then saveBtn.Visible = false end
		end)
	end
	local x = v and -122 or -6
	Lib.tween(resetBtn, { Position = UDim2.new(1, x, 0.5, 0) }, 0.45)
	Lib.tween(permBtn, { Position = UDim2.new(1, x - 116, 0.5, 0) }, 0.45)
end

local slotOf = setmetatable({}, { __mode = "k" })
local seenMap = {}
local function myPallets()
	local list = {}
	local f = workspace:FindFirstChild(FOLDER)
	if f then
		for _, m in ipairs(f:GetChildren()) do
			if m.Name == "PalletLightBrown" and m:IsA("Model") then list[#list + 1] = m end
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
	for i, c in pairs(chips) do
		local active = (i == selected)
		if c.active ~= active then
			c.active = active
			Lib.tween(c.btn, { BackgroundColor3 = active and ACCENT or WHITE, BackgroundTransparency = active and 0.1 or 0.85 }, 0.25)
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
	permBtn.Text = permanentOps and "📌 永久保存中" or "📌 永久保存"
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
for i = 1, 7 do pages[i] = newPage() end

-- 1: 色
do
	local e = Lib.element(pages[1])
	e:title("カラー")
	local colors = {
		{239, 68, 68}, {249, 115, 22}, {250, 204, 21}, {132, 204, 22}, {52, 211, 153}, {20, 184, 166}, {56, 189, 248}, {59, 130, 246},
		{129, 140, 248}, {168, 85, 247}, {236, 72, 153}, {244, 63, 94}, {120, 72, 40}, {244, 245, 248}, {120, 126, 140}, {20, 22, 28},
		{255, 183, 205}, {253, 224, 71}, {190, 242, 100}, {110, 231, 183}, {147, 197, 253}, {196, 181, 253}, {251, 146, 60}, {148, 163, 184},
	}
	local row = e:row(gridHeight(#colors, 8, 34, 8))
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
	e:slider("色相", 0, 1, function(v, r) hsv[1] = v sendThrottled("HSV", { hsv[1], hsv[2], hsv[3] }, r) end, hsv[1], nil, nil, hueSeq())
	e:slider("彩度", 0, 1, function(v, r) hsv[2] = v sendThrottled("HSV", { hsv[1], hsv[2], hsv[3] }, r) end, hsv[2], WHITE, Color3.fromRGB(99, 102, 241))
	e:slider("明度", 0, 1, function(v, r) hsv[3] = v sendThrottled("HSV", { hsv[1], hsv[2], hsv[3] }, r) end, hsv[3], Color3.fromRGB(20, 20, 30), WHITE)
	e:title("色を調整 (RGB)")
	local rgb = { 1, 1, 1 }
	local function rgbSend(r) sendThrottled("RGB", { rgb[1], rgb[2], rgb[3] }, r) end
	e:slider("赤 R", 0, 1, function(v, r) rgb[1] = v rgbSend(r) end, 1, Color3.fromRGB(60, 10, 10), Color3.fromRGB(255, 70, 70))
	e:slider("緑 G", 0, 1, function(v, r) rgb[2] = v rgbSend(r) end, 1, Color3.fromRGB(10, 50, 20), Color3.fromRGB(70, 255, 110))
	e:slider("青 B", 0, 1, function(v, r) rgb[3] = v rgbSend(r) end, 1, Color3.fromRGB(10, 20, 60), Color3.fromRGB(70, 140, 255))
	e:title("16進数")
	local hr = e:row(40)
	local box = mk("TextBox", { PlaceholderText = "#RRGGBB", PlaceholderColor3 = SOFT, Text = "", TextSize = 15, FontFace = FONT, TextColor3 = WHITE, ClearTextOnFocus = false, Size = UDim2.new(1, -100, 1, 0) }, hr)
	Lib.glass(box, 0.85, 12)
	local ap = mk("TextButton", { AutoButtonColor = false, Text = "適用", TextSize = 16, FontFace = FONT, TextColor3 = WHITE, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(92, 40) }, hr)
	Lib.glass(ap, 0.3, 12)
	ap.BackgroundColor3 = ACCENT
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
	local row = e:row(gridHeight(#mats, 3, 56, 8))
	grid(row, 154, 56, 8, 8)
	for i, m in ipairs(mats) do
		local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i }, row)
		Lib.glass(b, 0.84, 14)
		local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(44, 44) }, b)
		corner(sw, 10)
		mk("UIGradient", { Rotation = 35, Color = ColorSequence.new(m[3], Color3.new(m[3].R * 0.5, m[3].G * 0.5, m[3].B * 0.5)) }, sw)
		text(b, m[2], 14, UDim2.fromOffset(56, 0), UDim2.new(1, -58, 1, 0), Enum.TextXAlignment.Left)
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
	local row = e:row(gridHeight(#presets, 3, 84, 8))
	grid(row, 154, 84, 8, 8)
	for i, p in ipairs(presets) do
		local b = mk("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i }, row)
		Lib.glass(b, 0.84, 14)
		local sw = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 44) }, b)
		corner(sw, 10)
		mk("UIGradient", { Rotation = 25, Color = ColorSequence.new(p[3], Color3.new(p[3].R * 0.45, p[3].G * 0.45, p[3].B * 0.45)) }, sw)
		text(b, p[2], 14, UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 24), Enum.TextXAlignment.Center)
		Lib.juice(b)
		b.MouseButton1Click:Connect(function() send("Preset", p[1]) end)
	end
end

-- 4: 質感
do
	local e = Lib.element(pages[4])
	e:title("質感")
	e:slider("反射", 0, 1, function(v, r) sendThrottled("Reflectance", v, r) end, 0)
	e:slider("透明度", 0, 0.9, function(v, r) sendThrottled("Transparency", v, r) end, 0)
	e:slider("色ムラ", 0, 1, function(v, r) sendThrottled("Variance", v, r) end, 0, Color3.fromRGB(99, 102, 241), PINK)
	e:title("テクスチャ")
	e:toggle("元の木目テクスチャ", function(s) send("Texture", s) end, true)
end

-- 5: 光
do
	local e = Lib.element(pages[5])
	e:title("発光")
	e:slider("発光の強さ", 0, 5, function(v, r) sendThrottled("Glow", v, r) end, 0, Color3.fromRGB(120, 80, 20), Color3.fromRGB(255, 240, 120))
	e:slider("発光の範囲", 4, 30, function(v, r) sendThrottled("GlowRange", v, r) end, 8)
	e:slider("発光の色", 0, 1, function(v, r) sendThrottled("GlowHue", v, r) end, 0.58, nil, nil, hueSeq())
	e:title("縁取り")
	local ot = e:toggle("縁取り", function(s) send("Outline", s) end, false)
	e:slider("縁取りの色", 0, 1, function(v, r) ot:set(true) sendThrottled("OutlineHue", v, r) end, 0.55, nil, nil, hueSeq())
end

-- 6: 効果
do
	local e = Lib.element(pages[6])
	e:title("レインボー")
	local rt = e:toggle("レインボー", function(s) send("Rainbow", s) end, false)
	e:slider("速さ", 0.02, 1, function(v, r) rt:set(true) sendThrottled("RainbowSpeed", v, r) end, 0.15)
	e:slider("鮮やかさ", 0, 1, function(v, r) sendThrottled("RainbowSat", v, r) end, 0.85, WHITE, PINK)
	e:title("キラキラ")
	local st_ = e:toggle("キラキラ", function(s) send("Sparkle", s) end, false)
	e:slider("量", 1, 120, function(v, r) st_:set(true) sendThrottled("SparkleRate", v, r) end, 25, Color3.fromRGB(99, 102, 241), CYAN)
	e:slider("大きさ", 0.05, 2, function(v, r) st_:set(true) sendThrottled("SparkleSize", v, r) end, 0.35, Color3.fromRGB(99, 102, 241), CYAN)
end

-- 7: その他
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

-- ページ切り替え
local tabs = { {"🎨", "色"}, {"🧱", "素材"}, {"✨", "プリセット"}, {"💎", "質感"}, {"💡", "光"}, {"🌈", "効果"}, {"⚙️", "その他"} }
local tabBtns = {}
local function showTab(i)
	for j, p in ipairs(pages) do p.Visible = (j == i) end
	for j, b in ipairs(tabBtns) do
		local active = (j == i)
		Lib.tween(b, { BackgroundColor3 = active and ACCENT or WHITE, BackgroundTransparency = active and 0.15 or 0.9 }, 0.3)
	end
end
for i, t in ipairs(tabs) do
	local b = mk("TextButton", { Name = "Tab" .. i, AutoButtonColor = false, Text = t[1] .. "  " .. t[2], TextSize = 17, FontFace = FONT, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 40) }, side)
	Lib.glass(b, 0.9, 13)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 14) }, b)
	Lib.juice(b)
	b.MouseButton1Click:Connect(function() showTab(i) end)
	tabBtns[i] = b
end

-- 開閉
local function fit()
	local vp = gui.AbsoluteSize
	fitScale = math.clamp(math.min((vp.X - 48) / W, (vp.Y - 48) / H), 0.5, 1)
end

local function setOpen(open)
	if open == isOpen then return end
	isOpen = open
	if open then
		fit()
		refresh()
		win.Visible = true
		winScale.Scale = 0.9 * fitScale
		blobsOn(true)
		Lib.tween(winScale, { Scale = fitScale }, 0.6)
		Lib.tween(win, { GroupTransparency = 0 }, 0.4)
	else
		selVisuals()
		Lib.tween(winScale, { Scale = 0.9 * fitScale }, 0.4)
		local t = Lib.tween(win, { GroupTransparency = 1 }, 0.3)
		t.Completed:Connect(function()
			if not isOpen then
				win.Visible = false
				blobsOn(false)
			end
		end)
	end
end

Lib.drag(toggle, toggle, function() setOpen(not isOpen) end)
Lib.drag(topbar, win, nil, winScale)
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
minBtn.MouseButton1Click:Connect(function() setOpen(false) end)
resetBtn.MouseButton1Click:Connect(function() send("Reset", nil) end)
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
TweenService:Create(ringGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
TweenService:Create(titleGrad, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()

local function isMine(m)
	local pv = m:FindFirstChild("PlayerValue")
	if not pv or not pv:IsA("ValueBase") then return true end
	local v = pv.Value
	if typeof(v) == "Instance" then return v == lp end
	if typeof(v) == "string" then return v == lp.Name or v == lp.DisplayName or v == tostring(lp.UserId) end
	if typeof(v) == "number" then return v == lp.UserId end
	return false
end

workspace.DescendantAdded:Connect(function(m)
	if m.Name ~= "PalletLightBrown" or not m:IsA("Model") then return end
	if m.Parent ~= workspace:FindFirstChild(FOLDER) then return end
	if isOpen then task.delay(0.5, refresh) end
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

-- 起動時: 右下に "make by aino" をぬるっと表示して消す
local function playCredit()
	local TextService = game:GetService("TextService")
	local function tw(o, t, props, style, dir)
		local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Exponential, dir or Enum.EasingDirection.Out), props)
		x:Play()
		return x
	end
	local cg = mk("ScreenGui", { Name = "PalletStudioCredit", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 2147483646, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, lp:WaitForChild("PlayerGui"))
	local pill = mk("CanvasGroup", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 70, 1, -28), Size = UDim2.fromOffset(212, 54), BackgroundTransparency = 1, GroupTransparency = 1, BorderSizePixel = 0 }, cg)
	corner(pill, 27)
	stroke(pill, 0.35, WHITE, 1.5)
	local sc = mk("UIScale", { Scale = 0.8 }, pill)
	local bgf = mk("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, pill)
	mk("UIGradient", { Rotation = 20, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(49, 46, 129)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(126, 34, 206)), ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 116, 190)) }) }, bgf)
	local icon = mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(28, 27), Size = UDim2.fromOffset(26, 26), Text = "✦", TextSize = 24, FontFace = FONT, TextColor3 = PINK }, pill)
	local holder = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 52, 0.5, 0), Size = UDim2.new(1, -62, 0, 30), ClipsDescendants = true }, pill)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, holder)
	local str = "make by aino"
	local letters = {}
	for i = 1, #str do
		local ch = str:sub(i, i)
		local w = (ch == " ") and 7 or math.ceil(TextService:GetTextSize(ch, 22, Enum.Font.FredokaOne, Vector2.new(200, 30)).X) + 1
		local wrap = mk("Frame", { BackgroundTransparency = 1, LayoutOrder = i, Size = UDim2.fromOffset(w, 30), ClipsDescendants = false }, holder)
		local lb = mk("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 16), Size = UDim2.fromScale(1, 1), Text = ch, TextSize = 22, FontFace = FONT, TextTransparency = 1, TextColor3 = (i > 8) and WHITE or Color3.fromRGB(221, 214, 254) }, wrap)
		if i > 8 then
			mk("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(244, 114, 182), Color3.fromRGB(125, 211, 252)), Rotation = 30 }, lb)
			lb.TextColor3 = WHITE
		end
		letters[i] = lb
	end
	local shine = mk("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.78, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.2, 0, 0.5, 0), Size = UDim2.fromOffset(34, 100), Rotation = 20, ZIndex = 5 }, pill)

	tw(pill, 0.9, { Position = UDim2.new(1, -28, 1, -28), GroupTransparency = 0 })
	tw(sc, 0.8, { Scale = 1 }, Enum.EasingStyle.Back)
	TweenService:Create(icon, TweenInfo.new(2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
	for i, lb in ipairs(letters) do
		task.delay(0.25 + i * 0.05, function()
			if lb.Parent then
				tw(lb, 0.6, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
				tw(lb, 0.5, { TextTransparency = 0 })
			end
		end)
	end
	task.delay(1.1, function()
		if shine.Parent then tw(shine, 0.9, { Position = UDim2.new(1.2, 0, 0.5, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut) end
	end)
	task.wait(3.4)
	tw(pill, 0.7, { Position = UDim2.new(1, 70, 1, -28), GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	tw(sc, 0.7, { Scale = 0.85 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	task.wait(0.8)
	cg:Destroy()
end
task.spawn(playCredit)
