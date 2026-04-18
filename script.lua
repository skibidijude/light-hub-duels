local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Unloading = false

local Config = {
    UILocked = false
}

-- Remove accessories
local function RemoveAccessories(character)
    if not character then return end
    for _, v in ipairs(character:GetChildren()) do
        if v:IsA("Accessory") then
            v:Destroy()
        end
    end
end

if LocalPlayer.Character then
    RemoveAccessories(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(RemoveAccessories)

-- [AUTO STEAL LOGIC]
local AUTO_STEAL_NEAREST = false
local AnimalsData = nil
pcall(function()
    AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
end)
if not AnimalsData then AnimalsData = {} end

local allAnimalsCache = {}
local PromptMemoryCache = {}
local InternalStealCache = {}
local LastTargetUID = nil
local LastPlayerPosition = nil
local PlayerVelocity = Vector3.zero

local AUTO_STEAL_PROX_RADIUS = 20
local IsStealing = false
local StealProgress = 0
local CurrentStealTarget = nil
local StealStartTime = 0

local CIRCLE_RADIUS = AUTO_STEAL_PROX_RADIUS
local PART_THICKNESS = 0.3
local PART_HEIGHT = 0.2
local PART_COLOR = Color3.fromRGB(0, 255, 255)
local PartsCount = 65
local circleParts = {}
local circleEnabled = true

local stealConnection = nil
local velocityConnection = nil

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
end

local function isMyBase(plotName)
    local plot = workspace.Plots:FindFirstChild(plotName)
    if not plot then return false end
    
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yourBase = sign:FindFirstChild("YourBase")
        if yourBase and yourBase:IsA("BillboardGui") then
            return yourBase.Enabled == true
        end
    end
    return false
end

local function scanSinglePlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    
    for _, podium in ipairs(podiums:GetChildren()) do
        if podium:IsA("Model") and podium:FindFirstChild("Base") then
            local animalName = "Unknown"
            local spawn = podium.Base:FindFirstChild("Spawn")
            if spawn then
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "PromptAttachment" then
                        animalName = child.Name
                        local animalInfo = AnimalsData[animalName]
                        if animalInfo and animalInfo.DisplayName then
                            animalName = animalInfo.DisplayName
                        end
                        break
                    end
                end
            end
            
            table.insert(allAnimalsCache, {
                name = animalName,
                plot = plot.Name,
                slot = podium.Name,
                worldPosition = podium:GetPivot().Position,
                uid = plot.Name .. "_" .. podium.Name,
            })
        end
    end
end

local function initializeScanner()
    task.wait(2)
    
    local plots = workspace:WaitForChild("Plots", 10)
    if not plots then 
        return
    end
    
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then
            scanSinglePlot(plot)
        end
    end
    
    plots.ChildAdded:Connect(function(plot)
        if plot:IsA("Model") then
            task.wait(0.5)
            scanSinglePlot(plot)
        end
    end)
    
    task.spawn(function()
        while task.wait(5) do
            allAnimalsCache = {}
            for _, plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then
                    scanSinglePlot(plot)
                end
            end
        end
    end)
end

local function findProximityPromptForAnimal(animalData)
    if not animalData then return nil end
    
    local cachedPrompt = PromptMemoryCache[animalData.uid]
    if cachedPrompt and cachedPrompt.Parent then
        return cachedPrompt
    end
    
    local plot = workspace.Plots:FindFirstChild(animalData.plot)
    if not plot then return nil end
    
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return nil end
    
    local podium = podiums:FindFirstChild(animalData.slot)
    if not podium then return nil end
    
    local base = podium:FindFirstChild("Base")
    if not base then return nil end
    
    local spawn = base:FindFirstChild("Spawn")
    if not spawn then return nil end
    
    local attach = spawn:FindFirstChild("PromptAttachment")
    if not attach then return nil end
    
    for _, p in ipairs(attach:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            PromptMemoryCache[animalData.uid] = p
            return p
        end
    end
    
    return nil
end

local function updatePlayerVelocity()
    local hrp = getHRP()
    if not hrp then return end
    
    local currentPos = hrp.Position
    
    if LastPlayerPosition then
        PlayerVelocity = (currentPos - LastPlayerPosition) / task.wait()
    end
    
    LastPlayerPosition = currentPos
end

local function shouldSteal(animalData)
    if not animalData or not animalData.worldPosition then return false end
    
    local hrp = getHRP()
    if not hrp then return false end
    
    local currentDistance = (hrp.Position - animalData.worldPosition).Magnitude
    
    return currentDistance <= AUTO_STEAL_PROX_RADIUS
end

local function buildStealCallbacks(prompt)
    if InternalStealCache[prompt] then return end
    
    local data = {
        holdCallbacks = {},
        triggerCallbacks = {},
        ready = true,
    }
    
    local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(conns1) == "table" then
        for _, conn in ipairs(conns1) do
            if type(conn.Function) == "function" then
                table.insert(data.holdCallbacks, conn.Function)
            end
        end
    end
    
    local ok2, conns2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(conns2) == "table" then
        for _, conn in ipairs(conns2) do
            if type(conn.Function) == "function" then
                table.insert(data.triggerCallbacks, conn.Function)
            end
        end
    end
    
    if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) then
        InternalStealCache[prompt] = data
    end
end

local function executeInternalStealAsync(prompt, animalData)
    local data = InternalStealCache[prompt]
    if not data or not data.ready then return false end
    
    data.ready = false
    IsStealing = true
    StealProgress = 0
    CurrentStealTarget = animalData
    StealStartTime = tick()
    
    task.spawn(function()
        if #data.holdCallbacks > 0 then
            for _, fn in ipairs(data.holdCallbacks) do
                task.spawn(fn)
            end
        end
        
        local startTime = tick()
        while tick() - startTime < 1.3 do
            StealProgress = (tick() - startTime) / 1.3
            task.wait(0.05)
        end
        StealProgress = 1
        
        if #data.triggerCallbacks > 0 then
            for _, fn in ipairs(data.triggerCallbacks) do
                task.spawn(fn)
            end
        end
        
        task.wait(0.1)
        data.ready = true
        
        task.wait(0.3)
        IsStealing = false
        StealProgress = 0
        CurrentStealTarget = nil
    end)
    
    return true
end

local function attemptSteal(prompt, animalData)
    if not prompt or not prompt.Parent then return false end
    
    buildStealCallbacks(prompt)
    if not InternalStealCache[prompt] then return false end
    
    return executeInternalStealAsync(prompt, animalData)
end

local function getNearestAnimal()
    local hrp = getHRP()
    if not hrp then return nil end
    
    local nearest = nil
    local minDist = math.huge
    
    for _, animalData in ipairs(allAnimalsCache) do
        if isMyBase(animalData.plot) then continue end
        
        if animalData.worldPosition then
            local dist = (hrp.Position - animalData.worldPosition).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = animalData
            end
        end
    end
    
    return nearest
end

local function autoStealLoop()
    if stealConnection then stealConnection:Disconnect() end
    if velocityConnection then velocityConnection:Disconnect() end
    
    velocityConnection = RunService.Heartbeat:Connect(updatePlayerVelocity)
    
    stealConnection = RunService.Heartbeat:Connect(function()
        if not AUTO_STEAL_NEAREST then return end
        if IsStealing then return end
        
        local targetAnimal = getNearestAnimal()
        if not targetAnimal then return end
        
        if not shouldSteal(targetAnimal) then return end
        
        if LastTargetUID ~= targetAnimal.uid then
            LastTargetUID = targetAnimal.uid
        end
        
        local prompt = PromptMemoryCache[targetAnimal.uid]
        if not prompt or not prompt.Parent then
            prompt = findProximityPromptForAnimal(targetAnimal)
        end
        
        if prompt then
            attemptSteal(prompt, targetAnimal)
        end
    end)
end

local function createCircle(character)
    for _, part in ipairs(circleParts) do
        if part then part:Destroy() end
    end
    circleParts = {}
    
    CIRCLE_RADIUS = AUTO_STEAL_PROX_RADIUS
    local root = character:WaitForChild("HumanoidRootPart")
    
    local points = {}
    for i = 0, PartsCount - 1 do
        local angle = math.rad(i * 360 / PartsCount)
        table.insert(points, Vector3.new(math.cos(angle), 0, math.sin(angle)) * CIRCLE_RADIUS)
    end
    
    for i = 1, #points do
        local nextIndex = i % #points + 1
        local p1 = points[i]
        local p2 = points[nextIndex]
        
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Size = Vector3.new((p2 - p1).Magnitude, PART_HEIGHT, PART_THICKNESS)
        part.Color = PART_COLOR
        part.Material = Enum.Material.Neon
        part.Transparency = 0.3
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = workspace
        table.insert(circleParts, part)
    end
end

local function updateCircle(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local points = {}
    for i = 0, PartsCount - 1 do
        local angle = math.rad(i * 360 / PartsCount)
        table.insert(points, Vector3.new(math.cos(angle), 0, math.sin(angle)) * CIRCLE_RADIUS)
    end
    
    for i, part in ipairs(circleParts) do
        local nextIndex = i % #points + 1
        local p1 = points[i]
        local p2 = points[nextIndex]
        local center = (p1 + p2) / 2 + root.Position
        
        part.CFrame = CFrame.new(center, center + Vector3.new(p2.X - p1.X, 0, p2.Z - p1.Z)) * CFrame.Angles(0, math.pi/2, 0)
    end
end

local function onCharacterAdded(character)
    if circleEnabled then
        createCircle(character)
        RunService:BindToRenderStep("CircleFollow", Enum.RenderPriority.Camera.Value + 1, function()
            updateCircle(character)
        end)
    end
end

local function updateCircleRadius()
    CIRCLE_RADIUS = AUTO_STEAL_PROX_RADIUS
    local character = LocalPlayer.Character
    if character and circleEnabled then
        createCircle(character)
    end
end

-- [GUI CREATION START]

local Colors = {
    Background = Color3.fromRGB(10, 35, 45),
    BackgroundDark = Color3.fromRGB(5, 25, 35),
    Purple = Color3.fromRGB(0, 200, 255),
    Pink = Color3.fromRGB(0, 255, 255),
    Cyan = Color3.fromRGB(80, 200, 220),
    White = Color3.fromRGB(255, 255, 255),
    Green = Color3.fromRGB(100, 255, 150),
    Red = Color3.fromRGB(255, 80, 100),
    TextGray = Color3.fromRGB(200, 200, 200)
}

if CoreGui:FindFirstChild("FistDuelRushUI") then
    CoreGui.FistDuelRushUI:Destroy()
end

local function CreateElement(className, properties)
    local element = Instance.new(className)
    for k, v in pairs(properties or {}) do
        element[k] = v
    end
    return element
end

local function CreateGradient(parent, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    }
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

-- Custom Draggable Function
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos
    
    local handle = dragHandle or frame
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FistDuelRushUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Minimize functionality
local PanelsVisible = true
local ToggleUIBtn = CreateElement("TextButton", {
    Name = "ToggleUI",
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.2,
    Text = "-",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 24,
    Parent = ScreenGui
})
CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = ToggleUIBtn})
CreateElement("UIStroke", {Color = Colors.White, Thickness = 1.5, Transparency = 0.5, Parent = ToggleUIBtn})
MakeDraggable(ToggleUIBtn)

