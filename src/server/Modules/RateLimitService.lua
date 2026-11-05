local RateLimitService = {}

local requestsByUserId = {}

function RateLimitService.Allow(player, key, cooldown)
	if
		typeof(player) ~= "Instance"
		or not player:IsA("Player")
		or type(key) ~= "string"
		or key == ""
		or type(cooldown) ~= "number"
		or cooldown < 0
		or cooldown ~= cooldown
		or cooldown == math.huge
	then
		return false
	end

	local userId = player.UserId
	local now = os.clock()
	local userRequests = requestsByUserId[userId]
	if not userRequests then
		userRequests = {}
		requestsByUserId[userId] = userRequests
	end

	local previous = userRequests[key]
	if previous and now - previous < cooldown then
		return false
	end

	userRequests[key] = now
	return true
end

function RateLimitService.CleanupPlayer(player)
	if player and player:IsA("Player") then
		requestsByUserId[player.UserId] = nil
	end
end

return RateLimitService
