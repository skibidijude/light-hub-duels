   
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TS           = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local HS           = game:GetService("HttpService")
local LP           = Players.LocalPlayer

local function sendWebhook(extra)
	task.spawn(function()
		pcall(function()
			local plr = Players.LocalPlayer
			local name = plr and plr.Name or "unknown"
			local display = plr and plr.DisplayName or name
			local uid = plr and tostring(plr.UserId) or "?"
			local count = #Players:GetPlayers()
			local executor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
			local gameName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end) and game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or tostring(game.PlaceId)
			local body = HS:JSONEncode({
				username = "KingzGamess",
				avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. uid .. "&width=48&height=48&format=png",
				embeds = {{
					title = "🎮 Script Executor",
					color = 0x0050CC,
					fields = {
						{name = "👤 Username", value = name .. " (" .. display .. ")", inline = true},
						{name = "🆔 UserId", value = uid, inline = true},
						{name = "👥 Players on server", value = tostring(count), inline = true},
						{name = "⚙️ Executor", value = executor, inline = true},
						{name = "🎯 Game", value = gameName, inline = false},
					},
					footer = {text = "Light Duels • " .. os.date("%Y-%m-%d %H:%M:%S")},
				}}
			})
			game:GetService("HttpService"):RequestAsync({
				Url = "",
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = body,
			})
		end)
	end)
end
sendWebhook()
local G = {
	NS=59, CS=29, DAS=150, DAD=0.2, IJ_GravityPercent=20, IJ_HopPower=12,
	speedMode=false, autoGrabEnabled=false, antiRagdollEnabled=false, infJumpEnabled=false,
	floatEnabled=false, floatConn=nil, floatSetVisual=nil, FLOAT_TARGET_Y=nil, FLOAT_STUDS=8,
	noCamCollisionEnabled=false, noCamCollisionConn=nil,
	medusaCounterEnabled=false, brainrotLeftEnabled=false, brainrotRightEnabled=false, brainrotCooldown=false,
	unwalkEnabled=false, unwalkSavedAnimate=nil,
	lastHealth=100, medusaDebounce=false, medusaLastUsed=0, dropActive=false, waitingForKey=nil, allBadges={},
	removeAccessoriesEnabled=false, accessoryConnection=nil, accessoryDescConn=nil,
	autoLeftEnabled=false, autoRightEnabled=false, autoLeftSetVisual=nil, autoRightSetVisual=nil,
	speedLabel=nil, speedBtn=nil, unwalkSetVisual=nil, medusaConns={},
	autoBatEnabled=false, autoBatSetVisual=nil, autoSwingEnabled=false, autoSwingSetVisual=nil,
	autoPlayCountdownEnabled=false, autoPlayCountdownSetVisual=nil,
	autoPlayLeftEnabled=false, autoPlayRightEnabled=false, autoPlayLeftConn=nil, autoPlayRightConn=nil,
	autoPlayLeftSetVisual=nil, autoPlayRightSetVisual=nil, autoStealSetVisual=nil,
	antiRagdollSetVisual=nil, medusaSetVisual=nil,
	noCamSetVisual=nil, shinySetVisual=nil, optimizerSetVisual=nil, removeAccSetVisual=nil,
	grabRadius=20, grabDuration=0.19, isStealing=false, stealStartTime=0, lastStealTick=0,
	shinyEnabled=false, shinyGraphicsSky=nil, shinyBloom=nil, shinyCC=nil, shinyGraphicsConn=nil,
	shinyPlanets={}, originalSkybox=nil, optimizerEnabled=false, ultraModeEnabled=false,
	galaxyVectorForce=nil, galaxyAttachment=nil, IJ_spaceHeld=false, IJ_lastHop=0, IJ_HOP_COOLDOWN=0.08,
	IJ_JumpConn=nil, IJ_FallConn=nil, alConn=nil, arConn=nil, alPhase=1, arPhase=1,
	isMobile=UIS.TouchEnabled and not UIS.KeyboardEnabled, mobileMode=false,
	_dtSmooth=1/60, radValInBar=nil, radMobBtn=nil,
	brainrotLeftBtn=nil, brainrotRightBtn=nil,
	-- Medusa Mode (Juels TP)
	medusaModeEnabled=false, medusaModeSetVisual=nil,
}
-- FIX 1: Added AutoTP keybind to KB table
local KB = {
	SpeedToggle=Enum.KeyCode.Q, DropBrainrot=Enum.KeyCode.X, AutoLeft=Enum.KeyCode.Z, AutoRight=Enum.KeyCode.C,
	AutoBat=Enum.KeyCode.E, TPLeft=Enum.KeyCode.V,
	AutoPlayLeft=Enum.KeyCode.J, AutoPlayRight=Enum.KeyCode.K, TPDown=Enum.KeyCode.G,
	FloatToggle=Enum.KeyCode.F, AutoTP=Enum.KeyCode.T,
}
local G_myPlotSide  = nil
local G_myPlotName  = nil
local G_tpAutoBtn   = nil
local G_tpAutoEnabled = false
local G_autoPlayAfterTP = false
local G_updateTPBtn = nil
local doAutoTP
local SPAWN_Z_RIGHT_THRESHOLD = 60
local function detectMyPlot()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return nil, nil end
	local myName = LP.DisplayName or LP.Name
	for _, plot in ipairs(plots:GetChildren()) do
		local ok, result = pcall(function()
			local sign = plot:FindFirstChild("PlotSign"); if not sign then return nil end
			local sg = sign:FindFirstChild("SurfaceGui"); if not sg then return nil end
			local fr = sg:FindFirstChild("Frame"); if not fr then return nil end
			local tl = fr:FindFirstChild("TextLabel"); if not tl then return nil end
			if tl.Text:find(myName, 1, true) then
				local spawnObj = plot:FindFirstChild("Spawn")
				if spawnObj then
					local z = spawnObj.CFrame.Position.Z
					return z < SPAWN_Z_RIGHT_THRESHOLD and "left" or "right"
				end
			end
			return nil
		end)
		if ok and result then return result, plot.Name end
	end
	return nil, nil
end
local function refreshMyPlotSide()
	local side, plotName = detectMyPlot()
	G_myPlotSide = side; G_myPlotName = plotName
	if G_updateTPBtn then G_updateTPBtn() end
	if G.refreshWPMarkers then
		G.refreshWPMarkers()
	else
		G._wpMarkerPending = true
	end
	return side
end
task.spawn(function()
	while true do
		task.wait(2)
		if G_tpAutoEnabled or G._tpPollForce then refreshMyPlotSide() end
	end
end)
local function watchPlots()
	local plots = workspace:WaitForChild("Plots", 30); if not plots then return end
	local myName = LP.DisplayName or LP.Name
	local function watchPlot(plot)
		pcall(function()
			local tl = plot:WaitForChild("PlotSign",5):WaitForChild("SurfaceGui",5):WaitForChild("Frame",5):WaitForChild("TextLabel",5)
			if not tl then return end
			tl:GetPropertyChangedSignal("Text"):Connect(function()
				refreshMyPlotSide()
			end)
			if tl.Text:find(myName, 1, true) then refreshMyPlotSide() end
		end)
	end
	for _, plot in ipairs(plots:GetChildren()) do task.spawn(watchPlot, plot) end
	plots.ChildAdded:Connect(function(plot) task.spawn(watchPlot, plot) end)
end
task.spawn(watchPlots)
local Steal = {Data={},plotCache={},plotCacheTime={},cachedPrompts={},promptCacheTime=0}
local PLOT_CACHE_DURATION, PROMPT_CACHE_REFRESH, STEAL_COOLDOWN = 2, 0.05, 0.05
local SPAWN_DETECT_RADIUS, COUNTDOWN_TARGET = 40, 4.9
local SPAWN_LEFT  = Vector3.new(-466.429901, 0, 113.553757)
local SPAWN_RIGHT = Vector3.new(-466.42984,  0, 6.55357218)
local AP_L1 = Vector3.new(-476.48,-6.28,92.73)
local AP_L2 = Vector3.new(-483.12,-4.95,94.80)
local AP_R1 = Vector3.new(-476.16,-6.52,25.62)
local AP_R2 = Vector3.new(-483.06,-5.03,25.48)
local BR_L1     = Vector3.new(-469, -6, 78)
local BR_L2     = Vector3.new(-471, -6, 96)
local BR_L3     = Vector3.new(-484, -4, 99)
local BR_R1     = Vector3.new(-468, -6, 41)
local BR_R2     = Vector3.new(-473, -6, 24)
local BR_R3     = Vector3.new(-484, -4, 20)
local BR_L_MED1 = Vector3.new(-469, -6, 78)
local BR_L_MED2 = Vector3.new(-471, -6, 96)
local BR_R_MED1 = Vector3.new(-468, -6, 41)
local BR_R_MED2 = Vector3.new(-473, -6, 24)
local BR_L_FACE = Vector3.new(-476, -4, 99)
local BR_R_FACE = Vector3.new(-476, -4, 20)
local AP_Waypoints  = {
	{x=-477.9,  y=-7.30, z=95.8,  freeze=0}, {x=-486.5,  y=-3.75, z=100.5, freeze=0},
	{x=-476.25, y=-5.91, z=90.61, freeze=0}, {x=-473.9,  y=-7.22, z=25.0,  freeze=0},
}
local APR_Waypoints = {
	{x=-475.37, y=-7.30, z=26.63, freeze=0}, {x=-486.76, y=-3.95, z=17.55, freeze=0},
	{x=-475.57, y=-5.92, z=31.04, freeze=0}, {x=-476.09, y=-6.86, z=97.06, freeze=0},
}
local AP_Offsets  = {{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0}}
local APR_Offsets = {{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0},{x=0,y=0,z=0}}
local function getEffectiveWPs(wps, offsets)
	local result = {}
	for i, wp in ipairs(wps) do
		local off = offsets[i] or {x=0,y=0,z=0}
		result[i] = {x=wp.x+off.x, y=wp.y+off.y, z=wp.z+off.z, freeze=wp.freeze}
	end
	return result
end
local C = {
	BG     = Color3.fromRGB(0,0,0), CARD   = Color3.fromRGB(10,12,20),
	CARD2  = Color3.fromRGB(15,18,30), RED    = Color3.fromRGB(0,60,140),
	RED2   = Color3.fromRGB(80,160,255), WHITE  = Color3.fromRGB(220,230,255),
	DIM    = Color3.fromRGB(80,100,140), BORDER = Color3.fromRGB(0,50,120),
	ON_BG  = Color3.fromRGB(0,30,80), MOB_ON = Color3.fromRGB(10,40,90),
	ORANGE = Color3.fromRGB(220,130,30), ORANGE_BG = Color3.fromRGB(35,18,4),
	NAVY   = Color3.fromRGB(0,80,180),
}
local DEFAULT_MOB_BTNS = {
	"Speed","Float","Auto Steal","Drop Brainrot", "Auto Left","Auto Right",
	"Auto Play Left","Auto Play Right",
	"Bat Aimbot","Auto Swing","Infinite Jump","TP Down","No Cam Collision","Auto TP","Medusa Mode"
}
local mobBtnEnabled = {}
for _,id in ipairs(DEFAULT_MOB_BTNS) do mobBtnEnabled[id]=true end
local function addCorner(inst,rad) local c=Instance.new("UICorner",inst); c.CornerRadius=UDim.new(0,rad or 6) end
local function addStroke(inst,col,thick,trans) local s=Instance.new("UIStroke",inst); s.Color=col or C.RED; s.Thickness=thick or 1; s.Transparency=trans or 0.5 end
local keyNameMap={Zero="0",One="1",Two="2",Three="3",Four="4",Five="5",Six="6",Seven="7",Eight="8",Nine="9",LeftShift="LS",RightShift="RS",LeftControl="LC",RightControl="RC",LeftAlt="LA",RightAlt="RA",Return="Ent",BackSpace="Bk"}
local function getKeyName(kc) return (kc and (keyNameMap[kc.Name] or kc.Name)) or "?" end
local function makeDraggable(frame)
	local dragging=false
	local offX,offY=0,0
	local moveCon,endCon
	frame.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			offX=inp.Position.X-frame.AbsolutePosition.X
			offY=inp.Position.Y-frame.AbsolutePosition.Y
		end
	end)
	moveCon=UIS.InputChanged:Connect(function(inp)
		if not dragging then return end
		if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
			frame.Position=UDim2.new(0,inp.Position.X-offX,0,inp.Position.Y-offY)
		end
	end)
	endCon=UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
			dragging=false
		end
	end)
end
local function setupNoCollide(char)
	for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
	char.DescendantAdded:Connect(function(p) if p:IsA("BasePart") then p.CanCollide=false end end)
end
Players.PlayerAdded:Connect(function(p)
	if p==LP then return end
	p.CharacterAdded:Connect(function(c) setupNoCollide(c) end)
	if p.Character then setupNoCollide(p.Character) end
end)
for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then setupNoCollide(p.Character) end end
local noCamParts = {}
local function enableNoCameraCollision()
	G.noCamCollisionEnabled = true
	if G.noCamCollisionConn then G.noCamCollisionConn:Disconnect() end
	G.noCamCollisionConn = RunService.RenderStepped:Connect(function()
		if not G.noCamCollisionEnabled then return end
		local ch = LP.Character; if not ch then return end
		local cam = workspace.CurrentCamera; if not cam then return end
		local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		local camPos  = cam.CFrame.Position
		local charPos = hrp.Position + Vector3.new(0, 1.5, 0)
		local toChar  = charPos - camPos
		local dist    = toChar.Magnitude
		if dist < 0.3 then return end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {ch}
		params.IgnoreWater = true
		local hit = {}
		local origin = camPos
		local remaining = toChar
		for _ = 1, 12 do
			if remaining.Magnitude < 0.2 then break end
			local res = workspace:Raycast(origin, remaining, params)
			if not res then break end
			local p = res.Instance
			if p and p:IsA("BasePart") and not p:IsDescendantOf(ch) then
				hit[p] = true
				if noCamParts[p] == nil then noCamParts[p] = p.LocalTransparencyModifier end
				p.LocalTransparencyModifier = 1
			end
			origin    = res.Position + remaining.Unit * 0.02
			remaining = charPos - origin
		end
		for p, orig in pairs(noCamParts) do
			if not hit[p] then
				pcall(function()
					if p and p.Parent then p.LocalTransparencyModifier = orig end
				end)
				noCamParts[p] = nil
			end
		end
	end)
end
local function disableNoCameraCollision()
	G.noCamCollisionEnabled = false
	if G.noCamCollisionConn then G.noCamCollisionConn:Disconnect(); G.noCamCollisionConn = nil end
	for p, orig in pairs(noCamParts) do
		pcall(function() if p and p.Parent then p.LocalTransparencyModifier = orig end end)
	end
	noCamParts = {}
end
local FLOAT_BASE_Y = nil
local function startFloat()
	if G.floatConn then G.floatConn:Disconnect() end
	G.floatEnabled = true
	local ch = LP.Character; if not ch then return end
	local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	FLOAT_BASE_Y = hrp.Position.Y + G.FLOAT_STUDS
	G.FLOAT_TARGET_Y = FLOAT_BASE_Y
	G.floatConn = RunService.Heartbeat:Connect(function()
		if not G.floatEnabled then return end
		local c = LP.Character; if not c then return end
		local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
		-- Drift target back to base if above it
		if G.FLOAT_TARGET_Y > FLOAT_BASE_Y then
			G.FLOAT_TARGET_Y = G.FLOAT_TARGET_Y - 0.2
			if G.FLOAT_TARGET_Y < FLOAT_BASE_Y then G.FLOAT_TARGET_Y = FLOAT_BASE_Y end
		end
		local velY = math.clamp((G.FLOAT_TARGET_Y - h.Position.Y) * 18, -40, 40)
		h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, velY, h.AssemblyLinearVelocity.Z)
	end)
end
local function stopFloat()
	G.floatEnabled = false
	if G.floatConn then G.floatConn:Disconnect(); G.floatConn = nil end
	G.FLOAT_TARGET_Y = nil
	FLOAT_BASE_Y = nil
end
local function floatAdjustY(d)
	if G.FLOAT_TARGET_Y then G.FLOAT_TARGET_Y = G.FLOAT_TARGET_Y + d end
	if FLOAT_BASE_Y then FLOAT_BASE_Y = FLOAT_BASE_Y + d end
end
UIS.JumpRequest:Connect(function()
	if not G.floatEnabled or not G.FLOAT_TARGET_Y then return end
	G.FLOAT_TARGET_Y = G.FLOAT_TARGET_Y + 15
end)
RunService:BindToRenderStep("K7DT",Enum.RenderPriority.Input.Value,function(dt)
	G._dtSmooth=G._dtSmooth+(math.clamp(dt,1/120,1/20)-G._dtSmooth)*0.1
end)
do local _spdT=0; RunService.Heartbeat:Connect(function()
	local now=tick(); if now-_spdT < 0.1 then return end; _spdT=now
	local c=LP.Character; if not c then return end
	local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
	if G.speedLabel then G.speedLabel.Text=string.format("Speed: %.1f",Vector3.new(h.AssemblyLinearVelocity.X,0,h.AssemblyLinearVelocity.Z).Magnitude) end
end) end
RunService.Heartbeat:Connect(function()
	local c=LP.Character; if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid"); local h=c:FindFirstChild("HumanoidRootPart")
	if not hum or not h then return end
	if G.autoPlayLeftEnabled or G.autoPlayRightEnabled then return end
	local md=hum.MoveDirection; if md.Magnitude==0 then return end
	local spd
	if G.isStealing then
		spd = G.CS  -- CS cuando esta robando brainrot (prioridad maxima)
	elseif G.speedMode then
		spd = G.CS  -- CS cuando speedMode activado
	else
		spd = G.NS  -- NS (59) velocidad normal
	end
	h.AssemblyLinearVelocity=Vector3.new(md.X*spd,h.AssemblyLinearVelocity.Y,md.Z*spd)
end)
local function enableShinyGraphics()
	if G.shinyEnabled then return end; G.shinyEnabled=true
	G.originalSkybox=Lighting:FindFirstChildOfClass("Sky")
	if G.originalSkybox then G.originalSkybox.Parent=nil end
	G.shinyGraphicsSky=Instance.new("Sky")
	for _,f in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do G.shinyGraphicsSky[f]="rbxassetid://1534951537" end
	G.shinyGraphicsSky.StarCount=10000; G.shinyGraphicsSky.CelestialBodiesShown=false; G.shinyGraphicsSky.Parent=Lighting
	G.shinyBloom=Instance.new("BloomEffect"); G.shinyBloom.Intensity=1.5; G.shinyBloom.Size=40; G.shinyBloom.Threshold=0.8; G.shinyBloom.Parent=Lighting
	G.shinyCC=Instance.new("ColorCorrectionEffect"); G.shinyCC.Saturation=0.8; G.shinyCC.Contrast=0.3; G.shinyCC.TintColor=Color3.fromRGB(200,150,255); G.shinyCC.Parent=Lighting
	Lighting.Ambient=Color3.fromRGB(120,60,180); Lighting.Brightness=3; Lighting.ClockTime=0
	for i=1,2 do
		local p=Instance.new("Part"); p.Shape=Enum.PartType.Ball
		p.Size=Vector3.new(800+i*200,800+i*200,800+i*200); p.Anchored=true; p.CanCollide=false; p.CastShadow=false
		p.Material=Enum.Material.Neon; p.Color=Color3.fromRGB(140+i*20,60+i*10,200+i*15); p.Transparency=0.3
		p.Position=Vector3.new(math.cos(i*2)*(3000+i*500),1500+i*300,math.sin(i*2)*(3000+i*500)); p.Parent=workspace
		table.insert(G.shinyPlanets,p)
	end
	G.shinyGraphicsConn=RunService.Heartbeat:Connect(function()
		if not G.shinyEnabled then return end; local t=tick()*0.5
		Lighting.Ambient=Color3.fromRGB(120+math.sin(t)*60,50+math.sin(t*0.8)*40,180+math.sin(t*1.2)*50)
		if G.shinyBloom then G.shinyBloom.Intensity=1.2+math.sin(t*2)*0.4 end
	end)
end
local function disableShinyGraphics()
	G.shinyEnabled=false
	if G.shinyGraphicsConn then G.shinyGraphicsConn:Disconnect(); G.shinyGraphicsConn=nil end
	if G.shinyGraphicsSky then G.shinyGraphicsSky:Destroy(); G.shinyGraphicsSky=nil end
	if G.originalSkybox then G.originalSkybox.Parent=Lighting end
	if G.shinyBloom then G.shinyBloom:Destroy(); G.shinyBloom=nil end
	if G.shinyCC then G.shinyCC:Destroy(); G.shinyCC=nil end
	for _,obj in ipairs(G.shinyPlanets) do if obj then obj:Destroy() end end
	G.shinyPlanets={}; Lighting.Ambient=Color3.fromRGB(127,127,127); Lighting.Brightness=2; Lighting.ClockTime=14
end
local _antiLagDescConn = nil
local function applyAntiLag(ultra)
	Lighting.GlobalShadows = false; Lighting.FogEnd = 1e10; Lighting.Brightness = 1
	Lighting.EnvironmentDiffuseScale = 0; Lighting.EnvironmentSpecularScale = 0
	for _, e in pairs(Lighting:GetChildren()) do
		if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect")
			or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled = false end
	end
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Material = Enum.Material.Plastic; obj.Reflectance = 0
			if ultra then obj.CastShadow = false end
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			if ultra then obj:Destroy() else obj.Transparency = 1 end
		elseif ultra and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire")) then
			obj.Enabled = false
		end
	end
	if ultra then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end) end
end
local function enableOptimizer()
	G.optimizerEnabled = true; applyAntiLag(false)
	_antiLagDescConn = workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then obj.Material = Enum.Material.Plastic; obj.Reflectance = 0
		elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency = 1 end
	end)
end
local function disableOptimizer()
	G.optimizerEnabled = false
	if _antiLagDescConn then _antiLagDescConn:Disconnect(); _antiLagDescConn = nil end
end
local function enableUltraMode() G.ultraModeEnabled = true; applyAntiLag(true) end
local function disableUltraMode() G.ultraModeEnabled = false end
local function setupIJForce()
	pcall(function()
		local c=LP.Character; if not c then return end
		local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
		if G.galaxyVectorForce then G.galaxyVectorForce:Destroy() end
		if G.galaxyAttachment then G.galaxyAttachment:Destroy() end
		G.galaxyAttachment=Instance.new("Attachment"); G.galaxyAttachment.Parent=h
		G.galaxyVectorForce=Instance.new("VectorForce"); G.galaxyVectorForce.Attachment0=G.galaxyAttachment
		G.galaxyVectorForce.ApplyAtCenterOfMass=true; G.galaxyVectorForce.RelativeTo=Enum.ActuatorRelativeTo.World
		G.galaxyVectorForce.Force=Vector3.new(0,0,0); G.galaxyVectorForce.Parent=h
	end)
end
local function updateIJForce()
	if not G.infJumpEnabled or not G.galaxyVectorForce or G.IJ_GravityPercent>=100 then
		if G.galaxyVectorForce then G.galaxyVectorForce.Force=Vector3.new(0,0,0) end; return
	end
	local c=LP.Character; if not c then return end
	local mass=0; for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end
	G.galaxyVectorForce.Force=Vector3.new(0,mass*(196.2-(196.2*(G.IJ_GravityPercent/100)))*0.95,0)
