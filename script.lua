repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

----------------------------------------------------------------
local Config = {
    StealRadius         = 20,
    StealDuration       = 0.2,
    GalaxyGravityPercent= 70,
    HopPower            = 35,
    HopCooldown         = 0.08,
    AimbotRadius        = 100,
    BatAimbotSpeed      = 55,
    SpeedBoost          = 29,
    LeftPathSpeed       = 58.5,
    RightPathSpeed      = 58.5,
    LeftReturnSpeed     = 30.4,
    RightReturnSpeed    = 30.4,
}

local Keybinds = {
    AutoLeft     = Enum.KeyCode.Q,
    AutoRight    = Enum.KeyCode.E,
    SpeedBoost   = Enum.KeyCode.R,
    AutoSteal    = Enum.KeyCode.V,
    BatAimbot    = Enum.KeyCode.Z,
    AntiRagdoll  = Enum.KeyCode.X,
    NoAnimations = Enum.KeyCode.N,
    Drop         = Enum.KeyCode.F,
}

local CGREEN  = Color3.fromRGB(255, 60, 60)
local CGRLIT  = Color3.fromRGB(255, 255, 255)
local CGRDIM  = Color3.fromRGB(100, 100, 100)
local CBLACK  = Color3.fromRGB(5,   5,   5)
local CDARK   = Color3.fromRGB(15,  15,  15)
local CDARK2  = Color3.fromRGB(22,  22,  22)
local CDARK3  = Color3.fromRGB(35,  35,  35)
local CW      = Color3.fromRGB(255, 255, 255)
local CGRAY   = Color3.fromRGB(180, 180, 180)
local CON     = Color3.fromRGB(180, 40,  40)
local COFF    = Color3.fromRGB(40,  40,  40)
local CCYAN   = Color3.fromRGB(255, 80,  80)
local NEON1   = Color3.fromRGB(255, 30,  30)
local NEON2   = Color3.fromRGB(255, 120, 120)

local leftActive        = false
local rightActive       = false
local speedBoostConn    = nil
local noAnimConn        = nil
local batAimbotConn     = nil
local batDmgConn        = nil
local lockedTarget      = nil
local MELEE_OFFSET      = 3
local galaxyVectorForce = nil
local galaxyAttachment  = nil
local galaxyEnabled     = false
local hopsEnabled       = false
local lastHopTime       = 0
local spaceHeld         = false
local originalJumpPower = 50
local DEFAULT_GRAVITY   = 196.2
local autoStealEnabled  = false
local isStealing        = false
local stealStartTime    = nil
local StealData         = {}
local progressConnection= nil
local autoStealConn     = nil
local autoStealGui      = nil
local changingKeybind   = nil
local speedBB           = nil
local toggleStates      = {
    AutoLeft=false, AutoRight=false, SpeedBoost=false,
    AutoSteal=false, BatAimbot=false, Galaxy=false,
    Optimizer=false, AntiRagdoll=false, NoAnimations=false,
    XrayBase=false, PlayerESP=false, TPDown=false,
}
local MobileButtonsGui  = nil

local waypointsRight = {
    {position = Vector3.new(-474,-7,29),                      isReturn = false},
    {position = Vector3.new(-473,-7,29),                      isReturn = false},
    {position = Vector3.new(-478,-6,25),                      isReturn = false},
    {position = Vector3.new(-488,-5,23),                      isReturn = false},
    {position = Vector3.new(-488,-5,23),                      isReturn = false},
    {position = Vector3.new(-474,-7,29),                      isReturn = true},
    {position = Vector3.new(-474,-7,29),                      isReturn = true},
    {position = Vector3.new(-473.026947,-7.298133,97.617050), isReturn = true},
    {position = Vector3.new(-483.267639,-5.341616,97.578979), isReturn = true, isEnd = true},
}

local waypointsLeft = {
    {position = Vector3.new(-475,-7,90),                      isReturn = false},
    {position = Vector3.new(-475,-7,90),                      isReturn = false},
    {position = Vector3.new(-479,-5,95),                      isReturn = false},
    {position = Vector3.new(-479,-5,95),                      isReturn = false},
    {position = Vector3.new(-486,-5,97),                      isReturn = false},
    {position = Vector3.new(-486,-5,97),                      isReturn = false},
    {position = Vector3.new(-474.018768,-7.306343,95.489868), isReturn = true},
    {position = Vector3.new(-474.018768,-7.306343,95.489868), isReturn = true},
    {position = Vector3.new(-471.452301,-7.303422,26.809414), isReturn = true},
    {position = Vector3.new(-471.452301,-7.303422,26.809414), isReturn = true},
    {position = Vector3.new(-483.653137,-5.341625,22.855717), isReturn = true, isEnd = true},
}

local _savedToggles = {}
local _savedMobile  = false

local function saveConfig()
    pcall(function()
        local data = {Config=Config, Keybinds={}, Toggles={}, Mobile=false}
        for k,v in pairs(Keybinds) do if v then data.Keybinds[k]=v.Name end end
        for k,v in pairs(toggleStates) do data.Toggles[k]=v end
        if MobileButtonsGui then data.Mobile=MobileButtonsGui.Enabled end
        writefile("KakashiHub_Config.json", HttpService:JSONEncode(data))
    end)
end
local function loadConfig()
    pcall(function()
        if isfile("KakashiHub_Config.json") then
            local data = HttpService:JSONDecode(readfile("KakashiHub_Config.json"))
            if data.Config   then for k,v in pairs(data.Config)   do Config[k]=v end end
            if data.Keybinds then for k,v in pairs(data.Keybinds) do Keybinds[k]=Enum.KeyCode[v] end end
            if data.Toggles  then for k,v in pairs(data.Toggles)  do _savedToggles[k]=v end end
            if data.Mobile   then _savedMobile=data.Mobile end
        end
    end)
end
loadConfig()

local function getHRP()
    local c = player.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso"))
end

----------------------------------------------------------------
-- SPEED LABEL
----------------------------------------------------------------
local function makeSpeedBB()
    local c = player.Character if not c then return end
    local head = c:FindFirstChild("Head") if not head then return end
    if speedBB then pcall(function() speedBB:Destroy() end) end
    speedBB = Instance.new("BillboardGui")
    speedBB.Name = "KakashiSpeedBB"
    speedBB.Adornee = head
    speedBB.Size = UDim2.new(0, 130, 0, 30)
    speedBB.StudsOffset = Vector3.new(0, 3.2, 0)
    speedBB.AlwaysOnTop = true
    speedBB.Parent = head
    local lbl = Instance.new("TextLabel", speedBB)
    lbl.Name = "SpeedLbl"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = CW
    lbl.TextStrokeColor3 = CGREEN
    lbl.TextStrokeTransparency = 0.3
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.Text = "Speed: 0"
end

RunService.RenderStepped:Connect(function()
    if not speedBB or not speedBB.Parent then return end
    local h = getHRP() if not h then return end
    local lbl = speedBB:FindFirstChild("SpeedLbl") if not lbl then return end
    local v = h.AssemblyLinearVelocity
    lbl.Text = "Speed: " .. math.floor(Vector3.new(v.X, 0, v.Z).Magnitude)
end)

makeSpeedBB()
player.CharacterAdded:Connect(function() task.wait(0.5) makeSpeedBB() end)

----------------------------------------------------------------
-- INF JUMP
----------------------------------------------------------------
local infJumpEnabled = true
local jumpForce      = 54
local clampFallSpeed = 80

UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local hrp = getHRP() if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, jumpForce, hrp.AssemblyLinearVelocity.Z)
end)
RunService.Heartbeat:Connect(function()
    if not infJumpEnabled then return end
    local hrp = getHRP() if not hrp then return end
    if hrp.AssemblyLinearVelocity.Y < -clampFallSpeed then
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -clampFallSpeed, hrp.AssemblyLinearVelocity.Z)
    end
end)

----------------------------------------------------------------
-- ANTI-RAGDOLL
----------------------------------------------------------------
local AntiRagdollConns = {}

