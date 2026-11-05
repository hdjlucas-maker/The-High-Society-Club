local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))
local EconomyService = require(script.Parent.EconomyService)

local MonetizationService = {}

local settings = Config.Monetization
local productsById = {}
local duplicateProductIds = {}
local warnedUnknownProducts = {}
local resultRemote
local initialized = false

local function isConfiguredId(value)
	return type(value) == "number" and value % 1 == 0 and value > 0
end

local function setVipStatus(player, ownsPass, verified)
	if player.Parent ~= Players then
		return
	end
	player:SetAttribute("SocietyVIP", ownsPass == true)
	player:SetAttribute("SocietyVIPVerified", verified == true)
end

local function refreshVipStatus(player)
	local gamePassId = settings.VIPGamePassId
	if not isConfiguredId(gamePassId) then
		setVipStatus(player, false, true)
		return
	end

	for attempt = 1, Config.DataStore.MaxRetries do
		if player.Parent ~= Players then
			return
		end
		local success, ownsPass = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, gamePassId)
		if success and type(ownsPass) == "boolean" then
			setVipStatus(player, ownsPass, true)
			return
		end
		if attempt < Config.DataStore.MaxRetries then
			task.wait(attempt)
		else
			setVipStatus(player, false, false)
			Logger.Warn("Monetization", string.format("Falha ao verificar o Game Pass VIP de %s: %s", player.Name, tostring(ownsPass)))
		end
	end
end

local function handleReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local product = productsById[receiptInfo.ProductId]
	if not product then
		if not warnedUnknownProducts[receiptInfo.ProductId] then
			warnedUnknownProducts[receiptInfo.ProductId] = true
			Logger.Error(
				"Monetization",
				string.format("Developer Product %s não está cadastrado em Config.Monetization", tostring(receiptInfo.ProductId))
			)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted, alreadyProcessedOrError =
		EconomyService.GrantDeveloperProduct(player, receiptInfo.PurchaseId, tostring(receiptInfo.ProductId), product.Credits)
	if not granted then
		Logger.Warn(
			"Monetization",
			string.format(
				"Recibo %s aguardando processamento para %s: %s",
				tostring(receiptInfo.PurchaseId),
				player.Name,
				tostring(alreadyProcessedOrError)
			)
		)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if resultRemote and resultRemote.Parent then
		resultRemote:FireClient(player, {
			Success = true,
			Message = alreadyProcessedOrError and "Compra confirmada; este recibo já havia sido processado."
				or string.format("%s adicionados ao seu saldo.", product.Name),
		})
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Init(purchaseResultRemote)
	if initialized then
		return
	end
	initialized = true
	resultRemote = purchaseResultRemote

	for _, product in ipairs(settings.DeveloperProducts) do
		if type(product) == "table" and isConfiguredId(product.Id) then
			if productsById[product.Id] or duplicateProductIds[product.Id] then
				Logger.Error(
					"Monetization",
					"ID de Developer Product duplicado em Config.Monetization: " .. tostring(product.Id)
				)
				productsById[product.Id] = nil
				duplicateProductIds[product.Id] = true
			elseif
				type(product.Name) ~= "string"
				or type(product.Credits) ~= "number"
				or product.Credits % 1 ~= 0
				or product.Credits <= 0
				or product.Credits > Config.Economy.MaxCurrency
			then
				Logger.Error("Monetization", "Configuração inválida para Developer Product " .. tostring(product.Id))
			else
				productsById[product.Id] = product
			end
		end
	end

	MarketplaceService.ProcessReceipt = handleReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if gamePassId == settings.VIPGamePassId and wasPurchased then
			setVipStatus(player, true, true)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(refreshVipStatus, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(refreshVipStatus, player)
	end
end

return MonetizationService