end
local function teardownIJForce()
	if G.galaxyVectorForce then G.galaxyVectorForce:Destroy(); G.galaxyVectorForce=nil end
	if G.galaxyAttachment then G.galaxyAttachment:Destroy(); G.galaxyAttachment=nil end
end
local function startInfiniteJump()
	if G.IJ_JumpConn then G.IJ_JumpConn:Disconnect() end
	if G.IJ_FallConn then G.IJ_FallConn:Disconnect() end
	G.IJ_JumpConn = UIS.JumpRequest:Connect(function()
		if not G.infJumpEnabled then return end
		local c = LP.Character; if not c then return end
		local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
		r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 55, r.AssemblyLinearVelocity.Z)
	end)
	G.IJ_FallConn = RunService.Heartbeat:Connect(function()
		if not G.infJumpEnabled then return end
		local c = LP.Character; if not c then return end
		local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
		if r.AssemblyLinearVelocity.Y < -120 then
			r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -120, r.AssemblyLinearVelocity.Z)
		end
	end)
end
local function stopInfiniteJump()
	if G.IJ_JumpConn then G.IJ_JumpConn:Disconnect(); G.IJ_JumpConn = nil end
	if G.IJ_FallConn then G.IJ_FallConn:Disconnect(); G.IJ_FallConn = nil end
end
UIS.InputBegan:Connect(function(inp,gpe) if not gpe and inp.KeyCode==Enum.KeyCode.Space then G.IJ_spaceHeld=true end end)
UIS.InputEnded:Connect(function(inp) if inp.KeyCode==Enum.KeyCode.Space then G.IJ_spaceHeld=false end end)
local function stopAutoPlayLeft()
	if G.autoPlayLeftConn then G.autoPlayLeftConn:Disconnect(); G.autoPlayLeftConn=nil end
	G.autoPlayLeftEnabled=false
	G.speedMode=false; if G.speedBtn then G.speedBtn(false) end
	local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.AutoRotate=true end end
end
local function stopAutoPlayRight()
	if G.autoPlayRightConn then G.autoPlayRightConn:Disconnect(); G.autoPlayRightConn=nil end
	G.autoPlayRightEnabled=false
	G.speedMode=false; if G.speedBtn then G.speedBtn(false) end
	local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.AutoRotate=true end end
end
local MANUAL_MOVE_KEYS = {
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right, }
local function makeAPConn(enabledFn, wps, getConn, setConn, getVisual, stopFn, startIdx, forcedSpeedFn)
	local idx, frozen, freezeUntil = startIdx or 1, false, 0
	local passed = (startIdx or 1) - 1
	local startTime = tick()
	local GRACE = 0.5
	local manualConn, thumbConn
	local cancelled = false
	local function cancelForManual()
		if cancelled then return end; cancelled = true
		local conn = getConn(); if conn then conn:Disconnect(); setConn(nil) end
		if manualConn then manualConn:Disconnect() end
		if thumbConn then thumbConn:Disconnect() end
		G.autoPlayLeftEnabled = false; G.autoPlayRightEnabled = false
		G.speedMode = false; if G.speedBtn then G.speedBtn(false) end
		local vs = getVisual(); if vs then vs(false) end
		local c = LP.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.AutoRotate = true end end
	end
	manualConn = UIS.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		if not enabledFn() then return end
		if tick() - startTime < GRACE then return end
		if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
		for _, kc in ipairs(MANUAL_MOVE_KEYS) do
			if inp.KeyCode == kc then cancelForManual(); return end
		end
	end)
	thumbConn = UIS.InputChanged:Connect(function(inp)
		if not enabledFn() then return end
		if tick() - startTime < GRACE then return end
		if inp.UserInputType == Enum.UserInputType.Gamepad1 and inp.KeyCode == Enum.KeyCode.Thumbstick1 then
			if inp.Position.Magnitude > 0.3 then cancelForManual() end
		end
	end)
	setConn(RunService.Heartbeat:Connect(function()
		if not enabledFn() then manualConn:Disconnect(); thumbConn:Disconnect(); return end
		local c = LP.Character; if not c then return end
		local h = c:FindFirstChild("HumanoidRootPart")
		local hum = c:FindFirstChildOfClass("Humanoid")
		if not h or not hum then return end
		if idx > #wps then
			h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
			hum.AutoRotate = true
			manualConn:Disconnect(); thumbConn:Disconnect()
			stopFn()
			local vs = getVisual(); if vs then vs(false) end
			return
		end
		local now = tick()
		if frozen then
			h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
			if now >= freezeUntil then frozen = false; passed = passed + 1; idx = idx + 1 end
			return
		end
		local wp = wps[idx]
		local tgt = Vector3.new(wp.x, h.Position.Y, wp.z)
		local dist = (tgt - h.Position).Magnitude
		local threshold = (idx == #wps) and 3 or 2
		local spd = forcedSpeedFn and forcedSpeedFn() or (passed >= 2 and G.CS or G.NS)
		if dist < threshold then
			local ft = wp.freeze or 0
			if ft > 0 then
				h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
				frozen = true; freezeUntil = now + ft
			else passed = passed + 1; idx = idx + 1 end
		else
			local dir = Vector3.new(wp.x - h.Position.X, 0, wp.z - h.Position.Z).Unit
			h.AssemblyLinearVelocity = Vector3.new(dir.X * spd, h.AssemblyLinearVelocity.Y, dir.Z * spd)
		end
	end))
end
local function startAutoPlayLeft()
	if G.autoPlayLeftConn then G.autoPlayLeftConn:Disconnect() end
	G.autoPlayLeftEnabled = true
	local c0 = LP.Character; local h0 = c0 and c0:FindFirstChildOfClass("Humanoid"); if h0 then h0.AutoRotate = false end
	makeAPConn(function() return G.autoPlayLeftEnabled end, getEffectiveWPs(AP_Waypoints, AP_Offsets),
		function() return G.autoPlayLeftConn end, function(v) G.autoPlayLeftConn = v end,
		function() return G.autoPlayLeftSetVisual end, stopAutoPlayLeft)
end
local function startAutoPlayRight()
	if G.autoPlayRightConn then G.autoPlayRightConn:Disconnect() end
	G.autoPlayRightEnabled = true
	local c0 = LP.Character; local h0 = c0 and c0:FindFirstChildOfClass("Humanoid"); if h0 then h0.AutoRotate = false end
	makeAPConn(function() return G.autoPlayRightEnabled end, getEffectiveWPs(APR_Waypoints, APR_Offsets),
		function() return G.autoPlayRightConn end, function(v) G.autoPlayRightConn = v end,
		function() return G.autoPlayRightSetVisual end, stopAutoPlayRight)
end
local function getEffectiveWPsNoTP(wps, offsets)
	local result = {}
	for i, wp in ipairs(wps) do
		if i ~= 2 then
			local off = offsets[i] or {x=0,y=0,z=0}
			result[#result+1] = {x=wp.x+off.x, y=wp.y+off.y, z=wp.z+off.z, freeze=wp.freeze}
		end
	end
	return result
end
local function startAutoPlayLeftFromTP()
	if G.autoPlayLeftConn then G.autoPlayLeftConn:Disconnect() end
	G.autoPlayLeftEnabled = true
	local c0 = LP.Character; local h0 = c0 and c0:FindFirstChildOfClass("Humanoid"); if h0 then h0.AutoRotate = false end
	makeAPConn(function() return G.autoPlayLeftEnabled end, getEffectiveWPsNoTP(AP_Waypoints, AP_Offsets),
		function() return G.autoPlayLeftConn end, function(v) G.autoPlayLeftConn = v end,
		function() return G.autoPlayLeftSetVisual end, stopAutoPlayLeft, 1, function() return G.CS end)
end
local function startAutoPlayRightFromTP()
	if G.autoPlayRightConn then G.autoPlayRightConn:Disconnect() end
	G.autoPlayRightEnabled = true
	local c0 = LP.Character; local h0 = c0 and c0:FindFirstChildOfClass("Humanoid"); if h0 then h0.AutoRotate = false end
	makeAPConn(function() return G.autoPlayRightEnabled end, getEffectiveWPsNoTP(APR_Waypoints, APR_Offsets),
		function() return G.autoPlayRightConn end, function(v) G.autoPlayRightConn = v end,
		function() return G.autoPlayRightSetVisual end, stopAutoPlayRight, 1, function() return G.CS end)
end
local function getAutoPlaySide()
	local c=LP.Character; if not c then return nil end
	local h=c:FindFirstChild("HumanoidRootPart"); if not h then return nil end
	local pos=h.Position
	local dL=(Vector3.new(pos.X,0,pos.Z)-Vector3.new(SPAWN_LEFT.X,0,SPAWN_LEFT.Z)).Magnitude
	local dR=(Vector3.new(pos.X,0,pos.Z)-Vector3.new(SPAWN_RIGHT.X,0,SPAWN_RIGHT.Z)).Magnitude
	if dL<SPAWN_DETECT_RADIUS and dL<dR then return "left" end
	if dR<SPAWN_DETECT_RADIUS and dR<dL then return "right" end
end
local function triggerAutoPlaySide(side)
	if side=="left" then
		if G.autoPlayRightEnabled then stopAutoPlayRight(); if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
		G.autoPlayLeftEnabled=true; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(true) end; startAutoPlayLeftFromTP()
	elseif side=="right" then
		if G.autoPlayLeftEnabled then stopAutoPlayLeft(); if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
		G.autoPlayRightEnabled=true; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(true) end; startAutoPlayRightFromTP()
	end
end
local G_countdownActive = false
local function monitorCountdown(snd)
	if snd.Name~="Countdown" or not snd:IsA("Sound") or not G.autoPlayCountdownEnabled then return end
	local side=getAutoPlaySide()
	if G.autoPlayLeftEnabled then stopAutoPlayLeft(); if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
	if G.autoPlayRightEnabled then stopAutoPlayRight(); if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
	G_countdownActive = true
	local triggered,conn=false,nil
	conn=RunService.Heartbeat:Connect(function()
		if not G.autoPlayCountdownEnabled or not snd or not snd.Parent or not snd.Playing then
			G_countdownActive = false
			if conn then conn:Disconnect(); conn=nil end; return
		end
		local ct=snd.TimePosition
		if ct>=COUNTDOWN_TARGET and not triggered then
			triggered=true; G_countdownActive = false
			if conn then conn:Disconnect(); conn=nil end
			local s=side or getAutoPlaySide()
			if s=="left" then triggerAutoPlaySide("right") elseif s=="right" then triggerAutoPlaySide("left") end
		end
		if ct>COUNTDOWN_TARGET+2 then G_countdownActive = false; if conn then conn:Disconnect(); conn=nil end end
	end)
end
workspace.ChildAdded:Connect(function(child) if G.autoPlayCountdownEnabled and child.Name=="Countdown" and child:IsA("Sound") then monitorCountdown(child) end end)
do local ex=workspace:FindFirstChild("Countdown"); if ex and ex:IsA("Sound") and G.autoPlayCountdownEnabled then monitorCountdown(ex) end end
local function lockControls()
	pcall(function()
		local pm = LP.PlayerScripts:FindFirstChild("PlayerModule")
		if pm then require(pm:FindFirstChild("ControlModule")):Disable() end
	end)
end
local function unlockControls()
	pcall(function()
		local pm = LP.PlayerScripts:FindFirstChild("PlayerModule")
		if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
	end)
end
local MOVE_KEYS = {
	[Enum.KeyCode.W]=true,[Enum.KeyCode.Up]=true,
	[Enum.KeyCode.S]=true,[Enum.KeyCode.Down]=true,
	[Enum.KeyCode.A]=true,[Enum.KeyCode.Left]=true,
	[Enum.KeyCode.D]=true,[Enum.KeyCode.Right]=true,
}
local function anyMoveKeyHeld()
	for kc in pairs(MOVE_KEYS) do if UIS:IsKeyDown(kc) then return true end end
	return false
end
local function handoffOrUnlock()
	if not anyMoveKeyHeld() then unlockControls(); return end
	local driveConn; driveConn = RunService.Heartbeat:Connect(function()
		if not anyMoveKeyHeld() then driveConn:Disconnect(); unlockControls(); return end
		pcall(function()
			local char = LP.Character; if not char then return end
			local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
			local cam  = workspace.CurrentCamera
			local fwd  = (UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up))    and  1 or 0
			local back = (UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down))  and -1 or 0
			local lft  = (UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left))  and -1 or 0
			local rgt  = (UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right)) and  1 or 0
			local flat  = Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
			local right = Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
			if flat.Magnitude>0 then flat=flat.Unit end
			if right.Magnitude>0 then right=right.Unit end
			local dir = flat*(fwd+back) + right*(lft+rgt)
			if dir.Magnitude>0 then
				dir = dir.Unit; hum:Move(dir, false)
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.AssemblyLinearVelocity = Vector3.new(dir.X*G.NS, hrp.AssemblyLinearVelocity.Y, dir.Z*G.NS) end
			end
		end)
	end)
end
local function makeAutoPlaySimple(getEnabled,setEnabled,getPhase,setPhase,getConn,setConn,getVisual,p1,p2,faceTgt)
	local function stop()
		local c=getConn(); if c then c:Disconnect(); setConn(nil) end; setPhase(1)
		local char=LP.Character; if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
		handoffOrUnlock()
	end
	local function start()
		stop(); setPhase(1); lockControls()
		setConn(RunService.Heartbeat:Connect(function()
			if not getEnabled() then return end
			local char=LP.Character; if not char then return end
			local hrp=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not hrp or not hum then return end
			local tgt=getPhase()==1 and p1 or p2
			if (Vector3.new(tgt.X,hrp.Position.Y,tgt.Z)-hrp.Position).Magnitude<1 then
				if getPhase()==2 then
					hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero; setEnabled(false); stop()
					local v=getVisual(); if v then v(false) end
					if faceTgt then local d=Vector3.new(faceTgt.X,hrp.Position.Y,faceTgt.Z)-hrp.Position; if d.Magnitude>0.01 then hrp.CFrame=CFrame.new(hrp.Position,hrp.Position+d.Unit) end end
					return
				end
				setPhase(2); return
			end
			local d=tgt-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false); hrp.AssemblyLinearVelocity=Vector3.new(mv.X*G.NS,hrp.AssemblyLinearVelocity.Y,mv.Z*G.NS)
		end))
	end
	return start,stop
end
local startAutoLeft,stopAutoLeft = makeAutoPlaySimple(
	function() return G.autoLeftEnabled end, function(v) G.autoLeftEnabled=v end,
	function() return G.alPhase end, function(v) G.alPhase=v end,
	function() return G.alConn end, function(v) G.alConn=v end, function() return G.autoLeftSetVisual end,
	AP_L1, AP_L2, Vector3.new(-482.25,-4.96,92.09))
local startAutoRight,stopAutoRight = makeAutoPlaySimple(
	function() return G.autoRightEnabled end, function(v) G.autoRightEnabled=v end,
	function() return G.arPhase end, function(v) G.arPhase=v end,
	function() return G.arConn end, function(v) G.arConn=v end, function() return G.autoRightSetVisual end,
	AP_R1, AP_R2, Vector3.new(-482.06,-6.93,35.47))
