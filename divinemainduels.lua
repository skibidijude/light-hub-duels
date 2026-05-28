repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

-- ===================== STATE =====================
local NS, CS, LS = 60, 30, 12.8
local MEDUSA_COOLDOWN = 25
local STEAL_COOLDOWN = 0.2

local speedMode = false
local laggerMode = false
local antiRagdollEnabled = false
local infJumpEnabled = false
local medusaCounterEnabled = false
local unwalkEnabled = false
local floatEnabled = false
local floatHeight = 9.5
local floatJumping = false
local medusaDebounce = false
local medusaLastUsed = 0
local stretchRezEnabled = false
local autoBatEnabled = false      -- Lock aimbot
local autoLeftEnabled = false     -- Play L (2-step)
local autoRightEnabled = false    -- Play R (2-step)
local fullAutoLeftEnabled = false
local fullAutoRightEnabled = false
local _anyKeyListening = false
local guiLocked = false
local introEnabled = true
local mobileDraggingEnabled = false
local antiBatEnabled = false
local dropEnabled = false
local autoTPEnabled = false
local autoTPHeight = 20
local spamBatEnabled = false
local spamBatRange = 30
local tryhardEnabled = false
local darkModeEnabled = false

-- Drop fling
local dropConns = {}
local function toggleDrop(state)
    dropEnabled = state
    if dropEnabled then
        local colConn = RunService.Stepped:Connect(function()
            if not dropEnabled then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end
        end)
        table.insert(dropConns, colConn)
        task.spawn(function()
            while dropEnabled do
                RunService.Heartbeat:Wait()
                local c = LP.Character
                local root = c and c:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local vel = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                if root and root.Parent then root.AssemblyLinearVelocity = vel end
                RunService.Stepped:Wait()
                if root and root.Parent then root.AssemblyLinearVelocity = vel + Vector3.new(0, 0.1, 0) end
            end
        end)
    else
        for _, c in ipairs(dropConns) do
            if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        end
        dropConns = {}
    end
end

-- Anti Bat
local antiBatConn = nil
local function startAntiBat()
    if antiBatConn then return end
    antiBatConn = RunService.RenderStepped:Connect(function()
        if not antiBatEnabled then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            root.AssemblyLinearVelocity = Vector3.new(dir.X * 50, root.AssemblyLinearVelocity.Y, dir.Z * 50)
        end
    end)
end
local function stopAntiBat()
    if antiBatConn then antiBatConn:Disconnect(); antiBatConn = nil end
end

-- Auto TP
local autoTPConn = nil
local function startAutoTP()
    if autoTPConn then return end
    autoTPConn = RunService.Heartbeat:Connect(function()
        if not autoTPEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y >= autoTPHeight then
            hrp.CFrame = CFrame.new(hrp.Position.X, -8.80, hrp.Position.Z)
        end
    end)
end
local function stopAutoTP()
    if autoTPConn then autoTPConn:Disconnect(); autoTPConn = nil end
end

-- Spam Bat
local spamBatConn = nil
local lastBatSwing = 0
local BAT_SWING_COOLDOWN = 0.12
local SlapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

local function findBat()
    local char = LP.Character; if not char then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, name in ipairs(SlapList) do
        local t = char:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    return nil
end

local function getClosestEnemyDistance()
    local char = LP.Character
    if not char then return math.huge end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return math.huge end
    local minDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (root.Position - hrp.Position).Magnitude
                if d < minDist then minDist = d end
            end
        end
    end
    return minDist
end

local function startSpamBat()
    if spamBatConn then return end
    spamBatConn = RunService.Heartbeat:Connect(function()
        if not spamBatEnabled then return end
        local dist = getClosestEnemyDistance()
        if dist <= spamBatRange then
            local bat = findBat()
            if bat then
                if tick() - lastBatSwing >= BAT_SWING_COOLDOWN then
                    lastBatSwing = tick()
                    pcall(function() bat:Activate() end)
                end
            end
        end
    end)
end
local function stopSpamBat()
    if spamBatConn then spamBatConn:Disconnect(); spamBatConn = nil end
end

-- Tryhard Animation
local tryhardHeartbeat = nil
local originalAnims = {}
local TryhardAnims = {
    idle1 = "rbxassetid://133806214992291",
    idle2 = "rbxassetid://94970088341563",
    walk = "rbxassetid://707897309",
    run = "rbxassetid://707861613",
    jump = "rbxassetid://116936326516985",
    fall = "rbxassetid://116936326516985",
    climb = "rbxassetid://116936326516985",
    swim = "rbxassetid://116936326516985",
    swimidle = "rbxassetid://116936326516985",
}
local function saveOriginalAnims(char)
    local animate = char:FindFirstChild("Animate"); if not animate then return end
    local function g(obj) return obj and obj.AnimationId or nil end
    originalAnims = {
        idle1 = g(animate.idle and animate.idle.Animation1),
        idle2 = g(animate.idle and animate.idle.Animation2),
        walk = g(animate.walk and animate.walk.WalkAnim),
        run = g(animate.run and animate.run.RunAnim),
        jump = g(animate.jump and animate.jump.JumpAnim),
        fall = g(animate.fall and animate.fall.FallAnim),
        climb = g(animate.climb and animate.climb.ClimbAnim),
        swim = g(animate.swim and animate.swim.Swim),
        swimidle = g(animate.swimidle and animate.swimidle.SwimIdle),
    }
end
local function applyTryhardPack(char)
    local animate = char:FindFirstChild("Animate"); if not animate then return end
    local function s(obj, id) if obj then obj.AnimationId = id end end
    s(animate.idle and animate.idle.Animation1, TryhardAnims.idle1)
    s(animate.idle and animate.idle.Animation2, TryhardAnims.idle2)
    s(animate.walk and animate.walk.WalkAnim, TryhardAnims.walk)
    s(animate.run and animate.run.RunAnim, TryhardAnims.run)
    s(animate.jump and animate.jump.JumpAnim, TryhardAnims.jump)
    s(animate.fall and animate.fall.FallAnim, TryhardAnims.fall)
    s(animate.climb and animate.climb.ClimbAnim, TryhardAnims.climb)
    s(animate.swim and animate.swim.Swim, TryhardAnims.swim)
    s(animate.swimidle and animate.swimidle.SwimIdle, TryhardAnims.swimidle)
end
local function restoreOriginalAnims(char)
    if not originalAnims then return end
    local animate = char:FindFirstChild("Animate"); if not animate then return end
    local function s(obj, id) if obj and id then obj.AnimationId = id end end
    s(animate.idle and animate.idle.Animation1, originalAnims.idle1)
    s(animate.idle and animate.idle.Animation2, originalAnims.idle2)
    s(animate.walk and animate.walk.WalkAnim, originalAnims.walk)
    s(animate.run and animate.run.RunAnim, originalAnims.run)
    s(animate.jump and animate.jump.JumpAnim, originalAnims.jump)
    s(animate.fall and animate.fall.FallAnim, originalAnims.fall)
    s(animate.climb and animate.climb.ClimbAnim, originalAnims.climb)
    s(animate.swim and animate.swim.Swim, originalAnims.swim)
    s(animate.swimidle and animate.swimidle.SwimIdle, originalAnims.swimidle)
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if hum2 then for _, t in ipairs(hum2:GetPlayingAnimationTracks()) do t:Stop(0) end end
end
local function startTryhardAnim()
    if tryhardHeartbeat then tryhardHeartbeat:Disconnect() end
    local char = LP.Character
    if char then
        saveOriginalAnims(char)
        applyTryhardPack(char)
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if hum2 then for _, t in ipairs(hum2:GetPlayingAnimationTracks()) do t:Stop(0) end end
    end
    tryhardHeartbeat = RunService.Heartbeat:Connect(function()
        if not tryhardEnabled then return end
        local c = LP.Character
        if c then applyTryhardPack(c) end
    end)
end
local function stopTryhardAnim()
    if tryhardHeartbeat then tryhardHeartbeat:Disconnect(); tryhardHeartbeat = nil end
    local char = LP.Character
    if char then restoreOriginalAnims(char) end
end

-- Keybinds
local KB = {
    DropBrainrot = {kb=Enum.KeyCode.X, gp=nil},
    AutoLeft = {kb=Enum.KeyCode.Z, gp=nil},
    AutoRight = {kb=Enum.KeyCode.C, gp=nil},
    AutoBat = {kb=Enum.KeyCode.E, gp=nil},
    LaggerMode = {kb=Enum.KeyCode.R, gp=nil},
    GuiHide = {kb=Enum.KeyCode.LeftControl, gp=nil},
    Float = {kb=Enum.KeyCode.J, gp=nil},
    SpeedToggle = {kb=Enum.KeyCode.Q, gp=nil},
    TPDown = {kb=Enum.KeyCode.F, gp=nil},
}
local function kbMatch(e,kc) return kc==e.kb or (e.gp and kc==e.gp) end

-- Steal system
local Steal = {AutoStealEnabled=false, StealRadius=20, StealDuration=0.25}
local isStealing = false
local stealLoopRunning = false
local stealLoopThread = nil
local progressFill, progressPct, progressRadLbl
local ConnsProgress = nil

local function resetProgressBar()
    if progressPct then progressPct.Text="0%" end
    if progressFill then progressFill.Size=UDim2.new(0,0,1,0) end
end

local function getCharacter() return LP.Character or LP.CharacterAdded:Wait() end
local function getHRP()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function getPromptPart(prompt)
    local parent = prompt.Parent
    if parent:IsA("BasePart") then return parent end
    if parent:IsA("Model") then return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart") end
    if parent:IsA("Attachment") then return parent.Parent end
    return parent:FindFirstChildWhichIsA("BasePart", true)
end

local function findNearestStealPrompt(hrp)
    local nearestPrompt = nil
    local minDist = math.huge
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, desc in pairs(plots:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText == "Steal" then
            local part = getPromptPart(desc)
            if part then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist <= Steal.StealRadius and dist < minDist then
                    minDist = dist
                    nearestPrompt = desc
                end
            end
        end
    end
    return nearestPrompt
end

local function triggerPromptWithProgress(prompt)
    if not prompt or not prompt:IsDescendantOf(workspace) then return end
    prompt.MaxActivationDistance = 9e9
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true

    isStealing = true
    local startTime = tick()
    if ConnsProgress then ConnsProgress:Disconnect() end
    ConnsProgress = RunService.Heartbeat:Connect(function()
        local prog = math.clamp((tick() - startTime) / Steal.StealDuration, 0, 1)
        if progressFill then progressFill.Size = UDim2.new(prog, 0, 1, 0) end
        if progressPct then progressPct.Text = math.floor(prog * 100) .. "%" end
    end)

    local usedFire = pcall(function() fireproximityprompt(prompt, 9e9, Steal.StealDuration) end)
    if not usedFire then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(Steal.StealDuration)
            prompt:InputHoldEnd()
        end)
    end
    task.wait(Steal.StealDuration * 0.3)
    if ConnsProgress then ConnsProgress:Disconnect(); ConnsProgress = nil end
    resetProgressBar()
    isStealing = false
end

local function stealLoop()
    while stealLoopRunning do
        local hrp = getHRP()
        if hrp then
            local prompt = findNearestStealPrompt(hrp)
            if prompt then triggerPromptWithProgress(prompt) end
        else
            LP.CharacterAdded:Wait()
        end
        task.wait(STEAL_COOLDOWN)
    end
end

local function startAutoSteal()
    if stealLoopRunning then return end
    stealLoopRunning = true
    stealLoopThread = task.spawn(stealLoop)
end

local function stopAutoSteal()
    stealLoopRunning = false
    if stealLoopThread then task.cancel(stealLoopThread); stealLoopThread = nil end
    if isStealing then
        isStealing = false
        if ConnsProgress then ConnsProgress:Disconnect(); ConnsProgress = nil end
        resetProgressBar()
    end