-- PROGRESS BAR AT TOP OF SCREEN
local TopProgressFrame = CreateElement("Frame", {
    Name = "TopProgress",
    Size = UDim2.new(0, 300, 0, 20),
    Position = UDim2.new(0.5, -150, 0, 10),
    BackgroundColor3 = Colors.BackgroundDark,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Parent = ScreenGui
})
CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TopProgressFrame})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Transparency = 0.3, Parent = TopProgressFrame})

local TopProgressLabel = CreateElement("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "FIST DUELS ON TOP",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    ZIndex = 2,
    Parent = TopProgressFrame
})

local TopProgressBarFill = CreateElement("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Colors.Green,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = TopProgressFrame
})
CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TopProgressBarFill})
CreateGradient(TopProgressBarFill, Colors.Green, Colors.Cyan, 0)

local NotificationContainer = CreateElement("Frame", {
    Name = "NotificationContainer",
    Size = UDim2.new(0, 300, 0, 100),
    Position = UDim2.new(0.5, -150, 1, -120),
    BackgroundTransparency = 1,
    Parent = ScreenGui
})

local ActiveNotifications = {}

local function SendNotification(title, message, duration, color)
    duration = duration or 5
    color = color or Colors.Purple
    
    local notification = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Colors.BackgroundDark,
        BackgroundTransparency = 0.1, 
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = NotificationContainer
    })
    
    CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = notification})
    CreateElement("UIStroke", {Color = color, Thickness = 2, Transparency = 0.3, Parent = notification})
    
    local accentBar = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = notification
    })
    CreateGradient(accentBar, color, Colors.Pink, 0)
    
    local titleLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Colors.White,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    local messageLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, -40, 0, 35),
        Position = UDim2.new(0, 10, 0, 25),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Colors.TextGray,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = notification
    })
    
    local closeBtn = CreateElement("TextButton", {
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(1, -30, 0, 5),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = Colors.TextGray,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = notification
    })
    
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Colors.White end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Colors.TextGray end)
    
    table.insert(ActiveNotifications, notification)
    
    local function updatePositions()
        for i, notif in ipairs(ActiveNotifications) do
            local targetPos = UDim2.new(0, 0, 1, -(i * 75))
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetPos
            }):Play()
        end
    end
    
    local function closeNotification()
        TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.3)
        task.wait()
        for i, notif in ipairs(ActiveNotifications) do
            if notif == notification then
                table.remove(ActiveNotifications, i)
                break
            end
        end
        notification:Destroy()
        updatePositions()
    end
    
    closeBtn.MouseButton1Click:Connect(closeNotification)
    
    TweenService:Create(notification, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 65)
    }):Play()
    
    updatePositions()
    task.delay(duration, function()
        if notification and notification.Parent then closeNotification() end
    end)