local function enableAntiRagdoll()
    if #AntiRagdollConns > 0 then return end
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    local animator = humanoid:WaitForChild("Animator")
    local maxVelocity = 40
    local clampVelocity = 25
    local maxClamp = 15
    local lastVelocity = Vector3.new(0, 0, 0)
    local function IsRagdollState()
        local state = humanoid:GetState()
        return state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.GettingUp
    end
    local function CleanRagdollEffects()
        for _, obj in pairs(char:GetDescendants()) do
            if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint")
                or (obj:IsA("Attachment") and (obj.Name == "A" or obj.Name == "B")) then
                obj:Destroy()
            elseif obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                obj:Destroy()
            elseif obj:IsA("Motor6D") then
                obj.Enabled = true
            end
        end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local animName = track.Animation and track.Animation.Name:lower() or ""
            if animName:find("rag") or animName:find("fall") or animName:find("hurt") or animName:find("down") then
                track:Stop(0)
            end
        end
    end
    local function ReEnableControls()
        pcall(function()
            require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Enable()
        end)
    end
    table.insert(AntiRagdollConns, humanoid.StateChanged:Connect(function(_, newState)
        if IsRagdollState() then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            CleanRagdollEffects()
            cam.CameraSubject = humanoid
            ReEnableControls()
        end
    end))
    table.insert(AntiRagdollConns, RunService.Heartbeat:Connect(function()
        if IsRagdollState() then
            CleanRagdollEffects()
            local vel = root.AssemblyLinearVelocity
            local velChange = (vel - lastVelocity).Magnitude
            if velChange > maxVelocity and vel.Magnitude > clampVelocity then
                root.AssemblyLinearVelocity = vel.Unit * math.min(vel.Magnitude, maxClamp)
            end
            lastVelocity = vel
        end
    end))
    table.insert(AntiRagdollConns, char.DescendantAdded:Connect(function()
        if IsRagdollState() then CleanRagdollEffects() end
    end))
    table.insert(AntiRagdollConns, player.CharacterAdded:Connect(function(newChar)
        char = newChar
        humanoid = newChar:WaitForChild("Humanoid")
        root = newChar:WaitForChild("HumanoidRootPart")
        animator = humanoid:WaitForChild("Animator")
        lastVelocity = Vector3.new(0, 0, 0)
        ReEnableControls()
        CleanRagdollEffects()
    end))
    ReEnableControls()
    CleanRagdollEffects()
end

local function disableAntiRagdoll()
    for _, conn in pairs(AntiRagdollConns) do conn:Disconnect() end
    AntiRagdollConns = {}
end

local function startAntiRagdoll() enableAntiRagdoll() end
local function stopAntiRagdoll()  disableAntiRagdoll() end

----------------------------------------------------------------
-- PLAYER ESP
----------------------------------------------------------------
local ESP_COLOR     = CGREEN
local espHighlights = {}
local espBillboards = {}
local espConns      = {}
local espBodyParts  = {}

local BODY_PARTS = {
    "Head","UpperTorso","LowerTorso","Torso",
    "LeftUpperArm","LeftLowerArm","LeftHand",
    "RightUpperArm","RightLowerArm","RightHand",
    "LeftUpperLeg","LeftLowerLeg","LeftFoot",
    "RightUpperLeg","RightLowerLeg","RightFoot",
}

local function _espCreateHighlight(char)
    local h = Instance.new("Highlight")
    h.Name                = "KakashiHub_HL"
    h.Adornee             = char
    h.FillColor           = ESP_COLOR
    h.FillTransparency    = 0.4
    h.OutlineColor        = CCYAN
    h.OutlineTransparency = 0
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent              = player:WaitForChild("PlayerGui")
    return h
end

local function _espCreateBillboard(char, p)
    local hrp = char:WaitForChild("HumanoidRootPart", 5) if not hrp then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name                  = "KakashiHub_BB"
    bb.Adornee               = hrp
    bb.AlwaysOnTop           = true
    bb.Size                  = UDim2.new(0, 110, 0, 22)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    bb.MaxDistance           = 600
    bb.Parent                = player:WaitForChild("PlayerGui")
    local bg = Instance.new("Frame", bb)
    bg.Size                   = UDim2.new(1,0,1,0)
    bg.BackgroundColor3       = Color3.fromRGB(10,10,10)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel        = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color        = CGREEN
    stroke.Thickness    = 1
    stroke.Transparency = 0.3
    local txt = Instance.new("TextLabel", bg)
    txt.Size                   = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font                   = Enum.Font.GothamBold
    txt.TextSize               = 12
    txt.TextColor3             = CW
    txt.TextStrokeTransparency = 0.4
    txt.Text                   = p.DisplayName
    return bb
end

local function _espRemoveBody(p)
    if espBodyParts[p] then
        for _, box in ipairs(espBodyParts[p]) do pcall(function() box:Destroy() end) end
        espBodyParts[p] = nil
    end
end

local function _espCreateBody(char, p)
    _espRemoveBody(p)
    local boxes = {}
    local gui = player:WaitForChild("PlayerGui")
    for _, partName in ipairs(BODY_PARTS) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local box = Instance.new("SelectionBox")
            box.Adornee             = part
            box.Color3              = CGREEN
            box.LineThickness       = 0.04
            box.SurfaceTransparency = 1
            box.SurfaceColor3       = CGREEN
            box.Parent              = gui
            table.insert(boxes, box)
        end
    end
    espBodyParts[p] = boxes
end

local function _espAttach(p)
    if p == player then return end
    local function apply(char)
        if espHighlights[p] then pcall(function() espHighlights[p]:Destroy() end) end
        if espBillboards[p] then pcall(function() espBillboards[p]:Destroy() end) end
        espHighlights[p] = _espCreateHighlight(char)
        espBillboards[p] = _espCreateBillboard(char, p)
        _espCreateBody(char, p)
    end
    if p.Character then apply(p.Character) end
    local c = p.CharacterAdded:Connect(apply)
    table.insert(espConns, c)
end

local function _espRemove(p)
    if espHighlights[p] then pcall(function() espHighlights[p]:Destroy() end) espHighlights[p]=nil end
    if espBillboards[p] then pcall(function() espBillboards[p]:Destroy() end) espBillboards[p]=nil end
    _espRemoveBody(p)
end

local function startPlayerESP()
    for _,p in ipairs(Players:GetPlayers()) do _espAttach(p) end
    table.insert(espConns, Players.PlayerAdded:Connect(_espAttach))
    table.insert(espConns, Players.PlayerRemoving:Connect(_espRemove))
end

local function stopPlayerESP()
    for _,h in pairs(espHighlights) do pcall(function() h:Destroy() end) end
    for _,b in pairs(espBillboards) do pcall(function() b:Destroy() end) end
    for _,c in ipairs(espConns)     do pcall(function() c:Disconnect() end) end
    for p,_ in pairs(espBodyParts)  do _espRemoveBody(p) end
    espHighlights = {}
    espBillboards = {}
    espConns      = {}
end

----------------------------------------------------------------
-- TP DOWN
----------------------------------------------------------------
local function doTPDown()
    local r = getHRP()
    if r then r.CFrame = r.CFrame * CFrame.new(0, -20, 0) end
end

----------------------------------------------------------------
-- NO ANIMATIONS
----------------------------------------------------------------
local function toggleNoAnimations(state)
    if noAnimConn then noAnimConn:Disconnect() noAnimConn=nil end
    if not state then return end
    local char = player.Character if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid") if not hum then return end
    local anim = hum:FindFirstChildOfClass("Animator")
    if anim then for _,t in pairs(anim:GetPlayingAnimationTracks()) do t:Stop() t:AdjustSpeed(0) end end
    noAnimConn = hum.AnimationPlayed:Connect(function(t) t:Stop() t:AdjustSpeed(0) end)
end

----------------------------------------------------------------
-- GALAXY MODE
----------------------------------------------------------------
local function captureJumpPower()
    local c = player.Character
    if c then local h=c:FindFirstChildOfClass("Humanoid") if h and h.JumpPower>0 then originalJumpPower=h.JumpPower end end
end
task.spawn(function() task.wait(1) captureJumpPower() end)
player.CharacterAdded:Connect(function() task.wait(1) captureJumpPower() end)

local function setupGalaxyForce()
    pcall(function()
        local c=player.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment  then galaxyAttachment:Destroy()  end
        galaxyAttachment=Instance.new("Attachment") galaxyAttachment.Parent=h
        galaxyVectorForce=Instance.new("VectorForce")
        galaxyVectorForce.Attachment0=galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass=true
        galaxyVectorForce.RelativeTo=Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force=Vector3.zero
        galaxyVectorForce.Parent=h
    end)
end
local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c=player.Character if not c then return end
    local mass=0
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end
    local tg=DEFAULT_GRAVITY*(Config.GalaxyGravityPercent/100)
    galaxyVectorForce.Force=Vector3.new(0,mass*(DEFAULT_GRAVITY-tg)*0.95,0)
end
local function adjustGalaxyJump()
    pcall(function()
        local c=player.Character if not c then return end
        local hum=c:FindFirstChildOfClass("Humanoid") if not hum then return end
        if not galaxyEnabled then hum.JumpPower=originalJumpPower return end
        local ratio=math.sqrt((DEFAULT_GRAVITY*(Config.GalaxyGravityPercent/100))/DEFAULT_GRAVITY)
        hum.JumpPower=originalJumpPower*ratio
    end)
