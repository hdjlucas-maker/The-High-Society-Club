local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))
local Modules = script.Parent:WaitForChild("Modules")
local EconomyService = require(Modules:WaitForChild("EconomyService"))
local ShopService = require(Modules:WaitForChild("ShopService"))
local PropertyService = require(Modules:WaitForChild("PropertyService"))
local VehicleService = require(Modules:WaitForChild("VehicleService"))
local VehicleBuilder = require(Modules:WaitForChild("VehicleBuilder"))
local WorldBuilder = require(Modules:WaitForChild("WorldBuilder"))
local WorkService = require(Modules:WaitForChild("WorkService"))
local ClubService = require(Modules:WaitForChild("ClubService"))
local AppearanceService = require(Modules:WaitForChild("AppearanceService"))
local PlayerMarketService = require(Modules:WaitForChild("PlayerMarketService"))
local CreationService = require(Modules:WaitForChild("CreationService"))
local DayNightService = require(Modules:WaitForChild("DayNightService"))
local AchievementService = require(Modules:WaitForChild("AchievementService"))
local EventService = require(Modules:WaitForChild("EventService"))
local FashionContestService = require(Modules:WaitForChild("FashionContestService"))
local AdminService = require(Modules:WaitForChild("AdminService"))
local DailyRewardService = require(Modules:WaitForChild("DailyRewardService"))
local MonetizationService = require(Modules:WaitForChild("MonetizationService"))
local RateLimitService = require(Modules:WaitForChild("RateLimitService"))
local RegionService = require(Modules:WaitForChild("RegionService"))
local WorldLife = require(Modules:WaitForChild("WorldLife"))
local PlayerSafetyService = require(Modules:WaitForChild("PlayerSafetyService"))
local WorldAudit = require(Modules:WaitForChild("WorldAudit"))

local WELCOME_BONUS = Config.Economy.WelcomeBonus
local REQUEST_COOLDOWN = Config.RateLimits.RequestCooldown
local SPAWN_COOLDOWN = Config.RateLimits.SpawnCooldown

local function allowRemoteQuery(player, queryName)
	return RateLimitService.Allow(player, "query." .. queryName, Config.RateLimits.QueryCooldown)
end

local function ensureRemote(folder, name, className)
	local remote = folder:FindFirstChild(name)
	if remote then
		if not remote:IsA(className) then
			error(
				string.format(
					"ReplicatedStorage.HSC.Remotes.%s precisa ser %s, mas é %s",
					name,
					className,
					remote.ClassName
				)
			)
		end
		return remote
	end

	remote = Instance.new(className)
	remote.Name = name
	remote.Parent = folder
	return remote
end

