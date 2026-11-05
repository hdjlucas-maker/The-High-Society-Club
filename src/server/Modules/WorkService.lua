local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("Config"))
local EconomyService = require(script.Parent.EconomyService)
local AchievementService = require(script.Parent.AchievementService)
local VehicleService = require(script.Parent.VehicleService)
local RateLimitService = require(script.Parent.RateLimitService)
local CreationService = require(script.Parent.CreationService)

local WorkService = {}

local WORK_COOLDOWN = 8
local WORK_CANCEL_COOLDOWN = 4
local MAX_MOVEMENT_SPEED = 60
local MOVEMENT_TOLERANCE = 8
local MINIMUM_ROUTE_FRACTION = 0.65
local MOVEMENT_SAMPLE_INTERVAL = 0.5
local jobs = {
	{
		Id = "city_guide",
		Name = "Guia turístico",
		Description = "Faça um percurso turístico entre o boulevard e a ilha.",
		Route = "Boulevard → Paradise Island",
		Reward = 75,
		MinimumDuration = 25,
		StartPoint = "TourGuideStart",
		FinishPoint = "TourGuideFinish",
	},
	{
		Id = "chauffeur",
		Name = "Motorista particular",
		Description = "Complete um trajeto entre o hotel e a galeria automotiva.",
		Route = "Luxury Hotel → Automotive Gallery",
		Reward = 90,
		MinimumDuration = 20,
		RequiresVehicle = true,
		StartPoint = "ChauffeurStart",
		FinishPoint = "ChauffeurFinish",
	},
	{
		Id = "photographer",
		Name = "Fotógrafo virtual",
		Description = "Faça um percurso pelos jardins até o clube.",
		Route = "Garden Park → Grand Society Club",
		Reward = 60,
		MinimumDuration = 15,
		StartPoint = "PhotographerStart",
		FinishPoint = "PhotographerFinish",
	},
	{
		Id = "dj",
		Name = "DJ",
		Description = "Prepare a apresentação na marina e leve a energia até o clube.",
		Route = "Royal Marina → Grand Society Club",
		Reward = 100,
		MinimumDuration = 25,
		StartPoint = "DJStart",
		FinishPoint = "DJFinish",
	},
	{
		Id = "event_animator",
		Name = "Animador de eventos",
		Description = "Conduza uma atividade segura entre o parque e a avenida da moda.",
		Route = "Garden Park → Fashion Avenue",
		Reward = 85,
		MinimumDuration = 30,
		StartPoint = "EventAnimatorStart",
		FinishPoint = "EventAnimatorFinish",
	},
	{
		Id = "entrepreneur",
		Name = "Empresário virtual",
		Description = "Leve uma proposta comercial da galeria ao Luxury Hotel.",
		Route = "High Society Gallery → Luxury Hotel",
		Reward = 95,
		MinimumDuration = 35,
		StartPoint = "EntrepreneurStart",
		FinishPoint = "EntrepreneurFinish",
	},
	{
		Id = "fashion_designer",
		Name = "Designer de moda",
		Description = "Apresente sua coleção da Fashion Avenue na Automotive Gallery.",
		Route = "Fashion Avenue → Automotive Gallery",
		Reward = 80,
		MinimumDuration = 25,
		StartPoint = "FashionDesignerStart",
		FinishPoint = "FashionDesignerFinish",
	},
	{
		Id = "event_organizer",
		Name = "Organizador de eventos",
		Description = "Prepare o evento no clube e entregue o material na Fashion Avenue.",
		Route = "Grand Society Club → Fashion Avenue",
		Reward = 90,
		MinimumDuration = 30,
		StartPoint = "EventOrganizerStart",
		FinishPoint = "EventOrganizerFinish",
	},
	{
		Id = "establishment_owner",
		Name = "Proprietário de estabelecimento",
		Description = "Planeje a operação do hotel e audite o atendimento do clube.",
		Route = "Luxury Hotel → Grand Society Club",
		Reward = 95,
		MinimumDuration = 30,
		StartPoint = "EstablishmentOwnerStart",
		FinishPoint = "EstablishmentOwnerFinish",
		Activities = {
			{
				Label = "Definir a prioridade operacional",
				Choices = {
					{
						Point = "EstablishmentOwnerOperationsService",
						Name = "Priorizar atendimento",
						Outcome = "atendimento premium",
					},
					{
						Point = "EstablishmentOwnerOperationsEvents",
						Name = "Priorizar eventos",
						Outcome = "agenda de eventos",
					},
				},
			},
			{
				Label = "Avaliar o padrão de atendimento",
				Choices = {
					{
						Point = "EstablishmentOwnerAuditApprove",
						Name = "Aprovar padrão",
						Outcome = "padrão aprovado",
					},
					{
						Point = "EstablishmentOwnerAuditTraining",
						Name = "Recomendar treinamento",
						Outcome = "treinamento recomendado",
					},
				},
			},
		},
	},
	{
		Id = "world_creator",
		Name = "Criador de mundos",
		Description = "Crie um conceito de cenário e apresente a maquete na galeria.",
		Route = "Garden Park → High Society Gallery",
		Reward = 100,
		MinimumDuration = 35,
		StartPoint = "WorldCreatorStart",
		FinishPoint = "WorldCreatorFinish",
		Activities = {
			{
				Label = "Escolher o tema do cenário",
				Choices = {
					{ Point = "WorldCreatorThemeGarden", Name = "Tema de jardim", Outcome = "tema de jardim" },
					{ Point = "WorldCreatorThemeCoastal", Name = "Tema costeiro", Outcome = "tema costeiro" },
					{ Point = "WorldCreatorThemeUrban", Name = "Tema urbano", Outcome = "tema urbano" },
				},
			},
			{
				Label = "Montar a composição da maquete",
				Choices = {
					{
						Point = "WorldCreatorLayoutPavilion",
						Name = "Composição com pavilhão",
						Outcome = "layout de pavilhão",
					},
					{
						Point = "WorldCreatorLayoutPlaza",
						Name = "Composição com praça",
						Outcome = "layout de praça",
					},
					{
						Point = "WorldCreatorLayoutPromenade",
						Name = "Composição com passeio",
						Outcome = "layout de passeio",
					},
				},
			},
		},
	},
}

