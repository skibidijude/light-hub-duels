print("[LIGHT HUB] Loading...")
repeat task.wait() until game:IsLoaded()

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local pgui        = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════
-- SPEED / KEY DEFAULTS
-- ══════════════════════════════════════════
local NORMAL_SPEED = 60
local CARRY_SPEED  = 30

local speedToggled       = false
local autoBatToggled       = false
local autoBatKey         = Enum.KeyCode.E
local speedToggleKey     = Enum.KeyCode.Q
local autoLeftKey        = Enum.KeyCode.Z
local autoRightKey       = Enum.KeyCode.C
local autoLeftPlayKey    = Enum.KeyCode.J
local autoRightPlayKey   = Enum.KeyCode.K
local floatKey           = Enum.KeyCode.F
local guiToggleKey       = Enum.KeyCode.RightAlt
local tpDownKey          = Enum.KeyCode.G
local dropKey            = Enum.KeyCode.H

local guiVisible = true

-- ══════════════════════════════════════════
-- WAYPOINTS  (offset-editable, K7 style)
-- ══════════════════════════════════════════
local WP = {
    Left = {
        { label="L1", pos=Vector3.new(-476.48,-6.28, 92.73), offset=Vector3.new(0,0,0) },
        { label="L2", pos=Vector3.new(-483.12,-4.95, 94.80), offset=Vector3.new(0,0,0) },
    },
    Right = {
        { label="R1", pos=Vector3.new(-476.16,-6.52, 25.62), offset=Vector3.new(0,0,0) },
        { label="R2", pos=Vector3.new(-483.04,-5.09, 23.14), offset=Vector3.new(0,0,0) },
    },
    LeftPlay = {
        { label="LP1", pos=Vector3.new(-476.2,-6.5,  94.8), offset=Vector3.new(0,0,0) },
        { label="LP2", pos=Vector3.new(-484.1,-4.7,  94.7), offset=Vector3.new(0,0,0) },
        { label="LP3", pos=Vector3.new(-476.5,-6.1,   7.5), offset=Vector3.new(0,0,0) },
    },
    RightPlay = {
        { label="RP1", pos=Vector3.new(-476.2,-6.1,  25.8), offset=Vector3.new(0,0,0) },
        { label="RP2", pos=Vector3.new(-484.1,-4.7,  25.9), offset=Vector3.new(0,0,0) },
        { label="RP3", pos=Vector3.new(-476.2,-6.2, 113.5), offset=Vector3.new(0,0,0) },
    },
}
local function wpPos(wp) return wp.pos + wp.offset end

-- Keep legacy names working for the rest of the code
local POSITION_L1 = Vector3.new(-476.48, -6.28, 92.73)
local POSITION_L2 = Vector3.new(-483.12, -4.95, 94.80)
local POSITION_R1 = Vector3.new(-476.16, -6.52, 25.62)
local POSITION_R2 = Vector3.new(-483.04, -5.09, 23.14)

local ALP_P1 = Vector3.new(-476.2, -6.5, 94.8)
local ALP_P2 = Vector3.new(-484.1, -4.7, 94.7)
local ALP_P3 = Vector3.new(-476.5, -6.1, 7.5)

local ARP_P1 = Vector3.new(-476.2, -6.1, 25.8)
local ARP_P2 = Vector3.new(-484.1, -4.7, 25.9)
local ARP_P3 = Vector3.new(-476.2, -6.2, 113.5)

-- ══════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════
local Values = {
    STEAL_RADIUS       = 8,
    STEAL_DURATION     = 0.2,
    DEFAULT_GRAVITY    = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER          = 35,
    HOP_COOLDOWN       = 0.08,
}

local Enabled = {
    AntiRagdoll        = false,
    AutoSteal          = false,
    Galaxy             = false,
    Optimizer          = false,
    Unwalk             = false,
    AutoLeftEnabled    = false,
    AutoRightEnabled   = false,
    AutoLeftPlayEnabled  = false,
    AutoRightPlayEnabled = false,
    FloatEnabled       = false,
    NoClip             = false,
    DarkMode           = false,
    MiniGuiEnabled     = false,
    WaypointESP        = false,
    Spinbot            = false,
    RagdollTP          = false,
    BatAimbot          = false,
    CounterMedusa      = false,
    MobileButtonsVisible = true,
    UILocked           = false,
    AutoCarryOnPickup  = false,
}

local Connections  = {}
local StealData    = {}
local VisualSetters = {}

local isStealing     = false
local stealStartTime = false

local AutoLeftEnabled      = false
local AutoRightEnabled     = false
local AutoLeftPlayEnabled  = false
local AutoRightPlayEnabled = false

