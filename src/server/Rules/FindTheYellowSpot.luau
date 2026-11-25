--!strict

local Utils = require(script.Parent.RuleUtils)
local Rule = { Id = "FindTheYellowSpot" }
local TARGET = Vector3.new(58, 0, 0)

function Rule:Start(_context)
	self.Reached = {}
end

function Rule:CheckPlayer(player, context)
	if self.Reached[player.UserId] then
		return false, nil, 0
	end
	local root = Utils.GetRoot(player)
	if root and Utils.HorizontalDistance(root.Position, TARGET) <= 11 then
		self.Reached[player.UserId] = true
		return false, nil, 0
	end
	local elapsed = os.clock() - context.StartedAt
	if elapsed >= 12 then
		return true, "You missed the yellow market marker."
	end
	return false, nil, elapsed / 12
end

function Rule:Stop(_context) end

return Rule
