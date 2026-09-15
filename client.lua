if not LPS_OBFUSCATED then LPS_ATTRIBUTES = function(...) end; VM = function(...) end; OPAL = nil; NONE = nil; PRESET = function(...) end; SECURE = nil; FAST = nil; ERROR_HANDLING = function(...) end; TRANSFORM = function(...) end; CONTROL_FLOW = nil; REWRITE_NAMECALLS = nil; EXTRACT = function(...) end; GLOBALS = nil; CONSTANTS = nil; INLINE = function(...) end; UNROLL = function(...) end; OPTIMIZE = function(...) end; ENCRYPT = function(...) end; LPS_ENCSTR = function(s) return s end; LPS_ENCNUM = function(n) return n end; LPS_CRASH = function() end end
LPS_ATTRIBUTES(
    PRESET(FAST)
)

local _nametagsLoadStart = os.clock()

local Players         = game:GetService("Players")
local HttpService     = game:GetService("HttpService")
local RunService      = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local localPlayer = Players.LocalPlayer
while not localPlayer do
	task.wait()
	localPlayer = Players.LocalPlayer
end

if getgenv then
	if getgenv().SlateNametags and type(getgenv().SlateNametags.Destroy) == "function" then
		pcall(function() getgenv().SlateNametags:Destroy() end)
	end
end

local targetUI = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
	if targetUI then
		local oldUi = targetUI:FindFirstChild("SlateOwnerClient")
		if oldUi then oldUi:Destroy() end
	end
	if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
		local oldUi = localPlayer.PlayerGui:FindFirstChild("SlateOwnerClient")
		if oldUi then oldUi:Destroy() end
	end
	local cg = game:GetService("CoreGui")
	if cg then
		local oldUi = cg:FindFirstChild("SlateOwnerClient")
		if oldUi then oldUi:Destroy() end
	end
end)

local DEFAULT_RAW_CONFIG = {
	font = "GothamBold",
	isGif = false,
	bgType = "image",
	iconImage = "https://i.postimg.cc/fTW53y7h/IMG-2754-Photoroom.png",
	textColor = "#ffffff",
	sizePreset = "medium",
	displayName = "SLATEㅤㅤ",
	nametagShape = "Square",
	outlineColor = "#000000",
	bgGradientDir = "to right",
	bgTransparency = 0,
	backgroundColor = "#000000",
	backgroundImage = "https://i.postimg.cc/NFGmdgc0/IMG-1295.jpg",
	bgGradientStops = {
		{ pos = 0, color = "#1a1a2e" },
		{ pos = 100, color = "#16213e" }
	},
	strokeThickness = 3,
	textGradientDir = "to right",
	strokeGradientDir = "to right",
	textGradientSpeed = 3,
	textGradientStops = {
		{ pos = 0, color = "#ffffff" },
		{ pos = 50, color = "#595959" }
	},
	strokeGradientStops = {
		{ pos = 0, color = "#1a366a" },
		{ pos = 50, color = "#142d5d" }
	},
	textGradientEnabled = true,
	strokeGradientEnabled = false,
	textGradientAnimEnabled = true,
	strokeGradientAnimEnabled = false
}

local API_BASE = (getgenv and (getgenv().SLATE_BACKEND or _G.SLATE_BACKEND)) or "https://sl8ght.xyz"
local WS_BASE  = API_BASE:gsub("^http", "ws") .. "/ws"

local CONFIG = {
	backendUrl        = API_BASE,
	wsUrl             = WS_BASE,
	heartbeatPoll     = 45,
	minimizeDistance  = 45,
	distanceCheck     = 0.2,
	studsOffset       = Vector3.new(0, 1.7, 0),
	tagHeight         = 48,
	iconSize          = 32,
	cacheRoot         = "slate/client",
	defaultIcon       = DEFAULT_RAW_CONFIG.iconImage,
	defaultBackground = DEFAULT_RAW_CONFIG.backgroundImage,
	headshot          = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
}

local PLACE_ID = tostring(game.PlaceId)
local JOB_ID   = (game.JobId ~= nil and game.JobId ~= "") and game.JobId or "unknown"

local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or (getgenv and (getgenv().request or getgenv().http_request))
local targetUI      = (gethui and gethui()) or game:GetService("CoreGui")
local hasFileSystem = type(writefile) == "function" and type(getcustomasset) == "function"
	and type(isfile) == "function" and type(isfolder) == "function"
	and type(makefolder) == "function"

local wsLib = (getgenv and (getgenv().WebSocket or getgenv().websocket)) or WebSocket or websocket

local function ensureFolder(path)
	if not hasFileSystem then return end
	local build = nil
	for segment in path:gmatch("[^/]+") do
		build = build and (build .. "/" .. segment) or segment
		if not isfolder(build) then pcall(makefolder, build) end
	end
end

local function decodeJson(raw)
	if type(raw) ~= "string" or raw == "" then return nil end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(decoded) == "table" then return decoded end
	return nil
end

local function ensureDefaultConfig()
	if not hasFileSystem then return end
	local folder = CONFIG.cacheRoot .. "/default"
	ensureFolder(folder)
	local filePath = folder .. "/config.json"
	if isfile(filePath) and type(readfile) == "function" then
		local content = nil
		pcall(function() content = readfile(filePath) end)
		local decoded = decodeJson(content)
		if decoded and type(decoded) == "table" then
			DEFAULT_RAW_CONFIG = decoded
			return
		end
	end
	pcall(writefile, filePath, HttpService:JSONEncode(DEFAULT_RAW_CONFIG))
end

ensureDefaultConfig()