local function createRemotes()
	local hscFolder = ReplicatedStorage:FindFirstChild("HSC")
	if not hscFolder then
		hscFolder = Instance.new("Folder")
		hscFolder.Name = "HSC"
		hscFolder.Parent = ReplicatedStorage
	elseif not hscFolder:IsA("Folder") then
		error("ReplicatedStorage.HSC precisa ser uma Folder")
	end

	local folder = hscFolder:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = hscFolder
	elseif not folder:IsA("Folder") then
		error("ReplicatedStorage.HSC.Remotes precisa ser uma Folder")
	end

	return folder,
		{
			CurrencyChanged = ensureRemote(folder, "CurrencyChanged", "RemoteEvent"),
			RequestRecentTransactions = ensureRemote(folder, "RequestRecentTransactions", "RemoteFunction"),
			RequestDailyRewardStatus = ensureRemote(folder, "RequestDailyRewardStatus", "RemoteFunction"),
			DailyRewardClaim = ensureRemote(folder, "DailyRewardClaim", "RemoteEvent"),
			DailyRewardResult = ensureRemote(folder, "DailyRewardResult", "RemoteEvent"),
			RequestAchievements = ensureRemote(folder, "RequestAchievements", "RemoteFunction"),
			AchievementUnlocked = ensureRemote(folder, "AchievementUnlocked", "RemoteEvent"),
			RequestEvents = ensureRemote(folder, "RequestEvents", "RemoteFunction"),
			EventParticipationRequest = ensureRemote(folder, "EventParticipationRequest", "RemoteEvent"),
			EventParticipationResult = ensureRemote(folder, "EventParticipationResult", "RemoteEvent"),
			RequestFashionContest = ensureRemote(folder, "RequestFashionContest", "RemoteFunction"),
			FashionContestRequest = ensureRemote(folder, "FashionContestRequest", "RemoteEvent"),
			FashionContestResult = ensureRemote(folder, "FashionContestResult", "RemoteEvent"),
			EventInviteRequest = ensureRemote(folder, "EventInviteRequest", "RemoteEvent"),
			EventInviteResponse = ensureRemote(folder, "EventInviteResponse", "RemoteEvent"),
			EventInviteReceived = ensureRemote(folder, "EventInviteReceived", "RemoteEvent"),
			EventInviteResult = ensureRemote(folder, "EventInviteResult", "RemoteEvent"),
			RequestAdminStatus = ensureRemote(folder, "RequestAdminStatus", "RemoteFunction"),
			RequestModerationLogs = ensureRemote(folder, "RequestModerationLogs", "RemoteFunction"),
			AdminAction = ensureRemote(folder, "AdminAction", "RemoteEvent"),
			AdminActionResult = ensureRemote(folder, "AdminActionResult", "RemoteEvent"),
			RequestShopItems = ensureRemote(folder, "RequestShopItems", "RemoteFunction"),
			RequestOwnedItems = ensureRemote(folder, "RequestOwnedItems", "RemoteFunction"),
			ItemEquipmentRequest = ensureRemote(folder, "ItemEquipmentRequest", "RemoteEvent"),
			ItemEquipmentResult = ensureRemote(folder, "ItemEquipmentResult", "RemoteEvent"),
			ShopPurchase = ensureRemote(folder, "ShopPurchase", "RemoteEvent"),
			RequestMarketData = ensureRemote(folder, "RequestMarketData", "RemoteFunction"),
			MarketAction = ensureRemote(folder, "MarketAction", "RemoteEvent"),
			MarketActionResult = ensureRemote(folder, "MarketActionResult", "RemoteEvent"),
			MonetizationResult = ensureRemote(folder, "MonetizationResult", "RemoteEvent"),
			RequestApprovedCreations = ensureRemote(folder, "RequestApprovedCreations", "RemoteFunction"),
			RequestPendingCreations = ensureRemote(folder, "RequestPendingCreations", "RemoteFunction"),
			CreationReviewRequest = ensureRemote(folder, "CreationReviewRequest", "RemoteEvent"),
			CreationReviewResult = ensureRemote(folder, "CreationReviewResult", "RemoteEvent"),
			RequestPropertyCatalog = ensureRemote(folder, "RequestPropertyCatalog", "RemoteFunction"),
			PropertyPurchase = ensureRemote(folder, "PropertyPurchase", "RemoteEvent"),
			RequestOwnedProperties = ensureRemote(folder, "RequestOwnedProperties", "RemoteFunction"),
			RequestPropertyEntry = ensureRemote(folder, "RequestPropertyEntry", "RemoteEvent"),
			PropertyStyleRequest = ensureRemote(folder, "PropertyStyleRequest", "RemoteEvent"),
			PropertyStyleResult = ensureRemote(folder, "PropertyStyleResult", "RemoteEvent"),
			RequestPropertyDecorCatalog = ensureRemote(folder, "RequestPropertyDecorCatalog", "RemoteFunction"),
			PropertyDecorRequest = ensureRemote(folder, "PropertyDecorRequest", "RemoteEvent"),
			PropertyDecorResult = ensureRemote(folder, "PropertyDecorResult", "RemoteEvent"),
			PropertyInviteRequest = ensureRemote(folder, "PropertyInviteRequest", "RemoteEvent"),
			PropertyInviteResponse = ensureRemote(folder, "PropertyInviteResponse", "RemoteEvent"),
			PropertyInviteReceived = ensureRemote(folder, "PropertyInviteReceived", "RemoteEvent"),
			PropertyInviteResult = ensureRemote(folder, "PropertyInviteResult", "RemoteEvent"),
			RequestVehicleCatalog = ensureRemote(folder, "RequestVehicleCatalog", "RemoteFunction"),
			RequestVehiclePaintCatalog = ensureRemote(folder, "RequestVehiclePaintCatalog", "RemoteFunction"),
			VehiclePaintRequest = ensureRemote(folder, "VehiclePaintRequest", "RemoteEvent"),
			VehiclePaintResult = ensureRemote(folder, "VehiclePaintResult", "RemoteEvent"),
			VehiclePurchase = ensureRemote(folder, "VehiclePurchase", "RemoteEvent"),
			VehicleTestDriveRequest = ensureRemote(folder, "VehicleTestDriveRequest", "RemoteEvent"),
			VehicleTestDriveResult = ensureRemote(folder, "VehicleTestDriveResult", "RemoteEvent"),
			RequestOwnedVehicles = ensureRemote(folder, "RequestOwnedVehicles", "RemoteFunction"),
			RequestVehicleSpawn = ensureRemote(folder, "RequestVehicleSpawn", "RemoteEvent"),
			RequestActiveVehicle = ensureRemote(folder, "RequestActiveVehicle", "RemoteFunction"),
			VehicleStoreRequest = ensureRemote(folder, "VehicleStoreRequest", "RemoteEvent"),
			VehicleStoreResult = ensureRemote(folder, "VehicleStoreResult", "RemoteEvent"),
			VehicleSpawnResult = ensureRemote(folder, "VehicleSpawnResult", "RemoteEvent"),
			VehicleDrive = ensureRemote(folder, "VehicleDrive", "RemoteEvent"),
			RequestWorkJobs = ensureRemote(folder, "RequestWorkJobs", "RemoteFunction"),
			RequestActiveWork = ensureRemote(folder, "RequestActiveWork", "RemoteFunction"),
			WorkJobRequest = ensureRemote(folder, "WorkJobRequest", "RemoteEvent"),
			WorkJobResult = ensureRemote(folder, "WorkJobResult", "RemoteEvent"),
			RequestClubStatus = ensureRemote(folder, "RequestClubStatus", "RemoteFunction"),
			ClubPerformanceRequest = ensureRemote(folder, "ClubPerformanceRequest", "RemoteEvent"),
			ClubPerformanceResult = ensureRemote(folder, "ClubPerformanceResult", "RemoteEvent"),
			LegacyRequestSpawnVehicle = ensureRemote(folder, "RequestSpawnVehicle", "RemoteEvent"),
			RegionChanged = ensureRemote(folder, "RegionChanged", "RemoteEvent"),
		}
