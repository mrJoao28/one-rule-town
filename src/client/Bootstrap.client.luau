--!nonstrict

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)
local RuleCatalog = require(ReplicatedStorage.Shared.RuleCatalog)
local MapCatalog = require(ReplicatedStorage.Shared.MapCatalog)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameStateRemote = remotes:WaitForChild("GameState")
local playerStateRemote = remotes:WaitForChild("PlayerState")
local dataRemote = remotes:WaitForChild("DataUpdated")
local purchaseRemote = remotes:WaitForChild("PurchaseRequest")
local cosmeticRemote = remotes:WaitForChild("CosmeticAction")
local useReviveRemote = remotes:WaitForChild("UseRevive")
local voteRemote = remotes:WaitForChild("VoteMap")
local getSnapshot = remotes:WaitForChild("GetSnapshot")

local COLORS = {
	Dark = Color3.fromRGB(25, 29, 38),
	Panel = Color3.fromRGB(38, 44, 56),
	Cream = Color3.fromRGB(255, 245, 214),
	Yellow = Color3.fromRGB(255, 199, 63),
	Red = Color3.fromRGB(232, 64, 74),
	Green = Color3.fromRGB(75, 205, 134),
	Blue = Color3.fromRGB(76, 164, 255),
	Muted = Color3.fromRGB(174, 184, 201),
}

local currentData = nil
local currentState = {
	State = "Booting",
	TimeLeft = 0,
	RuleId = nil,
	AliveCount = 0,
	IsAlive = false,
	CanRevive = false,
}

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 12)
	value.Parent = parent
	return value
end

local function stroke(parent, color, thickness, transparency)
	local value = Instance.new("UIStroke")
	value.Color = color or Color3.new(1, 1, 1)
	value.Thickness = thickness or 2
	value.Transparency = transparency or 0
	value.Parent = parent
	return value
end

local function textLabel(parent, name, text, size, position, font, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position or UDim2.new()
	label.Font = font or Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function button(parent, name, text, size, position, color)
	local value = Instance.new("TextButton")
	value.Name = name
	value.Size = size
	value.Position = position or UDim2.new()
	value.BackgroundColor3 = color or COLORS.Blue
	value.AutoButtonColor = true
	value.Font = Enum.Font.GothamBlack
	value.Text = text
	value.TextColor3 = Color3.new(1, 1, 1)
	value.TextScaled = true
	value.Parent = parent
	corner(value, 10)
	stroke(value, Color3.new(1, 1, 1), 2, 0.72)
	return value
end

local gui = Instance.new("ScreenGui")
gui.Name = "OneRuleTownUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Name = "ResponsiveScale"
scale.Parent = gui

local function updateScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.68, 1.15)
end
updateScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end

local vignette = Instance.new("Frame")
vignette.Name = "DangerOverlay"
vignette.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
vignette.BackgroundColor3 = COLORS.Red
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 1
vignette.Parent = gui

local ruleCard = Instance.new("Frame")
ruleCard.Name = "RuleCard"
ruleCard.AnchorPoint = Vector2.new(0.5, 0)
ruleCard.Position = UDim2.new(0.5, 0, 0, 24)
ruleCard.Size = UDim2.fromOffset(600, 150)
ruleCard.BackgroundColor3 = COLORS.Dark
ruleCard.BackgroundTransparency = 0.04
ruleCard.Parent = gui
corner(ruleCard, 18)
local ruleStroke = stroke(ruleCard, COLORS.Yellow, 4, 0)

local stateLabel = textLabel(ruleCard, "State", "WAITING FOR THE TOWN", UDim2.fromOffset(420, 25), UDim2.fromOffset(90, 8), Enum.Font.GothamBold, COLORS.Muted)
local ruleLabel = textLabel(ruleCard, "Rule", "ONE RULE TOWN", UDim2.fromOffset(520, 52), UDim2.fromOffset(40, 34), Enum.Font.GothamBlack, COLORS.Cream)
local descriptionLabel = textLabel(ruleCard, "Description", "Every round, the town makes one absurd rule.", UDim2.fromOffset(445, 40), UDim2.fromOffset(40, 91), Enum.Font.GothamMedium, Color3.new(1, 1, 1))
local timerLabel = textLabel(ruleCard, "Timer", "--", UDim2.fromOffset(75, 48), UDim2.fromOffset(515, 90), Enum.Font.GothamBlack, COLORS.Yellow)

