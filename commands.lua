if not LPS_OBFUSCATED then LPS_ATTRIBUTES = function(...) end; VM = function(...) end; OPAL = nil; NONE = nil; PRESET = function(...) end; SECURE = nil; FAST = nil; ERROR_HANDLING = function(...) end; TRANSFORM = function(...) end; CONTROL_FLOW = nil; REWRITE_NAMECALLS = nil; EXTRACT = function(...) end; GLOBALS = nil; CONSTANTS = nil; INLINE = function(...) end; UNROLL = function(...) end; OPTIMIZE = function(...) end; ENCRYPT = function(...) end; LPS_ENCSTR = function(s) return s end; LPS_ENCNUM = function(n) return n end; LPS_CRASH = function() end end
LPS_ATTRIBUTES(
    PRESET(FAST)
)

local _cmdLoadStart = os.clock()

_IY_execCmd = (function(cmdStr, speaker, store)
    if not cmdStr or type(cmdStr) ~= "string" then return end
    cmdStr = cmdStr:gsub("^[%./!;:]+", "")
    if cmdStr:find("\\") then
        for subCmd in cmdStr:gmatch("[^\\/]+") do
            _IY_execCmd(subCmd, speaker, store)
        end
        return
    end
    local parts = {}
    for w in cmdStr:gmatch("%S+") do table.insert(parts, w) end
    local cname = (parts[1] or ""):lower()
    local carg  = #parts > 1 and table.concat(parts, " ", 2) or ""

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
                    if lowerArg == "on" or lowerArg == "true" or lowerArg == "1" or lowerArg == "enable" or lowerArg == "enabled" then
                        targetState = true
                    elseif lowerArg == "off" or lowerArg == "false" or lowerArg == "0" or lowerArg == "disable" or lowerArg == "disabled" then
                        targetState = false
                    elseif cmd.getState then
                        targetState = not cmd.getState()
                    else
                        targetState = true
                    end
                    pcall(cmd.callback, targetState)
                else
                    pcall(cmd.callback, carg)
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
            pcall(actualExec, cmdStr, speaker, store)
            return
        end
    end
end)

IY.notify        = _IY_notify
IY.toClipboard   = _IY_toClipboard
IY.getRoot       = _IY_getRoot
IY.FindInTable   = _IY_FindInTable
IY.getPlayer     = _IY_getPlayer
IY.splitArgs     = _IY_splitArgs
IY.Loops         = _IY_Loops
IY.waypoints     = _IY_waypoints
IY.saveWaypoints = _IY_saveWaypoints

SlateBinds = { map = {}, file = "slate/keybinds.json" }

function SlateBinds.resolveKey(str)
	if not str or str == "" then return nil end
	str = tostring(str):gsub("%s", "")
	local ok, direct = pcall(function() return Enum.KeyCode[str] end)
	if ok and direct then return direct.Name end
	local lower = str:lower()
	for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
		if item.Name:lower() == lower then return item.Name end
	end
	return nil
end

function SlateBinds.save()
	task.spawn(function()
		pcall(function()
			if not writefile then return end
			if makefolder and isfolder and not isfolder("slate") then pcall(makefolder, "slate") end
			local ok, json = pcall(httpService.JSONEncode, httpService, SlateBinds.map)
			if ok and json then writefile(SlateBinds.file, json) end
		end)
	end)
end

function SlateBinds.load()
	pcall(function()
		if not (isfile and isfile(SlateBinds.file) and readfile) then return end
		local raw = readfile(SlateBinds.file)
		if not raw or raw == "" then return end
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
	if not key then return nil, "unknown key" end
	if not command or command:gsub("%s", "") == "" then return nil, "no command given" end
	SlateBinds.map[key] = command
	SlateBinds.save()
	SlateBinds.notifyChanged()
	return key
end

function SlateBinds.clear(keyStr)
	local key = SlateBinds.resolveKey(keyStr)
	if not key then return nil, "unknown key" end
	if not SlateBinds.map[key] then return nil, "nothing bound to " .. key end
	SlateBinds.map[key] = nil
	SlateBinds.save()
	SlateBinds.notifyChanged()
	return key
end

function SlateBinds.keyFor(commandName)
	if not commandName then return nil end
	local want = tostring(commandName):lower()
	for key, cmd in pairs(SlateBinds.map) do
		local head = tostring(cmd):match("^%s*(%S+)")
		if head and head:lower() == want then return key, cmd end
	end
	return nil
end

SlateBinds.listeners = {}
function SlateBinds.onChanged(fn)
	if fn then table.insert(SlateBinds.listeners, fn) end
end
function SlateBinds.notifyChanged()
	for _, fn in ipairs(SlateBinds.listeners) do pcall(fn) end
end

function SlateBinds.list()
	local out = {}
	for key, cmd in pairs(SlateBinds.map) do
		out[#out + 1] = { key = key, command = cmd }
	end
	table.sort(out, function(a, b) return a.key < b.key end)
	return out
end

function SlateBinds.fire(key)
	local command = SlateBinds.map[key]
	if not command then return end
	task.spawn(function()
		local head = command:match("^%s*(%S+)")
		if head and onyxCommands then
			local want = head:lower()
			for _, c in ipairs(onyxCommands) do
				local hit = (c.name and c.name:lower() == want)
				if not hit and c.aliases then
					for _, a in ipairs(c.aliases) do
						if a:lower() == want then hit = true break end
					end
				end
				if hit and c.isToggle and c.getState then
					pcall(c.callback, not c.getState())
					return
				end
				if hit then break end
			end
		end

		if execCmd then pcall(execCmd, command) end
	end)
end

SlateBinds.load()

function SlateBinds.captureKey(callback)

	if SlateBinds.cancelActive then SlateBinds.cancelActive() end

	SlateBinds.captureGen = (SlateBinds.captureGen or 0) + 1
	local myGen = SlateBinds.captureGen

	local conn
	local function finish(name, action)
		if conn then conn:Disconnect() conn = nil end
		SlateBinds.cancelActive = nil
		callback(name, action)

		task.defer(function()
			if SlateBinds.captureGen == myGen then SlateBinds.capturing = false end
		end)
	end

	SlateBinds.capturing = true
	SlateBinds.cancelActive = function() finish(nil, "cancel") end

	conn = userInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
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
	if gameProcessed then return end
	if SlateBinds.capturing then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if userInputService:GetFocusedTextBox() then return end
	SlateBinds.fire(input.KeyCode.Name)
end)

_G.SlateBindCommand   = function(key, cmd) return SlateBinds.set(key, cmd) end
_G.SlateUnbindCommand = function(key) return SlateBinds.clear(key) end
_G.SlateGetCommandBinds = function() return SlateBinds.list() end

SlateCloud = {
	busy = false,
}

function SlateCloud.baseUrl()
	local resolved = (getgenv and getgenv().SLATE_CLOUD_BASE)
		or _G.SLATE_CLOUD_BASE
		or _G.SlateBackendBase
		or "https://api.onyxv2.lol"
	return (tostring(resolved):gsub("/$", ""))
end

SlateCloud.files = {
	{ key = "keybinds",         path = "slate/keybinds.json" },
	{ key = "autoexec",         path = "slate/autoexec.json" },
	{ key = "autoexecCmds",     path = "slate/autoexec_cmds.json" },
	{ key = "favCommands",      path = "slate/fav_commands.json" },
	{ key = "emoteBinds",       path = "slate/emotes_binds.json" },
	{ key = "emoteFavs",        path = "slate/emotes_favs.json" },
	{ key = "reanimFavourites", path = "slate/reanimation/favorite_animations.json" },
	{ key = "reanimKeybinds",   path = "slate/reanimation/animation_keybinds.json" },
	{ key = "reanimSpeeds",     path = "slate/reanimation/speed_keybinds.json" },
	{ key = "reanimStates",     path = "slate/reanimation/state_animations.json" },
	{ key = "musicPlaylists",   path = "slate/music/playlists.json" },
	{ key = "musicEqualizer",   path = "slate/music/equalizer.json" },
	{ key = "waypoints",        path = "slate/iy_waypoints.json" },
	{ key = "iy",               path = "IY_FE.iy" },
}

SlateCloud.espDir = "slate/espconfigs"

SlateCloud.sections = {
	{ key = "settings",         label = "Settings" },
	{ key = "sliders",          label = "Sliders" },
	{ key = "keybinds",         label = "Command keybinds" },
	{ key = "autoexec",         label = "Auto execute" },
	{ key = "autoexecCmds",     label = "Auto execute commands" },
	{ key = "favCommands",      label = "Favourite commands" },
	{ key = "emoteBinds",       label = "Emote keybinds" },
	{ key = "emoteFavs",        label = "Favourite emotes" },
	{ key = "reanimFavourites", label = "Reanimate favourites" },
	{ key = "reanimKeybinds",   label = "Reanimate keybinds" },
	{ key = "reanimSpeeds",     label = "Reanimate speeds" },
	{ key = "reanimStates",     label = "Reanimate states" },
	{ key = "espConfigs",       label = "ESP / aimlock configs" },
	{ key = "musicPlaylists",   label = "Music playlists" },
	{ key = "musicEqualizer",   label = "Music equalizer" },
	{ key = "waypoints",        label = "Waypoints" },
	{ key = "iy",               label = "Infinite Yield data" },
}

SlateCloud.retired = {
	reanimCustoms = true,
}

function SlateCloud.sectionLabel(key)
	for _, entry in ipairs(SlateCloud.sections) do
		if entry.key == key then return entry.label end
	end
	return key
end

function SlateCloud.wants(selection, key)
	if SlateCloud.retired[key] then return false end
	if selection == nil then return true end
	return selection[key] == true
end

function SlateCloud.notify(title, body)
	pcall(queueNotification, title or "Cloud", body or "")
end

function SlateCloud.http()
	return request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
end

function SlateCloud.credentials()
	local key
	pcall(function()
		if KS and KS.loadSavedKey then key = KS.loadSavedKey() end
	end)
	if (not key or key == "") and isfile and isfile("slate/key.json") then
		pcall(function()
			local decoded = httpService:JSONDecode(readfile("slate/key.json"))
			key = decoded and decoded.Key
		end)
	end
	if not key or key == "" then return nil, "No license key found on this device." end

	local player = players.LocalPlayer
	return {
		key = key,
		userId = tostring(player.UserId),
		username = player.Name,
	}
end

function SlateCloud.request(method, path, query, body)
	local http = SlateCloud.http()
	if not http then return nil, "Your executor cannot make HTTP requests." end

	local creds, credErr = SlateCloud.credentials()
	if not creds then return nil, credErr end

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
		for k, v in pairs(body or {}) do merged[k] = v end
		local ok, encoded = pcall(httpService.JSONEncode, httpService, merged)
		if not ok then return nil, "Could not encode the request." end
		payload = encoded
	end

	local ok, res = pcall(http, {
		Url = url,
		Method = method,
		Headers = { ["Content-Type"] = "application/json" },
		Body = payload,
	})
	if not ok or not res then return nil, "Could not reach the Slate backend." end

	local decoded
	pcall(function() decoded = httpService:JSONDecode(res.Body or "") end)

	local status = res.StatusCode or res.Status or 0
	if status < 200 or status >= 300 then
		if decoded and decoded.error then return nil, decoded.error end
		if status == 413 then
			return nil, "The server rejected that request as too large. Try saving again."
		elseif status == 404 then
			return nil, "Cloud configs are not available on this backend yet."
		elseif status == 401 or status == 403 then
			return nil, "Your key was rejected. Re-enter it and try again."
		end
		return nil, "Backend returned HTTP " .. tostring(status)
	end
	if not decoded then return nil, "Backend sent a response we could not read." end
	return decoded, nil
end

function SlateCloud.readJson(path)
	if not (isfile and readfile and isfile(path)) then return nil end
	local ok, raw = pcall(readfile, path)
	if not ok or not raw or raw == "" then return nil end
	local decoded
	local decodedOk = pcall(function() decoded = httpService:JSONDecode(raw) end)
	if not decodedOk then return nil end
	return decoded
end

function SlateCloud.writeJson(path, value)
	if not writefile then return false end
	local ok, encoded = pcall(httpService.JSONEncode, httpService, value)
	if not ok then return false end
	return (pcall(writefile, path, encoded))
end

function SlateCloud.ensureFolders()
	if not (makefolder and isfolder) then return end
	for _, dir in ipairs({ "slate", "slate/music", "slate/reanimation", SlateCloud.espDir }) do
		if not isfolder(dir) then pcall(makefolder, dir) end
	end
end

function SlateCloud.collectSettings()
	local settings, sliders = {}, {}
	pcall(function()
		for _, category in ipairs(siriusSettings) do
			for _, setting in ipairs(category.categorySettings) do
				if setting.current ~= nil then settings[setting.id] = setting.current end
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
	if not (listfiles and isfolder and isfolder(SlateCloud.espDir)) then return nil end
	local out, any = {}, false
	pcall(function()
		for _, full in ipairs(listfiles(SlateCloud.espDir)) do
			local name = tostring(full):match("([^/\\]+)%.json$")
			if name then
				local decoded = SlateCloud.readJson(SlateCloud.espDir .. "/" .. name .. ".json")
				if decoded then out[name] = decoded; any = true end
			end
		end
	end)
	return any and out or nil
end

function SlateCloud.collect(selection)
	local data = { schema = 1 }

	if SlateCloud.wants(selection, "settings") or SlateCloud.wants(selection, "sliders") then
		local settings, sliders = SlateCloud.collectSettings()
		if SlateCloud.wants(selection, "settings") and next(settings) then data.settings = settings end
		if SlateCloud.wants(selection, "sliders")  and next(sliders)  then data.sliders  = sliders end
	end

	if SlateCloud.wants(selection, "keybinds") then
		pcall(function()
			if SlateBinds and next(SlateBinds.map) then
				local binds = {}
				for k, v in pairs(SlateBinds.map) do binds[k] = v end
				data.keybinds = binds
			end
		end)
	end

	for _, entry in ipairs(SlateCloud.files) do
		if entry.key ~= "keybinds" and SlateCloud.wants(selection, entry.key) then
			local value = SlateCloud.readJson(entry.path)
			if value ~= nil then data[entry.key] = value end
		end
	end

	if SlateCloud.wants(selection, "espConfigs") then
		local esp = SlateCloud.collectEspConfigs()
		if esp then data.espConfigs = esp end
	end

	return data
end

function SlateCloud.availableSections()
	local present = {}
	local settings, sliders = SlateCloud.collectSettings()
	if next(settings) then present.settings = true end
	if next(sliders)  then present.sliders  = true end
	pcall(function()
		if SlateBinds and next(SlateBinds.map) then present.keybinds = true end
	end)
	for _, entry in ipairs(SlateCloud.files) do
		if entry.key ~= "keybinds" and isfile and isfile(entry.path) then present[entry.key] = true end
	end
	if isfolder and isfolder(SlateCloud.espDir) then present.espConfigs = true end
	return present
end

function SlateCloud.apply(data, selection)
	if type(data) ~= "table" then return false, "That config is empty." end
	if not writefile then return false, "Your executor cannot write files." end
	SlateCloud.ensureFolders()

	local applied = {}

	local wantSettings = SlateCloud.wants(selection, "settings") and type(data.settings) == "table"
	local wantSliders  = SlateCloud.wants(selection, "sliders")  and type(data.sliders)  == "table"
	if wantSettings or wantSliders then
		local merged = SlateCloud.readJson("slate/settings.srs")
		if type(merged) ~= "table" then merged = {} end
		if wantSettings then for k, v in pairs(data.settings) do merged[k] = v end end
		if wantSliders  then for name, value in pairs(data.sliders) do merged["slider_" .. name] = value end end
		if SlateCloud.writeJson("slate/settings.srs", merged) then
			pcall(loadSettings)
			if wantSettings then applied[#applied + 1] = "settings" end
			if wantSliders  then applied[#applied + 1] = "sliders"  end
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
		if entry.key ~= "keybinds" and data[entry.key] ~= nil
			and SlateCloud.wants(selection, entry.key) then
			if SlateCloud.writeJson(entry.path, data[entry.key]) then
				applied[#applied + 1] = entry.key
			end
		end
	end

	if SlateCloud.wants(selection, "espConfigs") and type(data.espConfigs) == "table" then
		for name, value in pairs(data.espConfigs) do
			local safe = tostring(name):gsub("[^%w _%-]", "")
			if safe ~= "" then SlateCloud.writeJson(SlateCloud.espDir .. "/" .. safe .. ".json", value) end
		end
		applied[#applied + 1] = "espConfigs"
	end

	pcall(function() if loadAutoexecConfig then loadAutoexecConfig() end end)
	pcall(function() if _G.SlateReloadReanimConfig then _G.SlateReloadReanimConfig() end end)

	return true, applied
end

SlateCloud.chunkSize = 160 * 1024
SlateCloud.singleShotMax = 120 * 1024

function SlateCloud.progress(fn)
	SlateCloud.onProgress = fn
end

function SlateCloud.report(text)
	if SlateCloud.onProgress then pcall(SlateCloud.onProgress, text) end
end

function SlateCloud.save(name, setDefault, selection)
	local slot = tostring(name or ""):gsub("[^%w _%-%(%)%.]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if slot == "" then return nil, "Give the config a name first." end

	local data = SlateCloud.collect(selection)
	do
		local any = false
		for k in pairs(data) do
			if k ~= "schema" then any = true break end
		end
		if not any then return nil, "Pick at least one thing to save." end
	end
	local ok, encoded = pcall(httpService.JSONEncode, httpService, data)
	if not ok or not encoded then return nil, "Could not encode your settings." end

	if #encoded <= SlateCloud.singleShotMax then
		local res, err = SlateCloud.request("POST", "/api/cloud/save", nil, {
			name = slot,
			data = data,
			setDefault = setDefault and true or false,
		})
		if res then return res end
		if err and not tostring(err):find("too") then return nil, err end
	end

	local begun, beginErr = SlateCloud.request("POST", "/api/cloud/save/begin", nil, {
		name = slot,
		setDefault = setDefault and true or false,
	})
	if not begun then return nil, beginErr end

	local size = tonumber(begun.chunkSize) or SlateCloud.chunkSize
	if size > SlateCloud.chunkSize then size = SlateCloud.chunkSize end

	local total = math.max(1, math.ceil(#encoded / size))
	for i = 1, total do
		local slice = encoded:sub((i - 1) * size + 1, i * size)
		SlateCloud.report(string.format("Uploading… %d%%", math.floor((i - 1) / total * 100)))

		local sent, sendErr
		for attempt = 1, 2 do
			sent, sendErr = SlateCloud.request("POST", "/api/cloud/save/chunk", nil, {
				uploadId = begun.uploadId,
				seq = i - 1,
				chunk = slice,
			})
			if sent then break end
			if attempt == 1 then task.wait(0.35) end
		end
		if not sent then return nil, sendErr or "Upload failed part way through." end
	end

	SlateCloud.report("Finishing…")
	local done, commitErr = SlateCloud.request("POST", "/api/cloud/save/commit", nil, {
		uploadId = begun.uploadId,
		parts = total,
	})
	if not done then return nil, commitErr end
	return done
end

function SlateCloud.sectionsOf(name)
	local query = name and { name = name } or nil
	local meta = SlateCloud.request("GET", "/api/cloud/load/meta", query)
	if meta and meta.sections then return meta.sections end

	local res, err = SlateCloud.request("GET", "/api/cloud/load", query)
	if not res then return nil, err end
	local out = {}
	for key in pairs(res.data or {}) do
		if key ~= "meta" and key ~= "schema" then out[#out + 1] = { key = key } end
	end
	return out
end

function SlateCloud.list()
	local res, err = SlateCloud.request("GET", "/api/cloud/list")
	if not res then return nil, err end
	return res
end

function SlateCloud.load(name, selection)
	local query = name and { name = name } or nil

	local meta = SlateCloud.request("GET", "/api/cloud/load/meta", query)
	if meta and meta.sections then
		local wanted = {}
		for _, section in ipairs(meta.sections) do
			if SlateCloud.wants(selection, section.key) then wanted[#wanted + 1] = section end
		end
		if #wanted == 0 then return nil, "Pick at least one thing to import." end

		local data = {}
		for i, section in ipairs(wanted) do
			SlateCloud.report(string.format("Downloading… %d%%", math.floor((i - 1) / #wanted * 100)))
			local q = { section = section.key }
			if name then q.name = name end
			local got, err = SlateCloud.request("GET", "/api/cloud/load/section", q)
			if not got then return nil, err end
			data[section.key] = got.data
		end

		local ok, applied = SlateCloud.apply(data, selection)
		if not ok then return nil, applied end
		return { name = meta.name, applied = applied }
	end

	local res, err = SlateCloud.request("GET", "/api/cloud/load", query)
	if not res then return nil, err end

	local ok, applied = SlateCloud.apply(res.data, selection)
	if not ok then return nil, applied end
	return { name = res.name, applied = applied }
end

function SlateCloud.delete(name)
	local res, err = SlateCloud.request("POST", "/api/cloud/delete", nil, { name = name })
	if not res then return nil, err end
	return res
end

function SlateCloud.linkCode()
	local res, err = SlateCloud.request("POST", "/api/cloud/linkcode", nil, {})
	if not res then return nil, err end
	return res
end

SlateCloud.saveSelection = nil
SlateCloud.importSelection = nil
SlateCloud.importTarget = nil

SlateCloud.PILL_W, SlateCloud.PILL_H, SlateCloud.KNOB, SlateCloud.PILL_PAD = 32, 18, 12, 3

function SlateCloud.build()
	if SlateCloud.tab then return SlateCloud.tab end

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
	SlateCloud.setStatus = function(text) status.Text = text or "" end

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
			tweenService:Create(btn, TweenInfo.new(0.12), {
				BackgroundTransparency = primary and 0 or 0,
				BackgroundColor3 = primary and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(54, 54, 60),
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			tweenService:Create(btn, TweenInfo.new(0.12), {
				BackgroundTransparency = primary and 0 or 0.2,
				BackgroundColor3 = primary and Color3.fromRGB(238, 238, 242) or Color3.fromRGB(40, 40, 44),
			}):Play()
		end)
		return btn
	end

	local function toggleRow(parent, order, label, initial, onChange)
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
		local on  = UDim2.new(0, PILL_W - PILL_PAD - KNOB / 2, 0.5, 0)
		knob.Position = off

		local state = initial and true or false
		local function paint(animate)
			local info = TweenInfo.new(animate and 0.15 or 0)
			tweenService:Create(pill, info, {
				BackgroundColor3 = state and Color3.fromRGB(48, 48, 50) or Color3.fromRGB(28, 28, 30),
			}):Play()
			tweenService:Create(knob, info, {
				Position = state and on or off,
				BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 115),
			}):Play()
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
			if state == v then return end
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
		scroll.ScrollBarThickness = 3
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
	local saveAllBtn  = button(left, "All",  UDim2.new(1, -104, 0, 70), UDim2.new(0, 42, 0, 20))
	local saveNoneBtn = button(left, "None", UDim2.new(1, -58, 0, 70), UDim2.new(0, 48, 0, 20))

	local saveList = scrollList(left, 96, 178)
	local saveBtn = button(left, "Save to cloud", UDim2.new(0, 10, 1, -42), UDim2.new(1, -20, 0, 32), true)

	local saveSetters = {}

	local function renderSaveList()
		clear(saveList)
		saveSetters = {}

		local present = SlateCloud.availableSections()
		if SlateCloud.saveSelection == nil then
			SlateCloud.saveSelection = {}
			for key in pairs(present) do SlateCloud.saveSelection[key] = true end
		end

		local order, any = 0, false
		for _, entry in ipairs(SlateCloud.sections) do
			if present[entry.key] then
				any = true
				order = order + 1
				local key = entry.key
				saveSetters[key] = toggleRow(saveList, order, entry.label,
					SlateCloud.saveSelection[key], function(v)
						SlateCloud.saveSelection[key] = v or nil
					end)
			end
		end
		if not any then emptyRow(saveList, "Nothing on this device to save yet.") end
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
	local linkBtn    = button(right, "Link account", UDim2.new(1, -104, 0, 8), UDim2.new(0, 94, 0, 22))

	local configList = scrollList(right, 36, 116)

	local importHeading = heading(right, "WHAT TO IMPORT", 164)
	importHeading.Size = UDim2.new(1, -120, 0, 12)
	local importAllBtn  = button(right, "All",  UDim2.new(1, -104, 0, 158), UDim2.new(0, 42, 0, 20))
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
		clear(importList)
		importSetters = {}

		if not SlateCloud.importTarget then
			importHeading.Text = "WHAT TO IMPORT"
			importBtn.Text = "Import selected"
			setImportButtons(false)
			emptyRow(importList, "Click a config above to choose what to bring in.")
			return
		end

		importHeading.Text = "WHAT TO IMPORT  —  " .. string.upper(SlateCloud.importTarget)
		importBtn.Text = "Import into game"
		setImportButtons(true)
		emptyRow(importList, "Reading config…")

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
				if not SlateCloud.retired[section.key] then usable[#usable + 1] = section end
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
		name.Text = entry.isDefault and (entry.name .. "  •  default") or entry.name
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
		sub.Text = selected
			and string.format("selected  ·  %d sections", #(entry.sections or {}))
			or string.format("%d sections  ·  %.1f KB", #(entry.sections or {}), (entry.sizeBytes or 0) / 1024)
		sub.TextColor3 = selected and Color3.fromRGB(170, 170, 180) or Color3.fromRGB(124, 124, 132)
		sub.TextSize = 10
		sub.Font = Enum.Font.BuilderSans
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextTruncate = Enum.TextTruncate.AtEnd
		sub.ZIndex = 6

		row.MouseEnter:Connect(function()
			if SlateCloud.importTarget == entry.name then return end
			tweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(26, 26, 31) }):Play()
		end)
		row.MouseLeave:Connect(function()
			if SlateCloud.importTarget == entry.name then return end
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
			if SlateCloud.busy then return end
			SlateCloud.busy = true
			SlateCloud.setStatus("Deleting '" .. entry.name .. "'…")
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
		emptyRow(configList, "Loading…")
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
				for i, entry in ipairs(res.configs) do configRow(i, entry) end
			end
			linkBtn.Text = res.linked and "Account linked" or "Link account"
			SlateCloud.setStatus(string.format("%d of %d slots used.", #res.configs, res.limit or 0))
		end)
	end
	SlateCloud.renderList = renderConfigList

	saveBtn.MouseButton1Click:Connect(function()
		if SlateCloud.busy then return end
		SlateCloud.busy = true
		SlateCloud.setStatus("Saving…")
		task.spawn(function()
			SlateCloud.progress(function(text) SlateCloud.setStatus(text) end)
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
		if SlateCloud.busy then return end
		if not SlateCloud.importTarget then
			SlateCloud.setStatus("Click a config first, then pick what to import.")
			return
		end
		SlateCloud.busy = true
		SlateCloud.setStatus("Importing…")
		task.spawn(function()
			SlateCloud.progress(function(text) SlateCloud.setStatus(text) end)
			local res, err = SlateCloud.load(SlateCloud.importTarget, SlateCloud.importSelection)
			SlateCloud.progress(nil)
			SlateCloud.busy = false
			if not res then
				SlateCloud.setStatus(err)
				SlateCloud.notify("Cloud Configs", err)
				return
			end
			SlateCloud.setStatus("Imported " .. #(res.applied or {}) .. " section(s) from '" .. res.name .. "'.")
			SlateCloud.notify("Cloud Configs",
				"Imported '" .. res.name .. "'. Rejoin to reapply reanimate animations.")
		end)
	end)

	refreshBtn.MouseButton1Click:Connect(function()
		renderSaveList()
		renderConfigList()
	end)

	linkBtn.MouseButton1Click:Connect(function()
		if SlateCloud.busy then return end
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
			SlateCloud.setStatus("Code " .. res.code .. " — enter it on the dashboard within 15 minutes.")
			if setclipboard then pcall(setclipboard, res.code) end
			SlateCloud.notify("Cloud Configs",
				"Link code: " .. res.code .. "\nCopied to clipboard. Enter it at sl8ght.xyz/dash.")
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
	if SlateCloud.refreshPanes then SlateCloud.refreshPanes() end
end

SlateCloud.toggleWindow = SlateCloud.openTab
_G.SlateToggleCloudConfigs = SlateCloud.openTab

onyxCommands = {
	{
		name = "slatechat",
		aliases = {"gc", "globalchat", "chatui"},
		desc = "Open the Slate global chat",
		callback = function()
			if _G.SlateToggleChat then
				_G.SlateToggleChat()
			else
				queueNotification("Slate Chat", "Chat is still loading.")
			end
		end
	},
	{
		name = "espmenu",
		aliases = {"espgui", "esppanel", "espsettings"},
		desc = "Open the ESP menu",
		callback = function()
			SlateEspMenu.toggle()
		end
	},
	{
		name = "reanimate",
		aliases = {"reanimmenu", "reanimategui"},
		desc = "Open the Reanimate GUI",
		autoexecable = true,
		callback = function()
			if _G.ToggleReanimGUI then
				_G.ToggleReanimGUI()
			else
				local inst = _G.AKReanimGUIInstance
				local isAlive = inst and pcall(function()
					return inst.Parent ~= nil
				end) and inst.Parent ~= nil
				if isAlive then
					inst.Enabled = not inst.Enabled
				else
					if _G.guiUpdateFunction then
						_G.guiUpdateFunction()
						task.wait(0.05)
						if _G.AKReanimGUIInstance then
							_G.AKReanimGUIInstance.Enabled = true
						end
					end
				end
			end
		end
	},
	{
		name = "emotes",
		aliases = {"ugc", "animations", "emotemenu"},
		desc = "Open UGC Emotes & Animations GUI",
		callback = function()
			if _G.ToggleSlateEmoteMenu then
				_G.ToggleSlateEmoteMenu()
			end
		end
	},
	{
		name = "antivcbypass",
		aliases = {"antivc"},
		desc = "Bypasses the Roblox voice chat mute state",
		callback = function()
			pcall(execCmd, "antivcbypass")
		end
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
		end
	},
	{
		name = "hide",
		aliases = {"mutehide", "ghostplayer", "hideplayer"},
		desc = "Hide a player, mute their VC and hide their chat bubbles",
		args = "<player>",
		callback = function(arg)
			local target = GetPlayer(arg)
			if target then
				hidePlayer(target)
			else
				queueNotification("Error", "Player not found: " .. tostring(arg))
			end
		end
	},
	{
		name = "unhide",
		aliases = {"unmutehide", "unghostplayer", "unhideplayer"},
		desc = "Unhide a player, unmute their VC and restore visibility",
		args = "<player>",
		callback = function(arg)
			local target = GetPlayer(arg)
			if target then
				unhidePlayer(target)
			else
				queueNotification("Error", "Player not found: " .. tostring(arg))
			end
		end
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
		end
	},
	{
		name = "unview",
		desc = "Reset camera back to self",
		callback = function()
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				camera.CameraSubject = hum
				queueNotification("Camera Reset", "Reset view to self")
			end
		end
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
		end
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
		end
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
		end
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
			if not hrp then return end
			local savedCF = hrp.CFrame
			pcall(function()
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
				char:BreakJoints()
			end)
			localPlayer.CharacterAdded:Wait()
			task.wait(0.3)
			local newHrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if newHrp then
				newHrp.CFrame = savedCF
				queueNotification("Respawned", "Respawned at location")
			end
		end
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
					if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
					char:BreakJoints()
				end)
			end
		end
	},
	{
		name = "rejoin",
		desc = "Rejoin the current server",
		callback = function()
			rejoin()
		end
	},
	{
		name = "noclip",
		desc = "Toggle walking through walls",
		isToggle = true,
		getState = function() return _walkWallEnabled == false and _noclipConn ~= nil end,
		callback = function(state)
			if state then _startNoclip() else _stopNoclip() end
		end
	},
	{
		name = "fly",
		desc = "Toggle flying controls",
		isToggle = true,
		getState = function() return siriusValues.actions[2].enabled end,
		callback = function(state)
			siriusValues.actions[2].enabled = state
			siriusValues.actions[2].callback(state)
		end
	},
	{
		name = "baseplate",
		desc = "Toggle Infinite Baseplate (Grid / Invisible / Off)",
		autoexecable = true,
		callback = function()
			loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/onyxbaseplate.lua")))()
		end
	},
	{
		name = "shaders",
		desc = "Load and execute visual shaders",
		autoexecable = true,
		callback = function()
			loadstring(game:HttpGet(LPS_ENCSTR("https://zxt.lol/public/shaders.lua")))()
		end
	},
	{
		name = "clicktp",
		desc = "Toggle press F to teleport to cursor",
		isToggle = true,
		getState = function() return _G.ClickTeleportEnabled end,
		callback = function(state)
			_G.ClickTeleportEnabled = state
			queueNotification("Click Teleport", state and "Enabled - Press F to teleport" or "Disabled")
		end
	},
	{
		name = "tptool",
		desc = "Toggle Teleport Tool",
		isToggle = true,
		getState = function() return _G.TeleportToolEnabled end,
		callback = function(state)
			_G.TeleportToolEnabled = state
			updateTeleportToolState(state)
			queueNotification("Teleport Tool", state and "Tool added to backpack" or "Tool removed")
		end
	},
	{
		name = "walkonair",
		desc = "Toggle float in place platform",
		isToggle = true,
		getState = function() return _G.WalkOnAirEnabled == true end,
		callback = function(state)
			_G.WalkOnAirEnabled = state
			if state then
				local char = localPlayer.Character
				local hrp  = char and char:FindFirstChild("HumanoidRootPart")
				local baseY  = hrp and hrp.Position.Y or 0
				if _G.woaPlatform then pcall(function() _G.woaPlatform:Destroy() end) end
				local p = Instance.new("Part")
				p.Name         = "OnyxWOAPlatform"
				p.Size         = Vector3.new(16, 0.2, 16)
				p.Transparency = 1
				p.Anchored     = true
				p.CanCollide   = true
				p.CanQuery     = false
				p.CastShadow   = false
				p.Parent       = workspace
				_G.woaPlatform   = p
				task.spawn(function()
					while _G.WalkOnAirEnabled do
						local c = localPlayer.Character
						local h = c and c:FindFirstChild("HumanoidRootPart")
						if h then
							local targetY = baseY
							p.CFrame = CFrame.new(h.Position.X, targetY - 3.1, h.Position.Z)
							if h.Position.Y < targetY - 0.5 then
								h.CFrame = CFrame.new(h.Position.X, targetY, h.Position.Z)
									* CFrame.Angles(0, select(2, h.CFrame:ToEulerAnglesYXZ()), 0)
								h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, 0, h.AssemblyLinearVelocity.Z)
							end
						end
						task.wait()
					end
					pcall(function() p:Destroy() end)
					_G.woaPlatform = nil
				end)
				queueNotification("Walk on Air", "Enabled")
			else
				if _G.woaPlatform then
					pcall(function() _G.woaPlatform:Destroy() end)
					_G.woaPlatform = nil
				end
				queueNotification("Walk on Air", "Disabled")
			end
		end
	},
	{
		name = "walkwall",
		desc = "Stick to and walk on any wall surface",
		isToggle = true,
		getState = function() return _walkWallEnabled end,
		callback = function(state)
			_walkWallEnabled = state
			if state then _startWalkWall() else _stopWalkWall() end
			queueNotification("Walk on Wall", state and "Enabled" or "Disabled")
		end
	},
	{
		name = "zerograv",
		desc = "Toggle zero gravity",
		isToggle = true,
		getState = function() return workspace.Gravity == 0 end,
		callback = function(state)
			workspace.Gravity = state and 0 or 196.2
			queueNotification("Gravity", state and "Disabled" or "Restored")
		end
	},
	{
		name = "infzoom",
		aliases = {"infinitezoom", "infzoomout", "maxzoomout"},
		desc = "Scroll out beyond the normal zoom limit",
		isToggle = true,
		getState = function() return _infZoomEnabled end,
		callback = function(state)
			_infZoomEnabled = state
			if state then
				localPlayer.CameraMaxZoomDistance = 9e9
				localPlayer.CameraMinZoomDistance = 0.5
			else
				localPlayer.CameraMaxZoomDistance = 128
				localPlayer.CameraMinZoomDistance = 0.5
			end
			queueNotification("Infinite Zoom", state and "Enabled" or "Disabled")
		end
	},
	{
		name = "facebang",
		desc = "Open Facebang Controls panel",
		callback = function()
			FacebangWindow.Visible = not FacebangWindow.Visible
		end
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
		end
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
		end
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
		end
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
		end
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
		end
	},
	{
		name = "untarget",
		desc = "Stop all Zero Delay attachments",
		callback = function()
			StopZeroDelay()
		end
	},
	{
		name = "jerk",
		desc = "Toggle Jerk Off Tool",
		callback = function()
			_G.OnyxDoJerk()
		end
	},

	{
		name = "btools",
		desc = "Give building tools (F3X / Hopper)",
		callback = function()
			pcall(function()
				local f3x = game:GetObjects("rbxassetid://142273772")[1]
				if f3x then
					f3x.Parent = localPlayer:FindFirstChildOfClass("Backpack") or localPlayer.Character
					queueNotification("BTools", "Gave F3X Building Tools")
				else
					local tool1 = Instance.new("Tool")
					tool1.Name = "Clone"
					Instance.new("CloneTemplate", tool1)
					tool1.Parent = localPlayer:FindFirstChildOfClass("Backpack")
					local tool2 = Instance.new("Tool")
					tool2.Name = "Delete"
					Instance.new("DeleteTemplate", tool2)
					tool2.Parent = localPlayer:FindFirstChildOfClass("Backpack")
					local tool3 = Instance.new("Tool")
					tool3.Name = "Grab"
					Instance.new("GrabTemplate", tool3)
					tool3.Parent = localPlayer:FindFirstChildOfClass("Backpack")
					queueNotification("BTools", "Gave Classic Hopper Tools")
				end
			end)
		end
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
				queueNotification("Fly Speed", "Flying speed set to " .. speed)
			end
		end
	},
	{
		name = "infjump",
		desc = "Toggle jumping in mid-air",
		isToggle = true,
		getState = function() return _infJumpConn ~= nil end,
		callback = function(state)
			if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn = nil end
			if state then
				_infJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
					local char = localPlayer.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum:ChangeState(Enum.HumanoidStateType.Jumping)
					end
				end)
				queueNotification("Infinite Jump", "Enabled")
			else
				queueNotification("Infinite Jump", "Disabled")
			end
		end
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
		end
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
		end
	},
	{
		name = "god",
		desc = "Toggle local character invulnerability",
		isToggle = true,
		getState = function() return _G.OnyxGodModeEnabled == true end,
		callback = function(state)
			_G.OnyxGodModeEnabled = state
			if state then
				task.spawn(function()
					while _G.OnyxGodModeEnabled do
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
		end
	},

	{
		name = "float",
		desc = "Create a floating platform under you",
		aliases = {'platform'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			Floating = true
			local pchar = _IY_lp.Character
			if pchar and not pchar:FindFirstChild(floatName) then
				task.spawn(function()
					local root = _IY_getRoot(pchar)
					if not root then return end
					local Float = Instance.new('Part')
					Float.Name = floatName
					Float.Parent = pchar
					Float.Transparency = 1
					Float.Size = Vector3.new(4, 0.5, 4)
					Float.Anchored = true
					local fixedElevation = root.Position.Y - 3.1
					local isHoldingQ = false
					local isHoldingE = false
					local floatSpeed = 24.0

					Float.CFrame = CFrame.new(root.Position.X, fixedElevation, root.Position.Z)
					_IY_notify('Float','Float Enabled (Hold E = Up, Hold Q = Down)')

					qDown = _IY_UIS.InputBegan:Connect(function(input, gp)
						if not gp then
							if input.KeyCode == Enum.KeyCode.Q then isHoldingQ = true end
							if input.KeyCode == Enum.KeyCode.E then isHoldingE = true end
						end
					end)
					qUp = _IY_UIS.InputEnded:Connect(function(input, gp)
						if input.KeyCode == Enum.KeyCode.Q then isHoldingQ = false end
						if input.KeyCode == Enum.KeyCode.E then isHoldingE = false end
					end)

					floatDied = _IY_lp.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
						if FloatingFunc then FloatingFunc:Disconnect() end
						if Float and Float.Parent then Float:Destroy() end
						if qDown then qDown:Disconnect() end
						if qUp then qUp:Disconnect() end
						if floatDied then floatDied:Disconnect() end
					end)
					local FloatPadLoop = (function(dt)
						local delta = dt or 0.016
						if isHoldingE and not isHoldingQ then
							fixedElevation = fixedElevation + (floatSpeed * delta)
						elseif isHoldingQ and not isHoldingE then
							fixedElevation = fixedElevation - (floatSpeed * delta)
						end

						local r = _IY_getRoot(pchar)
						if pchar:FindFirstChild(floatName) and r then
							Float.CFrame = CFrame.new(r.Position.X, fixedElevation, r.Position.Z)
						else
							if FloatingFunc then FloatingFunc:Disconnect() end
							if Float and Float.Parent then Float:Destroy() end
							if qDown then qDown:Disconnect() end
							if qUp then qUp:Disconnect() end
							if floatDied then floatDied:Disconnect() end
						end
					end)
					FloatingFunc = _IY_RunService.Heartbeat:Connect(FloatPadLoop)
				end)
			end
		end
	},
	{
		name = "unfloat",
		desc = "Remove the float platform",
		aliases = {'nofloat', 'unplatform', 'noplatform'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			Floating = false
			local pchar = _IY_lp.Character
			_IY_notify('Float','Float Disabled')
			if pchar:FindFirstChild(floatName) then
				pchar:FindFirstChild(floatName):Destroy()
			end
			if floatDied then
				FloatingFunc:Disconnect()
				qUp:Disconnect()
				eUp:Disconnect()
				qDown:Disconnect()
				eDown:Disconnect()
				floatDied:Disconnect()
			end
		end
	},
	{
		name = "togglefloat",
		desc = "Toggle float platform",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if Floating then
				execCmd('unfloat')
			else
				execCmd('float')
			end
		end
	},
	{
		name = "swim",
		desc = "Enable swim physics anywhere",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if not swimming and _IY_lp and _IY_lp.Character and _IY_lp.Character:FindFirstChildWhichIsA("Humanoid") then
				oldgrav = workspace.Gravity
				workspace.Gravity = 0
				local swimDied = function()
					workspace.Gravity = oldgrav
					swimming = false
				end
				local Humanoid = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
				gravReset = Humanoid.Died:Connect(swimDied)
				local enums = Enum.HumanoidStateType:GetEnumItems()
				table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
				for i, v in pairs(enums) do
					Humanoid:SetStateEnabled(v, false)
				end
				Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
				swimbeat = _IY_RunService.Heartbeat:Connect((function()
					LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
					pcall(function()
						_IY__IY_getRoot(_IY_lp.Character).AssemblyLinearVelocity = ((Humanoid.MoveDirection ~= Vector3.new() or _IY_UIS:IsKeyDown(Enum.KeyCode.Space)) and _IY__IY_getRoot(_IY_lp.Character).AssemblyLinearVelocity or Vector3.new())
					end)
				end))
				swimming = true
			end
		end
	},
	{
		name = "unswim",
		desc = "Disable swim physics",
		aliases = {'noswim'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if _IY_lp and _IY_lp.Character and _IY_lp.Character:FindFirstChildWhichIsA("Humanoid") then
				workspace.Gravity = oldgrav
				swimming = false
				if gravReset then
					gravReset:Disconnect()
				end
				if swimbeat ~= nil then
					swimbeat:Disconnect()
					swimbeat = nil
				end
				local Humanoid = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
				local enums = Enum.HumanoidStateType:GetEnumItems()
				table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
				for i, v in pairs(enums) do
					Humanoid:SetStateEnabled(v, true)
				end
			end
		end
	},
	{
		name = "toggleswim",
		desc = "Toggle swim mode",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if swimming then
				execCmd('unswim')
			else
				execCmd('swim')
			end
		end
	},
	{
		name = "setwaypoint",
		desc = "Save a waypoint at current position <name>",
		aliases = {'swp', 'setwp', 'spos', 'saveposition', 'savepos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local WPName = tostring(getstring(1, args))
			if _IY_getRoot(_IY_lp.Character) then
				_IY_notify('Modified Waypoints',"Created waypoint: "..getstring(1, args))
				local torso = _IY_getRoot(_IY_lp.Character)
				WayPoints[#WayPoints + 1] = {NAME = WPName, COORD = {math.floor(torso.Position.X), math.floor(torso.Position.Y), math.floor(torso.Position.Z)}, GAME = PlaceId}
				if AllWaypoints ~= nil then
					AllWaypoints[#AllWaypoints + 1] = {NAME = WPName, COORD = {math.floor(torso.Position.X), math.floor(torso.Position.Y), math.floor(torso.Position.Z)}, GAME = PlaceId}
				end
			end
			refreshwaypoints()
			updatesaves()
		end
	},
	{
		name = "waypointpos",
		desc = "Set waypoint to coordinates <name x y z>",
		args = "<arg>",
		aliases = {'wpp', 'setwaypointposition', 'setpos', 'setwaypoint', 'setwaypointpos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local WPName = tostring(getstring(1, args))
			if _IY_getRoot(_IY_lp.Character) then
				_IY_notify('Modified Waypoints',"Created waypoint: "..getstring(1, args))
				WayPoints[#WayPoints + 1] = {NAME = WPName, COORD = {args[2], args[3], args[4]}, GAME = PlaceId}
				if AllWaypoints ~= nil then
					AllWaypoints[#AllWaypoints + 1] = {NAME = WPName, COORD = {args[2], args[3], args[4]}, GAME = PlaceId}
				end
			end
			refreshwaypoints()
			updatesaves()
		end
	},
	{
		name = "waypoints",
		desc = "List all saved waypoints",
		aliases = {'positions'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if SettingsOpen == false then
				SettingsOpen = true
				Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.5, true, nil)
				CMDsF.Visible = false
			end
			KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
			AliasesFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
			PluginsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
			PositionsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
			wait(0.5)
			SettingsHolder.Visible = false
			maximizeHolder()
		end
	},
	{
		name = "showwaypoints",
		desc = "Show waypoint markers in workspace",
		aliases = {'showwp', 'showwps'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			execCmd('hidewaypoints')
			wait()
			for i,_ in pairs(WayPoints) do
				local x = WayPoints[i].COORD[1]
				local y = WayPoints[i].COORD[2]
				local z = WayPoints[i].COORD[3]
				local part = Instance.new("Part")
				part.Size = Vector3.new(5,5,5)
				part.CFrame = CFrame.new(x,y,z)
				part.Parent = workspace
				part.Anchored = true
				part.CanCollide = false
				table.insert(waypointParts,part)
				local view = Instance.new("BoxHandleAdornment")
				view.Adornee = part
				view.AlwaysOnTop = true
				view.ZIndex = 10
				view.Size = part.Size
				view.Parent = part
			end
			for i,v in pairs(pWayPoints) do
				local view = Instance.new("BoxHandleAdornment")
				view.Adornee = pWayPoints[i].COORD[1]
				view.AlwaysOnTop = true
				view.ZIndex = 10
				view.Size = pWayPoints[i].COORD[1].Size
				view.Parent = pWayPoints[i].COORD[1]
				table.insert(waypointParts,view)
			end
		end
	},
	{
		name = "hidewaypoints",
		desc = "Hide waypoint markers",
		aliases = {'hidewp', 'hidewps'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(waypointParts) do
				v:Destroy()
			end
			waypointParts = {}
		end
	},
	{
		name = "waypoint",
		desc = "Teleport to a waypoint <name>",
		aliases = {'wp', 'lpos', 'loadposition', 'loadpos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local WPName = tostring(getstring(1, args))
			if _IY_lp.Character then
				for i,_ in pairs(WayPoints) do
					if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
						local x = WayPoints[i].COORD[1]
						local y = WayPoints[i].COORD[2]
						local z = WayPoints[i].COORD[3]
						_IY_getRoot(_IY_lp.Character).CFrame = CFrame.new(x,y,z)
					end
				end
				for i,_ in pairs(pWayPoints) do
					if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
						_IY_getRoot(_IY_lp.Character).CFrame = CFrame.new(pWayPoints[i].COORD[1].Position)
					end
				end
			end
		end
	},
	{
		name = "tweenspeed",
		desc = "Set tween travel speed <value>",
		args = "<arg>",
		aliases = {'tspeed'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local newSpeed = args[1] or 1
			if tonumber(newSpeed) then
				_IY_tweenSpeed = tonumber(newSpeed)
			end
		end
	},
	{
		name = "tweenwaypoint",
		desc = "Tween to a waypoint <name>",
		aliases = {'twp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local WPName = tostring(getstring(1, args))
			if _IY_lp.Character then
				for i,_ in pairs(WayPoints) do
					local x = WayPoints[i].COORD[1]
					local y = WayPoints[i].COORD[2]
					local z = WayPoints[i].COORD[3]
					if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
						_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(x,y,z)}):Play()
					end
				end
				for i,_ in pairs(pWayPoints) do
					if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
						_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pWayPoints[i].COORD[1].Position)}):Play()
					end
				end
			end
		end
	},
	{
		name = "walktowaypoint",
		desc = "Walk to a waypoint <name>",
		aliases = {'wtwp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local WPName = tostring(getstring(1, args))
			if _IY_lp.Character then
				for i,_ in pairs(WayPoints) do
					local x = WayPoints[i].COORD[1]
					local y = WayPoints[i].COORD[2]
					local z = WayPoints[i].COORD[3]
					if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
						if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
							_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
							wait(.1)
						end
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(x,y,z)
					end
				end
				for i,_ in pairs(pWayPoints) do
					if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
						if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
							_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
							wait(.1)
						end
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(pWayPoints[i].COORD[1].Position)
					end
				end
			end
		end
	},
	{
		name = "deletewaypoint",
		desc = "Delete a waypoint <name>",
		aliases = {'dwp', 'dpos', 'deleteposition', 'deletepos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(WayPoints) do
				if v.NAME:lower() == tostring(getstring(1, args)):lower() then
					_IY_notify('Modified Waypoints',"Deleted waypoint: " .. v.NAME)
					table.remove(WayPoints, i)
				end
			end
			if AllWaypoints ~= nil and #AllWaypoints > 0 then
				for i,v in pairs(AllWaypoints) do
					if v.NAME:lower() == tostring(getstring(1, args)):lower() then
						if not v.GAME or v.GAME == PlaceId then
							table.remove(AllWaypoints, i)
						end
					end
				end
			end
			for i,v in pairs(pWayPoints) do
				if v.NAME:lower() == tostring(getstring(1, args)):lower() then
					_IY_notify('Modified Waypoints',"Deleted waypoint: " .. v.NAME)
					table.remove(pWayPoints, i)
				end
			end
			refreshwaypoints()
			updatesaves()
		end
	},
	{
		name = "clearwaypoints",
		desc = "Clear all waypoints",
		aliases = {'cwp', 'clearpositions', 'cpos', 'clearpos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			WayPoints = {}
			pWayPoints = {}
			refreshwaypoints()
			updatesaves()
			AllWaypoints = {}
			_IY_notify('Modified Waypoints','Removed all _IY_waypoints')
		end
	},
	{
		name = "cleargamewaypoints",
		desc = "Clear game-default waypoints",
		aliases = {'cgamewp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(WayPoints) do
				if v.GAME == PlaceId then
					table.remove(WayPoints, i)
				end
			end
			if AllWaypoints ~= nil and #AllWaypoints > 0 then
				for i,v in pairs(AllWaypoints) do
					if v.GAME == PlaceId then
						table.remove(AllWaypoints, i)
					end
				end
			end
			for i,v in pairs(pWayPoints) do
				if v.GAME == PlaceId then
					table.remove(pWayPoints, i)
				end
			end
			refreshwaypoints()
			updatesaves()
			_IY_notify('Modified Waypoints','Deleted game _IY_waypoints')
		end
	},
	{
		name = "enable",
		desc = "Enable a GUI <name>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local input = args[1] and args[1]:lower()
			if input then
				if input == "reset" then
					StarterGui:SetCore("ResetButtonCallback", true)
				else
					local coreGuiType = coreGuiTypeNames[input]
					if coreGuiType then
						StarterGui:SetCoreGuiEnabled(coreGuiType, true)
					end
				end
			end
		end
	},
	{
		name = "disable",
		desc = "Disable a GUI <name>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local input = args[1] and args[1]:lower()
			if input then
				if input == "reset" then
					StarterGui:SetCore("ResetButtonCallback", false)
				else
					local coreGuiType = coreGuiTypeNames[input]
					if coreGuiType then
						StarterGui:SetCoreGuiEnabled(coreGuiType, false)
					end
				end
			end
		end
	},
	{
		name = "showguis",
		desc = "Show all player GUIs",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(PlayerGui:GetDescendants()) do
				if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and not v.Visible then
					v.Visible = true
					if not _IY_FindInTable(invisGUIS,v) then
						table.insert(invisGUIS,v)
					end
				end
			end
		end
	},
	{
		name = "unshowguis",
		desc = "Restore hidden GUIs",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(invisGUIS) do
				v.Visible = false
			end
			invisGUIS = {}
		end
	},
	{
		name = "hideguis",
		desc = "Hide all player GUIs",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(PlayerGui:GetDescendants()) do
				if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and v.Visible then
					v.Visible = false
					if not _IY_FindInTable(hiddenGUIS,v) then
						table.insert(hiddenGUIS,v)
					end
				end
			end
		end
	},
	{
		name = "unhideguis",
		desc = "Restore hidden GUIs",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(hiddenGUIS) do
				v.Visible = true
			end
			hiddenGUIS = {}
		end
	},
	{
		name = "guidelete",
		desc = "Delete a GUI <name>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			deleteGuiInput = _IY_UIS.InputBegan:Connect(function(input, gameProcessedEvent)
				if not gameProcessedEvent then
					if input.KeyCode == Enum.KeyCode.Backspace then
						deleteGuisAtPos()
					end
				end
			end)
			_IY_notify('GUI Delete Enabled','Hover over a GUI and press backspace to delete it')
		end
	},
	{
		name = "unguidelete",
		desc = "Restore deleted GUIs",
		aliases = {'noguidelete'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if deleteGuiInput then deleteGuiInput:Disconnect() end
			_IY_notify('GUI Delete Disabled','GUI backspace delete has been disabled')
		end
	},
	{
		name = "togglefs",
		desc = "Toggle fullscreen",
		aliases = {'togglefullscreen'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			return GuiService:ToggleFullscreen()
		end
	},
	{
		name = "inspect",
		desc = "Open inspect menu on player <player>",
		args = "<arg>",
		aliases = {'examine'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			for _, v in ipairs(_IY_getPlayer(args[1], _IY_lp)) do
				GuiService:CloseInspectMenu()
				GuiService:InspectPlayerFromUserId(_IY_Players[v].UserId)
			end
		end
	},
	{
		name = "partesp",
		desc = "ESP highlight a part by name <name>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local partEspName = getstring(1, args):lower()
			if not _IY_FindInTable(espParts,partEspName) then
				table.insert(espParts,partEspName)
				for i,v in pairs(workspace:GetDescendants()) do
					if v:IsA("BasePart") and v.Name:lower() == partEspName then
						local a = Instance.new("BoxHandleAdornment")
						a.Name = partEspName.."_PESP"
						a.Parent = v
						a.Adornee = v
						a.AlwaysOnTop = true
						a.ZIndex = 0
						a.Size = v.Size
						a.Transparency = espTransparency
						a.Color = BrickColor.new("Lime green")
					end
				end
			end
			if partEspTrigger == nil then
				partEspTrigger = workspace.DescendantAdded:Connect(partAdded)
			end
		end
	},
	{
		name = "unpartesp",
		desc = "Remove part ESP",
		args = "<arg>",
		aliases = {'nopartesp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if args[1] then
				local partEspName = getstring(1, args):lower()
				if _IY_FindInTable(espParts,partEspName) then
					table.remove(espParts, GetInTable(espParts, partEspName))
				end
				for i,v in pairs(workspace:GetDescendants()) do
					if v:IsA("BoxHandleAdornment") and v.Name == partEspName..'_PESP' then
						v:Destroy()
					end
				end
			else
				partEspTrigger:Disconnect()
				partEspTrigger = nil
				espParts = {}
				for i,v in pairs(workspace:GetDescendants()) do
					if v:IsA("BoxHandleAdornment") and v.Name:sub(-5) == '_PESP' then
						v:Destroy()
					end
				end
			end
		end
	},
	{
		name = "chams",
		desc = "Apply chams (highlight) to players <player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if not ESPenabled then
				CHMSenabled = true
				for i,v in pairs(_IY_Players:GetPlayers()) do
					if v.Name ~= _IY_lp.Name then
						CHMS(v)
					end
				end
			else
				_IY_notify('Chams','Disable ESP (noesp) before using chams')
			end
		end
	},
	{
		name = "nochams",
		desc = "Remove chams from players <player>",
		aliases = {'unchams'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			CHMSenabled = false
			for i,v in pairs(_IY_Players:GetPlayers()) do
				local chmsplr = v
				for i,c in pairs(COREGUI:GetChildren()) do
					if c.Name == chmsplr.Name..'_CHMS' then
						c:Destroy()
					end
				end
			end
		end
	},
	{
		name = "locate",
		desc = "Track a player with a billboard <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				Locate(_IY_Players[v])
			end
		end
	},
	{
		name = "nolocate",
		desc = "Remove locate tracker",
		args = "<arg>",
		aliases = {'unlocate'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			if args[1] then
				for i,v in pairs(players) do
					for i,c in pairs(COREGUI:GetChildren()) do
						if c.Name == _IY_Players[v].Name..'_LC' then
							c:Destroy()
						end
					end
				end
			else
				for i,c in pairs(COREGUI:GetChildren()) do
					if string.sub(c.Name, -3) == '_LC' then
						c:Destroy()
					end
				end
			end
		end
	},
	{
		name = "viewpart",
		desc = "Set camera to look at a part <name>",
		args = "<arg>",
		aliases = {'viewp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			StopFreecam()
			if args[1] then
				for i,v in pairs(workspace:GetDescendants()) do
					if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
						wait(0.1)
						workspace.CurrentCamera.CameraSubject = v
					end
				end
			end
		end
	},
	{
		name = "freecam",
		desc = "Enable free camera",
		aliases = {'fc'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			StartFreecam()
		end
	},
	{
		name = "freecampos",
		desc = "Set freecam position <x y z>",
		args = "<arg>",
		aliases = {'fcpos', 'fcp', 'freecamposition', 'fcposition'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if not args[1] then return end
			local freecamPos = CFrame.new(args[1],args[2],args[3])
			StartFreecam(freecamPos)
		end
	},
	{
		name = "freecamwaypoint",
		desc = "Freecam to waypoint <name>",
		aliases = {'fcwp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local WPName = tostring(getstring(1, args))
			if _IY_lp.Character then
				for i,_ in pairs(WayPoints) do
					local x = WayPoints[i].COORD[1]
					local y = WayPoints[i].COORD[2]
					local z = WayPoints[i].COORD[3]
					if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
						StartFreecam(CFrame.new(x,y,z))
					end
				end
				for i,_ in pairs(pWayPoints) do
					if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
						StartFreecam(CFrame.new(pWayPoints[i].COORD[1].Position))
					end
				end
			end
		end
	},
	{
		name = "freecamgoto",
		desc = "Freecam to player <player>",
		args = "<arg>",
		aliases = {'fcgoto', 'freecamtp', 'fctp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				StartFreecam(_IY_getRoot(_IY_Players[v].Character).CFrame)
			end
		end
	},
	{
		name = "unfreecam",
		desc = "Disable free camera",
		aliases = {'nofreecam', 'unfc', 'nofc'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			StopFreecam()
		end
	},
	{
		name = "freecamspeed",
		desc = "Set freecam speed <value>",
		args = "<arg>",
		aliases = {'fcspeed'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local FCspeed = args[1] or 1
			if isNumber(FCspeed) then
				NAV_KEYBOARD_SPEED = Vector3.new(FCspeed, FCspeed, FCspeed)
			end
		end
	},
	{
		name = "notifyfreecamposition",
		desc = "Notify current freecam position",
		aliases = {'notifyfcpos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if fcRunning then
				local X,Y,Z = workspace.CurrentCamera.CFrame.Position.X,workspace.CurrentCamera.CFrame.Position.Y,workspace.CurrentCamera.CFrame.Position.Z
				local Format, Round = string.format, math.round
				_IY_notify("Current Position", Format("%s, %s, %s", Round(X), Round(Y), Round(Z)))
			end
		end
	},
	{
		name = "copyfreecamposition",
		desc = "Copy freecam position to clipboard",
		aliases = {'copyfcpos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if fcRunning then
				local X,Y,Z = workspace.CurrentCamera.CFrame.Position.X,workspace.CurrentCamera.CFrame.Position.Y,workspace.CurrentCamera.CFrame.Position.Z
				local Format, Round = string.format, math.round
				_IY_toClipboard(Format("%s, %s, %s", Round(X), Round(Y), Round(Z)))
			end
		end
	},
	{
		name = "gotocamera",
		desc = "Teleport to camera position",
		aliases = {'gotocam', 'tocam'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_getRoot(_IY_lp.Character).CFrame = workspace.Camera.CFrame
		end
	},
	{
		name = "tweengotocamera",
		desc = "Tween to camera position",
		aliases = {'tweengotocam', 'tgotocam', 'ttocam'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = workspace.Camera.CFrame}):Play()
		end
	},
	{
		name = "fov",
		desc = "Set field of view <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local fov = args[1] or 70
			if isNumber(fov) then
				workspace.CurrentCamera.FieldOfView = fov
			end
		end
	},
	{
		name = "lookat",
		desc = "Look at a player <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			if _IY_lp.CameraMaxZoomDistance ~= 0.5 then
				preMaxZoom = _IY_lp.CameraMaxZoomDistance
				preMinZoom = _IY_lp.CameraMinZoomDistance
			end
			_IY_lp.CameraMaxZoomDistance = 0.5
			_IY_lp.CameraMinZoomDistance = 0.5
			wait()
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				local target = _IY_Players[v].Character
				if target and target:FindFirstChild('Head') then
					workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.p, target.Head.CFrame.p)
					wait(0.1)
				end
			end
			_IY_lp.CameraMaxZoomDistance = preMaxZoom
			_IY_lp.CameraMinZoomDistance = preMinZoom
		end
	},
	{
		name = "fixcam",
		desc = "Reset camera to default",
		aliases = {'restorecam'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			StopFreecam()
			execCmd('unview')
			workspace.CurrentCamera:remove()
			wait(.1)
			repeat wait() until _IY_lp.Character ~= nil
			workspace.CurrentCamera.CameraSubject = _IY_lp.Character:FindFirstChildWhichIsA('Humanoid')
			workspace.CurrentCamera.CameraType = "Custom"
			_IY_lp.CameraMinZoomDistance = 0.5
			_IY_lp.CameraMaxZoomDistance = 400
			_IY_lp.CameraMode = "Classic"
			_IY_lp.Character.Head.Anchored = false
		end
	},
	{
		name = "firstp",
		desc = "Switch to first person",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_lp.CameraMode = "LockFirstPerson"
		end
	},
	{
		name = "thirdp",
		desc = "Switch to third person",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_lp.CameraMode = "Classic"
		end
	},
	{
		name = "noclipcam",
		desc = "Toggle camera noclip",
		aliases = {'nccam'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local sc = (debug and debug.setconstant) or setconstant
			local gc = (debug and debug.getconstants) or getconstants
			if not sc or not getgc or not gc then
				return _IY_notify('Incompatible Exploit', 'Your exploit does not support this command (missing setconstant or getconstants or getgc)')
			end
			local pop = _IY_lp.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
			for _, v in pairs(getgc()) do
				if type(v) == 'function' and getfenv(v).script == pop then
					for i, v1 in pairs(gc(v)) do
						if tonumber(v1) == .25 then
							sc(v, i, 0)
						elseif tonumber(v1) == 0 then
							sc(v, i, .25)
						end
					end
				end
			end
		end
	},
	{
		name = "maxzoom",
		desc = "Set max camera zoom <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_lp.CameraMaxZoomDistance = args[1]
		end
	},
	{
		name = "infzoom",
		aliases = {"infinitezoom", "infzoomout"},
		desc = "Toggle infinite zoom distance",
		callback = function(arg)
			_infZoomEnabled = not _infZoomEnabled
			_IY_lp.CameraMaxZoomDistance = _infZoomEnabled and 9e9 or 128
			_IY_lp.CameraMinZoomDistance = 0.5
			queueNotification("Infinite Zoom", _infZoomEnabled and "Enabled" or "Disabled")
		end
	},
	{
		name = "hide",
		aliases = {"mutehide", "ghost"},
		desc = "Hide player, mute their VC and hide chat bubbles <player>",
		args = "<player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local targets = _IY_getPlayer(args[1], speaker)
			for _, targetName in ipairs(targets) do
				local target = players:FindFirstChild(targetName)
				if target then
					hidePlayer(target)
				end
			end
		end
	},
	{
		name = "unhide",
		aliases = {"unmutehide", "unghost"},
		desc = "Unhide player, unmute their VC and restore visibility <player>",
		args = "<player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local targets = _IY_getPlayer(args[1], speaker)
			for _, targetName in ipairs(targets) do
				local target = players:FindFirstChild(targetName)
				if target then
					unhidePlayer(target)
				end
			end
		end
	},
	{
		name = "minzoom",
		desc = "Set min camera zoom <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_lp.CameraMinZoomDistance = args[1]
		end
	},
	{
		name = "camdistance",
		desc = "Set camera distance <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local camMax = _IY_lp.CameraMaxZoomDistance
			local camMin = _IY_lp.CameraMinZoomDistance
			if camMax < tonumber(args[1]) then
				camMax = args[1]
			end
			_IY_lp.CameraMaxZoomDistance = args[1]
			_IY_lp.CameraMinZoomDistance = args[1]
			wait()
			_IY_lp.CameraMaxZoomDistance = camMax
			_IY_lp.CameraMinZoomDistance = camMin
		end
	},
	{
		name = "unlockws",
		desc = "Unlock workspace anchored parts",
		aliases = {'unlockworkspace'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Locked = false
				end
			end
		end
	},
	{
		name = "lockws",
		desc = "Lock workspace parts",
		aliases = {'lockworkspace'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Locked = true
				end
			end
		end
	},
	{
		name = "delete",
		desc = "Delete a part by name <name>",
		aliases = {'remove'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.Name:lower() == getstring(1, args):lower() then
					v:Destroy()
				end
			end
			_IY_notify('Item(s) Deleted','Deleted ' ..getstring(1, args))
		end
	},
	{
		name = "deleteclass",
		desc = "Delete all parts of a class <class>",
		aliases = {'removeclass', 'deleteclassname', 'removeclassname', 'dc'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.ClassName:lower() == getstring(1, args):lower() then
					v:Destroy()
				end
			end
			_IY_notify('Item(s) Deleted','Deleted items with ClassName ' ..getstring(1, args))
		end
	},
	{
		name = "chardelete",
		desc = "Delete a body part <name>",
		aliases = {'charremove', 'cd'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v.Name:lower() == getstring(1, args):lower() then
					v:Destroy()
				end
			end
			_IY_notify('Item(s) Deleted','Deleted ' ..getstring(1, args))
		end
	},
	{
		name = "chardeleteclass",
		desc = "Delete body parts of class <class>",
		aliases = {'charremoveclass', 'chardeleteclassname', 'charremoveclassname', 'cdc'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v.ClassName:lower() == getstring(1, args):lower() then
					v:Destroy()
				end
			end
			_IY_notify('Item(s) Deleted','Deleted items with ClassName ' ..getstring(1, args))
		end
	},
	{
		name = "deletevelocity",
		desc = "Zero out all velocities",
		aliases = {'dv', 'removevelocity', 'removeforces'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("RocketPropulsion") or v:IsA("BodyThrust") or v:IsA("BodyAngularVelocity") or v:IsA("AngularVelocity") or v:IsA("BodyForce") or v:IsA("VectorForce") or v:IsA("LineForce") then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "deleteinvisparts",
		desc = "Delete invisible parts",
		aliases = {'deleteinvisibleparts', 'dip'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and v.Transparency == 1 and v.CanCollide then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "invisibleparts",
		desc = "Make parts invisible <name>",
		aliases = {'invisparts'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and v.Transparency == 1 then
					if not table.find(shownParts,v) then
						table.insert(shownParts,v)
					end
					v.Transparency = 0
				end
			end
		end
	},
	{
		name = "uninvisibleparts",
		desc = "Restore part visibility <name>",
		aliases = {'uninvisparts'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(shownParts) do
				v.Transparency = 1
			end
			shownParts = {}
		end
	},
	{
		name = "age",
		desc = "Show account age of player <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			local ages = {}
			for i,v in pairs(players) do
				local p = _IY_Players[v]
				table.insert(ages, p.Name.."'s age is: "..p.AccountAge)
			end
			_IY_notify('Account Age',table.concat(ages, ',\n'))
		end
	},
	{
		name = "chatage",
		desc = "Chat account age of player <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			local ages = {}
			for i,v in pairs(players) do
				local p = _IY_Players[v]
				table.insert(ages, p.Name.."'s age is: "..p.AccountAge)
			end
			local chatString = table.concat(ages, ', ')
			chatMessage(chatString)
		end
	},
	{
		name = "joindate",
		desc = "Show join date <player>",
		args = "<arg>",
		aliases = {'jd'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			local dates = {}
			for i,v in pairs(players) do
				local p = _IY_Players[v]
				local secondsOld = p.AccountAge * 24 * 60 * 60
				local now = os.time()
				local dateJoined  = p.Name .. " joined: " .. os.date("%m/%d/%y", now - secondsOld)
				table.insert(dates, dateJoined)
			end
			_IY_notify('Join Date (Month/Day/Year)',table.concat(dates, ',\n'))
		end
	},
	{
		name = "chatjoindate",
		desc = "Chat join date <player>",
		args = "<arg>",
		aliases = {'cjd'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			local dates = {}
			for i,v in pairs(players) do
				local p = _IY_Players[v]
				local secondsOld = p.AccountAge * 24 * 60 * 60
				local now = os.time()
				local dateJoined  = p.Name .. " joined: " .. os.date("%m/%d/%y", now - secondsOld)
				table.insert(dates, dateJoined)
			end
			local chatString = table.concat(dates, ', ')
			chatMessage(chatString)
		end
	},
	{
		name = "copyname",
		desc = "Copy player username to clipboard <player>",
		args = "<arg>",
		aliases = {'copyuser'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				local name = tostring(_IY_Players[v].Name)
				_IY_toClipboard(name)
			end
		end
	},
	{
		name = "userid",
		desc = "Notify player user ID <player>",
		args = "<arg>",
		aliases = {'id'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				local id = tostring(_IY_Players[v].UserId)
				_IY_notify('User ID',id)
			end
		end
	},
	{
		name = "copyid",
		desc = "Copy player user ID to clipboard <player>",
		args = "<arg>",
		aliases = {'copyuserid'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				local id = tostring(_IY_Players[v].UserId)
				_IY_toClipboard(id)
			end
		end
	},
	{
		name = "creatorid",
		desc = "Show game creator ID",
		aliases = {'creator'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if game.CreatorType == Enum.CreatorType.User then
				_IY_notify('Creator ID',game.CreatorId)
			elseif game.CreatorType == Enum.CreatorType.Group then
				local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
				_IY_lp.UserId = OwnerID
				_IY_notify('Creator ID',OwnerID)
			end
		end
	},
	{
		name = "copycreatorid",
		desc = "Copy creator ID to clipboard",
		aliases = {'copycreator'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if game.CreatorType == Enum.CreatorType.User then
				_IY_toClipboard(game.CreatorId)
				_IY_notify('Copied ID','Copied creator ID to clipboard')
			elseif game.CreatorType == Enum.CreatorType.Group then
				local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
				_IY_toClipboard(OwnerID)
				_IY_notify('Copied ID','Copied creator ID to clipboard')
			end
		end
	},
	{
		name = "setcreatorid",
		desc = "Set creator ID <id>",
		aliases = {'setcreator'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if game.CreatorType == Enum.CreatorType.User then
				_IY_lp.UserId = game.CreatorId
				_IY_notify('Set ID','Set UserId to '..game.CreatorId)
			elseif game.CreatorType == Enum.CreatorType.Group then
				local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
				_IY_lp.UserId = OwnerID
				_IY_notify('Set ID','Set UserId to '..OwnerID)
			end
		end
	},
	{
		name = "appearanceid",
		desc = "Show player appearance ID <player>",
		args = "<arg>",
		aliases = {'aid'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				local aid = tostring(_IY_Players[v].CharacterAppearanceId)
				_IY_notify('Appearance ID',aid)
			end
		end
	},
	{
		name = "copyappearanceid",
		desc = "Copy appearance ID to clipboard <player>",
		args = "<arg>",
		aliases = {'caid'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players) do
				local aid = tostring(_IY_Players[v].CharacterAppearanceId)
				_IY_toClipboard(aid)
			end
		end
	},
	{
		name = "norender",
		desc = "Disable rendering (black screen)",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_RunService:Set3dRenderingEnabled(false)
		end
	},
	{
		name = "render",
		desc = "Re-enable rendering",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_RunService:Set3dRenderingEnabled(true)
		end
	},
	{
		name = "2022materials",
		desc = "Apply 2022 material textures",
		aliases = {'use2022materials'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if sethidden then
				sethidden(MaterialService, "Use2022Materials", true)
			else
				_IY_notify('Incompatible Exploit','Your exploit does not support this command (missing sethiddenproperty)')
			end
		end
	},
	{
		name = "un2022materials",
		desc = "Remove 2022 material textures",
		aliases = {'unuse2022materials'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if sethidden then
				sethidden(MaterialService, "Use2022Materials", false)
			else
				_IY_notify('Incompatible Exploit','Your exploit does not support this command (missing sethiddenproperty)')
			end
		end
	},
	{
		name = "tweengoto",
		desc = "Tween to player position <player>",
		args = "<arg>",
		aliases = {'tgoto', 'tto', 'tweento'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				if _IY_Players[v].Character ~= nil then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = _IY_getRoot(_IY_Players[v].Character).CFrame + Vector3.new(3,1,0)}):Play()
				end
			end
			execCmd('breakvelocity')
		end
	},
	{
		name = "vehiclegoto",
		desc = "Teleport vehicle to player <player>",
		args = "<arg>",
		aliases = {'vgoto', 'vtp', 'vehicletp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				if _IY_Players[v].Character ~= nil then
					local seat = _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart
					local vehicleModel = seat:FindFirstAncestorWhichIsA("Model")
					vehicleModel:MoveTo(_IY_getRoot(_IY_Players[v].Character).Position)
				end
			end
		end
	},
	{
		name = "pulsetp",
		desc = "Repeatedly teleport to player <player>",
		args = "<arg>",
		aliases = {'ptp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				if _IY_Players[v].Character ~= nil then
					local startPos = _IY_getRoot(_IY_lp.Character).CFrame
					local seconds = args[2] or 1
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					_IY_getRoot(_IY_lp.Character).CFrame = _IY_getRoot(_IY_Players[v].Character).CFrame + Vector3.new(3,1,0)
					wait(seconds)
					_IY_getRoot(_IY_lp.Character).CFrame = startPos
				end
			end
			execCmd('breakvelocity')
		end
	},
	{
		name = "vehiclenoclip",
		desc = "Toggle vehicle noclip",
		aliases = {'vnoclip'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			vnoclipParts = {}
			local seat = _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart
			local vehicleModel = seat.Parent
			repeat
				if vehicleModel.ClassName ~= "Model" then
					vehicleModel = vehicleModel.Parent
				end
			until vehicleModel.ClassName == "Model"
			wait(0.1)
			execCmd('noclip')
			for i,v in pairs(vehicleModel:GetDescendants()) do
				if v:IsA("BasePart") and v.CanCollide then
					table.insert(vnoclipParts,v)
					v.CanCollide = false
				end
			end
		end
	},
	{
		name = "clientbring",
		desc = "Client-side bring player to you <player>",
		args = "<arg>",
		aliases = {'cbring'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				if _IY_Players[v].Character ~= nil then
					if _IY_Players[v].Character:FindFirstChildOfClass('Humanoid') then
						_IY_Players[v].Character:FindFirstChildOfClass('Humanoid').Sit = false
					end
					wait()
					_IY_getRoot(_IY_Players[v].Character).CFrame = _IY_getRoot(_IY_lp.Character).CFrame + Vector3.new(3,1,0)
				end
			end
		end
	},
	{
		name = "loopbring",
		desc = "Loop bring player <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				task.spawn(function()
					if _IY_Players[v].Name ~= _IY_lp.Name and not _IY_FindInTable(bringT, _IY_Players[v].Name) then
						table.insert(bringT, _IY_Players[v].Name)
						local plrName = _IY_Players[v].Name
						local pchar=_IY_Players[v].Character
						local distance = 3
						if args[2] and isNumber(args[2]) then
							distance = args[2]
						end
						local lDelay = 0
						if args[3] and isNumber(args[3]) then
							lDelay = args[3]
						end
						repeat
							for i,c in pairs(players) do
								if _IY_Players:FindFirstChild(v) then
									pchar = _IY_Players[v].Character
									if pchar~= nil and _IY_Players[v].Character ~= nil and _IY_getRoot(pchar) and _IY_lp.Character ~= nil and _IY_getRoot(_IY_lp.Character) then
										_IY_getRoot(pchar).CFrame = _IY_getRoot(_IY_lp.Character).CFrame + Vector3.new(distance,1,0)
									end
									wait(lDelay)
								else
									for a,b in pairs(bringT) do if b == plrName then table.remove(bringT, a) end end
								end
							end
						until not _IY_FindInTable(bringT, plrName)
					end
				end)
			end
		end
	},
	{
		name = "unloopbring",
		desc = "Stop loop bring",
		args = "<arg>",
		aliases = {'noloopbring'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				task.spawn(function()
					for a,b in pairs(bringT) do if b == _IY_Players[v].Name then table.remove(bringT, a) end end
				end)
			end
		end
	},
	{
		name = "walkto",
		desc = "Walk to player <player>",
		args = "<arg>",
		aliases = {'follow'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				if _IY_Players[v].Character ~= nil then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					walkto = true
					repeat wait()
						_IY_lp.Character:FindFirstChildOfClass('Humanoid'):MoveTo(_IY_getRoot(_IY_Players[v].Character).Position)
					until _IY_Players[v].Character == nil or not _IY_getRoot(_IY_Players[v].Character) or walkto == false
				end
			end
		end
	},
	{
		name = "pathfindwalkto",
		desc = "Pathfind walk to player <player>",
		args = "<arg>",
		aliases = {'pathfindfollow'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			walkto = false
			wait()
			local players = _IY_getPlayer(args[1], _IY_lp)
			local hum = _IY_lp.Character:FindFirstChildOfClass("Humanoid")
			local path = PathService:CreatePath()
			for i,v in pairs(players)do
				if _IY_Players[v].Character ~= nil then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					walkto = true
					repeat wait()
						local success, response = pcall(function()
							path:ComputeAsync(_IY_getRoot(_IY_lp.Character).Position, _IY_getRoot(_IY_Players[v].Character).Position)
							local _IY_waypoints = path:GetWaypoints()
							local distance
							for waypointIndex, waypoint in pairs(_IY_waypoints) do
								local waypointPosition = waypoint.Position
								hum:MoveTo(waypointPosition)
								repeat
									distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
									wait()
								until
								distance <= 5
							end
						end)
						if not success then
							_IY_lp.Character:FindFirstChildOfClass('Humanoid'):MoveTo(_IY_getRoot(_IY_Players[v].Character).Position)
						end
					until _IY_Players[v].Character == nil or not _IY_getRoot(_IY_Players[v].Character) or walkto == false
				end
			end
		end
	},
	{
		name = "pathfindwalktowaypoint",
		desc = "Pathfind to waypoint <name>",
		aliases = {'pathfindwalktowp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			waypointwalkto = false
			wait()
			local WPName = tostring(getstring(1, args))
			local hum = _IY_lp.Character:FindFirstChildOfClass("Humanoid")
			local path = PathService:CreatePath()
			if _IY_lp.Character then
				for i,_ in pairs(WayPoints) do
					if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
						if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
							_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
							wait(.1)
						end
						local TrueCoords = Vector3.new(WayPoints[i].COORD[1], WayPoints[i].COORD[2], WayPoints[i].COORD[3])
						waypointwalkto = true
						repeat wait()
							local success, response = pcall(function()
								path:ComputeAsync(_IY_getRoot(_IY_lp.Character).Position, TrueCoords)
								local _IY_waypoints = path:GetWaypoints()
								local distance
								for waypointIndex, waypoint in pairs(_IY_waypoints) do
									local waypointPosition = waypoint.Position
									hum:MoveTo(waypointPosition)
									repeat
										distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
										wait()
									until
									distance <= 5
								end
							end)
							if not success then
								_IY_lp.Character:FindFirstChildOfClass('Humanoid'):MoveTo(TrueCoords)
							end
						until not _IY_lp.Character or waypointwalkto == false
					end
				end
				for i,_ in pairs(pWayPoints) do
					if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
						if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
							_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
							wait(.1)
						end
						local TrueCoords = pWayPoints[i].COORD[1].Position
						waypointwalkto = true
						repeat wait()
							local success, response = pcall(function()
								path:ComputeAsync(_IY_getRoot(_IY_lp.Character).Position, TrueCoords)
								local _IY_waypoints = path:GetWaypoints()
								local distance
								for waypointIndex, waypoint in pairs(_IY_waypoints) do
									local waypointPosition = waypoint.Position
									hum:MoveTo(waypointPosition)
									repeat
										distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
										wait()
									until
									distance <= 5
								end
							end)
							if not success then
								_IY_lp.Character:FindFirstChildOfClass('Humanoid'):MoveTo(TrueCoords)
							end
						until not _IY_lp.Character or waypointwalkto == false
					end
				end
			end
		end
	},
	{
		name = "unwalkto",
		desc = "Stop walking to target",
		aliases = {'nowalkto', 'unfollow', 'nofollow'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			walkto = false
			waypointwalkto = false
		end
	},
	{
		name = "freeze",
		desc = "Freeze player <player>",
		args = "<arg>",
		aliases = {'fr'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			if players ~= nil then
				for i,v in pairs(players) do
					task.spawn(function()
						for i, x in next, _IY_Players[v].Character:GetDescendants() do
							if x:IsA("BasePart") and not x.Anchored then
								x.Anchored = true
							end
						end
					end)
				end
			end
		end
	},
	{
		name = "thaw",
		desc = "Unfreeze player <player>",
		args = "<arg>",
		aliases = {'unfreeze', 'unfr'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			if players ~= nil then
				for i,v in pairs(players) do
					task.spawn(function()
						for i, x in next, _IY_Players[v].Character:GetDescendants() do
							if x.Name ~= floatName and x:IsA("BasePart") and x.Anchored then
								x.Anchored = false
							end
						end
					end)
				end
			end
		end
	},
	{
		name = "loopoof",
		desc = "Loop play oof sound on player death",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			oofing = true
			repeat wait(0.1)
				for i,v in pairs(_IY_Players:GetPlayers()) do
					if v.Character ~= nil and v.Character:FindFirstChild'Head' then
						for _,x in pairs(v.Character.Head:GetChildren()) do
							if x:IsA'Sound' then x.Playing = true end
						end
					end
				end
			until oofing == false
		end
	},
	{
		name = "unloopoof",
		desc = "Stop loop oof",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			oofing = false
		end
	},
	{
		name = "muteboombox",
		desc = "Mute boombox sounds",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			if not notifiedRespectFiltering and SoundService.RespectFilteringEnabled then notifiedRespectFiltering = true _IY_notify('RespectFilteringEnabled','RespectFilteringEnabled is set to true (the command will still work but may only be clientsided)') end
			local players = _IY_getPlayer(args[1], _IY_lp)
			if players ~= nil then
				for i,v in pairs(players) do
					task.spawn(function()
						for i, x in next, _IY_Players[v].Character:GetDescendants() do
							if x:IsA("Sound") and x.Playing == true then
								x.Playing = false
							end
						end
						for i, x in next, _IY_Players[v]:FindFirstChildOfClass("Backpack"):GetDescendants() do
							if x:IsA("Sound") and x.Playing == true then
								x.Playing = false
							end
						end
					end)
				end
			end
		end
	},
	{
		name = "unmuteboombox",
		desc = "Unmute boombox sounds",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			if not notifiedRespectFiltering and SoundService.RespectFilteringEnabled then notifiedRespectFiltering = true _IY_notify('RespectFilteringEnabled','RespectFilteringEnabled is set to true (the command will still work but may only be clientsided)') end
			local players = _IY_getPlayer(args[1], _IY_lp)
			if players ~= nil then
				for i,v in pairs(players) do
					task.spawn(function()
						for i, x in next, _IY_Players[v].Character:GetDescendants() do
							if x:IsA("Sound") and x.Playing == false then
								x.Playing = true
							end
						end
					end)
				end
			end
		end
	},
	{
		name = "freezeanims",
		desc = "Freeze player animations <player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Humanoid = _IY_lp.Character:FindFirstChildOfClass("Humanoid") or _IY_lp.Character:FindFirstChildOfClass("AnimationController")
			local ActiveTracks = Humanoid:GetPlayingAnimationTracks()
			for _, v in pairs(ActiveTracks) do
				v:AdjustSpeed(0)
			end
		end
	},
	{
		name = "unfreezeanims",
		desc = "Unfreeze player animations <player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Humanoid = _IY_lp.Character:FindFirstChildOfClass("Humanoid") or _IY_lp.Character:FindFirstChildOfClass("AnimationController")
			local ActiveTracks = Humanoid:GetPlayingAnimationTracks()
			for _, v in pairs(ActiveTracks) do
				v:AdjustSpeed(1)
			end
		end
	},
	{
		name = "invisible",
		desc = "Make self invisible",
		aliases = {'invis'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if invisRunning then return end
			invisRunning = true

			local Player = _IY_lp
			repeat wait(.1) until Player.Character
			local Character = Player.Character
			Character.Archivable = true
			local IsInvis = false
			local IsRunning = true
			local InvisibleCharacter = Character:Clone()
			InvisibleCharacter.Parent = Lighting
			local Void = workspace.FallenPartsDestroyHeight
			InvisibleCharacter.Name = ""
			local CF
			local invisFix = _IY_RunService.Stepped:Connect((function()
				LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
				pcall(function()
					local IsInteger
					if tostring(Void):find'-' then
						IsInteger = true
					else
						IsInteger = false
					end
					local Pos = Player.Character.Humanoid.RootPart.Position
					local Pos_String = tostring(Pos)
					local Pos_Seperate = Pos_String:split(', ')
					local X = tonumber(Pos_Seperate[1])
					local Y = tonumber(Pos_Seperate[2])
					local Z = tonumber(Pos_Seperate[3])
					if IsInteger == true then
						if Y <= Void then
							Respawn()
						end
					elseif IsInteger == false then
						if Y >= Void then
							Respawn()
						end
					end
				end)
			end))
			for i,v in pairs(InvisibleCharacter:GetDescendants())do
				if v:IsA("BasePart") then
					if v.Name == "HumanoidRootPart" then
						v.Transparency = 1
					else
						v.Transparency = .5
					end
				end
			end
			function Respawn()
				IsRunning = false
				if IsInvis == true then
					pcall(function()
						Player.Character = Character
						wait()
						Character.Parent = workspace
						Character:FindFirstChildWhichIsA'Humanoid':Destroy()
						IsInvis = false
						InvisibleCharacter.Parent = nil
						invisRunning = false
					end)
				elseif IsInvis == false then
					pcall(function()
						Player.Character = Character
						wait()
						Character.Parent = workspace
						Character:FindFirstChildWhichIsA'Humanoid':Destroy()
						TurnVisible()
					end)
				end
			end
			local invisDied
			invisDied = InvisibleCharacter:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
				Respawn()
				invisDied:Disconnect()
			end)
			if IsInvis == true then return end
			IsInvis = true
			CF = workspace.CurrentCamera.CFrame
			local CF_1 = Player.Character.Humanoid.RootPart.CFrame
			Character:MoveTo(Vector3.new(0,math.pi*1000000,0))
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			wait(.2)
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			InvisibleCharacter = InvisibleCharacter
			Character.Parent = Lighting
			InvisibleCharacter.Parent = workspace
			InvisibleCharacter.Humanoid.RootPart.CFrame = CF_1
			Player.Character = InvisibleCharacter
			execCmd('fixcam')
			Player.Character.Animate.Disabled = true
			Player.Character.Animate.Disabled = false
			function TurnVisible()
				if IsInvis == false then return end
				invisFix:Disconnect()
				invisDied:Disconnect()
				CF = workspace.CurrentCamera.CFrame
				Character = Character
				local CF_1 = Player.Character.Humanoid.RootPart.CFrame
				Character.Humanoid.RootPart.CFrame = CF_1
				InvisibleCharacter:Destroy()
				Player.Character = Character
				Character.Parent = workspace
				IsInvis = false
				Player.Character.Animate.Disabled = true
				Player.Character.Animate.Disabled = false
				invisDied = Character:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
					Respawn()
					invisDied:Disconnect()
				end)
				invisRunning = false
			end
			_IY_notify('Invisible','You now appear invisible to other players')
		end
	},
	{
		name = "toolinvisible",
		desc = "Toggle tool visibility",
		aliases = {'toolinvis', 'tinvis'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char  = _IY_lp.Character
			local touched = false
			local tpdback = false
			local box = Instance.new('Part')
			box.Anchored = true
			box.CanCollide = true
			box.Size = Vector3.new(10,1,10)
			box.Position = Vector3.new(0,10000,0)
			box.Parent = workspace
			local boxTouched = box.Touched:connect(function(part)
				if (part.Parent.Name == _IY_lp.Name) then
					if touched == false then
						touched = true
						local function apply()
							local no = Char.Humanoid.RootPart:Clone()
							task.wait(.25)
							Char.Humanoid.RootPart:Destroy()
							no.Parent = Char
							Char:MoveTo(loc)
							touched = false
						end
						if Char then
							apply()
						end
					end
				end
			end)
			repeat wait() until Char
			local cleanUp
			cleanUp = _IY_lp.CharacterAdded:connect(function(char)
				boxTouched:Disconnect()
				box:Destroy()
				cleanUp:Disconnect()
			end)
			loc = Char.Humanoid.RootPart.Position
			Char:MoveTo(box.Position + Vector3.new(0,.5,0))
		end
	},
	{
		name = "jpower",
		desc = "Set jump power <value>",
		args = "<arg>",
		aliases = {'jumppower', 'jp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local jpower = args[1] or 50
			if isNumber(jpower) then
				if _IY_lp.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
					_IY_lp.Character:FindFirstChildOfClass('Humanoid').JumpPower = jpower
				else
					_IY_lp.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = jpower
				end
			end
		end
	},
	{
		name = "nolimbs",
		desc = "Remove limbs",
		aliases = {'rlimbs'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if r15(_IY_lp) then
				for i,v in pairs(_IY_lp.Character:GetChildren()) do
					if v:IsA("BasePart") and
						v.Name == "RightUpperLeg" or
						v.Name == "LeftUpperLeg" or
						v.Name == "RightUpperArm" or
						v.Name == "LeftUpperArm" then
						v:Destroy()
					end
				end
			else
				for i,v in pairs(_IY_lp.Character:GetChildren()) do
					if v:IsA("BasePart") and
						v.Name == "Right Leg" or
						v.Name == "Left Leg" or
						v.Name == "Right Arm" or
						v.Name == "Left Arm" then
						v:Destroy()
					end
				end
			end
		end
	},
	{
		name = "noarms",
		desc = "Remove arms",
		aliases = {'rarms'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if r15(_IY_lp) then
				for i,v in pairs(_IY_lp.Character:GetChildren()) do
					if v:IsA("BasePart") and
						v.Name == "RightUpperArm" or
						v.Name == "LeftUpperArm" then
						v:Destroy()
					end
				end
			else
				for i,v in pairs(_IY_lp.Character:GetChildren()) do
					if v:IsA("BasePart") and
						v.Name == "Right Arm" or
						v.Name == "Left Arm" then
						v:Destroy()
					end
				end
			end
		end
	},
	{
		name = "nolegs",
		desc = "Remove legs",
		aliases = {'rlegs'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if r15(_IY_lp) then
				for i,v in pairs(_IY_lp.Character:GetChildren()) do
					if v:IsA("BasePart") and
						v.Name == "RightUpperLeg" or
						v.Name == "LeftUpperLeg" then
						v:Destroy()
					end
				end
			else
				for i,v in pairs(_IY_lp.Character:GetChildren()) do
					if v:IsA("BasePart") and
						v.Name == "Right Leg" or
						v.Name == "Left Leg" then
						v:Destroy()
					end
				end
			end
		end
	},
	{
		name = "autojump",
		desc = "Enable auto-jump on ground",
		aliases = {'ajump'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char = _IY_lp.Character
			local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
			local autoJump = (function()
				if Char and Human then
					local check1 = workspace:FindPartOnRay(Ray.new(Human.RootPart.Position-Vector3.new(0,1.5,0), Human.RootPart.CFrame.lookVector*3), Human.Parent)
					local check2 = workspace:FindPartOnRay(Ray.new(Human.RootPart.Position+Vector3.new(0,1.5,0), Human.RootPart.CFrame.lookVector*3), Human.Parent)
					if check1 or check2 then
						Human.Jump = true
					end
				end
			end)
			autoJump()
			HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or _IY_RunService.RenderStepped:Connect(autoJump)
			HumanModCons.ajCA = (HumanModCons.ajCA and HumanModCons.ajCA:Disconnect() and false) or _IY_lp.CharacterAdded:Connect(function(nChar)
				Char, Human = nChar, nChar:WaitForChild("Humanoid")
				autoJump()
				HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or _IY_RunService.RenderStepped:Connect(autoJump)
			end)
		end
	},
	{
		name = "unautojump",
		desc = "Disable auto-jump",
		aliases = {'noautojump', 'noajump', 'unajump'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or nil
			HumanModCons.ajCA = (HumanModCons.ajCA and HumanModCons.ajCA:Disconnect() and false) or nil
		end
	},
	{
		name = "edgejump",
		desc = "Jump when walking off edges",
		aliases = {'ejump'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char = _IY_lp.Character
			local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")

			local state
			local laststate
			local lastcf
			local edgejump = (function()
				if Char and Human then
					laststate = state
					state = Human:GetState()
					if laststate ~= state and state == Enum.HumanoidStateType.Freefall and laststate ~= Enum.HumanoidStateType.Jumping then
						Char.Humanoid.RootPart.CFrame = lastcf
						Char.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(Char.Humanoid.RootPart.AssemblyLinearVelocity.X, Human.JumpPower or Human.JumpHeight, Char.Humanoid.RootPart.AssemblyLinearVelocity.Z)
					end
					lastcf = Char.Humanoid.RootPart.CFrame
				end
			end)
			edgejump()
			HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or _IY_RunService.RenderStepped:Connect(edgejump)
			HumanModCons.ejCA = (HumanModCons.ejCA and HumanModCons.ejCA:Disconnect() and false) or _IY_lp.CharacterAdded:Connect(function(nChar)
				Char, Human = nChar, nChar:WaitForChild("Humanoid")
				edgejump()
				HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or _IY_RunService.RenderStepped:Connect(edgejump)
			end)
		end
	},
	{
		name = "unedgejump",
		desc = "Disable edge jump",
		aliases = {'noedgejump', 'noejump', 'unejump'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or nil
			HumanModCons.ejCA = (HumanModCons.ejCA and HumanModCons.ejCA:Disconnect() and false) or nil
		end
	},
	{
		name = "nobgui",
		desc = "Block a player billboard GUI <player>",
		aliases = {'unbgui', 'nobillboardgui', 'unbillboardgui', 'noname', 'rohg'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants())do
				if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "loopnobgui",
		desc = "Loop block billboard GUI <player>",
		aliases = {'loopunbgui', 'loopnobillboardgui', 'loopunbillboardgui', 'loopnoname', 'looprohg'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants())do
				if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
					v:Destroy()
				end
			end
			local function charPartAdded(part)
				if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
					wait()
					part:Destroy()
				end
			end
			charPartTrigger = _IY_lp.Character.DescendantAdded:Connect(charPartAdded)
		end
	},
	{
		name = "unloopnobgui",
		desc = "Stop loop block billboard GUI",
		aliases = {'unloopunbgui', 'unloopnobillboardgui', 'unloopunbillboardgui', 'unloopnoname', 'unlooprohg'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if charPartTrigger then
				charPartTrigger:Disconnect()
			end
		end
	},
	{
		name = "spasm",
		desc = "Rapidly flail character",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if not r15(_IY_lp) then
				local pchar=_IY_lp.Character
				local AnimationId = "33796059"
				SpasmAnim = Instance.new("Animation")
				SpasmAnim.AnimationId = "rbxassetid://"..AnimationId
				Spasm = pchar:FindFirstChildOfClass('Humanoid'):LoadAnimation(SpasmAnim)
				Spasm:Play()
				Spasm:AdjustSpeed(99)
			else
				_IY_notify('R6 Required','This command requires the r6 rig type')
			end
		end
	},
	{
		name = "unspasm",
		desc = "Stop spasm",
		aliases = {'nospasm'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			Spasm:Stop()
			SpasmAnim:Destroy()
		end
	},
	{
		name = "headthrow",
		desc = "Fling head off body",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if not r15(_IY_lp) then
				local AnimationId = "35154961"
				local Anim = Instance.new("Animation")
				Anim.AnimationId = "rbxassetid://"..AnimationId
				local k = _IY_lp.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(Anim)
				k:Play(0)
				k:AdjustSpeed(1)
			else
				_IY_notify('R6 Required','This command requires the r6 rig type')
			end
		end
	},
	{
		name = "noanim",
		desc = "Disable all animations",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_lp.Character.Animate.Disabled = true
		end
	},
	{
		name = "reanim",
		desc = "Re-enable animations",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_lp.Character.Animate.Disabled = false
		end
	},
	{
		name = "animspeed",
		desc = "Set animation speed <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char = _IY_lp.Character
			local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
			for i,v in next, Hum:GetPlayingAnimationTracks() do
				v:AdjustSpeed(tonumber(args[1] or 1))
			end
		end
	},
	{
		name = "copyanimation",
		desc = "Copy current animation ID",
		args = "<arg>",
		aliases = {'copyanim', 'copyemote'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for _,v in ipairs(players)do
				local char = _IY_Players[v].Character
				for _, v1 in pairs(_IY_lp.Character:FindFirstChildOfClass('Humanoid'):GetPlayingAnimationTracks()) do
					v1:Stop()
				end
				for _, v1 in pairs(_IY_Players[v].Character:FindFirstChildOfClass('Humanoid'):GetPlayingAnimationTracks()) do
					if not string.find(v1.Animation.AnimationId, "507768375") then
						local ANIM = _IY_lp.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(v1.Animation)
						ANIM:Play(.1, 1, v1.Speed)
						ANIM.TimePosition = v1.TimePosition
						task.spawn(function()
							v1.Stopped:Wait()
							ANIM:Stop()
							ANIM:Destroy()
						end)
					end
				end
			end
		end
	},
	{
		name = "stopanimations",
		desc = "Stop all playing animations",
		aliases = {'stopanims', 'stopanim'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char = _IY_lp.Character
			local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
			for i,v in next, Hum:GetPlayingAnimationTracks() do
				v:Stop()
			end
		end
	},
	{
		name = "refreshanimations",
		desc = "Refresh character animations",
		aliases = {'refreshanimation', 'refreshanims', 'refreshanim'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char = _IY_lp.Character or _IY_lp.CharacterAdded:Wait()
			local Human = Char and Char:WaitForChild('Humanoid', 15)
			local Animate = Char and Char:WaitForChild('Animate', 15)
			if not Human or not Animate then
				return _IY_notify('Refresh Animations', 'Failed to get Animate/Humanoid')
			end
			Animate.Disabled = true
			for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
				v:Stop()
			end
			Animate.Disabled = false
		end
	},
	{
		name = "allowcustomanim",
		desc = "Allow custom animations",
		aliases = {'allowcustomanimations'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			StarterPlayer.AllowCustomAnimations = true
			execCmd('refreshanimations')
		end
	},
	{
		name = "unallowcustomanim",
		desc = "Disallow custom animations",
		aliases = {'unallowcustomanimations'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			StarterPlayer.AllowCustomAnimations = false
			execCmd('refreshanimations')
		end
	},
	{
		name = "loopanimation",
		desc = "Loop play an animation <id>",
		aliases = {'loopanim'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char = _IY_lp.Character
			local Human = Char and Char.FindFirstChildWhichIsA(Char, "Humanoid")
			for _, v in ipairs(Human.GetPlayingAnimationTracks(Human)) do
				v.Looped = true
			end
		end
	},
	{
		name = "tpposition",
		desc = "Teleport to coordinates <x y z>",
		args = "<arg>",
		aliases = {'tppos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if #args < 3 then return end
			local tpX,tpY,tpZ = tonumber((args[1]:gsub(",", ""))),tonumber((args[2]:gsub(",", ""))),tonumber((args[3]:gsub(",", "")))
			local char = _IY_lp.Character
			if char and _IY_getRoot(char) then
				_IY_getRoot(char).CFrame = CFrame.new(tpX,tpY,tpZ)
			end
		end
	},
	{
		name = "tweentpposition",
		desc = "Tween to coordinates <x y z>",
		args = "<arg>",
		aliases = {'ttppos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if #args < 3 then return end
			local tpX,tpY,tpZ = tonumber((args[1]:gsub(",", ""))),tonumber((args[2]:gsub(",", ""))),tonumber((args[3]:gsub(",", "")))
			local char = _IY_lp.Character
			if char and _IY_getRoot(char) then
				_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(tpX,tpY,tpZ)}):Play()
			end
		end
	},
	{
		name = "clickdelete",
		desc = "Delete clicked part",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if _IY_lp == _IY_lp then
				_IY_notify('Click Delete','Go to Settings > Keybinds > Add to set up click delete')
			end
		end
	},
	{
		name = "getposition",
		desc = "Notify current position",
		args = "<arg>",
		aliases = {'getpos', 'notifypos', 'notifyposition'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				local char = _IY_Players[v].Character
				local pos = char and (_IY_getRoot(char) or char:FindFirstChildWhichIsA("BasePart"))
				pos = pos and pos.Position
				if not pos then
					return _IY_notify('Getposition Error','Missing character')
				end
				local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)
				_IY_notify('Current Position',roundedPos)
			end
		end
	},
	{
		name = "copyposition",
		desc = "Copy position to clipboard",
		args = "<arg>",
		aliases = {'copypos'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				local char = _IY_Players[v].Character
				local pos = char and (_IY_getRoot(char) or char:FindFirstChildWhichIsA("BasePart"))
				pos = pos and pos.Position
				if not pos then
					return _IY_notify('Getposition Error','Missing character')
				end
				local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)
				_IY_toClipboard(roundedPos)
			end
		end
	},
	{
		name = "walktopos",
		desc = "Walk to coordinates <x y z>",
		args = "<arg>",
		aliases = {'walktoposition'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			_IY_lp.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(args[1],args[2],args[3])
		end
	},
	{
		name = "spoofspeed",
		desc = "Spoof displayed walk speed <value>",
		args = "<arg>",
		aliases = {'spoofws', 'spoofwalkspeed'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if args[1] and isNumber(args[1]) then
				if hookmetamethod then
					local char = _IY_lp.Character
					local setspeed;
					local index; index = hookmetamethod(game, "__index", (function(self, key)
						if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "walkSpeed") and self:IsDescendantOf(char) then
							return setspeed or args[1]
						end
						return index(self, key)
					end))
					local newindex; newindex = hookmetamethod(game, "__newindex", (function(self, key, value)
						if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "walkSpeed") and self:IsDescendantOf(char) then
							setspeed = tonumber(value)
						end
						return newindex(self, key, value)
					end))
				else
					_IY_notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
				end
			end
		end
	},
	{
		name = "loopspeed",
		desc = "Loop set walk speed <value>",
		args = "<arg>",
		aliases = {'loopws'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local speed = args[1] or 16
			if args[2] then
				speed = args[2] or 16
			end
			if isNumber(speed) then
				local Char = _IY_lp.Character or workspace:FindFirstChild(_IY_lp.Name)
				local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
				local function WalkSpeedChange()
					if Char and Human then
						Human.WalkSpeed = speed
					end
				end
				WalkSpeedChange()
				HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
				HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or _IY_lp.CharacterAdded:Connect(function(nChar)
					Char, Human = nChar, nChar:WaitForChild("Humanoid")
					WalkSpeedChange()
					HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
				end)
			end
		end
	},
	{
		name = "unloopspeed",
		desc = "Stop loop speed",
		aliases = {'unloopws'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or nil
			HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or nil
		end
	},
	{
		name = "spoofjumppower",
		desc = "Spoof displayed jump power <value>",
		args = "<arg>",
		aliases = {'spoofjp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if args[1] and isNumber(args[1]) then
				if hookmetamethod then
					local char = _IY_lp.Character
					local setpower;
					local index; index = hookmetamethod(game, "__index", (function(self, key)
						if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "JumpPower" or key == "jumpPower") and self:IsDescendantOf(char) then
							return setpower or args[1]
						end
						return index(self, key)
					end))
					local newindex; newindex = hookmetamethod(game, "__newindex", (function(self, key, value)
						if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "JumpPower" or key == "jumpPower") and self:IsDescendantOf(char) then
							setpower = tonumber(value)
						end
						return newindex(self, key, value)
					end))
				else
					_IY_notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
				end
			end
		end
	},
	{
		name = "loopjumppower",
		desc = "Loop set jump power <value>",
		args = "<arg>",
		aliases = {'loopjp', 'loopjpower'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local jpower = args[1] or 50
			if isNumber(jpower) then
				local Char = _IY_lp.Character or workspace:FindFirstChild(_IY_lp.Name)
				local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
				local function JumpPowerChange()
					if Char and Human then
						if _IY_lp.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
							_IY_lp.Character:FindFirstChildOfClass('Humanoid').JumpPower = jpower
						else
							_IY_lp.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = jpower
						end
					end
				end
				JumpPowerChange()
				HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
				HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or _IY_lp.CharacterAdded:Connect(function(nChar)
					Char, Human = nChar, nChar:WaitForChild("Humanoid")
					JumpPowerChange()
					HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
				end)
			end
		end
	},
	{
		name = "unloopjumppower",
		desc = "Stop loop jump power",
		aliases = {'unloopjp', 'unloopjpower'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local Char = _IY_lp.Character or workspace:FindFirstChild(_IY_lp.Name)
			local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
			HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or nil
			HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or nil
			if Char and Human then
				if _IY_lp.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
					_IY_lp.Character:FindFirstChildOfClass('Humanoid').JumpPower = 50
				else
					_IY_lp.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = 50
				end
			end
		end
	},
	{
		name = "tools",
		desc = "List backpack tools",
		aliases = {'gears'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local function copy(instance)
				for i,c in pairs(instance:GetChildren())do
					if c:IsA('Tool') or c:IsA('HopperBin') then
						c:Clone().Parent = _IY_lp:FindFirstChildOfClass("Backpack")
					end
					copy(c)
				end
			end
			copy(Lighting)
			local function copy(instance)
				for i,c in pairs(instance:GetChildren())do
					if c:IsA('Tool') or c:IsA('HopperBin') then
						c:Clone().Parent = _IY_lp:FindFirstChildOfClass("Backpack")
					end
					copy(c)
				end
			end
			copy(ReplicatedStorage)
			_IY_notify('Tools','Copied tools from ReplicatedStorage and Lighting')
		end
	},
	{
		name = "notools",
		desc = "Remove all tools from backpack",
		aliases = {'rtools', 'clrtools', 'removetools', 'deletetools', 'dtools'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp:FindFirstChildOfClass("Backpack"):GetDescendants()) do
				if v:IsA('Tool') or v:IsA('HopperBin') then
					v:Destroy()
				end
			end
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v:IsA('Tool') or v:IsA('HopperBin') then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "deleteselectedtool",
		desc = "Delete currently equipped tool",
		aliases = {'dst'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v:IsA('Tool') or v:IsA('HopperBin') then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "loopgoto",
		desc = "Loop teleport to player <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				loopgoto = nil
				if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				loopgoto = _IY_Players[v]
				local distance = 3
				if args[2] and isNumber(args[2]) then
					distance = args[2]
				end
				local lDelay = 0
				if args[3] and isNumber(args[3]) then
					lDelay = args[3]
				end
				repeat
					if _IY_Players:FindFirstChild(v) then
						if _IY_Players[v].Character ~= nil then
							_IY_getRoot(_IY_lp.Character).CFrame = _IY_getRoot(_IY_Players[v].Character).CFrame + Vector3.new(distance,1,0)
						end
						wait(lDelay)
					else
						loopgoto = nil
					end
				until loopgoto ~= _IY_Players[v]
			end
		end
	},
	{
		name = "unloopgoto",
		desc = "Stop loop goto",
		aliases = {'noloopgoto'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			loopgoto = nil
		end
	},
	{
		name = "chat",
		desc = "Send chat message <message>",
		aliases = {'say'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local cString = getstring(1, args)
			chatMessage(cString)
		end
	},
	{
		name = "spam",
		desc = "Spam chat message <message>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			spamming = true
			local spamstring = getstring(1, args)
			repeat wait(spamspeed)
				chatMessage(spamstring)
			until spamming == false
		end
	},
	{
		name = "nospam",
		desc = "Stop chat spam",
		aliases = {'unspam'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			spamming = false
		end
	},
	{
		name = "whisper",
		desc = "Whisper to player <player message>",
		args = "<arg>",
		aliases = {'pm'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				task.spawn(function()
					local plrName = _IY_Players[v].Name
					local pmstring = getstring(2, args)
					chatMessage("/w "..plrName.." "..pmstring)
				end)
			end
		end
	},
	{
		name = "pmspam",
		desc = "Spam private messages <player message>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				task.spawn(function()
					local plrName = _IY_Players[v].Name
					if _IY_FindInTable(pmspamming, plrName) then return end
					table.insert(pmspamming, plrName)
					local pmspamstring = getstring(2, args)
					repeat
						if _IY_Players:FindFirstChild(v) then
							wait(spamspeed)
							chatMessage("/w "..plrName.." "..pmspamstring)
						else
							for a,b in pairs(pmspamming) do if b == plrName then table.remove(pmspamming, a) end end
						end
					until not _IY_FindInTable(pmspamming, plrName)
				end)
			end
		end
	},
	{
		name = "nopmspam",
		desc = "Stop PM spam",
		args = "<arg>",
		aliases = {'unpmspam'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				task.spawn(function()
					for a,b in pairs(pmspamming) do
						if b == _IY_Players[v].Name then
							table.remove(pmspamming, a)
						end
					end
				end)
			end
		end
	},
	{
		name = "spamspeed",
		desc = "Set spam speed <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local speed = args[1] or 1
			if isNumber(speed) then
				spamspeed = speed
			end
		end
	},
	{
		name = "bubblechat",
		desc = "Show bubble chat",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if isLegacyChat then
				ChatService.BubbleChatEnabled = true
			else
				TextChatService.BubbleChatConfiguration.Enabled = true
			end
		end
	},
	{
		name = "unbubblechat",
		desc = "Hide bubble chat",
		aliases = {'nobubblechat'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if isLegacyChat then
				ChatService.BubbleChatEnabled = false
			else
				TextChatService.BubbleChatConfiguration.Enabled = false
			end
		end
	},
	{
		name = "blockhead",
		desc = "Give block head accessory",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			_IY_lp.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
		end
	},
	{
		name = "blockhats",
		desc = "Block/hide hats on player <player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for _,v in pairs(_IY_lp.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
				for i,c in pairs(v:GetDescendants()) do
					if c:IsA("SpecialMesh") then
						c:Destroy()
					end
				end
			end
		end
	},
	{
		name = "blocktool",
		desc = "Block tools from equipping",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for _,v in pairs(_IY_lp.Character:GetChildren()) do
				if v:IsA("Tool") or v:IsA("HopperBin") then
					for i,c in pairs(v:GetDescendants()) do
						if c:IsA("SpecialMesh") then
							c:Destroy()
						end
					end
				end
			end
		end
	},
	{
		name = "creeper",
		desc = "Turn character into creeper shape",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			if r15(_IY_lp) then
				_IY_lp.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
				_IY_lp.Character.LeftUpperArm:Destroy()
				_IY_lp.Character.RightUpperArm:Destroy()
				_IY_lp.Character:FindFirstChildOfClass("Humanoid"):RemoveAccessories()
			else
				_IY_lp.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
				_IY_lp.Character["Left Arm"]:Destroy()
				_IY_lp.Character["Right Arm"]:Destroy()
				_IY_lp.Character:FindFirstChildOfClass("Humanoid"):RemoveAccessories()
			end
		end
	},
	{
		name = "carpet",
		desc = "Flatten character like carpet",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			if not r15(_IY_lp) then
				execCmd('uncarpet')
				wait()
				local players = _IY_getPlayer(args[1], _IY_lp)
				for i,v in pairs(players)do
					carpetAnim = Instance.new("Animation")
					carpetAnim.AnimationId = "rbxassetid://282574440"
					carpet = _IY_lp.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(carpetAnim)
					carpet:Play(.1, 1, 1)
					local carpetplr = _IY_Players[v].Name
					carpetDied = _IY_lp.Character:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
						carpetLoop:Disconnect()
						carpet:Stop()
						carpetAnim:Destroy()
						carpetDied:Disconnect()
					end)
					carpetLoop = _IY_RunService.Heartbeat:Connect((function()
						LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
						pcall(function()
							_IY_getRoot(_IY_lp.Character).CFrame = _IY_getRoot(_IY_Players[carpetplr].Character).CFrame
						end)
					end))
				end
			else
				_IY_notify('R6 Required','This command requires the r6 rig type')
			end
		end
	},
	{
		name = "uncarpet",
		desc = "Restore character from carpet",
		aliases = {'nocarpet'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if carpetLoop then
				carpetLoop:Disconnect()
				carpetDied:Disconnect()
				carpet:Stop()
				carpetAnim:Destroy()
			end
		end
	},
	{
		name = "friend",
		desc = "Send friend request <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				_IY_lp:RequestFriendship(_IY_Players[v])
			end
		end
	},
	{
		name = "unfriend",
		desc = "Unfriend player <player>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				_IY_lp:RevokeFriendship(_IY_Players[v])
			end
		end
	},
	{
		name = "bringpart",
		desc = "Teleport a part to you <name>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
					v.CFrame = _IY_getRoot(_IY_lp.Character).CFrame
				end
			end
		end
	},
	{
		name = "bringpartclass",
		desc = "Teleport parts of class to you <class>",
		aliases = {'bpc'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
					v.CFrame = _IY_getRoot(_IY_lp.Character).CFrame
				end
			end
		end
	},
	{
		name = "gotopart",
		desc = "Teleport to a part <name>",
		aliases = {'topart'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					wait(gotopartDelay)
					_IY_getRoot(_IY_lp.Character).CFrame = v.CFrame
				end
			end
		end
	},
	{
		name = "tweengotopart",
		desc = "Tween to a part <name>",
		aliases = {'tgotopart', 'ttopart'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					wait(gotopartDelay)
					_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v.CFrame}):Play()
				end
			end
		end
	},
	{
		name = "gotopartclass",
		desc = "Teleport to part class <class>",
		aliases = {'gpc'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					wait(gotopartDelay)
					_IY_getRoot(_IY_lp.Character).CFrame = v.CFrame
				end
			end
		end
	},
	{
		name = "tweengotopartclass",
		desc = "Tween to part class <class>",
		aliases = {'tgpc'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					wait(gotopartDelay)
					_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v.CFrame}):Play()
				end
			end
		end
	},
	{
		name = "gotomodel",
		desc = "Teleport to model <name>",
		aliases = {'tomodel'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.Name:lower() == getstring(1, args):lower() and v:IsA("Model") then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					wait(gotopartDelay)
					_IY_getRoot(_IY_lp.Character).CFrame = v:GetModelCFrame()
				end
			end
		end
	},
	{
		name = "tweengotomodel",
		desc = "Tween to model <name>",
		aliases = {'tgotomodel', 'ttomodel'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v.Name:lower() == getstring(1, args):lower() and v:IsA("Model") then
					if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
						_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
						wait(.1)
					end
					wait(gotopartDelay)
					_IY_TweenSvc:Create(_IY_getRoot(_IY_lp.Character), TweenInfo.new(_IY_tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v:GetModelCFrame()}):Play()
				end
			end
		end
	},
	{
		name = "gotopartdelay",
		desc = "Teleport to part after delay <delay name>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local gtpDelay = args[1] or 0.1
			if isNumber(gtpDelay) then
				gotopartDelay = gtpDelay
			end
		end
	},
	{
		name = "noclickdetectorlimits",
		desc = "Remove ClickDetector distance limits",
		aliases = {'nocdlimits', 'removecdlimits'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in ipairs(workspace:GetDescendants()) do
				if v:IsA("ClickDetector") then
					v.MaxActivationDistance = math.huge
				end
			end
		end
	},
	{
		name = "fireclickdetectors",
		desc = "Fire click detectors in radius",
		args = "<arg>",
		aliases = {'firecd', 'firecds'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if fireclickdetector then
				if args[1] then
					local name = getstring(1, args):lower()
					for _, descendant in ipairs(workspace:GetDescendants()) do
						if descendant:IsA("ClickDetector") and descendant.Name:lower() == name or descendant.Parent.Name:lower() == name then
							fireclickdetector(descendant)
						end
					end
				else
					for _, descendant in ipairs(workspace:GetDescendants()) do
						if descendant:IsA("ClickDetector") then
							fireclickdetector(descendant)
						end
					end
				end
			else
				_IY_notify("Incompatible Exploit", "Your exploit does not support this command (missing fireclickdetector)")
			end
		end
	},
	{
		name = "noproximitypromptlimits",
		desc = "Remove ProximityPrompt limits",
		aliases = {'nopplimits', 'removepplimits'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(workspace:GetDescendants()) do
				if v:IsA("ProximityPrompt") then
					v.MaxActivationDistance = math.huge
				end
			end
		end
	},
	{
		name = "fireproximityprompts",
		desc = "Fire all ProximityPrompts",
		args = "<arg>",
		aliases = {'firepp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if fireproximityprompt then
				if args[1] then
					local name = getstring(1, args)
					for _, descendant in ipairs(workspace:GetDescendants()) do
						if descendant:IsA("ProximityPrompt") and descendant.Name == name or descendant.Parent.Name == name then
							fireproximityprompt(descendant)
						end
					end
				else
					for _, descendant in ipairs(workspace:GetDescendants()) do
						if descendant:IsA("ProximityPrompt") then
							fireproximityprompt(descendant)
						end
					end
				end
			else
				_IY_notify("Incompatible Exploit", "Your exploit does not support this command (missing fireproximityprompt)")
			end
		end
	},
	{
		name = "instantproximityprompts",
		desc = "Make ProximityPrompts instant",
		aliases = {'instantpp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if fireproximityprompt then
				execCmd("uninstantproximityprompts")
				wait(0.1)
				PromptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
					fireproximityprompt(prompt)
				end)
			else
				_IY_notify('Incompatible Exploit','Your exploit does not support this command (missing fireproximityprompt)')
			end
		end
	},
	{
		name = "uninstantproximityprompts",
		desc = "Restore ProximityPrompt hold times",
		aliases = {'uninstantpp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if PromptButtonHoldBegan ~= nil then
				PromptButtonHoldBegan:Disconnect()
				PromptButtonHoldBegan = nil
			end
		end
	},
	{
		name = "notifyping",
		desc = "Notify current ping",
		aliases = {'ping'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_notify("Ping", math.round(_IY_lp:GetNetworkPing() * 1000) .. "ms")
		end
	},
	{
		name = "grabtools",
		desc = "Grab tools from workspace parts",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local humanoid = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
			for _, child in ipairs(workspace:GetChildren()) do
				if _IY_lp.Character and child:IsA("BackpackItem") and child:FindFirstChild("Handle") then
					humanoid:EquipTool(child)
				end
			end
			if grabtoolsFunc then
				grabtoolsFunc:Disconnect()
			end
			grabtoolsFunc = workspace.ChildAdded:Connect(function(child)
				if _IY_lp.Character and child:IsA("BackpackItem") and child:FindFirstChild("Handle") then
					humanoid:EquipTool(child)
				end
			end)
			_IY_notify("Grabtools", "Picking up any dropped tools")
		end
	},
	{
		name = "nograbtools",
		desc = "Remove grabbed tools",
		aliases = {'ungrabtools'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if grabtoolsFunc then
				grabtoolsFunc:Disconnect()
			end
			_IY_notify("Grabtools", "Grabtools has been disabled")
		end
	},
	{
		name = "removespecifictool",
		desc = "Remove a specific tool <name>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if args[1] and _IY_lp:FindFirstChildOfClass("Backpack") then
				local tool = string.lower(getstring(1, args))
				local RST = _IY_RunService.RenderStepped:Connect((function()
					LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
					if _IY_lp:FindFirstChildOfClass("Backpack") then
						for i,v in pairs(_IY_lp:FindFirstChildOfClass("Backpack"):GetChildren()) do
							if v.Name:lower() == tool then
								v:Remove()
							end
						end
					end
				end))
				specifictoolremoval[tool] = RST
			end
		end
	},
	{
		name = "unremovespecifictool",
		desc = "Restore specific tool removal",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if args[1] then
				local tool = string.lower(getstring(1, args))
				if specifictoolremoval[tool] ~= nil then
					specifictoolremoval[tool]:Disconnect()
					specifictoolremoval[tool] = nil
				end
			end
		end
	},
	{
		name = "clearremovespecifictool",
		desc = "Clear specific tool removal list",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for obj in pairs(specifictoolremoval) do
				specifictoolremoval[obj]:Disconnect()
				specifictoolremoval[obj] = nil
			end
		end
	},
	{
		name = "light",
		desc = "Attach a light to character",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local light = Instance.new("PointLight")
			light.Parent = _IY_getRoot(_IY_lp.Character)
			light.Range = 30
			if args[1] then
				light.Brightness = args[2]
				light.Range = args[1]
			else
				light.Brightness = 5
			end
		end
	},
	{
		name = "unlight",
		desc = "Remove attached light",
		aliases = {'nolight'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v.ClassName == "PointLight" then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "copytools",
		desc = "Copy all backpack tools to a temp folder",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
			local players = _IY_getPlayer(args[1], _IY_lp)
			for i,v in pairs(players)do
				task.spawn(function()
					for i,v in pairs(_IY_Players[v]:FindFirstChildOfClass("Backpack"):GetChildren()) do
						if v:IsA('Tool') or v:IsA('HopperBin') then
							v:Clone().Parent = _IY_lp:FindFirstChildOfClass("Backpack")
						end
					end
				end)
			end
		end
	},
	{
		name = "naked",
		desc = "Remove all accessories",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v:IsA("Clothing") or v:IsA("ShirtGraphic") then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "noface",
		desc = "Remove face accessory",
		aliases = {'removeface'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			for i,v in pairs(_IY_lp.Character:GetDescendants()) do
				if v:IsA("Decal") and v.Name == 'face' then
					v:Destroy()
				end
			end
		end
	},
	{
		name = "spawnpoint",
		desc = "Set respawn location at current position",
		args = "<arg>",
		aliases = {'spawn'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			spawnpos = _IY_getRoot(_IY_lp.Character).CFrame
			spawnpoint = true
			spDelay = tonumber(args[1]) or 0.1
			_IY_notify('Spawn Point','Spawn point created at '..tostring(spawnpos))
		end
	},
	{
		name = "nospawnpoint",
		desc = "Remove custom spawn point",
		aliases = {'nospawn', 'removespawnpoint'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			spawnpoint = false
			_IY_notify('Spawn Point','Removed spawn point')
		end
	},
	{
		name = "flashback",
		desc = "Teleport back to where you last died",
		aliases = {'diedtp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if lastDeath ~= nil then
				if _IY_lp.Character:FindFirstChildOfClass('Humanoid') and _IY_lp.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					_IY_lp.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				_IY_getRoot(_IY_lp.Character).CFrame = lastDeath
			end
		end
	},
	{
		name = "hatspin",
		desc = "Spin all hats/accessories",
		args = "<arg>",
		aliases = {'spinhats'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			execCmd('unhatspin')
			wait(.5)
			for _,v in pairs(_IY_lp.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
				local keep = Instance.new("BodyPosition") keep.Name = randomString() keep.Parent = v.Handle
				local spin = Instance.new("BodyAngularVelocity") spin.Name = randomString() spin.Parent = v.Handle
				v.Handle:FindFirstChildOfClass("Weld"):Destroy()
				if args[1] then
					spin.AngularVelocity = Vector3.new(0, args[1], 0)
					spin.MaxTorque = Vector3.new(0, args[1] * 2, 0)
				else
					spin.AngularVelocity = Vector3.new(0, 100, 0)
					spin.MaxTorque = Vector3.new(0, 200, 0)
				end
				keep.P = 30000
				keep.D = 50
				spinhats = _IY_RunService.Stepped:Connect((function()
					LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
					pcall(function()
						keep.Position = _IY_lp.Character.Head.Position
					end)
				end))
			end
		end
	},
	{
		name = "unhatspin",
		desc = "Stop hat spinning",
		aliases = {'unspinhats'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if spinhats then
		spinhats:Disconnect()
	end
	for _,v in pairs(_IY_lp.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
		v.Parent = workspace
		for i,c in pairs(v.Handle) do
			if c:IsA("BodyPosition") or c:IsA("BodyAngularVelocity") then
				c:Destroy()
			end
		end
		wait()
		v.Parent = _IY_lp.Character
	end
		end
	},
	{
		name = "clearhats",
		desc = "Remove all hats and accessories",
		aliases = {'cleanhats'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if firetouchinterest then
		local Player = _IY_lp
		local Character = Player.Character
		local Old = _IY_getRoot(Character).CFrame
		local Hats = {}
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Accessory") then
				table.insert(Hats, child)
			end
		end
		for _, accessory in ipairs(Character:FindFirstChildOfClass("Humanoid"):GetAccessories()) do
			accessory:Destroy()
		end
		for i = 1, #Hats do
			repeat _IY_RunService.Heartbeat:wait() until Hats[i]
			firetouchinterest(Hats[i].Handle,_IY_getRoot(Character),0)
			repeat _IY_RunService.Heartbeat:wait() until Character:FindFirstChildOfClass("Accessory")
			Character:FindFirstChildOfClass("Accessory"):Destroy()
			repeat _IY_RunService.Heartbeat:wait() until not Character:FindFirstChildOfClass("Accessory")
		end
		execCmd("reset")
		Player.CharacterAdded:Wait()
		for i = 1,20 do
			_IY_RunService.Heartbeat:Wait()
			if _IY_getRoot(Player.Character) then
				_IY_getRoot(Player.Character).Humanoid.RootPart.CFrame = Old
			end
		end
	else
		_IY_notify("Incompatible Exploit","Your exploit does not support this command (missing firetouchinterest)")
	end
		end
	},
	{
		name = "split",
		desc = "Split into multiple body parts",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if r15(_IY_lp) then
		_IY_lp.Character.UpperTorso.Waist:Destroy()
	else
		_IY_notify('R15 Required','This command requires the r15 rig type')
	end
		end
	},
	{
		name = "nilchar",
		desc = "Move character to nil",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if _IY_lp.Character ~= nil then
		_IY_lp.Character.Parent = nil
	end
		end
	},
	{
		name = "unnilchar",
		desc = "Restore character from nil",
		aliases = {'nonilchar'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if _IY_lp.Character ~= nil then
		_IY_lp.Character.Parent = workspace
	end
		end
	},
	{
		name = "noroot",
		desc = "Remove HumanoidRootPart",
		aliases = {'removeroot', 'rroot'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if _IY_lp.Character ~= nil then
		local char = _IY_lp.Character
		char.Parent = nil
		char.Humanoid.RootPart:Destroy()
		char.Parent = workspace
	end
		end
	},
	{
		name = "replaceroot",
		desc = "Replace HumanoidRootPart",
		aliases = {'replacerootpart'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if _IY_lp.Character ~= nil and _IY_getRoot(_IY_lp.Character) then
		local Char = _IY_lp.Character
		local OldParent = Char.Parent
		local HRP = Char and _IY_getRoot(Char)
		local OldPos = HRP.CFrame
		Char.Parent = game
		local HRP1 = HRP:Clone()
		HRP1.Parent = Char
		HRP = HRP:Destroy()
		HRP1.CFrame = OldPos
		Char.Parent = OldParent
	end
		end
	},
	{
		name = "clearcharappearance",
		desc = "Clear character appearance",
		aliases = {'clearchar', 'clrchar'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp:ClearCharacterAppearance()
		end
	},
	{
		name = "equiptools",
		desc = "Equip tools from backpack",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for i,v in pairs(_IY_lp:FindFirstChildOfClass("Backpack"):GetChildren()) do
		if v:IsA("Tool") or v:IsA("HopperBin") then
			v.Parent = _IY_lp.Character
		end
	end
		end
	},
	{
		name = "unequiptools",
		desc = "Unequip all tools",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
		end
	},
	{
		name = "dupetools",
		desc = "Duplicate all tools in backpack",
		args = "<arg>",
		aliases = {'clonetools'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local LOOP_NUM = tonumber(args[1]) or 1
	local OrigPos = _IY_lp.Character.Humanoid.RootPart.Position
	local Tools, TempPos = {}, Vector3.new(math.random(-2e5, 2e5), 2e5, math.random(-2e5, 2e5))
	for i = 1, LOOP_NUM do
		local Human = _IY_lp.Character:WaitForChild("Humanoid")
		wait(.1, Human.Parent:MoveTo(TempPos))
		Human.RootPart.Anchored = _IY_lp:ClearCharacterAppearance(wait(.1)) or true
		local t = GetHandleTools(_IY_lp)
		while #t > 0 do
			for _, v in ipairs(t) do
				task.spawn(function()
					for _ = 1, 25 do
						v.Parent = _IY_lp.Character
						v.Handle.Anchored = true
					end
					for _ = 1, 5 do
						v.Parent = workspace
					end
					table.insert(Tools, v.Handle)
				end)
			end
			t = GetHandleTools(_IY_lp)
		end
		wait(.1)
		_IY_lp.Character = _IY_lp.Character:Destroy()
		_IY_lp.CharacterAdded:Wait():WaitForChild("Humanoid").Parent:MoveTo(LOOP_NUM == i and OrigPos or TempPos, wait(.1))
		if i == LOOP_NUM or i % 5 == 0 then
			local HRP = _IY_lp.Character.Humanoid.RootPart
			if type(firetouchinterest) == "function" then
				for _, v in ipairs(Tools) do
					v.Anchored = not firetouchinterest(v, HRP, 1, firetouchinterest(v, HRP, 0)) and false or false
				end
			else
				for _, v in ipairs(Tools) do
					task.spawn(function()
						local x = v.CanCollide
						v.CanCollide = false
						v.Anchored = false
						for _ = 1, 10 do
							v.CFrame = HRP.CFrame
							wait()
						end
						v.CanCollide = x
					end)
				end
			end
			wait(.1)
			Tools = {}
		end
		TempPos = TempPos + Vector3.new(10, math.random(-5, 5), 0)
	end
		end
	},
	{
		name = "touchinterests",
		desc = "Fire touch events on parts",
		args = "<arg>",
		aliases = {'touchinterest', 'firetouchinterests', 'firetouchinterest'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local Root = _IY_getRoot(_IY_lp.Character) or _IY_lp.Character:FindFirstChildWhichIsA("BasePart")
	if not firetouchinterest then
		_IY_notify("Incompatible Exploit", "Your exploit does not support this command (missing firetouchinterest)")
		return
	end
	local function Touch(x)
		x = x.FindFirstAncestorWhichIsA(x, "Part")
		if x then
			return task.spawn(function()
				firetouchinterest(x, Root, 1, wait() and firetouchinterest(x, Root, 0))
			end)
		end
		x.CFrame = Root.CFrame
	end
	if args[1] then
		local name = getstring(1, args):lower()
		print(name..' -name')
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("TouchTransmitter") and v.Name:lower() == name or v.Parent.Name:lower() == name then
				Touch(v)
			end
		end
	else
		for _, v in ipairs(workspace:GetDescendants()) do
			if v.IsA(v, "TouchTransmitter") then
				Touch(v)
			end
		end
	end
		end
	},
	{
		name = "fullbright",
		desc = "Set lighting to fullbright",
		aliases = {'fb', 'fullbrightness'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 100000
	Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		end
	},
	{
		name = "loopfullbright",
		desc = "Loop fullbright",
		aliases = {'loopfb'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if brightLoop then
		brightLoop:Disconnect()
	end
	local function brightFunc()
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end
	brightFunc()
	brightLoop = Lighting.Changed:Connect(brightFunc)
		end
	},
	{
		name = "unloopfullbright",
		desc = "Stop loop fullbright",
		aliases = {'unloopfb'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if brightLoop then
		brightLoop:Disconnect()
	end
		end
	},
	{
		name = "ambient",
		desc = "Set ambient color <r g b>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.Ambient = Color3.new(args[1],args[2],args[3])
	Lighting.OutdoorAmbient = Color3.new(args[1],args[2],args[3])
		end
	},
	{
		name = "day",
		desc = "Set time to daytime",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.ClockTime = 14
		end
	},
	{
		name = "night",
		desc = "Set time to nighttime",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.ClockTime = 0
		end
	},
	{
		name = "nofog",
		desc = "Remove fog from lighting",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.FogEnd = 100000
	for i,v in pairs(Lighting:GetDescendants()) do
		if v:IsA("Atmosphere") then
			v:Destroy()
		end
	end
		end
	},
	{
		name = "brightness",
		desc = "Set lighting brightness <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.Brightness = args[1]
		end
	},
	{
		name = "globalshadows",
		desc = "Enable global shadows",
		aliases = {'gshadows'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.GlobalShadows = true
		end
	},
	{
		name = "unglobalshadows",
		desc = "Disable global shadows",
		aliases = {'nogshadows', 'ungshadows', 'noglobalshadows'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.GlobalShadows = false
		end
	},
	{
		name = "restorelighting",
		desc = "Restore default lighting",
		aliases = {'rlighting'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	Lighting.Ambient = origsettings.abt
	Lighting.OutdoorAmbient = origsettings.oabt
	Lighting.Brightness = origsettings.brt
	Lighting.ClockTime = origsettings.time
	Lighting.FogEnd = origsettings.fe
	Lighting.FogStart = origsettings.fs
	Lighting.GlobalShadows = origsettings.gs
		end
	},
	{
		name = "stun",
		desc = "Enable platform stand",
		aliases = {'platformstand'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
		end
	},
	{
		name = "unstun",
		desc = "Disable platform stand",
		aliases = {'nostun', 'unplatformstand', 'noplatformstand'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
		end
	},
	{
		name = "norotate",
		desc = "Disable auto-rotate",
		aliases = {'noautorotate'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildOfClass('Humanoid').AutoRotate  = false
		end
	},
	{
		name = "unnorotate",
		desc = "Re-enable auto-rotate",
		aliases = {'autorotate'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildOfClass('Humanoid').AutoRotate  = true
		end
	},
	{
		name = "enablestate",
		desc = "Enable humanoid state <state>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local x = args[1]
	if not tonumber(x) then
		local x = Enum.HumanoidStateType[args[1]]
	end
	_IY_lp.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(x, true)
		end
	},
	{
		name = "disablestate",
		desc = "Disable humanoid state <state>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local x = args[1]
	if not tonumber(x) then
		local x = Enum.HumanoidStateType[args[1]]
	end
	_IY_lp.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(x, false)
		end
	},
	{
		name = "drophats",
		desc = "Drop hats to workspace",
		aliases = {'drophat'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if _IY_lp.Character then
		for _,v in pairs(_IY_lp.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
			v.Parent = workspace
		end
	end
		end
	},
	{
		name = "deletehats",
		desc = "Delete all hats",
		aliases = {'nohats', 'rhats'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for i,v in next, _IY_lp.Character:GetDescendants() do
		if v:IsA("Accessory") then
			for i,p in next, v:GetDescendants() do
				if p:IsA("Weld") then
					p:Destroy()
				end
			end
		end
	end
		end
	},
	{
		name = "droptools",
		desc = "Drop tools to workspace",
		aliases = {'droptool'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for i,v in pairs(_IY_lp.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = _IY_lp.Character
		end
	end
	wait()
	for i,v in pairs(_IY_lp.Character:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = workspace
		end
	end
		end
	},
	{
		name = "droppabletools",
		desc = "Make tools droppable",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if _IY_lp.Character then
		for _,obj in pairs(_IY_lp.Character:GetChildren()) do
			if obj:IsA("Tool") then
				obj.CanBeDropped = true
			end
		end
	end
	if _IY_lp:FindFirstChildOfClass("Backpack") then
		for _,obj in pairs(_IY_lp:FindFirstChildOfClass("Backpack"):GetChildren()) do
			if obj:IsA("Tool") then
				obj.CanBeDropped = true
			end
		end
	end
		end
	},
	{
		name = "reach",
		desc = "Enable reach (extended hit range) <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	execCmd('unreach')
	wait()
	for i,v in pairs(_IY_lp.Character:GetDescendants()) do
		if v:IsA("Tool") then
			if args[1] then
				currentToolSize = v.Handle.Size
				currentGripPos = v.GripPos
				local a = Instance.new("SelectionBox")
				a.Name = "SelectionBoxCreated"
				a.Parent = v.Handle
				a.Adornee = v.Handle
				v.Handle.Massless = true
				v.Handle.Size = Vector3.new(0.5,0.5,args[1])
				v.GripPos = Vector3.new(0,0,0)
				_IY_lp.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
			else
				currentToolSize = v.Handle.Size
				currentGripPos = v.GripPos
				local a = Instance.new("SelectionBox")
				a.Name = "SelectionBoxCreated"
				a.Parent = v.Handle
				a.Adornee = v.Handle
				v.Handle.Massless = true
				v.Handle.Size = Vector3.new(0.5,0.5,60)
				v.GripPos = Vector3.new(0,0,0)
				_IY_lp.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
			end
		end
	end
		end
	},
	{
		name = "unreach",
		desc = "Disable reach",
		aliases = {'noreach', 'unboxreach'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for i,v in pairs(_IY_lp.Character:GetDescendants()) do
		if v:IsA("Tool") then
			v.Handle.Size = currentToolSize
			v.GripPos = currentGripPos
			v.Handle.SelectionBoxCreated:Destroy()
		end
	end
		end
	},
	{
		name = "grippos",
		desc = "Set tool grip position <x y z>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for i,v in pairs(_IY_lp.Character:GetDescendants()) do
		if v:IsA("Tool") then
			v.Parent = _IY_lp:FindFirstChildOfClass("Backpack")
			v.GripPos = Vector3.new(args[1],args[2],args[3])
			v.Parent = _IY_lp.Character
		end
	end
		end
	},
	{
		name = "usetools",
		desc = "Use/activate equipped tools",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local Backpack = _IY_lp:FindFirstChildOfClass("Backpack")
	local amount = tonumber(args[1]) or 1
	local delay_ = tonumber(args[2]) or false
	for _, v in ipairs(Backpack:GetChildren()) do
		v.Parent = _IY_lp.Character
		task.spawn(function()
			for _ = 1, amount do
				v:Activate()
				if delay_ then
					wait(delay_)
				end
			end
			v.Parent = Backpack
		end)
	end
		end
	},
	{
		name = "fling",
		desc = "Fling a player <player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	flinging = false
	for _, child in pairs(_IY_lp.Character:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
		end
	end
	execCmd('noclip')
	wait(.1)
	local bambam = Instance.new("BodyAngularVelocity")
	bambam.Name = randomString()
	bambam.Parent = _IY_getRoot(_IY_lp.Character)
	bambam.AngularVelocity = Vector3.new(0,99999,0)
	bambam.MaxTorque = Vector3.new(0,math.huge,0)
	bambam.P = math.huge
	local Char = _IY_lp.Character:GetChildren()
	for i, v in next, Char do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
			v.Velocity = Vector3.new(0, 0, 0)
		end
	end
	flinging = true
	local function flingDiedF()
		execCmd('unfling')
	end
	flingDied = _IY_lp.Character:FindFirstChildOfClass('Humanoid').Died:Connect(flingDiedF)
	repeat
		bambam.AngularVelocity = Vector3.new(0,99999,0)
		wait(.2)
		bambam.AngularVelocity = Vector3.new(0,0,0)
		wait(.1)
	until flinging == false
		end
	},
	{
		name = "unfling",
		desc = "Stop flinging <player>",
		aliases = {'nofling'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	execCmd('clip')
	if flingDied then
		flingDied:Disconnect()
	end
	flinging = false
	wait(.1)
	local speakerChar = _IY_lp.Character
	if not speakerChar or not _IY_getRoot(speakerChar) then return end
	for i,v in pairs(_IY_getRoot(speakerChar):GetChildren()) do
		if v.ClassName == 'BodyAngularVelocity' then
			v:Destroy()
		end
	end
	for _, child in pairs(speakerChar:GetDescendants()) do
		if child.ClassName == "Part" or child.ClassName == "MeshPart" then
			child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
		end
	end
		end
	},
	{
		name = "togglefling",
		desc = "Toggle fling on player <player>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if flinging then
		execCmd('unfling')
	else
		execCmd('fling')
	end
		end
	},
	{
		name = "invisfling",
		desc = "Fling invisibly",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
	local ch = _IY_lp.Character
	ch:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local prt=Instance.new("Model")
	prt.Parent = _IY_lp.Character
	local z1 = Instance.new("Part")
	z1.Name="Torso"
	z1.CanCollide = false
	z1.Anchored = true
	local z2 = Instance.new("Part")
	z2.Name="Head"
	z2.Parent = prt
	z2.Anchored = true
	z2.CanCollide = false
	local z3 =Instance.new("Humanoid")
	z3.Name="Humanoid"
	z3.Parent = prt
	z1.Position = Vector3.new(0,9999,0)
	_IY_lp.Character=prt
	wait(3)
	_IY_lp.Character=ch
	wait(3)
	local Hum = Instance.new("Humanoid")
	z2:Clone()
	Hum.Parent = _IY_lp.Character
	local root =  _IY_getRoot(_IY_lp.Character)
	for i,v in pairs(_IY_lp.Character:GetChildren()) do
		if v ~= root and  v.Name ~= "Humanoid" then
			v:Destroy()
		end
	end
	root.Transparency = 0
	root.Color = Color3.new(1, 1, 1)
	local invisflingStepped
	invisflingStepped = _IY_RunService.Stepped:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if _IY_lp.Character and _IY_getRoot(_IY_lp.Character) then
			_IY_getRoot(_IY_lp.Character).CanCollide = false
		else
			invisflingStepped:Disconnect()
		end
	end))
	sFLY()
	workspace.CurrentCamera.CameraSubject = root
	local bambam = Instance.new("BodyThrust")
	bambam.Parent = _IY_getRoot(_IY_lp.Character)
	bambam.Force = Vector3.new(99999,99999*10,99999)
	bambam.Location = _IY_getRoot(_IY_lp.Character).Position
		end
	},
	{
		name = "spin",
		desc = "Spin character rapidly",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local spinSpeed = 20
	if args[1] and isNumber(args[1]) then
		spinSpeed = args[1]
	end
	for i,v in pairs(_IY_getRoot(_IY_lp.Character):GetChildren()) do
		if v.Name == "Spinning" then
			v:Destroy()
		end
	end
	local Spin = Instance.new("BodyAngularVelocity")
	Spin.Name = "Spinning"
	Spin.Parent = _IY_getRoot(_IY_lp.Character)
	Spin.MaxTorque = Vector3.new(0, math.huge, 0)
	Spin.AngularVelocity = Vector3.new(0,spinSpeed,0)
		end
	},
	{
		name = "unspin",
		desc = "Stop spinning",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for i,v in pairs(_IY_getRoot(_IY_lp.Character):GetChildren()) do
		if v.Name == "Spinning" then
			v:Destroy()
		end
	end
		end
	},
	{
		name = "walltp",
		desc = "Teleport through walls by clicking",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local torso
	if r15(_IY_lp) then
		torso = _IY_lp.Character.UpperTorso
	else
		torso = _IY_lp.Character.Torso
	end
	local function touchedFunc(hit)
		local Root = _IY_getRoot(_IY_lp.Character)
		if hit:IsA("BasePart") and hit.Position.Y > Root.Position.Y - _IY_lp.Character:FindFirstChildOfClass('Humanoid').HipHeight then
			local hitP = _IY_getRoot(hit.Parent)
			if hitP ~= nil then
				Root.CFrame = hit.CFrame * CFrame.new(Root.CFrame.lookVector.X,hitP.Size.Z/2 + _IY_lp.Character:FindFirstChildOfClass('Humanoid').HipHeight,Root.CFrame.lookVector.Z)
			elseif hitP == nil then
				Root.CFrame = hit.CFrame * CFrame.new(Root.CFrame.lookVector.X,hit.Size.Y/2 + _IY_lp.Character:FindFirstChildOfClass('Humanoid').HipHeight,Root.CFrame.lookVector.Z)
			end
		end
	end
	walltpTouch = torso.Touched:Connect(touchedFunc)
		end
	},
	{
		name = "unwalltp",
		desc = "Stop wall teleport mode",
		aliases = {'nowalltp'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if walltpTouch then
		walltpTouch:Disconnect()
	end
		end
	},
	{
		name = "autoclick",
		desc = "Auto-click mouse at interval <delay>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if mouse1press and mouse1release then
		execCmd('unautoclick')
		wait()
		local clickDelay = 0.1
		local releaseDelay = 0.1
		if args[1] and isNumber(args[1]) then clickDelay = args[1] end
		if args[2] and isNumber(args[2]) then releaseDelay = args[2] end
		autoclicking = true
		cancelAutoClick = _IY_UIS.InputBegan:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				if (input.KeyCode == Enum.KeyCode.Backspace and _IY_UIS:IsKeyDown(Enum.KeyCode.Equals)) or (input.KeyCode == Enum.KeyCode.Equals and _IY_UIS:IsKeyDown(Enum.KeyCode.Backspace)) then
					autoclicking = false
					cancelAutoClick:Disconnect()
				end
			end
		end)
		_IY_notify('Auto Clicker',"Press [backspace] and [=] at the same time to stop")
		repeat wait(clickDelay)
			mouse1press()
			wait(releaseDelay)
			mouse1release()
		until autoclicking == false
	else
		_IY_notify('Auto Clicker',"Your exploit doesn't have the ability to use the autoclick")
	end
		end
	},
	{
		name = "unautoclick",
		desc = "Stop auto-click",
		aliases = {'noautoclick'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	autoclicking = false
	if cancelAutoClick then cancelAutoClick:Disconnect() end
		end
	},
	{
		name = "mousesensitivity",
		desc = "Set mouse sensitivity <value>",
		args = "<arg>",
		aliases = {'ms'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_UIS.MouseDeltaSensitivity = args[1]
		end
	},
	{
		name = "hovername",
		desc = "Show player name on hover",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	execCmd('unhovername')
	wait()
	nameBox = Instance.new("TextLabel")
	nameBox.Name = randomString()
	nameBox.Parent = ScaledHolder
	nameBox.BackgroundTransparency = 1
	nameBox.Size = UDim2.new(0,200,0,30)
	nameBox.Font = Enum.Font.Code
	nameBox.TextSize = 16
	nameBox.Text = ""
	nameBox.TextColor3 = Color3.new(1, 1, 1)
	nameBox.TextStrokeTransparency = 0
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.ZIndex = 10
	nbSelection = Instance.new('SelectionBox')
	nbSelection.Name = randomString()
	nbSelection.LineThickness = 0.03
	nbSelection.Color3 = Color3.new(1, 1, 1)
	local updateNameBox = (function()
		local t
		local mouse = pcall(function() return _IY_lp:GetMouse() end) and _IY_lp:GetMouse()
		local target = mouse and mouse.Target
		if target then
			local humanoid = target.Parent:FindFirstChildOfClass("Humanoid") or target.Parent.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				t = humanoid.Parent
			end
		end
		if t ~= nil then
			local mouseX = mouse and mouse.X or 0
			local mouseY = mouse and mouse.Y or 0
			local xP
			if mouseX > 200 then
				xP = mouseX - 205
				nameBox.TextXAlignment = Enum.TextXAlignment.Right
			else
				xP = mouseX + 25
				nameBox.TextXAlignment = Enum.TextXAlignment.Left
			end
			nameBox.Position = UDim2.new(0, xP, 0, mouseY)
			nameBox.Text = t.Name
			nameBox.Visible = true
			nbSelection.Parent = t
			nbSelection.Adornee = t
		else
			nameBox.Visible = false
			nbSelection.Parent = nil
			nbSelection.Adornee = nil
		end
	end)
	nbUpdateFunc = _IY_RunService.RenderStepped:Connect(updateNameBox)
		end
	},
	{
		name = "unhovername",
		desc = "Hide hover name",
		aliases = {'nohovername'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if nbUpdateFunc then
		nbUpdateFunc:Disconnect()
		nameBox:Destroy()
		nbSelection:Destroy()
	end
		end
	},
	{
		name = "headsize",
		desc = "Set head size <value>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
	local players = _IY_getPlayer(args[1], _IY_lp)
	for i,v in pairs(players) do
		if _IY_Players[v] ~= _IY_lp and _IY_Players[v].Character:FindFirstChild('Head') then
			local sizeArg = tonumber(args[2])
			local Size = Vector3.new(sizeArg,sizeArg,sizeArg)
			local Head = _IY_Players[v].Character:FindFirstChild('Head')
			if Head:IsA("BasePart") then
				Head.CanCollide = false
				if not args[2] or sizeArg == 1 then
					Head.Size = Vector3.new(2,1,1)
				else
					Head.Size = Size
				end
			end
		end
	end
		end
	},
	{
		name = "hitbox",
		desc = "Expand character hitbox <size>",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
	local players = _IY_getPlayer(args[1], _IY_lp)
	local transparency = args[3] and tonumber(args[3]) or 0.4
	for i,v in pairs(players) do
		if _IY_Players[v] ~= _IY_lp and _IY_getRoot(_IY_Players[v].Character) then
			local sizeArg = tonumber(args[2])
			local Size = Vector3.new(sizeArg,sizeArg,sizeArg)
			local Root = _IY_getRoot(_IY_Players[v].Character)
			if Root:IsA("BasePart") then
				Root.CanCollide = false
				if not args[2] or sizeArg == 1 then
					Root.Size = Vector3.new(2,1,1)
					Root.Transparency = transparency
				else
					Root.Size = Size
					Root.Transparency = transparency
				end
			end
		end
	end
		end
	},
	{
		name = "stareat",
		desc = "Stare at player <player>",
		args = "<arg>",
		aliases = {'stare'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
	local players = _IY_getPlayer(args[1], _IY_lp)
	for i,v in pairs(players) do
		if stareLoop then
			stareLoop:Disconnect()
		end
		if not _IY_getRoot(_IY_lp.Character) and _IY_getRoot(_IY_Players[v].Character) then return end
		local stareFunc = (function()
			if _IY_lp.Character.PrimaryPart and _IY_Players:FindFirstChild(v) and _IY_Players[v].Character ~= nil and _IY_getRoot(_IY_Players[v].Character) then
				local chrPos=_IY_lp.Character.PrimaryPart.Position
				local tPos=_IY_getRoot(_IY_Players[v].Character).Position
				local modTPos=Vector3.new(tPos.X,chrPos.Y,tPos.Z)
				local newCF=CFrame.new(chrPos,modTPos)
				_IY_lp.Character:SetPrimaryPartCFrame(newCF)
			elseif not _IY_Players:FindFirstChild(v) then
				stareLoop:Disconnect()
			end
		end)
		stareLoop = _IY_RunService.RenderStepped:Connect(stareFunc)
	end
		end
	},
	{
		name = "unstareat",
		desc = "Stop staring",
		aliases = {'unstare', 'nostare', 'nostareat'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if stareLoop then
		stareLoop:Disconnect()
	end
		end
	},
	{
		name = "removeterrain",
		desc = "Remove all terrain",
		aliases = {'rterrain', 'noterrain'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	workspace:FindFirstChildOfClass('Terrain'):Clear()
		end
	},
	{
		name = "clearnilinstances",
		desc = "Remove instances with nil parents",
		aliases = {'nonilinstances', 'cni'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if getnilinstances then
		for i,v in pairs(getnilinstances()) do
			v:Destroy()
		end
	else
		_IY_notify('Incompatible Exploit','Your exploit does not support this command (missing getnilinstances)')
	end
		end
	},
	{
		name = "destroyheight",
		desc = "Destroy parts below height <y>",
		args = "<arg>",
		aliases = {'dh'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
	local dh = args[1] or -500
	if isNumber(dh) then
		workspace.FallenPartsDestroyHeight = dh
	end
		end
	},
	{
		name = "freezeunanchored",
		desc = "Freeze all unanchored parts",
		aliases = {'freezeua'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local badnames = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"RightUpperArm",
		"LeftUpperArm",
		"RightLowerArm",
		"LeftLowerArm",
		"RightHand",
		"LeftHand",
		"RightUpperLeg",
		"LeftUpperLeg",
		"RightLowerLeg",
		"LeftLowerLeg",
		"RightFoot",
		"LeftFoot",
		"Torso",
		"Right Arm",
		"Left Arm",
		"Right Leg",
		"Left Leg",
		"HumanoidRootPart"
	}
	local function FREEZENOOB(v)
		if v:IsA("BasePart" or "UnionOperation") and v.Anchored == false then
			local BADD = false
			for i = 1,#badnames do
				if v.Name == badnames[i] then
					BADD = true
				end
			end
			if _IY_lp.Character and v:IsDescendantOf(_IY_lp.Character) then
				BADD = true
			end
			if BADD == false then
				for i,c in pairs(v:GetChildren()) do
					if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
						c:Destroy()
					end
				end
				local bodypos = Instance.new("BodyPosition")
				bodypos.Parent = v
				bodypos.Position = v.Position
				bodypos.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
				local bodygyro = Instance.new("BodyGyro")
				bodygyro.Parent = v
				bodygyro.CFrame = v.CFrame
				bodygyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
				if not table.find(_IY_frozenParts,v) then
					table.insert(_IY_frozenParts,v)
				end
			end
		end
	end
	for i,v in pairs(workspace:GetDescendants()) do
		FREEZENOOB(v)
	end
	freezingua = workspace.DescendantAdded:Connect(FREEZENOOB)
		end
	},
	{
		name = "thawunanchored",
		desc = "Unfreeze all unanchored parts",
		aliases = {'thawua', 'unfreezeunanchored', 'unfreezeua'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if freezingua then
		freezingua:Disconnect()
	end
	for i,v in pairs(_IY_frozenParts) do
		for i,c in pairs(v:GetChildren()) do
			if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
				c:Destroy()
			end
		end
	end
	_IY_frozenParts = {}
		end
	},
	{
		name = "tpunanchored",
		desc = "Teleport unanchored parts to position <x y z>",
		args = "<arg>",
		aliases = {'tpua'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			local _ = speaker
	local players = _IY_getPlayer(args[1], _IY_lp)
	for i,v in pairs(players) do
		local Forces = {}
		for _,part in pairs(workspace:GetDescendants()) do
			if _IY_Players[v].Character:FindFirstChild('Head') and part:IsA("BasePart" or "UnionOperation" or "Model") and part.Anchored == false and not part:IsDescendantOf(_IY_lp.Character) and part.Name == "Torso" == false and part.Name == "Head" == false and part.Name == "Right Arm" == false and part.Name == "Left Arm" == false and part.Name == "Right Leg" == false and part.Name == "Left Leg" == false and part.Name == "HumanoidRootPart" == false then
				for i,c in pairs(part:GetChildren()) do
					if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
						c:Destroy()
					end
				end
				local ForceInstance = Instance.new("BodyPosition")
				ForceInstance.Parent = part
				ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				table.insert(Forces, ForceInstance)
				if not table.find(_IY_frozenParts,part) then
					table.insert(_IY_frozenParts,part)
				end
			end
		end
		for i,c in pairs(Forces) do
			c.Position = _IY_Players[v].Character.Head.Position
		end
	end
		end
	},
	{
		name = "autokeypress",
		desc = "Auto-press a key <key>",
		args = "<arg>",
		aliases = {'keypress'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if keypress and keyrelease and args[1] then
		local code = keycodeMap[args[1]:lower()]
		if not code then _IY_notify('Auto Key Press',"Invalid key") return end
		execCmd('unautokeypress')
		wait()
		local clickDelay = 0.1
		local releaseDelay = 0.1
		if args[2] and isNumber(args[2]) then clickDelay = args[2] end
		if args[3] and isNumber(args[3]) then releaseDelay = args[3] end
		autoKeyPressing = true
		cancelAutoKeyPress = _IY_UIS.InputBegan:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				if (input.KeyCode == Enum.KeyCode.Backspace and _IY_UIS:IsKeyDown(Enum.KeyCode.Equals)) or (input.KeyCode == Enum.KeyCode.Equals and _IY_UIS:IsKeyDown(Enum.KeyCode.Backspace)) then
					autoKeyPressing = false
					cancelAutoKeyPress:Disconnect()
				end
			end
		end)
		_IY_notify('Auto Key Press',"Press [backspace] and [=] at the same time to stop")
		repeat wait(clickDelay)
			keypress(code)
			wait(releaseDelay)
			keyrelease(code)
		until autoKeyPressing == false
		if cancelAutoKeyPress then cancelAutoKeyPress:Disconnect() keyrelease(code) end
	else
		_IY_notify('Auto Key Press',"Your exploit doesn't have the ability to use auto key press")
	end
		end
	},
	{
		name = "unautokeypress",
		desc = "Stop auto-key press",
		aliases = {'noautokeypress', 'unkeypress', 'nokeypress'},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	autoKeyPressing = false
	if cancelAutoKeyPress then cancelAutoKeyPress:Disconnect() end
		end
	},

	{
		name = "jobid",
		desc = "Notify the current server Job ID",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_toClipboard("roblox://placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId)
		end
	},
	{
		name = "notifyjobid",
		desc = "Notify Job ID and Place ID",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_notify('game.JobId / game.PlaceId',game.JobId..' / '..game.PlaceId)
		end
	},
	{
		name = "gametp",
		desc = "Teleport to a game by place ID",
		args = "<arg>",
		aliases = {"gameteleport"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	game:GetService("TeleportService"):Teleport(args[1])
		end
	},
	{
		name = "autorejoin",
		desc = "Auto rejoin when kicked",
		aliases = {"autorj"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	game:GetService("GuiService").ErrorMessageChanged:Connect(function()
		_IY_execCmd("rejoin")
	end)
	_IY_notify("Auto Rejoin", "Auto rejoin enabled")
		end
	},
	{
		name = "serverhop",
		desc = "Hop to a random server",
		aliases = {"shop"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp

	local servers = {}
	local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
	local body = _IY_HttpSvc:JSONDecode(req)
	if body and body.data then
		for i, v in next, body.data do
			if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
				table.insert(servers, 1, v.id)
			end
		end
	end
	if #servers > 0 then
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], _IY_lp)
	else
		return _IY_notify("Serverhop", "Couldn't find a server.")
	end
		end
	},
	{
		name = "exit",
		desc = "Shutdown / leave the game",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			game:Shutdown()
		end
	},
	{
		name = "clip",
		desc = "Disable noclip",
		args = "<arg>",
		aliases = {"unnoclip"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if Noclipping then
		Noclipping:Disconnect()
	end
	Clip = true
	if args[1] and args[1] == 'nonotify' then return end
	_IY_notify('Noclip','Noclip Disabled')
		end
	},
	{
		name = "togglenoclip",
		desc = "Toggle noclip on/off",
		aliases = {"cliptoggle","nocliptoggle"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if Clip then
				_IY_execCmd('noclip')
			else
				_IY_execCmd('clip')
			end
		end
	},
	{
		name = "unfly",
		desc = "Stop flying",
		aliases = {"nofly", "novfly", "unvehiclefly", "novehiclefly", "unvfly"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if not IsOnMobile then NOFLY() else unmobilefly(_IY_lp) end
		end
	},
	{
		name = "vfly",
		desc = "Toggle vehicle fly mode",
		args = "<arg>",
		aliases = {"vehiclefly"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if not IsOnMobile then
		NOFLY()
		wait()
		sFLY(true)
	else
		mobilefly(_IY_lp, true)
	end
	if args[1] and isNumber(args[1]) then
		vehicleflyspeed = args[1]
	end
		end
	},
	{
		name = "togglevfly",
		desc = "Toggle vehicle fly",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if FLYING then
		if not IsOnMobile then NOFLY() else unmobilefly(_IY_lp) end
	else
		if not IsOnMobile then sFLY(true) else mobilefly(_IY_lp, true) end
	end
		end
	},
	{
		name = "vflyspeed",
		desc = "Set vehicle fly speed",
		args = "<arg>",
		aliases = {"vflysp", "vehicleflyspeed", "vehicleflysp"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local speed = args[1] or 1
	if isNumber(speed) then
		vehicleflyspeed = speed
	end
		end
	},
	{
		name = "qefly",
		desc = "Toggle Q/E vertical fly controls",
		args = "<arg>",
		aliases = {"flyqe"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if args[1] == 'false' then
		QEfly = false
	else
		QEfly = true
	end
		end
	},
	{
		name = "togglefly",
		desc = "Toggle fly on/off",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if FLYING then
		if not IsOnMobile then NOFLY() else unmobilefly(_IY_lp) end
	else
		if not IsOnMobile then sFLY() else mobilefly(_IY_lp) end
	end
		end
	},
	{
		name = "cframefly",
		desc = "CFrame-based fly mode",
		args = "<arg>",
		aliases = {"cfly"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if args[1] and isNumber(args[1]) then
		CFspeed = args[1]
	end

	_IY_lp.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
	local Head = _IY_lp.Character:WaitForChild("Head")
	Head.Anchored = true
	if CFloop then CFloop:Disconnect() end
	CFloop = _IY_RunService.Heartbeat:Connect((function(deltaTime)
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		local moveDirection = _IY_lp.Character:FindFirstChildOfClass('Humanoid').MoveDirection * (CFspeed * deltaTime)
		local headCFrame = Head.CFrame
		local camera = workspace.CurrentCamera
		local cameraCFrame = camera.CFrame
		local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
		cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
		local cameraPosition = cameraCFrame.Position
		local headPosition = headCFrame.Position
		local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
		Head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
	end))
		end
	},
	{
		name = "uncframefly",
		desc = "Stop CFrame fly",
		aliases = {"uncfly"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if CFloop then
		CFloop:Disconnect()
		_IY_lp.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
		local Head = _IY_lp.Character:WaitForChild("Head")
		Head.Anchored = false
	end
		end
	},
	{
		name = "cframeflyspeed",
		desc = "Set CFrame fly speed",
		args = "<arg>",
		aliases = {"cflyspeed"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if isNumber(args[1]) then
		CFspeed = args[1]
	end
		end
	},
	{
		name = "rec",
		desc = "Toggle game recording",
		aliases = {"record"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	return game:GetService("CoreGui"):ToggleRecording()
		end
	},
	{
		name = "screenshot",
		desc = "Take a screenshot",
		aliases = {"scrnshot"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	return game:GetService("CoreGui"):TakeScreenshot()
		end
	},
	{
		name = "clearerror",
		desc = "Clear the Roblox error screen",
		aliases = {"clearerrors"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    game:GetService("GuiService"):ClearError()
		end
	},
	{
		name = "antigameplaypaused",
		desc = "Prevent gameplay paused screen",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    pcall(function() networkPaused:Disconnect() end)
    networkPaused = game:GetService("CoreGui").RobloxGui.ChildAdded:Connect(function(obj)
        if obj.Name == "CoreScripts/NetworkPause" then
            obj:Destroy()
        end
    end)
    game:GetService("CoreGui").RobloxGui["CoreScripts/NetworkPause"]:Destroy()
		end
	},
	{
		name = "unantigameplaypaused",
		desc = "Remove gameplay paused prevention",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    networkPaused:Disconnect()
		end
	},
	{
		name = "clientantikick",
		desc = "Hook kick to prevent being kicked",
		aliases = {"antikick"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if not hookmetamethod then
		return _IY_notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
	end
	local LocalPlayer = _IY_lp
	local oldhmmi
	local oldhmmnc
	local oldKickFunction
	if hookfunction then
		oldKickFunction = hookfunction(LocalPlayer.Kick, function() end)
	end
	oldhmmi = hookmetamethod(game, "__index", (function(self, method)
		if self == LocalPlayer and method:lower() == "kick" then
			return error("Expected ':' not '.' calling member function Kick", 2)
		end
		return oldhmmi(self, method)
	end))
	oldhmmnc = hookmetamethod(game, "__namecall", (function(self, ...)
		if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
			return
		end
		return oldhmmnc(self, ...)
	end))
	_IY_notify('Client Antikick','Client anti kick is now active (only effective on localscript kick)')
		end
	},
	{
		name = "clientantiteleport",
		desc = "Hook teleport to block forced TPs",
		aliases = {"antiteleport"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if not hookmetamethod then
		return _IY_notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
	end
	local TeleportService = game:GetService("TeleportService")
	local oldhmmi
	local oldhmmnc
	oldhmmi = hookmetamethod(game, "__index", (function(self, method)
		if self == game:GetService("TeleportService") then
			if method:lower() == "teleport" then
				return error("Expected ':' not '.' calling member function Kick", 2)
			elseif method == "TeleportToPlaceInstance" then
				return error("Expected ':' not '.' calling member function TeleportToPlaceInstance", 2)
			end
		end
		return oldhmmi(self, method)
	end))
	oldhmmnc = hookmetamethod(game, "__namecall", (function(self, ...)
		if self == game:GetService("TeleportService") and getnamecallmethod():lower() == "teleport" or getnamecallmethod() == "TeleportToPlaceInstance" then
			return
		end
		return oldhmmnc(self, ...)
	end))
	_IY_notify('Client AntiTP','Client anti teleport is now active (only effective on localscript teleport)')
		end
	},
	{
		name = "allowrejoin",
		desc = "Allow or disallow rejoin after anti-teleport",
		args = "<arg>",
		aliases = {"allowrj"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if args[1] and args[1] == 'false' then
		allow_rj = false
		_IY_notify('Client AntiTP','Allow rejoin set to false')
	else
		allow_rj = true
		_IY_notify('Client AntiTP','Allow rejoin set to true')
	end
		end
	},
	{
		name = "cancelteleport",
		desc = "Cancel a pending teleport",
		aliases = {"canceltp"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	game:GetService("TeleportService"):TeleportCancel()
		end
	},
	{
		name = "volume",
		desc = "Set master audio volume 0-10",
		args = "<arg>",
		aliases = {"vol"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	UserSettings():GetService("UserGameSettings").MasterVolume = args[1]/10
		end
	},
	{
		name = "antilag",
		desc = "Reduce graphics for better FPS",
		aliases = {"boostfps", "lowgraphics"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1
	game:GetService("Lighting").GlobalShadows = false
	game:GetService("Lighting").FogEnd = 9e9
	game:GetService("Lighting").FogStart = 9e9
	settings().Rendering.QualityLevel = 1
	for _, v in pairs(game:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CastShadow = false
			v.Material = "Plastic"
			v.Reflectance = 0
			v.BackSurface = "SmoothNoOutlines"
			v.BottomSurface = "SmoothNoOutlines"
			v.FrontSurface = "SmoothNoOutlines"
			v.LeftSurface = "SmoothNoOutlines"
			v.RightSurface = "SmoothNoOutlines"
			v.TopSurface = "SmoothNoOutlines"
		elseif v:IsA("Decal") then
			v.Transparency = 1
			v.Texture = ""
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Lifetime = NumberRange.new(0)
		end
	end
	for _, v in pairs(game:GetService("Lighting"):GetDescendants()) do
		if v:IsA("PostEffect") then
			v.Enabled = false
		end
	end
	workspace.DescendantAdded:Connect(function(child)
		task.spawn(function()
			if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
				_IY_RunService.Heartbeat:Wait()
				child:Destroy()
			elseif child:IsA("BasePart") then
				child.CastShadow = false
			end
		end)
	end)
		end
	},
	{
		name = "setfpscap",
		desc = "Set FPS cap",
		args = "<arg>",
		aliases = {"fpscap", "maxfps"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if fpscaploop then
		task.cancel(fpscaploop)
		fpscaploop = nil
	end
	local fpsCap = 60
	local num = tonumber(args[1]) or 1e6
	if num == "none" then
		return
	elseif num > 0 then
		fpsCap = num
	else
		return _IY_notify("Invalid argument", "Please provide a number above 0 or 'none'.")
	end
	if setfpscap and type(setfpscap) == "function" then
		setfpscap(fpsCap)
	else
		fpscaploop = task.spawn(function()
			local timer = os.clock()
			while true do
				if os.clock() >= timer + 1 / fpsCap then
					timer = os.clock()
					task.wait()
				end
			end
		end)
	end
		end
	},
	{
		name = "lastcommand",
		desc = "Re-run your last command",
		aliases = {"lastcmd"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if cmdHistory[1]:sub(1,11) ~= 'lastcommand' and cmdHistory[1]:sub(1,7) ~= 'lastcmd' then
		_IY_execCmd(cmdHistory[1])
	end
		end
	},
	{
		name = "esp",
		desc = "Enable ESP outlines for all players",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if not CHMSenabled then
		ESPenabled = true
		for i,v in pairs(_IY_Players:GetPlayers()) do
			if v.Name ~= _IY_lp.Name then
				ESP(v)
			end
		end
	else
		_IY_notify('ESP','Disable chams (nochams) before using esp')
	end
		end
	},
	{
		name = "espteam",
		desc = "Enable team-coloured ESP",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if not CHMSenabled then
		ESPenabled = true
		for i,v in pairs(_IY_Players:GetPlayers()) do
			if v.Name ~= _IY_lp.Name then
				ESP(v, true)
			end
		end
	else
		_IY_notify('ESP','Disable chams (nochams) before using esp')
	end
		end
	},
	{
		name = "noesp",
		desc = "Disable ESP",
		aliases = {"unesp", "unespteam"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	ESPenabled = false
	for i,c in pairs(game:GetService("CoreGui"):GetChildren()) do
		if string.sub(c.Name, -4) == '_ESP' then
			c:Destroy()
		end
	end
		end
	},
	{
		name = "esptransparency",
		desc = "Set ESP transparency",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    espTransparency = tonumber(args[1]) or 0.3
    if ESPenabled then _IY_execCmd("esp") end
    if CHMSenabled then _IY_execCmd("chams") end
    updatesaves()
		end
	},
	{
		name = "enableshiftlock",
		desc = "Enable shift lock",
		aliases = {"enablesl", "shiftlock"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local function enableShiftlock()
		_IY_lp.DevEnableMouseLock = true
	end
	_IY_lp:GetPropertyChangedSignal("DevEnableMouseLock"):Connect(enableShiftlock)
	enableShiftlock()
	_IY_notify("Shiftlock", "Shift lock should now be available")
		end
	},
	{
		name = "f3x",
		desc = "Give F3X building tools",
		aliases = {"fex"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	loadstring(game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/f3x.lua")))()
		end
	},
	{
		name = "partpath",
		desc = "Print full path of a named part",
		aliases = {"partname"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	selectPart()
		end
	},
	{
		name = "antiafk",
		desc = "Toggle anti-AFK",
		args = "<arg>",
		aliases = {"antiidle"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if getconnections then
		for _, connection in pairs(getconnections(_IY_lp.Idled)) do
			if connection["Disable"] then
				connection["Disable"](connection)
			elseif connection["Disconnect"] then
				connection["Disconnect"](connection)
			end
		end
	else
		_IY_lp.Idled:Connect(function()

		end)
	end
	if not (args[1] and tostring(args[1]) == "nonotify") then _IY_notify("Anti Idle", "Anti idle is enabled") end
		end
	},
	{
		name = "datalimit",
		desc = "Set network data limit",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local kbps = tonumber(args[1])
	if kbps then
		Services.NetworkClient:SetOutgoingKBPSLimit(kbps)
	end
		end
	},
	{
		name = "replicationlag",
		desc = "Set replication lag",
		args = "<arg>",
		aliases = {"backtrack"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if tonumber(args[1]) then
		settings():GetService("NetworkSettings").IncomingReplicationLag = args[1]
	end
		end
	},
	{
		name = "noprompts",
		desc = "Remove all ProximityPrompt UIs",
		aliases = {"nopurchaseprompts"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	game:GetService("CoreGui").PurchasePromptApp.Enabled = false
		end
	},
	{
		name = "showprompts",
		desc = "Restore ProximityPrompt UIs",
		aliases = {"showpurchaseprompts"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	game:GetService("CoreGui").PurchasePromptApp.Enabled = true
		end
	},
	{
		name = "promptr6",
		desc = "Force R6 rig prompts",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	promptNewRig(_IY_lp, "R6")
		end
	},
	{
		name = "promptr15",
		desc = "Force R15 rig prompts",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	promptNewRig(_IY_lp, "R15")
		end
	},
	{
		name = "wallwalk",
		desc = "Toggle walking on walls",
		aliases = {"walkonwalls"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	loadstring(game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/main/wallwalker.lua")))()
		end
	},
	{
		name = "copyplaceid",
		desc = "Copy current Place ID to clipboard",
		aliases = {"placeid"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_toClipboard(game.PlaceId)
		end
	},
	{
		name = "copygameid",
		desc = "Copy current Universe ID to clipboard",
		aliases = {"gameid"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_toClipboard(game.GameId)
		end
	},
	{
		name = "vehicleclip",
		desc = "Toggle noclip for vehicles",
		aliases = {"vclip", "unvnoclip", "unvehiclenoclip"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("clip")
	for i, v in pairs(vnoclipParts) do
		v.CanCollide = true
	end
	vnoclipParts = {}
		end
	},
	{
		name = "togglevnoclip",
		desc = "Toggle vehicle noclip",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd(Clip and "vnoclip" or "vclip")
		end
	},
	{
		name = "orbit",
		desc = "Orbit around a player",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("unorbit nonotify")
	local target = _IY_Players:FindFirstChild(getPlayer(args[1], _IY_lp)[1])
	local root = _IY_getRoot(_IY_lp.Character)
	local humanoid = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
	if target and target.Character and _IY_getRoot(target.Character) and root and humanoid then
		local rotation = 0
		local speed = tonumber(args[2]) or 0.2
		local distance = tonumber(args[3]) or 6
		orbit1 = _IY_RunService.Heartbeat:Connect((function()
			LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
			pcall(function()
				rotation = rotation + speed
				root.CFrame = CFrame.new(_IY_getRoot(target.Character).Position) * CFrame.Angles(0, math.rad(rotation), 0) * CFrame.new(distance, 0, 0)
			end)
		end))
		orbit2 = _IY_RunService.RenderStepped:Connect((function()
			LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
			pcall(function()
				root.CFrame = CFrame.new(root.Position, _IY_getRoot(target.Character).Position)
			end)
		end))
		orbit3 = humanoid.Died:Connect(function() _IY_execCmd("unorbit") end)
		orbit4 = humanoid.Seated:Connect(function(value) if value then _IY_execCmd("unorbit") end end)
		_IY_notify("Orbit", "Started orbiting " .. formatUsername(target))
	end
		end
	},
	{
		name = "unorbit",
		desc = "Stop orbiting",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if orbit1 then orbit1:Disconnect() end
	if orbit2 then orbit2:Disconnect() end
	if orbit3 then orbit3:Disconnect() end
	if orbit4 then orbit4:Disconnect() end
	if args[1] ~= "nonotify" then _IY_notify("Orbit", "Stopped orbiting player") end
		end
	},
	{
		name = "anchor",
		desc = "Anchor your character in place",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    _IY_getRoot(_IY_lp.Character).Anchored = true
		end
	},
	{
		name = "unanchor",
		desc = "Unanchor your character",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    _IY_getRoot(_IY_lp.Character).Anchored = false
		end
	},
	{
		name = "reset",
		desc = "Reset your character",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local humanoid = _IY_lp.Character and _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
	if replicatesignal then
		replicatesignal(_IY_lp.Kill)
	elseif humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	else
		_IY_lp.Character:BreakJoints()
	end
		end
	},
	{
		name = "refresh",
		desc = "Reload your character",
		aliases = {"re"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	refresh(_IY_lp)
		end
	},
	{
		name = "visible",
		desc = "Make your character visible",
		aliases = {"vis", "uninvisible"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	TurnVisible()
		end
	},
	{
		name = "toggleinvis",
		desc = "Toggle character invisibility",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd(invisRunning and "visible" or "invisible")
		end
	},
	{
		name = "strengthen",
		desc = "Increase hit damage multiplier",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for _, child in pairs(_IY_lp.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			if args[1] then
				child.CustomPhysicalProperties = PhysicalProperties.new(args[1], 0.3, 0.5)
			else
				child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
			end
		end
	end
		end
	},
	{
		name = "weaken",
		desc = "Decrease a player hit damage",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for _, child in pairs(_IY_lp.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			if args[1] then
				child.CustomPhysicalProperties = PhysicalProperties.new(-args[1], 0.3, 0.5)
			else
				child.CustomPhysicalProperties = PhysicalProperties.new(0, 0.3, 0.5)
			end
		end
	end
		end
	},
	{
		name = "unweaken",
		desc = "Remove weaken effect",
		aliases = {"unstrengthen"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	for _, child in pairs(_IY_lp.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
		end
	end
		end
	},
	{
		name = "breakvelocity",
		desc = "Zero out all body velocities",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local BeenASecond, V3 = false, Vector3.new(0, 0, 0)
	delay(1, function()
		BeenASecond = true
	end)
	while not BeenASecond do
		for _, v in ipairs(_IY_lp.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.AssemblyLinearVelocity, v.AssemblyAngularVelocity = V3, V3
			end
		end
		wait()
	end
		end
	},
	{
		name = "maxslopeangle",
		desc = "Set humanoid max slope angle",
		args = "<arg>",
		aliases = {"msa"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local sangle = args[1] or 89
	if isNumber(sangle) then
		_IY_lp.Character:FindFirstChildWhichIsA("Humanoid").MaxSlopeAngle = sangle
	end
		end
	},
	{
		name = "hipheight",
		desc = "Set humanoid hip height",
		args = "<arg>",
		aliases = {"hheight"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local hipHeight = args[1] or (r15(_IY_lp) and 2.1 or 0)
	if isNumber(hipHeight) then
		_IY_lp.Character:FindFirstChildWhichIsA("Humanoid").HipHeight = hipHeight
	end
		end
	},
	{
		name = "dance",
		desc = "Play a dance animation",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	pcall(_IY_execCmd, "undance")
	local dances = {"27789359", "30196114", "248263260", "45834924", "33796059", "28488254", "52155728"}
	if r15(_IY_lp) then
		dances = {"3333432454", "4555808220", "4049037604", "4555782893", "10214311282", "10714010337", "10713981723", "10714372526", "10714076981", "10714392151", "11444443576"}
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. dances[math.random(1, #dances)]
	danceTrack = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(animation)
	danceTrack.Looped = true
	danceTrack:Play()
		end
	},
	{
		name = "undance",
		desc = "Stop the current dance",
		aliases = {"nodance"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	danceTrack:Stop()
	danceTrack:Destroy()
		end
	},
	{
		name = "sit",
		desc = "Force character to sit",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildWhichIsA("Humanoid").Sit = true
		end
	},
	{
		name = "lay",
		desc = "Force character to lay flat",
		aliases = {"laydown"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local humanoid = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
	humanoid.Sit = true
	task.wait(0.1)
	humanoid.RootPart.CFrame = humanoid.RootPart.CFrame * CFrame.Angles(math.pi * 0.5, 0, 0)
	for _, v in ipairs(humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
		end
	},
	{
		name = "sitwalk",
		desc = "Walk while sitting",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local anims = _IY_lp.Character.Animate
	local sit = anims.sit:FindFirstChildWhichIsA("Animation").AnimationId
	anims.idle:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.walk:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.run:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.jump:FindFirstChildWhichIsA("Animation").AnimationId = sit
	_IY_lp.Character:FindFirstChildWhichIsA("Humanoid").HipHeight = not r15(_IY_lp) and -1.5 or 0.5
		end
	},
	{
		name = "nosit",
		desc = "Prevent character from sitting",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		end
	},
	{
		name = "unnosit",
		desc = "Allow character to sit again",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		end
	},
	{
		name = "jump",
		desc = "Make character jump",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_lp.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
		end
	},
	{
		name = "uninfjump",
		desc = "Disable infinite jump",
		aliases = {"uninfinitejump", "noinfjump", "noinfinitejump"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if infJump then infJump:Disconnect() end
	infJumpDebounce = false
		end
	},
	{
		name = "flyjump",
		desc = "Jump while flying",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if flyjump then flyjump:Disconnect() end
	flyjump = _IY_UIS.JumpRequest:Connect(function()
		_IY_lp.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
	end)
		end
	},
	{
		name = "unflyjump",
		desc = "Disable fly jump",
		aliases = {"noflyjump"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if flyjump then flyjump:Disconnect() end
		end
	},
	{
		name = "team",
		desc = "Set your team",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local teamName = getstring(1, args)
	local team = nil
	local root = _IY_lp.Character and _IY_getRoot(_IY_lp.Character)
	for _, v in ipairs(Teams:GetChildren()) do
		if v.Name:lower():match(teamName:lower()) then
			team = v
			break
		end
	end
	if not team then
		return _IY_notify("Invalid Team", teamName .. " is not a valid team")
	end
	if root and firetouchinterest then
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("SpawnLocation") and v.BrickColor == team.TeamColor and v.AllowTeamChangeOnTouch == true then
				firetouchinterest(v, root, 0)
				firetouchinterest(v, root, 1)
				break
			end
		end
	else
		_IY_lp.Team = team
	end
		end
	},
	{
		name = "animation",
		desc = "Play an animation by ID",
		args = "<arg>",
		aliases = {"anim"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local animid = tostring(args[1])
	if not animid:find("rbxassetid://") then
		animid = "rbxassetid://" .. animid
	end
	animid = anim2track(animid)
	local animation = Instance.new("Animation")
	animation.AnimationId = animid
	local anim = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(animation)
	anim.Priority = Enum.AnimationPriority.Movement
	anim:Play()
	if args[2] then anim:AdjustSpeed(tostring(args[2])) end
		end
	},
	{
		name = "emote",
		desc = "Play an emote animation",
		args = "<arg>",
		aliases = {"em"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local anim = humanoid:PlayEmoteAndGetAnimTrackById(args[1])
	if args[2] then anim:AdjustSpeed(tostring(args[2])) end
		end
	},
	{
		name = "copyanimationid",
		desc = "Copy the currently playing animation ID",
		args = "<arg>",
		aliases = {"copyanimid", "copyemoteid"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local copyAnimId = function(player)
		local found = "Animations Copied"
		for _, v in pairs(player.Character:FindFirstChildWhichIsA("Humanoid"):GetPlayingAnimationTracks()) do
			local animationId = v.Animation.AnimationId
			local assetId = animationId:find("rbxassetid://") and animationId:match("%d+")
			if not string.find(animationId, "507768375") and not string.find(animationId, "180435571") then
				if assetId then
					local success, result = pcall(function()
						return MarketplaceService:GetProductInfo(tonumber(assetId)).Name
					end)
					local name = success and result or "Failed to get name"
					found = found .. "\n\nName: " .. name .. "\nAnimation Id: " .. animationId
				else
					found = found .. "\n\nAnimation Id: " .. animationId
				end
			end
		end
		if found ~= "Animations Copied" then
			_IY_toClipboard(found)
		else
			_IY_notify("Animations", "No animations to copy")
		end
	end
	if args[1] then
		copyAnimId(_IY_Players[getPlayer(args[1], _IY_lp)[1]])
	else
		copyAnimId(_IY_lp)
	end
		end
	},
	{
		name = "offset",
		desc = "Apply position offset",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    if #args < 3 then return end
    _IY_lp.Character:TranslateBy(Vector3.new(tonumber(args[1]) or 0, tonumber(args[2]) or 0, tonumber(args[3]) or 0))
		end
	},
	{
		name = "tweenoffset",
		desc = "Tween to offset position",
		args = "<arg>",
		aliases = {"toffset"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    if #args < 3 then return end
    local tpX, tpY, tpZ = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    local root = _IY_getRoot(_IY_lp.Character)
    local pos = root.Position + Vector3.new(tpX, tpY, tpZ)
    _IY_TweenSvc:Create(root, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)}):Play()
    breakVelocity()
		end
	},
	{
		name = "clickteleport",
		desc = "Toggle click-to-teleport mode",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    if _IY_lp ~= _IY_lp then return end
    _IY_notify("Click TP", "Go to Settings > Keybinds > Add to set up click teleport")
		end
	},
	{
		name = "mouseteleport",
		desc = "Teleport to mouse position",
		aliases = {"mousetp"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    local root = _IY_getRoot(_IY_lp.Character)
    local pos = _IY_lp:GetMouse().Hit
    if root and pos then
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z, select(4, root.CFrame:components()))
        breakVelocity()
    end
		end
	},
	{
		name = "thru",
		desc = "Teleport through the nearest wall",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    local root = _IY_getRoot(_IY_lp.Character)
    local num = tonumber(args[1]) or 5
    local pos = root.CFrame.Position + (root.CFrame.LookVector * num)
    root.CFrame = CFrame.new(pos, pos + root.CFrame.LookVector)
		end
	},
	{
		name = "chatwindow",
		desc = "Show the chat window",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	TextChatService.ChatWindowConfiguration.Enabled = true
		end
	},
	{
		name = "unchatwindow",
		desc = "Hide the chat window",
		aliases = {"nochatwindow"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	TextChatService.ChatWindowConfiguration.Enabled = false
		end
	},
	{
		name = "darkchat",
		desc = "Apply dark theme to chat",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    local BCC = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    local CWC = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    local CIBC = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
    if BCC then
        BCC.Enabled = true
        BCC.BackgroundColor3 = Color3.fromRGB()
        BCC.BackgroundTransparency = 0.3
        BCC.TailVisible = true
        BCC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
    end
    if CWC then
        CWC.Enabled = true
        CWC.BackgroundColor3 = Color3.fromRGB()
        CWC.BackgroundTransparency = 0.3
        CWC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CWC.TextStrokeColor3 = Color3.fromRGB()
        CWC.TextStrokeTransparency = 0.5
    end
    if CIBC then
        CIBC.Enabled = true
        CIBC.BackgroundColor3 = Color3.fromRGB()
        CIBC.BackgroundTransparency = 0.5
        CIBC.PlaceholderColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CIBC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CIBC.TextStrokeColor3 = Color3.fromRGB()
        CIBC.TextStrokeTransparency = 0.5
    end
		end
	},
	{
		name = "boxreach",
		desc = "Enable box-shaped reach",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("unreach")
	wait()
	for i, v in pairs(_IY_lp.Character:GetDescendants()) do
		if v:IsA("Tool") then
			local size = tonumber(args[1]) or 60
			currentToolSize = v.Handle.Size
			currentGripPos = v.GripPos
			local a = Instance.new("SelectionBox")
			a.Name = "SelectionBoxCreated"
			a.Parent = v.Handle
			a.Adornee = v.Handle
			v.Handle.Massless = true
			v.Handle.Size = Vector3.new(size, size, size)
			v.GripPos = Vector3.new(0, 0, 0)
			_IY_lp.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
		end
	end
		end
	},
	{
		name = "flyfling",
		desc = "Fling players you fly into",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("unvehiclefly\\unwalkfling")
	task.wait()
	vehicleflyspeed = tonumber(args[1]) or vehicleflyspeed
	_IY_execCmd("vehiclefly\\walkfling")
		end
	},
	{
		name = "unflyfling",
		desc = "Stop fly fling",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("unvehiclefly\\unwalkfling\\breakvelocity")
		end
	},
	{
		name = "toggleflyfling",
		desc = "Toggle fly fling",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd(flinging and "unflyfling" or "flyfling")
		end
	},
	{
		name = "walkfling",
		desc = "Fling a player by walking into them",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("unwalkfling")
	local humanoid = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			_IY_execCmd("unwalkfling")
		end)
	end
	_IY_execCmd("noclip nonotify")
	walkflinging = true
	repeat _IY_RunService.Heartbeat:Wait()
		local character = _IY_lp.Character
		local root = _IY_getRoot(character)
		local vel, movel = nil, 0.1
		while not (character and character.Parent and root and root.Parent) do
			_IY_RunService.Heartbeat:Wait()
			character = _IY_lp.Character
			root = _IY_getRoot(character)
		end
		vel = root.Velocity
		root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
		_IY_RunService.RenderStepped:Wait()
		if character and character.Parent and root and root.Parent then
			root.Velocity = vel
		end
		_IY_RunService.Stepped:Wait()
		if character and character.Parent and root and root.Parent then
			root.Velocity = vel + Vector3.new(0, movel, 0)
			movel = movel * -1
		end
	until walkflinging == false
		end
	},
	{
		name = "unwalkfling",
		desc = "Stop walk fling",
		aliases = {"nowalkfling"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	walkflinging = false
	_IY_execCmd("unnoclip nonotify")
		end
	},
	{
		name = "togglewalkfling",
		desc = "Toggle walk fling",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd(walkflinging and "unwalkfling" or "walkfling")
		end
	},
	{
		name = "antifling",
		desc = "Enable anti-fling protection",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if antifling then
		antifling:Disconnect()
		antifling = nil
	end
	antifling = _IY_RunService.Stepped:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		for _, player in pairs(_IY_Players:GetPlayers()) do
			if player ~= _IY_lp and player.Character then
				for _, v in pairs(player.Character:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
					end
				end
			end
		end
	end))
		end
	},
	{
		name = "unantifling",
		desc = "Disable anti-fling",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if antifling then
		antifling:Disconnect()
		antifling = nil
	end
		end
	},
	{
		name = "toggleantifling",
		desc = "Toggle anti-fling",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd(antifling and "unantifling" or "antifling")
		end
	},
	{
		name = "handlekill",
		desc = "Kill a player via tool handle collision",
		args = "<arg>",
		aliases = {"hkill"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if not firetouchinterest then
		return _IY_notify("Incompatible Exploit", "Your exploit does not support this command (missing firetouchinterest)")
	end
	if not _IY_lp.Character then return end
	local tool = _IY_lp.Character:FindFirstChildWhichIsA("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle then
		return _IY_notify("Handle Kill", "You need to hold a \"Tool\" that does damage on touch. For example a common Sword tool.")
	end
	local range = tonumber(args[2]) or math.huge
	if range ~= math.huge then _IY_notify("Handle Kill", ("Started!\nRadius: %s"):format(tostring(range):upper())) end
	while task.wait() and _IY_lp.Character and tool.Parent and tool.Parent == _IY_lp.Character do
		for _, plr in next, getPlayer(args[1], _IY_lp) do
			plr = _IY_Players[plr]
			if plr ~= _IY_lp and plr.Character then
				local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
				local root = hum and _IY_getRoot(plr.Character)
				if root and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead and _IY_lp:DistanceFromCharacter(root.Position) <= range then
					firetouchinterest(handle, root, 1)
					firetouchinterest(handle, root, 0)
				end
			end
		end
	end
	_IY_notify("Handle Kill", "Stopped!")
		end
	},
	{
		name = "teleportwalk",
		desc = "Walk using rapid short teleports",
		args = "<arg>",
		aliases = {"tpwalk"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    pcall(function() tpwalking:Disconnect() end)
    local character = _IY_lp.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local speed = (args[1] and isNumber(args[1])) and tonumber(args[1]) or 1
    if parseBoolean(args[2]) then
        tpwalkStack = tpwalkStack + speed
    end
    tpwalking = _IY_RunService.Heartbeat:Connect((function(delta)
					LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
        if not (character and humanoid and humanoid.Parent) then
            tpwalking:Disconnect()
            return
        end
        if humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * (speed + tpwalkStack) * delta * 10)
        end
    end))
		end
	},
	{
		name = "unteleportwalk",
		desc = "Stop teleport walk",
		aliases = {"untpwalk"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
    tpwalkStack = 0
    tpwalking:Disconnect()
		end
	},
	{
		name = "xray",
		desc = "Make all workspace parts transparent",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	xrayEnabled = true
	xray()
		end
	},
	{
		name = "unxray",
		desc = "Restore part transparency",
		aliases = {"noxray"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	xrayEnabled = false
	xray()
		end
	},
	{
		name = "togglexray",
		desc = "Toggle X-ray vision",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	xrayEnabled = not xrayEnabled
	xray()
		end
	},
	{
		name = "loopxray",
		desc = "Loop X-ray on new parts",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	pcall(function() xrayLoop:Disconnect() end)
	xrayLoop = _IY_RunService.RenderStepped:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		xrayEnabled = true
		xray()
	end))
		end
	},
	{
		name = "unloopxray",
		desc = "Stop loop X-ray",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	pcall(function() xrayLoop:Disconnect() end)
	xrayEnabled = false
	xray()
		end
	},
	{
		name = "antivoid",
		desc = "Auto-teleport up when falling into void",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("unantivoid nonotify")
	task.wait()
	antivoidloop = _IY_RunService.Stepped:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		local root = _IY_getRoot(_IY_lp.Character)
		if root and root.Position.Y <= OrgDestroyHeight + 25 then
			root.Velocity = root.Velocity + Vector3.new(0, 250, 0)
		end
	end))
	if args[1] ~= "nonotify" then _IY_notify("antivoid", "Enabled") end
		end
	},
	{
		name = "unantivoid",
		desc = "Disable anti-void",
		args = "<arg>",
		aliases = {"noantivoid"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	pcall(function() antivoidloop:Disconnect() end)
	antivoidloop = nil
	if args[1] ~= "nonotify" then _IY_notify("antivoid", "Disabled") end
		end
	},
	{
		name = "fakeout",
		desc = "Play a fake death animation",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local root = _IY_getRoot(_IY_lp.Character)
	local oldpos = root.CFrame
	if antivoidloop then
		_IY_execCmd("unantivoid nonotify")
		antivoidWasEnabled = true
	end
	workspace.FallenPartsDestroyHeight = 0/1/0
	root.CFrame = CFrame.new(Vector3.new(0, OrgDestroyHeight - 25, 0))
	task.wait(1)
	root.CFrame = oldpos
	workspace.FallenPartsDestroyHeight = OrgDestroyHeight
	if antivoidWasEnabled then
		_IY_execCmd("antivoid nonotify")
		antivoidWasEnabled = false
	end
		end
	},
	{
		name = "trip",
		desc = "Trip your character",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local humanoid = _IY_lp.Character and _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
	local root = _IY_lp.Character and _IY_getRoot(_IY_lp.Character)
	if humanoid and root then
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
		root.Velocity = root.CFrame.LookVector * 30
	end
		end
	},
	{
		name = "removeads",
		desc = "Remove ad decals from workspace",
		aliases = {"adblock"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp

	local function cleanAd(v)
		if v:IsA("PackageLink") then
			if v.Parent:FindFirstChild("ADpart") then
				v.Parent:Destroy()
			elseif v.Parent:FindFirstChild("AdGuiAdornee") then
				v.Parent.Parent:Destroy()
			end
		end
	end
	pcall(function()
		for _, v in ipairs(workspace:GetDescendants()) do
			cleanAd(v)
		end
	end)
	if _G.OnyxAdBlockConnection then
		_G.OnyxAdBlockConnection:Disconnect()
	end
	_G.OnyxAdBlockConnection = workspace.DescendantAdded:Connect(function(v)
		pcall(cleanAd, v)
	end)
		end
	},
	{
		name = "scare",
		desc = "Flash a scare image on screen",
		args = "<arg>",
		aliases = {"spook"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local players = getPlayer(args[1], _IY_lp)
	local oldpos = nil
	for _, v in pairs(players) do
		local root = _IY_lp.Character and _IY_getRoot(_IY_lp.Character)
		local target = _IY_Players[v]
		local targetRoot = target and target.Character and _IY_getRoot(target.Character)
		if root and targetRoot and target ~= _IY_lp then
			oldpos = root.CFrame
			root.CFrame = targetRoot.CFrame + targetRoot.CFrame.lookVector * 2
			root.CFrame = CFrame.new(root.Position, targetRoot.Position)
			task.wait(0.5)
			root.CFrame = oldpos
		end
	end
		end
	},
	{
		name = "alignmentkeys",
		desc = "Use arrow keys to align parts",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	alignmentKeys = _IY_UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Comma then workspace.CurrentCamera:PanUnits(-1) end
		if input.KeyCode == Enum.KeyCode.Period then workspace.CurrentCamera:PanUnits(1) end
	end)
	alignmentKeysEmotes = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
		end
	},
	{
		name = "unalignmentkeys",
		desc = "Disable alignment keys",
		aliases = {"noalignmentkeys"},
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	if type(alignmentKeysEmotes) == "boolean" then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, alignmentKeysEmotes)
	end
	alignmentKeys:Disconnect()
		end
	},
	{
		name = "ctrllock",
		desc = "Prevent Ctrl from triggering crouch",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local mouseLockController = _IY_lp.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
	local boundKeys = mouseLockController:FindFirstChild("BoundKeys")
	if boundKeys then
		boundKeys.Value = "LeftControl"
	else
		boundKeys = Instance.new("StringValue")
		boundKeys.Name = "BoundKeys"
		boundKeys.Value = "LeftControl"
		boundKeys.Parent = mouseLockController
	end
		end
	},
	{
		name = "unctrllock",
		desc = "Re-enable Ctrl crouch",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	local mouseLockController = _IY_lp.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
	local boundKeys = mouseLockController:FindFirstChild("BoundKeys")
	if boundKeys then
		boundKeys.Value = "LeftShift"
	else
		boundKeys = Instance.new("StringValue")
		boundKeys.Name = "BoundKeys"
		boundKeys.Value = "LeftShift"
		boundKeys.Parent = mouseLockController
	end
		end
	},
	{
		name = "listento",
		desc = "Listen to a players audio",
		args = "<arg>",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	_IY_execCmd("unlistento")
	if not args[1] then return end
	local player = _IY_Players:FindFirstChild(getPlayer(args[1], _IY_lp)[1])
	local root = player and player.Character and _IY_getRoot(player.Character)
	if root then
		SoundService:SetListener(Enum.ListenerType.ObjectPosition, root)
		listentoChar = player.CharacterAdded:Connect(function()
			repeat task.wait() until _IY_Players[player.Name].Character ~= nil and _IY_getRoot(_IY_Players[player.Name].Character)
			SoundService:SetListener(Enum.ListenerType.ObjectPosition, _IY_getRoot(_IY_Players[player.Name].Character))
		end)
	end
		end
	},
	{
		name = "unlistento",
		desc = "Stop listening to player audio",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
	SoundService:SetListener(Enum.ListenerType.Camera)
	listentoChar:Disconnect()
		end
	},
	{
		name = "permadeath",
		desc = "Delete character permanently on death",
		callback = function(arg)
			local args = _IY_splitArgs(arg)
			local speaker = _IY_lp
			if replicatesignal then
				permadeath(_IY_lp)
				_IY_notify("Permadeath", "Enabled")
			else
				_IY_notify("Incompatible Exploit", "Your exploit does not support this command")
			end
		end
	},
	{
		name = "muteall",
		desc = "Mute all players except friends in voice and text chat",
		aliases = {"muteothers", "friendsonly"},
		callback = function()
			if not _G._slateVCI then
				local ok, svc = pcall(function() return game:GetService("VoiceChatInternal") end)
				_G._slateVCI = ok and svc or false
			end
			if not _G._slateMuteProps then
				_G._slateMuteProps = Instance.new("TextChatMessageProperties")
				_G._slateMuteProps.Text = ""
			end
			_G._slateMutedUserIds = {}
			_G._slateAutoMuteActive = true
			local function _slateIsFriend(player)
				if player == localPlayer then return true end
				local ok, result = pcall(function() return player:IsFriendsWith(localPlayer.UserId) end)
				return ok and result
			end
			_G._slateIsFriend = _slateIsFriend
			local function _slateMuteOne(p)
				if p == localPlayer then return end
				if _G._slateIsFriend(p) then return end
				_G._slateMutedUserIds[p.UserId] = true
				if _G._slateVCI then
					pcall(function() _G._slateVCI:SubscribePause(p.UserId, true) end)
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
				_G._slateMuteTextHooked = true
				_G._slateMuteTextPrev = TextChatService.OnIncomingMessage
				TextChatService.OnIncomingMessage = function(msg)
					local src = rawget(msg, "TextSource") or (msg and pcall(function() return msg.TextSource end) and msg.TextSource)
					if src and _G._slateMutedUserIds and _G._slateMutedUserIds[src.UserId] then
						return _G._slateMuteProps
					end
					if _G._slateMuteTextPrev then
						return _G._slateMuteTextPrev(msg)
					end
				end
			end
			if _G._slateAutoMuteConn then
				pcall(function() _G._slateAutoMuteConn:Disconnect() end)
				_G._slateAutoMuteConn = nil
			end
			_G._slateAutoMuteConn = players.PlayerAdded:Connect(function(p)
				if not _G._slateAutoMuteActive then return end
				task.wait(1.5)
				if not _G._slateAutoMuteActive then return end
				if not _G._slateIsFriend(p) then
					_G._slateMutedUserIds[p.UserId] = true
					if _G._slateVCI then
						pcall(function() _G._slateVCI:SubscribePause(p.UserId, true) end)
					end
				end
			end)
			queueNotification("Mute All", "Muted " .. mutedCount .. " player(s). Friends exempt.")
		end,
	},
	{
		name = "unmuteall",
		desc = "Unmute all players muted by muteall",
		aliases = {"unmutall", "unfriendonly"},
		callback = function()
			_G._slateAutoMuteActive = false
			if _G._slateAutoMuteConn then
				pcall(function() _G._slateAutoMuteConn:Disconnect() end)
				_G._slateAutoMuteConn = nil
			end
			if not isLegacyChat and _G._slateMuteTextHooked then
				TextChatService.OnIncomingMessage = _G._slateMuteTextPrev or nil
				_G._slateMuteTextPrev = nil
				_G._slateMuteTextHooked = false
			end
			local unmutedCount = 0
			if _G._slateVCI then
				pcall(function() _G._slateVCI:SubscribePauseAll(false) end)
			end
			for _, p in ipairs(players:GetPlayers()) do
				if p == localPlayer then continue end
				if _G._slateVCI then
					pcall(function() _G._slateVCI:SubscribePause(p.UserId, false) end)
				end
				unmutedCount = unmutedCount + 1
			end
			_G._slateMutedUserIds = {}
			queueNotification("Unmute All", "Unmuted " .. unmutedCount .. " player(s).")
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
	antivc = "antivcbypass"
}

if IY_LOADED and not _G.IY_DEBUG then

	return

end

pcall(function() getgenv().IY_LOADED = true end)

if not game:IsLoaded() then game.Loaded:Wait() end

function missing(t, f, fallback)

	if type(f) == t then return f end

	return fallback

end

cloneref = missing("function", cloneref, function(...) return ... end)

sethidden =  missing("function", sethiddenproperty or set_hidden_property or set_hidden_prop)

gethidden =  missing("function", gethiddenproperty or get_hidden_property or get_hidden_prop)

queueteleport =  missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))

httprequest =  missing("function", request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request))

everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))

firetouchinterest = missing("function", firetouchinterest)

waxwritefile, waxreadfile = writefile, readfile

writefile = missing("function", waxwritefile) and function(file, data, safe)

	if safe == true then return pcall(waxwritefile, file, data) end

	waxwritefile(file, data)

end

readfile = missing("function", waxreadfile) and function(file, safe)

	if safe == true then return pcall(waxreadfile, file) end

	return waxreadfile(file)

end

isfile = missing("function", isfile, readfile and function(file)

	local success, result = pcall(function()

		return readfile(file)

	end)

	return success and result ~= nil and result ~= ""

end)

makefolder = missing("function", makefolder)

isfolder = missing("function", isfolder)

waxgetcustomasset = missing("function", getcustomasset or getsynasset)

hookfunction = missing("function", hookfunction)

hookmetamethod = missing("function", hookmetamethod)

getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method)

checkcaller = missing("function", checkcaller, function() return false end)

newcclosure = missing("function", newcclosure)

getgc = missing("function", getgc or get_gc_objects)

setthreadidentity = missing("function", setthreadidentity or (syn and syn.set_thread_identity) or syn_context_set or setthreadcontext)

replicatesignal = missing("function", replicatesignal)

getconnections = missing("function", getconnections or get_signal_cons)

Services = setmetatable({}, {

	__index = function(self, name)

		local success, cache = pcall(function()

			return cloneref(game:GetService(name))

		end)

		if success then

			rawset(self, name, cache)

			return cache

		else

			error("Invalid Service: " .. tostring(name))

		end

	end

})

Players = Services.Players

UserInputService = Services.UserInputService

TweenService = Services.TweenService

HttpService = Services.HttpService

MarketplaceService = Services.MarketplaceService

RunService = Services.RunService

TeleportService = Services.TeleportService

StarterGui = Services.StarterGui

GuiService = Services.GuiService

Lighting = Services.Lighting

ContextActionService = Services.ContextActionService

ReplicatedStorage = Services.ReplicatedStorage

GroupService = Services.GroupService

PathService = Services.PathfindingService

SoundService = Services.SoundService

Teams = Services.Teams

StarterPlayer = Services.StarterPlayer

InsertService = Services.InsertService

ChatService = Services.Chat

ProximityPromptService = Services.ProximityPromptService

ContentProvider = Services.ContentProvider

StatsService = Services.Stats

MaterialService = Services.MaterialService

AvatarEditorService = Services.AvatarEditorService

TextService = Services.TextService

TextChatService = Services.TextChatService

CaptureService = Services.CaptureService

VoiceChatService = Services.VoiceChatService

SocialService = Services.SocialService

PlayerGui = cloneref(Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui"))

COREGUI = Services.CoreGui or PlayerGui

IYMouse = cloneref(Players.LocalPlayer:GetMouse())

PlaceId, JobId = game.PlaceId, game.JobId

xpcall(function()

	IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform())

end, function()

	IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

end)

isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local iyassets = {

	["slate/iy/assets/bindsandplugins.png"] = "rbxassetid://5147695474",

	["slate/iy/assets/close.png"] = "rbxassetid://5054663650",

	["slate/iy/assets/editaliases.png"] = "rbxassetid://5147488658",

	["slate/iy/assets/editkeybinds.png"] = "rbxassetid://129697930",

	["slate/iy/assets/edittheme.png"] = "rbxassetid://4911962991",

	["slate/iy/assets/editwaypoints.png"] = "rbxassetid://5147488592",

	["slate/iy/assets/imgstudiopluginlogo.png"] = "rbxassetid://4113050383",

	["slate/iy/assets/logo.png"] = "rbxassetid://1352543873",

	["slate/iy/assets/minimize.png"] = "rbxassetid://2406617031",

	["slate/iy/assets/pin.png"] = "rbxassetid://6234691350",

	["slate/iy/assets/reference.png"] = "rbxassetid://3523243755",

	["slate/iy/assets/settings.png"] = "rbxassetid://1204397029"

}

function getcustomasset(asset)

	if waxgetcustomasset then

		local success, result = pcall(function()

			return waxgetcustomasset(asset)

		end)

		if success and result ~= nil and result ~= "" then

			return result

		end

	end

	return iyassets[asset]

end

if makefolder and isfolder and writefile and isfile then

	pcall(function()

		local assets = "https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/"

		for _, folder in {"slate/iy", "slate/iy/assets"} do

			if not isfolder(folder) then

				makefolder(folder)

			end

		end

		for path in iyassets do

			if not isfile(path) then

				writefile(path, game:HttpGet((path:gsub("infiniteyield/", assets))))

			end

		end

		if IsOnMobile then writefile("slate/iy/assets/.nomedia", "") end

	end)

end

currentVersion = "6.4"

ScaledHolder = Instance.new("Frame")

Scale = Instance.new("UIScale")

Holder = Instance.new("Frame")

Title = Instance.new("TextLabel")

Dark = Instance.new("Frame")

Cmdbar = Instance.new("TextBox")

CMDsF = Instance.new("ScrollingFrame")

cmdListLayout = Instance.new("UIListLayout")

SettingsButton = Instance.new("ImageButton")

ColorsButton = Instance.new("ImageButton")

Settings = Instance.new("Frame")

Prefix = Instance.new("TextLabel")

PrefixBox = Instance.new("TextBox")

Keybinds = Instance.new("TextLabel")

StayOpen = Instance.new("TextLabel")

Button = Instance.new("Frame")

On = Instance.new("TextButton")

Positions = Instance.new("TextLabel")

EventBind = Instance.new("TextLabel")

Plugins = Instance.new("TextLabel")

Example = Instance.new("TextButton")

Notification = Instance.new("Frame")

Title_2 = Instance.new("TextLabel")

Text_2 = Instance.new("TextLabel")

CloseButton = Instance.new("TextButton")

CloseImage = Instance.new("ImageLabel")

PinButton = Instance.new("TextButton")

PinImage = Instance.new("ImageLabel")

Tooltip = Instance.new("Frame")

Title_3 = Instance.new("TextLabel")

Description = Instance.new("TextLabel")

IntroBackground = Instance.new("Frame")

Logo = Instance.new("ImageLabel")

Credits = Instance.new("TextBox")

KeybindsFrame = Instance.new("Frame")

Close = Instance.new("TextButton")

Add = Instance.new("TextButton")

Delete = Instance.new("TextButton")

Holder_2 = Instance.new("ScrollingFrame")

Example_2 = Instance.new("Frame")

Text_3 = Instance.new("TextLabel")

Delete_2 = Instance.new("TextButton")

KeybindEditor = Instance.new("Frame")

background_2 = Instance.new("Frame")

Dark_3 = Instance.new("Frame")

Directions = Instance.new("TextLabel")

BindTo = Instance.new("TextButton")

TriggerLabel = Instance.new("TextLabel")

BindTriggerSelect = Instance.new("TextButton")

Add_2 = Instance.new("TextButton")

Toggles = Instance.new("ScrollingFrame")

ClickTP  = Instance.new("TextLabel")

Select = Instance.new("TextButton")

ClickDelete = Instance.new("TextLabel")

Select_2 = Instance.new("TextButton")

Cmdbar_2 = Instance.new("TextBox")

Cmdbar_3 = Instance.new("TextBox")

CreateToggle = Instance.new("TextLabel")

Button_2 = Instance.new("Frame")

On_2 = Instance.new("TextButton")

shadow_2 = Instance.new("Frame")

PopupText_2 = Instance.new("TextLabel")

Exit_2 = Instance.new("TextButton")

ExitImage_2 = Instance.new("ImageLabel")

PositionsFrame = Instance.new("Frame")

Close_3 = Instance.new("TextButton")

Delete_5 = Instance.new("TextButton")

Part = Instance.new("TextButton")

Holder_4 = Instance.new("ScrollingFrame")

Example_4 = Instance.new("Frame")

Text_5 = Instance.new("TextLabel")

Delete_6 = Instance.new("TextButton")

TP = Instance.new("TextButton")

AliasesFrame = Instance.new("Frame")

Close_2 = Instance.new("TextButton")

Delete_3 = Instance.new("TextButton")

Holder_3 = Instance.new("ScrollingFrame")

Example_3 = Instance.new("Frame")

Text_4 = Instance.new("TextLabel")

Delete_4 = Instance.new("TextButton")

Aliases = Instance.new("TextLabel")

PluginsFrame = Instance.new("Frame")

Close_4 = Instance.new("TextButton")

Add_3 = Instance.new("TextButton")

Holder_5 = Instance.new("ScrollingFrame")

Example_5 = Instance.new("Frame")

Text_6 = Instance.new("TextLabel")

Delete_7 = Instance.new("TextButton")

PluginEditor = Instance.new("Frame")

background_3 = Instance.new("Frame")

Dark_2 = Instance.new("Frame")

Img = Instance.new("ImageButton")

AddPlugin = Instance.new("TextButton")

FileName = Instance.new("TextBox")

About = Instance.new("TextLabel")

Directions_2 = Instance.new("TextLabel")

shadow_3 = Instance.new("Frame")

PopupText_3 = Instance.new("TextLabel")

Exit_3 = Instance.new("TextButton")

ExitImage_3 = Instance.new("ImageLabel")

AliasHint = Instance.new("TextLabel")

PluginsHint = Instance.new("TextLabel")

PositionsHint = Instance.new("TextLabel")

ToPartFrame = Instance.new("Frame")

background_4 = Instance.new("Frame")

ChoosePart = Instance.new("TextButton")

CopyPath = Instance.new("TextButton")

Directions_3 = Instance.new("TextLabel")

Path = Instance.new("TextLabel")

shadow_4 = Instance.new("Frame")

PopupText_5 = Instance.new("TextLabel")

Exit_4 = Instance.new("TextButton")

ExitImage_5 = Instance.new("ImageLabel")

logs = Instance.new("Frame")

shadow = Instance.new("Frame")

Hide = Instance.new("TextButton")

ImageLabel = Instance.new("ImageLabel")

PopupText = Instance.new("TextLabel")

Exit = Instance.new("TextButton")

ImageLabel_2 = Instance.new("ImageLabel")

background = Instance.new("Frame")

chat = Instance.new("Frame")

Clear = Instance.new("TextButton")

SaveChatlogs = Instance.new("TextButton")

Toggle = Instance.new("TextButton")

scroll_2 = Instance.new("ScrollingFrame")

join = Instance.new("Frame")

Toggle_2 = Instance.new("TextButton")

Clear_2 = Instance.new("TextButton")

scroll_3 = Instance.new("ScrollingFrame")

listlayout = Instance.new("UIListLayout",scroll_3)

selectChat = Instance.new("TextButton")

selectJoin = Instance.new("TextButton")

function randomString()

	local length = math.random(10,20)

	local array = {}

	for i = 1, length do

		array[i] = string.char(math.random(32, 126))

	end

	return table.concat(array)

end

PARENT = nil

MAX_DISPLAY_ORDER = 2147483647

if get_hidden_gui or gethui then

    local hiddenUI = get_hidden_gui or gethui

    local Main = Instance.new("ScreenGui")

    Main.Name = randomString()

    Main.ResetOnSpawn = false

    Main.DisplayOrder = MAX_DISPLAY_ORDER

    Main.Parent = hiddenUI()

    PARENT = Main

elseif (not is_sirhurt_closure) and (syn and syn.protect_gui) then

    local Main = Instance.new("ScreenGui")

    Main.Name = randomString()

    Main.ResetOnSpawn = false

    Main.DisplayOrder = MAX_DISPLAY_ORDER

    syn.protect_gui(Main)

    Main.Parent = COREGUI

    PARENT = Main

elseif COREGUI:FindFirstChild("RobloxGui") then

    PARENT = COREGUI.RobloxGui

else

    local Main = Instance.new("ScreenGui")

    Main.Name = randomString()

    Main.ResetOnSpawn = false

    Main.DisplayOrder = MAX_DISPLAY_ORDER

    Main.Parent = COREGUI

    PARENT = Main

end

shade1 = {}

shade2 = {}

shade3 = {}

text1 = {}

text2 = {}

scroll = {}

ScaledHolder.Name = randomString()

ScaledHolder.Size = UDim2.fromScale(1, 1)

ScaledHolder.BackgroundTransparency = 1

ScaledHolder.Parent = PARENT

ScaledHolder.Visible = false

Scale.Name = randomString()

Holder.Name = randomString()

Holder.Parent = ScaledHolder

Holder.Active = true

Holder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Holder.BorderSizePixel = 0

Holder.Position = UDim2.new(1, -250, 1, -220)

Holder.Size = UDim2.new(0, 250, 0, 220)

Holder.ZIndex = 10

table.insert(shade2,Holder)

Title.Name = "Title"

Title.Parent = Holder

Title.Active = true

Title.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

Title.BorderSizePixel = 0

Title.Size = UDim2.new(0, 250, 0, 20)

Title.Font = Enum.Font.SourceSans

Title.TextSize = 18

Title.Text = "Slate v" .. currentVersion

do

	local emoji = ({

		["01 01"] = "ðŸŽ†",

		[(function(Year)

			local A = math.floor(Year/100)

			local B = math.floor((13+8*A)/25)

			local C = (15-B+A-math.floor(A/4))%30

			local D = (4+A-math.floor(A/4))%7

			local E = (19*(Year%19)+C)%30

			local F = (2*(Year%4)+4*(Year%7)+6*E+D)%7

			local G = (22+E+F)

			if E == 29 and F == 6 then

				return "04 19"

			elseif E == 28 and F == 6 then

				return "04 18"

			elseif 31 < G then

				return ("04 %02d"):format(G-31)

			end

			return ("03 %02d"):format(G)

		end)(tonumber(os.date"%Y"))] = "ðŸ¥š",

		["10 31"] = "ðŸŽƒ",

		["12 25"] = "ðŸŽ„"

	})[os.date("%m %d")]

	if emoji then

		Title.Text = ("%s %s %s"):format(emoji, Title.Text, emoji)

	end

end

Title.TextColor3 = Color3.new(1, 1, 1)

Title.ZIndex = 10

table.insert(shade1,Title)

table.insert(text1,Title)

Dark.Name = "Dark"

Dark.Parent = Holder

Dark.Active = true

Dark.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

Dark.BorderSizePixel = 0

Dark.Position = UDim2.new(0, 0, 0, 45)

Dark.Size = UDim2.new(0, 250, 0, 175)

Dark.ZIndex = 10

table.insert(shade1,Dark)

Cmdbar.Name = "Cmdbar"

Cmdbar.Parent = Holder

Cmdbar.BackgroundTransparency = 1

Cmdbar.BorderSizePixel = 0

Cmdbar.Position = UDim2.new(0, 5, 0, 20)

Cmdbar.Size = UDim2.new(0, 240, 0, 25)

Cmdbar.Font = Enum.Font.SourceSans

Cmdbar.TextSize = 18

Cmdbar.TextXAlignment = Enum.TextXAlignment.Left

Cmdbar.TextColor3 = Color3.new(1, 1, 1)

Cmdbar.Text = ""

Cmdbar.ZIndex = 10

Cmdbar.PlaceholderText = "Command Bar"

CMDsF.Name = "CMDs"

CMDsF.Parent = Holder

CMDsF.BackgroundTransparency = 1

CMDsF.BorderSizePixel = 0

CMDsF.Position = UDim2.new(0, 5, 0, 45)

CMDsF.Size = UDim2.new(0, 245, 0, 175)

CMDsF.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)

CMDsF.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

CMDsF.CanvasSize = UDim2.new(0, 0, 0, 0)

CMDsF.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

CMDsF.ScrollBarThickness = 8
CMDsF.ScrollBarImageTransparency = 1

CMDsF.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

CMDsF.VerticalScrollBarInset = 'Always'

CMDsF.ZIndex = 10

table.insert(scroll,CMDsF)

cmdListLayout.Parent = CMDsF

SettingsButton.Name = "SettingsButton"

SettingsButton.Parent = Holder

SettingsButton.BackgroundTransparency = 1

SettingsButton.Position = UDim2.new(0, 230, 0, 0)

SettingsButton.Size = UDim2.new(0, 20, 0, 20)

SettingsButton.Image = getcustomasset("slate/iy/assets/settings.png")

SettingsButton.ZIndex = 10

ReferenceButton = Instance.new("ImageButton")

ReferenceButton.Name = "ReferenceButton"

ReferenceButton.Parent = Holder

ReferenceButton.BackgroundTransparency = 1

ReferenceButton.Position = UDim2.new(0, 212, 0, 2)

ReferenceButton.Size = UDim2.new(0, 16, 0, 16)

ReferenceButton.Image = getcustomasset("slate/iy/assets/reference.png")

ReferenceButton.ZIndex = 10

Settings.Name = "Settings"

Settings.Parent = Holder

Settings.Active = true

Settings.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

Settings.BorderSizePixel = 0

Settings.Position = UDim2.new(0, 0, 0, 220)

Settings.Size = UDim2.new(0, 250, 0, 175)

Settings.ZIndex = 10

table.insert(shade1,Settings)

SettingsHolder = Instance.new("ScrollingFrame")

SettingsHolder.Name = "Holder"

SettingsHolder.Parent = Settings

SettingsHolder.BackgroundTransparency = 1

SettingsHolder.BorderSizePixel = 0

SettingsHolder.Size = UDim2.new(1,0,1,0)

SettingsHolder.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)

SettingsHolder.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

SettingsHolder.CanvasSize = UDim2.new(0, 0, 0, 235)

SettingsHolder.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

SettingsHolder.ScrollBarThickness = 8
SettingsHolder.ScrollBarImageTransparency = 1

SettingsHolder.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

SettingsHolder.VerticalScrollBarInset = 'Always'

SettingsHolder.ZIndex = 10

table.insert(scroll,SettingsHolder)

Prefix.Name = "Prefix"

Prefix.Parent = SettingsHolder

Prefix.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Prefix.BorderSizePixel = 0

Prefix.BackgroundTransparency = 1

Prefix.Position = UDim2.new(0, 5, 0, 5)

Prefix.Size = UDim2.new(1, -10, 0, 20)

Prefix.Font = Enum.Font.SourceSans

Prefix.TextSize = 14

Prefix.Text = "Prefix"

Prefix.TextColor3 = Color3.new(1, 1, 1)

Prefix.TextXAlignment = Enum.TextXAlignment.Left

Prefix.ZIndex = 10

table.insert(shade2,Prefix)

table.insert(text1,Prefix)

PrefixBox.Name = "PrefixBox"

PrefixBox.Parent = Prefix

PrefixBox.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

PrefixBox.BorderSizePixel = 0

PrefixBox.Position = UDim2.new(1, -20, 0, 0)

PrefixBox.Size = UDim2.new(0, 20, 0, 20)

PrefixBox.Font = Enum.Font.SourceSansBold

PrefixBox.TextSize = 14

PrefixBox.Text = ''

PrefixBox.TextColor3 = Color3.new(0, 0, 0)

PrefixBox.ZIndex = 10

table.insert(shade3,PrefixBox)

table.insert(text2,PrefixBox)

function makeSettingsButton(name,iconID,off)

	local button = Instance.new("TextButton")

	button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

	button.BorderSizePixel = 0

	button.Position = UDim2.new(0,0,0,0)

	button.Size = UDim2.new(1,0,0,25)

	button.Text = ""

	button.ZIndex = 10

	local icon = Instance.new("ImageLabel")

	icon.Name = "Icon"

	icon.Parent = button

	icon.Position = UDim2.new(0,5,0,5)

	icon.Size = UDim2.new(0,16,0,16)

	icon.BackgroundTransparency = 1

	icon.Image = iconID

	icon.ZIndex = 10

	if off then

		icon.ScaleType = Enum.ScaleType.Crop

		icon.ImageRectSize = Vector2.new(16,16)

		icon.ImageRectOffset = Vector2.new(off,0)

	end

	local label = Instance.new("TextLabel")

	label.Name = "ButtonLabel"

	label.Parent = button

	label.BackgroundTransparency = 1

	label.Text = name

	label.Position = UDim2.new(0,28,0,0)

	label.Size = UDim2.new(1,-28,1,0)

	label.Font = Enum.Font.SourceSans

	label.TextColor3 = Color3.new(1, 1, 1)

	label.TextSize = 14

	label.ZIndex = 10

	label.TextXAlignment = Enum.TextXAlignment.Left

	table.insert(shade2,button)

	table.insert(text1,label)

	return button

end

ColorsButton = makeSettingsButton("Edit Theme",getcustomasset("slate/iy/assets/edittheme.png"))

ColorsButton.Position = UDim2.new(0, 5, 0, 55)

ColorsButton.Size = UDim2.new(1, -10, 0, 25)

ColorsButton.Name = "Colors"

ColorsButton.Parent = SettingsHolder

Keybinds = makeSettingsButton("Edit Keybinds",getcustomasset("slate/iy/assets/editkeybinds.png"))

Keybinds.Position = UDim2.new(0, 5, 0, 85)

Keybinds.Size = UDim2.new(1, -10, 0, 25)

Keybinds.Name = "Keybinds"

Keybinds.Parent = SettingsHolder

Aliases = makeSettingsButton("Edit Aliases",getcustomasset("slate/iy/assets/editaliases.png"))

Aliases.Position = UDim2.new(0, 5, 0, 115)

Aliases.Size = UDim2.new(1, -10, 0, 25)

Aliases.Name = "Aliases"

Aliases.Parent = SettingsHolder

StayOpen.Name = "StayOpen"

StayOpen.Parent = SettingsHolder

StayOpen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

StayOpen.BorderSizePixel = 0

StayOpen.BackgroundTransparency = 1

StayOpen.Position = UDim2.new(0, 5, 0, 30)

StayOpen.Size = UDim2.new(1, -10, 0, 20)

StayOpen.Font = Enum.Font.SourceSans

StayOpen.TextSize = 14

StayOpen.Text = "Keep Menu Open"

StayOpen.TextColor3 = Color3.new(1, 1, 1)

StayOpen.TextXAlignment = Enum.TextXAlignment.Left

StayOpen.ZIndex = 10

table.insert(shade2,StayOpen)

table.insert(text1,StayOpen)

Button.Name = "Button"

Button.Parent = StayOpen

Button.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Button.BorderSizePixel = 0

Button.Position = UDim2.new(1, -20, 0, 0)

Button.Size = UDim2.new(0, 20, 0, 20)

Button.ZIndex = 10

table.insert(shade3,Button)

On.Name = "On"

On.Parent = Button

On.BackgroundColor3 = Color3.fromRGB(150, 150, 151)

On.BackgroundTransparency = 1

On.BorderSizePixel = 0

On.Position = UDim2.new(0, 2, 0, 2)

On.Size = UDim2.new(0, 16, 0, 16)

On.Font = Enum.Font.SourceSans

On.FontSize = Enum.FontSize.Size14

On.Text = ""

On.TextColor3 = Color3.new(0, 0, 0)

On.ZIndex = 10

Positions = makeSettingsButton("Edit/Goto Waypoints",getcustomasset("slate/iy/assets/editwaypoints.png"))

Positions.Position = UDim2.new(0, 5, 0, 145)

Positions.Size = UDim2.new(1, -10, 0, 25)

Positions.Name = "Waypoints"

Positions.Parent = SettingsHolder

EventBind = makeSettingsButton("Edit Event Binds",getcustomasset("slate/iy/assets/bindsandplugins.png"),759)

EventBind.Position = UDim2.new(0, 5, 0, 205)

EventBind.Size = UDim2.new(1, -10, 0, 25)

EventBind.Name = "EventBinds"

EventBind.Parent = SettingsHolder

Plugins = makeSettingsButton("Manage Plugins",getcustomasset("slate/iy/assets/bindsandplugins.png"),743)

Plugins.Position = UDim2.new(0, 5, 0, 175)

Plugins.Size = UDim2.new(1, -10, 0, 25)

Plugins.Name = "Plugins"

Plugins.Parent = SettingsHolder

Example.Name = "Example"

Example.Parent = Holder

Example.BackgroundTransparency = 1

Example.BorderSizePixel = 0

Example.Size = UDim2.new(0, 190, 0, 20)

Example.Visible = false

Example.Font = Enum.Font.SourceSans

Example.TextSize = 18

Example.Text = "Example"

Example.TextColor3 = Color3.new(1, 1, 1)

Example.TextXAlignment = Enum.TextXAlignment.Left

Example.ZIndex = 10

table.insert(text1,Example)

Notification.Name = randomString()

Notification.Parent = ScaledHolder

Notification.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

Notification.BorderSizePixel = 0

Notification.Position = UDim2.new(1, -500, 1, 20)

Notification.Size = UDim2.new(0, 250, 0, 100)

Notification.ZIndex = 10

table.insert(shade1,Notification)

Title_2.Name = "Title"

Title_2.Parent = Notification

Title_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Title_2.BorderSizePixel = 0

Title_2.Size = UDim2.new(0, 250, 0, 20)

Title_2.Font = Enum.Font.SourceSans

Title_2.TextSize = 14

Title_2.Text = "Notification Title"

Title_2.TextColor3 = Color3.new(1, 1, 1)

Title_2.ZIndex = 10

table.insert(shade2,Title_2)

table.insert(text1,Title_2)

Text_2.Name = "Text"

Text_2.Parent = Notification

Text_2.BackgroundTransparency = 1

Text_2.BorderSizePixel = 0

Text_2.Position = UDim2.new(0, 5, 0, 25)

Text_2.Size = UDim2.new(0, 240, 0, 75)

Text_2.Font = Enum.Font.SourceSans

Text_2.TextSize = 16

Text_2.Text = "Notification Text"

Text_2.TextColor3 = Color3.new(1, 1, 1)

Text_2.TextWrapped = true

Text_2.ZIndex = 10

table.insert(text1,Text_2)

CloseButton.Name = "CloseButton"

CloseButton.Parent = Notification

CloseButton.BackgroundTransparency = 1

CloseButton.Position = UDim2.new(1, -20, 0, 0)

CloseButton.Size = UDim2.new(0, 20, 0, 20)

CloseButton.Text = ""

CloseButton.ZIndex = 10

CloseImage.Parent = CloseButton

CloseImage.BackgroundColor3 = Color3.new(1, 1, 1)

CloseImage.BackgroundTransparency = 1

CloseImage.Position = UDim2.new(0, 5, 0, 5)

CloseImage.Size = UDim2.new(0, 10, 0, 10)

CloseImage.Image = getcustomasset("slate/iy/assets/close.png")

CloseImage.ZIndex = 10

PinButton.Name = "PinButton"

PinButton.Parent = Notification

PinButton.BackgroundTransparency = 1

PinButton.Size = UDim2.new(0, 20, 0, 20)

PinButton.ZIndex = 10

PinButton.Text = ""

PinImage.Parent = PinButton

PinImage.BackgroundColor3 = Color3.new(1, 1, 1)

PinImage.BackgroundTransparency = 1

PinImage.Position = UDim2.new(0, 3, 0, 3)

PinImage.Size = UDim2.new(0, 14, 0, 14)

PinImage.ZIndex = 10

PinImage.Image = getcustomasset("slate/iy/assets/pin.png")

Tooltip.Name = randomString()

Tooltip.Parent = ScaledHolder

Tooltip.Active = true

Tooltip.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

Tooltip.BackgroundTransparency = 0.1

Tooltip.BorderSizePixel = 0

Tooltip.Size = UDim2.new(0, 200, 0, 96)

Tooltip.Visible = false

Tooltip.ZIndex = 10

table.insert(shade1,Tooltip)

Title_3.Name = "Title"

Title_3.Parent = Tooltip

Title_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Title_3.BackgroundTransparency = 0.1

Title_3.BorderSizePixel = 0

Title_3.Size = UDim2.new(0, 200, 0, 20)

Title_3.Font = Enum.Font.SourceSans

Title_3.TextSize = 14

Title_3.Text = ""

Title_3.TextColor3 = Color3.new(1, 1, 1)

Title_3.TextTransparency = 0.1

Title_3.ZIndex = 10

table.insert(shade2,Title_3)

table.insert(text1,Title_3)

Description.Name = "Description"

Description.Parent = Tooltip

Description.BackgroundTransparency = 1

Description.BorderSizePixel = 0

Description.Size = UDim2.new(0,180,0,72)

Description.Position = UDim2.new(0,10,0,18)

Description.Font = Enum.Font.SourceSans

Description.TextSize = 16

Description.Text = ""

Description.TextColor3 = Color3.new(1, 1, 1)

Description.TextTransparency = 0.1

Description.TextWrapped = true

Description.ZIndex = 10

table.insert(text1,Description)

IntroBackground.Name = "IntroBackground"

IntroBackground.Parent = Holder

IntroBackground.Active = true

IntroBackground.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

IntroBackground.BorderSizePixel = 0

IntroBackground.Position = UDim2.new(0, 0, 0, 45)

IntroBackground.Size = UDim2.new(0, 250, 0, 175)

IntroBackground.ZIndex = 10

Logo.Name = "Logo"

Logo.Parent = Holder

Logo.BackgroundTransparency = 1

Logo.BorderSizePixel = 0

Logo.Position = UDim2.new(0, 125, 0, 127)

Logo.Size = UDim2.new(0, 10, 0, 10)

Logo.Image = getcustomasset("slate/iy/assets/logo.png")

Logo.ImageTransparency = 0

Logo.ZIndex = 10

Credits.Name = "Credits"

Credits.Parent = Holder

Credits.BackgroundTransparency = 1

Credits.BorderSizePixel = 0

Credits.Position = UDim2.new(0, 0, 0.9, 30)

Credits.Size = UDim2.new(0, 250, 0, 20)

Credits.Font = Enum.Font.SourceSansLight

Credits.FontSize = Enum.FontSize.Size14

Credits.Text = "Edge // Zwolf // Moon // Toon // Peyton // ATP"

Credits.TextColor3 = Color3.new(1, 1, 1)

Credits.ZIndex = 10

KeybindsFrame.Name = "KeybindsFrame"

KeybindsFrame.Parent = Settings

KeybindsFrame.Active = true

KeybindsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

KeybindsFrame.BorderSizePixel = 0

KeybindsFrame.Position = UDim2.new(0, 0, 0, 175)

KeybindsFrame.Size = UDim2.new(0, 250, 0, 175)

KeybindsFrame.ZIndex = 10

table.insert(shade1,KeybindsFrame)

Close.Name = "Close"

Close.Parent = KeybindsFrame

Close.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Close.BorderSizePixel = 0

Close.Position = UDim2.new(0, 205, 0, 150)

Close.Size = UDim2.new(0, 40, 0, 20)

Close.Font = Enum.Font.SourceSans

Close.TextSize = 14

Close.Text = "Close"

Close.TextColor3 = Color3.new(1, 1, 1)

Close.ZIndex = 10

table.insert(shade2,Close)

table.insert(text1,Close)

Add.Name = "Add"

Add.Parent = KeybindsFrame

Add.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Add.BorderSizePixel = 0

Add.Position = UDim2.new(0, 5, 0, 150)

Add.Size = UDim2.new(0, 40, 0, 20)

Add.Font = Enum.Font.SourceSans

Add.TextSize = 14

Add.Text = "Add"

Add.TextColor3 = Color3.new(1, 1, 1)

Add.ZIndex = 10

table.insert(shade2,Add)

table.insert(text1,Add)

Delete.Name = "Delete"

Delete.Parent = KeybindsFrame

Delete.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Delete.BorderSizePixel = 0

Delete.Position = UDim2.new(0, 50, 0, 150)

Delete.Size = UDim2.new(0, 40, 0, 20)

Delete.Font = Enum.Font.SourceSans

Delete.TextSize = 14

Delete.Text = "Clear"

Delete.TextColor3 = Color3.new(1, 1, 1)

Delete.ZIndex = 10

table.insert(shade2,Delete)

table.insert(text1,Delete)

Holder_2.Name = "Holder"

Holder_2.Parent = KeybindsFrame

Holder_2.BackgroundTransparency = 1

Holder_2.BorderSizePixel = 0

Holder_2.Position = UDim2.new(0, 0, 0, 0)

Holder_2.Size = UDim2.new(0, 250, 0, 145)

Holder_2.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)

Holder_2.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_2.CanvasSize = UDim2.new(0, 0, 0, 0)

Holder_2.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_2.ScrollBarThickness = 0
Holder_2.ScrollBarImageTransparency = 1

Holder_2.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_2.VerticalScrollBarInset = 'Always'

Holder_2.ZIndex = 10

Example_2.Name = "Example"

Example_2.Parent = KeybindsFrame

Example_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Example_2.BorderSizePixel = 0

Example_2.Size = UDim2.new(0, 10, 0, 20)

Example_2.Visible = false

Example_2.ZIndex = 10

table.insert(shade2,Example_2)

Text_3.Name = "Text"

Text_3.Parent = Example_2

Text_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Text_3.BorderSizePixel = 0

Text_3.Position = UDim2.new(0, 10, 0, 0)

Text_3.Size = UDim2.new(0, 240, 0, 20)

Text_3.Font = Enum.Font.SourceSans

Text_3.TextSize = 14

Text_3.Text = "nom"

Text_3.TextColor3 = Color3.new(1, 1, 1)

Text_3.TextXAlignment = Enum.TextXAlignment.Left

Text_3.ZIndex = 10

table.insert(shade2,Text_3)

table.insert(text1,Text_3)

Delete_2.Name = "Delete"

Delete_2.Parent = Text_3

Delete_2.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Delete_2.BorderSizePixel = 0

Delete_2.Position = UDim2.new(0, 200, 0, 0)

Delete_2.Size = UDim2.new(0, 40, 0, 20)

Delete_2.Font = Enum.Font.SourceSans

Delete_2.TextSize = 14

Delete_2.Text = "Delete"

Delete_2.TextColor3 = Color3.new(0, 0, 0)

Delete_2.ZIndex = 10

table.insert(shade3,Delete_2)

table.insert(text2,Delete_2)

KeybindEditor.Name = randomString()

KeybindEditor.Parent = ScaledHolder

KeybindEditor.Active = true

KeybindEditor.BackgroundTransparency = 1

KeybindEditor.Position = UDim2.new(0.5, -180, 0, -500)

KeybindEditor.Size = UDim2.new(0, 360, 0, 20)

KeybindEditor.ZIndex = 10

background_2.Name = "background"

background_2.Parent = KeybindEditor

background_2.Active = true

background_2.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

background_2.BorderSizePixel = 0

background_2.Position = UDim2.new(0, 0, 0, 20)

background_2.Size = UDim2.new(0, 360, 0, 185)

background_2.ZIndex = 10

table.insert(shade1,background_2)

Dark_3.Name = "Dark"

Dark_3.Parent = background_2

Dark_3.Active = true

Dark_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Dark_3.BorderSizePixel = 0

Dark_3.Position = UDim2.new(0, 135, 0, 0)

Dark_3.Size = UDim2.new(0, 2, 0, 185)

Dark_3.ZIndex = 10

table.insert(shade2,Dark_3)

Directions.Name = "Directions"

Directions.Parent = background_2

Directions.BackgroundTransparency = 1

Directions.BorderSizePixel = 0

Directions.Position = UDim2.new(0, 10, 0, 15)

Directions.Size = UDim2.new(0, 115, 0, 90)

Directions.ZIndex = 10

Directions.Font = Enum.Font.SourceSans

Directions.Text = "Click the button below and press a key/mouse button. Then select what you want to bind it to."

Directions.TextColor3 = Color3.fromRGB(255, 255, 255)

Directions.TextSize = 14.000

Directions.TextWrapped = true

Directions.TextYAlignment = Enum.TextYAlignment.Top

table.insert(text1,Directions)

BindTo.Name = "BindTo"

BindTo.Parent = background_2

BindTo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

BindTo.BorderSizePixel = 0

BindTo.Position = UDim2.new(0, 10, 0, 95)

BindTo.Size = UDim2.new(0, 115, 0, 50)

BindTo.ZIndex = 10

BindTo.Font = Enum.Font.SourceSans

BindTo.Text = "Click to bind"

BindTo.TextColor3 = Color3.fromRGB(255, 255, 255)

BindTo.TextSize = 16.000

table.insert(shade2,BindTo)

table.insert(text1,BindTo)

TriggerLabel.Name = "TriggerLabel"

TriggerLabel.Parent = background_2

TriggerLabel.BackgroundTransparency = 1

TriggerLabel.Position = UDim2.new(0, 10, 0, 155)

TriggerLabel.Size = UDim2.new(0, 45, 0, 20)

TriggerLabel.ZIndex = 10

TriggerLabel.Font = Enum.Font.SourceSans

TriggerLabel.Text = "Trigger:"

TriggerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

TriggerLabel.TextSize = 14.000

TriggerLabel.TextXAlignment = Enum.TextXAlignment.Left

table.insert(text1,TriggerLabel)

BindTriggerSelect.Name = "BindTo"

BindTriggerSelect.Parent = background_2

BindTriggerSelect.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

BindTriggerSelect.BorderSizePixel = 0

BindTriggerSelect.Position = UDim2.new(0, 60, 0, 155)

BindTriggerSelect.Size = UDim2.new(0, 65, 0, 20)

BindTriggerSelect.ZIndex = 10

BindTriggerSelect.Font = Enum.Font.SourceSans

BindTriggerSelect.Text = "KeyDown"

BindTriggerSelect.TextColor3 = Color3.fromRGB(255, 255, 255)

BindTriggerSelect.TextSize = 16.000

table.insert(shade2,BindTriggerSelect)

table.insert(text1,BindTriggerSelect)

Add_2.Name = "Add"

Add_2.Parent = background_2

Add_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Add_2.BorderSizePixel = 0

Add_2.Position = UDim2.new(0, 310, 0, 35)

Add_2.Size = UDim2.new(0, 40, 0, 20)

Add_2.ZIndex = 10

Add_2.Font = Enum.Font.SourceSans

Add_2.Text = "Add"

Add_2.TextColor3 = Color3.fromRGB(255, 255, 255)

Add_2.TextSize = 14.000

table.insert(shade2,Add_2)

table.insert(text1,Add_2)

Toggles.Name = "Toggles"

Toggles.Parent = background_2

Toggles.BackgroundTransparency = 1

Toggles.BorderSizePixel = 0

Toggles.Position = UDim2.new(0, 150, 0, 125)

Toggles.Size = UDim2.new(0, 200, 0, 50)

Toggles.ZIndex = 10

Toggles.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Toggles.CanvasSize = UDim2.new(0, 0, 0, 50)

Toggles.ScrollBarThickness = 8
Toggles.ScrollBarImageTransparency = 1

Toggles.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Toggles.VerticalScrollBarInset = Enum.ScrollBarInset.Always

table.insert(scroll,Toggles)

ClickTP.Name = "Click TP (Hold Key & Click)"

ClickTP.Parent = Toggles

ClickTP.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

ClickTP.BorderSizePixel = 0

ClickTP.Size = UDim2.new(0, 200, 0, 20)

ClickTP.ZIndex = 10

ClickTP.Font = Enum.Font.SourceSans

ClickTP.Text = "    Click TP (Hold Key & Click)"

ClickTP.TextColor3 = Color3.fromRGB(255, 255, 255)

ClickTP.TextSize = 14.000

ClickTP.TextXAlignment = Enum.TextXAlignment.Left

table.insert(shade2,ClickTP)

table.insert(text1,ClickTP)

Select.Name = "Select"

Select.Parent = ClickTP

Select.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Select.BorderSizePixel = 0

Select.Position = UDim2.new(0, 160, 0, 0)

Select.Size = UDim2.new(0, 40, 0, 20)

Select.ZIndex = 10

Select.Font = Enum.Font.SourceSans

Select.Text = "Add"

Select.TextColor3 = Color3.fromRGB(0, 0, 0)

Select.TextSize = 14.000

table.insert(shade3,Select)

table.insert(text2,Select)

ClickDelete.Name = "Click Delete (Hold Key & Click)"

ClickDelete.Parent = Toggles

ClickDelete.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

ClickDelete.BorderSizePixel = 0

ClickDelete.Position = UDim2.new(0, 0, 0, 25)

ClickDelete.Size = UDim2.new(0, 200, 0, 20)

ClickDelete.ZIndex = 10

ClickDelete.Font = Enum.Font.SourceSans

ClickDelete.Text = "    Click Delete (Hold Key & Click)"

ClickDelete.TextColor3 = Color3.fromRGB(255, 255, 255)

ClickDelete.TextSize = 14.000

ClickDelete.TextXAlignment = Enum.TextXAlignment.Left

table.insert(shade2,ClickDelete)

table.insert(text1,ClickDelete)

Select_2.Name = "Select"

Select_2.Parent = ClickDelete

Select_2.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Select_2.BorderSizePixel = 0

Select_2.Position = UDim2.new(0, 160, 0, 0)

Select_2.Size = UDim2.new(0, 40, 0, 20)

Select_2.ZIndex = 10

Select_2.Font = Enum.Font.SourceSans

Select_2.Text = "Add"

Select_2.TextColor3 = Color3.fromRGB(0, 0, 0)

Select_2.TextSize = 14.000

table.insert(shade3,Select_2)

table.insert(text2,Select_2)

Cmdbar_2.Name = "Cmdbar_2"

Cmdbar_2.Parent = background_2

Cmdbar_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Cmdbar_2.BorderSizePixel = 0

Cmdbar_2.Position = UDim2.new(0, 150, 0, 35)

Cmdbar_2.Size = UDim2.new(0, 150, 0, 20)

Cmdbar_2.ZIndex = 10

Cmdbar_2.Font = Enum.Font.SourceSans

Cmdbar_2.PlaceholderText = "Command"

Cmdbar_2.Text = ""

Cmdbar_2.TextColor3 = Color3.fromRGB(255, 255, 255)

Cmdbar_2.TextSize = 14.000

Cmdbar_2.TextXAlignment = Enum.TextXAlignment.Left

Cmdbar_3.Name = "Cmdbar_3"

Cmdbar_3.Parent = background_2

Cmdbar_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Cmdbar_3.BorderSizePixel = 0

Cmdbar_3.Position = UDim2.new(0, 150, 0, 60)

Cmdbar_3.Size = UDim2.new(0, 150, 0, 20)

Cmdbar_3.ZIndex = 10

Cmdbar_3.Font = Enum.Font.SourceSans

Cmdbar_3.PlaceholderText = "Command 2"

Cmdbar_3.Text = ""

Cmdbar_3.TextColor3 = Color3.fromRGB(255, 255, 255)

Cmdbar_3.TextSize = 14.000

Cmdbar_3.TextXAlignment = Enum.TextXAlignment.Left

CreateToggle.Name = "CreateToggle"

CreateToggle.Parent = background_2

CreateToggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

CreateToggle.BackgroundTransparency = 1

CreateToggle.BorderSizePixel = 0

CreateToggle.Position = UDim2.new(0, 152, 0, 10)

CreateToggle.Size = UDim2.new(0, 198, 0, 20)

CreateToggle.ZIndex = 10

CreateToggle.Font = Enum.Font.SourceSans

CreateToggle.Text = "Create Toggle"

CreateToggle.TextColor3 = Color3.fromRGB(255, 255, 255)

CreateToggle.TextSize = 14.000

CreateToggle.TextXAlignment = Enum.TextXAlignment.Left

table.insert(text1,CreateToggle)

Button_2.Name = "Button"

Button_2.Parent = CreateToggle

Button_2.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Button_2.BorderSizePixel = 0

Button_2.Position = UDim2.new(1, -20, 0, 0)

Button_2.Size = UDim2.new(0, 20, 0, 20)

Button_2.ZIndex = 10

table.insert(shade3,Button_2)

On_2.Name = "On"

On_2.Parent = Button_2

On_2.BackgroundColor3 = Color3.fromRGB(150, 150, 151)

On_2.BackgroundTransparency = 1

On_2.BorderSizePixel = 0

On_2.Position = UDim2.new(0, 2, 0, 2)

On_2.Size = UDim2.new(0, 16, 0, 16)

On_2.ZIndex = 10

On_2.Font = Enum.Font.SourceSans

On_2.Text = ""

On_2.TextColor3 = Color3.fromRGB(0, 0, 0)

On_2.TextSize = 14.000

shadow_2.Name = "shadow"

shadow_2.Parent = KeybindEditor

shadow_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

shadow_2.BorderSizePixel = 0

shadow_2.Size = UDim2.new(0, 360, 0, 20)

shadow_2.ZIndex = 10

table.insert(shade2,shadow_2)

PopupText_2.Name = "PopupText_2"

PopupText_2.Parent = shadow_2

PopupText_2.BackgroundTransparency = 1

PopupText_2.Size = UDim2.new(1, 0, 0.949999988, 0)

PopupText_2.ZIndex = 10

PopupText_2.Font = Enum.Font.SourceSans

PopupText_2.Text = "Set Keybinds"

PopupText_2.TextColor3 = Color3.fromRGB(255, 255, 255)

PopupText_2.TextSize = 14.000

PopupText_2.TextWrapped = true

table.insert(text1,PopupText_2)

Exit_2.Name = "Exit_2"

Exit_2.Parent = shadow_2

Exit_2.BackgroundTransparency = 1

Exit_2.Position = UDim2.new(1, -20, 0, 0)

Exit_2.Size = UDim2.new(0, 20, 0, 20)

Exit_2.ZIndex = 10

Exit_2.Text = ""

ExitImage_2.Parent = Exit_2

ExitImage_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

ExitImage_2.BackgroundTransparency = 1

ExitImage_2.Position = UDim2.new(0, 5, 0, 5)

ExitImage_2.Size = UDim2.new(0, 10, 0, 10)

ExitImage_2.ZIndex = 10

ExitImage_2.Image = getcustomasset("slate/iy/assets/close.png")

PositionsFrame.Name = "PositionsFrame"

PositionsFrame.Parent = Settings

PositionsFrame.Active = true

PositionsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

PositionsFrame.BorderSizePixel = 0

PositionsFrame.Size = UDim2.new(0, 250, 0, 175)

PositionsFrame.Position = UDim2.new(0, 0, 0, 175)

PositionsFrame.ZIndex = 10

table.insert(shade1,PositionsFrame)

Close_3.Name = "Close"

Close_3.Parent = PositionsFrame

Close_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Close_3.BorderSizePixel = 0

Close_3.Position = UDim2.new(0, 205, 0, 150)

Close_3.Size = UDim2.new(0, 40, 0, 20)

Close_3.Font = Enum.Font.SourceSans

Close_3.TextSize = 14

Close_3.Text = "Close"

Close_3.TextColor3 = Color3.new(1, 1, 1)

Close_3.ZIndex = 10

table.insert(shade2,Close_3)

table.insert(text1,Close_3)

Delete_5.Name = "Delete"

Delete_5.Parent = PositionsFrame

Delete_5.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Delete_5.BorderSizePixel = 0

Delete_5.Position = UDim2.new(0, 50, 0, 150)

Delete_5.Size = UDim2.new(0, 40, 0, 20)

Delete_5.Font = Enum.Font.SourceSans

Delete_5.TextSize = 14

Delete_5.Text = "Clear"

Delete_5.TextColor3 = Color3.new(1, 1, 1)

Delete_5.ZIndex = 10

table.insert(shade2,Delete_5)

table.insert(text1,Delete_5)

Part.Name = "PartGoto"

Part.Parent = PositionsFrame

Part.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Part.BorderSizePixel = 0

Part.Position = UDim2.new(0, 5, 0, 150)

Part.Size = UDim2.new(0, 40, 0, 20)

Part.Font = Enum.Font.SourceSans

Part.TextSize = 14

Part.Text = "Part"

Part.TextColor3 = Color3.new(1, 1, 1)

Part.ZIndex = 10

table.insert(shade2,Part)

table.insert(text1,Part)

Holder_4.Name = "Holder"

Holder_4.Parent = PositionsFrame

Holder_4.BackgroundTransparency = 1

Holder_4.BorderSizePixel = 0

Holder_4.Position = UDim2.new(0, 0, 0, 0)

Holder_4.Selectable = false

Holder_4.Size = UDim2.new(0, 250, 0, 145)

Holder_4.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)

Holder_4.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_4.CanvasSize = UDim2.new(0, 0, 0, 0)

Holder_4.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_4.ScrollBarThickness = 0
Holder_4.ScrollBarImageTransparency = 1

Holder_4.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_4.VerticalScrollBarInset = 'Always'

Holder_4.ZIndex = 10

Example_4.Name = "Example"

Example_4.Parent = PositionsFrame

Example_4.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Example_4.BorderSizePixel = 0

Example_4.Size = UDim2.new(0, 10, 0, 20)

Example_4.Visible = false

Example_4.Position = UDim2.new(0, 0, 0, -5)

Example_4.ZIndex = 10

table.insert(shade2,Example_4)

Text_5.Name = "Text"

Text_5.Parent = Example_4

Text_5.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Text_5.BorderSizePixel = 0

Text_5.Position = UDim2.new(0, 10, 0, 0)

Text_5.Size = UDim2.new(0, 240, 0, 20)

Text_5.Font = Enum.Font.SourceSans

Text_5.TextSize = 14

Text_5.Text = "Position"

Text_5.TextColor3 = Color3.new(1, 1, 1)

Text_5.TextXAlignment = Enum.TextXAlignment.Left

Text_5.ZIndex = 10

table.insert(shade2,Text_5)

table.insert(text1,Text_5)

Delete_6.Name = "Delete"

Delete_6.Parent = Text_5

Delete_6.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Delete_6.BorderSizePixel = 0

Delete_6.Position = UDim2.new(0, 200, 0, 0)

Delete_6.Size = UDim2.new(0, 40, 0, 20)

Delete_6.Font = Enum.Font.SourceSans

Delete_6.TextSize = 14

Delete_6.Text = "Delete"

Delete_6.TextColor3 = Color3.new(0, 0, 0)

Delete_6.ZIndex = 10

table.insert(shade3,Delete_6)

table.insert(text2,Delete_6)

TP.Name = "TP"

TP.Parent = Text_5

TP.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

TP.BorderSizePixel = 0

TP.Position = UDim2.new(0, 155, 0, 0)

TP.Size = UDim2.new(0, 40, 0, 20)

TP.Font = Enum.Font.SourceSans

TP.TextSize = 14

TP.Text = "Goto"

TP.TextColor3 = Color3.new(0, 0, 0)

TP.ZIndex = 10

table.insert(shade3,TP)

table.insert(text2,TP)

AliasesFrame.Name = "AliasesFrame"

AliasesFrame.Parent = Settings

AliasesFrame.Active = true

AliasesFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

AliasesFrame.BorderSizePixel = 0

AliasesFrame.Position = UDim2.new(0, 0, 0, 175)

AliasesFrame.Size = UDim2.new(0, 250, 0, 175)

AliasesFrame.ZIndex = 10

table.insert(shade1,AliasesFrame)

Close_2.Name = "Close"

Close_2.Parent = AliasesFrame

Close_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Close_2.BorderSizePixel = 0

Close_2.Position = UDim2.new(0, 205, 0, 150)

Close_2.Size = UDim2.new(0, 40, 0, 20)

Close_2.Font = Enum.Font.SourceSans

Close_2.TextSize = 14

Close_2.Text = "Close"

Close_2.TextColor3 = Color3.new(1, 1, 1)

Close_2.ZIndex = 10

table.insert(shade2,Close_2)

table.insert(text1,Close_2)

Delete_3.Name = "Delete"

Delete_3.Parent = AliasesFrame

Delete_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Delete_3.BorderSizePixel = 0

Delete_3.Position = UDim2.new(0, 5, 0, 150)

Delete_3.Size = UDim2.new(0, 40, 0, 20)

Delete_3.Font = Enum.Font.SourceSans

Delete_3.TextSize = 14

Delete_3.Text = "Clear"

Delete_3.TextColor3 = Color3.new(1, 1, 1)

Delete_3.ZIndex = 10

table.insert(shade2,Delete_3)

table.insert(text1,Delete_3)

Holder_3.Name = "Holder"

Holder_3.Parent = AliasesFrame

Holder_3.BackgroundTransparency = 1

Holder_3.BorderSizePixel = 0

Holder_3.Position = UDim2.new(0, 0, 0, 0)

Holder_3.Size = UDim2.new(0, 250, 0, 145)

Holder_3.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)

Holder_3.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_3.CanvasSize = UDim2.new(0, 0, 0, 0)

Holder_3.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_3.ScrollBarThickness = 0
Holder_3.ScrollBarImageTransparency = 1

Holder_3.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_3.VerticalScrollBarInset = 'Always'

Holder_3.ZIndex = 10

Example_3.Name = "Example"

Example_3.Parent = AliasesFrame

Example_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Example_3.BorderSizePixel = 0

Example_3.Size = UDim2.new(0, 10, 0, 20)

Example_3.Visible = false

Example_3.ZIndex = 10

table.insert(shade2,Example_3)

Text_4.Name = "Text"

Text_4.Parent = Example_3

Text_4.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Text_4.BorderSizePixel = 0

Text_4.Position = UDim2.new(0, 10, 0, 0)

Text_4.Size = UDim2.new(0, 240, 0, 20)

Text_4.Font = Enum.Font.SourceSans

Text_4.TextSize = 14

Text_4.Text = "honk"

Text_4.TextColor3 = Color3.new(1, 1, 1)

Text_4.TextXAlignment = Enum.TextXAlignment.Left

Text_4.ZIndex = 10

table.insert(shade2,Text_4)

table.insert(text1,Text_4)

Delete_4.Name = "Delete"

Delete_4.Parent = Text_4

Delete_4.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Delete_4.BorderSizePixel = 0

Delete_4.Position = UDim2.new(0, 200, 0, 0)

Delete_4.Size = UDim2.new(0, 40, 0, 20)

Delete_4.Font = Enum.Font.SourceSans

Delete_4.TextSize = 14

Delete_4.Text = "Delete"

Delete_4.TextColor3 = Color3.new(0, 0, 0)

Delete_4.ZIndex = 10

table.insert(shade3,Delete_4)

table.insert(text2,Delete_4)

PluginsFrame.Name = "PluginsFrame"

PluginsFrame.Parent = Settings

PluginsFrame.Active = true

PluginsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

PluginsFrame.BorderSizePixel = 0

PluginsFrame.Position = UDim2.new(0, 0, 0, 175)

PluginsFrame.Size = UDim2.new(0, 250, 0, 175)

PluginsFrame.ZIndex = 10

table.insert(shade1,PluginsFrame)

Close_4.Name = "Close"

Close_4.Parent = PluginsFrame

Close_4.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Close_4.BorderSizePixel = 0

Close_4.Position = UDim2.new(0, 205, 0, 150)

Close_4.Size = UDim2.new(0, 40, 0, 20)

Close_4.Font = Enum.Font.SourceSans

Close_4.TextSize = 14

Close_4.Text = "Close"

Close_4.TextColor3 = Color3.new(1, 1, 1)

Close_4.ZIndex = 10

table.insert(shade2,Close_4)

table.insert(text1,Close_4)

Add_3.Name = "Add"

Add_3.Parent = PluginsFrame

Add_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Add_3.BorderSizePixel = 0

Add_3.Position = UDim2.new(0, 5, 0, 150)

Add_3.Size = UDim2.new(0, 40, 0, 20)

Add_3.Font = Enum.Font.SourceSans

Add_3.TextSize = 14

Add_3.Text = "Add"

Add_3.TextColor3 = Color3.new(1, 1, 1)

Add_3.ZIndex = 10

table.insert(shade2,Add_3)

table.insert(text1,Add_3)

Holder_5.Name = "Holder"

Holder_5.Parent = PluginsFrame

Holder_5.BackgroundTransparency = 1

Holder_5.BorderSizePixel = 0

Holder_5.Position = UDim2.new(0, 0, 0, 0)

Holder_5.Selectable = false

Holder_5.Size = UDim2.new(0, 250, 0, 145)

Holder_5.ScrollBarImageColor3 = Color3.fromRGB(78,78,79)

Holder_5.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_5.CanvasSize = UDim2.new(0, 0, 0, 0)

Holder_5.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_5.ScrollBarThickness = 0
Holder_5.ScrollBarImageTransparency = 1

Holder_5.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

Holder_5.VerticalScrollBarInset = 'Always'

Holder_5.ZIndex = 10

Example_5.Name = "Example"

Example_5.Parent = PluginsFrame

Example_5.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Example_5.BorderSizePixel = 0

Example_5.Size = UDim2.new(0, 10, 0, 20)

Example_5.Visible = false

Example_5.ZIndex = 10

table.insert(shade2,Example_5)

Text_6.Name = "Text"

Text_6.Parent = Example_5

Text_6.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Text_6.BorderSizePixel = 0

Text_6.Position = UDim2.new(0, 10, 0, 0)

Text_6.Size = UDim2.new(0, 240, 0, 20)

Text_6.Font = Enum.Font.SourceSans

Text_6.TextSize = 14

Text_6.Text = "F4 > Toggle Fly"

Text_6.TextColor3 = Color3.new(1, 1, 1)

Text_6.TextXAlignment = Enum.TextXAlignment.Left

Text_6.ZIndex = 10

table.insert(shade2,Text_6)

table.insert(text1,Text_6)

Delete_7.Name = "Delete"

Delete_7.Parent = Text_6

Delete_7.BackgroundColor3 = Color3.fromRGB(78, 78, 79)

Delete_7.BorderSizePixel = 0

Delete_7.Position = UDim2.new(0, 200, 0, 0)

Delete_7.Size = UDim2.new(0, 40, 0, 20)

Delete_7.Font = Enum.Font.SourceSans

Delete_7.TextSize = 14

Delete_7.Text = "Delete"

Delete_7.TextColor3 = Color3.new(0, 0, 0)

Delete_7.ZIndex = 10

table.insert(shade3,Delete_7)

table.insert(text2,Delete_7)

PluginEditor.Name = randomString()

PluginEditor.Parent = ScaledHolder

PluginEditor.BorderSizePixel = 0

PluginEditor.Active = true

PluginEditor.BackgroundTransparency = 1

PluginEditor.Position = UDim2.new(0.5, -180, 0, -500)

PluginEditor.Size = UDim2.new(0, 360, 0, 20)

PluginEditor.ZIndex = 10

background_3.Name = "background"

background_3.Parent = PluginEditor

background_3.Active = true

background_3.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

background_3.BorderSizePixel = 0

background_3.Position = UDim2.new(0, 0, 0, 20)

background_3.Size = UDim2.new(0, 360, 0, 160)

background_3.ZIndex = 10

table.insert(shade1,background_3)

Dark_2.Name = "Dark"

Dark_2.Parent = background_3

Dark_2.Active = true

Dark_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

Dark_2.BorderSizePixel = 0

Dark_2.Position = UDim2.new(0, 222, 0, 0)

Dark_2.Size = UDim2.new(0, 2, 0, 160)

Dark_2.ZIndex = 10

table.insert(shade2,Dark_2)

Img.Name = "Img"

Img.Parent = background_3

Img.BackgroundTransparency = 1

Img.Position = UDim2.new(0, 242, 0, 3)

Img.Size = UDim2.new(0, 100, 0, 95)

Img.Image = getcustomasset("slate/iy/assets/imgstudiopluginlogo.png")

Img.ZIndex = 10

AddPlugin.Name = "AddPlugin"

AddPlugin.Parent = background_3

AddPlugin.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

AddPlugin.BorderSizePixel = 0

AddPlugin.Position = UDim2.new(0, 235, 0, 100)

AddPlugin.Size = UDim2.new(0, 115, 0, 50)

AddPlugin.Font = Enum.Font.SourceSans

AddPlugin.TextSize = 14

AddPlugin.Text = "Add Plugin"

AddPlugin.TextColor3 = Color3.new(1, 1, 1)

AddPlugin.ZIndex = 10

table.insert(shade2,AddPlugin)

table.insert(text1,AddPlugin)

FileName.Name = "FileName"

FileName.Parent = background_3

FileName.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

FileName.BorderSizePixel = 0

FileName.Position = UDim2.new(0.028, 0, 0.625, 0)

FileName.Size = UDim2.new(0, 200, 0, 50)

FileName.Font = Enum.Font.SourceSans

FileName.TextSize = 14

FileName.Text = "Plugin File Name"

FileName.TextColor3 = Color3.new(1, 1, 1)

FileName.ZIndex = 10

table.insert(shade2,FileName)

table.insert(text1,FileName)

About.Name = "About"

About.Parent = background_3

About.BackgroundTransparency = 1

About.BorderSizePixel = 0

About.Position = UDim2.new(0, 17, 0, 10)

About.Size = UDim2.new(0, 187, 0, 49)

About.Font = Enum.Font.SourceSans

About.TextSize = 14

About.Text = "Plugins are .iy files and should be located in the 'workspace' folder of your exploit."

About.TextColor3 = Color3.fromRGB(255, 255, 255)

About.TextWrapped = true

About.TextYAlignment = Enum.TextYAlignment.Top

About.ZIndex = 10

table.insert(text1,About)

Directions_2.Name = "Directions"

Directions_2.Parent = background_3

Directions_2.BackgroundTransparency = 1

Directions_2.BorderSizePixel = 0

Directions_2.Position = UDim2.new(0, 17, 0, 60)

Directions_2.Size = UDim2.new(0, 187, 0, 49)

Directions_2.Font = Enum.Font.SourceSans

Directions_2.TextSize = 14

Directions_2.Text = "Type the name of the plugin file you want to add below."

Directions_2.TextColor3 = Color3.fromRGB(255, 255, 255)

Directions_2.TextWrapped = true

Directions_2.TextYAlignment = Enum.TextYAlignment.Top

Directions_2.ZIndex = 10

table.insert(text1,Directions_2)

shadow_3.Name = "shadow"

shadow_3.Parent = PluginEditor

shadow_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

shadow_3.BorderSizePixel = 0

shadow_3.Size = UDim2.new(0, 360, 0, 20)

shadow_3.ZIndex = 10

table.insert(shade2,shadow_3)

PopupText_3.Name = "PopupText"

PopupText_3.Parent = shadow_3

PopupText_3.BackgroundTransparency = 1

PopupText_3.Size = UDim2.new(1, 0, 0.95, 0)

PopupText_3.ZIndex = 10

PopupText_3.Font = Enum.Font.SourceSans

PopupText_3.TextSize = 14

PopupText_3.Text = "Add Plugins"

PopupText_3.TextColor3 = Color3.new(1, 1, 1)

PopupText_3.TextWrapped = true

table.insert(text1,PopupText_3)

Exit_3.Name = "Exit"

Exit_3.Parent = shadow_3

Exit_3.BackgroundTransparency = 1

Exit_3.Position = UDim2.new(1, -20, 0, 0)

Exit_3.Size = UDim2.new(0, 20, 0, 20)

Exit_3.Text = ""

Exit_3.ZIndex = 10

ExitImage_3.Parent = Exit_3

ExitImage_3.BackgroundColor3 = Color3.new(1, 1, 1)

ExitImage_3.BackgroundTransparency = 1

ExitImage_3.Position = UDim2.new(0, 5, 0, 5)

ExitImage_3.Size = UDim2.new(0, 10, 0, 10)

ExitImage_3.Image = getcustomasset("slate/iy/assets/close.png")

ExitImage_3.ZIndex = 10

AliasHint.Name = "AliasHint"

AliasHint.Parent = AliasesFrame

AliasHint.BackgroundTransparency = 1

AliasHint.BorderSizePixel = 0

AliasHint.Position = UDim2.new(0, 25, 0, 40)

AliasHint.Size = UDim2.new(0, 200, 0, 50)

AliasHint.Font = Enum.Font.SourceSansItalic

AliasHint.TextSize = 16

AliasHint.Text = "Add aliases by using the 'addalias' command"

AliasHint.TextColor3 = Color3.new(1, 1, 1)

AliasHint.TextStrokeColor3 = Color3.new(1, 1, 1)

AliasHint.TextWrapped = true

AliasHint.ZIndex = 10

table.insert(text1,AliasHint)

PluginsHint.Name = "PluginsHint"

PluginsHint.Parent = PluginsFrame

PluginsHint.BackgroundTransparency = 1

PluginsHint.BorderSizePixel = 0

PluginsHint.Position = UDim2.new(0, 25, 0, 40)

PluginsHint.Size = UDim2.new(0, 200, 0, 50)

PluginsHint.Font = Enum.Font.SourceSansItalic

PluginsHint.TextSize = 16

PluginsHint.Text = "Download plugins from the IY Discord (discord.gg/78ZuWSq)"

PluginsHint.TextColor3 = Color3.new(1, 1, 1)

PluginsHint.TextStrokeColor3 = Color3.new(1, 1, 1)

PluginsHint.TextWrapped = true

PluginsHint.ZIndex = 10

table.insert(text1,PluginsHint)

PositionsHint.Name = "PositionsHint"

PositionsHint.Parent = PositionsFrame

PositionsHint.BackgroundTransparency = 1

PositionsHint.BorderSizePixel = 0

PositionsHint.Position = UDim2.new(0, 25, 0, 40)

PositionsHint.Size = UDim2.new(0, 200, 0, 70)

PositionsHint.Font = Enum.Font.SourceSansItalic

PositionsHint.TextSize = 16

PositionsHint.Text = "Use the 'swp' or 'setwaypoint' command to add a position using your character (NOTE: Part teleports will not save)"

PositionsHint.TextColor3 = Color3.new(1, 1, 1)

PositionsHint.TextStrokeColor3 = Color3.new(1, 1, 1)

PositionsHint.TextWrapped = true

PositionsHint.ZIndex = 10

table.insert(text1,PositionsHint)

ToPartFrame.Name = randomString()

ToPartFrame.Parent = ScaledHolder

ToPartFrame.Active = true

ToPartFrame.BackgroundTransparency = 1

ToPartFrame.Position = UDim2.new(0.5, -180, 0, -500)

ToPartFrame.Size = UDim2.new(0, 360, 0, 20)

ToPartFrame.ZIndex = 10

background_4.Name = "background"

background_4.Parent = ToPartFrame

background_4.Active = true

background_4.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

background_4.BorderSizePixel = 0

background_4.Position = UDim2.new(0, 0, 0, 20)

background_4.Size = UDim2.new(0, 360, 0, 117)

background_4.ZIndex = 10

table.insert(shade1,background_4)

ChoosePart.Name = "ChoosePart"

ChoosePart.Parent = background_4

ChoosePart.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

ChoosePart.BorderSizePixel = 0

ChoosePart.Position = UDim2.new(0, 100, 0, 55)

ChoosePart.Size = UDim2.new(0, 75, 0, 30)

ChoosePart.Font = Enum.Font.SourceSans

ChoosePart.TextSize = 14

ChoosePart.Text = "Select Part"

ChoosePart.TextColor3 = Color3.new(1, 1, 1)

ChoosePart.ZIndex = 10

table.insert(shade2,ChoosePart)

table.insert(text1,ChoosePart)

CopyPath.Name = "CopyPath"

CopyPath.Parent = background_4

CopyPath.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

CopyPath.BorderSizePixel = 0

CopyPath.Position = UDim2.new(0, 185, 0, 55)

CopyPath.Size = UDim2.new(0, 75, 0, 30)

CopyPath.Font = Enum.Font.SourceSans

CopyPath.TextSize = 14

CopyPath.Text = "Copy Path"

CopyPath.TextColor3 = Color3.new(1, 1, 1)

CopyPath.ZIndex = 10

table.insert(shade2,CopyPath)

table.insert(text1,CopyPath)

Directions_3.Name = "Directions"

Directions_3.Parent = background_4

Directions_3.BackgroundTransparency = 1

Directions_3.BorderSizePixel = 0

Directions_3.Position = UDim2.new(0, 51, 0, 17)

Directions_3.Size = UDim2.new(0, 257, 0, 32)

Directions_3.Font = Enum.Font.SourceSans

Directions_3.TextSize = 14

Directions_3.Text = 'Click on a part and then click the "Select Part" button below to set it as a teleport location'

Directions_3.TextColor3 = Color3.new(1, 1, 1)

Directions_3.TextWrapped = true

Directions_3.TextYAlignment = Enum.TextYAlignment.Top

Directions_3.ZIndex = 10

table.insert(text1,Directions_3)

Path.Name = "Path"

Path.Parent = background_4

Path.BackgroundTransparency = 1

Path.BorderSizePixel = 0

Path.Position = UDim2.new(0, 0, 0, 94)

Path.Size = UDim2.new(0, 360, 0, 16)

Path.Font = Enum.Font.SourceSansItalic

Path.TextSize = 14

Path.Text = ""

Path.TextColor3 = Color3.new(1, 1, 1)

Path.TextScaled = true

Path.TextWrapped = true

Path.TextYAlignment = Enum.TextYAlignment.Top

Path.ZIndex = 10

table.insert(text1,Path)

shadow_4.Name = "shadow"

shadow_4.Parent = ToPartFrame

shadow_4.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

shadow_4.BorderSizePixel = 0

shadow_4.Size = UDim2.new(0, 360, 0, 20)

shadow_4.ZIndex = 10

table.insert(shade2,shadow_4)

PopupText_5.Name = "PopupText"

PopupText_5.Parent = shadow_4

PopupText_5.BackgroundTransparency = 1

PopupText_5.Size = UDim2.new(1, 0, 0.95, 0)

PopupText_5.ZIndex = 10

PopupText_5.Font = Enum.Font.SourceSans

PopupText_5.TextSize = 14

PopupText_5.Text = "Teleport to Part"

PopupText_5.TextColor3 = Color3.new(1, 1, 1)

PopupText_5.TextWrapped = true

table.insert(text1,PopupText_5)

Exit_4.Name = "Exit"

Exit_4.Parent = shadow_4

Exit_4.BackgroundTransparency = 1

Exit_4.Position = UDim2.new(1, -20, 0, 0)

Exit_4.Size = UDim2.new(0, 20, 0, 20)

Exit_4.Text = ""

Exit_4.ZIndex = 10

ExitImage_5.Parent = Exit_4

ExitImage_5.BackgroundColor3 = Color3.new(1, 1, 1)

ExitImage_5.BackgroundTransparency = 1

ExitImage_5.Position = UDim2.new(0, 5, 0, 5)

ExitImage_5.Size = UDim2.new(0, 10, 0, 10)

ExitImage_5.Image = getcustomasset("slate/iy/assets/close.png")

ExitImage_5.ZIndex = 10

logs.Name = randomString()

logs.Parent = ScaledHolder

logs.Active = true

logs.BackgroundTransparency = 1

logs.Position = UDim2.new(0, 0, 1, 10)

logs.Size = UDim2.new(0, 338, 0, 20)

logs.ZIndex = 10

shadow.Name = "shadow"

shadow.Parent = logs

shadow.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

shadow.BorderSizePixel = 0

shadow.Position = UDim2.new(0, 0, 0.00999999978, 0)

shadow.Size = UDim2.new(0, 338, 0, 20)

shadow.ZIndex = 10

table.insert(shade2,shadow)

Hide.Name = "Hide"

Hide.Parent = shadow

Hide.BackgroundTransparency = 1

Hide.Position = UDim2.new(1, -40, 0, 0)

Hide.Size = UDim2.new(0, 20, 0, 20)

Hide.ZIndex = 10

Hide.Text = ""

ImageLabel.Parent = Hide

ImageLabel.BackgroundColor3 = Color3.new(1, 1, 1)

ImageLabel.BackgroundTransparency = 1

ImageLabel.Position = UDim2.new(0, 3, 0, 3)

ImageLabel.Size = UDim2.new(0, 14, 0, 14)

ImageLabel.Image = getcustomasset("slate/iy/assets/minimize.png")

ImageLabel.ZIndex = 10

PopupText.Name = "PopupText"

PopupText.Parent = shadow

PopupText.BackgroundTransparency = 1

PopupText.Size = UDim2.new(1, 0, 0.949999988, 0)

PopupText.ZIndex = 10

PopupText.Font = Enum.Font.SourceSans

PopupText.FontSize = Enum.FontSize.Size14

PopupText.Text = "Logs"

PopupText.TextColor3 = Color3.new(1, 1, 1)

PopupText.TextWrapped = true

table.insert(text1,PopupText)

Exit.Name = "Exit"

Exit.Parent = shadow

Exit.BackgroundTransparency = 1

Exit.Position = UDim2.new(1, -20, 0, 0)

Exit.Size = UDim2.new(0, 20, 0, 20)

Exit.ZIndex = 10

Exit.Text = ""

ImageLabel_2.Parent = Exit

ImageLabel_2.BackgroundColor3 = Color3.new(1, 1, 1)

ImageLabel_2.BackgroundTransparency = 1

ImageLabel_2.Position = UDim2.new(0, 5, 0, 5)

ImageLabel_2.Size = UDim2.new(0, 10, 0, 10)

ImageLabel_2.Image = getcustomasset("slate/iy/assets/close.png")

ImageLabel_2.ZIndex = 10

background.Name = "background"

background.Parent = logs

background.Active = true

background.BackgroundColor3 = Color3.new(0.141176, 0.141176, 0.145098)

background.BorderSizePixel = 0

background.ClipsDescendants = true

background.Position = UDim2.new(0, 0, 1, 0)

background.Size = UDim2.new(0, 338, 0, 245)

background.ZIndex = 10

chat.Name = "chat"

chat.Parent = background

chat.Active = true

chat.BackgroundColor3 = Color3.new(0.141176, 0.141176, 0.145098)

chat.BorderSizePixel = 0

chat.ClipsDescendants = true

chat.Size = UDim2.new(0, 338, 0, 245)

chat.ZIndex = 10

table.insert(shade1,chat)

Clear.Name = "Clear"

Clear.Parent = chat

Clear.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

Clear.BorderSizePixel = 0

Clear.Position = UDim2.new(0, 5, 0, 220)

Clear.Size = UDim2.new(0, 50, 0, 20)

Clear.ZIndex = 10

Clear.Font = Enum.Font.SourceSans

Clear.FontSize = Enum.FontSize.Size14

Clear.Text = "Clear"

Clear.TextColor3 = Color3.new(1, 1, 1)

table.insert(shade2,Clear)

table.insert(text1,Clear)

SaveChatlogs.Name = "SaveChatlogs"

SaveChatlogs.Parent = chat

SaveChatlogs.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

SaveChatlogs.BorderSizePixel = 0

SaveChatlogs.Position = UDim2.new(0, 258, 0, 220)

SaveChatlogs.Size = UDim2.new(0, 75, 0, 20)

SaveChatlogs.ZIndex = 10

SaveChatlogs.Font = Enum.Font.SourceSans

SaveChatlogs.FontSize = Enum.FontSize.Size14

SaveChatlogs.Text = "Save To .txt"

SaveChatlogs.TextColor3 = Color3.new(1, 1, 1)

table.insert(shade2,SaveChatlogs)

table.insert(text1,SaveChatlogs)

Toggle.Name = "Toggle"

Toggle.Parent = chat

Toggle.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

Toggle.BorderSizePixel = 0

Toggle.Position = UDim2.new(0, 60, 0, 220)

Toggle.Size = UDim2.new(0, 66, 0, 20)

Toggle.ZIndex = 10

Toggle.Font = Enum.Font.SourceSans

Toggle.FontSize = Enum.FontSize.Size14

Toggle.Text = "Disabled"

Toggle.TextColor3 = Color3.new(1, 1, 1)

table.insert(shade2,Toggle)

table.insert(text1,Toggle)

scroll_2.Name = "scroll"

scroll_2.Parent = chat

scroll_2.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

scroll_2.BorderSizePixel = 0

scroll_2.Position = UDim2.new(0, 5, 0, 25)

scroll_2.Size = UDim2.new(0, 328, 0, 190)

scroll_2.ZIndex = 10

scroll_2.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

scroll_2.CanvasSize = UDim2.new(0, 0, 0, 10)

scroll_2.ScrollBarThickness = 8
scroll_2.ScrollBarImageTransparency = 1

scroll_2.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

table.insert(scroll,scroll_2)

table.insert(shade2,scroll_2)

join.Name = "join"

join.Parent = background

join.Active = true

join.BackgroundColor3 = Color3.new(0.141176, 0.141176, 0.145098)

join.BorderSizePixel = 0

join.ClipsDescendants = true

join.Size = UDim2.new(0, 338, 0, 245)

join.Visible = false

join.ZIndex = 10

table.insert(shade1,join)

Toggle_2.Name = "Toggle"

Toggle_2.Parent = join

Toggle_2.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

Toggle_2.BorderSizePixel = 0

Toggle_2.Position = UDim2.new(0, 60, 0, 220)

Toggle_2.Size = UDim2.new(0, 66, 0, 20)

Toggle_2.ZIndex = 10

Toggle_2.Font = Enum.Font.SourceSans

Toggle_2.FontSize = Enum.FontSize.Size14

Toggle_2.Text = "Disabled"

Toggle_2.TextColor3 = Color3.new(1, 1, 1)

table.insert(shade2,Toggle_2)

table.insert(text1,Toggle_2)

Clear_2.Name = "Clear"

Clear_2.Parent = join

Clear_2.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

Clear_2.BorderSizePixel = 0

Clear_2.Position = UDim2.new(0, 5, 0, 220)

Clear_2.Size = UDim2.new(0, 50, 0, 20)

Clear_2.ZIndex = 10

Clear_2.Font = Enum.Font.SourceSans

Clear_2.FontSize = Enum.FontSize.Size14

Clear_2.Text = "Clear"

Clear_2.TextColor3 = Color3.new(1, 1, 1)

table.insert(shade2,Clear_2)

table.insert(text1,Clear_2)

scroll_3.Name = "scroll"

scroll_3.Parent = join

scroll_3.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

scroll_3.BorderSizePixel = 0

scroll_3.Position = UDim2.new(0, 5, 0, 25)

scroll_3.Size = UDim2.new(0, 328, 0, 190)

scroll_3.ZIndex = 10

scroll_3.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

scroll_3.CanvasSize = UDim2.new(0, 0, 0, 10)

scroll_3.ScrollBarThickness = 8
scroll_3.ScrollBarImageTransparency = 1

scroll_3.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

table.insert(scroll,scroll_3)

table.insert(shade2,scroll_3)

selectChat.Name = "selectChat"

selectChat.Parent = background

selectChat.BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.184314)

selectChat.BorderSizePixel = 0

selectChat.Position = UDim2.new(0, 5, 0, 5)

selectChat.Size = UDim2.new(0, 164, 0, 20)

selectChat.ZIndex = 10

selectChat.Font = Enum.Font.SourceSans

selectChat.FontSize = Enum.FontSize.Size14

selectChat.Text = "Chat Logs"

selectChat.TextColor3 = Color3.new(1, 1, 1)

table.insert(shade2,selectChat)

table.insert(text1,selectChat)

selectJoin.Name = "selectJoin"

selectJoin.Parent = background

selectJoin.BackgroundColor3 = Color3.new(0.305882, 0.305882, 0.309804)

selectJoin.BorderSizePixel = 0

selectJoin.Position = UDim2.new(0, 169, 0, 5)

selectJoin.Size = UDim2.new(0, 164, 0, 20)

selectJoin.ZIndex = 10

selectJoin.Font = Enum.Font.SourceSans

selectJoin.FontSize = Enum.FontSize.Size14

selectJoin.Text = "Join Logs"

selectJoin.TextColor3 = Color3.new(1, 1, 1)

table.insert(shade3,selectJoin)

table.insert(text1,selectJoin)

function create(data)

	local insts = {}

	for i,v in pairs(data) do insts[v[1]] = Instance.new(v[2]) end
	for _,v in pairs(data) do
		for prop,val in pairs(v[3]) do
			if type(val) == "table" then
				insts[v[1]][prop] = insts[val[1]]
			else
				insts[v[1]][prop] = val
			end
		end
	end
	return insts[1]
end
ViewportTextBox = (function()
	local funcs = {}
	funcs.Update = function(self)
		local cursorPos = self.TextBox.CursorPosition
		local text = self.TextBox.Text
		if text == "" then self.TextBox.Position = UDim2.new(0,2,0,0) return end
		if cursorPos == -1 then return end
		local cursorText = text:sub(1,cursorPos-1)
		local pos = nil
		local leftEnd = -self.TextBox.Position.X.Offset
		local rightEnd = leftEnd + self.View.AbsoluteSize.X
		local totalTextSize = TextService:GetTextSize(text,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X
		local cursorTextSize = TextService:GetTextSize(cursorText,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X
		if cursorTextSize > rightEnd then
			pos = math.max(-2,cursorTextSize - self.View.AbsoluteSize.X + 2)
		elseif cursorTextSize < leftEnd then
			pos = math.max(-2,cursorTextSize-2)
		elseif totalTextSize < rightEnd then
			pos = math.max(-2,totalTextSize - self.View.AbsoluteSize.X + 2)
		end
		if pos then
			self.TextBox.Position = UDim2.new(0,-pos,0,0)
			self.TextBox.Size = UDim2.new(1,pos,1,0)
		end
	end
	local mt = {}
	mt.__index = funcs
	local function convert(textbox)
		local obj = setmetatable({OffsetX = 0, TextBox = textbox},mt)
		local view = Instance.new("Frame")
		view.BackgroundTransparency = textbox.BackgroundTransparency
		view.BackgroundColor3 = textbox.BackgroundColor3
		view.BorderSizePixel = textbox.BorderSizePixel
		view.BorderColor3 = textbox.BorderColor3
		view.Position = textbox.Position
		view.Size = textbox.Size
		view.ClipsDescendants = true
		view.Name = textbox.Name
		view.ZIndex = 10
		textbox.BackgroundTransparency = 1
		textbox.Position = UDim2.new(0,4,0,0)
		textbox.Size = UDim2.new(1,-8,1,0)
		textbox.TextXAlignment = Enum.TextXAlignment.Left
		textbox.Name = "Input"
		table.insert(text1,textbox)
		table.insert(shade2,view)
		obj.View = view
		textbox.Changed:Connect(function(prop)
			if prop == "Text" or prop == "CursorPosition" or prop == "AbsoluteSize" then
				obj:Update()
			end
		end)
		obj:Update()
		view.Parent = textbox.Parent
		textbox.Parent = view
		return obj
	end
	return {convert = convert}
end)()
ViewportTextBox.convert(Cmdbar).View.ZIndex = 10
ViewportTextBox.convert(Cmdbar_2).View.ZIndex = 10
ViewportTextBox.convert(Cmdbar_3).View.ZIndex = 10
function writefileExploit()
	if writefile then
		return true
	end
end
function readfileExploit()
	if readfile then
		return true
	end
end
function isNumber(str)
	if tonumber(str) ~= nil or str == "inf" then
		return true
	end
end
function vtype(o, t)
	if o == nil then return false end
	if type(o) == "userdata" then return typeof(o) == t end
	return type(o) == t
end
function getRoot(char)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char:FindFirstChildOfClass("Humanoid").RootPart
	else
		return nil
	end
end
function tools(plr)
	if plr:FindFirstChildOfClass("Backpack"):FindFirstChildOfClass("Tool") or plr.Character:FindFirstChildOfClass("Tool") then
		return true
	end
end
function r15(plr)
	if plr.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15 then
		return true
	end
end
function breakVelocity()
    local V3 = Vector3.new(0, 0, 0)
    for _, v in ipairs(Players.LocalPlayer.Character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.AssemblyLinearVelocity, v.AssemblyAngularVelocity = V3, V3
        end
    end
end
function toClipboard(txt)
	if everyClipboard then
		everyClipboard(tostring(txt))
		notify("Clipboard", "Copied to clipboard")
	else
		notify("Clipboard", "Your exploit doesn't have the ability to use the clipboard")
	end
end
function chatMessage(str)
	str = tostring(str)
	if isLegacyChat then
		local chatRemote = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
		if chatRemote then chatRemote:FireServer(str, "All") end
		return
	end
	local chat = TextChatService.ChatInputBarConfiguration.TargetTextChannel
	local textChannels = TextChatService:FindFirstChild("TextChannels")
	local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")
	pcall(function()
		(generalChannel and generalChannel or chat):SendAsync(str)
	end)
end
function getHierarchy(obj)
	local fullname
	local period
	if string.find(obj.Name,' ') then
		fullname = '["'..obj.Name..'"]'
		period = false
	else
		fullname = obj.Name
		period = true
	end
	local getS = obj
	local parent = obj
	local service = ''
	if getS.Parent ~= game then
		repeat
			getS = getS.Parent
			service = getS.ClassName
		until getS.Parent == game
	end
	if parent.Parent ~= getS then
		repeat
			parent = parent.Parent
			if string.find(tostring(parent),' ') then
				if period then
					fullname = '["'..parent.Name..'"].'..fullname
				else
					fullname = '["'..parent.Name..'"]'..fullname
				end
				period = false
			else
				if period then
					fullname = parent.Name..'.'..fullname
				else
					fullname = parent.Name..''..fullname
				end
				period = true
			end
		until parent.Parent == getS
	elseif string.find(tostring(parent),' ') then
		fullname = '["'..parent.Name..'"]'
		period = false
	end
	if period then
		return 'game:GetService("'..service..'").'..fullname
	else
		return 'game:GetService("'..service..'")'..fullname
	end
end
AllWaypoints = {}
local cooldown = false
function writefileCooldown(name,data)
	task.spawn(function()
		if not cooldown then
			cooldown = true
			writefile(name, data, true)
		else
			repeat wait() until cooldown == false
			writefileCooldown(name,data)
		end
		wait(3)
		cooldown = false
	end)
end
function dragGUI(gui)
	task.spawn(function()
		local dragging
		local dragInput
		local dragStart = Vector3.new(0,0,0)
		local startPos
		local function update(input)
			local delta = input.Position - dragStart
			local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
		end
		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		gui.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end)
end
dragGUI(logs)
dragGUI(KeybindEditor)
dragGUI(PluginEditor)
dragGUI(ToPartFrame)
eventEditor = (function()
	local events = {}
	local function registerEvent(name,sets)
		events[name] = {
			commands = {},
			sets = sets or {}
		}
	end
	local onEdited = nil
	local function fireEvent(name,...)
		local args = {...}
		local event = events[name]
		if event then
			for i,cmd in pairs(event.commands) do
				local metCondition = true
				for idx,set in pairs(event.sets) do
					local argVal = args[idx]
					local cmdSet = cmd[2][idx]
					local condType = set.Type
					if condType == "Player" then
						if cmdSet == 0 then
							metCondition = metCondition and (tostring(Players.LocalPlayer) == argVal)
						elseif cmdSet ~= 1 then
							metCondition = metCondition and table.find(getPlayer(cmdSet,Players.LocalPlayer),argVal)
						end
					elseif condType == "String" then
						if cmdSet ~= 0 then
							metCondition = metCondition and string.find(argVal:lower(),cmdSet:lower())
						end
					elseif condType == "Number" then
						if cmdSet ~= 0 then
							metCondition = metCondition and tonumber(argVal)<=tonumber(cmdSet)
						end
					end
					if not metCondition then break end
				end
				if metCondition then
					pcall(task.spawn(function()
						local cmdStr = cmd[1]
						for count,arg in pairs(args) do
							cmdStr = cmdStr:gsub("%$"..count,arg)
						end
						wait(cmd[3] or 0)
						execCmd(cmdStr)
					end))
				end
			end
		end
	end
	local main = create({
		{1,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderSizePixel=0,Name="EventEditor",Position=UDim2.new(0.5,-175,0,-500),Size=UDim2.new(0,350,0,20),ZIndex=10,}},
		{2,"Frame",{BackgroundColor3=currentShade2,BorderSizePixel=0,Name="TopBar",Parent={1},Size=UDim2.new(1,0,0,20),ZIndex=10,}},
		{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,0.95,0),Text="Event Editor",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=10,}},
		{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Close",Parent={2},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=getcustomasset("slate/iy/assets/close.png"),Parent={4},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,10,0,10),ZIndex=10,}},
		{6,"Frame",{BackgroundColor3=currentShade1,BorderSizePixel=0,Name="Content",Parent={1},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,0,202),ZIndex=10,}},
		{7,"ScrollingFrame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",CanvasSize=UDim2.new(0,0,0,100),Name="List",Parent={6},Position=UDim2.new(0,5,0,5),ScrollBarImageColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),ScrollBarThickness=8,Size=UDim2.new(1,-10,1,-10),TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",ZIndex=10,}},
		{8,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Holder",Parent={7},Size=UDim2.new(1,0,1,0),ZIndex=10,}},
		{9,"UIListLayout",{Parent={8},SortOrder=2,}},
		{10,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BorderSizePixel=0,ClipsDescendants=true,Name="Settings",Parent={6},Position=UDim2.new(1,0,0,0),Size=UDim2.new(0,150,1,0),ZIndex=10,}},
		{11,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),Name="Slider",Parent={10},Position=UDim2.new(0,-150,0,0),Size=UDim2.new(1,0,1,0),ZIndex=10,}},
		{12,"Frame",{BackgroundColor3=Color3.new(0.23529413342476,0.23529413342476,0.23529413342476),BorderColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BorderSizePixel=0,Name="Line",Parent={11},Size=UDim2.new(0,1,1,0),ZIndex=10,}},
		{13,"ScrollingFrame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",CanvasSize=UDim2.new(0,0,0,100),Name="List",Parent={11},Position=UDim2.new(0,0,0,25),ScrollBarImageColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),ScrollBarThickness=8,Size=UDim2.new(1,0,1,-25),TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",ZIndex=10,}},
		{14,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Holder",Parent={13},Size=UDim2.new(1,0,1,0),ZIndex=10,}},
		{15,"UIListLayout",{Parent={14},SortOrder=2,}},
		{16,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={11},Size=UDim2.new(1,0,0,20),Text="Event Settings",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{17,"TextButton",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Font=3,Name="Close",BorderSizePixel=0,Parent={11},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="<",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{18,"Folder",{Name="Templates",Parent={10},}},
		{19,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="Players",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,86),Visible=false,ZIndex=10,}},
		{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={19},Size=UDim2.new(1,0,0,20),Text="Choose Players",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{21,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Any",Parent={19},Position=UDim2.new(0,5,0,42),Size=UDim2.new(1,-10,0,20),Text="Any Player",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{22,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={21},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{23,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={22},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{24,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Me",Parent={19},Position=UDim2.new(0,5,0,20),Size=UDim2.new(1,-10,0,20),Text="Me Only",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{25,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={24},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{26,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={25},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{27,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Name="Custom",Parent={19},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),PlaceholderText="Custom Player Set",Position=UDim2.new(0,5,0,64),Size=UDim2.new(1,-35,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{28,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="CustomButton",Parent={19},Position=UDim2.new(1,-25,0,64),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{29,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={28},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{30,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="Strings",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,64),Visible=false,ZIndex=10,}},
		{31,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={30},Size=UDim2.new(1,0,0,20),Text="Choose String",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{32,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Any",Parent={30},Position=UDim2.new(0,5,0,20),Size=UDim2.new(1,-10,0,20),Text="Any String",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{33,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={32},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{34,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={33},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{54,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="Numbers",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,64),Visible=false,ZIndex=10,}},
		{55,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={54},Size=UDim2.new(1,0,0,20),Text="Choose String",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{56,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Any",Parent={54},Position=UDim2.new(0,5,0,20),Size=UDim2.new(1,-10,0,20),Text="Any Number",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{57,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="Button",Parent={56},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{58,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={57},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{59,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Name="Custom",Parent={54},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),PlaceholderText="Number",Position=UDim2.new(0,5,0,42),Size=UDim2.new(1,-35,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{60,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="CustomButton",Parent={54},Position=UDim2.new(1,-25,0,42),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{61,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={60},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{35,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Name="Custom",Parent={30},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),PlaceholderText="Match String",Position=UDim2.new(0,5,0,42),Size=UDim2.new(1,-35,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{36,"Frame",{BackgroundColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),BorderSizePixel=0,Name="CustomButton",Parent={30},Position=UDim2.new(1,-25,0,42),Size=UDim2.new(0,20,0,20),ZIndex=10,}},
		{37,"TextButton",{BackgroundColor3=Color3.new(0.58823531866074,0.58823531866074,0.59215688705444),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="On",Parent={36},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,ZIndex=10,}},
		{38,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),Name="DelayEditor",Parent={18},Position=UDim2.new(0,0,0,25),Size=UDim2.new(1,0,0,24),Visible=false,ZIndex=10,}},
		{39,"TextBox",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Font=3,Name="Secs",Parent={38},PlaceholderColor3=Color3.new(0.47058826684952,0.47058826684952,0.47058826684952),Position=UDim2.new(0,60,0,2),Size=UDim2.new(1,-65,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{40,"TextLabel",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Label",Parent={39},Position=UDim2.new(0,-55,0,0),Size=UDim2.new(1,0,1,0),Text="Delay (s):",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{41,"Frame",{BackgroundColor3=currentShade1,BorderSizePixel=0,ClipsDescendants=true,Name="EventTemplate",Parent={6},Size=UDim2.new(1,0,0,20),Visible=false,ZIndex=10,}},
		{42,"TextButton",{BackgroundColor3=currentText1,BackgroundTransparency=1,Font=3,Name="Expand",Parent={41},Size=UDim2.new(0,20,0,20),Text=">",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{43,"TextLabel",{BackgroundColor3=currentText1,BackgroundTransparency=1,Font=3,Name="EventName",Parent={41},Position=UDim2.new(0,25,0,0),Size=UDim2.new(1,-25,0,20),Text="OnSpawn",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{44,"Frame",{BackgroundColor3=Color3.new(0.19607844948769,0.19607844948769,0.19607844948769),BorderSizePixel=0,BackgroundTransparency=1,ClipsDescendants=true,Name="Cmds",Parent={41},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),ZIndex=10,}},
		{45,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BorderColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),Name="Add",Parent={44},Position=UDim2.new(0,0,1,-20),Size=UDim2.new(1,0,0,20),ZIndex=10,}},
		{46,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Parent={45},PlaceholderColor3=Color3.new(0.7843137383461,0.7843137383461,0.7843137383461),PlaceholderText="Add new command",Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-10,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{47,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Holder",Parent={44},Size=UDim2.new(1,0,1,-20),ZIndex=10,}},
		{48,"UIListLayout",{Parent={47},SortOrder=2,}},
		{49,"Frame",{currentShade1,BorderSizePixel=0,ClipsDescendants=true,Name="CmdTemplate",Parent={6},Size=UDim2.new(1,0,0,20),Visible=false,ZIndex=10,}},
		{50,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Parent={49},PlaceholderColor3=Color3.new(1,1,1),Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-45,0,20),Text="a\\b\\c\\d",TextColor3=currentText1,TextSize=14,TextXAlignment=0,ZIndex=10,}},
		{51,"TextButton",{BackgroundColor3=currentShade1,BorderSizePixel=0,Font=3,Name="Delete",Parent={49},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="X",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{52,"TextButton",{BackgroundColor3=currentShade1,BorderSizePixel=0,Font=3,Name="Settings",Parent={49},Position=UDim2.new(1,-40,0,0),Size=UDim2.new(0,20,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=18,ZIndex=10,}},
		{53,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=getcustomasset("slate/iy/assets/settings.png"),Parent={52},Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,16,0,16),ZIndex=10,}},
	})
	main.Name = randomString()
	local mainFrame = main:WaitForChild("Content")
	local eventList = mainFrame:WaitForChild("List")
	local eventListHolder = eventList:WaitForChild("Holder")
	local cmdTemplate = mainFrame:WaitForChild("CmdTemplate")
	local eventTemplate = mainFrame:WaitForChild("EventTemplate")
	local settingsFrame = mainFrame:WaitForChild("Settings"):WaitForChild("Slider")
	local settingsTemplates = mainFrame.Settings:WaitForChild("Templates")
	local settingsList = settingsFrame:WaitForChild("List"):WaitForChild("Holder")
	table.insert(shade2,main.TopBar) table.insert(shade1,mainFrame) table.insert(shade2,eventTemplate)
	table.insert(text1,eventTemplate.EventName) table.insert(shade1,eventTemplate.Cmds.Add) table.insert(shade1,cmdTemplate)
	table.insert(text1,cmdTemplate.TextBox) table.insert(shade2,cmdTemplate.Delete) table.insert(shade2,cmdTemplate.Settings)
	table.insert(scroll,mainFrame.List) table.insert(shade1,settingsFrame) table.insert(shade2,settingsFrame.Line)
	table.insert(shade2,settingsFrame.Close) table.insert(scroll,settingsFrame.List) table.insert(shade2,settingsTemplates.DelayEditor.Secs)
	table.insert(text1,settingsTemplates.DelayEditor.Secs) table.insert(text1,settingsTemplates.DelayEditor.Secs.Label) table.insert(text1,settingsTemplates.Players.Title)
	table.insert(shade3,settingsTemplates.Players.CustomButton) table.insert(shade2,settingsTemplates.Players.Custom) table.insert(text1,settingsTemplates.Players.Custom)
	table.insert(shade3,settingsTemplates.Players.Any.Button) table.insert(shade3,settingsTemplates.Players.Me.Button) table.insert(text1,settingsTemplates.Players.Any)
	table.insert(text1,settingsTemplates.Players.Me) table.insert(text1,settingsTemplates.Strings.Title) table.insert(text1,settingsTemplates.Strings.Any)
	table.insert(shade3,settingsTemplates.Strings.Any.Button) table.insert(shade3,settingsTemplates.Strings.CustomButton) table.insert(text1,settingsTemplates.Strings.Custom)
	table.insert(shade2,settingsTemplates.Strings.Custom)
	table.insert(text1,settingsTemplates.Players.Me) table.insert(text1,settingsTemplates.Numbers.Title) table.insert(text1,settingsTemplates.Numbers.Any)
	table.insert(shade3,settingsTemplates.Numbers.Any.Button) table.insert(shade3,settingsTemplates.Numbers.CustomButton) table.insert(text1,settingsTemplates.Numbers.Custom)
	table.insert(shade2,settingsTemplates.Numbers.Custom)
	local tweenInf = TweenInfo.new(0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
	local currentlyEditingCmd = nil
	settingsFrame:WaitForChild("Close").MouseButton1Click:Connect(function()
		settingsFrame:TweenPosition(UDim2.new(0,-150,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
	end)
	local function resizeList()
		local size = 0
		for i,v in pairs(eventListHolder:GetChildren()) do
			if v.Name == "EventTemplate" then
				size = size + 20
				if v.Expand.Rotation == 90 then
					size = size + 20*(1+(#events[v.EventName:GetAttribute("RawName")].commands or 0))
				end
			end
		end
		TweenService:Create(eventList,tweenInf,{CanvasSize = UDim2.new(0,0,0,size)}):Play()
		if size > eventList.AbsoluteSize.Y then
			eventListHolder.Size = UDim2.new(1,-8,1,0)
		else
			eventListHolder.Size = UDim2.new(1,0,1,0)
		end
	end
	local function resizeSettingsList()
		local size = 0
		for i,v in pairs(settingsList:GetChildren()) do
			if v:IsA("Frame") then
				size = size + v.AbsoluteSize.Y
			end
		end
		settingsList.Parent.CanvasSize = UDim2.new(0,0,0,size)
		if size > settingsList.Parent.AbsoluteSize.Y then
			settingsList.Size = UDim2.new(1,-8,1,0)
		else
			settingsList.Size = UDim2.new(1,0,1,0)
		end
	end
	local function setupCheckbox(button,callback)
		local enabled = button.On.BackgroundTransparency == 0
		local function update()
			button.On.BackgroundTransparency = (enabled and 0 or 1)
		end
		button.On.MouseButton1Click:Connect(function()
			enabled = not enabled
			update()
			if callback then callback(enabled) end
		end)
		return {
			Toggle = function(nocall) enabled = not enabled update() if not nocall and callback then callback(enabled) end end,
			Enable = function(nocall) if enabled then return end enabled = true update()if not nocall and callback then callback(enabled) end end,
			Disable = function(nocall) if not enabled then return end enabled = false update()if not nocall and callback then callback(enabled) end end,
			IsEnabled = function() return enabled end
		}
	end
	local function openSettingsEditor(event,cmd)
		currentlyEditingCmd = cmd
		for i,v in pairs(settingsList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
		local delayEditor = settingsTemplates.DelayEditor:Clone()
		delayEditor.Secs.FocusLost:Connect(function()
			cmd[3] = tonumber(delayEditor.Secs.Text) or 0
			delayEditor.Secs.Text = cmd[3]
			if onEdited then onEdited() end
		end)
		delayEditor.Secs.Text = cmd[3]
		delayEditor.Visible = true
		table.insert(shade2,delayEditor.Secs)
		table.insert(text1,delayEditor.Secs)
		table.insert(text1,delayEditor.Secs.Label)
		delayEditor.Parent = settingsList
		for i,v in pairs(event.sets) do
			if v.Type == "Player" then
				local template = settingsTemplates.Players:Clone()
				template.Title.Text = v.Name or "Player"
				local me,any,custom
				me = setupCheckbox(template.Me.Button,function(on)
					if not on then return end
					any.Disable()
					custom.Disable()
					cmd[2][i] = 0
					if onEdited then onEdited() end
				end)
				any = setupCheckbox(template.Any.Button,function(on)
					if not on then return end
					me.Disable()
					custom.Disable()
					cmd[2][i] = 1
					if onEdited then onEdited() end
				end)
				local customTextBox = template.Custom
				custom = setupCheckbox(template.CustomButton,function(on)
					if not on then return end
					me.Disable()
					any.Disable()
					cmd[2][i] = customTextBox.Text
					if onEdited then onEdited() end
				end)
				ViewportTextBox.convert(customTextBox)
				customTextBox.FocusLost:Connect(function()
					if custom:IsEnabled() then
						cmd[2][i] = customTextBox.Text
						if onEdited then onEdited() end
					end
				end)
				local cVal = cmd[2][i]
				if cVal == 0 then
					me:Enable()
				elseif cVal == 1 then
					any:Enable()
				else
					custom:Enable()
					customTextBox.Text = cVal
				end
				template.Visible = true
				table.insert(text1,template.Title)
				table.insert(shade3,template.CustomButton)
				table.insert(shade3,template.Any.Button)
				table.insert(shade3,template.Me.Button)
				table.insert(text1,template.Any)
				table.insert(text1,template.Me)
				template.Parent = settingsList
			elseif v.Type == "String" then
				local template = settingsTemplates.Strings:Clone()
				template.Title.Text = v.Name or "String"
				local any,custom
				any = setupCheckbox(template.Any.Button,function(on)
					if not on then return end
					custom.Disable()
					cmd[2][i] = 0
					if onEdited then onEdited() end
				end)
				local customTextBox = template.Custom
				custom = setupCheckbox(template.CustomButton,function(on)
					if not on then return end
					any.Disable()
					cmd[2][i] = customTextBox.Text
					if onEdited then onEdited() end
				end)
				ViewportTextBox.convert(customTextBox)
				customTextBox.FocusLost:Connect(function()
					if custom:IsEnabled() then
						cmd[2][i] = customTextBox.Text
						if onEdited then onEdited() end
					end
				end)
				local cVal = cmd[2][i]
				if cVal == 0 then
					any:Enable()
				else
					custom:Enable()
					customTextBox.Text = cVal
				end
				template.Visible = true
				table.insert(text1,template.Title)
				table.insert(text1,template.Any)
				table.insert(shade3,template.Any.Button)
				table.insert(shade3,template.CustomButton)
				template.Parent = settingsList
			elseif v.Type == "Number" then
				local template = settingsTemplates.Numbers:Clone()
				template.Title.Text = v.Name or "Number"
				local any,custom
				any = setupCheckbox(template.Any.Button,function(on)
					if not on then return end
					custom.Disable()
					cmd[2][i] = 0
					if onEdited then onEdited() end
				end)
				local customTextBox = template.Custom
				custom = setupCheckbox(template.CustomButton,function(on)
					if not on then return end
					any.Disable()
					cmd[2][i] = customTextBox.Text
					if onEdited then onEdited() end
				end)
				ViewportTextBox.convert(customTextBox)
				customTextBox.FocusLost:Connect(function()
					cmd[2][i] = tonumber(customTextBox.Text) or 0
					customTextBox.Text = cmd[2][i]
					if custom:IsEnabled() then
						if onEdited then onEdited() end
					end
				end)
				local cVal = cmd[2][i]
				if cVal == 0 then
					any:Enable()
				else
					custom:Enable()
					customTextBox.Text = cVal
				end
				template.Visible = true
				table.insert(text1,template.Title)
				table.insert(text1,template.Any)
				table.insert(shade3,template.Any.Button)
				table.insert(shade3,template.CustomButton)
				template.Parent = settingsList
			end
		end
		resizeSettingsList()
		settingsFrame:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
	end
	local function defaultSettings(ev)
		local res = {}
		for i,v in pairs(ev.sets) do
			if v.Type == "Player" then
				res[#res+1] = v.Default or 0
			elseif v.Type == "String" then
				res[#res+1] = v.Default or 0
			elseif v.Type == "Number" then
				res[#res+1] = v.Default or 0
			end
		end
		return res
	end
	local function refreshList()
		for i,v in pairs(eventListHolder:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
		for name,event in pairs(events) do
			local eventF = eventTemplate:Clone()
			eventF.EventName.Text = name
			eventF.Visible = true
			eventF.EventName:SetAttribute("RawName", name)
			table.insert(shade2,eventF)
			table.insert(text1,eventF.EventName)
			table.insert(shade1,eventF.Cmds.Add)
			local expanded = false
			eventF.Expand.MouseButton1Down:Connect(function()
				expanded = not expanded
				eventF:TweenSize(UDim2.new(1,0,0,20 + (expanded and 20*#eventF.Cmds.Holder:GetChildren() or 0)),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
				eventF.Expand.Rotation = expanded and 90 or 0
				resizeList()
			end)
			local function refreshCommands()
				for i,v in pairs(eventF.Cmds.Holder:GetChildren()) do
					if v.Name == "CmdTemplate" then
						v:Destroy()
					end
				end
				eventF.EventName.Text = name..(#event.commands > 0 and " ("..#event.commands..")" or "")
				for i,cmd in pairs(event.commands) do
					local cmdF = cmdTemplate:Clone()
					local cmdTextBox = cmdF.TextBox
					ViewportTextBox.convert(cmdTextBox)
					cmdTextBox.Text = cmd[1]
					cmdF.Visible = true
					table.insert(shade1,cmdF)
					table.insert(shade2,cmdF.Delete)
					table.insert(shade2,cmdF.Settings)
					cmdTextBox.FocusLost:Connect(function()
						event.commands[i] = {cmdTextBox.Text,cmd[2],cmd[3]}
						if onEdited then onEdited() end
					end)
					cmdF.Settings.MouseButton1Click:Connect(function()
						openSettingsEditor(event,cmd)
					end)
					cmdF.Delete.MouseButton1Click:Connect(function()
						table.remove(event.commands,i)
						refreshCommands()
						resizeList()
						if currentlyEditingCmd == cmd then
							settingsFrame:TweenPosition(UDim2.new(0,-150,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
						end
						if onEdited then onEdited() end
					end)
					cmdF.Parent = eventF.Cmds.Holder
				end
				eventF:TweenSize(UDim2.new(1,0,0,20 + (expanded and 20*#eventF.Cmds.Holder:GetChildren() or 0)),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
			end
			local newBox = eventF.Cmds.Add.TextBox
			ViewportTextBox.convert(newBox)
			newBox.FocusLost:Connect(function(enter)
				if enter then
					event.commands[#event.commands+1] = {newBox.Text,defaultSettings(event),0}
					newBox.Text = ""
					refreshCommands()
					resizeList()
					if onEdited then onEdited() end
				end
			end)
			eventF.Parent = eventListHolder
			refreshCommands()
		end
		resizeList()
	end
	local function saveData()
		local result = {}
		for i,v in pairs(events) do
			result[i] = v.commands
		end
		return HttpService:JSONEncode(result)
	end
	local function loadData(str)
		local data = HttpService:JSONDecode(str)
		for i,v in pairs(data) do
			if events[i] then
				events[i].commands = v
			end
		end
	end
	local function addCmd(event,data)
		table.insert(events[event].commands,data)
	end
	local function setOnEdited(f)
		if type(f) == "function" then
			onEdited = f
		end
	end
	main.TopBar.Close.MouseButton1Click:Connect(function()
		main:TweenPosition(UDim2.new(0.5,-175,0,-500), "InOut", "Quart", 0.5, true, nil)
	end)
	dragGUI(main)
	main.Parent = ScaledHolder
	return {
		RegisterEvent = registerEvent,
		FireEvent = fireEvent,
		Refresh = refreshList,
		SaveData = saveData,
		LoadData = loadData,
		AddCmd = addCmd,
		Frame = main,
		SetOnEdited = setOnEdited
	}
end)()
reference = (function()
	local main = create({
		{1,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="Main",Position=UDim2.new(0.5,-250,0,-500),Size=UDim2.new(0,500,0,20),ZIndex=10,}},
		{2,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="TopBar",Parent={1},Size=UDim2.new(1,0,0,20),ZIndex=10,}},
		{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Size=UDim2.new(1,0,0.94999998807907,0),Text="Reference",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Close",Parent={2},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,20),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,ZIndex=10,}},
		{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=getcustomasset("slate/iy/assets/close.png"),Parent={4},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,10,0,10),ZIndex=10,}},
		{6,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BorderSizePixel=0,Name="Content",Parent={1},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,0,300),ZIndex=10,}},
		{7,"ScrollingFrame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14509804546833),BackgroundTransparency=1,BorderColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",CanvasSize=UDim2.new(0,0,0,1313),Name="List",Parent={6},ScrollBarImageColor3=Color3.new(0.30588236451149,0.30588236451149,0.3098039329052),ScrollBarThickness=8,Size=UDim2.new(1,0,1,0),TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",VerticalScrollBarInset=2,ZIndex=10,}},
		{8,"UIListLayout",{Parent={7},SortOrder=2,}},
		{9,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,429),ZIndex=10,}},
		{10,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={9},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Special Player Cases",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={9},Position=UDim2.new(0,8,0,25),Size=UDim2.new(1,-8,0,20),Text="These keywords can be used to quickly select groups of players in commands:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{12,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={9},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{13,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Cases",Parent={9},Position=UDim2.new(0,8,0,55),Size=UDim2.new(1,-16,0,342),ZIndex=10,}},
		{14,"UIListLayout",{Parent={13},SortOrder=2,}},
		{15,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-4,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{16,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={15},Size=UDim2.new(1,0,1,0),Text="all",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{17,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={15},Position=UDim2.new(0,15,0,0),Size=UDim2.new(1,0,1,0),Text="- includes everyone",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{18,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-3,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{19,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={18},Size=UDim2.new(1,0,1,0),Text="others",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={18},Position=UDim2.new(0,37,0,0),Size=UDim2.new(1,0,1,0),Text="- includes everyone except you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{21,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-2,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{22,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={21},Size=UDim2.new(1,0,1,0),Text="me",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{23,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={21},Position=UDim2.new(0,19,0,0),Size=UDim2.new(1,0,1,0),Text="- includes your player only",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{24,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{25,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={24},Size=UDim2.new(1,0,1,0),Text="#[number]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{26,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={24},Position=UDim2.new(0,59,0,0),Size=UDim2.new(1,0,1,0),Text="- gets a specified amount of random players",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{27,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{28,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={27},Size=UDim2.new(1,0,1,0),Text="random",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{29,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={27},Position=UDim2.new(0,44,0,0),Size=UDim2.new(1,0,1,0),Text="- affects a random player",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{30,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{31,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={30},Size=UDim2.new(1,0,1,0),Text="%[team name]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{32,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={30},Position=UDim2.new(0,78,0,0),Size=UDim2.new(1,0,1,0),Text="- includes everyone on a given team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{33,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{34,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={33},Size=UDim2.new(1,0,1,0),Text="allies / team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{35,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={33},Position=UDim2.new(0,63,0,0),Size=UDim2.new(1,0,1,0),Text="- players who are on your team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{36,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{37,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={36},Size=UDim2.new(1,0,1,0),Text="enemies / nonteam",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{38,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={36},Position=UDim2.new(0,101,0,0),Size=UDim2.new(1,0,1,0),Text="- players who are not on your team",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{39,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{40,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={39},Size=UDim2.new(1,0,1,0),Text="friends",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{41,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={39},Position=UDim2.new(0,40,0,0),Size=UDim2.new(1,0,1,0),Text="- anyone who is friends with you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{42,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{43,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={42},Size=UDim2.new(1,0,1,0),Text="nonfriends",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{44,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={42},Position=UDim2.new(0,61,0,0),Size=UDim2.new(1,0,1,0),Text="- anyone who is not friends with you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{45,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{46,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={45},Size=UDim2.new(1,0,1,0),Text="guests",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{47,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={45},Position=UDim2.new(0,36,0,0),Size=UDim2.new(1,0,1,0),Text="- guest players (obsolete)",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{48,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{49,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={48},Size=UDim2.new(1,0,1,0),Text="bacons",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{50,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={48},Position=UDim2.new(0,40,0,0),Size=UDim2.new(1,0,1,0),Text="- anyone with the \"bacon\" or pal hair",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{51,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{52,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={51},Size=UDim2.new(1,0,1,0),Text="age[number]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{53,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={51},Position=UDim2.new(0,71,0,0),Size=UDim2.new(1,0,1,0),Text="- includes anyone below or at the given age",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{54,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{55,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={54},Size=UDim2.new(1,0,1,0),Text="rad[number]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{56,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={54},Position=UDim2.new(0,70,0,0),Size=UDim2.new(1,0,1,0),Text="- includes anyone within the given radius",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{57,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{58,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={57},Size=UDim2.new(1,0,1,0),Text="nearest",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{59,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={57},Position=UDim2.new(0,43,0,0),Size=UDim2.new(1,0,1,0),Text="- gets the closest player to you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{60,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{61,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={60},Size=UDim2.new(1,0,1,0),Text="farthest",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{62,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={60},Position=UDim2.new(0,46,0,0),Size=UDim2.new(1,0,1,0),Text="- gets the farthest player from you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{63,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{64,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={63},Size=UDim2.new(1,0,1,0),Text="group[ID]",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{65,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={63},Position=UDim2.new(0,55,0,0),Size=UDim2.new(1,0,1,0),Text="- gets players who are in a certain group",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{66,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{67,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={66},Size=UDim2.new(1,0,1,0),Text="alive",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{68,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={66},Position=UDim2.new(0,27,0,0),Size=UDim2.new(1,0,1,0),Text="- gets players who are alive",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{69,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{70,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={69},Size=UDim2.new(1,0,1,0),Text="dead",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{71,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={69},Position=UDim2.new(0,29,0,0),Size=UDim2.new(1,0,1,0),Text="- gets players who are dead",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{72,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=-1,Name="Case",Parent={13},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,0,0,18),ZIndex=10,}},
		{73,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="CaseName",Parent={72},Size=UDim2.new(1,0,1,0),Text="@username",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{74,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="CaseDesc",Parent={72},Position=UDim2.new(0,66,0,0),Size=UDim2.new(1,0,1,0),Text="- searches for players by username only (ignores displaynames)",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{75,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,180),ZIndex=10,}},
		{76,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={75},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Various Operators",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{77,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={75},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{78,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={75},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,16),Text="Use commas to separate multiple expressions:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{79,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={75},Position=UDim2.new(0,8,0,75),Size=UDim2.new(1,-8,0,16),Text="Use - to exclude, and + to include players in your expression:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{80,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={75},Position=UDim2.new(0,8,0,91),Size=UDim2.new(1,-8,0,16),Text=";locate %blue-friends (gets players in blue team who aren't your friends)",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{81,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={75},Position=UDim2.new(0,8,0,46),Size=UDim2.new(1,-8,0,16),Text=";locate noob,noob2,bob",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{82,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={75},Position=UDim2.new(0,8,0,120),Size=UDim2.new(1,-8,0,16),Text="Put ! before a command to run it with the last arguments it was ran with:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{83,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={75},Position=UDim2.new(0,8,0,136),Size=UDim2.new(1,-8,0,32),Text="After running ;offset 0 100 0,  you can run !offset anytime to repeat that command with the same arguments that were used to run it last time",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{84,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,154),ZIndex=10,}},
		{85,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={84},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Command Looping",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{86,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={84},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,20),Text="Form: [How many times it loops]^[delay (optional)]^[command]",TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{87,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={84},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{88,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={84},Position=UDim2.new(0,8,0,50),Size=UDim2.new(1,-8,0,20),Text="Use the 'breakloops' command to stop all running loops.",TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{89,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={84},Position=UDim2.new(0,8,0,80),Size=UDim2.new(1,-8,0,16),Text="Examples:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{90,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={84},Position=UDim2.new(0,8,0,98),Size=UDim2.new(1,-8,0,42),Text=";5^btools - gives you 5 sets of btools\n;10^3^drophats - drops your hats every 3 seconds 10 times\n;inf^0.1^animspeed 100 - infinitely loops your animation speed to 100",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{91,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,120),ZIndex=10,}},
		{92,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={91},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Execute Multiple Commands at Once",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{93,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={91},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,20),Text="You can execute multiple commands at once using \"\\\"",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{94,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={91},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{95,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={91},Position=UDim2.new(0,8,0,60),Size=UDim2.new(1,-8,0,16),Text="Examples:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{96,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={91},Position=UDim2.new(0,8,0,78),Size=UDim2.new(1,-8,0,32),Text=";drophats\\respawn - drops your hats and respawns you\n;enable inventory\\enable playerlist\\refresh - enables those coregui items and refreshes you",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{97,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,75),ZIndex=10,}},
		{98,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={97},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Browse Command History",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{99,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={97},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,32),Text="While focused on the command bar, you can use the up and down arrow keys to browse recently used commands",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{100,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={97},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{101,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,75),ZIndex=10,}},
		{102,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={101},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Autocomplete in the Command Bar",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{103,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={101},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,32),Text="While focused on the command bar, you can use the tab key to insert the top suggested command into the command bar.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{104,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={101},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{105,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,175),ZIndex=10,}},
		{106,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={105},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Using Event Binds",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{107,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={105},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,32),Text="Use event binds to set up commands that get executed when certain events happen. You can edit the conditions for an event command to run (such as which player triggers it).",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{108,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={105},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),ZIndex=10,}},
		{109,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={105},Position=UDim2.new(0,8,0,70),Size=UDim2.new(1,-8,0,48),Text="Some events may send arguments; you can use them in your event command by using $ followed by the argument number ($1, $2, etc). You can find out the order and types of these arguments by looking at the settings of the event command.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{110,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Text",Parent={105},Position=UDim2.new(0,8,0,130),Size=UDim2.new(1,-8,0,16),Text="Example:",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{111,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={105},Position=UDim2.new(0,8,0,148),Size=UDim2.new(1,-8,0,16),Text="Setting up 'goto $1' on the OnChatted event will teleport you to any player that chats.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,TextYAlignment=0,ZIndex=10,}},
		{112,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Section",Parent={7},Size=UDim2.new(1,0,0,105),ZIndex=10,}},
		{113,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Header",Parent={112},Position=UDim2.new(0,8,0,5),Size=UDim2.new(1,-8,0,20),Text="Get Further Help",TextColor3=Color3.new(1,1,1),TextSize=20,TextXAlignment=0,ZIndex=10,}},
		{114,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Text",Parent={112},Position=UDim2.new(0,8,0,30),Size=UDim2.new(1,-8,0,32),Text="You can join the Discord server to get support with IY,  and read up on more documentation such as the Plugin API.",TextColor3=Color3.new(1,1,1),TextSize=14,TextWrapped=true,TextXAlignment=0,ZIndex=10,}},
		{115,"Frame",{BackgroundColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),BorderSizePixel=0,Name="Line",Parent={112},Position=UDim2.new(0,10,1,-1),Size=UDim2.new(1,-20,0,1),Visible=false,ZIndex=10,}},
		{116,"TextButton",{BackgroundColor3=Color3.new(0.48627451062202,0.61960786581039,0.85098040103912),BorderColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),Font=4,Name="InviteButton",Parent={112},Position=UDim2.new(0,5,0,75),Size=UDim2.new(1,-10,0,25),Text="Copy Discord Invite Link (https://discord.gg/78ZuWSq)",TextColor3=Color3.new(0.1803921610117,0.1803921610117,0.1843137294054),TextSize=16,ZIndex=10,}},
	})
	for i,v in pairs(main.Content.List:GetDescendants()) do
		if v:IsA("TextLabel") then
			table.insert(text1,v)
		end
	end
	table.insert(scroll,main.Content.List)
	table.insert(shade1,main.Content)
	table.insert(shade2,main.TopBar)
	main.Name = randomString()
	main.TopBar.Close.MouseButton1Click:Connect(function()
		main:TweenPosition(UDim2.new(0.5,-250,0,-500), "InOut", "Quart", 0.5, true, nil)
	end)
	local inviteButton = main:FindFirstChild("InviteButton",true)
	local lastPress = nil
	inviteButton.MouseButton1Click:Connect(function()
		if everyClipboard then
			toClipboard("https://discord.gg/78ZuWSq")
			inviteButton.Text = "Copied"
		else
			inviteButton.Text = "No Clipboard Function, type out the link"
		end
		local pressTime = tick()
		lastPress = pressTime
		wait(2)
		if lastPress ~= pressTime then return end
		inviteButton.Text = "Copy Discord Invite Link (https://discord.gg/78ZuWSq)"
	end)
	dragGUI(main)
	main.Parent = ScaledHolder
	ReferenceButton.MouseButton1Click:Connect(function()
		main:TweenPosition(UDim2.new(0.5,-250,0.5,-150), "InOut", "Quart", 0.5, true, nil)
	end)
end)()
currentShade1 = Color3.fromRGB(10, 10, 10)
currentShade2 = Color3.fromRGB(0, 0, 0)
currentShade3 = Color3.fromRGB(78, 78, 79)
currentText1 = Color3.new(1, 1, 1)
currentText2 = Color3.new(0, 0, 0)
currentScroll = Color3.fromRGB(78,78,79)
defaultGuiScale = IsOnMobile and 0.9 or 1
defaultsettings = {
	prefix = ';';
	StayOpen = false;
	guiScale = defaultGuiScale;
	espTransparency = 0.3;
	keepIY = true;
	logsEnabled = false;
	jLogsEnabled = false;
	aliases = {};
	binds = {};
	WayPoints = {};
	PluginsTable = {};
	currentShade1 = {currentShade1.R,currentShade1.G,currentShade1.B};
	currentShade2 = {currentShade2.R,currentShade2.G,currentShade2.B};
	currentShade3 = {currentShade3.R,currentShade3.G,currentShade3.B};
	currentText1 = {currentText1.R,currentText1.G,currentText1.B};
	currentText2 = {currentText2.R,currentText2.G,currentText2.B};
	currentScroll = {currentScroll.R,currentScroll.G,currentScroll.B};
	eventBinds = eventEditor.SaveData()
}
defaults = HttpService:JSONEncode(defaultsettings)
nosaves = false
useFactorySettings = function()
	prefix = ';'
	StayOpen = false
	guiScale = defaultGuiScale
	KeepInfYield = false
	espTransparency = 0.3
	logsEnabled = false
	jLogsEnabled = false
	logsWebhook = nil
	aliases = {}
	binds = {}
	WayPoints = {}
	PluginsTable = {}
end
function createPopup(title, text)
	local Popup = Instance.new("Frame")
	local background = Instance.new("Frame")
	local Directions = Instance.new("TextLabel")
	local shadow = Instance.new("Frame")
	local PopupText = Instance.new("TextLabel")
	local Exit = Instance.new("TextButton")
	local ExitImage = Instance.new("ImageLabel")
	Popup.Name = randomString()
	Popup.Parent = ScaledHolder
	Popup.Active = true
	Popup.BackgroundTransparency = 1
	Popup.Position = UDim2.new(0.5, -180, 0, -500)
	Popup.Size = UDim2.new(0, 360, 0, 20)
	Popup.ZIndex = 10
	background.Name = "background"
	background.Parent = Popup
	background.Active = true
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	background.BorderSizePixel = 0
	background.Position = UDim2.new(0, 0, 0, 20)
	background.Size = UDim2.new(0, 360, 0, 205)
	background.ZIndex = 10
	Directions.Name = "Directions"
	Directions.Parent = background
	Directions.BackgroundTransparency = 1
	Directions.BorderSizePixel = 0
	Directions.Position = UDim2.new(0, 10, 0, 10)
	Directions.Size = UDim2.new(0, 340, 0, 185)
	Directions.Font = Enum.Font.SourceSans
	Directions.TextSize = 14
	Directions.Text = text
	Directions.TextColor3 = Color3.new(1, 1, 1)
	Directions.TextWrapped = true
	Directions.TextXAlignment = Enum.TextXAlignment.Left
	Directions.TextYAlignment = Enum.TextYAlignment.Top
	Directions.ZIndex = 10
	shadow.Name = "shadow"
	shadow.Parent = Popup
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.new(0, 360, 0, 20)
	shadow.ZIndex = 10
	PopupText.Name = "PopupText"
	PopupText.Parent = shadow
	PopupText.BackgroundTransparency = 1
	PopupText.Size = UDim2.new(1, 0, 0.95, 0)
	PopupText.ZIndex = 10
	PopupText.Font = Enum.Font.SourceSans
	PopupText.TextSize = 14
	PopupText.Text = title
	PopupText.TextColor3 = Color3.new(1, 1, 1)
	PopupText.TextWrapped = true
	Exit.Name = "Exit"
	Exit.Parent = shadow
	Exit.BackgroundTransparency = 1
	Exit.Position = UDim2.new(1, -20, 0, 0)
	Exit.Size = UDim2.new(0, 20, 0, 20)
	Exit.Text = ""
	Exit.ZIndex = 10
	ExitImage.Parent = Exit
	ExitImage.BackgroundColor3 = Color3.new(1, 1, 1)
	ExitImage.BackgroundTransparency = 1
	ExitImage.Position = UDim2.new(0, 5, 0, 5)
	ExitImage.Size = UDim2.new(0, 10, 0, 10)
	ExitImage.Image = getcustomasset("slate/iy/assets/close.png")
	ExitImage.ZIndex = 10
	Popup:TweenPosition(UDim2.new(0.5, -180, 0, 150), "InOut", "Quart", 0.5, true, nil)
	Exit.MouseButton1Click:Connect(function()
		Popup:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
		task.wait(0.6)
		Popup:Destroy()
	end)
end
local loadedEventData = nil
local jsonAttempts = 0
function saves()
	if writefileExploit() and readfileExploit() and jsonAttempts < 10 then
		local readSuccess, out = readfile("IY_FE.iy", true)
		if readSuccess then
			if out ~= nil and tostring(out):gsub("%s", "") ~= "" then
				local success, response = pcall(function()
					local json = HttpService:JSONDecode(out)
					if vtype(json.prefix, "string") then prefix = json.prefix else prefix = ';' end
					if vtype(json.StayOpen, "boolean") then StayOpen = json.StayOpen else StayOpen = false end
					if vtype(json.guiScale, "number") then guiScale = json.guiScale else guiScale = defaultGuiScale end
					if vtype(json.keepIY, "boolean") then KeepInfYield = json.keepIY else KeepInfYield = false end
					if vtype(json.espTransparency, "number") then espTransparency = json.espTransparency else espTransparency = 0.3 end
					if vtype(json.logsEnabled, "boolean") then logsEnabled = json.logsEnabled else logsEnabled = false end
					if vtype(json.jLogsEnabled, "boolean") then jLogsEnabled = json.jLogsEnabled else jLogsEnabled = false end
					if vtype(json.logsWebhook, "string") then logsWebhook = json.logsWebhook else logsWebhook = nil end
					if vtype(json.aliases, "table") then aliases = json.aliases else aliases = {} end
					if vtype(json.binds, "table") then binds = json.binds else binds = {} end
					if vtype(json.spawnCmds, "table") then spawnCmds = json.spawnCmds end
					if vtype(json.WayPoints, "table") then AllWaypoints = json.WayPoints else WayPoints = {} AllWaypoints = {} end
					if vtype(json.PluginsTable, "table") then PluginsTable = json.PluginsTable else PluginsTable = {} end
					if vtype(json.currentShade1, "table") then currentShade1 = Color3.new(json.currentShade1[1],json.currentShade1[2],json.currentShade1[3]) end
					if vtype(json.currentShade2, "table") then currentShade2 = Color3.new(json.currentShade2[1],json.currentShade2[2],json.currentShade2[3]) end
					if vtype(json.currentShade3, "table") then currentShade3 = Color3.new(json.currentShade3[1],json.currentShade3[2],json.currentShade3[3]) end
					if vtype(json.currentText1, "table") then currentText1 = Color3.new(json.currentText1[1],json.currentText1[2],json.currentText1[3]) end
					if vtype(json.currentText2, "table") then currentText2 = Color3.new(json.currentText2[1],json.currentText2[2],json.currentText2[3]) end
					if vtype(json.currentScroll, "table") then currentScroll = Color3.new(json.currentScroll[1],json.currentScroll[2],json.currentScroll[3]) end
					if vtype(json.eventBinds, "string") then loadedEventData = json.eventBinds end
				end)
				if not success then
					jsonAttempts = jsonAttempts + 1
					warn("Save Json Error:", response)
					warn("Overwriting Save File")
					writefile("IY_FE.iy", defaults, true)
					wait()
					saves()
				end
			else
				writefile("IY_FE.iy", defaults, true)
				wait()
				local dReadSuccess, dOut = readfile("IY_FE.iy", true)
				if dReadSuccess and dOut ~= nil and tostring(dOut):gsub("%s", "") ~= "" then
					saves()
				else
					nosaves = true
					useFactorySettings()
					createPopup("File Error", "There was a problem writing a save file to your PC.\n\nPlease contact the developer/support team for your exploit and tell them writefile/readfile is not working.\n\nYour settings, keybinds, waypoints, and aliases will not save if you continue.\n\nThings to try:\n> Make sure a 'workspace' folder is located in the same folder as your exploit\n> If your exploit is inside of a zip/rar file, extract it.\n> Rejoin the game and try again or restart your PC and try again.")
				end
			end
		else
			writefile("IY_FE.iy", defaults, true)
			wait()
			local dReadSuccess, dOut = readfile("IY_FE.iy", true)
			if dReadSuccess and dOut ~= nil and tostring(dOut):gsub("%s", "") ~= "" then
				saves()
			else
				nosaves = true
				useFactorySettings()
				createPopup("File Error", "There was a problem writing a save file to your PC.\n\nPlease contact the developer/support team for your exploit and tell them writefile/readfile is not working.\n\nYour settings, keybinds, waypoints, and aliases will not save if you continue.\n\nThings to try:\n> Make sure a 'workspace' folder is located in the same folder as your exploit\n> If your exploit is inside of a zip/rar file, extract it.\n> Rejoin the game and try again or restart your PC and try again.")
			end
		end
	else
		if jsonAttempts >= 10 then
			nosaves = true
			useFactorySettings()
			createPopup("File Error", "Sorry, we have attempted to parse your save file, but it is unreadable!\n\nSlate is now using factory settings until your exploit's file system works.\n\nYour save file has not been deleted.")
		else
			nosaves = true
			useFactorySettings()
		end
	end
end
saves()
function updatesaves()
	if nosaves == false and writefileExploit() then
		local update = {
			prefix = prefix;
			StayOpen = StayOpen;
			guiScale = guiScale;
			keepIY = KeepInfYield;
			espTransparency = espTransparency;
			logsEnabled = logsEnabled;
			jLogsEnabled = jLogsEnabled;
			logsWebhook = logsWebhook;
			aliases = aliases;
			binds = binds or {};
			WayPoints = AllWaypoints;
			PluginsTable = PluginsTable;
			currentShade1 = {currentShade1.R,currentShade1.G,currentShade1.B};
			currentShade2 = {currentShade2.R,currentShade2.G,currentShade2.B};
			currentShade3 = {currentShade3.R,currentShade3.G,currentShade3.B};
			currentText1 = {currentText1.R,currentText1.G,currentText1.B};
			currentText2 = {currentText2.R,currentText2.G,currentText2.B};
			currentScroll = {currentScroll.R,currentScroll.G,currentScroll.B};
			eventBinds = eventEditor.SaveData()
		}
		writefileCooldown("IY_FE.iy", HttpService:JSONEncode(update))
	end
end
eventEditor.SetOnEdited(updatesaves)
pWayPoints = {}
WayPoints = {}
if #AllWaypoints > 0 then
	for i = 1, #AllWaypoints do
		if not AllWaypoints[i].GAME or AllWaypoints[i].GAME == PlaceId then
			WayPoints[#WayPoints + 1] = {NAME = AllWaypoints[i].NAME, COORD = {AllWaypoints[i].COORD[1], AllWaypoints[i].COORD[2], AllWaypoints[i].COORD[3]}, GAME = AllWaypoints[i].GAME}
		end
	end
end
if type(binds) ~= "table" then binds = {} end
if type(PluginsTable) == "table" then
	for i = #PluginsTable, 1, -1 do
		if string.sub(PluginsTable[i], -3) ~= ".iy" then
			table.remove(PluginsTable, i)
		end
	end
end
function Time()
	local HOUR = math.floor((tick() % 86400) / 3600)
	local MINUTE = math.floor((tick() % 3600) / 60)
	local SECOND = math.floor(tick() % 60)
	local AP = HOUR > 11 and 'PM' or 'AM'
	HOUR = (HOUR % 12 == 0 and 12 or HOUR % 12)
	HOUR = HOUR < 10 and '0' .. HOUR or HOUR
	MINUTE = MINUTE < 10 and '0' .. MINUTE or MINUTE
	SECOND = SECOND < 10 and '0' .. SECOND or SECOND
	return HOUR .. ':' .. MINUTE .. ':' .. SECOND .. ' ' .. AP
end
PrefixBox.Text = prefix
local SettingsOpen = false
local isHidden = false
if StayOpen == false then
	On.BackgroundTransparency = 1
else
	On.BackgroundTransparency = 0
end
if logsEnabled then
	Toggle.Text = 'Enabled'
else
	Toggle.Text = 'Disabled'
end
if jLogsEnabled then
	Toggle_2.Text = 'Enabled'
else
	Toggle_2.Text = 'Disabled'
end
function maximizeHolder()
	if StayOpen == false then
		Holder:TweenPosition(UDim2.new(1, Holder.Position.X.Offset, 1, -220), "InOut", "Quart", 0.2, true, nil)
	end
end
minimizeNum = -20
function minimizeHolder()
	if StayOpen == false then
		Holder:TweenPosition(UDim2.new(1, Holder.Position.X.Offset, 1, minimizeNum), "InOut", "Quart", 0.5, true, nil)
	end
end
function cmdbarHolder()
	if StayOpen == false then
		Holder:TweenPosition(UDim2.new(1, Holder.Position.X.Offset, 1, -45), "InOut", "Quart", 0.5, true, nil)
	end
end
pinNotification = nil
local notifyCount = 0
function notify(text,text2,length)
	local disableAll = checkSetting and checkSetting("disableallnotifs")
	if disableAll and disableAll.current then return end
	if queueNotification then
		if text2 then
			queueNotification(text, text2)
		else
			queueNotification("Notification", text)
		end
		return
	end
	task.spawn(function()
		local LnotifyCount = notifyCount+1
		local notificationPinned = false
		notifyCount = notifyCount+1
		if pinNotification then pinNotification:Disconnect() end
		pinNotification = PinButton.MouseButton1Click:Connect(function()
			task.spawn(function()
				pinNotification:Disconnect()
				notificationPinned = true
				Title_2.BackgroundTransparency = 1
				wait(0.5)
				Title_2.BackgroundTransparency = 0
			end)
		end)
		Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, 0), "InOut", "Quart", 0.5, true, nil)
		wait(0.6)
		local closepressed = false
		if text2 then
			Title_2.Text = text
			Text_2.Text = text2
		else
			Title_2.Text = 'Notification'
			Text_2.Text = text
		end
		Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, -100), "InOut", "Quart", 0.5, true, nil)
		CloseButton.MouseButton1Click:Connect(function()
			Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, 0), "InOut", "Quart", 0.5, true, nil)
			closepressed = true
			pinNotification:Disconnect()
		end)
		if length and isNumber(length) then
			wait(length)
		else
			wait(10)
		end
		if LnotifyCount == notifyCount then
			if closepressed == false and notificationPinned == false then
				pinNotification:Disconnect()
				Notification:TweenPosition(UDim2.new(1, Notification.Position.X.Offset, 1, 0), "InOut", "Quart", 0.5, true, nil)
			end
			notifyCount = 0
		end
	end)
end
local lastMessage = nil
local lastLabel = nil
local lastMsgLabel = nil
local dupeCount = 1
function CreateLabel(player, Text)
	local username = player.Name
	local displayName = player.DisplayName
	local userId = player.UserId
	local nameText = displayName .. " (@" .. username .. ")"

	if lastMessage == username..Text then
		dupeCount = dupeCount+1
		if lastMsgLabel then
			lastMsgLabel.Text = Text .. " (x" .. dupeCount .. ")"
		end
	else
		if dupeCount > 1 then dupeCount = 1 end
		if #scroll_2:GetChildren() >= 2546 then
			scroll_2:ClearAllChildren()
		end
		local alls = 0
		for i,v in pairs(scroll_2:GetChildren()) do
			if v then
				alls = v.Size.Y.Offset + alls
			end
		end

		local card = Instance.new("Frame")
		card.Name = username
		card.Parent = scroll_2
		card.BackgroundTransparency = 1
		card.BorderSizePixel = 0

		local pfp = Instance.new("ImageLabel", card)
		pfp.Size = UDim2.new(0, 32, 0, 32)
		pfp.Position = UDim2.new(0, 6, 0, 6)
		pfp.BackgroundTransparency = 1
		pfp.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
		local pfpCorner = Instance.new("UICorner", pfp)
		pfpCorner.CornerRadius = UDim.new(1, 0)

		local nameLbl = Instance.new("TextLabel", card)
		nameLbl.Size = UDim2.new(1, -50, 0, 15)
		nameLbl.Position = UDim2.new(0, 46, 0, 5)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = nameText
		nameLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
		nameLbl.TextSize = 13
		nameLbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left

		local msgLbl = Instance.new("TextLabel", card)
		msgLbl.Position = UDim2.new(0, 46, 0, 22)
		msgLbl.Size = UDim2.new(1, -50, 0, 20)
		msgLbl.BackgroundTransparency = 1
		msgLbl.Text = Text
		msgLbl.TextColor3 = Color3.fromRGB(170, 170, 170)
		msgLbl.TextSize = 13
		msgLbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		msgLbl.TextWrapped = true
		msgLbl.TextXAlignment = Enum.TextXAlignment.Left
		msgLbl.TextYAlignment = Enum.TextYAlignment.Top

		msgLbl.Size = UDim2.new(1, -50, 0, msgLbl.TextBounds.Y)
		local cardHeight = math.max(44, 28 + msgLbl.TextBounds.Y)
		card.Size = UDim2.new(1, -10, 0, cardHeight)

		lastMessage = username..Text
		lastLabel = card
		lastMsgLabel = msgLbl

		card.Position = UDim2.new(-1, 0, 0, alls)
		scroll_2.CanvasSize = UDim2.new(0, 0, 0, alls + cardHeight)
		scroll_2.CanvasPosition = Vector2.new(0, scroll_2.CanvasPosition.Y + cardHeight)
		card:TweenPosition(UDim2.new(0, 3, 0, alls), 'In', 'Quint', 0.5)
	end
end
function CreateJoinLabel(plr,ID)
	if #scroll_3:GetChildren() >= 2546 then
		scroll_3:ClearAllChildren()
	end
	local infoFrame = Instance.new("Frame")
	local info1 = Instance.new("TextLabel")
	local info2 = Instance.new("TextLabel")
	local ImageLabel_3 = Instance.new("ImageLabel")
	infoFrame.Name = randomString()
	infoFrame.Parent = scroll_3
	infoFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	infoFrame.BackgroundTransparency = 1
	infoFrame.BorderColor3 = Color3.new(0.105882, 0.164706, 0.207843)
	infoFrame.Size = UDim2.new(1, 0, 0, 50)
	info1.Name = randomString()
	info1.Parent = infoFrame
	info1.BackgroundTransparency = 1
	info1.BorderSizePixel = 0
	info1.Position = UDim2.new(0, 45, 0, 0)
	info1.Size = UDim2.new(0, 135, 1, 0)
	info1.ZIndex = 10
	info1.Font = Enum.Font.SourceSans
	info1.FontSize = Enum.FontSize.Size14
	info1.Text = "Username: "..plr.Name.."\nJoined Server: "..Time()
	info1.TextColor3 = Color3.new(1, 1, 1)
	info1.TextWrapped = true
	info1.TextXAlignment = Enum.TextXAlignment.Left
	info2.Name = randomString()
	info2.Parent = infoFrame
	info2.BackgroundTransparency = 1
	info2.BorderSizePixel = 0
	info2.Position = UDim2.new(0, 185, 0, 0)
	info2.Size = UDim2.new(0, 140, 1, -5)
	info2.ZIndex = 10
	info2.Font = Enum.Font.SourceSans
	info2.FontSize = Enum.FontSize.Size14
	info2.Text = "User ID: "..ID.."\nAccount Age: "..plr.AccountAge.."\nJoined Roblox: Loading..."
	info2.TextColor3 = Color3.new(1, 1, 1)
	info2.TextWrapped = true
	info2.TextXAlignment = Enum.TextXAlignment.Left
	info2.TextYAlignment = Enum.TextYAlignment.Center
	ImageLabel_3.Parent = infoFrame
	ImageLabel_3.BackgroundTransparency = 1
	ImageLabel_3.BorderSizePixel = 0
	ImageLabel_3.Size = UDim2.new(0, 45, 1, 0)
	ImageLabel_3.Image = Players:GetUserThumbnailAsync(ID, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
	scroll_3.CanvasSize = UDim2.new(0, 0, 0, listlayout.AbsoluteContentSize.Y)
	scroll_3.CanvasPosition = Vector2.new(0,scroll_2.CanvasPosition.Y+infoFrame.AbsoluteSize.Y)
	wait()
	local user = game:HttpGet("https://users.roblox.com/v1/users/"..ID)
	local json = HttpService:JSONDecode(user)
	local date = json["created"]:sub(1,10)
	local splitDates = string.split(date,"-")
	info2.Text = string.gsub(info2.Text, "Loading...",splitDates[2].."/"..splitDates[3].."/"..splitDates[1])
end
IYMouse.KeyDown:Connect(function(Key)
	if (Key==prefix) then
		RunService.RenderStepped:Wait()
		Cmdbar:CaptureFocus()
		maximizeHolder()
	end
end)
local lastMinimizeReq = 0
Holder.MouseEnter:Connect(function()
	lastMinimizeReq = 0
	maximizeHolder()
end)
Holder.MouseLeave:Connect(function()
	if not Cmdbar:IsFocused() then
		local reqTime = tick()
		lastMinimizeReq = reqTime
		wait(1)
		if lastMinimizeReq ~= reqTime then return end
		if not Cmdbar:IsFocused() then
			minimizeHolder()
		end
	end
end)
function updateColors(color,ctype)
	if ctype == shade1 then
		for i,v in pairs(shade1) do
			v.BackgroundColor3 = color
		end
		currentShade1 = color
	elseif ctype == shade2 then
		for i,v in pairs(shade2) do
			v.BackgroundColor3 = color
		end
		currentShade2 = color
	elseif ctype == shade3 then
		for i,v in pairs(shade3) do
			v.BackgroundColor3 = color
		end
		currentShade3 = color
	elseif ctype == text1 then
		for i,v in pairs(text1) do
			v.TextColor3 = color
			if v:IsA("TextBox") then
				v.PlaceholderColor3 = color
			end
		end
		currentText1 = color
	elseif ctype == text2 then
		for i,v in pairs(text2) do
			v.TextColor3 = color
		end
		currentText2 = color
	elseif ctype == scroll then
		for i,v in pairs(scroll) do
			v.ScrollBarImageColor3 = color
		end
		currentScroll = color
	end
end
local colorpickerOpen = false
ColorsButton.MouseButton1Click:Connect(function()
	cache_currentShade1 = currentShade1
	cache_currentShade2 = currentShade2
	cache_currentShade3 = currentShade3
	cache_currentText1 = currentText1
	cache_currentText2 = currentText2
	cache_currentScroll = currentScroll
	if not colorpickerOpen then
		colorpickerOpen = true
		picker = game:GetObjects("rbxassetid://4908465318")[1]
		picker.Name = randomString()
		picker.Parent = ScaledHolder
		local ColorPicker do
			ColorPicker = {}
			ColorPicker.new = function()
				local newMt = setmetatable({},{})
				local pickerGui = picker.ColorPicker
				local pickerTopBar = pickerGui.TopBar
				local pickerExit = pickerTopBar.Exit
				local pickerFrame = pickerGui.Content
				local colorSpace = pickerFrame.ColorSpaceFrame.ColorSpace
				local colorStrip = pickerFrame.ColorStrip
				local previewFrame = pickerFrame.Preview
				local basicColorsFrame = pickerFrame.BasicColors
				local customColorsFrame = pickerFrame.CustomColors
				local defaultButton = pickerFrame.Default
				local cancelButton = pickerFrame.Cancel
				local shade1Button = pickerFrame.Shade1
				local shade2Button = pickerFrame.Shade2
				local shade3Button = pickerFrame.Shade3
				local text1Button = pickerFrame.Text1
				local text2Button = pickerFrame.Text2
				local scrollButton = pickerFrame.Scroll
				local colorScope = colorSpace.Scope
				local colorArrow = pickerFrame.ArrowFrame.Arrow
				local hueInput = pickerFrame.Hue.Input
				local satInput = pickerFrame.Sat.Input
				local valInput = pickerFrame.Val.Input
				local redInput = pickerFrame.Red.Input
				local greenInput = pickerFrame.Green.Input
				local blueInput = pickerFrame.Blue.Input
				local mouse = IYMouse
				local hue,sat,val = 0,0,1
				local red,green,blue = 1,1,1
				local chosenColor = Color3.new(0,0,0)
				local basicColors = {Color3.new(0,0,0),Color3.new(0.66666668653488,0,0),Color3.new(0,0.33333334326744,0),Color3.new(0.66666668653488,0.33333334326744,0),Color3.new(0,0.66666668653488,0),Color3.new(0.66666668653488,0.66666668653488,0),Color3.new(0,1,0),Color3.new(0.66666668653488,1,0),Color3.new(0,0,0.49803924560547),Color3.new(0.66666668653488,0,0.49803924560547),Color3.new(0,0.33333334326744,0.49803924560547),Color3.new(0.66666668653488,0.33333334326744,0.49803924560547),Color3.new(0,0.66666668653488,0.49803924560547),Color3.new(0.66666668653488,0.66666668653488,0.49803924560547),Color3.new(0,1,0.49803924560547),Color3.new(0.66666668653488,1,0.49803924560547),Color3.new(0,0,1),Color3.new(0.66666668653488,0,1),Color3.new(0,0.33333334326744,1),Color3.new(0.66666668653488,0.33333334326744,1),Color3.new(0,0.66666668653488,1),Color3.new(0.66666668653488,0.66666668653488,1),Color3.new(0,1,1),Color3.new(0.66666668653488,1,1),Color3.new(0.33333334326744,0,0),Color3.new(1,0,0),Color3.new(0.33333334326744,0.33333334326744,0),Color3.new(1,0.33333334326744,0),Color3.new(0.33333334326744,0.66666668653488,0),Color3.new(1,0.66666668653488,0),Color3.new(0.33333334326744,1,0),Color3.new(1,1,0),Color3.new(0.33333334326744,0,0.49803924560547),Color3.new(1,0,0.49803924560547),Color3.new(0.33333334326744,0.33333334326744,0.49803924560547),Color3.new(1,0.33333334326744,0.49803924560547),Color3.new(0.33333334326744,0.66666668653488,0.49803924560547),Color3.new(1,0.66666668653488,0.49803924560547),Color3.new(0.33333334326744,1,0.49803924560547),Color3.new(1,1,0.49803924560547),Color3.new(0.33333334326744,0,1),Color3.new(1,0,1),Color3.new(0.33333334326744,0.33333334326744,1),Color3.new(1,0.33333334326744,1),Color3.new(0.33333334326744,0.66666668653488,1),Color3.new(1,0.66666668653488,1),Color3.new(0.33333334326744,1,1),Color3.new(1,1,1)}
				local customColors = {}
				dragGUI(picker)
				local function updateColor(noupdate)
					local relativeX,relativeY,relativeStripY = 219 - hue*219, 199 - sat*199, 199 - val*199
					local hsvColor = Color3.fromHSV(hue,sat,val)
					if noupdate == 2 or not noupdate then
						hueInput.Text = tostring(math.ceil(359*hue))
						satInput.Text = tostring(math.ceil(255*sat))
						valInput.Text = tostring(math.floor(255*val))
					end
					if noupdate == 1 or not noupdate then
						redInput.Text = tostring(math.floor(255*red))
						greenInput.Text = tostring(math.floor(255*green))
						blueInput.Text = tostring(math.floor(255*blue))
					end
					chosenColor = Color3.new(red,green,blue)
					colorScope.Position = UDim2.new(0,relativeX-9,0,relativeY-9)
					colorStrip.ImageColor3 = Color3.fromHSV(hue,sat,1)
					colorArrow.Position = UDim2.new(0,-2,0,relativeStripY-4)
					previewFrame.BackgroundColor3 = chosenColor
					newMt.Color = chosenColor
					if newMt.Changed then newMt:Changed(chosenColor) end
				end
				local function colorSpaceInput()
					local relativeX = mouse.X - colorSpace.AbsolutePosition.X
					local relativeY = mouse.Y - colorSpace.AbsolutePosition.Y
					if relativeX < 0 then relativeX = 0 elseif relativeX > 219 then relativeX = 219 end
					if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end
					hue = (219 - relativeX)/219
					sat = (199 - relativeY)/199
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
					updateColor()
				end
				local function colorStripInput()
					local relativeY = mouse.Y - colorStrip.AbsolutePosition.Y
					if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end
					val = (199 - relativeY)/199
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
					updateColor()
				end
				local function hookButtons(frame,func)
					frame.ArrowFrame.Up.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Up.BackgroundTransparency = 0.5
						elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
							local releaseEvent,runEvent
							local startTime = tick()
							local pressing = true
							local startNum = tonumber(frame.Text)
							if not startNum then return end
							releaseEvent = UserInputService.InputEnded:Connect(function(input)
								if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
								releaseEvent:Disconnect()
								pressing = false
							end)
							startNum = startNum + 1
							func(startNum)
							while pressing do
								if tick()-startTime > 0.3 then
									startNum = startNum + 1
									func(startNum)
								end
								wait(0.1)
							end
						end
					end)
					frame.ArrowFrame.Up.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Up.BackgroundTransparency = 1
						end
					end)
					frame.ArrowFrame.Down.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Down.BackgroundTransparency = 0.5
						elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
							local releaseEvent,runEvent
							local startTime = tick()
							local pressing = true
							local startNum = tonumber(frame.Text)
							if not startNum then return end
							releaseEvent = UserInputService.InputEnded:Connect(function(input)
								if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
								releaseEvent:Disconnect()
								pressing = false
							end)
							startNum = startNum - 1
							func(startNum)
							while pressing do
								if tick()-startTime > 0.3 then
									startNum = startNum - 1
									func(startNum)
								end
								wait(0.1)
							end
						end
					end)
					frame.ArrowFrame.Down.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							frame.ArrowFrame.Down.BackgroundTransparency = 1
						end
					end)
				end
				colorSpace.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local releaseEvent,mouseEvent
						releaseEvent = UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
						end)
						mouseEvent = UserInputService.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								colorSpaceInput()
							end
						end)
						colorSpaceInput()
					end
				end)
				colorStrip.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local releaseEvent,mouseEvent
						releaseEvent = UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
						end)
						mouseEvent = UserInputService.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								colorStripInput()
							end
						end)
						colorStripInput()
					end
				end)
				local function updateHue(str)
					local num = tonumber(str)
					if num then
						hue = math.clamp(math.floor(num),0,359)/359
						local hsvColor = Color3.fromHSV(hue,sat,val)
						red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
						hueInput.Text = tostring(hue*359)
						updateColor(1)
					end
				end
				hueInput.FocusLost:Connect(function() updateHue(hueInput.Text) end) hookButtons(hueInput,updateHue)
				local function updateSat(str)
					local num = tonumber(str)
					if num then
						sat = math.clamp(math.floor(num),0,255)/255
						local hsvColor = Color3.fromHSV(hue,sat,val)
						red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
						satInput.Text = tostring(sat*255)
						updateColor(1)
					end
				end
				satInput.FocusLost:Connect(function() updateSat(satInput.Text) end) hookButtons(satInput,updateSat)
				local function updateVal(str)
					local num = tonumber(str)
					if num then
						val = math.clamp(math.floor(num),0,255)/255
						local hsvColor = Color3.fromHSV(hue,sat,val)
						red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
						valInput.Text = tostring(val*255)
						updateColor(1)
					end
				end
				valInput.FocusLost:Connect(function() updateVal(valInput.Text) end) hookButtons(valInput,updateVal)
				local function updateRed(str)
					local num = tonumber(str)
					if num then
						red = math.clamp(math.floor(num),0,255)/255
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						redInput.Text = tostring(red*255)
						updateColor(2)
					end
				end
				redInput.FocusLost:Connect(function() updateRed(redInput.Text) end) hookButtons(redInput,updateRed)
				local function updateGreen(str)
					local num = tonumber(str)
					if num then
						green = math.clamp(math.floor(num),0,255)/255
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						greenInput.Text = tostring(green*255)
						updateColor(2)
					end
				end
				greenInput.FocusLost:Connect(function() updateGreen(greenInput.Text) end) hookButtons(greenInput,updateGreen)
				local function updateBlue(str)
					local num = tonumber(str)
					if num then
						blue = math.clamp(math.floor(num),0,255)/255
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						blueInput.Text = tostring(blue*255)
						updateColor(2)
					end
				end
				blueInput.FocusLost:Connect(function() updateBlue(blueInput.Text) end) hookButtons(blueInput,updateBlue)
				local colorChoice = Instance.new("TextButton")
				colorChoice.Name = "Choice"
				colorChoice.Size = UDim2.new(0,25,0,18)
				colorChoice.BorderColor3 = Color3.new(96/255,96/255,96/255)
				colorChoice.Text = ""
				colorChoice.AutoButtonColor = false
				colorChoice.ZIndex = 10
				local row = 0
				local column = 0
				for i,v in pairs(basicColors) do
					local newColor = colorChoice:Clone()
					newColor.BackgroundColor3 = v
					newColor.Position = UDim2.new(0,1 + 30*column,0,21 + 23*row)
					newColor.MouseButton1Click:Connect(function()
						red,green,blue = v.r,v.g,v.b
						local newColor = Color3.new(red,green,blue)
						hue,sat,val = Color3.toHSV(newColor)
						updateColor()
					end)
					newColor.Parent = basicColorsFrame
					column = column + 1
					if column == 6 then row = row + 1 column = 0 end
				end
				row = 0
				column = 0
				for i = 1,12 do
					local color = customColors[i] or Color3.new(0,0,0)
					local newColor = colorChoice:Clone()
					newColor.BackgroundColor3 = color
					newColor.Position = UDim2.new(0,1 + 30*column,0,20 + 23*row)
					newColor.MouseButton1Click:Connect(function()
						local curColor = customColors[i] or Color3.new(0,0,0)
						red,green,blue = curColor.r,curColor.g,curColor.b
						hue,sat,val = Color3.toHSV(curColor)
						updateColor()
					end)
					newColor.MouseButton2Click:Connect(function()
						customColors[i] = chosenColor
						newColor.BackgroundColor3 = chosenColor
					end)
					newColor.Parent = customColorsFrame
					column = column + 1
					if column == 6 then row = row + 1 column = 0 end
				end
				shade1Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,shade1) end end)
				shade1Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade1Button.BackgroundTransparency = 0.4 end end)
				shade1Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade1Button.BackgroundTransparency = 0 end end)
				shade2Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,shade2) end end)
				shade2Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade2Button.BackgroundTransparency = 0.4 end end)
				shade2Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade2Button.BackgroundTransparency = 0 end end)
				shade3Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,shade3) end end)
				shade3Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade3Button.BackgroundTransparency = 0.4 end end)
				shade3Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then shade3Button.BackgroundTransparency = 0 end end)
				text1Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,text1) end end)
				text1Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text1Button.BackgroundTransparency = 0.4 end end)
				text1Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text1Button.BackgroundTransparency = 0 end end)
				text2Button.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,text2) end end)
				text2Button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text2Button.BackgroundTransparency = 0.4 end end)
				text2Button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then text2Button.BackgroundTransparency = 0 end end)
				scrollButton.MouseButton1Click:Connect(function() if newMt.Confirm then newMt:Confirm(chosenColor,scroll) end end)
				scrollButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then scrollButton.BackgroundTransparency = 0.4 end end)
				scrollButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then scrollButton.BackgroundTransparency = 0 end end)
				cancelButton.MouseButton1Click:Connect(function() if newMt.Cancel then newMt:Cancel() end end)
				cancelButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then cancelButton.BackgroundTransparency = 0.4 end end)
				cancelButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then cancelButton.BackgroundTransparency = 0 end end)
				defaultButton.MouseButton1Click:Connect(function() if newMt.Default then newMt:Default() end end)
				defaultButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then defaultButton.BackgroundTransparency = 0.4 end end)
				defaultButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then defaultButton.BackgroundTransparency = 0 end end)
				pickerExit.MouseButton1Click:Connect(function()
					picker:TweenPosition(UDim2.new(0.5, -219, 0, -500), "InOut", "Quart", 0.5, true, nil)
				end)
				updateColor()
				newMt.SetColor = function(self,color)
					red,green,blue = color.r,color.g,color.b
					hue,sat,val = Color3.toHSV(color)
					updateColor()
				end
				return newMt
			end
		end
		picker:TweenPosition(UDim2.new(0.5, -219, 0, 100), "InOut", "Quart", 0.5, true, nil)
		local Npicker = ColorPicker.new()
		Npicker.Confirm = function(self,color,ctype) updateColors(color,ctype) wait() updatesaves() end
		Npicker.Cancel = function(self)
			updateColors(cache_currentShade1,shade1)
			updateColors(cache_currentShade2,shade2)
			updateColors(cache_currentShade3,shade3)
			updateColors(cache_currentText1,text1)
			updateColors(cache_currentText2,text2)
			updateColors(cache_currentScroll,scroll)
			wait()
			updatesaves()
		end
		Npicker.Default = function(self)
			updateColors(Color3.fromRGB(10, 10, 10),shade1)
			updateColors(Color3.fromRGB(0, 0, 0),shade2)
			updateColors(Color3.fromRGB(78, 78, 79),shade3)
			updateColors(Color3.new(1, 1, 1),text1)
			updateColors(Color3.new(0, 0, 0),text2)
			updateColors(Color3.fromRGB(78,78,79),scroll)
			wait()
			updatesaves()
		end
	else
		picker:TweenPosition(UDim2.new(0.5, -219, 0, 100), "InOut", "Quart", 0.5, true, nil)
	end
end)
SettingsButton.MouseButton1Click:Connect(function()
	if SettingsOpen == false then SettingsOpen = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.5, true, nil)
		CMDsF.Visible = false
	else SettingsOpen = false
		CMDsF.Visible = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 220), "InOut", "Quart", 0.5, true, nil)
	end
end)
On.MouseButton1Click:Connect(function()
	if isHidden == false then
		if StayOpen == false then
			StayOpen = true
			On.BackgroundTransparency = 0
		else
			StayOpen = false
			On.BackgroundTransparency = 1
		end
		updatesaves()
	end
end)
Clear.MouseButton1Down:Connect(function()
	for _, child in pairs(scroll_2:GetChildren()) do
		child:Destroy()
	end
	scroll_2.CanvasSize = UDim2.new(0, 0, 0, 10)
end)
Clear_2.MouseButton1Down:Connect(function()
	for _, child in pairs(scroll_3:GetChildren()) do
		child:Destroy()
	end
	scroll_3.CanvasSize = UDim2.new(0, 0, 0, 10)
end)
Toggle.MouseButton1Down:Connect(function()
	if logsEnabled then
		logsEnabled = false
		Toggle.Text = 'Disabled'
		updatesaves()
	else
		logsEnabled = true
		Toggle.Text = 'Enabled'
		updatesaves()
	end
end)
Toggle_2.MouseButton1Down:Connect(function()
	if jLogsEnabled then
		jLogsEnabled = false
		Toggle_2.Text = 'Disabled'
		updatesaves()
	else
		jLogsEnabled = true
		Toggle_2.Text = 'Enabled'
		updatesaves()
	end
end)
selectChat.MouseButton1Down:Connect(function()
	join.Visible = false
	chat.Visible = true
	table.remove(shade3,table.find(shade3,selectChat))
	table.remove(shade2,table.find(shade2,selectJoin))
	table.insert(shade2,selectChat)
	table.insert(shade3,selectJoin)
	selectJoin.BackgroundColor3 = currentShade3
	selectChat.BackgroundColor3 = currentShade2
end)
selectJoin.MouseButton1Down:Connect(function()
	chat.Visible = false
	join.Visible = true
	table.remove(shade3,table.find(shade3,selectJoin))
	table.remove(shade2,table.find(shade2,selectChat))
	table.insert(shade2,selectJoin)
	table.insert(shade3,selectChat)
	selectChat.BackgroundColor3 = currentShade3
	selectJoin.BackgroundColor3 = currentShade2
end)
if not writefileExploit() then
	notify("Saves", "Your exploit does not support read/write file. Your settings will not save.")
end
avatarcache = {}
function sendChatWebhook(player, message)
	if httprequest and vtype(logsWebhook, "string") then
		local id = player.UserId
		local avatar = avatarcache[id]
		if not avatar then
			local d = HttpService:JSONDecode(httprequest({
				Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. id .. "&size=420x420&format=Png&isCircular=false",
				Method = "GET"
			}).Body)["data"]
			avatar = d and d[1].state == "Completed" and d[1].imageUrl or "https://files.catbox.moe/i968v2.jpg"
			avatarcache[id] = avatar
		end
		local log = HttpService:JSONEncode({
			content = message,
			avatar_url = avatar,
			username = formatUsername(player),
			allowed_mentions = {parse = {}}
		})
		httprequest({
			Url = logsWebhook,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = log
		})
	end

	if jLogsEnabled == true then
		CreateJoinLabel(plr,plr.UserId)
	end
end
CleanFileName = function(name)
	return tostring(name):gsub("[*\\?:<>|]+", ""):sub(1, 175)
end
SaveChatlogs.MouseButton1Down:Connect(function()
	if writefileExploit() then
		if #scroll_2:GetChildren() > 0 then
			notify("Loading",'Hold on a sec')
			local placeName = CleanFileName(MarketplaceService:GetProductInfo(PlaceId).Name)
			local writelogs = '-- Slate Chat logs for "'..placeName..'"\n'
			for _, child in pairs(scroll_2:GetChildren()) do
				writelogs = writelogs..'\n'..child.Text
			end
			local writelogsFile = tostring(writelogs)
			local fileext = 0
			local function nameFile()
				local file
				pcall(function() file = readfile(placeName..' Chat Logs ('..fileext..').txt') end)
				if file then
					fileext = fileext+1
					nameFile()
				else
					writefileCooldown(placeName..' Chat Logs ('..fileext..').txt', writelogsFile)
				end
			end
			nameFile()
			notify('Chat Logs','Saved chat logs to the workspace folder within your exploit folder.')
		end
	else
		notify('Chat Logs','Your exploit does not support write file. You cannot save chat logs.')
	end
end)
if isLegacyChat then
	for _, plr in pairs(Players:GetPlayers()) do
		if ChatLog then ChatLog(plr) end
	end
end
Players.PlayerRemoving:Connect(function(player)
	if ESPenabled or CHMSenabled or COREGUI:FindFirstChild(player.Name..'_LC') then
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == player.Name..'_ESP' or v.Name == player.Name..'_LC' or v.Name == player.Name..'_CHMS' then
				v:Destroy()
			end
		end
	end
	if viewing ~= nil and player == viewing then
		workspace.CurrentCamera.CameraSubject = Players.LocalPlayer.Character
		viewing = nil
		if viewDied then
			viewDied:Disconnect()
			viewChanged:Disconnect()
		end
		notify('Spectate','View turned off (player left)')
	end
	eventEditor.FireEvent("OnLeave", player.Name)
end)
Exit.MouseButton1Down:Connect(function()
	logs:TweenPosition(UDim2.new(0, 0, 1, 10), "InOut", "Quart", 0.3, true, nil)
end)
Hide.MouseButton1Down:Connect(function()
	if logs.Position ~= UDim2.new(0, 0, 1, -20) then
		logs:TweenPosition(UDim2.new(0, 0, 1, -20), "InOut", "Quart", 0.3, true, nil)
	else
		logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
	end
end)
EventBind.MouseButton1Click:Connect(function()
	eventEditor.Frame:TweenPosition(UDim2.new(0.5,-175,0.5,-101), "InOut", "Quart", 0.5, true, nil)
end)
Keybinds.MouseButton1Click:Connect(function()
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)
Close.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)
Keybinds.MouseButton1Click:Connect(function()
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)
Add.MouseButton1Click:Connect(function()
	KeybindEditor:TweenPosition(UDim2.new(0.5, -180, 0, 260), "InOut", "Quart", 0.5, true, nil)
end)
Delete.MouseButton1Click:Connect(function()
	binds = {}
	refreshbinds()
	updatesaves()
	notify('Keybinds Updated','Removed all keybinds')
end)
Close_2.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	AliasesFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)
Aliases.MouseButton1Click:Connect(function()
	AliasesFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)
Close_3.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	PositionsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)
Positions.MouseButton1Click:Connect(function()
	PositionsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
end)
local selectionBox = Instance.new("SelectionBox")
selectionBox.Name = randomString()
selectionBox.Color3 = Color3.new(255,255,255)
selectionBox.Adornee = nil
selectionBox.Parent = PARENT
local selected = Instance.new("SelectionBox")
selected.Name = randomString()
selected.Color3 = Color3.new(0,166,0)
selected.Adornee = nil
selected.Parent = PARENT
local ActivateHighlight = nil
local ClickSelect = nil
function selectPart()
	ToPartFrame:TweenPosition(UDim2.new(0.5, -180, 0, 335), "InOut", "Quart", 0.5, true, nil)
	local function HighlightPart()
		if selected.Adornee ~= IYMouse.Target then
			selectionBox.Adornee = IYMouse.Target
		else
			selectionBox.Adornee = nil
		end
	end
	ActivateHighlight = IYMouse.Move:Connect(HighlightPart)
	local function SelectPart()
		if IYMouse.Target ~= nil then
			selected.Adornee = IYMouse.Target
			Path.Text = getHierarchy(IYMouse.Target)
		end
	end
	ClickSelect = IYMouse.Button1Down:Connect(SelectPart)
end
Part.MouseButton1Click:Connect(function()
	selectPart()
end)
Exit_4.MouseButton1Click:Connect(function()
	ToPartFrame:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
	if ActivateHighlight then
		ActivateHighlight:Disconnect()
	end
	if ClickSelect then
		ClickSelect:Disconnect()
	end
	selectionBox.Adornee = nil
	selected.Adornee = nil
	Path.Text = ""
end)
CopyPath.MouseButton1Click:Connect(function()
	if Path.Text ~= "" then
		toClipboard(Path.Text)
	else
		notify('Copy Path','Select a part to copy its path')
	end
end)
ChoosePart.MouseButton1Click:Connect(function()
	if Path.Text ~= "" then
		local tpNameExt = ''
		local function handleWpNames()
			local FoundDupe = false
			for i,v in pairs(pWayPoints) do
				if v.NAME:lower() == selected.Adornee.Name:lower()..tpNameExt then
					FoundDupe = true
				end
			end
			if not FoundDupe then
				notify('Modified Waypoints',"Created waypoint: "..selected.Adornee.Name..tpNameExt)
				pWayPoints[#pWayPoints + 1] = {NAME = selected.Adornee.Name..tpNameExt, COORD = {selected.Adornee}}
			else
				if isNumber(tpNameExt) then
					tpNameExt = tpNameExt+1
				else
					tpNameExt = 1
				end
				handleWpNames()
			end
		end
		handleWpNames()
		refreshwaypoints()
	else
		notify('Part Selection','Select a part first')
	end
end)
cmds={}
customAlias = {}
Delete_3.MouseButton1Click:Connect(function()
	customAlias = {}
	aliases = {}
	notify('Aliases Modified','Removed all aliases')
	updatesaves()
	refreshaliases()
end)
PrefixBox:GetPropertyChangedSignal("Text"):Connect(function()
	prefix = PrefixBox.Text
	Cmdbar.PlaceholderText = "Command Bar ("..prefix..")"
	updatesaves()
end)
function CamViewport()
	if workspace.CurrentCamera then
		return workspace.CurrentCamera.ViewportSize.X
	end
end
function UpdateToViewport()
	if Holder.Position.X.Offset < -CamViewport() then
		Holder:TweenPosition(UDim2.new(1, -CamViewport(), Holder.Position.Y.Scale, Holder.Position.Y.Offset), "InOut", "Quart", 0.04, true, nil)
		Notification:TweenPosition(UDim2.new(1, -CamViewport() + 250, Notification.Position.Y.Scale, Notification.Position.Y.Offset), "InOut", "Quart", 0.04, true, nil)
	end
end
CameraChanged = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateToViewport)
function updateCamera(child, parent)
	if parent ~= workspace then
		CamMoved:Disconnect()
		CameraChanged:Disconnect()
		repeat wait() until workspace.CurrentCamera
		CameraChanged = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateToViewport)
		CamMoved = workspace.CurrentCamera.AncestryChanged:Connect(updateCamera)
	end
end
CamMoved = workspace.CurrentCamera.AncestryChanged:Connect(updateCamera)
function dragMain(dragpoint,gui)
	task.spawn(function()
		local dragging
		local dragInput
		local dragStart = Vector3.new(0,0,0)
		local startPos
		local function update(input)
			local pos = -250
			local delta = input.Position - dragStart
			if startPos.X.Offset + delta.X <= -500 then
				local Position = UDim2.new(1, -250, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position}):Play()
				pos = 250
			else
				local Position = UDim2.new(1, -500, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position}):Play()
				pos = -250
			end
			if startPos.X.Offset + delta.X <= -250 and -CamViewport() <= startPos.X.Offset + delta.X then
				local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, gui.Position.Y.Scale, gui.Position.Y.Offset)
				TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
				local Position2 = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X + pos, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position2}):Play()
			elseif startPos.X.Offset + delta.X > -500 then
				local Position = UDim2.new(1, -250, gui.Position.Y.Scale, gui.Position.Y.Offset)
				TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
			elseif -CamViewport() > startPos.X.Offset + delta.X then
				gui:TweenPosition(UDim2.new(1, -CamViewport(), gui.Position.Y.Scale, gui.Position.Y.Offset), "InOut", "Quart", 0.04, true, nil)
				local Position = UDim2.new(1, -CamViewport(), gui.Position.Y.Scale, gui.Position.Y.Offset)
				TweenService:Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
				local Position2 = UDim2.new(1, -CamViewport() + 250, Notification.Position.Y.Scale, Notification.Position.Y.Offset)
				TweenService:Create(Notification, TweenInfo.new(.20), {Position = Position2}):Play()
			end
		end
		dragpoint.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		dragpoint.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end)
end
dragMain(Title,Holder)
Match = function(name,str)
	str = str:gsub("%W", "%%%1")
	return name:lower():find(str:lower()) and true
end
local canvasPos = Vector2.new(0,0)
local topCommand = nil
IndexContents = function(str,bool,cmdbar,Ianim)
	CMDsF.CanvasPosition = Vector2.new(0,0)
	local SizeY = 0
	local indexnum = 0
	local frame = CMDsF
	topCommand = nil
	local chunks = {}
	if str:sub(#str,#str) == "\\" then str = "" end
	for w in string.gmatch(str,"[^\\]+") do
		table.insert(chunks,w)
	end
	if #chunks > 0 then str = chunks[#chunks] end
	if str:sub(1,1) == "!" then str = str:sub(2) end
	for i,v in next, frame:GetChildren() do
		if v:IsA("TextButton") then
			if bool then
				if Match(v.Text,str) then
					indexnum = indexnum + 1
					v.Visible = true
					if topCommand == nil then
						topCommand = v.Text
					end
				else
					v.Visible = false
				end
			else
				v.Visible = true
				if topCommand == nil then
					topCommand = v.Text
				end
			end
		end
	end
	frame.CanvasSize = UDim2.new(0,0,0,cmdListLayout.AbsoluteContentSize.Y)
	if not Ianim then
		if indexnum == 0 or string.find(str, " ") then
			if not cmdbar then
				minimizeHolder()
			elseif cmdbar then
				cmdbarHolder()
			end
		else
			maximizeHolder()
		end
	else
		minimizeHolder()
	end
end
task.spawn(function()
	if not isLegacyChat then return end
	local chatbox
	local success, result = pcall(function() chatbox = PlayerGui:WaitForChild("Chat").Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar end)
	if success then
		local function chatboxFocused()
			canvasPos = CMDsF.CanvasPosition
		end
		local chatboxFocusedC = chatbox.Focused:Connect(chatboxFocused)
		local function Index()
			if chatbox.Text:lower():sub(1,1) == prefix then
				if SettingsOpen == true then
					wait(0.2)
					CMDsF.Visible = true
					Settings:TweenPosition(UDim2.new(0, 0, 0, 220), "InOut", "Quart", 0.2, true, nil)
				end
				IndexContents(PlayerGui.Chat.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar.Text:lower():sub(2),true)
			else
				minimizeHolder()
				if SettingsOpen == true then
					wait(0.2)
					Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.2, true, nil)
					CMDsF.Visible = false
				end
			end
		end
		local chatboxFunc = chatbox:GetPropertyChangedSignal("Text"):Connect(Index)
		local function chatboxFocusLost(enterpressed)
			if not enterpressed or chatbox.Text:lower():sub(1,1) ~= prefix then
				IndexContents('',true)
			end
			CMDsF.CanvasPosition = canvasPos
			minimizeHolder()
		end
		local chatboxFocusLostC = chatbox.FocusLost:Connect(chatboxFocusLost)
		PlayerGui:WaitForChild("Chat").Frame.ChatBarParentFrame.ChildAdded:Connect(function(newbar)
			wait()
			if newbar:FindFirstChild('BoxFrame') then
				chatbox = PlayerGui:WaitForChild("Chat").Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar
				if chatboxFocusedC then chatboxFocusedC:Disconnect() end
				chatboxFocusedC = chatbox.Focused:Connect(chatboxFocused)
				if chatboxFunc then chatboxFunc:Disconnect() end
				chatboxFunc = chatbox:GetPropertyChangedSignal("Text"):Connect(Index)
				if chatboxFocusLostC then chatboxFocusLostC:Disconnect() end
				chatboxFocusLostC = chatbox.FocusLost:Connect(chatboxFocusLost)
			end
		end)
	end
end)
function autoComplete(str,curText)
	local endingChar = {"[", "/", "(", " "}
	local stop = 0
	for i=1,#str do
		local c = str:sub(i,i)
		if table.find(endingChar, c) then
			stop = i
			break
		end
	end
	curText = curText or Cmdbar.Text
	local subPos = 0
	local pos = 1
	local findRes = string.find(curText,"\\",pos)
	while findRes do
		subPos = findRes
		pos = findRes+1
		findRes = string.find(curText,"\\",pos)
	end
	if curText:sub(subPos+1,subPos+1) == "!" then subPos = subPos + 1 end
	Cmdbar.Text = curText:sub(1,subPos) .. str:sub(1, stop - 1)..' '
	RunService.RenderStepped:Wait()
	Cmdbar.Text = Cmdbar.Text:gsub( '\t', '' )
	Cmdbar.CursorPosition = #Cmdbar.Text+1
end
CMDs = {}
CMDs[#CMDs + 1] = {NAME = 'discord / support / help', DESC = 'Invite to the Slate discord server.'}
CMDs[#CMDs + 1] = {NAME = 'guiscale [number]', DESC = 'Changes the size of the gui. [number] accepts both decimals and whole numbers. Min is 0.4 and Max is 2'}
CMDs[#CMDs + 1] = {NAME = 'console', DESC = 'Loads Roblox console'}
CMDs[#CMDs + 1] = {NAME = 'oldconsole', DESC = 'Loads old Roblox console'}
CMDs[#CMDs + 1] = {NAME = 'explorer / dex', DESC = 'Opens DEX by Moon'}
CMDs[#CMDs + 1] = {NAME = 'olddex / odex', DESC = 'Opens Old DEX by Moon'}
CMDs[#CMDs + 1] = {NAME = 'remotespy / rspy', DESC = 'Opens Simple Spy V3'}
CMDs[#CMDs + 1] = {NAME = 'executor', DESC = 'Opens an internal executor gui by dnezero'}
CMDs[#CMDs + 1] = {NAME = 'audiologger / alogger', DESC = 'Opens Edges audio logger'}
CMDs[#CMDs + 1] = {NAME = 'serverinfo / info', DESC = 'Gives you info about the server'}
CMDs[#CMDs + 1] = {NAME = 'jobid', DESC = 'Copies the games JobId to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'notifyjobid', DESC = 'Notifies you the games JobId'}
CMDs[#CMDs + 1] = {NAME = 'rejoin / rj', DESC = 'Makes you rejoin the game'}
CMDs[#CMDs + 1] = {NAME = 'autorejoin / autorj', DESC = 'Automatically rejoins the server if you get kicked/disconnected'}
CMDs[#CMDs + 1] = {NAME = 'serverhop / shop', DESC = 'Teleports you to a different server'}
CMDs[#CMDs + 1] = {NAME = 'gameteleport / gametp [place ID]', DESC = 'Joins a game by ID'}
CMDs[#CMDs + 1] = {NAME = 'antiidle / antiafk', DESC = 'Prevents the game from kicking you for being idle/afk'}
CMDs[#CMDs + 1] = {NAME = 'datalimit [num]', DESC = 'Set outgoing KBPS limit'}
CMDs[#CMDs + 1] = {NAME = 'replicationlag / backtrack [num]', DESC = 'Set IncomingReplicationLag'}
CMDs[#CMDs + 1] = {NAME = 'creatorid / creator', DESC = 'Notifies you the creators ID'}
CMDs[#CMDs + 1] = {NAME = 'copycreatorid / copycreator', DESC = 'Copies the creators ID to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'setcreatorid / setcreator', DESC = 'Sets your userid to the creators ID'}
CMDs[#CMDs + 1] = {NAME = 'noprompts', DESC = 'Prevents the game from showing you purchase/premium prompts'}
CMDs[#CMDs + 1] = {NAME = 'showprompts', DESC = 'Allows the game to show purchase/premium prompts again'}
CMDs[#CMDs + 1] = {NAME = 'enable [inventory/playerlist/chat/reset/emotes/all]', DESC = 'Toggles visibility of coregui items'}
CMDs[#CMDs + 1] = {NAME = 'disable [inventory/playerlist/chat/reset/emotes/all]', DESC = 'Toggles visibility of coregui items'}
CMDs[#CMDs + 1] = {NAME = 'showguis', DESC = 'Shows any invisible GUIs'}
CMDs[#CMDs + 1] = {NAME = 'unshowguis', DESC = 'Undoes showguis'}
CMDs[#CMDs + 1] = {NAME = 'hideguis', DESC = 'Hides any GUIs in PlayerGui'}
CMDs[#CMDs + 1] = {NAME = 'unhideguis', DESC = 'Undoes hideguis'}
CMDs[#CMDs + 1] = {NAME = 'guidelete', DESC = 'Enables backspace to delete GUI'}
CMDs[#CMDs + 1] = {NAME = 'unguidelete / noguidelete', DESC = 'Disables guidelete'}
CMDs[#CMDs + 1] = {NAME = 'hideiy', DESC = 'Hides the main IY GUI'}
CMDs[#CMDs + 1] = {NAME = 'showiy / unhideiy', DESC = 'Shows IY again'}
CMDs[#CMDs + 1] = {NAME = 'keepiy', DESC = 'Auto execute IY when you teleport through servers'}
CMDs[#CMDs + 1] = {NAME = 'unkeepiy', DESC = 'Disable keepiy'}
CMDs[#CMDs + 1] = {NAME = 'togglekeepiy', DESC = 'Toggles keepiy'}
CMDs[#CMDs + 1] = {NAME = 'removeads / adblock', DESC = 'Automatically removes ad billboards'}
CMDs[#CMDs + 1] = {NAME = 'savegame / saveplace', DESC = 'Uses saveinstance to save the game'}
CMDs[#CMDs + 1] = {NAME = 'clearerror', DESC = 'Clears the annoying box and blur when a game kicks you'}
CMDs[#CMDs + 1] = {NAME = 'antigameplaypaused', DESC = 'Clears the annoying box shown when a game is loading assets due to network lag'}
CMDs[#CMDs + 1] = {NAME = 'unantigameplaypaused', DESC = 'Disables antigameplaypaused'}
CMDs[#CMDs + 1] = {NAME = 'clientantikick / antikick (CLIENT)', DESC = 'Prevents localscripts from kicking you'}
CMDs[#CMDs + 1] = {NAME = 'clientantiteleport / antiteleport (CLIENT)', DESC = 'Prevents localscripts from teleporting you'}
CMDs[#CMDs + 1] = {NAME = 'allowrejoin / allowrj [true/false] (CLIENT)', DESC = 'Changes if antiteleport allows you to rejoin or not'}
CMDs[#CMDs + 1] = {NAME = 'cancelteleport / canceltp', DESC = 'Cancels teleports in progress'}
CMDs[#CMDs + 1] = {NAME = 'volume / vol [0-10]', DESC = 'Adjusts your game volume on a scale of 0 to 10'}
CMDs[#CMDs + 1] = {NAME = 'antilag / boostfps / lowgraphics', DESC = 'Lowers game quality to boost FPS'}
CMDs[#CMDs + 1] = {NAME = 'record / rec', DESC = 'Starts Roblox recorder'}
CMDs[#CMDs + 1] = {NAME = 'screenshot / scrnshot', DESC = 'Takes a screenshot'}
CMDs[#CMDs + 1] = {NAME = 'togglefullscreen / togglefs', DESC = 'Toggles fullscreen'}
CMDs[#CMDs + 1] = {NAME = 'notify [text]', DESC = 'Sends you a notification with the provided text'}
CMDs[#CMDs + 1] = {NAME = 'lastcommand / lastcmd', DESC = 'Executes the previous command used'}
CMDs[#CMDs + 1] = {NAME = 'notifyping / ping', DESC = 'Notify yourself your ping'}
CMDs[#CMDs + 1] = {NAME = 'norender', DESC = 'Disable 3d Rendering to decrease the amount of CPU the client uses'}
CMDs[#CMDs + 1] = {NAME = 'render', DESC = 'Enable 3d Rendering'}
CMDs[#CMDs + 1] = {NAME = 'use2022materials / 2022materials', DESC = 'Enables 2022 material textures'}
CMDs[#CMDs + 1] = {NAME = 'unuse2022materials / un2022materials', DESC = 'Disables 2022 material textures'}
CMDs[#CMDs + 1] = {NAME = 'alignmentkeys', DESC = 'Enables the left and right alignment keys (comma and period)'}
CMDs[#CMDs + 1] = {NAME = 'unalignmentkeys / noalignmentkeys', DESC = 'Disables the alignment keys'}
CMDs[#CMDs + 1] = {NAME = 'ctrllock', DESC = 'Binds Shiftlock to LeftControl'}
CMDs[#CMDs + 1] = {NAME = 'unctrllock', DESC = 'Re-binds Shiftlock to LeftShift'}
CMDs[#CMDs + 1] = {NAME = 'exit', DESC = 'Kills roblox process'}
CMDs[#CMDs + 1] = {NAME = 'removecmd / deletecmd', DESC = 'Removes a command until the script is reloaded'}
CMDs[#CMDs + 1] = {NAME = 'breakloops / break (cmd loops)', DESC = 'Stops any cmd loops (;100^1^cmd)'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'noclip', DESC = 'Go through objects'}
CMDs[#CMDs + 1] = {NAME = 'unnoclip / clip', DESC = 'Disables noclip'}
CMDs[#CMDs + 1] = {NAME = 'fly [speed]', DESC = 'Makes you fly'}
CMDs[#CMDs + 1] = {NAME = 'unfly', DESC = 'Disables fly'}
CMDs[#CMDs + 1] = {NAME = 'flyspeed [num]', DESC = 'Set fly speed (default is 20)'}
CMDs[#CMDs + 1] = {NAME = 'vehiclefly / vfly [speed]', DESC = 'Makes you fly in a vehicle'}
CMDs[#CMDs + 1] = {NAME = 'unvehiclefly / unvfly', DESC = 'Disables vehicle fly'}
CMDs[#CMDs + 1] = {NAME = 'vehicleflyspeed  / vflyspeed [num]', DESC = 'Set vehicle fly speed'}
CMDs[#CMDs + 1] = {NAME = 'cframefly / cfly [speed]', DESC = 'Makes you fly, bypassing some anti cheats (works on mobile)'}
CMDs[#CMDs + 1] = {NAME = 'uncframefly / uncfly', DESC = 'Disables cfly'}
CMDs[#CMDs + 1] = {NAME = 'cframeflyspeed  / cflyspeed [num]', DESC = 'Sets cfly speed'}
CMDs[#CMDs + 1] = {NAME = 'qefly [true / false]', DESC = 'Enables or disables the Q and E hotkeys for fly'}
CMDs[#CMDs + 1] = {NAME = 'vehiclenoclip / vnoclip', DESC = 'Turns off vehicle collision'}
CMDs[#CMDs + 1] = {NAME = 'vehicleclip / vclip / unvnoclip', DESC = 'Enables vehicle collision'}
CMDs[#CMDs + 1] = {NAME = 'float /  platform', DESC = 'Spawns a platform beneath you causing you to float'}
CMDs[#CMDs + 1] = {NAME = 'unfloat / noplatform', DESC = 'Removes the platform'}
CMDs[#CMDs + 1] = {NAME = 'swim', DESC = 'Allows you to swim in the air'}
CMDs[#CMDs + 1] = {NAME = 'unswim / noswim', DESC = 'Stops you from swimming everywhere'}
CMDs[#CMDs + 1] = {NAME = 'toggleswim', DESC = 'Toggles swimming'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'setwaypoint / swp [name]', DESC = 'Sets a waypoint at your position'}
CMDs[#CMDs + 1] = {NAME = 'waypointpos / wpp [name] [X Y Z]', DESC = 'Sets a waypoint with specified coordinates'}
CMDs[#CMDs + 1] = {NAME = 'waypoints', DESC = 'Shows a list of currently active waypoints'}
CMDs[#CMDs + 1] = {NAME = 'showwaypoints / showwp', DESC = 'Shows all currently set waypoints'}
CMDs[#CMDs + 1] = {NAME = 'hidewaypoints / hidewp', DESC = 'Hides shown waypoints'}
CMDs[#CMDs + 1] = {NAME = 'waypoint / wp [name]', DESC = 'Teleports player to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'tweenwaypoint / twp [name]', DESC = 'Tweens player to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'walktowaypoint / wtwp [name]', DESC = 'Walks player to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'deletewaypoint / dwp [name]', DESC = 'Deletes a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'clearwaypoints / cwp', DESC = 'Clears all waypoints'}
CMDs[#CMDs + 1] = {NAME = 'cleargamewaypoints / cgamewp', DESC = 'Clears all waypoints for the game you are in'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'goto [player]', DESC = 'Go to a player'}
CMDs[#CMDs + 1] = {NAME = 'tweengoto / tgoto [player]', DESC = 'Tween to a player (bypasses some anti cheats)'}
CMDs[#CMDs + 1] = {NAME = 'tweenspeed / tspeed [num]', DESC = 'Sets how fast all tween commands go (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'vehiclegoto / vgoto [player]', DESC = 'Go to a player while in a vehicle'}
CMDs[#CMDs + 1] = {NAME = 'loopgoto [player] [distance] [delay]', DESC = 'Loop teleport to a player'}
CMDs[#CMDs + 1] = {NAME = 'unloopgoto', DESC = 'Stops teleporting you to a player'}
CMDs[#CMDs + 1] = {NAME = 'pulsetp / ptp [player] [seconds]', DESC = 'Teleports you to a player for a specified amount of time'}
CMDs[#CMDs + 1] = {NAME = 'clientbring / cbring [player] (CLIENT)', DESC = 'Bring a player'}
CMDs[#CMDs + 1] = {NAME = 'loopbring [player] [distance] [delay] (CLIENT)', DESC = 'Loop brings a player to you (useful for killing)'}
CMDs[#CMDs + 1] = {NAME = 'unloopbring [player]', DESC = 'Undoes loopbring'}
CMDs[#CMDs + 1] = {NAME = 'freeze / fr [player] (CLIENT)', DESC = 'Freezes a player'}
CMDs[#CMDs + 1] = {NAME = 'freezeanims', DESC = 'Freezes your animations / pauses your animations - Does not work on default animations'}
CMDs[#CMDs + 1] = {NAME = 'unfreezeanims', DESC = 'Unfreezes your animations / plays your animations'}
CMDs[#CMDs + 1] = {NAME = 'thaw / unfr [player] (CLIENT)', DESC = 'Unfreezes a player'}
CMDs[#CMDs + 1] = {NAME = 'anchor', DESC = 'Anchors your characters RootPart'}
CMDs[#CMDs + 1] = {NAME = 'unanchor', DESC = 'Unanchors your characters RootPart'}
CMDs[#CMDs + 1] = {NAME = 'tpposition / tppos [X Y Z]', DESC = 'Teleports you to certain coordinates'}
CMDs[#CMDs + 1] = {NAME = 'tweentpposition / ttppos [X Y Z]', DESC = 'Tween to coordinates (bypasses some anti cheats)'}
CMDs[#CMDs + 1] = {NAME = 'offset [X Y Z]', DESC = 'Offsets you by certain coordinates'}
CMDs[#CMDs + 1] = {NAME = 'tweenoffset / toffset [X Y Z]', DESC = 'Tween offset (bypasses some anti cheats)'}
CMDs[#CMDs + 1] = {NAME = 'thru [num]', DESC = 'Teleports you [num] studs ahead of where your character is facing'}
CMDs[#CMDs + 1] = {NAME = 'notifyposition / notifypos [player]', DESC = 'Notifies you the coordinates of a character'}
CMDs[#CMDs + 1] = {NAME = 'copyposition / copypos [player]', DESC = 'Copies the coordinates of a character to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'walktoposition / walktopos [X Y Z]', DESC = 'Makes you walk to a coordinate'}
CMDs[#CMDs + 1] = {NAME = 'spawnpoint / spawn [delay]', DESC = 'Sets a position where you will spawn'}
CMDs[#CMDs + 1] = {NAME = 'nospawnpoint / nospawn', DESC = 'Removes your custom spawn point'}
CMDs[#CMDs + 1] = {NAME = 'flashback / diedtp', DESC = 'Teleports you to where you last died'}
CMDs[#CMDs + 1] = {NAME = 'walltp', DESC = 'Teleports you above/over any wall you run into'}
CMDs[#CMDs + 1] = {NAME = 'nowalltp / unwalltp', DESC = 'Disables walltp'}
CMDs[#CMDs + 1] = {NAME = 'teleporttool / tptool', DESC = 'Gives you a teleport tool'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'logs', DESC = 'Opens the logs GUI'}
CMDs[#CMDs + 1] = {NAME = 'chatlogs / clogs', DESC = 'Log what people say or whisper'}
CMDs[#CMDs + 1] = {NAME = 'joinlogs / jlogs', DESC = 'Log when people join'}
CMDs[#CMDs + 1] = {NAME = 'chatlogswebhook / logswebhook [url]', DESC = 'Set a discord webhook for chatlogs to go to (provide no url to disable this)'}
CMDs[#CMDs + 1] = {NAME = 'chat / say [text]', DESC = 'Makes you chat a string (possible mute bypass)'}
CMDs[#CMDs + 1] = {NAME = 'spam [text]', DESC = 'Makes you spam the chat'}
CMDs[#CMDs + 1] = {NAME = 'unspam', DESC = 'Turns off spam'}
CMDs[#CMDs + 1] = {NAME = 'whisper / pm [player] [text]', DESC = 'Makes you whisper a string to someone (possible mute bypass)'}
CMDs[#CMDs + 1] = {NAME = 'pmspam [player] [text]', DESC = 'Makes you spam a players whispers'}
CMDs[#CMDs + 1] = {NAME = 'unpmspam [player]', DESC = 'Turns off pm spam'}
CMDs[#CMDs + 1] = {NAME = 'spamspeed [num]', DESC = 'How quickly you spam (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'bubblechat (CLIENT)', DESC = 'Enables bubble chat for your client'}
CMDs[#CMDs + 1] = {NAME = 'unbubblechat / nobubblechat', DESC = 'Disables the bubblechat command'}
CMDs[#CMDs + 1] = {NAME = 'chatwindow', DESC = 'Enables the chat window for your client'}
CMDs[#CMDs + 1] = {NAME = 'unchatwindow / nochatwindow', DESC = 'Disables the chat window for your client'}
CMDs[#CMDs + 1] = {NAME = 'darkchat', DESC = 'Makes the chat window dark for your client'}
CMDs[#CMDs + 1] = {NAME = 'listento [player]', DESC = 'Listens to the area around a player. Can also eavesdrop with vc'}
CMDs[#CMDs + 1] = {NAME = 'unlistento', DESC = 'Disables listento'}
CMDs[#CMDs + 1] = {NAME = 'muteallvoices / muteallvcs', DESC = 'Mutes voice chat for all players'}
CMDs[#CMDs + 1] = {NAME = 'unmuteallvoices / unmuteallvcs', DESC = 'Unmutes voice chat for all players'}
CMDs[#CMDs + 1] = {NAME = 'mutevc [player]', DESC = 'Mutes the voice chat of a player'}
CMDs[#CMDs + 1] = {NAME = 'unmutevc [player]', DESC = 'Unmutes the voice chat of a player'}
CMDs[#CMDs + 1] = {NAME = 'phonebook / call', DESC = 'Prompts the Roblox phonebook UI to let you call your friends. Needs voice chat enabled'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'esp', DESC = 'View all players and their status'}
CMDs[#CMDs + 1] = {NAME = 'espteam', DESC = 'ESP but teammates are green and bad guys are red'}
CMDs[#CMDs + 1] = {NAME = 'noesp / unesp / unespteam', DESC = 'Removes ESP'}
CMDs[#CMDs + 1] = {NAME = 'esptransparency [number]', DESC = 'Changes the transparency of ESP related commands'}
CMDs[#CMDs + 1] = {NAME = 'partesp [part name]', DESC = 'Highlights a part'}
CMDs[#CMDs + 1] = {NAME = 'unpartesp / nopartesp [part name]', DESC = 'removes partesp'}
CMDs[#CMDs + 1] = {NAME = 'chams', DESC = 'ESP but without text in the way'}
CMDs[#CMDs + 1] = {NAME = 'nochams / unchams', DESC = 'Removes chams'}
CMDs[#CMDs + 1] = {NAME = 'locate [player]', DESC = 'View a single player and their status'}
CMDs[#CMDs + 1] = {NAME = 'unlocate / nolocate [player]', DESC = 'Removes locate'}
CMDs[#CMDs + 1] = {NAME = 'xray', DESC = 'Makes all parts in workspace transparent'}
CMDs[#CMDs + 1] = {NAME = 'unxray / noxray', DESC = 'Restores transparency to all parts in workspace'}
CMDs[#CMDs + 1] = {NAME = 'loopxray', DESC = 'Makes all parts in workspace transparent but looped'}
CMDs[#CMDs + 1] = {NAME = 'unloopxray', DESC = 'Unloops xray'}
CMDs[#CMDs + 1] = {NAME = 'togglexray', DESC = 'Toggles xray'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'spectate / view [player]', DESC = 'View a player'}
CMDs[#CMDs + 1] = {NAME = 'viewpart / viewp [part name]', DESC = 'View a part'}
CMDs[#CMDs + 1] = {NAME = 'unspectate / unview', DESC = 'Stops viewing player'}
CMDs[#CMDs + 1] = {NAME = 'freecam / fc', DESC = 'Allows you to freely move camera around the game'}
CMDs[#CMDs + 1] = {NAME = 'freecampos / fcpos [X Y Z]', DESC = 'Moves / opens freecam in a certain position'}
CMDs[#CMDs + 1] = {NAME = 'freecamwaypoint / fcwp [name]', DESC = 'Moves / opens freecam to a waypoint'}
CMDs[#CMDs + 1] = {NAME = 'freecamgoto / fcgoto / fctp [player]', DESC = 'Moves / opens freecam to a player'}
CMDs[#CMDs + 1] = {NAME = 'unfreecam / unfc', DESC = 'Disables freecam'}
CMDs[#CMDs + 1] = {NAME = 'freecamspeed / fcspeed [num]', DESC = 'Adjusts freecam speed (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'notifyfreecamposition / notifyfcpos', DESC = 'Noitifies you your freecam coordinates'}
CMDs[#CMDs + 1] = {NAME = 'copyfreecamposition / copyfcpos', DESC = 'Copies your freecam coordinates to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'gotocamera / gotocam', DESC = 'Teleports you to the location of your camera'}
CMDs[#CMDs + 1] = {NAME = 'tweengotocam / tgotocam', DESC = 'Tweens you to the location of your camera'}
CMDs[#CMDs + 1] = {NAME = 'firstp', DESC = 'Forces camera to go into first person'}
CMDs[#CMDs + 1] = {NAME = 'thirdp', DESC = 'Allows camera to go into third person'}
CMDs[#CMDs + 1] = {NAME = 'noclipcam / nccam', DESC = 'Allows camera to go through objects like walls'}
CMDs[#CMDs + 1] = {NAME = 'maxzoom [num]', DESC = 'Maximum camera zoom'}
CMDs[#CMDs + 1] = {NAME = 'minzoom [num]', DESC = 'Minimum camera zoom'}
CMDs[#CMDs + 1] = {NAME = 'camdistance [num]', DESC = 'Changes camera distance from your player'}
CMDs[#CMDs + 1] = {NAME = 'fov [num]', DESC = 'Adjusts field of view (default is 70)'}
CMDs[#CMDs + 1] = {NAME = 'fixcam / restorecam', DESC = 'Fixes camera'}
CMDs[#CMDs + 1] = {NAME = 'enableshiftlock / enablesl', DESC = 'Enables the shift lock option'}
CMDs[#CMDs + 1] = {NAME = 'lookat [player]', DESC = 'Moves your camera view to a player'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'btools (CLIENT)', DESC = 'Gives you building tools (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'f3x (CLIENT)', DESC = 'Gives you F3X building tools (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'partname / partpath', DESC = 'Allows you to click a part to see its path & name'}
CMDs[#CMDs + 1] = {NAME = 'delete [instance name] (CLIENT)', DESC = 'Removes any part with a certain name from the workspace (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'deleteclass / dc [class name] (CLIENT)', DESC = 'Removes any part with a certain classname from the workspace (DOES NOT REPLICATE)'}
CMDs[#CMDs + 1] = {NAME = 'lockworkspace / lockws', DESC = 'Locks the whole workspace'}
CMDs[#CMDs + 1] = {NAME = 'unlockworkspace / unlockws', DESC = 'Unlocks the whole workspace'}
CMDs[#CMDs + 1] = {NAME = 'invisibleparts / invisparts (CLIENT)', DESC = 'Shows invisible parts'}
CMDs[#CMDs + 1] = {NAME = 'uninvisibleparts / uninvisparts (CLIENT)', DESC = 'Makes parts affected by invisparts return to normal'}
CMDs[#CMDs + 1] = {NAME = 'deleteinvisparts / dip (CLIENT)', DESC = 'Deletes invisible parts'}
CMDs[#CMDs + 1] = {NAME = 'gotopart [part name]', DESC = 'Moves your character to a part or multiple parts'}
CMDs[#CMDs + 1] = {NAME = 'tweengotopart / tgotopart [part name]', DESC = 'Tweens your character to a part or multiple parts'}
CMDs[#CMDs + 1] = {NAME = 'gotopartclass / gpc [class name]', DESC = 'Moves your character to a part or multiple parts based on classname'}
CMDs[#CMDs + 1] = {NAME = 'tweengotopartclass / tgpc [class name]', DESC = 'Tweens your character to a part or multiple parts based on classname'}
CMDs[#CMDs + 1] = {NAME = 'gotomodel [part name]', DESC = 'Moves your character to a model or multiple models'}
CMDs[#CMDs + 1] = {NAME = 'tweengotomodel / tgotomodel [part name]', DESC = 'Tweens your character to a model or multiple models'}
CMDs[#CMDs + 1] = {NAME = 'gotopartdelay / gotomodeldelay [num]', DESC = 'Adjusts how quickly you teleport to each part (default is 0.1)'}
CMDs[#CMDs + 1] = {NAME = 'bringpart [part name] (CLIENT)', DESC = 'Moves a part or multiple parts to your character'}
CMDs[#CMDs + 1] = {NAME = 'bringpartclass / bpc [class name] (CLIENT)', DESC = 'Moves a part or multiple parts to your character based on classname'}
CMDs[#CMDs + 1] = {NAME = 'noclickdetectorlimits / nocdlimits', DESC = 'Sets all click detectors MaxActivationDistance to math.huge'}
CMDs[#CMDs + 1] = {NAME = 'fireclickdetectors / firecd [name]', DESC = 'Uses all click detectors in a game or uses the optional name'}
CMDs[#CMDs + 1] = {NAME = 'firetouchinterests / touchinterests [name]', DESC = 'Uses all touchinterests in a game or uses the optional name'}
CMDs[#CMDs + 1] = {NAME = 'noproximitypromptlimits / nopplimits', DESC = 'Sets all proximity prompts MaxActivationDistance to math.huge'}
CMDs[#CMDs + 1] = {NAME = 'fireproximityprompts / firepp [name]', DESC = 'Uses all proximity prompts in a game or uses the optional name'}
CMDs[#CMDs + 1] = {NAME = 'instantproximityprompts / instantpp', DESC = 'Disable the cooldown for proximity prompts'}
CMDs[#CMDs + 1] = {NAME = 'uninstantproximityprompts / uninstantpp', DESC = 'Undo the cooldown removal'}
CMDs[#CMDs + 1] = {NAME = 'tpunanchored / tpua [player]', DESC = 'Teleports unanchored parts to a player'}
CMDs[#CMDs + 1] = {NAME = 'animsunanchored / freezeua', DESC = 'Freezes unanchored parts'}
CMDs[#CMDs + 1] = {NAME = 'thawunanchored / thawua / unfreezeua', DESC = 'Thaws unanchored parts'}
CMDs[#CMDs + 1] = {NAME = 'removeterrain / rterrain / noterrain', DESC = 'Removes all terrain'}
CMDs[#CMDs + 1] = {NAME = 'clearnilinstances / nonilinstances / cni', DESC = 'Removes nil instances'}
CMDs[#CMDs + 1] = {NAME = 'destroyheight / dh [num]', DESC = 'Sets FallenPartsDestroyHeight'}
CMDs[#CMDs + 1] = {NAME = 'fakeout', DESC = 'Tp to the void and then back (useful to kill people attached to you)'}
CMDs[#CMDs + 1] = {NAME = 'antivoid', DESC = 'Prevents you from falling into the void by launching you upwards'}
CMDs[#CMDs + 1] = {NAME = 'unantivoid / noantivoid', DESC = 'Disables antivoid'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'fullbright / fb (CLIENT)', DESC = 'Makes the map brighter / more visible'}
CMDs[#CMDs + 1] = {NAME = 'loopfullbright / loopfb (CLIENT)', DESC = 'Makes the map brighter / more visible but looped'}
CMDs[#CMDs + 1] = {NAME = 'unloopfullbright / unloopfb', DESC = 'Unloops fullbright'}
CMDs[#CMDs + 1] = {NAME = 'ambient [num] [num] [num] (CLIENT)', DESC = 'Changes ambient'}
CMDs[#CMDs + 1] = {NAME = 'day (CLIENT)', DESC = 'Changes the time to day for the client'}
CMDs[#CMDs + 1] = {NAME = 'night (CLIENT)', DESC = 'Changes the time to night for the client'}
CMDs[#CMDs + 1] = {NAME = 'nofog (CLIENT)', DESC = 'Removes fog'}
CMDs[#CMDs + 1] = {NAME = 'brightness [num] (CLIENT)', DESC = 'Changes the brightness lighting property'}
CMDs[#CMDs + 1] = {NAME = 'globalshadows / gshadows (CLIENT)', DESC = 'Enables global shadows'}
CMDs[#CMDs + 1] = {NAME = 'noglobalshadows / nogshadows (CLIENT)', DESC = 'Disables global shadows'}
CMDs[#CMDs + 1] = {NAME = 'restorelighting / rlighting', DESC = 'Restores Lighting properties'}
CMDs[#CMDs + 1] = {NAME = 'light [radius] [brightness] (CLIENT)', DESC = 'Gives your player dynamic light'}
CMDs[#CMDs + 1] = {NAME = 'nolight / unlight', DESC = 'Removes dynamic light from your player'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'inspect / examine [player]', DESC = 'Opens InspectMenu for a certain player'}
CMDs[#CMDs + 1] = {NAME = 'age [player]', DESC = 'Tells you the age of a player'}
CMDs[#CMDs + 1] = {NAME = 'chatage [player]', DESC = 'Chats the age of a player'}
CMDs[#CMDs + 1] = {NAME = 'joindate / jd [player]', DESC = 'Tells you the date the player joined Roblox'}
CMDs[#CMDs + 1] = {NAME = 'chatjoindate / cjd [player]', DESC = 'Chats the date the player joined Roblox'}
CMDs[#CMDs + 1] = {NAME = 'copyname / copyuser [player]', DESC = 'Copies a players full username to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'userid / id [player]', DESC = 'Notifies a players user ID'}
CMDs[#CMDs + 1] = {NAME = 'copyplaceid / placeid', DESC = 'Copies the current place id to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'copygameid / gameid', DESC = 'Copies the current game id to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'copyuserid / copyid [player]', DESC = 'Copies a players user ID to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'appearanceid / aid [player]', DESC = 'Notifies a players appearance ID'}
CMDs[#CMDs + 1] = {NAME = 'copyappearanceid / caid [player]', DESC = 'Copies a players appearance ID to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'bang [player] [speed]', DESC = 'owo'}
CMDs[#CMDs + 1] = {NAME = 'unbang', DESC = 'uwu'}
CMDs[#CMDs + 1] = {NAME = 'jerk', DESC = 'Makes you jork it'}
CMDs[#CMDs + 1] = {NAME = 'scare / spook [player]', DESC = 'Teleports in front of a player for half a second'}
CMDs[#CMDs + 1] = {NAME = 'carpet [player]', DESC = 'Be someones carpet'}
CMDs[#CMDs + 1] = {NAME = 'uncarpet', DESC = 'Undoes carpet'}
CMDs[#CMDs + 1] = {NAME = 'friend [player]', DESC = 'Sends a friend request to certain players'}
CMDs[#CMDs + 1] = {NAME = 'unfriend [player]', DESC = 'Unfriends certain players'}
CMDs[#CMDs + 1] = {NAME = 'headsit [player]', DESC = 'Sit on a players head'}
CMDs[#CMDs + 1] = {NAME = 'walkto / follow [player]', DESC = 'Follow a player'}
CMDs[#CMDs + 1] = {NAME = 'pathfindwalkto / pathfindfollow [player]', DESC = 'Follow a player using pathfinding'}
CMDs[#CMDs + 1] = {NAME = 'pathfindwalktowaypoint / pathfindwalktowp [waypoint]', DESC = 'Walk to a waypoint using pathfinding'}
CMDs[#CMDs + 1] = {NAME = 'unwalkto / unfollow', DESC = 'Stops following a player'}
CMDs[#CMDs + 1] = {NAME = 'orbit [player] [speed] [distance]', DESC = 'Makes your character orbit around a player with an optional speed and an optional distance'}
CMDs[#CMDs + 1] = {NAME = 'unorbit', DESC = 'Disables orbit'}
CMDs[#CMDs + 1] = {NAME = 'stareat / stare [player]', DESC = 'Stare / look at a player'}
CMDs[#CMDs + 1] = {NAME = 'unstareat / unstare [player]', DESC = 'Disables stareat'}
CMDs[#CMDs + 1] = {NAME = 'rolewatch [group id] [role name]', DESC = 'Notify if someone from a watched group joins the server'}
CMDs[#CMDs + 1] = {NAME = 'rolewatchstop / unrolewatch', DESC = 'Disable Rolewatch'}
CMDs[#CMDs + 1] = {NAME = 'rolewatchleave', DESC = 'Toggle if you should leave the game if someone from a watched group joins the server'}
CMDs[#CMDs + 1] = {NAME = 'staffwatch', DESC = 'Notify if a staff member of the game joins the server'}
CMDs[#CMDs + 1] = {NAME = 'unstaffwatch', DESC = 'Disable Staffwatch'}
CMDs[#CMDs + 1] = {NAME = 'findfriendgroups', DESC = 'Notifies you if any players are friends with each other'}
CMDs[#CMDs + 1] = {NAME = 'handlekill / hkill [player] [radius] (TOOL)', DESC = 'Kills a player using tool damage (YOU NEED A TOOL)'}
CMDs[#CMDs + 1] = {NAME = 'fling', DESC = 'Flings anyone you touch'}
CMDs[#CMDs + 1] = {NAME = 'unfling', DESC = 'Disables the fling command'}
CMDs[#CMDs + 1] = {NAME = 'flyfling [speed]', DESC = 'Basically the invisfling command but not invisible'}
CMDs[#CMDs + 1] = {NAME = 'unflyfling', DESC = 'Disables the flyfling command'}
CMDs[#CMDs + 1] = {NAME = 'walkfling', DESC = 'Basically fling but no spinning'}
CMDs[#CMDs + 1] = {NAME = 'unwalkfling / nowalkfling', DESC = 'Disables walkfling'}
CMDs[#CMDs + 1] = {NAME = 'invisfling', DESC = 'Enables invisible fling (the invis part is patched, try using the god command before using this)'}
CMDs[#CMDs + 1] = {NAME = 'antifling', DESC = 'Disables player collisions to prevent you from being flung'}
CMDs[#CMDs + 1] = {NAME = 'unantifling', DESC = 'Disables antifling'}
CMDs[#CMDs + 1] = {NAME = 'loopoof', DESC = 'Loops everyones character sounds (everyone can hear)'}
CMDs[#CMDs + 1] = {NAME = 'unloopoof', DESC = 'Stops the oof chaos'}
CMDs[#CMDs + 1] = {NAME = 'muteboombox [player]', DESC = 'Mutes someones boombox'}
CMDs[#CMDs + 1] = {NAME = 'unmuteboombox [player]', DESC = 'Unmutes someones boombox'}
CMDs[#CMDs + 1] = {NAME = 'hitbox [player] [size] [transparency]', DESC = 'Expands the hitbox for players HumanoidRootPart (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'headsize [player] [size]', DESC = 'Expands the head size for players Head (default is 1)'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'reset', DESC = 'Resets your character normally'}
CMDs[#CMDs + 1] = {NAME = 'respawn', DESC = 'Respawns you'}
CMDs[#CMDs + 1] = {NAME = 'refresh / re', DESC = 'Respawns and brings you back to the same position'}
CMDs[#CMDs + 1] = {NAME = 'god', DESC = 'Makes your character difficult to kill in most games'}
CMDs[#CMDs + 1] = {NAME = 'permadeath', DESC = 'Makes you unable to respawn after death'}
CMDs[#CMDs + 1] = {NAME = 'invisible / invis', DESC = 'Makes you invisible to other players'}
CMDs[#CMDs + 1] = {NAME = 'visible / vis', DESC = 'Makes you visible to other players'}
CMDs[#CMDs + 1] = {NAME = 'toolinvisible / toolinvis / tinvis', DESC = 'Makes you invisible to other players and able to use tools'}
CMDs[#CMDs + 1] = {NAME = 'speed / ws / walkspeed [num]', DESC = 'Change your walkspeed (default is 16)'}
CMDs[#CMDs + 1] = {NAME = 'spoofspeed / spoofws [num]', DESC = 'Spoofs your WalkSpeed on the Client'}
CMDs[#CMDs + 1] = {NAME = 'loopspeed / loopws [num]', DESC = 'Loops your walkspeed'}
CMDs[#CMDs + 1] = {NAME = 'unloopspeed / unloopws', DESC = 'Turns off loopspeed'}
CMDs[#CMDs + 1] = {NAME = 'hipheight / hheight [num]', DESC = 'Adjusts hip height'}
CMDs[#CMDs + 1] = {NAME = 'jumppower / jpower / jp [num]', DESC = 'Change a players jump height (default is 50)'}
CMDs[#CMDs + 1] = {NAME = 'spoofjumppower / spoofjp [num]', DESC = 'Spoofs your JumpPower on the Client'}
CMDs[#CMDs + 1] = {NAME = 'loopjumppower / loopjp [num]', DESC = 'Loops your jump height'}
CMDs[#CMDs + 1] = {NAME = 'unloopjumppower / unloopjp', DESC = 'Turns off loopjumppower'}
CMDs[#CMDs + 1] = {NAME = 'maxslopeangle / msa [num]', DESC = 'Adjusts MaxSlopeAngle'}
CMDs[#CMDs + 1] = {NAME = 'gravity / grav [num] (CLIENT)', DESC = 'Change your gravity'}
CMDs[#CMDs + 1] = {NAME = 'sit', DESC = 'Makes your character sit'}
CMDs[#CMDs + 1] = {NAME = 'lay / laydown', DESC = 'Makes your character lay down'}
CMDs[#CMDs + 1] = {NAME = 'sitwalk', DESC = 'Makes your character sit while still being able to walk'}
CMDs[#CMDs + 1] = {NAME = 'nosit', DESC = 'Prevents your character from sitting'}
CMDs[#CMDs + 1] = {NAME = 'unnosit', DESC = 'Disables nosit'}
CMDs[#CMDs + 1] = {NAME = 'jump', DESC = 'Makes your character jump'}
CMDs[#CMDs + 1] = {NAME = 'infinitejump / infjump', DESC = 'Allows you to jump before hitting the ground'}
CMDs[#CMDs + 1] = {NAME = 'uninfinitejump / uninfjump', DESC = 'Disables infjump'}
CMDs[#CMDs + 1] = {NAME = 'flyjump', DESC = 'Allows you to hold space to fly up'}
CMDs[#CMDs + 1] = {NAME = 'unflyjump', DESC = 'Disables flyjump'}
CMDs[#CMDs + 1] = {NAME = 'autojump / ajump', DESC = 'Automatically jumps when you run into an object'}
CMDs[#CMDs + 1] = {NAME = 'unautojump / unajump', DESC = 'Disables autojump'}
CMDs[#CMDs + 1] = {NAME = 'edgejump / ejump', DESC = 'Automatically jumps when you get to the edge of an object'}
CMDs[#CMDs + 1] = {NAME = 'unedgejump / unejump', DESC = 'Disables edgejump'}
CMDs[#CMDs + 1] = {NAME = 'platformstand / stun', DESC = 'Enables PlatformStand'}
CMDs[#CMDs + 1] = {NAME = 'unplatformstand / unstun', DESC = 'Disables PlatformStand'}
CMDs[#CMDs + 1] = {NAME = 'norotate / noautorotate', DESC = 'Disables AutoRotate'}
CMDs[#CMDs + 1] = {NAME = 'unnorotate / autorotate', DESC = 'Enables AutoRotate'}
CMDs[#CMDs + 1] = {NAME = 'enablestate [StateType]', DESC = 'Enables a humanoid state type'}
CMDs[#CMDs + 1] = {NAME = 'disablestate [StateType]', DESC = 'Disables a humanoid state type'}
CMDs[#CMDs + 1] = {NAME = 'team [team name] (CLIENT)', DESC = 'Changes your team. Sometimes fools localscripts.'}
CMDs[#CMDs + 1] = {NAME = 'nobillboardgui / nobgui / noname', DESC = 'Removes billboard and surface GUIs from your players (i.e. name GUIs at cafes)'}
CMDs[#CMDs + 1] = {NAME = 'loopnobgui / loopnoname', DESC = 'Loop removes billboard and surface GUIs from your players (i.e. name GUIs at cafes)'}
CMDs[#CMDs + 1] = {NAME = 'unloopnobgui / unloopnoname', DESC = 'Disables loopnobgui'}
CMDs[#CMDs + 1] = {NAME = 'noarms', DESC = 'Removes your arms'}
CMDs[#CMDs + 1] = {NAME = 'nolegs', DESC = 'Removes your legs'}
CMDs[#CMDs + 1] = {NAME = 'nolimbs', DESC = 'Removes your limbs'}
CMDs[#CMDs + 1] = {NAME = 'naked (CLIENT)', DESC = 'Removes your clothing'}
CMDs[#CMDs + 1] = {NAME = 'noface / removeface', DESC = 'Removes your face'}
CMDs[#CMDs + 1] = {NAME = 'blockhead', DESC = 'Turns your head into a block'}
CMDs[#CMDs + 1] = {NAME = 'blockhats', DESC = 'Turns your hats into blocks'}
CMDs[#CMDs + 1] = {NAME = 'blocktool', DESC = 'Turns the currently selected tool into a block'}
CMDs[#CMDs + 1] = {NAME = 'creeper', DESC = 'Makes you look like a creeper'}
CMDs[#CMDs + 1] = {NAME = 'drophats', DESC = 'Drops your hats'}
CMDs[#CMDs + 1] = {NAME = 'nohats / deletehats / rhats', DESC = 'Deletes your hats'}
CMDs[#CMDs + 1] = {NAME = 'hatspin / spinhats', DESC = 'Spins your characters accessories'}
CMDs[#CMDs + 1] = {NAME = 'unhatspin / unspinhats', DESC = 'Undoes spinhats'}
CMDs[#CMDs + 1] = {NAME = 'clearhats / cleanhats', DESC = 'Clears hats in the workspace'}
CMDs[#CMDs + 1] = {NAME = 'chardelete / cd [instance name]', DESC = 'Removes any part with a certain name from your character'}
CMDs[#CMDs + 1] = {NAME = 'chardeleteclass / cdc [class name]', DESC = 'Removes any part with a certain classname from your character'}
CMDs[#CMDs + 1] = {NAME = 'deletevelocity / dv / removeforces', DESC = 'Removes any velocity / force instances in your character'}
CMDs[#CMDs + 1] = {NAME = 'weaken [num]', DESC = 'Makes your character less dense'}
CMDs[#CMDs + 1] = {NAME = 'unweaken', DESC = 'Sets your characters CustomPhysicalProperties to default'}
CMDs[#CMDs + 1] = {NAME = 'strengthen [num]', DESC = 'Makes your character more dense (CustomPhysicalProperties)'}
CMDs[#CMDs + 1] = {NAME = 'unstrengthen', DESC = 'Sets your characters CustomPhysicalProperties to default'}
CMDs[#CMDs + 1] = {NAME = 'breakvelocity', DESC = 'Sets your characters velocity to 0'}
CMDs[#CMDs + 1] = {NAME = 'spin [speed]', DESC = 'Spins your character'}
CMDs[#CMDs + 1] = {NAME = 'unspin', DESC = 'Disables spin'}
CMDs[#CMDs + 1] = {NAME = 'split', DESC = 'Splits your character in half'}
CMDs[#CMDs + 1] = {NAME = 'nilchar', DESC = 'Sets your characters parent to nil'}
CMDs[#CMDs + 1] = {NAME = 'unnilchar / nonilchar', DESC = 'Sets your characters parent to workspace'}
CMDs[#CMDs + 1] = {NAME = 'noroot / removeroot / rroot', DESC = 'Removes your characters HumanoidRootPart'}
CMDs[#CMDs + 1] = {NAME = 'replaceroot', DESC = 'Replaces your characters HumanoidRootPart'}
CMDs[#CMDs + 1] = {NAME = 'clearcharappearance / clearchar / clrchar', DESC = 'Removes all accessory, shirt, pants, charactermesh, and bodycolors'}
CMDs[#CMDs + 1] = {NAME = 'tpwalk / teleportwalk [num]', DESC = 'Teleports you to your move direction'}
CMDs[#CMDs + 1] = {NAME = 'untpwalk / unteleportwalk', DESC = 'Undoes tpwalk / teleportwalk'}
CMDs[#CMDs + 1] = {NAME = 'trip', DESC = 'Makes your character fall over'}
CMDs[#CMDs + 1] = {NAME = 'wallwalk / walkonwalls', DESC = 'Walk on walls'}
CMDs[#CMDs + 1] = {NAME = 'promptr6', DESC = 'Prompts the game to switch your rig type to R6'}
CMDs[#CMDs + 1] = {NAME = 'promptr15', DESC = 'Prompts the game to switch your rig type to R15'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'animation / anim [ID] [speed]', DESC = 'Makes your character perform an animation (must be an animation on the marketplace or by roblox/stickmasterluke to replicate)'}
CMDs[#CMDs + 1] = {NAME = 'emote / em [ID] [speed]', DESC = 'Makes your character perform an emote (must be on the marketplace or by roblox/stickmasterluke to replicate)'}
CMDs[#CMDs + 1] = {NAME = 'dance', DESC = 'Makes you  d a n c e'}
CMDs[#CMDs + 1] = {NAME = 'undance', DESC = 'Stops dance animations'}
CMDs[#CMDs + 1] = {NAME = 'spasm', DESC = 'Makes you  c r a z y'}
CMDs[#CMDs + 1] = {NAME = 'unspasm', DESC = 'Stops spasm'}
CMDs[#CMDs + 1] = {NAME = 'headthrow', DESC = 'Simply makes you throw your head'}
CMDs[#CMDs + 1] = {NAME = 'noanim', DESC = 'Disables your animations'}
CMDs[#CMDs + 1] = {NAME = 'reanim', DESC = 'Restores your animations'}
CMDs[#CMDs + 1] = {NAME = 'animspeed [num]', DESC = 'Changes the speed of your current animation'}
CMDs[#CMDs + 1] = {NAME = 'copyanimation / copyanim / copyemote [player]', DESC = 'Copies someone elses animation'}
CMDs[#CMDs + 1] = {NAME = 'copyanimationid / copyanimid / copyemoteid [player]', DESC = 'Copies your animation id or someone elses to your clipboard'}
CMDs[#CMDs + 1] = {NAME = 'loopanimation / loopanim', DESC = 'Loops your current animation'}
CMDs[#CMDs + 1] = {NAME = 'stopanimations / stopanims', DESC = 'Stops running animations'}
CMDs[#CMDs + 1] = {NAME = 'refreshanimations / refreshanims', DESC = 'Refreshes animations'}
CMDs[#CMDs + 1] = {NAME = 'allowcustomanim / allowcustomanimations', DESC = 'Lets you use custom animation packs instead'}
CMDs[#CMDs + 1] = {NAME = 'unallowcustomanim / unallowcustomanimations', DESC = 'Doesn\'t let you use custom animation packs instead'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'autoclick [click delay] [release delay]', DESC = 'Automatically clicks your mouse with a set delay'}
CMDs[#CMDs + 1] = {NAME = 'unautoclick / noautoclick', DESC = 'Turns off autoclick'}
CMDs[#CMDs + 1] = {NAME = 'autokeypress [key] [down delay] [up delay]', DESC = 'Automatically presses a key with a set delay'}
CMDs[#CMDs + 1] = {NAME = 'unautokeypress', DESC = 'Stops autokeypress'}
CMDs[#CMDs + 1] = {NAME = 'hovername', DESC = 'Shows a players username when your mouse is hovered over them'}
CMDs[#CMDs + 1] = {NAME = 'unhovername / nohovername', DESC = 'Turns off hovername'}
CMDs[#CMDs + 1] = {NAME = 'mousesensitivity / ms [0-10]', DESC = 'Sets your mouse sensitivity (affects first person and right click drag) (default is 1)'}
CMDs[#CMDs + 1] = {NAME = 'clickdelete', DESC = 'Go to Settings > Keybinds > Add for click delete'}
CMDs[#CMDs + 1] = {NAME = 'clickteleport', DESC = 'Go to Settings > Keybinds > Add for click teleport'}
CMDs[#CMDs + 1] = {NAME = 'mouseteleport / mousetp', DESC = 'Teleports your character to your mouse. This is recommended as a keybind'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'tools', DESC = 'Copies tools from ReplicatedStorage and Lighting'}
CMDs[#CMDs + 1] = {NAME = 'notools / removetools / deletetools', DESC = 'Removes tools from character and backpack'}
CMDs[#CMDs + 1] = {NAME = 'deleteselectedtool / dst', DESC = 'Removes any currently selected tools'}
CMDs[#CMDs + 1] = {NAME = 'grabtools', DESC = 'Automatically get tools that are dropped'}
CMDs[#CMDs + 1] = {NAME = 'ungrabtools / nograbtools', DESC = 'Disables grabtools'}
CMDs[#CMDs + 1] = {NAME = 'copytools [player] (CLIENT)', DESC = 'Copies a players tools'}
CMDs[#CMDs + 1] = {NAME = 'dupetools / clonetools [num]', DESC = 'Duplicates your inventory tools a set amount of times'}
CMDs[#CMDs + 1] = {NAME = 'droptools', DESC = 'Drops your tools'}
CMDs[#CMDs + 1] = {NAME = 'droppabletools', DESC = 'Makes your tools droppable'}
CMDs[#CMDs + 1] = {NAME = 'equiptools', DESC = 'Equips every tool in your inventory at once'}
CMDs[#CMDs + 1] = {NAME = 'unequiptools', DESC = 'Unequips every tool you are currently holding at once'}
CMDs[#CMDs + 1] = {NAME = 'removespecifictool [name]', DESC = 'Automatically remove a specific tool from your inventory'}
CMDs[#CMDs + 1] = {NAME = 'unremovespecifictool [name]', DESC = 'Stops removing a specific tool from your inventory'}
CMDs[#CMDs + 1] = {NAME = 'clearremovespecifictool', DESC = 'Stop removing all specific tools from your inventory'}
CMDs[#CMDs + 1] = {NAME = 'reach [num]', DESC = 'Increases the hitbox of your held tool'}
CMDs[#CMDs + 1] = {NAME = 'boxreach [num]', DESC = 'Increases the hitbox of your held tool in a box shape'}
CMDs[#CMDs + 1] = {NAME = 'unreach / noreach', DESC = 'Turns off reach'}
CMDs[#CMDs + 1] = {NAME = 'grippos [X Y Z]', DESC = 'Changes your current tools grip position'}
CMDs[#CMDs + 1] = {NAME = 'usetools [amount] [delay]', DESC = 'Activates all tools in your backpack at the same time'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'addalias [cmd] [alias]', DESC = 'Adds an alias to a command'}
CMDs[#CMDs + 1] = {NAME = 'removealias [alias]', DESC = 'Removes a custom alias'}
CMDs[#CMDs + 1] = {NAME = 'clraliases', DESC = 'Removes all custom aliases'}
CMDs[#CMDs + 1] = {NAME = '', DESC = ''}
CMDs[#CMDs + 1] = {NAME = 'addplugin / plugin [name]', DESC = 'Add a plugin via command'}
CMDs[#CMDs + 1] = {NAME = 'removeplugin / deleteplugin [name]', DESC = 'Remove a plugin via command'}
CMDs[#CMDs + 1] = {NAME = 'reloadplugin [name]', DESC = 'Reloads a plugin'}
CMDs[#CMDs + 1] = {NAME = 'addallplugins / loadallplugins', DESC = 'Adds all available plugins from the workspace folder'}
for i = 1, #CMDs do
	if i % 30 == 0 then task.wait() end
	local newcmd = Example:Clone()
	newcmd.Parent = CMDsF
	newcmd.Visible = false
	newcmd.Text = CMDs[i].NAME
	newcmd.Name = "CMD"
	table.insert(text1, newcmd)
	if CMDs[i].DESC ~= "" then
		newcmd:SetAttribute("Title", CMDs[i].NAME)
		newcmd:SetAttribute("Desc", CMDs[i].DESC)
		newcmd.MouseButton1Down:Connect(function()
			if not IsOnMobile and newcmd.Visible and newcmd.TextTransparency == 0 then
				local currentText = Cmdbar.Text
				Cmdbar:CaptureFocus()
				autoComplete(newcmd.Text, currentText)
				maximizeHolder()
			end
		end)
	end
end
IndexContents("", true)
function checkTT()
	local t
	local guisAtPosition = COREGUI:GetGuiObjectsAtPosition(IYMouse.X, IYMouse.Y)
	for _, gui in pairs(guisAtPosition) do
		if gui.Parent == CMDsF then
			t = gui
		end
	end
	if t ~= nil and t:GetAttribute("Title") ~= nil then
		local x = IYMouse.X
		local y = IYMouse.Y
		local xP
		local yP
		if IYMouse.X > 200 then
			xP = x - 201
		else
			xP = x + 21
		end
		if IYMouse.Y > (IYMouse.ViewSizeY-96) then
			yP = y - 97
		else
			yP = y
		end
		Tooltip.Position = UDim2.new(0, xP, 0, yP)
		Description.Text = t:GetAttribute("Desc")
		if t:GetAttribute("Title") ~= nil then
			Title_3.Text = t:GetAttribute("Title")
		else
			Title_3.Text = ''
		end
		Tooltip.Visible = true
	else
		Tooltip.Visible = false
	end
end
function FindInTable(tbl,val)
	if tbl == nil then return false end
	for _,v in pairs(tbl) do
		if v == val then return true end
	end
	return false
end
function GetInTable(Table, Name)
	for i = 1, #Table do
		if Table[i] == Name then
			return i
		end
	end
	return false
end
function permadeath(plr)
	if replicatesignal then
		replicatesignal(plr.ConnectDiedSignalBackend)
		task.wait(Players.RespawnTime - 0.1)
	end
end
function respawn(plr)
	if invisRunning then TurnVisible() end
	local char = plr.Character
	if onyxAPI and onyxAPI.is_reanimated and onyxAPI.is_reanimated() then
		char = onyxAPI.get_real_character(plr) or char
	end
	if char then
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Dead)
		end
		char:BreakJoints()
	end
end
local refreshCmd = false
function refresh(plr)
	refreshCmd = true
	local root = getRoot(plr.Character)
	if not root then
		respawn(plr)
		refreshCmd = false
		return
	end
	local pos = root.CFrame
	local pos1 = workspace.CurrentCamera.CFrame
	respawn(plr)
	task.spawn(function()
		local char = plr.CharacterAdded:Wait()
		local humanoid = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				task.wait(0.1)
				hrp.CFrame = pos
				workspace.CurrentCamera.CFrame = pos1
			end
		end
		refreshCmd = false
	end)
end
local lastDeath
function onDied()
	task.spawn(function()
		if pcall(function() Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') end) and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
			Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
				if getRoot(Players.LocalPlayer.Character) then
					lastDeath = getRoot(Players.LocalPlayer.Character).CFrame
				end
			end)
		else
			wait(2)
			onDied()
		end
	end)
end
Clip = true
spDelay = 0.1
Players.LocalPlayer.CharacterAdded:Connect(function()
	NOFLY()
	Floating = false
	if not Clip then
		execCmd('clip')
	end
	repeat wait() until getRoot(Players.LocalPlayer.Character)
	pcall(function()
		if spawnpoint and not refreshCmd and spawnpos ~= nil then
			wait(spDelay)
			getRoot(Players.LocalPlayer.Character).CFrame = spawnpos
		end
	end)
	onDied()
end)
onDied()
local booly = {
    truthy = { ["true"] = true, ["t"] = true, ["1"] = true, yes = true, y = true, on = true, enable = true, enabled = true },
    falsy = { ["false"] = true, ["f"] = true, ["0"] = true, no = true, n = true, off = true, disable = true, disabled = true }
}
parseBoolean = function(raw, default)
    raw = tostring(raw)
    if booly.truthy[raw] then return true end
    if booly.falsy[raw] then return false end
    return default or false
end

getstring = function(begin, args)
    return table.concat(args or cargs, " ", begin)
end

findCmd = function(cmd_name)
	for i,v in pairs(cmds)do
		if v.NAME:lower()==cmd_name:lower() or FindInTable(v.ALIAS,cmd_name:lower()) then
			return v
		end
	end
	return customAlias[cmd_name:lower()]
end

splitString = function(str,delim)
	local broken = {}
	if delim == nil then delim = "," end
	for w in string.gmatch(str,"[^"..delim.."]+") do
		table.insert(broken,w)
	end
	return broken
end

cmdHistory = {}
local lastCmds = {}
local historyCount = 0
local split=" "
local lastBreakTime = 0
execCmd = function(cmdStr,speaker,store)
	cmdStr = cmdStr:gsub("%s+$","")
	task.spawn(function()
		local rawCmdStr = cmdStr
		cmdStr = string.gsub(cmdStr,"\\\\","%%BackSlash%%")
		local commandsToRun = splitString(cmdStr,"\\")
		for i,v in pairs(commandsToRun) do
			v = string.gsub(v,"%%BackSlash%%","\\")
			local x,y,num = v:find("^(%d+)%^")
			local cmdDelay = 0
			local infTimes = false
			if num then
				v = v:sub(y+1)
				local x,y,del = v:find("^([%d%.]+)%^")
				if del then
					v = v:sub(y+1)
					cmdDelay = tonumber(del) or 0
				end
			else
				local x,y = v:find("^inf%^")
				if x then
					infTimes = true
					v = v:sub(y+1)
					local x,y,del = v:find("^([%d%.]+)%^")
					if del then
						v = v:sub(y+1)
						del = tonumber(del) or 1
						cmdDelay = (del > 0 and del or 1)
					else
						cmdDelay = 1
					end
				end
			end
			num = tonumber(num or 1)
			if v:sub(1,1) == "!" then
				local chunks = splitString(v:sub(2),split)
				if chunks[1] and lastCmds[chunks[1]] then v = lastCmds[chunks[1]] end
			end
			local args = splitString(v,split)
			local cmdName = args[1]
			local cmd = findCmd(cmdName)
			if cmd then
				table.remove(args,1)
				cargs = args
				if not speaker then speaker = Players.LocalPlayer end
				if store then
					if speaker == Players.LocalPlayer then
						if cmdHistory[1] ~= rawCmdStr and rawCmdStr:sub(1,11) ~= 'lastcommand' and rawCmdStr:sub(1,7) ~= 'lastcmd' then
							table.insert(cmdHistory,1,rawCmdStr)
						end
					end
					if #cmdHistory > 30 then table.remove(cmdHistory) end
					lastCmds[cmdName] = v
				end
				local cmdStartTime = tick()
				if infTimes then
					while lastBreakTime < cmdStartTime do
						local success,err = pcall(cmd.FUNC,args, speaker)
						if not success and _G.IY_DEBUG then
							warn("Command Error:", cmdName, err)
						end
						wait(cmdDelay)
					end
				else
					for rep = 1,num do
						if lastBreakTime > cmdStartTime then break end
						local success,err = pcall(function()
							cmd.FUNC(args, speaker)
						end)
						if not success and _G.IY_DEBUG then
							warn("Command Error:", cmdName, err)
						end
						if cmdDelay ~= 0 then wait(cmdDelay) end
					end
				end
			end
		end
	end)
end

addcmd = function(name,alias,func,plgn)
	cmds[#cmds+1]=
		{
			NAME=name;
			ALIAS=alias or {};
			FUNC=func;
			PLUGIN=plgn;
		}
end

removecmd = function(cmd)
	if cmd ~= " " then
		for i = #cmds,1,-1 do
			if cmds[i].NAME == cmd or FindInTable(cmds[i].ALIAS,cmd) then
				table.remove(cmds, i)
				for a,c in pairs(CMDsF:GetChildren()) do
					if string.find(c.Text, "^"..cmd.."$") or string.find(c.Text, "^"..cmd.." ") or string.find(c.Text, " "..cmd.."$") or string.find(c.Text, " "..cmd.." ") then
						c.TextTransparency = 0.7
						c.MouseButton1Click:Connect(function()
							notify(c.Text, "Command has been disabled by you or a plugin")
						end)
					end
				end
			end
		end
	end
end
function overridecmd(name, func)
	local cmd = findCmd(name)
	if cmd and cmd.FUNC then cmd.FUNC = func end
end
function addbind(cmd,key,iskeyup,toggle)
	if toggle then
		binds[#binds+1]=
			{
				COMMAND=cmd;
				KEY=key;
				ISKEYUP=iskeyup;
				TOGGLE = toggle;
			}
	else
		binds[#binds+1]=
			{
				COMMAND=cmd;
				KEY=key;
				ISKEYUP=iskeyup;
			}
	end
end
function addcmdtext(text,name,desc)
	local newcmd = Example:Clone()
	local tooltipText = tostring(text)
	local tooltipDesc = tostring(desc)
	newcmd.Parent = CMDsF
	newcmd.Visible = false
	newcmd.Text = text
	newcmd.Name = 'PLUGIN_'..name
	table.insert(text1,newcmd)
	if desc and desc ~= '' then
		newcmd:SetAttribute("Title", tooltipText)
		newcmd:SetAttribute("Desc", tooltipDesc)
		newcmd.MouseButton1Down:Connect(function()
			if newcmd.Visible and newcmd.TextTransparency == 0 then
				Cmdbar:CaptureFocus()
				autoComplete(newcmd.Text)
				maximizeHolder()
			end
		end)
	end
end
local WorldToScreen = function(Object)
	local ObjectVector = workspace.CurrentCamera:WorldToScreenPoint(Object.Position)
	return Vector2.new(ObjectVector.X, ObjectVector.Y)
end
local MousePositionToVector2 = function()
	return Vector2.new(IYMouse.X, IYMouse.Y)
end
local GetClosestPlayerFromCursor = function()
	local found = nil
	local ClosestDistance = math.huge
	for i, v in pairs(Players:GetPlayers()) do
		if v ~= Players.LocalPlayer and v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
			for k, x in pairs(v.Character:GetChildren()) do
				if string.find(x.Name, "Torso") then
					local Distance = (WorldToScreen(x) - MousePositionToVector2()).Magnitude
					if Distance < ClosestDistance then
						ClosestDistance = Distance
						found = v
					end
				end
			end
		end
	end
	return found
end
SpecialPlayerCases = {
	["all"] = function(speaker) return Players:GetPlayers() end,
	["others"] = function(speaker)
		local plrs = {}
		for i,v in pairs(Players:GetPlayers()) do
			if v ~= speaker then
				table.insert(plrs,v)
			end
		end
		return plrs
	end,
	["me"] = function(speaker)return {speaker} end,
	["#(%d+)"] = function(speaker,args,currentList)
		local returns = {}
		local randAmount = tonumber(args[1])
		local players = {unpack(currentList)}
		for i = 1,randAmount do
			if #players == 0 then break end
			local randIndex = math.random(1,#players)
			table.insert(returns,players[randIndex])
			table.remove(players,randIndex)
		end
		return returns
	end,
	["random"] = function(speaker,args,currentList)
		local players = Players:GetPlayers()
		local localplayer = Players.LocalPlayer
		table.remove(players, table.find(players, localplayer))
		return {players[math.random(1,#players)]}
	end,
	["%%(.+)"] = function(speaker,args)
		local returns = {}
		local team = args[1]
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team and string.sub(string.lower(plr.Team.Name),1,#team) == string.lower(team) then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["allies"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team == team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["enemies"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team ~= team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["team"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team == team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["nonteam"] = function(speaker)
		local returns = {}
		local team = speaker.Team
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Team ~= team then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["friends"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr:IsFriendsWith(speaker.UserId) and plr ~= speaker then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["nonfriends"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if not plr:IsFriendsWith(speaker.UserId) and plr ~= speaker then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["guests"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Guest then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["bacons"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Character:FindFirstChild('Pal Hair') or plr.Character:FindFirstChild('Kate Hair') then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["age(%d+)"] = function(speaker,args)
		local returns = {}
		local age = tonumber(args[1])
		if not age == nil then return end
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.AccountAge <= age then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["nearest"] = function(speaker,args,currentList)
		local speakerChar = speaker.Character
		if not speakerChar or not getRoot(speakerChar) then return end
		local lowest = math.huge
		local NearestPlayer = nil
		for _,plr in pairs(currentList) do
			if plr ~= speaker and plr.Character then
				local distance = plr:DistanceFromCharacter(getRoot(speakerChar).Position)
				if distance < lowest then
					lowest = distance
					NearestPlayer = {plr}
				end
			end
		end
		return NearestPlayer
	end,
	["farthest"] = function(speaker,args,currentList)
		local speakerChar = speaker.Character
		if not speakerChar or not getRoot(speakerChar) then return end
		local highest = 0
		local Farthest = nil
		for _,plr in pairs(currentList) do
			if plr ~= speaker and plr.Character then
				local distance = plr:DistanceFromCharacter(getRoot(speakerChar).Position)
				if distance > highest then
					highest = distance
					Farthest = {plr}
				end
			end
		end
		return Farthest
	end,
	["group(%d+)"] = function(speaker,args)
		local returns = {}
		local groupID = tonumber(args[1])
		for _,plr in pairs(Players:GetPlayers()) do
			if plr:IsInGroup(groupID) then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["alive"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["dead"] = function(speaker,args)
		local returns = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if (not plr.Character or not plr.Character:FindFirstChildOfClass("Humanoid")) or plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
				table.insert(returns,plr)
			end
		end
		return returns
	end,
	["rad(%d+)"] = function(speaker,args)
		local returns = {}
		local radius = tonumber(args[1])
		local speakerChar = speaker.Character
		if not speakerChar or not getRoot(speakerChar) then return end
		for _,plr in pairs(Players:GetPlayers()) do
			if plr.Character and getRoot(plr.Character) then
				local magnitude = (getRoot(plr.Character).Position-getRoot(speakerChar).Position).magnitude
				if magnitude <= radius then table.insert(returns,plr) end
			end
		end
		return returns
	end,
	["cursor"] = function(speaker)
		local plrs = {}
		local v = GetClosestPlayerFromCursor()
		if v ~= nil then table.insert(plrs, v) end
		return plrs
	end,
	["npcs"] = function(speaker,args)
		local returns = {}
		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("Model") and getRoot(v) and v:FindFirstChildWhichIsA("Humanoid") and Players:GetPlayerFromCharacter(v) == nil then
				local clone = Instance.new("Player")
				clone.Name = v.Name .. " - " .. v:FindFirstChildWhichIsA("Humanoid").DisplayName
				clone.Character = v
				table.insert(returns, clone)
			end
		end
		return returns
	end,
}
function toTokens(str)
	local tokens = {}
	for op,name in string.gmatch(str,"([+-])([^+-]+)") do
		table.insert(tokens,{Operator = op,Name = name})
	end
	return tokens
end
function onlyIncludeInTable(tab,matches)
	local matchTable = {}
	local resultTable = {}
	for i,v in pairs(matches) do matchTable[v.Name] = true end
	for i,v in pairs(tab) do if matchTable[v.Name] then table.insert(resultTable,v) end end
	return resultTable
end
function removeTableMatches(tab,matches)
	local matchTable = {}
	local resultTable = {}
	for i,v in pairs(matches) do matchTable[v.Name] = true end
	for i,v in pairs(tab) do if not matchTable[v.Name] then table.insert(resultTable,v) end end
	return resultTable
end
function getPlayersByName(Name)
	if not Name or Name == "" then return {} end
	local cleanName = string.lower(Name)
	if cleanName:sub(1, 1) == "@" then
		cleanName = cleanName:sub(2)
	end
	local Len = #cleanName
	if Len == 0 then return {} end

	local exact = {}
	local prefix = {}
	local substring = {}

	for _, v in pairs(Players:GetPlayers()) do
		local uname = string.lower(v.Name)
		local dname = string.lower(v.DisplayName or v.Name)

		if uname == cleanName or dname == cleanName then
			table.insert(exact, v)
		elseif string.sub(uname, 1, Len) == cleanName or string.sub(dname, 1, Len) == cleanName then
			table.insert(prefix, v)
		elseif string.find(uname, cleanName, 1, true) or string.find(dname, cleanName, 1, true) then
			table.insert(substring, v)
		end
	end

	if #exact > 0 then return exact end
	if #prefix > 0 then return prefix end
	return substring
end
function getPlayer(list,speaker)
	speaker = speaker or Players.LocalPlayer
	if list == nil or list == "" or list == "me" or list == "self" then
		return {speaker.Name}
	end
	local nameList = splitString(list,",")
	local foundList = {}
	for _,name in pairs(nameList) do
		name = name:match("^%s*(.-)%s*$")
		if name == "me" or name == "self" then
			table.insert(foundList, speaker)
		elseif name == "others" then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= speaker then table.insert(foundList, p) end
			end
		elseif name == "all" then
			for _, p in ipairs(Players:GetPlayers()) do
				table.insert(foundList, p)
			end
		elseif name ~= "" then
			if string.sub(name,1,1) ~= "+" and string.sub(name,1,1) ~= "-" then name = "+"..name end
			local tokens = toTokens(name)
			local initialPlayers = Players:GetPlayers()
			for i,v in pairs(tokens) do
				if v.Operator == "+" then
					local tokenContent = v.Name
					local foundCase = false
					for regex,case in pairs(SpecialPlayerCases) do
						local matches = {string.match(tokenContent,"^"..regex.."$")}
						if #matches > 0 then
							foundCase = true
							initialPlayers = onlyIncludeInTable(initialPlayers,case(speaker,matches,initialPlayers))
						end
					end
					if not foundCase then
						initialPlayers = onlyIncludeInTable(initialPlayers,getPlayersByName(tokenContent))
					end
				else
					local tokenContent = v.Name
					local foundCase = false
					for regex,case in pairs(SpecialPlayerCases) do
						local matches = {string.match(tokenContent,"^"..regex.."$")}
						if #matches > 0 then
							foundCase = true
							initialPlayers = removeTableMatches(initialPlayers,case(speaker,matches,initialPlayers))
						end
					end
					if not foundCase then
						initialPlayers = removeTableMatches(initialPlayers,getPlayersByName(tokenContent))
					end
				end
			end
			for i,v in pairs(initialPlayers) do table.insert(foundList,v) end
		end
	end
	local foundNames = {}
	for i,v in pairs(foundList) do
		if not table.find(foundNames, v.Name) then
			table.insert(foundNames, v.Name)
		end
	end
	return foundNames
end
function formatUsername(player)
	if player.DisplayName ~= player.Name then
		return string.format("%s (%s)", player.Name, player.DisplayName)
	end
	return player.Name
end
getprfx=function(strn)
	if strn:sub(1,string.len(prefix))==prefix then return{'cmd',string.len(prefix)+1}
	end return
end
function do_exec(str, plr)
	str = str:gsub('/e ', '')
	local t = getprfx(str)
	if not t then return end
	str = str:sub(t[2])
	if t[1]=='cmd' then
		execCmd(str, plr, true)
		IndexContents('',true,false,true)
		CMDsF.CanvasPosition = canvasPos
	end
end
lastTextBoxString,lastTextBoxCon,lastEnteredString = nil,nil,nil
UserInputService.TextBoxFocused:Connect(function(obj)
	if lastTextBoxCon then lastTextBoxCon:Disconnect() end
	if obj == Cmdbar then lastTextBoxString = nil return end
	lastTextBoxString = obj.Text
	lastTextBoxCon = obj:GetPropertyChangedSignal("Text"):Connect(function()
		if not (UserInputService:IsKeyDown(Enum.KeyCode.Return) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadEnter)) then
			lastTextBoxString = obj.Text
		end
	end)
end)
UserInputService.InputBegan:Connect(function(input,gameProcessed)
	if gameProcessed then
		if Cmdbar and Cmdbar:IsFocused() then
			if input.KeyCode == Enum.KeyCode.Up then
				historyCount = historyCount + 1
				if historyCount > #cmdHistory then historyCount = #cmdHistory end
				Cmdbar.Text = cmdHistory[historyCount] or ""
				Cmdbar.CursorPosition = 1020
			elseif input.KeyCode == Enum.KeyCode.Down then
				historyCount = historyCount - 1
				if historyCount < 0 then historyCount = 0 end
				Cmdbar.Text = cmdHistory[historyCount] or ""
				Cmdbar.CursorPosition = 1020
			end
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			lastEnteredString = lastTextBoxString
		end
	end
end)
Players.LocalPlayer.Chatted:Connect(function()
	wait()
	if lastEnteredString then
		local message = lastEnteredString
		lastEnteredString = nil
		pcall(do_exec, message, Players.LocalPlayer)
	end
end)
Cmdbar.PlaceholderText = "Command Bar ("..prefix..")"
Cmdbar:GetPropertyChangedSignal("Text"):Connect(function()
	if Cmdbar:IsFocused() then
		IndexContents(Cmdbar.Text,true,true)
	end
end)
local tabComplete = nil
tabAllowed = true
Cmdbar.FocusLost:Connect(function(enterpressed)
	if enterpressed then
		local cmdbarText = Cmdbar.Text:gsub("^"..prefix,"")
		execCmd(cmdbarText,Players.LocalPlayer,true)
	end
	if tabComplete then tabComplete:Disconnect() end
	wait()
	if not Cmdbar:IsFocused() then
		Cmdbar.Text = ""
		IndexContents('',true,false,true)
		if SettingsOpen == true then
			wait(0.2)
			Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.2, true, nil)
			CMDsF.Visible = false
		end
	end
	CMDsF.CanvasPosition = canvasPos
end)
Cmdbar.Focused:Connect(function()
	historyCount = 0
	canvasPos = CMDsF.CanvasPosition
	if SettingsOpen == true then
		wait(0.2)
		CMDsF.Visible = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 220), "InOut", "Quart", 0.2, true, nil)
	end
	tabComplete = UserInputService.InputBegan:Connect(function(input,gameProcessed)
		if Cmdbar:IsFocused() then
			if tabAllowed == true and input.KeyCode == Enum.KeyCode.Tab and topCommand ~= nil then
				autoComplete(topCommand)
			end
		else
			tabComplete:Disconnect()
		end
	end)
end)
ESPenabled = false
CHMSenabled = false
function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end
function ESP(plr, logic)
	task.spawn(function()
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_ESP' then
				v:Destroy()
			end
		end
		wait()
		if plr.Character and plr.Name ~= Players.LocalPlayer.Name and not COREGUI:FindFirstChild(plr.Name..'_ESP') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_ESP'
			ESPholder.Parent = COREGUI
			repeat wait(1) until plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
			for b,n in pairs (plr.Character:GetChildren()) do
				if (n:IsA("BasePart")) then
					local a = Instance.new("BoxHandleAdornment")
					a.Name = plr.Name
					a.Parent = ESPholder
					a.Adornee = n
					a.AlwaysOnTop = true
					a.ZIndex = 10
					a.Size = n.Size
					a.Transparency = espTransparency
					if logic == true then
						a.Color = BrickColor.new(plr.TeamColor == Players.LocalPlayer.TeamColor and "Bright green" or "Bright red")
					else
						a.Color = plr.TeamColor
					end
				end
			end
			if plr.Character and plr.Character:FindFirstChild('Head') then
				local BillboardGui = Instance.new("BillboardGui")
				local TextLabel = Instance.new("TextLabel")
				BillboardGui.Adornee = plr.Character.Head
				BillboardGui.Name = plr.Name
				BillboardGui.Parent = ESPholder
				BillboardGui.Size = UDim2.new(0, 100, 0, 150)
				BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
				BillboardGui.AlwaysOnTop = true
				TextLabel.Parent = BillboardGui
				TextLabel.BackgroundTransparency = 1
				TextLabel.Position = UDim2.new(0, 0, 0, -50)
				TextLabel.Size = UDim2.new(0, 100, 0, 100)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.TextSize = 20
				TextLabel.TextColor3 = Color3.new(1, 1, 1)
				TextLabel.TextStrokeTransparency = 0
				TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
				TextLabel.Text = 'Name: '..plr.Name
				TextLabel.ZIndex = 10
				local espLoopFunc
				local teamChange
				local addedFunc
				addedFunc = plr.CharacterAdded:Connect(function()
					if ESPenabled then
						espLoopFunc:Disconnect()
						teamChange:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						ESP(plr, logic)
						addedFunc:Disconnect()
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
					end
				end)
				teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
					if ESPenabled then
						espLoopFunc:Disconnect()
						addedFunc:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						ESP(plr, logic)
						teamChange:Disconnect()
					else
						teamChange:Disconnect()
					end
				end)
				local lastUpdate = 0
				local espLoop = function()
					if COREGUI:FindFirstChild(plr.Name..'_ESP') then
						local now = tick()
						if now - lastUpdate >= 0.1 then
							lastUpdate = now
							if plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid") and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
								local pos = math.floor((getRoot(Players.LocalPlayer.Character).Position - getRoot(plr.Character).Position).magnitude)
								TextLabel.Text = 'Name: '..plr.Name..' | Health: '..round(plr.Character:FindFirstChildOfClass('Humanoid').Health, 1)..' | Studs: '..pos
							end
						end
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
						espLoopFunc:Disconnect()
					end
				end
				espLoopFunc = RunService.RenderStepped:Connect(espLoop)
			end
		end
	end)
end
function CHMS(plr)
	task.spawn(function()
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_CHMS' then
				v:Destroy()
			end
		end
		wait()
		if plr.Character and plr.Name ~= Players.LocalPlayer.Name and not COREGUI:FindFirstChild(plr.Name..'_CHMS') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_CHMS'
			ESPholder.Parent = COREGUI
			repeat wait(1) until plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
			for b,n in pairs (plr.Character:GetChildren()) do
				if (n:IsA("BasePart")) then
					local a = Instance.new("BoxHandleAdornment")
					a.Name = plr.Name
					a.Parent = ESPholder
					a.Adornee = n
					a.AlwaysOnTop = true
					a.ZIndex = 10
					a.Size = n.Size
					a.Transparency = espTransparency
					a.Color = plr.TeamColor
				end
			end
			local addedFunc
			local teamChange
			local CHMSremoved
			addedFunc = plr.CharacterAdded:Connect(function()
				if CHMSenabled then
					ESPholder:Destroy()
					teamChange:Disconnect()
					repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
					CHMS(plr)
					addedFunc:Disconnect()
				else
					teamChange:Disconnect()
					addedFunc:Disconnect()
				end
			end)
			teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
				if CHMSenabled then
					ESPholder:Destroy()
					addedFunc:Disconnect()
					repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
					CHMS(plr)
					teamChange:Disconnect()
				else
					teamChange:Disconnect()
				end
			end)
			CHMSremoved = ESPholder.AncestryChanged:Connect(function()
				teamChange:Disconnect()
				addedFunc:Disconnect()
				CHMSremoved:Disconnect()
			end)
		end
	end)
end
function Locate(plr)
	task.spawn(function()
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_LC' then
				v:Destroy()
			end
		end
		wait()
		if plr.Character and plr.Name ~= Players.LocalPlayer.Name and not COREGUI:FindFirstChild(plr.Name..'_LC') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_LC'
			ESPholder.Parent = COREGUI
			repeat wait(1) until plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
			for b,n in pairs (plr.Character:GetChildren()) do
				if (n:IsA("BasePart")) then
					local a = Instance.new("BoxHandleAdornment")
					a.Name = plr.Name
					a.Parent = ESPholder
					a.Adornee = n
					a.AlwaysOnTop = true
					a.ZIndex = 10
					a.Size = n.Size
					a.Transparency = espTransparency
					a.Color = plr.TeamColor
				end
			end
			if plr.Character and plr.Character:FindFirstChild('Head') then
				local BillboardGui = Instance.new("BillboardGui")
				local TextLabel = Instance.new("TextLabel")
				BillboardGui.Adornee = plr.Character.Head
				BillboardGui.Name = plr.Name
				BillboardGui.Parent = ESPholder
				BillboardGui.Size = UDim2.new(0, 100, 0, 150)
				BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
				BillboardGui.AlwaysOnTop = true
				TextLabel.Parent = BillboardGui
				TextLabel.BackgroundTransparency = 1
				TextLabel.Position = UDim2.new(0, 0, 0, -50)
				TextLabel.Size = UDim2.new(0, 100, 0, 100)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.TextSize = 20
				TextLabel.TextColor3 = Color3.new(1, 1, 1)
				TextLabel.TextStrokeTransparency = 0
				TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
				TextLabel.Text = 'Name: '..plr.Name
				TextLabel.ZIndex = 10
				local lcLoopFunc
				local addedFunc
				local teamChange
				addedFunc = plr.CharacterAdded:Connect(function()
					if ESPholder ~= nil and ESPholder.Parent ~= nil then
						lcLoopFunc:Disconnect()
						teamChange:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						Locate(plr)
						addedFunc:Disconnect()
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
					end
				end)
				teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
					if ESPholder ~= nil and ESPholder.Parent ~= nil then
						lcLoopFunc:Disconnect()
						addedFunc:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						Locate(plr)
						teamChange:Disconnect()
					else
						teamChange:Disconnect()
					end
				end)
				local lastUpdate = 0
				local lcLoop = function()
					if COREGUI:FindFirstChild(plr.Name..'_LC') then
						local now = tick()
						if now - lastUpdate >= 0.1 then
							lastUpdate = now
							if plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid") and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
								local pos = math.floor((getRoot(Players.LocalPlayer.Character).Position - getRoot(plr.Character).Position).magnitude)
								TextLabel.Text = 'Name: '..plr.Name..' | Health: '..round(plr.Character:FindFirstChildOfClass('Humanoid').Health, 1)..' | Studs: '..pos
							end
						end
					else
						teamChange:Disconnect()
						addedFunc:Disconnect()
						lcLoopFunc:Disconnect()
					end
				end
				lcLoopFunc = RunService.RenderStepped:Connect(lcLoop)
			end
		end
	end)
end
local bindsGUI = KeybindEditor
local awaitingInput = false
local keySelected = false
local function getKeyName(input)
	local str = tostring(input)
	if str:sub(1, 13) == "Enum.KeyCode." then
		return str:sub(14)
	end
	return str
end

function refreshbinds()
	if Holder_2 then
		Holder_2:ClearAllChildren()
		Holder_2.CanvasSize = UDim2.new(0, 0, 0, 10)
		for i = 1, #binds do
			local YSize = 25
			local Position = ((i * YSize) - YSize)
			local newbind = Example_2:Clone()
			newbind.Parent = Holder_2
			newbind.Visible = true
			newbind.Position = UDim2.new(0,0,0, Position + 5)
			table.insert(shade2,newbind)
			table.insert(shade2,newbind.Text)
			table.insert(text1,newbind.Text)
			table.insert(shade3,newbind.Text.Delete)
			table.insert(text2,newbind.Text.Delete)
			local input = tostring(binds[i].KEY)
			local key
			if input == 'RightClick' or input == 'LeftClick' then
				key = input
			else
				key = getKeyName(input)
			end
			if binds[i].TOGGLE then
				newbind.Text.Text = key.." > "..binds[i].COMMAND.." / "..binds[i].TOGGLE
			else
				newbind.Text.Text = key.." > "..binds[i].COMMAND.."  "..(binds[i].ISKEYUP and "(keyup)" or "(keydown)")
			end
			Holder_2.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newbind.Text.Delete.MouseButton1Click:Connect(function()
				unkeybind(binds[i].COMMAND,binds[i].KEY)
			end)
		end
	end
end
refreshbinds()
toggleOn = {}
function unkeybind(cmd,key)
	for i = #binds,1,-1 do
		if binds[i].COMMAND == cmd and binds[i].KEY == key then
			toggleOn[binds[i]] = nil
			table.remove(binds, i)
		end
	end
	refreshbinds()
	updatesaves()
	if key == 'RightClick' or key == 'LeftClick' then
		notify('Keybinds Updated','Unbinded '..key..' from '..cmd)
	else
		notify('Keybinds Updated','Unbinded '..key:sub(14)..' from '..cmd)
	end
end
PositionsFrame.Delete.MouseButton1Click:Connect(function()
	execCmd('cpos')
end)
function refreshwaypoints()
	if #WayPoints > 0 or #pWayPoints > 0 then
		PositionsHint:Destroy()
	end
	if Holder_4 then
		Holder_4:ClearAllChildren()
		Holder_4.CanvasSize = UDim2.new(0, 0, 0, 10)
		local YSize = 25
		local num = 1
		for i = 1, #WayPoints do
			local Position = ((num * YSize) - YSize)
			local newpoint = Example_4:Clone()
			newpoint.Parent = Holder_4
			newpoint.Visible = true
			newpoint.Position = UDim2.new(0,0,0, Position + 5)
			newpoint.Text.Text = WayPoints[i].NAME
			table.insert(shade2,newpoint)
			table.insert(shade2,newpoint.Text)
			table.insert(text1,newpoint.Text)
			table.insert(shade3,newpoint.Text.Delete)
			table.insert(text2,newpoint.Text.Delete)
			table.insert(shade3,newpoint.Text.TP)
			table.insert(text2,newpoint.Text.TP)
			Holder_4.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newpoint.Text.Delete.MouseButton1Click:Connect(function()
				execCmd('dpos '..WayPoints[i].NAME)
			end)
			newpoint.Text.TP.MouseButton1Click:Connect(function()
				execCmd("loadpos "..WayPoints[i].NAME)
			end)
			num = num+1
		end
		for i = 1, #pWayPoints do
			local Position = ((num * YSize) - YSize)
			local newpoint = Example_4:Clone()
			newpoint.Parent = Holder_4
			newpoint.Visible = true
			newpoint.Position = UDim2.new(0,0,0, Position + 5)
			newpoint.Text.Text = pWayPoints[i].NAME
			table.insert(shade2,newpoint)
			table.insert(shade2,newpoint.Text)
			table.insert(text1,newpoint.Text)
			table.insert(shade3,newpoint.Text.Delete)
			table.insert(text2,newpoint.Text.Delete)
			table.insert(shade3,newpoint.Text.TP)
			table.insert(text2,newpoint.Text.TP)
			Holder_4.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newpoint.Text.Delete.MouseButton1Click:Connect(function()
				execCmd('dpos '..pWayPoints[i].NAME)
			end)
			newpoint.Text.TP.MouseButton1Click:Connect(function()
				execCmd("loadpos "..pWayPoints[i].NAME)
			end)
			num = num+1
		end
	end
end
refreshwaypoints()
function refreshaliases()
	if #aliases > 0 then
		AliasHint:Destroy()
	end
	if Holder_3 then
		Holder_3:ClearAllChildren()
		Holder_3.CanvasSize = UDim2.new(0, 0, 0, 10)
		for i = 1, #aliases do
			local YSize = 25
			local Position = ((i * YSize) - YSize)
			local newalias = Example_3:Clone()
			newalias.Parent = Holder_3
			newalias.Visible = true
			newalias.Position = UDim2.new(0,0,0, Position + 5)
			newalias.Text.Text = aliases[i].CMD.." > "..aliases[i].ALIAS
			table.insert(shade2,newalias)
			table.insert(shade2,newalias.Text)
			table.insert(text1,newalias.Text)
			table.insert(shade3,newalias.Text.Delete)
			table.insert(text2,newalias.Text.Delete)
			Holder_3.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newalias.Text.Delete.MouseButton1Click:Connect(function()
				execCmd('removealias '..aliases[i].ALIAS)
			end)
		end
	end
end
local bindChosenKeyUp = false
BindTo.MouseButton1Click:Connect(function()
	awaitingInput = true
	BindTo.Text = 'Press something'
end)
BindTriggerSelect.MouseButton1Click:Connect(function()
	bindChosenKeyUp = not bindChosenKeyUp
	BindTriggerSelect.Text = bindChosenKeyUp and "KeyUp" or "KeyDown"
end)
newToggle = false
Cmdbar_3.Parent.Visible = false
On_2.MouseButton1Click:Connect(function()
	if newToggle == false then newToggle = true
		On_2.BackgroundTransparency = 0
		Cmdbar_3.Parent.Visible = true
		BindTriggerSelect.Visible = false
	else newToggle = false
		On_2.BackgroundTransparency = 1
		Cmdbar_3.Parent.Visible = false
		BindTriggerSelect.Visible = true
	end
end)
Add_2.MouseButton1Click:Connect(function()
	if keySelected then
		if string.find(Cmdbar_2.Text, "\\\\") or string.find(Cmdbar_3.Text, "\\\\") then
			notify('Keybind Error','Only use one backslash to keybind multiple commands into one keybind or command')
		else
			if newToggle and Cmdbar_3.Text ~= '' and Cmdbar_2.text ~= '' then
				addbind(Cmdbar_2.Text,keyPressed,false,Cmdbar_3.Text)
			elseif not newToggle and Cmdbar_2.text ~= '' then
				addbind(Cmdbar_2.Text,keyPressed,bindChosenKeyUp)
			else
				return
			end
			refreshbinds()
			updatesaves()
			if keyPressed == 'RightClick' or keyPressed == 'LeftClick' then
				notify('Keybinds Updated','Binded '..keyPressed..' to '..Cmdbar_2.Text..(newToggle and " / "..Cmdbar_3.Text or ""))
			else
				notify('Keybinds Updated','Binded '..keyPressed:sub(14)..' to '..Cmdbar_2.Text..(newToggle and " / "..Cmdbar_3.Text or ""))
			end
		end
	end
end)
Exit_2.MouseButton1Click:Connect(function()
	Cmdbar_2.Text = 'Command'
	Cmdbar_3.Text = 'Command 2'
	BindTo.Text = 'Click to bind'
	bindChosenKeyUp = false
	BindTriggerSelect.Text = "KeyDown"
	keySelected = false
	KeybindEditor:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
end)
function onInputBegan(input,gameProcessed)
	if awaitingInput then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keyPressed = tostring(input.KeyCode)
			BindTo.Text = keyPressed:sub(14)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			keyPressed = 'LeftClick'
			BindTo.Text = 'LeftClick'
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			keyPressed = 'RightClick'
			BindTo.Text = 'RightClick'
		end
		awaitingInput = false
		keySelected = true
	end
	if not gameProcessed and #binds > 0 then
		for i,v in pairs(binds) do
			if not v.ISKEYUP then
				if (input.UserInputType == Enum.UserInputType.Keyboard and v.KEY:lower()==tostring(input.KeyCode):lower()) or (input.UserInputType == Enum.UserInputType.MouseButton1 and v.KEY:lower()=='leftclick') or (input.UserInputType == Enum.UserInputType.MouseButton2 and v.KEY:lower()=='rightclick') then
					if v.TOGGLE then
						local isOn = toggleOn[v] == true
						toggleOn[v] = not isOn
						if isOn then
							execCmd(v.TOGGLE,Players.LocalPlayer)
						else
							execCmd(v.COMMAND,Players.LocalPlayer)
						end
					else
						execCmd(v.COMMAND,Players.LocalPlayer)
					end
				end
			end
		end
	end
end
function onInputEnded(input,gameProcessed)
	if not gameProcessed and #binds > 0 then
		for i,v in pairs(binds) do
			if v.ISKEYUP then
				if (input.UserInputType == Enum.UserInputType.Keyboard and v.KEY:lower()==tostring(input.KeyCode):lower()) or (input.UserInputType == Enum.UserInputType.MouseButton1 and v.KEY:lower()=='leftclick') or (input.UserInputType == Enum.UserInputType.MouseButton2 and v.KEY:lower()=='rightclick') then
					execCmd(v.COMMAND,Players.LocalPlayer)
				end
			end
		end
	end
end
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)
ClickTP.Select.MouseButton1Click:Connect(function()
	if keySelected then
		addbind('clicktp',keyPressed,bindChosenKeyUp)
		refreshbinds()
		updatesaves()
		if keyPressed == 'RightClick' or keyPressed == 'LeftClick' then
			notify('Keybinds Updated','Binded '..keyPressed..' to click tp')
		else
			notify('Keybinds Updated','Binded '..keyPressed:sub(14)..' to click tp')
		end
	end
end)
ClickDelete.Select.MouseButton1Click:Connect(function()
	if keySelected then
		addbind('clickdel',keyPressed,bindChosenKeyUp)
		refreshbinds()
		updatesaves()
		if keyPressed == 'RightClick' or keyPressed == 'LeftClick' then
			notify('Keybinds Updated','Binded '..keyPressed..' to click delete')
		else
			notify('Keybinds Updated','Binded '..keyPressed:sub(14)..' to click delete')
		end
	end
end)
function clicktpFunc()
	pcall(function()
		local character = Players.LocalPlayer.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart then
			humanoid.Sit = false
			wait(0.1)
		end
		local hipHeight = humanoid and humanoid.HipHeight > 0 and (humanoid.HipHeight + 1)
		local rootPart = getRoot(character)
		local rootPartPosition = rootPart.Position
		local hitPosition = IYMouse.Hit.Position
		local newCFrame = CFrame.new(
			hitPosition,
			Vector3.new(rootPartPosition.X, hitPosition.Y, rootPartPosition.Z)
		) * CFrame.Angles(0, math.pi, 0)
		rootPart.CFrame = newCFrame + Vector3.new(0, hipHeight or 4, 0)
		breakVelocity()
	end)
end
IYMouse.Button1Down:Connect(function()
	for i,v in pairs(binds) do
		if v.COMMAND == 'clicktp' then
			local input = v.KEY
			if input == 'RightClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and Players.LocalPlayer.Character then
				clicktpFunc()
			elseif input == 'LeftClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and Players.LocalPlayer.Character then
				clicktpFunc()
			elseif (function()
				local kn = getKeyName(input)
				local ok, kc = pcall(function() return Enum.KeyCode[kn] end)
				return ok and kc and UserInputService:IsKeyDown(kc)
			end)() and Players.LocalPlayer.Character then
				clicktpFunc()
			end
		elseif v.COMMAND == 'clickdel' then
			local input = v.KEY
			if input == 'RightClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				pcall(function() IYMouse.Target:Destroy() end)
			elseif input == 'LeftClick' and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				pcall(function() IYMouse.Target:Destroy() end)
			elseif (function()
				local kn = getKeyName(input)
				local ok, kc = pcall(function() return Enum.KeyCode[kn] end)
				return ok and kc and UserInputService:IsKeyDown(kc)
			end)() then
				pcall(function() IYMouse.Target:Destroy() end)
			end
		end
	end
end)
PluginsGUI = PluginEditor.background
function addPlugin(name)
	if name:lower() == 'plugin file name' or name:lower() == 'iy_fe.iy' or name == 'iy_fe' then
		notify('Plugin Error','Please enter a valid plugin')
	else
		local file
		local fileName
		if name:sub(-3) == '.iy' then
			pcall(function() file = readfile(name) end)
			fileName = name
		else
			pcall(function() file = readfile(name..'.iy') end)
			fileName = name..'.iy'
		end
		if file then
			if not FindInTable(PluginsTable, fileName) then
				table.insert(PluginsTable, fileName)
				LoadPlugin(fileName)
				refreshplugins()
				pcall(eventEditor.Refresh)
			else
				notify('Plugin Error','This plugin is already added')
			end
		else
			notify('Plugin Error','Cannot locate file "'..fileName..'". Is the file in the correct folder?')
		end
	end
end
function deletePlugin(name)
	local pName = name..'.iy'
	if name:sub(-3) == '.iy' then
		pName = name
	end
	for i = #cmds,1,-1 do
		if cmds[i].PLUGIN == pName then
			table.remove(cmds, i)
		end
	end
	for i,v in pairs(CMDsF:GetChildren()) do
		if v.Name == 'PLUGIN_'..pName then
			v:Destroy()
		end
	end
	for i,v in pairs(PluginsTable) do
		if v == pName then
			table.remove(PluginsTable, i)
			notify('Removed Plugin',pName..' was removed')
		end
	end
	IndexContents('',true)
	refreshplugins()
end
function refreshplugins(dontSave)
	if #PluginsTable > 0 then
		PluginsHint:Destroy()
	end
	if Holder_5 then
		Holder_5:ClearAllChildren()
		Holder_5.CanvasSize = UDim2.new(0, 0, 0, 10)
		for i,v in pairs(PluginsTable) do
			local pName = v
			local YSize = 25
			local Position = ((i * YSize) - YSize)
			local newplugin = Example_5:Clone()
			newplugin.Parent = Holder_5
			newplugin.Visible = true
			newplugin.Position = UDim2.new(0,0,0, Position + 5)
			newplugin.Text.Text = pName
			table.insert(shade2,newplugin)
			table.insert(shade2,newplugin.Text)
			table.insert(text1,newplugin.Text)
			table.insert(shade3,newplugin.Text.Delete)
			table.insert(text2,newplugin.Text.Delete)
			Holder_5.CanvasSize = UDim2.new(0,0,0, Position + 30)
			newplugin.Text.Delete.MouseButton1Click:Connect(function()
				deletePlugin(pName)
			end)
		end
		if not dontSave then
			updatesaves()
		end
	end
end
local PluginCache
function LoadPlugin(val,startup)
	local plugin
	function CatchedPluginLoad()
		plugin = loadfile(val)()
	end
	function handlePluginError(plerror)
		notify('Plugin Error','An error occurred with the plugin, "'..val..'" and it could not be loaded')
		if FindInTable(PluginsTable,val) then
			for i,v in pairs(PluginsTable) do
				if v == val then
					table.remove(PluginsTable,i)
				end
			end
		end
		updatesaves()
		print("Original Error: "..tostring(plerror))
		print("Plugin Error, stack traceback: "..tostring(debug.traceback()))
		plugin = nil
		return false
	end
	xpcall(CatchedPluginLoad, handlePluginError)
	if plugin ~= nil then
		if not startup then
			notify('Loaded Plugin',"Name: "..plugin["PluginName"].."\n".."Description: "..plugin["PluginDescription"])
		end
		addcmdtext('',val)
		addcmdtext(string.upper('--'..plugin["PluginName"]),val,plugin["PluginDescription"])
		if plugin["Commands"] then
			for i,v in pairs(plugin["Commands"]) do
				local cmdExt = ''
				local cmdName = i
				local function handleNames()
					cmdName = i
					if findCmd(cmdName..cmdExt) then
						if isNumber(cmdExt) then
							cmdExt = cmdExt+1
						else
							cmdExt = 1
						end
						handleNames()
					else
						cmdName = cmdName..cmdExt
					end
				end
				handleNames()
				addcmd(cmdName, v["Aliases"], v["Function"], val)
				if v["ListName"] then
					local newName = v.ListName
					local cmdNames = {i,unpack(v.Aliases)}
					for i,v in pairs(cmdNames) do
						newName = newName:gsub(v,v..cmdExt)
					end
					addcmdtext(newName,val,v["Description"])
				else
					addcmdtext(cmdName,val,v["Description"])
				end
			end
		end
		IndexContents('',true)
	elseif plugin == nil then
		plugin = nil
	end
end
function FindPlugins()
	if PluginsTable ~= nil and type(PluginsTable) == "table" then
		for i,v in pairs(PluginsTable) do
			LoadPlugin(v,true)
		end
		refreshplugins(true)
	end
end
AddPlugin.MouseButton1Click:Connect(function()
	addPlugin(PluginsGUI.FileName.Text)
end)
Exit_3.MouseButton1Click:Connect(function()
	PluginEditor:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
	FileName.Text = 'Plugin File Name'
end)
Add_3.MouseButton1Click:Connect(function()
	PluginEditor:TweenPosition(UDim2.new(0.5, -180, 0, 310), "InOut", "Quart", 0.5, true, nil)
end)
Plugins.MouseButton1Click:Connect(function()
	if writefileExploit() then
		PluginsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
		wait(0.5)
		SettingsHolder.Visible = false
	else
		notify('Incompatible Exploit','Your exploit is unable to use plugins (missing read/writefile)')
	end
end)
Close_4.MouseButton1Click:Connect(function()
	SettingsHolder.Visible = true
	PluginsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
end)
local TeleportCheck = false
Players.LocalPlayer.OnTeleport:Connect(function(State)
	if KeepInfYield and (not TeleportCheck) and queueteleport then
		TeleportCheck = true
		pcall(function()
			queueteleport("pcall(function() loadstring(readfile('Slate.lua'))() end)")
		end)
	end
end)
addcmd('addalias',{},function(args, speaker)
	if #args < 2 then return end
	local cmd = string.lower(args[1])
	local alias = string.lower(args[2])
	for i,v in pairs(cmds) do
		if v.NAME:lower()==cmd or FindInTable(v.ALIAS,cmd) then
			customAlias[alias] = v
			aliases[#aliases + 1] = {CMD = cmd, ALIAS = alias}
			notify('Aliases Modified',"Added "..alias.." as an alias to "..cmd)
			updatesaves()
			refreshaliases()
			break
		end
	end
end)
addcmd('removealias',{},function(args, speaker)
	if #args < 1 then return end
	local alias = string.lower(args[1])
	if customAlias[alias] then
		local cmd = customAlias[alias].NAME
		customAlias[alias] = nil
		for i = #aliases,1,-1 do
			if aliases[i].ALIAS == tostring(alias) then
				table.remove(aliases, i)
			end
		end
		notify('Aliases Modified',"Removed the alias "..alias.." from "..cmd)
		updatesaves()
		refreshaliases()
	end
end)
addcmd('clraliases',{},function(args, speaker)
	customAlias = {}
	aliases = {}
	notify('Aliases Modified','Removed all aliases')
	updatesaves()
	refreshaliases()
end)
addcmd('discord', {'support', 'help'}, function(args, speaker)
	if everyClipboard then
		toClipboard('https://discord.com/invite/78ZuWSq')
		notify('Discord Invite', 'Copied to clipboard!\ndiscord.gg/78ZuWSq')
	else
		notify('Discord Invite', 'discord.gg/78ZuWSq')
	end
	if httprequest then
		httprequest({
			Url = 'http://127.0.0.1:6463/rpc?v=1',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				Origin = 'https://discord.com'
			},
			Body = HttpService:JSONEncode({
				cmd = 'INVITE_BROWSER',
				nonce = HttpService:GenerateGUID(false),
				args = {code = '78ZuWSq'}
			})
		})
	end
end)
addcmd('keepslate', {'keepiy'}, function(args, speaker)
	if queueteleport then
		KeepInfYield = true
		notify('Keep Slate','Slate will now run after you teleport')
		updatesaves()
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing queue_on_teleport)')
	end
end)
addcmd('unkeepslate', {'unkeepiy'}, function(args, speaker)
	if queueteleport then
		KeepInfYield = false
		notify('Keep Slate','Slate will no longer run after you teleport')
		updatesaves()
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing queue_on_teleport)')
	end
end)
addcmd('togglekeepslate', {'togglekeepiy'}, function(args, speaker)
	if queueteleport then
		KeepInfYield = not KeepInfYield
		notify('Keep Slate', 'Keep Slate toggled to ' .. tostring(KeepInfYield))
		updatesaves()
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing queue_on_teleport)')
	end
end)
local canOpenServerinfo = true
addcmd('serverinfo',{'info','sinfo'},function(args, speaker)
	if not canOpenServerinfo then return end
	canOpenServerinfo = false
	task.spawn(function()
		local FRAME = Instance.new("Frame")
		local shadow = Instance.new("Frame")
		local PopupText = Instance.new("TextLabel")
		local Exit = Instance.new("TextButton")
		local ExitImage = Instance.new("ImageLabel")
		local background = Instance.new("Frame")
		local TextLabel = Instance.new("TextLabel")
		local TextLabel2 = Instance.new("TextLabel")
		local TextLabel3 = Instance.new("TextLabel")
		local Time = Instance.new("TextLabel")
		local appearance = Instance.new("TextLabel")
		local maxplayers = Instance.new("TextLabel")
		local name = Instance.new("TextLabel")
		local placeid = Instance.new("TextLabel")
		local playerid = Instance.new("TextLabel")
		local players = Instance.new("TextLabel")
		local CopyApp = Instance.new("TextButton")
		local CopyPlrID = Instance.new("TextButton")
		local CopyPlcID = Instance.new("TextButton")
		local CopyPlcName = Instance.new("TextButton")
		FRAME.Name = randomString()
		FRAME.Parent = ScaledHolder
		FRAME.Active = true
		FRAME.BackgroundTransparency = 1
		FRAME.Position = UDim2.new(0.5, -130, 0, -500)
		FRAME.Size = UDim2.new(0, 250, 0, 20)
		FRAME.ZIndex = 10
		dragGUI(FRAME)
		shadow.Name = "shadow"
		shadow.Parent = FRAME
		shadow.BackgroundColor3 = currentShade2
		shadow.BorderSizePixel = 0
		shadow.Size = UDim2.new(0, 250, 0, 20)
		shadow.ZIndex = 10
		table.insert(shade2,shadow)
		PopupText.Name = "PopupText"
		PopupText.Parent = shadow
		PopupText.BackgroundTransparency = 1
		PopupText.Size = UDim2.new(1, 0, 0.95, 0)
		PopupText.ZIndex = 10
		PopupText.Font = Enum.Font.SourceSans
		PopupText.TextSize = 14
		PopupText.Text = "Server"
		PopupText.TextColor3 = currentText1
		PopupText.TextWrapped = true
		table.insert(text1,PopupText)
		Exit.Name = "Exit"
		Exit.Parent = shadow
		Exit.BackgroundTransparency = 1
		Exit.Position = UDim2.new(1, -20, 0, 0)
		Exit.Size = UDim2.new(0, 20, 0, 20)
		Exit.Text = ""
		Exit.ZIndex = 10
		ExitImage.Parent = Exit
		ExitImage.BackgroundColor3 = Color3.new(1, 1, 1)
		ExitImage.BackgroundTransparency = 1
		ExitImage.Position = UDim2.new(0, 5, 0, 5)
		ExitImage.Size = UDim2.new(0, 10, 0, 10)
		ExitImage.Image = getcustomasset("slate/iy/assets/close.png")
		ExitImage.ZIndex = 10
		background.Name = "background"
		background.Parent = FRAME
		background.Active = true
		background.BackgroundColor3 = currentShade1
		background.BorderSizePixel = 0
		background.Position = UDim2.new(0, 0, 1, 0)
		background.Size = UDim2.new(0, 250, 0, 250)
		background.ZIndex = 10
		table.insert(shade1,background)
		TextLabel.Name = "Text Label"
		TextLabel.Parent = background
		TextLabel.BackgroundTransparency = 1
		TextLabel.BorderSizePixel = 0
		TextLabel.Position = UDim2.new(0, 5, 0, 80)
		TextLabel.Size = UDim2.new(0, 100, 0, 20)
		TextLabel.ZIndex = 10
		TextLabel.Font = Enum.Font.SourceSansLight
		TextLabel.TextSize = 20
		TextLabel.Text = "Run Time:"
		TextLabel.TextColor3 = currentText1
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,TextLabel)
		TextLabel2.Name = "Text Label2"
		TextLabel2.Parent = background
		TextLabel2.BackgroundTransparency = 1
		TextLabel2.BorderSizePixel = 0
		TextLabel2.Position = UDim2.new(0, 5, 0, 130)
		TextLabel2.Size = UDim2.new(0, 100, 0, 20)
		TextLabel2.ZIndex = 10
		TextLabel2.Font = Enum.Font.SourceSansLight
		TextLabel2.TextSize = 20
		TextLabel2.Text = "Statistics:"
		TextLabel2.TextColor3 = currentText1
		TextLabel2.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,TextLabel2)
		TextLabel3.Name = "Text Label3"
		TextLabel3.Parent = background
		TextLabel3.BackgroundTransparency = 1
		TextLabel3.BorderSizePixel = 0
		TextLabel3.Position = UDim2.new(0, 5, 0, 10)
		TextLabel3.Size = UDim2.new(0, 100, 0, 20)
		TextLabel3.ZIndex = 10
		TextLabel3.Font = Enum.Font.SourceSansLight
		TextLabel3.TextSize = 20
		TextLabel3.Text = "Local Player:"
		TextLabel3.TextColor3 = currentText1
		TextLabel3.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,TextLabel3)
		Time.Name = "Time"
		Time.Parent = background
		Time.BackgroundTransparency = 1
		Time.BorderSizePixel = 0
		Time.Position = UDim2.new(0, 5, 0, 105)
		Time.Size = UDim2.new(0, 100, 0, 20)
		Time.ZIndex = 10
		Time.Font = Enum.Font.SourceSans
		Time.FontSize = Enum.FontSize.Size14
		Time.Text = "LOADING"
		Time.TextColor3 = currentText1
		Time.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,Time)
		appearance.Name = "appearance"
		appearance.Parent = background
		appearance.BackgroundTransparency = 1
		appearance.BorderSizePixel = 0
		appearance.Position = UDim2.new(0, 5, 0, 55)
		appearance.Size = UDim2.new(0, 100, 0, 20)
		appearance.ZIndex = 10
		appearance.Font = Enum.Font.SourceSans
		appearance.FontSize = Enum.FontSize.Size14
		appearance.Text = "Appearance: LOADING"
		appearance.TextColor3 = currentText1
		appearance.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,appearance)
		maxplayers.Name = "maxplayers"
		maxplayers.Parent = background
		maxplayers.BackgroundTransparency = 1
		maxplayers.BorderSizePixel = 0
		maxplayers.Position = UDim2.new(0, 5, 0, 175)
		maxplayers.Size = UDim2.new(0, 100, 0, 20)
		maxplayers.ZIndex = 10
		maxplayers.Font = Enum.Font.SourceSans
		maxplayers.FontSize = Enum.FontSize.Size14
		maxplayers.Text = "LOADING"
		maxplayers.TextColor3 = currentText1
		maxplayers.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,maxplayers)
		name.Name = "name"
		name.Parent = background
		name.BackgroundTransparency = 1
		name.BorderSizePixel = 0
		name.Position = UDim2.new(0, 5, 0, 215)
		name.Size = UDim2.new(0, 240, 0, 30)
		name.ZIndex = 10
		name.Font = Enum.Font.SourceSans
		name.FontSize = Enum.FontSize.Size14
		name.Text = "Place Name: LOADING"
		name.TextColor3 = currentText1
		name.TextWrapped = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextYAlignment = Enum.TextYAlignment.Top
		table.insert(text1,name)
		placeid.Name = "placeid"
		placeid.Parent = background
		placeid.BackgroundTransparency = 1
		placeid.BorderSizePixel = 0
		placeid.Position = UDim2.new(0, 5, 0, 195)
		placeid.Size = UDim2.new(0, 100, 0, 20)
		placeid.ZIndex = 10
		placeid.Font = Enum.Font.SourceSans
		placeid.FontSize = Enum.FontSize.Size14
		placeid.Text = "Place ID: LOADING"
		placeid.TextColor3 = currentText1
		placeid.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,placeid)
		playerid.Name = "playerid"
		playerid.Parent = background
		playerid.BackgroundTransparency = 1
		playerid.BorderSizePixel = 0
		playerid.Position = UDim2.new(0, 5, 0, 35)
		playerid.Size = UDim2.new(0, 100, 0, 20)
		playerid.ZIndex = 10
		playerid.Font = Enum.Font.SourceSans
		playerid.FontSize = Enum.FontSize.Size14
		playerid.Text = "Player ID: LOADING"
		playerid.TextColor3 = currentText1
		playerid.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,playerid)
		players.Name = "players"
		players.Parent = background
		players.BackgroundTransparency = 1
		players.BorderSizePixel = 0
		players.Position = UDim2.new(0, 5, 0, 155)
		players.Size = UDim2.new(0, 100, 0, 20)
		players.ZIndex = 10
		players.Font = Enum.Font.SourceSans
		players.FontSize = Enum.FontSize.Size14
		players.Text = "LOADING"
		players.TextColor3 = currentText1
		players.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(text1,players)
		CopyApp.Name = "CopyApp"
		CopyApp.Parent = background
		CopyApp.BackgroundColor3 = currentShade2
		CopyApp.BorderSizePixel = 0
		CopyApp.Position = UDim2.new(0, 210, 0, 55)
		CopyApp.Size = UDim2.new(0, 35, 0, 20)
		CopyApp.Font = Enum.Font.SourceSans
		CopyApp.TextSize = 14
		CopyApp.Text = "Copy"
		CopyApp.TextColor3 = currentText1
		CopyApp.ZIndex = 10
		table.insert(shade2,CopyApp)
		table.insert(text1,CopyApp)
		CopyPlrID.Name = "CopyPlrID"
		CopyPlrID.Parent = background
		CopyPlrID.BackgroundColor3 = currentShade2
		CopyPlrID.BorderSizePixel = 0
		CopyPlrID.Position = UDim2.new(0, 210, 0, 35)
		CopyPlrID.Size = UDim2.new(0, 35, 0, 20)
		CopyPlrID.Font = Enum.Font.SourceSans
		CopyPlrID.TextSize = 14
		CopyPlrID.Text = "Copy"
		CopyPlrID.TextColor3 = currentText1
		CopyPlrID.ZIndex = 10
		table.insert(shade2,CopyPlrID)
		table.insert(text1,CopyPlrID)
		CopyPlcID.Name = "CopyPlcID"
		CopyPlcID.Parent = background
		CopyPlcID.BackgroundColor3 = currentShade2
		CopyPlcID.BorderSizePixel = 0
		CopyPlcID.Position = UDim2.new(0, 210, 0, 195)
		CopyPlcID.Size = UDim2.new(0, 35, 0, 20)
		CopyPlcID.Font = Enum.Font.SourceSans
		CopyPlcID.TextSize = 14
		CopyPlcID.Text = "Copy"
		CopyPlcID.TextColor3 = currentText1
		CopyPlcID.ZIndex = 10
		table.insert(shade2,CopyPlcID)
		table.insert(text1,CopyPlcID)
		CopyPlcName.Name = "CopyPlcName"
		CopyPlcName.Parent = background
		CopyPlcName.BackgroundColor3 = currentShade2
		CopyPlcName.BorderSizePixel = 0
		CopyPlcName.Position = UDim2.new(0, 210, 0, 215)
		CopyPlcName.Size = UDim2.new(0, 35, 0, 20)
		CopyPlcName.Font = Enum.Font.SourceSans
		CopyPlcName.TextSize = 14
		CopyPlcName.Text = "Copy"
		CopyPlcName.TextColor3 = currentText1
		CopyPlcName.ZIndex = 10
		table.insert(shade2,CopyPlcName)
		table.insert(text1,CopyPlcName)
		local SINFOGUI = background
		FRAME:TweenPosition(UDim2.new(0.5, -130, 0, 100), "InOut", "Quart", 0.5, true, nil)
		wait(0.5)
		Exit.MouseButton1Click:Connect(function()
			FRAME:TweenPosition(UDim2.new(0.5, -130, 0, -500), "InOut", "Quart", 0.5, true, nil)
			wait(0.6)
			FRAME:Destroy()
			canOpenServerinfo = true
		end)
		local Asset = MarketplaceService:GetProductInfo(PlaceId)
		SINFOGUI.name.Text = "Place Name: " .. Asset.Name
		SINFOGUI.playerid.Text = "Player ID: " ..speaker.UserId
		SINFOGUI.maxplayers.Text = Players.MaxPlayers.. " Players Max"
		SINFOGUI.placeid.Text = "Place ID: " ..PlaceId
		CopyApp.MouseButton1Click:Connect(function()
			toClipboard(speaker.CharacterAppearanceId)
		end)
		CopyPlrID.MouseButton1Click:Connect(function()
			toClipboard(speaker.UserId)
		end)
		CopyPlcID.MouseButton1Click:Connect(function()
			toClipboard(PlaceId)
		end)
		CopyPlcName.MouseButton1Click:Connect(function()
			toClipboard(Asset.Name)
		end)
		repeat
			players = Players:GetPlayers()
			SINFOGUI.players.Text = #players.. " Player(s)"
			SINFOGUI.appearance.Text = "Appearance: " ..speaker.CharacterAppearanceId
			local seconds = math.floor(workspace.DistributedGameTime)
			local minutes = math.floor(workspace.DistributedGameTime / 60)
			local hours = math.floor(workspace.DistributedGameTime / 60 / 60)
			local seconds = seconds - (minutes * 60)
			local minutes = minutes - (hours * 60)
			if hours < 1 then if minutes < 1 then
					SINFOGUI.Time.Text = seconds .. " Second(s)" else
					SINFOGUI.Time.Text = minutes .. " Minute(s), " .. seconds .. " Second(s)"
				end
			else
				SINFOGUI.Time.Text = hours .. " Hour(s), " .. minutes .. " Minute(s), " .. seconds .. " Second(s)"
			end
			wait(1)
		until SINFOGUI.Parent == nil
	end)
end)
addcmd("jobid", {}, function(args, speaker)
	toClipboard("roblox://placeId=" .. PlaceId .. "&gameInstanceId=" .. JobId)
end)
addcmd('notifyjobid',{},function(args, speaker)
	notify('JobId / PlaceId',JobId..' / '..PlaceId)
end)
addcmd('breakloops',{'break'},function(args, speaker)
	lastBreakTime = tick()
end)
addcmd('gametp',{'gameteleport'},function(args, speaker)
	TeleportService:Teleport(args[1])
end)
addcmd("rejoin", {"rj"}, function(args, speaker)
	if #Players:GetPlayers() <= 1 then
		Players.LocalPlayer:Kick("\nRejoining...")
		wait()
		TeleportService:Teleport(PlaceId, Players.LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Players.LocalPlayer)
	end
end)
addcmd("autorejoin", {"autorj"}, function(args, speaker)
	GuiService.ErrorMessageChanged:Connect(function()
		execCmd("rejoin")
	end)
	notify("Auto Rejoin", "Auto rejoin enabled")
end)
addcmd("serverhop", {"shop"}, function(args, speaker)
	local servers = {}
	local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
	local body = HttpService:JSONDecode(req)
	if body and body.data then
		for i, v in next, body.data do
			if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
				table.insert(servers, 1, v.id)
			end
		end
	end
	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], Players.LocalPlayer)
	else
		return notify("Serverhop", "Couldn't find a server.")
	end
end)
addcmd("exit", {}, function(args, speaker)
	game:Shutdown()
end)
local Noclipping = nil
addcmd('noclip',{},function(args, speaker)
	Clip = false
	wait(0.1)
	local NoclipLoop = function()
		if Clip == false and speaker.Character ~= nil then
			for _, child in pairs(speaker.Character:GetDescendants()) do
				if child:IsA("BasePart") and child.CanCollide == true and child.Name ~= floatName then
					child.CanCollide = false
				end
			end
		end
	end
	Noclipping = RunService.Stepped:Connect(NoclipLoop)
	if args[1] and args[1] == 'nonotify' then return end
	notify('Noclip','Noclip Enabled')
end)
addcmd('clip',{'unnoclip'},function(args, speaker)
	if Noclipping then
		Noclipping:Disconnect()
	end
	Clip = true
	if args[1] and args[1] == 'nonotify' then return end
	notify('Noclip','Noclip Disabled')
end)
addcmd('togglenoclip',{},function(args, speaker)
	if Clip then
		execCmd('noclip')
	else
		execCmd('clip')
	end
end)
FLYING = false
QEfly = true
iyflyspeed = 1
vehicleflyspeed = 1
function sFLY(vfly)
	local plr = Players.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
		humanoid = char:FindFirstChildOfClass("Humanoid")
	end
	if flyKeyDown or flyKeyUp then
		flyKeyDown:Disconnect()
		flyKeyUp:Disconnect()
	end
	local T = getRoot(char)
	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0
	local function FLY()
		FLYING = true
		local BG = Instance.new('BodyGyro')
		local BV = Instance.new('BodyVelocity')
		BG.P = 9e4
		BG.Parent = T
		BV.Parent = T
		BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.CFrame = T.CFrame
		BV.Velocity = Vector3.new(0, 0, 0)
		BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		task.spawn(function()
			repeat task.wait()
				local camera = workspace.CurrentCamera
				if not vfly and humanoid then
					humanoid.PlatformStand = true
				end
				if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
					SPEED = 50
				elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
					SPEED = 0
				end
				if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
					BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
					lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
				elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
					BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
				else
					BV.Velocity = Vector3.new(0, 0, 0)
				end
				BG.CFrame = camera.CFrame
			until not FLYING
			CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			SPEED = 0
			BG:Destroy()
			BV:Destroy()
			if humanoid then humanoid.PlatformStand = false end
		end)
	end
	flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = - (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = - (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = (vfly and vehicleflyspeed or iyflyspeed)
		elseif input.KeyCode == Enum.KeyCode.E and QEfly then
			CONTROL.Q = (vfly and vehicleflyspeed or iyflyspeed)*2
		elseif input.KeyCode == Enum.KeyCode.Q and QEfly then
			CONTROL.E = -(vfly and vehicleflyspeed or iyflyspeed)*2
		end
		pcall(function() camera.CameraType = Enum.CameraType.Track end)
	end)
	flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = 0
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = 0
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = 0
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = 0
		elseif input.KeyCode == Enum.KeyCode.E then
			CONTROL.Q = 0
		elseif input.KeyCode == Enum.KeyCode.Q then
			CONTROL.E = 0
		end
	end)
	FLY()
end
function NOFLY()
	FLYING = false
	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
	if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
		Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
	end
	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end
local velocityHandlerName = randomString()
local gyroHandlerName = randomString()
local mfly1
local mfly2
local unmobilefly = function(speaker)
	pcall(function()
		FLYING = false
		local root = getRoot(speaker.Character)
		root:FindFirstChild(velocityHandlerName):Destroy()
		root:FindFirstChild(gyroHandlerName):Destroy()
		speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
		mfly1:Disconnect()
		mfly2:Disconnect()
	end)
end
local mobilefly = function(speaker, vfly)
	unmobilefly(speaker)
	FLYING = true
	local root = getRoot(speaker.Character)
	local camera = workspace.CurrentCamera
	local v3none = Vector3.new()
	local v3zero = Vector3.new(0, 0, 0)
	local v3inf = Vector3.new(9e9, 9e9, 9e9)
	local controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	local bv = Instance.new("BodyVelocity")
	bv.Name = velocityHandlerName
	bv.Parent = root
	bv.MaxForce = v3zero
	bv.Velocity = v3zero
	local bg = Instance.new("BodyGyro")
	bg.Name = gyroHandlerName
	bg.Parent = root
	bg.MaxTorque = v3inf
	bg.P = 1000
	bg.D = 50
	mfly1 = speaker.CharacterAdded:Connect(function()
		local bv = Instance.new("BodyVelocity")
		bv.Name = velocityHandlerName
		bv.Parent = root
		bv.MaxForce = v3zero
		bv.Velocity = v3zero
		local bg = Instance.new("BodyGyro")
		bg.Name = gyroHandlerName
		bg.Parent = root
		bg.MaxTorque = v3inf
		bg.P = 1000
		bg.D = 50
	end)
	mfly2 = RunService.RenderStepped:Connect(function()
		root = getRoot(speaker.Character)
		camera = workspace.CurrentCamera
		if speaker.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
			local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
			local VelocityHandler = root:FindFirstChild(velocityHandlerName)
			local GyroHandler = root:FindFirstChild(gyroHandlerName)
			VelocityHandler.MaxForce = v3inf
			GyroHandler.MaxTorque = v3inf
			if not vfly then humanoid.PlatformStand = true end
			GyroHandler.CFrame = camera.CoordinateFrame
			VelocityHandler.Velocity = v3none
			local direction = controlModule:GetMoveVector()
			if direction.X > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.X < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.Z > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
			if direction.Z < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((vfly and vehicleflyspeed or iyflyspeed) * 50))
			end
		end
	end)
end
addcmd('fly',{},function(args, speaker)
	if not IsOnMobile then
		NOFLY()
		wait()
		sFLY()
	else
		mobilefly(speaker)
	end
	if args[1] and isNumber(args[1]) then
		iyflyspeed = args[1]
	end
end)
addcmd('flyspeed',{'flysp'},function(args, speaker)
	local speed = args[1] or 1
	if isNumber(speed) then
		iyflyspeed = speed
	end
end)
addcmd('unfly',{'nofly','novfly','unvehiclefly','novehiclefly','unvfly'},function(args, speaker)
	if not IsOnMobile then NOFLY() else unmobilefly(speaker) end
end)
addcmd('vfly',{'vehiclefly'},function(args, speaker)
	if not IsOnMobile then
		NOFLY()
		wait()
		sFLY(true)
	else
		mobilefly(speaker, true)
	end
	if args[1] and isNumber(args[1]) then
		vehicleflyspeed = args[1]
	end
end)
addcmd('togglevfly',{},function(args, speaker)
	if FLYING then
		if not IsOnMobile then NOFLY() else unmobilefly(speaker) end
	else
		if not IsOnMobile then sFLY(true) else mobilefly(speaker, true) end
	end
end)
addcmd('vflyspeed',{'vflysp','vehicleflyspeed','vehicleflysp'},function(args, speaker)
	local speed = args[1] or 1
	if isNumber(speed) then
		vehicleflyspeed = speed
	end
end)
addcmd('qefly',{'flyqe'},function(args, speaker)
	if args[1] == 'false' then
		QEfly = false
	else
		QEfly = true
	end
end)
addcmd('togglefly',{},function(args, speaker)
	if FLYING then
		if not IsOnMobile then NOFLY() else unmobilefly(speaker) end
	else
		if not IsOnMobile then sFLY() else mobilefly(speaker) end
	end
end)
CFspeed = 50
addcmd('cframefly', {'cfly'}, function(args, speaker)
	if args[1] and isNumber(args[1]) then
		CFspeed = args[1]
	end
	speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
	local Head = speaker.Character:WaitForChild("Head")
	Head.Anchored = true
	if CFloop then CFloop:Disconnect() end
	CFloop = RunService.Heartbeat:Connect(function(deltaTime)
		local moveDirection = speaker.Character:FindFirstChildOfClass('Humanoid').MoveDirection * (CFspeed * deltaTime)
		local headCFrame = Head.CFrame
		local camera = workspace.CurrentCamera
		local cameraCFrame = camera.CFrame
		local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
		cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
		local cameraPosition = cameraCFrame.Position
		local headPosition = headCFrame.Position
		local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
		Head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
	end)
end)
addcmd('uncframefly',{'uncfly'},function(args, speaker)
	if CFloop then
		CFloop:Disconnect()
		speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
		local Head = speaker.Character:WaitForChild("Head")
		Head.Anchored = false
	end
end)
addcmd('cframeflyspeed',{'cflyspeed'},function(args, speaker)
	if isNumber(args[1]) then
		CFspeed = args[1]
	end
end)
Floating = false
floatName = randomString()
addcmd('float', {'platform'},function(args, speaker)
	Floating = true
	local pchar = speaker.Character
	if pchar and not pchar:FindFirstChild(floatName) then
		task.spawn(function()
			local root = getRoot(pchar)
			if not root then return end
			local Float = Instance.new('Part')
			Float.Name = floatName
			Float.Parent = pchar
			Float.Transparency = 1
			Float.Size = Vector3.new(4, 0.5, 4)
			Float.Anchored = true
			local fixedElevation = root.Position.Y - 3.1
			local isHoldingQ = false
			local isHoldingE = false
			local floatSpeed = 24.0

			Float.CFrame = CFrame.new(root.Position.X, fixedElevation, root.Position.Z)
			notify('Float','Float Enabled (Hold E = Up, Hold Q = Down)')

			qDown = IYMouse.KeyDown:Connect(function(KEY)
				if KEY == 'q' then isHoldingQ = true end
				if KEY == 'e' then isHoldingE = true end
			end)
			qUp = IYMouse.KeyUp:Connect(function(KEY)
				if KEY == 'q' then isHoldingQ = false end
				if KEY == 'e' then isHoldingE = false end
			end)

			floatDied = speaker.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
				if FloatingFunc then FloatingFunc:Disconnect() end
				if Float and Float.Parent then Float:Destroy() end
				if qDown then qDown:Disconnect() end
				if qUp then qUp:Disconnect() end
				if floatDied then floatDied:Disconnect() end
			end)
			local FloatPadLoop = (function(dt)
				local delta = dt or 0.016
				if isHoldingE and not isHoldingQ then
					fixedElevation = fixedElevation + (floatSpeed * delta)
				elseif isHoldingQ and not isHoldingE then
					fixedElevation = fixedElevation - (floatSpeed * delta)
				end

				local r = getRoot(pchar)
				if pchar:FindFirstChild(floatName) and r then
					Float.CFrame = CFrame.new(r.Position.X, fixedElevation, r.Position.Z)
				else
					if FloatingFunc then FloatingFunc:Disconnect() end
					if Float and Float.Parent then Float:Destroy() end
					if qDown then qDown:Disconnect() end
					if qUp then qUp:Disconnect() end
					if floatDied then floatDied:Disconnect() end
				end
			end)
			FloatingFunc = RunService.Heartbeat:Connect(FloatPadLoop)
		end)
	end
end)
addcmd('unfloat',{'nofloat','unplatform','noplatform'},function(args, speaker)
	Floating = false
	local pchar = speaker.Character
	notify('Float','Float Disabled')
	if pchar:FindFirstChild(floatName) then
		pchar:FindFirstChild(floatName):Destroy()
	end
	if floatDied then
		FloatingFunc:Disconnect()
		qUp:Disconnect()
		eUp:Disconnect()
		qDown:Disconnect()
		eDown:Disconnect()
		floatDied:Disconnect()
	end
end)
addcmd('togglefloat',{},function(args, speaker)
	if Floating then
		execCmd('unfloat')
	else
		execCmd('float')
	end
end)
swimming = false
local oldgrav = workspace.Gravity
local swimbeat = nil
addcmd('swim',{},function(args, speaker)
	if not swimming and speaker and speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
		oldgrav = workspace.Gravity
		workspace.Gravity = 0
		local swimDied = function()
			workspace.Gravity = oldgrav
			swimming = false
		end
		local Humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
		gravReset = Humanoid.Died:Connect(swimDied)
		local enums = Enum.HumanoidStateType:GetEnumItems()
		table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
		for i, v in pairs(enums) do
			Humanoid:SetStateEnabled(v, false)
		end
		Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
		swimbeat = RunService.Heartbeat:Connect(function()
			pcall(function()
				getRoot(speaker.Character).Humanoid.RootPart.Velocity = ((Humanoid.MoveDirection ~= Vector3.new() or UserInputService:IsKeyDown(Enum.KeyCode.Space)) and getRoot(speaker.Character).Humanoid.RootPart.Velocity or Vector3.new())
			end)
		end)
		swimming = true
	end
end)
addcmd('unswim',{'noswim'},function(args, speaker)
	if speaker and speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
		workspace.Gravity = oldgrav
		swimming = false
		if gravReset then
			gravReset:Disconnect()
		end
		if swimbeat ~= nil then
			swimbeat:Disconnect()
			swimbeat = nil
		end
		local Humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
		local enums = Enum.HumanoidStateType:GetEnumItems()
		table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
		for i, v in pairs(enums) do
			Humanoid:SetStateEnabled(v, true)
		end
	end
end)
addcmd('toggleswim',{},function(args, speaker)
	if swimming then
		execCmd('unswim')
	else
		execCmd('swim')
	end
end)
addcmd('setwaypoint',{'swp','setwp','spos','saveposition','savepos'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if getRoot(speaker.Character) then
		notify('Modified Waypoints',"Created waypoint: "..getstring(1, args))
		local torso = getRoot(speaker.Character)
		WayPoints[#WayPoints + 1] = {NAME = WPName, COORD = {math.floor(torso.Position.X), math.floor(torso.Position.Y), math.floor(torso.Position.Z)}, GAME = PlaceId}
		if AllWaypoints ~= nil then
			AllWaypoints[#AllWaypoints + 1] = {NAME = WPName, COORD = {math.floor(torso.Position.X), math.floor(torso.Position.Y), math.floor(torso.Position.Z)}, GAME = PlaceId}
		end
	end
	refreshwaypoints()
	updatesaves()
end)
addcmd('waypointpos',{'wpp','setwaypointposition','setpos','setwaypoint','setwaypointpos'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if getRoot(speaker.Character) then
		notify('Modified Waypoints',"Created waypoint: "..getstring(1, args))
		WayPoints[#WayPoints + 1] = {NAME = WPName, COORD = {args[2], args[3], args[4]}, GAME = PlaceId}
		if AllWaypoints ~= nil then
			AllWaypoints[#AllWaypoints + 1] = {NAME = WPName, COORD = {args[2], args[3], args[4]}, GAME = PlaceId}
		end
	end
	refreshwaypoints()
	updatesaves()
end)
addcmd('waypoints',{'positions'},function(args, speaker)
	if SettingsOpen == false then SettingsOpen = true
		Settings:TweenPosition(UDim2.new(0, 0, 0, 45), "InOut", "Quart", 0.5, true, nil)
		CMDsF.Visible = false
	end
	KeybindsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
	AliasesFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
	PluginsFrame:TweenPosition(UDim2.new(0, 0, 0, 175), "InOut", "Quart", 0.5, true, nil)
	PositionsFrame:TweenPosition(UDim2.new(0, 0, 0, 0), "InOut", "Quart", 0.5, true, nil)
	wait(0.5)
	SettingsHolder.Visible = false
	maximizeHolder()
end)
waypointParts = {}
addcmd('showwaypoints',{'showwp','showwps'},function(args, speaker)
	execCmd('hidewaypoints')
	wait()
	for i,_ in pairs(WayPoints) do
		local x = WayPoints[i].COORD[1]
		local y = WayPoints[i].COORD[2]
		local z = WayPoints[i].COORD[3]
		local part = Instance.new("Part")
		part.Size = Vector3.new(5,5,5)
		part.CFrame = CFrame.new(x,y,z)
		part.Parent = workspace
		part.Anchored = true
		part.CanCollide = false
		table.insert(waypointParts,part)
		local view = Instance.new("BoxHandleAdornment")
		view.Adornee = part
		view.AlwaysOnTop = true
		view.ZIndex = 10
		view.Size = part.Size
		view.Parent = part
	end
	for i,v in pairs(pWayPoints) do
		local view = Instance.new("BoxHandleAdornment")
		view.Adornee = pWayPoints[i].COORD[1]
		view.AlwaysOnTop = true
		view.ZIndex = 10
		view.Size = pWayPoints[i].COORD[1].Size
		view.Parent = pWayPoints[i].COORD[1]
		table.insert(waypointParts,view)
	end
end)
addcmd('hidewaypoints',{'hidewp','hidewps'},function(args, speaker)
	for i,v in pairs(waypointParts) do
		v:Destroy()
	end
	waypointParts = {}
end)
addcmd('waypoint',{'wp','lpos','loadposition','loadpos'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				local x = WayPoints[i].COORD[1]
				local y = WayPoints[i].COORD[2]
				local z = WayPoints[i].COORD[3]
				getRoot(speaker.Character).CFrame = CFrame.new(x,y,z)
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				getRoot(speaker.Character).CFrame = CFrame.new(pWayPoints[i].COORD[1].Position)
			end
		end
	end
end)
tweenSpeed = 1
addcmd('tweenspeed',{'tspeed'},function(args, speaker)
	local newSpeed = args[1] or 1
	if tonumber(newSpeed) then
		tweenSpeed = tonumber(newSpeed)
	end
end)
addcmd('tweenwaypoint',{'twp'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			local x = WayPoints[i].COORD[1]
			local y = WayPoints[i].COORD[2]
			local z = WayPoints[i].COORD[3]
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(x,y,z)}):Play()
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pWayPoints[i].COORD[1].Position)}):Play()
			end
		end
	end
end)
addcmd('walktowaypoint',{'wtwp'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			local x = WayPoints[i].COORD[1]
			local y = WayPoints[i].COORD[2]
			local z = WayPoints[i].COORD[3]
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				speaker.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(x,y,z)
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				speaker.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(pWayPoints[i].COORD[1].Position)
			end
		end
	end
end)
addcmd('deletewaypoint',{'dwp','dpos','deleteposition','deletepos'},function(args, speaker)
	for i,v in pairs(WayPoints) do
		if v.NAME:lower() == tostring(getstring(1, args)):lower() then
			notify('Modified Waypoints',"Deleted waypoint: " .. v.NAME)
			table.remove(WayPoints, i)
		end
	end
	if AllWaypoints ~= nil and #AllWaypoints > 0 then
		for i,v in pairs(AllWaypoints) do
			if v.NAME:lower() == tostring(getstring(1, args)):lower() then
				if not v.GAME or v.GAME == PlaceId then
					table.remove(AllWaypoints, i)
				end
			end
		end
	end
	for i,v in pairs(pWayPoints) do
		if v.NAME:lower() == tostring(getstring(1, args)):lower() then
			notify('Modified Waypoints',"Deleted waypoint: " .. v.NAME)
			table.remove(pWayPoints, i)
		end
	end
	refreshwaypoints()
	updatesaves()
end)
addcmd('clearwaypoints',{'cwp','clearpositions','cpos','clearpos'},function(args, speaker)
	WayPoints = {}
	pWayPoints = {}
	refreshwaypoints()
	updatesaves()
	AllWaypoints = {}
	notify('Modified Waypoints','Removed all waypoints')
end)
addcmd('cleargamewaypoints',{'cgamewp'},function(args, speaker)
	for i,v in pairs(WayPoints) do
		if v.GAME == PlaceId then
			table.remove(WayPoints, i)
		end
	end
	if AllWaypoints ~= nil and #AllWaypoints > 0 then
		for i,v in pairs(AllWaypoints) do
			if v.GAME == PlaceId then
				table.remove(AllWaypoints, i)
			end
		end
	end
	for i,v in pairs(pWayPoints) do
		if v.GAME == PlaceId then
			table.remove(pWayPoints, i)
		end
	end
	refreshwaypoints()
	updatesaves()
	notify('Modified Waypoints','Deleted game waypoints')
end)
local coreGuiTypeNames = {
	["inventory"] = Enum.CoreGuiType.Backpack,
	["leaderboard"] = Enum.CoreGuiType.PlayerList,
	["emotes"] = Enum.CoreGuiType.EmotesMenu
}
for _, enumItem in ipairs(Enum.CoreGuiType:GetEnumItems()) do
	coreGuiTypeNames[enumItem.Name:lower()] = enumItem
end
addcmd('enable',{},function(args, speaker)
	local input = args[1] and args[1]:lower()
	if input then
		if input == "reset" then
			StarterGui:SetCore("ResetButtonCallback", true)
		else
			local coreGuiType = coreGuiTypeNames[input]
			if coreGuiType then
				StarterGui:SetCoreGuiEnabled(coreGuiType, true)
			end
		end
	end
end)
addcmd('disable',{},function(args, speaker)
	local input = args[1] and args[1]:lower()
	if input then
		if input == "reset" then
			StarterGui:SetCore("ResetButtonCallback", false)
		else
			local coreGuiType = coreGuiTypeNames[input]
			if coreGuiType then
				StarterGui:SetCoreGuiEnabled(coreGuiType, false)
			end
		end
	end
end)
local invisGUIS = {}
addcmd('showguis',{},function(args, speaker)
	for i,v in pairs(PlayerGui:GetDescendants()) do
		if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and not v.Visible then
			v.Visible = true
			if not FindInTable(invisGUIS,v) then
				table.insert(invisGUIS,v)
			end
		end
	end
end)
addcmd('unshowguis',{},function(args, speaker)
	for i,v in pairs(invisGUIS) do
		v.Visible = false
	end
	invisGUIS = {}
end)
local hiddenGUIS = {}
addcmd('hideguis',{},function(args, speaker)
	for i,v in pairs(PlayerGui:GetDescendants()) do
		if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ScrollingFrame")) and v.Visible then
			v.Visible = false
			if not FindInTable(hiddenGUIS,v) then
				table.insert(hiddenGUIS,v)
			end
		end
	end
end)
addcmd('unhideguis',{},function(args, speaker)
	for i,v in pairs(hiddenGUIS) do
		v.Visible = true
	end
	hiddenGUIS = {}
end)
function deleteGuisAtPos()
	pcall(function()
		local guisAtPosition = PlayerGui:GetGuiObjectsAtPosition(IYMouse.X, IYMouse.Y)
		for _, gui in pairs(guisAtPosition) do
			if gui.Visible == true then
				gui:Destroy()
			end
		end
	end)
end
local deleteGuiInput
addcmd('guidelete',{},function(args, speaker)
	deleteGuiInput = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent then
			if input.KeyCode == Enum.KeyCode.Backspace then
				deleteGuisAtPos()
			end
		end
	end)
	notify('GUI Delete Enabled','Hover over a GUI and press backspace to delete it')
end)
addcmd('unguidelete',{'noguidelete'},function(args, speaker)
	if deleteGuiInput then deleteGuiInput:Disconnect() end
	notify('GUI Delete Disabled','GUI backspace delete has been disabled')
end)
local wasStayOpen = StayOpen
addcmd('hideiy',{},function(args, speaker)
	isHidden = true
	wasStayOpen = StayOpen
	if StayOpen == true then
		StayOpen = false
		On.BackgroundTransparency = 1
	end
	minimizeNum = 0
	minimizeHolder()
	if not (args[1] and tostring(args[1]) == 'nonotify') then notify('IY Hidden','You can press the prefix key to access the command bar') end
end)
addcmd('showiy',{'unhideiy'},function(args, speaker)
	isHidden = false
	minimizeNum = -20
	if wasStayOpen then
		maximizeHolder()
		StayOpen = true
		On.BackgroundTransparency = 0
	else
		minimizeHolder()
	end
end)
addcmd('rec', {'record'}, function(args, speaker)
	return COREGUI:ToggleRecording()
end)
addcmd('screenshot', {'scrnshot'}, function(args, speaker)
	return COREGUI:TakeScreenshot()
end)
addcmd('togglefs', {'togglefullscreen'}, function(args, speaker)
	return GuiService:ToggleFullscreen()
end)
addcmd('inspect', {'examine'}, function(args, speaker)
	for _, v in ipairs(getPlayer(args[1], speaker)) do
		GuiService:CloseInspectMenu()
		GuiService:InspectPlayerFromUserId(Players[v].UserId)
	end
end)
addcmd("savegame", {"saveplace"}, function(args, speaker)
	if saveinstance then
		notify("Loading", "Downloading game. This will take a while")
		saveinstance()
		notify("Game Saved", "Saved place to the workspace folder within your exploit folder.")
	else
		notify("Incompatible Exploit", "Your exploit does not support this command (missing saveinstance)")
	end
end)
addcmd("clearerror", {"clearerrors"}, function(args, speaker)
    GuiService:ClearError()
end)
addcmd("antigameplaypaused", {}, function(args, speaker)
    pcall(function() networkPaused:Disconnect() end)
    networkPaused = COREGUI.RobloxGui.ChildAdded:Connect(function(obj)
        if obj.Name == "CoreScripts/NetworkPause" then
            obj:Destroy()
        end
    end)
    COREGUI.RobloxGui["CoreScripts/NetworkPause"]:Destroy()
end)
addcmd("unantigameplaypaused", {}, function(args, speaker)
    networkPaused:Disconnect()
end)
addcmd('clientantikick',{'antikick'},function(args, speaker)
	if not hookmetamethod then
		return notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
	end
	local LocalPlayer = Players.LocalPlayer
	local oldhmmi
	local oldhmmnc
	local oldKickFunction
	if hookfunction then
		oldKickFunction = hookfunction(LocalPlayer.Kick, function() end)
	end
	oldhmmi = hookmetamethod(game, "__index", function(self, method)
		if self == LocalPlayer and method:lower() == "kick" then
			return error("Expected ':' not '.' calling member function Kick", 2)
		end
		return oldhmmi(self, method)
	end)
	oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
		if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
			return
		end
		return oldhmmnc(self, ...)
	end)
	notify('Client Antikick','Client anti kick is now active (only effective on localscript kick)')
end)
allow_rj = true
addcmd('clientantiteleport',{'antiteleport'},function(args, speaker)
	if not hookmetamethod then
		return notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
	end
	local TeleportService = TeleportService
	local oldhmmi
	local oldhmmnc
	oldhmmi = hookmetamethod(game, "__index", function(self, method)
		if self == TeleportService then
			if method:lower() == "teleport" then
				return error("Expected ':' not '.' calling member function Kick", 2)
			elseif method == "TeleportToPlaceInstance" then
				return error("Expected ':' not '.' calling member function TeleportToPlaceInstance", 2)
			end
		end
		return oldhmmi(self, method)
	end)
	oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
		if self == TeleportService and getnamecallmethod():lower() == "teleport" or getnamecallmethod() == "TeleportToPlaceInstance" then
			return
		end
		return oldhmmnc(self, ...)
	end)
	notify('Client AntiTP','Client anti teleport is now active (only effective on localscript teleport)')
end)
addcmd('allowrejoin',{'allowrj'},function(args, speaker)
	if args[1] and args[1] == 'false' then
		allow_rj = false
		notify('Client AntiTP','Allow rejoin set to false')
	else
		allow_rj = true
		notify('Client AntiTP','Allow rejoin set to true')
	end
end)
addcmd("cancelteleport", {"canceltp"}, function(args, speaker)
	TeleportService:TeleportCancel()
end)
addcmd("volume",{ "vol"}, function(args, speaker)
	UserSettings():GetService("UserGameSettings").MasterVolume = args[1]/10
end)
addcmd("antilag", {"boostfps", "lowgraphics"}, function(args, speaker)
	local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.FogStart = 9e9
	settings().Rendering.QualityLevel = 1
	for _, v in pairs(game:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CastShadow = false
			v.Material = "Plastic"
			v.Reflectance = 0
			v.BackSurface = "SmoothNoOutlines"
			v.BottomSurface = "SmoothNoOutlines"
			v.FrontSurface = "SmoothNoOutlines"
			v.LeftSurface = "SmoothNoOutlines"
			v.RightSurface = "SmoothNoOutlines"
			v.TopSurface = "SmoothNoOutlines"
		elseif v:IsA("Decal") then
			v.Transparency = 1
			v.Texture = ""
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Lifetime = NumberRange.new(0)
		end
	end
	for _, v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") then
			v.Enabled = false
		end
	end
	workspace.DescendantAdded:Connect(function(child)
		task.spawn(function()
			if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
				RunService.Heartbeat:Wait()
				child:Destroy()
			elseif child:IsA("BasePart") then
				child.CastShadow = false
			end
		end)
	end)
end)
addcmd("setfpscap", {"fpscap", "maxfps"}, function(args, speaker)
	if fpscaploop then
		task.cancel(fpscaploop)
		fpscaploop = nil
	end
	local fpsCap = 60
	local num = tonumber(args[1]) or 1e6
	if num == "none" then
		return
	elseif num > 0 then
		fpsCap = num
	else
		return notify("Invalid argument", "Please provide a number above 0 or 'none'.")
	end
	if setfpscap and type(setfpscap) == "function" then
		setfpscap(fpsCap)
	else
		fpscaploop = task.spawn(function()
			local timer = os.clock()
			while true do
				if os.clock() >= timer + 1 / fpsCap then
					timer = os.clock()
					task.wait()
				end
			end
		end)
	end
end)
addcmd('notify',{},function(args, speaker)
	notify(getstring(1, args))
end)
addcmd('lastcommand',{'lastcmd'},function(args, speaker)
	if cmdHistory[1]:sub(1,11) ~= 'lastcommand' and cmdHistory[1]:sub(1,7) ~= 'lastcmd' then
		execCmd(cmdHistory[1])
	end
end)
addcmd('esp',{},function(args, speaker)
	if not CHMSenabled then
		ESPenabled = true
		for i,v in pairs(Players:GetPlayers()) do
			if v.Name ~= speaker.Name then
				ESP(v)
			end
		end
	else
		notify('ESP','Disable chams (nochams) before using esp')
	end
end)
addcmd('espteam',{},function(args, speaker)
	if not CHMSenabled then
		ESPenabled = true
		for i,v in pairs(Players:GetPlayers()) do
			if v.Name ~= speaker.Name then
				ESP(v, true)
			end
		end
	else
		notify('ESP','Disable chams (nochams) before using esp')
	end
end)
addcmd('noesp',{'unesp','unespteam'},function(args, speaker)
	ESPenabled = false
	for i,c in pairs(COREGUI:GetChildren()) do
		if string.sub(c.Name, -4) == '_ESP' then
			c:Destroy()
		end
	end
end)
addcmd("esptransparency", {}, function(args, speaker)
    espTransparency = tonumber(args[1]) or 0.3
    if ESPenabled then execCmd("esp") end
    if CHMSenabled then execCmd("chams") end
    updatesaves()
end)
local espParts = {}
local partEspTrigger = nil
function partAdded(part)
	if #espParts > 0 then
		if FindInTable(espParts,part.Name:lower()) then
			local a = Instance.new("BoxHandleAdornment")
			a.Name = part.Name:lower().."_PESP"
			a.Parent = part
			a.Adornee = part
			a.AlwaysOnTop = true
			a.ZIndex = 0
			a.Size = part.Size
			a.Transparency = espTransparency
			a.Color = BrickColor.new("Lime green")
		end
	else
		partEspTrigger:Disconnect()
		partEspTrigger = nil
	end
end
addcmd('partesp',{},function(args, speaker)
	local partEspName = getstring(1, args):lower()
	if not FindInTable(espParts,partEspName) then
		table.insert(espParts,partEspName)
		for i,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and v.Name:lower() == partEspName then
				local a = Instance.new("BoxHandleAdornment")
				a.Name = partEspName.."_PESP"
				a.Parent = v
				a.Adornee = v
				a.AlwaysOnTop = true
				a.ZIndex = 0
				a.Size = v.Size
				a.Transparency = espTransparency
				a.Color = BrickColor.new("Lime green")
			end
		end
	end
	if partEspTrigger == nil then
		partEspTrigger = workspace.DescendantAdded:Connect(partAdded)
	end
end)
addcmd('unpartesp',{'nopartesp'},function(args, speaker)
	if args[1] then
		local partEspName = getstring(1, args):lower()
		if FindInTable(espParts,partEspName) then
			table.remove(espParts, GetInTable(espParts, partEspName))
		end
		for i,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BoxHandleAdornment") and v.Name == partEspName..'_PESP' then
				v:Destroy()
			end
		end
	else
		partEspTrigger:Disconnect()
		partEspTrigger = nil
		espParts = {}
		for i,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BoxHandleAdornment") and v.Name:sub(-5) == '_PESP' then
				v:Destroy()
			end
		end
	end
end)
addcmd('chams',{},function(args, speaker)
	if not ESPenabled then
		CHMSenabled = true
		for i,v in pairs(Players:GetPlayers()) do
			if v.Name ~= speaker.Name then
				CHMS(v)
			end
		end
	else
		notify('Chams','Disable ESP (noesp) before using chams')
	end
end)
addcmd('nochams',{'unchams'},function(args, speaker)
	CHMSenabled = false
	for i,v in pairs(Players:GetPlayers()) do
		local chmsplr = v
		for i,c in pairs(COREGUI:GetChildren()) do
			if c.Name == chmsplr.Name..'_CHMS' then
				c:Destroy()
			end
		end
	end
end)
addcmd('locate',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		Locate(Players[v])
	end
end)
addcmd('nolocate',{'unlocate'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if args[1] then
		for i,v in pairs(players) do
			for i,c in pairs(COREGUI:GetChildren()) do
				if c.Name == Players[v].Name..'_LC' then
					c:Destroy()
				end
			end
		end
	else
		for i,c in pairs(COREGUI:GetChildren()) do
			if string.sub(c.Name, -3) == '_LC' then
				c:Destroy()
			end
		end
	end
end)
viewing = nil
addcmd('view',{'spectate'},function(args, speaker)
	StopFreecam()
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		if viewDied then
			viewDied:Disconnect()
			viewChanged:Disconnect()
		end
		viewing = Players[v]
		workspace.CurrentCamera.CameraSubject = viewing.Character
		notify('Spectate','Viewing ' .. Players[v].Name)
		local function viewDiedFunc()
			repeat wait() until Players[v].Character ~= nil and getRoot(Players[v].Character)
			workspace.CurrentCamera.CameraSubject = viewing.Character
		end
		viewDied = Players[v].CharacterAdded:Connect(viewDiedFunc)
		local function viewChangedFunc()
			workspace.CurrentCamera.CameraSubject = viewing.Character
		end
		viewChanged = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(viewChangedFunc)
	end
end)
addcmd('viewpart',{'viewp'},function(args, speaker)
	StopFreecam()
	if args[1] then
		for i,v in pairs(workspace:GetDescendants()) do
			if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
				wait(0.1)
				workspace.CurrentCamera.CameraSubject = v
			end
		end
	end
end)
addcmd('unview',{'unspectate'},function(args, speaker)
	StopFreecam()
	if viewing ~= nil then
		viewing = nil
		notify('Spectate','View turned off')
	end
	if viewDied then
		viewDied:Disconnect()
		viewChanged:Disconnect()
	end
	workspace.CurrentCamera.CameraSubject = speaker.Character
end)
fcRunning = false
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = workspace.CurrentCamera
	if newCamera then
		Camera = newCamera
	end
end)
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
Spring = {} do
	Spring.__index = Spring
	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end
	function Spring:Update(dt, goal)
		local f = self.f*2*math.pi
		local p0 = self.p
		local v0 = self.v
		local offset = goal - p0
		local decay = math.exp(-f*dt)
		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay
		self.p = p1
		self.v = v1
		return p1
	end
	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end
local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local velSpring = Spring.new(5, Vector3.new())
local panSpring = Spring.new(5, Vector2.new())
Input = {} do
	keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
	}
	mouse = {
		Delta = Vector2.new(),
	}
	NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	PAN_MOUSE_SPEED = Vector2.new(1, 1)*(math.pi/64)
	NAV_ADJ_SPEED = 0.75
	NAV_SHIFT_MUL = 0.25
	navSpeed = 1
	function Input.Vel(dt)
		navSpeed = math.clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)
		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A,
			keyboard.E - keyboard.Q,
			keyboard.S - keyboard.W
		)*NAV_KEYBOARD_SPEED
		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		return (kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end
	function Input.Pan(dt)
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kMouse
	end
		function Keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end
		function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end
		function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end
		function Input.StartCapture()
			ContextActionService:BindActionAtPriority("FreecamKeyboard",Keypress,false,INPUT_PRIORITY,
				Enum.KeyCode.W,
				Enum.KeyCode.A,
				Enum.KeyCode.S,
				Enum.KeyCode.D,
				Enum.KeyCode.E,
				Enum.KeyCode.Q,
				Enum.KeyCode.Up,
				Enum.KeyCode.Down
			)
			ContextActionService:BindActionAtPriority("FreecamMousePan",MousePan,false,INPUT_PRIORITY,Enum.UserInputType.MouseMovement)
		end
		function Input.StopCapture()
			navSpeed = 1
			Zero(keyboard)
			Zero(mouse)
			ContextActionService:UnbindAction("FreecamKeyboard")
			ContextActionService:UnbindAction("FreecamMousePan")
		end
	end
function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = Camera.ViewportSize
	local projy = 2*math.tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector
	local minVect = Vector3.new()
	local minDist = 512
	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end
	return fz:Dot(minVect)*minDist
end
function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))
	local zoomFactor = math.sqrt(math.tan(math.rad(70/2))/math.tan(math.rad(cameraFov/2)))
	cameraRot = cameraRot + pan*Vector2.new(0.75, 1)*8*(dt/zoomFactor)
	cameraRot = Vector2.new(math.clamp(cameraRot.x, -math.rad(90), math.rad(90)), cameraRot.y%(2*math.pi))
	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*Vector3.new(1, 1, 1)*64*dt)
	cameraPos = cameraCFrame.p
	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	Camera.FieldOfView = cameraFov
end
local PlayerState = {} do
	mouseBehavior = ""
	mouseIconEnabled = ""
	cameraType = ""
	cameraFocus = ""
	cameraCFrame = ""
	cameraFieldOfView = ""
	function PlayerState.Push()
		cameraFieldOfView = Camera.FieldOfView
		Camera.FieldOfView = 70
		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom
		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus
		mouseIconEnabled = UserInputService.MouseIconEnabled
		UserInputService.MouseIconEnabled = true
		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	function PlayerState.Pop()
		Camera.FieldOfView = 70
		Camera.CameraType = cameraType
		cameraType = nil
		Camera.CFrame = cameraCFrame
		cameraCFrame = nil
		Camera.Focus = cameraFocus
		cameraFocus = nil
		UserInputService.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil
		UserInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end
function StartFreecam(pos)
	if fcRunning then
		StopFreecam()
	end
	local cameraCFrame = Camera.CFrame
	if pos then
		cameraCFrame = pos
	end
	cameraRot = Vector2.new()
	cameraPos = cameraCFrame.p
	cameraFov = Camera.FieldOfView
	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())
	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
	fcRunning = true
end
function StopFreecam()
	if not fcRunning then return end
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
	workspace.Camera.FieldOfView = 70
	fcRunning = false
end
addcmd('freecam',{'fc'},function(args, speaker)
	StartFreecam()
end)
addcmd('freecampos',{'fcpos','fcp','freecamposition','fcposition'},function(args, speaker)
	if not args[1] then return end
	local freecamPos = CFrame.new(args[1],args[2],args[3])
	StartFreecam(freecamPos)
end)
addcmd('freecamwaypoint',{'fcwp'},function(args, speaker)
	local WPName = tostring(getstring(1, args))
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			local x = WayPoints[i].COORD[1]
			local y = WayPoints[i].COORD[2]
			local z = WayPoints[i].COORD[3]
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				StartFreecam(CFrame.new(x,y,z))
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				StartFreecam(CFrame.new(pWayPoints[i].COORD[1].Position))
			end
		end
	end
end)
addcmd('freecamgoto',{'fcgoto','freecamtp','fctp'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		StartFreecam(getRoot(Players[v].Character).CFrame)
	end
end)
addcmd('unfreecam',{'nofreecam','unfc','nofc'},function(args, speaker)
	StopFreecam()
end)
addcmd('freecamspeed',{'fcspeed'},function(args, speaker)
	local FCspeed = args[1] or 1
	if isNumber(FCspeed) then
		NAV_KEYBOARD_SPEED = Vector3.new(FCspeed, FCspeed, FCspeed)
	end
end)
addcmd('notifyfreecamposition',{'notifyfcpos'},function(args, speaker)
	if fcRunning then
		local X,Y,Z = workspace.CurrentCamera.CFrame.Position.X,workspace.CurrentCamera.CFrame.Position.Y,workspace.CurrentCamera.CFrame.Position.Z
		local Format, Round = string.format, math.round
		notify("Current Position", Format("%s, %s, %s", Round(X), Round(Y), Round(Z)))
	end
end)
addcmd('copyfreecamposition',{'copyfcpos'},function(args, speaker)
	if fcRunning then
		local X,Y,Z = workspace.CurrentCamera.CFrame.Position.X,workspace.CurrentCamera.CFrame.Position.Y,workspace.CurrentCamera.CFrame.Position.Z
		local Format, Round = string.format, math.round
		toClipboard(Format("%s, %s, %s", Round(X), Round(Y), Round(Z)))
	end
end)
addcmd('gotocamera',{'gotocam','tocam'},function(args, speaker)
	getRoot(speaker.Character).CFrame = workspace.Camera.CFrame
end)
addcmd('tweengotocamera',{'tweengotocam','tgotocam','ttocam'},function(args, speaker)
	TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = workspace.Camera.CFrame}):Play()
end)
addcmd('fov',{},function(args, speaker)
	local fov = args[1] or 70
	if isNumber(fov) then
		workspace.CurrentCamera.FieldOfView = fov
	end
end)
local preMaxZoom = Players.LocalPlayer.CameraMaxZoomDistance
local preMinZoom = Players.LocalPlayer.CameraMinZoomDistance
addcmd('lookat',{},function(args, speaker)
	if speaker.CameraMaxZoomDistance ~= 0.5 then
		preMaxZoom = speaker.CameraMaxZoomDistance
		preMinZoom = speaker.CameraMinZoomDistance
	end
	speaker.CameraMaxZoomDistance = 0.5
	speaker.CameraMinZoomDistance = 0.5
	wait()
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local target = Players[v].Character
		if target and target:FindFirstChild('Head') then
			workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.p, target.Head.CFrame.p)
			wait(0.1)
		end
	end
	speaker.CameraMaxZoomDistance = preMaxZoom
	speaker.CameraMinZoomDistance = preMinZoom
end)
addcmd('fixcam',{'restorecam'},function(args, speaker)
	StopFreecam()
	execCmd('unview')
	workspace.CurrentCamera:remove()
	wait(.1)
	repeat wait() until speaker.Character ~= nil
	workspace.CurrentCamera.CameraSubject = speaker.Character:FindFirstChildWhichIsA('Humanoid')
	workspace.CurrentCamera.CameraType = "Custom"
	speaker.CameraMinZoomDistance = 0.5
	speaker.CameraMaxZoomDistance = 400
	speaker.CameraMode = "Classic"
	speaker.Character.Head.Anchored = false
end)
addcmd("enableshiftlock", {"enablesl", "shiftlock"}, function(args, speaker)
	local function enableShiftlock()
		speaker.DevEnableMouseLock = true
	end
	speaker:GetPropertyChangedSignal("DevEnableMouseLock"):Connect(enableShiftlock)
	enableShiftlock()
	notify("Shiftlock", "Shift lock should now be available")
end)
addcmd('firstp',{},function(args, speaker)
	speaker.CameraMode = "LockFirstPerson"
end)
addcmd('thirdp',{},function(args, speaker)
	speaker.CameraMode = "Classic"
end)
addcmd('noclipcam', {'nccam'}, function(args, speaker)
	local sc = (debug and debug.setconstant) or setconstant
	local gc = (debug and debug.getconstants) or getconstants
	if not sc or not getgc or not gc then
		return notify('Incompatible Exploit', 'Your exploit does not support this command (missing setconstant or getconstants or getgc)')
	end
	local pop = speaker.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
	for _, v in pairs(getgc()) do
		if type(v) == 'function' and getfenv(v).script == pop then
			for i, v1 in pairs(gc(v)) do
				if tonumber(v1) == .25 then
					sc(v, i, 0)
				elseif tonumber(v1) == 0 then
					sc(v, i, .25)
				end
			end
		end
	end
end)
addcmd('maxzoom',{},function(args, speaker)
	speaker.CameraMaxZoomDistance = args[1]
end)

addcmd('infzoom',{'infinitezoom','infzoomout'},function(args, speaker)
	_infZoomEnabled = not _infZoomEnabled
	speaker.CameraMaxZoomDistance = _infZoomEnabled and 9e9 or 128
	speaker.CameraMinZoomDistance = 0.5
	notify("Infinite Zoom", _infZoomEnabled and "Enabled" or "Disabled")
end)

addcmd('hide',{'ghost','mutehide','hideplayer'},function(args, speaker)
	local targets = getPlayer(args[1], speaker)
	for _, targetName in ipairs(targets) do
		local target = players:FindFirstChild(targetName)
		if target then
			hidePlayer(target)
		end
	end
end)

addcmd('unhide',{'unghost','unmutehide','unhideplayer'},function(args, speaker)
	local targets = getPlayer(args[1], speaker)
	for _, targetName in ipairs(targets) do
		local target = players:FindFirstChild(targetName)
		if target then
			unhidePlayer(target)
		end
	end
end)
addcmd('minzoom',{},function(args, speaker)
	speaker.CameraMinZoomDistance = args[1]
end)
addcmd('camdistance',{},function(args, speaker)
	local camMax = speaker.CameraMaxZoomDistance
	local camMin = speaker.CameraMinZoomDistance
	if camMax < tonumber(args[1]) then
		camMax = args[1]
	end
	speaker.CameraMaxZoomDistance = args[1]
	speaker.CameraMinZoomDistance = args[1]
	wait()
	speaker.CameraMaxZoomDistance = camMax
	speaker.CameraMinZoomDistance = camMin
end)
addcmd('unlockws',{'unlockworkspace'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = false
		end
	end
end)
addcmd('lockws',{'lockworkspace'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = true
		end
	end
end)
addcmd('delete',{'remove'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted ' ..getstring(1, args))
end)
addcmd('deleteclass',{'removeclass','deleteclassname','removeclassname','dc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted items with ClassName ' ..getstring(1, args))
end)
addcmd('chardelete',{'charremove','cd'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted ' ..getstring(1, args))
end)
addcmd('chardeleteclass',{'charremoveclass','chardeleteclassname','charremoveclassname','cdc'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() then
			v:Destroy()
		end
	end
	notify('Item(s) Deleted','Deleted items with ClassName ' ..getstring(1, args))
end)
addcmd('deletevelocity',{'dv','removevelocity','removeforces'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("RocketPropulsion") or v:IsA("BodyThrust") or v:IsA("BodyAngularVelocity") or v:IsA("AngularVelocity") or v:IsA("BodyForce") or v:IsA("VectorForce") or v:IsA("LineForce") then
			v:Destroy()
		end
	end
end)
addcmd('deleteinvisparts',{'deleteinvisibleparts','dip'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Transparency == 1 and v.CanCollide then
			v:Destroy()
		end
	end
end)
local shownParts = {}
addcmd('invisibleparts',{'invisparts'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Transparency == 1 then
			if not table.find(shownParts,v) then
				table.insert(shownParts,v)
			end
			v.Transparency = 0
		end
	end
end)
addcmd('uninvisibleparts',{'uninvisparts'},function(args, speaker)
	for i,v in pairs(shownParts) do
		v.Transparency = 1
	end
	shownParts = {}
end)
addcmd("btools", {}, function(args, speaker)
	for i = 1, 4 do
		local Tool = Instance.new("HopperBin")
		Tool.BinType = i
		Tool.Name = randomString()
		Tool.Parent = speaker:FindFirstChildWhichIsA("Backpack")
	end
end)
addcmd("f3x", {"fex"}, function(args, speaker)
	loadstring(game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/f3x.lua")))()
end)
addcmd("partpath", {"partname"}, function(args, speaker)
	selectPart()
end)
addcmd("antiafk", {"antiidle"}, function(args, speaker)
	if getconnections then
		for _, connection in pairs(getconnections(speaker.Idled)) do
			if connection["Disable"] then
				connection["Disable"](connection)
			elseif connection["Disconnect"] then
				connection["Disconnect"](connection)
			end
		end
	else
		speaker.Idled:Connect(function()
		end)
	end
	if not (args[1] and tostring(args[1]) == "nonotify") then notify("Anti Idle", "Anti idle is enabled") end
end)
addcmd("datalimit", {}, function(args, speaker)
	local kbps = tonumber(args[1])
	if kbps then
		Services.NetworkClient:SetOutgoingKBPSLimit(kbps)
	end
end)
addcmd("replicationlag", {"backtrack"}, function(args, speaker)
	if tonumber(args[1]) then
		settings():GetService("NetworkSettings").IncomingReplicationLag = args[1]
	end
end)
addcmd("noprompts", {"nopurchaseprompts"}, function(args, speaker)
	COREGUI.PurchasePromptApp.Enabled = false
end)
addcmd("showprompts", {"showpurchaseprompts"}, function(args, speaker)
	COREGUI.PurchasePromptApp.Enabled = true
end)
promptNewRig = function(speaker, rig)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		AvatarEditorService:PromptSaveAvatar(humanoid.HumanoidDescription, Enum.HumanoidRigType[rig])
		local result = AvatarEditorService.PromptSaveAvatarCompleted:Wait()
		if result == Enum.AvatarPromptResult.Success then
			execCmd("reset")
		end
	end
end
addcmd("promptr6", {}, function(args, speaker)
	promptNewRig(speaker, "R6")
end)
addcmd("promptr15", {}, function(args, speaker)
	promptNewRig(speaker, "R15")
end)
addcmd("wallwalk", {"walkonwalls"}, function(args, speaker)
	loadstring(game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/main/wallwalker.lua")))()
end)
addcmd('age',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local ages = {}
	for i,v in pairs(players) do
		local p = Players[v]
		table.insert(ages, p.Name.."'s age is: "..p.AccountAge)
	end
	notify('Account Age',table.concat(ages, ',\n'))
end)
addcmd('chatage',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local ages = {}
	for i,v in pairs(players) do
		local p = Players[v]
		table.insert(ages, p.Name.."'s age is: "..p.AccountAge)
	end
	local chatString = table.concat(ages, ', ')
	chatMessage(chatString)
end)
addcmd('joindate',{'jd'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local dates = {}
	for i,v in pairs(players) do
		local p = Players[v]
		local secondsOld = p.AccountAge * 24 * 60 * 60
		local now = os.time()
		local dateJoined  = p.Name .. " joined: " .. os.date("%m/%d/%y", now - secondsOld)
		table.insert(dates, dateJoined)
	end
	notify('Join Date (Month/Day/Year)',table.concat(dates, ',\n'))
end)
addcmd('chatjoindate',{'cjd'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local dates = {}
	for i,v in pairs(players) do
		local p = Players[v]
		local secondsOld = p.AccountAge * 24 * 60 * 60
		local now = os.time()
		local dateJoined  = p.Name .. " joined: " .. os.date("%m/%d/%y", now - secondsOld)
		table.insert(dates, dateJoined)
	end
	local chatString = table.concat(dates, ', ')
	chatMessage(chatString)
end)
addcmd('copyname',{'copyuser'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local name = tostring(Players[v].Name)
		toClipboard(name)
	end
end)
addcmd('userid',{'id'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local id = tostring(Players[v].UserId)
		notify('User ID',id)
	end
end)
addcmd("copyplaceid", {"placeid"}, function(args, speaker)
	toClipboard(PlaceId)
end)
addcmd("copygameid", {"gameid"}, function(args, speaker)
	toClipboard(game.GameId)
end)
addcmd('copyid',{'copyuserid'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local id = tostring(Players[v].UserId)
		toClipboard(id)
	end
end)
addcmd('creatorid',{'creator'},function(args, speaker)
	if game.CreatorType == Enum.CreatorType.User then
		notify('Creator ID',game.CreatorId)
	elseif game.CreatorType == Enum.CreatorType.Group then
		local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
		speaker.UserId = OwnerID
		notify('Creator ID',OwnerID)
	end
end)
addcmd('copycreatorid',{'copycreator'},function(args, speaker)
	if game.CreatorType == Enum.CreatorType.User then
		toClipboard(game.CreatorId)
		notify('Copied ID','Copied creator ID to clipboard')
	elseif game.CreatorType == Enum.CreatorType.Group then
		local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
		toClipboard(OwnerID)
		notify('Copied ID','Copied creator ID to clipboard')
	end
end)
addcmd('setcreatorid',{'setcreator'},function(args, speaker)
	if game.CreatorType == Enum.CreatorType.User then
		speaker.UserId = game.CreatorId
		notify('Set ID','Set UserId to '..game.CreatorId)
	elseif game.CreatorType == Enum.CreatorType.Group then
		local OwnerID = GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
		speaker.UserId = OwnerID
		notify('Set ID','Set UserId to '..OwnerID)
	end
end)
addcmd('appearanceid',{'aid'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local aid = tostring(Players[v].CharacterAppearanceId)
		notify('Appearance ID',aid)
	end
end)
addcmd('copyappearanceid',{'caid'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local aid = tostring(Players[v].CharacterAppearanceId)
		toClipboard(aid)
	end
end)
addcmd('norender',{},function(args, speaker)
	RunService:Set3dRenderingEnabled(false)
end)
addcmd('render',{},function(args, speaker)
	RunService:Set3dRenderingEnabled(true)
end)
addcmd('2022materials',{'use2022materials'},function(args, speaker)
	if sethidden then
		sethidden(MaterialService, "Use2022Materials", true)
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing sethiddenproperty)')
	end
end)
addcmd('un2022materials',{'unuse2022materials'},function(args, speaker)
	if sethidden then
		sethidden(MaterialService, "Use2022Materials", false)
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing sethiddenproperty)')
	end
end)
addcmd('goto',{'to'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			getRoot(speaker.Character).CFrame = getRoot(Players[v].Character).CFrame + Vector3.new(3,1,0)
		end
	end
	execCmd('breakvelocity')
end)
addcmd('tweengoto',{'tgoto','tto','tweento'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = getRoot(Players[v].Character).CFrame + Vector3.new(3,1,0)}):Play()
		end
	end
	execCmd('breakvelocity')
end)
addcmd('vehiclegoto',{'vgoto','vtp','vehicletp'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			local seat = speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart
			local vehicleModel = seat:FindFirstAncestorWhichIsA("Model")
			vehicleModel:MoveTo(getRoot(Players[v].Character).Position)
		end
	end
end)
addcmd('pulsetp',{'ptp'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			local startPos = getRoot(speaker.Character).CFrame
			local seconds = args[2] or 1
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			getRoot(speaker.Character).CFrame = getRoot(Players[v].Character).CFrame + Vector3.new(3,1,0)
			wait(seconds)
			getRoot(speaker.Character).CFrame = startPos
		end
	end
	execCmd('breakvelocity')
end)
local vnoclipParts = {}
addcmd('vehiclenoclip',{'vnoclip'},function(args, speaker)
	vnoclipParts = {}
	local seat = speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart
	local vehicleModel = seat.Parent
	repeat
		if vehicleModel.ClassName ~= "Model" then
			vehicleModel = vehicleModel.Parent
		end
	until vehicleModel.ClassName == "Model"
	wait(0.1)
	execCmd('noclip')
	for i,v in pairs(vehicleModel:GetDescendants()) do
		if v:IsA("BasePart") and v.CanCollide then
			table.insert(vnoclipParts,v)
			v.CanCollide = false
		end
	end
end)
addcmd("vehicleclip", {"vclip", "unvnoclip", "unvehiclenoclip"}, function(args, speaker)
	execCmd("clip")
	for i, v in pairs(vnoclipParts) do
		v.CanCollide = true
	end
	vnoclipParts = {}
end)
addcmd("togglevnoclip", {}, function(args, speaker)
	execCmd(Clip and "vnoclip" or "vclip")
end)
addcmd('clientbring',{'cbring'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if Players[v].Character:FindFirstChildOfClass('Humanoid') then
				Players[v].Character:FindFirstChildOfClass('Humanoid').Sit = false
			end
			wait()
			getRoot(Players[v].Character).CFrame = getRoot(speaker.Character).CFrame + Vector3.new(3,1,0)
		end
	end
end)
local bringT = {}
addcmd('loopbring',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			if Players[v].Name ~= speaker.Name and not FindInTable(bringT, Players[v].Name) then
				table.insert(bringT, Players[v].Name)
				local plrName = Players[v].Name
				local pchar=Players[v].Character
				local distance = 3
				if args[2] and isNumber(args[2]) then
					distance = args[2]
				end
				local lDelay = 0
				if args[3] and isNumber(args[3]) then
					lDelay = args[3]
				end
				repeat
					for i,c in pairs(players) do
						if Players:FindFirstChild(v) then
							pchar = Players[v].Character
							if pchar~= nil and Players[v].Character ~= nil and getRoot(pchar) and speaker.Character ~= nil and getRoot(speaker.Character) then
								getRoot(pchar).CFrame = getRoot(speaker.Character).CFrame + Vector3.new(distance,1,0)
							end
							wait(lDelay)
						else
							for a,b in pairs(bringT) do if b == plrName then table.remove(bringT, a) end end
						end
					end
				until not FindInTable(bringT, plrName)
			end
		end)
	end
end)
addcmd('unloopbring',{'noloopbring'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			for a,b in pairs(bringT) do if b == Players[v].Name then table.remove(bringT, a) end end
		end)
	end
end)
local walkto = false
local waypointwalkto = false
addcmd('walkto',{'follow'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			walkto = true
			repeat wait()
				speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(getRoot(Players[v].Character).Position)
			until Players[v].Character == nil or not getRoot(Players[v].Character) or walkto == false
		end
	end
end)
addcmd('pathfindwalkto',{'pathfindfollow'},function(args, speaker)
	walkto = false
	wait()
	local players = getPlayer(args[1], speaker)
	local hum = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local path = PathService:CreatePath()
	for i,v in pairs(players)do
		if Players[v].Character ~= nil then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			walkto = true
			repeat wait()
				local success, response = pcall(function()
					path:ComputeAsync(getRoot(speaker.Character).Position, getRoot(Players[v].Character).Position)
					local waypoints = path:GetWaypoints()
					local distance
					for waypointIndex, waypoint in pairs(waypoints) do
						local waypointPosition = waypoint.Position
						hum:MoveTo(waypointPosition)
						repeat
							distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
							wait()
						until
						distance <= 5
					end
				end)
				if not success then
					speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(getRoot(Players[v].Character).Position)
				end
			until Players[v].Character == nil or not getRoot(Players[v].Character) or walkto == false
		end
	end
end)
addcmd('pathfindwalktowaypoint',{'pathfindwalktowp'},function(args, speaker)
	waypointwalkto = false
	wait()
	local WPName = tostring(getstring(1, args))
	local hum = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local path = PathService:CreatePath()
	if speaker.Character then
		for i,_ in pairs(WayPoints) do
			if tostring(WayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				local TrueCoords = Vector3.new(WayPoints[i].COORD[1], WayPoints[i].COORD[2], WayPoints[i].COORD[3])
				waypointwalkto = true
				repeat wait()
					local success, response = pcall(function()
						path:ComputeAsync(getRoot(speaker.Character).Position, TrueCoords)
						local waypoints = path:GetWaypoints()
						local distance
						for waypointIndex, waypoint in pairs(waypoints) do
							local waypointPosition = waypoint.Position
							hum:MoveTo(waypointPosition)
							repeat
								distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
								wait()
							until
							distance <= 5
						end
					end)
					if not success then
						speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(TrueCoords)
					end
				until not speaker.Character or waypointwalkto == false
			end
		end
		for i,_ in pairs(pWayPoints) do
			if tostring(pWayPoints[i].NAME):lower() == tostring(WPName):lower() then
				if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
					speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
					wait(.1)
				end
				local TrueCoords = pWayPoints[i].COORD[1].Position
				waypointwalkto = true
				repeat wait()
					local success, response = pcall(function()
						path:ComputeAsync(getRoot(speaker.Character).Position, TrueCoords)
						local waypoints = path:GetWaypoints()
						local distance
						for waypointIndex, waypoint in pairs(waypoints) do
							local waypointPosition = waypoint.Position
							hum:MoveTo(waypointPosition)
							repeat
								distance = (waypointPosition - hum.Parent.PrimaryPart.Position).magnitude
								wait()
							until
							distance <= 5
						end
					end)
					if not success then
						speaker.Character:FindFirstChildOfClass('Humanoid'):MoveTo(TrueCoords)
					end
				until not speaker.Character or waypointwalkto == false
			end
		end
	end
end)
addcmd('unwalkto',{'nowalkto','unfollow','nofollow'},function(args, speaker)
	walkto = false
	waypointwalkto = false
end)
addcmd("orbit", {}, function(args, speaker)
	execCmd("unorbit nonotify")
	local target = Players:FindFirstChild(getPlayer(args[1], speaker)[1])
	local root = getRoot(speaker.Character)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if target and target.Character and getRoot(target.Character) and root and humanoid then
		local rotation = 0
		local speed = tonumber(args[2]) or 0.2
		local distance = tonumber(args[3]) or 6
		orbit1 = RunService.Heartbeat:Connect(function()
			pcall(function()
				rotation = rotation + speed
				root.CFrame = CFrame.new(getRoot(target.Character).Position) * CFrame.Angles(0, math.rad(rotation), 0) * CFrame.new(distance, 0, 0)
			end)
		end)
		orbit2 = RunService.RenderStepped:Connect(function()
			pcall(function()
				root.CFrame = CFrame.new(root.Position, getRoot(target.Character).Position)
			end)
		end)
		orbit3 = humanoid.Died:Connect(function() execCmd("unorbit") end)
		orbit4 = humanoid.Seated:Connect(function(value) if value then execCmd("unorbit") end end)
		notify("Orbit", "Started orbiting " .. formatUsername(target))
	end
end)
addcmd("unorbit", {}, function(args, speaker)
	if orbit1 then orbit1:Disconnect() end
	if orbit2 then orbit2:Disconnect() end
	if orbit3 then orbit3:Disconnect() end
	if orbit4 then orbit4:Disconnect() end
	if args[1] ~= "nonotify" then notify("Orbit", "Stopped orbiting player") end
end)
addcmd('freeze',{'fr'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x:IsA("BasePart") and not x.Anchored then
						x.Anchored = true
					end
				end
			end)
		end
	end
end)
addcmd('thaw',{'unfreeze','unfr'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x.Name ~= floatName and x:IsA("BasePart") and x.Anchored then
						x.Anchored = false
					end
				end
			end)
		end
	end
end)
addcmd("anchor", {}, function(args, speaker)
    getRoot(speaker.Character).Anchored = true
end)
addcmd("unanchor", {}, function(args, speaker)
    getRoot(speaker.Character).Anchored = false
end)
oofing = false
addcmd('loopoof',{},function(args, speaker)
	oofing = true
	repeat wait(0.1)
		for i,v in pairs(Players:GetPlayers()) do
			if v.Character ~= nil and v.Character:FindFirstChild'Head' then
				for _,x in pairs(v.Character.Head:GetChildren()) do
					if x:IsA'Sound' then x.Playing = true end
				end
			end
		end
	until oofing == false
end)
addcmd('unloopoof',{},function(args, speaker)
	oofing = false
end)
local notifiedRespectFiltering = false
addcmd('muteboombox',{},function(args, speaker)
	if not notifiedRespectFiltering and SoundService.RespectFilteringEnabled then notifiedRespectFiltering = true notify('RespectFilteringEnabled','RespectFilteringEnabled is set to true (the command will still work but may only be clientsided)') end
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x:IsA("Sound") and x.Playing == true then
						x.Playing = false
					end
				end
				for i, x in next, Players[v]:FindFirstChildOfClass("Backpack"):GetDescendants() do
					if x:IsA("Sound") and x.Playing == true then
						x.Playing = false
					end
				end
			end)
		end
	end
end)
addcmd('unmuteboombox',{},function(args, speaker)
	if not notifiedRespectFiltering and SoundService.RespectFilteringEnabled then notifiedRespectFiltering = true notify('RespectFilteringEnabled','RespectFilteringEnabled is set to true (the command will still work but may only be clientsided)') end
	local players = getPlayer(args[1], speaker)
	if players ~= nil then
		for i,v in pairs(players) do
			task.spawn(function()
				for i, x in next, Players[v].Character:GetDescendants() do
					if x:IsA("Sound") and x.Playing == false then
						x.Playing = true
					end
				end
			end)
		end
	end
end)
addcmd("reset", {}, function(args, speaker)
	local humanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if replicatesignal then
		replicatesignal(speaker.Kill)
	elseif humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	else
		speaker.Character:BreakJoints()
	end
end)
addcmd('freezeanims',{},function(args, speaker)
	local Humanoid = speaker.Character:FindFirstChildOfClass("Humanoid") or speaker.Character:FindFirstChildOfClass("AnimationController")
	local ActiveTracks = Humanoid:GetPlayingAnimationTracks()
	for _, v in pairs(ActiveTracks) do
		v:AdjustSpeed(0)
	end
end)
addcmd('unfreezeanims',{},function(args, speaker)
	local Humanoid = speaker.Character:FindFirstChildOfClass("Humanoid") or speaker.Character:FindFirstChildOfClass("AnimationController")
	local ActiveTracks = Humanoid:GetPlayingAnimationTracks()
	for _, v in pairs(ActiveTracks) do
		v:AdjustSpeed(1)
	end
end)
addcmd("respawn", {}, function(args, speaker)
	respawn(speaker)
end)
addcmd("refresh", {"re"}, function(args, speaker)
	refresh(speaker)
end)
addcmd("god", {}, function(args, speaker)
	permadeath(speaker)
	local Cam = workspace.CurrentCamera
	local Char, Pos = speaker.Character, Cam.CFrame
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local nHuman = Human:Clone()
	nHuman.Parent = char
	speaker.Character = nil
	nHuman:SetStateEnabled(15, false)
	nHuman:SetStateEnabled(1, false)
	nHuman:SetStateEnabled(0, false)
	nHuman.BreakJointsOnDeath = true
	Human:Destroy()
	speaker.Character = char
	Cam.CameraSubject = nHuman
	Cam.CFrame = task.wait() and pos
	nHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local Script = Char:FindFirstChild("Animate")
	if Script then
		Script.Disabled = true
		task.wait()
		Script.Disabled = false
	end
	nHuman.Health = nHuman.MaxHealth
end)
invisRunning = false
addcmd('invisible',{'invis'},function(args, speaker)
	if invisRunning then return end
	invisRunning = true
	local Player = speaker
	repeat wait(.1) until Player.Character
	local Character = Player.Character
	Character.Archivable = true
	local IsInvis = false
	local IsRunning = true
	local InvisibleCharacter = Character:Clone()
	InvisibleCharacter.Parent = Lighting
	local Void = workspace.FallenPartsDestroyHeight
	InvisibleCharacter.Name = ""
	local CF
	local invisFix = RunService.Stepped:Connect(function()
		pcall(function()
			local IsInteger
			if tostring(Void):find'-' then
				IsInteger = true
			else
				IsInteger = false
			end
			local Pos = Player.Character.Humanoid.RootPart.Position
			local Pos_String = tostring(Pos)
			local Pos_Seperate = Pos_String:split(', ')
			local X = tonumber(Pos_Seperate[1])
			local Y = tonumber(Pos_Seperate[2])
			local Z = tonumber(Pos_Seperate[3])
			if IsInteger == true then
				if Y <= Void then
					Respawn()
				end
			elseif IsInteger == false then
				if Y >= Void then
					Respawn()
				end
			end
		end)
	end)
	for i,v in pairs(InvisibleCharacter:GetDescendants())do
		if v:IsA("BasePart") then
			if v.Name == "HumanoidRootPart" then
				v.Transparency = 1
			else
				v.Transparency = .5
			end
		end
	end
	function Respawn()
		IsRunning = false
		if IsInvis == true then
			pcall(function()
				Player.Character = Character
				wait()
				Character.Parent = workspace
				Character:FindFirstChildWhichIsA'Humanoid':Destroy()
				IsInvis = false
				InvisibleCharacter.Parent = nil
				invisRunning = false
			end)
		elseif IsInvis == false then
			pcall(function()
				Player.Character = Character
				wait()
				Character.Parent = workspace
				Character:FindFirstChildWhichIsA'Humanoid':Destroy()
				TurnVisible()
			end)
		end
	end
	local invisDied
	invisDied = InvisibleCharacter:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
		Respawn()
		invisDied:Disconnect()
	end)
	if IsInvis == true then return end
	IsInvis = true
	CF = workspace.CurrentCamera.CFrame
	local CF_1 = Player.Character.Humanoid.RootPart.CFrame
	Character:MoveTo(Vector3.new(0,math.pi*1000000,0))
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	wait(.2)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	InvisibleCharacter = InvisibleCharacter
	Character.Parent = Lighting
	InvisibleCharacter.Parent = workspace
	InvisibleCharacter.Humanoid.RootPart.CFrame = CF_1
	Player.Character = InvisibleCharacter
	execCmd('fixcam')
	Player.Character.Animate.Disabled = true
	Player.Character.Animate.Disabled = false
	function TurnVisible()
		if IsInvis == false then return end
		invisFix:Disconnect()
		invisDied:Disconnect()
		CF = workspace.CurrentCamera.CFrame
		Character = Character
		local CF_1 = Player.Character.Humanoid.RootPart.CFrame
		Character.Humanoid.RootPart.CFrame = CF_1
		InvisibleCharacter:Destroy()
		Player.Character = Character
		Character.Parent = workspace
		IsInvis = false
		Player.Character.Animate.Disabled = true
		Player.Character.Animate.Disabled = false
		invisDied = Character:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
			Respawn()
			invisDied:Disconnect()
		end)
		invisRunning = false
	end
	notify('Invisible','You now appear invisible to other players')
end)
addcmd("visible", {"vis","uninvisible"}, function(args, speaker)
	TurnVisible()
end)
addcmd("toggleinvis", {}, function(args, speaker)
	execCmd(invisRunning and "visible" or "invisible")
end)
addcmd('toolinvisible',{'toolinvis','tinvis'},function(args, speaker)
	local Char  = Players.LocalPlayer.Character
	local touched = false
	local tpdback = false
	local box = Instance.new('Part')
	box.Anchored = true
	box.CanCollide = true
	box.Size = Vector3.new(10,1,10)
	box.Position = Vector3.new(0,10000,0)
	box.Parent = workspace
	local boxTouched = box.Touched:connect(function(part)
		if (part.Parent.Name == Players.LocalPlayer.Name) then
			if touched == false then
				touched = true
				local function apply()
					local no = Char.Humanoid.RootPart:Clone()
					task.wait(.25)
					Char.Humanoid.RootPart:Destroy()
					no.Parent = Char
					Char:MoveTo(loc)
					touched = false
				end
				if Char then
					apply()
				end
			end
		end
	end)
	repeat wait() until Char
	local cleanUp
	cleanUp = Players.LocalPlayer.CharacterAdded:connect(function(char)
		boxTouched:Disconnect()
		box:Destroy()
		cleanUp:Disconnect()
	end)
	loc = Char.Humanoid.RootPart.Position
	Char:MoveTo(box.Position + Vector3.new(0,.5,0))
end)
addcmd("strengthen", {}, function(args, speaker)
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			if args[1] then
				child.CustomPhysicalProperties = PhysicalProperties.new(args[1], 0.3, 0.5)
			else
				child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
			end
		end
	end
end)
addcmd("weaken", {}, function(args, speaker)
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			if args[1] then
				child.CustomPhysicalProperties = PhysicalProperties.new(-args[1], 0.3, 0.5)
			else
				child.CustomPhysicalProperties = PhysicalProperties.new(0, 0.3, 0.5)
			end
		end
	end
end)
addcmd("unweaken", {"unstrengthen"}, function(args, speaker)
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child.ClassName == "Part" then
			child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
		end
	end
end)
addcmd("breakvelocity", {}, function(args, speaker)
	local BeenASecond, V3 = false, Vector3.new(0, 0, 0)
	delay(1, function()
		BeenASecond = true
	end)
	while not BeenASecond do
		for _, v in ipairs(speaker.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.AssemblyLinearVelocity, v.AssemblyAngularVelocity = V3, V3
			end
		end
		wait()
	end
end)
addcmd('jpower',{'jumppower','jp'},function(args, speaker)
	local jpower = args[1] or 50
	if isNumber(jpower) then
		if speaker.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpPower = jpower
		else
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = jpower
		end
	end
end)
addcmd("maxslopeangle", {"msa"}, function(args, speaker)
	local sangle = args[1] or 89
	if isNumber(sangle) then
		speaker.Character:FindFirstChildWhichIsA("Humanoid").MaxSlopeAngle = sangle
	end
end)
addcmd("gravity", {"grav"}, function(args, speaker)
	local grav = args[1] or oldgrav
	if isNumber(grav) then
		workspace.Gravity = grav
	end
end)
addcmd("hipheight", {"hheight"}, function(args, speaker)
	local hipHeight = args[1] or (r15(speaker) and 2.1 or 0)
	if isNumber(hipHeight) then
		speaker.Character:FindFirstChildWhichIsA("Humanoid").HipHeight = hipHeight
	end
end)
addcmd("dance", {}, function(args, speaker)
	pcall(execCmd, "undance")
	local dances = {"27789359", "30196114", "248263260", "45834924", "33796059", "28488254", "52155728"}
	if r15(speaker) then
		dances = {"3333432454", "4555808220", "4049037604", "4555782893", "10214311282", "10714010337", "10713981723", "10714372526", "10714076981", "10714392151", "11444443576"}
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. dances[math.random(1, #dances)]
	danceTrack = speaker.Character:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(animation)
	danceTrack.Looped = true
	danceTrack:Play()
end)
addcmd("undance", {"nodance"}, function(args, speaker)
	danceTrack:Stop()
	danceTrack:Destroy()
end)
addcmd('nolimbs',{'rlimbs'},function(args, speaker)
	if r15(speaker) then
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "RightUpperLeg" or
				v.Name == "LeftUpperLeg" or
				v.Name == "RightUpperArm" or
				v.Name == "LeftUpperArm" then
				v:Destroy()
			end
		end
	else
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "Right Leg" or
				v.Name == "Left Leg" or
				v.Name == "Right Arm" or
				v.Name == "Left Arm" then
				v:Destroy()
			end
		end
	end
end)
addcmd('noarms',{'rarms'},function(args, speaker)
	if r15(speaker) then
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "RightUpperArm" or
				v.Name == "LeftUpperArm" then
				v:Destroy()
			end
		end
	else
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "Right Arm" or
				v.Name == "Left Arm" then
				v:Destroy()
			end
		end
	end
end)
addcmd('nolegs',{'rlegs'},function(args, speaker)
	if r15(speaker) then
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "RightUpperLeg" or
				v.Name == "LeftUpperLeg" then
				v:Destroy()
			end
		end
	else
		for i,v in pairs(speaker.Character:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "Right Leg" or
				v.Name == "Left Leg" then
				v:Destroy()
			end
		end
	end
end)
addcmd("sit", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid").Sit = true
end)
addcmd("lay", {"laydown"}, function(args, speaker)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	humanoid.Sit = true
	task.wait(0.1)
	humanoid.RootPart.CFrame = humanoid.RootPart.CFrame * CFrame.Angles(math.pi * 0.5, 0, 0)
	for _, v in ipairs(humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end)
addcmd("sitwalk", {}, function(args, speaker)
	local anims = speaker.Character.Animate
	local sit = anims.sit:FindFirstChildWhichIsA("Animation").AnimationId
	anims.idle:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.walk:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.run:FindFirstChildWhichIsA("Animation").AnimationId = sit
	anims.jump:FindFirstChildWhichIsA("Animation").AnimationId = sit
	speaker.Character:FindFirstChildWhichIsA("Humanoid").HipHeight = not r15(speaker) and -1.5 or 0.5
end)
addcmd("nosit", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Seated, false)
end)
addcmd("unnosit", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Seated, true)
end)
addcmd("jump", {}, function(args, speaker)
	speaker.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
end)
local infJump
infJumpDebounce = false
addcmd("infjump", {"infinitejump"}, function(args, speaker)
	if infJump then infJump:Disconnect() end
	infJumpDebounce = false
	infJump = UserInputService.JumpRequest:Connect(function()
		if not infJumpDebounce then
			infJumpDebounce = true
			speaker.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
			wait()
			infJumpDebounce = false
		end
	end)
end)
addcmd("uninfjump", {"uninfinitejump", "noinfjump", "noinfinitejump"}, function(args, speaker)
	if infJump then infJump:Disconnect() end
	infJumpDebounce = false
end)
local flyjump
addcmd("flyjump", {}, function(args, speaker)
	if flyjump then flyjump:Disconnect() end
	flyjump = UserInputService.JumpRequest:Connect(function()
		speaker.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
	end)
end)
addcmd("unflyjump", {"noflyjump"}, function(args, speaker)
	if flyjump then flyjump:Disconnect() end
end)
local HumanModCons = {}
addcmd('autojump',{'ajump'},function(args, speaker)
	local Char = speaker.Character
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local autoJump = function()
		if Char and Human then
			local check1 = workspace:FindPartOnRay(Ray.new(Human.RootPart.Position-Vector3.new(0,1.5,0), Human.RootPart.CFrame.lookVector*3), Human.Parent)
			local check2 = workspace:FindPartOnRay(Ray.new(Human.RootPart.Position+Vector3.new(0,1.5,0), Human.RootPart.CFrame.lookVector*3), Human.Parent)
			if check1 or check2 then
				Human.Jump = true
			end
		end
	end
	autoJump()
	HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or RunService.RenderStepped:Connect(autoJump)
	HumanModCons.ajCA = (HumanModCons.ajCA and HumanModCons.ajCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
		Char, Human = nChar, nChar:WaitForChild("Humanoid")
		autoJump()
		HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or RunService.RenderStepped:Connect(autoJump)
	end)
end)
addcmd('unautojump',{'noautojump', 'noajump', 'unajump'},function(args, speaker)
	HumanModCons.ajLoop = (HumanModCons.ajLoop and HumanModCons.ajLoop:Disconnect() and false) or nil
	HumanModCons.ajCA = (HumanModCons.ajCA and HumanModCons.ajCA:Disconnect() and false) or nil
end)
addcmd('edgejump',{'ejump'},function(args, speaker)
	local Char = speaker.Character
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local state
	local laststate
	local lastcf
	local edgejump = function()
		if Char and Human then
			laststate = state
			state = Human:GetState()
			if laststate ~= state and state == Enum.HumanoidStateType.Freefall and laststate ~= Enum.HumanoidStateType.Jumping then
				Char.Humanoid.RootPart.CFrame = lastcf
				Char.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new(Char.Humanoid.RootPart.AssemblyLinearVelocity.X, Human.JumpPower or Human.JumpHeight, Char.Humanoid.RootPart.AssemblyLinearVelocity.Z)
			end
			lastcf = Char.Humanoid.RootPart.CFrame
		end
	end
	edgejump()
	HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or RunService.RenderStepped:Connect(edgejump)
	HumanModCons.ejCA = (HumanModCons.ejCA and HumanModCons.ejCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
		Char, Human = nChar, nChar:WaitForChild("Humanoid")
		edgejump()
		HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or RunService.RenderStepped:Connect(edgejump)
	end)
end)
addcmd('unedgejump',{'noedgejump', 'noejump', 'unejump'},function(args, speaker)
	HumanModCons.ejLoop = (HumanModCons.ejLoop and HumanModCons.ejLoop:Disconnect() and false) or nil
	HumanModCons.ejCA = (HumanModCons.ejCA and HumanModCons.ejCA:Disconnect() and false) or nil
end)
addcmd("team", {}, function(args, speaker)
	local teamName = getstring(1, args)
	local team = nil
	local root = speaker.Character and getRoot(speaker.Character)
	for _, v in ipairs(Teams:GetChildren()) do
		if v.Name:lower():match(teamName:lower()) then
			team = v
			break
		end
	end
	if not team then
		return notify("Invalid Team", teamName .. " is not a valid team")
	end
	if root and firetouchinterest then
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("SpawnLocation") and v.BrickColor == team.TeamColor and v.AllowTeamChangeOnTouch == true then
				firetouchinterest(v, root, 0)
				firetouchinterest(v, root, 1)
				break
			end
		end
	else
		speaker.Team = team
	end
end)
addcmd('nobgui',{'unbgui','nobillboardgui','unbillboardgui','noname','rohg'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants())do
		if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
			v:Destroy()
		end
	end
end)
addcmd('loopnobgui',{'loopunbgui','loopnobillboardgui','loopunbillboardgui','loopnoname','looprohg'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants())do
		if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
			v:Destroy()
		end
	end
	local function charPartAdded(part)
		if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
			wait()
			part:Destroy()
		end
	end
	charPartTrigger = speaker.Character.DescendantAdded:Connect(charPartAdded)
end)
addcmd('unloopnobgui',{'unloopunbgui','unloopnobillboardgui','unloopunbillboardgui','unloopnoname','unlooprohg'},function(args, speaker)
	if charPartTrigger then
		charPartTrigger:Disconnect()
	end
end)
addcmd('spasm',{},function(args, speaker)
	if not r15(speaker) then
		local pchar=speaker.Character
		local AnimationId = "33796059"
		SpasmAnim = Instance.new("Animation")
		SpasmAnim.AnimationId = "rbxassetid://"..AnimationId
		Spasm = pchar:FindFirstChildOfClass('Humanoid'):LoadAnimation(SpasmAnim)
		Spasm:Play()
		Spasm:AdjustSpeed(99)
	else
		notify('R6 Required','This command requires the r6 rig type')
	end
end)
addcmd('unspasm',{'nospasm'},function(args, speaker)
	Spasm:Stop()
	SpasmAnim:Destroy()
end)
addcmd('headthrow',{},function(args, speaker)
	if not r15(speaker) then
		local AnimationId = "35154961"
		local Anim = Instance.new("Animation")
		Anim.AnimationId = "rbxassetid://"..AnimationId
		local k = speaker.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(Anim)
		k:Play(0)
		k:AdjustSpeed(1)
	else
		notify('R6 Required','This command requires the r6 rig type')
	end
end)
function anim2track(asset_id)
	local objs = game:GetObjects(asset_id)
	for i = 1, #objs do
		if objs[i]:IsA("Animation") then
			return objs[i].AnimationId
		end
	end
	return asset_id
end
addcmd("animation", {"anim"}, function(args, speaker)
	local animid = tostring(args[1])
	if not animid:find("rbxassetid://") then
		animid = "rbxassetid://" .. animid
	end
	animid = anim2track(animid)
	local animation = Instance.new("Animation")
	animation.AnimationId = animid
	local anim = speaker.Character:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(animation)
	anim.Priority = Enum.AnimationPriority.Movement
	anim:Play()
	if args[2] then anim:AdjustSpeed(tostring(args[2])) end
end)
addcmd("emote", {"em"}, function(args, speaker)
	local anim = humanoid:PlayEmoteAndGetAnimTrackById(args[1])
	if args[2] then anim:AdjustSpeed(tostring(args[2])) end
end)
addcmd('noanim',{},function(args, speaker)
	speaker.Character.Animate.Disabled = true
end)
addcmd('reanim',{},function(args, speaker)
	speaker.Character.Animate.Disabled = false
end)
addcmd('animspeed',{},function(args, speaker)
	local Char = speaker.Character
	local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
	for i,v in next, Hum:GetPlayingAnimationTracks() do
		v:AdjustSpeed(tonumber(args[1] or 1))
	end
end)
addcmd('copyanimation',{'copyanim','copyemote'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for _,v in ipairs(players)do
		local char = Players[v].Character
		for _, v1 in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetPlayingAnimationTracks()) do
			v1:Stop()
		end
		for _, v1 in pairs(Players[v].Character:FindFirstChildOfClass('Humanoid'):GetPlayingAnimationTracks()) do
			if not string.find(v1.Animation.AnimationId, "507768375") then
				local ANIM = speaker.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(v1.Animation)
				ANIM:Play(.1, 1, v1.Speed)
				ANIM.TimePosition = v1.TimePosition
				task.spawn(function()
					v1.Stopped:Wait()
					ANIM:Stop()
					ANIM:Destroy()
				end)
			end
		end
	end
end)
addcmd("copyanimationid", {"copyanimid", "copyemoteid"}, function(args, speaker)
	local copyAnimId = function(player)
		local found = "Animations Copied"
		for _, v in pairs(player.Character:FindFirstChildWhichIsA("Humanoid"):GetPlayingAnimationTracks()) do
			local animationId = v.Animation.AnimationId
			local assetId = animationId:find("rbxassetid://") and animationId:match("%d+")
			if not string.find(animationId, "507768375") and not string.find(animationId, "180435571") then
				if assetId then
					local success, result = pcall(function()
						return MarketplaceService:GetProductInfo(tonumber(assetId)).Name
					end)
					local name = success and result or "Failed to get name"
					found = found .. "\n\nName: " .. name .. "\nAnimation Id: " .. animationId
				else
					found = found .. "\n\nAnimation Id: " .. animationId
				end
			end
		end
		if found ~= "Animations Copied" then
			toClipboard(found)
		else
			notify("Animations", "No animations to copy")
		end
	end
	if args[1] then
		copyAnimId(Players[getPlayer(args[1], speaker)[1]])
	else
		copyAnimId(speaker)
	end
end)
addcmd('stopanimations',{'stopanims','stopanim'},function(args, speaker)
	local Char = speaker.Character
	local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
	for i,v in next, Hum:GetPlayingAnimationTracks() do
		v:Stop()
	end
end)
addcmd('refreshanimations', {'refreshanimation', 'refreshanims', 'refreshanim'}, function(args, speaker)
	local Char = speaker.Character or speaker.CharacterAdded:Wait()
	local Human = Char and Char:WaitForChild('Humanoid', 15)
	local Animate = Char and Char:WaitForChild('Animate', 15)
	if not Human or not Animate then
		return notify('Refresh Animations', 'Failed to get Animate/Humanoid')
	end
	Animate.Disabled = true
	for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
		v:Stop()
	end
	Animate.Disabled = false
end)
addcmd('allowcustomanim', {'allowcustomanimations'}, function(args, speaker)
	StarterPlayer.AllowCustomAnimations = true
	execCmd('refreshanimations')
end)
addcmd('unallowcustomanim', {'unallowcustomanimations'}, function(args, speaker)
	StarterPlayer.AllowCustomAnimations = false
	execCmd('refreshanimations')
end)
addcmd('loopanimation', {'loopanim'},function(args, speaker)
	local Char = speaker.Character
	local Human = Char and Char.FindFirstChildWhichIsA(Char, "Humanoid")
	for _, v in ipairs(Human.GetPlayingAnimationTracks(Human)) do
		v.Looped = true
	end
end)
addcmd('tpposition',{'tppos'},function(args, speaker)
	if #args < 3 then return end
	local tpX,tpY,tpZ = tonumber((args[1]:gsub(",", ""))),tonumber((args[2]:gsub(",", ""))),tonumber((args[3]:gsub(",", "")))
	local char = speaker.Character
	if char and getRoot(char) then
		getRoot(char).CFrame = CFrame.new(tpX,tpY,tpZ)
	end
end)
addcmd('tweentpposition',{'ttppos'},function(args, speaker)
	if #args < 3 then return end
	local tpX,tpY,tpZ = tonumber((args[1]:gsub(",", ""))),tonumber((args[2]:gsub(",", ""))),tonumber((args[3]:gsub(",", "")))
	local char = speaker.Character
	if char and getRoot(char) then
		TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(tpX,tpY,tpZ)}):Play()
	end
end)
addcmd("offset", {}, function(args, speaker)
    if #args < 3 then return end
    speaker.Character:TranslateBy(Vector3.new(tonumber(args[1]) or 0, tonumber(args[2]) or 0, tonumber(args[3]) or 0))
end)
addcmd("tweenoffset", {"toffset"}, function(args, speaker)
    if #args < 3 then return end
    local tpX, tpY, tpZ = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    local root = getRoot(speaker.Character)
    local pos = root.Position + Vector3.new(tpX, tpY, tpZ)
    TweenService:Create(root, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)}):Play()
    breakVelocity()
end)
addcmd("clickteleport", {}, function(args, speaker)
    if speaker ~= Players.LocalPlayer then return end
    notify("Click TP", "Go to Settings > Keybinds > Add to set up click teleport")
end)
addcmd("mouseteleport", {"mousetp"}, function(args, speaker)
    local root = getRoot(speaker.Character)
    local pos = IYMouse.Hit
    if root and pos then
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z, select(4, root.CFrame:components()))
        breakVelocity()
    end
end)
addcmd("tptool", {"teleporttool"}, function(args, speaker)
    local TpTool = Instance.new("Tool")
    TpTool.Name = "Teleport Tool"
    TpTool.RequiresHandle = false
    TpTool.Parent = speaker:FindFirstChildOfClass("Backpack")
    TpTool.Activated:Connect(function()
        local root = getRoot(speaker.Character)
        local pos = IYMouse.Hit
        if not root or not pos then return end
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z, select(4, root.CFrame:components()))
        breakVelocity()
    end)
end)
addcmd("thru", {}, function(args, speaker)
    local root = getRoot(speaker.Character)
    local num = tonumber(args[1]) or 5
    local pos = root.CFrame.Position + (root.CFrame.LookVector * num)
    root.CFrame = CFrame.new(pos, pos + root.CFrame.LookVector)
end)
addcmd('clickdelete',{},function(args, speaker)
	if speaker == Players.LocalPlayer then
		notify('Click Delete','Go to Settings > Keybinds > Add to set up click delete')
	end
end)
addcmd('getposition',{'getpos','notifypos','notifyposition'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		local char = Players[v].Character
		local pos = char and (getRoot(char) or char:FindFirstChildWhichIsA("BasePart"))
		pos = pos and pos.Position
		if not pos then
			return notify('Getposition Error','Missing character')
		end
		local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)
		notify('Current Position',roundedPos)
	end
end)
addcmd('copyposition',{'copypos'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		local char = Players[v].Character
		local pos = char and (getRoot(char) or char:FindFirstChildWhichIsA("BasePart"))
		pos = pos and pos.Position
		if not pos then
			return notify('Getposition Error','Missing character')
		end
		local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)
		toClipboard(roundedPos)
	end
end)
addcmd('walktopos',{'walktoposition'},function(args, speaker)
	if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
		speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
		wait(.1)
	end
	speaker.Character:FindFirstChildOfClass('Humanoid').WalkToPoint = Vector3.new(args[1],args[2],args[3])
end)
addcmd('speed',{'ws','walkspeed'},function(args, speaker)
	if args[2] then
		local speed = args[2] or 16
		if isNumber(speed) then
			speaker.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = speed
		end
	else
		local speed = args[1] or 16
		if isNumber(speed) then
			speaker.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = speed
		end
	end
end)
addcmd('spoofspeed',{'spoofws','spoofwalkspeed'},function(args, speaker)
	if args[1] and isNumber(args[1]) then
		if hookmetamethod then
			local char = speaker.Character
			local setspeed;
			local index; index = hookmetamethod(game, "__index", function(self, key)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "walkSpeed") and self:IsDescendantOf(char) then
					return setspeed or args[1]
				end
				return index(self, key)
			end)
			local newindex; newindex = hookmetamethod(game, "__newindex", function(self, key, value)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "WalkSpeed" or key == "walkSpeed") and self:IsDescendantOf(char) then
					setspeed = tonumber(value)
				end
				return newindex(self, key, value)
			end)
		else
			notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
		end
	end
end)
addcmd('loopspeed',{'loopws'},function(args, speaker)
	local speed = args[1] or 16
	if args[2] then
		speed = args[2] or 16
	end
	if isNumber(speed) then
		local Char = speaker.Character or workspace:FindFirstChild(speaker.Name)
		local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
		local function WalkSpeedChange()
			if Char and Human then
				Human.WalkSpeed = speed
			end
		end
		WalkSpeedChange()
		HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
		HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
			Char, Human = nChar, nChar:WaitForChild("Humanoid")
			WalkSpeedChange()
			HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
		end)
	end
end)
addcmd('unloopspeed',{'unloopws'},function(args, speaker)
	HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or nil
	HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or nil
end)
addcmd('spoofjumppower',{'spoofjp'},function(args, speaker)
	if args[1] and isNumber(args[1]) then
		if hookmetamethod then
			local char = speaker.Character
			local setpower;
			local index; index = hookmetamethod(game, "__index", function(self, key)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "JumpPower" or key == "jumpPower") and self:IsDescendantOf(char) then
					return setpower or args[1]
				end
				return index(self, key)
			end)
			local newindex; newindex = hookmetamethod(game, "__newindex", function(self, key, value)
				if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") and (key == "JumpPower" or key == "jumpPower") and self:IsDescendantOf(char) then
					setpower = tonumber(value)
				end
				return newindex(self, key, value)
			end)
		else
			notify('Incompatible Exploit','Your exploit does not support this command (missing hookmetamethod)')
		end
	end
end)
addcmd('loopjumppower',{'loopjp','loopjpower'},function(args, speaker)
	local jpower = args[1] or 50
	if isNumber(jpower) then
		local Char = speaker.Character or workspace:FindFirstChild(speaker.Name)
		local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
		local function JumpPowerChange()
			if Char and Human then
				if speaker.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
					speaker.Character:FindFirstChildOfClass('Humanoid').JumpPower = jpower
				else
					speaker.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = jpower
				end
			end
		end
		JumpPowerChange()
		HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
		HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or speaker.CharacterAdded:Connect(function(nChar)
			Char, Human = nChar, nChar:WaitForChild("Humanoid")
			JumpPowerChange()
			HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
		end)
	end
end)
addcmd('unloopjumppower',{'unloopjp','unloopjpower'},function(args, speaker)
	local Char = speaker.Character or workspace:FindFirstChild(speaker.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or nil
	HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or nil
	if Char and Human then
		if speaker.Character:FindFirstChildOfClass('Humanoid').UseJumpPower then
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpPower = 50
		else
			speaker.Character:FindFirstChildOfClass('Humanoid').JumpHeight  = 50
		end
	end
end)
addcmd('tools',{'gears'},function(args, speaker)
	local function copy(instance)
		for i,c in pairs(instance:GetChildren())do
			if c:IsA('Tool') or c:IsA('HopperBin') then
				c:Clone().Parent = speaker:FindFirstChildOfClass("Backpack")
			end
			copy(c)
		end
	end
	copy(Lighting)
	local function copy(instance)
		for i,c in pairs(instance:GetChildren())do
			if c:IsA('Tool') or c:IsA('HopperBin') then
				c:Clone().Parent = speaker:FindFirstChildOfClass("Backpack")
			end
			copy(c)
		end
	end
	copy(ReplicatedStorage)
	notify('Tools','Copied tools from ReplicatedStorage and Lighting')
end)
addcmd('notools',{'rtools','clrtools','removetools','deletetools','dtools'},function(args, speaker)
	for i,v in pairs(speaker:FindFirstChildOfClass("Backpack"):GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
end)
addcmd('deleteselectedtool',{'dst'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA('Tool') or v:IsA('HopperBin') then
			v:Destroy()
		end
	end
end)
addcmd("console", {}, function(args, speaker)
	StarterGui:SetCore("DevConsoleVisible", true)
end)
addcmd('oldconsole',{},function(args, speaker)
	notify("Loading",'Hold on a sec')
	local _, str = pcall(function()
		return game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/main/console.lua"), true)
	end)
	local s, e = loadstring(str)
	if typeof(s) ~= "function" then
		return
	end
	local success, message = pcall(s)
	if (not success) then
		if printconsole then
			printconsole(message)
		elseif printoutput then
			printoutput(message)
		end
	end
	wait(1)
	notify('Console','Press F9 to open the console')
end)
addcmd("explorer", {"dex"}, function(args, speaker)
	notify("Loading", "Hold on a sec")
	loadstring(game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua")))()
end)
addcmd('olddex', {'odex'}, function(args, speaker)
	notify('Loading old explorer', 'Hold on a sec')
	local getobjects = function(a)
		local Objects = {}
		if a then
			local b = InsertService:LoadLocalAsset(a)
			if b then
				table.insert(Objects, b)
			end
		end
		return Objects
	end
	local Dex = getobjects("rbxassetid://10055842438")[1]
	Dex.Parent = PARENT
	local function Load(Obj, Url)
		local function GiveOwnGlobals(Func, Script)
			local Fenv, RealFenv, FenvMt = {}, {
				script = Script,
				getupvalue = function(a, b)
					return nil
				end,
				getreg = function()
					return {}
				end,
				getprops = getprops or function(inst)
					if getproperties then
						local props = getproperties(inst)
						if props[1] and gethiddenproperty then
							local results = {}
							for _,name in pairs(props) do
								local success, res = pcall(gethiddenproperty, inst, name)
								if success then
									results[name] = res
								end
							end
							return results
						end
						return props
					end
					return {}
				end
			}, {}
			FenvMt.__index = function(a,b)
				return RealFenv[b] == nil and getgenv()[b] or RealFenv[b]
			end
			FenvMt.__newindex = function(a, b, c)
				if RealFenv[b] == nil then
					getgenv()[b] = c
				else
					RealFenv[b] = c
				end
			end
			setmetatable(Fenv, FenvMt)
			pcall(setfenv, Func, Fenv)
			return Func
		end
		local function LoadScripts(_, Script)
			if Script:IsA("LocalScript") then
				task.spawn(function()
					GiveOwnGlobals(loadstring(Script.Source,"="..Script:GetFullName()), Script)()
				end)
			end
			table.foreach(Script:GetChildren(), LoadScripts)
		end
		LoadScripts(nil, Obj)
	end
	Load(Dex)
end)
addcmd('remotespy',{'rspy'},function(args, speaker)
	notify("Loading",'Hold on a sec')
	loadstring(game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua")))()
end)
addcmd("executor", {}, function(args, speaker)
    notify("Loading", "Hold on a sec")
    loadstring(game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/executor.lua")))()
end)
addcmd('audiologger',{'alogger'},function(args, speaker)
	notify("Loading",'Hold on a sec')
	loadstring(game:HttpGet(('https://raw.githubusercontent.com/infyiff/backup/main/audiologger.lua'),true))()
end)
local loopgoto = nil
addcmd('loopgoto',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		loopgoto = nil
		if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
			speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
			wait(.1)
		end
		loopgoto = Players[v]
		local distance = 3
		if args[2] and isNumber(args[2]) then
			distance = args[2]
		end
		local lDelay = 0
		if args[3] and isNumber(args[3]) then
			lDelay = args[3]
		end
		repeat
			if Players:FindFirstChild(v) then
				if Players[v].Character ~= nil then
					getRoot(speaker.Character).CFrame = getRoot(Players[v].Character).CFrame + Vector3.new(distance,1,0)
				end
				wait(lDelay)
			else
				loopgoto = nil
			end
		until loopgoto ~= Players[v]
	end
end)
addcmd('unloopgoto',{'noloopgoto'},function(args, speaker)
	loopgoto = nil
end)
addcmd('headsit',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	if headSit then headSit:Disconnect() end
	for i,v in pairs(players)do
		speaker.Character:FindFirstChildOfClass('Humanoid').Sit = true
		headSit = RunService.Heartbeat:Connect(function()
			if Players:FindFirstChild(Players[v].Name) and Players[v].Character ~= nil and getRoot(Players[v].Character) and getRoot(speaker.Character) and speaker.Character:FindFirstChildOfClass('Humanoid').Sit == true then
				getRoot(speaker.Character).CFrame = getRoot(Players[v].Character).CFrame * CFrame.Angles(0,math.rad(0),0)* CFrame.new(0,1.6,0.4)
			else
				headSit:Disconnect()
			end
		end)
	end
end)
addcmd('chat',{'say'},function(args, speaker)
	local cString = getstring(1, args)
	chatMessage(cString)
end)
spamming = false
spamspeed = 1
addcmd('spam',{},function(args, speaker)
	spamming = true
	local spamstring = getstring(1, args)
	repeat wait(spamspeed)
		chatMessage(spamstring)
	until spamming == false
end)
addcmd('nospam',{'unspam'},function(args, speaker)
	spamming = false
end)
addcmd('whisper',{'pm'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			local plrName = Players[v].Name
			local pmstring = getstring(2, args)
			chatMessage("/w "..plrName.." "..pmstring)
		end)
	end
end)
pmspamming = {}
addcmd('pmspam',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			local plrName = Players[v].Name
			if FindInTable(pmspamming, plrName) then return end
			table.insert(pmspamming, plrName)
			local pmspamstring = getstring(2, args)
			repeat
				if Players:FindFirstChild(v) then
					wait(spamspeed)
					chatMessage("/w "..plrName.." "..pmspamstring)
				else
					for a,b in pairs(pmspamming) do if b == plrName then table.remove(pmspamming, a) end end
				end
			until not FindInTable(pmspamming, plrName)
		end)
	end
end)
addcmd('nopmspam',{'unpmspam'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			for a,b in pairs(pmspamming) do
				if b == Players[v].Name then
					table.remove(pmspamming, a)
				end
			end
		end)
	end
end)
addcmd('spamspeed',{},function(args, speaker)
	local speed = args[1] or 1
	if isNumber(speed) then
		spamspeed = speed
	end
end)
addcmd('bubblechat',{},function(args, speaker)
	if isLegacyChat then
		ChatService.BubbleChatEnabled = true
	else
		TextChatService.BubbleChatConfiguration.Enabled = true
	end
end)
addcmd('unbubblechat',{'nobubblechat'},function(args, speaker)
	if isLegacyChat then
		ChatService.BubbleChatEnabled = false
	else
		TextChatService.BubbleChatConfiguration.Enabled = false
	end
end)
addcmd("chatwindow", {}, function(args, speaker)
	TextChatService.ChatWindowConfiguration.Enabled = true
end)
addcmd("unchatwindow", {"nochatwindow"}, function(args, speaker)
	TextChatService.ChatWindowConfiguration.Enabled = false
end)
addcmd("darkchat", {}, function(args, speaker)
    local BCC = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    local CWC = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    local CIBC = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
    if BCC then
        BCC.Enabled = true
        BCC.BackgroundColor3 = Color3.fromRGB()
        BCC.BackgroundTransparency = 0.3
        BCC.TailVisible = true
        BCC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
    end
    if CWC then
        CWC.Enabled = true
        CWC.BackgroundColor3 = Color3.fromRGB()
        CWC.BackgroundTransparency = 0.3
        CWC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CWC.TextStrokeColor3 = Color3.fromRGB()
        CWC.TextStrokeTransparency = 0.5
    end
    if CIBC then
        CIBC.Enabled = true
        CIBC.BackgroundColor3 = Color3.fromRGB()
        CIBC.BackgroundTransparency = 0.5
        CIBC.PlaceholderColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CIBC.TextColor3 = Color3.fromRGB(0xFF, 0xFF, 0xFF)
        CIBC.TextStrokeColor3 = Color3.fromRGB()
        CIBC.TextStrokeTransparency = 0.5
    end
end)
addcmd('blockhead',{},function(args, speaker)
	speaker.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
end)
addcmd('blockhats',{},function(args, speaker)
	for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
		for i,c in pairs(v:GetDescendants()) do
			if c:IsA("SpecialMesh") then
				c:Destroy()
			end
		end
	end
end)
addcmd('blocktool',{},function(args, speaker)
	for _,v in pairs(speaker.Character:GetChildren()) do
		if v:IsA("Tool") or v:IsA("HopperBin") then
			for i,c in pairs(v:GetDescendants()) do
				if c:IsA("SpecialMesh") then
					c:Destroy()
				end
			end
		end
	end
end)
addcmd('creeper',{},function(args, speaker)
	if r15(speaker) then
		speaker.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
		speaker.Character.LeftUpperArm:Destroy()
		speaker.Character.RightUpperArm:Destroy()
		speaker.Character:FindFirstChildOfClass("Humanoid"):RemoveAccessories()
	else
		speaker.Character.Head:FindFirstChildOfClass("SpecialMesh"):Destroy()
		speaker.Character["Left Arm"]:Destroy()
		speaker.Character["Right Arm"]:Destroy()
		speaker.Character:FindFirstChildOfClass("Humanoid"):RemoveAccessories()
	end
end)
function getTorso(x)
	x = x or Players.LocalPlayer.Character
	return x:FindFirstChild("Torso") or x:FindFirstChild("UpperTorso") or x:FindFirstChild("LowerTorso") or x:FindFirstChild("HumanoidRootPart")
end
addcmd("bang", {"rape"}, function(args, speaker)
	execCmd("unbang")
	wait()
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	bangAnim = Instance.new("Animation")
	bangAnim.AnimationId = not r15(speaker) and "rbxassetid://148840371" or "rbxassetid://5918726674"
	bang = humanoid:LoadAnimation(bangAnim)
	bang:Play(0.1, 1, 1)
	bang:AdjustSpeed(args[2] or 3)
	bangDied = humanoid.Died:Connect(function()
		bang:Stop()
		bangAnim:Destroy()
		bangDied:Disconnect()
		bangLoop:Disconnect()
	end)
	if args[1] then
		local players = getPlayer(args[1], speaker)
		for _, v in pairs(players) do
			local bangplr = Players[v].Name
			local bangOffet = CFrame.new(0, 0, 1.1)
			bangLoop = RunService.Stepped:Connect(function()
				pcall(function()
					local otherRoot = getTorso(Players[bangplr].Character)
					getRoot(speaker.Character).CFrame = otherRoot.CFrame * bangOffet
				end)
			end)
		end
	end
end)
addcmd("unbang", {"unrape"}, function(args, speaker)
	if bangDied then
		bangDied:Disconnect()
		bang:Stop()
		bangAnim:Destroy()
		bangLoop:Disconnect()
	end
end)
addcmd('carpet',{},function(args, speaker)
	if not r15(speaker) then
		execCmd('uncarpet')
		wait()
		local players = getPlayer(args[1], speaker)
		for i,v in pairs(players)do
			carpetAnim = Instance.new("Animation")
			carpetAnim.AnimationId = "rbxassetid://282574440"
			carpet = speaker.Character:FindFirstChildOfClass('Humanoid'):LoadAnimation(carpetAnim)
			carpet:Play(.1, 1, 1)
			local carpetplr = Players[v].Name
			carpetDied = speaker.Character:FindFirstChildOfClass'Humanoid'.Died:Connect(function()
				carpetLoop:Disconnect()
				carpet:Stop()
				carpetAnim:Destroy()
				carpetDied:Disconnect()
			end)
			carpetLoop = RunService.Heartbeat:Connect(function()
				pcall(function()
					getRoot(Players.LocalPlayer.Character).CFrame = getRoot(Players[carpetplr].Character).CFrame
				end)
			end)
		end
	else
		notify('R6 Required','This command requires the r6 rig type')
	end
end)
addcmd('uncarpet',{'nocarpet'},function(args, speaker)
	if carpetLoop then
		carpetLoop:Disconnect()
		carpetDied:Disconnect()
		carpet:Stop()
		carpetAnim:Destroy()
	end
end)
addcmd('friend',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		speaker:RequestFriendship(Players[v])
	end
end)
addcmd('unfriend',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		speaker:RevokeFriendship(Players[v])
	end
end)
addcmd('bringpart',{},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			v.CFrame = getRoot(speaker.Character).CFrame
		end
	end
end)
addcmd('bringpartclass',{'bpc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			v.CFrame = getRoot(speaker.Character).CFrame
		end
	end
end)
gotopartDelay = 0.1
addcmd('gotopart',{'topart'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			getRoot(speaker.Character).CFrame = v.CFrame
		end
	end
end)
addcmd('tweengotopart',{'tgotopart','ttopart'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v.CFrame}):Play()
		end
	end
end)
addcmd('gotopartclass',{'gpc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			getRoot(speaker.Character).CFrame = v.CFrame
		end
	end
end)
addcmd('tweengotopartclass',{'tgpc'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.ClassName:lower() == getstring(1, args):lower() and v:IsA("BasePart") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v.CFrame}):Play()
		end
	end
end)
addcmd('gotomodel',{'tomodel'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("Model") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			getRoot(speaker.Character).CFrame = v:GetModelCFrame()
		end
	end
end)
addcmd('tweengotomodel',{'tgotomodel','ttomodel'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v.Name:lower() == getstring(1, args):lower() and v:IsA("Model") then
			if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
				speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
				wait(.1)
			end
			wait(gotopartDelay)
			TweenService:Create(getRoot(speaker.Character), TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear), {CFrame = v:GetModelCFrame()}):Play()
		end
	end
end)
addcmd('gotopartdelay',{},function(args, speaker)
	local gtpDelay = args[1] or 0.1
	if isNumber(gtpDelay) then
		gotopartDelay = gtpDelay
	end
end)
addcmd('noclickdetectorlimits',{'nocdlimits','removecdlimits'},function(args, speaker)
	for i,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ClickDetector") then
			v.MaxActivationDistance = math.huge
		end
	end
end)
addcmd('fireclickdetectors',{'firecd','firecds'}, function(args, speaker)
	if fireclickdetector then
		if args[1] then
			local name = getstring(1, args):lower()
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ClickDetector") and descendant.Name:lower() == name or descendant.Parent.Name:lower() == name then
					fireclickdetector(descendant)
				end
			end
		else
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ClickDetector") then
					fireclickdetector(descendant)
				end
			end
		end
	else
		notify("Incompatible Exploit", "Your exploit does not support this command (missing fireclickdetector)")
	end
end)
addcmd('noproximitypromptlimits',{'nopplimits','removepplimits'},function(args, speaker)
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			v.MaxActivationDistance = math.huge
		end
	end
end)
addcmd('fireproximityprompts',{'firepp'},function(args, speaker)
	if fireproximityprompt then
		if args[1] then
			local name = getstring(1, args)
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") and descendant.Name == name or descendant.Parent.Name == name then
					fireproximityprompt(descendant)
				end
			end
		else
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") then
					fireproximityprompt(descendant)
				end
			end
		end
	else
		notify("Incompatible Exploit", "Your exploit does not support this command (missing fireproximityprompt)")
	end
end)
local PromptButtonHoldBegan = nil
addcmd('instantproximityprompts',{'instantpp'},function(args, speaker)
	if fireproximityprompt then
		execCmd("uninstantproximityprompts")
		wait(0.1)
		PromptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			fireproximityprompt(prompt)
		end)
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing fireproximityprompt)')
	end
end)
addcmd('uninstantproximityprompts',{'uninstantpp'},function(args, speaker)
	if PromptButtonHoldBegan ~= nil then
		PromptButtonHoldBegan:Disconnect()
		PromptButtonHoldBegan = nil
	end
end)
addcmd('notifyping',{'ping'},function(args, speaker)
	notify("Ping", math.round(speaker:GetNetworkPing() * 1000) .. "ms")
end)
addcmd('grabtools', {}, function(args, speaker)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	for _, child in ipairs(workspace:GetChildren()) do
		if speaker.Character and child:IsA("BackpackItem") and child:FindFirstChild("Handle") then
			humanoid:EquipTool(child)
		end
	end
	if grabtoolsFunc then
		grabtoolsFunc:Disconnect()
	end
	grabtoolsFunc = workspace.ChildAdded:Connect(function(child)
		if speaker.Character and child:IsA("BackpackItem") and child:FindFirstChild("Handle") then
			humanoid:EquipTool(child)
		end
	end)
	notify("Grabtools", "Picking up any dropped tools")
end)
addcmd('nograbtools',{'ungrabtools'},function(args, speaker)
	if grabtoolsFunc then
		grabtoolsFunc:Disconnect()
	end
	notify("Grabtools", "Grabtools has been disabled")
end)
local specifictoolremoval = {}
addcmd('removespecifictool',{},function(args, speaker)
	if args[1] and speaker:FindFirstChildOfClass("Backpack") then
		local tool = string.lower(getstring(1, args))
		local RST = RunService.RenderStepped:Connect(function()
			if speaker:FindFirstChildOfClass("Backpack") then
				for i,v in pairs(speaker:FindFirstChildOfClass("Backpack"):GetChildren()) do
					if v.Name:lower() == tool then
						v:Remove()
					end
				end
			end
		end)
		specifictoolremoval[tool] = RST
	end
end)
addcmd('unremovespecifictool',{},function(args, speaker)
	if args[1] then
		local tool = string.lower(getstring(1, args))
		if specifictoolremoval[tool] ~= nil then
			specifictoolremoval[tool]:Disconnect()
			specifictoolremoval[tool] = nil
		end
	end
end)
addcmd('clearremovespecifictool',{},function(args, speaker)
	for obj in pairs(specifictoolremoval) do
		specifictoolremoval[obj]:Disconnect()
		specifictoolremoval[obj] = nil
	end
end)
addcmd('light',{},function(args, speaker)
	local light = Instance.new("PointLight")
	light.Parent = getRoot(speaker.Character)
	light.Range = 30
	if args[1] then
		light.Brightness = args[2]
		light.Range = args[1]
	else
		light.Brightness = 5
	end
end)
addcmd('unlight',{'nolight'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v.ClassName == "PointLight" then
			v:Destroy()
		end
	end
end)
addcmd('copytools',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players)do
		task.spawn(function()
			for i,v in pairs(Players[v]:FindFirstChildOfClass("Backpack"):GetChildren()) do
				if v:IsA('Tool') or v:IsA('HopperBin') then
					v:Clone().Parent = speaker:FindFirstChildOfClass("Backpack")
				end
			end
		end)
	end
end)
addcmd('naked',{},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Clothing") or v:IsA("ShirtGraphic") then
			v:Destroy()
		end
	end
end)
addcmd('noface',{'removeface'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Decal") and v.Name == 'face' then
			v:Destroy()
		end
	end
end)
addcmd('spawnpoint',{'spawn'},function(args, speaker)
	spawnpos = getRoot(speaker.Character).CFrame
	spawnpoint = true
	spDelay = tonumber(args[1]) or 0.1
	notify('Spawn Point','Spawn point created at '..tostring(spawnpos))
end)
addcmd('nospawnpoint',{'nospawn','removespawnpoint'},function(args, speaker)
	spawnpoint = false
	notify('Spawn Point','Removed spawn point')
end)
addcmd('flashback',{'diedtp'},function(args, speaker)
	if lastDeath ~= nil then
		if speaker.Character:FindFirstChildOfClass('Humanoid') and speaker.Character:FindFirstChildOfClass('Humanoid').SeatPart then
			speaker.Character:FindFirstChildOfClass('Humanoid').Sit = false
			wait(.1)
		end
		getRoot(speaker.Character).CFrame = lastDeath
	end
end)
addcmd('hatspin',{'spinhats'},function(args, speaker)
	execCmd('unhatspin')
	wait(.5)
	for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
		local keep = Instance.new("BodyPosition") keep.Name = randomString() keep.Parent = v.Handle
		local spin = Instance.new("BodyAngularVelocity") spin.Name = randomString() spin.Parent = v.Handle
		v.Handle:FindFirstChildOfClass("Weld"):Destroy()
		if args[1] then
			spin.AngularVelocity = Vector3.new(0, args[1], 0)
			spin.MaxTorque = Vector3.new(0, args[1] * 2, 0)
		else
			spin.AngularVelocity = Vector3.new(0, 100, 0)
			spin.MaxTorque = Vector3.new(0, 200, 0)
		end
		keep.P = 30000
		keep.D = 50
		spinhats = RunService.Stepped:Connect(function()
			pcall(function()
				keep.Position = Players.LocalPlayer.Character.Head.Position
			end)
		end)
	end
end)
addcmd('unhatspin',{'unspinhats'},function(args, speaker)
	if spinhats then
		spinhats:Disconnect()
	end
	for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
		v.Parent = workspace
		for i,c in pairs(v.Handle) do
			if c:IsA("BodyPosition") or c:IsA("BodyAngularVelocity") then
				c:Destroy()
			end
		end
		wait()
		v.Parent = speaker.Character
	end
end)
addcmd('clearhats',{'cleanhats'},function(args, speaker)
	if firetouchinterest then
		local Player = Players.LocalPlayer
		local Character = Player.Character
		local Old = getRoot(Character).CFrame
		local Hats = {}
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Accessory") then
				table.insert(Hats, child)
			end
		end
		for _, accessory in ipairs(Character:FindFirstChildOfClass("Humanoid"):GetAccessories()) do
			accessory:Destroy()
		end
		for i = 1, #Hats do
			repeat RunService.Heartbeat:wait() until Hats[i]
			firetouchinterest(Hats[i].Handle,getRoot(Character),0)
			repeat RunService.Heartbeat:wait() until Character:FindFirstChildOfClass("Accessory")
			Character:FindFirstChildOfClass("Accessory"):Destroy()
			repeat RunService.Heartbeat:wait() until not Character:FindFirstChildOfClass("Accessory")
		end
		execCmd("reset")
		Player.CharacterAdded:Wait()
		for i = 1,20 do
			RunService.Heartbeat:Wait()
			if getRoot(Player.Character) then
				getRoot(Player.Character).Humanoid.RootPart.CFrame = Old
			end
		end
	else
		notify("Incompatible Exploit","Your exploit does not support this command (missing firetouchinterest)")
	end
end)
addcmd('split',{},function(args, speaker)
	if r15(speaker) then
		speaker.Character.UpperTorso.Waist:Destroy()
	else
		notify('R15 Required','This command requires the r15 rig type')
	end
end)
addcmd('nilchar',{},function(args, speaker)
	if speaker.Character ~= nil then
		speaker.Character.Parent = nil
	end
end)
addcmd('unnilchar',{'nonilchar'},function(args, speaker)
	if speaker.Character ~= nil then
		speaker.Character.Parent = workspace
	end
end)
addcmd('noroot',{'removeroot','rroot'},function(args, speaker)
	if speaker.Character ~= nil then
		local char = Players.LocalPlayer.Character
		char.Parent = nil
		char.Humanoid.RootPart:Destroy()
		char.Parent = workspace
	end
end)
addcmd('replaceroot',{'replacerootpart'},function(args, speaker)
	if speaker.Character ~= nil and getRoot(speaker.Character) then
		local Char = speaker.Character
		local OldParent = Char.Parent
		local HRP = Char and getRoot(Char)
		local OldPos = HRP.CFrame
		Char.Parent = game
		local HRP1 = HRP:Clone()
		HRP1.Parent = Char
		HRP = HRP:Destroy()
		HRP1.CFrame = OldPos
		Char.Parent = OldParent
	end
end)
addcmd('clearcharappearance',{'clearchar','clrchar'},function(args, speaker)
	speaker:ClearCharacterAppearance()
end)
addcmd('equiptools',{},function(args, speaker)
	for i,v in pairs(speaker:FindFirstChildOfClass("Backpack"):GetChildren()) do
		if v:IsA("Tool") or v:IsA("HopperBin") then
			v.Parent = speaker.Character
		end
	end
end)
addcmd('unequiptools',{},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
end)
function GetHandleTools(p)
	p = p or Players.LocalPlayer
	local r = {}
	for _, v in ipairs(p.Character and p.Character:GetChildren() or {}) do
		if v.IsA(v, "BackpackItem") and v.FindFirstChild(v, "Handle") then
			r[#r + 1] = v
		end
	end
	for _, v in ipairs(p.Backpack:GetChildren()) do
		if v.IsA(v, "BackpackItem") and v.FindFirstChild(v, "Handle") then
			r[#r + 1] = v
		end
	end
	return r
end
addcmd('dupetools', {'clonetools'}, function(args, speaker)
	local LOOP_NUM = tonumber(args[1]) or 1
	local OrigPos = speaker.Character.Humanoid.RootPart.Position
	local Tools, TempPos = {}, Vector3.new(math.random(-2e5, 2e5), 2e5, math.random(-2e5, 2e5))
	for i = 1, LOOP_NUM do
		local Human = speaker.Character:WaitForChild("Humanoid")
		wait(.1, Human.Parent:MoveTo(TempPos))
		Human.RootPart.Anchored = speaker:ClearCharacterAppearance(wait(.1)) or true
		local t = GetHandleTools(speaker)
		while #t > 0 do
			for _, v in ipairs(t) do
				task.spawn(function()
					for _ = 1, 25 do
						v.Parent = speaker.Character
						v.Handle.Anchored = true
					end
					for _ = 1, 5 do
						v.Parent = workspace
					end
					table.insert(Tools, v.Handle)
				end)
			end
			t = GetHandleTools(speaker)
		end
		wait(.1)
		speaker.Character = speaker.Character:Destroy()
		speaker.CharacterAdded:Wait():WaitForChild("Humanoid").Parent:MoveTo(LOOP_NUM == i and OrigPos or TempPos, wait(.1))
		if i == LOOP_NUM or i % 5 == 0 then
			local HRP = speaker.Character.Humanoid.RootPart
			if type(firetouchinterest) == "function" then
				for _, v in ipairs(Tools) do
					v.Anchored = not firetouchinterest(v, HRP, 1, firetouchinterest(v, HRP, 0)) and false or false
				end
			else
				for _, v in ipairs(Tools) do
					task.spawn(function()
						local x = v.CanCollide
						v.CanCollide = false
						v.Anchored = false
						for _ = 1, 10 do
							v.CFrame = HRP.CFrame
							wait()
						end
						v.CanCollide = x
					end)
				end
			end
			wait(.1)
			Tools = {}
		end
		TempPos = TempPos + Vector3.new(10, math.random(-5, 5), 0)
	end
end)
addcmd('touchinterests', {'touchinterest', 'firetouchinterests', 'firetouchinterest'}, function(args, speaker)
	local Root = getRoot(speaker.Character) or speaker.Character:FindFirstChildWhichIsA("BasePart")
	if not firetouchinterest then
		notify("Incompatible Exploit", "Your exploit does not support this command (missing firetouchinterest)")
		return
	end
	local function Touch(x)
		x = x.FindFirstAncestorWhichIsA(x, "Part")
		if x then
			return task.spawn(function()
				firetouchinterest(x, Root, 1, wait() and firetouchinterest(x, Root, 0))
			end)
		end
		x.CFrame = Root.CFrame
	end
	if args[1] then
		local name = getstring(1, args):lower()
		print(name..' -name')
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("TouchTransmitter") and v.Name:lower() == name or v.Parent.Name:lower() == name then
				Touch(v)
			end
		end
	else
		for _, v in ipairs(workspace:GetDescendants()) do
			if v.IsA(v, "TouchTransmitter") then
				Touch(v)
			end
		end
	end
end)
addcmd('fullbright',{'fb','fullbrightness'},function(args, speaker)
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 100000
	Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end)
addcmd('loopfullbright',{'loopfb'},function(args, speaker)
	if brightLoop then
		brightLoop:Disconnect()
	end
	local brightFunc = function()
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end
	brightLoop = RunService.RenderStepped:Connect(brightFunc)
end)
addcmd('unloopfullbright',{'unloopfb'},function(args, speaker)
	if brightLoop then
		brightLoop:Disconnect()
	end
end)
addcmd('ambient',{},function(args, speaker)
	Lighting.Ambient = Color3.new(args[1],args[2],args[3])
	Lighting.OutdoorAmbient = Color3.new(args[1],args[2],args[3])
end)
addcmd('day',{},function(args, speaker)
	Lighting.ClockTime = 14
end)
addcmd('night',{},function(args, speaker)
	Lighting.ClockTime = 0
end)
addcmd('nofog',{},function(args, speaker)
	Lighting.FogEnd = 100000
	for i,v in pairs(Lighting:GetDescendants()) do
		if v:IsA("Atmosphere") then
			v:Destroy()
		end
	end
end)
addcmd('brightness',{},function(args, speaker)
	Lighting.Brightness = args[1]
end)
addcmd('globalshadows',{'gshadows'},function(args, speaker)
	Lighting.GlobalShadows = true
end)
addcmd('unglobalshadows',{'nogshadows','ungshadows','noglobalshadows'},function(args, speaker)
	Lighting.GlobalShadows = false
end)
origsettings = {abt = Lighting.Ambient, oabt = Lighting.OutdoorAmbient, brt = Lighting.Brightness, time = Lighting.ClockTime, fe = Lighting.FogEnd, fs = Lighting.FogStart, gs = Lighting.GlobalShadows}
addcmd('restorelighting',{'rlighting'},function(args, speaker)
	Lighting.Ambient = origsettings.abt
	Lighting.OutdoorAmbient = origsettings.oabt
	Lighting.Brightness = origsettings.brt
	Lighting.ClockTime = origsettings.time
	Lighting.FogEnd = origsettings.fe
	Lighting.FogStart = origsettings.fs
	Lighting.GlobalShadows = origsettings.gs
end)
addcmd('stun',{'platformstand'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
end)
addcmd('unstun',{'nostun','unplatformstand','noplatformstand'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
end)
addcmd('norotate',{'noautorotate'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').AutoRotate  = false
end)
addcmd('unnorotate',{'autorotate'},function(args, speaker)
	speaker.Character:FindFirstChildOfClass('Humanoid').AutoRotate  = true
end)
addcmd('enablestate',{},function(args, speaker)
	local x = args[1]
	if not tonumber(x) then
		local x = Enum.HumanoidStateType[args[1]]
	end
	speaker.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(x, true)
end)
addcmd('disablestate',{},function(args, speaker)
	local x = args[1]
	if not tonumber(x) then
		local x = Enum.HumanoidStateType[args[1]]
	end
	speaker.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(x, false)
end)
addcmd('drophats',{'drophat'},function(args, speaker)
	if speaker.Character then
		for _,v in pairs(speaker.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do
			v.Parent = workspace
		end
	end
end)
addcmd('deletehats',{'nohats','rhats'},function(args, speaker)
	for i,v in next, speaker.Character:GetDescendants() do
		if v:IsA("Accessory") then
			for i,p in next, v:GetDescendants() do
				if p:IsA("Weld") then
					p:Destroy()
				end
			end
		end
	end
end)
addcmd('droptools',{'droptool'},function(args, speaker)
	for i,v in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = Players.LocalPlayer.Character
		end
	end
	wait()
	for i,v in pairs(Players.LocalPlayer.Character:GetChildren()) do
		if v:IsA("Tool") then
			v.Parent = workspace
		end
	end
end)
addcmd('droppabletools',{},function(args, speaker)
	if speaker.Character then
		for _,obj in pairs(speaker.Character:GetChildren()) do
			if obj:IsA("Tool") then
				obj.CanBeDropped = true
			end
		end
	end
	if speaker:FindFirstChildOfClass("Backpack") then
		for _,obj in pairs(speaker:FindFirstChildOfClass("Backpack"):GetChildren()) do
			if obj:IsA("Tool") then
				obj.CanBeDropped = true
			end
		end
	end
end)
local currentToolSize = ""
local currentGripPos = ""
addcmd('reach',{},function(args, speaker)
	execCmd('unreach')
	wait()
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			if args[1] then
				currentToolSize = v.Handle.Size
				currentGripPos = v.GripPos
				local a = Instance.new("SelectionBox")
				a.Name = "SelectionBoxCreated"
				a.Parent = v.Handle
				a.Adornee = v.Handle
				v.Handle.Massless = true
				v.Handle.Size = Vector3.new(0.5,0.5,args[1])
				v.GripPos = Vector3.new(0,0,0)
				speaker.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
			else
				currentToolSize = v.Handle.Size
				currentGripPos = v.GripPos
				local a = Instance.new("SelectionBox")
				a.Name = "SelectionBoxCreated"
				a.Parent = v.Handle
				a.Adornee = v.Handle
				v.Handle.Massless = true
				v.Handle.Size = Vector3.new(0.5,0.5,60)
				v.GripPos = Vector3.new(0,0,0)
				speaker.Character:FindFirstChildOfClass('Humanoid'):UnequipTools()
			end
		end
	end
end)
addcmd("boxreach", {}, function(args, speaker)
	execCmd("unreach")
	wait()
	for i, v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			local size = tonumber(args[1]) or 60
			currentToolSize = v.Handle.Size
			currentGripPos = v.GripPos
			local a = Instance.new("SelectionBox")
			a.Name = "SelectionBoxCreated"
			a.Parent = v.Handle
			a.Adornee = v.Handle
			v.Handle.Massless = true
			v.Handle.Size = Vector3.new(size, size, size)
			v.GripPos = Vector3.new(0, 0, 0)
			speaker.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
		end
	end
end)
addcmd('unreach',{'noreach','unboxreach'},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			v.Handle.Size = currentToolSize
			v.GripPos = currentGripPos
			v.Handle.SelectionBoxCreated:Destroy()
		end
	end
end)
addcmd('grippos',{},function(args, speaker)
	for i,v in pairs(speaker.Character:GetDescendants()) do
		if v:IsA("Tool") then
			v.Parent = speaker:FindFirstChildOfClass("Backpack")
			v.GripPos = Vector3.new(args[1],args[2],args[3])
			v.Parent = speaker.Character
		end
	end
end)
addcmd('usetools', {}, function(args, speaker)
	local Backpack = speaker:FindFirstChildOfClass("Backpack")
	local amount = tonumber(args[1]) or 1
	local delay_ = tonumber(args[2]) or false
	for _, v in ipairs(Backpack:GetChildren()) do
		v.Parent = speaker.Character
		task.spawn(function()
			for _ = 1, amount do
				v:Activate()
				if delay_ then
					wait(delay_)
				end
			end
			v.Parent = Backpack
		end)
	end
end)
addcmd("logs", {}, function(args, speaker)
	logsEnabled = true
	jLogsEnabled = true
	Toggle.Text = "Enabled"
	Toggle_2.Text = "Enabled"
	logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
end)
addcmd("chatlogs", {"clogs"}, function(args, speaker)
	logsEnabled = true
	join.Visible = false
	chat.Visible = true
	table.remove(shade3, table.find(shade3, selectChat))
	table.remove(shade2, table.find(shade2, selectJoin))
	table.insert(shade2, selectChat)
	table.insert(shade3, selectJoin)
	selectJoin.BackgroundColor3 = currentShade3
	selectChat.BackgroundColor3 = currentShade2
	Toggle.Text = "Enabled"
	logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
end)
addcmd("joinlogs", {"jlogs"}, function(args, speaker)
	jLogsEnabled = true
	chat.Visible = false
	join.Visible = true
	table.remove(shade3, table.find(shade3, selectJoin))
	table.remove(shade2, table.find(shade2, selectChat))
	table.insert(shade2, selectJoin)
	table.insert(shade3, selectChat)
	selectChat.BackgroundColor3 = currentShade3
	selectJoin.BackgroundColor3 = currentShade2
	Toggle_2.Text = "Enabled"
	logs:TweenPosition(UDim2.new(0, 0, 1, -265), "InOut", "Quart", 0.3, true, nil)
end)
addcmd("chatlogswebhook", {"logswebhook"}, function(args, speaker)
	if not httprequest then
		return notify("Incompatible Exploit", "Your exploit does not support this command (missing request)")
	end
	logsWebhook = args[1] or nil
	updatesaves()
end)
flinging = false
addcmd('fling',{},function(args, speaker)
	flinging = false
	for _, child in pairs(speaker.Character:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
		end
	end
	execCmd('noclip')
	wait(.1)
	local bambam = Instance.new("BodyAngularVelocity")
	bambam.Name = randomString()
	bambam.Parent = getRoot(speaker.Character)
	bambam.AngularVelocity = Vector3.new(0,99999,0)
	bambam.MaxTorque = Vector3.new(0,math.huge,0)
	bambam.P = math.huge
	local Char = speaker.Character:GetChildren()
	for i, v in next, Char do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
			v.Velocity = Vector3.new(0, 0, 0)
		end
	end
	flinging = true
	local function flingDiedF()
		execCmd('unfling')
	end
	flingDied = speaker.Character:FindFirstChildOfClass('Humanoid').Died:Connect(flingDiedF)
	repeat
		bambam.AngularVelocity = Vector3.new(0,99999,0)
		wait(.2)
		bambam.AngularVelocity = Vector3.new(0,0,0)
		wait(.1)
	until flinging == false
end)
addcmd('unfling',{'nofling'},function(args, speaker)
	execCmd('clip')
	if flingDied then
		flingDied:Disconnect()
	end
	flinging = false
	wait(.1)
	local speakerChar = speaker.Character
	if not speakerChar or not getRoot(speakerChar) then return end
	for i,v in pairs(getRoot(speakerChar):GetChildren()) do
		if v.ClassName == 'BodyAngularVelocity' then
			v:Destroy()
		end
	end
	for _, child in pairs(speakerChar:GetDescendants()) do
		if child.ClassName == "Part" or child.ClassName == "MeshPart" then
			child.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
		end
	end
end)
addcmd('togglefling',{},function(args, speaker)
	if flinging then
		execCmd('unfling')
	else
		execCmd('fling')
	end
end)
addcmd("flyfling", {}, function(args, speaker)
	execCmd("unvehiclefly\\unwalkfling")
	task.wait()
	vehicleflyspeed = tonumber(args[1]) or vehicleflyspeed
	execCmd("vehiclefly\\walkfling")
end)
addcmd("unflyfling", {}, function(args, speaker)
	execCmd("unvehiclefly\\unwalkfling\\breakvelocity")
end)
addcmd("toggleflyfling", {}, function(args, speaker)
	execCmd(flinging and "unflyfling" or "flyfling")
end)
walkflinging = false
addcmd("walkfling", {}, function(args, speaker)
	execCmd("unwalkfling")
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			execCmd("unwalkfling")
		end)
	end
	execCmd("noclip nonotify")
	walkflinging = true
	repeat RunService.Heartbeat:Wait()
		local character = speaker.Character
		local root = getRoot(character)
		local vel, movel = nil, 0.1
		while not (character and character.Parent and root and root.Parent) do
			RunService.Heartbeat:Wait()
			character = speaker.Character
			root = getRoot(character)
		end
		vel = root.Velocity
		root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
		RunService.RenderStepped:Wait()
		if character and character.Parent and root and root.Parent then
			root.Velocity = vel
		end
		RunService.Stepped:Wait()
		if character and character.Parent and root and root.Parent then
			root.Velocity = vel + Vector3.new(0, movel, 0)
			movel = movel * -1
		end
	until walkflinging == false
end)
addcmd("unwalkfling", {"nowalkfling"}, function(args, speaker)
	walkflinging = false
	execCmd("unnoclip nonotify")
end)
addcmd("togglewalkfling", {}, function(args, speaker)
	execCmd(walkflinging and "unwalkfling" or "walkfling")
end)
addcmd('invisfling',{},function(args, speaker)
	local ch = speaker.Character
	ch:FindFirstChildWhichIsA("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local prt=Instance.new("Model")
	prt.Parent = speaker.Character
	local z1 = Instance.new("Part")
	z1.Name="Torso"
	z1.CanCollide = false
	z1.Anchored = true
	local z2 = Instance.new("Part")
	z2.Name="Head"
	z2.Parent = prt
	z2.Anchored = true
	z2.CanCollide = false
	local z3 =Instance.new("Humanoid")
	z3.Name="Humanoid"
	z3.Parent = prt
	z1.Position = Vector3.new(0,9999,0)
	speaker.Character=prt
	wait(3)
	speaker.Character=ch
	wait(3)
	local Hum = Instance.new("Humanoid")
	z2:Clone()
	Hum.Parent = speaker.Character
	local root =  getRoot(speaker.Character)
	for i,v in pairs(speaker.Character:GetChildren()) do
		if v ~= root and  v.Name ~= "Humanoid" then
			v:Destroy()
		end
	end
	root.Transparency = 0
	root.Color = Color3.new(1, 1, 1)
	local invisflingStepped
	invisflingStepped = RunService.Stepped:Connect(function()
		if speaker.Character and getRoot(speaker.Character) then
			getRoot(speaker.Character).CanCollide = false
		else
			invisflingStepped:Disconnect()
		end
	end)
	sFLY()
	workspace.CurrentCamera.CameraSubject = root
	local bambam = Instance.new("BodyThrust")
	bambam.Parent = getRoot(speaker.Character)
	bambam.Force = Vector3.new(99999,99999*10,99999)
	bambam.Location = getRoot(speaker.Character).Position
end)
addcmd("antifling", {}, function(args, speaker)
	if antifling then
		antifling:Disconnect()
		antifling = nil
	end
	antifling = RunService.Stepped:Connect(function()
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= speaker and player.Character then
				for _, v in pairs(player.Character:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CanCollide = false
					end
				end
			end
		end
	end)
end)
addcmd("unantifling", {}, function(args, speaker)
	if antifling then
		antifling:Disconnect()
		antifling = nil
	end
end)
addcmd("toggleantifling", {}, function(args, speaker)
	execCmd(antifling and "unantifling" or "antifling")
end)
function attach(speaker,target)
	if tools(speaker) then
		local char = speaker.Character
		local tchar = target.Character
		local hum = speaker.Character:FindFirstChildOfClass("Humanoid")
		local hrp = getRoot(speaker.Character)
		local hrp2 = getRoot(target.Character)
		hum.Name = "1"
		local newHum = hum:Clone()
		newHum.Parent = char
		newHum.Name = "Humanoid"
		wait()
		hum:Destroy()
		workspace.CurrentCamera.CameraSubject = char
		newHum.DisplayDistanceType = "None"
		local tool = speaker:FindFirstChildOfClass("Backpack"):FindFirstChildOfClass("Tool") or speaker.Character:FindFirstChildOfClass("Tool")
		tool.Parent = char
		hrp.CFrame = hrp2.CFrame * CFrame.new(0, 0, 0) * CFrame.new(math.random(-100, 100)/200,math.random(-100, 100)/200,math.random(-100, 100)/200)
		local n = 0
		repeat
			wait(.1)
			n = n + 1
			hrp.CFrame = hrp2.CFrame
		until (tool.Parent ~= char or not hrp or not hrp2 or not hrp.Parent or not hrp2.Parent or n > 250) and n > 2
	else
		notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
function kill(speaker,target,fast)
	if tools(speaker) then
		if target ~= nil then
			local NormPos = getRoot(speaker.Character).CFrame
			if not fast then
				refresh(speaker)
				wait()
				repeat wait() until speaker.Character ~= nil and getRoot(speaker.Character)
				wait(0.3)
			end
			local hrp = getRoot(speaker.Character)
			attach(speaker,target)
			repeat
				wait()
				hrp.CFrame = CFrame.new(999999, workspace.FallenPartsDestroyHeight + 5,999999)
			until not getRoot(target.Character) or not getRoot(speaker.Character)
			local char = speaker.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
addcmd("handlekill", {"hkill"}, function(args, speaker)
	if not firetouchinterest then
		return notify("Incompatible Exploit", "Your exploit does not support this command (missing firetouchinterest)")
	end
	if not speaker.Character then return end
	local tool = speaker.Character:FindFirstChildWhichIsA("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle then
		return notify("Handle Kill", "You need to hold a \"Tool\" that does damage on touch. For example a common Sword tool.")
	end
	local range = tonumber(args[2]) or math.huge
	if range ~= math.huge then notify("Handle Kill", ("Started!\nRadius: %s"):format(tostring(range):upper())) end
	while task.wait() and speaker.Character and tool.Parent and tool.Parent == speaker.Character do
		for _, plr in next, getPlayer(args[1], speaker) do
			plr = Players[plr]
			if plr ~= speaker and plr.Character then
				local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
				local root = hum and getRoot(plr.Character)
				if root and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead and speaker:DistanceFromCharacter(root.Position) <= range then
					firetouchinterest(handle, root, 1)
					firetouchinterest(handle, root, 0)
				end
			end
		end
	end
	notify("Handle Kill", "Stopped!")
end)
tpwalkStack = 0
addcmd("teleportwalk", {"tpwalk"}, function(args, speaker)
    pcall(function() tpwalking:Disconnect() end)
    local character = speaker.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local speed = (args[1] and isNumber(args[1])) and tonumber(args[1]) or 1
    if parseBoolean(args[2]) then
        tpwalkStack = tpwalkStack + speed
    end
    tpwalking = RunService.Heartbeat:Connect(function(delta)
        if not (character and humanoid and humanoid.Parent) then
            tpwalking:Disconnect()
            return
        end
        if humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * (speed + tpwalkStack) * delta * 10)
        end
    end)
end)
addcmd("unteleportwalk", {"untpwalk"}, function(args, speaker)
    tpwalkStack = 0
    tpwalking:Disconnect()
end)
function bring(speaker,target,fast)
	if tools(speaker) then
		if target ~= nil then
			local NormPos = getRoot(speaker.Character).CFrame
			if not fast then
				refresh(speaker)
				wait()
				repeat wait() until speaker.Character ~= nil and getRoot(speaker.Character)
				wait(0.3)
			end
			local hrp = getRoot(speaker.Character)
			attach(speaker,target)
			repeat
				wait()
				hrp.CFrame = NormPos
			until not getRoot(target.Character) or not getRoot(speaker.Character)
			local char = speaker.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
function teleport(speaker,target,target2,fast)
	if tools(speaker) then
		if target ~= nil then
			local NormPos = getRoot(speaker.Character).CFrame
			if not fast then
				refresh(speaker)
				wait()
				repeat wait() until speaker.Character ~= nil and getRoot(speaker.Character)
				wait(0.3)
			end
			local hrp = getRoot(speaker.Character)
			local hrp2 = getRoot(target2.Character)
			attach(speaker,target)
			repeat
				wait()
				hrp.CFrame = hrp2.CFrame
			until not getRoot(target.Character) or not getRoot(speaker.Character)
			wait(1)
			local char = speaker.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
addcmd('spin',{},function(args, speaker)
	local spinSpeed = 20
	if args[1] and isNumber(args[1]) then
		spinSpeed = args[1]
	end
	for i,v in pairs(getRoot(speaker.Character):GetChildren()) do
		if v.Name == "Spinning" then
			v:Destroy()
		end
	end
	local Spin = Instance.new("BodyAngularVelocity")
	Spin.Name = "Spinning"
	Spin.Parent = getRoot(speaker.Character)
	Spin.MaxTorque = Vector3.new(0, math.huge, 0)
	Spin.AngularVelocity = Vector3.new(0,spinSpeed,0)
end)
addcmd('unspin',{},function(args, speaker)
	for i,v in pairs(getRoot(speaker.Character):GetChildren()) do
		if v.Name == "Spinning" then
			v:Destroy()
		end
	end
end)
xrayEnabled = false
function xray()
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then
			v.LocalTransparencyModifier = xrayEnabled and 0.5 or 0
		end
	end
end
addcmd("xray", {}, function(args, speaker)
	xrayEnabled = true
	xray()
end)
addcmd("unxray", {"noxray"}, function(args, speaker)
	xrayEnabled = false
	xray()
end)
addcmd("togglexray", {}, function(args, speaker)
	xrayEnabled = not xrayEnabled
	xray()
end)
addcmd("loopxray", {}, function(args, speaker)
	pcall(function() xrayLoop:Disconnect() end)
	xrayLoop = RunService.RenderStepped:Connect(function()
		xrayEnabled = true
		xray()
	end)
end)
addcmd("unloopxray", {}, function(args, speaker)
	pcall(function() xrayLoop:Disconnect() end)
	xrayEnabled = false
	xray()
end)
local walltpTouch = nil
addcmd('walltp',{},function(args, speaker)
	local torso
	if r15(speaker) then
		torso = speaker.Character.UpperTorso
	else
		torso = speaker.Character.Torso
	end
	local function touchedFunc(hit)
		local Root = getRoot(speaker.Character)
		if hit:IsA("BasePart") and hit.Position.Y > Root.Position.Y - speaker.Character:FindFirstChildOfClass('Humanoid').HipHeight then
			local hitP = getRoot(hit.Parent)
			if hitP ~= nil then
				Root.CFrame = hit.CFrame * CFrame.new(Root.CFrame.lookVector.X,hitP.Size.Z/2 + speaker.Character:FindFirstChildOfClass('Humanoid').HipHeight,Root.CFrame.lookVector.Z)
			elseif hitP == nil then
				Root.CFrame = hit.CFrame * CFrame.new(Root.CFrame.lookVector.X,hit.Size.Y/2 + speaker.Character:FindFirstChildOfClass('Humanoid').HipHeight,Root.CFrame.lookVector.Z)
			end
		end
	end
	walltpTouch = torso.Touched:Connect(touchedFunc)
end)
addcmd('unwalltp',{'nowalltp'},function(args, speaker)
	if walltpTouch then
		walltpTouch:Disconnect()
	end
end)
autoclicking = false
addcmd('autoclick',{},function(args, speaker)
	if mouse1press and mouse1release then
		execCmd('unautoclick')
		wait()
		local clickDelay = 0.1
		local releaseDelay = 0.1
		if args[1] and isNumber(args[1]) then clickDelay = args[1] end
		if args[2] and isNumber(args[2]) then releaseDelay = args[2] end
		autoclicking = true
		cancelAutoClick = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				if (input.KeyCode == Enum.KeyCode.Backspace and UserInputService:IsKeyDown(Enum.KeyCode.Equals)) or (input.KeyCode == Enum.KeyCode.Equals and UserInputService:IsKeyDown(Enum.KeyCode.Backspace)) then
					autoclicking = false
					cancelAutoClick:Disconnect()
				end
			end
		end)
		notify('Auto Clicker',"Press [backspace] and [=] at the same time to stop")
		repeat wait(clickDelay)
			mouse1press()
			wait(releaseDelay)
			mouse1release()
		until autoclicking == false
	else
		notify('Auto Clicker',"Your exploit doesn't have the ability to use the autoclick")
	end
end)
addcmd('unautoclick',{'noautoclick'},function(args, speaker)
	autoclicking = false
	if cancelAutoClick then cancelAutoClick:Disconnect() end
end)
addcmd('mousesensitivity',{'ms'},function(args, speaker)
	UserInputService.MouseDeltaSensitivity = args[1]
end)
local nameBox = nil
local nbSelection = nil
addcmd('hovername',{},function(args, speaker)
	execCmd('unhovername')
	wait()
	nameBox = Instance.new("TextLabel")
	nameBox.Name = randomString()
	nameBox.Parent = ScaledHolder
	nameBox.BackgroundTransparency = 1
	nameBox.Size = UDim2.new(0,200,0,30)
	nameBox.Font = Enum.Font.Code
	nameBox.TextSize = 16
	nameBox.Text = ""
	nameBox.TextColor3 = Color3.new(1, 1, 1)
	nameBox.TextStrokeTransparency = 0
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.ZIndex = 10
	nbSelection = Instance.new('SelectionBox')
	nbSelection.Name = randomString()
	nbSelection.LineThickness = 0.03
	nbSelection.Color3 = Color3.new(1, 1, 1)
	local function updateNameBox()
		local t
		local target = IYMouse.Target
		if target then
			local humanoid = target.Parent:FindFirstChildOfClass("Humanoid") or target.Parent.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				t = humanoid.Parent
			end
		end
		if t ~= nil then
			local x = IYMouse.X
			local y = IYMouse.Y
			local xP
			local yP
			if IYMouse.X > 200 then
				xP = x - 205
				nameBox.TextXAlignment = Enum.TextXAlignment.Right
			else
				xP = x + 25
				nameBox.TextXAlignment = Enum.TextXAlignment.Left
			end
			nameBox.Position = UDim2.new(0, xP, 0, y)
			nameBox.Text = t.Name
			nameBox.Visible = true
			nbSelection.Parent = t
			nbSelection.Adornee = t
		else
			nameBox.Visible = false
			nbSelection.Parent = nil
			nbSelection.Adornee = nil
		end
	end
	nbUpdateFunc = IYMouse.Move:Connect(updateNameBox)
end)
addcmd('unhovername',{'nohovername'},function(args, speaker)
	if nbUpdateFunc then
		nbUpdateFunc:Disconnect()
		nameBox:Destroy()
		nbSelection:Destroy()
	end
end)
addcmd('headsize',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		if Players[v] ~= speaker and Players[v].Character:FindFirstChild('Head') then
			local sizeArg = tonumber(args[2])
			local Size = Vector3.new(sizeArg,sizeArg,sizeArg)
			local Head = Players[v].Character:FindFirstChild('Head')
			if Head:IsA("BasePart") then
				Head.CanCollide = false
				if not args[2] or sizeArg == 1 then
					Head.Size = Vector3.new(2,1,1)
				else
					Head.Size = Size
				end
			end
		end
	end
end)
addcmd('hitbox',{},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local transparency = args[3] and tonumber(args[3]) or 0.4
	for i,v in pairs(players) do
		if Players[v] ~= speaker and getRoot(Players[v].Character) then
			local sizeArg = tonumber(args[2])
			local Size = Vector3.new(sizeArg,sizeArg,sizeArg)
			local Root = getRoot(Players[v].Character)
			if Root:IsA("BasePart") then
				Root.CanCollide = false
				if not args[2] or sizeArg == 1 then
					Root.Size = Vector3.new(2,1,1)
					Root.Transparency = transparency
				else
					Root.Size = Size
					Root.Transparency = transparency
				end
			end
		end
	end
end)
addcmd('stareat',{'stare'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		if stareLoop then
			stareLoop:Disconnect()
		end
		if not getRoot(Players.LocalPlayer.Character) and getRoot(Players[v].Character) then return end
		local stareFunc = function()
			if Players.LocalPlayer.Character.PrimaryPart and Players:FindFirstChild(v) and Players[v].Character ~= nil and getRoot(Players[v].Character) then
				local chrPos=Players.LocalPlayer.Character.PrimaryPart.Position
				local tPos=getRoot(Players[v].Character).Position
				local modTPos=Vector3.new(tPos.X,chrPos.Y,tPos.Z)
				local newCF=CFrame.new(chrPos,modTPos)
				Players.LocalPlayer.Character:SetPrimaryPartCFrame(newCF)
			elseif not Players:FindFirstChild(v) then
				stareLoop:Disconnect()
			end
		end
		stareLoop = RunService.RenderStepped:Connect(stareFunc)
	end
end)
addcmd('unstareat',{'unstare','nostare','nostareat'},function(args, speaker)
	if stareLoop then
		stareLoop:Disconnect()
	end
end)
RolewatchData = {Group = 0, Role = "", Leave = false}
RolewatchConnection = Players.PlayerAdded:Connect(function(player)
	if RolewatchData.Group == 0 then return end
	if player:IsInGroup(RolewatchData.Group) then
		if tostring(player:GetRoleInGroup(RolewatchData.Group)):lower() == RolewatchData.Role:lower() then
			if RolewatchData.Leave == true then
				Players.LocalPlayer:Kick("\n\nRolewatch\nPlayer \"" .. tostring(player.Name) .. "\" has joined with the Role \"" .. RolewatchData.Role .. "\"\n")
			else
				notify("Rolewatch", "Player \"" .. tostring(player.Name) .. "\" has joined with the Role \"" .. RolewatchData.Role .. "\"")
			end
		end
	end
end)
addcmd("rolewatch", {}, function(args, speaker)
	local groupId = tonumber(args[1] or 0)
	local roleName = args[2] and tostring(getstring(2, args))
	if groupId and roleName then
		RolewatchData.Group = groupId
		RolewatchData.Role = roleName
		notify("Rolewatch", "Watching Group ID \"" .. tostring(groupId) .. "\" for Role \"" .. roleName .. "\"")
	end
end)
addcmd("rolewatchstop", {}, function(args, speaker)
	RolewatchData.Group = 0
	RolewatchData.Role = ""
	RolewatchData.Leave = false
	notify("Rolewatch", "Disabled")
end)
addcmd("rolewatchleave", {"unrolewatch"}, function(args, speaker)
	RolewatchData.Leave = not RolewatchData.Leave
	notify("Rolewatch", RolewatchData.Leave and "Leave has been Enabled" or "Leave has been Disabled")
end)
staffRoles = {"mod", "admin", "staff", "dev", "founder", "owner", "supervis", "manager", "management", "executive", "president", "chairman", "chairwoman", "chairperson", "director"}
getStaffRole = function(player)
	local playerRole = player:GetRoleInGroup(game.CreatorId)
	local result = {Role = playerRole, Staff = false}
	if player:IsInGroup(1200769) then
		result.Role = "Roblox Employee"
		result.Staff = true
	end
	for _, role in pairs(staffRoles) do
		if string.find(string.lower(playerRole), role) then
			result.Staff = true
		end
	end
	return result
end
addcmd("staffwatch", {}, function(args, speaker)
	if staffwatchjoin then
		staffwatchjoin:Disconnect()
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local found = {}
		staffwatchjoin = Players.PlayerAdded:Connect(function(player)
			local result = getStaffRole(player)
			if result.Staff then
				notify("Staffwatch", formatUsername(player) .. " is a " .. result.Role)
			end
		end)
		for _, player in pairs(Players:GetPlayers()) do
			local result = getStaffRole(player)
			if result.Staff then
				table.insert(found, formatUsername(player) .. " is a " .. result.Role)
			end
		end
		if #found > 0 then
			notify("Staffwatch", table.concat(found, ",\n"))
		else
			notify("Staffwatch", "Enabled")
		end
	else
		notify("Staffwatch", "Game is not owned by a Group")
	end
end)
addcmd("unstaffwatch", {}, function(args, speaker)
	if staffwatchjoin then
		staffwatchjoin:Disconnect()
	end
	notify("Staffwatch", "Disabled")
end)
function playerGroups()
    local players = Players:GetPlayers()
    local graph = {}
    local seen = {}
    local groups = {}
    for _, p in ipairs(players) do
        graph[p] = {}
    end
    for i = 1, #players do
        for j = i + 1, #players do
            local p1 = players[i]
            local p2 = players[j]
            local success, result = pcall(function()
                return p1:IsFriendsWithAsync(p2.UserId)
            end)
            if success and result then
                table.insert(graph[p1], p2)
                table.insert(graph[p2], p1)
            end
        end
    end
    local function dfs(player, group)
        seen[player] = true
        table.insert(group, player)
        for _, possible in ipairs(graph[player]) do
            if not seen[possible] then
                dfs(possible, group)
            end
        end
    end
    for _, p in ipairs(players) do
        if not seen[p] then
            local group = {}
            dfs(p, group)
            table.insert(groups, group)
        end
    end
    return groups
end
addcmd("findfriendgroups", {}, function(args, speaker)
    notify("Checking Players", "This might take a while (slow function)")
    local groups = playerGroups()
    local playerList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
    local result = ""
    local index = 1
    local found = 0
    for _, group in ipairs(groups) do
        if #group == 1 then continue end
        local names = {}
        for _, player in ipairs(group) do
            table.insert(names, playerList and player.DisplayName or player.Name)
        end
        result = result .. index .. ". " .. table.concat(names, ", ") .. "\n"
        index = index + 1
        found = found + 1
    end
    createPopup("Friend Groups", found == 0 and "None" or result)
end)
addcmd('removeterrain',{'rterrain','noterrain'},function(args, speaker)
	workspace:FindFirstChildOfClass('Terrain'):Clear()
end)
addcmd('clearnilinstances',{'nonilinstances','cni'},function(args, speaker)
	if getnilinstances then
		for i,v in pairs(getnilinstances()) do
			v:Destroy()
		end
	else
		notify('Incompatible Exploit','Your exploit does not support this command (missing getnilinstances)')
	end
end)
addcmd('destroyheight',{'dh'},function(args, speaker)
	local dh = args[1] or -500
	if isNumber(dh) then
		workspace.FallenPartsDestroyHeight = dh
	end
end)
OrgDestroyHeight = workspace.FallenPartsDestroyHeight
addcmd("antivoid", {}, function(args, speaker)
	execCmd("unantivoid nonotify")
	task.wait()
	antivoidloop = RunService.Stepped:Connect(function()
		local root = getRoot(speaker.Character)
		if root and root.Position.Y <= OrgDestroyHeight + 25 then
			root.Velocity = root.Velocity + Vector3.new(0, 250, 0)
		end
	end)
	if args[1] ~= "nonotify" then notify("antivoid", "Enabled") end
end)
addcmd("unantivoid", {"noantivoid"}, function(args, speaker)
	pcall(function() antivoidloop:Disconnect() end)
	antivoidloop = nil
	if args[1] ~= "nonotify" then notify("antivoid", "Disabled") end
end)
antivoidWasEnabled = false
addcmd("fakeout", {}, function(args, speaker)
	local root = getRoot(speaker.Character)
	local oldpos = root.CFrame
	if antivoidloop then
		execCmd("unantivoid nonotify")
		antivoidWasEnabled = true
	end
	workspace.FallenPartsDestroyHeight = 0/1/0
	root.CFrame = CFrame.new(Vector3.new(0, OrgDestroyHeight - 25, 0))
	task.wait(1)
	root.CFrame = oldpos
	workspace.FallenPartsDestroyHeight = OrgDestroyHeight
	if antivoidWasEnabled then
		execCmd("antivoid nonotify")
		antivoidWasEnabled = false
	end
end)
addcmd("trip", {}, function(args, speaker)
	local humanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
	local root = speaker.Character and getRoot(speaker.Character)
	if humanoid and root then
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
		root.Velocity = root.CFrame.LookVector * 30
	end
end)
addcmd("removeads", {"adblock"}, function(args, speaker)
	local function cleanAd(v)
		if v:IsA("PackageLink") then
			if v.Parent:FindFirstChild("ADpart") then
				v.Parent:Destroy()
			elseif v.Parent:FindFirstChild("AdGuiAdornee") then
				v.Parent.Parent:Destroy()
			end
		end
	end
	pcall(function()
		for _, v in ipairs(workspace:GetDescendants()) do
			cleanAd(v)
		end
	end)
	if _G.IYAdBlockConnection then
		_G.IYAdBlockConnection:Disconnect()
	end
	_G.IYAdBlockConnection = workspace.DescendantAdded:Connect(function(v)
		pcall(cleanAd, v)
	end)
end)
addcmd("scare", {"spook"}, function(args, speaker)
	local players = getPlayer(args[1], speaker)
	local oldpos = nil
	for _, v in pairs(players) do
		local root = speaker.Character and getRoot(speaker.Character)
		local target = Players[v]
		local targetRoot = target and target.Character and getRoot(target.Character)
		if root and targetRoot and target ~= speaker then
			oldpos = root.CFrame
			root.CFrame = targetRoot.CFrame + targetRoot.CFrame.lookVector * 2
			root.CFrame = CFrame.new(root.Position, targetRoot.Position)
			task.wait(0.5)
			root.CFrame = oldpos
		end
	end
end)
addcmd("alignmentkeys", {}, function(args, speaker)
	alignmentKeys = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Comma then workspace.CurrentCamera:PanUnits(-1) end
		if input.KeyCode == Enum.KeyCode.Period then workspace.CurrentCamera:PanUnits(1) end
	end)
	alignmentKeysEmotes = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)
addcmd("unalignmentkeys", {"noalignmentkeys"}, function(args, speaker)
	if type(alignmentKeysEmotes) == "boolean" then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, alignmentKeysEmotes)
	end
	alignmentKeys:Disconnect()
end)
addcmd("ctrllock", {}, function(args, speaker)
	local mouseLockController = speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
	local boundKeys = mouseLockController:FindFirstChild("BoundKeys")
	if boundKeys then
		boundKeys.Value = "LeftControl"
	else
		boundKeys = Instance.new("StringValue")
		boundKeys.Name = "BoundKeys"
		boundKeys.Value = "LeftControl"
		boundKeys.Parent = mouseLockController
	end
end)
addcmd("unctrllock", {}, function(args, speaker)
	local mouseLockController = speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("MouseLockController")
	local boundKeys = mouseLockController:FindFirstChild("BoundKeys")
	if boundKeys then
		boundKeys.Value = "LeftShift"
	else
		boundKeys = Instance.new("StringValue")
		boundKeys.Name = "BoundKeys"
		boundKeys.Value = "LeftShift"
		boundKeys.Parent = mouseLockController
	end
end)
addcmd("listento", {}, function(args, speaker)
	execCmd("unlistento")
	if not args[1] then return end
	local player = Players:FindFirstChild(getPlayer(args[1], speaker)[1])
	local root = player and player.Character and getRoot(player.Character)
	if root then
		SoundService:SetListener(Enum.ListenerType.ObjectPosition, root)
		listentoChar = player.CharacterAdded:Connect(function()
			repeat task.wait() until Players[player.Name].Character ~= nil and getRoot(Players[player.Name].Character)
			SoundService:SetListener(Enum.ListenerType.ObjectPosition, getRoot(Players[player.Name].Character))
		end)
	end
end)
addcmd("unlistento", {}, function(args, speaker)
	SoundService:SetListener(Enum.ListenerType.Camera)
	listentoChar:Disconnect()
end)
addcmd("jerk", {}, function(args, speaker)
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	local backpack = speaker:FindFirstChildWhichIsA("Backpack")
	if not humanoid or not backpack then return end
	local tool = Instance.new("Tool")
	tool.Name = "Jerk Off"
	tool.ToolTip = "in the stripped club. straight up \"jorking it\" . and by \"it\" , haha, well. let's justr say. My peanits."
	tool.RequiresHandle = false
	tool.Parent = backpack
	local jorkin = false
	local track = nil
	local function stopTomfoolery()
		jorkin = false
		if track then
			track:Stop()
			track = nil
		end
	end
	tool.Equipped:Connect(function() jorkin = true end)
	tool.Unequipped:Connect(stopTomfoolery)
	humanoid.Died:Connect(stopTomfoolery)
	while task.wait() do
		if not jorkin then continue end
		local isR15 = r15(speaker)
		if not track then
			local anim = Instance.new("Animation")
			anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
			track = humanoid:LoadAnimation(anim)
		end
		track:Play()
		track:AdjustSpeed(isR15 and 0.7 or 0.65)
		track.TimePosition = 0.6
		task.wait(0.1)
		while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
		if track then
			track:Stop()
			track = nil
		end
	end
end)
addcmd("guiscale", {}, function(args, speaker)
	if args[1] and isNumber(args[1]) then
		local scale = tonumber(args[1])
		if scale % 1 == 0 then scale = scale / 100 end
		if scale == 0.01 then scale = 1 end
		if scale == 0.02 then scale = 2 end
		if scale >= 0.4 and scale <= 2 then
			guiScale = scale
		end
	else
		guiScale = defaultGuiScale
	end
	Scale.Scale = math.max(Holder.AbsoluteSize.X / 1920, guiScale)
	updatesaves()
end)
local _slateMuteAllActive = false
local _slateMuteAllConn = nil

addcmd("muteallvoices", {"muteallvcs"}, function(args, speaker)
	_slateMuteAllActive = true
	pcall(function() Services.VoiceChatInternal:SubscribePauseAll(true) end)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= speaker then
			pcall(function() Services.VoiceChatInternal:SubscribePause(p.UserId, true) end)
		end
	end
	if _slateMuteAllConn then pcall(function() _slateMuteAllConn:Disconnect() end) end
	_slateMuteAllConn = Players.PlayerAdded:Connect(function(newPlayer)
		if _slateMuteAllActive then
			task.wait(1)
			pcall(function() Services.VoiceChatInternal:SubscribePause(newPlayer.UserId, true) end)
		end
	end)
	notify("Voice Chat", "Muted all players (including future joiners)")
end)
addcmd("unmuteallvoices", {"unmuteallvcs"}, function(args, speaker)
	_slateMuteAllActive = false
	if _slateMuteAllConn then
		pcall(function() _slateMuteAllConn:Disconnect() end)
		_slateMuteAllConn = nil
	end
	pcall(function() Services.VoiceChatInternal:SubscribePauseAll(false) end)
	for _, p in ipairs(Players:GetPlayers()) do
		pcall(function() Services.VoiceChatInternal:SubscribePause(p.UserId, false) end)
	end
	notify("Voice Chat", "Unmuted all players")
end)
addcmd("mutevc", {}, function(args, speaker)
	for _, plr in getPlayer(args[1], speaker) do
		if Players[plr] == speaker then continue end
		pcall(function() Services.VoiceChatInternal:SubscribePause(Players[plr].UserId, true) end)
	end
end)
addcmd("unmutevc", {}, function(args, speaker)
	for _, plr in getPlayer(args[1], speaker) do
		if Players[plr] == speaker then continue end
		pcall(function() Services.VoiceChatInternal:SubscribePause(Players[plr].UserId, false) end)
	end
end)

addcmd("antivcbypass", {"antivc"}, function(args, speaker)
	task.spawn(function()
		local clonereference = cloneref or function(...) return ... end
		local ok1, voicechatservice = pcall(function() return clonereference(game:GetService("VoiceChatService")) end)
		local ok2, voicechatinternal = pcall(function() return clonereference(game:GetService("VoiceChatInternal")) end)

		if not (ok1 and voicechatservice) or not (ok2 and voicechatinternal) then
			notify("Anti-VC Bypass", "VoiceChat services are not accessible on your exploit.")
			return
		end

		local getconnectionsfunc = getconnections
		notify("Anti-VC Bypass", "Bypassing... Please wait.")

		pcall(function() voicechatservice:leaveVoice() end)
		task.wait(1.5)

		if getconnectionsfunc then
			pcall(function()
				local connections = getconnectionsfunc(voicechatinternal.StateChanged)
				for i = 1, #connections do
					if connections[i] then connections[i]:Disable() end
				end
			end)
		end

		task.wait(1.5)
		pcall(function() voicechatservice:joinVoice() end)
		pcall(function() voicechatinternal:PublishPause(true) end)

		notify("Anti-VC Bypass", "Bypass activated successfully! You are now undetectably muted.")
	end)
end)

addcmd("phonebook", {"call"}, function(args, speaker)
	local success, canInvite = pcall(function()
		return SocialService:CanSendCallInviteAsync(speaker)
	end)
	if success and canInvite then
		SocialService:PromptPhoneBook(speaker, "")
	else
		notify("Phonebook", "It seems you're not able to call anyone. Sorry!")
	end
end)
addcmd("permadeath", {}, function(args, speaker)
	if replicatesignal then
		permadeath(speaker)
		notify("Permadeath", "Enabled")
	else
		notify("Incompatible Exploit", "Your exploit does not support this command (missing replicatesignal)")
	end
end)
local freezingua = nil
frozenParts = {}
addcmd('freezeunanchored',{'freezeua'},function(args, speaker)
	local badnames = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"RightUpperArm",
		"LeftUpperArm",
		"RightLowerArm",
		"LeftLowerArm",
		"RightHand",
		"LeftHand",
		"RightUpperLeg",
		"LeftUpperLeg",
		"RightLowerLeg",
		"LeftLowerLeg",
		"RightFoot",
		"LeftFoot",
		"Torso",
		"Right Arm",
		"Left Arm",
		"Right Leg",
		"Left Leg",
		"HumanoidRootPart"
	}
	local function FREEZENOOB(v)
		if v:IsA("BasePart" or "UnionOperation") and v.Anchored == false then
			local BADD = false
			for i = 1,#badnames do
				if v.Name == badnames[i] then
					BADD = true
				end
			end
			if speaker.Character and v:IsDescendantOf(speaker.Character) then
				BADD = true
			end
			if BADD == false then
				for i,c in pairs(v:GetChildren()) do
					if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
						c:Destroy()
					end
				end
				local bodypos = Instance.new("BodyPosition")
				bodypos.Parent = v
				bodypos.Position = v.Position
				bodypos.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
				local bodygyro = Instance.new("BodyGyro")
				bodygyro.Parent = v
				bodygyro.CFrame = v.CFrame
				bodygyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
				if not table.find(frozenParts,v) then
					table.insert(frozenParts,v)
				end
			end
		end
	end
	for i,v in pairs(workspace:GetDescendants()) do
		FREEZENOOB(v)
	end
	freezingua = workspace.DescendantAdded:Connect(FREEZENOOB)
end)
addcmd('thawunanchored',{'thawua','unfreezeunanchored','unfreezeua'},function(args, speaker)
	if freezingua then
		freezingua:Disconnect()
	end
	for i,v in pairs(frozenParts) do
		for i,c in pairs(v:GetChildren()) do
			if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
				c:Destroy()
			end
		end
	end
	frozenParts = {}
end)
addcmd('tpunanchored',{'tpua'},function(args, speaker)
	local players = getPlayer(args[1], speaker)
	for i,v in pairs(players) do
		local Forces = {}
		for _,part in pairs(workspace:GetDescendants()) do
			if Players[v].Character:FindFirstChild('Head') and part:IsA("BasePart" or "UnionOperation" or "Model") and part.Anchored == false and not part:IsDescendantOf(speaker.Character) and part.Name == "Torso" == false and part.Name == "Head" == false and part.Name == "Right Arm" == false and part.Name == "Left Arm" == false and part.Name == "Right Leg" == false and part.Name == "Left Leg" == false and part.Name == "HumanoidRootPart" == false then
				for i,c in pairs(part:GetChildren()) do
					if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
						c:Destroy()
					end
				end
				local ForceInstance = Instance.new("BodyPosition")
				ForceInstance.Parent = part
				ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				table.insert(Forces, ForceInstance)
				if not table.find(frozenParts,part) then
					table.insert(frozenParts,part)
				end
			end
		end
		for i,c in pairs(Forces) do
			c.Position = Players[v].Character.Head.Position
		end
	end
end)
keycodeMap = {
	["0"] = 0x30,
	["1"] = 0x31,
	["2"] = 0x32,
	["3"] = 0x33,
	["4"] = 0x34,
	["5"] = 0x35,
	["6"] = 0x36,
	["7"] = 0x37,
	["8"] = 0x38,
	["9"] = 0x39,
	["a"] = 0x41,
	["b"] = 0x42,
	["c"] = 0x43,
	["d"] = 0x44,
	["e"] = 0x45,
	["f"] = 0x46,
	["g"] = 0x47,
	["h"] = 0x48,
	["i"] = 0x49,
	["j"] = 0x4A,
	["k"] = 0x4B,
	["l"] = 0x4C,
	["m"] = 0x4D,
	["n"] = 0x4E,
	["o"] = 0x4F,
	["p"] = 0x50,
	["q"] = 0x51,
	["r"] = 0x52,
	["s"] = 0x53,
	["t"] = 0x54,
	["u"] = 0x55,
	["v"] = 0x56,
	["w"] = 0x57,
	["x"] = 0x58,
	["y"] = 0x59,
	["z"] = 0x5A,
	["enter"] = 0x0D,
	["shift"] = 0x10,
	["ctrl"] = 0x11,
	["alt"] = 0x12,
	["pause"] = 0x13,
	["capslock"] = 0x14,
	["spacebar"] = 0x20,
	["space"] = 0x20,
	["pageup"] = 0x21,
	["pagedown"] = 0x22,
	["end"] = 0x23,
	["home"] = 0x24,
	["left"] = 0x25,
	["up"] = 0x26,
	["right"] = 0x27,
	["down"] = 0x28,
	["insert"] = 0x2D,
	["delete"] = 0x2E,
	["f1"] = 0x70,
	["f2"] = 0x71,
	["f3"] = 0x72,
	["f4"] = 0x73,
	["f5"] = 0x74,
	["f6"] = 0x75,
	["f7"] = 0x76,
	["f8"] = 0x77,
	["f9"] = 0x78,
	["f10"] = 0x79,
	["f11"] = 0x7A,
	["f12"] = 0x7B,
}
autoKeyPressing = false
cancelAutoKeyPress = nil
addcmd('autokeypress',{'keypress'},function(args, speaker)
	if keypress and keyrelease and args[1] then
		local code = keycodeMap[args[1]:lower()]
		if not code then notify('Auto Key Press',"Invalid key") return end
		execCmd('unautokeypress')
		wait()
		local clickDelay = 0.1
		local releaseDelay = 0.1
		if args[2] and isNumber(args[2]) then clickDelay = args[2] end
		if args[3] and isNumber(args[3]) then releaseDelay = args[3] end
		autoKeyPressing = true
		cancelAutoKeyPress = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if not gameProcessedEvent then
				if (input.KeyCode == Enum.KeyCode.Backspace and UserInputService:IsKeyDown(Enum.KeyCode.Equals)) or (input.KeyCode == Enum.KeyCode.Equals and UserInputService:IsKeyDown(Enum.KeyCode.Backspace)) then
					autoKeyPressing = false
					cancelAutoKeyPress:Disconnect()
				end
			end
		end)
		notify('Auto Key Press',"Press [backspace] and [=] at the same time to stop")
		repeat wait(clickDelay)
			keypress(code)
			wait(releaseDelay)
			keyrelease(code)
		until autoKeyPressing == false
		if cancelAutoKeyPress then cancelAutoKeyPress:Disconnect() keyrelease(code) end
	else
		notify('Auto Key Press',"Your exploit doesn't have the ability to use auto key press")
	end
end)
addcmd('unautokeypress',{'noautokeypress','unkeypress','nokeypress'},function(args, speaker)
	autoKeyPressing = false
	if cancelAutoKeyPress then cancelAutoKeyPress:Disconnect() end
end)
addcmd('addplugin',{'plugin'},function(args, speaker)
	addPlugin(getstring(1, args))
end)
addcmd('removeplugin',{'deleteplugin'},function(args, speaker)
	deletePlugin(getstring(1, args))
end)
addcmd('reloadplugin',{},function(args, speaker)
	local pluginName = getstring(1, args)
	deletePlugin(pluginName)
	wait(1)
	addPlugin(pluginName)
end)
addcmd("addallplugins", {"loadallplugins"}, function(args, speaker)
	if not listfiles or not isfolder then
		notify("Incompatible Exploit", "Your exploit does not support this command (missing listfiles/isfolder)")
		return
	end
	for _, filePath in ipairs(listfiles("")) do
		local fileName = filePath:match("([^/\\]+%.iy)$")
		if fileName and
			fileName:lower() ~= "iy_fe.iy" and
			not isfolder(fileName) and
			not table.find(PluginsTable, fileName)
		then
			addPlugin(fileName)
		end
	end
end)
addcmd('removecmd',{'deletecmd'},function(args, speaker)
	removecmd(args[1])
end)
addcmd("debug", {}, function(args, speaker)
    local opt = parseBoolean(args[1], true)
    _G.IY_DEBUG = opt
    notify("debug", tostring(opt), 1)
end)

print(string.format("[cmnds loaded in %.4fs", os.clock() - _cmdLoadStart))