end

-- SPEED BOOSTER PANEL (From Script 1)
local BoosterPanel = CreateElement("Frame", {
    Name = "BoosterPanel",
    Size = UDim2.new(0, 190, 0, 120),
    Position = UDim2.new(0.5, -95, 0.4, 0),
    BackgroundColor3 = Color3.fromRGB(5, 25, 35),
    BorderSizePixel = 0,
    Active = true,
    Parent = ScreenGui
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = BoosterPanel})

local BoosterStroke = CreateElement("UIStroke", {
    Color = Color3.fromRGB(0, 255, 255),
    Thickness = 2,
    Transparency = 0.1,
    Parent = BoosterPanel
})

MakeDraggable(BoosterPanel)

-- Title
local BoosterTitle = CreateElement("TextLabel", {
    Size = UDim2.new(1, -60, 0, 22),
    Position = UDim2.new(0, 10, 0, 6),
    BackgroundTransparency = 1,
    Text = "LEAK BY FIST Booster",
    TextColor3 = Color3.fromRGB(0, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = BoosterPanel
})

-- Speed
local SpeedLabel = CreateElement("TextLabel", {
    Size = UDim2.new(0, 70, 0, 20),
    Position = UDim2.new(0, 10, 0, 36),
    BackgroundTransparency = 1,
    Text = "Speed",
    TextColor3 = Color3.fromRGB(0, 240, 255),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    Parent = BoosterPanel
})

local SpeedBox = CreateElement("TextBox", {
    Size = UDim2.new(0, 80, 0, 22),
    Position = UDim2.new(0, 95, 0, 36),
    BackgroundColor3 = Color3.fromRGB(10, 35, 45),
    Text = "29.4",
    TextColor3 = Color3.fromRGB(200, 255, 255),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    ClearTextOnFocus = false,
    Parent = BoosterPanel
})
CreateElement("UICorner", {Parent = SpeedBox})

-- Jump
local JumpLabel = CreateElement("TextLabel", {
    Size = UDim2.new(0, 70, 0, 20),
    Position = UDim2.new(0, 10, 0, 62),
    BackgroundTransparency = 1,
    Text = "Jump",
    TextColor3 = Color3.fromRGB(0, 240, 255),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    Parent = BoosterPanel
})

local JumpBox = CreateElement("TextBox", {
    Size = UDim2.new(0, 80, 0, 22),
    Position = UDim2.new(0, 95, 0, 62),
    BackgroundColor3 = Color3.fromRGB(10, 35, 45),
    Text = "54",
    TextColor3 = Color3.fromRGB(200, 255, 255),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    ClearTextOnFocus = false,
    Parent = BoosterPanel
})
CreateElement("UICorner", {Parent = JumpBox})

-- Toggle
local BoosterToggle = CreateElement("TextButton", {
    Size = UDim2.new(0, 44, 0, 18),
    Position = UDim2.new(1, -54, 0, 8),
    BackgroundColor3 = Color3.fromRGB(80, 80, 80),
    Text = "",
    AutoButtonColor = false,
    Parent = BoosterPanel
})
CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = BoosterToggle})

