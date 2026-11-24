--!nonstrict

local RuleService = {}

function RuleService:Initialize()
	self.Rules = {}
	self.History = {}
	local rulesFolder = script.Parent.Parent.Rules
	for _, module in rulesFolder:GetChildren() do
		if module:IsA("ModuleScript") and module.Name ~= "RuleUtils" then
			local success, rule = pcall(require, module)
			if success and type(rule) == "table" and type(rule.Id) == "string" then
				self.Rules[rule.Id] = rule
			else
				warn("Could not load rule", module.Name, rule)
			end
		end
	end
end

function RuleService:ChooseRule()
	local candidates = {}
	for id in pairs(self.Rules) do
		if not table.find(self.History, id) then
			table.insert(candidates, id)
		end
	end
	if #candidates == 0 then
		self.History = {}
		for id in pairs(self.Rules) do table.insert(candidates, id) end
	end
	local id = candidates[math.random(1, #candidates)]
	table.insert(self.History, id)
	while #self.History > 3 do table.remove(self.History, 1) end
	return id
end

function RuleService:StartRule(id, context)
	local template = self.Rules[id]
	assert(template, "Unknown rule: " .. tostring(id))
	local rule = table.clone(template)
	self.ActiveRule = rule
	self.LastDanger = {}
	local success, err = pcall(function() rule:Start(context) end)
	if not success then
		warn("Rule start failed", id, err)
	end
	return rule
end

function RuleService:CheckPlayers(context)
	local rule = self.ActiveRule
	if not rule then return end
	for _, player in context.GetAlivePlayers() do
		local success, violated, reason, danger = pcall(function()
			return rule:CheckPlayer(player, context)
		end)
		if not success then
			warn("Rule check failed", rule.Id, player.Name, violated)
		elseif violated then
			context.Eliminate(player, reason or "You broke the rule.")
		elseif type(danger) == "number" then
			local previous = self.LastDanger[player.UserId]
			local progress = math.clamp(danger, 0, 1)
			if (progress == 0 and previous and previous.Progress > 0)
				or (progress > 0 and (not previous or os.clock() - previous.At >= 0.5)) then
				self.LastDanger[player.UserId] = { Progress = progress, At = os.clock() }
				context.ReportDanger(player, progress)
			end
		end
	end
end

function RuleService:StopRule(context)
	local rule = self.ActiveRule
	self.ActiveRule = nil
	self.LastDanger = nil
	if rule then
		local success, err = pcall(function() rule:Stop(context) end)
		if not success then warn("Rule cleanup failed", rule.Id, err) end
	end
end

return RuleService
