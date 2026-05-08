local ANIMATION_MODE = "GUI"
local animationCompleted = false

if ANIMATION_MODE == "GUI" and game then
    local Players    = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local player     = Players.LocalPlayer

    local sg = Instance.new("ScreenGui")
    sg.Name = "LH_Intro"; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = player:WaitForChild("PlayerGui")

    local function makeTL(txt, size, y, color, stroke)
        local l = Instance.new("TextLabel", sg)
        l.Size = UDim2.new(0,500,0,size); l.Position = UDim2.new(0.5,-250,0.5,y)
        l.BackgroundTransparency=1; l.Text=txt; l.TextScaled=true
        l.Font=Enum.Font.GothamBlack; l.TextColor3=color
        l.TextStrokeTransparency=stroke and 0.3 or 1
        l.TextStrokeColor3=Color3.fromRGB(0,80,100)
        l.ZIndex=2; l.TextTransparency=1; return l
    end
    local t1 = makeTL("LIGHT HUB", 70, -75, Color3.fromRGB(255, 204, 255), true)
    local t2 = makeTL("V4", 42, 10,  Color3.fromRGB(255, 153, 255), true)
    local t3 = makeTL("Made By ws91z", 22, 62, Color3.fromRGB(229, 204, 255), false)

    task.spawn(function()
        local fi = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local fo = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        for _,l in ipairs({t1,t2,t3}) do TweenService:Create(l,fi,{TextTransparency=0}):Play() end
        task.wait(2)
        for _,l in ipairs({t1,t2,t3}) do TweenService:Create(l,fo,{TextTransparency=1}):Play() end
        task.wait(1.1); sg:Destroy(); animationCompleted=true
    end)
else
    animationCompleted = true
end

local function waitForAnim()
    while not animationCompleted do task.wait(0.1) end
    task.wait(0.4)
end

task.spawn(function()
    waitForAnim()
    task.spawn(function()

-- ============================================================
--   SERVICES
-- ============================================================
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")
local player         = Players.LocalPlayer

-- ============================================================
--   COLORS / THEME
-- ============================================================
local TH = {
    bg       = Color3.fromRGB(16, 16, 16),
    panel    = Color3.fromRGB(32, 32, 32),
    panel2   = Color3.fromRGB(64, 64, 64),
    panel3   = Color3.fromRGB(192, 192, 192),
    accent   = Color3.fromRGB(160, 160, 160),
    accent2  = Color3.fromRGB(128, 128, 128),
    green    = Color3.fromRGB(30, 220, 100),
    red      = Color3.fromRGB(220, 55, 55),
    off      = Color3.fromRGB(64, 64, 64),
    text     = Color3.fromRGB(255, 153, 255),
    muted    = Color3.fromRGB(255, 255, 255),
    gold     = Color3.fromRGB(255, 195, 55),
    purple   = Color3.fromRGB(145, 75, 255),
    divider  = Color3.fromRGB(204, 255, 204),
}

-- ============================================================
--   ALL ORIGINAL CZ HUB VARIABLES (unchanged)
-- ============================================================
NORMAL_SPEED=60; DESYNC_SPEED=46; LAGGER_SPEED=25
BEFORE_STEAL_SPEED=25; AFTER_STEAL_SPEED=12; SLOW_SPEED=29
STEAL_RADIUS=20; STEAL_DURATION=0.35; SPIN_SPEED=19
fovValue=70; AIMBOT_SPEED=60; BAT_ENGAGE_RANGE=5
DEFAULT_GRAVITY=196.2; GALAXY_GRAVITY=42; GALAXY_HOP=35
HOP_COOLDOWN=0.08; INF_JUMP_FORCE=54; CLAMP_FALL=80; MELEE_OFFSET=3

speedMode="NORMAL"; desyncEnabled=false; lagSpeedEnabled=false
aplOn=false; aprOn=false; aplPhase=1; aprPhase=1; aplConn=nil; aprConn=nil
autoLOn=false; autoROn=false; autoLConn=nil; autoRConn=nil; autoLPhase=1; autoRPhase=1
autoStealEnabled=false; isStealing=false; stealStartTime=nil
autoStealConn=nil; progressConn=nil
antiRagdollEnabled=false; unwalkEnabled=false; unwalkConn=nil
batAimbotEnabled=false; aimbotConnection=nil
galaxyEnabled=false; hopsEnabled=false; galaxyVF=nil; galaxyAtt=nil
spinBotEnabled=false; spinBAV=nil
espEnabled=true; espConns={}
optimizerEnabled=false; xrayOrig={}; fovConn=nil
slowDownEnabled=true; infJumpEnabled=true
spaceHeld=false; lastHop=0
gChar=nil; gHum=nil; gHrp=nil
ProgressBarFill=nil; ProgressLabel=nil; ProgressPctLabel=nil
animalCache={}; promptCache={}; stealCache={}
toggleSetters={}; AntiRagdollConns={}
autoSaveEnabled=false
brainrotDefenseEnabled=false; brainrotDefenseConn=nil; brainrotDefenseSide="left"
medusaCounterEnabled=false
goodAnimEnabled=false; goodAnimConn=nil
wasRagdolled=false; alreadyTP=false

POS_L1=Vector3.new(-476.48,-6.28,92.73); POS_L2=Vector3.new(-483.12,-4.95,94.80)
POS_R1=Vector3.new(-476.16,-6.52,25.62); POS_R2=Vector3.new(-483.04,-5.09,23.14)
FAP_L1=Vector3.new(-476.48,-6.28,92.73); FAP_L2=Vector3.new(-482.85,-5.03,93.13)
FAP_L3=Vector3.new(-475.68,-6.89,92.76); FAP_L4=Vector3.new(-476.50,-6.46,27.58); FAP_L5=Vector3.new(-482.42,-5.03,27.84)
FAP_R1=Vector3.new(-476.16,-6.52,25.62); FAP_R2=Vector3.new(-483.06,-5.03,27.51)
FAP_R3=Vector3.new(-476.21,-6.63,27.46); FAP_R4=Vector3.new(-476.66,-6.39,92.44); FAP_R5=Vector3.new(-481.94,-5.03,92.42)
DEFENSE_LEFT_FINAL=Vector3.new(-483.59,-5.04,104.24)
DEFENSE_RIGHT_FINAL=Vector3.new(-483.51,-5.10,18.89)
CHECKPOINT_A=Vector3.new(-472.60,-7.00,57.52)
CHECKPOINT_L=Vector3.new(-472.65,-7.00,95.69)
CHECKPOINT_R=Vector3.new(-471.76,-7.00,26.22)

local BAT_SWING_COOLDOWN=0.12; local lastBatSwing=0

Keybinds={
    AutoLeft=Enum.KeyCode.Q, AutoRight=Enum.KeyCode.E,
    AutoSteal=Enum.KeyCode.V, BatAimbot=Enum.KeyCode.Z,
    AntiRagdoll=Enum.KeyCode.X, Unwalk=Enum.KeyCode.N,
    CarrySpd=Enum.KeyCode.F7, Drop=Enum.KeyCode.F3, TPDown=Enum.KeyCode.G,
    MobAutoL=Enum.KeyCode.Unknown, MobAutoR=Enum.KeyCode.Unknown
}

-- ============================================================
--   HELPERS
-- ============================================================
local function getHRP() local c=player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getCurrentSpeed()
    if speedMode=="LAGGER" then return LAGGER_SPEED
    elseif speedMode=="DESYNC" then return DESYNC_SPEED
    else return NORMAL_SPEED end
end

-- ============================================================
--   CONFIG SAVE/LOAD
-- ============================================================
local CONFIG_KEY="LH_V4_Config"
local function saveConfig()
    pcall(function()
        if not writefile then return end
        local d={NORMAL_SPEED=NORMAL_SPEED,DESYNC_SPEED=DESYNC_SPEED,LAGGER_SPEED=LAGGER_SPEED,
            BEFORE_STEAL_SPEED=BEFORE_STEAL_SPEED,AFTER_STEAL_SPEED=AFTER_STEAL_SPEED,
            STEAL_RADIUS=STEAL_RADIUS,STEAL_DURATION=STEAL_DURATION,SPIN_SPEED=SPIN_SPEED,
            fovValue=fovValue,AIMBOT_SPEED=AIMBOT_SPEED,speedMode=speedMode,
            desyncEnabled=desyncEnabled,antiRagdollEnabled=antiRagdollEnabled,
            unwalkEnabled=unwalkEnabled,spinBotEnabled=spinBotEnabled,
            slowDownEnabled=slowDownEnabled,galaxyEnabled=galaxyEnabled,
            optimizerEnabled=optimizerEnabled,autoStealEnabled=autoStealEnabled,
            batAimbotEnabled=batAimbotEnabled,autoSaveEnabled=autoSaveEnabled,
            brainrotDefenseEnabled=brainrotDefenseEnabled,brainrotDefenseSide=brainrotDefenseSide,
            medusaCounterEnabled=medusaCounterEnabled,goodAnimEnabled=goodAnimEnabled,
            infJumpEnabled=infJumpEnabled,espEnabled=espEnabled}
        writefile(CONFIG_KEY..".json",HttpService:JSONEncode(d))
    end)
end
local function loadConfig()
    pcall(function()
        if not(readfile and isfile and isfile(CONFIG_KEY..".json")) then return end
        local ok,d=pcall(function() return HttpService:JSONDecode(readfile(CONFIG_KEY..".json")) end)
        if not ok or not d then return end
        if d.NORMAL_SPEED then NORMAL_SPEED=d.NORMAL_SPEED end
        if d.DESYNC_SPEED then DESYNC_SPEED=d.DESYNC_SPEED end
        if d.LAGGER_SPEED then LAGGER_SPEED=d.LAGGER_SPEED end
        if d.BEFORE_STEAL_SPEED then BEFORE_STEAL_SPEED=d.BEFORE_STEAL_SPEED end
        if d.AFTER_STEAL_SPEED then AFTER_STEAL_SPEED=d.AFTER_STEAL_SPEED end
        if d.STEAL_RADIUS then STEAL_RADIUS=d.STEAL_RADIUS end
        if d.STEAL_DURATION then STEAL_DURATION=d.STEAL_DURATION end
        if d.SPIN_SPEED then SPIN_SPEED=d.SPIN_SPEED end
        if d.fovValue then fovValue=d.fovValue end
        if d.speedMode then speedMode=d.speedMode end
        if d.desyncEnabled~=nil then desyncEnabled=d.desyncEnabled end
        if d.antiRagdollEnabled~=nil then antiRagdollEnabled=d.antiRagdollEnabled end
        if d.espEnabled~=nil then espEnabled=d.espEnabled end
        if d.brainrotDefenseSide then brainrotDefenseSide=d.brainrotDefenseSide end
        if d.autoSaveEnabled~=nil then autoSaveEnabled=d.autoSaveEnabled end
        if d.infJumpEnabled~=nil then infJumpEnabled=d.infJumpEnabled end
    end)
end
loadConfig()

-- ============================================================
--   ALL ORIGINAL FEATURE FUNCTIONS (unchanged logic)
-- ============================================================

-- INF JUMP
UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local h=getHRP(); if not h then return end
    h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,INF_JUMP_FORCE,h.AssemblyLinearVelocity.Z)
end)
RunService.Heartbeat:Connect(function()
    if not infJumpEnabled then return end
    local h=getHRP(); if not h then return end
    if h.AssemblyLinearVelocity.Y<-CLAMP_FALL then
        h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,-CLAMP_FALL,h.AssemblyLinearVelocity.Z)
    end
end)

-- GALAXY
local function setupGalaxyForce()
    local h=getHRP(); if not h then return end
    if galaxyVF then galaxyVF:Destroy() end; if galaxyAtt then galaxyAtt:Destroy() end
    galaxyAtt=Instance.new("Attachment"); galaxyAtt.Parent=h
    galaxyVF=Instance.new("VectorForce"); galaxyVF.Attachment0=galaxyAtt
    galaxyVF.ApplyAtCenterOfMass=true; galaxyVF.RelativeTo=Enum.ActuatorRelativeTo.World
    galaxyVF.Force=Vector3.zero; galaxyVF.Parent=h
