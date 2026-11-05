-- WorldLife: dá vida e beleza ao mundo.
--  * céu estrelado, nuvens, brilho (bloom) e raios de sol
--  * luzes de rua e janelas que acendem à noite (seguindo o relógio do jogo)
--  * árvores, canteiros, bancos, chafarizes com água e outdoors de luxo
--  * visitantes (NPCs) que passeiam pela cidade usando Pathfinding
-- Tudo é gerado por código, sem depender de assets externos.
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))
local LuxuryKit = require(script.Parent:WaitForChild("LuxuryKit"))

local WorldLife = {}

local initialized = false
local LIFE_FOLDER_NAME = "HSC_Life"

local COLORS = {
	Gold = Color3.fromRGB(218, 180, 91),
	Stone = Color3.fromRGB(207, 204, 194),
	Wood = Color3.fromRGB(112, 82, 59),
	Green = Color3.fromRGB(77, 117, 78),
	DarkGreen = Color3.fromRGB(43, 79, 58),
	Water = Color3.fromRGB(110, 190, 225),
	Dark = Color3.fromRGB(24, 27, 32),
	WarmLight = Color3.fromRGB(255, 214, 140),
}

local function makePart(parent, name, size, cframe, color, material, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = canCollide ~= false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

----------------------------------------------------------------------
-- Céu e efeitos
----------------------------------------------------------------------

local function setupSky()
	local sky = getOrCreate(Lighting, "Sky", "HSC_Sky")
	sky.StarCount = 5000
	sky.SunAngularSize = 12
	sky.MoonAngularSize = 9
	sky.CelestialBodiesShown = true

	local bloom = getOrCreate(Lighting, "BloomEffect", "HSC_Bloom")
	bloom.Intensity = 0.55
	bloom.Size = 30
	bloom.Threshold = 1.5

	local sunRays = getOrCreate(Lighting, "SunRaysEffect", "HSC_SunRays")
	sunRays.Intensity = 0.12
	sunRays.Spread = 0.65

	local depthOfField = getOrCreate(Lighting, "DepthOfFieldEffect", "HSC_DepthOfField")
	depthOfField.FarIntensity = 0.08
	depthOfField.FocusDistance = 80
	depthOfField.InFocusRadius = 55
	depthOfField.NearIntensity = 0.02

	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.65

	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		local clouds = terrain:FindFirstChildOfClass("Clouds")
		if not clouds then
			clouds = Instance.new("Clouds")
			clouds.Parent = terrain
		end
		clouds.Cover = 0.35
		clouds.Density = 0.4
	end
end

----------------------------------------------------------------------
-- Decoração
----------------------------------------------------------------------

local function makeTree(parent, x, y, z, scale, isPalm)
	if isPalm then
		return LuxuryKit.palm(parent, "Palm", Vector3.new(x, y, z), scale, "beach")
	end
	return LuxuryKit.tree(parent, "Tree", Vector3.new(x, y, z), scale)
end

local function makeBench(parent, x, y, z, yaw)
	local model = Instance.new("Model")
	model.Name = "Bench"
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
	makePart(model, "Seat", Vector3.new(6, 0.5, 2), base * CFrame.new(0, 1.4, 0), COLORS.Wood, Enum.Material.Wood)
	makePart(
		model,
		"Back",
		Vector3.new(6, 1.6, 0.4),
		base * CFrame.new(0, 2.4, 0.8),
		COLORS.Wood,
		Enum.Material.Wood
	)
	makePart(model, "LegL", Vector3.new(0.5, 1.4, 1.8), base * CFrame.new(-2.5, 0.7, 0), COLORS.Gold, Enum.Material.Metal)
	makePart(model, "LegR", Vector3.new(0.5, 1.4, 1.8), base * CFrame.new(2.5, 0.7, 0), COLORS.Gold, Enum.Material.Metal)
	model.Parent = parent
end

local function makeFlowerBed(parent, x, y, z, width, depth, seed)
	local rng = Random.new(seed)
	local palette = {
		Color3.fromRGB(226, 84, 111),
		Color3.fromRGB(245, 205, 90),
		Color3.fromRGB(186, 120, 220),
		Color3.fromRGB(250, 250, 245),
		Color3.fromRGB(240, 140, 70),
	}
	local model = Instance.new("Model")
	model.Name = "FlowerBed"
	makePart(
		model,
		"Soil",
		Vector3.new(width, 0.8, depth),
		CFrame.new(x, y + 0.4, z),
		Color3.fromRGB(70, 50, 38),
		Enum.Material.Ground
	)
	for _ = 1, math.floor(width * depth / 3) do
		local fx = x + rng:NextNumber(-width / 2 + 0.4, width / 2 - 0.4)
		local fz = z + rng:NextNumber(-depth / 2 + 0.4, depth / 2 - 0.4)
		local flower = makePart(
			model,
			"Flower",
			Vector3.new(0.7, 0.7, 0.7),
			CFrame.new(fx, y + 1.1, fz),
			palette[rng:NextInteger(1, #palette)],
			Enum.Material.SmoothPlastic,
			0,
			false
		)
		flower.Shape = Enum.PartType.Ball
		flower.CastShadow = false
	end
	model.Parent = parent
end

local function addFountainSpray(basePart, topY)
	local emitterHolder = makePart(
		basePart.Parent,
		"FountainSpray",
		Vector3.new(0.5, 0.5, 0.5),
		CFrame.new(basePart.Position.X, topY, basePart.Position.Z),
		COLORS.Water,
		Enum.Material.SmoothPlastic,
		1,
		false
	)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Spray"
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new(0.55)
	emitter.Lifetime = NumberRange.new(1.2, 1.8)
	emitter.Rate = 90
	emitter.Speed = NumberRange.new(13, 17)
	emitter.SpreadAngle = Vector2.new(22, 22)
	emitter.Acceleration = Vector3.new(0, -32, 0)
	emitter.LightEmission = 0.4
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = emitterHolder
end

local function makeBillboard(parent, x, y, z, index, imageId)
	local model = Instance.new("Model")
	model.Name = "LuxuryBillboard" .. index
	makePart(model, "PostL", Vector3.new(1, 12, 1), CFrame.new(x - 9, y + 6, z + 0.6), COLORS.Dark, Enum.Material.Metal)
	makePart(model, "PostR", Vector3.new(1, 12, 1), CFrame.new(x + 9, y + 6, z + 0.6), COLORS.Dark, Enum.Material.Metal)
	local board = makePart(
		model,
		"Board",
		Vector3.new(24, 11, 0.8),
		CFrame.new(x, y + 14, z),
		COLORS.Dark,
		Enum.Material.SmoothPlastic
	)
	makePart(
		model,
		"Frame",
		Vector3.new(25, 0.6, 1),
		CFrame.new(x, y + 19.8, z),
		COLORS.Gold,
		Enum.Material.Metal
	)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "BillboardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.Parent = board

	if imageId then
		local image = Instance.new("ImageLabel")
		image.Size = UDim2.fromScale(1, 1)
		image.BackgroundTransparency = 1
		image.ScaleType = Enum.ScaleType.Crop
		image.Image = "rbxassetid://" .. tostring(imageId)
		image.Parent = gui
	else
		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(1, 0.55)
		title.Position = UDim2.fromScale(0, 0.1)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.Text = "THE HIGH SOCIETY CLUB"
		title.TextColor3 = COLORS.Gold
		title.TextScaled = true
		title.Parent = gui

		local slogan = Instance.new("TextLabel")
		slogan.Size = UDim2.fromScale(1, 0.2)
		slogan.Position = UDim2.fromScale(0, 0.65)
		slogan.BackgroundTransparency = 1
		slogan.Font = Enum.Font.Gotham
		slogan.Text = "Seu mundo. Seu estilo. Sua conquista."
		slogan.TextColor3 = Color3.fromRGB(235, 235, 235)
		slogan.TextScaled = true
		slogan.Parent = gui
	end

	local glow = Instance.new("SpotLight")
	glow.Name = "BillboardLight"
	glow.Face = Enum.NormalId.Front
	glow.Range = 40
	glow.Angle = 80
	glow.Brightness = 1.5
	glow.Parent = board

	model.Parent = parent
end

----------------------------------------------------------------------
-- Luzes que acendem à noite
----------------------------------------------------------------------

local nightLamps = {}
local windows = {}
local glowParts = {}

local WINDOW_NAMES = {
	Window = true,
	WindowBand = true,
	WindowBandBack = true,
	StorefrontGlass = true,
	StorefrontGlassBack = true,
	SideStorefront = true,
	UpperGlassFront = true,
	UpperGlassSide = true,
	FrontWindowGlass = true,
	SideWindowGlass = true,
	GlassDome = true,
}

local function collectLightTargets(world)
	for _, descendant in ipairs(world:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Name == "StreetLight" then
				local light = descendant:FindFirstChildOfClass("PointLight")
				if not light then
					light = Instance.new("PointLight")
					light.Name = "NightLamp"
					light.Color = COLORS.WarmLight
					light.Range = 40
					light.Brightness = 2
					light.Parent = descendant
				end
				light.Enabled = false
				table.insert(nightLamps, { Part = descendant, Light = light })
			elseif descendant.Name == "StreetGlow" then
				table.insert(glowParts, descendant)
			elseif WINDOW_NAMES[descendant.Name] then
				table.insert(windows, {
					Part = descendant,
					Color = descendant.Color,
					Material = descendant.Material,
					Transparency = descendant.Transparency,
					Lit = math.random() < 0.65,
				})
			end
		end
	end
end

local function setNight(isNight)
	for _, lamp in ipairs(nightLamps) do
		if lamp.Part.Parent then
			lamp.Light.Enabled = isNight
			lamp.Part.Material = Enum.Material.Neon
		end
	end
	for _, glow in ipairs(glowParts) do
		if glow.Parent then
			glow.Material = isNight and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
	for _, window in ipairs(windows) do
		if window.Part.Parent then
			if isNight and window.Lit then
				window.Part.Color = COLORS.WarmLight
				window.Part.Material = Enum.Material.Neon
				window.Part.Transparency = 0.1
			else
				window.Part.Color = window.Color
				window.Part.Material = window.Material
				window.Part.Transparency = window.Transparency
			end
		end
	end
end

local function startNightLoop()
	task.spawn(function()
		local lastState
		while true do
			local hour = Lighting.ClockTime
			local isNight = hour >= 18 or hour < 6
			if isNight ~= lastState then
				lastState = isNight
				setNight(isNight)
			end
			task.wait(5)
		end
	end)
end

----------------------------------------------------------------------
-- Visitantes (NPCs)
----------------------------------------------------------------------

----------------------------------------------------------------------
-- AVATARES DOS VISITANTES
-- (1) Modelos próprios em ServerStorage > HSC_NpcModels, se existirem.
-- (2) Senão, avatares reais do Roblox da lista abaixo.
-- Cada visitante usa o avatar REAL de uma conta do Roblox (cabelo, rosto,
-- roupas e acessórios de verdade) — 100% gratuito, sem comprar nada.
--
-- Como trocar os avatares:
--   * Coloque o ID numérico (o número na URL do perfil:
--     roblox.com/users/NUMERO/profile) OU o nome de usuário entre aspas.
--   * Quanto mais avatares na lista, mais variados ficam os visitantes.
--   * Use contas com visual elegante (roupas sociais, vestidos, etc.).
----------------------------------------------------------------------
local NPC_AVATARS = {
	1, -- Roblox
	156, -- builderman
	-- Adicione aqui os avatares que você achar bonitos, por exemplo:
	-- 123456789,
	-- "NomeDeUsuario",
}

local descriptionCache = {}
local avatarUserIds = {}
local npcCreationBroken = false

local function resolveAvatarUserIds()
	local ids = {}
	for _, entry in ipairs(NPC_AVATARS) do
		if typeof(entry) == "number" then
			table.insert(ids, entry)
		elseif typeof(entry) == "string" then
			local ok, userId = pcall(function()
				return Players:GetUserIdFromNameAsync(entry)
			end)
			if ok and typeof(userId) == "number" then
				table.insert(ids, userId)
			else
				Logger.Warn("WorldLife", "Avatar de visitante não encontrado: " .. entry)
			end
		end
	end
	return ids
end

local function getAvatarDescription(userId)
	local cached = descriptionCache[userId]
	if cached == nil then
		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		if ok and description then
			cached = description
		else
			cached = false
		end
		descriptionCache[userId] = cached
	end
	if cached then
		return cached:Clone()
	end
	return nil
end

local function getPlayerAvatarDescription()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local ok, description = pcall(function()
				return humanoid:GetAppliedDescription()
			end)
			if ok and description then
				return description
			end
		end
	end
	return nil
end

-- Personagens prontos (ex.: modelos do Meshy já com Humanoid) colocados em
-- ServerStorage > HSC_NpcModels. Se a pasta existir e tiver modelos, eles têm prioridade.
local NPC_MODELS_FOLDER = "HSC_NpcModels"

local function buildCustomNpcModel(index)
	local folder = ServerStorage:FindFirstChild(NPC_MODELS_FOLDER)
	if not folder then
		return nil
	end
	local templates = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
			table.insert(templates, child)
		end
	end
	if #templates == 0 then
		return nil
	end
	table.sort(templates, function(left, right)
		return left.Name < right.Name
	end)

	local template = templates[((index - 1) % #templates) + 1]
	local model = template:Clone()
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
	end
	if not model:FindFirstChild("HumanoidRootPart") then
		model:Destroy()
		Logger.Warn("WorldLife", "Modelo sem HumanoidRootPart na pasta " .. NPC_MODELS_FOLDER .. ": " .. template.Name)
		return nil
	end
	model.Name = "Visitante " .. index
	model:SetAttribute("HSC_NPC", true)
	return model
end

local function buildNpcModel(index)
	local customModel = buildCustomNpcModel(index)
	if customModel then
		return customModel
	end

	local description
	local total = #avatarUserIds
	for attempt = 0, total - 1 do
		local userId = avatarUserIds[((index - 1 + attempt) % total) + 1]
		description = getAvatarDescription(userId)
		if description then
			break
		end
	end
	if not description then
		description = getPlayerAvatarDescription()
	end
	if not description then
		return nil, "nenhum avatar disponível para os visitantes"
	end

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	description:Destroy()
	if not ok or not model then
		return nil, tostring(model)
	end
	model.Name = "Visitante " .. index
	model:SetAttribute("HSC_NPC", true)
	return model
end

local function buildTargetList(world, groundY)
	local targets = {
		Vector3.new(0, groundY + 3, 0),
		Vector3.new(0, groundY + 3, 20),
		Vector3.new(-150, groundY + 3, 20),
		Vector3.new(-150, groundY + 3, 95),
		Vector3.new(12, groundY + 3, 30),
		Vector3.new(12, groundY + 3, 80),
		Vector3.new(178, groundY + 3, 40),
		Vector3.new(178, groundY + 3, 120),
		Vector3.new(-100, groundY + 3, -40),
		Vector3.new(60, groundY + 3, -40),
		Vector3.new(150, groundY + 3, -40),
		Vector3.new(160, groundY + 3, 160),
	}
	for _, folderName in ipairs({ "WorkPoints", "EventPoints" }) do
		local folder = world and world:FindFirstChild(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("BasePart") then
					table.insert(targets, child.Position + Vector3.new(0, 1, 0))
				end
			end
		end
	end
	return targets
end

local function walkTo(humanoid, root, destination)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
	})
	local computed = pcall(function()
		path:ComputeAsync(root.Position, destination)
	end)
	if not computed or path.Status ~= Enum.PathStatus.Success then
		return false
	end

	for _, waypoint in ipairs(path:GetWaypoints()) do
		if humanoid.Health <= 0 or not root.Parent then
			return false
		end
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end
		humanoid:MoveTo(waypoint.Position)

		local finished = false
		local connection = humanoid.MoveToFinished:Connect(function()
			finished = true
		end)
		local deadline = os.clock() + 4
		while not finished and os.clock() < deadline and humanoid.Health > 0 do
			task.wait(0.1)
		end
		connection:Disconnect()
		if not finished then
			return false
		end
	end
	return true
end

local function runNpc(index, world, groundY, targets)
	local rng = Random.new(os.time() + index * 131)
	while true do
		local model, errorMessage = buildNpcModel(index)
		if not model then
			if not npcCreationBroken then
				npcCreationBroken = true
				Logger.Warn("WorldLife", "Não foi possível criar os visitantes (NPCs): " .. tostring(errorMessage))
			end
			return
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			model:Destroy()
			return
		end

		humanoid.WalkSpeed = rng:NextNumber(8, 11)
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.BreakJointsOnDeath = false

		local start = targets[rng:NextInteger(1, #targets)]
		model:PivotTo(CFrame.new(start + Vector3.new(rng:NextNumber(-4, 4), 2, rng:NextNumber(-4, 4))))
		model.Parent = world.Parent == workspace and world or workspace
		pcall(function()
			root:SetNetworkOwner(nil)
		end)

		while model.Parent and humanoid.Health > 0 and root.Position.Y > groundY - 20 do
			local destination = targets[rng:NextInteger(1, #targets)]
				+ Vector3.new(rng:NextNumber(-5, 5), 0, rng:NextNumber(-5, 5))
			walkTo(humanoid, root, destination)
			task.wait(rng:NextNumber(3, 10))
		end

		model:Destroy()
		task.wait(3)
	end
end

local function startNpcs(world, groundY)
	local count = math.clamp(tonumber(Config.World and Config.World.NpcCount) or 0, 0, 40)
	if count <= 0 then
		return
	end
	local targets = buildTargetList(world, groundY)
	task.spawn(function()
		avatarUserIds = resolveAvatarUserIds()
		for index = 1, count do
			task.spawn(function()
				-- Escalona a criação para não pesar no início do servidor.
				task.wait(index * 1.5)
				runNpc(index, world, groundY, targets)
			end)
		end
	end)
end

----------------------------------------------------------------------
-- Montagem
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Ruas, calçadas e praça (acabamento de luxo)
-- Só ADICIONA peças dentro da pasta HSC_Streetscape, por cima das ruas e
-- calçadas que já existem. Nada do que já foi construído é apagado.
----------------------------------------------------------------------

local STREETSCAPE_FOLDER = "HSC_Streetscape"
-- v4: EntrancePath no mesmo nível da calçada (WalkTop = groundY + 0,30).
local STREETSCAPE_VERSION = 4

local STREET_COLORS = {
	Asphalt = Color3.fromRGB(30, 32, 38),
	Mark = Color3.fromRGB(240, 232, 205),
	Gold = Color3.fromRGB(218, 180, 91),
	Paver = Color3.fromRGB(214, 203, 182),
	Ivory = Color3.fromRGB(250, 246, 236),
	Slate = Color3.fromRGB(62, 68, 84),
	Charcoal = Color3.fromRGB(28, 30, 36),
	Glow = Color3.fromRGB(255, 226, 170),
}

local CROSSING_XS = { -150, 12, 178 }

local function lay(parent, name, size, cframe, color, material)
	local part = makePart(parent, name, size, cframe, color, material, 0, false)
	part.CanQuery = false
	part.CastShadow = false
	return part
end

local function layCylinder(parent, name, height, diameter, center, color, material)
	local part = LuxuryKit.verticalCylinder(parent, name, height, diameter, center, color, material, 0, false)
	part.CanQuery = false
	part.CastShadow = false
	return part
end

local function collectMedians(boulevard)
	local medians = {}
	for _, child in ipairs(boulevard:GetChildren()) do
		if child.Name == "MedianIsland" and child:IsA("BasePart") then
			table.insert(medians, { X = child.Position.X, Half = child.Size.X / 2 })
		end
	end
	table.sort(medians, function(left, right)
		return left.X < right.X
	end)
	return medians
end

local function nearAny(value, centers, distance)
	for _, center in ipairs(centers) do
		if math.abs(value - center) < distance then
			return true
		end
	end
	return false
end

-- Baliza elegante (corpo escuro, topo dourado e faixa que brilha à noite).
local function addBollard(folder, basePosition)
	layCylinder(
		folder,
		"BollardBody",
		1.5,
		0.5,
		basePosition + Vector3.new(0, 0.75, 0),
		STREET_COLORS.Charcoal,
		Enum.Material.Metal
	)
	layCylinder(
		folder,
		"BollardCap",
		0.14,
		0.62,
		basePosition + Vector3.new(0, 1.57, 0),
		STREET_COLORS.Gold,
		Enum.Material.Metal
	)
	layCylinder(
		folder,
		"StreetGlow",
		0.16,
		0.54,
		basePosition + Vector3.new(0, 1.2, 0),
		STREET_COLORS.Glow,
		Enum.Material.SmoothPlastic
	)
end

-- Rua principal: asfalto escuro, faixas laterais e linha dupla dourada entre os canteiros.
local function polishMainRoad(folder, boulevard)
	local road = boulevard and boulevard:FindFirstChild("MainRoad")
	if not road or not road:IsA("BasePart") then
		return
	end

	local length = road.Size.X
	local width = road.Size.Z
	local lift = road.Size.Y / 2
	local function onRoad(localX, rise, localZ)
		return road.CFrame * CFrame.new(localX, lift + rise, localZ)
	end

	lay(
		folder,
		"RoadAsphalt",
		Vector3.new(length, 0.04, width - 1),
		onRoad(0, 0.02, 0),
		STREET_COLORS.Asphalt,
		Enum.Material.Asphalt
	)

	for _, side in ipairs({ -1, 1 }) do
		lay(
			folder,
			"RoadEdgeLine",
			Vector3.new(length, 0.02, 0.35),
			onRoad(0, 0.05, side * (width / 2 - 1.6)),
			STREET_COLORS.Mark,
			Enum.Material.SmoothPlastic
		)
	end

	-- Linha dupla dourada, interrompida nos canteiros centrais.
	local medians = collectMedians(boulevard)
	local roadX = road.Position.X
	local cursor = -length / 2 + 2
	local function centerLine(fromX, toX)
		if toX - fromX < 3 then
			return
		end
		for _, offset in ipairs({ -0.35, 0.35 }) do
			lay(
				folder,
				"RoadCenterLine",
				Vector3.new(toX - fromX, 0.02, 0.18),
				onRoad((fromX + toX) / 2, 0.05, offset),
				STREET_COLORS.Gold,
				Enum.Material.SmoothPlastic
			)
		end
	end
	for _, median in ipairs(medians) do
		local localX = median.X - roadX
		centerLine(cursor, localX - median.Half - 1)
		cursor = localX + median.Half + 1
	end
	centerLine(cursor, length / 2 - 2)

	-- Faixas de pedestre nos cruzamentos com as alamedas.
	for _, crossingX in ipairs(CROSSING_XS) do
		local localX = crossingX - roadX
		local blockedByMedian = false
		for _, median in ipairs(medians) do
			if math.abs(median.X - crossingX) < median.Half + 4 then
				blockedByMedian = true
			end
		end
		for index = -4, 4 do
			local z = index * 2.2
			if not blockedByMedian or math.abs(z) > 2.4 then
				lay(
					folder,
					"Crosswalk",
					Vector3.new(8, 0.02, 1),
					onRoad(localX, 0.07, z),
					STREET_COLORS.Mark,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end

	-- Balizas elegantes nas duas calçadas (brilham à noite).
	local bollardLift = lift
	local nearCrossings = {}
	for _, crossingX in ipairs(CROSSING_XS) do
		table.insert(nearCrossings, crossingX - roadX)
	end
	for localX = -216, 216, 16 do
		if not nearAny(localX, nearCrossings, 8) then
			for _, side in ipairs({ -1, 1 }) do
				local base = road.CFrame * CFrame.new(localX, bollardLift, side * (width / 2 + 1.3))
				addBollard(folder, base.Position)
			end
		end
	end
end

-- Alamedas e passeios: pavimento claro com frisos dourados.
local PROMENADE_NAMES = {
	"BoulevardToGarden",
	"ClubPromenade",
	"BoulevardToMarina",
	"GardenWalkNorth",
	"GardenWalkSouth",
	"IslandPromenade",
	"BeachPromenade",
	"MarinaPromenade",
}

local function polishPromenades(folder, world)
	for _, name in ipairs(PROMENADE_NAMES) do
		local path = world:FindFirstChild(name, true)
		if path and path:IsA("BasePart") then
			local lift = path.Size.Y / 2
			local width = path.Size.Z
			lay(
				folder,
				name .. "Pavers",
				Vector3.new(path.Size.X, 0.04, math.max(width - 1.6, 1)),
				path.CFrame * CFrame.new(0, lift + 0.02, 0),
				STREET_COLORS.Paver,
				Enum.Material.Cobblestone
			)
			for _, side in ipairs({ -1, 1 }) do
				lay(
					folder,
					name .. "GoldInlay",
					Vector3.new(path.Size.X, 0.05, 0.2),
					path.CFrame * CFrame.new(0, lift + 0.025, side * (width / 2 - 0.8)),
					STREET_COLORS.Gold,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end
end

-- Praça central: anéis de mármore com frisos dourados, raios e luzes no piso.
local function polishCentralPlaza(folder, world)
	local plaza = world:FindFirstChild("CentralPlaza", true) or workspace:FindFirstChild("CentralPlaza", true)
	local base = plaza and plaza:FindFirstChild("PlazaBase")
	local basin = plaza and plaza:FindFirstChild("PlazaFountainBasin")
	if not base or not base:IsA("BasePart") or not basin or not basin:IsA("BasePart") then
		return
	end

	local top = base.Position.Y + base.Size.Y / 2
	local fx, fz = basin.Position.X, basin.Position.Z

	local function ring(name, height, diameter, riseTop, color, material)
		layCylinder(
			folder,
			name,
			height,
			diameter,
			Vector3.new(fx, top + riseTop - height / 2, fz),
			color,
			material
		)
	end
	ring("PlazaRingGoldOuter", 0.03, 31, 0.03, STREET_COLORS.Gold, Enum.Material.SmoothPlastic)
	ring("PlazaRingSlate", 0.03, 30, 0.04, STREET_COLORS.Slate, Enum.Material.Marble)
	ring("PlazaRingGoldInner", 0.03, 24.8, 0.05, STREET_COLORS.Gold, Enum.Material.SmoothPlastic)
	ring("PlazaRingIvory", 0.03, 24, 0.06, STREET_COLORS.Ivory, Enum.Material.Marble)

	for index = 0, 11 do
		local angle = math.rad(index * 30)
		lay(
			folder,
			"PlazaSunburst",
			Vector3.new(3.4, 0.03, 0.22),
			CFrame.new(fx, top + 0.075, fz) * CFrame.Angles(0, angle, 0) * CFrame.new(10.4, 0, 0),
			STREET_COLORS.Gold,
			Enum.Material.SmoothPlastic
		)
	end

	for index = 0, 15 do
		local angle = math.rad(index * 22.5)
		local disc = layCylinder(
			folder,
			"StreetGlow",
			0.04,
			0.55,
			Vector3.new(fx + math.cos(angle) * 13.7, top + 0.06, fz + math.sin(angle) * 13.7),
			STREET_COLORS.Glow,
			Enum.Material.SmoothPlastic
		)
		disc.Color = STREET_COLORS.Glow
	end
end

-- Rua da Fashion Avenue: as fachadas das lojas, do hotel e da galeria de carros
-- olham para o lado norte (z negativo), onde antes só havia grama. Aqui nasce a
-- rua de frente para elas, com calçadas de mármore, faixas, postes e palmeiras,
-- além de duas ruas de ligação com a avenida principal.
local FRONT_ROAD_Z = -164.5
local FRONT_ROAD_WIDTH = 24
local FRONT_X_MIN = -220
local FRONT_X_MAX = 220
local FRONT_ENTRANCE_XS = { -150, -68, 93, 178 }
local FRONT_CROSSWALK_XS = { -150, -68, -22, 93, 178 }
local FRONT_CONNECTOR_XS = { -107.5, 136 }

local function solid(part)
	part.CanCollide = true
	part.CanQuery = true
	return part
end

local function polishFrontAvenue(folder, world, groundY)
	if not world:FindFirstChild("HighSocietyBoulevard") then
		return
	end

	local length = FRONT_X_MAX - FRONT_X_MIN
	local centerX = (FRONT_X_MIN + FRONT_X_MAX) / 2
	local southEdge = FRONT_ROAD_Z + FRONT_ROAD_WIDTH / 2
	local northEdge = FRONT_ROAD_Z - FRONT_ROAD_WIDTH / 2
	local sidewalkColor = Color3.fromRGB(226, 220, 206)

	solid(lay(
		folder,
		"FrontAvenueRoad",
		Vector3.new(length, 0.3, FRONT_ROAD_WIDTH),
		CFrame.new(centerX, groundY + 0.15, FRONT_ROAD_Z),
		STREET_COLORS.Asphalt,
		Enum.Material.Asphalt
	))
	solid(lay(
		folder,
		"FrontAvenueSidewalkSouth",
		Vector3.new(length, 0.3, 7),
		CFrame.new(centerX, groundY + 0.15, southEdge + 3.5),
		sidewalkColor,
		Enum.Material.Marble
	))
	solid(lay(
		folder,
		"FrontAvenueSidewalkNorth",
		Vector3.new(length, 0.3, 7),
		CFrame.new(centerX, groundY + 0.15, northEdge - 3.5),
		sidewalkColor,
		Enum.Material.Marble
	))
	for _, curbZ in ipairs({ southEdge + 0.18, northEdge - 0.18 }) do
		lay(
			folder,
			"FrontAvenueGoldCurb",
			Vector3.new(length, 0.12, 0.35),
			CFrame.new(centerX, groundY + 0.36, curbZ),
			STREET_COLORS.Gold,
			Enum.Material.Metal
		)
	end

	-- Marcação da pista.
	for _, side in ipairs({ -1, 1 }) do
		lay(
			folder,
			"FrontRoadEdgeLine",
			Vector3.new(length, 0.02, 0.35),
			CFrame.new(centerX, groundY + 0.31, FRONT_ROAD_Z + side * (FRONT_ROAD_WIDTH / 2 - 1.6)),
			STREET_COLORS.Mark,
			Enum.Material.SmoothPlastic
		)
	end
	for _, offset in ipairs({ -0.35, 0.35 }) do
		lay(
			folder,
			"FrontRoadCenterLine",
			Vector3.new(length, 0.02, 0.18),
			CFrame.new(centerX, groundY + 0.31, FRONT_ROAD_Z + offset),
			STREET_COLORS.Gold,
			Enum.Material.SmoothPlastic
		)
	end
	for _, crossingX in ipairs(FRONT_CROSSWALK_XS) do
		for index = -4, 4 do
			lay(
				folder,
				"FrontCrosswalk",
				Vector3.new(8, 0.02, 1),
				CFrame.new(crossingX, groundY + 0.33, FRONT_ROAD_Z + index * 2.2),
				STREET_COLORS.Mark,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- Ruas de ligação entre a avenida principal e a Fashion Avenue.
	local connectorStartZ = -66.25
	local connectorEndZ = southEdge + 7
	local connectorLength = connectorStartZ - connectorEndZ
	for _, connectorX in ipairs(FRONT_CONNECTOR_XS) do
		solid(lay(
			folder,
			"ConnectorRoad",
			Vector3.new(10, 0.3, connectorLength),
			CFrame.new(connectorX, groundY + 0.15, (connectorStartZ + connectorEndZ) / 2),
			STREET_COLORS.Asphalt,
			Enum.Material.Asphalt
		))
		for _, side in ipairs({ -1, 1 }) do
			lay(
				folder,
				"ConnectorEdgeLine",
				Vector3.new(0.35, 0.02, connectorLength),
				CFrame.new(connectorX + side * 4.3, groundY + 0.31, (connectorStartZ + connectorEndZ) / 2),
				STREET_COLORS.Mark,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- Passeios de entrada: da escadaria de cada edifício até a calçada.
	for _, entranceX in ipairs(FRONT_ENTRANCE_XS) do
		local pathStartZ = -135.5 -- pé da escadaria
		local pathEndZ = southEdge + 7 -- borda interna da calçada
		local pathLength = pathStartZ - pathEndZ
		local pathCenterZ = (pathStartZ + pathEndZ) / 2
		-- Mesmo nível da calçada e do primeiro degrau (WalkTop = groundY + 0,30).
		-- O topo fica 0,01 abaixo para não coincidir com o topo do degrau
		-- onde o passeio encosta na escadaria (evita z-fighting).
		solid(lay(
			folder,
			"EntrancePath",
			Vector3.new(9, 0.3, pathLength),
			CFrame.new(entranceX, groundY + 0.14, pathCenterZ),
			STREET_COLORS.Ivory,
			Enum.Material.Marble
		))
		for _, side in ipairs({ -1, 1 }) do
			lay(
				folder,
				"EntrancePathGold",
				Vector3.new(0.2, 0.03, pathLength),
				CFrame.new(entranceX + side * 4.3, groundY + 0.30, pathCenterZ),
				STREET_COLORS.Gold,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- Postes na calçada das lojas, palmeiras na calçada oposta e balizas nas duas.
	local avoidLamps = {}
	for _, x in ipairs(FRONT_CROSSWALK_XS) do
		table.insert(avoidLamps, x)
	end
	for _, x in ipairs(FRONT_CONNECTOR_XS) do
		table.insert(avoidLamps, x)
	end
	for x = FRONT_X_MIN + 10, FRONT_X_MAX - 10, 30 do
		if not nearAny(x, avoidLamps, 9) then
			LuxuryKit.streetLamp(folder, "FrontLamp", Vector3.new(x, groundY + 0.3, southEdge + 3.5), 9.5, STREET_COLORS.Charcoal)
		end
	end
	for x = FRONT_X_MIN + 12, FRONT_X_MAX - 12, 24 do
		if not nearAny(x, avoidLamps, 7) then
			LuxuryKit.palm(folder, "FrontPalm", Vector3.new(x, groundY + 0.3, northEdge - 3.5), 0.9, "beach")
		end
	end
	for x = FRONT_X_MIN + 8, FRONT_X_MAX - 8, 16 do
		if not nearAny(x, avoidLamps, 8) then
			addBollard(folder, Vector3.new(x, groundY + 0.3, southEdge + 1.3))
			addBollard(folder, Vector3.new(x, groundY + 0.3, northEdge - 1.3))
		end
	end
end

-- Garden Park: praça de mármore em volta do espelho d'água, avenida de entrada
-- e balizas luminosas ao longo das duas alamedas.
local function polishGarden(folder, world, groundY)
	local garden = world:FindFirstChild("GardenPark")
	local lawn = garden and garden:FindFirstChild("GardenLawn")
	local basin = garden and garden:FindFirstChild("GardenFountainBasin")
	if not lawn or not lawn:IsA("BasePart") or not basin or not basin:IsA("BasePart") then
		return
	end

	local top = lawn.Position.Y + lawn.Size.Y / 2
	local fx, fz = basin.Position.X, basin.Position.Z

	local function ring(name, diameter, riseTop, color, material)
		layCylinder(folder, name, 0.03, diameter, Vector3.new(fx, top + riseTop - 0.015, fz), color, material)
	end
	ring("GardenPlazaGold", 32.6, 0.03, STREET_COLORS.Gold, Enum.Material.SmoothPlastic)
	ring("GardenPlazaPaver", 32, 0.04, STREET_COLORS.Paver, Enum.Material.Marble)
	ring("GardenPlazaSlate", 29, 0.05, STREET_COLORS.Slate, Enum.Material.Marble)
	ring("GardenPlazaInner", 28.4, 0.06, STREET_COLORS.Paver, Enum.Material.Marble)
	for index = 0, 11 do
		local angle = math.rad(index * 30)
		layCylinder(
			folder,
			"StreetGlow",
			0.04,
			0.5,
			Vector3.new(fx + math.cos(angle) * 15.2, top + 0.06, fz + math.sin(angle) * 15.2),
			STREET_COLORS.Glow,
			Enum.Material.SmoothPlastic
		)
	end

	-- Avenida de entrada (norte e sul), alinhada com a alameda da avenida principal.
	for _, strip in ipairs({ { 39, 66 }, { 98, 121 } }) do
		local zStart, zEnd = strip[1], strip[2]
		local centerZ = (zStart + zEnd) / 2
		lay(
			folder,
			"GardenAvenuePavers",
			Vector3.new(6, 0.04, zEnd - zStart),
			CFrame.new(fx, top + 0.02, centerZ),
			STREET_COLORS.Paver,
			Enum.Material.Cobblestone
		)
		for _, side in ipairs({ -1, 1 }) do
			lay(
				folder,
				"GardenAvenueGold",
				Vector3.new(0.2, 0.05, zEnd - zStart),
				CFrame.new(fx + side * 2.6, top + 0.025, centerZ),
				STREET_COLORS.Gold,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- Balizas luminosas ao longo das alamedas do parque.
	local avoid = { fx, -175, -125 }
	for _, walkZ in ipairs({ 58, 104 }) do
		for x = -188, -112, 12 do
			if not nearAny(x, avoid, 7) then
				for _, side in ipairs({ -1, 1 }) do
					addBollard(folder, Vector3.new(x, top, walkZ + side * 4.8))
				end
			end
		end
	end
end

-- Marina e Paradise Island: luzes e frisos nos píeres, balizas nos calçadões
-- e praça de mármore diante do Royal Marina Clubhouse.
local function polishMarina(folder, world, groundY)
	local district = world:FindFirstChild("ParadiseIslandAndRoyalMarina")
	if not district then
		return
	end

	for index = 1, 3 do
		local dock = district:FindFirstChild("MarinaDock" .. index)
		if dock and dock:IsA("BasePart") then
			local deckTop = dock.Position.Y + dock.Size.Y / 2
			for _, side in ipairs({ -1, 1 }) do
				lay(
					folder,
					"DockGoldInlay",
					Vector3.new(0.12, 0.04, dock.Size.Z - 2),
					CFrame.new(dock.Position.X + side * 3.2, deckTop + 0.02, dock.Position.Z),
					STREET_COLORS.Gold,
					Enum.Material.SmoothPlastic
				)
				lay(
					folder,
					"StreetGlow",
					Vector3.new(0.2, 0.05, dock.Size.Z - 2),
					CFrame.new(dock.Position.X + side * 3.6, deckTop + 0.025, dock.Position.Z),
					STREET_COLORS.Glow,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end

	for _, name in ipairs({ "IslandPromenade", "BeachPromenade" }) do
		local path = district:FindFirstChild(name, true)
		if path and path:IsA("BasePart") then
			local pathTop = path.Position.Y + path.Size.Y / 2
			for step = -2, 2 do
				addBollard(
					folder,
					Vector3.new(path.Position.X + step * 16, pathTop + 0.04, path.Position.Z - path.Size.Z / 2 - 0.5)
				)
			end
		end
	end

	local clubhouse = district:FindFirstChild("RoyalMarinaClubhouse")
	local foundation = clubhouse and clubhouse:FindFirstChild("Foundation")
	if foundation and foundation:IsA("BasePart") then
		local centerX = foundation.Position.X
		local frontZ = foundation.Position.Z - foundation.Size.Z / 2
		local plazaZ = frontZ - 12
		lay(
			folder,
			"MarinaForecourt",
			Vector3.new(22, 0.1, 14),
			CFrame.new(centerX, groundY + 0.05, plazaZ),
			STREET_COLORS.Ivory,
			Enum.Material.Marble
		)
		for _, side in ipairs({ -1, 1 }) do
			lay(
				folder,
				"MarinaForecourtGold",
				Vector3.new(0.2, 0.03, 14),
				CFrame.new(centerX + side * 10.6, groundY + 0.11, plazaZ),
				STREET_COLORS.Gold,
				Enum.Material.SmoothPlastic
			)
			addBollard(folder, Vector3.new(centerX + side * 10.6, groundY + 0.1, plazaZ - 6.4))
		end
	end
end

-- Grand Society Club: moldura dourada e balizas luminosas na praça do clube.
local function polishClub(folder, world, groundY)
	local club = world:FindFirstChild("GrandSocietyClub")
	local plaza = club and club:FindFirstChild("ClubPlaza")
	if not plaza or not plaza:IsA("BasePart") then
		return
	end

	local top = plaza.Position.Y + plaza.Size.Y / 2
	local sizeX, sizeZ = plaza.Size.X, plaza.Size.Z
	local inset = 1.5
	for _, side in ipairs({ -1, 1 }) do
		lay(
			folder,
			"ClubPlazaGoldFrame",
			Vector3.new(sizeX - inset * 2, 0.03, 0.25),
			CFrame.new(plaza.Position.X, top + 0.015, plaza.Position.Z + side * (sizeZ / 2 - inset)),
			STREET_COLORS.Gold,
			Enum.Material.SmoothPlastic
		)
		lay(
			folder,
			"ClubPlazaGoldFrame",
			Vector3.new(0.25, 0.03, sizeZ - inset * 2),
			CFrame.new(plaza.Position.X + side * (sizeX / 2 - inset), top + 0.015, plaza.Position.Z),
			STREET_COLORS.Gold,
			Enum.Material.SmoothPlastic
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		for z = plaza.Position.Z - sizeZ / 2 + 8, plaza.Position.Z + sizeZ / 2 - 8, 16 do
			addBollard(folder, Vector3.new(plaza.Position.X + side * (sizeX / 2 - 3), top, z))
		end
	end
end

local function polishStreets(world, groundY)
	local existing = world:FindFirstChild(STREETSCAPE_FOLDER)
	if existing then
		if existing:GetAttribute("Version") == STREETSCAPE_VERSION then
			return
		end
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = STREETSCAPE_FOLDER
	folder:SetAttribute("Version", STREETSCAPE_VERSION)

	local boulevard = world:FindFirstChild("HighSocietyBoulevard")
	local steps = {
		function()
			polishMainRoad(folder, boulevard)
		end,
		function()
			polishPromenades(folder, world)
		end,
		function()
			polishCentralPlaza(folder, world)
		end,
		function()
			polishFrontAvenue(folder, world, groundY)
		end,
		function()
			polishGarden(folder, world, groundY)
		end,
		function()
			polishMarina(folder, world, groundY)
		end,
		function()
			polishClub(folder, world, groundY)
		end,
	}
	for index, step in ipairs(steps) do
		local ok, stepError = pcall(step)
		if not ok then
			Logger.Warn("WorldLife", string.format("Acabamento das ruas (etapa %d) falhou: %s", index, tostring(stepError)))
		end
	end

	folder.Parent = world
	Logger.Info("WorldLife", "Ruas, calçadas e praça com acabamento de luxo")
end

local function decorate(world, groundY)
	local folder = world:FindFirstChild(LIFE_FOLDER_NAME)
	if folder then
		return
	end
	folder = Instance.new("Folder")
	folder.Name = LIFE_FOLDER_NAME
	folder.Parent = world

	-- Alameda de árvores ao longo da avenida principal (pula os cruzamentos).
	local crossings = { -150, 12, 178 }
	for x = -200, 200, 20 do
		local nearCrossing = false
		for _, crossingX in ipairs(crossings) do
			if math.abs(x - crossingX) < 14 then
				nearCrossing = true
			end
		end
		if not nearCrossing then
			makeTree(folder, x, groundY, -30, 0.85, false)
		end
	end

	-- Palmeiras na praia e promenade da Paradise Island.
	for _, x in ipairs({ 136, 152, 168, 184, 200, 214 }) do
		makeTree(folder, x, groundY + 0.45, 186, 1.0, true)
	end

	-- Canteiros de flores no Garden Park e na praça do clube.
	local seed = 11
	for _, position in ipairs({
		Vector3.new(-175, groundY + 0.5, 66),
		Vector3.new(-125, groundY + 0.5, 66),
		Vector3.new(-175, groundY + 0.5, 98),
		Vector3.new(-125, groundY + 0.5, 98),
		Vector3.new(-30, groundY + 0.5, 70),
		Vector3.new(54, groundY + 0.5, 70),
		Vector3.new(-30, groundY + 0.5, 120),
		Vector3.new(54, groundY + 0.5, 120),
	}) do
		seed += 1
		makeFlowerBed(folder, position.X, position.Y, position.Z, 10, 5, seed)
	end

	-- Bancos nas calçadas do parque.
	for _, x in ipairs({ -185, -165, -135, -115 }) do
		makeBench(folder, x, groundY + 0.5, 62, 0)
		makeBench(folder, x, groundY + 0.5, 100, math.pi)
	end

	-- Chafariz do Garden Park ganha água.
	local fountainColumn = world:FindFirstChild("FountainColumn", true)
	if fountainColumn and fountainColumn:IsA("BasePart") then
		addFountainSpray(fountainColumn, fountainColumn.Position.Y + fountainColumn.Size.Y / 2)
	end

	-- Chafariz novo na praça do Grand Society Club.
	local plazaFountainBase = makePart(
		folder,
		"PlazaFountainBase",
		Vector3.new(2.4, 14, 14),
		CFrame.new(-8, groundY + 1.2, 135) * CFrame.Angles(0, 0, math.rad(90)),
		COLORS.Stone,
		Enum.Material.Marble
	)
	plazaFountainBase.Shape = Enum.PartType.Cylinder
	local plazaPool = makePart(
		folder,
		"PlazaFountainWater",
		Vector3.new(0.4, 11, 11),
		CFrame.new(-8, groundY + 2.45, 135) * CFrame.Angles(0, 0, math.rad(90)),
		COLORS.Water,
		Enum.Material.Glass,
		0.3,
		false
	)
	plazaPool.Shape = Enum.PartType.Cylinder
	addFountainSpray(plazaPool, groundY + 3)

	-- Outdoors de luxo ao longo da avenida.
	local ids = Config.World and Config.World.BillboardImageIds or {}
	makeBillboard(folder, -100, groundY, -20, 1, ids[1])
	makeBillboard(folder, 120, groundY, -20, 2, ids[2])

	Logger.Info("WorldLife", "Decoração de luxo criada")
end

function WorldLife.Init()
	if initialized then
		return
	end
	initialized = true

	setupSky()

	local world = workspace:FindFirstChild(Config.Map.WorldName)
	if not world then
		Logger.Warn("WorldLife", "Workspace." .. Config.Map.WorldName .. " não existe; decoração ignorada")
		return
	end

	local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
	local groundY = WorldBuilder.GetGroundY()

	decorate(world, groundY)
	polishStreets(world, groundY)
	collectLightTargets(world)
	startNightLoop()
	startNpcs(world, groundY)
end

return WorldLife
