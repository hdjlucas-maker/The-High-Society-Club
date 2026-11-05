local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("Config"))
local WorkService = require(script.Parent.WorkService)

local ClubService = {}

local styles = {
	golden_gala = {
		Name = "Gala dourada",
		Colors = {
			Color3.fromRGB(255, 215, 120),
			Color3.fromRGB(255, 244, 205),
			Color3.fromRGB(222, 174, 76),
		},
	},
	ocean_lounge = {
		Name = "Lounge oceânico",
		Colors = {
			Color3.fromRGB(76, 195, 220),
			Color3.fromRGB(140, 225, 238),
			Color3.fromRGB(60, 120, 185),
		},
	},
	neon_night = {
		Name = "Noite neon",
		Colors = {
			Color3.fromRGB(206, 100, 240),
			Color3.fromRGB(78, 196, 255),
			Color3.fromRGB(245, 96, 155),
		},
	},
}

local stageLight
local stageBeams = {}
local stageModel
local music
local performance

local function findStage()
	local world = workspace:FindFirstChild(Config.Map.WorldName)
	local decorations = world and world:FindFirstChild("EventDecorations")
	local stage = decorations and decorations:FindFirstChild("ClubStage")
	return stage
end

local function updateLights(style, beat)
	if not stageLight or not stageModel then
		return
	end

	local colorIndex = (beat - 1) % #style.Colors + 1
	local color = style.Colors[colorIndex]
	stageLight.Color = color
	stageLight.Brightness = 1 + (beat % 2) * 0.7
	stageModel:SetAttribute("ShowColor", color)

	for index, beam in ipairs(stageBeams) do
		beam.Color = color
		beam.Brightness = index == colorIndex and 2 or 0.6
	end
end

local function stopPerformance()
	performance = nil
	if stageModel then
		stageModel:SetAttribute("ShowActive", false)
		stageModel:SetAttribute("DJName", nil)
	end
	if stageLight then
		stageLight.Color = Color3.fromRGB(218, 180, 91)
		stageLight.Brightness = 0.6
	end
	for _, beam in ipairs(stageBeams) do
		beam.Brightness = 0
	end
	if music and music.IsPlaying then
		music:Stop()
	end
end

local function getPublicStatus(player)
	local canOperate = WorkService.CanOperateDJBooth(player)
	local remaining = performance and math.max(0, math.ceil(performance.ExpiresAt - os.clock())) or 0
	return {
		ShowActive = performance ~= nil,
		DJName = performance and performance.DJName or nil,
		StyleId = performance and performance.StyleId or nil,
		StyleName = performance and styles[performance.StyleId].Name or nil,
		SecondsRemaining = remaining,
		CanOperate = canOperate,
		IsPerformer = performance ~= nil and performance.UserId == player.UserId,
		MusicConfigured = music ~= nil and music.SoundId ~= "",
		Styles = {
			{ Id = "golden_gala", Name = styles.golden_gala.Name },
			{ Id = "ocean_lounge", Name = styles.ocean_lounge.Name },
			{ Id = "neon_night", Name = styles.neon_night.Name },
		},
	}
end

