if not LPS_OBFUSCATED then LPS_ATTRIBUTES = function(...) end; VM = function(...) end; OPAL = nil; NONE = nil; PRESET = function(...) end; SECURE = nil; FAST = nil; ERROR_HANDLING = function(...) end; TRANSFORM = function(...) end; CONTROL_FLOW = nil; REWRITE_NAMECALLS = nil; EXTRACT = function(...) end; GLOBALS = nil; CONSTANTS = nil; INLINE = function(...) end; UNROLL = function(...) end; OPTIMIZE = function(...) end; ENCRYPT = function(...) end; LPS_ENCSTR = function(s) return s end; LPS_ENCNUM = function(n) return n end; LPS_CRASH = function() end end
LPS_ATTRIBUTES(
    PRESET(FAST)
)

local _reanimLoadStart = os.clock()

-- =====================================================================
-- show_ui: master switch for whether the reanimation UI opens on execute.
--   true  -> UI shows on execute (default)
--   false -> UI stays hidden on execute; toggle from getgenv().show_ui
-- Runtime override: setting _G.show_ui = true/false before execute wins.
-- =====================================================================
local show_ui = false
if _G.show_ui ~= nil then show_ui = _G.show_ui == true end
_G.show_ui = show_ui
if getgenv then getgenv().show_ui = show_ui end
_G.AutoOpenReanimGUI = show_ui


-- ════════════════════════════════════════════════════════════════════════════

local createVectorShadow = _G.createVectorShadow or function(parentFrame)
	local shadowConfigs = {
		{size = 4,  offset = Vector2.new(0, 2),  trans = 0.82},
		{size = 8, offset = Vector2.new(0, 3),  trans = 0.88},
		{size = 15, offset = Vector2.new(0, 4),  trans = 0.93},
		{size = 20, offset = Vector2.new(0, 5), trans = 0.97},
	}
	local folder = Instance.new("Folder", parentFrame.Parent)
	folder.Name = parentFrame.Name .. "_Shadow"
	local mainCorner = parentFrame:FindFirstChildOfClass("UICorner")
	local cachedCornerRadius = mainCorner and mainCorner.CornerRadius

	for i, config in ipairs(shadowConfigs) do
		local layer = Instance.new("Frame", folder)
		layer.Name = "ShadowLayer" .. i
		layer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		layer.BackgroundTransparency = config.trans
		layer.BorderSizePixel = 0
		layer.ZIndex = math.max(0, parentFrame.ZIndex - 1)
		local corner = Instance.new("UICorner", layer)
		if cachedCornerRadius then
			corner.CornerRadius = cachedCornerRadius
		end
	end

	local layerOffsets = {}
	for _, item in ipairs(shadowConfigs) do
		local s = item.size
		local off = item.offset
		layerOffsets[#layerOffsets + 1] = {
			sizeAdd  = UDim2.new(0, s, 0, s),
			posOff   = UDim2.new(0, -s/2 + off.X, 0, -s/2 + off.Y),
		}
	end

	local function updateShadow()
		local isVisible = parentFrame.Visible
		local mainSize  = parentFrame.Size
		local mainPos   = parentFrame.Position
		local children = folder:GetChildren()
		for i, item in ipairs(children) do
			local lo = layerOffsets[i]
			if lo then
				item.Size     = mainSize + lo.sizeAdd
				item.Position = mainPos  + lo.posOff
				item.Visible  = isVisible
			end
		end
	end

	parentFrame:GetPropertyChangedSignal("Size"):Connect(updateShadow)
	parentFrame:GetPropertyChangedSignal("Position"):Connect(updateShadow)
	parentFrame:GetPropertyChangedSignal("Visible"):Connect(updateShadow)
	task.defer(updateShadow)
	return folder
end
_G.createVectorShadow = createVectorShadow

local runReanimEngine = function()

local playersService = game:GetService("Players")
local workspaceService = game:GetService("Workspace")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorageService = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local localPlayer = playersService.LocalPlayer
local currentAnimationState = nil
local httpService = game:GetService("HttpService")
local isInitialized = false
local animationTrack = nil
local animationFolder = nil
local keyframeSequence = nil
local animationController = nil

local animationData = nil

local animationConfig = nil

local activeAnimations = {}

local loadedAnimations = {}

local animationStates = {}

local stateAnimations = {

	["idle"] = nil,

	["walking"] = nil,

	["jumping"] = nil

}

local stateAnimationsPath = "slate/reanimation/state_animations.json"

local cachedAnimations = {}

local scaleSettings = {

	["heightScale"] = 1,

	["widthScale"] = 1

}

local animationCachePath = "slate/reanimation/animation_list_cache.json"

local onyx = {
	services = {
		players = game:GetService("Players");
		workspace = game:GetService("Workspace");
		replicated = game:GetService("ReplicatedStorage");
		run_service = game:GetService("RunService");
		user_input_service = game:GetService("UserInputService");
        http_service = game:GetService("HttpService");
	};
	flags = {
		reanimated = false;
	};
	clones = {};
	connections = {
		hb = nil;
		died = nil;
		real_char_child_removed = nil;
		character_removing = nil;
		clone_died = nil;
		clone_char_child_removed = nil;
        animation_hb = nil;
	};
	real_chars = {};
	callbacks = {
		on_play = nil,
		on_stop = nil,
	},
	animation = {
        cache = {};
        state = {
            is_playing = false;
            current_url = nil;
            speed = 1.0;
            keyframes = nil;
            total_duration = 0;
            elapsed_time = 0;
        };
        original_motor_c0s = {};
        joints = {};
    };
};

local onyxAPI = {};

local get_game_ragdoll_info = function(enable)
	local place_id = game.PlaceId;
	if place_id == 15546218972 or place_id == 6884319169 then
		-- Mic Up and Mic Up 18+
		local remote = onyx.services.replicated:WaitForChild("event_rag");
		return remote, {"Ball"}, false;
	elseif place_id == 5991163185 then
		-- Spray Paint
		local remote = onyx.services.replicated.Remotes.Physics.Ragdoll;
		return remote, {}, false;
	elseif place_id == 5683833663 then
		-- Ragdoll Engine (uses LocalEvent, not RemoteEvent)
		local local_event = onyx.services.replicated:WaitForChild("LocalRagdollEvent");
		return local_event, {enable}, true;
	end;
	return nil, nil, false;
end;

local set_model_transparency = function(model, transparency)
	if not model then
		return;
	end;
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = transparency;
		end;
	end;
end;

local get_local_player = function()
	local player = onyx.services.players.LocalPlayer;
	if not player then
		return "bad argument to 'get_local_player' (LocalPlayer not found; must run in a LocalScript)";
	end;
	return player;
end;

local get_char = function(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return ("bad argument #1 to 'get_char' (Player expected, got %s)"):format(typeof(player));
	end;
	local character = player.Character;
	if not character or not character.Parent then
		return ("Player %s has no active character."):format(player.Name);
	end;
	return character;
end;

local clone_char = function(model)
	if typeof(model) ~= "Instance" then
		return ("bad argument #1 to 'clone_char' (Instance expected, got %s)"):format(typeof(model));
	end;

    local old_archivables = {}
    old_archivables[model] = model.Archivable
	model.Archivable = true;
    for _, desc in ipairs(model:GetDescendants()) do
        old_archivables[desc] = desc.Archivable
        desc.Archivable = true
    end

	local new_clone = model:Clone();

    -- Manually reconstruct any missing Motor6Ds (bypasses games that break Clone())
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("Motor6D") and desc.Part0 and desc.Part1 then
            local p0_name = desc.Part0.Name
            local p1_name = desc.Part1.Name

            -- Check if the clone already has this joint
            local clone_p1 = new_clone:FindFirstChild(p1_name, true)
            if clone_p1 then
                local existing_joint = clone_p1:FindFirstChild(desc.Name)
                if not existing_joint then
                    local clone_p0 = new_clone:FindFirstChild(p0_name, true)
                    if clone_p0 then
                        local new_motor = Instance.new("Motor6D")
                        new_motor.Name = desc.Name
                        new_motor.Part0 = clone_p0
                        new_motor.Part1 = clone_p1
                        new_motor.C0 = desc.C0
                        new_motor.C1 = desc.C1
                        new_motor.Parent = clone_p1
                    end
                end
            end
        end
    end

    for obj, arch in pairs(old_archivables) do
        if obj and obj.Parent then
            obj.Archivable = arch
        end
    end
	new_clone.Name = "Reanimation";
	new_clone.Parent = onyx.services.workspace;
	new_clone:WaitForChild("Animate").Disabled = true;
    new_clone.Humanoid.RequiresNeck = false;
    new_clone.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
	if new_clone:FindFirstChildWhichIsA("ForceField") then
		new_clone:FindFirstChildWhichIsA("ForceField"):Destroy();
	end;
	return new_clone;
end;

local fire_remote = function(remote, is_local, ...)
	if typeof(remote) ~= "Instance" then
		return ("bad argument to 'fire_remote' (Instance expected, got %s)"):format(typeof(remote));
	end;
	if is_local then
		-- Handle local events (BindableEvent)
		if not remote:IsA("BindableEvent") then
			return ("bad argument to 'fire_remote' (BindableEvent expected for local event, got %s)"):format(remote.ClassName);
		end;
		remote:Fire(...);
	else
		-- Handle remote events/functions
		if not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
			return ("bad argument to 'fire_remote' (RemoteEvent or RemoteFunction expected, got %s)"):format(remote.ClassName);
		end;
		if remote:IsA("RemoteEvent") then
			remote:FireServer(...);
		else
			remote:InvokeServer(...);
		end;
	end;
end;

--- Stops any currently playing animation.
onyxAPI.stop_animation = (function()
    if onyx.connections.animation_hb then
        onyx.connections.animation_hb:Disconnect();
        onyx.connections.animation_hb = nil;
    end

    if not onyx.animation.state.is_playing then return end;

	local stopped_url = onyx.animation.state.current_url

    local player = get_local_player();
    if typeof(player) == "string" then return player end;

    local clone_char = onyxAPI.get_clone(player);

    -- Shallow-copy originals so play_animation clearing the table mid-fade
    -- doesn't wipe out what we need for finalization.
    local originals = {}
    for m, c in pairs(onyx.animation.original_motor_c0s) do originals[m] = c end

    -- Snapshot current Motor6D.Transform for the smooth ease-out
    local motorsToFade = {}
    if _G._SlateSmoothTransitionsEnabled == true and clone_char then
        for motor, _ in pairs(originals) do
            if motor and motor.Parent then
                local ok, cur = pcall(function() return motor.Transform end)
                if ok and cur then motorsToFade[motor] = cur end
            end
        end
    end

    local function restoreCharacter()
        if not (clone_char and clone_char.Parent) then return end
        -- Reset transforms from anti-anim-recorder random angles
        for _, desc in ipairs(clone_char:GetDescendants()) do
            if desc:IsA("Motor6D") or desc:IsA("AnimationConstraint") then
                pcall(function() desc.Transform = CFrame.new() end)
            end
        end

        -- Restore joint bases so the natural Animate script has clean C0s to work from.
        for motor, orig_c0 in pairs(originals) do
            if motor and motor.Parent then
                if motor:IsA("Motor6D") or motor:IsA("Motor") or motor:IsA("Weld") then
                    pcall(function() motor.C0 = orig_c0 end)
                end
            end
        end

        local animator = clone_char:FindFirstChild("Humanoid") and clone_char.Humanoid:FindFirstChild("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end

        -- Bounce-restart the Animate script so the natural idle/walk starts writing Transform
        -- IMMEDIATELY — this is what keeps the character standing during the fade.
        local clone_animate_script = clone_char:FindFirstChild("Animate")
        if clone_animate_script and clone_animate_script:IsA("LocalScript") then
            clone_animate_script.Disabled = true
            task.defer(function()
                if clone_animate_script and clone_animate_script.Parent then
                    clone_animate_script.Disabled = false
                end
            end)
        end

        local humanoid = clone_char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    local function clearState()
        table.clear(onyx.animation.original_motor_c0s);
        table.clear(onyx.animation.joints);
        onyx.animation.state = { is_playing = false, current_url = nil, speed = 1.0, keyframes = nil, total_duration = 0, elapsed_time = 0, play_token = (onyx.animation.state.play_token or 0) + 1 };
        if onyx.callbacks.on_stop then
            pcall(onyx.callbacks.on_stop, stopped_url)
        end
    end

    -- Mark stopped immediately.
    onyx.animation.state.is_playing = false

    -- Kick the natural animator back on RIGHT AWAY. Otherwise the fade window is 0.55s
    -- of no walk anim = the puppet slumps onto the ground (the "tangled" look).
    restoreCharacter()

    if next(motorsToFade) then
        if onyx.animation.stop_fade_conn then
            pcall(function() onyx.animation.stop_fade_conn:Disconnect() end)
            onyx.animation.stop_fade_conn = nil
        end
        local fadeDur = _G._SlateSmoothTransitionsDuration or 0.55
        local fadeToken = (onyx.animation.stop_fade_token or 0) + 1
        onyx.animation.stop_fade_token = fadeToken
        local elapsed = 0
        local fadeConn
        fadeConn = onyx.services.run_service.Stepped:Connect(function(_, dt)
            if onyx.animation.stop_fade_token ~= fadeToken or onyx.animation.state.is_playing then
                pcall(function() fadeConn:Disconnect() end)
                if onyx.animation.stop_fade_conn == fadeConn then onyx.animation.stop_fade_conn = nil end
                return
            end
            elapsed = elapsed + (dt or 0)
            local raw = math.clamp(elapsed / fadeDur, 0, 1)
            -- Quintic ease-in-out
            local tt = raw * raw * raw * (raw * (raw * 6 - 15) + 10)
            for motor, startCF in pairs(motorsToFade) do
                if motor and motor.Parent then
                    pcall(function()
                        -- motor.Transform was just written by the Animate script this frame.
                        -- Blend anim's last pose (startCF) toward Animate's current write.
                        -- t=0 → keep flip pose; t=1 → fully hand over to natural anim.
                        local liveCF = motor.Transform
                        motor.Transform = startCF:Lerp(liveCF, tt)
                    end)
                end
            end
            if raw >= 1 then
                pcall(function() fadeConn:Disconnect() end)
                if onyx.animation.stop_fade_conn == fadeConn then onyx.animation.stop_fade_conn = nil end
                clearState()
            end
        end)
        onyx.animation.stop_fade_conn = fadeConn
    else
        clearState()
    end
end);

-- Helper to normalize JSON animation formats (including Sharps spin and flip.json format)
local function normalizeJSONAnimation(decoded)
	if type(decoded) ~= "table" then return decoded end

	local function convertVal(v)
		if type(v) == "table" and #v == 12 then
			return CFrame.new(table.unpack(v))
		elseif type(v) == "table" and #v == 3 then
			return Vector3.new(table.unpack(v))
		elseif type(v) == "string" and v:find("CFrame.new") then
			local n = {}
			for num in v:gmatch("([%d%.%-]+)") do
				table.insert(n, tonumber(num))
			end
			if #n == 12 then
				return CFrame.new(table.unpack(n))
			elseif #n == 3 then
				return Vector3.new(table.unpack(n))
			end
		end
		return v
	end

	if decoded[1] and type(decoded[1]) == "table" then
		local resultList = {}
		for _, item in ipairs(decoded) do
			if type(item) == "table" then
				local tVal = item.t or item.Time or item.time or 0
				local dVal = item.d or item.Data or item.data or item
				local frameData = {}
				if type(dVal) == "table" then
					for partName, pData in pairs(dVal) do
						frameData[partName] = convertVal(pData)
					end
				end
				table.insert(resultList, { Time = tonumber(tVal) or 0, Data = frameData })
			end
		end
		return { CustomAnim = resultList }
	elseif type(decoded) == "table" then
		for k, v in pairs(decoded) do
			if type(v) == "table" then
				if #v == 12 then
					decoded[k] = CFrame.new(table.unpack(v))
				elseif #v == 3 then
					decoded[k] = Vector3.new(table.unpack(v))
				else
					normalizeJSONAnimation(v)
				end
			end
		end
	end
	return decoded
end

--- Toggles the Reanimate state.
-- @param bool (boolean) - true to enable reanimation, false to disable.
-- @param remote (Instance) [optional] - A RemoteEvent or RemoteFunction to fire.
-- @param args (table) [optional] - Arguments for the remote.
onyxAPI.reanimate = function(bool, remote, args)
	if bool ~= true and bool ~= false then
		return ("bad argument #1 to 'reanimate' (boolean expected, got %s)"):format(typeof(bool));
	end;
	local player = get_local_player();
	if typeof(player) == "string" then return player end;

	-- Auto-detect game ragdoll remote if none provided
	local is_local_event = false;
	if not remote then
		local game_remote, game_args, is_local = get_game_ragdoll_info(bool);
		if game_remote then
			remote = game_remote;
			args = game_args;
			is_local_event = is_local;
		end;
	end;

	if bool then
		if onyx.flags.reanimated then
			return "Already reanimated.";
		end;
		local real_char = get_char(player);
        if typeof(real_char) == "string" then return real_char end;
		if not real_char:FindFirstChild("Humanoid") then
			return "Real character is missing a Humanoid.";
		end;
		local real_hrp = real_char:FindFirstChild("HumanoidRootPart")
		if not real_hrp then
			return "Real character is missing a HumanoidRootPart, cannot reanimate.";
		end
		onyx.real_chars[player] = real_char;
		local cloned_char = clone_char(real_char);
        if typeof(cloned_char) == "string" then return cloned_char end;
		if not cloned_char:FindFirstChild("Humanoid") then
			return "Cloned character failed to create or is missing a Humanoid.";
		end;
		onyx.clones[player] = cloned_char;
		set_model_transparency(cloned_char, 1);
		-- Rename real_char away from the player's name so game scripts don't find it,
		-- and give the clone the player's actual name so native game scripts (like Mic Up's
		-- click_the_player GUI) work correctly with LocalPlayer.Character / workspace[name].
		local _realCharOriginalName = real_char.Name
		pcall(function() real_char.Name = "_slate_real_" .. player.Name end)
		pcall(function() cloned_char.Name = player.Name end)
		onyx._realCharOriginalName = _realCharOriginalName
		local player_gui = player:FindFirstChildWhichIsA("PlayerGui");
		if player_gui then
			for _, gui in player_gui:GetChildren() do
				if gui:IsA("ScreenGui") and gui.ResetOnSpawn then
					gui.ResetOnSpawn = false;
				end;
			end;
		end;
		player.Character = cloned_char;
		cloned_char:WaitForChild("Animate").Disabled = true;
		cloned_char:WaitForChild("Animate").Disabled = false;
		if player_gui then
			for _, gui in player_gui:GetChildren() do
				if gui:IsA("ScreenGui") and not gui.ResetOnSpawn then
					gui.ResetOnSpawn = true;
				end;
			end;
		end;
		-- Reanimation character position and collision sync
		onyx.connections.hb = onyx.services.run_service.Heartbeat:Connect((function()
			LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
			if not real_char or not real_char.Parent or not cloned_char or not cloned_char.Parent then
				onyxAPI.reanimate(false, remote, args);
				return;
			end;
			for _, p in real_char:GetChildren() do
				local clone_part = cloned_char:FindFirstChild(p.Name);
				if p:IsA("BasePart") and clone_part then
					pcall(function()
						p.CFrame = clone_part.CFrame;
						p.CanCollide = false;
						-- Zero velocity using whichever API is available
						if p.AssemblyLinearVelocity ~= nil then
							p.AssemblyLinearVelocity = Vector3.new();
							p.AssemblyAngularVelocity = Vector3.new();
						else
							p.Velocity = Vector3.new();
						end
					end)
				end;
			end;
		end));
		local real_humanoid = real_char.Humanoid;
		pcall(function() real_humanoid.RequiresNeck = false end)
		local cloned_humanoid = cloned_char.Humanoid;
		onyx.connections.died = real_humanoid.Died:Connect(function()
			if not onyx.flags.reanimated then return end
			onyxAPI.reanimate(false, remote, args);
		end);
		onyx.connections.real_char_child_removed = real_char.ChildRemoved:Connect(function(child)
			if not onyx.flags.reanimated then return end
			if child == real_humanoid or child == real_hrp then
				onyxAPI.reanimate(false, remote, args);
			end;
		end);
		onyx.connections.clone_char_child_removed = cloned_char.ChildRemoved:Connect(function(child)
			if not onyx.flags.reanimated then return end
			if child == cloned_humanoid then
				onyxAPI.reanimate(false, remote, args);
			end;
		end);
		onyx.connections.clone_died = cloned_humanoid.Died:Connect(function()
			if not onyx.flags.reanimated then return end
			local current_real_humanoid = real_char and real_char:FindFirstChild("Humanoid");
			if current_real_humanoid and current_real_humanoid.Health > 0 then
				current_real_humanoid.Health = 0;
			else
				onyxAPI.reanimate(false, remote, args);
			end;
		end);
		onyx.connections.character_removing = player.CharacterRemoving:Connect(function(character_being_removed)
			if not onyx.flags.reanimated then return end
			if character_being_removed == cloned_char or character_being_removed == real_char then
				onyxAPI.reanimate(false, remote, args);
			end;
		end);
		if remote then
			local err = fire_remote(remote, is_local_event, unpack(args or {}));
            if err then return err end;
		end;
		onyx.flags.reanimated = true;
	else
		onyx.flags.reanimated = false;
        onyxAPI.stop_animation();

		-- Clear tracker states and reset joint transforms on un-reanimate
		_G._HaloHeadTrackerEnabled = false
		_G._HaloLeftArmPointerEnabled = false
		_G._HaloRightArmPointerEnabled = false
		_G._HaloArmPointerSmoothedCF_Left = nil
		_G._HaloArmPointerSmoothedCF_Right = nil
		_G._HaloArmStretchSmoothedMult_Left = nil
		_G._HaloArmStretchSmoothedMult_Right = nil

		if remote then
			local err = fire_remote(remote, is_local_event, unpack(args or {}));
            if err then return err end;
		end;
		for key, connection in pairs(onyx.connections) do
			if connection then
				pcall(function() connection:Disconnect() end);
				onyx.connections[key] = nil;
			end;
		end;
		local cloned_char = onyx.clones[player];
		if cloned_char and cloned_char.Parent then
			pcall(function() cloned_char:Destroy() end);
			onyx.clones[player] = nil;
		end;
		local real_char = onyx.real_chars[player];
		if real_char and real_char.Parent then
			set_model_transparency(real_char, 0);
			local hrp = real_char:FindFirstChild("HumanoidRootPart");
			if hrp then
				hrp.Transparency = 1;
			end;
			-- Restore the real character's original name so workspace[player.Name] resolves correctly
			if onyx._realCharOriginalName then
				pcall(function() real_char.Name = onyx._realCharOriginalName end)
				onyx._realCharOriginalName = nil
			end
			local player_gui = player:FindFirstChildWhichIsA("PlayerGui");
			if player_gui then
				for _, gui in player_gui:GetChildren() do
					if gui:IsA("ScreenGui") and gui.ResetOnSpawn then
						gui.ResetOnSpawn = false;
					end;
				end;
			end;
			player.Character = real_char;
			local cam = workspace.CurrentCamera or (workspaceService and workspaceService.CurrentCamera)
			if cam then
				local hum = real_char:FindFirstChildWhichIsA("Humanoid")
				if hum then
					cam.CameraSubject = hum
				else
					cam.CameraSubject = real_char
				end
				cam.CameraType = Enum.CameraType.Custom
			end

            local animator = real_char:FindFirstChild("Humanoid") and real_char.Humanoid:FindFirstChild("Animator");
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop();
                end
            end

            local animate_script = real_char:FindFirstChild("Animate");
			if animate_script and animate_script:IsA("LocalScript") then
				animate_script.Disabled = true;
				task.defer(function()
					if animate_script and animate_script.Parent then
						animate_script.Disabled = false;
					end
				end);
			end;
			if player_gui then
				for _, gui in player_gui:GetChildren() do
					if gui:IsA("ScreenGui") and not gui.ResetOnSpawn then
						gui.ResetOnSpawn = true;
					end;
				end;
			end;
		end;
		onyx.flags.reanimated = false;
	end;
end;

-- =========================================================================
-- SHARED TRACKERS & LIMBS LOGIC (Unified for both Animation & Standalone)
-- =========================================================================

task.wait()
local function _HaloFindConstraintOnClone(char, partName)
	if not char then return nil end

	local primaryNames = {}
	local secondaryNames = {}

	if partName == "Head" then
		primaryNames = { "Neck" }
		secondaryNames = { "Head" }
	elseif partName == "RightUpperArm" or partName == "Right Arm" then
		primaryNames = { "Right Shoulder", "RightShoulder" }
		secondaryNames = { "RightUpperArm", "Right Arm" }
	elseif partName == "LeftUpperArm" or partName == "Left Arm" then
		primaryNames = { "Left Shoulder", "LeftShoulder" }
		secondaryNames = { "LeftUpperArm", "Left Arm" }
	elseif partName == "RightLowerArm" then
		primaryNames = { "RightElbow", "Right Elbow" }
		secondaryNames = { "RightLowerArm" }
	elseif partName == "LeftLowerArm" then
		primaryNames = { "LeftElbow", "Left Elbow" }
		secondaryNames = { "LeftLowerArm" }
	elseif partName == "RightHand" then
		primaryNames = { "RightWrist", "Right Wrist" }
		secondaryNames = { "RightHand" }
	elseif partName == "LeftHand" then
		primaryNames = { "LeftWrist", "Left Wrist" }
		secondaryNames = { "LeftHand" }
	elseif partName == "Waist" or partName == "UpperTorso" then
		primaryNames = { "Waist" }
		secondaryNames = { "UpperTorso" }
	elseif partName == "Torso" or partName == "LowerTorso" then
		primaryNames = { "Waist" }
		secondaryNames = { "LowerTorso", "Torso" }
	elseif partName == "RightUpperLeg" or partName == "Right Leg" then
		primaryNames = { "Right Hip", "RightHip" }
		secondaryNames = { "RightUpperLeg", "Right Leg" }
	elseif partName == "LeftUpperLeg" or partName == "Left Leg" then
		primaryNames = { "Left Hip", "LeftHip" }
		secondaryNames = { "LeftUpperLeg", "Left Leg" }
	elseif partName == "RightLowerLeg" then
		primaryNames = { "RightKnee", "Right Knee" }
		secondaryNames = { "RightLowerLeg" }
	elseif partName == "LeftLowerLeg" then
		primaryNames = { "LeftKnee", "Left Knee" }
		secondaryNames = { "LeftLowerLeg" }
	else
		primaryNames = { partName }
	end

	local descendants = char:GetDescendants()
	-- Pass 1: check primary joint names
	for _, desc in ipairs(descendants) do
		if desc:IsA("Motor6D") or desc:IsA("AnimationConstraint") then
			for _, pName in ipairs(primaryNames) do
				if desc.Name == pName then
					return desc
				end
			end
		end
	end

	-- Pass 2: check Part1 or Attachment1 names
	for _, desc in ipairs(descendants) do
		if desc:IsA("Motor6D") and desc.Part1 then
			for _, sName in ipairs(secondaryNames) do
				if desc.Part1.Name == sName then
					return desc
				end
			end
		elseif desc:IsA("AnimationConstraint") and desc.Attachment1 and desc.Attachment1.Parent then
			for _, sName in ipairs(secondaryNames) do
				if desc.Attachment1.Parent.Name == sName then
					return desc
				end
			end
		end
	end

	-- Pass 3: check if desc.Name matches secondaryNames
	for _, desc in ipairs(descendants) do
		if desc:IsA("Motor6D") or desc:IsA("AnimationConstraint") then
			for _, sName in ipairs(secondaryNames) do
				if desc.Name == sName then
					return desc
				end
			end
		end
	end

	return nil
end

local function _HaloGetMouseTargetPosition(camera, localPlayer, targetChar)
	local UserInputService = game:GetService("UserInputService")
	local mouseLocation = UserInputService:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local filterList = {}
	if localPlayer and localPlayer.Character then table.insert(filterList, localPlayer.Character) end
	if targetChar then table.insert(filterList, targetChar) end
	if onyxAPI and onyxAPI.get_clone then
		local c = onyxAPI.get_clone(localPlayer)
		if c and c ~= targetChar then table.insert(filterList, c) end
	end
	if onyxAPI and onyxAPI.get_real_character then
		local r = onyxAPI.get_real_character(localPlayer)
		if r then table.insert(filterList, r) end
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = filterList
	rayParams.CollisionGroup = "Default"

	local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, rayParams)
	if hit then
		return hit.Position
	else
		return unitRay.Origin + unitRay.Direction * 2000
	end
end

-- Global LMB-over-UI latch: set to true when LMB is pressed while any UI (Slate or otherwise)
-- had focus (gameProcessedEvent == true), cleared when LMB is released. Prevents trackers
-- from following the cursor while the user is dragging / clicking on UI.
if not _G._HaloUIInputLatchInit then
	_G._HaloUIInputLatchInit = true
	_G._HaloLMBOverUI = false
	local uis_ = game:GetService("UserInputService")
	uis_.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			_G._HaloLMBOverUI = processed == true
		end
	end)
	uis_.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			_G._HaloLMBOverUI = false
		end
	end)
end

local function _HaloIsClickingSlateUI()
	if _G._HaloLMBOverUI then return true end
	local UserInputService = game:GetService("UserInputService")
	local mouseLocation = UserInputService:GetMouseLocation()
	local gui = _G.AKReanimGUIInstance
	if gui and gui.Parent and gui.Enabled then
		for _, child in ipairs(gui:GetChildren()) do
			if child:IsA("GuiObject") and child.Visible then
				local pos = child.AbsolutePosition
				local sz = child.AbsoluteSize
				if mouseLocation.X >= pos.X and mouseLocation.X <= (pos.X + sz.X) and mouseLocation.Y >= pos.Y and mouseLocation.Y <= (pos.Y + sz.Y) then
					return true
				end
			end
		end
	end
	-- Fallback: any GUI object under the cursor across all ScreenGuis in PlayerGui / CoreGui
	local ok, hits = pcall(function()
		local plr = game:GetService("Players").LocalPlayer
		local playerGui = plr and plr:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			local h = playerGui:GetGuiObjectsAtPosition(mouseLocation.X, mouseLocation.Y)
			if h and #h > 0 then return true end
		end
		return false
	end)
	if ok and hits then return true end
	return false
end