local BoosterKnob = CreateElement("Frame", {
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(0, 2, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = Color3.fromRGB(200, 255, 255),
    Parent = BoosterToggle
})
CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = BoosterKnob})

-- Booster Logic
local BoosterEnabled = false
local SpeedValue = 29.4
local JumpValue = 54

BoosterToggle.MouseButton1Click:Connect(function()
    BoosterEnabled = not BoosterEnabled
    TweenService:Create(BoosterToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = BoosterEnabled and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(80, 80, 80)
    }):Play()
    TweenService:Create(BoosterKnob, TweenInfo.new(0.2), {
        Position = BoosterEnabled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    }):Play()
end)

SpeedBox.FocusLost:Connect(function()
    local v = tonumber(SpeedBox.Text)
    if v then SpeedValue = v end
end)

JumpBox.FocusLost:Connect(function()
    local v = tonumber(JumpBox.Text)
    if v then JumpValue = v end
end)

RunService.Heartbeat:Connect(function()
    if not BoosterEnabled then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root then
        if hum.MoveDirection.Magnitude > 0 then
            root.Velocity = Vector3.new(
                hum.MoveDirection.X * SpeedValue,
                root.Velocity.Y,
                hum.MoveDirection.Z * SpeedValue
            )
        end
        hum.UseJumpPower = true
        hum.JumpPower = JumpValue
    end
end)

-- LEFT PANEL (BATTLE SYSTEM)
local LeftPanel = CreateElement("Frame", {
    Name = "BattleSystem",
    Size = UDim2.new(0, 130, 0, 260), -- Increased height for Anti-Ragdoll
    Position = UDim2.new(0, 60, 0.5, -130),
    BackgroundColor3 = Colors.BackgroundDark,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Active = true,
    Parent = ScreenGui
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = LeftPanel})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Transparency = 0.3, Parent = LeftPanel})

local LeftHeader = CreateElement("TextLabel", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "BATTLE",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    Parent = LeftPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = LeftHeader})
CreateGradient(LeftHeader, Colors.Purple, Colors.Pink, 45)

MakeDraggable(LeftPanel, LeftHeader)

local BatTargetBtn = CreateElement("TextButton", {
    Name = "BatTarget",
    Size = UDim2.new(0.9, 0, 0, 35),
    Position = UDim2.new(0.05, 0, 0, 40),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "BAT TARGET: OFF",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Parent = LeftPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = BatTargetBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 1.5, Parent = BatTargetBtn})
CreateGradient(BatTargetBtn, Colors.Purple, Colors.Pink, 45)

local InfJumpBtn = CreateElement("TextButton", {
    Name = "InfJump",
    Size = UDim2.new(0.9, 0, 0, 35),
    Position = UDim2.new(0.05, 0, 0, 85),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "INF JUMP: OFF",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Parent = LeftPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = InfJumpBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 1.5, Parent = InfJumpBtn})
CreateGradient(InfJumpBtn, Colors.Purple, Colors.Pink, 45)

local UnwalkBtn = CreateElement("TextButton", {
    Name = "Unwalk",
    Size = UDim2.new(0.9, 0, 0, 35),
    Position = UDim2.new(0.05, 0, 0, 130),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "UNWALK: OFF",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Parent = LeftPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = UnwalkBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 1.5, Parent = UnwalkBtn})
