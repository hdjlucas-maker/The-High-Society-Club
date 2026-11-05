local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyService = require(script.Parent.EconomyService)
local AchievementService = require(script.Parent.AchievementService)
local catalog = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("PropertyCatalog"))

local PropertyService = {}
local returnPositions = {}
local privateInteriors = {}
local pendingInvites = {}
local privateInteriorFolder
local nextPrivateSlot = 0
local resultRemote
local inviteReceivedRemote
local inviteResultRemote
local applyInteriorStyle
local applyInteriorDecor
local initialized = false
local interiorStyles = {
	classic = {
		Name = "Clássico",
		Walls = Color3.fromRGB(232, 229, 218),
		Accent = Color3.fromRGB(218, 180, 91),
		Furniture = Color3.fromRGB(112, 82, 59),
		Light = Color3.fromRGB(255, 235, 190),
	},
	ocean = {
		Name = "Oceano",
		Walls = Color3.fromRGB(198, 219, 224),
		Accent = Color3.fromRGB(48, 113, 139),
		Furniture = Color3.fromRGB(83, 112, 120),
		Light = Color3.fromRGB(216, 241, 255),
	},
	garden = {
		Name = "Jardim",
		Walls = Color3.fromRGB(220, 229, 210),
		Accent = Color3.fromRGB(79, 119, 81),
		Furniture = Color3.fromRGB(126, 91, 62),
		Light = Color3.fromRGB(245, 246, 210),
	},
}

local interiorDecorCatalog = {
	{ Id = "botanical", Name = "Jardim interno", Description = "Vasos e folhagens ornamentais" },
	{ Id = "gallery", Name = "Galeria", Description = "Quadros decorativos e detalhes dourados" },
	{ Id = "lounge", Name = "Lounge", Description = "Tapete e luminárias de apoio" },
}

local decorById = {}
for _, decor in ipairs(interiorDecorCatalog) do
	decorById[decor.Id] = decor
end

local function findProperty(propertyId)
	for _, property in ipairs(catalog) do
		if property.Id == propertyId then
			return property
		end
	end

	return nil
end

local function getPropertyId(model)
	local propertyId = model:GetAttribute("PropertyId")
	if type(propertyId) == "string" then
		return propertyId
	end

	local idValue = model:FindFirstChild("PropertyId")
	if idValue and idValue:IsA("StringValue") then
		return idValue.Value
	end
	return nil
end

local function getPropertyModels()
	local models = {}
	local world = workspace:FindFirstChild("HighSocietyWorld")
	local generatedDistrict = world and world:FindFirstChild("MillionaireDistrict")
	local legacyFolder = workspace:FindFirstChild("Properties")
	local folders = {}
	if generatedDistrict then
		table.insert(folders, generatedDistrict)
	end
	if legacyFolder then
		table.insert(folders, legacyFolder)
	end

	for _, folder in ipairs(folders) do
		for _, model in ipairs(folder:GetChildren()) do
			if model:IsA("Model") then
				table.insert(models, model)
			end
		end
	end

	return models
end

local function getPurchasePoint(model)
	for _, name in ipairs({ "PropertyPurchasePoint", "Base", "SpawnPoint" }) do
		local point = model:FindFirstChild(name)
		if point and point:IsA("BasePart") then
			return point
		end
	end
	return nil
end

local function ensurePrivateInteriorFolder()
	if privateInteriorFolder and privateInteriorFolder.Parent then
		return privateInteriorFolder
	end

	local folder = workspace:FindFirstChild("HSCPrivateInteriors")
	if folder and not folder:IsA("Folder") then
		error("Workspace.HSCPrivateInteriors precisa ser uma Folder")
	end
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "HSCPrivateInteriors"
		folder.Parent = workspace
	end

	privateInteriorFolder = folder
	return folder
end

local function destroyPrivateInterior(player)
	local record = privateInteriors[player.UserId]
	if record and record.Model and record.Model.Parent then
		record.Model:Destroy()
	end
	privateInteriors[player.UserId] = nil
