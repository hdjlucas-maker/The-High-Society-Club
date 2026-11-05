local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("HSC")
local Logger = require(Shared:WaitForChild("Logger"))
local vehicleCatalog = require(Shared:WaitForChild("VehicleCatalog"))

local VehicleBuilder = {}

local SHOWROOM_NAME = "VehicleShowroom"
local GENERATED_VEHICLE_ID = "society_sedan"

local function findVehicleDefinition(vehicleId)
	for _, definition in ipairs(vehicleCatalog) do
		if definition.Id == vehicleId then
			return definition
		end
	end
	return nil
end

local baseVehicleDefinition = findVehicleDefinition(GENERATED_VEHICLE_ID)
assert(baseVehicleDefinition, "VehicleCatalog precisa definir society_sedan")
local boatDefinition = findVehicleDefinition("society_speedboat")
local motorcycleDefinition = findVehicleDefinition("society_roadster_bike")
assert(boatDefinition and boatDefinition.IsBoat, "VehicleCatalog precisa definir a lancha")
assert(motorcycleDefinition and motorcycleDefinition.IsMotorcycle, "VehicleCatalog precisa definir a motocicleta")

local COLORS = {
	Body = baseVehicleDefinition.BodyColor,
	Trim = baseVehicleDefinition.TrimColor,
	Glass = Color3.fromRGB(93, 143, 162),
	Tire = Color3.fromRGB(28, 29, 32),
	Metal = Color3.fromRGB(178, 181, 185),
	Light = Color3.fromRGB(255, 239, 195),
	TailLight = Color3.fromRGB(190, 53, 55),
}

