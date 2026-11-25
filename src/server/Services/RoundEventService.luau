--!nonstrict

local Players = game:GetService("Players")

local RoundEventService = {}

function RoundEventService:Start(context)
	self:Stop()
	local eventId = if math.random(1, 2) == 1 then "TownSprint" else "TokenShower"
	context.BroadcastEffect(eventId)
	if eventId == "TownSprint" then
		self.SpeedBoosts = {}
		for _, player in context.GetParticipants() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				self.SpeedBoosts[humanoid] = humanoid.WalkSpeed
				humanoid.WalkSpeed += 4
			end
		end
		task.delay(8, function()
			if self.SpeedBoosts then
				self:Stop()
			end
		end)
	else
		local folder = Instance.new("Folder")
		folder.Name = "TownTokenShower"
		folder.Parent = context.MapService.Map
		self.Folder = folder
		self.Connections = {}
		for index = 1, 8 do
			local part = Instance.new("Part")
			part.Name = "EventToken"
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(2, 2, 2)
			part.Position = context.MapService:GetRoundSpawn(index) + Vector3.new(0, 1, 0)
			part.Color = Color3.fromRGB(255, 211, 76)
			part.Material = Enum.Material.Neon
			part.Anchored = true
			part.CanCollide = false
			part.Parent = folder
			local claimed = false
			table.insert(
				self.Connections,
				part.Touched:Connect(function(hit)
					if claimed or not context.Active or self.Folder ~= folder then
						return
					end
					local model = hit:FindFirstAncestorOfClass("Model")
					local player = model and Players:GetPlayerFromCharacter(model)
					if not player or not context.IsParticipant(player) then
						return
					end
					local root = model:FindFirstChild("HumanoidRootPart")
					if not root or (root.Position - part.Position).Magnitude > 8 then
						return
					end
					claimed = true
					context.AddCoins(player, 2)
					part:Destroy()
				end)
			)
		end
		task.delay(12, function()
			if self.Folder == folder then
				self:Stop()
			end
		end)
	end
	return eventId
end

function RoundEventService:Stop()
	for humanoid, speed in pairs(self.SpeedBoosts or {}) do
		if humanoid.Parent then
			humanoid.WalkSpeed = speed
		end
	end
	self.SpeedBoosts = nil
	for _, connection in self.Connections or {} do
		connection:Disconnect()
	end
	self.Connections = nil
	if self.Folder then
		self.Folder:Destroy()
	end
	self.Folder = nil
end

return RoundEventService
