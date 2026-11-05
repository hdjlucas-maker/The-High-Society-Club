-- LuxuryKit: peças reutilizáveis de arquitetura e decoração de luxo.
-- Tudo é gerado por código com materiais, formas arredondadas e detalhes dourados.
-- Não depende de assets pagos nem de modelos externos.
local LuxuryKit = {}

local Palette = {
	Marble = Color3.fromRGB(238, 234, 224),
	WarmWhite = Color3.fromRGB(247, 243, 234),
	Cream = Color3.fromRGB(228, 219, 201),
	Ivory = Color3.fromRGB(252, 249, 241),
	Gold = Color3.fromRGB(214, 177, 96),
	GoldBright = Color3.fromRGB(246, 216, 138),
	GoldDark = Color3.fromRGB(150, 114, 54),
	Charcoal = Color3.fromRGB(28, 30, 36),
	Ink = Color3.fromRGB(17, 19, 24),
	Glass = Color3.fromRGB(122, 181, 198),
	DeepGlass = Color3.fromRGB(38, 76, 94),
	Aqua = Color3.fromRGB(77, 191, 203),
	Water = Color3.fromRGB(50, 151, 174),
	Sand = Color3.fromRGB(226, 205, 165),
	Stone = Color3.fromRGB(206, 201, 190),
	Concrete = Color3.fromRGB(172, 169, 161),
	Green = Color3.fromRGB(66, 111, 73),
	Leaf = Color3.fromRGB(96, 149, 92),
	DarkGreen = Color3.fromRGB(38, 78, 54),
	Wood = Color3.fromRGB(118, 82, 56),
	Teak = Color3.fromRGB(156, 113, 70),
	Fabric = Color3.fromRGB(238, 234, 226),
	Navy = Color3.fromRGB(28, 42, 59),
	Burgundy = Color3.fromRGB(99, 36, 48),
	Rose = Color3.fromRGB(192, 140, 174),
	NeonWarm = Color3.fromRGB(255, 226, 170),
	NeonCool = Color3.fromRGB(160, 222, 255),
}

LuxuryKit.Palette = Palette

local function applyBaseProperties(part, color, material, transparency, canCollide)
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = canCollide ~= false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

function LuxuryKit.part(parent, name, size, cframe, color, material, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	applyBaseProperties(part, color, material, transparency, canCollide)
	part.Parent = parent
	return part
end

function LuxuryKit.shapePart(parent, name, size, cframe, shape, color, material, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Shape = shape
	applyBaseProperties(part, color, material, transparency, canCollide)
	part.Parent = parent
	return part
end

function LuxuryKit.wedge(parent, name, size, cframe, color, material, transparency, canCollide)
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	applyBaseProperties(part, color, material, transparency, canCollide)
	part.Parent = parent
	return part
end

function LuxuryKit.ball(parent, name, size, center, color, material, transparency, canCollide)
	return LuxuryKit.shapePart(
		parent,
		name,
		size,
		CFrame.new(center),
		Enum.PartType.Ball,
		color,
		material,
		transparency,
		canCollide
	)
end

function LuxuryKit.verticalCylinder(parent, name, height, diameter, center, color, material, transparency, canCollide)
	return LuxuryKit.shapePart(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
		Enum.PartType.Cylinder,
		color,
		material,
		transparency,
		canCollide
	)
end

function LuxuryKit.horizontalCylinder(parent, name, length, diameter, cframe, color, material, transparency, canCollide)
	return LuxuryKit.shapePart(
		parent,
		name,
		Vector3.new(length, diameter, diameter),
		cframe,
		Enum.PartType.Cylinder,
		color,
		material,
		transparency,
		canCollide
	)
end

function LuxuryKit.neon(parent, name, size, cframe, color)
	local part = LuxuryKit.part(parent, name, size, cframe, color, Enum.Material.Neon, 0, false)
	part.CastShadow = false
	return part
end

function LuxuryKit.pointLight(parent, name, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Name = name
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = true
	light.Parent = parent
	return light
end

function LuxuryKit.spotLight(parent, name, color, range, brightness, angle, face)
	local light = Instance.new("SpotLight")
	light.Name = name
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Angle = angle or 70
	light.Face = face or Enum.NormalId.Front
	light.Shadows = true
	light.Parent = parent
	return light
end

function LuxuryKit.column(parent, name, center, height, diameter, color, material, accent)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Base",
		0.35,
		diameter * 1.55,
		Vector3.new(center.X, center.Y - height / 2 + 0.175, center.Z),
		color,
		material
	)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Plinth",
		0.25,
		diameter * 1.32,
		Vector3.new(center.X, center.Y - height / 2 + 0.45, center.Z),
		color,
		material
	)
	LuxuryKit.verticalCylinder(
		parent,
		name,
		math.max(0.5, height - 1),
		diameter,
		Vector3.new(center.X, center.Y, center.Z),
		color,
		material
	)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Capital",
		0.35,
		diameter * 1.38,
		Vector3.new(center.X, center.Y + height / 2 - 0.175, center.Z),
		color,
		material
	)
	if accent then
		LuxuryKit.verticalCylinder(
			parent,
			name .. "GoldRing",
			0.12,
			diameter * 1.18,
			Vector3.new(center.X, center.Y + height / 2 - 0.48, center.Z),
			accent,
			Enum.Material.Metal
		)
	end
