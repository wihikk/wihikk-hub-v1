local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local settings = {
    aimbot = false,
    wallCheck = false,
    fov = 120,
    smoothness = 30,
    predict = true,
    predictStrength = 5,
    esp = true,
    espBoxes = true,
    espHealth = true,
    espDist = true,
    espNames = true,
    tracers = false,
    clickTp = false,
    vehicleEsp = false,
    submarineEsp = true,
    uavEsp = true, 
    ugvEsp = true,
    teamCheck = true
}

local scriptConnections = {}
local isScriptActive = true

local baseSpawnCFrame = nil

local function captureSpawn(char)
    task.spawn(function()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            task.wait(1) 
            if isScriptActive then
                baseSpawnCFrame = hrp.CFrame
            end
        end
    end)
end

if LocalPlayer.Character then
    captureSpawn(LocalPlayer.Character)
end
table.insert(scriptConnections, LocalPlayer.CharacterAdded:Connect(captureSpawn))

local function safeRemoveDrawing(obj)
    if not obj then return end
    pcall(function()
        obj.Visible = false
        if obj.Remove then obj:Remove()
        elseif obj.Destroy then obj:Destroy() end
    end)
end

local function createDrawing(class, properties)
    local obj = Drawing.new(class)
    for prop, val in pairs(properties) do
        pcall(function() obj[prop] = val end)
    end
    return obj
end

local FOVring = createDrawing("Circle", {
    Thickness = 1.5,
    Radius = settings.fov,
    Transparency = 0.7,
    Color = Color3.fromRGB(255, 255, 255), 
    Filled = false,
    Visible = false,
    Position = UserInputService:GetMouseLocation()
})

local espObjects = {}
local tracerObjects = {}
local vehicles = {}
local vehicleDrawings = {}
local subDrawings = {}
local uavDrawings = {}
local ugvDrawings = {}

task.spawn(function()
    while isScriptActive do
        if settings.vehicleEsp then
            local newVehicles = {}
            local objectsToScan = workspace:GetChildren()
            local scanCount = 0
            while #objectsToScan > 0 and isScriptActive do
                local currentObj = table.remove(objectsToScan, #objectsToScan)
                if currentObj:IsA("VehicleSeat") then table.insert(newVehicles, currentObj) end
                for _, child in ipairs(currentObj:GetChildren()) do table.insert(objectsToScan, child) end
                scanCount = scanCount + 1
                if scanCount % 200 == 0 then RunService.Heartbeat:Wait() end
            end
            if isScriptActive then vehicles = newVehicles end
            task.wait(2)
        else
            task.wait(1)
        end
    end
end)

local targetParent = nil
pcall(function()
    if gethui then targetParent = gethui()
    elseif game:GetService("CoreGui") then targetParent = game:GetService("CoreGui")
    else targetParent = LocalPlayer:WaitForChild("PlayerGui") end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomOverlayMenu"
ScreenGui.ResetOnSpawn = false
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = targetParent

local Theme = {
    Background = Color3.fromRGB(0, 0, 0),
    BackgroundTrans = 0.5,
    PanelBG = Color3.fromRGB(15, 15, 15),
    PanelTrans = 0.4,
    Accent = Color3.fromRGB(220, 220, 220),
    TextMain = Color3.fromRGB(255, 255, 255),
    TextSub = Color3.fromRGB(170, 170, 170),
    Border = Color3.fromRGB(60, 60, 60),
    OffColor = Color3.fromRGB(30, 30, 30)
}

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 520, 0, 520)
Frame.Position = UDim2.new(0, 50, 0, 150)
Frame.BackgroundColor3 = Theme.Background
Frame.BackgroundTransparency = Theme.BackgroundTrans
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true -- Скрывает все, что выезжает за границы меню
Frame.Visible = true
Frame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", Frame)
MainCorner.CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke", Frame)
MainStroke.Thickness = 1.5
MainStroke.Color = Theme.Border
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local HeaderTitle = Instance.new("TextLabel", Frame)
HeaderTitle.Size = UDim2.new(0.5, 0, 0, 40)
HeaderTitle.Position = UDim2.new(0, 20, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "MENU"
HeaderTitle.TextColor3 = Theme.Accent
HeaderTitle.Font = Enum.Font.GothamBlack
HeaderTitle.TextSize = 20
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

local HeaderSub = Instance.new("TextLabel", Frame)
HeaderSub.Size = UDim2.new(0.5, -20, 0, 40)
HeaderSub.Position = UDim2.new(0.5, 0, 0, 0)
HeaderSub.BackgroundTransparency = 1
HeaderSub.Text = "made by wihikk"
HeaderSub.TextColor3 = Theme.TextSub
HeaderSub.Font = Enum.Font.GothamMedium
HeaderSub.TextSize = 12
HeaderSub.TextXAlignment = Enum.TextXAlignment.Right

local TabContainer = Instance.new("Frame", Frame)
TabContainer.Size = UDim2.new(1, -40, 0, 30)
TabContainer.Position = UDim2.new(0, 20, 0, 40)
TabContainer.BackgroundTransparency = 1

local TabList = Instance.new("UIListLayout", TabContainer)
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0, 20)

local Divider = Instance.new("Frame", Frame)
Divider.Size = UDim2.new(1, -40, 0, 1)
Divider.Position = UDim2.new(0, 20, 0, 75)
Divider.BackgroundColor3 = Theme.Border
Divider.BorderSizePixel = 0

local tabs = {}
local activePage = nil

local function createPage(name)
    local Page = Instance.new("Frame", Frame)
    Page.Name = name
    Page.Size = UDim2.new(1, 0, 1, -170)
    Page.Position = UDim2.new(0, 0, 0, 85)
    Page.BackgroundTransparency = 1
    Page.Visible = false

    local Left = Instance.new("Frame", Page)
    Left.Size = UDim2.new(0.5, -25, 1, 0)
    Left.Position = UDim2.new(0, 20, 0, 0)
    Left.BackgroundTransparency = 1
    local LLayout = Instance.new("UIListLayout", Left)
    LLayout.SortOrder = Enum.SortOrder.LayoutOrder; LLayout.Padding = UDim.new(0, 10)

    local Right = Instance.new("Frame", Page)
    Right.Size = UDim2.new(0.5, -25, 1, 0)
    Right.Position = UDim2.new(0.5, 5, 0, 0)
    Right.BackgroundTransparency = 1
    local RLayout = Instance.new("UIListLayout", Right)
    RLayout.SortOrder = Enum.SortOrder.LayoutOrder; RLayout.Padding = UDim.new(0, 10)

    return Page, Left, Right
end

local function createTabButton(name, pageObject, isDefault)
    local Btn = Instance.new("TextButton", TabContainer)
    Btn.Size = UDim2.new(0, 70, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = name
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextColor3 = isDefault and Theme.Accent or Theme.TextSub

    local Indicator = Instance.new("Frame", Btn)
    Indicator.Size = UDim2.new(1, 0, 0, 2)
    Indicator.Position = UDim2.new(0, 0, 1, -2)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BorderSizePixel = 0
    Indicator.Visible = isDefault

    Btn.MouseButton1Click:Connect(function()
        if activePage == pageObject then return end

        local oldIdx, newIdx = 1, 1
        for i, tab in ipairs(tabs) do
            if tab.page == activePage then oldIdx = i end
            if tab.page == pageObject then newIdx = i end
        end
        local dir = (newIdx > oldIdx) and 1 or -1

        for _, tab in pairs(tabs) do
            tab.btn.TextColor3 = Theme.TextSub
            tab.ind.Visible = false
        end
        
        Btn.TextColor3 = Theme.Accent
        Indicator.Visible = true

        local oldPage = activePage
        activePage = pageObject
        
        if oldPage then
            TweenService:Create(oldPage, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(-dir, 0, 0, 85)
            }):Play()
            task.delay(0.3, function()
                if activePage ~= oldPage then
                    oldPage.Visible = false
                end
            end)
        end
        
        pageObject.Position = UDim2.new(dir, 0, 0, 85)
        pageObject.Visible = true
        TweenService:Create(pageObject, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 85)
        }):Play()
    end)

    table.insert(tabs, {btn = Btn, ind = Indicator, page = pageObject})
    if isDefault then 
        activePage = pageObject
        pageObject.Position = UDim2.new(0, 0, 0, 85)
        pageObject.Visible = true 
    end
