--!nonstrict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}
local profiles = {}
local writers = {}
local released = {}
local closing = false
local SESSION_SECONDS = 120
local sessionId = game.JobId .. ":" .. HttpService:GenerateGUID(false)

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
	DataVersion = 2,
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

local function migrate(stored)
	if type(stored) ~= "table" then
		return nil
	end
	-- Keep the v1 store and every existing field. Future versions migrate here.
	if type(stored.DataVersion) == "number" and stored.DataVersion > 2 then
		error("Profile uses a newer schema")
	end
	local data = reconcile(deepCopy(stored), DEFAULT_DATA)
	if type(data.ProcessedReceipts) ~= "table" then
		error("Invalid receipt history")
	end
	if type(data.DataVersion) ~= "number" or data.DataVersion < 2 then
		data.DataVersion = 2
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

local function beginWrite(userId)
	while writers[userId] do
		task.wait(0.05)
	end
	writers[userId] = true
end

local function endWrite(userId)
	writers[userId] = nil
end

local function isOurSession(old)
	return type(old) == "table" and type(old.Session) == "table" and old.Session.Id == sessionId
end

local function addReceipt(data, purchaseId)
	if not table.find(data.ProcessedReceipts, purchaseId) then
		table.insert(data.ProcessedReceipts, purchaseId)
	end
end

function DataService:Initialize(networkService)
	self.Store = DataStoreService:GetDataStore(Config.DataStoreName)
	self.DataUpdated = networkService:GetEvent("DataUpdated")

	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayer(player, true)
		profiles[player.UserId] = nil
		released[player.UserId] = nil
	end)

	game:BindToClose(function()
		closing = true
		local remaining = 0
		for _, player in Players:GetPlayers() do
			remaining += 1
			task.spawn(function()
				self:SavePlayer(player, true)
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
	local stored
	local acquired = false
	local errorMessage
	for attempt = 1, 4 do
		local success, result = retry(function()
			return self.Store:UpdateAsync(key, function(old)
				if old ~= nil and type(old) ~= "table" then
					error("Unexpected profile format")
				end
				if
					type(old) == "table"
					and type(old.Session) == "table"
					and old.Session.Id ~= sessionId
					and type(old.Session.ExpiresAt) == "number"
					and old.Session.ExpiresAt > os.time()
				then
					return nil
				end
				local data = migrate(old) or deepCopy(DEFAULT_DATA)
				data.Session = { Id = sessionId, ExpiresAt = os.time() + SESSION_SECONDS }
				return data
			end)
		end)
		if success and type(result) == "table" and isOurSession(result) then
			stored = result
			acquired = true
			break
		end
		errorMessage = if success then "Profile is open in another server" else tostring(result)
		if attempt < 4 then
			task.wait(attempt * 2)
		end
	end
	if not acquired then
		warn("Profile load failed for", player.UserId, errorMessage)
		if player.Parent == Players then
			player:Kick("Your data could not be loaded safely. Please rejoin in a moment.")
		end
		return nil
	end

	if player.Parent ~= Players then
		-- A player who left while loading must release the newly acquired lock.
		retry(function()
			return self.Store:UpdateAsync(key, function(old)
				if not isOurSession(old) then
					return nil
				end
				local data = deepCopy(old)
				data.Session = nil
				return data
			end)
		end)
		return nil
	end

	stored.Session = nil
	local data = migrate(stored)
	profiles[player.UserId] = data
	released[player.UserId] = nil

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

function DataService:SavePlayer(player, release)
	local userId = player.UserId
	if not profiles[userId] or released[userId] then
		return true
	end
	beginWrite(userId)
	local data = profiles[userId]
	if not data or released[userId] then
		endWrite(userId)
		return true
	end
	local snapshot = deepCopy(data)
	snapshot.Session = if release then nil else { Id = sessionId, ExpiresAt = os.time() + SESSION_SECONDS }
	local success, saved = retry(function()
		return self.Store:UpdateAsync("player_" .. userId, function(old)
			if not isOurSession(old) then
				return nil
			end
			-- Receipts committed since the snapshot must never be discarded.
			for _, id in old.ProcessedReceipts or {} do
				addReceipt(snapshot, id)
			end
			return snapshot
		end)
	end)
	if not success or saved == nil then
		endWrite(userId)
		warn("Data save failed or session lost for", userId, saved)
		if saved == nil and player.Parent == Players then
			player:Kick("Your data session expired. Please rejoin to protect your progress.")
		end
		return false
	end
	if release then
		released[userId] = true
	end
	endWrite(userId)
	return true
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
			if wins then
				wins.Value = public.Wins
			end
			if tokens then
				tokens.Value = public.Coins
			end
		end
		self.DataUpdated:FireClient(player, public)
	end
end

function DataService:AddCoins(player, amount, applyMultiplier)
	local data = profiles[player.UserId]
	if not data then
		return
	end
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

function DataService:RecordRound(player, survived, soloSurvivor, specialRound)
	local data = profiles[player.UserId]
	if not data then
		return
	end
	local roundMultiplier = if specialRound then 2 else 1
	data.RoundsPlayed += 1
	local firstWinToday = false
	if survived then
		data.Wins += 1
		data.CurrentWinStreak += 1
		data.BestWinStreak = math.max(data.BestWinStreak, data.CurrentWinStreak)
		self:AddCoins(
			player,
			(Config.Rewards.Survival + (if soloSurvivor then Config.Rewards.SoloSurvivorBonus else 0)) * roundMultiplier,
			true
		)
		local today = os.date("!%Y-%m-%d")
		if data.LastDailyWin ~= today then
			data.LastDailyWin = today
			firstWinToday = true
			self:AddCoins(player, Config.Rewards.FirstWinToday, true)
		end
	else
		data.CurrentWinStreak = 0
	end
	self:AddCoins(player, Config.Rewards.Participation * roundMultiplier, true)
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
	local userId = player.UserId
	if not profiles[userId] then
		return false
	end
	beginWrite(userId)
	local data = profiles[userId]
	if not data then
		endWrite(userId)
		return false
	end
	local snapshot = deepCopy(data)
	local alreadyProcessed = false
	local success, saved = retry(function()
		return self.Store:UpdateAsync("player_" .. userId, function(old)
			if not isOurSession(old) then
				return nil
			end
			if table.find(old.ProcessedReceipts or {}, purchaseId) then
				alreadyProcessed = true
				return old
			end
			alreadyProcessed = false
			local nextData = deepCopy(snapshot)
			for _, id in old.ProcessedReceipts or {} do
				addReceipt(nextData, id)
			end
			if grantKind == "Coins" then
				nextData.Coins += amount
			elseif grantKind == "Revive" then
				nextData.ReviveCredits += amount
			else
				error("Unknown receipt grant kind")
			end
			addReceipt(nextData, purchaseId)
			nextData.Session = { Id = sessionId, ExpiresAt = os.time() + SESSION_SECONDS }
			return nextData
		end)
	end)
	if success and type(saved) == "table" then
		if not table.find(data.ProcessedReceipts, purchaseId) then
			if not alreadyProcessed then
				if grantKind == "Coins" then
					data.Coins += amount
				else
					data.ReviveCredits += amount
				end
			end
			addReceipt(data, purchaseId)
		end
		self:Push(player)
	end
	endWrite(userId)
	if success and type(saved) == "table" then
		return true, not alreadyProcessed
	end
	warn("Receipt could not be persisted", purchaseId, saved)
	return false
end

return DataService