end

function LuxuryKit.glassRailing(parent, name, cframe, length, height, accent)
	local glass = LuxuryKit.part(
		parent,
		name .. "Glass",
		Vector3.new(length, height, 0.08),
		cframe * CFrame.new(0, height / 2, 0),
		Palette.Glass,
		Enum.Material.Glass,
		0.55,
		false
	)
	glass.CastShadow = false
	LuxuryKit.part(
		parent,
		name .. "TopRail",
		Vector3.new(length + 0.25, 0.12, 0.2),
		cframe * CFrame.new(0, height, 0),
		accent or Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "BottomRail",
		Vector3.new(length, 0.1, 0.14),
		cframe * CFrame.new(0, 0.06, 0),
		accent or Palette.Gold,
		Enum.Material.Metal
	)
	local posts = math.max(2, math.floor(length / 6))
	for index = 0, posts do
		local x = -length / 2 + (length / posts) * index
		LuxuryKit.part(
			parent,
			name .. "Post",
			Vector3.new(0.12, height, 0.12),
			cframe * CFrame.new(x, height / 2, 0),
			accent or Palette.Gold,
			Enum.Material.Metal
		)
	end
end

function LuxuryKit.balustrade(parent, name, cframe, length, height, color, material, accent)
	LuxuryKit.part(
		parent,
		name .. "TopRail",
		Vector3.new(length + 0.3, 0.2, 0.35),
		cframe * CFrame.new(0, height, 0),
		accent or color,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "BottomRail",
		Vector3.new(length, 0.18, 0.3),
		cframe * CFrame.new(0, 0.1, 0),
		accent or color,
		Enum.Material.Metal
	)
	local posts = math.max(1, math.floor(length / 8))
	for index = 0, posts do
		local x = -length / 2 + (length / posts) * index
		LuxuryKit.part(
			parent,
			name .. "Post",
			Vector3.new(0.35, height, 0.35),
			cframe * CFrame.new(x, height / 2, 0),
			color,
			material
		)
	end
	local balusters = math.max(2, math.floor(length / 1.6))
	for index = 1, balusters - 1 do
		local x = -length / 2 + (length / balusters) * index
		LuxuryKit.verticalCylinder(
			parent,
			name .. "Baluster",
			math.max(0.4, height - 0.35),
			0.18,
			(cframe * CFrame.new(x, height / 2, 0)).Position,
			color,
			material
		)
	end
end

function LuxuryKit.windowGrid(parent, name, cframe, width, height, columns, rows, frameColor, glassColor)
	local glass = LuxuryKit.part(
		parent,
		name .. "Glass",
		Vector3.new(width, height, 0.12),
		cframe,
		glassColor or Palette.Glass,
		Enum.Material.Glass,
		0.24,
		false
	)
	glass.CastShadow = false

	local frame = frameColor or Palette.Gold
	LuxuryKit.part(
		parent,
		name .. "FrameTop",
		Vector3.new(width + 0.35, 0.24, 0.32),
		cframe * CFrame.new(0, height / 2, -0.08),
		frame,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "FrameBottom",
		Vector3.new(width + 0.35, 0.24, 0.32),
		cframe * CFrame.new(0, -height / 2, -0.08),
		frame,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "FrameLeft",
		Vector3.new(0.24, height + 0.35, 0.32),
		cframe * CFrame.new(-width / 2, 0, -0.08),
		frame,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "FrameRight",
		Vector3.new(0.24, height + 0.35, 0.32),
		cframe * CFrame.new(width / 2, 0, -0.08),
		frame,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "Sill",
		Vector3.new(width + 0.6, 0.2, 0.55),
		cframe * CFrame.new(0, -height / 2 - 0.16, -0.18),
		frame,
		Enum.Material.Metal
	)

	for column = 1, math.max(0, columns - 1) do
		local x = -width / 2 + (width / columns) * column
		LuxuryKit.part(
			parent,
			name .. "Mullion",
			Vector3.new(0.11, height, 0.2),
			cframe * CFrame.new(x, 0, -0.09),
			frame,
			Enum.Material.Metal
		)
	end
	for row = 1, math.max(0, rows - 1) do
		local y = -height / 2 + (height / rows) * row
		LuxuryKit.part(
			parent,
			name .. "Transom",
			Vector3.new(width, 0.11, 0.2),
			cframe * CFrame.new(0, y, -0.09),
			frame,
			Enum.Material.Metal
		)
	end
	return glass
