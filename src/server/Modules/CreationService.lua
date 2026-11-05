local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))
local AdminService = require(script.Parent.AdminService)
local RateLimitService = require(script.Parent.RateLimitService)
local CreationBuilder = require(script.Parent.CreationBuilder)

local CreationService = {}

local settings = Config.CreationModeration
local dataStore
local initialized = false
local worldRoot
local QUEUE_KEY = "Submissions"

local themes = {
	["tema de jardim"] = "Jardim",
	["tema costeiro"] = "Costeiro",
	["tema urbano"] = "Urbano",
}

local layouts = {
	["layout de pavilhão"] = "Pavilhão",
	["layout de praça"] = "Praça",
	["layout de passeio"] = "Passeio",
}

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
		Logger.Warn("Creation", string.format("Tentativa %d/%d falhou: %s", attempt, Config.DataStore.MaxRetries, tostring(result)))
		if attempt < Config.DataStore.MaxRetries then
			task.wait(attempt * 2)
		end
	end
	return false, lastError
end

local function normalizeQueue(value)
	if value == nil then
		return {}
	end
	if type(value) ~= "table" then
		return nil, "A fila salva de criações tem formato inválido"
	end
	local queue = {}
	for _, entry in ipairs(value) do
		if
			type(entry) == "table"
			and type(entry.Id) == "string"
			and #entry.Id <= 64
			and isFiniteNumber(entry.CreatorUserId)
			and entry.CreatorUserId > 0
			and entry.CreatorUserId % 1 == 0
			and type(entry.Theme) == "string"
			and themes[entry.Theme]
			and type(entry.Layout) == "string"
			and layouts[entry.Layout]
			and (entry.Status == "Pending" or entry.Status == "Approved" or entry.Status == "Rejected")
			and isFiniteNumber(entry.SubmittedAt)
			and entry.SubmittedAt >= 0
			and entry.SubmittedAt <= 253_402_300_799
		then
			table.insert(queue, {
				Id = entry.Id,
				CreatorUserId = math.floor(entry.CreatorUserId),
				CreatorName = type(entry.CreatorName) == "string" and string.sub(entry.CreatorName, 1, 20) or "Jogador",
				Theme = entry.Theme,
				Layout = entry.Layout,
				Status = entry.Status,
				SubmittedAt = math.floor(entry.SubmittedAt),
				ReviewedAt = isFiniteNumber(entry.ReviewedAt)
						and entry.ReviewedAt >= 0
						and entry.ReviewedAt <= 253_402_300_799
					and math.floor(entry.ReviewedAt)
					or nil,
				ReviewerUserId = isFiniteNumber(entry.ReviewerUserId)
						and entry.ReviewerUserId > 0
						and entry.ReviewerUserId % 1 == 0
					and math.floor(entry.ReviewerUserId)
					or nil,
				ReviewId = type(entry.ReviewId) == "string" and string.sub(entry.ReviewId, 1, 64) or nil,
			})
		end
	end
	return queue
end

local function findById(queue, id)
	for _, entry in ipairs(queue) do
		if entry.Id == id then
			return entry
		end
	end
	return nil
end

local function readQueue()
	if not dataStore then
		return nil, "O armazenamento da fila de criações está indisponível"
	end
	local success, result = retry(function()
		return dataStore:GetAsync(QUEUE_KEY)
	end)
	if not success then
		return nil, "Não foi possível consultar a fila de criações: " .. tostring(result)
	end
	return normalizeQueue(result)
end

local function copyPublicEntry(entry)
	return {
		Id = entry.Id,
		CreatorUserId = entry.CreatorUserId,
		CreatorName = entry.CreatorName,
		Theme = themes[entry.Theme],
		Layout = layouts[entry.Layout],
		SubmittedAt = entry.SubmittedAt,
	}
end

local function ensureReviewer(player)
	if not RateLimitService.Allow(player, "creations.review.query", Config.RateLimits.CreationQueryCooldown) then
		return false, "Aguarde antes de atualizar a fila de revisão"
	end
	local isAdmin, reason = AdminService.GetStatus(player)
	if not isAdmin then
		return false, reason or "Acesso restrito ao criador e administradores"
	end
	return true