local function _HaloApplyAllTrackers(targetChar, deltaTime, isFromAnim)
	if not (onyx and onyx.flags and onyx.flags.reanimated) then return end
	if not targetChar or not targetChar.Parent then return end
	local dt = math.clamp(tonumber(deltaTime) or 0.016, 0.001, 0.1)
	local camera = workspace.CurrentCamera
	local localPlayer = get_local_player()
	if typeof(localPlayer) == "string" then localPlayer = nil end

	-- Ensure clone parts are massless and non-colliding with real character to prevent teleporting/flinging
	for _, p in ipairs(targetChar:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.CanCollide = false
		end
	end

	-- 1. Head Tracker
	if _G._HaloHeadTrackerEnabled then
		local headConstraint = _HaloFindConstraintOnClone(targetChar, "Head")
		if headConstraint and camera then
			local headPivotCF = nil
			if headConstraint:IsA("Motor6D") and headConstraint.Part0 then
				headPivotCF = headConstraint.Part0.CFrame * headConstraint.C0
			elseif headConstraint.Attachment0 and headConstraint.Attachment0.Parent then
				headPivotCF = headConstraint.Attachment0.WorldCFrame
			end

			if headPivotCF then
				local camLook = camera.CFrame.LookVector
				local localCamLook = headPivotCF.Rotation:Inverse() * camLook
				local yaw = math.atan2(localCamLook.X, -localCamLook.Z)
				local pitch = math.asin(math.clamp(localCamLook.Y, -1, 1))
				local maxYaw, maxPitch = math.rad(75), math.rad(55)
				yaw = math.clamp(yaw, -maxYaw, maxYaw)
				pitch = math.clamp(pitch, -maxPitch, maxPitch)

				local c1RotInv = (headConstraint:IsA("Motor6D") and headConstraint.C1.Rotation:Inverse())
					or (headConstraint.Attachment1 and headConstraint.Attachment1.CFrame.Rotation:Inverse())
					or CFrame.new()
				local restHeadDir = (c1RotInv * Vector3.new(0, 0, -1)).Unit
				local desiredHeadDir = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)).Unit

				local cross = restHeadDir:Cross(desiredHeadDir)
				local dot = math.clamp(restHeadDir:Dot(desiredHeadDir), -1, 1)
				local targetRot = CFrame.new()
				if cross.Magnitude > 0.001 then
					targetRot = CFrame.fromAxisAngle(cross.Unit, math.acos(dot))
				elseif dot < -0.999 then
					targetRot = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.pi)
				end

				local curSmoothed = _G._HaloHeadTrackerSmoothedCF or targetRot
				local smoothFactor = 1 - math.exp(-18 * dt)
				local nextSmoothed = curSmoothed:Lerp(targetRot, smoothFactor)
				_G._HaloHeadTrackerSmoothedCF = nextSmoothed

				headConstraint.Transform = nextSmoothed
			end
		end
	else
		if _G._HaloHeadTrackerSmoothedCF then
			local headConstraint = _HaloFindConstraintOnClone(targetChar, "Head")
			local cur = _G._HaloHeadTrackerSmoothedCF
			local smoothFactor = 1 - math.exp(-18 * dt)
			local nextCF = cur:Lerp(CFrame.new(), smoothFactor)
			if (nextCF.LookVector - Vector3.new(0, 0, -1)).Magnitude < 0.01 then
				_G._HaloHeadTrackerSmoothedCF = nil
				if not isFromAnim and headConstraint then
					headConstraint.Transform = CFrame.new()
				end
			else
				_G._HaloHeadTrackerSmoothedCF = nextCF
				if headConstraint then
					headConstraint.Transform = nextCF
				end
			end
		end
	end

	-- 2. Arm Pointers & Stretch (ONLY follows mouse when holding LMB!)
	local anyArmPointer = _G._HaloRightArmPointerEnabled or _G._HaloLeftArmPointerEnabled
	local hasArmSmoothedState = _G._HaloArmPointerSmoothedCF_Right or _G._HaloArmPointerSmoothedCF_Left or _G._HaloArmStretchSmoothed_Right or _G._HaloArmStretchSmoothed_Left

	if anyArmPointer or hasArmSmoothedState then
		local UserInputService = game:GetService("UserInputService")
		local targetMousePos = nil
		if camera and localPlayer then
			targetMousePos = _HaloGetMouseTargetPosition(camera, localPlayer, targetChar)
		end

		local isLMBHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		local isTyping = UserInputService:GetFocusedTextBox() ~= nil
		local isClickingUI = _HaloIsClickingSlateUI()

		-- Manual stretch driver (keybind hold / scroll wheel).
		-- When either mode is active, the arm points at mouse but does NOT auto-stretch;
		-- instead the extra reach is grown by the keybind (rate) or scroll wheel (delta).
		local manualMode = (_G._HaloArmStretchKeybindEnabled == true) or (_G._HaloArmStretchScrollEnabled == true)
		_G._HaloArmStretchManualExtra = _G._HaloArmStretchManualExtra or 0
		if manualMode then
			if isLMBHeld and not isTyping and not isClickingUI then
				if _G._HaloArmStretchKeybindEnabled and _G._HaloArmStretchKey then
					local okKey, held = pcall(function()
						return UserInputService:IsKeyDown(_G._HaloArmStretchKey)
					end)
					if okKey and held then
						local rate = 14 -- studs per second growth while key held
						_G._HaloArmStretchManualExtra = _G._HaloArmStretchManualExtra + rate * dt
					end
				end
			else
				-- LMB released -> reset manual stretch so next LMB-hold starts at 0
				_G._HaloArmStretchManualExtra = 0
			end
		end

		local function pointArm(upperName, lowerName, handName, isRight, isEnabled)
			local shoulderConstraint = _HaloFindConstraintOnClone(targetChar, upperName)
			if not shoulderConstraint then return end

			local elbowConstraint = _HaloFindConstraintOnClone(targetChar, lowerName)
			local wristConstraint = _HaloFindConstraintOnClone(targetChar, handName)

			local stateKeyRot = isRight and "_HaloArmPointerSmoothedCF_Right" or "_HaloArmPointerSmoothedCF_Left"
			local stateKeyStretch = isRight and "_HaloArmStretchSmoothed_Right" or "_HaloArmStretchSmoothed_Left"

			-- User requirement: ONLY follow mouse when holding LMB!
			local shouldFollowMouse = isEnabled and isLMBHeld and not isTyping and not isClickingUI

			if shouldFollowMouse then
				-- Disable collision and mass on arm parts so stretching into the ground/character never causes jumping/teleporting/flinging
				local partNames = isRight and { "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm" }
					or { "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm" }
				for _, pName in ipairs(partNames) do
					local p = targetChar:FindFirstChild(pName)
					if p and p:IsA("BasePart") then
						p.CanCollide = false
						p.Massless = true
					end
					if localPlayer and onyxAPI and onyxAPI.get_real_character then
						local realChar = onyxAPI.get_real_character(localPlayer)
						if realChar then
							local rp = realChar:FindFirstChild(pName)
							if rp and rp:IsA("BasePart") then
								rp.CanCollide = false
								rp.Massless = true
							end
						end
					end
				end

				local shoulderPivotCF = nil
				if shoulderConstraint:IsA("Motor6D") and shoulderConstraint.Part0 then
					shoulderPivotCF = shoulderConstraint.Part0.CFrame * shoulderConstraint.C0
				elseif shoulderConstraint.Attachment0 and shoulderConstraint.Attachment0.Parent then
					shoulderPivotCF = shoulderConstraint.Attachment0.WorldCFrame
				end

				if shoulderPivotCF and targetMousePos then
					local shoulderPos = shoulderPivotCF.Position
					local toTarget = targetMousePos - shoulderPos
					local distToTarget = toTarget.Magnitude

					if distToTarget > 0.001 then
						local aimWorldDir = toTarget / distToTarget

						local c1RotInv = (shoulderConstraint:IsA("Motor6D") and shoulderConstraint.C1.Rotation:Inverse())
							or (shoulderConstraint.Attachment1 and shoulderConstraint.Attachment1.CFrame.Rotation:Inverse())
							or CFrame.new()
						local armRestDirInJoint = (c1RotInv * Vector3.new(0, -1, 0)).Unit
						local desiredAimInJoint = (shoulderPivotCF.Rotation:Inverse() * aimWorldDir).Unit

						local dot = math.clamp(armRestDirInJoint:Dot(desiredAimInJoint), -1, 1)
						local cross = armRestDirInJoint:Cross(desiredAimInJoint)
						local targetShoulderRot = CFrame.new()
						if cross.Magnitude > 0.0001 then
							targetShoulderRot = CFrame.fromAxisAngle(cross.Unit, math.acos(dot))
						elseif dot < -0.9999 then
							local perp = armRestDirInJoint:Cross(Vector3.new(0, 0, 1))
							if perp.Magnitude < 0.01 then perp = armRestDirInJoint:Cross(Vector3.new(1, 0, 0)) end
							targetShoulderRot = CFrame.fromAxisAngle(perp.Unit, math.pi)
						end

						local curRot = _G[stateKeyRot] or targetShoulderRot
						-- Softer rotation when stretched / in manual mode so a long arm
						-- doesn't whip around while you run or scroll.
						local rotRate = manualMode and 22 or 45
						local smoothFactor = 1 - math.exp(-rotRate * dt)
						local nextRot = curRot:Lerp(targetShoulderRot, smoothFactor)
						_G[stateKeyRot] = nextRot

						if isFromAnim then
							shoulderConstraint.Transform = nextRot * shoulderConstraint.Transform
						else
							shoulderConstraint.Transform = nextRot
						end

						-- Arm length & stretch calculation
						local upperLen = 1.0
						local lowerLen = 1.0
						local handLen = 0.5
						if shoulderConstraint:IsA("Motor6D") and shoulderConstraint.Part1 and shoulderConstraint.Part1:IsA("BasePart") then
							upperLen = shoulderConstraint.Part1.Size.Y
						end
						if elbowConstraint and elbowConstraint:IsA("Motor6D") and elbowConstraint.Part1 and elbowConstraint.Part1:IsA("BasePart") then
							lowerLen = elbowConstraint.Part1.Size.Y
						end
						if wristConstraint and wristConstraint:IsA("Motor6D") and wristConstraint.Part1 and wristConstraint.Part1:IsA("BasePart") then
							handLen = wristConstraint.Part1.Size.Y
						end
						local defaultArmLen = upperLen + lowerLen + handLen

						local targetExtraStretch = 0
						local maxLimitMult = _G._HaloArmStretchAmount or math.huge
						local maxReach = defaultArmLen * maxLimitMult
						if manualMode then
							local maxExtra = math.max(0, maxReach - defaultArmLen)
							_G._HaloArmStretchManualExtra = math.clamp(_G._HaloArmStretchManualExtra or 0, 0, maxExtra)
							targetExtraStretch = _G._HaloArmStretchManualExtra
						else
							local desiredReach = math.min(distToTarget, maxReach)
							if desiredReach > defaultArmLen then
								targetExtraStretch = math.max(0, desiredReach - defaultArmLen)
							end
						end

						local curStretch = _G[stateKeyStretch] or 0
						-- Slower stretch smoothing = gentler visual growth for keybind/scroll modes
						local stretchRate = manualMode and 10 or 40
						local stretchSmooth = 1 - math.exp(-stretchRate * dt)
						curStretch = curStretch + (targetExtraStretch - curStretch) * stretchSmooth
						_G[stateKeyStretch] = curStretch

						if elbowConstraint then
							elbowConstraint.Transform = CFrame.new(0, -curStretch, 0)
						end
						if wristConstraint then
							wristConstraint.Transform = CFrame.new()
						end
					end
				end
			else
				-- Not holding LMB: smoothly return arm to neutral/animation pose
				if _G[stateKeyRot] or _G[stateKeyStretch] then
					local curRot = _G[stateKeyRot] or CFrame.new()
					local curStretch = _G[stateKeyStretch] or 0
					local smoothFactor = 1 - math.exp(-24 * dt)

					local nextRot = curRot:Lerp(CFrame.new(), smoothFactor)
					local nextStretch = curStretch + (0 - curStretch) * smoothFactor

					local rx, ry, rz = nextRot:ToEulerAnglesYXZ()
					local rotDist = math.abs(rx) + math.abs(ry) + math.abs(rz)
					if rotDist < 0.02 and nextStretch < 0.02 then
						_G[stateKeyRot] = nil
						_G[stateKeyStretch] = nil
						if not isFromAnim then
							shoulderConstraint.Transform = CFrame.new()
							if elbowConstraint then elbowConstraint.Transform = CFrame.new() end
							if wristConstraint then wristConstraint.Transform = CFrame.new() end
						end
					else
						_G[stateKeyRot] = nextRot
						_G[stateKeyStretch] = nextStretch
						if isFromAnim then
							shoulderConstraint.Transform = nextRot * shoulderConstraint.Transform
						else
							shoulderConstraint.Transform = nextRot
						end
						if elbowConstraint then elbowConstraint.Transform = CFrame.new(0, -nextStretch, 0) end
						if wristConstraint then wristConstraint.Transform = CFrame.new() end
					end
				end
			end
		end

		pointArm("RightUpperArm", "RightLowerArm", "RightHand", true, _G._HaloRightArmPointerEnabled)
		pointArm("LeftUpperArm", "LeftLowerArm", "LeftHand", false, _G._HaloLeftArmPointerEnabled)
	end

	-- 3. Arm Slider
	if not _G._HaloArmSliderEnabled and _G._HaloArmSliderPrevEnabled then
		_G._HaloArmSliderPrevEnabled = false
		for constraint, orig in pairs(_G._HaloArmSliderOriginalTransforms or {}) do
			if constraint and constraint.Parent then pcall(function() constraint.Transform = orig end) end
		end
		_G._HaloArmSliderOriginalTransforms = {}
	end
	if _G._HaloArmSliderEnabled then
		_G._HaloArmSliderPrevEnabled = true
		_G._HaloArmSliderOriginalTransforms = _G._HaloArmSliderOriginalTransforms or {}
		local offsetX = _G._HaloArmSliderOffsetX or 0
		local offsetY = _G._HaloArmSliderOffsetY or 0
		local stretch = _G._HaloArmSliderStretch or 1.0
		local rotEnabled = _G._HaloArmSliderRotationEnabled or false
		local rotDeg = _G._HaloArmSliderRotation or 0

		local rUpper = _HaloFindConstraintOnClone(targetChar, "RightUpperArm")
		local rLower = _HaloFindConstraintOnClone(targetChar, "RightLowerArm")
		local rHand = _HaloFindConstraintOnClone(targetChar, "RightHand")
		local hipJoint = _HaloFindConstraintOnClone(targetChar, "Waist") or _HaloFindConstraintOnClone(targetChar, "LowerTorso")

		if rUpper and hipJoint then
			local hipWorldCF
			if hipJoint:IsA("Motor6D") then
				if hipJoint.Part0 then hipWorldCF = hipJoint.Part0.CFrame * hipJoint.C0
				elseif hipJoint.Part1 then hipWorldCF = hipJoint.Part1.CFrame * hipJoint.C1 end
			else
				local att0 = hipJoint.Attachment0
				if att0 and att0.Parent then hipWorldCF = att0.WorldCFrame end
			end

			if hipWorldCF then
				local targetPos = hipWorldCF.Position + hipWorldCF.RightVector * (0.3 + offsetX) + hipWorldCF.UpVector * (0.2 + offsetY) + hipWorldCF.LookVector * 0.25
				local stretchAngleDeg = math.clamp(-45 + (stretch - 1) * (130 / 9), -45, 85)
				local totalAngleDeg = stretchAngleDeg + (rotEnabled and rotDeg or 0)
				local t = math.clamp((stretch - 1) / 9, 0, 1)
				local swingAngle = math.rad(-15) + t * (math.rad(-135) - math.rad(-15))

				local armDir = (-hipWorldCF.UpVector * math.cos(swingAngle) - hipWorldCF.LookVector * math.sin(swingAngle) + hipWorldCF.RightVector * 0.15).Unit
				local yAxis = -armDir
				local xAxis = hipWorldCF.RightVector
				local desiredCF = CFrame.fromMatrix(targetPos, xAxis, yAxis)

				if not _G._HaloArmSliderOriginalTransforms[rUpper] then _G._HaloArmSliderOriginalTransforms[rUpper] = rUpper.Transform end
				if rLower and not _G._HaloArmSliderOriginalTransforms[rLower] then _G._HaloArmSliderOriginalTransforms[rLower] = rLower.Transform end
				if rHand and not _G._HaloArmSliderOriginalTransforms[rHand] then _G._HaloArmSliderOriginalTransforms[rHand] = rHand.Transform end

				if rUpper:IsA("Motor6D") and rUpper.Part0 and rUpper.Part1 then
					rUpper.Transform = rUpper.C0:Inverse() * rUpper.Part0.CFrame:Inverse() * desiredCF * rUpper.C1
				else
					local att0, att1 = rUpper.Attachment0, rUpper.Attachment1
					if att0 and att1 then rUpper.Transform = att0.WorldCFrame:Inverse() * (desiredCF * att1.CFrame) end
				end
			end
		end

		if rLower then
			local baseLen = 1.2
			if rLower:IsA("Motor6D") and rLower.Part1 and rLower.Part1:IsA("BasePart") then baseLen = rLower.Part1.Size.Y end
			rLower.Transform = (stretch ~= 1.0) and CFrame.new(Vector3.new(0, -baseLen * (stretch - 1.0), 0)) or CFrame.new()
		end
		if rHand then rHand.Transform = CFrame.new() end
	end

	-- 4. Torso Camera Control & Torso Stretcher
	if _G._HaloLimbsTorsoCamControl or _G._HaloTorsoStretcherEnabled then
		local waistConstraint = _HaloFindConstraintOnClone(targetChar, "Waist")
		-- Ensure we NEVER rotate HumanoidRootPart, which causes jumping/teleporting
		if waistConstraint and (
			(waistConstraint.Part0 and waistConstraint.Part0.Name == "HumanoidRootPart") or
			(waistConstraint.Part1 and waistConstraint.Part1.Name == "HumanoidRootPart")
		) then
			waistConstraint = nil
		end
		if waistConstraint then
			local baseRot = isFromAnim and waistConstraint.Transform.Rotation or CFrame.new()
			if _G._HaloLimbsTorsoCamControl then
				if camera then
					local parentWorldCF = nil
					if waistConstraint:IsA("Motor6D") and waistConstraint.Part0 then
						parentWorldCF = waistConstraint.Part0.CFrame * waistConstraint.C0
					else
						local att0 = waistConstraint.Attachment0
						if att0 and att0.Parent then parentWorldCF = att0.WorldCFrame end
					end
					if parentWorldCF then
						local camLook = camera.CFrame.LookVector
						local localLookDir = parentWorldCF.Rotation:Inverse() * camLook
						local yaw = math.atan2(localLookDir.X, -localLookDir.Z)
						local pitch = math.asin(math.clamp(localLookDir.Y, -1, 1))
						local camMode = _G._HaloLimbsTorsoCamMode or "360"
						local camRotCF
						if camMode == "Locked" then
							yaw = math.clamp(yaw, -math.rad(45), math.rad(45))
							pitch = math.clamp(pitch, -math.rad(30), math.rad(30))
							camRotCF = CFrame.fromEulerAnglesYXZ(pitch, -yaw, 0)
						elseif camMode == "Free" then
							camRotCF = parentWorldCF.Rotation:Inverse() * camera.CFrame.Rotation
						else
							camRotCF = CFrame.fromEulerAnglesYXZ(pitch * 2.25, -yaw, 0)
						end
						local curSmoothed = _G._HaloTorsoCamSmoothedCF or camRotCF
						local smoothFactor = 1 - math.exp(-18 * dt)
						local smoothed = curSmoothed:Lerp(camRotCF, smoothFactor)
						_G._HaloTorsoCamSmoothedCF = smoothed
						baseRot = smoothed * baseRot
					end
				end
			else
				_G._HaloTorsoCamSmoothedCF = nil
			end

			local utHeight = _G._HaloLimbsUpperTorsoHeight or 1.0
			local stretchY = _G._HaloTorsoStretcherEnabled and ((utHeight - 1.0) * 2.5) or 0
			waistConstraint.Transform = (stretchY ~= 0) and (CFrame.new(0, stretchY, 0) * baseRot) or baseRot
		end
	else
		if _G._HaloTorsoCamSmoothedCF then
			local waistConstraint = _HaloFindConstraintOnClone(targetChar, "Waist")
			if waistConstraint and (
				(waistConstraint.Part0 and waistConstraint.Part0.Name == "HumanoidRootPart") or
				(waistConstraint.Part1 and waistConstraint.Part1.Name == "HumanoidRootPart")
			) then
				waistConstraint = nil
			end
			local smoothFactor = 1 - math.exp(-18 * dt)
			local nextCF = _G._HaloTorsoCamSmoothedCF:Lerp(CFrame.new(), smoothFactor)
			if (nextCF.LookVector - Vector3.new(0, 0, -1)).Magnitude < 0.01 then
				_G._HaloTorsoCamSmoothedCF = nil
				if not isFromAnim and waistConstraint then waistConstraint.Transform = CFrame.new() end
			else
				_G._HaloTorsoCamSmoothedCF = nextCF
				if waistConstraint then waistConstraint.Transform = nextCF end
			end
		end
	end

	-- 5. Leg Stretcher
	if _G._HaloLegStretcherEnabled then
		local legScale = math.clamp(_G._HaloLimbsLegHeight or 1.0, 0.4, 100.0)
		if legScale ~= 1.0 then
			local kneeOffset = CFrame.new(0, -(legScale - 1.0) * 1.5, 0)
			local rll = _HaloFindConstraintOnClone(targetChar, "RightLowerLeg")
			local lll = _HaloFindConstraintOnClone(targetChar, "LeftLowerLeg")
			if rll then rll.Transform = kneeOffset * rll.Transform end
			if lll then lll.Transform = kneeOffset * lll.Transform end
		end
		local h = targetChar:FindFirstChildOfClass("Humanoid")
		if h then
			local defHip = h:GetAttribute("HaloDefaultHipHeight")
			if not defHip then
				defHip = (h.HipHeight > 0) and h.HipHeight or 2.0
				h:SetAttribute("HaloDefaultHipHeight", defHip)
			end
			h.HipHeight = defHip + math.max(0, (legScale - 1.0) * 1.5)
		end
	else
		local h = targetChar:FindFirstChildOfClass("Humanoid")
		if h then
			local defHip = h:GetAttribute("HaloDefaultHipHeight")
			if defHip then
				h.HipHeight = defHip
				h:SetAttribute("HaloDefaultHipHeight", nil)
			end
		end
	end
end

