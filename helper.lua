-- Divine Admin Abuse Helper
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

-- =====================
-- ANTI DIE
-- =====================
local function activateAntiDie()
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.BreakJointsOnDeath = false
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    hum:GetPropertyChangedSignal("Health"):Connect(function()
        if hum.Health <= 0 then hum.Health = hum.MaxHealth end
    end)
    hum.Died:Connect(function()
        task.wait()
        local newHum = Instance.new("Humanoid")
        newHum.Name = "ReplacedHumanoid"
        newHum.Parent = char
        Workspace.CurrentCamera.CameraSubject = newHum
        hum:Destroy()
    end)
end
activateAntiDie()
plr.CharacterAdded:Connect(function() task.wait(0.5); activateAntiDie() end)

-- =====================
-- ANCHOR
-- =====================
local anchorEnabled = false
local anchorConnection

local function startAnchor()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local lockedCF = hrp.CFrame
    if anchorConnection then anchorConnection:Disconnect() end
    anchorConnection = RunService.Heartbeat:Connect(function()
        if not anchorEnabled then return end
        local c = plr.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if h then
            h.CFrame = lockedCF
            h.AssemblyLinearVelocity = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function stopAnchor()
    if anchorConnection then anchorConnection:Disconnect(); anchorConnection = nil end
end

-- =====================
-- AUTO BUY — holds E on proximity prompts
-- =====================
local autoBuyEnabled = false
local autoBuyConnection
local heldPrompts = {}

local function startAutoBuy()
    if autoBuyConnection then autoBuyConnection:Disconnect() end
    autoBuyConnection = RunService.Heartbeat:Connect(function()
        if not autoBuyEnabled then return end
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local nearby = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    local dist = (hrp.Position - part.Position).Magnitude
                    if dist <= obj.MaxActivationDistance + 8 then
                        nearby[obj] = true
                        if not heldPrompts[obj] then
                            heldPrompts[obj] = true
                            task.spawn(function()
                                while autoBuyEnabled and obj and obj.Parent and obj.Enabled and heldPrompts[obj] do
                                    pcall(function()
                                        obj:InputHoldBegin()
                                    end)
                                    local dur = (obj.HoldDuration > 0) and obj.HoldDuration or 0.1
                                    task.wait(dur + 0.05)
                                    pcall(function()
                                        obj:InputHoldEnd()
                                    end)
                                    task.wait(0.15)
                                end
                                heldPrompts[obj] = nil
                            end)
                        end
                    end
                end
            end
        end

        -- release prompts no longer in range
        for obj in pairs(heldPrompts) do
            if not nearby[obj] then
                pcall(function() obj:InputHoldEnd() end)
                heldPrompts[obj] = nil
            end
        end
    end)
end

local function stopAutoBuy()
    if autoBuyConnection then autoBuyConnection:Disconnect(); autoBuyConnection = nil end
    for obj in pairs(heldPrompts) do
        pcall(function() obj:InputHoldEnd() end)
    end
    heldPrompts = {}
end

-- =====================
-- OPTIMISER
-- =====================
local optimiserEnabled = false
local optimiserConnection

local function applyOptimiser()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 8999999488.0
        Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("BloomEffect") or child:IsA("BlurEffect")
                or child:IsA("SunRaysEffect") or child:IsA("ColorCorrectionEffect")
                or child:IsA("DepthOfFieldEffect") or child:IsA("Atmosphere") then
                child.Enabled = false
            end
        end
    end)
    task.spawn(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.Plastic
                    obj.Reflectance = 0
                    obj.CastShadow = false
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                    or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end)
            task.wait()
        end
    end)
end

local function startOptimiserWatch()
    if optimiserConnection then optimiserConnection:Disconnect() end
    optimiserConnection = Workspace.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if not optimiserEnabled then return end
            pcall(function()
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.Plastic
                    obj.Reflectance = 0
                    obj.CastShadow = false
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                    or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end)
        end)
    end)
end

local function stopOptimiser()
    if optimiserConnection then optimiserConnection:Disconnect(); optimiserConnection = nil end
end

-- =====================
-- CLICK SOUND
-- =====================
local function playClick()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://6042053626"
    s.Volume = 0.35
    s.Parent = playerGui
    s:Play()
    game:GetService("Debris"):AddItem(s, 1)
end

