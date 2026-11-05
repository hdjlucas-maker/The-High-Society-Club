local Players = game:GetService("Players")

local EventService = require(script.Parent.EventService)

local FashionContestService = {}

local EVENT_ID = "fashion_show"
local currentDay
local entries = {}
local votesByUserId = {}

local function ensureCurrentDay()
	local day = math.floor(os.time() / 86400)
	if day ~= currentDay then
		currentDay = day
		entries = {}
		votesByUserId = {}
	end
end

local function getVoteCounts()
	local counts = {}
	for _, entry in pairs(entries) do
		counts[entry.UserId] = 0
	end
	for _, targetUserId in pairs(votesByUserId) do
		if counts[targetUserId] ~= nil then
			counts[targetUserId] += 1
		end
	end
	return counts
end

function FashionContestService.GetStatus(player)
	ensureCurrentDay()
	if not player or player.Parent ~= Players then
		return nil, "Jogador inválido"
	end

	local isOpen = EventService.IsEventOpen(EVENT_ID)
	local atEvent = EventService.IsAtEvent(player, EVENT_ID)
	local counts = getVoteCounts()
	local contestants = {}
	local highestVotes = 0
	for _, entry in pairs(entries) do
		local votes = counts[entry.UserId] or 0
		highestVotes = math.max(highestVotes, votes)
		local contestantPlayer = Players:GetPlayerByUserId(entry.UserId)
		table.insert(contestants, {
			UserId = entry.UserId,
			DisplayName = entry.DisplayName,
			Username = entry.Username,
			Votes = votes,
			AtEvent = isOpen and contestantPlayer ~= nil and EventService.IsAtEvent(contestantPlayer, EVENT_ID),
		})
	end
	table.sort(contestants, function(left, right)
		if left.Votes == right.Votes then
			local leftName = string.lower(left.DisplayName)
			local rightName = string.lower(right.DisplayName)
			if leftName == rightName then
				return left.UserId < right.UserId
			end
			return leftName < rightName
		end
		return left.Votes > right.Votes
	end)

	local winners = {}
	if not isOpen and highestVotes > 0 then
		for _, contestant in ipairs(contestants) do
			if contestant.Votes == highestVotes then
				table.insert(winners, contestant.UserId)
			else
				break
			end
		end
	end

	return {
		EventOpen = isOpen,
		AtEvent = atEvent,
		HasSubmitted = entries[player.UserId] ~= nil,
		VotedFor = votesByUserId[player.UserId],
		Contestants = contestants,
		WinnerUserIds = winners,
	}
end

function FashionContestService.Submit(player)
	ensureCurrentDay()
	if not player or player.Parent ~= Players then
		return false, "Jogador inválido"
	end
	if not EventService.IsEventOpen(EVENT_ID) then
		return false, "O desfile não está aberto agora"
	end
	if not EventService.IsAtEvent(player, EVENT_ID) then
		return false, "Aproxime-se do ponto do desfile na Fashion Avenue para se inscrever"
	end
	if entries[player.UserId] then
		return false, "Você já está inscrito no desfile de hoje"
	end

	entries[player.UserId] = {
		UserId = player.UserId,
		DisplayName = player.DisplayName,
		Username = player.Name,
	}
	return true, "Inscrição confirmada para o desfile de hoje"
end

function FashionContestService.Vote(player, targetUserId)
	ensureCurrentDay()
	if not player or player.Parent ~= Players then
		return false, "Jogador inválido"
	end
	if typeof(targetUserId) ~= "number" or targetUserId <= 0 or targetUserId % 1 ~= 0 then
		return false, "Participante inválido"
	end
	if not EventService.IsEventOpen(EVENT_ID) or not EventService.IsAtEvent(player, EVENT_ID) then
		return false, "Aproxime-se do ponto do desfile na Fashion Avenue para votar"
	end
	if votesByUserId[player.UserId] then
		return false, "Você já votou neste desfile"
	end
	if targetUserId == player.UserId then
		return false, "Você não pode votar em si mesmo"
	end
	if not entries[targetUserId] then
		return false, "Esse jogador não está inscrito no desfile"
	end
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer or not EventService.IsAtEvent(targetPlayer, EVENT_ID) then
		return false, "O participante precisa estar no ponto do desfile para receber votos"
	end

	votesByUserId[player.UserId] = targetUserId
	return true, "Voto registrado"
end

return FashionContestService
