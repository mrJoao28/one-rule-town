--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "DoNotJump" }

function Rule:Start(context)
	self.Violations = {}
	self.Connections = {}
	for _, player in context.GetAlivePlayers() do
		local humanoid = Utils.GetHumanoid(player)
		if humanoid then
			table.insert(self.Connections, humanoid.StateChanged:Connect(function(_, newState)
				if context.Active and newState == Enum.HumanoidStateType.Jumping then
					self.Violations[player.UserId] = true
				end
			end))
		end
	end
end

function Rule:CheckPlayer(player, _context)
	if self.Violations[player.UserId] then
		return true, "You jumped."
	end
	return false
end

function Rule:Stop(_context)
	for _, connection in self.Connections or {} do
		connection:Disconnect()
	end
end

return Rule

