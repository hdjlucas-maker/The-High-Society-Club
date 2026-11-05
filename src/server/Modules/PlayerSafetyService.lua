-- PlayerSafetyService: tira o jogador de situações em que ele fica preso.
--
-- Funciona apenas por detecção automática e silenciosa: jogador empurrando
-- uma parede sem sair do lugar por alguns segundos e com o corpo sobreposto
-- a uma peça colidível. Não existe botão nem interface de resgate.
--
-- O destino é sempre o spawn seguro (HSC_Spawn ou a SpawnLocation do lugar).
-- Nada aqui apaga construções ou altera a economia.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))

local PlayerSafetyService = {}

local states = {}
local initialized = false

local function getSafetyConfig()
	return Config.Safety or {}
end

local function getState(player)
	local state = states[player]
	if not state then
		state = {
			StuckSeconds = 0,
			LastPosition = nil,
			LastRescue = 0,
		}
		states[player] = state
	end
	return state
end

local function getCharacter(player)
	local character = player.Character
	if not character or not character:IsA("Model") then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not humanoid:IsA("Humanoid") or not root or not root:IsA("BasePart") then
		return nil
	end

	return character, humanoid, root
end

local function getSpawnPart()
	-- Prefere o spawn gerado pela praça central, que é o ponto seguro
	-- conhecido. A SpawnLocation padrão do lugar é o fallback.
	local world = Workspace:FindFirstChild(Config.Map.WorldName)
	if world then
		local safeSpawn = world:FindFirstChild("HSC_Spawn", true)
		if safeSpawn and safeSpawn:IsA("BasePart") then
			return safeSpawn
		end
	end

	return Workspace:FindFirstChildOfClass("SpawnLocation")
end

local function getSafeDestination()
	local spawn = getSpawnPart()
	if spawn then
		-- O pivô do personagem fica aproximadamente 3 studs acima dos pés.
		return spawn.Position + Vector3.new(0, spawn.Size.Y / 2 + 3.4, 0)
	end

	local world = Workspace:FindFirstChild(Config.Map.WorldName)
	local plaza = world and world:FindFirstChild("CentralPlaza")
	local plazaBase = plaza and plaza:FindFirstChild("PlazaBase")
	if plazaBase and plazaBase:IsA("BasePart") then
		return plazaBase.Position + Vector3.new(0, plazaBase.Size.Y / 2 + 3.4, 6)
	end

	return nil
end

local function rescuePlayer(player, reason)
	local safety = getSafetyConfig()
	if safety.Enabled == false then
		return false, "O resgate está desativado."
	end

	local character, humanoid, root = getCharacter(player)
	if not character then
		return false, "Seu personagem ainda não está pronto. Tente novamente em instantes."
	end

	local destination = getSafeDestination()
	if not destination then
		Logger.Warn("PlayerSafety", "Nenhum spawn seguro encontrado para " .. player.Name)
		return false, "O spawn seguro ainda não foi criado. Tente novamente em instantes."
	end

	local state = getState(player)
	local now = os.clock()
	state.LastRescue = now
	state.StuckSeconds = 0
	state.LastPosition = nil

	-- Teleporta o modelo inteiro e zera a velocidade para não continuar
	-- empurrando a parede depois do resgate. Se estiver sentado, levanta
	-- primeiro para não deixar o veículo com um ocupante fantasma.
	if humanoid.SeatPart then
		humanoid.Sit = false
	end
	character:PivotTo(CFrame.new(destination))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	if humanoid.Health > 0 then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	Logger.Info(
		"PlayerSafety",
		string.format(
			"%s resgatado (%s) para (%.1f, %.1f, %.1f)",
			player.Name,
			reason,
			destination.X,
			destination.Y,
			destination.Z
		)
	)
	return true, "Você foi levado ao spawn seguro."
end

local function checkPlayer(player, checkInterval)
	local character, humanoid, root = getCharacter(player)
	local state = getState(player)

	if not character or humanoid.Health <= 0 or humanoid.SeatPart then
		state.StuckSeconds = 0
		state.LastPosition = nil
		return
	end

	local position = root.Position
	if not state.LastPosition then
		state.LastPosition = position
		return
	end

	local moved = (position - state.LastPosition).Magnitude
	state.LastPosition = position

	-- Só conta como preso quem está tentando andar e não sai do lugar.
	local tryingToMove = humanoid.MoveDirection.Magnitude > 0.1
	if not tryingToMove or moved > 0.25 then
		state.StuckSeconds = math.max(0, state.StuckSeconds - checkInterval)
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }

	local overlaps = Workspace:GetPartBoundsInBox(
		CFrame.new(position),
		Vector3.new(1.4, 1.8, 1.4),
		overlapParams
	)

	local blockers = 0
	for _, part in ipairs(overlaps) do
		if part:IsA("BasePart") and part.CanCollide then
			blockers += 1
		end
	end

	if blockers == 0 then
		state.StuckSeconds = 0
		return
	end

	state.StuckSeconds += checkInterval
	local threshold = tonumber(getSafetyConfig().AutoUnstuckSeconds) or 5
	if state.StuckSeconds < threshold then
		return
	end

	-- Evita um segundo resgate em sequência se o spawn estiver momentaneamente
	-- ocupado por outro avatar.
	if state.LastRescue > 0 and os.clock() - state.LastRescue < 5 then
		state.StuckSeconds = 0
		return
	end

	local success, message = rescuePlayer(player, "detecção automática")
	if not success then
		state.StuckSeconds = 0
		Logger.Warn("PlayerSafety", string.format("Falha no resgate automático de %s: %s", player.Name, tostring(message)))
	end
end

function PlayerSafetyService.CleanupPlayer(player)
	if player then
		states[player] = nil
	end
end

function PlayerSafetyService.Init()
	if initialized then
		return
	end
	initialized = true

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	local safety = getSafetyConfig()
	if safety.AutoUnstuckEnabled == false then
		return
	end

	task.spawn(function()
		local checkInterval = math.max(0.2, tonumber(safety.CheckInterval) or 0.5)
		while true do
			task.wait(checkInterval)
			if getSafetyConfig().Enabled ~= false and getSafetyConfig().AutoUnstuckEnabled ~= false then
				for _, player in ipairs(Players:GetPlayers()) do
					local ok, checkError = pcall(checkPlayer, player, checkInterval)
					if not ok then
						Logger.Warn("PlayerSafety", "Falha na verificação de " .. player.Name .. ": " .. tostring(checkError))
					end
				end
			end
		end
	end)
end

return PlayerSafetyService
