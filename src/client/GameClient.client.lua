local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local legacyClientNames = {
	ClientExample = true,
	ShopClient = true,
	PropertyClient = true,
	VehicleClient = true,
	DealershipClient = true,
	GarageClient = true,
}

for _, child in ipairs(script.Parent.Parent:GetChildren()) do
	if child:IsA("LocalScript") and legacyClientNames[child.Name] then
		child.Disabled = true
		child:Destroy()
	end
end

local hscFolder = ReplicatedStorage:WaitForChild("HSC")
local Config = require(hscFolder:WaitForChild("Config"))
local remotes = hscFolder:WaitForChild("Remotes")

local function waitForRemote(name, className)
	local remote = remotes:WaitForChild(name)
	assert(remote:IsA(className), name .. " precisa ser " .. className)
	return remote
end

local currencyChanged = waitForRemote("CurrencyChanged", "RemoteEvent")
local requestRecentTransactions = waitForRemote("RequestRecentTransactions", "RemoteFunction")
local requestDailyRewardStatus = waitForRemote("RequestDailyRewardStatus", "RemoteFunction")
local dailyRewardClaim = waitForRemote("DailyRewardClaim", "RemoteEvent")
local dailyRewardResult = waitForRemote("DailyRewardResult", "RemoteEvent")
local requestAchievements = waitForRemote("RequestAchievements", "RemoteFunction")
local achievementUnlocked = waitForRemote("AchievementUnlocked", "RemoteEvent")
local requestEvents = waitForRemote("RequestEvents", "RemoteFunction")
local eventParticipationRequest = waitForRemote("EventParticipationRequest", "RemoteEvent")
local eventParticipationResult = waitForRemote("EventParticipationResult", "RemoteEvent")
local requestFashionContest = waitForRemote("RequestFashionContest", "RemoteFunction")
local fashionContestRequest = waitForRemote("FashionContestRequest", "RemoteEvent")
local fashionContestResult = waitForRemote("FashionContestResult", "RemoteEvent")
local eventInviteRequest = waitForRemote("EventInviteRequest", "RemoteEvent")
local eventInviteResponse = waitForRemote("EventInviteResponse", "RemoteEvent")
local eventInviteReceived = waitForRemote("EventInviteReceived", "RemoteEvent")
local eventInviteResult = waitForRemote("EventInviteResult", "RemoteEvent")
local requestAdminStatus = waitForRemote("RequestAdminStatus", "RemoteFunction")
local requestModerationLogs = waitForRemote("RequestModerationLogs", "RemoteFunction")
local adminAction = waitForRemote("AdminAction", "RemoteEvent")
local adminActionResult = waitForRemote("AdminActionResult", "RemoteEvent")
local requestShopItems = waitForRemote("RequestShopItems", "RemoteFunction")
local requestOwnedItems = waitForRemote("RequestOwnedItems", "RemoteFunction")
local itemEquipmentRequest = waitForRemote("ItemEquipmentRequest", "RemoteEvent")
local itemEquipmentResult = waitForRemote("ItemEquipmentResult", "RemoteEvent")
local shopPurchase = waitForRemote("ShopPurchase", "RemoteEvent")
local requestMarketData = waitForRemote("RequestMarketData", "RemoteFunction")
local marketAction = waitForRemote("MarketAction", "RemoteEvent")
local marketActionResult = waitForRemote("MarketActionResult", "RemoteEvent")
local monetizationResult = waitForRemote("MonetizationResult", "RemoteEvent")
local requestApprovedCreations = waitForRemote("RequestApprovedCreations", "RemoteFunction")
local requestPendingCreations = waitForRemote("RequestPendingCreations", "RemoteFunction")
local creationReviewRequest = waitForRemote("CreationReviewRequest", "RemoteEvent")
local creationReviewResult = waitForRemote("CreationReviewResult", "RemoteEvent")
local requestPropertyCatalog = waitForRemote("RequestPropertyCatalog", "RemoteFunction")
local propertyPurchase = waitForRemote("PropertyPurchase", "RemoteEvent")
local requestOwnedProperties = waitForRemote("RequestOwnedProperties", "RemoteFunction")
local requestPropertyEntry = waitForRemote("RequestPropertyEntry", "RemoteEvent")
local propertyStyleRequest = waitForRemote("PropertyStyleRequest", "RemoteEvent")
local propertyStyleResult = waitForRemote("PropertyStyleResult", "RemoteEvent")
local requestPropertyDecorCatalog = waitForRemote("RequestPropertyDecorCatalog", "RemoteFunction")
local propertyDecorRequest = waitForRemote("PropertyDecorRequest", "RemoteEvent")
local propertyDecorResult = waitForRemote("PropertyDecorResult", "RemoteEvent")
local propertyInviteRequest = waitForRemote("PropertyInviteRequest", "RemoteEvent")
local propertyInviteResponse = waitForRemote("PropertyInviteResponse", "RemoteEvent")
local propertyInviteReceived = waitForRemote("PropertyInviteReceived", "RemoteEvent")
local propertyInviteResult = waitForRemote("PropertyInviteResult", "RemoteEvent")
local requestVehicleCatalog = waitForRemote("RequestVehicleCatalog", "RemoteFunction")
local requestVehiclePaintCatalog = waitForRemote("RequestVehiclePaintCatalog", "RemoteFunction")
local vehiclePaintRequest = waitForRemote("VehiclePaintRequest", "RemoteEvent")
local vehiclePaintResult = waitForRemote("VehiclePaintResult", "RemoteEvent")
local vehiclePurchase = waitForRemote("VehiclePurchase", "RemoteEvent")
local vehicleTestDriveRequest = waitForRemote("VehicleTestDriveRequest", "RemoteEvent")
local vehicleTestDriveResult = waitForRemote("VehicleTestDriveResult", "RemoteEvent")
local requestOwnedVehicles = waitForRemote("RequestOwnedVehicles", "RemoteFunction")
local requestActiveVehicle = waitForRemote("RequestActiveVehicle", "RemoteFunction")
local vehicleStoreRequest = waitForRemote("VehicleStoreRequest", "RemoteEvent")
local vehicleStoreResult = waitForRemote("VehicleStoreResult", "RemoteEvent")
local requestVehicleSpawn = waitForRemote("RequestVehicleSpawn", "RemoteEvent")
local vehicleSpawnResult = waitForRemote("VehicleSpawnResult", "RemoteEvent")
local vehicleDrive = waitForRemote("VehicleDrive", "RemoteEvent")
local requestWorkJobs = waitForRemote("RequestWorkJobs", "RemoteFunction")
local requestActiveWork = waitForRemote("RequestActiveWork", "RemoteFunction")
local workJobRequest = waitForRemote("WorkJobRequest", "RemoteEvent")
local workJobResult = waitForRemote("WorkJobResult", "RemoteEvent")
local requestClubStatus = waitForRemote("RequestClubStatus", "RemoteFunction")
local clubPerformanceRequest = waitForRemote("ClubPerformanceRequest", "RemoteEvent")
local clubPerformanceResult = waitForRemote("ClubPerformanceResult", "RemoteEvent")
local regionChanged = waitForRemote("RegionChanged", "RemoteEvent")

local COLORS = {
	Background = Color3.fromRGB(17, 18, 22),
	Panel = Color3.fromRGB(27, 29, 35),
	PanelLight = Color3.fromRGB(38, 40, 47),
	Gold = Color3.fromRGB(221, 183, 93),
	Text = Color3.fromRGB(244, 241, 233),
	Muted = Color3.fromRGB(174, 174, 178),
	Success = Color3.fromRGB(125, 207, 151),
	Error = Color3.fromRGB(235, 117, 117),
}

local playerGui = player:WaitForChild("PlayerGui")
local previousGui = playerGui:FindFirstChild("SocietyInterface")
if previousGui then
	previousGui:Destroy()
end

local legacyShopGui = playerGui:FindFirstChild("ShopGui")
if legacyShopGui and legacyShopGui:IsA("ScreenGui") then
	legacyShopGui.Enabled = false
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SocietyInterface"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

local regionBanner = Instance.new("Frame")
regionBanner.Name = "RegionBanner"
regionBanner.AnchorPoint = Vector2.new(0.5, 0)
regionBanner.Position = UDim2.new(0.5, 0, 0, 78)
regionBanner.Size = UDim2.fromOffset(320, 52)
regionBanner.BackgroundColor3 = COLORS.Background
regionBanner.BackgroundTransparency = 1
regionBanner.BorderSizePixel = 0
regionBanner.Visible = false
regionBanner.Parent = screenGui
local regionBannerCorner = Instance.new("UICorner")
regionBannerCorner.CornerRadius = UDim.new(0, 10)
regionBannerCorner.Parent = regionBanner
local regionBannerStroke = Instance.new("UIStroke")
regionBannerStroke.Color = COLORS.Gold
regionBannerStroke.Transparency = 1
regionBannerStroke.Thickness = 1
regionBannerStroke.Parent = regionBanner

local regionBannerLabel = Instance.new("TextLabel")
regionBannerLabel.Name = "RegionName"
regionBannerLabel.Size = UDim2.new(1, -20, 1, 0)
regionBannerLabel.Position = UDim2.new(0, 10, 0, 0)
regionBannerLabel.BackgroundTransparency = 1
regionBannerLabel.Font = Enum.Font.GothamBold
regionBannerLabel.Text = ""
regionBannerLabel.TextColor3 = COLORS.Gold
regionBannerLabel.TextSize = 17
regionBannerLabel.TextWrapped = true
regionBannerLabel.TextTransparency = 1
regionBannerLabel.Parent = regionBanner

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Thickness = 1
	stroke.Parent = instance
end

local function createLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color or COLORS.Text
	label.TextSize = textSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function createButton(parent, name, text, size, background)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.BackgroundColor3 = background or COLORS.PanelLight
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 14
	button.TextWrapped = true
	button.AutoButtonColor = true
	button.Parent = parent
	addCorner(button, 8)
	return button
end

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, -32, 0, 52)
topBar.Position = UDim2.new(0, 16, 0, 16)
topBar.BackgroundColor3 = COLORS.Background
topBar.BackgroundTransparency = 0.08
topBar.BorderSizePixel = 0
topBar.Parent = screenGui
addCorner(topBar, 12)
addStroke(topBar, COLORS.Gold, 0.55)

local titleLabel = createLabel(
	topBar,
	"Title",
	"THE HIGH SOCIETY CLUB",
	UDim2.new(0.38, -16, 1, 0),
	UDim2.new(0, 16, 0, 0),
	16,
	COLORS.Gold
)
titleLabel.Font = Enum.Font.GothamBold

local timeLabel = createLabel(
	topBar,
	"WorldTime",
	"Carregando...",
	UDim2.new(0.2, -8, 1, 0),
	UDim2.new(0.4, 0, 0, 0),
	12,
	COLORS.Muted
)
timeLabel.TextXAlignment = Enum.TextXAlignment.Center

local balanceLabel = createLabel(
	topBar,
	"Balance",
	"Society Credits: carregando...",
	UDim2.new(0.38, -12, 1, 0),
	UDim2.new(0.6, 0, 0, 0),
	14,
	COLORS.Text
)
balanceLabel.TextXAlignment = Enum.TextXAlignment.Right

local menuButton = createButton(screenGui, "MenuButton", "CLUBE", UDim2.fromOffset(112, 42), COLORS.Background)
menuButton.Position = UDim2.new(0, 16, 0, 78)
menuButton.TextColor3 = COLORS.Gold
addStroke(menuButton, COLORS.Gold, 0.45)

local photoButton = createButton(screenGui, "PhotoModeButton", "FOTO", UDim2.fromOffset(88, 42), COLORS.Background)
photoButton.Position = UDim2.new(0, 138, 0, 78)
photoButton.TextColor3 = COLORS.Gold
addStroke(photoButton, COLORS.Gold, 0.45)

local poseButton = createButton(screenGui, "PoseButton", "POSE", UDim2.fromOffset(88, 42), COLORS.Background)
poseButton.Position = UDim2.new(0, 234, 0, 78)
poseButton.TextColor3 = COLORS.Gold
addStroke(poseButton, COLORS.Gold, 0.45)

local captureButton = createButton(screenGui, "CapturePhotoButton", "CAPTURAR", UDim2.fromOffset(128, 46), COLORS.Gold)
captureButton.AnchorPoint = Vector2.new(1, 1)
captureButton.Position = UDim2.new(1, -18, 1, -18)
captureButton.TextColor3 = COLORS.Background
captureButton.Visible = false

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.new(0.92, 0, 0.68, 0)
panel.Position = UDim2.new(0.04, 0, 0.2, 0)
panel.BackgroundColor3 = COLORS.Background
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
addCorner(panel, 12)
addStroke(panel, COLORS.Gold, 0.6)

local panelTitle = createLabel(
	panel,
	"PanelTitle",
	"Central do Clube",
	UDim2.new(1, -58, 0, 42),
	UDim2.new(0, 16, 0, 8),
	18,
	COLORS.Gold
)
panelTitle.Font = Enum.Font.GothamBold

local closeButton = createButton(panel, "CloseButton", "X", UDim2.fromOffset(34, 34), COLORS.PanelLight)
closeButton.Position = UDim2.new(1, -46, 0, 10)

local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TabBar"
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 3
tabBar.ScrollBarImageColor3 = COLORS.Gold
tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.CanvasSize = UDim2.new()
tabBar.Size = UDim2.new(1, -24, 0, 38)
tabBar.Position = UDim2.new(0, 12, 0, 52)
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.Padding = UDim.new(0, 6)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -24, 1, -142)
content.Position = UDim2.new(0, 12, 0, 98)
content.BackgroundColor3 = COLORS.Panel
content.BorderSizePixel = 0
content.ScrollBarThickness = 6
content.ScrollBarImageColor3 = COLORS.Gold
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel
addCorner(content, 8)

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 10)
contentPadding.PaddingBottom = UDim.new(0, 10)
contentPadding.PaddingLeft = UDim.new(0, 10)
contentPadding.PaddingRight = UDim.new(0, 10)
contentPadding.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

