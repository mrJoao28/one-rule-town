--!strict

local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "StayNearSomeone" }

function Rule:Start(_context)
	self.AloneSince = {}
end

function Rule:CheckPlayer(player, context)
	local players = context.GetAlivePlayers()
	if #players <= 1 and not context.CrowdService then
		self.AloneSince[player.UserId] = nil
		return false, nil, 0
	end
	local root = Utils.GetRoot(player)
	if not root then return false end
	local nearest = context.CrowdService and context.CrowdService:GetNearestDistance(root.Position) or math.huge
	for _, other in players do
		if other ~= player then
			local otherRoot = Utils.GetRoot(other)
			if otherRoot then
				nearest = math.min(nearest, (root.Position - otherRoot.Position).Magnitude)
			end
		end
	end
	if nearest <= 18 then
		self.AloneSince[player.UserId] = nil
		return false, nil, 0
	end
	self.AloneSince[player.UserId] = self.AloneSince[player.UserId] or os.clock()
	if os.clock() - self.AloneSince[player.UserId] >= 4 then
		return true, "You were alone for too long."
	end
	return false, nil, (os.clock() - self.AloneSince[player.UserId]) / 4
end

function Rule:Stop(_context) end

return Rule