end

local function countInteriorGuests(ownerUserId, propertyId)
	local count = 0
	for _, returnData in pairs(returnPositions) do
		if returnData.OwnerUserId == ownerUserId and returnData.PropertyId == propertyId then
			count += 1
		end
	end
	return count
end

local function returnInteriorGuests(owner, propertyId, reason)
	for userId, returnData in pairs(returnPositions) do
		if returnData.OwnerUserId == owner.UserId and returnData.PropertyId == propertyId then
			local guest = Players:GetPlayerByUserId(userId)
			local character = guest and guest.Character
			if character then
				character:PivotTo(returnData.CFrame)
			end
			returnPositions[userId] = nil
			if guest and inviteResultRemote and inviteResultRemote.Parent then
				inviteResultRemote:FireClient(guest, {
					Success = true,
					Message = reason or "A visita terminou e você voltou à cidade.",
				})
			end
		end
	end
end

local function cancelOwnerInvites(ownerUserId, reason)
	for guestUserId, invite in pairs(pendingInvites) do
		if invite.OwnerUserId == ownerUserId then
			pendingInvites[guestUserId] = nil
			local guest = Players:GetPlayerByUserId(guestUserId)
			if guest and inviteResultRemote and inviteResultRemote.Parent then
				inviteResultRemote:FireClient(guest, {
					Success = false,
					Message = reason,
				})
			end
		end
	end
end

local function isPlayerInsideInterior(player, returnData)
	if not returnData or returnData.OwnerUserId then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local model = returnData.Model
	if not root or not humanoid or humanoid.Health <= 0 or not model or not model.Parent then
		return false
	end

	local floor = model:FindFirstChild("InteriorFloor")
	if floor and floor:IsA("BasePart") then
		local localPosition = floor.CFrame:PointToObjectSpace(root.Position)
		return math.abs(localPosition.X) <= floor.Size.X / 2
			and math.abs(localPosition.Z) <= floor.Size.Z / 2
			and localPosition.Y >= -2
			and localPosition.Y <= 18
	end

	local spawnPoint = model:FindFirstChild("SpawnPoint")
	return spawnPoint ~= nil and spawnPoint:IsA("BasePart") and (root.Position - spawnPoint.Position).Magnitude <= 20
end

local function connectPrivateExitPrompt(model, propertyId)
	local spawnPoint = model:FindFirstChild("SpawnPoint")
	if not spawnPoint or not spawnPoint:IsA("BasePart") then
		error(string.format("%s precisa conter um SpawnPoint físico", model:GetFullName()))
	end

	local prompt = spawnPoint:FindFirstChild("PropertyExitPrompt")
	if prompt and not prompt:IsA("ProximityPrompt") then
		error(string.format("%s.PropertyExitPrompt precisa ser ProximityPrompt", spawnPoint:GetFullName()))
	end
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PropertyExitPrompt"
		prompt.Parent = spawnPoint
	end
	prompt.ActionText = "Sair"
	prompt.ObjectText = "Voltar para a cidade"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		local success, message = PropertyService.ReturnToCity(player, propertyId)
		if resultRemote and resultRemote.Parent then
			resultRemote:FireClient(player, {
				Success = success,
				PropertyId = propertyId,
				Message = message,
			})
		end
	end)
end