task.wait()
--- Plays an animation on the reanimated character.
-- @param url (string) - The URL of the keyframe script.
-- @param speed (number) [optional] - The playback speed multiplier. Defaults to 1.
onyxAPI.play_animation = (function(url, speed)
    if not onyx.flags.reanimated then
        return "Cannot play animation, not reanimated.";
    end

    local player = get_local_player();
    if typeof(player) == "string" then return player end;

    local clone_char = onyxAPI.get_clone(player);
    if not clone_char then
        return "Cannot play animation, clone character not found.";
    end

    if onyx.animation.state.is_playing and onyx.animation.state.current_url == url then
        onyxAPI.stop_animation();
        return;
    end

    local prevJointTransforms = {}
    local transitionElapsed = 0
    if _G._SlateSmoothTransitionsEnabled ~= false and clone_char then
        for _, desc in ipairs(clone_char:GetDescendants()) do
            if (desc:IsA("Motor6D") or desc:IsA("AnimationConstraint")) and desc.Part1 then
                prevJointTransforms[desc.Part1.Name] = desc.Transform
            end
        end
    end

    onyxAPI.stop_animation();

    if not _G._HaloHeadTrackerEnabled then _G._HaloHeadTrackerSmoothedCF = nil end
    if not _G._HaloRightArmPointerEnabled then
        _G._HaloArmPointerSmoothedCF_Right = nil
        _G._HaloArmStretchSmoothed_Right = nil
    end
    if not _G._HaloLeftArmPointerEnabled then
        _G._HaloArmPointerSmoothedCF_Left = nil
        _G._HaloArmStretchSmoothed_Left = nil
    end
    if not _G._HaloLimbsTorsoCamControl then _G._HaloTorsoCamSmoothedCF = nil end

    local clone_anim_controller = clone_char:FindFirstChildOfClass("Humanoid") or clone_char:FindFirstChildOfClass("AnimationController")
    if clone_anim_controller then
        for _, track in ipairs(clone_anim_controller:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
    local clone_animate_script = clone_char:FindFirstChild("Animate")
    if clone_animate_script then
        clone_animate_script.Disabled = true
        -- Use task.defer instead of task.wait() to avoid a frame of delay that
        -- breaks animation timing under obfuscation.
        task.defer(function()
            if clone_animate_script and clone_animate_script.Parent then
                clone_animate_script.Disabled = false
            end
        end)
    end

    -- Ensure humanoid is in proper state for animation playback
    local humanoid = clone_char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.PlatformStand = false -- Prevent platform stand which causes stiffness
    end

    local anim = onyx.animation;
    local playToken = (anim.state.play_token or 0) + 1;
    anim.state.play_token = playToken;
    local animSpeed = tonumber(speed) or 1.0;
    anim.state.speed = animSpeed;

    if type(url) == "table" and (url.clips or url.anim1) then
        if _G.playCombinedSequence then task.spawn(function() _G.playCombinedSequence(url) end) end
        return
    end
    if type(url) == "string" and _G.combinedSequences then
        for _, seq in ipairs(_G.combinedSequences) do
            if seq.name == url then
                if _G.playCombinedSequence then task.spawn(function() _G.playCombinedSequence(seq) end) end
                return
            end
        end
    end

    local keyframe_data = anim.cache[url];
    if not keyframe_data then
        local response

        -- Check if url is actually raw keyframe data (contains keyframe patterns)
        local is_raw_keyframe_data = url:match("{Time%s*=") or url:match("Time%s*=") or url:match("CFrame%.new")

        if is_raw_keyframe_data then
            -- Treat as raw keyframe data directly
            response = url
        elseif url:sub(1, 4) == "http" then
            local cache_path
            if isfolder and makefolder and isfile and readfile and writefile then
                if not isfolder("OnyxAnimCache") then
                    pcall(makefolder, "OnyxAnimCache")
                end
                local cleanUrl = url:match("^([^?]+)") or url
                local safe_name = cleanUrl:match("([^/]+)$") or "unknown.lua"
                safe_name = safe_name:gsub("[^%w%.%-]", "_")
                cache_path = "OnyxAnimCache/" .. safe_name
            end

            if cache_path and isfile(cache_path) then
                local success, file_res = pcall(readfile, cache_path)
                if success then
                    response = file_res
                end
            end

            if not response then
                local success, http_res = pcall(game.HttpGet, game, url);
                if not success then return "Animation Error: Failed to fetch URL." end
                response = http_res

                if cache_path then
                    pcall(writefile, cache_path, response)
                end
            end
        else
            -- Check transformCache or local file paths / animation name
            local codeInCache = transformCache and transformCache[url]
            if codeInCache and type(codeInCache) == "string" and codeInCache ~= "" and not codeInCache:match("^combined:") then
                response = codeInCache
                if (codeInCache:match("^slate/") or codeInCache:match("%.lua$") or codeInCache:match("%.json$")) and type(readfile) == "function" then
                    local okR, fData = pcall(readfile, codeInCache)
                    if okR and fData and fData ~= "" then response = fData end
                end
            elseif type(readfile) == "function" then
                local candidatePaths = {
                    url,
                    url .. ".lua",
                    url .. ".json",
                    "slate/reanimation/" .. url,
                    "slate/reanimation/" .. url .. ".json",
                    "slate/reanimation/" .. url .. ".lua",
                    "slate/reanimation/customs/" .. url,
                    "slate/reanimation/customs/" .. url .. ".lua",
                    "ReanimData/" .. url,
                    "ReanimData/" .. url .. ".lua",
                    "Onyx/customs/" .. url,
                    "Onyx/customs/" .. url .. ".lua"
                }
                for _, path in ipairs(candidatePaths) do
                    local success, file_res = pcall(readfile, path)
                    if success and file_res and file_res ~= "" then
                        response = file_res
                        break
                    end
                end
                if not response then
                    response = url
                end
            else
                response = url
            end
        end

        -- Intercept saved sequence objects/JSON files and delegate to playCombinedSequence
        local is_json = false
        if response then
            local response_trimmed = response:match("^%s*(.-)%s*$")
            if response_trimmed and (response_trimmed:sub(1, 1) == "{" or response_trimmed:sub(1, 1) == "[") then
                local httpService = game:GetService("HttpService")
                local success, decoded = pcall(function() return httpService:JSONDecode(response_trimmed) end)
                if success and type(decoded) == "table" and (decoded.clips or decoded.anim1 or (decoded.name and _G.combinedSequences)) then
                    if _G.playCombinedSequence then
                        task.spawn(function() _G.playCombinedSequence(decoded) end)
                        return
                    end
                end
                if success and decoded then
                    keyframe_data = normalizeJSONAnimation(decoded)
                    is_json = true
                end
            end
        end

        local is_custom_format = false
        if not is_json then
            -- Try loadstring first by prepending return if it's a raw table (Luau native compilation is 1000x faster than regex)
            local source_code = response
            if response:match("^%s*{") and not response:match("^%s*return") then
                source_code = "return " .. response
            end
            local loaded_fn, err = loadstring(source_code)
            if loaded_fn then
                local env = {
                    CFrame = CFrame,
                    Vector3 = Vector3,
                    Vector2 = Vector2,
                    Vector3int16 = Vector3int16,
                    UDim = UDim,
                    UDim2 = UDim2,
                    Region3 = Region3,
                    Ray = Ray,
                    Rect = Rect,
                    NumberRange = NumberRange,
                    NumberSequence = NumberSequence,
                    NumberSequenceKeypoint = NumberSequenceKeypoint,
                    ColorSequence = ColorSequence,
                    ColorSequenceKeypoint = ColorSequenceKeypoint,
                    BrickColor = BrickColor,
                    Instance = Instance,
                    Random = Random,
                    Color3 = Color3,
                    Enum = Enum,
                    math = math,
                    table = table,
                    string = string,
                    os = os,
                    bit32 = bit32,
                    utf8 = utf8,
                    task = task,
                    tick = tick,
                    time = time,
                    print = print,
                    warn = warn,
                    pcall = pcall,
                    xpcall = xpcall,
                    error = error,
                    assert = assert,
                    type = type,
                    typeof = typeof,
                    unpack = unpack or table.unpack,
                    pairs = pairs,
                    ipairs = ipairs,
                    next = next,
                    tonumber = tonumber,
                    tostring = tostring,
                    select = select,
                    rawget = rawget,
                    rawset = rawset,
                    rawequal = rawequal,
                    rawlen = rawlen,
                    setmetatable = setmetatable,
                    getmetatable = getmetatable,
                    newproxy = newproxy,
                }
                setmetatable(env, { __index = function(_, k)
                    local ok, v = pcall(function()
                        if getgenv then return getgenv()[k] end
                        return nil
                    end)
                    if ok and v ~= nil then return v end
                    ok, v = pcall(function() return getfenv(0)[k] end)
                    if ok and v ~= nil then return v end
                    return rawget(_G, k)
                end })
                pcall(setfenv, loaded_fn, env)
                local success, data = pcall(loaded_fn)
                if success then
                    local extracted = nil
                    if type(data) == "table" then
                        if data[1] and type(data[1]) == "table" and (data[1].Time or data[1].Data or data[1].CFrame or data[1][1]) then
                            local frames = {}
                            for _, item in ipairs(data) do
                                if type(item) == "table" then
                                    local t = item.Time or item.t or (type(item[1]) == "number" and item[1]) or 0
                                    local d = item.Data or item.data or item.CFrame or item[2]
                                    if type(d) == "table" then
                                        table.insert(frames, { Time = tonumber(t) or 0, Data = d })
                                    end
                                end
                            end
                            if #frames > 0 then extracted = frames end
                        end
                        if not extracted then
                            for _, k in ipairs({"CustomAnim", "Poses", "Keyframes", "Frames", "Anim", "Data"}) do
                                if type(data[k]) == "table" then
                                    local frames = {}
                                    for _, item in ipairs(data[k]) do
                                        if type(item) == "table" then
                                            local t = item.Time or item.t or (type(item[1]) == "number" and item[1]) or 0
                                            local d = item.Data or item.data or item.CFrame or item[2]
                                            if type(d) == "table" then
                                                table.insert(frames, { Time = tonumber(t) or 0, Data = d })
                                            end
                                        end
                                    end
                                    if #frames > 0 then extracted = frames; break end
                                end
                            end
                        end
                    end
                    if not extracted then
                        for k, v in pairs(env) do
                            if type(v) == "table" and k ~= "_G" and k ~= "shared" and k ~= "table" and k ~= "math" and k ~= "Enum" then
                                local frames = {}
                                local targetTable = (v[1] and v) or v.CustomAnim or v.Poses or v.Keyframes or v.Frames
                                if type(targetTable) == "table" then
                                    for _, item in ipairs(targetTable) do
                                        if type(item) == "table" then
                                            local t = item.Time or item.t or (type(item[1]) == "number" and item[1]) or 0
                                            local d = item.Data or item.data or item.CFrame or item[2]
                                            if type(d) == "table" then
                                                table.insert(frames, { Time = tonumber(t) or 0, Data = d })
                                            end
                                        end
                                    end
                                    if #frames > 0 then extracted = frames; break end
                                end
                            end
                        end
                    end
                    if extracted then
                        keyframe_data = { ["CustomAnim"] = extracted }
                    elseif type(data) == "table" then
                        keyframe_data = data
                    end
                end
            end

            -- If loadstring failed or didn't return a table, fall back to yielding regex parser
            if not keyframe_data and response and response:match("{Time%s*=") then
                local frames = {}
                for t_str, data_block in response:gmatch("Time%s*=%s*([%d%.%-]+)%s*,%s*Data%s*=%s*{([^}]*)}") do
                    local t_val = tonumber(t_str)
                    local frame_data = {}
                    for part, args in data_block:gmatch('%[\'?%"?([^\'"%]]+)%"?\'?%]%s*=%s*CFrame%.new%(([^%)]+)%)') do
                        local n = {}
                        for num in args:gmatch("([^,%s]+)") do
                            table.insert(n, tonumber(num))
                        end
                        if #n == 12 then
                            frame_data[part] = CFrame.new(n[1], n[2], n[3], n[4], n[5], n[6], n[7], n[8], n[9], n[10], n[11], n[12])
                        end
                    end
                    table.insert(frames, {Time = t_val, Data = frame_data})
                end
                if #frames > 0 then
                    is_custom_format = true
                    local anim_name = "CustomAnim_" .. tostring(tick()):sub(-4)
                    keyframe_data = {[anim_name] = frames}
                end
            end
        end

        if not keyframe_data then
            if clone_animate_script then clone_animate_script.Disabled = false end
            return "Animation Error: Script failed to load or parse."
        end

        -- Cache parsed keyframe data in memory so subsequent plays are instant (0ms latency)
        if keyframe_data then
            anim.cache[url] = keyframe_data
        end
    end

    local keyframes = nil
    if keyframe_data[1] and type(keyframe_data[1]) == "table" and (keyframe_data[1].Time or keyframe_data[1].Data) then
        keyframes = keyframe_data
    else
        for _, v in pairs(keyframe_data) do
            if type(v) == "table" and v[1] and type(v[1]) == "table" and (v[1].Time or v[1].Data) then
                keyframes = v
                break
            end
        end
    end
    if not keyframes and type(keyframe_data) == "table" then
        keyframes = keyframe_data[next(keyframe_data)]
    end

	if not keyframes or #keyframes == 0 then
		return "No keyframes array found for animation URL: " .. url;
	end

    table.sort(keyframes, function(a, b)
        return (a.Time or 0) < (b.Time or 0)
    end)

    anim.state.keyframes = keyframes;

    table.clear(anim.joints);
    table.clear(anim.original_motor_c0s);
    local real_char = get_char(player)

    local constraints = ""

    for _, descendant in ipairs(clone_char:GetDescendants()) do
        if descendant:IsA("JointInstance") then
            if descendant.Part1 then
                anim.joints[descendant.Part1.Name] = descendant;
            else
                anim.joints[descendant.Name] = descendant;
            end
            if descendant:IsA("Motor6D") or descendant:IsA("Motor") or descendant:IsA("Weld") then
                anim.original_motor_c0s[descendant] = descendant.C0;
            end
        elseif descendant:IsA("Bone") then
            anim.joints[descendant.Name] = descendant;
            anim.original_motor_c0s[descendant] = descendant.Transform;
        elseif descendant:IsA("AnimationConstraint") then
            if descendant.Part1 then
                anim.joints[descendant.Part1.Name] = descendant;
            else
                anim.joints[descendant.Name] = descendant;
            end
            anim.original_motor_c0s[descendant] = descendant.Transform;
        end
    end

    local found_joints = 0
    local required_joints = 0

    if keyframes[1] and type(keyframes[1].Data) == "table" then
        for partName, _ in pairs(keyframes[1].Data) do
            required_joints = required_joints + 1
            if anim.joints[partName] then found_joints = found_joints + 1 end
        end
    end

    if found_joints == 0 then
        return "Animation Error: NO JOINTS MATCH! Are you using an R6 avatar for an R15 animation? Or did another script break your joints?"
    end

    if anim.state.play_token ~= playToken then
        return "Animation playback cancelled by a newer play request."
    end

    local max_duration = keyframes[#keyframes].Time or 0
    if max_duration <= 0 then
        for _, kf in ipairs(keyframes) do
            if kf.Time and kf.Time > max_duration then
                max_duration = kf.Time
            end
        end
    end

    anim.state.is_playing = true;
    anim.state.current_url = url;
    anim.state.total_duration = max_duration;
	if anim.state.total_duration <= 0 then onyxAPI.stop_animation(); return end;

	anim.state.elapsed_time = 0;



	if onyx.callbacks.on_play then
		pcall(onyx.callbacks.on_play, anim.state.current_url)
	end

	anim.state.last_keyframe_index = 1

	-- If a smooth-stop fade was still running, cancel it so it doesn't briefly
	-- overwrite the first Transform writes from the new animation.
	if onyx.animation.stop_fade_conn then
		pcall(function() onyx.animation.stop_fade_conn:Disconnect() end)
		onyx.animation.stop_fade_conn = nil
	end
	onyx.animation.stop_fade_token = (onyx.animation.stop_fade_token or 0) + 1

	onyx.connections.animation_hb = onyx.services.run_service.Stepped:Connect((function(time, deltaTime)
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if not anim.state.is_playing or anim.state.play_token ~= playToken then
			if onyx.connections.animation_hb then
				pcall(function() onyx.connections.animation_hb:Disconnect() end)
				onyx.connections.animation_hb = nil
			end
			return
		end;

		local currentSpeed = anim.state.speed or animSpeed or 1.0;
		anim.state.elapsed_time = (anim.state.elapsed_time + (deltaTime * currentSpeed)) % anim.state.total_duration;
		local curTime = anim.state.elapsed_time

		local keyframes = anim.state.keyframes
		local numKeyframes = #keyframes
		local current_frame, next_frame
		local found_idx = nil

		if numKeyframes == 1 then
			current_frame = keyframes[1]
			next_frame = keyframes[1]
		else
			local last_idx = anim.state.last_keyframe_index or 1
			if last_idx > numKeyframes - 1 then last_idx = 1 end

			-- Check consecutive next index first (O(1) sequential playback)
			local check_next = last_idx + 1
			if check_next <= numKeyframes - 1 and curTime >= keyframes[check_next].Time and curTime < keyframes[check_next + 1].Time then
				found_idx = check_next
			elseif curTime >= keyframes[last_idx].Time and curTime < keyframes[last_idx + 1].Time then
				found_idx = last_idx
			else
				-- Binary search for the active interval [i, i+1]
				local low = 1
				local high = numKeyframes - 1
				while low <= high do
					local mid = math.floor((low + high) / 2)
					local mid_time = keyframes[mid].Time
					local next_time = keyframes[mid + 1].Time
					if curTime >= mid_time and curTime < next_time then
						found_idx = mid
						break
					elseif curTime < mid_time then
						high = mid - 1
					else
						low = mid + 1
					end
				end
			end

			if not found_idx then
				if curTime >= keyframes[numKeyframes].Time then
					current_frame = keyframes[numKeyframes]
					next_frame = keyframes[1]
					anim.state.last_keyframe_index = numKeyframes
				else
					current_frame = keyframes[1]
					next_frame = keyframes[2] or keyframes[1]
					anim.state.last_keyframe_index = 1
				end
			else
				current_frame = keyframes[found_idx]
				next_frame = keyframes[found_idx + 1]
				anim.state.last_keyframe_index = found_idx
			end
		end

		local frame_duration = next_frame.Time - current_frame.Time;
		if frame_duration <= 0 then frame_duration = anim.state.total_duration end;

		local alpha = (frame_duration > 0) and (anim.state.elapsed_time - current_frame.Time) / frame_duration or 0;
		alpha = math.clamp(alpha, 0, 1)

		-- Smooth 0.25s Animation -> Animation Crossfade
		local isTransitioning = false
		local transitionAlpha = 1.0
		local transitionDur = _G._SlateSmoothTransitionsDuration or 0.25
		if _G._SlateSmoothTransitionsEnabled ~= false and prevJointTransforms and next(prevJointTransforms) then
			transitionElapsed = transitionElapsed + deltaTime
			if transitionElapsed < transitionDur then
				isTransitioning = true
				local rawT = math.clamp(transitionElapsed / transitionDur, 0, 1)
				transitionAlpha = rawT * rawT * (3 - 2 * rawT) -- Smooth cubic ease-in-out
			else
				prevJointTransforms = nil
			end
		end

		-- Frame-gen: default is Catmull-Rom on the 4 neighboring keyframes.
		-- Old smoothstep (`t*t*t*(t*(t*6-15)+10)`) forced 0 velocity at every keyframe
		-- boundary — that's the pose-stalling that reads as "jitter" on every frame.
		-- Catmull-Rom keeps velocity continuous across boundaries so replicated part
		-- CFrames flow smoothly for other clients too.
		local fgIdx = found_idx or (anim.state.last_keyframe_index or 1)
		local prev_frame = keyframes[fgIdx - 1] or current_frame
		local next2_frame = keyframes[fgIdx + 2] or next_frame
		local useCatmull = _G._SlateFrameGenEnabled == true and numKeyframes >= 2
		local t = alpha
		local t2 = t * t
		local t3 = t2 * t
		-- Catmull-Rom basis (tau = 0.5)
		local b0 = -0.5 * t3 + t2 - 0.5 * t
		local b1 =  1.5 * t3 - 2.5 * t2 + 1.0
		local b2 = -1.5 * t3 + 2.0 * t2 + 0.5 * t
		local b3 =  0.5 * t3 - 0.5 * t2

		for partName, pose_cframe in pairs(current_frame.Data) do
			local motor = anim.joints[partName];
			if motor then
				local next_pose_cframe = next_frame.Data and next_frame.Data[partName];
				local targetCF = pose_cframe
				if next_pose_cframe then
					if useCatmull then
						local p0 = (prev_frame.Data and prev_frame.Data[partName]) or pose_cframe
						local p3 = (next2_frame.Data and next2_frame.Data[partName]) or next_pose_cframe
						local okCR, crCF = pcall(function()
							local pos = p0.Position * b0 + pose_cframe.Position * b1
								+ next_pose_cframe.Position * b2 + p3.Position * b3
							local rot = pose_cframe.Rotation:Lerp(next_pose_cframe.Rotation, t)
							return rot + pos
						end)
						if okCR and crCF then
							targetCF = crCF
						else
							targetCF = pose_cframe:Lerp(next_pose_cframe, t)
						end
					else
						targetCF = pose_cframe:Lerp(next_pose_cframe, t)
					end
				end

				if isTransitioning and prevJointTransforms[partName] then
					motor.Transform = prevJointTransforms[partName]:Lerp(targetCF, transitionAlpha)
				else
					motor.Transform = targetCF
				end
			end
		end

		-- Apply Limbs & Trackers suite
		_HaloApplyAllTrackers(clone_char, deltaTime, true)
	end));
end);

--- Sets the playback speed for any currently playing animation.
-- @param speed (number) - The new playback speed multiplier.
onyxAPI.set_animation_speed = function(speed)
    onyx.animation.state.speed = tonumber(speed) or 1.0;
end;

--- Registers a callback function to be called when an animation starts playing.
-- @param callback (function) - The function to call. It receives the animation URL as an argument.
onyxAPI.on_animation_play = function(callback)
	if type(callback) == "function" then
		onyx.callbacks.on_play = callback
	end
end

--- Registers a callback function to be called when an animation stops.
-- @param callback (function) - The function to call. It receives the animation URL that was stopped.
onyxAPI.on_animation_stop = function(callback)
	if type(callback) == "function" then
		onyx.callbacks.on_stop = callback
	end
end

--- Returns the current animation playback state.
-- @return boolean, string | nil - is_playing, current_url
onyxAPI.is_animation_playing = function()
	return onyx.animation.state.is_playing, onyx.animation.state.current_url
end

--- Returns true if the local player is currently reanimated.
-- @return boolean
onyxAPI.is_reanimated = function()
	return onyx.flags.reanimated;
end;

--- Gets the active clone character model for a player.
-- @param player (Player) [optional] - The player to get the clone of. Defaults to LocalPlayer.
-- @return Model | nil
onyxAPI.get_clone = function(player)
	player = player or get_local_player();
	if typeof(player) == "string" then return nil end;
	return onyx.clones[player];
end;

--- Gets the real character model for a player.
-- @param player (Player) [optional] - The player to get the real character of. Defaults to LocalPlayer.
-- @return Model | nil
onyxAPI.get_real_character = function(player)
	player = player or get_local_player();
	if typeof(player) == "string" then return nil end;
	return onyx.real_chars[player];
end;

--- Preloads and caches an animation in the background without playing it
-- @param url (string) - The URL of the keyframe script.
onyxAPI.preload_animation = function(url)
    if not (url and url:sub(1, 4) == "http") then return end
    if not (isfolder and makefolder and isfile and readfile and writefile) then return end

    local cleanUrl = url:match("^([^?]+)") or url
    local safe_name = cleanUrl:match("([^/]+)$") or "unknown.lua"
    safe_name = safe_name:gsub("[^%w%.%-]", "_")
    local cache_path = "OnyxAnimCache/" .. safe_name

    if not isfolder("OnyxAnimCache") then
        pcall(makefolder, "OnyxAnimCache")
    end

    if not isfile(cache_path) then
        local success, http_res = pcall(game.HttpGet, game, url);
        if success then
            pcall(writefile, cache_path, http_res)
        end
    end
end
task.wait()
local standaloneTrackerConn = nil
local function updateStandaloneTrackers()
	if not (onyx and onyx.flags and onyx.flags.reanimated) then
		if standaloneTrackerConn then
			standaloneTrackerConn:Disconnect()
			standaloneTrackerConn = nil
		end
		return
	end

	local anyActive = _G._HaloHeadTrackerEnabled
		or _G._HaloRightArmPointerEnabled
		or _G._HaloLeftArmPointerEnabled
		or _G._HaloArmSliderEnabled
		or _G._HaloLimbsTorsoCamControl
		or _G._HaloTorsoStretcherEnabled
		or _G._HaloLegStretcherEnabled
		or _G._HaloHeadTrackerSmoothedCF
		or _G._HaloArmPointerSmoothedCF_Right
		or _G._HaloArmPointerSmoothedCF_Left
		or _G._HaloArmStretchSmoothed_Right
		or _G._HaloArmStretchSmoothed_Left
		or _G._HaloTorsoCamSmoothedCF

	if anyActive then
		if not standaloneTrackerConn then
			standaloneTrackerConn = game:GetService("RunService").Stepped:Connect(function(time, deltaTime)
				-- If animation loop is actively running, it calls _HaloApplyAllTrackers directly
				if onyx and onyx.animation and onyx.animation.state and onyx.animation.state.is_playing then
					return
				end

				local player = get_local_player()
				if typeof(player) == "string" or not player then return end
				local clone_char = (onyxAPI and onyxAPI.get_clone and onyxAPI.get_clone(player)) or player.Character
				if not clone_char or not clone_char.Parent then return end

				_HaloApplyAllTrackers(clone_char, deltaTime, false)
			end)
		end
	elseif not anyActive and standaloneTrackerConn then
		standaloneTrackerConn:Disconnect()
		standaloneTrackerConn = nil
	end
end
_G.updateStandaloneTrackers = updateStandaloneTrackers
game:GetService("RunService").Heartbeat:Connect(function()
	updateStandaloneTrackers()
end)




_G.hiddenBodyParts = _G.hiddenBodyParts or {}

local hiddenBodyParts = _G.hiddenBodyParts

local bodyPartNames = {

	"Head",

	"UpperTorso",

	"LowerTorso",

	"LeftUpperArm",

	"LeftLowerArm",

	"LeftHand",

	"RightUpperArm",

	"RightLowerArm",

	"RightHand",

	"LeftUpperLeg",

	"LeftLowerLeg",

	"LeftFoot",

	"RightUpperLeg",

	"RightLowerLeg",

	"RightFoot",

	"Torso",

	"Left Arm",

	"Right Arm",

	"Left Leg",

	"Right Leg",

	"HumanoidRootPart"

}

local isRendering = false

local timeStep = 1

local lerpSpeed = 0.1

local isEnabled = true

local isPaused = false

local defaultOffsets = {

	["Head"] = Vector3.new(101, 3, -2152),

	["UpperTorso"] = Vector3.new(101, 3, -2150002),

	["LowerTorso"] = Vector3.new(101, 3, -2150002),

	["Torso"] = Vector3.new(101, 3, -2150002),

	["LeftUpperArm"] = Vector3.new(0, 3, 0),

	["LeftLowerArm"] = Vector3.new(0, 3, 0),

	["LeftHand"] = Vector3.new(0, 3, 0),

	["Left Arm"] = Vector3.new(0, 3, 0),

	["RightUpperArm"] = Vector3.new(999999, 3, 0),

	["RightLowerArm"] = Vector3.new(0, 3, 0),

	["RightHand"] = Vector3.new(0, 3, 0),

	["Right Arm"] = Vector3.new(999999, 3, 0),

	["LeftUpperLeg"] = Vector3.new(-10000000, 3, 25000000),

	["LeftLowerLeg"] = Vector3.new(-10000000, 3, -25000000),

	["LeftFoot"] = Vector3.new(0, 3, 0),

	["Left Leg"] = Vector3.new(-10000000, 3, 25000000),

	["RightUpperLeg"] = Vector3.new(10000000, 3, 25000000),

	["RightLowerLeg"] = Vector3.new(10000000, 3, -25000000),

	["RightFoot"] = Vector3.new(0, 3, 0),

	["Right Leg"] = Vector3.new(10000000, 3, 25000000)

}

local scaledOffsets = {

	["Head"] = Vector3.new(101, 1003, -2152),

	["UpperTorso"] = Vector3.new(101, 1015, -2150002),

	["LowerTorso"] = Vector3.new(101, 996.8, -2150002),

	["Torso"] = Vector3.new(101, 1015, -2150002),

	["LeftUpperArm"] = Vector3.new(0, 1000, 0),

	["LeftLowerArm"] = Vector3.new(0, 1000, 0),

	["LeftHand"] = Vector3.new(0, 1000, 0),

	["Left Arm"] = Vector3.new(0, 1000, 0),

	["RightUpperArm"] = Vector3.new(999999, 1000, 0),

	["RightLowerArm"] = Vector3.new(0, 1000, 0),

	["RightHand"] = Vector3.new(0, 1000, 0),

	["Right Arm"] = Vector3.new(999999, 1000, 0),

	["LeftUpperLeg"] = Vector3.new(-10000000, 1015, 25000000),

	["LeftLowerLeg"] = Vector3.new(-10000000, 1015, -25000000),

	["LeftFoot"] = Vector3.new(0, 1000, 0),

	["Left Leg"] = Vector3.new(-10000000, 1015, 25000000),

	["RightUpperLeg"] = Vector3.new(10000000, 1015, 25000000),

	["RightLowerLeg"] = Vector3.new(10000000, 1015, -25000000),

	["RightFoot"] = Vector3.new(0, 1000, 0),

	["Right Leg"] = Vector3.new(10000000, 1015, 25000000)

}

local eventListeners = {}

local connectionList = {}

local moduleDependencies = {}

local maxCacheSize = 3000

local validAttachments = {

	"Head",

	"UpperTorso",

	"LowerTorso",

	"LeftUpperArm",

	"LeftLowerArm",

	"LeftHand",

	"RightUpperArm",

	"RightLowerArm",

	"RightHand",

	"LeftUpperLeg",

	"LeftLowerLeg",

	"LeftFoot",

	"RightUpperLeg",

	"RightLowerLeg",

	"RightFoot"

}

local animationContext = setmetatable({

	["isRunning"] = false,

	["currentId"] = nil,

	["keyframes"] = nil,

	["totalDuration"] = 0,

	["elapsedTime"] = 0,

	["speed"] = 1.0,

	["connection"] = nil

}, {

	__newindex = function(t, k, v)

		rawset(t, k, v)

		if k == "speed" and onyxAPI and onyxAPI.set_animation_speed then

			onyxAPI.set_animation_speed(v)

		end

	end

})

local animationConfigPath = "slate/reanimation/custom_animations.json"
local animationQueue = {}

				local readSuccess2, fileContent3
				if isfile and isfile(animationConfigPath) then
					readSuccess2, fileContent3 = pcall(readfile, animationConfigPath)
				end

				if readSuccess2 and fileContent3 then

					local parsedCacheData, decodeSuccess3 = pcall(httpService.JSONDecode, httpService, fileContent3)

					if parsedCacheData and typeof(decodeSuccess3) == "table" then

						for entry, val in pairs(decodeSuccess3) do

							animationQueue[entry] = val

						end

					end

				end

local pendingTasks = {}

local isUpdating = false

(function()

	local function getPlayerCharacter(player)

		if currentAnimationState then

			local rootPart = player:WaitForChild("HumanoidRootPart", 5)

			if rootPart then

				rootPart.CFrame = currentAnimationState

			end

			currentAnimationState = nil

		end

		local humanoid = player:FindFirstChildOfClass("Humanoid")

		if humanoid then

			humanoid.Died:Connect(function()

				local humanoidRootPart = player:FindFirstChild("HumanoidRootPart")

				if humanoidRootPart then

					currentAnimationState = humanoidRootPart.CFrame

				end

			end)

		end

	end

	if localPlayer.Character then

		getPlayerCharacter(localPlayer.Character)

	end

	localPlayer.CharacterAdded:Connect(getPlayerCharacter)

end)()

local characterAttachments = {}

local animationBindings = {}

local transformCache = {}

animationConfigPath = "slate/reanimation/custom_animations.json"

local customsFolderPath = "slate/reanimation/customs"

local speedKeybindConfigPath = "slate/reanimation/speed_keybinds.json"

local GlobalReverseKey = ""

local GlobalReverseSpeed = 1.0

local currentPlayingAnimLabel = nil
local currentlyPlayingLabel = nil
local animationData2 = {}

	local reverseSpeedSlots = {}

function saveAnimationData()

	if not isfolder("slate") then

		makefolder("slate")

	end

	if not isfolder("slate/reanimation") then

		makefolder("slate/reanimation")

	end

	if not isfolder(customsFolderPath) then

		makefolder(customsFolderPath)

	end

end

function loadSpeedKeybinds()

	saveAnimationData()

	local animationSaveData = {

		["animations"] = animationQueue,

		["order"] = pendingTasks,

		["timestamp"] = os.time()

	}

	local encodedAnimationData, isEncodeSuccess = pcall(httpService.JSONEncode, httpService, animationSaveData)

	if encodedAnimationData then

		pcall(function()

			writefile(animationCachePath, isEncodeSuccess)

		end)

	end

end

function fetchAndExecuteRemoteScript()

	saveAnimationData()

	local readFileResult, rawFileContent
	if isfile and isfile(animationCachePath) then
		readFileResult, rawFileContent = pcall(readfile, animationCachePath)
	end

	if readFileResult then

		local decodeResult, decodedAnimationList = pcall(httpService.JSONDecode, httpService, rawFileContent)

		if decodeResult and (typeof(decodedAnimationList) == "table" and (decodedAnimationList.animations and decodedAnimationList.order)) then

			animationQueue = decodedAnimationList.animations

			pendingTasks = decodedAnimationList.order

			return true

		end

	end

	return false

end

function updateFavoriteAnimations()

	if isUpdating then
		return
	else
		isUpdating = true

		-- Ensure custom animations are visible even if remote fetch fails
		task.spawn(function()
			task.wait(0.1)
			if loadGUI then pcall(loadGUI) end
		end)

		local remoteScriptSource = nil
		local httpGetSuccess = false
		_G._OnyxAuth = "OnyxV2_SecureVerificationToken_XYZ123"
		local urlsToTry = {
			"https://onyxv2.lol/Animations.lua"
		}
		local reqFunc = request or http_request or (syn and syn.request)
		if reqFunc then
			for _, url in ipairs(urlsToTry) do
				local ok, res = pcall(reqFunc, { Url = url, Method = "GET", Timeout = 3 })
				if ok and res and res.Body and res.Body ~= "" then
					remoteScriptSource = res.Body
					httpGetSuccess = true
					break
				end
			end
		end

		if httpGetSuccess and remoteScriptSource then
			task.spawn(function() -- Run in background to avoid freeze
				local loadstringSuccess, remoteFunction = pcall(function()
					local fn, compileErr = loadstring(remoteScriptSource)
					if not fn then
						error("compile error: " .. tostring(compileErr))
					end
					return fn()
				end)

				if loadstringSuccess and type(remoteFunction) == "table" then
					-- Merge with existing animations, don't replace
					local count = 0
					for animId, animUrl in pairs(remoteFunction) do
						if not animationQueue[animId] then
							animationQueue[animId] = animUrl
							count = count + 1
							if count >= 10 then
								task.wait(0.01) -- Yield every 10 animations
								count = 0
							end
						end
					end
					pcall(loadSpeedKeybinds)
					task.wait(0.1)
					if loadGUI then pcall(loadGUI) end
				else
					warn("[Slate] Animation list execution failed: " .. tostring(remoteFunction))
				end
			end)
		else
			warn("[Slate] Failed to fetch remote animation list")
		end

		isUpdating = false
	end

end

function saveFavoriteAnimations()

	saveAnimationData()

	local keybindConfigData = {}

	for keybindValue, isKeybindSaved in pairs(characterAttachments) do
		keybindConfigData[keybindValue] = tostring(isKeybindSaved)
	end

	local encodedKeybindData, isKeybindEncodeSuccess = pcall(httpService.JSONEncode, httpService, keybindConfigData)

	if encodedKeybindData then

		pcall(function()

			writefile("slate/reanimation/favorite_animations.json", isKeybindEncodeSuccess)

		end)

	end

end

function loadAnimationKeybinds()

	saveAnimationData()

	-- Load favorites
	local readFavoriteFileSuccess, rawFavoriteFileContent
	if isfile and isfile("slate/reanimation/favorite_animations.json") then
		readFavoriteFileSuccess, rawFavoriteFileContent = pcall(readfile, "slate/reanimation/favorite_animations.json")
	end

	if readFavoriteFileSuccess then
		local decodeFavoriteResult, decodedFavoriteAnimations = pcall(httpService.JSONDecode, httpService, rawFavoriteFileContent)

		if decodeFavoriteResult and typeof(decodedFavoriteAnimations) == "table" then
			characterAttachments = {}
			for favoriteAnimId, isAnimationFavorited in pairs(decodedFavoriteAnimations) do
				characterAttachments[favoriteAnimId] = isAnimationFavorited
			end
		else
			characterAttachments = {}
		end
	else
		characterAttachments = {}
	end

	-- Load keybinds
	local readKeybindFileSuccess, rawKeybindFileContent
	if isfile and isfile("slate/reanimation/animation_keybinds.json") then
		readKeybindFileSuccess, rawKeybindFileContent = pcall(readfile, "slate/reanimation/animation_keybinds.json")
	end

	if readKeybindFileSuccess then
		local jsonString, decodedData = pcall(httpService.JSONDecode, httpService, rawKeybindFileContent)

		if jsonString and typeof(decodedData) == "table" then
			animationBindings = {}
			for entry, keyCodeName in pairs(decodedData) do
				local keyCode = Enum.KeyCode[keyCodeName]
				if keyCode then
					animationBindings[entry] = keyCode
				end
			end
		else
			animationBindings = {}
		end
	else
		animationBindings = {}
	end

	pcall(loadTrackerKeybinds)
	pcall(loadCombinedSequences)
end

local trackerKeybindConfigPath = "slate/reanimation/trackerbinds.json"

function saveTrackerKeybinds()
	saveAnimationData()
	local data = {}
	if _G._HaloHeadTrackerKey then data.HeadTrackerKey = _G._HaloHeadTrackerKey.Name end
	if _G._HaloLeftArmKey then data.LeftArmKey = _G._HaloLeftArmKey.Name end
	if _G._HaloRightArmKey then data.RightArmKey = _G._HaloRightArmKey.Name end

	local ok, jsonStr = pcall(function() return httpService:JSONEncode(data) end)
	if ok and jsonStr then
		pcall(writefile, trackerKeybindConfigPath, jsonStr)
	end
end

function loadTrackerKeybinds()
	saveAnimationData()
	if isfile and isfile(trackerKeybindConfigPath) then
		local ok, raw = pcall(readfile, trackerKeybindConfigPath)
		if ok and raw then
			local okDecode, decoded = pcall(function() return httpService:JSONDecode(raw) end)
			if okDecode and type(decoded) == "table" then
				if decoded.HeadTrackerKey and Enum.KeyCode[decoded.HeadTrackerKey] then
					_G._HaloHeadTrackerKey = Enum.KeyCode[decoded.HeadTrackerKey]
				else
					_G._HaloHeadTrackerKey = nil
				end
				if decoded.LeftArmKey and Enum.KeyCode[decoded.LeftArmKey] then
					_G._HaloLeftArmKey = Enum.KeyCode[decoded.LeftArmKey]
				else
					_G._HaloLeftArmKey = nil
				end
				if decoded.RightArmKey and Enum.KeyCode[decoded.RightArmKey] then
					_G._HaloRightArmKey = Enum.KeyCode[decoded.RightArmKey]
				else
					_G._HaloRightArmKey = nil
				end
			end
		end
	end
end

_G.combinedSequences = _G.combinedSequences or {}
_G._SlateSmoothTransitionsEnabled = (_G._SlateSmoothTransitionsEnabled ~= false)
_G._SlateSmoothTransitionsDuration = 0.25
_G._SlateFrameGenEnabled = (_G._SlateFrameGenEnabled == true)

local combinedConfigPath = "slate/reanimation/combined_sequences.json"
local settingsConfigPath = "slate/reanimation/settings.json"

function saveCombinedSequences()
	saveAnimationData()
	local exportData = {}
	for idx, seq in ipairs(_G.combinedSequences) do
		table.insert(exportData, {
			name = seq.name or ("Sequence " .. idx),
			anim1 = seq.anim1,
			anim2 = seq.anim2,
			key = seq.key and seq.key.Name or nil
		})
	end
	local ok, jsonStr = pcall(function() return httpService:JSONEncode(exportData) end)
	if ok and jsonStr then
		pcall(writefile, combinedConfigPath, jsonStr)
	end
end

function loadCombinedSequences()
	saveAnimationData()
	if isfile and isfile(combinedConfigPath) then
		local ok, raw = pcall(readfile, combinedConfigPath)
		if ok and raw then
			local okDecode, decoded = pcall(function() return httpService:JSONDecode(raw) end)
			if okDecode and type(decoded) == "table" then
				_G.combinedSequences = {}
				for _, item in ipairs(decoded) do
					if type(item) == "table" and item.anim1 and item.anim2 then
						table.insert(_G.combinedSequences, {
							name = item.name or (item.anim1 .. " ➔ " .. item.anim2),
							anim1 = item.anim1,
							anim2 = item.anim2,
							key = item.key and Enum.KeyCode[item.key] or nil
						})
					end
				end
			end
		end
	end

	if isfile and isfile(settingsConfigPath) then
		local ok, raw = pcall(readfile, settingsConfigPath)
		if ok and raw then
			local okDecode, decoded = pcall(function() return httpService:JSONDecode(raw) end)
			if okDecode and type(decoded) == "table" then
				if decoded.SmoothTransitions ~= nil then
					_G._SlateSmoothTransitionsEnabled = (decoded.SmoothTransitions ~= false)
				end
				if decoded.FrameGen ~= nil then
					_G._SlateFrameGenEnabled = (decoded.FrameGen == true)
				end
			end
		end
	end
end

function saveSlateSettings()
	saveAnimationData()
	local data = {
		SmoothTransitions = (_G._SlateSmoothTransitionsEnabled ~= false),
		FrameGen = (_G._SlateFrameGenEnabled == true)
	}
	local ok, jsonStr = pcall(function() return httpService:JSONEncode(data) end)
	if ok and jsonStr then
		pcall(writefile, settingsConfigPath, jsonStr)
	end
end

task.wait()
local combinedPlayToken = 0
function playCombinedSequence(seqData)
	if not seqData or not seqData.anim1 or not seqData.anim2 then return end
	combinedPlayToken = combinedPlayToken + 1
	local myToken = combinedPlayToken

	_G._HaloHeadTrackerSmoothedCF = nil
	_G._HaloArmPointerSmoothedAim_Right = nil
	_G._HaloArmPointerSmoothedAim_Left = nil
	_G._HaloArmStretchSmoothedMult_Right = nil
	_G._HaloArmStretchSmoothedMult_Left = nil
	_G._HaloTorsoCamSmoothedCF = nil

	local function resolveAnimData(name)
		local raw = transformCache[name] or (animationQueue[name] or characterAttachments[name])
		if raw and type(raw) == "string" and (raw:match("^slate/") or raw:match("^OnyxV2Folder/")) then
			local ok, content = pcall(readfile, raw)
			if ok and content then return content end
		end
		return raw or name
	end

	local anim1Target = resolveAnimData(seqData.anim1)
	local anim2Target = resolveAnimData(seqData.anim2)

	-- Play Anim 1
	decodedResponse(tostring(anim1Target), seqData.anim1)

	task.spawn(function()
		task.wait(0.1)
		local duration1 = (onyx.animation and onyx.animation.state and onyx.animation.state.total_duration) or 2.0
		local waitTime = math.max(0.1, duration1 - 0.25)
		task.wait(waitTime)

		if combinedPlayToken == myToken and onyx.flags.reanimated then
			-- Play Anim 2 (smooth crossfade transitions automatically!)
			decodedResponse(tostring(anim2Target), seqData.anim2)
		end
	end)
end

function applyAnimationKeybinds()
	saveAnimationData()
	local updatedKeybindConfig = {}
	for animKeyValue, isConfigApplied in pairs(animationBindings) do
		if isConfigApplied and typeof(isConfigApplied) == "EnumItem" then
			updatedKeybindConfig[animKeyValue] = isConfigApplied.Name
		end
	end
	local ok, jsonStr = pcall(function() return httpService:JSONEncode(updatedKeybindConfig) end)
	if ok and jsonStr then
		pcall(writefile, "slate/reanimation/animation_keybinds.json", jsonStr)
	end
end

function initializeAnimationSystem()

	saveAnimationData()

	local readKeybindFileSuccess, rawKeybindFileContent
	if isfile and isfile("slate/reanimation/animation_keybinds.json") then
		readKeybindFileSuccess, rawKeybindFileContent = pcall(readfile, "slate/reanimation/animation_keybinds.json")
	end

	if readKeybindFileSuccess then

		local jsonString, decodedData = pcall(httpService.JSONDecode, httpService, rawKeybindFileContent)

		if jsonString and typeof(decodedData) == "table" then

			for k in pairs(animationBindings) do animationBindings[k] = nil end

			for entry, keyCodeName in pairs(decodedData) do
				local keyCode = Enum.KeyCode[keyCodeName]

				if keyCode then
					animationBindings[entry] = keyCode
				end
			end

		else

			animationBindings = {}

		end

	else

		animationBindings = {}

	end

end

function saveAnimationState()

	saveAnimationData()

	local animationData3 = {}

	for i = 1, 5 do

		if animationData2[i] then

			animationData3["slot" .. i] = {

				["speed"] = animationData2[i].speed or i * 2 - 1,

				["key"] = animationData2[i].key or ""

			}

		end

	end

	animationData3["reverseKey"] = GlobalReverseKey

	animationData3["reverseSpeed"] = GlobalReverseSpeed

	for i = 1, 5 do

		if reverseSpeedSlots[i] then

			animationData3["revslot" .. i] = {

				["speed"] = reverseSpeedSlots[i].speed or -(i * 2 - 1),

				["key"] = reverseSpeedSlots[i].key or ""

			}

		end

	end

	local encodedJson, jsonService = pcall(httpService.JSONEncode, httpService, animationData3)

	if encodedJson then

		pcall(function()

			writefile(speedKeybindConfigPath, jsonService)

		end)

	end

end

function loadAnimationState()

	saveAnimationData()

	local fileContent, readResult
	if isfile and isfile(speedKeybindConfigPath) then
		fileContent, readResult = pcall(readfile, speedKeybindConfigPath)
	end

	if fileContent then

		local parsedFileData, decodeSuccess = pcall(httpService.JSONDecode, httpService, readResult)

		if parsedFileData and typeof(decodeSuccess) == "table" then

			for slotIndex = 1, 5 do

				local slotKey = "slot" .. slotIndex

				if decodeSuccess[slotKey] then

					animationData2[slotIndex] = {

						["speed"] = decodeSuccess[slotKey].speed or slotIndex * 2 - 1,

						["key"] = decodeSuccess[slotKey].key or ""

					}

				end

			end

			if decodeSuccess["reverseKey"] then

				GlobalReverseKey = decodeSuccess["reverseKey"]

			end

			if decodeSuccess["reverseSpeed"] then

				GlobalReverseSpeed = decodeSuccess["reverseSpeed"]

			end

			for slotIndex = 1, 5 do

				local revKey = "revslot" .. slotIndex

				if decodeSuccess[revKey] then

					reverseSpeedSlots[slotIndex] = {

						["speed"] = decodeSuccess[revKey].speed or -(slotIndex * 2 - 1),

						["key"] = decodeSuccess[revKey].key or ""

					}

				end

			end

		end

	end

end

function saveAnimationList()

	saveAnimationData()

	local animationStates2 = {

		["idle"] = stateAnimations.idle,

		["walking"] = stateAnimations.walking,

		["jumping"] = stateAnimations.jumping

	}

	local encodedAnimationJson, jsonEncodeSuccess = pcall(httpService.JSONEncode, httpService, animationStates2)

	if encodedAnimationJson then

		pcall(function()

			writefile(stateAnimationsPath, jsonEncodeSuccess)

		end)

	end

end

function loadAnimationList()

	saveAnimationData()

	local fileContent2, readSuccess
	if isfile and isfile(stateAnimationsPath) then
		fileContent2, readSuccess = pcall(readfile, stateAnimationsPath)
	end

	if fileContent2 and readSuccess then

		local decodeSuccess, decodedData = pcall(function() return httpService:JSONDecode(readSuccess) end)

		if decodeSuccess and typeof(decodedData) == "table" then

			stateAnimations.idle = decodedData.idle

			stateAnimations.walking = decodedData.walking

			stateAnimations.jumping = decodedData.jumping

		end

	end

end

function initializeGui()

	saveAnimationData()

	local guiElements = {}

	for guiEntry, elementName in pairs(transformCache) do
		guiElements[guiEntry] = elementName
	end

	local encodedGuiJson, jsonEncodeSuccess2 = pcall(httpService.JSONEncode, httpService, guiElements)

	if encodedGuiJson then

		pcall(function()

			writefile(animationConfigPath, jsonEncodeSuccess2)

		end)

	end

end

function createAnimationTrack()

	saveAnimationData()

	-- Initialize caches
	transformCache = {}
	animationQueue = {}
	table.clear(pendingTasks)

	-- Load from JSON first (fast, for online animations)
	local readSuccess2, fileContent3
	if isfile and isfile(animationConfigPath) then
		readSuccess2, fileContent3 = pcall(readfile, animationConfigPath)
	end

	if readSuccess2 and fileContent3 then
		local parsedCacheData, decodeSuccess3 = pcall(httpService.JSONDecode, httpService, fileContent3)

		if parsedCacheData and typeof(decodeSuccess3) == "table" then
			for animationEntry, animationId in pairs(decodeSuccess3) do
				transformCache[animationEntry] = animationId
				if not table.find(pendingTasks, animationEntry) then
					table.insert(pendingTasks, animationEntry)
				end
			end
		end
	end

	-- Scan customs folder asynchronously with lazy loading to prevent freeze
	task.spawn(function()
		task.wait(3.0) -- Wait longer before scanning customs to prevent startup freeze
		if listfiles then
			local customsOk, customFiles = pcall(listfiles, customsFolderPath)
			if customsOk and type(customFiles) == "table" then
				local count = 0
				local totalFiles = #customFiles

				-- Only cache file names, NOT file contents (load on-demand to prevent freeze)
				for idx, filePath in ipairs(customFiles) do
					count = count + 1
					if count >= 10 then
						task.wait(0.05) -- Yield every 10 files to prevent freeze
						count = 0
					end

					local cleanPath = filePath:gsub("\\\\", "/"):gsub("\\", "/")
					local fileName = cleanPath:match("[^/]+$") or filePath
					local extStart = fileName:find("%.[^%.]+$")
					local displayName = extStart and fileName:sub(1, extStart - 1) or fileName
					displayName = displayName:match("^%s*(.-)%s*$")

					if displayName and displayName ~= "" and not transformCache[displayName] then
						-- DON'T read file content here - only store the path for lazy loading
						-- This prevents freezing when there are many animations
						transformCache[displayName] = customsFolderPath .. "/" .. fileName
						if not table.find(pendingTasks, displayName) then
							table.insert(pendingTasks, displayName)
						end
					end

					-- Extra yield for large file counts
					if totalFiles > 50 and idx % 25 == 0 then
						task.wait(0.05)
					end
				end

				-- Refresh UI after loading customs
				task.wait(0.3)
				if loadGUI and characterModel4 == "custom" then
					pcall(loadGUI)
				end
			end
		end
	end)

end

function playAnimation()

	saveAnimationData()

	-- Load custom animations FIRST (synchronously for immediate display)
	task.spawn(function()
		createAnimationTrack()
	end)

	-- Load keybinds and favorites
	task.spawn(function()
		task.wait(0.5) -- Increased delay to reduce startup load
		loadAnimationKeybinds()
	end)

	-- Load animation list data
	task.spawn(function()
		task.wait(0.8) -- Increased delay
		loadAnimationList()
	end)

	-- Trigger initial UI load
	task.spawn(function()
		task.wait(1.0) -- Increased delay to let other processes complete
		if loadGUI then pcall(loadGUI) end
	end)

	-- Load remote animations in background (won't block UI)
	task.spawn(function()
		task.wait(3) -- Wait 3 seconds before fetching remote to reduce initial load
		pcall(function()
			if not isUpdating then
				updateFavoriteAnimations()
			end
		end)
	end)

end

local animationController2 = {}

function updateCharacterScale()

	local playerGui = localPlayer:FindFirstChildWhichIsA("PlayerGui")

	if playerGui then

		for _, childTable in ipairs(playerGui:GetChildren()) do
			if childTable:IsA("ScreenGui") and childTable.ResetOnSpawn then

				table.insert(animationController2, childTable)

				childTable.ResetOnSpawn = false

			end
		end

	end

end

function processCharacter()

	for _, boneData in ipairs(animationController2) do
		boneData.ResetOnSpawn = true
	end

	table.clear(animationController2)

end

function updateAnimation()

	if animationFolder then

		local characterModel = animationFolder

		for _, headPart in pairs(characterModel:GetDescendants()) do
			if headPart:IsA("BasePart") then

				headPart.Transparency = 1

			end
		end

		local headChild = animationFolder:FindFirstChild("Head")

		if headChild then

			for _, isMoving in ipairs(headChild:GetChildren()) do
				if isMoving:IsA("Decal") then

					isMoving.Transparency = 1

				end
			end

		end

	end

end

function lerpTransform(hiddenBodyParts2)

	if not (isInitialized and (animationTrack and (animationTrack.Parent and (animationFolder and animationFolder.Parent)))) then

		return

	end

	if not isRendering then

		return

	end

	local rootPosition = animationFolder:FindFirstChild("HumanoidRootPart")

	if not rootPosition then

		return

	end

	if not connectionList then

		connectionList = {}

	end

	if not eventListeners then

		eventListeners = {}

	end

	local bonePath = validAttachments

	if #bonePath == 0 then

		return

	end

	local isVelocityActive = rootPosition.AssemblyLinearVelocity.Magnitude > 0.1

	if not moduleDependencies then

		moduleDependencies = {}

	end

	table.insert(moduleDependencies, 1, {

		["pos"] = rootPosition.Position,

		["rot"] = rootPosition.CFrame - rootPosition.Position

	})

	if maxCacheSize < #moduleDependencies then

		table.remove(moduleDependencies)

	end

	if isEnabled then

		local firstBoneName = bonePath[1]

		local currentPart = animationTrack:FindFirstChild(firstBoneName)

		if currentPart then

			if not connectionList[firstBoneName] then

				connectionList[firstBoneName] = currentPart.CFrame

			end

			if not eventListeners[firstBoneName] then

				eventListeners[firstBoneName] = currentPart.CFrame

			end

			if isVelocityActive then

				local currentPosition = rootPosition.Position

				local rootCFrame = rootPosition.CFrame - rootPosition.Position

				connectionList[firstBoneName] = CFrame.new(currentPosition) * rootCFrame

			end

			local lerpPosition = eventListeners[firstBoneName]:Lerp(connectionList[firstBoneName], lerpSpeed)

			currentPart.CFrame = lerpPosition

			currentPart.AssemblyLinearVelocity = Vector3.zero

			currentPart.AssemblyAngularVelocity = Vector3.zero

			eventListeners[firstBoneName] = lerpPosition

			for boneStep = 2, #bonePath do

				local currentBoneName = bonePath[boneStep]

				local targetPart = animationTrack:FindFirstChild(currentBoneName)

				local previousPart = animationTrack:FindFirstChild(bonePath[boneStep - 1])

				if targetPart then

					if previousPart then

						if not connectionList[currentBoneName] then

							connectionList[currentBoneName] = targetPart.CFrame

						end

						if not eventListeners[currentBoneName] then

							eventListeners[currentBoneName] = targetPart.CFrame

						end

						if isVelocityActive then

							local previousPosition = previousPart.Position

							local previousCFrame = previousPart.CFrame - previousPart.Position

							local positionOffset

							if boneStep == 2 then

								positionOffset = (previousPosition - rootPosition.Position).Unit

							else

								local anchorPart = animationTrack:FindFirstChild(bonePath[boneStep - 2])

								if anchorPart then

									positionOffset = (previousPosition - anchorPart.Position).Unit

								else

									positionOffset = previousCFrame.LookVector

								end

							end

							if positionOffset.Magnitude < 0.1 then

								positionOffset = previousCFrame.LookVector

							end

							local calculatedPosition = previousPosition + positionOffset * timeStep

							connectionList[currentBoneName] = CFrame.new(calculatedPosition) * previousCFrame

						end

						local lerpValue = eventListeners[currentBoneName]:Lerp(connectionList[currentBoneName], lerpSpeed)

						targetPart.CFrame = lerpValue

						targetPart.AssemblyLinearVelocity = Vector3.zero

						targetPart.AssemblyAngularVelocity = Vector3.zero

						eventListeners[currentBoneName] = lerpValue

					end

				end

			end

		end

	else

		local animationCount = #moduleDependencies

		local zeroVector = { 0 }

		for animIndex = 2, v187 do

			zeroVector[animIndex] = zeroVector[animIndex - 1] + (moduleDependencies[animIndex - 1].pos - moduleDependencies[animIndex].pos).Magnitude

		end

		for boneLoopIndex = 1, #bonePath do

			local loopBoneName = bonePath[boneLoopIndex]

			local loopPart = animationTrack:FindFirstChild(loopBoneName)

			if loopPart then

				local timeOffset = (boneLoopIndex - 1) * timeStep

				local currentIndex = boneLoopIndex

				local tempHolder = nil

				for i2 = 2, v187 do

					if timeOffset <= zeroVector[i2] then

						tempHolder = i2

						break

					end

				end

				local j

				if tempHolder and (moduleDependencies[tempHolder] and moduleDependencies[tempHolder - 1]) then

					local previousTime = zeroVector[tempHolder - 1]

					local currentTime = zeroVector[tempHolder]

					local lerpAlpha = (timeOffset - previousTime) / math.max(1e-6, currentTime - previousTime)

					local previousPosition2 = moduleDependencies[tempHolder - 1].pos

					local currentPosition2 = moduleDependencies[tempHolder].pos

					local previousRotation = moduleDependencies[tempHolder - 1].rot

					local interpolatedPosition = previousPosition2:Lerp(currentPosition2, lerpAlpha)

					local interpolatedCFrame = CFrame.new(interpolatedPosition) * previousRotation

					if not eventListeners[loopBoneName] then

						eventListeners[loopBoneName] = loopPart.CFrame

					end

					if not connectionList[loopBoneName] then

						connectionList[loopBoneName] = loopPart.CFrame

					end

					connectionList[loopBoneName] = interpolatedCFrame

					local interpolatedAttachment = eventListeners[loopBoneName]:Lerp(connectionList[loopBoneName], lerpSpeed)

					loopPart.CFrame = interpolatedAttachment

					loopPart.AssemblyLinearVelocity = Vector3.zero

					loopPart.AssemblyAngularVelocity = Vector3.zero

					eventListeners[loopBoneName] = interpolatedAttachment

					j = currentIndex

				else

					local cameraCFrame = rootPosition.CFrame

					local rayOrigin = cameraCFrame + cameraCFrame.LookVector * (-(j - 1) * timeStep)

					loopPart.CFrame = rayOrigin

					eventListeners[loopBoneName] = rayOrigin

					j = currentIndex

				end

			end

		end

	end

end

function updateCharacter(player2)

	if isInitialized and (animationTrack and (animationTrack.Parent and (animationFolder and animationFolder.Parent))) then

		if isRendering then

			lerpTransform(player2)

			return

		elseif groundModeEnabled then

			for characterPart, characterModel2 in pairs(defaultOffsets) do
				local characterPartInstance = animationTrack:FindFirstChild(characterPart)

				if characterPartInstance and characterPartInstance:IsA("BasePart") then

					characterPartInstance.CFrame = CFrame.new(characterModel2)

					characterPartInstance.AssemblyLinearVelocity = Vector3.zero

					characterPartInstance.AssemblyAngularVelocity = Vector3.zero

				end
			end

			return

		elseif isPaused then

			for worldModel, worldModelInstance in pairs(scaledOffsets) do
				local worldPartInstance = animationTrack:FindFirstChild(worldModel)

				if worldPartInstance and worldPartInstance:IsA("BasePart") then

					worldPartInstance.CFrame = CFrame.new(worldModelInstance)

					worldPartInstance.AssemblyLinearVelocity = Vector3.zero

					worldPartInstance.AssemblyAngularVelocity = Vector3.zero

				end
			end

		else

			for _, characterBone in ipairs(bodyPartNames) do

				local worldBone = animationTrack:FindFirstChild(characterBone)

				local characterHumanoid = animationFolder:FindFirstChild(characterBone)

				if worldBone and characterHumanoid then

					if _G.hiddenBodyParts[characterBone] then

						if not _G.hiddenBodyPartPositions then

							_G.hiddenBodyPartPositions = {}

						end

						if not _G.hiddenBodyPartPositions[characterBone] then

							local gravityForce = Vector3.new(0, -500, 0)

							local baseCFrame = worldBone.CFrame - worldBone.Position

							_G.hiddenBodyPartPositions[characterBone] = CFrame.new(gravityForce) * baseCFrame

						end

						worldBone.CFrame = _G.hiddenBodyPartPositions[characterBone]

					else

						if _G.hiddenBodyPartPositions then

							_G.hiddenBodyPartPositions[characterBone] = nil

						end

						worldBone.Anchored = false

						worldBone.CFrame = characterHumanoid.CFrame

					end

					worldBone.AssemblyLinearVelocity = Vector3.zero

					worldBone.AssemblyAngularVelocity = Vector3.zero

				end

			end

			local worldHumanoid = animationFolder:FindFirstChildWhichIsA("Humanoid")

			if worldHumanoid and (scaleSettings.heightScale ~= 1 or scaleSettings.widthScale ~= 1) then

				local halfHeight = animationConfig * scaleSettings.heightScale - 0.5

				worldHumanoid.HipHeight = math.max(halfHeight, 0.2)

			end

		end

	else

		return

	end

end

function applyAnimation()

	if isInitialized and animationFolder then

		local targetHumanoid = animationFolder:FindFirstChildWhichIsA("Humanoid")

		if targetHumanoid then

			local scaledHalfHeight = animationConfig * scaleSettings.heightScale - 0.5

			targetHumanoid.HipHeight = math.max(scaledHalfHeight, 0.2)

			for partAttachment, worldAttachment in pairs(activeAnimations) do
				if partAttachment and partAttachment:IsA("BasePart") then

					partAttachment.Size = Vector3.new(worldAttachment.X * scaleSettings.widthScale, worldAttachment.Y * scaleSettings.heightScale, worldAttachment.Z * scaleSettings.widthScale)

				end

			end

			for worldAttachmentPoint, jointInstance in pairs(loadedAnimations) do
				if worldAttachmentPoint and worldAttachmentPoint:IsA("Motor6D") then

					local c0Position = jointInstance.C0.Position

					local scaledC0Position = Vector3.new(c0Position.X * scaleSettings.widthScale, c0Position.Y * scaleSettings.heightScale, c0Position.Z * scaleSettings.widthScale)

					worldAttachmentPoint.C0 = CFrame.new(scaledC0Position) * (jointInstance.C0 - jointInstance.C0.Position)

					local c1Position = jointInstance.C1.Position

					local scaledC1Position = Vector3.new(c1Position.X * scaleSettings.widthScale, c1Position.Y * scaleSettings.heightScale, c1Position.Z * scaleSettings.widthScale)

					worldAttachmentPoint.C1 = CFrame.new(scaledC1Position) * (jointInstance.C1 - jointInstance.C1.Position)

				end

			end

		end

	else

		return

	end

end

function renderStepHandler()

	pcall(function()

		local virtualModel = workspaceService:FindFirstChild("VirtuallyNad")

		if virtualModel then

			local headMovementAttachment = virtualModel:FindFirstChild("HeadMovement")

			if headMovementAttachment and headMovementAttachment:IsA("LocalScript") then

				headMovementAttachment.Disabled = true

			end

		end

		localPlayer:SetAttribute("TurnHead", false)

	end)

end

function virtualNadPart()

	pcall(function()

		local virtuallyNadPart = workspaceService:FindFirstChild("VirtuallyNad")

		if virtuallyNadPart then

			local headMovementAttachment2 = virtuallyNadPart:FindFirstChild("HeadMovement")

			if headMovementAttachment2 and headMovementAttachment2:IsA("LocalScript") then

				headMovementAttachment2.Disabled = false

			end

		end

	end)

end

local ragdollEvent = nil

function ragdollModule(player3)

	isInitialized = player3

	onyxAPI.reanimate(player3)

	if isInitialized then

		animationFolder = onyxAPI.get_clone(localPlayer)

		animationTrack = onyxAPI.get_real_character(localPlayer)

		if animationFolder then

			local targetHumanoid = animationFolder:FindFirstChildWhichIsA("Humanoid")

			if targetHumanoid then

				workspaceService.CurrentCamera.CameraSubject = targetHumanoid

				targetHumanoid:ChangeState(Enum.HumanoidStateType.Running)

			end

		end

		task.spawn(function()
			task.wait(0.25)
			if isInitialized and animationFolder then
				stateCheckFunction()
			end
		end)

	else

		animationFolder = nil

		animationTrack = nil

		local character = localPlayer.Character

		if character then

			local humanoid = character:FindFirstChildWhichIsA("Humanoid")

			if humanoid then

				workspaceService.CurrentCamera.CameraSubject = humanoid

			end

		end

	end

end

local eventListeners2 = {}

function animationModule()

	onyxAPI.stop_animation()

	animationContext.isRunning = false

	animationContext.currentId = nil
	animationContext.currentName = nil
	animationContext.isManualAnim = false

	for _, requestSuccess in pairs(eventListeners2) do
		requestSuccess.NameButton.BackgroundColor3 = Color3.new(0, 0, 0)
	end

end

function decodedResponse(url, overrideName, isStateTrigger)

	if not onyxAPI.is_reanimated() then
		warn("Reanimate first!")
		return
	end

	if url == "" then
		return
	end

	-- Lazy load: if url is a file path, load it now
	if type(url) == "string" then
		if url:match("^slate/") or url:match("^OnyxV2Folder/") then
			local readOk, fileContent = pcall(readfile, url)
			if readOk and fileContent and fileContent ~= "" then
				url = fileContent
				-- Cache the actual content if we have the name
				if overrideName and transformCache[overrideName] then
					transformCache[overrideName] = fileContent
				end
			else
				warn("[Slate] Failed to load animation file: " .. tostring(url))
				return
			end
		end
	end

	for _, animationData4 in pairs(eventListeners2) do
		animationData4.NameButton.BackgroundColor3 = Color3.new(0, 0, 0)
	end

	local animationList = { animationQueue, characterAttachments, transformCache }

	local currentAnimation = overrideName

	if not currentAnimation then
		for _, bodyParts in ipairs(animationList) do
			if bodyParts then
				for partObj, playingTracks in pairs(bodyParts) do
					if tostring(playingTracks) == url then
						currentAnimation = partObj
						break
					end
				end
				if currentAnimation then
					break
				end
			end
		end
	end

	if currentAnimation and eventListeners2[currentAnimation] then
		eventListeners2[currentAnimation].NameButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	end

	local isPlaying, currentUrl = onyxAPI.is_animation_playing()

	if isPlaying and currentUrl == url then
		animationModule()
		currentlyPlayingLabel.Text = "Playing: None"
		task.spawn(function()
			task.wait(0.05)
			if isInitialized and animationFolder then
				stateCheckFunction()
			end
		end)
		return
	end

	-- Instant 0ms synchronous animation playback
	animationContext.currentId = url
	animationContext.isRunning = true
	animationContext.isManualAnim = not isStateTrigger

	local clone = onyxAPI.get_clone(localPlayer)
	if clone and clone:FindFirstChild("HumanoidRootPart") then
		onyxAPI.play_animation(url, animationContext.speed)
	else
		task.spawn(function()
			local waited = 0
			while not (clone and clone:FindFirstChild("HumanoidRootPart")) and waited < 1.0 do
				waited = waited + task.wait(0.02)
				clone = onyxAPI.get_clone(localPlayer)
			end
			onyxAPI.play_animation(url, animationContext.speed)
		end)
	end
	animationContext.isRunning = onyxAPI.is_animation_playing()

	local playingAnimName = overrideName or "None"

		if playingAnimName == "None" then
			for name, val in pairs(animationQueue) do
				if tostring(val) == url then
					playingAnimName = name
					break
				end
			end
		end

		if playingAnimName == "None" then
			for name, val in pairs(characterAttachments) do
				if tostring(val) == url then
					playingAnimName = name
					break
				end
			end
		end

		if playingAnimName == "None" then
			for name, val in pairs(transformCache) do
				if tostring(val) == url then
					playingAnimName = name
					break
				end
			end
		end

		animationContext.currentName = playingAnimName

		if currentPlayingAnimLabel then
			currentPlayingAnimLabel.Text = "Playing: " .. playingAnimName
		end

end

function updateFunction(stateName2)

	if not (animationFolder and isInitialized) then
		return
	end

	local animName = stateAnimations[stateName2]
	local animationTrack2 = animName and (transformCache[animName] or animationQueue[animName] or characterAttachments[animName])

	-- If a manual emote/animation from the list is playing, don't interrupt it with state changes
	if animationContext.isRunning and animationContext.isManualAnim then
		return
	end

	if animationTrack2 and animationTrack2 ~= "" then
		if animationFolder then
			if animationFolder:FindFirstChildWhichIsA("Humanoid") then
				-- If already playing this exact state animation, don't restart it
				if animationContext.isRunning and animationContext.currentName == animName then
					return
				end

				if animationContext.isRunning then
					animationModule()
				end

				if animationFolder and isInitialized then
					pcall(function()
						decodedResponse(tostring(animationTrack2), animName, true)
					end)
				end
			end
		end
	else
		-- If state animation is cleared (None) and an automatic state anim was playing, stop it
		if animationContext.isRunning and not animationContext.isManualAnim then
			animationModule()
		end
	end

end

function stateCheckFunction()
	local player = get_local_player()
	if typeof(player) == "string" then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Disconnect old state connections
	if onyx.connections.state_changed then
		pcall(function() onyx.connections.state_changed:Disconnect() end)
		onyx.connections.state_changed = nil
	end
	if onyx.connections.move_changed then
		pcall(function() onyx.connections.move_changed:Disconnect() end)
		onyx.connections.move_changed = nil
	end

	local function evaluateState()
		if not humanoid or not humanoid.Parent then return end

		local isMoving = humanoid.MoveDirection.Magnitude > 0.05
		local floorMaterial = humanoid.FloorMaterial

		local targetState = "idle"
		if floorMaterial == Enum.Material.Air then
			-- In air (Jumping/Falling)
			local root = humanoid.Parent and (humanoid.Parent:FindFirstChild("HumanoidRootPart") or humanoid.Parent:FindFirstChild("Torso") or humanoid.Parent:FindFirstChildWhichIsA("BasePart"))
			local velY = root and root.Velocity.Y or 0
			if velY > 1 then
				targetState = "jumping"
			else
				targetState = "walking" -- fallback to walking/run state
			end
		elseif isMoving then
			targetState = "walking"
		else
			targetState = "idle"
		end

		updateFunction(targetState)
	end

	-- Connect StateChanged of the real character's humanoid
	onyx.connections.state_changed = humanoid.StateChanged:Connect(function(old, new)
		evaluateState()
	end)

	-- Connect MoveDirection of the real character's humanoid to detect moving vs idle
	onyx.connections.move_changed = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		evaluateState()
	end)

	-- Initial check
	evaluateState()
end

local favIconId = "rbxthumb://type=Asset&id=105536176972318&w=150&h=150"

local unfavIconId = "rbxthumb://type=Asset&id=108960170332502&w=150&h=150"

local delIconId = "rbxthumb://type=Asset&id=128430541943949&w=150&h=150"

local keybindIconId = "rbxthumb://type=Asset&id=124657808272985&w=150&h=150"


local isSettingBind = false

-- createVectorShadow moved to global scope
task.wait()
function guiUpdateFunction()
	local panelHost = (gethui and gethui()) or game:GetService("CoreGui")

	if panelHost:FindFirstChild("AKReanimGUI") then
		panelHost:FindFirstChild("AKReanimGUI"):Destroy()
	end

	local screenGuiInstance = Instance.new("ScreenGui")

	screenGuiInstance.Name = "AKReanimGUI"
	screenGuiInstance.ResetOnSpawn = false

	-- show_ui (top-of-file variable, mirrored to _G.show_ui) is the master switch.
	local shouldAutoOpen = (_G.show_ui ~= false) and (_G.AutoOpenReanimGUI ~= false) and (_G.ReanimEmbedded ~= true)
	screenGuiInstance.Enabled = shouldAutoOpen

	screenGuiInstance.Parent = panelHost

	_G.AKReanimGUIInstance = screenGuiInstance
	if getgenv then getgenv().AKReanimGUIInstance = screenGuiInstance end

	local isMenuOpen2 = false
	local characterModel4 = "all"

	local mainFrame = Instance.new("Frame")



	local resizeIconId = "rbxthumb://type=Asset&id=82637680965992&w=150&h=150"

	-- Resizable helper function
	local function makeResizable(frame, minSize)
		minSize = minSize or Vector2.new(150, 150)

		local handle = Instance.new("Frame", frame)
		handle.Name = "ResizeHandle"
		handle.Size = UDim2.new(0, 18, 0, 18)
		handle.Position = UDim2.new(1, -20, 1, -20)
		handle.BackgroundTransparency = 1
		handle.ZIndex = 99

		local img = Instance.new("ImageLabel", handle)
		img.Size = UDim2.new(0, 12, 0, 12)
		img.Position = UDim2.new(0, 3, 0, 3)
		img.BackgroundTransparency = 1
		img.Image = resizeIconId
		img.ImageColor3 = Color3.fromRGB(220, 220, 220)
		img.ZIndex = 99

		local btn = Instance.new("TextButton", handle)
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 101

		local dragging = false
		local dragStart = Vector2.new()
		local startSize = UDim2.new()

		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startSize = frame.Size

				local connection
				connection = userInputService.InputChanged:Connect(function(change)
					if dragging and (change.UserInputType == Enum.UserInputType.MouseMovement or change.UserInputType == Enum.UserInputType.Touch) then
						local delta = change.Position - dragStart
						local startWidth = startSize.X.Offset
						local startHeight = startSize.Y.Offset

						local newWidth = math.max(minSize.X, startWidth + delta.X)
						local newHeight = math.max(minSize.Y, startHeight + delta.Y)

						frame.Size = UDim2.new(startSize.X.Scale, newWidth, startSize.Y.Scale, newHeight)
					else
						connection:Disconnect()
					end
				end)

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if connection then connection:Disconnect() end
					end
				end)
			end
		end)
	end

	-- Main frame — styled directly like key system Rectangle 1
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 300, 0, 420)
	mainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
	mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 1
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGuiInstance
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
	makeResizable(mainFrame, Vector2.new(200, 300))


	local function addBorderStroke(parent, color, thickness)

		local stroke = Instance.new("UIStroke", parent)

		pcall(function() stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)

		stroke.Color = color or Color3.fromRGB(35, 35, 35)

		stroke.Thickness = thickness or 0.99

		local strokeGrad = Instance.new("UIGradient", stroke)
		strokeGrad.Rotation = 45
		strokeGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 40, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 90, 90))
		})

		return stroke

	end

	addBorderStroke(mainFrame, Color3.fromRGB(32, 32, 32))

	local headerFrame = Instance.new("Frame")

	headerFrame.Size = UDim2.new(1, 0, 0, 44)

	headerFrame.Position = UDim2.new(0, 0, 0, 0)

	headerFrame.BackgroundTransparency = 1

	headerFrame.Parent = mainFrame

	-- Key-system logo in header
	local headerLogo = Instance.new("ImageLabel", headerFrame)
	headerLogo.Name = "SlateLogo"
	headerLogo.Image = "rbxassetid://106790631609801"
	headerLogo.ScaleType = Enum.ScaleType.Fit
	headerLogo.Size = UDim2.new(0, 22, 0, 22)
	headerLogo.Position = UDim2.new(0, 12, 0.5, -11)
	headerLogo.BackgroundTransparency = 1
	headerLogo.ZIndex = 5

	local titleLabel = Instance.new("TextLabel")

	titleLabel.Size = UDim2.new(1, -160, 1, 0)

	titleLabel.Position = UDim2.new(0, 40, 0, 0)

	titleLabel.BackgroundTransparency = 1

	titleLabel.Text = "Reanimate"

	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	titleLabel.TextSize = 13

	titleLabel.Font = Enum.Font.BuilderSansBold

	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	titleLabel.Parent = headerFrame

	-- Close button — Spotify-style: no background box, plain white text
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.Position = UDim2.new(1, -30, 0.5, -12)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "×"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = headerFrame
	closeButton.MouseEnter:Connect(function()
		closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
	-- Minimize button — Spotify-style: no background box, plain white text
	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Size = UDim2.new(0, 24, 0, 24)
	minimizeButton.Position = UDim2.new(1, -58, 0.5, -12)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "−"
	minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimizeButton.TextSize = 16
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.Parent = headerFrame
	minimizeButton.MouseEnter:Connect(function()
		minimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	end)
	minimizeButton.MouseLeave:Connect(function()
		minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)

	local reanimToggleFrame = Instance.new("Frame", headerFrame)

	reanimToggleFrame.Size = UDim2.new(0, 32, 0, 14)

	reanimToggleFrame.Position = UDim2.new(1, -96, 0.5, -7)

	reanimToggleFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

	Instance.new("UICorner", reanimToggleFrame).CornerRadius = UDim.new(0, 7)

	addBorderStroke(reanimToggleFrame, Color3.fromRGB(32, 32, 32))

	local reanimToggleIndicator = Instance.new("Frame", reanimToggleFrame)

	reanimToggleIndicator.Size = UDim2.new(0, 10, 0, 10)

	reanimToggleIndicator.Position = UDim2.new(0, 2, 0, 2)

	reanimToggleIndicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)

	Instance.new("UICorner", reanimToggleIndicator).CornerRadius = UDim.new(0, 5)

	local reanimToggleBtn = Instance.new("TextButton", reanimToggleFrame)

	reanimToggleBtn.Size = UDim2.new(1, 0, 1, 0)

	reanimToggleBtn.BackgroundTransparency = 1

	reanimToggleBtn.Text = ""

	local isToggled = false
	local isToggleRunning = false
	local reanimLastClicked = 0

	task.spawn(function()
		local lastState = nil
		while reanimToggleFrame and reanimToggleFrame.Parent do
			local currentState = false
			if onyxAPI and onyxAPI.is_reanimated then
				currentState = onyxAPI.is_reanimated()
			end
			if currentState ~= lastState then
				lastState = currentState
				isToggled = currentState
				local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				if currentState then
					tweenService:Create(reanimToggleIndicator, tweenInfo, { Position = UDim2.new(1, -12, 0, 2), BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
				else
					tweenService:Create(reanimToggleIndicator, tweenInfo, { Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = Color3.fromRGB(150, 150, 150) }):Play()
				end
			end
			task.wait(0.25)
		end
	end)

	reanimToggleBtn.MouseButton1Click:Connect(function()
		if isToggleRunning then return end
		local startTime = tick()
		if startTime - reanimLastClicked >= 0.75 then
			isToggleRunning = true
			reanimLastClicked = startTime

			local currentState = false
			if onyxAPI and onyxAPI.is_reanimated then
				currentState = onyxAPI.is_reanimated()
			end
			local targetState = not currentState

			local camera = workspaceService.CurrentCamera
			local saved_camera_cframe = camera.CFrame

			ragdollModule(targetState)

			if targetState then
				task.spawn(function()
					task.wait(0.3)
					if isInitialized and animationFolder then
						stateCheckFunction()
					end
				end)
			end

			task.wait()
			camera.CFrame = saved_camera_cframe

			task.spawn(function()
				task.wait(0.75)
				isToggleRunning = false
			end)
		end
	end)

	local settingsFrame = Instance.new("ScrollingFrame")

	settingsFrame.Size = UDim2.new(1, -24, 0, 26)

	settingsFrame.Position = UDim2.new(0, 12, 0, 56)

	settingsFrame.BackgroundTransparency = 1

	settingsFrame.BorderSizePixel = 0

	settingsFrame.ClipsDescendants = true

	settingsFrame.ScrollBarThickness = 0

	settingsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

	settingsFrame.AutomaticCanvasSize = Enum.AutomaticSize.X

	settingsFrame.ScrollingDirection = Enum.ScrollingDirection.X

	settingsFrame.Parent = mainFrame

	local listLayoutSettings = Instance.new("UIListLayout", settingsFrame)

	listLayoutSettings.FillDirection = Enum.FillDirection.Horizontal

	listLayoutSettings.HorizontalAlignment = Enum.HorizontalAlignment.Left

	listLayoutSettings.Padding = UDim.new(0, 12)

	listLayoutSettings.SortOrder = Enum.SortOrder.LayoutOrder

	listLayoutSettings:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		settingsFrame.CanvasSize = UDim2.new(0, listLayoutSettings.AbsoluteContentSize.X + 24, 0, 0)
	end)

	local function createCategoryBtn(name, text, layoutOrder)

		local btn = Instance.new("TextButton")

		btn.Size = UDim2.new(0, 0, 1, 0)
		btn.AutomaticSize = Enum.AutomaticSize.X

		btn.BackgroundTransparency = 1

		btn.Text = text

		btn.TextColor3 = Color3.fromRGB(140, 140, 140)

		btn.TextSize = 10

		btn.Font = Enum.Font.GothamMedium

		btn.BorderSizePixel = 0

		btn.LayoutOrder = layoutOrder

		btn.Parent = settingsFrame



		local activeBar = Instance.new("Frame", btn)

		activeBar.Name = "ActiveBar"

		activeBar.Size = UDim2.new(1, 0, 0, 2)

		activeBar.Position = UDim2.new(0, 0, 1, -2)

		activeBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

		activeBar.BorderSizePixel = 0

		activeBar.Visible = false

		return btn

	end

	local allBtn = createCategoryBtn("allBtn", "All", 1)

	local favsBtn = createCategoryBtn("favsBtn", "Favs", 2)

	local customBtn = createCategoryBtn("customBtn", "Custom", 3)

	local bindsBtn = createCategoryBtn("bindsBtn", "Binds", 4)

	local speedTabBtn = createCategoryBtn("speedTabBtn", "Speed", 5)

	local statesTabBtn = createCategoryBtn("statesTabBtn", "States", 6)

	local trackerTabBtn = createCategoryBtn("trackerTabBtn", "Trackers", 7)

	local combineTabBtn = createCategoryBtn("combineTabBtn", "Combine", 8)

	local settingsBtn = createCategoryBtn("settingsBtn", "Settings", 9)

	local playingStatusBar = Instance.new("Frame")

	playingStatusBar.Size = UDim2.new(1, -24, 0, 26)

	playingStatusBar.Position = UDim2.new(0, 12, 0, 88)

	playingStatusBar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)

	playingStatusBar.Parent = mainFrame

	Instance.new("UICorner", playingStatusBar).CornerRadius = UDim.new(0, 6)

	addBorderStroke(playingStatusBar, Color3.fromRGB(30, 30, 30))

	currentlyPlayingLabel = Instance.new("TextLabel", playingStatusBar)

	currentlyPlayingLabel.Size = UDim2.new(1, -80, 1, 0)

	currentlyPlayingLabel.Position = UDim2.new(0, 10, 0, 0)

	currentlyPlayingLabel.BackgroundTransparency = 1

	currentlyPlayingLabel.Text = "Playing: None"

	currentlyPlayingLabel.TextColor3 = Color3.fromRGB(180, 180, 180)

	currentlyPlayingLabel.TextSize = 10

	currentlyPlayingLabel.TextTruncate = Enum.TextTruncate.AtEnd

	currentlyPlayingLabel.TextXAlignment = Enum.TextXAlignment.Left

	currentlyPlayingLabel.Font = Enum.Font.GothamMedium

	currentPlayingAnimLabel = currentlyPlayingLabel

	local stopBtn = Instance.new("TextButton", playingStatusBar)

	stopBtn.Size = UDim2.new(0, 48, 0, 18)

	stopBtn.Position = UDim2.new(1, -58, 0.5, -9)

	stopBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)

	stopBtn.Text = "Stop"

	stopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)

	stopBtn.TextSize = 9

	stopBtn.Font = Enum.Font.GothamBold

	Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 4)

	addBorderStroke(stopBtn, Color3.fromRGB(60, 30, 30))

	stopBtn.MouseButton1Click:Connect(function()

		animationModule()

		currentlyPlayingLabel.Text = "Playing: None"

		task.spawn(function()

			task.wait(0.05)

			if isInitialized and animationFolder then

				stateCheckFunction()

			end

		end)

	end)

	local searchBox = Instance.new("TextBox")

	searchBox.PlaceholderText = "Search animations..."

	searchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)

	searchBox.Size = UDim2.new(1, -24, 0, 26)

	searchBox.Position = UDim2.new(0, 12, 0, 120)

	searchBox.BackgroundColor3 = Color3.fromRGB(14, 14, 14)

	searchBox.TextColor3 = Color3.fromRGB(240, 240, 240)

	searchBox.ClearTextOnFocus = false

	searchBox.TextSize = 11

	searchBox.Text = ""

	searchBox.Font = Enum.Font.GothamMedium

	searchBox.BorderSizePixel = 0

	searchBox.Parent = mainFrame

	Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)

	addBorderStroke(searchBox, Color3.fromRGB(30, 30, 30))

	Instance.new("UIPadding", searchBox).PaddingLeft = UDim.new(0, 8)

	local scrollContainer = Instance.new("ScrollingFrame")

	scrollContainer.Size = UDim2.new(1, -24, 1, -170)

	scrollContainer.Position = UDim2.new(0, 12, 0, 158)

	scrollContainer.BackgroundTransparency = 1

	scrollContainer.BorderSizePixel = 0

	scrollContainer.ScrollBarThickness = 2

	scrollContainer.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)

	scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y

	scrollContainer.Parent = mainFrame

	local scrollPadding = Instance.new("UIPadding", scrollContainer)

	scrollPadding.PaddingLeft = UDim.new(0, 4)

	scrollPadding.PaddingRight = UDim.new(0, 4)

	scrollPadding.PaddingTop = UDim.new(0, 4)

	scrollPadding.PaddingBottom = UDim.new(0, 4)

	local listLayout = Instance.new("UIListLayout", scrollContainer)

	listLayout.Padding = UDim.new(0, 5)

	local settingsPanelFrame = Instance.new("Frame")

	settingsPanelFrame.Size = UDim2.new(1, -24, 1, -170)

	settingsPanelFrame.Position = UDim2.new(0, 12, 0, 158)

	settingsPanelFrame.BackgroundTransparency = 1

	settingsPanelFrame.Visible = false

	settingsPanelFrame.Parent = mainFrame

	local settingsListLayout = Instance.new("UIListLayout", settingsPanelFrame)

	settingsListLayout.Padding = UDim.new(0, 6)

	local optionFrame = Instance.new("Frame")

	optionFrame.Size = UDim2.new(1, -24, 0, 95)

	optionFrame.Position = UDim2.new(0, 12, 0, 120)

	optionFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)

	optionFrame.Visible = false

	optionFrame.Parent = mainFrame

	Instance.new("UICorner", optionFrame).CornerRadius = UDim.new(0, 6)

	addBorderStroke(optionFrame, Color3.fromRGB(30, 30, 30))

	local customList = Instance.new("UIListLayout", optionFrame)

	customList.Padding = UDim.new(0, 6)

	customList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	customList.VerticalAlignment = Enum.VerticalAlignment.Center

	local inputBox = Instance.new("TextBox")

	inputBox.PlaceholderText = "Animation Name..."

	inputBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)

	inputBox.Size = UDim2.new(0.92, 0, 0, 22)

	inputBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

	inputBox.TextColor3 = Color3.fromRGB(240, 240, 240)

	inputBox.TextSize = 10

	inputBox.Text = ""

	inputBox.Font = Enum.Font.GothamMedium

	inputBox.TextTruncate = Enum.TextTruncate.AtEnd

	inputBox.ClipsDescendants = true

	inputBox.ClearTextOnFocus = false

	inputBox.Parent = optionFrame

	Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 4)

	addBorderStroke(inputBox, Color3.fromRGB(28, 28, 28))

	Instance.new("UIPadding", inputBox).PaddingLeft = UDim.new(0, 8)

	local sliderInput = Instance.new("TextBox")

	sliderInput.PlaceholderText = "Keyframe Code / Asset ID..."

	sliderInput.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)

	sliderInput.Size = UDim2.new(0.92, 0, 0, 22)

	sliderInput.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

	sliderInput.TextColor3 = Color3.fromRGB(240, 240, 240)

	sliderInput.TextSize = 10

	sliderInput.Text = ""

	sliderInput.ClearTextOnFocus = false

	sliderInput.Font = Enum.Font.GothamMedium

	sliderInput.TextTruncate = Enum.TextTruncate.AtEnd

	sliderInput.ClipsDescendants = true

	sliderInput.Parent = optionFrame

	Instance.new("UICorner", sliderInput).CornerRadius = UDim.new(0, 4)

	addBorderStroke(sliderInput, Color3.fromRGB(28, 28, 28))

	Instance.new("UIPadding", sliderInput).PaddingLeft = UDim.new(0, 8)

	local customActionsRow = Instance.new("Frame")
	customActionsRow.Size = UDim2.new(0.92, 0, 0, 22)
	customActionsRow.BackgroundTransparency = 1
	customActionsRow.Parent = optionFrame

	local customActionsLayout = Instance.new("UIListLayout", customActionsRow)
	customActionsLayout.FillDirection = Enum.FillDirection.Horizontal
	customActionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	customActionsLayout.Padding = UDim.new(0, 6)

	local addSubmitBtn = Instance.new("TextButton")
	addSubmitBtn.Size = UDim2.new(0.68, 0, 1, 0)
	addSubmitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	addSubmitBtn.Text = "Save Custom Animation"
	addSubmitBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
	addSubmitBtn.TextSize = 10
	addSubmitBtn.Font = Enum.Font.GothamBold
	addSubmitBtn.BorderSizePixel = 0
	addSubmitBtn.Parent = customActionsRow
	Instance.new("UICorner", addSubmitBtn).CornerRadius = UDim.new(0, 4)

	local refreshCustomsBtn = Instance.new("TextButton")
	refreshCustomsBtn.Size = UDim2.new(0.3, 0, 1, 0)
	refreshCustomsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	refreshCustomsBtn.Text = "Refresh"
	refreshCustomsBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	refreshCustomsBtn.TextSize = 10
	refreshCustomsBtn.Font = Enum.Font.GothamBold
	refreshCustomsBtn.BorderSizePixel = 0
	refreshCustomsBtn.Parent = customActionsRow
	Instance.new("UICorner", refreshCustomsBtn).CornerRadius = UDim.new(0, 4)
	addBorderStroke(refreshCustomsBtn, Color3.fromRGB(50, 50, 55))

	refreshCustomsBtn.MouseButton1Click:Connect(function()
		refreshCustomsBtn.Text = "..."
		task.spawn(function()
			pcall(importFromOnyx, true)
			pcall(createAnimationTrack)
			if loadGUI then loadGUI() end
			task.wait(0.4)
			refreshCustomsBtn.Text = "Refresh"
		end)
	end)

	local speedsPanelFrame = Instance.new("Frame")

	speedsPanelFrame.Size = UDim2.new(1, -24, 1, -170)

	speedsPanelFrame.Position = UDim2.new(0, 12, 0, 158)

	speedsPanelFrame.BackgroundTransparency = 1

	speedsPanelFrame.Visible = false

	speedsPanelFrame.Parent = mainFrame

	local speedListLayout = Instance.new("UIListLayout", speedsPanelFrame)

	speedListLayout.Padding = UDim.new(0, 8)

	-- States Tab Panel (Idle, Walk, Jump setting custom animations)

	local statesPanelFrame = Instance.new("Frame")

	statesPanelFrame.Size = UDim2.new(1, -24, 1, -170)

	statesPanelFrame.Position = UDim2.new(0, 12, 0, 158)

	statesPanelFrame.BackgroundTransparency = 1

	statesPanelFrame.Visible = false

	statesPanelFrame.Parent = mainFrame

	local statesListLayout = Instance.new("UIListLayout", statesPanelFrame)

	statesListLayout.Padding = UDim.new(0, 6)

	-- Trackers & Stretching Panel Frame
	local trackersPanelFrame = Instance.new("ScrollingFrame")
	trackersPanelFrame.Size = UDim2.new(1, -24, 1, -132)
	trackersPanelFrame.Position = UDim2.new(0, 12, 0, 120)
	trackersPanelFrame.BackgroundTransparency = 1
	trackersPanelFrame.BorderSizePixel = 0
	trackersPanelFrame.ScrollBarThickness = 2
	trackersPanelFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
	trackersPanelFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	trackersPanelFrame.Visible = false
	trackersPanelFrame.Parent = mainFrame

	local trackersListLayout = Instance.new("UIListLayout", trackersPanelFrame)
	trackersListLayout.Padding = UDim.new(0, 6)
	trackersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	trackersListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		trackersPanelFrame.CanvasSize = UDim2.new(0, 0, 0, trackersListLayout.AbsoluteContentSize.Y + 10)
	end)

	local function createTrackerCard(titleText, subText, defaultState, onToggle, hasKeybind, keyRef, onKeybind, updateRefName)
		local card = Instance.new("Frame", trackersPanelFrame)
		card.Size = UDim2.new(1, 0, 0, 52)
		card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 5)
		addBorderStroke(card, Color3.fromRGB(30, 30, 30))

		local titleLbl = Instance.new("TextLabel", card)
		titleLbl.Size = UDim2.new(0.55, 0, 0, 18)
		titleLbl.Position = UDim2.new(0, 10, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = titleText
		titleLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
		titleLbl.TextSize = 10
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left

		local subLbl = Instance.new("TextLabel", card)
		subLbl.Size = UDim2.new(0.55, 0, 0, 20)
		subLbl.Position = UDim2.new(0, 10, 0, 24)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = subText
		subLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
		subLbl.TextSize = 8
		subLbl.Font = Enum.Font.Gotham
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.TextWrapped = true

		local toggleBtn = Instance.new("TextButton", card)
		toggleBtn.Size = UDim2.new(0, 42, 0, 20)
		toggleBtn.Position = UDim2.new(1, -52, 0, 16)
		toggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
		toggleBtn.Text = defaultState and "ON" or "OFF"
		toggleBtn.TextColor3 = defaultState and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)
		toggleBtn.TextSize = 9
		toggleBtn.Font = Enum.Font.GothamBold
		toggleBtn.BorderSizePixel = 0
		Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

		local state = defaultState
		local function updateUIState(newState)
			state = newState
			toggleBtn.BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
			toggleBtn.Text = state and "ON" or "OFF"
			toggleBtn.TextColor3 = state and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)
		end

		if updateRefName then
			_G[updateRefName] = updateUIState
		end

		toggleBtn.MouseButton1Click:Connect(function()
			state = not state
			updateUIState(state)
			if onToggle then onToggle(state) end
			pcall(updateStandaloneTrackers)
		end)

		if hasKeybind then
			local keyBtn = Instance.new("TextButton", card)
			keyBtn.Size = UDim2.new(0, 52, 0, 20)
			keyBtn.Position = UDim2.new(1, -110, 0, 16)
			keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			local curKey = keyRef and keyRef()
			keyBtn.Text = curKey and ("Key: " .. curKey.Name:sub(1,3)) or "Key: None"
			keyBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
			keyBtn.TextSize = 8
			keyBtn.Font = Enum.Font.GothamBold
			keyBtn.BorderSizePixel = 0
			Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4)

			local listening = false
			keyBtn.MouseButton1Click:Connect(function()
				if listening then return end
				if keyRef and keyRef() then
					if onKeybind then onKeybind(nil) end
					keyBtn.Text = "Key: None"
					keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					pcall(saveTrackerKeybinds)
					return
				end
				listening = true
				keyBtn.Text = "Press..."
				keyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				local conn
				conn = userInputService.InputBegan:Connect(function(input, processed)
					if processed then return end
					conn:Disconnect()
					listening = false
					keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					if input.KeyCode == Enum.KeyCode.Escape then
						keyBtn.Text = "Key: None"
						if onKeybind then onKeybind(nil) end
					else
						keyBtn.Text = "Key: " .. input.KeyCode.Name:sub(1,3)
						if onKeybind then onKeybind(input.KeyCode) end
					end
					pcall(saveTrackerKeybinds)
				end)
			end)
		end

		return card
	end

	local function saveTrackerKeybinds()
		pcall(function()
			local data = {
				head = _G._HaloHeadTrackerKey and _G._HaloHeadTrackerKey.Name or nil,
				leftArm = _G._HaloLeftArmKey and _G._HaloLeftArmKey.Name or nil,
				rightArm = _G._HaloRightArmKey and _G._HaloRightArmKey.Name or nil
			}
			writefile("slate/reanimation/tracker_keybinds.json", httpService:JSONEncode(data))
		end)
	end

	local function loadTrackerKeybinds()
		pcall(function()
			if isfile and isfile("slate/reanimation/tracker_keybinds.json") then
				local str = readfile("slate/reanimation/tracker_keybinds.json")
				local data = httpService:JSONDecode(str)
				if type(data) == "table" then
					if data.head then pcall(function() _G._HaloHeadTrackerKey = Enum.KeyCode[data.head] end) end
					if data.leftArm then pcall(function() _G._HaloLeftArmKey = Enum.KeyCode[data.leftArm] end) end
					if data.rightArm then pcall(function() _G._HaloRightArmKey = Enum.KeyCode[data.rightArm] end) end
				end
			end
		end)
	end

	loadTrackerKeybinds()

	local function matchesKey(boundKey, pressedKeyCode)
		if not boundKey then return false end
		if typeof(boundKey) == "EnumItem" then
			return boundKey == pressedKeyCode
		elseif type(boundKey) == "string" then
			return boundKey:upper() == pressedKeyCode.Name:upper()
		end
		return false
	end

	if _G.trackerKeybindConn then
		pcall(function() _G.trackerKeybindConn:Disconnect() end)
	end
	_G.trackerKeybindConn = userInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		-- Head Tracker Key
		if _G._HaloHeadTrackerKey and matchesKey(_G._HaloHeadTrackerKey, input.KeyCode) then
			_G._HaloHeadTrackerEnabled = not _G._HaloHeadTrackerEnabled
			if _G.updateTrackerUI_Head then _G.updateTrackerUI_Head(_G._HaloHeadTrackerEnabled) end
			updateStandaloneTrackers()
		end

		-- Left Arm Pointer Key
		if _G._HaloLeftArmKey and matchesKey(_G._HaloLeftArmKey, input.KeyCode) then
			_G._HaloLeftArmPointerEnabled = not _G._HaloLeftArmPointerEnabled
			if _G.updateTrackerUI_LeftArm then _G.updateTrackerUI_LeftArm(_G._HaloLeftArmPointerEnabled) end
			updateStandaloneTrackers()
		end

		-- Right Arm Pointer Key
		if _G._HaloRightArmKey and matchesKey(_G._HaloRightArmKey, input.KeyCode) then
			_G._HaloRightArmPointerEnabled = not _G._HaloRightArmPointerEnabled
			if _G.updateTrackerUI_RightArm then _G.updateTrackerUI_RightArm(_G._HaloRightArmPointerEnabled) end
			updateStandaloneTrackers()
		end
	end)

	-- 1. Head Tracker Card
	createTrackerCard("Head Tracker", "Head turns to follow camera look direction", _G._HaloHeadTrackerEnabled or false, function(st)
		_G._HaloHeadTrackerEnabled = st
	end, true, function() return _G._HaloHeadTrackerKey end, function(k) _G._HaloHeadTrackerKey = k end, "updateTrackerUI_Head")

	-- 2. Left Arm Pointer Card
	createTrackerCard("Left Arm Pointer", "Points left arm straight toward mouse cursor", _G._HaloLeftArmPointerEnabled or false, function(st)
		_G._HaloLeftArmPointerEnabled = st
	end, true, function() return _G._HaloLeftArmKey end, function(k) _G._HaloLeftArmKey = k end, "updateTrackerUI_LeftArm")

	-- 3. Right Arm Pointer Card
	createTrackerCard("Right Arm Pointer", "Points right arm straight toward mouse cursor", _G._HaloRightArmPointerEnabled or false, function(st)
		_G._HaloRightArmPointerEnabled = st
	end, true, function() return _G._HaloRightArmKey end, function(k) _G._HaloRightArmKey = k end, "updateTrackerUI_RightArm")

	-- 4. Arm Stretch Card (LMB Hold Reach Stretch)
	do
		-- Load stretch mode config (toggles + keybind) from disk.
		-- Keep each step independently pcall'd so one bad field can't kill the whole load,
		-- and never index Enum.KeyCode with a raw string (that throws on invalid names).
		local stretchBindPath = "slate/reanimation/stretchbind.json"
		if type(isfile) == "function" and type(readfile) == "function" and isfile(stretchBindPath) then
			local okRead, raw = pcall(readfile, stretchBindPath)
			if okRead and type(raw) == "string" then
				local okDec, data = pcall(function() return httpService:JSONDecode(raw) end)
				if okDec and type(data) == "table" then
					if data.keybindEnabled ~= nil then _G._HaloArmStretchKeybindEnabled = data.keybindEnabled == true end
					if data.scrollEnabled ~= nil then _G._HaloArmStretchScrollEnabled = data.scrollEnabled == true end
					if type(data.key) == "string" then
						local okKey, keyEnum = pcall(function() return Enum.KeyCode[data.key] end)
						if okKey and typeof(keyEnum) == "EnumItem" then
							_G._HaloArmStretchKey = keyEnum
						end
					end
				end
			end
		end

		local function saveStretchBind()
			pcall(function()
				local data = {
					keybindEnabled = _G._HaloArmStretchKeybindEnabled == true,
					scrollEnabled = _G._HaloArmStretchScrollEnabled == true,
					key = _G._HaloArmStretchKey and _G._HaloArmStretchKey.Name or nil,
				}
				writefile(stretchBindPath, httpService:JSONEncode(data))
			end)
		end

		-- Scroll-wheel sink: while scroll mode ON, absorb Roblox camera zoom.
		-- While LMB held, scroll up increases manual stretch, scroll down decreases it.
		local ContextActionService = game:GetService("ContextActionService")
		local function updateStretchScrollBinding()
			if _G._HaloArmStretchScrollEnabled then
				if not _G._HaloArmStretchScrollBound then
					ContextActionService:BindActionAtPriority(
						"HaloStretchScrollSink",
						function(_, state, input)
							if state == Enum.UserInputState.Change and input and input.Position then
								local dz = input.Position.Z
								if dz ~= 0 and userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
									local step = 2.5 -- studs per wheel tick
									local newVal = (_G._HaloArmStretchManualExtra or 0) + dz * step
									_G._HaloArmStretchManualExtra = math.max(0, newVal)
								end
							end
							return Enum.ContextActionResult.Sink
						end,
						false, 3000, Enum.UserInputType.MouseWheel
					)
					_G._HaloArmStretchScrollBound = true
				end
			else
				if _G._HaloArmStretchScrollBound then
					pcall(function() ContextActionService:UnbindAction("HaloStretchScrollSink") end)
					_G._HaloArmStretchScrollBound = false
				end
			end
		end
		updateStretchScrollBinding()

		local stretchCard = Instance.new("Frame", trackersPanelFrame)
		stretchCard.Size = UDim2.new(1, 0, 0, 160)
		stretchCard.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		Instance.new("UICorner", stretchCard).CornerRadius = UDim.new(0, 5)
		addBorderStroke(stretchCard, Color3.fromRGB(30, 30, 30))

		local titleLbl = Instance.new("TextLabel", stretchCard)
		titleLbl.Size = UDim2.new(0.6, 0, 0, 16)
		titleLbl.Position = UDim2.new(0, 10, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = "Arm Stretch & Reach (LMB Hold)"
		titleLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
		titleLbl.TextSize = 10
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left

		local subLbl = Instance.new("TextLabel", stretchCard)
		subLbl.Size = UDim2.new(0.9, 0, 0, 14)
		subLbl.Position = UDim2.new(0, 10, 0, 22)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = "Slider = auto-reach. Enable a mode below to drive stretch manually."
		subLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
		subLbl.TextSize = 8
		subLbl.Font = Enum.Font.Gotham
		subLbl.TextXAlignment = Enum.TextXAlignment.Left

		local curAmt = _G._HaloArmStretchAmount or math.huge
		local isInf = (curAmt == math.huge) or (curAmt >= 9999)
		local pct = isInf and 0 or math.clamp((curAmt - 1.0) / 99.0 * 0.95 + 0.05, 0, 1)

		local amtLbl = Instance.new("TextLabel", stretchCard)
		amtLbl.Size = UDim2.new(0.9, 0, 0, 14)
		amtLbl.Position = UDim2.new(0, 10, 0, 36)
		amtLbl.BackgroundTransparency = 1
		amtLbl.Text = "Max Limit: " .. (isInf and "Infinite" or string.format("%.1fx", curAmt))
		amtLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
		amtLbl.TextSize = 8
		amtLbl.Font = Enum.Font.GothamBold
		amtLbl.TextXAlignment = Enum.TextXAlignment.Left

		local sliderBg = Instance.new("Frame", stretchCard)
		sliderBg.Size = UDim2.new(1, -20, 0, 4)
		sliderBg.Position = UDim2.new(0, 10, 0, 54)
		sliderBg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 2)

		local fill = Instance.new("Frame", sliderBg)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

		local handle = Instance.new("Frame", sliderBg)
		handle.Size = UDim2.new(0, 10, 0, 10)
		handle.Position = UDim2.new(pct, -5, 0.5, -5)
		handle.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
		Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 5)

		local dragging = false
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		userInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local scale = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
				if scale <= 0.05 then
					_G._HaloArmStretchAmount = math.huge
					fill.Size = UDim2.new(0, 0, 1, 0)
					handle.Position = UDim2.new(0, -5, 0.5, -5)
					amtLbl.Text = "Max Limit: Infinite"
				else
					local val = 1.0 + ((scale - 0.05) / 0.95) * 99.0
					val = math.floor(val * 10 + 0.5) / 10
					_G._HaloArmStretchAmount = val
					fill.Size = UDim2.new(scale, 0, 1, 0)
					handle.Position = UDim2.new(scale, -5, 0.5, -5)
					amtLbl.Text = "Max Limit: " .. string.format("%.1fx", val)
				end
			end
		end)

		-- Divider
		local divider = Instance.new("Frame", stretchCard)
		divider.Size = UDim2.new(1, -20, 0, 1)
		divider.Position = UDim2.new(0, 10, 0, 68)
		divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		divider.BorderSizePixel = 0

		-- Helper: build a mini toggle button used by both mode rows
		local function makeToggle(parent, xOffset, yOffset, initialState, onClick)
			local btn = Instance.new("TextButton", parent)
			btn.Size = UDim2.new(0, 42, 0, 18)
			btn.Position = UDim2.new(1, xOffset, 0, yOffset)
			btn.BackgroundColor3 = initialState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
			btn.Text = initialState and "ON" or "OFF"
			btn.TextColor3 = initialState and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)
			btn.TextSize = 9
			btn.Font = Enum.Font.GothamBold
			btn.BorderSizePixel = 0
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			local st = initialState
			local function apply(newSt)
				st = newSt
				btn.BackgroundColor3 = st and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
				btn.Text = st and "ON" or "OFF"
				btn.TextColor3 = st and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)
			end
			btn.MouseButton1Click:Connect(function()
				st = not st
				apply(st)
				if onClick then onClick(st) end
			end)
			return btn, apply, function() return st end
		end

		-- Row A: Keybind stretch toggle + keybind picker
		local kbLbl = Instance.new("TextLabel", stretchCard)
		kbLbl.Size = UDim2.new(0.6, 0, 0, 14)
		kbLbl.Position = UDim2.new(0, 10, 0, 76)
		kbLbl.BackgroundTransparency = 1
		kbLbl.Text = "Keybind Stretch"
		kbLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
		kbLbl.TextSize = 9
		kbLbl.Font = Enum.Font.GothamBold
		kbLbl.TextXAlignment = Enum.TextXAlignment.Left

		local kbSub = Instance.new("TextLabel", stretchCard)
		kbSub.Size = UDim2.new(0.6, 0, 0, 12)
		kbSub.Position = UDim2.new(0, 10, 0, 90)
		kbSub.BackgroundTransparency = 1
		kbSub.Text = "Hold LMB + key to grow reach"
		kbSub.TextColor3 = Color3.fromRGB(120, 120, 120)
		kbSub.TextSize = 8
		kbSub.Font = Enum.Font.Gotham
		kbSub.TextXAlignment = Enum.TextXAlignment.Left

		local keyBtn = Instance.new("TextButton", stretchCard)
		keyBtn.Size = UDim2.new(0, 58, 0, 18)
		keyBtn.Position = UDim2.new(1, -114, 0, 78)
		keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		local curKey = _G._HaloArmStretchKey
		keyBtn.Text = curKey and ("Key: " .. curKey.Name:sub(1, 3)) or "Key: None"
		keyBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
		keyBtn.TextSize = 8
		keyBtn.Font = Enum.Font.GothamBold
		keyBtn.BorderSizePixel = 0
		Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4)

		local listening = false
		keyBtn.MouseButton1Click:Connect(function()
			if listening then return end
			if _G._HaloArmStretchKey then
				_G._HaloArmStretchKey = nil
				keyBtn.Text = "Key: None"
				keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				saveStretchBind()
				return
			end
			listening = true
			keyBtn.Text = "Press..."
			keyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			local conn
			conn = userInputService.InputBegan:Connect(function(input, processed)
				if processed then return end
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				conn:Disconnect()
				listening = false
				keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				if input.KeyCode == Enum.KeyCode.Escape then
					_G._HaloArmStretchKey = nil
					keyBtn.Text = "Key: None"
				else
					_G._HaloArmStretchKey = input.KeyCode
					keyBtn.Text = "Key: " .. input.KeyCode.Name:sub(1, 3)
				end
				saveStretchBind()
			end)
		end)

		makeToggle(stretchCard, -52, 78, _G._HaloArmStretchKeybindEnabled == true, function(st)
			_G._HaloArmStretchKeybindEnabled = st
			-- Turning ON keybind mode resets manual reach so it starts fresh next LMB hold
			_G._HaloArmStretchManualExtra = 0
			saveStretchBind()
		end)

		-- Row B: Scroll-wheel stretch toggle
		local swLbl = Instance.new("TextLabel", stretchCard)
		swLbl.Size = UDim2.new(0.6, 0, 0, 14)
		swLbl.Position = UDim2.new(0, 10, 0, 116)
		swLbl.BackgroundTransparency = 1
		swLbl.Text = "Scroll Wheel Stretch"
		swLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
		swLbl.TextSize = 9
		swLbl.Font = Enum.Font.GothamBold
		swLbl.TextXAlignment = Enum.TextXAlignment.Left

		local swSub = Instance.new("TextLabel", stretchCard)
		swSub.Size = UDim2.new(0.7, 0, 0, 12)
		swSub.Position = UDim2.new(0, 10, 0, 130)
		swSub.BackgroundTransparency = 1
		swSub.Text = "Disables camera zoom. LMB + scroll up/down = grow/shrink."
		swSub.TextColor3 = Color3.fromRGB(120, 120, 120)
		swSub.TextSize = 8
		swSub.Font = Enum.Font.Gotham
		swSub.TextXAlignment = Enum.TextXAlignment.Left

		makeToggle(stretchCard, -52, 118, _G._HaloArmStretchScrollEnabled == true, function(st)
			_G._HaloArmStretchScrollEnabled = st
			_G._HaloArmStretchManualExtra = 0
			updateStretchScrollBinding()
			saveStretchBind()
		end)
	end

	-- 5. Arm Slider Card removed per user request

	-- 6. Torso Camera Control Card
	do
		local camCard = Instance.new("Frame", trackersPanelFrame)
		camCard.Size = UDim2.new(1, 0, 0, 62)
		camCard.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		Instance.new("UICorner", camCard).CornerRadius = UDim.new(0, 5)
		addBorderStroke(camCard, Color3.fromRGB(30, 30, 30))

		local titleLbl = Instance.new("TextLabel", camCard)
		titleLbl.Size = UDim2.new(0.55, 0, 0, 16)
		titleLbl.Position = UDim2.new(0, 10, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = "Torso Camera Control"
		titleLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
		titleLbl.TextSize = 10
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left

		local subLbl = Instance.new("TextLabel", camCard)
		subLbl.Size = UDim2.new(0.55, 0, 0, 14)
		subLbl.Position = UDim2.new(0, 10, 0, 22)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = "Lean & turn body with camera look direction"
		subLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
		subLbl.TextSize = 8
		subLbl.Font = Enum.Font.Gotham
		subLbl.TextXAlignment = Enum.TextXAlignment.Left

		local toggleBtn = Instance.new("TextButton", camCard)
		toggleBtn.Size = UDim2.new(0, 42, 0, 20)
		toggleBtn.Position = UDim2.new(1, -52, 0, 12)
		local tcState = _G._HaloLimbsTorsoCamControl or false
		toggleBtn.BackgroundColor3 = tcState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
		toggleBtn.Text = tcState and "ON" or "OFF"
		toggleBtn.TextColor3 = tcState and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)
		toggleBtn.TextSize = 9
		toggleBtn.Font = Enum.Font.GothamBold
		toggleBtn.BorderSizePixel = 0
		Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

		toggleBtn.MouseButton1Click:Connect(function()
			tcState = not tcState
			toggleBtn.BackgroundColor3 = tcState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
			toggleBtn.Text = tcState and "ON" or "OFF"
			toggleBtn.TextColor3 = tcState and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)
			_G._HaloLimbsTorsoCamControl = tcState
			pcall(updateStandaloneTrackers)
		end)

		local modeBtn = Instance.new("TextButton", camCard)
		modeBtn.Size = UDim2.new(0, 80, 0, 18)
		modeBtn.Position = UDim2.new(0, 10, 0, 38)
		modeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		local curMode = _G._HaloLimbsTorsoCamMode or "360"
		modeBtn.Text = "Mode: " .. curMode
		modeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
		modeBtn.TextSize = 8
		modeBtn.Font = Enum.Font.GothamBold
		modeBtn.BorderSizePixel = 0
		Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 4)

		local modes = {"360", "Locked", "Free"}
		local modeIdx = 1
		modeBtn.MouseButton1Click:Connect(function()
			modeIdx = (modeIdx % #modes) + 1
			_G._HaloLimbsTorsoCamMode = modes[modeIdx]
			modeBtn.Text = "Mode: " .. modes[modeIdx]
		end)
	end

	-- Combine Panel Frame (Sequence Creator & Sequence List)
	local combinePanelFrame = Instance.new("ScrollingFrame")
	combinePanelFrame.Size = UDim2.new(1, -24, 1, -132)
	combinePanelFrame.Position = UDim2.new(0, 12, 0, 120)
	combinePanelFrame.BackgroundTransparency = 1
	combinePanelFrame.BorderSizePixel = 0
	combinePanelFrame.ScrollBarThickness = 2
	combinePanelFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
	combinePanelFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	combinePanelFrame.Visible = false
	combinePanelFrame.Parent = mainFrame

	local combineListLayout = Instance.new("UIListLayout", combinePanelFrame)
	combineListLayout.Padding = UDim.new(0, 6)
	combineListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	combineListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		combinePanelFrame.CanvasSize = UDim2.new(0, 0, 0, combineListLayout.AbsoluteContentSize.Y + 10)
	end)

	_G.combinedSequences = _G.combinedSequences or {}
	_G.activeSequenceClips = _G.activeSequenceClips or {}

	local function getExactAnimationDuration(animName)
		if not animName then return 2.0 end
		local trackData = transformCache[animName] or animationQueue[animName] or characterAttachments[animName] or animName
		if not trackData then return 2.0 end

		if onyx and onyx.animation and onyx.animation.cache and onyx.animation.cache[trackData] then
			local cached = onyx.animation.cache[trackData]
			local keyframes = nil
			if cached[1] and type(cached[1]) == "table" and (cached[1].Time or cached[1].Data) then
				keyframes = cached
			else
				for _, v in pairs(cached) do
					if type(v) == "table" and v[1] and type(v[1]) == "table" and (v[1].Time or v[1].Data) then
						keyframes = v; break
					end
				end
			end
			if keyframes and #keyframes > 0 then
				local maxTime = 0
				for _, kf in ipairs(keyframes) do
					local t = tonumber(kf.Time or kf.t or (type(kf[1]) == "number" and kf[1])) or 0
					if t > maxTime then maxTime = t end
				end
				if maxTime > 0 then return math.floor(maxTime * 100 + 0.5) / 100 end
			end
		end

		if type(trackData) == "string" then
			local maxTime = 0
			for tStr in trackData:gmatch("Time%s*=%s*([%d%.]+)") do
				local t = tonumber(tStr)
				if t and t > maxTime then maxTime = t end
			end
			if maxTime > 0 then return math.floor(maxTime * 100 + 0.5) / 100 end
		end

		return 2.0
	end

	local function saveCombinedSequences()
		pcall(function()
			local dataToSave = {}
			for _, seq in ipairs(_G.combinedSequences or {}) do
				local clipData = {}
				if seq.clips then
					for _, c in ipairs(seq.clips) do
						table.insert(clipData, {
							animName = c.animName,
							cutStart = c.cutStart or 0,
							cutDuration = c.cutDuration or 2,
							maxLen = c.maxLen or 5
						})
					end
				end
				local keyStr = nil
				if typeof(seq.key) == "EnumItem" then
					keyStr = seq.key.Name
				elseif type(seq.key) == "string" then
					keyStr = seq.key:gsub("^Enum%.KeyCode%.", "")
				end
				local obj = {
					name = seq.name,
					anim1 = seq.anim1,
					anim2 = seq.anim2,
					clips = #clipData > 0 and clipData or nil,
					key = keyStr
				}
				table.insert(dataToSave, obj)

				-- Save sequence file in slate/reanimation/<sequencename>
				if seq.name and writefile then
					local safeName = seq.name:gsub("[^%w%s%-_$]", ""):match("^%s*(.-)%s*$")
					if safeName ~= "" then
						local encoded = httpService:JSONEncode(obj)
						pcall(writefile, "slate/reanimation/" .. safeName .. ".json", encoded)
						pcall(writefile, "slate/reanimation/customs/" .. safeName .. ".lua", "-- Slate Sequence\nreturn " .. encoded)
						transformCache[seq.name] = "slate/reanimation/" .. safeName .. ".json"
						if animationQueue then animationQueue[seq.name] = transformCache[seq.name] end
					end
				end
			end
			writefile("slate/reanimation/combined_sequences.json", httpService:JSONEncode(dataToSave))
		end)
	end

	local function loadCombinedSequences()
		pcall(function()
			_G.combinedSequences = _G.combinedSequences or {}
			if isfile and isfile("slate/reanimation/combined_sequences.json") then
				local str = readfile("slate/reanimation/combined_sequences.json")
				local data = httpService:JSONDecode(str)
				if type(data) == "table" then
					_G.combinedSequences = {}
					for _, seqData in ipairs(data) do
						local keyVal = nil
						if seqData.key and type(seqData.key) == "string" and seqData.key ~= "" then
							local cleanName = seqData.key:gsub("^Enum%.KeyCode%.", "")
							pcall(function() keyVal = Enum.KeyCode[cleanName] end)
						end
						local seqObj = {
							name = seqData.name,
							anim1 = seqData.anim1,
							anim2 = seqData.anim2,
							clips = seqData.clips,
							key = keyVal
						}
						table.insert(_G.combinedSequences, seqObj)
						if seqData.name then
							local safeName = seqData.name:gsub("[^%w%s%-_$]", ""):match("^%s*(.-)%s*$")
							transformCache[seqData.name] = "slate/reanimation/" .. safeName .. ".json"
							if animationQueue then animationQueue[seqData.name] = transformCache[seqData.name] end
						end
					end
				end
			end

			-- Also scan slate/reanimation folder for individual sequence files
			if isfolder and isfolder("slate/reanimation") and listfiles then
				local okList, files = pcall(listfiles, "slate/reanimation")
				if okList and type(files) == "table" then
					for _, f in ipairs(files) do
						local cleanF = f:gsub("\\", "/")
						if cleanF:match("%.json$") and not cleanF:match("combined_sequences%.json") and not cleanF:match("favorites") and not cleanF:match("states") then
							local okR, content = pcall(readfile, cleanF)
							if okR and content and content ~= "" then
								local okDec, seqData = pcall(function() return httpService:JSONDecode(content) end)
								if okDec and type(seqData) == "table" and seqData.name then
									local exists = false
									for _, existing in ipairs(_G.combinedSequences) do
										if existing.name == seqData.name then exists = true; break end
									end
									if not exists then
										local keyVal = nil
										if seqData.key and type(seqData.key) == "string" and seqData.key ~= "" then
											local cleanName = seqData.key:gsub("^Enum%.KeyCode%.", "")
											pcall(function() keyVal = Enum.KeyCode[cleanName] end)
										end
										table.insert(_G.combinedSequences, {
											name = seqData.name,
											anim1 = seqData.anim1,
											anim2 = seqData.anim2,
											clips = seqData.clips,
											key = keyVal
										})
										transformCache[seqData.name] = cleanF
										if animationQueue then animationQueue[seqData.name] = cleanF end
									end
								end
							end
						end
					end
				end
			end
		end)
	end

	loadCombinedSequences()

	local function playCombinedSequence(seq)
		if not seq then return end
		task.spawn(function()
			local clips = seq.clips
			if not clips or #clips == 0 then
				clips = {}
				if seq.anim1 then table.insert(clips, { animName = seq.anim1, cutStart = 0, cutDuration = getExactAnimationDuration(seq.anim1) }) end
				if seq.anim2 then table.insert(clips, { animName = seq.anim2, cutStart = 0, cutDuration = getExactAnimationDuration(seq.anim2) }) end
			end
			for _, clip in ipairs(clips) do
				if clip.animName then
					local animCode = transformCache[clip.animName] or animationQueue[clip.animName] or characterAttachments[clip.animName] or clip.animName
					if type(animCode) == "string" and (animCode:match("^slate/") or animCode:match("%.lua$") or animCode:match("%.json$")) and type(readfile) == "function" then
						local okRead, fileData = pcall(readfile, animCode)
						if okRead and fileData and fileData ~= "" then
							animCode = fileData
						end
					end
					if onyxAPI and onyxAPI.play_animation then
						onyxAPI.play_animation(animCode)
					end
					if clip.cutStart and clip.cutStart > 0 and onyx and onyx.animation and onyx.animation.state then
						onyx.animation.state.elapsed_time = clip.cutStart
					end
					local waitTime = clip.cutDuration or getExactAnimationDuration(clip.animName)
					task.wait(waitTime)
				end
			end
		end)
	end
	_G.playCombinedSequence = playCombinedSequence

	local function matchesKey(boundKey, inputKeyCode)
		if not boundKey or not inputKeyCode then return false end
		if typeof(boundKey) == "EnumItem" then
			return inputKeyCode == boundKey
		elseif type(boundKey) == "string" then
			local cleanKey = boundKey:gsub("^Enum%.KeyCode%.", ""):lower()
			return inputKeyCode.Name:lower() == cleanKey
		end
		return false
	end

	if _G.combinedSequencesKeyConn then
		pcall(function() _G.combinedSequencesKeyConn:Disconnect() end)
	end
	_G.combinedSequencesKeyConn = userInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if not _G.combinedSequences then return end
		for _, seq in ipairs(_G.combinedSequences) do
			if matchesKey(seq.key, input.KeyCode) then
				playCombinedSequence(seq)
				break
			end
		end
	end)

	local function getAvailableAnims()
		local list = {}
		for animName in pairs(transformCache) do table.insert(list, animName) end
		for animName in pairs(animationQueue) do if not table.find(list, animName) then table.insert(list, animName) end end
		for animName in pairs(characterAttachments) do if not table.find(list, animName) then table.insert(list, animName) end end
		table.sort(list)
		return list
	end

	local function refreshCombinePanel()
		for _, child in ipairs(combinePanelFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		-- 1. Studio Sequence Builder Creator Card
		local activeClips = _G.activeSequenceClips
		local totalDuration = 0
		for _, c in ipairs(activeClips) do
			totalDuration = totalDuration + (tonumber(c.cutDuration) or getExactAnimationDuration(c.animName))
		end

		local hasClips = #activeClips > 0
		local clipsScrollHeight = hasClips and math.clamp(#activeClips * 72, 72, 280) or 0
		local cardHeight = 110 + clipsScrollHeight + 68
		local createCard = Instance.new("Frame", combinePanelFrame)
		createCard.Size = UDim2.new(1, 0, 0, cardHeight)
		createCard.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		Instance.new("UICorner", createCard).CornerRadius = UDim.new(0, 5)
		addBorderStroke(createCard, Color3.fromRGB(30, 30, 30))

		local createTitle = Instance.new("TextLabel", createCard)
		createTitle.Size = UDim2.new(1, -120, 0, 18)
		createTitle.Position = UDim2.new(0, 10, 0, 6)
		createTitle.BackgroundTransparency = 1
		createTitle.Text = "Studio Sequence Builder"
		createTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
		createTitle.TextSize = 10
		createTitle.Font = Enum.Font.GothamBold
		createTitle.TextXAlignment = Enum.TextXAlignment.Left

		local durLabel = Instance.new("TextLabel", createCard)
		durLabel.Size = UDim2.new(0, 110, 0, 18)
		durLabel.Position = UDim2.new(1, -115, 0, 6)
		durLabel.BackgroundTransparency = 1
		durLabel.Text = string.format("Total: %.2fs", totalDuration)
		durLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
		durLabel.TextSize = 9
		durLabel.Font = Enum.Font.GothamBold
		durLabel.TextXAlignment = Enum.TextXAlignment.Right

		-- Search Bar for finding animations
		local animSearchBox = Instance.new("TextBox", createCard)
		animSearchBox.Size = UDim2.new(1, -20, 0, 22)
		animSearchBox.Position = UDim2.new(0, 10, 0, 28)
		animSearchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		animSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		animSearchBox.PlaceholderText = "Search animations to add..."
		animSearchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
		animSearchBox.TextSize = 8
		animSearchBox.Font = Enum.Font.GothamMedium
		animSearchBox.Text = ""
		animSearchBox.ClearTextOnFocus = false
		Instance.new("UICorner", animSearchBox).CornerRadius = UDim.new(0, 4)
		addBorderStroke(animSearchBox, Color3.fromRGB(35, 35, 35))

		-- Animation Search Picker Scrolling Container
		local searchResultFrame = Instance.new("ScrollingFrame", createCard)
		searchResultFrame.Size = UDim2.new(1, -20, 0, 50)
		searchResultFrame.Position = UDim2.new(0, 10, 0, 54)
		searchResultFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
		searchResultFrame.BorderSizePixel = 0
		searchResultFrame.ScrollBarThickness = 2
		searchResultFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
		searchResultFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		Instance.new("UICorner", searchResultFrame).CornerRadius = UDim.new(0, 4)

		local searchLayout = Instance.new("UIListLayout", searchResultFrame)
		searchLayout.Padding = UDim.new(0, 2)
		searchLayout.SortOrder = Enum.SortOrder.LayoutOrder
		searchLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			searchResultFrame.CanvasSize = UDim2.new(0, 0, 0, searchLayout.AbsoluteContentSize.Y + 4)
		end)

		local function populateSearchResults(filterText)
			for _, child in ipairs(searchResultFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			filterText = (filterText or ""):lower()
			local allAnims = getAvailableAnims()
			local count = 0
			for _, animName in ipairs(allAnims) do
				if filterText == "" or animName:lower():find(filterText, 1, true) then
					count = count + 1
					if count > 30 then break end
					local btn = Instance.new("TextButton", searchResultFrame)
					btn.Size = UDim2.new(1, -4, 0, 18)
					btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
					btn.Text = "+ Add: " .. animName
					btn.TextColor3 = Color3.fromRGB(200, 200, 200)
					btn.TextSize = 8
					btn.Font = Enum.Font.GothamMedium
					btn.TextXAlignment = Enum.TextXAlignment.Left
					Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)

					btn.MouseButton1Click:Connect(function()
						local exactDur = getExactAnimationDuration(animName)
						table.insert(_G.activeSequenceClips, {
							animName = animName,
							cutStart = 0,
							cutDuration = exactDur,
							maxLen = math.max(exactDur, 5.0)
						})
						refreshCombinePanel()
					end)
				end
			end
		end

		populateSearchResults("")
		animSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			populateSearchResults(animSearchBox.Text)
		end)

		-- Active Clips Timeline list
		local clipsScroll = Instance.new("ScrollingFrame", createCard)
		clipsScroll.Size = UDim2.new(1, -20, 0, clipsScrollHeight)
		clipsScroll.Position = UDim2.new(0, 10, 0, 108)
		clipsScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
		clipsScroll.BorderSizePixel = 0
		clipsScroll.Visible = hasClips
		clipsScroll.ScrollBarThickness = 2
		clipsScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
		clipsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		Instance.new("UICorner", clipsScroll).CornerRadius = UDim.new(0, 4)

		local clipsLayout = Instance.new("UIListLayout", clipsScroll)
		clipsLayout.Padding = UDim.new(0, 4)
		clipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		clipsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			clipsScroll.CanvasSize = UDim2.new(0, 0, 0, clipsLayout.AbsoluteContentSize.Y + 6)
		end)

		for cIdx, clip in ipairs(activeClips) do
			local exactDur = getExactAnimationDuration(clip.animName)
			local maxLen = math.max(clip.maxLen or exactDur, exactDur, 1.0)
			clip.maxLen = maxLen
			local cutStart = math.clamp(tonumber(clip.cutStart) or 0, 0, maxLen - 0.05)
			local cutDur = math.clamp(tonumber(clip.cutDuration) or exactDur, 0.05, maxLen - cutStart)
			clip.cutStart = math.floor(cutStart * 100 + 0.5) / 100
			clip.cutDuration = math.floor(cutDur * 100 + 0.5) / 100

			local row = Instance.new("Frame", clipsScroll)
			row.Size = UDim2.new(1, -4, 0, 68)
			row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
			addBorderStroke(row, Color3.fromRGB(36, 36, 36))

			-- Top Row: Clip Title & Controls
			local clipTitle = Instance.new("TextLabel", row)
			clipTitle.Size = UDim2.new(0.45, 0, 0, 20)
			clipTitle.Position = UDim2.new(0, 8, 0, 6)
			clipTitle.BackgroundTransparency = 1
			clipTitle.Text = string.format("%d. %s", cIdx, clip.animName:sub(1, 16))
			clipTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
			clipTitle.TextSize = 9
			clipTitle.Font = Enum.Font.GothamBold
			clipTitle.TextXAlignment = Enum.TextXAlignment.Left

			-- Preview Clip Button
			local prevBtn = Instance.new("TextButton", row)
			prevBtn.Size = UDim2.new(0, 52, 0, 18)
			prevBtn.Position = UDim2.new(1, -120, 0, 6)
			prevBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			prevBtn.Text = "▶ Preview"
			prevBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
			prevBtn.TextSize = 7
			prevBtn.Font = Enum.Font.GothamBold
			Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 4)

			prevBtn.MouseButton1Click:Connect(function()
				task.spawn(function()
					local animCode = transformCache[clip.animName] or animationQueue[clip.animName] or characterAttachments[clip.animName] or clip.animName
					if type(animCode) == "string" and (animCode:match("^slate/") or animCode:match("%.lua$") or animCode:match("%.json$")) and type(readfile) == "function" then
						local okRead, fileData = pcall(readfile, animCode)
						if okRead and fileData and fileData ~= "" then
							animCode = fileData
						end
					end
					if onyxAPI and onyxAPI.play_animation then
						onyxAPI.play_animation(animCode)
					elseif decodedResponse then
						decodedResponse(animCode, clip.animName)
					end
					if clip.cutStart and clip.cutStart > 0 and onyx and onyx.animation and onyx.animation.state then
						onyx.animation.state.elapsed_time = clip.cutStart
					end
					task.wait(clip.cutDuration or exactDur)
					if onyxAPI and onyxAPI.is_animation_playing and onyxAPI.is_animation_playing() then
						animationModule()
					end
				end)
			end)

			-- Up / Down Order Buttons
			local upBtn = Instance.new("TextButton", row)
			upBtn.Size = UDim2.new(0, 16, 0, 18)
			upBtn.Position = UDim2.new(1, -64, 0, 6)
			upBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			upBtn.Text = "▲"
			upBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
			upBtn.TextSize = 7
			Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 3)

			upBtn.MouseButton1Click:Connect(function()
				if cIdx > 1 then
					activeClips[cIdx], activeClips[cIdx - 1] = activeClips[cIdx - 1], activeClips[cIdx]
					refreshCombinePanel()
				end
			end)

			local dnBtn = Instance.new("TextButton", row)
			dnBtn.Size = UDim2.new(0, 16, 0, 18)
			dnBtn.Position = UDim2.new(1, -44, 0, 6)
			dnBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			dnBtn.Text = "▼"
			dnBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
			dnBtn.TextSize = 7
			Instance.new("UICorner", dnBtn).CornerRadius = UDim.new(0, 3)

			dnBtn.MouseButton1Click:Connect(function()
				if cIdx < #activeClips then
					activeClips[cIdx], activeClips[cIdx + 1] = activeClips[cIdx + 1], activeClips[cIdx]
					refreshCombinePanel()
				end
			end)

			-- Delete Button using delIconId (same icon as customs tab!)
			local delBtn = Instance.new("ImageButton", row)
			delBtn.Size = UDim2.new(0, 20, 0, 18)
			delBtn.Position = UDim2.new(1, -24, 0, 6)
			delBtn.BackgroundTransparency = 1
			delBtn.Image = delIconId
			delBtn.ScaleType = Enum.ScaleType.Fit
			Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)

			local targetClipIndex = cIdx
			delBtn.MouseButton1Click:Connect(function()
				if _G.activeSequenceClips and _G.activeSequenceClips[targetClipIndex] then
					table.remove(_G.activeSequenceClips, targetClipIndex)
					refreshCombinePanel()
				end
			end)

			-- Middle Row: Cut Info Label (exact 2 decimal readout)
			local startScale = math.clamp(clip.cutStart / maxLen, 0, 0.95)
			local endScale = math.clamp((clip.cutStart + clip.cutDuration) / maxLen, startScale + 0.05, 1)

			local cutInfoLbl = Instance.new("TextLabel", row)
			cutInfoLbl.Size = UDim2.new(1, -16, 0, 14)
			cutInfoLbl.Position = UDim2.new(0, 8, 0, 28)
			cutInfoLbl.BackgroundTransparency = 1
			cutInfoLbl.Text = string.format("Cut Start: %.2fs  |  Duration: %.2fs  |  End: %.2fs", clip.cutStart, clip.cutDuration, clip.cutStart + clip.cutDuration)
			cutInfoLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
			cutInfoLbl.TextSize = 7
			cutInfoLbl.Font = Enum.Font.Gotham
			cutInfoLbl.TextXAlignment = Enum.TextXAlignment.Left

			-- Bottom Row: Two-Way Dual-Handle Timeline Range Slider
			local sliderBg = Instance.new("Frame", row)
			sliderBg.Size = UDim2.new(1, -16, 0, 6)
			sliderBg.Position = UDim2.new(0, 8, 0, 48)
			sliderBg.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
			Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 3)

			local activeFill = Instance.new("Frame", sliderBg)
			activeFill.Size = UDim2.new(endScale - startScale, 0, 1, 0)
			activeFill.Position = UDim2.new(startScale, 0, 0, 0)
			activeFill.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			Instance.new("UICorner", activeFill).CornerRadius = UDim.new(0, 3)

			local handleLeft = Instance.new("Frame", sliderBg)
			handleLeft.Size = UDim2.new(0, 10, 0, 12)
			handleLeft.Position = UDim2.new(startScale, -5, 0.5, -6)
			handleLeft.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			handleLeft.ZIndex = 3
			Instance.new("UICorner", handleLeft).CornerRadius = UDim.new(0, 3)

			local handleRight = Instance.new("Frame", sliderBg)
			handleRight.Size = UDim2.new(0, 10, 0, 12)
			handleRight.Position = UDim2.new(endScale, -5, 0.5, -6)
			handleRight.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			handleRight.ZIndex = 3
			Instance.new("UICorner", handleRight).CornerRadius = UDim.new(0, 3)

			local function updateSliderVisuals()
				startScale = math.clamp(clip.cutStart / maxLen, 0, 0.95)
				endScale = math.clamp((clip.cutStart + clip.cutDuration) / maxLen, startScale + 0.05, 1)
				activeFill.Position = UDim2.new(startScale, 0, 0, 0)
				activeFill.Size = UDim2.new(endScale - startScale, 0, 1, 0)
				handleLeft.Position = UDim2.new(startScale, -5, 0.5, -6)
				handleRight.Position = UDim2.new(endScale, -5, 0.5, -6)
				cutInfoLbl.Text = string.format("Cut Start: %.2fs  |  Duration: %.2fs  |  End: %.2fs", clip.cutStart, clip.cutDuration, clip.cutStart + clip.cutDuration)
			end

			local dragLeft, dragRight = false, false
			handleLeft.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragLeft = true
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then dragLeft = false end
					end)
				end
			end)
			handleRight.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragRight = true
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then dragRight = false end
					end)
				end
			end)

			userInputService.InputChanged:Connect(function(input)
				if (dragLeft or dragRight) and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local mouseX = input.Position.X - sliderBg.AbsolutePosition.X
					local trackWidth = sliderBg.AbsoluteSize.X
					if trackWidth > 0 then
						local scale = math.clamp(mouseX / trackWidth, 0, 1)
						if dragLeft then
							startScale = math.clamp(scale, 0, endScale - 0.05)
						elseif dragRight then
							endScale = math.clamp(scale, startScale + 0.05, 1)
						end
						clip.cutStart = math.floor(startScale * maxLen * 100 + 0.5) / 100
						clip.cutDuration = math.floor((endScale - startScale) * maxLen * 100 + 0.5) / 100
						updateSliderVisuals()
					end
				end
			end)
		end

		-- Bottom Controls: Sequence Name, Keybind, Preview Sequence, Save Button
		local bottomY = 114 + clipsScrollHeight
		createCard.Size = UDim2.new(1, 0, 0, bottomY + 68)

		local previewSeqBtn = Instance.new("TextButton", createCard)
		previewSeqBtn.Size = UDim2.new(1, -20, 0, 22)
		previewSeqBtn.Position = UDim2.new(0, 10, 0, bottomY + 6)
		previewSeqBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		previewSeqBtn.Text = "▶ Preview Full Sequence"
		previewSeqBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
		previewSeqBtn.TextSize = 8
		previewSeqBtn.Font = Enum.Font.GothamBold
		Instance.new("UICorner", previewSeqBtn).CornerRadius = UDim.new(0, 4)

		previewSeqBtn.MouseButton1Click:Connect(function()
			playCombinedSequence({ clips = activeClips })
		end)

		local seqNameBox = Instance.new("TextBox", createCard)
		seqNameBox.Size = UDim2.new(0.4, -5, 0, 22)
		seqNameBox.Position = UDim2.new(0, 10, 0, bottomY + 34)
		seqNameBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		seqNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		seqNameBox.PlaceholderText = "Sequence Name"
		seqNameBox.Text = _G.draftSeqName or ""
		seqNameBox.TextSize = 8
		seqNameBox.Font = Enum.Font.GothamMedium
		Instance.new("UICorner", seqNameBox).CornerRadius = UDim.new(0, 4)

		seqNameBox:GetPropertyChangedSignal("Text"):Connect(function()
			_G.draftSeqName = seqNameBox.Text
		end)

		local draftKey = _G.draftSeqKey
		local keyBtn = Instance.new("TextButton", createCard)
		keyBtn.Size = UDim2.new(0.2, -5, 0, 22)
		keyBtn.Position = UDim2.new(0.4, 8, 0, bottomY + 34)
		keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		keyBtn.Text = draftKey and ("Key: " .. draftKey.Name:sub(1,3)) or "Key: None"
		keyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		keyBtn.TextSize = 8
		keyBtn.Font = Enum.Font.GothamBold
		Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4)

		local listening = false
		keyBtn.MouseButton1Click:Connect(function()
			if listening then return end
			listening = true
			keyBtn.Text = "Press..."
			keyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			local conn
			conn = userInputService.InputBegan:Connect(function(input, processed)
				if processed then return end
				conn:Disconnect()
				listening = false
				keyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				if input.KeyCode == Enum.KeyCode.Escape then
					_G.draftSeqKey = nil
					keyBtn.Text = "Key: None"
				else
					_G.draftSeqKey = input.KeyCode
					keyBtn.Text = "Key: " .. input.KeyCode.Name:sub(1,3)
				end
			end)
		end)

		local saveBtn = Instance.new("TextButton", createCard)
		saveBtn.Size = UDim2.new(0.4, -10, 0, 22)
		saveBtn.Position = UDim2.new(0.6, 5, 0, bottomY + 34)
		saveBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		saveBtn.Text = "+ Save Custom Anim"
		saveBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
		saveBtn.TextSize = 8
		saveBtn.Font = Enum.Font.GothamBold
		Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)

		saveBtn.MouseButton1Click:Connect(function()
			if #activeClips == 0 then
				saveBtn.Text = "Add clips first!"
				task.delay(1, function() saveBtn.Text = "+ Save Custom Anim" end)
				return
			end
			local seqName = (_G.draftSeqName and _G.draftSeqName ~= "") and _G.draftSeqName or ("Sequence " .. (#_G.combinedSequences + 1))
			local newSeq = {
				name = seqName,
				clips = table.clone(activeClips),
				key = _G.draftSeqKey
			}
			table.insert(_G.combinedSequences, newSeq)

			-- Register sequence as a Custom Animation so it acts as a native custom anim!
			transformCache[seqName] = "combined:" .. seqName
			if animationQueue then animationQueue[seqName] = transformCache[seqName] end

			pcall(saveCombinedSequences)
			_G.activeSequenceClips = {}
			_G.draftSeqName = ""
			_G.draftSeqKey = nil
			refreshCombinePanel()
		end)

		-- 2. Saved Sequence Cards
		for idx, seq in ipairs(_G.combinedSequences) do
			local seqCard = Instance.new("Frame", combinePanelFrame)
			seqCard.Size = UDim2.new(1, 0, 0, 48)
			seqCard.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			Instance.new("UICorner", seqCard).CornerRadius = UDim.new(0, 5)
			addBorderStroke(seqCard, Color3.fromRGB(30, 30, 30))

			local seqDur = 0
			local clipCount = 0
			if seq.clips then
				clipCount = #seq.clips
				for _, c in ipairs(seq.clips) do seqDur = seqDur + (tonumber(c.cutDuration) or 2) end
			else
				clipCount = (seq.anim1 and 1 or 0) + (seq.anim2 and 1 or 0)
				seqDur = clipCount * 2
			end

			local titleLbl = Instance.new("TextLabel", seqCard)
			titleLbl.Size = UDim2.new(0.55, 0, 0, 16)
			titleLbl.Position = UDim2.new(0, 10, 0, 6)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Text = seq.name or ("Sequence " .. idx)
			titleLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
			titleLbl.TextSize = 9
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left

			local subLbl = Instance.new("TextLabel", seqCard)
			subLbl.Size = UDim2.new(0.55, 0, 0, 14)
			subLbl.Position = UDim2.new(0, 10, 0, 24)
			subLbl.BackgroundTransparency = 1
			subLbl.Text = string.format("%d clips • Total: %.1fs", clipCount, seqDur)
			subLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
			subLbl.TextSize = 8
			subLbl.Font = Enum.Font.Gotham
			subLbl.TextXAlignment = Enum.TextXAlignment.Left

			local playBtn = Instance.new("TextButton", seqCard)
			playBtn.Size = UDim2.new(0, 36, 0, 20)
			playBtn.Position = UDim2.new(1, -118, 0, 14)
			playBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			playBtn.Text = "Play"
			playBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
			playBtn.TextSize = 8
			playBtn.Font = Enum.Font.GothamBold
			playBtn.BorderSizePixel = 0
			Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 4)

			playBtn.MouseButton1Click:Connect(function()
				playCombinedSequence(seq)
			end)

			local seqKeyBtn = Instance.new("TextButton", seqCard)
			seqKeyBtn.Size = UDim2.new(0, 48, 0, 20)
			seqKeyBtn.Position = UDim2.new(1, -78, 0, 14)
			seqKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			seqKeyBtn.Text = seq.key and ("Key: " .. seq.key.Name:sub(1,3)) or "Key: None"
			seqKeyBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
			seqKeyBtn.TextSize = 8
			seqKeyBtn.Font = Enum.Font.GothamBold
			seqKeyBtn.BorderSizePixel = 0
			Instance.new("UICorner", seqKeyBtn).CornerRadius = UDim.new(0, 4)

			local seqListening = false
			seqKeyBtn.MouseButton1Click:Connect(function()
				if seqListening then return end
				if seq.key then
					seq.key = nil
					seqKeyBtn.Text = "Key: None"
					seqKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					pcall(saveCombinedSequences)
					return
				end
				seqListening = true
				seqKeyBtn.Text = "Press..."
				seqKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				local conn
				conn = userInputService.InputBegan:Connect(function(input, processed)
					if processed then return end
					conn:Disconnect()
					seqListening = false
					seqKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					if input.KeyCode == Enum.KeyCode.Escape then
						seq.key = nil
						seqKeyBtn.Text = "Key: None"
					else
						seq.key = input.KeyCode
						seqKeyBtn.Text = "Key: " .. input.KeyCode.Name:sub(1,3)
					end
					pcall(saveCombinedSequences)
				end)
			end)

			local delBtn = Instance.new("ImageButton", seqCard)
			delBtn.Size = UDim2.new(0, 20, 0, 20)
			delBtn.Position = UDim2.new(1, -26, 0, 14)
			delBtn.BackgroundTransparency = 1
			delBtn.Image = delIconId
			delBtn.ScaleType = Enum.ScaleType.Fit
			Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)

			local targetSeqIndex = idx
			delBtn.MouseButton1Click:Connect(function()
				if _G.combinedSequences and _G.combinedSequences[targetSeqIndex] then
					local removedSeq = table.remove(_G.combinedSequences, targetSeqIndex)
					if removedSeq and removedSeq.name then
						transformCache[removedSeq.name] = nil
						if animationQueue then animationQueue[removedSeq.name] = nil end
						local safeName = removedSeq.name:gsub("[^%w%s%-_$]", ""):match("^%s*(.-)%s*$")
						if safeName and safeName ~= "" and delfile then
							pcall(delfile, "slate/reanimation/" .. safeName .. ".json")
							pcall(delfile, "slate/reanimation/customs/" .. safeName .. ".lua")
						end
					end
					pcall(saveCombinedSequences)
					refreshCombinePanel()
				end
			end)
		end
	end

	refreshCombinePanel()



	-- Modal Pop-up to select animations from list

	local selectModal = Instance.new("Frame")

	selectModal.Size = UDim2.new(1, -24, 1, -170)

	selectModal.Position = UDim2.new(0, 12, 0, 158)

	selectModal.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

	selectModal.Visible = false

	selectModal.ZIndex = 20

	selectModal.Parent = mainFrame

	Instance.new("UICorner", selectModal).CornerRadius = UDim.new(0, 6)

	addBorderStroke(selectModal, Color3.fromRGB(30, 30, 30))

	local modalTitle = Instance.new("TextLabel", selectModal)

	modalTitle.Size = UDim2.new(1, -40, 0, 30)

	modalTitle.Position = UDim2.new(0, 10, 0, 5)

	modalTitle.BackgroundTransparency = 1

	modalTitle.Text = "Select Animation"

	modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)

	modalTitle.TextSize = 12

	modalTitle.Font = Enum.Font.GothamBold

	modalTitle.TextXAlignment = Enum.TextXAlignment.Left

	modalTitle.ZIndex = 21

	local modalCloseBtn = Instance.new("TextButton", selectModal)

	modalCloseBtn.Size = UDim2.new(0, 24, 0, 24)

	modalCloseBtn.Position = UDim2.new(1, -28, 0, 5)

	modalCloseBtn.BackgroundTransparency = 1

	modalCloseBtn.Text = "×"

	modalCloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)

	modalCloseBtn.TextSize = 18

	modalCloseBtn.Font = Enum.Font.GothamBold

	modalCloseBtn.ZIndex = 21

	modalCloseBtn.MouseButton1Click:Connect(function()

		selectModal.Visible = false

	end)

	local modalSearch = Instance.new("TextBox", selectModal)

	modalSearch.Size = UDim2.new(1, -20, 0, 24)

	modalSearch.Position = UDim2.new(0, 10, 0, 35)

	modalSearch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	modalSearch.TextColor3 = Color3.fromRGB(255, 255, 255)

	modalSearch.PlaceholderText = "Search animations..."

	modalSearch.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)

	modalSearch.TextSize = 10

	modalSearch.Text = ""

	modalSearch.ClearTextOnFocus = false

	modalSearch.Font = Enum.Font.GothamMedium

	modalSearch.ZIndex = 21

	Instance.new("UICorner", modalSearch).CornerRadius = UDim.new(0, 4)

	addBorderStroke(modalSearch, Color3.fromRGB(28, 28, 28))

	Instance.new("UIPadding", modalSearch).PaddingLeft = UDim.new(0, 8)

	local modalScroll = Instance.new("ScrollingFrame", selectModal)

	modalScroll.Size = UDim2.new(1, -20, 1, -70)

	modalScroll.Position = UDim2.new(0, 10, 0, 65)

	modalScroll.BackgroundTransparency = 1

	modalScroll.BorderSizePixel = 0

	modalScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	modalScroll.ScrollBarThickness = 2

	modalScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)

	modalScroll.ZIndex = 21

	local modalListLayout = Instance.new("UIListLayout", modalScroll)

	modalListLayout.Padding = UDim.new(0, 4)

	modalListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local searchConnect = nil

	local function openSelectionModal(stateName, callback)

		selectModal.Visible = true

		modalTitle.Text = "Select " .. stateName:sub(1,1):upper() .. stateName:sub(2) .. " Anim"

		modalSearch.Text = ""



		for _, child in ipairs(modalScroll:GetChildren()) do

			if child:IsA("Frame") then child:Destroy() end

		end

		local rows = {}

		-- Add "None" option row at the top

		local noneRow = Instance.new("Frame", modalScroll)

		noneRow.Size = UDim2.new(1, -6, 0, 24)

		noneRow.BackgroundColor3 = Color3.fromRGB(22, 22, 22)

		Instance.new("UICorner", noneRow).CornerRadius = UDim.new(0, 4)

		addBorderStroke(noneRow, Color3.fromRGB(32, 32, 32))

		noneRow.ZIndex = 22

		noneRow.LayoutOrder = -1

		local noneBtn = Instance.new("TextButton", noneRow)

		noneBtn.Size = UDim2.new(1, -16, 1, 0)

		noneBtn.Position = UDim2.new(0, 8, 0, 0)

		noneBtn.BackgroundTransparency = 1

		noneBtn.Text = "None (Remove)"

		noneBtn.TextColor3 = Color3.fromRGB(200, 100, 100)

		noneBtn.TextSize = 10

		noneBtn.Font = Enum.Font.GothamMedium

		noneBtn.ZIndex = 23

		noneBtn.MouseButton1Click:Connect(function()

			stateAnimations[stateName] = nil

			saveAnimationList()

			callback("None")

			selectModal.Visible = false

			if isInitialized and animationFolder then
				task.spawn(stateCheckFunction)
			end

		end)



		-- Gather unique animations

		local anims = {}

		for name, val in pairs(transformCache) do anims[name] = val end

		for name, val in pairs(animationQueue) do anims[name] = val end

		for name, val in pairs(characterAttachments) do anims[name] = val end



		local sortedNames = {}

		for name in pairs(anims) do

			table.insert(sortedNames, name)

		end

		table.sort(sortedNames)



		for _, name in ipairs(sortedNames) do

			local val = anims[name]

			local row = Instance.new("Frame", modalScroll)

			row.Size = UDim2.new(1, -6, 0, 24)

			row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)

			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

			addBorderStroke(row, Color3.fromRGB(32, 32, 32))

			row.ZIndex = 22



			local btn = Instance.new("TextButton", row)

			btn.Size = UDim2.new(1, -16, 1, 0)

			btn.Position = UDim2.new(0, 8, 0, 0)

			btn.BackgroundTransparency = 1

			btn.Text = name

			btn.TextColor3 = Color3.fromRGB(220, 220, 220)

			btn.TextSize = 10

			btn.Font = Enum.Font.GothamMedium

			btn.TextXAlignment = Enum.TextXAlignment.Left

			btn.ZIndex = 23



			btn.MouseButton1Click:Connect(function()

				stateAnimations[stateName] = name

				saveAnimationList()

				callback(name)

				selectModal.Visible = false

				if isInitialized and animationFolder then
					task.spawn(stateCheckFunction)
				end

			end)



			rows[name] = row

		end



		local function filterRows()

			local query = modalSearch.Text:lower()

			local visibleCount = 0

			for name, row in pairs(rows) do

				local visible = (query == "" or name:lower():find(query, 1, true) ~= nil)

				row.Visible = visible

				if visible then visibleCount = visibleCount + 1 end

			end

			modalScroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 28)

		end



		if searchConnect then searchConnect:Disconnect() end

		searchConnect = modalSearch:GetPropertyChangedSignal("Text"):Connect(filterRows)

		filterRows()

	end

	local function createStateRow(stateName, labelText)

		local row = Instance.new("Frame", statesPanelFrame)

		row.Size = UDim2.new(1, 0, 0, 45)

		row.BackgroundColor3 = Color3.fromRGB(18, 18, 18)

		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		addBorderStroke(row, Color3.fromRGB(30, 30, 30))

		local label = Instance.new("TextLabel", row)

		label.Size = UDim2.new(0.4, 0, 1, 0)

		label.Position = UDim2.new(0, 10, 0, 0)

		label.BackgroundTransparency = 1

		label.Text = labelText

		label.TextColor3 = Color3.fromRGB(220, 220, 220)

		label.TextSize = 11

		label.TextXAlignment = Enum.TextXAlignment.Left

		label.Font = Enum.Font.GothamBold

		local selectBtn = Instance.new("TextButton", row)

		selectBtn.Size = UDim2.new(0, 130, 0, 24)

		selectBtn.Position = UDim2.new(1, -140, 0.5, -12)

		selectBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

		selectBtn.TextColor3 = Color3.fromRGB(240, 240, 240)

		selectBtn.Text = "Click to select..."

		selectBtn.TextSize = 9

		selectBtn.Font = Enum.Font.GothamMedium

		Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 4)

		addBorderStroke(selectBtn, Color3.fromRGB(45, 45, 45))

		local function refreshText()
			local currentVal = stateAnimations[stateName] or stateAnimations[tostring(stateName):lower()]
			if currentVal and currentVal ~= "" then
				local foundName = nil

				for name, val in pairs(animationQueue) do
					if tostring(val) == tostring(currentVal) or tostring(val):gsub("%s+", "") == tostring(currentVal):gsub("%s+", "") then
						foundName = name
						break
					end
				end

				if not foundName then
					for name, val in pairs(transformCache) do
						if tostring(val) == tostring(currentVal) or tostring(val):gsub("%s+", "") == tostring(currentVal):gsub("%s+", "") then
							foundName = name
							break
						end
					end
				end

				if not foundName then
					for name, val in pairs(characterAttachments) do
						if tostring(val) == tostring(currentVal) then
							foundName = name
							break
						end
					end
				end

				selectBtn.Text = foundName or "Custom (" .. (tostring(currentVal):match("rbxassetid://(%d+)") or "Loaded") .. ")"
			else
				selectBtn.Text = "None (Click to select)"
			end
		end



		task.spawn(function()

			task.wait(0.5)

			refreshText()

		end)

		selectBtn.MouseButton1Click:Connect(function()

			openSelectionModal(stateName, function(selectedName)

				selectBtn.Text = selectedName

			end)

		end)

	end

	createStateRow("idle", "Idle State")

	createStateRow("walking", "Run/Walk State")

	createStateRow("jumping", "Jump State")

	local speedCard = Instance.new("Frame", speedsPanelFrame)

	speedCard.Size = UDim2.new(1, 0, 0, 72)

	speedCard.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	Instance.new("UICorner", speedCard).CornerRadius = UDim.new(0, 6)

	addBorderStroke(speedCard, Color3.fromRGB(30, 30, 30))

	local settingsLabel = Instance.new("TextLabel")

	settingsLabel.Size = UDim2.new(0, 45, 0, 18)

	settingsLabel.Position = UDim2.new(0, 10, 0, 6)

	settingsLabel.BackgroundTransparency = 1

	settingsLabel.Text = "Speed:"

	settingsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

	settingsLabel.TextSize = 10

	settingsLabel.Font = Enum.Font.GothamBold

	settingsLabel.TextXAlignment = Enum.TextXAlignment.Left

	settingsLabel.Parent = speedCard

	local sliderBackground = Instance.new("Frame")

	sliderBackground.Size = UDim2.new(1, -115, 0, 4)

	sliderBackground.Position = UDim2.new(0, 55, 0, 13)

	sliderBackground.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

	sliderBackground.BorderSizePixel = 0

	sliderBackground.Parent = speedCard

	Instance.new("UICorner", sliderBackground).CornerRadius = UDim.new(0, 2)

	local sliderFill = Instance.new("Frame")

	sliderFill.Size = UDim2.new(0.5, 0, 1, 0)

	sliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

	sliderFill.BorderSizePixel = 0

	sliderFill.Parent = sliderBackground

	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 2)

	local sliderHandle = Instance.new("Frame")

	sliderHandle.Size = UDim2.new(0, 10, 0, 10)

	sliderHandle.Position = UDim2.new(0.5, -5, 0.5, -5)

	sliderHandle.BackgroundColor3 = Color3.fromRGB(240, 240, 240)

	sliderHandle.BorderSizePixel = 0

	sliderHandle.Parent = sliderBackground

	Instance.new("UICorner", sliderHandle).CornerRadius = UDim.new(0, 5)

	local sliderValueLabel = Instance.new("TextLabel")

	sliderValueLabel.Size = UDim2.new(0, 20, 0, 18)

	sliderValueLabel.Position = UDim2.new(1, -55, 0, 6)

	sliderValueLabel.BackgroundTransparency = 1

	sliderValueLabel.Text = "5"

	sliderValueLabel.TextColor3 = Color3.fromRGB(240, 240, 240)

	sliderValueLabel.TextSize = 10

	sliderValueLabel.Font = Enum.Font.GothamBold

	sliderValueLabel.Parent = speedCard

	local resetButton3 = Instance.new("TextButton")

	resetButton3.Size = UDim2.new(0, 32, 0, 15)

	resetButton3.Position = UDim2.new(1, -42, 0, 8)

	resetButton3.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

	resetButton3.Text = "Reset"

	resetButton3.TextColor3 = Color3.fromRGB(220, 220, 220)

	resetButton3.TextSize = 8

	resetButton3.Font = Enum.Font.GothamBold

	resetButton3.BorderSizePixel = 0

	resetButton3.Parent = speedCard

	Instance.new("UICorner", resetButton3).CornerRadius = UDim.new(0, 4)

	addBorderStroke(resetButton3, Color3.fromRGB(40, 40, 40))

	local contentContainer = Instance.new("Frame")

	contentContainer.Size = UDim2.new(1, -20, 0, 36)

	contentContainer.Position = UDim2.new(0, 10, 0, 28)

	contentContainer.BackgroundTransparency = 1

	contentContainer.Parent = speedCard

	local reverseCard = Instance.new("Frame", speedsPanelFrame)

	reverseCard.Size = UDim2.new(1, 0, 0, 104)

	reverseCard.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	Instance.new("UICorner", reverseCard).CornerRadius = UDim.new(0, 6)

	addBorderStroke(reverseCard, Color3.fromRGB(30, 30, 30))

	local reverseLabel = Instance.new("TextLabel", reverseCard)

	reverseLabel.Size = UDim2.new(0, 110, 0, 18)

	reverseLabel.Position = UDim2.new(0, 10, 0, 6)

	reverseLabel.BackgroundTransparency = 1

	reverseLabel.Text = "Hold to Reverse"

	reverseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

	reverseLabel.TextSize = 10

	reverseLabel.Font = Enum.Font.GothamBold

	reverseLabel.TextXAlignment = Enum.TextXAlignment.Left

	local reverseKeyBtn = Instance.new("TextButton", reverseCard)

	reverseKeyBtn.Size = UDim2.new(0.24, 0, 0, 16)

	reverseKeyBtn.Position = UDim2.new(1, -84, 0, 8)

	reverseKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

	reverseKeyBtn.Text = GlobalReverseKey ~= "" and GlobalReverseKey:sub(1,3) or "Key"

	reverseKeyBtn.TextColor3 = GlobalReverseKey ~= "" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(140, 140, 140)

	reverseKeyBtn.TextSize = 8

	reverseKeyBtn.Font = Enum.Font.GothamBold

	Instance.new("UICorner", reverseKeyBtn).CornerRadius = UDim.new(0, 4)

	addBorderStroke(reverseKeyBtn, Color3.fromRGB(45, 45, 45))

	local revSliderLabel = Instance.new("TextLabel", reverseCard)

	revSliderLabel.Size = UDim2.new(0, 60, 0, 18)

	revSliderLabel.Position = UDim2.new(0, 10, 0, 26)

	revSliderLabel.BackgroundTransparency = 1

	revSliderLabel.Text = "Rev Speed:"

	revSliderLabel.TextColor3 = Color3.fromRGB(160, 160, 160)

	revSliderLabel.TextSize = 9

	revSliderLabel.Font = Enum.Font.GothamBold

	revSliderLabel.TextXAlignment = Enum.TextXAlignment.Left

	local revSliderBackground = Instance.new("Frame", reverseCard)

	revSliderBackground.Size = UDim2.new(1, -125, 0, 4)

	revSliderBackground.Position = UDim2.new(0, 75, 0, 33)

	revSliderBackground.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

	Instance.new("UICorner", revSliderBackground).CornerRadius = UDim.new(0, 2)

	local revSliderFill = Instance.new("Frame", revSliderBackground)

	revSliderFill.Size = UDim2.new(0.33, 0, 1, 0)

	revSliderFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)

	Instance.new("UICorner", revSliderFill).CornerRadius = UDim.new(0, 2)

	local revSliderHandle = Instance.new("Frame", revSliderBackground)

	revSliderHandle.Size = UDim2.new(0, 10, 0, 10)

	revSliderHandle.Position = UDim2.new(0.33, -5, 0.5, -5)

	revSliderHandle.BackgroundColor3 = Color3.fromRGB(240, 240, 240)

	Instance.new("UICorner", revSliderHandle).CornerRadius = UDim.new(0, 5)

	local revSliderValLabel = Instance.new("TextLabel", reverseCard)

	revSliderValLabel.Size = UDim2.new(0, 30, 0, 18)

	revSliderValLabel.Position = UDim2.new(1, -40, 0, 26)

	revSliderValLabel.BackgroundTransparency = 1

	revSliderValLabel.Text = "1.0x"

	revSliderValLabel.TextColor3 = Color3.fromRGB(240, 240, 240)

	revSliderValLabel.TextSize = 10

	revSliderValLabel.Font = Enum.Font.GothamBold

	local dragStartPos = mainFrame

	local dragToggle, dragStart, startPos

	local dragToggle, dragStart, startPos

	local dragToggle, dragStart, startPos

	headerFrame.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

			startPos = mainFrame.Position

			dragStart = input.Position

			dragToggle = true

			input.Changed:Connect(function()

				if input.UserInputState == Enum.UserInputState.End then

					dragToggle = false

				end

			end)

		end

	end)

	userInputService.InputChanged:Connect(function(input)

		if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then

			local delta = input.Position - dragStart

			local screenGui = mainFrame:FindFirstAncestorOfClass("ScreenGui")

			local viewport = screenGui and screenGui.AbsoluteSize or Vector2.new(1920, 1080)

			if viewport.X < 100 or viewport.Y < 100 then

				viewport = Vector2.new(1920, 1080)

			end

			local size = mainFrame.AbsoluteSize



			-- Scale-safe offset clamp to keep absolute position within screen bounds

			local minX = -startPos.X.Scale * viewport.X

			local maxX = viewport.X - size.X - startPos.X.Scale * viewport.X

			local newX = math.clamp(startPos.X.Offset + delta.X, minX, math.max(minX, maxX))



			local minY = -startPos.Y.Scale * viewport.Y

			local maxY = viewport.Y - size.Y - startPos.Y.Scale * viewport.Y

			local newY = math.clamp(startPos.Y.Offset + delta.Y, minY, math.max(minY, maxY))



			mainFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)

		end

	end)

	local onSubmitInput

	local lastSavedSize = UDim2.new(0, 300, 0, 420)

	minimizeButton.MouseButton1Click:Connect(function()

		isMenuOpen2 = not isMenuOpen2

		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local handle = mainFrame:FindFirstChild("ResizeHandle")

		if isMenuOpen2 then

			lastSavedSize = mainFrame.Size

			tweenService:Create(mainFrame, tweenInfo, { Size = UDim2.new(mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, 0, 44) }):Play()

			minimizeButton.Text = "+"

			if handle then handle.Visible = false end

			playingStatusBar.Visible = false

			scrollContainer.Visible = false

			settingsFrame.Visible = false

			searchBox.Visible = false

			settingsPanelFrame.Visible = false

			optionFrame.Visible = false

			speedsPanelFrame.Visible = false

			statesPanelFrame.Visible = false

			trackersPanelFrame.Visible = false

			combinePanelFrame.Visible = false

			selectModal.Visible = false

		else

			tweenService:Create(mainFrame, tweenInfo, { Size = lastSavedSize }):Play()

			minimizeButton.Text = "-"

			if handle then handle.Visible = true end

			playingStatusBar.Visible = true

			settingsFrame.Visible = true

			onSubmitInput()

		end

	end)

	closeButton.MouseButton1Click:Connect(function()
		screenGuiInstance.Enabled = false

		if onyxAPI and onyxAPI.reanimate then
			pcall(onyxAPI.reanimate, false)
		end

		local cam = workspace.CurrentCamera
		if cam then
			local player = get_local_player()
			local char = (typeof(player) ~= "string" and player and player.Character) or (localPlayer and localPlayer.Character)
			if char then
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if hum then
					cam.CameraSubject = hum
				else
					cam.CameraSubject = char
				end
			end
			cam.CameraType = Enum.CameraType.Custom
		end

		_G._HaloHeadTrackerEnabled = false
		_G._HaloLeftArmPointerEnabled = false
		_G._HaloRightArmPointerEnabled = false
		_G._HaloArmPointerSmoothedAim_Left = nil
		_G._HaloArmPointerSmoothedAim_Right = nil
		_G._HaloArmStretchSmoothedMult_Left = nil
		_G._HaloArmStretchSmoothedMult_Right = nil
	end)

	local activeGen = 0

	function onSubmitInput()

		optionFrame.Visible = false

		settingsPanelFrame.Visible = false

		scrollContainer.Visible = false

		searchBox.Visible = false

		speedsPanelFrame.Visible = false

		statesPanelFrame.Visible = false

		trackersPanelFrame.Visible = false

		combinePanelFrame.Visible = false

		if characterModel4 == "custom" then

			optionFrame.Visible = true

			searchBox.Position = UDim2.new(0, 12, 0, 212)

			searchBox.Visible = true

			scrollContainer.Position = UDim2.new(0, 12, 0, 244)

			scrollContainer.Size = UDim2.new(1, -24, 1, -252)

			scrollContainer.Visible = true

		elseif characterModel4 == "settings" then

			settingsPanelFrame.Visible = true

		elseif characterModel4 == "speed" then

			speedsPanelFrame.Visible = true

		elseif characterModel4 == "states" then

			statesPanelFrame.Visible = true

			selectModal.Visible = false

		elseif characterModel4 == "tracker" then

			trackersPanelFrame.Visible = true

		elseif characterModel4 == "combine" then

			combinePanelFrame.Visible = true

		else

			scrollContainer.Position = UDim2.new(0, 12, 0, 158)

			scrollContainer.Size = UDim2.new(1, -24, 1, -170)

			scrollContainer.Visible = true

			if characterModel4 == "all" or characterModel4 == "favorites" then

				searchBox.Position = UDim2.new(0, 12, 0, 120)

				searchBox.Visible = true

			end

		end

	end

	-- Auto-Import Onyx custom animations, keybinds, favorites, and states into Slate
	local function importFromOnyx(manualTrigger)
		local importedAnimsCount = 0
		local importedBindsCount = 0

		-- Ensure customs folder exists
		if not isfolder(customsFolderPath) then
			makefolder(customsFolderPath)
		end

		-- Pre-resolve the Onyx folder to prevent redundant file checks
		local resolvedFolder = nil
		local foldersToCheck = {"ReanimData", "Onyx/customs", "OnyxV2Folder/customs", "OnyxV2Folder", "Onyx"}
		for _, f in ipairs(foldersToCheck) do
			if isfolder and isfolder(f) then
				resolvedFolder = f
				break
			end
		end

		-- Helper function: read a file from ReanimData/ folder or relative path
		local function readOnyxFile(fname)
			if resolvedFolder then
				local path = resolvedFolder .. "/" .. fname
				local ok, res = pcall(readfile, path)
				if ok and type(res) == "string" and res ~= "" then
					return res
				end
			end
			local paths = {
				"ReanimData/" .. fname,
				fname,
				"OnyxV2Folder/" .. fname,
				"Onyx/" .. fname
			}
			for _, p in ipairs(paths) do
				local ok, res = pcall(readfile, p)
				if ok and type(res) == "string" and res ~= "" then
					return res
				end
			end
			return nil
		end

		-- Helper function: decode JSON safely
		local function decodeJSON(str)
			if not str or str == "" then return nil end
			local cleaned = str:gsub("^" .. string.char(239, 187, 191), ""):gsub("\r\n", "\n"):gsub("\r", "\n")
			local ok, res = pcall(function() return httpService:JSONDecode(cleaned) end)
			return ok and type(res) == "table" and res or nil
		end

		-- Batch file saving queue
		local filesToSave = {}

		-- Helper function: queue animation for saving (don't save immediately)
		local function queueAnimForSaving(name, content)
			if not name or not content or name == "" or content == "" then return false end
			local safeName = name:gsub("[^%w%s%-_$]", ""):match("^%s*(.-)%s*$")
			if safeName == "" then return false end

			filesToSave[safeName] = content
			return true
		end

		-- Helper function: save all queued files in batches
		local function saveQueuedFiles()
			local count = 0
			for name, content in pairs(filesToSave) do
				count = count + 1
				if count % 2 == 0 then
					task.wait(0.05) -- Yield every 2 file writes with shorter wait
				end
				local filePath = customsFolderPath .. "/" .. name .. ".lua"
				pcall(writefile, filePath, content)
			end
		end

		-- 1. Import Custom Animations from Onyx index / catalog files
		local customCatalogNames = {
			"onyx_custom_anims.json",
			"ReanimCustomAnims.json",
			"index.json",
			"OnyxAnimations.json",
			"CustomAnims.json",
			"custom_animations.json",
			"OnyxV2CustomAnims.json"
		}

		local batchCounter = 0
		for _, catName in ipairs(customCatalogNames) do
			local rawJson = readOnyxFile(catName)
			local data = decodeJSON(rawJson)
			if data then
				-- Handle Array Format
				for _, entry in ipairs(data) do
					batchCounter = batchCounter + 1
					if batchCounter >= 10 then
						task.wait(0.02) -- Yield every 10 items with shorter wait
						batchCounter = 0
					end
					if type(entry) == "table" then
						local animName = entry.name or entry.Name
						local animContent = entry.url or entry.file or entry.code or entry.script or entry.id or entry.Id or (entry.animData and httpService:JSONEncode(entry.animData))

						if type(animContent) == "number" or (type(animContent) == "string" and animContent:match("^%d+$")) then
							animContent = "rbxassetid://" .. tostring(animContent)
						elseif type(animContent) == "string" and (animContent:match("%.dat$") or animContent:match("%.lua$") or animContent:match("%.json$") or animContent:find("/")) then
							local fileData = readOnyxFile(animContent) or readOnyxFile((animContent:gsub("^ReanimData/", "")))
							if fileData then animContent = fileData end
						end

						if animName and animContent and animName ~= "" and type(animContent) == "string" and animContent ~= "" then
							local sanitized = animName:gsub("[^%w%s%-_$]", ""):match("^%s*(.-)%s*$")
							if sanitized ~= "" and not transformCache[sanitized] then
								-- Queue for saving (don't save yet)
								if queueAnimForSaving(sanitized, animContent) then
									transformCache[sanitized] = animContent
									importedAnimsCount = importedAnimsCount + 1
								end
							end
						end
					end
				end

				-- Handle Dictionary Format
				for key, val in pairs(data) do
					batchCounter = batchCounter + 1
					if batchCounter >= 10 then
						task.wait(0.02) -- Yield every 10 items with shorter wait
						batchCounter = 0
					end
					if type(key) == "string" and (type(val) == "string" or type(val) == "number" or type(val) == "table") then
						local animScript = type(val) == "string" and val or (type(val) == "number" and "rbxassetid://" .. tostring(val)) or (val.code or val.script or val.url or val.id or (val.animData and httpService:JSONEncode(val.animData)))
						if type(animScript) == "string" then
							if animScript:match("^%d+$") then
								animScript = "rbxassetid://" .. animScript
							elseif animScript:match("%.dat$") or animScript:match("%.lua$") or animScript:find("/") then
								local fileData = readOnyxFile(animScript) or readOnyxFile((animScript:gsub("^ReanimData/", "")))
								if fileData then animScript = fileData end
							end
							local sanitized = key:gsub("[^%w%s%-_$]", ""):match("^%s*(.-)%s*$")
							if sanitized ~= "" and not transformCache[sanitized] then
								-- Queue for saving (don't save yet)
								if queueAnimForSaving(sanitized, animScript) then
									transformCache[sanitized] = animScript
									importedAnimsCount = importedAnimsCount + 1
								end
							end
						end
					end
				end
			end
		end

		-- 2. Scan ReanimData/ folder for raw custom animation files
		local onyxFolders = {"slate/reanimation/customs", "slate/reanimation", "slate/customs", "customs", "ReanimData", "Onyx/customs", "OnyxV2Folder/customs"}
		local onyxIgnoredFiles = {
			reanimfavorites = true,
			reanimkeybinds = true,
			reanimspeedkeys = true,
			reanimstates = true,
			onlineanimationscache = true,
			index = true,
			reanimcustomanims = true,
			reanimautoimportdone = true,
			editorpreview = true,
			reanimreversekey = true,
			reanimreversespeed = true,
			reanimrevspeedkeys = true,
			reanimfortnitewheelkey = true,
			reanimmobilewheelbtn = true
		}

		batchCounter = 0
		for _, folder in ipairs(onyxFolders) do
			if isfolder and isfolder(folder) then
				local ok, files = pcall(listfiles, folder)
				if ok and type(files) == "table" then
					for _, f in ipairs(files) do
						batchCounter = batchCounter + 1
						if batchCounter >= 10 then
							task.wait(0.02) -- Yield every 10 files with shorter wait
							batchCounter = 0
						end

						local cleanF = f:gsub("\\\\", "/"):gsub("\\", "/")
						local fileBase = cleanF:match("([^/]+)$")
						if fileBase then
							local extStart = fileBase:find("%.[^%.]+$")
							local ext = extStart and fileBase:sub(extStart):lower() or ""
							local rawName = extStart and fileBase:sub(1, extStart - 1) or fileBase

							local lowerName = rawName:lower()
							if ext == ".lua" or ext == ".json" or ext == ".txt" or ext == ".dat" or ext == "" then
								if not lowerName:match("^anim_%d+$") and not onyxIgnoredFiles[lowerName] and not lowerName:match("[Ss]ettings") and not lowerName:match("[Cc]onfig") then
									local cleanName = rawName:gsub("^custom_", ""):gsub("[^%w%s%-_%$%#%@%!]", ""):match("^%s*(.-)%s*$")
									if cleanName ~= "" and not transformCache[cleanName] then
										local okRead, code = pcall(readfile, folder .. "/" .. fileBase)
										if okRead and type(code) == "string" and code ~= "" then
											-- Queue for saving (don't save yet)
											if queueAnimForSaving(cleanName, code) then
												transformCache[cleanName] = code
												importedAnimsCount = importedAnimsCount + 1
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		-- 3. Import Favorites
		local rawFavs = decodeJSON(readOnyxFile("ReanimFavorites.json")) or decodeJSON(readOnyxFile("OnyxFavorites.json"))
		if rawFavs then
			for name, isFav in pairs(rawFavs) do
				if isFav == true then
					local sanitized = tostring(name):gsub("^%[Custom%]%s*", ""):gsub("[^%w%s%-_$]", ""):match("^%s*(.-)%s*$")
					if sanitized ~= "" then
						characterAttachments[sanitized] = true
					end
				end
			end
		end

		-- 4. Import States
		local rawStates = decodeJSON(readOnyxFile("ReanimStates.json")) or decodeJSON(readOnyxFile("OnyxStates.json"))
		if rawStates then
			for stateKey, stateVal in pairs(rawStates) do
				local animCodeOrPath = type(stateVal) == "string" and stateVal or (type(stateVal) == "table" and (stateVal.url or stateVal.file or stateVal.code) or nil)
				if animCodeOrPath then
					if type(animCodeOrPath) == "string" and (animCodeOrPath:match("%.dat$") or animCodeOrPath:match("%.lua$") or animCodeOrPath:match("%.txt$") or animCodeOrPath:find("/")) then
						local fileData = readOnyxFile(animCodeOrPath) or readOnyxFile((animCodeOrPath:gsub("^ReanimData/", "")))
						if fileData then animCodeOrPath = fileData end
					end
					local sKey = tostring(stateKey):lower()
					stateAnimations[sKey] = animCodeOrPath
					if sKey == "idle" or sKey == "walking" or sKey == "jumping" or sKey == "running" or sKey == "falling" or sKey == "climbing" then
						stateAnimations[sKey] = animCodeOrPath
					end
				end
			end
			if writefile and isfolder and isfolder("slate/reanimation") then
				pcall(writefile, stateAnimationsPath, httpService:JSONEncode(stateAnimations))
			end
		end

		-- Save favorites and keybinds
		saveFavoriteAnimations()
		applyAnimationKeybinds()

		-- Now save all queued animation files in batches (this is the slow part)
		task.wait(0.1)
		saveQueuedFiles()

		-- Refresh UI
		task.wait(0.1)
		pcall(initializeGui)
		task.wait(0.1)
		if loadGUI then pcall(loadGUI) end

		return true, importedAnimsCount, importedBindsCount
	end

	-- Auto-import disabled - use the Import button in settings instead

	local function importFromAK()

		local pathsToCheck = {

			"custom_animations.json",

			"workspace/custom_animations.json",

			"ak/custom_animations.json",

			"../workspace/custom_animations.json"

		}

		local raw = nil

		for _, path in ipairs(pathsToCheck) do

			local ok, content = pcall(readfile, path)

			if ok and content and content ~= "" then

				raw = content

				break

			end

		end



		if raw then

			local cleaned = raw:gsub("^" .. string.char(239, 187, 191), ""):gsub("\r\n", "\n"):gsub("\r", "\n")

			local ok2, data = pcall(function() return httpService:JSONDecode(cleaned) end)

			if ok2 and type(data) == "table" then

				local count = 0

				for key, val in pairs(data) do

					local animName, animScript

					if type(key) == "string" and type(val) == "string" then

						animName, animScript = key, val

					end

					if animName and animScript and animName ~= "" and animScript ~= "" then

						local sanitizedName = animName:gsub("[^%w%s%-_]",""):match("^%s*(.-)%s*$")

						if sanitizedName ~= "" and not transformCache[sanitizedName] then

							transformCache[sanitizedName] = animScript

							count = count + 1

						end

					end

				end



				local kbData = {}

				local kbPaths = {

					"animation_keybinds.json",

					"workspace/animation_keybinds.json",

					"ak/animation_keybinds.json",

					"../workspace/animation_keybinds.json"

				}

				for _, path in ipairs(kbPaths) do

					local ok, content = pcall(readfile, path)

					if ok and content and content ~= "" then

						local kbCleaned = content:gsub("^" .. string.char(239, 187, 191), ""):gsub("\r\n", "\n"):gsub("\r", "\n")

						local ok3, parsedKb = pcall(function() return httpService:JSONDecode(kbCleaned) end)

						if ok3 and type(parsedKb) == "table" then

							kbData = parsedKb

							break

						end

					end

				end



				local boundCount = 0

				for name, keyName in pairs(kbData) do

					local sanitizedName = name:gsub("[^%w%s%-_]",""):match("^%s*(.-)%s*$")

					if type(keyName) == "string" then

						local kc = Enum.KeyCode[keyName]

						if kc and (transformCache[sanitizedName] or animationQueue[sanitizedName]) then

							animationBindings[sanitizedName] = kc

							boundCount = boundCount + 1

						end

					end

				end



				saveFavoriteAnimations()

				applyAnimationKeybinds()

				return true, count, boundCount

			end

		end

		return false, 0, 0

	end

	local currentNamesList = {}

	local currentListToUse = {}

	local currentRenderedCount = 0

	local currentActiveGen = 0

	local function renderRow(name, id)

		local item = Instance.new("Frame", scrollContainer)

		item.Size = UDim2.new(1, -8, 0, 32)

		item.BackgroundColor3 = Color3.fromRGB(18, 18, 18)

		Instance.new("UICorner", item).CornerRadius = UDim.new(0, 5)

		addBorderStroke(item, Color3.fromRGB(30, 30, 30))

		local playBtn = Instance.new("TextButton", item)

		playBtn.BackgroundTransparency = 1

		local displayName = name

		if displayName:sub(-4):lower() == ".lua" then displayName = displayName:sub(1, -5) end

		playBtn.Text = displayName
		playBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
		playBtn.TextSize = 11
		playBtn.TextXAlignment = Enum.TextXAlignment.Left
		playBtn.Font = Enum.Font.GothamMedium
		playBtn.TextTruncate = Enum.TextTruncate.AtEnd
		playBtn.ClipsDescendants = true

		local isFav = characterAttachments[name] ~= nil

		local favBtn = Instance.new("ImageButton", item)

		favBtn.Size = UDim2.new(0, 16, 0, 16)

		favBtn.BackgroundTransparency = 1

		favBtn.ScaleType = Enum.ScaleType.Fit

		favBtn.Image = isFav and favIconId or unfavIconId

		local actionBtn = Instance.new("ImageButton", item)

		actionBtn.Size = UDim2.new(0, 30, 0, 20)

		actionBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

		actionBtn.ScaleType = Enum.ScaleType.Fit

		Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 4)

		addBorderStroke(actionBtn, Color3.fromRGB(45, 45, 45))

		local actionText = Instance.new("TextLabel", actionBtn)

		actionText.Size = UDim2.new(1, 0, 1, 0)

		actionText.BackgroundTransparency = 1

		actionText.TextColor3 = Color3.fromRGB(255, 255, 255)

		actionText.TextSize = 8

		actionText.Font = Enum.Font.GothamBold

		actionText.Visible = false

		local function updateActionBtnDisplay()

			if animationBindings[name] then

				actionBtn.Image = ""

				actionText.Text = animationBindings[name].Name:sub(1,3)

				actionText.Visible = true

			else

				actionBtn.Image = keybindIconId

				actionText.Visible = false

			end

		end

		updateActionBtnDisplay()

		local delBtn = nil

		if characterModel4 == "custom" then

			playBtn.Position = UDim2.new(0, 12, 0, 0)

			playBtn.Size = UDim2.new(1, -97, 1, 0)

			favBtn.Position = UDim2.new(1, -85, 0.5, -8)

			actionBtn.Position = UDim2.new(1, -60, 0.5, -10)

			delBtn = Instance.new("ImageButton", item)

			delBtn.Size = UDim2.new(0, 16, 0, 16)

			delBtn.Position = UDim2.new(1, -23, 0.5, -8)

			delBtn.BackgroundTransparency = 1

			delBtn.ScaleType = Enum.ScaleType.Fit

			delBtn.Image = delIconId

else

			playBtn.Position = UDim2.new(0, 12, 0, 0)

			playBtn.Size = UDim2.new(1, -73, 1, 0)

			favBtn.Position = UDim2.new(1, -61, 0.5, -8)

			actionBtn.Position = UDim2.new(1, -38, 0.5, -10)

		end

		playBtn.MouseButton1Click:Connect(function()

			decodedResponse(tostring(id), name)

		end)

		favBtn.MouseButton1Click:Connect(function()

			if characterAttachments[name] then

				characterAttachments[name] = nil

				favBtn.Image = unfavIconId

			else

				characterAttachments[name] = tostring(id)

				favBtn.Image = favIconId

			end

			saveFavoriteAnimations()

			if characterModel4 == "favorites" then

				loadGUI()

			end

		end)

		if delBtn then

			delBtn.MouseButton1Click:Connect(function()
				transformCache[name] = nil
				animationQueue[name] = nil
				pcall(function()
					local sanitized = name:gsub("[^%w%s%-_]",""):match("^%s*(.-)%s*$")
					if delfile then
						delfile(customsFolderPath .. "/" .. sanitized .. ".lua")
						delfile(customsFolderPath .. "/" .. sanitized .. ".json")
					end
				end)
				initializeGui()
				loadGUI()
			end)

		end

		actionBtn.MouseButton1Click:Connect(function()

			if animationBindings[name] then

				animationBindings[name] = nil

				applyAnimationKeybinds()

				updateActionBtnDisplay()

			else

				actionBtn.Image = ""

				actionText.Text = "..."

				actionText.Visible = true

				isSettingBind = true

				connection = userInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Keyboard then
						if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
							connection:Disconnect()
							updateActionBtnDisplay()
							isSettingBind = false
						elseif input.KeyCode ~= Enum.KeyCode.Unknown then
							animationBindings[name] = input.KeyCode
							applyAnimationKeybinds()
							updateActionBtnDisplay()
							connection:Disconnect()
							task.defer(function()
								isSettingBind = false
							end)
						end
					end
				end)

			end

		end)

	end

	local function loadMoreItems()

		if currentRenderedCount >= #currentNamesList then return end

		local batchSize = 30

		local myGen = currentActiveGen

		local startIdx = currentRenderedCount + 1

		local endIdx = math.min(startIdx + batchSize - 1, #currentNamesList)

		currentRenderedCount = endIdx

		task.spawn(function()

			for i = startIdx, endIdx do

				if myGen ~= currentActiveGen then return end

				local name = currentNamesList[i]

				local id = currentListToUse[name]

				renderRow(name, id)

				if i % 5 == 0 then

					task.wait() -- yield every 5 items to prevent frame drops

				end

			end

		end)

	end

function loadGUI()

		currentActiveGen = currentActiveGen + 1

		local myGen = currentActiveGen

		for _, child in ipairs(scrollContainer:GetChildren()) do

			if child:IsA("Frame") then child:Destroy() end

		end

		local query = searchBox.Text:lower()

		local listToUse = {}

		if characterModel4 == "all" then

			for name, id in pairs(animationQueue) do

				if not transformCache[name] then

					listToUse[name] = id

				end

			end

		elseif characterModel4 == "favorites" then

			for name, id in pairs(characterAttachments) do

				listToUse[name] = id

			end

		elseif characterModel4 == "custom" then

			for name, id in pairs(transformCache) do

				listToUse[name] = id

			end

		elseif characterModel4 == "binds" then

			for name, key in pairs(animationBindings) do

				local id = animationQueue[name] or transformCache[name] or characterAttachments[name] or "0"

				listToUse[name] = id

			end

		end

		local sortedNames = {}

		for name in pairs(listToUse) do

			-- Use plain substring find instead of regex match to prevent search string parsing errors

			if query == "" or name:lower():find(query, 1, true) ~= nil then

				table.insert(sortedNames, name)

			end

		end

		table.sort(sortedNames)

		currentNamesList = sortedNames

		currentListToUse = listToUse

		currentRenderedCount = 0

		loadMoreItems()

	end

	local function selectCategory(catName, btn)

		characterModel4 = catName

		for _, b in ipairs({allBtn, favsBtn, customBtn, bindsBtn, speedTabBtn, statesTabBtn, trackerTabBtn, combineTabBtn, settingsBtn}) do

			if b then

				b.TextColor3 = Color3.fromRGB(140, 140, 140)

				if b:FindFirstChild("ActiveBar") then b.ActiveBar.Visible = false end

			end

		end

		if btn then

			btn.TextColor3 = Color3.fromRGB(255, 255, 255)

			if btn:FindFirstChild("ActiveBar") then btn.ActiveBar.Visible = true end

		end

		onSubmitInput()

		if selectModal then selectModal.Visible = false end

		if catName == "all" or catName == "favorites" or catName == "custom" or catName == "binds" then

			loadGUI()

		end

	end

	if allBtn then allBtn.MouseButton1Click:Connect(function() selectCategory("all", allBtn) end) end

	if favsBtn then favsBtn.MouseButton1Click:Connect(function() selectCategory("favorites", favsBtn) end) end

	if customBtn then customBtn.MouseButton1Click:Connect(function() selectCategory("custom", customBtn) end) end

	if bindsBtn then bindsBtn.MouseButton1Click:Connect(function() selectCategory("binds", bindsBtn) end) end

	if speedTabBtn then speedTabBtn.MouseButton1Click:Connect(function() selectCategory("speed", speedTabBtn) end) end

	if statesTabBtn then statesTabBtn.MouseButton1Click:Connect(function() selectCategory("states", statesTabBtn) end) end

	if trackerTabBtn then trackerTabBtn.MouseButton1Click:Connect(function() selectCategory("tracker", trackerTabBtn) end) end

	if combineTabBtn then combineTabBtn.MouseButton1Click:Connect(function() selectCategory("combine", combineTabBtn) end) end

	if settingsBtn then settingsBtn.MouseButton1Click:Connect(function() selectCategory("settings", settingsBtn) end) end

	addSubmitBtn.MouseButton1Click:Connect(function()

		local name = inputBox.Text

		local code = sliderInput.Text

		if name == "" or code == "" then

			currentlyPlayingLabel.Text = "Name and code required!"

			task.spawn(function()

				task.wait(2)

				currentlyPlayingLabel.Text = "Playing: None"

			end)

			return

		end

		local sanitizedName = name:gsub("[^%w%s%-_]",""):match("^%s*(.-)%s*$")
		if sanitizedName ~= "" then
			pcall(function()
				if writefile then
					if not isfolder(customsFolderPath) then
						makefolder(customsFolderPath)
					end
					writefile(customsFolderPath .. "/" .. sanitizedName .. ".lua", code)
				end
			end)
		end

		transformCache[name] = code

		animationQueue[name] = code

		initializeGui()

		inputBox.Text = ""

		sliderInput.Text = ""

		currentlyPlayingLabel.Text = "Saved: " .. name

		task.spawn(function()

			task.wait(2)

			currentlyPlayingLabel.Text = "Playing: None"

		end)

		if characterModel4 == "custom" then

			loadGUI()

		end

	end)

	local function updateSpeedSlider(speed)
		speed = math.clamp(speed, 0.1, 10.0)
		animationContext.speed = speed

		local fraction = math.clamp((speed - 0.1) / 3.9, 0, 1)
		sliderFill.Size = UDim2.new(fraction, 0, 1, 0)
		sliderHandle.Position = UDim2.new(fraction, -5, 0.5, -5)
		sliderValueLabel.Text = string.format("%.1fx", speed)

		pcall(onyxAPI.set_animation_speed, speed)
	end

	local sliderDragging = false

	sliderHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					sliderDragging = false
				end
			end)
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local scale = math.clamp((input.Position.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
			updateSpeedSlider(0.1 + scale * 3.9)
		end
	end)

	resetButton3.MouseButton1Click:Connect(function()
		updateSpeedSlider(1.0)
	end)

	local function updateRevSpeedSlider(speed)
		speed = math.clamp(speed, 0.1, 10.0)
		GlobalReverseSpeed = speed

		local fraction = math.clamp((speed - 0.1) / 3.9, 0, 1)
		revSliderFill.Size = UDim2.new(fraction, 0, 1, 0)
		revSliderHandle.Position = UDim2.new(fraction, -5, 0.5, -5)
		revSliderValLabel.Text = string.format("%.1fx", speed)

		saveAnimationState()
	end

	local revSliderDragging = false

	revSliderHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			revSliderDragging = true
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					revSliderDragging = false
				end
			end)
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if revSliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local scale = math.clamp((input.Position.X - revSliderBackground.AbsolutePosition.X) / revSliderBackground.AbsoluteSize.X, 0, 1)
			updateRevSpeedSlider(0.1 + scale * 3.9)
		end
	end)

	local reverseContentContainer = Instance.new("Frame")

	reverseContentContainer.Size = UDim2.new(1, -20, 0, 36)

	reverseContentContainer.Position = UDim2.new(0, 10, 0, 60)

	reverseContentContainer.BackgroundTransparency = 1

	reverseContentContainer.Parent = reverseCard

	local revSpeedLabel = Instance.new("TextLabel", reverseCard)

	revSpeedLabel.Size = UDim2.new(0, 80, 0, 14)

	revSpeedLabel.Position = UDim2.new(0, 10, 0, 46)

	revSpeedLabel.BackgroundTransparency = 1

	revSpeedLabel.Text = "Rev Speed Slots:"

	revSpeedLabel.TextColor3 = Color3.fromRGB(160, 160, 160)

	revSpeedLabel.TextSize = 8

	revSpeedLabel.Font = Enum.Font.GothamBold

	revSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

	reverseKeyBtn.MouseButton1Click:Connect(function()

		if GlobalReverseKey ~= "" then

			GlobalReverseKey = ""

			reverseKeyBtn.Text = "Key"

			reverseKeyBtn.TextColor3 = Color3.fromRGB(140, 140, 140)

			saveAnimationState()

		else

			reverseKeyBtn.Text = "..."

			local connection

			connection = userInputService.InputBegan:Connect(function(input, processed)

				if processed then return end

				if input.UserInputType == Enum.UserInputType.Keyboard then

					GlobalReverseKey = input.KeyCode.Name

					reverseKeyBtn.Text = input.KeyCode.Name:sub(1,3)

					reverseKeyBtn.TextColor3 = Color3.fromRGB(255, 100, 100)

					saveAnimationState()

					connection:Disconnect()

				end

			end)

		end

	end)

	local searchDebounce = 0

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()

		searchDebounce = searchDebounce + 1

		local currentDebounce = searchDebounce

		task.delay(0.25, function()

			if searchDebounce == currentDebounce then

				loadGUI()

			end

		end)

	end)

	local function populateSettingsTab()

		local importRow = Instance.new("Frame", settingsPanelFrame)

		importRow.Size = UDim2.new(1, 0, 0, 45)

		importRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)

		Instance.new("UICorner", importRow).CornerRadius = UDim.new(0, 6)

		addBorderStroke(importRow, Color3.fromRGB(30, 30, 30))

		local importLabel = Instance.new("TextLabel", importRow)

		importLabel.Size = UDim2.new(0.6, 0, 0.5, 0)

		importLabel.Position = UDim2.new(0, 10, 0.1, 0)

		importLabel.BackgroundTransparency = 1

		importLabel.Text = "Import Animations"

		importLabel.TextColor3 = Color3.fromRGB(220, 220, 220)

		importLabel.TextSize = 11

		importLabel.TextXAlignment = Enum.TextXAlignment.Left

		importLabel.Font = Enum.Font.GothamBold

		local importDesc = Instance.new("TextLabel", importRow)

		importDesc.Size = UDim2.new(0.6, 0, 0.4, 0)

		importDesc.Position = UDim2.new(0, 10, 0.5, 0)

		importDesc.BackgroundTransparency = 1

		importDesc.Text = "Import custom files from AK Admin config"

		importDesc.TextColor3 = Color3.fromRGB(140, 140, 140)

		importDesc.TextSize = 8

		importDesc.TextXAlignment = Enum.TextXAlignment.Left

		importDesc.Font = Enum.Font.GothamMedium

		local runImportBtn = Instance.new("TextButton", importRow)

		runImportBtn.Size = UDim2.new(0.24, 0, 0.5, 0)

		runImportBtn.Position = UDim2.new(0.72, 0, 0.25, 0)

		runImportBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

		runImportBtn.Text = "Import"

		runImportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

		runImportBtn.TextSize = 9

		runImportBtn.Font = Enum.Font.GothamBold

		Instance.new("UICorner", runImportBtn).CornerRadius = UDim.new(0, 4)

		addBorderStroke(runImportBtn, Color3.fromRGB(45, 45, 45))

		runImportBtn.MouseButton1Click:Connect(function()
			runImportBtn.Text = "Loading..."
			task.spawn(function()
				local ok, animsCount, bindsCount = importFromAK()
				if ok then
					runImportBtn.Text = "Import"
					currentlyPlayingLabel.Text = "Imported " .. animsCount .. " anims & " .. bindsCount .. " binds!"
					if loadGUI then loadGUI() end
				else
					runImportBtn.Text = "Import"
					currentlyPlayingLabel.Text = "No AK config file found to import."
				end
				task.spawn(function()
					task.wait(3)
					currentlyPlayingLabel.Text = "Playing: None"
				end)
			end)
		end)

		-- Onyx Import Row
		local importOnyxRow = Instance.new("Frame", settingsPanelFrame)
		importOnyxRow.Size = UDim2.new(1, 0, 0, 45)
		importOnyxRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		Instance.new("UICorner", importOnyxRow).CornerRadius = UDim.new(0, 6)
		addBorderStroke(importOnyxRow, Color3.fromRGB(30, 30, 30))

		local importOnyxLabel = Instance.new("TextLabel", importOnyxRow)
		importOnyxLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		importOnyxLabel.Position = UDim2.new(0, 10, 0.1, 0)
		importOnyxLabel.BackgroundTransparency = 1
		importOnyxLabel.Text = "Import Onyx Config"
		importOnyxLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		importOnyxLabel.TextSize = 11
		importOnyxLabel.TextXAlignment = Enum.TextXAlignment.Left
		importOnyxLabel.Font = Enum.Font.GothamBold

		local importOnyxDesc = Instance.new("TextLabel", importOnyxRow)
		importOnyxDesc.Size = UDim2.new(0.6, 0, 0.4, 0)
		importOnyxDesc.Position = UDim2.new(0, 10, 0.5, 0)
		importOnyxDesc.BackgroundTransparency = 1
		importOnyxDesc.Text = "Import anims, keybinds, favs & states from Onyx"
		importOnyxDesc.TextColor3 = Color3.fromRGB(140, 140, 140)
		importOnyxDesc.TextSize = 8
		importOnyxDesc.TextXAlignment = Enum.TextXAlignment.Left
		importOnyxDesc.Font = Enum.Font.GothamMedium

		local runImportOnyxBtn = Instance.new("TextButton", importOnyxRow)
		runImportOnyxBtn.Size = UDim2.new(0.24, 0, 0.5, 0)
		runImportOnyxBtn.Position = UDim2.new(0.72, 0, 0.25, 0)
		runImportOnyxBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		runImportOnyxBtn.Text = "Import"
		runImportOnyxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		runImportOnyxBtn.TextSize = 9
		runImportOnyxBtn.Font = Enum.Font.GothamBold
		Instance.new("UICorner", runImportOnyxBtn).CornerRadius = UDim.new(0, 4)
		addBorderStroke(runImportOnyxBtn, Color3.fromRGB(45, 45, 45))

		runImportOnyxBtn.MouseButton1Click:Connect(function()
			runImportOnyxBtn.Text = "Loading..."
			task.spawn(function()
				local ok, animsCount, bindsCount = importFromOnyx(true)
				if ok then
					runImportOnyxBtn.Text = "Import"
					currentlyPlayingLabel.Text = "Imported " .. animsCount .. " Onyx anims & " .. bindsCount .. " binds!"
					if loadGUI then loadGUI() end
				else
					runImportOnyxBtn.Text = "Import"
					currentlyPlayingLabel.Text = "No Onyx config files found to import."
				end
				task.spawn(function()
					task.wait(3)
					currentlyPlayingLabel.Text = "Playing: None"
				end)
			end)
		end)

		-- Smooth Transitions / Frame Gen Card
		local stRow = Instance.new("Frame", settingsPanelFrame)
		stRow.Size = UDim2.new(1, 0, 0, 45)
		stRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		Instance.new("UICorner", stRow).CornerRadius = UDim.new(0, 6)
		addBorderStroke(stRow, Color3.fromRGB(30, 30, 30))

		local stLabel = Instance.new("TextLabel", stRow)
		stLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		stLabel.Position = UDim2.new(0, 10, 0.1, 0)
		stLabel.BackgroundTransparency = 1
		stLabel.Text = "Smooth Transitions (Frame Gen)"
		stLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		stLabel.TextSize = 11
		stLabel.TextXAlignment = Enum.TextXAlignment.Left
		stLabel.Font = Enum.Font.GothamBold

		local stDesc = Instance.new("TextLabel", stRow)
		stDesc.Size = UDim2.new(0.6, 0, 0.4, 0)
		stDesc.Position = UDim2.new(0, 10, 0.5, 0)
		stDesc.BackgroundTransparency = 1
		stDesc.Text = "Smoothly crossfades and interpolates between animations"
		stDesc.TextColor3 = Color3.fromRGB(140, 140, 140)
		stDesc.TextSize = 8
		stDesc.TextXAlignment = Enum.TextXAlignment.Left
		stDesc.Font = Enum.Font.GothamMedium

		local stToggleBtn = Instance.new("TextButton", stRow)
		stToggleBtn.Size = UDim2.new(0.24, 0, 0.5, 0)
		stToggleBtn.Position = UDim2.new(0.72, 0, 0.25, 0)
		local isStOn = (_G._SlateSmoothTransitionsEnabled ~= false)
		stToggleBtn.BackgroundColor3 = isStOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
		stToggleBtn.Text = isStOn and "ON" or "OFF"
		stToggleBtn.TextColor3 = isStOn and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(160, 160, 160)
		stToggleBtn.TextSize = 9
		stToggleBtn.Font = Enum.Font.GothamBold
		Instance.new("UICorner", stToggleBtn).CornerRadius = UDim.new(0, 4)
		addBorderStroke(stToggleBtn, Color3.fromRGB(45, 45, 45))

		stToggleBtn.MouseButton1Click:Connect(function()
			isStOn = not isStOn
			stToggleBtn.BackgroundColor3 = isStOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
			stToggleBtn.Text = isStOn and "ON" or "OFF"
			stToggleBtn.TextColor3 = isStOn and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(160, 160, 160)
			_G._SlateSmoothTransitionsEnabled = isStOn
			pcall(saveSlateSettings)
		end)
	end

	populateSettingsTab()

	local eventListeners3 = {}

	for i = 1, 5 do

		local slotIndex = i

		local slotFrame = Instance.new("Frame")

		slotFrame.Size = UDim2.new(0.18, 0, 1, 0)

		slotFrame.Position = UDim2.new((slotIndex - 1) * 0.2 + 0.01, 0, 0, 0)

		slotFrame.BackgroundTransparency = 1

		slotFrame.Parent = contentContainer

		local speedInputBox = Instance.new("TextBox")

		speedInputBox.Size = UDim2.new(1, 0, 0, 16)

		speedInputBox.Position = UDim2.new(0, 0, 0, 0)

		speedInputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

		speedInputBox.Text = animationData2 and animationData2[slotIndex] and tostring(animationData2[slotIndex].speed) or tostring(slotIndex * 2 - 1)

		speedInputBox.TextColor3 = Color3.fromRGB(240, 240, 240)

		speedInputBox.ClearTextOnFocus = false

		speedInputBox.TextSize = 8

		speedInputBox.Font = Enum.Font.GothamMedium

		speedInputBox.BorderSizePixel = 0

		speedInputBox.Parent = slotFrame

		Instance.new("UICorner", speedInputBox).CornerRadius = UDim.new(0, 4)

		addBorderStroke(speedInputBox, Color3.fromRGB(45, 45, 45))

		local applySpeedButton = Instance.new("TextButton")

		applySpeedButton.Size = UDim2.new(1, 0, 0, 16)

		applySpeedButton.Position = UDim2.new(0, 0, 0, 20)

		applySpeedButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

		applySpeedButton.Text = "Key"

		applySpeedButton.TextColor3 = Color3.fromRGB(140, 140, 140)

		applySpeedButton.TextSize = 7

		applySpeedButton.Font = Enum.Font.GothamBold

		applySpeedButton.BorderSizePixel = 0

		applySpeedButton.Parent = slotFrame

		Instance.new("UICorner", applySpeedButton).CornerRadius = UDim.new(0, 4)

		addBorderStroke(applySpeedButton, Color3.fromRGB(45, 45, 45))

		eventListeners3[slotIndex] = {

			["speedInput"] = speedInputBox,

			["keybindButton"] = applySpeedButton,

			["connection"] = nil

		}

		speedInputBox.FocusLost:Connect(function()

			if not animationData2[slotIndex] then

				animationData2[slotIndex] = {

					["speed"] = slotIndex * 2 - 1,

					["key"] = ""

				}

			end

			local inputSpeedValue = tonumber(speedInputBox.Text)

			if inputSpeedValue and (0 <= inputSpeedValue and inputSpeedValue <= 10) then

				animationData2[slotIndex].speed = inputSpeedValue

				saveAnimationState()

			else

				speedInputBox.Text = tostring(animationData2[slotIndex].speed)

			end

		end)

		applySpeedButton.MouseButton1Click:Connect(function()

			if not animationData2[slotIndex] then

				animationData2[slotIndex] = {

					["speed"] = slotIndex * 2 - 1,

					["key"] = ""

				}

			end

			if animationData2[slotIndex].key == "" then

				applySpeedButton.Text = "..."

				currentlyPlayingLabel.Text = "Press key for speed slot " .. slotIndex .. "..."

				local bindConn

				bindConn = userInputService.InputBegan:Connect(function(input, processed)

					if not processed then

						if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then

							applySpeedButton.Text = "Key"

							currentlyPlayingLabel.Text = "Playing: None"

							bindConn:Disconnect()

						elseif input.KeyCode ~= Enum.KeyCode.Unknown then

							animationData2[slotIndex].key = input.KeyCode.Name

							applySpeedButton.Text = input.KeyCode.Name:sub(1, 3)

							applySpeedButton.TextColor3 = Color3.fromRGB(255, 255, 255)

							saveAnimationState()



							if eventListeners3[slotIndex].connection then

								eventListeners3[slotIndex].connection:Disconnect()

							end



							eventListeners3[slotIndex].connection = userInputService.InputBegan:Connect(function(kInput, kProcessed)
								if not kProcessed then
									if kInput.KeyCode == input.KeyCode then
										local currentSpeed = animationData2[slotIndex].speed
										updateSpeedSlider(currentSpeed)
										updateRevSpeedSlider(currentSpeed)
									end
								end
							end)



							currentlyPlayingLabel.Text = "Bound slot " .. slotIndex .. " to " .. input.KeyCode.Name

							task.spawn(function()

								task.wait(2)

								currentlyPlayingLabel.Text = "Playing: None"

							end)

							bindConn:Disconnect()

						end

					end

				end)

			else

				animationData2[slotIndex].key = ""

				applySpeedButton.Text = "Key"

				applySpeedButton.TextColor3 = Color3.fromRGB(140, 140, 140)

				saveAnimationState()

				if eventListeners3[slotIndex].connection then

					eventListeners3[slotIndex].connection:Disconnect()

					eventListeners3[slotIndex].connection = nil

				end

				currentlyPlayingLabel.Text = "Unbound slot " .. slotIndex

				task.spawn(function()

					task.wait(2)

					currentlyPlayingLabel.Text = "Playing: None"

				end)

			end

		end)

	end

	for i = 1, 5 do

		local slotIndex = i

		if animationData2[slotIndex] then

			eventListeners3[slotIndex].speedInput.Text = tostring(animationData2[slotIndex].speed)

			if animationData2[slotIndex].key and animationData2[slotIndex].key ~= "" then

				eventListeners3[slotIndex].keybindButton.Text = animationData2[slotIndex].key:sub(1, 3)

				eventListeners3[slotIndex].keybindButton.TextColor3 = Color3.fromRGB(255, 255, 255)

				local targetKey = Enum.KeyCode[animationData2[slotIndex].key]

				if targetKey then

					eventListeners3[slotIndex].connection = userInputService.InputBegan:Connect(function(input, processed)
						if not processed then
							if input.KeyCode == targetKey then
								local currentSpeed = animationData2[slotIndex].speed
								updateSpeedSlider(currentSpeed)
								updateRevSpeedSlider(currentSpeed)
							end
						end
					end)

				end

			end

		end

	end

	-- Reverse Speed Slots: 5 bindable slots that each set a negative speed

	local eventListenersRev = {}

	for i = 1, 5 do

		local slotIndex = i

		local defaultRevSpeed = -(slotIndex * 2 - 1)

		local revSlotFrame = Instance.new("Frame")

		revSlotFrame.Size = UDim2.new(0.18, 0, 1, 0)

		revSlotFrame.Position = UDim2.new((slotIndex - 1) * 0.2 + 0.01, 0, 0, 0)

		revSlotFrame.BackgroundTransparency = 1

		revSlotFrame.Parent = reverseContentContainer

		local revSpeedInput = Instance.new("TextBox")

		revSpeedInput.Size = UDim2.new(1, 0, 0, 16)

		revSpeedInput.Position = UDim2.new(0, 0, 0, 0)

		revSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

		revSpeedInput.Text = reverseSpeedSlots[slotIndex] and tostring(reverseSpeedSlots[slotIndex].speed) or tostring(defaultRevSpeed)

		revSpeedInput.TextColor3 = Color3.fromRGB(255, 100, 100)

		revSpeedInput.ClearTextOnFocus = false

		revSpeedInput.TextSize = 8

		revSpeedInput.Font = Enum.Font.GothamMedium

		revSpeedInput.BorderSizePixel = 0

		revSpeedInput.Parent = revSlotFrame

		Instance.new("UICorner", revSpeedInput).CornerRadius = UDim.new(0, 4)

		addBorderStroke(revSpeedInput, Color3.fromRGB(80, 30, 30))

		local revKeyBtn = Instance.new("TextButton")

		revKeyBtn.Size = UDim2.new(1, 0, 0, 16)

		revKeyBtn.Position = UDim2.new(0, 0, 0, 20)

		revKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

		revKeyBtn.Text = "Key"

		revKeyBtn.TextColor3 = Color3.fromRGB(140, 140, 140)

		revKeyBtn.TextSize = 7

		revKeyBtn.Font = Enum.Font.GothamBold

		revKeyBtn.BorderSizePixel = 0

		revKeyBtn.Parent = revSlotFrame

		Instance.new("UICorner", revKeyBtn).CornerRadius = UDim.new(0, 4)

		addBorderStroke(revKeyBtn, Color3.fromRGB(80, 30, 30))

		eventListenersRev[slotIndex] = {

			["speedInput"] = revSpeedInput,

			["keybindButton"] = revKeyBtn,

			["connection"] = nil

		}

		revSpeedInput.FocusLost:Connect(function()

			if not reverseSpeedSlots[slotIndex] then

				reverseSpeedSlots[slotIndex] = { ["speed"] = defaultRevSpeed, ["key"] = "" }

			end

			local v = tonumber(revSpeedInput.Text)

			if v and v ~= 0 then

				reverseSpeedSlots[slotIndex].speed = v

				saveAnimationState()

			else

				revSpeedInput.Text = tostring(reverseSpeedSlots[slotIndex].speed)

			end

		end)

		revKeyBtn.MouseButton1Click:Connect(function()

			if not reverseSpeedSlots[slotIndex] then

				reverseSpeedSlots[slotIndex] = { ["speed"] = defaultRevSpeed, ["key"] = "" }

			end

			if reverseSpeedSlots[slotIndex].key == "" then

				revKeyBtn.Text = "..."

				currentlyPlayingLabel.Text = "Press key for reverse slot " .. slotIndex .. "..."

				local bindConn

				bindConn = userInputService.InputBegan:Connect(function(input, processed)

					if not processed then

						if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then

							revKeyBtn.Text = "Key"

							currentlyPlayingLabel.Text = "Playing: None"

							bindConn:Disconnect()

						elseif input.KeyCode ~= Enum.KeyCode.Unknown then

							reverseSpeedSlots[slotIndex].key = input.KeyCode.Name

							revKeyBtn.Text = input.KeyCode.Name:sub(1, 3)

							revKeyBtn.TextColor3 = Color3.fromRGB(255, 100, 100)

							saveAnimationState()

							if eventListenersRev[slotIndex].connection then

								eventListenersRev[slotIndex].connection:Disconnect()

							end

							eventListenersRev[slotIndex].connection = userInputService.InputBegan:Connect(function(kInput, kProcessed)
								if not kProcessed then
									if kInput.KeyCode == input.KeyCode then
										local currentSpeed = math.abs(reverseSpeedSlots[slotIndex].speed)
										updateRevSpeedSlider(currentSpeed)
									end
								end
							end)

							currentlyPlayingLabel.Text = "Bound rev slot " .. slotIndex .. " to " .. input.KeyCode.Name

							task.spawn(function()

								task.wait(2)

								currentlyPlayingLabel.Text = "Playing: None"

							end)

							bindConn:Disconnect()

						end

					end

				end)

			else

				reverseSpeedSlots[slotIndex].key = ""

				revKeyBtn.Text = "Key"

				revKeyBtn.TextColor3 = Color3.fromRGB(140, 140, 140)

				saveAnimationState()

				if eventListenersRev[slotIndex].connection then

					eventListenersRev[slotIndex].connection:Disconnect()

					eventListenersRev[slotIndex].connection = nil

				end

				currentlyPlayingLabel.Text = "Unbound rev slot " .. slotIndex

				task.spawn(function()

					task.wait(2)

					currentlyPlayingLabel.Text = "Playing: None"

				end)

			end

		end)

	end

	-- Restore loaded reverse slot keybinds

	for i = 1, 5 do

		local slotIndex = i

		if reverseSpeedSlots[slotIndex] then

			eventListenersRev[slotIndex].speedInput.Text = tostring(reverseSpeedSlots[slotIndex].speed)

			if reverseSpeedSlots[slotIndex].key and reverseSpeedSlots[slotIndex].key ~= "" then

				eventListenersRev[slotIndex].keybindButton.Text = reverseSpeedSlots[slotIndex].key:sub(1, 3)

				eventListenersRev[slotIndex].keybindButton.TextColor3 = Color3.fromRGB(255, 100, 100)

				local targetRevKey = Enum.KeyCode[reverseSpeedSlots[slotIndex].key]

				if targetRevKey then

					eventListenersRev[slotIndex].connection = userInputService.InputBegan:Connect(function(input, processed)
						if not processed then
							if input.KeyCode == targetRevKey then
								local currentSpeed = math.abs(reverseSpeedSlots[slotIndex].speed)
								updateRevSpeedSlider(currentSpeed)
							end
						end
					end)
				end
			end
		end
	end

	updateSpeedSlider(1.0)
	updateRevSpeedSlider(GlobalReverseSpeed)

	-- Infinite scrolling trigger for loading more animations in the scroll list (placed here so loadMoreItems is defined)

	scrollContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(function()

		local canvasHeight = listLayout.AbsoluteContentSize.Y

		local containerHeight = scrollContainer.AbsoluteSize.Y

		local scrollPos = scrollContainer.CanvasPosition.Y

		if scrollPos >= (canvasHeight - containerHeight - 50) then

			loadMoreItems()

		end

	end)

	selectCategory("all", allBtn)

	-- Non-blocking UI update without GetObjects network freezes
	task.spawn(function()
		task.wait(0.1)
		pcall(loadGUI)
	end)