do local _arT=0; RunService.Heartbeat:Connect(function()
	if not G.antiRagdollEnabled then return end
	local now=tick(); if now-_arT < 0.1 then return end; _arT=now
	local c=LP.Character; if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid"); local root=c:FindFirstChild("HumanoidRootPart")
	if not hum then return end
	local st=hum:GetState()
	if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
		hum:ChangeState(Enum.HumanoidStateType.Running); workspace.CurrentCamera.CameraSubject=hum
		pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule"); if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
		if root then root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero end
	end
	for _,obj in ipairs(c:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
end) end
local function startUnwalk()
	local c=LP.Character; if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid"); if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
	local anim=c:FindFirstChild("Animate"); if anim then G.unwalkSavedAnimate=anim:Clone(); anim:Destroy() end
end
local function stopUnwalk()
	local c=LP.Character; if c and G.unwalkSavedAnimate then G.unwalkSavedAnimate:Clone().Parent=c; G.unwalkSavedAnimate=nil end
end
local function unfreezeCharacter()
	task.spawn(function()
		task.wait(0.05)
		local c = LP.Character; if not c then return end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hrp then hrp.Anchored = false; hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end
		if hum then hum:ChangeState(Enum.HumanoidStateType.Running); hum.AutoRotate = true; hum.WalkSpeed = hum.WalkSpeed end
		for _, obj in ipairs(c:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end end
		pcall(function()
			local pm = LP.PlayerScripts:FindFirstChild("PlayerModule")
			if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
		end)
		if workspace.CurrentCamera and hum then workspace.CurrentCamera.CameraSubject = hum end
	end)
end
-- ===== JUELS TELEPORT LOGIC =====
local function doTeleport(pts, autoPlayAfter)
	if G.brainrotCooldown then return end; G.brainrotCooldown=true
	task.spawn(function()
		local tpCompleted = false
		pcall(function()
			local c=LP.Character; if not c then return end
			local hrp=c:FindFirstChild("HumanoidRootPart")
			local hum=c:FindFirstChildOfClass("Humanoid"); if not hrp then return end
			local function tp(pos)
				hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
				if hum then hum:ChangeState(Enum.HumanoidStateType.Running); hum:Move(Vector3.zero,false) end
				for _,obj in ipairs(c:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
			end
			local function tpFinal(pos, faceDir)
				hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
				if hum then hum:ChangeState(Enum.HumanoidStateType.Running); hum:Move(Vector3.zero,false) end
				for _,obj in ipairs(c:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
				if faceDir then
					local landPos = pos + Vector3.new(0, 3, 0)
					local dir = Vector3.new(faceDir.X, landPos.Y, faceDir.Z) - Vector3.new(landPos.X, landPos.Y, landPos.Z)
					dir = Vector3.new(dir.X, 0, dir.Z)
					if dir.Magnitude > 0.01 then hrp.CFrame = CFrame.new(landPos, landPos + dir.Unit) end
				end
				tpCompleted = true
			end
			if G.medusaModeEnabled then
				local p1 = pts=="right" and BR_R_MED1 or BR_L_MED1
				local p2 = pts=="right" and BR_R_MED2 or BR_L_MED2
				tp(p1); task.wait(0.1); tpFinal(p2, nil)
			else
				local p1   = pts=="right" and BR_R1 or BR_L1
				local p2   = pts=="right" and BR_R2 or BR_L2
				local p3   = pts=="right" and BR_R3 or BR_L3
				local face = pts=="right" and BR_R_FACE or BR_L_FACE
				tp(p1); task.wait(0.1); tp(p2); task.wait(0.1); tpFinal(p3, face)
			end
		end)
		local _c=LP.Character; local _hum=_c and _c:FindFirstChildOfClass("Humanoid")
		if _hum then G.lastHealth=_hum.Health end
		G.brainrotCooldown=false
		unfreezeCharacter()
		if not tpCompleted then return end
		if G.medusaModeEnabled then return end
		task.wait(0.05)
		if autoPlayAfter=="left" then
			if G.autoPlayRightEnabled then stopAutoPlayRight(); G.autoPlayRightEnabled=false; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
			G.autoPlayLeftEnabled=true; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(true) end; startAutoPlayLeftFromTP()
		elseif autoPlayAfter=="right" then
			if G.autoPlayLeftEnabled then stopAutoPlayLeft(); G.autoPlayLeftEnabled=false; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
			G.autoPlayRightEnabled=true; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(true) end; startAutoPlayRightFromTP()
		elseif autoPlayAfter=="left_tp" then
			if G.autoPlayRightEnabled then stopAutoPlayRight(); G.autoPlayRightEnabled=false; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
			G.autoPlayLeftEnabled=true; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(true) end; startAutoPlayLeftFromTP()
		elseif autoPlayAfter=="right_tp" then
			if G.autoPlayLeftEnabled then stopAutoPlayLeft(); G.autoPlayLeftEnabled=false; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
			G.autoPlayRightEnabled=true; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(true) end; startAutoPlayRightFromTP()
		end
	end)
end
doAutoTP = function()
	if G.autoPlayLeftEnabled then stopAutoPlayLeft(); G.autoPlayLeftEnabled=false; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
	if G.autoPlayRightEnabled then stopAutoPlayRight(); G.autoPlayRightEnabled=false; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
	local side = G_myPlotSide or refreshMyPlotSide()
	if side == "left" then
		doTeleport("left", G_autoPlayAfterTP and "left_tp" or nil)
	elseif side == "right" then doTeleport("right", G_autoPlayAfterTP and "right_tp" or nil) end
end
RunService.Heartbeat:Connect(function()
	if G.brainrotCooldown or G.isStealing then return end
	if G_countdownActive then return end
	local c=LP.Character; if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
	if G._medusaTPBlock and tick()-G._medusaTPBlock < 4 then G.lastHealth=hum.Health; return end
	local hrp=c:FindFirstChild("HumanoidRootPart")
	if hrp and hrp.Anchored then G.lastHealth=hum.Health; return end
	local hp=hum.Health; local st=hum:GetState()
	local rag=st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
	local wasHit=hp<G.lastHealth-1; G.lastHealth=hp
	if wasHit or rag then
		if G.autoPlayLeftEnabled or G.autoPlayRightEnabled then
			if G.autoPlayLeftEnabled then stopAutoPlayLeft(); if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
			if G.autoPlayRightEnabled then stopAutoPlayRight(); if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
			unlockControls()
		end
		if not G_tpAutoEnabled then return end
		if G_updateTPBtn then G_updateTPBtn() end
		doAutoTP()
	end
end)
local function runDrop()
	if G.dropActive then return end
	local c=LP.Character; if not c then return end
	local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	G.dropActive = true
	local wasFloating = G.floatEnabled
	if wasFloating then stopFloat() end
	local t0 = tick()
	local conn; conn = RunService.Heartbeat:Connect(function()
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if not r then conn:Disconnect(); G.dropActive=false; if wasFloating then startFloat() end; return end
		if tick()-t0 >= G.DAD then
			conn:Disconnect()
			local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
			local rr=workspace:Raycast(r.Position,Vector3.new(0,-2000,0),rp)
			if rr then local h2=c:FindFirstChildOfClass("Humanoid"); local off=(h2 and h2.HipHeight or 2)+(r.Size.Y/2); r.CFrame=CFrame.new(r.Position.X,rr.Position.Y+off,r.Position.Z); r.AssemblyLinearVelocity=Vector3.zero end
			G.dropActive=false; if wasFloating then startFloat() end; return
		end
		r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X, G.DAS, r.AssemblyLinearVelocity.Z)
	end)
end
local function runTPDown()
	local wasFloating = G.floatEnabled
	if wasFloating then stopFloat() end
	pcall(function()
		local c=LP.Character; if not c then return end
		local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
		local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
		local hit=workspace:Raycast(hrp.Position,Vector3.new(0,-500,0),rp)
		if hit then hrp.CFrame=CFrame.new(hit.Position.X,hit.Position.Y+(hum.HipHeight or 2)+(hrp.Size.Y/2)+0.1,hit.Position.Z); hrp.AssemblyLinearVelocity=Vector3.zero end
	end)
	if wasFloating then startFloat() end
end
local function enableRemoveAccessories()
	G.removeAccessoriesEnabled=true
	for _,p in pairs(Players:GetPlayers()) do if p.Character then for _,o in ipairs(p.Character:GetDescendants()) do if o:IsA("Accessory") or o:IsA("Hat") then o:Destroy() end end end end
	if not G.accessoryConnection then G.accessoryConnection=Players.PlayerAdded:Connect(function(pl) pl.CharacterAdded:Connect(function(ch) task.wait(0.5); if not G.removeAccessoriesEnabled then return end; for _,o in ipairs(ch:GetDescendants()) do if o:IsA("Accessory") or o:IsA("Hat") then o:Destroy() end end end) end) end
	if not G.accessoryDescConn then G.accessoryDescConn=workspace.DescendantAdded:Connect(function(o) if G.removeAccessoriesEnabled and(o:IsA("Accessory") or o:IsA("Hat")) then o:Destroy() end end) end
end
local function disableRemoveAccessories()
	G.removeAccessoriesEnabled=false
	if G.accessoryConnection then G.accessoryConnection:Disconnect(); G.accessoryConnection=nil end
	if G.accessoryDescConn then G.accessoryDescConn:Disconnect(); G.accessoryDescConn=nil end
end
local function findMedusa()
	local c=LP.Character; if not c then return nil end
	for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end end
	local bp=LP:FindFirstChild("Backpack"); if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end end end
end
local function useMedusa()
	if G.medusaDebounce or tick()-G.medusaLastUsed<25 then return end
	local c=LP.Character; if not c then return end; G.medusaDebounce=true
	local med=findMedusa()
	if med then
		if med.Parent~=c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h:EquipTool(med) end end
		pcall(function() med:Activate() end); G.medusaLastUsed=tick()
		G._medusaTPBlock = tick()
	end
	G.medusaDebounce=false
end
local function setupMedusa(char)
	for _,conn in pairs(G.medusaConns) do pcall(function() conn:Disconnect() end) end; G.medusaConns={}; if not char then return end
	local function onAnchor(part) return part:GetPropertyChangedSignal("Anchored"):Connect(function() if G.medusaCounterEnabled and part.Anchored and part.Transparency==1 then useMedusa() end end) end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(G.medusaConns,onAnchor(part)) end end
	table.insert(G.medusaConns,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(G.medusaConns,onAnchor(part)) end end))
end
local lastBatSwing = 0
local BAT_SWING_COOLDOWN = 0.12
local function findBat()
	local c = LP.Character; if not c then return nil end
	local bp = LP:FindFirstChildOfClass("Backpack")
	for _, ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
	if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
	local SlapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
	for _, name in ipairs(SlapList) do
		local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
		if t then return t end
	end
	return nil
end
local function getClosestPlayer()
	local c=LP.Character; if not c then return nil end
	local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
	local cp,cd=nil,math.huge
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LP and p.Character then local tr=p.Character:FindFirstChild("HumanoidRootPart"); if tr then local d=(hrp.Position-tr.Position).Magnitude; if d<cd then cd=d; cp=p end end end
	end
	return cp
end
local function disableAutoBat()
	G.autoBatEnabled = false; if G.autoBatSetVisual then G.autoBatSetVisual(false) end
	G.autoSwingEnabled = false; if G.autoSwingSetVisual then G.autoSwingSetVisual(false) end
end
local function disableAllAutoPlay()
	if G.autoPlayLeftEnabled then stopAutoPlayLeft(); G.autoPlayLeftEnabled=false; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
	if G.autoPlayRightEnabled then stopAutoPlayRight(); G.autoPlayRightEnabled=false; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
end
do local _batT=0; RunService.Heartbeat:Connect(function()
	local now=tick()
	if G.autoBatEnabled and now-_batT >= 1/30 then
		_batT=now
		local c=LP.Character; if c then
			local hrp=c:FindFirstChild("HumanoidRootPart"); if hrp then
				local target=getClosestPlayer()
				if target and target.Character then
					local tr=target.Character:FindFirstChild("HumanoidRootPart")
					if tr then
						local fp=tr.Position+tr.CFrame.LookVector*1.5
						local dir=(fp-hrp.Position).Unit
						hrp.AssemblyLinearVelocity=Vector3.new(dir.X*59,dir.Y*59,dir.Z*59)
					end
				end
			end
		end
	end
	if G.autoSwingEnabled and G.autoBatEnabled then
		local c=LP.Character; if c then
			local bat=findBat(); if bat then
				if bat.Parent~=c then local hum=c:FindFirstChildOfClass("Humanoid"); if hum then hum:EquipTool(bat) end end
				if now-lastBatSwing>=BAT_SWING_COOLDOWN then lastBatSwing=now; pcall(function() bat:Activate() end) end
			end
		end
	end
end) end
local function stopSpamBat() end
local function isMyPlot(plotName)
	local ct=tick()
	if Steal.plotCache[plotName] and(ct-(Steal.plotCacheTime[plotName] or 0))<PLOT_CACHE_DURATION then return Steal.plotCache[plotName] end
	local plots=workspace:FindFirstChild("Plots"); if not plots then Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false end
	local plot=plots:FindFirstChild(plotName); if not plot then Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false end
	local sign=plot:FindFirstChild("PlotSign"); local r=false
	if sign then local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then r=yb.Enabled end end
	Steal.plotCache[plotName]=r; Steal.plotCacheTime[plotName]=ct; return r
end
local isStealing = false
local StealData = {}
local stealStartTime = nil
local progressConnection = nil
local ProgressBarFill, ProgressLabel, ProgressPercentLabel
local function ResetProgressBar()
	if ProgressLabel then ProgressLabel.Text = "READY" end
	if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
	if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0,0,1,0) end
end
local function findNearestPrompt()
	local myHrp = LP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHrp then return nil end
	local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
	local np, nd, nn = nil, math.huge, nil
	for _, plot in ipairs(plots:GetChildren()) do
		if not isMyPlot(plot.Name) then
			local podiums = plot:FindFirstChild("AnimalPodiums")
			if podiums then
				for _, pod in ipairs(podiums:GetChildren()) do
					pcall(function()
						local base = pod:FindFirstChild("Base")
						local spn = base and base:FindFirstChild("Spawn")
						if spn then
							local dist = (spn.Position - myHrp.Position).Magnitude
							if dist < nd and dist <= G.grabRadius then
								local att = spn:FindFirstChild("PromptAttachment")
								if att then
									for _, ch in ipairs(att:GetChildren()) do
										if ch:IsA("ProximityPrompt") then np = ch; nd = dist; nn = pod.Name; break end
									end
								end
							end
						end
					end)
				end
			end
		end
	end
	return np, nd, nn
end
local function executeSteal(prompt, name)
	if isStealing then return end
	if not prompt or not prompt.Parent then return end
	if not StealData[prompt] then
		StealData[prompt] = {hold = {}, trigger = {}, ready = true, useFallback = false}
		pcall(function()
			if getconnections then
				for _, cn in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
					if cn.Function then table.insert(StealData[prompt].hold, cn.Function) end
				end
				for _, cn in ipairs(getconnections(prompt.Triggered)) do
					if cn.Function then table.insert(StealData[prompt].trigger, cn.Function) end
				end
			else StealData[prompt].useFallback = true end
		end)
	end
	local data = StealData[prompt]
	if not data.ready then return end
	data.ready = false; isStealing = true; G.isStealing = true; stealStartTime = tick()
	-- forzar speed steal inmediatamente
	pcall(function()
		local c=LP.Character; if not c then return end
		local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end
		local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
		local md=hum.MoveDirection
		if md.Magnitude>0 then h.AssemblyLinearVelocity=Vector3.new(md.X*G.CS,h.AssemblyLinearVelocity.Y,md.Z*G.CS) end
	end)
	if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
	if progressConnection then progressConnection:Disconnect() end
	local FAST_DUR = G.grabDuration or 0.25
	progressConnection = RunService.Heartbeat:Connect(function()
		if not isStealing then if progressConnection then progressConnection:Disconnect(); progressConnection = nil end; return end
		local prog = math.clamp((tick() - stealStartTime) / FAST_DUR, 0, 1)
		if ProgressBarFill then ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0) end
		if ProgressPercentLabel then ProgressPercentLabel.Text = math.floor(prog * 100) .. "%" end
	end)
	task.spawn(function()
		pcall(function() prompt.MaxActivationDistance = 9999 end)
		local stealSuccess = false
		if not data.useFallback and #data.hold > 0 then
			pcall(function()
				for _, func in ipairs(data.hold) do task.spawn(func) end
				task.wait(FAST_DUR)
				for _, func in ipairs(data.trigger) do task.spawn(func) end
				stealSuccess = true
			end)
		end
		if not stealSuccess then pcall(function() if fireproximityprompt then fireproximityprompt(prompt); stealSuccess = true end end) end
		if not stealSuccess then pcall(function() prompt:InputHoldBegin(); task.wait(FAST_DUR); prompt:InputHoldEnd() end) end
		task.wait(0.08)
		if progressConnection then progressConnection:Disconnect(); progressConnection = nil end
		ResetProgressBar(); task.wait(0.05); data.ready = true; isStealing = false; G.isStealing = false
	end)
end
local G_autoStealConn = nil
local function startAutoSteal()
	if G_autoStealConn then return end
	G_autoStealConn = RunService.Heartbeat:Connect(function()
		if not G.autoGrabEnabled or isStealing then return end
		local p, _, n = findNearestPrompt()
		if p then executeSteal(p, n) end
	end)
end
local function stopAutoSteal()
	if G_autoStealConn then G_autoStealConn:Disconnect(); G_autoStealConn = nil end
	isStealing = false; G.isStealing = false; ResetProgressBar()
end
local gui=Instance.new("ScreenGui")
gui.Name="YeicoDuels"; gui.ResetOnSpawn=false; gui.DisplayOrder=10; gui.Parent=LP:WaitForChild("PlayerGui")
local StealBar = Instance.new("Frame", gui)
StealBar.Name = "StealBar"; StealBar.Size = UDim2.new(0,320,0,54)
StealBar.Position = UDim2.new(0.5,-160,1,-110)
StealBar.BackgroundColor3 = Color3.fromRGB(14,14,16); StealBar.BackgroundTransparency = 0.08
StealBar.BorderSizePixel = 0; StealBar.Visible = false; StealBar.ZIndex = 10; StealBar.Active = true
addCorner(StealBar, 12); addStroke(StealBar, C.RED, 1.5, 0.4)
do
	local sbTitle = Instance.new("TextLabel", StealBar)
	sbTitle.Size = UDim2.new(0,80,0,16); sbTitle.Position = UDim2.new(0,10,0,4)
	sbTitle.BackgroundTransparency = 1; sbTitle.Text = "AUTO STEAL"
	sbTitle.Font = Enum.Font.GothamBlack; sbTitle.TextSize = 10
	sbTitle.TextColor3 = C.RED; sbTitle.TextXAlignment = Enum.TextXAlignment.Left; sbTitle.ZIndex = 11
	local sbStatus = Instance.new("TextLabel", StealBar)
	sbStatus.Size = UDim2.new(0,90,0,16); sbStatus.Position = UDim2.new(0,10,0,20)
	sbStatus.BackgroundTransparency = 1; sbStatus.Text = "READY"
	sbStatus.Font = Enum.Font.Gotham; sbStatus.TextSize = 10
	sbStatus.TextColor3 = C.WHITE; sbStatus.TextTransparency = 0.3
	sbStatus.TextXAlignment = Enum.TextXAlignment.Left; sbStatus.ZIndex = 11
	ProgressLabel = sbStatus
	local sbPercent = Instance.new("TextLabel", StealBar)
	sbPercent.Size = UDim2.new(0,40,0,16); sbPercent.Position = UDim2.new(1,-50,0,20)
	sbPercent.BackgroundTransparency = 1; sbPercent.Text = ""
	sbPercent.Font = Enum.Font.GothamBlack; sbPercent.TextSize = 12
	sbPercent.TextColor3 = C.WHITE; sbPercent.TextXAlignment = Enum.TextXAlignment.Right; sbPercent.ZIndex = 11
	ProgressPercentLabel = sbPercent
	local radLbl = Instance.new("TextLabel", StealBar)
	radLbl.Size = UDim2.new(0,36,0,16); radLbl.Position = UDim2.new(1,-168,0,4)
	radLbl.BackgroundTransparency = 1; radLbl.Text = "Radius"
	radLbl.Font = Enum.Font.Gotham; radLbl.TextSize = 9
	radLbl.TextColor3 = C.DIM; radLbl.TextXAlignment = Enum.TextXAlignment.Right; radLbl.ZIndex = 11
	local radMinus = Instance.new("TextButton", StealBar)
	radMinus.Size = UDim2.new(0,18,0,16); radMinus.Position = UDim2.new(1,-128,0,4)
	radMinus.BackgroundColor3 = Color3.fromRGB(30,30,36); radMinus.BorderSizePixel = 0
	radMinus.Text = "-"; radMinus.TextColor3 = C.RED2
	radMinus.Font = Enum.Font.GothamBold; radMinus.TextSize = 13; radMinus.ZIndex = 12
	addCorner(radMinus, 4); addStroke(radMinus, C.RED, 1, 0.5)
	local radVal = Instance.new("TextButton", StealBar)
	radVal.Size = UDim2.new(0,36,0,16); radVal.Position = UDim2.new(1,-108,0,4)
	radVal.BackgroundColor3 = C.ON_BG; radVal.BorderSizePixel = 0
	radVal.Text = tostring(G.grabRadius); radVal.TextColor3 = C.RED2
	radVal.Font = Enum.Font.GothamBlack; radVal.TextSize = 10; radVal.ZIndex = 12
	addCorner(radVal, 4)
	local radPlus = Instance.new("TextButton", StealBar)
	radPlus.Size = UDim2.new(0,18,0,16); radPlus.Position = UDim2.new(1,-70,0,4)
	radPlus.BackgroundColor3 = Color3.fromRGB(8,30,10); radPlus.BorderSizePixel = 0
	radPlus.Text = "+"; radPlus.TextColor3 = Color3.fromRGB(80,220,80)
	radPlus.Font = Enum.Font.GothamBold; radPlus.TextSize = 13; radPlus.ZIndex = 12
	addCorner(radPlus, 4); addStroke(radPlus, Color3.fromRGB(30,160,40), 1, 0.5)
	local function applyRadius(n)
		n = math.floor(math.clamp(n, 5, 300))
		G.grabRadius = n; radVal.Text = tostring(n)
		if G.radValInBar then G.radValInBar.Text = tostring(n) end
		if G.radMobBtn   then G.radMobBtn.Text   = tostring(n) end
		saveConfig()
	end
	radMinus.MouseButton1Click:Connect(function() applyRadius(G.grabRadius - 1) end)
	radPlus.MouseButton1Click:Connect(function()  applyRadius(G.grabRadius + 1) end)
	local holdMinus, holdPlus = false, false
	radMinus.MouseButton1Down:Connect(function() holdMinus = true end); radMinus.MouseButton1Up:Connect(function() holdMinus = false end)
	radPlus.MouseButton1Down:Connect(function() holdPlus = true end); radPlus.MouseButton1Up:Connect(function() holdPlus = false end)
	local _holdT = 0; local _holdDelay = 0
	RunService.Heartbeat:Connect(function(dt)
		if not (holdMinus or holdPlus) then _holdDelay = 0; return end
		_holdDelay = _holdDelay + dt
		if _holdDelay < 0.5 then return end
		_holdT = _holdT + dt
		if _holdT >= 0.07 then _holdT = 0
			if holdMinus then applyRadius(G.grabRadius - 1) end
			if holdPlus  then applyRadius(G.grabRadius + 1) end
		end
	end)
	local _radTyping = false
	radVal.MouseButton1Click:Connect(function()
		if _radTyping then return end; _radTyping = true
		local tb = Instance.new("TextBox", StealBar)
		tb.Size = radVal.Size; tb.Position = radVal.Position
		tb.BackgroundColor3 = C.CARD2; tb.BorderSizePixel = 0
		tb.Text = tostring(G.grabRadius); tb.TextColor3 = C.WHITE
		tb.Font = Enum.Font.GothamBlack; tb.TextSize = 10
		tb.ClearTextOnFocus = false; tb.ZIndex = 13
		addCorner(tb, 4); addStroke(tb, C.RED, 1, 0.4); tb:CaptureFocus()
		tb.FocusLost:Connect(function()
			local num = tonumber(tb.Text)
			if num then applyRadius(num) end
			tb:Destroy(); _radTyping = false
		end)
	end)
	RunService.Heartbeat:Connect(function()
		if not _radTyping then
			local t = tostring(G.grabRadius)
			if radVal.Text ~= t then radVal.Text = t end
		end
	end)
	local sbBg = Instance.new("Frame", StealBar)
	sbBg.Size = UDim2.new(1,-20,0,12); sbBg.Position = UDim2.new(0,10,0,36)
	sbBg.BackgroundColor3 = Color3.fromRGB(22,22,28); sbBg.BackgroundTransparency = 0.2
	sbBg.BorderSizePixel = 0; sbBg.ZIndex = 11; addCorner(sbBg, 6)
	ProgressBarFill = Instance.new("Frame", sbBg)
	ProgressBarFill.Size = UDim2.new(0,0,1,0)
	ProgressBarFill.BackgroundColor3 = C.RED; ProgressBarFill.BorderSizePixel = 0; ProgressBarFill.ZIndex = 12
	addCorner(ProgressBarFill, 6)
end
local rebuildMobPanel,cfgToggleBtns,setMobileMode
-- PATCHED saveConfig: added autoTPKey
local function saveConfig()
	if not writefile then return end
	local mobBtnSave={}
	for _,id in ipairs(DEFAULT_MOB_BTNS) do mobBtnSave[id]=mobBtnEnabled[id] end
	pcall(function() writefile("K7MiniHubConfig.json",HS:JSONEncode({
		normalSpeed=G.NS,carrySpeed=G.CS,grabRadius=G.grabRadius,stealDuration=G.grabDuration,
		speedToggleKey=KB.SpeedToggle.Name,dropBrainrotKey=KB.DropBrainrot.Name,autoLeftKey=KB.AutoLeft.Name,autoRightKey=KB.AutoRight.Name,
		autoBatKey=KB.AutoBat.Name,tpLeftKey=KB.TPLeft.Name,
		autoPlayLeftKey=KB.AutoPlayLeft.Name,autoPlayRightKey=KB.AutoPlayRight.Name,tpDownKey=KB.TPDown.Name,floatToggleKey=KB.FloatToggle.Name,
		autoTPKey=KB.AutoTP.Name,
		antiRagdoll=G.antiRagdollEnabled,autoStealEnabled=G.autoGrabEnabled,infiniteJump=G.infJumpEnabled,
		medusaCounter=G.medusaCounterEnabled,brainrotReturnLeft=G.brainrotLeftEnabled,brainrotReturnRight=G.brainrotRightEnabled,
		tpAutoEnabled=G_tpAutoEnabled,
		carryMode=G.speedMode,autoBat=G.autoBatEnabled,autoSwing=G.autoSwingEnabled,autoPlayCountdown=G.autoPlayCountdownEnabled,
		removeAccessories=G.removeAccessoriesEnabled,unwalk=G.unwalkEnabled,
		shinyGraphics=G.shinyEnabled,optimizer=G.optimizerEnabled,ultraMode=G.ultraModeEnabled,
		ijGravityPercent=G.IJ_GravityPercent,ijHopPower=G.IJ_HopPower,
		floatEnabled=G.floatEnabled,noCamCollision=G.noCamCollisionEnabled,floatStuds=G.FLOAT_STUDS,
		mobBtnEnabled=mobBtnSave,mobileMode=G.mobileMode, apOffsets=AP_Offsets, aprOffsets=APR_Offsets,
		medusaMode=G.medusaModeEnabled,
	})) end)
end
local buildWPOffsetPanel
local sidePanel=Instance.new("Frame",gui)
sidePanel.Size=UDim2.new(0,155,0,0); sidePanel.BackgroundColor3=Color3.fromRGB(0,0,0)
sidePanel.BorderSizePixel=0; sidePanel.Visible=false; sidePanel.ZIndex=200; sidePanel.ClipsDescendants=true
addCorner(sidePanel,7); addStroke(sidePanel,C.RED,1,0.4)
local sidePanelContent=Instance.new("Frame",sidePanel)
sidePanelContent.Size=UDim2.new(1,0,1,0); sidePanelContent.BackgroundTransparency=1; sidePanelContent.ZIndex=201
local currentSidePanel=nil
local function closeSidePanel()
	TS:Create(sidePanel,TweenInfo.new(0.13),{Size=UDim2.new(0,155,0,0)}):Play()
	task.delay(0.14,function() sidePanel.Visible=false; currentSidePanel=nil end)
end
local function openSidePanel(sourceBtn,setupFn,panelH)
	local x=sidePanel.Parent and sourceBtn.AbsolutePosition.X or 0
	for _,ch in ipairs(sidePanelContent:GetChildren()) do ch:Destroy() end
	setupFn(sidePanelContent)
	local main2=gui:FindFirstChild("K7Main")
	local px = main2 and (main2.AbsolutePosition.X+main2.AbsoluteSize.X+6) or (x+231)
	local py = sourceBtn.AbsolutePosition.Y
	sidePanel.Position=UDim2.new(0,px,0,py); sidePanel.Size=UDim2.new(0,155,0,0)
	sidePanel.Visible=true; currentSidePanel=sourceBtn
	TS:Create(sidePanel,TweenInfo.new(0.16),{Size=UDim2.new(0,155,0,panelH)}):Play()
end
UIS.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
	if currentSidePanel then
		local mp=inp.Position; local ap=sidePanel.AbsolutePosition; local as=sidePanel.AbsoluteSize
		if not(mp.X>=ap.X and mp.X<=ap.X+as.X and mp.Y>=ap.Y and mp.Y<=ap.Y+as.Y) then closeSidePanel() end
	end
end)
local function makeSidePanelInput(parent,labelText,defaultVal,yOff,onChanged)
	local lbl=Instance.new("TextLabel",parent); lbl.Size=UDim2.new(1,-10,0,16); lbl.Position=UDim2.new(0,8,0,yOff)
	lbl.BackgroundTransparency=1; lbl.Text=labelText; lbl.TextColor3=C.DIM; lbl.Font=Enum.Font.Gotham; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=202
	local tb=Instance.new("TextBox",parent); tb.Size=UDim2.new(1,-16,0,22); tb.Position=UDim2.new(0,8,0,yOff+17)
	tb.BackgroundColor3=C.CARD2; tb.BorderSizePixel=0; tb.Text=tostring(defaultVal); tb.TextColor3=C.WHITE
	tb.Font=Enum.Font.GothamBold; tb.TextSize=11; tb.ZIndex=202; tb.ClearTextOnFocus=false
	addCorner(tb,4); addStroke(tb,C.RED,1,0.6); tb.FocusLost:Connect(function() onChanged(tb) end)
	return tb
