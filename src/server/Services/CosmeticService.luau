--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CosmeticService = {}

local function clearEffects(character)
	for _, descendant in character:GetDescendants() do
		if descendant.Name == "ORT_Cosmetic" then
			descendant:Destroy()
		end
	end
end

function CosmeticService:Initialize(networkService, dataService)
	self.DataService = dataService
	self.Cooldowns = {}
	self.Remote = networkService:GetEvent("CosmeticAction")
	self.Remote.OnServerEvent:Connect(function(player, action, cosmeticId)
		if type(action) ~= "string" or type(cosmeticId) ~= "string" then return end
		local last = self.Cooldowns[player] or 0
		if os.clock() - last < 0.4 then return end
		self.Cooldowns[player] = os.clock()

		local cosmetic = Config.Cosmetics[cosmeticId]
		if not cosmetic then return end
		if cosmetic.RequiresVIP and not player:GetAttribute("VIP") then return end

		if action == "Buy" then
			if self.DataService:BuyCosmetic(player, cosmeticId, cosmetic.Price) then
				self.DataService:EquipCosmetic(player, cosmeticId)
				self:Apply(player)
			end
		elseif action == "Equip" then
			if self.DataService:EquipCosmetic(player, cosmeticId) then
				self:Apply(player)
			end
		end
	end)
end

function CosmeticService:OnPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		self:Apply(player)
	end)
	if player.Character then
		task.defer(function() self:Apply(player) end)
	end
end

function CosmeticService:Apply(player)
	local character = player.Character
	local data = self.DataService:Get(player)
	if not character or not data then return end
	clearEffects(character)

	local cosmetic = Config.Cosmetics[data.EquippedCosmetic]
	if not cosmetic then return end
	if cosmetic.RequiresVIP and not player:GetAttribute("VIP") then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end

	if cosmetic.Effect == "Trail" then
		local bottom = Instance.new("Attachment")
		bottom.Name = "ORT_Cosmetic"
		bottom.Position = Vector3.new(0, -2.4, 0)
		bottom.Parent = root
		local top = Instance.new("Attachment")
		top.Name = "ORT_Cosmetic"
		top.Position = Vector3.new(0, 2.2, 0)
		top.Parent = root
		local trail = Instance.new("Trail")
		trail.Name = "ORT_Cosmetic"
		trail.Attachment0 = bottom
		trail.Attachment1 = top
		trail.Color = ColorSequence.new(cosmetic.Color)
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.Lifetime = 0.5
		trail.Parent = root
	elseif cosmetic.Effect == "Highlight" then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ORT_Cosmetic"
		highlight.FillColor = cosmetic.Color
		highlight.FillTransparency = 0.45
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.OutlineTransparency = 0.15
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = character
	end
end

return CosmeticService

