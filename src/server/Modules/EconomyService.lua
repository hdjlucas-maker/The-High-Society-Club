local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))
local DataService = require(script.Parent.DataService)

local EconomyService = {}

local MAX_CURRENCY = Config.Economy.MaxCurrency
local MAX_TRANSACTIONS = Config.Economy.MaxTransactions
local AUTOSAVE_INTERVAL = Config.DataStore.AutosaveInterval

local currencyChanged
local profiles = {}
local loadingProfiles = {}
local savingProfiles = {}
local transactionLocks = {}
local closingProfiles = {}
local finalizingProfiles = {}
local initialized = false

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function sanitizeCurrency(value)
	if not isFiniteNumber(value) then
		return 0
	end

	return math.clamp(math.floor(value), 0, MAX_CURRENCY)
end

local function sanitizeProfessionCompletions(value)
	local result = {}
	if type(value) ~= "table" then
		return result
	end

	local count = 0
	for professionId, completions in pairs(value) do
		if
			count >= 20
			or type(professionId) ~= "string"
			or #professionId > 40
			or not professionId:match("^[%w_]+$")
		then
			continue
		end

		result[professionId] = sanitizeCurrency(completions)
		count += 1
	end

	return result
end

local function makeDefaultProfile(data, isTemporary)
	data = type(data) == "table" and data or {}

	local hasLegacyBalance = data.coins ~= nil or data.Credits ~= nil
	local bonusClaimed = data.FirstJoinBonusClaimed == true or (data.FirstJoinBonusClaimed == nil and hasLegacyBalance)

	return {
		coins = sanitizeCurrency(data.coins or data.Credits or 0),
		FirstJoinBonusClaimed = bonusClaimed,
		TotalEarned = sanitizeCurrency(data.TotalEarned or 0),
		TotalSpent = sanitizeCurrency(data.TotalSpent or 0),
		LastLogin = isFiniteNumber(data.LastLogin) and data.LastLogin or os.time(),
		inventory = type(data.inventory) == "table" and data.inventory or {},
		transactions = type(data.transactions) == "table" and data.transactions or {},
		achievements = type(data.achievements) == "table" and data.achievements or {},
		completedJobs = sanitizeCurrency(data.completedJobs or 0),
		professionCompletions = sanitizeProfessionCompletions(data.professionCompletions),
		eventPoints = sanitizeCurrency(data.eventPoints or 0),
		eventClaims = type(data.eventClaims) == "table" and data.eventClaims or {},
		dailyRewardDay = sanitizeCurrency(data.dailyRewardDay or 0),
		dailyRewardStreak = math.min(sanitizeCurrency(data.dailyRewardStreak or 0), 3650),
		properties = type(data.properties) == "table" and data.properties or {},
		vehicles = type(data.vehicles) == "table" and data.vehicles or {},
		equippedItems = type(data.equippedItems) == "table" and data.equippedItems or {},
		processedDeveloperReceipts = type(data.processedDeveloperReceipts) == "table"
			and data.processedDeveloperReceipts
			or {},
		Temporary = isTemporary == true,
	}
end

local function logTransaction(player, transaction)
	local reference = transaction.ItemId
		or transaction.PropertyId
		or transaction.VehicleId
		or transaction.JobId
		or "none"
	local peer = transaction.PeerUserId and (" | peerUserId=" .. tostring(transaction.PeerUserId)) or ""
	Logger.Info(
		"Economy",
		string.format(
			"TRANSACTION | userId=%d | player=%s | type=%s | amount=%d | result=%s | reference=%s%s",
			player.UserId,
			player.Name,
			transaction.Type,
			transaction.Amount,
			transaction.Result,
			reference,
			peer
		)
	)
end

local function makeTransaction(player, transaction)
	local normalized = {
		Type = transaction.Type,
		Amount = math.floor(transaction.Amount),
		Time = math.floor(transaction.Time or os.time()),
		UserId = player.UserId,
		PlayerName = player.Name,
		Result = "Success",
	}
	for _, field in ipairs({ "ItemId", "PropertyId", "VehicleId", "JobId", "ProductId" }) do
		if type(transaction[field]) == "string" then
			normalized[field] = transaction[field]
		end
	end
	if type(transaction.PeerUserId) == "number" and transaction.PeerUserId % 1 == 0 then
		normalized.PeerUserId = transaction.PeerUserId
	end
	return normalized
