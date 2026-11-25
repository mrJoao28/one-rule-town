--!nonstrict

local Players = game:GetService("Players")

local Services = script.Parent.Services
local NetworkService = require(Services.NetworkService)
local MapService = require(Services.MapService)
local CrowdService = require(Services.CrowdService)
local DataService = require(Services.DataService)
local RuleService = require(Services.RuleService)
local RoundService = require(Services.RoundService)
local CosmeticService = require(Services.CosmeticService)
local MonetizationService = require(Services.MonetizationService)

NetworkService:Initialize()
MapService:Initialize()
CrowdService:Initialize(MapService)
DataService:Initialize(NetworkService)
RuleService:Initialize()
RoundService:Initialize(NetworkService, MapService, RuleService, DataService, CrowdService)
CosmeticService:Initialize(NetworkService, DataService)
MonetizationService:Initialize(NetworkService, DataService, RoundService)

local function playerAdded(player)
	-- Connect spawn handling immediately. DataStore requests can take several
	-- seconds, and the player must not be left falling before their profile loads.
	RoundService:OnPlayerAdded(player)

	task.spawn(function()
		local data = DataService:LoadPlayer(player)
		if not data then return end
		if player.Parent ~= Players then return end

		MonetizationService:RefreshPasses(player)
		CosmeticService:OnPlayerAdded(player)
	end)
end

local snapshotCooldown = setmetatable({}, { __mode = "k" })
NetworkService:GetFunction("GetSnapshot").OnServerInvoke = function(player)
	local now = os.clock()
	if now - (snapshotCooldown[player] or -math.huge) < 1 then return nil end
	snapshotCooldown[player] = now
	return RoundService:GetSnapshot(player)
end

Players.PlayerAdded:Connect(playerAdded)
for _, player in Players:GetPlayers() do playerAdded(player) end

RoundService:Start()