CreateGradient(UnwalkBtn, Colors.Purple, Colors.Pink, 45)

local AntiRagdollBtn = CreateElement("TextButton", { -- Moved from Right Panel
    Name = "AntiRagdoll",
    Size = UDim2.new(0.9, 0, 0, 35),
    Position = UDim2.new(0.05, 0, 0, 175),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "ANTI-RAGDOLL: OFF",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Parent = LeftPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = AntiRagdollBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 1.5, Parent = AntiRagdollBtn})
CreateGradient(AntiRagdollBtn, Colors.Purple, Colors.Pink, 45)

local LockBtn = CreateElement("TextButton", {
    Name = "Lock",
    Size = UDim2.new(0.9, 0, 0, 30),
    Position = UDim2.new(0.05, 0, 0, 220), -- Position adjusted to accommodate AntiRagdollBtn
    BackgroundColor3 = Colors.BackgroundDark,
    BackgroundTransparency = 0.3,
    Text = "🔓 UNLOCK UI",
    TextColor3 = Colors.Cyan,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    BorderSizePixel = 0,
    Parent = LeftPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = LockBtn})
CreateElement("UIStroke", {Color = Colors.Cyan, Thickness = 1.5, Parent = LockBtn})

-- CENTER PANEL (AUTO PLAY)
local CenterPanel = CreateElement("Frame", {
    Name = "AutoPlayPanel",
    Size = UDim2.new(0, 150, 0, 300),
    Position = UDim2.new(0.5, -75, 0.5, -110),
    BackgroundColor3 = Colors.BackgroundDark,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Active = true,
    Parent = ScreenGui
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = CenterPanel})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Transparency = 0.3, Parent = CenterPanel})

local CenterHeader = CreateElement("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "LEAK BY FIST HUB DUEL",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    BorderSizePixel = 0,
    Parent = CenterPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = CenterHeader})
CreateGradient(CenterHeader, Colors.Purple, Colors.Pink, 45)

MakeDraggable(CenterPanel, CenterHeader)

local StatusLabel = CreateElement("TextLabel", {
    Name = "Status",
    Size = UDim2.new(0.9, 0, 0, 20),
    Position = UDim2.new(0.05, 0, 0, 35),
    BackgroundTransparency = 1,
    Text = "⚡ READY",
    TextColor3 = Colors.Green,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Parent = CenterPanel
})



-- TO SPD UI
local ToSpdLabel = CreateElement("TextLabel", {
    Size = UDim2.new(0.9, 0, 0, 18),
    Position = UDim2.new(0.05, 0, 0, 160),
    BackgroundTransparency = 1,
    Text = "To Spd:",
    TextColor3 = Colors.Cyan,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    Parent = CenterPanel
})

local ToSpdBox = CreateElement("TextBox", {
    Size = UDim2.new(0.9, 0, 0, 22),
    Position = UDim2.new(0.05, 0, 0, 180),
    BackgroundColor3 = Colors.Background,
    Text = "58.5",
    TextColor3 = Colors.White,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ClearTextOnFocus = false,
    Parent = CenterPanel
})
CreateElement("UICorner", {Parent = ToSpdBox})

-- BACK SPD UI
local BackSpdLabel = CreateElement("TextLabel", {
    Size = UDim2.new(0.9, 0, 0, 18),
    Position = UDim2.new(0.05, 0, 0, 205),
    BackgroundTransparency = 1,
    Text = "Back Spd:",
    TextColor3 = Colors.Cyan,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    Parent = CenterPanel
})

local BackSpdBox = CreateElement("TextBox", {
    Size = UDim2.new(0.9, 0, 0, 22),
    Position = UDim2.new(0.05, 0, 0, 230),
    BackgroundColor3 = Colors.Background,
    Text = "29",
    TextColor3 = Colors.White,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ClearTextOnFocus = false,
    Parent = CenterPanel
})
CreateElement("UICorner", {Parent = BackSpdBox})


local AutoRightBtn = CreateElement("TextButton", {
    Name = "AutoRight",
    Size = UDim2.new(0.9, 0, 0, 40),
    Position = UDim2.new(0.05, 0, 0, 60),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "🌠 AUTO RIGHT",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    Parent = CenterPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = AutoRightBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Parent = AutoRightBtn})
CreateGradient(AutoRightBtn, Colors.Purple, Colors.Pink, 45)

local AutoLeftBtn = CreateElement("TextButton", {
    Name = "AutoLeft",
    Size = UDim2.new(0.9, 0, 0, 40),
    Position = UDim2.new(0.05, 0, 0, 105),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "🌌 AUTO LEFT",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    Parent = CenterPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = AutoLeftBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Parent = AutoLeftBtn})
CreateGradient(AutoLeftBtn, Colors.Purple, Colors.Pink, 45)