local autoLeftConnection      = nil
local autoRightConnection     = nil
local autoLeftPlayConnection  = nil
local autoRightPlayConnection = nil
local autoLeftPhase      = 1
local autoRightPhase     = 1
local autoLeftPlayPhase  = 1
local autoRightPlayPhase = 1

local galaxyVectorForce  = nil
local galaxyAttachment   = nil
local galaxyEnabled      = false
local hopsEnabled        = false
local lastHopTime        = 0
local spaceHeld          = false
local originalJumpPower  = 50

local floatEnabled   = false
local floatTargetY   = nil
local floatConn      = nil
local FLOAT_HEIGHT   = 10

local originalTransparency = {}
local xrayEnabled    = false
local savedAnimations = {}
local noClipTracked  = {}

local currentTransparency = 0
local h, hrp, speedLbl    = nil, nil, nil

-- Ragdoll TP state
local tpWasRagdolled   = false
local tpCooldown       = false
local tpStateConn, tpChildConn, tpChildRemConn = nil, nil, nil

-- Steal bar UI refs
local SBFill, SBPct, SBStatus, SBRadBtn, StealBarFrame
local stealBarTimer = 0

local modeLabel    = nil
local autoSaveLabel = nil

-- ══════════════════════════════════════════
-- CHARACTER HELPERS
-- ══════════════════════════════════════════
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ══════════════════════════════════════════
-- STEAL HELPERS
-- ══════════════════════════════════════════
local function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled == true end
    end
    return false
end

local function findNearestPrompt()
    local myHrp = getHRP()
    if not myHrp then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base  = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - myHrp.Position).Magnitude
                    if dist < nd and dist <= Values.STEAL_RADIUS then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd, nn = ch, dist, pod.Name; break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np, nd, nn
end

-- ══════════════════════════════════════════
-- STEAL
-- ══════════════════════════════════════════
local progressConnection = nil

local function ResetProgressBar()
    for _, lbl in ipairs(phantomLetterLabels) do lbl.TextTransparency = 1 end
    if SBPct    then SBPct.Visible = false end
    if SBFill   then SBFill.Size = UDim2.new(0,0,1,0) end
    if SBStatus then SBStatus.Text = "READY" end
end

local function UpdatePhantomLetters(prog)
    local numLetters = 7
    local lettersToShow = math.clamp(math.floor(prog * numLetters + 0.999), 0, numLetters)
    for i, lbl in ipairs(phantomLetterLabels) do lbl.TextTransparency = i <= lettersToShow and 0 or 1 end
    if SBPct then SBPct.Visible = true; SBPct.Text = math.floor(prog*100).."%" end
end

local function cachePromptData(prompt)
    if StealData[prompt] then return StealData[prompt] end
    local data = {hold={}, trigger={}, ready=true}
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(data.hold, c.Function) end end
            for _, c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(data.trigger, c.Function) end end
        end
    end)
    StealData[prompt] = data
    return data
end

local function executeSteal(prompt, name)
    if isStealing then return end
    local data = cachePromptData(prompt)
    if not data.ready then return end
    data.ready = false isStealing = true stealStartTime = tick()
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then if progressConnection then progressConnection:Disconnect() progressConnection = nil end return end
        local prog = math.clamp((tick()-stealStartTime)/Values.STEAL_DURATION, 0, 1)
        UpdatePhantomLetters(prog)
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(pcall, f) end
        task.wait(Values.STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(pcall, f) end
        if progressConnection then progressConnection:Disconnect() progressConnection = nil end
        ResetProgressBar()
        data.ready = true isStealing = false
    end)
end

local lastStealScan = 0
local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local now = tick()
        if now - lastStealScan < 0.05 then return end
        lastStealScan = now
        local p, _, n = findNearestPrompt()
        if p then executeSteal(p, n) end
    end)
end

local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect() Connections.autoSteal = nil end
    isStealing = false
    if progressConnection then progressConnection:Disconnect() progressConnection = nil end
    ResetProgressBar()
end

-- ══════════════════════════════════════════
-- ANTI RAGDOLL
-- ══════════════════════════════════════════
local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local humState = hum:GetState()
            if humState == Enum.HumanoidStateType.Physics or humState == Enum.HumanoidStateType.Ragdoll or humState == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    if LocalPlayer.Character then
                        local PM = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                        if PM then require(PM:FindFirstChild("ControlModule")):Enable() end
                    end
                end)
                if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) root.AssemblyAngularVelocity = Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
        end
    end)
end

local function stopAntiRagdoll()
    if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect(); Connections.antiRagdoll = nil end
end

-- ══════════════════════════════════════════
-- GALAXY
-- ══════════════════════════════════════════
local function captureJumpPower()
    local c = LocalPlayer.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid") if hum and hum.JumpPower > 0 then originalJumpPower = hum.JumpPower end end
