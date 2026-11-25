--!strict

local Utils = require(script.Parent.RuleUtils)
local Rule = { Id = "CrossTheStreet" }

function Rule:Start(context)
	self.StartSide = {}
	self.Crossed = {}
	for _, player in context.GetAlivePlayers() do
		local root = Utils.GetRoot(player)
		if root then
			self.StartSide[player.UserId] = if root.Position.X >= 0 then 1 else -1
		end
	end
end

function Rule:CheckPlayer(player, context)
	if self.Crossed[player.UserId] then
		return false, nil, 0
	end
	local root = Utils.GetRoot(player)
	if not root then
		return false
	end
	local side = self.StartSide[player.UserId]
	if not side then
		side = if root.Position.X >= 0 then 1 else -1
		self.StartSide[player.UserId] = side
	end
	if root.Position.X * side < -12 then
		self.Crossed[player.UserId] = true
		return false, nil, 0
	end
	local elapsed = os.clock() - context.StartedAt
	if elapsed >= 15 then
		return true, "You did not cross the town."
	end
	return false, nil, elapsed / 15
end

function Rule:Stop(_context) end

return Rule