end
local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVF or not gChar then return end
    local mass=0; for _,p in ipairs(gChar:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end
    local tg=DEFAULT_GRAVITY*(GALAXY_GRAVITY/100); galaxyVF.Force=Vector3.new(0,mass*(DEFAULT_GRAVITY-tg)*0.95,0)
end
local function startGalaxy() galaxyEnabled=true; hopsEnabled=true; pcall(setupGalaxyForce) end
local function stopGalaxy()
    galaxyEnabled=false; hopsEnabled=false
    if galaxyVF then galaxyVF:Destroy(); galaxyVF=nil end
    if galaxyAtt then galaxyAtt:Destroy(); galaxyAtt=nil end
end
local function doHop()
    local h=getHRP(); local hh=getHum(); if not h or not hh then return end
    if tick()-lastHop<HOP_COOLDOWN then return end; lastHop=tick()
    if hh.FloorMaterial==Enum.Material.Air then
        h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,GALAXY_HOP,h.AssemblyLinearVelocity.Z)
    end
end

-- SPINBOT
local function startSpin()
    local c=player.Character; if not c then return end
    local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
    if spinBAV then spinBAV:Destroy() end
    spinBAV=Instance.new("BodyAngularVelocity"); spinBAV.Name="LH_SpinBAV"
    spinBAV.MaxTorque=Vector3.new(0,math.huge,0); spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0); spinBAV.Parent=root
end
local function stopSpin() if spinBAV then spinBAV:Destroy(); spinBAV=nil end end

-- ESP
local function createESP(plr)
    if plr==player or not plr.Character then return end
    local c=plr.Character; local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
    if c:FindFirstChild("LH_ESP") then return end
    local box=Instance.new("BoxHandleAdornment"); box.Name="LH_ESP"; box.Adornee=root
    box.Size=Vector3.new(4,6,2); box.Color3=TH.accent; box.Transparency=0.45; box.ZIndex=10; box.AlwaysOnTop=true; box.Parent=c
    local head=c:FindFirstChild("Head")
    local bb=Instance.new("BillboardGui"); bb.Name="LH_ESP_Name"; bb.Adornee=head or root
    bb.Size=UDim2.new(0,200,0,45); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=c
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Text=plr.DisplayName; lbl.TextColor3=TH.accent; lbl.Font=Enum.Font.GothamBold
    lbl.TextScaled=true; lbl.TextStrokeTransparency=0.5; lbl.TextStrokeColor3=TH.accent2; lbl.Parent=bb
end
local function removeESP(plr)
    if not plr.Character then return end
    local b=plr.Character:FindFirstChild("LH_ESP"); local n=plr.Character:FindFirstChild("LH_ESP_Name")
    if b then b:Destroy() end; if n then n:Destroy() end
end
local function enableESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            if plr.Character then pcall(function() createESP(plr) end) end
            table.insert(espConns, plr.CharacterAdded:Connect(function() task.wait(0.1); if espEnabled then pcall(function() createESP(plr) end) end end))
        end
    end
    table.insert(espConns, Players.PlayerAdded:Connect(function(plr)
        if plr==player then return end
        table.insert(espConns, plr.CharacterAdded:Connect(function() task.wait(0.1); if espEnabled then pcall(function() createESP(plr) end) end end))
    end))
end
local function disableESP()
    for _,plr in ipairs(Players:GetPlayers()) do pcall(function() removeESP(plr) end) end
    for _,c in ipairs(espConns) do if c and c.Connected then c:Disconnect() end end; espConns={}
end

-- ANTI RAGDOLL
local function startAntiRagdoll()
    if #AntiRagdollConns>0 then return end
    local c=player.Character or player.CharacterAdded:Wait()
    local humanoid=c:WaitForChild("Humanoid"); local root=c:WaitForChild("HumanoidRootPart")
    local animator=humanoid:WaitForChild("Animator")
    local function IsRag() local s=humanoid:GetState(); return s==Enum.HumanoidStateType.Physics or s==Enum.HumanoidStateType.Ragdoll or s==Enum.HumanoidStateType.FallingDown or s==Enum.HumanoidStateType.GettingUp end
    local function Clean()
        for _,obj in pairs(c:GetDescendants()) do
            if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") then obj:Destroy()
            elseif obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then obj:Destroy()
            elseif obj:IsA("Motor6D") then obj.Enabled=true end
        end
    end
    local function ReEn() pcall(function() require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Enable() end) end
    table.insert(AntiRagdollConns, humanoid.StateChanged:Connect(function() if IsRag() then humanoid:ChangeState(Enum.HumanoidStateType.Running); Clean(); workspace.CurrentCamera.CameraSubject=humanoid; ReEn() end end))
    table.insert(AntiRagdollConns, RunService.Heartbeat:Connect(function() if not antiRagdollEnabled then return end; if IsRag() then Clean() end end))
    table.insert(AntiRagdollConns, player.CharacterAdded:Connect(function(nc) c=nc; humanoid=nc:WaitForChild("Humanoid"); root=nc:WaitForChild("HumanoidRootPart"); animator=humanoid:WaitForChild("Animator"); ReEn(); Clean() end))
    ReEn(); Clean()
end
local function stopAntiRagdoll() for _,conn in pairs(AntiRagdollConns) do conn:Disconnect() end; AntiRagdollConns={} end

-- UNWALK
local function startUnwalk()
    local c=player.Character; if not c then return end
    local hh=c:FindFirstChildOfClass("Humanoid"); if not hh then return end
    local anim=hh:FindFirstChildOfClass("Animator"); if not anim then return end
    for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn=RunService.Heartbeat:Connect(function()
        if not unwalkEnabled then unwalkConn:Disconnect(); unwalkConn=nil; return end
        local cc=player.Character; if not cc then return end
        local hhn=cc:FindFirstChildOfClass("Humanoid"); if not hhn then return end
        local an=hhn:FindFirstChildOfClass("Animator"); if not an then return end
        for _,t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end
    end)
end
local function stopUnwalk() if unwalkConn then unwalkConn:Disconnect(); unwalkConn=nil end end

-- OPTIMIZER
local function enableOptimizer()
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01; Lighting.GlobalShadows=false; Lighting.Brightness=2; Lighting.FogEnd=9e9; for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=false end end end)
    pcall(function() for _,obj in ipairs(workspace:GetDescendants()) do pcall(function() if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled=false; obj:Destroy() elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.Plastic end end) end end)
    pcall(function() for _,obj in ipairs(workspace:GetDescendants()) do if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then xrayOrig[obj]=obj.LocalTransparencyModifier; obj.LocalTransparencyModifier=0.88 end end end)
end
local function disableOptimizer()
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic; Lighting.GlobalShadows=true end)
    for part,val in pairs(xrayOrig) do if part and part.Parent then part.LocalTransparencyModifier=val end end; xrayOrig={}
end

-- FOV
local function applyFOV()
    if fovConn then fovConn:Disconnect() end
    fovConn=RunService.RenderStepped:Connect(function() workspace.CurrentCamera.FieldOfView=fovValue end)
end

-- DROP
local _wfConns={}; local _wfActive=false
local function startWalkFling()
    _wfActive=true
    table.insert(_wfConns, RunService.Stepped:Connect(function()
        if not _wfActive then return end
        for _,p in ipairs(Players:GetPlayers()) do if p~=player and p.Character then for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end end end
    end))
    local co=coroutine.create(function()
        while _wfActive do RunService.Heartbeat:Wait(); local c=player.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); if not root then continue end; local vel=root.Velocity; root.Velocity=vel*10000+Vector3.new(0,10000,0); RunService.RenderStepped:Wait(); if root and root.Parent then root.Velocity=vel end; RunService.Stepped:Wait(); if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end end
    end); coroutine.resume(co); table.insert(_wfConns,co)
end
local function stopWalkFling() _wfActive=false; for _,c in ipairs(_wfConns) do if typeof(c)=="RBXScriptConnection" then c:Disconnect() elseif typeof(c)=="thread" then pcall(task.cancel,c) end end; _wfConns={} end
local function doDrop() startWalkFling(); task.delay(0.4, stopWalkFling) end

-- TP DOWN
local function doTPDown()
    task.spawn(function() pcall(function()
        local c=player.Character; if not c then return end
        local hrp=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid"); if not hrp or not hum then return end
        local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
        local hit=workspace:Raycast(hrp.Position,Vector3.new(0,-600,0),rp)
        if hit then hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero; local hh=hum.HipHeight or 2; local hy=hrp.Size.Y/2; hrp.CFrame=CFrame.new(hit.Position.X,hit.Position.Y+hh+hy+0.1,hit.Position.Z); hrp.AssemblyLinearVelocity=Vector3.zero end
    end) end)
end

-- LAG SPEED
local lagSpeedConn=nil
local function startLagSpeed()
    if lagSpeedConn then lagSpeedConn:Disconnect() end
    local toggle=true
    lagSpeedConn=RunService.Heartbeat:Connect(function()
        if not lagSpeedEnabled then return end
        local h=getHRP(); if not h then return end
        local spd=toggle and getCurrentSpeed() or getCurrentSpeed()*0.3; toggle=not toggle
        local md=gHum and gHum.MoveDirection or Vector3.zero
        if md.Magnitude>0.1 then h.AssemblyLinearVelocity=Vector3.new(md.X*spd,h.AssemblyLinearVelocity.Y,md.Z*spd) end
    end)
end
local function stopLagSpeed() if lagSpeedConn then lagSpeedConn:Disconnect(); lagSpeedConn=nil end end

-- BAT AIMBOT
local aimbotHighlight=Instance.new("Highlight"); aimbotHighlight.Name="IK_AimbotESP"; aimbotHighlight.FillColor=TH.accent; aimbotHighlight.OutlineColor=Color3.fromRGB(255,255,255); aimbotHighlight.FillTransparency=0.5; aimbotHighlight.OutlineTransparency=0
pcall(function() aimbotHighlight.Parent=player:WaitForChild("PlayerGui") end)
local function isTargetValid(tc) if not tc then return false end; local h=tc:FindFirstChildOfClass("Humanoid"); local r=tc:FindFirstChild("HumanoidRootPart"); local ff=tc:FindFirstChildOfClass("ForceField"); return h and r and h.Health>0 and not ff end
local function getBestTarget(myHRP) local s=math.huge; local bC,bR=nil,nil; for _,p in ipairs(Players:GetPlayers()) do if p~=player and isTargetValid(p.Character) then local tr=p.Character:FindFirstChild("HumanoidRootPart"); if tr then local d=(tr.Position-myHRP.Position).Magnitude; if d<s then s=d; bR=tr; bC=p.Character end end end end; return bR,bC end
local function findBatTool() local c=player.Character; if not c then return nil end; local bp=player:FindFirstChildOfClass("Backpack"); local nl={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}; for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end; if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end; for _,n in ipairs(nl) do local t=c:FindFirstChild(n) or (bp and bp:FindFirstChild(n)); if t then return t end end end
local function startBatAimbot()
    if aimbotConnection then return end
    local c=player.Character; if not c then return end
    local h=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid"); if not h or not hum then return end
    hum.AutoRotate=false
    local att=h:FindFirstChild("IK_Att") or Instance.new("Attachment",h); att.Name="IK_Att"
    local al=h:FindFirstChild("IK_Al") or Instance.new("AlignOrientation",h); al.Name="IK_Al"; al.Mode=Enum.OrientationAlignmentMode.OneAttachment; al.Attachment0=att; al.MaxTorque=math.huge; al.Responsiveness=200
    batAimbotEnabled=true
    aimbotConnection=RunService.Heartbeat:Connect(function()
        if not batAimbotEnabled then return end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local now=tick(); local cHRP=player.Character.HumanoidRootPart; local cHum=player.Character:FindFirstChildOfClass("Humanoid")
        local bat=findBatTool(); if bat and bat.Parent~=player.Character then pcall(function() cHum:EquipTool(bat) end) end
        local tHRP,tChar=getBestTarget(cHRP)
        if tHRP and tChar then
            aimbotHighlight.Adornee=tChar
            local tVel=tHRP.AssemblyLinearVelocity; local pt=math.clamp(tVel.Magnitude/150,0.05,0.2)
            local pPos=tHRP.Position+(tVel*pt); al.CFrame=CFrame.lookAt(cHRP.Position,pPos)
            local dir=pPos-cHRP.Position; local dist=dir.Magnitude
            local standPos=dist>0 and (pPos-(dir.Unit*MELEE_OFFSET)) or pPos
            local mDir=standPos-cHRP.Position; local ds=mDir.Magnitude
            if ds>1 then cHRP.AssemblyLinearVelocity=mDir.Unit*AIMBOT_SPEED else cHRP.AssemblyLinearVelocity=tVel end
            if ds<=BAT_ENGAGE_RANGE then if bat and bat.Parent==player.Character and (now-lastBatSwing)>=BAT_SWING_COOLDOWN then lastBatSwing=now; pcall(function() bat:Activate() end) end end
        else cHRP.AssemblyLinearVelocity=Vector3.zero; aimbotHighlight.Adornee=nil end
    end)