end

local BottomPanel = Instance.new("Frame", Frame)
BottomPanel.Size = UDim2.new(1, -40, 0, 50)
BottomPanel.Position = UDim2.new(0, 20, 1, -85)
BottomPanel.BackgroundTransparency = 1
local BottomLayout = Instance.new("UIListLayout", BottomPanel)
BottomLayout.SortOrder = Enum.SortOrder.LayoutOrder; BottomLayout.Padding = UDim.new(0, 10)

local dragging, dragInput, dragStart, startPos
local function update(input)
    if not dragStart or not startPos then return end
    local delta = input.Position - dragStart
    Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
table.insert(scriptConnections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end))

local function createGroup(parent)
    local Group = Instance.new("Frame", parent)
    Group.Size = UDim2.new(1, 0, 0, 0)
    Group.BackgroundColor3 = Theme.PanelBG
    Group.BackgroundTransparency = Theme.PanelTrans
    Group.BorderSizePixel = 0
    Instance.new("UICorner", Group).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke", Group)
    Stroke.Thickness = 1; Stroke.Color = Theme.Border; Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local Layout = Instance.new("UIListLayout", Group)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function updateSize()
        Group.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
    end
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
    task.defer(updateSize)
    
    return Group
end

local function createToggle(name, parent, state, callback)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, 0, 0, 38)
    Container.BackgroundTransparency = 1 
    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name; Label.TextColor3 = Theme.TextMain; Label.Font = Enum.Font.GothamMedium; Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left
    local BtnBG = Instance.new("TextButton", Container)
    BtnBG.Size = UDim2.new(0, 42, 0, 22)
    BtnBG.AnchorPoint = Vector2.new(1, 0.5); BtnBG.Position = UDim2.new(1, -12, 0.5, 0)
    BtnBG.Text = ""; BtnBG.AutoButtonColor = false
    BtnBG.BackgroundColor3 = state and Theme.Accent or Theme.OffColor
    Instance.new("UICorner", BtnBG).CornerRadius = UDim.new(1, 0)
    local Indicator = Instance.new("Frame", BtnBG)
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Indicator.BackgroundColor3 = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    BtnBG.MouseButton1Click:Connect(function()
        state = not state; callback(state)
        local targetColor = state and Theme.Accent or Theme.OffColor
        local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetIndColor = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
        TweenService:Create(BtnBG, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = targetPos, BackgroundColor3 = targetIndColor}):Play()
    end)
    return Container