end

local _, remotes = createRemotes()

-- O chão é criado primeiro, antes de qualquer outra coisa, para o avatar não cair no vazio.
pcall(WorldBuilder.EnsureGround)

-- Se um módulo falhar ao iniciar, o erro vai para o Output e o resto do jogo continua
-- (antes, um único erro parava o servidor e deixava Loja e Society Credits sem resposta).
local function safeInit(name, initFunction)
	local ok, initError = pcall(initFunction)
	if not ok then
		Logger.Error("Bootstrap", string.format("Falha ao iniciar %s: %s", name, tostring(initError)))
	end
	return ok
end

safeInit("WorldBuilder", WorldBuilder.Init)
safeInit("DayNightService", DayNightService.Init)
safeInit("EconomyService", function()
	EconomyService.Init(remotes.CurrencyChanged)
end)
safeInit("RegionService", function()
	RegionService.Init(remotes.RegionChanged)
end)
safeInit("ClubService", ClubService.Init)
safeInit("VehicleBuilder", VehicleBuilder.Init)
safeInit("VehicleService", function()
	VehicleService.Init(remotes.VehicleTestDriveResult)
end)
safeInit("PropertyService", function()
	PropertyService.Init(remotes.RequestPropertyEntry, remotes.PropertyInviteReceived, remotes.PropertyInviteResult)
end)
safeInit("MonetizationService", function()
	MonetizationService.Init(remotes.MonetizationResult)
end)
safeInit("AppearanceService", AppearanceService.Init)
safeInit("AchievementService", function()
	AchievementService.Init(remotes.AchievementUnlocked)
end)
safeInit("EventService", function()
	EventService.Init(remotes.EventParticipationResult, remotes.EventInviteReceived, remotes.EventInviteResult)
end)
safeInit("AdminService", AdminService.Init)
safeInit("CreationService", CreationService.Init)
safeInit("WorldLife", WorldLife.Init)
safeInit("PlayerSafetyService", PlayerSafetyService.Init)
safeInit("WorldAudit", WorldAudit.Init)

local function isPlayerNearPartPrompt(player, part, promptName)
	local prompt = part and part:FindFirstChild(promptName)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if
		not part
		or not part:IsA("BasePart")
		or not prompt
		or not prompt:IsA("ProximityPrompt")
		or not prompt.Enabled
		or not root
		or not humanoid
		or humanoid.Health <= 0
	then
		return false
	end

	return (root.Position - part.Position).Magnitude <= prompt.MaxActivationDistance + 3
end

local function isPlayerNearPrompt(player, partName, promptName)
	local part = workspace:FindFirstChild(partName)
	if not part then
		local world = workspace:FindFirstChild("HighSocietyWorld")
		part = world and world:FindFirstChild(partName, true)
	end

	return isPlayerNearPartPrompt(player, part, promptName)
end

local function isPlayerNearShop(player, storeId)
	local definition = ShopService.GetStoreDefinition(storeId)
	if not definition then
		return false
	end

	local world = workspace:FindFirstChild("HighSocietyWorld")
	local district = world and world:FindFirstChild(definition.DistrictName)
	local store = district and district:FindFirstChild(definition.ModelName)
	local point = store and store:FindFirstChild(definition.PointName)
	if point and point:IsA("BasePart") and point:GetAttribute("ShopId") ~= storeId then
		return false
	end
	return isPlayerNearPartPrompt(player, point, definition.PromptName)
end

