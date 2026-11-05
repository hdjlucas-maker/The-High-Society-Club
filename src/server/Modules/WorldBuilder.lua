local WorldBuilder = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("Logger"))
local propertyCatalog = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("PropertyCatalog"))

local Config = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("Config"))
local LuxuryKit = require(script.Parent:WaitForChild("LuxuryKit"))
local Palette = LuxuryKit.Palette
local WORLD_NAME = Config.Map.WorldName
local WORLD_VERSION = 3

-- Larguras compartilhadas com o WorldLife (acabamento das ruas).
local STREETS = Config.World.Streets or {}
local STREET_VERSION = STREETS.Version or 1
local MAIN_ROAD_WIDTH = STREETS.MainRoadWidth or 36
local MAIN_SIDEWALK_WIDTH = STREETS.MainSidewalkWidth or 10
local PROMENADE_WIDTH = STREETS.PromenadeWidth or 16
local GARDEN_WALK_WIDTH = STREETS.GardenWalkWidth or 12
local ISLAND_PROMENADE_WIDTH = STREETS.IslandPromenadeWidth or 11
local BEACH_PROMENADE_WIDTH = STREETS.BeachPromenadeWidth or 8
local MARINA_PROMENADE_WIDTH = STREETS.MarinaPromenadeWidth or 10
local MAIN_ROAD_Z = -48