end

userInputService.InputBegan:Connect(function(mouse, camera)

	if camera or isSettingBind then

		return

	end


	-- Combined Sequence Keybind Triggers
	if _G.combinedSequences then
		for _, seq in ipairs(_G.combinedSequences) do
			if seq.key and mouse.KeyCode == seq.key then
				playCombinedSequence(seq)
				return
			end
		end
	end

	if GlobalReverseKey ~= "" and mouse.KeyCode == Enum.KeyCode[GlobalReverseKey] then

		if onyxAPI and onyxAPI.set_animation_speed then

			pcall(onyxAPI.set_animation_speed, -GlobalReverseSpeed)

		end

		return

	end

	for animPair, fallbackAnim in pairs(animationBindings) do
		if mouse.KeyCode == fallbackAnim then

			local activeAnimation = transformCache[animPair] or (animationQueue[animPair] or characterAttachments[animPair])

			-- Lazy load: if activeAnimation is a file path (string starting with "slate/"), load it now
			if activeAnimation and type(activeAnimation) == "string" then
				if activeAnimation:match("^slate/") or activeAnimation:match("^OnyxV2Folder/") then
					local readOk, fileContent = pcall(readfile, activeAnimation)
					if readOk and fileContent and fileContent ~= "" then
						activeAnimation = fileContent
						transformCache[animPair] = fileContent -- Cache the actual content
					else
						warn("[Slate] Failed to load animation file: " .. tostring(activeAnimation))
						activeAnimation = nil
					end
				end
			end

			if activeAnimation then

				decodedResponse(tostring(activeAnimation), animPair)

			end

			break

		end

	end

end)