local jobsById = {}
for _, job in ipairs(jobs) do
	jobsById[job.Id] = job
end

local activeJobs = {}
local cooldownUntil = {}
local djBoothAccessUntil = {}

local function findWorkPoint(pointName)
	local folder = workspace:FindFirstChild("HighSocietyWorld")
	local workPoints = folder and folder:FindFirstChild("WorkPoints")
	local point = workPoints and workPoints:FindFirstChild(pointName)

	if point and point:IsA("BasePart") then
		return point
	end

	return nil
end

local function getPlayerRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return root
end

local function isNearPoint(player, pointName)
	local point = findWorkPoint(pointName)
	local root = getPlayerRoot(player)
	local prompt = point and point:FindFirstChild("WorkPrompt")

	if not point or not point:IsA("BasePart") or not prompt or not prompt:IsA("ProximityPrompt") or not root then
		return false
	end

	return (root.Position - point.Position).Magnitude <= prompt.MaxActivationDistance + 3
end

local function sampleMovement(player, active, now)
	if not player or player.Character ~= active.Character then
		active.MovementInvalid = true
		return
	end

	local root = getPlayerRoot(player)
	if not root then
		active.MovementInvalid = true
		return
	end

	local elapsed = math.max(now - active.LastSampleAt, 0)
	local moved = (root.Position - active.LastPosition).Magnitude
	if moved > MAX_MOVEMENT_SPEED * elapsed + MOVEMENT_TOLERANCE then
		active.MovementInvalid = true
	else
		active.TravelledDistance += moved
		if active.RequiresVehicle and VehicleService.IsPlayerDrivingOwnedVehicle(player) then
			active.DrivenDistance += moved
		end
	end

	active.LastPosition = root.Position
	active.LastSampleAt = now