local function createPart(parent, name, size, cframe, color, material, shape, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Shape = shape or Enum.PartType.Block
	part.Transparency = transparency or 0
	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function weldToChassis(chassis, part)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "BodyWeld"
	weld.Part0 = chassis
	weld.Part1 = part
	weld.Parent = chassis
	part.Massless = true
end

local function createDecoration(model, chassis, name, size, offset, color, material, shape, transparency)
	local part =
		createPart(model, name, size, chassis.CFrame * CFrame.new(offset), color, material, shape, transparency)
	part.CanCollide = false
	weldToChassis(chassis, part)
	return part
end

local function createDriveWheel(model, chassis, side, front)
	local z = front and -5 or 5
	local x = side * 4.95
	local wheel = createPart(
		model,
		front and (side < 0 and "FrontLeftWheel" or "FrontRightWheel")
			or (side < 0 and "RearLeftWheel" or "RearRightWheel"),
		Vector3.new(1.25, 2.2, 2.2),
		chassis.CFrame * CFrame.new(x, -0.45, z),
		COLORS.Tire,
		Enum.Material.Rubber,
		Enum.PartType.Cylinder
	)
	wheel.CustomPhysicalProperties = PhysicalProperties.new(1.5, 1.1, 0.05, 1, 1)

	local rim = createPart(
		model,
		"WheelRim",
		Vector3.new(1.28, 1.15, 1.15),
		wheel.CFrame,
		COLORS.Metal,
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	rim.CanCollide = false
	rim.Massless = true
	local rimWeld = Instance.new("WeldConstraint")
	rimWeld.Name = "RimWeld"
	rimWeld.Part0 = wheel
	rimWeld.Part1 = rim
	rimWeld.Parent = wheel

	local chassisAttachment = Instance.new("Attachment")
	chassisAttachment.Name = "WheelMount"
	chassisAttachment.Position = Vector3.new(x, -0.45, z)
	chassisAttachment.Parent = chassis

	local wheelAttachment = Instance.new("Attachment")
	wheelAttachment.Name = "WheelAxis"
	wheelAttachment.Parent = wheel

	local hinge = Instance.new("HingeConstraint")
	hinge.Name = "DriveMotor"
	hinge.Attachment0 = chassisAttachment
	hinge.Attachment1 = wheelAttachment
	hinge.ActuatorType = Enum.ActuatorType.Motor
	hinge.AngularVelocity = 0
	hinge.MotorMaxTorque = 12000
	hinge.MotorMaxAcceleration = 80
	hinge:SetAttribute("DriveSide", side)
	hinge.Parent = chassis

	return wheel
end

local function buildModel()
	local model = Instance.new("Model")
	model.Name = baseVehicleDefinition.ModelName

	local chassis =
		createPart(model, "Chassis", Vector3.new(8.5, 1.5, 15), CFrame.new(), COLORS.Body, Enum.Material.Metal)
	chassis.CustomPhysicalProperties = PhysicalProperties.new(2.5, 0.8, 0.05, 1, 1)
	chassis.RootPriority = 127
	model.PrimaryPart = chassis

	createDecoration(
		model,
		chassis,
		"LowerTrim",
		Vector3.new(8.8, 0.45, 14),
		Vector3.new(0, -0.85, 0),
		COLORS.Trim,
		Enum.Material.Metal
	)
	createDecoration(
		model,
		chassis,
		"Hood",
		Vector3.new(7.5, 0.7, 4.1),
		Vector3.new(0, 0.9, -5.15),
		COLORS.Body,
		Enum.Material.Metal
	)
	createDecoration(
		model,
		chassis,
		"RearDeck",
		Vector3.new(7.5, 0.7, 2.7),
		Vector3.new(0, 0.9, 5.3),
		COLORS.Body,
		Enum.Material.Metal
	)
	createDecoration(
		model,
		chassis,
		"Windshield",
		Vector3.new(6.25, 1.55, 0.22),
		Vector3.new(0, 2.0, -3.2),
		COLORS.Glass,
		Enum.Material.Glass,
		nil,
		0.2
	)
	createDecoration(
		model,
		chassis,
		"RearWindow",
		Vector3.new(6.1, 1.35, 0.22),
		Vector3.new(0, 2.0, 4.1),
		COLORS.Glass,
		Enum.Material.Glass,
		nil,
		0.2
	)

	for _, side in ipairs({ -1, 1 }) do
		createDecoration(
			model,
			chassis,
			"SideWindow",
			Vector3.new(0.2, 1.3, 5.2),
			Vector3.new(side * 3.35, 2.0, 0.45),
			COLORS.Glass,
			Enum.Material.Glass,
			nil,
			0.25
		)
		createDecoration(
			model,
			chassis,
			"DoorTrim",
			Vector3.new(0.22, 0.25, 5.8),
			Vector3.new(side * 4.3, 0.2, 0.3),
			COLORS.Trim,
			Enum.Material.Metal
		)
		createDriveWheel(model, chassis, side, true)
		createDriveWheel(model, chassis, side, false)
	end

	for _, side in ipairs({ -1, 1 }) do
		createDecoration(
			model,
			chassis,
			"Headlight",
			Vector3.new(1.8, 0.3, 0.18),
			Vector3.new(side * 2.6, 0.1, -7.58),
			COLORS.Light,
			Enum.Material.Neon
		)
		createDecoration(
			model,
			chassis,
			"TailLight",
			Vector3.new(1.8, 0.4, 0.18),
			Vector3.new(side * 2.6, 0.1, 7.58),
			COLORS.TailLight,
			Enum.Material.Neon
		)
	end

	createDecoration(
		model,
		chassis,
		"FrontGrille",
		Vector3.new(2.8, 0.65, 0.2),
		Vector3.new(0, -0.05, -7.62),
		COLORS.Metal,
		Enum.Material.Metal
	)

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 0.8, 2)
	seat.CFrame = chassis.CFrame * CFrame.new(0, 2.3, 1.1)
	seat.Color = COLORS.Trim
	seat.Material = Enum.Material.SmoothPlastic
	seat.Anchored = false
	seat.CanCollide = false
	seat.CanTouch = true
	seat.Massless = true
	seat.Parent = model
	weldToChassis(chassis, seat)

	return model
end

local function buildSpeedboat(vehicleFolder)
	local modelName = boatDefinition.ModelName
	local existing = vehicleFolder:FindFirstChild(modelName)
	if existing then
		if not existing:IsA("Model") then
			error(string.format("ServerStorage.VehicleModels.%s precisa ser um Model", modelName))
		end
		return existing
	end

	local model = Instance.new("Model")
	model.Name = modelName
	model:SetAttribute("VehicleType", "Boat")

	local hull =
		createPart(model, "Hull", Vector3.new(10, 2, 22), CFrame.new(), Color3.fromRGB(35, 44, 58), Enum.Material.Metal)
	hull.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.25, 0.1, 1, 1)
	hull.RootPriority = 127
	model.PrimaryPart = hull

	local function addBoatPart(name, size, offset, color, material, shape)
		local part = createPart(model, name, size, hull.CFrame * CFrame.new(offset), color, material, shape)
		part.CanCollide = false
		weldToChassis(hull, part)
		return part
	end

	addBoatPart(
		"Bow",
		Vector3.new(9.8, 1.8, 5),
		Vector3.new(0, 0.1, -8.5),
		Color3.fromRGB(35, 44, 58),
		Enum.Material.Metal,
		Enum.PartType.Wedge
	)
	addBoatPart(
		"Deck",
		Vector3.new(8.5, 0.3, 14),
		Vector3.new(0, 1.15, 2.5),
		Color3.fromRGB(218, 180, 91),
		Enum.Material.WoodPlanks
	)
	for _, side in ipairs({ -1, 1 }) do
		addBoatPart(
			"Rail",
			Vector3.new(0.35, 1.3, 16),
			Vector3.new(side * 4.7, 1.3, 1),
			Color3.fromRGB(224, 222, 209),
			Enum.Material.Metal
		)
		addBoatPart(
			"SeatBench",
			Vector3.new(7, 0.7, 1.3),
			Vector3.new(0, 1.7, 2.5),
			Color3.fromRGB(83, 112, 120),
			Enum.Material.Fabric
		)
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2.2, 0.8, 2)
	seat.CFrame = hull.CFrame * CFrame.new(0, 2.1, 5)
	seat.Color = Color3.fromRGB(83, 112, 120)
	seat.Material = Enum.Material.Fabric
	seat.Anchored = false
	seat.CanCollide = false
	seat.CanTouch = true
	seat.Massless = true
	seat.Parent = model
	weldToChassis(hull, seat)

	local attachment = Instance.new("Attachment")
	attachment.Name = "BoatForceAttachment"
	attachment.Parent = hull

	local propulsion = Instance.new("VectorForce")
	propulsion.Name = "PropulsionForce"
	propulsion.Attachment0 = attachment
	propulsion.RelativeTo = Enum.ActuatorRelativeTo.World
	propulsion.ApplyAtCenterOfMass = true
	propulsion.Parent = hull

	local buoyancy = Instance.new("VectorForce")
	buoyancy.Name = "BuoyancyForce"
	buoyancy.Attachment0 = attachment
	buoyancy.RelativeTo = Enum.ActuatorRelativeTo.World
	buoyancy.ApplyAtCenterOfMass = true
	buoyancy.Parent = hull

	local steering = Instance.new("Torque")
	steering.Name = "SteeringTorque"
	steering.Attachment0 = attachment
	steering.RelativeTo = Enum.ActuatorRelativeTo.World
	steering.Parent = hull

	model.Parent = vehicleFolder
	return model