end

local function createSlider(name, parent, min, max, default, callback)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, 0, 0, 52)
    Container.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(0.5, 0, 0, 20); Label.Position = UDim2.new(0, 12, 0, 6)
    Label.BackgroundTransparency = 1; Label.Text = name; Label.TextColor3 = Theme.TextMain; Label.Font = Enum.Font.GothamMedium; Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left
    local ValueText = Instance.new("TextLabel", Container)
    ValueText.Size = UDim2.new(0.5, 0, 0, 20); ValueText.AnchorPoint = Vector2.new(1, 0); ValueText.Position = UDim2.new(1, -12, 0, 6)
    ValueText.BackgroundTransparency = 1; ValueText.Text = tostring(default); ValueText.TextColor3 = Theme.Accent; ValueText.Font = Enum.Font.GothamBold; ValueText.TextSize = 13; ValueText.TextXAlignment = Enum.TextXAlignment.Right
    local SliderBG = Instance.new("TextButton", Container)
    SliderBG.Size = UDim2.new(1, -24, 0, 6); SliderBG.AnchorPoint = Vector2.new(0.5, 0); SliderBG.Position = UDim2.new(0.5, 0, 0, 34)
    SliderBG.BackgroundColor3 = Theme.OffColor; SliderBG.Text = ""; SliderBG.AutoButtonColor = false
    Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1, 0)
    local SliderFill = Instance.new("Frame", SliderBG)
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0); SliderFill.BackgroundColor3 = Theme.Accent
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
    local SliderThumb = Instance.new("Frame", SliderFill)
    SliderThumb.Size = UDim2.new(0, 12, 0, 12); SliderThumb.AnchorPoint = Vector2.new(0.5, 0.5); SliderThumb.Position = UDim2.new(1, 0, 0.5, 0); SliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", SliderThumb).CornerRadius = UDim.new(1, 0)

    local isDragging = false
    local function updateSlider(input)
        local rawPos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * rawPos))
        local snappedPos = (val - min) / (max - min)
        TweenService:Create(SliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(snappedPos, 0, 1, 0)}):Play()
        ValueText.Text = tostring(val); callback(val)
    end
    SliderBG.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = true; updateSlider(input) end end)
    table.insert(scriptConnections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end end))
    table.insert(scriptConnections, UserInputService.InputChanged:Connect(function(input) if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end end))
end