end

-- Aimbot (Lock)
local bypassPart, bypassWeld, aimbotConn = nil, nil, nil
local function cleanupBypass()
    if bypassPart then bypassPart:Destroy(); bypassPart = nil end
    if bypassWeld then bypassWeld:Destroy(); bypassWeld = nil end
end
local function createProxy()
    cleanupBypass()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    bypassPart = Instance.new("Part")
    bypassPart.Name = "AimbotProxy"
    bypassPart.Size = Vector3.new(1,1,1)
    bypassPart.Transparency = 1
    bypassPart.CanCollide = false
    bypassPart.Massless = true
    bypassPart.Parent = char
    bypassWeld = Instance.new("Weld")
    bypassWeld.Part0 = hrp
    bypassWeld.Part1 = bypassPart
    bypassWeld.C0 = CFrame.new(0,0,0)
    bypassWeld.Parent = bypassPart
end

local function getClosestEnemy(rootPos)
    local target, dist, part = nil, math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local d = (tRoot.Position - rootPos).Magnitude
                if d < dist then
                    dist = d
                    target = tRoot
                    part = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso") or tRoot
                end
            end
        end
    end
    return target, dist, part
end

local function findBatAimbot()
    local char = LP.Character; if not char then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _, name in ipairs(SlapList) do
        local t = char:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    for _, ch in ipairs(char:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    return nil
end

local lastSwing = 0
local function trySwing()
    if tick() - lastSwing < 0.12 then return end
    lastSwing = tick()
    local bat = findBatAimbot()
    if bat then pcall(function() bat:Activate() end) end
end

local function startAimbot()
    if aimbotConn then return end
    aimbotConn = RunService.Heartbeat:Connect(function()
        if not autoBatEnabled then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        local tRoot, d, tPart = getClosestEnemy(root.Position)
        if tRoot and tPart then
            hum.AutoRotate = false
            local targetDir = Vector3.new(tPart.Position.X - root.Position.X, 0, tPart.Position.Z - root.Position.Z)
            if targetDir.Magnitude > 0.1 then
                targetDir = targetDir.Unit
                local currentDir = root.CFrame.LookVector
                local currentDirFlat = Vector3.new(currentDir.X, 0, currentDir.Z)
                if currentDirFlat.Magnitude > 0.1 then
                    currentDirFlat = currentDirFlat.Unit
                    local crossY = currentDirFlat:Cross(targetDir).Y
                    local dot = math.clamp(currentDirFlat:Dot(targetDir), -1, 1)
                    local angle = math.atan2(crossY, dot)
                    root.AssemblyAngularVelocity = Vector3.new(0, angle * 25, 0)
                end
            end
            if not bypassPart or bypassPart.Parent ~= char then createProxy() end
            local moveSpd = speedMode and CS or NS
            local moveDir = (tPart.Position - root.Position).Unit
            if d > 2 then
                bypassPart.AssemblyLinearVelocity = moveDir * moveSpd
            else
                bypassPart.AssemblyLinearVelocity = tRoot.AssemblyLinearVelocity
            end
            trySwing()
        else
            hum.AutoRotate = true
        end
    end)
end
local function stopAimbot()
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    local char = LP.Character
    if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.AutoRotate = true end end
    cleanupBypass()
end

-- TP Down
local function runTPDown()
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {char}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local rr = workspace:Raycast(hrp.Position, Vector3.new(0, -2000, 0), rp)
    if rr then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local off = (hum and hum.HipHeight or 2) + (hrp.Size.Y/2)
        hrp.CFrame = CFrame.new(rr.Position.X, rr.Position.Y + off, rr.Position.Z)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

-- Anti Ragdoll
local antiRagConn = nil
local function startAntiRagdoll()
    if antiRagConn then return end
    antiRagConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollEnabled then return end
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local st = hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                if root then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end
        end
    end)
end
local function stopAntiRagdoll()
    if antiRagConn then antiRagConn:Disconnect(); antiRagConn = nil end
end

-- Infinite Jump (handled in heartbeat)
local function startInfiniteJump() end
local function stopInfiniteJump() end

-- Unwalk
local unwalkAnimations = {}
local function disableAnimations()
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    for _, track in pairs(unwalkAnimations) do pcall(function() track:Stop() end) end
    unwalkAnimations = {}
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(); table.insert(unwalkAnimations, track)
        end
    end
end
local function startUnwalk()
    if unwalkEnabled then
        disableAnimations()
        RunService.Heartbeat:Connect(function()
            if unwalkEnabled then disableAnimations() end
        end)
    end
end
local function stopUnwalk() end

-- Stretch Rez
local stretchConn = nil
local function enableStretchRez()
    stretchRezEnabled = true
    workspace.CurrentCamera.FieldOfView = 120
    if stretchConn then stretchConn:Disconnect() end
    stretchConn = RunService.RenderStepped:Connect(function()
        if stretchRezEnabled then workspace.CurrentCamera.FieldOfView = 120 end
    end)
end
local function disableStretchRez()
    stretchRezEnabled = false
    if stretchConn then stretchConn:Disconnect(); stretchConn = nil end
    workspace.CurrentCamera.FieldOfView = 70
end

-- Medusa Counter
local medusaConns = {}
local function findMedusa()
    local char = LP.Character; if not char then return nil end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") and (t.Name:lower():find("medusa") or t.Name:lower():find("head") or t.Name:lower():find("stone")) then
            return t
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t.Name:lower():find("medusa") or t.Name:lower():find("head") or t.Name:lower():find("stone")) then
                return t
            end
        end
    end
end
local function useMedusa()
    if medusaDebounce or tick() - medusaLastUsed < MEDUSA_COOLDOWN then return end
    local char = LP.Character; if not char then return end
    medusaDebounce = true
    local med = findMedusa()
    if med then
        if med.Parent ~= char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h:EquipTool(med) end
        end
        pcall(function() med:Activate() end)
        medusaLastUsed = tick()
    end
    medusaDebounce = false
end
local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 and medusaCounterEnabled then
            useMedusa()
        end
    end)
end
local function setupMedusa(char)
    for _, c in pairs(medusaConns) do pcall(function() c:Disconnect() end) end
    medusaConns = {}
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(medusaConns, onAnchorChanged(part)) end
    end
    table.insert(medusaConns, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then table.insert(medusaConns, onAnchorChanged(part)) end
    end))
end
local function stopMedusaCounter()
    for _, c in pairs(medusaConns) do pcall(function() c:Disconnect() end) end
    medusaConns = {}
end

-- FPS Boost
local function applyFPSBoost()
    pcall(function() setfpscap(999) end)
    for _, v in pairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("BasePart") then v.Material = Enum.Material.Plastic; v.CastShadow = false; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") then v.Enabled = false
            end
        end)
    end
    Lighting.GlobalShadows = false
    Lighting.Brightness = 0
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
end
local function enableFPSBoost() task.spawn(applyFPSBoost) end
local function disableFPSBoost() end

-- Dark Mode
local savedBrightness, savedClockTime, savedOutdoorAmbient, savedExposureComp
local function applyDarkMode(enabled)
    if enabled then
        savedBrightness = Lighting.Brightness
        savedClockTime = Lighting.ClockTime
        savedOutdoorAmbient = Lighting.OutdoorAmbient
        savedExposureComp = Lighting.ExposureCompensation
        Lighting.Brightness = 0
        Lighting.ClockTime = 0
        Lighting.ExposureCompensation = -2
        Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
        local sky = Lighting:FindFirstChild("DivineDarkSky")
        if not sky then
            sky = Instance.new("Sky")
            sky.Name = "DivineDarkSky"
            sky.SkyboxBk = "rbxassetid://159454299"
            sky.SkyboxDn = "rbxassetid://159454296"
            sky.SkyboxFt = "rbxassetid://159454293"
            sky.SkyboxLf = "rbxassetid://159454286"
            sky.SkyboxRt = "rbxassetid://159454289"
            sky.SkyboxUp = "rbxassetid://159454291"
            sky.Parent = Lighting
        else
            sky.Enabled = true
        end
    else
        if savedBrightness then Lighting.Brightness = savedBrightness end
        if savedClockTime then Lighting.ClockTime = savedClockTime end
        if savedExposureComp then Lighting.ExposureCompensation = savedExposureComp end
        if savedOutdoorAmbient then Lighting.OutdoorAmbient = savedOutdoorAmbient end
        local sky = Lighting:FindFirstChild("DivineDarkSky")
        if sky then sky:Destroy() end
    end
end

-- Waypoints
local AP_L1 = Vector3.new(-476.48,-6.28,92.73)
local AP_L2 = Vector3.new(-483.12,-4.95,94.80)
local AP_L_FACE = Vector3.new(-482.25,-4.96,92.09)
local AP_R1 = Vector3.new(-476.16,-6.52,25.62)
local AP_R2 = Vector3.new(-483.06,-5.03,25.48)
local AP_R_FACE = Vector3.new(-482.06,-6.93,35.47)

local FAP_L1 = Vector3.new(-476.48,-6.28,92.73)
local FAP_L2 = Vector3.new(-482.85,-5.03,93.13)
local FAP_L3 = Vector3.new(-475.68,-6.89,92.76)
local FAP_L4 = Vector3.new(-476.50,-6.46,27.58)
local FAP_L5 = Vector3.new(-482.42,-5.03,27.84)
local FAP_R1 = Vector3.new(-476.16,-6.52,25.62)
local FAP_R2 = Vector3.new(-483.06,-5.03,27.51)
local FAP_R3 = Vector3.new(-476.21,-6.63,27.46)
local FAP_R4 = Vector3.new(-476.66,-6.39,92.44)
local FAP_R5 = Vector3.new(-481.94,-5.03,92.42)
local FACE_FAP_L = Vector3.new(-482.25,-4.96,92.09)
local FACE_FAP_R = Vector3.new(-482.06,-6.93,35.47)

-- Play L/R (2-step)
local alConn, arConn = nil, nil
local alPhase, arPhase = 1,1

local function stopPlayLeft()
    if alConn then alConn:Disconnect(); alConn=nil end; alPhase=1
    local char=LP.Character; if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
end
local function startPlayLeft()
    if alConn then alConn:Disconnect() end; alPhase=1
    alConn = RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then return end
        local char=LP.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local spd = speedMode and CS or NS
        if alPhase==1 then
            if (Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)-hrp.Position).Magnitude < 1 then
                alPhase=2
                local d=AP_L2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false)
                hrp.AssemblyLinearVelocity = Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=AP_L1-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif alPhase==2 then
            if (Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)-hrp.Position).Magnitude < 1 then
                hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero
                autoLeftEnabled=false
                if alConn then alConn:Disconnect(); alConn=nil end; alPhase=1
                if autoLeftSetVisual then autoLeftSetVisual(false) end
                if (AP_L_FACE - hrp.Position).Magnitude > 0.01 then
                    hrp.CFrame = CFrame.new(hrp.Position, AP_L_FACE)
                end
                return
            end
            local d=AP_L2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

local function stopPlayRight()
    if arConn then arConn:Disconnect(); arConn=nil end; arPhase=1
    local char=LP.Character; if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
end
local function startPlayRight()
    if arConn then arConn:Disconnect() end; arPhase=1
    arConn = RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then return end
        local char=LP.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local spd = speedMode and CS or NS
        if arPhase==1 then
            if (Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)-hrp.Position).Magnitude < 1 then
                arPhase=2
                local d=AP_R2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false)
                hrp.AssemblyLinearVelocity = Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
                return
            end
            local d=AP_R1-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif arPhase==2 then
            if (Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)-hrp.Position).Magnitude < 1 then
                hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero
                autoRightEnabled=false
                if arConn then arConn:Disconnect(); arConn=nil end; arPhase=1
                if autoRightSetVisual then autoRightSetVisual(false) end
                if (AP_R_FACE - hrp.Position).Magnitude > 0.01 then
                    hrp.CFrame = CFrame.new(hrp.Position, AP_R_FACE)
                end
                return
            end
            local d=AP_R2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

