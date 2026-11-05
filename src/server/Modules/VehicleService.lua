local EconomyService = require(script.Parent.EconomyService)
local AchievementService = require(script.Parent.AchievementService)

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local catalog = require(Shared:WaitForChild("VehicleCatalog"))

local VehicleService = {}

local paintCatalog = {
	{ Id = "midnight", Name = "Azul meia-noite", Color = Color3.fromRGB(35, 44, 58) },
	{ Id = "pearl", Name = "Pérola", Color = Color3.fromRGB(226, 224, 214) },
	{ Id = "ruby", Name = "Rubi", Color = Color3.fromRGB(111, 40, 48) },
	{ Id = "emerald", Name = "Esmeralda", Color = Color3.fromRGB(42, 94, 70) },
	{ Id = "silver", Name = "Prata", Color = Color3.fromRGB(142, 151, 160) },
	{ Id = "sapphire", Name = "Safira", Color = Color3.fromRGB(44, 86, 145) },
}

local paintById = {}
for _, paint in ipairs(paintCatalog) do
	paintById[paint.Id] = paint
end

local activeVehicles = {}
local lastControlAt = {}
local CONTROL_TIMEOUT = 0.6
local TEST_DRIVE_DURATION = Config.Vehicles.TestDriveDuration
local marinaWater
local testDriveResultRemote

local function isFiniteNumber(value)
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function findVehicle(vehicleId)
	for _, vehicle in ipairs(catalog) do
		if vehicle.Id == vehicleId then
			return vehicle
		end

		function VehicleService.Init(testDriveRemote)
			testDriveResultRemote = testDriveRemote
		end
	end

	return nil
end

local function applyVehiclePaint(vehicle, paintId)
	local paint = paintById[paintId] or paintById.midnight
	for _, descendant in ipairs(vehicle:GetDescendants()) do
		if
			descendant:IsA("BasePart")
			and (
				descendant.Name == "Chassis"
				or descendant.Name == "Hood"
				or descendant.Name == "RearDeck"
				or descendant.Name == "Hull"
				or descendant.Name == "Bow"
				or descendant.Name == "Frame"
				or descendant.Name == "FuelTank"
			)
		then
			descendant.Color = paint.Color
		end
	end
end

local function setBoatControls(vehicle, throttle, steer)
	local root = vehicle.PrimaryPart
	local propulsion = root and root:FindFirstChild("PropulsionForce")
	local steering = root and root:FindFirstChild("SteeringTorque")
	if
		not root
		or not propulsion
		or not propulsion:IsA("VectorForce")
		or not steering
		or not steering:IsA("Torque")
	then
		return
	end

	local mass = root.AssemblyMass
	propulsion.Force = root.CFrame.LookVector * throttle * mass * 34
	steering.Torque = Vector3.new(0, -steer * mass * 8, 0)
end

local function maintainBoatBuoyancy(vehicle)
	local root = vehicle.PrimaryPart
	local buoyancy = root and root:FindFirstChild("BuoyancyForce")
	if not root or not buoyancy or not buoyancy:IsA("VectorForce") then
		return
	end

	if not marinaWater or not marinaWater.Parent then
		local world = workspace:FindFirstChild("HighSocietyWorld")
		marinaWater = world and world:FindFirstChild("MarinaWater", true)
	end
	if not marinaWater or not marinaWater:IsA("BasePart") then
		buoyancy.Force = Vector3.zero
		return
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { vehicle }
	rayParams.IgnoreWater = false
	local origin = root.Position + Vector3.new(0, 4, 0)
	local waterHit = workspace:Raycast(origin, Vector3.new(0, -14, 0), rayParams)

	if not waterHit or waterHit.Instance ~= marinaWater then
		buoyancy.Force = Vector3.zero
		return
	end

	local waterSurfaceY = marinaWater.Position.Y + marinaWater.Size.Y / 2
	local heightError = math.clamp(waterSurfaceY + 0.9 - root.Position.Y, -12, 4)
	local verticalSpeed = math.clamp(root.AssemblyLinearVelocity.Y, -30, 30)
	local mass = root.AssemblyMass
	local force =
		math.clamp(mass * (workspace.Gravity + heightError * 12 - verticalSpeed * 4), 0, mass * workspace.Gravity * 2)
	buoyancy.Force = Vector3.new(0, force, 0)