end
local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c=player.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart")
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if tick()-lastHopTime<Config.HopCooldown then return end
        lastHopTime=tick()
        if hum.FloorMaterial==Enum.Material.Air then
            h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,Config.HopPower,h.AssemblyLinearVelocity.Z)
        end
    end)
end
local function startGalaxy() galaxyEnabled=true hopsEnabled=true setupGalaxyForce() adjustGalaxyJump() end
local function stopGalaxy()
    galaxyEnabled=false hopsEnabled=false
    if galaxyVectorForce then galaxyVectorForce:Destroy() galaxyVectorForce=nil end
    if galaxyAttachment  then galaxyAttachment:Destroy()  galaxyAttachment=nil  end
    adjustGalaxyJump()
end

RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then doMiniHop() end
    if galaxyEnabled then updateGalaxyForce() end
end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode==Enum.KeyCode.Space then spaceHeld=false end end)

----------------------------------------------------------------
-- BAT AIMBOT (Eclipse version)
----------------------------------------------------------------
local SlapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

local function findBat()
    local c=player.Character if not c then return nil end
    local bp=player:FindFirstChildOfClass("Backpack")
    for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    for _,name in ipairs(SlapList) do
        local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
end

local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local ff  = targetChar:FindFirstChildOfClass("ForceField")
    return hum and hrp and hum.Health > 0 and not ff
end

local function getBestTarget(myHRP)
    if lockedTarget and isTargetValid(lockedTarget) then
        return lockedTarget:FindFirstChild("HumanoidRootPart"), lockedTarget
    end
    local shortestDist, newTargetChar, newTargetHRP = math.huge, nil, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isTargetValid(p.Character) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                newTargetHRP = hrp
                newTargetChar = p.Character
            end
        end
    end
    lockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end

local function startBatAimbot()
    if batAimbotConn then return end

    local function applyShield()
        local char = player.Character if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid") if not hum then return end
        if batDmgConn then batDmgConn:Disconnect() batDmgConn = nil end
        batDmgConn = hum.HealthChanged:Connect(function()
            if toggleStates.BatAimbot and hum and hum.Parent then
                hum.Health = hum.MaxHealth
            end
        end)
    end

    applyShield()
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if toggleStates.BatAimbot then applyShield() end
    end)

    local c = player.Character if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not h or not hum then return end
    hum.AutoRotate = false

    local attachment = h:FindFirstChild("AimbotAttachment") or Instance.new("Attachment", h)
    attachment.Name = "AimbotAttachment"
    local align = h:FindFirstChild("AimbotAlign") or Instance.new("AlignOrientation", h)
    align.Name = "AimbotAlign"
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0 = attachment
    align.MaxTorque = math.huge
    align.Responsiveness = 200

    batAimbotConn = RunService.Heartbeat:Connect(function()
        if not toggleStates.BatAimbot then return end
        local char = player.Character if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local curHum = char:FindFirstChildOfClass("Humanoid")
        if not root or not curHum then return end

        local bat = findBat()
        if bat and bat.Parent ~= char then
            pcall(function() curHum:EquipTool(bat) end)
        end

        local targetHRP, targetChar = getBestTarget(root)
        if targetHRP and targetChar then
            local targetVel = targetHRP.AssemblyLinearVelocity
            local speed = targetVel.Magnitude
            local predictTime = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos = targetHRP.Position + targetVel * predictTime
            local dirToTarget = predictedPos - root.Position
            local dist3D = dirToTarget.Magnitude
            local standPos = predictedPos
            if dist3D > 0 then
                standPos = predictedPos - dirToTarget.Unit * MELEE_OFFSET
            end
            align.CFrame = CFrame.lookAt(root.Position, predictedPos)
            local moveDir = standPos - root.Position
            local distToStand = moveDir.Magnitude
            if distToStand > 1 then
                root.AssemblyLinearVelocity = moveDir.Unit * Config.BatAimbotSpeed
            else
                root.AssemblyLinearVelocity = targetVel
            end
            if distToStand <= 5 then
                if bat and bat.Parent == char then
                    pcall(function() bat:Activate() end)
                end
            end
        else
            lockedTarget = nil
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function stopBatAimbot()
    if batAimbotConn then batAimbotConn:Disconnect() batAimbotConn = nil end
    if batDmgConn then batDmgConn:Disconnect() batDmgConn = nil end
    lockedTarget = nil
    local c = player.Character
    local h = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        local att = h:FindFirstChild("AimbotAttachment") if att then att:Destroy() end
        local al = h:FindFirstChild("AimbotAlign") if al then al:Destroy() end
        h.AssemblyLinearVelocity = Vector3.zero
    end
    if hum then hum.AutoRotate = true end
end

----------------------------------------------------------------
-- SPEED BOOST
----------------------------------------------------------------
local function startSpeedBoost()
    if speedBoostConn then return end
    speedBoostConn=RunService.Heartbeat:Connect(function()
        local char=player.Character if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        local hrp=char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        local md=hum.MoveDirection
        if md.Magnitude>0.1 then
            hrp.AssemblyLinearVelocity=Vector3.new(md.X*Config.SpeedBoost,hrp.AssemblyLinearVelocity.Y,md.Z*Config.SpeedBoost)
        end
    end)
end
local function stopSpeedBoost()
    if speedBoostConn then speedBoostConn:Disconnect() speedBoostConn=nil end
end

----------------------------------------------------------------
-- DROP
----------------------------------------------------------------
local function doDrop()
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    local originalY = root.Position.Y
    local protected = true
    local protConn = humanoid.HealthChanged:Connect(function(hp)
        if protected and humanoid.Parent and hp < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    root.AssemblyLinearVelocity = Vector3.new(
        root.AssemblyLinearVelocity.X, 100, root.AssemblyLinearVelocity.Z)
    local start = tick()
    while tick() - start < 0.2 do
        local pos = root.Position
        root.CFrame = CFrame.new(pos.X, originalY, pos.Z) * CFrame.Angles(0, root.Orientation.Y * math.pi/180, 0)
        task.wait()
    end
    local timeout = tick() + 5
    repeat task.wait(0.05) until
        humanoid.FloorMaterial ~= Enum.Material.Air or
        tick() > timeout or
        not humanoid.Parent
    task.wait()
    protected = false
    protConn:Disconnect()
end

----------------------------------------------------------------
-- OPTIMIZER + X-RAY BASE
----------------------------------------------------------------
local originalTransparency = {}

local function enableOptimizer()
    pcall(function()
        settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
        game:GetService("Lighting").GlobalShadows=false
        game:GetService("Lighting").FogEnd=9e9
    end)
    pcall(function()
        for _,obj in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj:Destroy()
                elseif obj:IsA("BasePart") then obj.CastShadow=false obj.Material=Enum.Material.Plastic end
            end)
        end
    end)
end
local function disableOptimizer()
    for part,val in pairs(originalTransparency) do if part then part.LocalTransparencyModifier=val end end
    originalTransparency={}
end

local xrayConn     = nil
local xrayOriginal = {}

local function isPlayerBase(obj)
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then return false end
    local n = obj.Name:lower()
    local p = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or n:find("claim") or p:find("base") or p:find("claim")
end

local function applyXrayObj(obj)
    if isPlayerBase(obj) then
        if xrayOriginal[obj]==nil then xrayOriginal[obj]=obj.LocalTransparencyModifier end
        obj.LocalTransparencyModifier=0.8
    end
end

local function startXrayBase()
    if xrayConn then return end
    for _,obj in ipairs(Workspace:GetDescendants()) do pcall(function() applyXrayObj(obj) end) end
    xrayConn=Workspace.DescendantAdded:Connect(function(obj) pcall(function() applyXrayObj(obj) end) end)
end

local function stopXrayBase()
    if xrayConn then xrayConn:Disconnect() xrayConn=nil end
    for part,orig in pairs(xrayOriginal) do
        pcall(function() if part and part.Parent then part.LocalTransparencyModifier=orig end end)
    end
    xrayOriginal={}
end

----------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------
local currentWaypoint = 1
local wpConnection    = nil

local function stopWaypoints()
    if wpConnection then wpConnection:Disconnect() wpConnection=nil end
    leftActive  = false
    rightActive = false
    local hrp = getHRP()
    if hrp then hrp.Velocity=Vector3.zero end
end

local function startWaypoints(wps, activeFlag, onEnd)
    stopWaypoints()
    currentWaypoint = 1
    if activeFlag=="left"  then leftActive=true  end
    if activeFlag=="right" then rightActive=true end
    wpConnection = RunService.Stepped:Connect(function()
        local isActive=(activeFlag=="left" and leftActive) or (activeFlag=="right" and rightActive)
        if not isActive then wpConnection:Disconnect() wpConnection=nil return end
        local char=player.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or #wps==0 then return end
        local wp=wps[currentWaypoint]
        local dist=(hrp.Position-wp.position).Magnitude
        if dist<5 then
            if wp.isEnd then
                stopWaypoints()
                if onEnd then onEnd() end
                return
            end
            currentWaypoint=(currentWaypoint%#wps)+1
        else
            local dir=(wp.position-hrp.Position).Unit
            local spd
            if wp.isReturn then
                spd = activeFlag=="left" and Config.LeftReturnSpeed or Config.RightReturnSpeed
            else
                spd = activeFlag=="left" and Config.LeftPathSpeed or Config.RightPathSpeed
            end
            hrp.Velocity=Vector3.new(dir.X*spd,hrp.Velocity.Y,dir.Z*spd)
        end
    end)
end

----------------------------------------------------------------
-- AUTO STEAL
----------------------------------------------------------------
local function isMyPlot(plotName)
    local plots=workspace:FindFirstChild("Plots") if not plots then return false end
    local plot=plots:FindFirstChild(plotName) if not plot then return false end
    local sign=plot:FindFirstChild("PlotSign") if not sign then return false end
    local yb=sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled==true
end

local function findNearestPrompt()
    local hrp=getHRP() if not hrp then return nil,math.huge,nil end
    local plots=workspace:FindFirstChild("Plots") if not plots then return nil,math.huge,nil end
    local np,nd,nn=nil,math.huge,nil
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlot(plot.Name) then continue end
        local podiums=plot:FindFirstChild("AnimalPodiums") if not podiums then continue end
        for _,pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base=pod:FindFirstChild("Base")
                local spawn=base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist=(spawn.Position-hrp.Position).Magnitude
                    if dist<nd and dist<=Config.StealRadius then
                        local att=spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _,ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then np=ch nd=dist nn=pod.Name break end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np,nd,nn
end

local ProgressBarFill    = nil
local ProgressPercentLbl = nil

local function resetProgressBar()
    if ProgressPercentLbl then ProgressPercentLbl.Text="0%" end
    if ProgressBarFill then ProgressBarFill.Size=UDim2.new(0,0,1,0) end
end

local function executeSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt]={hold={},trigger={},ready=true}
        pcall(function()
            if getconnections then
                for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold,c.Function) end
                end
                for _,c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger,c.Function) end
                end
            end
        end)
    end
    local data=StealData[prompt]
    if not data.ready then return end
    data.ready=false isStealing=true stealStartTime=tick()
    if progressConnection then progressConnection:Disconnect() progressConnection=nil end
    progressConnection=RunService.Heartbeat:Connect(function()
        if not isStealing then
            if progressConnection then progressConnection:Disconnect() progressConnection=nil end return
        end
        local prog=math.clamp((tick()-stealStartTime)/Config.StealDuration,0,1)
        if ProgressBarFill then ProgressBarFill.Size=UDim2.new(prog,0,1,0) end
        if ProgressPercentLbl then ProgressPercentLbl.Text=math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        for _,f in ipairs(data.hold) do task.spawn(function() pcall(f) end) end
        task.wait(Config.StealDuration)
        for _,f in ipairs(data.trigger) do task.spawn(function() pcall(f) end) end
        if progressConnection then progressConnection:Disconnect() progressConnection=nil end
        resetProgressBar() data.ready=true isStealing=false
    end)
