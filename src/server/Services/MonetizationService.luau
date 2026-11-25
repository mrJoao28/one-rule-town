--!nonstrict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MonetizationService = {}

function MonetizationService:Initialize(networkService, dataService, roundService)
	self.DataService = dataService
	self.RoundService = roundService
	self.Cooldowns = {}
	self.ProductById = {}

	for key, product in pairs(Config.Monetization.DeveloperProducts) do
		if product.Id > 0 then
			self.ProductById[product.Id] = {
				Key = key,
				GrantKind = if key == "Revive" then "Revive" else "Coins",
				Amount = product.Amount,
			}
		end
	end

	networkService:GetEvent("PurchaseRequest").OnServerEvent:Connect(function(player, category, key)
		if type(category) ~= "string" or type(key) ~= "string" then return end
		local last = self.Cooldowns[player] or 0
		if os.clock() - last < 1 then return end
		self.Cooldowns[player] = os.clock()

		if category == "Product" then
			local product = Config.Monetization.DeveloperProducts[key]
			if product and product.Id > 0 then
				MarketplaceService:PromptProductPurchase(player, product.Id)
			end
		elseif category == "Pass" then
			local passId = Config.Monetization.GamePasses[key]
			if type(passId) == "number" and passId > 0 then
				if player:GetAttribute(key) then return end
				local success, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
				if not success then return end
				if owns then
					player:SetAttribute(key, true)
					return
				end
				MarketplaceService:PromptGamePassPurchase(player, passId)
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		local product = self.ProductById[receiptInfo.ProductId]
		if not player or not product then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local granted = self.DataService:ProcessReceipt(player, tostring(receiptInfo.PurchaseId), product.GrantKind, product.Amount)
		if granted then
			if product.GrantKind == "Revive" then
				task.defer(function() self.RoundService:TryRevive(player) end)
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if wasPurchased then self:RefreshPasses(player, passId) end
	end)
end

function MonetizationService:RefreshPasses(player, onlyPassId)
	for key, passId in pairs(Config.Monetization.GamePasses) do
		if passId > 0 and (not onlyPassId or passId == onlyPassId) then
			local success, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
			if success and owns then player:SetAttribute(key, true) end
		end
	end
end

return MonetizationService

