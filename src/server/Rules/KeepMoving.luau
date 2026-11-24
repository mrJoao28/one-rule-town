--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "KeepMoving" }

function Rule:Start(_context)
	self.LastPositions = {}
	self.StationarySince = {}
end

function Rule:CheckPlayer(player, _context)
	local root = Utils.GetRoot(player)
	if not root then return false end
	local id = player.UserId
	local previous = self.LastPositions[id]
	self.LastPositions[id] = root.Position
	if not previous or Utils.HorizontalDistance(previous, root.Position) >= 0.35 then
		self.StationarySince[id] = nil
		return false, nil, 0
	end
	self.StationarySince[id] = self.StationarySince[id] or os.clock()
	if os.clock() - self.StationarySince[id] >= 2.5 then
		return true, "You stopped moving."
	end
	return false, nil, (os.clock() - self.StationarySince[id]) / 2.5
end

function Rule:Stop(_context) end

return Rule