end
local function stopBatAimbot()
    batAimbotEnabled=false; if aimbotConnection then aimbotConnection:Disconnect(); aimbotConnection=nil end
    local c=player.Character; local h=c and c:FindFirstChild("HumanoidRootPart"); local hum=c and c:FindFirstChildOfClass("Humanoid")
    if h then local at=h:FindFirstChild("IK_Att"); if at then at:Destroy() end; local al=h:FindFirstChild("IK_Al"); if al then al:Destroy() end; h.AssemblyLinearVelocity=Vector3.zero end
    if hum then hum.AutoRotate=true end; aimbotHighlight.Adornee=nil
end

-- AUTO MOVEMENT
local function stopAutoL() autoLOn=false; if autoLConn then autoLConn:Disconnect(); autoLConn=nil end; autoLPhase=1; local h=getHRP(); if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end end
local function stopAutoR() autoROn=false; if autoRConn then autoRConn:Disconnect(); autoRConn=nil end; autoRPhase=1; local h=getHRP(); if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end end
local function startAutoL()
    if autoLConn then autoLConn:Disconnect() end; autoLPhase=1
    local pts={FAP_L1,FAP_L2,FAP_L3,FAP_L4,FAP_L5}
    autoLConn=RunService.Heartbeat:Connect(function()
        if not autoLOn or not gHrp or not gHum then return end
        local ph=autoLPhase; local tgt=pts[ph]; local spd=ph>=3 and SLOW_SPEED or getCurrentSpeed()
        local flat=Vector3.new(tgt.X-gHrp.Position.X,0,tgt.Z-gHrp.Position.Z)
        if flat.Magnitude<1 then
            if ph==5 then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; autoLOn=false; stopAutoL(); if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](false) end; return
            elseif ph==2 then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; task.wait(0.05); autoLPhase=3; return
            else autoLPhase=ph+1; return end
        end
        local md=flat.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,gHrp.AssemblyLinearVelocity.Y,md.Z*spd)
    end)
end
local function startAutoR()
    if autoRConn then autoRConn:Disconnect() end; autoRPhase=1
    local pts={FAP_R1,FAP_R2,FAP_R3,FAP_R4,FAP_R5}
    autoRConn=RunService.Heartbeat:Connect(function()
        if not autoROn or not gHrp or not gHum then return end
        local ph=autoRPhase; local tgt=pts[ph]; local spd=ph>=3 and SLOW_SPEED or getCurrentSpeed()
        local flat=Vector3.new(tgt.X-gHrp.Position.X,0,tgt.Z-gHrp.Position.Z)
        if flat.Magnitude<1 then
            if ph==5 then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; autoROn=false; stopAutoR(); if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](false) end; return
            elseif ph==2 then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; task.wait(0.05); autoRPhase=3; return
            else autoRPhase=ph+1; return end
        end
        local md=flat.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,gHrp.AssemblyLinearVelocity.Y,md.Z*spd)
    end)
end
local function stopAutoPlayLeft() aplOn=false; if aplConn then aplConn:Disconnect(); aplConn=nil end; aplPhase=1; local h=getHRP(); if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end end
local function stopAutoPlayRight() aprOn=false; if aprConn then aprConn:Disconnect(); aprConn=nil end; aprPhase=1; local h=getHRP(); if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end end
local function startAutoPlayLeft()
    if aplConn then aplConn:Disconnect() end; aplPhase=1
    aplConn=RunService.Heartbeat:Connect(function()
        if not aplOn or not gHrp or not gHum then return end
        local targets={POS_L1,POS_L2}; local tp=targets[aplPhase]
        local d=Vector3.new(tp.X-gHrp.Position.X,0,tp.Z-gHrp.Position.Z)
        if d.Magnitude<1 then if aplPhase==#targets then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; aplOn=false; stopAutoPlayLeft(); if toggleSetters["Play Left"] then toggleSetters["Play Left"](false) end; return end; aplPhase=aplPhase+1
        else local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*getCurrentSpeed(),gHrp.AssemblyLinearVelocity.Y,md.Z*getCurrentSpeed()) end
    end)
end
local function startAutoPlayRight()
    if aprConn then aprConn:Disconnect() end; aprPhase=1
    aprConn=RunService.Heartbeat:Connect(function()
        if not aprOn or not gHrp or not gHum then return end
        local targets={POS_R1,POS_R2}; local tp=targets[aprPhase]
        local d=Vector3.new(tp.X-gHrp.Position.X,0,tp.Z-gHrp.Position.Z)
        if d.Magnitude<1 then if aprPhase==#targets then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; aprOn=false; stopAutoPlayRight(); if toggleSetters["Play Right"] then toggleSetters["Play Right"](false) end; return end; aprPhase=aprPhase+1
        else local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*getCurrentSpeed(),gHrp.AssemblyLinearVelocity.Y,md.Z*getCurrentSpeed()) end
    end)
end

-- AUTO STEAL
local function isMyBase(pn) local pl=workspace:FindFirstChild("Plots"); if not pl then return false end; local p=pl:FindFirstChild(pn); if not p then return false end; local s=p:FindFirstChild("PlotSign"); if not s then return false end; local yb=s:FindFirstChild("YourBase"); return yb and yb:IsA("BillboardGui") and yb.Enabled end
local function scanPlot(plot) if not plot or not plot:IsA("Model") then return end; if isMyBase(plot.Name) then return end; local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then return end; for _,pod in ipairs(pods:GetChildren()) do if pod:IsA("Model") and pod:FindFirstChild("Base") then table.insert(animalCache,{plot=plot.Name,slot=pod.Name,worldPosition=pod:GetPivot().Position,uid=plot.Name.."_"..pod.Name}) end end end
local function findPromptForAnimal(ad) if not ad then return nil end; local cp=promptCache[ad.uid]; if cp and cp.Parent then return cp end; local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end; local plot=plots:FindFirstChild(ad.plot); if not plot then return nil end; local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end; local pod=pods:FindFirstChild(ad.slot); if not pod then return nil end; local base=pod:FindFirstChild("Base"); if not base then return nil end; local sp=base:FindFirstChild("Spawn"); if not sp then return nil end; local att=sp:FindFirstChild("PromptAttachment"); if not att then return nil end; for _,p in ipairs(att:GetChildren()) do if p:IsA("ProximityPrompt") then promptCache[ad.uid]=p; return p end end end
local function buildCallbacks(prompt) if stealCache[prompt] then return end; local data={hold={},trigger={},ready=true}; pcall(function() if getconnections then for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if type(c.Function)=="function" then table.insert(data.hold,c.Function) end end; for _,c in ipairs(getconnections(prompt.Triggered)) do if type(c.Function)=="function" then table.insert(data.trigger,c.Function) end end end end); if #data.hold>0 or #data.trigger>0 then stealCache[prompt]=data end end
local function execSteal(prompt)
    local data=stealCache[prompt]; if not data or not data.ready then return false end; data.ready=false; isStealing=true; stealStartTime=tick()
    if ProgressLabel then ProgressLabel.Text="STEALING..." end
    if progressConn then progressConn:Disconnect() end
    progressConn=RunService.Heartbeat:Connect(function() if not isStealing then progressConn:Disconnect(); return end; local prog=math.clamp((tick()-stealStartTime)/STEAL_DURATION,0,1); if ProgressBarFill then ProgressBarFill.Size=UDim2.new(prog,0,1,0) end; if ProgressPctLabel then ProgressPctLabel.Text=math.floor(prog*100).."%" end end)
    task.spawn(function() for _,f in ipairs(data.hold) do task.spawn(f) end; task.wait(STEAL_DURATION); for _,f in ipairs(data.trigger) do task.spawn(f) end; if progressConn then progressConn:Disconnect() end; if ProgressLabel then ProgressLabel.Text="READY" end; if ProgressPctLabel then ProgressPctLabel.Text="" end; if ProgressBarFill then ProgressBarFill.Size=UDim2.new(0,0,1,0) end; data.ready=true; isStealing=false end)
    return true
end
local function nearestAnimal() local h=getHRP(); if not h then return nil end; local best,bestD=nil,math.huge; for _,ad in ipairs(animalCache) do if not isMyBase(ad.plot) and ad.worldPosition then local d=(h.Position-ad.worldPosition).Magnitude; if d<bestD then bestD=d; best=ad end end end; return best end
local function startAutoSteal() if autoStealConn then return end; autoStealConn=RunService.Heartbeat:Connect(function() if not autoStealEnabled or isStealing then return end; local target=nearestAnimal(); if not target then return end; local h=getHRP(); if not h then return end; if (h.Position-target.worldPosition).Magnitude>STEAL_RADIUS then return end; local prompt=promptCache[target.uid]; if not prompt or not prompt.Parent then prompt=findPromptForAnimal(target) end; if prompt then buildCallbacks(prompt); execSteal(prompt) end end) end
local function stopAutoSteal() if autoStealConn then autoStealConn:Disconnect(); autoStealConn=nil end; isStealing=false; if progressConn then progressConn:Disconnect(); progressConn=nil end; if ProgressBarFill then ProgressBarFill.Size=UDim2.new(0,0,1,0) end; if ProgressLabel then ProgressLabel.Text="READY" end; if ProgressPctLabel then ProgressPctLabel.Text="" end end

task.spawn(function() task.wait(2); local plots=workspace:WaitForChild("Plots",10); if not plots then return end; for _,p in ipairs(plots:GetChildren()) do if p:IsA("Model") then scanPlot(p) end end; plots.ChildAdded:Connect(function(p) if p:IsA("Model") then task.wait(0.5); scanPlot(p) end end); task.spawn(function() while task.wait(5) do animalCache={}; for _,p in ipairs(plots:GetChildren()) do if p:IsA("Model") then scanPlot(p) end end end end) end)

