local CreationBuilder = {}

local EXHIBIT_NAME = "ApprovedCreationExhibits"
local DISPLAY_LIMIT = 6
local PLOT_SIZE = Vector3.new(20, 1, 18)
local PLOT_POSITIONS = {
	Vector2.new(-24, -60),
	Vector2.new(16, -60),
	Vector2.new(56, -60),
	Vector2.new(-24, -90),
	Vector2.new(16, -90),
	Vector2.new(56, -90),
}

local themes = {
	Jardim = {
		Ground = Color3.fromRGB(84, 121, 76),
		Accent = Color3.fromRGB(203, 181, 111),
		Structure = Color3.fromRGB(226, 221, 199),
		Material = Enum.Material.Grass,
	},
	Costeiro = {
		Ground = Color3.fromRGB(207, 188, 143),
		Accent = Color3.fromRGB(70, 146, 174),
		Structure = Color3.fromRGB(231, 236, 224),
		Material = Enum.Material.Sand,
	},
	Urbano = {
		Ground = Color3.fromRGB(75, 79, 87),
		Accent = Color3.fromRGB(219, 180, 90),
		Structure = Color3.fromRGB(171, 181, 190),
		Material = Enum.Material.Concrete,
	},
}

local function makePart(parent, name, size, cframe, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function makeSign(parent, text, position, color)
	local sign = makePart(
		parent,
		"CreatorSign",
		Vector3.new(12, 2.4, 0.3),
		CFrame.new(position),
		Color3.fromRGB(24, 27, 32),
		Enum.Material.SmoothPlastic
	)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "SignSurface"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 24
	surface.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = surface
end

local function buildPavilion(model, origin, palette)
	for _, offset in ipairs({
		Vector3.new(-5, 3.2, -4),
		Vector3.new(5, 3.2, -4),
		Vector3.new(-5, 3.2, 4),
		Vector3.new(5, 3.2, 4),
	}) do
		makePart(
			model,
			"PavilionColumn",
			Vector3.new(0.9, 5, 0.9),
			CFrame.new(origin + Vector3.new(offset.X, 2.5, offset.Z)),
			palette.Structure,
			Enum.Material.Marble
		)
	end
	makePart(
		model,
		"PavilionRoof",
		Vector3.new(13, 0.8, 11),
		CFrame.new(origin + Vector3.new(0, 5.4, 0)),
		palette.Accent,
		Enum.Material.Metal
	)
end

local function buildPlaza(model, origin, palette)
	makePart(
		model,
		"PlazaFountainBasin",
		Vector3.new(7, 0.8, 7),
		CFrame.new(origin + Vector3.new(0, 0.4, 0)),
		palette.Accent,
		Enum.Material.Marble,
		Enum.PartType.Cylinder
	)
	makePart(
		model,
		"PlazaFountain",
		Vector3.new(2.4, 2.6, 2.4),
		CFrame.new(origin + Vector3.new(0, 1.7, 0)),
		palette.Structure,
		Enum.Material.Marble,
		Enum.PartType.Cylinder
	)
	makePart(
		model,
		"PlazaFeature",
		Vector3.new(1, 0.4, 1),
		CFrame.new(origin + Vector3.new(0, 3.2, 0)),
		palette.Accent,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
end

local function buildPromenade(model, origin, palette)
	makePart(
		model,
		"PromenadeWalk",
		Vector3.new(5, 0.35, 15),
		CFrame.new(origin + Vector3.new(0, 0.175, 0)),
		palette.Structure,
		Enum.Material.Marble
	)
	for _, zOffset in ipairs({ -5, 5 }) do
		makePart(
			model,
			"PromenadeLamp",
			Vector3.new(0.45, 5.2, 0.45),
			CFrame.new(origin + Vector3.new(6, 2.6, zOffset)),
			palette.Accent,
			Enum.Material.Metal
		)
		makePart(
			model,
			"PromenadeLight",
			Vector3.new(1.4, 0.5, 1.4),
			CFrame.new(origin + Vector3.new(6, 5.45, zOffset)),
			palette.Accent,
			Enum.Material.Neon
		)
		makePart(
			model,
			"PromenadeTree",
			Vector3.new(2.6, 2.6, 2.6),
			CFrame.new(origin + Vector3.new(-6, 1.3, zOffset)),
			palette.Ground,
			Enum.Material.Grass,
			Enum.PartType.Ball
		)
	end
end

function CreationBuilder.Update(world, creations)
	if typeof(world) ~= "Instance" or type(creations) ~= "table" then
		return false, "Mundo ou lista de criações inválida"
	end
	local workPoints = world:FindFirstChild("WorkPoints")
	local finishPoint = workPoints and workPoints:FindFirstChild("WorldCreatorFinish")
	if not finishPoint or not finishPoint:IsA("BasePart") then
		return false, "Ponto da Galeria WorldCreatorFinish não está disponível"
	end

	local count = math.min(#creations, DISPLAY_LIMIT)
	local fingerprintParts = {}
	for index = 1, count do
		local creation = creations[index]
		if type(creation) == "table" then
			table.insert(
				fingerprintParts,
				string.format("%s:%s:%s", tostring(creation.Id), tostring(creation.Theme), tostring(creation.Layout))
			)
		end
	end
	local fingerprint = table.concat(fingerprintParts, "|")

	local existing = world:FindFirstChild(EXHIBIT_NAME)
	if existing then
		if not existing:IsA("Folder") or existing:GetAttribute("GeneratedBy") ~= "CreationBuilder" then
			return false, "O nome ApprovedCreationExhibits já pertence a um objeto do projeto"
		end
		if existing:GetAttribute("Fingerprint") == fingerprint then
			return true
		end
		existing:Destroy()
	end

	local gallery = Instance.new("Folder")
	gallery.Name = EXHIBIT_NAME
	gallery:SetAttribute("GeneratedBy", "CreationBuilder")
	gallery:SetAttribute("Fingerprint", fingerprint)

	local groundY = finishPoint.Position.Y - 2

	for index = 1, count do
		local creation = creations[index]
		local palette = type(creation) == "table" and themes[creation.Theme]
		if palette and (creation.Layout == "Pavilhão" or creation.Layout == "Praça" or creation.Layout == "Passeio") then
			local positionOffset = PLOT_POSITIONS[index]
			local position = Vector3.new(
				finishPoint.Position.X + positionOffset.X,
				groundY,
				finishPoint.Position.Z + positionOffset.Y
			)
			local plot = Instance.new("Model")
			plot.Name = string.format("ApprovedCreation_%d", index)
			plot:SetAttribute("SubmissionId", creation.Id)
			plot:SetAttribute("CreatorUserId", creation.CreatorUserId)
			plot.Parent = gallery

			local origin = Vector3.new(position.X, groundY + PLOT_SIZE.Y, position.Z)
			makePart(
				plot,
				"DisplayPlot",
				PLOT_SIZE,
				CFrame.new(position.X, groundY + PLOT_SIZE.Y / 2, position.Z),
				palette.Ground,
				palette.Material
			)

			if creation.Layout == "Pavilhão" then
				buildPavilion(plot, origin, palette)
			elseif creation.Layout == "Praça" then
				buildPlaza(plot, origin, palette)
			else
				buildPromenade(plot, origin, palette)
			end
			makeSign(
				plot,
				string.format("%s • %s", creation.Theme, creation.Layout),
				origin + Vector3.new(0, 2.2, -8.7),
				palette.Accent
			)
		end
	end

	gallery.Parent = world
	return true
end

return CreationBuilder
