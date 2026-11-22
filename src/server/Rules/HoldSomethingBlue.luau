--!strict

local Players = game:GetService("Players")
local Utils = require(script.Parent.RuleUtils)

local Rule = { Id = "HoldSomethingBlue" }

function Rule:Start(context)
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "BlueRuleObjects"
	self.Folder.Parent = context.MapService.Map
	self.Connections = {}
	self.Objects = {}

	for index, position in context.MapService.BlueObjectSpawns do
		local object = Instance.new("Part")
		object.Name = "BlueObject" .. index
		object.Shape = if index % 2 == 0 then Enum.PartType.Ball else Enum.PartType.Block
		object.Size = Vector3.new(2.5, 2.5, 2.5)
		object.CFrame = CFrame.new(position)
		object.Color = Color3.fromRGB(45, 125, 255)
		object.Material = Enum.Material.Neon
		object.Anchored = true
		object.Parent = self.Folder
		table.insert(self.Objects, object)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pick Up"
		prompt.ObjectText = "Blue Object"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 10
		prompt.Parent = object

		table.insert(self.Connections, prompt.Triggered:Connect(function(player)
			if not context.Active or not context.IsAlive(player) or player:GetAttribute("HoldingBlue") then return end
			local root = Utils.GetRoot(player)
			if not root or not object.Parent then return end
			player:SetAttribute("HoldingBlue", true)
			prompt.Enabled = false
			object.Anchored = false
			object.CanCollide = false
			object.CFrame = root.CFrame * CFrame.new(1.8, 0, 0)
			object.Parent = player.Character
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = object
			weld.Parent = object
		end))
	end
end

function Rule:CheckPlayer(player, context)
	if os.clock() - context.StartedAt < 12 then return false end
	if not player:GetAttribute("HoldingBlue") then
		return true, "You did not find a blue object."
	end
	return false
end

function Rule:Stop(context)
	for _, connection in self.Connections or {} do connection:Disconnect() end
	if self.Folder then self.Folder:Destroy() end
	for _, object in self.Objects or {} do
		if object.Parent then object:Destroy() end
	end
	for _, player in Players:GetPlayers() do
		player:SetAttribute("HoldingBlue", nil)
		local character = player.Character
		if character then
			for _, child in character:GetChildren() do
				if child.Name:match("^BlueObject") then child:Destroy() end
			end
		end
	end
end

return Rule