function ClubService.Init()
	stageModel = findStage()
	if not stageModel or not stageModel:IsA("Model") then
		error("Workspace.HighSocietyWorld.EventDecorations.ClubStage precisa existir antes de inicializar ClubService")
	end
	local lightBar = stageModel:FindFirstChild("LightBar")
	stageLight = lightBar and lightBar:FindFirstChild("StageLight")
	if not lightBar or not lightBar:IsA("BasePart") or not stageLight or not stageLight:IsA("PointLight") then
		error("ClubStage precisa conter LightBar.StageLight")
	end
	for index = 1, 3 do
		local beam = lightBar:FindFirstChild("StageBeam" .. index)
		if not beam or not beam:IsA("SpotLight") then
			error(string.format("ClubStage precisa conter StageBeam%d", index))
		end
		table.insert(stageBeams, beam)
	end

	local soundId = Config.Club.MusicSoundId
	if typeof(soundId) ~= "string" or (soundId ~= "" and not string.match(soundId, "^rbxassetid://%d+$")) then
		error("Config.Club.MusicSoundId precisa estar vazio ou usar o formato rbxassetid://<ID>")
	end
	if
		typeof(Config.Club.MaxPerformanceDuration) ~= "number"
		or Config.Club.MaxPerformanceDuration <= 0
		or Config.Club.MaxPerformanceDuration ~= math.floor(Config.Club.MaxPerformanceDuration)
	then
		error("Config.Club.MaxPerformanceDuration precisa ser um inteiro positivo")
	end
	if soundId ~= "" then
		music = lightBar:FindFirstChild("ClubMusic")
		if music and not music:IsA("Sound") then
			error("ClubStage.LightBar.ClubMusic precisa ser Sound")
		end
		if not music then
			music = Instance.new("Sound")
			music.Name = "ClubMusic"
			music.Parent = lightBar
		end
		music.SoundId = soundId
		music.Looped = true
		music.Volume = 0.35
	end

	stageModel:SetAttribute("ShowActive", false)
	task.spawn(function()
		local beat = 0
		while true do
			task.wait(1.25)
			if not performance then
				continue
			end

			local performer = Players:GetPlayerByUserId(performance.UserId)
			if not performer or os.clock() >= performance.ExpiresAt or not WorkService.CanOperateDJBooth(performer) then
				stopPerformance()
				continue
			end

			beat += 1
			updateLights(styles[performance.StyleId], beat)
		end
	end)
end

function ClubService.GetStatus(player)
	if not player or player.Parent ~= Players then
		return nil, "Jogador inválido"
	end
	return getPublicStatus(player)
end

function ClubService.HandleRequest(player, action, styleId)
	if not player or player.Parent ~= Players then
		return false, "Jogador inválido"
	end
	if typeof(action) ~= "string" then
		return false, "Solicitação da cabine inválida"
	end
	if not WorkService.CanOperateDJBooth(player) then
		return false, "Conclua a rota de DJ e aproxime-se da cabine do Grand Society Club"
	end

	if action == "Start" then
		if performance then
			return false, "Já existe uma apresentação em andamento"
		end
		if styleId ~= nil and (typeof(styleId) ~= "string" or not styles[styleId]) then
			return false, "Estilo de apresentação inválido"
		end
		local selectedStyle = styleId or "golden_gala"
		performance = {
			UserId = player.UserId,
			DJName = player.DisplayName,
			StyleId = selectedStyle,
			ExpiresAt = os.clock() + Config.Club.MaxPerformanceDuration,
		}
		stageModel:SetAttribute("ShowActive", true)
		stageModel:SetAttribute("DJName", player.DisplayName)
		stageModel:SetAttribute("StyleId", selectedStyle)
		if music and not music.IsPlaying then
			music:Play()
		end
		updateLights(styles[selectedStyle], 1)
		return true, "Apresentação iniciada no Grand Society Club"
	end

	if not performance or performance.UserId ~= player.UserId then
		return false, "Somente o DJ da apresentação atual pode controlar a cabine"
	end
	if action == "Stop" then
		stopPerformance()
		return true, "Apresentação encerrada"
	end
	if action == "SetStyle" then
		if typeof(styleId) ~= "string" or not styles[styleId] then
			return false, "Estilo de apresentação inválido"
		end
		performance.StyleId = styleId
		stageModel:SetAttribute("StyleId", styleId)
		updateLights(styles[styleId], 1)
		return true, "Estilo alterado: " .. styles[styleId].Name
	end

	return false, "Ação de cabine inválida"
end

function ClubService.CleanupPlayer(player)
	if performance and performance.UserId == player.UserId then
		stopPerformance()
	end
end

return ClubService
