if not LPS_OBFUSCATED then
	LPS_ATTRIBUTES = function(...) end
	VM = function(...) end
	OPAL = nil
	NONE = nil
	PRESET = function(...) end
	SECURE = nil
	FAST = nil
	ENCRYPT = function(...) end
	LPS_ASSUME = function(expr, expected)
		return expr
	end
	LPS_OPAQUE = function(val)
		return val
	end
	TRANSFORM = function(...) end
	CONTROL_FLOW = nil
	REWRITE_NAMECALLS = nil
	EXTRACT = function(...) end
	GLOBALS = nil
	CONSTANTS = nil
	INLINE = function(...) end
	UNROLL = function(...) end
	OPTIMIZE = function(...) end
	ERROR_HANDLING = function(...) end
	LPS_ENCSTR = function(s)
		return s
	end
	LPS_ENCNUM = function(n)
		return n
	end
	LPS_REWRITE = function(e)
		return e
	end
	LPS_STACKALLOC = function(...) end
	LPS_INDEX_TO_NUM = function(t)
		return t
	end
	LPS_LINE = function()
		return 0
	end
	LPS_CRASH = function()
		while true do
		end
	end
end

-- Protected half of Slate v2: the command runtime and the nametag client.
-- Obfuscate THIS file only. slatev2.lua loads it and hands over the shared UI helpers through D.
return function(D)
local ContentProvider, HttpService, LocalPlayer, MarketplaceService, PlayerGui, Players, RunService, SLATE_LOGO_ASSET, SPRING_FAST, SoundService, T, TeleportService, TweenService, UserInputService, body, brand, corner, createGlow, gui, icon, isOwnerUser, isStrictOwnerUser, logo, makeSlider, makeSwitch, new, pad, pages, queueNotification, resolveDecalImage, root, stroke, tabButtons, tween, Slate, SlateUIState, _SlateIsMac, _SE, WIN_H, WIN_W, PILL_H, PILL_W, BG_DECAL_ASSET, SlateSettings, bgImage, executeSlateCommand, handleHeld, handleRest, polishPrimary, resolveIcon, rootStroke, showTooltip, tabRow, tabsHolder, tooltip, topBar, topRight =
	D.ContentProvider, D.HttpService, D.LocalPlayer, D.MarketplaceService, D.PlayerGui, D.Players, D.RunService, D.SLATE_LOGO_ASSET, D.SPRING_FAST, D.SoundService, D.T, D.TeleportService, D.TweenService, D.UserInputService, D.body, D.brand, D.corner, D.createGlow, D.gui, D.icon, D.isOwnerUser, D.isStrictOwnerUser, D.logo, D.makeSlider, D.makeSwitch, D.new, D.pad, D.pages, D.queueNotification, D.resolveDecalImage, D.root, D.stroke, D.tabButtons, D.tween, D.Slate, D.SlateUIState, D._SlateIsMac, D._SE, D.WIN_H, D.WIN_W, D.PILL_H, D.PILL_W, D.BG_DECAL_ASSET, D.SlateSettings, D.bgImage, D.executeSlateCommand, D.handleHeld, D.handleRest, D.polishPrimary, D.resolveIcon, D.rootStroke, D.showTooltip, D.tabRow, D.tabsHolder, D.tooltip, D.topBar, D.topRight

local commandsModule = function(...)
	LPS_ATTRIBUTES(VM(NONE))
	local _slateEnv = (getfenv and getfenv()) or (getgenv and getgenv()) or _G
	local _cmdLoadStart = os.clock()
local function setupFacebang()
    _G._OnyxFaceBangSpeed = _G._OnyxFaceBangSpeed or 24
    _G._OnyxFaceBangDistance = _G._OnyxFaceBangDistance or 6
    _G._OnyxFaceBangHeight = _G._OnyxFaceBangHeight or 1

    local FB_W, FB_H, FB_HEADER = 264, 226, 46
    local fbWindow = new("CanvasGroup", {
        Name = "FacebangControls",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(FB_W, FB_H),
        BackgroundColor3 = T.bg,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 60,
        Parent = gui,
    }, { corner(18) })
    local fbScale = new("UIScale", { Scale = 0.95, Parent = fbWindow })
    local fbGlow = createGlow(fbWindow, Color3.fromRGB(0, 0, 0), 28, 0.4)

    local fbHeader = new("Frame", {
        Size = UDim2.new(1, 0, 0, FB_HEADER),
        BackgroundTransparency = 1,
        ZIndex = 62,
        Parent = fbWindow,
    }, { pad(0, 12, 0, 16) })
    local fbBrand = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 190, 0, 32), BackgroundTransparency = 1, ZIndex = 63, Parent = fbHeader,
    }, {
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
        }),
    })
    local fbLogo = new("ImageLabel", {
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=" .. SLATE_LOGO_ASSET .. "&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit, ImageColor3 = T.accent, ZIndex = 64, Parent = fbBrand,
    })
    task.spawn(function()
        local r = resolveDecalImage(SLATE_LOGO_ASSET)
        if r and fbLogo.Parent then fbLogo.Image = r end
    end)
    new("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, Text = "Facebang",
        Font = Enum.Font.BuilderSansBold, TextSize = 15, TextColor3 = T.text1,
        ZIndex = 64, Parent = fbBrand,
    })

    local fbDragHandle = new("TextButton", {
        Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 63, Parent = fbHeader,
    })

    local fbControls = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(60, 26), BackgroundTransparency = 1, ZIndex = 65, Parent = fbHeader,
    })
    local function fbTopBtn(text, xOff)
        local b = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
            Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = text,
            Font = Enum.Font.BuilderSansMedium, TextSize = 18, TextColor3 = T.text2,
            AutoButtonColor = false, ZIndex = 66, Parent = fbControls,
        })
        b.MouseEnter:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text1 }) end)
        b.MouseLeave:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text2 }) end)
        return b
    end
    local fbClose = fbTopBtn("×", 0)
    local fbMin = fbTopBtn("–", -26)
    _G.SlateHeaderCtl(fbClose, "x", 11)
    _G.SlateHeaderCtl(fbMin, "minus", 12)

    local fbOpenToken = 0
    local function fbSetOpen(open)
        fbOpenToken = fbOpenToken + 1
        local token = fbOpenToken
        if open then
            fbWindow.Visible = true
            fbScale.Scale = 0.95
            tween(fbWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 0 })
            tween(fbScale, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 })
        else
            tween(fbWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })
            tween(fbScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.96 })
            task.delay(0.21, function()
                if token == fbOpenToken then fbWindow.Visible = false end
            end)
        end
    end
    fbClose.MouseButton1Click:Connect(function() fbSetOpen(false) end)

    do
        local fbDragging = false
        local fbDragStart, fbDragOrigin
        local fbTarget = fbWindow.Position
        fbDragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fbDragging = true
                fbDragStart = input.Position
                fbDragOrigin = fbWindow.Position
                fbTarget = fbWindow.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if fbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - fbDragStart
                fbTarget = _G.SlateClampPos(fbWindow, UDim2.new(
                    fbDragOrigin.X.Scale, fbDragOrigin.X.Offset + delta.X,
                    fbDragOrigin.Y.Scale, fbDragOrigin.Y.Offset + delta.Y
                ))
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fbDragging = false
            end
        end)
        RunService.RenderStepped:Connect(function(dt)
            LPS_ATTRIBUTES(VM(NONE))
            if not fbWindow.Visible then return end
            local dx = fbTarget.X.Offset - fbWindow.Position.X.Offset
            local dy = fbTarget.Y.Offset - fbWindow.Position.Y.Offset
            if math.abs(dx) < 0.3 and math.abs(dy) < 0.3 then return end
            local f = (SlateSettings and SlateSettings.smoothdrag == false) and 1 or math.clamp(dt * 22, 0.05, 0.95)
            fbWindow.Position = UDim2.new(fbTarget.X.Scale,
                fbWindow.Position.X.Offset + dx * f,
                fbTarget.Y.Scale,
                fbWindow.Position.Y.Offset + dy * f)
        end)
    end

    local fbContent = new("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(12, FB_HEADER + 2),
        Size = UDim2.new(1, -24, 1, -(FB_HEADER + 14)),
        BackgroundTransparency = 1,
        ZIndex = 61,
        Parent = fbWindow,
    })
    new("UIListLayout", { Padding = UDim.new(0, 8), Parent = fbContent })

    local fbMinimized = false
    fbMin.MouseButton1Click:Connect(function()
        fbMinimized = not fbMinimized
        if not fbMinimized then fbContent.Visible = true end
        tween(fbWindow, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(FB_W, fbMinimized and FB_HEADER or FB_H),
        })
        task.delay(0.35, function()
            if fbMinimized then fbContent.Visible = false end
        end)
        _G.SlateHeaderCtl(fbMin, fbMinimized and "plus" or "minus", 12)
    end)

    makeSlider(fbContent, {
        title = "Speed", min = 0.1, max = 60, default = _G._OnyxFaceBangSpeed, step = 0.1, suffix = "",
        onChange = function(v) _G._OnyxFaceBangSpeed = v end
    })
    makeSlider(fbContent, {
        title = "Distance", min = 1, max = 20, default = _G._OnyxFaceBangDistance, step = 0.1, suffix = "",
        onChange = function(v) _G._OnyxFaceBangDistance = v end
    })
    _G._OnyxFaceBangHeight = 1

    local fbActive = false
    local fbStartBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "START (Z)",
        Font = Enum.Font.BuilderSansBold, TextSize = 11,
        TextColor3 = Color3.fromRGB(15, 15, 20),
        ZIndex = 61,
        Parent = fbContent,
    }, { corner(8) })
    polishPrimary(fbStartBtn)

    local fbConn = nil
    local fbWeld = nil
    local fbLastWorld = nil
    local stopFacebang
    local function getNearestPlayer()
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (r.Position - myRoot.Position).Magnitude
                    if d < bestDist then best = p; bestDist = d end
                end
            end
        end
        return best
    end

    local _fbOscTime = 0
    local function startFacebang(target)
        if fbActive then return end
        if not target or not target.Character then return end
        fbActive = true
        fbStartBtn.Text = "STOP FACEBANG"
        fbStartBtn.BackgroundColor3 = T.danger
        local myChar = LocalPlayer.Character
        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then fbActive = false return end
        hum.PlatformStand = true
        hum.AutoRotate = false
        _fbOscTime = 0

        local function getFBCFrame()
            local tChar = target.Character
            if not tChar then return nil, nil end
            local tHead = tChar:FindFirstChild("Head")
            local tHrp = tChar:FindFirstChild("HumanoidRootPart")
            if not tHead or not tHrp then return nil, nil end

            local dist = _G._OnyxFaceBangDistance or 6
            local height = _G._OnyxFaceBangHeight or 1
            local t = (math.sin(_fbOscTime) + 1) / 2
            local headPos = tHead.Position
            local finalPos = headPos + Vector3.new(0, height, 0) + tHead.CFrame.LookVector * (0.5 + t * dist)
            local flatTarget = Vector3.new(headPos.X, finalPos.Y, headPos.Z)
            if (flatTarget - finalPos).Magnitude < 0.05 then
                flatTarget = finalPos + tHead.CFrame.LookVector * -1
            end
            local worldCF = CFrame.lookAt(finalPos, flatTarget, Vector3.yAxis)
            return worldCF, tHead
        end

        RunService:BindToRenderStep("SlateFBClient", Enum.RenderPriority.Camera.Value - 1, function(dt)
            LPS_ATTRIBUTES(VM(NONE))
            if not fbActive then return end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local speed = _G._OnyxFaceBangSpeed or 24
            _fbOscTime = _fbOscTime + (speed / 1.5) * dt

            local worldCF = getFBCFrame()
            if not worldCF then return end

            root.CFrame = worldCF
            fbLastWorld = worldCF

            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end)

        fbConn = RunService.PreSimulation:Connect(function()
            LPS_ATTRIBUTES(VM(NONE))
            if not fbActive then return end
            if not target.Parent then stopFacebang(); return end
            local char = LocalPlayer.Character
            if not char then stopFacebang(); return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local worldCF, tHead = getFBCFrame()
            if not worldCF or not tHead then return end

            if canPhysicsRep() then
                pcall(sethiddenproperty, root, "PhysicsRepRootPart", tHead)
                root.CFrame = tHead.CFrame:ToObjectSpace(worldCF)
            else
                root.CFrame = worldCF
            end

            root.AssemblyAngularVelocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero

            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= root then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end)
        end)
    end

    stopFacebang = function()
        if not fbActive then return end
        fbActive = false
        pcall(function() RunService:UnbindFromRenderStep("SlateFBClient") end)
        if fbConn then fbConn:Disconnect(); fbConn = nil end
        if fbWeld then pcall(function() fbWeld:Destroy() end); fbWeld = nil end
        fbStartBtn.Text = "START (Z)"
        fbStartBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and type(sethiddenproperty) == "function" then
            pcall(sethiddenproperty, hrp, "PhysicsRepRootPart", nil)
        end
        if hrp and fbLastWorld then
            hrp.CFrame = fbLastWorld
            fbLastWorld = nil
        end
        pcall(function()
            local c = LocalPlayer.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            end
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end

    fbStartBtn.MouseButton1Click:Connect(function()
        if fbActive then stopFacebang() else startFacebang(getNearestPlayer()) end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Z and fbWindow.Visible then
            if fbActive then stopFacebang() else startFacebang(getNearestPlayer()) end
        end
    end)

    _G.SlateToggleFacebangPanel = function()
        fbSetOpen(not fbWindow.Visible or fbWindow.GroupTransparency > 0.5)
    end
end
task.spawn(setupFacebang)

_G.SlateRunAntiVC = function(setStatus)
    setStatus = setStatus or function() end
    task.spawn(function()
        local ok, err = pcall(function()
            local ref = cloneref or function(v) return v end
            local cfn = clonefunction or function(v) return v end

            local Players_ = ref(game:GetService("Players"))
            local VoiceChatService = ref(game:GetService("VoiceChatService"))
            local VoiceChatInternal = ref(game:GetService("VoiceChatInternal"))
            local StarterGui_ = ref(game:GetService("StarterGui"))
            local CoreGui_ = ref(game:GetService("CoreGui"))

            local lp = Players_.LocalPlayer
            local playerGui = lp:WaitForChild("PlayerGui")

            local getConns = getconnections and cfn(getconnections)
            local getHui = gethui and cfn(gethui)

            local OFFSET_X, OFFSET_Y, ICON_SIZE = 14, 13, 35
            local MUTED_ICON = "rbxasset://textures/ui/VoiceChat/MicLight/Muted.png"
            local talkingIcon = "rbxasset://textures/ui/VoiceChat/MicLight/Talking0.png"

            local micButton, iconFrame, iconImage, redDot

            local function findMic()
                for _, v in ipairs(CoreGui_:GetDescendants()) do
                    if v.Name == "toggle_mic_mute" then
                        micButton = v
                    elseif v.Name == "RedVoiceDot" and v:IsA("GuiObject") then
                        redDot = v
                    end
                end
                if micButton then
                    iconFrame = micButton:FindFirstChild("IntegrationIconFrame", true)
                    if iconFrame then
                        iconImage = iconFrame:FindFirstChild("IntegrationIcon", true)
                    end
                end
            end

            findMic()
            if not micButton then
                task.spawn(function() VoiceChatService:joinVoice() end)
                task.wait(1.5)
                findMic()
            end

            StarterGui_:SetCore("SendNotification", {
                Title = "created by masklol,dm me for issue",
                Text = "Unmute to continue.",
                Duration = 5,
            })
            setStatus("Unmute to continue...", false)

            local function readTalkingIcon()
                if iconImage and iconImage:FindFirstChild("1") then
                    return iconImage["1"].Image
                end
                return nil
            end

            local captured = false
            while not captured do
                local img = readTalkingIcon()
                if img and img ~= MUTED_ICON and img ~= "" then
                    talkingIcon = img
                    captured = true
                end
                if not captured then task.wait(0.5) end
            end
            setStatus("Applying bypass...", false)
            task.wait(1)

            task.spawn(function() VoiceChatService:leaveVoice() end)
            task.wait(2)

            if getConns then
                task.spawn(function()
                    local conns = getConns(VoiceChatInternal.StateChanged)
                    for idx, conn in ipairs(conns) do
                        if idx >= 7 and conn then conn:Disable() end
                    end
                end)
            end

            task.wait(2)
            task.spawn(function() VoiceChatService:joinVoice() end)

            task.wait(1)
            findMic()

            if micButton then
                task.spawn(function()
                    for _, d in ipairs(micButton:GetDescendants()) do
                        if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                            d.ImageTransparency = 1
                        elseif d:IsA("TextLabel") or d:IsA("TextButton") then
                            d.TextTransparency = 1
                        end
                    end
                end)
            end

            local host = (getHui and getHui()) or CoreGui_ or playerGui
            local old = host:FindFirstChild("CustomVoiceController")
            if old then old:Destroy() end

            local sg = Instance.new("ScreenGui")
            sg.Name = "CustomVoiceController"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            sg.DisplayOrder = 999999
            sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            sg.Parent = host

            local hit = Instance.new("TextButton")
            hit.Name = "MicHitArea"
            hit.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
            hit.Position = UDim2.new(0, 150 + OFFSET_X, 0, 4 + OFFSET_Y)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.Active = true
            hit.ZIndex = 10000
            hit.Parent = sg

            local icon = Instance.new("ImageLabel")
            icon.Name = "MicIcon"
            icon.Size = UDim2.new(1, 0, 1, 0)
            icon.BackgroundTransparency = 1
            icon.Image = MUTED_ICON
            icon.ScaleType = Enum.ScaleType.Fit
            icon.ZIndex = 10001
            icon.Parent = hit

            local paused = false
            pcall(function() paused = VoiceChatInternal:IsPublishPaused() end)

            local function applyPause(state)
                icon.Image = state and MUTED_ICON or talkingIcon
                if redDot and redDot.Parent then redDot.Visible = not state end
                task.spawn(function() VoiceChatInternal:PublishPause(state) end)
            end

            hit.MouseButton1Click:Connect(function()
                paused = not paused
                applyPause(paused)
            end)

            applyPause(true)
            paused = true

            local function micPosition()
                if not iconImage or not iconImage.Parent then findMic() end
                if iconImage and iconImage.AbsolutePosition.X > 50 then
                    return iconImage.AbsolutePosition, iconImage.AbsoluteSize
                elseif micButton and micButton.AbsolutePosition.X > 50 then
                    return micButton.AbsolutePosition, micButton.AbsoluteSize
                end
                return nil, nil
            end

            local pos = micPosition()
            if pos and pos.X > 0 and pos.Y >= 0 then
                hit.Position = UDim2.new(0, pos.X + OFFSET_X, 0, pos.Y + OFFSET_Y)
                hit.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
            end

            if redDot and redDot:IsA("GuiObject") then
                redDot.Visible = not paused
            end

            VoiceChatInternal.StateChanged:Connect(function()
                pcall(function() paused = VoiceChatInternal:IsPublishPaused() end)
                if redDot and redDot.Parent then redDot.Visible = not paused end
            end)

            setStatus("Active", true)
        end)
        if not ok then
            setStatus("Failed: " .. tostring(err):sub(1, 60), false)
            warn("[Slate] Anti VC failed: " .. tostring(err))
        end
    end)
end

do
    local function ensureSlateFolder(path)
        pcall(function()
            if makefolder and isfolder then
                local acc = ""
                for part in path:gmatch("[^/]+") do
                    acc = (acc == "") and part or (acc .. "/" .. part)
                    if not isfolder(acc) then makefolder(acc) end
                end
            end
        end)
    end

    local function makeSlateWindow(title, name, w, h)
        LPS_ATTRIBUTES(VM(NONE))
        local root = new("CanvasGroup", {
            Name = name,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, -h / 2),
            Size = UDim2.fromOffset(w, h),
            BackgroundColor3 = T.bg,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 70,
            Parent = gui,
        })
        corner(18).Parent = root
        local glow = createGlow(root, Color3.fromRGB(0, 0, 0), 28, 0.4)
        local rootStroke = stroke(T.lineHi, 1, 0.4)
        rootStroke.Parent = root
        rootStroke.Enabled = false

        local bg = new("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 80, 1, 70),
            BackgroundTransparency = 1,
            Image = "rbxthumb://type=Asset&id=" .. BG_DECAL_ASSET .. "&w=768&h=432",
            ScaleType = Enum.ScaleType.Crop,
            ImageTransparency = 1,
            ZIndex = 70,
            Parent = root,
        })
        corner(18).Parent = bg

        local topBar = new("Frame", {
            Name = "TopBar",
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = T.surface,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 72,
            Parent = root,
        })
        corner(18).Parent = topBar
        pad(0, 10, 0, 10).Parent = topBar

        local brand = new("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 190, 0, 32),
            BackgroundTransparency = 1,
            ZIndex = 73,
            Parent = topBar,
        })
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = brand,
        })
        new("ImageLabel", {
            Size = UDim2.fromOffset(22, 22),
            BackgroundTransparency = 1,
            Image = "rbxthumb://type=Asset&id=" .. SLATE_LOGO_ASSET .. "&w=420&h=420",
            ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = T.accent,
            ZIndex = 74,
            Parent = brand,
        })
        new("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = title,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 15,
            TextColor3 = T.text1,
            ZIndex = 74,
            Parent = brand,
        })

        local dragHandle = new("TextButton", {
            Size = UDim2.new(1, -65, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 73,
            Parent = topBar,
        })

        local topRight = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(60, 26),
            BackgroundTransparency = 1,
            ZIndex = 75,
            Parent = topBar,
        })
        local function topBtn(text, xOff)
            local b = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, xOff, 0.5, 0),
                Size = UDim2.fromOffset(24, 24),
                BackgroundTransparency = 1,
                Text = text,
                Font = Enum.Font.BuilderSansMedium,
                TextSize = 18,
                TextColor3 = T.text2,
                AutoButtonColor = false,
                ZIndex = 76,
                Parent = topRight,
            })
            b.MouseEnter:Connect(function() b.TextColor3 = T.text1 end)
            b.MouseLeave:Connect(function() b.TextColor3 = T.text2 end)
            return b
        end
        local closeBtn = topBtn("×", 0)
        local minBtn = topBtn("–", -26)
        _G.SlateHeaderCtl(closeBtn, "x", 11)
        _G.SlateHeaderCtl(minBtn, "minus", 12)

        local body = new("Frame", {
            Name = "Body",
            Position = UDim2.fromOffset(10, 58),
            Size = UDim2.new(1, -20, 1, -68),
            BackgroundTransparency = 1,
            ZIndex = 71,
            Parent = root,
        })

        local winScale = new("UIScale", { Scale = 1, Parent = root })
        local function winHide() root.Visible = false end
        local win = { root = root, body = body, closeBtn = closeBtn }
        function win.isOpen() return root.Visible and not root:GetAttribute("SlateClosing") end
        function win.setOpen(v)
            if v then
                if root:GetAttribute("SlateClosing") then
                    (_G.SlateWindowAnim or SlateUIState.windowAnim).open(root, winScale)
                elseif not root.Visible then
                    root.Visible = true
                end
            else
                if root.Visible then (_G.SlateWindowAnim or SlateUIState.windowAnim).close(root, winScale, winHide) end
            end
        end
        function win.toggle()
            local open = not win.isOpen()
            win.setOpen(open)
            return open
        end
        root:GetPropertyChangedSignal("Visible"):Connect(function()
            if root.Visible and not root:GetAttribute("SlateClosing") then
                (_G.SlateWindowAnim or SlateUIState.windowAnim).open(root, winScale)
            end
        end)
        closeBtn.MouseButton1Click:Connect(function() win.setOpen(false) end)

        local minimized = false
        minBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            body.Visible = not minimized
            bg.Visible = not minimized
            tween(root, SPRING_FAST, { Size = UDim2.fromOffset(w, minimized and 50 or h) })
            _G.SlateHeaderCtl(minBtn, minimized and "plus" or "minus", 12)
        end)

        local dragging, dragStart, dragOrigin, target = false, Vector2.zero, root.Position, root.Position
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                dragOrigin = root.Position
                target = root.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                target = _G.SlateClampPos(root, UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y))
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        game:GetService("RunService").RenderStepped:Connect(function(dt)
            LPS_ATTRIBUTES(VM(NONE))
            if not root.Visible then return end
            if not (dragging or math.abs(root.Position.X.Offset - target.X.Offset) > 0.4 or math.abs(root.Position.Y.Offset - target.Y.Offset) > 0.4) then return end
            local f = math.clamp(dt * 22, 0.05, 0.95)
            root.Position = UDim2.new(target.X.Scale,
                root.Position.X.Offset + (target.X.Offset - root.Position.X.Offset) * f,
                target.Y.Scale,
                root.Position.Y.Offset + (target.Y.Offset - root.Position.Y.Offset) * f)
        end)
        return win
    end

    local function makeCard(parent, height, order)
        LPS_ATTRIBUTES(VM(NONE))
        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = T.surface2,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            LayoutOrder = order or 0,
            ZIndex = 72,
            Parent = parent,
        })
        corner(9).Parent = card
        local s = stroke(T.line, 1, 0.4)
        s.Parent = card
        return card, s
    end
    local function makeButton(parent, text, w, h)
        LPS_ATTRIBUTES(VM(NONE))
        local b = new("TextButton", {
            Size = UDim2.fromOffset(w, h),
            BackgroundColor3 = T.surface3,
            Text = text,
            TextColor3 = T.text1,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 10,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 74,
            Parent = parent,
        })
        corner(6).Parent = b
        local s = stroke(T.line, 1, 0.5)
        s.Parent = b
        b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(45, 45, 55) end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = T.surface3 end)
        return b, s
    end
    local function makeLabel(parent, text, size, font, color, z)
        LPS_ATTRIBUTES(VM(NONE))
        return new("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            TextSize = size,
            Font = font,
            TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = z or 74,
            Parent = parent,
        })
    end

    local function makePrimary(parent, text, w, h, textSize)
        LPS_ATTRIBUTES(VM(NONE))
        local b = new("TextButton", {
            Size = UDim2.fromOffset(w, h),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutoButtonColor = false,
            Text = text,
            Font = Enum.Font.BuilderSansBold,
            TextSize = textSize or 12,
            TextColor3 = Color3.fromRGB(15, 15, 20),
            BorderSizePixel = 0,
            ZIndex = 74,
            Parent = parent,
        })
        corner(10).Parent = b
        polishPrimary(b)
        return b
    end
    local function makeCaption(parent, text, order)
        LPS_ATTRIBUTES(VM(NONE))
        local l = new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.BuilderSansMedium,
            TextSize = 11,
            TextColor3 = T.text2,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = order or 0,
            ZIndex = 74,
            Parent = parent,
        })
        return l
    end

    do
        local win = makeSlateWindow("Spectate", "SlateSpectatePanel", 270, 340)
        local body = win.body

        local search = new("TextBox", {
            Size = UDim2.new(1, -4, 0, 32),
            Position = UDim2.fromOffset(2, 1),
            BackgroundColor3 = T.surface2,
            BackgroundTransparency = 0.35,
            PlaceholderText = "Search players...",
            PlaceholderColor3 = T.text3,
            Text = "",
            TextColor3 = T.text1,
            ClearTextOnFocus = false,
            TextSize = 11,
            Font = Enum.Font.BuilderSansMedium,
            BorderSizePixel = 0,
            ZIndex = 73,
            Parent = body,
        })
        corner(9).Parent = search
        stroke(T.line, 1, 0.4).Parent = search
        pad(0, 12, 0, 12).Parent = search

        local scroll = new("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 40),
            Size = UDim2.new(1, 0, 1, -40),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 72,
            Parent = body,
        })
        pad(2, 2, 8, 2).Parent = scroll
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

        local empty = new("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 56),
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = "No other players",
            Font = Enum.Font.BuilderSansMedium,
            TextSize = 11,
            TextColor3 = T.text3,
            Visible = false,
            ZIndex = 73,
            Parent = body,
        })

        local viewing, diedConn, subjConn
        local rows = {}

        local function refreshRows()
            for p, info in pairs(rows) do
                local on = viewing == p
                info.btn.Text = on and "Stop" or "Spectate"
                info.stroke.Color = on and T.accent or T.line
                info.stroke.Transparency = on and 0.15 or 0.45
            end
        end

        local function stopSpectating()
            if diedConn then diedConn:Disconnect(); diedConn = nil end
            if subjConn then subjConn:Disconnect(); subjConn = nil end
            viewing = nil
            pcall(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                workspace.CurrentCamera.CameraSubject = hum or LocalPlayer.Character
            end)
            refreshRows()
        end

        local function startSpectating(p)
            stopSpectating()
            if not (p and p.Character) then return end
            viewing = p
            pcall(function()
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                workspace.CurrentCamera.CameraSubject = hum or p.Character
            end)
            diedConn = p.CharacterAdded:Connect(function(ch)
                local hum = ch:WaitForChild("Humanoid", 5)
                if viewing == p and hum then
                    pcall(function() workspace.CurrentCamera.CameraSubject = hum end)
                end
            end)
            subjConn = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
                if viewing == p and p.Character then
                    task.defer(function()
                        pcall(function()
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            workspace.CurrentCamera.CameraSubject = hum or p.Character
                        end)
                    end)
                end
            end)
            refreshRows()
        end

        local function rebuild()
            local okB, errB = pcall(function()
                for _, c in ipairs(scroll:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                rows = {}
                local q = search.Text:lower()
                local list = Players:GetPlayers()
                table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
                local order = 0
                for _, p in ipairs(list) do
                    if p ~= LocalPlayer and (q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) then
                        order = order + 1
                        local row, rStroke = makeCard(scroll, 46, order)
                        row.Name = p.Name
                        local img = new("Frame", {
                            Position = UDim2.new(0, 8, 0.5, -16),
                            Size = UDim2.fromOffset(32, 32),
                            BackgroundColor3 = T.surface3,
                            BorderSizePixel = 0,
                            ZIndex = 73,
                            Parent = row,
                        })
                        corner(6).Parent = img
                        stroke(T.line, 1, 0.5).Parent = img
                        local face = new("ImageLabel", {
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150",
                            ZIndex = 74,
                            Parent = img,
                        })
                        corner(6).Parent = face
                        local nm = makeLabel(row, p.DisplayName, 11, Enum.Font.BuilderSansBold, T.text1)
                        nm.Position = UDim2.fromOffset(48, 7)
                        nm.Size = UDim2.new(1, -128, 0, 16)
                        local un = makeLabel(row, "@" .. p.Name, 9, Enum.Font.BuilderSans, T.text3)
                        un.Position = UDim2.fromOffset(48, 24)
                        un.Size = UDim2.new(1, -128, 0, 13)
                        local btn = makePrimary(row, "Spectate", 64, 24, 10)
                        corner(7).Parent = btn
                        btn.AnchorPoint = Vector2.new(1, 0.5)
                        btn.Position = UDim2.new(1, -8, 0.5, 0)
                        btn.MouseButton1Click:Connect(function()
                            if viewing == p then stopSpectating() else startSpectating(p) end
                        end)
                        rows[p] = { row = row, btn = btn, stroke = rStroke }
                    end
                end
                empty.Visible = (order == 0)
                refreshRows()
            end)
            if not okB then warn("[Slate] Spectate list failed: " .. tostring(errB)) end
        end

        search:GetPropertyChangedSignal("Text"):Connect(rebuild)
        Players.PlayerAdded:Connect(function() if win.isOpen() then task.defer(rebuild) end end)
        Players.PlayerRemoving:Connect(function(p)
            if viewing == p then stopSpectating() end
            if win.isOpen() then task.defer(rebuild) end
        end)

        _G.SlateToggleSpectatePanel = function()
            if win.toggle() then rebuild() end
        end
    end

    do
        local KEY_FILE = "slate/keybinds/fakeout.json"
        local win = makeSlateWindow("Fakeout", "SlateFakeoutPanel", 270, 194)
        local body = win.body
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })

        makeCaption(body, "Teleports you to the void and back.", 1)
        local runBtn = makePrimary(body, "Fake out", 100, 36, 12)
        runBtn.Size = UDim2.new(1, 0, 0, 36)
        runBtn.LayoutOrder = 2

        local keyCard = makeCard(body, 44, 3)
        pad(0, 8, 0, 12).Parent = keyCard
        local k1 = makeLabel(keyCard, "Keybind", 11, Enum.Font.BuilderSansBold, T.text1)
        k1.Size = UDim2.new(0.5, 0, 1, 0)
        local keyBtn = makeButton(keyCard, "None", 72, 26)
        keyBtn.AnchorPoint = Vector2.new(1, 0.5)
        keyBtn.Position = UDim2.new(1, 0, 0.5, 0)
        _G.SlateKeyIconize(keyBtn)

        local boundKey = nil
        local listening = false

        local function saveKey()
            pcall(function()
                ensureSlateFolder("slate/keybinds")
                writefile(KEY_FILE, HttpService:JSONEncode({ key = boundKey and boundKey.Name or nil }))
            end)
        end
        pcall(function()
            if isfile and isfile(KEY_FILE) and readfile then
                local data = HttpService:JSONDecode(readfile(KEY_FILE))
                if type(data) == "table" and data.key and Enum.KeyCode[data.key] then
                    boundKey = Enum.KeyCode[data.key]
                end
            end
        end)
        local function showKey()
            keyBtn.Text = boundKey and boundKey.Name or "None"
            keyBtn.TextColor3 = T.text1
        end
        showKey()

        local busy = false
        local function runFakeout()
            if busy then return end
            if not _G.SlateRunFakeout then
                queueNotification("Fakeout", "Fakeout is still loading", 3, "warning")
                return
            end
            busy = true
            runBtn.Text = "Faking out..."
            task.spawn(function()
                pcall(_G.SlateRunFakeout)
                busy = false
                runBtn.Text = "Fake out"
            end)
        end
        runBtn.MouseButton1Click:Connect(runFakeout)

        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            if boundKey then
                boundKey = nil
                saveKey()
                showKey()
                return
            end
            listening = true
            keyBtn.Text = "..."
            keyBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        end)

        UserInputService.InputBegan:Connect(function(input, gpe)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if listening then
                listening = false
                if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                    boundKey = nil
                elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                    boundKey = input.KeyCode
                end
                saveKey()
                showKey()
                return
            end
            if gpe or not win.isOpen() then return end
            if boundKey and input.KeyCode == boundKey then
                runFakeout()
            end
        end)

        _G.SlateToggleFakeoutPanel = function() win.toggle() end
    end

    do
        local win = makeSlateWindow("Anti VC", "SlateAntiVCPanel", 270, 150)
        local body = win.body
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })

        makeCaption(body, "Bypass the voice chat mute state. Unmute when asked.", 1)
        local actBtn = makePrimary(body, "Activate", 100, 36, 12)
        actBtn.Size = UDim2.new(1, 0, 0, 36)
        actBtn.LayoutOrder = 2

        local started = false
        actBtn.MouseButton1Click:Connect(function()
            if started then return end
            started = true
            actBtn.Text = "Starting..."
            _G.SlateRunAntiVC(function(text, done)
                actBtn.Text = done and "Active" or text
                if not done and text:sub(1, 6) == "Failed" then started = false end
            end)
        end)

        _G.SlateToggleAntiVCPanel = function() win.toggle() end
    end
end

do
local _slateActualToggleEmoteMenu = nil
local _slateEmoteMenuLoading = false
local function ensureEmoteMenuLoaded()
	LPS_ATTRIBUTES(VM(NONE))
	if _slateActualToggleEmoteMenu or _slateEmoteMenuLoading then
		return
	end
	_slateEmoteMenuLoading = true
	local SHOW_UI_ON_EXECUTE = false
	local players = game:GetService("Players")
	local tweenService = game:GetService("TweenService")
	local userInputSvc = game:GetService("UserInputService")
	local httpService = game:GetService("HttpService")
	local runService = game:GetService("RunService")
	local marketplaceService = game:GetService("MarketplaceService")
	local localPlr = players.LocalPlayer
	local panelHost = (gethui and gethui()) or game:GetService("CoreGui")
	local C = {
		bg = T.bg,
		panel = T.surface,
		card = T.surface2,
		input = T.surface,
		border = T.line,
		text = T.text1,
		sub = T.text2,
		accent = T.accent,
		danger = T.danger,
		success = T.success,
	}

	local function cr(r, p)
		local c = Instance.new("UICorner", p)
		c.CornerRadius = UDim.new(0, r)
		return c
	end

	local function stk(t, col, p)
		local s = Instance.new("UIStroke", p)
		s.Thickness = t or 0.99
		s.Color = col or C.border
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		return s
	end

	local function tw(obj, props, dur)
		return tweenService:Create(
			obj,
			TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			props
		)
	end

	local function lbl(parent, text, size, font, col, xa)
		local l = Instance.new("TextLabel", parent)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextSize = size or 12
		l.Font = font or Enum.Font.BuilderSansBold
		l.TextColor3 = col or C.text
		l.TextXAlignment = xa or Enum.TextXAlignment.Left
		return l
	end

	local function downloadExternalImage(url)
		if
			type(writefile) ~= "function" or (type(getcustomasset) ~= "function" and type(getsynasset) ~= "function")
		then
			return "rbxassetid://18055627255"
		end
		if makefolder and not isfolder("slate/cache") then
			if not isfolder("slate") then
				pcall(makefolder, "slate")
			end
			pcall(makefolder, "slate/cache")
		end
		local cleanName = "slate/cache/slate_cache_" .. tostring(url):gsub("[^%a%d]", "_") .. ".png"
		local get_asset = getcustomasset or getsynasset
		local is_file = isfile or function(path)
			return pcall(readfile, path)
		end
		if is_file(cleanName) then
			local ok, asset = pcall(get_asset, cleanName)
			if ok then
				return asset
			end
		end
		local success, content = pcall(function()
			return game:HttpGet(url)
		end)
		if success and content and content ~= "" then
			pcall(writefile, cleanName, content)
			local ok, asset = pcall(get_asset, cleanName)
			if ok then
				return asset
			end
		end
		return "rbxassetid://18055627255"
	end

	local function resolveImageId(idStr)
		if not idStr or idStr == 0 or idStr == "0" or idStr == "" then
			return "rbxassetid://18055627255"
		end
		local str = tostring(idStr)
		if str:find("http://") or str:find("https://") then
			return downloadExternalImage(str)
		end
		if str:find("rbxassetid://") or str:find("rbxthumb://") or str:find("rbxasset://") then
			local numericId = str:match("%d+$")
			if numericId then
				local num = tonumber(numericId)
				local ok, info = pcall(function()
					return marketplaceService:GetProductInfo(num)
				end)
				if ok and info and info.AssetTypeId == 13 then
					return "rbxthumb://type=Asset&id=" .. numericId .. "&w=150&h=150"
				end
			end
			return str
		end
		local numericId = str:match("%d+")
		if numericId then
			local num = tonumber(numericId)
			local ok, info = pcall(function()
				return marketplaceService:GetProductInfo(num)
			end)
			if ok and info and info.AssetTypeId == 13 then
				return "rbxthumb://type=Asset&id=" .. numericId .. "&w=150&h=150"
			end
			return "rbxassetid://" .. numericId
		end
		return str
	end

	local function resolveAnimationId(rawId)
		local idStr = tostring(rawId):gsub("%.0$", ""):match("%d+") or tostring(rawId)
		_G.__SlateAnimIdCache = _G.__SlateAnimIdCache or {}
		if _G.__SlateAnimIdCache[idStr] then
			return _G.__SlateAnimIdCache[idStr], nil
		end
		task.wait()
		local ok, obj = pcall(function()
			return game:GetObjects("rbxassetid://" .. idStr)
		end)
		if ok and obj and #obj > 0 and obj[1] then
			local animObj = obj[1]
			if not animObj:IsA("Animation") then
				animObj = animObj:FindFirstChildOfClass("Animation")
					or animObj:FindFirstChildWhichIsA("Animation", true)
			end
			if
				animObj
				and animObj:IsA("Animation")
				and animObj.AnimationId ~= ""
				and animObj.AnimationId ~= "rbxassetid://0"
			then
				local realId = animObj.AnimationId:match("%d+")
				if realId then
					_G.__SlateAnimIdCache[idStr] = realId
					return realId, animObj
				end
			end
		end
		return idStr, nil
	end
	local PackCustomImages = {
		["Vampire"] = "https://i.postimg.cc/85gFFGxp/vampirepack.webp",
		["Ghost"] = "https://i.postimg.cc/rm2ddT7X/ghostpack.webp",
		["Robot"] = "https://i.postimg.cc/nzfssxNZ/robotpack.webp",
		["Zombie"] = "https://i.postimg.cc/KzhKKbCc/zombiepaack.webp",
		["Ninja"] = "https://i.postimg.cc/9MH442sh/ninjapack.webp",
		["Pirate"] = "https://i.postimg.cc/SsbXX4H4/piratepack.webp",
		["Mage"] = "https://i.postimg.cc/d1c77FgK/magepack.webp",
		["Knight"] = "https://i.postimg.cc/TwvyyxBv/knightpack.webp",
		["Superhero"] = "https://i.postimg.cc/d1c77FgJ/superheropack.webp",
		["Cartoony"] = "https://i.postimg.cc/TwvyyxFS/cartoonyreal.webp",
		["Toy"] = "https://i.postimg.cc/j5YWWTmG/cartoonpack.webp",
		["Astronaut"] = "https://i.postimg.cc/RFx33myY/Astronautpack.webp",
		["Sneaky"] = "https://i.postimg.cc/76rCC4jw/sneakyanimpack.webp",
		["Default"] = "https://i.postimg.cc/mDWcc4JK/defaultanimpack.webp",
	}
	local OriginalAnimations = {
		["Idle"] = {
			["2016 Animation (mm2)"] = { "387947158", "387947464" },
			["(UGC) Oh Really?"] = { "98004748982532", "98004748982532" },
			["Astronaut"] = { "891621366", "891633237" },
			["Adidas Community"] = { "122257458498464", "102357151005774" },
			["Bold"] = { "16738333868", "16738334710" },
			["(UGC) Slasher"] = { "140051337061095", "140051337061095" },
			["(UGC) Retro"] = { "80479383912838", "80479383912838" },
			["(UGC) Magician"] = { "139433213852503", "139433213852503" },
			["(UGC) John Doe"] = { "72526127498800", "72526127498800" },
			["(UGC) Noli"] = { "139360856809483", "139360856809483" },
			["(UGC) Coolkid"] = { "95203125292023", "95203125292023" },
			["(UGC) Survivor Injured"] = { "73905365652295", "73905365652295" },
			["(UGC) Retro Zombie"] = { "90806086002292", "90806086002292" },
			["(UGC) 1x1x1x1"] = { "76780522821306", "76780522821306" },
			["Borock"] = { "3293641938", "3293642554" },
			["Bubbly"] = { "910004836", "910009958" },
			["Cartoony"] = { "742637544", "742638445" },
			["Confident"] = { "1069977950", "1069987858" },
			["Catwalk Glam"] = { "133806214992291", "94970088341563" },
			["Cowboy"] = { "1014390418", "1014398616" },
			["Drooling Zombie"] = { "3489171152", "3489171152" },
			["Elder"] = { "10921101664", "10921102574" },
			["Ghost"] = { "616006778", "616008087" },
			["Knight"] = { "657595757", "657568135" },
			["Levitation"] = { "616006778", "616008087" },
			["Mage"] = { "707742142", "707855907" },
			["MrToilet"] = { "4417977954", "4417978624" },
			["Ninja"] = { "656117400", "656118341" },
			["NFL"] = { "92080889861410", "74451233229259" },
			["OldSchool"] = { "10921230744", "10921232093" },
			["Patrol"] = { "1149612882", "1150842221" },
			["Pirate"] = { "750781874", "750782770" },
			["Default Retarget"] = { "95884606664820", "95884606664820" },
			["Very Long"] = { "18307781743", "18307781743" },
			["Sway"] = { "560832030", "560833564" },
			["Popstar"] = { "1212900985", "1150842221" },
			["Princess"] = { "941003647", "941013098" },
			["R6"] = { "12521158637", "12521162526" },
			["R15 Reanimated"] = { "4211217646", "4211218409" },
			["Realistic"] = { "17172918855", "17173014241" },
			["Robot"] = { "616088211", "616089559" },
			["Sneaky"] = { "1132473842", "1132477671" },
			["Sports (Adidas)"] = { "18537376492", "18537371272" },
			["Soldier"] = { "3972151362", "3972151362" },
			["Stylish"] = { "616136790", "616138447" },
			["Stylized Female"] = { "4708191566", "4708192150" },
			["Superhero"] = { "10921288909", "10921290167" },
			["Toy"] = { "782841498", "782845736" },
			["Udzal"] = { "3303162274", "3303162549" },
			["Vampire"] = { "1083445855", "1083450166" },
			["Werewolf"] = { "1083195517", "1083214717" },
			["Wicked (Popular)"] = { "118832222982049", "76049494037641" },
			["No Boundaries (Walmart)"] = { "18747067405", "18747063918" },
			["Zombie"] = { "616158929", "616160636" },
			["(UGC) Zombie"] = { "77672872857991", "77672872857991" },
			["(UGC) TailWag"] = { "129026910898635", "129026910898635" },
			["[VOTE] warming up"] = { "83573330053643", "83573330053643" },
			["cesus"] = { "115879733952840", "115879733952840" },
			["[VOTE] Float"] = { "110375749767299", "110375749767299" },
			["UGC Oneleft"] = { "121217497452435", "121217497452435" },
			["AuraFarming"] = { "138665010911335", "138665010911335" },
			["[VOTE] Mech Float"] = { "74447366032908", "74447366032908" },
			["Badware"] = { "140131631438778", "140131631438778" },
			['Wicked "Dancing Through Life"'] = { "92849173543269", "132238900951109" },
			["Unboxed By Amazon"] = { "98281136301627", "138183121662404" },
		},
		["Walk"] = {
			["Geto"] = "85811471336028",
			["Patrol"] = "1151231493",
			["Drooling Zombie"] = "3489174223",
			["Adidas Community"] = "122150855457006",
			["Levitation"] = "616013216",
			["Catwalk Glam"] = "109168724482748",
			["Knight"] = "10921127095",
			["Pirate"] = "750785693",
			["Bold"] = "16738340646",
			["Sports (Adidas)"] = "18537392113",
			["Zombie"] = "616168032",
			["Astronaut"] = "891667138",
			["Cartoony"] = "742640026",
			["Ninja"] = "656121766",
			["Confident"] = "1070017263",
			['Wicked "Dancing Through Life"'] = "73718308412641",
			["Unboxed By Amazon"] = "90478085024465",
			["Gojo"] = "95643163365384",
			["R15 Reanimated"] = "4211223236",
			["Ghost"] = "616013216",
			["2016 Animation (mm2)"] = "387947975",
			["(UGC) Zombie"] = "113603435314095",
			["No Boundaries (Walmart)"] = "18747074203",
			["Rthro"] = "10921269718",
			["Werewolf"] = "1083178339",
			["Wicked (Popular)"] = "92072849924640",
			["Vampire"] = "1083473930",
			["Popstar"] = "1212980338",
			["Mage"] = "707897309",
			["(UGC) Smooth"] = "76630051272791",
			["R6"] = "12518152696",
			["NFL"] = "110358958299415",
			["Bubbly"] = "910034870",
			["(UGC) Retro"] = "107806791584829",
			["(UGC) Retro Zombie"] = "140703855480494",
			["OldSchool"] = "10921244891",
			["Elder"] = "10921111375",
			["Stylish"] = "616146177",
			["Stylized Female"] = "4708193840",
			["Robot"] = "616095330",
			["Sneaky"] = "1132510133",
			["Superhero"] = "10921298616",
			["Udzal"] = "3303162967",
			["Toy"] = "782843345",
			["Default Retarget"] = "115825677624788",
			["Princess"] = "941028902",
			["Cowboy"] = "1014421541",
		},
		["Run"] = {
			["Robot"] = "10921250460",
			["Patrol"] = "1150967949",
			["Drooling Zombie"] = "3489173414",
			["Adidas Community"] = "82598234841035",
			["Heavy Run (Udzal / Borock)"] = "3236836670",
			["Catwalk Glam"] = "81024476153754",
			["Knight"] = "10921121197",
			["Pirate"] = "750783738",
			["Bold"] = "16738337225",
			["Sports (Adidas)"] = "18537384940",
			["Zombie"] = "616163682",
			["Astronaut"] = "10921039308",
			["Cartoony"] = "10921076136",
			["Ninja"] = "656118852",
			["(UGC) Dog"] = "130072963359721",
			['Wicked "Dancing Through Life"'] = "135515454877967",
			["Unboxed By Amazon"] = "134824450619865",
			["[UGC] Flipping"] = "124427738251511",
			["Sneaky"] = "1132494274",
			["R6"] = "12518152696",
			["[VOTE] Aura"] = "120142877225965",
			["Popstar"] = "1212980348",
			["[UGC] reset"] = "0",
			["Wicked (Popular)"] = "72301599441680",
			["[UGC] chibi"] = "85887415033585",
			["R15 Reanimated"] = "4211220381",
			["Mage"] = "10921148209",
			["Ghost"] = "616013216",
			["Rthro"] = "10921261968",
			["Confident"] = "1070001516",
			["Stylized Female"] = "4708192705",
			["No Boundaries (Walmart)"] = "18747070484",
			["Elder"] = "10921104374",
			["Werewolf"] = "10921336997",
			["[UGC] Girly"] = "128578785610052",
			["Stylish"] = "10921276116",
			["(UGC) Pride"] = "116462200642360",
			["NFL"] = "117333533048078",
			["(UGC) Soccer"] = "116881956670910",
			["MrToilet"] = "4417979645",
			["[VOTE] Float"] = "71267457613791",
			["Levitation"] = "616010382",
			["(UGC) Retro"] = "107806791584829",
			["(UGC) Retro Zombie"] = "140703855480494",
			["OldSchool"] = "10921240218",
			["Vampire"] = "10921320299",
			["furry"] = "102269417125238",
			["Bubbly"] = "10921057244",
			["fake wicked"] = "138992096476836",
			["2016 Animation (mm2)"] = "387947975",
			["[UGC] ball"] = "132499588684957",
			["Superhero"] = "10921291831",
			["Toy"] = "10921306285",
			["Default Retarget"] = "102294264237491",
			["Princess"] = "941015281",
			["Cowboy"] = "1014401683",
		},
		["Jump"] = {
			["Robot"] = "616090535",
			["Patrol"] = "1148811837",
			["Adidas Community"] = "75290611992385",
			["Levitation"] = "616008936",
			["Catwalk Glam"] = "116936326516985",
			["Knight"] = "910016857",
			["Pirate"] = "750782230",
			["Bold"] = "16738336650",
			["Sports (Adidas)"] = "18537380791",
			["Zombie"] = "616161997",
			["Astronaut"] = "891627522",
			["Cartoony"] = "742637942",
			["Ninja"] = "656117878",
			["Confident"] = "1069984524",
			['Wicked "Dancing Through Life"'] = "78508480717326",
			["Unboxed By Amazon"] = "121454505477205",
			["R6"] = "12520880485",
			["R15 Reanimated"] = "4211219390",
			["Ghost"] = "616008936",
			["Rthro"] = "10921263860",
			["No Boundaries (Walmart)"] = "18747069148",
			["Werewolf"] = "1083218792",
			["Cowboy"] = "1014394726",
			["UGC"] = "91788124131212",
			["[VOTE] Animal"] = "131203832825082",
			["Popstar"] = "1212954642",
			["Mage"] = "10921149743",
			["Sneaky"] = "1132489853",
			["Superhero"] = "10921294559",
			["Elder"] = "10921107367",
			["(UGC) Retro"] = "139390570947836",
			["NFL"] = "119846112151352",
			["OldSchool"] = "10921242013",
			["Stylized Female"] = "4708188025",
			["Stylish"] = "616139451",
			["Bubbly"] = "910016857",
			["[VOTE] Float"] = "75611679208549",
			["[VOTE] Aura"] = "93382302369459",
			["Vampire"] = "1083455352",
			["Wicked (Popular)"] = "104325245285198",
			["Toy"] = "10921308158",
			["Default Retarget"] = "117150377950987",
			["Princess"] = "941008832",
			["[UGC] happy"] = "72388373557525",
		},
		["Fall"] = {
			["Robot"] = "616087089",
			["Patrol"] = "1148863382",
			["Adidas Community"] = "98600215928904",
			["Levitation"] = "616005863",
			["Catwalk Glam"] = "92294537340807",
			["Knight"] = "10921122579",
			["Pirate"] = "750780242",
			["Bold"] = "16738333171",
			["Sports (Adidas)"] = "18537367238",
			["Zombie"] = "616157476",
			["Astronaut"] = "891617961",
			["Cartoony"] = "742637151",
			["Ninja"] = "656115606",
			["Confident"] = "1069973677",
			['Wicked "Dancing Through Life"'] = "78147885297412",
			["Unboxed By Amazon"] = "94788218468396",
			["R6"] = "12520972571",
			["[UGC] skydiving"] = "102674302534126",
			["R15 Reanimated"] = "4211216152",
			["Rthro"] = "10921262864",
			["No Boundaries (Walmart)"] = "18747062535",
			["Werewolf"] = "1083189019",
			["[VOTE] TPose"] = "139027266704971",
			["Mage"] = "707829716",
			["[VOTE] Animal"] = "77069224396280",
			["Wicked (Popular)"] = "121152442762481",
			["Popstar"] = "1212900995",
			["NFL"] = "129773241321032",
			["OldSchool"] = "10921241244",
			["Sneaky"] = "1132469004",
			["Elder"] = "10921105765",
			["Bubbly"] = "910001910",
			["Stylish"] = "616134815",
			["Stylized Female"] = "4708186162",
			["Vampire"] = "1083443587",
			["Superhero"] = "10921293373",
			["Toy"] = "782846423",
			["Default Retarget"] = "110205622518029",
			["Princess"] = "941000007",
			["Cowboy"] = "1014384571",
		},
		["SwimIdle"] = {
			["Sneaky"] = "1132506407",
			["SuperHero"] = "10921297391",
			["Adidas Community"] = "109346520324160",
			["Levitation"] = "10921139478",
			["Catwalk Glam"] = "98854111361360",
			["Knight"] = "10921125935",
			["Pirate"] = "750785176",
			["Bold"] = "16738339817",
			["Sports (Adidas)"] = "18537387180",
			["Stylized"] = "4708190607",
			["Astronaut"] = "891663592",
			["Cartoony"] = "10921079380",
			["Wicked (Popular)"] = "113199415118199",
			["Mage"] = "707894699",
			['Wicked "Dancing Through Life"'] = "129183123083281",
			["Unboxed By Amazon"] = "129126268464847",
			["R6"] = "12518152696",
			["Rthro"] = "10921265698",
			["CowBoy"] = "1014411816",
			["No Boundaries (Walmart)"] = "18747071682",
			["Werewolf"] = "10921341319",
			["NFL"] = "79090109939093",
			["OldSchool"] = "10921244018",
			["Robot"] = "10921253767",
			["Elder"] = "10921110146",
			["Bubbly"] = "910030921",
			["Patrol"] = "1151221899",
			["Vampire"] = "10921325443",
			["Popstar"] = "1212998578",
			["Ninja"] = "656118341",
			["Toy"] = "10921310341",
			["Confident"] = "1070012133",
			["Princess"] = "941025398",
			["Stylish"] = "10921281964",
		},
		["Swim"] = {
			["Sneaky"] = "1132500520",
			["Patrol"] = "1151204998",
			["Adidas Community"] = "133308483266208",
			["Levitation"] = "10921138209",
			["Catwalk Glam"] = "134591743181628",
			["Knight"] = "10921125160",
			["Pirate"] = "750784579",
			["Bold"] = "16738339158",
			["Sports (Adidas)"] = "18537389531",
			["Zombie"] = "616165109",
			["Astronaut"] = "891663592",
			["Cartoony"] = "10921079380",
			["Wicked (Popular)"] = "99384245425157",
			["Mage"] = "707876443",
			["PopStar"] = "1212998578",
			["Unboxed By Amazon"] = "105962919001086",
			["R6"] = "12518152696",
			["[VOTE] Boat"] = "85689117221382",
			["Rthro"] = "10921264784",
			["CowBoy"] = "1014406523",
			["No Boundaries (Walmart)"] = "18747073181",
			["Werewolf"] = "10921340419",
			["NFL"] = "132697394189921",
			["OldSchool"] = "10921243048",
			['Wicked "Dancing Through Life"'] = "110657013921774",
			["Elder"] = "10921108971",
			["Bubbly"] = "910028158",
			["Robot"] = "10921253142",
			["[VOTE] Aura"] = "80645586378736",
			["Vampire"] = "10921324408",
			["Stylish"] = "10921281000",
			["Toy"] = "10921309319",
			["SuperHero"] = "10921295495",
			["Princess"] = "941018893",
			["Confident"] = "1070009914",
		},
		["Climb"] = {
			["Robot"] = "616086039",
			["Patrol"] = "1148811837",
			["Adidas Community"] = "88763136693023",
			["Levitation"] = "10921132092",
			["Catwalk Glam"] = "119377220967554",
			["Knight"] = "10921125160",
			["[VOTE] Animal"] = "124810859712282",
			["Bold"] = "16738332169",
			["Sports (Adidas)"] = "18537363391",
			["Zombie"] = "616156119",
			["Astronaut"] = "10921032124",
			["Cartoony"] = "742636889",
			["Ninja"] = "656114359",
			["Confident"] = "1069946257",
			['Wicked "Dancing Through Life"'] = "129447497744818",
			["Unboxed By Amazon"] = "121145883950231",
			["R6"] = "12520982150",
			["Ghost"] = "616003713",
			["Rthro"] = "10921257536",
			["CowBoy"] = "1014380606",
			["No Boundaries (Walmart)"] = "18747060903",
			["Mage"] = "707826056",
			["[VOTE] sticky"] = "77520617871799",
			["Reanimated R15"] = "4211214992",
			["Popstar"] = "1213044953",
			["(UGC) Retro"] = "121075390792786",
			["NFL"] = "134630013742019",
			["OldSchool"] = "10921229866",
			["Sneaky"] = "1132461372",
			["Elder"] = "845392038",
			["Stylized Female"] = "4708184253",
			["Stylish"] = "10921271391",
			["SuperHero"] = "10921286911",
			["WereWolf"] = "10921329322",
			["Vampire"] = "1083439238",
			["Toy"] = "10921300839",
			["Wicked (Popular)"] = "131326830509784",
			["Princess"] = "940996062",
			["[VOTE] Rope"] = "134977367563514",
		},
	}
	local PACK_NAMES = {
		"Vampire",
		"Ghost",
		"Robot",
		"Zombie",
		"Ninja",
		"Pirate",
		"Mage",
		"Knight",
		"Superhero",
		"Cartoony",
		"Toy",
		"Astronaut",
		"Sneaky",
		"Default",
	}
	local EMOTES = {
		{ id = "3360689775", name = "Salute" },
		{ id = "5915779043", name = "Applaud" },
		{ id = "3360692915", name = "Tilt" },
		{ id = "3823158750", name = "Godlike" },
		{ id = "5230661597", name = "Bored" },
		{ id = "4689362868", name = "Sleep" },
		{ id = "3576717965", name = "Shy" },
		{ id = "5104377791", name = "Hero Landing" },
		{ id = "5917570207", name = "Floss Dance" },
		{ id = "3716636630", name = "Monkey" },
		{ id = "4646306583", name = "Curtsy" },
		{ id = "4849502101", name = "Sad" },
		{ id = "3576968026", name = "Shrug" },
		{ id = "3576686446", name = "Hello" },
		{ id = "3360686498", name = "Stadium" },
		{ id = "4940597758", name = "Cower" },
		{ id = "4102315500", name = "Haha" },
		{ id = "3934986896", name = "Dizzy" },
		{ id = "4849499887", name = "Happy" },
		{ id = "79752538807060", name = "Griddy" },
		{ id = "4849497510", name = "Power Blast" },
		{ id = "3576823880", name = "Pointing" },
		{ id = "93511411593120", name = "/e fly" },
		{ id = "114899970878842", name = "R15 Death" },
		{ id = "132074413582912", name = "California Girl" },
		{ id = "93105950995997", name = "Caramelldansen" },
		{ id = "70615023659736", name = "Floating" },
		{ id = "78620443286892", name = "Cute Laying" },
		{ id = "130998336536045", name = "Gangnam Style" },
		{ id = "75528418031928", name = "Rambunctious" },
	}
	local emoteFavorites = {}
	local emoteKeybinds = {}
	local listeningEmoteId = nil
	local listeningKeyBtn = nil

	local function loadEmoteState()
		pcall(function()
			if isfile and readfile then
				local favPath = isfile("slate/emotes/favs.json") and "slate/emotes/favs.json"
					or (isfile("slate/emotes_favs.json") and "slate/emotes_favs.json")
				if favPath then
					local ok, decoded = pcall(function()
						return httpService:JSONDecode(readfile(favPath))
					end)
					if ok and type(decoded) == "table" then
						emoteFavorites = decoded
					end
				end
				local bindPath = isfile("slate/emotes/binds.json") and "slate/emotes/binds.json"
					or (isfile("slate/emotes_binds.json") and "slate/emotes_binds.json")
				if bindPath then
					local ok, decoded = pcall(function()
						return httpService:JSONDecode(readfile(bindPath))
					end)
					if ok and type(decoded) == "table" then
						emoteKeybinds = decoded
					end
				end
			end
		end)
	end
	loadEmoteState()
	local _inventoryLoaded = false
	local _buildEmotesListCallback = nil

	local function _refreshEmoteUI()
		if _buildEmotesListCallback then
			pcall(_buildEmotesListCallback)
		end
	end
	local _emoteIdSet = {}
	for _, em in ipairs(EMOTES) do
		_emoteIdSet[tostring(em.id)] = true
	end

	local _allEmotesById = {}
	for _, em in ipairs(EMOTES) do
		_allEmotesById[tostring(em.id)] = em
	end
	local function _getEmoteName(id)
		local em = _allEmotesById[tostring(id)]
		return em and em.name or ("Emote " .. tostring(id))
	end
	local function _registerEmote(id, name)
		local sId = tostring(id)
		if not _allEmotesById[sId] then
			_allEmotesById[sId] = { id = sId, name = name }
		elseif name and name ~= "" and _allEmotesById[sId].name:match("^Emote %d+") then
			_allEmotesById[sId].name = name
		end
	end

	local function _addEmoteBatch(batch)
		if #batch == 0 then
			return
		end
		for _, em in ipairs(batch) do
			local key = tostring(em.id)
			_registerEmote(key, em.name)
			if not _emoteIdSet[key] then
				_emoteIdSet[key] = true
				table.insert(EMOTES, em)
			end
		end
	end
	local _rawCatalog = nil
	task.spawn(function()
		task.wait(0.5)
		local cachePath = "slate/emotecache.json"
		local cacheLoaded = false
		if isfile and readfile and isfile(cachePath) then
			local okRead, content = pcall(readfile, cachePath)
			if okRead and content and content ~= "" then
				local okDec, decoded = pcall(function()
					return httpService:JSONDecode(content)
				end)
				if okDec and type(decoded) == "table" then
					_rawCatalog = (type(decoded.data) == "table" and decoded.data) or decoded
					if type(decoded.totalItems) == "number" then
						_G._rawCatalogTotalItems = decoded.totalItems
					else
						_G._rawCatalogTotalItems = #_rawCatalog
					end
					for _, item in ipairs(_rawCatalog) do
						if type(item) == "table" then
							local id = tostring(item.id or item.idStr or item.assetId or item.AssetId or "")
							local name = tostring(item.name or item.Name or "Unknown")
							if id ~= "" then _registerEmote(id, name) end
						end
					end
					cacheLoaded = true
					_refreshEmoteUI()
				end
			end
		end
		if not cacheLoaded then
			local reqFunc = request or http_request or (syn and syn.request) or (http and http.request)
			local jsonUrl = "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json"
			local okJson, resJson
			if reqFunc then
				okJson, resJson = pcall(reqFunc, { Url = jsonUrl, Method = "GET" })
			else
				local okH, body = pcall(function()
					return game:HttpGet(jsonUrl)
				end)
				if okH and body then
					okJson = true
					resJson = { StatusCode = 200, Body = body }
				end
			end
			if okJson and resJson and resJson.StatusCode == 200 and resJson.Body then
				local okDec, decoded = pcall(function()
					return httpService:JSONDecode(resJson.Body)
				end)
				if okDec and type(decoded) == "table" then
					_rawCatalog = (type(decoded.data) == "table" and decoded.data) or decoded
					if type(decoded.totalItems) == "number" then
						_G._rawCatalogTotalItems = decoded.totalItems
					else
						_G._rawCatalogTotalItems = #_rawCatalog
					end
					for _, item in ipairs(_rawCatalog) do
						if type(item) == "table" then
							local id = tostring(item.id or item.idStr or item.assetId or item.AssetId or "")
							local name = tostring(item.name or item.Name or "Unknown")
							if id ~= "" then _registerEmote(id, name) end
						end
					end
					pcall(function()
						if not isfolder("slate") then
							makefolder("slate")
						end
						writefile(cachePath, resJson.Body)
					end)
					_refreshEmoteUI()
				end
			end
		end
		local userId = localPlr.UserId
		local aes = pcall(function()
			return game:GetService("AvatarEditorService")
		end) and game:GetService("AvatarEditorService")
		if aes then
			local ok, pages = pcall(function()
				return aes:GetInventoryPages((Enum.AvatarAssetType :: any).EmoteAnimation or (Enum.AvatarAssetType :: any).Emote, 100, nil)
			end)
			if ok and pages then
				local batch = {}
				pcall(function()
					while true do
						local items = pages:GetCurrentPage()
						for _, item in ipairs(items) do
							local id = tostring(item.assetId or item.AssetId or item.id or "")
							local name = tostring(item.name or item.Name or item.assetName or "Unknown")
							if id ~= "" then
								table.insert(batch, { id = id, name = name })
							end
						end
						if pages.IsFinished then
							break
						end
						pages:AdvanceToNextPageAsync()
					end
				end)
				if #batch > 0 then
					_addEmoteBatch(batch)
				end
			end
		end
		_inventoryLoaded = true
		_refreshEmoteUI()
	end)

	local function saveEmoteState()
		pcall(function()
			if not isfolder("slate") then
				makefolder("slate")
			end
			if not isfolder("slate/emotes") then
				makefolder("slate/emotes")
			end
			writefile("slate/emotes/favs.json", httpService:JSONEncode(emoteFavorites))
			writefile("slate/emotes/binds.json", httpService:JSONEncode(emoteKeybinds))
		end)
	end
	userInputSvc.InputBegan:Connect(function(input, gpe)
		if listeningKeyBtn and listeningEmoteId then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local kc = input.KeyCode
				if kc ~= Enum.KeyCode.Unknown and kc ~= Enum.KeyCode.Escape and kc ~= Enum.KeyCode.Backspace then
					for otherId, otherKey in pairs(emoteKeybinds) do
						if otherKey == kc.Name and otherId ~= listeningEmoteId then
							emoteKeybinds[otherId] = nil
						end
					end
					emoteKeybinds[listeningEmoteId] = kc.Name
					listeningKeyBtn.Text = kc.Name:sub(1, 3)
					listeningKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					listeningKeyBtn.Visible = true
					local pBtn = listeningKeyBtn.Parent
					if pBtn and pBtn:IsA("ImageButton") then
						pBtn.Image = ""
					end
					saveEmoteState()
				elseif kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Backspace then
					emoteKeybinds[listeningEmoteId] = nil
					listeningKeyBtn.Text = ""
					listeningKeyBtn.Visible = false
					local pBtn = listeningKeyBtn.Parent
					if pBtn and pBtn:IsA("ImageButton") then
						pBtn.Image = keybindIconId
					end
					saveEmoteState()
				end
			end
			listeningKeyBtn = nil
			listeningEmoteId = nil
			return
		end
		if gpe then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local emoteGui = _G.__SlateEmoteGui
			if not (emoteGui and emoteGui.Parent and emoteGui.Enabled) then return end
			local pressedKey = input.KeyCode.Name
			for eId, keyName in pairs(emoteKeybinds) do
				if keyName == pressedKey then
					local eName = _getEmoteName(eId)
					task.spawn(function() local f = _G.__SlatePlayEmote; if f then f(eId, eName) end end)
					break
				end
			end
		end
	end)

	local function freezeChar()
		pcall(function()
			local char = localPlr.Character
			if not char then
				return
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = true
			end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and not p.Anchored then
					p.Anchored = true
				end
			end
		end)
	end

	local function unfreezeChar()
		pcall(function()
			local char = localPlr.Character
			if not char then
				return
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = false
			end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.Anchored then
					p.Anchored = false
				end
			end
		end)
	end

	local function stopAllTracks(hum)
		pcall(function()
			local animator = hum:FindFirstChildOfClass("Animator")
			if animator then
				for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
					pcall(function()
						t:Stop(0)
					end)
				end
			end
			for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
				pcall(function()
					t:Stop(0)
				end)
			end
		end)
	end

	local function resetIdle(Animate)
		if Animate and Animate:FindFirstChild("idle") then
			pcall(function()
				Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=0"
				Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=0"
			end)
		end
	end

	local function applyOnyxPackage(packageName)
		local char = localPlr.Character
		if not char then
			return
		end
		local Animate = char:FindFirstChild("Animate")
		if not Animate then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		if _G.__SlateSnapAnimate then _G.__SlateSnapAnimate(Animate) end
		freezeChar()
		task.wait(0.1)
		pcall(function()
			local base = "http://www.roblox.com/asset/?id="
			stopAllTracks(hum)
			if OriginalAnimations.Walk[packageName] == nil and OriginalAnimations.Idle[packageName] then
				local packageId = OriginalAnimations.Idle[packageName][1]
				local ok, objList = pcall(function()
					return game:GetObjects("rbxassetid://" .. packageId)
				end)
				if ok and objList and #objList > 0 and objList[1] then
					local packageModel = objList[1]
					local function applySubAnim(folderName, childName, targetFolder, targetAnimName)
						local sourceFolder = packageModel:FindFirstChild(folderName)
						if sourceFolder then
							local sourceAnim = sourceFolder:FindFirstChild(childName)
							if sourceAnim and sourceAnim:IsA("Animation") then
								local realId = sourceAnim.AnimationId:match("%d+")
								if realId and Animate:FindFirstChild(targetFolder) then
									Animate[targetFolder][targetAnimName].AnimationId = base .. realId
								end
							end
						end
					end
					local sourceIdle = packageModel:FindFirstChild("idle")
					if sourceIdle and Animate:FindFirstChild("idle") then
						resetIdle(Animate)
						local anim1 = sourceIdle:FindFirstChild("Animation1")
						if anim1 and anim1:IsA("Animation") then
							local id1 = anim1.AnimationId:match("%d+")
							if id1 then
								Animate.idle.Animation1.AnimationId = base .. id1
							end
						end
						local anim2 = sourceIdle:FindFirstChild("Animation2")
						if anim2 and anim2:IsA("Animation") then
							local id2 = anim2.AnimationId:match("%d+")
							if id2 then
								Animate.idle.Animation2.AnimationId = base .. id2
							end
						end
					end
					applySubAnim("walk", "WalkAnim", "walk", "WalkAnim")
					applySubAnim("run", "RunAnim", "run", "RunAnim")
					applySubAnim("jump", "JumpAnim", "jump", "JumpAnim")
					applySubAnim("fall", "FallAnim", "fall", "FallAnim")
					applySubAnim("swim", "Swim", "swim", "Swim")
					applySubAnim("swimidle", "SwimIdle", "swimidle", "SwimIdle")
					applySubAnim("climb", "ClimbAnim", "climb", "ClimbAnim")
				end
			else
				local idleVal = OriginalAnimations.Idle[packageName]
				if idleVal then
					resetIdle(Animate)
					if Animate:FindFirstChild("idle") then
						local real1 = resolveAnimationId(idleVal[1])
						Animate.idle.Animation1.AnimationId = base .. real1
						if idleVal[2] then
							local real2 = resolveAnimationId(idleVal[2])
							Animate.idle.Animation2.AnimationId = base .. real2
						end
					end
				end
				local function setSingle(animType, childName, animName)
					local val = OriginalAnimations[animType][packageName]
					if val and Animate:FindFirstChild(childName) then
						local realId = resolveAnimationId(val)
						Animate[childName][animName].AnimationId = base .. realId
					end
				end
				setSingle("Walk", "walk", "WalkAnim")
				setSingle("Run", "run", "RunAnim")
				setSingle("Jump", "jump", "JumpAnim")
				setSingle("Fall", "fall", "FallAnim")
				setSingle("Swim", "swim", "Swim")
				setSingle("SwimIdle", "swimidle", "SwimIdle")
				setSingle("Climb", "climb", "ClimbAnim")
			end
		end)
		task.wait(0.05)
		unfreezeChar()
		if Animate then
			Animate.Disabled = true
			task.wait(0.05)
			Animate.Disabled = false
		end
		stopAllTracks(hum)
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end

	local function refreshState(stateType)
		pcall(function()
			local char = localPlr.Character
			if not char then
				return
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then
				return
			end
			if stateType == "swim" then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				task.wait(0.1)
				hum:ChangeState(Enum.HumanoidStateType.Swimming)
			elseif stateType == "climb" then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				task.wait(0.1)
				hum:ChangeState(Enum.HumanoidStateType.Climbing)
			else
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end)
	end

	local function setAnimation(animationType, animationId, noSave)
		if type(animationId) ~= "table" and type(animationId) ~= "string" and type(animationId) ~= "number" then
			return
		end
		local char = localPlr.Character
		if not char then
			return
		end
		local Animate = char:FindFirstChild("Animate")
		if not Animate then
			return
		end
		if _G.__SlateSnapAnimate then _G.__SlateSnapAnimate(Animate) end
		freezeChar()
		task.wait(0.1)
		local success, err = pcall(function()
			local base = "http://www.roblox.com/asset/?id="
			if animationType == "Idle" then
				resetIdle(Animate)
				if type(animationId) == "table" then
					Animate.idle.Animation1.AnimationId = base .. tostring(animationId[1])
					Animate.idle.Animation2.AnimationId = base .. tostring(animationId[2] or animationId[1])
				else
					Animate.idle.Animation1.AnimationId = base .. tostring(animationId)
					Animate.idle.Animation2.AnimationId = base .. tostring(animationId)
				end
				refreshState("freefall")
			elseif animationType == "Walk" then
				if Animate:FindFirstChild("walk") then
					Animate.walk.WalkAnim.AnimationId = base .. tostring(animationId)
				end
				refreshState("freefall")
			elseif animationType == "Run" then
				if Animate:FindFirstChild("run") then
					Animate.run.RunAnim.AnimationId = base .. tostring(animationId)
				end
				refreshState("freefall")
			elseif animationType == "Jump" then
				if Animate:FindFirstChild("jump") then
					Animate.jump.JumpAnim.AnimationId = base .. tostring(animationId)
				end
				refreshState("freefall")
			elseif animationType == "Fall" then
				if Animate:FindFirstChild("fall") then
					Animate.fall.FallAnim.AnimationId = base .. tostring(animationId)
				end
				refreshState("freefall")
			elseif animationType == "Swim" then
				if Animate:FindFirstChild("swim") then
					Animate.swim.Swim.AnimationId = base .. tostring(animationId)
				end
				refreshState("swim")
			elseif animationType == "SwimIdle" then
				if Animate:FindFirstChild("swimidle") then
					Animate.swimidle.SwimIdle.AnimationId = base .. tostring(animationId)
				end
				refreshState("swim")
			elseif animationType == "Climb" then
				if Animate:FindFirstChild("climb") then
					Animate.climb.ClimbAnim.AnimationId = base .. tostring(animationId)
				end
				refreshState("climb")
			end
		end)
		if not success then
			warn("Failed to set animation:", err)
		end
		task.wait(0.1)
		unfreezeChar()
		if success and not noSave then
			pcall(function()
				_G.__SlateCustomAnims = _G.__SlateCustomAnims or {}
				_G.__SlateCustomAnims[animationType] = animationId
				if writefile then
					if not isfolder("slate") then
						makefolder("slate")
					end
					writefile("slate/customanims.json", httpService:JSONEncode(_G.__SlateCustomAnims))
				end
			end)
		end
	end
	local currentEmoteTrack, selectedEmoteId = nil, nil
	local emoteSpeed = 1.0
	local nowPlayingLbl = nil
	local emoteCharacter = nil
	local emoteAnimate = nil
	local emoteStateConnection = nil
	local emoteMoveConnection = nil

	local function restoreEmoteCharacter(char, animate)
		char = char or emoteCharacter
		animate = animate or emoteAnimate
		if animate and animate.Parent and animate:IsA("LocalScript") then
			pcall(function()
				animate.Disabled = false
			end)
		end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			pcall(function()
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
		if char == emoteCharacter then
			emoteCharacter = nil
			emoteAnimate = nil
		end
	end

	local function disconnectEmoteSignals()
		if emoteStateConnection then
			emoteStateConnection:Disconnect()
			emoteStateConnection = nil
		end
		if emoteMoveConnection then
			emoteMoveConnection:Disconnect()
			emoteMoveConnection = nil
		end
	end

	local function stopEmote()
		local char, animate = emoteCharacter, emoteAnimate
		disconnectEmoteSignals()
		if currentEmoteTrack then
			pcall(function()
				currentEmoteTrack:Stop(0)
			end)
			currentEmoteTrack = nil
		end
		selectedEmoteId = nil
		if nowPlayingLbl then
			nowPlayingLbl.Text = "No emote playing"
		end
		if not char then
			local onyx = _G.onyxAPI
			local isReanim = false
			if onyx and onyx.is_reanimated then
				local ok, res = pcall(onyx.is_reanimated)
				isReanim = ok and (res == true)
			end
			local cloneChar = isReanim and onyx.get_clone and onyx.get_clone(localPlr)
			char = (cloneChar and cloneChar:FindFirstChildOfClass("Humanoid") and cloneChar) or localPlr.Character
		end
		if not char then
			return
		end
		restoreEmoteCharacter(char, animate or char:FindFirstChild("Animate"))
	end

	local function playEmote(emoteId, emoteName)
		local idStr = tostring(emoteId):gsub("%.0$", "")
		if selectedEmoteId and tostring(selectedEmoteId):gsub("%.0$", "") == idStr then
			stopEmote()
			return
		end
		if currentEmoteTrack then
			disconnectEmoteSignals()
			pcall(function()
				currentEmoteTrack:Stop(0)
			end)
			currentEmoteTrack = nil
		end

		if emoteCharacter then
			restoreEmoteCharacter()
		end
		selectedEmoteId = emoteId
		if nowPlayingLbl then
			nowPlayingLbl.Text = tostring(emoteName)
		end
		task.spawn(function()
			local g = (getgenv and getgenv()) or _G
			local reanimDummy = (g and (g.AKReanimDummy or g.ReanimDummy or g.ReanimCharacter))
				or workspace:FindFirstChild(localPlr.Name .. "_Reanim")
				or workspace:FindFirstChild(localPlr.Name .. "_Dummy")
				or workspace:FindFirstChild("AKReanim_Dummy")
				or workspace:FindFirstChild("Reanim")

			local onyx = _G.onyxAPI
			local isReanim = false
			if onyx and onyx.is_reanimated then
				local ok, res = pcall(onyx.is_reanimated)
				isReanim = ok and (res == true)
			end
			local cloneChar = isReanim and onyx.get_clone and onyx.get_clone(localPlr)

			local char = (cloneChar and cloneChar:FindFirstChildOfClass("Humanoid") and cloneChar)
				or (reanimDummy and reanimDummy:FindFirstChildOfClass("Humanoid") and reanimDummy)
				or localPlr.Character
			if not char then
				return
			end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then
				return
			end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				pcall(function()
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
				end)
			end
			local animate = char:FindFirstChild("Animate")
			emoteCharacter = char
			emoteAnimate = animate
			if animate then
				pcall(function()
					animate.Disabled = true
				end)
			end
			task.wait(0.05)
			local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
			if not animator then
				restoreEmoteCharacter(char, animate)
				selectedEmoteId = nil
				if nowPlayingLbl then
					nowPlayingLbl.Text = "No emote playing"
				end
				return
			end
			for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function()
					t:Stop(0)
				end)
			end
			if tostring(selectedEmoteId):gsub("%.0$", "") ~= idStr then
				return
			end
			local anim
			local realId, animObj = resolveAnimationId(idStr)
			if animObj then
				anim = animObj
				pcall(function()
					anim.Parent = workspace
				end)
			else
				anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. realId
			end
			local loadOk, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			pcall(function()
				if anim and anim.Parent == workspace then
					anim:Destroy()
				end
			end)
			if not loadOk or not track then
				restoreEmoteCharacter(char, animate)
				selectedEmoteId = nil
				if nowPlayingLbl then
					nowPlayingLbl.Text = "Failed to load emote"
				end
				return
			end
			if tostring(selectedEmoteId):gsub("%.0$", "") ~= idStr then
				pcall(function()
					track:Stop(0)
				end)
				restoreEmoteCharacter(char, animate)
				return
			end
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = true
			track:Play(0, 1, emoteSpeed)
			currentEmoteTrack = track
			emoteMoveConnection = hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
				if currentEmoteTrack == track and hum.MoveDirection.Magnitude > 0.1 then
					stopEmote()
				end
			end)
			emoteStateConnection = hum.StateChanged:Connect(function(_, state)
				if
					currentEmoteTrack == track
					and (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall)
				then
					stopEmote()
				end
			end)
			track.Stopped:Connect(function()
				if currentEmoteTrack ~= track then return end
				disconnectEmoteSignals()
				if currentEmoteTrack == track then
					currentEmoteTrack = nil
					selectedEmoteId = nil
					if nowPlayingLbl then
						nowPlayingLbl.Text = "No emote playing"
					end
					restoreEmoteCharacter(char, animate)
				end
			end)
		end)
	end

	_G.__SlatePlayEmote = playEmote

	local WIN_W = 310
	local WIN_H = 460
	local SLATE_LOGO_ASSET = 106573940007070
	local BG_DECAL_ASSET   = 120796464700913
	local favIconId    = _G._HaloIconStarOff or "rbxthumb://type=Asset&id=108960170332502&w=150&h=150"
	local unfavIconId  = _G._HaloIconStar    or "rbxthumb://type=Asset&id=105536176972318&w=150&h=150"
	local keybindIconId = _G._HaloIconKeyboard or "rbxthumb://type=Asset&id=124657808272985&w=150&h=150"

	local function pad(top, right, bottom, left)
		local p = Instance.new("UIPadding")
		p.PaddingTop = UDim.new(0, top or 0)
		p.PaddingRight = UDim.new(0, right or top or 0)
		p.PaddingBottom = UDim.new(0, bottom or top or 0)
		p.PaddingLeft = UDim.new(0, left or right or top or 0)
		return p
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "SlateEmoteAnimGUI"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Enabled = (SHOW_UI_ON_EXECUTE == true)
	sg.Parent = panelHost
	_G.__SlateEmoteGui = sg

	local root = Instance.new("CanvasGroup")
	root.Name = "SlateEmoteWindow"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.5, 0, 0.5, -WIN_H / 2)
	root.Size = UDim2.fromOffset(WIN_W, WIN_H)
	root.BackgroundColor3 = C.bg
	root.BackgroundTransparency = 0
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.ZIndex = 2
	root.Parent = sg
	cr(18, root)

	local rootShadow = createGlow(root, Color3.fromRGB(0, 0, 0), 28, 0.4)
	local rootStroke = stk(1, T.lineHi, root)
	rootStroke.Transparency = 0.4
	rootStroke.Enabled = false

	local bgImage = Instance.new("ImageLabel")
	bgImage.Name = "BackgroundImage"
	bgImage.AnchorPoint = Vector2.new(0.5, 0.5)
	bgImage.Position = UDim2.fromScale(0.5, 0.5)
	bgImage.Size = UDim2.new(1, 80, 1, 70)
	bgImage.BackgroundTransparency = 1
	bgImage.Image = "rbxthumb://type=Asset&id=" .. BG_DECAL_ASSET .. "&w=768&h=432"
	bgImage.ScaleType = Enum.ScaleType.Crop
	bgImage.ImageTransparency = 1
	bgImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
	bgImage.ZIndex = 0
	bgImage.Parent = root
	cr(18, bgImage)

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.BackgroundColor3 = T.surface
	topBar.BackgroundTransparency = 1
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 10
	topBar.Parent = root
	cr(18, topBar)
	local topBarPad = pad(0, 10, 0, 10)
	topBarPad.Parent = topBar

	local brand = Instance.new("Frame")
	brand.AnchorPoint = Vector2.new(0, 0.5)
	brand.Position = UDim2.new(0, 0, 0.5, 0)
	brand.Size = UDim2.new(0, 160, 0, 32)
	brand.BackgroundTransparency = 1
	brand.Parent = topBar

	local brandLayout = Instance.new("UIListLayout")
	brandLayout.FillDirection = Enum.FillDirection.Horizontal
	brandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	brandLayout.Padding = UDim.new(0, 8)
	brandLayout.Parent = brand

	local brandLogo = Instance.new("ImageLabel")
	brandLogo.Size = UDim2.fromOffset(22, 22)
	brandLogo.BackgroundTransparency = 1
	brandLogo.Image = "rbxthumb://type=Asset&id=" .. SLATE_LOGO_ASSET .. "&w=420&h=420"
	brandLogo.ScaleType = Enum.ScaleType.Fit
	brandLogo.ImageColor3 = C.accent
	brandLogo.Parent = brand

	local brandTitle = Instance.new("TextLabel")
	brandTitle.AutomaticSize = Enum.AutomaticSize.X
	brandTitle.Size = UDim2.new(0, 0, 1, 0)
	brandTitle.BackgroundTransparency = 1
	brandTitle.Text = "Emotes"
	brandTitle.Font = Enum.Font.BuilderSansBold
	brandTitle.TextSize = 15
	brandTitle.TextColor3 = C.text
	brandTitle.ZIndex = 11
	brandTitle.Parent = brand
	brandLogo.ZIndex = 11

	local topRight = Instance.new("Frame")
	topRight.AnchorPoint = Vector2.new(1, 0.5)
	topRight.Position = UDim2.new(1, 0, 0.5, 0)
	topRight.Size = UDim2.fromOffset(60, 26)
	topRight.BackgroundTransparency = 1
	topRight.ZIndex = 15
	topRight.Parent = topBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(24, 24)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.BuilderSansMedium
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = T.text2
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 16
	closeBtn.Parent = topRight

	closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = T.text1 end)
	closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = T.text2 end)
	local emoteAnimScale = Instance.new("UIScale")
	emoteAnimScale.Parent = root
	sg:GetPropertyChangedSignal("Enabled"):Connect(function()
		local anim = _G.SlateWindowAnim
		if anim and sg.Enabled and not root:GetAttribute("SlateClosing") then
			anim.open(root, emoteAnimScale)
		end
	end)
	local function emoteHide() sg.Enabled = false end
	_G.__SlateEmoteAnimClose = function()
		local anim = _G.SlateWindowAnim
		if anim then anim.close(root, emoteAnimScale, emoteHide) else emoteHide() end
	end
	closeBtn.MouseButton1Click:Connect(function() _G.__SlateEmoteAnimClose() end)
	_G.SlateHeaderCtl(closeBtn, "x", 11)

	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Name = "MinimizeBtn"
	minimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
	minimizeBtn.Position = UDim2.new(1, -26, 0.5, 0)
	minimizeBtn.Size = UDim2.fromOffset(24, 24)
	minimizeBtn.BackgroundTransparency = 1
	minimizeBtn.Text = "–"
	minimizeBtn.Font = Enum.Font.BuilderSansMedium
	minimizeBtn.TextSize = 18
	minimizeBtn.TextColor3 = T.text2
	minimizeBtn.AutoButtonColor = false
	minimizeBtn.ZIndex = 16
	minimizeBtn.Parent = topRight
	_G.SlateHeaderCtl(minimizeBtn, "minus", 12)

	minimizeBtn.MouseEnter:Connect(function() minimizeBtn.TextColor3 = T.text1 end)
	minimizeBtn.MouseLeave:Connect(function() minimizeBtn.TextColor3 = T.text2 end)

	local navBar = Instance.new("Frame")
	navBar.Name = "NavBar"
	navBar.Position = UDim2.fromOffset(8, 54)
	navBar.Size = UDim2.new(1, -16, 0, 30)
	navBar.BackgroundTransparency = 1
	navBar.ZIndex = 30
	navBar.Parent = root

	local tabsHolder = Instance.new("ScrollingFrame")
	tabsHolder.Name = "TabsHolder"
	tabsHolder.Size = UDim2.new(1, 0, 1, 0)
	tabsHolder.BackgroundTransparency = 1
	tabsHolder.BorderSizePixel = 0
	tabsHolder.ZIndex = 31
	tabsHolder.ScrollBarThickness = 0
	tabsHolder.ScrollingDirection = Enum.ScrollingDirection.X
	tabsHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabsHolder.Parent = navBar
	local tabsHolderPad = pad(0, 2, 0, 2)
	tabsHolderPad.Parent = tabsHolder

	local tabRow = Instance.new("Frame")
	tabRow.Size = UDim2.new(0, 0, 1, 0)
	tabRow.AutomaticSize = Enum.AutomaticSize.X
	tabRow.BackgroundTransparency = 1
	tabRow.ZIndex = 31
	tabRow.Parent = tabsHolder

	local tabRowLayout = Instance.new("UIListLayout")
	tabRowLayout.FillDirection = Enum.FillDirection.Horizontal
	tabRowLayout.Padding = UDim.new(0, 4)
	tabRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabRowLayout.Parent = tabRow

	local dragHandle = Instance.new("TextButton")
	dragHandle.Name = "TopBarDragHandle"
	dragHandle.Size = UDim2.new(1, -65, 1, 0)
	dragHandle.BackgroundTransparency = 1
	dragHandle.Text = ""
	dragHandle.AutoButtonColor = false
	dragHandle.ZIndex = 12
	dragHandle.Parent = topBar

	do
		local isDragging = false
		local dragStartPos = Vector2.zero
		local dragWindowStart = root.Position
		local targetWindowPos = root.Position

		dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				dragStartPos = input.Position
				dragWindowStart = root.Position
				targetWindowPos = root.Position
			end
		end)

		userInputSvc.InputChanged:Connect(function(input)
			if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStartPos
				targetWindowPos = _G.SlateClampPos(root, UDim2.new(
					dragWindowStart.X.Scale, dragWindowStart.X.Offset + delta.X,
					dragWindowStart.Y.Scale, dragWindowStart.Y.Offset + delta.Y
				))
			end
		end)

		userInputSvc.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = false
			end
		end)

		runService.RenderStepped:Connect(function(dt)
			LPS_ATTRIBUTES(VM(NONE))
			if not root.Visible then return end
			local extTarget = dragHandle:GetAttribute("TargetPos")
			if extTarget and not isDragging then
				dragHandle:SetAttribute("TargetPos", nil)
				targetWindowPos = extTarget
			end
			local posChanged = isDragging
				or math.abs(root.Position.X.Offset - targetWindowPos.X.Offset) > 0.4
				or math.abs(root.Position.Y.Offset - targetWindowPos.Y.Offset) > 0.4
			if not posChanged then return end
			local lerpFactor = math.clamp(dt * 22, 0.05, 0.95)
			local newX = root.Position.X.Offset + (targetWindowPos.X.Offset - root.Position.X.Offset) * lerpFactor
			local newY = root.Position.Y.Offset + (targetWindowPos.Y.Offset - root.Position.Y.Offset) * lerpFactor
			root.Position = UDim2.new(targetWindowPos.X.Scale, newX, targetWindowPos.Y.Scale, newY)
		end)
	end

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Position = UDim2.fromOffset(8, 92)
	body.Size = UDim2.new(1, -16, 1, -104)
	body.BackgroundTransparency = 1
	body.ClipsDescendants = false
	body.ZIndex = 5
	body.Parent = root
	pad(0, 2, 0, 2).Parent = body

	do
		local cam = workspace.CurrentCamera
		if cam then
			local vp = cam.ViewportSize
			local sc = math.min(1, (vp.X - 16) / WIN_W, (vp.Y - 40) / WIN_H)
			if sc < 1 and sc > 0.3 then
				local us = Instance.new("UIScale")
				us.Scale = sc
				us.Parent = root
			end
		end
	end

	local isMinimized = false
	local function applyMinimized(min, animate)
		isMinimized = min
		root:SetAttribute("SlateMinimized", min)
		local SPRING_FAST = animate ~= false and TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) or TweenInfo.new(0)
		if isMinimized then
			body.Visible = false
			navBar.Visible = false
			bgImage.Visible = false
			if animate ~= false then
				tweenService:Create(root, SPRING_FAST, { Size = UDim2.fromOffset(WIN_W, 50) }):Play()
				if rootShadow and rootShadow:IsA("GuiObject") then
					tweenService:Create(rootShadow, SPRING_FAST, { Size = UDim2.fromOffset(WIN_W + 52, 50 + 52) }):Play()
				end
			else
				root.Size = UDim2.fromOffset(WIN_W, 50)
				if rootShadow and rootShadow:IsA("GuiObject") then rootShadow.Size = UDim2.fromOffset(WIN_W + 52, 50 + 52) end
			end
			_G.SlateHeaderCtl(minimizeBtn, "plus", 12)
		else
			body.Visible = true
			navBar.Visible = true
			bgImage.Visible = true
			if animate ~= false then
				tweenService:Create(root, SPRING_FAST, { Size = UDim2.fromOffset(WIN_W, WIN_H) }):Play()
				if rootShadow and rootShadow:IsA("GuiObject") then
					tweenService:Create(rootShadow, SPRING_FAST, { Size = UDim2.fromOffset(WIN_W + 52, WIN_H + 52) }):Play()
				end
			else
				root.Size = UDim2.fromOffset(WIN_W, WIN_H)
				if rootShadow and rootShadow:IsA("GuiObject") then rootShadow.Size = UDim2.fromOffset(WIN_W + 52, WIN_H + 52) end
			end
			_G.SlateHeaderCtl(minimizeBtn, "minus", 12)
		end
	end
	minimizeBtn.MouseButton1Click:Connect(function()
		applyMinimized(not isMinimized, true)
	end)

	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, 0, 0, 36)
	statusBar.Position = UDim2.fromOffset(0, 0)
	statusBar.BackgroundColor3 = T.surface2
	statusBar.BackgroundTransparency = 0.35
	statusBar.BorderSizePixel = 0
	statusBar.ZIndex = 6
	statusBar.Parent = body
	cr(9, statusBar)
	local statusBarStroke = stk(1, T.line, statusBar)
	statusBarStroke.Transparency = 0.4
	local statusBarPad = pad(0, 10, 0, 12)
	statusBarPad.Parent = statusBar

	nowPlayingLbl = Instance.new("TextLabel")
	nowPlayingLbl.Name = "PlayingLabel"
	nowPlayingLbl.Size = UDim2.new(1, -75, 1, 0)
	nowPlayingLbl.BackgroundTransparency = 1
	nowPlayingLbl.Text = "Playing: None"
	nowPlayingLbl.TextColor3 = T.text2
	nowPlayingLbl.TextSize = 11
	nowPlayingLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nowPlayingLbl.TextXAlignment = Enum.TextXAlignment.Left
	nowPlayingLbl.Font = Enum.Font.BuilderSansMedium
	nowPlayingLbl.ZIndex = 7
	nowPlayingLbl.Parent = statusBar

	local stopBtn = Instance.new("TextButton")
	stopBtn.Name = "StopBtn"
	stopBtn.AnchorPoint = Vector2.new(1, 0.5)
	stopBtn.Position = UDim2.new(1, 0, 0.5, 0)
	stopBtn.Size = UDim2.fromOffset(60, 24)
	stopBtn.BackgroundColor3 = Color3.fromRGB(38, 20, 24)
	stopBtn.BorderSizePixel = 0
	stopBtn.AutoButtonColor = false
	stopBtn.Text = "STOP"
	stopBtn.TextColor3 = T.danger
	stopBtn.TextSize = 9.5
	stopBtn.Font = Enum.Font.BuilderSansBold
	stopBtn.ZIndex = 7
	stopBtn.Parent = statusBar
	cr(6, stopBtn)
	local stopBtnStroke = stk(1, T.danger, stopBtn)
	stopBtnStroke.Transparency = 0.6
	stopBtn.MouseButton1Click:Connect(stopEmote)

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.PlaceholderText = "Search animations & emotes..."
	searchBox.PlaceholderColor3 = T.text3
	searchBox.Size = UDim2.new(1, 0, 0, 32)
	searchBox.Position = UDim2.fromOffset(0, 42)
	searchBox.BackgroundColor3 = T.surface2
	searchBox.BackgroundTransparency = 0.35
	searchBox.TextColor3 = T.text1
	searchBox.ClearTextOnFocus = false
	searchBox.TextSize = 11
	searchBox.Text = ""
	searchBox.Font = Enum.Font.BuilderSansMedium
	searchBox.BorderSizePixel = 0
	searchBox.ZIndex = 6
	searchBox.Parent = body
	cr(9, searchBox)
	local searchBoxPad = pad(0, 12, 0, 12)
	searchBoxPad.Parent = searchBox
	local searchBoxStroke = stk(1, T.line, searchBox)
	searchBoxStroke.Transparency = 0.4

	local scrollContainer = Instance.new("ScrollingFrame")
	scrollContainer.Name = "AnimationsScroll"
	scrollContainer.Size = UDim2.new(1, 0, 1, -122)
	scrollContainer.ClipsDescendants = true
	scrollContainer.Position = UDim2.fromOffset(0, 80)
	scrollContainer.BackgroundTransparency = 1
	scrollContainer.BorderSizePixel = 0
	scrollContainer.ScrollBarThickness = 0
	scrollContainer.ScrollBarImageColor3 = T.lineHi
	scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollContainer.ZIndex = 6
	scrollContainer.Parent = body
	local scrollContainerPad = pad(2, 3, 12, 3)
	scrollContainerPad.Parent = scrollContainer

	local function makeListFade(isTop)
		LPS_ATTRIBUTES(VM(NONE))
		local f = Instance.new("Frame")
		f.Name = isTop and "ListFadeTop" or "ListFadeBottom"
		f.AnchorPoint = Vector2.new(0, isTop and 0 or 1)
		f.Position = isTop and UDim2.fromOffset(0, 80) or UDim2.new(0, 0, 1, -42)
		f.Size = UDim2.new(1, 0, 0, 22)
		f.BackgroundColor3 = C.bg
		f.BorderSizePixel = 0
		f.Active = false
		f.ZIndex = 7
		f.Parent = body
		local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 10); fc.Parent = f
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, isTop and 0.2 or 1),
			NumberSequenceKeypoint.new(1, isTop and 1 or 0.2),
		})
		g.Parent = f
	end

	do
		local ef = Instance.new("Frame")
		ef.Name = "ListFadeBottom"
		ef.AnchorPoint = Vector2.new(0, 1)
		ef.Position = UDim2.new(0, 0, 1, -42)
		ef.Size = UDim2.new(1, 0, 0, 22)
		ef.BackgroundColor3 = C.bg
		ef.BorderSizePixel = 0
		ef.Active = false
		ef.ZIndex = 7
		ef.Parent = body
		local eg = Instance.new("UIGradient")
		eg.Rotation = 90
		eg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.2),
		})
		eg.Parent = ef
	end

	local spdBar = Instance.new("Frame")
	spdBar.Name = "SpeedBar"
	spdBar.Size = UDim2.new(1, 0, 0, 34)
	spdBar.Position = UDim2.new(0, 0, 1, -36)
	spdBar.BackgroundColor3 = T.surface2
	spdBar.BackgroundTransparency = 0.35
	spdBar.BorderSizePixel = 0
	spdBar.ZIndex = 7
	spdBar.Parent = body
	cr(8, spdBar)
	local spdBarStroke = stk(1, T.line, spdBar)
	spdBarStroke.Transparency = 0.45

	local spdLbl = Instance.new("TextLabel")
	spdLbl.Size = UDim2.new(0, 82, 1, 0)
	spdLbl.Position = UDim2.new(0, 12, 0, 0)
	spdLbl.BackgroundTransparency = 1
	spdLbl.Text = "Speed: 1.0x"
	spdLbl.TextColor3 = T.text2
	spdLbl.TextSize = 10.5
	spdLbl.Font = Enum.Font.BuilderSansBold
	spdLbl.TextXAlignment = Enum.TextXAlignment.Left
	spdLbl.ZIndex = 8
	spdLbl.Parent = spdBar

	local sTrack = Instance.new("Frame")
	sTrack.Size = UDim2.new(1, -104, 0, 12)
	sTrack.Position = UDim2.new(0, 94, 0.5, -6)
	sTrack.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	sTrack.BorderSizePixel = 0
	sTrack.ZIndex = 8
	sTrack.Parent = spdBar
	cr(6, sTrack)
	local sTrackStk = stk(1, Color3.fromRGB(255, 255, 255), sTrack)
	sTrackStk.Transparency = 0.85

	local defaultRel = math.clamp((1.0 - 0.1) / (3.0 - 0.1), 0, 1)
	local sHandleRest = Vector2.new(35, 18)
	local sHandleHeld = Vector2.new(41, 20)
	local currentHandleWidth = sHandleRest.X
	local handleOffset = (1 - 2 * defaultRel) * (currentHandleWidth / 2 - 2)

	local sFill = Instance.new("Frame")
	sFill.Size = UDim2.new(defaultRel, handleOffset, 1, 0)
	sFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sFill.BorderSizePixel = 0
	sFill.ZIndex = 8
	sFill.Parent = sTrack
	cr(6, sFill)
	local sFillGrad = Instance.new("UIGradient")
	sFillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 195, 210)),
	})
	sFillGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.85),
		NumberSequenceKeypoint.new(1, 0),
	})
	sFillGrad.Offset = Vector2.new(0, 0.5)
	sFillGrad.Rotation = 2
	sFillGrad.Parent = sFill

	local sHandle = Instance.new("Frame")
	sHandle.Name = "Handle"
	sHandle.AnchorPoint = Vector2.new(0.5, 0.5)
	sHandle.Position = UDim2.new(defaultRel, handleOffset, 0.5, 0)
	sHandle.Size = UDim2.fromOffset(sHandleRest.X, sHandleRest.Y)
	sHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sHandle.BorderSizePixel = 0
	sHandle.ZIndex = 9
	sHandle.Parent = sTrack
	cr(9, sHandle)
	local sHandleStroke = stk(1, Color3.fromRGB(255, 255, 255), sHandle)
	sHandleStroke.Transparency = 1
	createGlow(sHandle, Color3.fromRGB(255, 255, 255), 10, 0.55)

	local sHit = Instance.new("TextButton")
	sHit.BackgroundTransparency = 1
	sHit.Text = ""
	sHit.Position = UDim2.new(0, -6, 0, -8)
	sHit.Size = UDim2.new(1, 12, 1, 16)
	sHit.ZIndex = 10
	sHit.Parent = sTrack

	do
		local dragging = false
		local dragConn = nil
		local targetRatio = defaultRel
		local visualRatio = defaultRel

		local function renderProgress(ratio, info)
			LPS_ATTRIBUTES(VM(NONE))
			ratio = math.clamp(ratio, 0, 1)
			local hOffset = (1 - 2 * ratio) * (currentHandleWidth / 2 - 2)
			local hPos = UDim2.new(ratio, hOffset, 0.5, 0)
			local fSize = UDim2.new(ratio, hOffset, 1, 0)
			if info then
				tweenService:Create(sFill, info, { Size = fSize }):Play()
				tweenService:Create(sHandle, info, { Position = hPos }):Play()
			else
				sFill.Size = fSize
				sHandle.Position = hPos
			end
		end

		local function updateFromPointer(pointerX)
			local trackX = sTrack.AbsolutePosition.X
			local trackW = sTrack.AbsoluteSize.X
			if trackW <= 0 then return end
			local ratio = math.clamp((pointerX - trackX) / trackW, 0, 1)
			targetRatio = ratio
			local rawSpd = 0.1 + ratio * 2.9
			local snapped = math.floor(rawSpd * 10 + 0.5) / 10
			snapped = math.clamp(snapped, 0.1, 3.0)
			emoteSpeed = snapped
			spdLbl.Text = string.format("Speed: %.1fx", emoteSpeed)
			if currentEmoteTrack then
				pcall(function() currentEmoteTrack:AdjustSpeed(emoteSpeed) end)
			end
		end

		local function setHeld(held)
			local target = held and sHandleHeld or sHandleRest
			currentHandleWidth = target.X
			local ti = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			tweenService:Create(sHandle, ti, {
				Size = UDim2.fromOffset(target.X, target.Y),
				BackgroundTransparency = held and 0.45 or 0,
			}):Play()
			tweenService:Create(sHandleStroke, ti, {
				Transparency = held and 0.4 or 1,
			}):Play()
		end

		local function endDrag()
			if not dragging then return end
			dragging = false
			local exactRatio = math.clamp((emoteSpeed - 0.1) / 2.9, 0, 1)
			targetRatio = exactRatio
			visualRatio = exactRatio
			renderProgress(exactRatio, nil)
			setHeld(false)
			if dragConn then
				dragConn:Disconnect()
				dragConn = nil
			end
		end

		sHit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				setHeld(true)
				updateFromPointer(input.Position.X)
				if dragConn then dragConn:Disconnect() end
				dragConn = runService.RenderStepped:Connect(function(dt)
					LPS_ATTRIBUTES(VM(NONE))
					if not dragging then
						if dragConn then dragConn:Disconnect(); dragConn = nil end
						return
					end
					local mousePos = userInputSvc:GetMouseLocation()
					updateFromPointer(mousePos.X)
					dt = math.min(0.08, dt)
					local alpha = 1 - math.exp(-dt * 22)
					visualRatio = visualRatio + (targetRatio - visualRatio) * alpha
					if math.abs(targetRatio - visualRatio) < 0.0004 then visualRatio = targetRatio end
					renderProgress(visualRatio, nil)
				end)
			end
		end)

		userInputSvc.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				endDrag()
			end
		end)
	end

	local tabBtns = {}
	local emotePages = {}
	local currentActiveTab = "Emotes"
	local tabConfigs = {
		{ id = "Emotes",    label = "Emotes",    w = 78 },
		{ id = "Favorites", label = "Favorites", w = 84 },
		{ id = "Packs",     label = "Packs",     w = 46 },
		{ id = "Custom",    label = "Custom",    w = 52 },
	}

	local function updateTabCounts()
		local favCount = 0
		for key, val in pairs(emoteFavorites) do
			if val then favCount = favCount + 1 end
		end
		local totalEmotes = _G._rawCatalogTotalItems or (_rawCatalog and #_rawCatalog) or #EMOTES
		for _, tb in ipairs(tabBtns) do
			local tid = tb:GetAttribute("tn")
			if tid == "Emotes" then
				tb.Text = "Emotes"
			elseif tid == "Favorites" then
				tb.Text = "Favorites"
			end
		end
	end

	local function createCategoryBtn(tabName, text, widthPx, layoutOrder)
		LPS_ATTRIBUTES(VM(NONE))
		local isFirst = (layoutOrder == 1)
		local btn = Instance.new("TextButton")
		btn.Name = tabName
		btn.Size = UDim2.new(0, widthPx, 1, -4)
		btn.BackgroundColor3 = isFirst and T.surface3 or T.surface
		btn.BackgroundTransparency = isFirst and 0 or 0.2
		btn.Text = text
		btn.Font = Enum.Font.BuilderSansMedium
		btn.TextSize = 10
		btn.ZIndex = 32
		btn.TextColor3 = isFirst and T.text1 or T.text2
		btn.AutoButtonColor = false
		btn.BorderSizePixel = 0
		btn.LayoutOrder = layoutOrder
		btn.Parent = tabRow
		btn:SetAttribute("tn", tabName)
		cr(13, btn)
		local btnStroke = stk(1, isFirst and Color3.fromRGB(255, 255, 255) or T.line, btn)
		btnStroke.Transparency = isFirst and 0.75 or 0.45

		btn.MouseEnter:Connect(function()
			if currentActiveTab ~= tabName then
				tweenService:Create(btn, TweenInfo.new(0.18), { TextColor3 = T.text1, BackgroundTransparency = 0.2 }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if currentActiveTab ~= tabName then
				tweenService:Create(btn, TweenInfo.new(0.18), { TextColor3 = T.text3, BackgroundTransparency = 0.45 }):Play()
			end
		end)

		table.insert(tabBtns, btn)
		return btn
	end

	for idx, tc in ipairs(tabConfigs) do
		createCategoryBtn(tc.id, tc.label, tc.w, idx)
	end

	local function renderEmoteRow(container, em, idx, onStateChanged)
		LPS_ATTRIBUTES(VM(NONE))
		local sId = tostring(em.id)
		_registerEmote(sId, em.name)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.LayoutOrder = idx
		row.BackgroundColor3 = T.surface2
		row.BackgroundTransparency = 0.35
		row.BorderSizePixel = 0
		row.Parent = container
		cr(8, row)
		local rowStroke = stk(1, T.line, row)
		rowStroke.Transparency = 0.45

		local rowPad = pad(0, 10, 0, 12)
		rowPad.Parent = row

		local playBtn = Instance.new("TextButton")
		playBtn.Size = UDim2.new(1, -80, 1, 0)
		playBtn.Position = UDim2.new(0, 0, 0, 0)
		playBtn.BackgroundTransparency = 1
		playBtn.Text = em.name
		playBtn.TextColor3 = T.text1
		playBtn.TextSize = 11
		playBtn.Font = Enum.Font.BuilderSansMedium
		playBtn.TextXAlignment = Enum.TextXAlignment.Left
		playBtn.TextTruncate = Enum.TextTruncate.AtEnd
		playBtn.ClipsDescendants = true
		playBtn.ZIndex = 2
		playBtn.Parent = row

		playBtn.MouseEnter:Connect(function()
			tweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = T.surface3, BackgroundTransparency = 0.15 }):Play()
		end)
		playBtn.MouseLeave:Connect(function()
			tweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = T.surface2, BackgroundTransparency = 0.35 }):Play()
		end)
		playBtn.MouseButton1Click:Connect(function()
			playEmote(em.id, em.name)
		end)

		local favBtn = Instance.new("ImageButton")
		favBtn.Size = UDim2.fromOffset(16, 16)
		favBtn.AnchorPoint = Vector2.new(1, 0.5)
		favBtn.Position = UDim2.new(1, -48, 0.5, 0)
		favBtn.BackgroundTransparency = 1
		favBtn.ScaleType = Enum.ScaleType.Fit
		favBtn.ZIndex = 3
		favBtn.Parent = row

		local isFav = emoteFavorites[sId] == true
		favBtn.Image = isFav and unfavIconId or favIconId

		favBtn.MouseButton1Click:Connect(function()
			if emoteFavorites[sId] then
				emoteFavorites[sId] = nil
				favBtn.Image = favIconId
			else
				emoteFavorites[sId] = true
				favBtn.Image = unfavIconId
			end
			saveEmoteState()
			updateTabCounts()
			if onStateChanged then onStateChanged() end
		end)

		local bindBtn = Instance.new("ImageButton")
		bindBtn.Size = UDim2.fromOffset(36, 22)
		bindBtn.AnchorPoint = Vector2.new(1, 0.5)
		bindBtn.Position = UDim2.new(1, 0, 0.5, 0)
		bindBtn.BackgroundColor3 = T.surface3
		bindBtn.ScaleType = Enum.ScaleType.Fit
		bindBtn.BorderSizePixel = 0
		bindBtn.AutoButtonColor = false
		bindBtn.ZIndex = 3
		bindBtn.Parent = row
		cr(5, bindBtn)
		local bindStroke = stk(1, T.line, bindBtn)
		bindStroke.Transparency = 0.5

		local bindTxt = Instance.new("TextLabel")
		bindTxt.Size = UDim2.fromScale(1, 1)
		bindTxt.BackgroundTransparency = 1
		bindTxt.TextColor3 = T.text1
		bindTxt.TextSize = 8.5
		bindTxt.Font = Enum.Font.BuilderSansBold
		bindTxt.Visible = false
		bindTxt.ZIndex = 4
		bindTxt.Parent = bindBtn

		local function updateEmoteBindDisplay()
			local currentBind = emoteKeybinds[sId]
			if currentBind then
				bindBtn.Image = ""
				bindTxt.Text = currentBind:sub(1, 3)
				bindTxt.Visible = true
			else
				bindBtn.Image = keybindIconId
				bindTxt.Visible = false
			end
		end
		updateEmoteBindDisplay()

		bindBtn.MouseButton1Click:Connect(function()
			if emoteKeybinds[sId] then
				emoteKeybinds[sId] = nil
				saveEmoteState()
				updateEmoteBindDisplay()
				if listeningEmoteId == sId then
					listeningEmoteId = nil
					listeningKeyBtn = nil
				end
			else
				listeningEmoteId = sId
				listeningKeyBtn = bindTxt
				bindBtn.Image = ""
				bindTxt.Text = "..."
				bindTxt.TextColor3 = Color3.fromRGB(255, 200, 50)
				bindTxt.Visible = true
			end
		end)
	end

	local buildFavsList
	do
		local p = Instance.new("Frame", scrollContainer)
		p.Size = UDim2.new(1, 0, 0, 0)
		p.AutomaticSize = Enum.AutomaticSize.Y
		p.BackgroundTransparency = 1
		p.Visible = true
		emotePages["Emotes"] = p
		local listL = Instance.new("UIListLayout", p)
		listL.Padding = UDim.new(0, 6)
		listL.SortOrder = Enum.SortOrder.LayoutOrder

		local loadedIndex = 0
		local filteredSource = {}

		local function prepareSource(filter)
			filteredSource = {}
			filter = filter:lower()
			if _rawCatalog and type(_rawCatalog) == "table" then
				for idx, item in ipairs(_rawCatalog) do
					if type(item) == "table" then
						local id = tostring(item.id or item.idStr or item.assetId or item.AssetId or "")
						local name = tostring(item.name or item.Name or "Unknown")
						if id ~= "" and tonumber(id) then
							_registerEmote(id, name)
							if filter == "" or name:lower():find(filter, 1, true) then
								table.insert(filteredSource, { id = id, name = name })
							end
						end
					end
				end
			else
				for _, em in ipairs(EMOTES) do
					_registerEmote(em.id, em.name)
					if filter == "" or em.name:lower():find(filter, 1, true) then
						table.insert(filteredSource, em)
					end
				end
			end
		end

		local function renderMoreRows(batchSize)
			LPS_ATTRIBUTES(VM(NONE))
			batchSize = batchSize or 30
			local target = math.min(#filteredSource, loadedIndex + batchSize)
			for i = loadedIndex + 1, target do
				loadedIndex = i
				renderEmoteRow(p, filteredSource[i], loadedIndex, function()
					if buildFavsList then
						buildFavsList(searchBox.Text)
					end
				end)
			end
		end

		local function buildEmotesList(filter)
			LPS_ATTRIBUTES(VM(NONE))
			for _, c in ipairs(p:GetChildren()) do
				if c:IsA("Frame") then
					c:Destroy()
				end
			end
			loadedIndex = 0
			prepareSource(filter)
			renderMoreRows(40)
			updateTabCounts()
		end

		scrollContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if emotePages["Emotes"].Visible and filteredSource then
				local maxScroll = scrollContainer.AbsoluteCanvasSize.Y - scrollContainer.AbsoluteWindowSize.Y
				if maxScroll > 0 and scrollContainer.CanvasPosition.Y >= maxScroll - 150 then
					if loadedIndex < #filteredSource then
						renderMoreRows(30)
					end
				end
			end
		end)
		buildEmotesList("")
		_buildEmotesListCallback = function()
			buildEmotesList(searchBox.Text)
		end
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if emotePages["Emotes"].Visible then
				buildEmotesList(searchBox.Text)
			elseif emotePages["Favorites"].Visible and buildFavsList then
				buildFavsList(searchBox.Text)
			end
		end)
	end

	do
		local p = Instance.new("Frame", scrollContainer)
		p.Size = UDim2.new(1, 0, 0, 0)
		p.AutomaticSize = Enum.AutomaticSize.Y
		p.BackgroundTransparency = 1
		p.Visible = false
		emotePages["Favorites"] = p
		local listL = Instance.new("UIListLayout", p)
		listL.Padding = UDim.new(0, 6)
		listL.SortOrder = Enum.SortOrder.LayoutOrder

		buildFavsList = function(filter)
			for _, c in ipairs(p:GetChildren()) do
				if c:IsA("Frame") or c:IsA("TextLabel") then
					c:Destroy()
				end
			end
			local idx = 0
			filter = (filter or ""):lower()

			local favEmotesList = {}
			local seenFavIds = {}

			for favIdStr, isFav in pairs(emoteFavorites) do
				if isFav and not seenFavIds[favIdStr] then
					seenFavIds[favIdStr] = true
					local em = _allEmotesById[favIdStr]
					local name = em and em.name or ("Emote " .. favIdStr)
					table.insert(favEmotesList, { id = favIdStr, name = name })
				end
			end

			table.sort(favEmotesList, function(a, b) return a.name:lower() < b.name:lower() end)

			for _, em in ipairs(favEmotesList) do
				if filter == "" or em.name:lower():find(filter, 1, true) then
					idx = idx + 1
					renderEmoteRow(p, em, idx, function()
						buildFavsList(filter)
					end)
				end
			end

			if idx == 0 then
				local noFavsLbl = Instance.new("TextLabel", p)
				noFavsLbl.Size = UDim2.new(1, 0, 0, 40)
				noFavsLbl.BackgroundTransparency = 1
				noFavsLbl.Text = "No favorites yet — star an emote!"
				noFavsLbl.TextColor3 = T.text3
				noFavsLbl.TextSize = 11
				noFavsLbl.Font = Enum.Font.BuilderSansMedium
			end
			updateTabCounts()
		end
		buildFavsList("")
	end

	do
		local p = Instance.new("Frame", scrollContainer)
		p.Size = UDim2.new(1, 0, 0, 0)
		p.AutomaticSize = Enum.AutomaticSize.Y
		p.BackgroundTransparency = 1
		p.Visible = false
		emotePages["Packs"] = p
		local listL = Instance.new("UIListLayout", p)
		listL.Padding = UDim.new(0, 6)
		listL.SortOrder = Enum.SortOrder.LayoutOrder

		local fetchedPacks = {}
		local packsFetchState = "idle"
		local packsFetchInfo = ""
		local packFetchedSeen = {}
		local function packNorm(n)
			n = tostring(n):lower()
			n = n:gsub(" animation packages?$", ""):gsub(" animations?$", ""):gsub(" packs?$", "")
			return (n:gsub("^%s+", ""):gsub("%s+$", ""))
		end
		for _, n in ipairs(PACK_NAMES) do
			packFetchedSeen[packNorm(n)] = true
		end

		local function packHttpJson(url)
			local reqFunc = request or http_request or (syn and syn.request) or (http and http.request)
			local body
			if reqFunc then
				local ok, res = pcall(reqFunc, { Url = url, Method = "GET" })
				if ok and res and (res.StatusCode == 200 or res.Success) and res.Body then
					body = res.Body
				end
			end
			if not body then
				local ok, b = pcall(function()
					return game:HttpGet(url)
				end)
				if ok and b then
					body = b
				end
			end
			if not body then
				return nil
			end
			local ok, decoded = pcall(function()
				return httpService:JSONDecode(body)
			end)
			return ok and decoded or nil
		end

		local PACK_JSON_URL = "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json"
		local PACK_SLOT_ORDER = { "Climb", "Fall", "Idle", "Jump", "Run", "Swim", "Walk" }
		local packLimit = 60

		local function addFetchedPack(id, name, slots)
			LPS_ATTRIBUTES(VM(NONE))
			id = tostring(id)
			if packFetchedSeen["id" .. id] or packFetchedSeen[packNorm(name)] then
				return
			end
			packFetchedSeen["id" .. id] = true
			local assets
			local ids
			if type(slots) == "table" then
				ids = {}
				local keys = {}
				for k in pairs(slots) do
					keys[#keys + 1] = tonumber(k) or 0
				end
				table.sort(keys)
				for _, k in ipairs(keys) do
					local v = slots[tostring(k)] or slots[k]
					if type(v) == "table" then
						v = v[1]
					end
					if v then
						ids[#ids + 1] = tostring(v)
					end
				end
				local n = 0
				for _ in pairs(slots) do
					n = n + 1
				end
				if n == 7 then
					assets = {}
					for k, t in ipairs(PACK_SLOT_ORDER) do
						local v = slots[tostring(k)] or slots[k]
						if type(v) == "table" then
							v = v[1]
						end
						if v then
							assets[t] = tostring(v)
						end
					end
				end
			end
			table.insert(fetchedPacks, { id = id, name = tostring(name), assets = assets, ids = ids })
		end

		local function ingestPackJson(decoded)
			local list = type(decoded) == "table" and (decoded.data or decoded) or nil
			if type(list) ~= "table" then
				return 0
			end
			local n = 0
			for _, it in ipairs(list) do
				if type(it) == "table" and it.id and it.name then
					addFetchedPack(it.id, it.name, it.bundledItems)
					n = n + 1
				end
			end
			return n
		end

		local function loadPackCache()
			pcall(function()
				if isfile and readfile and isfile("slate/animationpacks.json") then
					ingestPackJson(httpService:JSONDecode(readfile("slate/animationpacks.json")))
				end
			end)
		end

		local function fetchAllPacks(onDone)
			if packsFetchState == "loading" then
				return
			end
			packsFetchState = "loading"
			task.spawn(function()
				local before = #fetchedPacks
				local reqFunc = request or http_request or (syn and syn.request) or (http and http.request)
				local body
				if reqFunc then
					local ok, res = pcall(reqFunc, { Url = PACK_JSON_URL, Method = "GET" })
					if ok and res and res.StatusCode == 200 and res.Body then
						body = res.Body
					end
				end
				if not body then
					local ok, b = pcall(function()
						return game:HttpGet(PACK_JSON_URL)
					end)
					if ok and b then
						body = b
					end
				end
				if body then
					local ok, decoded = pcall(function()
						return httpService:JSONDecode(body)
					end)
					if ok then
						ingestPackJson(decoded)
						if #fetchedPacks > before then
							pcall(function()
								if not isfolder("slate") then
									makefolder("slate")
								end
								writefile("slate/animationpacks.json", body)
							end)
						end
					end
				end
				packsFetchInfo = body and "ok" or "download failed"
				packsFetchState = "done"
				if onDone then
					pcall(onDone)
				end
			end)
		end

		local function getPackEntries()
			local list = {}
			for _, packName in ipairs(PACK_NAMES) do
				list[#list + 1] = {
					key = packName,
					title = packName .. " Pack",
					image = PackCustomImages[packName] or "https://i.postimg.cc/mDWcc4JK/defaultanimpack.webp",
				}
			end
			local extra = {}
			for _, fp in ipairs(fetchedPacks) do
				extra[#extra + 1] = {
					key = "RobloxPack_" .. fp.id,
					title = fp.name,
					bundleId = fp.id,
					assets = fp.assets,
					ids = fp.ids,
					thumb = "rbxthumb://type=BundleThumbnail&id=" .. fp.id .. "&w=150&h=150",
				}
			end
			table.sort(extra, function(a, b)
				return a.title:lower() < b.title:lower()
			end)
			for _, e in ipairs(extra) do
				list[#list + 1] = e
			end
			return list
		end

		local bundleAssetCache = {}
		local function resolveBundleAssets(bundleId)
			if bundleAssetCache[bundleId] then
				return bundleAssetCache[bundleId]
			end
			local list
			pcall(function()
				local aes = game:GetService("AvatarEditorService")
				local d = aes:GetItemDetails(tonumber(bundleId), Enum.AvatarItemType.Bundle)
				if type(d) == "table" then
					list = d.BundledItems or d.bundledItems or d.items
				end
			end)
			if type(list) ~= "table" or #list == 0 then
				local data = packHttpJson("https://catalog.roblox.com/v1/bundles/" .. bundleId .. "/details")
				if type(data) == "table" and data[1] then
					data = data[1]
				end
				list = type(data) == "table" and data.items or nil
			end
			local out = {}
			if type(list) == "table" then
				for _, it in ipairs(list) do
					local itId = type(it) == "table" and (it.id or it.Id)
					if itId then
						it = { id = itId, name = it.name or it.Name }
						local n = tostring(it.name or ""):lower()
						local t
						if n:find("swim idle", 1, true) or n:find("swimidle", 1, true) then
							t = "SwimIdle"
						elseif n:find("%f[%a]idle%f[%A]") then
							t = "Idle"
						elseif n:find("%f[%a]walk%f[%A]") then
							t = "Walk"
						elseif n:find("%f[%a]run%f[%A]") then
							t = "Run"
						elseif n:find("%f[%a]jump%f[%A]") then
							t = "Jump"
						elseif n:find("%f[%a]fall%f[%A]") then
							t = "Fall"
						elseif n:find("%f[%a]swim%f[%A]") then
							t = "Swim"
						elseif n:find("%f[%a]climb%f[%A]") then
							t = "Climb"
						end
						if t and not out[t] then
							out[t] = tostring(it.id)
						end
					end
				end
			end
			bundleAssetCache[bundleId] = out
			return out
		end

		local function idleIdsFor(assetId)
			local key = "idle:" .. assetId
			_G.__SlateAnimIdCache = _G.__SlateAnimIdCache or {}
			local c = _G.__SlateAnimIdCache[key]
			if c then
				return c
			end
			task.wait()
			local ids = {}
			pcall(function()
				local o = game:GetObjects("rbxassetid://" .. assetId)
				local obj = o and o[1]
				if obj then
					if obj:IsA("Animation") then
						ids[1] = obj.AnimationId:match("%d+")
					else
						for _, nm in ipairs({ "Animation1", "Animation2" }) do
							local a = obj:FindFirstChild(nm, true)
							if a and a:IsA("Animation") then
								ids[#ids + 1] = a.AnimationId:match("%d+")
							end
						end
						if #ids == 0 then
							local a = obj:FindFirstChildWhichIsA("Animation", true)
							if a then
								ids[1] = a.AnimationId:match("%d+")
							end
						end
					end
				end
			end)
			if #ids == 0 then
				ids[1] = assetId
			end
			_G.__SlateAnimIdCache[key] = ids
			return ids
		end

		_G.__SlateSnap = _G.__SlateSnap or setmetatable({}, { __mode = "k" })
		_G.__SlateSnapAnimate = function(Animate)
			if not Animate or _G.__SlateSnap[Animate] then
				return
			end
			local snap = {}
			for _, d in ipairs(Animate:GetDescendants()) do
				if d:IsA("Animation") then
					snap[d] = d.AnimationId
				end
			end
			_G.__SlateSnap[Animate] = snap
		end

		local function saveLastPack(entry)
			pcall(function()
				if not writefile then
					return
				end
				if not isfolder("slate") then
					makefolder("slate")
				end
				_G.__SlateCustomAnims = {}
				writefile("slate/customanims.json", "{}")
				if entry == nil then
					writefile("slate/lastpack.json", "{}")
					return
				end
				writefile(
					"slate/lastpack.json",
					httpService:JSONEncode({
						key = entry.key,
						title = entry.title,
						bundleId = entry.bundleId,
						ids = entry.ids,
						assets = entry.assets,
					})
				)
			end)
		end

		local function saveIdCache()
			pcall(function()
				if writefile then
					if not isfolder("slate") then
						makefolder("slate")
					end
					writefile("slate/animidcache.json", httpService:JSONEncode(_G.__SlateAnimIdCache or {}))
				end
			end)
		end

		local packApplying = false
		local function applyPackEntry(entry, silent)
			if packApplying then
				return
			end
			local char = localPlr.Character
			local Animate = char and char:FindFirstChild("Animate")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not (Animate and hum) then
				return
			end
			if not entry.bundleId and OriginalAnimations.Walk[entry.key] == nil and OriginalAnimations.Idle[entry.key] then
				_G.__SlateSnapAnimate(Animate)
				task.spawn(applyOnyxPackage, entry.key)
				if not silent then
					saveLastPack(entry)
				end
				return
			end
			packApplying = true
			pcall(function()
				_G.__SlateSnapAnimate(Animate)
				_G.__SlateAnimIdCache = _G.__SlateAnimIdCache or {}
				local assets = {}
				local idleList
				if entry.bundleId then
					local clsKey = "cls:" .. tostring(entry.bundleId)
					local cached = _G.__SlateAnimIdCache[clsKey]
					if type(cached) == "table" and next(cached) ~= nil then
						assets = cached
					elseif entry.ids then
						local TYPE_BY_ASSET = { [48] = "Climb", [50] = "Fall", [51] = "Idle", [52] = "Jump", [53] = "Run", [54] = "Swim", [55] = "Walk" }
						_G.__SlateAssetTypeCache = _G.__SlateAssetTypeCache or {}
						local pending = 0
						for _, id in ipairs(entry.ids) do
							if _G.__SlateAssetTypeCache[id] == nil then
								pending = pending + 1
								task.spawn(function()
									local okP, info = pcall(function()
										return marketplaceService:GetProductInfo(tonumber(id))
									end)
									_G.__SlateAssetTypeCache[id] = (okP and info and info.AssetTypeId) or false
									pending = pending - 1
								end)
							end
						end
						local t0 = os.clock()
						while pending > 0 and os.clock() - t0 < 6 do
							task.wait(0.05)
						end
						for _, id in ipairs(entry.ids) do
							local c = _G.__SlateAssetTypeCache[id]
							local t = c and TYPE_BY_ASSET[c]
							if t and not assets[t] then
								assets[t] = id
							end
						end
						if entry.assets then
							for t, id in pairs(entry.assets) do
								if not assets[t] then
									assets[t] = id
								end
							end
						end
					elseif entry.assets then
						assets = entry.assets
					end
					if next(assets) == nil then
						assets = resolveBundleAssets(entry.bundleId)
					end
					if next(assets) ~= nil then
						_G.__SlateAnimIdCache[clsKey] = assets
						entry.assets = assets
					end
				else
					local k = entry.key
					for _, t in ipairs({ "Walk", "Run", "Jump", "Fall", "Swim", "SwimIdle", "Climb" }) do
						local v = OriginalAnimations[t] and OriginalAnimations[t][k]
						if v then
							assets[t] = type(v) == "table" and v[1] or v
						end
					end
					idleList = OriginalAnimations.Idle[k]
					if idleList then
						assets.Idle = idleList[1]
					end
				end
				if next(assets) == nil then
					return
				end
				local base = "http://www.roblox.com/asset/?id="
				local order = { "Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim", "SwimIdle" }
				local SLOT = {
					Walk = { "walk", "WalkAnim" },
					Run = { "run", "RunAnim" },
					Jump = { "jump", "JumpAnim" },
					Fall = { "fall", "FallAnim" },
					Climb = { "climb", "ClimbAnim" },
					Swim = { "swim", "Swim" },
					SwimIdle = { "swimidle", "SwimIdle" },
				}
				local function setId(folder, child, id)
					local f = Animate:FindFirstChild(folder)
					local v = f and f:FindFirstChild(child)
					if v and id then
						v.AnimationId = base .. id
					end
				end
				local reqFunc = request or http_request or (syn and syn.request) or (http and http.request)
				local function httpIds(sid)
					if not reqFunc then
						return nil
					end
					local okR, res = pcall(reqFunc, { Url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. sid, Method = "GET" })
					if not (okR and res and res.StatusCode == 200 and type(res.Body) == "string") then
						return nil
					end
					local out, seen = {}, {}
					for _, pat in ipairs({ "rbxassetid://(%d+)", "asset/%?id=(%d+)" }) do
						for n in res.Body:gmatch(pat) do
							if n ~= sid and not seen[n] then
								seen[n] = true
								out[#out + 1] = n
								if #out >= 2 then
									break
								end
							end
						end
						if #out > 0 then
							break
						end
					end
					return #out > 0 and out or nil
				end
				local jobs = {}
				for _, t in ipairs(order) do
					local id = assets[t]
					if id then
						if t == "Idle" then
							if idleList then
								jobs[#jobs + 1] = { t = "Idle", sid = tostring(idleList[1]), slot = 1 }
								if idleList[2] then
									jobs[#jobs + 1] = { t = "Idle", sid = tostring(idleList[2]), slot = 2 }
								end
							else
								jobs[#jobs + 1] = { t = "Idle", sid = tostring(id), asIdle = true }
							end
						else
							jobs[#jobs + 1] = { t = t, sid = tostring(id) }
						end
					end
				end
				local pending = 0
				for _, j in ipairs(jobs) do
					local ck = (j.asIdle and "idle:" or "") .. j.sid
					local c = _G.__SlateAnimIdCache[ck]
					if c then
						j.real = c
					else
						pending = pending + 1
						task.spawn(function()
							local l = httpIds(j.sid)
							if l then
								j.real = j.asIdle and l or l[1]
								_G.__SlateAnimIdCache[ck] = j.real
							end
							pending = pending - 1
						end)
					end
				end
				local t0 = os.clock()
				while pending > 0 and os.clock() - t0 < 8 do
					task.wait(0.05)
				end
				for _, j in ipairs(jobs) do
					if not j.real then
						if j.asIdle then
							j.real = idleIdsFor(j.sid)
						else
							j.real = (resolveAnimationId(j.sid))
						end
						task.wait(0.15)
					end
				end
				saveIdCache()
				local idleOut = {}
				for _, t in ipairs(order) do
					if localPlr.Character ~= char or not Animate.Parent then
						break
					end
					local did = false
					for _, j in ipairs(jobs) do
						if j.t == t then
							did = true
							if t == "Idle" then
								if j.asIdle then
									idleOut[1] = j.real[1]
									idleOut[2] = j.real[2]
								else
									idleOut[j.slot] = j.real
								end
							else
								setId(SLOT[t][1], SLOT[t][2], j.real)
							end
						end
					end
					if t == "Idle" and idleOut[1] then
						setId("idle", "Animation1", idleOut[1])
						setId("idle", "Animation2", idleOut[2] or idleOut[1])
					end
					if did then
						task.wait(0.1)
					end
				end
				if not silent then
					saveLastPack(entry)
				end
			end)
			packApplying = false
		end

		local function resetAnimations()
			saveLastPack(nil)
			local char = localPlr.Character
			local Animate = char and char:FindFirstChild("Animate")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local snap = Animate and _G.__SlateSnap[Animate]
			if not (Animate and hum and snap) then
				return
			end
			pcall(function()
				stopAllTracks(hum)
				Animate.Disabled = true
				for d, v in pairs(snap) do
					if d.Parent then
						d.AnimationId = v
					end
				end
				task.wait()
				Animate.Disabled = false
			end)
		end

		_G.__SlateResetAnims = resetAnimations

		local function restoreSavedPack()
			pcall(function()
				if isfile and readfile and isfile("slate/lastpack.json") then
					local d = httpService:JSONDecode(readfile("slate/lastpack.json"))
					if type(d) == "table" and d.key then
						applyPackEntry({ key = d.key, title = d.title, bundleId = d.bundleId, ids = d.ids, assets = d.assets }, true)
						while packApplying do
							task.wait(0.2)
						end
					end
				end
			end)
			pcall(function()
				if isfile and readfile and isfile("slate/customanims.json") then
					local d = httpService:JSONDecode(readfile("slate/customanims.json"))
					if type(d) == "table" then
						_G.__SlateCustomAnims = d
						for _, t in ipairs({ "Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim", "SwimIdle" }) do
							if d[t] ~= nil then
								setAnimation(t, d[t], true)
								task.wait(0.4)
							end
						end
					end
				end
			end)
		end
		local function onPackChar(c)
			task.spawn(function()
				if c:WaitForChild("Animate", 15) then
					task.wait(2)
					restoreSavedPack()
				end
			end)
		end
		localPlr.CharacterAdded:Connect(onPackChar)
		if localPlr.Character then
			onPackChar(localPlr.Character)
		end

		pcall(function()
			if isfile and readfile and isfile("slate/animidcache.json") then
				local d = httpService:JSONDecode(readfile("slate/animidcache.json"))
				if type(d) == "table" then
					_G.__SlateAnimIdCache = _G.__SlateAnimIdCache or {}
					for k, v in pairs(d) do
						if _G.__SlateAnimIdCache[k] == nil then
							_G.__SlateAnimIdCache[k] = v
						end
					end
				end
			end
		end)
		loadPackCache()

		local packMatched, packRendered, packIdx = {}, 0, 0
		local renderPackBatch

		local function rebuildPacksList(filter)
			for _, child in ipairs(p:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end
			filter = (filter or ""):lower()
			packMatched = {}
			for _, e in ipairs(getPackEntries()) do
				if filter == "" or e.title:lower():find(filter, 1, true) then
					packMatched[#packMatched + 1] = e
				end
			end
			packRendered = 0
			packIdx = 1
			do
				local rrFrame = Instance.new("Frame", p)
				rrFrame.Size = UDim2.new(1, -6, 0, 30)
				rrFrame.LayoutOrder = 0
				rrFrame.BackgroundTransparency = 1
				local rrBtn = Instance.new("TextButton", rrFrame)
				rrBtn.Size = UDim2.new(1, 0, 1, 0)
				rrBtn.BackgroundColor3 = Color3.fromRGB(38, 20, 24)
				rrBtn.BorderSizePixel = 0
				rrBtn.Text = "Reset to default animations"
				rrBtn.TextColor3 = T.danger
				rrBtn.Font = Enum.Font.BuilderSansBold
				rrBtn.TextSize = 10
				rrBtn.AutoButtonColor = false
				cr(8, rrBtn)
				stk(1, T.danger, rrBtn).Transparency = 0.6
				rrBtn.MouseButton1Click:Connect(function()
					task.spawn(resetAnimations)
					rrBtn.Text = "Reset!"
					task.delay(0.8, function()
						rrBtn.Text = "Reset to default animations"
					end)
				end)
			end
			if packsFetchState == "loading" or #fetchedPacks == 0 then
				local divFrame = Instance.new("Frame", p)
				divFrame.Size = UDim2.new(1, 0, 0, 22)
				divFrame.LayoutOrder = 1
				divFrame.BackgroundTransparency = 1
				local divLbl = lbl(
					divFrame,
					packsFetchState == "loading" and "Loading Roblox packs…" or ("Couldn't load Roblox packs (" .. packsFetchInfo .. ")"),
					10,
					Enum.Font.BuilderSansBold,
					T.text3,
					Enum.TextXAlignment.Center
				)
				divLbl.Size = UDim2.new(1, 0, 1, 0)
			end
			renderPackBatch(40)
		end

		renderPackBatch = function(count)
			local idx = packIdx
			local last = math.min(#packMatched, packRendered + count)
			for k = packRendered + 1, last do
				local entry = packMatched[k]
				local packName = entry.key
				local packTitle = entry.title

					idx = idx + 1
					local row = Instance.new("Frame", p)
					row.Size = UDim2.new(1, -6, 0, 46)
					row.LayoutOrder = idx
					row.BackgroundColor3 = T.surface2
					row.BackgroundTransparency = 0.35
					row.BorderSizePixel = 0
					cr(8, row)
					local rStk = stk(1, T.line, row)
					rStk.Transparency = 0.45

					local imgFrame = Instance.new("Frame", row)
					imgFrame.Size = UDim2.new(0, 34, 0, 34)
					imgFrame.Position = UDim2.new(0, 6, 0.5, -17)
					imgFrame.BackgroundColor3 = T.surface3
					cr(6, imgFrame)
					stk(1, T.line, imgFrame).Transparency = 0.5

					local packImg = Instance.new("ImageLabel", imgFrame)
					packImg.Size = UDim2.new(1, 0, 1, 0)
					packImg.BackgroundTransparency = 1
					packImg.ScaleType = Enum.ScaleType.Crop
					cr(6, packImg)
					if entry.thumb then
							packImg.Image = entry.thumb
						else
							task.spawn(function()
								packImg.Image = resolveImageId(entry.image)
							end)
						end

					local nl = lbl(row, packTitle, 11, Enum.Font.BuilderSansBold, T.text1)
					nl.Size = UDim2.new(1, -120, 1, 0)
					nl.TextTruncate = Enum.TextTruncate.AtEnd
					nl.Position = UDim2.new(0, 48, 0, 0)

					local applyBtn = Instance.new("TextButton", row)
					applyBtn.Size = UDim2.new(0, 56, 0, 24)
					applyBtn.Position = UDim2.new(1, -64, 0.5, -12)
					applyBtn.BackgroundColor3 = T.surface3
					applyBtn.Text = "Apply"
					applyBtn.TextColor3 = T.text1
					applyBtn.Font = Enum.Font.BuilderSansBold
					applyBtn.TextSize = 10
					applyBtn.AutoButtonColor = false
					cr(6, applyBtn)
					stk(1, T.line, applyBtn).Transparency = 0.5

					applyBtn.MouseEnter:Connect(function()
						applyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
					end)
					applyBtn.MouseLeave:Connect(function()
						applyBtn.BackgroundColor3 = T.surface3
					end)
					applyBtn.MouseButton1Click:Connect(function()
						task.spawn(applyPackEntry, entry)
						tw(applyBtn, { BackgroundColor3 = Color3.fromRGB(70, 70, 84) }):Play()
						task.delay(0.8, function()
							tw(applyBtn, { BackgroundColor3 = T.surface3, TextColor3 = T.text1 }):Play()
						end)
					end)
			end
			packRendered = last
			packIdx = idx
		end

		scrollContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if p.Visible and packRendered < #packMatched then
				if scrollContainer.CanvasPosition.Y + scrollContainer.AbsoluteWindowSize.Y >= scrollContainer.AbsoluteCanvasSize.Y - 320 then
					renderPackBatch(30)
				end
			end
		end)

		local packsBuilt = false
		p:GetPropertyChangedSignal("Visible"):Connect(function()
			if p.Visible and not packsBuilt then
				packsBuilt = true
				rebuildPacksList(searchBox.Text)
				fetchAllPacks(function()
					if p.Visible then
						rebuildPacksList(searchBox.Text)
					end
				end)
			end
		end)
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if emotePages["Packs"].Visible then
				rebuildPacksList(searchBox.Text)
			end
		end)
	end

	do
		local p = Instance.new("Frame", scrollContainer)
		p.Size = UDim2.new(1, 0, 0, 0)
		p.AutomaticSize = Enum.AutomaticSize.Y
		p.BackgroundTransparency = 1
		p.Visible = false
		emotePages["Custom"] = p
		local listL = Instance.new("UIListLayout", p)
		listL.Padding = UDim.new(0, 6)
		listL.SortOrder = Enum.SortOrder.LayoutOrder

		for idx, slotName in ipairs({ "Idle", "Walk", "Run", "Jump", "Fall", "Swim", "SwimIdle", "Climb" }) do
			local row = Instance.new("Frame", p)
			row.Size = UDim2.new(1, -6, 0, 36)
			row.LayoutOrder = idx
			row.BackgroundColor3 = T.surface2
			row.BackgroundTransparency = 0.35
			row.BorderSizePixel = 0
			cr(8, row)
			local rStk = stk(1, T.line, row)
			rStk.Transparency = 0.45

			local sLbl = lbl(row, slotName, 11, Enum.Font.BuilderSansBold, T.text1)
			sLbl.Size = UDim2.new(0, 55, 1, 0)
			sLbl.Position = UDim2.new(0, 10, 0, 0)

			local idBox = Instance.new("TextBox", row)
			idBox.Size = UDim2.new(1, -120, 0, 24)
			idBox.Position = UDim2.new(0, 66, 0.5, -12)
			idBox.BackgroundColor3 = T.surface3
			idBox.Text = ""
			idBox.PlaceholderText = slotName == "Idle" and "ID 1, ID 2..." or "Animation ID..."
			idBox.TextColor3 = T.text1
			idBox.PlaceholderColor3 = T.text3
			idBox.Font = Enum.Font.BuilderSansMedium
			idBox.TextSize = 10.5
			cr(6, idBox)
			stk(1, T.line, idBox).Transparency = 0.5
			local ibp = Instance.new("UIPadding", idBox)
			ibp.PaddingLeft = UDim.new(0, 8)

			local setBtn = Instance.new("TextButton", row)
			setBtn.Size = UDim2.new(0, 44, 0, 24)
			setBtn.Position = UDim2.new(1, -50, 0.5, -12)
			setBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			setBtn.Text = "Set"
			setBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
			setBtn.Font = Enum.Font.BuilderSansBold
			setBtn.TextSize = 10
			setBtn.AutoButtonColor = false
			cr(6, setBtn)

			setBtn.MouseButton1Click:Connect(function()
				local text = idBox.Text
				if slotName == "Idle" then
					local ids = {}
					for num in text:gmatch("%d+") do
						table.insert(ids, num)
					end
					if #ids > 0 then
						task.spawn(setAnimation, "Idle", ids)
					end
				else
					local raw = text:match("%d+")
					if raw then
						task.spawn(setAnimation, slotName, raw)
					end
				end
				tw(setBtn, { BackgroundColor3 = Color3.fromRGB(70, 70, 84) }):Play()
				task.delay(0.6, function()
					tw(setBtn, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), TextColor3 = Color3.fromRGB(15, 15, 20) }):Play()
				end)
			end)
		end

		local indBuilt = false
		local function buildIndividualList(filter)
			LPS_ATTRIBUTES(VM(NONE))
			for _, c in ipairs(p:GetChildren()) do
				if c.Name == "IndRow" then
					c:Destroy()
				end
			end
			filter = (filter or ""):lower()
			local idx = 100
			local hdr = Instance.new("Frame", p)
			hdr.Name = "IndRow"
			hdr.Size = UDim2.new(1, 0, 0, 24)
			hdr.LayoutOrder = idx
			hdr.BackgroundTransparency = 1
			local hl = lbl(hdr, "— Preset Animations —", 10, Enum.Font.BuilderSansBold, T.text3, Enum.TextXAlignment.Center)
			hl.Size = UDim2.new(1, 0, 1, 0)
			local typeOrder = { "Idle", "Walk", "Run", "Jump", "Fall", "Swim", "SwimIdle", "Climb" }
			for _, animType in ipairs(typeOrder) do
				local anims = OriginalAnimations[animType]
				if anims then
					for name, animData in pairs(anims) do
						local combinedName = name .. " (" .. animType .. ")"
						if filter == "" or combinedName:lower():find(filter, 1, true) then
							idx = idx + 1
							local row = Instance.new("Frame", p)
							row.Name = "IndRow"
							row.Size = UDim2.new(1, -6, 0, 36)
							row.LayoutOrder = idx
							row.BackgroundColor3 = T.surface2
							row.BackgroundTransparency = 0.35
							row.BorderSizePixel = 0
							cr(8, row)
							local rStk = stk(1, T.line, row)
							rStk.Transparency = 0.45

							local nl = lbl(row, combinedName, 11, Enum.Font.BuilderSansMedium, T.text1)
							nl.Size = UDim2.new(1, -75, 1, 0)
							nl.Position = UDim2.new(0, 12, 0, 0)
							nl.TextTruncate = Enum.TextTruncate.AtEnd

							local applyBtn = Instance.new("TextButton", row)
							applyBtn.Size = UDim2.new(0, 52, 0, 22)
							applyBtn.Position = UDim2.new(1, -58, 0.5, -11)
							applyBtn.BackgroundColor3 = T.surface3
							applyBtn.Text = "Apply"
							applyBtn.TextColor3 = T.text1
							applyBtn.Font = Enum.Font.BuilderSansBold
							applyBtn.TextSize = 9.5
							applyBtn.AutoButtonColor = false
							cr(6, applyBtn)
							stk(1, T.line, applyBtn).Transparency = 0.5

							applyBtn.MouseEnter:Connect(function()
								applyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
							end)
							applyBtn.MouseLeave:Connect(function()
								applyBtn.BackgroundColor3 = T.surface3
							end)
							applyBtn.MouseButton1Click:Connect(function()
								task.spawn(setAnimation, animType, animData)
								tw(applyBtn, { BackgroundColor3 = Color3.fromRGB(70, 70, 84) }):Play()
								task.delay(0.8, function()
									tw(applyBtn, { BackgroundColor3 = T.surface3, TextColor3 = T.text1 }):Play()
								end)
							end)
						end
					end
				end
			end
		end
		p:GetPropertyChangedSignal("Visible"):Connect(function()
			if p.Visible and not indBuilt then
				indBuilt = true
				buildIndividualList(searchBox.Text)
			end
		end)
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if p.Visible then
				buildIndividualList(searchBox.Text)
			end
		end)

		local rRow = Instance.new("Frame", p)
		rRow.Size = UDim2.new(1, -6, 0, 34)
		rRow.BackgroundTransparency = 1
		rRow.LayoutOrder = 99

		local rBtn = Instance.new("TextButton", rRow)
		rBtn.Size = UDim2.new(1, 0, 1, 0)
		rBtn.BackgroundColor3 = Color3.fromRGB(38, 20, 24)
		rBtn.BorderSizePixel = 0
		rBtn.Text = "Reset All Custom Animations"
		rBtn.TextColor3 = T.danger
		rBtn.Font = Enum.Font.BuilderSansBold
		rBtn.TextSize = 10
		rBtn.AutoButtonColor = false
		cr(6, rBtn)
		stk(1, T.danger, rBtn).Transparency = 0.6

		rBtn.MouseButton1Click:Connect(function()
			if _G.__SlateResetAnims then
				task.spawn(_G.__SlateResetAnims)
				return
			end
			local char = localPlr.Character
			if not char then return end
			local Animate = char:FindFirstChild("Animate")
			if not Animate then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			pcall(function()
				freezeChar()
				task.wait(0.05)
				stopAllTracks(hum)
				resetIdle(Animate)
				if Animate:FindFirstChild("walk") then
					Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
				end
				if Animate:FindFirstChild("run") then
					Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
				end
				if Animate:FindFirstChild("jump") then
					Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
				end
				if Animate:FindFirstChild("fall") then
					Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
				end
				if Animate:FindFirstChild("climb") then
					Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
				end
				unfreezeChar()
				Animate.Disabled = true
				task.wait(0.05)
				Animate.Disabled = false
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end)
		end)
	end

	local function switchTab(tabName)
		_G.__SlateTabSearch = _G.__SlateTabSearch or {}
		_G.__SlateTabSearch[currentActiveTab] = searchBox.Text
		currentActiveTab = tabName
		for _, pg in pairs(emotePages) do
			pg.Visible = false
		end
		searchBox.Text = _G.__SlateTabSearch[tabName] or ""
		searchBox.PlaceholderText = ({
			Emotes = "Search emotes...",
			Favorites = "Search favorites...",
			Packs = "Search animation packs...",
			Custom = "Search preset animations...",
		})[tabName] or "Search..."
		if emotePages[tabName] then
			emotePages[tabName].Visible = true
		end
		for _, btn in ipairs(tabBtns) do
			local active = btn:GetAttribute("tn") == tabName
			local bStroke = btn:FindFirstChildOfClass("UIStroke")
			if active then
				tweenService:Create(btn, TweenInfo.new(0.18), {
					BackgroundColor3 = T.surface3,
					BackgroundTransparency = 0,
					TextColor3 = T.text1,
				}):Play()
				if bStroke then
					tweenService:Create(bStroke, TweenInfo.new(0.18), {
						Color = Color3.fromRGB(255, 255, 255),
						Transparency = 0.75,
					}):Play()
				end
			else
				tweenService:Create(btn, TweenInfo.new(0.18), {
					BackgroundColor3 = T.surface,
					BackgroundTransparency = 0.2,
					TextColor3 = T.text2,
				}):Play()
				if bStroke then
					tweenService:Create(bStroke, TweenInfo.new(0.18), {
						Color = T.line,
						Transparency = 0.45,
					}):Play()
				end
			end
		end
		if tabName == "Favorites" and buildFavsList then
			buildFavsList(searchBox.Text)
		end
	end

	for _, btn in ipairs(tabBtns) do
		btn.MouseButton1Click:Connect(function()
			switchTab(btn:GetAttribute("tn"))
		end)
	end
	switchTab("Emotes")
	updateTabCounts()
	_slateActualToggleEmoteMenu = function()
		if sg then
			if sg.Enabled then
				if _G.__SlateEmoteAnimClose then _G.__SlateEmoteAnimClose() else sg.Enabled = false end
			else
				sg.Enabled = true
			end
		end
	end
	_slateEmoteMenuLoading = false
end

task.delay(2, function()
	if not _slateActualToggleEmoteMenu then
		pcall(ensureEmoteMenuLoaded)
	end
end)

_G.ToggleSlateEmoteMenu = function()
	if not _slateActualToggleEmoteMenu then
		ensureEmoteMenuLoaded()
	end
	if _slateActualToggleEmoteMenu then
		_slateActualToggleEmoteMenu()
	end
end
end
(function()
	local Tempus = (function()
		local Tempus = {}
		Tempus.Flags = {}
		Tempus.Version = "2.0.0"

		local function getService(name)
			local ok, svc = pcall(function()
				return game:GetService(name)
			end)
			if ok and svc then
				if type(cloneref) == "function" then
					local ok2, c = pcall(cloneref, svc)
					if ok2 and c then
						return c
					end
				end
				return svc
			end
			return nil
		end
		local TweenService = getService("TweenService")
		local UserInputService = getService("UserInputService")
		local RunService = getService("RunService")
		local Players = getService("Players")
		local CoreGui = getService("CoreGui")
		local HttpService = getService("HttpService")

		local function localPlayer()
			return Players and Players.LocalPlayer
		end

		local function getGuiParent()
			if type(gethui) == "function" then
				local ok, h = pcall(gethui)
				if ok and h then
					return h
				end
			end
			if type(get_hidden_gui) == "function" then
				local ok, h = pcall(get_hidden_gui)
				if ok and h then
					return h
				end
			end
			if CoreGui then
				return CoreGui
			end
			local lp = localPlayer()
			if lp then
				return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui")
			end
			return nil
		end

		local function protectGui(sg)
			LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
			pcall(function()
				if syn and syn.protect_gui then
					syn.protect_gui(sg)
				elseif type(protectgui) == "function" then
					protectgui(sg)
				end
			end)
		end
		local ICON_URL = LPS_ENCSTR("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
		local iconMap = nil

		local function loadIconMap()
			if iconMap ~= nil then
				return iconMap
			end
			iconMap = false
			if type(loadstring) == "function" then
				pcall(function()
					local src = game:HttpGet(ICON_URL)
					local fn = loadstring(src)
					if type(fn) == "function" then
						local ok, map = pcall(fn)
						if ok and type(map) == "table" then
							iconMap = map
						end
					end
				end)
			end
			return iconMap
		end

		local function resolveIcon(icon)
			if not icon or icon == 0 or icon == "" then
				return nil
			end
			if type(icon) == "number" then
				return { Image = "rbxassetid://" .. icon }
			end
			if type(icon) == "string" then
				if string.match(icon, "^%d+$") then
					return { Image = "rbxassetid://" .. icon }
				end
				if string.find(icon, "rbxassetid://") == 1 or string.sub(icon, 1, 4) == "http" then
					return { Image = icon }
				end
				local map = loadIconMap()
				if type(map) == "table" then
					local sized = map["48px"] or map
					local entry = sized and sized[string.lower(icon)]
					if entry then
						return {
							Image = "rbxassetid://" .. entry[1],
							ImageRectSize = Vector2.new(entry[2][1], entry[2][2]),
							ImageRectOffset = Vector2.new(entry[3][1], entry[3][2]),
						}
					end
				end
			end
			return nil
		end

		local function applyIcon(image, spec)
			if not spec or not spec.Image then
				image.Image = ""
				return false
			end
			image.Image = spec.Image
			if spec.ImageRectSize then
				image.ImageRectSize = spec.ImageRectSize
			end
			if spec.ImageRectOffset then
				image.ImageRectOffset = spec.ImageRectOffset
			end
			image.Visible = true
			return true
		end
		local ASSET_BASE = "https://raw.githubusercontent.com/SyncUnofficial/Tempus/main/assets/"

		local function customAssetFn()
			if type(getcustomasset) == "function" then
				return getcustomasset
			end
			if type(getsynasset) == "function" then
				return getsynasset
			end
			if syn and type(syn.getcustomasset) == "function" then
				return function(p)
					return syn.getcustomasset(p)
				end
			end
			return nil
		end
		local PNG_MAGIC = "\137PNG\r\n\26\n"
		local remoteImageCache = {}

		local function remoteImage(filename)
			if remoteImageCache[filename] ~= nil then
				return remoteImageCache[filename] or nil
			end
			remoteImageCache[filename] = false
			local getAsset = customAssetFn()
			if not getAsset or type(writefile) ~= "function" then
				return nil
			end
			pcall(function()
				local valid = false
				if type(isfile) == "function" and isfile(filename) and type(readfile) == "function" then
					local head = readfile(filename)
					valid = type(head) == "string" and string.sub(head, 1, 8) == PNG_MAGIC
				end
				if not valid then
					local body = game:HttpGet(ASSET_BASE .. filename)
					if type(body) ~= "string" or string.sub(body, 1, 8) ~= PNG_MAGIC then
						return
					end
					writefile(filename, body)
				end
				remoteImageCache[filename] = getAsset(filename)
			end)
			return remoteImageCache[filename] or nil
		end
		local STRIPES_FILE = "tempus_stripes_v1.png"
		local Theme = {
			Accent = Color3.fromRGB(255, 255, 255),
			AccentDark = Color3.fromRGB(11, 12, 18),
			HeaderFade = Color3.fromRGB(8, 8, 11),
			WindowBg = Color3.fromRGB(8, 8, 11),
			ChromeBg = Color3.fromRGB(7, 8, 12),
			PanelBg = Color3.fromRGB(11, 12, 18),
			ControlBg = Color3.fromRGB(24, 25, 32),
			ControlBorder = Color3.fromRGB(55, 55, 66),
			Track = Color3.fromRGB(36, 36, 44),
			TextWhite = Color3.fromRGB(248, 248, 250),
			TextBright = Color3.fromRGB(215, 215, 222),
			TextMid = Color3.fromRGB(185, 185, 195),
			TextDim = Color3.fromRGB(125, 125, 135),
			Check = Color3.fromRGB(8, 8, 11),
			FillA = Color3.fromRGB(255, 255, 255),
			FillB = Color3.fromRGB(210, 210, 218),
		}
		local WIN_W = 580
		local WIN_H = 470
		local TOPBAR_H = 46
		local FOOTER_H = 26
		local MARGIN = 14
		local COL_GAP = 10
		local COL_W = math.floor((WIN_W - MARGIN * 2 - COL_GAP) / 2)
		local HEAD_H = 28
		local ROW_H = 24
		local TEXT = 11.5
		local FONT = Enum.Font.BuilderSans
		local FONT_MED = Enum.Font.BuilderSansMedium
		local FONT_BOLD = Enum.Font.BuilderSansBold

		local function tween(obj, props, dur, style, dir)
			if not obj then
				return
			end
			local t = TweenService:Create(
				obj,
				TweenInfo.new(dur or 0.16, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
				props
			)
			t:Play()
			return t
		end

		local function make(class, props, children)
			LPS_ATTRIBUTES(VM(NONE))
			local inst = Instance.new(class)
			for k, v in pairs(props or {}) do
				if k ~= "Parent" then
					inst[k] = v
				end
			end
			for _, c in ipairs(children or {}) do
				c.Parent = inst
			end
			if props and props.Parent then
				inst.Parent = props.Parent
			end
			return inst
		end

		local function corner(parent, r)
			return make("UICorner", { CornerRadius = UDim.new(0, r or 3), Parent = parent })
		end

		local function stroke(parent, color, transparency)
			return make("UIStroke", {
				Color = color or Theme.ControlBorder,
				Thickness = 1,
				Transparency = transparency or 0,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Parent = parent,
			})
		end

		local function keyName(keyCode)
			if not keyCode then
				return "None"
			end
			local pretty = {
				LeftShift = "LShift",
				RightShift = "RShift",
				LeftControl = "LCtrl",
				RightControl = "RCtrl",
				LeftAlt = "LAlt",
				RightAlt = "RAlt",
				KeypadZero = "Num 0",
				KeypadOne = "Num 1",
				KeypadTwo = "Num 2",
				KeypadThree = "Num 3",
				KeypadFour = "Num 4",
				KeypadFive = "Num 5",
				KeypadSix = "Num 6",
				KeypadSeven = "Num 7",
				KeypadEight = "Num 8",
				KeypadNine = "Num 9",
				MouseButton1 = "Mouse 1",
				MouseButton2 = "Mouse 2",
				MouseButton3 = "Mouse 3",
			}
			return pretty[keyCode.Name] or keyCode.Name
		end
		local CONFIG_FOLDER = "Slate"

		local function canFile()
			return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
		end

		local function ensureFolder()
			if type(isfolder) == "function" and type(makefolder) == "function" then
				pcall(function()
					if not isfolder(CONFIG_FOLDER) then
						makefolder(CONFIG_FOLDER)
					end
					if not isfolder(CONFIG_FOLDER .. "/configs") then
						makefolder(CONFIG_FOLDER .. "/configs")
					end
				end)
			end
		end

		function Tempus.Window(opts)
			opts = opts or {}
			local self = {}
			local title = opts.title or "SLATE"
			if opts.accent then
				Theme.Accent = opts.accent
			end
			local menuKey = opts.keybind or Enum.KeyCode.KeypadZero
			pcall(function()
				local p = getGuiParent()
				if p then
					for _, g in ipairs(p:GetChildren()) do
						if g.Name == "SlateEspGui" then
							g:Destroy()
						end
					end
				end
			end)
			local screen = make("ScreenGui", {
				Name = "SlateEspGui",
				ResetOnSpawn = false,
				IgnoreGuiInset = true,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				DisplayOrder = 999,
			})
			protectGui(screen)
			screen.Parent = getGuiParent()
			self.Gui = screen
			local conns = {}

			local function trackConn(c)
				conns[#conns + 1] = c
				return c
			end
			local keybindListenCancel = nil
			local anyListening = false
			local attachElements
			local openHuePopup
			local popupCleanup
			local flagBinds = {}

			local function bindFlag(flag, setter, getter)
				if flag and flag ~= "" then
					flagBinds[flag] = { set = setter, get = getter }
				end
			end

			function self.Destroy()
				for _, c in ipairs(conns) do
					pcall(function()
						c:Disconnect()
					end)
				end
				conns = {}
				flagBinds = {}
				screen:Destroy()
			end

			local function viewport()
				local cam = workspace.CurrentCamera
				if cam and cam.ViewportSize.X > 100 then
					return cam.ViewportSize
				end
				return Vector2.new(1280, 720)
			end
			local vp = viewport()
			local win = make("Frame", {
				Name = "Window",
				Position = UDim2.new(
					0,
					math.max(20, math.floor((vp.X - WIN_W) / 2)),
					0,
					math.max(20, math.floor((vp.Y - WIN_H) / 2))
				),
				Size = UDim2.new(0, WIN_W, 0, WIN_H),
				BackgroundColor3 = Theme.WindowBg,
				BorderSizePixel = 0,
				Visible = false,
				Parent = screen,
			})
			corner(win, 14)
			stroke(win, Color3.fromRGB(55, 55, 66), 0.4)
			local topbar = make("Frame", {
				Name = "Topbar",
				Size = UDim2.new(1, 0, 0, TOPBAR_H),
				BackgroundTransparency = 1,
				Parent = win,
			})
			local logo = make("ImageLabel", {
				Name = "Logo",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, MARGIN + 2, 0.5, 0),
				Size = UDim2.new(0, 30, 0, 30),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.Accent,
				ScaleType = Enum.ScaleType.Fit,
				Parent = topbar,
			})
			logo.Image = "rbxassetid://106790631609801"
			logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
			if opts.logo then
				applyIcon(logo, resolveIcon(opts.logo))
			end
			local closeBtn = make("TextButton", {
				Name = "CloseBtn",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -MARGIN, 0.5, 0),
				Size = UDim2.new(0, 26, 0, 26),
				BackgroundColor3 = Theme.ControlBg,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "\u{d7}",
				Font = FONT_BOLD,
				TextSize = 16,
				TextColor3 = Theme.TextDim,
				AutoButtonColor = false,
				ZIndex = 2,
				Parent = topbar,
			})
			corner(closeBtn, 4)
			closeBtn.MouseEnter:Connect(function()
				tween(closeBtn, {
					BackgroundTransparency = 0,
					BackgroundColor3 = Color3.fromRGB(38, 38, 42),
					TextColor3 = Theme.TextWhite,
				}, 0.1)
			end)
			closeBtn.MouseLeave:Connect(function()
				tween(closeBtn, { BackgroundTransparency = 1, TextColor3 = Theme.TextDim }, 0.12)
			end)
			closeBtn.MouseButton1Click:Connect(function()
				self.SetMenuVisible(false)
			end)
			local searchIcon = make("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, MARGIN + 58, 0.5, 0),
				Size = UDim2.new(0, 14, 0, 14),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.TextDim,
				ScaleType = Enum.ScaleType.Fit,
				Parent = topbar,
			})
			applyIcon(searchIcon, resolveIcon("search"))
			local searchBox = make("TextBox", {
				Name = "SearchBox",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, MARGIN + 78, 0.5, 0),
				Size = UDim2.new(0, 96, 0, 24),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = "",
				PlaceholderText = "Search...",
				PlaceholderColor3 = Theme.TextDim,
				TextSize = TEXT,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Parent = topbar,
			})
			local content = make("Frame", {
				Name = "Content",
				Position = UDim2.new(0, 0, 0, TOPBAR_H),
				Size = UDim2.new(1, 0, 1, -TOPBAR_H - FOOTER_H),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Parent = win,
			})
			local footer = make("Frame", {
				Name = "Footer",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, FOOTER_H),
				BackgroundTransparency = 1,
				Parent = win,
			})
			make("Frame", {
				Position = UDim2.new(0, MARGIN, 0, 0),
				Size = UDim2.new(1, -MARGIN * 2, 0, 1),
				BackgroundColor3 = Color3.fromRGB(30, 29, 32),
				BorderSizePixel = 0,
				Parent = footer,
			})
			local globe = make("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, MARGIN, 0.5, 0),
				Size = UDim2.new(0, 13, 0, 13),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.TextDim,
				ScaleType = Enum.ScaleType.Fit,
				Parent = footer,
			})
			applyIcon(globe, resolveIcon("globe"))
			make("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, MARGIN + 19, 0.5, 0),
				Size = UDim2.new(0, 160, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = opts.footerText or "English",
				TextSize = 12,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = footer,
			})
			local menuKeyLbl = make("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -MARGIN, 0.5, 0),
				Size = UDim2.new(0, 200, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = "Menu: " .. keyName(menuKey),
				TextSize = 12,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = footer,
			})
			local overlay = make("Frame", {
				Name = "Overlay",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Visible = false,
				ZIndex = 50,
				Parent = win,
			})
			local overlayBlock = make("TextButton", {
				Name = "Block",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 50,
				Parent = overlay,
			})
			local overlayContent = nil
			local overlayOwnerClose = nil

			local function closeOverlay()
				if overlayContent then
					overlayContent:Destroy()
					overlayContent = nil
				end
				overlay.Visible = false
				if overlayOwnerClose then
					local cb = overlayOwnerClose
					overlayOwnerClose = nil
					cb()
				end
			end

			local function openOverlay(buildFn, onClose)
				closeOverlay()
				overlayOwnerClose = onClose
				overlayContent = make("Frame", {
					Name = "OverlayContent",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					ZIndex = 51,
					Parent = overlay,
				})
				overlay.Visible = true
				buildFn(overlayContent)
			end
			overlayBlock.MouseButton1Click:Connect(function()
				closeOverlay()
			end)
			local tooltip = make("Frame", {
				Name = "Tooltip",
				Size = UDim2.new(0, 10, 0, 24),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 60,
				Parent = win,
			})
			corner(tooltip, 3)
			stroke(tooltip, Theme.ControlBorder, 0.3)
			local tooltipLbl = make("TextLabel", {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Font = FONT,
				Text = "",
				TextSize = 12,
				TextColor3 = Theme.TextBright,
				ZIndex = 60,
				Parent = tooltip,
			})
			make("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = tooltipLbl,
			})

			local function showTooltip(text, anchor)
				tooltipLbl.Text = text
				local ap = anchor.AbsolutePosition
				local wp = win.AbsolutePosition
				tooltip.Position = UDim2.new(0, ap.X - wp.X - 4, 0, ap.Y - wp.Y + 20)
				tooltip.Visible = true
			end

			local function hideTooltip()
				tooltip.Visible = false
			end
			do
				local dragging = false
				local startPos, startMouse
				topbar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						startMouse = input.Position
						startPos = win.Position
					end
				end)
				trackConn(UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end))
				trackConn(UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and win.Visible then
						local delta = input.Position - startMouse
						local screenGui = win:FindFirstAncestorOfClass("ScreenGui")
						local viewport = screenGui and screenGui.AbsoluteSize or Vector2.new(1920, 1080)
						if viewport.X < 100 or viewport.Y < 100 then
							viewport = Vector2.new(1920, 1080)
						end
						local size = win.AbsoluteSize
						local ap = win.AnchorPoint
						local minX = -startPos.X.Scale * viewport.X + (size.X * ap.X)
						local maxX = viewport.X - (size.X * (1 - ap.X)) - startPos.X.Scale * viewport.X
						local newX = math.clamp(startPos.X.Offset + delta.X, minX, math.max(minX, maxX))
						local minY = -startPos.Y.Scale * viewport.Y + (size.Y * ap.Y)
						local maxY = viewport.Y - (size.Y * (1 - ap.Y)) - startPos.Y.Scale * viewport.Y
						local newY = math.clamp(startPos.Y.Offset + delta.Y, minY, math.max(minY, maxY))
						win.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
					end
				end))
			end
			local fadeProps = {
				Frame = { "BackgroundTransparency" },
				TextLabel = { "BackgroundTransparency", "TextTransparency" },
				TextBox = { "BackgroundTransparency", "TextTransparency" },
				TextButton = { "BackgroundTransparency", "TextTransparency" },
				ImageLabel = { "BackgroundTransparency", "ImageTransparency" },
				ImageButton = { "BackgroundTransparency", "ImageTransparency" },
				ScrollingFrame = { "BackgroundTransparency", "ScrollBarImageTransparency" },
				UIStroke = { "Transparency" },
			}

			local function collectFade(root)
				local list = {}
				local function grab(inst)
					local props = fadeProps[inst.ClassName]
					if props then
						for _, p in ipairs(props) do
							list[#list + 1] = { inst = inst, prop = p, value = inst[p] }
						end
					end
				end
				grab(root)
				for _, d in ipairs(root:GetDescendants()) do
					grab(d)
				end
				return list
			end
			local tabs = {}
			local activeTab = nil
			local navX = MARGIN + 78 + 110
			local searchIndex = {}
			local switchGen = 0

			local function restorePage(tb)
				if tb.ActiveTweens then
					for _, tw in ipairs(tb.ActiveTweens) do
						pcall(function()
							tw:Cancel()
						end)
					end
				end
				tb.ActiveTweens = nil
				if tb.LastCache then
					for _, e in ipairs(tb.LastCache) do
						if e.inst and e.inst.Parent then
							e.inst[e.prop] = e.value
						end
					end
				end
				tb.LastCache = nil
			end

			local function setActiveTab(t)
				if activeTab == t then
					return
				end
				closeOverlay()
				switchGen = switchGen + 1
				local gen = switchGen
				local old = activeTab
				local oi, ni = 0, 0
				for i, tb in ipairs(tabs) do
					if tb == old then
						oi = i
					end
					if tb == t then
						ni = i
					end
				end
				local dir = (oi ~= 0 and ni < oi) and -1 or 1
				if old then
					restorePage(old)
					old.Page.Visible = false
					local oldProp = old.NavIcon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
					tween(old.NavIcon, { [oldProp] = Theme.TextDim }, 0.14)
					tween(old.NavLabel, { TextColor3 = Theme.TextDim }, 0.14)
				end
				activeTab = t
				local tProp = t.NavIcon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
				tween(t.NavIcon, { [tProp] = Theme.Accent }, 0.14)
				tween(t.NavLabel, { TextColor3 = Theme.TextWhite }, 0.14)
				restorePage(t)
				local cache = collectFade(t.Page)
				t.LastCache = cache
				t.ActiveTweens = {}
				for _, e in ipairs(cache) do
					e.inst[e.prop] = 1
				end
				t.Page.Position = UDim2.new(0, dir * 26, 0, 0)
				t.Page.Visible = true
				t.ActiveTweens[#t.ActiveTweens + 1] =
					tween(t.Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)
				local byGroup = {}
				for _, e in ipairs(cache) do
					local box
					for _, gr in ipairs(t.Groups) do
						if e.inst == gr.Box or e.inst:IsDescendantOf(gr.Box) then
							box = gr.Box
							break
						end
					end
					byGroup[box or t.Page] = byGroup[box or t.Page] or {}
					table.insert(byGroup[box or t.Page], e)
				end
				for gi, gr in ipairs(t.Groups) do
					local entries = byGroup[gr.Box]
					if entries then
						task.delay(0.02 + gi * 0.03, function()
							if switchGen ~= gen or not t.ActiveTweens then
								return
							end
							for _, e in ipairs(entries) do
								t.ActiveTweens[#t.ActiveTweens + 1] =
									tween(e.inst, { [e.prop] = e.value }, 0.2, Enum.EasingStyle.Quad)
							end
						end)
					end
				end
				local loose = byGroup[t.Page]
				if loose then
					for _, e in ipairs(loose) do
						t.ActiveTweens[#t.ActiveTweens + 1] =
							tween(e.inst, { [e.prop] = e.value }, 0.18, Enum.EasingStyle.Quad)
					end
				end
				task.delay(0.02 + #t.Groups * 0.03 + 0.24, function()
					if switchGen == gen then
						t.ActiveTweens = nil
						t.LastCache = nil
					end
				end)
			end

			function self.Tab(name, topts)
				topts = topts or {}
				local tab = {}
				tab.Name = name
				local nav = make("Frame", {
					Name = "Nav_" .. name,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, navX, 0.5, 0),
					Size = UDim2.new(0, 30, 1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Parent = topbar,
				})
				local _iconMap = {
					crosshair = "\u{2295}",
					eye = "\u{25ce}",
					circle = "\u{25cf}",
					search = "\u{2299}",
					globe = "\u{25c9}",
					settings = "\u{2699}",
					grid = "\u{229e}",
					shield = "\u{25c8}",
					wrench = "\u{2692}",
				}
				local isImage = false
				local imageId = nil
				local iconChar = ""
				if topts.icon then
					local str = tostring(topts.icon)
					if
						string.match(str, "^%d+$")
						or string.find(str, "rbxassetid://") == 1
						or string.find(str, "rbxthumb://") == 1
					then
						isImage = true
						if string.match(str, "^%d+$") then
							imageId = "rbxthumb://type=Asset&id=" .. str .. "&w=150&h=150"
						else
							imageId = str
						end
					else
						iconChar = _iconMap[string.lower(str)] or ""
					end
				end
				local navIcon
				if isImage then
					navIcon = make("ImageLabel", {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(0, 14, 0, 14),
						BackgroundTransparency = 1,
						Image = imageId,
						ImageColor3 = Theme.TextDim,
						ScaleType = Enum.ScaleType.Fit,
						Parent = nav,
					})
				else
					navIcon = make("TextLabel", {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(0, 16, 0, 16),
						BackgroundTransparency = 1,
						Text = iconChar,
						TextSize = 13,
						TextColor3 = Theme.TextDim,
						Font = FONT_MED,
						Parent = nav,
					})
				end
				local hasIcon = isImage or iconChar ~= ""
				if not hasIcon then
					navIcon.Visible = false
					navIcon.Size = UDim2.new(0, 0, 0, 0)
				end
				local navLbl = make("TextLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, hasIcon and 20 or 0, 0.5, 0),
					Size = UDim2.new(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Font = FONT_MED,
					Text = name,
					TextSize = TEXT,
					TextColor3 = Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = nav,
				})
				navX = navX
					+ (hasIcon and 20 or 0)
					+ math.max(40, navLbl.TextBounds.X ~= 0 and navLbl.TextBounds.X or (#name * 7))
					+ 26
				local page = make("ScrollingFrame", {
					Name = "Page_" .. name,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.ControlBorder,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					Visible = false,
					Parent = content,
				})
				local colL = make("Frame", {
					Name = "ColLeft",
					Position = UDim2.new(0, MARGIN, 0, 12),
					Size = UDim2.new(0, COL_W, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = page,
				})
				make("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, COL_GAP),
					Parent = colL,
				})
				local colR = make("Frame", {
					Name = "ColRight",
					Position = UDim2.new(0, MARGIN + COL_W + COL_GAP, 0, 12),
					Size = UDim2.new(0, COL_W, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = page,
				})
				make("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, COL_GAP),
					Parent = colR,
				})
				make("UIPadding", {
					PaddingBottom = UDim.new(0, 14),
					Parent = page,
				})
				tab.Page = page
				tab.NavIcon = navIcon
				tab.NavLabel = navLbl
				tab.ColL = colL
				tab.ColR = colR
				tab.Groups = {}
				nav.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						setActiveTab(tab)
					end
				end)
				nav.MouseEnter:Connect(function()
					if activeTab ~= tab then
						local prop = navIcon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
						tween(navIcon, { [prop] = Theme.TextMid }, 0.1)
						tween(navLbl, { TextColor3 = Theme.TextMid }, 0.1)
					end
				end)
				nav.MouseLeave:Connect(function()
					if activeTab ~= tab then
						local prop = navIcon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
						tween(navIcon, { [prop] = Theme.TextDim }, 0.1)
						tween(navLbl, { TextColor3 = Theme.TextDim }, 0.1)
					end
				end)
				function tab.Group(gname, gopts)
					gopts = gopts or {}
					local group = {}
					local side = gopts.side
					if side ~= "left" and side ~= "right" then
						local nl, nr = 0, 0
						for _, gr in ipairs(tab.Groups) do
							if gr.Side == "left" then
								nl = nl + 1
							else
								nr = nr + 1
							end
						end
						side = (nl <= nr) and "left" or "right"
					end
					local parentCol = (side == "left") and colL or colR
					local box = make("Frame", {
						Name = "Group_" .. gname,
						Size = UDim2.new(1, 0, 0, HEAD_H),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = Theme.PanelBg,
						BorderSizePixel = 0,
						Parent = parentCol,
					})
					corner(box, 12)
					stroke(box, Color3.fromRGB(55, 55, 66), 0.5)
					local head = make("Frame", {
						Name = "Head",
						Size = UDim2.new(1, 0, 0, HEAD_H),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Parent = box,
					})
					make("Frame", {
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.new(0, 10, 1, 0),
						Size = UDim2.new(1, -20, 0, 1),
						BackgroundColor3 = Color3.fromRGB(55, 55, 66),
						BackgroundTransparency = 0.6,
						BorderSizePixel = 0,
						Parent = head,
					})
					local stripesAsset = nil
					if stripesAsset then
						make("ImageLabel", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Image = stripesAsset,
							ScaleType = Enum.ScaleType.Tile,
							TileSize = UDim2.new(0, 24, 0, 24),
							ImageTransparency = 0.45,
							ZIndex = 2,
							Parent = head,
						})
					end
					make("TextLabel", {
						Position = UDim2.new(0, 10, 0, 0),
						Size = UDim2.new(1, -50, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT_BOLD,
						Text = gname,
						TextSize = TEXT,
						TextColor3 = Theme.TextWhite,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 3,
						Parent = head,
					})
					local body = make("Frame", {
						Name = "Body",
						Position = UDim2.new(0, 0, 0, HEAD_H),
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						Parent = box,
					})
					make("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4),
						Parent = body,
					})
					make("UIPadding", {
						PaddingTop = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 10),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						Parent = body,
					})
					group.Box = box
					group.Body = body
					group.Name = gname
					group.Side = side
					local elemOrder = 0
					local function nextOrder()
						elemOrder = elemOrder + 1
						return elemOrder
					end
					local function registerSearch(text, row)
						searchIndex[#searchIndex + 1] = {
							tab = tab,
							group = group,
							text = text,
							row = row,
						}
					end
					group._nextOrder = nextOrder
					group._registerSearch = registerSearch
					tab.Groups[#tab.Groups + 1] = group
					attachElements(group)
					return group
				end
				tab.Select = function()
					setActiveTab(tab)
				end
				tabs[#tabs + 1] = tab
				if not activeTab then
					setActiveTab(tab)
				end
				return tab
			end

			local function createGlow(parent, color, blur, transparency)
				LPS_ATTRIBUTES(VM(NONE))
				local ok, shadow = pcall(function()
					local s = Instance.new("UIShadow")
					s.BlurRadius = UDim.new(0, blur)
					s.Transparency = transparency
					s.Color = color
					s.ZIndex = -1
					s.Parent = parent
					return s
				end)
				if ok and shadow then
					return shadow
				end
				local img = Instance.new("ImageLabel")
				img.Name = "Glow"
				img.BackgroundTransparency = 1
				img.AnchorPoint = Vector2.new(0.5, 0.5)
				img.Position = UDim2.new(0.5, 0, 0.5, 0)
				img.Size = UDim2.new(1, blur * 2, 1, blur * 2)
				img.Image = "rbxassetid://6014261993"
				img.ScaleType = Enum.ScaleType.Slice
				img.SliceCenter = Rect.new(49, 49, 450, 450)
				img.ImageColor3 = color
				img.ImageTransparency = transparency
				img.ZIndex = math.max((parent.ZIndex or 1) - 1, 1)
				img.Parent = parent
				return img
			end

			local function tweenGlow(glow, info, targetTransparency)
				if not glow then return end
				if glow:IsA("UIShadow") then
					if info then
						TweenService:Create(glow, info, { Transparency = targetTransparency }):Play()
					else
						glow.Transparency = targetTransparency
					end
				elseif glow:IsA("ImageLabel") then
					if info then
						TweenService:Create(glow, info, { ImageTransparency = targetTransparency }):Play()
					else
						glow.ImageTransparency = targetTransparency
					end
				end
			end

			function attachElements(group)
				local body = group.Body
				local nextOrder = group._nextOrder
				local registerSearch = group._registerSearch
				local function baseRow(h)
					local row = make("Frame", {
						Size = UDim2.new(1, 0, 0, h),
						BackgroundTransparency = 1,
						LayoutOrder = nextOrder(),
						Parent = body,
					})
					return row
				end
				function group.Label(o)
					o = o or {}
					local row = baseRow(20)
					make("TextLabel", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT,
						Text = o.text or "",
						TextSize = TEXT,
						TextColor3 = Theme.TextMid,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						Parent = row,
					})
					return { Row = row }
				end
				function group.Toggle(o)
					o = o or {}
					local state = o.default and true or false
					local ch, cs, cv = 0, 1, 1
					local hasColor = o.color ~= nil
					if hasColor and typeof(o.color) == "Color3" then
						ch, cs, cv = o.color:ToHSV()
					end
					local row = baseRow(30)
					local lbl = make("TextLabel", {
						Size = UDim2.new(1, hasColor and -90 or -65, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT_MED,
						Text = o.text or "Toggle",
						TextSize = TEXT,
						TextColor3 = state and Theme.TextWhite or Theme.TextMid,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = row,
					})
					registerSearch(o.text or "Toggle", row)

					local track = make("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.fromOffset(50, 21),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Parent = row,
					})
					corner(track, 15)
					stroke(track, Color3.fromRGB(255, 255, 255), 0.85)

					local overlay = make("Frame", {
						Size = UDim2.fromScale(1, 1),
						Position = UDim2.fromScale(0, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						Parent = track,
					})
					corner(overlay, 15)
					make("UIGradient", {
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30)),
						}),
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(1, 0.35),
						}),
						Parent = overlay,
					})

					local indicator = make("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = state and UDim2.new(1, -28, 0.5, 0) or UDim2.new(1, -47, 0.5, 0),
						Size = UDim2.fromOffset(25, 17),
						BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 170),
						BackgroundTransparency = state and 0 or 0.6,
						BorderSizePixel = 0,
						ZIndex = 5,
						Parent = track,
					})
					corner(indicator, 999)
					local indicatorStroke = stroke(indicator, Color3.fromRGB(255, 255, 255), state and 0 or 0.7)
					local indicatorGlow = createGlow(indicator, Color3.fromRGB(255, 255, 255), 20, state and 0.05 or 1)

					local swatch
					if hasColor then
						swatch = make("Frame", {
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, -58, 0.5, 0),
							Size = UDim2.new(0, 24, 0, 16),
							BackgroundColor3 = Color3.fromHSV(ch, cs, cv),
							BorderSizePixel = 0,
							Parent = row,
						})
						corner(swatch, 4)
						stroke(swatch, Color3.fromRGB(255, 255, 255), 0.75)
					end

					local function paint(animate)
						local info = animate and TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out) or nil
						if state then
							if info then
								TweenService:Create(indicator, info, {
									Position = UDim2.new(1, -28, 0.5, 0),
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BackgroundTransparency = 0,
								}):Play()
								TweenService:Create(indicatorStroke, info, {
									Color = Color3.fromRGB(255, 255, 255),
									Transparency = 0,
								}):Play()
								tweenGlow(indicatorGlow, info, 0.05)
								tween(lbl, { TextColor3 = Theme.TextWhite }, 0.2)
							else
								indicator.Position = UDim2.new(1, -28, 0.5, 0)
								indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
								indicator.BackgroundTransparency = 0
								indicatorStroke.Color = Color3.fromRGB(255, 255, 255)
								indicatorStroke.Transparency = 0
								tweenGlow(indicatorGlow, nil, 0.05)
								lbl.TextColor3 = Theme.TextWhite
							end
						else
							if info then
								TweenService:Create(indicator, info, {
									Position = UDim2.new(1, -47, 0.5, 0),
									BackgroundColor3 = Color3.fromRGB(160, 160, 170),
									BackgroundTransparency = 0.6,
								}):Play()
								TweenService:Create(indicatorStroke, info, {
									Color = Color3.fromRGB(255, 255, 255),
									Transparency = 0.7,
								}):Play()
								tweenGlow(indicatorGlow, info, 1)
								tween(lbl, { TextColor3 = Theme.TextMid }, 0.2)
							else
								indicator.Position = UDim2.new(1, -47, 0.5, 0)
								indicator.BackgroundColor3 = Color3.fromRGB(160, 160, 170)
								indicator.BackgroundTransparency = 0.6
								indicatorStroke.Color = Color3.fromRGB(255, 255, 255)
								indicatorStroke.Transparency = 0.7
								tweenGlow(indicatorGlow, nil, 1)
								lbl.TextColor3 = Theme.TextMid
							end
						end
					end
					paint(false)

					local function currentColor()
						return Color3.fromHSV(ch, cs, cv)
					end
					local function push(silent)
						if o.flag then
							Tempus.Flags[o.flag] = state
						end
						if hasColor and o.colorFlag then
							Tempus.Flags[o.colorFlag] = currentColor()
						end
						if not silent and o.callback then
							task.spawn(o.callback, state)
						end
					end
					local function set(v, silent)
						v = v and true or false
						if v == state then
							return
						end
						state = v
						paint(true)
						push(silent)
					end

					row.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							if swatch then
								local x, y = input.Position.X, input.Position.Y
								local sp, ss = swatch.AbsolutePosition, swatch.AbsoluteSize
								if x >= sp.X and x <= sp.X + ss.X and y >= sp.Y and y <= sp.Y + ss.Y then
									return
								end
							end
							task.spawn(function()
								TweenService:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
									Size = UDim2.fromOffset(47, 19)
								}):Play()
								task.wait(0.09)
								TweenService:Create(track, TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
									Size = UDim2.fromOffset(50, 21)
								}):Play()
							end)
							set(not state)
						end
					end)

					row.MouseEnter:Connect(function()
						if not state then
							tween(lbl, { TextColor3 = Theme.TextBright }, 0.15)
						end
					end)
					row.MouseLeave:Connect(function()
						if not state then
							tween(lbl, { TextColor3 = Theme.TextMid }, 0.15)
						end
					end)

					if swatch then
						swatch.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								openHuePopup(swatch, function()
									return ch
								end, function(h)
									ch, cs, cv = h, 1, 1
									local col = currentColor()
									swatch.BackgroundColor3 = col
									if o.colorFlag then
										Tempus.Flags[o.colorFlag] = col
									end
									if o.colorCallback then
										task.spawn(o.colorCallback, col)
									end
								end)
							end
						end)
					end
					push(true)
					bindFlag(o.flag, function(v)
						set(v, false)
					end, function()
						return state
					end)
					if hasColor and o.colorFlag then
						bindFlag(o.colorFlag, function(v)
							if typeof(v) == "Color3" then
								ch, cs, cv = v:ToHSV()
								swatch.BackgroundColor3 = currentColor()
							end
						end, currentColor)
					end
					return {
						Row = row,
						Set = set,
						Get = function()
							return state
						end,
						SetColor = hasColor and function(c)
							ch, cs, cv = c:ToHSV()
							swatch.BackgroundColor3 = currentColor()
						end or nil,
						GetColor = hasColor and currentColor or nil,
					}
				end
				function group.Keybind(o)
					o = o or {}
					local key = o.default
					local mode = o.mode or "Toggle"
					local listening = false
					local held = false
					local row = baseRow(22)
					local lbl = make("TextLabel", {
						Size = UDim2.new(1, -80, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT,
						Text = o.text or "Keybind",
						TextSize = TEXT,
						TextColor3 = Theme.TextDim,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = row,
					})
					registerSearch(o.text or "Keybind", row)
					local keyLbl = make("TextLabel", {
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, 0, 0, 0),
						Size = UDim2.new(0, 120, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT_MED,
						Text = "[ " .. keyName(key) .. " ]",
						TextSize = TEXT,
						TextColor3 = Theme.TextDim,
						TextXAlignment = Enum.TextXAlignment.Right,
						Parent = row,
					})
					local function stopListening()
						listening = false
						keyLbl.Text = "[ " .. keyName(key) .. " ]"
						tween(keyLbl, { TextColor3 = Theme.TextDim }, 0.1)
					end
					local function applyKey(kc)
						key = kc
						keyLbl.Text = "[ " .. keyName(key) .. " ]"
						if o.flag then
							Tempus.Flags[o.flag] = key and key.Name or "None"
						end
					end
					row.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							if keybindListenCancel then
								keybindListenCancel()
							end
							keybindListenCancel = stopListening
							anyListening = true
							listening = true
							keyLbl.Text = "[ ... ]"
							tween(keyLbl, { TextColor3 = Theme.Accent }, 0.1)
						end
					end)
					local function push(state)
						if o.callback then
							task.spawn(o.callback, state, key)
						end
					end
					trackConn(UserInputService.InputBegan:Connect(function(input, processed)
						if listening and not processed then
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								return
							end
							if input.KeyCode == Enum.KeyCode.Escape then
								key = nil
							elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
								key = input.UserInputType
							elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
								key = input.KeyCode
							else
								return
							end
							keybindListenCancel = nil
							stopListening()
							task.defer(function()
								anyListening = false
							end)
							if o.flag then
								Tempus.Flags[o.flag] = key and key.Name or "None"
							end
							if o.changed then
								task.spawn(o.changed, key)
							end
							return
						end
						if processed or listening or anyListening then
							return
						end
						if key and (input.KeyCode == key or input.UserInputType == key) then
							if mode == "Hold" then
								held = true
								push(true)
							else
								push(true)
							end
						end
					end))
					trackConn(UserInputService.InputEnded:Connect(function(input)
						if mode == "Hold" and key and (input.KeyCode == key or input.UserInputType == key) and held then
							held = false
							push(false)
						end
					end))
					if o.flag then
						Tempus.Flags[o.flag] = key and key.Name or "None"
					end
					bindFlag(o.flag, function(v)
						if type(v) == "string" and v ~= "None" then
							local ok, kc = pcall(function()
								return Enum.KeyCode[v] or Enum.UserInputType[v]
							end)
							applyKey(ok and kc or nil)
						else
							applyKey(nil)
						end
					end, function()
						return key and key.Name or "None"
					end)
					return {
						Row = row,
						Set = applyKey,
						Get = function()
							return key
						end,
					}
				end
				function group.Slider(o)
					o = o or {}
					local min = o.min or 0
					local max = o.max or 100
					local step = o.step or 1
					local decimals = o.decimals
					if decimals == nil then
						decimals = (step % 1 ~= 0) and 2 or 0
					end
					local value = math.clamp(o.default or min, min, max)
					local row = baseRow(50)

					local lbl = make("TextLabel", {
						Size = UDim2.new(1, -80, 0, 16),
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						Font = FONT_MED,
						Text = o.text or "Slider",
						TextSize = TEXT,
						TextColor3 = Theme.TextBright,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = row,
					})
					registerSearch(o.text or "Slider", row)

					local valueLbl = make("TextLabel", {
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, 0, 0, 0),
						Size = UDim2.new(0, 75, 0, 16),
						BackgroundTransparency = 1,
						Font = FONT_MED,
						Text = "",
						TextSize = TEXT,
						TextColor3 = Theme.TextBright,
						TextXAlignment = Enum.TextXAlignment.Right,
						Parent = row,
					})

					local track = make("Frame", {
						Position = UDim2.new(0, 0, 0, 26),
						Size = UDim2.new(1, 0, 0, 12),
						BackgroundColor3 = Color3.fromRGB(22, 22, 28),
						BorderSizePixel = 0,
						Parent = row,
					})
					corner(track, 999)
					stroke(track, Color3.fromRGB(255, 255, 255), 0.85)

					local progress = make("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.fromScale(0, 1),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = 2,
						Parent = track,
					})
					corner(progress, 999)

					make("UIGradient", {
						Offset = Vector2.new(0, 0.5),
						Rotation = 2,
						Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(195, 195, 210)),
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0.85),
							NumberSequenceKeypoint.new(1, 0),
						}),
						Parent = progress,
					})

					local handleRest = Vector2.new(35, 20)
					local handleHeld = Vector2.new(41, 22)
					local handleWidth = handleRest.X

					local handle = make("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0, handleRest.X / 2 - 2, 0.5, 0),
						Size = UDim2.fromOffset(handleRest.X, handleRest.Y),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						ZIndex = 50,
						Parent = track,
					})
					corner(handle, 999)
					createGlow(handle, Color3.fromRGB(255, 255, 255), 10, 0.55)
					local handleStroke = stroke(handle, Color3.fromRGB(255, 255, 255), 1)

					local function fmt(v)
						local s
						if decimals > 0 then
							s = string.format("%." .. decimals .. "f", v)
						else
							s = tostring(math.floor(v + 0.5))
						end
						return s .. (o.suffix or "")
					end

					local function renderProgress(info)
						LPS_ATTRIBUTES(VM(NONE))
						local span = max - min
						local ratio = (span ~= 0) and math.clamp((value - min) / span, 0, 1) or 0
						local size = UDim2.new(ratio, 0, 1, 0)
						local hOffset = (1 - 2 * ratio) * (handleWidth / 2 - 2)
						local hPos = UDim2.new(ratio, hOffset, 0.5, 0)
						valueLbl.Text = fmt(value)
						if info then
							TweenService:Create(progress, info, { Size = size }):Play()
							TweenService:Create(handle, info, { Position = hPos }):Play()
						else
							progress.Size = size
							handle.Position = hPos
						end
					end

					local function setHeld(held)
						local target = held and handleHeld or handleRest
						handleWidth = target.X
						local heldInfo = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
						TweenService:Create(handle, heldInfo, {
							Size = UDim2.fromOffset(target.X, target.Y),
							BackgroundTransparency = held and 0.7 or 0,
						}):Play()
						TweenService:Create(handleStroke, heldInfo, {
							Transparency = held and 0.6 or 1,
						}):Play()
						renderProgress(heldInfo)
					end

					local function set(v, silent, info)
						v = math.clamp(v, min, max)
						v = min + math.floor((v - min) / step + 0.5) * step
						v = math.clamp(v, min, max)
						if v == value then
							renderProgress(info)
							return
						end
						value = v
						renderProgress(info)
						if o.flag then
							Tempus.Flags[o.flag] = value
						end
						if not silent and o.callback then
							task.spawn(o.callback, value)
						end
					end

					local hoverInfo = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
					row.MouseEnter:Connect(function()
						TweenService:Create(track, hoverInfo, { BackgroundColor3 = Color3.fromRGB(30, 30, 38) }):Play()
					end)
					row.MouseLeave:Connect(function()
						TweenService:Create(track, hoverInfo, { BackgroundColor3 = Color3.fromRGB(22, 22, 28) }):Play()
					end)

					local dragging = false
					local followInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					local function fromX(x)
						local travel = math.max(track.AbsoluteSize.X, 1)
						local ratio = math.clamp((x - track.AbsolutePosition.X) / travel, 0, 1)
						local snapped = min + math.round((ratio * (max - min)) / step) * step
						set(snapped, false, followInfo)
					end

					row.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragging = true
							setHeld(true)
							fromX(input.Position.X)
						end
					end)
					trackConn(UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							if dragging then
								dragging = false
								setHeld(false)
							end
						end
					end))
					trackConn(UserInputService.InputChanged:Connect(function(input)
						if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							fromX(input.Position.X)
						end
					end))

					renderProgress(nil)
					if o.flag then
						Tempus.Flags[o.flag] = value
					end
					bindFlag(o.flag, function(v)
						set(v, false, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
					end, function()
						return value
					end)
					return {
						Row = row,
						Set = set,
						Get = function()
							return value
						end,
					}
				end
				function group.Dropdown(o)
					o = o or {}
					local options = o.options or {}
					local multi = o.multi and true or false
					local selected
					local selectedSet = {}
					if multi then
						for _, v in ipairs(o.default or {}) do
							selectedSet[v] = true
						end
					else
						selected = o.default or options[1]
					end
					local row = baseRow(26)
					local lbl = make("TextLabel", {
						Size = UDim2.new(1, -130, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT_MED,
						Text = o.text or "Dropdown",
						TextSize = TEXT,
						TextColor3 = Theme.TextBright,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = row,
					})
					registerSearch(o.text or "Dropdown", row)
					local chevBtn = make("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 22, 0, 22),
						BackgroundColor3 = Theme.ControlBg,
						BorderSizePixel = 0,
						Parent = row,
					})
					corner(chevBtn, 3)
					local chev = make("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Size = UDim2.new(0, 11, 0, 11),
						BackgroundTransparency = 1,
						ImageColor3 = Theme.TextMid,
						ScaleType = Enum.ScaleType.Fit,
						Parent = chevBtn,
					})
					applyIcon(chev, resolveIcon("chevron-down"))
					local valBtn = make("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -24, 0.5, 0),
						Size = UDim2.new(0, 86, 0, 22),
						BackgroundColor3 = Theme.ControlBg,
						BorderSizePixel = 0,
						Parent = row,
					})
					corner(valBtn, 3)
					local valLbl = make("TextLabel", {
						Size = UDim2.new(1, -8, 1, 0),
						Position = UDim2.new(0, 4, 0, 0),
						BackgroundTransparency = 1,
						Font = FONT,
						Text = "",
						TextSize = 12,
						TextColor3 = Theme.TextBright,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Parent = valBtn,
					})
					local function current()
						if multi then
							local parts = {}
							for _, opt in ipairs(options) do
								if selectedSet[opt] then
									parts[#parts + 1] = opt
								end
							end
							return parts
						end
						return selected
					end
					local function paintValue()
						if multi then
							local parts = current()
							valLbl.Text = #parts > 0 and table.concat(parts, ", ") or "None"
						else
							valLbl.Text = tostring(selected or "None")
						end
					end
					local function push(silent)
						if o.flag then
							Tempus.Flags[o.flag] = current()
						end
						if not silent and o.callback then
							task.spawn(o.callback, current())
						end
					end
					local open = false
					local function openList()
						open = true
						tween(chev, { Rotation = 180 }, 0.15)
						openOverlay(function(root)
							local wp = win.AbsolutePosition
							local bp = valBtn.AbsolutePosition
							local listW = 130
							local listH = math.min(#options, 8) * 24 + 8
							local x = bp.X - wp.X + valBtn.AbsoluteSize.X - listW + 24
							local y = bp.Y - wp.Y + valBtn.AbsoluteSize.Y + 4
							if y + listH > WIN_H - FOOTER_H then
								y = bp.Y - wp.Y - listH - 4
							end
							local list = make("ScrollingFrame", {
								Position = UDim2.new(0, x, 0, y),
								Size = UDim2.new(0, listW, 0, listH),
								BackgroundColor3 = Theme.ControlBg,
								BorderSizePixel = 0,
								ScrollBarThickness = 2,
								ScrollBarImageColor3 = Theme.ControlBorder,
								AutomaticCanvasSize = Enum.AutomaticSize.Y,
								CanvasSize = UDim2.new(0, 0, 0, 0),
								ZIndex = 52,
								Parent = root,
							})
							corner(list, 3)
							stroke(list, Theme.ControlBorder, 0.2)
							make("UIListLayout", {
								SortOrder = Enum.SortOrder.LayoutOrder,
								Parent = list,
							})
							make("UIPadding", {
								PaddingTop = UDim.new(0, 4),
								PaddingBottom = UDim.new(0, 4),
								Parent = list,
							})
							for i, opt in ipairs(options) do
								local item = make("TextButton", {
									Size = UDim2.new(1, 0, 0, 24),
									BackgroundTransparency = 1,
									Text = "",
									AutoButtonColor = false,
									LayoutOrder = i,
									ZIndex = 53,
									Parent = list,
								})
								local on = multi and selectedSet[opt] or (opt == selected)
								local il = make("TextLabel", {
									Position = UDim2.new(0, 10, 0, 0),
									Size = UDim2.new(1, -20, 1, 0),
									BackgroundTransparency = 1,
									Font = FONT,
									Text = opt,
									TextSize = 12,
									TextColor3 = on and Theme.Accent or Theme.TextMid,
									TextXAlignment = Enum.TextXAlignment.Left,
									ZIndex = 53,
									Parent = item,
								})
								item.MouseEnter:Connect(function()
									local sel = multi and selectedSet[opt] or (opt == selected)
									if not sel then
										tween(il, { TextColor3 = Theme.TextBright }, 0.1)
									end
								end)
								item.MouseLeave:Connect(function()
									local sel = multi and selectedSet[opt] or (opt == selected)
									if not sel then
										tween(il, { TextColor3 = Theme.TextMid }, 0.1)
									end
								end)
								item.MouseButton1Click:Connect(function()
									if multi then
										selectedSet[opt] = not selectedSet[opt] or nil
										local sel = selectedSet[opt]
										tween(il, { TextColor3 = sel and Theme.Accent or Theme.TextMid }, 0.1)
										paintValue()
										push(false)
									else
										selected = opt
										paintValue()
										push(false)
										closeOverlay()
									end
								end)
							end
						end, function()
							open = false
							tween(chev, { Rotation = 0 }, 0.15)
						end)
					end
					local function clickOpen(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							if open then
								closeOverlay()
							else
								openList()
							end
						end
					end
					valBtn.InputBegan:Connect(clickOpen)
					chevBtn.InputBegan:Connect(clickOpen)
					paintValue()
					push(true)
					bindFlag(o.flag, function(v)
						if multi and type(v) == "table" then
							selectedSet = {}
							for _, x in ipairs(v) do
								selectedSet[x] = true
							end
						elseif not multi then
							selected = v
						end
						paintValue()
						push(false)
					end, current)
					return {
						Row = row,
						Set = function(v)
							if multi and type(v) == "table" then
								selectedSet = {}
								for _, x in ipairs(v) do
									selectedSet[x] = true
								end
							elseif not multi then
								selected = v
							end
							paintValue()
							push(false)
						end,
						Get = current,
					}
				end
				function group.Color(o)
					o = o or {}
					local ch, cs, cv = 0, 1, 1
					if typeof(o.default) == "Color3" then
						ch, cs, cv = o.default:ToHSV()
					end
					local row = baseRow(22)
					make("TextLabel", {
						Size = UDim2.new(1, -60, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT_MED,
						Text = o.text or "Color",
						TextSize = TEXT,
						TextColor3 = Theme.TextBright,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = row,
					})
					registerSearch(o.text or "Color", row)
					local swatch = make("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 24, 0, 14),
						BackgroundColor3 = Color3.fromHSV(ch, cs, cv),
						BorderSizePixel = 0,
						Parent = row,
					})
					corner(swatch, 2)
					stroke(swatch, Theme.ControlBorder, 0.2)
					local function color()
						return Color3.fromHSV(ch, cs, cv)
					end
					local function push(silent)
						if o.flag then
							Tempus.Flags[o.flag] = color()
						end
						if not silent and o.callback then
							task.spawn(o.callback, color())
						end
					end
					swatch.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							openHuePopup(swatch, function()
								return ch
							end, function(h)
								ch, cs, cv = h, 1, 1
								swatch.BackgroundColor3 = color()
								push(false)
							end)
						end
					end)
					push(true)
					bindFlag(o.flag, function(v)
						if typeof(v) == "Color3" then
							ch, cs, cv = v:ToHSV()
							swatch.BackgroundColor3 = color()
							push(false)
						end
					end, color)
					return {
						Row = row,
						Set = function(c)
							ch, cs, cv = c:ToHSV()
							swatch.BackgroundColor3 = color()
							push(false)
						end,
						Get = color,
					}
				end
				function group.Button(o)
					o = o or {}
					local row = baseRow(28)
					local btn = make("Frame", {
						Size = UDim2.new(1, 0, 0, 24),
						Position = UDim2.new(0, 0, 0, 2),
						BackgroundColor3 = Theme.ControlBg,
						BorderSizePixel = 0,
						Parent = row,
					})
					corner(btn, 3)
					local btnStroke = stroke(btn, Theme.ControlBorder, 0.3)
					local lbl = make("TextLabel", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Font = FONT_MED,
						Text = o.text or "Button",
						TextSize = 12,
						TextColor3 = Theme.TextBright,
						Parent = btn,
					})
					registerSearch(o.text or "Button", row)
					btn.MouseEnter:Connect(function()
						tween(btnStroke, { Color = Theme.Accent, Transparency = 0.2 }, 0.12)
					end)
					btn.MouseLeave:Connect(function()
						tween(btnStroke, { Color = Theme.ControlBorder, Transparency = 0.3 }, 0.15)
					end)
					btn.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							tween(lbl, { TextColor3 = Theme.Accent }, 0.06)
							task.delay(0.12, function()
								tween(lbl, { TextColor3 = Theme.TextBright }, 0.2)
							end)
							if o.callback then
								task.spawn(o.callback)
							end
						end
					end)
					return { Row = row }
				end
			end

			function openHuePopup(anchor, getHue, setHue)
				openOverlay(function(root)
					local wp = win.AbsolutePosition
					local ap = anchor.AbsolutePosition
					local popW, popH = 170, 40
					local x = math.clamp(ap.X - wp.X + anchor.AbsoluteSize.X - popW, 8, WIN_W - popW - 8)
					local y = ap.Y - wp.Y + anchor.AbsoluteSize.Y + 6
					if y + popH > WIN_H - FOOTER_H then
						y = ap.Y - wp.Y - popH - 6
					end
					local pop = make("Frame", {
						Position = UDim2.new(0, x, 0, y),
						Size = UDim2.new(0, popW, 0, popH),
						BackgroundColor3 = Theme.ControlBg,
						BorderSizePixel = 0,
						ZIndex = 52,
						Parent = root,
					})
					corner(pop, 3)
					stroke(pop, Theme.ControlBorder, 0.2)
					local rail = make("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Size = UDim2.new(1, -20, 0, 10),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						ZIndex = 53,
						Parent = pop,
					})
					corner(rail, 3)
					make("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
							ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
							ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
							ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
							ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
							ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
							ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
						}),
						Parent = rail,
					})
					local knob = make("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(getHue(), 0, 0.5, 0),
						Size = UDim2.new(0, 6, 0, 14),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						ZIndex = 54,
						Parent = rail,
					})
					corner(knob, 2)
					stroke(knob, Color3.fromRGB(20, 20, 22), 0)
					local dragging = false
					local function fromX(px)
						local a = math.clamp((px - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
						knob.Position = UDim2.new(a, 0, 0.5, 0)
						setHue(a)
					end
					pop.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true
							fromX(input.Position.X)
						end
					end)
					local moveConn = UserInputService.InputChanged:Connect(function(input)
						if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							fromX(input.Position.X)
						end
					end)
					local upConn = UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
						end
					end)
					popupCleanup = function()
						pcall(function()
							moveConn:Disconnect()
						end)
						pcall(function()
							upConn:Disconnect()
						end)
					end
				end, function()
					if popupCleanup then
						popupCleanup()
						popupCleanup = nil
					end
				end)
			end
			local searchToken = 0
			local searchOpenFlag = false

			local function flashRow(row)
				local hl = make("Frame", {
					Size = UDim2.new(1, 8, 1, 4),
					Position = UDim2.new(0, -4, 0, -2),
					BackgroundColor3 = Theme.Accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 0,
					Parent = row,
				})
				corner(hl, 3)
				task.spawn(function()
					for _ = 1, 2 do
						tween(hl, { BackgroundTransparency = 0.75 }, 0.16)
						task.wait(0.2)
						tween(hl, { BackgroundTransparency = 1 }, 0.22)
						task.wait(0.26)
					end
					hl:Destroy()
				end)
			end

			local function runSearch(q)
				q = string.lower(q or "")
				if q == "" then
					if searchOpenFlag then
						searchOpenFlag = false
						closeOverlay()
					end
					return
				end
				searchToken = searchToken + 1
				local myToken = searchToken
				local hits = {}
				for _, e in ipairs(searchIndex) do
					if
						string.find(string.lower(e.text), q, 1, true)
						or string.find(string.lower(e.group.Name), q, 1, true)
					then
						hits[#hits + 1] = e
						if #hits >= 8 then
							break
						end
					end
				end
				openOverlay(function(root)
					local listH = math.max(#hits, 1) * 26 + 8
					local list = make("Frame", {
						Position = UDim2.new(0, MARGIN + 56, 0, TOPBAR_H - 6),
						Size = UDim2.new(0, 240, 0, listH),
						BackgroundColor3 = Theme.ControlBg,
						BorderSizePixel = 0,
						ZIndex = 52,
						Parent = root,
					})
					corner(list, 3)
					stroke(list, Theme.ControlBorder, 0.2)
					make("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = list,
					})
					make("UIPadding", {
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
						Parent = list,
					})
					if #hits == 0 then
						make("TextLabel", {
							Size = UDim2.new(1, 0, 0, 26),
							BackgroundTransparency = 1,
							Font = FONT,
							Text = "No results",
							TextSize = 12,
							TextColor3 = Theme.TextDim,
							ZIndex = 53,
							Parent = list,
						})
					end
					for i, e in ipairs(hits) do
						local item = make("TextButton", {
							Size = UDim2.new(1, 0, 0, 26),
							BackgroundTransparency = 1,
							Text = "",
							AutoButtonColor = false,
							LayoutOrder = i,
							ZIndex = 53,
							Parent = list,
						})
						local il = make("TextLabel", {
							Position = UDim2.new(0, 10, 0, 0),
							Size = UDim2.new(1, -20, 1, 0),
							BackgroundTransparency = 1,
							Font = FONT,
							Text = e.tab.Name .. "  >  " .. e.group.Name .. "  >  " .. e.text,
							TextSize = 12,
							TextColor3 = Theme.TextMid,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextTruncate = Enum.TextTruncate.AtEnd,
							ZIndex = 53,
							Parent = item,
						})
						item.MouseEnter:Connect(function()
							tween(il, { TextColor3 = Theme.TextBright }, 0.1)
						end)
						item.MouseLeave:Connect(function()
							tween(il, { TextColor3 = Theme.TextMid }, 0.1)
						end)
						item.MouseButton1Click:Connect(function()
							searchOpenFlag = false
							searchBox.Text = ""
							closeOverlay()
							setActiveTab(e.tab)
							task.delay(0.05, function()
								local page = e.tab.Page
								local rowY = e.row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
								page.CanvasPosition = Vector2.new(0, math.max(0, rowY - 80))
								flashRow(e.row)
							end)
						end)
					end
				end, function()
					if myToken == searchToken then
						searchOpenFlag = false
					end
				end)
				searchOpenFlag = true
			end
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				runSearch(searchBox.Text)
			end)
			local menuVisible = false
			local fadeCache = nil
			local fadeLock = 0

			local function setMenuVisible(v)
				if v == menuVisible then
					return
				end
				if os.clock() < fadeLock then
					return
				end
				fadeLock = os.clock() + 0.2
				menuVisible = v
				if not v then
					closeOverlay()
					hideTooltip()
					fadeCache = collectFade(win)
					for _, e in ipairs(fadeCache) do
						tween(e.inst, { [e.prop] = 1 }, 0.14)
					end
					task.delay(0.15, function()
						if not menuVisible then
							win.Visible = false
						end
					end)
				else
					win.Visible = true
					if fadeCache then
						for _, e in ipairs(fadeCache) do
							tween(e.inst, { [e.prop] = e.value }, 0.16)
						end
					end
				end
			end

			function self.ToggleMenu()
				setMenuVisible(not menuVisible)
			end

			function self.SetMenuVisible(v)
				setMenuVisible(v and true or false)
			end

			function self.SetMenuKey(kc)
				menuKey = kc
				menuKeyLbl.Text = "Menu: " .. keyName(menuKey)
			end
			trackConn(UserInputService.InputBegan:Connect(function(input, processed)
				if processed or anyListening then
					return
				end
				if menuKey and input.KeyCode == menuKey then
					self.ToggleMenu()
				end
			end))

			self.Flags = Tempus.Flags
			self.Window = win
			return self
		end
		return Tempus
	end)()

	local espContainer = Instance.new("Folder")
	espContainer.Name = "SlateEspContainer"
	espContainer.Parent = (gethui and gethui()) or game:GetService("CoreGui")

	local EspConfig = {
		enabled = false,
		fill = true,
		fillTransparency = 0.55,
		outline = true,
		box = false,
		health = false,
		names = true,
		distance = true,
		skeleton = false,
		tracers = false,
		teamCheck = false,
		teamColor = false,
		maxDistance = 0,
		color = Color3.fromRGB(148, 40, 206),
	}
	local AimConfig = {
		enabled = false,
		mode = "Hold",
		key = Enum.UserInputType.MouseButton2,
		smoothing = true,
		smoothAmount = 0.18,
		smoothAmountX = 0.18,
		smoothAmountY = 0.18,
		perAxisSmooth = false,
		fov = 120,
		fovStyle = "Circle",
		showFov = true,
		fovFollow = true,
		targetPart = "Head",
		wallCheck = true,
		sticky = true,
		predict = false,
		predictAmount = 0.135,
		projectile = 0,
		priority = "Crosshair",
		maxTurn = 0,
		rage = false,
		aimDelay = 0,
		silentAim = false,
		triggerbot = false,
		triggerbotDelay = 0.05,
		aimTeamCheck = false,
		aimKnockedCheck = false,
		aimWeaponCheck = false,
	}

	local hasDrawing = false
	pcall(function()
		local probe = Drawing.new("Line")
		probe:Remove()
		hasDrawing = true
	end)
	local tags, boxes, bars, skels, tracers = {}, {}, {}, {}, {}
	local SKELETON_R15 = {
		{ "Head", "UpperTorso" },
		{ "UpperTorso", "LowerTorso" },
		{ "UpperTorso", "LeftUpperArm" },
		{ "LeftUpperArm", "LeftLowerArm" },
		{ "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" },
		{ "RightUpperArm", "RightLowerArm" },
		{ "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" },
		{ "LeftUpperLeg", "LeftLowerLeg" },
		{ "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" },
		{ "RightUpperLeg", "RightLowerLeg" },
		{ "RightLowerLeg", "RightFoot" },
	}
	local SKELETON_R6 = {
		{ "Head", "Torso" },
		{ "Torso", "Left Arm" },
		{ "Torso", "Right Arm" },
		{ "Torso", "Left Leg" },
		{ "Torso", "Right Leg" },
	}
	local function espOn()
		return EspConfig.enabled == true
	end
	local function distanceTo(char)
		local myChar = LocalPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not (myRoot and root) then
			return nil
		end
		return (root.Position - myRoot.Position).Magnitude
	end
	local function sameTeam(player)
		if not player.Team or not LocalPlayer.Team then
			return false
		end
		return player.Team == LocalPlayer.Team
	end
	local function colourFor(player)
		if EspConfig.teamColor and player.Team and player.TeamColor then
			return player.TeamColor.Color
		end
		return EspConfig.color
	end
	local function dropTag(n)
		if tags[n] then
			pcall(function() tags[n]:Destroy() end)
			tags[n] = nil
		end
	end
	local function dropBox(n)
		if boxes[n] then
			for _, ln in ipairs(boxes[n]) do
				pcall(function() ln:Remove() end)
			end
			boxes[n] = nil
		end
	end
	local function dropBar(n)
		if bars[n] then
			pcall(function() bars[n].gui:Destroy() end)
			bars[n] = nil
		end
	end
	local function dropSkel(n)
		if skels[n] then
			for _, ln in ipairs(skels[n]) do
				pcall(function() ln:Remove() end)
			end
			skels[n] = nil
		end
	end
	local function dropTracer(n)
		if tracers[n] then
			pcall(function() tracers[n]:Remove() end)
			tracers[n] = nil
		end
	end
	local function dropAll(n)
		dropTag(n)
		dropBox(n)
		dropBar(n)
		dropSkel(n)
		dropTracer(n)
	end
	local function updateTag(player, char, col)
		if not (EspConfig.names or EspConfig.distance) then
			dropTag(player.Name)
			return
		end
		local head = char and char:FindFirstChild("Head")
		if not head then
			dropTag(player.Name)
			return
		end
		local tag = tags[player.Name]
		if not tag or not tag.Parent then
			tag = Instance.new("BillboardGui")
			tag.Name = "SlateEspTag"
			tag.Size = UDim2.new(0, 220, 0, 20)
			tag.StudsOffset = Vector3.new(0, 2.8, 0)
			tag.AlwaysOnTop = true
			tag.Parent = espContainer
			local lbl = Instance.new("TextLabel", tag)
			lbl.Name = "L"
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.BuilderSansBold
			lbl.TextSize = 13
			lbl.TextStrokeTransparency = 0.4
			lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			tags[player.Name] = tag
		end
		tag.Adornee = head
		local lbl = tag:FindFirstChild("L")
		if lbl then
			local parts = {}
			if EspConfig.names then
				parts[#parts + 1] = player.DisplayName
			end
			if EspConfig.distance then
				local d = distanceTo(char)
				if d then
					parts[#parts + 1] = tostring(math.floor(d)) .. "m"
				end
			end
			lbl.Text = table.concat(parts, "  ")
			lbl.TextColor3 = col
		end
	end
	local function updateBar(player, char)
		if not EspConfig.health then
			dropBar(player.Name)
			return
		end
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (head and hum) then
			dropBar(player.Name)
			return
		end
		local rec = bars[player.Name]
		if not rec or not rec.gui.Parent then
			local g = Instance.new("BillboardGui")
			g.Name = "SlateEspHealth"
			g.Size = UDim2.new(0, 4, 0, 46)
			g.StudsOffset = Vector3.new(-2.4, 0.3, 0)
			g.AlwaysOnTop = true
			g.Parent = espContainer
			local bg = Instance.new("Frame", g)
			bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = Color3.fromRGB(12, 6, 20)
			bg.BorderSizePixel = 0
			Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
			local fg = Instance.new("Frame", bg)
			fg.Name = "F"
			fg.AnchorPoint = Vector2.new(0, 1)
			fg.Position = UDim2.new(0, 0, 1, 0)
			fg.Size = UDim2.new(1, 0, 1, 0)
			fg.BorderSizePixel = 0
			Instance.new("UICorner", fg).CornerRadius = UDim.new(1, 0)
			rec = { gui = g, fg = fg }
			bars[player.Name] = rec
		end
		rec.gui.Adornee = head
		local frac = 0
		if hum.MaxHealth > 0 then
			frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		end
		rec.fg.Size = UDim2.new(1, 0, frac, 0)
		rec.fg.BackgroundColor3 = Color3.fromRGB(214, 64, 82):Lerp(Color3.fromRGB(104, 214, 122), frac)
	end
	local function newLine()
		LPS_ATTRIBUTES(VM(NONE))
		local ln = Drawing.new("Line")
		ln.Thickness = 1
		ln.Transparency = 1
		return ln
	end
	local function hideBox(n)
		if boxes[n] then
			for _, ln in ipairs(boxes[n]) do
				ln.Visible = false
			end
		end
	end
	local function updateBox(player, char, col)
		if not (hasDrawing and EspConfig.box) then
			dropBox(player.Name)
			return
		end
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			hideBox(player.Name)
			return
		end
		local head = char:FindFirstChild("Head")
		local cam = workspace.CurrentCamera
		local topWorld = (head and head.Position or root.Position) + Vector3.new(0, 1.5, 0)
		local botWorld = root.Position - Vector3.new(0, 3.2, 0)
		local top, tv = cam:WorldToViewportPoint(topWorld)
		local bot, bv = cam:WorldToViewportPoint(botWorld)
		if not (tv and bv) then
			hideBox(player.Name)
			return
		end
		local y1, y2 = math.min(top.Y, bot.Y), math.max(top.Y, bot.Y)
		local h = y2 - y1
		if h < 4 then
			hideBox(player.Name)
			return
		end
		local w = h * 0.62
		local cx = (top.X + bot.X) / 2
		local x1, x2 = cx - w / 2, cx + w / 2
		local seg = math.clamp(math.min(w, h) * 0.3, 3, 26)
		local set = boxes[player.Name]
		if not set or #set < 8 then
			dropBox(player.Name)
			set = {}
			for i = 1, 8 do
				set[i] = newLine()
			end
			boxes[player.Name] = set
		end
		local pts = {
			{ x1, y1, x1 + seg, y1 },
			{ x1, y1, x1, y1 + seg },
			{ x2, y1, x2 - seg, y1 },
			{ x2, y1, x2, y1 + seg },
			{ x1, y2, x1 + seg, y2 },
			{ x1, y2, x1, y2 - seg },
			{ x2, y2, x2 - seg, y2 },
			{ x2, y2, x2, y2 - seg },
		}
		for i, p in ipairs(pts) do
			local ln = set[i]
			ln.From = Vector2.new(p[1], p[2])
			ln.To = Vector2.new(p[3], p[4])
			ln.Color = col
			ln.Thickness = 1.6
			ln.Visible = true
		end
	end
	local function hideSkel(n)
		if skels[n] then
			for _, ln in ipairs(skels[n]) do
				ln.Visible = false
			end
		end
	end
	local function hideTracer(n)
		if tracers[n] then
			tracers[n].Visible = false
		end
	end
	local function updateSkeleton(player, char, col)
		if not (hasDrawing and EspConfig.skeleton) then
			dropSkel(player.Name)
			return
		end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			hideSkel(player.Name)
			return
		end
		local pairsList = (hum.RigType == Enum.HumanoidRigType.R15) and SKELETON_R15 or SKELETON_R6
		local set = skels[player.Name]
		if not set or #set < #pairsList then
			dropSkel(player.Name)
			set = {}
			for _ = 1, #pairsList do
				set[#set + 1] = newLine()
			end
			skels[player.Name] = set
		end
		local cam = workspace.CurrentCamera
		for i, joint in ipairs(pairsList) do
			local a = char:FindFirstChild(joint[1])
			local b = char:FindFirstChild(joint[2])
			local ln = set[i]
			if a and b and ln then
				local pa, va = cam:WorldToViewportPoint(a.Position)
				local pb, vb = cam:WorldToViewportPoint(b.Position)
				if va and vb then
					ln.From = Vector2.new(pa.X, pa.Y)
					ln.To = Vector2.new(pb.X, pb.Y)
					ln.Color = col
					ln.Visible = true
				else
					ln.Visible = false
				end
			elseif ln then
				ln.Visible = false
			end
		end
	end
	local function updateTracer(player, char, col)
		if not (hasDrawing and EspConfig.tracers) then
			dropTracer(player.Name)
			return
		end
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			hideTracer(player.Name)
			return
		end
		local ln = tracers[player.Name]
		if not ln then
			ln = newLine()
			tracers[player.Name] = ln
		end
		local cam = workspace.CurrentCamera
		local pos, vis = cam:WorldToViewportPoint(root.Position)
		if vis then
			ln.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
			ln.To = Vector2.new(pos.X, pos.Y)
			ln.Color = col
			ln.Visible = true
		else
			ln.Visible = false
		end
	end
	local espWasOn = true
	local function EspRefresh()
		local on = espOn()
		if not on and not espWasOn then
			return
		end
		espWasOn = on
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local name = player.Name
				local char = player.Character
				local hl = espContainer:FindFirstChild(name)
				if on and not hl then
					hl = Instance.new("Highlight")
					hl.Name = name
					hl.Enabled = false
					hl.Parent = espContainer
				end
				local show = on
				if show and EspConfig.teamCheck and sameTeam(player) then
					show = false
				end
				if show and EspConfig.maxDistance > 0 then
					local d = distanceTo(char)
					if d and d > EspConfig.maxDistance then
						show = false
					end
				end
				local col = colourFor(player)
				if hl and hl:IsA("Highlight") then
					hl.Adornee = char
					hl.Enabled = show and char ~= nil
					hl.FillColor = col
					hl.OutlineColor = col:Lerp(Color3.fromRGB(255, 255, 255), 0.45)
					hl.FillTransparency = EspConfig.fill and EspConfig.fillTransparency or 1
					hl.OutlineTransparency = EspConfig.outline and 0 or 1
				end
				if show and char then
					updateTag(player, char, col)
					updateBar(player, char)
					updateSkeleton(player, char, col)
					updateTracer(player, char, col)
				else
					dropAll(name)
				end
			end
		end
		if not on then
			for _, player in ipairs(Players:GetPlayers()) do
				dropAll(player.Name)
			end
		end
	end
	Players.PlayerRemoving:Connect(function(p)
		dropAll(p.Name)
		local hl = espContainer:FindFirstChild(p.Name)
		if hl then pcall(function() hl:Destroy() end) end
	end)
	task.spawn(function()
		while task.wait(0.35) do
			pcall(EspRefresh)
		end
	end)
	RunService.RenderStepped:Connect(function()
		LPS_ATTRIBUTES(VM(NONE))
		if not (hasDrawing and espOn()) then
			return
		end
		if not (EspConfig.box or EspConfig.skeleton or EspConfig.tracers) then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				pcall(function()
					local char = player.Character
					if char then
						local col = colourFor(player)
						updateBox(player, char, col)
						updateSkeleton(player, char, col)
						updateTracer(player, char, col)
					end
				end)
			end
		end
	end)

	local guiService = game:GetService("GuiService")
	local PART_FALLBACK = { "HumanoidRootPart", "UpperTorso", "Torso", "Head" }
	local AIM_PARTS = {
		"Head",
		"UpperTorso",
		"HumanoidRootPart",
		"Torso",
		"LeftUpperArm",
		"RightUpperArm",
		"LeftUpperLeg",
		"RightUpperLeg",
	}
	local toggleActive = false
	local lockedTarget = nil
	local function isMouseKey(k)
		return typeof(k) == "EnumItem" and k.EnumType == Enum.UserInputType
	end
	local function inputMatches(input)
		local k = AimConfig.key
		if k == nil then return false end
		if isMouseKey(k) then return input.UserInputType == k end
		return input.KeyCode == k
	end
	local function keyDown(k)
		if k == nil then return false end
		local ok, down = pcall(function()
			if isMouseKey(k) then return UserInputService:IsMouseButtonPressed(k) end
			return UserInputService:IsKeyDown(k)
		end)
		return ok and down == true
	end
	local function aimActive()
		if not AimConfig.enabled then return false end
		if AimConfig.mode == "Always" then return true end
		if AimConfig.mode == "Toggle" then return toggleActive end
		return keyDown(AimConfig.key)
	end
	local function insetY()
		local ok, inset = pcall(function() return guiService:GetGuiInset() end)
		return (ok and inset) and inset.Y or 0
	end
	local function cursorViewport()
		local cam = workspace.CurrentCamera
		if AimConfig.fovFollow then
			local m = UserInputService:GetMouseLocation()
			return Vector2.new(m.X, m.Y - insetY())
		end
		local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		return Vector2.new(vp.X / 2, vp.Y / 2)
	end
	local function cursorScreen()
		local v = cursorViewport()
		return Vector2.new(v.X, v.Y + insetY())
	end
	local function validTarget(player)
		if player == LocalPlayer then return false end
		local char = player.Character
		if not char then return false end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false end
		if AimConfig.aimTeamCheck and sameTeam(player) then return false end
		if AimConfig.aimKnockedCheck and hum.Health < hum.MaxHealth * 0.15 then return false end
		if AimConfig.aimWeaponCheck then
			local lc = LocalPlayer.Character
			local tool = lc and lc:FindFirstChildOfClass("Tool")
			if not tool then return false end
		end
		if EspConfig.maxDistance > 0 then
			local d = distanceTo(char)
			if d and d > EspConfig.maxDistance then return false end
		end
		return true
	end
	local function leadTime(part)
		if AimConfig.projectile > 0 then
			local cam = workspace.CurrentCamera
			if cam then
				local dist = (part.Position - cam.CFrame.Position).Magnitude
				return dist / AimConfig.projectile
			end
		end
		return AimConfig.predict and AimConfig.predictAmount or 0
	end
	local function aimPointOf(part)
		if not (AimConfig.predict or AimConfig.projectile > 0) then
			return part.Position
		end
		local t = leadTime(part)
		if t <= 0 then return part.Position end
		local ok, vel = pcall(function() return part.AssemblyLinearVelocity end)
		if ok and vel then return part.Position + vel * t end
		return part.Position
	end
	local function visibleFrom(char, part)
		if not AimConfig.wallCheck or AimConfig.rage then return true end
		local cam = workspace.CurrentCamera
		if not (cam and part) then return true end
		local ignore = { char, cam }
		if LocalPlayer.Character then ignore[#ignore + 1] = LocalPlayer.Character end
		local ok, blocked = pcall(function()
			local params = RaycastParams.new()
			local kinds = Enum["RaycastFilterType"]
			if kinds then params.FilterType = kinds.Exclude or kinds.Blacklist end
			params.FilterDescendantsInstances = ignore
			local origin = cam.CFrame.Position
			return workspace:Raycast(origin, part.Position - origin, params)
		end)
		if not ok then return true end
		return blocked == nil
	end
	local function bestPartOf(char, cursor)
		local cam = workspace.CurrentCamera
		if not (cam and char) then return nil end
		local function project(name)
			local part = char:FindFirstChild(name)
			if not (part and part:IsA("BasePart")) then return nil end
			local v, onScreen = cam:WorldToViewportPoint(aimPointOf(part))
			if not onScreen or v.Z <= 0 then return nil end
			return part, (Vector2.new(v.X, v.Y) - cursor).Magnitude
		end
		local targetPart = (AimConfig.targetPart == "Root") and "HumanoidRootPart" or AimConfig.targetPart
		local names = targetPart == "Nearest" and AIM_PARTS or nil
		local candidates = {}
		if names then
			for _, n in ipairs(names) do
				local part, d = project(n)
				if part then candidates[#candidates + 1] = { part = part, dist = d } end
			end
			table.sort(candidates, function(a, b) return a.dist < b.dist end)
		else
			local part, d = project(targetPart)
			if part then candidates[#candidates + 1] = { part = part, dist = d } end
			for _, n in ipairs(PART_FALLBACK) do
				if n ~= targetPart then
					part, d = project(n)
					if part then candidates[#candidates + 1] = { part = part, dist = d } end
				end
			end
		end
		for _, c in ipairs(candidates) do
			if visibleFrom(char, c.part) then return c.part, c.dist end
		end
		return nil
	end
	local function scoreOf(char, cursorDist)
		local mode = AimConfig.priority
		if mode == "Distance" then
			return distanceTo(char) or math.huge
		elseif mode == "Health" then
			local hum = char:FindFirstChildOfClass("Humanoid")
			return (hum and hum.Health) or math.huge
		end
		return cursorDist
	end
	local function pickTarget()
		local cursor = cursorViewport()
		local radius = AimConfig.rage and math.huge or AimConfig.fov
		if AimConfig.sticky and lockedTarget and validTarget(lockedTarget) then
			local part, d = bestPartOf(lockedTarget.Character, cursor)
			if part and d <= radius then return lockedTarget, part end
		end
		local bestPlayer, bestPart, bestScore
		for _, player in ipairs(Players:GetPlayers()) do
			if validTarget(player) then
				local char = player.Character
				local part, d = bestPartOf(char, cursor)
				if part and d <= radius then
					local score = scoreOf(char, d)
					if not bestScore or score < bestScore then
						bestPlayer, bestPart, bestScore = player, part, score
					end
				end
			end
		end
		lockedTarget = bestPlayer
		return bestPlayer, bestPart
	end
	local fovCircle, fovSquare, fovDot
	if hasDrawing then
		pcall(function()
			fovCircle = Drawing.new("Circle")
			fovCircle.Thickness = 1
			fovCircle.NumSides = 64
			fovCircle.Filled = false
			fovCircle.Transparency = 1
			fovCircle.Visible = false
			fovSquare = Drawing.new("Square")
			fovSquare.Thickness = 1
			fovSquare.Filled = false
			fovSquare.Transparency = 1
			fovSquare.Visible = false
			fovDot = Drawing.new("Circle")
			fovDot.Thickness = 1
			fovDot.NumSides = 12
			fovDot.Filled = true
			fovDot.Transparency = 1
			fovDot.Visible = false
		end)
	end
	local function updateFovCircle()
		local show = AimConfig.enabled and AimConfig.showFov and not AimConfig.rage
		if not show then
			if fovCircle then fovCircle.Visible = false end
			if fovSquare then fovSquare.Visible = false end
			if fovDot then fovDot.Visible = false end
			return
		end
		local active = aimActive()
		local col = active and Color3.fromRGB(160, 160, 165) or Color3.fromRGB(110, 110, 115)
		local c = cursorScreen()
		local style = AimConfig.fovStyle or "Circle"
		if fovCircle then
			fovCircle.Visible = show and style == "Circle"
			if fovCircle.Visible then
				fovCircle.Position = Vector2.new(c.X, c.Y)
				fovCircle.Radius = AimConfig.fov
				fovCircle.Color = col
			end
		end
		if fovSquare then
			fovSquare.Visible = show and style == "Square"
			if fovSquare.Visible then
				local r = AimConfig.fov
				fovSquare.Position = Vector2.new(c.X - r, c.Y - r)
				fovSquare.Size = Vector2.new(r * 2, r * 2)
				fovSquare.Color = col
			end
		end
		if fovDot then
			fovDot.Visible = show and style == "Dot"
			if fovDot.Visible then
				fovDot.Position = Vector2.new(c.X, c.Y)
				fovDot.Radius = 3
				fovDot.Color = col
			end
		end
	end
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or UserInputService:GetFocusedTextBox() then return end
		if AimConfig.mode == "Toggle" and inputMatches(input) then
			toggleActive = not toggleActive
			if not toggleActive then lockedTarget = nil end
		end
	end)
	local AIM_BIND = "SlateAimlock"
	local aimPriority = Enum.RenderPriority.Camera.Value + 1
	local _aimDelayUntil = 0
	local _rayOffsetDirty = false
	local function doSilentAim(part)
		local cam = workspace.CurrentCamera
		if not (cam and part) then return end
		local aimPos = aimPointOf(part)
		local _, onScreen = cam:WorldToViewportPoint(aimPos)
		if not onScreen then return end
		pcall(function()
			local ray = cam:ScreenPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
			local dir = (aimPos - ray.Origin).Unit
			local fakeOrigin = aimPos - dir * ray.Direction.Magnitude
			UserInputService:SetMouseRayOffset(fakeOrigin - ray.Origin)
			_rayOffsetDirty = true
		end)
	end
	local stepAim = function(dt)
		LPS_ATTRIBUTES(VM(NONE))
		updateFovCircle()
		if not aimActive() then
			lockedTarget = nil
			_aimDelayUntil = 0
			if _rayOffsetDirty then
				_rayOffsetDirty = false
				pcall(function() UserInputService:SetMouseRayOffset(Vector3.new(0, 0, 0)) end)
			end
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local target, part = pickTarget()
		if not (target and part) then
			_aimDelayUntil = 0
			if _rayOffsetDirty then
				_rayOffsetDirty = false
				pcall(function() UserInputService:SetMouseRayOffset(Vector3.new(0, 0, 0)) end)
			end
			return
		end
		if AimConfig.aimDelay > 0 then
			if _aimDelayUntil == 0 then _aimDelayUntil = tick() + AimConfig.aimDelay end
			if tick() < _aimDelayUntil then return end
		end
		if AimConfig.silentAim then
			doSilentAim(part)
			return
		end
		local now = cam.CFrame
		local aimPos = aimPointOf(part)
		if (aimPos - now.Position).Magnitude < 0.05 then return end
		local goal = CFrame.lookAt(now.Position, aimPos)
		if AimConfig.rage or not AimConfig.smoothing then
			cam.CFrame = goal
			return
		end
		local blended
		if AimConfig.perAxisSmooth then
			local sx = math.clamp(AimConfig.smoothAmountX, 0.01, 1)
			local sy = math.clamp(AimConfig.smoothAmountY, 0.01, 1)
			local f = math.clamp((dt or 0) * 60, 0, 8)
			local ax = 1 - (1 - sx) ^ f
			local ay = 1 - (1 - sy) ^ f
			blended = now:Lerp(goal, (ax + ay) / 2)
		else
			local s = math.clamp(AimConfig.smoothAmount, 0.01, 1)
			local alpha = 1 - (1 - s) ^ math.clamp((dt or 0) * 60, 0, 8)
			blended = now:Lerp(goal, alpha)
		end
		if AimConfig.maxTurn > 0 then
			local from, to = now.LookVector, blended.LookVector
			local cosang = math.clamp(from:Dot(to), -1, 1)
			local ang = math.acos(cosang)
			local allowed = math.rad(AimConfig.maxTurn) * math.max(dt or 0, 0)
			if ang > allowed and ang > 0 then
				blended = now:Lerp(blended, allowed / ang)
			end
		end
		if (blended.LookVector - goal.LookVector).Magnitude < 0.0005 then
			blended = goal
		end
		cam.CFrame = blended
	end
	RunService.Heartbeat:Connect(function()
		LPS_ATTRIBUTES(VM(NONE))
		if not (AimConfig.enabled and AimConfig.triggerbot) then return end
		local target, _ = pickTarget()
		if not target then return end
		task.delay(AimConfig.triggerbotDelay, function()
			local uis = UserInputService
			pcall(function()
				uis:SendMouseButtonEvent(uis:GetMouseLocation().X, uis:GetMouseLocation().Y, 0, true, game, 0)
				task.wait(0.05)
				uis:SendMouseButtonEvent(uis:GetMouseLocation().X, uis:GetMouseLocation().Y, 0, false, game, 0)
			end)
		end)
	end)
	pcall(function() RunService:UnbindFromRenderStep(AIM_BIND) end)
	RunService:BindToRenderStep(AIM_BIND, aimPriority, stepAim)

	SlateEspMenu = {}
	_G.SlateEspMenu = SlateEspMenu

	function SlateEspMenu.setEsp(on)
		EspConfig.enabled = on and true or false
	end

	function SlateEspMenu.espEnabled()
		return EspConfig.enabled == true
	end

	function SlateEspMenu.refresh()
		pcall(EspRefresh)
	end

	function SlateEspMenu.build()
		LPS_ATTRIBUTES(VM(NONE))
		if SlateEspMenu.ui then
			return SlateEspMenu.ui
		end
		if not Tempus then
			return nil
		end
		local UI = Tempus.Window({
			title = "SLATE",
			keybind = nil,
			footerText = "Slate",
		})
		SlateEspMenu.ui = UI
		local Aimbot = UI.Tab("Aimbot", { icon = "126439761728978" })
		local Aim = Aimbot.Group("Aim", { side = "left", info = "Main aimlock toggles" })
		Aim.Toggle({
			text = "Aimlock",
			default = AimConfig.enabled,
			callback = function(v) AimConfig.enabled = v end,
		})
		Aim.Toggle({
			text = "Silent Aim",
			default = AimConfig.silentAim,
			callback = function(v) AimConfig.silentAim = v end,
		})
		Aim.Keybind({
			text = "Aim Key",
			default = AimConfig.key,
			changed = function(kc) AimConfig.key = kc end,
		})
		Aim.Toggle({
			text = "Field of View",
			default = AimConfig.showFov,
			callback = function(v) AimConfig.showFov = v end,
		})
		Aim.Slider({
			text = "FOV Size",
			min = 0,
			max = 500,
			default = AimConfig.fov,
			step = 1,
			callback = function(v) AimConfig.fov = v end,
		})
		Aim.Dropdown({
			text = "FOV Style",
			options = { "Circle", "Square", "Dot" },
			default = AimConfig.fovStyle,
			callback = function(v) AimConfig.fovStyle = v end,
		})
		Aim.Toggle({
			text = "FOV Follows Cursor",
			default = AimConfig.fovFollow,
			callback = function(v) AimConfig.fovFollow = v end,
		})
		local Configure = Aimbot.Group("Configure", { side = "left", info = "How the aim behaves" })
		Configure.Dropdown({
			text = "Aimbot Type",
			options = { "Hold", "Toggle", "Always" },
			default = AimConfig.mode,
			callback = function(v) AimConfig.mode = v end,
		})
		Configure.Dropdown({
			text = "Hitbox",
			options = { "Head", "Root", "Nearest" },
			default = AimConfig.targetPart,
			callback = function(v) AimConfig.targetPart = v end,
		})
		Configure.Dropdown({
			text = "Priority",
			options = { "Crosshair", "Distance", "Health" },
			default = AimConfig.priority,
			callback = function(v) AimConfig.priority = v end,
		})
		Configure.Slider({
			text = "Aim Delay (s)",
			min = 0,
			max = 1,
			default = AimConfig.aimDelay,
			step = 0.01,
			callback = function(v) AimConfig.aimDelay = v end,
		})
		local Trig = Aimbot.Group("Triggerbot", { side = "right", info = "Auto-fire when target is in FOV" })
		Trig.Toggle({
			text = "Triggerbot",
			default = AimConfig.triggerbot,
			callback = function(v) AimConfig.triggerbot = v end,
		})
		Trig.Slider({
			text = "Trigger Delay (s)",
			min = 0,
			max = 0.5,
			default = AimConfig.triggerbotDelay,
			step = 0.01,
			callback = function(v) AimConfig.triggerbotDelay = v end,
		})
		local Pred = Aimbot.Group("Prediction & Smoothing", { side = "right" })
		Pred.Toggle({
			text = "Smoothing",
			default = AimConfig.smoothing,
			callback = function(v) AimConfig.smoothing = v end,
		})
		Pred.Toggle({
			text = "Per-Axis Smoothing",
			default = AimConfig.perAxisSmooth,
			callback = function(v) AimConfig.perAxisSmooth = v end,
		})
		Pred.Slider({
			text = "Smoothing Amount",
			min = 0,
			max = 1,
			default = AimConfig.smoothAmount,
			step = 0.01,
			callback = function(v) AimConfig.smoothAmount = v end,
		})
		Pred.Slider({
			text = "Smoothing X",
			min = 0,
			max = 1,
			default = AimConfig.smoothAmountX,
			step = 0.01,
			callback = function(v) AimConfig.smoothAmountX = v end,
		})
		Pred.Slider({
			text = "Smoothing Y",
			min = 0,
			max = 1,
			default = AimConfig.smoothAmountY,
			step = 0.01,
			callback = function(v) AimConfig.smoothAmountY = v end,
		})
		Pred.Toggle({
			text = "Prediction",
			default = AimConfig.predict,
			callback = function(v) AimConfig.predict = v end,
		})
		Pred.Slider({
			text = "Prediction Amount",
			min = 0,
			max = 0.5,
			default = AimConfig.predictAmount,
			step = 0.005,
			callback = function(v) AimConfig.predictAmount = v end,
		})
		Pred.Slider({
			text = "Projectile Speed",
			min = 0,
			max = 1500,
			default = AimConfig.projectile,
			step = 1,
			callback = function(v) AimConfig.projectile = math.floor(v) end,
		})
		local AimSet = Aimbot.Group("Settings", { side = "right", info = "Target selection and limits" })
		AimSet.Toggle({
			text = "Wall Check",
			default = AimConfig.wallCheck,
			callback = function(v) AimConfig.wallCheck = v end,
		})
		AimSet.Toggle({
			text = "Team Check",
			default = AimConfig.aimTeamCheck,
			callback = function(v) AimConfig.aimTeamCheck = v end,
		})
		AimSet.Toggle({
			text = "Skip Knocked",
			default = AimConfig.aimKnockedCheck,
			callback = function(v) AimConfig.aimKnockedCheck = v end,
		})
		AimSet.Toggle({
			text = "Weapon Check",
			default = AimConfig.aimWeaponCheck,
			callback = function(v) AimConfig.aimWeaponCheck = v end,
		})
		AimSet.Toggle({
			text = "Sticky Target",
			default = AimConfig.sticky,
			callback = function(v) AimConfig.sticky = v end,
		})
		AimSet.Slider({
			text = "Max Turn",
			min = 0,
			max = 1440,
			default = AimConfig.maxTurn,
			step = 1,
			callback = function(v) AimConfig.maxTurn = math.floor(v) end,
		})
		AimSet.Toggle({
			text = "Rage Aimbot",
			default = AimConfig.rage,
			callback = function(v) AimConfig.rage = v end,
		})
		local Visual = UI.Tab("Visual", { icon = "100086900641425" })
		local ESP = Visual.Group("ESP", { side = "left", info = "Player ESP" })
		ESP.Toggle({
			text = "Enabled",
			default = SlateEspMenu.espEnabled(),
			callback = function(v)
				SlateEspMenu.setEsp(v)
				SlateEspMenu.refresh()
			end,
		})
		ESP.Toggle({
			text = "Fill",
			default = EspConfig.fill,
			color = EspConfig.color,
			callback = function(v)
				EspConfig.fill = v
				SlateEspMenu.refresh()
			end,
			colorCallback = function(c)
				EspConfig.color = c
				SlateEspMenu.refresh()
			end,
		})
		ESP.Slider({
			text = "Fill Transparency",
			min = 0,
			max = 1,
			default = EspConfig.fillTransparency,
			step = 0.01,
			callback = function(v)
				EspConfig.fillTransparency = v
				SlateEspMenu.refresh()
			end,
		})
		ESP.Toggle({
			text = "Outline",
			default = EspConfig.outline,
			callback = function(v)
				EspConfig.outline = v
				SlateEspMenu.refresh()
			end,
		})
		ESP.Toggle({
			text = "Corner Box",
			default = EspConfig.box,
			callback = function(v)
				EspConfig.box = v
				SlateEspMenu.refresh()
			end,
		})
		ESP.Slider({
			text = "Max Distance",
			min = 0,
			max = 5000,
			default = EspConfig.maxDistance,
			step = 10,
			callback = function(v)
				EspConfig.maxDistance = math.floor(v)
				SlateEspMenu.refresh()
			end,
		})
		local Overlay = Visual.Group("Overlay", { side = "left", info = "What is drawn on each player" })
		Overlay.Toggle({
			text = "Names",
			default = EspConfig.names,
			callback = function(v)
				EspConfig.names = v
				SlateEspMenu.refresh()
			end,
		})
		Overlay.Toggle({
			text = "Distance",
			default = EspConfig.distance,
			callback = function(v)
				EspConfig.distance = v
				SlateEspMenu.refresh()
			end,
		})
		Overlay.Toggle({
			text = "Health Bar",
			default = EspConfig.health,
			callback = function(v)
				EspConfig.health = v
				SlateEspMenu.refresh()
			end,
		})
		Overlay.Toggle({
			text = "Skeleton",
			default = EspConfig.skeleton,
			callback = function(v)
				EspConfig.skeleton = v
				SlateEspMenu.refresh()
			end,
		})
		Overlay.Toggle({
			text = "Tracers",
			default = EspConfig.tracers,
			callback = function(v)
				EspConfig.tracers = v
				SlateEspMenu.refresh()
			end,
		})
		local Filters = Visual.Group("Filters", { side = "right", info = "Who gets drawn" })
		Filters.Toggle({
			text = "Team Check",
			default = EspConfig.teamCheck,
			callback = function(v)
				EspConfig.teamCheck = v
				SlateEspMenu.refresh()
			end,
		})
		Filters.Toggle({
			text = "Team Colours",
			default = EspConfig.teamColor,
			callback = function(v)
				EspConfig.teamColor = v
				SlateEspMenu.refresh()
			end,
		})
		Filters.Color({
			text = "ESP Colour",
			default = EspConfig.color,
			callback = function(c)
				EspConfig.color = c
				SlateEspMenu.refresh()
			end,
		})
		local Menu = Visual.Group("Menu", { side = "right" })
		Menu.Keybind({
			text = "Menu Key",
			default = Enum.KeyCode.Insert,
			changed = function(kc)
				UI.SetMenuKey(kc)
			end,
		})
		Menu.Button({
			text = "Close",
			callback = function()
				UI.SetMenuVisible(false)
			end,
		})
		local Misc = UI.Tab("Misc", { icon = "100428338507079" })
		local Movement = Misc.Group("Movement", { side = "left", info = "Character movement tweaks" })
		Movement.Toggle({
			text = "Noclip",
			default = false,
			callback = function(v)
				executeSlateCommand(v and "noclip" or "clip")
			end,
		})
		Movement.Toggle({
			text = "Flight",
			default = false,
			callback = function(v)
				executeSlateCommand(v and "fly" or "unfly")
			end,
		})
		Movement.Toggle({
			text = "Infinite Jump",
			default = false,
			callback = function(v)
				executeSlateCommand(v and "infjump" or "uninfjump")
			end,
		})
		Movement.Toggle({
			text = "Anti AFK",
			default = false,
			callback = function(v)
				if v then executeSlateCommand("antiafk") end
			end,
		})
		local World = Misc.Group("World", { side = "left", info = "Lighting and environment" })
		World.Toggle({
			text = "Fullbright",
			default = false,
			callback = function(v)
				executeSlateCommand(v and "loopfullbright" or "unloopfullbright")
			end,
		})
		World.Toggle({
			text = "No Fog",
			default = false,
			callback = function(v)
				if v then executeSlateCommand("nofog") end
			end,
		})
		World.Button({
			text = "Set Day",
			callback = function()
				executeSlateCommand("day")
			end,
		})
		World.Button({
			text = "Set Night",
			callback = function()
				executeSlateCommand("night")
			end,
		})
		return UI
	end

	function SlateEspMenu.toggle()
		local UI = SlateEspMenu.build()
		if not UI then
			queueNotification("ESP", "The ESP menu is still loading.")
			return
		end
		UI.ToggleMenu()
	end
	_G.SlateToggleEspMenu = SlateEspMenu.toggle
end)()
do
    local panel = new("Frame", {
        Name = "SlateReanimatePanel", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(310, 178),
        BackgroundColor3 = T.surface, BorderSizePixel = 0,
        Visible = false, ZIndex = 80, Parent = gui,
    }, { corner(10), pad(12) })
    do local s_ = stroke(T.line, 1, 0.1); s_.Parent = panel; s_.Enabled = false end
    new("TextLabel", {
        Size = UDim2.new(1, -25, 0, 19), BackgroundTransparency = 1,
        Text = "Reanimate", Font = Enum.Font.BuilderSansBold, TextSize = 13,
        TextColor3 = T.text1, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 81, Parent = panel,
    })
    local close = new("TextButton", {
        Position = UDim2.new(1, -21, 0, -2), Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1, Text = "×", Font = Enum.Font.BuilderSansMedium,
        TextSize = 17, TextColor3 = T.text3, ZIndex = 81, Parent = panel,
    })
    _G.SlateHeaderCtl(close, "x", 11)
    close.MouseButton1Click:Connect(function() panel.Visible = false end)
    local state = new("TextLabel", {
        Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1, Text = "Ready", Font = Enum.Font.BuilderSans,
        TextSize = 10, TextColor3 = T.text3, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 81, Parent = panel,
    })
    local function action(textValue, y, callback)
        local button = new("TextButton", {
            Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = T.surface2, BorderSizePixel = 0,
            AutoButtonColor = false, Text = textValue, Font = Enum.Font.BuilderSansMedium,
            TextSize = 10, TextColor3 = T.text1, ZIndex = 81, Parent = panel,
        }, { corner(6) })
        button.MouseButton1Click:Connect(callback)
    end
    action("Start / stop reanimation", 51, function()
        local api = _G.SlateReanimAPI
        if not api then queueNotification("Reanimate", "Still loading", 3, "warning") return end
        local enable = not api.is_reanimated()
        local ok, result = pcall(api.reanimate, enable)
        state.Text = ok and (enable and "Active" or "Stopped") or tostring(result):sub(1, 50)
        if not ok then queueNotification("Reanimate", tostring(result):sub(1, 100), 5, "error") end
    end)
    action("Open emotes", 87, function()
        if _G.ToggleSlateEmoteMenu then _G.ToggleSlateEmoteMenu() end
    end)
    action("Open animation copier", 123, function()
        if _G.SlateOpenAnimCopier then _G.SlateOpenAnimCopier() end
    end)
    _G.SlateToggleReanimPanel = function()
        panel.Visible = not panel.Visible
        local api = _G.SlateReanimAPI
        if api then state.Text = api.is_reanimated() and "Active" or "Ready" end
    end
    _G.SlateOpenReanimMenu = function()
        if type(_G.ToggleReanimGUI) == "function" then
            _G.ToggleReanimGUI()
            return
        end
        local function showLoadedMenu()
            if type(_G.ToggleReanimGUI) == "function" then
                _G.ToggleReanimGUI(true)
            elseif type(_G.guiUpdateFunction) == "function" then
                pcall(_G.guiUpdateFunction)
                local guiInstance = _G.AKReanimGUIInstance
                if guiInstance and guiInstance.Parent then guiInstance.Enabled = true end
            elseif _G.AKReanimGUIInstance and _G.AKReanimGUIInstance.Parent then
                _G.AKReanimGUIInstance.Enabled = true
            else
                _G.SlateToggleReanimPanel()
            end
        end
        local loader = _G.ensureReanimateLoaded or Slate.ensureReanimateLoaded
        if type(loader) == "function" then
            _G.show_ui = true
            _G.AutoOpenReanimGUI = true
            local ok = pcall(loader, showLoadedMenu)
            if not ok then _G.SlateToggleReanimPanel() end
        else
            _G.SlateToggleReanimPanel()
        end
    end
end
	Slate.playEmote = function(input, speaker)
		local args = type(input) == "table" and input or _IY_splitArgs(tostring(input or ""))
		local character = speaker and speaker.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			queueNotification("Emote", "Your character is not ready", 4, "error")
			return
		end
		local emote = tostring(args[1] or "")
		if emote == "" then
			queueNotification("Emote", "Enter an emote name or animation ID", 4, "info")
			return
		end
		local speed = tonumber(args[2])
		local track
		local playById
		pcall(function()
			playById = humanoid.PlayEmoteAndGetAnimTrackById
		end)
		if type(playById) == "function" then
			local ok, result = pcall(playById, humanoid, emote)
			if ok then
				track = result
			end
		end
		if track and track.Play then
			if speed then
				pcall(function()
					track:AdjustSpeed(speed)
				end)
			end
			return track
		end
		local animationId =
			emote:match("^%s*(%d+)%s*$")
			or emote:match("rbxassetid://(%d+)")
			or emote:match("[?&]id=(%d+)")
		if animationId then
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. animationId
			local animator = humanoid:FindFirstChildOfClass("Animator")
			local ok, result = pcall(function()
				if animator then
					return animator:LoadAnimation(animation)
				end
				return humanoid:LoadAnimation(animation)
			end)
			if ok and result then
				track = result
				track.Priority = Enum.AnimationPriority.Movement
				track:Play()
				if speed then
					track:AdjustSpeed(speed)
				end
				return track
			end
			queueNotification("Emote", "Could not load that animation ID", 4, "error")
			return
		end
		local ok, played = pcall(function()
			return humanoid:PlayEmote(emote)
		end)
		if not ok or played == false then
			queueNotification("Emote", "That emote is unavailable for your avatar", 4, "error")
		end
		return played
	end
	_IY_execCmd = function(cmdStr, speaker, store)
		if not cmdStr or type(cmdStr) ~= "string" then
			return
		end
		cmdStr = cmdStr:gsub("^[%./!;:]+", "")
		if cmdStr:find("\\") then
			for subCmd in cmdStr:gmatch("[^\\/]+") do
				_IY_execCmd(subCmd, speaker, store)
			end
			return
		end
		local parts = {}
		for w in cmdStr:gmatch("%S+") do
			table.insert(parts, w)
		end
		local cname = (parts[1] or ""):lower()
		do
			local st = _G.SlateCmdStats
			if st and cname ~= "" and #cname <= 24 then st[cname] = (st[cname] or 0) + 1 end
		end
		local carg = #parts > 1 and table.concat(parts, " ", 2) or ""
		if onyxAliases and onyxAliases[cname] then
			cname = tostring(onyxAliases[cname]):lower()
		end
		if onyxCommands then
			for _, cmd in ipairs(onyxCommands) do
				local isMatch = false
				if cmd.name and cmd.name:lower() == cname then
					isMatch = true
				elseif cmd.aliases then
					for _, alias in ipairs(cmd.aliases) do
						if tostring(alias):lower() == cname then
							isMatch = true
							break
						end
					end
				end
				if isMatch then
					if cmd.isToggle then
						local targetState
						local lowerArg = carg:lower():match("^%s*(.-)%s*$")
						if
							lowerArg == "on"
							or lowerArg == "true"
							or lowerArg == "1"
							or lowerArg == "enable"
							or lowerArg == "enabled"
						then
							targetState = true
						elseif
							lowerArg == "off"
							or lowerArg == "false"
							or lowerArg == "0"
							or lowerArg == "disable"
							or lowerArg == "disabled"
						then
							targetState = false
						elseif cmd.getState then
							targetState = not cmd.getState()
						else
							targetState = true
						end
						local callbackOk, callbackErr = pcall(cmd.callback, targetState)
						if not callbackOk then
							warn("[SlateUI] command " .. tostring(cmd.name) .. " failed: " .. tostring(callbackErr))
							queueNotification("Command failed", tostring(callbackErr):sub(1, 120), 5, "error")
						end
					else
						local callbackOk, callbackErr = pcall(cmd.callback, carg)
						if not callbackOk then
							warn("[SlateUI] command " .. tostring(cmd.name) .. " failed: " .. tostring(callbackErr))
							queueNotification("Command failed", tostring(callbackErr):sub(1, 120), 5, "error")
						end
					end
					return
				end
			end
		end
		local actualExec = execCmd
		if actualExec then
			local foundInIy = false
			local iyTable = cmds or {}
			for _, iyCmd in ipairs(iyTable) do
				if iyCmd.NAME and iyCmd.NAME:lower() == cname then
					foundInIy = true
					break
				elseif iyCmd.ALIAS then
					for _, alias in ipairs(iyCmd.ALIAS) do
						if alias and tostring(alias):lower() == cname then
							foundInIy = true
							break
						end
					end
				end
			end
			if foundInIy then
				local commandOk, commandErr = pcall(actualExec, cmdStr, speaker, store)
				if not commandOk then
					warn("[SlateUI] legacy command failed: " .. tostring(commandErr))
					queueNotification("Command failed", tostring(commandErr):sub(1, 120), 5, "error")
				end
				return
			end
		end
		queueNotification("Command not found", "No command named '" .. tostring(cname) .. "'", 4, "warning")
	end
	IY = IY or {}
	IY.notify = _IY_notify
	IY.toClipboard = _IY_toClipboard
	IY.getRoot = _IY_getRoot
	IY.FindInTable = _IY_FindInTable
	IY.getPlayer = _IY_getPlayer
	IY.splitArgs = _IY_splitArgs
	IY.Loops = _IY_Loops
	IY.waypoints = _IY_waypoints
	IY.saveWaypoints = _IY_saveWaypoints
	SlateBinds = { map = {}, file = "slate/keybinds.json" }

	function SlateBinds.resolveKey(str)
		if not str or str == "" then
			return nil
		end
		str = tostring(str):gsub("%s", "")
		local ok, direct = pcall(function()
			return Enum.KeyCode[str]
		end)
		if ok and direct then
			return direct.Name
		end
		local lower = str:lower()
		for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
			if item.Name:lower() == lower then
				return item.Name
			end
		end
		return nil
	end

	function SlateBinds.save()
		task.spawn(function()
			pcall(function()
				if not writefile then
					return
				end
				if makefolder and isfolder and not isfolder("slate") then
					pcall(makefolder, "slate")
				end
				local ok, json = pcall(httpService.JSONEncode, httpService, SlateBinds.map)
				if ok and json then
					writefile(SlateBinds.file, json)
				end
			end)
		end)
	end

	function SlateBinds.load()
		pcall(function()
			if not (isfile and isfile(SlateBinds.file) and readfile) then
				return
			end
			local raw = readfile(SlateBinds.file)
			if not raw or raw == "" then
				return
			end
			local ok, data = pcall(httpService.JSONDecode, httpService, raw)
			if ok and type(data) == "table" then
				for key, cmd in pairs(data) do
					local canonical = SlateBinds.resolveKey(key)
					if canonical and type(cmd) == "string" and cmd ~= "" then
						SlateBinds.map[canonical] = cmd
					end
				end
			end
		end)
	end

	function SlateBinds.set(keyStr, command)
		local key = SlateBinds.resolveKey(keyStr)
		if not key then
			return nil, "unknown key"
		end
		if not command or command:gsub("%s", "") == "" then
			return nil, "no command given"
		end
		SlateBinds.map[key] = command
		SlateBinds.save()
		SlateBinds.notifyChanged()
		return key
	end

	function SlateBinds.clear(keyStr)
		local key = SlateBinds.resolveKey(keyStr)
		if not key then
			return nil, "unknown key"
		end
		if not SlateBinds.map[key] then
			return nil, "nothing bound to " .. key
		end
		SlateBinds.map[key] = nil
		SlateBinds.save()
		SlateBinds.notifyChanged()
		return key
	end

	function SlateBinds.keyFor(commandName)
		if not commandName then
			return nil
		end
		local want = tostring(commandName):lower()
		for key, cmd in pairs(SlateBinds.map) do
			local head = tostring(cmd):match("^%s*(%S+)")
			if head and head:lower() == want then
				return key, cmd
			end
		end
		return nil
	end
	SlateBinds.listeners = {}

	function SlateBinds.onChanged(fn)
		if fn then
			table.insert(SlateBinds.listeners, fn)
		end
	end

	function SlateBinds.notifyChanged()
		for _, fn in ipairs(SlateBinds.listeners) do
			pcall(fn)
		end
	end

	function SlateBinds.list()
		local out = {}
		for key, cmd in pairs(SlateBinds.map) do
			out[#out + 1] = { key = key, command = cmd }
		end
		table.sort(out, function(a, b)
			return a.key < b.key
		end)
		return out
	end

	function SlateBinds.fire(key, input)
		local command = SlateBinds.map[key]
		if not command then
			return
		end
		task.spawn(function()
			local head = command:match("^%s*(%S+)")
            if head and (head:lower() == "cmdbar" or head:lower() == "commandbar") then

                if _G.SlateOpenCmdBar then _G.SlateOpenCmdBar(nil, input) end
                return
			end
			if head and onyxCommands then
				local want = head:lower()
				for _, c in ipairs(onyxCommands) do
					local hit = (c.name and c.name:lower() == want)
					if not hit and c.aliases then
						for _, a in ipairs(c.aliases) do
							if a:lower() == want then
								hit = true
								break
							end
						end
					end
					if hit and c.isToggle and c.getState then
						pcall(c.callback, not c.getState())
						return
					end
					if hit then
						break
					end
				end
			end
			if execCmd then
				pcall(execCmd, command)
			end
		end)
	end
	SlateBinds.load()

	function SlateBinds.captureKey(callback)
		if SlateBinds.cancelActive then
			SlateBinds.cancelActive()
		end
		SlateBinds.captureGen = (SlateBinds.captureGen or 0) + 1
		local myGen = SlateBinds.captureGen
		local conn

		local function finish(name, action)
			if conn then
				conn:Disconnect()
				conn = nil
			end
			SlateBinds.cancelActive = nil
			callback(name, action)
			task.defer(function()
				if SlateBinds.captureGen == myGen then
					SlateBinds.capturing = false
				end
			end)
		end
		SlateBinds.capturing = true
		SlateBinds.cancelActive = function()
			finish(nil, "cancel")
		end
		conn = userInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			local name = input.KeyCode.Name
			if name == "Escape" then
				finish(nil, "cancel")
			elseif name == "Backspace" or name == "Delete" then
				finish(nil, "clear")
			else
				finish(name, "set")
			end
		end)
		return SlateBinds.cancelActive
	end
	userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if SlateBinds.capturing then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if userInputService:GetFocusedTextBox() then
			return
		end
		SlateBinds.fire(input.KeyCode.Name, input)
	end)
	_G.SlateBindCommand = function(key, cmd)
		return SlateBinds.set(key, cmd)
	end
	_G.SlateUnbindCommand = function(key)
		return SlateBinds.clear(key)
	end
	_G.SlateGetCommandBinds = function()
		return SlateBinds.list()
	end
	SlateCloud = {
		busy = false,
	}

	function SlateCloud.baseUrl()
		local resolved = (getgenv and getgenv().SLATE_CLOUD_BASE)
			or _G.SLATE_CLOUD_BASE
			or _G.SlateBackendBase
			or "https://sl8ght.xyz/"
		return (tostring(resolved):gsub("/$", ""))
	end
	SlateCloud.files = {
		{ key = "keybinds", path = "slate/keybinds.json" },
		{ key = "autoexec", path = "slate/autoexec.json" },
		{ key = "autoexecCmds", path = "slate/autoexec_cmds.json" },
		{ key = "favCommands", path = "slate/fav_commands.json" },
		{ key = "emoteBinds", path = "slate/emotes_binds.json" },
		{ key = "emoteFavs", path = "slate/emotes_favs.json" },
		{ key = "reanimFavourites", path = "slate/reanimation/favorite_animations.json" },
		{ key = "reanimKeybinds", path = "slate/reanimation/animation_keybinds.json" },
		{ key = "reanimSpeeds", path = "slate/reanimation/speed_keybinds.json" },
		{ key = "reanimStates", path = "slate/reanimation/state_animations.json" },
		{ key = "musicPlaylists", path = "slate/music/playlists.json" },
		{ key = "musicEqualizer", path = "slate/music/equalizer.json" },
		{ key = "waypoints", path = "slate/iy_waypoints.json" },
		{ key = "iy", path = "IY_FE.iy" },
	}
	SlateCloud.espDir = "slate/espconfigs"
	SlateCloud.sections = {
		{ key = "settings", label = "Settings" },
		{ key = "sliders", label = "Sliders" },
		{ key = "keybinds", label = "Command keybinds" },
		{ key = "autoexec", label = "Auto execute" },
		{ key = "autoexecCmds", label = "Auto execute commands" },
		{ key = "favCommands", label = "Favourite commands" },
		{ key = "emoteBinds", label = "Emote keybinds" },
		{ key = "emoteFavs", label = "Favourite emotes" },
		{ key = "reanimFavourites", label = "Reanimate favourites" },
		{ key = "reanimKeybinds", label = "Reanimate keybinds" },
		{ key = "reanimSpeeds", label = "Reanimate speeds" },
		{ key = "reanimStates", label = "Reanimate states" },
		{ key = "espConfigs", label = "ESP / aimlock configs" },
		{ key = "musicPlaylists", label = "Music playlists" },
		{ key = "musicEqualizer", label = "Music equalizer" },
		{ key = "waypoints", label = "Waypoints" },
		{ key = "iy", label = "Infinite Yield data" },
	}
	SlateCloud.retired = {
		reanimCustoms = true,
	}

	function SlateCloud.sectionLabel(key)
		for _, entry in ipairs(SlateCloud.sections) do
			if entry.key == key then
				return entry.label
			end
		end
		return key
	end

	function SlateCloud.wants(selection, key)
		if SlateCloud.retired[key] then
			return false
		end
		if selection == nil then
			return true
		end
		return selection[key] == true
	end

	function SlateCloud.notify(title, body)
		pcall(queueNotification, title or "Cloud", body or "")
	end

	function SlateCloud.http()
		return request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
	end

	function SlateCloud.credentials()
		LPS_ATTRIBUTES(VM(OPAL), PRESET(SECURE))
		local key
		if isfile and isfile("slate/key.json") then
			pcall(function()
				local decoded = httpService:JSONDecode(readfile("slate/key.json"))
				key = decoded and decoded.Key
			end)
		end
		if not key or key == "" then
			return nil, "No license key found on this device."
		end
		local player = players.LocalPlayer
		return {
			key = key,
			userId = tostring(player.UserId),
			username = player.Name,
		}
	end

	function SlateCloud.request(method, path, query, body)
		local http = SlateCloud.http()
		if not http then
			return nil, "Your executor cannot make HTTP requests."
		end
		local creds, credErr = SlateCloud.credentials()
		if not creds then
			return nil, credErr
		end
		local url = SlateCloud.baseUrl() .. path
		if method == "GET" then
			local parts = { "key=" .. httpService:UrlEncode(creds.key), "userId=" .. creds.userId }
			for k, v in pairs(query or {}) do
				parts[#parts + 1] = k .. "=" .. httpService:UrlEncode(tostring(v))
			end
			url = url .. "?" .. table.concat(parts, "&")
		end
		local payload
		if method ~= "GET" then
			local merged = { key = creds.key, userId = creds.userId, username = creds.username }
			for k, v in pairs(body or {}) do
				merged[k] = v
			end
			local ok, encoded = pcall(httpService.JSONEncode, httpService, merged)
			if not ok then
				return nil, "Could not encode the request."
			end
			payload = encoded
		end
		local ok, res = pcall(http, {
			Url = url,
			Method = method,
			Headers = { ["Content-Type"] = "application/json" },
			Body = payload,
		})
		if not ok or not res then
			return nil, "Could not reach the Slate backend."
		end
		local decoded
		pcall(function()
			decoded = httpService:JSONDecode(res.Body or "")
		end)
		local status = res.StatusCode or res.Status or 0
		if status < 200 or status >= 300 then
			if decoded and decoded.error then
				return nil, decoded.error
			end
			if status == 413 then
				return nil, "The server rejected that request as too large. Try saving again."
			elseif status == 404 then
				return nil, "Cloud configs are not available on this backend yet."
			elseif status == 401 or status == 403 then
				return nil, "Your key was rejected. Re-enter it and try again."
			end
			return nil, "Backend returned HTTP " .. tostring(status)
		end
		if not decoded then
			return nil, "Backend sent a response we could not read."
		end
		return decoded, nil
	end

	function SlateCloud.readJson(path)
		if not (isfile and readfile and isfile(path)) then
			return nil
		end
		local ok, raw = pcall(readfile, path)
		if not ok or not raw or raw == "" then
			return nil
		end
		local decoded
		local decodedOk = pcall(function()
			decoded = httpService:JSONDecode(raw)
		end)
		if not decodedOk then
			return nil
		end
		return decoded
	end

	function SlateCloud.writeJson(path, value)
		if not writefile then
			return false
		end
		local ok, encoded = pcall(httpService.JSONEncode, httpService, value)
		if not ok then
			return false
		end
		return (pcall(writefile, path, encoded))
	end

	function SlateCloud.ensureFolders()
		if not (makefolder and isfolder) then
			return
		end
		for _, dir in ipairs({ "slate", "slate/music", "slate/reanimation", SlateCloud.espDir }) do
			if not isfolder(dir) then
				pcall(makefolder, dir)
			end
		end
	end

	function SlateCloud.collectSettings()
		local settings, sliders = {}, {}
		pcall(function()
			for _, category in ipairs(siriusSettings) do
				for _, setting in ipairs(category.categorySettings) do
					if setting.current ~= nil then
						settings[setting.id] = setting.current
					end
				end
			end
			if siriusValues and siriusValues.sliders then
				for _, slider in ipairs(siriusValues.sliders) do
					sliders[slider.name] = slider.value
				end
			end
		end)
		return settings, sliders
	end

	function SlateCloud.collectEspConfigs()
		if not (listfiles and isfolder and isfolder(SlateCloud.espDir)) then
			return nil
		end
		local out, any = {}, false
		pcall(function()
			for _, full in ipairs(listfiles(SlateCloud.espDir)) do
				local name = tostring(full):match("([^/\\]+)%.json$")
				if name then
					local decoded = SlateCloud.readJson(SlateCloud.espDir .. "/" .. name .. ".json")
					if decoded then
						out[name] = decoded
						any = true
					end
				end
			end
		end)
		return any and out or nil
	end

	function SlateCloud.collect(selection)
		local data = { schema = 1 }
		if SlateCloud.wants(selection, "settings") or SlateCloud.wants(selection, "sliders") then
			local settings, sliders = SlateCloud.collectSettings()
			if SlateCloud.wants(selection, "settings") and next(settings) then
				data.settings = settings
			end
			if SlateCloud.wants(selection, "sliders") and next(sliders) then
				data.sliders = sliders
			end
		end
		if SlateCloud.wants(selection, "keybinds") then
			pcall(function()
				if SlateBinds and next(SlateBinds.map) then
					local binds = {}
					for k, v in pairs(SlateBinds.map) do
						binds[k] = v
					end
					data.keybinds = binds
				end
			end)
		end
		for _, entry in ipairs(SlateCloud.files) do
			if entry.key ~= "keybinds" and SlateCloud.wants(selection, entry.key) then
				local value = SlateCloud.readJson(entry.path)
				if value ~= nil then
					data[entry.key] = value
				end
			end
		end
		if SlateCloud.wants(selection, "espConfigs") then
			local esp = SlateCloud.collectEspConfigs()
			if esp then
				data.espConfigs = esp
			end
		end
		return data
	end

	function SlateCloud.availableSections()
		local present = {}
		local settings, sliders = SlateCloud.collectSettings()
		if next(settings) then
			present.settings = true
		end
		if next(sliders) then
			present.sliders = true
		end
		pcall(function()
			if SlateBinds and next(SlateBinds.map) then
				present.keybinds = true
			end
		end)
		for _, entry in ipairs(SlateCloud.files) do
			if entry.key ~= "keybinds" and isfile and isfile(entry.path) then
				present[entry.key] = true
			end
		end
		if isfolder and isfolder(SlateCloud.espDir) then
			present.espConfigs = true
		end
		return present
	end

	function SlateCloud.apply(data, selection)
		if type(data) ~= "table" then
			return false, "That config is empty."
		end
		if not writefile then
			return false, "Your executor cannot write files."
		end
		SlateCloud.ensureFolders()
		local applied = {}
		local wantSettings = SlateCloud.wants(selection, "settings") and type(data.settings) == "table"
		local wantSliders = SlateCloud.wants(selection, "sliders") and type(data.sliders) == "table"
		if wantSettings or wantSliders then
			local merged = SlateCloud.readJson("slate/settings.srs")
			if type(merged) ~= "table" then
				merged = {}
			end
			if wantSettings then
				for k, v in pairs(data.settings) do
					merged[k] = v
				end
			end
			if wantSliders then
				for name, value in pairs(data.sliders) do
					merged["slider_" .. name] = value
				end
			end
			if SlateCloud.writeJson("slate/settings.srs", merged) then
				pcall(loadSettings)
				if wantSettings then
					applied[#applied + 1] = "settings"
				end
				if wantSliders then
					applied[#applied + 1] = "sliders"
				end
			end
		end
		if SlateCloud.wants(selection, "keybinds") and type(data.keybinds) == "table" then
			if SlateCloud.writeJson("slate/keybinds.json", data.keybinds) then
				pcall(function()
					SlateBinds.map = {}
					SlateBinds.load()
					SlateBinds.notifyChanged()
				end)
				applied[#applied + 1] = "keybinds"
			end
		end
		for _, entry in ipairs(SlateCloud.files) do
			if entry.key ~= "keybinds" and data[entry.key] ~= nil and SlateCloud.wants(selection, entry.key) then
				if SlateCloud.writeJson(entry.path, data[entry.key]) then
					applied[#applied + 1] = entry.key
				end
			end
		end
		if SlateCloud.wants(selection, "espConfigs") and type(data.espConfigs) == "table" then
			for name, value in pairs(data.espConfigs) do
				local safe = tostring(name):gsub("[^%w _%-]", "")
				if safe ~= "" then
					SlateCloud.writeJson(SlateCloud.espDir .. "/" .. safe .. ".json", value)
				end
			end
			applied[#applied + 1] = "espConfigs"
		end
		pcall(function()
			if loadAutoexecConfig then
				loadAutoexecConfig()
			end
		end)
		pcall(function()
			if _G.SlateReloadReanimConfig then
				_G.SlateReloadReanimConfig()
			end
		end)
		return true, applied
	end
	SlateCloud.chunkSize = 160 * 1024
	SlateCloud.singleShotMax = 120 * 1024

	function SlateCloud.progress(fn)
		SlateCloud.onProgress = fn
	end

	function SlateCloud.report(text)
		if SlateCloud.onProgress then
			pcall(SlateCloud.onProgress, text)
		end
	end

	function SlateCloud.save(name, setDefault, selection)
		local slot = tostring(name or ""):gsub("[^%w _%-%(%)%.]", ""):gsub("^%s+", ""):gsub("%s+$", "")
		if slot == "" then
			return nil, "Give the config a name first."
		end
		local data = SlateCloud.collect(selection)
		do
			local any = false
			for k in pairs(data) do
				if k ~= "schema" then
					any = true
					break
				end
			end
			if not any then
				return nil, "Pick at least one thing to save."
			end
		end
		local ok, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not ok or not encoded then
			return nil, "Could not encode your settings."
		end
		if #encoded <= SlateCloud.singleShotMax then
			local res, err = SlateCloud.request("POST", "/api/cloud/save", nil, {
				name = slot,
				data = data,
				setDefault = setDefault and true or false,
			})
			if res then
				return res
			end
			if err and not tostring(err):find("too") then
				return nil, err
			end
		end
		local begun, beginErr = SlateCloud.request("POST", "/api/cloud/save/begin", nil, {
			name = slot,
			setDefault = setDefault and true or false,
		})
		if not begun then
			return nil, beginErr
		end
		local size = tonumber(begun.chunkSize) or SlateCloud.chunkSize
		if size > SlateCloud.chunkSize then
			size = SlateCloud.chunkSize
		end
		local total = math.max(1, math.ceil(#encoded / size))
		for i = 1, total do
			local slice = encoded:sub((i - 1) * size + 1, i * size)
			SlateCloud.report(string.format("Uploading\u{2026} %d%%", math.floor((i - 1) / total * 100)))
			local sent, sendErr
			for attempt = 1, 2 do
				sent, sendErr = SlateCloud.request("POST", "/api/cloud/save/chunk", nil, {
					uploadId = begun.uploadId,
					seq = i - 1,
					chunk = slice,
				})
				if sent then
					break
				end
				if attempt == 1 then
					task.wait(0.35)
				end
			end
			if not sent then
				return nil, sendErr or "Upload failed part way through."
			end
		end
		SlateCloud.report("Finishing\u{2026}")
		local done, commitErr = SlateCloud.request("POST", "/api/cloud/save/commit", nil, {
			uploadId = begun.uploadId,
			parts = total,
		})
		if not done then
			return nil, commitErr
		end
		return done
	end

	function SlateCloud.sectionsOf(name)
		local query = name and { name = name } or nil
		local meta = SlateCloud.request("GET", "/api/cloud/load/meta", query)
		if meta and meta.sections then
			return meta.sections
		end
		local res, err = SlateCloud.request("GET", "/api/cloud/load", query)
		if not res then
			return nil, err
		end
		local out = {}
		for key in pairs(res.data or {}) do
			if key ~= "meta" and key ~= "schema" then
				out[#out + 1] = { key = key }
			end
		end
		return out
	end

	function SlateCloud.list()
		local res, err = SlateCloud.request("GET", "/api/cloud/list")
		if not res then
			return nil, err
		end
		return res
	end

	function SlateCloud.load(name, selection)
		local query = name and { name = name } or nil
		local meta = SlateCloud.request("GET", "/api/cloud/load/meta", query)
		if meta and meta.sections then
			local wanted = {}
			for _, section in ipairs(meta.sections) do
				if SlateCloud.wants(selection, section.key) then
					wanted[#wanted + 1] = section
				end
			end
			if #wanted == 0 then
				return nil, "Pick at least one thing to import."
			end
			local data = {}
			for i, section in ipairs(wanted) do
				SlateCloud.report(string.format("Downloading\u{2026} %d%%", math.floor((i - 1) / #wanted * 100)))
				local q = { section = section.key }
				if name then
					q.name = name
				end
				local got, err = SlateCloud.request("GET", "/api/cloud/load/section", q)
				if not got then
					return nil, err
				end
				data[section.key] = got.data
			end
			local ok, applied = SlateCloud.apply(data, selection)
			if not ok then
				return nil, applied
			end
			return { name = meta.name, applied = applied }
		end
		local res, err = SlateCloud.request("GET", "/api/cloud/load", query)
		if not res then
			return nil, err
		end
		local ok, applied = SlateCloud.apply(res.data, selection)
		if not ok then
			return nil, applied
		end
		return { name = res.name, applied = applied }
	end

	function SlateCloud.delete(name)
		local res, err = SlateCloud.request("POST", "/api/cloud/delete", nil, { name = name })
		if not res then
			return nil, err
		end
		return res
	end

	function SlateCloud.linkCode()
		local res, err = SlateCloud.request("POST", "/api/cloud/linkcode", nil, {})
		if not res then
			return nil, err
		end
		return res
	end
	SlateCloud.saveSelection = nil
	SlateCloud.importSelection = nil
	SlateCloud.importTarget = nil
	SlateCloud.PILL_W, SlateCloud.PILL_H, SlateCloud.KNOB, SlateCloud.PILL_PAD = 32, 18, 12, 3

	function SlateCloud.build()
		if SlateCloud.tab then
			return SlateCloud.tab
		end
		local tab = createTabFrame("CloudTab")
		SlateCloud.tab = tab
		local PILL_W, PILL_H = SlateCloud.PILL_W, SlateCloud.PILL_H
		local KNOB, PILL_PAD = SlateCloud.KNOB, SlateCloud.PILL_PAD
		local COL_L, COL_R, COL_W = 20, 320, 280
		local BODY_TOP, BODY_BOTTOM = 84, 406
		addLabel(tab, "Cloud Configs", UDim2.new(0, 300, 0, 32), UDim2.new(0.03, 0, 0.05, 0), true)
		local status = Instance.new("TextLabel", tab)
		status.Size = UDim2.new(0, 420, 0, 14)
		status.Position = UDim2.new(0, COL_L, 0, 60)
		status.BackgroundTransparency = 1
		status.Text = ""
		status.TextColor3 = Color3.fromRGB(140, 140, 148)
		status.TextSize = 11
		status.Font = Enum.Font.BuilderSans
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.TextTruncate = Enum.TextTruncate.AtEnd
		status.ZIndex = 4
		SlateCloud.setStatus = function(text)
			status.Text = text or ""
		end

		local function panel(x)
			local p = Instance.new("Frame", tab)
			p.Size = UDim2.new(0, COL_W, 0, BODY_BOTTOM - BODY_TOP)
			p.Position = UDim2.new(0, x, 0, BODY_TOP)
			p.BackgroundColor3 = Color3.fromRGB(16, 16, 19)
			p.BackgroundTransparency = 0.25
			p.BorderSizePixel = 0
			p.ZIndex = 3
			Instance.new("UICorner", p).CornerRadius = UDim.new(0, 10)
			local stroke = Instance.new("UIStroke", p)
			stroke.Color = Color3.fromRGB(38, 38, 42)
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			return p
		end

		local function heading(parent, text, y)
			local lbl = Instance.new("TextLabel", parent)
			lbl.Size = UDim2.new(0, 180, 0, 12)
			lbl.Position = UDim2.new(0, 14, 0, y)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = Color3.fromRGB(118, 118, 126)
			lbl.TextSize = 9.5
			lbl.Font = Enum.Font.BuilderSansBold
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextTruncate = Enum.TextTruncate.AtEnd
			lbl.ZIndex = 5
			return lbl
		end

		local function button(parent, text, pos, size, primary)
			LPS_ATTRIBUTES(VM(NONE))
			local btn = Instance.new("TextButton", parent)
			btn.Size = size
			btn.Position = pos
			btn.BackgroundColor3 = primary and Color3.fromRGB(238, 238, 242) or Color3.fromRGB(40, 40, 44)
			btn.BackgroundTransparency = primary and 0 or 0.2
			btn.BorderSizePixel = 0
			btn.Text = text
			btn.TextColor3 = primary and Color3.fromRGB(14, 14, 16) or Color3.fromRGB(228, 228, 233)
			btn.Font = Enum.Font.BuilderSansBold
			btn.TextSize = primary and 11.5 or 10.5
			btn.AutoButtonColor = false
			btn.ZIndex = 6
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
			if not primary then
				local stroke = Instance.new("UIStroke", btn)
				stroke.Color = Color3.fromRGB(52, 52, 58)
				stroke.Thickness = 1
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			end
			btn.MouseButton1Click:Connect(SlateUiSound.click)
			btn.MouseEnter:Connect(function()
				tweenService
					:Create(btn, TweenInfo.new(0.12), {
						BackgroundTransparency = primary and 0 or 0,
						BackgroundColor3 = primary and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(54, 54, 60),
					})
					:Play()
			end)
			btn.MouseLeave:Connect(function()
				tweenService
					:Create(btn, TweenInfo.new(0.12), {
						BackgroundTransparency = primary and 0 or 0.2,
						BackgroundColor3 = primary and Color3.fromRGB(238, 238, 242) or Color3.fromRGB(40, 40, 44),
					})
					:Play()
			end)
			return btn
		end

		local function toggleRow(parent, order, label, initial, onChange)
			LPS_ATTRIBUTES(VM(NONE))
			local row = Instance.new("TextButton", parent)
			row.LayoutOrder = order
			row.Size = UDim2.new(1, -10, 0, 26)
			row.BackgroundTransparency = 1
			row.Text = ""
			row.AutoButtonColor = false
			row.ZIndex = 5
			local lbl = Instance.new("TextLabel", row)
			lbl.Size = UDim2.new(1, -(PILL_W + 18), 1, 0)
			lbl.Position = UDim2.new(0, 6, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = label
			lbl.TextColor3 = Color3.fromRGB(200, 200, 205)
			lbl.Font = Enum.Font.BuilderSans
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextTruncate = Enum.TextTruncate.AtEnd
			lbl.ZIndex = 6
			local pill = Instance.new("Frame", row)
			pill.AnchorPoint = Vector2.new(1, 0.5)
			pill.Size = UDim2.new(0, PILL_W, 0, PILL_H)
			pill.Position = UDim2.new(1, -6, 0.5, 0)
			pill.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
			pill.BorderSizePixel = 0
			pill.ZIndex = 6
			Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
			local knob = Instance.new("Frame", pill)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Size = UDim2.new(0, KNOB, 0, KNOB)
			knob.BackgroundColor3 = Color3.fromRGB(110, 110, 115)
			knob.BorderSizePixel = 0
			knob.ZIndex = 7
			Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
			local off = UDim2.new(0, PILL_PAD + KNOB / 2, 0.5, 0)
			local on = UDim2.new(0, PILL_W - PILL_PAD - KNOB / 2, 0.5, 0)
			knob.Position = off
			local state = initial and true or false
			local function paint(animate)
				local info = TweenInfo.new(animate and 0.15 or 0)
				tweenService
					:Create(pill, info, {
						BackgroundColor3 = state and Color3.fromRGB(48, 48, 50) or Color3.fromRGB(28, 28, 30),
					})
					:Play()
				tweenService
					:Create(knob, info, {
						Position = state and on or off,
						BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 115),
					})
					:Play()
				lbl.TextColor3 = state and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(155, 155, 162)
			end
			paint(false)
			row.MouseButton1Click:Connect(function()
				SlateUiSound.click()
				state = not state
				paint(true)
				onChange(state)
			end)
			return function(v)
				if state == v then
					return
				end
				state = v
				paint(true)
			end
		end

		local function scrollList(parent, y, height)
			local scroll = Instance.new("ScrollingFrame", parent)
			scroll.Size = UDim2.new(1, -20, 0, height)
			scroll.Position = UDim2.new(0, 10, 0, y)
			scroll.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
			scroll.BackgroundTransparency = 0.3
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 0
			scroll.ScrollBarImageColor3 = Color3.fromRGB(64, 64, 70)
			scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			scroll.ZIndex = 4
			Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 8)
			local layout = Instance.new("UIListLayout", scroll)
			layout.Padding = UDim.new(0, 3)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			local pad = Instance.new("UIPadding", scroll)
			pad.PaddingTop = UDim.new(0, 6)
			pad.PaddingBottom = UDim.new(0, 6)
			pad.PaddingLeft = UDim.new(0, 5)
			return scroll
		end

		local function clear(frame)
			for _, child in ipairs(frame:GetChildren()) do
				if not (child:IsA("UIListLayout") or child:IsA("UIPadding") or child:IsA("UICorner")) then
					child:Destroy()
				end
			end
		end

		local function emptyRow(parent, text)
			local lbl = Instance.new("TextLabel", parent)
			lbl.Size = UDim2.new(1, -16, 0, 36)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = Color3.fromRGB(128, 128, 136)
			lbl.TextSize = 10.5
			lbl.Font = Enum.Font.BuilderSans
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextYAlignment = Enum.TextYAlignment.Top
			lbl.TextWrapped = true
			lbl.ZIndex = 5
			return lbl
		end
		local left = panel(COL_L)
		heading(left, "SAVE TO CLOUD", 14)
		local nameBox = Instance.new("TextBox", left)
		nameBox.Size = UDim2.new(1, -20, 0, 28)
		nameBox.Position = UDim2.new(0, 10, 0, 32)
		nameBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
		nameBox.BorderSizePixel = 0
		nameBox.Text = ""
		nameBox.PlaceholderText = "config name"
		nameBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 118)
		nameBox.TextColor3 = Color3.fromRGB(240, 240, 245)
		nameBox.Font = Enum.Font.BuilderSans
		nameBox.TextSize = 11.5
		nameBox.TextXAlignment = Enum.TextXAlignment.Left
		nameBox.ClearTextOnFocus = false
		nameBox.ZIndex = 5
		Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 7)
		Instance.new("UIPadding", nameBox).PaddingLeft = UDim.new(0, 9)
		local nameStroke = Instance.new("UIStroke", nameBox)
		nameStroke.Color = Color3.fromRGB(46, 46, 52)
		nameStroke.Thickness = 1
		nameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		heading(left, "WHAT TO SAVE", 76)
		local saveAllBtn = button(left, "All", UDim2.new(1, -104, 0, 70), UDim2.new(0, 42, 0, 20))
		local saveNoneBtn = button(left, "None", UDim2.new(1, -58, 0, 70), UDim2.new(0, 48, 0, 20))
		local saveList = scrollList(left, 96, 178)
		local saveBtn = button(left, "Save to cloud", UDim2.new(0, 10, 1, -42), UDim2.new(1, -20, 0, 32), true)
		local saveSetters = {}

		local function renderSaveList()
			LPS_ATTRIBUTES(VM(NONE))
			clear(saveList)
			saveSetters = {}
			local present = SlateCloud.availableSections()
			if SlateCloud.saveSelection == nil then
				SlateCloud.saveSelection = {}
				for key in pairs(present) do
					SlateCloud.saveSelection[key] = true
				end
			end
			local order, any = 0, false
			for _, entry in ipairs(SlateCloud.sections) do
				if present[entry.key] then
					any = true
					order = order + 1
					local key = entry.key
					saveSetters[key] = toggleRow(
						saveList,
						order,
						entry.label,
						SlateCloud.saveSelection[key],
						function(v)
							SlateCloud.saveSelection[key] = v or nil
						end
					)
				end
			end
			if not any then
				emptyRow(saveList, "Nothing on this device to save yet.")
			end
		end
		saveAllBtn.MouseButton1Click:Connect(function()
			for key, set in pairs(saveSetters) do
				SlateCloud.saveSelection[key] = true
				set(true)
			end
		end)
		saveNoneBtn.MouseButton1Click:Connect(function()
			for key, set in pairs(saveSetters) do
				SlateCloud.saveSelection[key] = nil
				set(false)
			end
		end)
		local right = panel(COL_R)
		heading(right, "YOUR CONFIGS", 14)
		local refreshBtn = button(right, "Refresh", UDim2.new(1, -170, 0, 8), UDim2.new(0, 62, 0, 22))
		local linkBtn = button(right, "Link account", UDim2.new(1, -104, 0, 8), UDim2.new(0, 94, 0, 22))
		local configList = scrollList(right, 36, 116)
		local importHeading = heading(right, "WHAT TO IMPORT", 164)
		importHeading.Size = UDim2.new(1, -120, 0, 12)
		local importAllBtn = button(right, "All", UDim2.new(1, -104, 0, 158), UDim2.new(0, 42, 0, 20))
		local importNoneBtn = button(right, "None", UDim2.new(1, -58, 0, 158), UDim2.new(0, 48, 0, 20))
		local importList = scrollList(right, 184, 90)
		local importBtn = button(right, "Import selected", UDim2.new(0, 10, 1, -42), UDim2.new(1, -20, 0, 32), true)
		local importSetters = {}
		local renderConfigList

		local function setImportButtons(enabled)
			importAllBtn.Visible = enabled
			importNoneBtn.Visible = enabled
		end

		local function renderImportList()
			LPS_ATTRIBUTES(VM(NONE))
			clear(importList)
			importSetters = {}
			if not SlateCloud.importTarget then
				importHeading.Text = "WHAT TO IMPORT"
				importBtn.Text = "Import selected"
				setImportButtons(false)
				emptyRow(importList, "Click a config above to choose what to bring in.")
				return
			end
			importHeading.Text = "WHAT TO IMPORT  \u{2014}  " .. string.upper(SlateCloud.importTarget)
			importBtn.Text = "Import into game"
			setImportButtons(true)
			emptyRow(importList, "Reading config\u{2026}")
			task.spawn(function()
				local sections, err = SlateCloud.sectionsOf(SlateCloud.importTarget)
				clear(importList)
				if not sections then
					emptyRow(importList, err or "Could not read that config.")
					setImportButtons(false)
					return
				end
				if #sections == 0 then
					emptyRow(importList, "That config is empty.")
					setImportButtons(false)
					return
				end
				local usable = {}
				for _, section in ipairs(sections) do
					if not SlateCloud.retired[section.key] then
						usable[#usable + 1] = section
					end
				end
				sections = usable
				if #sections == 0 then
					emptyRow(importList, "Nothing in this config can be imported any more.")
					setImportButtons(false)
					return
				end
				SlateCloud.importSelection = {}
				for _, section in ipairs(sections) do
					SlateCloud.importSelection[section.key] = true
				end
				local seen, ordered = {}, {}
				for _, entry in ipairs(SlateCloud.sections) do
					for _, section in ipairs(sections) do
						if section.key == entry.key and not seen[entry.key] then
							ordered[#ordered + 1] = { key = entry.key, label = entry.label }
							seen[entry.key] = true
						end
					end
				end
				for _, section in ipairs(sections) do
					if not seen[section.key] then
						seen[section.key] = true
						ordered[#ordered + 1] = { key = section.key, label = section.key }
					end
				end
				for i, entry in ipairs(ordered) do
					local key = entry.key
					importSetters[key] = toggleRow(importList, i, entry.label, true, function(v)
						SlateCloud.importSelection[key] = v or nil
					end)
				end
			end)
		end
		importAllBtn.MouseButton1Click:Connect(function()
			SlateCloud.importSelection = SlateCloud.importSelection or {}
			for key, set in pairs(importSetters) do
				SlateCloud.importSelection[key] = true
				set(true)
			end
		end)
		importNoneBtn.MouseButton1Click:Connect(function()
			SlateCloud.importSelection = SlateCloud.importSelection or {}
			for key, set in pairs(importSetters) do
				SlateCloud.importSelection[key] = nil
				set(false)
			end
		end)

		local function configRow(index, entry)
			local selected = (SlateCloud.importTarget == entry.name)
			local row = Instance.new("TextButton", configList)
			row.LayoutOrder = index
			row.Size = UDim2.new(1, -14, 0, 40)
			row.BackgroundColor3 = selected and Color3.fromRGB(32, 32, 38) or Color3.fromRGB(19, 19, 23)
			row.BorderSizePixel = 0
			row.Text = ""
			row.AutoButtonColor = false
			row.ZIndex = 5
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
			local rowStroke = Instance.new("UIStroke", row)
			rowStroke.Color = selected and Color3.fromRGB(120, 120, 130) or Color3.fromRGB(34, 34, 40)
			rowStroke.Thickness = 1
			rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			local name = Instance.new("TextLabel", row)
			name.Size = UDim2.new(1, -78, 0, 14)
			name.Position = UDim2.new(0, 11, 0, 6)
			name.BackgroundTransparency = 1
			name.Text = entry.isDefault and (entry.name .. "  \u{2022}  default") or entry.name
			name.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(226, 226, 232)
			name.TextSize = 11.5
			name.Font = Enum.Font.BuilderSansBold
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.ZIndex = 6
			local sub = Instance.new("TextLabel", row)
			sub.Size = UDim2.new(1, -78, 0, 12)
			sub.Position = UDim2.new(0, 11, 0, 21)
			sub.BackgroundTransparency = 1
			sub.Text = selected and string.format("selected  \u{b7}  %d sections", #(entry.sections or {}))
				or string.format("%d sections  \u{b7}  %.1f KB", #(entry.sections or {}), (entry.sizeBytes or 0) / 1024)
			sub.TextColor3 = selected and Color3.fromRGB(170, 170, 180) or Color3.fromRGB(124, 124, 132)
			sub.TextSize = 10
			sub.Font = Enum.Font.BuilderSans
			sub.TextXAlignment = Enum.TextXAlignment.Left
			sub.TextTruncate = Enum.TextTruncate.AtEnd
			sub.ZIndex = 6
			row.MouseEnter:Connect(function()
				if SlateCloud.importTarget == entry.name then
					return
				end
				tweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(26, 26, 31) }):Play()
			end)
			row.MouseLeave:Connect(function()
				if SlateCloud.importTarget == entry.name then
					return
				end
				tweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(19, 19, 23) }):Play()
			end)
			row.MouseButton1Click:Connect(function()
				if SlateCloud.importTarget == entry.name then
					SlateCloud.importTarget = nil
					SlateCloud.importSelection = nil
				else
					SlateCloud.importTarget = entry.name
				end
				renderConfigList()
				renderImportList()
			end)
			local delBtn = button(row, "Delete", UDim2.new(1, -58, 0.5, -11), UDim2.new(0, 50, 0, 22))
			delBtn.ZIndex = 8
			delBtn.MouseButton1Click:Connect(function()
				if SlateCloud.busy then
					return
				end
				SlateCloud.busy = true
				SlateCloud.setStatus("Deleting '" .. entry.name .. "'\u{2026}")
				task.spawn(function()
					local res, err = SlateCloud.delete(entry.name)
					SlateCloud.busy = false
					if not res then
						SlateCloud.setStatus(err)
						return
					end
					if SlateCloud.importTarget == entry.name then
						SlateCloud.importTarget = nil
						renderImportList()
					end
					SlateCloud.setStatus("Deleted '" .. entry.name .. "'.")
					renderConfigList()
				end)
			end)
		end
		renderConfigList = function()
			clear(configList)
			emptyRow(configList, "Loading\u{2026}")
			task.spawn(function()
				local res, err = SlateCloud.list()
				clear(configList)
				if not res then
					emptyRow(configList, err)
					return
				end
				if #res.configs == 0 then
					emptyRow(configList, "No cloud configs yet. Name one on the left and press Save to cloud.")
				else
					for i, entry in ipairs(res.configs) do
						configRow(i, entry)
					end
				end
				linkBtn.Text = res.linked and "Account linked" or "Link account"
				SlateCloud.setStatus(string.format("%d of %d slots used.", #res.configs, res.limit or 0))
			end)
		end
		SlateCloud.renderList = renderConfigList
		saveBtn.MouseButton1Click:Connect(function()
			if SlateCloud.busy then
				return
			end
			SlateCloud.busy = true
			SlateCloud.setStatus("Saving\u{2026}")
			task.spawn(function()
				SlateCloud.progress(function(text)
					SlateCloud.setStatus(text)
				end)
				local res, err = SlateCloud.save(nameBox.Text, false, SlateCloud.saveSelection)
				SlateCloud.progress(nil)
				SlateCloud.busy = false
				if not res then
					SlateCloud.setStatus(err)
					SlateCloud.notify("Cloud Configs", err)
					return
				end
				nameBox.Text = ""
				SlateCloud.notify("Cloud Configs", "Saved '" .. res.config.name .. "' to the cloud.")
				renderConfigList()
			end)
		end)
		importBtn.MouseButton1Click:Connect(function()
			if SlateCloud.busy then
				return
			end
			if not SlateCloud.importTarget then
				SlateCloud.setStatus("Click a config first, then pick what to import.")
				return
			end
			SlateCloud.busy = true
			SlateCloud.setStatus("Importing\u{2026}")
			task.spawn(function()
				SlateCloud.progress(function(text)
					SlateCloud.setStatus(text)
				end)
				local res, err = SlateCloud.load(SlateCloud.importTarget, SlateCloud.importSelection)
				SlateCloud.progress(nil)
				SlateCloud.busy = false
				if not res then
					SlateCloud.setStatus(err)
					SlateCloud.notify("Cloud Configs", err)
					return
				end
				SlateCloud.setStatus("Imported " .. #(res.applied or {}) .. " section(s) from '" .. res.name .. "'.")
				SlateCloud.notify(
					"Cloud Configs",
					"Imported '" .. res.name .. "'. Rejoin to reapply reanimate animations."
				)
			end)
		end)
		refreshBtn.MouseButton1Click:Connect(function()
			renderSaveList()
			renderConfigList()
		end)
		linkBtn.MouseButton1Click:Connect(function()
			if SlateCloud.busy then
				return
			end
			SlateCloud.busy = true
			task.spawn(function()
				local res, err = SlateCloud.linkCode()
				SlateCloud.busy = false
				if not res then
					SlateCloud.setStatus(err)
					return
				end
				if res.alreadyLinked then
					SlateCloud.setStatus("This account is already linked to your Discord.")
					return
				end
				SlateCloud.setStatus("Code " .. res.code .. " \u{2014} enter it on the dashboard within 15 minutes.")
				if setclipboard then
					pcall(setclipboard, res.code)
				end
				SlateCloud.notify(
					"Cloud Configs",
					"Link code: " .. res.code .. "\nCopied to clipboard. Enter it at sl8ght.xyz/dash."
				)
			end)
		end)
		SlateCloud.refreshPanes = function()
			renderSaveList()
			renderImportList()
			renderConfigList()
		end
		renderSaveList()
		renderImportList()
		return tab
	end

	function SlateCloud.openTab()
		local tab = SlateCloud.build()
		switchTab(tab)
		if SlateCloud.refreshPanes then
			SlateCloud.refreshPanes()
		end
	end
	SlateCloud.toggleWindow = SlateCloud.openTab
	_G.SlateToggleCloudConfigs = SlateCloud.openTab

local function runAnimCopier()
if _G.__SlateAnimCopierWindow and _G.__SlateAnimCopierWindow.Parent and _G.__SlateAnimCopierToggle then
    return _G.__SlateAnimCopierToggle()
end

local ReanimAPI = (function()
    local zen: any = {
        services = {
            players = game:GetService("Players");
            workspace = game:GetService("Workspace");
            replicated = game:GetService("ReplicatedStorage");
            run_service = game:GetService("RunService");
            user_input_service = game:GetService("UserInputService");
            http_service = game:GetService("HttpService");
        };
        flags = { reanimated = false; is_processing = false; };
        clones = {};
        connections = {
            hb = nil; died = nil; real_char_child_removed = nil;
            character_removing = nil; clone_died = nil;
            clone_char_child_removed = nil; animation_hb = nil;
        };
        real_chars = {};
        original_transparencies = {};
        callbacks = { on_play = nil, on_stop = nil, };
        animation = {
            cache = {};
            state = {
                is_playing = false; current_url = nil; speed = 1.0;
                keyframes = nil; total_duration = 0; elapsed_time = 0;
            };
            original_motor_c0s = {};
            joints = {};
        };
    };

    local API: any = {};

    local get_game_ragdoll_info = function(enable)
        local place_id = game.PlaceId;
        if place_id == 15546218972 or place_id == 6884319169 then
            if enable == false then return nil, nil, false end
            local remote = zen.services.replicated:FindFirstChild("event_rag");
            if not remote then return nil, nil, false end
            return remote, {"Ball"}, false;
        elseif place_id == 5991163185 then
            local remote = zen.services.replicated:FindFirstChild("Remotes")
                and zen.services.replicated.Remotes:FindFirstChild("Physics")
                and zen.services.replicated.Remotes.Physics:FindFirstChild("Ragdoll");
            if not remote then return nil, nil, false end
            return remote, {}, false;
        elseif place_id == 5683833663 then
            local local_event = zen.services.replicated:FindFirstChild("LocalRagdollEvent");
            if not local_event then return nil, nil, false end
            return local_event, {enable}, true;
        end;
        return nil, nil, false;
    end;

    local set_model_transparency = function(model, transparency)
        if not model then return end;
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then part.Transparency = transparency; end;
        end;
    end;

    local get_local_player = function()
        local player = zen.services.players.LocalPlayer;
        if not player then return "LocalPlayer not found"; end;
        return player;
    end;

    local get_char = function(player)
        if typeof(player) ~= "Instance" or not player:IsA("Player") then
            return ("bad argument to get_char (Player expected, got %s)"):format(typeof(player));
        end;
        local character = player.Character;
        if not character or not character.Parent then
            return ("Player %s has no active character."):format(player.Name);
        end;
        return character;
    end;

    local clone_char = function(model)
        if typeof(model) ~= "Instance" then
            return ("bad argument to clone_char (Instance expected, got %s)"):format(typeof(model));
        end;
        local old_archivables = {}
        old_archivables[model] = model.Archivable
        model.Archivable = true;
        for _, desc in ipairs(model:GetDescendants()) do
            old_archivables[desc] = desc.Archivable
            desc.Archivable = true
        end
        local new_clone = model:Clone();
        for _, desc in ipairs(new_clone:GetDescendants()) do
            if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui")
               or desc:IsA("Highlight") or desc:IsA("ParticleEmitter") then
                desc:Destroy()
            end
        end

        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Motor6D") and desc.Part0 and desc.Part1 then
                local p0_name = desc.Part0.Name
                local p1_name = desc.Part1.Name
                local clone_p1 = new_clone:FindFirstChild(p1_name, true)
                if clone_p1 then
                    local existing = clone_p1:FindFirstChild(desc.Name)
                    if not existing then
                        local clone_p0 = new_clone:FindFirstChild(p0_name, true)
                        if clone_p0 then
                            local nm = Instance.new("Motor6D")
                            nm.Name = desc.Name
                            nm.Part0 = clone_p0; nm.Part1 = clone_p1
                            nm.C0 = desc.C0;     nm.C1 = desc.C1
                            nm.Parent = clone_p1
                        end
                    end
                end
            end
        end
        for obj, arch in pairs(old_archivables) do
            if obj and obj.Parent then obj.Archivable = arch end
        end
        new_clone.Name = "Reanimation";
        new_clone.Parent = zen.services.workspace;
        local animate_script = new_clone:FindFirstChild("Animate");
        if animate_script then animate_script.Disabled = true; end;
        if new_clone.Humanoid then
            new_clone.Humanoid.RequiresNeck = false;
            new_clone.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
        end
        if new_clone:FindFirstChildWhichIsA("ForceField") then
            new_clone:FindFirstChildWhichIsA("ForceField"):Destroy();
        end;
        return new_clone;
    end;

    local fire_remote = function(remote, is_local, ...)
        if typeof(remote) ~= "Instance" then
            return ("bad argument to fire_remote (Instance expected, got %s)"):format(typeof(remote));
        end;
        if is_local then
            if not remote:IsA("BindableEvent") then
                return "fire_remote expected BindableEvent for local event";
            end;
            remote:Fire(...);
        else
            if not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                return "fire_remote expected RemoteEvent or RemoteFunction";
            end;
            if remote:IsA("RemoteEvent") then remote:FireServer(...);
            else remote:InvokeServer(...); end;
        end;
    end;

    API.stop_animation = function()
        if not zen.animation.state.is_playing then return end;
        local stopped_url = zen.animation.state.current_url
        if zen.connections.animation_hb then
            zen.connections.animation_hb:Disconnect();
            zen.connections.animation_hb = nil;
        end
        local player = get_local_player();
        if typeof(player) == "string" then return player end;
        local cc = API.get_clone(player);
        if cc then
            for motor, orig_c0 in pairs(zen.animation.original_motor_c0s) do
                if motor and motor.Parent then
                    if motor:IsA("Motor6D") or motor:IsA("Motor") or motor:IsA("Weld") then
                        pcall(function() motor.C0 = orig_c0 end)
                    else
                        pcall(function() motor.Transform = orig_c0 end)
                    end
                end
            end
            local animator = cc:FindFirstChild("Humanoid") and cc.Humanoid:FindFirstChild("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
            end
            local as = cc:FindFirstChild("Animate")
            if as and as:IsA("LocalScript") then
                as.Disabled = true; task.wait(); as.Disabled = false
            end
        end
        table.clear(zen.animation.original_motor_c0s);
        table.clear(zen.animation.joints);
        zen.animation.state = { is_playing=false, current_url=nil, speed=1.0,
                                keyframes=nil, total_duration=0, elapsed_time=0 };
        if zen.callbacks.on_stop then pcall(zen.callbacks.on_stop, stopped_url) end
    end;

    API.reanimate = function(bool, remote, args)
        if bool ~= true and bool ~= false then
            return ("bad argument to reanimate (boolean expected, got %s)"):format(typeof(bool));
        end;
        if zen.flags.is_processing then return "Busy processing reanimation request"; end;
        zen.flags.is_processing = true;
        local success, result = pcall(function()
            return API._reanimate_internal(bool, remote, args)
        end)
        zen.flags.is_processing = false;
        if not success then return "Reanimation error: " .. tostring(result); end
        return result;
    end;

    API._reanimate_internal = function(bool, remote, args)
        local player = get_local_player();
        if typeof(player) == "string" then return player end;
        local is_local_event = false;
        if not remote then
            local gr, ga, il = get_game_ragdoll_info(bool);
            if gr then remote = gr; args = ga; is_local_event = il; end;
        end;
        if bool then
            if zen.flags.reanimated then return "Already reanimated."; end;
            local real_char = get_char(player);
            if typeof(real_char) == "string" then return real_char end;
            if not real_char:FindFirstChild("Humanoid") then return "Real char missing Humanoid."; end;
            real_char.Humanoid.RequiresNeck = false;
            real_char.Humanoid.BreakJointsOnDeath = false;
            local real_hrp = real_char:FindFirstChild("HumanoidRootPart")
            if not real_hrp then return "Real char missing HRP."; end
            zen.real_chars[player] = real_char;
            local original_transparencies = {}
            for _, desc in ipairs(real_char:GetDescendants()) do
                if desc:IsA("BasePart") then
                    original_transparencies[desc] = desc.Transparency
                end
            end
            zen.original_transparencies[player] = original_transparencies
            local cloned_char = clone_char(real_char);
            if typeof(cloned_char) == "string" then return cloned_char end;
            if not cloned_char:FindFirstChild("Humanoid") then return "Clone failed to create Humanoid."; end;
            zen.clones[player] = cloned_char;
            set_model_transparency(cloned_char, 1);
            for _, desc in ipairs(real_char:GetDescendants()) do
                if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
                    pcall(function() desc:Destroy() end)
                elseif desc:IsA("Motor6D") or desc:IsA("Weld") or desc:IsA("WeldConstraint") then
                    pcall(function() desc:Destroy() end)
                elseif desc:IsA("BasePart") then
                    pcall(function() desc.CanCollide = false end)
                end
            end
            local saved_gui_states = {};
            local player_gui = player:FindFirstChildWhichIsA("PlayerGui");
            if player_gui then
                for _, gui in player_gui:GetChildren() do
                    if gui:IsA("ScreenGui") then
                        saved_gui_states[gui] = gui.ResetOnSpawn;
                        gui.ResetOnSpawn = false;
                    end;
                end;
            end;
            player.Character = cloned_char;
            if workspace.CurrentCamera and cloned_char:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = cloned_char.Humanoid;
            end
            local as = cloned_char:FindFirstChild("Animate");
            if as then as.Disabled = true; as.Disabled = false; end;
            task.spawn(function()
                task.wait();
                if player_gui then
                    for gui, state in pairs(saved_gui_states) do
                        if gui and gui.Parent then gui.ResetOnSpawn = state; end;
                    end;
                end;
            end);
            local lastCFrames = {}
            local lastPosUpdate = os.clock()

            local function syncRealParts()
                LPS_ATTRIBUTES(VM(NONE))
                if not real_char or not real_char.Parent
                   or not cloned_char or not cloned_char.Parent then
                    API.reanimate(false, remote, args); return;
                end;

                local now = os.clock()
                local dt = math.max(now - lastPosUpdate, 0.001)
                lastPosUpdate = now

                local targetBaseVel = Vector3.zero
                local repTarget = real_hrp
                pcall(function()
                    if State and State.copyActive and State.selectedPlayer and State.selectedPlayer.Character then
                        local tHRP = State.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if tHRP then
                            targetBaseVel = tHRP.AssemblyLinearVelocity
                            repTarget = tHRP
                        end
                    else
                        local cHRP = cloned_char:FindFirstChild("HumanoidRootPart")
                        if cHRP then targetBaseVel = cHRP.AssemblyLinearVelocity end
                    end
                end)

                local function findClonePart(p)
                    if p.Parent == real_char then
                        return cloned_char:FindFirstChild(p.Name)
                    elseif p.Parent then
                        local pParentClone = cloned_char:FindFirstChild(p.Parent.Name)
                        if pParentClone then
                            local cp = pParentClone:FindFirstChild(p.Name)
                            if cp then return cp end
                        end
                    end
                    return cloned_char:FindFirstChild(p.Name, true)
                end

                for _, p in ipairs(real_char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        local cp = findClonePart(p)
                        if cp then
                            local targetCF = cp.CFrame
                            p.CanCollide = false

                            local prevCF = lastCFrames[p] or targetCF
                            local calcVel = (targetCF.Position - prevCF.Position) / dt
                            lastCFrames[p] = targetCF

                            local finalVel = targetBaseVel + calcVel + Vector3.new(0, 25.1, 0)

                            pcall(function() p.AssemblyLinearVelocity = finalVel end)
                            pcall(function() p.Velocity = finalVel end)
                            pcall(function() p.AssemblyAngularVelocity = cp.AssemblyAngularVelocity end)
                            if sethiddenproperty and repTarget then
                                pcall(sethiddenproperty, p, "PhysicsRepRootPart", repTarget)
                            end
                        end
                    end;
                end;
            end;

            pcall(function()
                if setscriptable then pcall(setscriptable, player, "SimulationRadius", true) end
                pcall(function() player.SimulationRadius = 1000 end)
            end)

            for _, p in ipairs(real_char:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function()
                        if sethiddenproperty then
                            pcall(sethiddenproperty, p, "NetworkIsDistanceFiltered", false)
                            if real_hrp then
                                pcall(sethiddenproperty, p, "PhysicsRepRootPart", real_hrp)
                            end
                        end
                        if setnetworkowner then
                            pcall(setnetworkowner, p, player)
                        end
                    end)
                end
            end

            zen.connections.hb = zen.services.run_service.PreSimulation:Connect(syncRealParts);
            local rh = real_char.Humanoid;
            local ch = cloned_char.Humanoid;
            zen.connections.died = rh.Died:Connect(function()
                if _G._isCloningAvatar or game.PlaceId == 6884319169 or game.PlaceId == 15546218972 then return end;
                API.reanimate(false, remote, args);
            end);
            zen.connections.real_char_child_removed = real_char.ChildRemoved:Connect(function(child)
                if _G._isCloningAvatar or game.PlaceId == 6884319169 or game.PlaceId == 15546218972 then return end;
                if child == rh or child == real_hrp then API.reanimate(false, remote, args); end;
            end);
            zen.connections.clone_char_child_removed = cloned_char.ChildRemoved:Connect(function(child)
                if _G._isCloningAvatar then return end;
                if child == ch then API.reanimate(false, remote, args); end;
            end);
            zen.connections.clone_died = ch.Died:Connect(function()
                if _G._isCloningAvatar or game.PlaceId == 6884319169 or game.PlaceId == 15546218972 then return end;
                local crh = real_char and real_char:FindFirstChild("Humanoid");
                if crh and crh.Health > 0 then crh.Health = 0;
                else API.reanimate(false, remote, args); end;
            end);
            zen.connections.character_removing = player.CharacterRemoving:Connect(function(cbr)
                if _G._isCloningAvatar or game.PlaceId == 6884319169 or game.PlaceId == 15546218972 then return end;
                if cbr == cloned_char or cbr == real_char then API.reanimate(false, remote, args); end;
            end);
            if remote then
                local err = fire_remote(remote, is_local_event, unpack(args or {}));
                if err then return err end;
            end;
            zen.flags.reanimated = true;
        else
            if not zen.flags.reanimated then return; end;
            API.stop_animation();
            if remote then
                local err = fire_remote(remote, is_local_event, unpack(args or {}));
                if err then return err end;
            end;
            for key, connection in pairs(zen.connections) do
                if connection then connection:Disconnect(); zen.connections[key] = nil; end;
            end;
            local cc = zen.clones[player];
            if cc and cc.Parent then cc:Destroy(); zen.clones[player] = nil; end;
            local rc = zen.real_chars[player];
            if rc and rc.Parent then
                local original_transparencies = zen.original_transparencies[player]
                if original_transparencies then
                    for part, transparency in pairs(original_transparencies) do
                        if part and part.Parent then
                            pcall(function() part.Transparency = transparency end)
                        end
                    end
                else
                    set_model_transparency(rc, 0)
                end
                zen.original_transparencies[player] = nil
                local hrp = rc:FindFirstChild("HumanoidRootPart");
                if hrp then hrp.Transparency = 1; end;
                local sgs = {};
                local pg = player:FindFirstChildWhichIsA("PlayerGui");
                if pg then
                    for _, gui in pg:GetChildren() do
                        if gui:IsA("ScreenGui") then
                            sgs[gui] = gui.ResetOnSpawn; gui.ResetOnSpawn = false;
                        end;
                    end;
                end;
                player.Character = rc;
                if workspace.CurrentCamera and rc:FindFirstChild("Humanoid") then
                    workspace.CurrentCamera.CameraSubject = rc.Humanoid;
                end
                local animator = rc:FindFirstChild("Humanoid") and rc.Humanoid:FindFirstChild("Animator");
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(); end
                end
                local as2 = rc:FindFirstChild("Animate");
                if as2 and as2:IsA("LocalScript") then
                    as2.Disabled = true; task.wait(); as2.Disabled = false;
                end;
                task.spawn(function()
                    task.wait();
                    if pg then
                        for gui, state in pairs(sgs) do
                            if gui and gui.Parent then gui.ResetOnSpawn = state; end;
                        end;
                    end;
                    if _SlateFixMobileControls then _SlateFixMobileControls(rc); end;
                end);
            end;
            zen.flags.reanimated = false;
        end;
    end;

    API.is_reanimated = function() return zen.flags.reanimated; end;
    API.get_clone = function(player)
        player = player or get_local_player();
        if typeof(player) == "string" then return nil end;
        return zen.clones[player];
    end;
    API.get_real_character = function(player)
        player = player or get_local_player();
        if typeof(player) == "string" then return nil end;
        return zen.real_chars[player];
    end;
    API.on_animation_play = function(cb)
        if type(cb) == "function" then zen.callbacks.on_play = cb end
    end
    API.on_animation_stop = function(cb)
        if type(cb) == "function" then zen.callbacks.on_stop = cb end
    end
    API.is_animation_playing = function()
        return zen.animation.state.is_playing, zen.animation.state.current_url
    end
    return API;
end)()
_G.SlateReanimAPI = ReanimAPI

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local plr       = Players.LocalPlayer
local PlayerGui = plr:WaitForChild("PlayerGui")

local function _SlateFixMobileControls(char)
	task.spawn(function()
		local player = Players.LocalPlayer or game:GetService("Players").LocalPlayer
		if not player then return end
		char = char or player.Character or player.CharacterAdded:Wait()
		if not char then return end

		task.wait(0.15)

		local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)

		if hum then
			pcall(function()
				hum.PlatformStand = false
				hum.AutoRotate = true
				if hum.WalkSpeed <= 0 then
					hum.WalkSpeed = 16
				end
				if hum.JumpPower <= 0 and hum.JumpHeight <= 0 then
					hum.JumpPower = 50
				end
			end)
		end

		if hrp then
			pcall(function()
				hrp.Anchored = false
			end)
		end

		pcall(function()
			UserInputService.ModalEnabled = false
		end)

		pcall(function()
			if workspace.CurrentCamera and hum then
				workspace.CurrentCamera.CameraSubject = hum
				workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			end
		end)

		pcall(function()
			local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 3)
			if pg then
				local touchGui = pg:FindFirstChild("TouchGui")
				if touchGui then
					touchGui.Enabled = true
					for _, desc in ipairs(touchGui:GetDescendants()) do
						if desc:IsA("GuiObject") then
							desc.Visible = true
						end
					end
				end
			end
		end)

		pcall(function()
			local ps = player:FindFirstChildOfClass("PlayerScripts")
			if ps then
				local pm = ps:FindFirstChild("PlayerModule")
				if pm then
					local module = require(pm)
					if module and module.GetControls then
						local controls = module:GetControls()
						if controls and controls.Enable then
							controls:Enable(true)
						end
					end
				end
			end
		end)
	end)
end
_G._SlateFixMobileControls = _SlateFixMobileControls

pcall(function()
	if Players and Players.LocalPlayer then
		Players.LocalPlayer.CharacterAdded:Connect(function(nChar)
			_SlateFixMobileControls(nChar)
		end)
	end
end)

do
    local targets = { PlayerGui }
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then table.insert(targets, 1, cg) end
    for _, target in ipairs(targets) do
        pcall(function()
            local old = target:FindFirstChild("OnyxAnimCopierV2")
            if old then old:Destroy() end
        end)
    end
end

local State = {
    selectedPlayer = nil,
    copyActive     = false,
    copyDistance   = 4.0,
    copySide       = 1,
    copyAnywhere   = false,
    myClone        = nil,
    myRealChar     = nil,
    jointPairs     = {},
    copyConn       = nil,
    builtForChar   = nil,
}

local C = {
    BG            = Color3.fromRGB(12, 12, 12),
    PANEL         = Color3.fromRGB(14, 14, 14),
    PANEL_HOVER   = Color3.fromRGB(22, 22, 22),
    BORDER        = Color3.fromRGB(32, 32, 32),
    BORDER_SOFT   = Color3.fromRGB(30, 30, 30),
    TOGGLE_OFF    = Color3.fromRGB(45, 45, 45),
    KNOB_INACTIVE = Color3.fromRGB(150, 150, 150),
    WHITE         = Color3.fromRGB(255, 255, 255),
    TEXT          = Color3.fromRGB(220, 220, 220),
    MUTED         = Color3.fromRGB(140, 140, 140),
    DIM           = Color3.fromRGB(100, 100, 100),
    ACCENT        = Color3.fromRGB(255, 255, 255),
    RED           = Color3.fromRGB(255, 90, 90),
    ROW_BG        = Color3.fromRGB(18, 18, 18),
    ROW_SELECTED  = Color3.fromRGB(30, 30, 30),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

local function addBorderStroke(parent, color, thickness)
    LPS_ATTRIBUTES(VM(NONE))
    local stroke = Instance.new("UIStroke", parent)
    pcall(function() stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
    stroke.Color = color or C.BORDER
    stroke.Thickness = thickness or 1
    local grad = Instance.new("UIGradient", stroke)
    grad.Rotation = 45
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(120, 120, 120)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40,  40,  40)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(90,  90,  90)),
    })
    return stroke
end

local function padding(p, all, l, r, t, b)
    local pd = Instance.new("UIPadding", p)
    pd.PaddingLeft   = UDim.new(0, l or all or 0)
    pd.PaddingRight  = UDim.new(0, r or all or 0)
    pd.PaddingTop    = UDim.new(0, t or all or 0)
    pd.PaddingBottom = UDim.new(0, b or all or 0)
    return pd
end

local activateBtn, statusLabel, copyAnywhereKnob, copyAnywhereFrame
local distRow, sideRow, distValLbl
local setActivateBtn, updateStatus, setCopyAnywhereVisuals
local Notify

local function buildJointPairs(cloneModel, targetChar)
    LPS_ATTRIBUTES(VM(NONE))
    local tMap = {}
    for _, d in ipairs(targetChar:GetDescendants()) do
        if d:IsA("Motor6D") and d.Part0 and d.Part1 then
            tMap[d.Name] = d
        end
    end
    local out = {}
    for _, d in ipairs(cloneModel:GetDescendants()) do
        if d:IsA("Motor6D") and d.Part0 and d.Part1 then
            local t = tMap[d.Name]
            if t then table.insert(out, { cm = d, tm = t }) end
        end
    end
    return out
end

local function applyAnchorForMode()
    if not State.myClone then return end
    local hrp = State.myClone:FindFirstChild("HumanoidRootPart")
    if hrp then

        pcall(function() hrp.Anchored = not State.copyAnywhere end)
    end
    local hum = State.myClone:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.PlatformStand = false end)
        if State.copyAnywhere then
            pcall(function()
                if hum.WalkSpeed <= 0 then hum.WalkSpeed = 16 end
                if hum.JumpPower <= 0 then hum.JumpPower = 50 end
            end)
        end
    end
end

local function stopCopying()
    State.copyActive = false
    State.jointPairs = {}
    if State.copyConn then State.copyConn:Disconnect(); State.copyConn = nil end
    if State.copyConn2 then State.copyConn2:Disconnect(); State.copyConn2 = nil end

    if State.myRealChar and State.myClone then
        for _, clonePart in ipairs(State.myClone:GetChildren()) do
            if clonePart:IsA("BasePart") then
                local realPart = State.myRealChar:FindFirstChild(clonePart.Name)
                if realPart then
                    for _, child in ipairs(clonePart:GetChildren()) do
                        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                            pcall(function() child.Parent = realPart end)
                        end
                    end
                end
            end
        end
        for _, d in ipairs(State.myRealChar:GetDescendants()) do
            if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                pcall(function() d.Enabled = true end)
            end
        end
    end
    State.myRealChar = nil

    if ReanimAPI.is_reanimated() then
        pcall(function() ReanimAPI.reanimate(false) end)
    end
    if _SlateFixMobileControls then _SlateFixMobileControls() end
    State.myClone = nil
    if updateStatus then updateStatus() end
    if setActivateBtn then setActivateBtn(false) end
    if Notify then Notify("Stopped \u{2014} character restored") end
end

local function doStartCopying()
    local tChar = State.selectedPlayer and State.selectedPlayer.Character
    if not tChar or not tChar.Parent then
        Notify((State.selectedPlayer and State.selectedPlayer.DisplayName or "Target") .. " has no character")
        updateStatus(); return
    end

    local ok, err = pcall(function() return ReanimAPI.reanimate(true) end)
    if not ok then
        Notify("Reanimate failed: " .. tostring(err):sub(1, 60))
        updateStatus(); return
    end

    task.wait()

    if not plr.Character or not plr.Character.Parent then
        Notify("Character lost during setup")
        pcall(function() ReanimAPI.reanimate(false) end)
        updateStatus(); return
    end
    tChar = State.selectedPlayer and State.selectedPlayer.Character
    if not tChar or not tChar.Parent then
        Notify((State.selectedPlayer and State.selectedPlayer.DisplayName or "Target") .. " lost connection")
        pcall(function() ReanimAPI.reanimate(false) end)
        updateStatus(); return
    end

    local clone = ReanimAPI.get_clone(plr)
    if not clone then
        Notify("Could not get clone \u{2014} try again")
        pcall(function() ReanimAPI.reanimate(false) end)
        updateStatus(); return
    end
    State.myClone = clone

    local realChar = ReanimAPI.get_real_character(plr)
    if realChar then
        for _, p in ipairs(realChar:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.Transparency = 1 end) end
        end
        for _, d in ipairs(realChar:GetDescendants()) do
            if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                pcall(function() d.Enabled = false end)
            end
        end
        State.myRealChar = realChar
    end

    for _, p in ipairs(clone:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.Transparency = (p.Name == "HumanoidRootPart") and 1 or 0
            end)
        end
    end

    if realChar then
        for _, part in ipairs(realChar:GetChildren()) do
            if part:IsA("BasePart") then
                local clonePart = clone:FindFirstChild(part.Name)
                if clonePart then
                    for _, child in ipairs(part:GetChildren()) do
                        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                            pcall(function() child.Parent = clonePart end)
                        end
                    end
                end
            end
        end
    end

    local cloneAnimate = clone:FindFirstChild("Animate")
    if cloneAnimate then pcall(function() cloneAnimate.Disabled = true end) end

    local cloneCtrl = clone:FindFirstChildOfClass("Humanoid")
                   or clone:FindFirstChildOfClass("AnimationController")
    if cloneCtrl then
        local cloneAnimator = cloneCtrl:FindFirstChildOfClass("Animator")
        if cloneAnimator then
            for _, t in ipairs(cloneAnimator:GetPlayingAnimationTracks()) do
                pcall(function() t:Stop(0) end)
            end
            pcall(function() cloneAnimator:Destroy() end)
        end
    end

    local cloneHRP0 = clone:FindFirstChild("HumanoidRootPart")
    if cloneHRP0 then
        pcall(function() cloneHRP0.Anchored = not State.copyAnywhere end)
    end

    local tHRP0    = tChar:FindFirstChild("HumanoidRootPart")
    local cloneHRP = clone:FindFirstChild("HumanoidRootPart")
    if tHRP0 and cloneHRP and not State.copyAnywhere then
        local initCF = tHRP0.CFrame * CFrame.new(State.copySide * State.copyDistance, 0, 0)
        pcall(function() cloneHRP.CFrame = initCF end)
    end

    applyAnchorForMode()

    State.jointPairs = buildJointPairs(clone, tChar)
    if #State.jointPairs == 0 then
        Notify("No matching joints \u{2014} rig mismatch? (R6 vs R15)")
        stopCopying(); return
    end

    State.copyActive = true
    State.builtForChar = tChar
    updateStatus(); setActivateBtn(true)
    Notify("Copying " .. State.selectedPlayer.DisplayName)

    local function syncPose()
        LPS_ATTRIBUTES(VM(NONE))
        local tc = State.selectedPlayer and State.selectedPlayer.Character
        if not tc or not tc.Parent then return end
        if not State.myClone or not State.myClone.Parent then stopCopying(); return end

        if tc ~= State.builtForChar then
            State.builtForChar = tc
            State.jointPairs = buildJointPairs(State.myClone, tc)
        end

        local tHRP     = tc:FindFirstChild("HumanoidRootPart")
        local cloneHRP = State.myClone:FindFirstChild("HumanoidRootPart")
        if not tHRP or not cloneHRP then return end

        if not State.copyAnywhere then
            local sideCF = tHRP.CFrame * CFrame.new(State.copySide * State.copyDistance, 0, 0)
            pcall(function() cloneHRP.CFrame = sideCF end)
        end

        pcall(function() cloneHRP.AssemblyLinearVelocity = tHRP.AssemblyLinearVelocity end)
        pcall(function() cloneHRP.AssemblyAngularVelocity = tHRP.AssemblyAngularVelocity end)

        if sethiddenproperty and State.myRealChar then
            for _, rp in ipairs(State.myRealChar:GetChildren()) do
                if rp:IsA("BasePart") then
                    pcall(sethiddenproperty, rp, "PhysicsRepRootPart", tHRP)
                end
            end
        end

        for _, pair in ipairs(State.jointPairs) do
            pcall(function()
                local tm = pair.tm
                local cm = pair.cm
                if tm.Parent and cm.Parent and tm.Part0 and tm.Part1
                   and cm.Part0 and cm.Part1 then
                    local effT = tm.C0:Inverse()
                              * tm.Part0.CFrame:Inverse()
                              * tm.Part1.CFrame
                              * tm.C1
                    cm.Transform = effT
                end
            end)
        end
    end

    State.copyConn = RunService.PreSimulation:Connect(syncPose)
end

local function startCopying()
    do
        local sApi = _G.onyxAPI
        local slateOn = false
        if sApi and sApi.is_reanimated then
            local okR, res = pcall(sApi.is_reanimated)
            slateOn = okR and res == true
        end
        if slateOn then
            if Notify then Notify("Turn off Reanimate first, then start copying") end
            return
        end
    end
    if State.copyActive or ReanimAPI.is_reanimated() then
        stopCopying()
        task.wait(0.2)
    end
    if not State.selectedPlayer then return end
    doStartCopying()
end

local WIN_W, WIN_H, HEAD_H = 330, 478, 50

local function cr(r)
    return new("UICorner", { CornerRadius = UDim.new(0, r) })
end
local function rc(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = p
    return c
end

Notify = function(msg)
    pcall(queueNotification, "Animation Copier", tostring(msg), 3, "info")
end

local window = new("CanvasGroup", {
    Name = "SlateAnimCopier",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0.5, -WIN_H / 2),
    Size = UDim2.fromOffset(WIN_W, WIN_H),
    BackgroundColor3 = T.bg,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    GroupTransparency = 1,
    ClipsDescendants = true,
    Visible = false,
    ZIndex = 60,
    Parent = gui,
})
rc(window, 18)
local winScale = new("UIScale", { Scale = 1, Parent = window })
pcall(createGlow, window, Color3.fromRGB(0, 0, 0), 28, 0.4)
_G.__SlateAnimCopierWindow = window

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, HEAD_H),
    BackgroundTransparency = 1,
    ZIndex = 62,
    Parent = window,
}, { pad(0, 12, 0, 16) })
local brand = new("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.new(0, 220, 0, 32), BackgroundTransparency = 1, ZIndex = 63, Parent = header,
}, {
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
    }),
})
local logo = new("ImageLabel", {
    Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
    Image = "rbxthumb://type=Asset&id=" .. SLATE_LOGO_ASSET .. "&w=420&h=420",
    ScaleType = Enum.ScaleType.Fit, ImageColor3 = T.accent, ZIndex = 64, Parent = brand,
})
task.spawn(function()
    local r = resolveDecalImage(SLATE_LOGO_ASSET)
    if r and logo.Parent then logo.Image = r end
end)
new("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    BackgroundTransparency = 1, Text = "Animation Copier",
    Font = Enum.Font.BuilderSansBold, TextSize = 15, TextColor3 = T.text1,
    ZIndex = 64, Parent = brand,
})
local dragHandle = new("TextButton", {
    Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "",
    AutoButtonColor = false, ZIndex = 63, Parent = header,
})
local ctlBox = new("Frame", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
    Size = UDim2.fromOffset(60, 26), BackgroundTransparency = 1, ZIndex = 65, Parent = header,
})
local function ctlBtn(text, xOff)
    local b = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
        Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = text,
        Font = Enum.Font.BuilderSansMedium, TextSize = 18, TextColor3 = T.text2,
        AutoButtonColor = false, ZIndex = 66, Parent = ctlBox,
    })
    b.MouseEnter:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text1 }) end)
    b.MouseLeave:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text2 }) end)
    return b
end
local closeBtn = ctlBtn("×", 0)
local minBtn = ctlBtn("–", -26)
pcall(_G.SlateHeaderCtl, closeBtn, "x", 11)
pcall(_G.SlateHeaderCtl, minBtn, "minus", 12)

local function winHide() window.Visible = false end
local function openWindow()
    window.Visible = true
    local anim = _G.SlateWindowAnim
    if anim then anim.open(window, winScale) else window.GroupTransparency = 0 end
end
local function closeWindow()
    local anim = _G.SlateWindowAnim
    if anim then anim.close(window, winScale, winHide) else winHide() end
end
local function toggleWindow()
    LPS_ATTRIBUTES(VM(NONE))
    if window.Visible and not window:GetAttribute("SlateClosing") then
        closeWindow()
    else
        openWindow()
    end
end
_G.SlateOpenAnimCopier = toggleWindow
_G.__SlateAnimCopierToggle = toggleWindow

do
    local dragging, dragStart, dragOrigin = false, nil, nil
    local target = window.Position
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            dragOrigin = window.Position
            target = window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target = _G.SlateClampPos(window, UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function(dt)
        LPS_ATTRIBUTES(VM(NONE))
        if not window.Visible then return end
        local dx = target.X.Offset - window.Position.X.Offset
        local dy = target.Y.Offset - window.Position.Y.Offset
        if math.abs(dx) < 0.3 and math.abs(dy) < 0.3 then return end
        local f = math.clamp(dt * 22, 0.05, 0.95)
        window.Position = UDim2.new(target.X.Scale, window.Position.X.Offset + dx * f,
            target.Y.Scale, window.Position.Y.Offset + dy * f)
    end)
end

local body = new("Frame", {
    Position = UDim2.fromOffset(0, HEAD_H),
    Size = UDim2.new(1, 0, 1, -HEAD_H),
    BackgroundTransparency = 1,
    ZIndex = 61,
    Parent = window,
})

local function card(y, h)
    LPS_ATTRIBUTES(VM(NONE))
    return new("Frame", {
        Position = UDim2.fromOffset(14, y),
        Size = UDim2.new(1, -28, 0, h),
        BackgroundColor3 = T.surface2,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 62,
        Parent = body,
    }, { cr(10), stroke(T.line, 1, 0.4) })
end
local function label(parent, text, x, y, w, h, size, font, color, align)
    LPS_ATTRIBUTES(VM(NONE))
    return new("TextLabel", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundTransparency = 1, Text = text, Font = font or Enum.Font.BuilderSansBold,
        TextSize = size or 11, TextColor3 = color or T.text1,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 63, Parent = parent,
    })
end

local statusCard = card(4, 32)
statusLabel = new("TextLabel", {
    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1, Font = Enum.Font.BuilderSansMedium, TextSize = 11,
    TextColor3 = T.text3, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "", ZIndex = 63, Parent = statusCard,
})
updateStatus = function()
    if not statusLabel or not statusLabel.Parent then return end
    if State.copyActive and State.selectedPlayer then
        statusLabel.Text = "Copying  " .. State.selectedPlayer.DisplayName
        statusLabel.TextColor3 = T.text1
    elseif State.selectedPlayer then
        statusLabel.Text = State.selectedPlayer.DisplayName .. "  selected"
        statusLabel.TextColor3 = T.text2
    else
        statusLabel.Text = "No player selected"
        statusLabel.TextColor3 = T.text3
    end
end
updateStatus()

label(body, "PLAYERS", 16, 46, 100, 14, 10, Enum.Font.BuilderSansBold, T.text3)
local refreshBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 42),
    Size = UDim2.fromOffset(62, 20), BackgroundColor3 = T.surface3, BorderSizePixel = 0,
    Text = "Refresh", Font = Enum.Font.BuilderSansBold, TextSize = 10, TextColor3 = T.text1,
    AutoButtonColor = false, ZIndex = 63, Parent = body,
}, { cr(6), stroke(T.lineHi, 1, 0.5) })

local searchCard = card(66, 30)
local sIcon = icon(searchCard, "search", 13, T.text3)
sIcon.AnchorPoint = Vector2.new(0, 0.5)
sIcon.Position = UDim2.new(0, 11, 0.5, 0)
sIcon.ZIndex = 64
local searchBox = new("TextBox", {
    Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -42, 1, 0),
    BackgroundTransparency = 1, Text = "", PlaceholderText = "Search players",
    PlaceholderColor3 = T.text3, TextColor3 = T.text1,
    Font = Enum.Font.BuilderSansMedium, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    ZIndex = 63, Parent = searchCard,
})

local listCard = card(100, 104)
listCard.BackgroundTransparency = 0.35
local listFrame = new("ScrollingFrame", {
    Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 0, ScrollBarImageTransparency = 1,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ClipsDescendants = true, ZIndex = 63, Parent = listCard,
}, { pad(2, 3, 2, 3) })
local listLayout = new("UIListLayout", {
    Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name, Parent = listFrame,
})

local playerRows = {}

local function highlightRows()
    for uid, row in pairs(playerRows) do
        local sel = State.selectedPlayer and uid == State.selectedPlayer.UserId
        tween(row, SPRING_FAST, {
            BackgroundColor3 = sel and T.surface3 or T.surface2,
            BackgroundTransparency = sel and 0.1 or 0.42,
        })
        local nm = row:FindFirstChild("NL")
        if nm then nm.TextColor3 = sel and T.text1 or T.text2 end
        local dot = row:FindFirstChild("SelDot")
        if dot then dot.Visible = sel and true or false end
        local rs = row:FindFirstChildOfClass("UIStroke")
        if rs then rs.Color = sel and T.lineHi or T.line end
    end
end

local function selectPlayer(p)
    if p == plr then return end
    if State.copyActive then stopCopying() end
    State.selectedPlayer = p
    highlightRows()
    updateStatus()
end

local function makeRow(player)
    LPS_ATTRIBUTES(VM(NONE))
    if player == plr or playerRows[player.UserId] then return end
    local row = new("TextButton", {
        Name = player.Name, Text = "", BackgroundColor3 = T.surface2,
        BackgroundTransparency = 0.42, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38), AutoButtonColor = false, ZIndex = 64, Parent = listFrame,
    }, { cr(9), stroke(T.line, 1, 0.45) })
    local thumb = new("ImageLabel", {
        BackgroundColor3 = T.surface3, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0),
        Size = UDim2.fromOffset(26, 26), ZIndex = 65, Parent = row,
    }, { cr(13) })
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if ok and thumb.Parent then thumb.Image = img end
    end)
    new("TextLabel", {
        Name = "NL", BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 4),
        Size = UDim2.new(1, -66, 0, 16), Font = Enum.Font.BuilderSansBold, Text = player.DisplayName,
        TextColor3 = T.text2, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 65, Parent = row,
    })
    new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 21),
        Size = UDim2.new(1, -66, 0, 12), Font = Enum.Font.BuilderSansMedium, Text = "@" .. player.Name,
        TextColor3 = T.text3, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 65, Parent = row,
    })
    new("Frame", {
        Name = "SelDot", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(7, 7), BackgroundColor3 = T.text1, BorderSizePixel = 0,
        Visible = false, ZIndex = 65, Parent = row,
    }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    row.MouseButton1Click:Connect(function() selectPlayer(player) end)
    row.MouseEnter:Connect(function()
        if State.selectedPlayer ~= player then tween(row, SPRING_FAST, { BackgroundTransparency = 0.25 }) end
    end)
    row.MouseLeave:Connect(function()
        if State.selectedPlayer ~= player then tween(row, SPRING_FAST, { BackgroundTransparency = 0.42 }) end
    end)
    playerRows[player.UserId] = row

    local q = searchBox.Text:lower()
    if q ~= "" then
        row.Visible = (player.Name:lower():find(q, 1, true) or player.DisplayName:lower():find(q, 1, true)) ~= nil
    end
end

local function removeRow(player)
    local row = playerRows[player.UserId]
    if row then row:Destroy(); playerRows[player.UserId] = nil end
    if State.selectedPlayer == player then
        State.selectedPlayer = nil
        if State.copyActive then stopCopying() end
        updateStatus()
    end
end

local function rebuildList()
    for uid, row in pairs(playerRows) do row:Destroy(); playerRows[uid] = nil end
    for _, p in ipairs(Players:GetPlayers()) do task.spawn(makeRow, p) end
end

local function filterRows(q)
    q = q:lower()
    for uid, row in pairs(playerRows) do
        local p = Players:GetPlayerByUserId(uid)
        if p then
            row.Visible = q == "" or (p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) ~= nil
        end
    end
end

rebuildList()
Players.PlayerAdded:Connect(makeRow)
Players.PlayerRemoving:Connect(removeRow)
refreshBtn.MouseButton1Click:Connect(rebuildList)
searchBox:GetPropertyChangedSignal("Text"):Connect(function() filterRows(searchBox.Text) end)

label(body, "CONTROLS", 16, 210, 100, 14, 10, Enum.Font.BuilderSansBold, T.text3)

activateBtn = new("TextButton", {
    Position = UDim2.fromOffset(14, 228), Size = UDim2.new(1, -28, 0, 32),
    BackgroundColor3 = T.text1, BorderSizePixel = 0, Text = "Activate Copy",
    Font = Enum.Font.BuilderSansBold, TextSize = 12.5, TextColor3 = T.bg,
    AutoButtonColor = false, ZIndex = 63, Parent = body,
}, { cr(9) })
activateBtn.MouseEnter:Connect(function()
    if not State.copyActive then tween(activateBtn, SPRING_FAST, { BackgroundColor3 = T.text2 }) end
end)
activateBtn.MouseLeave:Connect(function()
    if not State.copyActive then tween(activateBtn, SPRING_FAST, { BackgroundColor3 = T.text1 }) end
end)

setActivateBtn = function(on)
    if not activateBtn or not activateBtn.Parent then return end
    if on then
        activateBtn.Text = "Stop Copying"
        tween(activateBtn, SPRING_FAST, { BackgroundColor3 = T.surface3, TextColor3 = T.text1 })
    else
        activateBtn.Text = "Activate Copy"
        tween(activateBtn, SPRING_FAST, { BackgroundColor3 = T.text1, TextColor3 = T.bg })
    end
end

activateBtn.MouseButton1Click:Connect(function()
    if not State.selectedPlayer then
        Notify("Select a player first")
        return
    end
    if State.copyActive then stopCopying() else startCopying() end
end)

distRow = card(268, 54)
label(distRow, "Distance", 12, 7, 120, 14, 11, Enum.Font.BuilderSansBold, T.text1)
distValLbl = label(distRow, "", 0, 7, 60, 14, 11, Enum.Font.BuilderSansBold, T.text2, Enum.TextXAlignment.Right)
distValLbl.AnchorPoint = Vector2.new(1, 0)
distValLbl.Position = UDim2.new(1, -12, 0, 7)
local sliderTrack = new("Frame", {
    Position = UDim2.fromOffset(13, 30), Size = UDim2.new(1, -26, 0, 12),
    BackgroundColor3 = Color3.fromRGB(22, 22, 28), BorderSizePixel = 0, ZIndex = 63, Parent = distRow,
}, { new("UICorner", { CornerRadius = UDim.new(0, 6) }), stroke(Color3.fromRGB(255, 255, 255), 1, 0.85) })
local sliderFill = new("Frame", {
    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0, ZIndex = 64, Parent = sliderTrack,
}, {
    new("UICorner", { CornerRadius = UDim.new(0, 6) }),
    new("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 195, 210)),
        },
        Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(1, 0),
        },
        Rotation = 2,
    }),
})
local KNOB_W = 35
local sliderThumb = new("Frame", {
    Size = UDim2.fromOffset(KNOB_W, 18), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0, ZIndex = 66, Parent = sliderTrack,
}, { new("UICorner", { CornerRadius = UDim.new(0, 9) }), stroke(Color3.fromRGB(255, 255, 255), 1, 0.7) })
pcall(createGlow, sliderThumb, Color3.fromRGB(255, 255, 255), 10, 0.55)

local DIST_MIN, DIST_MAX = 1.0, 20.0
local function setDistFromAlpha(alpha, animate)
    alpha = math.clamp(alpha, 0, 1)
    State.copyDistance = DIST_MIN + alpha * (DIST_MAX - DIST_MIN)
    State.copyDistance = math.floor(State.copyDistance * 2 + 0.5) / 2
    State.copyDistance = math.clamp(State.copyDistance, DIST_MIN, DIST_MAX)
    local a = (State.copyDistance - DIST_MIN) / (DIST_MAX - DIST_MIN)
    local handleOffset = (1 - 2 * a) * (KNOB_W / 2 - 2)
    local targetPos = UDim2.new(a, handleOffset, 0.5, 0)
    local targetSize = UDim2.new(a, 0, 1, 0)
    if animate then
        local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(sliderFill, info, { Size = targetSize }):Play()
        TweenService:Create(sliderThumb, info, { Position = targetPos }):Play()
    else
        sliderFill.Size = targetSize
        sliderThumb.Position = targetPos
    end
    distValLbl.Text = string.format("%.1f st", State.copyDistance)
end
setDistFromAlpha((State.copyDistance - DIST_MIN) / (DIST_MAX - DIST_MIN), false)

local sliderDragging = false
local function sliderBegin(inp)
    LPS_ATTRIBUTES(VM(NONE))
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        setDistFromAlpha((inp.Position.X - sliderTrack.AbsolutePosition.X) / math.max(1, sliderTrack.AbsoluteSize.X), true)
    end
end
sliderTrack.InputBegan:Connect(sliderBegin)
sliderThumb.InputBegan:Connect(sliderBegin)
UserInputService.InputChanged:Connect(function(inp)
    if sliderDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        setDistFromAlpha((inp.Position.X - sliderTrack.AbsolutePosition.X) / math.max(1, sliderTrack.AbsoluteSize.X), true)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

sideRow = card(330, 38)
local sideLbl = label(sideRow, "Side", 12, 0, 60, 38, 11, Enum.Font.BuilderSansBold, T.text1)
local function sideBtn(txt, xOff)
    return new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
        Size = UDim2.fromOffset(64, 24), BackgroundColor3 = T.surface3, BorderSizePixel = 0,
        Text = txt, Font = Enum.Font.BuilderSansBold, TextSize = 10.5, TextColor3 = T.text2,
        AutoButtonColor = false, ZIndex = 63, Parent = sideRow,
    }, { cr(7) })
end
local rightBtn = sideBtn("Right", -10)
local leftBtn = sideBtn("Left", -80)
local function updateSide()
    local function style(btn, on)
        tween(btn, SPRING_FAST, {
            BackgroundColor3 = on and T.text1 or T.surface3,
            TextColor3 = on and T.bg or T.text2,
        })
    end
    style(leftBtn, State.copySide == -1)
    style(rightBtn, State.copySide == 1)
end
updateSide()
leftBtn.MouseButton1Click:Connect(function() State.copySide = -1; updateSide() end)
rightBtn.MouseButton1Click:Connect(function() State.copySide = 1; updateSide() end)

copyAnywhereFrame = card(376, 38)
label(copyAnywhereFrame, "Copy Anywhere", 12, 0, 180, 38, 11, Enum.Font.BuilderSansBold, T.text1)
local caSwitchHost = new("Frame", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(50, 21), BackgroundTransparency = 1, ZIndex = 63, Parent = copyAnywhereFrame,
})
setCopyAnywhereVisuals = function()
    local on = State.copyAnywhere
    distRow.BackgroundTransparency = on and 0.7 or 0.4
    sideRow.BackgroundTransparency = on and 0.7 or 0.4
end
makeSwitch(caSwitchHost, State.copyAnywhere, function(v)
    State.copyAnywhere = v
    setCopyAnywhereVisuals()
    applyAnchorForMode()
    if State.copyActive then
        Notify(v and "Copy Anywhere on - move freely" or "Copy Anywhere off")
    end
end)
setCopyAnywhereVisuals()

closeBtn.MouseButton1Click:Connect(function()
    if State.copyActive then stopCopying() end
    closeWindow()
end)
local isMin = false
local bodyToken = 0
minBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    bodyToken = bodyToken + 1
    local token = bodyToken
    tween(window, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(WIN_W, isMin and HEAD_H or WIN_H),
    })
    if isMin then
        task.delay(0.15, function()
            if token == bodyToken and isMin then body.Visible = false end
        end)
    else
        body.Visible = true
    end
    pcall(_G.SlateHeaderCtl, minBtn, isMin and "plus" or "minus", 12)
end)

openWindow()
Notify("Animation Copier ready")

end
_G.SlateRunAnimCopier = runAnimCopier

_G.SlateRunBaseplate2 = function()
    if _G.__SlateBaseplate2Window and _G.__SlateBaseplate2Window.Parent and _G.__SlateBaseplate2Toggle then
        return _G.__SlateBaseplate2Toggle()
    end

    local Players_ = game:GetService("Players")
    local Workspace_ = game:GetService("Workspace")
    local UIS = game:GetService("UserInputService")
    local RS = game:GetService("RunService")
    local TS = game:GetService("TweenService")
    local GuiService_ = game:GetService("GuiService")

    local TILE_SIZE = Vector3.new(648, 16, 648)
    local RADIUS = 1
    local UPDATE_RATE = 0.15
    local BASEPLATE_COLOR = Color3.fromRGB(128, 128, 128)
    local BASEPLATE_MATERIAL = Enum.Material.Plastic

    local isBaseplateEnabled = false
    local clearMode = false
    local selectedIsClear = true
    local selectedIsInvis = false
    local rainbowMode = false
    local rainbowConnection = nil
    local updatingUI = false
    local hasPickedColor = true

    _G.StandaloneBaseplateGeneration = (_G.StandaloneBaseplateGeneration or 0) + 1
    local scriptGeneration = _G.StandaloneBaseplateGeneration
    _G.StandaloneBaseplateLoop = false

    if _G.StandaloneBaseplateFolder then
        pcall(function() _G.StandaloneBaseplateFolder:Destroy() end)
        _G.StandaloneBaseplateFolder = nil
    end

    local folder = Instance.new("Folder")
    folder.Name = "Baseplate"
    folder.Parent = Workspace_
    _G.StandaloneBaseplateFolder = folder

    local originalBaseplates = {}
    local originalBackups = _G.StandaloneOriginalBaseplateBackups or {}
    _G.StandaloneOriginalBaseplateBackups = originalBackups

    local function baseplateKey(obj)
        local p, s = obj.Position, obj.Size
        return string.format("%.3f:%.3f:%.3f|%.3f:%.3f:%.3f", p.X, p.Y, p.Z, s.X, s.Y, s.Z)
    end
    local function isGeneratedBaseplate(obj)
        return folder and (obj == folder or obj:IsDescendantOf(folder))
    end
    local function addOriginalBaseplate(obj)
        LPS_ATTRIBUTES(VM(NONE))
        if not obj or not obj:IsA("BasePart") or obj.Name ~= "Baseplate" or isGeneratedBaseplate(obj) then return end
        local key = baseplateKey(obj)
        local backup = originalBackups[key]
        if not backup then
            local clone = obj:Clone()
            clone.Transparency = 0
            clone.CanCollide = true
            originalBackups[key] = { object = obj, clone = clone, parent = obj.Parent }
        else
            backup.object = obj
            if obj.Parent then backup.parent = obj.Parent end
            if not backup.clone then backup.clone = obj:Clone() end
            backup.clone.Transparency = 0
            backup.clone.CanCollide = true
        end
        for _, current in ipairs(originalBaseplates) do
            if current == obj then return end
        end
        table.insert(originalBaseplates, obj)
    end
    local function scanOriginalBaseplates()
        LPS_ATTRIBUTES(VM(NONE))
        local refreshed = {}
        for _, obj in ipairs(Workspace_:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Baseplate" and not isGeneratedBaseplate(obj) then
                addOriginalBaseplate(obj)
                table.insert(refreshed, obj)
            end
        end
        originalBaseplates = refreshed
    end
    local function calculateBaseplateHeight()
        local highestTop = nil
        scanOriginalBaseplates()
        for _, bp in ipairs(originalBaseplates) do
            if bp and bp.Parent then
                local topY = bp.Position.Y + (bp.Size.Y / 2)
                if highestTop == nil or topY > highestTop then highestTop = topY end
            end
        end
        if highestTop == nil then
            for _, backup in pairs(originalBackups) do
                local clone = backup.clone
                if clone then
                    local topY = clone.Position.Y + (clone.Size.Y / 2)
                    if highestTop == nil or topY > highestTop then highestTop = topY end
                end
            end
        end
        if highestTop == nil then return -TILE_SIZE.Y / 2 end
        return highestTop - (TILE_SIZE.Y / 2)
    end
    local Y = calculateBaseplateHeight()

    local extraRoomBackups = {}
    local function getExtraRoom()
        local map = Workspace_:FindFirstChild("map")
        return map and map:FindFirstChild("extra_room")
    end
    local function getExtraRoomTargets()
        local extraRoom = getExtraRoom()
        if not extraRoom then return {} end
        local children = extraRoom:GetChildren()
        local list = { children[2], children[3], children[4], extraRoom:FindFirstChild("platform") }
        local result, seen = {}, {}
        for _, object in ipairs(list) do
            if object and not seen[object] then
                seen[object] = true
                table.insert(result, object)
            end
        end
        return result
    end
    local function extraRoomSignature(object)
        if not object then return nil end
        local signature = object.ClassName .. "|" .. object.Name
        if object:IsA("BasePart") then
            local p, s = object.Position, object.Size
            signature = signature .. string.format("|%.3f:%.3f:%.3f|%.3f:%.3f:%.3f", p.X, p.Y, p.Z, s.X, s.Y, s.Z)
        end
        return signature
    end
    local function captureExtraRoomObjects()
        for _, object in ipairs(getExtraRoomTargets()) do
            local signature = extraRoomSignature(object)
            local backup = signature and extraRoomBackups[signature]
            if not backup and signature then
                extraRoomBackups[signature] = { object = object, clone = object:Clone(), signature = signature }
            elseif backup then
                backup.object = object
            end
        end
    end
    captureExtraRoomObjects()
    local function removeExtraRoomObjects()
        captureExtraRoomObjects()
        for _, object in ipairs(getExtraRoomTargets()) do
            local signature = extraRoomSignature(object)
            local backup = signature and extraRoomBackups[signature]
            if backup then backup.object = object end
            pcall(function() object:Destroy() end)
        end
        task.defer(function()
            local extraRoom = getExtraRoom()
            if not extraRoom or not isBaseplateEnabled then return end
            for _, object in ipairs(getExtraRoomTargets()) do
                pcall(function() object:Destroy() end)
            end
        end)
    end
    local function restoreExtraRoomObjects()
        local extraRoom = getExtraRoom()
        if not extraRoom then return end
        local existing = {}
        for _, object in ipairs(extraRoom:GetChildren()) do
            existing[extraRoomSignature(object)] = object
        end
        for signature, backup in pairs(extraRoomBackups) do
            local ex = existing[signature]
            if ex and ex.Parent then
                backup.object = ex
            elseif backup.clone then
                pcall(function()
                    local restored = backup.clone:Clone()
                    restored.Parent = extraRoom
                    backup.object = restored
                end)
            end
        end
    end

    local function hideOriginalBaseplates()
        scanOriginalBaseplates()
        for _, bp in ipairs(originalBaseplates) do
            if bp and bp.Parent then
                pcall(function()
                    bp.Transparency = 1
                    bp.CanCollide = false
                    bp.CanTouch = false
                end)
            end
        end
    end
    local function restoreOriginalBaseplates()
        scanOriginalBaseplates()
        for _, backup in pairs(originalBackups) do
            local object = backup.object
            if object and object.Parent then
                pcall(function()
                    object.Transparency = 0
                    object.CanCollide = true
                    object.CanTouch = true
                end)
            elseif backup.clone then
                pcall(function()
                    local restored = backup.clone:Clone()
                    restored.Transparency = 0
                    restored.CanCollide = true
                    restored.CanTouch = true
                    backup.object = restored
                    local parent = backup.parent
                    restored.Parent = (parent and parent.Parent) and parent or Workspace_
                    addOriginalBaseplate(restored)
                end)
            end
        end
        scanOriginalBaseplates()
        for _, bp in ipairs(originalBaseplates) do
            if bp and bp.Parent then
                pcall(function()
                    bp.Transparency = 0
                    bp.CanCollide = true
                    bp.CanTouch = true
                end)
            end
        end
        restoreExtraRoomObjects()
    end

    Workspace_.DescendantAdded:Connect(function(obj)
        LPS_ATTRIBUTES(VM(NONE))
        if scriptGeneration ~= _G.StandaloneBaseplateGeneration then return end
        if obj:IsA("BasePart") and obj.Name == "Baseplate" then
            task.defer(function()
                if scriptGeneration ~= _G.StandaloneBaseplateGeneration or not obj.Parent or isGeneratedBaseplate(obj) then return end
                addOriginalBaseplate(obj)
                if isBaseplateEnabled and not selectedIsInvis then
                    pcall(function()
                        obj.Transparency = 1
                        obj.CanCollide = false
                        obj.CanTouch = false
                    end)
                else
                    pcall(function()
                        obj.Transparency = 0
                        obj.CanCollide = true
                        obj.CanTouch = true
                    end)
                end
            end)
        end
    end)
    restoreOriginalBaseplates()

    local tiles = {}
    local sourceBaseplate = originalBaseplates[1]
    local initialColor = sourceBaseplate and sourceBaseplate.Color or BASEPLATE_COLOR
    local initialMaterial = sourceBaseplate and sourceBaseplate.Material or BASEPLATE_MATERIAL
    local initialTransparency = sourceBaseplate and sourceBaseplate.Transparency or 0
    local currentColor = initialColor
    local currentMaterial = initialMaterial
    local selectedMaterialValue = initialMaterial
    _G.StandaloneBaseplateColor = currentColor
    _G.StandaloneBaseplateTransparency = initialTransparency
    _G.StandaloneBaseplateMaterial = currentMaterial

    local template = Instance.new("Part")
    template.Name = "Baseplate"
    template.Material = currentMaterial
    template.TopSurface = Enum.SurfaceType.Smooth
    template.BottomSurface = Enum.SurfaceType.Smooth
    template.Size = TILE_SIZE
    template.Color = currentColor
    template.Anchored = true
    template.CanCollide = true
    template.CanTouch = true
    template.CanQuery = true
    local curAlpha = initialTransparency

    local function getBaseplateTransparency()
        if not isBaseplateEnabled then return 1 end
        if clearMode then return 1 end
        return _G.StandaloneBaseplateTransparency or curAlpha or 0
    end
    local function getTile(x, z)
        local name = x .. ":" .. z
        if tiles[name] then return tiles[name] end
        local tile = template:Clone()
        tile.Name = "Baseplate_" .. x .. "_" .. z
        tile.Position = Vector3.new(x * TILE_SIZE.X, Y, z * TILE_SIZE.Z)
        tile.Color = _G.StandaloneBaseplateColor or currentColor
        tile.Material = currentMaterial
        tile.Transparency = getBaseplateTransparency()
        tile.Parent = folder
        tiles[name] = tile
        return tile
    end
    local function getGrid(pos)
        return math.floor(pos.X / TILE_SIZE.X + 0.5), math.floor(pos.Z / TILE_SIZE.Z + 0.5)
    end
    local function updateTiles()
        local needed = {}
        for _, plr in ipairs(Players_:GetPlayers()) do
            local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local gx, gz = getGrid(root.Position)
                for x = gx - RADIUS, gx + RADIUS do
                    for z = gz - RADIUS, gz + RADIUS do
                        needed[x .. ":" .. z] = true
                        getTile(x, z)
                    end
                end
            end
        end
        for name, tile in pairs(tiles) do
            if not needed[name] then
                tile:Destroy()
                tiles[name] = nil
            end
        end
    end
    local function clearAllTiles()
        for _, tile in pairs(tiles) do
            if tile and tile.Parent then pcall(function() tile:Destroy() end) end
        end
        table.clear(tiles)
        if folder and folder.Parent then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("BasePart") then pcall(function() child:Destroy() end) end
            end
        end
    end
    local baseplateLoopGeneration = 0
    local function stopBaseplateLoop()
        baseplateLoopGeneration += 1
        _G.StandaloneBaseplateLoop = false
    end
    local function startBaseplateLoop()
        baseplateLoopGeneration += 1
        local generation = baseplateLoopGeneration
        Y = calculateBaseplateHeight()
        if selectedIsInvis then restoreOriginalBaseplates() else hideOriginalBaseplates() end
        _G.StandaloneBaseplateLoop = true
        task.spawn(function()
            while scriptGeneration == _G.StandaloneBaseplateGeneration and generation == baseplateLoopGeneration
                and isBaseplateEnabled and folder.Parent do
                if selectedIsInvis then restoreOriginalBaseplates() else hideOriginalBaseplates() end
                updateTiles()
                task.wait(UPDATE_RATE)
            end
        end)
    end
    folder.ChildAdded:Connect(function(obj)
        if obj:IsA("BasePart") then
            task.wait()
            obj.Color = _G.StandaloneBaseplateColor or currentColor
            obj.Material = currentMaterial
            obj.Transparency = getBaseplateTransparency()
        end
    end)
    local function applyMaterial(materialName)
        currentMaterial = materialName
        _G.StandaloneBaseplateMaterial = materialName
        _G.StandaloneBaseplateTransparency = math.clamp(curAlpha or 0, 0, 1)
        if folder and folder.Parent then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("BasePart") then
                    obj.Material = materialName
                    obj.Transparency = getBaseplateTransparency()
                end
            end
        end
    end
    local function changeColor(color, transp)
        _G.StandaloneBaseplateColor = color
        _G.StandaloneBaseplateTransparency = transp or _G.StandaloneBaseplateTransparency or 0
        if folder and folder.Parent then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("BasePart") then
                    obj.Color = color
                    obj.Transparency = getBaseplateTransparency()
                end
            end
        end
    end

    local function setBaseplateEnabled(on)
        isBaseplateEnabled = on
        if on then
            stopBaseplateLoop()
            clearAllTiles()
            clearMode = selectedIsClear or selectedIsInvis
            currentMaterial = selectedMaterialValue
            _G.StandaloneBaseplateMaterial = selectedMaterialValue
            template.Material = selectedMaterialValue
            if selectedIsClear or selectedIsInvis then
                _G.StandaloneBaseplateTransparency = 1
            else
                _G.StandaloneBaseplateTransparency = math.clamp(curAlpha or 0, 0, 1)
            end
            if selectedIsInvis then
                restoreOriginalBaseplates()
            else
                removeExtraRoomObjects()
                hideOriginalBaseplates()
            end
            startBaseplateLoop()
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("BasePart") then
                    obj.Color = _G.StandaloneBaseplateColor or currentColor
                    obj.Material = selectedMaterialValue
                    obj.CanCollide = true
                    obj.CanTouch = true
                    obj.Transparency = (selectedIsClear or selectedIsInvis) and 1 or (_G.StandaloneBaseplateTransparency or 0)
                end
            end
        else
            stopBaseplateLoop()
            clearAllTiles()
            restoreOriginalBaseplates()
        end
    end

    local WIN_W, HEAD_H = 340, 50
    local isMicUp = true
    local WIN_H = HEAD_H + 14 + 52 + 8 + 190 + 8 + 190 + (isMicUp and (8 + 52) or 0) + 14

    local function cr(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

    local window = new("CanvasGroup", {
        Name = "SlateBaseplate2",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, -WIN_H / 2),
        Size = UDim2.fromOffset(WIN_W, WIN_H),
        BackgroundColor3 = T.bg,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 60,
        Parent = gui,
    }, { cr(18) })
    local winScale = new("UIScale", { Scale = 1, Parent = window })
    pcall(createGlow, window, Color3.fromRGB(0, 0, 0), 28, 0.4)
    _G.__SlateBaseplate2Window = window

    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, ZIndex = 62, Parent = window,
    }, { pad(0, 12, 0, 16) })
    local brand = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 220, 0, 32), BackgroundTransparency = 1, ZIndex = 63, Parent = header,
    }, {
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
        }),
    })
    local logo = new("ImageLabel", {
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=" .. SLATE_LOGO_ASSET .. "&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit, ImageColor3 = T.accent, ZIndex = 64, Parent = brand,
    })
    task.spawn(function()
        local r = resolveDecalImage(SLATE_LOGO_ASSET)
        if r and logo.Parent then logo.Image = r end
    end)
    new("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1,
        Text = "Baseplate", Font = Enum.Font.BuilderSansBold, TextSize = 15, TextColor3 = T.text1,
        ZIndex = 64, Parent = brand,
    })
    local dragHandle = new("TextButton", {
        Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 63, Parent = header,
    })
    local ctlBox = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(60, 26), BackgroundTransparency = 1, ZIndex = 65, Parent = header,
    })
    local function ctlBtn(text, xOff)
        local b = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
            Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = text,
            Font = Enum.Font.BuilderSansMedium, TextSize = 18, TextColor3 = T.text2,
            AutoButtonColor = false, ZIndex = 66, Parent = ctlBox,
        })
        b.MouseEnter:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text1 }) end)
        b.MouseLeave:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text2 }) end)
        return b
    end
    local closeBtn = ctlBtn("×", 0)
    local minBtn = ctlBtn("–", -26)
    pcall(_G.SlateHeaderCtl, closeBtn, "x", 11)
    pcall(_G.SlateHeaderCtl, minBtn, "minus", 12)

    local function winHide() window.Visible = false end
    local function openWindow()
        window.Visible = true
        local anim = _G.SlateWindowAnim
        if anim then anim.open(window, winScale) else window.GroupTransparency = 0 end
    end
    local function closeWindow()
        local anim = _G.SlateWindowAnim
        if anim then anim.close(window, winScale, winHide) else winHide() end
    end
    local function toggleWindow()
        LPS_ATTRIBUTES(VM(NONE))
        if window.Visible and not window:GetAttribute("SlateClosing") then closeWindow() else openWindow() end
    end
    _G.__SlateBaseplate2Toggle = toggleWindow
    closeBtn.MouseButton1Click:Connect(closeWindow)

    do
        local dragging, dragStart, dragOrigin = false, nil, nil
        local target = window.Position
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                dragOrigin = window.Position
                target = window.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                target = _G.SlateClampPos(window, UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y))
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        RS.RenderStepped:Connect(function(dt)
            LPS_ATTRIBUTES(VM(NONE))
            if not window.Visible then return end
            local dx = target.X.Offset - window.Position.X.Offset
            local dy = target.Y.Offset - window.Position.Y.Offset
            if math.abs(dx) < 0.3 and math.abs(dy) < 0.3 then return end
            local f = math.clamp(dt * 22, 0.05, 0.95)
            window.Position = UDim2.new(target.X.Scale, window.Position.X.Offset + dx * f,
                target.Y.Scale, window.Position.Y.Offset + dy * f)
        end)
    end

    local body = new("Frame", {
        Position = UDim2.fromOffset(0, HEAD_H), Size = UDim2.new(1, 0, 1, -HEAD_H),
        BackgroundTransparency = 1, ZIndex = 61, Parent = window,
    })
    local function card(y, h)
        LPS_ATTRIBUTES(VM(NONE))
        return new("Frame", {
            Position = UDim2.fromOffset(14, y), Size = UDim2.new(1, -28, 0, h),
            BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4, BorderSizePixel = 0,
            ZIndex = 62, Parent = body,
        }, { cr(10), stroke(T.line, 1, 0.4) })
    end
    local function lbl(parent, text, x, y, w, h, size, font, color, align)
        return new("TextLabel", {
            Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
            Text = text, Font = font or Enum.Font.BuilderSansBold, TextSize = size or 11,
            TextColor3 = color or T.text1, TextXAlignment = align or Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 63, Parent = parent,
        })
    end

    local y0 = 8
    local activeCard = card(y0, 52)
    lbl(activeCard, "Infinite baseplate", 12, 9, 200, 16, 12, Enum.Font.BuilderSansBold, T.text1)
    lbl(activeCard, "Generates ground under every player", 12, 27, 220, 14, 10, Enum.Font.BuilderSansMedium, T.text3)
    local switchHost = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(50, 21), BackgroundTransparency = 1, ZIndex = 63, Parent = activeCard,
    })
    makeSwitch(switchHost, false, function(v) setBaseplateEnabled(v) end)

    local colorY = y0 + 52 + 8
    local colorCard = card(colorY, 190)
    local h, s, v = Color3.toHSV(initialColor)
    local updateVisualsFromHSV

    local csHolder = new("Frame", {
        Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -56, 0, 118),
        BackgroundTransparency = 1, ZIndex = 63, Parent = colorCard,
    })
    local colorSpace = new("CanvasGroup", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0, ZIndex = 63, Parent = csHolder,
    }, { cr(9) })
    new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, ZIndex = 64, Parent = colorSpace,
    }, {
        new("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
        }),
    })
    new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0, ZIndex = 65, Parent = colorSpace,
    }, {
        new("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
            Rotation = 90,
        }),
    })
    stroke(T.line, 1, 0.4).Parent = colorSpace
    local cursor = new("Frame", {
        Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1 - v, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 67, Parent = csHolder,
    }, {
        new("UICorner", { CornerRadius = UDim.new(1, 0) }),
        stroke(Color3.fromRGB(255, 255, 255), 2, 0),
    })
    new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = 66, Parent = cursor,
    }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(Color3.fromRGB(0, 0, 0), 1, 0.6) })

    local hueBar = new("Frame", {
        Position = UDim2.new(1, -40, 0, 10), Size = UDim2.fromOffset(30, 118),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ClipsDescendants = true,
        ZIndex = 63, Parent = colorCard,
    }, {
        cr(9),
        stroke(T.line, 1, 0.4),
        new("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
            }),
        }),
    })
    local hueKnob = new("Frame", {
        Size = UDim2.new(1, -4, 0, 6), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, h, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, ZIndex = 65, Parent = hueBar,
    }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(Color3.fromRGB(0, 0, 0), 1, 0.55) })

    local function colorInput(name, x, w, placeholder)
        return new("TextBox", {
            Name = name, Position = UDim2.fromOffset(x, 140), Size = UDim2.fromOffset(w, 28),
            BackgroundColor3 = T.surface3, BackgroundTransparency = 0.2, BorderSizePixel = 0,
            ClearTextOnFocus = false, PlaceholderText = placeholder, PlaceholderColor3 = T.text3,
            Text = "", TextColor3 = T.text1, TextSize = 11, Font = Enum.Font.BuilderSansMedium,
            ClipsDescendants = true, ZIndex = 63, Parent = colorCard,
        }, { cr(7), stroke(T.line, 1, 0.5) })
    end
    local rInput = colorInput("R", 10, 44, "R")
    local gInput = colorInput("G", 59, 44, "G")
    local bInput = colorInput("B", 108, 44, "B")
    local hexInput = colorInput("HEX", 157, 68, "HEX")
    local rainbowBtn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 140), Size = UDim2.fromOffset(70, 28),
        BackgroundColor3 = T.surface3, BorderSizePixel = 0, Text = "Rainbow",
        Font = Enum.Font.BuilderSansBold, TextSize = 10.5, TextColor3 = T.text1,
        AutoButtonColor = false, ZIndex = 63, Parent = colorCard,
    }, { cr(7), stroke(T.lineHi, 1, 0.5) })

    local function setInputText(input, text)
        if not input:IsFocused() and input.Text ~= text then input.Text = text end
    end
    local function syncColorInputs(color)
        local r, g, b = math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
        setInputText(rInput, tostring(r))
        setInputText(gInput, tostring(g))
        setInputText(bInput, tostring(b))
        setInputText(hexInput, string.format("%02X%02X%02X", r, g, b))
    end
    updateVisualsFromHSV = function(liveApply)
        if updatingUI then return end
        updatingUI = true
        colorSpace.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        cursor.Visible = hasPickedColor
        hueKnob.Position = UDim2.new(0.5, 0, h, 0)
        local c = Color3.fromHSV(h, s, v)
        syncColorInputs(c)
        updatingUI = false
        if liveApply and isBaseplateEnabled then changeColor(c, curAlpha) end
    end
    local function applyInputColor(color)
        if updatingUI then return end
        h, s, v = Color3.toHSV(color)
        hasPickedColor = true
        updateVisualsFromHSV(true)
    end
    local function fromRGBInputs()
        local r, g, b = tonumber(rInput.Text), tonumber(gInput.Text), tonumber(bInput.Text)
        if r and g and b then
            applyInputColor(Color3.fromRGB(math.clamp(math.floor(r + 0.5), 0, 255),
                math.clamp(math.floor(g + 0.5), 0, 255), math.clamp(math.floor(b + 0.5), 0, 255)))
        end
    end
    local function fromHexInput()
        local text = hexInput.Text:gsub("#", ""):gsub("%s", ""):upper()
        if #text > 6 then
            text = text:sub(1, 6)
            hexInput.Text = text
        end
        if (#text == 3 or #text == 6) and text:match("^[%x]+$") then
            if #text == 3 then
                text = text:sub(1, 1):rep(2) .. text:sub(2, 2):rep(2) .. text:sub(3, 3):rep(2)
            end
            local value = tonumber(text, 16)
            if value then
                applyInputColor(Color3.fromRGB(math.floor(value / 65536) % 256, math.floor(value / 256) % 256, value % 256))
            end
        end
    end
    rInput:GetPropertyChangedSignal("Text"):Connect(fromRGBInputs)
    gInput:GetPropertyChangedSignal("Text"):Connect(fromRGBInputs)
    bInput:GetPropertyChangedSignal("Text"):Connect(fromRGBInputs)
    hexInput:GetPropertyChangedSignal("Text"):Connect(fromHexInput)

    local function stopRainbow()
        rainbowMode = false
        if rainbowConnection then rainbowConnection:Disconnect() rainbowConnection = nil end
        tween(rainbowBtn, SPRING_FAST, { BackgroundColor3 = T.surface3, TextColor3 = T.text1 })
    end
    local function startRainbow()
        rainbowMode = true
        tween(rainbowBtn, SPRING_FAST, { BackgroundColor3 = T.text1, TextColor3 = T.bg })
        if rainbowConnection then rainbowConnection:Disconnect() end
        rainbowConnection = RS.RenderStepped:Connect(function()
            LPS_ATTRIBUTES(VM(NONE))
            if not rainbowMode then return end
            h, s, v = (os.clock() * 0.08) % 1, 1, 1
            hasPickedColor = true
            updateVisualsFromHSV(false)
            if isBaseplateEnabled then changeColor(Color3.fromHSV(h, s, v), curAlpha) end
        end)
    end
    rainbowBtn.MouseButton1Click:Connect(function()
        if rainbowMode then stopRainbow() else startRainbow() end
    end)

    local function relMouse(frame)
        local inset = GuiService_:GetGuiInset()
        local m = UIS:GetMouseLocation() - inset
        return math.clamp((m.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1),
            math.clamp((m.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y, 0, 1)
    end
    local csDrag, hueDrag = false, false
    csHolder.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            csDrag = true
            if rainbowMode then stopRainbow() end
            local rx, ry = relMouse(csHolder)
            s, v = rx, 1 - ry
            hasPickedColor = true
            updateVisualsFromHSV(true)
        end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hueDrag = true
            if rainbowMode then stopRainbow() end
            local _, ry = relMouse(hueBar)
            h = ry
            hasPickedColor = true
            updateVisualsFromHSV(true)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            if csDrag then
                local rx, ry = relMouse(csHolder)
                s, v = rx, 1 - ry
                updateVisualsFromHSV(true)
            elseif hueDrag then
                local _, ry = relMouse(hueBar)
                h = ry
                updateVisualsFromHSV(true)
            end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            csDrag, hueDrag = false, false
        end
    end)

    local matY = colorY + 190 + 8
    local matCard = card(matY, 190)
    lbl(matCard, "Texture / material", 12, 8, 200, 16, 11, Enum.Font.BuilderSansBold, T.text1)
    local matScroll = new("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 1, -38),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
        ScrollBarImageTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true, ZIndex = 63, Parent = matCard,
    }, { pad(2, 2, 2, 2) })
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 28), CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = matScroll,
    })
    local selectedMatBtn = nil
    local matButtons = {}
    local function styleMat(btn, on)
        tween(btn, SPRING_FAST, {
            BackgroundColor3 = on and T.text1 or T.surface3,
            TextColor3 = on and T.bg or T.text1,
        })
    end
    local function selectMat(btn)
        if selectedMatBtn and selectedMatBtn ~= btn then styleMat(selectedMatBtn, false) end
        selectedMatBtn = btn
        if btn then styleMat(btn, true) end
    end
    local function makeMatButton(displayName, materialValue, order)
        LPS_ATTRIBUTES(VM(NONE))
        local btn = new("TextButton", {
            LayoutOrder = order, BackgroundColor3 = T.surface3, BorderSizePixel = 0,
            AutoButtonColor = false, Text = (displayName == "Air") and "Smooth" or displayName,
            Font = Enum.Font.BuilderSansBold, TextSize = 10.5, TextColor3 = T.text1,
            ZIndex = 64, Parent = matScroll,
        }, { cr(7), stroke(T.line, 1, 0.5) })
        matButtons[displayName] = btn
        btn.MouseEnter:Connect(function()
            if selectedMatBtn ~= btn then tween(btn, SPRING_FAST, { BackgroundColor3 = T.line }) end
        end)
        btn.MouseLeave:Connect(function()
            if selectedMatBtn ~= btn then tween(btn, SPRING_FAST, { BackgroundColor3 = T.surface3 }) end
        end)
        btn.MouseButton1Click:Connect(function()
            selectMat(btn)
            if displayName == "Clear" then
                selectedIsClear, selectedIsInvis = true, false
                selectedMaterialValue = initialMaterial
                clearMode = true
                currentMaterial = initialMaterial
                _G.StandaloneBaseplateMaterial = initialMaterial
                _G.StandaloneBaseplateTransparency = 1
                template.Material = initialMaterial
                if isBaseplateEnabled then
                    removeExtraRoomObjects()
                    hideOriginalBaseplates()
                    for _, obj in ipairs(folder:GetChildren()) do
                        if obj:IsA("BasePart") then
                            obj.Material = initialMaterial
                            obj.CanCollide = true
                            obj.CanTouch = true
                            obj.Transparency = 1
                        end
                    end
                end
            elseif displayName == "Invis" then
                selectedIsClear, selectedIsInvis = false, true
                selectedMaterialValue = initialMaterial
                clearMode = true
                currentMaterial = initialMaterial
                _G.StandaloneBaseplateMaterial = initialMaterial
                _G.StandaloneBaseplateTransparency = 1
                template.Material = initialMaterial
                if isBaseplateEnabled then
                    restoreOriginalBaseplates()
                    for _, obj in ipairs(folder:GetChildren()) do
                        if obj:IsA("BasePart") then
                            obj.Material = initialMaterial
                            obj.CanCollide = true
                            obj.CanTouch = true
                            obj.Transparency = 1
                        end
                    end
                end
            else
                selectedIsClear, selectedIsInvis = false, false
                selectedMaterialValue = materialValue
                clearMode = false
                currentMaterial = materialValue
                _G.StandaloneBaseplateMaterial = materialValue
                template.Material = materialValue
                if isBaseplateEnabled then
                    removeExtraRoomObjects()
                    hideOriginalBaseplates()
                    applyMaterial(materialValue)
                end
            end
        end)
        return btn
    end
    local materialNames = {}
    for _, item in ipairs(Enum.Material:GetEnumItems()) do
        if item ~= Enum.Material.SmoothPlastic and item ~= Enum.Material.Water and item ~= BASEPLATE_MATERIAL then
            table.insert(materialNames, item)
        end
    end
    table.sort(materialNames, function(a, b) return a.Name < b.Name end)
    makeMatButton("Clear", initialMaterial, 1)
    makeMatButton("Invis", initialMaterial, 2)
    makeMatButton(BASEPLATE_MATERIAL.Name, BASEPLATE_MATERIAL, 3)
    for index, item in ipairs(materialNames) do
        makeMatButton(item.Name, item, index + 3)
    end
    if matButtons["Clear"] then selectMat(matButtons["Clear"]) end

    if isMicUp then
        local wipeCard = card(matY + 190 + 8, 52)
        lbl(wipeCard, "Map wiper", 12, 9, 200, 16, 12, Enum.Font.BuilderSansBold, T.text1)
        lbl(wipeCard, "Removes workspace.map (restores when off)", 12, 27, 230, 14, 10, Enum.Font.BuilderSansMedium, T.text3)
        local wipeHost = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(50, 21), BackgroundTransparency = 1, ZIndex = 63, Parent = wipeCard,
        })
        local mapBackupSource = Workspace_:FindFirstChild("map")
        local mapBackup = mapBackupSource and mapBackupSource:Clone() or nil
        local mapParent = mapBackupSource and mapBackupSource.Parent or Workspace_
        local function wipeMap()
            local current = Workspace_:FindFirstChild("map")
            if current then current:Destroy()
            else queueNotification("Map wiper", "No 'map' found in workspace here.", 4, "error") end
        end
        local function restoreMap()
            if not mapBackup or Workspace_:FindFirstChild("map") then return end
            mapBackup:Clone().Parent = mapParent
        end
        makeSwitch(wipeHost, false, function(on)
            if on then wipeMap() else restoreMap() end
        end)
    end

    local isMin, bodyToken = false, 0
    minBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        bodyToken += 1
        local token = bodyToken
        tween(window, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(WIN_W, isMin and HEAD_H or WIN_H),
        })
        if isMin then
            task.delay(0.15, function()
                if token == bodyToken and isMin then body.Visible = false end
            end)
        else
            body.Visible = true
        end
        pcall(_G.SlateHeaderCtl, minBtn, isMin and "plus" or "minus", 12)
    end)

    updateVisualsFromHSV(false)
    openWindow()
end

_G.SlateRunShaders = function()
    if _G.__SlateShadersToggle then
        _G.__SlateShadersToggle()
        return
    end
    local Lighting_ = game:GetService("Lighting")
    local Workspace_ = game:GetService("Workspace")
    local Terrain_ = Workspace_:FindFirstChildOfClass("Terrain")
    local RS = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local BASE = "https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/"
    local CACHE_DIR = "slate/shaders"

    local KEYMAP = {
        fhnchvhfjsd = "cc_brightness", ugtbbjhygt = "cc_contrast", tfbghuugbnjhg = "cc_saturation",
        fvrtccvghghj = "cc_tint", jnfdhbnfcvh = "bloom_intensity", fvtyghj = "bloom_size",
        ygbhnj = "bloom_threshold", njnfg = "blur_size", yfbghj = "ambient", tgvbyd = "clocktime",
        ghuybhuyhj = "latitude", khnbfth = "brightness", hgyghkg = "shift_bottom", yfbhjku = "shift_top",
        ygyyfgvhbjytrt = "env_diffuse", sdfcddc = "env_specular", hgnujuu7thgr = "global_shadows",
        hyhnngtf = "outdoor_ambient", hdfr7thgr = "exposure", gyhgtg = "cloud_cover",
        ygbhggv = "cloud_density", jghbjhgyfd = "cloud_color", shdbsnjfc = "atm_density",
        skdjfkdm = "atm_offset", sjdjncdjf = "atm_color", efjdjfk = "atm_decay", sejfd = "atm_glare",
        jddfjsd = "atm_haze", jdfkd = "dof_far", fvgsdfg = "dof_focus", sdkvkflv = "dof_radius",
        hbjhd = "dof_near",
    }

    local PRESET_LIST = {
        { "Shaders", "Morning", "shr/morning.json", 113299445142241 },
        { "Shaders", "Midday", "shr/midday.json", 92217393876433 },
        { "Shaders", "Afternoon", "shr/afternoon.json", 95808526176628 },
        { "Shaders", "Evening", "shr/evening%2Cjson", 132108667983758 },
        { "Shaders", "Night", "shr/night.json", 100757920131658 },
        { "Shaders", "Midnight", "shr/midnight.json", 97773466118344 },
        { "Lite", "Morning", "shr/morning1.json", 92514237282380 },
        { "Lite", "Midday", "shr/midday1.json", 90305235042714 },
        { "Lite", "Afternoon", "shr/afternoon1.json", 92695333618512 },
        { "Lite", "Evening", "shr/evening1.json", 132108667983758 },
        { "Lite", "Night", "shr/night1.json", 103792896194001 },
        { "Lite", "Midnight", "shr/midnight1.json", 90454550243625 },
        { "Color", "Black", "shr/black.json", 104993140300372 },
        { "Color", "Green", "shr/green.json", 87566194970749 },
        { "Color", "Red", "shr/red.json", 86019467400697 },
        { "Color", "Yellow", "shr/yellow.json", 89622996021764 },
        { "Color", "Pink", "shr/pink.json", 115387662887412 },
        { "Color", "Gray", "shr/gray.json", 129482833602389 },
        { "Color", "White", "shr/white.json", 83122100057126 },
        { "Color", "Purple", "shr/purple.json", 115365056970455 },
        { "Color Lite", "Black", "shr/black1.json", 140706916861132 },
        { "Color Lite", "Green", "shr/green1.json", 89405340565983 },
        { "Color Lite", "Red", "shr/red1.json", 110115983611192 },
        { "Color Lite", "Yellow", "shr/yellow1.json", 101326949437503 },
        { "Color Lite", "Pink", "shr/pink1.json", 111633113748366 },
        { "Color Lite", "Gray", "shr/gray1.json", 138870069540821 },
        { "Color Lite", "White", "shr/white1.json", 83122100057126 },
        { "Color Lite", "Purple", "shr/purple1.json", 72297228732689 },
        { "Weather", "Rain", "shr/rain.json", 121654329755016 },
        { "Weather", "Snow", "shr/snow.json", 110010584259758 },
        { "Weather", "Fog", "shr/fog.json", 112830594028052 },
        { "Weather", "Sunny", "shr/sunny.json", 79338735074080 },
        { "Weather", "Cloudy", "shr/cloudy.json", 132274518547408 },
        { "Weather", "Storm", "shr/storm.json", 94816009531038 },
        { "Seasons", "Autumn", "shr/autumn.json", 80499728835866 },
        { "Seasons", "Spring", "shr/spring.json", 80194430595868 },
        { "Seasons", "Summer", "shr/summer.json", 135858146426147 },
        { "Seasons", "Winter", "shr/winter.json", 109637660711657 },
    }
    local CATEGORIES = { "Shaders", "Lite", "Color", "Color Lite", "Weather", "Seasons" }
    local SKY_LIST = {
        { "Default", nil }, { "Game", "game" }, { "Morning", "sky/m.json" }, { "Midday", "sky/n.json" },
        { "Afternoon", "sky/a.json" }, { "Evening", "sky/e.json" }, { "Rain", "sky/r.json" },
        { "Cloudy", "sky/c.json" },
    }
    local DEFAULT_SKY = {
        bk = "rbxassetid://9544505500", dn = "rbxassetid://9544547905", ft = "rbxassetid://9544504852",
        lt = "rbxassetid://9544547694", rt = "rbxassetid://9544547542", up = "rbxassetid://9544547398",
    }
    local TECHS = { "Future", "ShadowMap", "Compatibility", "Legacy", "Voxel" }

    local function ensureDir()
        pcall(function()
            if type(makefolder) == "function" and type(isfolder) == "function" then
                if not isfolder("slate") then makefolder("slate") end
                if not isfolder(CACHE_DIR) then makefolder(CACHE_DIR) end
            end
        end)
    end
    local function fetchText(path)
        local cacheName = CACHE_DIR .. "/" .. path:gsub("[^%w]", "_") .. ".dat"
        local text
        pcall(function()
            if type(isfile) == "function" and type(readfile) == "function" and isfile(cacheName) then
                text = readfile(cacheName)
            end
        end)
        if type(text) == "string" and #text > 20 then return text end
        local ok, body = pcall(function() return game:HttpGet(BASE .. path) end)
        if ok and type(body) == "string" and #body > 20 and body:find("^%s*return") then
            ensureDir()
            pcall(function() if type(writefile) == "function" then writefile(cacheName, body) end end)
            return body
        end
        return nil
    end
    local function parseData(text)
        if type(text) ~= "string" then return nil end
        local out = {}
        for key, raw in text:gmatch("%[%s*['\"]([%w_]+)['\"]%s*%]%s*=%s*([^\n]-)%s*,?%s*\n") do
            raw = raw:gsub("%-%-.*$", ""):gsub("%s+$", ""):gsub(",$", "")
            local r, g, b = raw:match("Color3%s*%[?['\"]?fromRGB['\"]?%]?%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)")
            local v
            if r then
                v = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
            elseif raw == "true" then v = true
            elseif raw == "false" then v = false
            elseif tonumber(raw) then v = tonumber(raw)
            else
                local s = raw:match("^['\"](.-)['\"]$")
                if s then v = s end
            end
            if v ~= nil then out[KEYMAP[key] or key] = v end
        end
        return next(out) and out or nil
    end

    local state = {
        on = false, preset = nil, presetName = nil, adj = {}, skyName = "Default", sky = DEFAULT_SKY,
        tech = nil, fxOn = { cc = true, bloom = true, dof = true, rays = false, blur = false },
    }
    local base, backup, created, disabledByUs, fx = {}, {}, {}, {}, {}
    local LIGHT_PROPS = { "Ambient", "ClockTime", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows", "OutdoorAmbient",
        "GeographicLatitude", "ExposureCompensation", "FogEnd", "FogStart", "FogColor" }
    local EFFECT_CLASSES = { "ColorCorrectionEffect", "BloomEffect", "BlurEffect", "DepthOfFieldEffect", "SunRaysEffect" }

    local function val(k)
        local a = state.adj[k]
        if a ~= nil then return a end
        local p = state.preset and state.preset[k]
        if p ~= nil then return p end
        return base[k]
    end
    local function setIf(obj, prop, v)
        if v ~= nil and obj[prop] ~= v then obj[prop] = v end
    end
    local function ours(class)
        local o = fx[class]
        if o and o.Parent then return o end
        o = Instance.new(class)
        o.Name = "SlateFx" .. class
        o.Parent = Lighting_
        fx[class] = o
        return o
    end
    local function skyObj()
        local s = Lighting_:FindFirstChildOfClass("Sky")
        if not s then
            s = Instance.new("Sky"); s.Name = "SlateSky"; s.Parent = Lighting_
            created[#created + 1] = s
        end
        return s
    end
    local function atmoObj()
        local a = Lighting_:FindFirstChildOfClass("Atmosphere")
        if not a then
            a = Instance.new("Atmosphere"); a.Name = "SlateAtmosphere"; a.Parent = Lighting_
            created[#created + 1] = a
        end
        return a
    end
    local function cloudObj()
        if not Terrain_ then return nil end
        local c = Terrain_:FindFirstChildOfClass("Clouds")
        if not c then
            c = Instance.new("Clouds"); c.Name = "SlateClouds"; c.Parent = Terrain_
            created[#created + 1] = c
        end
        return c
    end
    local function saveProps(obj, props)
        local t = { obj = obj }
        for _, p in ipairs(props) do pcall(function() t[p] = obj[p] end) end
        return t
    end
    local function restoreProps(t)
        if not (t and t.obj and t.obj.Parent) then return end
        for k, v in pairs(t) do
            if k ~= "obj" then pcall(function() t.obj[k] = v end) end
        end
    end

    local function captureBase()
        base = {}
        backup = {}
        for _, p in ipairs(LIGHT_PROPS) do pcall(function() backup[p] = Lighting_[p] end) end
        base.ambient, base.clocktime, base.brightness = Lighting_.Ambient, Lighting_.ClockTime, Lighting_.Brightness
        base.shift_bottom, base.shift_top = Lighting_.ColorShift_Bottom, Lighting_.ColorShift_Top
        base.env_diffuse, base.env_specular = Lighting_.EnvironmentDiffuseScale, Lighting_.EnvironmentSpecularScale
        base.global_shadows, base.outdoor_ambient = Lighting_.GlobalShadows, Lighting_.OutdoorAmbient
        base.latitude, base.exposure = Lighting_.GeographicLatitude, Lighting_.ExposureCompensation
        local cc = Lighting_:FindFirstChildOfClass("ColorCorrectionEffect")
        base.cc_brightness = cc and cc.Brightness or 0
        base.cc_contrast = cc and cc.Contrast or 0
        base.cc_saturation = cc and cc.Saturation or 0
        base.cc_tint = cc and cc.TintColor or Color3.new(1, 1, 1)
        local bl = Lighting_:FindFirstChildOfClass("BloomEffect")
        base.bloom_intensity = bl and bl.Intensity or 0.4
        base.bloom_size = bl and bl.Size or 24
        base.bloom_threshold = bl and bl.Threshold or 2
        local bu = Lighting_:FindFirstChildOfClass("BlurEffect")
        base.blur_size = bu and bu.Size or 0
        local df = Lighting_:FindFirstChildOfClass("DepthOfFieldEffect")
        base.dof_far = df and df.FarIntensity or 0.75
        base.dof_focus = df and df.FocusDistance or 0.05
        base.dof_radius = df and df.InFocusRadius or 10
        base.dof_near = df and df.NearIntensity or 0.75
        local at = Lighting_:FindFirstChildOfClass("Atmosphere")
        base.atm_density = at and at.Density or 0
        base.atm_offset = at and at.Offset or 0
        base.atm_color = at and at.Color or Color3.fromRGB(199, 199, 199)
        base.atm_decay = at and at.Decay or Color3.fromRGB(92, 60, 13)
        base.atm_glare = at and at.Glare or 0
        base.atm_haze = at and at.Haze or 0
        local cl = Terrain_ and Terrain_:FindFirstChildOfClass("Clouds")
        base.cloud_cover = cl and cl.Cover or 0
        base.cloud_density = cl and cl.Density or 0
        base.cloud_color = cl and cl.Color or Color3.new(1, 1, 1)
    end

    local gameSkyBackup
    local function applyAll()
        local L = Lighting_
        setIf(L, "Ambient", val("ambient"))
        setIf(L, "ClockTime", val("clocktime"))
        setIf(L, "GeographicLatitude", val("latitude"))
        setIf(L, "Brightness", val("brightness"))
        setIf(L, "ColorShift_Bottom", val("shift_bottom"))
        setIf(L, "ColorShift_Top", val("shift_top"))
        setIf(L, "EnvironmentDiffuseScale", val("env_diffuse"))
        setIf(L, "EnvironmentSpecularScale", val("env_specular"))
        setIf(L, "GlobalShadows", val("global_shadows"))
        setIf(L, "OutdoorAmbient", val("outdoor_ambient"))
        setIf(L, "ExposureCompensation", val("exposure"))
        if state.preset then
            setIf(L, "FogEnd", math.huge)
            setIf(L, "FogStart", math.huge)
        end

        local cc = ours("ColorCorrectionEffect")
        cc.Enabled = state.fxOn.cc
        setIf(cc, "Brightness", val("cc_brightness")); setIf(cc, "Contrast", val("cc_contrast"))
        setIf(cc, "Saturation", val("cc_saturation")); setIf(cc, "TintColor", val("cc_tint"))
        local bl = ours("BloomEffect")
        bl.Enabled = state.fxOn.bloom
        setIf(bl, "Intensity", val("bloom_intensity")); setIf(bl, "Size", val("bloom_size"))
        setIf(bl, "Threshold", val("bloom_threshold"))
        local bu = ours("BlurEffect")
        bu.Enabled = state.fxOn.blur
        setIf(bu, "Size", val("blur_size"))
        local df = ours("DepthOfFieldEffect")
        df.Enabled = state.fxOn.dof
        setIf(df, "FarIntensity", val("dof_far")); setIf(df, "FocusDistance", val("dof_focus"))
        setIf(df, "InFocusRadius", val("dof_radius")); setIf(df, "NearIntensity", val("dof_near"))
        local sr = ours("SunRaysEffect")
        sr.Enabled = state.fxOn.rays

        local at = atmoObj()
        if not backup.__atmo then backup.__atmo = saveProps(at, { "Density", "Offset", "Color", "Decay", "Glare", "Haze" }) end
        setIf(at, "Density", val("atm_density")); setIf(at, "Offset", val("atm_offset"))
        setIf(at, "Color", val("atm_color")); setIf(at, "Decay", val("atm_decay"))
        setIf(at, "Glare", val("atm_glare")); setIf(at, "Haze", val("atm_haze"))
        local cl = cloudObj()
        if cl then
            if not backup.__cloud then backup.__cloud = saveProps(cl, { "Cover", "Density", "Color" }) end
            setIf(cl, "Cover", val("cloud_cover")); setIf(cl, "Density", val("cloud_density"))
            setIf(cl, "Color", val("cloud_color"))
        end
        local sk = skyObj()
        if not backup.__sky then
            backup.__sky = saveProps(sk, { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" })
        end
        local ids = state.sky
        if ids == "game" then ids = gameSkyBackup end
        if type(ids) == "table" then
            setIf(sk, "SkyboxBk", ids.bk); setIf(sk, "SkyboxDn", ids.dn); setIf(sk, "SkyboxFt", ids.ft)
            setIf(sk, "SkyboxLf", ids.lt); setIf(sk, "SkyboxRt", ids.rt); setIf(sk, "SkyboxUp", ids.up)
        end
        for _, c in ipairs(L:GetChildren()) do
            if c:IsA("PostEffect") and c ~= fx[c.ClassName] and c.Enabled then
                disabledByUs[c] = true
                c.Enabled = false
            end
        end
        if state.tech then pcall(function() sethiddenproperty(L, "Technology", state.tech) end) end
    end

    local conn, acc = nil, 0
    local function enable()
        if state.on then return end
        state.on = true
        captureBase()
        local gs = Lighting_:FindFirstChildOfClass("Sky")
        if gs then
            gameSkyBackup = { bk = gs.SkyboxBk, dn = gs.SkyboxDn, ft = gs.SkyboxFt, lt = gs.SkyboxLf, rt = gs.SkyboxRt, up = gs.SkyboxUp }
        end
        pcall(function() backup.__tech = gethiddenproperty(Lighting_, "Technology") end)
        applyAll()
        conn = RS.Heartbeat:Connect(function(dt)
            LPS_ATTRIBUTES(VM(NONE))
            acc += dt
            if acc < 0.1 then return end
            acc = 0
            pcall(applyAll)
        end)
    end
    local function disable()
        if not state.on then return end
        state.on = false
        if conn then conn:Disconnect() conn = nil end
        for _, o in pairs(fx) do pcall(function() o:Destroy() end) end
        fx = {}
        for _, o in ipairs(created) do pcall(function() o:Destroy() end) end
        created = {}
        for _, p in ipairs(LIGHT_PROPS) do
            if backup[p] ~= nil then pcall(function() Lighting_[p] = backup[p] end) end
        end
        restoreProps(backup.__atmo); restoreProps(backup.__cloud); restoreProps(backup.__sky)
        for c in pairs(disabledByUs) do if c.Parent then pcall(function() c.Enabled = true end) end end
        disabledByUs = {}
        if backup.__tech ~= nil then pcall(function() sethiddenproperty(Lighting_, "Technology", backup.__tech) end) end
        backup = {}
    end
    local function loadPreset(label, file)
        local text = fetchText(file)
        local data = parseData(text)
        if not data then
            queueNotification("Shaders", "Couldn't load " .. label .. ". Check your connection.", 4, "error")
            return false
        end
        state.preset = data
        state.presetName = label
        state.adj = {}
        return true
    end
    local function loadSky(name, file)
        state.skyName = name
        if name == "Default" then state.sky = DEFAULT_SKY return true end
        if file == "game" then state.sky = "game" return true end
        local data = parseData(fetchText(file))
        if not data then
            queueNotification("Shaders", "Couldn't load that skybox.", 4, "error")
            return false
        end
        state.sky = data
        return true
    end

    local function cr(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
    local WIN_W, WIN_H, HEAD_H = 536, 540, 50

    local window = new("CanvasGroup", {
        Name = "SlateShaders",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, -WIN_H / 2),
        Size = UDim2.fromOffset(WIN_W, WIN_H),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0, BorderSizePixel = 0,
        GroupTransparency = 1, ClipsDescendants = true, Visible = false, ZIndex = 60, Parent = gui,
    }, { cr(18) })
    local winScale = new("UIScale", { Scale = 1, Parent = window })
    pcall(createGlow, window, Color3.fromRGB(0, 0, 0), 28, 0.4)

    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, ZIndex = 62, Parent = window,
    }, { pad(0, 12, 0, 16) })
    local brand = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 220, 0, 32), BackgroundTransparency = 1, ZIndex = 63, Parent = header,
    }, { new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
    }) })
    local logo = new("ImageLabel", {
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=" .. SLATE_LOGO_ASSET .. "&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit, ImageColor3 = T.accent, ZIndex = 64, Parent = brand,
    })
    task.spawn(function()
        local r = resolveDecalImage(SLATE_LOGO_ASSET)
        if r and logo.Parent then logo.Image = r end
    end)
    new("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1,
        Text = "Shaders", Font = Enum.Font.BuilderSansBold, TextSize = 15, TextColor3 = T.text1,
        ZIndex = 64, Parent = brand,
    })
    local dragHandle = new("TextButton", {
        Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        ZIndex = 63, Parent = header,
    })
    local ctlBox = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(60, 26), BackgroundTransparency = 1, ZIndex = 65, Parent = header,
    })
    local function ctlBtn(text, xOff)
        local b = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
            Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = text,
            Font = Enum.Font.BuilderSansMedium, TextSize = 18, TextColor3 = T.text2,
            AutoButtonColor = false, ZIndex = 66, Parent = ctlBox,
        })
        b.MouseEnter:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text1 }) end)
        b.MouseLeave:Connect(function() tween(b, SPRING_FAST, { TextColor3 = T.text2 }) end)
        return b
    end
    local closeBtn, minBtn = ctlBtn("×", 0), ctlBtn("–", -26)
    pcall(_G.SlateHeaderCtl, closeBtn, "x", 11)
    pcall(_G.SlateHeaderCtl, minBtn, "minus", 12)

    local function winHide() window.Visible = false end
    local function openWindow()
        window.Visible = true
        local anim = _G.SlateWindowAnim
        if anim then anim.open(window, winScale) else window.GroupTransparency = 0 end
    end
    local function closeWindow()
        local anim = _G.SlateWindowAnim
        if anim then anim.close(window, winScale, winHide) else winHide() end
    end
    _G.__SlateShadersToggle = function()
        if window.Visible and not window:GetAttribute("SlateClosing") then closeWindow() else openWindow() end
    end
    closeBtn.MouseButton1Click:Connect(closeWindow)

    do
        local dragging, dragStart, dragOrigin, target = false, nil, nil, window.Position
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, dragOrigin, target = true, input.Position, window.Position, window.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                target = _G.SlateClampPos(window, UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y))
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        RS.RenderStepped:Connect(function(dt)
            LPS_ATTRIBUTES(VM(NONE))
            if not window.Visible then return end
            local dx = target.X.Offset - window.Position.X.Offset
            local dy = target.Y.Offset - window.Position.Y.Offset
            if math.abs(dx) < 0.3 and math.abs(dy) < 0.3 then return end
            local f = math.clamp(dt * 22, 0.05, 0.95)
            window.Position = UDim2.new(target.X.Scale, window.Position.X.Offset + dx * f,
                target.Y.Scale, window.Position.Y.Offset + dy * f)
        end)
    end

    local body = new("Frame", {
        Position = UDim2.fromOffset(0, HEAD_H), Size = UDim2.new(1, 0, 1, -HEAD_H),
        BackgroundTransparency = 1, ZIndex = 61, Parent = window,
    })
    local function lbl(parent, text, x, y, w, h, size, font, color)
        return new("TextLabel", {
            Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
            Text = text, Font = font or Enum.Font.BuilderSansBold, TextSize = size or 11,
            TextColor3 = color or T.text1, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 63, Parent = parent,
        })
    end

    local masterCard = new("Frame", {
        Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 48),
        BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        ZIndex = 62, Parent = body,
    }, { cr(10), stroke(T.line, 1, 0.4) })
    lbl(masterCard, "Shaders", 12, 8, 220, 16, 12, Enum.Font.BuilderSansBold, T.text1)
    local statusLbl = lbl(masterCard, "Pick a look below, then turn shaders on", 12, 26, 260, 14, 10,
        Enum.Font.BuilderSansMedium, T.text3)
    local masterHost = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(50, 21), BackgroundTransparency = 1, ZIndex = 63, Parent = masterCard,
    })
    local setMasterVisual
    do
        local sw
        sw = makeSwitch(masterHost, false, function(v)
            if v then enable() else disable() end
            statusLbl.Text = v and ("On" .. (state.presetName and (" · " .. state.presetName) or ""))
                or "Pick a look below, then turn shaders on"
        end)
        setMasterVisual = sw
    end

    local NAV = {
        { "Shaders", "Shaders" }, { "Lite", "Shaders Lite" }, { "Color", "Shaders Color" },
        { "Color Lite", "Color Lite" }, { "Weather", "Weathers" }, { "Seasons", "Seasons" },
        { "Adjustment", "Adjustment" }, { "Effects", "Effects" }, { "Skybox", "Skybox" },
    }
    local SIDE_W = 112
    local sideBar = new("Frame", {
        Position = UDim2.fromOffset(14, 62), Size = UDim2.new(0, SIDE_W, 1, -70),
        BackgroundColor3 = T.surface2, BackgroundTransparency = 0.5, BorderSizePixel = 0,
        ZIndex = 62, Parent = body,
    }, {
        cr(10), pad(5, 5, 5, 5),
        new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local pageHost = new("Frame", {
        Position = UDim2.fromOffset(14 + SIDE_W + 8, 62), Size = UDim2.new(1, -(28 + SIDE_W + 8), 1, -70),
        BackgroundTransparency = 1, ZIndex = 62, Parent = body,
    })
    local pages, tabButtons = {}, {}
    local function showTab(name)
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, b in pairs(tabButtons) do
            tween(b, SPRING_FAST, {
                BackgroundTransparency = (n == name) and 0.1 or 1,
                TextColor3 = (n == name) and T.text1 or T.text2,
            })
        end
    end
    for i, nav in ipairs(NAV) do
        local name, label = nav[1], nav[2]
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.surface3, BackgroundTransparency = 1,
            Text = label, Font = Enum.Font.BuilderSansBold, TextSize = 11, TextColor3 = T.text2,
            TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i,
            ZIndex = 63, Parent = sideBar,
        }, { cr(8), pad(0, 8, 0, 10) })
        tabButtons[name] = b
        b.MouseButton1Click:Connect(function() showTab(name) end)
        local pg = new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageTransparency = 1, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 62, Parent = pageHost,
        }, { pad(4, 6, 12, 4) })
        pages[name] = pg
    end

    local cards = {}
    local function refreshSelection()
        for _, c in ipairs(cards) do
            local sel = (state.presetName == c.label and state.presetCat == c.cat)
            c.stroke.Color = sel and T.accent or T.line
            c.stroke.Transparency = sel and 0 or 0.4
            c.stroke.Thickness = sel and 2 or 1
        end
    end
    local function buildPresetPage(cat)
        LPS_ATTRIBUTES(VM(NONE))
        local grid = new("Frame", {
            Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, ZIndex = 63, Parent = pages[cat],
        }, {
            new("UIGridLayout", {
                CellSize = UDim2.new(0.5, -4, 0, 84), CellPadding = UDim2.fromOffset(8, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        local order = 0
        local function addCard(label, file, imageId)
            LPS_ATTRIBUTES(VM(NONE))
            order += 1
            local f = new("TextButton", {
                BackgroundColor3 = T.surface3, BackgroundTransparency = 0.2, BorderSizePixel = 0,
                Text = "", AutoButtonColor = false, ClipsDescendants = true, LayoutOrder = order,
                ZIndex = 64, Parent = grid,
            }, { cr(10) })
            if imageId then
                new("ImageLabel", {
                    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                    Image = "rbxassetid://" .. tostring(imageId), ScaleType = Enum.ScaleType.Crop,
                    ZIndex = 64, Parent = f,
                }, { cr(10) })
            end
            new("Frame", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 65, Parent = f,
            }, { cr(10), new("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) }),
            }) })
            new("TextLabel", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -6), Size = UDim2.new(1, -20, 0, 14),
                BackgroundTransparency = 1, Text = label, Font = Enum.Font.BuilderSansBold, TextSize = 11,
                TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 66, Parent = f,
            })
            local st = stroke(T.line, 1, 0.4)
            st.Parent = f
            cards[#cards + 1] = { frame = f, stroke = st, label = label, cat = cat }
            f.MouseButton1Click:Connect(function()
                task.spawn(function()
                    statusLbl.Text = "Loading " .. label .. "…"
                    if file == "default" then
                        state.preset, state.adj = nil, {}
                    elseif not loadPreset(label, file) then
                        statusLbl.Text = "Couldn't load " .. label
                        return
                    end
                    state.presetCat = cat
                    state.presetName = label
                    refreshSelection()
                    statusLbl.Text = state.on and ("On · " .. label) or ("Selected " .. label .. " · turn shaders on")
                    if state.on then pcall(applyAll) end
                end)
            end)
        end
        addCard("Default", "default", nil)
        for _, p in ipairs(PRESET_LIST) do
            if p[1] == cat then addCard(p[2], p[3], p[4]) end
        end
    end
    for _, cat in ipairs(CATEGORIES) do buildPresetPage(cat) end

    captureBase()
    local adjPage = pages.Adjustment
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = adjPage })
    local adjOrder = 0
    local function nextOrder() adjOrder += 1 return adjOrder end
    local function heading(text)
        local h = new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.upper(text),
            Font = Enum.Font.BuilderSansBold, TextSize = 9.5, TextColor3 = T.text3,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(), ZIndex = 63, Parent = adjPage,
        })
        return h
    end
    local function sliderRow(title, key, min, max, step, defaultFn)
        LPS_ATTRIBUTES(VM(NONE))
        local cont = makeSlider(adjPage, {
            title = title, min = min, max = max, default = defaultFn(), step = step, suffix = "",
            onChange = function(v)
                state.adj[key] = v
                if state.on then pcall(applyAll) end
            end,
        })
        if cont then cont.LayoutOrder = nextOrder() end
    end
    local function toggleRow(text, key)
        LPS_ATTRIBUTES(VM(NONE))
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4,
            BorderSizePixel = 0, LayoutOrder = nextOrder(), ZIndex = 63, Parent = adjPage,
        }, { cr(10), stroke(T.line, 1, 0.4) })
        lbl(row, text, 12, 12, 220, 16, 11, Enum.Font.BuilderSansBold, T.text1)
        local host = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(50, 21), BackgroundTransparency = 1, ZIndex = 64, Parent = row,
        })
        makeSwitch(host, state.fxOn[key], function(v)
            state.fxOn[key] = v
            if state.on then pcall(applyAll) end
        end)
    end
    local function defOf(k, fallback) return function() return (state.preset and state.preset[k]) or base[k] or fallback end end

    do
        local row = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = nextOrder(),
            ZIndex = 63, Parent = adjPage,
        }, { cr(10), stroke(T.line, 1, 0.4) })
        lbl(row, "Lighting technology", 12, 12, 200, 16, 11, Enum.Font.BuilderSansBold, T.text1)
        local val_ = new("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(120, 16),
            BackgroundTransparency = 1, Text = "Game default", Font = Enum.Font.BuilderSansMedium, TextSize = 10.5,
            TextColor3 = T.text2, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 64, Parent = row,
        })
        local idx = 0
        row.MouseButton1Click:Connect(function()
            idx = idx % #TECHS + 1
            state.tech = TECHS[idx]
            val_.Text = state.tech
            if state.on then pcall(applyAll) end
        end)
    end

    heading("Time")
    sliderRow("Clock time", "clocktime", 0, 24, 0.1, defOf("clocktime", 14))
    sliderRow("Geographic latitude", "latitude", 0, 180, 1, defOf("latitude", 0))
    sliderRow("Brightness", "brightness", 0, 6, 0.05, defOf("brightness", 2))
    sliderRow("Exposure", "exposure", -3, 3, 0.05, defOf("exposure", 0))
    heading("Color correction")
    toggleRow("Color correction", "cc")
    sliderRow("CC brightness", "cc_brightness", -1, 1, 0.02, defOf("cc_brightness", 0))
    sliderRow("CC contrast", "cc_contrast", -1, 1, 0.02, defOf("cc_contrast", 0))
    sliderRow("CC saturation", "cc_saturation", -1, 1, 0.02, defOf("cc_saturation", 0))
    heading("Bloom")
    toggleRow("Bloom", "bloom")
    sliderRow("Bloom intensity", "bloom_intensity", 0, 2, 0.02, defOf("bloom_intensity", 0.4))
    sliderRow("Bloom size", "bloom_size", 0, 56, 1, defOf("bloom_size", 24))
    sliderRow("Bloom threshold", "bloom_threshold", 0, 4, 0.05, defOf("bloom_threshold", 1))
    heading("Depth of field")
    toggleRow("Depth of field", "dof")
    sliderRow("Far intensity", "dof_far", 0, 1, 0.02, defOf("dof_far", 0))
    sliderRow("Near intensity", "dof_near", 0, 1, 0.02, defOf("dof_near", 0))
    sliderRow("Focus distance", "dof_focus", 0, 200, 1, defOf("dof_focus", 20))
    sliderRow("In-focus radius", "dof_radius", 0, 50, 1, defOf("dof_radius", 10))
    heading("Atmosphere & clouds")
    sliderRow("Atmosphere density", "atm_density", 0, 1, 0.01, defOf("atm_density", 0))
    sliderRow("Atmosphere offset", "atm_offset", 0, 1, 0.01, defOf("atm_offset", 0))
    sliderRow("Atmosphere glare", "atm_glare", 0, 10, 0.1, defOf("atm_glare", 0))
    sliderRow("Atmosphere haze", "atm_haze", 0, 10, 0.1, defOf("atm_haze", 0))
    sliderRow("Cloud cover", "cloud_cover", 0, 1, 0.01, defOf("cloud_cover", 0))
    sliderRow("Cloud density", "cloud_density", 0, 1, 0.01, defOf("cloud_density", 0))
    adjPage = pages.Effects
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = adjPage })
    adjOrder = 0
    heading("Effects")
    toggleRow("Sun rays", "rays")
    toggleRow("Blur", "blur")
    sliderRow("Blur size", "blur_size", 0, 56, 1, defOf("blur_size", 0))

    local skyPage = pages.Skybox
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = skyPage })
    local skyButtons = {}
    local function refreshSky()
        for n, b in pairs(skyButtons) do
            local sel = (n == state.skyName)
            b.stroke.Color = sel and T.accent or T.line
            b.stroke.Transparency = sel and 0 or 0.4
            b.label.TextColor3 = sel and T.text1 or T.text2
        end
    end
    for i, s in ipairs(SKY_LIST) do
        local name, file = s[1], s[2]
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 63, Parent = skyPage,
        }, { cr(10) })
        local st = stroke(T.line, 1, 0.4)
        st.Parent = b
        local l = lbl(b, name, 14, 11, 260, 16, 11.5, Enum.Font.BuilderSansBold, T.text2)
        skyButtons[name] = { stroke = st, label = l }
        b.MouseButton1Click:Connect(function()
            task.spawn(function()
                if loadSky(name, file) then
                    refreshSky()
                    if state.on then pcall(applyAll) end
                end
            end)
        end)
    end
    refreshSky()

    showTab("Shaders")
    window.Destroying:Connect(function() disable() end)
    openWindow()
end

_G.SlateRunClicker = function()
    if _G.__SlateClickerToggle then
        _G.__SlateClickerToggle()
        return
    end
    local RS = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local HttpService_ = game:GetService("HttpService")
    local SAVE_FILE = "slate/clicker.json"

    local BUILDINGS = {
        { "Hand Oven",        15,        0.1,     "A tiny oven that bakes one biscuit at a time", "flame" },
        { "Apprentice Baker", 100,       1,       "Learns the trade and keeps the trays full", "chef-hat" },
        { "Corner Bakery",    1100,      8,       "A cosy shop with a queue out the door", "store" },
        { "Dough Mixer",      12000,     47,      "Kneads far faster than any pair of hands", "blend" },
        { "Biscuit Factory",  130000,    260,     "Conveyor belts of golden biscuits", "factory" },
        { "Sugar Mine",       1400000,   1400,    "Dig deep for the sweetest crystals", "pickaxe" },
        { "Cream Portal",     20000000,  7800,    "Pulls cream in from a nearby dimension", "orbit" },
        { "Time Oven",        330000000, 44000,   "Bakes yesterday's biscuits tomorrow", "hourglass" },
        { "Star Bakery",      5.1e9,     260000,  "Heated by a small, friendly sun", "star" },
        { "Cosmic Kitchen",   75e9,      1600000, "Biscuits for every galaxy", "sparkles" },
    }
    local COST_GROWTH = 1.15
    local TIER_COUNTS = { 10, 25, 50, 100 }
    local TIER_COST_MULT = { 10, 50, 500, 5000 }
    local CLICK_UPGRADES = {
        { id = "click1", name = "Sturdy Fingers",   desc = "Clicks give twice as much",        cost = 100,     need = 50 },
        { id = "click2", name = "Floury Gloves",    desc = "Clicks give twice as much",        cost = 1000,    need = 500 },
        { id = "click3", name = "Rolling Pin",      desc = "Clicks give twice as much",        cost = 50000,   need = 25000 },
        { id = "click4", name = "Master's Touch",   desc = "Clicks give twice as much",        cost = 5e6,     need = 2.5e6 },
        { id = "click5", name = "Golden Whisk",     desc = "Clicks give twice as much",        cost = 5e8,     need = 2.5e8 },
        { id = "finger1", name = "Helpful Hands",   desc = "Clicks also give 1% of your /s",   cost = 10000,   need = 5000 },
        { id = "finger2", name = "Team Effort",     desc = "Clicks also give 2% of your /s",   cost = 2e6,     need = 1e6 },
    }
    local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }
    local function fmt(n)
        n = tonumber(n) or 0
        if n < 1000 then
            if n < 10 and n % 1 ~= 0 then return string.format("%.1f", n) end
            return string.format("%d", math.floor(n))
        end
        local i = 1
        while n >= 1000 and i < #SUFFIX do n = n / 1000; i += 1 end
        return string.format("%.2f%s", n, SUFFIX[i])
    end
    local ACHIEVEMENTS = {
        { "First Batch", "Bake 1 biscuit", function(s) return s.total >= 1 end },
        { "Tray Full", "Bake 1,000 biscuits", function(s) return s.total >= 1e3 end },
        { "Bakery Boom", "Bake 1 million biscuits", function(s) return s.total >= 1e6 end },
        { "Biscuit Baron", "Bake 1 billion biscuits", function(s) return s.total >= 1e9 end },
        { "Industrial", "Bake 1 trillion biscuits", function(s) return s.total >= 1e12 end },
        { "Clicking Along", "Click 100 times", function(s) return s.clicks >= 100 end },
        { "Finger Workout", "Click 5,000 times", function(s) return s.clicks >= 5000 end },
        { "Expansion", "Own 10 of one building", function(s)
            for _, c in ipairs(s.counts) do if c >= 10 then return true end end return false end },
        { "Empire", "Own 50 of one building", function(s)
            for _, c in ipairs(s.counts) do if c >= 50 then return true end end return false end },
        { "Lucky Day", "Catch a lucky biscuit", function(s) return s.lucky >= 1 end },
        { "Fortune", "Catch 25 lucky biscuits", function(s) return s.lucky >= 25 end },
        { "Fresh Start", "Rise once", function(s) return s.stars > 0 end },
    }

    local S = {
        biscuits = 0, total = 0, run = 0, clicks = 0, lucky = 0, stars = 0,
        counts = {}, upg = {}, ach = {}, buff = 0, buffMult = 1, t = os.time(), buy = 1,
    }
    for i = 1, #BUILDINGS do S.counts[i] = 0 end
    local function load()
        pcall(function()
            if type(isfile) == "function" and type(readfile) == "function" and isfile(SAVE_FILE) then
                local d = HttpService_:JSONDecode(readfile(SAVE_FILE))
                if type(d) == "table" then
                    for _, k in ipairs({ "biscuits", "total", "run", "clicks", "lucky", "stars" }) do
                        if tonumber(d[k]) then S[k] = tonumber(d[k]) end
                    end
                    if type(d.counts) == "table" then
                        for i = 1, #BUILDINGS do S.counts[i] = tonumber(d.counts[i]) or 0 end
                    end
                    if type(d.upg) == "table" then S.upg = d.upg end
                    if type(d.ach) == "table" then S.ach = d.ach end
                    S.t = tonumber(d.t) or os.time()
                end
            end
        end)
    end
    local function save()
        pcall(function()
            if type(writefile) ~= "function" then return end
            if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("slate") then makefolder("slate") end
            S.t = os.time()
            writefile(SAVE_FILE, HttpService_:JSONEncode({
                biscuits = S.biscuits, total = S.total, run = S.run, clicks = S.clicks, lucky = S.lucky,
                stars = S.stars, counts = S.counts, upg = S.upg, ach = S.ach, t = S.t,
            }))
        end)
    end

    local function tierMult(i)
        local m = 1
        for t = 1, #TIER_COUNTS do
            if S.upg["b" .. i .. "_" .. t] then m *= 2 end
        end
        return m
    end
    local function starMult() return 1 + S.stars * 0.02 end
    local function cps()
        local sum = 0
        for i, b in ipairs(BUILDINGS) do
            sum += S.counts[i] * b[3] * tierMult(i)
        end
        local buff = (os.clock() < S.buff) and S.buffMult or 1
        return sum * starMult() * buff
    end
    local function clickValue()
        local v = 1
        for n = 1, 5 do if S.upg["click" .. n] then v *= 2 end end
        local frac = (S.upg.finger1 and 0.01 or 0) + (S.upg.finger2 and 0.02 or 0)
        return (v + cps() * frac) * starMult()
    end
    local function buildingCost(i, count, qty)
        LPS_ATTRIBUTES(VM(NONE))
        local base = BUILDINGS[i][2]
        local first = base * COST_GROWTH ^ count
        return first * (COST_GROWTH ^ qty - 1) / (COST_GROWTH - 1)
    end
    local function maxAffordable(i)
        local n = 0
        while n < 500 and buildingCost(i, S.counts[i], n + 1) <= S.biscuits do n += 1 end
        return n
    end
    local function earn(amount)
        S.biscuits += amount
        S.total += amount
        S.run += amount
    end
    local function starsAvailable()
        return math.floor((S.run / 1e9) ^ (1 / 3))
    end

    local function cr(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
    local WIN_W, WIN_H, HEAD_H = 640, 440, 50
    local window = new("CanvasGroup", {
        Name = "SlateClicker",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, -WIN_H / 2),
        Size = UDim2.fromOffset(WIN_W, WIN_H),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0, BorderSizePixel = 0,
        GroupTransparency = 1, ClipsDescendants = true, Visible = false, ZIndex = 60, Parent = gui,
    }, { cr(18) })
    local winScale = new("UIScale", { Scale = 1, Parent = window })
    pcall(createGlow, window, Color3.fromRGB(0, 0, 0), 28, 0.4)

    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, ZIndex = 62, Parent = window,
    }, { pad(0, 12, 0, 16) })
    local brand = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 260, 0, 32), BackgroundTransparency = 1, ZIndex = 63, Parent = header,
    }, { new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
    }) })
    local logo = new("ImageLabel", {
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=" .. SLATE_LOGO_ASSET .. "&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit, ImageColor3 = T.accent, ZIndex = 64, Parent = brand,
    })
    task.spawn(function()
        local r = resolveDecalImage(SLATE_LOGO_ASSET)
        if r and logo.Parent then logo.Image = r end
    end)
    new("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1,
        Text = "Cookie Clicker", Font = Enum.Font.BuilderSansBold, TextSize = 15, TextColor3 = T.text1,
        ZIndex = 64, Parent = brand,
    })
    local dragHandle = new("TextButton", {
        Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        ZIndex = 63, Parent = header,
    })
    local closeBtn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1, Text = "×", Font = Enum.Font.BuilderSansMedium, TextSize = 18,
        TextColor3 = T.text2, AutoButtonColor = false, ZIndex = 66, Parent = header,
    })
    pcall(_G.SlateHeaderCtl, closeBtn, "x", 11)

    local function winHide() window.Visible = false; save() end
    local function openWindow()
        window.Visible = true
        local anim = _G.SlateWindowAnim
        if anim then anim.open(window, winScale) else window.GroupTransparency = 0 end
    end
    local function closeWindow()
        local anim = _G.SlateWindowAnim
        if anim then anim.close(window, winScale, winHide) else winHide() end
    end
    _G.__SlateClickerToggle = function()
        if window.Visible and not window:GetAttribute("SlateClosing") then closeWindow() else openWindow() end
    end
    closeBtn.MouseButton1Click:Connect(closeWindow)

    do
        local dragging, dragStart, dragOrigin, target = false, nil, nil, window.Position
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, dragOrigin, target = true, input.Position, window.Position, window.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                target = _G.SlateClampPos(window, UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X,
                    dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y))
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        RS.RenderStepped:Connect(function(dt)
            LPS_ATTRIBUTES(VM(NONE))
            if not window.Visible then return end
            local dx = target.X.Offset - window.Position.X.Offset
            local dy = target.Y.Offset - window.Position.Y.Offset
            if math.abs(dx) < 0.3 and math.abs(dy) < 0.3 then return end
            local f = math.clamp(dt * 22, 0.05, 0.95)
            window.Position = UDim2.new(target.X.Scale, window.Position.X.Offset + dx * f,
                target.Y.Scale, window.Position.Y.Offset + dy * f)
        end)
    end

    local body = new("Frame", {
        Position = UDim2.fromOffset(0, HEAD_H), Size = UDim2.new(1, 0, 1, -HEAD_H),
        BackgroundTransparency = 1, ZIndex = 61, Parent = window,
    })
    local function lbl(parent, text, size, font, color, align)
        return new("TextLabel", {
            BackgroundTransparency = 1, Text = text, Font = font or Enum.Font.BuilderSansBold,
            TextSize = size or 12, TextColor3 = color or T.text1,
            TextXAlignment = align or Enum.TextXAlignment.Left, ZIndex = 64, Parent = parent,
        })
    end

    local left = new("Frame", {
        Position = UDim2.fromOffset(14, 4), Size = UDim2.new(0, 236, 1, -18),
        BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        ZIndex = 62, Parent = body,
    }, { cr(14), stroke(T.line, 1, 0.4) })
    local countLbl = lbl(left, "0", 30, Enum.Font.BuilderSansBold, T.text1, Enum.TextXAlignment.Center)
    countLbl.Position = UDim2.fromOffset(0, 16); countLbl.Size = UDim2.new(1, 0, 0, 36)
    countLbl.TextTruncate = Enum.TextTruncate.AtEnd
    local nameLbl = lbl(left, "cookies", 11, Enum.Font.BuilderSansMedium, T.text3, Enum.TextXAlignment.Center)
    nameLbl.Position = UDim2.fromOffset(0, 54); nameLbl.Size = UDim2.new(1, 0, 0, 14)
    local cpsLbl = lbl(left, "0 per second", 11, Enum.Font.BuilderSansMedium, T.text2, Enum.TextXAlignment.Center)
    cpsLbl.Position = UDim2.fromOffset(0, 70); cpsLbl.Size = UDim2.new(1, 0, 0, 14)

    local biscuitHost = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 1, ZIndex = 63, Parent = left,
    })
    local biscuit = new("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false, ZIndex = 64, Parent = biscuitHost,
    })
    local COOKIE_ASSET = 89079205467397
    local cookieImg = new("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.92, 0.92), BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=" .. COOKIE_ASSET .. "&w=420&h=420",
        ScaleType = Enum.ScaleType.Fit, ZIndex = 65, Active = false, Parent = biscuit,
    })
    task.spawn(function()
        local r = resolveDecalImage(COOKIE_ASSET)
        if r and cookieImg.Parent then cookieImg.Image = r end
    end)
    local biscuitScale = new("UIScale", { Scale = 1, Parent = biscuit })

    local rise = new("Frame", {
        Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ClipsDescendants = false, ZIndex = 90, Active = false, Parent = left,
    })
    local function floatText(text, x, y)
        local t = new("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(100, 18),
            BackgroundTransparency = 1, Text = text, Font = Enum.Font.BuilderSansBold, TextSize = 14,
            TextColor3 = T.text1, TextStrokeTransparency = 0.6, ZIndex = 91, Parent = rise,
        })
        tween(t, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(x, y - 46), TextTransparency = 1, TextStrokeTransparency = 1,
        })
        task.delay(0.9, function() t:Destroy() end)
    end

    local risePanel = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -28, 0, 34),
        BackgroundColor3 = T.surface3, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 63, Parent = left,
    }, { cr(10), stroke(T.line, 1, 0.45) })
    local riseLbl = lbl(risePanel, "", 11, Enum.Font.BuilderSansBold, T.text2, Enum.TextXAlignment.Center)
    riseLbl.Size = UDim2.fromScale(1, 1)
    local riseBtn = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        ZIndex = 66, Parent = risePanel,
    })

    local right = new("Frame", {
        Position = UDim2.fromOffset(258, 4), Size = UDim2.new(1, -272, 1, -18),
        BackgroundTransparency = 1, ZIndex = 62, Parent = body,
    })
    local tabBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.surface2, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, ZIndex = 63, Parent = right,
    }, { cr(9), pad(3, 3, 3, 3), new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3),
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }) })
    local listHost = new("Frame", {
        Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), BackgroundTransparency = 1,
        ZIndex = 63, Parent = right,
    })
    local TAB_NAMES = { "Buildings", "Upgrades", "Stats" }
    local pagesC, tabBtns = {}, {}
    local function showTab(name)
        for n, p in pairs(pagesC) do p.Visible = (n == name) end
        for n, b in pairs(tabBtns) do
            tween(b, SPRING_FAST, { BackgroundTransparency = (n == name) and 0.1 or 1,
                TextColor3 = (n == name) and T.text1 or T.text2 })
        end
    end
    for _, name in ipairs(TAB_NAMES) do
        local b = new("TextButton", {
            Size = UDim2.new(1 / #TAB_NAMES, -2, 1, 0), BackgroundColor3 = T.surface3, BackgroundTransparency = 1,
            Text = name, Font = Enum.Font.BuilderSansBold, TextSize = 11, TextColor3 = T.text2,
            AutoButtonColor = false, ZIndex = 64, Parent = tabBar,
        }, { cr(7) })
        tabBtns[name] = b
        local pg = new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageTransparency = 1, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 63, Parent = listHost,
        }, { pad(2, 2, 10, 2), new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
        pagesC[name] = pg
        b.MouseButton1Click:Connect(function() showTab(name) end)
    end

    local qtyRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 0, ZIndex = 64, Parent = pagesC.Buildings,
    }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
        VerticalAlignment = Enum.VerticalAlignment.Center }) })
    local qtyBtns = {}
    for _, q in ipairs({ { "1", 1 }, { "10", 10 }, { "Max", -1 } }) do
        local b = new("TextButton", {
            Size = UDim2.fromOffset(54, 24), BackgroundColor3 = T.surface3, BackgroundTransparency = 0.4,
            Text = "Buy " .. q[1], Font = Enum.Font.BuilderSansBold, TextSize = 10, TextColor3 = T.text2,
            AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 65, Parent = qtyRow,
        }, { cr(7) })
        qtyBtns[q[2]] = b
        b.MouseButton1Click:Connect(function()
            S.buy = q[2]
            for v, btn in pairs(qtyBtns) do
                btn.TextColor3 = (v == S.buy) and T.text1 or T.text2
                btn.BackgroundTransparency = (v == S.buy) and 0.1 or 0.4
            end
        end)
    end
    qtyBtns[1].TextColor3 = T.text1
    qtyBtns[1].BackgroundTransparency = 0.1

    local bRows = {}
    for i, b in ipairs(BUILDINGS) do
        local row = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 64,
            Parent = pagesC.Buildings,
        }, { cr(10), stroke(T.line, 1, 0.45) })
        local iconHolder = new("Frame", {
            Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = T.surface3,
            BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 65, Active = false, Parent = row,
        }, { new("UICorner", { CornerRadius = UDim.new(0, 8) }) })
        local bIcon = icon(iconHolder, b[5] or "circle", 15, T.text2)
        bIcon.ZIndex = 66
        local name = lbl(row, b[1], 12, Enum.Font.BuilderSansBold, T.text1)
        name.Position = UDim2.fromOffset(50, 6); name.Size = UDim2.new(1, -130, 0, 16)
        local sub = lbl(row, b[4], 9.5, Enum.Font.BuilderSansMedium, T.text3)
        sub.Position = UDim2.fromOffset(50, 24); sub.Size = UDim2.new(1, -150, 0, 14)
        sub.TextTruncate = Enum.TextTruncate.AtEnd
        local owned = lbl(row, "0", 16, Enum.Font.BuilderSansBold, T.text2, Enum.TextXAlignment.Right)
        owned.AnchorPoint = Vector2.new(1, 0); owned.Position = UDim2.new(1, -12, 0, 4); owned.Size = UDim2.fromOffset(60, 20)
        local cost = lbl(row, "", 10.5, Enum.Font.BuilderSansBold, T.text2, Enum.TextXAlignment.Right)
        cost.AnchorPoint = Vector2.new(1, 0); cost.Position = UDim2.new(1, -12, 0, 26); cost.Size = UDim2.fromOffset(90, 14)
        bRows[i] = { row = row, owned = owned, cost = cost, name = name }
        row.MouseButton1Click:Connect(function()
            local qty = S.buy == -1 and maxAffordable(i) or S.buy
            if qty <= 0 then return end
            local c = buildingCost(i, S.counts[i], qty)
            if S.biscuits >= c then
                S.biscuits -= c
                S.counts[i] += qty
            end
        end)
    end

    local upgradeEntries = {}
    local function allUpgrades()
        local list = {}
        for _, u in ipairs(CLICK_UPGRADES) do list[#list + 1] = u end
        for i, b in ipairs(BUILDINGS) do
            for t, n in ipairs(TIER_COUNTS) do
                list[#list + 1] = {
                    id = "b" .. i .. "_" .. t, name = b[1] .. " Mk " .. t,
                    desc = b[1] .. " output doubles", cost = b[2] * TIER_COST_MULT[t],
                    need = nil, building = i, count = n,
                }
            end
        end
        return list
    end
    local ALL_UPGRADES = allUpgrades()
    local function unlocked(u)
        if u.building then return S.counts[u.building] >= u.count end
        return S.total >= u.need
    end
    local upgradePage = pagesC.Upgrades
    local upgradeRows = {}
    local lastUpgradeSig = ""
    local function rebuildUpgrades()
        local sig = {}
        for _, u in ipairs(ALL_UPGRADES) do
            if not S.upg[u.id] and unlocked(u) then sig[#sig + 1] = u.id end
        end
        local s = table.concat(sig, ",")
        if s == lastUpgradeSig then return end
        lastUpgradeSig = s
        for _, r in ipairs(upgradeRows) do r.row:Destroy() end
        upgradeRows = {}
        local order = 0
        for _, u in ipairs(ALL_UPGRADES) do
            if not S.upg[u.id] and unlocked(u) then
                order += 1
                local row = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.surface2, BackgroundTransparency = 0.4,
                    BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = order, ZIndex = 64,
                    Parent = upgradePage,
                }, { cr(10), stroke(T.line, 1, 0.45) })
                local n = lbl(row, u.name, 12, Enum.Font.BuilderSansBold, T.text1)
                n.Position = UDim2.fromOffset(12, 6); n.Size = UDim2.new(1, -110, 0, 16)
                local d = lbl(row, u.desc, 9.5, Enum.Font.BuilderSansMedium, T.text3)
                d.Position = UDim2.fromOffset(12, 24); d.Size = UDim2.new(1, -110, 0, 14)
                local c = lbl(row, fmt(u.cost), 11, Enum.Font.BuilderSansBold, T.text2, Enum.TextXAlignment.Right)
                c.AnchorPoint = Vector2.new(1, 0.5); c.Position = UDim2.new(1, -12, 0.5, 0); c.Size = UDim2.fromOffset(90, 16)
                upgradeRows[#upgradeRows + 1] = { row = row, cost = c, u = u }
                row.MouseButton1Click:Connect(function()
                    if S.biscuits >= u.cost and not S.upg[u.id] then
                        S.biscuits -= u.cost
                        S.upg[u.id] = true
                        lastUpgradeSig = ""
                    end
                end)
            end
        end
        if #upgradeRows == 0 then
            local e = lbl(upgradePage, "Nothing unlocked yet. Keep baking!", 11, Enum.Font.BuilderSansMedium, T.text3)
            e.Size = UDim2.new(1, 0, 0, 30); e.LayoutOrder = 1
            upgradeRows[1] = { row = e, cost = e }
        end
    end

    local statsLabel = lbl(pagesC.Stats, "", 11.5, Enum.Font.BuilderSansMedium, T.text2)
    statsLabel.Size = UDim2.new(1, 0, 0, 160); statsLabel.TextWrapped = true
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top; statsLabel.LayoutOrder = 1
    local achHeader = lbl(pagesC.Stats, "ACHIEVEMENTS", 9.5, Enum.Font.BuilderSansBold, T.text3)
    achHeader.Size = UDim2.new(1, 0, 0, 18); achHeader.LayoutOrder = 2
    local achLabels = {}
    for i, a in ipairs(ACHIEVEMENTS) do
        local r = lbl(pagesC.Stats, "", 11, Enum.Font.BuilderSansMedium, T.text3)
        r.Size = UDim2.new(1, 0, 0, 16); r.LayoutOrder = 2 + i
        achLabels[i] = r
    end

    local lucky = new("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(46, 46), Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "🍀", TextSize = 38,
        Font = Enum.Font.BuilderSans, TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false, Visible = false, ZIndex = 120, Parent = window,
    })
    local luckyHideAt = 0
    local nextLucky = os.clock() + math.random(60, 110)
    lucky.MouseButton1Click:Connect(function()
        lucky.Visible = false
        S.lucky += 1
        if math.random() < 0.5 then
            local gain = math.max(13, cps() * 600)
            earn(gain)
            queueNotification("Lucky cookie", "+" .. fmt(gain) .. " cookies", 4, "success")
        else
            S.buff = os.clock() + 30
            S.buffMult = 7
            queueNotification("Lucky cookie", "Baking is x7 for 30 seconds", 4, "success")
        end
    end)

    local function doRise()
        local gain = starsAvailable() - S.stars
        if gain <= 0 then return end
        S.stars += gain
        S.biscuits, S.run, S.buff = 0, 0, 0
        for i = 1, #BUILDINGS do S.counts[i] = 0 end
        S.upg = {}
        lastUpgradeSig = ""
        queueNotification("You rose", "+" .. gain .. " stars (+" .. gain * 2 .. "% baking)", 5, "success")
        save()
    end
    riseBtn.MouseButton1Click:Connect(doRise)

    biscuit.MouseButton1Click:Connect(function()
        local v = clickValue()
        earn(v)
        S.clicks += 1
        local m = UIS:GetMouseLocation()
        local abs, size = left.AbsolutePosition, left.AbsoluteSize
        floatText("+" .. fmt(v), math.clamp(m.X - abs.X, 20, size.X - 20), math.clamp(m.Y - abs.Y - 36, 20, size.Y - 20))
        biscuitScale.Scale = 0.93
        tween(biscuitScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
    end)

    load()
    do
        local away = math.clamp(os.time() - (S.t or os.time()), 0, 7200)
        if away > 60 then
            local c = cps() * 0.5 * away
            if c > 0 then
                earn(c)
                task.delay(1, function()
                    queueNotification("Welcome back", "Your bakery made " .. fmt(c) .. " biscuits while you were away", 5, "info")
                end)
            end
        end
    end
    local accumUI, accumSave = 0, 0
    RS.Heartbeat:Connect(function(dt)
        LPS_ATTRIBUTES(VM(NONE))
        earn(cps() * dt)
        accumSave += dt
        if accumSave > 15 then accumSave = 0; save() end
        accumUI += dt
        if accumUI < 0.1 then return end
        accumUI = 0
        if not window.Visible then return end
        countLbl.Text = fmt(S.biscuits)
        local buffed = os.clock() < S.buff
        cpsLbl.Text = fmt(cps()) .. " per second" .. (buffed and "  (x" .. S.buffMult .. ")" or "")
        cpsLbl.TextColor3 = buffed and Color3.fromRGB(255, 214, 92) or T.text2
        for i, r in ipairs(bRows) do
            local qty = S.buy == -1 and math.max(1, maxAffordable(i)) or S.buy
            local c = buildingCost(i, S.counts[i], qty)
            r.owned.Text = tostring(S.counts[i])
            r.cost.Text = fmt(c) .. (qty > 1 and ("  (x" .. qty .. ")") or "")
            local afford = S.biscuits >= c
            r.cost.TextColor3 = afford and T.success or T.text3
            r.name.TextColor3 = afford and T.text1 or T.text2
        end
        rebuildUpgrades()
        for _, r in ipairs(upgradeRows) do
            if r.u then r.cost.TextColor3 = S.biscuits >= r.u.cost and T.success or T.text3 end
        end
        local gain = starsAvailable() - S.stars
        riseLbl.Text = gain > 0 and ("Rise for " .. gain .. " stars") or
            ("Rise at " .. fmt(1e9) .. " baked  -  " .. fmt(S.run))
        riseLbl.TextColor3 = gain > 0 and T.text1 or T.text3
        statsLabel.Text = string.format(
            "Baked this run: %s\nBaked all time: %s\nClicks: %s\nPer click: %s\nLucky cookies caught: %d\nStars: %d (+%d%% baking)",
            fmt(S.run), fmt(S.total), fmt(S.clicks), fmt(clickValue()), S.lucky, S.stars, S.stars * 2)
        for i, a in ipairs(ACHIEVEMENTS) do
            if not S.ach[a[1]] and a[3](S) then
                S.ach[a[1]] = true
                queueNotification("Achievement", a[1] .. ": " .. a[2], 4, "success")
            end
            achLabels[i].Text = (S.ach[a[1]] and "Done   " or "Locked   ") .. a[1] .. "  -  " .. a[2]
            achLabels[i].TextColor3 = S.ach[a[1]] and T.text1 or T.text3
        end
        if lucky.Visible and os.clock() > luckyHideAt then lucky.Visible = false end
        if not lucky.Visible and os.clock() > nextLucky then
            nextLucky = os.clock() + math.random(70, 140)
            luckyHideAt = os.clock() + 12
            lucky.Position = UDim2.new(math.random(10, 90) / 100, 0, math.random(25, 85) / 100, 0)
            lucky.Visible = true
        end
    end)

    showTab("Buildings")
    openWindow()
end

local teleportToolInstance = nil
local function updateTeleportToolState(state)
    local holders = { LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer.Character }
    for _, h in ipairs(holders) do
        if h then
            for _, t in ipairs(h:GetChildren()) do
                if t:IsA("Tool") and t.Name == "Teleport Tool" then
                    t:Destroy()
                end
            end
        end
    end
    teleportToolInstance = nil
    if state then
        local targetParent = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer.Character
        if not targetParent then
            targetParent = LocalPlayer:WaitForChild("Backpack", 3) or LocalPlayer.Character
        end
        local t = Instance.new("Tool")
        t.Name = "Teleport Tool"
        t.ToolTip = "Click anywhere to teleport"
        t.RequiresHandle = false
        t.CanBeDropped = false
        t.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            local hit = mouse and mouse.Hit
            if root and hit then
                root.CFrame = CFrame.new(hit.X, hit.Y + 3, hit.Z, select(4, root.CFrame:components()))
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Velocity = Vector3.new(0, 0, 0)
                        part.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)
        t.Parent = targetParent
        teleportToolInstance = t
    end
end

	onyxCommands = {
		{
			name = "animcopy",
			aliases = {},
			desc = "Open the Animation Copier tool",
			callback = function()
				if _G.SlateRunAnimCopier then
					task.spawn(_G.SlateRunAnimCopier)
				else
					queueNotification("Anim Copier", "Anim Copier is loading...")
				end
			end,
		},
		{
			name = "rootview",
			aliases = {},
			desc = "Show where every player's root part is, including yours",
			callback = function()
				local st = _G.__SlateRootView
				if st and st.on then
					st.on = false
					if st.conn then st.conn:Disconnect() end
					for _, tag in pairs(st.tags) do pcall(function() tag:Destroy() end) end
					st.tags = {}
					queueNotification("Root view", "Off.", 3, "info")
					return
				end
				st = { on = true, tags = {} }
				_G.__SlateRootView = st
				queueNotification("Root view", "On. Red means the root is far from the body.", 4, "info")

				local function build(plr, hrp)
					LPS_ATTRIBUTES(VM(NONE))
					local tag = Instance.new("BillboardGui")
					tag.Name = "SlateRootView"
					tag.Adornee = hrp
					tag.AlwaysOnTop = true
					tag.Size = UDim2.fromOffset(230, 70)
					tag.MaxDistance = math.huge

					local scale = Instance.new("UIScale")
					scale.Name = "S"
					scale.Parent = tag

					local card = Instance.new("Frame")
					card.Name = "Card"
					card.AnchorPoint = Vector2.new(0.5, 0)
					card.Position = UDim2.fromScale(0.5, 0)
					card.Size = UDim2.new(0, 0, 0, 46)
					card.AutomaticSize = Enum.AutomaticSize.X
					card.BackgroundColor3 = T.bg
					card.BackgroundTransparency = 0.04
					card.BorderSizePixel = 0
					card.ZIndex = 3
					card.Parent = tag
					Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
					local cs = Instance.new("UIStroke")
					cs.Name = "Stroke"
					cs.Color = T.lineHi
					cs.Transparency = 0.5
					cs.Parent = card
					local cpad = Instance.new("UIPadding")
					cpad.PaddingLeft = UDim.new(0, 8)
					cpad.PaddingRight = UDim.new(0, 16)
					cpad.Parent = card
					local layout = Instance.new("UIListLayout")
					layout.FillDirection = Enum.FillDirection.Horizontal
					layout.VerticalAlignment = Enum.VerticalAlignment.Center
					layout.SortOrder = Enum.SortOrder.LayoutOrder
					layout.Padding = UDim.new(0, 10)
					layout.Parent = card

					local notch = Instance.new("Frame")
					notch.AnchorPoint = Vector2.new(0.5, 0.5)
					notch.Position = UDim2.new(0.5, 0, 0, 46)
					notch.Size = UDim2.fromOffset(11, 11)
					notch.Rotation = 45
					notch.BackgroundColor3 = T.bg
					notch.BackgroundTransparency = 0.04
					notch.BorderSizePixel = 0
					notch.ZIndex = 2
					notch.Parent = tag
					local ns = Instance.new("UIStroke")
					ns.Color = T.lineHi
					ns.Transparency = 0.5
					ns.Parent = notch

					local av = Instance.new("ImageLabel")
					av.Size = UDim2.fromOffset(32, 32)
					av.BackgroundColor3 = T.surface3
					av.BorderSizePixel = 0
					av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=150&h=150"
					av.LayoutOrder = 1
					av.ZIndex = 4
					av.Parent = card
					Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

					local col = Instance.new("Frame")
					col.BackgroundTransparency = 1
					col.AutomaticSize = Enum.AutomaticSize.X
					col.Size = UDim2.new(0, 0, 0, 32)
					col.LayoutOrder = 2
					col.ZIndex = 4
					col.Parent = card
					local cl = Instance.new("UIListLayout")
					cl.FillDirection = Enum.FillDirection.Vertical
					cl.VerticalAlignment = Enum.VerticalAlignment.Center
					cl.Padding = UDim.new(0, 1)
					cl.Parent = col

					local nameLbl = Instance.new("TextLabel")
					nameLbl.Name = "Name"
					nameLbl.BackgroundTransparency = 1
					nameLbl.AutomaticSize = Enum.AutomaticSize.X
					nameLbl.Size = UDim2.new(0, 0, 0, 17)
					nameLbl.Font = Enum.Font.BuilderSansBold
					nameLbl.TextSize = 14
					nameLbl.TextColor3 = T.text1
					nameLbl.TextXAlignment = Enum.TextXAlignment.Left
					nameLbl.Text = plr == LocalPlayer and (plr.DisplayName .. "  (you)") or plr.DisplayName
					nameLbl.ZIndex = 4
					nameLbl.Parent = col

					local info = Instance.new("TextLabel")
					info.Name = "Info"
					info.BackgroundTransparency = 1
					info.AutomaticSize = Enum.AutomaticSize.X
					info.Size = UDim2.new(0, 0, 0, 13)
					info.Font = Enum.Font.BuilderSansMedium
					info.TextSize = 11
					info.TextColor3 = T.text3
					info.TextXAlignment = Enum.TextXAlignment.Left
					info.Text = "root --"
					info.ZIndex = 4
					info.Parent = col

					tag.Parent = hrp
					return tag
				end

				local acc = 0
				st.conn = RunService.Heartbeat:Connect(function(dt)
					LPS_ATTRIBUTES(VM(NONE))
					local ownTag = st.tags[LocalPlayer]
					if ownTag and ownTag.Parent then
						ownTag.StudsOffsetWorldSpace = _G._SlateOwnRootOffset or Vector3.zero
					end
					acc = acc + dt
					if acc < 0.1 then return end
					acc = 0
					local seen = {}
					local cam = workspace.CurrentCamera
					for _, plr in ipairs(Players:GetPlayers()) do
						local char = plr.Character
						local isSelf = plr == LocalPlayer
						if isSelf then
							local api = _G.onyxAPI
							if api and api.is_reanimated and api.is_reanimated() and api.get_real_character then
								char = api.get_real_character(LocalPlayer) or char
							end
						end
						local hrp = char and char:FindFirstChild("HumanoidRootPart")
						local body = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head"))
						if hrp and body then
							seen[plr] = true
							local tag = st.tags[plr]
							if not tag or not tag.Parent or tag.Adornee ~= hrp then
								if tag then pcall(function() tag:Destroy() end) end
								tag = build(plr, hrp)
								st.tags[plr] = tag
							end
							local up
							if isSelf and _G._SlateOwnRootLift then
								up = _G._SlateOwnRootLift
							else
								up = hrp.Position.Y - body.Position.Y
							end
							local far = math.abs(up) > 4
							local card = tag:FindFirstChild("Card")
							local info = tag:FindFirstChild("Info", true)
							if info then
								info.Text = "root " .. (up >= 0 and "+" or "") .. string.format("%.1f", up) .. " studs"
								info.TextColor3 = far and Color3.fromRGB(255, 110, 110) or T.text3
							end
							if card then
								local stroke = card:FindFirstChild("Stroke")
								if stroke then stroke.Color = far and Color3.fromRGB(255, 110, 110) or T.lineHi end
							end
							local sc = tag:FindFirstChild("S")
							if sc and cam then
								local d = (hrp.Position - cam.CFrame.Position).Magnitude
								local target = math.clamp(1 - (d - 50) / 450 * 0.45, 0.55, 1)
								sc.Scale = sc.Scale + (target - sc.Scale) * 0.4
							end
						end
					end
					for plr, tag in pairs(st.tags) do
						if not seen[plr] then
							pcall(function() tag:Destroy() end)
							st.tags[plr] = nil
						end
					end
				end)
			end,
		},
		{
			name = "slatechat",
			aliases = { "gc", "globalchat", "chatui" },
			desc = "Open the Slate global chat",
			callback = function()
				if _G.SlateToggleChat then
					_G.SlateToggleChat()
				else
					queueNotification("Slate Chat", "Chat is still loading.")
				end
			end,
		},
		{
			name = "espmenu",
			aliases = { "espgui", "esppanel", "espsettings" },
			desc = "Open the ESP menu",
			callback = function()
				if SlateEspMenu and SlateEspMenu.toggle then
					SlateEspMenu.toggle()
				elseif _G.SlateToggleEspMenu then
					_G.SlateToggleEspMenu()
				end
			end,
		},
		{
			name = "reanim",
			aliases = {},
			desc = "Open the Reanimation controls",
			callback = function()
				if _G.SlateOpenReanimMenu then _G.SlateOpenReanimMenu() end
			end,
		},
		{
			name = "emotes",
			aliases = {},
			desc = "Open UGC Emotes & Animations GUI",
			callback = function()
				if _G.ToggleSlateEmoteMenu then
					_G.ToggleSlateEmoteMenu()
				end
			end,
		},
		{
			name = "spectate",
			aliases = { "spec" },
			desc = "Open the Spectate player list",
			callback = function()
				if _G.SlateToggleSpectatePanel then _G.SlateToggleSpectatePanel() end
			end,
		},
		{
			name = "antivcbypass",
			aliases = { "antivc" },
			desc = "Bypasses the Roblox voice chat mute state",
			callback = function()
				if _G.SlateToggleAntiVCPanel then _G.SlateToggleAntiVCPanel() end
			end,
		},
		{
			name = "tp",
			desc = "Teleport to a player",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					TeleportTO(target)
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "hide",
			aliases = { "mutehide", "ghostplayer", "hideplayer" },
			desc = "Hide a player, mute their VC and hide their chat bubbles",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					hidePlayer(target)
				else
					queueNotification("Error", "Player not found: " .. tostring(arg))
				end
			end,
		},
		{
			name = "unhide",
			aliases = { "unmutehide", "unghostplayer", "unhideplayer" },
			desc = "Unhide a player, unmute their VC and restore visibility",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					unhidePlayer(target)
				else
					queueNotification("Error", "Player not found: " .. tostring(arg))
				end
			end,
		},
		{
			name = "view",
			desc = "Spectate a player's camera view",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target and target.Character and target.Character:FindFirstChild("Humanoid") then
					camera.CameraSubject = target.Character.Humanoid
					queueNotification("Viewing", "Spectating " .. target.DisplayName)
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "unview",
			desc = "Reset camera back to self",
			callback = function()
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					camera.CameraSubject = hum
					queueNotification("Camera reset", "Reset view to self")
				end
			end,
		},
		{
			name = "speed",
			desc = "Set local player WalkSpeed",
			args = "<value>",
			callback = function(arg)
				local speed = tonumber(arg)
				if speed then
					local char = localPlayer.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.WalkSpeed = speed
						queueNotification("Speed", "WalkSpeed set to " .. speed)
					end
				end
			end,
		},
		{
			name = "jumppower",
			desc = "Set local player JumpPower",
			args = "<value>",
			callback = function(arg)
				local jp = tonumber(arg)
				if jp then
					local char = localPlayer.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.UseJumpPower = true
						hum.JumpPower = jp
						queueNotification("JumpPower", "JumpPower set to " .. jp)
					end
				end
			end,
		},
		{
			name = "gravity",
			desc = "Set workspace gravity",
			args = "<value>",
			callback = function(arg)
				local grav = tonumber(arg)
				if grav then
					workspace.Gravity = grav
					queueNotification("Gravity", "Gravity set to " .. grav)
				end
			end,
		},
		{
			name = "re",
			desc = "Reset and respawn at exact current CFrame",
			callback = function()
				local char = localPlayer.Character
				if onyxAPI and onyxAPI.is_reanimated and onyxAPI.is_reanimated() then
					char = onyxAPI.get_real_character(localPlayer) or char
				end
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if not hrp then
					return
				end
				local savedCF = hrp.CFrame
				pcall(function()
					local hum = char:FindFirstChildWhichIsA("Humanoid")
					if hum then
						hum:ChangeState(Enum.HumanoidStateType.Dead)
					end
					char:BreakJoints()
				end)
				localPlayer.CharacterAdded:Wait()
				task.wait(0.3)
				local newHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
				if newHrp then
					newHrp.CFrame = savedCF
					queueNotification("Respawned", "Respawned at location")
				end
			end,
		},
		{
			name = "respawn",
			desc = "Respawn your character",
			callback = function()
				local char = localPlayer.Character
				if onyxAPI and onyxAPI.is_reanimated and onyxAPI.is_reanimated() then
					char = onyxAPI.get_real_character(localPlayer) or char
				end
				if char then
					pcall(function()
						local hum = char:FindFirstChildWhichIsA("Humanoid")
						if hum then
							hum:ChangeState(Enum.HumanoidStateType.Dead)
						end
						char:BreakJoints()
					end)
				end
			end,
		},
		{
			name = "rejoin",
			desc = "Rejoin the current server",
			callback = function()
				if rejoin then
					rejoin()
				else
					queueNotification("Rejoin unavailable", "Teleport service is not ready")
				end
			end,
		},
		{
			name = "noclip",
			desc = "Toggle walking through walls",
			isToggle = true,
			getState = function()
				return _walkWallEnabled == false and _noclipConn ~= nil
			end,
			callback = function(state)
				if state then
					_startNoclip()
				else
					_stopNoclip()
				end
			end,
		},
		{
			name = "fly",
			desc = "Toggle flying controls",
			isToggle = true,
			getState = function()
				return siriusValues.actions[2].enabled
			end,
			callback = function(state)
				siriusValues.actions[2].enabled = state
				siriusValues.actions[2].callback(state)
			end,
		},
		{
			name = "baseplate",
			desc = "Toggle Infinite Baseplate (Grid / Invisible / Off)",
			autoexecable = true,
			callback = function()
				toggleInfiniteBaseplate()
			end,
		},
		{
			name = "clicker",
			aliases = { "cookieclicker", "biscuits" },
			desc = "Play a cookie clicker game",
			autoexecable = false,
			callback = function()
				if _G.SlateRunClicker then
					task.spawn(_G.SlateRunClicker)
				else
					queueNotification("Clicker", "The game is still loading.")
				end
			end,
		},
		{
			name = "shaders2",
			aliases = {},
			desc = "Open the Shaders 2 window (lighting looks, adjustments, skyboxes)",
			autoexecable = false,
			callback = function()
				if _G.SlateRunShaders then
					task.spawn(_G.SlateRunShaders)
				else
					queueNotification("Shaders", "Shaders is still loading.")
				end
			end,
		},
		{
			name = "baseplate2",
			desc = "Load the Onyx infinite baseplate script",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/onyxbaseplate.lua")))()
			end,
		},
		{
			name = "resolution",
			desc = "Load and execute resolution changer script",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/resolution.lua")))()
			end,
		},
		{
			name = "transparency",
			desc = "Make yourself transparent locally",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/reanimtrasparent.lua")))()
			end,
		},
		{
			name = "micupbot",
			desc = "Bring Mic Up Bots to main area",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/micupbot.lua")))()
			end,
		},
		{
			name = "shaders",
			desc = "Load and execute visual shaders",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/shaders.lua")))()
			end,
		},
		{
			name = "internalexecutor",
			desc = "In game way to execute and download code",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/internalexecutor.lua")))()
			end,
		},
		{
			name = "UntitledDriftGameAFK",
			desc = "Keeps the Untitled Drift Game AFK state enabled while active",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/zvzt/UntitledDriftGameAFK/refs/heads/main/AFK.lua"))()
			end,
		},
		{
			name = "PositionSaver",
			desc = "Save you current position coordinates",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/zvzt/positionsaver.lua/refs/heads/main/posrecorder.lua"))()
			end,
		},
		{
			name = "Snake",
			desc = "Cursor effect that creates a configurable trailing snake following your mouse",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/zvzt/snake.lua/refs/heads/main/snake.lua"))()
			end,
		},
		{
			name = "R6Anims",
			desc = "Load and execute R6 animations",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/zvzt/R6Anims.lua/refs/heads/main/r6anims.lua"))()
			end,
		},
		{
			name = "Gamble",
			desc = "gamble in roblox",
			autoexecable = true,
			callback = function()
				loadstring(game:HttpGet("https://sl8ght.xyz/gambe.lua"))()
			end,
		},
		{
			name = "clicktp",
			desc = "Toggle press F to teleport to cursor",
			aliases = { "ftp" },
			isToggle = true,
			getState = function()
				return _G.ClickTeleportEnabled
			end,
			callback = function(state)
				_G.ClickTeleportEnabled = state
				queueNotification("Click teleport", state and "Enabled - press F to teleport" or "Disabled")
			end,
		},
		{
			name = "tptool",
			desc = "Toggle Teleport Tool",
			isToggle = true,
			getState = function()
				return _G.TeleportToolEnabled
			end,
			callback = function(state)
				_G.TeleportToolEnabled = state
				updateTeleportToolState(state)
				queueNotification("Teleport Tool", state and "Tool added to backpack" or "Tool removed")
			end,
		},
		{
			name = "walkonair",
			desc = "Toggle float in place platform",
			isToggle = true,
			getState = function()
				return Slate.WalkOnAirEnabled == true
			end,
			callback = function(state)
				Slate.WalkOnAirEnabled = state
				if state then
					local char = localPlayer.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					local baseY = hrp and hrp.Position.Y or 0
					if _G.woaPlatform then
						pcall(function()
							_G.woaPlatform:Destroy()
						end)
					end
					local p = Instance.new("Part")
					p.Name = "OnyxWOAPlatform"
					p.Size = Vector3.new(16, 0.2, 16)
					p.Transparency = 1
					p.Anchored = true
					p.CanCollide = true
					p.CanQuery = false
					p.CastShadow = false
					p.Parent = workspace
					_G.woaPlatform = p
					task.spawn(function()
						LPS_ATTRIBUTES(VM(NONE))
						while Slate.WalkOnAirEnabled do
							local c = localPlayer.Character
							local h = c and c:FindFirstChild("HumanoidRootPart")
							if h then
								local targetY = baseY
								p.CFrame = CFrame.new(h.Position.X, targetY - 3.1, h.Position.Z)
								if h.Position.Y < targetY - 0.5 then
									h.CFrame = CFrame.new(h.Position.X, targetY, h.Position.Z)
										* CFrame.Angles(0, select(2, h.CFrame:ToEulerAnglesYXZ()), 0)
									h.AssemblyLinearVelocity =
										Vector3.new(h.AssemblyLinearVelocity.X, 0, h.AssemblyLinearVelocity.Z)
								end
							end
							task.wait()
						end
						pcall(function()
							p:Destroy()
						end)
						_G.woaPlatform = nil
					end)
					queueNotification("Walk on air", "Enabled")
				else
					if _G.woaPlatform then
						pcall(function()
							_G.woaPlatform:Destroy()
						end)
						_G.woaPlatform = nil
					end
					queueNotification("Walk on air", "Disabled")
				end
			end,
		},
		{
			name = "walkwall",
			desc = "Stick to and walk on any wall surface",
			isToggle = true,
			getState = function()
				return _walkWallEnabled
			end,
			callback = function(state)
				_walkWallEnabled = state
				if state then
					_startWalkWall()
				else
					_stopWalkWall()
				end
				queueNotification("Walk on wall", state and "Enabled" or "Disabled")
			end,
		},
		{
			name = "zerograv",
			desc = "Toggle zero gravity",
			isToggle = true,
			getState = function()
				return workspace.Gravity == 0
			end,
			callback = function(state)
				workspace.Gravity = state and 0 or 196.2
				queueNotification("Gravity", state and "Disabled" or "Restored")
			end,
		},
		{
			name = "infzoom",
			aliases = { "infinitezoom", "infzoomout", "maxzoomout" },
			desc = "Scroll out beyond the normal zoom limit",
			isToggle = true,
			getState = function()
				return _infZoomEnabled
			end,
			callback = function(state)
				_infZoomEnabled = state
				if state then
					localPlayer.CameraMaxZoomDistance = 9e9
					localPlayer.CameraMinZoomDistance = 0.5
				else
					localPlayer.CameraMaxZoomDistance = 128
					localPlayer.CameraMinZoomDistance = 0.5
				end
				queueNotification("Infinite zoom", state and "Enabled" or "Disabled")
			end,
		},
		{
			name = "facebang",
			desc = "Open Facebang Controls panel",
			callback = function()
				FacebangWindow.Visible = not FacebangWindow.Visible
			end,
		},
		{
			name = "headsit",
			desc = "Sit on a player's head",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					StartZeroDelay(target, "headsit")
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "doggy",
			desc = "Attach behind a player",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					StartZeroDelay(target, "doggy")
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "backpack",
			desc = "Ride a player's back",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					StartZeroDelay(target, "backpack")
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "stand",
			desc = "Stand on a player",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					StartZeroDelay(target, "stand")
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "drag",
			desc = "Drag a player around",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					StartZeroDelay(target, "drag")
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "untarget",
			desc = "Stop all Zero Delay attachments",
			callback = function()
				StopZeroDelay()
			end,
		},
		{
			name = "btools",
			desc = "Give building tools (F3X / Hopper)",
			callback = function()
				pcall(function()
					local f3x = game:GetObjects("rbxassetid://142273772")[1]
					if f3x then
						f3x.Parent = localPlayer:FindFirstChildOfClass("Backpack") or localPlayer.Character
						queueNotification("Btools", "Gave F3X building tools")
					else
						local tool1 = Instance.new("HopperBin")
						tool1.BinType = Enum.BinType.Clone
						tool1.Parent = localPlayer:FindFirstChildOfClass("Backpack")
						local tool2 = Instance.new("HopperBin")
						tool2.BinType = Enum.BinType.Hammer
						tool2.Parent = localPlayer:FindFirstChildOfClass("Backpack")
						local tool3 = Instance.new("HopperBin")
						tool3.BinType = Enum.BinType.GameTool
						tool3.Parent = localPlayer:FindFirstChildOfClass("Backpack")
						queueNotification("Btools", "Gave classic hopper tools")
					end
				end)
			end,
		},
		{
			name = "flyspeed",
			desc = "Set flying movement speed",
			args = "<value>",
			callback = function(arg)
				local speed = tonumber(arg)
				if speed then
					for _, s in ipairs(siriusValues.sliders) do
						if s.name == "Flight Speed" then
							s.value = speed
							local sobj = sliderObjects["Flight Speed"]
							if sobj then
								local percent = math.clamp((speed - s.values[1]) / (s.values[2] - s.values[1]), 0, 1)
								sobj.fill.Size = UDim2.new(percent, 0, 1, 0)
								sobj.lbl.Text = s.name .. " (" .. tostring(speed) .. ")"
							end
						end
					end
					queueNotification("Fly speed", "Flying speed set to " .. speed)
				end
			end,
		},
		{
			name = "infjump",
			desc = "Toggle jumping in mid-air",
			isToggle = true,
			getState = function()
				return _infJumpConn ~= nil
			end,
			callback = function(state)
				if _infJumpConn then
					_infJumpConn:Disconnect()
					_infJumpConn = nil
				end
				if state then
					_infJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
						local char = localPlayer.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hum then
							hum:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					end)
					queueNotification("Infinite jump", "Enabled")
				else
					queueNotification("Infinite jump", "Disabled")
				end
			end,
		},
		{
			name = "goto",
			desc = "Teleport to a player",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					TeleportTO(target)
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "bring",
			desc = "Bring a player to you (using zero delay)",
			args = "<player>",
			callback = function(arg)
				local target = GetPlayer(arg)
				if target then
					StartZeroDelay(target, "drag")
				else
					queueNotification("Error", "Player not found")
				end
			end,
		},
		{
			name = "god",
			desc = "Toggle local character invulnerability",
			isToggle = true,
			getState = function()
				return Slate.OnyxGodModeEnabled == true
			end,
			callback = function(state)
				Slate.OnyxGodModeEnabled = state
				if state then
					task.spawn(function()
						LPS_ATTRIBUTES(VM(NONE))
						while Slate.OnyxGodModeEnabled do
							local char = localPlayer.Character
							local hum = char and char:FindFirstChildOfClass("Humanoid")
							if hum then
								hum.MaxHealth = math.huge
								hum.Health = math.huge
							end
							task.wait(0.1)
						end
					end)
					queueNotification("Godmode", "Enabled")
				else
					local char = localPlayer.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.MaxHealth = 100
						hum.Health = 100
					end
					queueNotification("Godmode", "Disabled")
				end
			end,
		},
		{
			name = "clearhats",
			desc = "Remove all hats and accessories",
			aliases = { "cleanhats" },
			callback = function()
				if not firetouchinterest then
					queueNotification("Incompatible exploit", "Your executor does not support firetouchinterest", 4, "warning")
					return
				end
				local lp = Players.LocalPlayer
				local char = lp.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root = char and (char:FindFirstChild("HumanoidRootPart") or (hum and hum.RootPart))
				if not (char and hum and root) then
					queueNotification("Clear hats", "Character not ready", 3, "warning")
					return
				end
				if _G.__SlateClearingHats then return end
				_G.__SlateClearingHats = true
				task.spawn(function()
					local ok, err = pcall(function()
						local old = root.CFrame
						local hats = {}
						for _, child in ipairs(workspace:GetChildren()) do
							if child:IsA("Accessory") and child:FindFirstChild("Handle") then hats[#hats + 1] = child end
						end
						for _, accessory in ipairs(hum:GetAccessories()) do accessory:Destroy() end
						for i = 1, #hats do
							local hat = hats[i]
							if hat and hat.Parent and hat:FindFirstChild("Handle") then
								firetouchinterest(hat.Handle, root, 0)
								local waited = 0
								while not char:FindFirstChildOfClass("Accessory") and waited < 2 do
									waited += RunService.Heartbeat:Wait()
								end
								local worn = char:FindFirstChildOfClass("Accessory")
								if worn then worn:Destroy() end
								RunService.Heartbeat:Wait()
							end
						end
						-- respawn so the server drops the accessories, then put the player back where they were
						hum.Health = 0
						local newChar = lp.CharacterAdded:Wait()
						local newRoot = newChar:WaitForChild("HumanoidRootPart", 10)
						for _ = 1, 20 do
							RunService.Heartbeat:Wait()
							if newRoot and newRoot.Parent then newRoot.CFrame = old end
						end
					end)
					_G.__SlateClearingHats = false
					if not ok then queueNotification("Clear hats failed", tostring(err):sub(1, 100), 5, "error") end
				end)
			end,
		},
		{
			name = "bang",
			aliases = { "rape" },
			desc = "Bang a player <player> [speed]",
			args = "<player> [speed]",
			callback = function(arg)
				local lp = Players.LocalPlayer
				local parts = {}
				for w in tostring(arg or ""):gmatch("%S+") do parts[#parts + 1] = w end
				local target = parts[1] and GetPlayer(parts[1])
				if not target then
					queueNotification("Bang", "Player not found", 3, "warning")
					return
				end
				local char = lp.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root = char and (char:FindFirstChild("HumanoidRootPart") or (hum and hum.RootPart))
				if not (char and hum and root) then return end
				if _G.__SlateBangStop then pcall(_G.__SlateBangStop) end
				local r15 = hum.RigType == Enum.HumanoidRigType.R15
				local anim = Instance.new("Animation")
				anim.AnimationId = r15 and "rbxassetid://5918726674" or "rbxassetid://148840371"
				local animator = hum:FindFirstChildOfClass("Animator") or hum
				local track = animator:LoadAnimation(anim)
				track:Play(0.1, 1, 1)
				track:AdjustSpeed(tonumber(parts[2]) or 3)
				local offset = CFrame.new(0, 0, 1.1)
				local conns = {}
				local function stop()
					_G.__SlateBangStop = nil
					for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
					pcall(function() track:Stop() end)
					pcall(function() anim:Destroy() end)
				end
				_G.__SlateBangStop = stop
				conns[#conns + 1] = hum.Died:Connect(stop)
				conns[#conns + 1] = RunService.Stepped:Connect(function()
					LPS_ATTRIBUTES(VM(NONE))
					local tc = target.Character
					local tr = tc and (tc:FindFirstChild("HumanoidRootPart") or tc:FindFirstChild("Torso") or tc:FindFirstChild("UpperTorso"))
					local mr = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
					if tr and mr then mr.CFrame = tr.CFrame * offset end
				end)
				queueNotification("Bang", "Started on " .. target.DisplayName, 3)
			end,
		},
		{
			name = "unbang",
			aliases = { "unrape" },
			desc = "Stop banging",
			callback = function()
				if _G.__SlateBangStop then pcall(_G.__SlateBangStop) end
			end,
		},
		{
			name = "muteall",
			desc = "Mute all players except friends in voice and text chat",
			aliases = { "muteothers", "friendsonly" },
			callback = function()
				if not _G._slateVCI then
					local ok, svc = pcall(function()
						return game:GetService("VoiceChatInternal")
					end)
					_G._slateVCI = ok and svc or false
				end
				if not _G._slateMuteProps then
					_G._slateMuteProps = Instance.new("TextChatMessageProperties")
					_G._slateMuteProps.Text = ""
				end
				Slate._slateMutedUserIds = {}
				_G._slateAutoMuteActive = true
				local function _slateIsFriend(player)
					if player == localPlayer then
						return true
					end
					local ok, result = pcall(function()
						return player:IsFriendsWith(localPlayer.UserId)
					end)
					return ok and result
				end
				_G._slateIsFriend = _slateIsFriend
				local function _slateMuteOne(p)
					if p == localPlayer then
						return
					end
					if _G._slateIsFriend(p) then
						return
					end
					Slate._slateMutedUserIds[p.UserId] = true
					if _G._slateVCI then
						pcall(function()
							_G._slateVCI:SubscribePause(p.UserId, true)
						end)
					end
				end
				local mutedCount = 0
				for _, p in ipairs(players:GetPlayers()) do
					if p ~= localPlayer and not _slateIsFriend(p) then
						_slateMuteOne(p)
						mutedCount = mutedCount + 1
					end
				end
				if not isLegacyChat and not _G._slateMuteTextHooked then
					local okPrev, prevCb = pcall(function()
						if type(getcallbackvalue) == "function" then
							return getcallbackvalue(TextChatService, "OnIncomingMessage")
						end
					end)
					_G._slateMuteTextPrev = okPrev and type(prevCb) == "function" and prevCb or nil
					_G._slateMuteTextHooked = true
					TextChatService.OnIncomingMessage = function(msg)
						local okSrc, src = pcall(function() return msg.TextSource end)
						if not okSrc then src = nil end
						if src and Slate._slateMutedUserIds and Slate._slateMutedUserIds[src.UserId] then
							return _G._slateMuteProps
						end
						if _G._slateMuteTextPrev then
							return _G._slateMuteTextPrev(msg)
						end
					end
				end
				if _G._slateAutoMuteConn then
					pcall(function()
						_G._slateAutoMuteConn:Disconnect()
					end)
					_G._slateAutoMuteConn = nil
				end
				_G._slateAutoMuteConn = players.PlayerAdded:Connect(function(p)
					if not _G._slateAutoMuteActive then
						return
					end
					task.wait(1.5)
					if not _G._slateAutoMuteActive then
						return
					end
					if not _G._slateIsFriend(p) then
						Slate._slateMutedUserIds[p.UserId] = true
						if _G._slateVCI then
							pcall(function()
								_G._slateVCI:SubscribePause(p.UserId, true)
							end)
						end
					end
				end)
				queueNotification("Mute all", "Muted " .. mutedCount .. " player(s). friends exempt.")
			end,
		},
		{
			name = "unmuteall",
			desc = "Unmute all players muted by muteall",
			aliases = { "unmutall", "unfriendonly" },
			callback = function()
				_G._slateAutoMuteActive = false
				if _G._slateAutoMuteConn then
					pcall(function()
						_G._slateAutoMuteConn:Disconnect()
					end)
					_G._slateAutoMuteConn = nil
				end
				if not isLegacyChat and _G._slateMuteTextHooked then
					pcall(function() TextChatService.OnIncomingMessage = _G._slateMuteTextPrev end)
					_G._slateMuteTextPrev = nil
					_G._slateMuteTextHooked = false
				end
				if _G._slateVCI == nil then
					local okV, svcV = pcall(function() return game:GetService("VoiceChatInternal") end)
					_G._slateVCI = okV and svcV or false
				end
				local unmutedCount = 0
				if _G._slateVCI then
					pcall(function()
						_G._slateVCI:SubscribePauseAll(false)
					end)
				end
				for _, p in ipairs(players:GetPlayers()) do
					if not (p == localPlayer) then
					if _G._slateVCI then
						pcall(function()
							_G._slateVCI:SubscribePause(p.UserId, false)
						end)
					end
					unmutedCount = unmutedCount + 1
					end
				end
				Slate._slateMutedUserIds = {}
				queueNotification("Unmute all", "Unmuted " .. unmutedCount .. " player(s).")
			end,
		},
	}
	onyxAliases = {
		teleport = "tp",
		spectate = "view",
		rj = "rejoin",
		ws = "speed",
		jp = "jumppower",
		grav = "gravity",
		unheadsit = "untarget",
		undoggy = "untarget",
		unbackpack = "untarget",
		unstand = "untarget",
		undrag = "untarget",
		antivc = "antivcbypass",
	}
	_SE.onyxCommands = onyxCommands
	_SE.onyxAliases = onyxAliases
	_G.onyxCommands = onyxCommands
	_G.onyxAliases = onyxAliases
	if getgenv then
		pcall(function()
			local g = getgenv()
			g.onyxCommands = onyxCommands
			g.onyxAliases = onyxAliases
		end)
	end
	D.iyCommands()
	_SE.SlateBinds = SlateBinds
	_SE.onyxCommands = onyxCommands
	_SE.onyxAliases = onyxAliases
	_G.SlateBinds = SlateBinds
	_G.onyxCommands = onyxCommands
	_G.onyxAliases = onyxAliases
	if getgenv then
		pcall(function()
			local g = getgenv()
			g.SlateBinds = SlateBinds
			g.onyxCommands = onyxCommands
			g.onyxAliases = onyxAliases
		end)
	end
	print(string.format("cmnds loaded in %.4fs", os.clock() - _cmdLoadStart))
end

local clientModule = function(...)
	LPS_ATTRIBUTES(VM(NONE))
	local _nametagsLoadStart = os.clock()
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local localPlayer = Players.LocalPlayer

	local registerAnimator
	do
		local _slateAnimators = {}
		local _slateAnimConn = nil
		function registerAnimator(step, inst)
			_slateAnimators[step] = { inst = inst, nextCheck = 0, culled = false }
			if not _slateAnimConn then
				local acc = 0
				_slateAnimConn = RunService.Heartbeat:Connect(function(dt)
					LPS_ATTRIBUTES(VM(NONE))
					acc = acc + dt
					if acc < 1 / 30 then return end
					local stepDt = acc
					acc = 0
					local now = os.clock()
					local cam = workspace.CurrentCamera
					local camPos = cam and cam.CFrame.Position
					for fn, entry in pairs(_slateAnimators) do
						local inst = entry.inst
						if inst then
							if not inst.Parent then
								_slateAnimators[fn] = nil
								continue
							end
							if now >= entry.nextCheck then
								entry.nextCheck = now + 0.5
								local culled = false
								local bb = entry.bb
								if not bb or not bb.Parent then
									bb = inst:FindFirstAncestorWhichIsA("BillboardGui")
									entry.bb = bb
								end
								if bb then
									if not bb.Enabled then
										culled = true
									elseif camPos then
										local adornee = bb.Adornee or bb.Parent
										if adornee and adornee:IsA("BasePart") then
											culled = (adornee.Position - camPos).Magnitude > 220
										end
									end
								end
								entry.culled = culled
							end
						end
						if not entry.culled then
							local ok, keep = pcall(fn, stepDt)
							if not ok or keep == false then
								_slateAnimators[fn] = nil
							end
						end
					end
					if not next(_slateAnimators) and _slateAnimConn then
						_slateAnimConn:Disconnect()
						_slateAnimConn = nil
					end
				end)
			end
		end
	end
	while not localPlayer do
		task.wait()
		localPlayer = Players.LocalPlayer
	end
	if getgenv then
		if getgenv().SlateNametags and type(getgenv().SlateNametags.Destroy) == "function" then
			pcall(function()
				getgenv().SlateNametags:Destroy()
			end)
		end
	end
	local targetUI = (gethui and gethui()) or game:GetService("CoreGui")
	pcall(function()
		if targetUI then
			local oldUi = targetUI:FindFirstChild("SlateOwnerClient")
			if oldUi then
				oldUi:Destroy()
			end
		end
		if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
			local oldUi = localPlayer.PlayerGui:FindFirstChild("SlateOwnerClient")
			if oldUi then
				oldUi:Destroy()
			end
		end
		local cg = game:GetService("CoreGui")
		if cg then
			local oldUi = cg:FindFirstChild("SlateOwnerClient")
			if oldUi then
				oldUi:Destroy()
			end
		end
	end)
	local running = true
	local DEFAULT_RAW_CONFIG = {
		font = "GothamBold",
		isGif = false,
		bgType = "image",
		iconImage = "https://i.postimg.cc/43WF1qCT/icon.png",
		textColor = "#ffffff",
		sizePreset = "medium",
		displayName = "SLATE\u{3164}\u{3164}",
		nametagShape = "Square",
		outlineColor = "#ffffff",
		bgGradientDir = "to right",
		bgTransparency = 0,
		backgroundColor = "#000000",
		backgroundImage = "https://i.postimg.cc/tgqMWyM4/background.png",
		bgGradientStops = {
			{ pos = 0, color = "#1a1a2e" },
			{ pos = 100, color = "#16213e" },
		},
		strokeThickness = 2,
		textGradientDir = "to right",
		strokeGradientDir = "to right",
		textGradientSpeed = 3,
		textGradientStops = {
			{ pos = 0, color = "#ffffff" },
			{ pos = 50, color = "#000000" },
		},
		strokeGradientStops = {
			{ pos = 0, color = "#1a366a" },
			{ pos = 50, color = "#142d5d" },
		},
		textGradientEnabled = true,
		strokeGradientEnabled = false,
		textGradientAnimEnabled = true,
		strokeGradientAnimEnabled = false,
		glowColor = "#ffffff",
		artVersion = "muq4yo4u_yrqz",
	}
	local API_BASE = (getgenv and (getgenv().SLATE_BACKEND or getgenv().BACKEND_URL or getgenv().WORKER_BASE)) or _G.SLATE_BACKEND or _G.BACKEND_URL or _G.WORKER_BASE or LPS_ENCSTR("https://sl8ght.xyz")
	local WS_BASE = API_BASE:gsub("^http", "ws") .. "/ws"
	local CONFIG = {
		backendUrl = API_BASE,
		wsUrl = WS_BASE,
		heartbeatPoll = 45,
		minimizeDistance = 45,
		distanceCheck = 0.4,
		studsOffset = Vector3.new(0, 1.7, 0),
		tagHeight = 48,
		iconSize = 32,
		cacheRoot = "slate/client",
		defaultIcon = DEFAULT_RAW_CONFIG.iconImage,
		defaultBackground = DEFAULT_RAW_CONFIG.backgroundImage,
		headshot = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
	}

	local applyHeadshot
	do
		local _headshotUrlCache = {}
		function applyHeadshot(icon, userId)
		local uid = tonumber(userId)
		if not uid then return end
		icon.Image = string.format(CONFIG.headshot, uid)
		if _headshotUrlCache[uid] then
			applyImage(icon, _headshotUrlCache[uid], uid, 0, tostring(uid) .. "hs", nil)
			return
		end
		task.spawn(function()
			local cdnUrl = nil
			pcall(function()
				local apiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. uid .. "&size=150x150&format=Png&isCircular=false"
				local body = httpGet(apiUrl)
				if body then
					local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
					if ok and type(data) == "table" and type(data.data) == "table" and data.data[1] then
						local imgUrl = data.data[1].imageUrl
						if type(imgUrl) == "string" and imgUrl:find("^https?://") then
							cdnUrl = imgUrl
						end
					end
				end
			end)
			if cdnUrl then
				_headshotUrlCache[uid] = cdnUrl
				if icon and icon.Parent then
					applyImage(icon, cdnUrl, uid, 0, tostring(uid) .. "hs", nil)
				end
			end
		end)
		end
	end
	local PLACE_ID = tostring(game.PlaceId)
	local JOB_ID = (game.JobId ~= nil and game.JobId ~= "") and game.JobId or "unknown"
	local getcustomasset = getcustomasset or getsynasset or (syn and syn.get_custom_asset) or (getgenv and (getgenv().getcustomasset or getgenv().getsynasset))
	local writefile = writefile or (getgenv and getgenv().writefile)
	local isfile = isfile or (getgenv and getgenv().isfile)
	local isfolder = isfolder or (getgenv and getgenv().isfolder)
	local makefolder = makefolder or (getgenv and getgenv().makefolder)
	local httpRequest = request
		or http_request
		or (syn and syn.request)
		or (http and http.request)
		or (fluxus and fluxus.request)
		or (getgenv and (getgenv().request or getgenv().http_request))
	local hasFileSystem = type(writefile) == "function"
		and type(getcustomasset) == "function"
		and type(isfile) == "function"
		and type(isfolder) == "function"
		and type(makefolder) == "function"
	local wsLib = (getgenv and (getgenv().WebSocket or getgenv().websocket)) or WebSocket or websocket

	local function ensureFolder(path)
		if not hasFileSystem then
			return
		end
		local build = nil
		for segment in path:gmatch("[^/]+") do
			build = build and (build .. "/" .. segment) or segment
			if not isfolder(build) then
				pcall(makefolder, build)
			end
		end
	end

	local function decodeJson(raw)
		if type(raw) ~= "string" or raw == "" then
			return nil
		end
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(decoded) == "table" then
			return decoded
		end
		return nil
	end

	local function ensureDefaultConfig()
		if not hasFileSystem then
			return
		end
		local folder = CONFIG.cacheRoot .. "/default"
		ensureFolder(folder)
		local filePath = folder .. "/config.json"
		pcall(writefile, filePath, HttpService:JSONEncode(DEFAULT_RAW_CONFIG))
		CONFIG.defaultIcon = DEFAULT_RAW_CONFIG.iconImage
		CONFIG.defaultBackground = DEFAULT_RAW_CONFIG.backgroundImage
	end
	task.spawn(ensureDefaultConfig)

	local function findPlayer(identifier)
		if not identifier then
			return nil
		end
		local num = tonumber(identifier)
		if num then
			local p = Players:GetPlayerByUserId(num)
			if p then
				return p
			end
		end
		local s = tostring(identifier):lower()
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower() == s then
				return p
			end
		end
		return nil
	end

	local function httpGet(url)
		if type(url) ~= "string" or url == "" then
			return nil
		end
		if url:find("^http://") then
			url = "https://" .. url:sub(8)
		end
		if httpRequest then
			local ok, res = pcall(httpRequest, {
				Url = url,
				Method = "GET",
				Headers = {
					["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
					["Accept"] = "*/*",
				},
			})
			if ok and type(res) == "table" then
				local code = res.StatusCode or res.Status
				if not code or (code >= 200 and code < 300) then
					local body = res.Body or res.body
					if type(body) == "string" and body ~= "" then
						return body
					end
				end
			end
		end
		if not _SlateIsMac and type(game.HttpGet) == "function" then
			local ok, body = pcall(game.HttpGet, game, url)
			if ok and type(body) == "string" and body ~= "" then
				return body
			end
		end
		return nil
	end

	local function httpPostJson(url, body)
		if not httpRequest then
			return nil
		end
		if type(url) == "string" and url:find("^http://") then
			url = "https://" .. url:sub(8)
		end
		local ok, res = pcall(httpRequest, {
			Url = url,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(body),
		})
		if not ok or type(res) ~= "table" then
			return nil
		end
		local code = res.StatusCode or res.Status
		if code and code ~= 200 then
			return nil
		end
		return res.Body or res.body
	end

	local function hexToColor3(hex)
		if type(hex) ~= "string" then
			return nil
		end
		hex = hex:gsub("#", "")
		if #hex == 3 then
			hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
		end
		if #hex ~= 6 then
			return nil
		end
		local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
		if not (r and g and b) then
			return nil
		end
		return Color3.fromRGB(r, g, b)
	end

	local function toColor3(value, fallback)
		if typeof(value) == "Color3" then
			return value
		end
		if type(value) == "string" then
			return hexToColor3(value) or fallback
		end
		if type(value) == "table" then
			local r, g, b = value.r or value[1], value.g or value[2], value.b or value[3]
			if r and g and b then
				if r > 1 or g > 1 or b > 1 then
					return Color3.fromRGB(r, g, b)
				end
				return Color3.new(r, g, b)
			end
		end
		return fallback
	end

	local function resolveAsset(url)
		if type(url) ~= "string" or url == "" then
			return nil
		end
		local s = url:match("^%s*(.-)%s*$")
		if s:find("Slate_Halloween_Logo", 1, true) then return DEFAULT_RAW_CONFIG.iconImage end
		if s:find("Slate_Halloween_Banner", 1, true) then return DEFAULT_RAW_CONFIG.backgroundImage end
		if s:find("^http://") then
			s = "https://" .. s:sub(8)
		end
		if s:find("^rbx") then
			return s
		end
		if s:find("^https?://") and not s:find("roblox%.com") then
			return s
		end
		local id = s:match("^(%d+)$") or s:match("id=(%d+)")
		if id then
			return "rbxassetid://" .. id
		end
		return s
	end
	local assetCache = {}

	local function userFolder(ownerId, version)
		local folderName = tostring(ownerId or "default")
		if folderName == "shared" or folderName == "0" then
			folderName = "default"
		end
		local dir = CONFIG.cacheRoot .. "/" .. folderName
		ensureFolder(dir)
		return dir
	end

	local function deleteUserCache(ownerId)
		if not ownerId then
			return
		end
		local targets = {}
		local folderName = tostring(ownerId)
		targets[#targets + 1] = folderName
		local p = findPlayer(ownerId)
		if p then
			targets[#targets + 1] = tostring(p.UserId)
			targets[#targets + 1] = p.Name:lower()
			targets[#targets + 1] = p.Name
		end
		for _, name in ipairs(targets) do
			if name ~= "" and name ~= "default" and name ~= "shared" and name ~= "0" then
				for k in pairs(assetCache) do
					if k:sub(1, #name + 1) == name .. "/" then
						assetCache[k] = nil
					end
				end
			end
		end
	end

	local function getUrlHash(urlStr)
		if type(urlStr) ~= "string" or urlStr == "" then
			return tostring(string.format("%x", os.time())):sub(-6)
		end
		local hash = 5381
		for i = 1, #urlStr do
			hash = (hash * 33 + string.byte(urlStr, i)) % 4294967296
		end
		return string.format("%x", hash)
	end

	local function looksLikeHtml(body)
		local head = body:sub(1, 32):lower()
		return head:find("<html", 1, true) ~= nil or head:find("<!doctype", 1, true) ~= nil
	end

	local function writeAsset(ownerId, version, key, bytes)
		if not hasFileSystem then
			return nil
		end
		local ext = ".png"
		if type(bytes) == "string" and #bytes >= 4 then
			if bytes:sub(1, 3) == "GIF" then
				ext = ".gif"
			elseif bytes:sub(1, 2) == "\255\216" then
				ext = ".jpg"
			elseif bytes:sub(1, 4) == "RIFF" and #bytes >= 12 and bytes:sub(9, 12) == "WEBP" then
				ext = ".webp"
			end
		end
		local path = userFolder(ownerId, version) .. "/" .. key .. ext
		local asset = nil
		pcall(function()
			writefile(path, bytes)
			asset = getcustomasset(path)
		end)
		if asset and asset ~= "" then
			assetCache[tostring(ownerId or "default") .. "/" .. key] = asset
			return asset
		end
		return nil
	end

	local function readAsset(ownerId, version, key)
		if not hasFileSystem then
			return nil
		end
		local memo = assetCache[tostring(ownerId or "default") .. "/" .. key]
		if memo then
			return memo
		end
		local base = userFolder(ownerId, version) .. "/" .. key
		local path = nil
		for _, tryExt in ipairs({ ".png", ".gif", ".jpg", ".webp" }) do
			if isfile(base .. tryExt) then
				path = base .. tryExt
				break
			end
		end
		if not path then
			return nil
		end
		local asset = nil
		pcall(function()
			asset = getcustomasset(path)
		end)
		if asset and asset ~= "" then
			assetCache[tostring(ownerId or "default") .. "/" .. key] = asset
			return asset
		end
		return nil
	end

	local function fetchImage(url, ownerId, version, key)
		url = resolveAsset(url)
		if not url then
			return nil
		end
		if not url:find("^https?://") then
			return url
		end
		if not hasFileSystem then
			return url
		end
		local fullKey = key .. "_" .. getUrlHash(url)
		local cached = readAsset(ownerId, version, fullKey)
		if cached then
			return cached
		end
		local body = httpGet(url)
		if not body or looksLikeHtml(body) then
			return url
		end
		return writeAsset(ownerId, version, fullKey, body) or url
	end

	local function applyImage(label, url, ownerId, version, key, fallbackFn)
		if not url then
			if fallbackFn then fallbackFn() end
			return
		end
		task.spawn(function()
			local asset = fetchImage(url, ownerId, version, key)
			if label and label.Parent then
				if asset and asset ~= "" then
					label.Image = asset
				else
					if fallbackFn then
						fallbackFn()
					else
						label.Visible = false
					end
				end
			end
		end)
	end
	local PACK_HEADER = 13

	local function unpackFrames(bytes)
		if type(bytes) ~= "string" or #bytes < PACK_HEADER then
			return nil
		end
		local magic = bytes:sub(1, 4)
		if magic ~= "SLTF" and magic ~= "SFP1" then
			return nil
		end
		local count = string.unpack(">I2", bytes, 7)
		local delay = string.unpack(">I2", bytes, 9)
		local frames = {}
		local at = PACK_HEADER + 1
		for i = 1, count do
			if at + 3 > #bytes then
				break
			end
			local length = string.unpack(">I4", bytes, at)
			at = at + 4
			if at + length - 1 > #bytes then
				break
			end
			frames[i] = bytes:sub(at, at + length - 1)
			at = at + length
		end
		if #frames == 0 then
			return nil
		end
		return frames, delay
	end

	local function loadFrames(pack, ownerId, version)
		local prefix = pack.prefix
		local assets = {}
		if hasFileSystem and pack.count and pack.count > 0 then
			for i = 1, pack.count do
				local fileKey = prefix .. i
				local asset = readAsset(ownerId, version, fileKey)
				if not asset then
					assets = {}
					break
				end
				assets[i] = asset
			end
			if #assets == pack.count then
				return assets
			end
		end
		local url = resolveAsset(pack.url) or pack.url
		local rawBody = httpGet(url)
		if not rawBody then
			return nil
		end
		local frames, packDelay = unpackFrames(rawBody)
		if not frames or #frames == 0 then
			local singleAsset = writeAsset(ownerId, version, prefix .. "1", rawBody)
			if singleAsset then
				return { singleAsset }
			end
			return nil
		end
		if packDelay and packDelay > 0 then
			pack.delay = packDelay
		end
		pack.count = #frames
		assets = {}
		for i, png in ipairs(frames) do
			local fileKey = prefix .. i
			local asset = writeAsset(ownerId, version, fileKey, png)
			if asset then
				assets[#assets + 1] = asset
			end
		end
		if #assets == 0 then
			return nil
		end
		return assets
	end

	local function playFrames(container, pack, ownerId, version, baseTransparency)
		baseTransparency = baseTransparency or 0
		local token = (container:GetAttribute("SlateFrameToken") or 0) + 1
		container:SetAttribute("SlateFrameToken", token)
		task.spawn(function()
			local assets = loadFrames(pack, ownerId, version)
			if not assets or not container.Parent then
				if not assets and container:IsA("ImageLabel") then
					local fallbackUrl = pack.fallbackUrl or pack.url
					if fallbackUrl then
						local fallbackKey = tostring(ownerId) .. (pack.prefix or "fb")
						applyImage(container, fallbackUrl, ownerId, version, fallbackKey)
					end
				end
				return
			end
			if container:GetAttribute("SlateFrameToken") ~= token then
				return
			end
			local existingCorner = container:FindFirstChildOfClass("UICorner")
			local cornerRadius = existingCorner and existingCorner.CornerRadius or UDim.new(0, 6)
			local frameLabels = {}
			for i, asset in ipairs(assets) do
				local img = Instance.new("ImageLabel")
				img.Name = "Frame_" .. i
				img.Size = UDim2.new(1, 0, 1, 0)
				img.BackgroundTransparency = 1
				img.ImageTransparency = baseTransparency
				img.ScaleType = Enum.ScaleType.Crop
				img.ZIndex = container.ZIndex + 1
				img.Visible = (i == 1)
				img.Image = asset
				Instance.new("UICorner", img).CornerRadius = cornerRadius
				frameLabels[i] = img
			end
			if not container.Parent or container:GetAttribute("SlateFrameToken") ~= token then
				return
			end
			local oldHolder = container:FindFirstChild("SlateFrameStack")
			if oldHolder then
				pcall(function()
					oldHolder:Destroy()
				end)
			end
			local holder = Instance.new("Frame")
			holder.Name = "SlateFrameStack"
			holder.Size = UDim2.new(1, 0, 1, 0)
			holder.BackgroundTransparency = 1
			holder.ClipsDescendants = true
			holder.ZIndex = container.ZIndex
			Instance.new("UICorner", holder).CornerRadius = cornerRadius
			for _, img in ipairs(frameLabels) do
				img.Parent = holder
			end
			holder.Parent = container
			local step = math.max((pack.delay or 100) / 1000, 1 / 60)
			local current = 1
			local elapsed = 0
			registerAnimator(function(dt)
				if not container.Parent or container:GetAttribute("SlateFrameToken") ~= token then
					return false
				end
				elapsed = elapsed + dt
				if elapsed < step then
					return true
				end
				local advance = math.floor(elapsed / step)
				elapsed = elapsed % step
				local nextFrame = ((current - 1 + advance) % #frameLabels) + 1
				if nextFrame ~= current then
					frameLabels[nextFrame].Visible = true
					frameLabels[current].Visible = false
					current = nextFrame
				end
				return true
			end, container)
		end)
	end
	local FONT_MAP = {
		Gotham = Enum.Font.BuilderSans,
		GothamBold = Enum.Font.BuilderSansBold,
		GothamBlack = Enum.Font.BuilderSansExtraBold,
		GothamMedium = Enum.Font.BuilderSansMedium,
		Montserrat = Enum.Font.BuilderSansMedium,
		Poppins = Enum.Font.BuilderSansBold,
		Inter = Enum.Font.BuilderSans,
		Outfit = Enum.Font.BuilderSansBold,
		SpaceGrotesk = Enum.Font.Code,
		BebasNeue = Enum.Font.Highway,
		Orbitron = Enum.Font.SciFi,
		RussoOne = Enum.Font.BuilderSansExtraBold,
		Rajdhani = Enum.Font.TitilliumWeb,
		Audiowide = Enum.Font.SciFi,
		PressStart2P = Enum.Font.Arcade,
		Silkscreen = Enum.Font.Arcade,
		Bungee = Enum.Font.BuilderSansExtraBold,
		Righteous = Enum.Font.FredokaOne,
		Fredoka = Enum.Font.FredokaOne,
		Comfortaa = Enum.Font.BuilderSans,
		Quicksand = Enum.Font.BuilderSansMedium,
		Lexend = Enum.Font.BuilderSansBold,
		Syne = Enum.Font.BuilderSansExtraBold,
		Playfair = Enum.Font.Garamond,
		SourceSans = Enum.Font.SourceSans,
		SourceSansBold = Enum.Font.SourceSansBold,
	}
	local GRADIENT_ROTATION = {
		["to right"] = 0,
		["to bottom right"] = 45,
		["to bottom"] = 90,
		["to bottom left"] = 135,
		["to left"] = 180,
		["to top left"] = 225,
		["to top"] = 270,
		["to top right"] = 315,
	}

	local function resolveFont(name)
		return FONT_MAP[name or "GothamBold"] or Enum.Font.BuilderSansBold
	end

	local function camel(key)
		return key:gsub("_(%l)", string.upper)
	end

	local function snake(key)
		return key:gsub("(%l)(%u)", "%1_%2"):lower()
	end

	local function getValue(raw, fallback, ...)
		if type(raw) ~= "table" then
			return fallback
		end
		for i = 1, select("#", ...) do
			local k = select(i, ...)
			if k ~= nil then
				if raw[k] ~= nil then
					return raw[k]
				end
				local c = camel(tostring(k))
				if raw[c] ~= nil then
					return raw[c]
				end
				local s = snake(tostring(k))
				if raw[s] ~= nil then
					return raw[s]
				end
			end
		end
		return fallback
	end

	local function parseStops(stops)
		if type(stops) == "string" then
			stops = decodeJson(stops)
		end
		if type(stops) ~= "table" or #stops < 2 then
			return nil
		end
		local sorted = {}
		for _, stop in pairs(stops) do
			if type(stop) == "table" then
				sorted[#sorted + 1] = stop
			end
		end
		if #sorted < 2 then
			return nil
		end
		table.sort(sorted, function(a, b)
			return (a.pos or a.position or 0) < (b.pos or b.position or 0)
		end)
		return sorted
	end

	local function mirroredSequence(stops)
		local keypoints = {}

		local function push(time, color)
			time = math.clamp(time, 0, 1)
			local last = keypoints[#keypoints]
			if last and time <= last.Time then
				time = math.min(last.Time + 0.001, 1)
			end
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(time, color)
		end
		for _, stop in ipairs(stops) do
			push(((stop.pos or stop.position or 0) / 100) * 0.5, toColor3(stop.color, Color3.new(1, 1, 1)))
		end
		for i = #stops - 1, 1, -1 do
			local stop = stops[i]
			push(0.5 + (1 - (stop.pos or stop.position or 0) / 100) * 0.5, toColor3(stop.color, Color3.new(1, 1, 1)))
		end
		if #keypoints < 2 then
			return nil
		end
		if keypoints[1].Time > 0 then
			table.insert(keypoints, 1, ColorSequenceKeypoint.new(0, keypoints[1].Value))
		end
		if keypoints[#keypoints].Time < 1 then
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, keypoints[#keypoints].Value)
		end
		local ok, sequence = pcall(function()
			return ColorSequence.new(keypoints)
		end)
		return ok and sequence or nil
	end

	local function flatSequence(stops)
		local keypoints = {}
		for _, stop in ipairs(stops) do
			local time = math.clamp((stop.pos or stop.position or 0) / 100, 0, 1)
			local last = keypoints[#keypoints]
			if last and time <= last.Time then
				time = math.min(last.Time + 0.001, 1)
			end
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(time, toColor3(stop.color, Color3.new(0, 0, 0)))
		end
		if #keypoints < 2 then
			return nil
		end
		if keypoints[1].Time > 0 then
			table.insert(keypoints, 1, ColorSequenceKeypoint.new(0, keypoints[1].Value))
		end
		if keypoints[#keypoints].Time < 1 then
			keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, keypoints[#keypoints].Value)
		end
		local ok, sequence = pcall(function()
			return ColorSequence.new(keypoints)
		end)
		return ok and sequence or nil
	end

	local function parseGradient(
		raw,
		defaultObj,
		enabledKey1,
		enabledKey2,
		dirKey1,
		dirKey2,
		stopsKey1,
		stopsKey2,
		animKey1,
		animKey2,
		speedKey1,
		speedKey2
	)
		local enabled = getValue(raw, defaultObj and defaultObj.enabled, enabledKey1, enabledKey2)
		if enabled ~= true then
			return nil
		end
		local stopsRaw = getValue(raw, defaultObj and defaultObj.stops, stopsKey1, stopsKey2)
		local stops = parseStops(stopsRaw) or (defaultObj and defaultObj.stops and parseStops(defaultObj.stops))
		if not stops then
			return nil
		end
		local animated = getValue(raw, defaultObj and defaultObj.anim, animKey1, animKey2) == true
		local sequence = animated and mirroredSequence(stops) or flatSequence(stops)
		if not sequence then
			return nil
		end
		local dir = getValue(raw, defaultObj and defaultObj.dir or "to right", dirKey1, dirKey2)
		local speed = tonumber(getValue(raw, defaultObj and defaultObj.speed or 3, speedKey1, speedKey2)) or 3
		return {
			sequence = sequence,
			rotation = GRADIENT_ROTATION[dir] or 0,
			animated = animated,
			speed = speed,
		}
	end

	local function parseConfig(raw, ownerId)
		LPS_ATTRIBUTES(VM(NONE))
		raw = type(raw) == "table" and raw or {}
		ownerId = ownerId or "default"
		local tagPrefix = tostring(ownerId)
		local displayName = getValue(raw, DEFAULT_RAW_CONFIG.displayName, "displayName", "name_text", "text", "tagText")
		local function _isHalloweenArt(u) return type(u) == "string" and u:find("Slate_Halloween_", 1, true) ~= nil end
		local isDefault = (raw == DEFAULT_RAW_CONFIG or raw == "default" or (type(raw) == "table" and (raw.isDefault == true
			or _isHalloweenArt(raw.backgroundImage) or _isHalloweenArt(raw.iconImage)
			or _isHalloweenArt(raw.image_url) or _isHalloweenArt(raw.icon_image))))
		local bgType = getValue(raw, DEFAULT_RAW_CONFIG.bgType, "bgType", "bg_type")
		local version = tostring(getValue(raw, "v1", "artVersion", "art_version", "updated_at"))
		local iconRaw = getValue(raw, DEFAULT_RAW_CONFIG.iconImage, "iconImage", "icon_image")
		local iconResolved = resolveAsset(iconRaw) or CONFIG.defaultIcon
		local iconOwner = (iconResolved == CONFIG.defaultIcon or isDefault) and "default" or ownerId
		local bgImageRaw =
			getValue(raw, DEFAULT_RAW_CONFIG.backgroundImage, "backgroundImage", "image_url", "tag_image")
		local bgImageResolved = resolveAsset(bgImageRaw) or CONFIG.defaultBackground
		local bgOwner = (bgImageResolved == CONFIG.defaultBackground or isDefault) and "default" or ownerId
		local outlineCol = isDefault and toColor3(DEFAULT_RAW_CONFIG.outlineColor, Color3.fromRGB(255, 255, 255))
			or toColor3(
				getValue(
					raw,
					DEFAULT_RAW_CONFIG.outlineColor,
					"outlineColor",
					"outline_color",
					"strokeColor",
					"glow_color"
				),
				Color3.fromRGB(255, 255, 255)
			)
		local strokeThick = isDefault and (tonumber(DEFAULT_RAW_CONFIG.strokeThickness) or 2)
			or math.max(
				tonumber(getValue(raw, DEFAULT_RAW_CONFIG.strokeThickness, "strokeThickness", "stroke_thickness")) or 2,
				0
			)
		local cfg = {
			version = version,
			displayName = displayName,
			font = resolveFont(getValue(raw, DEFAULT_RAW_CONFIG.font, "font", "font_face")),
			textColor = isDefault and Color3.fromRGB(255, 255, 255) or toColor3(
				getValue(raw, DEFAULT_RAW_CONFIG.textColor, "textColor", "name_color", "color"),
				Color3.fromRGB(255, 255, 255)
			),
			outlineColor = outlineCol,
			backgroundColor = toColor3(
				getValue(raw, DEFAULT_RAW_CONFIG.backgroundColor, "backgroundColor", "background_color", "tag_color"),
				Color3.fromRGB(0, 0, 0)
			),
			strokeThickness = strokeThick,
			bgTransparency = (tonumber(
				getValue(raw, DEFAULT_RAW_CONFIG.bgTransparency, "bgTransparency", "bg_transparency")
			) or 0) / 100,
			bgType = isDefault and "image" or bgType,
			glitch = getValue(raw, false, "glitchAnim", "glitch_anim") == true,
			iconImage = isDefault and CONFIG.defaultIcon or iconResolved,
			iconOwner = iconOwner,
			backgroundImage = isDefault and CONFIG.defaultBackground or bgImageResolved,
			bgOwner = bgOwner,
		}
		local isGif = getValue(raw, false, "isGif", "is_gif") == true
		local bgFrames = getValue(raw, nil, "framesUrl", "frames_url", "backgroundFrames", "bgFrames", "bgFramesUrl", "bg_frames_url")
		local bgCount = tonumber(getValue(raw, 0, "framesCount", "frames_count", "frameCount", "frame_count", "bgFramesCount", "bg_frames_count")) or 0
		local iconFrames = getValue(raw, nil, "iconFramesUrl", "icon_frames_url", "iconFrames", "icon_frames")
		local iconCount = tonumber(
			getValue(raw, 0, "iconFramesCount", "icon_frames_count", "iconFrameCount", "icon_frame_count")
		) or 0
		if
			(not bgFrames or bgFrames == "")
			and type(bgImageRaw) == "string"
			and bgImageRaw:lower():find("%.gif")
		then
			bgFrames = bgImageRaw:gsub("%.[gG][iI][fF]$", ".sltf"):gsub("%.[gG][iI][fF]%?", ".sltf?")
		end
		if
			(not iconFrames or iconFrames == "")
			and type(iconRaw) == "string"
			and iconRaw:lower():find("%.gif")
		then
			iconFrames = iconRaw:gsub("%.[gG][iI][fF]$", ".sltf"):gsub("%.[gG][iI][fF]%?", ".sltf?")
		end
		local hasBgFrames = (bgFrames and bgFrames ~= "")
		local hasIconFrames = (iconFrames and iconFrames ~= "")
		if not isDefault and (isGif or hasBgFrames) and hasBgFrames then
			local urlHash = getUrlHash(tostring(bgFrames))
			cfg.backgroundFrames = {
				url = bgFrames,
				fallbackUrl = bgImageResolved,
				count = bgCount,
				delay = tonumber(getValue(raw, 100, "framesDelay", "frames_delay", "frameDelay", "frame_delay")) or 100,
				prefix = "bg_" .. urlHash .. "_" .. tostring(version or "v1") .. "_",
			}
		else
			cfg.backgroundFrames = nil
		end
		if not isDefault and (isGif or hasIconFrames) and hasIconFrames then
			local urlHash = getUrlHash(tostring(iconFrames))
			cfg.iconFrames = {
				url = iconFrames,
				fallbackUrl = iconResolved,
				count = iconCount,
				delay = tonumber(
					getValue(raw, 100, "iconFramesDelay", "icon_frames_delay", "iconFrameDelay", "icon_frame_delay")
				) or 100,
				prefix = "icon_" .. urlHash .. "_" .. tostring(version or "v1") .. "_",
			}
		else
			cfg.iconFrames = nil
		end
		if isDefault then
			local stops = parseStops(DEFAULT_RAW_CONFIG.textGradientStops)
			cfg.textGradient = {
				sequence = mirroredSequence(stops),
				rotation = 0,
				animated = true,
				speed = 3,
			}
			cfg.strokeGradient = nil
		else
			local textEnabled = getValue(
				raw,
				DEFAULT_RAW_CONFIG.textGradientEnabled,
				"textGradientEnabled",
				"text_gradient_enabled"
			) == true
			local textDef = {
				enabled = textEnabled,
				dir = getValue(raw, DEFAULT_RAW_CONFIG.textGradientDir, "textGradientDir", "text_gradient_dir"),
				stops = getValue(raw, DEFAULT_RAW_CONFIG.textGradientStops, "textGradientStops", "text_gradient_stops"),
				anim = getValue(
					raw,
					DEFAULT_RAW_CONFIG.textGradientAnimEnabled,
					"textGradientAnimEnabled",
					"text_gradient_anim_enabled"
				) == true,
				speed = getValue(raw, DEFAULT_RAW_CONFIG.textGradientSpeed, "textGradientSpeed", "text_gradient_speed"),
			}
			cfg.textGradient = parseGradient(
				raw,
				textDef,
				"textGradientEnabled",
				"text_gradient_enabled",
				"textGradientDir",
				"text_gradient_dir",
				"textGradientStops",
				"text_gradient_stops",
				"textGradientAnimEnabled",
				"text_gradient_anim_enabled",
				"textGradientSpeed",
				"text_gradient_speed"
			)
			local strokeEnabled = getValue(
				raw,
				DEFAULT_RAW_CONFIG.strokeGradientEnabled,
				"strokeGradientEnabled",
				"stroke_gradient_enabled"
			) == true
			local strokeDef = {
				enabled = strokeEnabled,
				dir = getValue(raw, DEFAULT_RAW_CONFIG.strokeGradientDir, "strokeGradientDir", "stroke_gradient_dir"),
				stops = getValue(
					raw,
					DEFAULT_RAW_CONFIG.strokeGradientStops,
					"strokeGradientStops",
					"stroke_gradient_stops"
				),
				anim = getValue(
					raw,
					DEFAULT_RAW_CONFIG.strokeGradientAnimEnabled,
					"strokeGradientAnimEnabled",
					"stroke_gradient_anim_enabled"
				) == true,
			}
			cfg.strokeGradient = parseGradient(
				raw,
				strokeDef,
				"strokeGradientEnabled",
				"stroke_gradient_enabled",
				"strokeGradientDir",
				"stroke_gradient_dir",
				"strokeGradientStops",
				"stroke_gradient_stops",
				"strokeGradientAnimEnabled",
				"stroke_gradient_anim_enabled",
				nil,
				nil
			)
		end
		local bgStopsRaw = getValue(raw, DEFAULT_RAW_CONFIG.bgGradientStops, "bgGradientStops", "bg_gradient_stops")
		if not isDefault and (bgType == "gradient" or bgStopsRaw ~= nil) then
			local stops = parseStops(bgStopsRaw)
			if stops then
				local dir = getValue(raw, DEFAULT_RAW_CONFIG.bgGradientDir, "bgGradientDir", "bg_gradient_dir")
				cfg.bgGradient = {
					sequence = flatSequence(stops),
					rotation = GRADIENT_ROTATION[dir] or 0,
				}
			end
		end
		return cfg
	end
	local enabled = true
	local tags = {}

	local function billboardNameFor(player)
		return player.Name .. "_SlateBillboard"
	end

	local function adorneeFor(player)
		local character = player.Character
		if not character then
			return nil
		end
		return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	end

	local function attachGradient(instance, gradient, colorProperty)
		if not gradient or not gradient.sequence then
			return
		end
		if colorProperty then
			instance[colorProperty] = Color3.new(1, 1, 1)
		end
		local ui = Instance.new("UIGradient")
		ui.Color = gradient.sequence
		ui.Rotation = gradient.rotation
		ui.Parent = instance
		if not gradient.animated then
			return
		end
		local speed = math.max(gradient.speed or 3, 0.1)
		local t = 0
		registerAnimator(function(dt)
			if not instance.Parent then
				return false
			end
			t = (t + (dt * 2) / speed) % 2
			ui.Offset = Vector2.new(-1 + t, 0)
			return true
		end, instance)
	end
	local GLITCH_CHARS = { "!", "@", "#", "$", "%", "^", "&", "*", "~", "?", "/" }

	local function runGlitch(label, baseText)
		task.spawn(function()
			LPS_ATTRIBUTES(VM(NONE))
			while label.Parent do
				task.wait(2)
				if not label.Parent then
					return
				end
				if math.random() < 0.3 then
					local scrambled = ""
					for i = 1, #baseText do
						scrambled = scrambled
							.. (math.random() < 0.15 and GLITCH_CHARS[math.random(#GLITCH_CHARS)] or baseText:sub(i, i))
					end
					label.Text = scrambled
					task.wait(0.2)
					if label.Parent then
						label.Text = baseText
					end
				end
			end
		end)
	end

	local function buildTag(player, cfg, billboard)
		local ownerId = player.UserId
		local frame = Instance.new("Frame")
		frame.Name = "Background"
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.Size = UDim2.new(0, 0, 0, CONFIG.tagHeight)
		frame.AutomaticSize = Enum.AutomaticSize.X
		frame.BackgroundColor3 = cfg.backgroundColor
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = false
		frame.ZIndex = 1
		local hasArt = cfg.backgroundFrames ~= nil or cfg.backgroundImage ~= nil

		if (tonumber(cfg.bgTransparency) or 0) >= 0.98 and (tonumber(cfg.strokeThickness) or 0) <= 0 then
			cfg.bgTransparency = 0.18
			cfg.strokeThickness = 1.5
		end
		frame.BackgroundTransparency = cfg.bgTransparency
		frame.Parent = billboard
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
		if cfg.bgGradient then
			attachGradient(frame, cfg.bgGradient, "BackgroundColor3")
		end
		local stroke = Instance.new("UIStroke", frame)
		stroke.Name = "Stroke"
		stroke.Color = cfg.outlineColor
		stroke.Thickness = cfg.strokeThickness
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Enabled = cfg.strokeThickness > 0
		attachGradient(stroke, cfg.strokeGradient, "Color")
		local hasArt = cfg.backgroundFrames ~= nil or cfg.backgroundImage ~= nil
		if hasArt then
			local art = Instance.new("ImageLabel", frame)
			art.Name = "BackgroundArt"
			art.Size = UDim2.new(1, 0, 1, 0)
			art.BackgroundTransparency = 1
			art.ImageTransparency = cfg.bgTransparency
			art.ScaleType = Enum.ScaleType.Crop
			art.ClipsDescendants = true
			art.ZIndex = 2
			art.Image = ""
			Instance.new("UICorner", art).CornerRadius = UDim.new(0, 6)
			if cfg.backgroundFrames then
				playFrames(art, cfg.backgroundFrames, ownerId, cfg.version, cfg.bgTransparency)
			else
				local oldStack = art:FindFirstChild("SlateFrameStack")
				if oldStack then
					pcall(function()
						oldStack:Destroy()
					end)
				end
				local bgKey = tostring(cfg.bgOwner or ownerId) .. "bg"
				local function onBgFail()
					if art and art.Parent then
						art.Visible = false
					end
				end
				applyImage(art, cfg.backgroundImage, cfg.bgOwner or ownerId, cfg.version, bgKey, onBgFail)
			end
		end
		local content = Instance.new("Frame", frame)
		content.Name = "Content"
		content.Size = UDim2.new(1, 0, 1, 0)
		content.BackgroundTransparency = 1
		content.ZIndex = 10
		local layout = Instance.new("UIListLayout", content)
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 6)
		local padding = Instance.new("UIPadding", content)
		padding.Name = "TagPadding"
		padding.PaddingLeft = UDim.new(0, 8)
		padding.PaddingRight = UDim.new(0, 8)
		padding.PaddingTop = UDim.new(0, 4)
		padding.PaddingBottom = UDim.new(0, 4)
		local icon = Instance.new("ImageLabel", content)
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, CONFIG.iconSize, 0, CONFIG.iconSize)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.LayoutOrder = 0
		icon.ZIndex = 51
		icon.Image = ""
		Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
		if cfg.iconFrames then
			playFrames(icon, cfg.iconFrames, ownerId, cfg.version, 0)
		elseif cfg.iconImage and cfg.iconImage ~= "" then
			local oldStack = icon:FindFirstChild("SlateFrameStack")
			if oldStack then
				pcall(function()
					oldStack:Destroy()
				end)
			end
			local iconKey = tostring(cfg.iconOwner or ownerId) .. "icon"
			local function onIconFail()
				if icon and icon.Parent then
					applyHeadshot(icon, ownerId)
				end
			end
			applyImage(icon, cfg.iconImage, cfg.iconOwner or ownerId, cfg.version, iconKey, onIconFail)
		else
			applyHeadshot(icon, ownerId)
		end
		local text = Instance.new("Frame", content)
		text.Name = "Text"
		text.Size = UDim2.new(0, 0, 0, 38)
		text.AutomaticSize = Enum.AutomaticSize.X
		text.BackgroundTransparency = 1
		text.LayoutOrder = 1
		text.ZIndex = 51
		local textLayout = Instance.new("UIListLayout", text)
		textLayout.FillDirection = Enum.FillDirection.Vertical
		textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		textLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local nameLabel = Instance.new("TextLabel", text)
		nameLabel.Name = "DisplayName"
		nameLabel.Size = UDim2.new(0, 0, 0, 20)
		nameLabel.AutomaticSize = Enum.AutomaticSize.X
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = cfg.displayName
		nameLabel.Font = cfg.font
		nameLabel.TextSize = 13
		nameLabel.TextColor3 = cfg.textColor
		nameLabel.TextStrokeTransparency = 1
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.LayoutOrder = 0
		nameLabel.ZIndex = 52
		attachGradient(nameLabel, cfg.textGradient, "TextColor3")
		if cfg.glitch then
			runGlitch(nameLabel, cfg.displayName)
		end
		local userLabel = Instance.new("TextLabel", text)
		userLabel.Name = "Username"
		userLabel.Size = UDim2.new(0, 0, 0, 15)
		userLabel.AutomaticSize = Enum.AutomaticSize.X
		userLabel.BackgroundTransparency = 1
		userLabel.Text = "@" .. player.Name
		userLabel.Font = Enum.Font.BuilderSans
		userLabel.TextSize = 11
		userLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
		userLabel.TextTransparency = 0.4
		userLabel.TextStrokeTransparency = 1
		userLabel.TextXAlignment = Enum.TextXAlignment.Left
		userLabel.LayoutOrder = 1
		userLabel.ZIndex = 52
		if player ~= localPlayer then
			local btn = Instance.new("TextButton", frame)
			btn.Name = "TeleportButton"
			btn.Size = UDim2.new(1, 0, 1, 0)
			btn.Position = UDim2.new(0, 0, 0, 0)
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.Active = true
			btn.ZIndex = 1000
			local function doTeleport()
				pcall(function()
					local targetChar = player.Character
					local localChar = localPlayer.Character
					local targetRoot = targetChar
						and (
							targetChar:FindFirstChild("HumanoidRootPart")
							or targetChar:FindFirstChild("Head")
							or targetChar.PrimaryPart
						)
					local localRoot = localChar
						and (
							localChar:FindFirstChild("HumanoidRootPart")
							or localChar:FindFirstChild("Head")
							or localChar.PrimaryPart
						)
					if targetRoot and localChar then
						local targetCFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
						if localChar.PivotTo then
							localChar:PivotTo(targetCFrame)
						elseif localRoot then
							localRoot.CFrame = targetCFrame
						end
						if localRoot then
							pcall(function()
								localRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							end)
						end
					end
				end)
			end
			btn.MouseButton1Click:Connect(doTeleport)
			btn.Activated:Connect(doTeleport)
		end
		return frame, content, text, layout
	end

	local function runDistanceLoop(billboard, frame, textContainer, layout, adornee)
		task.spawn(function()
			local content = frame:FindFirstChild("Content")
			local padding = content and content:FindFirstChild("TagPadding")
			task.wait(math.random() * 0.2)
			local minimized = nil
			local function setMinimized(state)
				if minimized == state then return end
				minimized = state
				textContainer.Visible = not state
				if not state then
					frame.AutomaticSize = Enum.AutomaticSize.X
					frame.Size = UDim2.new(0, 0, 0, CONFIG.tagHeight)
					layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
					if padding then
						padding.PaddingLeft = UDim.new(0, 8)
						padding.PaddingRight = UDim.new(0, 8)
					end
				else
					frame.AutomaticSize = Enum.AutomaticSize.None
					frame.Size = UDim2.new(0, CONFIG.tagHeight, 0, CONFIG.tagHeight)
					layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
					if padding then
						padding.PaddingLeft = UDim.new(0, 0)
						padding.PaddingRight = UDim.new(0, 0)
					end
				end
			end
			while billboard.Parent and frame.Parent and textContainer.Parent do
				local camera = workspace.CurrentCamera
				local part = (adornee and adornee.Parent and adornee) or billboard.Adornee
				if camera and part and part.Parent then
					local far = (part.Position - camera.CFrame.Position).Magnitude > CONFIG.minimizeDistance
					setMinimized(far)
				else
					setMinimized(false)
				end
				task.wait(CONFIG.distanceCheck or 0.25)
			end
		end)
	end

	local function setHumanoidNames(player, visible)
		local character = player and player.Character
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			humanoid = character:WaitForChild("Humanoid", 4)
			if not humanoid then return end
		end
		pcall(function()
			humanoid.DisplayDistanceType = visible and Enum.HumanoidDisplayDistanceType.Viewer
				or Enum.HumanoidDisplayDistanceType.None
		end)
	end

	local function removeTag(userId)
		local tag = tags[userId]
		if not tag then
			return
		end
		tags[userId] = nil
		if tag.billboard then
			pcall(function()
				tag.billboard:Destroy()
			end)
		end
		setHumanoidNames(Players:GetPlayerByUserId(userId), true)
	end

	local function isTagValid(player, configVersion)
		local tag = tags[player.UserId]
		if not tag then
			return false
		end
		if not tag.billboard or not tag.billboard.Parent then
			return false
		end
		if not tag.adornee or not tag.adornee.Parent then
			return false
		end
		if tag.adornee ~= adorneeFor(player) then
			return false
		end
		if tag.configVersion ~= configVersion then
			return false
		end
		return true
	end

	local function createTag(player, cfg, configVersion)
		local adornee = adorneeFor(player)
		if not adornee then
			local char = player.Character
			if char then
				local head = char:WaitForChild("Head", 6)
				adornee = head or char:FindFirstChild("HumanoidRootPart")
			end
			if not adornee then return end
		end
		removeTag(player.UserId)
		local billboardParent = localPlayer:FindFirstChildOfClass("PlayerGui") or targetUI
		local existing = billboardParent:FindFirstChild(billboardNameFor(player))
		if existing then
			pcall(function()
				existing:Destroy()
			end)
		end
		setHumanoidNames(player, false)
		local billboard = Instance.new("BillboardGui")
		billboard.Name = billboardNameFor(player)
		billboard.Adornee = adornee
		billboard.Size = UDim2.new(0, 150, 0, CONFIG.tagHeight)
		billboard.StudsOffsetWorldSpace = CONFIG.studsOffset
		billboard.MaxDistance = math.huge
		billboard.AlwaysOnTop = true
		billboard.Active = true
		billboard.LightInfluence = 0
		billboard.ResetOnSpawn = false
		billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		billboard.Enabled = enabled
		billboard.Parent = billboardParent
		local frame, content, textContainer, layout = buildTag(player, cfg, billboard)
		runDistanceLoop(billboard, frame, textContainer, layout, adornee)
		tags[player.UserId] = {
			billboard = billboard,
			frame = frame,
			content = content,
			textContainer = textContainer,
			adornee = adornee,
			configVersion = configVersion,
		}
	end
	local configs = {}
	local rawConfigs = {}

	local function storeConfig(username, rawConfig)
		local key = username:lower()
		local p = findPlayer(username)
		local ownerId = p and p.UserId or "default"
		if not rawConfig or rawConfig == false then
			configs[key] = parseConfig(DEFAULT_RAW_CONFIG, ownerId)
			rawConfigs[key] = "default"
			return
		end
		local encoded = (type(rawConfig) == "string") and rawConfig or HttpService:JSONEncode(rawConfig)
		if rawConfigs[key] == encoded and type(configs[key]) == "table" then
			return
		end
		local decoded = (type(rawConfig) == "table") and rawConfig or decodeJson(encoded)
		configs[key] = parseConfig(decoded, ownerId)
		rawConfigs[key] = encoded
		if p then
			local uidKey = tostring(p.UserId)
			configs[uidKey] = configs[key]
			rawConfigs[uidKey] = encoded
		end
	end
	local activeSlateUsers = {
		[localPlayer.UserId] = true,
		[tostring(localPlayer.UserId)] = true,
		[localPlayer.Name:lower()] = true,
	}

	local function isUserActiveSlate(player)
		if not player then
			return false
		end
		if player == localPlayer then
			return true
		end
		if activeSlateUsers[player.UserId] then
			return true
		end
		if activeSlateUsers[tostring(player.UserId)] then
			return true
		end
		if activeSlateUsers[player.Name:lower()] then
			return true
		end
		if activeSlateUsers[player.Name] then
			return true
		end
		return false
	end

	local function applyConfig(player)
		if not player then
			return
		end
		local key = player.Name:lower()
		local uidStr = tostring(player.UserId)

		if not isUserActiveSlate(player) then
			removeTag(player.UserId)
			return
		end
		local raw = rawConfigs[key] or rawConfigs[uidStr]
		local cfg = configs[key] or configs[uidStr]
		if raw and raw ~= "default" and cfg and type(cfg) == "table" and cfg ~= "inactive" then
			if not isTagValid(player, raw) then
				createTag(player, cfg, raw)
			end
			return
		end
		if not cfg or cfg == "inactive" or type(cfg) ~= "table" then
			storeConfig(key, DEFAULT_RAW_CONFIG)
			storeConfig(uidStr, DEFAULT_RAW_CONFIG)
			cfg = configs[key]
		end
		if cfg and type(cfg) == "table" and cfg ~= "inactive" then
			if not isTagValid(player, rawConfigs[key] or "default") then
				createTag(player, cfg, rawConfigs[key] or "default")
			end
		end
	end

	local function postPresence(action)
		task.defer(function()
			pcall(function()
				httpPostJson(CONFIG.backendUrl .. LPS_ENCSTR("/api/globalusers"), {
					userId = localPlayer.UserId,
					placeId = PLACE_ID,
					jobId = JOB_ID,
					action = action,
				})
			end)
		end)
	end

	local function fetchActiveUserIds()
		local active = {
			[localPlayer.UserId] = true,
			[tostring(localPlayer.UserId)] = true,
			[localPlayer.Name:lower()] = true,
		}
		local payload = decodeJson(httpGet(CONFIG.backendUrl .. LPS_ENCSTR("/api/globalusers?nocache=") .. tick()))

		if not payload or type(payload.servers) ~= "table" then
			return nil
		end
		local place = payload.servers[PLACE_ID]
		local ids = place and place[JOB_ID]
		if type(ids) ~= "table" then
			return active
		end
		for _, id in ipairs(ids) do
			local n = tonumber(id)
			if n then
				active[n] = true
			end
			active[tostring(id)] = true
			active[tostring(id):lower()] = true
			local p = findPlayer(id)
			if p then
				active[p.UserId] = true
				active[tostring(p.UserId)] = true
				active[p.Name:lower()] = true
			end
		end
		return active
	end

	local function fetchAllConfigs()
		local body = httpGet(CONFIG.backendUrl .. LPS_ENCSTR("/tags.json?nocache=") .. tick())
		local payload = decodeJson(body)
		if type(payload) == "table" then
			for identifier, entry in pairs(payload) do
				local usable = type(entry) == "table" and (entry.config or entry) or entry
				storeConfig(tostring(identifier), usable)
			end
		end
	end

	local function updatePlayerTagLive(identifier, rawConfig)
		local p = findPlayer(identifier)
		if not p then
			return
		end
		removeTag(p.UserId)
		deleteUserCache(p.UserId)
		local key = p.Name:lower()
		rawConfigs[key] = nil
		configs[key] = nil
		if not rawConfig or not isCustomConfig(rawConfig) then
			storeConfig(key, DEFAULT_RAW_CONFIG)
			storeConfig(tostring(p.UserId), DEFAULT_RAW_CONFIG)
		else
			storeConfig(key, rawConfig)
			storeConfig(tostring(p.UserId), rawConfig)
		end

		applyConfig(p)
	end

	local function extractConfig(raw)
		if type(raw) ~= "table" then
			return nil
		end
		if type(raw.config) == "table" then
			return raw.config
		end
		if type(raw.data) == "table" then
			return raw.data
		end
		if type(raw.payload) == "table" then
			return raw.payload
		end
		return raw
	end

	local function isCustomConfig(cfg)
		if type(cfg) ~= "table" then
			return false
		end
		if cfg == DEFAULT_RAW_CONFIG or cfg.isDefault == true or cfg.isCustom == false then
			return false
		end
		local inner = cfg.config or cfg.data or cfg.payload
		if type(inner) == "table" and inner ~= cfg then
			if isCustomConfig(inner) then
				return true
			end
		end
		if cfg.isCustom == true then
			return true
		end
		local function oldDefaultArt(u) return type(u) == "string" and (u:find("Slate_Halloween_", 1, true) ~= nil) end
		if cfg.image_url and cfg.image_url ~= DEFAULT_RAW_CONFIG.backgroundImage and not oldDefaultArt(cfg.image_url) and cfg.image_url ~= "https://i.postimg.cc/NFGmdgc0/IMG-1295.jpg" then
			return true
		end
		if cfg.backgroundImage and cfg.backgroundImage ~= DEFAULT_RAW_CONFIG.backgroundImage and not oldDefaultArt(cfg.backgroundImage) and cfg.backgroundImage ~= "https://i.postimg.cc/NFGmdgc0/IMG-1295.jpg" then
			return true
		end
		if cfg.frames_url or cfg.framesUrl or cfg.bgFramesUrl then
			return true
		end
		if cfg.icon_image and cfg.icon_image ~= DEFAULT_RAW_CONFIG.iconImage and not oldDefaultArt(cfg.icon_image) and cfg.icon_image ~= "https://i.postimg.cc/fTW53y7h/IMG-2754-Photoroom.png" then
			return true
		end
		if cfg.iconImage and cfg.iconImage ~= DEFAULT_RAW_CONFIG.iconImage and not oldDefaultArt(cfg.iconImage) and cfg.iconImage ~= "https://i.postimg.cc/fTW53y7h/IMG-2754-Photoroom.png" then
			return true
		end
		if cfg.icon_frames_url or cfg.iconFramesUrl then
			return true
		end
		if cfg.name_text and cfg.name_text ~= DEFAULT_RAW_CONFIG.displayName and cfg.name_text:gsub("%s+", "") ~= "SLATE" then
			return true
		end
		if cfg.displayName and cfg.displayName ~= DEFAULT_RAW_CONFIG.displayName and cfg.displayName:gsub("%s+", "") ~= "SLATE" then
			return true
		end
		if cfg.is_gif or cfg.isGif then
			return true
		end
		return false
	end

	local function syncPlayer(player)
		if not player then
			return
		end
		local key = player.Name:lower()
		local uidStr = tostring(player.UserId)
		local body = httpGet(CONFIG.backendUrl .. LPS_ENCSTR("/api/nametagconfig/") .. uidStr .. "?nocache=" .. tick())
		local res = decodeJson(body)
		local customCfg = extractConfig(res)
		if not isCustomConfig(customCfg) then
			local nameBody = httpGet(CONFIG.backendUrl .. LPS_ENCSTR("/api/nametagconfig/") .. player.Name .. "?nocache=" .. tick())
			local nameRes = decodeJson(nameBody)
			local nameCustomCfg = extractConfig(nameRes)
			if isCustomConfig(nameCustomCfg) then
				customCfg = nameCustomCfg
			end
		end
		if isCustomConfig(customCfg) then
			local encoded = HttpService:JSONEncode(customCfg)
			if rawConfigs[key] ~= encoded then
				removeTag(player.UserId)
				deleteUserCache(player.UserId)
				rawConfigs[key] = nil
				configs[key] = nil
				storeConfig(key, customCfg)
				storeConfig(uidStr, customCfg)
			end
		else
			if not isUserActiveSlate(player) then
				removeTag(player.UserId)
				deleteUserCache(player.UserId)
				rawConfigs[key] = nil
				configs[key] = nil
				rawConfigs[uidStr] = nil
				configs[uidStr] = nil
				return
			else

				if not rawConfigs[key] then
					storeConfig(key, DEFAULT_RAW_CONFIG)
					storeConfig(uidStr, DEFAULT_RAW_CONFIG)
				end
			end
		end
		applyConfig(player)
	end

	local function fetchConfigsBulk(list)
		if type(list) ~= "table" or #list == 0 then
			return
		end
		local ws = _G.SlateActiveWS
		if ws then
			local sent = pcall(function()
				ws:Send(HttpService:JSONEncode({ type = LPS_ENCSTR("nametag_request"), usernames = list }))
			end)
			if sent then
				return
			end
		end
		local delay = 0
		for _, ident in ipairs(list) do
			local p = findPlayer(ident)
			if p then
				local d = delay
				task.delay(d, function()
					pcall(syncPlayer, p)
				end)
				delay = delay + 0.15
			end
		end
	end

	local function syncAll()
		activeSlateUsers = fetchActiveUserIds() or activeSlateUsers
		pcall(fetchAllConfigs)
		local delay = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local p = player
			task.delay(delay, function()
				pcall(syncPlayer, p)
			end)
			delay = delay + 0.12
		end
	end
	local players = Players
	local httpService = HttpService
	local runService = RunService
	local tweenService = game:GetService("TweenService")
	local userInputService = game:GetService("UserInputService")
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local soundService = game:GetService("SoundService")
	local lighting = game:GetService("Lighting")
	local debris = game:GetService("Debris")
	local textChatService = game:GetService("TextChatService")
	local coreGui = game:GetService("CoreGui")
	local voiceChatService = (pcall(function()
		return game:GetService("VoiceChatService")
	end)) and game:GetService("VoiceChatService") or nil
	local voiceChatInternal = (pcall(function()
		return game:GetService("VoiceChatInternal")
	end)) and game:GetService("VoiceChatInternal") or nil
	local camera = workspace.CurrentCamera
	local isLegacyChat = textChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
	local jobId = game.JobId
	local connections = {}
	local stopAllDragging
	local runUncrucifyOnPlayer, runUnhangOnPlayer
	local CMD_MAIN_WHITELISTED_IDS = {
		LPS_ENCNUM(10808550547),
		LPS_ENCNUM(10012699579),
		LPS_ENCNUM(4377530875),
		LPS_ENCNUM(3459666509),
		LPS_ENCNUM(10845358519),
		LPS_ENCNUM(293450),
		LPS_ENCNUM(2637355515),
		LPS_ENCNUM(8678906109),
		LPS_ENCNUM(10565812383),
	}
	local CMD_ADMINISTRATIVE_WHITELISTED_IDS = {}
	local CMD_SECONDARY_WHITELISTED_IDS = {}
	local CMD_IMMUNE_WHITELISTED_IDS = { LPS_ENCNUM(10808550547), LPS_ENCNUM(10012699579) }

	local function cmdIsWhitelisted(userId)
		LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
		return table.find(CMD_MAIN_WHITELISTED_IDS, userId) ~= nil
	end

	local function cmdIsImmuneWhitelisted(userId)
		LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
		return table.find(CMD_IMMUNE_WHITELISTED_IDS, userId) ~= nil
	end

	local function cmdIsAdminWhitelisted(userId)
		LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
		return table.find(CMD_ADMINISTRATIVE_WHITELISTED_IDS, userId) ~= nil
	end

	local function cmdIsSecondaryWhitelisted(userId)
		LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
		return table.find(CMD_SECONDARY_WHITELISTED_IDS, userId) ~= nil or cmdIsAdminWhitelisted(userId)
	end

	local function isAnyWhitelisted(userId)
		LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
		return cmdIsWhitelisted(userId) or cmdIsAdminWhitelisted(userId) or cmdIsSecondaryWhitelisted(userId)
	end
	local commands, aliases = {}, {}
	local following, followTarget = false, nil
	local looping = {}
	local Anchored = false
	local audioCommands = {
		creepy = { "157636218", { "shiver", "xd" } },
		knock = { "5236308259", { "xd2" } },
		elevatorjam = { "131371906028599", { "ejam", "jam" } },
	}
	local scaryFaces = {
		"9565121852",
		"13812091235",
		"5182578556",
		"99181901800612",
		"13193479764",
		"12527364300",
		"136342594291398",
		"10970697149",
		"121616559982446",
	}
	local scarySounds = {
		"5710016194",
		"161964303",
		"126552929107766",
		"84131007103998",
		"123124825019861",
		"81987511375108",
	}
	local crucifyConnections = {}
	local hangConnections = {}

	local function runPaniniOnPlayer(target)
		if not target then
			return
		end
		if target ~= localPlayer then
			return
		end
		local targetGui = (gethui and gethui()) or localPlayer:FindFirstChildOfClass("PlayerGui") or coreGui
		if not targetGui then
			return
		end
		local oldSg = targetGui:FindFirstChild("PaniniFlash")
		if oldSg then
			oldSg:Destroy()
		end
		local sg = Instance.new("ScreenGui")
		sg.Name = "PaniniFlash"
		sg.IgnoreGuiInset = true
		sg.DisplayOrder = 999999
		sg.ResetOnSpawn = false
		sg.Parent = targetGui
		local img = Instance.new("ImageLabel", sg)
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 0
		img.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		img.Image = "rbxassetid://106404414030833"
		img.ScaleType = Enum.ScaleType.Fit
		img.ZIndex = 999999
		local s = Instance.new("Sound", soundService)
		s.SoundId = "rbxassetid://6770036737"
		s.Volume = 0.5
		s:Play()
		task.delay(1.8, function()
			if img and img.Parent then
				tweenService
					:Create(img, TweenInfo.new(0.5), { ImageTransparency = 1, BackgroundTransparency = 1 })
					:Play()
			end
		end)
		task.delay(2.5, function()
			if sg and sg.Parent then
				sg:Destroy()
			end
			if s and s.Parent then
				s:Destroy()
			end
		end)
	end

	local function stopCharacterTracks(hum)
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function()
					track:Stop()
				end)
			end
		end
	end

	local function alignAndFreeze(target, targetCFrame, isHang)
		if not target or not target.Character then
			return
		end
		local char = target.Character
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			stopCharacterTracks(hum)
			hum.PlatformStand = true
			pcall(function()
				local animScript = char:FindFirstChild("Animate")
				if animScript then
					animScript.Disabled = true
				end
			end)
		end
		local anchorPart
		if isHang then
			anchorPart = char:FindFirstChild("Head")
		end
		if not anchorPart then
			anchorPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = (part == anchorPart)
				part.Velocity = Vector3.zero
				part.RotVelocity = Vector3.zero
				pcall(function()
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end
		if anchorPart then
			pcall(function()
				anchorPart.CFrame = targetCFrame
			end)
		end
	end

	local function unalignAndThaw(target)
		if not target or not target.Character then
			return
		end
		local char = target.Character
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			pcall(function()
				local animScript = char:FindFirstChild("Animate")
				if animScript then
					animScript.Disabled = false
				end
			end)
		end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
	end

	local function runCrucifyOnPlayer(target)
		if not target or not target.Character then
			return
		end
		local char = target.Character
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then
			return
		end
		if crucifyConnections[target.Name] then
			pcall(function()
				crucifyConnections[target.Name]:Disconnect()
			end)
			crucifyConnections[target.Name] = nil
		end
		local oldCross = workspace:FindFirstChild("Crucifix_" .. target.Name)
		if oldCross then
			oldCross:Destroy()
		end
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { char }
		local rayResult = workspace:Raycast(hrp.Position, Vector3.new(0, -300, 0), rayParams)
		local floorY = rayResult and rayResult.Position.Y or (hrp.Position.Y - 3)
		local groundCF = CFrame.new(hrp.Position.X, floorY, hrp.Position.Z)
			* CFrame.Angles(0, math.atan2(-hrp.CFrame.LookVector.X, -hrp.CFrame.LookVector.Z), 0)
		local crossModel = Instance.new("Model")
		crossModel.Name = "Crucifix_" .. target.Name
		local base = Instance.new("Part")
		base.Size = Vector3.new(3.5, 0.6, 3.5)
		base.Material = Enum.Material.Wood
		base.Color = Color3.fromRGB(75, 45, 25)
		base.Anchored = true
		base.CanCollide = false
		base.CFrame = groundCF * CFrame.new(0, 0.3, 0)
		base.Parent = crossModel
		local vert = Instance.new("Part")
		vert.Size = Vector3.new(1.2, 10, 1.2)
		vert.Material = Enum.Material.Wood
		vert.Color = Color3.fromRGB(90, 55, 30)
		vert.Anchored = true
		vert.CanCollide = false
		vert.CFrame = base.CFrame * CFrame.new(0, 5, 0)
		vert.Parent = crossModel
		local horiz = Instance.new("Part")
		horiz.Size = Vector3.new(7.5, 1.2, 1.2)
		horiz.Material = Enum.Material.Wood
		horiz.Color = Color3.fromRGB(90, 55, 30)
		horiz.Anchored = true
		horiz.CanCollide = false
		horiz.CFrame = vert.CFrame * CFrame.new(0, 2.5, 0)
		horiz.Parent = crossModel
		Instance.new("Fire", base).Size = 14
		Instance.new("Fire", vert).Size = 12
		Instance.new("Fire", horiz).Size = 10
		local light = Instance.new("PointLight", vert)
		light.Color = Color3.fromRGB(255, 120, 30)
		light.Range = 25
		light.Brightness = 3
		crossModel.Parent = workspace
		local targetCFrame = vert.CFrame * CFrame.new(0, 1.2, 0.85) * CFrame.Angles(0, math.pi, 0)
		alignAndFreeze(target, targetCFrame)

		local function applyTPose()
			if not char or not char.Parent then
				return
			end
			for _, desc in ipairs(char:GetDescendants()) do
				if desc:IsA("Motor6D") then
					local n = desc.Name:lower()
					if
						(n:find("left") and (n:find("shoulder") or n:find("upperarm")))
						or desc.Name == "LeftShoulder"
						or desc.Name == "Left Shoulder"
					then
						pcall(function()
							desc.Transform = CFrame.Angles(0, 0, math.rad(-90))
						end)
					elseif
						(n:find("right") and (n:find("shoulder") or n:find("upperarm")))
						or desc.Name == "RightShoulder"
						or desc.Name == "Right Shoulder"
					then
						pcall(function()
							desc.Transform = CFrame.Angles(0, 0, math.rad(90))
						end)
					elseif n:find("elbow") or n:find("wrist") or n:find("lowerarm") or n:find("hand") then
						pcall(function()
							desc.Transform = CFrame.identity
						end)
					end
				end
			end
		end
		applyTPose()
		local cachedParts, cachedMotors = {}, {}

		local function cacheDescendants()
			cachedParts, cachedMotors = {}, {}
			for _, desc in ipairs(char:GetDescendants()) do
				if desc:IsA("BasePart") then
					table.insert(cachedParts, desc)
				elseif desc:IsA("Motor6D") then
					table.insert(cachedMotors, desc)
				end
			end
		end
		cacheDescendants()
		local cacheConn = char.DescendantAdded:Connect(function()
			task.defer(cacheDescendants)
		end)
		crucifyConnections[target.Name .. "_cache"] = cacheConn
		crucifyConnections[target.Name] = runService.RenderStepped:Connect(function()
			LPS_ATTRIBUTES(VM(NONE))
			if not char or not char.Parent or not hrp or not hrp.Parent then
				if runUncrucifyOnPlayer then
					runUncrucifyOnPlayer(target)
				end
				return
			end
			local anchorPart = char:FindFirstChild("Head")
				or char:FindFirstChild("HumanoidRootPart")
				or char:FindFirstChild("Torso")
			for _, part in ipairs(cachedParts) do
				if part.Parent then
					part.Anchored = (part == anchorPart)
					part.Velocity = Vector3.zero
					part.RotVelocity = Vector3.zero
				end
			end
			if anchorPart then
				pcall(function()
					anchorPart.CFrame = targetCFrame
				end)
			end
			for _, desc in ipairs(cachedMotors) do
				if desc.Parent then
					local n = desc.Name:lower()
					if
						(n:find("left") and (n:find("shoulder") or n:find("upperarm")))
						or desc.Name == "LeftShoulder"
						or desc.Name == "Left Shoulder"
					then
						pcall(function()
							desc.Transform = CFrame.Angles(0, 0, math.rad(-90))
						end)
					elseif
						(n:find("right") and (n:find("shoulder") or n:find("upperarm")))
						or desc.Name == "RightShoulder"
						or desc.Name == "Right Shoulder"
					then
						pcall(function()
							desc.Transform = CFrame.Angles(0, 0, math.rad(90))
						end)
					elseif n:find("elbow") or n:find("wrist") or n:find("lowerarm") or n:find("hand") then
						pcall(function()
							desc.Transform = CFrame.identity
						end)
					end
				end
			end
		end)
	end
	runUncrucifyOnPlayer = function(target)
		if not target then
			return
		end
		if crucifyConnections[target.Name] then
			pcall(function()
				crucifyConnections[target.Name]:Disconnect()
			end)
			crucifyConnections[target.Name] = nil
		end
		unalignAndThaw(target)
		local char = target.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and target == localPlayer then
				hum.Sit = false
				hum.AutoRotate = true
				pcall(function()
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end)
			end
			for _, desc in ipairs(char:GetDescendants()) do
				if desc:IsA("Motor6D") then
					pcall(function()
						desc.Transform = CFrame.identity
					end)
				end
			end
		end
		local crossModel = workspace:FindFirstChild("Crucifix_" .. target.Name)
		if crossModel then
			crossModel:Destroy()
		end
	end

	local function runHangOnPlayer(target)
		if not target or not target.Character then
			return
		end
		local char = target.Character
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then
			return
		end
		if hangConnections[target.Name] then
			pcall(function()
				hangConnections[target.Name]:Disconnect()
			end)
			hangConnections[target.Name] = nil
		end
		local oldGallows = workspace:FindFirstChild("Gallows_" .. target.Name)
		if oldGallows then
			oldGallows:Destroy()
		end
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { char }
		local rayResult = workspace:Raycast(hrp.Position, Vector3.new(0, -300, 0), rayParams)
		local floorY = rayResult and rayResult.Position.Y or (hrp.Position.Y - 3)
		local groundCF = CFrame.new(hrp.Position.X, floorY, hrp.Position.Z)
			* CFrame.Angles(0, math.atan2(-hrp.CFrame.LookVector.X, -hrp.CFrame.LookVector.Z), 0)
		local gallows = Instance.new("Model")
		gallows.Name = "Gallows_" .. target.Name
		local p1 = Instance.new("Part")
		p1.Size = Vector3.new(1, 10.5, 1)
		p1.Material = Enum.Material.Wood
		p1.Color = Color3.fromRGB(80, 50, 25)
		p1.Anchored = true
		p1.CanCollide = false
		p1.CFrame = groundCF * CFrame.new(-3, 5.25, 0)
		p1.Parent = gallows
		local p2 = Instance.new("Part")
		p2.Size = Vector3.new(1, 10.5, 1)
		p2.Material = Enum.Material.Wood
		p2.Color = Color3.fromRGB(80, 50, 25)
		p2.Anchored = true
		p2.CanCollide = false
		p2.CFrame = groundCF * CFrame.new(3, 5.25, 0)
		p2.Parent = gallows
		local top = Instance.new("Part")
		top.Size = Vector3.new(7, 1, 1)
		top.Material = Enum.Material.Wood
		top.Color = Color3.fromRGB(80, 50, 25)
		top.Anchored = true
		top.CanCollide = false
		top.CFrame = groundCF * CFrame.new(0, 10.75, 0)
		top.Parent = gallows
		local noose = Instance.new("Part")
		noose.Size = Vector3.new(0.3, 4.2, 0.3)
		noose.Material = Enum.Material.Fabric
		noose.Color = Color3.fromRGB(180, 160, 120)
		noose.Anchored = true
		noose.CanCollide = false
		noose.CFrame = top.CFrame * CFrame.new(0, -2.6, 0)
		noose.Parent = gallows
		gallows.Parent = workspace
		local targetCFrame = noose.CFrame * CFrame.new(0, -1.2, 0)
		alignAndFreeze(target, targetCFrame, true)
		hangConnections[target.Name] = runService.Stepped:Connect(function()
			LPS_ATTRIBUTES(VM(NONE))
			if not char or not char.Parent or not hrp or not hrp.Parent then
				if runUnhangOnPlayer then
					runUnhangOnPlayer(target)
				end
				return
			end
			alignAndFreeze(target, targetCFrame, true)
		end)
	end
	runUnhangOnPlayer = function(target)
		if not target then
			return
		end
		if hangConnections[target.Name] then
			pcall(function()
				hangConnections[target.Name]:Disconnect()
			end)
			hangConnections[target.Name] = nil
		end
		unalignAndThaw(target)
		local char = target.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and target == localPlayer then
				hum.Sit = false
				hum.AutoRotate = true
				pcall(function()
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end)
			end
		end
		local gallows = workspace:FindFirstChild("Gallows_" .. target.Name)
		if gallows then
			gallows:Destroy()
		end
	end
	local dragModeActive = false
	local currentDraggedPlayer = nil
	local dragDistance = 25
	local dragActiveConnections = {}
	local armedDragTargets = {}
	local dragThrowVelocities = {}

	local function sendWsCommand(commandStr)
		if _G.SlateActiveWS then
			pcall(function()
				_G.SlateActiveWS:Send(httpService:JSONEncode({
					type = "command",
					command = commandStr,
					sender = localPlayer.Name,
					from_user = localPlayer.Name,
					userId = localPlayer.UserId,
				}))
			end)
		end
	end

	local function getTargetModelsAndRoots(target)
		local models, roots = {}, {}
		if not target then
			return models, roots
		end
		if target.Character and target.Character.Parent then
			table.insert(models, target.Character)
			local hrp = target.Character:FindFirstChild("HumanoidRootPart")
				or target.Character:FindFirstChild("Torso")
				or target.Character:FindFirstChild("UpperTorso")
				or target.Character.PrimaryPart
				or target.Character:FindFirstChild("Head")
				or target.Character:FindFirstChildWhichIsA("BasePart")
			if hrp and hrp:IsA("BasePart") then
				table.insert(roots, hrp)
			end
		end
		return models, roots
	end

	local function stopDraggingPlayer(target, applyThrow)
		if not target then
			return
		end
		if dragActiveConnections[target.Name] then
			pcall(function()
				dragActiveConnections[target.Name]:Disconnect()
			end)
			dragActiveConnections[target.Name] = nil
		end
		if currentDraggedPlayer == target then
			currentDraggedPlayer = nil
		end
		local throwVel = dragThrowVelocities[target.Name] or Vector3.zero
		dragThrowVelocities[target.Name] = nil
		local shouldFling = applyThrow and (throwVel.Magnitude > 15)
		if shouldFling then
			local maxSpeed = 300
			if throwVel.Magnitude > maxSpeed then
				throwVel = throwVel.Unit * maxSpeed
			end
			local throwVector = throwVel * 1.25 + Vector3.new(0, math.clamp(throwVel.Magnitude * 0.15, 6, 35), 0)
			if target ~= localPlayer then
				sendWsCommand(
					string.format(
						".dragthrow %s %.2f %.2f %.2f",
						target.Name,
						throwVector.X,
						throwVector.Y,
						throwVector.Z
					)
				)
			end
			local _, roots = getTargetModelsAndRoots(target)
			for _, root in ipairs(roots) do
				if root and root.Parent then
					root.Anchored = false
					pcall(function()
						root.AssemblyLinearVelocity = throwVector
					end)
				end
			end
		else
			if target ~= localPlayer then
				sendWsCommand(".dragstop " .. target.Name)
			end
			local _, roots = getTargetModelsAndRoots(target)
			for _, root in ipairs(roots) do
				if root and root.Parent then
					root.Anchored = false
					pcall(function()
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
					end)
				end
			end
		end
	end
	stopAllDragging = function()
		for name, conn in pairs(dragActiveConnections) do
			pcall(function()
				conn:Disconnect()
			end)
			local p = players:FindFirstChild(name)
			if p then
				stopDraggingPlayer(p, false)
			end
		end
		dragActiveConnections = {}
		currentDraggedPlayer = nil
		armedDragTargets = {}
		dragThrowVelocities = {}
	end

	local function startDraggingPlayer(target)
		if not target then
			return
		end
		local targetModels, targetRoots = getTargetModelsAndRoots(target)
		if #targetRoots == 0 then
			return
		end
		local mainHrp = targetRoots[1]
		stopDraggingPlayer(target, false)
		currentDraggedPlayer = target
		local cam = workspace.CurrentCamera or camera
		local initialDist = (mainHrp.Position - cam.CFrame.Position).Magnitude
		dragDistance = math.clamp(initialDist, 6, 120)
		if target ~= localPlayer then
			sendWsCommand(".dragstart " .. target.Name)
		end
		local lastWsSend = 0
		local lastPos = mainHrp.Position
		local lastPosTime = tick()
		local recentVelocities = {}
		local conn
		conn = runService.RenderStepped:Connect(function(dt)
			LPS_ATTRIBUTES(VM(NONE))
			if not target.Parent or not mainHrp or not mainHrp.Parent then
				stopDraggingPlayer(target, false)
				return
			end
			local mousePos = userInputService:GetMouseLocation()
			local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local excludeList = {}
			for _, m in ipairs(targetModels) do
				table.insert(excludeList, m)
			end
			if localPlayer.Character and localPlayer ~= target then
				table.insert(excludeList, localPlayer.Character)
			end
			rayParams.FilterDescendantsInstances = excludeList
			local rayResult = workspace:Raycast(ray.Origin, ray.Direction * dragDistance, rayParams)
			local targetPos = rayResult and (rayResult.Position + rayResult.Normal * 2.2)
				or (ray.Origin + ray.Direction * dragDistance)
			local targetCF = CFrame.new(targetPos, targetPos + cam.CFrame.LookVector)
			local _, curRoots = getTargetModelsAndRoots(target)
			if #curRoots == 0 then
				curRoots = targetRoots
			end
			for _, hrp in ipairs(curRoots) do
				if hrp and hrp.Parent then
					hrp.Anchored = (target == localPlayer)
					hrp.CFrame = targetCF
					pcall(function()
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					end)
				end
			end
			local now = tick()
			local timeDelta = now - lastPosTime
			if timeDelta > 0.001 then
				local instVel = (targetPos - lastPos) / timeDelta
				lastPos = targetPos
				lastPosTime = now
				table.insert(recentVelocities, { vel = instVel, t = now })
				while #recentVelocities > 0 and (now - recentVelocities[1].t) > 0.12 do
					table.remove(recentVelocities, 1)
				end
				local avgVel = Vector3.zero
				for _, s in ipairs(recentVelocities) do
					avgVel = avgVel + s.vel
				end
				if #recentVelocities > 0 then
					avgVel = avgVel / #recentVelocities
				end
				dragThrowVelocities[target.Name] = avgVel
			end
			if target ~= localPlayer and now - lastWsSend >= 0.03 then
				lastWsSend = now
				sendWsCommand(
					string.format(".dragpos %s %.2f %.2f %.2f", target.Name, targetPos.X, targetPos.Y, targetPos.Z)
				)
			end
		end)
		dragActiveConnections[target.Name] = conn
	end

	do
	local function resolvePlayerFromInstance(inst)
		if not inst then
			return nil
		end
		local model = inst:FindFirstAncestorOfClass("Model")
		while model and model ~= workspace do
			local p = players:GetPlayerFromCharacter(model)
			if p then
				return p
			end
			for _, player in ipairs(players:GetPlayers()) do
				if player.Name:lower() == model.Name:lower() then
					return player
				end
			end
			model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
		end
		return nil
	end

	local function getPlayerUnderMouse()
		local mouse = localPlayer:GetMouse()
		if mouse and mouse.Target then
			local p = resolvePlayerFromInstance(mouse.Target)
			if p then
				return p
			end
		end
		return nil
	end
	local isMouseDown = false
	local mouseClickConn = userInputService.InputBegan:Connect(function(input)
		if userInputService:GetFocusedTextBox() then
			return
		end
		if not isAnyWhitelisted(localPlayer.UserId) then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if dragModeActive or next(armedDragTargets) then
				local targetP = getPlayerUnderMouse()
				if targetP and (dragModeActive or armedDragTargets[targetP.Name] == true) then
					isMouseDown = true
					startDraggingPlayer(targetP)
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			if currentDraggedPlayer and isMouseDown then
				dragDistance = math.clamp(dragDistance + (input.Position.Z * 4), 4, 250)
			end
		end
	end)
	table.insert(connections, mouseClickConn)
	local mouseUpConn = userInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			isMouseDown = false
			if currentDraggedPlayer then
				stopDraggingPlayer(currentDraggedPlayer, true)
			end
		end
	end)
	table.insert(connections, mouseUpConn)
	end

	local function playFlashbang(options)
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local screenGui = Instance.new("ScreenGui", playerGui)
		screenGui.IgnoreGuiInset = true
		screenGui.DisplayOrder = 999999
		screenGui.ResetOnSpawn = false
		local imageLabel = Instance.new("ImageLabel", screenGui)
		imageLabel.Size = UDim2.fromScale(1, 1)
		imageLabel.BackgroundTransparency = 1
		imageLabel.Image = options.imageId
		imageLabel.ImageTransparency = 1
		imageLabel.ZIndex = 999999
		local whiteFrame = Instance.new("Frame", screenGui)
		whiteFrame.Size = UDim2.fromScale(1, 1)
		whiteFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		whiteFrame.BackgroundTransparency = 1
		whiteFrame.ZIndex = 999998
		local sound = Instance.new("Sound", soundService)
		sound.SoundId = options.soundId
		sound.Volume = options.volume or 10
		sound:Play()
		tweenService:Create(imageLabel, TweenInfo.new(0.1), { ImageTransparency = 0 }):Play()
		task.wait(options.imageTime or 1)
		imageLabel.ImageTransparency = 1
		whiteFrame.BackgroundTransparency = 0
		task.wait(math.max(sound.TimeLength - 0.5, 0))
		screenGui:Destroy()
		sound:Destroy()
	end

	local function addConnection(A, Callback)
		local connection = A:Connect(Callback)
		connections[#connections + 1] = connection
		return connection
	end

	local function compareText(original, comparison)
		return string.match(string.lower(tostring(original)), string.lower(tostring(comparison)))
	end

	local function getPlayer(input, ignoreSelf)
		if not input or type(tonumber(input)) == "number" then
			return false
		end
		for _, v in ipairs(players:GetPlayers()) do
			if
				(not ignoreSelf or v ~= localPlayer)
				and (compareText(tostring(v), input) or compareText(v.DisplayName, input))
			then
				return v
			end
		end
		return false
	end

	local function registerCommand(commandName, commandAliases, requireArguments, commandCallback, isAdminCommand)
		commandName = string.lower(commandName)
		commands[commandName] = {
			name = commandName,
			func = commandCallback,
			requireArguments = requireArguments,
			isAdminCommand = isAdminCommand,
		}
		for i = 1, #commandAliases do
			aliases[string.lower(commandAliases[i])] = commandName
		end
	end

	local function handleMessage(caller, message)
		if type(message) ~= "string" or #message <= 1 or string.sub(message, 1, 1) ~= "." then
			return
		end
		local arguments = string.split(string.sub(message, 2), " ")
		local executedCommand = string.lower(arguments[1])
		local commandData = commands[executedCommand]
			or (aliases[executedCommand] and commands[aliases[executedCommand]])
			or false
		if not commandData then
			return
		end
		if commandData.requireArguments and not arguments[2] then
			return
		end
		if
			commandData.requireArguments
			and arguments[2] ~= "*"
			and (
				not compareText(tostring(localPlayer), arguments[2])
				and not compareText(localPlayer.DisplayName, arguments[2])
			)
		then
			return
		end
		local callArguments = {}
		for i = commandData.requireArguments and 3 or 2, #arguments do
			callArguments[#callArguments + 1] = arguments[i]
		end
		local isUserOwner = cmdIsWhitelisted(caller.UserId)
		local isUserWhitelisted = cmdIsSecondaryWhitelisted(caller.UserId)
		if cmdIsImmuneWhitelisted(localPlayer.UserId) and caller ~= localPlayer then
			return
		end
		if commandData.isAdminCommand and not isUserOwner then
			return
		end
		if commandData.name == "whitelist" or commandData.name == "unwhitelist" then
			if not (isUserOwner or cmdIsAdminWhitelisted(caller.UserId)) then
				return
			end
		end
		if isUserWhitelisted and cmdIsWhitelisted(localPlayer.UserId) then
			return
		end
		pcall(commandData.func, caller, table.unpack(callArguments))
	end
	_G.SlateHandleMessage = handleMessage
	_G.handleMessage = handleMessage

	local function sendChat(message)
		if not message or #message == 0 then
			return
		end
		if isLegacyChat then
			local chatRemote = replicatedStorage:FindFirstChild("SayMessageRequest", true)
			if chatRemote then
				return chatRemote:FireServer(message, "All")
			end
			return
		end
		local ok = pcall(function()
			local textChannels = textChatService:FindFirstChild("TextChannels")
			local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")
			if generalChannel then
				generalChannel:SendAsync(message)
			else
				local chat = textChatService.ChatInputBarConfiguration.TargetTextChannel
				if chat then
					chat:SendAsync(message)
				end
			end
		end)
		return ok
	end

	local function playSound(id)
		local sound = Instance.new("Sound", soundService)
		sound.SoundId = "rbxassetid://" .. id
		sound.Volume = 100
		sound:Play()
		task.spawn(function()
			task.wait(0.5)
			task.wait(math.max(sound.TimeLength - 0.5, 0))
			sound:Destroy()
		end)
	end
	registerCommand("kick", { "ban" }, true, function(_, ...)
		localPlayer:Kick(select("#", ...) > 0 and table.concat({ ... }, " ") or "")
	end)
	registerCommand("chat", { "ch", "say" }, true, function(_, ...)
		sendChat(select("#", ...) > 0 and table.concat({ ... }, " ") or "Hello!")
	end)
	registerCommand("crash", {}, true, function()
		while true do
		end
	end, true)
	registerCommand("close", { "shutdown" }, true, function()
		game:Shutdown()
	end, true)
	registerCommand("bring", { "br" }, true, function(caller)
		if caller == localPlayer then
			return
		end
		if
			not (
				caller.Character
				and caller.Character:FindFirstChildOfClass("Humanoid")
				and caller.Character:FindFirstChildOfClass("Humanoid").RootPart
			)
		then
			return
		end
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			if Anchored then
				hrp.Anchored = false
				task.wait(0.1)
			end
			hrp.CFrame = caller.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame
			if Anchored then
				task.wait(0.1)
				hrp.Anchored = true
			end
		end
	end)
	registerCommand("kill", {}, true, function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = 0
		end
	end)
	registerCommand("reset", { "re" }, true, function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = hum and hum.RootPart
		if hum and hrp then
			local oldPos = hrp.CFrame
			hum.Health = 0
			players.LocalPlayer.CharacterAdded:Wait()
			task.spawn(function()
				local newChar = players.LocalPlayer.Character
				local newHrp = newChar and newChar:WaitForChild("HumanoidRootPart", 10)
				if newHrp then
					newHrp.CFrame = oldPos
				end
			end)
		end
	end)
	registerCommand("flashbang", { "fb" }, true, function()
		playFlashbang({
			imageId = "rbxassetid://11088883735",
			soundId = "rbxassetid://129172304986568",
			imageTime = 1,
			whiteFadeTime = 0.2,
			volume = 10,
		})
	end)
	registerCommand("freeze", { "lock" }, true, function()
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			Anchored = true
			hrp.Anchored = true
		end
	end)
	registerCommand("thaw", { "unfreeze", "unlock" }, true, function()
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			Anchored = false
			hrp.Anchored = false
		end
	end)
	registerCommand("jump", { "jmp", "unsit" }, true, function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = false
			pcall(function()
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end)
		end
	end)
	registerCommand("sit", {}, true, function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = true
		end
	end)
	registerCommand("fling", { "fl", "yeet" }, true, function()
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(math.random(-100, 100), math.random(50, 150), math.random(-100, 100))
			bv.MaxForce = Vector3.new(1e200, 1e200, 1e200)
			bv.Parent = hrp
			debris:AddItem(bv, 0.5)
		end
	end)
	registerCommand("fling2", { "fl2", "yeet2" }, true, function()
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(math.random(-1000, 1000), math.random(-1000, 1000), math.random(-1000, 1000))
			bv.MaxForce = Vector3.new(1e200, 1e200, 1e200)
			bv.Parent = hrp
			debris:AddItem(bv, 0.5)
		end
	end)
	registerCommand("trip", {}, true, function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp then
			hum.PlatformStand = true
			hrp.Velocity = hrp.CFrame.LookVector * 10 + Vector3.new(0, 10, 0)
			hrp.CFrame = hrp.CFrame * CFrame.Angles(90, 90, 90)
			task.wait(2)
			hum.PlatformStand = false
		end
	end)
	for i, v in pairs(audioCommands) do
		registerCommand(i, v[2], true, function()
			playSound(v[1])
		end)
	end
	registerCommand("blur", { "blr" }, true, function(_, amount)
		local blurEffect = Instance.new("BlurEffect", lighting)
		blurEffect.Size = tonumber(amount) or 15
		task.wait(10)
		blurEffect:Destroy()
	end)
	registerCommand("earthquake", { "quake" }, true, function(_, amount)
		local duration = tonumber(amount) or 10
		local startTime = tick()
		local conn
		conn = runService.RenderStepped:Connect(function()
			LPS_ATTRIBUTES(VM(NONE))
			if tick() - startTime > duration then
				conn:Disconnect()
				return
			end
			local cam = workspace.CurrentCamera or camera
			cam.CFrame = cam.CFrame * CFrame.new(math.random(-2, 2) / 10, math.random(-2, 2) / 10, 0)
		end)
	end)
	for i = 1, 3 do
		local num = i == 1 and "" or tostring(i)
		registerCommand("dance" .. num, { "dnc" .. num }, true, function()
			sendChat("/e dance" .. num)
		end)
	end
	registerCommand("jumpscare", { "jp", "lol" }, true, function()
		local selectedSound = "rbxassetid://" .. scarySounds[math.random(1, #scarySounds)]
		local selectedFace = "rbxassetid://" .. scaryFaces[math.random(1, #scaryFaces)]
		local host = (gethui and gethui()) or coreGui
		local jumpscareGui = Instance.new("ScreenGui", host)
		jumpscareGui.DisplayOrder = 10
		jumpscareGui.ResetOnSpawn = false
		jumpscareGui.IgnoreGuiInset = true
		local image = Instance.new("ImageLabel", jumpscareGui)
		image.Size = UDim2.new(1, 0, 1, 0)
		image.Image = selectedFace
		image.BackgroundTransparency = 0.99
		local sound = Instance.new("Sound", soundService)
		sound.SoundId = selectedSound
		sound.Volume = 100
		task.spawn(function()
			sound:Play()
			task.wait(sound.TimeLength >= 3 and 3 or math.max(sound.TimeLength, 0.5))
			jumpscareGui:Destroy()
			sound:Destroy()
		end)
	end, true)
	registerCommand("secretplace", { "sp", "secret" }, true, function()
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(-136, 4, 72240)
		end
	end)
	registerCommand("follow", {}, true, function(caller, targetName)
		local target = getPlayer(targetName) or caller
		if target then
			following, followTarget = true, target
		end
	end)
	registerCommand("unfollow", {}, true, function()
		following, followTarget = false, nil
	end)
	registerCommand("walkspeed", { "speed", "ws" }, true, function(_, speedStr)
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = tonumber(speedStr) or 16
		end
	end)
	registerCommand("rejoin", { "rj" }, true, function()
		rejoin()
	end)
	registerCommand("stun", {}, true, function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = true
		end
	end)
	registerCommand("unstun", {}, true, function()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
		end
	end)
	registerCommand("loopkill", { "lp" }, true, function()
		looping[localPlayer.UserId] = { type = "kill", target = localPlayer }
	end, true)
	registerCommand("unloopkill", { "unlp" }, true, function()
		looping[localPlayer.UserId] = nil
	end, true)
	task.spawn(function()
		LPS_ATTRIBUTES(VM(NONE))
		while true do
			local entry = looping[localPlayer.UserId]
			if entry and entry.type == "kill" then
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = 0
				end
			end
			task.wait(0.5)
		end
	end)
	registerCommand("drunk", { "dr" }, true, function()
		pcall(function()
			local drunkScript = game:HttpGet(LPS_ENCSTR("https://ib2.dev/absent/lua/drunk.lua"))
			if drunkScript ~= "" then
				loadstring(drunkScript)()
			end
		end)
	end)
	registerCommand("high", { "hh" }, true, function()
		pcall(function()
			local drunkScript = game:HttpGet(LPS_ENCSTR("https://ib2.dev/absent/lua/drunk.lua"))
			if drunkScript ~= "" then
				loadstring(string.rep(string.format("task.spawn(function() %s end);", drunkScript), 15))()
			end
		end)
	end)
	local oldMovement
	registerCommand("invert", { "inv" }, true, function()
		local movementController =
			require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		if not oldMovement then
			oldMovement = movementController.moveFunction
		end
		movementController.moveFunction = function(player, direction, relative)
			player.Move(player, -direction, relative)
		end
		task.spawn(function()
			task.wait(10)
			movementController.moveFunction = oldMovement
		end)
	end)
	registerCommand("unwalk", { "uwlk", "unwlk", "uwk" }, true, function()
		local movementController =
			require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		if not oldMovement then
			oldMovement = movementController.moveFunction
		end
		movementController.moveFunction = function(player, direction, relative)
			player.Move(player, Vector3.new(0, 0, 0), relative)
		end
	end)
	registerCommand("uninvert", { "wlk", "walk", "uninv" }, true, function()
		local movementController =
			require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
		if not oldMovement then
			oldMovement = movementController.moveFunction
		end
		movementController.moveFunction = oldMovement
			or function(player, direction, relative)
				player.Move(player, direction, relative)
			end
	end)
	registerCommand("mute", { "m" }, true, function()
		pcall(function()
			if voiceChatService then
				voiceChatService:getInternalGroupId()
				voiceChatService:getInternalSessionId()
			end
			if voiceChatInternal then
				voiceChatInternal:PublishPause(true)
			end
		end)
	end)
	registerCommand("unmute", { "um" }, true, function()
		pcall(function()
			if voiceChatService then
				voiceChatService:getInternalGroupId()
				voiceChatService:getInternalSessionId()
			end
			if voiceChatInternal then
				voiceChatInternal:PublishPause(true)
				task.wait(1)
				voiceChatInternal:PublishPause(false)
			end
		end)
	end)
	registerCommand("walkto", {}, true, function(caller, destName)
		local dest = getPlayer(destName) or caller
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and dest and dest.Character and dest.Character:FindFirstChild("HumanoidRootPart") then
			hum:MoveTo(dest.Character.HumanoidRootPart.Position)
		end
	end)
	registerCommand("orbit", {}, true, function(caller, aroundName)
		local around = getPlayer(aroundName) or caller
		local amount = tonumber(aroundName) or 5
		task.spawn(function()
			for i = 1, 360 * amount do
				local char = localPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and around and around.Character and around.Character:FindFirstChild("HumanoidRootPart") then
					local angle = math.rad(i)
					local target = around.Character.HumanoidRootPart.Position
					local x = target.X + math.cos(angle) * 10
					local z = target.Z + math.sin(angle) * 10
					local currentRotation = hrp.CFrame - hrp.Position
					hrp.CFrame = CFrame.new(x, target.Y, z) * currentRotation
					task.wait()
				end
			end
		end)
	end)
	registerCommand("circle", {}, true, function(_, amount)
		local amt = tonumber(amount) or 5
		task.spawn(function()
			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				return
			end
			local startPos = hrp.Position
			for i = 1, 360 * amt do
				if hrp and hrp.Parent then
					local angle = math.rad(i)
					local x = startPos.X + math.cos(angle) * 5
					local z = startPos.Z + math.sin(angle) * 5
					local currentRotation = hrp.CFrame - hrp.Position
					hrp.CFrame = CFrame.new(x, startPos.Y, z) * currentRotation
					task.wait(0)
				end
			end
		end)
	end)
	registerCommand("beyblade", { "bb" }, true, function()
		task.spawn(function()
			for i = 1, 360 do
				local char = localPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(i), 0)
					task.wait(0.015)
				end
			end
		end)
	end)
	registerCommand("spin", {}, true, function()
		task.spawn(function()
			for i = 1, 36 do
				local char = localPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(10), 0)
					task.wait(0.05)
				end
			end
		end)
	end)
	registerCommand("panini", {}, false, function(_, targetName)
		local target = getPlayer(targetName)
		if target then
			runPaniniOnPlayer(target)
		end
	end)
	registerCommand("crucify", {}, false, function(_, targetName)
		local target = getPlayer(targetName)
		if target then
			runCrucifyOnPlayer(target)
		end
	end)
	registerCommand("uncrucify", {}, false, function(_, targetName)
		local target = getPlayer(targetName)
		if target then
			runUncrucifyOnPlayer(target)
		end
	end)
	registerCommand("hang", {}, false, function(_, targetName)
		local target = getPlayer(targetName)
		if target then
			runHangOnPlayer(target)
		end
	end)
	registerCommand("unhang", {}, false, function(_, targetName)
		local target = getPlayer(targetName)
		if target then
			runUnhangOnPlayer(target)
		end
	end)
	do
	local auras = {}
	local loadAura
	local activeAuras = {}
	registerCommand("aura", { "ar" }, false, function(_, targetName, auraName)
		local target = getPlayer(targetName)
		if not target or not auraName then
			return
		end
		if not next(auras) then
			pcall(function()
				auras = httpService:JSONDecode(game:HttpGet(LPS_ENCSTR("https://scripts.ib2.dev/auras.json")))
			end)
		end
		if type(loadAura) ~= "function" then
			pcall(function()
				loadAura = loadstring(game:HttpGet(LPS_ENCSTR("https://scripts.ib2.dev/auraloader.lua")))()
			end)
		end
		if activeAuras[target.UserId] then
			pcall(activeAuras[target.UserId].Destroy, activeAuras[target.UserId])
			activeAuras[target.UserId] = nil
		end
		local selectedAura = auras[auraName] or auras[auraName:lower()]
		if selectedAura and type(loadAura) == "function" then
			local root = target.Character
				and (target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso"))
			if root then
				local ok, res = pcall(loadAura, selectedAura, root)
				if ok and res then
					activeAuras[target.UserId] = res
				end
			end
		end
	end)
	registerCommand("unaura", { "unar" }, false, function(_, targetName)
		local target = getPlayer(targetName)
		if not target then
			return
		end
		if activeAuras[target.UserId] then
			pcall(activeAuras[target.UserId].Destroy, activeAuras[target.UserId])
			activeAuras[target.UserId] = nil
		end
	end)
	end
	do
	local isBeingDragged = false
	local networkDragTargetPos = nil
	local targetDragRenderConn = nil

	local function stopTargetDragRender()
		if targetDragRenderConn then
			pcall(function()
				targetDragRenderConn:Disconnect()
			end)
			targetDragRenderConn = nil
		end
		networkDragTargetPos = nil
	end
	registerCommand("dragstart", { "drgstart" }, true, function()
		isBeingDragged = true
		stopTargetDragRender()
		local _, roots = getTargetModelsAndRoots(localPlayer)
		if #roots > 0 then
			networkDragTargetPos = roots[1].Position
		end
		targetDragRenderConn = runService.RenderStepped:Connect(function(dt)
			LPS_ATTRIBUTES(VM(NONE))
			if not isBeingDragged then
				stopTargetDragRender()
				return
			end
			if networkDragTargetPos then
				local targetCF = CFrame.new(networkDragTargetPos)
				local alpha = math.clamp(dt * 35, 0.35, 1.0)
				local _, currentRoots = getTargetModelsAndRoots(localPlayer)
				for _, root in ipairs(currentRoots) do
					if root and root.Parent then
						root.Anchored = true
						root.CFrame = root.CFrame:Lerp(targetCF, alpha)
						pcall(function()
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
						end)
					end
				end
			end
		end)
	end, true)
	registerCommand("dragpos", { "drgpos", "dragto" }, true, function(_, x, y, z)
		if not isBeingDragged then
			return
		end
		local posX, posY, posZ = tonumber(x), tonumber(y), tonumber(z)
		if posX and posY and posZ then
			networkDragTargetPos = Vector3.new(posX, posY, posZ)
		end
	end, true)
	registerCommand("dragthrow", { "drgthrow" }, true, function(_, vx, vy, vz)
		isBeingDragged = false
		stopTargetDragRender()
		local x, y, z = tonumber(vx), tonumber(vy), tonumber(vz)
		if x and y and z then
			local throwVec = Vector3.new(x, y, z)
			local _, roots = getTargetModelsAndRoots(localPlayer)
			for _, root in ipairs(roots) do
				if root and root.Parent then
					root.Anchored = false
					pcall(function()
						root.AssemblyLinearVelocity = throwVec
					end)
				end
			end
		end
	end, true)
	registerCommand("dragstop", { "drgstop" }, true, function()
		isBeingDragged = false
		stopTargetDragRender()
		local _, roots = getTargetModelsAndRoots(localPlayer)
		for _, root in ipairs(roots) do
			if root and root.Parent then
				root.Anchored = false
				pcall(function()
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end
	end, true)
	end
	registerCommand("drag", { "dragperson", "drg", "mousedrag", "dragplayer" }, false, function(_, targetName)
		if targetName and targetName ~= "" and targetName ~= "*" then
			local target = getPlayer(targetName)
			if target then
				armedDragTargets[target.Name] = true
				_G.SlateDragEnabled = true
			end
		else
			dragModeActive = not dragModeActive
			_G.SlateDragEnabled = dragModeActive
			if not dragModeActive then
				stopAllDragging()
			end
		end
	end, true)
	registerCommand("undrag", { "undragperson", "undrg", "unmousedrag", "drop" }, false, function(_, targetName)
		if targetName and targetName ~= "" and targetName ~= "*" then
			local target = getPlayer(targetName)
			if target then
				armedDragTargets[target.Name] = nil
				stopDraggingPlayer(target)
				if not next(armedDragTargets) then
					dragModeActive = false
					_G.SlateDragEnabled = false
				end
			end
		else
			dragModeActive = false
			_G.SlateDragEnabled = false
			armedDragTargets = {}
			stopAllDragging()
		end
	end, true)
	registerCommand("whitelist", { "wl" }, true, function(caller, targetName)
		local target = getPlayer(targetName)
		if not target or target == localPlayer then
			return
		end
		if cmdIsWhitelisted(target.UserId) then
			return
		end
		CMD_SECONDARY_WHITELISTED_IDS[#CMD_SECONDARY_WHITELISTED_IDS + 1] = target.UserId
		sendChat(target.DisplayName .. " has been whitelisted by " .. caller.DisplayName .. "!")
	end, true)
	registerCommand("unwhitelist", { "unwl" }, true, function(caller, targetName)
		local target = getPlayer(targetName)
		if not target or target == localPlayer then
			return
		end
		local index = table.find(CMD_SECONDARY_WHITELISTED_IDS, target.UserId)
		if not index then
			return
		end
		table.remove(CMD_SECONDARY_WHITELISTED_IDS, index)
		sendChat(target.DisplayName .. " has been removed from whitelist by " .. caller.DisplayName .. "!")
	end, true)

	local wsActive = false
	local wsConnection = nil
	local wsInitReceived = false
	local lastWsMessageAt = 0

	local lastWsInboundAt = 0
	local setBackendStatus, destroyBackendToast
	do
		local backendStatus = nil
		local backendToastToken = 0
		local backendToastGui = targetUI:FindFirstChild("SlateBackendConnectionToast")
		if backendToastGui then
			backendToastGui:Destroy()
		end
		backendToastGui = Instance.new("ScreenGui")
		backendToastGui.Name = "SlateBackendConnectionToast"
		backendToastGui.IgnoreGuiInset = true
		backendToastGui.DisplayOrder = 10000
		backendToastGui.ResetOnSpawn = false
		backendToastGui.Parent = targetUI
		local backendToast = Instance.new("Frame")
		backendToast.Name = "Toast"
		backendToast.AnchorPoint = Vector2.new(1, 1)
		backendToast.Position = UDim2.new(1, 340, 1, -22)
		backendToast.Size = UDim2.fromOffset(300, 78)
		backendToast.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		backendToast.BackgroundTransparency = 0
		backendToast.BorderSizePixel = 0
		backendToast.Visible = false
		backendToast.Parent = backendToastGui
		Instance.new("UICorner", backendToast).CornerRadius = UDim.new(0, 8)
		local backendToastStroke = Instance.new("UIStroke", backendToast)
		backendToastStroke.Color = Color3.fromRGB(38, 38, 38)
		backendToastStroke.Transparency = 0
		backendToastStroke.Thickness = 1
		local backendToastLogo = Instance.new("ImageLabel", backendToast)
		backendToastLogo.Name = "SlateMark"
		backendToastLogo.BackgroundTransparency = 1
		backendToastLogo.Position = UDim2.fromOffset(16, 12)
		backendToastLogo.Size = UDim2.fromOffset(16, 16)
		backendToastLogo.Image = "rbxassetid://106790631609801"
		backendToastLogo.ImageColor3 = Color3.fromRGB(235, 235, 235)
		backendToastLogo.ImageTransparency = 0.08
		local backendToastEyebrow = Instance.new("TextLabel", backendToast)
		backendToastEyebrow.BackgroundTransparency = 1
		backendToastEyebrow.Position = UDim2.fromOffset(40, 12)
		backendToastEyebrow.Size = UDim2.new(1, -54, 0, 14)
		backendToastEyebrow.Font = Enum.Font.BuilderSansMedium
		backendToastEyebrow.TextSize = 9
		backendToastEyebrow.TextColor3 = Color3.fromRGB(130, 130, 130)
		backendToastEyebrow.TextXAlignment = Enum.TextXAlignment.Left
		backendToastEyebrow.Text = "SLATE  /  BACKEND"
		local backendToastTitle = Instance.new("TextLabel", backendToast)
		backendToastTitle.BackgroundTransparency = 1
		backendToastTitle.Position = UDim2.fromOffset(40, 31)
		backendToastTitle.Size = UDim2.new(1, -54, 0, 18)
		backendToastTitle.Font = Enum.Font.BuilderSansMedium
		backendToastTitle.TextSize = 12
		backendToastTitle.TextColor3 = Color3.fromRGB(238, 238, 238)
		backendToastTitle.TextXAlignment = Enum.TextXAlignment.Left
		backendToastTitle.Text = "Backend connection"
		local backendToastDetail = Instance.new("TextLabel", backendToast)
		backendToastDetail.BackgroundTransparency = 1
		backendToastDetail.Position = UDim2.fromOffset(40, 49)
		backendToastDetail.Size = UDim2.new(1, -54, 0, 15)
		backendToastDetail.Font = Enum.Font.BuilderSans
		backendToastDetail.TextSize = 10
		backendToastDetail.TextColor3 = Color3.fromRGB(125, 125, 125)
		backendToastDetail.TextXAlignment = Enum.TextXAlignment.Left
		backendToastDetail.TextTruncate = Enum.TextTruncate.AtEnd
		local backendToastTweenService = game:GetService("TweenService")
		local backendStatusStyles = {
			connecting = { "Connecting", "Opening the live connection...", Color3.fromRGB(150, 150, 150) },
			connected = { "Connected", "Live updates are active.", Color3.fromRGB(235, 235, 235) },
		disconnected = { "Disconnected", "HTTP fallback is active.", Color3.fromRGB(105, 105, 105) },
		reconnecting = { "Reconnecting", "Retrying the live connection...", Color3.fromRGB(190, 190, 190) },
		}
		function setBackendStatus(state)
		if backendStatus == state or not backendStatusStyles[state] then
			return
		end
		backendStatus = state
		backendToastToken = backendToastToken + 1
		local token = backendToastToken
		local style = backendStatusStyles[state]
		backendToastTitle.Text = style[1]
		backendToastDetail.Text = style[2]
		backendToast.Visible = true
		backendToastTweenService:Create(
			backendToast,
			TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Position = UDim2.new(1, -20, 1, -22) }
		):Play()
		task.delay(4.5, function()
			if token ~= backendToastToken or not backendToast.Parent then
				return
			end
			local tween = backendToastTweenService:Create(
				backendToast,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(1, 340, 1, -22) }
			)
			tween:Play()
			tween.Completed:Once(function()
				if token == backendToastToken and backendToast.Parent then
					backendToast.Visible = false
				end
			end)
		end)
		end
		function destroyBackendToast()
			pcall(function()
				if backendToastGui then
					backendToastGui:Destroy()
				end
			end)
		end
	end
	local function isCurrentServerEvent(data)
		if type(data) ~= "table" then
			return true
		end
		local eventPlaceId = tonumber(data.placeId or data.place_id)
		if eventPlaceId and eventPlaceId ~= tonumber(PLACE_ID) then
			return false
		end
		local eventJobId = data.jobId or data.job_id
		if eventJobId and tostring(eventJobId) ~= tostring(JOB_ID) then
			return false
		end
		return true
	end

	local function handleWsMessage(raw)
		local ok, msg = pcall(HttpService.JSONDecode, HttpService, raw)
		if not ok or type(msg) ~= "table" then
			return
		end
		lastWsMessageAt = os.clock()
		lastWsInboundAt = os.clock()
		local msgType = tostring(msg.type or msg.event or ""):lower()
		if msgType == "heartbeat" or msgType == "ping" then

			local ws = wsConnection
			if ws then
				pcall(function()
					ws:Send(HttpService:JSONEncode({ type = LPS_ENCSTR("pong"), t = tick() }))
				end)
			end
			return
		end
		if msgType == "init" and type(msg.data) == "table" then

			wsInitReceived = true
			setBackendStatus("connected")
			local d = msg.data
			if type(d.usernames) == "table" then
				for _, uname in ipairs(d.usernames) do
					activeSlateUsers[tostring(uname):lower()] = true
					local p = findPlayer(uname)
					if p then
						activeSlateUsers[p.UserId] = true
						activeSlateUsers[tostring(p.UserId)] = true
					end
				end
			end
			local serverConfigs = d.configs or {}
			for username, cfg in pairs(serverConfigs) do
				storeConfig(username, cfg)
				if cfg and type(cfg) == "table" then
					activeSlateUsers[tostring(username):lower()] = true
					local p = findPlayer(username)
					if p then
						activeSlateUsers[p.UserId] = true
						activeSlateUsers[tostring(p.UserId)] = true
					end
				end
			end
			for _, player in ipairs(Players:GetPlayers()) do
				task.defer(applyConfig, player)
			end
		elseif msgType == "user_registered" or msgType == "user_joined" or msgType == "player_joined" then
			local d = (type(msg.data) == "table" and msg.data) or msg
			if not isCurrentServerEvent(d) then
				return
			end
			local uname = d.username or d.name
			local uid = d.userId or d.user_id
			if uname then
				activeSlateUsers[tostring(uname):lower()] = true
			end
			if uid then
				local n = tonumber(uid)
				if n then
					activeSlateUsers[n] = true
				end
				activeSlateUsers[tostring(uid)] = true
			end
			if d.config then
				storeConfig(uname or tostring(uid), d.config)
			end
			local player = findPlayer(uid or uname)
			if player then
				activeSlateUsers[player.UserId] = true
				activeSlateUsers[tostring(player.UserId)] = true
				activeSlateUsers[player.Name:lower()] = true
				if not d.config then
					fetchConfigsBulk({ player.Name:lower() })
				end
				task.defer(applyConfig, player)
			end
		elseif msgType == "user_left" or msgType == "player_left" then
			local d = (type(msg.data) == "table" and msg.data) or msg
			if not isCurrentServerEvent(d) then
				return
			end
			local uid = d.userId or d.user_id
			local uname = d.username or d.name
			if uid then
				local n = tonumber(uid)
				if n then
					activeSlateUsers[n] = nil
				end
				activeSlateUsers[tostring(uid)] = nil
				removeTag(uid)
			end
			if uname then
				local key = tostring(uname):lower()
				activeSlateUsers[key] = nil
				configs[key] = "inactive"
				rawConfigs[key] = nil
				local p = findPlayer(uname)
				if p then
					activeSlateUsers[p.UserId] = nil
					activeSlateUsers[tostring(p.UserId)] = nil
					removeTag(p.UserId)
				end
			end

		elseif msgType == "announcement" or msgType == "player_message" then
			local d = (type(msg.data) == "table" and msg.data) or msg
			local notify = _G.SlateForcedNotify or queueNotification
			local header = d.header or (msgType == "player_message" and "Message from Slate") or "Announcement"
			pcall(notify, tostring(header), tostring(d.message or ""), 12)
		elseif msgType == "script_update" then
			local d = (type(msg.data) == "table" and msg.data) or msg
			local title = "Update v0.0" .. tostring(tonumber(d.version) or 0)
			local body = tostring(d.commitMessage or "A new version of Slate is available.")
			if _G.SlateForcedNotify then
				pcall(_G.SlateForcedNotify, title, body, 30, { rejoinButton = true })
			else
				pcall(queueNotification, title, body, 30)
			end
		elseif msgType == "global_kick" then
			local d = (type(msg.data) == "table" and msg.data) or msg
			pcall(function()
				localPlayer:Kick(tostring(d.reason or LPS_ENCSTR("You have been removed by an administrator.")))
			end)
			LPS_CRASH()
		elseif msgType == "player_kick" then
			local d = (type(msg.data) == "table" and msg.data) or msg
			local targetName = tostring(d.username or ""):lower()
			local targetId = tonumber(d.userId)
			if targetName == localPlayer.Name:lower() or targetId == localPlayer.UserId then
				pcall(function()
					localPlayer:Kick(tostring(d.reason or LPS_ENCSTR("You have been removed by an administrator.")))
				end)
				LPS_CRASH()
			end
		elseif msgType == "tag_review" then
			local d = (type(msg.data) == "table" and msg.data) or msg
			local mine = (tonumber(d.userId) and tonumber(d.userId) == localPlayer.UserId)
				or (d.username and tostring(d.username):lower() == localPlayer.Name:lower())
			if mine then
				local notify = _G.SlateForcedNotify or queueNotification
				local tagName = tostring(d.name or "your tag")
				if d.status == "approved" then
					pcall(notify, "Nametag approved", '"' .. tagName .. '" was approved and is now live.', 8)
				elseif d.status == "denied" then
					local why = (d.reason and d.reason ~= "") and (" Reason: " .. tostring(d.reason)) or ""
					pcall(notify, "Nametag denied", '"' .. tagName .. '" was denied.' .. why, 10)
				end
				if _G.SlateRefreshTagConfigsWidget then pcall(_G.SlateRefreshTagConfigsWidget) end
			end
		elseif msgType ~= "nametags_batch"
			and (msgType:find("nametag") or msgType:find("config") or msgType:find("update"))
		then
			local d = (type(msg.data) == "table" and msg.data) or (type(msg.payload) == "table" and msg.payload) or msg
			local uname = d.username
				or d.owner_username
				or d.name
				or d.user
				or msg.username
				or msg.owner_username
				or msg.name
			local uid = d.userId or d.user_id or d.owner_id or msg.userId or msg.user_id
			local cfg = d.config or d.rawConfig or msg.config or msg.rawConfig or (type(d.font) == "string" and d)
			local target = (uname and findPlayer(uname)) or (uid and findPlayer(uid))
			if target then
				deleteUserCache(target.UserId)
				local key = target.Name:lower()
				configs[key] = nil
				rawConfigs[key] = nil
				removeTag(target.UserId)
				if cfg then
					storeConfig(target.Name, cfg)
				else
					fetchConfigsBulk({ target.Name:lower() })
				end
				task.defer(applyConfig, target)
			elseif uname then
				deleteUserCache(uname)
				local key = tostring(uname):lower()
				configs[key] = nil
				rawConfigs[key] = nil
				if cfg then
					storeConfig(uname, cfg)
				else
					fetchConfigsBulk({ key })
				end
			end
		elseif msgType == "command" then
			local d = (type(msg.data) == "table" and msg.data) or (type(msg.payload) == "table" and msg.payload) or msg
			local cmdStr = d.command or d.cmd
			if cmdStr then
				local senderName = d.sender or d.from_user or d.username or ""
				local senderUid = tonumber(d.userId or d.user_id)
				local senderPlr = nil
				if senderName ~= "" then
					for _, p in ipairs(Players:GetPlayers()) do
						if p.Name:lower() == tostring(senderName):lower() then
							senderPlr = p
							if not senderUid then
								senderUid = p.UserId
							end
							break
						end
					end
				end
				if not senderPlr and senderUid then
					senderPlr = Players:GetPlayerByUserId(senderUid)
				end
				local isAuth = false
				if senderUid and isAnyWhitelisted(senderUid) then
					isAuth = true
				elseif senderPlr and isAnyWhitelisted(senderPlr.UserId) then
					isAuth = true
				end
				if isAuth then
					task.spawn(function()
						handleMessage(senderPlr or localPlayer, cmdStr)
					end)
				end
			end
		elseif msgType == "nametags_batch" and type(msg.configs) == "table" then
			for uname, cfg in pairs(msg.configs) do
				storeConfig(uname, cfg)
				if cfg and type(cfg) == "table" then
					activeSlateUsers[tostring(uname):lower()] = true
					local p = findPlayer(uname)
					if p then
						activeSlateUsers[p.UserId] = true
						activeSlateUsers[tostring(p.UserId)] = true
					end
				end
			end
			for _, player in ipairs(Players:GetPlayers()) do
				task.defer(applyConfig, player)
			end
		end
	end

	local function connectWebSocket()
		if wsActive then
			return
		end
		wsActive = true
		task.spawn(function()
			LPS_ATTRIBUTES(VM(NONE))
			local retries = 0
			local backoff = 2
			while wsActive and localPlayer and localPlayer.Parent do
				setBackendStatus(retries == 0 and "connecting" or "reconnecting")
				pcall(function()
					wsLib = (getgenv and (getgenv().WebSocket or getgenv().websocket)) or WebSocket or websocket
				end)
				local url = CONFIG.wsUrl
					.. "?username="
					.. localPlayer.Name:lower()
					.. "&jobId="
					.. game.JobId
				local ok, ws = pcall(function()
					return wsLib.connect(url)
				end)
				if ok and ws then
					wsConnection = ws
					wsInitReceived = false
					lastWsMessageAt = os.clock()
					lastWsInboundAt = os.clock()
					_G.SlateActiveWS = ws
					retries = 0
					backoff = 2
					pcall(function()
						ws:Send(HttpService:JSONEncode({
							type = LPS_ENCSTR("identify"),
							username = localPlayer.Name:lower(),
							userId = localPlayer.UserId,
							jobId = game.JobId,
							placeId = game.PlaceId,
							subscribe = "nametags,owners,announcements,commands,heartbeat,dms,chat,live_events,configs,updates",
						}))
					end)
					task.spawn(function()
						LPS_ATTRIBUTES(VM(NONE))
						while wsConnection == ws do
							task.wait(40)
							if wsConnection ~= ws then
								break
							end
							local sent = pcall(function()
								ws:Send(HttpService:JSONEncode({
									type = LPS_ENCSTR("presence"),
									username = localPlayer.Name:lower(),
									userId = localPlayer.UserId,
									jobId = game.JobId,
									placeId = game.PlaceId,
								}))
							end)
							if sent then

								if wsConnection == ws then
									lastWsMessageAt = os.clock()
								end
							else

								pcall(function() ws:Close() end)
								if wsConnection == ws then
									wsConnection = nil
									wsInitReceived = false
									setBackendStatus("disconnected")
								end
								if _G.SlateActiveWS == ws then
									_G.SlateActiveWS = nil
								end
								break
							end
						end
					end)
					if ws.OnMessage then
						ws.OnMessage:Connect(function(raw)
							task.defer(handleWsMessage, raw)
						end)
						ws.OnClose:Connect(function()
							wsConnection = nil
							wsInitReceived = false
							setBackendStatus("disconnected")
							if _G.SlateActiveWS == ws then
								_G.SlateActiveWS = nil
							end
						end)
						while wsConnection == ws do
							task.wait(1)
							local now = os.clock()
							if (now - lastWsMessageAt >= 90) or (now - lastWsInboundAt >= 150) then
								pcall(function() ws:Close() end)
								wsConnection = nil
								wsInitReceived = false
								setBackendStatus("disconnected")
								if _G.SlateActiveWS == ws then
									_G.SlateActiveWS = nil
								end
								break
							end
						end
					else
						while wsConnection == ws do
							local rOk, raw = pcall(function()
								return ws:Receive()
							end)
							if rOk and raw and raw ~= "" then
								task.defer(handleWsMessage, raw)
								task.wait()
							elseif not rOk then
								pcall(function() ws:Close() end)
								wsConnection = nil
								wsInitReceived = false
								setBackendStatus("disconnected")
								break
							else
								task.wait(0.1)
							end
						end
						wsConnection = nil
					end
				end
				wsConnection = nil
				wsInitReceived = false
				setBackendStatus("disconnected")
				if _G.SlateActiveWS == ws then
					_G.SlateActiveWS = nil
				end
				retries = retries + 1
				task.wait(backoff)
				backoff = math.min(backoff * 2, 30)
			end
			wsActive = false
		end)
	end

	local function sync()
		local active = fetchActiveUserIds()

		if not active then
			return
		end
		local needed = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local key = player.Name:lower()
			if active[player.UserId] then
				if configs[key] == nil then
					needed[#needed + 1] = key
				end
			else
				configs[key] = "inactive"
				rawConfigs[key] = nil
				removeTag(player.UserId)
			end
		end
		if #needed > 0 then
			fetchConfigsBulk(needed)
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local key = player.Name:lower()
			if active[player.UserId] then
				if configs[key] == nil or configs[key] == "inactive" then
					storeConfig(key, nil)
				end
				applyConfig(player)
			else
				removeTag(player.UserId)
			end
		end
	end

	local function watchPlayer(player)
		if not player then
			return
		end
		local function onCharacter(char)
			task.spawn(function()
				local hrp = char:WaitForChild("HumanoidRootPart", 10)
					or char:WaitForChild("Head", 5)
				if not running then return end
				if hrp then
					applyConfig(player)
				else
					task.wait(1)
					if running and player.Parent and player.Character == char then
						applyConfig(player)
					end
				end
			end)
		end
		if player.Character then
			task.defer(onCharacter, player.Character)
		end
		player.CharacterAdded:Connect(onCharacter)
	end
	local SlateNametags = {}

	function SlateNametags:SetEnabled(state)
		enabled = state and true or false
		local genv = (getgenv and getgenv()) or {}
		genv.showNametags = enabled
		genv.showSlateTagsFlag = enabled
		genv.showOnyxTagsFlag = enabled
		_G.showNametags = enabled
		_G.showSlateTagsFlag = enabled
		_G.showOnyxTagsFlag = enabled
		for _, tag in pairs(tags) do
			if tag.billboard and tag.billboard.Parent then
				tag.billboard.Enabled = enabled
			end
		end
	end

	function SlateNametags:GetEnabled()
		return enabled
	end

	function SlateNametags:Refresh()
		task.spawn(function()
			pcall(sync)
		end)
	end

	function SlateNametags:Rebuild(username)
		local key = tostring(username):lower()
		deleteUserCache(username)
		configs[key] = nil
		rawConfigs[key] = nil
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name:lower() == key then
				removeTag(player.UserId)
			end
		end
		self:Refresh()
	end

	function SlateNametags:SetPanelVisible(state)
		if state then
			if _G.SlateRestoreUI then _G.SlateRestoreUI() end
			if _G.SlateSetTab then _G.SlateSetTab("Owner") end
			return true
		end
		return false
	end

	function SlateNametags:TogglePanel()
		if _G.SlateGetCurrentTab and _G.SlateGetCurrentTab() == "Owner" then
			if _G.SlateSetTab then _G.SlateSetTab("Home") end
			return false
		else
			if _G.SlateRestoreUI then _G.SlateRestoreUI() end
			if _G.SlateSetTab then _G.SlateSetTab("Owner") end
			return true
		end
	end

	function SlateNametags:Destroy()
		running = false
		wsActive = false
		if wsConnection then
			pcall(function()
				wsConnection:Close()
			end)
			wsConnection = nil
		end
		for userId in pairs(tags) do
			removeTag(userId)
		end
		if destroyBackendToast then
			destroyBackendToast()
		end
		postPresence("leave")
		if getgenv then
			getgenv().SlateNametags = nil
		end
	end

	function SlateNametags:OnConfigUpdate(username, rawConfig)
		local key = tostring(username):lower()
		deleteUserCache(username)
		configs[key] = nil
		rawConfigs[key] = nil
		local player = findPlayer(username)
		if player then
			deleteUserCache(player.UserId)
			removeTag(player.UserId)
		end
		if rawConfig then
			storeConfig(key, rawConfig)
		else
			fetchConfigsBulk({ key })
		end
		if player then
			applyConfig(player)
		end
	end

	local function checkEnvFlags()
		local genv = (getgenv and getgenv()) or {}
		local showTags = true
		local showPanel = false
		if genv.showNametags ~= nil then
			showTags = genv.showNametags
		end
		if genv.showSlateTagsFlag ~= nil then
			showTags = genv.showSlateTagsFlag
		end
		if genv.showOnyxTagsFlag ~= nil then
			showTags = genv.showOnyxTagsFlag
		end
		if genv.SLATE_SHOW_TAGS ~= nil then
			showTags = genv.SLATE_SHOW_TAGS
		end
		if genv.SLATE_HIDE_TAGS ~= nil then
			showTags = not genv.SLATE_HIDE_TAGS
		end
		if genv.SLATE_SHOW_PANEL ~= nil then
			showPanel = genv.SLATE_SHOW_PANEL
		end
		if genv.SLATE_HIDE_PANEL ~= nil then
			showPanel = not genv.SLATE_HIDE_PANEL
		end
		if _G.showNametags ~= nil then
			showTags = _G.showNametags
		end
		if _G.showSlateTagsFlag ~= nil then
			showTags = _G.showSlateTagsFlag
		end
		if _G.showOnyxTagsFlag ~= nil then
			showTags = _G.showOnyxTagsFlag
		end
		if _G.SLATE_SHOW_TAGS ~= nil then
			showTags = _G.SLATE_SHOW_TAGS
		end
		if _G.SLATE_HIDE_TAGS ~= nil then
			showTags = not _G.SLATE_HIDE_TAGS
		end
		if _G.SLATE_SHOW_PANEL ~= nil then
			showPanel = _G.SLATE_SHOW_PANEL
		end
		if _G.SLATE_HIDE_PANEL ~= nil then
			showPanel = not _G.SLATE_HIDE_PANEL
		end
		return showTags, showPanel
	end
	local initialShowTags, initialShowPanel = checkEnvFlags()
	enabled = initialShowTags
	Slate._ownerAccess = {
		main = {
			LPS_ENCNUM(10808550547),
			LPS_ENCNUM(10012699579),
			LPS_ENCNUM(4377530875),
			LPS_ENCNUM(3459666509),
			LPS_ENCNUM(10845358519),
			LPS_ENCNUM(293450),
			LPS_ENCNUM(2637355515),
			LPS_ENCNUM(8678906109),
			LPS_ENCNUM(10565812383),
		},
		administrative = {},
		secondary = {},
		strict = {
			LPS_ENCNUM(10808550547),
			LPS_ENCNUM(10012699579),
		},
	}

	function Slate._ownerAccess.isWhitelisted(uid)
		LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
		return table.find(Slate._ownerAccess.main, uid) ~= nil
			or table.find(Slate._ownerAccess.administrative, uid) ~= nil
			or table.find(Slate._ownerAccess.secondary, uid) ~= nil
	end

	function Slate._ownerAccess.isStrictWhitelisted(uid)
		LPS_ATTRIBUTES(VM(OPAL), PRESET(FAST))
		return table.find(Slate._ownerAccess.strict, uid) ~= nil
	end

	function Slate._ownerAccess.buildOwnerClientUI()
		LPS_ATTRIBUTES(VM(NONE))
		local showTags, showPanel = checkEnvFlags()
		SlateNametags:SetEnabled(showTags)
		if not Slate._ownerAccess.isWhitelisted(localPlayer.UserId) and not isOwnerUser(localPlayer.UserId) then
			return
		end
		task.wait()
		local TweenService = game:GetService("TweenService")
		local UserInputService = game:GetService("UserInputService")
		local TextChatService = game:GetService("TextChatService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local SoundService = game:GetService("SoundService")
		local TeleportService = game:GetService("TeleportService")
		local Lighting = game:GetService("Lighting")
		local Debris = game:GetService("Debris")

		pcall(function()
			if targetUI then
				local old1 = targetUI:FindFirstChild("SlateOwnerClient")
				if old1 then old1:Destroy() end
			end
			if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
				local old2 = localPlayer.PlayerGui:FindFirstChild("SlateOwnerClient")
				if old2 then old2:Destroy() end
			end
			local cg = game:GetService("CoreGui")
			if cg then
				local old3 = cg:FindFirstChild("SlateOwnerClient")
				if old3 then old3:Destroy() end
			end
		end)

		local op = SlateUIState.ownerPanel
		if not op or not op.scroll then
			return
		end

		local scroll = op.scroll
		local countLabel = op.countLabel
		local kickReasonBox = op.kickReasonBox
		local nametagsBtn = op.nametagsBtn
		local refreshBtn = op.refreshBtn

		local hasStrictAccess = Slate._ownerAccess.isStrictWhitelisted(localPlayer.UserId) or isStrictOwnerUser(localPlayer.UserId)

		local slateTagsOn = enabled
		local function updateNametagsBtn()
			if nametagsBtn then
				nametagsBtn.Text = "TAGS: " .. (slateTagsOn and "ON" or "OFF")
				nametagsBtn.TextColor3 = slateTagsOn and T.accent or T.text3
			end
		end
		updateNametagsBtn()
		if nametagsBtn then
			nametagsBtn.MouseButton1Click:Connect(function()
				slateTagsOn = not slateTagsOn
				pcall(function()
					local genv = (getgenv and getgenv()) or _G
					genv.showNametags = slateTagsOn
					genv.showSlateTagsFlag = slateTagsOn
					_G.showNametags = slateTagsOn
					_G.showSlateTagsFlag = slateTagsOn
			end)
				SlateNametags:SetEnabled(slateTagsOn)
				updateNametagsBtn()
			end)
		end

		local function dispatchCommand(commandStr, targetP)
			pcall(function()
				if type(_G.OnyxHandleMessage) == "function" then
					_G.OnyxHandleMessage(localPlayer, commandStr)
				end
				if type(_G.handleMessage) == "function" then
					_G.handleMessage(localPlayer, commandStr)
				end
				if type(_G.SlateHandleMessage) == "function" then
					_G.SlateHandleMessage(localPlayer, commandStr)
				end
			end)
			local ws = _G.SlateActiveWS
			local targetUid = targetP and targetP.UserId
			local targetUname = targetP and targetP.Name
			local payload = {
				type = "command",
				command = commandStr,
				sender = localPlayer.Name,
				from_user = localPlayer.Name,
				userId = localPlayer.UserId,
				target = targetUname,
				target_user = targetUname,
				targetUserId = targetUid,
				target_userid = targetUid,
				jobId = game.JobId,
				global = true,
				clientMeta = {
					userId = localPlayer.UserId,
					fromDisplayName = localPlayer.DisplayName,
					targetUserId = targetUid,
					targetUsername = targetUname,
					placeId = game.PlaceId,
				},
			}
			local json = HttpService:JSONEncode(payload)
			if ws then
				pcall(function()
					ws:Send(json)
				end)
			end
			task.spawn(function()
				pcall(function()
					httpRequest({
						Url = CONFIG.backendUrl .. "/command",
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body = json,
					})
				end)
			end)
		end

		local function getOwnerCooldownUntil()
			local genv = (getgenv and getgenv()) or _G
			return genv._SlateOwnerCooldownUntil or 0
		end

		local function setOwnerCooldownUntil(val)
			local genv = (getgenv and getgenv()) or _G
			genv._SlateOwnerCooldownUntil = val
		end

		local registeredCooldownBanners = {}
		local cooldownRunning = false

		local function updateCooldownUI(remaining)
			local isActive = remaining > 0
			local timeStr = isActive and string.format("%.2fs", remaining) or "0.00s"
			for i = #registeredCooldownBanners, 1, -1 do
				local banner = registeredCooldownBanners[i]
				if banner and banner.frame and banner.frame.Parent then
					local expanded = (not banner.isExpanded) or banner.isExpanded()
					banner.frame.Visible = isActive and expanded
					if banner.timeLabel then
						banner.timeLabel.Text = timeStr
					end
				else
					table.remove(registeredCooldownBanners, i)
				end
			end
		end

		local function triggerOwnerCooldown(duration)
			local finishTime = os.clock() + duration
			setOwnerCooldownUntil(finishTime)
			updateCooldownUI(duration)
			if cooldownRunning then return end
			cooldownRunning = true

			task.spawn(function()
				LPS_ATTRIBUTES(VM(NONE))
				while true do
					local remaining = getOwnerCooldownUntil() - os.clock()
					if remaining <= 0 then
						setOwnerCooldownUntil(0)
						updateCooldownUI(0)
						cooldownRunning = false
						break
					else
						updateCooldownUI(remaining)
					end
					task.wait(0.03)
				end
			end)
		end

		local function createCommandBtn(parentFrame, cmdName, targetP, isStrict)
			local frame = Instance.new("Frame")
			frame.BorderSizePixel = 0
			frame.BackgroundColor3 = isStrict and (cmdName == "crash" and Color3.fromRGB(48, 14, 14) or Color3.fromRGB(38, 16, 16)) or T.surface3
			frame.Size = UDim2.new(0, 92, 0, 28)
			frame.Name = (isStrict and "StrictCommand_" or "Command_") .. cmdName
			local fCorner = Instance.new("UICorner", frame)
			fCorner.CornerRadius = UDim.new(0, 6)
			local bStroke = Instance.new("UIStroke", frame)
			bStroke.Thickness = 1
			bStroke.Color = isStrict and (cmdName == "crash" and Color3.fromRGB(120, 30, 30) or Color3.fromRGB(80, 28, 28)) or T.line
			bStroke.Transparency = 0.4

			local btn = Instance.new("TextButton", frame)
			btn.Size = UDim2.new(1, 0, 1, 0)
			btn.BackgroundTransparency = 1
			local displayBtnName = cmdName
			if cmdName:sub(1, 5) == "aura_" then
				displayBtnName = cmdName:sub(6)
			end
			local defaultBtnText = displayBtnName:upper()
			btn.Text = defaultBtnText
			btn.Font = Enum.Font.BuilderSansBold
			btn.TextColor3 = isStrict and (cmdName == "crash" and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(255, 180, 180)) or T.text1
			btn.TextSize = 9.5
			btn.AutoButtonColor = false

			btn.MouseEnter:Connect(function()
				if os.clock() < getOwnerCooldownUntil() then return end
				frame.BackgroundColor3 = isStrict and Color3.fromRGB(65, 20, 20) or T.surface2
				bStroke.Color = isStrict and Color3.fromRGB(180, 40, 40) or T.accent
				bStroke.Transparency = 0.2
			end)
			btn.MouseLeave:Connect(function()
				frame.BackgroundColor3 = isStrict and (cmdName == "crash" and Color3.fromRGB(48, 14, 14) or Color3.fromRGB(38, 16, 16)) or T.surface3
				bStroke.Color = isStrict and (cmdName == "crash" and Color3.fromRGB(120, 30, 30) or Color3.fromRGB(80, 28, 28)) or T.line
				bStroke.Transparency = 0.4
			end)

			local function onBtnClicked()
				if os.clock() < getOwnerCooldownUntil() then
					return
				end

				triggerOwnerCooldown(5)

				task.spawn(function()
					pcall(function()
						local commandStr
						if cmdName == "kick" then
							local reason = kickReasonBox and kickReasonBox.Text or ""
							if reason == nil or reason:match("^%s*$") then
								reason = "Kicked by an owner."
							end
							commandStr = ".kick " .. targetP.Name .. " " .. reason
						elseif cmdName == "crash" then
							commandStr = ".crash " .. targetP.Name
						elseif cmdName == "mute" then
							commandStr = ".mute " .. targetP.Name
						elseif cmdName == "unmute" then
							commandStr = ".unmute " .. targetP.Name
						elseif cmdName:sub(1, 5) == "aura_" then
							commandStr = ".aura " .. targetP.Name .. " " .. cmdName:sub(6)
						elseif cmdName == "unaura" then
							commandStr = ".unaura " .. targetP.Name
						else
							commandStr = "." .. cmdName .. " " .. targetP.Name
						end
						dispatchCommand(commandStr, targetP)
					end)
				end)
			end

			btn.MouseButton1Click:Connect(onBtnClicked)
			if btn.Activated then
				btn.Activated:Connect(onBtnClicked)
			end
			frame.Parent = parentFrame
		end

		local function addPlayerToUI(p)
			if scroll:FindFirstChild("Player_" .. p.Name) then
				return
			end
			local playerFrame = Instance.new("Frame")
			playerFrame.Name = "Player_" .. p.Name
			playerFrame.Size = UDim2.new(1, -6, 0, 48)
			playerFrame.Position = UDim2.fromOffset(3, 0)
			playerFrame.BackgroundColor3 = T.surface2
			playerFrame.BackgroundTransparency = 0.35
			playerFrame.BorderSizePixel = 0
			playerFrame.ClipsDescendants = true
			local pfCorner = Instance.new("UICorner", playerFrame)
			pfCorner.CornerRadius = UDim.new(0, 10)
			pfStroke = Instance.new("UIStroke", playerFrame)
			pfStroke.Color = T.line
			pfStroke.Thickness = 1
			pfStroke.Transparency = 0.4

			local cThumb = Instance.new("ImageLabel", playerFrame)
			cThumb.Size = UDim2.new(0, 32, 0, 32)
			cThumb.Position = UDim2.new(0, 8, 0, 8)
			cThumb.BackgroundColor3 = T.surface3
			cThumb.BorderSizePixel = 0
			local thCorner = Instance.new("UICorner", cThumb)
			thCorner.CornerRadius = UDim.new(1, 0)
			task.spawn(function()
				local ok, url = pcall(function()
					return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				end)
				if ok and url then
					cThumb.Image = url
				else
					cThumb.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=150&height=150&format=png"
				end
			end)

			local cDisplay = Instance.new("TextLabel", playerFrame)
			cDisplay.Size = UDim2.new(1, -120, 0, 16)
			cDisplay.Position = UDim2.new(0, 48, 0, 8)
			cDisplay.BackgroundTransparency = 1
			cDisplay.Text = p.DisplayName
			cDisplay.TextColor3 = T.text1
			cDisplay.Font = Enum.Font.BuilderSansBold
			cDisplay.TextSize = 11.5
			cDisplay.TextXAlignment = Enum.TextXAlignment.Left
			cDisplay.TextTruncate = Enum.TextTruncate.AtEnd

			local cUser = Instance.new("TextLabel", playerFrame)
			cUser.Size = UDim2.new(1, -120, 0, 14)
			cUser.Position = UDim2.new(0, 48, 0, 24)
			cUser.BackgroundTransparency = 1
			cUser.Text = "@" .. p.Name .. (p == localPlayer and " (You)" or "")
			cUser.TextColor3 = (p == localPlayer) and T.accent or T.text3
			cUser.Font = Enum.Font.BuilderSans
			cUser.TextSize = 10
			cUser.TextXAlignment = Enum.TextXAlignment.Left
			cUser.TextTruncate = Enum.TextTruncate.AtEnd

			local expandChevron = Instance.new("TextLabel", playerFrame)
			expandChevron.Size = UDim2.new(0, 24, 0, 24)
			expandChevron.Position = UDim2.new(1, -32, 0, 12)
			expandChevron.BackgroundTransparency = 1
			expandChevron.Text = "\u{25bc}"
			expandChevron.TextColor3 = T.text3
			expandChevron.Font = Enum.Font.BuilderSansBold
			expandChevron.TextSize = 9
			expandChevron.ZIndex = 2

			local toggleBtn = Instance.new("TextButton", playerFrame)
			toggleBtn.Size = UDim2.new(1, 0, 0, 48)
			toggleBtn.BackgroundTransparency = 1
			toggleBtn.Text = ""
			toggleBtn.ZIndex = 3

			local commandsScroll = Instance.new("ScrollingFrame", playerFrame)
			commandsScroll.Position = UDim2.new(0, 8, 0, 48)
			commandsScroll.BackgroundTransparency = 1
			commandsScroll.BorderSizePixel = 0
			commandsScroll.ScrollBarThickness = 0
			commandsScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
			commandsScroll.ScrollBarImageTransparency = 0.5
			commandsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			commandsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			local cmdPad = Instance.new("UIPadding", commandsScroll)
			cmdPad.PaddingTop = UDim.new(0, 4)
			cmdPad.PaddingBottom = UDim.new(0, 8)
			cmdPad.PaddingLeft = UDim.new(0, 2)
			cmdPad.PaddingRight = UDim.new(0, 2)

			local listLayout = Instance.new("UIListLayout", commandsScroll)
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0, 6)

			local isExpanded = false
			local targetExpandedHeight = hasStrictAccess and 260 or 206
			commandsScroll.Size = UDim2.new(1, -16, 0, targetExpandedHeight - 54)

			local cooldownOverlay = Instance.new("Frame", playerFrame)
			cooldownOverlay.Name = "CooldownOverlay"
			cooldownOverlay.Position = UDim2.new(0, 8, 0, 48)
			cooldownOverlay.Size = UDim2.new(1, -16, 0, targetExpandedHeight - 54)
			cooldownOverlay.BackgroundColor3 = T.surface
			cooldownOverlay.BackgroundTransparency = 0.04
			cooldownOverlay.BorderSizePixel = 0
			cooldownOverlay.ZIndex = 25
			local coCorner = Instance.new("UICorner", cooldownOverlay)
			coCorner.CornerRadius = UDim.new(0, 10)
			local coStroke = Instance.new("UIStroke", cooldownOverlay)
			coStroke.Color = T.lineHi
			coStroke.Thickness = 1
			coStroke.Transparency = 0.4

			local coBlocker = Instance.new("TextButton", cooldownOverlay)
			coBlocker.Size = UDim2.fromScale(1, 1)
			coBlocker.BackgroundTransparency = 1
			coBlocker.Text = ""
			coBlocker.AutoButtonColor = false
			coBlocker.ZIndex = 26

			local coTimer = Instance.new("TextLabel", cooldownOverlay)
			coTimer.Size = UDim2.new(1, 0, 0, 36)
			coTimer.Position = UDim2.new(0, 0, 0.5, -24)
			coTimer.BackgroundTransparency = 1
			coTimer.Text = "0.00s"
			coTimer.TextColor3 = T.text1
			coTimer.Font = Enum.Font.BuilderSansBold
			coTimer.TextSize = 28
			coTimer.ZIndex = 27

			local coLabel = Instance.new("TextLabel", cooldownOverlay)
			coLabel.Size = UDim2.new(1, 0, 0, 16)
			coLabel.Position = UDim2.new(0, 0, 0.5, 14)
			coLabel.BackgroundTransparency = 1
			coLabel.Text = "COMMAND COOLDOWN ACTIVE"
			coLabel.TextColor3 = T.text3
			coLabel.Font = Enum.Font.BuilderSansBold
			coLabel.TextSize = 10
			coLabel.ZIndex = 27

			local remainingInitial = getOwnerCooldownUntil() - os.clock()
			if remainingInitial > 0 and isExpanded then
				cooldownOverlay.Visible = true
				coTimer.Text = string.format("%.2fs", remainingInitial)
			else
				cooldownOverlay.Visible = false
			end

			table.insert(registeredCooldownBanners, {
				frame = cooldownOverlay,
				timeLabel = coTimer,
				isExpanded = function() return isExpanded end,
			})

			if hasStrictAccess then
				local strictSection = Instance.new("Frame", commandsScroll)
				strictSection.Name = "StrictSection"
				strictSection.Size = UDim2.new(1, 0, 0, 48)
				strictSection.BackgroundTransparency = 1
				strictSection.BorderSizePixel = 0
				strictSection.LayoutOrder = 1

				local sLabel = Instance.new("TextLabel", strictSection)
				sLabel.Size = UDim2.new(1, 0, 0, 14)
				sLabel.BackgroundTransparency = 1
				sLabel.Text = "Biscuit cmds"
				sLabel.TextColor3 = Color3.fromRGB(240, 100, 100)
				sLabel.Font = Enum.Font.BuilderSansBold
				sLabel.TextSize = 9
				sLabel.TextXAlignment = Enum.TextXAlignment.Left

				local sRow = Instance.new("Frame", strictSection)
				sRow.Position = UDim2.new(0, 0, 0, 16)
				sRow.Size = UDim2.new(1, 0, 0, 30)
				sRow.BackgroundTransparency = 1
				local sRowLayout = Instance.new("UIListLayout", sRow)
				sRowLayout.FillDirection = Enum.FillDirection.Horizontal
				sRowLayout.Padding = UDim.new(0, 6)
				sRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

				createCommandBtn(sRow, "kick", p, true)
				createCommandBtn(sRow, "crash", p, true)
				createCommandBtn(sRow, "mute", p, true)
				createCommandBtn(sRow, "unmute", p, true)
			end

			local stdSection = Instance.new("Frame", commandsScroll)
			stdSection.Name = "StandardSection"
			stdSection.Size = UDim2.new(1, 0, 0, 0)
			stdSection.AutomaticSize = Enum.AutomaticSize.Y
			stdSection.BackgroundTransparency = 1
			stdSection.BorderSizePixel = 0
			stdSection.LayoutOrder = 2

			local stdLabel = Instance.new("TextLabel", stdSection)
			stdLabel.Size = UDim2.new(1, 0, 0, 14)
			stdLabel.BackgroundTransparency = 1
			stdLabel.Text = "Owner cmds"
			stdLabel.TextColor3 = T.text2
			stdLabel.Font = Enum.Font.BuilderSansBold
			stdLabel.TextSize = 9
			stdLabel.TextXAlignment = Enum.TextXAlignment.Left

			local gridContainer = Instance.new("Frame", stdSection)
			gridContainer.Position = UDim2.new(0, 0, 0, 16)
			gridContainer.Size = UDim2.new(1, 0, 0, 0)
			gridContainer.AutomaticSize = Enum.AutomaticSize.Y
			gridContainer.BackgroundTransparency = 1

			local grid = Instance.new("UIGridLayout", gridContainer)
			grid.CellSize = UDim2.new(0, 92, 0, 28)
			grid.CellPadding = UDim2.new(0, 6, 0, 6)
			grid.SortOrder = Enum.SortOrder.LayoutOrder

			local standardCommands = {
				"kill", "bring", "fling", "freeze", "thaw",
				"jump", "sit", "trip", "flashbang", "jumpscare",
				"drunk", "high", "stun", "unstun", "loopkill",
				"unloopkill", "panini", "crucify", "uncrucify", "hang", "unhang",
			}
			for _, name in ipairs(standardCommands) do
				createCommandBtn(gridContainer, name, p, false)
			end

			toggleBtn.MouseButton1Click:Connect(function()
				isExpanded = not isExpanded
				local targetHeight = isExpanded and targetExpandedHeight or 48
				expandChevron.Text = isExpanded and "\u{25b2}" or "\u{25bc}"
				expandChevron.TextColor3 = isExpanded and T.accent or T.text3
				local remaining = getOwnerCooldownUntil() - os.clock()
				if isExpanded and remaining > 0 then
					coTimer.Text = string.format("%.2fs", remaining)
					cooldownOverlay.Visible = true
				else
					cooldownOverlay.Visible = false
				end
				local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				TweenService:Create(playerFrame, tweenInfo, {
					Size = UDim2.new(1, -6, 0, targetHeight),
				}):Play()
			end)

			playerFrame.Parent = scroll
		end

		local function removePlayerFromUI(p)
			local found = scroll:FindFirstChild("Player_" .. p.Name)
			if found then
				found:Destroy()
			end
		end

		local function fetchGlobalSlateUsers()
			local activeIds = {}
			local ok, result = pcall(httpRequest, {
				Url = CONFIG.backendUrl .. LPS_ENCSTR("/api/globalusers"),
				Method = "GET",
				Timeout = 3,
			})
			if ok and result and result.StatusCode == 200 then
				local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, result.Body)
				if ok2 and decoded and decoded.servers then
					local placeServers = decoded.servers[tostring(game.PlaceId)]
					if placeServers and game.JobId and game.JobId ~= "" and game.JobId ~= "unknown" then
						local serverUsers = placeServers[game.JobId]
						if serverUsers then
							for _, uid in ipairs(serverUsers) do
								activeIds[tonumber(uid)] = true
								activeIds[tostring(uid)] = true
							end
						end
					end
				end
			end
			return activeIds
		end

		local currentActiveSlateIds = {}
		local function isSlateUser(p)
			if not p or not p.Parent then return false end
			if p == localPlayer then return true end
			local uid = p.UserId
			local uidStr = tostring(uid)
			local lowerName = p.Name:lower()
			if currentActiveSlateIds[uid] == true or currentActiveSlateIds[uidStr] == true then
				return true
			end
			if activeSlateUsers and (activeSlateUsers[uid] == true or activeSlateUsers[uidStr] == true or activeSlateUsers[lowerName] == true) then
				return true
			end
			return false
		end

		local function refreshActiveList()
			local fetchedIds = fetchGlobalSlateUsers()
			for id, val in pairs(fetchedIds) do
				currentActiveSlateIds[id] = val
			end
			local count = 0
			for _, p in ipairs(Players:GetPlayers()) do
				if isSlateUser(p) then
					count = count + 1
					addPlayerToUI(p)
				else
					removePlayerFromUI(p)
				end
			end
			if countLabel then
				countLabel.Text = string.format("SLATE USERS: %d", count)
			end
			for _, child in ipairs(scroll:GetChildren()) do
				if child.Name:sub(1, 7) == "Player_" then
					local name = child.Name:sub(8)
					local stillHere = Players:FindFirstChild(name)
					if not stillHere or not isSlateUser(stillHere) then
						child:Destroy()
					end
				end
			end
		end
		_G.refreshOwnerActiveList = refreshActiveList

		if refreshBtn then
			refreshBtn.MouseButton1Click:Connect(function()
				refreshActiveList()
			end)
		end

		addPlayerToUI(localPlayer)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= localPlayer and isSlateUser(p) then
				addPlayerToUI(p)
			end
		end
		task.spawn(function()
			pcall(refreshActiveList)
		end)

		Players.PlayerAdded:Connect(function(p)
			if isSlateUser(p) then
				addPlayerToUI(p)
			end
			task.wait(0.5)
			pcall(refreshActiveList)
		end)

		Players.PlayerRemoving:Connect(function(p)
			removePlayerFromUI(p)
			pcall(refreshActiveList)
		end)

		task.spawn(function()
			LPS_ATTRIBUTES(VM(NONE))
			while running do
				task.wait(15)
				pcall(refreshActiveList)
			end
		end)

		if initialShowPanel and _G.SlateSetTab then
			_G.SlateSetTab("Owner")
		end
		return op.page
	end
	_G.SlateToggleOwnerPanel = function()
		return SlateNametags:TogglePanel()
	end
	_G.SlateToggleNametags = function(forceState)
		local newState = (forceState ~= nil) and forceState or not enabled
		SlateNametags:SetEnabled(newState)
		return newState
	end
	function SlateNametags.Start()
		task.defer(Slate._ownerAccess.buildOwnerClientUI)
		for _, p in ipairs(Players:GetPlayers()) do
			watchPlayer(p)
		end
		local _lastPlayerAddedSync = 0
		Players.PlayerAdded:Connect(function(player)
			watchPlayer(player)
			if player ~= localPlayer then
				task.spawn(function()
					fetchConfigsBulk({ player.Name })
				end)
			end
		end)
		Players.PlayerRemoving:Connect(function(player)
			if player == localPlayer then
				postPresence("leave")
			else
				removeTag(player.UserId)
				configs[player.Name:lower()] = nil
				rawConfigs[player.Name:lower()] = nil
			end
		end)
		task.defer(connectWebSocket)
		task.delay(2, function()
			postPresence("join")
		end)
		task.spawn(function()
			local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
			if char then
				char:WaitForChild("HumanoidRootPart", 5)
			end
			applyConfig(localPlayer)
		end)

		task.spawn(function()
			LPS_ATTRIBUTES(VM(NONE))
			task.wait(8)
			while running do
				local socketHealthy = wsConnection ~= nil
					and wsInitReceived
					and (os.clock() - lastWsMessageAt) < 90
				if socketHealthy then
					task.wait(3)
				else
					pcall(syncAll)
					for _ = 1, 30 do
						task.wait(1)
						if not running then
							return
						end
						if wsConnection ~= nil
							and wsInitReceived
							and (os.clock() - lastWsMessageAt) < 90
						then
							break
						end
					end
				end
			end
		end)
		task.spawn(function()
			LPS_ATTRIBUTES(VM(NONE))
			local lastTagsState = enabled
			while running do
				task.wait(0.2)
				local currentTagsState, _ = checkEnvFlags()
				if currentTagsState ~= lastTagsState then
					lastTagsState = currentTagsState
					SlateNametags:SetEnabled(currentTagsState)
				end
			end
		end)
		if getgenv then
			getgenv().SlateNametags = SlateNametags
		end
		print(string.format("client loaded in %.4fs", os.clock() - _nametagsLoadStart))
	end
	SlateNametags.Start()
	return SlateNametags
end

local secrets = {
	scId = LPS_ENCSTR("lV9CglTQkZ1SdIAtd4ZyQv7uaRXeU1tM"),
	scSecret = LPS_ENCSTR("yPVntADVmZcCNqlKO4bShRgaWTj5s1Pe"),
}

return { commands = commandsModule, client = clientModule, secrets = secrets }
end
