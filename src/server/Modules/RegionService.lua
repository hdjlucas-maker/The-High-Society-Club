local Players = game:GetService("Players")

local RegionService = {}

local SCAN_INTERVAL = 0.5
local regions = {
	{
		Name = "Paradise Island & Royal Marina",
		MinX = 124,
		MaxX = 255,
		MinZ = 125,
		MaxZ = 250,
	},
	{
		Name = "Garden Park",
		MinX = -210,
		MaxX = -90,
		MinZ = 38,
		MaxZ = 130,
	},
	{
		Name = "Grand Society Club",
		MinX = -42,
		MaxX = 66,
		MinZ = 58,
		MaxZ = 140,
	},
	{
		Name = "Millionaire District",
		MinX = 40,
		MaxX = 240,
		MinZ = 20,
		MaxZ = 58,
	},
	{
		Name = "High Society Boulevard",
		MinX = -240,
		MaxX = 240,
		MinZ = -155,
		MaxZ = 65,
	},
}

local regionChanged
local currentRegions = {}
local initialized = false

local function findRegion(position)
	for _, region in ipairs(regions) do
		if
			position.X >= region.MinX
			and position.X <= region.MaxX
			and position.Z >= region.MinZ
			and position.Z <= region.MaxZ
		then
			return region.Name
		end
	end

	return nil
end

function RegionService.Init(remote)
	if initialized then
		return
	end
	initialized = true
	regionChanged = remote

	Players.PlayerRemoving:Connect(function(player)
		currentRegions[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(SCAN_INTERVAL)

			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local regionName
				if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
					regionName = findRegion(root.Position)
				end

				if currentRegions[player] ~= regionName then
					currentRegions[player] = regionName
					if regionChanged and regionChanged.Parent then
						regionChanged:FireClient(player, regionName)
					end
				end
			end
		end
	end)
end

return RegionService