end

local function setWheelSpeeds(vehicle, throttle, steer)
	local vehicleData = findVehicle(vehicle:GetAttribute("VehicleId"))
	local maxWheelSpeed = vehicleData and vehicleData.MaxWheelSpeed or 32
	for _, descendant in ipairs(vehicle:GetDescendants()) do
		if descendant:IsA("HingeConstraint") and descendant.ActuatorType == Enum.ActuatorType.Motor then
			local side = descendant:GetAttribute("DriveSide")
			if side ~= -1 and side ~= 1 then
				side = 0
			end

			descendant.AngularVelocity = throttle * maxWheelSpeed * (1 - side * steer * 0.45)
		end
	end
end

local function setMotorcycleControls(vehicle, throttle, steer)
	local vehicleData = findVehicle(vehicle:GetAttribute("VehicleId"))
	local maxWheelSpeed = vehicleData and vehicleData.MaxWheelSpeed or 36
	local root = vehicle.PrimaryPart
	local steering = root and root:FindFirstChild("SteeringTorque")
	for _, descendant in ipairs(vehicle:GetDescendants()) do
		if descendant:IsA("HingeConstraint") and descendant.ActuatorType == Enum.ActuatorType.Motor then
			local isDriven = descendant:GetAttribute("DrivenWheel") == true
			descendant.AngularVelocity = isDriven and throttle * maxWheelSpeed or 0
		end
	end
	if steering and steering:IsA("Torque") then
		local mass = root.AssemblyMass
		local uprightTorque = root.CFrame.UpVector:Cross(Vector3.yAxis) * mass * 12
		local angularVelocity = root.AssemblyAngularVelocity
		local dampingTorque = Vector3.new(angularVelocity.X, 0, angularVelocity.Z) * mass * 3
		steering.Torque = uprightTorque - dampingTorque + Vector3.new(0, -steer * mass * 5, 0)
	end
end

local function hasClearSpawnSpace(player, vehicle, spawnPoint)
	local character = player.Character
	local spawnOffset = vehicle.IsBoat and CFrame.new(0, 3, 0) or CFrame.new(0, 3, -8)
	local spawnCFrame = spawnPoint.CFrame * spawnOffset
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { spawnPoint }
	if character then
		table.insert(overlapParams.FilterDescendantsInstances, character)
	end
	overlapParams.MaxParts = 1
	overlapParams.RespectCanCollide = true

	local boxSize = vehicle.IsBoat and Vector3.new(15, 7, 28) or Vector3.new(13, 5, 17)
	local overlappingParts = workspace:GetPartBoundsInBox(spawnCFrame, boxSize, overlapParams)
	return #overlappingParts == 0
end

function VehicleService.GetCatalog()
	local result = {}
	for _, vehicle in ipairs(catalog) do
		table.insert(result, {
			Id = vehicle.Id,
			Name = vehicle.Name,
			Category = vehicle.Category,
			Price = vehicle.Price,
			Performance = vehicle.Performance,
			IsBoat = vehicle.IsBoat == true,
			IsMotorcycle = vehicle.IsMotorcycle == true,
		})
	end
	return result
end

function VehicleService.GetPaintCatalog()
	return paintCatalog
end

