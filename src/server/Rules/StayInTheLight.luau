--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "StayInTheLight" }

function Rule:Start(_context)
	self.OutsideSince = {}
end

function Rule:CheckPlayer(player, context)
	local root = Utils.GetRoot(player)
	if not root then return false end
	if context.MapService:IsPointInsideTag(root.Position, "LightZone") then
		self.OutsideSince[player.UserId] = nil
		return false, nil, 0
	end
	self.OutsideSince[player.UserId] = self.OutsideSince[player.UserId] or os.clock()
	if os.clock() - self.OutsideSince[player.UserId] >= 3 then
		return true, "You stayed in the dark."
	end
	return false, nil, (os.clock() - self.OutsideSince[player.UserId]) / 3
end

function Rule:Stop(_context) end

return Rule