end

function LuxuryKit.door(parent, name, cframe, width, height, frameColor, glassColor, glassTransparency)
	local frame = frameColor or Palette.Gold
	local glass = glassColor or Palette.DeepGlass
	local transparency = glassTransparency or 0.18
	LuxuryKit.part(
		parent,
		name .. "FrameTop",
		Vector3.new(width + 0.5, 0.35, 0.4),
		cframe * CFrame.new(0, height / 2, -0.05),
		frame,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "FrameBottom",
		Vector3.new(width + 0.5, 0.2, 0.4),
		cframe * CFrame.new(0, -height / 2, -0.05),
		frame,
		Enum.Material.Metal
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			parent,
			name .. "FrameSide",
			Vector3.new(0.35, height + 0.5, 0.4),
			cframe * CFrame.new(side * (width / 2 + 0.05), 0, -0.05),
			frame,
			Enum.Material.Metal
		)
		LuxuryKit.part(
			parent,
			name .. "GlassPanel",
			Vector3.new(width / 2 - 0.2, height - 0.35, 0.1),
			cframe * CFrame.new(side * width / 4, 0, 0),
			glass,
			Enum.Material.Glass,
			transparency,
			false
		)
		LuxuryKit.verticalCylinder(
			parent,
			name .. "Handle",
			0.8,
			0.09,
			(cframe * CFrame.new(side * 0.35, 0, -0.18)).Position,
			frame,
			Enum.Material.Metal
		)
	end
	LuxuryKit.part(
		parent,
		name .. "CenterMullion",
		Vector3.new(0.16, height, 0.28),
		cframe * CFrame.new(0, 0, -0.05),
		frame,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "Transom",
		Vector3.new(width, 1.4, 0.12),
		cframe * CFrame.new(0, height / 2 + 1.05, 0),
		glass,
		Enum.Material.Glass,
		0.2,
		false
	)
	LuxuryKit.part(
		parent,
		name .. "TransomFrame",
		Vector3.new(width + 0.4, 0.2, 0.3),
		cframe * CFrame.new(0, height / 2 + 1.8, -0.05),
		frame,
		Enum.Material.Metal
	)
end

function LuxuryKit.planter(parent, name, center, width, depth, height, color, accent)
	local box = LuxuryKit.part(
		parent,
		name,
		Vector3.new(width, height, depth),
		CFrame.new(center.X, center.Y + height / 2, center.Z),
		color or Palette.Stone,
		Enum.Material.Marble
	)
	box.CanCollide = true
	LuxuryKit.part(
		parent,
		name .. "Rim",
		Vector3.new(width + 0.25, 0.18, depth + 0.25),
		CFrame.new(center.X, center.Y + height, center.Z),
		accent or Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "Soil",
		Vector3.new(width - 0.35, 0.12, depth - 0.35),
		CFrame.new(center.X, center.Y + height + 0.12, center.Z),
		Color3.fromRGB(67, 48, 36),
		Enum.Material.Ground
	)
	local count = math.max(2, math.floor(width / 2))
	for index = 1, count do
		local x = center.X - width / 2 + (width / (count + 1)) * index
		LuxuryKit.ball(
			parent,
			name .. "Shrub",
			Vector3.new(width / count * 1.2, height * 0.75, depth * 0.75),
			Vector3.new(x, center.Y + height + height * 0.38, center.Z),
			Palette.Leaf,
			Enum.Material.LeafyGrass
		)
	end
end

function LuxuryKit.hedge(parent, name, center, length, height, depth, color)
	local hedge = LuxuryKit.part(
		parent,
		name,
		Vector3.new(length, height, depth),
		CFrame.new(center.X, center.Y + height / 2, center.Z),
		color or Palette.Green,
		Enum.Material.LeafyGrass
	)
	hedge.CanCollide = true
	local count = math.max(2, math.floor(length / 1.8))
	for index = 1, count do
		local x = center.X - length / 2 + (length / (count + 1)) * index
		LuxuryKit.ball(
			parent,
			name .. "Crown",
			Vector3.new(length / count * 1.3, height * 0.45, depth * 1.15),
			Vector3.new(x, center.Y + height * 0.98, center.Z),
			index % 2 == 0 and Palette.Green or Palette.Leaf,
			Enum.Material.LeafyGrass
		)
	end