local dangerPanel = Instance.new("Frame")
dangerPanel.Name = "RuleDanger"
dangerPanel.AnchorPoint = Vector2.new(0.5, 0)
dangerPanel.Position = UDim2.new(0.5, 0, 0, 182)
dangerPanel.Size = UDim2.fromOffset(360, 46)
dangerPanel.BackgroundColor3 = COLORS.Dark
dangerPanel.Visible = false
dangerPanel.Parent = gui
corner(dangerPanel, 10)
textLabel(dangerPanel, "Warning", "RULE DANGER — GET SAFE!", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 2), Enum.Font.GothamBlack, COLORS.Cream)
local dangerTrack = Instance.new("Frame")
dangerTrack.Name = "Track"
dangerTrack.Position = UDim2.fromOffset(10, 29)
dangerTrack.Size = UDim2.new(1, -20, 0, 9)
dangerTrack.BackgroundColor3 = COLORS.Panel
dangerTrack.Parent = dangerPanel
corner(dangerTrack, 5)
local dangerFill = Instance.new("Frame")
dangerFill.Name = "Fill"
dangerFill.Size = UDim2.fromScale(0, 1)
dangerFill.BackgroundColor3 = COLORS.Red
dangerFill.Parent = dangerTrack
corner(dangerFill, 5)

local hunterBadge = textLabel(gui, "HunterStatus", "YOU ARE A TOWN HUNTER · TAG SURVIVORS", UDim2.new(0.8, 0, 0, 48), UDim2.new(0.1, 0, 0, 240), Enum.Font.GothamBlack, COLORS.Yellow)
hunterBadge.BackgroundColor3 = COLORS.Red
hunterBadge.BackgroundTransparency = 0.12
hunterBadge.Visible = false
corner(hunterBadge, 10)
local function updateHunter()
	hunterBadge.Visible = currentState.State == "Active" and player:GetAttribute("TownHunter") == true
end

local function updateDanger(progress)
	local visible = currentState.State == "Active" and player:GetAttribute("AliveInRound") == true and progress > 0
	dangerPanel.Visible = visible
	if visible then
		dangerFill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
	end
end

local aliveBadge = Instance.new("Frame")
aliveBadge.Size = UDim2.fromOffset(180, 50)
aliveBadge.Position = UDim2.fromOffset(25, 25)
aliveBadge.BackgroundColor3 = COLORS.Dark
aliveBadge.Parent = gui
corner(aliveBadge, 12)
local aliveLabel = textLabel(aliveBadge, "Alive", "0 ALIVE", UDim2.fromScale(1, 1), nil, Enum.Font.GothamBlack, Color3.new(1, 1, 1))

local statsBadge = Instance.new("Frame")
statsBadge.AnchorPoint = Vector2.new(1, 0)
statsBadge.Position = UDim2.new(1, -25, 0, 25)
statsBadge.Size = UDim2.fromOffset(220, 74)
statsBadge.BackgroundColor3 = COLORS.Dark
statsBadge.Parent = gui
corner(statsBadge, 12)
local tokensLabel = textLabel(statsBadge, "Tokens", "0 TOWN TOKENS", UDim2.new(1, -16, 0, 32), UDim2.fromOffset(8, 4), Enum.Font.GothamBlack, COLORS.Yellow)
local winsLabel = textLabel(statsBadge, "Wins", "0 WINS", UDim2.new(1, -16, 0, 25), UDim2.fromOffset(8, 40), Enum.Font.GothamBold, COLORS.Muted)

local notification = textLabel(gui, "Notification", "", UDim2.fromOffset(620, 80), UDim2.new(0.5, -310, 0.67, -40), Enum.Font.GothamBlack, Color3.new(1, 1, 1))
notification.BackgroundColor3 = COLORS.Dark
notification.BackgroundTransparency = 1
notification.TextTransparency = 1
notification.ZIndex = 20
corner(notification, 16)