local function onPlayerAdded(player)
	local profile, loadError = EconomyService.LoadPlayer(player)
	if not profile then
		Logger.Warn("Bootstrap", string.format("Dados de %s não carregaram: %s", player.Name, tostring(loadError)))
		player:Kick("Não foi possível carregar seus dados. Tente entrar novamente.")
		return
	end

	if EconomyService.ClaimFirstJoinBonus(player) then
		local granted, reason = EconomyService.AddCredits(player, WELCOME_BONUS, {
			Type = "WelcomeBonus",
		})
		if not granted then
			Logger.Warn("Bootstrap", string.format("Falha ao conceder bônus a %s: %s", player.Name, tostring(reason)))
		end
	end
end

remotes.RequestRecentTransactions.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "transactions") then
		return nil, "Aguarde antes de atualizar o extrato"
	end
	return EconomyService.GetRecentTransactions(player)
end

remotes.RequestDailyRewardStatus.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "daily-reward") then
		return nil, "Aguarde antes de atualizar a recompensa diária"
	end
	return DailyRewardService.GetStatus(player)
end

remotes.DailyRewardClaim.OnServerEvent:Connect(function(player)
	if not RateLimitService.Allow(player, "daily-reward.claim", REQUEST_COOLDOWN) then
		remotes.DailyRewardResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de tentar resgatar novamente",
		})
		return
	end

	local success, result = DailyRewardService.Claim(player)
	local response = { Success = success }
	if success and type(result) == "table" then
		for key, value in pairs(result) do
			response[key] = value
		end
	else
		response.Message = tostring(result)
	end
	remotes.DailyRewardResult:FireClient(player, response)
end)

remotes.RequestAchievements.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "achievements") then
		return nil, "Aguarde antes de atualizar as conquistas"
	end
	return AchievementService.GetCatalog(player)
end

remotes.RequestEvents.OnServerInvoke = function(player)
	if not RateLimitService.Allow(player, "event.catalog", Config.RateLimits.EventCatalogCooldown) then
		return nil, "Aguarde antes de atualizar a lista de eventos"
	end
	return EventService.GetEvents(player)
end

remotes.RequestFashionContest.OnServerInvoke = function(player)
	if not RateLimitService.Allow(player, "fashion-contest.status", Config.RateLimits.EventCatalogCooldown) then
		return nil, "Aguarde antes de atualizar o concurso"
	end
	return FashionContestService.GetStatus(player)
end

remotes.RequestAdminStatus.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "admin-status") then
		return nil, "Aguarde antes de verificar o acesso administrativo"
	end
	return AdminService.GetStatus(player)
end

remotes.RequestModerationLogs.OnServerInvoke = function(player)
	return AdminService.GetRecentModerationLogs(player)
end

remotes.AdminAction.OnServerEvent:Connect(function(player, action, targetUserId)
	if typeof(action) ~= "string" or action ~= "Kick" then
		AdminService.RecordInvalidAction(player)
		remotes.AdminActionResult:FireClient(player, {
			Success = false,
			Message = "Ação administrativa inválida",
		})
		return
	end

	local success, message = AdminService.KickPlayer(player, targetUserId)
	remotes.AdminActionResult:FireClient(player, {
		Success = success,
		Message = message,
		TargetUserId = typeof(targetUserId) == "number" and targetUserId or nil,
	})
end)

remotes.EventParticipationRequest.OnServerEvent:Connect(function(player, action, eventId)
	local success, message = EventService.HandleRequest(player, action, eventId)
	remotes.EventParticipationResult:FireClient(player, {
		Success = success,
		Message = message,
		EventId = typeof(eventId) == "string" and eventId or nil,
	})
end)

remotes.FashionContestRequest.OnServerEvent:Connect(function(player, action, targetUserId)
	if not RateLimitService.Allow(player, "fashion-contest.action", Config.RateLimits.FashionContestCooldown) then
		remotes.FashionContestResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de enviar outra ação do concurso",
		})
		return
	end
	if typeof(action) ~= "string" or (action ~= "Submit" and action ~= "Vote") then
		remotes.FashionContestResult:FireClient(player, {
			Success = false,
			Message = "Ação de concurso inválida",
		})
		return
	end

	local success, message
	if action == "Submit" then
		success, message = FashionContestService.Submit(player)
	else
		success, message = FashionContestService.Vote(player, targetUserId)
	end
	remotes.FashionContestResult:FireClient(player, {
		Success = success,
		Message = message,
	})
end)

remotes.EventInviteRequest.OnServerEvent:Connect(function(player, eventId, guestUserId)
	if not RateLimitService.Allow(player, "event.invite.send", REQUEST_COOLDOWN) then
		remotes.EventInviteResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de enviar outro convite de evento",
		})
		return
	end

	local success, message = EventService.InvitePlayer(player, eventId, guestUserId)
	remotes.EventInviteResult:FireClient(player, {
		Success = success,
		Message = message,
		EventId = typeof(eventId) == "string" and eventId or nil,
	})