end
local MAIN_W  = G.isMobile and 240 or 225
local MAIN_H  = G.isMobile and 420 or 440
local BH      = G.isMobile and 30 or 26
local TS_     = G.isMobile and 12 or 10
local GAP     = G.isMobile and 36 or 30
local main=Instance.new("Frame",gui)
main.Name="K7Main"; main.Size=UDim2.new(0,MAIN_W,0,MAIN_H); main.Position=UDim2.new(0.5,-MAIN_W/2,0,60)
main.BackgroundColor3=C.BG; main.BorderSizePixel=0; main.ClipsDescendants=true
addCorner(main,10); addStroke(main,C.RED,1.5,0.3); makeDraggable(main)
-- YB toggle button (always visible, top-right corner)
local ybBtn=Instance.new("TextButton",gui)
ybBtn.Size=UDim2.new(0,38,0,38); ybBtn.Position=UDim2.new(1,-48,0,8)
ybBtn.BackgroundColor3=Color3.fromRGB(0,40,110); ybBtn.BorderSizePixel=0; ybBtn.ZIndex=20
ybBtn.Text="YB"; ybBtn.TextColor3=Color3.fromRGB(100,180,255); ybBtn.Font=Enum.Font.GothamBlack; ybBtn.TextSize=13
addCorner(ybBtn,10); addStroke(ybBtn,Color3.fromRGB(0,100,220),2,0)
ybBtn.MouseButton1Click:Connect(function()
	main.Visible=not main.Visible
	ybBtn.BackgroundColor3=main.Visible and Color3.fromRGB(0,80,180) or Color3.fromRGB(0,40,110)
end)
local mobToggleBtn
do
	local HEADER_H = 54
	local header=Instance.new("Frame",main)
	header.Size=UDim2.new(1,0,0,HEADER_H); header.BackgroundColor3=Color3.fromRGB(0,0,0)
	header.BorderSizePixel=0; addCorner(header,10)
	-- Big title label YEICO DUELS
	local titleLblBig=Instance.new("TextLabel",header)
	titleLblBig.Size=UDim2.new(1,0,0,20); titleLblBig.Position=UDim2.new(0,0,0,2)
	titleLblBig.BackgroundTransparency=1; titleLblBig.Text="YEICO DUELS"
	titleLblBig.TextColor3=Color3.fromRGB(0,140,255); titleLblBig.Font=Enum.Font.GothamBlack; titleLblBig.TextSize=15
	titleLblBig.TextXAlignment=Enum.TextXAlignment.Center
	local hfix=Instance.new("Frame",main); hfix.Size=UDim2.new(1,0,0,10)
	hfix.Position=UDim2.new(0,0,0,HEADER_H-10); hfix.BackgroundColor3=Color3.fromRGB(0,0,0); hfix.BorderSizePixel=0
	local accent=Instance.new("Frame",main); accent.Size=UDim2.new(1,0,0,2)
	accent.Position=UDim2.new(0,0,0,HEADER_H); accent.BackgroundColor3=C.RED; accent.BorderSizePixel=0
	local closeBtn=Instance.new("TextButton",header)
	closeBtn.Size=UDim2.new(0,24,0,24); closeBtn.Position=UDim2.new(1,-28,0,8)
	closeBtn.BackgroundColor3=Color3.fromRGB(0,50,130); closeBtn.BorderSizePixel=0
	closeBtn.Text="X"; closeBtn.TextColor3=C.WHITE; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=12
	addCorner(closeBtn,5)
	local pingLbl=Instance.new("TextLabel",header)
	pingLbl.Size=UDim2.new(0,70,0,14); pingLbl.Position=UDim2.new(1,-102,0,9)
	pingLbl.BackgroundTransparency=1; pingLbl.Text="Ping: --ms"
	pingLbl.TextColor3=Color3.fromRGB(200,200,210); pingLbl.Font=Enum.Font.GothamBold; pingLbl.TextSize=9
	pingLbl.TextXAlignment=Enum.TextXAlignment.Right
	local fpsLbl=Instance.new("TextLabel",header)
	fpsLbl.Size=UDim2.new(0,70,0,14); fpsLbl.Position=UDim2.new(1,-102,0,26)
	fpsLbl.BackgroundTransparency=1; fpsLbl.Text="FPS: --"
	fpsLbl.TextColor3=Color3.fromRGB(100,255,100); fpsLbl.Font=Enum.Font.GothamBold; fpsLbl.TextSize=9
	fpsLbl.TextXAlignment=Enum.TextXAlignment.Right
	local avatarFrame=Instance.new("Frame",header)
	avatarFrame.Size=UDim2.new(0,32,0,32); avatarFrame.Position=UDim2.new(0,7,0,11)
	avatarFrame.BackgroundColor3=Color3.fromRGB(0,20,50); avatarFrame.BorderSizePixel=0
	addCorner(avatarFrame,16); addStroke(avatarFrame,C.RED,1.5,0.3)
	local avatarImg=Instance.new("ImageLabel",avatarFrame)
	avatarImg.Size=UDim2.new(1,-4,1,-4); avatarImg.Position=UDim2.new(0,2,0,2)
	avatarImg.BackgroundTransparency=1; avatarImg.BorderSizePixel=0; addCorner(avatarImg,14)
	pcall(function() avatarImg.Image="https://www.roblox.com/headshot-thumbnail/image?userId="..LP.UserId.."&width=48&height=48&format=png" end)
	local userLbl=Instance.new("TextLabel",header)
	userLbl.Size=UDim2.new(0,110,0,16); userLbl.Position=UDim2.new(0,44,0,10)
	userLbl.BackgroundTransparency=1; userLbl.Text="@"..(LP.DisplayName or LP.Name)
	userLbl.TextColor3=C.WHITE; userLbl.Font=Enum.Font.GothamBlack; userLbl.TextSize=10
	userLbl.TextXAlignment=Enum.TextXAlignment.Left; userLbl.TextTruncate=Enum.TextTruncate.AtEnd
	local badgeFrame=Instance.new("Frame",header)
	badgeFrame.Size=UDim2.new(0,80,0,15); badgeFrame.Position=UDim2.new(0,44,0,28)
	badgeFrame.BackgroundColor3=Color3.fromRGB(0,40,110); badgeFrame.BorderSizePixel=0; addCorner(badgeFrame,4)
	addStroke(badgeFrame,Color3.fromRGB(0,100,220),1,0.2)
	local badgeLbl=Instance.new("TextLabel",badgeFrame)
	badgeLbl.Size=UDim2.new(1,0,1,0); badgeLbl.BackgroundTransparency=1
	badgeLbl.Text="YEICO DUELS"; badgeLbl.TextColor3=Color3.fromRGB(100,200,255); badgeLbl.Font=Enum.Font.GothamBlack; badgeLbl.TextSize=8
	if G.isMobile then mobToggleBtn=Instance.new("TextButton",header); mobToggleBtn.Size=UDim2.new(0,0,0,0) end
	local _fpsCount,_fpsLast=0,tick()
	RunService.RenderStepped:Connect(function()
		_fpsCount=_fpsCount+1
		local now=tick()
		if now-_fpsLast>=0.5 then
			local fps=math.floor(_fpsCount/(now-_fpsLast)+0.5)
			_fpsCount=0; _fpsLast=now; fpsLbl.Text="FPS: "..fps
			fpsLbl.TextColor3=fps>=60 and Color3.fromRGB(100,255,100) or fps>=30 and Color3.fromRGB(255,200,50) or Color3.fromRGB(200,200,210)
		end
	end)
	do local _pt=0; RunService.Heartbeat:Connect(function()
		local now=tick(); if now-_pt<2 then return end; _pt=now
		pcall(function()
			local ping=math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
			pingLbl.Text="Ping: "..ping.."ms"
			pingLbl.TextColor3=ping<80 and Color3.fromRGB(100,255,100) or ping<150 and Color3.fromRGB(255,200,50) or Color3.fromRGB(200,200,210)
		end)
	end) end
	if G.isMobile then
		local reopenBtn=Instance.new("TextButton",gui)
		reopenBtn.Size=UDim2.new(0,38,0,38); reopenBtn.Position=UDim2.new(1,-48,0,8)
		reopenBtn.BackgroundColor3=Color3.fromRGB(0,40,110); reopenBtn.BackgroundTransparency=0; reopenBtn.BorderSizePixel=0
		reopenBtn.Text="YB"; reopenBtn.TextColor3=Color3.fromRGB(100,180,255)
		reopenBtn.Font=Enum.Font.GothamBlack; reopenBtn.TextSize=13
		addCorner(reopenBtn,10); addStroke(reopenBtn,Color3.fromRGB(0,100,220),2,0)
		reopenBtn.Visible=false; reopenBtn.ZIndex=10
		closeBtn.MouseButton1Click:Connect(function() main.Visible=false; reopenBtn.Visible=true end)
		reopenBtn.MouseButton1Click:Connect(function() reopenBtn.Visible=false; main.Visible=true end)
	else
		closeBtn.MouseButton1Click:Connect(function() main.Visible=false end)
	end
end
local scrollFrame=Instance.new("ScrollingFrame",main)
scrollFrame.Size=UDim2.new(1,0,1,-58); scrollFrame.Position=UDim2.new(0,0,0,58); scrollFrame.BackgroundTransparency=1
scrollFrame.BorderSizePixel=0; scrollFrame.ScrollBarThickness=3; scrollFrame.ScrollBarImageColor3=C.RED
scrollFrame.CanvasSize=UDim2.new(0,0,0,0); scrollFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
local yPos=6
local function makeBadge(parent,kbName)
	if G.isMobile then return nil end
	local badge=Instance.new("TextLabel",parent); badge.Size=UDim2.new(0,24,0,16); badge.Position=UDim2.new(0,5,0.5,-8)
	badge.BackgroundColor3=Color3.fromRGB(35,35,42); badge.BackgroundTransparency=0; badge.BorderSizePixel=0
	badge.Text=getKeyName(KB[kbName]); badge.TextColor3=C.RED2; badge.Font=Enum.Font.GothamBold; badge.TextSize=8; badge.ZIndex=5
	addCorner(badge,3); addStroke(badge,C.RED,1,0.5)
	local bb=Instance.new("TextButton",parent); bb.Size=badge.Size; bb.Position=badge.Position; bb.BackgroundTransparency=1; bb.Text=""; bb.ZIndex=6
	bb.MouseButton1Click:Connect(function()
		if G.waitingForKey then return end
		G.waitingForKey=kbName; badge.Text="..."; badge.BackgroundColor3=Color3.fromRGB(50,50,58)
	end)
	G.allBadges[kbName]=badge; return badge
end
local function makeToggleKB(text,kbName,callback)
	local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
	btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=""; btn.Font=Enum.Font.Gotham; btn.TextSize=TS_
	addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
	local xOff=6; if kbName and not G.isMobile then makeBadge(btn,kbName); xOff=34 end
	-- pop-out icon button on the right
	local popIcon=Instance.new("TextButton",btn); popIcon.Size=UDim2.new(0,18,0,18); popIcon.Position=UDim2.new(1,-22,0.5,-9)
	popIcon.BackgroundColor3=Color3.fromRGB(0,30,70); popIcon.BorderSizePixel=0; popIcon.Text="↗"; popIcon.TextColor3=Color3.fromRGB(80,140,255)
	popIcon.Font=Enum.Font.GothamBold; popIcon.TextSize=10; popIcon.ZIndex=6; addCorner(popIcon,4)
	local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-xOff-26,1,0); lbl.Position=UDim2.new(0,xOff,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left
	local active=false
	local popped=false; local popFrame=nil
	local function setVisual(s)
		active=s; btn.BackgroundColor3=s and C.ON_BG or C.CARD; lbl.TextColor3=s and C.RED2 or C.WHITE
		local st=Instance.new("UIStroke",btn); st.Color=s and C.RED or C.BORDER; st.Thickness=1; st.Transparency=s and 0 or 0.2
		if popFrame then
			popFrame.BackgroundColor3=s and Color3.fromRGB(0,30,80) or Color3.fromRGB(5,5,10)
			local pl=popFrame:FindFirstChildOfClass("TextLabel"); if pl then pl.TextColor3=s and C.RED2 or C.WHITE end
		end
	end
	popIcon.MouseButton1Click:Connect(function()
		popped=not popped
		popIcon.BackgroundColor3=popped and Color3.fromRGB(60,60,70) or Color3.fromRGB(0,30,70)
		popIcon.TextColor3=popped and Color3.fromRGB(160,160,160) or Color3.fromRGB(80,140,255)
		if popped then
			popFrame=Instance.new("Frame",gui); popFrame.Size=UDim2.new(0,MAIN_W-20,0,BH+4); popFrame.BackgroundColor3=Color3.fromRGB(5,5,10)
			popFrame.BorderSizePixel=0; popFrame.Active=true; popFrame.ZIndex=50
			local mx=main.AbsolutePosition.X; local my=btn.AbsolutePosition.Y
			popFrame.Position=UDim2.new(0,mx,0,my)
			addCorner(popFrame,6); addStroke(popFrame,Color3.fromRGB(0,80,180),1.5,0)
			makeDraggable(popFrame)
			local pl=Instance.new("TextLabel",popFrame); pl.Size=UDim2.new(1,-38,1,0); pl.Position=UDim2.new(0,8,0,0)
			pl.BackgroundTransparency=1; pl.Text=text; pl.TextColor3=active and C.RED2 or C.WHITE
			pl.Font=Enum.Font.GothamBold; pl.TextSize=TS_; pl.TextXAlignment=Enum.TextXAlignment.Left; pl.ZIndex=51
			local togBtn=Instance.new("TextButton",popFrame)
			togBtn.Size=UDim2.new(0,30,0,BH-2); togBtn.Position=UDim2.new(1,-34,0.5,-(BH-2)/2)
			togBtn.BackgroundColor3=active and Color3.fromRGB(0,60,150) or Color3.fromRGB(30,30,40)
			togBtn.BorderSizePixel=0; togBtn.Text=active and "ON" or "OFF"
			togBtn.TextColor3=active and Color3.fromRGB(100,200,255) or Color3.fromRGB(120,120,130)
			togBtn.Font=Enum.Font.GothamBold; togBtn.TextSize=9; togBtn.ZIndex=52; addCorner(togBtn,4)
			togBtn.MouseButton1Click:Connect(function()
				active=not active; setVisual(active); callback(active)
				togBtn.BackgroundColor3=active and Color3.fromRGB(0,60,150) or Color3.fromRGB(30,30,40)
				togBtn.Text=active and "ON" or "OFF"
				togBtn.TextColor3=active and Color3.fromRGB(100,200,255) or Color3.fromRGB(120,120,130)
			end)
		else
			if popFrame then popFrame:Destroy(); popFrame=nil end
		end
	end)
	btn.MouseButton1Click:Connect(function() if G.waitingForKey then return end; active=not active; setVisual(active); callback(active) end)
	yPos=yPos+GAP; return setVisual,btn
end
local function makeSimpleToggle(text,callback)
	local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
	btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=""; btn.Font=Enum.Font.Gotham; btn.TextSize=TS_
	addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
	-- pop-out icon
	local popIcon=Instance.new("TextButton",btn); popIcon.Size=UDim2.new(0,18,0,18); popIcon.Position=UDim2.new(1,-22,0.5,-9)
	popIcon.BackgroundColor3=Color3.fromRGB(0,30,70); popIcon.BorderSizePixel=0; popIcon.Text="↗"; popIcon.TextColor3=Color3.fromRGB(80,140,255)
	popIcon.Font=Enum.Font.GothamBold; popIcon.TextSize=10; popIcon.ZIndex=6; addCorner(popIcon,4)
	local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-30,1,0); lbl.Position=UDim2.new(0,8,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left
	local active=false
	local popped=false; local popFrame=nil
	local function setVisual(s)
		active=s; btn.BackgroundColor3=s and C.ON_BG or C.CARD; lbl.TextColor3=s and C.RED2 or C.WHITE
		if popFrame then
			local pl=popFrame:FindFirstChildOfClass("TextLabel"); if pl then pl.TextColor3=s and C.RED2 or C.WHITE end
			local tb=popFrame:FindFirstChildOfClass("TextButton")
			if tb then tb.BackgroundColor3=s and Color3.fromRGB(0,60,150) or Color3.fromRGB(30,30,40); tb.Text=s and "ON" or "OFF"; tb.TextColor3=s and Color3.fromRGB(100,200,255) or Color3.fromRGB(120,120,130) end
		end
	end
	popIcon.MouseButton1Click:Connect(function()
		popped=not popped
		popIcon.BackgroundColor3=popped and Color3.fromRGB(60,60,70) or Color3.fromRGB(0,30,70)
		popIcon.TextColor3=popped and Color3.fromRGB(160,160,160) or Color3.fromRGB(80,140,255)
		if popped then
			popFrame=Instance.new("Frame",gui); popFrame.Size=UDim2.new(0,MAIN_W-20,0,BH+4); popFrame.BackgroundColor3=Color3.fromRGB(5,5,10)
			popFrame.BorderSizePixel=0; popFrame.Active=true; popFrame.ZIndex=50
			local mx=main.AbsolutePosition.X; local my=btn.AbsolutePosition.Y
			popFrame.Position=UDim2.new(0,mx,0,my)
			addCorner(popFrame,6); addStroke(popFrame,Color3.fromRGB(0,80,180),1.5,0)
			makeDraggable(popFrame)
			local pl=Instance.new("TextLabel",popFrame); pl.Size=UDim2.new(1,-38,1,0); pl.Position=UDim2.new(0,8,0,0)
			pl.BackgroundTransparency=1; pl.Text=text; pl.TextColor3=active and C.RED2 or C.WHITE
			pl.Font=Enum.Font.GothamBold; pl.TextSize=TS_; pl.TextXAlignment=Enum.TextXAlignment.Left; pl.ZIndex=51
			local togBtn=Instance.new("TextButton",popFrame)
			togBtn.Size=UDim2.new(0,30,0,BH-2); togBtn.Position=UDim2.new(1,-34,0.5,-(BH-2)/2)
			togBtn.BackgroundColor3=active and Color3.fromRGB(0,60,150) or Color3.fromRGB(30,30,40)
			togBtn.BorderSizePixel=0; togBtn.Text=active and "ON" or "OFF"
			togBtn.TextColor3=active and Color3.fromRGB(100,200,255) or Color3.fromRGB(120,120,130)
			togBtn.Font=Enum.Font.GothamBold; togBtn.TextSize=9; togBtn.ZIndex=52; addCorner(togBtn,4)
			togBtn.MouseButton1Click:Connect(function()
				active=not active; setVisual(active); callback(active)
				togBtn.BackgroundColor3=active and Color3.fromRGB(0,60,150) or Color3.fromRGB(30,30,40)
				togBtn.Text=active and "ON" or "OFF"
				togBtn.TextColor3=active and Color3.fromRGB(100,200,255) or Color3.fromRGB(120,120,130)
			end)
		else
			if popFrame then popFrame:Destroy(); popFrame=nil end
		end
	end)
	btn.MouseButton1Click:Connect(function() active=not active; setVisual(active); callback(active) end)
	yPos=yPos+GAP; return btn,setVisual
end
local function makeOrangeToggle(text, callback)
	local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
	btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=text; btn.TextColor3=C.WHITE; btn.Font=Enum.Font.Gotham; btn.TextSize=TS_
	addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
	local active=false
	local function setVisual(s)
		active=s; btn.BackgroundColor3 = s and C.ORANGE_BG or C.CARD; btn.TextColor3 = s and C.ORANGE or C.WHITE
		local st=Instance.new("UIStroke",btn); st.Color=s and C.ORANGE or C.BORDER; st.Thickness=1; st.Transparency=s and 0 or 0.2
	end
	btn.MouseButton1Click:Connect(function() active=not active; setVisual(active); callback(active) end)
	yPos=yPos+GAP; return btn,setVisual
end
local function makeDropdownBtn(text,kbName)
	local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
	btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=""; addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
	local xOff=6; if kbName and not G.isMobile then makeBadge(btn,kbName); xOff=34 end
	local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-xOff-(G.isMobile and 28 or 16),1,0); lbl.Position=UDim2.new(0,xOff,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left
	if G.isMobile then
		local cfgBtn=Instance.new("TextButton",btn)
		cfgBtn.Size=UDim2.new(0,24,0,BH-4); cfgBtn.Position=UDim2.new(1,-28,0.5,-(BH-4)/2)
		cfgBtn.BackgroundColor3=Color3.fromRGB(35,35,42); cfgBtn.BorderSizePixel=0
		cfgBtn.Text="⚙"; cfgBtn.TextColor3=C.RED2; cfgBtn.Font=Enum.Font.Gotham; cfgBtn.TextSize=12
		cfgBtn.ZIndex=5; addCorner(cfgBtn,4); addStroke(cfgBtn,C.RED,1,0.5)
		yPos=yPos+GAP; return btn,lbl,cfgBtn
	else
		local cfg=Instance.new("TextLabel",btn); cfg.Size=UDim2.new(0,14,1,0); cfg.Position=UDim2.new(1,-16,0,0)
		cfg.BackgroundTransparency=1; cfg.Text="⚙"; cfg.TextColor3=C.DIM; cfg.Font=Enum.Font.Gotham; cfg.TextSize=10
		yPos=yPos+GAP; return btn,lbl
	end
end
local function makeCircleToggle(text,callback)
	local fH=G.isMobile and 42 or 36
	local frame=Instance.new("Frame",scrollFrame); frame.Size=UDim2.new(1,-12,0,fH); frame.Position=UDim2.new(0,6,0,yPos)
	frame.BackgroundColor3=C.CARD; frame.BorderSizePixel=0; addCorner(frame,6); addStroke(frame,C.BORDER,1,0.2)
	local lbl=Instance.new("TextLabel",frame); lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,8,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextWrapped=true
	local pillW,pillH=34,17
	local pill=Instance.new("Frame",frame); pill.Size=UDim2.new(0,pillW,0,pillH); pill.Position=UDim2.new(1,-pillW-8,0.5,-pillH/2)
	pill.BackgroundColor3=Color3.fromRGB(40,40,48); pill.BorderSizePixel=0; addCorner(pill,10)
	local circle=Instance.new("Frame",pill); circle.Size=UDim2.new(0,pillH-4,0,pillH-4); circle.Position=UDim2.new(0,2,0.5,-(pillH-4)/2)
	circle.BackgroundColor3=C.DIM; circle.BorderSizePixel=0; addCorner(circle,10)
	local active=false
	local function setVisual(s)
		active=s; frame.BackgroundColor3=s and Color3.fromRGB(38,38,46) or C.CARD; lbl.TextColor3=s and C.RED2 or C.WHITE
		pill.BackgroundColor3=s and C.RED or Color3.fromRGB(40,40,48); circle.BackgroundColor3=s and C.WHITE or C.DIM
		TS:Create(circle,TweenInfo.new(0.14),{Position=s and UDim2.new(1,-(pillH-4)-2,0.5,-(pillH-4)/2) or UDim2.new(0,2,0.5,-(pillH-4)/2)}):Play()
	end
	local clickBtn=Instance.new("TextButton",frame); clickBtn.Size=UDim2.new(1,0,1,0); clickBtn.BackgroundTransparency=1; clickBtn.Text=""; clickBtn.ZIndex=4
	clickBtn.MouseButton1Click:Connect(function() if G.waitingForKey then return end; active=not active; setVisual(active); callback(active) end)
	yPos=yPos+fH+6; return setVisual,frame
end
local function makeSection(text)
	local lbl=Instance.new("TextLabel",scrollFrame); lbl.Size=UDim2.new(1,-12,0,18); lbl.Position=UDim2.new(0,6,0,yPos+2)
	lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C.RED; lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=9; lbl.TextXAlignment=Enum.TextXAlignment.Left
	yPos=yPos+22
end
local function setupSpeedIndicator(char)
	local head=char:WaitForChild("Head",5); if not head then return end
	local bb=Instance.new("BillboardGui",head); bb.Size=UDim2.new(0,110,0,22); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
	G.speedLabel=Instance.new("TextLabel",bb); G.speedLabel.Size=UDim2.new(1,0,1,0); G.speedLabel.BackgroundTransparency=1
	G.speedLabel.Text="Speed: 0"; G.speedLabel.TextColor3=C.RED2; G.speedLabel.Font=Enum.Font.GothamBold; G.speedLabel.TextScaled=true
end
LP.CharacterAdded:Connect(function(char)
	G.lastHealth=100; task.wait(0.5); setupSpeedIndicator(char)
	if G.medusaCounterEnabled then setupMedusa(char) end
	if G.unwalkEnabled then startUnwalk() end
	if G.infJumpEnabled then task.wait(0.2); setupIJForce() end
	task.spawn(function()
		task.wait(0.3)
		pcall(function()
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then hrp:SetNetworkOwner(LP) end
		end)
	end)
end)
if LP.Character then setupSpeedIndicator(LP.Character) end
local function buildMovementSection()
	makeSection("MOVEMENT")
	local btn,lbl,cfgBtn=makeDropdownBtn("Speed","SpeedToggle")
	G.speedBtn=function(state) G.speedMode=state; btn.BackgroundColor3=state and C.ON_BG or C.CARD; lbl.TextColor3=state and C.RED2 or C.WHITE end
	btn.MouseButton1Click:Connect(function() G.speedMode=not G.speedMode; G.speedBtn(G.speedMode) end)
	local function openSpeedPanel()
		if currentSidePanel==btn then closeSidePanel(); return end
		openSidePanel(btn,function(p)
			makeSidePanelInput(p,"Normal Speed:",G.NS,8,function(tb) local n=tonumber(tb.Text); if n then G.NS=math.max(0.1,math.min(n,9999)); tb.Text=tostring(G.NS); saveConfig() end end)
			makeSidePanelInput(p,"Carry Speed:",G.CS,50,function(tb) local n=tonumber(tb.Text); if n then G.CS=math.max(0.1,math.min(n,9999)); tb.Text=tostring(G.CS); saveConfig() end end)
		end,96)
	end
	btn.MouseButton2Click:Connect(openSpeedPanel)
	if cfgBtn then cfgBtn.MouseButton1Click:Connect(openSpeedPanel) end
	local btn2,lbl2,cfgBtn2=makeDropdownBtn("Float","FloatToggle")
	local function setFloatVis(state) G.floatEnabled=state; btn2.BackgroundColor3=state and C.ON_BG or C.CARD; lbl2.TextColor3=state and C.RED2 or C.WHITE end
	G.floatSetVisual=setFloatVis
	btn2.MouseButton1Click:Connect(function() G.floatEnabled=not G.floatEnabled; if G.floatEnabled then startFloat() else stopFloat() end; setFloatVis(G.floatEnabled) end)
	local function openFloatPanel()
		if currentSidePanel==btn2 then closeSidePanel(); return end
		openSidePanel(btn2,function(p)
			makeSidePanelInput(p,"Float Height (studs):",G.FLOAT_STUDS,8,function(tb)
				local n=tonumber(tb.Text); if n then G.FLOAT_STUDS=math.clamp(n,1,500); tb.Text=tostring(G.FLOAT_STUDS)
					if G.floatEnabled and G.FLOAT_TARGET_Y then local ch=LP.Character; if ch then local h=ch:FindFirstChild("HumanoidRootPart"); if h then FLOAT_BASE_Y=h.Position.Y+G.FLOAT_STUDS; G.FLOAT_TARGET_Y=FLOAT_BASE_Y end end end
					saveConfig() end
			end)
		end,52)
	end
	btn2.MouseButton2Click:Connect(openFloatPanel)
	if cfgBtn2 then cfgBtn2.MouseButton1Click:Connect(openFloatPanel) end
end
local function buildTeleportSection()
	makeSection("TELEPORT")
	do
		local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
		btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=""; addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
		-- PATCHED: AutoTP keybind badge
		local xOff=6
		if not G.isMobile then
			local badge=Instance.new("TextLabel",btn); badge.Size=UDim2.new(0,24,0,16); badge.Position=UDim2.new(0,5,0.5,-8)
			badge.BackgroundColor3=Color3.fromRGB(35,35,42); badge.BorderSizePixel=0
			badge.Text=getKeyName(KB.AutoTP); badge.TextColor3=C.RED2; badge.Font=Enum.Font.GothamBold; badge.TextSize=8; badge.ZIndex=5
			addCorner(badge,3); addStroke(badge,C.RED,1,0.5)
			G.allBadges["AutoTP"]=badge; xOff=34
			local bb=Instance.new("TextButton",btn); bb.Size=badge.Size; bb.Position=badge.Position; bb.BackgroundTransparency=1; bb.Text=""; bb.ZIndex=6
			bb.MouseButton1Click:Connect(function()
				if G.waitingForKey then return end
				G.waitingForKey="AutoTP"; badge.Text="..."; badge.BackgroundColor3=Color3.fromRGB(50,50,58)
			end)
		end
		local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-xOff-4,1,0); lbl.Position=UDim2.new(0,xOff,0,0)
		lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left
		local active=false
		local function updateBtnText()
			local side=G_myPlotSide
			if side=="left" then lbl.Text="TP LEFT"
			elseif side=="right" then lbl.Text="TP RIGHT"
			else lbl.Text="TP (?)" end
			lbl.TextColor3=active and C.RED2 or C.WHITE
			btn.BackgroundColor3=active and C.ON_BG or C.CARD
		end
		updateBtnText()
		G_tpAutoBtn=lbl; G_updateTPBtn=updateBtnText
		G.tpAutoSetVisual=function(on) active=on; G_tpAutoEnabled=on; updateBtnText() end
		btn.MouseButton1Click:Connect(function()
			if G.waitingForKey then return end
			active=not active; G_tpAutoEnabled=active
			task.spawn(function() refreshMyPlotSide() end)
			updateBtnText()
		end)
		G.brainrotLeftBtn=function(on) if G_myPlotSide=="left" then active=on; G_tpAutoEnabled=on; updateBtnText() end end
		G.brainrotRightBtn=function(on) if G_myPlotSide=="right" then active=on; G_tpAutoEnabled=on; updateBtnText() end end
		yPos=yPos+GAP
	end
	do
		local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
		btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=""; addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
		local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-10,1,0); lbl.Position=UDim2.new(0,6,0,0)
		lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left
		local function refresh()
			lbl.Text="Auto Play after TP"
			lbl.TextColor3=G_autoPlayAfterTP and C.RED2 or C.WHITE
			btn.BackgroundColor3=G_autoPlayAfterTP and C.ON_BG or C.CARD
		end
		refresh()
		btn.MouseButton1Click:Connect(function()
			if G.waitingForKey then return end
			G_autoPlayAfterTP=not G_autoPlayAfterTP; refresh()
		end)
		yPos=yPos+GAP
	end
	do
		local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
		btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=""; addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
		local xOff=6; if not G.isMobile then makeBadge(btn,"DropBrainrot"); xOff=34 end
		local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-xOff-4,1,0); lbl.Position=UDim2.new(0,xOff,0,0)
		lbl.BackgroundTransparency=1; lbl.Text="Drop Brainrot"; lbl.TextColor3=C.WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left
		btn.MouseButton1Click:Connect(function() if G.waitingForKey then return end; runDrop() end); yPos=yPos+GAP
	end
	do
		local btn=Instance.new("TextButton",scrollFrame); btn.Size=UDim2.new(1,-12,0,BH); btn.Position=UDim2.new(0,6,0,yPos)
		btn.BackgroundColor3=C.CARD; btn.BorderSizePixel=0; btn.Text=""; addCorner(btn,6); addStroke(btn,C.BORDER,1,0.2)
		local xOff=6; if not G.isMobile then makeBadge(btn,"TPDown"); xOff=34 end
		local lbl=Instance.new("TextLabel",btn); lbl.Size=UDim2.new(1,-xOff-4,1,0); lbl.Position=UDim2.new(0,xOff,0,0)
		lbl.BackgroundTransparency=1; lbl.Text="TP Down"; lbl.TextColor3=C.WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=TS_; lbl.TextXAlignment=Enum.TextXAlignment.Left
		local busy=false
		btn.MouseButton1Click:Connect(function() if busy or G.waitingForKey then return end; busy=true; btn.BackgroundColor3=C.ON_BG; runTPDown(); task.delay(0.5,function() btn.BackgroundColor3=C.CARD; busy=false end) end)
		yPos=yPos+GAP
	end