local function createActionButton(name, parent, callback)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, 0, 0, 38)
    Container.BackgroundTransparency = 1 
    local BtnBG = Instance.new("TextButton", Container)
    BtnBG.Size = UDim2.new(1, -24, 0, 26)
    BtnBG.AnchorPoint = Vector2.new(0.5, 0.5); BtnBG.Position = UDim2.new(0.5, 0, 0.5, 0)
    BtnBG.Text = name; BtnBG.TextColor3 = Theme.TextMain; BtnBG.Font = Enum.Font.GothamMedium; BtnBG.TextSize = 13
    BtnBG.AutoButtonColor = false; BtnBG.BackgroundColor3 = Theme.OffColor
    Instance.new("UICorner", BtnBG).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", BtnBG)
    Stroke.Color = Theme.Border; Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BtnBG.MouseButton1Click:Connect(function()
        TweenService:Create(BtnBG, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
        task.delay(0.1, function() TweenService:Create(BtnBG, TweenInfo.new(0.2), {BackgroundColor3 = Theme.OffColor}):Play() end)
        callback()
    end)
end

local function createDualActionButtons(name1, name2, parent, callback1, callback2)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, 0, 0, 38)
    Container.BackgroundTransparency = 1 

    local Btn1 = Instance.new("TextButton", Container)
    Btn1.Size = UDim2.new(0.5, -16, 0, 26)
    Btn1.AnchorPoint = Vector2.new(0, 0.5); Btn1.Position = UDim2.new(0, 12, 0.5, 0)
    Btn1.Text = name1; Btn1.TextColor3 = Theme.TextMain; Btn1.Font = Enum.Font.GothamMedium; Btn1.TextSize = 12
    Btn1.AutoButtonColor = false; Btn1.BackgroundColor3 = Theme.OffColor
    Instance.new("UICorner", Btn1).CornerRadius = UDim.new(0, 6)
    local Stroke1 = Instance.new("UIStroke", Btn1); Stroke1.Color = Theme.Border; Stroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Btn1.MouseButton1Click:Connect(function()
        TweenService:Create(Btn1, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
        task.delay(0.1, function() TweenService:Create(Btn1, TweenInfo.new(0.2), {BackgroundColor3 = Theme.OffColor}):Play() end); callback1()
    end)

    local Btn2 = Instance.new("TextButton", Container)
    Btn2.Size = UDim2.new(0.5, -16, 0, 26)
    Btn2.AnchorPoint = Vector2.new(1, 0.5); Btn2.Position = UDim2.new(1, -12, 0.5, 0)
    Btn2.Text = name2; Btn2.TextColor3 = Theme.TextMain; Btn2.Font = Enum.Font.GothamMedium; Btn2.TextSize = 12
    Btn2.AutoButtonColor = false; Btn2.BackgroundColor3 = Theme.OffColor
    Instance.new("UICorner", Btn2).CornerRadius = UDim.new(0, 6)
    local Stroke2 = Instance.new("UIStroke", Btn2); Stroke2.Color = Theme.Border; Stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Btn2.MouseButton1Click:Connect(function()
        TweenService:Create(Btn2, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
        task.delay(0.1, function() TweenService:Create(Btn2, TweenInfo.new(0.2), {BackgroundColor3 = Theme.OffColor}):Play() end); callback2()
    end)
end

local function createSubGrid(parent)
    local Wrapper = Instance.new("Frame", parent)
    Wrapper.Size = UDim2.new(1, 0, 0, 60); Wrapper.BackgroundTransparency = 1
    local Padding = Instance.new("UIPadding", Wrapper)
    Padding.PaddingLeft = UDim.new(0, 10); Padding.PaddingRight = UDim.new(0, 10); Padding.PaddingBottom = UDim.new(0, 10)
    local UIGrid = Instance.new("UIGridLayout", Wrapper)
    UIGrid.CellSize = UDim2.new(0.48, 0, 0, 22); UIGrid.CellPadding = UDim2.new(0.04, 0, 0, 6); UIGrid.SortOrder = Enum.SortOrder.LayoutOrder
    return Wrapper
end

local function createSubButton(name, parent, state, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.BackgroundColor3 = state and Theme.Accent or Theme.OffColor
    Btn.TextColor3 = state and Color3.fromRGB(0, 0, 0) or Theme.TextSub
    Btn.Font = Enum.Font.GothamMedium; Btn.TextSize = 11; Btn.Text = name; Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(function()
        state = not state; callback(state)
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.Accent or Theme.OffColor, TextColor3 = state and Color3.fromRGB(0, 0, 0) or Theme.TextSub}):Play()
    end)
end

local PageCombat, CombatLeft, CombatRight = createPage("Combat")
local PageVisuals, VisualsLeft, VisualsRight = createPage("Visuals")

createTabButton("Combat", PageCombat, true)
createTabButton("Visuals", PageVisuals, false)

local AimbotGroup = createGroup(CombatLeft)
createToggle("Aimbot (RMB)", AimbotGroup, settings.aimbot, function(v) settings.aimbot = v end)
createToggle("Wall Check", AimbotGroup, settings.wallCheck, function(v) settings.wallCheck = v end)
createSlider("Aimbot FOV", AimbotGroup, 20, 400, settings.fov, function(v) settings.fov = v end)
createSlider("Smoothness", AimbotGroup, 0, 100, settings.smoothness, function(v) settings.smoothness = v end)
createToggle("Predict", AimbotGroup, settings.predict, function(v) settings.predict = v end)
createSlider("Predict Strength", AimbotGroup, 1, 100, settings.predictStrength, function(v) settings.predictStrength = v end)

local MiscGroup = createGroup(CombatRight)
createToggle("Click TP (LMB)", MiscGroup, settings.clickTp, function(v) settings.clickTp = v end)
createActionButton("TP to Base", MiscGroup, function()
    if baseSpawnCFrame then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = baseSpawnCFrame
        end
    end
end)

local EspGroup = createGroup(VisualsLeft)
createToggle("Player ESP", EspGroup, settings.esp, function(v) settings.esp = v end)
local EspGrid = createSubGrid(EspGroup)
createSubButton("Boxes", EspGrid, settings.espBoxes, function(v) settings.espBoxes = v end)
createSubButton("Health", EspGrid, settings.espHealth, function(v) settings.espHealth = v end)
createSubButton("Distance", EspGrid, settings.espDist, function(v) settings.espDist = v end)
createSubButton("Names", EspGrid, settings.espNames, function(v) settings.espNames = v end)
createToggle("Tracers", EspGroup, settings.tracers, function(v) settings.tracers = v end)

local EnvGroup = createGroup(VisualsRight)

local vehicleToggle = createToggle("Vehicle ESP", EnvGroup, settings.vehicleEsp, function(v) 
    settings.vehicleEsp = v 
    if not v then
        for i, draw in pairs(vehicleDrawings) do
            safeRemoveDrawing(draw.box); safeRemoveDrawing(draw.text)
            vehicleDrawings[i] = nil
        end
    end
end)

local waitLabel = Instance.new("TextLabel", vehicleToggle)
waitLabel.Size = UDim2.new(0, 100, 1, 0)
waitLabel.AnchorPoint = Vector2.new(1, 0.5)
waitLabel.Position = UDim2.new(1, -62, 0.5, 0)
waitLabel.BackgroundTransparency = 1
waitLabel.Text = "wait ≈15 seconds"
waitLabel.TextColor3 = Theme.TextSub
waitLabel.Font = Enum.Font.Gotham
waitLabel.TextSize = 10
waitLabel.TextXAlignment = Enum.TextXAlignment.Right

createToggle("Submarine ESP", EnvGroup, settings.submarineEsp, function(v) 
    settings.submarineEsp = v
    if not v then
        for i, draw in pairs(subDrawings) do
            safeRemoveDrawing(draw.box); safeRemoveDrawing(draw.text)
            subDrawings[i] = nil
        end
    end
end)

createToggle("UAV ESP", EnvGroup, settings.uavEsp, function(v) 
    settings.uavEsp = v
    if not v then
        for i, draw in pairs(uavDrawings) do
            safeRemoveDrawing(draw.box); safeRemoveDrawing(draw.text)
            uavDrawings[i] = nil
        end
    end
end) 

createToggle("UGV ESP", EnvGroup, settings.ugvEsp, function(v) 
    settings.ugvEsp = v
    if not v then
        for i, draw in pairs(ugvDrawings) do
            safeRemoveDrawing(draw.box); safeRemoveDrawing(draw.text)
            ugvDrawings[i] = nil
        end
    end
end)

local ServerGroup = createGroup(BottomPanel)
createDualActionButtons("Rejoin", "Server Hop", ServerGroup, 
    function()
        if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, LocalPlayer) else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end
    end, 
    function()
        pcall(function()
            local response = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
            if response then
                local data = HttpService:JSONDecode(response)
                local validServers = {}
                if data and data.data then
                    for _, server in ipairs(data.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then table.insert(validServers, server.id) end
                    end
                end
                if #validServers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, validServers[math.random(1, #validServers)], LocalPlayer) return end
            end
        end)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
)

local Footer = Instance.new("TextLabel", Frame)
Footer.Size = UDim2.new(1, 0, 0, 20); Footer.Position = UDim2.new(0, 0, 1, -25); Footer.BackgroundTransparency = 1
Footer.Text = "[K] - Toggle Menu  •  [Delete] - Unload"; Footer.TextColor3 = Theme.TextSub; Footer.Font = Enum.Font.GothamMedium; Footer.TextSize = 11

local guiVisible = true

local function UnloadScript()
    isScriptActive = false 
    for _, connection in pairs(scriptConnections) do if connection.Disconnect then pcall(function() connection:Disconnect() end) end end
    table.clear(scriptConnections)
    safeRemoveDrawing(FOVring)
    
    local function cleanDrawings(tbl)
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                for _, d in pairs(v) do safeRemoveDrawing(d) end
            else
                safeRemoveDrawing(v)
            end
        end
        table.clear(tbl)
    end

    cleanDrawings(espObjects); cleanDrawings(tracerObjects); cleanDrawings(vehicleDrawings); cleanDrawings(subDrawings); cleanDrawings(uavDrawings); cleanDrawings(ugvDrawings)
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
end

table.insert(scriptConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        guiVisible = not guiVisible
        Frame.Visible = guiVisible
    end
    if input.KeyCode == Enum.KeyCode.Delete then
        UnloadScript()
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and settings.clickTp then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

local function checkVisibility(targetChar)
    local head = targetChar:FindFirstChild("Head")
    if not head then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    params.IgnoreWater = true
    local result = workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, params)
    return not result 
end

local function getClosestTarget()
    local mouseLoc = UserInputService:GetMouseLocation()
    local closest, bestDist = nil, settings.fov
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                if not settings.teamCheck or player.Team ~= LocalPlayer.Team then
                    local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                    if onScreen and pos.Z > 0 then
                        local dist = (mouseLoc - Vector2.new(pos.X, pos.Y)).Magnitude
                        if dist <= bestDist then
                            if not settings.wallCheck or checkVisibility(player.Character) then
                                bestDist = dist
                                closest = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function createPlayerESP(player)
    if espObjects[player] then return end
    espObjects[player] = {
        box = createDrawing("Square", {Thickness = 1.5, Visible = false}),
        healthText = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(255, 255, 255), Outline = true, Visible = false}),
        toolText = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(241, 196, 15), Outline = true, Visible = false}),
        distText = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(255, 255, 255), Outline = true, Visible = false}),
        nameText = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(255, 255, 255), Outline = true, Visible = false})
    }
    tracerObjects[player] = createDrawing("Line", {Thickness = 1, Visible = false})