end)

remotes.EventInviteResponse.OnServerEvent:Connect(function(player, response)
	if not RateLimitService.Allow(player, "event.invite.respond", REQUEST_COOLDOWN) then
		remotes.EventInviteResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de responder a outro convite de evento",
		})
		return
	end

	local success, result = EventService.RespondToInvite(player, response)
	local responseData = {
		Success = success,
		Message = success and type(result) == "table" and result.Message or result,
	}
	if success and type(result) == "table" then
		responseData.EventId = result.EventId
		responseData.Accepted = result.Accepted
	end
	remotes.EventInviteResult:FireClient(player, responseData)
end)

remotes.RequestShopItems.OnServerInvoke = function(player, storeId)
	if not allowRemoteQuery(player, "shop-catalog") then
		return nil, "Aguarde antes de atualizar o catálogo da loja"
	end
	return ShopService.GetCatalog(storeId)
end

remotes.RequestOwnedItems.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "owned-items") then
		return nil, "Aguarde antes de atualizar o inventário"
	end
	return ShopService.GetOwnedItems(player)
end

remotes.RequestMarketData.OnServerInvoke = function(player)
	return PlayerMarketService.GetMarketData(player)
end

remotes.MarketAction.OnServerEvent:Connect(function(player, action, firstArgument, secondArgument)
	local success, result = PlayerMarketService.HandleRequest(player, action, firstArgument, secondArgument)
	local response = {
		Success = success,
		Message = success and type(result) == "table" and result.Message or result,
		Refresh = success,
	}
	if success and type(result) == "table" and result.RecipientUserId then
		local recipient = Players:GetPlayerByUserId(result.RecipientUserId)
		if recipient then
			remotes.MarketActionResult:FireClient(recipient, {
				Success = true,
				Message = result.RecipientMessage,
				Refresh = true,
			})
		end
	end
	remotes.MarketActionResult:FireClient(player, response)
end)

remotes.RequestApprovedCreations.OnServerInvoke = function(player)
	return CreationService.GetApproved(player)
end

remotes.RequestPendingCreations.OnServerInvoke = function(player)
	return CreationService.GetPending(player)
end

remotes.CreationReviewRequest.OnServerEvent:Connect(function(player, submissionId, decision)
	local success, message = CreationService.Review(player, submissionId, decision)
	remotes.CreationReviewResult:FireClient(player, {
		Success = success,
		Message = message,
		Refresh = success,
	})
end)

remotes.ItemEquipmentRequest.OnServerEvent:Connect(function(player, itemId, shouldEquip)
	if not RateLimitService.Allow(player, "equipment.request", REQUEST_COOLDOWN) then
		remotes.ItemEquipmentResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de alterar seus itens",
		})
		return
	end

	local success, result = AppearanceService.SetEquipped(player, itemId, shouldEquip)
	remotes.ItemEquipmentResult:FireClient(player, {
		Success = success,
		Message = result,
	})
end)

remotes.ShopPurchase.OnServerEvent:Connect(function(player, itemId, storeId)
	if not RateLimitService.Allow(player, "shop.request", REQUEST_COOLDOWN) then
		remotes.ShopPurchase:FireClient(player, {
			Success = false,
			Error = "Aguarde antes de fazer outra compra",
		})
		return
	end

	if not isPlayerNearShop(player, storeId) then
		local store = ShopService.GetStoreDefinition(storeId)
		local storeName = store and store.Name or "loja"
		remotes.ShopPurchase:FireClient(player, {
			Success = false,
			Error = "Aproxime-se de " .. storeName .. " para comprar itens",
		})
		return
	end

	local success, result = ShopService.PurchaseItem(player, itemId, storeId)
	local response = { Success = success }
	if success then
		response.Item = result
	else
		response.Error = result
	end
	remotes.ShopPurchase:FireClient(player, response)
end)

remotes.RequestPropertyCatalog.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "property-catalog") then
		return nil, "Aguarde antes de atualizar o catálogo de imóveis"
	end
	return PropertyService.GetCatalog()
end

remotes.RequestOwnedProperties.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "owned-properties") then
		return nil, "Aguarde antes de atualizar seus imóveis"
	end
	return PropertyService.GetOwnedProperties(player)
end

remotes.PropertyPurchase.OnServerEvent:Connect(function(player, propertyId)
	if not RateLimitService.Allow(player, "property.request", REQUEST_COOLDOWN) then
		remotes.PropertyPurchase:FireClient(player, {
			Success = false,
			Error = "Aguarde antes de fazer outra compra",
		})
		return
	end

	if typeof(propertyId) ~= "string" or not PropertyService.IsNearPurchasePoint(player, propertyId) then
		remotes.PropertyPurchase:FireClient(player, {
			Success = false,
			Error = "Aproxime-se do imóvel para concluir a compra",
		})
		return
	end

	local success, result = PropertyService.PurchaseProperty(player, propertyId)
	local response = { Success = success }
	if success then
		response.Property = result
	else
		response.Error = result
	end
	remotes.PropertyPurchase:FireClient(player, response)
end)

