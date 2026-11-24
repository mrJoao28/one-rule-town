--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "HussHussCourt" }
local COURT_CENTER = Vector3.new(-58, 0, 0)

function Rule:Start(_context)
	self.OutsideSince = {}
end

function Rule:CheckPlayer(player, _context)
	local root = Utils.GetRoot(player)
	if not root then return false end
	local id = player.UserId
	if Utils.HorizontalDistance(root.Position, COURT_CENTER) <= 17 then
		self.OutsideSince[id] = nil
		return false, nil, 0
	end
	self.OutsideSince[id] = self.OutsideSince[id] or os.clock()
	if os.clock() - self.OutsideSince[id] >= 12 then
		return true, "You missed the HUSS HUSS court."
	end
	return false, nil, (os.clock() - self.OutsideSince[id]) / 12
end

function Rule:Stop(_context) end

return Rule