-- Full Auto K7
local fullAutoLeftConn, fullAutoRightConn = nil, nil
local leftPhase, rightPhase = 1,1
local function stopFullAutoLeft()
    if fullAutoLeftConn then fullAutoLeftConn:Disconnect(); fullAutoLeftConn=nil end
    leftPhase=1
    local char=LP.Character; if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
end
local function startFullAutoLeft()
    stopFullAutoLeft()
    leftPhase=1
    fullAutoLeftConn = RunService.Heartbeat:Connect(function()
        if not fullAutoLeftEnabled then return end
        local char=LP.Character; if not char then return end
        local rp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        local pts = {FAP_L1, FAP_L2, FAP_L3, FAP_L4, FAP_L5}
        local ph = leftPhase
        local tgt = pts[ph]
        local spd = (ph >= 3) and CS or NS
        if (Vector3.new(tgt.X, rp.Position.Y, tgt.Z) - rp.Position).Magnitude < 1 then
            if ph == 5 then
                hum:Move(Vector3.zero,false); rp.AssemblyLinearVelocity=Vector3.zero
                fullAutoLeftEnabled=false
                stopFullAutoLeft()
                if fullAutoLeftSetter then fullAutoLeftSetter(false) end
                local face = Vector3.new(FACE_FAP_L.X, rp.Position.Y, FACE_FAP_L.Z)
                if (face - rp.Position).Magnitude > 0.01 then rp.CFrame = CFrame.new(rp.Position, face)
                return
            elseif ph == 2 then
                hum:Move(Vector3.zero,false); rp.AssemblyLinearVelocity=Vector3.zero
                task.wait(0.05); leftPhase=3; return
            else
                leftPhase = ph+1; return
            end
        end
        local d = tgt - rp.Position
        local mv = Vector3.new(d.X,0,d.Z).Unit
        hum:Move(mv,false); rp.AssemblyLinearVelocity = Vector3.new(mv.X*spd, rp.AssemblyLinearVelocity.Y, mv.Z*spd)
    end)
end

local function stopFullAutoRight()
    if fullAutoRightConn then fullAutoRightConn:Disconnect(); fullAutoRightConn=nil end
    rightPhase=1
    local char=LP.Character; if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
end
local function startFullAutoRight()
    stopFullAutoRight()
    rightPhase=1
    fullAutoRightConn = RunService.Heartbeat:Connect(function()
        if not fullAutoRightEnabled then return end
        local char=LP.Character; if not char then return end
        local rp=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        local pts = {FAP_R1, FAP_R2, FAP_R3, FAP_R4, FAP_R5}
        local ph = rightPhase
        local tgt = pts[ph]
        local spd = (ph >= 3) and CS or NS
        if (Vector3.new(tgt.X, rp.Position.Y, tgt.Z) - rp.Position).Magnitude < 1 then
            if ph == 5 then
                hum:Move(Vector3.zero,false); rp.AssemblyLinearVelocity=Vector3.zero
                fullAutoRightEnabled=false
                stopFullAutoRight()
                if fullAutoRightSetter then fullAutoRightSetter(false) end
                local face = Vector3.new(FACE_FAP_R.X, rp.Position.Y, FACE_FAP_R.Z)
                if (face - rp.Position).Magnitude > 0.01 then rp.CFrame = CFrame.new(rp.Position, face)
                return
            elseif ph == 2 then
                hum:Move(Vector3.zero,false); rp.AssemblyLinearVelocity=Vector3.zero
                task.wait(0.05); rightPhase=3; return
            else
                rightPhase = ph+1; return
            end
        end
        local d = tgt - rp.Position
        local mv = Vector3.new(d.X,0,d.Z).Unit
        hum:Move(mv,false); rp.AssemblyLinearVelocity = Vector3.new(mv.X*spd, rp.AssemblyLinearVelocity.Y, mv.Z*spd)
    end)
end

-- Float
local floatConn = nil
local function startFloat()
    if floatConn then return end
    floatConn = RunService.Heartbeat:Connect(function()
        if not floatEnabled then return end
        local char = LP.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {char}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local rr = workspace:Raycast(root.Position, Vector3.new(0,-200,0), rp)
        if rr then
            local diff = (rr.Position.Y + floatHeight) - root.Position.Y
            if floatJumping then
                if root.AssemblyLinearVelocity.Y <= 0 and diff >= -2 then floatJumping = false else return end
            end
            if math.abs(diff) > 0.3 then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, diff*15, root.AssemblyLinearVelocity.Z)
            else
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            end
        end
    end)
end
local function stopFloat()
    if floatConn then floatConn:Disconnect(); floatConn = nil end
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
    end
end

-- Lagger Mode
local laggerConn = nil
local function startLaggerMode()
    if laggerConn then return end
    laggerConn = RunService.Heartbeat:Connect(function()
        if not laggerMode then return end
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local bp = LP:FindFirstChild("Backpack"); if not bp then return end
        local tool = char:FindFirstChildOfClass("Tool") or bp:FindFirstChildOfClass("Tool")
        if tool then
            if tool.Parent == char then tool.Parent = bp else hum:EquipTool(tool) end
        end
    end)
end
local function stopLaggerMode()
    if laggerConn then laggerConn:Disconnect(); laggerConn = nil end
end

-- Billboard labels (created later)
local speedLabel = nil
local stealTimerLabel = nil
local divineUserLabel = nil

-- Rainbow cycle for steal timer
local rainbowHue = 0
task.spawn(function()
    while true do
        rainbowHue = (rainbowHue + 0.005) % 1
        if stealTimerLabel and stealTimerLabel.Visible and stealTimerLabel.Text == "READY TO STEAL" then
            stealTimerLabel.TextColor3 = Color3.fromHSV(rainbowHue, 1, 1)
        end
        task.wait(0.05)
    end
end)

-- Ragdoll timer
local ragTimerActive = false
local function startRagdollTimer()
    if ragTimerActive then return end
    ragTimerActive = true
    task.spawn(function()
        local countdown = 3.0
        while countdown > 0 and ragTimerActive do
            if stealTimerLabel then
                stealTimerLabel.Visible = true
                stealTimerLabel.Text = string.format("%.2f", countdown)
                stealTimerLabel.TextColor3 = Color3.fromRGB(255,80,80)
            end
            task.wait(0.05)
            countdown = countdown - 0.05
        end
        if ragTimerActive then
            if stealTimerLabel then
                stealTimerLabel.Text = "READY TO STEAL"
                stealTimerLabel.TextColor3 = Color3.fromHSV(0,1,1)
            end
            repeat task.wait(0.1) until (function()
                local c = LP.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if not hum then return true end
                local st = hum:GetState()
                return st ~= Enum.HumanoidStateType.Physics and st ~= Enum.HumanoidStateType.Ragdoll and st ~= Enum.HumanoidStateType.FallingDown
            end)()
            if stealTimerLabel then
                stealTimerLabel.Visible = false
                stealTimerLabel.Text = ""
            end
        end
        ragTimerActive = false
    end)
end

-- Movement speed loop
RunService.RenderStepped:Connect(function()
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local st = hum:GetState()
    if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
        startRagdollTimer()
    end

    local md = hum.MoveDirection
    local spd = laggerMode and LS or (speedMode and CS or NS)
    if md.Magnitude > 0 and not autoLeftEnabled and not autoRightEnabled then
        hrp.AssemblyLinearVelocity = Vector3.new(md.X * spd, hrp.AssemblyLinearVelocity.Y, md.Z * spd)
    end
    if speedLabel then
        speedLabel.Text = string.format("Speed: %.1f", Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude)
    end
end)

UIS.JumpRequest:Connect(function()
    if floatEnabled then floatJumping = true end
    if infJumpEnabled then
        local char = LP.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 55, root.AssemblyLinearVelocity.Z)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if infJumpEnabled then
        local char = LP.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root.AssemblyLinearVelocity.Y < -120 then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -120, root.AssemblyLinearVelocity.Z)
            end
        end
    end
end)

-- Character setup (adds billboard)
local function setupChar(char)
    task.wait(0.3)
    local head = char:FindFirstChild("Head")
    if head then
        local bb = Instance.new("BillboardGui", head)
        bb.Name = "DivineSpeedBB"
        bb.Size = UDim2.new(0, 180, 0, 76)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true

        speedLabel = Instance.new("TextLabel", bb)
        speedLabel.Size = UDim2.new(1, 0, 0, 24)
        speedLabel.Position = UDim2.new(0, 0, 0, 0)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Text = "Speed: 0"
        speedLabel.TextColor3 = Color3.fromRGB(210,210,210)
        speedLabel.Font = Enum.Font.GothamBlack
        speedLabel.TextScaled = true
        speedLabel.TextStrokeTransparency = 0.1
        speedLabel.TextStrokeColor3 = Color3.new(0,0,0)

        stealTimerLabel = Instance.new("TextLabel", bb)
        stealTimerLabel.Size = UDim2.new(1, 0, 0, 26)
        stealTimerLabel.Position = UDim2.new(0, 0, 0, 24)
        stealTimerLabel.BackgroundTransparency = 1
        stealTimerLabel.Text = ""
        stealTimerLabel.TextColor3 = Color3.fromRGB(255,80,80)
        stealTimerLabel.Font = Enum.Font.GothamBlack
        stealTimerLabel.TextScaled = true
        stealTimerLabel.TextStrokeTransparency = 0.1
        stealTimerLabel.TextStrokeColor3 = Color3.new(0,0,0)
        stealTimerLabel.Visible = false

        divineUserLabel = Instance.new("TextLabel", bb)
        divineUserLabel.Size = UDim2.new(1, 0, 0, 22)
        divineUserLabel.Position = UDim2.new(0, 0, 0, 50)
        divineUserLabel.BackgroundTransparency = 1
        divineUserLabel.Text = "divine user"
        divineUserLabel.TextColor3 = Color3.fromRGB(255,255,255)
        divineUserLabel.Font = Enum.Font.GothamBold
        divineUserLabel.TextScaled = true
        divineUserLabel.TextStrokeTransparency = 0.2
        divineUserLabel.TextStrokeColor3 = Color3.new(0,0,0)
    end
    if antiRagdollEnabled then startAntiRagdoll() end
    if medusaCounterEnabled then setupMedusa(char) end
    if unwalkEnabled then startUnwalk() end
    if autoBatEnabled then startAimbot() end
    if antiBatEnabled then startAntiBat() end
    if autoTPEnabled then startAutoTP() end
    if spamBatEnabled then startSpamBat() end
    if tryhardEnabled then startTryhardAnim() end
end
LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

-- GUI cleanup
for _, n in pairs({"DivineHubGUI"}) do
    pcall(function() game:GetService("CoreGui"):FindFirstChild(n):Destroy() end)
    pcall(function() LP:FindFirstChild("PlayerGui"):FindFirstChild(n):Destroy() end)
end

-- ================================
-- DIVINE HUB - PART 2
-- Run this immediately after Part 1.
-- ================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

-- ===================== COLORS =====================
local BG = Color3.fromRGB(8,8,8)
local SIDEBAR = Color3.fromRGB(14,14,14)
local CARD_BG = Color3.fromRGB(20,20,20)
local CARD_HOV = Color3.fromRGB(30,30,30)
local BORDER = Color3.fromRGB(40,40,40)
local BORDER2 = Color3.fromRGB(70,70,70)
local WHITE = Color3.fromRGB(235,235,235)
local DIM = Color3.fromRGB(160,160,160)
local ACCENT = Color3.fromRGB(235,235,235)
local DARK_ACC = Color3.fromRGB(90,90,90)
local OFF_BG = Color3.fromRGB(20,20,20)
local KB_BG = Color3.fromRGB(14,14,14)
local INPUT_BG = Color3.fromRGB(14,14,14)

