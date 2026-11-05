local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("Config"))

local EconomyService = require(script.Parent.EconomyService)
local AchievementService = require(script.Parent.AchievementService)
local RateLimitService = require(script.Parent.RateLimitService)

local EventService = {}

local ATTENDANCE_DURATION = 60
local MAX_MOVEMENT_SPEED = 60
local MOVEMENT_TOLERANCE = 8
local EVENT_RADIUS = 24
local EVENT_POINTS_PER_ATTENDANCE = 10
local SAMPLE_INTERVAL = 1

local events = {
	{
		Id = "club_festival",
		Name = "Noite no Grand Society Club",
		Description = "Encontre outros jogadores na praça do clube.",
		Location = "Grand Society Club",
		PointName = "club_festival",
		StartHour = 18,
		EndHour = 21,
	},
	{
		Id = "garden_photo_walk",
		Name = "Passeio fotográfico no Garden Park",
		Description = "Explore o jardim e participe do passeio fotográfico.",
		Location = "Garden Park",
		PointName = "garden_photo_walk",
		StartHour = 8,
		EndHour = 11,
	},
	{
		Id = "fashion_show",
		Name = "Desfile da Fashion Avenue",
		Description = "Participe do encontro de moda na Fashion Avenue.",
		Location = "Fashion Avenue",
		PointName = "fashion_show",
		StartHour = 12,
		EndHour = 15,
	},
	{
		Id = "marina_exhibition",
		Name = "Encontro na Royal Marina",
		Description = "Visite o ponto de encontro da marina.",
		Location = "Royal Marina",
		PointName = "marina_exhibition",
		StartHour = 10,
		EndHour = 13,
	},
}

local eventsById = {}
for _, event in ipairs(events) do
	eventsById[event.Id] = event
end

local activeAttendance = {}
local resultRemote
local inviteReceivedRemote
local inviteResultRemote
local pendingInvites = {}

local function getEventPoint(event)
	local world = workspace:FindFirstChild("HighSocietyWorld")
	local points = world and world:FindFirstChild("EventPoints")
	local point = points and points:FindFirstChild(event.PointName)
	if point and point:IsA("BasePart") then
		return point
	end
	return nil
end