-- BRAINROT DEFENSE
local function doVortexTP(char) if alreadyTP then return end; alreadyTP=true; task.spawn(function() task.wait(0.15); local cc=player.Character; if not cc then alreadyTP=false; return end; for _,v in ipairs(cc:GetDescendants()) do if v:IsA("BasePart") then v.AssemblyLinearVelocity=Vector3.zero; v.AssemblyAngularVelocity=Vector3.zero end end; if brainrotDefenseSide=="left" then cc:PivotTo(CFrame.new(CHECKPOINT_A+Vector3.new(0,3,0))); task.wait(0.08); cc:PivotTo(CFrame.new(CHECKPOINT_L+Vector3.new(0,3,0))); task.wait(0.08); cc:PivotTo(CFrame.new(DEFENSE_LEFT_FINAL+Vector3.new(0,3,0))) else cc:PivotTo(CFrame.new(CHECKPOINT_A+Vector3.new(0,3,0))); task.wait(0.08); cc:PivotTo(CFrame.new(CHECKPOINT_R+Vector3.new(0,3,0))); task.wait(0.08); cc:PivotTo(CFrame.new(DEFENSE_RIGHT_FINAL+Vector3.new(0,3,0))) end; task.wait(1.5); alreadyTP=false end) end
local function checkRagdollState(c) local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return false end; local state=hum:GetState(); return state==Enum.HumanoidStateType.Physics or state==Enum.HumanoidStateType.FallingDown or state==Enum.HumanoidStateType.Ragdoll end
local function startBrainrotDefense() if brainrotDefenseConn then return end; brainrotDefenseConn=RunService.Heartbeat:Connect(function() if not brainrotDefenseEnabled then return end; if batAimbotEnabled or aplOn or aprOn or autoLOn or autoROn then return end; local c=player.Character; if not c then return end; local ragNow=checkRagdollState(c); if ragNow and not wasRagdolled then doVortexTP(c) end; wasRagdolled=ragNow end); player.CharacterAdded:Connect(function() alreadyTP=false; wasRagdolled=false end) end
local function stopBrainrotDefense() if brainrotDefenseConn then brainrotDefenseConn:Disconnect(); brainrotDefenseConn=nil end end

-- GOOD ANIMATION
local Anims={idle1="rbxassetid://133806214992291",idle2="rbxassetid://94970088341563",walk="rbxassetid://707897309",run="rbxassetid://707861613",jump="rbxassetid://116936326516985",fall="rbxassetid://116936326516985",climb="rbxassetid://116936326516985",swim="rbxassetid://116936326516985",swimidle="rbxassetid://116936326516985"}
local origAnims=nil
local function saveOrigAnims(char) local a=char:FindFirstChild("Animate"); if not a then return end; local function g(o) return o and o.AnimationId or nil end; origAnims={idle1=g(a.idle and a.idle.Animation1),idle2=g(a.idle and a.idle.Animation2),walk=g(a.walk and a.walk.WalkAnim),run=g(a.run and a.run.RunAnim),jump=g(a.jump and a.jump.JumpAnim),fall=g(a.fall and a.fall.FallAnim),climb=g(a.climb and a.climb.ClimbAnim),swim=g(a.swim and a.swim.Swim),swimidle=g(a.swimidle and a.swimidle.SwimIdle)} end
local function applyGoodAnims(char) local a=char:FindFirstChild("Animate"); if not a then return end; local function s(o,id) if o then o.AnimationId=id end end; s(a.idle and a.idle.Animation1,Anims.idle1); s(a.idle and a.idle.Animation2,Anims.idle2); s(a.walk and a.walk.WalkAnim,Anims.walk); s(a.run and a.run.RunAnim,Anims.run); s(a.jump and a.jump.JumpAnim,Anims.jump); s(a.fall and a.fall.FallAnim,Anims.fall); s(a.climb and a.climb.ClimbAnim,Anims.climb); s(a.swim and a.swim.Swim,Anims.swim); s(a.swimidle and a.swimidle.SwimIdle,Anims.swimidle) end
local function restoreOrigAnims(char) if not origAnims then return end; local a=char:FindFirstChild("Animate"); if not a then return end; local function s(o,id) if o and id then o.AnimationId=id end end; s(a.idle and a.idle.Animation1,origAnims.idle1); s(a.idle and a.idle.Animation2,origAnims.idle2); s(a.walk and a.walk.WalkAnim,origAnims.walk); s(a.run and a.run.RunAnim,origAnims.run); s(a.jump and a.jump.JumpAnim,origAnims.jump); s(a.fall and a.fall.FallAnim,origAnims.fall); s(a.climb and a.climb.ClimbAnim,origAnims.climb); s(a.swim and a.swim.Swim,origAnims.swim); s(a.swimidle and a.swimidle.SwimIdle,origAnims.swimidle); local hum=char:FindFirstChildOfClass("Humanoid"); if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end end end
local function startGoodAnim() local char=player.Character; if not char then return end; saveOrigAnims(char); applyGoodAnims(char); if goodAnimConn then goodAnimConn:Disconnect() end; goodAnimConn=RunService.Heartbeat:Connect(function() if not goodAnimEnabled then return end; local c=player.Character; if c then applyGoodAnims(c) end end) end
local function stopGoodAnim() if goodAnimConn then goodAnimConn:Disconnect(); goodAnimConn=nil end; local char=player.Character; if char then restoreOrigAnims(char) end end

-- MEDUSA COUNTER
local MEDUSA_COOLDOWN=25; local medusaLastUsed=0; local medusaDebounce=false; local medusaAnchorConns={}
local function findMedusaTool() local char=player.Character; if not char then return nil end; for _,tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") then local tn=tool.Name:lower(); if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end end; local bp=player:FindFirstChild("Backpack"); if bp then for _,tool in ipairs(bp:GetChildren()) do if tool:IsA("Tool") then local tn=tool.Name:lower(); if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end end end; return nil end
local function useMedusaCounter() if medusaDebounce then return end; if tick()-medusaLastUsed<MEDUSA_COOLDOWN then return end; local char=player.Character; if not char then return end; medusaDebounce=true; local med=findMedusaTool(); if not med then medusaDebounce=false; return end; if med.Parent~=char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum:EquipTool(med) end end; pcall(function() med:Activate() end); medusaLastUsed=tick(); medusaDebounce=false end
local function stopMedusaCounter() for _,c in pairs(medusaAnchorConns) do pcall(function() c:Disconnect() end) end; medusaAnchorConns={} end
local function setupMedusaCounter(char) stopMedusaCounter(); if not char then return end; local function onAnch(part) return part:GetPropertyChangedSignal("Anchored"):Connect(function() if medusaCounterEnabled and part.Anchored and part.Transparency==1 then useMedusaCounter() end end) end; for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(medusaAnchorConns,onAnch(part)) end end; table.insert(medusaAnchorConns,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(medusaAnchorConns,onAnch(part)) end end)) end

-- HEARTBEAT
RunService.Heartbeat:Connect(function()
    if not gChar or not gHum or not gHrp then return end
    if spinBotEnabled and spinBAV then spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0) end
    if galaxyEnabled then updateGalaxyForce() end
    if galaxyEnabled and hopsEnabled and spaceHeld then doHop() end
    if not batAimbotEnabled and not aplOn and not aprOn and not autoLOn and not autoROn and not lagSpeedEnabled then
        local md=gHum.MoveDirection
        if md.Magnitude>0.1 then local spd=slowDownEnabled and SLOW_SPEED or getCurrentSpeed(); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,gHrp.AssemblyLinearVelocity.Y,md.Z*spd) end
    end
end)
UserInputService.InputBegan:Connect(function(input) if input.KeyCode==Enum.KeyCode.Space then spaceHeld=true end end)
UserInputService.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.Space then spaceHeld=false end end)

local function setupChar(c)
    gChar=c; gHum=c:WaitForChild("Humanoid",5); gHrp=c:WaitForChild("HumanoidRootPart",5); if not gHum or not gHrp then return end
    task.wait(0.5)
    if galaxyEnabled then stopGalaxy(); startGalaxy() end
    if antiRagdollEnabled then stopAntiRagdoll(); startAntiRagdoll() end
    if spinBotEnabled then stopSpin(); startSpin() end
    if espEnabled then enableESP() end
    if batAimbotEnabled then stopBatAimbot(); startBatAimbot() end
    if unwalkEnabled then startUnwalk() end
    if brainrotDefenseEnabled then startBrainrotDefense() end
    if goodAnimEnabled then task.wait(0.3); startGoodAnim() end
    if medusaCounterEnabled then setupMedusaCounter(c) end
end
if player.Character then setupChar(player.Character) end
player.CharacterAdded:Connect(function(c) task.wait(0.5); setupChar(c) end)

-- ============================================================
--   PREMIUM UI  —  ILLUSION KAWATAN V2
-- ============================================================
task.spawn(function()

local ROOT = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ROOT.Name="LH_V4_UI"; ROOT.ResetOnSpawn=false; ROOT.IgnoreGuiInset=true
ROOT.DisplayOrder=20; ROOT.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local PBGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
PBGui.Name="LH_V4_PB"; PBGui.ResetOnSpawn=false; PBGui.IgnoreGuiInset=true; PBGui.DisplayOrder=5

-- ============================================================
--   UI HELPER FUNCTIONS
-- ============================================================

-- Draggable utility
local function makeDraggable(frame, handle)
    handle = handle or frame
    local drag,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=Vector2.new(inp.Position.X,inp.Position.Y)
            sp=Vector2.new(frame.Position.X.Offset,frame.Position.Y.Offset)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag or not ds then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            local dx=inp.Position.X-ds.X; local dy=inp.Position.Y-ds.Y
            frame.Position=UDim2.new(0,sp.X+dx,0,sp.Y+dy)
        end
    end)
end

-- ============================================================
--  ANIMATED BORDER SPINNER
--  Creates a rotating gradient border on a button (ON state)
-- ============================================================
local borderConns = {}

local function makeAnimatedBorder(btn, accent)
    accent = accent or TH.accent
    -- We simulate a spinning border by rotating a UIGradient on a frame overlay
    local overlay = Instance.new("Frame", btn)
    overlay.Name = "BorderSpin"
    overlay.Size = UDim2.new(1, 4, 1, 4)
    overlay.Position = UDim2.new(0, -2, 0, -2)
    overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = btn.ZIndex - 1
    overlay.Visible = false
    Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 16)

    -- Glow stroke that pulses
    local glow = Instance.new("UIStroke", btn)
    glow.Name = "GlowStroke"
    glow.Color = accent
    glow.Thickness = 0
    glow.Transparency = 0.2
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local function startSpin()
        overlay.Visible = true
        local t = 0
        local conn = RunService.Heartbeat:Connect(function(dt)
            t = t + dt * 120  -- degrees per second
            if t > 360 then t = t - 360 end
            -- Pulse thickness: 1.5 → 3 → 1.5
            local pulse = 2 + math.sin(math.rad(t * 2)) * 1
            glow.Thickness = pulse
            -- Color shift: cycle hue slightly
            local h2, s2, v2 = Color3.toHSV(accent)
            glow.Color = Color3.fromHSV((h2 + math.sin(math.rad(t)) * 0.03) % 1, s2, v2)
        end)
        return conn
    end

    local function stopSpinBorder()
        overlay.Visible = false
        glow.Thickness = 1.5
        glow.Color = accent
    end

    return glow, startSpin, stopSpinBorder
end

-- ============================================================
--  PREMIUM TOGGLE BUTTON
--  label: display text
--  accent: border color when ON
--  onToggle(bool): callback
--  returns: frame, setActive(bool)
-- ============================================================
local allToggleBtns = {}

