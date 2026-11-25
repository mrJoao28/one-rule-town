--!strict

local Utils = require(script.Parent.RuleUtils)
local Rule = { Id = "AvoidTheCourt" }
local COURT = Vector3.new(-58, 0, 0)

function Rule:Start(_context)
	self.InsideSince = {}
end

function Rule:CheckPlayer(player, _context)
	local root = Utils.GetRoot(player)
	if not root then
		return false
	end
	local distance = Utils.HorizontalDistance(root.Position, COURT)
	if distance > 19 then
		self.InsideSince[player.UserId] = nil
		return false, nil, if distance < 25 then (25 - distance) / 30 else 0
	end
	self.InsideSince[player.UserId] = self.InsideSince[player.UserId] or os.clock()
	local elapsed = os.clock() - self.InsideSince[player.UserId]
	if elapsed >= 1.5 then
		return true, "The blue court is closed this round."
	end
	return false, nil, math.clamp(elapsed / 1.5, 0, 1)
end

function Rule:Stop(_context) end

return Rule
