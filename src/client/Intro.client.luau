--!strict

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local active = false
local runId = 0

local function label(parent: Instance, value: string, position: UDim2, size: UDim2, color: Color3): TextLabel
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.Position = position
	item.Size = size
	item.Font = Enum.Font.GothamBlack
	item.Text = value
	item.TextColor3 = color
	item.TextScaled = true
	item.TextWrapped = true
	item.TextStrokeTransparency = 0.35
	item.Parent = parent
	return item
end

local function playOpening()
	if active then
		return
	end
	active = true
	runId += 1
	local thisRun = runId
	local started = os.clock()
	local camera = workspace.CurrentCamera
	local controls: any = nil
	local cameraTween: Tween? = nil
	local inputConnection: RBXScriptConnection? = nil
	local cameraConnection: RBXScriptConnection? = nil
	local previousSelection = GuiService.SelectedObject

	local gui = Instance.new("ScreenGui")
	gui.Name = "OneRuleOpening"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.fromRGB(9, 15, 29)
	shade.BorderSizePixel = 0
	shade.Active = true
	shade.Parent = gui

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0.11, 0)
	topBar.BackgroundColor3 = Color3.new(0, 0, 0)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 3
	topBar.Parent = gui
	local bottomBar = topBar:Clone()
	bottomBar.AnchorPoint = Vector2.new(0, 1)
	bottomBar.Position = UDim2.fromScale(0, 1)
	bottomBar.Parent = gui

	local title = label(
		gui,
		"ONE RULE TOWN",
		UDim2.new(0.1, 0, 0.14, 0),
		UDim2.new(0.8, 0, 0.16, 0),
		Color3.fromRGB(255, 210, 71)
	)
	title.ZIndex = 4
	local caption = label(
		gui,
		"A PHONE CLIP. A VERY STRANGE TOWN.",
		UDim2.new(0.1, 0, 0.72, 0),
		UDim2.new(0.8, 0, 0.09, 0),
		Color3.fromRGB(255, 247, 220)
	)
	caption.ZIndex = 4

	local loading = label(
		gui,
		"LOADING THE TOWN...",
		UDim2.new(0.2, 0, 0.83, 0),
		UDim2.new(0.6, 0, 0.04, 0),
		Color3.fromRGB(255, 247, 220)
	)
	loading.ZIndex = 4
	local track = Instance.new("Frame")
	track.Position = UDim2.new(0.2, 0, 0.89, 0)
	track.Size = UDim2.new(0.6, 0, 0.018, 0)
	track.BackgroundColor3 = Color3.fromRGB(44, 54, 76)
	track.BorderSizePixel = 0
	track.ZIndex = 4
	track.Parent = gui
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 210, 71)
	fill.BorderSizePixel = 0
	fill.ZIndex = 5
	fill.Parent = track

	local skip = Instance.new("TextButton")
	skip.Name = "Skip"
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -16, 0.12, 8)
	skip.Size = UDim2.fromOffset(110, 42)
	skip.BackgroundColor3 = Color3.fromRGB(40, 64, 102)
	skip.Text = "SKIP"
	skip.TextColor3 = Color3.new(1, 1, 1)
	skip.TextScaled = true
	skip.Font = Enum.Font.GothamBold
	skip.Visible = false
	skip.Selectable = true
	skip.ZIndex = 6
	skip.Parent = gui
	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 10)
	skipCorner.Parent = skip

	local blip = Instance.new("Sound")
	blip.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	blip.Volume = 0.25
	blip.Parent = SoundService
	local function sound()
		if active then
			blip:Play()
		end
	end

	local function finish()
		if not active or runId ~= thisRun then
			return
		end
		active = false
		if cameraTween then
			cameraTween:Cancel()
		end
		if inputConnection then
			inputConnection:Disconnect()
		end
		if cameraConnection then
			cameraConnection:Disconnect()
		end
		if controls then
			pcall(function()
				controls:Enable()
			end)
		end
		if GuiService.SelectedObject == skip then
			GuiService.SelectedObject = previousSelection
		end
		local liveCamera = workspace.CurrentCamera
		if liveCamera then
			liveCamera.CameraType = Enum.CameraType.Custom
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				liveCamera.CameraSubject = humanoid
			end
		end
		-- Character creation can finish after the camera has already been restored.
		local function restoreSubject(character: Model)
			local humanoid = character:WaitForChild("Humanoid", 10)
			if runId == thisRun and not active and humanoid and humanoid:IsA("Humanoid") then
				local current = workspace.CurrentCamera
				if current then
					current.CameraSubject = humanoid
				end
			end
		end
		if player.Character then
			task.spawn(restoreSubject, player.Character)
		else
			local characterConnection: RBXScriptConnection?
			characterConnection = player.CharacterAdded:Connect(function(character)
				if characterConnection then
					characterConnection:Disconnect()
				end
				task.spawn(restoreSubject, character)
			end)
			task.delay(12, function()
				if characterConnection then
					characterConnection:Disconnect()
				end
			end)
		end
		title.Visible = false
		caption.Visible = false
		loading.Visible = false
		track.Visible = false
		skip.Visible = false
		TweenService:Create(shade, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		task.delay(0.3, function()
			gui:Destroy()
		end)
		blip:Destroy()
	end

	skip.Activated:Connect(function()
		if os.clock() - started >= 2 then
			finish()
		end
	end)
	inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not skip.Visible then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonB then
			finish()
		end
	end)
	task.delay(2, function()
		if not active or runId ~= thisRun then
			return
		end
		skip.Visible = true
		if UserInputService.GamepadEnabled then
			GuiService.SelectedObject = skip
		end
	end)
	task.delay(11.5, finish)
	task.delay(14, finish)
	cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if not active or runId ~= thisRun then
			return
		end
		local replacement = workspace.CurrentCamera
		if replacement then
			replacement.CameraType = Enum.CameraType.Scriptable
			if camera then
				replacement.CFrame = camera.CFrame
			end
			camera = replacement
		end
	end)

	task.spawn(function()
		local scripts = player:WaitForChild("PlayerScripts", 3)
		local module = scripts and scripts:WaitForChild("PlayerModule", 3)
		if not module or not module:IsA("ModuleScript") then
			return
		end
		local success, result = pcall(function()
			return require(module):GetControls()
		end)
		if success and result and active and runId == thisRun then
			controls = result
			pcall(function()
				controls:Disable()
			end)
		end
	end)

	task.spawn(function()
		local success, err = xpcall(function()
			local scene = workspace:WaitForChild("OneRuleIntro", 4)
			if not active or runId ~= thisRun then
				return
			end
			camera = workspace.CurrentCamera
			if camera then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = if scene
					then CFrame.lookAt(Vector3.new(6, 7, -240), Vector3.new(3, 4, -258))
					else CFrame.lookAt(Vector3.new(30, 22, -52), Vector3.new(0, 8, 0))
				if scene then
					cameraTween =
						TweenService:Create(camera, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							CFrame = CFrame.lookAt(Vector3.new(5, 6, -248), Vector3.new(4, 5, -259)),
						})
					cameraTween:Play()
				end
				shade.BackgroundTransparency = 0.4
			end

			task.spawn(function()
				local assets: { Instance } = { blip }
				local function collect(container: Instance?)
					if container then
						for _, item in container:GetDescendants() do
							if
								item:IsA("Sound")
								or item:IsA("MeshPart")
								or item:IsA("Decal")
								or item:IsA("Texture")
								or item:IsA("Animation")
								or item:IsA("ImageLabel")
								or item:IsA("ImageButton")
								or item:IsA("SurfaceAppearance")
							then
								table.insert(assets, item)
							end
						end
					end
				end
				collect(scene)
				collect(workspace:FindFirstChild("OneRuleTownMap"))
				local failed = false
				for index, item in assets do
					if not active or runId ~= thisRun then
						return
					end
					local ok = pcall(function()
						ContentProvider:PreloadAsync({ item })
					end)
					if not ok then
						failed = true
					end
					fill.Size = UDim2.fromScale(index / #assets, 1)
				end
				if active and runId == thisRun then
					loading.Text = if failed then "SOME SOUNDS UNAVAILABLE" else "TOWN READY"
				end
			end)

			task.wait(math.max(0, 2.8 - (os.clock() - started)))
			if not active or runId ~= thisRun then
				return
			end
			title.Text = "HUSS HUSS!"
			caption.Text = "THE MAYOR SAYS: ONE RULE. SURVIVE."
			sound()

			task.wait(math.max(0, 4 - (os.clock() - started)))
			if not active or runId ~= thisRun then
				return
			end
			TweenService:Create(shade, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
			task.wait(0.3)
			if not active or runId ~= thisRun then
				return
			end
			camera = workspace.CurrentCamera
			if camera then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = CFrame.lookAt(Vector3.new(45, 33, -55), Vector3.new(0, 10, 0))
				cameraTween = TweenService:Create(camera, TweenInfo.new(4), {
					CFrame = CFrame.lookAt(Vector3.new(25, 22, -30), Vector3.new(0, 10, 0)),
				})
				cameraTween:Play()
			end
			TweenService:Create(shade, TweenInfo.new(0.35), { BackgroundTransparency = 0.7 }):Play()
			title.Text = "ONE RULE TOWN"
			caption.Text = "45 SECONDS. THE WHOLE TOWN IS WATCHING."
			sound()

			task.wait(math.max(0, 8.4 - (os.clock() - started)))
			if not active or runId ~= thisRun then
				return
			end
			title.Text = "REACH THE BLUE COURT"
			caption.Text = "HUSS HUSS! YOUR STORY STARTS NOW."
			if camera then
				cameraTween = TweenService:Create(camera, TweenInfo.new(2.4), {
					CFrame = CFrame.lookAt(Vector3.new(-28, 20, -34), Vector3.new(-58, 1, 0)),
				})
				cameraTween:Play()
			end
			sound()
		end, debug.traceback)
		if not success then
			warn("Opening failed:", err)
			finish()
		end
	end)
end

player:GetAttributeChangedSignal("ReplayIntroRequest"):Connect(playOpening)
task.defer(playOpening)