end

local function startAutoSteal()
    if autoStealConn then return end
    autoStealConn=RunService.Heartbeat:Connect(function()
        if not autoStealEnabled or isStealing then return end
        local p,_,n=findNearestPrompt()
        if p then executeSteal(p,n) end
    end)
end
local function stopAutoSteal()
    if autoStealConn then autoStealConn:Disconnect() autoStealConn=nil end
    isStealing=false
    if progressConnection then progressConnection:Disconnect() progressConnection=nil end
    resetProgressBar()
end

local function initAutoStealGUI()
    if autoStealGui then pcall(function() autoStealGui:Destroy() end) autoStealGui=nil end
    autoStealGui=Instance.new("ScreenGui")
    autoStealGui.Name="KakashiHubAutoSteal"
    autoStealGui.ResetOnSpawn=false
    autoStealGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    autoStealGui.Parent=player:WaitForChild("PlayerGui")
    local frame=Instance.new("Frame",autoStealGui)
    frame.Size=UDim2.new(0,260,0,56)
    frame.Position=UDim2.new(0.5,-130,0,10)
    frame.BackgroundColor3=CBLACK frame.BackgroundTransparency=0.1 frame.BorderSizePixel=0
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local stroke=Instance.new("UIStroke",frame) stroke.Thickness=1.5 stroke.Color=CGREEN
    ProgressPercentLbl=Instance.new("TextLabel",frame)
    ProgressPercentLbl.Size=UDim2.new(0,36,0,22) ProgressPercentLbl.Position=UDim2.new(0,6,0,4)
    ProgressPercentLbl.BackgroundTransparency=1 ProgressPercentLbl.Text="0%"
    ProgressPercentLbl.Font=Enum.Font.GothamBold ProgressPercentLbl.TextSize=11
    ProgressPercentLbl.TextColor3=CGREEN ProgressPercentLbl.TextXAlignment=Enum.TextXAlignment.Left
    local bg=Instance.new("Frame",frame)
    bg.Size=UDim2.new(0,160,0,8) bg.Position=UDim2.new(0,44,0,11)
    bg.BackgroundColor3=CDARK2 bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
    ProgressBarFill=Instance.new("Frame",bg)
    ProgressBarFill.Name="Fill" ProgressBarFill.Size=UDim2.new(0,0,1,0)
    ProgressBarFill.BackgroundColor3=CGREEN ProgressBarFill.BorderSizePixel=0
    Instance.new("UICorner",ProgressBarFill).CornerRadius=UDim.new(1,0)
    local radLbl=Instance.new("TextLabel",frame)
    radLbl.Size=UDim2.new(0,38,0,22) radLbl.Position=UDim2.new(1,-42,0,4)
    radLbl.BackgroundTransparency=1 radLbl.Font=Enum.Font.GothamBold radLbl.TextSize=10
    radLbl.TextColor3=CGREEN radLbl.TextXAlignment=Enum.TextXAlignment.Right
    task.spawn(function()
        while autoStealGui and autoStealGui.Parent do
            radLbl.Text="r:"..tostring(Config.StealRadius) task.wait(0.5)
        end
    end)
    local div=Instance.new("Frame",frame)
    div.Size=UDim2.new(1,-16,0,1) div.Position=UDim2.new(0,8,0,28)
    div.BackgroundColor3=CDARK3 div.BorderSizePixel=0
    local stLbl=Instance.new("TextLabel",frame)
    stLbl.Size=UDim2.new(0,78,0,20) stLbl.Position=UDim2.new(0,8,0,31)
    stLbl.BackgroundTransparency=1 stLbl.Font=Enum.Font.GothamBold stLbl.TextSize=10
    stLbl.TextColor3=CGRAY stLbl.TextXAlignment=Enum.TextXAlignment.Left
    stLbl.Text="Steal Time (s):"
    local stInput=Instance.new("TextBox",frame)
    stInput.Size=UDim2.new(0,58,0,18) stInput.Position=UDim2.new(1,-64,0,32)
    stInput.BackgroundColor3=CDARK2 stInput.BorderSizePixel=0
    stInput.Text=tostring(Config.StealDuration)
    stInput.Font=Enum.Font.GothamBold stInput.TextSize=11
    stInput.TextColor3=CGREEN stInput.TextXAlignment=Enum.TextXAlignment.Center
    stInput.ClearTextOnFocus=false
    Instance.new("UICorner",stInput).CornerRadius=UDim.new(0,5)
    local inStroke=Instance.new("UIStroke",stInput) inStroke.Color=CGRDIM inStroke.Thickness=1
    stInput.FocusLost:Connect(function()
        local n=tonumber(stInput.Text)
        if n and n>=0.05 and n<=10 then
            Config.StealDuration=math.floor(n*100+0.5)/100
            stInput.Text=tostring(Config.StealDuration)
        else
            stInput.Text=tostring(Config.StealDuration)
        end
    end)
    stInput.Focused:Connect(function() inStroke.Color=CGREEN inStroke.Thickness=1.5 end)
    stInput.FocusLost:Connect(function() inStroke.Color=CGRDIM inStroke.Thickness=1 end)
end

----------------------------------------------------------------
-- TOGGLE STATE HELPER
----------------------------------------------------------------
local function setMobBtn(btn, active)
    TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=active and CON or Color3.fromRGB(25,8,8)}):Play()