remotes.RequestPropertyEntry.OnServerEvent:Connect(function(player, propertyId)
	if not RateLimitService.Allow(player, "property.entry", REQUEST_COOLDOWN) then
		remotes.RequestPropertyEntry:FireClient(player, {
			Success = false,
			PropertyId = propertyId,
			Message = "Aguarde antes de visitar outro imóvel",
		})
		return
	end

	local success, message = PropertyService.TeleportToProperty(player, propertyId)
	remotes.RequestPropertyEntry:FireClient(player, {
		Success = success,
		PropertyId = propertyId,
		Message = message,
	})
end)

remotes.PropertyStyleRequest.OnServerEvent:Connect(function(player, propertyId, styleId)
	if not RateLimitService.Allow(player, "property.style", REQUEST_COOLDOWN) then
		remotes.PropertyStyleResult:FireClient(player, {
			Success = false,
			PropertyId = typeof(propertyId) == "string" and propertyId or nil,
			Message = "Aguarde antes de alterar a decoração",
		})
		return
	end

	local success, result = PropertyService.SetInteriorStyle(player, propertyId, styleId)
	local response = { Success = success }
	if success then
		for key, value in pairs(result) do
			response[key] = value
		end
	else
		response.PropertyId = typeof(propertyId) == "string" and propertyId or nil
		response.Message = result
	end
	remotes.PropertyStyleResult:FireClient(player, response)
end)

remotes.RequestPropertyDecorCatalog.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "property-decor") then
		return nil, "Aguarde antes de atualizar o catálogo de decoração"
	end
	return PropertyService.GetDecorCatalog()
end

remotes.PropertyDecorRequest.OnServerEvent:Connect(function(player, propertyId, decorId)
	if not RateLimitService.Allow(player, "property.decor", REQUEST_COOLDOWN) then
		remotes.PropertyDecorResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de alterar a decoração",
		})
		return
	end

	local success, result = PropertyService.SetInteriorDecor(player, propertyId, decorId)
	local response = { Success = success }
	if success and type(result) == "table" then
		for key, value in pairs(result) do
			response[key] = value
		end
	else
		response.Message = tostring(result)
	end
	remotes.PropertyDecorResult:FireClient(player, response)
end)

remotes.PropertyInviteRequest.OnServerEvent:Connect(function(player, propertyId, guestUserId)
	if not RateLimitService.Allow(player, "property.invite.send", REQUEST_COOLDOWN) then
		remotes.PropertyInviteResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de enviar outro convite",
		})
		return
	end

	local success, message = PropertyService.InviteGuest(player, propertyId, guestUserId)
	remotes.PropertyInviteResult:FireClient(player, {
		Success = success,
		Message = message,
	})
end)

remotes.PropertyInviteResponse.OnServerEvent:Connect(function(player, response)
	if not RateLimitService.Allow(player, "property.invite.respond", REQUEST_COOLDOWN) then
		remotes.PropertyInviteResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de responder ao convite",
		})
		return
	end

	local success, message = PropertyService.RespondToInvite(player, response)
	remotes.PropertyInviteResult:FireClient(player, {
		Success = success,
		Message = message,
	})
end)

remotes.RequestVehicleCatalog.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "vehicle-catalog") then
		return nil, "Aguarde antes de atualizar o catálogo de veículos"
	end
	return VehicleService.GetCatalog()
end

remotes.RequestVehiclePaintCatalog.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "vehicle-paint-catalog") then
		return nil, "Aguarde antes de atualizar o catálogo de pinturas"
	end
	return VehicleService.GetPaintCatalog()
end

remotes.RequestOwnedVehicles.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "owned-vehicles") then
		return nil, "Aguarde antes de atualizar seus veículos"
	end
	return VehicleService.GetOwnedVehicles(player)
end

remotes.RequestActiveVehicle.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "active-vehicle") then
		return nil, "Aguarde antes de atualizar o veículo ativo"
	end
	return VehicleService.GetActiveVehicleStatus(player) or false
end