local FPSLabel = CreateElement("TextLabel", {
    Size = UDim2.new(0.9, 0, 0, 15),
    Position = UDim2.new(0.05, 0, 1, -20),
    BackgroundTransparency = 1,
    Text = "FPS: 60 | PING: 50ms",
    TextColor3 = Colors.TextGray,
    Font = Enum.Font.Code,
    TextSize = 9,
    BorderSizePixel = 0,
    Parent = CenterPanel
})

local OpenKeybindsBtn = CreateElement("TextButton", {
    Name = "OpenKeybinds",
    Size = UDim2.new(0.9, 0, 0, 30),
    Position = UDim2.new(0.05, 0, 0, 250),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "🎮 EDIT KEYBINDS",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Parent = CenterPanel
})
CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = OpenKeybindsBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Parent = OpenKeybindsBtn})
CreateGradient(OpenKeybindsBtn, Colors.Purple, Colors.Pink, 45)

CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = RightPanel})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Transparency = 0.3, Parent = RightPanel})

local RightHeader = CreateElement("TextLabel", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "UTILITIES",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    Parent = RightPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = RightHeader})
CreateGradient(RightHeader, Colors.Purple, Colors.Pink, 45)

MakeDraggable(RightPanel, RightHeader)

local InstaGrabBtn = CreateElement("TextButton", {
    Name = "InstaGrab",
    Size = UDim2.new(0.9, 0, 0, 40),
    Position = UDim2.new(0.05, 0, 0, 40),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "INSTA GRAB: OFF",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Parent = RightPanel
})

CreateElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = InstaGrabBtn})
CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 2, Parent = InstaGrabBtn})
CreateGradient(InstaGrabBtn, Colors.Purple, Colors.Pink, 45)

-- RADIUS TEXT BOX (REPLACING SLIDER)
local RadiusLbl = CreateElement("TextLabel", {
    Size = UDim2.new(0.9, 0, 0, 20),
    Position = UDim2.new(0.05, 0, 0, 85),
    BackgroundTransparency = 1,
    Text = "Radius",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    BorderSizePixel = 0,
    Parent = RightPanel
})

local RadiusBox = CreateElement("TextBox", {
    Size = UDim2.new(0.9, 0, 0, 25),
    Position = UDim2.new(0.05, 0, 0, 105),
    BackgroundColor3 = Color3.fromRGB(10, 35, 45),
    Text = "20",
    TextColor3 = Color3.fromRGB(200, 255, 255),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    ClearTextOnFocus = false,
    Parent = RightPanel
})
CreateElement("UICorner", {Parent = RadiusBox})

RadiusBox.FocusLost:Connect(function()
    local v = tonumber(RadiusBox.Text)
    if v and v >= 1 and v <= 200 then
        AUTO_STEAL_PROX_RADIUS = v
        updateCircleRadius()
        SendNotification("Radius Updated", "Auto-grab radius set to " .. v, 2, Colors.Green)
    else
        RadiusBox.Text = tostring(AUTO_STEAL_PROX_RADIUS)
        SendNotification("Invalid Radius", "Please enter a number between 1-200", 2, Colors.Red)
    end
end)

local CreditsLabel = CreateElement("TextLabel", {
    Size = UDim2.new(0.9, 0, 0, 15),
    Position = UDim2.new(0.05, 0, 1, -15),
    BackgroundTransparency = 1,
    Text = "discord.gg/YQrC6JdpzR",
    TextColor3 = Colors.TextGray,
    Font = Enum.Font.Code,
    TextSize = 8,
    BorderSizePixel = 0,
    Parent = RightPanel
})

-- KEYBIND EDITOR UI
local keybindsData = {
    autoLeft = Enum.KeyCode.A,
    autoRight = Enum.KeyCode.D,
    stopMovement = Enum.KeyCode.S
}

local KeybindsFrame = CreateElement("Frame", {
    Name = "KeybindsFrame",
    Size = UDim2.new(0, 200, 0, 180),
    Position = UDim2.new(0.5, -100, 0.5, -90),
    BackgroundColor3 = Colors.BackgroundDark,
    BackgroundTransparency = 0.05,
    Visible = false,
    ZIndex = 10,
    Parent = ScreenGui
})
CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = KeybindsFrame})
CreateElement("UIStroke", {Color = Colors.White, Thickness = 2, Transparency = 0.3, Parent = KeybindsFrame})
MakeDraggable(KeybindsFrame)

local KbHeader = CreateElement("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Colors.Purple,
    BackgroundTransparency = 0.3,
    Text = "KEYBINDS",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 11,
    Parent = KeybindsFrame
})
CreateElement("UICorner", {CornerRadius = UDim.new(0, 15), Parent = KbHeader})
CreateGradient(KbHeader, Colors.Purple, Colors.Pink, 45)

local KbClose = CreateElement("TextButton", {
    Size = UDim2.new(0, 25, 0, 25),
    Position = UDim2.new(1, -30, 0, 2),
    BackgroundTransparency = 1,
    Text = "X",
    TextColor3 = Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 12,
    Parent = KeybindsFrame
})

KbClose.MouseButton1Click:Connect(function() KeybindsFrame.Visible = false end)
OpenKeybindsBtn.MouseButton1Click:Connect(function() KeybindsFrame.Visible = not KeybindsFrame.Visible end)