-- =====================
-- OVERHEAD TAG
-- =====================
local function setupOverheadTag()
    local char = plr.Character or plr.CharacterAdded:Wait()
    local head = char:WaitForChild("Head")
    if head:FindFirstChild("DivineTag") then head.DivineTag:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "DivineTag"
    bb.Size = UDim2.new(0, 260, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = false
    bb.Adornee = head
    bb.Parent = head

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "https://discord.gg/szeWpaHj9K"
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextScaled = true
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Parent = bb
end

task.spawn(setupOverheadTag)
plr.CharacterAdded:Connect(function() task.wait(0.5); setupOverheadTag() end)

-- =====================
-- KEYBIND + GUI VISIBLE
-- =====================
local currentKeybind = Enum.KeyCode.Q
local waitingForKeybind = false
local guiVisible = true

-- =====================
-- INTRO SCREEN
-- =====================
local introGui = Instance.new("ScreenGui")
introGui.Name = "DivineIntro"
introGui.ResetOnSpawn = false
introGui.IgnoreGuiInset = true
introGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
introGui.DisplayOrder = 99
introGui.Parent = playerGui

local introLabel = Instance.new("TextLabel")
introLabel.Size = UDim2.new(1, 0, 0, 80)
introLabel.Position = UDim2.new(0, 0, 0.5, -40)
introLabel.BackgroundTransparency = 1
introLabel.Text = "Divine.VS"
introLabel.Font = Enum.Font.GothamBlack
introLabel.TextSize = 52
introLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
introLabel.TextTransparency = 1
introLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
introLabel.TextStrokeTransparency = 1
introLabel.ZIndex = 100
introLabel.Parent = introGui

-- flash then fade
task.spawn(function()
    -- fade in
    TweenService:Create(introLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        TextTransparency = 0,
        TextStrokeTransparency = 0.2
    }):Play()
    task.wait(0.3)

    -- flash loop for 3 seconds
    local flashCount = 0
    while flashCount < 6 do
        TweenService:Create(introLabel, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
            TextTransparency = 0.85
        }):Play()
        task.wait(0.22)
        TweenService:Create(introLabel, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
            TextTransparency = 0
        }):Play()
        task.wait(0.22)
        flashCount = flashCount + 1
    end

    -- fade out
    TweenService:Create(introLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    }):Play()
    task.wait(0.5)
    introGui:Destroy()
end)

-- =====================
-- MAIN GUI
-- =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DivineAdminHelper"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main frame (no separate ghost frame that stays behind)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 210, 0, 295)
mainFrame.Position = UDim2.new(0.5, -105, 0.5, -147)
mainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Pulsing white edge stroke
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.5

task.spawn(function()
    local t = 0
    while mainFrame and mainFrame.Parent do
        t = t + 0.05
        mainStroke.Transparency = 0.35 + ((math.sin(t) + 1) / 2) * 0.45
        task.wait(0.05)
    end
end)

-- Drag with shadow tween on the frame itself
local dragging = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        startPos = mainFrame.Position
        -- subtle tilt while dragging
        TweenService:Create(mainFrame, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        }):Play()
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then
                dragging = false
                TweenService:Create(mainFrame, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(5, 5, 5)
                }):Play()
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
        local delta = inp.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Title bar
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
local tbFix = Instance.new("Frame", titleBar)
tbFix.Size = UDim2.new(1, 0, 0.5, 0)
tbFix.Position = UDim2.new(0, 0, 0.5, 0)
tbFix.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
tbFix.BorderSizePixel = 0
tbFix.ZIndex = 2

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -12, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Divine Admin Abuse Helper"
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 11
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3

local divider = Instance.new("Frame", mainFrame)
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 40)
divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
divider.BorderSizePixel = 0
divider.ZIndex = 2

local content = Instance.new("Frame", mainFrame)
content.Size = UDim2.new(1, -16, 1, -54)
content.Position = UDim2.new(0, 8, 0, 48)
content.BackgroundTransparency = 1
content.ZIndex = 2
local listLayout = Instance.new("UIListLayout", content)
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Toggle maker
local function makeToggle(labelText, order, onEnable, onDisable)
    local isOn = false

    local row = Instance.new("Frame", content)
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = Color3.fromRGB(40, 40, 40)
    rowStroke.Thickness = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3

    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0, 32, 0, 17)
    pill.Position = UDim2.new(1, -40, 0.5, -8)
    pill.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    pill.BorderSizePixel = 0
    pill.ZIndex = 3
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame", pill)
    circle.Size = UDim2.new(0, 12, 0, 12)
    circle.Position = UDim2.new(0, 2, 0.5, -6)
    circle.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    circle.BorderSizePixel = 0
    circle.ZIndex = 4
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local function setState(state)
        isOn = state
        TweenService:Create(pill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = isOn and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(45, 45, 45)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = isOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = isOn and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(120, 120, 120)
        }):Play()
        TweenService:Create(rowStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Color = isOn and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(40, 40, 40)
        }):Play()
    end

    local click = Instance.new("TextButton", row)
    click.Size = UDim2.new(1, 0, 1, 0)
    click.BackgroundTransparency = 1
    click.Text = ""
    click.ZIndex = 5
    click.MouseButton1Click:Connect(function()
        playClick()
        setState(not isOn)
        if isOn then
            if onEnable then onEnable() end
        else
            if onDisable then onDisable() end
        end
        TweenService:Create(row, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        }):Play()
        task.delay(0.08, function()
            TweenService:Create(row, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            }):Play()
        end)
    end)
