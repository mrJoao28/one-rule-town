--!strict

local CollectionService = game:GetService("CollectionService")

local Rule = { Id = "DoNotTouchRed" }

function Rule:Start(_context) end

function Rule:CheckPlayer(player, context)
	local character = player.Character
	if not character then return false end
	local floor = context.MapService:GetFloorPart(character)
	if floor and CollectionService:HasTag(floor, "RedSurface") then
		return true, "You touched a red surface."
	end
	return false
end

function Rule:Stop(_context) end

return Rule