end

local function recordTransaction(player, profile, transaction)
	local entry = makeTransaction(player, transaction)
	table.insert(profile.transactions, entry)

	while #profile.transactions > MAX_TRANSACTIONS do
		table.remove(profile.transactions, 1)
	end
	logTransaction(player, entry)
end

local function updateLeaderstat(player, profile)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local credits = leaderstats:FindFirstChild("Society Credits")
	if not credits then
		credits = Instance.new("IntValue")
		credits.Name = "Society Credits"
		credits.Parent = leaderstats
	end

	credits.Value = profile.coins
	profile.Stats = credits
end

local function notifyClient(player, profile)
	if currencyChanged and currencyChanged.Parent then
		currencyChanged:FireClient(player, profile.coins)
	end
end

local function cloneTable(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, item in pairs(value) do
		copy[key] = cloneTable(item)
	end
	return copy
end

local function makeProfilePayload(profile)
	return {
		coins = profile.coins,
		FirstJoinBonusClaimed = profile.FirstJoinBonusClaimed,
		TotalEarned = profile.TotalEarned,
		TotalSpent = profile.TotalSpent,
		LastLogin = profile.LastLogin,
		inventory = cloneTable(profile.inventory),
		transactions = cloneTable(profile.transactions),
		achievements = cloneTable(profile.achievements),
		completedJobs = profile.completedJobs,
		professionCompletions = cloneTable(profile.professionCompletions),
		eventPoints = profile.eventPoints,
		eventClaims = cloneTable(profile.eventClaims),
		dailyRewardDay = profile.dailyRewardDay,
		dailyRewardStreak = profile.dailyRewardStreak,
		properties = cloneTable(profile.properties),
		vehicles = cloneTable(profile.vehicles),
		equippedItems = cloneTable(profile.equippedItems),
		processedDeveloperReceipts = cloneTable(profile.processedDeveloperReceipts),
	}
end

function EconomyService.Init(currencyRemote)
	currencyChanged = currencyRemote

	if initialized then
		return
	end
	initialized = true
	DataService.Init()

	Players.PlayerRemoving:Connect(function(player)
		EconomyService.FinalizePlayer(player)
	end)

	game:BindToClose(function()
		local pending = 0

		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				EconomyService.FinalizePlayer(player)
				pending -= 1
			end)
		end

		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in pairs(profiles) do
				task.spawn(EconomyService.SavePlayerData, player)
			end
		end
	end)
end

function EconomyService.LoadPlayer(player)
	if not player or not player:IsA("Player") then
		return nil, "Jogador inválido"
	end

	while loadingProfiles[player] do
		task.wait()
	end

	if profiles[player] then
		return profiles[player]
	end

	loadingProfiles[player] = true
	local function finish(profile, err)
		loadingProfiles[player] = nil
		return profile, err
	end

	local data
	local loadError
	local lockConflict
	local sessionId

	data, loadError, lockConflict, sessionId = DataService.LoadProfile(player)

	local temporary = false
	if loadError then
		if not RunService:IsStudio() or lockConflict then
			return finish(nil, tostring(loadError))
		end

		temporary = true
		Logger.Warn(
			"Economy",
			"Usando perfil temporário no Studio. Este perfil não será salvo: " .. tostring(loadError)
		)
		data = nil
	end

	if not player.Parent then
		if not temporary and sessionId then
			local released, releaseError = DataService.ReleaseProfileLock(player.UserId, sessionId)
			if not released then
				Logger.Warn(
					"Economy",
					string.format("Não foi possível liberar os dados de %s: %s", player.Name, tostring(releaseError))
				)
			end
		end
		return finish(nil, "Jogador saiu antes de concluir o carregamento")
	end

	local profile = makeDefaultProfile(data, temporary)
	profile.SessionLocked = not temporary
	profile.SessionId = sessionId
	profile.LastLogin = os.time()
	profile.Loaded = true
	profiles[player] = profile

	updateLeaderstat(player, profile)
	notifyClient(player, profile)

	return finish(profile)