end

local progressionRanks = {
	{ Completions = 0, Name = "Aprendiz" },
	{ Completions = 3, Name = "Profissional" },
	{ Completions = 10, Name = "Especialista" },
	{ Completions = 25, Name = "Elite" },
	{ Completions = 50, Name = "Lenda" },
}

local function getProfessionRank(completions)
	local rankIndex = 1
	for index, rank in ipairs(progressionRanks) do
		if completions >= rank.Completions then
			rankIndex = index
		else
			break
		end
	end

	return progressionRanks[rankIndex], progressionRanks[rankIndex + 1], rankIndex
end

function WorkService.GetJobs(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	profile.professionCompletions = profile.professionCompletions or {}
	local result = {}

	for _, job in ipairs(jobs) do
		local completions = profile.professionCompletions[job.Id] or 0
		local rank, nextRank, rankIndex = getProfessionRank(completions)
		local activities = {}
		for _, activity in ipairs(job.Activities or {}) do
			table.insert(activities, activity.Label)
		end

		table.insert(result, {
			Id = job.Id,
			Name = job.Name,
			Description = job.Description,
			Route = job.Route,
			Reward = job.Reward,
			EffectiveReward = math.floor(job.Reward * (1 + (rankIndex - 1) * 0.05)),
			MinimumDuration = job.MinimumDuration,
			RequiresVehicle = job.RequiresVehicle == true,
			Activities = activities,
			Completions = completions,
			Rank = rank.Name,
			NextRankAt = nextRank and nextRank.Completions or nil,
		})
	end

	return result
end

function WorkService.GetActiveJob(player)
	local active = activeJobs[player.UserId]
	if not active then
		return nil
	end

	local job = jobsById[active.JobId]
	if not job then
		activeJobs[player.UserId] = nil
		return nil
	end

	local elapsed = os.clock() - active.StartedAt
	local activities = job.Activities or {}
	local activityIndex = active.ActivityIndex or 1
	local objective = activities[activityIndex]
	local objectiveChoices = {}
	for _, choice in ipairs(objective and objective.Choices or {}) do
		table.insert(objectiveChoices, choice.Name)
	end
	return {
		JobId = job.Id,
		JobName = job.Name,
		FinishPoint = job.FinishPoint,
		ObjectivePoint = objective and objective.Choices[1].Point or nil,
		ObjectiveLabel = objective and objective.Label or nil,
		ObjectiveChoices = objectiveChoices,
		ActivityIndex = activityIndex,
		ActivityCount = #activities,
		ActivityComplete = objective == nil,
		Elapsed = math.floor(elapsed),
		SecondsRemaining = math.max(0, math.ceil(job.MinimumDuration - elapsed)),
		MovementInvalid = active.MovementInvalid == true,
		TravelProgress = active.RequiredDistance > 0
				and math.clamp(active.TravelledDistance / active.RequiredDistance, 0, 1)
			or 0,
		VehicleProgress = active.RequiresVehicle
				and active.RequiredDistance > 0
				and math.clamp(active.DrivenDistance / active.RequiredDistance, 0, 1)
			or nil,
	}
end

function WorkService.CanOperateDJBooth(player)
	if not player then
		return false
	end
	local job = jobsById.dj
	if not job then
		return false
	end
	local nearFinish = isNearPoint(player, job.FinishPoint)
	if not nearFinish then
		return false
	end

	local active = activeJobs[player.UserId]
	if active then
		if active.JobId ~= job.Id or active.MovementInvalid or player.Character ~= active.Character then
			return false
		end
		if os.clock() - active.StartedAt < job.MinimumDuration then
			return false
		end
		return active.TravelledDistance >= active.RequiredDistance
	end
	return os.clock() < (djBoothAccessUntil[player.UserId] or 0)
end

function WorkService.HandleRequest(player, action, jobId, pointName)
	if typeof(action) ~= "string" or typeof(jobId) ~= "string" then
		return false, "Solicitação de trabalho inválida"
	end

	if not RateLimitService.Allow(player, "work.request", Config.RateLimits.WorkRequestCooldown) then
		return false, "Aguarde antes de fazer outra solicitação"
	end
	local now = os.clock()

	if not EconomyService.GetProfile(player) then
		return false, "Perfil do jogador ainda não foi carregado"
	end

	local job = jobsById[jobId]
	if not job then
		return false, "Profissão não encontrada"
	end

	if action == "Start" then
		if activeJobs[player.UserId] then
			return false, "Conclua ou abandone seu trabalho atual primeiro"
		end
		if now < (cooldownUntil[player.UserId] or 0) then
			return false, "Aguarde antes de iniciar outro trabalho"
		end
		if not isNearPoint(player, job.StartPoint) then
			return false, "Aproxime-se do ponto de início desta profissão"
		end
		if job.RequiresVehicle and not VehicleService.IsPlayerDrivingOwnedVehicle(player) then
			return false, "Retire um veículo seu e sente-se ao volante para iniciar esta rota"
		end

		local startPoint = findWorkPoint(job.StartPoint)
		local finishPoint = findWorkPoint(job.FinishPoint)
		local root = getPlayerRoot(player)
		if not startPoint or not finishPoint or not root then
			return false, "Os pontos desta rota não estão disponíveis"
		end

		local requiredDistance = (finishPoint.Position - startPoint.Position).Magnitude * MINIMUM_ROUTE_FRACTION
		activeJobs[player.UserId] = {
			JobId = job.Id,
			CreationSubmissionId = job.Id == "world_creator" and HttpService:GenerateGUID(false) or nil,
			StartedAt = now,
			LastPosition = root.Position,
			LastSampleAt = now,
			Character = player.Character,
			TravelledDistance = 0,
			DrivenDistance = 0,
			RequiredDistance = requiredDistance,
			RequiresVehicle = job.RequiresVehicle == true,
			MovementInvalid = false,
		}

		return true,
			{
				Message = "Trabalho iniciado. Siga até o ponto de entrega.",
				ActiveJob = WorkService.GetActiveJob(player),
			}
	end

	if action == "Cancel" then
		local active = activeJobs[player.UserId]
		if not active or active.JobId ~= job.Id then
			return false, "Você não está realizando este trabalho"
		end

		activeJobs[player.UserId] = nil
		cooldownUntil[player.UserId] = now + WORK_CANCEL_COOLDOWN
		return true, {
			Message = "Trabalho abandonado. Nenhuma recompensa foi concedida.",
		}
	end

	if action == "Interact" then
		if typeof(pointName) ~= "string" then
			return false, "Ponto de atividade inválido"
		end
		local active = activeJobs[player.UserId]
		if not active or active.JobId ~= job.Id then
			return false, "Você não está realizando este trabalho"
		end
		sampleMovement(player, active, now)
		if active.MovementInvalid then
			return false, "O percurso foi interrompido. Abandone e comece novamente"
		end

		local activity = (job.Activities or {})[active.ActivityIndex or 1]
		if not activity then
			return false, "Todas as atividades desta profissão já foram concluídas"
		end
		local selectedChoice
		for _, choice in ipairs(activity.Choices) do
			if choice.Point == pointName then
				selectedChoice = choice
				break
			end
		end
		if not selectedChoice then
			return false, "Escolha uma opção da etapa atual indicada pelo marcador"
		end
		if not isNearPoint(player, selectedChoice.Point) then
			return false, "Aproxime-se do ponto da atividade atual"
		end

		active.ActivityChoices = active.ActivityChoices or {}
		active.ActivityChoices[active.ActivityIndex or 1] = selectedChoice.Outcome
		active.ActivityIndex = (active.ActivityIndex or 1) + 1
		local nextActivity = (job.Activities or {})[active.ActivityIndex]
		return true, {
			Message = nextActivity
					and ("Escolha registrada: " .. selectedChoice.Name .. ". Próxima: " .. nextActivity.Label)
				or "Atividades concluídas. Siga até o destino para finalizar.",
			ActiveJob = WorkService.GetActiveJob(player),
		}
	end

	if action == "Complete" then
		local active = activeJobs[player.UserId]
		if not active or active.JobId ~= job.Id then
			return false, "Você não está realizando este trabalho"
		end
		sampleMovement(player, active, now)
		if active.MovementInvalid then
			return false, "O percurso foi interrompido. Abandone e comece novamente"
		end

		if now - active.StartedAt < job.MinimumDuration then
			return false, "Conclua o trajeto antes de solicitar a recompensa"
		end
		if active.TravelledDistance < active.RequiredDistance then
			return false, "Percorra a rota antes de solicitar a recompensa"
		end
		if active.RequiresVehicle and active.DrivenDistance < active.RequiredDistance then
			return false, "Conclua o trajeto dirigindo seu veículo até o destino"
		end
		if (active.ActivityIndex or 1) <= #(job.Activities or {}) then
			return false, "Conclua as atividades da profissão antes de finalizar a rota"
		end

		if not isNearPoint(player, job.FinishPoint) then
			return false, "Vá até o marcador de entrega desta profissão"
		end

		local profile = EconomyService.GetProfile(player)
		if not profile then
			return false, "Perfil do jogador ainda não foi carregado"
		end

		profile.professionCompletions = profile.professionCompletions or {}
		local completions = profile.professionCompletions[job.Id] or 0
		local _, _, rankIndex = getProfessionRank(completions)
		local reward = math.floor(job.Reward * (1 + (rankIndex - 1) * 0.05))
		if job.Id == "world_creator" and not active.CreationSubmitted then
			local choices = active.ActivityChoices or {}
			local submitted, submissionResult =
				CreationService.SubmitWorldConcept(player, active.CreationSubmissionId, choices[1], choices[2])
			if not submitted then
				return false, submissionResult
			end
			active.CreationSubmitted = true
		end
		local paid, reason = EconomyService.AddCredits(player, reward, {
			Type = "JobReward",
			JobId = job.Id,
		})
		if not paid then
			return false, reason
		end

		activeJobs[player.UserId] = nil
		cooldownUntil[player.UserId] = now + WORK_COOLDOWN
		if job.Id == "dj" then
			djBoothAccessUntil[player.UserId] = now + Config.Club.DJBoothAccessDuration
		end
		profile.professionCompletions[job.Id] = math.min(completions + 1, 2_000_000_000)
		AchievementService.RecordJobCompleted(player, job.Id)

		local resultMessage = string.format("Trabalho concluído: +%d Society Credits", reward)
		if active.ActivityChoices and #active.ActivityChoices > 0 then
			resultMessage = resultMessage .. " • Decisões: " .. table.concat(active.ActivityChoices, ", ")
		end
		if job.Id == "world_creator" then
			resultMessage ..= " • Conceito enviado para revisão; publicação depende de aprovação."
		end

		return true,
			{
				Message = resultMessage,
				Reward = reward,
			}
	end

	return false, "Ação de trabalho inválida"
end

task.spawn(function()
	while true do
		task.wait(MOVEMENT_SAMPLE_INTERVAL)
		local now = os.clock()

		for userId, active in pairs(activeJobs) do
			local player = Players:GetPlayerByUserId(userId)
			sampleMovement(player, active, now)
		end
	end
end)

function WorkService.CleanupPlayer(player)
	activeJobs[player.UserId] = nil
	cooldownUntil[player.UserId] = nil
	djBoothAccessUntil[player.UserId] = nil
end

return WorkService