local function notify(text, color, duration)
	notification.Text = text
	notification.TextColor3 = color or Color3.new(1, 1, 1)
	notification.BackgroundTransparency = 0.08
	notification.TextTransparency = 0
	notification.Position = UDim2.new(0.5, -310, 0.62, -40)
	TweenService:Create(notification, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, -310, 0.57, -40) }):Play()
	local token = os.clock()
	notification:SetAttribute("Token", token)
	task.delay(duration or 2.5, function()
		if notification:GetAttribute("Token") ~= token then return end
		TweenService:Create(notification, TweenInfo.new(0.25), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	end)
end

local menuBar = Instance.new("Frame")
menuBar.AnchorPoint = Vector2.new(0.5, 1)
menuBar.Position = UDim2.new(0.5, 0, 1, -22)
menuBar.Size = UDim2.new(1, -20, 0, 62)
menuBar.BackgroundTransparency = 1
menuBar.Parent = gui
local menuLimit = Instance.new("UISizeConstraint")
menuLimit.MaxSize = Vector2.new(540, 62)
menuLimit.Parent = menuBar
local shopButton = button(menuBar, "Shop", "SHOP", UDim2.new(0.2, -4, 0, 58), UDim2.new(0, 0, 0, 0), COLORS.Blue)
local cosmeticsButton = button(menuBar, "Cosmetics", "COSMETICS", UDim2.new(0.31, -4, 0, 58), UDim2.new(0.21, 0, 0, 0), Color3.fromRGB(168, 91, 230))
local helpButton = button(menuBar, "Help", "HOW TO PLAY", UDim2.new(0.23, -4, 0, 58), UDim2.new(0.53, 0, 0, 0), COLORS.Green)
local introButton = button(menuBar, "ReplayIntro", "REPLAY INTRO", UDim2.new(0.23, -4, 0, 58), UDim2.new(0.77, 0, 0, 0), COLORS.Yellow)

local votePanel = Instance.new("Frame")
votePanel.Name = "MapVote"
votePanel.AnchorPoint = Vector2.new(0.5, 0)
votePanel.Position = UDim2.new(0.5, 0, 0, 240)
votePanel.Size = UDim2.new(0.9, 0, 0, 125)
votePanel.BackgroundColor3 = COLORS.Dark
votePanel.Visible = false
votePanel.Parent = gui
corner(votePanel, 12)
local voteLimit = Instance.new("UISizeConstraint")
voteLimit.MaxSize = Vector2.new(650, 125)
voteLimit.Parent = votePanel
textLabel(votePanel, "Title", "VOTE FOR THE NEXT CITY", UDim2.new(1, -12, 0, 32), UDim2.fromOffset(6, 3), Enum.Font.GothamBlack, COLORS.Yellow)
local voteButtons = {}
local voteCounts = {}
local selectedVote = nil
local function updateVotes()
	votePanel.Visible = currentState.State == "Intermission"
	for id, map in MapCatalog do
		local entry = voteButtons[id]
		entry.Text = map.Name .. "\n" .. tostring(voteCounts[id] or 0) .. " VOTES"
		entry.BackgroundColor3 = if selectedVote == id then COLORS.Green else COLORS.Blue
	end
end
for id in MapCatalog do
	local entry = button(votePanel, "Map" .. id, "", UDim2.new(0.31, -4, 0, 75), UDim2.new((id - 1) / 3 + 0.015, 0, 0, 39), COLORS.Blue)
	entry.Activated:Connect(function()
		if currentState.State ~= "Intermission" then return end
		selectedVote = id
		updateVotes()
		voteRemote:FireServer(id)
	end)
	voteButtons[id] = entry
end

local function makeModal(name, titleText)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.fromOffset(620, 480)
	panel.BackgroundColor3 = COLORS.Panel
	panel.Visible = false
	panel.ZIndex = 30
	panel.Parent = gui
	corner(panel, 20)
	stroke(panel, Color3.new(1, 1, 1), 3, 0.75)
	textLabel(panel, "Title", titleText, UDim2.new(1, -100, 0, 55), UDim2.fromOffset(24, 12), Enum.Font.GothamBlack, COLORS.Cream).ZIndex = 31
	local close = button(panel, "Close", "X", UDim2.fromOffset(48, 48), UDim2.new(1, -62, 0, 14), COLORS.Red)
	close.ZIndex = 32
	close.Activated:Connect(function() panel.Visible = false end)
	return panel
end

local shopPanel = makeModal("ShopPanel", "TOWN SHOP")
local shopContent = Instance.new("ScrollingFrame")
shopContent.Name = "Items"
shopContent.Position = UDim2.fromOffset(24, 78)
shopContent.Size = UDim2.new(1, -48, 1, -100)
shopContent.BackgroundTransparency = 1
shopContent.BorderSizePixel = 0
shopContent.ScrollBarThickness = 6
shopContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopContent.CanvasSize = UDim2.new()
shopContent.ZIndex = 31
shopContent.Parent = shopPanel
local shopList = Instance.new("UIListLayout")
shopList.Padding = UDim.new(0, 10)
shopList.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopList.Parent = shopContent
shopList.SortOrder = Enum.SortOrder.LayoutOrder

local function shopItem(text, category, key, enabled)
	local value = button(shopContent, key, text, UDim2.fromOffset(530, 58), nil, enabled and COLORS.Blue or Color3.fromRGB(90, 96, 108))
	value.LayoutOrder = 10
	value.ZIndex = 31
	if enabled then
		value.Activated:Connect(function() purchaseRemote:FireServer(category, key) end)
		local id = if category == "Pass" then Config.Monetization.GamePasses[key] else Config.Monetization.DeveloperProducts[key].Id
		task.spawn(function()
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfoAsync(id, if category == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
			end)
			if success and type(info.PriceInRobux) == "number" then
				value.Text = text .. "  •  " .. tostring(info.PriceInRobux) .. " ROBUX"
			end
			if category == "Pass" and player:GetAttribute(key) then
				value.Text = text .. "  •  OWNED"
				value.Active = false
			end
		end)
		if category == "Pass" then
			player:GetAttributeChangedSignal(key):Connect(function()
				if player:GetAttribute(key) then
					value.Text = text .. "  •  OWNED"
					value.Active = false
				end
			end)
		end
	else
		value.Text = text .. "  •  NOT CONFIGURED"
		value.AutoButtonColor = false
	end
	return value
end

shopItem("REVIVE CREDIT", "Product", "Revive", Config.Monetization.DeveloperProducts.Revive.Id > 0)
shopItem("250 TOWN TOKENS", "Product", "TokensSmall", Config.Monetization.DeveloperProducts.TokensSmall.Id > 0)
shopItem("750 TOWN TOKENS", "Product", "TokensMedium", Config.Monetization.DeveloperProducts.TokensMedium.Id > 0)
shopItem("2,000 TOWN TOKENS", "Product", "TokensLarge", Config.Monetization.DeveloperProducts.TokensLarge.Id > 0)
shopItem("VIP COSMETICS PASS", "Pass", "VIP", Config.Monetization.GamePasses.VIP > 0)
shopItem("DOUBLE TOKENS PASS", "Pass", "DoubleTokens", Config.Monetization.GamePasses.DoubleTokens > 0)

local cosmeticsPanel = makeModal("CosmeticsPanel", "COSMETICS")
local helpPanel = makeModal("HelpPanel", "HOW TO PLAY")
textLabel(helpPanel, "Steps", "1  READ the town rule before the round begins.\n\n2  FOLLOW it until the timer ends. The red danger bar shows when you are close to breaking a timed rule.\n\n3  SURVIVE to earn Town Tokens. Play solo or team up with friends and town residents.\n\nFind the blue court for HUSS HUSS!", UDim2.new(1, -60, 1, -120), UDim2.fromOffset(30, 85), Enum.Font.GothamMedium, COLORS.Cream).ZIndex = 31
local helpOkay = button(helpPanel, "GotIt", "GOT IT!", UDim2.fromOffset(180, 50), UDim2.new(0.5, -90, 1, -67), COLORS.Green)
helpOkay.ZIndex = 32
helpOkay.Activated:Connect(function() helpPanel.Visible = false end)
local cosmeticScroll = Instance.new("ScrollingFrame")
cosmeticScroll.Name = "Items"
cosmeticScroll.Position = UDim2.fromOffset(24, 78)
cosmeticScroll.Size = UDim2.new(1, -48, 1, -100)
cosmeticScroll.BackgroundTransparency = 1
cosmeticScroll.BorderSizePixel = 0
cosmeticScroll.ScrollBarThickness = 6
cosmeticScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
cosmeticScroll.CanvasSize = UDim2.new()
cosmeticScroll.ZIndex = 31
cosmeticScroll.Parent = cosmeticsPanel
local cosmeticLayout = Instance.new("UIListLayout")
cosmeticLayout.Padding = UDim.new(0, 9)
cosmeticLayout.Parent = cosmeticScroll

local cosmeticButtons = {}
local cosmeticIds = {}
for id in pairs(Config.Cosmetics) do table.insert(cosmeticIds, id) end
table.sort(cosmeticIds, function(a, b) return Config.Cosmetics[a].Price < Config.Cosmetics[b].Price end)
for _, id in cosmeticIds do
	local cosmetic = Config.Cosmetics[id]
	local value = button(cosmeticScroll, id, cosmetic.DisplayName, UDim2.new(1, -10, 0, 58), nil, cosmetic.Color)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextSize = 18
	value.TextScaled = false
	value.ZIndex = 32
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.Parent = value
	cosmeticButtons[id] = value
	value.Activated:Connect(function()
		local owned = currentData and currentData.OwnedCosmetics and currentData.OwnedCosmetics[id]
		cosmeticRemote:FireServer(if owned then "Equip" else "Buy", id)
	end)
end

local revivePanel = Instance.new("Frame")
revivePanel.AnchorPoint = Vector2.new(0.5, 1)
revivePanel.Position = UDim2.new(0.5, 0, 1 / scale.Scale, -100)
revivePanel.Size = UDim2.fromOffset(440, 125)
revivePanel.BackgroundColor3 = COLORS.Dark
revivePanel.Visible = false
revivePanel.ZIndex = 25
revivePanel.Parent = gui
corner(revivePanel, 16)
stroke(revivePanel, COLORS.Red, 3, 0)
local reviveTitle = textLabel(revivePanel, "Title", "YOU BROKE THE RULE", UDim2.new(1, -20, 0, 35), UDim2.fromOffset(10, 8), Enum.Font.GothamBlack, COLORS.Red)
reviveTitle.ZIndex = 26
local useReviveButton = button(revivePanel, "Use", "USE REVIVE", UDim2.fromOffset(190, 58), UDim2.fromOffset(20, 53), COLORS.Green)
useReviveButton.ZIndex = 26
local buyReviveButton = button(revivePanel, "Buy", "BUY REVIVE", UDim2.fromOffset(190, 58), UDim2.fromOffset(230, 53), COLORS.Blue)
buyReviveButton.ZIndex = 26
useReviveButton.Activated:Connect(function() useReviveRemote:FireServer() end)
buyReviveButton.Activated:Connect(function() purchaseRemote:FireServer("Product", "Revive") end)

shopButton.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	cosmeticsPanel.Visible = false
	helpPanel.Visible = false
end)
cosmeticsButton.Activated:Connect(function()
	cosmeticsPanel.Visible = not cosmeticsPanel.Visible
	shopPanel.Visible = false
	helpPanel.Visible = false
end)
helpButton.Activated:Connect(function()
	helpPanel.Visible = not helpPanel.Visible
	shopPanel.Visible = false
	cosmeticsPanel.Visible = false
end)
introButton.Activated:Connect(function()
	if currentState.State ~= "Results" and currentState.State ~= "WaitingForPlayers" then
		notify("REPLAY AFTER THE ROUND", COLORS.Yellow, 2)
		return
	end
	shopPanel.Visible = false
	cosmeticsPanel.Visible = false
	helpPanel.Visible = false
	player:SetAttribute("ReplayIntroRequest", (player:GetAttribute("ReplayIntroRequest") or 0) + 1)
end)