end

----------------------------------------------------------------
-- GUI SETUP
----------------------------------------------------------------
local _lo = {v=0}
local _ContentFrame, _makeCatLabel, _makeToggleRow, _makeNumRow
local _ScreenGui, _MainFrame, _closeBtn
local _doToggle
local _reopenBtn

do -- BLOCK 1

for _,g in ipairs(player.PlayerGui:GetChildren()) do
    if g.Name=="KakashiHubGUI" then g:Destroy() end
end

_ScreenGui=Instance.new("ScreenGui")
local ScreenGui=_ScreenGui
ScreenGui.Name="KakashiHubGUI"
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn=false

_MainFrame=Instance.new("Frame",ScreenGui)
local MainFrame=_MainFrame
MainFrame.Name="MainFrame"
MainFrame.Size=UDim2.new(0,272,0,460)
MainFrame.Position=UDim2.new(0.5,-136,0.5,-230)
MainFrame.BackgroundColor3=CBLACK
MainFrame.BorderSizePixel=0
MainFrame.Active=true
MainFrame.Draggable=true
Instance.new("UICorner",MainFrame).CornerRadius=UDim.new(0,14)

local MainStroke=Instance.new("UIStroke",MainFrame)
MainStroke.Thickness=2 MainStroke.Color=CGREEN
MainStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
task.spawn(function()
    while MainFrame.Parent do
        for i=0,30 do MainStroke.Thickness=2+(i*0.03) task.wait(0.03) end
        for i=0,30 do MainStroke.Thickness=2.9-(i*0.03) task.wait(0.03) end
    end
end)

local bgGrad=Instance.new("UIGradient",MainFrame)
bgGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(5,5,5)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(12,12,12)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(3,3,3)),
}) bgGrad.Rotation=135

local TitleBar=Instance.new("Frame",MainFrame)
TitleBar.Size=UDim2.new(1,0,0,44) TitleBar.BackgroundColor3=CDARK TitleBar.BorderSizePixel=0
Instance.new("UICorner",TitleBar).CornerRadius=UDim.new(0,14)
do
    local tbGrad=Instance.new("UIGradient",TitleBar)
    tbGrad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(20,20,20)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(45,45,45)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(20,20,20))
    }) tbGrad.Rotation=90
end

local PLogo=Instance.new("TextLabel",TitleBar)
PLogo.Size=UDim2.new(0,28,0,28) PLogo.Position=UDim2.new(0,8,0.5,-14)
PLogo.BackgroundColor3=CDARK3 PLogo.Text="K"
PLogo.Font=Enum.Font.GothamBlack PLogo.TextSize=20
PLogo.TextColor3=CGREEN PLogo.TextXAlignment=Enum.TextXAlignment.Center PLogo.BorderSizePixel=0
Instance.new("UICorner",PLogo).CornerRadius=UDim.new(0,7)
local pLogoStroke=Instance.new("UIStroke",PLogo)
pLogoStroke.Thickness=2 pLogoStroke.Color=CGREEN pLogoStroke.Transparency=0.1
task.spawn(function()
    local t=0 while PLogo.Parent do
        t=t+0.05 local p=math.abs(math.sin(t))
        pLogoStroke.Color=Color3.fromRGB(math.floor(200+p*55),math.floor(p*30),math.floor(p*30))
        pLogoStroke.Transparency=0.05+p*0.3
        task.wait(0.03)
    end
end)

local Title=Instance.new("TextLabel",TitleBar)
Title.Size=UDim2.new(1,-90,0,26) Title.Position=UDim2.new(0,42,0,5)
Title.BackgroundTransparency=1 Title.Text="KAKASHI HUB"
Title.Font=Enum.Font.GothamBlack Title.TextSize=15
Title.TextColor3=CGREEN Title.TextXAlignment=Enum.TextXAlignment.Left
local titleGrad=Instance.new("UIGradient",Title)
titleGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,80,80)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,160,160)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(200,60,60))
})
task.spawn(function() local r=0 while Title.Parent do r=(r+2)%360 titleGrad.Rotation=r task.wait(0.03) end end)

local titleBorder=Instance.new("Frame",TitleBar)
titleBorder.Size=UDim2.new(1,0,0,1.5) titleBorder.Position=UDim2.new(0,0,1,-1.5)
titleBorder.BackgroundColor3=CGREEN titleBorder.BorderSizePixel=0
task.spawn(function()
    local t=0 while titleBorder.Parent do
        t=t+0.04 local p=math.abs(math.sin(t))
        local r=math.floor(200+p*55)
        titleBorder.BackgroundColor3=Color3.fromRGB(r,math.floor(p*20),math.floor(p*20))
        task.wait(0.03)
    end
end)

_closeBtn=Instance.new("TextButton",TitleBar)
local closeBtn=_closeBtn
closeBtn.Size=UDim2.new(0,26,0,26) closeBtn.Position=UDim2.new(1,-32,0.5,-13)
closeBtn.BackgroundColor3=CDARK3 closeBtn.BorderSizePixel=0
closeBtn.Text="✕" closeBtn.TextColor3=CGRLIT
closeBtn.Font=Enum.Font.GothamBold closeBtn.TextSize=12
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
Instance.new("UIStroke",closeBtn).Color=CGREEN

_ContentFrame=Instance.new("ScrollingFrame",MainFrame)
local ContentFrame=_ContentFrame
ContentFrame.Size=UDim2.new(1,-14,1,-52)
ContentFrame.Position=UDim2.new(0,7,0,50)
ContentFrame.BackgroundTransparency=1
ContentFrame.BorderSizePixel=0
ContentFrame.ScrollBarThickness=3
ContentFrame.ScrollBarImageColor3=CGREEN
ContentFrame.CanvasSize=UDim2.new(0,0,0,0)
ContentFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y

local listLayout=Instance.new("UIListLayout",ContentFrame)
listLayout.Padding=UDim.new(0,6)
listLayout.SortOrder=Enum.SortOrder.LayoutOrder
local contentPad=Instance.new("UIPadding",ContentFrame)
contentPad.PaddingBottom=UDim.new(0,8)

local function makeCategoryLabel(text)
    _lo.v=_lo.v+1
    local lbl=Instance.new("TextLabel",ContentFrame)
    lbl.Size=UDim2.new(1,0,0,18)
    lbl.BackgroundTransparency=1
    lbl.Text=text
    lbl.Font=Enum.Font.GothamBlack
    lbl.TextSize=10
    lbl.TextColor3=CGRDIM
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.LayoutOrder=_lo.v
    Instance.new("UIPadding",lbl).PaddingLeft=UDim.new(0,4)
    if _lo.v>1 then
        local spacer=Instance.new("Frame",ContentFrame)
        spacer.Size=UDim2.new(1,0,0,2)
        spacer.BackgroundTransparency=1
        spacer.LayoutOrder=_lo.v-0.5
    end
end
_makeCatLabel = makeCategoryLabel

local function makeToggleRow(labelText, keybindKey)
    _lo.v=_lo.v+1
    local row=Instance.new("Frame",ContentFrame)
    row.Size=UDim2.new(1,0,0,36)
    row.BackgroundColor3=CDARK2
    row.BorderSizePixel=0
    row.LayoutOrder=_lo.v
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,9)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-100,1,0) lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=labelText
    lbl.Font=Enum.Font.GothamBold lbl.TextSize=12
    lbl.TextColor3=CW lbl.TextXAlignment=Enum.TextXAlignment.Left
    local kbBtn=Instance.new("TextButton",row)
    kbBtn.Size=UDim2.new(0,28,0,22) kbBtn.Position=UDim2.new(1,-70,0.5,-11)
    kbBtn.BackgroundColor3=CDARK3 kbBtn.BorderSizePixel=0
    local kbKey=Keybinds[keybindKey]
    kbBtn.Text=kbKey and kbKey.Name:sub(1,1) or "—"
    kbBtn.Font=Enum.Font.GothamBold kbBtn.TextSize=11 kbBtn.TextColor3=CGRAY
    Instance.new("UICorner",kbBtn).CornerRadius=UDim.new(0,5)
    local kbStroke=Instance.new("UIStroke",kbBtn) kbStroke.Color=CGRDIM kbStroke.Thickness=1
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(0,34,0,22) btn.Position=UDim2.new(1,-34,0.5,-11)
    btn.BackgroundColor3=COFF btn.BorderSizePixel=0
    btn.Text="OFF" btn.Font=Enum.Font.GothamBold btn.TextSize=10 btn.TextColor3=CGRAY
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local btnStroke=Instance.new("UIStroke",btn) btnStroke.Color=CGRDIM btnStroke.Thickness=1
    kbBtn.MouseButton1Click:Connect(function()
        if changingKeybind then return end
        changingKeybind=keybindKey
        kbBtn.Text="?" kbBtn.TextColor3=CGREEN
        local conn
        conn=UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.Keyboard then
                if input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.RightControl then
                    Keybinds[keybindKey]=nil kbBtn.Text="—" kbBtn.TextColor3=CGRAY
                else
                    Keybinds[keybindKey]=input.KeyCode
                    kbBtn.Text=input.KeyCode.Name:sub(1,1) kbBtn.TextColor3=CGRAY
                end
                saveConfig() changingKeybind=nil conn:Disconnect()
            end
        end)
    end)
    return btn, btnStroke