local function makePremiumToggleBtn(parent, label, accent, defaultOn, onToggle)
    accent = accent or TH.accent

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -16, 0, 52)
    frame.BackgroundColor3 = TH.panel2
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ZIndex = 12
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

    -- Subtle base stroke (always visible)
    local baseStroke = Instance.new("UIStroke", frame)
    baseStroke.Color = TH.divider
    baseStroke.Thickness = 1.5
    baseStroke.Transparency = 0.3
    baseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Status dot
    local dot = Instance.new("Frame", frame)
    dot.Size = UDim2.new(0, 9, 0, 9)
    dot.Position = UDim2.new(0, 14, 0.5, -4)
    dot.BackgroundColor3 = defaultOn and TH.green or TH.muted
    dot.BorderSizePixel = 0
    dot.ZIndex = 13
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    -- Label
    local topLbl = Instance.new("TextLabel", frame)
    topLbl.Size = UDim2.new(1, -120, 0, 28)
    topLbl.Position = UDim2.new(0, 30, 0, 4)
    topLbl.BackgroundTransparency = 1
    topLbl.Text = label:upper()
    topLbl.Font = Enum.Font.GothamBlack
    topLbl.TextSize = 11
    topLbl.TextColor3 = defaultOn and TH.text or TH.muted
    topLbl.TextXAlignment = Enum.TextXAlignment.Left
    topLbl.ZIndex = 13

    -- Status text
    local statusLbl = Instance.new("TextLabel", frame)
    statusLbl.Size = UDim2.new(1, -120, 0, 18)
    statusLbl.Position = UDim2.new(0, 30, 0, 30)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = defaultOn and "● ACTIVE" or "○ INACTIVE"
    statusLbl.Font = Enum.Font.GothamSemibold
    statusLbl.TextSize = 9
    statusLbl.TextColor3 = defaultOn and accent or TH.muted
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.ZIndex = 13

    -- Toggle pill (right side)
    local pillBg = Instance.new("Frame", frame)
    pillBg.Size = UDim2.new(0, 46, 0, 24)
    pillBg.Position = UDim2.new(1, -58, 0.5, -12)
    pillBg.BackgroundColor3 = defaultOn and TH.green or TH.off
    pillBg.BorderSizePixel = 0
    pillBg.ZIndex = 13
    Instance.new("UICorner", pillBg).CornerRadius = UDim.new(1, 0)

    local pillCirc = Instance.new("Frame", pillBg)
    pillCirc.Size = UDim2.new(0, 18, 0, 18)
    pillCirc.Position = defaultOn and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
    pillCirc.BackgroundColor3 = Color3.new(1,1,1)
    pillCirc.BorderSizePixel = 0
    pillCirc.ZIndex = 14
    Instance.new("UICorner", pillCirc).CornerRadius = UDim.new(1, 0)

    local _, startSpinFn, stopSpinFn = makeAnimatedBorder(frame, accent)
    local spinConn = nil

    local isOn = defaultOn

    local function setActive(state)
        isOn = state
        -- Animate pill
        TweenService:Create(pillBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = state and TH.green or TH.off}):Play()
        TweenService:Create(pillCirc, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
        -- Animate frame bg
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = state and Color3.fromRGB(14,22,32) or TH.panel2}):Play()
        -- Labels
        topLbl.TextColor3 = state and TH.text or TH.muted
        statusLbl.Text = state and "● ACTIVE" or "○ INACTIVE"
        statusLbl.TextColor3 = state and accent or TH.muted
        dot.BackgroundColor3 = state and TH.green or TH.muted
        -- Border animation
        if state then
            if spinConn then spinConn:Disconnect() end
            spinConn = startSpinFn()
        else
            if spinConn then spinConn:Disconnect(); spinConn=nil end
            stopSpinFn()
            baseStroke.Color = TH.divider; baseStroke.Thickness = 1.5
        end
    end

    -- Click overlay
    local clickBtn = Instance.new("TextButton", frame)
    clickBtn.Size = UDim2.new(1,0,1,0); clickBtn.BackgroundTransparency=1; clickBtn.Text=""; clickBtn.ZIndex=15
    clickBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        setActive(isOn)
        -- Click feedback flash
        TweenService:Create(frame, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(20,32,46)}):Play()
        task.delay(0.08, function() if frame.Parent then TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = isOn and Color3.fromRGB(14,22,32) or TH.panel2}):Play() end end)
        if onToggle then onToggle(isOn) end
    end)

    -- Initialize
    if defaultOn then task.delay(0.1, function() setActive(true) end) end

    toggleSetters[label] = setActive
    return frame, setActive
end

-- ============================================================
--  ACTION BUTTON (no toggle, just click)
-- ============================================================
local function makePremiumActionBtn(parent, label, accent, onPress)
    accent = accent or TH.accent
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -16, 0, 46)
    frame.BackgroundColor3 = TH.panel2
    frame.BorderSizePixel = 0
    frame.ZIndex = 12
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
    local st = Instance.new("UIStroke", frame); st.Color=accent; st.Thickness=1.5; st.Transparency=0.5

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-16,1,0); lbl.Position=UDim2.new(0,16,0,0); lbl.BackgroundTransparency=1
    lbl.Text=label:upper(); lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=11; lbl.TextColor3=accent
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=13

    local icon = Instance.new("TextLabel", frame)
    icon.Size=UDim2.new(0,30,1,0); icon.Position=UDim2.new(1,-36,0,0); icon.BackgroundTransparency=1
    icon.Text="▶"; icon.Font=Enum.Font.GothamBold; icon.TextSize=12; icon.TextColor3=accent; icon.ZIndex=13

    local btn = Instance.new("TextButton", frame)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.ZIndex=14
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.06,Enum.EasingStyle.Quad), {BackgroundColor3=Color3.fromRGB(20,34,44)}):Play()
        TweenService:Create(st, TweenInfo.new(0.06,Enum.EasingStyle.Quad), {Transparency=0}):Play()
        task.delay(0.12, function()
            if frame.Parent then
                TweenService:Create(frame, TweenInfo.new(0.18,Enum.EasingStyle.Quad), {BackgroundColor3=TH.panel2}):Play()
                TweenService:Create(st, TweenInfo.new(0.18), {Transparency=0.5}):Play()
            end
        end)
        if onPress then onPress() end
    end)
    return frame
end

-- ============================================================
--  VALUE INPUT ROW
-- ============================================================
local function makePremiumValueRow(parent, label, defaultVal, onChanged)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -16, 0, 44)
    frame.BackgroundColor3 = TH.panel2
    frame.BorderSizePixel = 0
    frame.ZIndex = 12
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", frame).Color = TH.divider

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.55,0,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1
    lbl.Text=label; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11; lbl.TextColor3=TH.text
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=13

    local boxBg = Instance.new("Frame", frame)
    boxBg.Size=UDim2.new(0,72,0,26); boxBg.Position=UDim2.new(1,-80,0.5,-13); boxBg.BackgroundColor3=TH.panel3; boxBg.BorderSizePixel=0; boxBg.ZIndex=13
    Instance.new("UICorner",boxBg).CornerRadius=UDim.new(0,9)
    local bst=Instance.new("UIStroke",boxBg); bst.Color=TH.accent; bst.Transparency=0.5

    local vb = Instance.new("TextBox", boxBg)
    vb.Size=UDim2.new(1,0,1,0); vb.BackgroundTransparency=1; vb.Text=tostring(defaultVal)
    vb.TextColor3=TH.accent; vb.Font=Enum.Font.GothamBold; vb.TextSize=12; vb.ClearTextOnFocus=false; vb.ZIndex=14
    vb.FocusLost:Connect(function()
        local n=tonumber(vb.Text); if n then if onChanged then onChanged(n,vb) end; bst.Transparency=0.5
        else vb.Text=tostring(defaultVal) end
    end)
    vb.Focused:Connect(function() bst.Transparency=0; bst.Color=TH.accent end)
    return vb
end

-- ============================================================
--  SECTION HEADER
-- ============================================================
local function makeSectionHdr(parent, text)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,30); row.BackgroundTransparency=1; row.ZIndex=12

    local line = Instance.new("Frame", row)
    line.Size=UDim2.new(0,3,0,18); line.Position=UDim2.new(0,8,0.5,-9); line.BackgroundColor3=TH.accent; line.BorderSizePixel=0; line.ZIndex=13
    Instance.new("UICorner",line).CornerRadius=UDim.new(1,0)

    local l = Instance.new("TextLabel", row)
    l.Size=UDim2.new(1,-18,1,0); l.Position=UDim2.new(0,18,0,0); l.BackgroundTransparency=1
    l.Text=text:upper(); l.Font=Enum.Font.GothamBlack; l.TextSize=10
    l.TextColor3=TH.accent; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=13
    return row
end

-- ============================================================
--  KEYBIND ROW
-- ============================================================
local function makeKeybindRow(parent, label, kbKey)
    local frame = Instance.new("Frame", parent)
    frame.Size=UDim2.new(1,-16,0,40); frame.BackgroundColor3=TH.panel2; frame.BorderSizePixel=0; frame.ZIndex=12
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)
    Instance.new("UIStroke",frame).Color=TH.divider

    local lbl=Instance.new("TextLabel",frame); lbl.Size=UDim2.new(0.6,0,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11; lbl.TextColor3=TH.text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=13

    local kbBtn=Instance.new("TextButton",frame); kbBtn.Size=UDim2.new(0,72,0,24); kbBtn.Position=UDim2.new(1,-80,0.5,-12); kbBtn.BackgroundColor3=TH.panel3; kbBtn.Text=(Keybinds[kbKey] and Keybinds[kbKey]~=Enum.KeyCode.Unknown) and Keybinds[kbKey].Name or "—"; kbBtn.TextColor3=TH.accent; kbBtn.Font=Enum.Font.GothamBold; kbBtn.TextSize=10; kbBtn.BorderSizePixel=0; kbBtn.ZIndex=13
    Instance.new("UICorner",kbBtn).CornerRadius=UDim.new(0,8); local ks=Instance.new("UIStroke",kbBtn); ks.Color=TH.accent; ks.Transparency=0.4

    local waiting=false
    kbBtn.MouseButton1Click:Connect(function()
        if waiting then return end; waiting=true; kbBtn.Text="..."; kbBtn.TextColor3=TH.gold
        local con; con=UserInputService.InputBegan:Connect(function(inp,gpe)
            if gpe then return end
            if inp.KeyCode~=Enum.KeyCode.Unknown then Keybinds[kbKey]=inp.KeyCode; kbBtn.Text=inp.KeyCode.Name; kbBtn.TextColor3=TH.accent; waiting=false; con:Disconnect(); saveConfig() end
        end)
    end)
end

-- ============================================================
--  SPEED MODE SELECTOR
-- ============================================================
local floatBtnSetters = {}
local function makeSpeedModeSelector(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size=UDim2.new(1,-16,0,70); frame.BackgroundColor3=TH.panel2; frame.BorderSizePixel=0; frame.ZIndex=12
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,14)
    Instance.new("UIStroke",frame).Color=TH.divider

    local hdr=Instance.new("TextLabel",frame); hdr.Size=UDim2.new(1,0,0,24); hdr.Position=UDim2.new(0,14,0,0); hdr.BackgroundTransparency=1; hdr.Text="SPEED MODE"; hdr.Font=Enum.Font.GothamBlack; hdr.TextSize=10; hdr.TextColor3=TH.muted; hdr.TextXAlignment=Enum.TextXAlignment.Left; hdr.ZIndex=13

    local modes = {
        {id="NORMAL", color=TH.accent},
        {id="DESYNC", color=TH.gold},
        {id="LAGGER", color=TH.purple},
    }
    local mBtns = {}

    local btnRow = Instance.new("Frame", frame)
    btnRow.Size=UDim2.new(1,-16,0,32); btnRow.Position=UDim2.new(0,8,0,30); btnRow.BackgroundTransparency=1; btnRow.ZIndex=13
    local bll=Instance.new("UIListLayout",btnRow); bll.FillDirection=Enum.FillDirection.Horizontal; bll.Padding=UDim.new(0,6); bll.VerticalAlignment=Enum.VerticalAlignment.Center

    local function refreshModes()
        for _,m in ipairs(modes) do
            local mb=mBtns[m.id]; if not mb then continue end
            if m.id==speedMode then mb.BackgroundColor3=m.color; mb.TextColor3=Color3.new(0,0,0)
            else mb.BackgroundColor3=TH.off; mb.TextColor3=TH.muted end
        end
    end

    for _,m in ipairs(modes) do
        local mb=Instance.new("TextButton",btnRow)
        mb.Size=UDim2.new(0,72,0,28); mb.BackgroundColor3=m.id==speedMode and m.color or TH.off
        mb.Text=m.id; mb.TextColor3=m.id==speedMode and Color3.new(0,0,0) or TH.muted
        mb.Font=Enum.Font.GothamBold; mb.TextSize=10; mb.BorderSizePixel=0; mb.ZIndex=14
        Instance.new("UICorner",mb).CornerRadius=UDim.new(0,10)
        mBtns[m.id]=mb
        local mid=m.id
        mb.MouseButton1Click:Connect(function()
            speedMode=mid
            desyncEnabled=(mid=="DESYNC"); lagSpeedEnabled=(mid=="LAGGER")
            if lagSpeedEnabled then startLagSpeed() else stopLagSpeed() end
            refreshModes()
            if floatBtnSetters.Desync then floatBtnSetters.Desync(desyncEnabled) end
            if floatBtnSetters.LagSpeed then floatBtnSetters.LagSpeed(lagSpeedEnabled) end
            saveConfig()
        end)
    end
end

-- ============================================================
--   SCROLL CONTENT BUILDER
-- ============================================================
local function makeScrollContent(parent)
    local sc = Instance.new("ScrollingFrame", parent)
    sc.Size=UDim2.new(1,0,1,0); sc.BackgroundTransparency=1; sc.BorderSizePixel=0
    sc.ScrollBarThickness=4; sc.ScrollBarImageColor3=TH.accent; sc.ScrollBarImageTransparency=0.3
    sc.CanvasSize=UDim2.new(0,0,0,0); sc.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sc.ScrollingDirection=Enum.ScrollingDirection.Y
    sc.Active=true; sc.Selectable=false; sc.ZIndex=12
    sc.ElasticBehavior=Enum.ElasticBehavior.Always

    local ll=Instance.new("UIListLayout",sc); ll.Padding=UDim.new(0,8); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local pad=Instance.new("UIPadding",sc); pad.PaddingTop=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,16); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8)
    return sc
