local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))

local AdminService = {}
local RateLimitService = require(script.Parent.RateLimitService)

local initialized = false
local groupOwnerUserId
local groupLookupComplete = false
local MAX_MODERATION_LOGS = 50
local moderationLogs = {}

local function normalizeUserId(value)
	if
		type(value) ~= "number"
		or value ~= value
		or value <= 0
		or value > 9_007_199_254_740_991
		or value % 1 ~= 0
	then
		return nil
	end

	return value
end

local function recordModerationAction(admin, action, target, targetUserId, success, reason)
	local entry = {
		Timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
		ActorUserId = admin.UserId,
		ActorName = admin.Name,
		Action = action,
		TargetUserId = target and target.UserId or targetUserId,
		TargetName = target and target.Name or nil,
		Success = success,
		Reason = reason,
	}

	table.insert(moderationLogs, entry)
	if #moderationLogs > MAX_MODERATION_LOGS then
		table.remove(moderationLogs, 1)
	end

	local targetDescription = entry.TargetUserId and (" targetUserId=" .. tostring(entry.TargetUserId)) or ""
	local targetName = entry.TargetName and string.format(" targetName=%q", entry.TargetName) or ""
	local message = string.format(
		"action=%s actorUserId=%d actorName=%q%s%s success=%s reason=%q",
		action,
		entry.ActorUserId,
		entry.ActorName,
		targetDescription,
		targetName,
		tostring(success),
		reason
	)
	if success then
		Logger.Info("Moderation", message)
	else
		Logger.Warn("Moderation", message)
	end
end

function AdminService.Init()
	if initialized then
		return
	end
	initialized = true

	if game.CreatorType ~= Enum.CreatorType.Group then
		groupLookupComplete = true
		return
	end

	task.spawn(function()
		local ok, groupInfo = pcall(function()
			return GroupService:GetGroupInfoAsync(game.CreatorId)
		end)
		if not ok then
			Logger.Warn("Admin", "Não foi possível consultar o proprietário do grupo: " .. tostring(groupInfo))
			groupLookupComplete = true
			return
		end

		local owner = type(groupInfo) == "table" and groupInfo.Owner
		if type(owner) == "table" and type(owner.Id) == "number" then
			groupOwnerUserId = owner.Id
		else
			Logger.Warn("Admin", "A resposta do Roblox não contém o proprietário do grupo.")
		end
		groupLookupComplete = true
	end)
end

function AdminService.IsCreator(player)
	if not player or not player:IsA("Player") then
		return false
	end

	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end

	return groupOwnerUserId ~= nil and player.UserId == groupOwnerUserId
end

function AdminService.GetStatus(player)
	if not player or not player:IsA("Player") then
		return false, "Jogador inválido"
	end
	for _, userId in ipairs(Config.AdminUserIds) do
		if userId == player.UserId then
			return true
		end
	end

	if game.CreatorType == Enum.CreatorType.Group then
		local deadline = os.clock() + 10
		while not groupLookupComplete and os.clock() < deadline do
			task.wait(0.1)
		end
		if not groupLookupComplete or not groupOwnerUserId then
			return false, "Não foi possível verificar o proprietário do grupo"
		end
	end

	return Config.AdminAllowExperienceCreator and AdminService.IsCreator(player)
end

function AdminService.KickPlayer(admin, targetUserId)
	if typeof(admin) ~= "Instance" or not admin:IsA("Player") then
		return false, "Jogador administrativo inválido"
	end
	if not RateLimitService.Allow(admin, "admin.action", Config.RateLimits.AdminActionCooldown) then
		return false, "Aguarde antes de executar outra ação administrativa"
	end

	local normalizedTargetUserId = normalizeUserId(targetUserId)
	local isAdmin, statusError = AdminService.GetStatus(admin)
	if not isAdmin then
		recordModerationAction(
			admin,
			"Kick",
			nil,
			normalizedTargetUserId,
			false,
			statusError or "Acesso administrativo negado"
		)
		return false, "Apenas o criador verificado pode usar este controle"
	end
	if not normalizedTargetUserId then
		recordModerationAction(admin, "Kick", nil, nil, false, "Identificador do jogador inválido")
		return false, "Identificador do jogador inválido"
	end

	local target = Players:GetPlayerByUserId(normalizedTargetUserId)
	if not target then
		recordModerationAction(
			admin,
			"Kick",
			nil,
			normalizedTargetUserId,
			false,
			"O jogador não está mais nesta sessão"
		)
		return false, "O jogador não está mais nesta sessão"
	end
	if target == admin then
		recordModerationAction(
			admin,
			"Kick",
			target,
			normalizedTargetUserId,
			false,
			"Tentativa de expulsar a própria conta"
		)
		return false, "Não é possível expulsar a própria conta por este painel"
	end
	if AdminService.IsCreator(target) then
		recordModerationAction(admin, "Kick", target, normalizedTargetUserId, false, "Proteção do criador")
		return false, "O criador do jogo não pode ser expulso por este painel"
	end

	recordModerationAction(admin, "Kick", target, normalizedTargetUserId, true, "Removido da sessão atual")
	target:Kick("Você foi removido desta sessão pelo criador do jogo.")
	return true, "Jogador removido desta sessão"
end

function AdminService.RecordInvalidAction(admin)
	if
		typeof(admin) ~= "Instance"
		or not admin:IsA("Player")
		or not RateLimitService.Allow(admin, "admin.action", Config.RateLimits.AdminActionCooldown)
	then
		return
	end

	recordModerationAction(admin, "InvalidAction", nil, nil, false, "Ação administrativa inválida")
end

function AdminService.GetRecentModerationLogs(player)
	if not RateLimitService.Allow(player, "admin.logs", Config.RateLimits.EventCatalogCooldown) then
		return nil, "Aguarde antes de consultar os logs de moderação"
	end
	local isAdmin, reason = AdminService.GetStatus(player)
	if not isAdmin then
		return nil, reason or "Acesso administrativo restrito"
	end

	local result = {}
	local firstIndex = math.max(1, #moderationLogs - 19)
	for index = #moderationLogs, firstIndex, -1 do
		local entry = moderationLogs[index]
		table.insert(result, {
			Timestamp = entry.Timestamp,
			ActorUserId = entry.ActorUserId,
			ActorName = entry.ActorName,
			Action = entry.Action,
			TargetUserId = entry.TargetUserId,
			TargetName = entry.TargetName,
			Success = entry.Success,
			Reason = entry.Reason,
		})
	end

	return result
end

return AdminService