end
_makeToggleRow = makeToggleRow

local function makeNumRow(labelText, cfgKey, minV, maxV)
    _lo.v=_lo.v+1
    local row=Instance.new("Frame",ContentFrame)
    row.Size=UDim2.new(1,0,0,36)
    row.BackgroundColor3=CDARK2
    row.BorderSizePixel=0
    row.LayoutOrder=_lo.v
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,9)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-90,1,0) lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=labelText
    lbl.Font=Enum.Font.GothamBold lbl.TextSize=12 lbl.TextColor3=CW lbl.TextXAlignment=Enum.TextXAlignment.Left
    local nb=Instance.new("TextButton",row)
    nb.Size=UDim2.new(0,70,0,24) nb.Position=UDim2.new(1,-76,0.5,-12)
    nb.BackgroundColor3=CON nb.BorderSizePixel=0
    nb.Text=tostring(Config[cfgKey])
    nb.Font=Enum.Font.GothamBold nb.TextSize=11 nb.TextColor3=CW
    Instance.new("UICorner",nb).CornerRadius=UDim.new(0,7)
    nb.MouseButton1Click:Connect(function()
        local tb=Instance.new("TextBox",row)
        tb.Size=nb.Size tb.Position=nb.Position
        tb.BackgroundColor3=CON tb.Text=tostring(Config[cfgKey])
        tb.Font=nb.Font tb.TextSize=nb.TextSize tb.TextColor3=CW
        tb.ClearTextOnFocus=false tb.BorderSizePixel=0
        Instance.new("UICorner",tb).CornerRadius=UDim.new(0,7)
        tb:CaptureFocus()
        tb.FocusLost:Connect(function(enter)
            if enter then local n=tonumber(tb.Text) if n and n>=minV and n<=maxV then Config[cfgKey]=n nb.Text=tostring(n) end end
            tb:Destroy()
        end)
    end)
end
_makeNumRow = makeNumRow

end -- BLOCK 1

do -- BLOCK 2
local ScreenGui         = _ScreenGui
local ContentFrame      = _ContentFrame
local closeBtn          = _closeBtn
local MainFrame         = _MainFrame
local MobileSupportBtn, mssS
local makeCategoryLabel = _makeCatLabel
local makeToggleRow     = _makeToggleRow
local makeNumRow        = _makeNumRow

local M = {}
local B = {}
local function TR(label, key) local b,s=makeToggleRow(label,key) B[key or label]={b,s} return b,s end

makeCategoryLabel("── MOVEMENT")
TR("Auto Left",    "AutoLeft")
TR("Auto Right",   "AutoRight")
TR("Speed Boost",  "SpeedBoost")

makeCategoryLabel("── COMBAT")
TR("Auto Steal",  "AutoSteal")
TR("Bat Aimbot",  "BatAimbot")
TR("Jump (Galaxy)","Galaxy")
TR("TP Down",     "TPDown")
TR("Player ESP",  "PlayerESP")

makeCategoryLabel("── UTILITY")
TR("Anti Ragdoll",    "AntiRagdoll")
TR("No Animations",   "NoAnimations")
TR("Drop (one-shot)", "Drop")
TR("X-Ray Base",      "XrayBase")
TR("Optimizer",       "Optimizer")

makeCategoryLabel("── SETTINGS")
makeNumRow("Speed Boost",        "SpeedBoost",           1, 100)
makeNumRow("Grab Radius",        "StealRadius",          1, 999999)
makeNumRow("Steal Speed",        "StealDuration",        0.01, 10)
makeNumRow("Left Path Speed",    "LeftPathSpeed",        1, 200)
makeNumRow("Right Path Speed",   "RightPathSpeed",       1, 200)
makeNumRow("Left Return Speed",  "LeftReturnSpeed",      1, 200)
makeNumRow("Right Return Speed", "RightReturnSpeed",     1, 200)
makeNumRow("Galaxy Gravity",     "GalaxyGravityPercent", 1, 130)
makeNumRow("Hop Power",          "HopPower",             1, 80)
makeNumRow("Aimbot Radius",      "AimbotRadius",         1, 999)
makeNumRow("Aimbot Speed",       "BatAimbotSpeed",       1, 200)

_lo.v=_lo.v+1
local saveBtn=Instance.new("TextButton",ContentFrame)
saveBtn.Size=UDim2.new(1,0,0,34) saveBtn.LayoutOrder=_lo.v
saveBtn.BackgroundColor3=CON saveBtn.BorderSizePixel=0
saveBtn.Text="SAVE CONFIG" saveBtn.Font=Enum.Font.GothamBlack saveBtn.TextSize=13 saveBtn.TextColor3=CW
Instance.new("UICorner",saveBtn).CornerRadius=UDim.new(0,9)
saveBtn.MouseButton1Click:Connect(function()
    saveConfig() saveBtn.Text="✅ SAVED!" task.wait(1.5) saveBtn.Text="SAVE CONFIG"
end)

makeCategoryLabel("── MOBILE")
_lo.v=_lo.v+1
local MobileSupportRow=Instance.new("Frame",ContentFrame)
MobileSupportRow.Size=UDim2.new(1,0,0,36) MobileSupportRow.BackgroundColor3=CDARK2
MobileSupportRow.BorderSizePixel=0 MobileSupportRow.LayoutOrder=_lo.v
Instance.new("UICorner",MobileSupportRow).CornerRadius=UDim.new(0,9)
do
    local mLbl=Instance.new("TextLabel",MobileSupportRow)
    mLbl.Size=UDim2.new(1,-80,1,0) mLbl.Position=UDim2.new(0,10,0,0)
    mLbl.BackgroundTransparency=1 mLbl.Text="Mobile Buttons"
    mLbl.Font=Enum.Font.GothamBold mLbl.TextSize=12 mLbl.TextColor3=CW mLbl.TextXAlignment=Enum.TextXAlignment.Left
end
MobileSupportBtn=Instance.new("TextButton",MobileSupportRow)
MobileSupportBtn.Size=UDim2.new(0,34,0,22) MobileSupportBtn.Position=UDim2.new(1,-40,0.5,-11)
MobileSupportBtn.BackgroundColor3=COFF MobileSupportBtn.BorderSizePixel=0
MobileSupportBtn.Text="OFF" MobileSupportBtn.Font=Enum.Font.GothamBold MobileSupportBtn.TextSize=10 MobileSupportBtn.TextColor3=CGRAY
Instance.new("UICorner",MobileSupportBtn).CornerRadius=UDim.new(0,5)
mssS=Instance.new("UIStroke",MobileSupportBtn) mssS.Color=CGRDIM mssS.Thickness=1

----------------------------------------------------------------
-- REOPEN BUTTON
----------------------------------------------------------------
_reopenBtn=Instance.new("Frame",ScreenGui)
local reopenBtn=_reopenBtn
reopenBtn.Name="KakashiHubReopenBtn"
reopenBtn.Size=UDim2.new(0,46,0,46)
reopenBtn.Position=UDim2.new(0,10,0,56)
reopenBtn.BackgroundColor3=Color3.fromRGB(40,40,40)
reopenBtn.BorderSizePixel=0 reopenBtn.ZIndex=10
reopenBtn.Active=true reopenBtn.Visible=false
Instance.new("UICorner",reopenBtn).CornerRadius=UDim.new(0,12)
local reopenStroke=Instance.new("UIStroke",reopenBtn)
reopenStroke.Thickness=2 reopenStroke.Color=CGREEN
reopenStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
task.spawn(function()
    local t=0 while reopenBtn.Parent do
        t=t+0.05 local p=math.abs(math.sin(t))
        local r=math.floor(180+p*75)
        reopenStroke.Color=Color3.fromRGB(r,math.floor(p*20),math.floor(p*20))
        reopenStroke.Transparency=p*0.35
        local bg=math.floor(30+p*40)
        reopenBtn.BackgroundColor3=Color3.fromRGB(bg,math.floor(bg*0.3),math.floor(bg*0.3))
        task.wait(0.03)
    end
end)
local reopenP=Instance.new("TextLabel",reopenBtn)
reopenP.Size=UDim2.new(1,0,1,0) reopenP.BackgroundTransparency=1
reopenP.Text="K" reopenP.Font=Enum.Font.GothamBlack
reopenP.TextSize=26 reopenP.TextColor3=CW
reopenP.TextXAlignment=Enum.TextXAlignment.Center reopenP.ZIndex=11
local reopenClick=Instance.new("TextButton",reopenBtn)
reopenClick.Size=UDim2.new(1,0,1,0) reopenClick.BackgroundTransparency=1
reopenClick.Text="" reopenClick.ZIndex=12