local function CreateBindButton(text, yPos, keyName)
    local btn = CreateElement("TextButton", {
        Size = UDim2.new(0.9, 0, 0, 30),
        Position = UDim2.new(0.05, 0, 0, yPos),
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.3,
        Text = text .. ": " .. keybindsData[keyName].Name,
        TextColor3 = Colors.White,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        ZIndex = 11,
        Parent = KeybindsFrame
    })
    CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = btn})
    CreateElement("UIStroke", {Color = Colors.Purple, Thickness = 1.5, Parent = btn})
    return btn
end

local AutoRightBindBtn = CreateBindButton("Auto Right", 40, "autoRight")
local AutoLeftBindBtn = CreateBindButton("Auto Left", 80, "autoLeft")
local StopBindBtn = CreateBindButton("Stop", 120, "stopMovement")

local currentRebinding = nil
local rebindingBtn = nil

local function StartRebind(btn, keyName)
    if currentRebinding then return end
    currentRebinding = keyName
    rebindingBtn = btn
    btn.Text = "Press any key..."
    btn.BackgroundColor3 = Colors.Purple
end

AutoRightBindBtn.MouseButton1Click:Connect(function() StartRebind(AutoRightBindBtn, "autoRight") end)
AutoLeftBindBtn.MouseButton1Click:Connect(function() StartRebind(AutoLeftBindBtn, "autoLeft") end)
StopBindBtn.MouseButton1Click:Connect(function() StartRebind(StopBindBtn, "stopMovement") end)

-- LOGIC VARIABLES

local waypoints = {}
local currentWaypoint = 1
local moving = false
local speed = tonumber(BackSpdBox.Text) or 29
local connection 

-- Bat Target variables
local batActive = false
local moveSpeed = 50
local engageRange = 20
local lastEquipTick = 0
local lastUseTick = 0

-- Infinity jump variables
local infinityJumpEnabled = false
local jumpForce = 50
local clampFallSpeed = 80

-- Unwalk variables
local unwalkEnabled = false
local savedAnims = {}
local watcher

-- Anti Move states
local isAutoRightActive = false
local isAutoLeftActive = false

-- Anti-Ragdoll states
local antiRagdollEnabled = false
local antiRagdollMode = nil
local ragdollConnections = {}
local cachedCharData = {}

-- HELPER FUNCTIONS

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- UNWALK LOGIC
local function isMovementAnim(anim)
    return anim and anim:IsA("Animation") and (
        anim.Name:lower():find("walk") or
        anim.Name:lower():find("run") or
        anim.Name:lower():find("jump") or
        anim.Name:lower():find("swim") or
        anim.Name:lower():find("fall") or
        anim.Name:lower():find("climb") or
        anim.Name:lower():find("idle") or
        anim.Name:lower():find("land") or
        anim.Name:lower():find("sit") or
        anim.Name:lower():find("crouch")
    )
end

local function stopMovementAnims(hum)
    if not hum then return end
    for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
        if t.Name:lower():find("walk") or
           t.Name:lower():find("run") or
           t.Name:lower():find("jump") or
           t.Name:lower():find("swim") or
           t.Name:lower():find("fall") or
           t.Name:lower():find("climb") or
           t.Name:lower():find("idle") or
           t.Name:lower():find("land") or
           t.Name:lower():find("sit") or
           t.Name:lower():find("crouch") then
            t:Stop()
        end
    end
end

local function saveAndClear(anim)
    for _, v in ipairs(savedAnims) do
        if v.instance == anim then return end
    end
    table.insert(savedAnims, {instance = anim, id = anim.AnimationId})
    anim.AnimationId = ""
end

local function restoreAnims()
    for _, v in ipairs(savedAnims) do
        if v.instance then
            v.instance.AnimationId = v.id
        end
    end
end

local function added(desc)
    if unwalkEnabled and isMovementAnim(desc) then
        saveAndClear(desc)
    end
end

local function scan(character)
    local animate = character and character:FindFirstChild("Animate")
    if not animate then return end

    local function clear(folder, name)
        local anim = folder and folder:FindFirstChild(name)
        if anim and anim:IsA("Animation") then
            saveAndClear(anim)
        end
    end

    clear(animate:FindFirstChild("walk"), "WalkAnim")
    clear(animate:FindFirstChild("run"), "RunAnim")
    clear(animate:FindFirstChild("jump"), "JumpAnim")
    clear(animate:FindFirstChild("swim"), "Swim")
    clear(animate:FindFirstChild("swimidle"), "SwimIdle")
    clear(animate:FindFirstChild("fall"), "FallAnim")
    clear(animate:FindFirstChild("climb"), "ClimbAnim")
    clear(animate:FindFirstChild("idle"), "Animation1")
    clear(animate:FindFirstChild("idle"), "Animation2")
    clear(animate:FindFirstChild("sit"), "SitAnim")
    clear(animate:FindFirstChild("toolnone"), "ToolNoneAnim")
    clear(animate:FindFirstChild("toolsit"), "ToolSitAnim")

    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then stopMovementAnims(hum) end
end