local ACTIVE_TAB_BG = ACCENT
local ACTIVE_TAB_TXT = WHITE
local IDLE_TAB_BG = Color3.fromRGB(22,22,22)
local IDLE_TAB_TXT = DIM

-- ===================== GUI BUILD =====================
local function buildGUI()
local gui = Instance.new("ScreenGui")
gui.Name = "DivineHubGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local W, H, SW, CORNER = 280, 440, 82, 12

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos = false
    frame.InputBegan:Connect(function(inp)
        if guiLocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging and not guiLocked then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- Main frame
local main = Instance.new("Frame", gui)
main.Name = "Main"
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0, 40, 0, 40)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, CORNER)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = DARK_ACC
mainStroke.Thickness = 1.2
makeDraggable(main)

-- Topbar
local topbar = Instance.new("Frame", main)
topbar.Size = UDim2.new(1, 0, 0, 40)
topbar.BackgroundColor3 = SIDEBAR
topbar.BorderSizePixel = 0
topbar.ZIndex = 10
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, CORNER)
local topPatch = Instance.new("Frame", topbar)
topPatch.Size = UDim2.new(1, 0, 0, CORNER)
topPatch.Position = UDim2.new(0, 0, 1, -CORNER)
topPatch.BackgroundColor3 = SIDEBAR
topPatch.BorderSizePixel = 0
topPatch.ZIndex = 9
local topDiv = Instance.new("Frame", topbar)
topDiv.Size = UDim2.new(1, 0, 0, 1)
topDiv.Position = UDim2.new(0, 0, 1, -1)
topDiv.BackgroundColor3 = DARK_ACC
topDiv.BorderSizePixel = 0
topDiv.ZIndex = 11

local titleLbl = Instance.new("TextLabel", topbar)
titleLbl.Size = UDim2.new(0, 150, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "DIVINE HUB"
titleLbl.TextColor3 = ACCENT
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 14
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 12

local verLbl = Instance.new("TextLabel", topbar)
verLbl.Size = UDim2.new(0, 120, 1, 0)
verLbl.Position = UDim2.new(0, 96, 0, 0)
verLbl.BackgroundTransparency = 1
verLbl.Text = "v10"
verLbl.TextColor3 = DIM
verLbl.Font = Enum.Font.Gotham
verLbl.TextSize = 7
verLbl.TextXAlignment = Enum.TextXAlignment.Left
verLbl.ZIndex = 12

local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -32, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(24,24,24)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = WHITE
minBtn.Font = Enum.Font.GothamBlack
minBtn.TextSize = 14
minBtn.ZIndex = 13
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", minBtn).Color = DARK_ACC
minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(50,50,50)}):Play() end)
minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(24,24,24)}):Play() end)

-- Sidebar
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, SW, 1, -40 - CORNER)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = SIDEBAR
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 5
local sideTopPatch = Instance.new("Frame", main)
sideTopPatch.Size = UDim2.new(0, SW, 0, CORNER)
sideTopPatch.Position = UDim2.new(0, 0, 0, 40)
sideTopPatch.BackgroundColor3 = SIDEBAR
sideTopPatch.BorderSizePixel = 0
sideTopPatch.ZIndex = 4
local sideDiv = Instance.new("Frame", sidebar)
sideDiv.Size = UDim2.new(0, 1, 1, 0)
sideDiv.Position = UDim2.new(1, -1, 0, 0)
sideDiv.BackgroundColor3 = DARK_ACC
sideDiv.BorderSizePixel = 0
sideDiv.ZIndex = 6

-- Content area
local content = Instance.new("Frame", main)
content.Name = "ContentArea"
content.Size = UDim2.new(1, -SW - 1, 1, -40 - CORNER)
content.Position = UDim2.new(0, SW + 1, 0, 40)
content.BackgroundColor3 = BG
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.ZIndex = 2

-- D button (top-right)
local dButton = Instance.new("TextButton", gui)
dButton.Name = "DivineToggle"
dButton.Size = UDim2.new(0, 36, 0, 36)
dButton.Position = UDim2.new(1, -46, 0, 10)
dButton.BackgroundColor3 = SIDEBAR
dButton.BorderSizePixel = 0
dButton.Text = "D"
dButton.TextColor3 = ACCENT
dButton.Font = Enum.Font.GothamBlack
dButton.TextSize = 18
dButton.ZIndex = 20
Instance.new("UICorner", dButton).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", dButton).Color = DARK_ACC
makeDraggable(dButton)

local guiVisible = true
local function showGui() main.Visible = true; guiVisible = true end
local function hideGui() main.Visible = false; guiVisible = false end

minBtn.MouseButton1Click:Connect(hideGui)
dButton.MouseButton1Click:Connect(function()
    if guiVisible then hideGui() else showGui() end
end)

-- ===== TABS =====
local tabs, tabPages, activeTabName = {}, {}, nil
local tabDefs = {
    {name="Speed"}, {name="Lock"}, {name="Mechanics"}, {name="Movement"}, {name="Settings"}
}

local tabListFrame = Instance.new("Frame", sidebar)
tabListFrame.Size = UDim2.new(1, 0, 1, 0)
tabListFrame.Position = UDim2.new(0, 0, 0, 0)
tabListFrame.BackgroundTransparency = 1
tabListFrame.BorderSizePixel = 0
tabListFrame.ZIndex = 6
local tabLL = Instance.new("UIListLayout", tabListFrame)
tabLL.SortOrder = Enum.SortOrder.LayoutOrder
tabLL.Padding = UDim.new(0, 2)
local tabPad = Instance.new("UIPadding", tabListFrame)
tabPad.PaddingTop = UDim.new(0, 8)
tabPad.PaddingLeft = UDim.new(0, 5)
tabPad.PaddingRight = UDim.new(0, 5)

local function switchTab(name)
    activeTabName = name
    for _, td in ipairs(tabDefs) do
        local t = tabs[td.name]
        local isA = td.name == name
        TweenService:Create(t.frame, TweenInfo.new(0.14), {BackgroundColor3 = isA and ACTIVE_TAB_BG or IDLE_TAB_BG}):Play()
        TweenService:Create(t.lbl, TweenInfo.new(0.14), {TextColor3 = isA and ACTIVE_TAB_TXT or IDLE_TAB_TXT}):Play()
        tabPages[td.name].Visible = isA
    end
end

local pageLOs = {}
for i, td in ipairs(tabDefs) do
    local btn = Instance.new("TextButton", tabListFrame)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = IDLE_TAB_BG
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.LayoutOrder = i
    btn.ZIndex = 7
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = td.name
    lbl.TextColor3 = IDLE_TAB_TXT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextWrapped = true
    lbl.ZIndex = 9
    tabs[td.name] = {frame = btn, lbl = lbl}
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundColor3 = BG
    page.BackgroundTransparency = 0
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = DARK_ACC
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.ZIndex = 3
    local pll = Instance.new("UIListLayout", page)
    pll.SortOrder = Enum.SortOrder.LayoutOrder
    pll.Padding = UDim.new(0, 3)
    local pp = Instance.new("UIPadding", page)
    pp.PaddingLeft = UDim.new(0, 6)
    pp.PaddingRight = UDim.new(0, 6)
    pp.PaddingTop = UDim.new(0, 8)
    pp.PaddingBottom = UDim.new(0, 8)
    tabPages[td.name] = page
    pageLOs[td.name] = 0
    btn.MouseButton1Click:Connect(function() switchTab(td.name) end)
    btn.MouseEnter:Connect(function()
        if activeTabName ~= td.name then TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=CARD_HOV}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabName ~= td.name then TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=IDLE_TAB_BG}):Play() end
    end)
end

-- ===== UI HELPERS =====
local function lo(t) pageLOs[t] = pageLOs[t] + 1; return pageLOs[t] end
local function pg(t) return tabPages[t] end

local function makeSecHeader(tabName, text)
    local f = Instance.new("Frame", pg(tabName))
    f.Size = UDim2.new(1, 0, 0, 16)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.LayoutOrder = lo(tabName)
    f.ZIndex = 4
    local t2 = Instance.new("Frame", f)
    t2.Size = UDim2.new(0, 3, 0, 9)
    t2.Position = UDim2.new(0, 0, 0.5, -4)
    t2.BackgroundColor3 = ACCENT
    t2.BorderSizePixel = 0
    Instance.new("UICorner", t2).CornerRadius = UDim.new(0, 2)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.TextColor3 = ACCENT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 7
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
end

local function baseCard(tabName, h2)
    local c = Instance.new("Frame", pg(tabName))
    c.Size = UDim2.new(1, 0, 0, h2 or 34)
    c.BackgroundColor3 = CARD_BG
    c.BorderSizePixel = 0
    c.LayoutOrder = lo(tabName)
    c.ZIndex = 4
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 7)
    local s = Instance.new("UIStroke", c)
    s.Color = BORDER
    s.Thickness = 1
    c.MouseEnter:Connect(function() TweenService:Create(c,TweenInfo.new(0.1),{BackgroundColor3=CARD_HOV}):Play() end)
    c.MouseLeave:Connect(function() TweenService:Create(c,TweenInfo.new(0.1),{BackgroundColor3=CARD_BG}):Play() end)
    return c
end

local function cLabel(p, text, x, w, sz, col, font, xa)
    local l = Instance.new("TextLabel", p)
    l.Size = UDim2.new(0, w or 140, 1, 0)
    l.Position = UDim2.new(0, x or 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = col or WHITE
    l.Font = font or Enum.Font.GothamBold
    l.TextSize = sz or 10
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.ZIndex = 10
    return l
end

local function makePillToggle(parent, defOn, onToggle)
    local PW, PH = 34, 18
    local pbg = Instance.new("Frame", parent)
    pbg.Size = UDim2.new(0, PW, 0, PH)
    pbg.Position = UDim2.new(1, -(PW+8), 0.5, -PH/2)
    pbg.BackgroundColor3 = defOn and ACCENT or OFF_BG
    pbg.BorderSizePixel = 0
    pbg.ZIndex = 8
    Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 9)
    local ps = Instance.new("UIStroke", pbg)
    ps.Color = defOn and DARK_ACC or BORDER2
    ps.Thickness = 1
    local dot = Instance.new("Frame", pbg)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = defOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = WHITE
    dot.BorderSizePixel = 0
    dot.ZIndex = 9
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
    local isOn = defOn or false
    local function setV(on)
        isOn = on
        TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3 = on and ACCENT or OFF_BG}):Play()
        TweenService:Create(ps, TweenInfo.new(0.18), {Color = on and DARK_ACC or BORDER2}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = WHITE
        }):Play()
    end
    local clk = Instance.new("TextButton", parent)
    clk.Size = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 6
    clk.MouseButton1Click:Connect(function()
        if _anyKeyListening then return end
        isOn = not isOn
        setV(isOn)
        if onToggle then pcall(onToggle, isOn) end
    end)
    return setV
end

