local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("HSC")
local Config = require(Shared:WaitForChild("Config"))
local catalog = require(Shared:WaitForChild("FashionCatalog"))
local EconomyService = require(script.Parent.EconomyService)
local RateLimitService = require(script.Parent.RateLimitService)
local ShopService = require(script.Parent.ShopService)

local PlayerMarketService = {}

local marketConfig = Config.Market
local catalogById = {}
local listings = {}
local nextListingId = 0

for _, item in ipairs(catalog) do
	catalogById[item.Id] = item
end

local function removeListing(listingId)
	listings[listingId] = nil
end

local function pruneExpiredListings()
	local now = os.time()
	for listingId, listing in pairs(listings) do
		if listing.ExpiresAt <= now then
			removeListing(listingId)
		end
	end
end

local function countListingsFor(userId)
	local count = 0
	for _, listing in pairs(listings) do
		if listing.SellerUserId == userId then
			count += 1
		end
	end
	return count
end

local function getLivingRoot(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return root
end

local function arePlayersClose(firstPlayer, secondPlayer)
	if firstPlayer.Parent ~= Players or secondPlayer.Parent ~= Players then
		return false
	end
	local firstRoot = getLivingRoot(firstPlayer)
	local secondRoot = getLivingRoot(secondPlayer)
	return firstRoot ~= nil
		and secondRoot ~= nil
		and (firstRoot.Position - secondRoot.Position).Magnitude <= marketConfig.TransferDistance
end

local function findListing(listingId)
	if type(listingId) ~= "number" or listingId % 1 ~= 0 or listingId < 1 then
		return nil
	end
	return listings[listingId]
end

local function validateActionCooldown(player)
	return RateLimitService.Allow(
		player,
		"market.action",
		Config.RateLimits.MarketActionCooldown
	)
end

function PlayerMarketService.IsItemListed(player, itemId)
	pruneExpiredListings()
	for _, listing in pairs(listings) do
		if listing.SellerUserId == player.UserId and listing.ItemId == itemId then
			return true
		end
	end
	return false
end

function PlayerMarketService.GetMarketData(player)
	if not RateLimitService.Allow(player, "market.query", Config.RateLimits.MarketQueryCooldown) then
		return nil, "Aguarde antes de atualizar o mercado"
	end
	if not EconomyService.GetProfile(player) then
		return nil, "Perfil do jogador ainda não foi carregado"
	end

	pruneExpiredListings()
	local ownedItems, ownedError = ShopService.GetOwnedItems(player)
	if not ownedItems then
		return nil, ownedError
	end

	local items = {}
	for _, item in ipairs(ownedItems) do
		if catalogById[item.Id] then
			local isListed = PlayerMarketService.IsItemListed(player, item.Id)
			table.insert(items, {
				Id = item.Id,
				Name = item.Name,
				Category = item.Category,
				Equipped = item.Equipped,
				Sellable = item.CanEquip and not item.Equipped and not isListed,
				IsListed = isListed,
			})
		end
	end

	local publicListings = {}
	for _, listing in pairs(listings) do
		local seller = Players:GetPlayerByUserId(listing.SellerUserId)
		if seller then
			table.insert(publicListings, {
				Id = listing.Id,
				ItemId = listing.ItemId,
				ItemName = listing.ItemName,
				Category = listing.Category,
				Price = listing.Price,
				SellerUserId = listing.SellerUserId,
				SellerName = seller.DisplayName,
				ExpiresAt = listing.ExpiresAt,
			})
		end
	end
	table.sort(publicListings, function(left, right)
		return left.Id > right.Id
	end)

	return {
		Items = items,
		Listings = publicListings,
		MaxPrice = marketConfig.MaxListingPrice,
		MaxDonation = marketConfig.MaxDonation,
		CommissionPercent = marketConfig.SaleCommissionPercent,
		MaxListingsPerPlayer = marketConfig.MaxListingsPerPlayer,
		TransferDistance = marketConfig.TransferDistance,
	}
end

local function createListing(player, itemId, price)
	if type(itemId) ~= "string" or #itemId > 40 then
		return false, "Item inválido"
	end
	if
		type(price) ~= "number"
		or price ~= price
		or price == math.huge
		or price == -math.huge
		or price % 1 ~= 0
		or price < 0
		or price > marketConfig.MaxListingPrice
	then
		return false, "Preço inválido"
	end

	local item = catalogById[itemId]
	local profile = EconomyService.GetProfile(player)
	if not item or not profile then
		return false, "Item não encontrado ou perfil ainda não carregado"
	end
	if not profile.inventory[itemId] then
		return false, "Você não possui este item"
	end
	if profile.equippedItems and profile.equippedItems[itemId] then
		return false, "Desequipe o item antes de anunciá-lo"
	end
	if PlayerMarketService.IsItemListed(player, itemId) then
		return false, "Este item já está anunciado"
	end
	if countListingsFor(player.UserId) >= marketConfig.MaxListingsPerPlayer then
		return false, "Você atingiu o limite de anúncios ativos"
	end
	local listingCount = 0
	for _ in pairs(listings) do
		listingCount += 1
	end
	if listingCount >= marketConfig.MaxActiveListings then
		return false, "O mercado está cheio; tente novamente mais tarde"
	end

	nextListingId += 1
	local now = os.time()
	listings[nextListingId] = {
		Id = nextListingId,
		ItemId = itemId,
		ItemName = item.Name,
		Category = item.Category,
		Price = price,
		SellerUserId = player.UserId,
		CreatedAt = now,
		ExpiresAt = now + marketConfig.ListingDuration,
	}
	local commission = math.floor(price * marketConfig.SaleCommissionPercent / 100)
	return true, {
		Message = if price == 0
			then "Item anunciado como presente; presentes não têm comissão"
			else string.format(
				"Item anunciado. Em uma venda, você recebe %d créditos; comissão: %d",
				price - commission,
				commission
			),
	}
end

local function cancelListing(player, listingId)
	pruneExpiredListings()
	local listing = findListing(listingId)
	if not listing or listing.SellerUserId ~= player.UserId then
		return false, "Anúncio não encontrado ou não pertence a você"
	end
	removeListing(listing.Id)
	return true, {
		Message = "Anúncio cancelado",
	}
end

local function buyListing(player, listingId)
	pruneExpiredListings()
	local listing = findListing(listingId)
	if not listing then
		return false, "Este anúncio expirou ou não está mais disponível"
	end
	if listing.SellerUserId == player.UserId then
		return false, "Você não pode comprar seu próprio anúncio"
	end

	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	if not seller or not arePlayersClose(player, seller) then
		return false, "Aproxime-se do vendedor para concluir a troca"
	end

	local sellerProfile = EconomyService.GetProfile(seller)
	local buyerProfile = EconomyService.GetProfile(player)
	local item = catalogById[listing.ItemId]
	if not sellerProfile or not buyerProfile or not item then
		return false, "Os dados da troca não estão disponíveis"
	end
	if not sellerProfile.inventory[listing.ItemId] then
		removeListing(listing.Id)
		return false, "O vendedor não possui mais este item; anúncio removido"
	end
	if sellerProfile.equippedItems and sellerProfile.equippedItems[listing.ItemId] then
		return false, "O vendedor precisa desequipar este item antes da venda"
	end
	if buyerProfile.inventory[listing.ItemId] then
		return false, "Você já possui este item"
	end

	local isGift = listing.Price == 0
	local commission = isGift and 0 or math.floor(listing.Price * marketConfig.SaleCommissionPercent / 100)
	local transferred, transferError = EconomyService.TransferCreditsWithFee(player, seller, listing.Price, commission, {
		ItemId = listing.ItemId,
		SenderType = isGift and "PlayerGiftReceived" or "MarketPurchase",
		RecipientType = isGift and "PlayerGiftSent" or "MarketSaleReceived",
		FeeType = "MarketCommissionPaid",
	})
	if not transferred then
		return false, transferError
	end

	sellerProfile.inventory[listing.ItemId] = nil
	sellerProfile.equippedItems[listing.ItemId] = nil
	buyerProfile.inventory[listing.ItemId] = {
		Name = item.Name,
		Category = item.Category,
		BoughtAt = os.time(),
	}
	removeListing(listing.Id)

	return true, {
		Message = isGift and ("Presente recebido: " .. item.Name) or ("Compra concluída: " .. item.Name),
		RecipientUserId = seller.UserId,
		RecipientMessage = isGift and (player.DisplayName .. " recebeu seu presente") or (player.DisplayName .. " comprou " .. item.Name),
	}
end

local function donateCredits(player, targetUserId, amount)
	if
		type(targetUserId) ~= "number"
		or targetUserId % 1 ~= 0
		or targetUserId < 1
		or type(amount) ~= "number"
		or amount ~= amount
		or amount == math.huge
		or amount == -math.huge
		or amount % 1 ~= 0
		or amount < 1
		or amount > marketConfig.MaxDonation
	then
		return false, "Jogador ou quantidade de créditos inválidos"
	end

	local recipient = Players:GetPlayerByUserId(targetUserId)
	if not recipient or recipient == player then
		return false, "Escolha outro jogador que esteja nesta sessão"
	end
	if not arePlayersClose(player, recipient) then
		return false, "Aproxime-se do jogador para fazer a doação"
	end

	local transferred, transferError = EconomyService.TransferCredits(player, recipient, amount, {
		SenderType = "PlayerDonationSent",
		RecipientType = "PlayerDonationReceived",
	})
	if not transferred then
		return false, transferError
	end

	return true, {
		Message = string.format("Doação de %d Society Credits enviada para %s", amount, recipient.DisplayName),
		RecipientUserId = recipient.UserId,
		RecipientMessage = string.format("%s doou %d Society Credits para você", player.DisplayName, amount),
	}
end

function PlayerMarketService.HandleRequest(player, action, firstArgument, secondArgument)
	if not validateActionCooldown(player) then
		return false, "Aguarde antes de enviar outra ação ao mercado"
	end

	if action == "ListItem" then
		return createListing(player, firstArgument, secondArgument)
	elseif action == "CancelListing" then
		return cancelListing(player, firstArgument)
	elseif action == "BuyListing" then
		return buyListing(player, firstArgument)
	elseif action == "DonateCredits" then
		return donateCredits(player, firstArgument, secondArgument)
	end

	return false, "Ação de mercado inválida"
end

function PlayerMarketService.CleanupPlayer(player)
	for listingId, listing in pairs(listings) do
		if listing.SellerUserId == player.UserId then
			removeListing(listingId)
		end
	end
end

return PlayerMarketService
