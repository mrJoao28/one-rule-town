--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RuleCatalog = require(ReplicatedStorage.Shared.RuleCatalog)

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
	self.GameState = networkService:GetEvent("GameState")
	self.PlayerState = networkService:GetEvent("PlayerState")
	self.UseRevive = networkService:GetEvent("UseRevive")
	self.State = "Booting"
	self.TimeLeft = 0
	self.CurrentRuleId = nil
	self.Alive = {}
	self.Participants = {}
	self.RoundNumber = 0
	self.RoundStartedWith = 0

	self.UseRevive.OnServerEvent:Connect(function(player)
		self:TryRevive(player)
	end)
end

function RoundService:OnPlayerAdded(player)
	player:SetAttribute("AliveInRound", false)
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
		CanRevive = self:CanRevive(player),
		RoundNumber = self.RoundNumber,
		MapName = self.MapService.MapName,
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
	player:SetAttribute("AliveInRound", false)
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
		if player.Parent ~= Players or self.Alive[player] then return end
		if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
		self:TeleportPlayer(player, self.MapService.SpectatorPosition)
	end)
end

function RoundService:CanRevive(player)
	return self.State == "Active"
		and self.Participants[player] == true
		and not self.Alive[player]
		and self.TimeLeft > Config.ReviveCutoffSeconds
end

function RoundService:TryRevive(player)
	if not self:CanRevive(player) then return false end
	if not self.DataService:ConsumeRevive(player) then return false end
	self.Alive[player] = true
	player:SetAttribute("AliveInRound", true)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Health = humanoid.MaxHealth
	end
	self:TeleportPlayer(player, self.MapService:GetRoundSpawn(math.random(1, #self.MapService.RoundSpawns)))
	self.PlayerState:FireAllClients({ Type = "Revived", UserId = player.UserId, Name = player.DisplayName })
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
			self:SetState("Intermission", Config.IntermissionDuration)
			self:RunTimer(Config.IntermissionDuration)

			local available = {}
			for _, player in Players:GetPlayers() do
				if self.DataService:Get(player) then table.insert(available, player) end
			end
			if #available < Config.MinimumPlayers then continue end

			self.RoundNumber += 1
			self.Alive = {}
			self.Participants = {}
			for index, player in available do
				self.Alive[player] = true
				self.Participants[player] = true
				player:SetAttribute("AliveInRound", true)
				self:PreparePlayer(player, index)
			end
			self.RoundStartedWith = #available

			self.CurrentRuleId = self.RuleService:ChooseRule()
			self:SetState("RuleReveal", Config.RuleRevealDuration)
			self:RunTimer(Config.RuleRevealDuration)

			local context = {
				MapService = self.MapService,
				CrowdService = self.CrowdService,
				GetAlivePlayers = function() return self:GetAlivePlayers() end,
				IsAlive = function(player) return self:IsAlive(player) end,
				Eliminate = function(player, reason) self:Eliminate(player, reason) end,
				BroadcastEffect = function(name, data) self:BroadcastEffect(name, data) end,
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
			while os.clock() < finishAt do
				self.TimeLeft = math.max(0, math.ceil(finishAt - os.clock()))
				self.RuleService:CheckPlayers(context)
				if self.TimeLeft ~= lastBroadcast then
					lastBroadcast = self.TimeLeft
					self:BroadcastState()
				end
				local aliveCount = #self:GetAlivePlayers()
				if aliveCount == 0 or (self.RoundStartedWith > 1 and aliveCount <= 1) then
					task.wait(0.8)
					break
				end
				task.wait(Config.RuleCheckInterval)
			end

			context.Active = false
			self.RuleService:StopRule(context)
			local survivors = self:GetAlivePlayers()
			local survivorNames = {}
			for _, player in survivors do table.insert(survivorNames, player.DisplayName) end
			for player in pairs(self.Participants) do
				if player.Parent == Players then
					local firstWinToday = self.DataService:RecordRound(player, self.Alive[player] == true, #survivors == 1 and self.Alive[player] == true)
					if firstWinToday then
						self.PlayerState:FireClient(player, { Type = "DailyWin", Amount = Config.Rewards.FirstWinToday })
					end
				end
			end

			self:SetState("Results", Config.ResultsDuration, { Survivors = survivorNames })
			for _, player in Players:GetPlayers() do
				player:SetAttribute("AliveInRound", false)
				self:TeleportPlayer(player, self.MapService.LobbyPosition + Vector3.new(math.random(-7, 7), 0, math.random(-5, 5)))
			end
			self:RunTimer(Config.ResultsDuration)
			self.Alive = {}
			self.Participants = {}
			self.MapService:Initialize((self.MapService.LayoutId % 2) + 1)
			self.CrowdService:Initialize(self.MapService)
			for _, player in Players:GetPlayers() do
				self:TeleportPlayer(player, self.MapService.LobbyPosition)
			end
		end
	end)
end

return RoundService

