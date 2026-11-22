--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "DoNotGoInside" }

function Rule:Start(_context) end

function Rule:CheckPlayer(player, context)
	local root = Utils.GetRoot(player)
	if root and context.MapService:IsPointInsideTag(root.Position, "IndoorZone") then
		return true, "You entered a closed building."
	end
	return false
end

function Rule:Stop(_context) end

return Rule