local function createPrivateInterior(player, propertyId, sourceModel)
	nextPrivateSlot += 1
	local model = sourceModel:Clone()
	model.Name = string.format("Interior_%d_%s", player.UserId, propertyId)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("PrivateOwnerUserId", player.UserId)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:GetAttribute("HSC_ExteriorOnly") then
			descendant:Destroy()
		elseif
			descendant:IsA("BaseScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("BindableEvent")
			or descendant:IsA("BindableFunction")
			or descendant:IsA("ProximityPrompt")
			or descendant.Name == "PropertyPurchasePoint"
			or descendant.Name == "PropertyPurchasePrompt"
		then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end

	local sourcePivot = sourceModel:GetPivot()
	local privateHeight = 1000 + nextPrivateSlot * 40
	model:PivotTo(CFrame.new(0, privateHeight - sourcePivot.Position.Y, 0) * sourcePivot)
	model.Parent = ensurePrivateInteriorFolder()
	applyInteriorStyle(model, "classic")
	connectPrivateExitPrompt(model, propertyId)

	privateInteriors[player.UserId] = {
		Model = model,
		PropertyId = propertyId,
	}
	return model
end

local function makeDecorPart(parent, name, size, cframe, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Parent = parent
	return part
end

applyInteriorDecor = function(model, decorId)
	local decor = decorById[decorId]
	local floor = model:FindFirstChild("InteriorFloor")
	if not decor or not floor or not floor:IsA("BasePart") then
		return false
	end

	local existing = model:FindFirstChild("PlayerInteriorDecor")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "PlayerInteriorDecor"
	folder.Parent = model

	local floorTop = floor.Size.Y / 2 + 0.08
	local halfWidth = floor.Size.X / 2
	local halfDepth = floor.Size.Z / 2
	local function at(x, y, z)
		return floor.CFrame * CFrame.new(x, floorTop + y, z)
	end

	if decorId == "botanical" then
		for _, x in ipairs({ -halfWidth + 3, halfWidth - 3 }) do
			local pot = makeDecorPart(
				folder,
				"Planter",
				Vector3.new(1.7, 1.4, 1.7),
				at(x, 0.7, 0),
				Color3.fromRGB(142, 100, 66),
				Enum.Material.Marble
			)
			makeDecorPart(
				folder,
				"Foliage",
				Vector3.new(2.2, 2.8, 2.2),
				at(x, 2.45, 0),
				Color3.fromRGB(68, 122, 76),
				Enum.Material.Grass,
				Enum.PartType.Ball
			)
			pot:SetAttribute("DecorItem", decorId)
		end
	elseif decorId == "gallery" then
		local backWall = model:FindFirstChild("BackWall")
		if not backWall or not backWall:IsA("BasePart") then
			folder:Destroy()
			return false
		end
		for _, x in ipairs({ -halfWidth * 0.45, 0, halfWidth * 0.45 }) do
			local frame = makeDecorPart(
				folder,
				"GalleryFrame",
				Vector3.new(4.5, 3.2, 0.22),
				backWall.CFrame * CFrame.new(x, 1.5, -backWall.Size.Z / 2 - 0.18),
				Color3.fromRGB(218, 180, 91),
				Enum.Material.Metal
			)
			makeDecorPart(
				folder,
				"Artwork",
				Vector3.new(3.9, 2.6, 0.08),
				frame.CFrame * CFrame.new(0, 0, -0.15),
				Color3.fromRGB(67, 103, 120),
				Enum.Material.SmoothPlastic
			)
		end
	elseif decorId == "lounge" then
		makeDecorPart(
			folder,
			"LoungeRug",
			Vector3.new(math.max(1, math.min(12, floor.Size.X - 8)), 0.12, math.max(1, math.min(8, floor.Size.Z - 8))),
			at(0, 0.06, 0),
			Color3.fromRGB(64, 75, 91),
			Enum.Material.Fabric
		)
		for _, x in ipairs({ -halfWidth + 3, halfWidth - 3 }) do
			local base = makeDecorPart(
				folder,
				"LampBase",
				Vector3.new(1.2, 0.3, 1.2),
				at(x, 0.15, -halfDepth + 4),
				Color3.fromRGB(218, 180, 91),
				Enum.Material.Metal,
				Enum.PartType.Cylinder
			)
			makeDecorPart(
				folder,
				"LampStem",
				Vector3.new(0.22, 3.4, 0.22),
				base.CFrame * CFrame.new(0, 1.8, 0),
				Color3.fromRGB(178, 181, 185),
				Enum.Material.Metal,
				Enum.PartType.Cylinder
			)
			local shade = makeDecorPart(
				folder,
				"LampShade",
				Vector3.new(1.4, 0.8, 1.4),
				base.CFrame * CFrame.new(0, 3.8, 0),
				Color3.fromRGB(255, 235, 190),
				Enum.Material.Neon,
				Enum.PartType.Ball
			)
			local light = Instance.new("PointLight")
			light.Name = "LoungeLight"
			light.Color = shade.Color
			light.Range = 12
			light.Brightness = 0.55
			light.Parent = shade
		end
	end

	folder:SetAttribute("DecorId", decorId)
	return true
end

local function getPrivateInterior(player, propertyId, sourceModel)
	local existing = privateInteriors[player.UserId]
	if existing and existing.Model and existing.Model.Parent and existing.PropertyId == propertyId then
		return existing.Model
	end

	destroyPrivateInterior(player)
	return createPrivateInterior(player, propertyId, sourceModel)
end

applyInteriorStyle = function(model, styleId)
	local style = interiorStyles[styleId]
	if not style then
		return false
	end

	local colorsByPart = {
		BackWall = style.Walls,
		FrontWall = style.Walls,
		SideWall = style.Walls,
		DoorLintel = style.Walls,
		Headboard = style.Accent,
		LoungeSofa = style.Accent,
		LuxuryBed = style.Furniture,
		LoungeTable = style.Furniture,
	}

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local color = colorsByPart[descendant.Name]
			if color then
				descendant.Color = color
			elseif descendant.Name == "CeilingLight" then
				descendant.Color = style.Light
				local pointLight = descendant:FindFirstChild("InteriorLight")
				if pointLight and pointLight:IsA("PointLight") then
					pointLight.Color = style.Light
				end
			end
		end
	end

	return true
end

function PropertyService.GetCatalog()
	local result = {}
	for _, property in ipairs(catalog) do
		table.insert(result, {
			Id = property.Id,
			Name = property.Name,
			Type = property.Type,
			Price = property.Price,
			AccessLevel = property.AccessLevel,
		})
	end
	return result
end

function PropertyService.GetDecorCatalog()
	return interiorDecorCatalog
end

function PropertyService.GetOwnedProperties(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	profile.properties = profile.properties or {}
	for _, property in pairs(profile.properties) do
		if type(property) == "table" then
			if not interiorStyles[property.InteriorStyle] then
				property.InteriorStyle = "classic"
			end
			if not decorById[property.InteriorDecor] then
				property.InteriorDecor = "botanical"
			end
		end
	end
	return profile.properties
end

function PropertyService.SetInteriorStyle(player, propertyId, styleId)
	if typeof(propertyId) ~= "string" or typeof(styleId) ~= "string" then
		return false, "Solicitação de decoração inválida"
	end

	local style = interiorStyles[styleId]
	if not style then
		return false, "Estilo de interior não disponível"
	end

	local returnData = returnPositions[player.UserId]
	if not returnData or returnData.PropertyId ~= propertyId then
		return false, "Entre no seu imóvel antes de personalizá-lo"
	end
	if returnData.OwnerUserId then
		return false, "Somente o proprietário pode alterar a decoração"
	end

	local profile = EconomyService.GetProfile(player)
	local propertyData = profile and profile.properties and profile.properties[propertyId]
	if not propertyData then
		return false, "Você não possui este imóvel"
	end

	local model = returnData.Model
	local spawnPoint = model and model:FindFirstChild("SpawnPoint")
	if not model or not spawnPoint or not spawnPoint:IsA("BasePart") then
		return false, "Aproxime-se do interior do seu imóvel para decorar"
	end
	if not isPlayerInsideInterior(player, returnData) then
		return false, "Entre no interior do seu imóvel para decorar"
	end

	if not applyInteriorStyle(model, styleId) then
		return false, "Não foi possível aplicar este estilo"
	end

	propertyData.InteriorStyle = styleId
	return true,
		{
			PropertyId = propertyId,
			StyleId = styleId,
			StyleName = style.Name,
			Message = "Interior atualizado para o estilo " .. style.Name,
		}
end

function PropertyService.SetInteriorDecor(player, propertyId, decorId)
	if typeof(propertyId) ~= "string" or typeof(decorId) ~= "string" then
		return false, "Solicitação de decoração inválida"
	end
	local decor = decorById[decorId]
	if not decor then
		return false, "Este conjunto de decoração não está disponível"
	end

	local returnData = returnPositions[player.UserId]
	if not returnData or returnData.PropertyId ~= propertyId then
		return false, "Entre no seu imóvel antes de decorá-lo"
	end
	if returnData.OwnerUserId then
		return false, "Somente o proprietário pode alterar a decoração"
	end
	if not isPlayerInsideInterior(player, returnData) then
		return false, "Entre no interior do seu imóvel para decorá-lo"
	end

	local profile = EconomyService.GetProfile(player)
	local propertyData = profile and profile.properties and profile.properties[propertyId]
	if not propertyData then
		return false, "Você não possui este imóvel"
	end
	if not applyInteriorDecor(returnData.Model, decorId) then
		return false, "Não foi possível aplicar esta decoração"
	end

	propertyData.InteriorDecor = decorId
	return true,
		{
			PropertyId = propertyId,
			DecorId = decorId,
			DecorName = decor.Name,
			Message = "Decoração atualizada: " .. decor.Name .. ".",
		}
end

function PropertyService.HasAccess(player, propertyId)
	local profile = EconomyService.GetProfile(player)
	return profile ~= nil
		and type(propertyId) == "string"
		and type(profile.properties) == "table"
		and profile.properties[propertyId] ~= nil
end

function PropertyService.InviteGuest(owner, propertyId, guestUserId)
	if
		typeof(propertyId) ~= "string"
		or not findProperty(propertyId)
		or typeof(guestUserId) ~= "number"
		or guestUserId <= 0
		or guestUserId % 1 ~= 0
	then
		return false, "Convite inválido"
	end

	if guestUserId == owner.UserId then
		return false, "Você não pode convidar a si mesmo"
	end

	local ownerReturn = returnPositions[owner.UserId]
	local interior = privateInteriors[owner.UserId]
	if
		not ownerReturn
		or ownerReturn.OwnerUserId
		or ownerReturn.PropertyId ~= propertyId
		or not interior
		or not interior.Model
		or not interior.Model.Parent
	then
		return false, "Entre no seu imóvel antes de convidar alguém"
	end
	if not isPlayerInsideInterior(owner, ownerReturn) then
		return false, "Você precisa estar dentro do imóvel para convidar alguém"
	end
	if not PropertyService.HasAccess(owner, propertyId) then
		return false, "Você não possui este imóvel"
	end

	local guest = Players:GetPlayerByUserId(guestUserId)
	if not guest or guest.Parent ~= Players then
		return false, "Este jogador não está mais nesta sessão"
	end
	if returnPositions[guest.UserId] then
		return false, "Este jogador já está visitando um imóvel"
	end
	if countInteriorGuests(owner.UserId, propertyId) >= 4 then
		return false, "Este imóvel já atingiu o limite de quatro visitantes"
	end
	if pendingInvites[guest.UserId] then
		return false, "Este jogador já tem um convite de imóvel pendente"
	end
	if not inviteReceivedRemote or not inviteReceivedRemote.Parent then
		return false, "Sistema de convites indisponível"
	end

	local property = findProperty(propertyId)
	local invite = {
		OwnerUserId = owner.UserId,
		PropertyId = propertyId,
		ExpiresAt = os.clock() + 60,
	}
	pendingInvites[guest.UserId] = invite
	task.delay(60, function()
		if pendingInvites[guest.UserId] ~= invite then
			return
		end
		pendingInvites[guest.UserId] = nil
		if guest.Parent == Players and inviteResultRemote and inviteResultRemote.Parent then
			inviteResultRemote:FireClient(guest, {
				Success = false,
				Message = "O convite para visitar o imóvel expirou.",
			})
		end
	end)

	inviteReceivedRemote:FireClient(guest, {
		OwnerUserId = owner.UserId,
		OwnerName = owner.DisplayName,
		PropertyId = propertyId,
		PropertyName = property and property.Name or "Imóvel",
		ExpiresIn = 60,
	})
	return true, "Convite enviado. Ele expira em 60 segundos."
end

function PropertyService.RespondToInvite(guest, response)
	if typeof(response) ~= "string" or (response ~= "Accept" and response ~= "Decline") then
		return false, "Resposta ao convite inválida"
	end

	local invite = pendingInvites[guest.UserId]
	if not invite then
		return false, "Este convite não existe mais"
	end
	pendingInvites[guest.UserId] = nil

	if os.clock() > invite.ExpiresAt then
		return false, "O convite expirou"
	end
	if response == "Decline" then
		local owner = Players:GetPlayerByUserId(invite.OwnerUserId)
		if owner and inviteResultRemote and inviteResultRemote.Parent then
			inviteResultRemote:FireClient(owner, {
				Success = true,
				Message = guest.DisplayName .. " recusou o convite.",
			})
		end
		return true, "Convite recusado"
	end

	if returnPositions[guest.UserId] then
		return false, "Saia do imóvel atual antes de aceitar outro convite"
	end

	local owner = Players:GetPlayerByUserId(invite.OwnerUserId)
	local ownerReturn = owner and returnPositions[owner.UserId]
	local interior = owner and privateInteriors[owner.UserId]
	if
		not owner
		or not ownerReturn
		or ownerReturn.OwnerUserId
		or ownerReturn.PropertyId ~= invite.PropertyId
		or not interior
		or not interior.Model
		or not interior.Model.Parent
	then
		return false, "O proprietário não está mais no imóvel"
	end
	if not isPlayerInsideInterior(owner, ownerReturn) then
		return false, "O proprietário não está mais dentro do imóvel"
	end
	if not PropertyService.HasAccess(owner, invite.PropertyId) then
		return false, "O proprietário não possui mais este imóvel"
	end
	if countInteriorGuests(owner.UserId, invite.PropertyId) >= 4 then
		return false, "Este imóvel já atingiu o limite de quatro visitantes"
	end

	local character = guest.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local spawnPoint = interior.Model:FindFirstChild("SpawnPoint")
	if
		not character
		or not root
		or not humanoid
		or humanoid.Health <= 0
		or not spawnPoint
		or not spawnPoint:IsA("BasePart")
	then
		return false, "Seu personagem ou o ponto de entrada não está disponível"
	end

	local prompt = spawnPoint:FindFirstChild("PropertyExitPrompt")
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false, "A saída do imóvel não está disponível"
	end

	local guestOffset = CFrame.new((countInteriorGuests(owner.UserId, invite.PropertyId) + 1) * 3, 2, 0)
	returnPositions[guest.UserId] = {
		PropertyId = invite.PropertyId,
		CFrame = root.CFrame,
		ExitPoint = spawnPoint,
		Model = interior.Model,
		OwnerUserId = owner.UserId,
	}
	character:PivotTo(spawnPoint.CFrame * guestOffset)

	if inviteResultRemote and inviteResultRemote.Parent then
		inviteResultRemote:FireClient(owner, {
			Success = true,
			Message = guest.DisplayName .. " aceitou o convite.",
		})
	end
	return true, "Você entrou no imóvel. A visita termina quando o proprietário sair."
end

function PropertyService.IsNearPurchasePoint(player, propertyId)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end

	for _, model in ipairs(getPropertyModels()) do
		if getPropertyId(model) == propertyId then
			local point = getPurchasePoint(model)
			local prompt = point and point:FindFirstChild("PropertyPurchasePrompt")
			if
				point
				and prompt
				and prompt:IsA("ProximityPrompt")
				and prompt.Enabled
				and (root.Position - point.Position).Magnitude <= prompt.MaxActivationDistance + 3
			then
				return true
			end
		end
	end

	return false
end

function PropertyService.ReturnToCity(player, propertyId)
	local returnData = returnPositions[player.UserId]
	if not returnData or returnData.PropertyId ~= propertyId then
		return false, "Você não está dentro deste imóvel"
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false, "Personagem não encontrado"
	end
	local exitPoint = returnData.ExitPoint
	if not exitPoint or not exitPoint.Parent then
		return false, "A saída deste imóvel não está disponível"
	end

	local prompt = exitPoint:FindFirstChild("PropertyExitPrompt")
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false, "A saída deste imóvel não está disponível"
	end
	if (root.Position - exitPoint.Position).Magnitude > prompt.MaxActivationDistance + 3 then
		return false, "Aproxime-se da saída deste imóvel"
	end

	if not returnData.OwnerUserId then
		cancelOwnerInvites(player.UserId, "O proprietário saiu do imóvel; o convite foi cancelado.")
		returnInteriorGuests(player, propertyId, "O proprietário encerrou a visita.")
	end
	character:PivotTo(returnData.CFrame)
	returnPositions[player.UserId] = nil
	if not returnData.OwnerUserId then
		destroyPrivateInterior(player)
	end
	return true, "Você voltou à cidade"
end

function PropertyService.Init(entryResultRemote, inviteReceived, inviteResult)
	if initialized then
		return
	end
	initialized = true
	resultRemote = entryResultRemote
	inviteReceivedRemote = inviteReceived
	inviteResultRemote = inviteResult
	ensurePrivateInteriorFolder()
	local function trackPlayer(player)
		player.CharacterAdded:Connect(function()
			local returnData = returnPositions[player.UserId]
			if returnData and not returnData.OwnerUserId then
				cancelOwnerInvites(player.UserId, "O proprietário saiu do imóvel; o convite foi cancelado.")
				returnInteriorGuests(player, returnData.PropertyId, "A visita foi encerrada.")
				destroyPrivateInterior(player)
			end
			returnPositions[player.UserId] = nil
		end)
	end

	Players.PlayerAdded:Connect(trackPlayer)
	Players.PlayerRemoving:Connect(function(player)
		returnInteriorGuests(
			player,
			(privateInteriors[player.UserId] or {}).PropertyId,
			"O proprietário saiu; a visita terminou."
		)
		cancelOwnerInvites(player.UserId, "O proprietário saiu; o convite foi cancelado.")
		pendingInvites[player.UserId] = nil
		returnPositions[player.UserId] = nil
		destroyPrivateInterior(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayer(player)
	end

	for _, model in ipairs(getPropertyModels()) do
		local propertyId = getPropertyId(model)
		if type(propertyId) == "string" then
			local purchasePoint = getPurchasePoint(model)
			if purchasePoint then
				purchasePoint:SetAttribute("PropertyId", propertyId)
				local purchasePrompt = purchasePoint:FindFirstChild("PropertyPurchasePrompt")
				if not purchasePrompt then
					purchasePrompt = Instance.new("ProximityPrompt")
					purchasePrompt.Name = "PropertyPurchasePrompt"
					purchasePrompt.ActionText = "Consultar imóvel"
					purchasePrompt.MaxActivationDistance = 10
					purchasePrompt.HoldDuration = 0
					purchasePrompt.RequiresLineOfSight = false
					purchasePrompt.Parent = purchasePoint
				elseif not purchasePrompt:IsA("ProximityPrompt") then
					error(string.format("%s.PropertyPurchasePrompt precisa ser ProximityPrompt", model:GetFullName()))
				end

				local property = findProperty(propertyId)
				if property then
					purchasePrompt.ObjectText = property.Name
				end
			end

			local spawnPoint = model:FindFirstChild("SpawnPoint")
			if spawnPoint and spawnPoint:IsA("BasePart") then
				local prompt = spawnPoint:FindFirstChild("PropertyExitPrompt")
				if not prompt then
					prompt = Instance.new("ProximityPrompt")
					prompt.Name = "PropertyExitPrompt"
					prompt.ActionText = "Sair"
					prompt.ObjectText = "Voltar para a cidade"
					prompt.MaxActivationDistance = 10
					prompt.HoldDuration = 0
					prompt.RequiresLineOfSight = false
					prompt.Parent = spawnPoint
				elseif not prompt:IsA("ProximityPrompt") then
					error(string.format("%s.PropertyExitPrompt precisa ser ProximityPrompt", model:GetFullName()))
				end

				prompt.Triggered:Connect(function(player)
					local success, message = PropertyService.ReturnToCity(player, propertyId)
					resultRemote:FireClient(player, {
						Success = success,
						PropertyId = propertyId,
						Message = message,
					})
				end)
			end
		end
	end
end

function PropertyService.PurchaseProperty(player, propertyId)
	if typeof(propertyId) ~= "string" then
		return false, "Identificador de propriedade inválido"
	end

	local property = findProperty(propertyId)
	if not property then
		return false, "Propriedade não encontrada"
	end

	local profile = EconomyService.GetProfile(player)
	if not profile then
		return false, "Perfil do jogador ainda não foi carregado"
	end

	profile.properties = profile.properties or {}
	if profile.properties[property.Id] then
		return false, "Você já possui esta propriedade"
	end

	local paid, reason = EconomyService.SpendCredits(player, property.Price, {
		Type = "PropertyPurchase",
		PropertyId = property.Id,
	})
	if not paid then
		return false, reason
	end

	profile.properties[property.Id] = {
		Id = property.Id,
		Name = property.Name,
		Type = property.Type,
		Price = property.Price,
		BoughtAt = os.time(),
		AccessLevel = property.AccessLevel,
	}

	AchievementService.RecordMilestone(player, "PropertyPurchased")

	return true,
		{
			Id = property.Id,
			Name = property.Name,
			Type = property.Type,
			Price = property.Price,
			AccessLevel = property.AccessLevel,
		}
end

function PropertyService.TeleportToProperty(player, propertyId)
	if typeof(propertyId) ~= "string" then
		return false, "Identificador de propriedade inválido"
	end

	if not PropertyService.HasAccess(player, propertyId) then
		return false, "Você não possui esta propriedade"
	end
	if returnPositions[player.UserId] then
		return false, "Saia do imóvel atual antes de visitar outro"
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false, "Personagem não encontrado"
	end

	local propertyModels = getPropertyModels()

	if #propertyModels == 0 then
		return false, "Nenhum imóvel foi encontrado no mapa"
	end

	for _, model in ipairs(propertyModels) do
		if getPropertyId(model) == propertyId then
			local profile = EconomyService.GetProfile(player)
			local propertyData = profile and profile.properties and profile.properties[propertyId]
			local privateModel = getPrivateInterior(player, propertyId, model)
			applyInteriorStyle(privateModel, propertyData and propertyData.InteriorStyle or "classic")
			applyInteriorDecor(privateModel, propertyData and propertyData.InteriorDecor or "botanical")
			local spawnPoint = privateModel:FindFirstChild("SpawnPoint")

			if not spawnPoint or not spawnPoint:IsA("BasePart") then
				destroyPrivateInterior(player)
				return false, "Ponto de entrada da propriedade não encontrado"
			end

			returnPositions[player.UserId] = {
				PropertyId = propertyId,
				CFrame = root.CFrame,
				ExitPoint = spawnPoint,
				Model = privateModel,
			}
			character:PivotTo(spawnPoint.CFrame * CFrame.new(0, 2, 0))
			return true, "Bem-vinda à sua propriedade"
		end
	end

	return false, "O imóvel existe, mas ainda não tem um ponto de entrada configurado"
end

function PropertyService.CleanupPlayer(player)
	returnPositions[player.UserId] = nil
end

return PropertyService
