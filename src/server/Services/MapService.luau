--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local MapService = {}

local MAP_NAME = "OneRuleTownMap"
local COLORS = {
	Cream = Color3.fromRGB(245, 235, 205),
	Blue = Color3.fromRGB(67, 161, 211),
	Green = Color3.fromRGB(83, 170, 116),
	Yellow = Color3.fromRGB(246, 190, 61),
	Red = Color3.fromRGB(215, 60, 67),
	Road = Color3.fromRGB(65, 69, 78),
	Sidewalk = Color3.fromRGB(188, 188, 180),
}

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local value = Instance.new("Part")
	value.Name = name
	value.Size = size
	value.CFrame = cframe
	value.Color = color
	value.Material = material or Enum.Material.SmoothPlastic
	value.Anchored = true
	value.TopSurface = Enum.SurfaceType.Smooth
	value.BottomSurface = Enum.SurfaceType.Smooth
	value.Parent = parent
	return value
end

local function addBillboard(parent: BasePart, text: string, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(260, 70)
	gui.StudsOffset = Vector3.new(0, parent.Size.Y / 2 + 1.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	label.BackgroundTransparency = 0.05
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
end

local function createBuilding(parent: Instance, name: string, center: Vector3, size: Vector3, color: Color3, signText: string)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local wallThickness = 1
	part(model, "Floor", Vector3.new(size.X, 1, size.Z), CFrame.new(center), Color3.fromRGB(225, 218, 198), Enum.Material.Concrete)
	part(model, "BackWall", Vector3.new(size.X, size.Y, wallThickness), CFrame.new(center + Vector3.new(0, size.Y / 2, size.Z / 2)), color)
	part(model, "LeftWall", Vector3.new(wallThickness, size.Y, size.Z), CFrame.new(center + Vector3.new(-size.X / 2, size.Y / 2, 0)), color)
	part(model, "RightWall", Vector3.new(wallThickness, size.Y, size.Z), CFrame.new(center + Vector3.new(size.X / 2, size.Y / 2, 0)), color)
	part(model, "Roof", Vector3.new(size.X + 2, 1, size.Z + 2), CFrame.new(center + Vector3.new(0, size.Y, 0)), color:Lerp(Color3.new(0, 0, 0), 0.12))
	local glass = Color3.fromRGB(105, 214, 240)
	local trim = Color3.fromRGB(255, 240, 194)
	for _, side in { -1, 1 } do
		for _, level in { 6, 11 } do
			for index = -1, 1 do
				local window = part(model, "LitWindow", Vector3.new(4, 3.5, 0.18), CFrame.new(center + Vector3.new(index * (size.X / 4), level, side * (size.Z / 2 + 0.55))), glass, Enum.Material.Glass)
				window.CanCollide = false
				part(model, "WindowSill", Vector3.new(5, 0.3, 0.7), CFrame.new(window.Position - Vector3.new(0, 1.9, 0)), trim)
			end
		end
	end
	part(model, "ShopAwning", Vector3.new(size.X - 2, 0.6, 4), CFrame.new(center + Vector3.new(0, 5, -size.Z / 2 - 2)), trim)
	for _, offset in { -size.X / 2 + 2, size.X / 2 - 2 } do
		part(model, "AwningStripe", Vector3.new(2, 0.1, 4), CFrame.new(center + Vector3.new(offset, 5.36, -size.Z / 2 - 2)), color)
	end
	part(model, "FrontDoor", Vector3.new(6, 7, 0.35), CFrame.new(center + Vector3.new(0, 3.5, -size.Z / 2 - 0.5)), Color3.fromRGB(51, 80, 98), Enum.Material.Glass).CanCollide = false

	local sign = part(model, "BuildingSign", Vector3.new(math.min(size.X - 2, 18), 3, 0.6), CFrame.new(center + Vector3.new(0, size.Y - 2.5, -size.Z / 2 - 0.5)), Color3.fromRGB(32, 36, 45))
	addBillboard(sign, signText, Color3.fromRGB(255, 244, 205))

	local zone = part(model, "IndoorZone", Vector3.new(size.X - 2, size.Y - 1, size.Z - 2), CFrame.new(center + Vector3.new(0, size.Y / 2, 0)), Color3.new(1, 1, 1))
	zone.Transparency = 1
	zone.CanCollide = false
	zone.CanQuery = false
	CollectionService:AddTag(zone, "IndoorZone")
end

local function createTree(parent: Instance, position: Vector3)
	part(parent, "TreeTrunk", Vector3.new(2, 7, 2), CFrame.new(position + Vector3.new(0, 3.5, 0)), Color3.fromRGB(111, 77, 54), Enum.Material.Wood)
	for _, offset in { Vector3.new(-2.4, 8, 0), Vector3.new(2.4, 8, 0), Vector3.new(0, 10, 0) } do
		local crown = part(parent, "TreeCrown", Vector3.new(6, 6, 6), CFrame.new(position + offset), COLORS.Green, Enum.Material.Grass)
		crown.Shape = Enum.PartType.Ball
		crown.CanCollide = false
	end
	part(parent, "TreePlanter", Vector3.new(6, 0.6, 6), CFrame.new(position + Vector3.new(0, 0.2, 0)), Color3.fromRGB(166, 130, 100), Enum.Material.Brick)
end

local function decorateTown(parent: Instance)
	-- A coherent street layout provides visual anchors in every short video clip.
	for _, side in { -1, 1 } do
		part(parent, "Sidewalk", Vector3.new(7, 0.5, 180), CFrame.new(side * 19, 0.55, 0), COLORS.Sidewalk, Enum.Material.Pavement)
		part(parent, "Sidewalk", Vector3.new(180, 0.5, 7), CFrame.new(0, 0.55, side * 19), COLORS.Sidewalk, Enum.Material.Pavement)
		for index = -3, 3 do
			local z = index * 24
			local pole = part(parent, "StreetLamp", Vector3.new(0.6, 14, 0.6), CFrame.new(side * 22, 7.5, z), Color3.fromRGB(54, 64, 81), Enum.Material.Metal)
			local bulb = part(parent, "LampGlow", Vector3.new(3.5, 0.7, 3.5), CFrame.new(side * 22, 14.7, z), COLORS.Yellow, Enum.Material.Neon)
			bulb.CanCollide = false
			local light = Instance.new("PointLight")
			light.Range = 19
			light.Brightness = 1.2
			light.Color = COLORS.Yellow
			light.Parent = bulb
			pole.CanCollide = false
		end
	end
	for index = -3, 3 do
		if index ~= 0 then
			part(parent, "RoadMarking", Vector3.new(0.6, 0.08, 9), CFrame.new(0, 0.62, index * 24), COLORS.Yellow, Enum.Material.Neon)
			part(parent, "RoadMarking", Vector3.new(9, 0.08, 0.6), CFrame.new(index * 24, 0.67, 0), COLORS.Yellow, Enum.Material.Neon)
		end
	end
	for _, position in { Vector3.new(-34, 0, 40), Vector3.new(34, 0, -40) } do
		local board = part(parent, "TownNoticeBoard", Vector3.new(13, 9, 1), CFrame.new(position + Vector3.new(0, 5, 0)), Color3.fromRGB(37, 49, 69), Enum.Material.Wood)
		addBillboard(board, "ONE RULE. SURVIVE.", COLORS.Yellow)
	end
	-- A visible entrance gives new players a landmark as soon as they spawn.
	for _, side in { -1, 1 } do
		part(parent, "TownGatePillar", Vector3.new(3, 17, 3), CFrame.new(side * 16, 8.5, -78), COLORS.Blue, Enum.Material.Brick)
		local lamp = part(parent, "GateBeacon", Vector3.new(4, 4, 4), CFrame.new(side * 16, 18, -78), COLORS.Yellow, Enum.Material.Neon)
		lamp.Shape = Enum.PartType.Ball
		lamp.CanCollide = false
	end
	local gate = part(parent, "TownGate", Vector3.new(35, 3, 3), CFrame.new(0, 17, -78), Color3.fromRGB(30, 44, 72), Enum.Material.Metal)
	addBillboard(gate, "WELCOME TO ONE RULE TOWN", COLORS.Yellow)
	-- The small plaza props are outside the road and do not hide any rule zones.
	for _, position in { Vector3.new(-31, 0, -8), Vector3.new(31, 0, 8), Vector3.new(-8, 0, 31), Vector3.new(8, 0, -31) } do
		local pedestal = part(parent, "MemePedestal", Vector3.new(5, 2, 5), CFrame.new(position + Vector3.new(0, 1, 0)), COLORS.Blue, Enum.Material.Brick)
		pedestal.CanCollide = true
		local token = part(parent, "TownTokenSculpture", Vector3.new(3, 3, 0.65), CFrame.new(position + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, math.rad(35), 0), COLORS.Yellow, Enum.Material.Neon)
		token.Shape = Enum.PartType.Cylinder
		token.CanCollide = false
	end
	local court = part(parent, "HussTrainingCourt", Vector3.new(30, 0.5, 24), CFrame.new(-58, 0.3, 0), Color3.fromRGB(62, 135, 205), Enum.Material.SmoothPlastic)
	part(parent, "CourtCenter", Vector3.new(0.4, 0.06, 22), CFrame.new(-58, 0.59, 0), COLORS.Cream, Enum.Material.Neon)
	addBillboard(court, "HUSS HUSS TRAINING", COLORS.Yellow)
	for _, x in { -71, -45 } do
		part(parent, "HoopPole", Vector3.new(0.6, 10, 0.6), CFrame.new(x, 5.5, 0), Color3.fromRGB(42, 57, 72), Enum.Material.Metal)
		part(parent, "Backboard", Vector3.new(0.5, 5, 7), CFrame.new(x, 10, 0), COLORS.Cream)
		local rim = part(parent, "BasketRim", Vector3.new(2, 0.3, 2), CFrame.new(x + (if x < -58 then 1.5 else -1.5), 8.5, 0), COLORS.Red, Enum.Material.Neon)
		rim.CanCollide = false
	end
	for _, position in { Vector3.new(-35, 0, -35), Vector3.new(35, 0, 35), Vector3.new(-35, 0, 35), Vector3.new(35, 0, -35) } do
		part(parent, "ParkBenchSeat", Vector3.new(7, 0.5, 2), CFrame.new(position + Vector3.new(0, 1.7, 0)), Color3.fromRGB(139, 81, 55), Enum.Material.Wood)
		part(parent, "ParkBenchBack", Vector3.new(7, 2, 0.4), CFrame.new(position + Vector3.new(0, 2.6, 1)), Color3.fromRGB(139, 81, 55), Enum.Material.Wood)
	end
	-- The outer blocks frame the playable town without obstructing the rule zones.
	for _, position in {
		Vector3.new(-81, 0, -81), Vector3.new(81, 0, -81),
		Vector3.new(-81, 0, 81), Vector3.new(81, 0, 81),
	} do
		local base = part(parent, "CornerKiosk", Vector3.new(10, 7, 10), CFrame.new(position + Vector3.new(0, 3.5, 0)), Color3.fromRGB(227, 193, 139), Enum.Material.Brick)
		part(parent, "KioskRoof", Vector3.new(12, 1, 12), CFrame.new(position + Vector3.new(0, 7.5, 0)), COLORS.Red, Enum.Material.Slate)
		base.CanCollide = true
	end
end

function MapService:Initialize()
	local old = Workspace:FindFirstChild(MAP_NAME)
	if old then
		old:Destroy()
	end

	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(128, 137, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(155, 165, 180)
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = 0.1
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Haze = 1
	atmosphere.Color = Color3.fromRGB(212, 231, 255)
	atmosphere.Parent = Lighting
	local colorCorrection = Lighting:FindFirstChild("TownColor") or Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "TownColor"
	colorCorrection.Contrast = 0.12
	colorCorrection.Saturation = 0.12
	colorCorrection.TintColor = Color3.fromRGB(255, 243, 226)
	colorCorrection.Parent = Lighting

	local map = Instance.new("Model")
	map.Name = MAP_NAME
	map.Parent = Workspace
	self.Map = map

	local environment = Instance.new("Folder")
	environment.Name = "Environment"
	environment.Parent = map

	local zones = Instance.new("Folder")
	zones.Name = "RuleZones"
	zones.Parent = map

	local ground = part(environment, "TownGround", Vector3.new(190, 2, 190), CFrame.new(0, -1, 0), Color3.fromRGB(93, 169, 98), Enum.Material.Grass)
	CollectionService:AddTag(ground, "TownFloor")

	local roadA = part(environment, "MainRoad", Vector3.new(28, 1, 190), CFrame.new(0, 0.05, 0), COLORS.Road, Enum.Material.Asphalt)
	local roadB = part(environment, "CrossRoad", Vector3.new(190, 1, 28), CFrame.new(0, 0.1, 0), COLORS.Road, Enum.Material.Asphalt)
	CollectionService:AddTag(roadA, "TownFloor")
	CollectionService:AddTag(roadB, "TownFloor")
	decorateTown(environment)

	part(environment, "Square", Vector3.new(38, 1.2, 38), CFrame.new(0, 0.65, 0), COLORS.Cream, Enum.Material.Pavement)

	for index = -3, 3 do
		local stripeA = part(environment, "RedCrossing", Vector3.new(2.5, 0.25, 10), CFrame.new(index * 4, 0.75, 20), COLORS.Red)
		local stripeB = part(environment, "RedCrossing", Vector3.new(10, 0.25, 2.5), CFrame.new(20, 0.8, index * 4), COLORS.Red)
		CollectionService:AddTag(stripeA, "RedSurface")
		CollectionService:AddTag(stripeB, "RedSurface")
	end

	local townHall = part(environment, "RuleTower", Vector3.new(8, 24, 8), CFrame.new(0, 12.6, 0), Color3.fromRGB(230, 218, 181), Enum.Material.Brick)
	local clock = part(environment, "TownClock", Vector3.new(9, 6, 1), CFrame.new(0, 18, -4.5), Color3.fromRGB(27, 31, 39))
	addBillboard(clock, "ONE RULE TOWN", COLORS.Yellow)
	CollectionService:AddTag(townHall, "FloorIsLavaSafe")
	part(environment, "TowerCap", Vector3.new(11, 2, 11), CFrame.new(0, 25.5, 0), Color3.fromRGB(44, 57, 74), Enum.Material.Slate)
	part(environment, "ClockFace", Vector3.new(6, 6, 0.4), CFrame.new(0, 18, -5.1), Color3.fromRGB(248, 231, 184), Enum.Material.Neon).CanCollide = false

	createBuilding(environment, "Diner", Vector3.new(-52, 0.5, -52), Vector3.new(32, 17, 26), Color3.fromRGB(240, 111, 126), "TOWN DINER")
	createBuilding(environment, "MiniMarket", Vector3.new(52, 0.5, -52), Vector3.new(30, 15, 24), COLORS.Blue, "MINI MARKET")
	createBuilding(environment, "TownLibrary", Vector3.new(-52, 0.5, 52), Vector3.new(32, 19, 26), Color3.fromRGB(193, 148, 94), "LIBRARY")
	createBuilding(environment, "Garage", Vector3.new(52, 0.5, 52), Vector3.new(34, 16, 26), COLORS.Yellow, "GARAGE")

	for _, position in {
		Vector3.new(-76, 0, -25), Vector3.new(-74, 0, 25), Vector3.new(76, 0, -24),
		Vector3.new(74, 0, 24), Vector3.new(-30, 0, 75), Vector3.new(30, 0, -75),
	} do
		createTree(environment, position)
	end

	-- Elevated objects provide readable safe spots for the lava rule.
	for index, position in {
		Vector3.new(-28, 3, -22), Vector3.new(30, 4, -25), Vector3.new(-24, 5, 31),
		Vector3.new(31, 6, 29), Vector3.new(-70, 4, 0), Vector3.new(70, 5, 0),
		Vector3.new(0, 6, -70), Vector3.new(0, 4, 70),
	} do
		local platform = part(environment, "RaisedPlatform" .. index, Vector3.new(12, 1.5, 12), CFrame.new(position), Color3.fromRGB(116, 135, 153), Enum.Material.Metal)
		CollectionService:AddTag(platform, "FloorIsLavaSafe")
	end

	-- Visible light pools are also physical zones for Stay In The Light.
	for index, position in {
		Vector3.new(-28, 1, 0), Vector3.new(28, 1, 0), Vector3.new(0, 1, -30), Vector3.new(0, 1, 30),
		Vector3.new(-60, 1, 25), Vector3.new(60, 1, -25),
	} do
		local lightZone = part(zones, "LightZone" .. index, Vector3.new(22, 7, 22), CFrame.new(position + Vector3.new(0, 3, 0)), Color3.fromRGB(255, 238, 140), Enum.Material.Neon)
		lightZone.Transparency = 0.82
		lightZone.CanCollide = false
		lightZone.CanQuery = false
		CollectionService:AddTag(lightZone, "LightZone")

		local lamp = Instance.new("PointLight")
		lamp.Color = Color3.fromRGB(255, 235, 174)
		lamp.Brightness = 2
		lamp.Range = 18
		lamp.Parent = lightZone
	end

	local spectator = part(environment, "SpectatorRoof", Vector3.new(32, 1, 20), CFrame.new(0, 34, 62), Color3.fromRGB(42, 49, 62), Enum.Material.Metal)
	addBillboard(spectator, "SPECTATORS", Color3.fromRGB(255, 255, 255))
	self.SpectatorPosition = spectator.Position + Vector3.new(0, 4, 0)
	self.LobbyPosition = Vector3.new(0, 4, -12)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.CFrame = CFrame.new(self.LobbyPosition - Vector3.new(0, 3, 0))
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.Neutral = true
	spawnLocation.Anchored = true
	spawnLocation.Parent = map

	self.RoundSpawns = {
		Vector3.new(-15, 4, -15), Vector3.new(15, 4, -15), Vector3.new(-15, 4, 15), Vector3.new(15, 4, 15),
		Vector3.new(-42, 4, 0), Vector3.new(42, 4, 0), Vector3.new(0, 4, -42), Vector3.new(0, 4, 42),
		Vector3.new(-65, 4, -25), Vector3.new(65, 4, 25), Vector3.new(-25, 4, 65), Vector3.new(25, 4, -65),
	}

	self.BlueObjectSpawns = {
		Vector3.new(-18, 2, -32), Vector3.new(18, 2, 32), Vector3.new(-45, 2, 20),
		Vector3.new(45, 2, -20), Vector3.new(-67, 2, -50), Vector3.new(67, 2, 50),
		Vector3.new(-25, 2, 67), Vector3.new(25, 2, -67), Vector3.new(0, 2, 24),
		Vector3.new(0, 2, -24), Vector3.new(70, 2, -8), Vector3.new(-70, 2, 8),
	}

	self.LavaVisualParts = { ground, roadA, roadB }
	self:SetLavaActive(false)
end

function MapService:IsPointInsideTag(position: Vector3, tag: string): boolean
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(self.Map) then
			local localPoint = instance.CFrame:PointToObjectSpace(position)
			local half = instance.Size / 2
			if math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z then
				return true
			end
		end
	end
	return false
end

function MapService:GetFloorPart(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = Workspace:Raycast(root.Position, Vector3.new(0, -9, 0), params)
	return if result then result.Instance else nil
end

function MapService:SetLavaActive(active: boolean)
	for _, value in self.LavaVisualParts or {} do
		if active then
			value.Color = Color3.fromRGB(255, 83, 32)
			value.Material = Enum.Material.Neon
		else
			if value.Name == "TownGround" then
				value.Color = Color3.fromRGB(93, 169, 98)
				value.Material = Enum.Material.Grass
			else
				value.Color = COLORS.Road
				value.Material = Enum.Material.Asphalt
			end
		end
	end
end

function MapService:GetRoundSpawn(index: number): Vector3
	return self.RoundSpawns[((index - 1) % #self.RoundSpawns) + 1]
end

return MapService

