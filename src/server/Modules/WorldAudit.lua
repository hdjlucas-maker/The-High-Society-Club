-- WorldAudit: auditoria de leitura do mundo gerado.
--
-- Não altera nada. Apenas percorre o Workspace e escreve um relatório no
-- Output com os problemas que explicam a sensação de mundo desalinhado:
--   * mobiliário (postes, árvores e palmeiras) dentro da área de caminhada;
--   * duplicatas de postes/árvores/palmeiras no mesmo lugar;
--   * placas soltas, sem apoio abaixo;
--   * superfícies de caminhada em alturas diferentes do padrão.
--
-- A auditoria roda uma vez, por padrão apenas no Studio, e guarda o resultado
-- como atributos no folder do mundo para facilitar a inspeção no Explorer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local Logger = require(Shared:WaitForChild("Logger"))

local WorldAudit = {}

local MAX_ISSUES = 40
local initialized = false

-- Apenas áreas de caminhada. As pistas (MainRoad, FrontAvenueRoad e
-- ConnectorRoad) ficam de fora porque os canteiros centrais têm postes
-- legítimos; o que queremos pegar é mobiliário no meio do pedestre.
local WALKWAY_NAMES = {
	BoulevardSidewalk = true,
	FrontAvenueSidewalkSouth = true,
	FrontAvenueSidewalkNorth = true,
	EntrancePath = true,
	IslandPromenade = true,
	BeachPromenade = true,
	MarinaPromenade = true,
	BoulevardToGarden = true,
	ClubPromenade = true,
	BoulevardToMarina = true,
	GardenWalkNorth = true,
	GardenWalkSouth = true,
}

-- Topo esperado de cada superfície, relativo ao groundY do lugar.
local SURFACE_EXPECTATIONS = {
	MainRoad = "Walk",
	BoulevardSidewalk = "Walk",
	FrontAvenueRoad = "Walk",
	FrontAvenueSidewalkSouth = "Walk",
	FrontAvenueSidewalkNorth = "Walk",
	ConnectorRoad = "Walk",
	EntrancePath = "Walk",
	IslandPromenade = "Walk",
	BeachPromenade = "Walk",
	MarinaPromenade = "Walk",
	IslandBeach = "Walk",
	GardenWalkNorth = "Walk",
	GardenWalkSouth = "Walk",
	GardenLawn = "Lawn",
	ClubPlaza = "Walk",
	PlazaBase = "Plaza",
}

local SURFACE_OFFSETS = {
	Walk = 0.30,
	Lawn = 0.50,
	Plaza = 0.75,
}

local SURFACE_LABELS = {
	Walk = "nível de caminhada",
	Lawn = "gramado",
	Plaza = "praça",
}

local function addIssue(issues, category, message)
	if #issues >= MAX_ISSUES then
		return
	end
	table.insert(issues, {
		Category = category,
		Message = message,
	})
end

local function surfaceTop(part)
	return part.Position.Y + part.Size.Y / 2
end