end

function LuxuryKit.tree(parent, name, base, scale, variant)
	scale = scale or 1
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local trunkHeight = 7.5 * scale
	local segments = 3
	for index = 1, segments do
		local segmentHeight = trunkHeight / segments
		local diameter = (1.35 - index * 0.22) * scale
		local y = base.Y + segmentHeight * (index - 0.5)
		local offsetX = (index - 1) * 0.12 * scale
		LuxuryKit.verticalCylinder(
			model,
			"Trunk",
			segmentHeight + 0.1,
			diameter,
			Vector3.new(base.X + offsetX, y, base.Z),
			Palette.Wood,
			Enum.Material.Wood
		)
		LuxuryKit.ball(
			model,
			"TrunkJoint",
			Vector3.new(diameter, diameter, diameter),
			Vector3.new(base.X + offsetX, base.Y + segmentHeight * index, base.Z),
			Palette.Wood,
			Enum.Material.Wood
		)
	end

	local canopyCenter = Vector3.new(base.X + 0.3 * scale, base.Y + trunkHeight + 2.2 * scale, base.Z)
	local lobes = {
		{ Vector3.new(0, 1.4, 0), 8.4, Palette.DarkGreen },
		{ Vector3.new(-2.4, 0.4, -1.2), 6.2, Palette.Green },
		{ Vector3.new(2.6, 0.6, -0.8), 6.6, Palette.Green },
		{ Vector3.new(-1.4, 0.2, 2.2), 6.0, Palette.Leaf },
		{ Vector3.new(1.8, 0.3, 2.0), 5.8, Palette.Leaf },
		{ Vector3.new(0, 2.8, 0.4), 5.6, Palette.DarkGreen },
	}
	for index, lobe in ipairs(lobes) do
		local position = canopyCenter + lobe[1] * scale
		local size = lobe[2] * scale
		LuxuryKit.ball(
			model,
			"Canopy" .. index,
			Vector3.new(size, size * 0.85, size),
			position,
			lobe[3],
			Enum.Material.LeafyGrass
		)
	end

	for _, offset in ipairs({
		Vector3.new(-2.2, 0, -0.8),
		Vector3.new(2.1, 0, 0.6),
		Vector3.new(0.4, 0, 2.1),
	}) do
		LuxuryKit.horizontalCylinder(
			model,
			"Branch",
			3.2 * scale,
			0.32 * scale,
			CFrame.new(base.X + offset.X * scale, base.Y + trunkHeight - 0.6 * scale, base.Z + offset.Z * scale)
				* CFrame.Angles(0, math.atan2(offset.Z, offset.X), math.rad(90))
				* CFrame.Angles(0, 0, math.rad(38)),
			Palette.Wood,
			Enum.Material.Wood
		)
	end

	if variant == "flowering" then
		local rng = Random.new(math.floor(base.X * 7 + base.Z * 13))
		for _ = 1, 18 do
			local angle = rng:NextNumber(0, math.pi * 2)
			local radius = rng:NextNumber(1.5, 4.5) * scale
			LuxuryKit.ball(
				model,
				"Blossom",
				Vector3.new(0.55, 0.55, 0.55) * scale,
				canopyCenter
					+ Vector3.new(math.cos(angle) * radius, rng:NextNumber(-1.5, 2.5) * scale, math.sin(angle) * radius),
				Color3.fromRGB(238, 160, 186),
				Enum.Material.SmoothPlastic
			)
		end
	end

	return model
end

