--!nonstrict

local Players = game:GetService("Players")

local Services = script.Parent.Services
local NetworkService = require(Services.NetworkService)
local MapService = require(Services.MapService)
local DataService = require(Services.DataService)
local RuleService = require(Services.RuleService)
local RoundService = require(Services.RoundService)
local CosmeticService = require(Services.CosmeticService)
local MonetizationService = require(Services.MonetizationService)

NetworkService:Initialize()
MapService:Initialize()
DataService:Initialize(NetworkService)
RuleService:Initialize()
RoundService:Initialize(NetworkService, MapService, RuleService, DataService)
CosmeticService:Initialize(NetworkService, DataService)
MonetizationService:Initialize(NetworkService, DataService, RoundService)

local function playerAdded(player)
	-- Connect spawn handling immediately. DataStore requests can take several
	-- seconds, and the player must not be left falling before their profile loads.
	RoundService:OnPlayerAdded(player)

	task.spawn(function()
		DataService:LoadPlayer(player)
		if player.Parent ~= Players then return end

		MonetizationService:RefreshPasses(player)
		CosmeticService:OnPlayerAdded(player)
	end)
end

NetworkService:GetFunction("GetSnapshot").OnServerInvoke = function(player)
	return RoundService:GetSnapshot(player)
end

Players.PlayerAdded:Connect(playerAdded)
for _, player in Players:GetPlayers() do playerAdded(player) end

RoundService:Start()