userInputService.InputEnded:Connect(function(mouse, camera)

	if camera then

		return

	end

	if GlobalReverseKey ~= "" and mouse.KeyCode == Enum.KeyCode[GlobalReverseKey] then

		if onyxAPI and onyxAPI.set_animation_speed then

			pcall(onyxAPI.set_animation_speed, animationContext.speed)

		end

	end

end)

local loggedIds = {}

function serializeCFrame(cf)

	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()

	return string.format("CFrame.new(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)",

		x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22)

end

function getPoses(parent, list)

	list = list or {}

	for _, child in ipairs(parent:GetChildren()) do

		if child:IsA("Pose") then

			list[child.Name] = child.CFrame

			getPoses(child, list)

		end

	end

	return list

end

function serializeKFS(kfs)

	local keyframes = kfs:GetKeyframes()

	table.sort(keyframes, function(a, b) return a.Time < b.Time end)



	local lines = {}

	table.insert(lines, "return {")

	table.insert(lines, "    {")

	for _, kf in ipairs(keyframes) do

		table.insert(lines, "        {")

		table.insert(lines, string.format("            Time = %.4f,", kf.Time))

		table.insert(lines, "            Data = {")

		local poses = getPoses(kf)

		for partName, cf in pairs(poses) do

			if partName ~= "HumanoidRootPart" then

				table.insert(lines, string.format("                [\"%s\"] = %s,", partName, serializeCFrame(cf)))

			end

		end

		table.insert(lines, "            }")

		table.insert(lines, "        },")

	end

	table.insert(lines, "    }")

	table.insert(lines, "}")

	return table.concat(lines, "\n")

