--!strict

local RunService = game:GetService("RunService")
local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "AvoidTheMayor" }

function Rule:Start(context)
	local model = Instance.new("Model")
	model.Name = "TheMayor"
	model.Parent = context.MapService.Map

	local root = Instance.new("Part")
	root.Name = "MayorRoot"
	root.Shape = Enum.PartType.Ball
	root.Size = Vector3.new(7, 7, 7)
	root.Color = Color3.fromRGB(195, 39, 54)
	root.Material = Enum.Material.Neon
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new(0, 5, 75)
	root.Parent = model
	model.PrimaryPart = root

	local face = Instance.new("BillboardGui")
	face.Size = UDim2.fromOffset(180, 55)
	face.StudsOffset = Vector3.new(0, 5, 0)
	face.AlwaysOnTop = true
	face.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = "THE MAYOR"
	label.Parent = face

	self.Model = model
	self.Connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not context.Active or not root.Parent then return end
		local targetPosition
		local distance = math.huge
		for _, player in context.GetAlivePlayers() do
			local playerRoot = Utils.GetRoot(player)
			if playerRoot then
				local candidate = (playerRoot.Position - root.Position).Magnitude
				if candidate < distance then
					distance = candidate
					targetPosition = playerRoot.Position
				end
			end
		end
		if targetPosition then
			local flatTarget = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
			local direction = flatTarget - root.Position
			if direction.Magnitude > 0.1 then
				local nextPosition = root.Position + direction.Unit * math.min(direction.Magnitude, 11 * deltaTime)
				root.CFrame = CFrame.lookAt(nextPosition, flatTarget)
			end
		end
	end)
end

function Rule:CheckPlayer(player, _context)
	local root = Utils.GetRoot(player)
	local mayorRoot = self.Model and self.Model.PrimaryPart
	if root and mayorRoot and (root.Position - mayorRoot.Position).Magnitude < 6 then
		return true, "The Mayor caught you."
	end
	return false
end

function Rule:Stop(_context)
	if self.Connection then self.Connection:Disconnect() end
	if self.Model then self.Model:Destroy() end
end

return Rule