remotes.VehicleStoreRequest.OnServerEvent:Connect(function(player)
	if not RateLimitService.Allow(player, "vehicle.store", SPAWN_COOLDOWN) then
		remotes.VehicleStoreResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de guardar um veículo",
		})
		return
	end

	local isBoat = VehicleService.IsActiveBoat(player)
	local isNearStorage = isBoat and isPlayerNearPrompt(player, "BoatStorePoint", "BoatStorePrompt")
		or (not isBoat and isPlayerNearPrompt(player, "GaragePoint", "GaragePrompt"))
	if not isNearStorage then
		remotes.VehicleStoreResult:FireClient(player, {
			Success = false,
			Message = isBoat and "Aproxime-se do píer da marina para guardar sua lancha"
				or "Aproxime-se da garagem para guardar seu veículo",
		})
		return
	end

	local success, message = VehicleService.DespawnVehicle(player)
	remotes.VehicleStoreResult:FireClient(player, {
		Success = success,
		Message = message,
	})
end)

remotes.VehiclePaintRequest.OnServerEvent:Connect(function(player, vehicleId, paintId)
	if not RateLimitService.Allow(player, "vehicle.paint", REQUEST_COOLDOWN) then
		remotes.VehiclePaintResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de alterar a pintura",
		})
		return
	end

	if not isPlayerNearPrompt(player, "GaragePoint", "GaragePrompt") then
		remotes.VehiclePaintResult:FireClient(player, {
			Success = false,
			Message = "Aproxime-se da garagem para personalizar seu veículo",
		})
		return
	end

	local success, result = VehicleService.SetVehiclePaint(player, vehicleId, paintId)
	local response = { Success = success }
	if success and type(result) == "table" then
		for key, value in pairs(result) do
			response[key] = value
		end
	else
		response.Message = tostring(result)
	end
	remotes.VehiclePaintResult:FireClient(player, response)
end)

remotes.RequestWorkJobs.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "work-jobs") then
		return nil, "Aguarde antes de atualizar as profissões"
	end
	return WorkService.GetJobs(player)
end

remotes.RequestActiveWork.OnServerInvoke = function(player)
	if not allowRemoteQuery(player, "active-work") then
		return nil, "Aguarde antes de atualizar o trabalho atual"
	end
	return WorkService.GetActiveJob(player) or {}
end

remotes.RequestClubStatus.OnServerInvoke = function(player)
	if not RateLimitService.Allow(player, "club.status", Config.RateLimits.EventCatalogCooldown) then
		return nil, "Aguarde antes de atualizar o status do clube"
	end
	return ClubService.GetStatus(player)
end

remotes.ClubPerformanceRequest.OnServerEvent:Connect(function(player, action, styleId)
	if not RateLimitService.Allow(player, "club.performance", Config.RateLimits.ClubPerformanceCooldown) then
		remotes.ClubPerformanceResult:FireClient(player, {
			Success = false,
			Message = "Aguarde antes de enviar outro comando para a cabine",
		})
		return
	end

	local success, message = ClubService.HandleRequest(player, action, styleId)
	remotes.ClubPerformanceResult:FireClient(player, {
		Success = success,
		Message = message,
	})
end)

remotes.WorkJobRequest.OnServerEvent:Connect(function(player, action, jobId, pointName)
	local success, result = WorkService.HandleRequest(player, action, jobId, pointName)
	local response = { Success = success }

	if success then
		if type(result) == "table" then
			for key, value in pairs(result) do
				response[key] = value
			end
		else
			response.Message = tostring(result)
		end
	else
		response.Message = tostring(result)
	end

	remotes.WorkJobResult:FireClient(player, response)
end)

remotes.VehiclePurchase.OnServerEvent:Connect(function(player, vehicleId)
	if not RateLimitService.Allow(player, "vehicle.request", REQUEST_COOLDOWN) then
		remotes.VehiclePurchase:FireClient(player, {
			Success = false,
			Error = "Aguarde antes de tentar novamente",
		})
		return
	end

	local isBoat = VehicleService.IsBoat(vehicleId)
	local isNearPurchase = isBoat and isPlayerNearPrompt(player, "BoatPurchasePoint", "BoatPurchasePrompt")
		or (not isBoat and isPlayerNearPrompt(player, "DealershipPurchasePoint", "PurchasePrompt"))
	if not isNearPurchase then
		remotes.VehiclePurchase:FireClient(player, {
			Success = false,
			Error = isBoat and "Aproxime-se da Royal Marina para comprar uma lancha"
				or "Aproxime-se do ponto de compra da concessionária",
		})
		return
	end

	local success, result = VehicleService.PurchaseVehicle(player, vehicleId)
	local response = { Success = success }
	if success then
		response.Vehicle = result
	else
		response.Error = result
	end
	remotes.VehiclePurchase:FireClient(player, response)
end)

