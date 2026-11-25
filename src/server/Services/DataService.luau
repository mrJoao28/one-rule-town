--!nonstrict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}
local profiles = {}
local closing = false

local DEFAULT_DATA = {
	Coins = 0,
	Wins = 0,
	RoundsPlayed = 0,
	BestWinStreak = 0,
	CurrentWinStreak = 0,
	LastDailyWin = "",
	ReviveCredits = 0,
	OwnedCosmetics = { Default = true },
	EquippedCosmetic = "Default",
	ProcessedReceipts = {},
	DataVersion = 1,
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = deepCopy(child)
	end
	return copy
end

local function reconcile(data, template)
	for key, defaultValue in pairs(template) do
		if data[key] == nil then
			data[key] = deepCopy(defaultValue)
		elseif type(defaultValue) == "table" and type(data[key]) == "table" then
			reconcile(data[key], defaultValue)
		end
	end
	return data
end

local function retry(callback)
	local lastError
	for attempt = 1, 4 do
		local success, result = pcall(callback)
		if success then
			return true, result
		end
		lastError = result
		if attempt < 4 then
			task.wait(math.min(8, 2 ^ (attempt - 1)) + math.random())
		end
	end
	return false, lastError
end

function DataService:Initialize(networkService)
	self.Store = DataStoreService:GetDataStore(Config.DataStoreName)
	self.DataUpdated = networkService:GetEvent("DataUpdated")

	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayer(player)
		profiles[player.UserId] = nil
	end)

	game:BindToClose(function()
		closing = true
		local remaining = 0
		for _, player in Players:GetPlayers() do
			remaining += 1
			task.spawn(function()
				self:SavePlayer(player)
				remaining -= 1
			end)
		end
		local started = os.clock()
		while remaining > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while not closing do
			task.wait(Config.AutoSaveInterval)
			for _, player in Players:GetPlayers() do
				task.spawn(function()
					self:SavePlayer(player)
				end)
			end
		end
	end)
end

function DataService:LoadPlayer(player)
	local key = "player_" .. player.UserId
	local success, stored = retry(function()
		return self.Store:GetAsync(key)
	end)

	local data = deepCopy(DEFAULT_DATA)
	if success and type(stored) == "table" then
		data = reconcile(stored, DEFAULT_DATA)
	elseif not success then
		warn("Data load failed for", player.Name, stored, "Using temporary defaults.")
	end
	profiles[player.UserId] = data

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = data.Wins
	wins.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "Tokens"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	self:Push(player)
	return data
end

function DataService:SavePlayer(player)
	local data = profiles[player.UserId]
	if not data then
		return true
	end
	local snapshot = deepCopy(data)
	local key = "player_" .. player.UserId
	local success, result = retry(function()
		return self.Store:UpdateAsync(key, function()
			return snapshot
		end)
	end)
	if not success then
		warn("Data save failed for", player.Name, result)
	end
	return success
end

function DataService:Get(player)
	return profiles[player.UserId]
end

function DataService:GetPublic(player)
	local data = profiles[player.UserId]
	if not data then
		return nil
	end
	return {
		Coins = data.Coins,
		Wins = data.Wins,
		RoundsPlayed = data.RoundsPlayed,
		BestWinStreak = data.BestWinStreak,
		CurrentWinStreak = data.CurrentWinStreak,
		ReviveCredits = data.ReviveCredits,
		OwnedCosmetics = deepCopy(data.OwnedCosmetics),
		EquippedCosmetic = data.EquippedCosmetic,
	}
end

function DataService:Push(player)
	local public = self:GetPublic(player)
	if public and player.Parent then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local wins = leaderstats:FindFirstChild("Wins")
			local tokens = leaderstats:FindFirstChild("Tokens")
			if wins then wins.Value = public.Wins end
			if tokens then tokens.Value = public.Coins end
		end
		self.DataUpdated:FireClient(player, public)
	end
end

function DataService:AddCoins(player, amount, applyMultiplier)
	local data = profiles[player.UserId]
	if not data then return end
	local finalAmount = amount
	if applyMultiplier and player:GetAttribute("DoubleTokens") then
		finalAmount *= 2
	end
	data.Coins = math.max(0, data.Coins + math.floor(finalAmount))
	self:Push(player)
end

function DataService:SpendCoins(player, amount)
	local data = profiles[player.UserId]
	if not data or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	self:Push(player)
	return true
end

function DataService:RecordRound(player, survived, soloSurvivor)
	local data = profiles[player.UserId]
	if not data then return end
	data.RoundsPlayed += 1
	local firstWinToday = false
	if survived then
		data.Wins += 1
		data.CurrentWinStreak += 1
		data.BestWinStreak = math.max(data.BestWinStreak, data.CurrentWinStreak)
		self:AddCoins(player, Config.Rewards.Survival + (if soloSurvivor then Config.Rewards.SoloSurvivorBonus else 0), true)
		local today = os.date("!%Y-%m-%d")
		if data.LastDailyWin ~= today then
			data.LastDailyWin = today
			firstWinToday = true
			self:AddCoins(player, Config.Rewards.FirstWinToday, true)
		end
	else
		data.CurrentWinStreak = 0
	end
	self:AddCoins(player, Config.Rewards.Participation, true)
	self:Push(player)
	return firstWinToday
end

function DataService:BuyCosmetic(player, cosmeticId, price)
	local data = profiles[player.UserId]
	if not data or data.OwnedCosmetics[cosmeticId] then
		return data ~= nil
	end
	if not self:SpendCoins(player, price) then
		return false
	end
	data.OwnedCosmetics[cosmeticId] = true
	self:Push(player)
	return true
end

function DataService:EquipCosmetic(player, cosmeticId)
	local data = profiles[player.UserId]
	if not data or not data.OwnedCosmetics[cosmeticId] then
		return false
	end
	data.EquippedCosmetic = cosmeticId
	self:Push(player)
	return true
end

function DataService:ConsumeRevive(player)
	local data = profiles[player.UserId]
	if not data or data.ReviveCredits <= 0 then
		return false
	end
	data.ReviveCredits -= 1
	self:Push(player)
	return true
end

function DataService:ProcessReceipt(player, purchaseId, grantKind, amount)
	local key = "player_" .. player.UserId
	local sessionSnapshot = deepCopy(profiles[player.UserId] or DEFAULT_DATA)
	local success, saved = retry(function()
		return self.Store:UpdateAsync(key, function(old)
			local storedData = reconcile(type(old) == "table" and old or deepCopy(DEFAULT_DATA), DEFAULT_DATA)
			for _, processedId in storedData.ProcessedReceipts do
				if processedId == purchaseId then
					return storedData
				end
			end
			local data = reconcile(deepCopy(sessionSnapshot), DEFAULT_DATA)
			for _, processedId in storedData.ProcessedReceipts do
				if not table.find(data.ProcessedReceipts, processedId) then
					table.insert(data.ProcessedReceipts, processedId)
				end
			end

			if grantKind == "Coins" then
				data.Coins += amount
			elseif grantKind == "Revive" then
				data.ReviveCredits += amount
			else
				error("Unknown receipt grant kind")
			end

			table.insert(data.ProcessedReceipts, purchaseId)
			while #data.ProcessedReceipts > 50 do
				table.remove(data.ProcessedReceipts, 1)
			end
			return data
		end)
	end)

	if success and type(saved) == "table" then
		profiles[player.UserId] = reconcile(saved, DEFAULT_DATA)
		self:Push(player)
		return true
	end
	warn("Receipt could not be persisted", purchaseId, saved)
	return false
end

return DataService