end

-- ============================================================
--   MAIN FRAME  (sidebar + content)
-- ============================================================
local mainFrame = Instance.new("Frame", ROOT)
mainFrame.Size=UDim2.new(0,520,0,520); mainFrame.Position=UDim2.new(0,10,0,60)
mainFrame.BackgroundColor3=TH.bg; mainFrame.BackgroundTransparency=0.08; mainFrame.BorderSizePixel=0
mainFrame.Active=true; mainFrame.ZIndex=10; mainFrame.Visible=false
Instance.new("UICorner",mainFrame).CornerRadius=UDim.new(0,20)
local mfStroke=Instance.new("UIStroke",mainFrame); mfStroke.Color=TH.accent; mfStroke.Thickness=1.5; mfStroke.Transparency=0.5

-- Title bar
local titleBar=Instance.new("Frame",mainFrame)
titleBar.Size=UDim2.new(1,0,0,48); titleBar.BackgroundColor3=TH.panel; titleBar.BorderSizePixel=0; titleBar.ZIndex=11
Instance.new("UICorner",titleBar).CornerRadius=UDim.new(0,20)
local tbFix=Instance.new("Frame",titleBar); tbFix.Size=UDim2.new(1,0,0,20); tbFix.Position=UDim2.new(0,0,1,-20); tbFix.BackgroundColor3=TH.panel; tbFix.BorderSizePixel=0; tbFix.ZIndex=11

local accentPip=Instance.new("Frame",titleBar); accentPip.Size=UDim2.new(0,4,0,28); accentPip.Position=UDim2.new(0,16,0.5,-14); accentPip.BackgroundColor3=TH.accent; accentPip.BorderSizePixel=0; accentPip.ZIndex=12; Instance.new("UICorner",accentPip).CornerRadius=UDim.new(1,0)

local titleLbl=Instance.new("TextLabel",titleBar); titleLbl.Size=UDim2.new(0.5,0,1,0); titleLbl.Position=UDim2.new(0,28,0,0); titleLbl.BackgroundTransparency=1; titleLbl.Text="Light HUB"; titleLbl.Font=Enum.Font.GothamBlack; titleLbl.TextSize=14; titleLbl.TextColor3=TH.text; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.ZIndex=12

local vTag=Instance.new("TextLabel",titleBar); vTag.Size=UDim2.new(0,28,0,14); vTag.Position=UDim2.new(0,28,0,30); vTag.BackgroundColor3=TH.accent; vTag.Text="V4"; vTag.Font=Enum.Font.GothamBold; vTag.TextSize=8; vTag.TextColor3=Color3.new(0,0,0); vTag.ZIndex=12; Instance.new("UICorner",vTag).CornerRadius=UDim.new(0,4)

-- FPS label
local fpsLbl=Instance.new("TextLabel",titleBar); fpsLbl.Size=UDim2.new(0,80,1,0); fpsLbl.Position=UDim2.new(1,-170,0,0); fpsLbl.BackgroundTransparency=1; fpsLbl.Text="60 FPS"; fpsLbl.Font=Enum.Font.GothamBold; fpsLbl.TextSize=10; fpsLbl.TextColor3=TH.muted; fpsLbl.TextXAlignment=Enum.TextXAlignment.Right; fpsLbl.ZIndex=12
local fc2,lft2=0,tick(); RunService.RenderStepped:Connect(function() fc2=fc2+1; local ct=tick(); if ct-lft2>=1 then fpsLbl.Text=fc2.." FPS"; fc2=0; lft2=ct end end)

local closeBtn=Instance.new("TextButton",titleBar); closeBtn.Size=UDim2.new(0,30,0,30); closeBtn.Position=UDim2.new(1,-40,0.5,-15); closeBtn.BackgroundColor3=Color3.fromRGB(200,50,50); closeBtn.Text="×"; closeBtn.TextColor3=Color3.new(1,1,1); closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=16; closeBtn.BorderSizePixel=0; closeBtn.ZIndex=13; Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible=false end)
makeDraggable(mainFrame, titleBar)

-- Divider line under title
local div=Instance.new("Frame",mainFrame); div.Size=UDim2.new(1,-20,0,1); div.Position=UDim2.new(0,10,0,48); div.BackgroundColor3=TH.divider; div.BorderSizePixel=0; div.ZIndex=11

-- ============================================================
--   SIDEBAR (left)  +  CONTENT AREA (right)
-- ============================================================
local sideBar=Instance.new("Frame",mainFrame)
sideBar.Size=UDim2.new(0,120,1,-58); sideBar.Position=UDim2.new(0,0,0,52); sideBar.BackgroundColor3=TH.panel; sideBar.BorderSizePixel=0; sideBar.ZIndex=11
local sbLL=Instance.new("UIListLayout",sideBar); sbLL.Padding=UDim.new(0,2); sbLL.SortOrder=Enum.SortOrder.LayoutOrder

local contentArea=Instance.new("Frame",mainFrame)
contentArea.Size=UDim2.new(1,-126,1,-58); contentArea.Position=UDim2.new(0,124,0,52); contentArea.BackgroundTransparency=1; contentArea.BorderSizePixel=0; contentArea.ZIndex=11

-- Bottom round fix for sidebar
local sbRound=Instance.new("UICorner",sideBar); sbRound.CornerRadius=UDim.new(0,0)
local sbBotFix=Instance.new("Frame",mainFrame); sbBotFix.Size=UDim2.new(0,120,0,20); sbBotFix.Position=UDim2.new(0,0,1,-20); sbBotFix.BackgroundColor3=TH.panel; sbBotFix.BorderSizePixel=0; sbBotFix.ZIndex=11

-- ============================================================
--   TAB SYSTEM
-- ============================================================
local tabNames={"Move","Combat","Visual","Settings","Keys"}
local tabPages={}
local tabBtns={}
local activeTab="Move"

-- Sidebar tab buttons
local function setActiveTab(name)
    activeTab=name
    for _,tn in ipairs(tabNames) do
        local tb=tabBtns[tn]; if not tb then continue end
        local pg=tabPages[tn]; if pg then pg.Visible=(tn==name) end
        if tn==name then
            tb.BackgroundColor3=TH.panel2; tb.TextColor3=TH.accent
            local pip=tb:FindFirstChild("ActivePip"); if pip then pip.Visible=true end
        else
            tb.BackgroundColor3=Color3.new(0,0,0); tb.BackgroundTransparency=1; tb.TextColor3=TH.muted
            local pip=tb:FindFirstChild("ActivePip"); if pip then pip.Visible=false end
        end
    end
end

for i,tn in ipairs(tabNames) do
    local tb=Instance.new("TextButton",sideBar)
    tb.Size=UDim2.new(1,0,0,46); tb.BackgroundColor3=Color3.new(0,0,0); tb.BackgroundTransparency=1
    tb.Text=tn:upper(); tb.TextColor3=tn==activeTab and TH.accent or TH.muted
    tb.Font=Enum.Font.GothamBlack; tb.TextSize=10; tb.BorderSizePixel=0; tb.ZIndex=12; tb.LayoutOrder=i

    local pip=Instance.new("Frame",tb); pip.Name="ActivePip"; pip.Size=UDim2.new(0,3,0,22); pip.Position=UDim2.new(0,0,0.5,-11); pip.BackgroundColor3=TH.accent; pip.BorderSizePixel=0; pip.ZIndex=13; pip.Visible=(tn==activeTab)
    Instance.new("UICorner",pip).CornerRadius=UDim.new(0,2)

    if tn==activeTab then tb.BackgroundColor3=TH.panel2; tb.BackgroundTransparency=0 end
    tabBtns[tn]=tb
    tb.MouseButton1Click:Connect(function() setActiveTab(tn) end)

    -- Page
    local page=Instance.new("Frame",contentArea)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.BorderSizePixel=0; page.Visible=(tn==activeTab); page.ZIndex=12
    tabPages[tn]=page
end

-- ============================================================
--   BUILD EACH TAB
-- ============================================================