end

local function buildMotorcycle(vehicleFolder)
	local modelName = motorcycleDefinition.ModelName
	local existing = vehicleFolder:FindFirstChild(modelName)
	if existing then
		if not existing:IsA("Model") then
			error(string.format("ServerStorage.VehicleModels.%s precisa ser um Model", modelName))
		end
		return existing
	end

	local model = Instance.new("Model")
	model.Name = modelName
	model:SetAttribute("VehicleType", "Motorcycle")

	local frame = createPart(
		model,
		"Frame",
		Vector3.new(2.4, 1, 6.5),
		CFrame.new(),
		Color3.fromRGB(35, 44, 58),
		Enum.Material.Metal
	)
	frame.CustomPhysicalProperties = PhysicalProperties.new(2.2, 0.7, 0.05, 1, 1)
	frame.RootPriority = 127
	model.PrimaryPart = frame

	local function addPart(name, size, offset, color, material, shape)
		local part = createPart(model, name, size, frame.CFrame * CFrame.new(offset), color, material, shape)
		part.CanCollide = false
		weldToChassis(frame, part)
		return part
	end

	addPart(
		"FuelTank",
		Vector3.new(2.2, 1.5, 2.8),
		Vector3.new(0, 1.1, -0.5),
		Color3.fromRGB(90, 43, 48),
		Enum.Material.Metal
	)
	addPart(
		"FrontFairing",
		Vector3.new(2.4, 2.4, 0.9),
		Vector3.new(0, 1.2, -2.35),
		Color3.fromRGB(90, 43, 48),
		Enum.Material.SmoothPlastic
	)
	addPart(
		"Handlebar",
		Vector3.new(4.2, 0.25, 0.3),
		Vector3.new(0, 2.25, -2.1),
		Color3.fromRGB(178, 181, 185),
		Enum.Material.Metal
	)
	addPart(
		"BikeSeat",
		Vector3.new(2, 0.55, 2.8),
		Vector3.new(0, 1.65, 1.45),
		Color3.fromRGB(35, 35, 38),
		Enum.Material.Fabric
	)
	addPart(
		"Headlight",
		Vector3.new(1.1, 1.1, 0.45),
		Vector3.new(0, 0.9, -2.9),
		COLORS.Light,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)

	for _, z in ipairs({ -3.2, 3.2 }) do
		local front = z < 0
		local wheel = createPart(
			model,
			front and "FrontWheel" or "RearWheel",
			Vector3.new(1.1, 2.3, 2.3),
			frame.CFrame * CFrame.new(0, -0.65, z),
			COLORS.Tire,
			Enum.Material.Rubber,
			Enum.PartType.Cylinder
		)
		wheel.CustomPhysicalProperties = PhysicalProperties.new(1.4, 1, 0.04, 1, 1)

		local mount = Instance.new("Attachment")
		mount.Name = "WheelMount"
		mount.Position = Vector3.new(0, -0.65, z)
		mount.Parent = frame

		local axis = Instance.new("Attachment")
		axis.Name = "WheelAxis"
		axis.Parent = wheel

		local hinge = Instance.new("HingeConstraint")
		hinge.Name = "DriveMotor"
		hinge.Attachment0 = mount
		hinge.Attachment1 = axis
		hinge.ActuatorType = Enum.ActuatorType.Motor
		hinge.AngularVelocity = 0
		hinge.MotorMaxTorque = 8500
		hinge.MotorMaxAcceleration = 65
		hinge:SetAttribute("DrivenWheel", not front)
		hinge.Parent = frame
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(1.8, 0.65, 1.8)
	seat.CFrame = frame.CFrame * CFrame.new(0, 2.15, 0.9)
	seat.Color = Color3.fromRGB(35, 35, 38)
	seat.Material = Enum.Material.Fabric
	seat.Anchored = false
	seat.CanCollide = false
	seat.CanTouch = true
	seat.Massless = true
	seat.Parent = model
	weldToChassis(frame, seat)

	local attachment = Instance.new("Attachment")
	attachment.Name = "MotorcycleForceAttachment"
	attachment.Parent = frame

	local steering = Instance.new("Torque")
	steering.Name = "SteeringTorque"
	steering.Attachment0 = attachment
	steering.RelativeTo = Enum.ActuatorRelativeTo.World
	steering.Parent = frame

	model.Parent = vehicleFolder
	return model
