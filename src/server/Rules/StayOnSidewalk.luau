--!strict

local CollectionService = game:GetService("CollectionService")
local Rule = { Id = "StayOnSidewalk" }

function Rule:Start(_context)
	self.OutsideSince = {}
end

function Rule:CheckPlayer(player, context)
	local character = player.Character
	if not character then
		return false
	end
	local floor = context.MapService:GetFloorPart(character)
	if not floor then
		return false
	end
	if CollectionService:HasTag(floor, "SafePavement") then
		self.OutsideSince[player.UserId] = nil
		return false, nil, 0
	end
	self.OutsideSince[player.UserId] = self.OutsideSince[player.UserId] or os.clock()
	local elapsed = os.clock() - self.OutsideSince[player.UserId]
	if elapsed >= 4 then
		return true, "The Mayor owns the road."
	end
	return false, nil, elapsed / 4
end

function Rule:Stop(_context) end

return Rule