end

function CreationService.Init()
	worldRoot = workspace:FindFirstChild(Config.Map.WorldName)
	if initialized then
		return dataStore ~= nil
	end
	initialized = true
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(settings.DataStoreName)
	end)
	if not ok then
		Logger.Error("Creation", "Não foi possível abrir o armazenamento de criações: " .. tostring(result))
		return false
	end
	dataStore = result
	task.spawn(function()
		local approved, err = readQueue()
		if not approved then
			Logger.Warn("Creation", "Não foi possível carregar criações aprovadas para a Galeria: " .. tostring(err))
			return
		end
		local publicCreations = {}
		for _, entry in ipairs(approved) do
			if entry.Status == "Approved" then
				table.insert(publicCreations, copyPublicEntry(entry))
			end
		end
		table.sort(publicCreations, function(left, right)
			return left.SubmittedAt > right.SubmittedAt
		end)
		while #publicCreations > settings.MaxPublicCreations do
			table.remove(publicCreations)
		end
		local updated, updateError = CreationBuilder.Update(worldRoot, publicCreations)
		if not updated then
			Logger.Warn("Creation", "Não foi possível construir a Galeria de criações: " .. tostring(updateError))
		end
	end)
	return true
end

function CreationService.SubmitWorldConcept(player, submissionId, theme, layout)
	if not dataStore then
		return false, "A fila persistente de criações está indisponível"
	end
	if
		typeof(player) ~= "Instance"
		or not player:IsA("Player")
		or player.Parent ~= Players
		or type(submissionId) ~= "string"
		or #submissionId > 64
		or not submissionId:match("^[%w%-]+$")
		or not themes[theme]
		or not layouts[layout]
	then
		return false, "Proposta de cenário inválida"
	end
	if not RateLimitService.Allow(player, "creations.submit", Config.RateLimits.CreationSubmitCooldown) then
		return false, "Aguarde antes de reenviar a proposta para revisão"
	end

	local success, result = retry(function()
		return dataStore:UpdateAsync(QUEUE_KEY, function(current)
			local queue, queueError = normalizeQueue(current)
			if not queue then
				error(queueError)
			end
			local existing = findById(queue, submissionId)
			if existing then
				return queue
			end
			for _, entry in ipairs(queue) do
				if entry.CreatorUserId == player.UserId and entry.Status == "Pending" then
					return queue
				end
			end

			if #queue >= settings.MaxStoredSubmissions then
				local removableIndex
				for index, entry in ipairs(queue) do
					if entry.Status ~= "Pending" then
						removableIndex = index
						break
					end
				end
				if not removableIndex then
					return queue
				end
				table.remove(queue, removableIndex)
			end

			table.insert(queue, {
				Id = submissionId,
				CreatorUserId = player.UserId,
				CreatorName = player.Name,
				Theme = theme,
				Layout = layout,
				Status = "Pending",
				SubmittedAt = os.time(),
			})
			return queue
		end)
	end)
	if not success then
		return false, "Não foi possível salvar a proposta: " .. tostring(result)
	end

	local queue, queueError = normalizeQueue(result)
	if not queue then
		return false, queueError
	end
	local entry = findById(queue, submissionId)
	if entry and entry.CreatorUserId == player.UserId and entry.Status == "Pending" then
		return true, "Proposta enviada para revisão"
	end
	for _, candidate in ipairs(queue) do
		if candidate.CreatorUserId == player.UserId and candidate.Status == "Pending" then
			return false, "Você já tem uma proposta aguardando revisão"
		end
	end
	return false, "A fila está cheia; tente novamente mais tarde"
end