local function makeKB(parent, kbEntry, onChange)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0, 40, 0, 18)
    b.BackgroundColor3 = KB_BG
    b.BorderSizePixel = 0
    local function getDisplayText()
        if kbEntry.gp then return "🎮"..kbEntry.gp.Name end
        return (kbEntry.kb or Enum.KeyCode.Unknown).Name
    end
    b.Text = getDisplayText()
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBold
    b.TextSize = 7
    b.ZIndex = 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local bs = Instance.new("UIStroke", b)
    bs.Color = BORDER2
    bs.Thickness = 1
    local li = false
    local lc
    local pv = b.Text
    b.MouseButton1Click:Connect(function()
        if li then
            li = false
            _anyKeyListening = false
            if lc then lc:Disconnect(); lc = nil end
            b.Text = pv
            b.TextColor3 = WHITE
            TweenService:Create(bs, TweenInfo.new(0.1), {Color = BORDER2}):Play()
            return
        end
        pv = b.Text
        li = true
        _anyKeyListening = true
        b.Text = "···"
        b.TextColor3 = DIM
        TweenService:Create(bs, TweenInfo.new(0.1), {Color = ACCENT}):Play()
        lc = UIS.InputBegan:Connect(function(inp)
            if not li then return end
            local isKB = inp.UserInputType == Enum.UserInputType.Keyboard
            local isGP = inp.UserInputType == Enum.UserInputType.Gamepad1 or inp.UserInputType == Enum.UserInputType.Gamepad2
            if not isKB and not isGP then return end
            if inp.KeyCode == Enum.KeyCode.Escape then
                li = false
                _anyKeyListening = false
                if lc then lc:Disconnect(); lc = nil end
                b.Text = pv
                b.TextColor3 = WHITE
                TweenService:Create(bs, TweenInfo.new(0.1), {Color = BORDER2}):Play()
                return
            end
            if isGP then
                kbEntry.gp = inp.KeyCode
                b.Text = "🎮"..inp.KeyCode.Name
                pv = b.Text
                b.TextColor3 = WHITE
            else
                kbEntry.gp = nil
                b.Text = inp.KeyCode.Name
                pv = inp.KeyCode.Name
                b.TextColor3 = WHITE
                if onChange then onChange(inp.KeyCode) end
            end
            li = false
            _anyKeyListening = false
            if lc then lc:Disconnect(); lc = nil end
            TweenService:Create(bs, TweenInfo.new(0.1), {Color = BORDER2}):Play()
            if isGP and onChange then onChange(inp.KeyCode) end
        end)
    end)
    return b
end

local function rowToggle(tabName, label, sub, defOn, onToggle)
    local c = baseCard(tabName, sub and 44 or 34)
    cLabel(c, label, 8, 150, 10, WHITE, Enum.Font.GothamBold)
    if sub then
        local sl = cLabel(c, sub, 8, 160, 8, DIM, Enum.Font.Gotham)
        sl.Size = UDim2.new(0, 160, 0, 12)
        sl.Position = UDim2.new(0, 8, 0, 22)
    end
    return makePillToggle(c, defOn, onToggle)
end

local function rowToggleKB(tabName, label, sub, kbEntry, defOn, onToggle, onKeyChange)
    local c = baseCard(tabName, sub and 44 or 34)
    cLabel(c, label, 8, 110, 10, WHITE, Enum.Font.GothamBold)
    if sub then
        local sl = cLabel(c, sub, 8, 140, 8, DIM, Enum.Font.Gotham)
        sl.Size = UDim2.new(0, 140, 0, 12)
        sl.Position = UDim2.new(0, 8, 0, 22)
    end
    local kb = makeKB(c, kbEntry, function(k)
        kbEntry.kb = k
        kbEntry.gp = nil
        if onKeyChange then onKeyChange(k) end
    end)
    kb.Position = UDim2.new(1, -(40+8+34+6), 0.5, -9)
    local PW, PH = 34, 18
    local pbg = Instance.new("Frame", c)
    pbg.Size = UDim2.new(0, PW, 0, PH)
    pbg.Position = UDim2.new(1, -(PW+8), 0.5, -PH/2)
    pbg.BackgroundColor3 = defOn and ACCENT or OFF_BG
    pbg.BorderSizePixel = 0
    pbg.ZIndex = 8
    Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 9)
    local ps = Instance.new("UIStroke", pbg)
    ps.Color = defOn and DARK_ACC or BORDER2
    ps.Thickness = 1
    local dot = Instance.new("Frame", pbg)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = defOn and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = WHITE
    dot.BorderSizePixel = 0
    dot.ZIndex = 9
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
    local isOn = defOn or false
    local function setV(on)
        isOn = on
        TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3 = on and ACCENT or OFF_BG}):Play()
        TweenService:Create(ps, TweenInfo.new(0.18), {Color = on and DARK_ACC or BORDER2}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = WHITE
        }):Play()
    end
    local clk = Instance.new("TextButton", c)
    clk.Size = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 6
    clk.MouseButton1Click:Connect(function()
        if _anyKeyListening then return end
        isOn = not isOn
        setV(isOn)
        if onToggle then pcall(onToggle, isOn) end
    end)
    return setV, kb
end

local function rowInput(tabName, label, sub, default, onChange)
    local c = baseCard(tabName, sub and 44 or 34)
    cLabel(c, label, 8, 120, 10, WHITE, Enum.Font.GothamBold)
    if sub then
        local sl = cLabel(c, sub, 8, 150, 8, DIM, Enum.Font.Gotham)
        sl.Size = UDim2.new(0, 150, 0, 12)
        sl.Position = UDim2.new(0, 8, 0, 22)
    end
    local box = Instance.new("TextBox", c)
    box.Size = UDim2.new(0, 58, 0, 22)
    box.Position = UDim2.new(1, -66, 0.5, -11)
    box.BackgroundColor3 = INPUT_BG
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = WHITE
    box.Font = Enum.Font.GothamBold
    box.TextSize = 10
    box.ClearTextOnFocus = false
    box.ZIndex = 11
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    local bs = Instance.new("UIStroke", box)
    bs.Color = BORDER2
    bs.Thickness = 1
    bs.ZIndex = 12
    box.Focused:Connect(function() TweenService:Create(bs,TweenInfo.new(0.1),{Color=ACCENT}):Play() end)
    box.FocusLost:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.1),{Color=BORDER2}):Play()
        if onChange then
            local n = tonumber(box.Text)
            if n then onChange(n) else box.Text = tostring(default) end
        end
    end)
    return box
end

local function rowActionBtnWhite(tabName, label, onClick)
    local b = Instance.new("TextButton", pg(tabName))
    b.Size = UDim2.new(1, 0, 0, 38)
    b.BackgroundColor3 = Color3.fromRGB(16,16,16)
    b.BorderSizePixel = 0
    b.Text = label
    b.TextColor3 = Color3.fromRGB(235,235,235)
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 11
    b.LayoutOrder = lo(tabName)
    b.ZIndex = 5
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    local bs = Instance.new("UIStroke", b)
    bs.Color = BORDER2
    bs.Thickness = 1
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(30,30,38)}):Play()
        task.delay(0.15,function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(16,16,16)}):Play() end)
        if onClick then pcall(onClick) end
    end)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(32,32,32)}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(16,16,16)}):Play() end)
    return b
end

