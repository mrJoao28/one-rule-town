--!strict

local RunService = game:GetService("RunService")
local Utils = require(script.Parent.RuleUtils)
local CharacterVisual = require(script.Parent.Parent.Services.CharacterVisual)

local Rule = { Id = "AvoidTheMayor" }

function Rule:Start(context)
	local model, root = CharacterVisual.Create("TheMayor", Color3.fromRGB(143, 45, 64), Color3.fromRGB(232, 181, 140), true)
	model.Parent = context.MapService.Map
	model:PivotTo(CFrame.new(0, 4, 75))

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
				model:PivotTo(CFrame.lookAt(nextPosition, flatTarget))
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

