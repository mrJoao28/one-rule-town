--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "FloorIsLava" }

function Rule:Start(context)
	self.LavaStarted = false
	context.BroadcastEffect("LavaWarning", { Delay = 8 })
end

function Rule:CheckPlayer(player, context)
	if not self.LavaStarted and os.clock() - context.StartedAt >= 8 then
		self.LavaStarted = true
		context.MapService:SetLavaActive(true)
		context.BroadcastEffect("LavaActive")
	end
	if not self.LavaStarted then return false end
	local root = Utils.GetRoot(player)
	if root and root.Position.Y < 5.2 then
		return true, "You touched the lava."
	end
	return false
end

function Rule:Stop(context)
	context.MapService:SetLavaActive(false)
end

return Rule