local function updateCosmetics()
	for id, value in pairs(cosmeticButtons) do
		local cosmetic = Config.Cosmetics[id]
		local owned = currentData and currentData.OwnedCosmetics and currentData.OwnedCosmetics[id]
		local equipped = currentData and currentData.EquippedCosmetic == id
		local suffix
		if equipped then
			suffix = "  •  EQUIPPED"
		elseif owned then
			suffix = "  •  EQUIP"
		elseif cosmetic.RequiresVIP then
			suffix = "  •  VIP"
		else
			suffix = "  •  " .. cosmetic.Price .. " TOKENS"
		end
		value.Text = cosmetic.DisplayName .. suffix
	end
end

local STATE_TEXT = {
	Booting = "THE TOWN IS WAKING UP",
	WaitingForPlayers = "WAITING FOR PLAYERS",
	Intermission = "NEXT RULE IN",
	RuleReveal = "THE TOWN HAS ONE RULE",
	Active = "FOLLOW THE RULE",
	Results = "ROUND RESULTS",
}

local function updateRevive()
	currentState.IsAlive = player:GetAttribute("AliveInRound") == true
	local canRevive = currentState.State == "Active"
		and not currentState.IsAlive
		and currentState.CanRevive
		and (currentState.TimeLeft or 0) > Config.ReviveCutoffSeconds
	revivePanel.Visible = canRevive
	if canRevive then
		local credits = currentData and currentData.ReviveCredits or 0
		useReviveButton.Text = "USE REVIVE (" .. credits .. ")"
		useReviveButton.Visible = credits > 0
		buyReviveButton.Visible = Config.Monetization.DeveloperProducts.Revive.Id > 0
		if not useReviveButton.Visible and not buyReviveButton.Visible then
			reviveTitle.Text = "REVIVE PRODUCT NOT CONFIGURED"
		end
	end
