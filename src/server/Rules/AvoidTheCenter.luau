--!strict

local Utils = require(script.Parent.RuleUtils)
local Rule = { Id = "AvoidTheCenter" }

function Rule:Start(_context)
	self.InsideSince = {}
end

function Rule:CheckPlayer(player, _context)
	local root = Utils.GetRoot(player)
	if not root then
		return false
	end
	local distance = Utils.HorizontalDistance(root.Position, Vector3.zero)
	if distance > 18 then
		self.InsideSince[player.UserId] = nil
		return false, nil, 0
	end
	self.InsideSince[player.UserId] = self.InsideSince[player.UserId] or os.clock()
	local elapsed = os.clock() - self.InsideSince[player.UserId]
	if elapsed >= 3 then
		return true, "The town center saw you."
	end
	return false, nil, elapsed / 3
end

function Rule:Stop(_context) end

return Rule