function VehicleService.GetOwnedVehicles(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	profile.vehicles = profile.vehicles or {}
	for _, vehicle in ipairs(catalog) do
		local ownedData = profile.vehicles[vehicle.Id]
		if ownedData then
			if type(ownedData) ~= "table" then
				ownedData = {
					Id = vehicle.Id,
					Name = vehicle.Name,
					Category = vehicle.Category,
				}
				profile.vehicles[vehicle.Id] = ownedData
			end
			if not paintById[ownedData.PaintId] then
				ownedData.PaintId = "midnight"
			end
		end
	end
	return profile.vehicles
end

function VehicleService.SetVehiclePaint(player, vehicleId, paintId)
	if typeof(vehicleId) ~= "string" or typeof(paintId) ~= "string" then
		return false, "Solicitação de pintura inválida"
	end

	local vehicle = findVehicle(vehicleId)
	local paint = paintById[paintId]
	if not vehicle or not paint then
		return false, "Veículo ou cor indisponível"
	end
	if vehicle.IsBoat then
		return false, "A pintura personalizada está disponível para os carros; a lancha já tem acabamento próprio"
	end

	local ownedVehicles, ownedError = VehicleService.GetOwnedVehicles(player)
	if not ownedVehicles then
		return false, ownedError
	end
	local ownedData = ownedVehicles[vehicle.Id]
	if not ownedData then
		return false, "Você não possui este veículo"
	end

	local activeVehicle = activeVehicles[player.UserId]
	if activeVehicle and activeVehicle.Parent then
		return false, "Guarde seu veículo antes de personalizá-lo"
	end

	ownedData.PaintId = paint.Id
	return true,
		{
			VehicleId = vehicle.Id,
			PaintId = paint.Id,
			PaintName = paint.Name,
			Message = vehicle.Name .. " personalizado na cor " .. paint.Name .. ".",
		}
end

function VehicleService.GetActiveVehicleId(player)
	local vehicle = activeVehicles[player.UserId]
	if not vehicle or not vehicle.Parent or vehicle:GetAttribute("OwnerUserId") ~= player.UserId then
		activeVehicles[player.UserId] = nil
		return nil
	end

	return vehicle:GetAttribute("VehicleId")
end

function VehicleService.GetActiveVehicleStatus(player)
	local vehicleId = VehicleService.GetActiveVehicleId(player)
	if not vehicleId then
		return nil
	end

	local vehicle = activeVehicles[player.UserId]
	return {
		Id = vehicleId,
		IsTestDrive = vehicle:GetAttribute("IsTestDrive") == true,
	}
end

function VehicleService.IsPlayerDrivingOwnedVehicle(player)
	local vehicle = activeVehicles[player.UserId]
	if not vehicle or not vehicle.Parent or vehicle:GetAttribute("OwnerUserId") ~= player.UserId then
		return false
	end

	local seat = vehicle:FindFirstChild("DriverSeat")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local vehicleData = findVehicle(vehicle:GetAttribute("VehicleId"))
	return vehicleData ~= nil
		and not vehicleData.IsBoat
		and not vehicleData.IsMotorcycle
		and vehicle:GetAttribute("IsTestDrive") ~= true
		and seat ~= nil
		and seat:IsA("VehicleSeat")
		and humanoid ~= nil
		and seat.Occupant == humanoid
end

function VehicleService.IsBoat(vehicleId)
	local vehicle = typeof(vehicleId) == "string" and findVehicle(vehicleId)
	return vehicle ~= nil and vehicle.IsBoat == true
end

function VehicleService.IsActiveBoat(player)
	local vehicle = activeVehicles[player.UserId]
	if not vehicle or not vehicle.Parent or vehicle:GetAttribute("OwnerUserId") ~= player.UserId then
		return false
	end
	return VehicleService.IsBoat(vehicle:GetAttribute("VehicleId"))
end

function VehicleService.PurchaseVehicle(player, vehicleId)
	if typeof(vehicleId) ~= "string" then
		return false, "Identificador de veículo inválido"
	end

	local vehicle = findVehicle(vehicleId)
	if not vehicle then
		return false, "Veículo não encontrado"
	end

	local profile = EconomyService.GetProfile(player)
	if not profile then
		return false, "Perfil do jogador ainda não foi carregado"
	end
	local activeVehicle = activeVehicles[player.UserId]
	if activeVehicle and activeVehicle.Parent and activeVehicle:GetAttribute("IsTestDrive") then
		return false, "Encerre seu test drive antes de comprar um veículo"
	end

	profile.vehicles = profile.vehicles or {}
	if profile.vehicles[vehicle.Id] then
		return false, "Você já possui este veículo"
	end

	local paid, reason = EconomyService.SpendCredits(player, vehicle.Price, {
		Type = "VehiclePurchase",
		VehicleId = vehicle.Id,
	})
	if not paid then
		return false, reason
	end

	profile.vehicles[vehicle.Id] = {
		Id = vehicle.Id,
		Name = vehicle.Name,
		Category = vehicle.Category,
		PurchasedAt = os.time(),
	}

	AchievementService.RecordMilestone(player, "VehiclePurchased")

	return true, {
		Id = vehicle.Id,
		Name = vehicle.Name,
		Category = vehicle.Category,
		Price = vehicle.Price,
	}
end

function VehicleService.SpawnVehicle(player, vehicleId, spawnPoint, isTestDrive)
	if typeof(vehicleId) ~= "string" then
		return false, "Identificador de veículo inválido"
	end

	local vehicle = findVehicle(vehicleId)
	if not vehicle then
		return false, "Veículo não encontrado"
	end

	local ownedVehicles
	if isTestDrive then
		if activeVehicles[player.UserId] and activeVehicles[player.UserId].Parent then
			return false, "Guarde seu veículo atual antes de iniciar um test drive"
		end
	else
		local ownedError
		ownedVehicles, ownedError = VehicleService.GetOwnedVehicles(player)
		if not ownedVehicles then
			return false, ownedError
		end
		if not ownedVehicles[vehicle.Id] then
			return false, "Você não possui este veículo"
		end
	end

	if not spawnPoint or not spawnPoint:IsA("BasePart") then
		return false, "Ponto de spawn do veículo não encontrado"
	end
	local existing = activeVehicles[player.UserId]
	if existing and existing.Parent then
		return false, "Você já tem um veículo retirado"
	end
	activeVehicles[player.UserId] = nil
	if not hasClearSpawnSpace(player, vehicle, spawnPoint) then
		return false, "O ponto de saída está bloqueado. Libere o espaço e tente novamente"
	end

	local modelsFolder = ServerStorage:FindFirstChild("VehicleModels")
	local template = modelsFolder and modelsFolder:FindFirstChild(vehicle.ModelName)
	if not template or not template:IsA("Model") then
		return false, string.format("Modelo %s não encontrado em ServerStorage.VehicleModels", vehicle.ModelName)
	end

	local hasPart = false
	for _, descendant in ipairs(template:GetDescendants()) do
		if descendant:IsA("BasePart") then
			hasPart = true
			break
		end
	end
	if not hasPart then
		return false, "O modelo do veículo não contém peças físicas"
	end

	local clone = template:Clone()
	clone:SetAttribute("OwnerUserId", player.UserId)
	clone:SetAttribute("VehicleId", vehicle.Id)
	clone:SetAttribute("IsTestDrive", isTestDrive == true)
	if ownedVehicles then
		applyVehiclePaint(clone, ownedVehicles[vehicle.Id].PaintId)
	end
	clone:PivotTo(spawnPoint.CFrame * (vehicle.IsBoat and CFrame.new(0, 3, 0) or CFrame.new(0, 3, -8)))
	clone.Parent = workspace

	local assemblyRoot = clone.PrimaryPart
	if not assemblyRoot then
		clone:Destroy()
		return false, "O modelo do veículo precisa definir uma PrimaryPart"
	end
	assemblyRoot:SetNetworkOwner(nil)

	activeVehicles[player.UserId] = clone
	if vehicle.IsBoat then
		maintainBoatBuoyancy(clone)
	end
	local testDriveExpiresAt = isTestDrive and (os.clock() + TEST_DRIVE_DURATION) or nil
	local seat = clone:FindFirstChild("DriverSeat")
	if seat and seat:IsA("VehicleSeat") then
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if not seat.Occupant then
				if vehicle.IsBoat then
					setBoatControls(clone, 0, 0)
				elseif vehicle.IsMotorcycle then
					setMotorcycleControls(clone, 0, 0)
				else
					setWheelSpeeds(clone, 0, 0)
				end
				lastControlAt[player.UserId] = nil
			end
		end)
	end
	lastControlAt[player.UserId] = nil

	task.spawn(function()
		while clone.Parent and activeVehicles[player.UserId] == clone do
			task.wait(0.25)
			if isTestDrive and os.clock() >= testDriveExpiresAt then
				clone:Destroy()
				if testDriveResultRemote and testDriveResultRemote.Parent and player.Parent == Players then
					testDriveResultRemote:FireClient(player, {
						Success = true,
						Ended = true,
						Message = "Seu test drive terminou. O veículo foi recolhido.",
					})
				end
				break
			end
			if vehicle.IsBoat then
				maintainBoatBuoyancy(clone)
			end
			local lastUpdate = lastControlAt[player.UserId]
			if lastUpdate and os.clock() - lastUpdate > CONTROL_TIMEOUT then
				if vehicle.IsBoat then
					setBoatControls(clone, 0, 0)
				elseif vehicle.IsMotorcycle then
					setMotorcycleControls(clone, 0, 0)
				else
					setWheelSpeeds(clone, 0, 0)
				end
				lastControlAt[player.UserId] = nil
			end
		end

		if activeVehicles[player.UserId] == clone then
			activeVehicles[player.UserId] = nil
		end
		lastControlAt[player.UserId] = nil
	end)

	return true, clone
