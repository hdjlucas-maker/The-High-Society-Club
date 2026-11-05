local EconomyService = require(script.Parent.EconomyService)

local AchievementService = {}

local catalog = {
	{
		Id = "first_job",
		Name = "Primeiro passo",
		Description = "Conclua sua primeira profissão.",
		Points = 10,
	},
	{
		Id = "five_jobs",
		Name = "Profissional em ascensão",
		Description = "Conclua cinco trabalhos.",
		Points = 25,
	},
	{
		Id = "city_guide",
		Name = "Embaixador da cidade",
		Description = "Conclua um passeio como guia turístico.",
		Points = 15,
	},
	{
		Id = "chauffeur",
		Name = "Rota de excelência",
		Description = "Conclua uma corrida como motorista particular.",
		Points = 15,
	},
	{
		Id = "photographer",
		Name = "Olhar de artista",
		Description = "Conclua um ensaio como fotógrafo virtual.",
		Points = 15,
	},
	{
		Id = "first_property",
		Name = "Novo endereço",
		Description = "Adquira sua primeira propriedade.",
		Points = 20,
	},
	{
		Id = "first_vehicle",
		Name = "Chaves do clube",
		Description = "Adquira seu primeiro veículo.",
		Points = 20,
	},
	{
		Id = "first_style",
		Name = "Estilo próprio",
		Description = "Adquira seu primeiro item de moda.",
		Points = 10,
	},
	{
		Id = "first_event",
		Name = "Presença marcante",
		Description = "Participe do seu primeiro evento.",
		Points = 15,
	},
}

local achievementsById = {}
for _, achievement in ipairs(catalog) do
	achievementsById[achievement.Id] = achievement
end

local unlockedRemote

local function unlock(player, achievementId)
	local profile = EconomyService.GetProfile(player)
	local definition = achievementsById[achievementId]
	if not profile or not definition then
		return false
	end

	profile.achievements = profile.achievements or {}
	if profile.achievements[achievementId] then
		return false
	end

	local unlockedAt = os.time()
	profile.achievements[achievementId] = unlockedAt
	if unlockedRemote and unlockedRemote.Parent then
		unlockedRemote:FireClient(player, {
			Id = achievementId,
			Name = definition.Name,
			Description = definition.Description,
			Points = definition.Points,
			UnlockedAt = unlockedAt,
		})
	end
	return true
end

function AchievementService.Init(remote)
	unlockedRemote = remote
end

function AchievementService.GetCatalog(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	local result = {}
	local reputation = 0
	for _, achievement in ipairs(catalog) do
		local unlockedAt = profile.achievements and profile.achievements[achievement.Id]
		if
			type(unlockedAt) == "number"
			and unlockedAt == unlockedAt
			and unlockedAt >= 0
			and unlockedAt <= 253_402_300_799
		then
			unlockedAt = math.floor(unlockedAt)
			reputation += achievement.Points
		else
			unlockedAt = nil
		end

		table.insert(result, {
			Id = achievement.Id,
			Name = achievement.Name,
			Description = achievement.Description,
			Points = achievement.Points,
			UnlockedAt = unlockedAt,
		})
	end

	local reputationTitle = "Visitante"
	if reputation >= 100 then
		reputationTitle = "Ícone da Alta Sociedade"
	elseif reputation >= 60 then
		reputationTitle = "Referência do Clube"
	elseif reputation >= 25 then
		reputationTitle = "Membro da Sociedade"
	end

	return {
		Achievements = result,
		Reputation = reputation,
		ReputationTitle = reputationTitle,
		CompletedJobs = profile.completedJobs or 0,
	}
end

function AchievementService.RecordJobCompleted(player, jobId)
	local profile = EconomyService.GetProfile(player)
	if not profile or type(jobId) ~= "string" then
		return
	end

	profile.completedJobs = math.min((profile.completedJobs or 0) + 1, 2_000_000_000)
	unlock(player, "first_job")
	if profile.completedJobs >= 5 then
		unlock(player, "five_jobs")
	end
	unlock(player, jobId)
end

function AchievementService.RecordMilestone(player, milestone)
	local achievementIdByMilestone = {
		PropertyPurchased = "first_property",
		VehiclePurchased = "first_vehicle",
		FashionPurchased = "first_style",
	}
	local achievementId = achievementIdByMilestone[milestone]
	if achievementId then
		unlock(player, achievementId)
	end
end

function AchievementService.RecordEventAttendance(player)
	unlock(player, "first_event")
end

return AchievementService