local function getLivingCharacter(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character, root
end

local function isEventOpen(event)
	local hour = Lighting.ClockTime
	return hour >= event.StartHour and hour < event.EndHour
end

local function isNearEvent(player, event)
	local point = getEventPoint(event)
	local _, root = getLivingCharacter(player)
	local prompt = point and point:FindFirstChild("EventPrompt")
	if not point or not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled or not root then
		return false
	end

	return (root.Position - point.Position).Magnitude <= prompt.MaxActivationDistance + 3
end

local function sendResult(player, success, message, eventId, pointsEarned)
	if resultRemote and resultRemote.Parent and player and player.Parent == Players then
		resultRemote:FireClient(player, {
			Success = success,
			Message = message,
			EventId = eventId,
			PointsEarned = pointsEarned or 0,
		})
	end
end

function EventService.Init(remote, eventInviteReceived, eventInviteResult)
	resultRemote = remote
	inviteReceivedRemote = eventInviteReceived
	inviteResultRemote = eventInviteResult
end

function EventService.GetEvents(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	local current = activeAttendance[player.UserId]
	local result = {}
	local today = math.floor(os.time() / 86400)
	local worldHour = Lighting.ClockTime

	for _, event in ipairs(events) do
		local claimDay = profile.eventClaims and profile.eventClaims[event.Id]
		local active = current and current.EventId == event.Id
		local participants = 0
		for _, attendance in pairs(activeAttendance) do
			if attendance.EventId == event.Id then
				participants += 1
			end
		end
		local open = isEventOpen(event)
		local opensInHours = (event.StartHour - worldHour) % 24
		table.insert(result, {
			Id = event.Id,
			Name = event.Name,
			Description = event.Description,
			Location = event.Location,
			Schedule = string.format("%02d:00-%02d:00 no relógio do jogo", event.StartHour, event.EndHour),
			Open = open,
			OpensInHours = open and 0 or math.floor(opensInHours),
			Participants = participants,
			PointsReward = EVENT_POINTS_PER_ATTENDANCE,
			AttendanceSeconds = ATTENDANCE_DURATION,
			Active = active == true,
			Invalid = active and current.Invalid or false,
			Progress = active and math.clamp(current.AttendedSeconds / ATTENDANCE_DURATION, 0, 1) or 0,
			ClaimedToday = type(claimDay) == "number" and claimDay == today,
		})
	end

	return {
		Events = result,
		EventPoints = profile.eventPoints or 0,
	}
end

function EventService.IsEventOpen(eventId)
	local event = typeof(eventId) == "string" and eventsById[eventId] or nil
	return event ~= nil and isEventOpen(event)
end

function EventService.IsAtEvent(player, eventId)
	local event = typeof(eventId) == "string" and eventsById[eventId] or nil
	return event ~= nil and isEventOpen(event) and isNearEvent(player, event)
end

function EventService.HandleRequest(player, action, eventId)
	if typeof(action) ~= "string" or typeof(eventId) ~= "string" then
		return false, "Solicitação de evento inválida"
	end

	if not RateLimitService.Allow(player, "event.action", Config.RateLimits.RequestCooldown) then
		return false, "Aguarde antes de fazer outra solicitação"
	end
	local now = os.clock()

	if not EconomyService.GetProfile(player) then
		return false, "Perfil do jogador ainda não foi carregado"
	end

	local event = eventsById[eventId]
	if not event then
		return false, "Evento não encontrado"
	end

	if action == "Leave" then
		local active = activeAttendance[player.UserId]
		if not active or active.EventId ~= event.Id then
			return false, "Você não está participando deste evento"
		end
		activeAttendance[player.UserId] = nil
		return true, "Você saiu do evento"
	end

	if action ~= "Join" then
		return false, "Ação de evento inválida"
	end
	if not isEventOpen(event) then
		return false,
			string.format(
				"Este evento acontece das %02d:00 às %02d:00 no relógio do jogo",
				event.StartHour,
				event.EndHour
			)
	end

	if activeAttendance[player.UserId] then
		return false, "Saia do evento atual antes de participar de outro"
	end
	if not isNearEvent(player, event) then
		return false, "Aproxime-se do ponto do evento para participar"
	end

	local profile = EconomyService.GetProfile(player)
	local today = math.floor(os.time() / 86400)
	if profile.eventClaims and profile.eventClaims[event.Id] == today then
		return false, "Você já recebeu os pontos deste evento hoje"
	end

	local character, root = getLivingCharacter(player)
	if not character or not root then
		return false, "Personagem não encontrado"
	end

	activeAttendance[player.UserId] = {
		EventId = event.Id,
		StartedAt = now,
		LastSampleAt = now,
		LastPosition = root.Position,
		Character = character,
		AttendedSeconds = 0,
		Invalid = false,
	}
	return true, string.format("Participação iniciada. Permaneça no local por %d segundos.", ATTENDANCE_DURATION)
end

function EventService.InvitePlayer(sender, eventId, guestUserId)
	if typeof(eventId) ~= "string" or typeof(guestUserId) ~= "number" or guestUserId <= 0 or guestUserId % 1 ~= 0 then
		return false, "Convite de evento inválido"
	end
	if guestUserId == sender.UserId then
		return false, "Você não pode convidar a si mesmo"
	end

	if not RateLimitService.Allow(sender, "event.invite.internal-send", Config.RateLimits.EventInviteCooldown) then
		return false, "Aguarde antes de enviar outro convite de evento"
	end
	local now = os.clock()

	local event = eventsById[eventId]
	if not event then
		return false, "Evento não encontrado"
	end
	if not EconomyService.GetProfile(sender) then
		return false, "Perfil do jogador ainda não foi carregado"
	end

	local guest = Players:GetPlayerByUserId(guestUserId)
	if not guest or guest.Parent ~= Players then
		return false, "Este jogador não está mais nesta sessão"
	end
	if pendingInvites[guest.UserId] then
		return false, "Este jogador já tem um convite de evento pendente"
	end
	if not inviteReceivedRemote or not inviteReceivedRemote.Parent then
		return false, "Sistema de convites de evento indisponível"
	end

	local invite = {
		SenderUserId = sender.UserId,
		EventId = event.Id,
		ExpiresAt = now + 60,
	}
	pendingInvites[guest.UserId] = invite
	task.delay(60, function()
		if pendingInvites[guest.UserId] ~= invite then
			return
		end
		pendingInvites[guest.UserId] = nil
		if inviteResultRemote and inviteResultRemote.Parent then
			if guest.Parent == Players then
				inviteResultRemote:FireClient(guest, {
					Success = false,
					Message = "O convite para o evento expirou.",
				})
			end
			local currentSender = Players:GetPlayerByUserId(invite.SenderUserId)
			if currentSender then
				inviteResultRemote:FireClient(currentSender, {
					Success = false,
					Message = "O convite para " .. event.Name .. " expirou.",
				})
			end
		end
	end)

	inviteReceivedRemote:FireClient(guest, {
		SenderName = sender.DisplayName,
		EventId = event.Id,
		EventName = event.Name,
		Location = event.Location,
		ExpiresIn = 60,
	})
	return true, "Convite para " .. event.Name .. " enviado. Expira em 60 segundos."
end

function EventService.RespondToInvite(guest, response)
	if typeof(response) ~= "string" or (response ~= "Accept" and response ~= "Decline") then
		return false, "Resposta ao convite de evento inválida"
	end

	if
		not RateLimitService.Allow(
			guest,
			"event.invite.internal-respond",
			Config.RateLimits.EventInviteResponseCooldown
		)
	then
		return false, "Aguarde antes de responder a outro convite"
	end
	local now = os.clock()

	local invite = pendingInvites[guest.UserId]
	if not invite then
		return false, "Este convite de evento não existe mais"
	end
	pendingInvites[guest.UserId] = nil

	if now > invite.ExpiresAt then
		return false, "O convite de evento expirou"
	end

	local sender = Players:GetPlayerByUserId(invite.SenderUserId)
	local event = eventsById[invite.EventId]
	if not event or not sender then
		return false, "Quem enviou o convite não está mais nesta sessão"
	end

	if response == "Decline" then
		if inviteResultRemote and inviteResultRemote.Parent then
			inviteResultRemote:FireClient(sender, {
				Success = true,
				Message = guest.DisplayName .. " recusou o convite para " .. event.Name .. ".",
				EventId = event.Id,
			})
		end
		return true, "Convite para " .. event.Name .. " recusado."
	end

	if inviteResultRemote and inviteResultRemote.Parent then
		inviteResultRemote:FireClient(sender, {
			Success = true,
			Message = guest.DisplayName .. " aceitou o convite para " .. event.Name .. ".",
			EventId = event.Id,
		})
	end
	return true,
		{
			Message = "Convite aceito. O marcador de " .. event.Name .. " foi ativado.",
			EventId = event.Id,
			Accepted = true,
		}
end

local function updateAttendance(userId, attendance, now)
	local player = Players:GetPlayerByUserId(userId)
	local event = eventsById[attendance.EventId]
	local point = event and getEventPoint(event)
	local character, root
	if player then
		character, root = getLivingCharacter(player)
	end
	if not player or not event or not point or character ~= attendance.Character or not root then
		attendance.Invalid = true
		return
	end
	if not isEventOpen(event) then
		attendance.Invalid = true
	end

	local elapsed = math.max(now - attendance.LastSampleAt, 0)
	local moved = (root.Position - attendance.LastPosition).Magnitude
	if moved > MAX_MOVEMENT_SPEED * elapsed + MOVEMENT_TOLERANCE then
		attendance.Invalid = true
	end
	if (root.Position - point.Position).Magnitude > EVENT_RADIUS then
		attendance.Invalid = true
	end

	if not attendance.Invalid then
		attendance.AttendedSeconds += elapsed
	end
	attendance.LastPosition = root.Position
	attendance.LastSampleAt = now

	if attendance.Invalid then
		activeAttendance[userId] = nil
		sendResult(
			player,
			false,
			"Participação interrompida. Volte ao ponto do evento para tentar novamente.",
			event.Id
		)
		return
	end

	if attendance.AttendedSeconds < ATTENDANCE_DURATION then
		return
	end

	local profile = EconomyService.GetProfile(player)
	if not profile then
		activeAttendance[userId] = nil
		sendResult(player, false, "Perfil indisponível; os pontos não foram registrados.", event.Id)
		return
	end

	local today = math.floor(os.time() / 86400)
	profile.eventClaims = profile.eventClaims or {}
	if profile.eventClaims[event.Id] ~= today then
		profile.eventClaims[event.Id] = today
		profile.eventPoints = math.min((profile.eventPoints or 0) + EVENT_POINTS_PER_ATTENDANCE, 2_000_000_000)
		AchievementService.RecordEventAttendance(player)
		sendResult(
			player,
			true,
			string.format("Evento concluído: +%d pontos de evento.", EVENT_POINTS_PER_ATTENDANCE),
			event.Id,
			EVENT_POINTS_PER_ATTENDANCE
		)
	else
		sendResult(player, true, "Você concluiu este evento; os pontos diários já foram recebidos.", event.Id)
	end
	activeAttendance[userId] = nil
end

task.spawn(function()
	while true do
		task.wait(SAMPLE_INTERVAL)
		local now = os.clock()
		for userId, attendance in pairs(activeAttendance) do
			updateAttendance(userId, attendance, now)
		end
	end
end)

function EventService.CleanupPlayer(player)
	activeAttendance[player.UserId] = nil

	local ownInvite = pendingInvites[player.UserId]
	if ownInvite then
		pendingInvites[player.UserId] = nil
		local sender = Players:GetPlayerByUserId(ownInvite.SenderUserId)
		if sender and inviteResultRemote and inviteResultRemote.Parent then
			inviteResultRemote:FireClient(sender, {
				Success = false,
				Message = player.DisplayName .. " saiu antes de responder ao convite.",
			})
		end
	end
	for guestUserId, invite in pairs(pendingInvites) do
		if invite.SenderUserId == player.UserId then
			pendingInvites[guestUserId] = nil
			local guest = Players:GetPlayerByUserId(guestUserId)
			if guest and inviteResultRemote and inviteResultRemote.Parent then
				inviteResultRemote:FireClient(guest, {
					Success = false,
					Message = "O convite foi cancelado porque quem enviou saiu da sessão.",
				})
			end
		end
	end
end

return EventService