do
    local dragging=false local dragStart=nil local startPos=nil
    local dragThreshold=6 local dragMoved=false
    reopenClick.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true dragMoved=false
            dragStart=input.Position startPos=reopenBtn.Position
        end
    end)
    reopenClick.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            if math.abs(delta.X)>dragThreshold or math.abs(delta.Y)>dragThreshold then dragMoved=true end
            if dragMoved then
                local vp=Camera.ViewportSize
                local newX=math.clamp(startPos.X.Offset+delta.X,0,vp.X-46)
                local newY=math.clamp(startPos.Y.Offset+delta.Y,0,vp.Y-46)
                reopenBtn.Position=UDim2.new(0,newX,0,newY)
            end
        end
    end)
    reopenClick.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            local wasDrag=dragMoved dragging=false dragMoved=false
            if not wasDrag then
                reopenBtn.Visible=false MainFrame.Visible=true
                TweenService:Create(MainFrame,TweenInfo.new(0.4,Enum.EasingStyle.Back),{Size=UDim2.new(0,272,0,460)}):Play()
            end
        end
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,272,0,0)}):Play()
    task.wait(0.35) MainFrame.Visible=false reopenBtn.Visible=true
end)

----------------------------------------------------------------
-- MOBILE BUTTONS
----------------------------------------------------------------
MobileButtonsGui=Instance.new("ScreenGui")
MobileButtonsGui.Name="KakashiHubMobileButtons"
MobileButtonsGui.ResetOnSpawn=false
MobileButtonsGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
MobileButtonsGui.Enabled=false
MobileButtonsGui.Parent=player:WaitForChild("PlayerGui")

do
    local BW = 52
    local BH = 38
    local GAP = 6

    local function defaultPos(i)
        local col = (i <= 3) and 0 or 1
        local row = (i - 1) % 3
        local x = -(BW * 2 + GAP + 10) + col * (BW + GAP)
        local y = -(BH * 3 + GAP * 2) / 2 + row * (BH + GAP)
        return UDim2.new(1, x, 0.5, y)
    end

    local function addNeonGlow(frame)
        local glowStroke = Instance.new("UIStroke", frame)
        glowStroke.Thickness = 3
        glowStroke.Color = NEON1
        glowStroke.Transparency = 0
        local glow2 = Instance.new("UIStroke", frame)
        glow2.Thickness = 6
        glow2.Color = NEON1
        glow2.Transparency = 0.6
        task.spawn(function()
            local t = 0
            while frame and frame.Parent do
                t = t + 0.06
                local p = math.abs(math.sin(t))
                local r = math.floor(200 + p * 55)
                local g = math.floor(p * 25)
                glowStroke.Color = Color3.fromRGB(r, g, g)
                glowStroke.Thickness = 2.5 + p * 2
                glow2.Color = Color3.fromRGB(r, g, g)
                glow2.Transparency = 0.4 + p * 0.35
                glow2.Thickness = 5 + p * 4
                task.wait(0.03)
            end
        end)
        return glowStroke
    end

    local function makeMobButton(label, index)
        local frame = Instance.new("Frame", MobileButtonsGui)
        frame.Size = UDim2.new(0, BW, 0, BH)
        frame.Position = defaultPos(index)
        frame.BackgroundColor3 = Color3.fromRGB(25, 8, 8)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.ZIndex = 15
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        addNeonGlow(frame)
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 10
        lbl.TextColor3 = Color3.fromRGB(255, 180, 180)
        lbl.TextWrapped = true
        lbl.ZIndex = 16
        return frame, lbl
    end

    local fAL,  bAL  = makeMobButton("AUTO\nL",    1)
    local fAR,  bAR  = makeMobButton("AUTO\nR",    2)
    local fSP,  bSP  = makeMobButton("SPEED",      3)
    local fBAT, bBAT = makeMobButton("BAT\nAIMBOT",4)
    local fTP,  bTP  = makeMobButton("TP\nDOWN",   5)
    local fDRP, bDRP = makeMobButton("DROP",       6)

    M.L1 = fAL  M.L2 = fAR  M.L3 = fSP
    M.R1 = fBAT M.R2 = fTP  M.R3 = fDRP

    local function onTap(frame, fn)
        local pressing = false
        UserInputService.InputBegan:Connect(function(inp)
            if (inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch) then return end
            if not frame.Visible then return end
            local ap = frame.AbsolutePosition local as = frame.AbsoluteSize
            if inp.Position.X >= ap.X and inp.Position.X <= ap.X+as.X and inp.Position.Y >= ap.Y and inp.Position.Y <= ap.Y+as.Y then
                pressing = true
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if not pressing then return end
            if (inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch) then return end
            local ap = frame.AbsolutePosition local as = frame.AbsoluteSize
            local inF = inp.Position.X >= ap.X and inp.Position.X <= ap.X+as.X and inp.Position.Y >= ap.Y and inp.Position.Y <= ap.Y+as.Y
            pressing = false
            if inF then fn() end
        end)
    end

    onTap(fAL,  function() _doToggle("AutoLeft")   end)
    onTap(fAR,  function() _doToggle("AutoRight")  end)
    onTap(fSP,  function() _doToggle("SpeedBoost") end)
    onTap(fBAT, function() _doToggle("BatAimbot")  end)
    onTap(fTP,  function()
        TweenService:Create(fTP, TweenInfo.new(0.08), {BackgroundColor3=CON}):Play()
        task.spawn(doTPDown)
        task.delay(0.4, function() TweenService:Create(fTP, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(25,8,8)}):Play() end)
    end)
    onTap(fDRP, function()
        TweenService:Create(fDRP, TweenInfo.new(0.08), {BackgroundColor3=CON}):Play()
        task.spawn(doDrop)
        task.delay(0.4, function() TweenService:Create(fDRP, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(25,8,8)}):Play() end)
    end)
end

----------------------------------------------------------------
-- UNIFIED TOGGLE SYSTEM
----------------------------------------------------------------
local function updateToggleBtn(btn, stroke, active)
    TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=active and CON or COFF}):Play()
    btn.Text=active and "ON" or "OFF"
    btn.TextColor3=active and CW or CGRAY
    stroke.Color=active and CGREEN or CGRDIM
    stroke.Thickness=active and 1.5 or 1
end