end
task.spawn(function() task.wait(1); captureJumpPower() end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(1); captureJumpPower() end)

local function setupGalaxyForce()
    pcall(function()
        local c = LocalPlayer.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment  then galaxyAttachment:Destroy()  end
        galaxyAttachment = Instance.new("Attachment"); galaxyAttachment.Parent = r
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0 = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force = Vector3.new(0,0,0)
        galaxyVectorForce.Parent = r
    end)
end

local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c = LocalPlayer.Character; if not c then return end
    local mass = 0
    for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass = mass + p:GetMass() end end
    local tg = Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent/100)
    galaxyVectorForce.Force = Vector3.new(0, mass*(Values.DEFAULT_GRAVITY-tg)*0.95, 0)
end

local function adjustGalaxyJump()
    pcall(function()
        local c = LocalPlayer.Character; if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if not galaxyEnabled then hum.JumpPower = originalJumpPower; return end
        local ratio = math.sqrt((Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100))/Values.DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower * ratio
    end)
end

local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c = LocalPlayer.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not r or not hum then return end
        if tick() - lastHopTime < Values.HOP_COOLDOWN then return end
        lastHopTime = tick()
        if hum.FloorMaterial == Enum.Material.Air then
            r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, Values.HOP_POWER, r.AssemblyLinearVelocity.Z)
        end
    end)
end

local function startGalaxy() galaxyEnabled=true; hopsEnabled=true; setupGalaxyForce(); adjustGalaxyJump() end
local function stopGalaxy()
    galaxyEnabled=false; hopsEnabled=false
    if galaxyVectorForce then galaxyVectorForce:Destroy(); galaxyVectorForce=nil end
    if galaxyAttachment  then galaxyAttachment:Destroy();  galaxyAttachment=nil  end
    adjustGalaxyJump()
end

RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then doMiniHop() end
    if galaxyEnabled then updateGalaxyForce() end
end)

-- ══════════════════════════════════════════
-- UNWALK / NOCLIP
-- ══════════════════════════════════════════
local function startUnwalk()
    local c = LocalPlayer.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = c:FindFirstChild("Animate")
    if anim then savedAnimations.Animate = anim:Clone(); anim:Destroy() end
end

local function stopUnwalk()
    local c = LocalPlayer.Character
    if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent = c; savedAnimations.Animate = nil end
end

local function startNoClip()
    if Connections.noClip then return end
    Connections.noClip = RunService.Stepped:Connect(function()
        if not Enabled.NoClip then return end
        local playerParts = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                for _, part in ipairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        playerParts[part] = true
                        if part.CanCollide then part.CanCollide = false; noClipTracked[part] = true end
                    end
                end
            end
        end
        for part, _ in pairs(noClipTracked) do
            if not playerParts[part] then pcall(function() part.CanCollide = true end); noClipTracked[part] = nil end
        end
    end)
end

local function stopNoClip()
    if Connections.noClip then Connections.noClip:Disconnect(); Connections.noClip = nil end
    for part, _ in pairs(noClipTracked) do pcall(function() part.CanCollide = true end) end
    noClipTracked = {}
end

-- ══════════════════════════════════════════
-- DROP / TP DOWN
-- ══════════════════════════════════════════
local function doDropBrainrots()
    local r = getHRP(); if not r then return end
    r.AssemblyLinearVelocity = Vector3.new(0, 125, 0)
    task.wait(0.4)
    r.AssemblyLinearVelocity = Vector3.new(0, -600, 0)
end

local function doTPDown()
    local r = getHRP(); if r then r.CFrame = r.CFrame * CFrame.new(0, -20, 0) end
end

-- ══════════════════════════════════════════
-- OPTIMIZER / DARK MODE
-- ══════════════════════════════════════════
local function enableOptimizer()
    if getgenv and getgenv().NEBULA_OPT_ACTIVE then return end
    if getgenv then getgenv().NEBULA_OPT_ACTIVE = true end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false; Lighting.Brightness = 2; Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9
        for _, fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled = false end end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false; obj.Material = Enum.Material.Plastic
                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then child:Destroy() end
                    end
                elseif obj:IsA("Sky") then obj:Destroy() end
            end)
        end
    end)
    xrayEnabled = true
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.88
            end
        end
    end)
end

local function disableOptimizer()
    if getgenv then getgenv().NEBULA_OPT_ACTIVE = false end
    if xrayEnabled then
        for part, value in pairs(originalTransparency) do if part then part.LocalTransparencyModifier = value end end
        originalTransparency = {}; xrayEnabled = false
    end
end