end

local function applyState(payload)
	local previousState = currentState.State
	for key, value in pairs(payload) do currentState[key] = value end
	if previousState ~= currentState.State and currentState.State == "Intermission" then
		selectedVote = nil
		voteCounts = {}
	end
	if payload.Voting then
		voteCounts = payload.Voting.Counts or {}
		selectedVote = payload.Voting.OwnVote
	end
	updateVotes()
	updateHunter()
	if currentState.State ~= "Active" then updateDanger(0) end
	if previousState ~= currentState.State and currentState.State == "RuleReveal" then
		helpPanel.Visible = false
		shopPanel.Visible = false
		cosmeticsPanel.Visible = false
	end
	stateLabel.Text = STATE_TEXT[currentState.State] or string.upper(tostring(currentState.State))
	if currentState.SpecialRound and currentState.State == "Active" then
		stateLabel.Text = "SPECIAL ROUND · 2X TOKENS"
	end
	timerLabel.Text = currentState.TimeLeft and tostring(currentState.TimeLeft) or "--"
	aliveLabel.Text = tostring(currentState.AliveCount or 0) .. " ALIVE"

	local rule = currentState.RuleId and RuleCatalog[currentState.RuleId]
	if rule and (currentState.State == "RuleReveal" or currentState.State == "Active") then
		ruleLabel.Text = rule.DisplayName
		descriptionLabel.Text = rule.Description
		ruleLabel.TextColor3 = rule.Accent
		timerLabel.TextColor3 = rule.Accent
		ruleStroke.Color = rule.Accent
	else
		ruleLabel.Text = currentState.State == "Results" and "THE TOWN HAS DECIDED" or "ONE RULE TOWN"
		descriptionLabel.Text = currentState.State == "Intermission" and ("Next: " .. tostring(currentState.MapName or "the town")) or "Read the rule. Follow it. Survive."
		ruleLabel.TextColor3 = COLORS.Cream
		timerLabel.TextColor3 = COLORS.Yellow
		ruleStroke.Color = COLORS.Yellow
	end

	if payload.Survivors then
		if #payload.Survivors == 0 then
			notify("NOBODY SURVIVED", COLORS.Red, 4)
		else
			notify("SURVIVORS: " .. table.concat(payload.Survivors, ", "), COLORS.Green, 4)
		end
	end
	updateRevive()