remotes.VehicleTestDriveRequest.OnServerEvent:Connect(function(player, vehicleId)
	local function respond(success, result)
		local response = { Success = success }
		if success then
			response.Vehicle = result
			response.Message = string.format("Test drive iniciado por %d segundos.", result.Duration)
		else
			response.Message = tostring(result)
		end
		remotes.VehicleTestDriveResult:FireClient(player, response)
	end

	if not RateLimitService.Allow(player, "vehicle.test-drive", SPAWN_COOLDOWN) then
		respond(false, "Aguarde antes de iniciar outro test drive")
		return
	end

	local isBoat = VehicleService.IsBoat(vehicleId)
	local isNearPurchase = isBoat and isPlayerNearPrompt(player, "BoatPurchasePoint", "BoatPurchasePrompt")
		or (not isBoat and isPlayerNearPrompt(player, "DealershipPurchasePoint", "PurchasePrompt"))
	if not isNearPurchase then
		respond(
			false,
			isBoat and "Aproxime-se da Royal Marina para iniciar o test drive"
				or "Aproxime-se da concessionária para iniciar o test drive"
		)
		return
	end

	local world = workspace:FindFirstChild("HighSocietyWorld")
	local spawnPointName = isBoat and "BoatSpawnPoint" or "VehicleSpawnPoint"
	local spawnPoint = world and world:FindFirstChild(spawnPointName, true)
	local success, result = VehicleService.StartTestDrive(player, vehicleId, spawnPoint)
	respond(success, result)
end)

local function handleVehicleSpawn(player, vehicleId, requestRemote)
	local function respond(success, message)
		local result = {
			Success = success,
			VehicleId = typeof(vehicleId) == "string" and vehicleId or nil,
			Message = message,
		}
		if not success then
			result.Error = message
		end

		requestRemote:FireClient(player, result)
		remotes.VehicleSpawnResult:FireClient(player, result)
	end

	if not RateLimitService.Allow(player, "vehicle.spawn", SPAWN_COOLDOWN) then
		respond(false, "Aguarde antes de tentar retirar outro veículo")
		return
	end

	local isBoat = VehicleService.IsBoat(vehicleId)
	local nearVehiclePoint = isBoat
			and (isPlayerNearPrompt(player, "BoatPurchasePoint", "BoatPurchasePrompt") or isPlayerNearPrompt(
				player,
				"BoatStorePoint",
				"BoatStorePrompt"
			))
		or (
			not isBoat
			and (
				isPlayerNearPrompt(player, "GaragePoint", "GaragePrompt")
				or isPlayerNearPrompt(player, "VehicleSpawnPoint", "SpawnVehiclePrompt")
			)
		)
	if not nearVehiclePoint then
		respond(
			false,
			isBoat and "Aproxime-se da Royal Marina para retirar a lancha" or "Aproxime-se do ponto da garagem"
		)
		return
	end

	local world = workspace:FindFirstChild("HighSocietyWorld")
	local spawnPointName = isBoat and "BoatSpawnPoint" or "VehicleSpawnPoint"
	local spawnPoint = workspace:FindFirstChild(spawnPointName)
		or (world and world:FindFirstChild(spawnPointName, true))
	if not spawnPoint or not spawnPoint:IsA("BasePart") then
		respond(false, "Workspace." .. spawnPointName .. " não foi encontrado")
		return
	end

	local success, result = VehicleService.SpawnVehicle(player, vehicleId, spawnPoint)
	if not success then
		respond(false, result)
		return
	end

	Logger.Info("Vehicle", string.format("SPAWN | %s | %s", player.Name, vehicleId))
	respond(true, isBoat and "Lancha retirada da Royal Marina" or "Veículo retirado da garagem")
end

remotes.VehicleDrive.OnServerEvent:Connect(function(player, throttle, steer)
	if not RateLimitService.Allow(player, "vehicle.drive", Config.RateLimits.VehicleControlCooldown) then
		return
	end

	local ok, reason = VehicleService.SetDriverControls(player, throttle, steer)
	if not ok then
		if reason ~= "Nenhum veículo ativo para este jogador" then
			Logger.Warn("Vehicle", string.format("Comando recusado para %s: %s", player.Name, reason))
		end
	end
end)

remotes.RequestVehicleSpawn.OnServerEvent:Connect(function(player, vehicleId)
	handleVehicleSpawn(player, vehicleId, remotes.RequestVehicleSpawn)
end)

remotes.LegacyRequestSpawnVehicle.OnServerEvent:Connect(function(player, vehicleId)
	handleVehicleSpawn(player, vehicleId, remotes.LegacyRequestSpawnVehicle)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	VehicleService.DespawnVehicle(player)
	PlayerMarketService.CleanupPlayer(player)
	WorkService.CleanupPlayer(player)
	ClubService.CleanupPlayer(player)
	PropertyService.CleanupPlayer(player)
	EventService.CleanupPlayer(player)
	PlayerSafetyService.CleanupPlayer(player)
	RateLimitService.CleanupPlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Logger.Info("Bootstrap", "Economia, loja, aparência, propriedades, garagem e profissões inicializadas")