local statusLabel = createLabel(
	panel,
	"Status",
	"Bem-vinda ao clube.",
	UDim2.new(1, -24, 0, 34),
	UDim2.new(0, 12, 1, -38),
	12,
	COLORS.Muted
)

local activeTab = "shop"
local activeShopId = "fashion_avenue"
local tabs = {}
local renderPage
local refreshWorkProgress
local refreshEventProgress
local refreshClubProgress
local driveAccumulator = 0
local wasDriving = false
local workMarker
local workMarkerPointName
local eventMarker
local eventMarkerPointName
local selectedEventId

local photoMode = false
local savedCameraState
local photoCameraConnection
local photoAlbum = {}
local photoCaptureInProgress = false
local photoCaptureSequence = 0

local function setStatus(message, isError)
	statusLabel.Text = tostring(message)
	statusLabel.TextColor3 = isError and COLORS.Error or COLORS.Success
end

local poseDefinitions = {
	{
		Name = "Elegante",
		Offsets = {
			LeftShoulder = CFrame.Angles(math.rad(-25), 0, math.rad(25)),
			RightShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(-20)),
			RightElbow = CFrame.Angles(0, 0, math.rad(-35)),
			Neck = CFrame.Angles(0, math.rad(-8), 0),
			Waist = CFrame.Angles(0, math.rad(8), 0),
			RootJoint = CFrame.Angles(0, math.rad(8), 0),
		},
	},
	{
		Name = "Brinde",
		Offsets = {
			LeftShoulder = CFrame.Angles(math.rad(-75), 0, math.rad(18)),
			RightShoulder = CFrame.Angles(math.rad(-75), 0, math.rad(-18)),
			LeftElbow = CFrame.Angles(0, 0, math.rad(-22)),
			RightElbow = CFrame.Angles(0, 0, math.rad(22)),
			Neck = CFrame.Angles(math.rad(-5), 0, 0),
		},
	},
	{
		Name = "Editorial",
		Offsets = {
			LeftShoulder = CFrame.Angles(math.rad(-10), 0, math.rad(12)),
			RightShoulder = CFrame.Angles(math.rad(-20), 0, math.rad(-55)),
			RightElbow = CFrame.Angles(0, 0, math.rad(-45)),
			Waist = CFrame.Angles(0, math.rad(-10), 0),
			RootJoint = CFrame.Angles(0, math.rad(-10), 0),
		},
	},
}

local poseJointNames = {
	["Left Shoulder"] = "LeftShoulder",
	LeftShoulder = "LeftShoulder",
	["Right Shoulder"] = "RightShoulder",
	RightShoulder = "RightShoulder",
	LeftElbow = "LeftElbow",
	RightElbow = "RightElbow",
	Neck = "Neck",
	Waist = "Waist",
	RootJoint = "RootJoint",
}
local currentPoseIndex = 0
local poseRenderBound = false

local function clearPose()
	if poseRenderBound then
		RunService:UnbindFromRenderStep("HSCPose")
		poseRenderBound = false
	end
	currentPoseIndex = 0
	poseButton.Text = "POSE"
end

local function setPose(index)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		setStatus("Uma pose precisa de um personagem ativo.", true)
		return
	end

	local pose = poseDefinitions[index]
	if not pose then
		clearPose()
		return
	end

	local hasTargetJoint = false
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and poseJointNames[descendant.Name] then
			hasTargetJoint = true
			break
		end
	end
	if not hasTargetJoint then
		setStatus("O avatar não tem articulações compatíveis com poses.", true)
		return
	end

	currentPoseIndex = index
	poseButton.Text = "POSE: " .. pose.Name
	if poseRenderBound then
		return
	end

	RunService:BindToRenderStep("HSCPose", Enum.RenderPriority.Character.Value + 1, function()
		local activeCharacter = player.Character
		local activePose = poseDefinitions[currentPoseIndex]
		if not activeCharacter or not activePose then
			clearPose()
			return
		end

		for _, descendant in ipairs(activeCharacter:GetDescendants()) do
			if descendant:IsA("Motor6D") then
				local jointName = poseJointNames[descendant.Name]
				local offset = jointName and activePose.Offsets[jointName]
				if offset then
					descendant.Transform *= offset
				end
			end
		end
	end)

	poseRenderBound = true
	setStatus("Pose ativa: " .. pose.Name .. ". Use POSE para alternar ou encerrar.", false)
end

poseButton.Activated:Connect(function()
	local nextIndex = currentPoseIndex + 1
	if nextIndex > #poseDefinitions then
		clearPose()
		setStatus("Pose encerrada.", false)
	else
		setPose(nextIndex)
	end
end)

player.CharacterRemoving:Connect(clearPose)