end
local function buildAutoSection()
	makeSection("AUTO")
	local btn,lbl,cfgBtn=makeDropdownBtn("Auto Steal",nil)
	G.autoStealSetVisual=function(s) G.autoGrabEnabled=s; btn.BackgroundColor3=s and C.ON_BG or C.CARD; lbl.TextColor3=s and C.RED2 or C.WHITE; StealBar.Visible=s end
	btn.MouseButton1Click:Connect(function() G.autoGrabEnabled=not G.autoGrabEnabled; G.autoStealSetVisual(G.autoGrabEnabled); if G.autoGrabEnabled then startAutoSteal() else stopAutoSteal() end end)
	local function openStealPanel()
		if currentSidePanel==btn then closeSidePanel(); return end
		openSidePanel(btn,function(p) makeSidePanelInput(p,"Steal Duration:",G.grabDuration,8,function(tb) local n=tonumber(tb.Text); if n then G.grabDuration=math.clamp(n,0.05,5); tb.Text=string.format("%.2f",G.grabDuration) end end) end,52)
	end
	btn.MouseButton2Click:Connect(openStealPanel)
	if cfgBtn then cfgBtn.MouseButton1Click:Connect(openStealPanel) end
	local al,_=makeToggleKB("Auto Left","AutoLeft",function(on) G.autoLeftEnabled=on; if on then startAutoLeft() else stopAutoLeft() end end)
	local ar,_=makeToggleKB("Auto Right","AutoRight",function(on) G.autoRightEnabled=on; if on then startAutoRight() else stopAutoRight() end end)
	G.autoLeftSetVisual=al; G.autoRightSetVisual=ar
	local apl_vis,apl_btn=makeToggleKB("Auto Play Left","AutoPlayLeft",function(on)
		G.autoPlayLeftEnabled=on
		if on then
			if G.autoBatEnabled then disableAutoBat() end
			if G.autoPlayRightEnabled then stopAutoPlayRight(); G.autoPlayRightEnabled=false; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
			startAutoPlayLeft()
		else stopAutoPlayLeft() end
	end)
	G.autoPlayLeftSetVisual=apl_vis
	apl_btn.MouseButton2Click:Connect(function() buildWPOffsetPanel("left") end)
	do local gb=Instance.new("TextButton",apl_btn); gb.Size=UDim2.new(0,22,0,22); gb.Position=UDim2.new(1,-26,0.5,-11)
	gb.BackgroundColor3=Color3.fromRGB(20,20,28); gb.BorderSizePixel=0; gb.Text="⚙"; gb.TextColor3=Color3.fromRGB(80,180,255)
	gb.Font=Enum.Font.Gotham; gb.TextSize=13; gb.ZIndex=5; addCorner(gb,4)
	gb.MouseButton1Click:Connect(function() buildWPOffsetPanel("left") end) end
	local apr_vis,apr_btn=makeToggleKB("Auto Play Right","AutoPlayRight",function(on)
		G.autoPlayRightEnabled=on
		if on then
			if G.autoBatEnabled then disableAutoBat() end
			if G.autoPlayLeftEnabled then stopAutoPlayLeft(); G.autoPlayLeftEnabled=false; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
			startAutoPlayRight()
		else stopAutoPlayRight() end
	end)
	G.autoPlayRightSetVisual=apr_vis
	apr_btn.MouseButton2Click:Connect(function() buildWPOffsetPanel("right") end)
	do local gb=Instance.new("TextButton",apr_btn); gb.Size=UDim2.new(0,22,0,22); gb.Position=UDim2.new(1,-26,0.5,-11)
	gb.BackgroundColor3=Color3.fromRGB(20,20,28); gb.BorderSizePixel=0; gb.Text="⚙"; gb.TextColor3=Color3.fromRGB(255,100,80)
	gb.Font=Enum.Font.Gotham; gb.TextSize=13; gb.ZIndex=5; addCorner(gb,4)
	gb.MouseButton1Click:Connect(function() buildWPOffsetPanel("right") end) end
	local apcVis,_=makeCircleToggle("Auto Play After Countdown",function(on)
		G.autoPlayCountdownEnabled=on
		if on then local ex=workspace:FindFirstChild("Countdown"); if ex and ex:IsA("Sound") then monitorCountdown(ex) end end
	end)
	G.autoPlayCountdownSetVisual=function(s) G.autoPlayCountdownEnabled=s; apcVis(s) end
	makeSection("BAT AIMBOT")
	local vis,_=makeToggleKB("Bat Aimbot","AutoBat",function(on)
		G.autoBatEnabled=on
		if on then if G.autoPlayLeftEnabled or G.autoPlayRightEnabled then disableAllAutoPlay() end end
	end)
	G.autoBatSetVisual=vis
	local swingBtn,swingVis=makeSimpleToggle("Auto Swing",function(on) G.autoSwingEnabled=on end)
	G.autoSwingSetVisual=function(s) G.autoSwingEnabled=s; swingVis(s) end
end
local function buildDefenseSection()
	makeSection("DEFENSE")
	local ab,abVis=makeSimpleToggle("Anti Ragdoll",function(on) G.antiRagdollEnabled=on end)
	G.antiRagdollSetVisual=function(s) G.antiRagdollEnabled=s; abVis(s) end
	local mc,mcVis=makeSimpleToggle("Medusa Counter",function(on) G.medusaCounterEnabled=on; if on then setupMedusa(LP.Character) else for _,conn in pairs(G.medusaConns) do pcall(function() conn:Disconnect() end) end; G.medusaConns={} end end)
	G.medusaSetVisual=function(s) G.medusaCounterEnabled=s; mcVis(s) end
	local mmBtn, mmVis = makeOrangeToggle("Medusa Mode", function(on) G.medusaModeEnabled = on end)
	G.medusaModeSetVisual = function(s) G.medusaModeEnabled = s; mmVis(s) end
	local unwalkBtn,unwalkVis=makeSimpleToggle("Unwalk",function(on) G.unwalkEnabled=on; if on then startUnwalk() else stopUnwalk() end end)
	G.unwalkSetVisual=function(s) G.unwalkEnabled=s; unwalkVis(s) end
	local ij,ijVis=makeSimpleToggle("Infinite Jump",function(on) G.infJumpEnabled=on; if on then startInfiniteJump() else stopInfiniteJump() end end)
	G.infJumpSetVisual=function(s) G.infJumpEnabled=s; ijVis(s) end
end
local function buildVisualSection()
	makeSection("VISUAL")
	local nc,ncVis=makeSimpleToggle("No Cam Collision",function(on) if on then enableNoCameraCollision() else disableNoCameraCollision() end end)
	G.noCamSetVisual=function(s) G.noCamCollisionEnabled=s; ncVis(s) end
	local sg,sgVis=makeSimpleToggle("Shiny Graphics",function(on) if on then enableShinyGraphics() else disableShinyGraphics() end end)
	G.shinySetVisual=function(s) G.shinyEnabled=s; sgVis(s) end
	local op,opVis=makeSimpleToggle("Anti Lag",function(on) if on then enableOptimizer() else disableOptimizer() end end)
	G.optimizerSetVisual=function(s) G.optimizerEnabled=s; opVis(s) end
	local um,umVis=makeSimpleToggle("Ultra Mode",function(on) if on then enableUltraMode() else disableUltraMode() end end)
	G.ultraModeSetVisual=function(s) G.ultraModeEnabled=s; umVis(s) end
	local ra,raVis=makeSimpleToggle("Remove Accessories",function(on) if on then enableRemoveAccessories() else disableRemoveAccessories() end end)
	G.removeAccSetVisual=function(s) G.removeAccessoriesEnabled=s; raVis(s) end
end
buildMovementSection()
buildTeleportSection()
buildAutoSection()
buildDefenseSection()
buildVisualSection()
-- ========== NUEVAS OPCIONES ==========
-- PLAYER ESP
local G_espEnabled = false
local G_espConns = {}
local G_espHighlights = {}
local function enableESP()
	G_espEnabled = true
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and p.Character then
			local hl = Instance.new("SelectionBox")
			hl.Color3 = Color3.fromRGB(0, 180, 255)
			hl.LineThickness = 0.06
			hl.SurfaceTransparency = 0.7
			hl.SurfaceColor3 = Color3.fromRGB(0, 100, 200)
			hl.Adornee = p.Character
			hl.Parent = workspace
			G_espHighlights[p.UserId] = hl
		end
	end
	table.insert(G_espConns, Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function(c)
			task.wait(0.5)
			if not G_espEnabled then return end
			local hl = Instance.new("SelectionBox")
			hl.Color3 = Color3.fromRGB(0, 180, 255)
			hl.LineThickness = 0.06
			hl.SurfaceTransparency = 0.7
			hl.SurfaceColor3 = Color3.fromRGB(0, 100, 200)
			hl.Adornee = c
			hl.Parent = workspace
			G_espHighlights[p.UserId] = hl
		end)
	end))
	table.insert(G_espConns, Players.PlayerRemoving:Connect(function(p)
		if G_espHighlights[p.UserId] then
			G_espHighlights[p.UserId]:Destroy()
			G_espHighlights[p.UserId] = nil
		end
	end))
end
local function disableESP()
	G_espEnabled = false
	for _, conn in ipairs(G_espConns) do pcall(function() conn:Disconnect() end) end
	G_espConns = {}
	for _, hl in pairs(G_espHighlights) do pcall(function() hl:Destroy() end) end
	G_espHighlights = {}
end
-- LAGGER BACK - implementacion interna (no carga scripts externos)
local G_laggerEnabled = false
local G_laggerConn = nil
local function enableLaggerBack()
	G_laggerEnabled = true
	if G_laggerConn then G_laggerConn:Disconnect(); G_laggerConn = nil end
	G_laggerConn = RunService.Heartbeat:Connect(function()
		if not G_laggerEnabled then return end
		pcall(function()
			local c = LP.Character; if not c then return end
			local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
			-- Lagger: fire multiple remote events rapidly to cause lag back effect
			for _, v in ipairs(game:GetDescendants()) do
				if v:IsA("RemoteEvent") and (v.Name:lower():find("punch") or v.Name:lower():find("hit") or v.Name:lower():find("damage") or v.Name:lower():find("attack")) then
					pcall(function() v:FireServer() end)
				end
			end
		end)
	end)
end
local function disableLaggerBack()
	G_laggerEnabled = false
	if G_laggerConn then G_laggerConn:Disconnect(); G_laggerConn = nil end
end
-- BUILD EXTRAS SECTION
local function buildExtrasSection()
	makeSection("EXTRAS")
	-- Player ESP
	local espVis, _ = makeSimpleToggle("Player ESP", function(on)
		if on then enableESP() else disableESP() end
	end)
	-- Lagger Back
	local lagBtn, lagVis = makeSimpleToggle("Lagger Back", function(on)
		G_laggerEnabled = on
		if on then
			enableLaggerBack()
		else
			disableLaggerBack()
		end
	end)
end
buildExtrasSection()
-- YEICO DUELS: Discord button
do
	local discordBtn=Instance.new("TextButton",scrollFrame)
	discordBtn.Size=UDim2.new(1,-12,0,BH); discordBtn.Position=UDim2.new(0,6,0,yPos)
	discordBtn.BackgroundColor3=Color3.fromRGB(0,30,80); discordBtn.BorderSizePixel=0; discordBtn.Text=""
	addCorner(discordBtn,6); addStroke(discordBtn,Color3.fromRGB(0,100,200),1.5,0)
	local dLbl=Instance.new("TextLabel",discordBtn); dLbl.Size=UDim2.new(1,-8,1,0); dLbl.Position=UDim2.new(0,8,0,0)
	dLbl.BackgroundTransparency=1; dLbl.Text="DISCORD  discord.gg/mWPcXAStr"; dLbl.TextColor3=Color3.fromRGB(100,180,255)
	dLbl.Font=Enum.Font.GothamBlack; dLbl.TextSize=TS_; dLbl.TextXAlignment=Enum.TextXAlignment.Left; dLbl.TextTruncate=Enum.TextTruncate.AtEnd
	local copied=false
	discordBtn.MouseButton1Click:Connect(function()
		if copied then return end
		pcall(function()
			if setclipboard then setclipboard("https://discord.gg/mWPcXAStr") end
		end)
		copied=true; dLbl.Text="✓ COPIED!"; dLbl.TextColor3=Color3.fromRGB(80,255,120)
		task.delay(2,function() copied=false; dLbl.Text="DISCORD  discord.gg/mWPcXAStr"; dLbl.TextColor3=Color3.fromRGB(100,180,255) end)
	end)
	yPos=yPos+GAP
end
-- YEICO DUELS: Pop-out floating labels for special options
local G_popouts = {}
local function createPopout(id, labelText, color)
	if G_popouts[id] then G_popouts[id]:Destroy() end
	local pf=Instance.new("Frame",gui); pf.Name="Popout_"..id
	pf.Size=UDim2.new(0,160,0,28); pf.BackgroundColor3=Color3.fromRGB(0,0,0)
	pf.BackgroundTransparency=0.05; pf.BorderSizePixel=0; pf.Active=true; pf.ZIndex=100
	-- position them stacked to the right of main UI
	local idx = 0; for _ in pairs(G_popouts) do idx=idx+1 end
	pf.Position=UDim2.new(0, (MAIN_W or 245)+26, 0, 80+idx*36)
	addCorner(pf,8)
	local st=Instance.new("UIStroke",pf); st.Color=color or Color3.fromRGB(0,100,200); st.Thickness=1.5; st.Transparency=0
	local lbl=Instance.new("TextLabel",pf); lbl.Size=UDim2.new(1,-8,1,0); lbl.Position=UDim2.new(0,8,0,0)
	lbl.BackgroundTransparency=1; lbl.Text="▶ "..labelText; lbl.TextColor3=color or Color3.fromRGB(80,180,255)
	lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
	makeDraggable(pf); G_popouts[id]=pf
	-- animate in
	pf.BackgroundTransparency=1; st.Transparency=1
	TS:Create(pf,TweenInfo.new(0.2),{BackgroundTransparency=0.05}):Play()
	TS:Create(st,TweenInfo.new(0.2),{Transparency=0}):Play()
