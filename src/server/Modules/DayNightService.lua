local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("Config"))

local DayNightService = {}

local CYCLE_DURATION = 24 * 60
local START_HOUR = 8
local UPDATE_INTERVAL = 5

local keyframes = {
	{
		Hour = 0,
		Brightness = 0.9,
		Exposure = -0.25,
		Ambient = Color3.fromRGB(45, 52, 78),
		OutdoorAmbient = Color3.fromRGB(34, 42, 68),
		AtmosphereColor = Color3.fromRGB(70, 88, 140),
		AtmosphereDecay = Color3.fromRGB(28, 36, 64),
		Density = 0.34,
		Haze = 1.6,
		Tint = Color3.fromRGB(170, 185, 255),
		Saturation = -0.14,
	},
	{
		Hour = 5,
		Brightness = 1.2,
		Exposure = -0.08,
		Ambient = Color3.fromRGB(112, 96, 110),
		OutdoorAmbient = Color3.fromRGB(100, 84, 98),
		AtmosphereColor = Color3.fromRGB(255, 170, 130),
		AtmosphereDecay = Color3.fromRGB(150, 104, 112),
		Density = 0.3,
		Haze = 1.9,
		Tint = Color3.fromRGB(255, 224, 204),
		Saturation = 0.02,
	},
	{
		Hour = 7,
		Brightness = 2.1,
		Exposure = 0.05,
		Ambient = Color3.fromRGB(150, 150, 158),
		OutdoorAmbient = Color3.fromRGB(136, 148, 162),
		AtmosphereColor = Color3.fromRGB(205, 222, 255),
		AtmosphereDecay = Color3.fromRGB(130, 132, 150),
		Density = 0.22,
		Haze = 1.1,
		Tint = Color3.fromRGB(255, 246, 232),
		Saturation = 0.06,
	},
	{
		Hour = 12,
		Brightness = 2.6,
		Exposure = 0.08,
		Ambient = Color3.fromRGB(155, 159, 168),
		OutdoorAmbient = Color3.fromRGB(148, 158, 170),
		AtmosphereColor = Color3.fromRGB(200, 224, 255),
		AtmosphereDecay = Color3.fromRGB(116, 128, 148),
		Density = 0.18,
		Haze = 0.6,
		Tint = Color3.fromRGB(255, 255, 255),
		Saturation = 0.08,
	},
	{
		Hour = 17,
		Brightness = 2.1,
		Exposure = 0,
		Ambient = Color3.fromRGB(160, 142, 132),
		OutdoorAmbient = Color3.fromRGB(158, 130, 114),
		AtmosphereColor = Color3.fromRGB(255, 190, 140),
		AtmosphereDecay = Color3.fromRGB(162, 120, 104),
		Density = 0.26,
		Haze = 1.7,
		Tint = Color3.fromRGB(255, 224, 198),
		Saturation = 0.1,
	},
	{
		Hour = 19,
		Brightness = 1.2,
		Exposure = -0.15,
		Ambient = Color3.fromRGB(96, 88, 118),
		OutdoorAmbient = Color3.fromRGB(80, 74, 110),
		AtmosphereColor = Color3.fromRGB(150, 120, 170),
		AtmosphereDecay = Color3.fromRGB(62, 58, 98),
		Density = 0.32,
		Haze = 1.9,
		Tint = Color3.fromRGB(226, 210, 255),
		Saturation = 0,
	},
	{
		Hour = 21,
		Brightness = 0.85,
		Exposure = -0.24,
		Ambient = Color3.fromRGB(52, 60, 88),
		OutdoorAmbient = Color3.fromRGB(40, 48, 78),
		AtmosphereColor = Color3.fromRGB(86, 105, 150),
		AtmosphereDecay = Color3.fromRGB(32, 40, 70),
		Density = 0.34,
		Haze = 1.5,
		Tint = Color3.fromRGB(184, 196, 255),
		Saturation = -0.12,
	},
	{
		Hour = 24,
		Brightness = 0.9,
		Exposure = -0.25,
		Ambient = Color3.fromRGB(45, 52, 78),
		OutdoorAmbient = Color3.fromRGB(34, 42, 68),
		AtmosphereColor = Color3.fromRGB(70, 88, 140),
		AtmosphereDecay = Color3.fromRGB(28, 36, 64),
		Density = 0.34,
		Haze = 1.6,
		Tint = Color3.fromRGB(170, 185, 255),
		Saturation = -0.14,
	},
}