local function enableUnwalk()
    local char = LocalPlayer.Character
    if not char then return end
    unwalkEnabled = true
    savedAnims = {}
    task.spawn(function()
        scan(char)
        if watcher then watcher:Disconnect() end
        watcher = char.DescendantAdded:Connect(added)
    end)
end

local function disableUnwalk()
    if watcher then watcher:Disconnect() watcher = nil end
    restoreAnims()
    savedAnims = {}
    unwalkEnabled = false
end

-- NEW ANTI RAGDOLL LOGIC

local antiRagdollConnection = nil

local function startAntiRagdoll()

    if antiRagdollConnection then return end

    antiRagdollConnection = RunService.Heartbeat:Connect(function()

        if not antiRagdollEnabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")

        if hum then
            local state = hum:GetState()

            if state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown then

                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum

                pcall(function()
                    local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if PlayerModule then
                        local Controls = require(PlayerModule:FindFirstChild("ControlModule"))
                        Controls:Enable()
                    end
                end)

                if root then
                    root.Velocity = Vector3.new(0,0,0)
                    root.RotVelocity = Vector3.new(0,0,0)
                end
            end
        end

        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("Motor6D") and v.Enabled == false then
                v.Enabled = true
            end
        end

    end)

end


local function stopAntiRagdoll()

    if antiRagdollConnection then
        antiRagdollConnection:Disconnect()
        antiRagdollConnection = nil
    end

end

-- BAT TARGET LOGIC
local function nearestPlayer()
    local hrp = getRoot()
    if not hrp then return end

    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = plr.Character:FindFirstChildOfClass("Humanoid")
            if targetHRP and targetHum and targetHum.Health > 0 then
                local distance = (targetHRP.Position - hrp.Position).Magnitude
                if distance < minDist then
                    minDist = distance
                    closest = targetHRP
                end
            end
        end
    end
    return closest, minDist
end

local function equipBat()
    local hum = getHum()
    if not hum then return end

    local char = LocalPlayer.Character
    local batTool = LocalPlayer.Backpack:FindFirstChild("Bat") or (char and char:FindFirstChild("Bat"))
    if batTool then
        hum:EquipTool(batTool)
        return batTool
    end
end

-- MOVEMENT LOGIC
local function moveToWaypoint()
    if connection then connection:Disconnect() end
    connection = RunService.Stepped:Connect(function()
        if not moving then return end
        local rootPart = getRoot()
        if not rootPart or #waypoints == 0 then return end
        
        local targetPos = waypoints[currentWaypoint].position
        local wpSpeed = waypoints[currentWaypoint].speed or speed
        local distance = (rootPart.Position - targetPos).Magnitude
        
        if distance < 5 then
            currentWaypoint = (currentWaypoint % #waypoints) + 1
        else
            local direction = (targetPos - rootPart.Position).Unit
            rootPart.AssemblyLinearVelocity = Vector3.new(direction.X * wpSpeed, rootPart.AssemblyLinearVelocity.Y, direction.Z * wpSpeed)
        end
    end)
end

local function stopMoving()
    if connection then connection:Disconnect() connection = nil end
    moving = false
    local rootPart = getRoot()
    if rootPart then rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0) end
end

-- AUTO MOVEMENT TOGGLE
local function toggleAutoMovement(type)
    if type == "right" then
        if isAutoRightActive then
            isAutoRightActive = false
            AutoRightBtn.Text = "🌠 AUTO RIGHT"
            AutoRightBtn.BackgroundColor3 = Colors.Purple
            stopMoving()
        else
            if isAutoLeftActive then
                isAutoLeftActive = false
                AutoLeftBtn.Text = "🌌 AUTO LEFT"
                AutoLeftBtn.BackgroundColor3 = Colors.Purple
            end
            
            isAutoRightActive = true
            AutoRightBtn.Text = "🌠 AUTO RIGHT [ON]"
            AutoRightBtn.BackgroundColor3 = Colors.Green
            
            stopMoving()
            waypoints = {
                {position = Vector3.new(-474, -7, 29), speed = tonumber(ToSpdBox.Text) or 58.5},
                {position = Vector3.new(-473, -7, 29), speed = tonumber(ToSpdBox.Text) or 58.5},
                {position = Vector3.new(-478, -6, 25), speed = tonumber(ToSpdBox.Text) or 58.5},
                {position = Vector3.new(-488, -5, 23), speed = tonumber(ToSpdBox.Text) or 58.5},
                {position = Vector3.new(-488, -5, 23), speed = tonumber(ToSpdBox.Text) or 58.5},
                {position = Vector3.new(-474, -7, 29), speed = tonumber(BackSpdBox.Text) or 29},
                {position = Vector3.new(-474, -7, 29), speed = tonumber(BackSpdBox.Text) or 29},
                {position = Vector3.new(-475, -7, 118), speed = tonumber(BackSpdBox.Text) or 29},
                {position = Vector3.new(-475, -7, 118), speed = tonumber(BackSpdBox.Text) or 29}
            }
            for _, v in ipairs(waypoints) do
                if v.speed == 58.5 then
                    local n = tonumber(ToSpdBox.Text)
                    if n then v.speed = n end
                el... (18 KB left)