local COLORS = {
	Asphalt = Color3.fromRGB(39, 43, 52),
	Line = Color3.fromRGB(235, 205, 132),
	Stone = Color3.fromRGB(207, 204, 194),
	White = Color3.fromRGB(232, 229, 218),
	Glass = Color3.fromRGB(121, 177, 191),
	DeepGlass = Color3.fromRGB(52, 94, 112),
	Gold = Color3.fromRGB(218, 180, 91),
	Green = Color3.fromRGB(77, 117, 78),
	DarkGreen = Color3.fromRGB(43, 79, 58),
	Sand = Color3.fromRGB(218, 194, 146),
	Water = Color3.fromRGB(49, 135, 165),
	Wood = Color3.fromRGB(112, 82, 59),
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
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeSign(parent, name, text, position, width, color, height)
	height = height or 5
	local board = makePart(
		parent,
		name,
		Vector3.new(width, height, 0.7),
		CFrame.new(position),
		Color3.fromRGB(22, 24, 30),
		Enum.Material.SmoothPlastic
	)
	board.CanCollide = false

	local frameColor = color or COLORS.Gold
	LuxuryKit.part(
		parent,
		name .. "FrameTop",
		Vector3.new(width + 0.45, 0.24, 0.9),
		CFrame.new(position.X, position.Y + height / 2, position.Z),
		frameColor,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "FrameBottom",
		Vector3.new(width + 0.45, 0.24, 0.9),
		CFrame.new(position.X, position.Y - height / 2, position.Z),
		frameColor,
		Enum.Material.Metal
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			parent,
			name .. "FrameSide",
			Vector3.new(0.24, height + 0.45, 0.9),
			CFrame.new(position.X + side * width / 2, position.Y, position.Z),
			frameColor,
			Enum.Material.Metal
		)
	end

	local surface = Instance.new("SurfaceGui")
	surface.Name = "SignSurface"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 48
	surface.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.fromScale(0.92, 0.72)
	label.Position = UDim2.fromScale(0.04, 0.1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = frameColor
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = surface

	local accentLine = Instance.new("Frame")
	accentLine.Name = "AccentLine"
	accentLine.AnchorPoint = Vector2.new(0.5, 0.5)
	accentLine.Position = UDim2.fromScale(0.5, 0.82)
	accentLine.Size = UDim2.fromScale(0.55, 0.025)
	accentLine.BackgroundColor3 = frameColor
	accentLine.BorderSizePixel = 0
	accentLine.Parent = surface

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.fromScale(0.92, 0.16)
	subtitle.Position = UDim2.fromScale(0.04, 0.85)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "THE HIGH SOCIETY CLUB"
	subtitle.TextColor3 = Color3.fromRGB(232, 226, 212)
	subtitle.TextScaled = true
	subtitle.TextTransparency = 0.1
	subtitle.Parent = surface

	local glow = Instance.new("SurfaceLight")
	glow.Name = "SignGlow"
	glow.Face = Enum.NormalId.Front
	glow.Color = frameColor
	glow.Range = 18
	glow.Brightness = 0.7
	glow.Parent = board

	return board
end

-- Postes e bases de uma placa de distrito. Separado para que o reparo do
-- mundo existente possa reaproveitar a mesma geometria.
local function addSignPosts(parent, name, position, width, color, height, baseY)
	local boardBottom = position.Y - (height or 5) / 2
	local postHeight = math.max(0.6, boardBottom - baseY)
	local postOffset = math.max(1.5, width / 2 - 1.5)

	for _, side in ipairs({ -1, 1 }) do
		local post = LuxuryKit.part(
			parent,
			name .. "Post",
			Vector3.new(0.45, postHeight, 0.45),
			CFrame.new(position.X + side * postOffset, baseY + postHeight / 2, position.Z),
			color or COLORS.Gold,
			Enum.Material.Metal
		)
		post:SetAttribute("HSC_SignSupport", true)

		LuxuryKit.part(
			parent,
			name .. "PostBase",
			Vector3.new(1.5, 0.35, 1.5),
			CFrame.new(position.X + side * postOffset, baseY + 0.175, position.Z),
			color or COLORS.Gold,
			Enum.Material.Metal
		)
	end
end

-- Placa de distrito com dois postes e bases, apoiada no chão.
-- Evita letreiros flutuando no ar e mantém a face voltada para -Z,
-- que é o lado de chegada do jogador na maioria dos acessos.
local function makeStandingSign(parent, name, text, position, width, color, height, baseY)
	local board = makeSign(parent, name, text, position, width, color, height)
	addSignPosts(parent, name, position, width, color, height, baseY)
	return board
end

local function makeGlassBand(parent, name, cframe, width, height, mullions, frameColor, glassColor)
	local glass = LuxuryKit.part(
		parent,
		name,
		Vector3.new(width, height, 0.14),
		cframe,
		glassColor or Palette.DeepGlass,
		Enum.Material.Glass,
		0.22,
		false
	)
	glass.CastShadow = false

	LuxuryKit.part(
		parent,
		name .. "Top",
		Vector3.new(width + 0.4, 0.24, 0.34),
		cframe * CFrame.new(0, height / 2, -0.08),
		frameColor or Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "Bottom",
		Vector3.new(width + 0.4, 0.24, 0.34),
		cframe * CFrame.new(0, -height / 2, -0.08),
		frameColor or Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "Sill",
		Vector3.new(width + 0.7, 0.2, 0.55),
		cframe * CFrame.new(0, -height / 2 - 0.18, -0.2),
		frameColor or Palette.Gold,
		Enum.Material.Metal
	)
	for index = 1, math.max(0, (mullions or 3) - 1) do
		local x = -width / 2 + (width / (mullions or 3)) * index
		LuxuryKit.part(
			parent,
			name .. "Mullion",
			Vector3.new(0.12, height, 0.2),
			cframe * CFrame.new(x, 0, -0.09),
			frameColor or Palette.Gold,
			Enum.Material.Metal
		)
	end
	return glass
end

local function makeStanchions(parent, name, center, length, color)
	for _, side in ipairs({ -1, 1 }) do
		for index = 0, 1 do
			local z = center.Z - length / 2 + index * length
			local base = Vector3.new(center.X + side * 3.6, center.Y, z)
			LuxuryKit.verticalCylinder(
				parent,
				name .. "Post",
				2.5,
				0.16,
				Vector3.new(base.X, base.Y + 1.25, base.Z),
				Palette.Gold,
				Enum.Material.Metal
			)
			LuxuryKit.ball(
				parent,
				name .. "PostTop",
				Vector3.new(0.35, 0.35, 0.35),
				Vector3.new(base.X, base.Y + 2.55, base.Z),
				Palette.Gold,
				Enum.Material.Metal
			)
		end
		LuxuryKit.part(
			parent,
			name .. "Rope",
			Vector3.new(0.08, 0.08, length),
			CFrame.new(center.X + side * 3.6, center.Y + 2.1, center.Z),
			color or Palette.Burgundy,
			Enum.Material.Fabric,
			0,
			false
		)
	end
end

local function markExteriorOnly(instance)
	instance:SetAttribute("HSC_ExteriorOnly", true)
	return instance
end

local function makeBuilding(parent, name, label, center, width, depth, height, accent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local ground = center.Y
	local trimColor = accent or Palette.Gold
	local wallColor = Palette.WarmWhite
	local frontZ = center.Z - depth / 2
	local backZ = center.Z + depth / 2
	local leftX = center.X - width / 2
	local rightX = center.X + width / 2
	local foundationTop = ground + 1.2
	local coreTop = foundationTop + height
	local roofY = coreTop + 0.6
	local floors = math.max(2, math.floor(height / 9))
	local floorHeight = height / floors

	-- Fundação de mármore, escadaria e faixa dourada.
	local foundation = makePart(
		model,
		"Foundation",
		Vector3.new(width + 7, 1.2, depth + 7),
		CFrame.new(center.X, ground + 0.6, center.Z),
		Palette.Stone,
		Enum.Material.Marble
	)
	foundation:SetAttribute("HSC_Foundation", true)
	-- Degraus do mais distante (baixo) ao mais próximo da fundação (alto).
	-- Assim o jogador sobe 0,30 por degrau até o piso da fundação (1,20).
	for step = 1, 3 do
		local stepWidth = width + 7 + step * 1.1
		local stepDepth = 1.8
		local stepZ = frontZ - 3.5 - (3 - step) * stepDepth - stepDepth / 2
		local stepY = ground + 0.15 + (step - 1) * 0.3
		makePart(
			model,
			"Step",
			Vector3.new(stepWidth, 0.3, stepDepth),
			CFrame.new(center.X, stepY, stepZ),
			Palette.Marble,
			Enum.Material.Marble
		)
	end
	makePart(
		model,
		"FoundationTrim",
		Vector3.new(width + 7.4, 0.16, depth + 7.4),
		CFrame.new(center.X, foundationTop + 0.02, center.Z),
		trimColor,
		Enum.Material.Metal
	)

	-- Volumetria principal, com faixas, cornija e cobertura.
	makePart(
		model,
		"Building",
		Vector3.new(width, height, depth),
		CFrame.new(center.X, foundationTop + height / 2, center.Z),
		wallColor,
		Enum.Material.Concrete
	)
	makePart(
		model,
		"BaseBand",
		Vector3.new(width + 1.2, 1.6, depth + 1.2),
		CFrame.new(center.X, foundationTop + 0.8, center.Z),
		Palette.Cream,
		Enum.Material.Marble
	)
	makePart(
		model,
		"Cornice",
		Vector3.new(width + 2.4, 1.1, depth + 2.4),
		CFrame.new(center.X, coreTop + 0.55, center.Z),
		trimColor,
		Enum.Material.Metal
	)
	makePart(
		model,
		"Roof",
		Vector3.new(width + 1.6, 0.6, depth + 1.6),
		CFrame.new(center.X, coreTop + 0.3, center.Z),
		Palette.Cream,
		Enum.Material.Marble
	)

	for floorIndex = 1, floors - 1 do
		local floorBase = foundationTop + floorIndex * floorHeight
		makePart(
			model,
			"FloorBand",
			Vector3.new(width + 0.8, 0.32, depth + 0.8),
			CFrame.new(center.X, floorBase, center.Z),
			Palette.Cream,
			Enum.Material.Marble
		)
	end

	-- Pilastras e detalhes dourados nas esquinas.
	local pilasterCount = math.max(3, math.floor(width / 12))
	for index = 0, pilasterCount do
		local x = leftX + (width / pilasterCount) * index
		local pilaster = LuxuryKit.part(
			model,
			"Pilaster",
			Vector3.new(0.95, height, 0.8),
			CFrame.new(x, foundationTop + height / 2, frontZ - 0.4),
			Palette.Cream,
			Enum.Material.Marble
		)
		pilaster.CastShadow = true
		LuxuryKit.part(
			model,
			"PilasterCapital",
			Vector3.new(1.45, 0.38, 1.2),
			CFrame.new(x, coreTop - 0.3, frontZ - 0.4),
			trimColor,
			Enum.Material.Metal
		)
		LuxuryKit.part(
			model,
			"PilasterBase",
			Vector3.new(1.45, 0.55, 1.2),
			CFrame.new(x, foundationTop + 0.28, frontZ - 0.4),
			trimColor,
			Enum.Material.Metal
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		for index = 1, 2 do
			local z = center.Z - depth / 2 + (depth / 3) * index
			LuxuryKit.part(
				model,
				"SidePilaster",
				Vector3.new(0.8, height, 0.95),
				CFrame.new(center.X + side * (width / 2 + 0.4), foundationTop + height / 2, z),
				Palette.Cream,
				Enum.Material.Marble
			)
			LuxuryKit.part(
				model,
				"SidePilasterCapital",
				Vector3.new(1.2, 0.38, 1.45),
				CFrame.new(center.X + side * (width / 2 + 0.4), coreTop - 0.3, z),
				trimColor,
				Enum.Material.Metal
			)
		end
		LuxuryKit.part(
			model,
			"CornerGoldStrip",
			Vector3.new(0.3, height, 0.3),
			CFrame.new(center.X + side * (width / 2 + 0.02), foundationTop + height / 2, frontZ - 0.02),
			trimColor,
			Enum.Material.Metal
		)
	end

	-- Vitrines do térreo e janelas dos andares superiores.
	makeGlassBand(
		model,
		"StorefrontGlass",
		CFrame.new(center.X, foundationTop + 3.8, frontZ - 0.12),
		width * 0.82,
		6.6,
		math.max(4, math.floor(width / 10)),
		trimColor,
		Palette.DeepGlass
	)
	makeGlassBand(
		model,
		"StorefrontGlassBack",
		CFrame.new(center.X, foundationTop + 3.8, backZ + 0.12) * CFrame.Angles(0, math.pi, 0),
		width * 0.78,
		6.6,
		math.max(4, math.floor(width / 12)),
		trimColor,
		Palette.DeepGlass
	)
	for _, side in ipairs({ -1, 1 }) do
		makeGlassBand(
			model,
			"SideStorefront",
			CFrame.new(center.X + side * (width / 2 + 0.12), foundationTop + 3.8, center.Z)
				* CFrame.Angles(0, -side * math.pi / 2, 0),
			depth * 0.58,
			6.6,
			3,
			trimColor,
			Palette.DeepGlass
		)
	end
	for floorIndex = 1, floors - 1 do
		local y = foundationTop + floorIndex * floorHeight + floorHeight / 2
		local windowHeight = math.min(6.2, floorHeight * 0.58)
		makeGlassBand(
			model,
			"WindowBand",
			CFrame.new(center.X, y, frontZ - 0.12),
			width * 0.84,
			windowHeight,
			math.max(4, math.floor(width / 10)),
			trimColor,
			Palette.Glass
		)
		makeGlassBand(
			model,
			"WindowBandBack",
			CFrame.new(center.X, y, backZ + 0.12) * CFrame.Angles(0, math.pi, 0),
			width * 0.8,
			windowHeight,
			math.max(3, math.floor(width / 14)),
			trimColor,
			Palette.Glass
		)
	end

	-- Entrada principal: porta de vidro fechada (não há interior), dossel,
	-- colunas, tapete e jardins. A placa avisa que o atendimento é externo.
	local doorCFrame = CFrame.new(center.X, foundationTop + 4.4, frontZ - 0.35)
	LuxuryKit.door(model, "Entrance", doorCFrame, 8, 8.4, trimColor, Palette.DeepGlass, 0.62)
	makePart(
		model,
		"Canopy",
		Vector3.new(width * 0.4, 0.32, 8.5),
		CFrame.new(center.X, foundationTop + 10.1, frontZ - 5),
		Palette.Glass,
		Enum.Material.Glass,
		0.35,
		false
	)
	LuxuryKit.part(
		model,
		"CanopyFrame",
		Vector3.new(width * 0.42, 0.16, 8.7),
		CFrame.new(center.X, foundationTop + 9.95, frontZ - 5),
		trimColor,
		Enum.Material.Metal
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.column(
			model,
			"EntranceColumn",
			Vector3.new(center.X + side * width * 0.16, ground + 5.65, frontZ - 8.6),
			11.3,
			1.1,
			Palette.Marble,
			Enum.Material.Marble,
			trimColor
		)
	end
	LuxuryKit.neon(
		model,
		"EntranceGlow",
		Vector3.new(width * 0.3, 0.08, 0.16),
		CFrame.new(center.X, foundationTop + 9.7, frontZ - 8.8),
		Palette.NeonWarm
	)
	makeSign(
		model,
		"ServiceSign",
		"ATENDIMENTO EXTERNO",
		Vector3.new(center.X, foundationTop + 9.1, frontZ - 9.42),
		math.min(width * 0.5, 14),
		trimColor,
		1.4
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			model,
			"ServiceSignSupport",
			Vector3.new(0.18, 0.35, 0.18),
			CFrame.new(center.X + side * math.min(width * 0.2, 5), foundationTop + 9.85, frontZ - 9.3),
			trimColor,
			Enum.Material.Metal
		)
	end

	local carpet = makePart(
		model,
		"RedCarpet",
		Vector3.new(7, 0.08, 5.5),
		CFrame.new(center.X, foundationTop + 0.04, frontZ - 1.2),
		Palette.Burgundy,
		Enum.Material.Fabric
	)
	carpet.CanCollide = false
	for _, side in ipairs({ -1, 1 }) do
		makePart(
			model,
			"CarpetGoldEdge",
			Vector3.new(0.18, 0.1, 5.5),
			CFrame.new(center.X + side * 3.6, foundationTop + 0.05, frontZ - 1.2),
			trimColor,
			Enum.Material.Metal
		)
	end
	makeStanchions(model, "VelvetRope", Vector3.new(center.X, foundationTop, frontZ - 1.2), 4, Palette.Burgundy)

	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.planter(
			model,
			"EntrancePlanter",
			Vector3.new(center.X + side * width * 0.3, foundationTop, frontZ - 2.0),
			4.6,
			4.6,
			1.2,
			Palette.Stone,
			trimColor
		)
		LuxuryKit.palm(
			model,
			"EntrancePalm",
			Vector3.new(center.X + side * width * 0.4, ground, frontZ - 11),
			0.82,
			"beach"
		)
	end

	-- Placa de fachada e iluminação.
	local signBoard = makeSign(
		model,
		"DistrictSign",
		label,
		Vector3.new(center.X, roofY + 2.4, frontZ - 0.65),
		math.min(width, 40),
		trimColor,
		4.6
	)
	signBoard.CastShadow = true
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			model,
			"SignSupport",
			Vector3.new(0.3, 2.8, 0.3),
			CFrame.new(center.X + side * (math.min(width, 40) / 2 + 1.2), roofY + 0.9, frontZ - 0.45),
			trimColor,
			Enum.Material.Metal
		)
	end

	-- Terraço na cobertura, com parapeito, deck e vegetação.
	for _, side in ipairs({ -1, 1 }) do
		makePart(
			model,
			"Parapet",
			Vector3.new(width + 1.4, 1.1, 0.4),
			CFrame.new(center.X, roofY + 0.55, center.Z + side * (depth / 2 + 0.5)),
			Palette.Cream,
			Enum.Material.Marble
		)
		makePart(
			model,
			"Parapet",
			Vector3.new(0.4, 1.1, depth + 1.4),
			CFrame.new(center.X + side * (width / 2 + 0.5), roofY + 0.55, center.Z),
			Palette.Cream,
			Enum.Material.Marble
		)
		makePart(
			model,
			"ParapetGold",
			Vector3.new(width + 1.5, 0.14, 0.5),
			CFrame.new(center.X, roofY + 1.12, center.Z + side * (depth / 2 + 0.5)),
			trimColor,
			Enum.Material.Metal
		)
	end
	makePart(
		model,
		"RoofDeck",
		Vector3.new(width * 0.82, 0.25, depth * 0.72),
		CFrame.new(center.X, roofY + 0.13, center.Z),
		Palette.Teak,
		Enum.Material.WoodPlanks
	)
	LuxuryKit.glassRailing(
		model,
		"RoofRailing",
		CFrame.new(center.X, roofY + 0.28, frontZ + 0.9),
		width * 0.78,
		1.2,
		trimColor
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.planter(
			model,
			"RoofPlanter",
			Vector3.new(center.X + side * width * 0.3, roofY + 0.26, center.Z + depth * 0.2),
			4.2,
			4.2,
			1,
			Palette.Stone,
			trimColor
		)
	end

	-- Detalhes específicos de cada prédio.
	if name == "LuxuryHotel" then
		local poolCenter = Vector3.new(center.X + width * 0.18, roofY + 0.3, center.Z - depth * 0.08)
		makePart(
			model,
			"RooftopPool",
			Vector3.new(16, 0.5, 8),
			CFrame.new(poolCenter),
			Palette.Aqua,
			Enum.Material.Glass,
			0.25,
			false
		)
		for _, side in ipairs({ -1, 1 }) do
			makePart(
				model,
				"PoolRim",
				Vector3.new(17, 0.35, 0.5),
				CFrame.new(poolCenter.X, poolCenter.Y + 0.2, poolCenter.Z + side * 4.2),
				Palette.Marble,
				Enum.Material.Marble
			)
			makePart(
				model,
				"PoolRim",
				Vector3.new(0.5, 0.35, 8.4),
				CFrame.new(poolCenter.X + side * 8.2, poolCenter.Y + 0.2, poolCenter.Z),
				Palette.Marble,
				Enum.Material.Marble
			)
		end
		LuxuryKit.loungeChair(model, "RoofLounge", CFrame.new(poolCenter.X - 13, roofY + 0.3, poolCenter.Z), Palette.Fabric, trimColor)
		LuxuryKit.loungeChair(model, "RoofLounge", CFrame.new(poolCenter.X - 13, roofY + 0.3, poolCenter.Z + 5), Palette.Fabric, trimColor)
		LuxuryKit.verticalCylinder(
			model,
			"HotelSpire",
			14,
			1.1,
			Vector3.new(center.X - width * 0.3, roofY + 7, center.Z + depth * 0.2),
			trimColor,
			Enum.Material.Metal
		)
		LuxuryKit.neon(
			model,
			"HotelSpireGlow",
			Vector3.new(0.35, 1.2, 0.35),
			CFrame.new(center.X - width * 0.3, roofY + 14.4, center.Z + depth * 0.2),
			Palette.NeonWarm
		)
	elseif name == "SocietyShoppingGallery" then
		LuxuryKit.ball(
			model,
			"GlassDome",
			Vector3.new(18, 18, 18),
			Vector3.new(center.X, roofY + 1.2, center.Z),
			Palette.Glass,
			Enum.Material.Glass,
			0.3,
			false
		)
		LuxuryKit.ball(
			model,
			"DomeFinial",
			Vector3.new(1.4, 1.4, 1.4),
			Vector3.new(center.X, roofY + 10.5, center.Z),
			trimColor,
			Enum.Material.Metal
		)
		for _, side in ipairs({ -1, 1 }) do
			for index = 1, 2 do
				local x = center.X + side * width * 0.22 + (index - 1.5) * 3
				LuxuryKit.verticalCylinder(
					model,
					"MannequinStand",
					2,
					1.1,
					Vector3.new(x, foundationTop + 2.6, frontZ - 1.4),
					Palette.Gold,
					Enum.Material.Metal
				)
				LuxuryKit.ball(
					model,
					"MannequinHead",
					Vector3.new(1.1, 1.1, 1.1),
					Vector3.new(x, foundationTop + 5.4, frontZ - 1.4),
					Palette.Ivory,
					Enum.Material.SmoothPlastic
				)
				LuxuryKit.part(
					model,
					"MannequinBody",
					Vector3.new(2.2, 3.2, 1.1),
					CFrame.new(x, foundationTop + 3.8, frontZ - 1.4),
					index % 2 == 0 and Palette.Burgundy or Palette.Navy,
					Enum.Material.Fabric
				)
			end
		end
	elseif name == "FashionAvenueStore" then
		for _, side in ipairs({ -1, 1 }) do
			LuxuryKit.verticalCylinder(
				model,
				"MannequinStand",
				2,
				1.1,
				Vector3.new(center.X + side * 7, foundationTop + 2.6, frontZ - 1.4),
				Palette.Gold,
				Enum.Material.Metal
			)
			LuxuryKit.ball(
				model,
				"MannequinHead",
				Vector3.new(1.1, 1.1, 1.1),
				Vector3.new(center.X + side * 7, foundationTop + 5.4, frontZ - 1.4),
				Palette.Ivory,
				Enum.Material.SmoothPlastic
			)
			LuxuryKit.part(
				model,
				"MannequinBody",
				Vector3.new(2.2, 3.2, 1.1),
				CFrame.new(center.X + side * 7, foundationTop + 3.8, frontZ - 1.4),
				side < 0 and Palette.Rose or Palette.Burgundy,
				Enum.Material.Fabric
			)
		end
	elseif name == "GrandSocietyClubBuilding" then
		for _, side in ipairs({ -1, 1 }) do
			LuxuryKit.neon(
				model,
				"ClubNeon",
				Vector3.new(0.22, height * 0.7, 0.22),
				CFrame.new(center.X + side * (width / 2 + 0.1), foundationTop + height * 0.42, frontZ - 0.1),
				trimColor
			)
		end
		LuxuryKit.part(
			model,
			"ClubMarquee",
			Vector3.new(width * 0.5, 1.2, 0.6),
			CFrame.new(center.X, foundationTop + 11.5, frontZ - 0.5),
			Palette.Charcoal,
			Enum.Material.SmoothPlastic
		)
		LuxuryKit.neon(
			model,
			"MarqueeGlow",
			Vector3.new(width * 0.48, 0.12, 0.7),
			CFrame.new(center.X, foundationTop + 11.5, frontZ - 0.5),
			trimColor
		)
	elseif name == "ParadiseResort" then
		local poolCenter = Vector3.new(center.X, ground + 0.35, center.Z + depth / 2 + 9)
		makePart(
			model,
			"ResortPool",
			Vector3.new(30, 0.5, 11),
			CFrame.new(poolCenter),
			Palette.Aqua,
			Enum.Material.Glass,
			0.25,
			false
		)
		for _, side in ipairs({ -1, 1 }) do
			makePart(
				model,
				"ResortPoolRim",
				Vector3.new(31, 0.4, 0.6),
				CFrame.new(poolCenter.X, poolCenter.Y + 0.22, poolCenter.Z + side * 5.7),
				Palette.Marble,
				Enum.Material.Marble
			)
			makePart(
				model,
				"ResortPoolRim",
				Vector3.new(0.6, 0.4, 11.4),
				CFrame.new(poolCenter.X + side * 15.2, poolCenter.Y + 0.22, poolCenter.Z),
				Palette.Marble,
				Enum.Material.Marble
			)
		end
		for index = -1, 1 do
			LuxuryKit.loungeChair(
				model,
				"ResortLounge",
				CFrame.new(poolCenter.X + index * 8, ground + 0.35, poolCenter.Z + 8.2),
				Palette.Fabric,
				trimColor
			)
		end
		for index = -1, 1, 2 do
			LuxuryKit.umbrella(
				model,
				"ResortUmbrella",
				Vector3.new(poolCenter.X + index * 10, ground + 0.35, poolCenter.Z + 8.2),
				8,
				4.5,
				Palette.Ivory
			)
		end
		for index = -2, 2 do
			LuxuryKit.palm(
				model,
				"ResortPalm",
				Vector3.new(poolCenter.X + index * 7, ground, poolCenter.Z + 12),
				0.9,
				"beach"
			)
		end
	elseif name == "RoyalMarinaClubhouse" then
		LuxuryKit.verticalCylinder(
			model,
			"MarinaLighthouse",
			12,
			2.4,
			Vector3.new(center.X + width * 0.35, roofY + 6, center.Z + depth * 0.2),
			Palette.Ivory,
			Enum.Material.SmoothPlastic
		)
		LuxuryKit.neon(
			model,
			"MarinaLighthouseGlow",
			Vector3.new(1.4, 1.4, 1.4),
			CFrame.new(center.X + width * 0.35, roofY + 12.2, center.Z + depth * 0.2),
			Palette.NeonWarm
		)
		for _, side in ipairs({ -1, 1 }) do
			LuxuryKit.flag(
				model,
				"MarinaFlag",
				Vector3.new(center.X + side * width * 0.42, foundationTop, frontZ - 2),
				9,
				side < 0 and Palette.Navy or Palette.Burgundy
			)
		end
	end

	-- Paisagismo na base.
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.hedge(
			model,
			"FoundationHedge",
			Vector3.new(center.X + side * (width / 2 + 3.4), ground, center.Z),
			depth * 0.55,
			1.4,
			2.2,
			Palette.Green
		)
	end

	return model
end

local function makeResidence(parent, name, label, propertyId, center, width, depth, accent)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("PropertyId", propertyId)
	model.Parent = parent

	local trimColor = accent or Palette.Gold
	local frontZ = center.Z - depth / 2
	local backZ = center.Z + depth / 2
	local leftX = center.X - width / 2
	local rightX = center.X + width / 2
	local groundY = center.Y
	local foundationTop = groundY + 1.2
	local floorTop = foundationTop + 0.125
	local wallHeight = 9
	local wallY = floorTop + wallHeight / 2
	local ceilingY = floorTop + wallHeight

	-- Grupo externo: removido quando o imóvel é clonado para o interior privado.
	local exterior = Instance.new("Folder")
	exterior.Name = "ExteriorDecor"
	exterior:SetAttribute("HSC_ExteriorOnly", true)
	exterior.Parent = model

	-- Fundação, escadaria e jardins suspensos.
	local foundation = makePart(
		model,
		"Foundation",
		Vector3.new(width + 8, 1.2, depth + 8),
		CFrame.new(center.X, groundY + 0.6, center.Z),
		Palette.Stone,
		Enum.Material.Marble
	)
	foundation:SetAttribute("HSC_Foundation", true)
	makePart(
		model,
		"InteriorFloor",
		Vector3.new(width, 0.35, depth),
		CFrame.new(center.X, center.Y + 1.15, center.Z),
		Palette.Teak,
		Enum.Material.WoodPlanks
	)
	LuxuryKit.part(
		model,
		"FoundationTrim",
		Vector3.new(width + 8.4, 0.18, depth + 8.4),
		CFrame.new(center.X, foundationTop + 0.04, center.Z),
		trimColor,
		Enum.Material.Metal
	)
	-- Degraus alinhados: o mais distante é o mais baixo e o mais próximo
	-- da fundação é o mais alto, sem degrau invertido.
	for step = 1, 3 do
		LuxuryKit.part(
			exterior,
			"EntranceStep",
			Vector3.new(10, 0.3, 1.8),
			CFrame.new(center.X, groundY + 0.15 + (step - 1) * 0.3, frontZ - 4 - (3 - step) * 1.8),
			Palette.Marble,
			Enum.Material.Marble
		)
	end

	-- Volumetria do térreo, em mármore claro com faixas douradas.
	makePart(
		model,
		"BackWall",
		Vector3.new(width, wallHeight, 0.8),
		CFrame.new(center.X, wallY, backZ),
		Palette.WarmWhite,
		Enum.Material.Marble
	)
	local doorwayWidth = 9
	local frontSectionWidth = (width - doorwayWidth) / 2
	for _, side in ipairs({ -1, 1 }) do
		makePart(
			model,
			"FrontWall",
			Vector3.new(frontSectionWidth, wallHeight, 0.8),
			CFrame.new(center.X + side * (doorwayWidth + frontSectionWidth) / 2, wallY, frontZ),
			Palette.WarmWhite,
			Enum.Material.Marble
		)
		makePart(
			model,
			"SideWall",
			Vector3.new(0.8, wallHeight, depth),
			CFrame.new(center.X + side * width / 2, wallY, center.Z),
			Palette.WarmWhite,
			Enum.Material.Marble
		)
		LuxuryKit.windowGrid(
			model,
			"FrontWindow",
			CFrame.new(center.X + side * (doorwayWidth + frontSectionWidth) / 2, floorTop + 4.6, frontZ - 0.42),
			frontSectionWidth * 0.68,
			5.2,
			2,
			2,
			trimColor,
			Palette.DeepGlass
		)
		for index = 1, 2 do
			LuxuryKit.windowGrid(
				model,
				"SideWindow",
				CFrame.new(rightX + 0.42, floorTop + 4.6, center.Z - depth / 4 + (index - 1) * depth / 2)
					* CFrame.Angles(0, -math.pi / 2, 0),
				depth * 0.28,
				5.2,
				2,
				2,
				trimColor,
				Palette.DeepGlass
			)
			LuxuryKit.windowGrid(
				model,
				"SideWindow",
				CFrame.new(leftX - 0.42, floorTop + 4.6, center.Z - depth / 4 + (index - 1) * depth / 2)
					* CFrame.Angles(0, math.pi / 2, 0),
				depth * 0.28,
				5.2,
				2,
				2,
				trimColor,
				Palette.DeepGlass
			)
		end
	end
	makePart(
		model,
		"DoorLintel",
		Vector3.new(doorwayWidth, wallHeight - 7.2, 0.8),
		CFrame.new(center.X, floorTop + 7.2 + (wallHeight - 7.2) / 2, frontZ),
		Palette.WarmWhite,
		Enum.Material.Marble
	)
	makePart(
		model,
		"Roof",
		Vector3.new(width + 2, 0.6, depth + 2),
		CFrame.new(center.X, ceilingY + 0.3, center.Z),
		Palette.Cream,
		Enum.Material.Marble
	)
	makePart(
		model,
		"Cornice",
		Vector3.new(width + 2.8, 0.5, depth + 2.8),
		CFrame.new(center.X, ceilingY - 0.1, center.Z),
		trimColor,
		Enum.Material.Metal
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			model,
			"CornerStrip",
			Vector3.new(0.35, wallHeight, 0.35),
			CFrame.new(center.X + side * (width / 2 + 0.02), wallY, frontZ - 0.02),
			trimColor,
			Enum.Material.Metal
		)
	end

	-- Porta principal, dossel, tapete e colunas de entrada.
	LuxuryKit.door(
		model,
		"Entrance",
		CFrame.new(center.X, floorTop + 3.6, frontZ - 0.35),
		8.4,
		7.2,
		trimColor,
		Palette.DeepGlass
	)
	LuxuryKit.part(
		exterior,
		"Canopy",
		Vector3.new(17, 0.3, 8),
		CFrame.new(center.X, floorTop + 8.2, frontZ - 4.2),
		Palette.Glass,
		Enum.Material.Glass,
		0.35,
		false
	)
	LuxuryKit.part(
		exterior,
		"CanopyFrame",
		Vector3.new(17.3, 0.16, 8.2),
		CFrame.new(center.X, floorTop + 8.02, frontZ - 4.2),
		trimColor,
		Enum.Material.Metal
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.column(
			exterior,
			"EntranceColumn",
			Vector3.new(center.X + side * 7.2, groundY + 4.1, frontZ - 7.4),
			8.2,
			0.9,
			Palette.Marble,
			Enum.Material.Marble,
			trimColor
		)
		LuxuryKit.planter(
			exterior,
			"EntrancePlanter",
			Vector3.new(center.X + side * 11.5, groundY, frontZ - 3.2),
			3.6,
			3.6,
			1,
			Palette.Stone,
			trimColor
		)
		LuxuryKit.palm(
			exterior,
			"EntrancePalm",
			Vector3.new(center.X + side * 14.5, groundY, frontZ - 9),
			0.78,
			"beach"
		)
	end
	local carpet = makePart(
		exterior,
		"RedCarpet",
		Vector3.new(6.4, 0.08, 8.2),
		CFrame.new(center.X, foundationTop + 0.06, frontZ - 4.4),
		Palette.Burgundy,
		Enum.Material.Fabric
	)
	carpet.CanCollide = false
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			exterior,
			"CarpetGoldEdge",
			Vector3.new(0.16, 0.1, 8.2),
			CFrame.new(center.X + side * 3.25, foundationTop + 0.07, frontZ - 4.4),
			trimColor,
			Enum.Material.Metal
		)
	end
	makeStanchions(exterior, "VelvetRope", Vector3.new(center.X, foundationTop, frontZ - 4.4), 6.4, Palette.Burgundy)

	-- Volume superior de vidro, varanda e terraço.
	local upperWidth = width * 0.78
	local upperDepth = depth * 0.62
	local upperCenterZ = center.Z + 4.2
	local upperFrontZ = upperCenterZ - upperDepth / 2
	local upperBaseY = ceilingY + 0.6
	local upperHeight = 7
	local upperCenterY = upperBaseY + upperHeight / 2
	local upperModel = Instance.new("Model")
	upperModel.Name = "UpperSuite"
	upperModel.Parent = exterior

	LuxuryKit.part(
		upperModel,
		"UpperCore",
		Vector3.new(upperWidth, upperHeight, upperDepth),
		CFrame.new(center.X, upperCenterY, upperCenterZ),
		Palette.WarmWhite,
		Enum.Material.Marble
	)
	LuxuryKit.part(
		upperModel,
		"UpperBackWall",
		Vector3.new(upperWidth, upperHeight, 0.6),
		CFrame.new(center.X, upperCenterY, upperCenterZ + upperDepth / 2),
		Palette.WarmWhite,
		Enum.Material.Marble
	)
	makeGlassBand(
		upperModel,
		"UpperGlassFront",
		CFrame.new(center.X, upperCenterY + 0.4, upperFrontZ - 0.42),
		upperWidth * 0.86,
		upperHeight * 0.62,
		5,
		trimColor,
		Palette.Glass
	)
	for _, side in ipairs({ -1, 1 }) do
		makeGlassBand(
			upperModel,
			"UpperGlassSide",
			CFrame.new(center.X + side * (upperWidth / 2 + 0.42), upperCenterY + 0.4, upperCenterZ)
				* CFrame.Angles(0, -side * math.pi / 2, 0),
			upperDepth * 0.72,
			upperHeight * 0.62,
			3,
			trimColor,
			Palette.Glass
		)
	end
	LuxuryKit.part(
		upperModel,
		"UpperRoof",
		Vector3.new(upperWidth + 1.6, 0.55, upperDepth + 1.6),
		CFrame.new(center.X, upperBaseY + upperHeight + 0.28, upperCenterZ),
		Palette.Cream,
		Enum.Material.Marble
	)
	LuxuryKit.part(
		upperModel,
		"UpperRoofTrim",
		Vector3.new(upperWidth + 2, 0.16, upperDepth + 2),
		CFrame.new(center.X, upperBaseY + upperHeight + 0.58, upperCenterZ),
		trimColor,
		Enum.Material.Metal
	)

	local balconyDepth = upperFrontZ - frontZ + 1.2
	LuxuryKit.part(
		upperModel,
		"BalconyDeck",
		Vector3.new(upperWidth + 3, 0.35, balconyDepth),
		CFrame.new(center.X, upperBaseY + 0.17, upperFrontZ - balconyDepth / 2 + 0.6),
		Palette.Teak,
		Enum.Material.WoodPlanks
	)
	LuxuryKit.glassRailing(
		upperModel,
		"BalconyRailing",
		CFrame.new(center.X, upperBaseY + 0.35, frontZ + 0.4),
		upperWidth + 3,
		1.25,
		trimColor
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.glassRailing(
			upperModel,
			"BalconySide",
			CFrame.new(center.X + side * (upperWidth / 2 + 1.5), upperBaseY + 0.35, upperFrontZ - balconyDepth / 2 + 0.6)
				* CFrame.Angles(0, math.pi / 2, 0),
			balconyDepth,
			1.25,
			trimColor
		)
		LuxuryKit.loungeChair(
			upperModel,
			"BalconyLounge",
			CFrame.new(center.X + side * upperWidth * 0.28, upperBaseY + 0.35, upperFrontZ - 1.6),
			Palette.Fabric,
			trimColor
		)
		LuxuryKit.planter(
			upperModel,
			"BalconyPlanter",
			Vector3.new(center.X + side * (upperWidth / 2 - 1), upperBaseY + 0.35, upperFrontZ - 0.8),
			2.6,
			2.6,
			0.8,
			Palette.Stone,
			trimColor
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.verticalCylinder(
			upperModel,
			"BalconyColumn",
			0.6,
			0.5,
			Vector3.new(center.X + side * (upperWidth / 2 + 1.2), upperBaseY + 0.7, frontZ + 0.4),
			trimColor,
			Enum.Material.Metal
		)
	end

	-- Piscina de borda infinita, deck e área de descanso.
	local poolCenter = Vector3.new(rightX + 11, groundY + 0.3, center.Z + 2)
	LuxuryKit.part(
		exterior,
		"PoolDeck",
		Vector3.new(20, 0.3, 24),
		CFrame.new(poolCenter.X, groundY + 0.15, poolCenter.Z),
		Palette.Stone,
		Enum.Material.Marble
	)
	LuxuryKit.part(
		exterior,
		"InfinityPool",
		Vector3.new(14, 0.5, 16),
		CFrame.new(poolCenter.X, groundY + 0.32, poolCenter.Z),
		Palette.Aqua,
		Enum.Material.Glass,
		0.28,
		false
	)
	LuxuryKit.part(
		exterior,
		"InfinityEdge",
		Vector3.new(0.4, 0.22, 16.4),
		CFrame.new(poolCenter.X + 7.1, groundY + 0.55, poolCenter.Z),
		trimColor,
		Enum.Material.Metal
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			exterior,
			"PoolRim",
			Vector3.new(14.4, 0.22, 0.5),
			CFrame.new(poolCenter.X, groundY + 0.55, poolCenter.Z + side * 8.1),
			Palette.Marble,
			Enum.Material.Marble
		)
		LuxuryKit.part(
			exterior,
			"PoolRim",
			Vector3.new(0.5, 0.22, 16.4),
			CFrame.new(poolCenter.X + side * 7.1, groundY + 0.55, poolCenter.Z),
			Palette.Marble,
			Enum.Material.Marble
		)
	end
	for index = -1, 1 do
		LuxuryKit.loungeChair(
			exterior,
			"PoolLounge",
			CFrame.new(poolCenter.X + index * 4.6, groundY + 0.3, poolCenter.Z + 11),
			Palette.Fabric,
			trimColor
		)
	end
	LuxuryKit.umbrella(
		exterior,
		"PoolUmbrella",
		Vector3.new(poolCenter.X, groundY + 0.3, poolCenter.Z + 12.5),
		7,
		4.2,
		Palette.Ivory
	)
	LuxuryKit.palm(exterior, "PoolPalm", Vector3.new(poolCenter.X + 9, groundY, poolCenter.Z + 10), 0.85, "beach")
	LuxuryKit.palm(exterior, "PoolPalm", Vector3.new(poolCenter.X + 9, groundY, poolCenter.Z - 10), 0.8, "beach")
	LuxuryKit.hedge(
		exterior,
		"PoolHedge",
		Vector3.new(poolCenter.X, groundY, poolCenter.Z + 13.4),
		18,
		1.2,
		1.4,
		Palette.Green
	)

	-- Jardim do outro lado e paisagismo frontal.
	LuxuryKit.hedge(
		exterior,
		"GardenHedge",
		Vector3.new(leftX - 8, groundY, center.Z + 2),
		4,
		1.4,
		18,
		Palette.Green
	)
	LuxuryKit.tree(exterior, "GardenTree", Vector3.new(leftX - 8, groundY, center.Z + 2), 0.9, "flowering")
	LuxuryKit.bench(
		exterior,
		"GardenBench",
		CFrame.new(leftX - 5.5, groundY + 0.1, center.Z - 4) * CFrame.Angles(0, math.pi / 2, 0),
		Palette.Teak,
		trimColor
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.hedge(
			exterior,
			"FrontHedge",
			Vector3.new(center.X + side * (width / 2 + 4.2), groundY, frontZ + 2),
			4.2,
			1.1,
			3.2,
			Palette.Green
		)
	end

	-- Placa da residência.
	makeSign(
		exterior,
		"ResidenceSign",
		label,
		Vector3.new(center.X, upperBaseY + upperHeight + 2.6, frontZ - 0.7),
		math.min(width, 36),
		trimColor,
		3.6
	)

	-- Ponto de compra: pedestal de mármore com moldura dourada.
	local purchasePoint = makePart(
		model,
		"PropertyPurchasePoint",
		Vector3.new(3.2, 1.4, 3.2),
		CFrame.new(center.X, foundationTop + 0.7, frontZ - 8.5),
		Palette.Marble,
		Enum.Material.Marble
	)
	purchasePoint:SetAttribute("PropertyId", propertyId)
	purchasePoint.CanCollide = false
	LuxuryKit.part(
		exterior,
		"PurchaseGoldRing",
		Vector3.new(3.6, 0.12, 3.6),
		CFrame.new(center.X, foundationTop + 1.45, frontZ - 8.5),
		trimColor,
		Enum.Material.Metal
	)
	LuxuryKit.neon(
		exterior,
		"PurchaseGlow",
		Vector3.new(0.18, 2.2, 0.18),
		CFrame.new(center.X, foundationTop + 2.6, frontZ - 8.5),
		Palette.NeonWarm
	)

	-- Ponto de retorno, discreto, dentro da residência.
	local spawnPoint = makePart(
		model,
		"SpawnPoint",
		Vector3.new(2, 0.2, 2),
		CFrame.new(center.X, floorTop + 0.1, center.Z - 2),
		trimColor,
		Enum.Material.SmoothPlastic,
		1,
		false
	)
	spawnPoint.CastShadow = false
	local exitPrompt = Instance.new("ProximityPrompt")
	exitPrompt.Name = "PropertyExitPrompt"
	exitPrompt.ActionText = "Sair"
	exitPrompt.ObjectText = "Voltar para a cidade"
	exitPrompt.MaxActivationDistance = 10
	exitPrompt.HoldDuration = 0
	exitPrompt.RequiresLineOfSight = false
	exitPrompt.Parent = spawnPoint

	-- Interiores: suíte, sala, cozinha, jantar e iluminação.
	LuxuryKit.part(
		model,
		"LivingRug",
		Vector3.new(14, 0.06, 10),
		CFrame.new(center.X - width * 0.22, floorTop + 0.04, center.Z - 3.2),
		Palette.Cream,
		Enum.Material.Fabric,
		0,
		false
	)
	local bed = makePart(
		model,
		"LuxuryBed",
		Vector3.new(8.4, 1.3, 6.4),
		CFrame.new(center.X + width * 0.24, floorTop + 0.65, center.Z + depth * 0.2),
		Palette.Ivory,
		Enum.Material.Fabric
	)
	bed.CanCollide = true
	makePart(
		model,
		"Headboard",
		Vector3.new(8.8, 3.4, 0.5),
		CFrame.new(center.X + width * 0.24, floorTop + 2, backZ - 1.1),
		trimColor,
		Enum.Material.Wood
	)
	LuxuryKit.part(
		model,
		"BedRunner",
		Vector3.new(8.2, 0.12, 1.4),
		CFrame.new(center.X + width * 0.24, floorTop + 1.36, center.Z + depth * 0.2 - 2.2),
		Palette.Burgundy,
		Enum.Material.Fabric
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			model,
			"BedsideTable",
			Vector3.new(1.8, 1.5, 1.8),
			CFrame.new(center.X + width * 0.24 + side * 5.4, floorTop + 0.75, center.Z + depth * 0.2 + 2.2),
			Palette.Teak,
			Enum.Material.Wood
		)
		local lamp = LuxuryKit.part(
			model,
			"BedsideLamp",
			Vector3.new(0.9, 1.1, 0.9),
			CFrame.new(center.X + width * 0.24 + side * 5.4, floorTop + 1.9, center.Z + depth * 0.2 + 2.2),
			Palette.NeonWarm,
			Enum.Material.Neon,
			0,
			false
		)
		LuxuryKit.pointLight(lamp, "LampLight", Palette.NeonWarm, 14, 0.9)
	end

	makePart(
		model,
		"LoungeSofa",
		Vector3.new(8.6, 1.6, 3.4),
		CFrame.new(center.X - width * 0.24, floorTop + 0.8, center.Z - 4.2),
		Palette.Navy,
		Enum.Material.Fabric
	)
	LuxuryKit.part(
		model,
		"SofaBack",
		Vector3.new(8.6, 1.6, 0.6),
		CFrame.new(center.X - width * 0.24, floorTop + 1.55, center.Z - 5.6),
		Palette.Navy,
		Enum.Material.Fabric
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			model,
			"SofaArm",
			Vector3.new(0.6, 1.1, 3.2),
			CFrame.new(center.X - width * 0.24 + side * 4, floorTop + 1.15, center.Z - 4.2),
			Palette.Navy,
			Enum.Material.Fabric
		)
	end
	LuxuryKit.part(
		model,
		"LoungeTable",
		Vector3.new(5, 0.5, 3),
		CFrame.new(center.X - width * 0.24, floorTop + 0.75, center.Z - 1.4),
		Palette.Marble,
		Enum.Material.Marble
	)
	for _, x in ipairs({ -2, 2 }) do
		for _, z in ipairs({ -1, 1 }) do
			LuxuryKit.verticalCylinder(
				model,
				"TableLeg",
				0.7,
				0.16,
				Vector3.new(center.X - width * 0.24 + x, floorTop + 0.35, center.Z - 1.4 + z),
				trimColor,
				Enum.Material.Metal
			)
		end
	end

	LuxuryKit.part(
		model,
		"KitchenIsland",
		Vector3.new(7.4, 1.1, 3.2),
		CFrame.new(center.X + width * 0.26, floorTop + 0.55, center.Z - depth * 0.24),
		Palette.Charcoal,
		Enum.Material.SmoothPlastic
	)
	LuxuryKit.part(
		model,
		"KitchenTop",
		Vector3.new(7.8, 0.18, 3.6),
		CFrame.new(center.X + width * 0.26, floorTop + 1.18, center.Z - depth * 0.24),
		Palette.Marble,
		Enum.Material.Marble
	)
	for index = -1, 1 do
		LuxuryKit.verticalCylinder(
			model,
			"BarStool",
			1.4,
			0.7,
			Vector3.new(center.X + width * 0.26 + index * 2.2, floorTop + 0.7, center.Z - depth * 0.24 - 2.6),
			Palette.Burgundy,
			Enum.Material.Fabric
		)
	end

	local diningTable = LuxuryKit.verticalCylinder(
		model,
		"DiningTable",
		0.35,
		5,
		Vector3.new(center.X - width * 0.26, floorTop + 1.25, center.Z + depth * 0.22),
		Palette.Marble,
		Enum.Material.Marble
	)
	diningTable.CanCollide = true
	LuxuryKit.verticalCylinder(
		model,
		"DiningBase",
		1.2,
		1.1,
		Vector3.new(center.X - width * 0.26, floorTop + 0.6, center.Z + depth * 0.22),
		trimColor,
		Enum.Material.Metal
	)
	for index = 0, 3 do
		local angle = math.rad(index * 90)
		LuxuryKit.part(
			model,
			"DiningChair",
			Vector3.new(1.6, 1.8, 1.6),
			CFrame.new(center.X - width * 0.26 + math.cos(angle) * 3.6, floorTop + 0.9, center.Z + depth * 0.22 + math.sin(angle) * 3.6)
				* CFrame.Angles(0, -angle, 0),
			Palette.Teak,
			Enum.Material.Wood
		)
	end

	for _, side in ipairs({ -1, 1 }) do
		local plant = LuxuryKit.part(
			model,
			"InteriorPlant",
			Vector3.new(2, 2.6, 2),
			CFrame.new(center.X + side * (width / 2 - 2.2), floorTop + 1.3, backZ - 2.2),
			Palette.Leaf,
			Enum.Material.LeafyGrass
		)
		plant.Shape = Enum.PartType.Ball
		plant.CanCollide = false
	end

	local ceilingLight = makePart(
		model,
		"CeilingLight",
		Vector3.new(4, 0.25, 4),
		CFrame.new(center.X, ceilingY - 0.25, center.Z),
		Palette.NeonWarm,
		Enum.Material.Neon,
		0,
		false
	)
	local pointLight = Instance.new("PointLight")
	pointLight.Name = "InteriorLight"
	pointLight.Color = Color3.fromRGB(255, 225, 175)
	pointLight.Range = 34
	pointLight.Brightness = 1.8
	pointLight.Shadows = true
	pointLight.Parent = ceilingLight

	local chandelier = LuxuryKit.part(
		model,
		"Chandelier",
		Vector3.new(2.6, 0.35, 2.6),
		CFrame.new(center.X, floorTop + 7.1, center.Z - 1),
		trimColor,
		Enum.Material.Metal
	)
	for index = 0, 7 do
		local angle = math.rad(index * 45)
		LuxuryKit.ball(
			model,
			"ChandelierLight",
			Vector3.new(0.5, 0.5, 0.5),
			Vector3.new(
				chandelier.Position.X + math.cos(angle) * 1.2,
				chandelier.Position.Y - 0.55,
				chandelier.Position.Z + math.sin(angle) * 1.2
			),
			Palette.NeonWarm,
			Enum.Material.Neon
		)
	end
	LuxuryKit.pointLight(chandelier, "ChandelierGlow", Palette.NeonWarm, 22, 1.1)

	for _, descendant in ipairs(exterior:GetDescendants()) do
		descendant:SetAttribute("HSC_ExteriorOnly", true)
	end

	return model
end

local function makeTree(parent, name, x, groundY, z, scale)
	return LuxuryKit.tree(parent, name, Vector3.new(x, groundY, z), scale)
end

local function makePalm(parent, name, x, groundY, z, scale, variant)
	return LuxuryKit.palm(parent, name, Vector3.new(x, groundY, z), scale, variant)
end

local function makeDistrictPath(parent, name, groundY, startX, startZ, endX, endZ, width)
	local midpoint = Vector3.new((startX + endX) / 2, groundY + 0.15, (startZ + endZ) / 2)
	local deltaX = endX - startX
	local deltaZ = endZ - startZ
	local length = math.sqrt(deltaX * deltaX + deltaZ * deltaZ)
	local yaw = math.atan2(deltaZ, deltaX)

	return makePart(
		parent,
		name,
		Vector3.new(length, 0.3, width),
		CFrame.new(midpoint) * CFrame.Angles(0, -yaw, 0),
		COLORS.Stone,
		Enum.Material.Concrete
	)
end

local function makeWorkPoint(parent, name, actionText, objectText, position)
	local point = makePart(parent, name, Vector3.new(4, 3, 4), CFrame.new(position), COLORS.Gold, Enum.Material.Metal)
	point:SetAttribute("InteractionPoint", true)
	-- Marcador de interação não deve bloquear a passagem do jogador.
	point.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorkPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = point

	return point
end

local function makeShopPoint(parent, position)
	local point = makePart(
		parent,
		"ShopPoint",
		Vector3.new(4, 3, 4),
		CFrame.new(position),
		Color3.fromRGB(190, 139, 173),
		Enum.Material.Metal
	)
	point:SetAttribute("InteractionPoint", true)
	point:SetAttribute("ShopId", "fashion_avenue")
	point:SetAttribute("ShopName", "Fashion Avenue")
	-- O balcão de atendimento é um marcador: não bloqueia a escadaria.
	point.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Abrir loja"
	prompt.ObjectText = "Fashion Avenue"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = point

	return point
end

local function ensureVehiclePoint(world, name, actionText, objectText, position)
	local point = workspace:FindFirstChild(name)
	if not point then
		point = world:FindFirstChild(name, true)
	end
	if not point then
		point = makePart(
			world,
			name,
			Vector3.new(4, 2, 4),
			CFrame.new(position),
			COLORS.Gold,
			Enum.Material.Metal,
			0.35,
			false
		)
		point.CanTouch = true
	end

	if not point:IsA("BasePart") then
		error(string.format("%s precisa ser uma BasePart", point:GetFullName()))
	end

	point:SetAttribute("InteractionPoint", true)
	-- Também corrige pontos antigos que foram salvos como blocos sólidos.
	point.CanCollide = false
	local promptNames = {
		DealershipPurchasePoint = "PurchasePrompt",
		GaragePoint = "GaragePrompt",
		VehicleSpawnPoint = "SpawnVehiclePrompt",
		BoatPurchasePoint = "BoatPurchasePrompt",
		BoatStorePoint = "BoatStorePrompt",
	}
	local promptName = promptNames[name]
	if not promptName then
		error(string.format("Ponto de veículo sem prompt configurado: %s", name))
	end
	local prompt = point:FindFirstChild(promptName)
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = promptName
		prompt.Parent = point
	elseif not prompt:IsA("ProximityPrompt") then
		error(string.format("%s.%s precisa ser um ProximityPrompt", point:GetFullName(), promptName))
	end

	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	return point
end

local function ensureVehiclePoints(world, groundY)
	ensureVehiclePoint(
		world,
		"DealershipPurchasePoint",
		"Ver veículos",
		"Automotive Gallery",
		Vector3.new(93, groundY + 2, -132)
	)
	ensureVehiclePoint(world, "GaragePoint", "Abrir garagem", "Garagem do clube", Vector3.new(126, groundY + 2, -112))
	ensureVehiclePoint(
		world,
		"VehicleSpawnPoint",
		"Retirar veículo",
		"Ponto de saída",
		Vector3.new(138, groundY + 1, -112)
	)
	ensureVehiclePoint(world, "BoatPurchasePoint", "Ver lanchas", "Royal Marina", Vector3.new(204, groundY + 2, 202))
	ensureVehiclePoint(world, "BoatStorePoint", "Guardar lancha", "Royal Marina", Vector3.new(204, groundY + 2, 230))

	local spawnPoint = world:FindFirstChild("BoatSpawnPoint", true)
	if not spawnPoint then
		spawnPoint = makePart(
			world,
			"BoatSpawnPoint",
			Vector3.new(2, 0.2, 2),
			CFrame.new(187, groundY + 0.28, 218),
			COLORS.Water,
			Enum.Material.Glass,
			1,
			false
		)
		spawnPoint.CastShadow = false
	elseif not spawnPoint:IsA("BasePart") then
		error("Workspace.HighSocietyWorld.BoatSpawnPoint precisa ser uma BasePart")
	end

	local marina = world:FindFirstChild("ParadiseIslandAndRoyalMarina")
	local water = marina and marina:FindFirstChild("MarinaWater")
	if water and water:IsA("BasePart") then
		water:SetAttribute("HSCWaterSurface", true)
	end
end

local function makeEventPoint(parent, name, eventName, position)
	local point = makePart(parent, name, Vector3.new(4, 2, 4), CFrame.new(position), COLORS.Gold, Enum.Material.Neon)
	point:SetAttribute("EventId", name)
	point.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EventPrompt"
	prompt.ActionText = "Participar"
	prompt.ObjectText = eventName
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = point

	local light = Instance.new("PointLight")
	light.Name = "EventGlow"
	light.Color = COLORS.Gold
	light.Range = 14
	light.Brightness = 0.8
	light.Parent = point

	return point
end

local function buildCentralPlaza(parent, groundY)
	local existing = parent:FindFirstChild("CentralPlaza")
	if existing then
		return existing
	end

	local plaza = Instance.new("Folder")
	plaza.Name = "CentralPlaza"
	plaza.Parent = parent

	local plazaY = groundY + 0.5
	local center = Vector3.new(0, plazaY, -10)
	local base = makePart(
		plaza,
		"PlazaBase",
		Vector3.new(76, 0.5, 50),
		CFrame.new(center),
		Palette.Marble,
		Enum.Material.Marble
	)
	base:SetAttribute("HSC_Plaza", true)

	for _, offset in ipairs({ -37.5, 37.5 }) do
		LuxuryKit.part(
			plaza,
			"PlazaGoldBorder",
			Vector3.new(0.5, 0.06, 50),
			CFrame.new(center.X + offset, plazaY + 0.28, center.Z),
			Palette.Gold,
			Enum.Material.Metal
		)
	end
	for _, offset in ipairs({ -24.5, 24.5 }) do
		LuxuryKit.part(
			plaza,
			"PlazaGoldBorder",
			Vector3.new(76, 0.06, 0.5),
			CFrame.new(center.X, plazaY + 0.28, center.Z + offset),
			Palette.Gold,
			Enum.Material.Metal
		)
	end

	-- Tapete central e passadeira dourada.
	local carpet = makePart(
		plaza,
		"PlazaCarpet",
		Vector3.new(6.5, 0.08, 19),
		CFrame.new(center.X, plazaY + 0.3, center.Z + 14.5),
		Palette.Burgundy,
		Enum.Material.Fabric,
		0,
		false
	)
	carpet.CastShadow = false
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			plaza,
			"CarpetGoldEdge",
			Vector3.new(0.16, 0.09, 19),
			CFrame.new(center.X + side * 3.3, plazaY + 0.31, center.Z + 14.5),
			Palette.Gold,
			Enum.Material.Metal
		)
	end

	-- Fonte monumental ao norte da praça.
	LuxuryKit.verticalCylinder(
		plaza,
		"FountainGoldRing",
		0.1,
		16.5,
		Vector3.new(center.X, plazaY + 0.3, center.Z - 4),
		Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.fountain(plaza, "PlazaFountain", Vector3.new(center.X, plazaY + 0.3, center.Z - 4), 7, Palette.Gold)

	-- Palmeiras, canteiros e bancos.
	for _, x in ipairs({ -27, 27 }) do
		for _, z in ipairs({ -22, 8 }) do
			LuxuryKit.palm(plaza, "PlazaPalm", Vector3.new(center.X + x, plazaY, center.Z + z), 0.95, "beach")
		end
		LuxuryKit.planter(
			plaza,
			"PlazaPlanter",
			Vector3.new(center.X + x, plazaY, center.Z - 2),
			3.2,
			9,
			1.1,
			Palette.Stone,
			Palette.Gold
		)
	end
	for _, x in ipairs({ -13, 13 }) do
		LuxuryKit.bench(
			plaza,
			"PlazaBench",
			CFrame.new(center.X + x, plazaY + 0.28, center.Z + 12),
			Palette.Teak,
			Palette.Gold
		)
	end
	for _, position in ipairs({
		Vector3.new(-19, plazaY, 10),
		Vector3.new(19, plazaY, 10),
		Vector3.new(-19, plazaY, -30),
		Vector3.new(19, plazaY, -30),
		Vector3.new(-35, plazaY, -4),
		Vector3.new(35, plazaY, -4),
	}) do
		LuxuryKit.streetLamp(plaza, "PlazaLamp", position, 9.5, Palette.Charcoal)
	end
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.flag(
			plaza,
			"PlazaFlag",
			Vector3.new(center.X + side * 34, plazaY, center.Z + 21),
			10,
			side < 0 and Palette.Navy or Palette.Burgundy
		)
		LuxuryKit.hedge(
			plaza,
			"PlazaHedge",
			Vector3.new(center.X + side * 28, plazaY, center.Z + 24),
			14,
			1.1,
			1.4,
			Palette.Green
		)
	end

	-- Arco de boas-vindas na entrada sul da praça.
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.column(
			plaza,
			"WelcomeColumn",
			Vector3.new(center.X + side * 14, plazaY + 5.6, center.Z + 24.2),
			10.6,
			1.1,
			Palette.Marble,
			Enum.Material.Marble,
			Palette.Gold
		)
		LuxuryKit.ball(
			plaza,
			"WelcomeFinial",
			Vector3.new(1.1, 1.1, 1.1),
			Vector3.new(center.X + side * 14, plazaY + 11.2, center.Z + 24.2),
			Palette.Gold,
			Enum.Material.Metal
		)
	end
	LuxuryKit.part(
		plaza,
		"WelcomeBeam",
		Vector3.new(32, 0.7, 1.2),
		CFrame.new(center.X, plazaY + 10.7, center.Z + 24.2),
		Palette.Gold,
		Enum.Material.Metal
	)
	makeSign(
		plaza,
		"WelcomeSign",
		"THE HIGH SOCIETY CLUB",
		Vector3.new(center.X, plazaY + 13.2, center.Z + 24.2),
		25,
		Palette.Gold,
		4.4
	)

	return plaza
end

local function ensureCentralPlaza(parent, groundY)
	local ok, plazaError = pcall(buildCentralPlaza, parent, groundY)
	if not ok then
		Logger.Warn("WorldBuilder", "Falha ao criar a praça central: " .. tostring(plazaError))
	end
end

local function ensureSpawn(parent, groundY)
	-- Procura primeiro o spawn criado pelo jogo (HSC_Spawn) e depois um
	-- SpawnLocation direto no Workspace. O primeiro é o ponto seguro conhecido.
	local existingSpawn = parent:FindFirstChild("HSC_Spawn", true)
	if not existingSpawn then
		existingSpawn = workspace:FindFirstChildOfClass("SpawnLocation")
	end

	-- A praça normalmente já foi criada por ensureCentralPlaza. Aqui ela é
	-- apenas localizada, sem recriar nada; se faltar, tenta criar com pcall.
	local plaza = parent:FindFirstChild("CentralPlaza")
	if not plaza then
		ensureCentralPlaza(parent, groundY)
		plaza = parent:FindFirstChild("CentralPlaza")
	end

	local plazaBase = plaza and plaza:FindFirstChild("PlazaBase")
	local plazaTop = plazaBase and plazaBase.Position.Y + plazaBase.Size.Y / 2 or groundY + 0.75

	if existingSpawn and existingSpawn:IsA("BasePart") then
		existingSpawn:SetAttribute("HSC_SafeSpawn", true)
		-- Se o spawn antigo está dentro da área da praça, alinha o topo ao piso.
		-- Isso corrige o caso de o jogador nascer dentro/sobre a base da praça.
		if plazaBase and plazaBase:IsA("BasePart") then
			local localPoint = plazaBase.CFrame:PointToObjectSpace(existingSpawn.Position)
			local insidePlaza = math.abs(localPoint.X) <= plazaBase.Size.X / 2
				and math.abs(localPoint.Z) <= plazaBase.Size.Z / 2
			if insidePlaza then
				local desiredY = plazaTop + 0.05 - existingSpawn.Size.Y / 2
				if math.abs(existingSpawn.Position.Y - desiredY) > 0.05 then
					existingSpawn.CFrame = CFrame.new(existingSpawn.Position.X, desiredY, existingSpawn.Position.Z)
				end
			end
		end
		return existingSpawn
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HSC_Spawn"
	spawn.Size = Vector3.new(10, 0.5, 10)
	-- O topo do spawn fica 0,05 acima do piso da praça: o avatar nasce em pé,
	-- sem cair de uma altura artificial.
	spawn.CFrame = CFrame.new(0, plazaTop + 0.05 - spawn.Size.Y / 2, 6)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 0.65
	spawn.Color = Palette.Gold
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.AllowTeamChangeOnTouch = false
	spawn:SetAttribute("HSC_SafeSpawn", true)
	spawn.Parent = plaza or parent
	return spawn
end

local function buildBoulevard(parent, groundY)
	local district = Instance.new("Folder")
	district.Name = "HighSocietyBoulevard"
	district.Parent = parent

	makeDistrictPath(district, "MainRoad", groundY, -220, MAIN_ROAD_Z, 220, MAIN_ROAD_Z, MAIN_ROAD_WIDTH)

	-- Calçadas largas, guias douradas e canteiro central.
	for _, side in ipairs({ -1, 1 }) do
		local sidewalkZ = MAIN_ROAD_Z + side * (MAIN_ROAD_WIDTH / 2 + MAIN_SIDEWALK_WIDTH / 2)
		LuxuryKit.part(
			district,
			"BoulevardSidewalk",
			Vector3.new(444, 0.3, MAIN_SIDEWALK_WIDTH),
			CFrame.new(0, groundY + 0.15, sidewalkZ),
			Palette.Stone,
			Enum.Material.Concrete
		)
		LuxuryKit.part(
			district,
			"SidewalkGoldCurb",
			Vector3.new(444, 0.12, 0.35),
			CFrame.new(0, groundY + 0.3, MAIN_ROAD_Z + side * (MAIN_ROAD_WIDTH / 2 - 0.3)),
			Palette.Gold,
			Enum.Material.Metal
		)
	end
	for index, x in ipairs({ -180, -120, -60, 0, 60, 120, 180 }) do
		LuxuryKit.part(
			district,
			"MedianIsland",
			Vector3.new(18, 0.35, 3.2),
			CFrame.new(x, groundY + 0.18, -48),
			Palette.Cream,
			Enum.Material.Marble
		)
		LuxuryKit.part(
			district,
			"MedianGoldCap",
			Vector3.new(18.4, 0.1, 3.6),
			CFrame.new(x, groundY + 0.36, -48),
			Palette.Gold,
			Enum.Material.Metal
		)
		LuxuryKit.hedge(
			district,
			"MedianHedge",
			Vector3.new(x, groundY + 0.36, -48),
			12,
			1.1,
			1.8,
			Palette.Green
		)
		if index % 2 == 1 then
			LuxuryKit.palm(
				district,
				"BoulevardPalm",
				Vector3.new(x + 9, groundY + 0.4, -48),
				0.82,
				"beach"
			)
		end
		for _, side in ipairs({ -1, 1 }) do
			local lampZ = MAIN_ROAD_Z + side * (MAIN_ROAD_WIDTH / 2 + MAIN_SIDEWALK_WIDTH - 1.2)
			LuxuryKit.streetLamp(
				district,
				"BoulevardLamp",
				Vector3.new(x + 22, groundY + 0.4, lampZ),
				10,
				Palette.Charcoal
			)
		end
	end
	for _, x in ipairs({ -140, -40, 60, 160 }) do
		LuxuryKit.bench(
			district,
			"BoulevardBench",
			CFrame.new(x, groundY + 0.35, MAIN_ROAD_Z - (MAIN_ROAD_WIDTH / 2 + 3.5))
				* CFrame.Angles(0, math.pi, 0),
			Palette.Teak,
			Palette.Gold
		)
	end
	for _, x in ipairs({ -200, -100, 0, 100, 200 }) do
		makeTree(district, "BoulevardTree", x, groundY + 0.4, -28, 0.85)
	end

	makeBuilding(
		district,
		"SocietyShoppingGallery",
		"HIGH SOCIETY GALLERY",
		Vector3.new(-150, groundY, -112),
		48,
		30,
		22,
		COLORS.Gold
	)
	local fashionStore = makeBuilding(
		district,
		"FashionAvenueStore",
		"FASHION AVENUE",
		Vector3.new(-68, groundY, -112),
		42,
		28,
		20,
		Color3.fromRGB(190, 139, 173)
	)
	makeShopPoint(fashionStore, Vector3.new(-68, groundY + 2, -130))
	makeBuilding(
		district,
		"AutomotiveGallery",
		"AUTOMOTIVE GALLERY",
		Vector3.new(93, groundY, -112),
		48,
		32,
		22,
		Color3.fromRGB(119, 177, 193)
	)
	makeBuilding(district, "LuxuryHotel", "LUXURY HOTEL", Vector3.new(178, groundY, -112), 44, 32, 48, COLORS.Gold)
end

local function buildGardenAndClub(parent, groundY)
	local garden = Instance.new("Folder")
	garden.Name = "GardenPark"
	garden.Parent = parent

	makePart(
		garden,
		"GardenLawn",
		Vector3.new(112, 0.5, 86),
		CFrame.new(-150, groundY + 0.25, 82),
		COLORS.Green,
		Enum.Material.Grass
	)

	makeDistrictPath(garden, "GardenWalkNorth", groundY + 0.5, -194, 58, -106, 58, GARDEN_WALK_WIDTH)
	makeDistrictPath(garden, "GardenWalkSouth", groundY + 0.5, -194, 104, -106, 104, GARDEN_WALK_WIDTH)
	for _, x in ipairs({ -184, -160, -136, -112 }) do
		makeTree(garden, "ParkTree", x, groundY + 0.5, 76, 0.9)
	end

	makePart(
		garden,
		"ReflectingPool",
		Vector3.new(22, 0.3, 12),
		CFrame.new(-150, groundY + 0.55, 82),
		COLORS.Water,
		Enum.Material.Glass,
		0.25,
		false
	)
	LuxuryKit.fountain(garden, "GardenFountain", Vector3.new(-150, groundY + 0.7, 82), 5.4, Palette.Gold)
	for _, position in ipairs({
		Vector3.new(-170, groundY + 0.5, 72),
		Vector3.new(-130, groundY + 0.5, 72),
		Vector3.new(-170, groundY + 0.5, 92),
		Vector3.new(-130, groundY + 0.5, 92),
	}) do
		LuxuryKit.streetLamp(garden, "GardenLamp", position, 8.5, Palette.Charcoal)
	end
	LuxuryKit.pergola(garden, "GardenPergola", Vector3.new(-150, groundY + 0.5, 68), 18, 7, 4.5, Palette.Teak)
	LuxuryKit.bench(garden, "GardenBench", CFrame.new(-162, groundY + 0.5, 68), Palette.Teak, Palette.Gold)
	LuxuryKit.bench(garden, "GardenBench", CFrame.new(-138, groundY + 0.5, 68), Palette.Teak, Palette.Gold)
	for _, x in ipairs({ -190, -110 }) do
		LuxuryKit.palm(garden, "GardenPalm", Vector3.new(x, groundY + 0.5, 116), 0.95, "beach")
	end
	for _, z in ipairs({ 58, 76, 94, 112 }) do
		for _, x in ipairs({ -194, -106 }) do
			LuxuryKit.hedge(
				garden,
				"GardenHedge",
				Vector3.new(x, groundY + 0.5, z),
				2.6,
				1.2,
				14,
				Palette.Green
			)
		end
	end
	makeStandingSign(
		garden,
		"ParkSign",
		"GARDEN PARK",
		Vector3.new(-170, groundY + 7.5, 42),
		26,
		COLORS.Gold,
		5,
		groundY + 0.5
	)

	local social = Instance.new("Folder")
	social.Name = "GrandSocietyClub"
	social.Parent = parent
	makePart(
		social,
		"ClubPlaza",
		Vector3.new(102, 0.5, 76),
		CFrame.new(12, groundY + 0.25, 99),
		COLORS.Stone,
		Enum.Material.Marble
	)
	makeBuilding(
		social,
		"GrandSocietyClubBuilding",
		"GRAND SOCIETY CLUB",
		Vector3.new(12, groundY + 0.5, 103),
		52,
		30,
		28,
		COLORS.Gold
	)
	for _, x in ipairs({ -22, 46 }) do
		makeTree(social, "ClubPalm", x, groundY + 0.5, 94, 1.1)
	end

	local clubCarpet = makePart(
		social,
		"ClubRedCarpet",
		Vector3.new(10, 0.08, 20),
		CFrame.new(12, groundY + 0.54, 77),
		Palette.Burgundy,
		Enum.Material.Fabric,
		0,
		false
	)
	clubCarpet.CastShadow = false
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			social,
			"CarpetGoldEdge",
			Vector3.new(0.18, 0.1, 20),
			CFrame.new(12 + side * 5.1, groundY + 0.55, 77),
			Palette.Gold,
			Enum.Material.Metal
		)
		LuxuryKit.palm(social, "ClubPalm", Vector3.new(12 + side * 28, groundY + 0.5, 70), 1.05, "beach")
		LuxuryKit.hedge(
			social,
			"ClubHedge",
			Vector3.new(12 + side * 32, groundY + 0.5, 64),
			20,
			1.2,
			1.6,
			Palette.Green
		)
		LuxuryKit.flag(
			social,
			"ClubFlag",
			Vector3.new(12 + side * 36, groundY + 0.5, 68),
			10,
			side < 0 and Palette.Navy or Palette.Burgundy
		)
	end
	makeStanchions(social, "ClubVelvetRope", Vector3.new(12, groundY + 0.5, 77), 16, Palette.Burgundy)
	for _, position in ipairs({
		Vector3.new(-26, groundY + 0.5, 68),
		Vector3.new(50, groundY + 0.5, 68),
		Vector3.new(-26, groundY + 0.5, 128),
		Vector3.new(50, groundY + 0.5, 128),
	}) do
		LuxuryKit.streetLamp(social, "ClubLamp", position, 9.5, Palette.Charcoal)
	end
end

local function buildProperties(parent, groundY)
	local district = Instance.new("Folder")
	district.Name = "MillionaireDistrict"
	district.Parent = parent

	for _, property in ipairs(propertyCatalog) do
		local existingProperties = workspace:FindFirstChild("Properties")
		local existingModel = existingProperties and existingProperties:FindFirstChild(property.LegacyModelName)
		local existingBase = existingModel and existingModel:FindFirstChild("Base")
		local x = existingBase and existingBase.Position.X or property.X
		local z = existingBase and existingBase.Position.Z + 38 or 38

		makeResidence(
			district,
			property.ModelName,
			property.DisplayLabel,
			property.Id,
			Vector3.new(x, groundY, z),
			property.Width,
			property.Depth,
			COLORS.Gold
		)
	end
end

local function buildIslandAndMarina(parent, groundY)
	local district = Instance.new("Folder")
	district.Name = "ParadiseIslandAndRoyalMarina"
	district.Parent = parent

	makePart(
		district,
		"IslandBeach",
		Vector3.new(94, 0.45, 70),
		CFrame.new(174, groundY + 0.23, 171),
		COLORS.Sand,
		Enum.Material.Sand
	)
	makePart(
		district,
		"IslandLagoon",
		Vector3.new(84, 0.35, 38),
		CFrame.new(174, groundY + 0.38, 207),
		COLORS.Water,
		Enum.Material.Glass,
		0.24,
		false
	)
	makeDistrictPath(district, "IslandPromenade", groundY + 0.5, 132, 167, 216, 167, ISLAND_PROMENADE_WIDTH)
	makeBuilding(
		district,
		"ParadiseResort",
		"PARADISE RESORT",
		Vector3.new(174, groundY + 0.5, 143),
		40,
		24,
		18,
		COLORS.Gold
	)
	makeStandingSign(
		district,
		"IslandSign",
		"PARADISE ISLAND",
		Vector3.new(135, groundY + 7.5, 129),
		26,
		COLORS.Gold,
		5,
		groundY
	)

	-- Calçadão e área de praia com cabanas, espreguiçadeiras e bar.
	makeDistrictPath(district, "BeachPromenade", groundY + 0.5, 130, 176, 218, 176, 5)
	for _, x in ipairs({ 138, 210 }) do
		LuxuryKit.cabana(
			district,
			"BeachCabana",
			CFrame.new(x, groundY + 0.5, 184),
			7,
			6,
			5,
			Palette.Ivory
		)
		LuxuryKit.palm(district, "BeachPalm", Vector3.new(x + (x < 174 and -8 or 8), groundY + 0.5, 188), 0.85, "beach")
	end
	for _, x in ipairs({ 150, 174, 198 }) do
		LuxuryKit.loungeChair(
			district,
			"BeachLounge",
			CFrame.new(x, groundY + 0.5, 180) * CFrame.Angles(0, math.pi, 0),
			Palette.Fabric,
			Palette.Gold
		)
	end
	for _, x in ipairs({ 150, 198 }) do
		LuxuryKit.umbrella(
			district,
			"BeachUmbrella",
			Vector3.new(x, groundY + 0.5, 179),
			7,
			4,
			Palette.Ivory
		)
	end
	LuxuryKit.part(
		district,
		"BeachBarCounter",
		Vector3.new(12, 1.2, 2.6),
		CFrame.new(174, groundY + 1.1, 182),
		Palette.Teak,
		Enum.Material.WoodPlanks
	)
	LuxuryKit.part(
		district,
		"BeachBarTop",
		Vector3.new(12.4, 0.18, 3),
		CFrame.new(174, groundY + 1.78, 182),
		Palette.Marble,
		Enum.Material.Marble
	)
	LuxuryKit.part(
		district,
		"BeachBarCanopy",
		Vector3.new(14, 0.25, 6),
		CFrame.new(174, groundY + 5.2, 182),
		Palette.Ivory,
		Enum.Material.Fabric
	)
	for _, x in ipairs({ 166, 174, 182 }) do
		LuxuryKit.verticalCylinder(
			district,
			"BarStool",
			1.5,
			0.8,
			Vector3.new(x, groundY + 0.75, 179.8),
			Palette.Burgundy,
			Enum.Material.Fabric
		)
	end
	LuxuryKit.neon(
		district,
		"BeachBarGlow",
		Vector3.new(8, 0.14, 0.18),
		CFrame.new(174, groundY + 4.95, 179.2),
		Palette.NeonWarm
	)

	makePart(
		district,
		"MarinaWater",
		Vector3.new(126, 0.45, 38),
		CFrame.new(180, groundY + 0.28, 218),
		COLORS.Water,
		Enum.Material.Glass,
		0.22,
		false
	)
	for index, x in ipairs({ 136, 170, 204 }) do
		makePart(
			district,
			"MarinaDock" .. index,
			Vector3.new(8, 0.8, 52),
			CFrame.new(x, groundY + 0.8, 211),
			COLORS.Wood,
			Enum.Material.WoodPlanks
		)
		for _, z in ipairs({ 188, 234 }) do
			makePart(
				district,
				"DockPost",
				Vector3.new(1.2, 3, 1.2),
				CFrame.new(x, groundY + 1, z),
				COLORS.Wood,
				Enum.Material.Wood
			)
			LuxuryKit.streetLamp(
				district,
				"DockLamp",
				Vector3.new(x + (z < 211 and -3.2 or 3.2), groundY + 1.2, z),
				6.5,
				Palette.Charcoal
			)
		end
		LuxuryKit.flag(
			district,
			"DockFlag",
			Vector3.new(x, groundY + 1.2, 236),
			7,
			index % 2 == 0 and Palette.Navy or Palette.Burgundy
		)
	end
	LuxuryKit.yacht(district, "MarinaYacht", CFrame.new(180, groundY + 1.2, 218), 0.62)

	makeBuilding(
		district,
		"RoyalMarinaClubhouse",
		"ROYAL MARINA",
		Vector3.new(236, groundY, 171),
		30,
		24,
		16,
		COLORS.Gold
	)
	local marinaCarpet = makePart(
		district,
		"MarinaRedCarpet",
		Vector3.new(8, 0.08, 10),
		CFrame.new(236, groundY + 0.54, 153),
		Palette.Burgundy,
		Enum.Material.Fabric,
		0,
		false
	)
	marinaCarpet.CastShadow = false
	makeStanchions(district, "MarinaVelvetRope", Vector3.new(236, groundY + 0.5, 153), 8, Palette.Burgundy)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.palm(district, "MarinaPalm", Vector3.new(236 + side * 15, groundY + 0.5, 149), 1, "beach")
		LuxuryKit.planter(
			district,
			"MarinaPlanter",
			Vector3.new(236 + side * 10, groundY + 0.5, 156),
			3.4,
			3.4,
			1,
			Palette.Stone,
			Palette.Gold
		)
	end

	-- Farol e calçadão de chegada da marina.
	LuxuryKit.verticalCylinder(
		district,
		"LighthouseBase",
		1.4,
		8,
		Vector3.new(260, groundY + 1, 218),
		Palette.Stone,
		Enum.Material.Marble
	)
	for level = 1, 3 do
		LuxuryKit.verticalCylinder(
			district,
			"LighthouseTower",
			7,
			5.4 - level * 0.7,
			Vector3.new(260, groundY + 1.4 + (level - 0.5) * 7, 218),
			level % 2 == 0 and Palette.Ivory or Palette.Burgundy,
			Enum.Material.SmoothPlastic
		)
	end
	LuxuryKit.verticalCylinder(
		district,
		"LighthouseGallery",
		0.5,
		7,
		Vector3.new(260, groundY + 22.4, 218),
		Palette.Gold,
		Enum.Material.Metal
	)
	local lighthouseLantern = LuxuryKit.verticalCylinder(
		district,
		"LighthouseLantern",
		3,
		3.2,
		Vector3.new(260, groundY + 24.2, 218),
		Palette.NeonWarm,
		Enum.Material.Neon
	)
	LuxuryKit.pointLight(lighthouseLantern, "LighthouseLight", Palette.NeonWarm, 60, 3)
	LuxuryKit.verticalCylinder(
		district,
		"LighthouseRoof",
		2.2,
		4.4,
		Vector3.new(260, groundY + 26.8, 218),
		Palette.Burgundy,
		Enum.Material.SmoothPlastic
	)
	makeDistrictPath(district, "MarinaPromenade", groundY + 0.15, 112, 245, 248, 245, 6)
	for x = 120, 240, 24 do
		LuxuryKit.streetLamp(
			district,
			"MarinaPromenadeLamp",
			Vector3.new(x, groundY + 0.3, 248.5),
			8.5,
			Palette.Charcoal
		)
	end
	makeStandingSign(
		district,
		"MarinaSign",
		"ROYAL MARINA",
		Vector3.new(126, groundY + 7, 243),
		24,
		COLORS.Gold,
		5,
		groundY + 0.3
	)
end

local function buildNeighborhood(parent, groundY)
	local neighborhood = Instance.new("Folder")
	neighborhood.Name = "HighSocietyNeighborhood"
	neighborhood.Parent = parent

	makeDistrictPath(neighborhood, "BoulevardToGarden", groundY, -150, -34, -150, 48, 10)
	makeDistrictPath(neighborhood, "ClubPromenade", groundY, 12, -34, 12, 58, 10)
	makeDistrictPath(neighborhood, "BoulevardToMarina", groundY, 178, -34, 178, 132, 10)

	for _, x in ipairs({ -210, -110, -10, 90, 190 }) do
		makeTree(neighborhood, "BoulevardTree", x, groundY + 0.5, -25, 0.8)
	end

	for _, position in ipairs({
		Vector3.new(-150, groundY + 0.5, -12),
		Vector3.new(-150, groundY + 0.5, 20),
		Vector3.new(12, groundY + 0.5, 30),
		Vector3.new(12, groundY + 0.5, 52),
		Vector3.new(178, groundY + 0.5, -12),
		Vector3.new(178, groundY + 0.5, 36),
		Vector3.new(178, groundY + 0.5, 84),
		Vector3.new(178, groundY + 0.5, 124),
	}) do
		LuxuryKit.streetLamp(neighborhood, "PromenadeLamp", position, 8.5, Palette.Charcoal)
	end
	for _, position in ipairs({
		Vector3.new(-158, groundY + 0.5, 4),
		Vector3.new(-142, groundY + 0.5, 32),
		Vector3.new(170, groundY + 0.5, 12),
		Vector3.new(186, groundY + 0.5, 56),
		Vector3.new(170, groundY + 0.5, 100),
	}) do
		LuxuryKit.palm(neighborhood, "PromenadePalm", position, 0.9, "beach")
	end
	for _, position in ipairs({
		Vector3.new(-158, groundY + 0.5, 14),
		Vector3.new(-142, groundY + 0.5, -4),
		Vector3.new(20, groundY + 0.5, 40),
		Vector3.new(170, groundY + 0.5, 24),
		Vector3.new(186, groundY + 0.5, 72),
	}) do
		LuxuryKit.bench(
			neighborhood,
			"PromenadeBench",
			CFrame.new(position) * CFrame.Angles(0, math.pi / 2, 0),
			Palette.Teak,
			Palette.Gold
		)
	end
	for _, position in ipairs({
		Vector3.new(-158, groundY + 0.5, -24),
		Vector3.new(-142, groundY + 0.5, 44),
		Vector3.new(170, groundY + 0.5, 68),
		Vector3.new(186, groundY + 0.5, 116),
	}) do
		LuxuryKit.hedge(
			neighborhood,
			"PromenadeHedge",
			position,
			2.4,
			1.1,
			10,
			Palette.Green
		)
	end
end

local function ensureWorkPoints(parent, groundY)
	local points = parent:FindFirstChild("WorkPoints")
	if not points then
		points = Instance.new("Folder")
		points.Name = "WorkPoints"
		points.Parent = parent
	elseif not points:IsA("Folder") then
		error("Workspace.HighSocietyWorld.WorkPoints precisa ser uma Folder")
	end

	local definitions = {
		{ "TourGuideStart", "Começar passeio", "Central de Turismo", Vector3.new(-150, groundY + 2, -76) },
		{ "TourGuideFinish", "Entregar passeio", "Paradise Island", Vector3.new(174, groundY + 2, 170) },
		{ "ChauffeurStart", "Iniciar corrida", "Ponto de Chauffeur", Vector3.new(178, groundY + 2, -77) },
		{ "ChauffeurFinish", "Finalizar corrida", "Automotive Gallery", Vector3.new(93, groundY + 2, -88) },
		{ "PhotographerStart", "Iniciar ensaio", "Garden Park", Vector3.new(-150, groundY + 2, 119) },
		{ "PhotographerFinish", "Entregar ensaio", "Grand Society Club", Vector3.new(12, groundY + 2, 129) },
		{ "DJStart", "Iniciar apresentação", "Royal Marina", Vector3.new(136, groundY + 2, 176) },
		{ "DJFinish", "Finalizar apresentação", "Grand Society Club", Vector3.new(12, groundY + 2, 63) },
		{ "EventAnimatorStart", "Iniciar animação", "Garden Park", Vector3.new(-116, groundY + 2, 105) },
		{ "EventAnimatorFinish", "Finalizar animação", "Fashion Avenue", Vector3.new(-58, groundY + 2, -132) },
		{ "EntrepreneurStart", "Apresentar proposta", "High Society Gallery", Vector3.new(-150, groundY + 2, -90) },
		{ "EntrepreneurFinish", "Entregar proposta", "Luxury Hotel", Vector3.new(178, groundY + 2, -77) },
		{ "FashionDesignerStart", "Apresentar coleção", "Fashion Avenue", Vector3.new(-42, groundY + 2, -130) },
		{ "FashionDesignerFinish", "Entregar coleção", "Automotive Gallery", Vector3.new(93, groundY + 2, -88) },
		{ "EventOrganizerStart", "Preparar evento", "Grand Society Club", Vector3.new(24, groundY + 2, 63) },
		{ "EventOrganizerFinish", "Entregar material", "Fashion Avenue", Vector3.new(-68, groundY + 2, -130) },
		{ "EstablishmentOwnerStart", "Iniciar planejamento", "Luxury Hotel", Vector3.new(178, groundY + 2, -130) },
		{
			"EstablishmentOwnerOperationsService",
			"Priorizar atendimento",
			"Plano do hotel",
			Vector3.new(174, groundY + 2, -136),
		},
		{
			"EstablishmentOwnerOperationsEvents",
			"Priorizar eventos",
			"Plano do hotel",
			Vector3.new(182, groundY + 2, -136),
		},
		{
			"EstablishmentOwnerAuditApprove",
			"Aprovar padrão",
			"Auditoria do clube",
			Vector3.new(22, groundY + 2, 82),
		},
		{
			"EstablishmentOwnerAuditTraining",
			"Recomendar treinamento",
			"Auditoria do clube",
			Vector3.new(30, groundY + 2, 82),
		},
		{ "EstablishmentOwnerFinish", "Entregar planejamento", "Grand Society Club", Vector3.new(0, groundY + 2, 63) },
		{ "WorldCreatorStart", "Criar proposta de cenário", "Garden Park", Vector3.new(-174, groundY + 2, 105) },
		{
			"WorldCreatorThemeGarden",
			"Tema de jardim",
			"Escolher tema",
			Vector3.new(-158, groundY + 2, 60),
		},
		{
			"WorldCreatorThemeCoastal",
			"Tema costeiro",
			"Escolher tema",
			Vector3.new(-150, groundY + 2, 60),
		},
		{
			"WorldCreatorThemeUrban",
			"Tema urbano",
			"Escolher tema",
			Vector3.new(-142, groundY + 2, 60),
		},
		{
			"WorldCreatorLayoutPavilion",
			"Composição com pavilhão",
			"Montar maquete",
			Vector3.new(-158, groundY + 2, -72),
		},
		{
			"WorldCreatorLayoutPlaza",
			"Composição com praça",
			"Montar maquete",
			Vector3.new(-150, groundY + 2, -72),
		},
		{
			"WorldCreatorLayoutPromenade",
			"Composição com passeio",
			"Montar maquete",
			Vector3.new(-142, groundY + 2, -72),
		},
		{ "WorldCreatorFinish", "Apresentar cenário", "High Society Gallery", Vector3.new(-166, groundY + 2, -90) },
	}

	for _, definition in ipairs(definitions) do
		local point = points:FindFirstChild(definition[1])
		if not point then
			makeWorkPoint(points, definition[1], definition[2], definition[3], definition[4])
		elseif not point:IsA("BasePart") then
			error(string.format("Workspace.HighSocietyWorld.WorkPoints.%s precisa ser uma peça", definition[1]))
		else
			-- Pontos salvos pela versão antiga eram blocos sólidos no caminho.
			point.CanCollide = false
			local prompt = point:FindFirstChild("WorkPrompt")
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.Name = "WorkPrompt"
				prompt.Parent = point
			elseif not prompt:IsA("ProximityPrompt") then
				error(string.format("%s.WorkPrompt precisa ser ProximityPrompt", point:GetFullName()))
			end
			prompt.ActionText = definition[2]
			prompt.ObjectText = definition[3]
			prompt.MaxActivationDistance = 10
			prompt.HoldDuration = 0
			prompt.RequiresLineOfSight = false
		end
	end

	return points
end

local function buildEventPoints(parent, groundY)
	local points = parent:FindFirstChild("EventPoints")
	if not points then
		points = Instance.new("Folder")
		points.Name = "EventPoints"
		points.Parent = parent
	elseif not points:IsA("Folder") then
		error("Workspace.HighSocietyWorld.EventPoints precisa ser uma Folder")
	end

	local definitions = {
		{ "club_festival", "Noite no Grand Society Club", Vector3.new(12, groundY + 2, 63) },
		{ "garden_photo_walk", "Passeio fotográfico no Garden Park", Vector3.new(-116, groundY + 2, 105) },
		{ "fashion_show", "Desfile da Fashion Avenue", Vector3.new(-58, groundY + 2, -132) },
		{ "marina_exhibition", "Encontro na Royal Marina", Vector3.new(136, groundY + 2, 176) },
	}

	for _, definition in ipairs(definitions) do
		local point = points:FindFirstChild(definition[1])
		if not point then
			makeEventPoint(points, definition[1], definition[2], definition[3])
		elseif not point:IsA("BasePart") then
			error(string.format("Workspace.HighSocietyWorld.EventPoints.%s precisa ser uma peça", definition[1]))
		end
	end
end

local function ensureEventDecorations(parent, groundY)
	local decorations = parent:FindFirstChild("EventDecorations")
	if not decorations then
		decorations = Instance.new("Folder")
		decorations.Name = "EventDecorations"
		decorations.Parent = parent
	elseif not decorations:IsA("Folder") then
		error("Workspace.HighSocietyWorld.EventDecorations precisa ser uma Folder")
	end

	local definitions = {
		{
			Name = "ClubStage",
			Label = "GRAND SOCIETY LIVE",
			Center = Vector3.new(12, groundY, 70),
			Platform = Vector3.new(34, 1, 18),
			Accent = COLORS.Gold,
			Background = Color3.fromRGB(28, 27, 38),
		},
		{
			Name = "FashionRunway",
			Label = "FASHION AVENUE",
			Center = Vector3.new(-22, groundY, -141),
			Platform = Vector3.new(42, 0.5, 7),
			Accent = Color3.fromRGB(190, 139, 173),
			Background = Color3.fromRGB(34, 29, 38),
		},
		{
			Name = "MarinaExhibition",
			Label = "ROYAL MARINA",
			Center = Vector3.new(136, groundY, 176),
			Platform = Vector3.new(20, 0.7, 12),
			Accent = Color3.fromRGB(119, 177, 193),
			Background = Color3.fromRGB(25, 39, 48),
		},
	}

	for _, definition in ipairs(definitions) do
		if decorations:FindFirstChild(definition.Name) then
			continue
		end

		local display = Instance.new("Model")
		display.Name = definition.Name
		display.Parent = decorations
		makePart(
			display,
			"Platform",
			definition.Platform,
			CFrame.new(definition.Center.X, definition.Center.Y + definition.Platform.Y / 2, definition.Center.Z),
			definition.Background,
			Enum.Material.Slate
		)
		makePart(
			display,
			"AccentStrip",
			Vector3.new(definition.Platform.X, 0.18, 0.35),
			CFrame.new(
				definition.Center.X,
				definition.Center.Y + definition.Platform.Y + 0.08,
				definition.Center.Z - definition.Platform.Z / 2 + 0.6
			),
			definition.Accent,
			Enum.Material.Neon,
			0,
			false
		)

		if definition.Name ~= "FashionRunway" then
			makePart(
				display,
				"Backdrop",
				Vector3.new(definition.Platform.X * 0.72, 8, 0.8),
				CFrame.new(
					definition.Center.X,
					definition.Center.Y + 5,
					definition.Center.Z + definition.Platform.Z / 2 - 0.6
				),
				definition.Background,
				Enum.Material.Metal
			)
			makeSign(
				display,
				"EventSign",
				definition.Label,
				Vector3.new(
					definition.Center.X,
					definition.Center.Y + 8,
					definition.Center.Z + definition.Platform.Z / 2 - 1
				),
				math.max(12, definition.Platform.X * 0.55),
				definition.Accent
			)

			local lightBar = makePart(
				display,
				"LightBar",
				Vector3.new(definition.Platform.X * 0.7, 0.35, 0.35),
				CFrame.new(
					definition.Center.X,
					definition.Center.Y + 10,
					definition.Center.Z - definition.Platform.Z / 2 + 1
				),
				definition.Accent,
				Enum.Material.Neon,
				0,
				false
			)
			local light = Instance.new("PointLight")
			light.Name = "StageLight"
			light.Color = definition.Accent
			light.Range = 28
			light.Brightness = 1.2
			light.Parent = lightBar
		else
			for index = -2, 2 do
				makePart(
					display,
					"RunwayMarker",
					Vector3.new(0.35, 0.2, definition.Platform.Z * 0.72),
					CFrame.new(
						definition.Center.X + index * 8,
						definition.Center.Y + definition.Platform.Y / 2 + 0.18,
						definition.Center.Z
					),
					definition.Accent,
					Enum.Material.Neon,
					0,
					false
				)
			end
		end
	end

	local clubStage = decorations:FindFirstChild("ClubStage")
	if not clubStage or not clubStage:IsA("Model") then
		error("Workspace.HighSocietyWorld.EventDecorations.ClubStage precisa ser um Model")
	end

	local lightBar = clubStage:FindFirstChild("LightBar")
	if not lightBar then
		lightBar = makePart(
			clubStage,
			"LightBar",
			Vector3.new(24, 0.35, 0.35),
			CFrame.new(12, groundY + 10, 64),
			COLORS.Gold,
			Enum.Material.Neon,
			0,
			false
		)
	elseif not lightBar:IsA("BasePart") then
		error("EventDecorations.ClubStage.LightBar precisa ser uma peça")
	end

	local stageLight = lightBar:FindFirstChild("StageLight")
	if not stageLight then
		stageLight = Instance.new("PointLight")
		stageLight.Name = "StageLight"
		stageLight.Color = COLORS.Gold
		stageLight.Range = 28
		stageLight.Brightness = 1.2
		stageLight.Parent = lightBar
	elseif not stageLight:IsA("PointLight") then
		error("EventDecorations.ClubStage.LightBar.StageLight precisa ser PointLight")
	end

	for index = 1, 3 do
		local beamName = "StageBeam" .. index
		local beam = lightBar:FindFirstChild(beamName)
		if not beam then
			beam = Instance.new("SpotLight")
			beam.Name = beamName
			beam.Angle = 70
			beam.Face = Enum.NormalId.Bottom
			beam.Range = 40
			beam.Brightness = 0
			beam.Parent = lightBar
		elseif not beam:IsA("SpotLight") then
			error(string.format("EventDecorations.ClubStage.LightBar.%s precisa ser SpotLight", beamName))
		end
	end

	local booth = clubStage:FindFirstChild("DJBooth")
	if not booth then
		booth = makePart(
			clubStage,
			"DJBooth",
			Vector3.new(5, 2, 2),
			CFrame.new(20, groundY + 1.5, 68),
			COLORS.Gold,
			Enum.Material.Metal
		)
	elseif not booth:IsA("BasePart") then
		error("EventDecorations.ClubStage.DJBooth precisa ser uma peça")
	end
	local prompt = booth:FindFirstChild("DJBoothPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DJBoothPrompt"
		prompt.Parent = booth
	elseif not prompt:IsA("ProximityPrompt") then
		error("EventDecorations.ClubStage.DJBooth.DJBoothPrompt precisa ser ProximityPrompt")
	end
	prompt.ActionText = "Abrir cabine"
	prompt.ObjectText = "Grand Society Club"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
end

local function ensureGeneratedPropertyPurchasePoints(world, groundY)
	local district = world:FindFirstChild("MillionaireDistrict")
	if not district then
		return
	end

	for _, model in ipairs(district:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("PropertyId") then
			local existingPoint = model:FindFirstChild("PropertyPurchasePoint")
			if not existingPoint then
				local spawnPoint = model:FindFirstChild("SpawnPoint")
				if spawnPoint and spawnPoint:IsA("BasePart") then
					local point = makePart(
						model,
						"PropertyPurchasePoint",
						Vector3.new(4, 2, 4),
						CFrame.new(spawnPoint.Position.X, groundY + 1, spawnPoint.Position.Z - 18),
						COLORS.Gold,
						Enum.Material.Metal
					)
					point:SetAttribute("PropertyId", model:GetAttribute("PropertyId"))
					point.CanCollide = false
				end
			elseif not existingPoint:IsA("BasePart") then
				error(string.format("%s.PropertyPurchasePoint precisa ser uma peça", model:GetFullName()))
			else
				existingPoint.CanCollide = false
			end
		end
	end
end

-- Reparo idempotente do mundo que já está salvo no Studio.
-- Corrige as escadarias invertidas sem apagar nenhuma construção.
local function repairSteps(model)
	local foundation = model:FindFirstChild("Foundation")
	if not foundation or not foundation:IsA("BasePart") then
		return 0
	end

	local groundY = foundation.Position.Y - foundation.Size.Y / 2
	local steps = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and (descendant.Name == "Step" or descendant.Name == "EntranceStep") then
			table.insert(steps, descendant)
		end
	end
	if #steps == 0 then
		return 0
	end

	-- A frente do prédio fica em Z menor. Ordenando do maior Z para o menor,
	-- o primeiro degrau é o mais próximo da fundação e deve ser o mais alto.
	table.sort(steps, function(left, right)
		return left.Position.Z > right.Position.Z
	end)

	local repaired = 0
	for index, step in ipairs(steps) do
		local desiredTop = groundY + 0.3 * (#steps - index + 1)
		local desiredY = desiredTop - step.Size.Y / 2
		if math.abs(step.Position.Y - desiredY) > 0.01 then
			step.CFrame = CFrame.new(step.Position.X, desiredY, step.Position.Z)
			repaired += 1
		end
	end
	return repaired
end

local function repairStandingSign(world, name, position, width, color, height, baseY)
	local board = world:FindFirstChild(name, true)
	if not board or not board:IsA("BasePart") then
		return false
	end

	local parent = board.Parent
	if not parent then
		return false
	end

	if parent:FindFirstChild(name .. "Post") then
		return false
	end

	-- Move a placa e a moldura juntas, sem recriar o letreiro.
	local delta = position - board.Position
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("BasePart") and child.Name:sub(1, #name) == name then
			child.CFrame = child.CFrame + delta
		end
	end

	addSignPosts(parent, name, position, width, color, height, baseY)
	return true
end

local function repairWorld(world, groundY)
	local buildingModels = {}
	for _, descendant in ipairs(world:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Foundation" then
			local model = descendant:FindFirstAncestorOfClass("Model")
			if model then
				buildingModels[model] = true
			end
		end
	end

	local repairedSteps = 0
	for model in pairs(buildingModels) do
		repairedSteps += repairSteps(model)
	end

	local repairedSigns = 0
	if repairStandingSign(world, "ParkSign", Vector3.new(-170, groundY + 7.5, 42), 26, COLORS.Gold, 5, groundY + 0.5) then
		repairedSigns += 1
	end
	if repairStandingSign(world, "IslandSign", Vector3.new(135, groundY + 7.5, 129), 26, COLORS.Gold, 5, groundY) then
		repairedSigns += 1
	end
	if repairStandingSign(world, "MarinaSign", Vector3.new(126, groundY + 7, 243), 24, COLORS.Gold, 5, groundY + 0.3) then
		repairedSigns += 1
	end

	Logger.Info(
		"WorldBuilder",
		string.format("Reparo do mundo existente: %d degrau(s) e %d placa(s).", repairedSteps, repairedSigns)
	)
	return repairedSteps, repairedSigns
end

local function getGroundY()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		return baseplate.Position.Y + baseplate.Size.Y / 2
	end

	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		return spawn.Position.Y - spawn.Size.Y / 2
	end

	Logger.Warn(
		"WorldBuilder",
		"Falta Workspace.Baseplate e uma SpawnLocation; a cidade será gerada usando o nível do chão Y=0."
	)
	return 0
end

-- Cria o chão do mundo quando o lugar não tem Baseplate.
-- Sem isso o avatar cai no vazio e fica em loop de queda/respawn.
-- Terra firme (grama) + mar ao redor da Paradise Island e da Marina.
local function ensureGround(groundY)
	local baseplate = workspace:FindFirstChild(Config.Map.BaseplateName)
	if baseplate and baseplate:IsA("BasePart") then
		return false
	end
	if workspace:FindFirstChild("HSC_Ground") then
		return false
	end

	local folder = Instance.new("Folder")
	folder.Name = "HSC_Ground"
	folder:SetAttribute("GeneratedBy", "WorldBuilder")

	local grass = Color3.fromRGB(86, 126, 74)
	local thickness = 4
	local topY = groundY - 0.05
	local centerY = topY - thickness / 2

	-- Limites da terra firme e buraco da marina (água fica sobre o leito do mar).
	local minX, maxX, minZ, maxZ = -300, 300, -230, 250
	local holeMinX, holeMaxX, holeMinZ, holeMaxZ = 112, 248, 186, 240

	local function slab(name, x1, x2, z1, z2)
		local part = makePart(
			folder,
			name,
			Vector3.new(x2 - x1, thickness, z2 - z1),
			CFrame.new((x1 + x2) / 2, centerY, (z1 + z2) / 2),
			grass,
			Enum.Material.Grass
		)
		return part
	end

	slab("LandMain", minX, maxX, minZ, holeMinZ)
	slab("LandWest", minX, holeMinX, holeMinZ, holeMaxZ)
	slab("LandEast", holeMaxX, maxX, holeMinZ, holeMaxZ)
	slab("LandSouth", minX, maxX, holeMaxZ, maxZ)

	-- Leito do mar (impede cair no vazio) e superfície da água.
	makePart(
		folder,
		"SeaFloor",
		Vector3.new(2600, 4, 2600),
		CFrame.new(0, groundY - 5, 0),
		COLORS.Sand,
		Enum.Material.Sand
	)
	makePart(
		folder,
		"Ocean",
		Vector3.new(2600, 1, 2600),
		CFrame.new(0, groundY - 1.5, 0),
		COLORS.Water,
		Enum.Material.Glass,
		0.35,
		false
	)

	folder.Parent = workspace
	Logger.Info("WorldBuilder", "Chão e mar criados (não havia Baseplate no lugar)")
	return true
end

function WorldBuilder.GetGroundY()
	return getGroundY()
end

function WorldBuilder.EnsureGround()
	return ensureGround(getGroundY())
end

function WorldBuilder.Init()
	ensureGround(getGroundY())
	local existing = workspace:FindFirstChild(WORLD_NAME)
	if existing then
		existing:SetAttribute("HSC_WorldVersion", WORLD_VERSION)
		local boulevard = existing:FindFirstChild("HighSocietyBoulevard")
		local fashionStore = boulevard and boulevard:FindFirstChild("FashionAvenueStore")
		if fashionStore and not fashionStore:FindFirstChild("ShopPoint") then
			makeShopPoint(fashionStore, Vector3.new(-68, getGroundY() + 2, -130))
		elseif fashionStore then
			local shopPoint = fashionStore:FindFirstChild("ShopPoint")
			if shopPoint and shopPoint:IsA("BasePart") then
				shopPoint:SetAttribute("ShopId", "fashion_avenue")
				shopPoint:SetAttribute("ShopName", "Fashion Avenue")
				shopPoint.CanCollide = false
			end
		end
		ensureCentralPlaza(existing, getGroundY())
		local spawnOk, spawnError = pcall(ensureSpawn, existing, getGroundY())
		if not spawnOk then
			Logger.Warn("WorldBuilder", "Falha ao ajustar o spawn: " .. tostring(spawnError))
		end
		local repairOk, repairError = pcall(repairWorld, existing, getGroundY())
		if not repairOk then
			Logger.Warn("WorldBuilder", "Falha ao reparar o mundo existente: " .. tostring(repairError))
		end
		ensureWorkPoints(existing, getGroundY())
		ensureVehiclePoints(existing, getGroundY())
		buildEventPoints(existing, getGroundY())
		ensureEventDecorations(existing, getGroundY())
		ensureGeneratedPropertyPurchasePoints(existing, getGroundY())
		return existing
	end

	local groundY = getGroundY()

	local world = Instance.new("Folder")
	world.Name = WORLD_NAME
	world:SetAttribute("GeneratedBy", "WorldBuilder")
	world:SetAttribute("HSC_WorldVersion", WORLD_VERSION)

	buildBoulevard(world, groundY)
	ensureCentralPlaza(world, groundY)
	ensureSpawn(world, groundY)
	ensureVehiclePoints(world, groundY)
	buildGardenAndClub(world, groundY)
	buildProperties(world, groundY)
	buildIslandAndMarina(world, groundY)
	buildNeighborhood(world, groundY)
	ensureWorkPoints(world, groundY)
	buildEventPoints(world, groundY)
	ensureEventDecorations(world, groundY)
	ensureGeneratedPropertyPurchasePoints(world, groundY)

	world.Parent = workspace
	Logger.Info("WorldBuilder", "Cidade-base criada sem substituir objetos existentes")
	return world
end

return WorldBuilder