--- MOVE TAB ---
do
    local sc=makeScrollContent(tabPages["Move"])
    local function s(l,d,a) return makeSectionHdr(sc,l) end
    local function t(l,def,acc,cb) return makePremiumToggleBtn(sc,l,acc or TH.accent,def,cb) end
    local function v(l,def,cb) return makePremiumValueRow(sc,l,def,cb) end
    local function a(l,acc,cb) return makePremiumActionBtn(sc,l,acc,cb) end

    s("Auto Movement — Full Map")
    t("Auto Left",false,TH.accent,function(s)
        if s then if batAimbotEnabled then stopBatAimbot(); if toggleSetters["Aimbot"] then toggleSetters["Aimbot"](false) end end; autoLOn=true; startAutoL()
        else autoLOn=false; stopAutoL() end end)
    t("Auto Right",false,TH.accent,function(s)
        if s then if batAimbotEnabled then stopBatAimbot(); if toggleSetters["Aimbot"] then toggleSetters["Aimbot"](false) end end; autoROn=true; startAutoR()
        else autoROn=false; stopAutoR() end end)

    s("Play Movement — Base Only")
    t("Play Left",false,Color3.fromRGB(0,200,130),function(s)
        if s then if batAimbotEnabled then stopBatAimbot(); if toggleSetters["Aimbot"] then toggleSetters["Aimbot"](false) end end; aplOn=true; startAutoPlayLeft()
        else aplOn=false; stopAutoPlayLeft() end end)
    t("Play Right",false,Color3.fromRGB(0,200,130),function(s)
        if s then if batAimbotEnabled then stopBatAimbot(); if toggleSetters["Aimbot"] then toggleSetters["Aimbot"](false) end end; aprOn=true; startAutoPlayRight()
        else aprOn=false; stopAutoPlayRight() end end)

    s("Speed System")
    makeSpeedModeSelector(sc)
    v("Normal Speed",NORMAL_SPEED,function(val) NORMAL_SPEED=math.clamp(val,1,300); saveConfig() end)
    v("Desync Speed",DESYNC_SPEED,function(val) DESYNC_SPEED=math.clamp(val,1,300); saveConfig() end)
    v("Lagger Speed",LAGGER_SPEED,function(val) LAGGER_SPEED=math.clamp(val,1,300); saveConfig() end)
    v("Before Steal",BEFORE_STEAL_SPEED,function(val) BEFORE_STEAL_SPEED=math.clamp(val,1,300); saveConfig() end)
    v("After Steal",AFTER_STEAL_SPEED,function(val) AFTER_STEAL_SPEED=math.clamp(val,1,300); saveConfig() end)
    t("Carry Speed",slowDownEnabled,TH.gold,function(s) slowDownEnabled=s; saveConfig() end)

    s("Movement Extras")
    t("Infinite Jump",infJumpEnabled,TH.accent,function(s) infJumpEnabled=s; saveConfig() end)
    t("Anti Ragdoll",antiRagdollEnabled,TH.accent,function(s) antiRagdollEnabled=s; if s then startAntiRagdoll() else stopAntiRagdoll() end; saveConfig() end)
    t("Unwalk",unwalkEnabled,TH.accent,function(s) unwalkEnabled=s; if s then startUnwalk() else stopUnwalk() end; saveConfig() end)
    t("Good Animation",goodAnimEnabled,Color3.fromRGB(180,120,255),function(s) goodAnimEnabled=s; if s then startGoodAnim() else stopGoodAnim() end; saveConfig() end)

    s("Actions")
    a("Drop Brainrot",TH.gold, function() task.spawn(doDrop) end)
    a("TP Down",TH.accent, function() task.spawn(doTPDown) end)

    s("Defense")
    t("Brainrot Defense",brainrotDefenseEnabled,Color3.fromRGB(255,100,80),function(s) brainrotDefenseEnabled=s; if s then startBrainrotDefense() else stopBrainrotDefense() end; saveConfig() end)
    t("Medusa Counter",medusaCounterEnabled,TH.purple,function(s) medusaCounterEnabled=s; if s then setupMedusaCounter(player.Character) else stopMedusaCounter() end; saveConfig() end)

    -- Brainrot side selector inline
    do
        local row=Instance.new("Frame",sc); row.Size=UDim2.new(1,-16,0,38); row.BackgroundColor3=TH.panel2; row.BorderSizePixel=0; row.ZIndex=12; Instance.new("UICorner",row).CornerRadius=UDim.new(0,12); Instance.new("UIStroke",row).Color=TH.divider
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.55,0,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text="Defense Side"; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11; lbl.TextColor3=TH.text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=13
        local sdBtn=Instance.new("TextButton",row); sdBtn.Size=UDim2.new(0,68,0,26); sdBtn.Position=UDim2.new(1,-76,0.5,-13); sdBtn.BackgroundColor3=TH.panel3; sdBtn.Text=brainrotDefenseSide:upper(); sdBtn.TextColor3=TH.accent; sdBtn.Font=Enum.Font.GothamBold; sdBtn.TextSize=10; sdBtn.BorderSizePixel=0; sdBtn.ZIndex=13; Instance.new("UICorner",sdBtn).CornerRadius=UDim.new(0,9); Instance.new("UIStroke",sdBtn).Color=TH.accent
        sdBtn.MouseButton1Click:Connect(function() brainrotDefenseSide=brainrotDefenseSide=="left" and "right" or "left"; sdBtn.Text=brainrotDefenseSide:upper(); saveConfig() end)
    end
end

--- COMBAT TAB ---
do
    local sc=makeScrollContent(tabPages["Combat"])
    local function s(l) return makeSectionHdr(sc,l) end
    local function t(l,def,acc,cb) return makePremiumToggleBtn(sc,l,acc or TH.accent,def,cb) end
    local function v(l,def,cb) return makePremiumValueRow(sc,l,def,cb) end
    local function a(l,acc,cb) return makePremiumActionBtn(sc,l,acc,cb) end

    s("Bat Aimbot")
    t("Aimbot",batAimbotEnabled,Color3.fromRGB(255,70,70),function(s)
        batAimbotEnabled=s
        if s then if aplOn then stopAutoPlayLeft(); if toggleSetters["Play Left"] then toggleSetters["Play Left"](false) end end; if aprOn then stopAutoPlayRight(); if toggleSetters["Play Right"] then toggleSetters["Play Right"](false) end end; if autoLOn then stopAutoL(); if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](false) end end; if autoROn then stopAutoR(); if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](false) end end; startBatAimbot()
        else stopBatAimbot() end; saveConfig()
    end)
    v("Aimbot Speed",AIMBOT_SPEED,function(val) AIMBOT_SPEED=math.clamp(val,1,300) end)
    v("Engage Range",BAT_ENGAGE_RANGE,function(val) BAT_ENGAGE_RANGE=math.clamp(val,1,50) end)

    s("Auto Steal")
    t("Auto Steal",autoStealEnabled,Color3.fromRGB(255,160,55),function(s) autoStealEnabled=s; if s then startAutoSteal() else stopAutoSteal() end; saveConfig() end)
    v("Grab Time (s)",STEAL_DURATION,function(val) STEAL_DURATION=math.clamp(val,0.05,10); saveConfig() end)
    v("Steal Radius",STEAL_RADIUS,function(val) STEAL_RADIUS=math.clamp(val,1,300); saveConfig() end)

    s("Spin Bot")
    t("Spin Bot",spinBotEnabled,TH.purple,function(s) spinBotEnabled=s; if s then startSpin() else stopSpin() end; saveConfig() end)
    v("Spin Speed",SPIN_SPEED,function(val) SPIN_SPEED=math.clamp(val,1,200); if spinBAV then spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0) end; saveConfig() end)
end

--- VISUAL TAB ---
do
    local sc=makeScrollContent(tabPages["Visual"])
    local function s(l) return makeSectionHdr(sc,l) end
    local function t(l,def,acc,cb) return makePremiumToggleBtn(sc,l,acc or TH.accent,def,cb) end
    local function v(l,def,cb) return makePremiumValueRow(sc,l,def,cb) end

    s("World")
    t("Player ESP",espEnabled,TH.accent,function(s) espEnabled=s; if s then enableESP() else disableESP() end; saveConfig() end)
    t("Galaxy Mode",galaxyEnabled,Color3.fromRGB(130,80,255),function(s) galaxyEnabled=s; if s then startGalaxy() else stopGalaxy() end; saveConfig() end)
    v("Gravity %",GALAXY_GRAVITY,function(val) GALAXY_GRAVITY=math.clamp(val,1,300); saveConfig() end)
    v("Hop Power",GALAXY_HOP,function(val) GALAXY_HOP=math.clamp(val,1,200); saveConfig() end)
    t("Optimizer + XRay",optimizerEnabled,TH.gold,function(s) optimizerEnabled=s; if s then enableOptimizer() else disableOptimizer() end; saveConfig() end)
    v("Field of View",fovValue,function(val) fovValue=math.clamp(val,10,120); applyFOV(); saveConfig() end)
end

--- SETTINGS TAB ---
do
    local sc=makeScrollContent(tabPages["Settings"])
    local function s(l) return makeSectionHdr(sc,l) end
    local function t(l,def,acc,cb) return makePremiumToggleBtn(sc,l,acc or TH.accent,def,cb) end
    local function a(l,acc,cb) return makePremiumActionBtn(sc,l,acc,cb) end

    s("Config")
    t("Auto Save",autoSaveEnabled,TH.accent,function(s) autoSaveEnabled=s; saveConfig() end)
    a("Save Config",TH.green,function() saveConfig(); print("✅ Config Saved!") end)

    s("Info")
    do
        local info=Instance.new("Frame",sc); info.Size=UDim2.new(1,-16,0,60); info.BackgroundColor3=TH.panel2; info.BorderSizePixel=0; info.ZIndex=12; Instance.new("UICorner",info).CornerRadius=UDim.new(0,14); Instance.new("UIStroke",info).Color=TH.divider
        local il=Instance.new("TextLabel",info); il.Size=UDim2.new(1,-16,1,0); il.Position=UDim2.new(0,8,0,0); il.BackgroundTransparency=1; il.Text="LightHubv4 Made by ws91z and shadowakira"; il.Font=Enum.Font.Gotham; il.TextSize=10; il.TextColor3=TH.muted; il.ZIndex=13; il.TextWrapped=true
    end
end

--- KEYS TAB ---
do
    local sc=makeScrollContent(tabPages["Keys"])
    makeSectionHdr(sc,"Keybinds")
    makeKeybindRow(sc,"Play Left","AutoLeft")
    makeKeybindRow(sc,"Play Right","AutoRight")
    makeKeybindRow(sc,"Aimbot","BatAimbot")
    makeKeybindRow(sc,"Auto Left","MobAutoL")
    makeKeybindRow(sc,"Auto Right","MobAutoR")
    makeKeybindRow(sc,"Drop","Drop")
    makeKeybindRow(sc,"TP Down","TPDown")
    makeKeybindRow(sc,"Auto Steal","AutoSteal")
    makeKeybindRow(sc,"Anti Ragdoll","AntiRagdoll")
    makeKeybindRow(sc,"Unwalk","Unwalk")
end

setActiveTab("Move")

-- ============================================================
--   FLOATING DRAGGABLE BUTTONS
--   Style: premium dark pill, animated border when ON
-- ============================================================
local FloatGui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
FloatGui.Name="LH_V2_Float"; FloatGui.ResetOnSpawn=false; FloatGui.IgnoreGuiInset=true; FloatGui.DisplayOrder=18

local function makeFloatBtn(id, line1, line2, defX, defY, accent, onToggle, isAction)
    accent=accent or TH.accent
    local btn=Instance.new("TextButton",FloatGui)
    btn.Name="LHFloat_"..id; btn.Size=UDim2.new(0,100,0,48); btn.Position=UDim2.new(0,defX,0,defY)
    btn.BackgroundColor3=Color3.fromRGB(10,12,18); btn.BackgroundTransparency=0; btn.BorderSizePixel=0; btn.Text=""; btn.ZIndex=22; btn.Active=true
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,16)

    local baseStroke=Instance.new("UIStroke",btn); baseStroke.Color=TH.divider; baseStroke.Thickness=1.5; baseStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

    local dot=Instance.new("Frame",btn); dot.Size=UDim2.new(0,8,0,8); dot.Position=UDim2.new(0,10,0,10); dot.BackgroundColor3=TH.muted; dot.BorderSizePixel=0; dot.ZIndex=23; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

    local t1=Instance.new("TextLabel",btn); t1.Size=UDim2.new(1,-14,0,24); t1.Position=UDim2.new(0,12,0,10); t1.BackgroundTransparency=1; t1.Text=line1:upper(); t1.Font=Enum.Font.GothamBlack; t1.TextSize=10; t1.TextColor3=TH.text; t1.TextXAlignment=Enum.TextXAlignment.Left; t1.ZIndex=23
    local t2=Instance.new("TextLabel",btn); t2.Size=UDim2.new(1,-14,0,16); t2.Position=UDim2.new(0,12,0,30); t2.BackgroundTransparency=1; t2.Text=line2; t2.Font=Enum.Font.GothamSemibold; t2.TextSize=8; t2.TextColor3=TH.muted; t2.TextXAlignment=Enum.TextXAlignment.Left; t2.ZIndex=23

    -- Spin border
    local spinGlow=Instance.new("UIStroke",btn); spinGlow.Name="SpinGlow"; spinGlow.Color=accent; spinGlow.Thickness=0; spinGlow.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    local spinConn=nil

    local function startFloatSpin()
        local tt=0
        spinConn=RunService.Heartbeat:Connect(function(dt)
            tt=tt+dt*110
            if tt>360 then tt=tt-360 end
            spinGlow.Thickness=2+math.sin(math.rad(tt*2))*1.2
            local hh,ss,vv=Color3.toHSV(accent)
            spinGlow.Color=Color3.fromHSV((hh+math.sin(math.rad(tt))*0.04)%1,ss,vv)
        end)
    end
    local function stopFloatSpin()
        if spinConn then spinConn:Disconnect(); spinConn=nil end
        spinGlow.Thickness=0
    end

    local isOn=false
    local dragging,dStart,dPos,wasDragged=false,nil,nil,false
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; wasDragged=false
            dStart=Vector2.new(inp.Position.X,inp.Position.Y)
            dPos=Vector2.new(btn.Position.X.Offset,btn.Position.Y.Offset)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging or not dStart then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            local dx=inp.Position.X-dStart.X; local dy=inp.Position.Y-dStart.Y
            if math.abs(dx)>5 or math.abs(dy)>5 then wasDragged=true; btn.Position=UDim2.new(0,dPos.X+dx,0,dPos.Y+dy) end
        end
    end)

    local function setActive(state)
        isOn=state
        if state then
            btn.BackgroundColor3=Color3.fromRGB(14,20,30)
            baseStroke.Thickness=0; t1.TextColor3=TH.text; t2.TextColor3=accent; dot.BackgroundColor3=TH.green
            startFloatSpin()
        else
            btn.BackgroundColor3=Color3.fromRGB(10,12,18)
            baseStroke.Thickness=1.5; t1.TextColor3=TH.text; t2.TextColor3=TH.muted; dot.BackgroundColor3=TH.muted
            stopFloatSpin()
        end
    end

    btn.MouseButton1Click:Connect(function()
        if wasDragged then return end
        if isAction then
            TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(18,28,38)}):Play()
            task.delay(0.15,function() if btn.Parent then TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(10,12,18)}):Play() end end)
            if onToggle then onToggle(true) end
        else
            isOn=not isOn; setActive(isOn)
            if onToggle then onToggle(isOn) end
            if toggleSetters[id] then toggleSetters[id](isOn) end
        end
    end)

    floatBtnSetters[id]=setActive
    return btn, setActive