end

function EconomyService.SavePlayerData(player, isFinalSave)
	while savingProfiles[player] or transactionLocks[player] do
		task.wait(0.05)
	end
	if closingProfiles[player] and not isFinalSave then
		return false, "Perfil sendo finalizado"
	end

	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return false, "Perfil não carregado"
	end

	if profile.Temporary then
		return true
	end

	if not DataService.IsAvailable() then
		return false, "DataStore indisponível"
	end
	if profile.LockLost then
		return false, "A sessão dos dados foi perdida"
	end

	savingProfiles[player] = true
	profile.LastLogin = os.time()

	local payload = makeProfilePayload(profile)
	local success, result, lockLost = DataService.SaveProfile(player.UserId, profile.SessionId, payload)
	savingProfiles[player] = nil

	if not success then
		local err = tostring(result)
		Logger.Warn("Economy", "Falha ao salvar " .. player.Name .. ": " .. err)
		if lockLost then
			profile.LockLost = true
			if player.Parent then
				player:Kick("A sessão dos seus dados foi interrompida. Entre novamente para proteger seu progresso.")
			end
		end
		return false, err
	end

	return true
end

function EconomyService.FinalizePlayer(player)
	if finalizingProfiles[player] then
		while finalizingProfiles[player] do
			task.wait(0.05)
		end
		return
	end

	finalizingProfiles[player] = true
	closingProfiles[player] = true
	while savingProfiles[player] do
		task.wait(0.05)
	end

	local profile = profiles[player]
	if profile and profile.Loaded then
		local saved, saveError = EconomyService.SavePlayerData(player, true)
		if saved and profile.SessionLocked then
			local released, releaseError = DataService.ReleaseProfileLock(player.UserId, profile.SessionId)
			if not released then
				Logger.Warn(
					"Economy",
					string.format("Não foi possível liberar os dados de %s: %s", player.Name, tostring(releaseError))
				)
			end
		elseif not saved then
			Logger.Warn(
				"Economy",
				string.format("Dados de %s podem não ter sido salvos ao sair: %s", player.Name, tostring(saveError))
			)
		end
	end

	profiles[player] = nil
	closingProfiles[player] = nil
	finalizingProfiles[player] = nil
end

function EconomyService.GetProfile(player)
	local profile = profiles[player]
	if not profile or not profile.Loaded or profile.LockLost then
		return nil
	end

	return profile
end

function EconomyService.GetCoins(player)
	local profile = EconomyService.GetProfile(player)
	return profile and profile.coins or nil
end