function LuxuryKit.palm(parent, name, base, scale, variant)
	scale = scale or 1
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local trunkHeight = 11 * scale
	local segments = 5
	local top = base
	for index = 1, segments do
		local segmentHeight = trunkHeight / segments
		local lean = (index - 1) * 0.35 * scale
		local diameter = (1.25 - index * 0.12) * scale
		local y = base.Y + segmentHeight * (index - 0.5)
		top = Vector3.new(base.X + lean, y, base.Z + lean * 0.35)
		LuxuryKit.verticalCylinder(
			model,
			"Trunk",
			segmentHeight + 0.12,
			diameter,
			top,
			Palette.Teak,
			Enum.Material.Wood
		)
		LuxuryKit.ball(
			model,
			"TrunkJoint",
			Vector3.new(diameter * 1.08, diameter * 1.08, diameter * 1.08),
			Vector3.new(top.X, base.Y + segmentHeight * index, top.Z),
			Palette.Teak,
			Enum.Material.Wood
		)
	end

	local crown = Vector3.new(base.X + (segments - 1) * 0.35 * scale, base.Y + trunkHeight, base.Z + (segments - 1) * 0.12 * scale)
	LuxuryKit.ball(
		model,
		"Crown",
		Vector3.new(2.2 * scale, 1.6 * scale, 2.2 * scale),
		crown,
		Palette.DarkGreen,
		Enum.Material.LeafyGrass
	)
	for index = 0, 9 do
		local angle = math.rad(index * 36 + (variant == "beach" and 18 or 0))
		local length = (7.4 + (index % 3) * 0.6) * scale
		local frond = LuxuryKit.part(
			model,
			"Frond",
			Vector3.new(0.34 * scale, 0.16 * scale, length),
			CFrame.new(crown)
				* CFrame.Angles(0, angle, 0)
				* CFrame.new(0, -0.25 * scale, -length * 0.42)
				* CFrame.Angles(math.rad(-22 - (index % 4) * 5), 0, 0),
			index % 2 == 0 and Palette.Green or Palette.Leaf,
			Enum.Material.LeafyGrass,
			0,
			false
		)
		frond.CastShadow = true
	end
	for index = 1, 3 do
		local angle = math.rad(index * 120)
		LuxuryKit.ball(
			model,
			"Coconut",
			Vector3.new(0.75, 0.75, 0.75) * scale,
			crown + Vector3.new(math.cos(angle) * 0.9 * scale, -0.7 * scale, math.sin(angle) * 0.9 * scale),
			Color3.fromRGB(92, 66, 42),
			Enum.Material.Wood
		)
	end

	if variant == "beach" then
		LuxuryKit.ball(
			model,
			"SandMound",
			Vector3.new(5.5 * scale, 0.6 * scale, 5.5 * scale),
			Vector3.new(base.X, base.Y + 0.1, base.Z),
			Palette.Sand,
			Enum.Material.Sand
		)
	end

	return model
end

function LuxuryKit.bench(parent, name, cframe, color, accent)
	local wood = color or Palette.Teak
	local metal = accent or Palette.Gold
	local seatY = 1.25
	for index = -1, 1 do
		LuxuryKit.part(
			parent,
			name .. "Seat",
			Vector3.new(6, 0.14, 0.56),
			cframe * CFrame.new(0, seatY, index * 0.62),
			wood,
			Enum.Material.WoodPlanks
		)
	end
	for index = 0, 2 do
		LuxuryKit.part(
			parent,
			name .. "Back",
			Vector3.new(6, 0.14, 0.5),
			cframe * CFrame.new(0, 1.85 + index * 0.48, 0.82),
			wood,
			Enum.Material.WoodPlanks
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			parent,
			name .. "Leg",
			Vector3.new(0.3, 1.2, 1.9),
			cframe * CFrame.new(side * 2.55, 0.6, 0),
			metal,
			Enum.Material.Metal
		)
		LuxuryKit.part(
			parent,
			name .. "Arm",
			Vector3.new(0.3, 0.16, 2.1),
			cframe * CFrame.new(side * 2.95, 1.75, 0.05),
			metal,
			Enum.Material.Metal
		)
	end
end

