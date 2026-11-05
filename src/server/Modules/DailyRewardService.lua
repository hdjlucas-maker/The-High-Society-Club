local EconomyService = require(script.Parent.EconomyService)

local DailyRewardService = {}

local BASE_REWARD = 100
local STREAK_INCREMENT = 25
local MAX_REWARD = 300
local MAX_STREAK = 3650

local function getUtcDay()
	return math.floor(os.time() / 86400)
end

local function getReward(streak)
	return math.min(BASE_REWARD + math.max(streak - 1, 0) * STREAK_INCREMENT, MAX_REWARD)
end

function DailyRewardService.GetStatus(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	local today = getUtcDay()
	local streak = profile.dailyRewardStreak or 0
	local alreadyClaimed = (profile.dailyRewardDay or 0) >= today
	local projectedStreak = if alreadyClaimed
		then streak
		elseif (profile.dailyRewardDay or 0) == today - 1 then math.min(streak + 1, MAX_STREAK)
		else 1
	local secondsUntilReset = (today + 1) * 86400 - os.time()

	return {
		ClaimedToday = alreadyClaimed,
		CurrentStreak = streak,
		NextStreak = projectedStreak,
		Reward = alreadyClaimed and 0 or getReward(projectedStreak),
		SecondsUntilReset = secondsUntilReset,
	}
end

function DailyRewardService.Claim(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return false, "Perfil do jogador ainda não foi carregado"
	end

	local today = getUtcDay()
	if (profile.dailyRewardDay or 0) >= today then
		return false, "Você já resgatou sua recompensa diária. Volte após a virada UTC."
	end

	local previousDay = profile.dailyRewardDay or 0
	local streak = previousDay == today - 1 and math.min((profile.dailyRewardStreak or 0) + 1, MAX_STREAK) or 1
	local reward = getReward(streak)
	local granted, reason = EconomyService.AddCredits(player, reward, {
		Type = "DailyReward",
	})
	if not granted then
		return false, reason
	end

	profile.dailyRewardDay = today
	profile.dailyRewardStreak = streak
	return true,
		{
			Reward = reward,
			Streak = streak,
			Message = string.format(
				"Recompensa diária resgatada: +%d Society Credits • sequência de %d dias.",
				reward,
				streak
			),
		}
end

return DailyRewardService