-- ===== PROGRESS BAR =====
local pbFrame = Instance.new("Frame", gui)
pbFrame.Size = UDim2.new(0, 240, 0, 44)
pbFrame.Position = UDim2.new(0.5, -120, 1, -65)
pbFrame.BackgroundColor3 = SIDEBAR
pbFrame.BorderSizePixel = 0
pbFrame.Active = true
Instance.new("UICorner", pbFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", pbFrame).Color = DARK_ACC
makeDraggable(pbFrame)
progressPct = Instance.new("TextLabel", pbFrame)
progressPct.Size = UDim2.new(0, 40, 0, 15)
progressPct.Position = UDim2.new(0, 8, 0, 5)
progressPct.BackgroundTransparency = 1
progressPct.Text = "0%"
progressPct.TextColor3 = WHITE
progressPct.Font = Enum.Font.GothamBold
progressPct.TextSize = 10
progressPct.TextXAlignment = Enum.TextXAlignment.Left
progressPct.ZIndex = 5
progressRadLbl = Instance.new("TextLabel", pbFrame)
progressRadLbl.Size = UDim2.new(0, 110, 0, 15)
progressRadLbl.Position = UDim2.new(1, -118, 0, 5)
progressRadLbl.BackgroundTransparency = 1
progressRadLbl.Text = "Radius: " .. Steal.StealRadius
progressRadLbl.TextColor3 = ACCENT
progressRadLbl.Font = Enum.Font.GothamBold
progressRadLbl.TextSize = 10
progressRadLbl.TextXAlignment = Enum.TextXAlignment.Right
progressRadLbl.ZIndex = 5
local pbBg = Instance.new("Frame", pbFrame)
pbBg.Size = UDim2.new(1, -16, 0, 10)
pbBg.Position = UDim2.new(0, 8, 0, 26)
pbBg.BackgroundColor3 = Color3.fromRGB(12,12,18)
pbBg.BorderSizePixel = 0
Instance.new("UICorner", pbBg).CornerRadius = UDim.new(0, 5)
progressFill = Instance.new("Frame", pbBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = ACCENT
progressFill.BorderSizePixel = 0
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 5)

-- ========== INDIVIDUAL MOBILE BUTTONS ==========
local mobileButtons = {}
local function createMobileButton(id, label, defaultPos, callback)
    local btnFrame = Instance.new("Frame", gui)
    btnFrame.Size = UDim2.new(0, 70, 0, 70)
    btnFrame.Position = defaultPos
    btnFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btnFrame.BorderSizePixel = 0
    btnFrame.ZIndex = 100
    Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", btnFrame)
    stroke.Color = Color3.fromRGB(70,70,70)
    stroke.Thickness = 1.5
    local inner = Instance.new("Frame", btnFrame)
    inner.Size = UDim2.new(1, -4, 1, -4)
    inner.Position = UDim2.new(0, 2, 0, 2)
    inner.BackgroundColor3 = Color3.fromRGB(15,15,20)
    inner.BorderSizePixel = 0
    Instance.new("UICorner", inner).CornerRadius = UDim.new(0, 10)
    local text = Instance.new("TextLabel", btnFrame)
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = Color3.fromRGB(245,245,245)
    text.Font = Enum.Font.GothamBlack
    text.TextSize = 11
    text.TextWrapped = true
    text.ZIndex = 101
    local clickArea = Instance.new("TextButton", btnFrame)
    clickArea.Size = UDim2.new(1,0,1,0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 102
    local dragging = false
    local dragStart, startPos, dragMoved = nil, nil, false
    local pressStart = nil
    clickArea.InputBegan:Connect(function(input)
        if not mobileDraggingEnabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btnFrame.Position
            dragMoved = false
            pressStart = tick()
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and mobileDraggingEnabled and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if not dragMoved and delta.Magnitude > 5 then
                dragMoved = true
            end
            if dragMoved then
                btnFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    clickArea.InputEnded:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not dragMoved and pressStart and (tick() - pressStart) < 0.3 then
                if callback then callback() end
            end
            dragging = false
            dragMoved = false
        end
    end)
    mobileButtons[id] = btnFrame
    return btnFrame
end

-- Positions (5 rows, 2 columns)
local startX = 0.85
local startY = 0.15
local offsetX = 85
local offsetY = 85
local positions = {
    LOCK   = UDim2.new(startX, -offsetX*1, startY, 0),
    PLAYL  = UDim2.new(startX, -offsetX*2, startY, 0),
    PLAYR  = UDim2.new(startX, -offsetX*1, startY + 0.12, 0),
    AUTOL  = UDim2.new(startX, -offsetX*2, startY + 0.12, 0),
    AUTOR  = UDim2.new(startX, -offsetX*1, startY + 0.24, 0),
    DROP   = UDim2.new(startX, -offsetX*2, startY + 0.24, 0),
    FLOAT  = UDim2.new(startX, -offsetX*1, startY + 0.36, 0),
    CARRY  = UDim2.new(startX, -offsetX*2, startY + 0.36, 0),
    LAGGER = UDim2.new(startX, -offsetX*1, startY + 0.48, 0),
    TPDOWN = UDim2.new(startX, -offsetX*2, startY + 0.48, 0),
}
createMobileButton("LOCK", "LOCK", positions.LOCK, function()
    autoBatEnabled = not autoBatEnabled
    if autoBatEnabled then startAimbot() else stopAimbot() end
    if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end
    saveConfig()
end)
createMobileButton("PLAYL", "PLAY L", positions.PLAYL, function()
    autoLeftEnabled = not autoLeftEnabled
    if autoLeftEnabled then startPlayLeft() else stopPlayLeft() end
    if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
    saveConfig()
end)
createMobileButton("PLAYR", "PLAY R", positions.PLAYR, function()
    autoRightEnabled = not autoRightEnabled
    if autoRightEnabled then startPlayRight() else stopPlayRight() end
    if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
    saveConfig()
end)
createMobileButton("AUTOL", "AUTO L", positions.AUTOL, function()
    fullAutoLeftEnabled = not fullAutoLeftEnabled
    if fullAutoLeftEnabled then startFullAutoLeft() else stopFullAutoLeft() end
    if fullAutoLeftSetter then fullAutoLeftSetter(fullAutoLeftEnabled) end
    saveConfig()
end)
createMobileButton("AUTOR", "AUTO R", positions.AUTOR, function()
    fullAutoRightEnabled = not fullAutoRightEnabled
    if fullAutoRightEnabled then startFullAutoRight() else stopFullAutoRight() end
    if fullAutoRightSetter then fullAutoRightSetter(fullAutoRightEnabled) end
    saveConfig()
end)
createMobileButton("DROP", "DROP", positions.DROP, function()
    local was = dropEnabled
    toggleDrop(not was)
    if dropMobileSetter then dropMobileSetter(not was) end
    saveConfig()
end)
createMobileButton("FLOAT", "FLOAT", positions.FLOAT, function()
    floatEnabled = not floatEnabled
    if setFloat then setFloat(floatEnabled) end
    if floatEnabled then startFloat() else stopFloat() end
    saveConfig()
end)
createMobileButton("CARRY", "CARRY", positions.CARRY, function()
    speedMode = not speedMode
    if modeValLbl then modeValLbl.Text = speedMode and "Carry" or "Normal" end
    saveConfig()
end)
createMobileButton("LAGGER", "LAGGER", positions.LAGGER, function()
    laggerMode = not laggerMode
    if setLaggerVisual then setLaggerVisual(laggerMode) end
    if laggerMode then startLaggerMode() else stopLaggerMode() end
    saveConfig()
end)
createMobileButton("TPDOWN", "TP DOWN", positions.TPDOWN, function()
    runTPDown()
end)

local function setMobileButtonsVisible(vis)
    for _, btn in pairs(mobileButtons) do
        btn.Visible = vis
    end
end

-- ===== SPEED TAB =====
makeSecHeader("Speed", "Speed")
normalBox = rowInput("Speed", "Normal Speed", "", NS, function(v) if v>0 and v<=500 then NS=v end; saveConfig() end)
carryBox = rowInput("Speed", "Carry Speed", "", CS, function(v) if v>0 and v<=500 then CS=v end; saveConfig() end)
laggerBox = rowInput("Speed", "Lagger Speed", "", LS, function(v) if v>0 and v<=500 then LS=v end; saveConfig() end)
do
    local c = baseCard("Speed", 34)
    cLabel(c, "Mode", 8, 70, 10, WHITE, Enum.Font.GothamBold)
    modeValLbl = cLabel(c, "Normal", 80, 70, 9, DIM, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    local kb = makeKB(c, KB.SpeedToggle, function(k) KB.SpeedToggle.kb = k; saveConfig() end)
    kb.Position = UDim2.new(1, -(40+8), 0.5, -9)
    local clk = Instance.new("TextButton", c)
    clk.Size = UDim2.new(0.65, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 6
    clk.MouseButton1Click:Connect(function()
        if _anyKeyListening then return end
        speedMode = not speedMode
        modeValLbl.Text = speedMode and "Carry" or "Normal"
        saveConfig()
    end)
end
do
    local c = baseCard("Speed", 34)
    cLabel(c, "Lagger Mode", 8, 100, 10, WHITE, Enum.Font.GothamBold)
    local kb = makeKB(c, KB.LaggerMode, function(k) KB.LaggerMode.kb = k; saveConfig() end)
    kb.Position = UDim2.new(1, -(40+8+34+6), 0.5, -9)
    local PW, PH = 34, 18
    local pbg = Instance.new("Frame", c)
    pbg.Size = UDim2.new(0, PW, 0, PH)
    pbg.Position = UDim2.new(1, -(PW+8), 0.5, -PH/2)
    pbg.BackgroundColor3 = OFF_BG
    pbg.BorderSizePixel = 0
    Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 9)
    local ps = Instance.new("UIStroke", pbg)
    ps.Color = BORDER2
    ps.Thickness = 1
    local dot = Instance.new("Frame", pbg)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = WHITE
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
    setLaggerVisual = function(on)
        TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3 = on and ACCENT or OFF_BG}):Play()
        TweenService:Create(ps, TweenInfo.new(0.18), {Color = on and DARK_ACC or BORDER2}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = WHITE
        }):Play()
    end
    local clk = Instance.new("TextButton", c)
    clk.Size = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 6
    clk.MouseButton1Click:Connect(function()
        if _anyKeyListening then return end
        laggerMode = not laggerMode
        setLaggerVisual(laggerMode)
        if laggerMode then startLaggerMode() else stopLaggerMode() end
        saveConfig()
    end)
end

-- ===== LOCK TAB =====
makeSecHeader("Lock", "Lock Combat")
do
    local sv, _ = rowToggleKB("Lock", "Lock", "Auto rush & swing", KB.AutoBat, false,
        function(on)
            autoBatEnabled = on
            if on then startAimbot() else stopAimbot() end
            saveConfig()
        end, function(k) KB.AutoBat.kb = k; saveConfig() end)
    autoBatSetVisual = sv
end

-- Auto Bat (Spam Bat) with range slider
makeSecHeader("Lock", "Auto Bat")
do
    local c = baseCard("Lock", 44)
    cLabel(c, "Auto Bat", 8, 100, 10, WHITE, Enum.Font.GothamBold)
    -- Toggle
    local toggleBg = Instance.new("Frame", c)
    toggleBg.Size = UDim2.new(0, 34, 0, 18)
    toggleBg.Position = UDim2.new(1, -50, 0.5, -9)
    toggleBg.BackgroundColor3 = spamBatEnabled and ACCENT or OFF_BG
    toggleBg.BorderSizePixel = 0
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(0, 9)
    local toggleDot = Instance.new("Frame", toggleBg)
    toggleDot.Size = UDim2.new(0, 12, 0, 12)
    toggleDot.Position = spamBatEnabled and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    toggleDot.BackgroundColor3 = WHITE
    Instance.new("UICorner", toggleDot).CornerRadius = UDim.new(0, 4)
    local toggleBtn = Instance.new("TextButton", c)
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 6
    toggleBtn.MouseButton1Click:Connect(function()
        spamBatEnabled = not spamBatEnabled
        if spamBatEnabled then startSpamBat() else stopSpamBat() end
        TweenService:Create(toggleBg, TweenInfo.new(0.18), {BackgroundColor3 = spamBatEnabled and ACCENT or OFF_BG}):Play()
        TweenService:Create(toggleDot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = spamBatEnabled and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        }):Play()
        saveConfig()
    end)
    -- Range slider
    local box = Instance.new("TextBox", c)
    box.Size = UDim2.new(0, 50, 0, 22)
    box.Position = UDim2.new(1, -66, 0.5, -11)
    box.BackgroundColor3 = INPUT_BG
    box.BorderSizePixel = 0
    box.Text = tostring(spamBatRange)
    box.TextColor3 = WHITE
    box.Font = Enum.Font.GothamBold
    box.TextSize = 10
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    local bs = Instance.new("UIStroke", box)
    bs.Color = BORDER2
    bs.Thickness = 1
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then spamBatRange = math.clamp(n, 1, 100); box.Text = tostring(spamBatRange); saveConfig() end
    end)
end

makeSecHeader("Lock", "Counter")
do
    local sv = rowToggle("Lock", "Medusa Counter", "", false, function(on)
        medusaCounterEnabled = on
        if on then setupMedusa(LP.Character) else stopMedusaCounter() end
        saveConfig()
    end)
    setMedusaVisual = sv
end
do
    local sv = rowToggle("Lock", "Anti Bat", "", false, function(on)
        antiBatEnabled = on
        if on then startAntiBat() else stopAntiBat() end
        saveConfig()
    end)
end

-- ===== MECHANICS TAB =====
makeSecHeader("Mechanics", "Auto Steal")
do
    local c = baseCard("Mechanics", 50)
    cLabel(c, "Auto Steal", 8, 120, 10, WHITE, Enum.Font.GothamBold)
    local toggleBtn = Instance.new("TextButton", c)
    toggleBtn.Size = UDim2.new(0, 80, 0, 26)
    toggleBtn.Position = UDim2.new(1, -90, 0.5, -13)
    toggleBtn.BackgroundColor3 = Steal.AutoStealEnabled and Color3.fromRGB(0,120,0) or Color3.fromRGB(50,50,60)
    toggleBtn.Text = Steal.AutoStealEnabled and "STOP" or "START"
    toggleBtn.TextColor3 = WHITE
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
    toggleBtn.MouseButton1Click:Connect(function()
        Steal.AutoStealEnabled = not Steal.AutoStealEnabled
        if Steal.AutoStealEnabled then startAutoSteal() else stopAutoSteal() end
        toggleBtn.BackgroundColor3 = Steal.AutoStealEnabled and Color3.fromRGB(0,120,0) or Color3.fromRGB(50,50,60)
        toggleBtn.Text = Steal.AutoStealEnabled and "STOP" or "START"
        saveConfig()
    end)
    setAutoStealVisual = function(on)
        toggleBtn.BackgroundColor3 = on and Color3.fromRGB(0,120,0) or Color3.fromRGB(50,50,60)
        toggleBtn.Text = on and "STOP" or "START"
    end
end
do
    local c = baseCard("Mechanics", 44)
    cLabel(c, "Steal Duration", 8, 150, 10, WHITE, Enum.Font.GothamBold)
    local box = Instance.new("TextBox", c)
    box.Size = UDim2.new(0, 58, 0, 22)
    box.Position = UDim2.new(1, -66, 0.5, -11)
    box.BackgroundColor3 = INPUT_BG
    box.BorderSizePixel = 0
    box.Text = tostring(Steal.StealDuration)
    box.TextColor3 = WHITE
    box.Font = Enum.Font.GothamBold
    box.TextSize = 10
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    local bs = Instance.new("UIStroke", box)
    bs.Color = BORDER2
    bs.Thickness = 1
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n and n > 0 and n <= 2 then Steal.StealDuration = n else box.Text = tostring(Steal.StealDuration) end
        saveConfig()
    end)
    durationInput = box
end
do
    local c = baseCard("Mechanics", 34)
    cLabel(c, "Grab Radius", 8, 110, 10, WHITE, Enum.Font.GothamBold)
    local radValBtn = Instance.new("TextButton", c)
    radValBtn.Size = UDim2.new(0, 58, 0, 22)
    radValBtn.Position = UDim2.new(1, -66, 0.5, -11)
    radValBtn.BackgroundColor3 = INPUT_BG
    radValBtn.BorderSizePixel = 0
    radValBtn.Text = tostring(Steal.StealRadius)
    radValBtn.TextColor3 = WHITE
    radValBtn.Font = Enum.Font.GothamBold
    radValBtn.TextSize = 10
    Instance.new("UICorner", radValBtn).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", radValBtn).Color = BORDER2
    local typing = false
    radValBtn.MouseButton1Click:Connect(function()
        if typing then return end
        typing = true
        local tb = Instance.new("TextBox", c)
        tb.Size = radValBtn.Size
        tb.Position = radValBtn.Position
        tb.BackgroundColor3 = CARD_HOV
        tb.BorderSizePixel = 0
        tb.Text = tostring(Steal.StealRadius)
        tb.TextColor3 = WHITE
        tb.Font = Enum.Font.GothamBold
        tb.TextSize = 10
        tb.ClearTextOnFocus = false
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)
        Instance.new("UIStroke", tb).Color = ACCENT
        tb:CaptureFocus()
        tb.FocusLost:Connect(function()
            local num = tonumber(tb.Text)
            if num and num >= 5 and num <= 300 then
                Steal.StealRadius = math.floor(num)
                radValBtn.Text = tostring(Steal.StealRadius)
                if progressRadLbl then progressRadLbl.Text = "Radius: " .. Steal.StealRadius end
            end
            tb:Destroy()
            typing = false
            saveConfig()
        end)
    end)
    radInput = radValBtn