function LuxuryKit.streetLamp(parent, name, base, height, color)
	local metal = color or Palette.Charcoal
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Base",
		0.55,
		1.5,
		Vector3.new(base.X, base.Y + 0.275, base.Z),
		Palette.GoldDark,
		Enum.Material.Metal
	)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Pole",
		height,
		0.42,
		Vector3.new(base.X, base.Y + height / 2, base.Z),
		metal,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "Arm",
		Vector3.new(2.2, 0.16, 0.16),
		CFrame.new(base.X + 0.9, base.Y + height, base.Z),
		metal,
		Enum.Material.Metal
	)
	local lanternPosition = Vector3.new(base.X + 1.9, base.Y + height - 0.15, base.Z)
	LuxuryKit.part(
		parent,
		name .. "LanternGlass",
		Vector3.new(1.35, 1.8, 1.35),
		CFrame.new(lanternPosition),
		Palette.Glass,
		Enum.Material.Glass,
		0.35,
		false
	)
	local core = LuxuryKit.neon(
		parent,
		"StreetLight",
		Vector3.new(0.65, 0.9, 0.65),
		CFrame.new(lanternPosition),
		Palette.NeonWarm
	)
	LuxuryKit.part(
		parent,
		name .. "LanternCap",
		Vector3.new(1.7, 0.22, 1.7),
		CFrame.new(lanternPosition.X, lanternPosition.Y + 1, lanternPosition.Z),
		Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.ball(
		parent,
		name .. "Finial",
		Vector3.new(0.45, 0.45, 0.45),
		Vector3.new(lanternPosition.X, lanternPosition.Y + 1.3, lanternPosition.Z),
		Palette.Gold,
		Enum.Material.Metal
	)
	local light = LuxuryKit.pointLight(core, "NightLamp", Palette.NeonWarm, 34, 2.2)
	light.Enabled = false
end

function LuxuryKit.fountain(parent, name, center, radius, accent)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Basin",
		0.9,
		radius * 2,
		Vector3.new(center.X, center.Y + 0.45, center.Z),
		Palette.Marble,
		Enum.Material.Marble
	)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Water",
		0.14,
		radius * 1.82,
		Vector3.new(center.X, center.Y + 0.92, center.Z),
		Palette.Aqua,
		Enum.Material.Glass,
		0.28,
		false
	)
	LuxuryKit.verticalCylinder(
		parent,
		"FountainColumn",
		3.4,
		1.25,
		Vector3.new(center.X, center.Y + 2.6, center.Z),
		Palette.Marble,
		Enum.Material.Marble
	)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "UpperBowl",
		0.4,
		4.2,
		Vector3.new(center.X, center.Y + 4.35, center.Z),
		Palette.Marble,
		Enum.Material.Marble
	)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "UpperWater",
		0.1,
		3.8,
		Vector3.new(center.X, center.Y + 4.6, center.Z),
		Palette.Aqua,
		Enum.Material.Glass,
		0.25,
		false
	)
	LuxuryKit.ball(
		parent,
		name .. "Finial",
		Vector3.new(1.1, 1.1, 1.1),
		Vector3.new(center.X, center.Y + 5.3, center.Z),
		accent or Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.neon(
		parent,
		name .. "Glow",
		Vector3.new(0.25, 3.6, 0.25),
		CFrame.new(center.X, center.Y + 2.6, center.Z),
		Palette.NeonCool
	)
end

function LuxuryKit.loungeChair(parent, name, cframe, cushionColor, frameColor)
	LuxuryKit.part(
		parent,
		name .. "Frame",
		Vector3.new(2.2, 0.3, 5.2),
		cframe * CFrame.new(0, 0.75, 0),
		frameColor or Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.part(
		parent,
		name .. "Cushion",
		Vector3.new(2.0, 0.28, 4.8),
		cframe * CFrame.new(0, 0.95, 0),
		cushionColor or Palette.Fabric,
		Enum.Material.Fabric
	)
	LuxuryKit.part(
		parent,
		name .. "Backrest",
		Vector3.new(2.0, 0.25, 2.2),
		cframe * CFrame.new(0, 1.55, 1.7) * CFrame.Angles(math.rad(-35), 0, 0),
		cushionColor or Palette.Fabric,
		Enum.Material.Fabric
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			parent,
			name .. "Leg",
			Vector3.new(0.18, 0.8, 0.18),
			cframe * CFrame.new(side * 0.9, 0.4, -2.1),
			frameColor or Palette.Gold,
			Enum.Material.Metal
		)
		LuxuryKit.part(
			parent,
			name .. "Leg",
			Vector3.new(0.18, 0.8, 0.18),
			cframe * CFrame.new(side * 0.9, 0.4, 2.1),
			frameColor or Palette.Gold,
			Enum.Material.Metal
		)
	end
end

function LuxuryKit.umbrella(parent, name, base, height, radius, color)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Pole",
		height,
		0.22,
		Vector3.new(base.X, base.Y + height / 2, base.Z),
		Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.ball(
		parent,
		name .. "Canopy",
		Vector3.new(radius * 2, radius * 0.55, radius * 2),
		Vector3.new(base.X, base.Y + height, base.Z),
		color or Palette.Ivory,
		Enum.Material.Fabric
	)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Valance",
		0.35,
		radius * 1.9,
		Vector3.new(base.X, base.Y + height - radius * 0.2, base.Z),
		color or Palette.Ivory,
		Enum.Material.Fabric
	)
	LuxuryKit.ball(
		parent,
		name .. "Finial",
		Vector3.new(0.4, 0.4, 0.4),
		Vector3.new(base.X, base.Y + height + radius * 0.3, base.Z),
		Palette.Gold,
		Enum.Material.Metal
	)
end

function LuxuryKit.cabana(parent, name, cframe, width, depth, height, color)
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			LuxuryKit.part(
				parent,
				name .. "Post",
				Vector3.new(0.28, height, 0.28),
				cframe * CFrame.new(x * width / 2, height / 2, z * depth / 2),
				Palette.Gold,
				Enum.Material.Metal
			)
		end
	end
	LuxuryKit.part(
		parent,
		name .. "Roof",
		Vector3.new(width + 1.2, 0.28, depth + 1.2),
		cframe * CFrame.new(0, height, 0),
		color or Palette.Ivory,
		Enum.Material.Fabric
	)
	for _, side in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			parent,
			name .. "Curtain",
			Vector3.new(0.12, height * 0.8, depth * 0.55),
			cframe * CFrame.new(side * (width / 2 - 0.1), height * 0.45, 0),
			color or Palette.Ivory,
			Enum.Material.Fabric,
			0.25,
			false
		)
	end
	LuxuryKit.part(
		parent,
		name .. "Daybed",
		Vector3.new(width * 0.72, 0.45, depth * 0.6),
		cframe * CFrame.new(0, 0.5, 0),
		Palette.Fabric,
		Enum.Material.Fabric
	)
	LuxuryKit.part(
		parent,
		name .. "DaybedBase",
		Vector3.new(width * 0.76, 0.4, depth * 0.64),
		cframe * CFrame.new(0, 0.2, 0),
		Palette.Teak,
		Enum.Material.WoodPlanks
	)