local function findPlayer(identifier)
	if not identifier then return nil end
	local num = tonumber(identifier)
	if num then
		local p = Players:GetPlayerByUserId(num)
		if p then return p end
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
	if type(url) ~= "string" or url == "" then return nil end
	if url:find("^http://") then
		url = "https://" .. url:sub(8)
	end
	if httpRequest then
		local ok, res = pcall(httpRequest, {
			Url = url,
			Method = "GET",
			Headers = {
				["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
				["Accept"] = "*/*"
			}
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
	if type(game.HttpGet) == "function" then
		local ok, body = pcall(game.HttpGet, game, url)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end
	end
	return nil
end

local function httpPostJson(url, body)
	if not httpRequest then return nil end
	if type(url) == "string" and url:find("^http://") then
		url = "https://" .. url:sub(8)
	end
	local ok, res = pcall(httpRequest, {
		Url     = url,
		Method  = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body    = HttpService:JSONEncode(body),
	})
	if not ok or type(res) ~= "table" then return nil end
	local code = res.StatusCode or res.Status
	if code and code ~= 200 then return nil end
	return res.Body or res.body
end

local function hexToColor3(hex)
	LPS_ATTRIBUTES(INLINE())
	if type(hex) ~= "string" then return nil end
	hex = hex:gsub("#", "")
	if #hex == 3 then
		hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
	end
	if #hex ~= 6 then return nil end
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

local function toColor3(value, fallback)
	if typeof(value) == "Color3" then return value end
	if type(value) == "string" then return hexToColor3(value) or fallback end
	if type(value) == "table" then
		local r, g, b = value.r or value[1], value.g or value[2], value.b or value[3]
		if r and g and b then
			if r > 1 or g > 1 or b > 1 then return Color3.fromRGB(r, g, b) end
			return Color3.new(r, g, b)
		end
	end
	return fallback
end

local function resolveAsset(url)
	if type(url) ~= "string" or url == "" then return nil end
	local s = url:match("^%s*(.-)%s*$")
	if s:find("^http://") then s = "https://" .. s:sub(8) end
	if s:find("^rbx") then return s end
	if s:find("^https?://") and not s:find("roblox%.com") then return s end
	local id = s:match("^(%d+)$") or s:match("id=(%d+)")
	if id then return "rbxassetid://" .. id end
	return s
end

local assetCache = {}

local function userFolder(ownerId, version)
	local folderName = tostring(ownerId or "default")
	if folderName == "shared" or folderName == "0" then folderName = "default" end
	local dir = CONFIG.cacheRoot .. "/" .. folderName
	ensureFolder(dir)
	return dir
end

local function deleteUserCache(ownerId)
	if not ownerId then return end
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
			if hasFileSystem then
				local dir = CONFIG.cacheRoot .. "/" .. name
				pcall(function()
					if type(isfolder) == "function" and isfolder(dir) and type(delfolder) == "function" then
						delfolder(dir)
					end
				end)
			end
			for k in pairs(assetCache) do
				if k:sub(1, #name + 1) == name .. "/" then
					assetCache[k] = nil
				end
			end
		end
	end
end

local function getUrlHash(urlStr)
	LPS_ATTRIBUTES(INLINE())
	if type(urlStr) ~= "string" or urlStr == "" then return tostring(string.format("%x", os.time())):sub(-6) end
	local hash = 5381
	for i = 1, #urlStr do
		hash = (hash * 33 + string.byte(urlStr, i)) % 4294967296
	end
	return string.format("%x", hash)
end

local function looksLikeHtml(body)
	LPS_ATTRIBUTES(INLINE())
	local head = body:sub(1, 32):lower()
	return head:find("<html", 1, true) ~= nil or head:find("<!doctype", 1, true) ~= nil
end

local function writeAsset(ownerId, version, key, bytes)
	if not hasFileSystem then return nil end
	local path = userFolder(ownerId, version) .. "/" .. key .. ".png"
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
	if not hasFileSystem then return nil end
	local memo = assetCache[tostring(ownerId or "default") .. "/" .. key]
	if memo then return memo end

	local path = userFolder(ownerId, version) .. "/" .. key .. ".png"
	if not isfile(path) then return nil end
	local asset = nil
	pcall(function() asset = getcustomasset(path) end)
	if asset and asset ~= "" then
		assetCache[tostring(ownerId or "default") .. "/" .. key] = asset
		return asset
	end
	return nil
end

local function fetchImage(url, ownerId, version, key)
	url = resolveAsset(url)
	if not url then return nil end
	if not url:find("^https?://") then return url end
	if not hasFileSystem then return url end

	local fullKey = key .. "_" .. getUrlHash(url)

	local cached = readAsset(ownerId, version, fullKey)
	if cached then return cached end

	local body = httpGet(url)
	if not body or looksLikeHtml(body) then return url end
	return writeAsset(ownerId, version, fullKey, body) or url
end

local function applyImage(label, url, ownerId, version, key)
	if not url then return end
	task.spawn(function()
		local asset = fetchImage(url, ownerId, version, key)
		if asset and label and label.Parent then
			label.Image = asset
		end
	end)
end

local PACK_HEADER = 13

local function unpackFrames(bytes)
	if type(bytes) ~= "string" or #bytes < PACK_HEADER then return nil end
	local magic = bytes:sub(1, 4)
	if magic ~= "SLTF" and magic ~= "SFP1" then return nil end

	local count = string.unpack(">I2", bytes, 7)
	local delay = string.unpack(">I2", bytes, 9)

	local frames = {}
	local at = PACK_HEADER + 1
	for i = 1, count do
		if at + 3 > #bytes then break end
		local length = string.unpack(">I4", bytes, at)
		at = at + 4
		if at + length - 1 > #bytes then break end
		frames[i] = bytes:sub(at, at + length - 1)
		at = at + length
	end

	if #frames == 0 then return nil end
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
		if #assets == pack.count then return assets end
	end

	local url = resolveAsset(pack.url) or pack.url
	local rawBody = httpGet(url)
	if not rawBody then return nil end

	local frames, packDelay = unpackFrames(rawBody)
	if not frames or #frames == 0 then return nil end

	if packDelay and packDelay > 0 then pack.delay = packDelay end
	pack.count = #frames

	assets = {}
	for i, png in ipairs(frames) do
		local fileKey = prefix .. i
		local asset = writeAsset(ownerId, version, fileKey, png)
		if asset then assets[#assets + 1] = asset end
	end
	if #assets == 0 then return nil end
	return assets
end

local function playFrames(container, pack, ownerId, version, baseTransparency)
	baseTransparency = baseTransparency or 0
	local token = (container:GetAttribute("SlateFrameToken") or 0) + 1
	container:SetAttribute("SlateFrameToken", token)

	task.spawn(function()
		local assets = loadFrames(pack, ownerId, version)
		if not assets or not container.Parent then return end
		if container:GetAttribute("SlateFrameToken") ~= token then return end

		local existingCorner = container:FindFirstChildOfClass("UICorner")
		local cornerRadius = existingCorner and existingCorner.CornerRadius or UDim.new(0, 6)

		local frameLabels = {}
		for i, asset in ipairs(assets) do
			local img = Instance.new("ImageLabel")
			img.Name                   = "Frame_" .. i
			img.Size                   = UDim2.new(1, 0, 1, 0)
			img.BackgroundTransparency = 1
			img.ImageTransparency      = (i == 1) and baseTransparency or 1
			img.ScaleType              = Enum.ScaleType.Crop
			img.ZIndex                 = (i == 1) and (container.ZIndex + 1) or container.ZIndex
			img.Image                  = asset
			Instance.new("UICorner", img).CornerRadius = cornerRadius
			frameLabels[i]             = img
		end

		if not container.Parent or container:GetAttribute("SlateFrameToken") ~= token then return end

		local oldHolder = container:FindFirstChild("SlateFrameStack")
		if oldHolder then pcall(function() oldHolder:Destroy() end) end

		local holder = Instance.new("Frame")
		holder.Name                   = "SlateFrameStack"
		holder.Size                   = UDim2.new(1, 0, 1, 0)
		holder.BackgroundTransparency = 1
		holder.ClipsDescendants       = true
		holder.ZIndex                 = container.ZIndex
		Instance.new("UICorner", holder).CornerRadius = cornerRadius

		for _, img in ipairs(frameLabels) do
			img.Parent = holder
		end
		holder.Parent = container

		local step    = math.max((pack.delay or 100) / 1000, 1 / 60)
		local current = 1
		local elapsed = 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not container.Parent or container:GetAttribute("SlateFrameToken") ~= token then
				conn:Disconnect()
				return
			end
			elapsed = elapsed + dt
			if elapsed < step then return end
			local advance = math.floor(elapsed / step)
			elapsed = elapsed % step

			local nextFrame = ((current - 1 + advance) % #frameLabels) + 1
			if nextFrame ~= current then
				frameLabels[nextFrame].ZIndex = container.ZIndex + 1
				frameLabels[nextFrame].ImageTransparency = baseTransparency
				frameLabels[current].ImageTransparency = 1
				frameLabels[current].ZIndex = container.ZIndex
				current = nextFrame
			end
		end)
	end)
end

local FONT_MAP = {
	Gotham         = Enum.Font.Gotham,
	GothamBold     = Enum.Font.GothamBold,
	GothamBlack    = Enum.Font.GothamBlack,
	GothamMedium   = Enum.Font.GothamMedium,
	Montserrat     = Enum.Font.GothamMedium,
	Poppins        = Enum.Font.GothamBold,
	Inter          = Enum.Font.Gotham,
	Outfit         = Enum.Font.GothamBold,
	SpaceGrotesk   = Enum.Font.Code,
	BebasNeue      = Enum.Font.Highway,
	Orbitron       = Enum.Font.SciFi,
	RussoOne       = Enum.Font.GothamBlack,
	Rajdhani       = Enum.Font.TitilliumWeb,
	Audiowide      = Enum.Font.SciFi,
	PressStart2P   = Enum.Font.Arcade,
	Silkscreen     = Enum.Font.Arcade,
	Bungee         = Enum.Font.GothamBlack,
	Righteous      = Enum.Font.FredokaOne,
	Fredoka        = Enum.Font.FredokaOne,
	Comfortaa      = Enum.Font.Gotham,
	Quicksand      = Enum.Font.GothamMedium,
	Lexend         = Enum.Font.GothamBold,
	Syne           = Enum.Font.GothamBlack,
	Playfair       = Enum.Font.Garamond,
	SourceSans     = Enum.Font.SourceSans,
	SourceSansBold = Enum.Font.SourceSansBold,
}

local GRADIENT_ROTATION = {
	["to right"]        = 0,
	["to bottom right"] = 45,
	["to bottom"]       = 90,
	["to bottom left"]  = 135,
	["to left"]         = 180,
	["to top left"]     = 225,
	["to top"]          = 270,
	["to top right"]    = 315,
}

local function resolveFont(name)
	LPS_ATTRIBUTES(INLINE())
	return FONT_MAP[name or "GothamBold"] or Enum.Font.GothamBold
end

local function camel(key) return key:gsub("_(%l)", string.upper) end
	LPS_ATTRIBUTES(INLINE())
local function snake(key) return key:gsub("(%l)(%u)", "%1_%2"):lower() end
	LPS_ATTRIBUTES(INLINE())

local function getValue(raw, fallback, ...)
	LPS_ATTRIBUTES(ERROR_HANDLING(false))
	if type(raw) ~= "table" then return fallback end
	for i = 1, select("#", ...) do
		local k = select(i, ...)
		if k ~= nil then
			if raw[k] ~= nil then return raw[k] end
			local c = camel(tostring(k))
			if raw[c] ~= nil then return raw[c] end
			local s = snake(tostring(k))
			if raw[s] ~= nil then return raw[s] end
		end
	end
	return fallback
end

local function parseStops(stops)
	if type(stops) == "string" then stops = decodeJson(stops) end
	if type(stops) ~= "table" or #stops < 2 then return nil end

	local sorted = {}
	for _, stop in pairs(stops) do
		if type(stop) == "table" then sorted[#sorted + 1] = stop end
	end
	if #sorted < 2 then return nil end
	table.sort(sorted, function(a, b) return (a.pos or a.position or 0) < (b.pos or b.position or 0) end)
	return sorted
end

local function mirroredSequence(stops)
	local keypoints = {}
	local function push(time, color)
		time = math.clamp(time, 0, 1)
		local last = keypoints[#keypoints]
		if last and time <= last.Time then time = math.min(last.Time + 0.001, 1) end
		keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(time, color)
	end

	for _, stop in ipairs(stops) do
		push(((stop.pos or stop.position or 0) / 100) * 0.5, toColor3(stop.color, Color3.new(1, 1, 1)))
	end
	for i = #stops - 1, 1, -1 do
		local stop = stops[i]
		push(0.5 + (1 - (stop.pos or stop.position or 0) / 100) * 0.5, toColor3(stop.color, Color3.new(1, 1, 1)))
	end

	if #keypoints < 2 then return nil end
	if keypoints[1].Time > 0 then table.insert(keypoints, 1, ColorSequenceKeypoint.new(0, keypoints[1].Value)) end
	if keypoints[#keypoints].Time < 1 then keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, keypoints[#keypoints].Value) end

	local ok, sequence = pcall(ColorSequence.new, keypoints)
	return ok and sequence or nil
end

local function flatSequence(stops)
	local keypoints = {}
	for _, stop in ipairs(stops) do
		local time = math.clamp((stop.pos or stop.position or 0) / 100, 0, 1)
		local last = keypoints[#keypoints]
		if last and time <= last.Time then time = math.min(last.Time + 0.001, 1) end
		keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(time, toColor3(stop.color, Color3.new(0, 0, 0)))
	end
	if #keypoints < 2 then return nil end
	if keypoints[1].Time > 0 then table.insert(keypoints, 1, ColorSequenceKeypoint.new(0, keypoints[1].Value)) end
	if keypoints[#keypoints].Time < 1 then keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(1, keypoints[#keypoints].Value) end

	local ok, sequence = pcall(ColorSequence.new, keypoints)
	return ok and sequence or nil
end

local function parseGradient(raw, defaultObj, enabledKey1, enabledKey2, dirKey1, dirKey2, stopsKey1, stopsKey2, animKey1, animKey2, speedKey1, speedKey2)
	local enabled = getValue(raw, defaultObj and defaultObj.enabled, enabledKey1, enabledKey2)
	if enabled ~= true then return nil end

	local stopsRaw = getValue(raw, defaultObj and defaultObj.stops, stopsKey1, stopsKey2)
	local stops = parseStops(stopsRaw) or (defaultObj and defaultObj.stops and parseStops(defaultObj.stops))
	if not stops then return nil end

	local animated = getValue(raw, defaultObj and defaultObj.anim, animKey1, animKey2) == true
	local sequence = animated and mirroredSequence(stops) or flatSequence(stops)
	if not sequence then return nil end

	local dir = getValue(raw, defaultObj and defaultObj.dir or "to right", dirKey1, dirKey2)
	local speed = tonumber(getValue(raw, defaultObj and defaultObj.speed or 3, speedKey1, speedKey2)) or 3
	return {
		sequence = sequence,
		rotation = GRADIENT_ROTATION[dir] or 0,
		animated = animated,
		speed    = speed,
	}
end

local function parseConfig(raw, ownerId)
	LPS_ATTRIBUTES(ERROR_HANDLING(false))
	raw = type(raw) == "table" and raw or {}
	ownerId = ownerId or "default"
	local tagPrefix = tostring(ownerId)

	local displayName = getValue(raw, DEFAULT_RAW_CONFIG.displayName, "displayName", "name_text", "text", "tagText")
	local isDefault = (raw == DEFAULT_RAW_CONFIG or raw.isCustom == false)

	local bgType  = getValue(raw, DEFAULT_RAW_CONFIG.bgType, "bgType", "bg_type")
	local version = tostring(getValue(raw, "v1", "artVersion", "art_version", "updated_at"))

	local iconRaw = getValue(raw, DEFAULT_RAW_CONFIG.iconImage, "iconImage", "icon_image")
	local iconResolved = resolveAsset(iconRaw) or CONFIG.defaultIcon
	local iconOwner = (iconResolved == CONFIG.defaultIcon or isDefault) and "default" or ownerId

	local bgImageRaw = getValue(raw, DEFAULT_RAW_CONFIG.backgroundImage, "backgroundImage", "image_url", "tag_image")
	local bgImageResolved = resolveAsset(bgImageRaw) or CONFIG.defaultBackground
	local bgOwner = (bgImageResolved == CONFIG.defaultBackground or isDefault) and "default" or ownerId

	local outlineCol = isDefault and Color3.fromRGB(0, 0, 0) or toColor3(getValue(raw, DEFAULT_RAW_CONFIG.outlineColor, "outlineColor", "outline_color", "strokeColor", "glow_color"), Color3.fromRGB(0, 0, 0))
	local strokeThick = isDefault and 3 or math.max(tonumber(getValue(raw, DEFAULT_RAW_CONFIG.strokeThickness, "strokeThickness", "stroke_thickness")) or 3, 0)

	local cfg = {
		version         = version,
		displayName     = displayName,
		font            = resolveFont(getValue(raw, DEFAULT_RAW_CONFIG.font, "font", "font_face")),
		textColor       = isDefault and Color3.fromRGB(255, 255, 255) or toColor3(getValue(raw, DEFAULT_RAW_CONFIG.textColor, "textColor", "name_color", "color"), Color3.fromRGB(255, 255, 255)),
		outlineColor    = outlineCol,
		backgroundColor = toColor3(getValue(raw, DEFAULT_RAW_CONFIG.backgroundColor, "backgroundColor", "background_color", "tag_color"), Color3.fromRGB(0, 0, 0)),
		strokeThickness = strokeThick,
		bgTransparency  = (tonumber(getValue(raw, DEFAULT_RAW_CONFIG.bgTransparency, "bgTransparency", "bg_transparency")) or 0) / 100,
		bgType          = isDefault and "image" or bgType,
		glitch          = getValue(raw, false, "glitchAnim", "glitch_anim") == true,
		iconImage       = isDefault and CONFIG.defaultIcon or iconResolved,
		iconOwner       = iconOwner,
		backgroundImage = isDefault and CONFIG.defaultBackground or bgImageResolved,
		bgOwner         = bgOwner,
	}

	local isGif = getValue(raw, false, "isGif", "is_gif") == true
	local bgFrames = getValue(raw, nil, "framesUrl", "frames_url", "backgroundFrames", "bgFrames")
	local bgCount = tonumber(getValue(raw, 0, "framesCount", "frames_count", "frameCount", "frame_count")) or 0

	local iconFrames = getValue(raw, nil, "iconFramesUrl", "icon_frames_url", "iconFrames", "icon_frames")
	local iconCount = tonumber(getValue(raw, 0, "iconFramesCount", "icon_frames_count", "iconFrameCount", "icon_frame_count")) or 0

	if (not bgFrames or bgFrames == "") and type(bgImageRaw) == "string" and bgImageRaw:lower():find("%.gif") and bgImageRaw:find("/uploads/") then
		bgFrames = bgImageRaw:gsub("%.[gG][iI][fF]$", ".sltf"):gsub("%.[gG][iI][fF]%?", ".sltf?")
	end

	if (not iconFrames or iconFrames == "") and type(iconRaw) == "string" and iconRaw:lower():find("%.gif") and iconRaw:find("/uploads/") then
		iconFrames = iconRaw:gsub("%.[gG][iI][fF]$", ".sltf"):gsub("%.[gG][iI][fF]%?", ".sltf?")
	end

	local hasBgFrames = (bgFrames and bgFrames ~= "")
	local hasIconFrames = (iconFrames and iconFrames ~= "")

	if not isDefault and (isGif or hasBgFrames) and hasBgFrames then
		local urlHash = getUrlHash(tostring(bgFrames))
		cfg.backgroundFrames = {
			url    = bgFrames,
			count  = bgCount,
			delay  = tonumber(getValue(raw, 100, "framesDelay", "frames_delay", "frameDelay", "frame_delay")) or 100,
			prefix = "bg_" .. urlHash .. "_" .. tostring(version or "v1") .. "_",
		}
	else
		cfg.backgroundFrames = nil
	end
	if not isDefault and (isGif or hasIconFrames) and hasIconFrames then
		local urlHash = getUrlHash(tostring(iconFrames))
		cfg.iconFrames = {
			url    = iconFrames,
			count  = iconCount,
			delay  = tonumber(getValue(raw, 100, "iconFramesDelay", "icon_frames_delay", "iconFrameDelay", "icon_frame_delay")) or 100,
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
			speed    = 3,
		}
		cfg.strokeGradient = nil
	else
		local textEnabled = getValue(raw, DEFAULT_RAW_CONFIG.textGradientEnabled, "textGradientEnabled", "text_gradient_enabled") == true
		local textDef = {
			enabled = textEnabled,
			dir     = getValue(raw, DEFAULT_RAW_CONFIG.textGradientDir, "textGradientDir", "text_gradient_dir"),
			stops   = getValue(raw, DEFAULT_RAW_CONFIG.textGradientStops, "textGradientStops", "text_gradient_stops"),
			anim    = getValue(raw, DEFAULT_RAW_CONFIG.textGradientAnimEnabled, "textGradientAnimEnabled", "text_gradient_anim_enabled") == true,
			speed   = getValue(raw, DEFAULT_RAW_CONFIG.textGradientSpeed, "textGradientSpeed", "text_gradient_speed"),
		}
		cfg.textGradient = parseGradient(raw, textDef, "textGradientEnabled", "text_gradient_enabled", "textGradientDir", "text_gradient_dir", "textGradientStops", "text_gradient_stops", "textGradientAnimEnabled", "text_gradient_anim_enabled", "textGradientSpeed", "text_gradient_speed")

		local strokeEnabled = getValue(raw, DEFAULT_RAW_CONFIG.strokeGradientEnabled, "strokeGradientEnabled", "stroke_gradient_enabled") == true
		local strokeDef = {
			enabled = strokeEnabled,
			dir     = getValue(raw, DEFAULT_RAW_CONFIG.strokeGradientDir, "strokeGradientDir", "stroke_gradient_dir"),
			stops   = getValue(raw, DEFAULT_RAW_CONFIG.strokeGradientStops, "strokeGradientStops", "stroke_gradient_stops"),
			anim    = getValue(raw, DEFAULT_RAW_CONFIG.strokeGradientAnimEnabled, "strokeGradientAnimEnabled", "stroke_gradient_anim_enabled") == true,
		}
		cfg.strokeGradient = parseGradient(raw, strokeDef, "strokeGradientEnabled", "stroke_gradient_enabled", "strokeGradientDir", "stroke_gradient_dir", "strokeGradientStops", "stroke_gradient_stops", "strokeGradientAnimEnabled", "stroke_gradient_anim_enabled", nil, nil)
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
local tags    = {}

local function billboardNameFor(player)
	LPS_ATTRIBUTES(INLINE())
	return player.Name .. "_SlateBillboard"
end

local function adorneeFor(player)
	LPS_ATTRIBUTES(INLINE())
	local character = player.Character
	if not character then return nil end
	return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function attachGradient(instance, gradient, colorProperty)
	if not gradient or not gradient.sequence then return end
	if colorProperty then instance[colorProperty] = Color3.new(1, 1, 1) end

	local ui = Instance.new("UIGradient")
	ui.Color    = gradient.sequence
	ui.Rotation = gradient.rotation
	ui.Parent   = instance
	if not gradient.animated then return end

	local speed = math.max(gradient.speed or 3, 0.1)
	local t = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not instance.Parent then
			conn:Disconnect()
			return
		end
		t = (t + (dt * 2) / speed) % 2
		ui.Offset = Vector2.new(-1 + t, 0)
	end)
end

local GLITCH_CHARS = { "!", "@", "#", "$", "%", "^", "&", "*", "~", "?", "/" }

local function runGlitch(label, baseText)
	task.spawn(function()
		while label.Parent do
			task.wait(2)
			if not label.Parent then return end
			if math.random() < 0.3 then
				local scrambled = ""
				for i = 1, #baseText do
					scrambled = scrambled .. (math.random() < 0.15 and GLITCH_CHARS[math.random(#GLITCH_CHARS)] or baseText:sub(i, i))
				end
				label.Text = scrambled
				task.wait(0.2)
				if label.Parent then label.Text = baseText end
			end
		end
	end)
end

local function buildTag(player, cfg, billboard)
	local ownerId = player.UserId

	local frame = Instance.new("Frame")
	frame.Name             = "Background"
	frame.AnchorPoint      = Vector2.new(0.5, 0.5)
	frame.Position         = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size             = UDim2.new(0, 0, 0, CONFIG.tagHeight)
	frame.AutomaticSize    = Enum.AutomaticSize.X
	frame.BackgroundColor3 = cfg.backgroundColor
	frame.BorderSizePixel  = 0
	frame.ClipsDescendants = false
	frame.ZIndex           = 2

	local hasArt = cfg.backgroundFrames ~= nil or cfg.backgroundImage ~= nil
	frame.BackgroundTransparency = cfg.bgTransparency
	frame.Parent = billboard

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

	if cfg.bgGradient then
		attachGradient(frame, cfg.bgGradient, "BackgroundColor3")
	end

	local stroke = Instance.new("UIStroke", frame)
	stroke.Name            = "Stroke"
	stroke.Color           = cfg.outlineColor
	stroke.Thickness       = cfg.strokeThickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Enabled         = cfg.strokeThickness > 0
	attachGradient(stroke, cfg.strokeGradient, "Color")

	local hasArt = cfg.backgroundFrames ~= nil or cfg.backgroundImage ~= nil
	if hasArt then
		local art = Instance.new("ImageLabel", frame)
		art.Name                   = "BackgroundArt"
		art.Size                   = UDim2.new(1, 0, 1, 0)
		art.BackgroundTransparency = 1
		art.ImageTransparency      = cfg.bgTransparency
		art.ScaleType              = Enum.ScaleType.Crop
		art.ClipsDescendants       = true
		art.ZIndex                 = 1
		art.Image                  = ""
		Instance.new("UICorner", art).CornerRadius = UDim.new(0, 6)
		if cfg.backgroundFrames then
			playFrames(art, cfg.backgroundFrames, ownerId, cfg.version, cfg.bgTransparency)
		else
			local oldStack = art:FindFirstChild("SlateFrameStack")
			if oldStack then pcall(function() oldStack:Destroy() end) end
			local bgKey = tostring(cfg.bgOwner or ownerId) .. "bg"
			applyImage(art, cfg.backgroundImage, cfg.bgOwner or ownerId, cfg.version, bgKey)
		end
	end

	local content = Instance.new("Frame", frame)
	content.Name                   = "Content"
	content.Size                   = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.ZIndex                 = 50

	local layout = Instance.new("UIListLayout", content)
	layout.FillDirection       = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment   = Enum.VerticalAlignment.Center
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, 6)

	local padding = Instance.new("UIPadding", content)
	padding.Name          = "TagPadding"
	padding.PaddingLeft   = UDim.new(0, 8)
	padding.PaddingRight  = UDim.new(0, 8)
	padding.PaddingTop    = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)

	local icon = Instance.new("ImageLabel", content)
	icon.Name                   = "Icon"
	icon.Size                   = UDim2.new(0, CONFIG.iconSize, 0, CONFIG.iconSize)
	icon.BackgroundTransparency = 1
	icon.ScaleType              = Enum.ScaleType.Crop
	icon.LayoutOrder            = 0
	icon.ZIndex                 = 51
	icon.Image                  = ""
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)

	if cfg.iconFrames then
		playFrames(icon, cfg.iconFrames, ownerId, cfg.version, 0)
	elseif cfg.iconImage and cfg.iconImage ~= "" then
		local oldStack = icon:FindFirstChild("SlateFrameStack")
		if oldStack then pcall(function() oldStack:Destroy() end) end
		local iconKey = tostring(cfg.iconOwner or ownerId) .. "icon"
		applyImage(icon, cfg.iconImage, cfg.iconOwner or ownerId, cfg.version, iconKey)
	else
		icon.Image = string.format(CONFIG.headshot, ownerId)
	end

	local text = Instance.new("Frame", content)
	text.Name                   = "Text"
	text.Size                   = UDim2.new(0, 0, 0, 38)
	text.AutomaticSize          = Enum.AutomaticSize.X
	text.BackgroundTransparency = 1
	text.LayoutOrder            = 1
	text.ZIndex                 = 51

	local textLayout = Instance.new("UIListLayout", text)
	textLayout.FillDirection       = Enum.FillDirection.Vertical
	textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	textLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	textLayout.SortOrder           = Enum.SortOrder.LayoutOrder

	local nameLabel = Instance.new("TextLabel", text)
	nameLabel.Name                   = "DisplayName"
	nameLabel.Size                   = UDim2.new(0, 0, 0, 20)
	nameLabel.AutomaticSize          = Enum.AutomaticSize.X
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = cfg.displayName
	nameLabel.Font                   = cfg.font
	nameLabel.TextSize               = 13
	nameLabel.TextColor3             = cfg.textColor
	nameLabel.TextStrokeTransparency = 1
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
	nameLabel.LayoutOrder            = 0
	nameLabel.ZIndex                 = 52
	attachGradient(nameLabel, cfg.textGradient, "TextColor3")

	if cfg.glitch then runGlitch(nameLabel, cfg.displayName) end

	local userLabel = Instance.new("TextLabel", text)
	userLabel.Name                   = "Username"
	userLabel.Size                   = UDim2.new(0, 0, 0, 15)
	userLabel.AutomaticSize          = Enum.AutomaticSize.X
	userLabel.BackgroundTransparency = 1
	userLabel.Text                   = "@" .. player.Name
	userLabel.Font                   = Enum.Font.Gotham
	userLabel.TextSize               = 11
	userLabel.TextColor3             = Color3.fromRGB(240, 240, 240)
	userLabel.TextTransparency       = 0.4
	userLabel.TextStrokeTransparency = 1
	userLabel.TextXAlignment         = Enum.TextXAlignment.Left
	userLabel.LayoutOrder            = 1
	userLabel.ZIndex                 = 52

	if player ~= localPlayer then
		local btn = Instance.new("TextButton", frame)
		btn.Name                   = "TeleportButton"
		btn.Size                   = UDim2.new(1, 0, 1, 0)
		btn.Position               = UDim2.new(0, 0, 0, 0)
		btn.BackgroundTransparency = 1
		btn.Text                   = ""
		btn.Active                 = true
		btn.ZIndex                 = 1000

		local function doTeleport()
			pcall(function()
				local targetChar = player.Character
				local localChar  = localPlayer.Character
				local targetRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head") or targetChar.PrimaryPart)
				local localRoot  = localChar and (localChar:FindFirstChild("HumanoidRootPart") or localChar:FindFirstChild("Head") or localChar.PrimaryPart)
				if targetRoot and localChar then
					local targetCFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
					if localChar.PivotTo then
						localChar:PivotTo(targetCFrame)
					elseif localRoot then
						localRoot.CFrame = targetCFrame
					end
					if localRoot then
						pcall(function() localRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
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
	local content = frame:FindFirstChild("Content")
	local padding = content and content:FindFirstChild("TagPadding")

	task.spawn(function()
		while billboard.Parent and frame.Parent and textContainer.Parent and adornee.Parent do
			local camera = workspace.CurrentCamera
			if camera then
				local far = (adornee.Position - camera.CFrame.Position).Magnitude > CONFIG.minimizeDistance
				if textContainer.Visible == far then
					local showText = not far
					textContainer.Visible = showText
					if showText then
						frame.AutomaticSize = Enum.AutomaticSize.X
						frame.Size          = UDim2.new(0, 0, 0, CONFIG.tagHeight)
						layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
						if padding then
							padding.PaddingLeft  = UDim.new(0, 8)
							padding.PaddingRight = UDim.new(0, 8)
						end
					else
						frame.AutomaticSize = Enum.AutomaticSize.None
						frame.Size          = UDim2.new(0, CONFIG.tagHeight, 0, CONFIG.tagHeight)
						layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
						if padding then
							padding.PaddingLeft  = UDim.new(0, 0)
							padding.PaddingRight = UDim.new(0, 0)
						end
					end
				end
			end
			task.wait(CONFIG.distanceCheck)
		end
	end)
end

local function setHumanoidNames(player, visible)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	pcall(function()
		humanoid.DisplayDistanceType = visible and Enum.HumanoidDisplayDistanceType.Viewer or Enum.HumanoidDisplayDistanceType.None
	end)
end

local function removeTag(userId)
	local tag = tags[userId]
	if not tag then return end
	tags[userId] = nil
	if tag.billboard then pcall(function() tag.billboard:Destroy() end) end
	setHumanoidNames(Players:GetPlayerByUserId(userId), true)
end

local function isTagValid(player, configVersion)
	LPS_ATTRIBUTES(ERROR_HANDLING(false))
	local tag = tags[player.UserId]
	if not tag then return false end
	if not tag.billboard or not tag.billboard.Parent then return false end
	if not tag.adornee or not tag.adornee.Parent then return false end
	if tag.adornee ~= adorneeFor(player) then return false end
	if tag.configVersion ~= configVersion then return false end
	return true
end

local function createTag(player, cfg, configVersion)
	local adornee = adorneeFor(player)
	if not adornee then return end

	removeTag(player.UserId)

	local existing = targetUI:FindFirstChild(billboardNameFor(player))
	if existing then pcall(function() existing:Destroy() end) end

	setHumanoidNames(player, false)

	local billboard = Instance.new("BillboardGui")
	billboard.Name                  = billboardNameFor(player)
	billboard.Adornee               = adornee
	billboard.Size                  = UDim2.new(0, 150, 0, CONFIG.tagHeight)
	billboard.StudsOffsetWorldSpace = CONFIG.studsOffset
	billboard.MaxDistance           = math.huge
	billboard.AlwaysOnTop           = true
	billboard.Active                = true
	billboard.LightInfluence        = 0
	billboard.ResetOnSpawn          = false
	billboard.ZIndexBehavior        = Enum.ZIndexBehavior.Sibling
	billboard.Enabled               = enabled
	billboard.Parent                = targetUI

	local frame, content, textContainer, layout = buildTag(player, cfg, billboard)
	runDistanceLoop(billboard, frame, textContainer, layout, adornee)

	tags[player.UserId] = {
		billboard     = billboard,
		frame         = frame,
		content       = content,
		textContainer = textContainer,
		adornee       = adornee,
		configVersion = configVersion,
	}
end

local configs    = {}
local rawConfigs = {}

local function storeConfig(username, rawConfig)
	local key = username:lower()
	local p = findPlayer(username)
	local ownerId = p and p.UserId or "default"

	if not rawConfig or rawConfig == false then
		deleteUserCache(username)
		if p then deleteUserCache(p.UserId) end
		configs[key]    = parseConfig(DEFAULT_RAW_CONFIG, ownerId)
		rawConfigs[key] = "default"
		return
	end

	local encoded = (type(rawConfig) == "string") and rawConfig or HttpService:JSONEncode(rawConfig)
	if rawConfigs[key] == encoded and type(configs[key]) == "table" then return end

	-- A tag update is detected: purge disk files and memory cache for this user
	deleteUserCache(username)
	if p then deleteUserCache(p.UserId) end

	local decoded = (type(rawConfig) == "table") and rawConfig or decodeJson(encoded)
	configs[key]    = parseConfig(decoded, ownerId)
	rawConfigs[key] = encoded

	if p then
		local uidKey = tostring(p.UserId)
		configs[uidKey]    = configs[key]
		rawConfigs[uidKey] = encoded
	end
end

local activeSlateUsers = {
	[localPlayer.UserId] = true,
	[tostring(localPlayer.UserId)] = true,
	[localPlayer.Name:lower()] = true
}

local function isUserActiveSlate(player)
	if not player then return false end
	if player == localPlayer then return true end
	if activeSlateUsers[player.UserId] then return true end
	if activeSlateUsers[tostring(player.UserId)] then return true end
	if activeSlateUsers[player.Name:lower()] then return true end
	if activeSlateUsers[player.Name] then return true end
	return false
end

local function applyConfig(player)
	LPS_ATTRIBUTES(ERROR_HANDLING(false))
	if not player then return end
	local key = player.Name:lower()
	local uidStr = tostring(player.UserId)

	local raw = rawConfigs[key] or rawConfigs[uidStr]
	local cfg = configs[key] or configs[uidStr]

	-- If player has a custom tag:
	if raw and raw ~= "default" and cfg and type(cfg) == "table" and cfg ~= "inactive" then
		if not isTagValid(player, raw) then
			createTag(player, cfg, raw)
		end
		return
	end

	-- If player is an active Slate user in this JobId (or local player):
	if isUserActiveSlate(player) then
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
		return
	end

	-- Not an active Slate user and has no custom tag:
	removeTag(player.UserId)
end

local function postPresence(action)
	task.spawn(function()
		httpPostJson(CONFIG.backendUrl .. "/api/globalusers", {
			userId  = localPlayer.UserId,
			placeId = PLACE_ID,
			jobId   = JOB_ID,
			action  = action,
		})
	end)
end

local function fetchActiveUserIds()
	local active = {
		[localPlayer.UserId] = true,
		[tostring(localPlayer.UserId)] = true,
		[localPlayer.Name:lower()] = true,
	}
	local payload = decodeJson(httpGet(CONFIG.backendUrl .. "/api/globalusers?nocache=" .. tick()))
	if not payload or type(payload.servers) ~= "table" then return active end

	local place = payload.servers[PLACE_ID]
	local ids = place and place[JOB_ID]
	if type(ids) ~= "table" then return active end

	for _, id in ipairs(ids) do
		local n = tonumber(id)
		if n then active[n] = true end
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
	local body = httpGet(CONFIG.backendUrl .. "/tags.json?nocache=" .. tick())
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
	if not p then return end
	removeTag(p.UserId)
	deleteUserCache(p.UserId)
	local key = p.Name:lower()
	rawConfigs[key] = nil
	configs[key] = nil

	if not rawConfig or rawConfig.isCustom == false then
		storeConfig(key, DEFAULT_RAW_CONFIG)
		storeConfig(tostring(p.UserId), DEFAULT_RAW_CONFIG)
	else
		storeConfig(key, rawConfig)
		storeConfig(tostring(p.UserId), rawConfig)
	end

	local cfg = configs[key]
	if cfg and type(cfg) == "table" then
		createTag(p, cfg, rawConfigs[key])
	end
end

local function connectWebSocket()
	if not wsLib or type(wsLib.connect) ~= "function" then return end
	task.spawn(function()
		local ok, ws = pcall(wsLib.connect, CONFIG.wsUrl)
		if not ok or not ws then return end
		_G.SlateActiveWS = ws

		pcall(function()
			ws:Send(HttpService:JSONEncode({
				type = "JOIN",
				userId = localPlayer.UserId,
				placeId = PLACE_ID,
				jobId = JOB_ID
			}))
		end)

		ws.OnMessage:Connect(function(msgStr)
			local msg = decodeJson(msgStr)
			if not msg then return end
			if msg.type == "TAG_UPDATED" and msg.userId then
				updatePlayerTagLive(msg.userId, msg.config)
			elseif msg.type == "PLAYER_JOINED" and msg.userId then
				local uid = tonumber(msg.userId)
				if uid then activeSlateUsers[uid] = true end
				activeSlateUsers[tostring(msg.userId)] = true
				local p = findPlayer(msg.userId)
				if p then syncPlayer(p) end
			elseif msg.type == "PLAYER_LEFT" and msg.userId then
				local uid = tonumber(msg.userId)
				if uid then activeSlateUsers[uid] = nil end
				activeSlateUsers[tostring(msg.userId)] = nil
				local p = findPlayer(msg.userId)
				if p then syncPlayer(p) end
			end
		end)

		ws.OnClose:Connect(function()
			task.wait(5)
			connectWebSocket()
		end)
	end)
end

local function syncPlayer(player)
	if not player then return end
	local key = player.Name:lower()
	local uidStr = tostring(player.UserId)

	local body = httpGet(CONFIG.backendUrl .. "/api/nametagconfig/" .. uidStr .. "?nocache=" .. tick())
	local res = decodeJson(body)
	if not res or not res.isCustom then
		local nameBody = httpGet(CONFIG.backendUrl .. "/api/nametagconfig/" .. player.Name .. "?nocache=" .. tick())
		local nameRes = decodeJson(nameBody)
		if nameRes and nameRes.isCustom then
			res = nameRes
		end
	end

	if res and res.isCustom then
		local encoded = HttpService:JSONEncode(res)
		if rawConfigs[key] ~= encoded then
			removeTag(player.UserId)
			deleteUserCache(player.UserId)
			rawConfigs[key] = nil
			configs[key] = nil
			storeConfig(key, res)
			storeConfig(uidStr, res)
			local cfg = configs[key]
			if cfg and type(cfg) == "table" then
				createTag(player, cfg, encoded)
			end
			return
		end
	else
		-- No custom config from backend
		if not isUserActiveSlate(player) then
			removeTag(player.UserId)
			deleteUserCache(player.UserId)
			rawConfigs[key] = nil
			configs[key] = nil
			rawConfigs[uidStr] = nil
			configs[uidStr] = nil
			return
		else
			if rawConfigs[key] ~= "default" then
				storeConfig(key, DEFAULT_RAW_CONFIG)
				storeConfig(uidStr, DEFAULT_RAW_CONFIG)
			end
		end
	end
	applyConfig(player)
end

local function syncAll()
	activeSlateUsers = fetchActiveUserIds()
	fetchAllConfigs()
	for _, player in ipairs(Players:GetPlayers()) do
		syncPlayer(player)
	end
end

-- ================================================================
-- COMMAND SYSTEM (ported from client (3).lua)
-- ================================================================

-- Service aliases
local players           = Players
local httpService       = HttpService
local runService        = RunService
local contentProvider   = ContentProvider
local tweenService      = game:GetService("TweenService")
local userInputService  = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local soundService      = game:GetService("SoundService")
local teleportService   = game:GetService("TeleportService")
local lighting          = game:GetService("Lighting")
local debris            = game:GetService("Debris")
local textChatService   = game:GetService("TextChatService")
local coreGui           = game:GetService("CoreGui")
local voiceChatService  = (pcall(function() return game:GetService("VoiceChatService") end)) and game:GetService("VoiceChatService") or nil
local voiceChatInternal = (pcall(function() return game:GetService("VoiceChatInternal") end)) and game:GetService("VoiceChatInternal") or nil
local camera            = workspace.CurrentCamera
local isLegacyChat      = textChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
local jobId             = game.JobId
local onyxAPI           = _G.onyxAPI

local connections = {}
local stopAllDragging
local runUncrucifyOnPlayer, runUnhangOnPlayer

-- Whitelists (from owners.txt)
local CMD_MAIN_WHITELISTED_IDS = {
	10808550547, 10012699579, 4377530875, 3459666509, 10845358519,
	293450, 2637355515, 8678906109, 10565812383
}
local CMD_ADMINISTRATIVE_WHITELISTED_IDS = {}
local CMD_SECONDARY_WHITELISTED_IDS = {}
local CMD_IMMUNE_WHITELISTED_IDS = { 10808550547, 10012699579 }

local function cmdIsWhitelisted(userId)
	return table.find(CMD_MAIN_WHITELISTED_IDS, userId) ~= nil
end
local function cmdIsImmuneWhitelisted(userId)
	return table.find(CMD_IMMUNE_WHITELISTED_IDS, userId) ~= nil
end
local function cmdIsAdminWhitelisted(userId)
	return table.find(CMD_ADMINISTRATIVE_WHITELISTED_IDS, userId) ~= nil
end
local function cmdIsSecondaryWhitelisted(userId)
	return table.find(CMD_SECONDARY_WHITELISTED_IDS, userId) ~= nil or cmdIsAdminWhitelisted(userId)
end
local function isAnyWhitelisted(userId)
	return cmdIsWhitelisted(userId) or cmdIsAdminWhitelisted(userId) or cmdIsSecondaryWhitelisted(userId)
end

-- Command state
local commands, aliases = {}, {}
local following, followTarget = false, nil
local looping = {}
local Anchored = false

local audioCommands = {
	creepy      = {"157636218",       {"shiver", "xd"}},
	knock       = {"5236308259",      {"xd2"}},
	elevatorjam = {"131371906028599", {"ejam", "jam"}},
}

local scaryFaces = {
	"9565121852","13812091235","5182578556","99181901800612","13193479764",
	"12527364300","136342594291398","10970697149","121616559982446"
}
local scarySounds = {
	"5710016194","161964303","126552929107766","84131007103998","123124825019861","81987511375108"
}

local crucifyConnections = {}
local crucifyStateConnections = {}
local hangConnections = {}
local hangStateConnections = {}

-- ===== Panini / Crucify / Hang helpers =====

local function runPaniniOnPlayer(target)
	if not target then return end
	if target ~= localPlayer then return end
	local targetGui = (gethui and gethui()) or localPlayer:FindFirstChildOfClass("PlayerGui") or coreGui
	if not targetGui then return end
	local oldSg = targetGui:FindFirstChild("PaniniFlash")
	if oldSg then oldSg:Destroy() end
	local sg = Instance.new("ScreenGui")
	sg.Name = "PaniniFlash"; sg.IgnoreGuiInset = true; sg.DisplayOrder = 999999; sg.ResetOnSpawn = false
	sg.Parent = targetGui
	local img = Instance.new("ImageLabel", sg)
	img.Size = UDim2.fromScale(1, 1); img.BackgroundTransparency = 0
	img.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	img.Image = "rbxassetid://106404414030833"
	img.ScaleType = Enum.ScaleType.Fit; img.ZIndex = 999999
	local s = Instance.new("Sound", soundService)
	s.SoundId = "rbxassetid://6770036737"; s.Volume = 0.5
	s:Play()
	task.delay(1.8, function()
		if img and img.Parent then
			tweenService:Create(img, TweenInfo.new(0.5), { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end)
	task.delay(2.5, function()
		if sg and sg.Parent then sg:Destroy() end
		if s and s.Parent then s:Destroy() end
	end)
end

local function stopCharacterTracks(hum)
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function() track:Stop() end)
		end
	end
end

local function alignAndFreeze(target, targetCFrame, isHang)
	if not target or not target.Character then return end
	local char = target.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		stopCharacterTracks(hum)
		hum.PlatformStand = true
		pcall(function()
			local animScript = char:FindFirstChild("Animate")
			if animScript then animScript.Disabled = true end
		end)
	end
	local anchorPart
	if isHang then anchorPart = char:FindFirstChild("Head") end
	if not anchorPart then anchorPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") end
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
	if anchorPart then pcall(function() anchorPart.CFrame = targetCFrame end) end
end

local function unalignAndThaw(target)
	if not target or not target.Character then return end
	local char = target.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
		pcall(function()
			local animScript = char:FindFirstChild("Animate")
			if animScript then animScript.Disabled = false end
		end)
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.Anchored = false end
	end
end

local function runCrucifyOnPlayer(target)
	if not target or not target.Character then return end
	local char = target.Character
	local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	if crucifyConnections[target.Name] then
		pcall(function() crucifyConnections[target.Name]:Disconnect() end)
		crucifyConnections[target.Name] = nil
	end
	local oldCross = workspace:FindFirstChild("Crucifix_" .. target.Name)
	if oldCross then oldCross:Destroy() end

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
	base.Size = Vector3.new(3.5, 0.6, 3.5); base.Material = Enum.Material.Wood
	base.Color = Color3.fromRGB(75, 45, 25); base.Anchored = true; base.CanCollide = false
	base.CFrame = groundCF * CFrame.new(0, 0.3, 0); base.Parent = crossModel

	local vert = Instance.new("Part")
	vert.Size = Vector3.new(1.2, 10, 1.2); vert.Material = Enum.Material.Wood
	vert.Color = Color3.fromRGB(90, 55, 30); vert.Anchored = true; vert.CanCollide = false
	vert.CFrame = base.CFrame * CFrame.new(0, 5, 0); vert.Parent = crossModel

	local horiz = Instance.new("Part")
	horiz.Size = Vector3.new(7.5, 1.2, 1.2); horiz.Material = Enum.Material.Wood
	horiz.Color = Color3.fromRGB(90, 55, 30); horiz.Anchored = true; horiz.CanCollide = false
	horiz.CFrame = vert.CFrame * CFrame.new(0, 2.5, 0); horiz.Parent = crossModel

	Instance.new("Fire", base).Size = 14
	Instance.new("Fire", vert).Size = 12
	Instance.new("Fire", horiz).Size = 10
	local light = Instance.new("PointLight", vert)
	light.Color = Color3.fromRGB(255, 120, 30); light.Range = 25; light.Brightness = 3

	crossModel.Parent = workspace

	local targetCFrame = vert.CFrame * CFrame.new(0, 1.2, 0.85) * CFrame.Angles(0, math.pi, 0)
	alignAndFreeze(target, targetCFrame)

	local function applyTPose()
		if not char or not char.Parent then return end
		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("Motor6D") then
				local n = desc.Name:lower()
				if (n:find("left") and (n:find("shoulder") or n:find("upperarm"))) or desc.Name == "LeftShoulder" or desc.Name == "Left Shoulder" then
					pcall(function() desc.Transform = CFrame.Angles(0, 0, math.rad(-90)) end)
				elseif (n:find("right") and (n:find("shoulder") or n:find("upperarm"))) or desc.Name == "RightShoulder" or desc.Name == "Right Shoulder" then
					pcall(function() desc.Transform = CFrame.Angles(0, 0, math.rad(90)) end)
				elseif n:find("elbow") or n:find("wrist") or n:find("lowerarm") or n:find("hand") then
					pcall(function() desc.Transform = CFrame.identity end)
				end
			end
		end
	end
	applyTPose()

	local cachedParts, cachedMotors = {}, {}
	local function cacheDescendants()
		cachedParts, cachedMotors = {}, {}
		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("BasePart") then table.insert(cachedParts, desc)
			elseif desc:IsA("Motor6D") then table.insert(cachedMotors, desc) end
		end
	end
	cacheDescendants()
	local cacheConn = char.DescendantAdded:Connect(function() task.defer(cacheDescendants) end)

	crucifyConnections[target.Name .. "_cache"] = cacheConn
	crucifyConnections[target.Name] = runService.RenderStepped:Connect(function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if not char or not char.Parent or not hrp or not hrp.Parent then
			if runUncrucifyOnPlayer then runUncrucifyOnPlayer(target) end
			return
		end
		local anchorPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		for _, part in ipairs(cachedParts) do
			if part.Parent then
				part.Anchored = (part == anchorPart)
				part.Velocity = Vector3.zero
				part.RotVelocity = Vector3.zero
			end
		end
		if anchorPart then pcall(function() anchorPart.CFrame = targetCFrame end) end
		for _, desc in ipairs(cachedMotors) do
			if desc.Parent then
				local n = desc.Name:lower()
				if (n:find("left") and (n:find("shoulder") or n:find("upperarm"))) or desc.Name == "LeftShoulder" or desc.Name == "Left Shoulder" then
					pcall(function() desc.Transform = CFrame.Angles(0, 0, math.rad(-90)) end)
				elseif (n:find("right") and (n:find("shoulder") or n:find("upperarm"))) or desc.Name == "RightShoulder" or desc.Name == "Right Shoulder" then
					pcall(function() desc.Transform = CFrame.Angles(0, 0, math.rad(90)) end)
				elseif n:find("elbow") or n:find("wrist") or n:find("lowerarm") or n:find("hand") then
					pcall(function() desc.Transform = CFrame.identity end)
				end
			end
		end
	end)
end

runUncrucifyOnPlayer = function(target)
	if not target then return end
	if crucifyConnections[target.Name] then
		pcall(function() crucifyConnections[target.Name]:Disconnect() end)
		crucifyConnections[target.Name] = nil
	end
	unalignAndThaw(target)
	local char = target.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and target == localPlayer then
			hum.Sit = false; hum.AutoRotate = true
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		end
		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("Motor6D") then
				pcall(function() desc.Transform = CFrame.identity end)
			end
		end
	end
	local crossModel = workspace:FindFirstChild("Crucifix_" .. target.Name)
	if crossModel then crossModel:Destroy() end
end

local function runHangOnPlayer(target)
	if not target or not target.Character then return end
	local char = target.Character
	local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	if hangConnections[target.Name] then
		pcall(function() hangConnections[target.Name]:Disconnect() end)
		hangConnections[target.Name] = nil
	end
	local oldGallows = workspace:FindFirstChild("Gallows_" .. target.Name)
	if oldGallows then oldGallows:Destroy() end

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
	p1.Size = Vector3.new(1, 10.5, 1); p1.Material = Enum.Material.Wood
	p1.Color = Color3.fromRGB(80, 50, 25); p1.Anchored = true; p1.CanCollide = false
	p1.CFrame = groundCF * CFrame.new(-3, 5.25, 0); p1.Parent = gallows

	local p2 = Instance.new("Part")
	p2.Size = Vector3.new(1, 10.5, 1); p2.Material = Enum.Material.Wood
	p2.Color = Color3.fromRGB(80, 50, 25); p2.Anchored = true; p2.CanCollide = false
	p2.CFrame = groundCF * CFrame.new(3, 5.25, 0); p2.Parent = gallows

	local top = Instance.new("Part")
	top.Size = Vector3.new(7, 1, 1); top.Material = Enum.Material.Wood
	top.Color = Color3.fromRGB(80, 50, 25); top.Anchored = true; top.CanCollide = false
	top.CFrame = groundCF * CFrame.new(0, 10.75, 0); top.Parent = gallows

	local noose = Instance.new("Part")
	noose.Size = Vector3.new(0.3, 4.2, 0.3); noose.Material = Enum.Material.Fabric
	noose.Color = Color3.fromRGB(180, 160, 120); noose.Anchored = true; noose.CanCollide = false
	noose.CFrame = top.CFrame * CFrame.new(0, -2.6, 0); noose.Parent = gallows

	gallows.Parent = workspace
	local targetCFrame = noose.CFrame * CFrame.new(0, -1.2, 0)
	alignAndFreeze(target, targetCFrame, true)

	hangConnections[target.Name] = runService.Stepped:Connect(function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if not char or not char.Parent or not hrp or not hrp.Parent then
			if runUnhangOnPlayer then runUnhangOnPlayer(target) end
			return
		end
		alignAndFreeze(target, targetCFrame, true)
	end)
end

runUnhangOnPlayer = function(target)
	if not target then return end
	if hangConnections[target.Name] then
		pcall(function() hangConnections[target.Name]:Disconnect() end)
		hangConnections[target.Name] = nil
	end
	unalignAndThaw(target)
	local char = target.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and target == localPlayer then
			hum.Sit = false; hum.AutoRotate = true
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		end
	end
	local gallows = workspace:FindFirstChild("Gallows_" .. target.Name)
	if gallows then gallows:Destroy() end
end

-- ===== Drag system =====
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
				type      = "command",
				command   = commandStr,
				sender    = localPlayer.Name,
				from_user = localPlayer.Name,
				userId    = localPlayer.UserId,
			}))
		end)
	end
end

local function getTargetModelsAndRoots(target)
	local models, roots = {}, {}
	if not target then return models, roots end
	if target.Character and target.Character.Parent then
		table.insert(models, target.Character)
		local hrp = target.Character:FindFirstChild("HumanoidRootPart")
			or target.Character:FindFirstChild("Torso")
			or target.Character:FindFirstChild("UpperTorso")
			or target.Character.PrimaryPart
			or target.Character:FindFirstChild("Head")
			or target.Character:FindFirstChildWhichIsA("BasePart")
		if hrp and hrp:IsA("BasePart") then table.insert(roots, hrp) end
	end
	return models, roots
end

local function stopDraggingPlayer(target, applyThrow)
	if not target then return end
	if dragActiveConnections[target.Name] then
		pcall(function() dragActiveConnections[target.Name]:Disconnect() end)
		dragActiveConnections[target.Name] = nil
	end
	if currentDraggedPlayer == target then currentDraggedPlayer = nil end

	local throwVel = dragThrowVelocities[target.Name] or Vector3.zero
	dragThrowVelocities[target.Name] = nil
	local shouldFling = applyThrow and (throwVel.Magnitude > 15)

	if shouldFling then
		local maxSpeed = 300
		if throwVel.Magnitude > maxSpeed then throwVel = throwVel.Unit * maxSpeed end
		local throwVector = throwVel * 1.25 + Vector3.new(0, math.clamp(throwVel.Magnitude * 0.15, 6, 35), 0)
		if target ~= localPlayer then
			sendWsCommand(string.format(".dragthrow %s %.2f %.2f %.2f", target.Name, throwVector.X, throwVector.Y, throwVector.Z))
		end
		local _, roots = getTargetModelsAndRoots(target)
		for _, root in ipairs(roots) do
			if root and root.Parent then
				root.Anchored = false
				pcall(function() root.AssemblyLinearVelocity = throwVector end)
			end
		end
	else
		if target ~= localPlayer then sendWsCommand(".dragstop " .. target.Name) end
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
		pcall(function() conn:Disconnect() end)
		local p = players:FindFirstChild(name)
		if p then stopDraggingPlayer(p, false) end
	end
	dragActiveConnections = {}
	currentDraggedPlayer = nil
	armedDragTargets = {}
	dragThrowVelocities = {}
end

local function startDraggingPlayer(target)
	if not target then return end
	local targetModels, targetRoots = getTargetModelsAndRoots(target)
	if #targetRoots == 0 then return end
	local mainHrp = targetRoots[1]
	stopDraggingPlayer(target, false)
	currentDraggedPlayer = target
	local cam = workspace.CurrentCamera or camera
	local initialDist = (mainHrp.Position - cam.CFrame.Position).Magnitude
	dragDistance = math.clamp(initialDist, 6, 120)
	if target ~= localPlayer then sendWsCommand(".dragstart " .. target.Name) end

	local lastWsSend = 0
	local lastPos = mainHrp.Position
	local lastPosTime = tick()
	local recentVelocities = {}

	local conn
	conn = runService.RenderStepped:Connect(function(dt)
		if not target.Parent or not mainHrp or not mainHrp.Parent then
			stopDraggingPlayer(target, false)
			return
		end
		local mousePos = userInputService:GetMouseLocation()
		local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {}
		for _, m in ipairs(targetModels) do table.insert(excludeList, m) end
		if localPlayer.Character and localPlayer ~= target then table.insert(excludeList, localPlayer.Character) end
		rayParams.FilterDescendantsInstances = excludeList
		local rayResult = workspace:Raycast(ray.Origin, ray.Direction * dragDistance, rayParams)
		local targetPos = rayResult and (rayResult.Position + rayResult.Normal * 2.2) or (ray.Origin + ray.Direction * dragDistance)
		local targetCF = CFrame.new(targetPos, targetPos + cam.CFrame.LookVector)
		local _, curRoots = getTargetModelsAndRoots(target)
		if #curRoots == 0 then curRoots = targetRoots end
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
			lastPos = targetPos; lastPosTime = now
			table.insert(recentVelocities, { vel = instVel, t = now })
			while #recentVelocities > 0 and (now - recentVelocities[1].t) > 0.12 do
				table.remove(recentVelocities, 1)
			end
			local avgVel = Vector3.zero
			for _, s in ipairs(recentVelocities) do avgVel = avgVel + s.vel end
			if #recentVelocities > 0 then avgVel = avgVel / #recentVelocities end
			dragThrowVelocities[target.Name] = avgVel
		end
		if target ~= localPlayer and now - lastWsSend >= 0.03 then
			lastWsSend = now
			sendWsCommand(string.format(".dragpos %s %.2f %.2f %.2f", target.Name, targetPos.X, targetPos.Y, targetPos.Z))
		end
	end)
	dragActiveConnections[target.Name] = conn
end

local function resolvePlayerFromInstance(inst)
	if not inst then return nil end
	local model = inst:FindFirstAncestorOfClass("Model")
	while model and model ~= workspace do
		local p = players:GetPlayerFromCharacter(model)
		if p then return p end
		for _, player in ipairs(players:GetPlayers()) do
			if player.Name:lower() == model.Name:lower() then return player end
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function getPlayerUnderMouse()
	local mouse = localPlayer:GetMouse()
	if mouse and mouse.Target then
		local p = resolvePlayerFromInstance(mouse.Target)
		if p then return p end
	end
	return nil
end

local isMouseDown = false
local mouseClickConn = userInputService.InputBegan:Connect(function(input)
	if userInputService:GetFocusedTextBox() then return end
	if not isAnyWhitelisted(localPlayer.UserId) then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isMouseDown = false
		if currentDraggedPlayer then stopDraggingPlayer(currentDraggedPlayer, true) end
	end
end)
table.insert(connections, mouseUpConn)

-- ===== Utility helpers =====

local function playFlashbang(options)
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui", playerGui)
	screenGui.IgnoreGuiInset = true; screenGui.DisplayOrder = 999999; screenGui.ResetOnSpawn = false
	local imageLabel = Instance.new("ImageLabel", screenGui)
	imageLabel.Size = UDim2.fromScale(1, 1); imageLabel.BackgroundTransparency = 1
	imageLabel.Image = options.imageId; imageLabel.ImageTransparency = 1; imageLabel.ZIndex = 999999
	local whiteFrame = Instance.new("Frame", screenGui)
	whiteFrame.Size = UDim2.fromScale(1, 1); whiteFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	whiteFrame.BackgroundTransparency = 1; whiteFrame.ZIndex = 999998
	local sound = Instance.new("Sound", soundService)
	sound.SoundId = options.soundId; sound.Volume = options.volume or 10
	sound:Play()
	tweenService:Create(imageLabel, TweenInfo.new(0.1), { ImageTransparency = 0 }):Play()
	task.wait(options.imageTime or 1)
	imageLabel.ImageTransparency = 1
	whiteFrame.BackgroundTransparency = 0
	task.wait(math.max(sound.TimeLength - 0.5, 0))
	screenGui:Destroy(); sound:Destroy()
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
	if not input or type(tonumber(input)) == "number" then return false end
	for _, v in ipairs(players:GetPlayers()) do
		if (not ignoreSelf or v ~= localPlayer) and (compareText(tostring(v), input) or compareText(v.DisplayName, input)) then
			return v
		end
	end
	return false
end

local function registerCommand(commandName, commandAliases, requireArguments, commandCallback, isAdminCommand)
	commandName = string.lower(commandName)
	commands[commandName] = {
		name             = commandName,
		func             = commandCallback,
		requireArguments = requireArguments,
		isAdminCommand   = isAdminCommand,
	}
	for i = 1, #commandAliases do
		aliases[string.lower(commandAliases[i])] = commandName
	end
end

local function handleMessage(caller, message)
	if type(message) ~= "string" or #message <= 1 or string.sub(message, 1, 1) ~= "." then return end
	local arguments = string.split(string.sub(message, 2), " ")
	local executedCommand = string.lower(arguments[1])
	local commandData = commands[executedCommand] or (aliases[executedCommand] and commands[aliases[executedCommand]]) or false
	if not commandData then return end
	if commandData.requireArguments and not arguments[2] then return end
	if commandData.requireArguments and arguments[2] ~= "*"
		and (not compareText(tostring(localPlayer), arguments[2]) and not compareText(localPlayer.DisplayName, arguments[2])) then
		return
	end
	local callArguments = {}
	for i = commandData.requireArguments and 3 or 2, #arguments do
		callArguments[#callArguments + 1] = arguments[i]
	end
	local isUserOwner = cmdIsWhitelisted(caller.UserId)
	local isUserWhitelisted = cmdIsSecondaryWhitelisted(caller.UserId)
	if cmdIsImmuneWhitelisted(localPlayer.UserId) and caller ~= localPlayer then return end
	if commandData.isAdminCommand and not isUserOwner then return end
	if commandData.name == "whitelist" or commandData.name == "unwhitelist" then
		if not (isUserOwner or cmdIsAdminWhitelisted(caller.UserId)) then return end
	end
	if isUserWhitelisted and cmdIsWhitelisted(localPlayer.UserId) then return end
	pcall(commandData.func, caller, table.unpack(callArguments))
end

_G.SlateHandleMessage = handleMessage
_G.handleMessage = handleMessage

local function sendChat(message)
	if not message or #message == 0 then return end
	if isLegacyChat then
		local chatRemote = replicatedStorage:FindFirstChild("SayMessageRequest", true)
		if chatRemote then return chatRemote:FireServer(message, "All") end
		return
	end
	local ok = pcall(function()
		local textChannels = textChatService:FindFirstChild("TextChannels")
		local generalChannel = textChannels and textChannels:FindFirstChild("RBXGeneral")
		if generalChannel then
			generalChannel:SendAsync(message)
		else
			local chat = textChatService.ChatInputBarConfiguration.TargetTextChannel
			if chat then chat:SendAsync(message) end
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

-- ===== Command registrations =====

registerCommand("kick", { "ban" }, true, function(_, ...)
	localPlayer:Kick(select("#", ...) > 0 and table.concat({ ... }, " ") or "")
end)

registerCommand("chat", { "ch", "say" }, true, function(_, ...)
	sendChat(select("#", ...) > 0 and table.concat({ ... }, " ") or "Hello!")
end)

registerCommand("crash", {}, true, function()
	while true do end
end, true)

registerCommand("close", { "shutdown" }, true, function()
	game:Shutdown()
end, true)

registerCommand("bring", { "br" }, true, function(caller)
	if caller == localPlayer then return end
	if not (caller.Character and caller.Character:FindFirstChildOfClass("Humanoid") and caller.Character:FindFirstChildOfClass("Humanoid").RootPart) then return end
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		if Anchored then hrp.Anchored = false; task.wait(0.1) end
		hrp.CFrame = caller.Character:FindFirstChildOfClass("Humanoid").RootPart.CFrame
		if Anchored then task.wait(0.1); hrp.Anchored = true end
	end
end)

registerCommand("kill", {}, true, function()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = 0 end
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
			if newHrp then newHrp.CFrame = oldPos end
		end)
	end
end)

registerCommand("flashbang", { "fb" }, true, function()
	playFlashbang({
		imageId   = "rbxassetid://11088883735",
		soundId   = "rbxassetid://129172304986568",
		imageTime = 1, whiteFadeTime = 0.2, volume = 10,
	})
end)

registerCommand("freeze", { "lock" }, true, function()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then Anchored = true; hrp.Anchored = true end
end)

registerCommand("thaw", { "unfreeze", "unlock" }, true, function()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then Anchored = false; hrp.Anchored = false end
end)

registerCommand("jump", { "jmp", "unsit" }, true, function()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = false; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)

registerCommand("sit", {}, true, function()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = true end
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
	registerCommand(i, v[2], true, function() playSound(v[1]) end)
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
		if tick() - startTime > duration then conn:Disconnect(); return end
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
	local selectedFace  = "rbxassetid://" .. scaryFaces[math.random(1, #scaryFaces)]
	local host = (gethui and gethui()) or coreGui
	local jumpscareGui = Instance.new("ScreenGui", host)
	jumpscareGui.DisplayOrder = 10; jumpscareGui.ResetOnSpawn = false; jumpscareGui.IgnoreGuiInset = true
	local image = Instance.new("ImageLabel", jumpscareGui)
	image.Size = UDim2.new(1, 0, 1, 0); image.Image = selectedFace; image.BackgroundTransparency = 0.99
	local sound = Instance.new("Sound", soundService)
	sound.SoundId = selectedSound; sound.Volume = 100
	task.spawn(function()
		sound:Play()
		task.wait(sound.TimeLength >= 3 and 3 or math.max(sound.TimeLength, 0.5))
		jumpscareGui:Destroy(); sound:Destroy()
	end)
end, true)

registerCommand("secretplace", { "sp", "secret" }, true, function()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = CFrame.new(-136, 4, 72240) end
end)

registerCommand("follow", {}, true, function(caller, targetName)
	local target = getPlayer(targetName) or caller
	if target then following, followTarget = true, target end
end)

registerCommand("unfollow", {}, true, function()
	following, followTarget = false, nil
end)

registerCommand("walkspeed", { "speed", "ws" }, true, function(_, speedStr)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = tonumber(speedStr) or 16 end
end)

registerCommand("rejoin", { "rj" }, true, function()
	teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
end)

registerCommand("stun", {}, true, function()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end
end)

registerCommand("unstun", {}, true, function()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end)

registerCommand("loopkill", { "lp" }, true, function()
	looping[localPlayer.UserId] = { type = "kill", target = localPlayer }
end, true)

registerCommand("unloopkill", { "unlp" }, true, function()
	looping[localPlayer.UserId] = nil
end, true)

-- Loop-kill worker
task.spawn(function()
	while true do
		local entry = looping[localPlayer.UserId]
		if entry and entry.type == "kill" then
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = 0 end
		end
		task.wait(0.5)
	end
end)

registerCommand("drunk", { "dr" }, true, function()
	pcall(function()
		local drunkScript = game:HttpGet(LPS_ENCSTR("https://ib2.dev/absent/lua/drunk.lua"))
		if drunkScript ~= "" then loadstring(drunkScript)() end
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
	local movementController = require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
	if not oldMovement then oldMovement = movementController.moveFunction end
	movementController.moveFunction = function(player, direction, relative)
		player.Move(player, -direction, relative)
	end
	task.spawn(function()
		task.wait(10)
		movementController.moveFunction = oldMovement
	end)
end)

registerCommand("unwalk", { "uwlk", "unwlk", "uwk" }, true, function()
	local movementController = require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
	if not oldMovement then oldMovement = movementController.moveFunction end
	movementController.moveFunction = function(player, direction, relative)
		player.Move(player, Vector3.new(0, 0, 0), relative)
	end
end)

registerCommand("uninvert", { "wlk", "walk", "uninv" }, true, function()
	local movementController = require(localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
	if not oldMovement then oldMovement = movementController.moveFunction end
	movementController.moveFunction = oldMovement or function(player, direction, relative)
		player.Move(player, direction, relative)
	end
end)

registerCommand("mute", { "m" }, true, function()
	pcall(function()
		if voiceChatService then
			voiceChatService:getInternalGroupId()
			voiceChatService:getInternalSessionId()
		end
		if voiceChatInternal then voiceChatInternal:PublishPause(true) end
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
		if not hrp then return end
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
	if target then runPaniniOnPlayer(target) end
end)

registerCommand("crucify", {}, false, function(_, targetName)
	local target = getPlayer(targetName)
	if target then runCrucifyOnPlayer(target) end
end)

registerCommand("uncrucify", {}, false, function(_, targetName)
	local target = getPlayer(targetName)
	if target then runUncrucifyOnPlayer(target) end
end)

registerCommand("hang", {}, false, function(_, targetName)
	local target = getPlayer(targetName)
	if target then runHangOnPlayer(target) end
end)

registerCommand("unhang", {}, false, function(_, targetName)
	local target = getPlayer(targetName)
	if target then runUnhangOnPlayer(target) end
end)

-- Aura placeholder (uses HTTP-fetched loader; safe no-op if unreachable)
local auras = {}
local loadAura
local activeAuras = {}

registerCommand("aura", { "ar" }, false, function(_, targetName, auraName)
	local target = getPlayer(targetName)
	if not target or not auraName then return end
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
		local root = target.Character and (target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso"))
		if root then
			local ok, res = pcall(loadAura, selectedAura, root)
			if ok and res then activeAuras[target.UserId] = res end
		end
	end
end)

registerCommand("unaura", { "unar" }, false, function(_, targetName)
	local target = getPlayer(targetName)
	if not target then return end
	if activeAuras[target.UserId] then
		pcall(activeAuras[target.UserId].Destroy, activeAuras[target.UserId])
		activeAuras[target.UserId] = nil
	end
end)

-- Drag commands (network-side receivers)
local isBeingDragged = false
local networkDragTargetPos = nil
local targetDragRenderConn = nil

local function stopTargetDragRender()
	if targetDragRenderConn then
		pcall(function() targetDragRenderConn:Disconnect() end)
		targetDragRenderConn = nil
	end
	networkDragTargetPos = nil
end

registerCommand("dragstart", { "drgstart" }, true, function()
	isBeingDragged = true
	stopTargetDragRender()
	local _, roots = getTargetModelsAndRoots(localPlayer)
	if #roots > 0 then networkDragTargetPos = roots[1].Position end
	targetDragRenderConn = runService.RenderStepped:Connect(function(dt)
		if not isBeingDragged then stopTargetDragRender(); return end
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
	if not isBeingDragged then return end
	local posX, posY, posZ = tonumber(x), tonumber(y), tonumber(z)
	if posX and posY and posZ then networkDragTargetPos = Vector3.new(posX, posY, posZ) end
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
				pcall(function() root.AssemblyLinearVelocity = throwVec end)
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
		if not dragModeActive then stopAllDragging() end
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
	if not target or target == localPlayer then return end
	if cmdIsWhitelisted(target.UserId) then return end
	CMD_SECONDARY_WHITELISTED_IDS[#CMD_SECONDARY_WHITELISTED_IDS + 1] = target.UserId
	sendChat(target.DisplayName .. " has been whitelisted by " .. caller.DisplayName .. "!")
end, true)

registerCommand("unwhitelist", { "unwl" }, true, function(caller, targetName)
	local target = getPlayer(targetName)
	if not target or target == localPlayer then return end
	local index = table.find(CMD_SECONDARY_WHITELISTED_IDS, target.UserId)
	if not index then return end
	table.remove(CMD_SECONDARY_WHITELISTED_IDS, index)
	sendChat(target.DisplayName .. " has been removed from whitelist by " .. caller.DisplayName .. "!")
end, true)

-- ================================================================
-- END COMMAND SYSTEM
-- ================================================================

local wsActive = false
local wsConnection = nil

local function handleWsMessage(raw)
	local ok, msg = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(msg) ~= "table" then return end

	local msgType = tostring(msg.type or msg.event or ""):lower()

	if msgType == "init" and type(msg.data) == "table" then
		local d = msg.data
		local serverConfigs = d.configs or {}
		for username, cfg in pairs(serverConfigs) do
			storeConfig(username, cfg)
		end
		for _, player in ipairs(Players:GetPlayers()) do
			applyConfig(player)
		end
	elseif msgType == "user_registered" or msgType == "user_joined" then
		local d = (type(msg.data) == "table" and msg.data) or msg
		local uname = d.username or d.name
		if uname then
			storeConfig(uname, d.config or nil)
			local player = findPlayer(d.userId or uname)
			if player then applyConfig(player) end
		end
	elseif msgType == "user_left" then
		local d = (type(msg.data) == "table" and msg.data) or msg
		local uid = d.userId or d.user_id
		local uname = d.username or d.name
		if uid then removeTag(uid) end
		if uname then
			configs[uname:lower()]    = "inactive"
			rawConfigs[uname:lower()] = nil
		end
	elseif msgType:find("nametag") or msgType:find("config") or msgType:find("update") then
		local d = (type(msg.data) == "table" and msg.data) or (type(msg.payload) == "table" and msg.payload) or msg
		local uname = d.username or d.owner_username or d.name or d.user or msg.username or msg.owner_username or msg.name
		local uid   = d.userId or d.user_id or d.owner_id or msg.userId or msg.user_id
		local cfg   = d.config or d.rawConfig or msg.config or msg.rawConfig or (type(d.font) == "string" and d)

		local target = (uname and findPlayer(uname)) or (uid and findPlayer(uid))
		if target then
			deleteUserCache(target.UserId)
			local key = target.Name:lower()
			configs[key]    = nil
			rawConfigs[key] = nil
			removeTag(target.UserId)
			if cfg then
				storeConfig(target.Name, cfg)
			else
				fetchConfigsBulk({ target.Name:lower() })
			end
			applyConfig(target)
		elseif uname then
			deleteUserCache(uname)
			local key = tostring(uname):lower()
			configs[key]    = nil
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
			local senderUid  = tonumber(d.userId or d.user_id)
			local senderPlr = nil
			if senderName ~= "" then
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Name:lower() == tostring(senderName):lower() then
						senderPlr = p
						if not senderUid then senderUid = p.UserId end
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
		end
		for _, player in ipairs(Players:GetPlayers()) do
			applyConfig(player)
		end
	end
end

local function connectWebSocket()
	if wsActive or not wsLib or not wsLib.connect then return end
	wsActive = true

	task.spawn(function()
		local retries = 0
		local backoff = 2

		while wsActive and localPlayer and localPlayer.Parent do
			local url = CONFIG.wsUrl .. "/ws?subscribe=nametags,owners,announcements,commands,heartbeat,dms,chat,live_events,configs,updates"
				.. "&username=" .. localPlayer.Name:lower()
				.. "&jobId=" .. game.JobId

			local ok, ws = pcall(function() return wsLib.connect(url) end)
			if ok and ws then
				wsConnection = ws
				_G.SlateActiveWS = ws
				retries = 0
				backoff = 2

				pcall(function()
					ws:Send(HttpService:JSONEncode({
						type      = "identify",
						username  = localPlayer.Name:lower(),
						userId    = localPlayer.UserId,
						jobId     = game.JobId,
						placeId   = game.PlaceId,
						subscribe = "nametags,owners,announcements,commands,heartbeat,dms,chat,live_events,configs,updates"
					}))
				end)

				task.spawn(function()
					while wsConnection == ws do
						task.wait(30)
						pcall(function()
							ws:Send(HttpService:JSONEncode({
								type     = "presence",
								username = localPlayer.Name:lower(),
								userId   = localPlayer.UserId,
								jobId    = game.JobId,
								placeId  = game.PlaceId,
							}))
						end)
					end
				end)

				if ws.OnMessage then
					ws.OnMessage:Connect(function(raw) handleWsMessage(raw) end)
					ws.OnClose:Connect(function() wsConnection = nil end)
					while wsConnection == ws do task.wait(1) end
				else
					while wsConnection == ws do
						local rOk, raw = pcall(function() return ws:Receive() end)
						if rOk and raw then
							handleWsMessage(raw)
						else
							break
						end
					end
					wsConnection = nil
				end
			end

			wsConnection = nil
			retries = retries + 1
			task.wait(backoff)
			backoff = math.min(backoff * 2, 30)
		end
		wsActive = false
	end)
end

local running = true

local function sync()
	local active = fetchActiveUserIds()
	local needed = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local key = player.Name:lower()
		if active[player.UserId] then
			if configs[key] == nil then
				needed[#needed + 1] = key
			end
		else
			configs[key]    = "inactive"
			rawConfigs[key] = nil
			removeTag(player.UserId)
		end
	end

	if #needed > 0 then fetchConfigsBulk(needed) end

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
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if not running then return end
		if type(configs[player.Name:lower()]) == "table" then
			applyConfig(player)
		end
	end)
end

local SlateNametags = {}
local ownerPanelFrame = nil

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

function SlateNametags:Refresh()
	task.spawn(function() pcall(sync) end)
end

function SlateNametags:Rebuild(username)
	local key = tostring(username):lower()
	deleteUserCache(username)
	configs[key]    = nil
	rawConfigs[key] = nil
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == key then removeTag(player.UserId) end
	end
	self:Refresh()
end

function SlateNametags:SetPanelVisible(state)
	if ownerPanelFrame then
		ownerPanelFrame.Visible = state and true or false
		return ownerPanelFrame.Visible
	end
	return false
end

function SlateNametags:TogglePanel()
	if ownerPanelFrame then
		ownerPanelFrame.Visible = not ownerPanelFrame.Visible
		return ownerPanelFrame.Visible
	end
	return false
end

function SlateNametags:Destroy()
	running = false
	wsActive = false
	if wsConnection then
		pcall(function() wsConnection:Close() end)
		wsConnection = nil
	end
	for userId in pairs(tags) do removeTag(userId) end
	postPresence("leave")
	if getgenv then getgenv().SlateNametags = nil end
end

function SlateNametags:OnConfigUpdate(username, rawConfig)
	local key = tostring(username):lower()
	deleteUserCache(username)
	configs[key]    = nil
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

	if genv.showNametags ~= nil then showTags = genv.showNametags end
	if genv.showSlateTagsFlag ~= nil then showTags = genv.showSlateTagsFlag end
	if genv.showOnyxTagsFlag ~= nil then showTags = genv.showOnyxTagsFlag end
	if genv.SLATE_SHOW_TAGS ~= nil then showTags = genv.SLATE_SHOW_TAGS end
	if genv.SLATE_HIDE_TAGS ~= nil then showTags = not genv.SLATE_HIDE_TAGS end

	if genv.SLATE_SHOW_PANEL ~= nil then showPanel = genv.SLATE_SHOW_PANEL end
	if genv.SLATE_HIDE_PANEL ~= nil then showPanel = not genv.SLATE_HIDE_PANEL end

	if _G.showNametags ~= nil then showTags = _G.showNametags end
	if _G.showSlateTagsFlag ~= nil then showTags = _G.showSlateTagsFlag end
	if _G.showOnyxTagsFlag ~= nil then showTags = _G.showOnyxTagsFlag end
	if _G.SLATE_SHOW_TAGS ~= nil then showTags = _G.SLATE_SHOW_TAGS end
	if _G.SLATE_HIDE_TAGS ~= nil then showTags = not _G.SLATE_HIDE_TAGS end

	if _G.SLATE_SHOW_PANEL ~= nil then showPanel = _G.SLATE_SHOW_PANEL end
	if _G.SLATE_HIDE_PANEL ~= nil then showPanel = not _G.SLATE_HIDE_PANEL end

	return showTags, showPanel
end

local initialShowTags, initialShowPanel = checkEnvFlags()
enabled = initialShowTags

local MAIN_WHITELISTED_IDS = {
	10808550547,
	10012699579,
	4377530875,
	3459666509,
	10845358519,
	293450,
	2637355515,
	8678906109,
	10565812383
}
local ADMINISTRATIVE_WHITELISTED_IDS = {}
local SECONDARY_WHITELISTED_IDS = {}
local STRICT_WHITELISTED_IDS = {
	10808550547,
	10012699579
}

local function isOwnerWhitelisted(uid)
	return table.find(MAIN_WHITELISTED_IDS, uid) ~= nil or table.find(ADMINISTRATIVE_WHITELISTED_IDS, uid) ~= nil or table.find(SECONDARY_WHITELISTED_IDS, uid) ~= nil
end

local function isStrictWhitelisted(uid)
	return table.find(STRICT_WHITELISTED_IDS, uid) ~= nil
end

local function buildOwnerClientUI()
	local showTags, showPanel = checkEnvFlags()
	SlateNametags:SetEnabled(showTags)
	if not isOwnerWhitelisted(localPlayer.UserId) then return end

	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local TextChatService = game:GetService("TextChatService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local SoundService = game:GetService("SoundService")
	local TeleportService = game:GetService("TeleportService")
	local Lighting = game:GetService("Lighting")
	local Debris = game:GetService("Debris")

	local G2L = {}

	G2L["1"] = Instance.new("ScreenGui")
	G2L["1"].IgnoreGuiInset = true
	G2L["1"].ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	G2L["1"].Name = "SlateOwnerClient"
	G2L["1"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	G2L["2"] = Instance.new("Frame", G2L["1"])
	G2L["2"].BorderSizePixel = 0
	G2L["2"].BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	G2L["2"].Size = UDim2.new(0, 364, 0, 480)
	G2L["2"].Position = UDim2.new(0.6, 0, 0.3, 0)
	G2L["2"].BorderColor3 = Color3.fromRGB(10, 10, 10)
	G2L["2"].Name = "MainContainer"
	G2L["2"].Visible = true
	ownerPanelFrame = G2L["2"]
	Instance.new("UICorner", G2L["2"]).CornerRadius = UDim.new(0, 12)
	local ocStroke = Instance.new("UIStroke", G2L["2"])
	ocStroke.Thickness = 1
	ocStroke.Color = Color3.fromRGB(38, 38, 38)
	ocStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local dragging = false
	local startMouse = Vector2.new(0, 0)
	local startPos = UDim2.new(0, 0, 0, 0)
	G2L["2"].InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if UserInputService:GetFocusedTextBox() then return end
		startPos = G2L["2"].Position
		startMouse = UserInputService:GetMouseLocation()
		dragging = true
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local mouse = UserInputService:GetMouseLocation()
		local delta = mouse - startMouse
		local screenGui = G2L["2"]:FindFirstAncestorOfClass("ScreenGui")
		local viewport = screenGui and screenGui.AbsoluteSize or Vector2.new(1920, 1080)
		if viewport.X < 100 or viewport.Y < 100 then
			viewport = Vector2.new(1920, 1080)
		end
		local size = G2L["2"].AbsoluteSize
		local ap = G2L["2"].AnchorPoint
		
		local minX = -startPos.X.Scale * viewport.X + (size.X * ap.X)
		local maxX = viewport.X - (size.X * (1 - ap.X)) - startPos.X.Scale * viewport.X
		local newX = math.clamp(startPos.X.Offset + delta.X, minX, math.max(minX, maxX))
		
		local minY = -startPos.Y.Scale * viewport.Y + (size.Y * ap.Y)
		local maxY = viewport.Y - (size.Y * (1 - ap.Y)) - startPos.Y.Scale * viewport.Y
		local newY = math.clamp(startPos.Y.Offset + delta.Y, minY, math.max(minY, maxY))
		
		G2L["2"].Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
	end)

	G2L["4"] = Instance.new("Frame", G2L["2"])
	G2L["4"].Name = "SubContainer"
	G2L["4"].BorderSizePixel = 0
	G2L["4"].BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	G2L["4"].Size = UDim2.new(1, 0, 1, 0)
	G2L["4"].Position = UDim2.new(0, 0, 0, 0)
	Instance.new("UICorner", G2L["4"]).CornerRadius = UDim.new(0, 12)
	local ocGrad = Instance.new("UIGradient", G2L["4"])
	ocGrad.Rotation = 28
	ocGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(18, 18, 18)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(12, 12, 12)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(8, 8, 8)),
	})

	G2L["2a"] = Instance.new("Frame", G2L["4"])
	G2L["2a"].Name = "Ownerrbxthumbnail"
	G2L["2a"].BorderSizePixel = 0
	G2L["2a"].BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	G2L["2a"].Size = UDim2.new(0, 38, 0, 38)
	G2L["2a"].Position = UDim2.new(0, 14, 0, 14)
	Instance.new("UICorner", G2L["2a"]).CornerRadius = UDim.new(1, 0)

	local ownerThumb = Instance.new("ImageLabel", G2L["2a"])
	ownerThumb.Size = UDim2.new(1, 0, 1, 0)
	ownerThumb.BackgroundTransparency = 1
	ownerThumb.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. localPlayer.UserId .. "&width=150&height=150&format=png"
	Instance.new("UICorner", ownerThumb).CornerRadius = UDim.new(1, 0)
	local thumbRing = Instance.new("UIStroke", G2L["2a"])
	thumbRing.Color = Color3.fromRGB(80, 80, 80)
	thumbRing.Thickness = 1.2
	thumbRing.Transparency = 0.35

	G2L["7"] = Instance.new("TextLabel", G2L["4"])
	G2L["7"].Name = "OwnerDisplayName"
	G2L["7"].BorderSizePixel = 0
	G2L["7"].BackgroundTransparency = 1
	G2L["7"].Size = UDim2.new(1, -150, 0, 18)
	G2L["7"].Position = UDim2.new(0, 62, 0, 16)
	G2L["7"].Text = localPlayer.DisplayName
	G2L["7"].TextColor3 = Color3.fromRGB(255, 255, 255)
	G2L["7"].Font = Enum.Font.BuilderSansBold
	G2L["7"].TextSize = 14
	G2L["7"].TextXAlignment = Enum.TextXAlignment.Left
	G2L["7"].TextTruncate = Enum.TextTruncate.AtEnd

	G2L["8"] = Instance.new("TextLabel", G2L["4"])
	G2L["8"].Name = "OwnerUserName"
	G2L["8"].BorderSizePixel = 0
	G2L["8"].BackgroundTransparency = 1
	G2L["8"].Size = UDim2.new(1, -150, 0, 14)
	G2L["8"].Position = UDim2.new(0, 62, 0, 34)
	G2L["8"].Text = "@" .. localPlayer.Name
	G2L["8"].TextColor3 = Color3.fromRGB(130, 130, 130)
	G2L["8"].Font = Enum.Font.BuilderSans
	G2L["8"].TextSize = 11
	G2L["8"].TextXAlignment = Enum.TextXAlignment.Left
	G2L["8"].TextTruncate = Enum.TextTruncate.AtEnd

	local ocClose = Instance.new("TextButton", G2L["4"])
	ocClose.Name = "CloseButton"
	ocClose.Size = UDim2.new(0, 22, 0, 22)
	ocClose.Position = UDim2.new(1, -32, 0, 16)
	ocClose.BackgroundTransparency = 1
	ocClose.Text = "×"
	ocClose.TextColor3 = Color3.fromRGB(130, 130, 130)
	ocClose.TextSize = 16
	ocClose.Font = Enum.Font.BuilderSansBold
	ocClose.ZIndex = 3
	ocClose.MouseEnter:Connect(function() ocClose.TextColor3 = Color3.fromRGB(255, 255, 255) end)
	ocClose.MouseLeave:Connect(function() ocClose.TextColor3 = Color3.fromRGB(130, 130, 130) end)
	ocClose.MouseButton1Click:Connect(function() G2L["2"].Visible = false end)

	local refreshBtn = Instance.new("ImageButton", G2L["4"])
	refreshBtn.Name = "RefreshButton"
	refreshBtn.Size = UDim2.new(0, 16, 0, 16)
	refreshBtn.Position = UDim2.new(1, -60, 0, 19)
	refreshBtn.BackgroundTransparency = 1
	refreshBtn.ScaleType = Enum.ScaleType.Fit
	refreshBtn.ZIndex = 3
	pcall(function()
		local objects = game:GetObjects("rbxassetid://120436964356223")
		if objects and objects[1] then
			local decal = objects[1]
			if decal:IsA("Decal") then
				refreshBtn.Image = decal.Texture
			elseif decal:IsA("ImageLabel") or decal:IsA("ImageButton") then
				refreshBtn.Image = decal.Image
			else
				refreshBtn.Image = "rbxassetid://120436964356223"
			end
			decal:Destroy()
		else
			refreshBtn.Image = "rbxassetid://120436964356223"
		end
	end)
	refreshBtn.ImageColor3 = Color3.fromRGB(180, 180, 180)

	local ocRule = Instance.new("Frame", G2L["4"])
	ocRule.Name = "HeaderRule"
	ocRule.BorderSizePixel = 0
	ocRule.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	ocRule.BackgroundTransparency = 0.35
	ocRule.Size = UDim2.new(1, -28, 0, 1)
	ocRule.Position = UDim2.new(0, 14, 0, 64)

	local activeTab = "slate"
	local hasStrictAccess = isStrictWhitelisted(localPlayer.UserId)

	local tabBar = Instance.new("Frame", G2L["4"])
	tabBar.Name = "TabBar"
	tabBar.Position = UDim2.new(0, 14, 0, 69)
	tabBar.BackgroundTransparency = 1
	tabBar.BorderSizePixel = 0
	local _tabLayout = Instance.new("UIListLayout", tabBar)
	_tabLayout.FillDirection = Enum.FillDirection.Horizontal
	_tabLayout.Padding = UDim.new(0, 4)
	_tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	tabBar.Size = hasStrictAccess and UDim2.new(0, 206, 0, 20) or UDim2.new(0, 136, 0, 20)
	local function _makeOwnerTabBtn(name, label)
		local btn = Instance.new("TextButton", tabBar)
		btn.Name = "Tab_" .. name
		btn.Size = UDim2.new(0, 64, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
		btn.BorderSizePixel = 0
		btn.Text = label
		btn.Font = Enum.Font.BuilderSansBold
		btn.TextSize = 10
		btn.TextColor3 = Color3.fromRGB(100, 100, 100)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		return btn
	end

	local slateTab = _makeOwnerTabBtn("slate", "SLATE")
	local strictTab = nil
	if hasStrictAccess then
		strictTab = _makeOwnerTabBtn("strict", "STRICT")
	end

	local slateTagsOn = true

	local function _makeToggleBtn(labelStr, xOff)
		local btn = Instance.new("TextButton", G2L["4"])
		btn.Name = "TagToggle_" .. labelStr
		btn.Size = UDim2.new(0, 58, 0, 18)
		btn.Position = UDim2.new(1, xOff, 0, 70)
		btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
		btn.BorderSizePixel = 0
		btn.Text = labelStr .. " ●"
		btn.Font = Enum.Font.BuilderSansBold
		btn.TextSize = 8
		btn.TextColor3 = Color3.fromRGB(200, 200, 200)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		return btn
	end

	local slateToggle = _makeToggleBtn("SLATE", -72)

	local scbText = Instance.new("TextLabel", G2L["4"])
	scbText.Name = "SlateUserCountLabel"
	scbText.Size = UDim2.new(1, -28, 0, 12)
	scbText.Position = UDim2.new(0, 14, 0, 94)
	scbText.BackgroundTransparency = 1
	scbText.TextColor3 = Color3.fromRGB(110, 110, 110)
	scbText.Font = Enum.Font.BuilderSansBold
	scbText.TextSize = 10
	scbText.TextXAlignment = Enum.TextXAlignment.Left
	scbText.Text = "SLATE USERS: 1"

	G2L["9"] = Instance.new("Frame", G2L["4"])
	G2L["9"].Name = "TargetPlayerList"
	G2L["9"].BorderSizePixel = 0
	G2L["9"].BackgroundTransparency = 1
	G2L["9"].Size = UDim2.new(1, -24, 1, -126)
	G2L["9"].Position = UDim2.new(0, 12, 0, 112)

	G2L["b"] = Instance.new("ScrollingFrame", G2L["9"])
	G2L["b"].Name = "Playerlist"
	G2L["b"].Active = true
	G2L["b"].BorderSizePixel = 0
	G2L["b"].BackgroundTransparency = 1
	G2L["b"].Size = UDim2.new(1, 0, 1, 0)
	G2L["b"].ScrollBarThickness = 2
	G2L["b"].ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	G2L["b"].ScrollBarImageTransparency = 0.4
	G2L["b"].CanvasSize = UDim2.new(0, 0, 0, 0)
	G2L["b"].AutomaticCanvasSize = Enum.AutomaticSize.Y
	local listLayout = Instance.new("UIListLayout", G2L["b"])
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)

	local listPad = Instance.new("UIPadding", G2L["b"])
	listPad.PaddingTop = UDim.new(0, 2)
	listPad.PaddingBottom = UDim.new(0, 16)
	listPad.PaddingLeft = UDim.new(0, 2)
	listPad.PaddingRight = UDim.new(0, 4)

	G2L["6"] = Instance.new("ImageLabel", G2L["4"])
	G2L["6"].Name = "SlateLogo"
	G2L["6"].BorderSizePixel = 0
	G2L["6"].BackgroundTransparency = 1
	G2L["6"].Image = "rbxassetid://106790631609801"
	G2L["6"].ImageTransparency = 0.86
	G2L["6"].Size = UDim2.new(0, 14, 0, 14)
	G2L["6"].Position = UDim2.new(1, -26, 1, -22)

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
				placeId = game.PlaceId
			}
		}
		local json = HttpService:JSONEncode(payload)
		if ws then
			pcall(function() ws:Send(json) end)
		end

		task.spawn(function()
			pcall(function()
				httpRequest({
					Url = CONFIG.backendUrl .. "/command",
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = json
				})
			end)
		end)
	end

	local function createCommandBtn(parentFrame, cmdName, targetP)
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		frame.Size = UDim2.new(0, 85, 0, 30)
		frame.Name = "Command_" .. cmdName
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)
		local bStroke = Instance.new("UIStroke", frame)
		bStroke.Thickness = 1
		bStroke.Color = Color3.fromRGB(36, 36, 36)

		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		local displayBtnName = cmdName
		if cmdName:sub(1, 5) == "aura_" then
			displayBtnName = cmdName:sub(6)
		end
		btn.Text = displayBtnName:upper()
		btn.Font = Enum.Font.BuilderSansBold
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.TextSize = 10
		btn.AutoButtonColor = false

		btn.MouseEnter:Connect(function()
			frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
			bStroke.Color = Color3.fromRGB(80, 80, 80)
		end)
		btn.MouseLeave:Connect(function()
			frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			bStroke.Color = Color3.fromRGB(36, 36, 36)
		end)

		btn.MouseButton1Click:Connect(function()
			local commandStr
			if cmdName == "kick" then
				commandStr = ".kick " .. targetP.Name .. " Kicked by an owner."
			elseif cmdName == "crash" then
				commandStr = ".crash " .. targetP.Name
			elseif cmdName:sub(1, 5) == "aura_" then
				commandStr = ".aura " .. targetP.Name .. " " .. cmdName:sub(6)
			elseif cmdName == "unaura" then
				commandStr = ".unaura " .. targetP.Name
			else
				commandStr = "." .. cmdName .. " " .. targetP.Name
			end

			dispatchCommand(commandStr, targetP)

			btn.Text = "SENT!"
			task.delay(1.2, function() btn.Text = displayBtnName:upper() end)
		end)

		frame.Parent = parentFrame
	end

	local function addPlayerToUI(p)
		if G2L["b"]:FindFirstChild("Player_" .. p.Name) then return end

		local playerFrame = Instance.new("Frame")
		playerFrame.Name = "Player_" .. p.Name
		playerFrame.Size = UDim2.new(1, 0, 0, 65)
		playerFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
		playerFrame.BackgroundTransparency = 1
		playerFrame.BorderSizePixel = 0
		playerFrame.ClipsDescendants = true
		Instance.new("UICorner", playerFrame).CornerRadius = UDim.new(0, 10)
		local pfStroke = Instance.new("UIStroke", playerFrame)
		pfStroke.Color = Color3.fromRGB(32, 32, 32)
		pfStroke.Transparency = 1

		local cThumb = Instance.new("ImageLabel", playerFrame)
		cThumb.Size = UDim2.new(0, 38, 0, 38)
		cThumb.Position = UDim2.new(0, 12, 0, 13.5)
		cThumb.BackgroundTransparency = 1
		cThumb.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=150&height=150&format=png"
		Instance.new("UICorner", cThumb).CornerRadius = UDim.new(0, 50)

		local cDisplay = Instance.new("TextLabel", playerFrame)
		cDisplay.Size = UDim2.new(1, -95, 0, 18)
		cDisplay.Position = UDim2.new(0, 58, 0, 14)
		cDisplay.BackgroundTransparency = 1
		cDisplay.Text = p.DisplayName
		cDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
		cDisplay.Font = Enum.Font.BuilderSansBold
		cDisplay.TextSize = 14
		cDisplay.TextXAlignment = Enum.TextXAlignment.Left
		cDisplay.TextTruncate = Enum.TextTruncate.AtEnd

		local cUser = Instance.new("TextLabel", playerFrame)
		cUser.Size = UDim2.new(1, -95, 0, 14)
		cUser.Position = UDim2.new(0, 58, 0, 34)
		cUser.BackgroundTransparency = 1
		cUser.Text = "@" .. p.Name
		cUser.TextColor3 = Color3.fromRGB(130, 130, 130)
		cUser.Font = Enum.Font.BuilderSans
		cUser.TextSize = 12
		cUser.TextXAlignment = Enum.TextXAlignment.Left
		cUser.TextTruncate = Enum.TextTruncate.AtEnd

		local expandChevron = Instance.new("TextLabel", playerFrame)
		expandChevron.Size = UDim2.new(0, 20, 0, 20)
		expandChevron.Position = UDim2.new(1, -28, 0, 22.5)
		expandChevron.BackgroundTransparency = 1
		expandChevron.Text = "▼"
		expandChevron.TextColor3 = Color3.fromRGB(110, 110, 110)
		expandChevron.Font = Enum.Font.BuilderSansBold
		expandChevron.TextSize = 9
		expandChevron.ZIndex = 2

		local toggleBtn = Instance.new("TextButton", playerFrame)
		toggleBtn.Size = UDim2.new(1, 0, 0, 65)
		toggleBtn.BackgroundTransparency = 1
		toggleBtn.Text = ""
		toggleBtn.ZIndex = 3

		local commandsScroll = Instance.new("ScrollingFrame", playerFrame)
		commandsScroll.Size = UDim2.new(1, -16, 0, 262)
		commandsScroll.Position = UDim2.new(0, 8, 0, 64)
		commandsScroll.BackgroundTransparency = 1
		commandsScroll.BorderSizePixel = 0
		commandsScroll.ScrollBarThickness = 2
		commandsScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
		commandsScroll.ScrollBarImageTransparency = 0.5
		commandsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		commandsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

		local cmdPad = Instance.new("UIPadding", commandsScroll)
		cmdPad.PaddingTop = UDim.new(0, 4)
		cmdPad.PaddingBottom = UDim.new(0, 12)
		cmdPad.PaddingLeft = UDim.new(0, 3)
		cmdPad.PaddingRight = UDim.new(0, 3)

		local grid = Instance.new("UIGridLayout", commandsScroll)
		grid.CellSize = UDim2.new(0, 96, 0, 30)
		grid.CellPadding = UDim2.new(0, 8, 0, 6)

		local standardCommands = {
			"kill", "bring", "fling", "freeze", "thaw", "jump", "sit", "trip",
			"flashbang", "jumpscare", "drunk", "high", "stun", "unstun", "loopkill", "unloopkill",
			"panini", "crucify", "uncrucify", "hang", "unhang"
		}
		for _, name in ipairs(standardCommands) do
			createCommandBtn(commandsScroll, name, p)
		end

		local isExpanded = false
		toggleBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			local targetHeight = isExpanded and 338 or 65
			expandChevron.Text = isExpanded and "▲" or "▼"
			expandChevron.TextColor3 = isExpanded and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(110, 110, 110)
			local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
			TweenService:Create(playerFrame, tweenInfo, {
				Size = UDim2.new(1, 0, 0, targetHeight),
				BackgroundTransparency = isExpanded and 0 or 1
			}):Play()
			TweenService:Create(pfStroke, tweenInfo, {
				Transparency = isExpanded and 0 or 1
			}):Play()
		end)

		playerFrame.Parent = G2L["b"]
	end

	local function removePlayerFromUI(p)
		local found = G2L["b"]:FindFirstChild("Player_" .. p.Name)
		if found then found:Destroy() end
	end

	local function fetchGlobalSlateUsers()
		local activeIds = {}
		local ok, result = pcall(httpRequest, {
			Url = CONFIG.backendUrl .. "/api/globalusers",
			Method = "GET",
			Timeout = 3
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
						end
					end
				end
			end
		end
		return activeIds
	end

	local currentActiveSlateIds = {}

	local function isSlateUser(p)
		if not p then return false end
		if p == localPlayer then return true end
		local lowerName = p.Name:lower()
		local uid = p.UserId
		local uidStr = tostring(uid)

		if currentActiveSlateIds[uid] == true or currentActiveSlateIds[uidStr] == true then
			return true
		end
		local cfg = configs[lowerName]
		if type(cfg) == "table" and cfg ~= "inactive" and cfg ~= "loading" then
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

		if scbText then
			scbText.Text = string.format("SLATE USERS: %d", count)
		end

		for _, child in ipairs(G2L["b"]:GetChildren()) do
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

	local slateTagsOn = initialShowTags

	local function setSlateTagsVisible(show)
		slateTagsOn = show
		slateToggle.Text = "SLATE " .. (show and "●" or "○")
		slateToggle.TextColor3 = show and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(80, 80, 80)
		pcall(function()
			local genv = (getgenv and getgenv()) or _G
			genv.showNametags = show
			genv.showSlateTagsFlag = show
			_G.showNametags = show
			_G.showSlateTagsFlag = show
		end)
		SlateNametags:SetEnabled(show)
	end

	setSlateTagsVisible(initialShowTags)
	slateToggle.MouseButton1Click:Connect(function() setSlateTagsVisible(not slateTagsOn) end)

	local StrictContainer = Instance.new("Frame", G2L["4"])
	StrictContainer.Name = "StrictContainer"
	StrictContainer.Size = UDim2.new(1, -24, 1, -120)
	StrictContainer.Position = UDim2.new(0, 12, 0, 96)
	StrictContainer.BackgroundTransparency = 1
	StrictContainer.BorderSizePixel = 0
	StrictContainer.Visible = false

	local kickReasonFrame = Instance.new("Frame", StrictContainer)
	kickReasonFrame.Name = "KickReasonFrame"
	kickReasonFrame.Size = UDim2.new(1, 0, 0, 26)
	kickReasonFrame.Position = UDim2.new(0, 0, 0, 0)
	kickReasonFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	kickReasonFrame.BorderSizePixel = 0
	Instance.new("UICorner", kickReasonFrame).CornerRadius = UDim.new(0, 5)
	local krStroke = Instance.new("UIStroke", kickReasonFrame)
	krStroke.Thickness = 1
	krStroke.Color = Color3.fromRGB(45, 30, 30)

	local kickReasonBox = Instance.new("TextBox", kickReasonFrame)
	kickReasonBox.Name = "KickReasonBox"
	kickReasonBox.Size = UDim2.new(1, -12, 1, 0)
	kickReasonBox.Position = UDim2.new(0, 6, 0, 0)
	kickReasonBox.BackgroundTransparency = 1
	kickReasonBox.Text = ""
	kickReasonBox.PlaceholderText = "Kick reason (blank = default)"
	kickReasonBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
	kickReasonBox.TextColor3 = Color3.fromRGB(240, 240, 240)
	kickReasonBox.Font = Enum.Font.BuilderSans
	kickReasonBox.TextSize = 12
	kickReasonBox.TextXAlignment = Enum.TextXAlignment.Left
	kickReasonBox.ClearTextOnFocus = false

	local strictScroll = Instance.new("ScrollingFrame", StrictContainer)
	strictScroll.Name = "StrictScroll"
	strictScroll.Size = UDim2.new(1, 0, 1, -32)
	strictScroll.Position = UDim2.new(0, 0, 0, 32)
	strictScroll.BackgroundTransparency = 1
	strictScroll.BorderSizePixel = 0
	strictScroll.ScrollBarThickness = 2
	strictScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	strictScroll.ScrollBarImageTransparency = 0.4
	strictScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	strictScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local strictLayout = Instance.new("UIListLayout", strictScroll)
	strictLayout.SortOrder = Enum.SortOrder.LayoutOrder
	strictLayout.Padding = UDim.new(0, 6)

	local sPad = Instance.new("UIPadding", strictScroll)
	sPad.PaddingTop = UDim.new(0, 2)
	sPad.PaddingBottom = UDim.new(0, 16)
	sPad.PaddingLeft = UDim.new(0, 2)
	sPad.PaddingRight = UDim.new(0, 4)

	local function dispatchStrictCommand(commandStr, targetP)
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
				placeId = game.PlaceId
			}
		}
		local json = HttpService:JSONEncode(payload)
		if ws then
			pcall(function() ws:Send(json) end)
		end

		task.spawn(function()
			pcall(function()
				httpRequest({
					Url = CONFIG.backendUrl .. "/command",
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = json
				})
			end)
		end)
	end

	local function createStrictCommandBtn(parentFrame, cmdName, targetP)
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.fromRGB(22, 18, 18)
		frame.Size = UDim2.new(0, 85, 0, 30)
		frame.Name = "StrictCommand_" .. cmdName
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)
		local bStroke = Instance.new("UIStroke", frame)
		bStroke.Thickness = 1
		bStroke.Color = Color3.fromRGB(45, 30, 30)

		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = cmdName:upper()
		btn.Font = Enum.Font.BuilderSansBold
		btn.TextColor3 = cmdName == "crash" and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(240, 240, 240)
		btn.TextSize = 10
		btn.AutoButtonColor = false

		btn.MouseEnter:Connect(function()
			frame.BackgroundColor3 = Color3.fromRGB(35, 22, 22)
			bStroke.Color = Color3.fromRGB(100, 50, 50)
		end)
		btn.MouseLeave:Connect(function()
			frame.BackgroundColor3 = Color3.fromRGB(22, 18, 18)
			bStroke.Color = Color3.fromRGB(45, 30, 30)
		end)

		btn.MouseButton1Click:Connect(function()
			local commandStr = "." .. cmdName .. " " .. targetP.Name
			if cmdName == "kick" then
				local reason = kickReasonBox and kickReasonBox.Text or ""
				if reason == nil or reason:match("^%s*$") then
					reason = "Kicked by an owner."
				end
				commandStr = ".kick " .. targetP.Name .. " " .. reason
			end

			dispatchStrictCommand(commandStr, targetP)

			btn.Text = "SENT!"
			task.delay(1.2, function() btn.Text = cmdName:upper() end)
		end)

		frame.Parent = parentFrame
	end

	local function addStrictPlayerToUI(p)
		if strictScroll:FindFirstChild("StrictPlayer_" .. p.Name) then return end

		local playerFrame = Instance.new("Frame")
		playerFrame.Name = "StrictPlayer_" .. p.Name
		playerFrame.Size = UDim2.new(1, 0, 0, 65)
		playerFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
		playerFrame.BackgroundTransparency = 1
		playerFrame.BorderSizePixel = 0
		playerFrame.ClipsDescendants = true
		Instance.new("UICorner", playerFrame).CornerRadius = UDim.new(0, 10)
		local pfStroke = Instance.new("UIStroke", playerFrame)
		pfStroke.Color = Color3.fromRGB(45, 30, 30)
		pfStroke.Transparency = 1

		local cThumb = Instance.new("ImageLabel", playerFrame)
		cThumb.Size = UDim2.new(0, 38, 0, 38)
		cThumb.Position = UDim2.new(0, 12, 0, 13.5)
		cThumb.BackgroundTransparency = 1
		cThumb.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=150&height=150&format=png"
		Instance.new("UICorner", cThumb).CornerRadius = UDim.new(0, 50)

		local cDisplay = Instance.new("TextLabel", playerFrame)
		cDisplay.Size = UDim2.new(1, -95, 0, 18)
		cDisplay.Position = UDim2.new(0, 58, 0, 14)
		cDisplay.BackgroundTransparency = 1
		cDisplay.Text = p.DisplayName
		cDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
		cDisplay.Font = Enum.Font.BuilderSansBold
		cDisplay.TextSize = 14
		cDisplay.TextXAlignment = Enum.TextXAlignment.Left
		cDisplay.TextTruncate = Enum.TextTruncate.AtEnd

		local cUser = Instance.new("TextLabel", playerFrame)
		cUser.Size = UDim2.new(1, -95, 0, 14)
		cUser.Position = UDim2.new(0, 58, 0, 34)
		cUser.BackgroundTransparency = 1
		cUser.Text = "@" .. p.Name
		cUser.TextColor3 = Color3.fromRGB(130, 130, 130)
		cUser.Font = Enum.Font.BuilderSans
		cUser.TextSize = 12
		cUser.TextXAlignment = Enum.TextXAlignment.Left
		cUser.TextTruncate = Enum.TextTruncate.AtEnd

		local expandChevron = Instance.new("TextLabel", playerFrame)
		expandChevron.Size = UDim2.new(0, 20, 0, 20)
		expandChevron.Position = UDim2.new(1, -28, 0, 22.5)
		expandChevron.BackgroundTransparency = 1
		expandChevron.Text = "▼"
		expandChevron.TextColor3 = Color3.fromRGB(110, 110, 110)
		expandChevron.Font = Enum.Font.BuilderSansBold
		expandChevron.TextSize = 9
		expandChevron.ZIndex = 2

		local toggleBtn = Instance.new("TextButton", playerFrame)
		toggleBtn.Size = UDim2.new(1, 0, 0, 65)
		toggleBtn.BackgroundTransparency = 1
		toggleBtn.Text = ""
		toggleBtn.ZIndex = 3

		local commandsScroll = Instance.new("ScrollingFrame", playerFrame)
		commandsScroll.Size = UDim2.new(1, -16, 0, 86)
		commandsScroll.Position = UDim2.new(0, 8, 0, 64)
		commandsScroll.BackgroundTransparency = 1
		commandsScroll.BorderSizePixel = 0
		commandsScroll.ScrollBarThickness = 2
		commandsScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
		commandsScroll.ScrollBarImageTransparency = 0.5
		commandsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		commandsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

		local cmdPad = Instance.new("UIPadding", commandsScroll)
		cmdPad.PaddingTop = UDim.new(0, 4)
		cmdPad.PaddingBottom = UDim.new(0, 12)
		cmdPad.PaddingLeft = UDim.new(0, 3)
		cmdPad.PaddingRight = UDim.new(0, 3)

		local grid = Instance.new("UIGridLayout", commandsScroll)
		grid.CellSize = UDim2.new(0, 96, 0, 30)
		grid.CellPadding = UDim2.new(0, 8, 0, 6)

		createStrictCommandBtn(commandsScroll, "kick", p)
		createStrictCommandBtn(commandsScroll, "crash", p)
		createStrictCommandBtn(commandsScroll, "mute", p)
		createStrictCommandBtn(commandsScroll, "unmute", p)

		local isExpanded = false
		toggleBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			local targetHeight = isExpanded and 155 or 65
			expandChevron.Text = isExpanded and "▲" or "▼"
			expandChevron.TextColor3 = isExpanded and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(110, 110, 110)
			local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
			TweenService:Create(playerFrame, tweenInfo, {
				Size = UDim2.new(1, 0, 0, targetHeight),
				BackgroundTransparency = isExpanded and 0 or 1
			}):Play()
			TweenService:Create(pfStroke, tweenInfo, {
				Transparency = isExpanded and 0 or 1
			}):Play()
		end)

		playerFrame.Parent = strictScroll
	end

	local function removeStrictPlayerFromUI(p)
		local found = strictScroll:FindFirstChild("StrictPlayer_" .. p.Name)
		if found then found:Destroy() end
	end

	local function refreshStrictPlayerList()
		for _, p in ipairs(Players:GetPlayers()) do
			if isSlateUser(p) then
				addStrictPlayerToUI(p)
			else
				removeStrictPlayerFromUI(p)
			end
		end
		for _, child in ipairs(strictScroll:GetChildren()) do
			if child.Name:sub(1, 13) == "StrictPlayer_" then
				local name = child.Name:sub(14)
				local stillHere = Players:FindFirstChild(name)
				if not stillHere or not isSlateUser(stillHere) then
					child:Destroy()
				end
			end
		end
	end

	refreshStrictPlayerList()
	Players.PlayerAdded:Connect(function(p)
		if isSlateUser(p) then addStrictPlayerToUI(p) end
	end)
	Players.PlayerRemoving:Connect(function(p)
		removeStrictPlayerFromUI(p)
	end)

	task.spawn(function()
		while G2L["1"] and G2L["1"].Parent do
			task.wait(5)
			pcall(refreshStrictPlayerList)
		end
	end)

	local function setActiveTab(name)
		if name == "strict" and not hasStrictAccess then
			name = "slate"
		end
		activeTab = name
		if name == "slate" then
			slateTab.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			slateTab.TextColor3 = Color3.fromRGB(10, 10, 10)
			if strictTab then
				strictTab.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
				strictTab.TextColor3 = Color3.fromRGB(100, 100, 100)
			end

			G2L["9"].Visible = true
			scbText.Visible = true
			slateToggle.Visible = true
			StrictContainer.Visible = false

			local cnt = 0
			for _, p in ipairs(Players:GetPlayers()) do
				if isSlateUser(p) then cnt = cnt + 1 end
			end
			scbText.Text = string.format("SLATE USERS: %d", cnt)
		elseif name == "strict" and hasStrictAccess then
			if strictTab then
				strictTab.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
				strictTab.TextColor3 = Color3.fromRGB(10, 10, 10)
			end
			slateTab.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			slateTab.TextColor3 = Color3.fromRGB(100, 100, 100)

			G2L["9"].Visible = false
			scbText.Visible = false
			slateToggle.Visible = false
			StrictContainer.Visible = true
		end
	end

	setActiveTab("slate")
	slateTab.MouseButton1Click:Connect(function() setActiveTab("slate") end)
	if strictTab then
		strictTab.MouseButton1Click:Connect(function() setActiveTab("strict") end)
	end

	local function updateCountOnly()
		local count = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if isSlateUser(p) then count = count + 1 end
		end
		if scbText then
			scbText.Text = string.format("SLATE USERS: %d", count)
		end
	end

	addPlayerToUI(localPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer and isSlateUser(p) then
			addPlayerToUI(p)
		end
	end
	updateCountOnly()
	task.spawn(function()
		pcall(refreshActiveList)
	end)

	Players.PlayerAdded:Connect(function(p)
		if isSlateUser(p) then
			addPlayerToUI(p)
		end
		updateCountOnly()
		task.wait(0.5)
		pcall(refreshActiveList)
	end)
	Players.PlayerRemoving:Connect(function(p)
		removePlayerFromUI(p)
		updateCountOnly()
	end)

	task.spawn(function()
		while G2L["1"] and G2L["1"].Parent do
			task.wait(5)
			pcall(refreshActiveList)
		end
	end)

	_G.SlateOwnerPanelGui = G2L["1"]
	G2L["1"].Parent = targetUI
	G2L["2"].Visible = initialShowPanel
	return G2L["1"]
end

_G.SlateToggleOwnerPanel = function()
	return SlateNametags:TogglePanel()
end

_G.SlateToggleNametags = function(forceState)
	local newState = (forceState ~= nil) and forceState or (not enabled)
	SlateNametags:SetEnabled(newState)
	return newState
end

task.spawn(buildOwnerClientUI)

ensureDefaultConfig()

-- Instantly render nametag for local player (0ms delay)
applyConfig(localPlayer)
task.spawn(function()
	syncPlayer(localPlayer)
end)

-- Non-blockingly sync other players in parallel (only users with custom tags will render)
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		task.spawn(function()
			syncPlayer(player)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player ~= localPlayer then
		task.spawn(function()
			syncPlayer(player)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if player == localPlayer then
		postPresence("leave")
	else
		removeTag(player.UserId)
		configs[player.Name:lower()]    = nil
		rawConfigs[player.Name:lower()] = nil
	end
end)

connectWebSocket()
postPresence("join")

task.spawn(function()
	while true do
		task.wait(CONFIG.heartbeatPoll)
		postPresence("join")
	end
end)

-- Auto-refresh tag configs every 10 seconds as a fallback for live updates
task.spawn(function()
	while true do
		pcall(syncAll)
		task.wait(10)
	end
end)

task.spawn(function()
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

return SlateNametags