end

local function buildShowroom(template)
	local world = workspace:FindFirstChild("HighSocietyWorld")
	local boulevard = world and world:FindFirstChild("HighSocietyBoulevard")
	local gallery = boulevard and boulevard:FindFirstChild("AutomotiveGallery")
	local foundation = gallery and gallery:FindFirstChild("Foundation")
	if not gallery or not foundation or not foundation:IsA("BasePart") then
		Logger.Warn("VehicleBuilder", "Automotive Gallery sem Foundation; veículos de exposição não foram criados.")
		return
	end

	local showroom = gallery:FindFirstChild(SHOWROOM_NAME)
	if not showroom then
		showroom = Instance.new("Folder")
		showroom.Name = SHOWROOM_NAME
		showroom.Parent = gallery
	elseif not showroom:IsA("Folder") then
		error(
			"Workspace.HighSocietyWorld.HighSocietyBoulevard.AutomotiveGallery.VehicleShowroom precisa ser uma Folder"
		)
	end

	local displayVehicles = {}
	for _, definition in ipairs(vehicleCatalog) do
		if not definition.IsBoat and not definition.IsMotorcycle then
			table.insert(displayVehicles, definition)
		end
	end

	for index, definition in ipairs(displayVehicles) do
		local displayName = definition.ModelName .. "Display"
		local existing = showroom:FindFirstChild(displayName)
		if existing then
			if not existing:IsA("Model") then
				error(string.format("%s precisa ser um Model", existing:GetFullName()))
			end
			continue
		end

		local display = template:Clone()
		display.Name = displayName
		display:SetAttribute("DisplayOnly", true)
		display:SetAttribute("DisplayName", definition.Name)
		display:ScaleTo(definition.DisplayScale or 1)

		for _, descendant in ipairs(display:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if descendant.Name == "Chassis" or descendant.Name == "Hood" or descendant.Name == "RearDeck" then
					descendant.Color = definition.DisplayBodyColor or definition.BodyColor
				elseif descendant.Name == "LowerTrim" then
					descendant.Color = definition.TrimColor
				elseif descendant.Name == "DriverSeat" and descendant:IsA("VehicleSeat") then
					descendant.Disabled = true
				end
				descendant.Anchored = true
			end
		end

		local slot = index - (#displayVehicles + 1) / 2
		local position = foundation.Position
			+ Vector3.new(
				slot * 18,
				foundation.Size.Y / 2 + 1.55 * definition.DisplayScale + 0.1,
				-foundation.Size.Z / 2 - 11
			)
		display:PivotTo(CFrame.new(position))
		display.Parent = showroom
	end
end

local function buildMarinaShowroom(template)
	local world = workspace:FindFirstChild("HighSocietyWorld")
	local marina = world and world:FindFirstChild("ParadiseIslandAndRoyalMarina")
	local water = marina and marina:FindFirstChild("MarinaWater")
	if not marina or not water or not water:IsA("BasePart") then
		Logger.Warn("VehicleBuilder", "Royal Marina sem MarinaWater; lancha de exposição não foi criada.")
		return
	end

	local showroom = marina:FindFirstChild("BoatShowroom")
	if not showroom then
		showroom = Instance.new("Folder")
		showroom.Name = "BoatShowroom"
		showroom.Parent = marina
	elseif not showroom:IsA("Folder") then
		error("Workspace.HighSocietyWorld.ParadiseIslandAndRoyalMarina.BoatShowroom precisa ser uma Folder")
	end
	local displayName = boatDefinition.ModelName .. "Display"
	if showroom:FindFirstChild(displayName) then
		return
	end

	local display = template:Clone()
	display.Name = displayName
	display:SetAttribute("DisplayOnly", true)
	display:SetAttribute("DisplayName", boatDefinition.Name)
	for _, descendant in ipairs(display:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			if descendant:IsA("VehicleSeat") then
				descendant.Disabled = true
			end
		elseif descendant:IsA("VectorForce") or descendant:IsA("Torque") then
			descendant:Destroy()
		end
	end
	display:PivotTo(CFrame.new(222, water.Position.Y + 1.1, water.Position.Z))
	display.Parent = showroom
end

local function buildMotorcycleShowroom(template)
	local world = workspace:FindFirstChild("HighSocietyWorld")
	local boulevard = world and world:FindFirstChild("HighSocietyBoulevard")
	local gallery = boulevard and boulevard:FindFirstChild("AutomotiveGallery")
	local foundation = gallery and gallery:FindFirstChild("Foundation")
	if not gallery or not foundation or not foundation:IsA("BasePart") then
		Logger.Warn("VehicleBuilder", "Automotive Gallery sem Foundation; moto de exposição não foi criada.")
		return
	end

	local showroom = gallery:FindFirstChild(SHOWROOM_NAME)
	if not showroom or not showroom:IsA("Folder") then
		return
	end
	local displayName = motorcycleDefinition.ModelName .. "Display"
	if showroom:FindFirstChild(displayName) then
		return
	end

	local display = template:Clone()
	display.Name = displayName
	display:SetAttribute("DisplayOnly", true)
	display:SetAttribute("DisplayName", motorcycleDefinition.Name)
	for _, descendant in ipairs(display:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			if descendant:IsA("VehicleSeat") then
				descendant.Disabled = true
			end
		elseif descendant:IsA("Torque") then
			descendant:Destroy()
		end
	end
	display:PivotTo(
		CFrame.new(
			foundation.Position.X + 38,
			foundation.Position.Y + foundation.Size.Y / 2 + 2.2,
			foundation.Position.Z - foundation.Size.Z / 2 - 11
		)
	)
	display.Parent = showroom
end

local function buildPlayableVariants(vehicleFolder, template)
	for _, definition in ipairs(vehicleCatalog) do
		if definition.Id == GENERATED_VEHICLE_ID or definition.IsBoat or definition.IsMotorcycle then
			continue
		end

		local existing = vehicleFolder:FindFirstChild(definition.ModelName)
		if existing then
			if not existing:IsA("Model") then
				error(string.format("ServerStorage.VehicleModels.%s precisa ser um Model", definition.ModelName))
			end
			continue
		end

		local variant = template:Clone()
		variant.Name = definition.ModelName
		variant:ScaleTo(definition.PlayableScale or 1)
		variant:SetAttribute("VehicleType", definition.ModelName)

		for _, descendant in ipairs(variant:GetDescendants()) do
			if not descendant:IsA("BasePart") then
				continue
			end

			if descendant.Name == "Chassis" or descendant.Name == "Hood" or descendant.Name == "RearDeck" then
				descendant.Color = definition.BodyColor
			elseif descendant.Name == "LowerTrim" or descendant.Name == "DoorTrim" then
				descendant.Color = definition.TrimColor
			end
		end

		variant.Parent = vehicleFolder
	end
end

function VehicleBuilder.Init()
	local vehicleFolder = ServerStorage:FindFirstChild("VehicleModels")
	if not vehicleFolder then
		vehicleFolder = Instance.new("Folder")
		vehicleFolder.Name = "VehicleModels"
		vehicleFolder.Parent = ServerStorage
	elseif not vehicleFolder:IsA("Folder") then
		error("ServerStorage.VehicleModels precisa ser uma Folder")
	end

	local generatedName = baseVehicleDefinition.ModelName
	local existing = vehicleFolder:FindFirstChild(generatedName)
	if existing then
		if not existing:IsA("Model") then
			error(string.format("ServerStorage.VehicleModels.%s precisa ser um Model", generatedName))
		end
		buildPlayableVariants(vehicleFolder, existing)
		local speedboat = buildSpeedboat(vehicleFolder)
		local motorcycle = buildMotorcycle(vehicleFolder)
		buildShowroom(existing)
		buildMotorcycleShowroom(motorcycle)
		buildMarinaShowroom(speedboat)
		return existing
	end

	local model = buildModel()
	model.Parent = vehicleFolder
	buildPlayableVariants(vehicleFolder, model)
	local speedboat = buildSpeedboat(vehicleFolder)
	local motorcycle = buildMotorcycle(vehicleFolder)
	buildShowroom(model)
	buildMotorcycleShowroom(motorcycle)
	buildMarinaShowroom(speedboat)
	Logger.Info("VehicleBuilder", "Modelos de veículos preparados")
	return model
end

return VehicleBuilder