end

function LuxuryKit.pergola(parent, name, center, width, depth, height, color)
	local postColor = color or Palette.Wood
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			LuxuryKit.verticalCylinder(
				parent,
				name .. "Post",
				height,
				0.42,
				Vector3.new(center.X + x * width / 2, center.Y + height / 2, center.Z + z * depth / 2),
				postColor,
				Enum.Material.Wood
			)
		end
	end
	for _, z in ipairs({ -1, 1 }) do
		LuxuryKit.part(
			parent,
			name .. "Beam",
			Vector3.new(width + 0.8, 0.32, 0.35),
			CFrame.new(center.X, center.Y + height, center.Z + z * depth / 2),
			postColor,
			Enum.Material.Wood
		)
	end
	local slats = math.max(3, math.floor(width / 1.5))
	for index = 0, slats do
		local x = center.X - width / 2 + (width / slats) * index
		LuxuryKit.part(
			parent,
			name .. "Slat",
			Vector3.new(0.16, 0.2, depth + 0.8),
			CFrame.new(x, center.Y + height + 0.22, center.Z),
			postColor,
			Enum.Material.Wood
		)
	end
	for index = 1, 6 do
		local x = center.X - width / 2 + (width / 6) * index
		LuxuryKit.ball(
			parent,
			name .. "Vine",
			Vector3.new(1.4, 0.8, 1.4),
			Vector3.new(x, center.Y + height + 0.45, center.Z + depth / 2),
			Palette.Green,
			Enum.Material.LeafyGrass
		)
	end
end

function LuxuryKit.flag(parent, name, base, height, color)
	LuxuryKit.verticalCylinder(
		parent,
		name .. "Pole",
		height,
		0.18,
		Vector3.new(base.X, base.Y + height / 2, base.Z),
		Palette.Gold,
		Enum.Material.Metal
	)
	LuxuryKit.ball(
		parent,
		name .. "Finial",
		Vector3.new(0.35, 0.35, 0.35),
		Vector3.new(base.X, base.Y + height + 0.1, base.Z),
		Palette.Gold,
		Enum.Material.Metal
	)
	local flag = LuxuryKit.part(
		parent,
		name .. "Cloth",
		Vector3.new(0.08, 1.8, 3.6),
		CFrame.new(base.X + 1.85, base.Y + height - 1.0, base.Z),
		color or Palette.Burgundy,
		Enum.Material.Fabric,
		0,
		false
	)
	flag.CastShadow = true
end

function LuxuryKit.stringLights(parent, name, startPosition, endPosition, sag, color)
	local count = 18
	for index = 0, count do
		local alpha = index / count
		local position = startPosition:Lerp(endPosition, alpha)
		position -= Vector3.new(0, math.sin(math.pi * alpha) * sag, 0)
		LuxuryKit.ball(
			parent,
			name,
			Vector3.new(0.32, 0.32, 0.32),
			position,
			color or Palette.NeonWarm,
			Enum.Material.Neon
		)
	end
end