local regionBannerVersion = 0
regionChanged.OnClientEvent:Connect(function(regionName)
	regionBannerVersion += 1
	local version = regionBannerVersion
	if type(regionName) ~= "string" or regionName == "" then
		regionBanner.Visible = false
		return
	end

	regionBannerLabel.Text = regionName
	regionBanner.Visible = true
	TweenService:Create(regionBanner, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.08,
	}):Play()
	TweenService:Create(regionBannerStroke, TweenInfo.new(0.2), {
		Transparency = 0.35,
	}):Play()
	TweenService:Create(regionBannerLabel, TweenInfo.new(0.2), {
		TextTransparency = 0,
	}):Play()

	task.delay(3, function()
		if version ~= regionBannerVersion then
			return
		end

		local fadeInfo = TweenInfo.new(0.35)
		TweenService:Create(regionBanner, fadeInfo, {
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(regionBannerStroke, fadeInfo, {
			Transparency = 1,
		}):Play()
		local labelTween = TweenService:Create(regionBannerLabel, fadeInfo, {
			TextTransparency = 1,
		})
		labelTween:Play()
		labelTween.Completed:Once(function()
			if version == regionBannerVersion then
				regionBanner.Visible = false
			end
		end)
	end)
end)

local function stopPhotoMode()
	if not photoMode then
		return
	end
	photoMode = false
	if photoCameraConnection then
		photoCameraConnection:Disconnect()
		photoCameraConnection = nil
	end

	local camera = workspace.CurrentCamera
	if camera and savedCameraState and camera == savedCameraState.Camera then
		camera.CameraType = savedCameraState.CameraType
		camera.CameraSubject = savedCameraState.CameraSubject
		camera.FieldOfView = savedCameraState.FieldOfView
		camera.CFrame = savedCameraState.CFrame
	end
	savedCameraState = nil
	photoButton.Text = "FOTO"
	captureButton.Visible = false
end

local function startPhotoMode()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local camera = workspace.CurrentCamera
	if not camera or not humanoid or humanoid.Health <= 0 or not root or not head then
		setStatus("A câmera de fotos precisa de um personagem ativo.", true)
		return
	end

	savedCameraState = {
		Camera = camera,
		CameraType = camera.CameraType,
		CameraSubject = camera.CameraSubject,
		FieldOfView = camera.FieldOfView,
		CFrame = camera.CFrame,
	}
	photoMode = true
	panel.Visible = false
	camera.CameraType = Enum.CameraType.Scriptable
	photoButton.Text = "SAIR DA FOTO"
	captureButton.Visible = true

	photoCameraConnection = RunService.RenderStepped:Connect(function()
		if not photoMode then
			return
		end
		if not character.Parent or player.Character ~= character or not root.Parent or not head.Parent then
			stopPhotoMode()
			return
		end

		local cameraPosition = head.Position + root.CFrame.LookVector * 7 + Vector3.new(0, 0.65, 0)
		camera.CFrame = CFrame.lookAt(cameraPosition, head.Position + Vector3.new(0, 0.2, 0))
	end)

	setStatus("Modo foto ativo. Use CAPTURAR e depois salve a foto pelo álbum.", false)
end

local function capturePhoto()
	if not photoMode then
		setStatus("Ative o modo foto antes de capturar.", true)
		return
	end
	if photoCaptureInProgress then
		setStatus("Aguarde a captura atual terminar.", true)
		return
	end

	local serviceAvailable, captureService = pcall(function()
		return game:GetService("CaptureService")
	end)
	if not serviceAvailable then
		setStatus("A captura oficial não está disponível nesta versão do Roblox.", true)
		return
	end

	photoCaptureInProgress = true
	photoCaptureSequence += 1
	local sequence = photoCaptureSequence
	captureButton.Text = "CAPTURANDO..."
	captureButton.Active = false
	local screenWasEnabled = screenGui.Enabled
	screenGui.Enabled = false
	task.delay(3, function()
		if photoCaptureSequence == sequence and screenGui.Parent then
			screenGui.Enabled = screenWasEnabled
			photoCaptureInProgress = false
			captureButton.Text = "CAPTURAR"
			captureButton.Active = true
		end
	end)

	local succeeded, captureError = pcall(function()
		captureService:CaptureScreenshot(function(contentId)
			if photoCaptureSequence == sequence and screenGui.Parent then
				screenGui.Enabled = screenWasEnabled
				photoCaptureInProgress = false
				captureButton.Text = "CAPTURAR"
				captureButton.Active = true
			end
			if typeof(contentId) ~= "string" or contentId == "" then
				setStatus("O Roblox não retornou uma captura. Tente novamente no dispositivo compatível.", true)
				return
			end

			table.insert(photoAlbum, 1, {
				ContentId = contentId,
				CapturedAt = os.time(),
			})
			while #photoAlbum > 20 do
				table.remove(photoAlbum)
			end
			if activeTab == "photos" and panel.Visible then
				renderPage("photos")
			end
			setStatus(
				"Foto registrada no álbum desta sessão. Abra o álbum para salvá-la na galeria do Roblox.",
				false
			)
		end)
	end)

	if not succeeded then
		if photoCaptureSequence == sequence and screenGui.Parent then
			screenGui.Enabled = screenWasEnabled
			photoCaptureInProgress = false
			captureButton.Text = "CAPTURAR"
			captureButton.Active = true
		end
		setStatus("Falha ao capturar a foto: " .. tostring(captureError), true)
	end
end

photoButton.Activated:Connect(function()
	if photoMode then
		stopPhotoMode()
		setStatus("Modo foto encerrado.", false)
	else
		startPhotoMode()
	end
end)

captureButton.Activated:Connect(capturePhoto)

player.CharacterRemoving:Connect(stopPhotoMode)

local function setWorkMarker(pointName)
	if
		workMarkerPointName == pointName
		and workMarker
		and workMarker.Parent
		and workMarker.Adornee
		and workMarker.Adornee.Parent
	then
		return
	end

	if workMarker then
		workMarker:Destroy()
		workMarker = nil
	end
	workMarkerPointName = nil

	if type(pointName) ~= "string" then
		return
	end

	local world = workspace:FindFirstChild("HighSocietyWorld")
	local points = world and world:FindFirstChild("WorkPoints")
	local target = points and points:FindFirstChild(pointName)
	if not target or not target:IsA("BasePart") then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ActiveWorkDestination"
	billboard.Adornee = target
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 350
	billboard.Size = UDim2.fromOffset(210, 54)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Name = "DestinationLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = COLORS.Background
	label.BackgroundTransparency = 0.1
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = "DESTINO DA PROFISSÃO"
	label.TextColor3 = COLORS.Gold
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = billboard
	addCorner(label, 10)
	addStroke(label, COLORS.Gold, 0.2)

	workMarker = billboard
	workMarkerPointName = pointName
end

local function setEventMarker(eventId)
	if
		eventMarkerPointName == eventId
		and eventMarker
		and eventMarker.Parent
		and eventMarker.Adornee
		and eventMarker.Adornee.Parent
	then
		return
	end

	if eventMarker then
		eventMarker:Destroy()
		eventMarker = nil
	end
	eventMarkerPointName = nil

	if type(eventId) ~= "string" then
		return
	end

	local world = workspace:FindFirstChild("HighSocietyWorld")
	local points = world and world:FindFirstChild("EventPoints")
	local target = points and points:FindFirstChild(eventId)
	if not target or not target:IsA("BasePart") then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EventDestination"
	billboard.Adornee = target
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 400
	billboard.Size = UDim2.fromOffset(190, 46)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Name = "EventLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = COLORS.Background
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = "EVENTO • PARTICIPE"
	label.TextColor3 = COLORS.Gold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = billboard
	addCorner(label, 8)
	addStroke(label, COLORS.Gold, 0.2)

	eventMarker = billboard
	eventMarkerPointName = eventId
end

local function clearContent()
	for _, child in ipairs(content:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function addCard(title, detail, actionText, callback, disabled)
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.new(1, 0, 0, 88)
	card.BackgroundColor3 = COLORS.PanelLight
	card.BorderSizePixel = 0
	card.Parent = content
	addCorner(card, 8)

	local titleLabel =
		createLabel(card, "Title", title, UDim2.new(1, -132, 0, 30), UDim2.new(0, 12, 0, 8), 14, COLORS.Text)
	titleLabel.Font = Enum.Font.GothamBold

	createLabel(card, "Detail", detail, UDim2.new(1, -132, 0, 38), UDim2.new(0, 12, 0, 39), 12, COLORS.Muted)

	local action =
		createButton(card, "Action", actionText, UDim2.fromOffset(108, 48), disabled and COLORS.Panel or COLORS.Gold)
	action.Position = UDim2.new(1, -120, 0.5, -24)
	action.TextColor3 = disabled and COLORS.Muted or COLORS.Background
	action.Active = not disabled
	action.AutoButtonColor = not disabled

	if not disabled then
		action.Activated:Connect(callback)
	end

	return card
end

local function invoke(remote, ...)
	local ok, result, detail = pcall(function(...)
		return remote:InvokeServer(...)
	end, ...)

	if not ok then
		return nil, tostring(result)
	end

	if result == nil then
		return nil, tostring(detail or "O servidor não retornou dados")
	end

	return result
end

local function renderShop(storeId)
	clearContent()
	storeId = storeId or activeShopId
	local items, err = invoke(requestShopItems, storeId)
	local owned, ownedError = invoke(requestOwnedItems)
	if not items or not owned then
		local requestError = err or ownedError
		addCard("Loja indisponível", requestError, "Indisponível", function() end, true)
		setStatus(requestError, true)
		return
	end

	local ownedById = {}
	for _, ownedItem in ipairs(owned) do
		ownedById[ownedItem.Id] = true
	end

	for _, item in ipairs(items) do
		local alreadyOwned = ownedById[item.Id]
		addCard(
			item.Name,
			string.format("%s • %d Society Credits", item.Category, item.Price),
			alreadyOwned and "Adquirido" or "Comprar",
			function()
				shopPurchase:FireServer(item.Id, item.StoreId)
				setStatus("Solicitação de compra enviada...", false)
			end,
			alreadyOwned
		)
	end

	setStatus("Visite a loja correspondente para concluir compras. Itens adquiridos vão para o inventário.", false)
end

local function renderInventory()
	clearContent()
	local items, err = invoke(requestOwnedItems)
	if not items then
		addCard("Inventário indisponível", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	if #items == 0 then
		addCard("Seu inventário está vazio", "Visite a loja para adquirir itens.", "Abrir loja", function()
			renderPage("shop")
		end)
	else
		for _, item in ipairs(items) do
			local actionText = item.CanEquip and (item.Equipped and "Desequipar" or "Equipar") or "Sem visual"
			addCard(item.Name, item.Category .. " • adquirido", actionText, function()
				itemEquipmentRequest:FireServer(item.Id, not item.Equipped)
				setStatus("Atualização do visual enviada...", false)
			end, not item.CanEquip)
		end
	end

	setStatus("Acessórios básicos são criados no avatar e a equipagem é salva no perfil.", false)
end

local transactionLabels = {
	Earn = "Créditos recebidos",
	Spend = "Créditos gastos",
	JobReward = "Recompensa de profissão",
	DailyReward = "Recompensa diária",
	WelcomeBonus = "Bônus de boas-vindas",
	Purchase = "Compra na loja",
	PropertyPurchase = "Compra de imóvel",
	VehiclePurchase = "Compra de veículo",
	MarketSaleReceived = "Venda no mercado",
	MarketCommissionPaid = "Comissão do mercado",
	MarketPurchase = "Compra no mercado",
	DeveloperProductPurchase = "Pacote de créditos",
	PlayerGiftSent = "Presente enviado",
	PlayerGiftReceived = "Presente recebido",
	PlayerDonationSent = "Doação enviada",
	PlayerDonationReceived = "Doação recebida",
}

local function getTransactionDetail(transaction)
	local label = transactionLabels[transaction.Type] or "Movimentação"
	local reference = transaction.JobId
		or transaction.ItemId
		or transaction.PropertyId
		or transaction.VehicleId
		or transaction.ProductId
	if transaction.PeerUserId then
		local peerDetail = "jogador " .. tostring(transaction.PeerUserId)
		return reference and (label .. " • " .. reference .. " • " .. peerDetail) or (label .. " • " .. peerDetail)
	end

	return reference and (label .. " • " .. reference) or label
end

local function renderTransactions()
	clearContent()
	local transactions, err = invoke(requestRecentTransactions)
	if not transactions then
		addCard("Extrato indisponível", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	if #transactions == 0 then
		addCard("Nenhuma movimentação", "Ganhos e compras aparecerão aqui.", "OK", function() end, true)
	else
		for _, transaction in ipairs(transactions) do
			local isIncome = transaction.Type == "Earn"
				or transaction.Type == "JobReward"
				or transaction.Type == "DailyReward"
				or transaction.Type == "WelcomeBonus"
				or transaction.Type == "MarketSaleReceived"
				or transaction.Type == "DeveloperProductPurchase"
				or transaction.Type == "PlayerDonationReceived"
				or transaction.Type == "PlayerGiftReceived"
			local sign = isIncome and "+" or "-"
			local date = os.date("%d/%m/%Y %H:%M", transaction.Time)
			local detail = string.format(
				"%s • %s • %s • %s%d Society Credits • %s",
				getTransactionDetail(transaction),
				transaction.PlayerName or "Jogador",
				date,
				sign,
				transaction.Amount,
				transaction.Result == "Success" and "Sucesso" or (transaction.Result or "Registrada")
			)
			addCard(isIncome and "Entrada" or "Saída", detail, isIncome and "Recebido" or "Pago", function() end, true)
		end
	end

	setStatus("Exibindo as movimentações mais recentes do seu perfil.", false)
end

local function renderDailyRewards()
	clearContent()
	local data, err = invoke(requestDailyRewardStatus)
	if not data then
		addCard("Recompensa diária indisponível", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	local remaining = math.max(0, data.SecondsUntilReset or 0)
	local hours = math.floor(remaining / 3600)
	local minutes = math.floor((remaining % 3600) / 60)
	local claimedToday = data.ClaimedToday == true
	local streak = data.CurrentStreak or 0
	local nextStreak = data.NextStreak or 1
	local reward = data.Reward or 0

	addCard(
		"Sequência diária",
		string.format(
			"Sequência atual: %d dia(s) • próxima: %d dia(s) • reinicia em %02d h %02d min (UTC)",
			streak,
			nextStreak,
			hours,
			minutes
		),
		"Society",
		function() end,
		true
	)

	addCard(
		claimedToday and "Recompensa já resgatada" or "Recompensa de hoje",
		claimedToday and "Volte após a virada do dia UTC para resgatar novamente."
			or string.format("%d Society Credits • bônus cresce com dias consecutivos e tem limite diário.", reward),
		claimedToday and "Resgatado" or ("Resgatar +" .. reward),
		function()
			dailyRewardClaim:FireServer()
			setStatus("Solicitação de recompensa diária enviada...", false)
		end,
		claimedToday
	)

	setStatus("Uma recompensa por dia UTC; a sequência é calculada e concedida pelo servidor.", false)
end

local function renderAchievements()
	clearContent()
	local data, err = invoke(requestAchievements)
	if not data then
		addCard("Conquistas indisponíveis", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	addCard(
		"Reputação",
		string.format(
			"%s • %d pontos • %d trabalhos concluídos",
			data.ReputationTitle,
			data.Reputation,
			data.CompletedJobs
		),
		"Society",
		function() end,
		true
	)

	for _, achievement in ipairs(data.Achievements) do
		local unlocked = achievement.UnlockedAt ~= nil
		local detail = string.format("%s • +%d reputação", achievement.Description, achievement.Points)
		if unlocked then
			detail = string.format("%s • conquistada em %s", detail, os.date("%d/%m/%Y", achievement.UnlockedAt))
		end
		addCard(achievement.Name, detail, unlocked and "Conquistada" or "Em progresso", function() end, true)
	end

	setStatus("Conquistas e reputação são salvas no perfil.", false)
end

local function renderEvents()
	clearContent()
	local data, err = invoke(requestEvents)
	if not data then
		setEventMarker(nil)
		addCard("Eventos indisponíveis", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	addCard(
		"Participação",
		string.format(
			"%d pontos acumulados • ganhe até 10 por evento, ficando no local por 60 segundos",
			data.EventPoints
		),
		"Society",
		function() end,
		true
	)

	local currentEvent
	for _, event in ipairs(data.Events) do
		if event.Active then
			currentEvent = event
			break
		end
	end
	if currentEvent then
		selectedEventId = currentEvent.Id
	end
	setEventMarker(currentEvent and currentEvent.Id or selectedEventId)

	for _, event in ipairs(data.Events) do
		local isActive = event.Active
		local anotherIsActive = currentEvent ~= nil and not isActive
		local scheduleStatus = event.Open and "aberto agora"
			or string.format("abre em cerca de %d h de jogo", event.OpensInHours)
		local detail = string.format(
			"%s • %s • %s • %s • %d participando • +%d pontos",
			event.Description,
			event.Location,
			event.Schedule,
			scheduleStatus,
			event.Participants,
			event.PointsReward
		)
		if isActive then
			detail = string.format("%s • presença %d%%", detail, math.floor(event.Progress * 100))
		elseif event.ClaimedToday then
			detail = detail .. " • pontos recebidos hoje"
		elseif not event.Open then
			detail = detail .. " • em breve"
		end

		local actionText = isActive and "Sair" or (event.ClaimedToday and "Concluído" or "Marcar local")
		local disabled = anotherIsActive or (event.ClaimedToday and not isActive)
		addCard(event.Name, detail, actionText, function()
			if isActive then
				eventParticipationRequest:FireServer("Leave", event.Id)
				selectedEventId = nil
				setEventMarker(nil)
				setStatus("Solicitação para sair do evento enviada.", false)
			else
				selectedEventId = event.Id
				setEventMarker(event.Id)
				setStatus("Vá ao marcador e use o prompt para participar do evento.", false)
			end
		end, disabled)

		addCard(
			"Convidar para " .. event.Name,
			"Convide alguém desta sessão para encontrar você no evento. Convites expiram em 60 segundos.",
			"Escolher",
			function()
				clearContent()
				addCard(
					"Escolha um jogador",
					"Quem aceitar receberá o marcador do local; a participação continua sendo iniciada no ponto do evento.",
					"Voltar",
					renderEvents
				)

				local inviteeCount = 0
				for _, targetPlayer in ipairs(Players:GetPlayers()) do
					if targetPlayer ~= player then
						inviteeCount += 1
						addCard(targetPlayer.DisplayName, "@" .. targetPlayer.Name, "Convidar", function()
							eventInviteRequest:FireServer(event.Id, targetPlayer.UserId)
							renderEvents()
							setStatus("Solicitação de convite de evento enviada ao servidor.", false)
						end)
					end
				end

				if inviteeCount == 0 then
					addCard(
						"Ninguém disponível",
						"Outros jogadores aparecerão aqui quando entrarem na sessão.",
						"Voltar",
						renderEvents
					)
				end
			end
		)
		addCard(
			"Society VIP e créditos",
			"Consulte o passe cosmético e os pacotes de créditos disponíveis.",
			"Premium",
			function()
				renderPage("monetization")
			end
		)
	end

	setStatus("A participação começa no local do evento e é validada pelo servidor.", false)
end

local function renderFashionContest()
	clearContent()
	local data, err = invoke(requestFashionContest)
	if not data then
		addCard("Concurso indisponível", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	if data.EventOpen and not data.AtEvent then
		addCard(
			"Desfile da Fashion Avenue",
			"Vá ao ponto do desfile. Inscrição e votos só são aceitos durante o evento e perto do local.",
			"Marcar local",
			function()
				selectedEventId = "fashion_show"
				setEventMarker("fashion_show")
				setStatus("Marcador do desfile definido. Aproxime-se do ponto para se inscrever ou votar.", false)
			end
		)
	elseif data.AtEvent and not data.HasSubmitted then
		addCard(
			"Inscrição no desfile",
			"Inscreva seu visual atual no concurso. Cada jogador pode participar uma vez por dia.",
			"Inscrever",
			function()
				fashionContestRequest:FireServer("Submit")
			end
		)
	elseif data.HasSubmitted then
		addCard(
			"Inscrição confirmada",
			"Seu visual está participando do desfile de hoje.",
			"Inscrito",
			function() end,
			true
		)
	elseif not data.EventOpen then
		addCard(
			"Próximo desfile",
			"O desfile acontece das 12:00 às 15:00 no relógio do jogo. A inscrição e a votação exigem participação no local.",
			"Em breve",
			function() end,
			true
		)
	end

	local winners = {}
	for _, userId in ipairs(data.WinnerUserIds) do
		winners[userId] = true
	end
	if #data.Contestants == 0 then
		addCard("Participantes", "Ainda não há inscrições para o desfile de hoje.", "Desfile", function() end, true)
	else
		for _, contestant in ipairs(data.Contestants) do
			local isWinner = winners[contestant.UserId] == true
			local isSelf = contestant.UserId == player.UserId
			local hasVoted = data.VotedFor ~= nil
			local canVote = data.EventOpen and data.AtEvent and contestant.AtEvent and not hasVoted and not isSelf
			local detail = string.format("@%s • %d voto(s)", contestant.Username, contestant.Votes)
			if not contestant.AtEvent and not isWinner then
				detail = detail .. " • fora do local"
			end
			if isWinner then
				detail = detail .. " • vencedor"
			end
			local actionText
			if isWinner then
				actionText = "Vencedor"
			elseif isSelf then
				actionText = "Você"
			elseif data.VotedFor == contestant.UserId then
				actionText = "Voto registrado"
			elseif hasVoted then
				actionText = "Voto encerrado"
			else
				actionText = "Votar"
			end
			addCard(contestant.DisplayName, detail, actionText, function()
				fashionContestRequest:FireServer("Vote", contestant.UserId)
			end, not canVote)
		end
	end

	setStatus(
		data.EventOpen and "Concurso diário da sessão; inscrição e voto são validados no servidor."
			or "Inscrições e votação ficam disponíveis durante o horário do desfile.",
		false
	)
end

refreshEventProgress = function()
	if activeTab == "events" and panel.Visible then
		renderEvents()
	elseif activeTab == "fashion_contest" and panel.Visible then
		renderFashionContest()
	end
end

local function renderProperties()
	clearContent()
	local catalog, catalogError = invoke(requestPropertyCatalog)
	local owned, ownedError = invoke(requestOwnedProperties)
	local decorCatalog, decorError = invoke(requestPropertyDecorCatalog)

	if not catalog or not owned or not decorCatalog then
		local err = catalogError or ownedError or decorError
		addCard("Imóveis indisponíveis", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	local styleOrder = { "classic", "ocean", "garden" }
	local styleNames = {
		classic = "Clássico",
		ocean = "Oceano",
		garden = "Jardim",
	}

	for _, property in ipairs(catalog) do
		local ownedProperty = owned[property.Id]
		local isOwned = ownedProperty ~= nil
		local currentStyle = isOwned and ownedProperty.InteriorStyle or "classic"
		addCard(
			property.Name,
			isOwned
					and string.format(
						"%s • Interior: %s",
						property.Type,
						styleNames[currentStyle] or styleNames.classic
					)
				or string.format("%s • %d Society Credits", property.Type, property.Price),
			isOwned and "Visitar" or "Comprar",
			function()
				if isOwned then
					requestPropertyEntry:FireServer(property.Id)
					setStatus("Solicitação de entrada enviada...", false)
				else
					propertyPurchase:FireServer(property.Id)
					setStatus("A compra do imóvel exige proximidade do ponto no mapa.", false)
				end
			end,
			false
		)

		if isOwned then
			local currentDecorName = "Jardim interno"
			for _, decor in ipairs(decorCatalog) do
				if decor.Id == ownedProperty.InteriorDecor then
					currentDecorName = decor.Name
					break
				end
			end
			local currentIndex = table.find(styleOrder, currentStyle) or 1
			local nextStyle = styleOrder[currentIndex % #styleOrder + 1]
			addCard(
				"Decoração • " .. property.Name,
				"Escolha o estilo " .. styleNames[nextStyle] .. ". A alteração só funciona dentro do imóvel.",
				"Aplicar",
				function()
					propertyStyleRequest:FireServer(property.Id, nextStyle)
					setStatus("Solicitação de decoração enviada...", false)
				end
			)
			addCard(
				"Mobiliário • " .. property.Name,
				"Atual: " .. currentDecorName .. ". Personalização disponível dentro do imóvel.",
				"Escolher",
				function()
					clearContent()
					addCard(
						"Decoração do imóvel",
						"Escolha um conjunto visual. A alteração é salva e não muda outras residências.",
						"Voltar",
						renderProperties
					)
					for _, decor in ipairs(decorCatalog) do
						addCard(decor.Name, decor.Description, "Aplicar", function()
							propertyDecorRequest:FireServer(property.Id, decor.Id)
							setStatus("Solicitação de decoração enviada...", false)
						end, decor.Id == ownedProperty.InteriorDecor)
					end
				end
			)
			addCard(
				"Convidar visitante • " .. property.Name,
				"Convites só podem ser enviados de dentro do seu imóvel. Até quatro visitantes.",
				"Escolher",
				function()
					clearContent()
					addCard(
						"Escolha um jogador",
						"Convide alguém que esteja nesta sessão. O convite expira em 60 segundos.",
						"Voltar",
						renderProperties
					)

					local inviteeCount = 0
					for _, targetPlayer in ipairs(Players:GetPlayers()) do
						if targetPlayer ~= player then
							inviteeCount += 1
							addCard(targetPlayer.DisplayName, "@" .. targetPlayer.Name, "Convidar", function()
								propertyInviteRequest:FireServer(property.Id, targetPlayer.UserId)
								renderProperties()
								setStatus("Solicitação de convite enviada ao servidor.", false)
							end)
						end
					end

					if inviteeCount == 0 then
						addCard(
							"Ninguém disponível",
							"Outros jogadores aparecerão aqui quando entrarem na sessão.",
							"Voltar",
							renderProperties
						)
					end
				end
			)
		end
	end

	setStatus("Acesso, convites, decoração e compras são validados pelo servidor.", false)
end

local function requestSpawn(vehicleId)
	requestVehicleSpawn:FireServer(vehicleId)
	setStatus("Solicitação de retirada enviada...", false)
end

local function renderVehicles()
	clearContent()
	local catalog, catalogError = invoke(requestVehicleCatalog)
	local owned, ownedError = invoke(requestOwnedVehicles)
	local activeVehicleStatus, activeVehicleError = invoke(requestActiveVehicle)
	local paintOptions, paintError = invoke(requestVehiclePaintCatalog)

	if not catalog or not owned or activeVehicleStatus == nil and activeVehicleError then
		local err = catalogError or ownedError or activeVehicleError
		addCard("Garagem indisponível", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	local activeVehicleId = type(activeVehicleStatus) == "table" and activeVehicleStatus.Id or nil
	local isTestDrive = type(activeVehicleStatus) == "table" and activeVehicleStatus.IsTestDrive == true
	local hasActiveVehicle = typeof(activeVehicleId) == "string"
	if hasActiveVehicle then
		local activeVehicle
		for _, item in ipairs(catalog) do
			if item.Id == activeVehicleId then
				activeVehicle = item
				break
			end
		end
		addCard(
			isTestDrive and "Test drive ativo" or "Veículo retirado",
			isTestDrive
					and string.format(
						"Experiência temporária de %d segundos. O veículo será recolhido automaticamente.",
						Config.Vehicles.TestDriveDuration
					)
				or activeVehicle and activeVehicle.Category == "Lancha" and "Sua lancha está na água. Retorne ao píer da Royal Marina para guardá-la."
				or "Seu veículo está no mundo. Retorne à garagem para guardá-lo.",
			"Guardar",
			function()
				vehicleStoreRequest:FireServer()
				setStatus("Solicitação para guardar o veículo enviada...", false)
			end
		)
	end

	for _, vehicle in ipairs(catalog) do
		local isOwned = owned[vehicle.Id] ~= nil
		local ownedData = owned[vehicle.Id]
		local isActive = activeVehicleId == vehicle.Id
		local actionText = if isTestDrive and isActive
			then "Testando"
			elseif not isOwned then "Comprar"
			elseif isActive then "Retirado"
			elseif hasActiveVehicle then "Ocupado"
			else "Retirar"
		local performance = vehicle.Performance or "Padrão"
		addCard(
			vehicle.Name,
			isOwned
					and string.format(
						"%s • %s • %s",
						vehicle.Category,
						performance,
						isActive and "está fora da garagem" or "disponível na garagem"
					)
				or string.format(
					"%s • %s • %d Society Credits • compre %s",
					vehicle.Category,
					performance,
					vehicle.Price,
					vehicle.Category == "Lancha" and "na Royal Marina" or "na concessionária"
				),
			actionText,
			function()
				if isOwned and vehicle.Category ~= "Lancha" then
					if not activeVehicleId then
						requestSpawn(vehicle.Id)
					end
				else
					vehiclePurchase:FireServer(vehicle.Id)
					setStatus("Solicitação de compra enviada...", false)
				end
			end,
			(isOwned and hasActiveVehicle) or (isTestDrive and hasActiveVehicle)
		)

		if not isOwned then
			addCard(
				"Test drive • " .. vehicle.Name,
				string.format("Experimente este veículo por %d segundos.", Config.Vehicles.TestDriveDuration),
				"Testar",
				function()
					vehicleTestDriveRequest:FireServer(vehicle.Id)
					setStatus("Solicitação de test drive enviada...", false)
				end,
				hasActiveVehicle
			)
		end

		if isOwned then
			local currentPaintName = "Azul meia-noite"
			for _, paint in ipairs(paintOptions or {}) do
				if paint.Id == ownedData.PaintId then
					currentPaintName = paint.Name
					break
				end
			end
			addCard(
				"Pintura • " .. vehicle.Name,
				"Cor atual: " .. currentPaintName .. ". A pintura é aplicada ao retirar o veículo.",
				"Personalizar",
				function()
					clearContent()
					addCard(
						"Pinturas disponíveis",
						"Selecione uma cor para " .. vehicle.Name .. ".",
						"Voltar",
						renderVehicles
					)
					for _, paint in ipairs(paintOptions or {}) do
						addCard(paint.Name, "A cor será salva para este veículo.", "Aplicar", function()
							vehiclePaintRequest:FireServer(vehicle.Id, paint.Id)
							setStatus("Solicitação de pintura enviada...", false)
						end)
					end
				end,
				hasActiveVehicle or paintOptions == nil
			)
		end
	end

	if next(owned) == nil then
		addCard("Sua garagem está vazia", "Compre um veículo para adicioná-lo.", "Garagem", function() end, true)
	end

	setStatus(
		paintOptions
				and "Carros são retirados na garagem; lanchas, na Royal Marina. Personalize a pintura dos carros na garagem."
			or "Veículos aparecem na garagem; pintura indisponível: " .. tostring(paintError),
		paintOptions == nil
	)
end

local function renderWork()
	clearContent()
	local jobs, jobsError = invoke(requestWorkJobs)
	local current, currentError = invoke(requestActiveWork)

	if not jobs or not current then
		setWorkMarker(nil)
		local err = jobsError or currentError
		addCard("Profissões indisponíveis", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	local latestCurrent = current
	local cardsByJob = {}

	local function updateJobCard(job)
		local card = cardsByJob[job.Id]
		if not card then
			return
		end

		local isActive = latestCurrent.JobId == job.Id
		local anotherJobIsActive = latestCurrent.JobId ~= nil and not isActive
		local canComplete = isActive
			and latestCurrent.SecondsRemaining <= 0
			and not latestCurrent.MovementInvalid
			and latestCurrent.ActivityComplete
		local detailLabel = card:FindFirstChild("Detail")
		local actionButton = card:FindFirstChild("Action")
		if not detailLabel or not actionButton or not actionButton:IsA("TextButton") then
			return
		end

		local progression = string.format("%s • %d concluídos", job.Rank, job.Completions)
		if job.NextRankAt then
			progression = string.format("%s • %d/%d para promoção", progression, job.Completions, job.NextRankAt)
		end
		local routeDescription = job.RequiresVehicle and (job.Route .. " • exige carro próprio") or job.Route
		local activitySummary = #job.Activities > 0
				and (" • etapas: " .. table.concat(job.Activities, " → "))
			or ""
		local detail = string.format(
			"%s%s • +%d Credits (atual) • mínimo %d s • %s",
			routeDescription,
			activitySummary,
			job.EffectiveReward,
			job.MinimumDuration,
			progression
		)
		if isActive and latestCurrent.MovementInvalid then
			detail = "Percurso interrompido. Abandone e comece novamente."
		elseif isActive then
			detail = string.format("%s • progresso %d%%", detail, math.floor(latestCurrent.TravelProgress * 100))
			if latestCurrent.ActivityComplete then
				detail = detail .. " • atividades concluídas"
			else
				detail = string.format(
					"%s • etapa %d/%d: %s",
					detail,
					latestCurrent.ActivityIndex,
					latestCurrent.ActivityCount,
					latestCurrent.ObjectiveLabel
				)
				if #latestCurrent.ObjectiveChoices > 0 then
					detail = string.format(
						"%s • escolhas: %s",
						detail,
						table.concat(latestCurrent.ObjectiveChoices, " / ")
					)
				end
			end
			if job.RequiresVehicle then
				detail = string.format("%s • dirigido %d%%", detail, math.floor(latestCurrent.VehicleProgress * 100))
			end
		end
		if isActive and latestCurrent.SecondsRemaining > 0 and not latestCurrent.MovementInvalid then
			detail = string.format("%s • faltam %d s", detail, latestCurrent.SecondsRemaining)
		end

		detailLabel.Text = detail
		actionButton.Text = anotherJobIsActive and "Em andamento"
			or (isActive and (canComplete and "Concluir" or "Abandonar") or "Começar")
		actionButton.Active = not anotherJobIsActive
		actionButton.AutoButtonColor = not anotherJobIsActive
		actionButton.BackgroundColor3 = anotherJobIsActive and COLORS.Panel or COLORS.Gold
		actionButton.TextColor3 = anotherJobIsActive and COLORS.Muted or COLORS.Background
	end

	setWorkMarker(current.ObjectivePoint or current.FinishPoint)
	for _, job in ipairs(jobs) do
		cardsByJob[job.Id] = addCard(job.Name, "", "Começar", function()
			local isActive = latestCurrent.JobId == job.Id
			if latestCurrent.JobId ~= nil and not isActive then
				return
			end
			local canComplete = isActive
				and latestCurrent.SecondsRemaining <= 0
				and not latestCurrent.MovementInvalid
				and latestCurrent.ActivityComplete
			local action = isActive and (canComplete and "Complete" or "Cancel") or "Start"
			workJobRequest:FireServer(action, job.Id)
			setStatus("Solicitação de trabalho enviada...", false)
		end)
		updateJobCard(job)
	end

	refreshWorkProgress = function()
		if activeTab ~= "work" or not panel.Visible then
			return
		end

		local updated, err = invoke(requestActiveWork)
		if not updated then
			setStatus(err, true)
			return
		end

		if updated.JobId ~= latestCurrent.JobId then
			renderWork()
			return
		end

		latestCurrent = updated
		setWorkMarker(updated.ObjectivePoint or updated.FinishPoint)
		for _, job in ipairs(jobs) do
			updateJobCard(job)
		end
	end

	setStatus("Use os marcadores de início e entrega da rota de cada profissão.", false)
end

local function renderClub()
	clearContent()
	local data, err = invoke(requestClubStatus)
	if not data then
		addCard("Clube indisponível", err, "Indisponível", function() end, true)
		setStatus(err, true)
		return
	end

	if data.ShowActive then
		local showDetail = string.format(
			"DJ: %s • estilo: %s • termina em %d s",
			data.DJName or "Apresentação",
			data.StyleName or "Lounge",
			data.SecondsRemaining
		)
		addCard("Apresentação ao vivo", showDetail, data.IsPerformer and "Encerrar" or "Ao vivo", function()
			clubPerformanceRequest:FireServer("Stop")
			setStatus("Solicitação para encerrar a apresentação enviada.", false)
		end, not data.IsPerformer)
	else
		addCard(
			"Palco do Grand Society Club",
			"Os estilos alteram as luzes do palco. Para controlar a cabine, inicie e complete a rota da profissão DJ.",
			"Palco",
			function() end,
			true
		)
	end

	if data.CanOperate then
		for _, style in ipairs(data.Styles) do
			local isCurrentStyle = data.ShowActive and data.StyleId == style.Id
			local actionText
			local disabled
			if data.IsPerformer then
				actionText = isCurrentStyle and "Em execução" or "Trocar"
				disabled = isCurrentStyle
			elseif data.ShowActive then
				actionText = "Ao vivo"
				disabled = true
			else
				actionText = "Iniciar"
				disabled = false
			end
			addCard(style.Name, "Apresentação visual com iluminação sincronizada do palco.", actionText, function()
				local action = data.ShowActive and "SetStyle" or "Start"
				clubPerformanceRequest:FireServer(action, style.Id)
				setStatus("Solicitação enviada à cabine do DJ.", false)
			end, disabled)
		end
	else
		addCard(
			"Como controlar o palco",
			"Comece o trabalho DJ na Royal Marina, percorra a rota e chegue à cabine no Grand Society Club.",
			"DJ",
			function()
				panel.Visible = true
				renderPage("work")
			end
		)
	end

	if data.IsPerformer then
		addCard(
			"Controle da apresentação",
			"O show também termina ao sair da cabine ou atingir o limite de tempo.",
			"DJ ativo",
			function() end,
			true
		)
	end

	local audioDescription = data.MusicConfigured
			and "A faixa de áudio configurada será reproduzida durante a apresentação."
		or "Sem faixa de áudio configurada; o show de luzes funciona normalmente."
	addCard("Áudio", audioDescription, "Informação", function() end, true)
	setStatus(
		data.ShowActive and "Apresentação do clube em andamento nesta sessão."
			or "Cabine do DJ do Grand Society Club.",
		false
	)

	refreshClubProgress = function()
		if activeTab == "club" and panel.Visible then
			renderClub()
		end
	end
end

local function renderPhotoAlbum()
	clearContent()
	addCard(
		"Álbum desta sessão",
		string.format(
			"%d de 20 capturas recentes. As imagens ficam no dispositivo, não no perfil do jogo.",
			#photoAlbum
		),
		photoMode and "Capturar" or "Modo foto",
		function()
			if photoMode then
				capturePhoto()
			else
				startPhotoMode()
			end
		end,
		photoCaptureInProgress
	)

	if #photoAlbum == 0 then
		addCard(
			"Nenhuma foto ainda",
			"Ative o modo foto, enquadre seu avatar e use CAPTURAR. Depois salve a captura na galeria do Roblox.",
			"Álbum",
			function() end,
			true
		)
	else
		for index, photo in ipairs(photoAlbum) do
			local contentId = photo.ContentId
			local capturedAt = photo.CapturedAt
			addCard(
				string.format("Foto %02d", index),
				"Capturada em "
					.. os.date("%d/%m/%Y às %H:%M", capturedAt)
					.. ". Salve para mantê-la na galeria do Roblox.",
				"Salvar",
				function()
					local serviceAvailable, captureService = pcall(function()
						return game:GetService("CaptureService")
					end)
					if not serviceAvailable then
						setStatus("A galeria de captura não está disponível nesta versão do Roblox.", true)
						return
					end

					local succeeded, saveError = pcall(function()
						captureService:PromptSaveCapturesToGallery({ contentId }, function(result)
							if not screenGui.Parent then
								return
							end
							local resultText = typeof(result) == "EnumItem" and result.Name or tostring(result)
							statusLabel.Text = "Resposta da galeria do Roblox: " .. resultText
							statusLabel.TextColor3 = result == false and COLORS.Error or COLORS.Muted
						end)
					end)
					if not succeeded then
						setStatus("Falha ao abrir a galeria do Roblox: " .. tostring(saveError), true)
						return
					end
					setStatus("Solicitação de salvamento enviada à galeria do Roblox.", false)
				end
			)
		end
	end

	setStatus(
		"Álbum temporário desta sessão. As capturas só ficam no dispositivo após salvamento na galeria.",
		false
	)
end

local function renderHelp()
	clearContent()
	addCard(
		"Comece por aqui",
		"Perfis novos recebem 250 Society Credits. Use o menu para inventário, imóveis, garagem e profissões; visite a Fashion Avenue para comprar itens.",
		"Entendi",
		function() end
	)
	addCard(
		"Profissões",
		"Abra Trabalho, escolha uma rota e siga o marcador dourado. Algumas profissões têm etapas e escolhas presenciais; a recompensa só é paga após concluir tudo e chegar ao destino.",
		"Ver rotas",
		function()
			renderPage("work")
		end
	)
	addCard(
		"Conquistas",
		"Conclua profissões e conquiste imóveis, veículos e itens para aumentar sua reputação.",
		"Conquistas",
		function()
			renderPage("achievements")
		end
	)
	addCard(
		"Eventos",
		"Participe no clube, no jardim, na Fashion Avenue ou na marina para ganhar pontos de evento.",
		"Ver eventos",
		function()
			renderPage("events")
		end
	)
	addCard(
		"Fotografia",
		"Use FOTO para enquadrar o avatar, CAPTURAR para registrar a imagem e Álbum para solicitar o salvamento na galeria do Roblox.",
		"Modo foto",
		function()
			startPhotoMode()
		end
	)
	addCard("Extrato", "Consulte ganhos, recompensas e compras recentes.", "Abrir extrato", function()
		renderPage("transactions")
	end)
	addCard(
		"Veículos",
		"Compre o Society Sedan no ponto da concessionária. Retire-o no ponto da garagem e dirija usando os controles do banco.",
		"Garagem",
		function()
			renderPage("vehicles")
		end
	)
	addCard(
		"Imóveis",
		"Compre um imóvel na aba Imóveis, visite-o pelo mesmo menu e use o prompt dentro dele para voltar à cidade.",
		"Imóveis",
		function()
			renderPage("properties")
		end
	)
	addCard(
		"Itens",
		"Equipe os acessórios básicos pelo Inventário. Eles são peças simples e não substituem roupas ou acessórios finais do catálogo Roblox.",
		"Inventário",
		function()
			renderPage("inventory")
		end
	)
	addCard(
		"Segurança",
		"Denúncias e bloqueios usam os menus oficiais do Roblox. Compras, saldo, imóveis e recompensas são validados no servidor.",
		"Jogadores",
		function()
			renderPage("players")
		end
	)
	addCard(
		"Versão atual",
		"Esta versão usa construções 3D básicas geradas por código e ainda requer teste integrado no Roblox Studio.",
		"Entendi",
		function() end
	)
	setStatus("Seu mundo. Seu estilo. Sua conquista.", false)
end

local function promptPurchase(promptType, productId)
	local success, err = pcall(function()
		if promptType == "GamePass" then
			MarketplaceService:PromptGamePassPurchase(player, productId)
		else
			MarketplaceService:PromptProductPurchase(player, productId)
		end
	end)
	if success then
		setStatus("Confirme a compra na janela oficial do Roblox.", false)
	else
		setStatus("Não foi possível abrir a compra do Roblox: " .. tostring(err), true)
	end
end

local function renderMonetization()
	clearContent()
	local vipGamePassId = Config.Monetization.VIPGamePassId
	local vipConfigured = type(vipGamePassId) == "number" and vipGamePassId % 1 == 0 and vipGamePassId > 0
	local vipVerified = player:GetAttribute("SocietyVIPVerified") == true
	local ownsVip = player:GetAttribute("SocietyVIP") == true
	local productIdCounts = {}
	for _, product in ipairs(Config.Monetization.DeveloperProducts) do
		if type(product.Id) == "number" and product.Id % 1 == 0 and product.Id > 0 then
			productIdCounts[product.Id] = (productIdCounts[product.Id] or 0) + 1
		end
	end
	local anyOfferConfigured = vipConfigured

	local vipDescription = "Passe permanente e cosmético: jogadores VIP recebem a identificação VIP na lista social; sem bônus de créditos."
	if not vipConfigured then
		vipDescription ..= " O proprietário ainda precisa cadastrar o ID do Game Pass."
	elseif not vipVerified then
		vipDescription ..= " A propriedade do passe está sendo verificada; tente novamente em instantes."
	end
	addCard(
		"Society VIP",
		vipDescription,
		ownsVip and "Ativo" or (vipConfigured and "Comprar" or "ID pendente"),
		function()
			promptPurchase("GamePass", vipGamePassId)
		end,
		ownsVip or not vipConfigured or not vipVerified
	)

	for _, product in ipairs(Config.Monetization.DeveloperProducts) do
		local productConfigured = type(product.Id) == "number"
			and product.Id % 1 == 0
			and product.Id > 0
			and productIdCounts[product.Id] == 1
			and type(product.Credits) == "number"
			and product.Credits % 1 == 0
			and product.Credits > 0
			and product.Credits <= Config.Economy.MaxCurrency
		anyOfferConfigured = anyOfferConfigured or productConfigured
		addCard(
			product.Name,
			"Compra única; os créditos são adicionados somente após confirmação do servidor Roblox.",
			productConfigured and "Comprar" or "ID/configuração inválida",
			function()
				promptPurchase("DeveloperProduct", product.Id)
			end,
			not productConfigured
		)
	end

	setStatus(
		anyOfferConfigured
				and "As compras usam as janelas oficiais do Roblox; créditos só são concedidos após confirmação server-side."
			or "Compras desativadas: o proprietário precisa criar os produtos no Roblox e cadastrar os IDs na configuração.",
		false
	)
end

local function requestRobloxCoreAction(actionName, targetPlayer, failureMessage)
	task.spawn(function()
		local lastError
		for attempt = 1, 8 do
			if targetPlayer.Parent ~= Players then
				setStatus("Este jogador saiu da sessão.", true)
				return
			end

			local ok, err = pcall(function()
				StarterGui:SetCore(actionName, targetPlayer)
			end)
			if ok then
				return
			end

			lastError = err
			task.wait(0.25)
		end

		setStatus(failureMessage .. " (" .. tostring(lastError) .. ")", true)
	end)
end

local function renderPlayers()
	clearContent()
	local targets = {}
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player then
			table.insert(targets, targetPlayer)
		end
	end
	table.sort(targets, function(left, right)
		return left.DisplayName:lower() < right.DisplayName:lower()
	end)

	if #targets == 0 then
		addCard(
			"Nenhum outro jogador",
			"Jogadores que entrarem nesta sessão aparecerão aqui.",
			"OK",
			function() end,
			true
		)
		setStatus("As ferramentas de denúncia e bloqueio são fornecidas pelo Roblox.", false)
		return
	end

	for _, targetPlayer in ipairs(targets) do
		local card = Instance.new("Frame")
		card.Name = "PlayerSafetyCard"
		card.Size = UDim2.new(1, 0, 0, 88)
		card.BackgroundColor3 = COLORS.PanelLight
		card.BorderSizePixel = 0
		card.Parent = content
		addCorner(card, 8)

		local identity = createLabel(
			card,
			"PlayerName",
			string.format(
				"%s%s (@%s)",
				targetPlayer.DisplayName,
				targetPlayer:GetAttribute("SocietyVIP") == true and " • VIP" or "",
				targetPlayer.Name
			),
			UDim2.new(1, -196, 1, -16),
			UDim2.new(0, 12, 0, 8),
			13,
			COLORS.Text
		)
		identity.Font = Enum.Font.GothamMedium

		local reportButton = createButton(card, "ReportPlayer", "Denunciar", UDim2.fromOffset(82, 44), COLORS.Gold)
		reportButton.Position = UDim2.new(1, -184, 0.5, -22)
		reportButton.TextColor3 = COLORS.Background
		reportButton.Activated:Connect(function()
			requestRobloxCoreAction(
				"PromptReportPlayer",
				targetPlayer,
				"Não foi possível abrir a denúncia do Roblox; use o menu oficial do jogador"
			)
		end)

		local blockButton = createButton(card, "BlockPlayer", "Bloquear", UDim2.fromOffset(82, 44), COLORS.Panel)
		blockButton.Position = UDim2.new(1, -94, 0.5, -22)
		blockButton.Activated:Connect(function()
			requestRobloxCoreAction(
				"PromptBlockPlayer",
				targetPlayer,
				"Não foi possível abrir o bloqueio do Roblox; use o menu oficial do jogador"
			)
		end)
	end

	setStatus("Denúncias e bloqueios usam os recursos oficiais do Roblox.", false)
end

local function addMarketRow(title, detail, actionText, callback, disabled, inputPlaceholder, inputValue)
	local card = Instance.new("Frame")
	card.Name = "MarketCard"
	card.Size = UDim2.new(1, 0, 0, inputPlaceholder and 104 or 82)
	card.BackgroundColor3 = COLORS.PanelLight
	card.BorderSizePixel = 0
	card.Parent = content
	addCorner(card, 8)

	local titleLabel = createLabel(
		card,
		"Title",
		title,
		UDim2.new(1, -24, 0, 24),
		UDim2.new(0, 12, 0, 7),
		13,
		COLORS.Text
	)
	titleLabel.Font = Enum.Font.GothamBold
	createLabel(
		card,
		"Detail",
		detail,
		UDim2.new(1, -24, 0, 25),
		UDim2.new(0, 12, 0, 31),
		11,
		COLORS.Muted
	)

	if inputPlaceholder then
		local input = Instance.new("TextBox")
		input.Name = "AmountOrPrice"
		input.Size = UDim2.fromOffset(112, 32)
		input.Position = UDim2.new(0, 12, 1, -40)
		input.BackgroundColor3 = COLORS.Panel
		input.BorderSizePixel = 0
		input.Font = Enum.Font.Gotham
		input.Text = inputValue or ""
		input.PlaceholderText = inputPlaceholder
		input.TextColor3 = COLORS.Text
		input.PlaceholderColor3 = COLORS.Muted
		input.TextSize = 12
		input.ClearTextOnFocus = false
		input.Parent = card
		addCorner(input, 6)
	end

	local buttonWidth = inputPlaceholder and 140 or 112
	local button = createButton(
		card,
		"Action",
		actionText,
		UDim2.fromOffset(buttonWidth, 34),
		disabled and COLORS.Panel or COLORS.Gold
	)
	button.Position = inputPlaceholder and UDim2.new(0, 132, 1, -41) or UDim2.new(1, -124, 1, -41)
	button.TextColor3 = disabled and COLORS.Muted or COLORS.Background
	button.Active = not disabled
	button.AutoButtonColor = not disabled
	if not disabled then
		button.Activated:Connect(function()
			local input = card:FindFirstChild("AmountOrPrice")
			callback(input and input.Text or nil)
		end)
	end
end

local function renderMarket()
	clearContent()
	local data, marketError = invoke(requestMarketData)
	if not data then
		addCard("Mercado indisponível", marketError, "Indisponível", function() end, true)
		setStatus(marketError, true)
		return
	end

	addCard(
		"Mercado entre jogadores",
		string.format(
			"Somente itens de moda e créditos desta sessão. Comissão de %d%% (arredondada para baixo) descontada do vendedor; o comprador paga o preço anunciado. Presentes/doações não têm comissão. Preço 0 significa presente; anúncios expiram em 15 minutos.",
			data.CommissionPercent
		),
		"Atualizar",
		function()
			task.delay(Config.RateLimits.MarketQueryCooldown, renderMarket)
		end
	)

	addCard(
		"Seus itens",
		string.format(
			"Máximo de %d anúncios por jogador; preço máximo de %d créditos.",
			data.MaxListingsPerPlayer,
			data.MaxPrice
		),
		"Informação",
		function() end,
		true
	)
	if #data.Items == 0 then
		addCard("Sem itens negociáveis", "Compre itens na Fashion Avenue para anunciá-los ou presenteá-los.", "Loja", function()
			renderPage("shop")
		end)
	else
		for _, item in ipairs(data.Items) do
			local disabled = not item.Sellable
			local detail = item.Category
			local actionText = "Anunciar"
			local placeholder = "Preço"
			if item.IsListed then
				detail ..= " • já anunciado; cancele abaixo"
				actionText = "Anunciado"
				placeholder = nil
			elseif item.Equipped then
				detail ..= " • desequipe para negociar"
				actionText = "Indisponível"
				placeholder = nil
			elseif not item.Sellable then
				detail ..= " • não negociável"
				actionText = "Indisponível"
				placeholder = nil
			end
			addMarketRow(item.Name, detail, actionText, function(priceText)
				local price = tonumber(priceText)
				if not price then
					setStatus("Informe um preço inteiro; 0 anuncia como presente.", true)
					return
				end
				marketAction:FireServer("ListItem", item.Id, price)
				setStatus("Solicitação de anúncio enviada...", false)
			end, disabled, placeholder, "0")
		end
	end

	addCard("Anúncios da sessão", "Compre ou receba itens de jogadores que estejam próximos.", "Mercado", function() end, true)
	if #data.Listings == 0 then
		addCard("Nenhum anúncio ativo", "Quando alguém anunciar um item nesta sessão, ele aparecerá aqui.", "OK", function() end, true)
	else
		for _, listing in ipairs(data.Listings) do
			local ownListing = listing.SellerUserId == player.UserId
			local priceText = listing.Price == 0 and "Presente" or (tostring(listing.Price) .. " Society Credits")
			local detail = string.format("%s • %s • vendedor: %s", listing.Category, priceText, listing.SellerName)
			addMarketRow(
				listing.ItemName,
				detail,
				ownListing and "Cancelar" or (listing.Price == 0 and "Receber" or "Comprar"),
				function()
					if ownListing then
						marketAction:FireServer("CancelListing", listing.Id)
						setStatus("Solicitação de cancelamento enviada...", false)
					else
						marketAction:FireServer("BuyListing", listing.Id)
						setStatus("Aproxime-se do vendedor para concluir a troca.", false)
					end
				end,
				false
			)
		end
	end

	addCard(
		"Doar créditos",
		"Escolha um jogador desta sessão e informe uma quantia. Doações não podem ser desfeitas.",
		"Doação",
		function() end,
		true
	)
	local targets = {}
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player then
			table.insert(targets, targetPlayer)
		end
	end
	table.sort(targets, function(left, right)
		return left.DisplayName:lower() < right.DisplayName:lower()
	end)
	if #targets == 0 then
		addCard("Sem destinatários", "Outro jogador precisa estar na mesma sessão para receber uma doação.", "OK", function() end, true)
	else
		for _, targetPlayer in ipairs(targets) do
			addMarketRow(
				targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")",
				string.format("Doação máxima: %d créditos; aproxime-se do jogador.", data.MaxDonation),
				"Doar",
				function(amountText)
					local amount = tonumber(amountText)
					if not amount then
						setStatus("Informe uma quantidade inteira de créditos.", true)
						return
					end
					marketAction:FireServer("DonateCredits", targetPlayer.UserId, amount)
					setStatus("Solicitação de doação enviada...", false)
				end,
				targetPlayer.Parent ~= Players,
				"Créditos",
				"100"
			)
		end
	end

	setStatus("As trocas são validadas e registradas pelo servidor. Veículos e imóveis não podem ser negociados.", false)
end

local function renderCommunityGallery()
	clearContent()
	local creations, galleryError = invoke(requestApprovedCreations)
	if not creations then
		addCard("Galeria indisponível", galleryError, "Indisponível", function() end, true)
		setStatus(galleryError, true)
		return
	end

	addCard(
		"Conceitos aprovados",
		"Propostas predefinidas aprovadas pelo criador; até seis maquetes também aparecem no mapa da Galeria.",
		"Atualizar",
		function()
			task.delay(Config.RateLimits.CreationQueryCooldown + 0.1, renderCommunityGallery)
		end
	)
	if #creations == 0 then
		addCard("Nenhum conceito publicado", "Complete a profissão Criador de mundos para enviar um conceito à revisão.", "OK", function() end, true)
	else
		for _, creation in ipairs(creations) do
			local date = os.date("%d/%m/%Y", creation.SubmittedAt)
			addCard(
				string.format("Cenário %s • %s", creation.Theme, creation.Layout),
				string.format("Criado por %s • aprovado em %s", creation.CreatorName, date),
				"Aprovado",
				function() end,
				true
			)
		end
	end
	setStatus("As propostas são limitadas a temas e composições aprovados no catálogo do jogo.", false)
end

local function renderAdmin()
	clearContent()
	local isAdmin, statusError = invoke(requestAdminStatus)
	if not isAdmin then
		local message = statusError or "Painel disponível somente para o criador verificado do jogo."
		addCard("Acesso restrito", message, "Restrito", function() end, true)
		setStatus(message, true)
		return
	end

	addCard(
		"Painel do criador",
		"Expulsar remove alguém somente desta sessão. Denúncias e bloqueios permanentes continuam nos recursos oficiais do Roblox.",
		"Ativo",
		function() end,
		true
	)

	local pendingCreations, creationsError = invoke(requestPendingCreations)
	if not pendingCreations then
		addCard("Fila de criações indisponível", creationsError, "Indisponível", function() end, true)
	elseif #pendingCreations == 0 then
		addCard("Revisão de criações", "Não há conceitos aguardando aprovação.", "Fila vazia", function() end, true)
	else
		addCard("Propostas aguardando revisão", "Aprovar publica o conceito na Galeria; rejeitar o mantém fora da lista pública.", "Moderação", function() end, true)
		for _, creation in ipairs(pendingCreations) do
			local card = Instance.new("Frame")
			card.Name = "CreationReviewCard"
			card.Size = UDim2.new(1, 0, 0, 100)
			card.BackgroundColor3 = COLORS.PanelLight
			card.BorderSizePixel = 0
			card.Parent = content
			addCorner(card, 8)

			local titleLabel = createLabel(
				card,
				"Title",
				string.format("Cenário %s • %s", creation.Theme, creation.Layout),
				UDim2.new(1, -24, 0, 28),
				UDim2.new(0, 12, 0, 7),
				13,
				COLORS.Text
			)
			titleLabel.Font = Enum.Font.GothamBold
			createLabel(
				card,
				"Detail",
				string.format("Criador: %s (@%d) • enviada em %s", creation.CreatorName, creation.CreatorUserId, os.date("%d/%m/%Y %H:%M", creation.SubmittedAt)),
				UDim2.new(1, -24, 0, 24),
				UDim2.new(0, 12, 0, 36),
				11,
				COLORS.Muted
			)

			local approve = createButton(card, "Approve", "Aprovar", UDim2.fromOffset(104, 30), COLORS.Gold)
			approve.Position = UDim2.new(1, -224, 1, -36)
			approve.TextColor3 = COLORS.Background
			approve.Activated:Connect(function()
				creationReviewRequest:FireServer(creation.Id, "Approve")
				setStatus("Enviando decisão de aprovação...", false)
			end)

			local reject = createButton(card, "Reject", "Rejeitar", UDim2.fromOffset(104, 30), COLORS.Error)
			reject.Position = UDim2.new(1, -112, 1, -36)
			reject.Activated:Connect(function()
				creationReviewRequest:FireServer(creation.Id, "Reject")
				setStatus("Enviando decisão de rejeição...", false)
			end)
		end
	end

	local targets = {}
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player then
			table.insert(targets, targetPlayer)
		end
	end
	table.sort(targets, function(left, right)
		return left.Name:lower() < right.Name:lower()
	end)

	if #targets == 0 then
		addCard("Sessão vazia", "Nenhum outro jogador está conectado.", "OK", function() end, true)
	else
		for _, targetPlayer in ipairs(targets) do
			local card = Instance.new("Frame")
			card.Name = "AdminPlayerCard"
			card.Size = UDim2.new(1, 0, 0, 88)
			card.BackgroundColor3 = COLORS.PanelLight
			card.BorderSizePixel = 0
			card.Parent = content
			addCorner(card, 8)

			local identity = createLabel(
				card,
				"PlayerName",
				string.format("%s (@%s)", targetPlayer.DisplayName, targetPlayer.Name),
				UDim2.new(1, -140, 1, -16),
				UDim2.new(0, 12, 0, 8),
				13,
				COLORS.Text
			)
			identity.Font = Enum.Font.GothamMedium

			local pendingConfirmation = false
			local kickButton = createButton(card, "KickPlayer", "Expulsar", UDim2.fromOffset(112, 44), COLORS.Error)
			kickButton.Position = UDim2.new(1, -124, 0.5, -22)
			kickButton.Activated:Connect(function()
				if not targetPlayer.Parent then
					setStatus("O jogador já saiu da sessão.", true)
					return
				end

				if not pendingConfirmation then
					pendingConfirmation = true
					kickButton.Text = "Confirmar"
					task.delay(5, function()
						if kickButton.Parent and pendingConfirmation then
							pendingConfirmation = false
							kickButton.Text = "Expulsar"
						end
					end)
					return
				end

				pendingConfirmation = false
				kickButton.Text = "Enviando..."
				kickButton.Active = false
				adminAction:FireServer("Kick", targetPlayer.UserId)
			end)
		end
	end

	local logs, logsError = invoke(requestModerationLogs)
	if not logs then
		addCard("Logs de moderação indisponíveis", logsError, "Indisponível", function() end, true)
	elseif #logs == 0 then
		addCard("Logs de moderação", "Nenhuma ação administrativa foi registrada nesta sessão.", "Sem registros", function() end, true)
	else
		addCard("Logs recentes de moderação", "Até 20 registros desta sessão; histórico completo no Output do servidor.", "Auditoria", function() end, true)
		for _, entry in ipairs(logs) do
			local target = entry.TargetName
				and string.format("%s (@%s)", entry.TargetName, tostring(entry.TargetUserId))
				or (entry.TargetUserId and ("UserId " .. tostring(entry.TargetUserId)) or "sem alvo")
			local result = entry.Success and "Concluída" or "Recusada"
			local detail = string.format(
				"%s • moderador %s (@%s)\nalvo: %s • %s",
				entry.Timestamp,
				entry.ActorName,
				tostring(entry.ActorUserId),
				target,
				entry.Reason
			)
			local card = Instance.new("Frame")
			card.Name = "ModerationLogCard"
			card.Size = UDim2.new(1, 0, 0, 108)
			card.BackgroundColor3 = COLORS.PanelLight
			card.BorderSizePixel = 0
			card.Parent = content
			addCorner(card, 8)

			local titleLabel = createLabel(
				card,
				"Title",
				entry.Action .. " • " .. result,
				UDim2.new(1, -24, 0, 26),
				UDim2.new(0, 12, 0, 8),
				13,
				COLORS.Text
			)
			titleLabel.Font = Enum.Font.GothamBold
			createLabel(
				card,
				"Detail",
				detail,
				UDim2.new(1, -24, 0, 62),
				UDim2.new(0, 12, 0, 37),
				11,
				COLORS.Muted
			)
		end
	end

	setStatus("Acesso administrativo restrito a contas autorizadas.", false)
end

local pageRenderers = {
	shop = renderShop,
	inventory = renderInventory,
	transactions = renderTransactions,
	daily_rewards = renderDailyRewards,
	achievements = renderAchievements,
	events = renderEvents,
	fashion_contest = renderFashionContest,
	club = renderClub,
	photos = renderPhotoAlbum,
	properties = renderProperties,
	vehicles = renderVehicles,
	work = renderWork,
	players = renderPlayers,
	market = renderMarket,
	monetization = renderMonetization,
	community_gallery = renderCommunityGallery,
	admin = renderAdmin,
	help = renderHelp,
}

renderPage = function(tabName)
	activeTab = tabName
	panelTitle.Text = ({
		shop = "Loja",
		inventory = "Inventário",
		transactions = "Extrato",
		daily_rewards = "Recompensas diárias",
		achievements = "Conquistas",
		events = "Eventos",
		fashion_contest = "Desfile e concurso",
		club = "Grand Society Club",
		photos = "Álbum",
		properties = "Imóveis",
		vehicles = "Veículos e garagem",
		work = "Profissões",
		players = "Segurança social",
		market = "Mercado entre jogadores",
		monetization = "Society VIP e créditos",
		community_gallery = "Galeria de criações",
		admin = "Painel do criador",
		help = "Informações",
	})[tabName] or "Central do Clube"

	for name, button in pairs(tabs) do
		button.BackgroundColor3 = name == activeTab and COLORS.Gold or COLORS.PanelLight
		button.TextColor3 = name == activeTab and COLORS.Background or COLORS.Text
	end

	pageRenderers[tabName]()
end

local tabDefinitions = {
	{ Id = "shop", Label = "Loja", Width = 64 },
	{ Id = "inventory", Label = "Itens", Width = 64 },
	{ Id = "transactions", Label = "Extrato", Width = 72 },
	{ Id = "daily_rewards", Label = "Diária", Width = 64 },
	{ Id = "achievements", Label = "Conquistas", Width = 96 },
	{ Id = "events", Label = "Eventos", Width = 70 },
	{ Id = "fashion_contest", Label = "Desfile", Width = 76 },
	{ Id = "club", Label = "Clube", Width = 64 },
	{ Id = "photos", Label = "Álbum", Width = 64 },
	{ Id = "properties", Label = "Imóveis", Width = 70 },
	{ Id = "vehicles", Label = "Garagem", Width = 76 },
	{ Id = "work", Label = "Trabalho", Width = 76 },
	{ Id = "players", Label = "Jogadores", Width = 82 },
	{ Id = "market", Label = "Mercado", Width = 78 },
	{ Id = "monetization", Label = "Premium", Width = 82 },
	{ Id = "community_gallery", Label = "Galeria", Width = 74 },
	{ Id = "help", Label = "Info", Width = 50 },
}

for index, definition in ipairs(tabDefinitions) do
	local button =
		createButton(tabBar, definition.Id, definition.Label, UDim2.fromOffset(definition.Width, 34), COLORS.PanelLight)
	button.LayoutOrder = index
	tabs[definition.Id] = button
	button.Activated:Connect(function()
		renderPage(definition.Id)
	end)
end

task.spawn(function()
	local isAdmin = invoke(requestAdminStatus)
	if not isAdmin or not screenGui.Parent then
		return
	end

	local button = createButton(tabBar, "admin", "Admin", UDim2.fromOffset(64, 34), COLORS.PanelLight)
	button.LayoutOrder = #tabDefinitions + 1
	tabs.admin = button
	button.Activated:Connect(function()
		renderPage("admin")
	end)
end)

menuButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		renderPage(activeTab)
	end
end)

closeButton.Activated:Connect(function()
	panel.Visible = false
end)

currencyChanged.OnClientEvent:Connect(function(amount)
	if typeof(amount) == "number" then
		balanceLabel.Text = string.format("Society Credits: %d", amount)
	end
end)

shopPurchase.OnClientEvent:Connect(function(response)
	if response.Success then
		setStatus("Compra concluída: " .. response.Item.Name, false)
		if activeTab == "shop" then
			renderShop()
		elseif activeTab == "inventory" then
			renderInventory()
		end
		if activeTab == "transactions" then
			renderTransactions()
		end
	else
		setStatus(response.Error or "Não foi possível concluir a compra.", true)
	end
end)

marketActionResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if response.Refresh and activeTab == "market" and panel.Visible then
		task.delay(Config.RateLimits.MarketQueryCooldown + 0.1, function()
			renderMarket()
			setStatus(response.Message or "Solicitação do mercado concluída.", not response.Success)
		end)
	else
		setStatus(response.Message or "Solicitação do mercado concluída.", not response.Success)
	end
end)

monetizationResult.OnClientEvent:Connect(function(response)
	if type(response) ~= "table" or type(response.Success) ~= "boolean" then
		return
	end
	setStatus(response.Message or "Resultado de compra recebido.", not response.Success)
	if response.Success and activeTab == "monetization" then
		task.defer(renderPage, "monetization")
	end
end)

player:GetAttributeChangedSignal("SocietyVIP"):Connect(function()
	if activeTab == "monetization" then
		task.defer(renderPage, "monetization")
	end
end)

creationReviewResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if response.Refresh and activeTab == "admin" and panel.Visible then
		task.delay(Config.RateLimits.CreationQueryCooldown + 0.1, function()
			renderAdmin()
			setStatus(response.Message or "Revisão registrada.", not response.Success)
		end)
	else
		setStatus(response.Message or "Revisão recebida.", not response.Success)
	end
end)

dailyRewardResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if response.Success then
		if activeTab == "daily_rewards" then
			renderDailyRewards()
		elseif activeTab == "transactions" then
			renderTransactions()
		end
	else
		if activeTab == "daily_rewards" then
			renderDailyRewards()
		end
	end
	setStatus(response.Message or "Solicitação de recompensa diária concluída.", not response.Success)
end)

propertyStyleResult.OnClientEvent:Connect(function(response)
	if response.Success and activeTab == "properties" then
		renderProperties()
	end
	setStatus(response.Message or "Solicitação de decoração concluída.", not response.Success)
end)

propertyDecorResult.OnClientEvent:Connect(function(response)
	if response.Success and activeTab == "properties" then
		renderProperties()
	end
	setStatus(response.Message or "Solicitação de mobiliário concluída.", not response.Success)
end)

requestPropertyEntry.OnClientEvent:Connect(function(response)
	setStatus(response.Message or "Solicitação concluída.", not response.Success)
end)

local inviteDialog
local inviteDialogSequence = 0

propertyInviteReceived.OnClientEvent:Connect(function(invite)
	if typeof(invite) ~= "table" or typeof(invite.OwnerName) ~= "string" or typeof(invite.PropertyName) ~= "string" then
		return
	end

	local expiresIn = typeof(invite.ExpiresIn) == "number" and math.clamp(invite.ExpiresIn, 1, 60) or 60
	inviteDialogSequence += 1
	local sequence = inviteDialogSequence
	if inviteDialog then
		inviteDialog:Destroy()
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "PropertyInviteDialog"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	local dialog = Instance.new("Frame")
	dialog.Name = "Dialog"
	dialog.Size = UDim2.new(0.82, 0, 0, 190)
	dialog.Position = UDim2.new(0.09, 0, 0.5, -95)
	dialog.BackgroundColor3 = COLORS.Background
	dialog.BorderSizePixel = 0
	dialog.Parent = overlay
	addCorner(dialog, 12)
	addStroke(dialog, COLORS.Gold, 0.2)

	local title = createLabel(
		dialog,
		"Title",
		invite.OwnerName .. " convidou você",
		UDim2.new(1, -32, 0, 40),
		UDim2.new(0, 16, 0, 16),
		18,
		COLORS.Gold
	)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	createLabel(
		dialog,
		"Property",
		string.format("Visitar: %s • o convite expira em %d s", invite.PropertyName, expiresIn),
		UDim2.new(1, -32, 0, 48),
		UDim2.new(0, 16, 0, 60),
		14,
		COLORS.Text
	).TextXAlignment =
		Enum.TextXAlignment.Center

	local decline = createButton(dialog, "Decline", "Recusar", UDim2.new(0.42, 0, 0, 42), COLORS.PanelLight)
	decline.Position = UDim2.new(0.06, 0, 1, -58)
	local accept = createButton(dialog, "Accept", "Aceitar visita", UDim2.new(0.46, 0, 0, 42), COLORS.Gold)
	accept.Position = UDim2.new(0.48, 0, 1, -58)
	accept.TextColor3 = COLORS.Background

	local function respond(response)
		if inviteDialog ~= overlay then
			return
		end
		inviteDialog = nil
		overlay:Destroy()
		propertyInviteResponse:FireServer(response)
	end

	decline.Activated:Connect(function()
		respond("Decline")
	end)
	accept.Activated:Connect(function()
		respond("Accept")
	end)

	inviteDialog = overlay
	task.delay(expiresIn, function()
		if inviteDialogSequence == sequence and inviteDialog == overlay then
			inviteDialog = nil
			overlay:Destroy()
		end
	end)
	setStatus("Você recebeu um convite para visitar um imóvel.", false)
end)

propertyInviteResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	setStatus(response.Message or "Atualização do convite recebida.", not response.Success)
end)

local eventInviteDialog
local eventInviteDialogSequence = 0

eventInviteReceived.OnClientEvent:Connect(function(invite)
	if
		typeof(invite) ~= "table"
		or typeof(invite.SenderName) ~= "string"
		or typeof(invite.EventName) ~= "string"
		or typeof(invite.EventId) ~= "string"
	then
		return
	end

	local expiresIn = typeof(invite.ExpiresIn) == "number" and math.clamp(invite.ExpiresIn, 1, 60) or 60
	eventInviteDialogSequence += 1
	local sequence = eventInviteDialogSequence
	if eventInviteDialog then
		eventInviteDialog:Destroy()
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "EventInviteDialog"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	local dialog = Instance.new("Frame")
	dialog.Name = "Dialog"
	dialog.Size = UDim2.new(0.82, 0, 0, 190)
	dialog.Position = UDim2.new(0.09, 0, 0.5, -95)
	dialog.BackgroundColor3 = COLORS.Background
	dialog.BorderSizePixel = 0
	dialog.Parent = overlay
	addCorner(dialog, 12)
	addStroke(dialog, COLORS.Gold, 0.2)

	local title = createLabel(
		dialog,
		"Title",
		invite.SenderName .. " convidou você",
		UDim2.new(1, -32, 0, 40),
		UDim2.new(0, 16, 0, 16),
		18,
		COLORS.Gold
	)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	createLabel(
		dialog,
		"Event",
		string.format("%s • %s • expira em %d s", invite.EventName, invite.Location, expiresIn),
		UDim2.new(1, -32, 0, 48),
		UDim2.new(0, 16, 0, 60),
		14,
		COLORS.Text
	).TextXAlignment =
		Enum.TextXAlignment.Center

	local decline = createButton(dialog, "Decline", "Recusar", UDim2.new(0.42, 0, 0, 42), COLORS.PanelLight)
	decline.Position = UDim2.new(0.06, 0, 1, -58)
	local accept = createButton(dialog, "Accept", "Ver evento", UDim2.new(0.46, 0, 0, 42), COLORS.Gold)
	accept.Position = UDim2.new(0.48, 0, 1, -58)
	accept.TextColor3 = COLORS.Background

	local function respond(response)
		if eventInviteDialog ~= overlay then
			return
		end
		eventInviteDialog = nil
		overlay:Destroy()
		eventInviteResponse:FireServer(response)
	end

	decline.Activated:Connect(function()
		respond("Decline")
	end)
	accept.Activated:Connect(function()
		respond("Accept")
	end)

	eventInviteDialog = overlay
	task.delay(expiresIn, function()
		if eventInviteDialogSequence == sequence and eventInviteDialog == overlay then
			eventInviteDialog = nil
			overlay:Destroy()
		end
	end)
	setStatus("Você recebeu um convite para um evento.", false)
end)

eventInviteResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if response.Success and response.Accepted and typeof(response.EventId) == "string" then
		selectedEventId = response.EventId
		setEventMarker(response.EventId)
	end
	setStatus(response.Message or "Atualização do convite de evento recebida.", not response.Success)
end)

vehiclePaintResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if response.Success and activeTab == "vehicles" then
		renderVehicles()
	end
	setStatus(response.Message or "Solicitação de pintura concluída.", not response.Success)
end)

vehiclePurchase.OnClientEvent:Connect(function(response)
	if response.Success then
		setStatus("Veículo adquirido: " .. response.Vehicle.Name, false)
		if activeTab == "vehicles" then
			renderVehicles()
		elseif activeTab == "transactions" then
			renderTransactions()
		end
	else
		setStatus(response.Error or "Não foi possível comprar o veículo.", true)
	end
end)

propertyPurchase.OnClientEvent:Connect(function(response)
	if response.Success then
		setStatus("Imóvel adquirido: " .. response.Property.Name, false)
		if activeTab == "properties" then
			renderProperties()
		elseif activeTab == "transactions" then
			renderTransactions()
		end
	else
		setStatus(response.Error or "Não foi possível comprar o imóvel.", true)
	end
end)

vehicleTestDriveResult.OnClientEvent:Connect(function(response)
	if response.Ended then
		setStatus(response.Message or "O test drive terminou.", false)
	elseif response.Success then
		setStatus(
			string.format("%s: test drive iniciado por %d segundos.", response.Vehicle.Name, response.Vehicle.Duration),
			false
		)
	else
		setStatus(response.Message or "Não foi possível iniciar o test drive.", true)
	end

	if activeTab == "vehicles" then
		renderVehicles()
	end
end)

vehicleSpawnResult.OnClientEvent:Connect(function(response)
	setStatus(response.Message or response.Error or "Solicitação concluída.", not response.Success)
end)

vehicleStoreResult.OnClientEvent:Connect(function(response)
	if activeTab == "vehicles" then
		renderVehicles()
	end
	setStatus(response.Message or "Solicitação de garagem concluída.", not response.Success)
end)

itemEquipmentResult.OnClientEvent:Connect(function(response)
	if activeTab == "inventory" then
		renderInventory()
	end
	setStatus(response.Message or "Solicitação de equipagem concluída.", not response.Success)
end)

workJobResult.OnClientEvent:Connect(function(response)
	if response.Success and activeTab == "work" then
		renderWork()
	elseif response.Success and activeTab == "transactions" then
		renderTransactions()
	end
	setStatus(response.Message or "Solicitação de trabalho concluída.", not response.Success)
end)

clubPerformanceResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if activeTab == "club" and panel.Visible then
		task.delay(Config.RateLimits.EventCatalogCooldown, function()
			if activeTab == "club" and panel.Visible then
				renderClub()
			end
		end)
	end
	setStatus(response.Message or "Solicitação da cabine concluída.", not response.Success)
end)

eventParticipationResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if response.Success and response.PointsEarned and response.PointsEarned > 0 then
		selectedEventId = nil
	end
	if activeTab == "events" or activeTab == "fashion_contest" then
		refreshEventProgress()
	end
	setStatus(response.Message or "Solicitação de evento concluída.", not response.Success)
end)

fashionContestResult.OnClientEvent:Connect(function(response)
	if typeof(response) ~= "table" then
		return
	end
	if activeTab == "fashion_contest" then
		renderFashionContest()
	end
	setStatus(response.Message or "Solicitação do concurso concluída.", not response.Success)
end)

adminActionResult.OnClientEvent:Connect(function(response)
	if activeTab == "admin" and panel.Visible then
		task.defer(renderAdmin)
	end
	setStatus(response.Message or "Ação administrativa concluída.", not response.Success)
end)

achievementUnlocked.OnClientEvent:Connect(function(achievement)
	setStatus("Conquista desbloqueada: " .. tostring(achievement.Name), false)
	if activeTab == "achievements" then
		renderAchievements()
	end
end)

local function findWorldInteractionPoint(partName)
	local point = workspace:FindFirstChild(partName)
	if point then
		return point
	end

	local generatedWorld = workspace:FindFirstChild("HighSocietyWorld")
	return generatedWorld and generatedWorld:FindFirstChild(partName, true)
end

local dealershipPoint = findWorldInteractionPoint("DealershipPurchasePoint")
local dealershipPrompt = dealershipPoint and dealershipPoint:FindFirstChild("PurchasePrompt")
if dealershipPrompt and dealershipPrompt:IsA("ProximityPrompt") then
	dealershipPrompt.Triggered:Connect(function()
		panel.Visible = true
		renderPage("vehicles")
		setStatus("Escolha um veículo. A compra é validada pelo servidor neste ponto.", false)
	end)
end

local world = workspace:WaitForChild("HighSocietyWorld", 30)
local function connectShopPrompts()
	if not world then
		return
	end

	for _, shopPoint in ipairs(world:GetDescendants()) do
		local storeId = shopPoint:GetAttribute("ShopId")
		if shopPoint:IsA("BasePart") and type(storeId) == "string" then
			local shopPrompt = shopPoint:FindFirstChild("ShopPrompt")
			if shopPrompt and shopPrompt:IsA("ProximityPrompt") then
				shopPrompt.Triggered:Connect(function()
					activeShopId = storeId
					panel.Visible = true
					renderPage("shop")
					local storeName = shopPoint:GetAttribute("ShopName") or shopPrompt.ObjectText
					setStatus(
						"Você está em " .. tostring(storeName) .. ". As compras são validadas pelo servidor.",
						false
					)
				end)
			end
		end
	end
end
connectShopPrompts()

local function connectGaragePrompt(partName, promptName)
	local part = findWorldInteractionPoint(partName)
	local prompt = part and part:FindFirstChild(promptName)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end

	prompt.Triggered:Connect(function()
		panel.Visible = true
		renderPage("vehicles")
		setStatus("Escolha seu veículo na garagem. Você pode retirar ou guardar pelo menu.", false)
	end)
end

connectGaragePrompt("GaragePoint", "GaragePrompt")
connectGaragePrompt("VehicleSpawnPoint", "SpawnVehiclePrompt")
connectGaragePrompt("BoatPurchasePoint", "BoatPurchasePrompt")
connectGaragePrompt("BoatStorePoint", "BoatStorePrompt")

local connectedPropertyPrompts = {}
local function connectPropertyPrompt(prompt)
	if
		not prompt:IsA("ProximityPrompt")
		or prompt.Name ~= "PropertyPurchasePrompt"
		or connectedPropertyPrompts[prompt]
	then
		return
	end

	local point = prompt.Parent
	local propertyId = point and point:GetAttribute("PropertyId")
	if type(propertyId) ~= "string" then
		return
	end

	connectedPropertyPrompts[prompt] = true
	prompt.Triggered:Connect(function()
		propertyPurchase:FireServer(propertyId)
		setStatus("Solicitação de compra enviada...", false)
	end)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	connectPropertyPrompt(descendant)
end
workspace.DescendantAdded:Connect(connectPropertyPrompt)

local connectedEventPrompts = {}
local function connectEventPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt.Name ~= "EventPrompt" or connectedEventPrompts[prompt] then
		return
	end

	local point = prompt.Parent
	local eventId = point and point:GetAttribute("EventId")
	if type(eventId) ~= "string" then
		return
	end

	connectedEventPrompts[prompt] = true
	prompt.Triggered:Connect(function()
		selectedEventId = eventId
		setEventMarker(eventId)
		eventParticipationRequest:FireServer("Join", eventId)
		setStatus("Solicitação de participação enviada...", false)
	end)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	connectEventPrompt(descendant)
end
workspace.DescendantAdded:Connect(connectEventPrompt)

local connectedClubPrompts = {}
local function connectClubBoothPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt.Name ~= "DJBoothPrompt" or connectedClubPrompts[prompt] then
		return
	end

	connectedClubPrompts[prompt] = true
	prompt.Triggered:Connect(function()
		panel.Visible = true
		renderPage("club")
	end)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	connectClubBoothPrompt(descendant)
end
workspace.DescendantAdded:Connect(connectClubBoothPrompt)

local workPromptActions = {
	TourGuideStart = { Action = "Start", JobId = "city_guide" },
	TourGuideFinish = { Action = "Complete", JobId = "city_guide" },
	ChauffeurStart = { Action = "Start", JobId = "chauffeur" },
	ChauffeurFinish = { Action = "Complete", JobId = "chauffeur" },
	PhotographerStart = { Action = "Start", JobId = "photographer" },
	PhotographerFinish = { Action = "Complete", JobId = "photographer" },
	DJStart = { Action = "Start", JobId = "dj" },
	DJFinish = { Action = "Complete", JobId = "dj" },
	EventAnimatorStart = { Action = "Start", JobId = "event_animator" },
	EventAnimatorFinish = { Action = "Complete", JobId = "event_animator" },
	EntrepreneurStart = { Action = "Start", JobId = "entrepreneur" },
	EntrepreneurFinish = { Action = "Complete", JobId = "entrepreneur" },
	FashionDesignerStart = { Action = "Start", JobId = "fashion_designer" },
	FashionDesignerFinish = { Action = "Complete", JobId = "fashion_designer" },
	EventOrganizerStart = { Action = "Start", JobId = "event_organizer" },
	EventOrganizerFinish = { Action = "Complete", JobId = "event_organizer" },
	EstablishmentOwnerStart = { Action = "Start", JobId = "establishment_owner" },
	EstablishmentOwnerOperationsService = {
		Action = "Interact",
		JobId = "establishment_owner",
		PointName = "EstablishmentOwnerOperationsService",
	},
	EstablishmentOwnerOperationsEvents = {
		Action = "Interact",
		JobId = "establishment_owner",
		PointName = "EstablishmentOwnerOperationsEvents",
	},
	EstablishmentOwnerAuditApprove = {
		Action = "Interact",
		JobId = "establishment_owner",
		PointName = "EstablishmentOwnerAuditApprove",
	},
	EstablishmentOwnerAuditTraining = {
		Action = "Interact",
		JobId = "establishment_owner",
		PointName = "EstablishmentOwnerAuditTraining",
	},
	EstablishmentOwnerFinish = { Action = "Complete", JobId = "establishment_owner" },
	WorldCreatorStart = { Action = "Start", JobId = "world_creator" },
	WorldCreatorThemeGarden = {
		Action = "Interact",
		JobId = "world_creator",
		PointName = "WorldCreatorThemeGarden",
	},
	WorldCreatorThemeCoastal = {
		Action = "Interact",
		JobId = "world_creator",
		PointName = "WorldCreatorThemeCoastal",
	},
	WorldCreatorThemeUrban = {
		Action = "Interact",
		JobId = "world_creator",
		PointName = "WorldCreatorThemeUrban",
	},
	WorldCreatorLayoutPavilion = {
		Action = "Interact",
		JobId = "world_creator",
		PointName = "WorldCreatorLayoutPavilion",
	},
	WorldCreatorLayoutPlaza = {
		Action = "Interact",
		JobId = "world_creator",
		PointName = "WorldCreatorLayoutPlaza",
	},
	WorldCreatorLayoutPromenade = {
		Action = "Interact",
		JobId = "world_creator",
		PointName = "WorldCreatorLayoutPromenade",
	},
	WorldCreatorFinish = { Action = "Complete", JobId = "world_creator" },
}

for pointName, work in pairs(workPromptActions) do
	local world = workspace:WaitForChild("HighSocietyWorld", 30)
	local points = world and world:WaitForChild("WorkPoints", 10)
	local point = points and points:WaitForChild(pointName, 10)
	local prompt = point and point:WaitForChild("WorkPrompt", 10)

	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function()
			workJobRequest:FireServer(work.Action, work.JobId, work.PointName)
			setStatus("Solicitação enviada: " .. work.JobId, false)
		end)
	end
end

RunService.Heartbeat:Connect(function(deltaTime)
	driveAccumulator += deltaTime
	if driveAccumulator < 0.1 then
		return
	end
	driveAccumulator = 0

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local isDriving = seat
		and seat:IsA("VehicleSeat")
		and seat.Name == "DriverSeat"
		and seat.Parent
		and seat.Parent:GetAttribute("OwnerUserId") == player.UserId

	if isDriving then
		wasDriving = true
		vehicleDrive:FireServer(seat.ThrottleFloat, seat.SteerFloat)
	elseif wasDriving then
		wasDriving = false
		vehicleDrive:FireServer(0, 0)
	end
end)

task.spawn(function()
	local eventRefreshAccumulator = 0
	local clubRefreshAccumulator = 0
	while screenGui.Parent do
		task.wait(1.5)
		if refreshWorkProgress then
			refreshWorkProgress()
		end
		eventRefreshAccumulator += 1.5
		if eventRefreshAccumulator >= 4 then
			eventRefreshAccumulator = 0
			if refreshEventProgress then
				refreshEventProgress()
			end
		end
		clubRefreshAccumulator += 1.5
		if clubRefreshAccumulator >= 4.5 then
			clubRefreshAccumulator = 0
			if refreshClubProgress then
				refreshClubProgress()
			end
		end
	end
end)

-- Espera o saldo sem desistir: o servidor pode demorar para carregar os dados.
balanceLabel.Text = "Society Credits: carregando..."
task.spawn(function()
	local credits
	while not credits do
		local leaderstats = player:FindFirstChild("leaderstats")
		credits = leaderstats and leaderstats:FindFirstChild("Society Credits")
		if not credits then
			task.wait(0.5)
		end
	end
	balanceLabel.Text = string.format("Society Credits: %d", credits.Value)
	credits:GetPropertyChangedSignal("Value"):Connect(function()
		balanceLabel.Text = string.format("Society Credits: %d", credits.Value)
	end)
end)

local function updateWorldTime()
	local hour = game:GetService("Lighting").ClockTime
	local phase = game:GetService("Lighting"):GetAttribute("HSC_TimePhase") or "Dia"
	timeLabel.Text = string.format("%s • %02d:%02d", phase, math.floor(hour), math.floor((hour % 1) * 60))
end

Players.PlayerAdded:Connect(function()
	if activeTab == "players" and panel.Visible then
		renderPlayers()
	elseif activeTab == "market" and panel.Visible then
		task.delay(Config.RateLimits.MarketQueryCooldown, renderMarket)
	end
end)
Players.PlayerRemoving:Connect(function()
	if activeTab == "players" and panel.Visible then
		task.defer(renderPlayers)
	elseif activeTab == "market" and panel.Visible then
		task.delay(Config.RateLimits.MarketQueryCooldown, renderMarket)
	end
end)

local lighting = game:GetService("Lighting")
lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateWorldTime)
lighting:GetAttributeChangedSignal("HSC_TimePhase"):Connect(updateWorldTime)
updateWorldTime()

setStatus("Bem-vinda ao clube.", false)