local darkCC = nil
local function enableDarkMode()
    if darkCC and darkCC.Parent then return end
    darkCC = Instance.new("ColorCorrectionEffect")
    darkCC.Name = "NebulaDarkMode"; darkCC.Brightness = -0.25; darkCC.Contrast = 0.1
    darkCC.Saturation = -0.1; darkCC.Enabled = true; darkCC.Parent = Lighting
end
local function disableDarkMode()
    if darkCC then darkCC:Destroy(); darkCC = nil end
end

-- ══════════════════════════════════════════
-- FLOAT
-- ══════════════════════════════════════════
local function updateFloatHeight()
    if not floatEnabled then return end
    local c = LocalPlayer.Character; if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
    floatTargetY = r.Position.Y + FLOAT_HEIGHT
end

local function startFloat()
    local c = LocalPlayer.Character; if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
    floatTargetY = r.Position.Y + FLOAT_HEIGHT; floatEnabled = true
    if floatConn then floatConn:Disconnect() end
    floatConn = RunService.Heartbeat:Connect(function()
        if not floatEnabled then floatConn:Disconnect(); floatConn = nil; return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
        local diff = floatTargetY - root.Position.Y
        if math.abs(diff) > 0.05 then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, diff*12, root.AssemblyLinearVelocity.Z)
        end
    end)
end

local function stopFloat()
    floatEnabled = false; floatTargetY = nil
    if floatConn then floatConn:Disconnect(); floatConn = nil end
    local c = LocalPlayer.Character
    if c then local r = c:FindFirstChild("HumanoidRootPart") if r then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X,-150,r.AssemblyLinearVelocity.Z) end end
end

-- ══════════════════════════════════════════
-- AUTO MOVEMENTS
-- ══════════════════════════════════════════
local function faceSouth()
    if Enabled.Spinbot then return end
    local c = LocalPlayer.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0,0,0)
end
local function faceNorth()
    if Enabled.Spinbot then return end
    local c = LocalPlayer.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0,math.rad(180),0)
end

local function stopAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect(); autoLeftConnection=nil end
    autoLeftPhase=1; AutoLeftEnabled=false; Enabled.AutoLeftEnabled=false
    local c = LocalPlayer.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
    if VisualSetters.AutoLeftEnabled then VisualSetters.AutoLeftEnabled(false, true) end
end

local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection=nil end
    autoRightPhase=1; AutoRightEnabled=false; Enabled.AutoRightEnabled=false
    local c = LocalPlayer.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
    if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false, true) end
end

local function stopAutoLeftPlay()
    if autoLeftPlayConnection then autoLeftPlayConnection:Disconnect(); autoLeftPlayConnection=nil end
    autoLeftPlayPhase=1; AutoLeftPlayEnabled=false; Enabled.AutoLeftPlayEnabled=false
    speedToggled=true; if modeLabel then modeLabel.Text="Mode: Carry" end
    local c = LocalPlayer.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
    if VisualSetters.AutoLeftPlayEnabled then VisualSetters.AutoLeftPlayEnabled(false, true) end
end

local function stopAutoRightPlay()
    if autoRightPlayConnection then autoRightPlayConnection:Disconnect(); autoRightPlayConnection=nil end
    autoRightPlayPhase=1; AutoRightPlayEnabled=false; Enabled.AutoRightPlayEnabled=false
    speedToggled=true; if modeLabel then modeLabel.Text="Mode: Carry" end
    local c = LocalPlayer.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
    if VisualSetters.AutoRightPlayEnabled then VisualSetters.AutoRightPlayEnabled(false, true) end
end

