--!nonstrict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local CrowdService = {}
local palette = {
	Color3.fromRGB(255, 195, 75), Color3.fromRGB(83, 181, 232),
	Color3.fromRGB(239, 113, 147), Color3.fromRGB(116, 203, 129),
	Color3.fromRGB(190, 134, 238),
}

local function limb(model, name, size, color, position)
	local value = Instance.new("Part")
	value.Name = name
	value.Size = size
	value.Color = color
	value.Material = Enum.Material.SmoothPlastic
	value.Anchored = true
	value.CanCollide = false
	value.CanTouch = false
	value.CanQuery = false
	value.Parent = model
	value.CFrame = CFrame.new(position)
	return value
end

function CrowdService:Initialize(mapService)
	self.Map = mapService
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "TownResidents"
	self.Folder.Parent = mapService.Map
	self.Residents = {}
	self.Elapsed = 0
	self.Connection = RunService.Heartbeat:Connect(function(delta)
		self.Elapsed += delta
		for index, resident in self.Residents do
			local angle = self.Elapsed * resident.Speed + index * (math.pi * 2 / math.max(1, #self.Residents))
			local radius = 18 + index * 4
			local base = Vector3.new(math.cos(angle) * radius, 2.5, math.sin(angle) * radius)
			local nextAngle = angle + 0.02
			local forward = Vector3.new(math.cos(nextAngle) * radius, 2.5, math.sin(nextAngle) * radius)
			local facing = CFrame.lookAt(base, forward)
			local stride = math.sin(self.Elapsed * 11 + index)
			resident.Root.CFrame = facing
			resident.Torso.CFrame = facing * CFrame.new(0, 0.1 + math.abs(stride) * 0.12, 0)
			resident.Head.CFrame = facing * CFrame.new(0, 2.1 + math.abs(stride) * 0.12, 0)
			resident.LeftArm.CFrame = facing * CFrame.new(-1.1, 0.05, stride * 0.5)
			resident.RightArm.CFrame = facing * CFrame.new(1.1, 0.05, -stride * 0.5)
			resident.LeftLeg.CFrame = facing * CFrame.new(-0.45, -1.65, -stride * 0.5)
			resident.RightLeg.CFrame = facing * CFrame.new(0.45, -1.65, stride * 0.5)
		end
	end)
	task.spawn(function()
		while self.Folder.Parent do
			self:AdjustPopulation()
			task.wait(3)
		end
	end)
end

function CrowdService:CreateResident(index)
	local model = Instance.new("Model")
	model.Name = "Resident_" .. index
	model.Parent = self.Folder
	local color = palette[(index - 1) % #palette + 1]
	local resident = {
		Root = limb(model, "Root", Vector3.new(0.5, 0.5, 0.5), color, Vector3.zero),
		Torso = limb(model, "Torso", Vector3.new(2, 2, 1), color, Vector3.zero),
		Head = limb(model, "Head", Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(245, 207, 165), Vector3.zero),
		LeftArm = limb(model, "LeftArm", Vector3.new(0.7, 1.8, 0.7), Color3.fromRGB(245, 207, 165), Vector3.zero),
		RightArm = limb(model, "RightArm", Vector3.new(0.7, 1.8, 0.7), Color3.fromRGB(245, 207, 165), Vector3.zero),
		LeftLeg = limb(model, "LeftLeg", Vector3.new(0.8, 1.7, 0.8), Color3.fromRGB(43, 52, 76), Vector3.zero),
		RightLeg = limb(model, "RightLeg", Vector3.new(0.8, 1.7, 0.8), Color3.fromRGB(43, 52, 76), Vector3.zero),
		Model = model,
		Speed = 0.22 + index * 0.03,
	}
	resident.Root.Transparency = 1
	return resident
end

function CrowdService:AdjustPopulation()
	local target = math.max(0, Config.TargetTownPopulation - #Players:GetPlayers())
	while #self.Residents < target do
		table.insert(self.Residents, self:CreateResident(#self.Residents + 1))
	end
	while #self.Residents > target do
		local resident = table.remove(self.Residents)
		resident.Model:Destroy()
	end
end

function CrowdService:GetNearestDistance(position)
	local distance = math.huge
	for _, resident in self.Residents do
		distance = math.min(distance, (resident.Root.Position - position).Magnitude)
	end
	return distance
end

return CrowdService
