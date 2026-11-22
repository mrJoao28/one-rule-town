--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "FreezeOnBell" }

function Rule:Start(_context)
	self.NextBell = os.clock() + math.random(6, 10)
	self.FreezeStarted = 0
	self.FreezeUntil = 0
	self.FrozenPositions = {}
end

function Rule:CheckPlayer(player, context)
	local now = os.clock()
	if now >= self.NextBell and now >= self.FreezeUntil then
		self.FreezeStarted = now
		self.FreezeUntil = now + 2.5
		self.NextBell = self.FreezeUntil + math.random(6, 10)
		self.FrozenPositions = {}
		for _, alivePlayer in context.GetAlivePlayers() do
			local root = Utils.GetRoot(alivePlayer)
			if root then self.FrozenPositions[alivePlayer.UserId] = root.Position end
		end
		context.BroadcastEffect("Bell", { Duration = 2.5 })
	end

	if now > self.FreezeStarted + 0.35 and now < self.FreezeUntil then
		local root = Utils.GetRoot(player)
		local startPosition = self.FrozenPositions[player.UserId]
		if root and startPosition and Utils.HorizontalDistance(root.Position, startPosition) > 1.5 then
			return true, "You moved while the bell was ringing."
		end
	end
	return false
end

function Rule:Stop(_context) end

return Rule