end

local loggerEnabled = false

local playerGui2 = localPlayer:FindFirstChildOfClass("PlayerGui") or panelHost

function createLoggerUI()

	local screen = playerGui2:FindFirstChild("SlateLoggerGui")

	if screen then screen:Destroy() end



	local loggerGui = Instance.new("ScreenGui")

	loggerGui.Name = "SlateLoggerGui"

	loggerGui.ResetOnSpawn = false

	loggerGui.Parent = playerGui2



	local frame = Instance.new("Frame", loggerGui)

	frame.Name = "MainFrame"

	frame.Size = UDim2.new(0, 280, 0, 340)

	frame.Position = UDim2.new(0.5, 160, 0.5, -170)

	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

	frame.Active = true

	frame.Draggable = true

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)



	local stroke = Instance.new("UIStroke", frame)

	stroke.Color = Color3.fromRGB(30, 30, 30)

	stroke.Thickness = 1



	local title = Instance.new("TextLabel", frame)

	title.Size = UDim2.new(0.5, 0, 0, 35)

	title.Position = UDim2.new(0, 12, 0, 0)

	title.BackgroundTransparency = 1

	title.Text = "Animation Logger"

	title.TextColor3 = Color3.fromRGB(240, 240, 240)

	title.TextSize = 12

	title.Font = Enum.Font.GothamBold

	title.TextXAlignment = Enum.TextXAlignment.Left



	local closeBtn = Instance.new("TextButton", frame)

	closeBtn.Size = UDim2.new(0, 24, 0, 24)

	closeBtn.Position = UDim2.new(1, -30, 0, 6)

	closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

	closeBtn.Text = "X"

	closeBtn.TextColor3 = Color3.fromRGB(200, 50, 50)

	closeBtn.TextSize = 10

	closeBtn.Font = Enum.Font.GothamBold

	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

	local closeStroke = Instance.new("UIStroke", closeBtn)

	closeStroke.Color = Color3.fromRGB(40, 40, 40)

	closeStroke.Thickness = 1

	closeBtn.MouseButton1Click:Connect(function()

		frame.Visible = false

	end)



	local toggleBtn = Instance.new("TextButton", frame)

	toggleBtn.Size = UDim2.new(0, 42, 0, 20)

	toggleBtn.Position = UDim2.new(1, -125, 0, 8)

	toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

	toggleBtn.Text = "OFF"

	toggleBtn.TextColor3 = Color3.fromRGB(150, 150, 150)

	toggleBtn.TextSize = 9

	toggleBtn.Font = Enum.Font.GothamBold

	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

	local toggleStroke = Instance.new("UIStroke", toggleBtn)

	toggleStroke.Color = Color3.fromRGB(40, 40, 40)



	local clearBtn = Instance.new("TextButton", frame)

	clearBtn.Size = UDim2.new(0, 42, 0, 20)

	clearBtn.Position = UDim2.new(1, -78, 0, 8)

	clearBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

	clearBtn.Text = "Clear"

	clearBtn.TextColor3 = Color3.fromRGB(200, 200, 200)

	clearBtn.TextSize = 9

	clearBtn.Font = Enum.Font.GothamBold

	Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)

	local clearStroke = Instance.new("UIStroke", clearBtn)

	clearStroke.Color = Color3.fromRGB(40, 40, 40)



	local scroll = Instance.new("ScrollingFrame", frame)

	scroll.Size = UDim2.new(1, -20, 1, -55)

	scroll.Position = UDim2.new(0, 10, 0, 45)

	scroll.BackgroundTransparency = 1

	scroll.BorderSizePixel = 0

	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	scroll.ScrollBarThickness = 2

	scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)



	local listLayout = Instance.new("UIListLayout", scroll)

	listLayout.Padding = UDim.new(0, 6)

	listLayout.SortOrder = Enum.SortOrder.LayoutOrder



	local function updateToggleDisplay()

		toggleBtn.Text = loggerEnabled and "ON" or "OFF"

		toggleBtn.BackgroundColor3 = loggerEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30)

		toggleBtn.TextColor3 = loggerEnabled and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(150, 150, 150)

	end



	toggleBtn.MouseButton1Click:Connect(function()
		loggerEnabled = not loggerEnabled
		updateToggleDisplay()
		if loggerEnabled then
			pcall(function() startLoggingAnimations() end)
		else
			pcall(function() stopLoggingAnimations() end)
		end
	end)



	local loggedRows = {}



	local function renderLoggerRow(displayName, serializedCode)

		if loggedRows[displayName] then return end



		local row = Instance.new("Frame", scroll)

		row.Size = UDim2.new(1, -6, 0, 32)

		row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

		local rowStroke = Instance.new("UIStroke", row)

		rowStroke.Color = Color3.fromRGB(30, 30, 30)



		local label = Instance.new("TextLabel", row)

		label.Size = UDim2.new(1, -65, 1, 0)

		label.Position = UDim2.new(0, 8, 0, 0)

		label.BackgroundTransparency = 1

		label.Text = displayName

		label.TextColor3 = Color3.fromRGB(220, 220, 220)

		label.TextSize = 10

		label.Font = Enum.Font.GothamMedium

		label.TextXAlignment = Enum.TextXAlignment.Left

		label.TextTruncate = Enum.TextTruncate.AtEnd



		local pBtn = Instance.new("TextButton", row)

		pBtn.Size = UDim2.new(0, 24, 0, 20)

		pBtn.Position = UDim2.new(1, -54, 0.5, -10)

		pBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

		pBtn.Text = "\u{25B6}"

		pBtn.TextColor3 = Color3.fromRGB(200, 200, 200)

		pBtn.TextSize = 9

		Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)

		local pStroke = Instance.new("UIStroke", pBtn)

		pStroke.Color = Color3.fromRGB(45, 45, 45)



		pBtn.MouseButton1Click:Connect(function()

			decodedResponse(tostring(serializedCode), displayName)

		end)



		local aBtn = Instance.new("TextButton", row)

		aBtn.Size = UDim2.new(0, 24, 0, 20)

		aBtn.Position = UDim2.new(1, -26, 0.5, -10)

		aBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

		aBtn.Text = "+"

		aBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

		aBtn.TextSize = 11

		Instance.new("UICorner", aBtn).CornerRadius = UDim.new(0, 4)

		local aStroke = Instance.new("UIStroke", aBtn)

		aStroke.Color = Color3.fromRGB(45, 45, 45)



		aBtn.MouseButton1Click:Connect(function()

			local sanitizedName = displayName:gsub("[^%w%s%-_]",""):match("^%s*(.-)%s*$")

			if transformCache[sanitizedName] or animationQueue[sanitizedName] then

				sanitizedName = sanitizedName .. "_" .. tostring(tick()):sub(-4)

			end

			transformCache[sanitizedName] = serializedCode

			pcall(function()
				if writefile then
					writefile(customsFolderPath .. "/" .. sanitizedName .. ".json", serializedCode)
				end
			end)

			initializeGui()

			if characterModel4 == "custom" then

				pcall(loadGUI)

			end

			aBtn.Text = "\u{2713}"

			aBtn.TextColor3 = Color3.fromRGB(100, 255, 100)

		end)



		loggedRows[displayName] = row

		scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)

	end



	clearBtn.MouseButton1Click:Connect(function()

		for _, row in pairs(loggedRows) do

			row:Destroy()

		end

		loggedRows = {}

		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	end)



	loggerUI = {

		Frame = frame,

		RenderRow = renderLoggerRow

	}