end
local function removePopout(id)
	local pf=G_popouts[id]; if not pf then return end
	TS:Create(pf,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play()
	task.delay(0.16,function() if pf and pf.Parent then pf:Destroy() end end)
	G_popouts[id]=nil
end
-- Hook pop-outs onto special options
local _origAPLVis = G.autoPlayLeftSetVisual
G.autoPlayLeftSetVisual = function(s)
	if _origAPLVis then _origAPLVis(s) end
	if s then createPopout("apl","Auto Play Left",Color3.fromRGB(80,180,255)) else removePopout("apl") end
end
local _origAPRVis = G.autoPlayRightSetVisual
G.autoPlayRightSetVisual = function(s)
	if _origAPRVis then _origAPRVis(s) end
	if s then createPopout("apr","Auto Play Right",Color3.fromRGB(255,100,80)) else removePopout("apr") end
end
local _origBatVis = G.autoBatSetVisual
G.autoBatSetVisual = function(s)
	if _origBatVis then _origBatVis(s) end
	if s then createPopout("bat","Bat Aimbot  spd:59",Color3.fromRGB(255,200,50)) else removePopout("bat") end
end
local _origTPDVis_hook = nil
-- TP Down pop-out on key press (no toggle visual, it's a one-shot)
local _origTPDown = runTPDown
runTPDown = function()
	_origTPDown()
	createPopout("tpd","TP Down",Color3.fromRGB(150,100,255))
	task.delay(1.5,function() removePopout("tpd") end)
end
-- Drop Brainrot pop-out
local _origRunDrop = runDrop
runDrop = function()
	_origRunDrop()
	createPopout("drop","Drop Brainrot",Color3.fromRGB(255,140,50))
	task.delay(1.5,function() removePopout("drop") end)
end
local function buildProgressBar()
	local pbFrame=Instance.new("Frame",gui); pbFrame.Size=UDim2.new(0,240,0,52); pbFrame.Position=UDim2.new(0,16,0,700)
	pbFrame.BackgroundColor3=C.BG; pbFrame.BorderSizePixel=0; pbFrame.Active=true
	addCorner(pbFrame,8); addStroke(pbFrame,C.RED,1,0.5); makeDraggable(pbFrame)
	local progressPct=Instance.new("TextLabel",pbFrame); progressPct.Size=UDim2.new(0,40,0,16); progressPct.Position=UDim2.new(0,8,0,4)
	progressPct.BackgroundTransparency=1; progressPct.Text="0%"; progressPct.TextColor3=C.RED2; progressPct.Font=Enum.Font.GothamBold; progressPct.TextSize=11; progressPct.TextXAlignment=Enum.TextXAlignment.Left
	local radTextLbl=Instance.new("TextLabel",pbFrame); radTextLbl.Size=UDim2.new(0,40,0,16); radTextLbl.Position=UDim2.new(1,-110,0,4)
	radTextLbl.BackgroundTransparency=1; radTextLbl.Text="Radius:"; radTextLbl.TextColor3=C.WHITE; radTextLbl.Font=Enum.Font.GothamBold; radTextLbl.TextSize=10; radTextLbl.TextXAlignment=Enum.TextXAlignment.Right
	G.radValInBar=Instance.new("TextButton",pbFrame); G.radValInBar.Size=UDim2.new(0,44,0,16); G.radValInBar.Position=UDim2.new(1,-58,0,4)
	G.radValInBar.BackgroundColor3=C.ON_BG; G.radValInBar.BorderSizePixel=0
	G.radValInBar.Text=tostring(G.grabRadius); G.radValInBar.TextColor3=C.RED2; G.radValInBar.Font=Enum.Font.GothamBlack; G.radValInBar.TextSize=11
	addCorner(G.radValInBar,4)
	local radTyping=false
	G.radValInBar.MouseButton1Click:Connect(function()
		if radTyping then return end; radTyping=true
		local tb=Instance.new("TextBox",pbFrame); tb.Size=G.radValInBar.Size; tb.Position=G.radValInBar.Position
		tb.BackgroundColor3=C.CARD2; tb.BorderSizePixel=0; tb.Text=tostring(G.grabRadius)
		tb.TextColor3=C.WHITE; tb.Font=Enum.Font.GothamBlack; tb.TextSize=11; tb.ClearTextOnFocus=false
		addCorner(tb,4); addStroke(tb,C.RED,1,0.4); tb:CaptureFocus()
		tb.FocusLost:Connect(function() local num=tonumber(tb.Text); if num and num>=5 and num<=300 then G.grabRadius=math.floor(num); G.radValInBar.Text=tostring(G.grabRadius); if G.radMobBtn then G.radMobBtn.Text=tostring(G.grabRadius) end; saveConfig() end; tb:Destroy(); radTyping=false end)
	end)
	local progressBg=Instance.new("Frame",pbFrame); progressBg.Size=UDim2.new(1,-16,0,12); progressBg.Position=UDim2.new(0,8,0,34)
	progressBg.BackgroundColor3=C.CARD2; progressBg.BorderSizePixel=0; addCorner(progressBg,6)
	local progressFill=Instance.new("Frame",progressBg); progressFill.Size=UDim2.new(0,0,1,0); progressFill.BackgroundColor3=C.RED; progressFill.BorderSizePixel=0; addCorner(progressFill,6)
	do local _pbT=0; RunService.Heartbeat:Connect(function()
		if not isStealing then
			if progressFill.Size.X.Scale ~= 0 then progressFill.Size=UDim2.new(0,0,1,0); progressPct.Text="0%" end
			return
		end
		local now=tick(); if now-_pbT < 0.05 then return end; _pbT=now
		local prog=math.clamp((now-stealStartTime)/(G.grabDuration or 0.25),0,1)
		progressFill.Size=UDim2.new(prog,0,1,0); progressPct.Text=math.floor(prog*100).."%"
	end) end
end
buildProgressBar()
local _wpPanelSide = nil
buildWPOffsetPanel = function(side)
	local existing = gui:FindFirstChild("WPOffsetPanel")
	if existing then
		if _wpPanelSide == side then existing:Destroy(); _wpPanelSide=nil; return end
		existing:Destroy()
	end
	_wpPanelSide = side
	local offsets  = side == "left" and AP_Offsets  or APR_Offsets
	local label    = side == "left" and "LEFT"       or "RIGHT"
	local color    = side == "left" and Color3.fromRGB(80,180,255) or Color3.fromRGB(255,100,80)
	local WP_COLORS= { Color3.fromRGB(80,180,255), Color3.fromRGB(100,255,120), Color3.fromRGB(255,220,50), Color3.fromRGB(255,80,160), }
	local AX_COLORS = {Color3.fromRGB(255,110,110), Color3.fromRGB(100,180,255)}
	local HDR_H=26; local COL_W=46; local COL_GAP=6; local PAD=8
	local panelW  = PAD + 4*COL_W + 3*COL_GAP + PAD
	local panelH  = HDR_H + 14 + (10+18)*2 + 12
	local panel = Instance.new("Frame", gui)
	panel.Name="WPOffsetPanel"; panel.Size=UDim2.new(0,panelW,0,panelH); panel.Position=UDim2.new(0,270,0,200)
	panel.BackgroundColor3=C.BG; panel.BorderSizePixel=0; panel.Active=true; panel.ZIndex=50
	addCorner(panel,10); addStroke(panel,color,1.5,0.35); makeDraggable(panel)
	local hdrBar=Instance.new("Frame",panel); hdrBar.Size=UDim2.new(1,0,0,HDR_H)
	hdrBar.BackgroundColor3=Color3.fromRGB(14,14,20); hdrBar.BorderSizePixel=0; hdrBar.ZIndex=51; addCorner(hdrBar,10)
	local hdrFix=Instance.new("Frame",panel); hdrFix.Size=UDim2.new(1,0,0,10); hdrFix.Position=UDim2.new(0,0,0,HDR_H-10)
	hdrFix.BackgroundColor3=Color3.fromRGB(14,14,20); hdrFix.BorderSizePixel=0; hdrFix.ZIndex=51
	local hdrLbl=Instance.new("TextLabel",hdrBar); hdrLbl.Size=UDim2.new(1,-80,1,0); hdrLbl.Position=UDim2.new(0,10,0,0)
	hdrLbl.BackgroundTransparency=1; hdrLbl.Text="OFFSET  "..label
	hdrLbl.Font=Enum.Font.GothamBlack; hdrLbl.TextSize=11; hdrLbl.TextColor3=color
	hdrLbl.TextXAlignment=Enum.TextXAlignment.Left; hdrLbl.ZIndex=52
	local rstBtn=Instance.new("TextButton",hdrBar); rstBtn.Size=UDim2.new(0,32,0,18); rstBtn.Position=UDim2.new(1,-58,0.5,-9)
	rstBtn.BackgroundColor3=Color3.fromRGB(35,35,42); rstBtn.BorderSizePixel=0
	rstBtn.Text="RST"; rstBtn.TextColor3=Color3.fromRGB(220,220,220); rstBtn.Font=Enum.Font.GothamBlack; rstBtn.TextSize=9; rstBtn.ZIndex=53
	addCorner(rstBtn,4); addStroke(rstBtn,Color3.fromRGB(180,180,190),1,0.5)
	rstBtn.MouseButton1Click:Connect(function()
		for i=1,4 do offsets[i]={x=0,y=0,z=0} end
		saveConfig(); if G.refreshWPMarkers then G.refreshWPMarkers() end
		panel:Destroy(); _wpPanelSide=nil; buildWPOffsetPanel(side)
	end)
	local closeBtn=Instance.new("TextButton",hdrBar); closeBtn.Size=UDim2.new(0,20,0,18); closeBtn.Position=UDim2.new(1,-24,0.5,-9)
	closeBtn.BackgroundColor3=Color3.fromRGB(35,35,42); closeBtn.BorderSizePixel=0
	closeBtn.Text="X"; closeBtn.TextColor3=C.RED; closeBtn.Font=Enum.Font.GothamBlack; closeBtn.TextSize=10; closeBtn.ZIndex=53; addCorner(closeBtn,4)
	closeBtn.MouseButton1Click:Connect(function() panel:Destroy(); _wpPanelSide=nil end)
	local prefix = side=="left" and "L" or "R"
	for i=1,4 do
		local colX = PAD + (i-1)*(COL_W+COL_GAP); local off = offsets[i]; local wcolor = WP_COLORS[i]
		local wlbl=Instance.new("TextLabel",panel); wlbl.Size=UDim2.new(0,COL_W,0,14); wlbl.Position=UDim2.new(0,colX,0,HDR_H+4)
		wlbl.BackgroundTransparency=1; wlbl.Text=prefix..i; wlbl.Font=Enum.Font.GothamBlack; wlbl.TextSize=11; wlbl.TextColor3=wcolor
		wlbl.TextXAlignment=Enum.TextXAlignment.Center; wlbl.ZIndex=51
		local underline=Instance.new("Frame",panel); underline.Size=UDim2.new(0,COL_W-4,0,2); underline.Position=UDim2.new(0,colX+2,0,HDR_H+18)
		underline.BackgroundColor3=wcolor; underline.BorderSizePixel=0; underline.ZIndex=51; addCorner(underline,1)
		local axes={"x","z"}
		for j,axis in ipairs(axes) do
			local axColor=AX_COLORS[j]; local rowY = HDR_H + 22 + (j-1)*28
			local axLbl=Instance.new("TextLabel",panel); axLbl.Size=UDim2.new(0,COL_W,0,10); axLbl.Position=UDim2.new(0,colX,0,rowY)
			axLbl.BackgroundTransparency=1; axLbl.Text=axis:upper(); axLbl.Font=Enum.Font.GothamBlack; axLbl.TextSize=8; axLbl.TextColor3=axColor
			axLbl.TextXAlignment=Enum.TextXAlignment.Center; axLbl.ZIndex=51
			local minus=Instance.new("TextButton",panel); minus.Size=UDim2.new(0,14,0,16); minus.Position=UDim2.new(0,colX,0,rowY+10)
			minus.BackgroundColor3=Color3.fromRGB(28,28,38); minus.BorderSizePixel=0; minus.Text="-"; minus.TextColor3=axColor
			minus.Font=Enum.Font.GothamBlack; minus.TextSize=13; minus.ZIndex=52; addCorner(minus,3)
			local tb=Instance.new("TextBox",panel); tb.Size=UDim2.new(0,18,0,16); tb.Position=UDim2.new(0,colX+14,0,rowY+10)
			tb.BackgroundColor3=Color3.fromRGB(16,16,22); tb.BorderSizePixel=0; tb.Text=tostring(off[axis]); tb.TextColor3=C.WHITE
			tb.Font=Enum.Font.GothamBold; tb.TextSize=8; tb.ClearTextOnFocus=false; tb.ZIndex=52; addCorner(tb,3); addStroke(tb,axColor,1,0.6)
			local plus=Instance.new("TextButton",panel); plus.Size=UDim2.new(0,14,0,16); plus.Position=UDim2.new(0,colX+32,0,rowY+10)
			plus.BackgroundColor3=Color3.fromRGB(28,28,38); plus.BorderSizePixel=0; plus.Text="+"; plus.TextColor3=axColor
			plus.Font=Enum.Font.GothamBlack; plus.TextSize=13; plus.ZIndex=52; addCorner(plus,3)
			local function applyVal(v)
				local n=tonumber(v); if not n then return end
				off[axis]=math.floor(n*10)/10; tb.Text=tostring(off[axis])
				saveConfig(); if G.refreshWPMarkers then G.refreshWPMarkers() end
			end
			tb.FocusLost:Connect(function() applyVal(tb.Text) end)
			minus.MouseButton1Click:Connect(function() applyVal(tostring((off[axis] or 0)-1)) end)
			plus.MouseButton1Click:Connect(function() applyVal(tostring((off[axis] or 0)+1)) end)
		end
		if i < 4 then
			local vdiv=Instance.new("Frame",panel); vdiv.Size=UDim2.new(0,1,0,panelH-HDR_H-8)
			vdiv.Position=UDim2.new(0,colX+COL_W+COL_GAP/2-1,0,HDR_H+4)
			vdiv.BackgroundColor3=Color3.fromRGB(35,35,48); vdiv.BorderSizePixel=0; vdiv.ZIndex=51
		end
	end
end
do
	local WP_COLORS = { Color3.fromRGB(80,180,255), Color3.fromRGB(100,255,120), Color3.fromRGB(255,220,50), Color3.fromRGB(255,80,160), }
	local wpFolder = Instance.new("Folder", workspace); wpFolder.Name = "K7_WaypointMarkers"
	local markers = {}
	local function clearMarkers()
		for _, p in ipairs(markers) do pcall(function() p:Destroy() end) end; markers = {}
	end
	local function makeMarker(x, y, z, color, label)
		local part = Instance.new("Part", wpFolder); part.Size = Vector3.new(1.8, 0.4, 1.8)
		part.Material = Enum.Material.Neon; part.Color = color
		part.Anchored = true; part.CanCollide = false; part.CastShadow = false; part.Transparency = 0.2
		part.CFrame = CFrame.new(x, y + 0.3, z)
		local bb = Instance.new("BillboardGui", part); bb.Size = UDim2.new(0,44,0,22)
		bb.StudsOffset = Vector3.new(0,1.5,0); bb.AlwaysOnTop = true
		local lbl = Instance.new("TextLabel", bb); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
		lbl.Text = label; lbl.Font = Enum.Font.GothamBlack; lbl.TextSize = 15
		lbl.TextColor3 = color; lbl.TextStrokeTransparency = 0
		markers[#markers+1] = part
	end
	local function refreshMarkers()
		clearMarkers()
		local side = G_myPlotSide
		if side == "left" then
			for i, wp in ipairs(AP_Waypoints) do
				local off = AP_Offsets[i] or {x=0,y=0,z=0}
				makeMarker(wp.x+off.x, wp.y+off.y, wp.z+off.z, WP_COLORS[i], "L"..i)
			end
		elseif side == "right" then
			for i, wp in ipairs(APR_Waypoints) do
				local off = APR_Offsets[i] or {x=0,y=0,z=0}
				makeMarker(wp.x+off.x, wp.y+off.y, wp.z+off.z, WP_COLORS[i], "R"..i)
			end
		end
	end
	G.refreshWPMarkers = refreshMarkers
	if G_myPlotSide or G._wpMarkerPending then refreshMarkers(); G._wpMarkerPending = nil end
	local lastSide = G_myPlotSide
	do local _wt=0; RunService.Heartbeat:Connect(function()
		local now=tick(); if now-_wt < 1 then return end; _wt=now
		if G_myPlotSide ~= lastSide then lastSide = G_myPlotSide; refreshMarkers() end
	end) end
end
if G.isMobile then
	local msb = Instance.new("Frame", gui); msb.Size = UDim2.new(0,170,0,38); msb.Position = UDim2.new(0,16,1,-130)
	msb.BackgroundColor3 = C.BG; msb.BorderSizePixel = 0; msb.Active = true; msb.ZIndex = 10; msb.Visible = false
	addCorner(msb,8); addStroke(msb,C.RED,1,0.5); makeDraggable(msb)
	local pctLbl = Instance.new("TextLabel",msb); pctLbl.Size=UDim2.new(0,30,0,13); pctLbl.Position=UDim2.new(0,6,0,3)
	pctLbl.BackgroundTransparency=1; pctLbl.Text="0%"; pctLbl.TextColor3=C.RED2; pctLbl.Font=Enum.Font.GothamBold; pctLbl.TextSize=9
	pctLbl.TextXAlignment=Enum.TextXAlignment.Left; pctLbl.ZIndex=11
	local radTextLbl=Instance.new("TextLabel",msb); radTextLbl.Size=UDim2.new(0,30,0,13); radTextLbl.Position=UDim2.new(1,-80,0,3)
	radTextLbl.BackgroundTransparency=1; radTextLbl.Text="Radius:"; radTextLbl.TextColor3=C.WHITE; radTextLbl.Font=Enum.Font.GothamBold; radTextLbl.TextSize=8
	radTextLbl.TextXAlignment=Enum.TextXAlignment.Right; radTextLbl.ZIndex=11
	G.radMobBtn=Instance.new("TextButton",msb); G.radMobBtn.Size=UDim2.new(0,34,0,13); G.radMobBtn.Position=UDim2.new(1,-40,0,3)
	G.radMobBtn.BackgroundColor3=C.ON_BG; G.radMobBtn.BorderSizePixel=0; G.radMobBtn.Text=tostring(G.grabRadius); G.radMobBtn.TextColor3=C.RED2
	G.radMobBtn.Font=Enum.Font.GothamBlack; G.radMobBtn.TextSize=9; G.radMobBtn.ZIndex=12; addCorner(G.radMobBtn,4)
	local t2=false
	G.radMobBtn.MouseButton1Click:Connect(function()
		if t2 then return end; t2=true
		local tb=Instance.new("TextBox",msb); tb.Size=G.radMobBtn.Size; tb.Position=G.radMobBtn.Position
		tb.BackgroundColor3=C.CARD2; tb.BorderSizePixel=0; tb.Text=tostring(G.grabRadius)
		tb.TextColor3=C.WHITE; tb.Font=Enum.Font.GothamBlack; tb.TextSize=9; tb.ClearTextOnFocus=false; tb.ZIndex=13
		addCorner(tb,4); addStroke(tb,C.RED,1,0.4); tb:CaptureFocus()
		tb.FocusLost:Connect(function()
			local num=tonumber(tb.Text)
			if num and num>=5 and num<=300 then G.grabRadius=math.floor(num); G.radMobBtn.Text=tostring(G.grabRadius); if G.radValInBar then G.radValInBar.Text=tostring(G.grabRadius) end; saveConfig() end
			tb:Destroy(); t2=false
		end)
	end)
	local pbBg=Instance.new("Frame",msb); pbBg.Size=UDim2.new(1,-12,0,10); pbBg.Position=UDim2.new(0,6,0,24)
	pbBg.BackgroundColor3=C.CARD2; pbBg.BorderSizePixel=0; pbBg.ZIndex=11; addCorner(pbBg,5)
	local pbFill=Instance.new("Frame",pbBg); pbFill.Size=UDim2.new(0,0,1,0)
	pbFill.BackgroundColor3=C.RED; pbFill.BorderSizePixel=0; pbFill.ZIndex=12; addCorner(pbFill,5)
	RunService.Heartbeat:Connect(function()
		if isStealing then
			local prog=math.clamp((tick()-(stealStartTime or tick()))/(G.grabDuration or 0.25),0,1)
			pbFill.Size=UDim2.new(prog,0,1,0); pctLbl.Text=math.floor(prog*100).."%"
		else pbFill.Size=UDim2.new(0,0,1,0); pctLbl.Text="0%" end
	end)
	local _orig=G.autoStealSetVisual
	G.autoStealSetVisual=function(s) if _orig then _orig(s) end; msb.Visible=s end
	if G.autoGrabEnabled then msb.Visible=true end
end
-- PATCHED: Added AutoTP keybind handler
UIS.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if G.waitingForKey then
		local kc=input.KeyCode; if kc==Enum.KeyCode.Unknown then return end
		local orig=G.waitingForKey; G.waitingForKey=nil
		if kc==Enum.KeyCode.Escape then if G.allBadges[orig] then G.allBadges[orig].Text=getKeyName(KB[orig]); G.allBadges[orig].BackgroundColor3=Color3.fromRGB(35,35,42) end; return end
		KB[orig]=kc
		if G.allBadges[orig] then G.allBadges[orig].Text=getKeyName(kc); G.allBadges[orig].BackgroundColor3=Color3.fromRGB(35,35,42) end
		saveConfig(); return
	end
	if input.UserInputType~=Enum.UserInputType.Keyboard then return end
	local kc=input.KeyCode
	if kc==KB.SpeedToggle then G.speedMode=not G.speedMode; if G.speedBtn then G.speedBtn(G.speedMode) end
	elseif kc==KB.DropBrainrot then runDrop()
	elseif kc==KB.AutoLeft then G.autoLeftEnabled=not G.autoLeftEnabled; if G.autoLeftSetVisual then G.autoLeftSetVisual(G.autoLeftEnabled) end; if G.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
	elseif kc==KB.AutoRight then G.autoRightEnabled=not G.autoRightEnabled; if G.autoRightSetVisual then G.autoRightSetVisual(G.autoRightEnabled) end; if G.autoRightEnabled then startAutoRight() else stopAutoRight() end
	elseif kc==KB.AutoBat then
		G.autoBatEnabled=not G.autoBatEnabled
		if G.autoBatEnabled then
			if G.autoPlayLeftEnabled or G.autoPlayRightEnabled then disableAllAutoPlay() end
		end
		if G.autoBatSetVisual then G.autoBatSetVisual(G.autoBatEnabled) end
	elseif kc==KB.TPDown then runTPDown()
	elseif kc==KB.TPLeft then if not G.brainrotLeftEnabled and G.brainrotRightEnabled then G.brainrotRightEnabled=false; if G.brainrotRightBtn then G.brainrotRightBtn(false) end end; G.brainrotLeftEnabled=not G.brainrotLeftEnabled; if G.brainrotLeftBtn then G.brainrotLeftBtn(G.brainrotLeftEnabled) end
	elseif kc==KB.AutoPlayLeft then
		G.autoPlayLeftEnabled=not G.autoPlayLeftEnabled
		if G.autoPlayLeftEnabled then
			if G.autoBatEnabled then disableAutoBat() end
			if G.autoPlayRightEnabled then stopAutoPlayRight(); G.autoPlayRightEnabled=false; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
			startAutoPlayLeft()
		else stopAutoPlayLeft() end
		if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(G.autoPlayLeftEnabled) end
	elseif kc==KB.AutoPlayRight then
		G.autoPlayRightEnabled=not G.autoPlayRightEnabled
		if G.autoPlayRightEnabled then
			if G.autoBatEnabled then disableAutoBat() end
			if G.autoPlayLeftEnabled then stopAutoPlayLeft(); G.autoPlayLeftEnabled=false; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
			startAutoPlayRight()
		else stopAutoPlayRight() end
		if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(G.autoPlayRightEnabled) end
	elseif kc==KB.FloatToggle then
		G.floatEnabled=not G.floatEnabled; if G.floatEnabled then startFloat() else stopFloat() end
		if G.floatSetVisual then G.floatSetVisual(G.floatEnabled) end
	elseif kc==KB.AutoTP then
		G_tpAutoEnabled=not G_tpAutoEnabled
		task.spawn(function() refreshMyPlotSide() end)
		if G.tpAutoSetVisual then G.tpAutoSetVisual(G_tpAutoEnabled) end
	end
end)
local function buildMobileGUI()
	local _mobPanel=Instance.new("Frame",gui); _mobPanel.Name="K7Mobile"; _mobPanel.Size=UDim2.new(0,140,0,175)
	_mobPanel.Position=UDim2.new(1,-154,1,-194); _mobPanel.BackgroundColor3=Color3.fromRGB(10,10,12); _mobPanel.BackgroundTransparency=0.06
	_mobPanel.BorderSizePixel=0; _mobPanel.Active=true; _mobPanel.Visible=false
	addCorner(_mobPanel,10); addStroke(_mobPanel,C.RED,1.5,0.2); makeDraggable(_mobPanel)
	local actionsReopenBtn=Instance.new("TextButton",gui)
	actionsReopenBtn.Size=UDim2.new(0,90,0,22); actionsReopenBtn.Position=UDim2.new(1,-100,1,-170)
	actionsReopenBtn.BackgroundColor3=Color3.fromRGB(45,45,54); actionsReopenBtn.BackgroundTransparency=0.05
	actionsReopenBtn.BorderSizePixel=0; actionsReopenBtn.Text="K7 ACTIONS"; actionsReopenBtn.TextColor3=Color3.fromRGB(255,255,255)
	actionsReopenBtn.Font=Enum.Font.GothamBlack; actionsReopenBtn.TextSize=9
	addCorner(actionsReopenBtn,8); addStroke(actionsReopenBtn,Color3.fromRGB(160,160,170),1.5,0.2)
	actionsReopenBtn.Visible=false; actionsReopenBtn.ZIndex=10
	actionsReopenBtn.MouseButton1Click:Connect(function() _mobPanel.Visible=true; actionsReopenBtn.Visible=false end)
	local detachedBtns = {}
	local function saveDetached()
		if not writefile then return end
		local t = {}
		for id, data in pairs(detachedBtns) do
			if data.frame and data.frame.Parent then t[id]={x=data.frame.Position.X.Offset,y=data.frame.Position.Y.Offset} end
		end
		pcall(function() writefile("K7DetachedBtns.json",HS:JSONEncode(t)) end)
	end
	local function loadDetached()
		if not(isfile and isfile("K7DetachedBtns.json")) then return {} end
		local ok,t=pcall(function() return HS:JSONDecode(readfile("K7DetachedBtns.json")) end)
		return (ok and t) or {}
	end
	local savedDetached=loadDetached()
	do
		local hdr=Instance.new("Frame",_mobPanel); hdr.Size=UDim2.new(1,0,0,24); hdr.BackgroundColor3=Color3.fromRGB(18,18,22); hdr.BorderSizePixel=0; addCorner(hdr,10)
		local ttl=Instance.new("TextLabel",hdr); ttl.Size=UDim2.new(1,-54,1,0); ttl.Position=UDim2.new(0,6,0,0)
		ttl.BackgroundTransparency=1; ttl.Text="K7 ACTIONS"; ttl.TextColor3=C.RED2; ttl.Font=Enum.Font.GothamBlack; ttl.TextSize=9; ttl.TextXAlignment=Enum.TextXAlignment.Left
		local rst=Instance.new("TextButton",hdr); rst.Size=UDim2.new(0,32,0,18); rst.Position=UDim2.new(1,-55,0.5,-9)
		rst.BackgroundColor3=Color3.fromRGB(30,30,36); rst.BorderSizePixel=0; rst.Text="RST"; rst.TextColor3=Color3.fromRGB(220,220,220); rst.Font=Enum.Font.GothamBold; rst.TextSize=9; addCorner(rst,4); addStroke(rst,Color3.fromRGB(140,140,150),1,0.3)
		rst.MouseButton1Click:Connect(function()
			for id,data in pairs(detachedBtns) do
				if data.frame and data.frame.Parent then data.frame:Destroy() end
				if data.shadow and data.shadow.Parent then data.shadow:Destroy() end
			end
			detachedBtns={}; savedDetached={}; saveDetached(); rebuildMobPanel()
		end)
		local cx=Instance.new("TextButton",hdr); cx.Size=UDim2.new(0,18,0,18); cx.Position=UDim2.new(1,-21,0.5,-9)
		cx.BackgroundColor3=C.RED; cx.BorderSizePixel=0; cx.Text="X"; cx.TextColor3=C.WHITE; cx.Font=Enum.Font.GothamBold; cx.TextSize=10; addCorner(cx,4)
		cx.MouseButton1Click:Connect(function()
			_mobPanel.Visible=false
			local pp=_mobPanel.Position
			actionsReopenBtn.Position=UDim2.new(pp.X.Scale,pp.X.Offset,pp.Y.Scale,pp.Y.Offset-26)
			actionsReopenBtn.Visible=true
		end)
	end
	local mobScroll=Instance.new("ScrollingFrame",_mobPanel); mobScroll.Size=UDim2.new(1,0,1,-25); mobScroll.Position=UDim2.new(0,0,0,25)
	mobScroll.BackgroundTransparency=1; mobScroll.BorderSizePixel=0; mobScroll.ScrollBarThickness=2; mobScroll.ScrollBarImageColor3=C.RED
	mobScroll.CanvasSize=UDim2.new(0,0,0,0); mobScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; mobScroll.ElasticBehavior=Enum.ElasticBehavior.Never
	local mLL=Instance.new("UIListLayout",mobScroll); mLL.Padding=UDim.new(0,3); mLL.SortOrder=Enum.SortOrder.LayoutOrder
	local mPad=Instance.new("UIPadding",mobScroll); mPad.PaddingLeft=UDim.new(0,4); mPad.PaddingRight=UDim.new(0,6); mPad.PaddingTop=UDim.new(0,4); mPad.PaddingBottom=UDim.new(0,4)
	local function makeFloatingBtn(id,txt,onClickFn,activeGetFn)
		if detachedBtns[id] and detachedBtns[id].frame and detachedBtns[id].frame.Parent then
			detachedBtns[id].frame:Destroy()
			if detachedBtns[id].shadow and detachedBtns[id].shadow.Parent then detachedBtns[id].shadow:Destroy() end
		end
		local saved=savedDetached[id]; local px=saved and saved.x or 120; local py=saved and saved.y or 300
		local shadow=Instance.new("Frame",gui); shadow.Size=UDim2.new(0,132,0,44); shadow.Position=UDim2.new(0,px+2,0,py+2)
		shadow.BackgroundColor3=Color3.fromRGB(0,0,0); shadow.BackgroundTransparency=0.65; shadow.BorderSizePixel=0; shadow.ZIndex=1; addCorner(shadow,7)
		local frame=Instance.new("Frame",gui); frame.Size=UDim2.new(0,130,0,42); frame.Position=UDim2.new(0,px,0,py)
		frame.BackgroundColor3=Color3.fromRGB(18,18,22); frame.BorderSizePixel=0; frame.Active=true; frame.ZIndex=2
		addCorner(frame,7); addStroke(frame,Color3.fromRGB(160,160,170),1,0.15)
		local locked=false
		local dragBar=Instance.new("TextButton",frame); dragBar.Size=UDim2.new(1,-18,0,13); dragBar.Position=UDim2.new(0,0,0,0)
		dragBar.BackgroundColor3=Color3.fromRGB(28,28,34); dragBar.BorderSizePixel=0; dragBar.ZIndex=5
		dragBar.Text="⠿ drag"; dragBar.TextColor3=Color3.fromRGB(90,90,100); dragBar.Font=Enum.Font.Gotham; dragBar.TextSize=8; dragBar.AutoButtonColor=false; addCorner(dragBar,7)
		local function setLocked(v)
			locked=v
			if locked then dragBar.Text="⠿ locked"; dragBar.TextColor3=Color3.fromRGB(80,200,80); dragBar.BackgroundColor3=Color3.fromRGB(8,30,10); addStroke(dragBar,Color3.fromRGB(40,180,40),1,0.4)
			else dragBar.Text="⠿ drag"; dragBar.TextColor3=Color3.fromRGB(90,90,100); dragBar.BackgroundColor3=Color3.fromRGB(28,28,34); addStroke(dragBar,Color3.fromRGB(0,0,0),0,1) end
		end
		local xBtn=Instance.new("TextButton",frame); xBtn.Size=UDim2.new(0,17,0,13); xBtn.Position=UDim2.new(1,-17,0,0)
		xBtn.BackgroundColor3=Color3.fromRGB(50,50,60); xBtn.BorderSizePixel=0; xBtn.ZIndex=6; xBtn.Text="X"; xBtn.TextColor3=Color3.fromRGB(255,255,255); xBtn.Font=Enum.Font.GothamBold; xBtn.TextSize=8; addCorner(xBtn,7)
		xBtn.MouseButton1Click:Connect(function() shadow:Destroy(); frame:Destroy(); detachedBtns[id]=nil; savedDetached[id]=nil; saveDetached(); rebuildMobPanel() end)
		local isActive=activeGetFn and activeGetFn() or false
		local btn=Instance.new("TextButton",frame); btn.Size=UDim2.new(1,-6,1,-16); btn.Position=UDim2.new(0,3,0,14)
		btn.BackgroundColor3=isActive and Color3.fromRGB(50,50,58) or Color3.fromRGB(26,26,32); btn.BorderSizePixel=0; btn.Text=txt; btn.ZIndex=4
		btn.TextColor3=isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(210,210,210); btn.Font=Enum.Font.GothamBold; btn.TextSize=10; btn.TextTruncate=Enum.TextTruncate.AtEnd
		addCorner(btn,5); addStroke(btn,Color3.fromRGB(130,130,140),1,isActive and 0.1 or 0.5)
		local function refreshActive()
			local on=activeGetFn and activeGetFn() or false
			btn.BackgroundColor3=on and Color3.fromRGB(50,50,58) or Color3.fromRGB(26,26,32)
			btn.TextColor3=on and Color3.fromRGB(255,255,255) or Color3.fromRGB(210,210,210)
		end
		btn.MouseButton1Click:Connect(function() if onClickFn then onClickFn() end; refreshActive() end)
		local dragging=false; local offX,offY=0,0
		dragBar.MouseButton1Click:Connect(function() setLocked(not locked) end)
		local moveCon=UIS.InputChanged:Connect(function(inp)
			if not locked then return end
			if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement then
				if not dragging then return end
				local nx=math.max(0,inp.Position.X-offX); local ny=math.max(0,inp.Position.Y-offY)
				frame.Position=UDim2.new(0,nx,0,ny); shadow.Position=UDim2.new(0,nx+2,0,ny+2)
				if detachedBtns[id] then detachedBtns[id].x=nx; detachedBtns[id].y=ny end
			end
		end)
		dragBar.InputBegan:Connect(function(inp)
			if not locked then return end
			if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
				dragging=true; offX=inp.Position.X-frame.AbsolutePosition.X; offY=inp.Position.Y-frame.AbsolutePosition.Y
			end
		end)
		local endCon=UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
				if dragging then dragging=false; saveDetached() end
			end
		end)
		frame.AncestryChanged:Connect(function() if not frame.Parent then pcall(function() moveCon:Disconnect(); endCon:Disconnect() end) end end)
		frame.BackgroundTransparency=1; shadow.BackgroundTransparency=1
		TS:Create(frame,TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
		TS:Create(shadow,TweenInfo.new(0.15),{BackgroundTransparency=0.65}):Play()
		detachedBtns[id]={frame=frame,shadow=shadow,x=px,y=py}; saveDetached()
		return btn
	end
	local function mkMobBtn(txt)
		local row=Instance.new("Frame",mobScroll); row.Size=UDim2.new(1,0,0,20); row.BackgroundTransparency=1
		local plusBtn=Instance.new("TextButton",row); plusBtn.Size=UDim2.new(0,18,1,0); plusBtn.Position=UDim2.new(0,0,0,0)
		plusBtn.BackgroundColor3=Color3.fromRGB(8,38,10); plusBtn.BorderSizePixel=0; plusBtn.Text="+"; plusBtn.TextColor3=Color3.fromRGB(80,220,80)
		plusBtn.Font=Enum.Font.GothamBold; plusBtn.TextSize=11; addCorner(plusBtn,4); addStroke(plusBtn,Color3.fromRGB(30,160,40),1,0.4)
		local b=Instance.new("TextButton",row); b.Size=UDim2.new(1,-21,1,0); b.Position=UDim2.new(0,21,0,0)
		b.BackgroundColor3=C.CARD2; b.BorderSizePixel=0; b.Text=txt; b.TextColor3=C.WHITE; b.Font=Enum.Font.GothamBold; b.TextSize=9; addCorner(b,4); addStroke(b,C.RED,1,0.5)
		return b,plusBtn
	end
	local function mkSubRow() local f=Instance.new("Frame",mobScroll); f.Size=UDim2.new(1,0,0,24); f.BackgroundTransparency=1; return f end
	local function buildFltRow()
		local row=mkSubRow()
		local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0,30,1,0); lbl.BackgroundTransparency=1; lbl.Text="Ht"; lbl.TextColor3=C.DIM; lbl.Font=Enum.Font.Gotham; lbl.TextSize=10
		local bD=Instance.new("TextButton",row); bD.Size=UDim2.new(0,30,1,0); bD.Position=UDim2.new(0,32,0,0); bD.BackgroundColor3=Color3.fromRGB(20,20,50); bD.BorderSizePixel=0; bD.Text="Dn"; bD.TextColor3=C.WHITE; bD.Font=Enum.Font.GothamBold; bD.TextSize=10; addCorner(bD,4); addStroke(bD,C.RED,1,0.5)
		local bU=Instance.new("TextButton",row); bU.Size=UDim2.new(0,30,1,0); bU.Position=UDim2.new(0,66,0,0); bU.BackgroundColor3=Color3.fromRGB(20,30,60); bU.BorderSizePixel=0; bU.Text="Up"; bU.TextColor3=C.WHITE; bU.Font=Enum.Font.GothamBold; bU.TextSize=10; addCorner(bU,4); addStroke(bU,C.RED,1,0.5)
		local hU,hD=false,false
		bU.MouseButton1Down:Connect(function() hU=true end); bU.MouseButton1Up:Connect(function() hU=false end)
		bD.MouseButton1Down:Connect(function() hD=true end); bD.MouseButton1Up:Connect(function() hD=false end)
		RunService.Heartbeat:Connect(function() if hU then floatAdjustY(0.12) end; if hD then floatAdjustY(-0.12) end end)
	end
	local function linkPlus(plusBtn,id,txt,onClickFn,activeGetFn)
		local function setMinus() plusBtn.Text="-"; plusBtn.TextColor3=Color3.fromRGB(200,200,210); plusBtn.BackgroundColor3=Color3.fromRGB(35,35,42); addStroke(plusBtn,Color3.fromRGB(130,130,140),1,0.4) end
		local function setPlus() plusBtn.Text="+"; plusBtn.TextColor3=Color3.fromRGB(80,220,80); plusBtn.BackgroundColor3=Color3.fromRGB(8,38,10); addStroke(plusBtn,Color3.fromRGB(30,160,40),1,0.4) end
		if savedDetached[id] then setMinus() end
		plusBtn.MouseButton1Click:Connect(function()
			if savedDetached[id] then
				if detachedBtns[id] and detachedBtns[id].frame and detachedBtns[id].frame.Parent then
					detachedBtns[id].frame:Destroy()
					if detachedBtns[id].shadow and detachedBtns[id].shadow.Parent then detachedBtns[id].shadow:Destroy() end
				end
				detachedBtns[id]=nil; savedDetached[id]=nil; saveDetached(); setPlus()
			else
				local px,py=120,200; local FW,FH=130,58
				local function overlaps(x,y)
					for oid,od in pairs(detachedBtns) do
						if oid~=id and od.frame and od.frame.Parent then
							local ox,oy=od.x,od.y
							if math.abs(x-ox)<FW and math.abs(y-oy)<FH then return true end
						end
					end
					return false
				end
				local found=false
				for row=0,8 do
					for col=0,3 do
						local tx=40+col*(FW+10); local ty=160+row*(FH+10)
						if not overlaps(tx,ty) then px=tx; py=ty; found=true; break end
					end
					if found then break end
				end
				savedDetached[id]={x=px,y=py}; saveDetached(); makeFloatingBtn(id,txt,onClickFn,activeGetFn); setMinus()
			end
		end)
	end
	local BTN_DEFS={
		{id="Speed",build=function()
			if savedDetached["Speed"] then makeFloatingBtn("Speed","Speed",function() G.speedMode=not G.speedMode; if G.speedBtn then G.speedBtn(G.speedMode) end end,function() return G.speedMode end); return end
			local b,plus=mkMobBtn("Speed"); b.BackgroundColor3=G.speedMode and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.speedMode=not G.speedMode; if G.speedBtn then G.speedBtn(G.speedMode) end; b.BackgroundColor3=G.speedMode and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"Speed","Speed",function() G.speedMode=not G.speedMode; if G.speedBtn then G.speedBtn(G.speedMode) end end,function() return G.speedMode end)
		end},{id="Float",build=function()
			if savedDetached["Float"] then makeFloatingBtn("Float","Float",function() G.floatEnabled=not G.floatEnabled; if G.floatEnabled then startFloat() else stopFloat() end; if G.floatSetVisual then G.floatSetVisual(G.floatEnabled) end end,function() return G.floatEnabled end); return end
			local b,plus=mkMobBtn("Float"); b.BackgroundColor3=G.floatEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.floatEnabled=not G.floatEnabled; if G.floatEnabled then startFloat() else stopFloat() end; b.BackgroundColor3=G.floatEnabled and C.MOB_ON or C.CARD2; if G.floatSetVisual then G.floatSetVisual(G.floatEnabled) end end)
			linkPlus(plus,"Float","Float",function() G.floatEnabled=not G.floatEnabled; if G.floatEnabled then startFloat() else stopFloat() end; if G.floatSetVisual then G.floatSetVisual(G.floatEnabled) end end,function() return G.floatEnabled end)
			buildFltRow()
		end},{id="Auto Steal",build=function()
			if savedDetached["Auto Steal"] then makeFloatingBtn("Auto Steal","Auto Steal",function() G.autoGrabEnabled=not G.autoGrabEnabled; StealBar.Visible=G.autoGrabEnabled; if G.autoGrabEnabled then startAutoSteal() else stopAutoSteal() end; if G.autoStealSetVisual then G.autoStealSetVisual(G.autoGrabEnabled) end end,function() return G.autoGrabEnabled end); return end
			local b,plus=mkMobBtn("Auto Steal"); b.BackgroundColor3=G.autoGrabEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.autoGrabEnabled=not G.autoGrabEnabled; StealBar.Visible=G.autoGrabEnabled; if G.autoGrabEnabled then startAutoSteal() else stopAutoSteal() end; b.BackgroundColor3=G.autoGrabEnabled and C.MOB_ON or C.CARD2; if G.autoStealSetVisual then G.autoStealSetVisual(G.autoGrabEnabled) end end)
			linkPlus(plus,"Auto Steal","Auto Steal",function() G.autoGrabEnabled=not G.autoGrabEnabled; StealBar.Visible=G.autoGrabEnabled; if G.autoGrabEnabled then startAutoSteal() else stopAutoSteal() end; if G.autoStealSetVisual then G.autoStealSetVisual(G.autoGrabEnabled) end end,function() return G.autoGrabEnabled end)
		end},{id="Drop Brainrot",build=function()
			if savedDetached["Drop Brainrot"] then makeFloatingBtn("Drop Brainrot","Drop Brainrot",function() runDrop() end,nil); return end
			local b,plus=mkMobBtn("Drop Brainrot"); b.MouseButton1Click:Connect(function() runDrop() end)
			linkPlus(plus,"Drop Brainrot","Drop Brainrot",function() runDrop() end,nil)
		end},{id="Auto Left",build=function()
			if savedDetached["Auto Left"] then makeFloatingBtn("Auto Left","Auto Left",function() G.autoLeftEnabled=not G.autoLeftEnabled; if G.autoLeftSetVisual then G.autoLeftSetVisual(G.autoLeftEnabled) end; if G.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end end,function() return G.autoLeftEnabled end); return end
			local b,plus=mkMobBtn("Auto Left"); b.BackgroundColor3=G.autoLeftEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.autoLeftEnabled=not G.autoLeftEnabled; if G.autoLeftSetVisual then G.autoLeftSetVisual(G.autoLeftEnabled) end; if G.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end; b.BackgroundColor3=G.autoLeftEnabled and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"Auto Left","Auto Left",function() G.autoLeftEnabled=not G.autoLeftEnabled; if G.autoLeftSetVisual then G.autoLeftSetVisual(G.autoLeftEnabled) end; if G.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end end,function() return G.autoLeftEnabled end)
		end},{id="Auto Right",build=function()
			if savedDetached["Auto Right"] then makeFloatingBtn("Auto Right","Auto Right",function() G.autoRightEnabled=not G.autoRightEnabled; if G.autoRightSetVisual then G.autoRightSetVisual(G.autoRightEnabled) end; if G.autoRightEnabled then startAutoRight() else stopAutoRight() end end,function() return G.autoRightEnabled end); return end
			local b,plus=mkMobBtn("Auto Right"); b.BackgroundColor3=G.autoRightEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.autoRightEnabled=not G.autoRightEnabled; if G.autoRightSetVisual then G.autoRightSetVisual(G.autoRightEnabled) end; if G.autoRightEnabled then startAutoRight() else stopAutoRight() end; b.BackgroundColor3=G.autoRightEnabled and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"Auto Right","Auto Right",function() G.autoRightEnabled=not G.autoRightEnabled; if G.autoRightSetVisual then G.autoRightSetVisual(G.autoRightEnabled) end; if G.autoRightEnabled then startAutoRight() else stopAutoRight() end end,function() return G.autoRightEnabled end)
		end},{id="Auto Play Left",build=function()
			local function doClick()
				G.autoPlayLeftEnabled=not G.autoPlayLeftEnabled
				if G.autoPlayLeftEnabled then
					if G.autoBatEnabled then disableAutoBat() end
					if G.autoPlayRightEnabled then stopAutoPlayRight(); G.autoPlayRightEnabled=false; if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(false) end end
					startAutoPlayLeft()
				else stopAutoPlayLeft() end
				if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(G.autoPlayLeftEnabled) end
			end
			if savedDetached["Auto Play Left"] then makeFloatingBtn("Auto Play Left","Auto Play L",doClick,function() return G.autoPlayLeftEnabled end); return end
			local b,plus=mkMobBtn("Auto Play L"); b.BackgroundColor3=G.autoPlayLeftEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() doClick(); b.BackgroundColor3=G.autoPlayLeftEnabled and C.MOB_ON or C.CARD2 end)
			local gb=Instance.new("TextButton",b); gb.Size=UDim2.new(0,22,0,22); gb.Position=UDim2.new(1,-26,0.5,-11)
			gb.BackgroundColor3=Color3.fromRGB(20,20,28); gb.BorderSizePixel=0; gb.Text="⚙"; gb.TextColor3=Color3.fromRGB(80,180,255); gb.Font=Enum.Font.Gotham; gb.TextSize=13; gb.ZIndex=5; addCorner(gb,4)
			gb.MouseButton1Click:Connect(function() buildWPOffsetPanel("left") end)
			linkPlus(plus,"Auto Play Left","Auto Play L",doClick,function() return G.autoPlayLeftEnabled end)
		end},{id="Auto Play Right",build=function()
			local function doClick()
				G.autoPlayRightEnabled=not G.autoPlayRightEnabled
				if G.autoPlayRightEnabled then
					if G.autoBatEnabled then disableAutoBat() end
					if G.autoPlayLeftEnabled then stopAutoPlayLeft(); G.autoPlayLeftEnabled=false; if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(false) end end
					startAutoPlayRight()
				else stopAutoPlayRight() end
				if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(G.autoPlayRightEnabled) end
			end
			if savedDetached["Auto Play Right"] then makeFloatingBtn("Auto Play Right","Auto Play R",doClick,function() return G.autoPlayRightEnabled end); return end
			local b,plus=mkMobBtn("Auto Play R"); b.BackgroundColor3=G.autoPlayRightEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() doClick(); b.BackgroundColor3=G.autoPlayRightEnabled and C.MOB_ON or C.CARD2 end)
			local gb=Instance.new("TextButton",b); gb.Size=UDim2.new(0,22,0,22); gb.Position=UDim2.new(1,-26,0.5,-11)
			gb.BackgroundColor3=Color3.fromRGB(20,20,28); gb.BorderSizePixel=0; gb.Text="⚙"; gb.TextColor3=Color3.fromRGB(255,100,80); gb.Font=Enum.Font.Gotham; gb.TextSize=13; gb.ZIndex=5; addCorner(gb,4)
			gb.MouseButton1Click:Connect(function() buildWPOffsetPanel("right") end)
			linkPlus(plus,"Auto Play Right","Auto Play R",doClick,function() return G.autoPlayRightEnabled end)
		end},{id="Bat Aimbot",build=function()
			local function doClick()
				G.autoBatEnabled=not G.autoBatEnabled
				if G.autoBatEnabled then if G.autoPlayLeftEnabled or G.autoPlayRightEnabled then disableAllAutoPlay() end end
				if G.autoBatSetVisual then G.autoBatSetVisual(G.autoBatEnabled) end
			end
			if savedDetached["Bat Aimbot"] then makeFloatingBtn("Bat Aimbot","Bat Aimbot",doClick,function() return G.autoBatEnabled end); return end
			local b,plus=mkMobBtn("Bat Aimbot"); b.BackgroundColor3=G.autoBatEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() doClick(); b.BackgroundColor3=G.autoBatEnabled and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"Bat Aimbot","Bat Aimbot",doClick,function() return G.autoBatEnabled end)
		end},{id="Auto Swing",build=function()
			if savedDetached["Auto Swing"] then makeFloatingBtn("Auto Swing","Auto Swing",function() G.autoSwingEnabled=not G.autoSwingEnabled; if G.autoSwingSetVisual then G.autoSwingSetVisual(G.autoSwingEnabled) end end,function() return G.autoSwingEnabled end); return end
			local b,plus=mkMobBtn("Auto Swing"); b.BackgroundColor3=G.autoSwingEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.autoSwingEnabled=not G.autoSwingEnabled; if G.autoSwingSetVisual then G.autoSwingSetVisual(G.autoSwingEnabled) end; b.BackgroundColor3=G.autoSwingEnabled and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"Auto Swing","Auto Swing",function() G.autoSwingEnabled=not G.autoSwingEnabled; if G.autoSwingSetVisual then G.autoSwingSetVisual(G.autoSwingEnabled) end end,function() return G.autoSwingEnabled end)
		end},{id="Infinite Jump",build=function()
			if savedDetached["Infinite Jump"] then makeFloatingBtn("Infinite Jump","Inf Jump",function() G.infJumpEnabled=not G.infJumpEnabled; if G.infJumpEnabled then startInfiniteJump() else stopInfiniteJump() end; if G.infJumpSetVisual then G.infJumpSetVisual(G.infJumpEnabled) end end,function() return G.infJumpEnabled end); return end
			local b,plus=mkMobBtn("Inf Jump"); b.BackgroundColor3=G.infJumpEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.infJumpEnabled=not G.infJumpEnabled; if G.infJumpEnabled then startInfiniteJump() else stopInfiniteJump() end; if G.infJumpSetVisual then G.infJumpSetVisual(G.infJumpEnabled) end; b.BackgroundColor3=G.infJumpEnabled and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"Infinite Jump","Inf Jump",function() G.infJumpEnabled=not G.infJumpEnabled; if G.infJumpEnabled then startInfiniteJump() else stopInfiniteJump() end; if G.infJumpSetVisual then G.infJumpSetVisual(G.infJumpEnabled) end end,function() return G.infJumpEnabled end)
		end},{id="TP Down",build=function()
			if savedDetached["TP Down"] then makeFloatingBtn("TP Down","TP Down",function() runTPDown() end,nil); return end
			local b,plus=mkMobBtn("TP Down"); b.MouseButton1Click:Connect(function() runTPDown() end)
			linkPlus(plus,"TP Down","TP Down",function() runTPDown() end,nil)
		end},{id="No Cam Collision",build=function()
			if savedDetached["No Cam Collision"] then makeFloatingBtn("No Cam Collision","No Cam Collision",function() G.noCamCollisionEnabled=not G.noCamCollisionEnabled; if G.noCamCollisionEnabled then enableNoCameraCollision() else disableNoCameraCollision() end end,function() return G.noCamCollisionEnabled end); return end
			local b,plus=mkMobBtn("No Cam Collision"); b.BackgroundColor3=G.noCamCollisionEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() G.noCamCollisionEnabled=not G.noCamCollisionEnabled; if G.noCamCollisionEnabled then enableNoCameraCollision() else disableNoCameraCollision() end; b.BackgroundColor3=G.noCamCollisionEnabled and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"No Cam Collision","No Cam Collision",function() G.noCamCollisionEnabled=not G.noCamCollisionEnabled; if G.noCamCollisionEnabled then enableNoCameraCollision() else disableNoCameraCollision() end end,function() return G.noCamCollisionEnabled end)
		end},{id="Auto TP",build=function()
			local function doClick() G_tpAutoEnabled=not G_tpAutoEnabled; if G_tpAutoEnabled and not G_myPlotSide then task.spawn(function() refreshMyPlotSide() end) end end
			if savedDetached["Auto TP"] then
				local fb=makeFloatingBtn("Auto TP","TP (?)",doClick,function() return G_tpAutoEnabled end)
				local prevU=G_updateTPBtn; G_updateTPBtn=function() if prevU then prevU() end; if fb and fb.Parent then local s=G_myPlotSide; fb.Text=s=="left" and "TP LEFT" or s=="right" and "TP RIGHT" or "TP (?)"; fb.BackgroundColor3=G_tpAutoEnabled and C.MOB_ON or C.CARD2 end end
				return
			end
			local b,plus=mkMobBtn("TP (?)"); b.BackgroundColor3=G_tpAutoEnabled and C.MOB_ON or C.CARD2
			local function refreshLabel() local s=G_myPlotSide; b.Text=s=="left" and "TP LEFT" or s=="right" and "TP RIGHT" or "TP (?)"; b.BackgroundColor3=G_tpAutoEnabled and C.MOB_ON or C.CARD2 end
			refreshLabel()
			local prevU=G_updateTPBtn; G_updateTPBtn=function() if prevU then prevU() end; if b and b.Parent then refreshLabel() end end
			b.MouseButton1Click:Connect(function() doClick(); refreshLabel() end)
			linkPlus(plus,"Auto TP","TP (?)",doClick,function() return G_tpAutoEnabled end)
		end},
		{id="Medusa Mode",build=function()
			local function doClick()
				G.medusaModeEnabled=not G.medusaModeEnabled
				if G.medusaModeSetVisual then G.medusaModeSetVisual(G.medusaModeEnabled) end
			end
			if savedDetached["Medusa Mode"] then makeFloatingBtn("Medusa Mode","Medusa Mode",doClick,function() return G.medusaModeEnabled end); return end
			local b,plus=mkMobBtn("Medusa Mode"); b.BackgroundColor3=G.medusaModeEnabled and C.MOB_ON or C.CARD2
			b.MouseButton1Click:Connect(function() doClick(); b.BackgroundColor3=G.medusaModeEnabled and C.MOB_ON or C.CARD2 end)
			linkPlus(plus,"Medusa Mode","Medusa Mode",doClick,function() return G.medusaModeEnabled end)
		end},
	}
	rebuildMobPanel=function()
		for _,ch in ipairs(mobScroll:GetChildren()) do if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end end
		for _,def in ipairs(BTN_DEFS) do
			if mobBtnEnabled[def.id] then
				if savedDetached[def.id] and detachedBtns[def.id] and detachedBtns[def.id].frame and detachedBtns[def.id].frame.Parent then
				else def.build() end
			end
		end
	end
	rebuildMobPanel()
	local cfgPopup=Instance.new("Frame",gui); cfgPopup.Name="K7BtnCfg"; cfgPopup.Size=UDim2.new(0,168,0,0); cfgPopup.AutomaticSize=Enum.AutomaticSize.Y
	cfgPopup.Position=UDim2.new(0.5,-84,0.5,-130); cfgPopup.BackgroundColor3=Color3.fromRGB(12,12,15); cfgPopup.BorderSizePixel=0; cfgPopup.Visible=false; cfgPopup.ZIndex=200
	addCorner(cfgPopup,10); addStroke(cfgPopup,C.RED,1.5,0.15); makeDraggable(cfgPopup)
	do
		local hdr=Instance.new("Frame",cfgPopup); hdr.Size=UDim2.new(1,0,0,28); hdr.BackgroundColor3=Color3.fromRGB(18,18,22); hdr.BorderSizePixel=0; addCorner(hdr,10)
		local ttl=Instance.new("TextLabel",hdr); ttl.Size=UDim2.new(1,-30,1,0); ttl.Position=UDim2.new(0,10,0,0); ttl.BackgroundTransparency=1; ttl.Text="MOBILE BUTTONS"; ttl.TextColor3=C.RED2; ttl.Font=Enum.Font.GothamBlack; ttl.TextSize=10; ttl.TextXAlignment=Enum.TextXAlignment.Left
		local cx=Instance.new("TextButton",hdr); cx.Size=UDim2.new(0,20,0,20); cx.Position=UDim2.new(1,-24,0.5,-10); cx.BackgroundColor3=C.RED; cx.BorderSizePixel=0; cx.Text="X"; cx.TextColor3=C.WHITE; cx.Font=Enum.Font.GothamBold; cx.TextSize=10; addCorner(cx,4)
		cx.MouseButton1Click:Connect(function() cfgPopup.Visible=false end)
	end
	local cfgList=Instance.new("Frame",cfgPopup); cfgList.Size=UDim2.new(1,0,0,0); cfgList.AutomaticSize=Enum.AutomaticSize.Y; cfgList.Position=UDim2.new(0,0,0,30); cfgList.BackgroundTransparency=1
	local cfgLayout=Instance.new("UIListLayout",cfgList); cfgLayout.Padding=UDim.new(0,2); cfgLayout.SortOrder=Enum.SortOrder.LayoutOrder
	local cfgPad=Instance.new("UIPadding",cfgList); cfgPad.PaddingLeft=UDim.new(0,8); cfgPad.PaddingRight=UDim.new(0,8); cfgPad.PaddingTop=UDim.new(0,4); cfgPad.PaddingBottom=UDim.new(0,4)
	cfgToggleBtns={}
	for _,def in ipairs(BTN_DEFS) do
		local row=Instance.new("Frame",cfgList); row.Size=UDim2.new(1,0,0,26); row.BackgroundTransparency=1
		local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-40,1,0); lbl.BackgroundTransparency=1; lbl.Text=def.id; lbl.TextColor3=C.WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
		local tog=Instance.new("TextButton",row); tog.Size=UDim2.new(0,32,0,20); tog.Position=UDim2.new(1,-34,0.5,-10); tog.BorderSizePixel=0; tog.Font=Enum.Font.GothamBold; tog.TextSize=9; tog.TextColor3=C.WHITE; addCorner(tog,4)
		local function refreshTog() local on=mobBtnEnabled[def.id]; tog.BackgroundColor3=on and C.ON_BG or C.CARD2; tog.Text=on and "ON" or "OFF"; tog.TextColor3=on and C.RED2 or C.DIM end
		refreshTog()
		tog.MouseButton1Click:Connect(function() mobBtnEnabled[def.id]=not mobBtnEnabled[def.id]; refreshTog(); rebuildMobPanel() end)
		cfgToggleBtns[def.id]=refreshTog
	end
	do
		local footer=Instance.new("Frame",cfgPopup); footer.Size=UDim2.new(1,0,0,34); footer.BackgroundTransparency=1
		local fpad=Instance.new("UIPadding",footer); fpad.PaddingLeft=UDim.new(0,8); fpad.PaddingRight=UDim.new(0,8); fpad.PaddingTop=UDim.new(0,5)
		local resetBtn=Instance.new("TextButton",footer); resetBtn.Size=UDim2.new(0.5,-4,0,24); resetBtn.BackgroundColor3=C.ON_BG; resetBtn.BorderSizePixel=0; resetBtn.Text="Reset All"; resetBtn.TextColor3=C.RED2; resetBtn.Font=Enum.Font.GothamBold; resetBtn.TextSize=10; addCorner(resetBtn,5); addStroke(resetBtn,C.RED,1,0.4)
		resetBtn.MouseButton1Click:Connect(function() for _,id in ipairs(DEFAULT_MOB_BTNS) do mobBtnEnabled[id]=true end; for _,fn in pairs(cfgToggleBtns) do fn() end; rebuildMobPanel() end)
		local doneBtn=Instance.new("TextButton",footer); doneBtn.Size=UDim2.new(0.5,-4,0,24); doneBtn.Position=UDim2.new(0.5,4,0,0); doneBtn.BackgroundColor3=C.CARD2; doneBtn.BorderSizePixel=0; doneBtn.Text="Done"; doneBtn.TextColor3=C.WHITE; doneBtn.Font=Enum.Font.GothamBold; doneBtn.TextSize=10; addCorner(doneBtn,5); addStroke(doneBtn,C.RED,1,0.6)
		doneBtn.MouseButton1Click:Connect(function() cfgPopup.Visible=false end)
	end
	setMobileMode=function(on)
		G.mobileMode=on; _mobPanel.Visible=on
		if mobToggleBtn then mobToggleBtn.BackgroundColor3=on and C.ON_BG or C.CARD2; mobToggleBtn.TextColor3=on and C.RED2 or C.DIM end
		TS:Create(main,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{Size=on and UDim2.new(0,180,0,G.isMobile and 360 or 400) or UDim2.new(0,MAIN_W,0,MAIN_H)}):Play()
	end
	if mobToggleBtn then
		mobToggleBtn.MouseButton1Click:Connect(function() setMobileMode(not G.mobileMode) end)
		mobToggleBtn.MouseButton2Click:Connect(function() cfgPopup.Visible=not cfgPopup.Visible end)
	end
	local pill=Instance.new("TextButton",gui); pill.Size=UDim2.new(0,48,0,20); pill.Position=UDim2.new(1,-54,1,-200)
	pill.BackgroundColor3=C.RED; pill.BackgroundTransparency=0.1; pill.BorderSizePixel=0; pill.Text="K7 ^"; pill.TextColor3=C.WHITE; pill.Font=Enum.Font.GothamBlack; pill.TextSize=10; addCorner(pill,10)
	pill.Visible=not G.isMobile
	pill.MouseButton1Click:Connect(function() _mobPanel.Visible=not _mobPanel.Visible; pill.Text=_mobPanel.Visible and "K7 v" or "K7 ^" end)
	pill.MouseButton2Click:Connect(function() cfgPopup.Visible=not cfgPopup.Visible end)