end

makeSecHeader("Mechanics", "Toggles")
setInfJumpVisual = rowToggle("Mechanics", "Infinite Jump", "", false, function(on) infJumpEnabled = on; saveConfig() end)
setAntiRagVisual = rowToggle("Mechanics", "Anti Ragdoll", "", false, function(on) antiRagdollEnabled = on; if on then startAntiRagdoll() else stopAntiRagdoll() end; saveConfig() end)
rowToggle("Mechanics", "FPS Boost", "", false, function(on) if on then enableFPSBoost() else disableFPSBoost() end; saveConfig() end)
setUnwalkVisual = rowToggle("Mechanics", "Unwalk", "", false, function(on) unwalkEnabled = on; if on then startUnwalk() else stopUnwalk() end; saveConfig() end)
setStretchRezVisual = rowToggle("Mechanics", "Stretch Rez", "", false, function(on) if on then enableStretchRez() else disableStretchRez() end; saveConfig() end)
do
    local sv = rowToggle("Mechanics", "Dark Mode", "", darkModeEnabled, function(on)
        darkModeEnabled = on
        applyDarkMode(on)
        saveConfig()
    end)
end

-- ===== MOVEMENT TAB =====
makeSecHeader("Movement", "Movement")
do
    local sv, _ = rowToggleKB("Movement", "Play L", "Walk to left podium", KB.AutoLeft, autoLeftEnabled,
        function(on) autoLeftEnabled = on; if on then startPlayLeft() else stopPlayLeft() end; saveConfig() end,
        function(k) KB.AutoLeft.kb = k; saveConfig() end)
    autoLeftSetVisual = sv
end
do
    local sv, _ = rowToggleKB("Movement", "Play R", "Walk to right podium", KB.AutoRight, autoRightEnabled,
        function(on) autoRightEnabled = on; if on then startPlayRight() else stopPlayRight() end; saveConfig() end,
        function(k) KB.AutoRight.kb = k; saveConfig() end)
    autoRightSetVisual = sv
end
makeSecHeader("Movement", "Full Auto")
do
    local sv = rowToggle("Movement", "Auto L", "", fullAutoLeftEnabled, function(on)
        fullAutoLeftEnabled = on
        if on then startFullAutoLeft() else stopFullAutoLeft() end
        if fullAutoLeftSetter then fullAutoLeftSetter(on) end
        saveConfig()
    end)
    fullAutoLeftSetter = sv
end
do
    local sv = rowToggle("Movement", "Auto R", "", fullAutoRightEnabled, function(on)
        fullAutoRightEnabled = on
        if on then startFullAutoRight() else stopFullAutoRight() end
        if fullAutoRightSetter then fullAutoRightSetter(on) end
        saveConfig()
    end)
    fullAutoRightSetter = sv
end
rowKBOnly("Movement", "Drop", "", KB.DropBrainrot, function(k) KB.DropBrainrot.kb = k; saveConfig() end)
rowKBOnly("Movement", "TP Down", "", KB.TPDown, function(k) KB.TPDown.kb = k; saveConfig() end)

makeSecHeader("Movement", "Tryhard Animation")
do
    local sv = rowToggle("Movement", "Tryhard", "", tryhardEnabled, function(on)
        tryhardEnabled = on
        if on then startTryhardAnim() else stopTryhardAnim() end
        saveConfig()
    end)
end

makeSecHeader("Movement", "Float")
floatHeightBox = rowInput("Movement", "Float Height", "", floatHeight, function(v) local n = tonumber(v); if n and n >= 1 and n <= 100 then floatHeight = n end; saveConfig() end)
do
    local c = baseCard("Movement", 34)
    cLabel(c, "Float", 8, 110, 10, WHITE, Enum.Font.GothamBold)
    local kb = makeKB(c, KB.Float, function(k) KB.Float.kb = k; saveConfig() end)
    kb.Position = UDim2.new(1, -(40+8+34+6), 0.5, -9)
    local PW, PH = 34, 18
    local pbg = Instance.new("Frame", c)
    pbg.Size = UDim2.new(0, PW, 0, PH)
    pbg.Position = UDim2.new(1, -(PW+8), 0.5, -PH/2)
    pbg.BackgroundColor3 = OFF_BG
    pbg.BorderSizePixel = 0
    Instance.new("UICorner", pbg).CornerRadius = UDim.new(0, 9)
    local ps = Instance.new("UIStroke", pbg)
    ps.Color = BORDER2
    ps.Thickness = 1
    local dot = Instance.new("Frame", pbg)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = WHITE
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
    setFloat = function(on)
        TweenService:Create(pbg, TweenInfo.new(0.18), {BackgroundColor3 = on and ACCENT or OFF_BG}):Play()
        TweenService:Create(ps, TweenInfo.new(0.18), {Color = on and DARK_ACC or BORDER2}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = WHITE
        }):Play()
    end
    local clk = Instance.new("TextButton", c)
    clk.Size = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 6
    clk.MouseButton1Click:Connect(function()
        if _anyKeyListening then return end
        floatEnabled = not floatEnabled
        setFloat(floatEnabled)
        if floatEnabled then startFloat() else stopFloat() end
        saveConfig()
    end)
end

makeSecHeader("Movement", "Auto TP")
do
    local c = baseCard("Movement", 44)
    cLabel(c, "Auto TP", 8, 100, 10, WHITE, Enum.Font.GothamBold)
    local yInput = Instance.new("TextBox", c)
    yInput.Size = UDim2.new(0, 50, 0, 22)
    yInput.Position = UDim2.new(1, -120, 0.5, -11)
    yInput.BackgroundColor3 = INPUT_BG
    yInput.BorderSizePixel = 0
    yInput.Text = tostring(autoTPHeight)
    yInput.TextColor3 = WHITE
    yInput.Font = Enum.Font.GothamBold
    yInput.TextSize = 10
    Instance.new("UICorner", yInput).CornerRadius = UDim.new(0, 5)
    local yStroke = Instance.new("UIStroke", yInput)
    yStroke.Color = BORDER2
    yStroke.Thickness = 1
    yInput.FocusLost:Connect(function()
        local n = tonumber(yInput.Text)
        if n then autoTPHeight = math.clamp(n, 0, 50); yInput.Text = tostring(autoTPHeight); saveConfig() end
    end)
    local toggleBtn = Instance.new("TextButton", c)
    toggleBtn.Size = UDim2.new(0, 50, 0, 22)
    toggleBtn.Position = UDim2.new(1, -60, 0.5, -11)
    toggleBtn.BackgroundColor3 = autoTPEnabled and Color3.fromRGB(0,120,0) or Color3.fromRGB(50,50,60)
    toggleBtn.Text = autoTPEnabled and "ON" or "OFF"
    toggleBtn.TextColor3 = WHITE
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 10
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 5)
    toggleBtn.MouseButton1Click:Connect(function()
        autoTPEnabled = not autoTPEnabled
        if autoTPEnabled then startAutoTP() else stopAutoTP() end
        toggleBtn.BackgroundColor3 = autoTPEnabled and Color3.fromRGB(0,120,0) or Color3.fromRGB(50,50,60)
        toggleBtn.Text = autoTPEnabled and "ON" or "OFF"
        saveConfig()
    end)
end

-- ===== SETTINGS TAB =====
makeSecHeader("Settings", "Interface")
rowKBOnly("Settings", "Hide GUI", "", KB.GuiHide, function(k) KB.GuiHide.kb = k; saveConfig() end)
do
    local sv = rowToggle("Settings", "Show Mobile Buttons", "", true, function(on)
        setMobileButtonsVisible(on)
        saveConfig()
    end)
end
do
    local sv = rowToggle("Settings", "Move Mobile Buttons", "", mobileDraggingEnabled, function(on)
        mobileDraggingEnabled = on
        saveConfig()
    end)
end
do
    local sv = rowToggle("Settings", "Toggle Intro", "", introEnabled, function(on)
        introEnabled = on
        saveConfig()
    end)
end
do
    local sv = rowToggle("Settings", "Lock UI", "", guiLocked, function(on)
        guiLocked = on
        saveConfig()
    end)
end

-- Music Player
makeSecHeader("Settings", "Music Player")
do
    local songs = {
        "rbxassetid://101540104583507",
        "rbxassetid://125968616299811",
        "rbxassetid://123181826801671",
        "rbxassetid://139957878565852",
        "rbxassetid://71934965392436"
    }
    local currentSong = 1
    local musicSound = nil
    local musicPlaying = false
    local function playSong(index)
        if musicSound then musicSound:Stop(); musicSound:Destroy() end
        if index > #songs then index = 1 end
        currentSong = index
        local id = songs[index]
        local sound = Instance.new("Sound")
        sound.SoundId = id
        sound.Volume = 0.5
        sound.Looped = false
        sound.Parent = game:GetService("SoundService")
        local conn
        conn = sound.Stopped:Connect(function()
            if musicPlaying then playSong(currentSong + 1) end
            conn:Disconnect()
        end)
        sound:Play()
        musicSound = sound
        musicPlaying = true
        task.delay(2, function()
            if sound and sound.Playing == false and musicPlaying then
                sound:Destroy()
                playSong(currentSong + 1)
            end
        end)
    end
    local function stopMusic()
        if musicSound then musicSound:Stop(); musicSound:Destroy(); musicSound = nil end
        musicPlaying = false
    end
    local c = baseCard("Settings", 44)
    cLabel(c, "Music", 8, 100, 10, WHITE, Enum.Font.GothamBold)
    local playBtn = Instance.new("TextButton", c)
    playBtn.Size = UDim2.new(0, 40, 0, 24)
    playBtn.Position = UDim2.new(1, -130, 0.5, -12)
    playBtn.BackgroundColor3 = Color3.fromRGB(20,20,30)
    playBtn.BorderSizePixel = 0
    playBtn.Text = "Play"
    playBtn.TextColor3 = WHITE
    playBtn.Font = Enum.Font.GothamBold
    playBtn.TextSize = 10
    Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 5)
    local stopBtn = Instance.new("TextButton", c)
    stopBtn.Size = UDim2.new(0, 40, 0, 24)
    stopBtn.Position = UDim2.new(1, -80, 0.5, -12)
    stopBtn.BackgroundColor3 = Color3.fromRGB(20,20,30)
    stopBtn.BorderSizePixel = 0
    stopBtn.Text = "Stop"
    stopBtn.TextColor3 = WHITE
    stopBtn.Font = Enum.Font.GothamBold
    stopBtn.TextSize = 10
    Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 5)
    local nextBtn = Instance.new("TextButton", c)
    nextBtn.Size = UDim2.new(0, 40, 0, 24)
    nextBtn.Position = UDim2.new(1, -30, 0.5, -12)
    nextBtn.BackgroundColor3 = Color3.fromRGB(20,20,30)
    nextBtn.BorderSizePixel = 0
    nextBtn.Text = "Next"
    nextBtn.TextColor3 = WHITE
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextSize = 10
    Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 5)
    playBtn.MouseButton1Click:Connect(function() stopMusic(); playSong(1) end)
    stopBtn.MouseButton1Click:Connect(stopMusic)
    nextBtn.MouseButton1Click:Connect(function()
        if musicPlaying then playSong(currentSong + 1) else playSong(1) end
    end)