local function checkSignSupport(sign)
	local filter = { sign }
	local prefix = sign.Name
	local parent = sign.Parent
	local boardBottom = sign.Position.Y - sign.Size.Y / 2
	local supported = false

	if parent then
		for _, sibling in ipairs(parent:GetChildren()) do
			if sibling:IsA("BasePart") and sibling ~= sign then
				local siblingName = sibling.Name
				local samePrefix = siblingName:sub(1, #prefix) == prefix
				local isSupport = siblingName:match("Post")
					or siblingName:match("Support")
					or siblingName:match("Beam")
					or siblingName:match("Pole")
					or siblingName:match("Column")

				if isSupport then
					local siblingTop = sibling.Position.Y + sibling.Size.Y / 2
					local horizontal = Vector3.new(
						sibling.Position.X - sign.Position.X,
						0,
						sibling.Position.Z - sign.Position.Z
					).Magnitude
					if horizontal <= sign.Size.X / 2 + 2 and math.abs(siblingTop - boardBottom) <= 1.2 then
						supported = true
					end
				end

				if samePrefix and not isSupport then
					table.insert(filter, sibling)
				end
			end
		end
	end

	if supported then
		return true
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = filter
	raycastParams.RespectCanCollide = true

	local origin = sign.Position - Vector3.new(0, sign.Size.Y / 2 + 0.02, 0)
	local result = Workspace:Raycast(origin, Vector3.new(0, -9, 0), raycastParams)
	if result and result.Distance <= 2 then
		return true
	end

	return false
end

local function isInsideWalkway(position, walkway)
	local localPoint = walkway.CFrame:PointToObjectSpace(position)
	return math.abs(localPoint.X) <= walkway.Size.X / 2 - 0.5
		and math.abs(localPoint.Z) <= walkway.Size.Z / 2 - 0.5
end

local function addDuplicateIssues(issues, items, radius, label)
	if #items < 2 then
		return
	end

	for leftIndex = 1, #items - 1 do
		for rightIndex = leftIndex + 1, #items do
			local left = items[leftIndex]
			local right = items[rightIndex]
			local distance = (left.Position - right.Position).Magnitude
			if distance < radius then
				addIssue(
					issues,
					"Duplicidade",
					string.format(
						"%s '%s' e '%s' a %.1f studs um do outro em (%.1f, %.1f).",
						label,
						left.Name,
						right.Name,
						distance,
						left.Position.X,
						left.Position.Z
					)
				)
			end
		end
	end
end

function WorldAudit.Run(world, groundY)
	local issues = {}
	local partCount = 0
	local modelCount = 0

	-- Spawns: mais de um SpawnLocation faz o Roblox escolher aleatoriamente
	-- onde o jogador nasce, inclusive em um ponto antigo/errado.
	local spawns = {}
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("SpawnLocation") then
			table.insert(spawns, descendant)
		end
	end
	if #spawns == 0 then
		addIssue(issues, "Spawn", "Nenhum SpawnLocation encontrado no Workspace.")
	elseif #spawns > 1 then
		addIssue(
			issues,
			"Spawn",
			string.format(
				"Há %d SpawnLocations no Workspace; o jogador pode nascer em qualquer um deles.",
				#spawns
			)
		)
	end

	local walkways = {}
	local lampPoles = {}
	local vegetation = {}
	local surfaces = {}

	for _, descendant in ipairs(world:GetDescendants()) do
		if descendant:IsA("BasePart") then
			partCount += 1

			if WALKWAY_NAMES[descendant.Name] then
				table.insert(walkways, descendant)
			end

			if descendant.Name:match("LampPole$") then
				table.insert(lampPoles, descendant)
			end

			if SURFACE_EXPECTATIONS[descendant.Name] then
				table.insert(surfaces, descendant)
			end

			if descendant:FindFirstChild("SignSurface") and not descendant:FindFirstAncestorOfClass("Model") then
				if not checkSignSupport(descendant) then
					addIssue(
						issues,
						"Placa",
						string.format(
							"'%s' flutua sem apoio em (%.1f, %.1f, %.1f).",
							descendant.Name,
							descendant.Position.X,
							descendant.Position.Y,
							descendant.Position.Z
						)
					)
				end
			end
		elseif descendant:IsA("Model") then
			modelCount += 1
			if descendant.Name:match("Tree") or descendant.Name:match("Palm") then
				table.insert(vegetation, {
					Name = descendant.Name,
					Position = descendant:GetPivot().Position,
				})
			end
		end
	end

	-- Mobiliário dentro da faixa de caminhada.
	for _, pole in ipairs(lampPoles) do
		for _, walkway in ipairs(walkways) do
			if isInsideWalkway(pole.Position, walkway) then
				addIssue(
					issues,
					"Passagem",
					string.format(
						"Poste '%s' no meio de '%s' em (%.1f, %.1f).",
						pole.Name,
						walkway.Name,
						pole.Position.X,
						pole.Position.Z
					)
				)
				break
			end
		end
	end

	for _, plant in ipairs(vegetation) do
		for _, walkway in ipairs(walkways) do
			if isInsideWalkway(plant.Position, walkway) then
				addIssue(
					issues,
					"Passagem",
					string.format(
						"%s no meio de '%s' em (%.1f, %.1f).",
						plant.Name,
						walkway.Name,
						plant.Position.X,
						plant.Position.Z
					)
				)
				break
			end
		end
	end

	addDuplicateIssues(issues, lampPoles, 6, "Poste")
	addDuplicateIssues(issues, vegetation, 6, "Árvore/palmeira")

	-- Alturas das superfícies caminháveis.
	for _, surface in ipairs(surfaces) do
		local expectedKind = SURFACE_EXPECTATIONS[surface.Name]
		local expectedOffset = SURFACE_OFFSETS[expectedKind]
		if expectedOffset then
			local actual = surfaceTop(surface) - groundY
			local difference = actual - expectedOffset
			if math.abs(difference) > 0.12 then
				addIssue(
					issues,
					"Altura",
					string.format(
						"'%s' está em +%.2f; esperado +%.2f (%s).",
						surface.Name,
						actual,
						expectedOffset,
						SURFACE_LABELS[expectedKind] or expectedKind
					)
				)
			end
		end
	end

	return {
		Issues = issues,
		PartCount = partCount,
		ModelCount = modelCount,
		WalkwayCount = #walkways,
		LampCount = #lampPoles,
		VegetationCount = #vegetation,
	}
end

local function getGroundY()
	local baseplate = Workspace:FindFirstChild(Config.Map.BaseplateName)
	if baseplate and baseplate:IsA("BasePart") then
		return baseplate.Position.Y + baseplate.Size.Y / 2
	end
	return 0
end

function WorldAudit.Init()
	if initialized then
		return
	end
	initialized = true

	local worldConfig = Config.World or {}
	if worldConfig.AuditOnStart == false then
		return
	end
	if worldConfig.AuditOnlyInStudio ~= false and not RunService:IsStudio() then
		return
	end

	task.spawn(function()
		-- Espera o WorldLife e os demais geradores terminarem a decoração.
		task.wait(2)

		local world = Workspace:FindFirstChild(Config.Map.WorldName)
		if not world then
			Logger.Warn("WorldAudit", "HighSocietyWorld não foi encontrado; auditoria não executada.")
			return
		end

		local groundY = getGroundY()
		local report = WorldAudit.Run(world, groundY)

		world:SetAttribute("HSC_AuditIssues", #report.Issues)
		world:SetAttribute("HSC_AuditPartCount", report.PartCount)
		world:SetAttribute("HSC_AuditLastRun", os.time())

		Logger.Info(
			"WorldAudit",
			string.format(
				"Auditoria v1: %d peças, %d modelos, %d áreas de caminhada, %d postes, %d árvores/palmeiras, %d aviso(s).",
				report.PartCount,
				report.ModelCount,
				report.WalkwayCount,
				report.LampCount,
				report.VegetationCount,
				#report.Issues
			)
		)

		for _, issue in ipairs(report.Issues) do
			Logger.Warn("WorldAudit", string.format("[%s] %s", issue.Category, issue.Message))
		end

		if #report.Issues == 0 then
			Logger.Info("WorldAudit", "Nenhuma violação crítica encontrada na auditoria v1.")
		end
	end)
end

return WorldAudit
