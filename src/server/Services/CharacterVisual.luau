--!strict

-- Lightweight characters built from native parts. No avatar assets or animation uploads required.
local CharacterVisual = {}

local function piece(model: Model, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = offset
	item.Color = color
	item.Material = Enum.Material.SmoothPlastic
	item.Shape = shape or Enum.PartType.Block
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = model
	return item
end

function CharacterVisual.Create(name: string, coat: Color3, skin: Color3, mayor: boolean): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = name
	local root = piece(model, "Root", Vector3.new(2.6, 3, 1.5), CFrame.new(0, 4, 0), coat)
	model.PrimaryPart = root
	piece(model, "Head", Vector3.new(2.1, 2.1, 2), root.CFrame * CFrame.new(0, 2.7, 0), skin, Enum.PartType.Ball)
	piece(model, "Hair", Vector3.new(2.35, 0.6, 2.2), root.CFrame * CFrame.new(0, 3.6, 0), if mayor then Color3.fromRGB(34, 37, 47) else Color3.fromRGB(69, 49, 46))
	for _, side in { -1, 1 } do
		piece(model, "Eye", Vector3.new(0.25, 0.32, 0.15), root.CFrame * CFrame.new(side * 0.5, 2.8, -0.98), Color3.fromRGB(31, 39, 52))
		piece(model, "Arm", Vector3.new(0.7, 2.6, 0.8), root.CFrame * CFrame.new(side * 1.75, -0.1, 0), skin)
		piece(model, "Leg", Vector3.new(0.9, 2.2, 1), root.CFrame * CFrame.new(side * 0.65, -2.5, 0), Color3.fromRGB(45, 56, 71))
		piece(model, "Shoe", Vector3.new(1.05, 0.5, 1.5), root.CFrame * CFrame.new(side * 0.65, -3.65, -0.25), Color3.fromRGB(28, 35, 46))
	end
	if mayor then
		piece(model, "HatBrim", Vector3.new(3.1, 0.25, 2.8), root.CFrame * CFrame.new(0, 4, 0), Color3.fromRGB(30, 35, 45))
		piece(model, "TopHat", Vector3.new(2.1, 1.7, 1.9), root.CFrame * CFrame.new(0, 4.8, 0), Color3.fromRGB(30, 35, 45))
		piece(model, "Tie", Vector3.new(0.45, 1.2, 0.2), root.CFrame * CFrame.new(0, 0.45, -0.84), Color3.fromRGB(255, 211, 68))
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 61, 75)
		highlight.FillTransparency = 0.78
		highlight.OutlineColor = Color3.fromRGB(255, 88, 88)
		highlight.Parent = model
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromOffset(160, 38)
	gui.StudsOffset = Vector3.new(0, 5.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 65
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(28, 39, 53)
	label.BackgroundTransparency = 0.22
	label.TextColor3 = if mayor then Color3.fromRGB(255, 172, 172) else Color3.fromRGB(255, 239, 192)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = if mayor then "THE MAYOR" else name .. " · NPC"
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return model, root
end

return CharacterVisual