local initialized = false
local atmosphere
local colorCorrection

local function getOrCreateEffect(className, name)
	local effect = Lighting:FindFirstChild(name)
	if effect then
		if not effect:IsA(className) then
			error(string.format("Lighting.%s precisa ser %s", name, className))
		end
		return effect
	end

	effect = Instance.new(className)
	effect.Name = name
	effect.Parent = Lighting
	return effect
end

local function getPhase(hour)
	if hour >= 6 and hour < 12 then
		return "Manhã"
	elseif hour >= 12 and hour < 18 then
		return "Tarde"
	elseif hour >= 18 and hour < 21 then
		return "Entardecer"
	end

	return "Noite"
end

local function getLightingPreset(hour)
	for index = 1, #keyframes - 1 do
		local current = keyframes[index]
		local nextFrame = keyframes[index + 1]
		if hour >= current.Hour and hour < nextFrame.Hour then
			local alpha = (hour - current.Hour) / (nextFrame.Hour - current.Hour)
			return current, nextFrame, alpha
		end
	end

	return keyframes[1], keyframes[2], 0
end

local function interpolate(current, nextFrame, alpha)
	Lighting.Brightness = current.Brightness + (nextFrame.Brightness - current.Brightness) * alpha
	Lighting.ExposureCompensation = current.Exposure + (nextFrame.Exposure - current.Exposure) * alpha
	Lighting.Ambient = current.Ambient:Lerp(nextFrame.Ambient, alpha)
	Lighting.OutdoorAmbient = current.OutdoorAmbient:Lerp(nextFrame.OutdoorAmbient, alpha)
	atmosphere.Color = current.AtmosphereColor:Lerp(nextFrame.AtmosphereColor, alpha)
	atmosphere.Decay = current.AtmosphereDecay:Lerp(nextFrame.AtmosphereDecay, alpha)
	atmosphere.Density = current.Density + (nextFrame.Density - current.Density) * alpha
	atmosphere.Haze = current.Haze + (nextFrame.Haze - current.Haze) * alpha
	colorCorrection.TintColor = current.Tint:Lerp(nextFrame.Tint, alpha)
	colorCorrection.Saturation = current.Saturation + (nextFrame.Saturation - current.Saturation) * alpha
end

function DayNightService.Init()
	if initialized then
		return
	end
	initialized = true

	atmosphere = getOrCreateEffect("Atmosphere", "HSC_DayNightAtmosphere")
	atmosphere.Glare = 0.2
	atmosphere.Offset = 0.1
	colorCorrection = getOrCreateEffect("ColorCorrectionEffect", "HSC_DayNightColor")
	colorCorrection.Brightness = 0.02
	colorCorrection.Contrast = 0.08

	local startedAt = os.clock()
	local dayNightConfig = Config.DayNight or {}
	local useRealTime = dayNightConfig.UseRealTime == true
	local utcOffset = tonumber(dayNightConfig.UTCOffsetHours) or 0
	task.spawn(function()
		local lastPhase
		while true do
			local hour
			if useRealTime then
				-- Hora real: segundos do dia em UTC + fuso configurado.
				local secondsOfDay = (os.time() + utcOffset * 3600) % 86400
				hour = secondsOfDay / 3600
			else
				local elapsed = os.clock() - startedAt
				hour = (START_HOUR + (elapsed / CYCLE_DURATION) * 24) % 24
			end
			local current, nextFrame, alpha = getLightingPreset(hour)

			Lighting.ClockTime = hour
			interpolate(current, nextFrame, alpha)

			local phase = getPhase(hour)
			if phase ~= lastPhase then
				lastPhase = phase
				Lighting:SetAttribute("HSC_TimePhase", phase)
			end

			task.wait(UPDATE_INTERVAL)
		end
	end)
end

return DayNightService
