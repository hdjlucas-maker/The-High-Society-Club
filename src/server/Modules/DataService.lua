local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))

local DataService = {}

local dataStore
local initialized = false
local sessionPrefix = game.JobId ~= "" and game.JobId or HttpService:GenerateGUID(false)

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function retry(operation)
	local lastError
	for attempt = 1, Config.DataStore.MaxRetries do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = result
		Logger.Warn(
			"Data",
			string.format("Tentativa %d/%d falhou: %s", attempt, Config.DataStore.MaxRetries, tostring(result))
		)
		-- No Studio sem publicar/liberar APIs, repetir não adianta: segue com perfil temporário.
		local message = string.lower(tostring(result))
		if
			RunService:IsStudio()
			and (string.find(message, "studioaccesstoapis", 1, true) or string.find(message, "publish", 1, true))
		then
			break
		end
		if attempt < Config.DataStore.MaxRetries then
			task.wait(attempt * 2)
		end
	end
	return false, lastError
end

local function acquireProfileData(player, sessionId)
	local key = "Player_" .. player.UserId
	local deadline = os.clock() + Config.DataStore.SessionLockWait
	local invalidStoredData = false
	local lockedUntil

	while os.clock() < deadline do
		if not player.Parent then
			return nil, "Jogador saiu antes de carregar os dados", true
		end

		invalidStoredData = false
		lockedUntil = nil
		local success, result = retry(function()
			return dataStore:UpdateAsync(key, function(stored)
				invalidStoredData = false
				lockedUntil = nil
				if stored ~= nil and type(stored) ~= "table" then
					invalidStoredData = true
					return nil
				end

				stored = type(stored) == "table" and stored or {}
				local lock = stored.__SessionLock
				if
					type(lock) == "table"
					and lock.SessionId ~= sessionId
					and isFiniteNumber(lock.ExpiresAt)
					and lock.ExpiresAt > os.time()
				then
					lockedUntil = lock.ExpiresAt
					return nil
				end

				stored.__SessionLock = {
					SessionId = sessionId,
					ExpiresAt = os.time() + Config.DataStore.SessionLockTtl,
				}
				return stored
			end)
		end)

		if not success then
			return nil, tostring(result), false
		end
		if invalidStoredData then
			return nil, "Os dados salvos do jogador não têm o formato esperado", true
		end
		if
			type(result) == "table"
			and type(result.__SessionLock) == "table"
			and result.__SessionLock.SessionId == sessionId
		then
			return result
		end

		local waitTime = lockedUntil and math.clamp(math.min(5, lockedUntil - os.time()), 1, 5) or 5
		task.wait(waitTime)
	end

	return nil, "Os dados deste jogador continuam abertos em outro servidor", true
end

function DataService.Init()
	if initialized then
		return dataStore ~= nil
	end
	initialized = true

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStore.Name)
	end)
	if not ok then
		Logger.Warn("Data", "Não foi possível obter o DataStore: " .. tostring(result))
		return false
	end

	dataStore = result
	return true
end

function DataService.IsAvailable()
	return dataStore ~= nil
end

function DataService.LoadProfile(player)
	if not player or not player:IsA("Player") then
		return nil, "Jogador inválido", true
	end
	if not dataStore then
		return nil, "DataStore indisponível", false
	end

	local sessionId = sessionPrefix .. ":" .. HttpService:GenerateGUID(false)
	local data, loadError, lockConflict = acquireProfileData(player, sessionId)
	return data, loadError, lockConflict, sessionId
end

function DataService.SaveProfile(userId, sessionId, payload)
	if typeof(userId) ~= "number" or userId <= 0 or typeof(sessionId) ~= "string" or typeof(payload) ~= "table" then
		return false, "Dados de salvamento inválidos", false
	end
	if not dataStore then
		return false, "DataStore indisponível", false
	end

	local storedPayload = table.clone(payload)
	storedPayload.__SessionLock = {
		SessionId = sessionId,
		ExpiresAt = os.time() + Config.DataStore.SessionLockTtl,
	}

	local success, result = retry(function()
		return dataStore:UpdateAsync("Player_" .. userId, function(stored)
			local lock = type(stored) == "table" and stored.__SessionLock
			if type(lock) ~= "table" or lock.SessionId ~= sessionId then
				return nil
			end
			return storedPayload
		end)
	end)
	if not success then
		return false, tostring(result), false
	end
	if
		type(result) ~= "table"
		or type(result.__SessionLock) ~= "table"
		or result.__SessionLock.SessionId ~= sessionId
	then
		return false, "A sessão dos dados foi perdida", true
	end

	return true
end