end

_G.toggleSlateLogger = function()

	if not loggerUI then

		createLoggerUI()

	end

	loggerUI.Frame.Visible = not loggerUI.Frame.Visible

end

function logAnimation(track, player)

	if not loggerEnabled then return end

	if not track or not track.Animation then return end

	local animId = tostring(track.Animation.AnimationId):match("%d+")

	if not animId or loggedIds[animId] then return end

	loggedIds[animId] = true



	task.spawn(function()

		local kfs = nil

		local providerOk, provider = pcall(game.GetService, game, "KeyframeSequenceProvider")

		if providerOk and provider then

			local ok, res = pcall(provider.GetKeyframeSequenceById, provider, track.Animation.AnimationId)

			if ok and res and res:IsA("KeyframeSequence") then

				kfs = res

			end

		end

		if not kfs then

			local ok, objList = pcall(game.GetObjects, game, "rbxassetid://" .. animId)

			if ok and objList and objList[1] and objList[1]:IsA("KeyframeSequence") then

				kfs = objList[1]

			end

		end

		if not kfs then return end

		local serializedCode = serializeKFS(kfs)



		local animName = (track.Animation.Name ~= "" and track.Animation.Name) or ("Logged_" .. animId)

		local sanitizedName = animName:gsub("[^%w%s%-_]",""):match("^%s*(.-)%s*$")

		if sanitizedName == "" then sanitizedName = "Logged_" .. animId end



		local displayName = player.Name .. " - " .. sanitizedName

		if loggedAnimationsList[displayName] then return end



		loggedAnimationsList[displayName] = serializedCode



		if loggerUI and loggerUI.RenderRow then

			loggerUI.RenderRow(displayName, serializedCode)

		end



		if currentPlayingAnimLabel then

			currentPlayingAnimLabel.Text = "Logged: " .. displayName

			task.spawn(function()

				task.wait(3)

				if currentPlayingAnimLabel.Text == "Logged: " .. displayName then

					currentPlayingAnimLabel.Text = "Playing: None"

				end

			end)

		end

	end)

