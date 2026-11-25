--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RuleCatalog = require(ReplicatedStorage.Shared.RuleCatalog)
local MapCatalog = require(ReplicatedStorage.Shared.MapCatalog)
local RoundEventService = require(script.Parent.RoundEventService)

local RoundService = {}

local function rootOf(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart") and root or nil
end

local function humanoidOf(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

function RoundService:Initialize(networkService, mapService, ruleService, dataService, crowdService)
	self.Network = networkService
	self.MapService = mapService
	self.RuleService = ruleService
	self.DataService = dataService
	self.CrowdService = crowdService
	self.RoundEvent = RoundEventService
	self.GameState = networkService:GetEvent("GameState")
	self.PlayerState = networkService:GetEvent("PlayerState")
	self.UseRevive = networkService:GetEvent("UseRevive")
	self.VoteMap = networkService:GetEvent("VoteMap")
	self.State = "Booting"
	self.TimeLeft = 0
	self.CurrentRuleId = nil
	self.Alive = {}
	self.Participants = {}
	self.Hunters = {}
	self.HunterActiveAt = {}
	self.Reviving = setmetatable({}, { __mode = "k" })
	self.RoundNumber = 0
	self.SpecialRound = false
	self.RoundStartedWith = 0
	self.ReviveCooldown = setmetatable({}, { __mode = "k" })
	self.VoteCooldown = setmetatable({}, { __mode = "k" })
	self.MapVotes = {}
	self.VotingOpen = false

	self.UseRevive.OnServerEvent:Connect(function(player)
		local now = os.clock()
		if now - (self.ReviveCooldown[player] or -math.huge) < 0.5 then return end
		self.ReviveCooldown[player] = now
		self:TryRevive(player)
	end)
	self.VoteMap.OnServerEvent:Connect(function(player, mapId)
		if not self.VotingOpen or self.State ~= "Intermission" or not self.DataService:Get(player) then return end
		if type(mapId) ~= "number" or mapId % 1 ~= 0 or not MapCatalog[mapId] then return end
		local now = os.clock()
		if now - (self.VoteCooldown[player] or -math.huge) < 0.4 then return end
		self.VoteCooldown[player] = now
		self.MapVotes[player] = mapId
		self:BroadcastVotes()
	end)
	Players.PlayerRemoving:Connect(function(player)
		if self.MapVotes[player] then
			self.MapVotes[player] = nil
			self:BroadcastVotes()
		end
		self.Hunters[player] = nil
		self.HunterActiveAt[player] = nil
	end)
end

function RoundService:GetVotingState(player)
	if not self.VotingOpen then return nil end
	local counts = {}
	for id in MapCatalog do counts[id] = 0 end
	for voter, id in pairs(self.MapVotes) do
		if voter.Parent == Players then counts[id] += 1 end
	end
	return { Counts = counts, OwnVote = player and self.MapVotes[player] or nil }
end

function RoundService:BroadcastVotes()
	local state = self:GetVotingState()
	if state then self.GameState:FireAllClients({ Type = "MapVote", Counts = state.Counts }) end
end

function RoundService:ChooseMap()
	local counts = self:GetVotingState().Counts
	local best = 0
	local tied = {}
	for id, count in counts do
		if count > best then
			best = count
			tied = { id }
		elseif count == best and best > 0 then
			table.insert(tied, id)
		end
	end
	if best == 0 then
		for id in MapCatalog do
			if id ~= self.MapService.LayoutId then table.insert(tied, id) end
		end
	end
	return tied[math.random(1, #tied)]
end

function RoundService:OnPlayerAdded(player)
	player:SetAttribute("AliveInRound", false)
	player:SetAttribute("TownHunter", false)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				if self.State == "Active" and self.Alive[player] then
					self:Eliminate(player, "You were knocked out.")
				end
			end)
		end
		task.wait(0.15)
		if self.State == "Active" and self.Alive[player] then
			self:TeleportPlayer(player, self.MapService:GetRoundSpawn(math.random(1, #self.MapService.RoundSpawns)))
		elseif self.State == "Active" and self.Hunters[player] then
			self:TeleportPlayer(player, self.MapService.HunterPosition)
			self:ApplyHunterVisual(player)
		elseif self.State == "Active" then
			self:TeleportPlayer(player, self.MapService.SpectatorPosition)
		else
			self:TeleportPlayer(player, self.MapService.LobbyPosition)
		end
	end)
	if player.Character then
		self:TeleportPlayer(player, self.MapService.LobbyPosition)
	end
end

function RoundService:ApplyHunterVisual(player)
	local character = player.Character
	if not character then return end
	local previous = character:FindFirstChild("ORT_Hunter")
	if previous then previous:Destroy() end
	if not self.Hunters[player] then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ORT_Hunter"
	highlight.FillColor = Color3.fromRGB(232, 65, 83)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(255, 222, 85)
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character
end

function RoundService:SpawnHunter(player)
	if player.Parent ~= Players or not self.Hunters[player] or self.State ~= "Active" or self.Reviving[player] then return end
	local humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 then
		local success, err = pcall(function() player:LoadCharacterAsync() end)
		if not success then warn("Could not spawn hunter", player.UserId, err) end
	else
		humanoid.PlatformStand = false
		self:TeleportPlayer(player, self.MapService.HunterPosition)
		self:ApplyHunterVisual(player)
	end
end

function RoundService:CheckHunters()
	local now = os.clock()
	for hunter in pairs(self.Hunters) do
		local hunterRoot = hunter.Parent == Players and rootOf(hunter)
		local hunterHumanoid = humanoidOf(hunter)
		if hunterRoot and hunterHumanoid and hunterHumanoid.Health > 0
			and now >= (self.HunterActiveAt[hunter] or math.huge) then
			for _, target in self:GetAlivePlayers() do
				local targetRoot = rootOf(target)
				local targetHumanoid = humanoidOf(target)
				if targetRoot and targetHumanoid and targetHumanoid.Health > 0
					and math.abs(targetRoot.Position.Y - hunterRoot.Position.Y) < 6
					and (targetRoot.Position - hunterRoot.Position).Magnitude < 5 then
					self:Eliminate(target, "A town hunter caught you.")
					self.DataService:AddCoins(hunter, 3, true)
					self.PlayerState:FireAllClients({ Type = "HunterTag", Name = hunter.DisplayName, Target = target.DisplayName })
				end
			end
		end
	end
end

function RoundService:TeleportPlayer(player, position)
	local root = rootOf(player)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.new(position)
	end
end

function RoundService:GetAlivePlayers()
	local result = {}
	for player, alive in pairs(self.Alive) do
		if alive and player.Parent == Players then
			table.insert(result, player)
		end
	end
	return result
end

function RoundService:IsAlive(player)
	return self.Alive[player] == true
end

function RoundService:GetSnapshot(player)
	return {
		State = self.State,
		TimeLeft = self.TimeLeft,
		RuleId = self.CurrentRuleId,
		AliveCount = #self:GetAlivePlayers(),
		IsAlive = self:IsAlive(player),
		IsHunter = self.Hunters[player] == true,
		SpecialRound = self.SpecialRound,
		CanRevive = self:CanRevive(player),
		RoundNumber = self.RoundNumber,
		MapName = self.MapService.MapName,
		Voting = self:GetVotingState(player),
		Data = self.DataService:GetPublic(player),
	}
end

function RoundService:BroadcastState(extra)
	local payload = {
		Type = "State",
		State = self.State,
		TimeLeft = self.TimeLeft,
		RuleId = self.CurrentRuleId,
		Rule = self.CurrentRuleId and RuleCatalog[self.CurrentRuleId] or nil,
		AliveCount = #self:GetAlivePlayers(),
		RoundNumber = self.RoundNumber,
		MapName = self.MapService.MapName,
		SpecialRound = self.SpecialRound,
	}
	for key, value in pairs(extra or {}) do payload[key] = value end
	self.GameState:FireAllClients(payload)
end

function RoundService:BroadcastEffect(effectName, data)
	self.GameState:FireAllClients({ Type = "Effect", Effect = effectName, Data = data })
end

function RoundService:SetState(state, duration, extra)
	self.State = state
	self.TimeLeft = duration or 0
	self:BroadcastState(extra)
end

function RoundService:RunTimer(duration, breakCondition)
	local finishAt = os.clock() + duration
	local previousSecond = -1
	while os.clock() < finishAt do
		self.TimeLeft = math.max(0, math.ceil(finishAt - os.clock()))
		if self.TimeLeft ~= previousSecond then
			previousSecond = self.TimeLeft
			self:BroadcastState()
		end
		if breakCondition and breakCondition() then break end
		task.wait(0.1)
	end
	self.TimeLeft = 0
end

function RoundService:PreparePlayer(player, spawnIndex)
	local humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 then
		local success, err = pcall(function() player:LoadCharacterAsync() end)
		if not success then warn("Could not load character", player.Name, err) end
		humanoid = humanoidOf(player)
	end
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		humanoid.PlatformStand = false
	end
	self:TeleportPlayer(player, self.MapService:GetRoundSpawn(spawnIndex))
end

function RoundService:Eliminate(player, reason)
	if not self.Alive[player] then return end
	self.Alive[player] = false
	self.Hunters[player] = true
	self.HunterActiveAt[player] = os.clock() + 4.2
	player:SetAttribute("AliveInRound", false)
	player:SetAttribute("TownHunter", true)
	self.PlayerState:FireAllClients({
		Type = "Eliminated",
		UserId = player.UserId,
		Name = player.DisplayName,
		Reason = reason,
		AliveCount = #self:GetAlivePlayers(),
	})

	local root = rootOf(player)
	local humanoid = humanoidOf(player)
	if humanoid then humanoid.PlatformStand = true end
	if root then
		root.AssemblyLinearVelocity = Vector3.new(math.random(-25, 25), 45, math.random(-25, 25))
		root.AssemblyAngularVelocity = Vector3.new(5, 8, 5)
	end
	task.delay(1.2, function()
		self:SpawnHunter(player)
	end)
end

function RoundService:CanRevive(player)
	return self.State == "Active"
		and self.Participants[player] == true
		and not self.Alive[player]
		and self.TimeLeft > Config.ReviveCutoffSeconds
end

function RoundService:TryRevive(player)
	if not self:CanRevive(player) or self.Reviving[player] then return false end
	self.Reviving[player] = true
	local humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 then
		local success, err = pcall(function() player:LoadCharacterAsync() end)
		if not success then
			warn("Could not load revived character", player.UserId, err)
			self.Reviving[player] = nil
			task.defer(function() self:SpawnHunter(player) end)
			return false
		end
	end
	humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 then
		self.Reviving[player] = nil
		task.defer(function() self:SpawnHunter(player) end)
		return false
	end
	if not self:CanRevive(player) or not self.DataService:ConsumeRevive(player) then
		self.Reviving[player] = nil
		return false
	end
	self.Hunters[player] = nil
	self.HunterActiveAt[player] = nil
	player:SetAttribute("TownHunter", false)
	self:ApplyHunterVisual(player)
	self.Alive[player] = true
	player:SetAttribute("AliveInRound", true)
	humanoid = humanoidOf(player)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Health = humanoid.MaxHealth
	end
	self:TeleportPlayer(player, self.MapService:GetRoundSpawn(math.random(1, #self.MapService.RoundSpawns)))
	self.PlayerState:FireAllClients({ Type = "Revived", UserId = player.UserId, Name = player.DisplayName })
	self.Reviving[player] = nil
	return true
end

function RoundService:Start()
	task.spawn(function()
		while true do
			while #Players:GetPlayers() < Config.MinimumPlayers do
				self:SetState("WaitingForPlayers", 0)
				task.wait(1)
			end

			self.CurrentRuleId = nil
			self.SpecialRound = false
			self.MapVotes = {}
			self.VotingOpen = true
			local intermissionDuration = if self.RoundNumber == 0 then Config.FirstIntermissionDuration else Config.IntermissionDuration
			self:SetState("Intermission", intermissionDuration)
			self:BroadcastVotes()
			self:RunTimer(intermissionDuration)
			local chosenMap = self:ChooseMap()
			self.VotingOpen = false

			local available = {}
			for _, player in Players:GetPlayers() do
				if self.DataService:Get(player) then table.insert(available, player) end
			end
			if #available < Config.MinimumPlayers then continue end
			if chosenMap ~= self.MapService.LayoutId then
				self.MapService:Initialize(chosenMap)
				self.CrowdService:Initialize(self.MapService)
			end
			for _, player in Players:GetPlayers() do
				self:TeleportPlayer(player, self.MapService.LobbyPosition)
			end

			self.RoundNumber += 1
			self.SpecialRound = self.RoundNumber % 5 == 0
			self.Alive = {}
			self.Participants = {}
			self.Hunters = {}
			self.HunterActiveAt = {}
			for index, player in available do
				self.Alive[player] = true
				self.Participants[player] = true
				player:SetAttribute("AliveInRound", true)
				player:SetAttribute("TownHunter", false)
				self:ApplyHunterVisual(player)
				self:PreparePlayer(player, index)
			end
			self.RoundStartedWith = #available

			self.CurrentRuleId = self.RuleService:ChooseRule(MapCatalog[chosenMap].FeaturedRule, self.RoundNumber)
			self:SetState("RuleReveal", Config.RuleRevealDuration)
			self:RunTimer(Config.RuleRevealDuration)

			local context = {
				MapService = self.MapService,
				CrowdService = self.CrowdService,
				GetAlivePlayers = function() return self:GetAlivePlayers() end,
				IsAlive = function(player) return self:IsAlive(player) end,
				Eliminate = function(player, reason) self:Eliminate(player, reason) end,
				BroadcastEffect = function(name, data) self:BroadcastEffect(name, data) end,
				GetParticipants = function()
					local result = {}
					for player in pairs(self.Participants) do
						if player.Parent == Players then table.insert(result, player) end
					end
					return result
				end,
				IsParticipant = function(player) return self.Participants[player] == true end,
				AddCoins = function(player, amount) self.DataService:AddCoins(player, amount, true) end,
				ReportDanger = function(player, progress)
					self.PlayerState:FireClient(player, { Type = "Danger", Progress = progress })
				end,
				Active = true,
				StartedAt = os.clock(),
			}
			self.RuleService:StartRule(self.CurrentRuleId, context)
			self:SetState("Active", Config.RoundDuration)

			local finishAt = os.clock() + Config.RoundDuration
			local lastBroadcast = -1
			local eventStarted = false
			while os.clock() < finishAt do
				self.TimeLeft = math.max(0, math.ceil(finishAt - os.clock()))
				if not eventStarted and os.clock() - context.StartedAt >= 16 then
					eventStarted = true
					self.RoundEvent:Start(context)
				end
				self.RuleService:CheckPlayers(context)
				self:CheckHunters()
				if self.TimeLeft ~= lastBroadcast then
					lastBroadcast = self.TimeLeft
					self:BroadcastState()
				end
				local aliveCount = #self:GetAlivePlayers()
				if aliveCount == 0 then
					task.wait(0.8)
					break
				end
				task.wait(Config.RuleCheckInterval)
			end

			context.Active = false
			self.RoundEvent:Stop()
			self.RuleService:StopRule(context)
			local survivors = self:GetAlivePlayers()
			local survivorNames = {}
			for _, player in survivors do table.insert(survivorNames, player.DisplayName) end
			for player in pairs(self.Participants) do
				if player.Parent == Players then
					local firstWinToday = self.DataService:RecordRound(player, self.Alive[player] == true, #survivors == 1 and self.Alive[player] == true, self.SpecialRound)
					if firstWinToday then
						self.PlayerState:FireClient(player, { Type = "DailyWin", Amount = Config.Rewards.FirstWinToday })
					end
				end
			end

			self:SetState("Results", Config.ResultsDuration, { Survivors = survivorNames })
			for _, player in Players:GetPlayers() do
				player:SetAttribute("AliveInRound", false)
				player:SetAttribute("TownHunter", false)
				self.Hunters[player] = nil
				self.HunterActiveAt[player] = nil
				self:ApplyHunterVisual(player)
				self:TeleportPlayer(player, self.MapService.LobbyPosition + Vector3.new(math.random(-7, 7), 0, math.random(-5, 5)))
			end
			self:RunTimer(Config.ResultsDuration)
			self.Alive = {}
			self.Participants = {}
			self.Hunters = {}
			self.HunterActiveAt = {}
		end
	end)
end

return RoundService