end

local sb = rowActionBtnWhite("Settings", "Save Config", function()
    saveConfig()
    if sb then local prev = sb.Text; sb.Text = "✓ Saved!"; task.wait(1.5); if sb then sb.Text = prev end end
end)
do
    local b = Instance.new("TextButton", pg("Settings"))
    b.Size = UDim2.new(1, 0, 0, 38)
    b.BackgroundColor3 = Color3.fromRGB(16,16,16)
    b.BorderSizePixel = 0
    b.Text = "Reset Button Positions"
    b.TextColor3 = Color3.fromRGB(235,235,235)
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 10
    b.LayoutOrder = lo("Settings")
    b.ZIndex = 5
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    Instance.new("UIStroke", b).Color = BORDER2
    b.MouseButton1Click:Connect(function()
        main.Position = UDim2.new(0, 40, 0, 40)
        dButton.Position = UDim2.new(1, -46, 0, 10)
        pbFrame.Position = UDim2.new(0.5, -120, 1, -65)
        local defaults = {
            LOCK   = UDim2.new(startX, -offsetX*1, startY, 0),
            PLAYL  = UDim2.new(startX, -offsetX*2, startY, 0),
            PLAYR  = UDim2.new(startX, -offsetX*1, startY+0.12, 0),
            AUTOL  = UDim2.new(startX, -offsetX*2, startY+0.12, 0),
            AUTOR  = UDim2.new(startX, -offsetX*1, startY+0.24, 0),
            DROP   = UDim2.new(startX, -offsetX*2, startY+0.24, 0),
            FLOAT  = UDim2.new(startX, -offsetX*1, startY+0.36, 0),
            CARRY  = UDim2.new(startX, -offsetX*2, startY+0.36, 0),
            LAGGER = UDim2.new(startX, -offsetX*1, startY+0.48, 0),
            TPDOWN = UDim2.new(startX, -offsetX*2, startY+0.48, 0),
        }
        for id, pos in pairs(defaults) do
            if mobileButtons[id] then mobileButtons[id].Position = pos end
        end
    end)
end

-- ===== SAVE/LOAD CONFIG =====
local function saveConfig()
    local mbPositions = {}
    for id, btn in pairs(mobileButtons) do
        if btn and btn.Parent then
            mbPositions[id] = {X=btn.Position.X.Scale, Xoff=btn.Position.X.Offset, Y=btn.Position.Y.Scale, Yoff=btn.Position.Y.Offset}
        end
    end
    local cfg = {
        normalSpeed = NS, carrySpeed = CS, laggerSpeed = LS,
        dropBrainrotKey = {kb=KB.DropBrainrot.kb.Name}, autoLeftKey = {kb=KB.AutoLeft.kb.Name},
        autoRightKey = {kb=KB.AutoRight.kb.Name}, autoBatKey = {kb=KB.AutoBat.kb.Name},
        laggerModeKey = {kb=KB.LaggerMode.kb.Name}, guiHideKey = {kb=KB.GuiHide.kb.Name},
        floatKey = {kb=KB.Float.kb.Name}, speedToggleKey = {kb=KB.SpeedToggle.kb.Name},
        tpDownKey = {kb=KB.TPDown.kb.Name},
        grabRadius = Steal.StealRadius, stealDuration = Steal.StealDuration,
        antiRagdoll = antiRagdollEnabled, autoStealEnabled = Steal.AutoStealEnabled,
        infiniteJump = infJumpEnabled, medusaCounter = medusaCounterEnabled,
        laggerMode = laggerMode, carryMode = speedMode, autoBat = autoBatEnabled,
        unwalkEnabled = unwalkEnabled, floatHeight = floatHeight, floatEnabled = floatEnabled,
        stretchRez = stretchRezEnabled, introEnabled = introEnabled,
        autoLeftEnabled = autoLeftEnabled, autoRightEnabled = autoRightEnabled,
        fullAutoLeftEnabled = fullAutoLeftEnabled, fullAutoRightEnabled = fullAutoRightEnabled,
        mobileDraggingEnabled = mobileDraggingEnabled,
        antiBatEnabled = antiBatEnabled, dropEnabled = dropEnabled,
        autoTPEnabled = autoTPEnabled, autoTPHeight = autoTPHeight,
        spamBatEnabled = spamBatEnabled, spamBatRange = spamBatRange,
        darkModeEnabled = darkModeEnabled, tryhardEnabled = tryhardEnabled,
        mobileButtons = mbPositions,
    }
    if writefile then pcall(function() writefile("DivineHubConfig.json", HttpService:JSONEncode(cfg)) end) end
end

local function loadConfig()
    if not (isfile and isfile("DivineHubConfig.json")) then return end
    local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile("DivineHubConfig.json")) end)
    if not ok or not cfg then return end
    local function lk(entry, data)
        if data and data.kb and Enum.KeyCode[data.kb] then entry.kb = Enum.KeyCode[data.kb] end
    end
    if cfg.normalSpeed then NS = cfg.normalSpeed; if normalBox then normalBox.Text = tostring(NS) end end
    if cfg.carrySpeed then CS = cfg.carrySpeed; if carryBox then carryBox.Text = tostring(CS) end end
    if cfg.laggerSpeed then LS = cfg.laggerSpeed; if laggerBox then laggerBox.Text = tostring(LS) end end
    if cfg.grabRadius then Steal.StealRadius = cfg.grabRadius; if progressRadLbl then progressRadLbl.Text = "Radius: " .. cfg.grabRadius end end
    if cfg.stealDuration then Steal.StealDuration = cfg.stealDuration; if durationInput then durationInput.Text = tostring(cfg.stealDuration) end end
    if cfg.floatHeight then floatHeight = cfg.floatHeight; if floatHeightBox then floatHeightBox.Text = tostring(cfg.floatHeight) end end
    lk(KB.DropBrainrot, cfg.dropBrainrotKey); lk(KB.AutoLeft, cfg.autoLeftKey)
    lk(KB.AutoRight, cfg.autoRightKey); lk(KB.AutoBat, cfg.autoBatKey)
    lk(KB.LaggerMode, cfg.laggerModeKey); lk(KB.GuiHide, cfg.guiHideKey)
    lk(KB.Float, cfg.floatKey); lk(KB.SpeedToggle, cfg.speedToggleKey)
    lk(KB.TPDown, cfg.tpDownKey)
    if cfg.antiRagdoll then antiRagdollEnabled = true; if setAntiRagVisual then setAntiRagVisual(true) end; startAntiRagdoll() end
    if cfg.autoStealEnabled then Steal.AutoStealEnabled = true; if setAutoStealVisual then setAutoStealVisual(true) end; startAutoSteal() end
    if cfg.infiniteJump then infJumpEnabled = true; if setInfJumpVisual then setInfJumpVisual(true) end end
    if cfg.medusaCounter then medusaCounterEnabled = true; if setMedusaVisual then setMedusaVisual(true) end; setupMedusa(LP.Character) end
    if cfg.laggerMode then laggerMode = true; if setLaggerVisual then setLaggerVisual(true) end; startLaggerMode() end
    if cfg.carryMode then speedMode = true; if modeValLbl then modeValLbl.Text = "Carry" end end
    if cfg.autoBat then autoBatEnabled = true; if autoBatSetVisual then autoBatSetVisual(true) end; startAimbot() end
    if cfg.unwalkEnabled then unwalkEnabled = true; if setUnwalkVisual then setUnwalkVisual(true) end; startUnwalk() end
    if cfg.floatEnabled then floatEnabled = true; if setFloat then setFloat(true) end; startFloat() end
    if cfg.stretchRez then stretchRezEnabled = true; if setStretchRezVisual then setStretchRezVisual(true) end; enableStretchRez() end
    if cfg.introEnabled ~= nil then introEnabled = cfg.introEnabled end
    if cfg.autoLeftEnabled ~= nil then autoLeftEnabled = cfg.autoLeftEnabled; if autoLeftEnabled then startPlayLeft() else stopPlayLeft() end; if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end end
    if cfg.autoRightEnabled ~= nil then autoRightEnabled = cfg.autoRightEnabled; if autoRightEnabled then startPlayRight() else stopPlayRight() end; if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end end
    if cfg.fullAutoLeftEnabled ~= nil then fullAutoLeftEnabled = cfg.fullAutoLeftEnabled; if fullAutoLeftEnabled then startFullAutoLeft() else stopFullAutoLeft() end; if fullAutoLeftSetter then fullAutoLeftSetter(fullAutoLeftEnabled) end end
    if cfg.fullAutoRightEnabled ~= nil then fullAutoRightEnabled = cfg.fullAutoRightEnabled; if fullAutoRightEnabled then startFullAutoRight() else stopFullAutoRight() end; if fullAutoRightSetter then fullAutoRightSetter(fullAutoRightEnabled) end end
    if cfg.mobileDraggingEnabled ~= nil then mobileDraggingEnabled = cfg.mobileDraggingEnabled end
    if cfg.antiBatEnabled ~= nil then antiBatEnabled = cfg.antiBatEnabled; if antiBatEnabled then startAntiBat() else stopAntiBat() end end
    if cfg.dropEnabled ~= nil then dropEnabled = cfg.dropEnabled; toggleDrop(dropEnabled) end
    if cfg.autoTPEnabled ~= nil then autoTPEnabled = cfg.autoTPEnabled; if autoTPEnabled then startAutoTP() else stopAutoTP() end end
    if cfg.autoTPHeight then autoTPHeight = math.clamp(cfg.autoTPHeight, 0, 50) end
    if cfg.spamBatEnabled ~= nil then spamBatEnabled = cfg.spamBatEnabled; if spamBatEnabled then startSpamBat() else stopSpamBat() end end
    if cfg.spamBatRange then spamBatRange = math.clamp(cfg.spamBatRange, 1, 100) end
    if cfg.darkModeEnabled ~= nil then darkModeEnabled = cfg.darkModeEnabled; applyDarkMode(darkModeEnabled) end
    if cfg.tryhardEnabled ~= nil then tryhardEnabled = cfg.tryhardEnabled; if tryhardEnabled then startTryhardAnim() else stopTryhardAnim() end end
    if cfg.mobileButtons then
        for id, pos in pairs(cfg.mobileButtons) do
            if mobileButtons[id] then mobileButtons[id].Position = UDim2.new(pos.X, pos.Xoff, pos.Y, pos.Yoff) end
        end
    end
end

switchTab("Speed")
loadConfig()
if autoLeftEnabled then startPlayLeft() else stopPlayLeft() end
if autoRightEnabled then startPlayRight() else stopPlayRight() end
if fullAutoLeftEnabled then startFullAutoLeft() else stopFullAutoLeft() end
if fullAutoRightEnabled then startFullAutoRight() else stopFullAutoRight() end
if autoBatEnabled then startAimbot() else stopAimbot() end
if floatEnabled then startFloat() end
if laggerMode then startLaggerMode() end
if speedMode and modeValLbl then modeValLbl.Text = "Carry" end
if antiBatEnabled then startAntiBat() end
if dropEnabled then toggleDrop(true) end
if autoTPEnabled then startAutoTP() end
if spamBatEnabled then startSpamBat() end
if tryhardEnabled then startTryhardAnim() end
setMobileButtonsVisible(true)

end -- buildGUI
buildGUI()

-- ===================== INTRO =====================
if introEnabled then
    task.wait(0.5)
    playIntro()
end

print("[Divine Hub v10] Fully loaded - Mobile buttons working, all features present.")