end

local loggerConnections = {}
local playerCharConns = {}
local playerAddedConn = nil

function hookAnimator(animator, player)
	local conn = animator.AnimationPlayed:Connect(function(track)
		logAnimation(track, player)
	end)
	table.insert(loggerConnections, conn)
end

function hookCharacter(char, player)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		local animator = hum:WaitForChild("Animator", 5)
		if animator then
			hookAnimator(animator, player)
		end
	end
end

function hookPlayer(p)
	if p.Character then task.spawn(hookCharacter, p.Character, p) end
	local charConn = p.CharacterAdded:Connect(function(char)
		hookCharacter(char, p)
	end)
	playerCharConns[p] = charConn
end

task.wait()
function startLoggingAnimations()
	stopLoggingAnimations()
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
		hookPlayer(p)
	end
	playerAddedConn = game:GetService("Players").PlayerAdded:Connect(hookPlayer)
end

function stopLoggingAnimations()
	if playerAddedConn then
		pcall(function() playerAddedConn:Disconnect() end)
		playerAddedConn = nil
	end
	for p, conn in pairs(playerCharConns) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	table.clear(playerCharConns)
	for _, conn in ipairs(loggerConnections) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	table.clear(loggerConnections)
end


-- Automatic startup to load animations
task.spawn(function()
	task.spawn(function()
		playAnimation()
	end)
	task.spawn(function()
		loadAnimationState()
	end)
	task.spawn(function()
		guiUpdateFunction()
	end)
end)


	-- Expose global references
	_G.onyxAPI = onyxAPI
	if getgenv then getgenv().onyxAPI = onyxAPI end
	_G.guiUpdateFunction = guiUpdateFunction

	_G.ToggleReanimGUI = function(forcedState)
		local inst = _G.AKReanimGUIInstance
		if not inst or not inst.Parent then
			if guiUpdateFunction then
				guiUpdateFunction()
				inst = _G.AKReanimGUIInstance
			end
		end
		if inst then
			if forcedState ~= nil then
				inst.Enabled = forcedState
			else
				inst.Enabled = not inst.Enabled
			end
		end
	end

	-- Mic Up: Click-to-interact player menu support
	task.spawn(function()
		local UserInputService = game:GetService("UserInputService")
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		if _G._MicUpClickHookConn then
			pcall(function() _G._MicUpClickHookConn:Disconnect() end)
			_G._MicUpClickHookConn = nil
		end

		if _G._MicUpClickMouseConn then
			pcall(function() _G._MicUpClickMouseConn:Disconnect() end)
			_G._MicUpClickMouseConn = nil
		end

		local lastGrabClickTick = 0

		local function handlePotentialPlayerClick()
			-- Only activate if GrabStatus exists in ReplicatedStorage (specific to Mic Up)
			local grabEvent = ReplicatedStorage:FindFirstChild("GrabStatus")
			if not grabEvent then return end

			-- Check if user is clicking on Slate UI
			if _HaloIsClickingSlateUI and _HaloIsClickingSlateUI() then return end

			local now = tick()
			if now - lastGrabClickTick < 0.25 then return end

			local localPlayer = get_local_player and get_local_player() or Players.LocalPlayer
			if typeof(localPlayer) == "string" then localPlayer = Players.LocalPlayer end
			if not localPlayer then return end

			local clickedPlayer = nil

			-- Method 1: Check mouse.Target directly
			local mouse = localPlayer:GetMouse()
			if mouse and mouse.Target then
				local current = mouse.Target
				while current and current ~= workspace do
					local p = Players:GetPlayerFromCharacter(current)
					if p and p ~= localPlayer then
						clickedPlayer = p
						break
					end
					current = current.Parent
				end
			end

			-- Method 2: Raycast fallback if mouse.Target didn't resolve to another player
			if not clickedPlayer then
				local camera = workspace.CurrentCamera
				if camera then
					local mouseLocation = UserInputService:GetMouseLocation()
					local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

					local filterList = {}
					if localPlayer and localPlayer.Character then table.insert(filterList, localPlayer.Character) end
					if onyxAPI and onyxAPI.get_clone then
						local c = onyxAPI.get_clone(localPlayer)
						if c then table.insert(filterList, c) end
					end
					if onyxAPI and onyxAPI.get_real_character then
						local r = onyxAPI.get_real_character(localPlayer)
						if r then table.insert(filterList, r) end
					end

					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = filterList

					local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
					if hit and hit.Instance then
						local current = hit.Instance
						while current and current ~= workspace do
							local p = Players:GetPlayerFromCharacter(current)
							if p and p ~= localPlayer then
								clickedPlayer = p
								break
							end
							current = current.Parent
						end
					end
				end
			end

			if clickedPlayer and clickedPlayer.UserId then
				lastGrabClickTick = now
				task.spawn(function()
					pcall(function()
						local playerGui = localPlayer:FindFirstChildWhichIsA("PlayerGui")
						local clickGui = playerGui and playerGui:FindFirstChild("click_the_player")
						if not clickGui then return end

						local display = clickGui:FindFirstChildWhichIsA("ScreenGui") or clickGui:FindFirstChild("display")
						local bg = display and display:FindFirstChild("bg")
						local playerInfoVal = bg and bg:FindFirstChild("player_info")

						-- Ensure the ScreenGui container is active
						if display and display:IsA("ScreenGui") then
							display.Enabled = true
						end

						-- Reset to 0 first so Changed ALWAYS fires even if same player is re-clicked
						if playerInfoVal and playerInfoVal:IsA("NumberValue") then
							playerInfoVal.Value = 0
						end

						-- Small yield so the reset registers, then set the real target
						task.wait(0.05)

						if playerInfoVal and playerInfoVal:IsA("NumberValue") then
							playerInfoVal.Value = clickedPlayer.UserId
							if firesignal then
								pcall(function() firesignal(playerInfoVal.Changed, clickedPlayer.UserId) end)
								pcall(function() firesignal(playerInfoVal:GetPropertyChangedSignal("Value")) end)
							end
						end

						-- Give the_click script 0.2s to handle the signal naturally.
						-- If after that bg is still not showing (size ~0 or not visible),
						-- force-show it ourselves using TweenService to match what the_click would do.
						task.wait(0.2)

						if not bg then return end

						local absSize = bg.AbsoluteSize
						local needsForceShow = (not bg.Visible) or (absSize.X < 30) or (absSize.Y < 30)

						if needsForceShow then
							-- Force-show: enable, center, tween in like the_click normally would
							if display and display:IsA("ScreenGui") then
								display.Enabled = true
								display.DisplayOrder = 999
							end
							bg.Visible = true
							bg.AnchorPoint = Vector2.new(0.5, 0.5)
							bg.Position = UDim2.new(0.5, 0, 0.5, 0)

							-- Animate in via TweenService (replicates the_click's open tween)
							local tweenService = game:GetService("TweenService")
							bg.Size = UDim2.new(0, 0, 0, 0)
							local tween = tweenService:Create(bg,
								TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
								{ Size = UDim2.new(0.32, 0, 0.42, 0) }
							)
							tween:Play()

							-- Make all child GuiObjects visible
							for _, child in ipairs(bg:GetDescendants()) do
								if child:IsA("GuiObject") then
									child.Visible = true
								end
							end

							-- Update name label if present
							local nameLbl = bg:FindFirstChild("name", true)
							if nameLbl and nameLbl:IsA("TextLabel") then
								nameLbl.Text = clickedPlayer.DisplayName or clickedPlayer.Name
							end
						end
					end)

					-- Fire GrabStatus server remote
					pcall(function()
						grabEvent:InvokeServer(clickedPlayer.UserId)
					end)
				end)
			end
		end

		_G._MicUpClickHookConn = UserInputService.InputBegan:Connect(function(input, processed)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				handlePotentialPlayerClick()
			end
		end)

		local lp = get_local_player and get_local_player() or Players.LocalPlayer
		if typeof(lp) ~= "string" and lp then
			local mouse = lp:GetMouse()
			if mouse then
				_G._MicUpClickMouseConn = mouse.Button1Down:Connect(handlePotentialPlayerClick)
			end
		end
	end)

	return onyxAPI
end

local _ok, _api = pcall(runReanimEngine)
if not _ok then
	warn("[Slate Reanimate] Failed to initialize reanimation engine: " .. tostring(_api))
end

_G.onyxAPI = _api or _G.onyxAPI

print(string.format("reanim loaded in %.4fs", os.clock() - _reanimLoadStart))

return _G.onyxAPI