local function startAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect() end
    autoLeftPhase = 1
    autoLeftConnection = RunService.Heartbeat:Connect(function()
        if not AutoLeftEnabled then return end
        local c = LocalPlayer.Character if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local currentSpeed = NORMAL_SPEED
        local T1 = wpPos(WP.Left[1]); local T2 = wpPos(WP.Left[2])
        if autoLeftPhase == 1 then
            local dist = (Vector3.new(T1.X, h.Position.Y, T1.Z) - h.Position).Magnitude
            if dist < 1 then autoLeftPhase = 2 return end
            local dir = Vector3.new((T1-h.Position).X,0,(T1-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity = Vector3.new(dir.X*currentSpeed,h.AssemblyLinearVelocity.Y,dir.Z*currentSpeed)
        elseif autoLeftPhase == 2 then
            local dist = (Vector3.new(T2.X, h.Position.Y, T2.Z) - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero,false) h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                AutoLeftEnabled=false Enabled.AutoLeftEnabled=false
                if autoLeftConnection then autoLeftConnection:Disconnect() autoLeftConnection=nil end
                autoLeftPhase=1
                if VisualSetters.AutoLeftEnabled then VisualSetters.AutoLeftEnabled(false,true) end
                faceSouth() return
            end
            local dir = Vector3.new((T2-h.Position).X,0,(T2-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity = Vector3.new(dir.X*currentSpeed,h.AssemblyLinearVelocity.Y,dir.Z*currentSpeed)
        end
    end)
end

local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end
    autoRightPhase=1
    local arLastPos, arStuckTimer = nil, 0
    autoRightConnection = RunService.Heartbeat:Connect(function(dt)
        if not AutoRightEnabled then return end
        local c = LocalPlayer.Character if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local currentSpeed = NORMAL_SPEED
        local T1 = wpPos(WP.Right[1]); local T2 = wpPos(WP.Right[2])
        local currentPos = h.Position
        if arLastPos then
            if (currentPos-arLastPos).Magnitude < 0.05 then arStuckTimer=arStuckTimer+dt else arStuckTimer=0 end
        end
        arLastPos = currentPos
        if autoRightPhase == 1 then
            local dist = (Vector3.new(T1.X,h.Position.Y,T1.Z)-h.Position).Magnitude
            if dist < 1 then autoRightPhase=2 arStuckTimer=0 return end
            if arStuckTimer > 0.4 then
                arStuckTimer=0
                local sd=(T1-h.Position)
                local ss=Vector3.new(sd.X,0,sd.Z).Unit*math.min(4,sd.Magnitude)
                h.CFrame=CFrame.new(h.Position+ss) h.AssemblyLinearVelocity=Vector3.zero return
            end
            local dir=Vector3.new((T1-h.Position).X,0,(T1-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*currentSpeed,h.AssemblyLinearVelocity.Y,dir.Z*currentSpeed)
        elseif autoRightPhase == 2 then
            local dist=(Vector3.new(T2.X,h.Position.Y,T2.Z)-h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero,false) h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoRightEnabled=false Enabled.AutoRightEnabled=false
                if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection=nil end
                autoRightPhase=1
                if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false,true) end
                faceNorth() return
            end
            if arStuckTimer > 0.4 then
                arStuckTimer=0
                local sd=(T2-h.Position)
                local ss=Vector3.new(sd.X,0,sd.Z).Unit*math.min(4,sd.Magnitude)
                h.CFrame=CFrame.new(h.Position+ss) h.AssemblyLinearVelocity=Vector3.zero return
            end
            local dir=Vector3.new((T2-h.Position).X,0,(T2-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*currentSpeed,h.AssemblyLinearVelocity.Y,dir.Z*currentSpeed)
        end
    end)
end

local function startAutoLeftPlay()
    if autoLeftPlayConnection then autoLeftPlayConnection:Disconnect() end
    autoLeftPlayPhase=1
    autoLeftPlayConnection=RunService.Heartbeat:Connect(function()
        if not AutoLeftPlayEnabled then return end
        local c=LocalPlayer.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart")
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local P1=wpPos(WP.LeftPlay[1]); local P2=wpPos(WP.LeftPlay[2]); local P3=wpPos(WP.LeftPlay[3])
        if autoLeftPlayPhase==1 then
            local dist=(Vector3.new(P1.X,h.Position.Y,P1.Z)-h.Position).Magnitude
            if dist<1.5 then speedToggled=true autoLeftPlayPhase=2 if modeLabel then modeLabel.Text="Mode: Carry" end return end
            local dir=Vector3.new((P1-h.Position).X,0,(P1-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        elseif autoLeftPlayPhase==2 then
            local dist=(Vector3.new(P2.X,h.Position.Y,P2.Z)-h.Position).Magnitude
            if dist<1.5 then autoLeftPlayPhase=3 return end
            local dir=Vector3.new((P2-h.Position).X,0,(P2-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoLeftPlayPhase==3 then
            local dist=(Vector3.new(P1.X,h.Position.Y,P1.Z)-h.Position).Magnitude
            if dist<1.5 then autoLeftPlayPhase=4 return end
            local dir=Vector3.new((P1-h.Position).X,0,(P1-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoLeftPlayPhase==4 then
            local dist=(Vector3.new(P3.X,h.Position.Y,P3.Z)-h.Position).Magnitude
            if dist<1.5 then
                hum:Move(Vector3.zero,false) h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoLeftPlayEnabled=false Enabled.AutoLeftPlayEnabled=false
                if autoLeftPlayConnection then autoLeftPlayConnection:Disconnect() autoLeftPlayConnection=nil end
                autoLeftPlayPhase=1 speedToggled=true
                if modeLabel then modeLabel.Text="Mode: Carry" end
                if VisualSetters.AutoLeftPlayEnabled then VisualSetters.AutoLeftPlayEnabled(false,true) end
                return
            end
            local dir=Vector3.new((P3-h.Position).X,0,(P3-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        end
    end)
end

local function startAutoRightPlay()
    if autoRightPlayConnection then autoRightPlayConnection:Disconnect() end
    autoRightPlayPhase=1
    autoRightPlayConnection=RunService.Heartbeat:Connect(function()
        if not AutoRightPlayEnabled then return end
        local c=LocalPlayer.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart")
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local P1=wpPos(WP.RightPlay[1]); local P2=wpPos(WP.RightPlay[2]); local P3=wpPos(WP.RightPlay[3])
        if autoRightPlayPhase==1 then
            local dist=(Vector3.new(P1.X,h.Position.Y,P1.Z)-h.Position).Magnitude
            if dist<1.5 then speedToggled=true autoRightPlayPhase=2 if modeLabel then modeLabel.Text="Mode: Carry" end return end
            local dir=Vector3.new((P1-h.Position).X,0,(P1-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        elseif autoRightPlayPhase==2 then
            local dist=(Vector3.new(P2.X,h.Position.Y,P2.Z)-h.Position).Magnitude
            if dist<1.5 then autoRightPlayPhase=3 return end
            local dir=Vector3.new((P2-h.Position).X,0,(P2-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoRightPlayPhase==3 then
            local dist=(Vector3.new(P1.X,h.Position.Y,P1.Z)-h.Position).Magnitude
            if dist<1.5 then autoRightPlayPhase=4 return end
            local dir=Vector3.new((P1-h.Position).X,0,(P1-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoRightPlayPhase==4 then
            local dist=(Vector3.new(P3.X,h.Position.Y,P3.Z)-h.Position).Magnitude
            if dist<1.5 then
                hum:Move(Vector3.zero,false) h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoRightPlayEnabled=false Enabled.AutoRightPlayEnabled=false
                if autoRightPlayConnection then autoRightPlayConnection:Disconnect() autoRightPlayConnection=nil end
                autoRightPlayPhase=1 speedToggled=true
                if modeLabel then modeLabel.Text="Mode: Carry" end
                if VisualSetters.AutoRightPlayEnabled then VisualSetters.AutoRightPlayEnabled(false,true) end
                return
            end
            local dir=Vector3.new((P3-h.Position).X,0,(P3-h.Position).Z).Unit
            hum:Move(dir,false) h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        end
    end)
end



-- ══════════════════════════════════════════
-- BAT AIMBOT
-- ══════════════════════════════════════════
local function getBat()
    local char = LocalPlayer.Character; if not char then return nil end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool and tool.Name == "Bat" then return tool end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then local bt = bp:FindFirstChild("Bat"); if bt then return bt end end
    return nil
end

local function findNearestEnemy(myHRP)
    local nearest, nearestDist, nearestTorso = nil, math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eh    = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum   = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist then nearestDist=d; nearest=eh; nearestTorso=torso or eh end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

local function startBatAimbot()
    if Connections.batAimbot then return end
    Connections.batAimbot = RunService.Heartbeat:Connect(function()
        if not Enabled.BatAimbot then return end
        local c = LocalPlayer.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local bat = getBat()
        if not bat then return end -- only run if bat exists, but don't force equip
        local target, dist, torso = findNearestEnemy(h)
        if not target or not torso then return end
        local targetVel = torso.AssemblyLinearVelocity
        local dir = torso.Position - h.Position
        local flatDir = Vector3.new(dir.X, 0, dir.Z)
        local flatDist = flatDir.Magnitude
        local timeToReach = flatDist / 80
        local predictedPos = torso.Position + targetVel * timeToReach
        local spd = 58
        if flatDist > 1 then
            local moveDir = Vector3.new(predictedPos.X-h.Position.X, 0, predictedPos.Z-h.Position.Z).Unit
            local yDiff = torso.Position.Y - h.Position.Y
            local ySpeed = math.abs(yDiff) > 0.5 and math.clamp(yDiff*8, -100, 100) or targetVel.Y
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X*spd, ySpeed, moveDir.Z*spd)
        else
            h.AssemblyLinearVelocity = Vector3.new(targetVel.X, targetVel.Y, targetVel.Z)
        end
    end)
end

local function stopBatAimbot()
    if Connections.batAimbot then Connections.batAimbot:Disconnect(); Connections.batAimbot = nil end
end

-- ══════════════════════════════════════════
-- SPEED HEARTBEAT
-- ══════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not (h and hrp) then return end
    if not h.Parent then return end
    if not (AutoLeftEnabled or AutoRightEnabled or AutoLeftPlayEnabled or AutoRightPlayEnabled) then
        local md = h.MoveDirection
        local speed = speedToggled and CARRY_SPEED or NORMAL_SPEED
        if md.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = Vector3.new(md.X*speed, hrp.AssemblyLinearVelocity.Y, md.Z*speed)
        end
    end
    if speedLbl then
        local v = hrp.AssemblyLinearVelocity
        local spd = math.floor(Vector3.new(v.X,0,v.Z).Magnitude)
        local mode = speedToggled and "CARRY" or "NORMAL"
        speedLbl.Text = spd .. " — " .. mode
    end
end)

-- ══════════════════════════════════════════
-- CONFIG SAVE / LOAD
-- ══════════════════════════════════════════
local function saveConfig()
    local cfg = {
        normalSpeed=NORMAL_SPEED, carrySpeed=CARRY_SPEED,
        autoBatKey=autoBatKey.Name, speedToggleKey=speedToggleKey.Name,
        autoLeftKey=autoLeftKey.Name, autoRightKey=autoRightKey.Name,
        autoLeftPlayKey=autoLeftPlayKey.Name, autoRightPlayKey=autoRightPlayKey.Name,
        floatKey=floatKey.Name, guiToggleKey=guiToggleKey.Name,
        tpDownKey=tpDownKey.Name, dropKey=dropKey.Name,
        autoSteal=Enabled.AutoSteal, stealRadius=Values.STEAL_RADIUS, stealDuration=Values.STEAL_DURATION,
        antiRagdoll=Enabled.AntiRagdoll, galaxy=Enabled.Galaxy,
        galaxyGravity=Values.GalaxyGravityPercent, hopPower=Values.HOP_POWER,
        optimizer=Enabled.Optimizer, unwalk=Enabled.Unwalk, noClip=Enabled.NoClip,
        darkMode=Enabled.DarkMode, floatHeight=FLOAT_HEIGHT,
        uiTransparency=currentTransparency, miniGuiEnabled=Enabled.MiniGuiEnabled,
        batAimbot=Enabled.BatAimbot,
    }
    local ok = false
    if writefile then pcall(function() writefile("NebulaHubConfig.json", HttpService:JSONEncode(cfg)); ok=true end) end
    return ok
end

local function loadConfig()
    if not isfile or not readfile then return end
    local ex; pcall(function() ex = isfile("NebulaHubConfig.json") end); if not ex then return end
    local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile("NebulaHubConfig.json")) end)
    if not ok or not cfg then return end
    if cfg.normalSpeed and cfg.normalSpeed >= 10 and cfg.normalSpeed <= 300 then NORMAL_SPEED = cfg.normalSpeed end
    if cfg.carrySpeed  and cfg.carrySpeed  >= 10 and cfg.carrySpeed  <= 300 then CARRY_SPEED  = cfg.carrySpeed  end
    if cfg.speedToggleKey     and Enum.KeyCode[cfg.speedToggleKey]     then speedToggleKey     = Enum.KeyCode[cfg.speedToggleKey]     end
    if cfg.autoLeftKey        and Enum.KeyCode[cfg.autoLeftKey]        then autoLeftKey        = Enum.KeyCode[cfg.autoLeftKey]        end
    if cfg.autoRightKey       and Enum.KeyCode[cfg.autoRightKey]       then autoRightKey       = Enum.KeyCode[cfg.autoRightKey]       end
    if cfg.autoLeftPlayKey    and Enum.KeyCode[cfg.autoLeftPlayKey]    then autoLeftPlayKey    = Enum.KeyCode[cfg.autoLeftPlayKey]    end
    if cfg.autoRightPlayKey   and Enum.KeyCode[cfg.autoRightPlayKey]   then autoRightPlayKey   = Enum.KeyCode[cfg.autoRightPlayKey]   end
    if cfg.floatKey           and Enum.KeyCode[cfg.floatKey]           then floatKey           = Enum.KeyCode[cfg.floatKey]           end
    if cfg.guiToggleKey       and Enum.KeyCode[cfg.guiToggleKey]       then guiToggleKey       = Enum.KeyCode[cfg.guiToggleKey]       end
    if cfg.tpDownKey          and Enum.KeyCode[cfg.tpDownKey]          then tpDownKey          = Enum.KeyCode[cfg.tpDownKey]          end
    if cfg.dropKey            and Enum.KeyCode[cfg.dropKey]            then dropKey            = Enum.KeyCode[cfg.dropKey]            end
    if cfg.stealRadius        then Values.STEAL_RADIUS = cfg.stealRadius       end
    if cfg.stealDuration      then Values.STEAL_DURATION = cfg.stealDuration   end
    if cfg.galaxyGravity      then Values.GalaxyGravityPercent = cfg.galaxyGravity end
    if cfg.hopPower           then Values.HOP_POWER = cfg.hopPower             end
    if cfg.floatHeight        then FLOAT_HEIGHT = math.clamp(cfg.floatHeight, 1, 20) end
    if cfg.uiTransparency     then currentTransparency = math.clamp(cfg.uiTransparency, 0, 1) end
    if cfg.antiRagdoll ~= nil then Enabled.AntiRagdoll = cfg.antiRagdoll end
    if cfg.autoSteal   ~= nil then Enabled.AutoSteal   = cfg.autoSteal   end
    if cfg.galaxy      ~= nil then Enabled.Galaxy      = cfg.galaxy      end
    if cfg.optimizer   ~= nil then Enabled.Optimizer   = cfg.optimizer   end
    if cfg.unwalk      ~= nil then Enabled.Unwalk      = cfg.unwalk      end
    if cfg.noClip      ~= nil then Enabled.NoClip      = cfg.noClip      end
    if cfg.darkMode    ~= nil then Enabled.DarkMode    = cfg.darkMode    end
    if cfg.miniGuiEnabled ~= nil then Enabled.MiniGuiEnabled = cfg.miniGuiEnabled end
    if cfg.autoBatKey  and Enum.KeyCode[cfg.autoBatKey]  then autoBatKey  = Enum.KeyCode[cfg.autoBatKey]  end
    if cfg.batAimbot ~= nil then Enabled.BatAimbot = cfg.batAimbot end
end

loadConfig()


-- ══════════════════════════════════════════
-- COUNTER MEDUSA  (Eppilson source, faster cooldowns)
-- ══════════════════════════════════════════
local medusaNames = { ["medusa's head"]=true, ["medusa"]=true }
local medusaCounterConn    = nil
local medusaToolConns      = {}
local medusaPlayerConns    = {}
local lastMedusaUse        = 0
local lastBoogieUse        = 0

local function isMedusaToolName(name)
    if not name then return false end
    local lower = name:lower()
    if medusaNames[lower] then return true end
    return lower:find("medusa") ~= nil
end

local function isBoogieName(name)
    if not name then return false end
    return name:lower():find("boogie") ~= nil
end

local function safeDiscMedusa(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() conn:Disconnect() end)
    end
end

local function getMedusaTool()
    local char = LocalPlayer.Character
    if char then
        for _, i in ipairs(char:GetChildren()) do
            if i:IsA("Tool") and isMedusaToolName(i.Name) then return i end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, i in ipairs(bp:GetChildren()) do
            if i:IsA("Tool") and isMedusaToolName(i.Name) then return i end
        end
    end
end

local function getBoogieTool()
    local char = LocalPlayer.Character
    if char then
        for _, i in ipairs(char:GetChildren()) do
            if i:IsA("Tool") and isBoogieName(i.Name) then return i end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, i in ipairs(bp:GetChildren()) do
            if i:IsA("Tool") and isBoogieName(i.Name) then return i end
        end
    end
end

local function enemyHasMedusa(character)
    if not character then return false end
    for _, i in ipairs(character:GetChildren()) do
        if i:IsA("Tool") and isMedusaToolName(i.Name) then return true end
    end
    return false
end

local function activateMedusa(tool)
    if not tool then return end
    local now = workspace:GetServerTimeNow()
    if now - lastMedusaUse <= 0.3 then return end  -- faster: was 1.5s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if tool.Parent ~= LocalPlayer.Character then pcall(function() hum:EquipTool(tool) end) end
    pcall(function() if type(tool.Activate) == "function" then tool:Activate() end end)
    lastMedusaUse = now
    task.delay(0.1, function()  -- faster: was 0.35s
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h:UnequipTools() end) end
    end)
end

local function activateBoogie(tool)
    if not tool then return end
    local now = workspace:GetServerTimeNow()
    if now - lastBoogieUse <= 0.3 then return end  -- faster: was 1.5s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if tool.Parent ~= LocalPlayer.Character then pcall(function() hum:EquipTool(tool) end) end
    pcall(function() if type(tool.Activate) == "function" then tool:Activate() end end)
    lastBoogieUse = now
    task.delay(0.1, function()  -- faster: was 0.35s
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h:UnequipTools() end) end
    end)
end

local function useCounterTool()
    local now = workspace:GetServerTimeNow()
    if now - lastMedusaUse > 0.3 then
        local t = getMedusaTool()
        if t then activateMedusa(t); return true end
    end
    if now - lastBoogieUse > 0.3 then
        local t = getBoogieTool()
        if t then activateBoogie(t); return true end
    end
    return false
end

local function unbindMedusaTool(tool)
    if medusaToolConns[tool] then
       ... (116 KB left)
