local EconomyService = require(script.Parent.EconomyService)
local AchievementService = require(script.Parent.AchievementService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local catalog = require(ReplicatedStorage:WaitForChild("HSC"):WaitForChild("FashionCatalog"))

local ShopService = {}

local stores = {
	fashion_avenue = {
		Id = "fashion_avenue",
		Name = "Fashion Avenue",
		DistrictName = "HighSocietyBoulevard",
		ModelName = "FashionAvenueStore",
		PointName = "ShopPoint",
		PromptName = "ShopPrompt",
	},
}

local function findItem(itemId)
	for _, item in ipairs(catalog) do
		if item.Id == itemId then
			return item
		end
	end

	return nil
end

local function copyPublicItem(item)
	return {
		Id = item.Id,
		Name = item.Name,
		Category = item.Category,
		Price = item.Price,
		AssetType = item.AssetType,
		StoreId = item.StoreId,
	}
end

function ShopService.GetStoreDefinition(storeId)
	local store = stores[storeId]
	if not store then
		return nil
	end

	return {
		Id = store.Id,
		Name = store.Name,
		DistrictName = store.DistrictName,
		ModelName = store.ModelName,
		PointName = store.PointName,
		PromptName = store.PromptName,
	}
end

function ShopService.GetCatalog(storeId)
	if storeId ~= nil and (type(storeId) ~= "string" or not stores[storeId]) then
		return nil, "Loja não encontrada"
	end

	local items = {}
	for _, item in ipairs(catalog) do
		if storeId == nil or item.StoreId == storeId then
			table.insert(items, copyPublicItem(item))
		end
	end

	table.sort(items, function(left, right)
		if left.Category == right.Category then
			return left.Name < right.Name
		end
		return left.Category < right.Category
	end)
	return items
end

function ShopService.GetOwnedItems(player)
	local profile = EconomyService.GetProfile(player)
	if not profile then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	local items = {}
	for itemId, ownedItem in pairs(profile.inventory or {}) do
		if type(itemId) == "string" then
			local item = findItem(itemId)
			local savedName = type(ownedItem) == "table" and ownedItem.Name
			local savedCategory = type(ownedItem) == "table" and ownedItem.Category
			table.insert(items, {
				Id = itemId,
				Name = item and item.Name or (type(savedName) == "string" and savedName) or itemId,
				Category = item and item.Category or (type(savedCategory) == "string" and savedCategory) or "Item",
				Equipped = profile.equippedItems and profile.equippedItems[itemId] == true or false,
				CanEquip = item ~= nil,
			})
		end
	end

	table.sort(items, function(left, right)
		return left.Name < right.Name
	end)

	return items
end

function ShopService.PurchaseItem(player, itemId, storeId)
	if typeof(itemId) ~= "string" then
		return false, "Identificador de item inválido"
	end
	if typeof(storeId) ~= "string" or not stores[storeId] then
		return false, "Loja não encontrada"
	end

	local item = findItem(itemId)
	if not item then
		return false, "Item não encontrado"
	end
	if item.StoreId ~= storeId then
		return false, "Este item não pertence a esta loja"
	end

	local profile = EconomyService.GetProfile(player)
	if not profile then
		return false, "Perfil do jogador ainda não foi carregado"
	end

	profile.inventory = profile.inventory or {}
	if profile.inventory[item.Id] then
		return false, "Você já possui este item"
	end

	local paid, reason = EconomyService.SpendCredits(player, item.Price, {
		Type = "Purchase",
		ItemId = item.Id,
	})
	if not paid then
		return false, reason
	end

	profile.inventory[item.Id] = {
		Name = item.Name,
		Category = item.Category,
		BoughtAt = os.time(),
	}

	if storeId == "fashion_avenue" then
		AchievementService.RecordMilestone(player, "FashionPurchased")
	end

	return true, copyPublicItem(item)
end

return ShopService