function LuxuryKit.yacht(parent, name, baseCFrame, scale)
	scale = scale or 1
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local function add(namePart, size, offset, color, material, shape)
		return LuxuryKit.shapePart(
			model,
			namePart,
			size * scale,
			baseCFrame * CFrame.new(offset * scale),
			shape or Enum.PartType.Block,
			color,
			material
		)
	end

	add("Hull", Vector3.new(14, 3, 42), Vector3.new(0, 1.5, 0), Palette.Ivory, Enum.Material.SmoothPlastic)
	add("HullStripe", Vector3.new(14.2, 0.35, 42.2), Vector3.new(0, 2.1, 0), Palette.Gold, Enum.Material.Metal)
	add("LowerHull", Vector3.new(13.4, 1.6, 40), Vector3.new(0, 0.1, 0), Palette.Navy, Enum.Material.SmoothPlastic)
	add("Bow", Vector3.new(13.8, 2.8, 6), Vector3.new(0, 1.5, -23), Palette.Ivory, Enum.Material.SmoothPlastic, Enum.PartType.Wedge)
	add("MainDeck", Vector3.new(12.6, 0.4, 38), Vector3.new(0, 3.15, 0), Palette.Teak, Enum.Material.WoodPlanks)
	add("Cabin", Vector3.new(10.5, 5, 20), Vector3.new(0, 5.8, 2), Palette.Ivory, Enum.Material.SmoothPlastic)
	add("CabinGlass", Vector3.new(10.7, 2.2, 14), Vector3.new(0, 6.3, 2), Palette.DeepGlass, Enum.Material.Glass)
	add("UpperDeck", Vector3.new(9.4, 0.4, 14), Vector3.new(0, 8.5, 2), Palette.Teak, Enum.Material.WoodPlanks)
	add("UpperCabin", Vector3.new(8.2, 3.2, 8), Vector3.new(0, 10.3, 2), Palette.Ivory, Enum.Material.SmoothPlastic)
	add("UpperGlass", Vector3.new(8.4, 1.5, 6), Vector3.new(0, 10.5, 2), Palette.DeepGlass, Enum.Material.Glass)
	add("Roof", Vector3.new(9.6, 0.4, 11), Vector3.new(0, 12.1, 2), Palette.Ivory, Enum.Material.SmoothPlastic)
	add("RadarArch", Vector3.new(0.4, 3, 0.4), Vector3.new(-3.2, 13.4, 2), Palette.Gold, Enum.Material.Metal)
	add("RadarArch", Vector3.new(0.4, 3, 0.4), Vector3.new(3.2, 13.4, 2), Palette.Gold, Enum.Material.Metal)
	add("RadarBar", Vector3.new(7, 0.3, 0.3), Vector3.new(0, 14.8, 2), Palette.Gold, Enum.Material.Metal)
	add("RadarDish", Vector3.new(2.2, 0.25, 2.2), Vector3.new(0, 15.1, 2), Palette.Ivory, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)

	for _, side in ipairs({ -1, 1 }) do
		add("DeckRail", Vector3.new(0.18, 1.4, 36), Vector3.new(side * 6.1, 4.0, 0), Palette.Gold, Enum.Material.Metal)
		add("UpperRail", Vector3.new(0.18, 1.2, 13), Vector3.new(side * 4.5, 9.4, 2), Palette.Gold, Enum.Material.Metal)
		for index = -3, 3 do
			add("Window", Vector3.new(0.16, 1.2, 1.8), Vector3.new(side * 5.26, 6.4, 2 + index * 2.4), Palette.DeepGlass, Enum.Material.Glass)
		end
	end

	add("SwimPlatform", Vector3.new(9, 0.35, 3), Vector3.new(0, 2.9, 23), Palette.Teak, Enum.Material.WoodPlanks)
	add("Jacuzzi", Vector3.new(4.2, 0.8, 4.2), Vector3.new(0, 12.6, 2), Palette.Aqua, Enum.Material.Glass)
	add("JacuzziRim", Vector3.new(4.8, 0.2, 4.8), Vector3.new(0, 12.9, 2), Palette.Gold, Enum.Material.Metal)
	add("FlagPole", Vector3.new(0.18, 4, 0.18), Vector3.new(0, 14.3, 22), Palette.Gold, Enum.Material.Metal)
	add("Flag", Vector3.new(0.08, 1.6, 2.8), Vector3.new(1.5, 15.6, 22), Palette.Burgundy, Enum.Material.Fabric)
	add("Nameplate", Vector3.new(4, 0.8, 0.12), Vector3.new(0, 2.8, 21.2), Palette.Gold, Enum.Material.Metal)

	return model
end

return LuxuryKit