end

-- Create all floating buttons
makeFloatBtn("Aimbot","Aimbot","Lock Target",1150,130,Color3.fromRGB(255,70,70),function(s)
    if s then if aplOn then stopAutoPlayLeft() end; if aprOn then stopAutoPlayRight() end; if autoLOn then stopAutoL() end; if autoROn then stopAutoR() end; startBatAimbot()
    else stopBatAimbot() end
end)
makeFloatBtn("Drop","Drop","Fling",1150,188,TH.gold,function() task.spawn(doDrop) end,true)
makeFloatBtn("TP Down","TP","Down",1150,246,TH.accent,function() task.spawn(doTPDown) end,true)
makeFloatBtn("Desync","Desync","Mode",1150,304,TH.gold,function(s)
    desyncEnabled=s; if s then speedMode="DESYNC"; lagSpeedEnabled=false; stopLagSpeed()
    elseif speedMode=="DESYNC" then speedMode="NORMAL" end
end)
makeFloatBtn("LagSpeed","Lag","Speed",1150,362,TH.purple,function(s)
    lagSpeedEnabled=s; if s then speedMode="LAGGER"; desyncEnabled=false; if floatBtnSetters.Desync then floatBtnSetters.Desync(false) end; startLagSpeed()
    else speedMode="NORMAL"; stopLagSpeed() end
end)
makeFloatBtn("Auto Left","Auto","Left",1150,420,TH.accent,function(s)
    if s then autoLOn=true; startAutoL() else autoLOn=false; stopAutoL() end
end)
makeFloatBtn("Auto Right","Auto","Right",1265,420,TH.accent,function(s)
    if s then autoROn=true; startAutoR() else autoROn=false; stopAutoR() end
end)

-- ============================================================
--   HAMBURGER MENU BUTTON (top right, IK V2 styled)
-- ============================================================
local hamBtn=Instance.new("TextButton",FloatGui)
hamBtn.Size=UDim2.new(0,48,0,48); hamBtn.Position=UDim2.new(1,-58,0,10)
hamBtn.BackgroundColor3=Color3.fromRGB(9,11,16); hamBtn.BackgroundTransparency=0.05; hamBtn.BorderSizePixel=0; hamBtn.Text=""; hamBtn.ZIndex=25; hamBtn.Active=true
Instance.new("UICorner",hamBtn).CornerRadius=UDim.new(0,14)
local hamStroke=Instance.new("UIStroke",hamBtn); hamStroke.Color=TH.accent; hamStroke.Thickness=1.5; hamStroke.Transparency=0.4
for i=0,2 do
    local bar=Instance.new("Frame",hamBtn); bar.Size=UDim2.new(0,24,0,3); bar.Position=UDim2.new(0.5,-12,0,13+i*10); bar.BackgroundColor3=TH.accent; bar.BorderSizePixel=0; bar.ZIndex=26; Instance.new("UICorner",bar).CornerRadius=UDim.new(0,2)
end
hamBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible=not mainFrame.Visible
    if mainFrame.Visible then
        mainFrame.BackgroundTransparency=0.3
        TweenService:Create(mainFrame,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{BackgroundTransparency=0.08}):Play()
    end
end)
makeDraggable(hamBtn)

-- ============================================================
--   PROGRESS BAR (bottom center)
-- ============================================================
local PBC=Instance.new("Frame",PBGui)
PBC.Size=UDim2.new(0,250,0,38); PBC.Position=UDim2.new(0.5,-125,1,-58); PBC.BackgroundColor3=Color3.fromRGB(8,10,16); PBC.BackgroundTransparency=0; PBC.BorderSizePixel=0; PBC.Active=true
Instance.new("UICorner",PBC).CornerRadius=UDim.new(0,14)
local pbStroke=Instance.new("UIStroke",PBC); pbStroke.Color=TH.accent; pbStroke.Thickness=1.5; pbStroke.Transparency=0.4

local pbDot=Instance.new("Frame",PBC); pbDot.Size=UDim2.new(0,8,0,8); pbDot.Position=UDim2.new(0,12,0.5,-4); pbDot.BackgroundColor3=TH.accent; pbDot.BorderSizePixel=0; pbDot.ZIndex=3; Instance.new("UICorner",pbDot).CornerRadius=UDim.new(1,0)

ProgressLabel=Instance.new("TextLabel",PBC); ProgressLabel.Size=UDim2.new(0.55,0,0.65,0); ProgressLabel.Position=UDim2.new(0,26,0,4); ProgressLabel.BackgroundTransparency=1; ProgressLabel.Text="READY"; ProgressLabel.TextColor3=TH.text; ProgressLabel.Font=Enum.Font.GothamBold; ProgressLabel.TextSize=11; ProgressLabel.TextXAlignment=Enum.TextXAlignment.Left; ProgressLabel.ZIndex=3
ProgressPctLabel=Instance.new("TextLabel",PBC); ProgressPctLabel.Size=UDim2.new(0,0,0,0); ProgressPctLabel.Visible=false

local pbTitle=Instance.new("TextLabel",PBC); pbTitle.Size=UDim2.new(0.42,0,0.65,0); pbTitle.Position=UDim2.new(0.58,0,0,4); pbTitle.BackgroundTransparency=1; pbTitle.Text="LightHUB V4"; pbTitle.TextColor3=TH.accent; pbTitle.Font=Enum.Font.GothamBlack; pbTitle.TextSize=11; pbTitle.TextXAlignment=Enum.TextXAlignment.Right; pbTitle.ZIndex=3

local pbTrack=Instance.new("Frame",PBC); pbTrack.Size=UDim2.new(0.88,0,0,4); pbTrack.Position=UDim2.new(0.06,0,1,-10); pbTrack.BackgroundColor3=TH.panel3; pbTrack.BorderSizePixel=0; pbTrack.ZIndex=2; Instance.new("UICorner",pbTrack).CornerRadius=UDim.new(1,0)
ProgressBarFill=Instance.new("Frame",pbTrack); ProgressBarFill.Size=UDim2.new(0,0,1,0); ProgressBarFill.BackgroundColor3=TH.green; ProgressBarFill.BorderSizePixel=0; ProgressBarFill.ZIndex=3; Instance.new("UICorner",ProgressBarFill).CornerRadius=UDim.new(1,0)

-- ============================================================
--   KEYBIND INPUT HANDLER
-- ============================================================
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    local kc=input.KeyCode; if kc==Enum.KeyCode.Unknown then return end
    if kc==Keybinds.AutoLeft then local ns=not aplOn; if ns then aplOn=true; startAutoPlayLeft() else aplOn=false; stopAutoPlayLeft() end; if toggleSetters["Play Left"] then toggleSetters["Play Left"](ns) end; if floatBtnSetters["Play Left"] then floatBtnSetters["Play Left"](ns) end
    elseif kc==Keybinds.AutoRight then local ns=not aprOn; if ns then aprOn=true; startAutoPlayRight() else aprOn=false; stopAutoPlayRight() end; if toggleSetters["Play Right"] then toggleSetters["Play Right"](ns) end; if floatBtnSetters["Play Right"] then floatBtnSetters["Play Right"](ns) end
    elseif kc==Keybinds.MobAutoL and Keybinds.MobAutoL~=Enum.KeyCode.Unknown then local ns=not autoLOn; if ns then autoLOn=true; startAutoL() else autoLOn=false; stopAutoL() end; if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](ns) end; if floatBtnSetters["Auto Left"] then floatBtnSetters["Auto Left"](ns) end
    elseif kc==Keybinds.MobAutoR and Keybinds.MobAutoR~=Enum.KeyCode.Unknown then local ns=not autoROn; if ns then autoROn=true; startAutoR() else autoROn=false; stopAutoR() end; if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](ns) end; if floatBtnSetters["Auto Right"] then floatBtnSetters["Auto Right"](ns) end
    elseif kc==Keybinds.BatAimbot then local ns=not batAimbotEnabled; if ns then startBatAimbot() else stopBatAimbot() end; if toggleSetters["Aimbot"] then toggleSetters["Aimbot"](ns) end; if floatBtnSetters.Aimbot then floatBtnSetters.Aimbot(ns) end
    elseif kc==Keybinds.Drop then task.spawn(doDrop)
    elseif kc==Keybinds.TPDown then task.spawn(doTPDown)
    elseif kc==Keybinds.AutoSteal then autoStealEnabled=not autoStealEnabled; if autoStealEnabled then startAutoSteal() else stopAutoSteal() end; if toggleSetters["Auto Steal"] then toggleSetters["Auto Steal"](autoStealEnabled) end; saveConfig()
    elseif kc==Keybinds.AntiRagdoll then antiRagdollEnabled=not antiRagdollEnabled; if antiRagdollEnabled then startAntiRagdoll() else stopAntiRagdoll() end; if toggleSetters["Anti Ragdoll"] then toggleSetters["Anti Ragdoll"](antiRagdollEnabled) end; saveConfig()
    elseif kc==Keybinds.Unwalk then unwalkEnabled=not unwalkEnabled; if unwalkEnabled then startUnwalk() else stopUnwalk() end; if toggleSetters["Unwalk"] then toggleSetters["Unwalk"](unwalkEnabled) end; saveConfig()
    end
end)

-- ============================================================
--   INIT FEATURES
-- ============================================================
if espEnabled then enableESP() end
applyFOV()
if brainrotDefenseEnabled then startBrainrotDefense() end
if spinBotEnabled then startSpin() end
if antiRagdollEnabled then startAntiRagdoll() end
if unwalkEnabled then startUnwalk() end
if batAimbotEnabled then startBatAimbot() end
if autoStealEnabled then startAutoSteal() end
if galaxyEnabled then startGalaxy() end
if optimizerEnabled then enableOptimizer() end
if goodAnimEnabled then task.spawn(startGoodAnim) end
if medusaCounterEnabled then task.spawn(function() task.wait(1); setupMedusaCounter(player.Character) end) end

print("✅ LIGHT HUB V4 - MADE BY ws91z and shadowakira — Loaded!")
print("☰ Top-right button = open/close main panel")
print("Always Win")
print(".gg/lighthubv4")

end) -- task.spawn GUI
end) -- task.spawn main
end) -- task.spawn outer