end

local function applyData(data)
	if not data then return end
	currentData = data
	tokensLabel.Text = tostring(data.Coins or 0) .. " TOWN TOKENS"
	winsLabel.Text = tostring(data.Wins or 0) .. " WINS"
	updateCosmetics()
	updateRevive()
end

gameStateRemote.OnClientEvent:Connect(function(payload)
	if payload.Type == "State" then
		applyState(payload)
	elseif payload.Type == "MapVote" then
		voteCounts = payload.Counts or {}
		updateVotes()
	elseif payload.Type == "Effect" then
		if payload.Effect == "Bell" then
			notify("🔔 FREEZE!", COLORS.Yellow, 2.3)
			vignette.BackgroundColor3 = COLORS.Blue
			vignette.BackgroundTransparency = 0.78
			TweenService:Create(vignette, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		elseif payload.Effect == "LavaWarning" then
			notify("THE FLOOR HEATS UP IN 8 SECONDS", Color3.fromRGB(255, 130, 48), 3)
		elseif payload.Effect == "LavaActive" then
			notify("THE FLOOR IS LAVA!", Color3.fromRGB(255, 90, 35), 2)
		elseif payload.Effect == "TownSprint" then
			notify("MINI EVENT: THE TOWN IS SPRINTING!", COLORS.Green, 3)
		elseif payload.Effect == "TokenShower" then
			notify("MINI EVENT: COLLECT THE GOLD TOKENS!", COLORS.Yellow, 3)
		end
	end
end)

playerStateRemote.OnClientEvent:Connect(function(payload)
	if payload.Type == "Danger" then
		updateDanger(payload.Progress or 0)
	elseif payload.Type == "DailyWin" then
		notify("FIRST WIN TODAY! +" .. tostring(payload.Amount) .. " TOKENS", COLORS.Yellow, 4)
	elseif payload.Type == "Eliminated" then
		updateDanger(0)
		currentState.AliveCount = payload.AliveCount or currentState.AliveCount
		aliveLabel.Text = tostring(currentState.AliveCount) .. " ALIVE"
		if payload.UserId == player.UserId then
			currentState.IsAlive = false
			currentState.CanRevive = currentState.TimeLeft > Config.ReviveCutoffSeconds
			notify("RULE BROKEN!\n" .. payload.Reason, COLORS.Red, 3.5)
			task.delay(3.5, function()
				if player:GetAttribute("TownHunter") and currentState.State == "Active" then
					notify("JOIN THE MAYOR! TAG SURVIVORS FOR TOKENS", COLORS.Yellow, 3)
				end
			end)
			vignette.BackgroundColor3 = COLORS.Red
			vignette.BackgroundTransparency = 0.65
			TweenService:Create(vignette, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
			updateRevive()
		else
			notify(payload.Name .. " BROKE THE RULE", COLORS.Muted, 1.8)
		end
	elseif payload.Type == "Revived" then
		if payload.UserId == player.UserId then
			currentState.IsAlive = true
			currentState.CanRevive = false
			revivePanel.Visible = false
			notify("BACK IN THE ROUND!", COLORS.Green, 2)
		else
			notify(payload.Name .. " RETURNED", COLORS.Green, 1.5)
		end
	elseif payload.Type == "HunterTag" then
		notify(payload.Name .. " TAGGED " .. payload.Target, COLORS.Yellow, 1.5)
	end
end)

dataRemote.OnClientEvent:Connect(applyData)
player:GetAttributeChangedSignal("AliveInRound"):Connect(function()
	currentState.IsAlive = player:GetAttribute("AliveInRound") == true
	if currentState.IsAlive then currentState.CanRevive = false end
	if not currentState.IsAlive then updateDanger(0) end
	updateRevive()
end)
player:GetAttributeChangedSignal("TownHunter"):Connect(updateHunter)

task.spawn(function()
	local success, snapshot = pcall(function() return getSnapshot:InvokeServer() end)
	if success and snapshot then
		applyState(snapshot)
		applyData(snapshot.Data)
		if snapshot.State == "Intermission" or snapshot.State == "WaitingForPlayers" then
			helpPanel.Visible = true
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then
		shopPanel.Visible = not shopPanel.Visible
		cosmeticsPanel.Visible = false
	elseif input.KeyCode == Enum.KeyCode.C then
		cosmeticsPanel.Visible = not cosmeticsPanel.Visible
		shopPanel.Visible = false
	end
end)