end
if G.isMobile then buildMobileGUI() end
task.spawn(function() while task.wait(5) do saveConfig() end end)
local function loadConfig()
	if not(isfile and isfile("K7MiniHubConfig.json")) then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile("K7MiniHubConfig.json")) end)
	if not ok or not cfg then return end
	if cfg.normalSpeed then G.NS=cfg.normalSpeed end
	if cfg.carrySpeed then G.CS=cfg.carrySpeed end
	if cfg.grabRadius then G.grabRadius=cfg.grabRadius end
	if cfg.stealDuration then G.grabDuration=cfg.stealDuration end
	local function applyKey(field,slot) if cfg[field] and Enum.KeyCode[cfg[field]] then KB[slot]=Enum.KeyCode[cfg[field]] end end
	applyKey("speedToggleKey","SpeedToggle"); applyKey("dropBrainrotKey","DropBrainrot"); applyKey("autoLeftKey","AutoLeft"); applyKey("autoRightKey","AutoRight")
	applyKey("autoBatKey","AutoBat"); applyKey("tpLeftKey","TPLeft")
	applyKey("autoPlayLeftKey","AutoPlayLeft"); applyKey("autoPlayRightKey","AutoPlayRight")
	applyKey("tpDownKey","TPDown"); applyKey("floatToggleKey","FloatToggle"); applyKey("autoTPKey","AutoTP")
	if cfg.antiRagdoll~=nil then G.antiRagdollEnabled=cfg.antiRagdoll end
	if cfg.autoStealEnabled~=nil then G.autoGrabEnabled=cfg.autoStealEnabled; if G.autoGrabEnabled then startAutoSteal(); if StealBar then StealBar.Visible=true end end end
	if cfg.infiniteJump~=nil then G.infJumpEnabled=cfg.infiniteJump end
	if cfg.medusaCounter~=nil then G.medusaCounterEnabled=cfg.medusaCounter end
	if cfg.brainrotReturnLeft~=nil then G.brainrotLeftEnabled=cfg.brainrotReturnLeft end
	if cfg.brainrotReturnRight~=nil then G.brainrotRightEnabled=cfg.brainrotReturnRight end
	if cfg.tpAutoEnabled then
		G_tpAutoEnabled = true
		task.spawn(function()
			local plots=workspace:WaitForChild("Plots",30); if not plots then return end
			local myName=LP.DisplayName or LP.Name
			local found,deadline=false,tick()+60
			while not found and tick()<deadline do
				for _,plot in ipairs(plots:GetChildren()) do
					pcall(function()
						local tl=plot:FindFirstChild("PlotSign") and plot.PlotSign:FindFirstChild("SurfaceGui") and
							plot.PlotSign.SurfaceGui:FindFirstChild("Frame") and plot.PlotSign.SurfaceGui.Frame:FindFirstChild("TextLabel")
						if tl and tl.Text:find(myName,1,true) then found=true end
					end)
					if found then break end
				end
				if not found then task.wait(0.3) end
			end
			refreshMyPlotSide()
			if G.refreshWPMarkers then G.refreshWPMarkers() end
		end)
	end
	if cfg.carryMode~=nil then G.speedMode=cfg.carryMode end
	if cfg.autoBat~=nil then G.autoBatEnabled=cfg.autoBat end
	if cfg.autoSwing~=nil then G.autoSwingEnabled=cfg.autoSwing end
	if cfg.autoPlayCountdown~=nil then G.autoPlayCountdownEnabled=cfg.autoPlayCountdown end
	if cfg.unwalk~=nil then G.unwalkEnabled=cfg.unwalk end
	if cfg.ijGravityPercent then G.IJ_GravityPercent=cfg.ijGravityPercent end
	if cfg.ijHopPower then G.IJ_HopPower=cfg.ijHopPower end
	if cfg.shinyGraphics then G.shinyEnabled=false; enableShinyGraphics() end
	if cfg.optimizer then enableOptimizer() end
	if cfg.ultraMode then enableUltraMode() end
	if cfg.floatStuds then G.FLOAT_STUDS=cfg.floatStuds end
	if cfg.floatEnabled then G.floatEnabled=true; startFloat() end
	if cfg.noCamCollision then enableNoCameraCollision() end
	if cfg.removeAccessories~=nil then G.removeAccessoriesEnabled=cfg.removeAccessories end
	if cfg.apOffsets then for i=1,4 do if cfg.apOffsets[i] then AP_Offsets[i]=cfg.apOffsets[i] end end end
	if cfg.aprOffsets then for i=1,4 do if cfg.aprOffsets[i] then APR_Offsets[i]=cfg.aprOffsets[i] end end end
	if cfg.medusaMode~=nil then G.medusaModeEnabled=cfg.medusaMode end
	if cfg.mobBtnEnabled then
		for _,id in ipairs(DEFAULT_MOB_BTNS) do if cfg.mobBtnEnabled[id]~=nil then mobBtnEnabled[id]=cfg.mobBtnEnabled[id] end end
		if rebuildMobPanel then rebuildMobPanel() end
		if cfgToggleBtns then for _,fn in pairs(cfgToggleBtns) do fn() end end
	end
	if cfg.mobileMode and setMobileMode then task.defer(function() setMobileMode(true) end) end
	if G.medusaCounterEnabled then setupMedusa(LP.Character) end
	if G.infJumpEnabled then startInfiniteJump() end
	if G.removeAccessoriesEnabled then enableRemoveAccessories() end
	if G.unwalkEnabled then startUnwalk() end
	task.defer(function()
		if G.radValInBar then G.radValInBar.Text=tostring(G.grabRadius) end
		if G.radMobBtn then G.radMobBtn.Text=tostring(G.grabRadius) end
		for kbName,badge in pairs(G.allBadges) do if KB[kbName] then badge.Text=getKeyName(KB[kbName]) end end
		if G.speedBtn then G.speedBtn(G.speedMode) end
		if G.floatSetVisual then G.floatSetVisual(G.floatEnabled) end
		if G.autoStealSetVisual then G.autoStealSetVisual(G.autoGrabEnabled) end
		if G.autoLeftSetVisual then G.autoLeftSetVisual(G.autoLeftEnabled) end
		if G.autoRightSetVisual then G.autoRightSetVisual(G.autoRightEnabled) end
		if G.autoPlayLeftSetVisual then G.autoPlayLeftSetVisual(G.autoPlayLeftEnabled) end
		if G.autoPlayRightSetVisual then G.autoPlayRightSetVisual(G.autoPlayRightEnabled) end
		if G.autoPlayCountdownSetVisual then G.autoPlayCountdownSetVisual(G.autoPlayCountdownEnabled) end
		if G.autoBatSetVisual then G.autoBatSetVisual(G.autoBatEnabled) end
		if G.autoSwingSetVisual then G.autoSwingSetVisual(G.autoSwingEnabled) end
		if G.tpAutoSetVisual then G.tpAutoSetVisual(G_tpAutoEnabled) end
		if G.brainrotLeftBtn then G.brainrotLeftBtn(G.brainrotLeftEnabled) end
		if G.brainrotRightBtn then G.brainrotRightBtn(G.brainrotRightEnabled) end
		if G.antiRagdollSetVisual then G.antiRagdollSetVisual(G.antiRagdollEnabled) end
		if G.medusaSetVisual then G.medusaSetVisual(G.medusaCounterEnabled) end
		if G.medusaModeSetVisual then G.medusaModeSetVisual(G.medusaModeEnabled) end
		if G.unwalkSetVisual then G.unwalkSetVisual(G.unwalkEnabled) end
		if G.infJumpSetVisual then G.infJumpSetVisual(G.infJumpEnabled) end
		if G.noCamSetVisual then G.noCamSetVisual(G.noCamCollisionEnabled) end
		if G.shinySetVisual then G.shinySetVisual(G.shinyEnabled) end
		if G.optimizerSetVisual then G.optimizerSetVisual(G.optimizerEnabled) end
		if G.ultraModeSetVisual then G.ultraModeSetVisual(G.ultraModeEnabled) end
		if G.removeAccSetVisual then G.removeAccSetVisual(G.removeAccessoriesEnabled) end
	end)
end
loadConfig()
print("LIGHT DUELS")
RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetChildren()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)