function EconomyService.GetRecentTransactions(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	local transactions = {}
	local firstIndex = math.max(1, #profile.transactions - 19)
	for index = #profile.transactions, firstIndex, -1 do
		local transaction = profile.transactions[index]
		if
			type(transaction) == "table"
			and type(transaction.Type) == "string"
			and isFiniteNumber(transaction.Amount)
			and transaction.Amount >= 0
			and transaction.Amount <= MAX_CURRENCY
			and isFiniteNumber(transaction.Time)
			and transaction.Time >= 0
			and transaction.Time <= 253_402_300_799
		then
			table.insert(transactions, {
				Type = transaction.Type,
				Amount = math.floor(transaction.Amount),
				Time = math.floor(transaction.Time),
				UserId = isFiniteNumber(transaction.UserId) and math.floor(transaction.UserId) or player.UserId,
				PlayerName = type(transaction.PlayerName) == "string" and transaction.PlayerName or player.Name,
				Result = type(transaction.Result) == "string" and transaction.Result or "Success",
				ItemId = type(transaction.ItemId) == "string" and transaction.ItemId or nil,
				PropertyId = type(transaction.PropertyId) == "string" and transaction.PropertyId or nil,
				VehicleId = type(transaction.VehicleId) == "string" and transaction.VehicleId or nil,
				JobId = type(transaction.JobId) == "string" and transaction.JobId or nil,
				ProductId = type(transaction.ProductId) == "string" and transaction.ProductId or nil,
				PeerUserId = isFiniteNumber(transaction.PeerUserId) and math.floor(transaction.PeerUserId) or nil,
			})
		end
	end

	return transactions
end

function EconomyService.CanAfford(player, amount)
	if not isFiniteNumber(amount) or amount <= 0 or amount % 1 ~= 0 then
		return false
	end

	local profile = EconomyService.GetProfile(player)
	return profile ~= nil and profile.coins >= amount
end

function EconomyService.AddCoins(player, amount, transactionMetadata)
	if not isFiniteNumber(amount) or amount <= 0 or amount % 1 ~= 0 or amount > MAX_CURRENCY then
		return false, "Quantidade inválida"
	end
	if transactionLocks[player] then
		return false, "Outra transação está em andamento"
	end
	transactionLocks[player] = true

	local profile = EconomyService.GetProfile(player)
	if not profile then
		transactionLocks[player] = nil
		return false, "Perfil do jogador ainda não foi carregado"
	end

	if profile.coins > MAX_CURRENCY - amount then
		transactionLocks[player] = nil
		return false, "Limite máximo de créditos atingido"
	end

	profile.coins += amount
	profile.TotalEarned = sanitizeCurrency(profile.TotalEarned + amount)
	local transaction = {
		Type = "Earn",
		Amount = amount,
		Time = os.time(),
	}
	if type(transactionMetadata) == "table" then
		if type(transactionMetadata.Type) == "string" then
			transaction.Type = transactionMetadata.Type
		end
		if type(transactionMetadata.ItemId) == "string" then
			transaction.ItemId = transactionMetadata.ItemId
		end
		if type(transactionMetadata.PropertyId) == "string" then
			transaction.PropertyId = transactionMetadata.PropertyId
		end
		if type(transactionMetadata.VehicleId) == "string" then
			transaction.VehicleId = transactionMetadata.VehicleId
		end
		if type(transactionMetadata.JobId) == "string" then
			transaction.JobId = transactionMetadata.JobId
		end
		if type(transactionMetadata.PeerUserId) == "number" then
			transaction.PeerUserId = transactionMetadata.PeerUserId
		end
	end
	recordTransaction(player, profile, transaction)

	updateLeaderstat(player, profile)
	notifyClient(player, profile)
	transactionLocks[player] = nil
	return true
end

function EconomyService.SpendCoins(player, amount, transactionMetadata)
	if not isFiniteNumber(amount) or amount <= 0 or amount % 1 ~= 0 then
		return false, "Quantidade inválida"
	end
	if transactionLocks[player] then
		return false, "Outra transação está em andamento"
	end
	transactionLocks[player] = true

	local profile = EconomyService.GetProfile(player)
	if not profile then
		transactionLocks[player] = nil
		return false, "Perfil do jogador ainda não foi carregado"
	end

	if profile.coins < amount then
		transactionLocks[player] = nil
		return false, "Créditos insuficientes"
	end

	profile.coins -= amount
	profile.TotalSpent = sanitizeCurrency(profile.TotalSpent + amount)
	local transaction = {
		Type = "Spend",
		Amount = amount,
		Time = os.time(),
	}
	if type(transactionMetadata) == "table" then
		for _, field in ipairs({ "Type", "ItemId", "PropertyId", "VehicleId", "JobId" }) do
			if type(transactionMetadata[field]) == "string" then
				transaction[field] = transactionMetadata[field]
			end
		end
		if type(transactionMetadata.PeerUserId) == "number" then
			transaction.PeerUserId = transactionMetadata.PeerUserId
		end
	end
	recordTransaction(player, profile, transaction)

	updateLeaderstat(player, profile)
	notifyClient(player, profile)
	transactionLocks[player] = nil
	return true
end

function EconomyService.AddCredits(player, amount, transactionMetadata)
	return EconomyService.AddCoins(player, amount, transactionMetadata)
end

function EconomyService.SpendCredits(player, amount, transactionMetadata)
	return EconomyService.SpendCoins(player, amount, transactionMetadata)
end

local function transferCredits(fromPlayer, toPlayer, amount, fee, metadata)
	if
		typeof(fromPlayer) ~= "Instance"
		or not fromPlayer:IsA("Player")
		or typeof(toPlayer) ~= "Instance"
		or not toPlayer:IsA("Player")
		or fromPlayer == toPlayer
	then
		return false, "Jogadores inválidos para transferência"
	end
	if fromPlayer.Parent ~= Players or toPlayer.Parent ~= Players then
		return false, "Um dos jogadores saiu da sessão"
	end
	if
		not isFiniteNumber(amount)
		or amount < 0
		or amount % 1 ~= 0
		or amount > MAX_CURRENCY
	then
		return false, "Quantidade de créditos inválida"
	end
	if not isFiniteNumber(fee) or fee < 0 or fee % 1 ~= 0 or fee > amount then
		return false, "Comissão inválida"
	end

	local senderProfile = EconomyService.GetProfile(fromPlayer)
	local recipientProfile = EconomyService.GetProfile(toPlayer)
	if not senderProfile or not recipientProfile then
		return false, "Os dados de um dos jogadores ainda não foram carregados"
	end
	if closingProfiles[fromPlayer] or closingProfiles[toPlayer] or savingProfiles[fromPlayer] or savingProfiles[toPlayer] then
		return false, "Os dados de um dos jogadores estão sendo salvos"
	end
	if transactionLocks[fromPlayer] or transactionLocks[toPlayer] then
		return false, "Outra transação está em andamento"
	end
	if senderProfile.coins < amount then
		return false, "Créditos insuficientes"
	end
	local recipientAmount = amount - fee
	if recipientProfile.coins > MAX_CURRENCY - recipientAmount then
		return false, "O destinatário atingiu o limite máximo de créditos"
	end

	transactionLocks[fromPlayer] = true
	transactionLocks[toPlayer] = true

	senderProfile.coins -= amount
	senderProfile.TotalSpent = sanitizeCurrency(senderProfile.TotalSpent + amount)
	recipientProfile.coins += recipientAmount
	recipientProfile.TotalEarned = sanitizeCurrency(recipientProfile.TotalEarned + recipientAmount)
	recipientProfile.TotalSpent = sanitizeCurrency(recipientProfile.TotalSpent + fee)

	local timestamp = os.time()
	local itemId = type(metadata) == "table" and type(metadata.ItemId) == "string" and metadata.ItemId or nil
	local senderType = type(metadata) == "table" and metadata.SenderType or "PlayerTransferSent"
	local recipientType = type(metadata) == "table" and metadata.RecipientType or "PlayerTransferReceived"
	if type(senderType) ~= "string" then
		senderType = "PlayerTransferSent"
	end
	if type(recipientType) ~= "string" then
		recipientType = "PlayerTransferReceived"
	end
	recordTransaction(fromPlayer, senderProfile, {
		Type = senderType,
		Amount = amount,
		Time = timestamp,
		PeerUserId = toPlayer.UserId,
		ItemId = itemId,
	})
	recordTransaction(toPlayer, recipientProfile, {
		Type = recipientType,
		Amount = recipientAmount,
		Time = timestamp,
		PeerUserId = fromPlayer.UserId,
		ItemId = itemId,
	})
	if fee > 0 then
		local feeType = type(metadata) == "table" and metadata.FeeType or "TransferFeePaid"
		if type(feeType) ~= "string" then
			feeType = "TransferFeePaid"
		end
		recordTransaction(toPlayer, recipientProfile, {
			Type = feeType,
			Amount = fee,
			Time = timestamp,
			ItemId = itemId,
		})
	end

	updateLeaderstat(fromPlayer, senderProfile)
	updateLeaderstat(toPlayer, recipientProfile)
	transactionLocks[fromPlayer] = nil
	transactionLocks[toPlayer] = nil
	notifyClient(fromPlayer, senderProfile)
	notifyClient(toPlayer, recipientProfile)
	return true
end

function EconomyService.TransferCredits(fromPlayer, toPlayer, amount, metadata)
	return transferCredits(fromPlayer, toPlayer, amount, 0, metadata)
end

function EconomyService.TransferCreditsWithFee(fromPlayer, toPlayer, amount, fee, metadata)
	return transferCredits(fromPlayer, toPlayer, amount, fee, metadata)
end

function EconomyService.GrantDeveloperProduct(player, purchaseId, productId, credits)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return false, "Jogador indisponível"
	end
	if
		type(purchaseId) ~= "string"
		or purchaseId == ""
		or #purchaseId > 100
		or type(productId) ~= "string"
		or #productId > 40
		or not isFiniteNumber(credits)
		or credits <= 0
		or credits % 1 ~= 0
		or credits > MAX_CURRENCY
	then
		return false, "Produto ou recibo inválido"
	end

	local profile = EconomyService.GetProfile(player)
	if not profile then
		return false, "Perfil do jogador ainda não foi carregado"
	end
	if profile.Temporary or not profile.SessionLocked or not DataService.IsAvailable() then
		return false, "Perfil persistente indisponível para confirmar a compra"
	end
	if profile.processedDeveloperReceipts[purchaseId] == true then
		return true, true
	end
	if closingProfiles[player] or savingProfiles[player] or transactionLocks[player] then
		return false, "O perfil está ocupado; a compra será processada novamente"
	end

	transactionLocks[player] = true
	local success, result, alreadyProcessed =
		DataService.ApplyDeveloperProductReceipt(
			player.UserId,
			profile.SessionId,
			purchaseId,
			productId,
			credits,
			player.Name,
			makeProfilePayload(profile)
		)
	if not success then
		transactionLocks[player] = nil
		if result == "A sessão dos dados foi perdida" then
			profile.LockLost = true
			if player.Parent then
				player:Kick("A sessão dos seus dados foi interrompida. Entre novamente para proteger seu progresso.")
			end
		end
		return false, result
	end

	if alreadyProcessed then
		profile.processedDeveloperReceipts[purchaseId] = true
		transactionLocks[player] = nil
		return true, true
	end

	profile.coins = sanitizeCurrency(result.coins)
	profile.TotalEarned = sanitizeCurrency(result.TotalEarned)
	profile.transactions = type(result.transactions) == "table" and cloneTable(result.transactions) or {}
	profile.processedDeveloperReceipts = type(result.processedDeveloperReceipts) == "table"
		and cloneTable(result.processedDeveloperReceipts)
		or {}
	updateLeaderstat(player, profile)
	notifyClient(player, profile)
	transactionLocks[player] = nil

	if not alreadyProcessed then
		Logger.Info(
			"Economy",
			string.format(
				"DEVELOPER_PRODUCT | userId=%d | productId=%s | credits=%d | receipt=%s",
				player.UserId,
				productId,
				credits,
				purchaseId
			)
		)
	end
	return true, alreadyProcessed == true
end

function EconomyService.RecordTransaction(player, transaction)
	local profile = EconomyService.GetProfile(player)
	if
		not profile
		or type(transaction) ~= "table"
		or type(transaction.Type) ~= "string"
		or not isFiniteNumber(transaction.Amount)
		or transaction.Amount < 0
		or transaction.Amount > MAX_CURRENCY
		or transaction.Amount % 1 ~= 0
		or not isFiniteNumber(transaction.Time)
		or transaction.Time < 0
		or transaction.Time > 253_402_300_799
	then
		return false
	end
	if transactionLocks[player] then
		return false
	end
	transactionLocks[player] = true

	recordTransaction(player, profile, transaction)
	transactionLocks[player] = nil
	return true
end

function EconomyService.ClaimFirstJoinBonus(player)
	local profile = EconomyService.GetProfile(player)
	if not profile or profile.FirstJoinBonusClaimed then
		return false
	end

	profile.FirstJoinBonusClaimed = true
	return true
end

return EconomyService