end

makeToggle("Anchor", 1,
    function() anchorEnabled = true; startAnchor() end,
    function() anchorEnabled = false; stopAnchor() end
)
makeToggle("Auto Buy", 2,
    function() autoBuyEnabled = true; startAutoBuy() end,
    function() autoBuyEnabled = false; stopAutoBuy() end
)
makeToggle("Optimiser", 3,
    function() optimiserEnabled = true; applyOptimiser(); startOptimiserWatch() end,
    function() optimiserEnabled = false; stopOptimiser() end
)

-- Keybind row
local kbRow = Instance.new("Frame", content)
kbRow.Size = UDim2.new(1, 0, 0, 40)
kbRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
kbRow.BorderSizePixel = 0
kbRow.LayoutOrder = 4
kbRow.ZIndex = 2
Instance.new("UICorner", kbRow).CornerRadius = UDim.new(0, 9)
Instance.new("UIStroke", kbRow).Color = Color3.fromRGB(40, 40, 40)

local kbLabel = Instance.new("TextLabel", kbRow)
kbLabel.Size = UDim2.new(0.55, 0, 1, 0)
kbLabel.Position = UDim2.new(0, 10, 0, 0)
kbLabel.BackgroundTransparency = 1
kbLabel.Text = "Open/Close Key"
kbLabel.Font = Enum.Font.GothamSemibold
kbLabel.TextSize = 11
kbLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
kbLabel.TextXAlignment = Enum.TextXAlignment.Left
kbLabel.ZIndex = 3

local kbBtn = Instance.new("TextButton", kbRow)
kbBtn.Size = UDim2.new(0, 50, 0, 22)
kbBtn.Position = UDim2.new(1, -56, 0.5, -11)
kbBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
kbBtn.Text = currentKeybind.Name
kbBtn.Font = Enum.Font.GothamBold
kbBtn.TextSize = 10
kbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
kbBtn.BorderSizePixel = 0
kbBtn.ZIndex = 4
Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)
local kbBtnStroke = Instance.new("UIStroke", kbBtn)
kbBtnStroke.Color = Color3.fromRGB(80, 80, 80)
kbBtnStroke.Thickness = 1

kbBtn.MouseButton1Click:Connect(function()
    if waitingForKeybind then return end
    playClick()
    waitingForKeybind = true
    kbBtn.Text = "..."
    kbBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
    local conn
    conn = UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode ~= Enum.KeyCode.Unknown then
            currentKeybind = inp.KeyCode
            kbBtn.Text = inp.KeyCode.Name
            kbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            waitingForKeybind = false
            conn:Disconnect()
        end
    end)
end)

-- Open/close keybind
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe or waitingForKeybind then return end
    if inp.KeyCode == currentKeybind then
        guiVisible = not guiVisible
        if guiVisible then
            mainFrame.Visible = true
            mainFrame.Size = UDim2.new(0, 210, 0, 0)
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 210, 0, 295)
            }):Play()
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 210, 0, 0)
            }):Play()
            task.delay(0.21, function()
                mainFrame.Visible = false
            end)
        end
    end
end)

-- Anti Die label
local antiDieLabel = Instance.new("TextLabel", mainFrame)
antiDieLabel.Size = UDim2.new(1, 0, 0, 16)
antiDieLabel.Position = UDim2.new(0, 0, 1, -18)
antiDieLabel.BackgroundTransparency = 1
antiDieLabel.Text = "✦ Anti Die — Always Active"
antiDieLabel.Font = Enum.Font.Gotham
antiDieLabel.TextSize = 9
antiDieLabel.TextColor3 = Color3.fromRGB(70, 70, 70)
antiDieLabel.ZIndex = 2