local function doToggle(name)
    local on=not toggleStates[name]
    toggleStates[name]=on

    if name=="AutoLeft" then
        updateToggleBtn(B["AutoLeft"][1],B["AutoLeft"][2],on) setMobBtn(M.L1,on)
        if on then
            toggleStates.AutoRight=false
            updateToggleBtn(B["AutoRight"][1],B["AutoRight"][2],false) setMobBtn(M.L2,false)
            rightActive=false leftActive=true
            startWaypoints(waypointsLeft,"left",function()
                toggleStates.AutoLeft=false
                updateToggleBtn(B["AutoLeft"][1],B["AutoLeft"][2],false)
                setMobBtn(M.L1,false)
            end)
        else leftActive=false stopWaypoints() end

    elseif name=="AutoRight" then
        updateToggleBtn(B["AutoRight"][1],B["AutoRight"][2],on) setMobBtn(M.L2,on)
        if on then
            toggleStates.AutoLeft=false
            updateToggleBtn(B["AutoLeft"][1],B["AutoLeft"][2],false) setMobBtn(M.L1,false)
            leftActive=false rightActive=true
            startWaypoints(waypointsRight,"right",function()
                toggleStates.AutoRight=false
                updateToggleBtn(B["AutoRight"][1],B["AutoRight"][2],false)
                setMobBtn(M.L2,false)
            end)
        else rightActive=false stopWaypoints() end

    elseif name=="SpeedBoost" then
        updateToggleBtn(B["SpeedBoost"][1],B["SpeedBoost"][2],on) setMobBtn(M.L3,on)
        if on then startSpeedBoost() else stopSpeedBoost() end

    elseif name=="AutoSteal" then
        autoStealEnabled=on
        updateToggleBtn(B["AutoSteal"][1],B["AutoSteal"][2],on)
        if on then
            initAutoStealGUI() startAutoSteal()
        else
            stopAutoSteal()
            if autoStealGui then pcall(function() autoStealGui:Destroy() end) autoStealGui=nil end
        end

    elseif name=="BatAimbot" then
        updateToggleBtn(B["BatAimbot"][1],B["BatAimbot"][2],on) setMobBtn(M.R1,on)
        if on then startBatAimbot() else stopBatAimbot() end

    elseif name=="Galaxy" then
        updateToggleBtn(B["Galaxy"][1],B["Galaxy"][2],on)
        if on then startGalaxy() else stopGalaxy() end

    elseif name=="TPDown" then
        toggleStates[name]=false
        TweenService:Create(B["TPDown"][1],TweenInfo.new(0.08),{BackgroundColor3=CON}):Play()
        task.spawn(function()
            doTPDown()
            task.wait(0.25)
            TweenService:Create(B["TPDown"][1],TweenInfo.new(0.15),{BackgroundColor3=COFF}):Play()
        end)

    elseif name=="PlayerESP" then
        updateToggleBtn(B["PlayerESP"][1],B["PlayerESP"][2],on)
        if on then startPlayerESP() else stopPlayerESP() end

    elseif name=="AntiRagdoll" then
        updateToggleBtn(B["AntiRagdoll"][1],B["AntiRagdoll"][2],on)
        if on then startAntiRagdoll() else stopAntiRagdoll() end

    elseif name=="NoAnimations" then
        updateToggleBtn(B["NoAnimations"][1],B["NoAnimations"][2],on)
        toggleNoAnimations(on)

    elseif name=="XrayBase" then
        updateToggleBtn(B["XrayBase"][1],B["XrayBase"][2],on)
        if on then startXrayBase() else stopXrayBase() end

    elseif name=="Optimizer" then
        updateToggleBtn(B["Optimizer"][1],B["Optimizer"][2],on)
        if on then enableOptimizer() else disableOptimizer() end

    elseif name=="Drop" then
        toggleStates[name]=false
        TweenService:Create(B["Drop"][1],TweenInfo.new(0.08),{BackgroundColor3=CON}):Play()
        task.spawn(function()
            doDrop()
            task.wait(0.25)
            TweenService:Create(B["Drop"][1],TweenInfo.new(0.15),{BackgroundColor3=COFF}):Play()
        end)
    end
end

_doToggle = doToggle

B["AutoLeft"][1].MouseButton1Click:Connect(function()    doToggle("AutoLeft")    end)
B["AutoRight"][1].MouseButton1Click:Connect(function()   doToggle("AutoRight")   end)
B["SpeedBoost"][1].MouseButton1Click:Connect(function()  doToggle("SpeedBoost")  end)
B["AutoSteal"][1].MouseButton1Click:Connect(function()   doToggle("AutoSteal")   end)
B["BatAimbot"][1].MouseButton1Click:Connect(function()   doToggle("BatAimbot")   end)
B["Galaxy"][1].MouseButton1Click:Connect(function()      doToggle("Galaxy")      end)
B["TPDown"][1].MouseButton1Click:Connect(function()      doToggle("TPDown")      end)
B["PlayerESP"][1].MouseButton1Click:Connect(function()   doToggle("PlayerESP")   end)
B["AntiRagdoll"][1].MouseButton1Click:Connect(function() doToggle("AntiRagdoll") end)
B["NoAnimations"][1].MouseButton1Click:Connect(function()doToggle("NoAnimations")end)
B["Drop"][1].MouseButton1Click:Connect(function()        doToggle("Drop")        end)
B["XrayBase"][1].MouseButton1Click:Connect(function()    doToggle("XrayBase")    end)
B["Optimizer"][1].MouseButton1Click:Connect(function()   doToggle("Optimizer")   end)

MobileSupportBtn.MouseButton1Click:Connect(function()
    local on=MobileSupportBtn.BackgroundColor3~=CON
    updateToggleBtn(MobileSupportBtn,mssS,on)
    MobileButtonsGui.Enabled=on
end)

UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if changingKeybind then return end
    if input.KeyCode==Enum.KeyCode.Space then spaceHeld=true return end
    if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    local function kb(name) return Keybinds[name] and input.KeyCode==Keybinds[name] end
    if     kb("AutoLeft")    then doToggle("AutoLeft")
    elseif kb("AutoRight")   then doToggle("AutoRight")
    elseif kb("SpeedBoost")  then doToggle("SpeedBoost")
    elseif kb("AutoSteal")   then doToggle("AutoSteal")
    elseif kb("BatAimbot")   then doToggle("BatAimbot")
    elseif kb("AntiRagdoll") then doToggle("AntiRagdoll")
    elseif kb("NoAnimations")then doToggle("NoAnimations")
    elseif kb("Drop")        then doToggle("Drop")
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.Space then spaceHeld=false end
end)

end -- BLOCK 2

----------------------------------------------------------------
-- OVERHEAD TAG
----------------------------------------------------------------
local function createOverheadTag()
    local char=player.Character or player.CharacterAdded:Wait()
    local head=char:WaitForChild("Head")
    local old=head:FindFirstChild("LightTag") if old then old:Destroy() end
    local billboard=Instance.new("BillboardGui")
    billboard.Name="LightTag"
    billboard.Size=UDim2.new(0,160,0,32)
    billboard.StudsOffset=Vector3.new(0,2.8,0)
    billboard.AlwaysOnTop=false billboard.ResetOnSpawn=false
    billboard.Parent=head
    local bg=Instance.new("Frame",billboard)
    bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(8,8,8)
    bg.BackgroundTransparency=0.15 bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,7)
    local stroke=Instance.new("UIStroke",bg)
    stroke.Thickness=1.8 stroke.Color=CGREEN stroke.Transparency=0.1
    task.spawn(function()
        local t=0 while billboard and billboard.Parent do
            t=t+0.05 local p=math.abs(math.sin(t))
            local r=math.floor(180+p*75)
            stroke.Color=Color3.fromRGB(r,math.floor(p*15),math.floor(p*15))
            stroke.Transparency=0.05+p*0.25
            task.wait(0.03)
        end
    end)
    local pIcon=Instance.new("TextLabel",bg)
    pIcon.Size=UDim2.new(0,24,1,-4) pIcon.Position=UDim2.new(0,4,0,2)
    pIcon.BackgroundColor3=Color3.fromRGB(60,20,20) pIcon.BackgroundTransparency=0.1
    pIcon.Text="L" pIcon.Font=Enum.Font.GothamBlack pIcon.TextSize=15
    pIcon.TextColor3=CW pIcon.TextXAlignment=Enum.TextXAlignment.Center pIcon.BorderSizePixel=0
    Instance.new("UICorner",pIcon).CornerRadius=UDim.new(0,5)
    local div=Instance.new("Frame",bg)
    div.Size=UDim2.new(0,1.5,0.7,0) div.Position=UDim2.new(0,32,0.15,0)
    div.BackgroundColor3=CGREEN div.BackgroundTransparency=0.3 div.BorderSizePixel=0
    local label=Instance.new("TextLabel",bg)
    label.Size=UDim2.new(1,-38,1,0) label.Position=UDim2.new(0,36,0,0)
    label.BackgroundTransparency=1 label.Text="LIGHT HUB"
    label.Font=Enum.Font.GothamBlack label.TextSize=10
    label.TextColor3=CW label.TextXAlignment=Enum.TextXAlignment.Center
    local grad=Instance.new("UIGradient",label)
    grad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,100,100)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,200,200)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(200,60,60))
    })
    task.spawn(function()
        local r=0 while label and label.Parent do r=(r+3)%360 grad.Rotation=r task.wait(0.03) end
    end)
end

createOverheadTag()
player.CharacterAdded:Connect(function() task.wait(0.5) createOverheadTag() end)

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
_ScreenGui.Parent=player:WaitForChild("PlayerGui")
task.spawn(function()
    for i=0,1,0.05 do _MainFrame.BackgroundTransparency=1-i task.wait(0.02) end
end)
task.spawn(function()
    task.wait(0.3)
    local allToggles = {
        "AutoLeft","AutoRight","SpeedBoost","AutoSteal","BatAimbot",
        "Galaxy","AntiRagdoll","NoAnimations","XrayBase",
        "Optimizer","TPDown","PlayerESP",
    }
    for _,k in ipairs(allToggles) do
        if _savedToggles[k]==true then _doToggle(k) end
    end
    if _savedToggles.AutoSteal==nil then _doToggle("AutoSteal") end
    if _savedMobile and MobileButtonsGui then
        MobileButtonsGui.Enabled=true
    end
end)

task.spawn(function()
    while true do task.wait(5) saveConfig() end
end)

print("LIGHT HUB LOADED")