end

function VehicleService.StartTestDrive(player, vehicleId, spawnPoint)
	local vehicle = typeof(vehicleId) == "string" and findVehicle(vehicleId)
	if not vehicle then
		return false, "Veículo não encontrado"
	end

	local success, result = VehicleService.SpawnVehicle(player, vehicle.Id, spawnPoint, true)
	if not success then
		return false, result
	end

	return true, {
		Id = vehicle.Id,
		Name = vehicle.Name,
		Duration = TEST_DRIVE_DURATION,
	}
end

function VehicleService.SetDriverControls(player, throttle, steer)
	if not isFiniteNumber(throttle) or not isFiniteNumber(steer) then
		return false, "Comandos do veículo inválidos"
	end

	local vehicle = activeVehicles[player.UserId]
	if not vehicle or not vehicle.Parent or vehicle:GetAttribute("OwnerUserId") ~= player.UserId then
		return false, "Nenhum veículo ativo para este jogador"
	end

	local seat = vehicle:FindFirstChild("DriverSeat")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not seat or not seat:IsA("VehicleSeat") or not humanoid or seat.Occupant ~= humanoid then
		return false, "O jogador não está no banco do motorista"
	end

	throttle = math.clamp(throttle, -1, 1)
	steer = math.clamp(steer, -1, 1)

	lastControlAt[player.UserId] = os.clock()
	local vehicleData = findVehicle(vehicle:GetAttribute("VehicleId"))
	if vehicleData and vehicleData.IsBoat then
		setBoatControls(vehicle, throttle, steer)
	elseif vehicleData and vehicleData.IsMotorcycle then
		setMotorcycleControls(vehicle, throttle, steer)
	else
		setWheelSpeeds(vehicle, throttle, steer)
	end

	return true
end

function VehicleService.DespawnVehicle(player)
	local vehicle = activeVehicles[player.UserId]
	if not vehicle or not vehicle.Parent then
		activeVehicles[player.UserId] = nil
		lastControlAt[player.UserId] = nil
		return false, "Você não tem um veículo retirado"
	end

	vehicle:Destroy()
	activeVehicles[player.UserId] = nil
	lastControlAt[player.UserId] = nil
	return true, "Veículo guardado na garagem"
end

return VehicleService
