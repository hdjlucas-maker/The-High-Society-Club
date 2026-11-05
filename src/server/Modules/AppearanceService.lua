local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyService = require(script.Parent.EconomyService)
local Logger = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("Logger"))
local fashionCatalog = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("FashionCatalog"))
local PlayerMarketService = require(script.Parent.PlayerMarketService)

local AppearanceService = {}

local ITEM_DEFINITIONS = {}
for _, item in ipairs(fashionCatalog) do
	ITEM_DEFINITIONS[item.Id] = {
		Slot = item.Slot,
		Color = item.Color,
	}
end

local function getBodyPart(character, preferredName, fallbackName)
	return character:FindFirstChild(preferredName) or character:FindFirstChild(fallbackName)
end

local function removeItemVisuals(character, itemId)
	for _, child in ipairs(character:GetChildren()) do
		if child:GetAttribute("SocietyWearable") and child:GetAttribute("SocietyItemId") == itemId then
			child:Destroy()
		end
	end
end

local function removeAllVisuals(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:GetAttribute("SocietyWearable") then
			child:Destroy()
		end
	end
end

local function attachPart(character, itemId, bodyPart, name, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = "SocietyWearable_" .. itemId .. "_" .. name
	part.Size = size
	part.CFrame = bodyPart.CFrame * offset
	part.Color = color
	part.Material = material
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("SocietyWearable", true)
	part:SetAttribute("SocietyItemId", itemId)
	part.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bodyPart
	weld.Part1 = part
	weld.Parent = part

	return part
end

local function applyJacket(character, color)
	local torso = getBodyPart(character, "UpperTorso", "Torso")
	if not torso or not torso:IsA("BasePart") then
		return false, "Não foi possível encontrar o torso do avatar"
	end

	local fit = Vector3.new(0.12, 0.08, 0.12)
	attachPart(character, "elite_jacket", torso, "Jacket", torso.Size + fit, CFrame.new(), color, Enum.Material.Fabric)

	local frontZ = -(torso.Size.Z / 2 + 0.075)
	for side = -1, 1, 2 do
		attachPart(
			character,
			"elite_jacket",
			torso,
			"GoldTrim",
			Vector3.new(0.07, math.max(0.35, torso.Size.Y * 0.62), 0.04),
			CFrame.new(side * 0.13, 0, frontZ),
			Color3.fromRGB(221, 183, 93),
			Enum.Material.Metal
		)
	end

	return true
end

local function applyWatch(character, color)
	local arm = getBodyPart(character, "RightHand", "Right Arm")
	if not arm or not arm:IsA("BasePart") then
		return false, "Não foi possível encontrar a mão direita do avatar"
	end

	local wristOffset = CFrame.new(0, -arm.Size.Y * 0.38, 0)
	attachPart(
		character,
		"luxury_watch",
		arm,
		"WatchBand",
		Vector3.new(math.max(0.35, arm.Size.X * 0.85), 0.2, math.max(0.35, arm.Size.Z * 0.85)),
		wristOffset,
		color,
		Enum.Material.Metal
	)
	attachPart(
		character,
		"luxury_watch",
		arm,
		"WatchFace",
		Vector3.new(0.28, 0.08, 0.28),
		wristOffset * CFrame.new(0, 0.12, -arm.Size.Z * 0.44),
		Color3.fromRGB(30, 32, 38),
		Enum.Material.Metal
	)

	return true
end

local function applyGlasses(character, color)
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return false, "Não foi possível encontrar a cabeça do avatar"
	end

	local lensSize = Vector3.new(head.Size.X * 0.34, head.Size.Y * 0.22, 0.08)
	local lensY = -head.Size.Y * 0.05
	local frontZ = -(head.Size.Z / 2 + 0.045)
	for side = -1, 1, 2 do
		attachPart(
			character,
			"sunset_glasses",
			head,
			"Lens",
			lensSize,
			CFrame.new(side * head.Size.X * 0.2, lensY, frontZ),
			color,
			Enum.Material.Glass
		)
		attachPart(
			character,
			"sunset_glasses",
			head,
			"Frame",
			Vector3.new(lensSize.X + 0.08, 0.06, 0.1),
			CFrame.new(side * head.Size.X * 0.2, lensY + lensSize.Y / 2, frontZ),
			Color3.fromRGB(34, 32, 35),
			Enum.Material.Metal
		)
	end

	attachPart(
		character,
		"sunset_glasses",
		head,
		"Bridge",
		Vector3.new(head.Size.X * 0.12, 0.06, 0.1),
		CFrame.new(0, lensY, frontZ),
		Color3.fromRGB(34, 32, 35),
		Enum.Material.Metal
	)

	return true
end

local function applySneakers(character, color)
	for _, side in ipairs({ "Left", "Right" }) do
		local foot = getBodyPart(character, side .. "Foot", side .. " Leg")
		if not foot or not foot:IsA("BasePart") then
			return false, "Não foi possível encontrar os pés do avatar"
		end
	end

	for _, side in ipairs({ "Left", "Right" }) do
		local foot = getBodyPart(character, side .. "Foot", side .. " Leg")
		local shoeSize = Vector3.new(
			math.max(0.65, foot.Size.X * 1.08),
			math.max(0.25, math.min(0.45, foot.Size.Y * 0.55)),
			math.max(0.75, foot.Size.Z * 1.12)
		)
		local shoeOffset = CFrame.new(0, -foot.Size.Y * 0.36, -foot.Size.Z * 0.08)

		attachPart(
			character,
			"island_sneakers",
			foot,
			side .. "Sneaker",
			shoeSize,
			shoeOffset,
			color,
			Enum.Material.SmoothPlastic
		)
		attachPart(
			character,
			"island_sneakers",
			foot,
			side .. "Sole",
			Vector3.new(shoeSize.X * 1.04, 0.08, shoeSize.Z * 1.04),
			shoeOffset * CFrame.new(0, -shoeSize.Y / 2, 0),
			Color3.fromRGB(46, 47, 51),
			Enum.Material.Rubber
		)
	end

	return true
end

local function applyItem(character, itemId)
	local definition = ITEM_DEFINITIONS[itemId]
	if not definition then
		return false, "Item visual não encontrado"
	end

	if itemId == "elite_jacket" then
		return applyJacket(character, definition.Color)
	elseif itemId == "luxury_watch" then
		return applyWatch(character, definition.Color)
	elseif itemId == "sunset_glasses" then
		return applyGlasses(character, definition.Color)
	elseif itemId == "island_sneakers" then
		return applySneakers(character, definition.Color)
	end

	return false, "Item visual não suportado"
end

local function applyProfile(player, character)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return false, "Perfil do jogador ainda não foi carregado"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if not humanoid or not character.Parent then
		return false, "Avatar não ficou pronto para equipar os itens"
	end

	removeAllVisuals(character)
	for itemId, equipped in pairs(profile.equippedItems or {}) do
		if equipped == true and profile.inventory[itemId] then
			local success, reason = applyItem(character, itemId)
			if not success then
				Logger.Warn("Appearance", string.format("Não foi possível equipar %s: %s", itemId, reason))
			end
		end
	end

	return true
end

function AppearanceService.SetEquipped(player, itemId, shouldEquip)
	if typeof(itemId) ~= "string" or typeof(shouldEquip) ~= "boolean" then
		return false, "Solicitação de equipagem inválida"
	end

	local definition = ITEM_DEFINITIONS[itemId]
	if not definition then
		return false, "Item não encontrado"
	end

	local profile = EconomyService.GetProfile(player)
	if not profile then
		return false, "Perfil do jogador ainda não foi carregado"
	end
	if not profile.inventory[itemId] then
		return false, "Você não possui este item"
	end
	if shouldEquip and PlayerMarketService.IsItemListed(player, itemId) then
		return false, "Retire o anúncio do mercado antes de equipar este item"
	end

	local character = player.Character
	if not character then
		return false, "Personagem não encontrado"
	end

	if not shouldEquip then
		profile.equippedItems[itemId] = nil
		removeItemVisuals(character, itemId)
		return true, "Item removido"
	end

	if profile.equippedItems[itemId] then
		removeItemVisuals(character, itemId)
		return applyItem(character, itemId)
	end

	local success, reason = applyItem(character, itemId)
	if not success then
		return false, reason
	end

	for equippedId in pairs(profile.equippedItems) do
		local equippedDefinition = ITEM_DEFINITIONS[equippedId]
		if equippedDefinition and equippedDefinition.Slot == definition.Slot then
			profile.equippedItems[equippedId] = nil
			removeItemVisuals(character, equippedId)
		end
	end
	profile.equippedItems[itemId] = true
	return true, "Item equipado"
end

function AppearanceService.Init()
	local function applyWhenReady(player, character)
		task.spawn(function()
			local deadline = os.clock() + 30
			while player.Parent and os.clock() < deadline do
				if player.Character ~= character then
					return
				end
				if EconomyService.GetProfile(player) then
					local success, reason = applyProfile(player, character)
					if not success then
						Logger.Warn("Appearance", string.format("Falha no avatar de %s: %s", player.Name, reason))
					end
					return
				end
				task.wait(0.25)
			end
		end)
	end

	local function trackPlayer(player)
		local appearanceLoaded = {}
		player.CharacterAppearanceLoaded:Connect(function(character)
			appearanceLoaded[character] = true
			applyWhenReady(player, character)
		end)

		player.CharacterAdded:Connect(function(character)
			task.spawn(function()
				local deadline = os.clock() + 10
				while player.Parent and player.Character == character and not appearanceLoaded[character] do
					if os.clock() >= deadline then
						applyWhenReady(player, character)
						return
					end
					task.wait(0.25)
				end
			end)
		end)

		if player.Character then
			applyWhenReady(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(trackPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayer(player)
	end
end

return AppearanceService