end

local function removePlayerAssets(player)
    if espObjects[player] then for _, v in pairs(espObjects[player]) do safeRemoveDrawing(v) end; espObjects[player] = nil end
    if tracerObjects[player] then safeRemoveDrawing(tracerObjects[player]); tracerObjects[player] = nil end
end

local function hideESP(esp)
    if not esp then return end
    for _, v in pairs(esp) do pcall(function() v.Visible = false end) end
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createPlayerESP(p) end end
table.insert(scriptConnections, Players.PlayerAdded:Connect(createPlayerESP))
table.insert(scriptConnections, Players.PlayerRemoving:Connect(removePlayerAssets))

table.insert(scriptConnections, RunService.RenderStepped:Connect(function()
    local targetLocked = false
    if settings.aimbot == true then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = getClosestTarget()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                targetLocked = true 
                local aimPos = target.Character.Head.Position
                if settings.predict and target.Character:FindFirstChild("HumanoidRootPart") then
                    local targetVelocity = target.Character.HumanoidRootPart.AssemblyLinearVelocity
                    local predictOffset = targetVelocity * (settings.predictStrength / 100)
                    aimPos = aimPos + predictOffset
                end
                local targetCFrame = CFrame.new(Camera.CFrame.Position, aimPos)
                if settings.smoothness > 0 then
                    local smoothAlpha = math.clamp((100 - settings.smoothness) / 100, 0.02, 1)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothAlpha)
                else
                    Camera.CFrame = targetCFrame
                end
            end
        end
    end

    pcall(function()
        FOVring.Position = UserInputService:GetMouseLocation()
        FOVring.Radius = settings.fov
        FOVring.Visible = settings.aimbot
        FOVring.Color = targetLocked and Color3.fromRGB(235, 94, 85) or Color3.fromRGB(255, 255, 255)
    end)

    for player, esp in pairs(espObjects) do
        local char = player.Character
        if settings.esp and player ~= LocalPlayer and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if not settings.teamCheck or player.Team ~= LocalPlayer.Team then
                local bottom3D = char.HumanoidRootPart.Position - Vector3.new(0, 3, 0)
                local top3D = char.Head.Position + Vector3.new(0, 0.5, 0)
                local bottom2D, onScreenBottom = Camera:WorldToViewportPoint(bottom3D)
                local top2D, onScreenTop = Camera:WorldToViewportPoint(top3D)
                if (onScreenBottom or onScreenTop) and bottom2D.Z > 0 then
                    local height = math.abs(bottom2D.Y - top2D.Y)
                    local width = height / 1.5
                    local boxPos = Vector2.new(top2D.X - width/2, top2D.Y)
                    local distance = math.floor((Camera.CFrame.Position - char.HumanoidRootPart.Position).Magnitude)
                    local teamColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 60, 60)
                    if settings.espBoxes then pcall(function() esp.box.Size = Vector2.new(width, height); esp.box.Position = boxPos; esp.box.Color = teamColor; esp.box.Visible = true end) else pcall(function() esp.box.Visible = false end) end
                    if settings.espHealth then pcall(function() esp.healthText.Text = tostring(math.floor(char.Humanoid.Health)) .. " HP"; esp.healthText.Color = Color3.fromRGB(100, 255, 100); esp.healthText.Position = Vector2.new(boxPos.X - 25, boxPos.Y + (height / 2) - 6); esp.healthText.Visible = true end) else pcall(function() esp.healthText.Visible = false end) end
                    if settings.espDist then pcall(function() esp.distText.Text = tostring(distance) .. "m"; esp.distText.Position = Vector2.new(boxPos.X + width / 2, boxPos.Y - 16); esp.distText.Visible = true end) else pcall(function() esp.distText.Visible = false end) end
                    local tool = char:FindFirstChildOfClass("Tool")
                    local currentY = boxPos.Y + height + 3
                    if tool and settings.espNames then pcall(function() esp.toolText.Text = "[" .. tool.Name .. "]"; esp.toolText.Position = Vector2.new(boxPos.X + width / 2, currentY); esp.toolText.Visible = true end); currentY = currentY + 14 else pcall(function() esp.toolText.Visible = false end) end
                    if settings.espNames then pcall(function() esp.nameText.Text = player.Name; esp.nameText.Position = Vector2.new(boxPos.X + width / 2, currentY); esp.nameText.Visible = true end) else pcall(function() esp.nameText.Visible = false end) end
                else hideESP(esp) end
            else hideESP(esp) end
        else hideESP(esp) end
    end

    for player, line in pairs(tracerObjects) do
        local char = player.Character
        if settings.tracers and player ~= LocalPlayer and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if not settings.teamCheck or player.Team ~= LocalPlayer.Team then
                local pos, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                if onScreen and pos.Z > 0 then
                    local teamColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 60, 60)
                    pcall(function() line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); line.To = Vector2.new(pos.X, pos.Y); line.Color = teamColor; line.Visible = true end)
                else pcall(function() line.Visible = false end) end
            else pcall(function() line.Visible = false end) end
        else pcall(function() if line then line.Visible = false end end) end
    end

    if settings.vehicleEsp then
        for i, seat in ipairs(vehicles) do
            if seat and seat.Parent then
                if not vehicleDrawings[i] then vehicleDrawings[i] = { box = createDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(150, 150, 255), Filled = false, Visible = false}), text = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(150, 150, 255), Outline = true, Visible = false}) } end
                pcall(function()
                    local model = seat:FindFirstAncestorOfClass("Model"); local cf, size = seat.CFrame, seat.Size; local name = "Vehicle"
                    if model then cf, size = model:GetBoundingBox(); name = model.Name end
                    if cf.Position.Y < 0 then vehicleDrawings[i].box.Visible = false; vehicleDrawings[i].text.Visible = false return end
                    local boxScale = 0.65; local sx, sy, sz = (size.X / 2) * boxScale, (size.Y / 2) * boxScale, (size.Z / 2) * boxScale
                    local corners = { (cf * CFrame.new(sx, sy, sz)).Position, (cf * CFrame.new(-sx, sy, sz)).Position, (cf * CFrame.new(sx, -sy, sz)).Position, (cf * CFrame.new(sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, sz)).Position, (cf * CFrame.new(sx, -sy, -sz)).Position, (cf * CFrame.new(-sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, -sz)).Position }
                    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; local allInFront = true
                    for _, corner3D in ipairs(corners) do
                        local pos2D, onScreen = Camera:WorldToViewportPoint(corner3D)
                        if pos2D.Z <= 0 then allInFront = false break end
                        minX = math.min(minX, pos2D.X); minY = math.min(minY, pos2D.Y); maxX = math.max(maxX, pos2D.X); maxY = math.max(maxY, pos2D.Y)
                    end
                    if allInFront then
                        vehicleDrawings[i].box.Size = Vector2.new(maxX - minX, maxY - minY); vehicleDrawings[i].box.Position = Vector2.new(minX, minY); vehicleDrawings[i].box.Visible = true
                        local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); vehicleDrawings[i].text.Text = "[" .. name .. "] " .. dist .. "m"; vehicleDrawings[i].text.Position = Vector2.new(minX + (maxX - minX)/2, maxY + 5); vehicleDrawings[i].text.Visible = true
                    else
                        local centerPos, centerOnScreen = Camera:WorldToViewportPoint(cf.Position)
                        if centerOnScreen and centerPos.Z > 0 then
                            vehicleDrawings[i].box.Visible = false; local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); vehicleDrawings[i].text.Text = "[" .. name .. "] " .. dist .. "m"; vehicleDrawings[i].text.Position = Vector2.new(centerPos.X, centerPos.Y); vehicleDrawings[i].text.Visible = true
                        else vehicleDrawings[i].box.Visible = false; vehicleDrawings[i].text.Visible = false end
                    end
                end)
            end
        end
    end

    if settings.submarineEsp then
        local subWorkspace = workspace:FindFirstChild("Game Systems") and workspace["Game Systems"]:FindFirstChild("Submarine Workspace")
        local currentSubs = {}
        if subWorkspace then for _, obj in ipairs(subWorkspace:GetChildren()) do if obj:IsA("Model") then table.insert(currentSubs, obj) end end end
        for i, model in ipairs(currentSubs) do
            if not subDrawings[i] then subDrawings[i] = { box = createDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(0, 255, 255), Filled = false, Visible = false}), text = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(0, 255, 255), Outline = true, Visible = false}) } end
            pcall(function()
                local cf, size = model:GetBoundingBox()
                if cf.Position.Y < 0 then subDrawings[i].box.Visible = false; subDrawings[i].text.Visible = false return end
                local sx, sy, sz = size.X / 2, size.Y / 2, size.Z / 2
                local corners = { (cf * CFrame.new(sx, sy, sz)).Position, (cf * CFrame.new(-sx, sy, sz)).Position, (cf * CFrame.new(sx, -sy, sz)).Position, (cf * CFrame.new(sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, sz)).Position, (cf * CFrame.new(sx, -sy, -sz)).Position, (cf * CFrame.new(-sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, -sz)).Position }
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; local allInFront = true
                for _, corner3D in ipairs(corners) do
                    local pos2D, onScreen = Camera:WorldToViewportPoint(corner3D); if pos2D.Z <= 0 then allInFront = false break end
                    minX = math.min(minX, pos2D.X); minY = math.min(minY, pos2D.Y); maxX = math.max(maxX, pos2D.X); maxY = math.max(maxY, pos2D.Y)
                end
                if allInFront then
                    subDrawings[i].box.Size = Vector2.new(maxX - minX, maxY - minY); subDrawings[i].box.Position = Vector2.new(minX, minY); subDrawings[i].box.Visible = true; local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); subDrawings[i].text.Text = "[" .. model.Name .. "] " .. dist .. "m"; subDrawings[i].text.Position = Vector2.new(minX + (maxX - minX)/2, maxY + 5); subDrawings[i].text.Visible = true
                else
                    local centerPos, centerOnScreen = Camera:WorldToViewportPoint(cf.Position)
                    if centerOnScreen and centerPos.Z > 0 then subDrawings[i].box.Visible = false; local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); subDrawings[i].text.Text = "[" .. model.Name .. "] " .. dist .. "m"; subDrawings[i].text.Position = Vector2.new(centerPos.X, centerPos.Y); subDrawings[i].text.Visible = true else subDrawings[i].box.Visible = false; subDrawings[i].text.Visible = false end
                end
            end)
        end
    end

    if settings.uavEsp then 
        local uavWorkspace = workspace:FindFirstChild("Game Systems") and workspace["Game Systems"]:FindFirstChild("Plane Workspace")
        local currentUavs = {}; local allowed = { ["S-70 Okhotnik"] = true, ["MQ-1 Predator"] = true, ["TB2 Bayraktar"] = true, ["MQ-9 Reaper"] = true }
        if uavWorkspace then for _, obj in ipairs(uavWorkspace:GetChildren()) do if obj:IsA("Model") and allowed[obj.Name] then table.insert(currentUavs, obj) end end end
        for i, model in ipairs(currentUavs) do
            if not uavDrawings[i] then uavDrawings[i] = { box = createDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(255, 140, 0), Filled = false, Visible = false}), text = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(255, 140, 0), Outline = true, Visible = false}) } end
            pcall(function()
                local cf, size = model:GetBoundingBox()
                local boxScale = 0.5; local sx, sy, sz = (size.X / 2) * boxScale, (size.Y / 2) * boxScale, (size.Z / 2) * boxScale
                local corners = { (cf * CFrame.new(sx, sy, sz)).Position, (cf * CFrame.new(-sx, sy, sz)).Position, (cf * CFrame.new(sx, -sy, sz)).Position, (cf * CFrame.new(sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, sz)).Position, (cf * CFrame.new(sx, -sy, -sz)).Position, (cf * CFrame.new(-sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, -sz)).Position }
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; local allInFront = true
                for _, corner3D in ipairs(corners) do
                    local pos2D, onScreen = Camera:WorldToViewportPoint(corner3D); if pos2D.Z <= 0 then allInFront = false break end
                    minX = math.min(minX, pos2D.X); minY = math.min(minY, pos2D.Y); maxX = math.max(maxX, pos2D.X); maxY = math.max(maxY, pos2D.Y)
                end
                if allInFront then
                    uavDrawings[i].box.Size = Vector2.new(maxX - minX, maxY - minY); uavDrawings[i].box.Position = Vector2.new(minX, minY); uavDrawings[i].box.Visible = true; local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); uavDrawings[i].text.Text = "[" .. model.Name .. "] " .. dist .. "m"; uavDrawings[i].text.Position = Vector2.new(minX + (maxX - minX)/2, maxY + 5); uavDrawings[i].text.Visible = true
                else
                    local centerPos, centerOnScreen = Camera:WorldToViewportPoint(cf.Position)
                    if centerOnScreen and centerPos.Z > 0 then uavDrawings[i].box.Visible = false; local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); uavDrawings[i].text.Text = "[" .. model.Name .. "] " .. dist .. "m"; uavDrawings[i].text.Position = Vector2.new(centerPos.X, centerPos.Y); uavDrawings[i].text.Visible = true else uavDrawings[i].box.Visible = false; uavDrawings[i].text.Visible = false end
                end
            end)
        end
    end

    if settings.ugvEsp then
        local tankWorkspace = workspace:FindFirstChild("Game Systems") and workspace["Game Systems"]:FindFirstChild("Tank Workspace")
        local currentUgvs = {}; local allowed = { ["Ripsaw M5"] = true, ["Aselsan Gurz"] = true }
        if tankWorkspace then for _, obj in ipairs(tankWorkspace:GetChildren()) do if obj:IsA("Model") and allowed[obj.Name] then table.insert(currentUgvs, obj) end end end
        for i, model in ipairs(currentUgvs) do
            if not ugvDrawings[i] then ugvDrawings[i] = { box = createDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(120, 255, 120), Filled = false, Visible = false}), text = createDrawing("Text", {Center = true, Size = 13, Font = 2, Color = Color3.fromRGB(120, 255, 120), Outline = true, Visible = false}) } end
            pcall(function()
                local cf, size = model:GetBoundingBox()
                local scale = 0.65; local sx, sy, sz = (size.X / 2) * scale, (size.Y / 2) * scale, (size.Z / 2) * scale
                local corners = { (cf * CFrame.new(sx, sy, sz)).Position, (cf * CFrame.new(-sx, sy, sz)).Position, (cf * CFrame.new(sx, -sy, sz)).Position, (cf * CFrame.new(sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, sz)).Position, (cf * CFrame.new(sx, -sy, -sz)).Position, (cf * CFrame.new(-sx, sy, -sz)).Position, (cf * CFrame.new(-sx, -sy, -sz)).Position }
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge; local allInFront = true
                for _, corner3D in ipairs(corners) do
                    local pos2D, onScreen = Camera:WorldToViewportPoint(corner3D); if pos2D.Z <= 0 then allInFront = false break end
                    minX = math.min(minX, pos2D.X); minY = math.min(minY, pos2D.Y); maxX = math.max(maxX, pos2D.X); maxY = math.max(maxY, pos2D.Y)
                end
                if allInFront then
                    ugvDrawings[i].box.Size = Vector2.new(maxX - minX, maxY - minY); ugvDrawings[i].box.Position = Vector2.new(minX, minY); ugvDrawings[i].box.Visible = true; local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); ugvDrawings[i].text.Text = "[" .. model.Name .. "] " .. dist .. "m"; ugvDrawings[i].text.Position = Vector2.new(minX + (maxX - minX)/2, maxY + 5); ugvDrawings[i].text.Visible = true
                else
                    local centerPos, centerOnScreen = Camera:WorldToViewportPoint(cf.Position)
                    if centerOnScreen and centerPos.Z > 0 then ugvDrawings[i].box.Visible = false; local dist = math.floor((Camera.CFrame.Position - cf.Position).Magnitude); ugvDrawings[i].text.Text = "[" .. model.Name .. "] " .. dist .. "m"; ugvDrawings[i].text.Position = Vector2.new(centerPos.X, centerPos.Y); ugvDrawings[i].text.Visible = true else ugvDrawings[i].box.Visible = false; ugvDrawings[i].text.Visible = false end
                end
            end)
        end
    end
end))