function CreationService.GetApproved(player)
	if not RateLimitService.Allow(player, "creations.gallery.query", Config.RateLimits.CreationQueryCooldown) then
		return nil, "Aguarde antes de atualizar a Galeria"
	end
	local queue, err = readQueue()
	if not queue then
		return nil, err
	end
	local approved = {}
	for _, entry in ipairs(queue) do
		if entry.Status == "Approved" then
			table.insert(approved, copyPublicEntry(entry))
		end
	end
	table.sort(approved, function(left, right)
		return left.SubmittedAt > right.SubmittedAt
	end)
	while #approved > settings.MaxPublicCreations do
		table.remove(approved)
	end
	local updated, updateError = CreationBuilder.Update(worldRoot, approved)
	if not updated then
		Logger.Warn("Creation", "Não foi possível atualizar as maquetes da Galeria: " .. tostring(updateError))
		return nil, "Não foi possível atualizar a Galeria: " .. tostring(updateError)
	end
	return approved
end

function CreationService.GetPending(player)
	local authorized, authError = ensureReviewer(player)
	if not authorized then
		return nil, authError
	end
	local queue, err = readQueue()
	if not queue then
		return nil, err
	end
	local pending = {}
	for _, entry in ipairs(queue) do
		if entry.Status == "Pending" then
			table.insert(pending, copyPublicEntry(entry))
		end
	end
	table.sort(pending, function(left, right)
		return left.SubmittedAt < right.SubmittedAt
	end)
	return pending
end

function CreationService.Review(player, submissionId, decision)
	if not RateLimitService.Allow(player, "creations.review.action", Config.RateLimits.CreationReviewCooldown) then
		return false, "Aguarde antes de revisar outra proposta"
	end
	local isAdmin, authError = AdminService.GetStatus(player)
	if not isAdmin then
		return false, authError or "Acesso restrito ao criador e administradores"
	end
	if
		type(submissionId) ~= "string"
		or #submissionId > 64
		or not submissionId:match("^[%w%-]+$")
		or (decision ~= "Approve" and decision ~= "Reject")
	then
		return false, "Ação de revisão inválida"
	end
	if not dataStore then
		return false, "A fila persistente de criações está indisponível"
	end

	local targetStatus = decision == "Approve" and "Approved" or "Rejected"
	local reviewId = HttpService:GenerateGUID(false)
	local success, result = retry(function()
		return dataStore:UpdateAsync(QUEUE_KEY, function(current)
			local queue, queueError = normalizeQueue(current)
			if not queue then
				error(queueError)
			end
			local entry = findById(queue, submissionId)
			if entry and entry.Status == "Pending" then
				entry.Status = targetStatus
				entry.ReviewedAt = os.time()
				entry.ReviewerUserId = player.UserId
				entry.ReviewId = reviewId
			end
			return queue
		end)
	end)
	if not success then
		Logger.Error("Creation", "Falha na revisão da proposta " .. submissionId .. ": " .. tostring(result))
		return false, "Não foi possível registrar a decisão: " .. tostring(result)
	end
	local queue, queueError = normalizeQueue(result)
	if not queue then
		return false, queueError
	end
	local entry = findById(queue, submissionId)
	if not entry or entry.ReviewId ~= reviewId or entry.Status ~= targetStatus then
		return false, "Proposta não encontrada ou já revisada"
	end

	Logger.Info(
		"Creation",
		string.format(
			"REVIEW | submission=%s | creatorUserId=%d | reviewerUserId=%d | decision=%s",
			submissionId,
			entry.CreatorUserId,
			player.UserId,
			targetStatus
		)
	)
	if targetStatus == "Approved" then
		local approved = {}
		for _, candidate in ipairs(queue) do
			if candidate.Status == "Approved" then
				table.insert(approved, copyPublicEntry(candidate))
			end
		end
		table.sort(approved, function(left, right)
			return left.SubmittedAt > right.SubmittedAt
		end)
		while #approved > settings.MaxPublicCreations do
			table.remove(approved)
		end
		local updated, updateError = CreationBuilder.Update(worldRoot, approved)
		if not updated then
			Logger.Warn("Creation", "Aprovação registrada, mas a Galeria não foi atualizada: " .. tostring(updateError))
			return true, "Aprovação registrada; a Galeria será atualizada quando estiver disponível"
		end
	end
	return true, targetStatus == "Approved" and "Proposta aprovada e publicada na Galeria" or "Proposta recusada"
end

return CreationService