function DataService.ApplyDeveloperProductReceipt(userId, sessionId, purchaseId, productId, credits, playerName, payload)
	if
		typeof(userId) ~= "number"
		or userId <= 0
		or type(sessionId) ~= "string"
		or type(purchaseId) ~= "string"
		or purchaseId == ""
		or #purchaseId > 100
		or type(productId) ~= "string"
		or #productId > 40
		or not isFiniteNumber(credits)
		or credits <= 0
		or credits % 1 ~= 0
		or credits > Config.Economy.MaxCurrency
		or type(playerName) ~= "string"
		or type(payload) ~= "table"
		or not isFiniteNumber(payload.coins)
		or payload.coins < 0
		or payload.coins % 1 ~= 0
		or payload.coins > Config.Economy.MaxCurrency
		or not isFiniteNumber(payload.TotalEarned)
		or payload.TotalEarned < 0
		or payload.TotalEarned % 1 ~= 0
		or type(payload.transactions) ~= "table"
	then
		return false, "Dados de recibo inválidos"
	end
	if not dataStore then
		return false, "DataStore indisponível"
	end

	local lostSession = false
	local balanceLimitReached = false
	local alreadyProcessed = false
	local invalidData = false
	local receiptAppliedByCall = false
	local success, result = retry(function()
		return dataStore:UpdateAsync("Player_" .. userId, function(stored)
			lostSession = false
			balanceLimitReached = false
			alreadyProcessed = false
			invalidData = false
			if type(stored) ~= "table" then
				invalidData = true
				return nil
			end

			local lock = stored.__SessionLock
			if type(lock) ~= "table" or lock.SessionId ~= sessionId then
				lostSession = true
				return nil
			end

			local processedReceipts = type(stored.processedDeveloperReceipts) == "table"
				and stored.processedDeveloperReceipts
				or {}
			if processedReceipts[purchaseId] == true then
				alreadyProcessed = not receiptAppliedByCall
				return stored
			end

			if payload.coins > Config.Economy.MaxCurrency - credits then
				balanceLimitReached = true
				return nil
			end

			local updated = table.clone(stored)
			updated.coins = payload.coins + credits
			updated.TotalEarned = math.min(Config.Economy.MaxCurrency, payload.TotalEarned + credits)

			local transactions = table.clone(payload.transactions)
			table.insert(transactions, {
				Type = "DeveloperProductPurchase",
				Amount = credits,
				Time = os.time(),
				UserId = userId,
				PlayerName = playerName,
				Result = "Success",
				ProductId = productId,
				ReceiptId = purchaseId,
			})
			while #transactions > Config.Economy.MaxTransactions do
				table.remove(transactions, 1)
			end
			updated.transactions = transactions

			local receiptMap = table.clone(processedReceipts)
			if type(payload.processedDeveloperReceipts) == "table" then
				for storedPurchaseId, wasProcessed in pairs(payload.processedDeveloperReceipts) do
					if wasProcessed == true then
						receiptMap[storedPurchaseId] = true
					end
				end
			end
			receiptMap[purchaseId] = true
			updated.processedDeveloperReceipts = receiptMap
			updated.__SessionLock = {
				SessionId = sessionId,
				ExpiresAt = os.time() + Config.DataStore.SessionLockTtl,
			}
			receiptAppliedByCall = true
			return updated
		end)
	end)

	if not success then
		return false, tostring(result)
	end
	if invalidData then
		return false, "Os dados salvos do jogador não têm o formato esperado"
	end
	if balanceLimitReached then
		return false, "O saldo está no limite; use créditos antes de resgatar esta compra"
	end
	if lostSession then
		return false, "A sessão dos dados foi perdida"
	end
	if
		type(result) ~= "table"
		or type(result.__SessionLock) ~= "table"
		or result.__SessionLock.SessionId ~= sessionId
		or type(result.processedDeveloperReceipts) ~= "table"
		or result.processedDeveloperReceipts[purchaseId] ~= true
	then
		return false, "Não foi possível confirmar o recibo no perfil"
	end

	return true, result, alreadyProcessed
end

function DataService.ReleaseProfileLock(userId, sessionId)
	if not dataStore then
		return false, "DataStore indisponível"
	end

	local success, result = retry(function()
		return dataStore:UpdateAsync("Player_" .. userId, function(stored)
			local lock = type(stored) == "table" and stored.__SessionLock
			if type(lock) ~= "table" or lock.SessionId ~= sessionId then
				return nil
			end

			stored.__SessionLock = nil
			return stored
		end)
	end)
	if not success then
		return false, tostring(result)
	end
	if type(result) ~= "table" or result.__SessionLock ~= nil then
		return false, "A sessão não é mais proprietária do bloqueio dos dados"
	end

	return true
end

return DataService
