if not LPS_OBFUSCATED then LPS_ATTRIBUTES = function(...) end; VM = function(...) end; OPAL = nil; NONE = nil; PRESET = function(...) end; SECURE = nil; FAST = nil; ERROR_HANDLING = function(...) end; TRANSFORM = function(...) end; CONTROL_FLOW = nil; REWRITE_NAMECALLS = nil; EXTRACT = function(...) end; GLOBALS = nil; CONSTANTS = nil; INLINE = function(...) end; UNROLL = function(...) end; OPTIMIZE = function(...) end; ENCRYPT = function(...) end; LPS_ENCSTR = function(s) return s end; LPS_ENCNUM = function(n) return n end; LPS_CRASH = function() end end
LPS_ATTRIBUTES(
    PRESET(FAST)
)

local _slateLoadStart = os.clock()

local _prefetchedScripts = {}
local _prefetchDone = {}
local _prefetchUrls = {
	commands = LPS_ENCSTR("https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/commands.lua"),
	reanimate = LPS_ENCSTR("https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/reanimate.lua"),
	client = LPS_ENCSTR("https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/client.lua"),
}
for name, url in pairs(_prefetchUrls) do
	task.spawn(function()
		local ok, src = pcall(game.HttpGet, game, url)
		if ok then _prefetchedScripts[name] = src end
		_prefetchDone[name] = true
	end)
end
local function _awaitPrefetch(name, timeout)
	if _prefetchDone[name] then return end
	local elapsed = 0
	while not _prefetchDone[name] and elapsed < (timeout or 5) do
		task.wait()
		elapsed = elapsed + 0.016
	end
end

espContainer = espContainer or Instance.new("Folder", gethui and gethui() or game:GetService("CoreGui"))
espContainer.Name = "SlateEspContainer"

local KS = {
	validated = false,
	folder = "slate",
	file = "slate/key.json",
	scriptId = "04097065230177886056",
	sdk = nil
}
local runMainScript

local KEYLESS_OVERRIDE = true

local BOOT_SOUND_URL    = "https://www.sl8ght.xyz/start.mp3"
local BOOT_SOUND_VOLUME = 1

task.spawn(function()
	local url = tostring(BOOT_SOUND_URL or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if url == "" then return end

	if _G.SlateBootSound then
		pcall(function() _G.SlateBootSound:Destroy() end)
		_G.SlateBootSound = nil
	end

	local soundId
	if url:match("^rbxassetid://%d+$") then
		soundId = url
	elseif url:match("^%d+$") then
		soundId = "rbxassetid://" .. url
	else

		local getAsset = getcustomasset or getsynasset or (syn and syn.get_custom_asset)
		local req = request or http_request or (syn and syn.request)
		if not (getAsset and req and writefile and isfile and isfolder and makefolder) then
			warn("[Slate] Boot sound needs getcustomasset + file support in this executor.")
			return
		end

		local BOOT_DIR = "slate/boot"
		local h = 5381
		for i = 1, #url do h = (h * 33 + string.byte(url, i)) % 4294967296 end
		local ext = url:match("%.(%a%a%a?%a?)%f[%W]") or "mp3"
		local path = ("%s/%08x.%s"):format(BOOT_DIR, h, ext)

		local cached = false
		pcall(function() cached = isfile(path) end)

		if not cached then
			local okDir = pcall(function()
				if not isfolder("slate") then makefolder("slate") end
				if not isfolder(BOOT_DIR) then makefolder(BOOT_DIR) end
			end)
			if not okDir then
				warn("[Slate] Boot sound could not create " .. BOOT_DIR)
				return
			end

			local ok, res = pcall(req, { Url = url, Method = "GET" })
			if not (ok and res and res.Body and #res.Body > 0) then
				warn("[Slate] Boot sound download failed: " .. tostring(url))
				return
			end
			local status = tonumber(res.StatusCode) or 200
			if status ~= 200 then
				warn("[Slate] Boot sound download returned HTTP " .. tostring(status))
				return
			end
			local okW, errW = pcall(function() writefile(path, res.Body) end)
			if not okW then
				warn("[Slate] Boot sound could not be saved: " .. tostring(errW))
				return
			end
			print("[Slate] Boot sound cached to " .. path)
		end

		local okA, asset = pcall(getAsset, path)
		if not okA or not asset then
			warn("[Slate] getcustomasset rejected the boot sound: " .. tostring(asset))
			return
		end
		soundId = asset
	end

	local snd = Instance.new("Sound")
	snd.Name = "SlateBootSound"
	snd.SoundId = soundId
	snd.Volume = math.clamp(tonumber(BOOT_SOUND_VOLUME) or 0.5, 0, 10)
	snd.Looped = false
	snd.Parent = game:GetService("SoundService")
	_G.SlateBootSound = snd

	local okP, errP = pcall(function() snd:Play() end)
	if not okP then
		warn("[Slate] Boot sound failed to play: " .. tostring(errP))
		pcall(function() snd:Destroy() end)
		return
	end

	snd.Ended:Connect(function() pcall(function() snd:Destroy() end) end)

	task.delay(30, function()
		if snd and snd.Parent then pcall(function() snd:Destroy() end) end
	end)
end)

local function cleanupExistingUIs()
	local coreGui = game:GetService("CoreGui")
	local targetUI = gethui and gethui() or coreGui
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")

	for _, parent in ipairs({targetUI, coreGui, playerGui}) do
		if parent then
			pcall(function()
				for _, child in ipairs(parent:GetChildren()) do
					if child.Name == "SlateUi" or child.Name == "SlateIsland" or child.Name == "AKReanimGUI" or child.Name == "SlateKeySystemTemp" then
						pcall(function() child:Destroy() end)
					end
				end
			end)
		end
	end
end
cleanupExistingUIs()

task.spawn(function()
	local coreGui = game:GetService("CoreGui")
	local plrs = game:GetService("Players")

	local function sweep()
		local hosts = { gethui and gethui() or nil, coreGui }
		local plr = plrs.LocalPlayer
		if plr then
			local pg = plr:FindFirstChildOfClass("PlayerGui")
			if pg then hosts[#hosts + 1] = pg end
		end
		for _, host in ipairs(hosts) do
			if host then
				pcall(function()
					for _, child in ipairs(host:GetChildren()) do
						if child.Name == "SlateIsland" then
							child:Destroy()
						end
					end
				end)
			end
		end
	end

	for _ = 1, 60 do
		sweep()
		task.wait(1)
	end

	sweep()
end)

_G.SlateLoaded = true
_G.isShowingOwnerNotification = nil
_G._slateCmdBarOpen = nil
_G.showSlateTagsFlag = true
_G.showOnyxTagsFlag  = true

task.spawn(function()
	_awaitPrefetch("reanimate", 5)
	local ok = pcall(function()
		loadstring(_prefetchedScripts.reanimate or game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/reanimate.lua")))()
	end)
	if not ok then
		pcall(function()
			if isfile and isfile("slate/reanimate.lua") then
				loadstring(readfile("slate/reanimate.lua"))()
			elseif isfile and isfile("reanimate.lua") then
				loadstring(readfile("reanimate.lua"))()
			end
		end)
	end
end)

players = game:GetService("Players")
localPlayer = players.LocalPlayer
while not localPlayer do
	task.wait()
	localPlayer = players.LocalPlayer
end

local SlateBackdrop = { fields = {}, running = false }

SlateBackdrop.palette = {
	ink    = Color3.fromRGB(0, 0, 0),
	shade  = Color3.fromRGB(8, 8, 10),
	deep   = Color3.fromRGB(15, 15, 17),
	mid    = Color3.fromRGB(24, 24, 27),
	violet = Color3.fromRGB(255, 255, 255),
	bright = Color3.fromRGB(230, 230, 235),
	lift   = Color3.fromRGB(160, 160, 165),
	spark  = Color3.fromRGB(120, 120, 125),
}

function SlateBackdrop.baseSequence() return ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color3.new(0.06,0.06,0.07))}) end
function SlateBackdrop.barSequence()  return ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1))}) end
SlateBackdrop.recipe = {}
function createSlateBackdrop(hostFrame, cornerRadius, opts)
	opts = opts or {}
	local base = Instance.new("Frame", hostFrame)
	base.Name = "SlateBackdrop"
	base.Size = opts.size or UDim2.new(1, 0, 1, 0)
	base.Position = opts.position or UDim2.new(0, 0, 0, 0)
	base.AnchorPoint = opts.anchorPoint or Vector2.new(0, 0)
	base.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	base.BorderSizePixel = 0
	base.ZIndex = opts.zIndex or 0
	Instance.new("UICorner", base).CornerRadius = UDim.new(0, cornerRadius or 12)
	return base
end
function SlateBackdrop.setCornerRadius(base, radius)
	if not base then return end
	for _, obj in ipairs(base:GetDescendants()) do
		if obj:IsA("UICorner") then obj.CornerRadius = radius end
	end
end
function SlateBackdrop.refresh() end
function SlateBackdrop.start()   end

function createVectorShadow(parentFrame)
	return Instance.new("Folder")
end
coreGui = game:GetService("CoreGui")
targetUI = gethui and gethui() or coreGui
httpService = game:GetService("HttpService")
lighting = game:GetService("Lighting")
replicatedStorage = game:GetService("ReplicatedStorage")
runService = game:GetService("RunService")
guiService = game:GetService("GuiService")
statsService = game:GetService("Stats")
starterGui = game:GetService("StarterGui")
teleportService = game:GetService("TeleportService")
tweenService = game:GetService("TweenService")
userInputService = game:GetService("UserInputService")
local gameSettings = UserSettings():GetService("UserGameSettings")

_G.SlateBackendOnline = false
local function startBackendServices()

end

local isBlacklisted = false
local errorMsg = "Access Denied."
local hwid = "Unknown"
pcall(function() hwid = (gethwid and gethwid()) or "LegacyHWID-" .. tostring(players.LocalPlayer.UserId) end)
local httpRequest = request or http_request or (syn and syn.request)

if not httpRequest then

end

_G._SlateBackendCheckDone = false
_G._SlateIsWhitelisted = false
_G._SlateIsBlacklisted = false
_G._SlateBlacklistMsg = nil

if httpRequest and (getgenv().SLATE_ONLINE ~= false and _G.SLATE_ONLINE ~= false) then
	task.spawn(function()
		local resolvedBackend = getgenv().BACKEND_URL or _G.BACKEND_URL or getgenv().WORKER_BASE or _G.WORKER_BASE or LPS_ENCSTR("https://api.onyxv2.lol")
		local username = players.LocalPlayer.Name
		local baseUrl = resolvedBackend:gsub("/$", "")
		_G.SlateBackendBase = baseUrl

		local keylessOn = false
		if KEYLESS_OVERRIDE ~= nil then

			keylessOn = KEYLESS_OVERRIDE

		else
			local okK, resK = pcall(function()
				return httpRequest({
					Url = baseUrl .. "/keyless",
					Method = "GET",
					Headers = { ["Content-Type"] = "application/json" },
				})
			end)
			if okK and resK and resK.StatusCode == 200 and resK.Body then
				local okJK, dataK = pcall(httpService.JSONDecode, httpService, resK.Body)
				if okJK and type(dataK) == "table" and dataK.keyless == true then
					keylessOn = true
				end
			else

			end
		end

		if keylessOn then

			_G._SlateKeylessMode = true
			KS.validated = true
			_G._SlateBackendCheckDone = true
			_G.SlateBackendOnline = true
		end

		task.spawn(function()
			local since = math.floor(os.time() * 1000)
			while task.wait(6) do
				local okP, resP = pcall(function()
					return httpRequest({
						Url = baseUrl .. "/player-kick?username=" .. username .. "&since=" .. tostring(since),
						Method = "GET",
						Headers = { ["Content-Type"] = "application/json" },
					})
				end)
				if okP and resP and resP.StatusCode == 200 and resP.Body then
					local okJP, dataP = pcall(httpService.JSONDecode, httpService, resP.Body)
					if okJP and type(dataP) == "table" and type(dataP.kick) == "table" and dataP.kick.id then
						since = dataP.kick.id
						local reason = dataP.kick.reason or "You have been removed by an administrator."
						pcall(function() players.LocalPlayer:Kick(reason) end)
						break
					end
				end
			end
		end)

		local whitelistUrl = baseUrl .. "/whitelist/" .. username

		local ok, res = pcall(function()
			return httpRequest({
				Url = whitelistUrl,
				Method = "GET",
				Headers = { ["Content-Type"] = "application/json" },
			})
		end)

		if ok and res and res.StatusCode == 200 and res.Body then

			local okJ, data = pcall(httpService.JSONDecode, httpService, res.Body)
			if okJ and type(data) == "table" then
				if data.blacklisted then

					_G._SlateIsBlacklisted = true
					_G._SlateBlacklistMsg = data.reason or "You have been permanently blacklisted from Slate."

					KS.validated = true
				elseif data.whitelisted then

					_G._SlateIsWhitelisted = true
					KS.validated = true
				else

				end
			end
		else

		end
		_G._SlateBackendCheckDone = true
		_G.SlateBackendOnline = true

		task.spawn(function()
			local wsWait = 0
			while not KS.validated and wsWait < 120 do
				task.wait(0.2)
				wsWait = wsWait + 0.2
			end
			if _G.startWsAndNametags then
				pcall(_G.startWsAndNametags)
			end
		end)
	end)
else

	if KEYLESS_OVERRIDE == true then

		_G._SlateKeylessMode = true
		KS.validated = true
	end
	_G._SlateBackendCheckDone = true
end

if not KS then
	KS = {
		validated = false,
		folder = "slate",
		file = "slate/key.json",
		scriptId = "04097065230177886056",
		sdk = nil
	}
end

function KS.ensureFolder()
	local ok = pcall(function()
		if not isfolder(KS.folder) then
			makefolder(KS.folder)
		end
	end)
	return ok
end

function KS.loadSavedKey()
	local ok, result = pcall(function()
		if isfile(KS.file) then
			local raw = readfile(KS.file)
			local decoded = httpService:JSONDecode(raw)
			return decoded and decoded.Key
		end
		return nil
	end)
	if ok then return result end
	return nil
end

function KS.saveKey(key)
	pcall(function()
		KS.ensureFolder()
		writefile(KS.file, httpService:JSONEncode({ Key = key }))
	end)
end

local gui, frame, bar, statusText, tween

local function updateUI(val)
	if not gui then
		local core = game:GetService("CoreGui")
		local parent = gethui and gethui() or core

		gui = Instance.new("ScreenGui")
		gui.Name = "SlateLoader"
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.IgnoreGuiInset = true
		gui.Parent = parent

		frame = Instance.new("Frame", gui)
		frame.Name = "Main"
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
		frame.Position = UDim2.new(0.5, -125, 0.4, -50)
		frame.Size = UDim2.new(0, 250, 0, 100)
		frame.ZIndex = 20

		local corner = Instance.new("UICorner", frame)
		corner.CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = Color3.fromRGB(40, 40, 42)
		stroke.Thickness = 1.5

		pcall(function()
			if createSlateBackdrop then
				createSlateBackdrop(frame, 12, { zIndex = 20, intensity = 0.8 })
			end
		end)

		local logo = Instance.new("ImageLabel", frame)
		logo.Size = UDim2.new(0, 24, 0, 26)
		logo.Position = UDim2.new(0, 15, 0, 15)
		logo.Image = "rbxassetid://106790631609801"
		logo.BackgroundTransparency = 1
		logo.ZIndex = 22

		local title = Instance.new("TextLabel", frame)
		title.Size = UDim2.new(0, 180, 0, 20)
		title.Position = UDim2.new(0, 48, 0, 18)
		title.Text = "Slate"
		if Font and Font.new then
			title.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		else
			title.Font = Enum.Font.GothamBold
		end
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 15
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.BackgroundTransparency = 1
		title.ZIndex = 22

		statusText = Instance.new("TextLabel", frame)
		statusText.Size = UDim2.new(1, -30, 0, 20)
		statusText.Position = UDim2.new(0, 15, 0, 50)
		statusText.Text = "Loading..."
		if Font and Font.new then
			statusText.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		else
			statusText.Font = Enum.Font.Gotham
		end
		statusText.TextColor3 = Color3.fromRGB(180, 180, 190)
		statusText.TextSize = 11
		statusText.TextXAlignment = Enum.TextXAlignment.Left
		statusText.BackgroundTransparency = 1
		statusText.ZIndex = 22

		local bg = Instance.new("Frame", frame)
		bg.Name = "ProgressBg"
		bg.Size = UDim2.new(1, -30, 0, 6)
		bg.Position = UDim2.new(0, 15, 0, 75)
		bg.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
		bg.BorderSizePixel = 0
		bg.ZIndex = 22
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 3)

		bar = Instance.new("Frame", bg)
		bar.Name = "Bar"
		bar.Size = UDim2.new(0, 0, 1, 0)
		bar.BackgroundColor3 = Color3.fromRGB(200, 200, 205)
		bar.BorderSizePixel = 0
		bar.ZIndex = 23
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)
	end

	local ts = tweenService
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if val == 1 then
		statusText.Text = "Attempting to authenticate..."
		if tween then tween:Cancel() end
		tween = ts:Create(bar, info, { Size = UDim2.new(0.33, 0, 1, 0) })
		tween = ts:Create(bar, info, { Size = UDim2.new(0.33, 0, 1, 0) })
		tween:Play()
	elseif val == 2 then
		statusText.Text = "Connecting to LuaProt servers..."
		if tween then tween:Cancel() end
		tween = ts:Create(bar, info, { Size = UDim2.new(0.66, 0, 1, 0) })
		tween:Play()
	else
		statusText.Text = "Successfully loaded in " .. string.format("%.2f", tonumber(val) or 0) .. "s!"
		statusText.TextColor3 = Color3.fromRGB(100, 220, 130)
		if tween then tween:Cancel() end
		tween = ts:Create(bar, info, { Size = UDim2.new(1, 0, 1, 0) })
		tween:Play()

		task.delay(1, function()
			pcall(function()
				local fade = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				ts:Create(frame, fade, { BackgroundTransparency = 1 }):Play()
				ts:Create(statusText, fade, { TextTransparency = 1 }):Play()
				ts:Create(bar, fade, { BackgroundTransparency = 1 }):Play()
				task.wait(0.3)
				gui:Destroy()
			end)
		end)
	end
end

local canUsePhysicsRep = false

do

KS = {
	validated = false,
	folder = LPS_ENCSTR("slate"),
	file = LPS_ENCSTR("slate/key.json"),
	scriptId = LPS_ENCSTR("04097065230177886056"),
	sdk = nil
}

function KS.ensureFolder()
	LPS_ATTRIBUTES(VM(OPAL), PRESET(SECURE), ERROR_HANDLING(false))
	local ok = pcall(function()
		if not isfolder(KS.folder) then
			makefolder(KS.folder)
		end
	end)
	return ok
end

function KS.loadSavedKey()
	LPS_ATTRIBUTES(VM(OPAL), PRESET(SECURE), ERROR_HANDLING(false))
	local ok, result = pcall(function()
		if isfile(KS.file) then
			local raw = readfile(KS.file)
			local decoded = httpService:JSONDecode(raw)
			return decoded and decoded.Key
		end
		return nil
	end)
	if ok then return result end
	return nil
end

function KS.saveKey(key)
	LPS_ATTRIBUTES(VM(OPAL), PRESET(SECURE), ERROR_HANDLING(false))
	pcall(function()
		KS.ensureFolder()
		writefile(KS.file, httpService:JSONEncode({ Key = key }))
	end)
end

cachedOnyxUsers = {}
autoexecConfig = {}
localPlayer = localPlayer or players.LocalPlayer
camera = workspace.CurrentCamera
mouse = localPlayer:GetMouse()
getMessage = replicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 1) and replicatedStorage.DefaultChatSystemChatEvents:WaitForChild("OnMessageDoneFiltering", 1)
notifications = {}
friendsCooldown = 0
smartBarOpen = false
dragInput = nil
debounce = false
searchingForPlayer = false
musicQueue = {}
playGeneration = 0
currentAudio = nil
lowerName = localPlayer.Name:lower()
lowerDisplayName = localPlayer.DisplayName:lower()
placeId = game.PlaceId
jobId = game.JobId
checkingForKey = false
originalTextValues = {}
creatorId = game.CreatorId
creatorType = game.CreatorType
noclipDefaults = {}
movers = movers or {}
local espContainer = Instance.new("Folder", gethui and gethui() or coreGui)
espContainer.Name = "SlateEspContainer"
local locatedPlayers = {}
local espConnections = {}
local oldVolume = gameSettings.MasterVolume
local suppressedSounds = {}
local soundSuppressionNotificationCooldown = 0
local soundInstances = {}
local cachedIds = {}
local cachedText = {}
local lastCoverUrl = ""
local lastCoverPath = ""
local tokenExpiredNotification = false

_G.SlateUnavailableTabs = {
	["Cloud"] = true
}

G2L = G2L or {}
ServerPlayersLbl, ServerPingLbl = nil, nil
MainCloseBtn = nil
DockLogo, ToggleButton = nil, nil
HomeBtn, CharacterBtn, CommandsBtn, PlayersBtn, MusicBtn, SettingsBtn, NametagsBtn, OwnerBtn, AutoExecBtn, AutoExecTab, refreshAEList = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
PlayersTab, PlayersScroll, MusicTab, SettingsTab = nil, nil, nil, nil
btn1, btn2, btn3, stroke1, stroke2, stroke3 = nil, nil, nil, nil, nil, nil
showNametags = true
checkSetting, saveSettings = nil, nil
GetNearestPlayer, StartFaceBang, StopFaceBang = nil, nil, nil
FriendsRefreshBtn = nil
ResetCustomsBtn = nil
SpotifyWindow, SpotifyPlayBtn, SpotifyNextBtn, SpotifyBackBtn, SongLabel, ArtistLabel, AlbumCover, BackgroundCover = nil, nil, nil, nil, nil, nil, nil, nil
ShuffleBtn, RepeatBtn, ProgressBarFill, TimeCurrent, TimeLength = nil, nil, nil, nil, nil
local shuffleState, repeatState = false, "off"
local currentProgressMs, trackDurationMs, lastProgressUpdate = 0, 1, 0
populateLibrary = nil
spotifyRequest = nil
styleMediaBtn, uiControlsFrame = nil, nil
local SettingsTitle, SettingsBackBtn, SettingsCategories, SettingsOptionsFrame, playerContainer, setupContainer, setupBackBtn, siriusValues, uiProgFill, musicIcon, connectBtn, isEditingCredentials = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, false
local art, uiSongLabel, uiArtistLabel, uiPlay
sliderObjects = sliderObjects or {}
onyxCommands, onyxAliases = nil, nil
_infZoomEnabled = false
_infZoomMax = 100
_walkWallEnabled = false
_noclipConn = nil
ZeroDelayEnabled = false
zeroDelayTargetPlayer = nil
zeroDelayThread = nil
zeroDelayConnection = nil
zeroDelayMode = nil
FaceBangEnabled = false
antiFlingConn = nil
AntiFlingEnabled = false
_antiNetPauseConn = nil
_infJumpConn = nil
FacebangWindow = nil

local SLATE_OWNER_IDS = {
	LPS_ENCNUM(10808550547),
	LPS_ENCNUM(10012699579),
	LPS_ENCNUM(4377530875),
	LPS_ENCNUM(3459666509),
	LPS_ENCNUM(10845358519),
	LPS_ENCNUM(293450),
	LPS_ENCNUM(2637355515),
}
local function slateResolveOwner()
	local id = localPlayer and localPlayer.UserId
	if not id then return false end
	return table.find(SLATE_OWNER_IDS, id) ~= nil
end
slateIsOwner = slateResolveOwner()
_G.SlateIsOwner = slateIsOwner
dockButtons = dockButtons or {}
IslandAlbumCover = nil
IslandGroup = nil
ClockIcon = nil
IslandTimeLabel = nil
spotifyIsPlaying = false

function clearCache()
	pcall(function()
		if listfiles and delfile then

			if isfolder and isfolder("slate/cache") then
				local files = listfiles("slate/cache")
				for i, file in ipairs(files) do
					local cleanF = file:gsub("\\\\", "/"):gsub("\\", "/")
					local fileBase = cleanF:match("([^/]+)$")
					if fileBase then
						pcall(delfile, "slate/cache/" .. fileBase)
					end
					if i % 30 == 0 then task.wait() end
				end
			end

			if isfolder and isfolder("slate/music") then
				local files = listfiles("slate/music")
				local count = 0
				for _, file in ipairs(files) do
					local cleanF = file:gsub("\\\\", "/"):gsub("\\", "/")
					local fileBase = cleanF:match("([^/]+)$")
					if fileBase and (fileBase:match("cover_") or fileBase:match("%.png$")) then
						pcall(delfile, "slate/music/" .. fileBase)
						count = count + 1
						if count % 30 == 0 then task.wait() end
					end
				end
			end
		end
	end)
end
task.spawn(clearCache)

function checkFolder()
	if makefolder then
		if not isfolder("slate") then makefolder("slate") end
		if not isfolder("slate/cache") then makefolder("slate/cache") end
		if not isfolder("slate/music") then
			makefolder("slate/music")
			if writefile then
				writefile("slate/music/readme.txt", "Store spotify album covers or music cache here.")
			end
		end
	end
end
task.spawn(checkFolder)

local savedToken = ""
pcall(function()
	if readfile and isfile("slate/music/spotify_token.txt") then
		savedToken = readfile("slate/music/spotify_token.txt")
	end
end)
local savedRefreshToken = ""
pcall(function()
	if readfile and isfile("slate/music/spotify_refresh_token.txt") then
		savedRefreshToken = readfile("slate/music/spotify_refresh_token.txt")
	end
end)
local savedClientId = ""
pcall(function()
	if readfile and isfile("slate/music/spotify_client_id.txt") then
		savedClientId = readfile("slate/music/spotify_client_id.txt")
	end
end)
local savedClientSecret = ""
pcall(function()
	if readfile and isfile("slate/music/spotify_client_secret.txt") then
		savedClientSecret = readfile("slate/music/spotify_client_secret.txt")
	end
end)

siriusSettings = {
	{
		name = "General",
		description = "General configuration options.",
		color = Color3.fromRGB(255, 255, 255),
		categorySettings = {
			{name = "Spotify OAuth Token", settingType = "Input", current = savedToken, id = "spotifyoauthtoken"},
			{name = "Spotify Refresh Token", settingType = "Input", current = savedRefreshToken, id = "spotifyrefreshtoken"},
			{name = "Spotify Client ID", settingType = "Input", current = savedClientId, id = "spotifyclientid"},
			{name = "Spotify Client Secret", settingType = "Input", current = savedClientSecret, id = "spotifyclientsecret"},
			{name = "Anonymous Client", settingType = "Boolean", current = false, id = "anonmode"},
			{name = "Chat Spy", settingType = "Boolean", current = true, id = "chatspy"},
			{name = "Hide Toggle Button", settingType = "Boolean", current = false, id = "hidetoggle"},
			{name = "Now Playing Notifications", settingType = "Boolean", current = true, id = "nowplaying"},
			{name = "Friend Notifications", settingType = "Boolean", current = true, id = "friendnotifs"},
			{name = "Disable All Notifications", settingType = "Boolean", current = false, id = "disableallnotifs"},
			{name = "Load Hidden", settingType = "Boolean", current = false, id = "loadhidden"},
			{name = "Startup Sound Effect", settingType = "Boolean", current = true, id = "startupsound"},
			{name = "Hover Sound Effect", settingType = "Boolean", current = true, id = "hoversound"},
			{name = "Notification Sound Effect", settingType = "Boolean", current = true, id = "notifsound"},
			{name = "Anti Idle", settingType = "Boolean", current = true, id = "antiidle"},
			{name = "Client-Based Anti Kick", settingType = "Boolean", current = false, id = "antikick"},
			{name = "Muffle audio while unfocused", settingType = "Boolean", current = true, id = "muffleunfocused"}
		}
	},
	{
		name = "Keybinds",
		description = "Configure script hotkeys.",
		color = Color3.fromRGB(255, 255, 255),
		categorySettings = {
						{name = "Toggle Slate UI", settingType = "Key", current = "K", id = "smartbar"},
			{name = "Command Bar", settingType = "Key", current = "Semicolon", id = "cmdbar"},
			{name = "Open ScriptSearch", settingType = "Key", current = nil, id = "openscriptsearch"},
			{name = "NoClip", settingType = "Key", current = nil, id = "noclip"},
			{name = "Flight", settingType = "Key", current = nil, id = "flight"},
			{name = "Refresh", settingType = "Key", current = nil, id = "refresh"},
			{name = "Respawn", settingType = "Key", current = nil, id = "respawn"},
			{name = "Invulnerability", settingType = "Key", current = nil, id = "invuln"},
			{name = "Fling", settingType = "Key", current = nil, id = "fling"},
			{name = "ESP", settingType = "Key", current = nil, id = "esp"},
			{name = "Night and Day", settingType = "Key", current = nil, id = "nightday"},
			{name = "Global Audio", settingType = "Key", current = nil, id = "globalaudio"},
			{name = "Visibility", settingType = "Key", current = nil, id = "visibility"},
			{name = "Facebang Panel", settingType = "Key", current = nil, id = "facebangpanel"},
			{name = "Anti-Fling", settingType = "Key", current = nil, id = "antifling"},
			{name = "Anti Net Pause", settingType = "Key", current = nil, id = "antinetpause"},
			{name = "Platform Stand", settingType = "Key", current = nil, id = "platformstand"},
			{name = "Trip Character", settingType = "Key", current = nil, id = "tripcharacter"},
			{name = "Invisible Sit", settingType = "Key", current = nil, id = "invisiblesit"},
			{name = "Zero Gravity", settingType = "Key", current = nil, id = "zerogravity"},
			{name = "Infinite Zoom", settingType = "Key", current = nil, id = "infinitezoom"},
			{name = "Godmode", settingType = "Key", current = nil, id = "godmode"},
			{name = "BTools", settingType = "Key", current = nil, id = "btools"},
			{name = "Infinite Jump", settingType = "Key", current = nil, id = "infjump"},
			{name = "Walk on Air", settingType = "Key", current = nil, id = "walkonair"},
			{name = "Walk on Walls", settingType = "Key", current = nil, id = "walkwall"},
			{name = "Click Teleport", settingType = "Key", current = nil, id = "clicktp"},
			{name = "Teleport Tool", settingType = "Key", current = nil, id = "tptool"}
		}
	},
	{
		name = "Performance",
		description = "Performance settings.",
		color = Color3.fromRGB(255, 255, 255),
		categorySettings = {
			{name = "Artificial FPS Limit", settingType = "Number", values = {20, 5000}, current = 240, id = "fpscap"},
			{name = "Limit FPS while unfocused", settingType = "Boolean", current = true, id = "fpsunfocused"},
			{name = "Adaptive Latency Warning", settingType = "Boolean", current = true, id = "latencywarning"},
			{name = "Adaptive Performance Warning", settingType = "Boolean", current = true, id = "perfwarning"}
		}
	},
	{
		name = "Detections",
		description = "Malicious action detections.",
		color = Color3.fromRGB(255, 255, 255),
		categorySettings = {
			{name = "Spatial Shield", settingType = "Boolean", current = true, id = "spatialshield"},
			{name = "Spatial Shield Threshold", settingType = "Number", values = {100, 1000}, current = 300, id = "spatialshieldthreshold"},
			{name = "Moderator Detection", settingType = "Boolean", current = true, id = "moddetection"},
			{name = "Intelligent HTTP Interception", settingType = "Boolean", current = true, id = "httpinterception"},
			{name = "Intelligent Clipboard Interception", settingType = "Boolean", current = true, id = "clipinterception"}
		}
	},
	{
		name = "Logging",
		description = "Log actions to discord webhook.",
		color = Color3.fromRGB(255, 255, 255),
		categorySettings = {
			{name = "Log Messages", settingType = "Boolean", current = false, id = "logmsg"},
			{name = "Message Webhook URL", settingType = "Input", current = "No Webhook", id = "logmsgurl"},
			{name = "Log PlayerAdded and PlayerRemoving", settingType = "Boolean", current = false, id = "logplrjoinleave"},
			{name = "Player Added and Removing Webhook URL", settingType = "Input", current = "No Webhook", id = "logplrjoinleaveurl"}
		}
	},
	{
		name = "Themes",
		description = "Customise Slate's colour scheme.",
		color = Color3.fromRGB(255, 255, 255),
		categorySettings = {
			{name = "Main Background Colour", settingType = "Color", current = "#0C0C0E", id = "maincolor"},
			{name = "Accent Colour", settingType = "Color", current = "#FFFFFF", id = "accentcolor"},
			{name = "Active Theme", settingType = "Input", current = "Obsidian", id = "activetheme"},
			{name = "Custom Background Image ID", settingType = "Input", current = "", id = "custombackgroundid"},
		}
	}
}

checkSetting = function(id)
	for _, category in ipairs(siriusSettings) do
		for i, setting in ipairs(category.categorySettings) do
			if setting.id == id then
				return setting
			end
		end
	end
	return nil
end
local _themeAccentStrokes = {}
local _themeToggleElements = {}

function hexToColor3(hex)
	if not hex then return Color3.fromRGB(255, 255, 255) end
	hex = hex:gsub("#", "")
	if #hex < 6 then return Color3.fromRGB(255, 255, 255) end
	local r = tonumber("0x" .. hex:sub(1, 2)) or 255
	local g = tonumber("0x" .. hex:sub(3, 4)) or 255
	local b = tonumber("0x" .. hex:sub(5, 6)) or 255
	return Color3.fromRGB(r, g, b)
end

local slatePresetThemes = {
	{name = "Monochrome",   main = "#0C0C0E", accent = "#FFFFFF"},
	{name = "Royal Violet",  main = "#0C0C0E", accent = "#FFFFFF"},
	{name = "Ruby",         main = "#0C0C0E", accent = "#E11D3C"},
	{name = "Blossom",      main = "#0C0C0E", accent = "#FF52A8"},
	{name = "Amethyst",     main = "#0C0C0E", accent = "#CCCCCC"},
	{name = "Midnight",     main = "#050912", accent = "#3B82F6"},
	{name = "Glacier",      main = "#04101A", accent = "#22D3EE"},
	{name = "Emerald",      main = "#04120C", accent = "#10B981"},
	{name = "Inferno",      main = "#150701", accent = "#FF6A1A"},
	{name = "Gold",         main = "#120D02", accent = "#F2B705"},
	{name = "Obsidian",     main = "#08090C", accent = "#B8C4D4"},
}
function applyTheme(mainHex, accentHex)
	local mainCol = hexToColor3(mainHex or "#000000")
	local accentCol = hexToColor3(accentHex or "#FFFFFF")
	_currentThemeMain = mainCol
	_currentThemeAccent = accentCol
	local _accentLum = 0.2126 * accentCol.R + 0.7152 * accentCol.G + 0.0722 * accentCol.B
	_G._SlateAccentTextCol = (_accentLum > 0.45) and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(255, 255, 255)

	pcall(function() if G2L and G2L["2"] then G2L["2"].BackgroundColor3 = mainCol end end)

	pcall(function() if G2L and G2L["30"] then G2L["30"].BackgroundColor3 = mainCol end end)

	pcall(function() if G2L and G2L["2f"] then G2L["2f"].Color = accentCol end end)

	pcall(function()
		if SlateBackdrop and SlateBackdrop.palette then
			local p = SlateBackdrop.palette
			p.ink    = mainCol
			p.shade  = mainCol:Lerp(Color3.fromRGB(0, 0, 0), 0.4)
			p.violet = accentCol
			p.mid    = accentCol:Lerp(mainCol, 0.56)
			p.deep   = accentCol:Lerp(mainCol, 0.86)
			p.bright = accentCol:Lerp(Color3.fromRGB(255, 255, 255), 0.16)
			p.lift   = accentCol:Lerp(Color3.fromRGB(255, 255, 255), 0.42)
			p.spark  = accentCol:Lerp(Color3.fromRGB(255, 255, 255), 0.66)
			SlateBackdrop.refresh()
		end
	end)

	for _, stroke in ipairs(_themeAccentStrokes) do
		pcall(function() stroke.Color = accentCol end)
	end

	for _, btn in ipairs(_themeToggleElements) do
		pcall(function()
			if btn.Text == "ON" then
				btn.BackgroundColor3 = accentCol
				btn.TextColor3 = _G._SlateAccentTextCol or Color3.fromRGB(10, 10, 10)
			end
		end)
	end
	pcall(function()
		if uiProgFill then uiProgFill.BackgroundColor3 = accentCol end
		if musicIcon then musicIcon.ImageColor3 = accentCol end
		if connectBtn then connectBtn.BackgroundColor3 = accentCol end
	end)

	pcall(function()
		local mainSet = checkSetting("maincolor")
		local accentSet = checkSetting("accentcolor")
		if mainSet then mainSet.current = mainHex end
		if accentSet then accentSet.current = accentHex end
	end)
end

_G._customBackgroundImage = ""

local function applyCustomBgToFrame(frame)
	if not frame or not (frame:IsA("Frame") or frame:IsA("CanvasGroup") or frame:IsA("ScrollingFrame")) then return end
	local imgId = _G._customBackgroundImage or ""

	local bgImg = frame:FindFirstChild("BackgroundImage") or frame:FindFirstChild("SlateCustomBg")
	local backdrop = frame:FindFirstChild("Backdrop")

	if imgId == "" then
		if bgImg then
			bgImg.Visible = false
			bgImg.Image = ""
			bgImg.ImageTransparency = 1
		end

		if backdrop then backdrop.ImageTransparency = 0 end
		return
	end

	if not bgImg then
		bgImg = Instance.new("ImageLabel")
		bgImg.Name = "SlateCustomBg"
		bgImg.Size = UDim2.new(1, 0, 1, 0)
		bgImg.BackgroundTransparency = 1
		bgImg.ScaleType = Enum.ScaleType.Crop
		bgImg.ZIndex = 2
		bgImg.Parent = frame
	end

	bgImg.ScaleType = Enum.ScaleType.Crop
	bgImg.ZIndex = 2
	bgImg.Visible = true

	if backdrop then backdrop.ImageTransparency = 1 end

	local numericId = imgId:match("^%s*(%d+)%s*$") or imgId:match("rbxassetid://(%d+)") or imgId:match("id=(%d+)")
	if numericId then
		bgImg.Image = "rbxthumb://type=Asset&id=" .. numericId .. "&w=768&h=432"
		bgImg.ImageTransparency = 0.45
	elseif imgId:find("^https?://") then
		bgImg.ImageTransparency = 0.45
		task.spawn(function()
			if not bgImg or not bgImg.Parent then return end
			if type(getcustomasset) == "function" and type(writefile) == "function" then
				if makefolder and not isfolder("slate/cache") then
					pcall(makefolder, "slate")
					pcall(makefolder, "slate/cache")
				end
				local baseKeyBg = (function(str)
					local hash = 5381
					for i = 1, #str do
						hash = (hash * 33 + str:byte(i)) % 4294967296
					end
					return tostring(hash)
				end)(imgId)
				local fetched = false

				if type(isfile) == "function" then
					for _, tryExt in ipairs({".gif", ".png"}) do
						local tryFname = "slate/cache/slate_bg_" .. baseKeyBg .. "_cached" .. tryExt
						if isfile(tryFname) then
							pcall(function()
								local ca = getcustomasset(tryFname)
								if ca and bgImg and bgImg.Parent then bgImg.Image = ca; fetched = true end
							end)
							if fetched then break end
						end
					end
				end
				if not fetched then
					local ok, result = pcall(httpRequest, { Url = imgId, Method = "GET" })
					if ok and result and result.Body and #result.Body > 0 then
						local isGifBg = imgId:lower():find("%.gif") or (result.Headers and (result.Headers["content-type"] or result.Headers["Content-Type"] or ""):find("gif"))
						local ext = isGifBg and ".gif" or ".png"
						local fname = "slate/cache/slate_bg_" .. baseKeyBg .. "_cached" .. ext
						pcall(function()
							writefile(fname, result.Body)
							local ca = getcustomasset(fname)
							if bgImg and bgImg.Parent then bgImg.Image = ca end
						end)
					end
				end
			else
				if bgImg and bgImg.Parent then bgImg.Image = imgId end
			end
		end)
	elseif imgId:find("rbxthumb://") or imgId:find("rbxasset://") or imgId:find("rbxassetid://") then
		bgImg.Image = imgId
		bgImg.ImageTransparency = 0.45
	else
		bgImg.Visible = false
		if backdrop then backdrop.ImageTransparency = 0 end
	end
end

function _G.updateAllCustomBackgrounds()
	local activeBg = checkSetting("custombackgroundid")
	_G._customBackgroundImage = activeBg and activeBg.current or ""

	local hosts = {gethui and gethui() or nil, coreGui, localPlayer:FindFirstChild("PlayerGui")}
	for _, host in ipairs(hosts) do
		if host then
			for _, gui in ipairs(host:GetChildren()) do
				if gui:IsA("ScreenGui") then
					if gui.Name == "SlateUi" or gui.Name == "SlateEmoteAnimGUI" or gui.Name == "SlateGlitchMenu" then
						local mainFrame = gui:FindFirstChild("Main") or gui:FindFirstChild("MainFrame") or gui:FindFirstChild("MainContainer") or gui:FindFirstChild("Window") or gui:FindFirstChild("GlitchMenu")
						if mainFrame then
							applyCustomBgToFrame(mainFrame)
						end
					end
				end
			end
		end
	end
end

saveSettings = function()
	if not writefile then return end
	if not siriusValues or not siriusValues.sliders then return end
	local data = {}
	for _, category in ipairs(siriusSettings) do
		for i, setting in ipairs(category.categorySettings) do
			data[setting.id] = setting.current
		end
	end
	for _, slider in ipairs(siriusValues.sliders) do
		data["slider_" .. slider.name] = slider.value
	end
	pcall(writefile, "slate/settings.srs", httpService:JSONEncode(data))

	local tokenSet = checkSetting("spotifyoauthtoken")
	if tokenSet and tokenSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_token.txt", tokenSet.current)
	end
	local refreshSet = checkSetting("spotifyrefreshtoken")
	if refreshSet and refreshSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_refresh_token.txt", refreshSet.current)
	end
	local clientidSet = checkSetting("spotifyclientid")
	if clientidSet and clientidSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_client_id.txt", clientidSet.current)
	end
	local clientsecretSet = checkSetting("spotifyclientsecret")
	if clientsecretSet and clientsecretSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_client_secret.txt", clientsecretSet.current)
	end
	pcall(function() _G.updateAllCustomBackgrounds() end)
end

function addBorderStroke(parent, color, thickness, cornerRadius)
	local border = Instance.new("Frame", parent)
	border.Name = "BorderFrame"
	border.BorderSizePixel = 0
	border.Size = UDim2.new(1, 0, 1, 0)
	border.BackgroundTransparency = 1
	border.ZIndex = parent.ZIndex

	local radius = cornerRadius
	if not radius then
		local parentCorner = parent:FindFirstChildOfClass("UICorner")
		if parentCorner then radius = parentCorner.CornerRadius end
	end
	if radius then
		local corner = Instance.new("UICorner", border)
		corner.CornerRadius = radius
	end
	local stroke = Instance.new("UIStroke", border)
	stroke.Color = color or Color3.fromRGB(40, 40, 42)
	stroke.Thickness = thickness or 0.99
	return stroke
end
local islandNotificationQueue = {}
_G.isShowingIslandNotif = false
local lastActionNotifTime = {}

local islandNotificationQueue = {}
_G.isShowingIslandNotif = false
local lastActionNotifTime = {}

local function processIslandNotifQueue()
	local disableAll = checkSetting and checkSetting("disableallnotifs")
	if disableAll and disableAll.current then
		table.clear(islandNotificationQueue)
		_G.isShowingIslandNotif = false
		_G.isShowingOwnerNotification = false
		return
	end
	if _G.isShowingIslandNotif or _G.isShowingOwnerNotification or _G._slateCmdBarOpen or #islandNotificationQueue == 0 then return end
	_G.isShowingIslandNotif = true

	local notifData = table.remove(islandNotificationQueue, 1)
	local title = tostring(notifData.title or "Notification")
	local desc = tostring(notifData.description or "")
	local displayTime = notifData.duration or 3.5
	local targetPlr = notifData.targetPlayer

	if not G2L or not G2L["30"] then
		_G.isShowingIslandNotif = false
		return
	end

	local dock = G2L["30"]
	local corner = G2L["31"]

	for _, child in ipairs(dock:GetChildren()) do
		if child.Name == "IslandNotifyFrame" or child.Name == "OwnerNotify" then
			pcall(function() child:Destroy() end)
		end
	end

	if IslandGroup then IslandGroup.Visible = false end
	if DockLogo then DockLogo.Visible = false end
	if G2L["42"] then G2L["42"].Visible = false end
	if G2L["43"] then G2L["43"].Visible = false end
	if dockButtons then
		for _, data in ipairs(dockButtons) do
			if data.btn then data.btn.Visible = false end
		end
	end

	local frame = Instance.new("CanvasGroup", dock)
	frame.Name = "IslandNotifyFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.GroupTransparency = 1

	local isDismissed = false
	local function dismissNotif()
		if isDismissed then return end
		isDismissed = true

		tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1}):Play()
		task.wait(0.25)
		if frame and frame.Parent then frame:Destroy() end

		local function completeCollapse()
			_G.isShowingIslandNotif = false
			if not smartBarOpen and IslandGroup then
				IslandGroup.Visible = true
				updateIslandLayout()
			end
			processIslandNotifQueue()
		end

		if smartBarOpen then
			local barWidth = (slateIsOwner or _G.SlateIsOwner == true) and 210 or 166
			local halfWidth = barWidth / 2
			local restoreTween = tweenService:Create(dock, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, -halfWidth, 0, 15),
				Size = UDim2.new(0, barWidth, 0, 60)
			})
			restoreTween:Play()
			if corner then
				tweenService:Create(corner, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					CornerRadius = UDim.new(0, 10)
				}):Play()
			end
			if DockLogo then DockLogo.Visible = true end
			if dockButtons then
				for _, d in ipairs(dockButtons) do
					if d.btn then d.btn.Visible = true end
				end
			end
			if G2L["42"] then G2L["42"].Visible = true end
			if G2L["43"] then G2L["43"].Visible = true end
			restoreTween.Completed:Connect(completeCollapse)
		else
			local collapseTween = tweenService:Create(dock, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, -58, 0, 15),
				Size = UDim2.new(0, 117, 0, 39)
			})
			collapseTween:Play()
			if corner then
				tweenService:Create(corner, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					CornerRadius = UDim.new(0, 30)
				}):Play()
			end
			collapseTween.Completed:Connect(completeCollapse)
		end
	end

	local targetWidth = 310
	local targetHeight = 100

	if targetPlr then

		local thumb = Instance.new("ImageLabel", frame)
		thumb.Size = UDim2.new(0, 48, 0, 48)
		thumb.Position = UDim2.new(0, 15, 0.5, -24)
		thumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
		thumb.BorderSizePixel = 0
		thumb.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlr.UserId .. "&w=150&h=150"
		Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
		local thumbStroke = Instance.new("UIStroke", thumb)
		thumbStroke.Color = Color3.fromRGB(180, 180, 185)
		thumbStroke.Thickness = 0.8

		local titleLbl = Instance.new("TextLabel", frame)
		titleLbl.Size = UDim2.new(1, -95, 0, 18)
		titleLbl.Position = UDim2.new(0, 75, 0, 20)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextSize = 12.5
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local descLbl = Instance.new("TextLabel", frame)
		descLbl.Size = UDim2.new(1, -195, 0, 36)
		descLbl.Position = UDim2.new(0, 75, 0, 42)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = desc
		descLbl.TextColor3 = Color3.fromRGB(170, 170, 185)
		descLbl.Font = Enum.Font.GothamMedium
		descLbl.TextSize = 11
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextWrapped = true

		local btnsFrame = Instance.new("Frame", frame)
		btnsFrame.Size = UDim2.new(0, 96, 0, 26)
		btnsFrame.Position = UDim2.new(1, -111, 0.5, -5)
		btnsFrame.BackgroundTransparency = 1

		if notifData and notifData.isOwnerJoin then

			local dismissBtn = Instance.new("TextButton", btnsFrame)
			dismissBtn.Size = UDim2.new(1, 0, 1, 0)
			dismissBtn.Position = UDim2.new(0, 0, 0, 0)
			dismissBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
			dismissBtn.Text = "Dismiss"
			dismissBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
			dismissBtn.Font = Enum.Font.GothamBold
			dismissBtn.TextSize = 9.5
			dismissBtn.BorderSizePixel = 0
			Instance.new("UICorner", dismissBtn).CornerRadius = UDim.new(0, 6)

			dismissBtn.MouseButton1Click:Connect(dismissNotif)
		else

			local tpBtn = Instance.new("TextButton", btnsFrame)
			tpBtn.Size = UDim2.new(0, 44, 1, 0)
			tpBtn.Position = UDim2.new(0, 0, 0, 0)
			tpBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			tpBtn.Text = "TP"
			tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			tpBtn.Font = Enum.Font.GothamBold
			tpBtn.TextSize = 11
			tpBtn.BorderSizePixel = 0
			Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

			tpBtn.MouseButton1Click:Connect(function()
				pcall(function()
					local lp = Players.LocalPlayer or localPlayer
					if lp and lp.Character and targetPlr and targetPlr.Character then
						local myHrp = lp.Character:FindFirstChild("HumanoidRootPart") or lp.Character:FindFirstChild("Torso")
						local tHrp = targetPlr.Character:FindFirstChild("HumanoidRootPart") or targetPlr.Character:FindFirstChild("Torso")
						if myHrp and tHrp then
							myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 4)
						end
					end
				end)
				dismissNotif()
			end)

			local dismissBtn = Instance.new("TextButton", btnsFrame)
			dismissBtn.Size = UDim2.new(0, 48, 1, 0)
			dismissBtn.Position = UDim2.new(0, 48, 0, 0)
			dismissBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
			dismissBtn.Text = "Dismiss"
			dismissBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
			dismissBtn.Font = Enum.Font.GothamBold
			dismissBtn.TextSize = 9.5
			dismissBtn.BorderSizePixel = 0
			Instance.new("UICorner", dismissBtn).CornerRadius = UDim.new(0, 6)

			dismissBtn.MouseButton1Click:Connect(dismissNotif)
		end
	else

		local logo = Instance.new("ImageLabel", frame)
		logo.Size = UDim2.new(0, 32, 0, 32)
		logo.Position = UDim2.new(0, 23, 0.5, -16)
		logo.BackgroundTransparency = 1
		logo.Image = "rbxassetid://106790631609801"
		logo.ImageColor3 = Color3.fromRGB(255, 255, 255)

		local titleLbl = Instance.new("TextLabel", frame)
		titleLbl.Size = UDim2.new(1, -170, 0, 18)
		titleLbl.Position = UDim2.new(0, 75, 0, 18)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextSize = 12.5
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local descLbl = Instance.new("TextLabel", frame)
		descLbl.Size = UDim2.new(1, -170, 0, 32)
		descLbl.Position = UDim2.new(0, 75, 0, 38)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = desc
		descLbl.TextColor3 = Color3.fromRGB(170, 170, 185)
		descLbl.Font = Enum.Font.GothamMedium
		descLbl.TextSize = 11
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextWrapped = true

		local dismissBtn = Instance.new("TextButton", frame)
		dismissBtn.Size = UDim2.new(0, 75, 0, 26)
		dismissBtn.Position = UDim2.new(1, -90, 1, -38)
		dismissBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		dismissBtn.Text = "Dismiss"
		dismissBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
		dismissBtn.Font = Enum.Font.GothamBold
		dismissBtn.TextSize = 9.5
		dismissBtn.BorderSizePixel = 0
		Instance.new("UICorner", dismissBtn).CornerRadius = UDim.new(0, 5)

		dismissBtn.MouseButton1Click:Connect(dismissNotif)
	end

	tweenService:Create(dock, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -math.floor(targetWidth / 2), 0, 15),
		Size = UDim2.new(0, targetWidth, 0, targetHeight)
	}):Play()
	if corner then
		tweenService:Create(corner, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			CornerRadius = UDim.new(0, 12)
		}):Play()
	end
	task.spawn(function()
		task.wait(0.15)
		tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0
		}):Play()
	end)

	task.delay(displayTime, function()
		if not isDismissed then
			dismissNotif()
		end
	end)
end

function queueNotification(title, description, duration)
	local disableAll = checkSetting("disableallnotifs")
	if disableAll and disableAll.current then return end
	table.insert(islandNotificationQueue, {
		title = title,
		description = description,
		duration = duration or 3
	})
	task.spawn(processIslandNotifQueue)
end

function queueTargetActionNotification(targetPlayer, actionName)
	if not targetPlayer then return end
	local disableAll = checkSetting("disableallnotifs")
	if disableAll and disableAll.current then return end
	local key = targetPlayer.Name .. "_" .. actionName
	local now = tick()
	if lastActionNotifTime[key] and (now - lastActionNotifTime[key]) < 8 then
		return
	end
	lastActionNotifTime[key] = now

	table.insert(islandNotificationQueue, {
		title = targetPlayer.DisplayName .. " is getting " .. actionName .. "!",
		description = "@" .. targetPlayer.Name,
		duration = 5,
		targetPlayer = targetPlayer,
		actionName = actionName
	})
	task.spawn(processIslandNotifQueue)
end

updateIslandLayout = (function()
	if not IslandGroup then return end
	if _G.isShowingOwnerNotification or _G.isShowingIslandNotif or smartBarOpen or _G._slateCmdBarOpen then
		IslandGroup.Visible = false
		if ClockIcon then ClockIcon.Visible = false end
		if IslandTimeLabel then IslandTimeLabel.Visible = false end
		return
	end
	local isPlayingNow = (spotifyIsPlaying or _G.spotifyIsPlaying or _G.SlateSpotifyIsPlaying) == true
	local sas = IslandGroup:FindFirstChild("SpotifyActiveSong")
	local lag = IslandGroup:FindFirstChild("LiveAudioGraph")
	local targetSpotifyAlpha = isPlayingNow and 0 or 1
	local targetClockAlpha = isPlayingNow and 1 or 0

	if sas then sas.Visible = true end
	if lag then lag.Visible = true end
	if ClockIcon then ClockIcon.Visible = true end
	if IslandTimeLabel then IslandTimeLabel.Visible = true end

	if sas and IslandAlbumCover then
		tweenService:Create(IslandAlbumCover, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = targetSpotifyAlpha
		}):Play()
	end
	if lag then
		for _, bar in ipairs(lag:GetChildren()) do
			if bar:IsA("Frame") then
				tweenService:Create(bar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = targetSpotifyAlpha
				}):Play()
			end
		end
	end

	if ClockIcon then
		tweenService:Create(ClockIcon, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = targetClockAlpha
		}):Play()
	end
	if IslandTimeLabel then
		tweenService:Create(IslandTimeLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = targetClockAlpha
		}):Play()
	end

	task.delay(0.35, function()
		if not IslandGroup then return end
		local playingCheck = (spotifyIsPlaying or _G.spotifyIsPlaying or _G.SlateSpotifyIsPlaying) == true
		if playingCheck then
			if ClockIcon then ClockIcon.Visible = false end
			if IslandTimeLabel then IslandTimeLabel.Visible = false end
		else
			if sas then sas.Visible = false end
			if lag then lag.Visible = false end
		end
	end)
end)

_G.SlateSetSpotifyPlaying = function(isPlaying)
	spotifyIsPlaying = isPlaying
	_G.spotifyIsPlaying = isPlaying
	_G.SlateSpotifyIsPlaying = isPlaying
	if updateIslandLayout then updateIslandLayout() end
end

local slateBlurOverlay = Instance.new("TextButton")
slateBlurOverlay.Name = "SlateBlurOverlay"
slateBlurOverlay.Size = UDim2.new(1, 0, 1, 0)
slateBlurOverlay.Position = UDim2.new(0, 0, 0, 0)
slateBlurOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
slateBlurOverlay.BackgroundTransparency = 1
slateBlurOverlay.BorderSizePixel = 0
slateBlurOverlay.ZIndex = 1
slateBlurOverlay.Text = ""
slateBlurOverlay.AutoButtonColor = false
slateBlurOverlay.Visible = false
slateBlurOverlay.Parent = G2L["1"]
slateBlurOverlay.MouseButton1Click:Connect(function()
	if G2L["2"] and G2L["2"].Visible then
		local fade = tweenService:Create(G2L["2"], TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
		fade.Completed:Connect(function() G2L["2"].Visible = false end)
		fade:Play()
		local fadeBlur = tweenService:Create(slateBlurOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		fadeBlur.Completed:Connect(function() slateBlurOverlay.Visible = false end)
		fadeBlur:Play()
	end
end)
function showBlurOverlay()
	slateBlurOverlay.Visible = true
	slateBlurOverlay.BackgroundTransparency = 1
	tweenService:Create(slateBlurOverlay, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55}):Play()
end
function hideBlurOverlay()
	local t = tweenService:Create(slateBlurOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	t.Completed:Connect(function() slateBlurOverlay.Visible = false end)
	t:Play()
end

_smartBarOpenedAt = 0

function isMouseInSmartBarArea()
	local ok, inArea = pcall(function()
		local mPos = userInputService:GetMouseLocation()
		local cam = workspace.CurrentCamera
		if not cam then return false end
		local vp = cam.ViewportSize
		if not vp or vp.X <= 0 then return false end
		local midX = vp.X / 2
		-- The expanded dock reaches ~368-456px width (midX - 235 to midX + 235) and height up to ~65px.
		-- Top of screen to bottom of dock + margin: Y 0 to 120.
		return (mPos.X >= midX - 240) and (mPos.X <= midX + 240) and (mPos.Y >= 0) and (mPos.Y <= 120)
	end)
	return ok and inArea == true
end

function openSmartBar()
	if smartBarOpen or _G.isShowingOwnerNotification or _G._slateCmdBarOpen or _G.isShowingIslandNotif then return end
	smartBarOpen = true
	_smartBarOpenedAt = os.clock()

	if IslandGroup then IslandGroup.Visible = false end

	DockLogo.Visible = true

	task.spawn(function()
		task.wait(0.4)
		local outsideCount = 0
		while smartBarOpen and not _G._slateCmdBarOpen do
			task.wait(0.08)
			if smartBarOpen and not _G._slateCmdBarOpen then
				if os.clock() - _smartBarOpenedAt < 0.5 then
					outsideCount = 0
				elseif not isMouseInSmartBarArea() then
					outsideCount = outsideCount + 1
					if outsideCount >= 5 then
						if smartBarOpen and not _G._slateCmdBarOpen then
							closeSmartBar()
						end
						break
					end
				else
					outsideCount = 0
				end
			end
		end
	end)

	local hasGameConfig = false

	local isOwner = slateIsOwner or _G.SlateIsOwner == true
	local barWidth = isOwner and 210 or 166
	local halfWidth = barWidth / 2

	local offset = -44
	for _, data in ipairs(dockButtons) do
		local isVisible = true
		local btnX = 0
		if data.btn == NametagsBtn then
			btnX = 60
		elseif data.btn == OwnerBtn then
			btnX = 104
			isVisible = isOwner
		elseif data.btn == HomeBtn then
			btnX = 60

		elseif data.btn == CharacterBtn then
			btnX = 148 + offset
		elseif data.btn == CommandsBtn then
			btnX = 192 + offset
		elseif data.btn == PlayersBtn then
			btnX = 236 + offset
		elseif data.btn == MusicBtn then
			btnX = 280 + offset
		elseif data.btn == SettingsBtn then
			btnX = 324 + offset
		elseif data.btn == NametagsBtn then
			btnX = 368 + offset
		elseif data.btn == OwnerBtn then
			btnX = 412 + offset
			isVisible = isOwner
		elseif data.btn == CloudBtn then
			btnX = (isOwner and 456 or 412) + offset
		end

		data.btn.Visible = isVisible
		data.btn.ImageTransparency = 0
		data.pos = UDim2.new(0, btnX, 0.5, -14)
		data.btn.Position = data.pos + UDim2.new(0, 0, 0, 30)

		local hoverBg = data.btn:FindFirstChild("HoverBackground")
		if hoverBg then hoverBg.BackgroundTransparency = 1 end
	end

	if G2L["42"] then G2L["42"].Position = UDim2.new(1, -44, 0.68, 0) end
	if G2L["43"] then G2L["43"].Position = UDim2.new(1, -44, 0.32, 0) end

	tweenService:Create(G2L["30"], TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -halfWidth, 0, 15),
		Size = UDim2.new(0, barWidth, 0, 60)
	}):Play()
	tweenService:Create(G2L["31"], TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		CornerRadius = UDim.new(0, 10)
	}):Play()
	pcall(function()
		G2L["30"].GroupTransparency = 1
		tweenService:Create(G2L["30"], TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
	end)

	local idx = 1
	for _, data in ipairs(dockButtons) do
		if data.btn.Visible then
			task.spawn(function()
				task.wait(0.04 * (idx - 1))
				tweenService:Create(data.btn, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = data.pos}):Play()
			end)
			idx = idx + 1
		end
	end
	if G2L["42"] then G2L["42"].Visible = true end
	if G2L["43"] then G2L["43"].Visible = true end

	if G2L["2"].Visible then
		tweenService:Create(G2L["2"], TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
	end
end
function closeSmartBar()
	if not smartBarOpen then return end
	smartBarOpen = false
	_G.isShowingIslandNotif = false
	_G.isShowingOwnerNotification = false

	for _, data in ipairs(dockButtons) do
		pcall(function()
			tweenService:Create(data.btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
			local hoverBg = data.btn:FindFirstChild("HoverBackground")
			if hoverBg then
				tweenService:Create(hoverBg, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
			end
			task.spawn(function()
				task.wait(0.12)
				if not smartBarOpen then
					data.btn.Visible = false
				end
			end)
		end)
	end
	if DockLogo then DockLogo.Visible = false end
	if G2L["42"] then G2L["42"].Visible = false end
	if G2L["43"] then G2L["43"].Visible = false end

	pcall(function()
		tweenService:Create(G2L["30"], TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -58, 0, 15),
			Size = UDim2.new(0, 117, 0, 39)
		}):Play()
		tweenService:Create(G2L["31"], TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			CornerRadius = UDim.new(0, 30)
		}):Play()
	end)

	task.delay(0.2, function()
		if not smartBarOpen and IslandGroup then
			IslandGroup.Visible = true
			if updateIslandLayout then pcall(updateIslandLayout) end
		end
	end)
end

local _ownerUIState = slateIsOwner == true
function refreshOwnerUI()
	local isOwner = slateIsOwner or _G.SlateIsOwner == true
	if isOwner == _ownerUIState then return end
	_ownerUIState = isOwner
	if OwnerBtn then OwnerBtn.Visible = isOwner and smartBarOpen end

	if smartBarOpen then pcall(openSmartBar) end
end
_G.SlateRefreshOwnerUI = refreshOwnerUI

task.spawn(function()
	for _ = 1, 60 do
		task.wait(2)
		if _G.SlateIsOwner == true then
			refreshOwnerUI()
			return
		end
	end
end)

task.spawn(function()
  local _cmdBarOk, _cmdBarErr = pcall(function()

    local _uiWait = 0
    while not (G2L and G2L["1"] and G2L["30"]) and _uiWait < 30 do
        task.wait(0.1)
        _uiWait = _uiWait + 0.1
    end
    if not (G2L and G2L["1"] and G2L["30"]) then
        warn("[Slate] Command bar: the dock UI never appeared, aborting setup.")
        return
    end
    task.wait(0.2)
    local players = game:GetService("Players")
    local userInputService = game:GetService("UserInputService")
    local tweenService = tweenService
    local localPlayer = players.LocalPlayer

    local cmdBarOpen = false
    local cmdBarWidth = 420
    local cmdBarHalfW = cmdBarWidth / 2

    local SuggestionIsCanvas = false
    local SuggestionFrame
    do
        local okCG, cg = pcall(function() return Instance.new("CanvasGroup") end)
        if okCG and cg then
            cg:Destroy()
            SuggestionFrame = Instance.new("CanvasGroup", G2L["1"])
            SuggestionIsCanvas = true
        else
            SuggestionFrame = Instance.new("Frame", G2L["1"])
        end
    end
    SuggestionFrame.Name = "CmdSuggestions"
    SuggestionFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    SuggestionFrame.BorderSizePixel = 0
    SuggestionFrame.Size = UDim2.new(0, cmdBarWidth, 0, 0)
    SuggestionFrame.Position = UDim2.new(0.5, -cmdBarHalfW, 0, 75)
    SuggestionFrame.Visible = false
    if SuggestionIsCanvas then SuggestionFrame.GroupTransparency = 1 end
    SuggestionFrame.ZIndex = 900
    SuggestionFrame.ClipsDescendants = true
    local sugCorner = Instance.new("UICorner", SuggestionFrame)
    sugCorner.CornerRadius = UDim.new(0, 12)
    local sugStroke = Instance.new("UIStroke", SuggestionFrame)
    sugStroke.Color = Color3.fromRGB(65, 65, 75)
    sugStroke.Thickness = 1
    sugStroke.Transparency = 0.4

    local SuggestionScroll = Instance.new("ScrollingFrame", SuggestionFrame)
    SuggestionScroll.Name = "Scroll"
    SuggestionScroll.Size = UDim2.new(1, -12, 1, -12)
    SuggestionScroll.Position = UDim2.new(0, 6, 0, 6)
    SuggestionScroll.BackgroundTransparency = 1
    SuggestionScroll.BorderSizePixel = 0
    SuggestionScroll.ScrollBarThickness = 0
    SuggestionScroll.ScrollBarImageTransparency = 1
    SuggestionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SuggestionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SuggestionScroll.ZIndex = 901
    local sugLayout = Instance.new("UIListLayout", SuggestionScroll)
    sugLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sugLayout.Padding = UDim.new(0, 3)

    local CmdSearchIcon = Instance.new("ImageLabel", G2L["30"])
    CmdSearchIcon.Name = "CmdSearchIcon"
    CmdSearchIcon.Size = UDim2.new(0, 16, 0, 16)
    CmdSearchIcon.Position = UDim2.new(0, 16, 0.5, -8)
    CmdSearchIcon.BackgroundTransparency = 1
    CmdSearchIcon.Image = "rbxassetid://113204342754993"
    CmdSearchIcon.ImageColor3 = Color3.fromRGB(150, 150, 160)
    CmdSearchIcon.Visible = false
    CmdSearchIcon.ZIndex = 951

    local CmdSearchBox = Instance.new("TextBox", G2L["30"])
    CmdSearchBox.Name = "CmdSearchBox"
    CmdSearchBox.Size = UDim2.new(1, -54, 0, 30)
    CmdSearchBox.Position = UDim2.new(0, 42, 0.5, -15)
    CmdSearchBox.BackgroundTransparency = 1
    CmdSearchBox.Text = ""
    CmdSearchBox.PlaceholderText = "Type a command..."
    CmdSearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
    CmdSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    CmdSearchBox.TextSize = 14
    CmdSearchBox.Font = Enum.Font.GothamMedium
    CmdSearchBox.TextXAlignment = Enum.TextXAlignment.Left
    CmdSearchBox.ClearTextOnFocus = false
    CmdSearchBox.Visible = false
    CmdSearchBox.ZIndex = 950

    local topMatchCmd = nil
    local currentSugHeight = 0

    local function clearSuggestions()
        for _, c in ipairs(SuggestionScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end

    local function animateSuggestionHeight(h)
        if h == currentSugHeight then return end
        currentSugHeight = h
        if h > 0 then
            SuggestionFrame.Visible = true
            local goal = { Size = UDim2.new(0, cmdBarWidth, 0, h) }
            if SuggestionIsCanvas then goal.GroupTransparency = 0 end
            tweenService:Create(SuggestionFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
        else
            local goal = { Size = UDim2.new(0, cmdBarWidth, 0, 0) }
            if SuggestionIsCanvas then goal.GroupTransparency = 1 end
            local tw = tweenService:Create(SuggestionFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), goal)
            tw:Play()
            tw.Completed:Connect(function()
                if currentSugHeight == 0 then SuggestionFrame.Visible = false end
            end)
        end
    end

    local function updateSuggestions(text)
        clearSuggestions()
        local textClean = tostring(text or ""):gsub("^[%./!;:]+", "")
        if textClean == "" then
            topMatchCmd = nil
            animateSuggestionHeight(0)
            return
        end

        local matches = {}
        local seenNames = {}
        local parts = {}
        for part in textClean:gmatch("%S+") do table.insert(parts, part) end
        local query = (parts[1] or ""):lower()

        if onyxCommands then
            for _, cmd in ipairs(onyxCommands) do
                local name = (cmd.name or ""):lower()
                local matched = false
                if name:sub(1, #query) == query or name:find(query, 1, true) then
                    matched = true
                elseif cmd.aliases then
                    for _, a in ipairs(cmd.aliases) do
                        local al = tostring(a):lower()
                        if al:sub(1, #query) == query or al:find(query, 1, true) then
                            matched = true
                            break
                        end
                    end
                end
                if matched and not seenNames[name] then
                    seenNames[name] = true
                    table.insert(matches, cmd)
                    if #matches >= 12 then break end
                end
            end
        end

        if #matches == 0 then
            topMatchCmd = nil
            animateSuggestionHeight(0)
            return
        end

        topMatchCmd = matches[1]
        local itemH = 30
        local totalH = math.min(#matches * (itemH + 2) + 8, 200)
        animateSuggestionHeight(totalH)

        for i, cmd in ipairs(matches) do
            local btn = Instance.new("TextButton", SuggestionScroll)
            btn.Size = UDim2.new(1, 0, 0, itemH)
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            btn.BackgroundTransparency = 1
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.ZIndex = 902
            btn.LayoutOrder = i
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            local displayName = cmd.name or ""
            local displayDesc = cmd.desc or ""
            local lbl = Instance.new("TextLabel", btn)
            lbl.Size = UDim2.new(1, -16, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = displayName .. "  —  " .. displayDesc
            lbl.TextColor3 = Color3.fromRGB(170, 170, 175)
            lbl.TextSize = 11.5
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = 903

            btn.MouseEnter:Connect(function()
                tweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(35, 35, 40)}):Play()
                lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            end)
            btn.MouseLeave:Connect(function()
                tweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 1}):Play()
                lbl.TextColor3 = Color3.fromRGB(170, 170, 175)
            end)
            btn.MouseButton1Down:Connect(function()
                local cmdName = cmd.name or ""
                closeCmdBar()
                task.spawn(function()
                    if _IY_execCmd then _IY_execCmd(cmdName) end
                end)
            end)
        end
        SuggestionScroll.CanvasSize = UDim2.new(0, 0, 0, sugLayout.AbsoluteContentSize.Y)
    end

    function openCmdBar()
        if cmdBarOpen then return end
        if smartBarOpen then closeSmartBar() end
        cmdBarOpen = true
        _G._slateCmdBarOpen = true

        pcall(function()
            for _, child in ipairs(G2L["30"]:GetChildren()) do
                if child.Name == "IslandNotifyFrame" or child.Name == "OwnerNotify" then
                    child:Destroy()
                end
            end
        end)
        _G.isShowingIslandNotif = false
        _G.isShowingOwnerNotification = false

        if IslandGroup then IslandGroup.Visible = false end

        CmdSearchBox.Text = ""
        CmdSearchBox.Visible = true
        if CmdSearchIcon then CmdSearchIcon.Visible = true end

        for _, data in ipairs(dockButtons) do
            data.btn.Visible = false
        end
        if DockLogo then DockLogo.Visible = false end
        if G2L["42"] then G2L["42"].Visible = false end
        if G2L["43"] then G2L["43"].Visible = false end

        tweenService:Create(G2L["30"], TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -cmdBarHalfW, 0, 15),
            Size = UDim2.new(0, cmdBarWidth, 0, 48)
        }):Play()
        tweenService:Create(G2L["31"], TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            CornerRadius = UDim.new(0, 10)
        }):Play()
        pcall(function()
            if G2L["30"].GroupTransparency then
                G2L["30"].GroupTransparency = 1
                tweenService:Create(G2L["30"], TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
            end
        end)

        task.delay(0.05, function()
            pcall(function() CmdSearchBox:CaptureFocus() end)
        end)
        clearSuggestions()
        animateSuggestionHeight(0)
    end

    function closeCmdBar()
        if not cmdBarOpen then return end
        cmdBarOpen = false
        _G._slateCmdBarOpen = false

        CmdSearchBox:ReleaseFocus()
        CmdSearchBox.Text = ""
        CmdSearchBox.Visible = false
        if CmdSearchIcon then CmdSearchIcon.Visible = false end
        animateSuggestionHeight(0)

        tweenService:Create(G2L["30"], TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -58, 0, 15),
            Size = UDim2.new(0, 117, 0, 39)
        }):Play()
        tweenService:Create(G2L["31"], TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            CornerRadius = UDim.new(0, 30)
        }):Play()

        task.delay(0.3, function()
            if not cmdBarOpen and not smartBarOpen then
                if IslandGroup then IslandGroup.Visible = true end
                pcall(processIslandNotifQueue)
            end
        end)
    end

    _G._slateToggleCmdBar = function()
        if cmdBarOpen then closeCmdBar() else openCmdBar() end
    end

    userInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local keyName
        pcall(function()
            local st = checkSetting and checkSetting("cmdbar")
            keyName = st and st.current
        end)
        if not keyName or keyName == "" or keyName == "None" then keyName = "Semicolon" end
        pcall(function()
            if input.KeyCode == Enum.KeyCode[keyName] then
                if cmdBarOpen then closeCmdBar() else openCmdBar() end
            end
        end)
    end)

    CmdSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if cmdBarOpen then
            updateSuggestions(CmdSearchBox.Text)
        end
    end)

    userInputService.InputBegan:Connect(function(input, gpe)
        if not cmdBarOpen or gpe then return end
        if input.KeyCode == Enum.KeyCode.Tab then
            if topMatchCmd then
                CmdSearchBox.Text = (topMatchCmd.name or "") .. " "
                CmdSearchBox.CursorPosition = #CmdSearchBox.Text + 1
            end
        end
    end)

    CmdSearchBox.FocusLost:Connect(function(enterPressed)
        if not cmdBarOpen then return end
        if enterPressed then
            local rawText = CmdSearchBox.Text or ""
            local trimmed = rawText:match("^%s*(.-)%s*$") or ""
            if trimmed ~= "" then
                local cleanText = trimmed:gsub("^[%./!;:]+", "")
                local parts = {}
                for part in cleanText:gmatch("%S+") do table.insert(parts, part) end
                local query = (parts[1] or ""):lower()
                local args = #parts > 1 and table.concat(parts, " ", 2) or ""

                local execCmdName = query
                local foundExact = false

                if onyxCommands then
                    for _, c in ipairs(onyxCommands) do
                        if c.name and c.name:lower() == query then
                            execCmdName = c.name
                            foundExact = true
                            break
                        elseif c.aliases then
                            for _, a in ipairs(c.aliases) do
                                if tostring(a):lower() == query then
                                    execCmdName = tostring(a)
                                    foundExact = true
                                    break
                                end
                            end
                        end
                        if foundExact then break end
                    end
                end

                if not foundExact and onyxAliases and onyxAliases[query] then
                    execCmdName = query
                    foundExact = true
                end

                if not foundExact and topMatchCmd and topMatchCmd.name then
                    local topName = topMatchCmd.name:lower()
                    if topName:sub(1, #query) == query then
                        execCmdName = topMatchCmd.name
                    end
                end

                local finalExec = execCmdName .. (args ~= "" and (" " .. args) or "")
                closeCmdBar()
                task.spawn(function()
                    if _IY_execCmd then _IY_execCmd(finalExec) end
                end)
                return
            end
            closeCmdBar()
        end
    end)

    userInputService.InputBegan:Connect(function(input)
        if cmdBarOpen and input.KeyCode == Enum.KeyCode.Escape then
            closeCmdBar()
        end
    end)

    userInputService.InputBegan:Connect(function(input)
        if not cmdBarOpen then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local function insideFrame(frame)
                if not frame or not frame.Visible then return false end
                local ap, asz = frame.AbsolutePosition, frame.AbsoluteSize
                return pos.X >= ap.X and pos.X <= ap.X + asz.X
                    and pos.Y >= ap.Y and pos.Y <= ap.Y + asz.Y
            end
            if not insideFrame(G2L["30"]) and not insideFrame(SuggestionFrame) then
                closeCmdBar()
            end
        end
    end)

    local function isCmdBarPhrase(msg)
        msg = tostring(msg or ""):lower()
        return msg == "/cmd" or msg == "!cmd" or msg == ".cmd"
    end

    localPlayer.Chatted:Connect(function(msg)
        if isCmdBarPhrase(msg) then
            if cmdBarOpen then closeCmdBar() else openCmdBar() end
        end
    end)

    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
        local bar = tcs:FindFirstChildOfClass("ChatInputBarConfiguration")
        local channels = tcs:WaitForChild("TextChannels", 5)
        if not channels then return end
        local function hookChannel(ch)
            if not ch:IsA("TextChannel") then return end
            ch.MessageReceived:Connect(function(textChatMessage)
                local src = textChatMessage.TextSource
                if not src or src.UserId ~= localPlayer.UserId then return end
                if isCmdBarPhrase(textChatMessage.Text) then
                    if cmdBarOpen then closeCmdBar() else openCmdBar() end
                end
            end)
        end
        for _, ch in ipairs(channels:GetChildren()) do hookChannel(ch) end
        channels.ChildAdded:Connect(hookChannel)
    end)
  end)
  if not _cmdBarOk then
    warn("[Slate] Command bar setup failed: " .. tostring(_cmdBarErr))
  end
end)

local activeTab
SlateNav = { rows = {} }

function SlateNav.build()
	if SlateNav.frame then return SlateNav.frame end

	local W = SLATE_SIDEBAR_W
	local ROW_H, ROW_GAP, TOP = 38, 5, 94
	local ROW_X, ROW_W = 12, W - 24

	local bar = Instance.new("Frame", G2L["2"])
	bar.Name = "Sidebar"
	bar.Size = UDim2.new(0, W, 0.98538, 0)
	bar.Position = UDim2.new(0.00561, 0, 0.00883, 0)
	bar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.ZIndex = 2
	SlateNav.frame = bar

	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)

	pcall(function()
		if G2L["2e"] then
			G2L["2e"].Parent = bar
			G2L["2e"].Position = UDim2.new(0, 20, 0, 20)
			G2L["2e"].Size = UDim2.new(0, 40, 0, 42)
			G2L["2e"].ZIndex = 5
		end
	end)

	local wordmark = Instance.new("TextLabel", bar)
	wordmark.Size = UDim2.new(0, 100, 0, 28)
	wordmark.Position = UDim2.new(0, 68, 0, 27)
	wordmark.BackgroundTransparency = 1
	wordmark.Text = "SLATE"
	wordmark.TextColor3 = Color3.fromRGB(255, 255, 255)
	wordmark.TextSize = 22
	wordmark.Font = Enum.Font.BuilderSansBold
	wordmark.TextXAlignment = Enum.TextXAlignment.Left
	wordmark.ZIndex = 4

	local items = {
		{ name = "Home",      icon = 131020769964098, tab = function() return G2L["6"] end },
		{ name = "Character", icon = 77913721129068,  tab = function() return CharacterTab end },
		{ name = "Commands",  icon = 132715960634165, tab = function() return CommandsTab end },
		{ name = "Players",   icon = 128832612895005, tab = function() return PlayersTab end },
		{ name = "Music",     icon = 76273968889626,  tab = function() return MusicTab end },
		{ name = "Settings",  icon = 140667076868313, tab = function() return SettingsTab end },
	}

	local y = TOP
	for _, item in ipairs(items) do
		if not (item.ownerOnly and not (slateIsOwner or _G.SlateIsOwner == true)) then
			local row = Instance.new("TextButton", bar)
			row.Name = item.name .. "NavRow"
			row.Size = UDim2.new(0, ROW_W, 0, ROW_H)
			row.Position = UDim2.new(0, ROW_X, 0, y)
			row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			row.BackgroundTransparency = 1
			row.BorderSizePixel = 0
			row.Text = ""
			row.AutoButtonColor = false
			row.ZIndex = 4
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

			local icon = Instance.new("ImageLabel", row)
			icon.Size = UDim2.new(0, 24, 0, 24)
			icon.Position = UDim2.new(0, 14, 0.5, -12)
			icon.BackgroundTransparency = 1
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Image = "rbxthumb://type=Asset&id=" .. tostring(item.icon) .. "&w=420&h=420"
			icon.ImageColor3 = Color3.fromRGB(150, 150, 158)
			icon.ZIndex = 5

			local label = Instance.new("TextLabel", row)
			label.Size = UDim2.new(1, -52, 1, 0)
			label.Position = UDim2.new(0, 48, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = item.name
			label.TextColor3 = Color3.fromRGB(160, 160, 168)
			label.TextSize = 15
			label.Font = Enum.Font.BuilderSans
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 5

			local rec = {
				item = item, row = row, icon = icon, label = label,
				baseSize = UDim2.new(0, ROW_W, 0, ROW_H),
				basePos  = UDim2.new(0, ROW_X, 0, y),
				bigSize  = UDim2.new(0, ROW_W + 6, 0, ROW_H + 4),
				bigPos   = UDim2.new(0, ROW_X - 3, 0, y - 2),
				hovering = false,
			}
			SlateNav.rows[#SlateNav.rows + 1] = rec

			local function isActive()
				if item.lit then return item.lit() end
				if item.tab then
					local t = item.tab()
					return t ~= nil and activeTab == t and G2L["2"].Visible
				end
				return false
			end
			rec.isActive = isActive

			row.MouseEnter:Connect(function()
				rec.hovering = true
				tweenService:Create(row, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = rec.bigSize, Position = rec.bigPos,
					BackgroundTransparency = isActive() and 0.86 or 0.94,
				}):Play()
				tweenService:Create(icon, TweenInfo.new(0.16), {
					Size = UDim2.new(0, 26, 0, 26),
					ImageColor3 = Color3.fromRGB(255, 255, 255),
				}):Play()
				icon.Position = UDim2.new(0, 14, 0.5, -13)
				tweenService:Create(label, TweenInfo.new(0.16), {
					TextColor3 = Color3.fromRGB(255, 255, 255),
				}):Play()
			end)

			row.MouseLeave:Connect(function()
				rec.hovering = false
				SlateNav.paintRow(rec)
			end)

			row.MouseButton1Click:Connect(function()
				SlateUiSound.click()
				if item.action then
					item.action()
				elseif item.tab then
					local t = item.tab()
					if t then switchTab(t) end
				end
				SlateNav.paint()
			end)

			y = y + ROW_H + ROW_GAP
		end
	end

	local lp = game:GetService("Players").LocalPlayer
	local profileRow = Instance.new("Frame", bar)
	profileRow.Name = "RobloxProfileRow"
	profileRow.Size = UDim2.new(0, ROW_W, 0, 54)
	profileRow.Position = UDim2.new(0, ROW_X, 1, -66)
	profileRow.BackgroundTransparency = 1
	profileRow.BorderSizePixel = 0
	profileRow.ZIndex = 4

	local pfp = Instance.new("ImageLabel", profileRow)
	pfp.Name = "RobloxAvatar"
	pfp.Size = UDim2.new(0, 40, 0, 40)
	pfp.Position = UDim2.new(0, 6, 0.5, -20)
	pfp.BackgroundTransparency = 1
	pfp.ZIndex = 5
	local pfpCorner = Instance.new("UICorner", pfp)
	pfpCorner.CornerRadius = UDim.new(0, 20)
	pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=150&h=150"

	local dispLabel = Instance.new("TextLabel", profileRow)
	dispLabel.Size = UDim2.new(1, -64, 0.45, 0)
	dispLabel.Position = UDim2.new(0, 54, 0.16, 0)
	dispLabel.BackgroundTransparency = 1
	dispLabel.Text = lp.DisplayName
	dispLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	dispLabel.TextSize = 14
	dispLabel.Font = Enum.Font.BuilderSansBold
	dispLabel.TextXAlignment = Enum.TextXAlignment.Left
	dispLabel.TextTruncate = Enum.TextTruncate.AtEnd
	dispLabel.ZIndex = 5

	local userLabel = Instance.new("TextLabel", profileRow)
	userLabel.Size = UDim2.new(1, -64, 0.45, 0)
	userLabel.Position = UDim2.new(0, 54, 0.52, 0)
	userLabel.BackgroundTransparency = 1
	userLabel.Text = "@" .. lp.Name
	userLabel.TextColor3 = Color3.fromRGB(150, 150, 155)
	userLabel.TextSize = 12
	userLabel.Font = Enum.Font.BuilderSans
	userLabel.TextXAlignment = Enum.TextXAlignment.Left
	userLabel.TextTruncate = Enum.TextTruncate.AtEnd
	userLabel.ZIndex = 5

	return bar
end

function SlateNav.paintRow(rec)
	if rec.hovering then return end
	local active = rec.isActive and rec.isActive() or false
	tweenService:Create(rec.row, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = rec.baseSize, Position = rec.basePos,
		BackgroundTransparency = active and 0.9 or 1,
	}):Play()
	tweenService:Create(rec.icon, TweenInfo.new(0.16), {
		Size = UDim2.new(0, 24, 0, 24),
		ImageColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 158),
	}):Play()
	rec.icon.Position = UDim2.new(0, 14, 0.5, -12)
	tweenService:Create(rec.label, TweenInfo.new(0.16), {
		TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 168),
	}):Play()
	rec.label.Font = active and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans
end

function SlateNav.paint()
	for _, rec in ipairs(SlateNav.rows) do
		pcall(SlateNav.paintRow, rec)
	end
end

function switchTab(tab)
	if not tab then return end
	local main = G2L and G2L["2"]
	if main then
		for _, child in ipairs(main:GetChildren()) do
			if child:IsA("CanvasGroup") or child:IsA("Frame") then
				if child ~= tab and child.Name ~= "HeaderBar" and child.Name ~= "Backdrop" and child.Name ~= "SlateBackdrop" and not child.Name:find("Sidebar") and not child.Name:find("Nav") then
					child.Visible = false
					if child:IsA("CanvasGroup") then
						child.GroupTransparency = 1
					end
				end
			end
		end
	end

	activeTab = tab
	tab.Visible = true
	tab.ZIndex = 2

	if not main or not main.Visible or main.GroupTransparency > 0.9 then
		tab.GroupTransparency = 0
		if main then
			main.Visible = true
			main.GroupTransparency = 1
			tweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
		end
		showBlurOverlay()
		if SlateNav and SlateNav.paint then task.defer(SlateNav.paint) end
		return
	end

	if SlateNav and SlateNav.paint then task.defer(SlateNav.paint) end
	if tab.GroupTransparency > 0 then
		tweenService:Create(tab, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
	end
end

function toggleMainWindow()
	local main = G2L and G2L["2"]
	if not main then return end

	if main.Visible and main.GroupTransparency < 0.1 then
		local fade = tweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{GroupTransparency = 1})
		fade.Completed:Connect(function() main.Visible = false end)
		fade:Play()
		pcall(hideBlurOverlay)
		return false
	end

	pcall(SlateNav.build)
	local target = activeTab or (G2L and G2L["6"])
	if target then
		switchTab(target)
	else
		main.Visible = true
		main.GroupTransparency = 1
		tweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{GroupTransparency = 0}):Play()
		pcall(showBlurOverlay)
	end
	pcall(SlateNav.paint)
	return true
end

_G.SlateToggleUI = toggleMainWindow

function toggleWindow(win)
	if win.Visible and win.GroupTransparency < 0.1 then
		local fade = tweenService:Create(win, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
		fade.Completed:Connect(function() win.Visible = false end)
		fade:Play()
	else
		win.Visible = true
		win.GroupTransparency = 1
		tweenService:Create(win, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
	end
end

function addLabel(parent, text, size, pos, isTitle)
	local lbl = Instance.new("TextLabel")
	lbl.BorderSizePixel = 0
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextSize = isTitle and 22 or 14
	lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", isTitle and Enum.FontWeight.Bold or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	lbl.Size = size
	lbl.Position = pos
	lbl.Text = text
	lbl.Parent = parent
	if not isTitle then
		lbl.TextTransparency = 0.4
	end
	return lbl
end

local _currentThemeMain = Color3.fromRGB(13, 13, 15)
local _currentThemeAccent = Color3.fromRGB(255, 255, 255)

local _themeToggleElements = {}

function registerThemeStroke(stroke)
	if stroke then table.insert(_themeAccentStrokes, stroke) end
end
function registerThemeToggle(btn)
	if btn then table.insert(_themeToggleElements, btn) end
end


local function color3ToHex(c)
	LPS_ATTRIBUTES(INLINE())
	return string.format("#%02X%02X%02X", math.round(c.R*255), math.round(c.G*255), math.round(c.B*255))
end

SLATE_SIDEBAR_W = 160
SLATE_CONTENT_W = 620
SLATE_WINDOW_H  = 470
SLATE_TAB_H     = 430

function createTabFrame(name)
	local cg = Instance.new("CanvasGroup", G2L["2"])
	cg.Name = name
	cg.BorderSizePixel = 0
	cg.BackgroundTransparency = 1
	cg.Size = UDim2.new(1, -SLATE_SIDEBAR_W, 0, SLATE_TAB_H)
	cg.Position = UDim2.new(0, SLATE_SIDEBAR_W, 0, (SLATE_WINDOW_H - SLATE_TAB_H) / 2)
	cg.Visible = false

	local overlay = Instance.new("Frame", cg)
	overlay.Name = "UnavailableOverlay"
	overlay.Size = UDim2.new(1, -15, 1, -70)
	overlay.Position = UDim2.new(0, 5, 0, 55)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0
	overlay.Active = true
	overlay.ZIndex = 9999
	overlay.Visible = false

	local corner = Instance.new("UICorner", overlay)
	corner.CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel", overlay)
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(220, 220, 225)
	title.TextSize = 22
	title.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	title.Text = "Currently Unavailable"
	title.ZIndex = 10000

	local function checkInitial()
		local cleanName = name:gsub("Tab$", "")
		local isUnavailable = false
		if _G.SlateUnavailableTabs then
			if _G.SlateUnavailableTabs[name] or _G.SlateUnavailableTabs[cleanName] then
				isUnavailable = true
			end
		end
		overlay.Visible = isUnavailable
	end
	checkInitial()

	task.spawn(function()
		local cleanName = name:gsub("Tab$", "")
		while task.wait(0.5) do
			local isUnavailable = false
			if _G.SlateUnavailableTabs then
				if _G.SlateUnavailableTabs[name] or _G.SlateUnavailableTabs[cleanName] then
					isUnavailable = true
				end
			end
			overlay.Visible = isUnavailable
		end
	end)

	return cg
end

function createStandaloneWindow(name, titleText, size)
	local win = Instance.new("CanvasGroup", G2L["1"])
	win.Name = name
	win.BorderSizePixel = 0
	win.Size = size or UDim2.new(0, 500, 0, 350)
	win.Position = UDim2.new(0.5, -win.Size.X.Offset/2, 0.4, -win.Size.Y.Offset/2)
	win.Active = true
	win.BackgroundTransparency = 1
	win.Visible = false

	local bg = createSlateBackdrop(win, 16, { zIndex = 0 })
	bg.Name = "Background"

	local stroke = Instance.new("UIStroke", win)
	stroke.Thickness = 1.2
	stroke.Color = Color3.fromRGB(40, 40, 42)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local strokeGrad = Instance.new("UIGradient", stroke)
	strokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 125)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 64)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 205))
	})
	strokeGrad.Rotation = 90
	local winCorner = Instance.new("UICorner", win)
	winCorner.CornerRadius = UDim.new(0, 16)

	local header = Instance.new("Frame", win)
	header.Name = "HeaderBar"
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	local title = Instance.new("TextLabel", header)
	title.Text = titleText
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	title.Position = UDim2.new(0, 14, 0, 0)
	title.Size = UDim2.new(0, 200, 1, 0)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	local close = Instance.new("TextButton", win)
	close.Name = "CloseBtn"
	close.Active = true
	close.AutoButtonColor = false
	close.Text = "\u{00D7}"
	close.TextSize = 16
	close.TextColor3 = Color3.fromRGB(150, 150, 160)
	close.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	close.Size = UDim2.new(0, 24, 0, 24)
	close.Position = UDim2.new(1, -32, 0, 8)
	close.BackgroundTransparency = 1
	close.BorderSizePixel = 0
	close.ZIndex = 20
	close.MouseEnter:Connect(function()
		tweenService:Create(close, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
	end)
	close.MouseLeave:Connect(function()
		tweenService:Create(close, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(150, 150, 160)}):Play()
	end)
	local function doClose()
		toggleWindow(win)
	end
	close.MouseButton1Click:Connect(doClose)
	close.Activated:Connect(doClose)
	makeDraggable(header, win)

	local content = Instance.new("Frame", win)
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -40)
	content.Position = UDim2.new(0, 0, 0, 40)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	return content, win
end

SlateUiSound = {
	id = "rbxassetid://94859356677805",
	volume = 0.45,
}

function SlateUiSound.get()
	if SlateUiSound.instance and SlateUiSound.instance.Parent then
		return SlateUiSound.instance
	end
	local ok, snd = pcall(function()
		local s = Instance.new("Sound")
		s.Name = "SlateUiClick"
		s.SoundId = SlateUiSound.id
		s.Volume = SlateUiSound.volume
		s.Parent = game:GetService("SoundService")
		return s
	end)
	if ok then SlateUiSound.instance = snd end
	return SlateUiSound.instance
end

function SlateUiSound.click()
	local pref = checkSetting and checkSetting("hoversound")
	if pref and pref.current == false then return end
	local snd = SlateUiSound.get()
	if not snd then return end
	pcall(function()
		snd.TimePosition = 0
		snd:Play()
	end)
end

function makeDraggable(clickFrame, parentFrame)
	parentFrame = parentFrame or clickFrame
	local dragging = false
	local startMouse = Vector2.new(0, 0)
	local startPos = UDim2.new(0, 0, 0, 0)
	clickFrame.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if userInputService:GetFocusedTextBox() then return end
		startPos = parentFrame.Position
		startMouse = userInputService:GetMouseLocation()
		dragging = true
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
			end)
		end)
	userInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local mouse = userInputService:GetMouseLocation()
		local delta = mouse - startMouse
		local screenGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
		local viewport = screenGui and screenGui.AbsoluteSize or Vector2.new(1920, 1080)
		if viewport.X < 100 or viewport.Y < 100 then
			viewport = Vector2.new(1920, 1080)
		end
		local size = parentFrame.AbsoluteSize
		local ap = parentFrame.AnchorPoint

		local minX = -startPos.X.Scale * viewport.X + (size.X * ap.X)
		local maxX = viewport.X - (size.X * (1 - ap.X)) - startPos.X.Scale * viewport.X
		local newX = math.clamp(startPos.X.Offset + delta.X, minX, math.max(minX, maxX))
		local minY = -startPos.Y.Scale * viewport.Y + (size.Y * ap.Y)
		local maxY = viewport.Y - (size.Y * (1 - ap.Y)) - startPos.Y.Scale * viewport.Y
		local newY = math.clamp(startPos.Y.Offset + delta.Y, minY, math.max(minY, maxY))
		parentFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
	end)
end

function makeResizable(frame, minSize)
	minSize = minSize or Vector2.new(150, 150)

	local handle = Instance.new("ImageButton", frame)
	handle.Name = "ResizeHandle"
	handle.Size = UDim2.new(0, 14, 0, 14)
	handle.Position = UDim2.new(1, -14, 1, -14)
	handle.BackgroundTransparency = 1
	handle.Image = "rbxthumb://type=Asset&id=118191845701573&w=150&h=150"
	handle.ImageColor3 = Color3.fromRGB(150, 150, 150)
	handle.ZIndex = 99

	local dragging = false
	local dragStart = Vector2.new()
	local startSize = UDim2.new()

	handle.InputBegan:Connect(function(input)
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

	end
do
	G2L["1"] = Instance.new("ScreenGui");
	G2L["1"]["Name"] = [[SlateUi]];
	G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;
	G2L["1"]["IgnoreGuiInset"] = true;
	G2L["1"]["ResetOnSpawn"] = false;
	pcall(function() G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.None end)
	-- Parent deferred until UI tree is fully built (see _slateParentGui below)

	-- DescendantAdded deferred until after UI tree is built to avoid 865+ callback fires during init

	G2L["2"] = Instance.new("CanvasGroup", G2L["1"]);
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Size"] = UDim2.new(0, SLATE_CONTENT_W + SLATE_SIDEBAR_W, 0, SLATE_WINDOW_H);
	G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["2"]["Name"] = [[MainContainer]];
	G2L["2"]["Active"] = true;
	G2L["2"]["ZIndex"] = 1;
	G2L["2"]["Visible"] = false;
	G2L["2"]["BackgroundTransparency"] = 1;

	local function syncShadow() end

	local SLATE_UI_SCALE = 0.88

	local function updateScale()
		local viewport = workspace.CurrentCamera.ViewportSize
		local scaleFactor = 1
		local targetWidth = SLATE_CONTENT_W + SLATE_SIDEBAR_W
		local targetHeight = SLATE_WINDOW_H
		local margin = 40
		if viewport.X < (targetWidth + margin) or viewport.Y < (targetHeight + margin) then
			local scaleX = viewport.X / (targetWidth + margin)
			local scaleY = viewport.Y / (targetHeight + margin)
			scaleFactor = math.min(scaleX, scaleY)
		end
		scaleFactor = math.clamp(scaleFactor, 0.4, 1.0)
		local uiScale = G2L["2"]:FindFirstChild("SlateUIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Name = "SlateUIScale"
			uiScale.Parent = G2L["2"]
		end
		uiScale.Scale = scaleFactor * SLATE_UI_SCALE
		syncShadow()
	end

	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	G2L["2"]:GetPropertyChangedSignal("Visible"):Connect(updateScale)
	G2L["2"]:GetPropertyChangedSignal("Position"):Connect(syncShadow)
	G2L["2"]:GetPropertyChangedSignal("Visible"):Connect(syncShadow)
	updateScale()

	local Backdrop = Instance.new("ImageLabel", G2L["2"])
	Backdrop.Name = "Backdrop"
	Backdrop.ZIndex = 1
	Backdrop.BorderSizePixel = 0
	Backdrop.AnchorPoint = Vector2.new(0.5, 0.5)
	Backdrop.Image = "rbxassetid://70478974816232"
	Backdrop.Size = UDim2.new(0.9904, 0, 0.98538, 0)
	Backdrop.BackgroundTransparency = 1
	Backdrop.Position = UDim2.new(0.50081, 0, 0.50152, 0)

	createSlateBackdrop(G2L["2"], 12, {
		size = UDim2.new(0.9904, 0, 0.98538, 0),
		position = UDim2.new(0.50081, 0, 0.50152, 0),
		anchorPoint = Vector2.new(0.5, 0.5),
		zIndex = 1,
	})

	_G.SlateSetBackdropTone = function(inkHex, violetHex, liftHex)
		pcall(function()
			local p = SlateBackdrop.palette
			if inkHex then
				p.ink = hexToColor3(inkHex)
				p.shade = p.ink:Lerp(Color3.fromRGB(0, 0, 0), 0.4)
			end
			if violetHex then
				p.violet = hexToColor3(violetHex)
				p.mid = p.violet:Lerp(Color3.fromRGB(0, 0, 0), 0.56)
				p.deep = p.violet:Lerp(Color3.fromRGB(0, 0, 0), 0.86)
				p.bright = p.violet:Lerp(Color3.fromRGB(255, 255, 255), 0.16)
			end
			if liftHex then
				p.lift = hexToColor3(liftHex)
				p.spark = p.lift:Lerp(Color3.fromRGB(255, 255, 255), 0.30)
			end
			SlateBackdrop.refresh()
		end)
	end

	local Header = Instance.new("Frame", G2L["2"])
	Header.Name = "HeaderBar"
	Header.Size = UDim2.new(1, 0, 0, 45)
	Header.Position = UDim2.new(0, 0, 0, 0)
	Header.BackgroundTransparency = 1
	Header.BorderSizePixel = 0
	local Title = Instance.new("TextLabel", Header)
	Title.Name = "Title"
	Title.Text = "SLATE"
	Title.Visible = false
	local CloseBtn = Instance.new("TextButton", Header)
	CloseBtn.Name = "CloseBtn"
	CloseBtn.Visible = true
	CloseBtn.Active = true
	CloseBtn.Text = "×"
	CloseBtn.TextSize = 16
	CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 160)
	CloseBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	CloseBtn.Size = UDim2.new(0, 24, 0, 24)
	CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.BorderSizePixel = 0
	CloseBtn.MouseEnter:Connect(function()
		tweenService:Create(CloseBtn, TweenInfo.new(0.15), {
			TextColor3 = Color3.fromRGB(200, 200, 200)
		}):Play()
	end)
	CloseBtn.MouseLeave:Connect(function()
		tweenService:Create(CloseBtn, TweenInfo.new(0.15), {
			TextColor3 = Color3.fromRGB(150, 150, 160)
		}):Play()
	end)
	MainCloseBtn = CloseBtn
	G2L["3"] = Instance.new("ImageLabel", G2L["2"]);
	G2L["3"]["ZIndex"] = 0;
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["ImageTransparency"] = 1;
	G2L["3"]["Image"] = [[]];
	G2L["3"]["Visible"] = false;
	G2L["3"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["3"]["BackgroundTransparency"] = 1;
	G2L["3"]["Name"] = [[BackgroundImage]];
	G2L["4"] = Instance.new("UICorner", G2L["3"]);

	G2L["6"] = createTabFrame("HomeTab")
	G2L["7"] = Instance.new("Frame", G2L["6"]);
	G2L["7"]["BorderSizePixel"] = 0;
	G2L["7"]["Size"] = UDim2.new(0, 270, 0, 150);
	G2L["7"]["Position"] = UDim2.new(0.03, 0, 0.20, 0);
	G2L["7"]["Name"] = [[ServerInfo]];
	G2L["7"]["BackgroundColor3"] = Color3.fromRGB(15, 15, 17);
	G2L["7"]["BackgroundTransparency"] = 0.42;
	G2L["8"] = Instance.new("UICorner", G2L["7"]);
	G2L["9"] = addBorderStroke(G2L["7"], Color3.fromRGB(40, 40, 42));
	G2L["a"] = Instance.new("TextLabel", G2L["7"]);
	G2L["a"]["BorderSizePixel"] = 0;
	G2L["a"]["TextSize"] = 27;
	G2L["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["BackgroundTransparency"] = 1;
	G2L["a"]["Size"] = UDim2.new(0, 120, 0, 32);
	G2L["a"]["Text"] = [[Server]];
	G2L["a"]["Name"] = [[ServerLabel]];
	G2L["a"]["Position"] = UDim2.new(0.05, 0, 0.05, 0);
	G2L["a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["b"] = Instance.new("TextLabel", G2L["7"]);
	G2L["b"]["BorderSizePixel"] = 0;
	G2L["b"]["TextSize"] = 15;
	G2L["b"]["TextTransparency"] = 0.61;
	G2L["b"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["b"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["b"]["BackgroundTransparency"] = 1;
	G2L["b"]["Size"] = UDim2.new(0, 200, 0, 15);
	G2L["b"]["Text"] = [[Current session info]];
	G2L["b"]["Name"] = [[Serverdesc]];
	G2L["b"]["Position"] = UDim2.new(0.05, 0, 0.28, 0);
	G2L["b"]["TextXAlignment"] = Enum.TextXAlignment.Left;

	ServerPlayersLbl = Instance.new("TextLabel", G2L["7"])
	ServerPlayersLbl.Size = UDim2.new(0, 200, 0, 15)
	ServerPlayersLbl.Position = UDim2.new(0.05, 0, 0.48, 0)
	ServerPlayersLbl.BackgroundTransparency = 1
	ServerPlayersLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	ServerPlayersLbl.TextTransparency = 0.4
	ServerPlayersLbl.TextSize = 14
	ServerPlayersLbl.TextXAlignment = Enum.TextXAlignment.Left
	ServerPlayersLbl.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	ServerPlayersLbl.Text = "Loading players..."
	ServerPingLbl = Instance.new("TextLabel", G2L["7"])
	ServerPingLbl.Size = UDim2.new(0, 200, 0, 15)
	ServerPingLbl.Position = UDim2.new(0.05, 0, 0.68, 0)
	ServerPingLbl.BackgroundTransparency = 1
	ServerPingLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	ServerPingLbl.TextTransparency = 0.4
	ServerPingLbl.TextSize = 14
	ServerPingLbl.TextXAlignment = Enum.TextXAlignment.Left
	ServerPingLbl.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	ServerPingLbl.Text = "Latency: --ms"

	local function readServerPing()
		local ok, value = pcall(function()
			return game:GetService("Stats").Network.ServerToClientPing:GetValue()
		end)
		if ok and tonumber(value) then return math.floor(tonumber(value) + 0.5) end
		local ok2, value2 = pcall(function()
			return localPlayer:GetNetworkPing() * 1000
		end)
		if ok2 and tonumber(value2) then return math.floor(tonumber(value2) + 0.5) end
		return nil
	end

	local function refreshServerCard()

		pcall(function()
			local ping = readServerPing()
			ServerPingLbl.Text = ping and ("Latency: " .. tostring(ping) .. "ms") or "Latency: n/a"
		end)
		pcall(function()
			local playersCount = #players:GetPlayers()
			local maxPlayers = players.MaxPlayers
			ServerPlayersLbl.Text = "Players: " .. tostring(playersCount) .. "/" .. tostring(maxPlayers)
		end)
	end

	task.spawn(function()
		refreshServerCard()
		while task.wait(1) do
			refreshServerCard()
		end
	end)
	players.PlayerAdded:Connect(function() task.defer(refreshServerCard) end)
	players.PlayerRemoving:Connect(function() task.defer(refreshServerCard) end)

	G2L["1d"] = Instance.new("TextLabel", G2L["6"]);
	G2L["1d"]["BorderSizePixel"] = 0;
	G2L["1d"]["TextSize"] = 27;
	G2L["1d"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["1d"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["1d"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1d"]["BackgroundTransparency"] = 1;
	G2L["1d"]["Size"] = UDim2.new(0, 350, 0, 32);
	G2L["1d"]["Name"] = [[WelcomeMessage]];
	G2L["1d"]["Position"] = UDim2.new(0.03, 0, 0.0647, 0);
	G2L["1d"]["Text"] = "Welcome, " .. localPlayer.DisplayName

	G2L["1e"] = Instance.new("Frame", G2L["6"]);
	G2L["1e"]["BorderSizePixel"] = 0;
	G2L["1e"]["Size"] = UDim2.new(0, 270, 0, 150);
	G2L["1e"]["Position"] = UDim2.new(0.03, 0, 0.56, 0);
	G2L["1e"]["Name"] = [[PlayerInfo]];
	G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(15, 15, 17);
	G2L["1e"]["BackgroundTransparency"] = 0.42;
	G2L["1f"] = Instance.new("UICorner", G2L["1e"]);
	G2L["1f"]["CornerRadius"] = UDim.new(0, 5);
	G2L["20"] = addBorderStroke(G2L["1e"], Color3.fromRGB(40, 40, 42));
	G2L["21"] = Instance.new("TextLabel", G2L["1e"]);
	G2L["21"]["BorderSizePixel"] = 0;
	G2L["21"]["TextSize"] = 27;
	G2L["21"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["21"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["21"]["BackgroundTransparency"] = 1;
	G2L["21"]["Size"] = UDim2.new(0, 120, 0, 32);
	G2L["21"]["Text"] = [[Player]];
	G2L["21"]["Name"] = [[ServerLabel]];
	G2L["21"]["Position"] = UDim2.new(0.05, 0, 0.05, 0);
	G2L["21"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["22"] = Instance.new("TextLabel", G2L["1e"]);
	G2L["22"]["BorderSizePixel"] = 0;
	G2L["22"]["TextSize"] = 15;
	G2L["22"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["22"]["TextTransparency"] = 0.61;
	G2L["22"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["22"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["22"]["BackgroundTransparency"] = 1;
	G2L["22"]["Size"] = UDim2.new(0, 200, 0, 15);
	G2L["22"]["Text"] = [[Player Stats]];
	G2L["22"]["Name"] = [[Serverdesc]];
	G2L["22"]["Position"] = UDim2.new(0.05, 0, 0.28, 0);
	local AgeLbl = Instance.new("TextLabel", G2L["1e"])
	AgeLbl.Size = UDim2.new(0, 200, 0, 15)
	AgeLbl.Position = UDim2.new(0.05, 0, 0.48, 0)
	AgeLbl.BackgroundTransparency = 1
	AgeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	AgeLbl.TextTransparency = 0.4
	AgeLbl.TextSize = 14
	AgeLbl.TextXAlignment = Enum.TextXAlignment.Left
	AgeLbl.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	AgeLbl.Text = "Account Age: " .. localPlayer.AccountAge .. " days"
	local UserIdLbl = Instance.new("TextLabel", G2L["1e"])
	UserIdLbl.Size = UDim2.new(0, 200, 0, 15)
	UserIdLbl.Position = UDim2.new(0.05, 0, 0.68, 0)
	UserIdLbl.BackgroundTransparency = 1
	UserIdLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	UserIdLbl.TextTransparency = 0.4
	UserIdLbl.TextSize = 14
	UserIdLbl.TextXAlignment = Enum.TextXAlignment.Left
	UserIdLbl.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	UserIdLbl.Text = "User ID: " .. localPlayer.UserId

	G2L["23"] = Instance.new("Frame", G2L["6"]);
	G2L["23"]["BorderSizePixel"] = 0;
	G2L["23"]["Size"] = UDim2.new(0, 270, 0, 150);
	G2L["23"]["Position"] = UDim2.new(0.51, 0, 0.20, 0);
	G2L["23"]["Name"] = [[ExecutorCard]];
	G2L["23"]["BackgroundColor3"] = Color3.fromRGB(15, 15, 17);
	G2L["23"]["BackgroundTransparency"] = 0.42;
	G2L["24"] = Instance.new("UICorner", G2L["23"]);
	G2L["25"] = addBorderStroke(G2L["23"], Color3.fromRGB(40, 40, 42));

	do
		local ExecHeader = Instance.new("TextLabel", G2L["23"])
		ExecHeader.BorderSizePixel = 0
		ExecHeader.TextSize = 27
		ExecHeader.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		ExecHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
		ExecHeader.BackgroundTransparency = 1
		ExecHeader.Size = UDim2.new(0, 200, 0, 32)
		ExecHeader.Text = "Executor"
		ExecHeader.Position = UDim2.new(0.05, 0, 0.05, 0)
		ExecHeader.TextXAlignment = Enum.TextXAlignment.Left

		local ExecDesc = Instance.new("TextLabel", G2L["23"])
		ExecDesc.BorderSizePixel = 0
		ExecDesc.TextSize = 15
		ExecDesc.TextTransparency = 0.61
		ExecDesc.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		ExecDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
		ExecDesc.BackgroundTransparency = 1
		ExecDesc.Size = UDim2.new(0, 200, 0, 15)
		ExecDesc.Text = "exec environment"
		ExecDesc.Position = UDim2.new(0.05, 0, 0.28, 0)
		ExecDesc.TextXAlignment = Enum.TextXAlignment.Left

		local ExecNameLbl = Instance.new("TextLabel", G2L["23"])
		ExecNameLbl.BorderSizePixel = 0
		ExecNameLbl.TextSize = 20
		ExecNameLbl.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		ExecNameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		ExecNameLbl.BackgroundTransparency = 1
		ExecNameLbl.Size = UDim2.new(0, 250, 0, 30)
		ExecNameLbl.Text = identifyexecutor()
		ExecNameLbl.Position = UDim2.new(0.05, 0, 0.55, 0)
		ExecNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	end

	G2L["27"] = Instance.new("Frame", G2L["6"]);
	G2L["27"]["BorderSizePixel"] = 0;
	G2L["27"]["Size"] = UDim2.new(0, 270, 0, 150);
	G2L["27"]["Position"] = UDim2.new(0.51, 0, 0.56, 0);
	G2L["27"]["Name"] = [[DiscordCard]];
	G2L["27"]["BackgroundTransparency"] = 1;
	G2L["28"] = Instance.new("UICorner", G2L["27"]);
	G2L["28"]["CornerRadius"] = UDim.new(0, 5);
	G2L["29"] = addBorderStroke(G2L["27"], Color3.fromRGB(40, 40, 42));
	do
		local DiscHeader = Instance.new("TextLabel", G2L["27"])
		DiscHeader.BorderSizePixel = 0
		DiscHeader.TextSize = 27
		DiscHeader.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		DiscHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
		DiscHeader.BackgroundTransparency = 1
		DiscHeader.Size = UDim2.new(0, 200, 0, 32)
		DiscHeader.Text = "Discord"
		DiscHeader.Position = UDim2.new(0.05, 0, 0.05, 0)
		DiscHeader.TextXAlignment = Enum.TextXAlignment.Left

		local DiscDesc = Instance.new("TextLabel", G2L["27"])
		DiscDesc.BorderSizePixel = 0
		DiscDesc.TextSize = 15
		DiscDesc.TextTransparency = 0.61
		DiscDesc.FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		DiscDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
		DiscDesc.BackgroundTransparency = 1
		DiscDesc.Size = UDim2.new(0, 200, 0, 15)
		DiscDesc.Text = "Join our community server"
		DiscDesc.Position = UDim2.new(0.05, 0, 0.28, 0)
		DiscDesc.TextXAlignment = Enum.TextXAlignment.Left

		local joinBtn = Instance.new("TextButton", G2L["27"])
		joinBtn.Size = UDim2.new(0.9, 0, 0, 32)
		joinBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
		joinBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
		joinBtn.Text = "Join Server (Copy Link)"
		joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		joinBtn.TextSize = 13
		joinBtn.Font = Enum.Font.GothamBold
		joinBtn.BorderSizePixel = 0
		Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

		joinBtn.MouseButton1Click:Connect(function()
			if setclipboard then
				setclipboard("https://discord.gg/sl8")
				queueNotification("Discord Link Copied", "The server invite link has been copied to your clipboard!")
			end
		end)
	end
	G2L["2e"] = Instance.new("ImageLabel", G2L["2"]);
	G2L["2e"]["BorderSizePixel"] = 0;
	G2e_Corner = Instance.new("UICorner", G2L["2e"])
	G2e_Corner.CornerRadius = UDim.new(0, 5)
	G2L["2e"]["ScaleType"] = Enum.ScaleType.Fit;
	G2L["2e"]["Image"] = [[rbxassetid://106790631609801]];
	G2L["2e"]["Size"] = UDim2.new(0, 46, 0, 49);
	G2L["2e"]["BackgroundTransparency"] = 1;
	G2L["2e"]["Name"] = [[SlateLogo]];
	G2L["2e"]["Position"] = UDim2.new(0, 16, 0, 22);
	G2L["2e"]["ZIndex"] = 5;
	G2L["2f"] = addBorderStroke(G2L["2"], Color3.fromRGB(40, 40, 42));

	local successCG, testCG = pcall(function() return Instance.new("CanvasGroup") end)
	if successCG and testCG then
		testCG:Destroy()
		G2L["30"] = Instance.new("CanvasGroup", G2L["1"]);
	else
		G2L["30"] = Instance.new("Frame", G2L["1"]);
	end
	G2L["30"]["BorderSizePixel"] = 0;
	G2L["30"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["30"]["Size"] = UDim2.new(0, 117, 0, 39);
	G2L["30"]["Position"] = UDim2.new(0.5, -58, 0, 15);
	G2L["30"]["Name"] = [[Dock Bar]];
	G2L["31"] = Instance.new("UICorner", G2L["30"]);
	G2L["31"]["CornerRadius"] = UDim.new(0, 30);

	do
		local dockBg = createSlateBackdrop(G2L["30"], 30, {
			zIndex = 0,
			sequence = SlateBackdrop.barSequence,
			rotation = 10,
			baseSpin = 1.4,
			shadeScale = 0.3,
			intensity = 0.95,
		})

		G2L["31"]:GetPropertyChangedSignal("CornerRadius"):Connect(function()
			SlateBackdrop.setCornerRadius(dockBg, G2L["31"].CornerRadius)
		end)
		SlateBackdrop.setCornerRadius(dockBg, G2L["31"].CornerRadius)
	end
	G2L["32"] = Instance.new("ImageLabel", G2L["30"]);
	G2L["32"]["ZIndex"] = 0;
	G2L["32"]["BorderSizePixel"] = 0;
	G2L["32"]["ImageTransparency"] = 1;
	G2L["32"]["Image"] = [[]];
	G2L["32"]["Visible"] = false;
	G2L["32"]["Size"] = UDim2.new(1, -2, 1, 0);
	G2L["32"]["BackgroundTransparency"] = 1;
	G2L["32"]["Name"] = [[BackgroundImage]];
	G2L["33"] = Instance.new("UICorner", G2L["32"]);

	IslandGroup = Instance.new("Frame", G2L["30"])
	IslandGroup.Name = "IslandGroup"
	IslandGroup.Size = UDim2.new(1, 0, 1, 0)
	IslandGroup.BackgroundTransparency = 1
	IslandGroup.Visible = true

	local PlayerThumbnail = Instance.new("Frame", IslandGroup)
	PlayerThumbnail.Name = "PlayerThumbnail"
	PlayerThumbnail.BorderSizePixel = 0
	PlayerThumbnail.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	PlayerThumbnail.Size = UDim2.new(0, 24, 0, 24)
	PlayerThumbnail.Position = UDim2.new(0, 83, 0.5, -12)
	PlayerThumbnail.BackgroundTransparency = 1
	local ptStroke = Instance.new("UIStroke", PlayerThumbnail)
	ptStroke.Color = Color3.fromRGB(112, 112, 112)
	ptStroke.Thickness = 0.99
	local ptCorner = Instance.new("UICorner", PlayerThumbnail)
	ptCorner.CornerRadius = UDim.new(0, 50)
	local ptImage = Instance.new("ImageLabel", PlayerThumbnail)
	ptImage.Name = "Headshot"
	ptImage.Size = UDim2.new(1, 0, 1, 0)
	ptImage.BackgroundTransparency = 1
	ptImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. game:GetService("Players").LocalPlayer.UserId .. "&w=150&h=150"
	local ptImageCorner = Instance.new("UICorner", ptImage)
	ptImageCorner.CornerRadius = UDim.new(0, 50)

	local SpotifyActiveSong = Instance.new("Frame", IslandGroup)
	SpotifyActiveSong.Name = "SpotifyActiveSong"
	SpotifyActiveSong.BorderSizePixel = 0
	SpotifyActiveSong.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SpotifyActiveSong.Size = UDim2.new(0, 24, 0, 24)
	SpotifyActiveSong.Position = UDim2.new(0, 10, 0.5, -12)
	SpotifyActiveSong.BackgroundTransparency = 1
	SpotifyActiveSong.Visible = false
	local sasCorner = Instance.new("UICorner", SpotifyActiveSong)
	sasCorner.CornerRadius = UDim.new(1, 0)
	IslandAlbumCover = Instance.new("ImageLabel", SpotifyActiveSong)
	IslandAlbumCover.Name = "AlbumCover"
	IslandAlbumCover.BorderSizePixel = 0
	IslandAlbumCover.BackgroundTransparency = 1
	IslandAlbumCover.Image = "rbxassetid://73264766715941"
	IslandAlbumCover.ImageTransparency = 1
	IslandAlbumCover.Size = UDim2.new(1, 0, 1, 0)
	IslandAlbumCover.Position = UDim2.new(0, 0, 0, 0)
	local iacCorner = Instance.new("UICorner", IslandAlbumCover)
	iacCorner.CornerRadius = UDim.new(1, 0)

	local LiveAudioGraph = Instance.new("Frame", IslandGroup)
	LiveAudioGraph.Name = "LiveAudioGraph"
	LiveAudioGraph.BorderSizePixel = 0
	LiveAudioGraph.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	LiveAudioGraph.Size = UDim2.new(0, 33, 0, 16)
	LiveAudioGraph.Position = UDim2.new(0.5, -16.5, 0.5, -8)
	LiveAudioGraph.BackgroundTransparency = 1
	LiveAudioGraph.Visible = false
	local audioBars = {}
	for i = 1, 4 do
		local bar = Instance.new("Frame", LiveAudioGraph)
		bar.Name = "Bar" .. i
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bar.BackgroundTransparency = 1
		bar.Size = UDim2.new(0.15, 0, 0, 3)
		bar.Position = UDim2.new(0.25 * (i - 1), 0, 0.5, -1.5)
		local barCorner = Instance.new("UICorner", bar)
		barCorner.CornerRadius = UDim.new(1, 0)
		table.insert(audioBars, bar)
	end

	local _barFreqs = {2.2, 3.1, 2.5, 3.4}
	local _barPhases = {0.0, 1.4, 2.8, 0.9}
	local _smoothedLoudness = 0.5

	runService.RenderStepped:Connect((function(dt)
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		local isPlayingNow = (spotifyIsPlaying or _G.spotifyIsPlaying or _G.SlateSpotifyIsPlaying) == true and not _G.isShowingIslandNotif and not _G.isShowingOwnerNotification
		if not LiveAudioGraph.Visible then return end

		if isPlayingNow then
			local soundInst = (SlateMusic and SlateMusic.sound) or game:FindFirstChild("SoundService") and game.SoundService:FindFirstChild("SlateMusicAudio")
			local rawLoudness = (soundInst and soundInst.PlaybackLoudness) or 0

			local targetScale = math.clamp(rawLoudness / 240, 0.25, 1.6)
			_smoothedLoudness = _smoothedLoudness + ((targetScale - _smoothedLoudness) * math.clamp((dt or 0.016) * 20, 0, 1))

			local t = os.clock() * (5.5 + _smoothedLoudness * 4.5)
			for i = 1, 4 do
				local bar = audioBars[i]
				if bar then
					local s = math.abs(math.sin(t * _barFreqs[i] + _barPhases[i]))
					local h = math.clamp(3.0 + (_smoothedLoudness * (3.5 + s * 8.5)), 3.0, 15.0)
					bar.Size = UDim2.new(0.16, 0, 0, h)
					bar.Position = UDim2.new(0.25 * (i - 1), 0, 0.5, -h * 0.5)
				end
			end
		else
			_smoothedLoudness = 0.2
			for i = 1, 4 do
				local bar = audioBars[i]
				if bar and bar.Size.Y.Offset > 3.2 then
					local h = math.max(3, bar.Size.Y.Offset - (15 * (dt or 0.016)))
					bar.Size = UDim2.new(0.16, 0, 0, h)
					bar.Position = UDim2.new(0.25 * (i - 1), 0, 0.5, -h * 0.5)
				end
			end
		end
	end))

	ClockIcon = Instance.new("ImageLabel", IslandGroup)
	ClockIcon.Name = "ClockIcon"
	ClockIcon.Image = "rbxassetid://95038539084767"
	ClockIcon.Size = UDim2.new(0, 16, 0, 16)
	ClockIcon.Position = UDim2.new(0, 12, 0.5, -8)
	ClockIcon.BackgroundTransparency = 1

	IslandTimeLabel = Instance.new("TextLabel", IslandGroup)
	IslandTimeLabel.Name = "TimeLabel"
	IslandTimeLabel.BorderSizePixel = 0
	IslandTimeLabel.TextSize = 12
	IslandTimeLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	IslandTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	IslandTimeLabel.BackgroundTransparency = 1
	IslandTimeLabel.Size = UDim2.new(0, 48, 1, 0)
	IslandTimeLabel.Position = UDim2.new(0, 34, 0, 0)
	IslandTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	IslandTimeLabel.TextYAlignment = Enum.TextYAlignment.Center
	IslandTimeLabel.Text = os.date("%I:%M %p")

	DockLogo = Instance.new("ImageButton", G2L["30"])
	DockLogo.Name = "SlateLogo"
	DockLogo.Image = "rbxassetid://106790631609801"
	DockLogo.ScaleType = Enum.ScaleType.Fit
	DockLogo.Size = UDim2.new(0, 37, 0, 43)
	DockLogo.Position = UDim2.new(0.02703, 0, 0.5, -21)
	DockLogo.BackgroundTransparency = 1
	DockLogo.BorderSizePixel = 0
	DockLogo.ZIndex = 5
	DockLogo.Visible = false

	local function makeDockButton(name, imageId, pos)
		local btn = Instance.new("ImageButton", G2L["30"]);
		btn.Name = name .. "TabButton";
		btn.BorderSizePixel = 0;
		btn.BackgroundTransparency = 1;
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		btn.Image = "rbxthumb://type=Asset&id=" .. tostring(imageId) .. "&w=420&h=420";
		btn.Size = UDim2.new(0, 28, 0, 28);
		btn.Position = pos;
		btn.Visible = false;
		btn.ZIndex = 3;

		local hoverBg = Instance.new("Frame", btn)
		hoverBg.Name = "HoverBackground"
		hoverBg.Size = UDim2.new(1.40, 0, 1.40, 0)
		hoverBg.Position = UDim2.new(-0.20, 0, -0.20, 0)
		hoverBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hoverBg.BackgroundTransparency = 1
		hoverBg.BorderSizePixel = 0
		hoverBg.ZIndex = 2;
		local corner = Instance.new("UICorner", hoverBg)
		corner.CornerRadius = UDim.new(0, 8)
		btn.MouseEnter:Connect(function()
			tweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 30, 0, 30)
			}):Play()
			tweenService:Create(hoverBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.88
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			tweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 28, 0, 28)
			}):Play()
			tweenService:Create(hoverBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1
			}):Play()
		end)
		btn.Visible = false
		return btn
	end
	HomeBtn = makeDockButton("Home", 131020769964098, UDim2.new(0.13, 0, 0.5, -14))
	AutoExecBtn = nil

	CharacterBtn = makeDockButton("Character", 77913721129068, UDim2.new(0.24, 0, 0.5, -14))
	CommandsBtn = makeDockButton("Commands", 132715960634165, UDim2.new(0.35, 0, 0.5, -14))
	PlayersBtn = makeDockButton("Players", 128832612895005, UDim2.new(0.46, 0, 0.5, -14))
	MusicBtn = makeDockButton("Music", 76273968889626, UDim2.new(0.57, 0, 0.5, -14))
	NametagsBtn = makeDockButton("Nametags", 105837003124093, UDim2.new(0.68, 0, 0.5, -14))
	table.insert(dockButtons, {btn = NametagsBtn, pos = UDim2.new(0, 0, 0, 0)})
	SettingsBtn = makeDockButton("Settings", 140667076868313, UDim2.new(0.79, 0, 0.5, -14))
	CloudBtn = makeDockButton("Cloud", 95102918008383, UDim2.new(0.79, 0, 0.5, -14))

	local OWNER_ICON_ID = 118191845701573
	local OWNER_ICON_SIZE = 47

	OwnerBtn = makeDockButton("Owner", OWNER_ICON_ID, UDim2.new(0.90, 0, 0.5, -14))
	table.insert(dockButtons, {btn = OwnerBtn, pos = UDim2.new(0, 0, 0, 0)})

	OwnerBtn.Image = ""
	local crownIcon
	if OWNER_ICON_ID ~= 0 then
		crownIcon = Instance.new("ImageLabel", OwnerBtn)
		crownIcon.Image = "rbxthumb://type=Asset&id=" .. tostring(OWNER_ICON_ID) .. "&w=420&h=420"
		crownIcon.ScaleType = Enum.ScaleType.Fit
	else
		crownIcon = Instance.new("TextLabel", OwnerBtn)
		crownIcon.Text = "◆"
		crownIcon.TextScaled = true
		crownIcon.Font = Enum.Font.BuilderSansBold
	end
	crownIcon.Name = "OwnerIcon"
	crownIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	crownIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	crownIcon.Size = UDim2.new(0, OWNER_ICON_SIZE, 0, OWNER_ICON_SIZE)
	crownIcon.BackgroundTransparency = 1
	crownIcon.ZIndex = 4

	if crownIcon:IsA("ImageLabel") then
		crownIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	else
		crownIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	OwnerBtn.MouseEnter:Connect(function()
		tweenService:Create(crownIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, OWNER_ICON_SIZE + 2, 0, OWNER_ICON_SIZE + 2)
		}):Play()
	end)
	OwnerBtn.MouseLeave:Connect(function()
		tweenService:Create(crownIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, OWNER_ICON_SIZE, 0, OWNER_ICON_SIZE)
		}):Play()
	end)

	OwnerBtn.MouseButton1Click:Connect(function()
		if type(_G.SlateToggleOwnerPanel) == "function" then
			_G.SlateToggleOwnerPanel()
		else
			queueNotification("Owner", "Owner panel is still loading.")
		end
	end)
	_G.SlateToggleNametags = function()
		showNametags = not showNametags

		_G.showSlateTagsFlag        = showNametags
		_G.showOnyxTagsFlag         = showNametags
		getgenv().showNametags      = showNametags
		getgenv().showSlateTagsFlag = showNametags
		getgenv().showOnyxTagsFlag  = showNametags
		local reg = _G.OnyxTagRegistry
		if reg then
			for i = #reg, 1, -1 do
				local tag = reg[i]
				if tag and tag.Parent then
					pcall(function() tag.Enabled = showNametags end)
				else
					table.remove(reg, i)
				end
			end
		end
		if NametagsBtn then
			NametagsBtn.ImageColor3 = showNametags and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
		end
		if SlateNav and SlateNav.paint then SlateNav.paint() end
		return showNametags
	end
	NametagsBtn.MouseButton1Click:Connect(_G.SlateToggleNametags)
	G2L["42"] = Instance.new("TextLabel", G2L["30"]);
	G2L["42"]["BorderSizePixel"] = 0;
	G2L["42"]["TextSize"] = 12;
	G2L["42"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
	G2L["42"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["42"]["BackgroundTransparency"] = 1;
	G2L["42"]["Size"] = UDim2.new(0, 90, 0, 16);
	G2L["42"]["Text"] = os.date("%I:%M %p");
	G2L["42"]["Name"] = [[CurrentTIme12HRFormat]];
	G2L["42"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["42"]["Position"] = UDim2.new(0.90, 0, 0.68, 0);
	G2L["42"]["Visible"] = false;
	G2L["43"] = Instance.new("ImageLabel", G2L["30"]);
	G2L["43"]["BorderSizePixel"] = 0;
	G2L["43"]["Image"] = "rbxthumb://type=AvatarHeadShot&id=" .. localPlayer.UserId .. "&w=150&h=150";
	G2L["43"]["Size"] = UDim2.new(0, 22, 0, 22);
	G2L["43"]["BackgroundTransparency"] = 1;
	G2L["43"]["Name"] = [[Player Thumbnail]];
	G2L["43"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["43"]["Position"] = UDim2.new(0.90, 0, 0.32, 0);
	G2L["43"]["Visible"] = false;
	local G2L_43_Corner = Instance.new("UICorner", G2L["43"])
	G2L_43_Corner.CornerRadius = UDim.new(1, 0)

	do
		local function _init_block_8460()
		G2L["NotificationContainer"] = Instance.new("Frame", G2L["1"]);
		G2L["NotificationContainer"].Name = "NotificationContainer";
		G2L["NotificationContainer"].Size = UDim2.new(0, 300, 0, 500);
		G2L["NotificationContainer"].Position = UDim2.new(1, -310, 0, 20);
		G2L["NotificationContainer"].BackgroundTransparency = 1;
		G2L["NotificationTemplate"] = Instance.new("Frame");
		G2L["NotificationTemplate"].Name = "NotificationTemplate";
		G2L["NotificationTemplate"].BorderSizePixel = 0;
		G2L["NotificationTemplate"].BackgroundColor3 = Color3.fromRGB(12, 12, 14);
		G2L["NotificationTemplate"].Size = UDim2.new(0, 280, 0, 79);
		G2L["NotificationTemplate"].Visible = false;
		local NotifBg = Instance.new("ImageLabel", G2L["NotificationTemplate"]);
		NotifBg.Name = "BackgroundImage";
		NotifBg.ZIndex = 0;
		NotifBg.BorderSizePixel = 0;
		NotifBg.ImageTransparency = 0.85;
		NotifBg.Image = "";
		NotifBg.Size = UDim2.new(1, 0, 1, 0);
		NotifBg.BackgroundTransparency = 1;
		local NotifBgCorner = Instance.new("UICorner", NotifBg);
		local NotifCorner = Instance.new("UICorner", G2L["NotificationTemplate"]);
		local NotifStroke = Instance.new("UIStroke", G2L["NotificationTemplate"]);
		NotifStroke.Thickness = 0.99;
		NotifStroke.Color = Color3.fromRGB(40, 40, 42);
		local NotifLogo = Instance.new("ImageLabel", G2L["NotificationTemplate"]);
		NotifLogo.Name = "SlateLogo";
		NotifLogo.BorderSizePixel = 0;
		NotifLogo.ScaleType = Enum.ScaleType.Fit;
		NotifLogo.Image = "rbxassetid://106790631609801";
		NotifLogo.Size = UDim2.new(0, 30, 0, 35);
		NotifLogo.BackgroundTransparency = 1;
		NotifLogo.Position = UDim2.new(0.04, 0, 0.25, 0);
		local NotifTitle = Instance.new("TextLabel", G2L["NotificationTemplate"]);
		NotifTitle.Name = "Title";
		NotifTitle.BorderSizePixel = 0;
		NotifTitle.TextSize = 15;
		NotifTitle.TextColor3 = Color3.fromRGB(255, 255, 255);
		NotifTitle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal);
		NotifTitle.BackgroundTransparency = 1;
		NotifTitle.Position = UDim2.new(0.18, 0, 0.15, 0);
		NotifTitle.Size = UDim2.new(0.75, 0, 0, 20);
		NotifTitle.TextXAlignment = Enum.TextXAlignment.Left;
		local NotifDesc = Instance.new("TextLabel", G2L["NotificationTemplate"]);
		NotifDesc.Name = "Description";
		NotifDesc.BorderSizePixel = 0;
		NotifDesc.TextSize = 12;
		NotifDesc.TextColor3 = Color3.fromRGB(200, 200, 200);
		NotifDesc.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		NotifDesc.BackgroundTransparency = 1;
		NotifDesc.Position = UDim2.new(0.18, 0, 0.42, 0);
		NotifDesc.Size = UDim2.new(0.75, 0, 0, 35);
		NotifDesc.TextWrapped = true;
		NotifDesc.TextXAlignment = Enum.TextXAlignment.Left;
		NotifDesc.TextYAlignment = Enum.TextYAlignment.Top;
		local NotifClose = Instance.new("TextButton", G2L["NotificationTemplate"]);
		NotifClose.Name = "Interact";
		NotifClose.BackgroundTransparency = 1;
		NotifClose.Text = "";
		NotifClose.Size = UDim2.new(1, 0, 1, 0);
		end
		_init_block_8460()
	end
	do
		local function initializeGameConfigs()

		end

	end

	do
		local function _init_block_8719()
		CharacterTab = createTabFrame("CharacterTab")
		addLabel(CharacterTab, "Gameplay & Character", UDim2.new(0, 300, 0, 32), UDim2.new(0.03, 0, 0.05, 0), true)
		local ActionsContainer = Instance.new("ScrollingFrame", CharacterTab)
		ActionsContainer.Name = "ActionsContainer"
		ActionsContainer.BorderSizePixel = 0
		ActionsContainer.BackgroundTransparency = 1
		ActionsContainer.Size = UDim2.new(0, 360, 0.75, 0)
		ActionsContainer.Position = UDim2.new(0.03, 0, 0.18, 0)
		ActionsContainer.ScrollBarThickness = 2
		ActionsContainer.ScrollBarImageTransparency = 1
		ActionsContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
		ActionsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ActionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		local ActionsPadding = Instance.new("UIPadding", ActionsContainer)
		ActionsPadding.PaddingLeft = UDim.new(0, 4)
		ActionsPadding.PaddingRight = UDim.new(0, 4)
		ActionsPadding.PaddingTop = UDim.new(0, 4)
		ActionsPadding.PaddingBottom = UDim.new(0, 4)
		local ActionsLayout = Instance.new("UIGridLayout", ActionsContainer)
		ActionsLayout.CellSize = UDim2.new(0, 110, 0, 45)
		ActionsLayout.CellPadding = UDim2.new(0, 8, 0, 8)
		local RightContainer = Instance.new("Frame", CharacterTab)
		RightContainer.Name = "RightContainer"
		RightContainer.BorderSizePixel = 0
		RightContainer.BackgroundTransparency = 1
		RightContainer.Size = UDim2.new(0, 190, 0.75, 0)
		RightContainer.Position = UDim2.new(0, 395, 0.18, 0)
		local RightLayout = Instance.new("UIListLayout", RightContainer)
		RightLayout.Padding = UDim.new(0, 10)
		end
		_init_block_8719()
	end
	do
		local function _init_block_8748()
		CommandsTab = createTabFrame("CommandsTab")
		addLabel(CommandsTab, "Commands", UDim2.new(0, 300, 0, 32), UDim2.new(0.03, 0, 0.05, 0), true)

		local ScriptsSearchBar = Instance.new("TextBox", CommandsTab)
		ScriptsSearchBar.Name = "ScriptsSearchBar"
		ScriptsSearchBar.PlaceholderText = " Search commands..."
		ScriptsSearchBar.PlaceholderColor3 = Color3.fromRGB(166, 166, 166)
		ScriptsSearchBar.BorderSizePixel = 0
		ScriptsSearchBar.TextSize = 13
		ScriptsSearchBar.ClearTextOnFocus = false
		ScriptsSearchBar.Text = ""
		ScriptsSearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
		ScriptsSearchBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		ScriptsSearchBar.BackgroundTransparency = 0.8
		ScriptsSearchBar.Size = UDim2.new(0.94, 0, 0, 28)
		ScriptsSearchBar.Position = UDim2.new(0.03, 0, 0.155, 0)
		ScriptsSearchBar.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		local SSBStrokeFrame = Instance.new("Frame", ScriptsSearchBar)
		SSBStrokeFrame.Name = "BorderFrame"
		SSBStrokeFrame.Size = UDim2.new(1, 0, 1, 0)
		SSBStrokeFrame.BackgroundTransparency = 1
		Instance.new("UICorner", SSBStrokeFrame).CornerRadius = UDim.new(0, 5)
		local SSBStroke = Instance.new("UIStroke", SSBStrokeFrame)
		SSBStroke.Color = Color3.fromRGB(40, 40, 42)
		SSBStroke.Thickness = 0.99
		Instance.new("UICorner", ScriptsSearchBar).CornerRadius = UDim.new(0, 5)

		local cmdSubNav = Instance.new("Frame", CommandsTab)
		cmdSubNav.Name = "CmdSubNav"
		cmdSubNav.Size = UDim2.new(0.94, 0, 0, 28)
		cmdSubNav.Position = UDim2.new(0.03, 0, 0.245, 0)
		cmdSubNav.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		cmdSubNav.BorderSizePixel = 0
		Instance.new("UICorner", cmdSubNav).CornerRadius = UDim.new(0, 6)
		local cmdNavLayout = Instance.new("UIListLayout", cmdSubNav)
		cmdNavLayout.FillDirection = Enum.FillDirection.Horizontal
		cmdNavLayout.Padding = UDim.new(0, 0)

		local allCmdsNavBtn = Instance.new("TextButton", cmdSubNav)
		allCmdsNavBtn.Name = "AllCmdsNavBtn"
		allCmdsNavBtn.Size = UDim2.new(0.5, 0, 1, 0)
		allCmdsNavBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 34)
		allCmdsNavBtn.BorderSizePixel = 0
		allCmdsNavBtn.Text = "All Commands"
		allCmdsNavBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		allCmdsNavBtn.TextStrokeTransparency = 1
		allCmdsNavBtn.Font = Enum.Font.GothamBold
		allCmdsNavBtn.TextSize = 11
		Instance.new("UICorner", allCmdsNavBtn).CornerRadius = UDim.new(0, 6)

		local favCmdsNavBtn = Instance.new("TextButton", cmdSubNav)
		favCmdsNavBtn.Name = "FavCmdsNavBtn"
		favCmdsNavBtn.Size = UDim2.new(0.5, 0, 1, 0)
		favCmdsNavBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		favCmdsNavBtn.BackgroundTransparency = 1
		favCmdsNavBtn.BorderSizePixel = 0
		favCmdsNavBtn.Text = "Favorites"
		favCmdsNavBtn.TextColor3 = Color3.fromRGB(140, 140, 145)
		favCmdsNavBtn.TextStrokeTransparency = 1
		favCmdsNavBtn.Font = Enum.Font.GothamBold
		favCmdsNavBtn.TextSize = 11
		Instance.new("UICorner", favCmdsNavBtn).CornerRadius = UDim.new(0, 6)

		local ScriptsScroll = Instance.new("ScrollingFrame", CommandsTab)
		ScriptsScroll.Name = "ScriptsScroll"
		ScriptsScroll.BorderSizePixel = 0
		ScriptsScroll.BackgroundTransparency = 1
		ScriptsScroll.Size = UDim2.new(0.94, 0, 0, 265)
		ScriptsScroll.Position = UDim2.new(0.03, 0, 0.33, 0)
		ScriptsScroll.ScrollBarThickness = 4
		ScriptsScroll.ScrollBarImageTransparency = 1
		ScriptsScroll.ScrollBarImageColor3 = Color3.fromRGB(82, 82, 82)
		ScriptsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		end
		_init_block_8748()
	end

	do
		local function _init_block_8793()
		PlayersTab = createTabFrame("PlayersTab")
		addLabel(PlayersTab, "Active Server Players", UDim2.new(0, 300, 0, 32), UDim2.new(0.03, 0, 0.05, 0), true)
		local PlayersSearchBar = Instance.new("TextBox", PlayersTab)
		PlayersSearchBar.PlaceholderText = " Filter players..."
		PlayersSearchBar.PlaceholderColor3 = Color3.fromRGB(166, 166, 166)
		PlayersSearchBar.BorderSizePixel = 0
		PlayersSearchBar.TextSize = 14
		PlayersSearchBar.Text = ""
		PlayersSearchBar.ClearTextOnFocus = false
		PlayersSearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
		PlayersSearchBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		PlayersSearchBar.BackgroundTransparency = 0.8
		PlayersSearchBar.Size = UDim2.new(0.94, 0, 0, 30)
		PlayersSearchBar.Position = UDim2.new(0.03, 0, 0.18, 0)
		PlayersSearchBar.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		PlayersSearchBar:GetPropertyChangedSignal("Text"):Connect(function()
			local query = PlayersSearchBar.Text:lower()
			local scroll = PlayersScroll or (PlayersTab and PlayersTab:FindFirstChild("PlayersScroll"))
			if scroll then
				local visibleCount = 0
				for _, child in ipairs(scroll:GetChildren()) do
					if child:IsA("Frame") and child.Name ~= "EmptyPlayersLabel" then
						if query == "" or child.Name:lower():find(query, 1, true) then
							child.Visible = true
							visibleCount = visibleCount + 1
						else
							child.Visible = false
						end
					end
				end
				local emptyLbl = scroll:FindFirstChild("EmptyPlayersLabel")
				if emptyLbl then
					if visibleCount == 0 then
						emptyLbl.Text = query == "" and "No other players in server." or "No players matching search."
						emptyLbl.Visible = true
					else
						emptyLbl.Visible = false
					end
				end
			end
		end)
		local PSBStroke2Frame = Instance.new("Frame", PlayersSearchBar)
		PSBStroke2Frame.Name = "BorderFrame"
		PSBStroke2Frame.Size = UDim2.new(1, 0, 1, 0)
		PSBStroke2Frame.BackgroundTransparency = 1
		local PSBStroke2Corner = Instance.new("UICorner", PSBStroke2Frame)
		PSBStroke2Corner.CornerRadius = UDim.new(0, 5)
		local PSBStroke2 = Instance.new("UIStroke", PSBStroke2Frame)
		PSBStroke2.Color = Color3.fromRGB(40, 40, 42)
		PSBStroke2.Thickness = 0.99
		local PSBCorner2 = Instance.new("UICorner", PlayersSearchBar)
		PSBCorner2.CornerRadius = UDim.new(0, 5)
		end
		_init_block_8793()
	end
	do
		local function _init_block_8821()

		local subNav = Instance.new("Frame", PlayersTab)
		subNav.Name = "SubNav"
		subNav.Size = UDim2.new(0.94, 0, 0, 26)
		subNav.Position = UDim2.new(0.03, 0, 0.27, 0)
		subNav.BackgroundTransparency = 1
		local navLayout = Instance.new("UIListLayout", subNav)
		navLayout.FillDirection = Enum.FillDirection.Horizontal
		navLayout.Padding = UDim.new(0, 6)

		PlayersScroll = Instance.new("ScrollingFrame", PlayersTab)
		PlayersScroll.Name = "PlayersScroll"
		PlayersScroll.Visible = true
		PlayersScroll.ZIndex = 2
		PlayersScroll.ZIndex = 2
		PlayersScroll.BorderSizePixel = 0
		PlayersScroll.BackgroundTransparency = 1
		PlayersScroll.Size = UDim2.new(0.94, 0, 0, 260)
		PlayersScroll.Position = UDim2.new(0.03, 0, 0.35, 0)
		PlayersScroll.ScrollBarThickness = 4
		PlayersScroll.ScrollBarImageTransparency = 1
		PlayersScroll.ScrollBarImageColor3 = Color3.fromRGB(82, 82, 82)
		PlayersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		local PlayersScrollPadding = Instance.new("UIPadding", PlayersScroll)
		PlayersScrollPadding.PaddingLeft = UDim.new(0, 5)
		PlayersScrollPadding.PaddingRight = UDim.new(0, 5)
		PlayersScrollPadding.PaddingTop = UDim.new(0, 5)
		PlayersScrollPadding.PaddingBottom = UDim.new(0, 5)
		local PlayersLayout = Instance.new("UIListLayout", PlayersScroll)
		PlayersLayout.Padding = UDim.new(0, 6)

		_G.CurrentServerScroll = Instance.new("ScrollingFrame", PlayersTab)
		local CurrentServerScroll = _G.CurrentServerScroll
		CurrentServerScroll.BorderSizePixel = 0
		CurrentServerScroll.BackgroundTransparency = 1
		CurrentServerScroll.Size = UDim2.new(0.94, 0, 0, 260)
		CurrentServerScroll.Position = UDim2.new(0.03, 0, 0.35, 0)
		CurrentServerScroll.ScrollBarThickness = 4
		CurrentServerScroll.ScrollBarImageTransparency = 1
		CurrentServerScroll.ScrollBarImageColor3 = Color3.fromRGB(82, 82, 82)
		CurrentServerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		CurrentServerScroll.Visible = false
		local CurrentServerPadding = Instance.new("UIPadding", CurrentServerScroll)
		CurrentServerPadding.PaddingLeft = UDim.new(0, 5)
		CurrentServerPadding.PaddingRight = UDim.new(0, 5)
		CurrentServerPadding.PaddingTop = UDim.new(0, 5)
		CurrentServerPadding.PaddingBottom = UDim.new(0, 5)
		local CurrentServerLayout = Instance.new("UIListLayout", CurrentServerScroll)
		CurrentServerLayout.Padding = UDim.new(0, 6)

		_G.GlobalServersScroll = Instance.new("ScrollingFrame", PlayersTab)
		local GlobalServersScroll = _G.GlobalServersScroll
		GlobalServersScroll.BorderSizePixel = 0
		GlobalServersScroll.BackgroundTransparency = 1
		GlobalServersScroll.Size = UDim2.new(0.94, 0, 0, 260)
		GlobalServersScroll.Position = UDim2.new(0.03, 0, 0.35, 0)
		GlobalServersScroll.ScrollBarThickness = 4
		GlobalServersScroll.ScrollBarImageTransparency = 1
		GlobalServersScroll.ScrollBarImageColor3 = Color3.fromRGB(82, 82, 82)
		GlobalServersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		GlobalServersScroll.Visible = false
		local GlobalServersPadding = Instance.new("UIPadding", GlobalServersScroll)
		GlobalServersPadding.PaddingLeft = UDim.new(0, 5)
		GlobalServersPadding.PaddingRight = UDim.new(0, 5)
		GlobalServersPadding.PaddingTop = UDim.new(0, 5)
		GlobalServersPadding.PaddingBottom = UDim.new(0, 5)
		local GlobalServersLayout = Instance.new("UIListLayout", GlobalServersScroll)
		GlobalServersLayout.Padding = UDim.new(0, 6)

		do
			local placeNameCache = {}
			local refreshing = false

			local function countUsers(t)
				if type(t) ~= "table" then return 0 end
				local c = 0
				for _ in pairs(t) do
					c = c + 1
				end
				return c
			end

			local function normalizeUserList(users)
				if type(users) ~= "table" then return {} end
				local arr = {}
				for _, uid in pairs(users) do
					local numUid = tonumber(uid) or uid
					if numUid then
						arr[#arr + 1] = numUid
					end
				end
				return arr
			end

			local function fetchGlobalUsersPayload()
				local base = (_G.SlateBackendBase or (getgenv and getgenv().BACKEND_URL) or _G.BACKEND_URL or (getgenv and getgenv().SLATE_BACKEND) or _G.SLATE_BACKEND or "https://sl8ght.xyz"):gsub("/+$", "")
				local endpoints = { base .. "/api/globalusers", "https://sl8ght.xyz/api/globalusers", "https://www.sl8ght.xyz/api/globalusers" }

				local reqFunc = (type(request) == "function" and request)
					or (type(http_request) == "function" and http_request)
					or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
					or (type(fluxus) == "table" and type(fluxus.request) == "function" and fluxus.request)
					or (type(http) == "table" and type(http.request) == "function" and http.request)

				local rawJson = nil

				if reqFunc then
					for _, url in ipairs(endpoints) do
						local ok, res = pcall(reqFunc, {
							Url = url,
							Method = "GET",
							Headers = {
								["User-Agent"] = "SlateClient/1.0",
								["Accept"] = "application/json"
							}
						})
						if ok and res and (res.StatusCode == 200 or res.Status == 200) and res.Body and #res.Body > 0 then
							rawJson = res.Body
							break
						end
					end
				end

				if not rawJson and type(game.HttpGet) == "function" then
					for _, url in ipairs(endpoints) do
						local ok, body = pcall(game.HttpGet, game, url)
						if ok and body and #body > 0 then
							rawJson = body
							break
						end
					end
				end

				if not rawJson then return nil end

				local hs = game:GetService("HttpService")
				local ok, data = pcall(function() return hs:JSONDecode(rawJson) end)
				if ok and type(data) == "table" and type(data.servers) == "table" then
					return data
				end
				return nil
			end

			local function statusRow(text)
				for _, c in ipairs(GlobalServersScroll:GetChildren()) do
					if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
				end
				local lbl = Instance.new("TextLabel", GlobalServersScroll)
				lbl.Size = UDim2.new(1, -6, 0, 44)
				lbl.BackgroundTransparency = 1
				lbl.Text = text
				lbl.TextColor3 = Color3.fromRGB(110, 110, 115)
				lbl.Font = Enum.Font.BuilderSans
				lbl.TextSize = 12
				lbl.TextWrapped = true
			end

			local function placeName(placeId)
				local numId = tonumber(placeId)
				if not numId or numId <= 0 then return "Place " .. tostring(placeId) end
				if placeNameCache[numId] then return placeNameCache[numId] end
				local ok, info = pcall(function()
					return game:GetService("MarketplaceService"):GetProductInfo(numId)
				end)
				local name = (ok and info and info.Name and #info.Name > 0 and info.Name) or ("Place " .. tostring(placeId))
				placeNameCache[numId] = name
				return name
			end

			local function buildServerCard(placeId, jobId, userIds, order, isCurrentServer)
				local isExpanded = false
				local card = Instance.new("Frame", GlobalServersScroll)
				card.Name = "Srv_" .. tostring(jobId):gsub("[^%w]", "")
				card.Size = UDim2.new(1, -6, 0, 56)
				card.LayoutOrder = order
				card.BackgroundColor3 = isCurrentServer and Color3.fromRGB(22, 22, 26) or Color3.fromRGB(15, 15, 17)
				card.BorderSizePixel = 0
				card.ClipsDescendants = true
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

				local st = Instance.new("UIStroke", card)
				st.Color = isCurrentServer and Color3.fromRGB(140, 140, 155) or Color3.fromRGB(32, 32, 36)
				st.Thickness = 1
				st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

				card.MouseEnter:Connect(function()
					if not isExpanded then
						tweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							BackgroundColor3 = isCurrentServer and Color3.fromRGB(28, 28, 34) or Color3.fromRGB(22, 22, 25)
						}):Play()
						tweenService:Create(st, TweenInfo.new(0.15), {
							Color = isCurrentServer and Color3.fromRGB(200, 200, 215) or Color3.fromRGB(48, 48, 54)
						}):Play()
					end
				end)
				card.MouseLeave:Connect(function()
					if not isExpanded then
						tweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							BackgroundColor3 = isCurrentServer and Color3.fromRGB(22, 22, 26) or Color3.fromRGB(15, 15, 17)
						}):Play()
						tweenService:Create(st, TweenInfo.new(0.15), {
							Color = isCurrentServer and Color3.fromRGB(140, 140, 155) or Color3.fromRGB(32, 32, 36)
						}):Play()
					end
				end)

				local headerBtn = Instance.new("TextButton", card)
				headerBtn.Size = UDim2.new(1, -190, 0, 56)
				headerBtn.Position = UDim2.new(0, 0, 0, 0)
				headerBtn.BackgroundTransparency = 1
				headerBtn.Text = ""
				headerBtn.ZIndex = 2

				local starIcon = nil
				if isCurrentServer then
					starIcon = Instance.new("ImageLabel", card)
					starIcon.Name = "CurrentStarIcon"
					starIcon.Size = UDim2.new(0, 15, 0, 15)
					starIcon.Position = UDim2.new(0, 14, 0, 10)
					starIcon.BackgroundTransparency = 1
					starIcon.Image = "rbxthumb://type=Asset&id=102819382107866&w=150&h=150"
					starIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
					starIcon.ZIndex = 3
				end

				local title = Instance.new("TextLabel", card)
				title.Size = UDim2.new(1, isCurrentServer and -232 or -210, 0, 18)
				title.Position = UDim2.new(0, isCurrentServer and 34 or 14, 0, 9)
				title.BackgroundTransparency = 1
				title.TextColor3 = Color3.fromRGB(255, 255, 255)
				title.Font = Enum.Font.BuilderSansBold
				title.TextSize = 14
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.TextTruncate = Enum.TextTruncate.AtEnd
				title.Text = (isCurrentServer and "Current Server: " or "") .. "Loading..."
				title.ZIndex = 3
				task.spawn(function()
					title.Text = (isCurrentServer and "Current Server: " or "") .. placeName(placeId)
				end)

				local userCount = #userIds
				local sub = Instance.new("TextLabel", card)
				sub.Size = UDim2.new(1, -210, 0, 14)
				sub.Position = UDim2.new(0, 14, 0, 30)
				sub.BackgroundTransparency = 1
				sub.TextColor3 = Color3.fromRGB(130, 130, 138)
				sub.Font = Enum.Font.BuilderSans
				sub.TextSize = 12
				sub.TextXAlignment = Enum.TextXAlignment.Left
				sub.TextTruncate = Enum.TextTruncate.AtEnd
				sub.Text = tostring(userCount) .. (userCount == 1 and " player" or " players")
					.. " • " .. tostring(jobId):sub(1, 8) .. "  ▾"
				sub.ZIndex = 3

				-- Join Server button
				local joinBtn = Instance.new("TextButton", card)
				joinBtn.Name = "JoinBtn"
				joinBtn.Size = UDim2.new(0, 68, 0, 26)
				joinBtn.Position = UDim2.new(1, -80, 0, 15)
				joinBtn.BorderSizePixel = 0
				joinBtn.ZIndex = 5
				Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

				if isCurrentServer then
					joinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
					joinBtn.Text = "Current"
					joinBtn.TextColor3 = Color3.fromRGB(190, 190, 200)
					joinBtn.Font = Enum.Font.BuilderSans
					joinBtn.TextSize = 11
					local jSt = Instance.new("UIStroke", joinBtn)
					jSt.Color = Color3.fromRGB(50, 50, 58)
					jSt.Thickness = 0.8
				else
					joinBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					joinBtn.Text = "Join"
					joinBtn.TextColor3 = Color3.fromRGB(12, 12, 14)
					joinBtn.Font = Enum.Font.BuilderSansBold
					joinBtn.TextSize = 12

					joinBtn.MouseEnter:Connect(function()
						tweenService:Create(joinBtn, TweenInfo.new(0.12), {
							BackgroundColor3 = Color3.fromRGB(225, 225, 230)
						}):Play()
					end)
					joinBtn.MouseLeave:Connect(function()
						tweenService:Create(joinBtn, TweenInfo.new(0.12), {
							BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						}):Play()
					end)
					joinBtn.MouseButton1Click:Connect(function()
						if isCurrentServer then return end
						SlateUiSound.click()
						queueNotification("Teleporting", "Joining global server...")
						local pIdNum = tonumber(placeId) or placeId
						pcall(function()
							game:GetService("TeleportService"):TeleportToPlaceInstance(pIdNum, tostring(jobId), game:GetService("Players").LocalPlayer)
						end)
					end)
				end

				-- Mini avatar previews
				local strip = Instance.new("Frame", card)
				strip.Size = UDim2.new(0, 84, 0, 22)
				strip.Position = UDim2.new(1, -172, 0, 17)
				strip.BackgroundTransparency = 1
				strip.ZIndex = 3
				local sLayout = Instance.new("UIListLayout", strip)
				sLayout.FillDirection = Enum.FillDirection.Horizontal
				sLayout.Padding = UDim.new(0, 3)

				for i = 1, math.min(#userIds, 3) do
					local uid = userIds[i]
					local numUid = tonumber(uid) or uid
					if numUid then
						local av = Instance.new("ImageLabel", strip)
						av.Size = UDim2.new(0, 22, 0, 22)
						av.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
						av.BorderSizePixel = 0
						av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(numUid) .. "&w=48&h=48"
						av.ZIndex = 4
						Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)
						local aSt = Instance.new("UIStroke", av)
						aSt.Color = Color3.fromRGB(36, 36, 42)
						aSt.Thickness = 0.8
					end
				end

				local details = Instance.new("Frame", card)
				details.Name = "ExpandedDetails"
				details.Size = UDim2.new(1, -24, 0, 0)
				details.Position = UDim2.new(0, 12, 0, 58)
				details.BackgroundTransparency = 1
				details.ClipsDescendants = true
				details.ZIndex = 2

				local dLayout = Instance.new("UIListLayout", details)
				dLayout.Padding = UDim.new(0, 4)

				task.spawn(function()
					for _, uid in ipairs(userIds) do
						local numUid = tonumber(uid) or uid
						local pRow = Instance.new("Frame", details)
						pRow.Size = UDim2.new(1, 0, 0, 34)
						pRow.BackgroundColor3 = Color3.fromRGB(19, 19, 22)
						pRow.BorderSizePixel = 0
						pRow.ZIndex = 3
						Instance.new("UICorner", pRow).CornerRadius = UDim.new(0, 6)
						local pRowStroke = Instance.new("UIStroke", pRow)
						pRowStroke.Color = Color3.fromRGB(30, 30, 35)
						pRowStroke.Thickness = 0.7

						local pAv = Instance.new("ImageLabel", pRow)
						pAv.Size = UDim2.new(0, 24, 0, 24)
						pAv.Position = UDim2.new(0, 6, 0.5, -12)
						pAv.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
						pAv.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(numUid) .. "&w=48&h=48"
						pAv.ZIndex = 4
						Instance.new("UICorner", pAv).CornerRadius = UDim.new(1, 0)

						local pName = Instance.new("TextLabel", pRow)
						pName.Size = UDim2.new(1, -42, 1, 0)
						pName.Position = UDim2.new(0, 38, 0, 0)
						pName.BackgroundTransparency = 1
						pName.TextColor3 = Color3.fromRGB(220, 220, 225)
						pName.Font = Enum.Font.BuilderSans
						pName.TextSize = 12
						pName.TextXAlignment = Enum.TextXAlignment.Left
						pName.Text = "User ID: " .. tostring(numUid)
						pName.ZIndex = 4

						task.spawn(function()
							pcall(function()
								local pNameStr = game:GetService("Players"):GetNameFromUserIdAsync(tonumber(numUid))
								pName.Text = pNameStr .. " (" .. tostring(numUid) .. ")"
							end)
						end)
					end
				end)

				local function toggleExpand()
					isExpanded = not isExpanded
					sub.Text = tostring(#userIds) .. (#userIds == 1 and " player" or " players")
						.. " • " .. tostring(jobId):sub(1, 8) .. (isExpanded and "  ▴" or "  ▾")
					local expandedHeight = 58 + (#userIds * 38) + 8
					local targetHeight = isExpanded and expandedHeight or 56
					tweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -6, 0, targetHeight),
						BackgroundColor3 = isExpanded and (isCurrentServer and Color3.fromRGB(22, 28, 36) or Color3.fromRGB(18, 18, 22)) or (isCurrentServer and Color3.fromRGB(20, 24, 30) or Color3.fromRGB(15, 15, 17))
					}):Play()
					tweenService:Create(details, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -24, 0, isExpanded and (expandedHeight - 64) or 0)
					}):Play()
				end

				headerBtn.MouseButton1Click:Connect(toggleExpand)
			end

			local function fetchGlobalServers()
				if refreshing then return end
				refreshing = true
				statusRow("Loading global servers...")
				task.spawn(function()
					local data = fetchGlobalUsersPayload()
					if not data then
						statusRow("Could not reach the server list.")
						refreshing = false
						return
					end

					local list = {}
					local totalCount = 0
					for placeId, jobs in pairs(data.servers) do
						if type(jobs) == "table" then
							for jobId, users in pairs(jobs) do
								local userList = normalizeUserList(users)
								if #userList > 0 then
									totalCount = totalCount + #userList
									list[#list + 1] = {
										place = tostring(placeId),
										job = tostring(jobId),
										users = userList,
										count = #userList
									}
								end
							end
						end
					end

					table.sort(list, function(a, b)
						local aIsCurrent = tostring(a.job) == tostring(game.JobId)
						local bIsCurrent = tostring(b.job) == tostring(game.JobId)
						if aIsCurrent ~= bIsCurrent then
							return aIsCurrent
						end
						local aCount = a.count or 0
						local bCount = b.count or 0
						if aCount ~= bCount then
							return aCount > bCount
						end
						return tostring(a.place) < tostring(b.place)
					end)

					for _, c in ipairs(GlobalServersScroll:GetChildren()) do
						if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
					end

					if #list == 0 then
						statusRow("No active Slate users online right now.")
						refreshing = false
						return
					end

					local totalUsersNum = tonumber(data.total_users) or totalCount
					local header = Instance.new("TextLabel", GlobalServersScroll)
					header.Size = UDim2.new(1, -6, 0, 18)
					header.LayoutOrder = 0
					header.BackgroundTransparency = 1
					header.Text = tostring(totalUsersNum) .. (totalUsersNum == 1 and " player online" or " players online") .. " across "
						.. tostring(#list) .. (#list == 1 and " server" or " servers")
					header.TextColor3 = Color3.fromRGB(110, 110, 115)
					header.Font = Enum.Font.BuilderSans
					header.TextSize = 11
					header.TextXAlignment = Enum.TextXAlignment.Left

					for i, entry in ipairs(list) do
						buildServerCard(entry.place, entry.job, entry.users, i, tostring(entry.job) == tostring(game.JobId))
					end
					refreshing = false
				end)
			end
			_G.refreshGlobalServers = fetchGlobalServers
		end

		do
			local csRefreshing = false

			local function csStatusRow(text)
				for _, c in ipairs(CurrentServerScroll:GetChildren()) do
					if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
				end
				local lbl = Instance.new("TextLabel", CurrentServerScroll)
				lbl.Size = UDim2.new(1, -6, 0, 44)
				lbl.BackgroundTransparency = 1
				lbl.Text = text
				lbl.TextColor3 = Color3.fromRGB(110, 110, 115)
				lbl.Font = Enum.Font.BuilderSans
				lbl.TextSize = 12
				lbl.TextWrapped = true
			end

			local function buildCurrentServerCard(userId, order)
				local isExpanded = false
				local frame = Instance.new("Frame", CurrentServerScroll)
				frame.Name = "CSUser_" .. tostring(userId)
				frame.Size = UDim2.new(1, -10, 0, 56)
				frame.ClipsDescendants = true
				frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
				frame.BorderSizePixel = 0
				frame.LayoutOrder = order
				Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
				local stroke = Instance.new("UIStroke", frame)
				stroke.Color = Color3.fromRGB(28, 28, 28)
				stroke.Thickness = 1
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

				frame.MouseEnter:Connect(function()
					if not isExpanded then
						tweenService:Create(frame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
						tweenService:Create(stroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(45, 45, 45)}):Play()
					end
				end)
				frame.MouseLeave:Connect(function()
					if not isExpanded then
						tweenService:Create(frame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(15, 15, 15)}):Play()
						tweenService:Create(stroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(28, 28, 28)}):Play()
					end
				end)

				local headerBtn = Instance.new("TextButton", frame)
				headerBtn.Size = UDim2.new(1, 0, 0, 56)
				headerBtn.BackgroundTransparency = 1
				headerBtn.Text = ""

				local thumbFrame = Instance.new("Frame", frame)
				thumbFrame.Name = "Thumb"
				thumbFrame.Size = UDim2.new(0, 38, 0, 38)
				thumbFrame.Position = UDim2.new(0, 10, 0, 9)
				thumbFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
				thumbFrame.BorderSizePixel = 0
				Instance.new("UICorner", thumbFrame).CornerRadius = UDim.new(1, 0)
				local tStroke = Instance.new("UIStroke", thumbFrame)
				tStroke.Color = Color3.fromRGB(32, 32, 32)
				tStroke.Thickness = 1.2
				local av = Instance.new("ImageLabel", thumbFrame)
				av.Size = UDim2.new(1, 0, 1, 0)
				av.BackgroundTransparency = 1
				av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
				Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

				local title = Instance.new("TextLabel", frame)
				title.Name = "PlayerNameLabel"
				title.Size = UDim2.new(1, -70, 0, 18)
				title.Position = UDim2.new(0, 58, 0, 11)
				title.BackgroundTransparency = 1
				title.TextColor3 = Color3.fromRGB(255, 255, 255)
				title.Font = Enum.Font.SourceSansBold
				title.TextSize = 14
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.TextTruncate = Enum.TextTruncate.AtEnd
				title.Text = "User " .. tostring(userId)

				local sub = Instance.new("TextLabel", frame)
				sub.Size = UDim2.new(1, -70, 0, 14)
				sub.Position = UDim2.new(0, 58, 0, 29)
				sub.BackgroundTransparency = 1
				sub.TextColor3 = Color3.fromRGB(120, 120, 120)
				sub.Font = Enum.Font.SourceSans
				sub.TextSize = 11
				sub.TextXAlignment = Enum.TextXAlignment.Left
				sub.TextTruncate = Enum.TextTruncate.AtEnd
				sub.Text = "Click to toggle actions"

				task.spawn(function()
					pcall(function()
						local name = game:GetService("Players"):GetNameFromUserIdAsync(tonumber(userId) or userId)
						title.Text = name
						sub.Text = "@" .. name .. " • Click to toggle actions"
					end)
				end)

				local actionsContainer = Instance.new("Frame", frame)
				actionsContainer.Name = "ExpandedActions"
				actionsContainer.Size = UDim2.new(1, -20, 0, 48)
				actionsContainer.Position = UDim2.new(0, 10, 0, 58)
				actionsContainer.BackgroundTransparency = 1
				local aLayout = Instance.new("UIListLayout", actionsContainer)
				aLayout.FillDirection = Enum.FillDirection.Horizontal
				aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				aLayout.VerticalAlignment = Enum.VerticalAlignment.Center
				aLayout.Padding = UDim.new(0, 12)

				local function makeCSIconBtn(iconId, callback)
					local b = Instance.new("ImageButton", actionsContainer)
					b.Size = UDim2.new(0, 40, 0, 40)
					b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
					b.Image = "rbxthumb://type=Asset&id=" .. tostring(iconId) .. "&w=420&h=420"
					b.ImageColor3 = Color3.fromRGB(240, 240, 245)
					b.ScaleType = Enum.ScaleType.Fit
					Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
					local s = Instance.new("UIStroke", b)
					s.Thickness = 1
					s.Color = Color3.fromRGB(45, 45, 52)
					b.MouseEnter:Connect(function()
						tweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
						tweenService:Create(s, TweenInfo.new(0.12), {Color = Color3.fromRGB(70, 70, 80)}):Play()
					end)
					b.MouseLeave:Connect(function()
						tweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}):Play()
						tweenService:Create(s, TweenInfo.new(0.12), {Color = Color3.fromRGB(45, 45, 52)}):Play()
					end)
					b.MouseButton1Click:Connect(function() callback(b) end)
					return b
				end

				-- Teleport to player
				makeCSIconBtn(102819382107866, function()
					local targetPlayer = game:GetService("Players"):GetPlayerByUserId(tonumber(userId) or userId)
					if targetPlayer then
						local char = targetPlayer.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
						if root and myRoot then
							myRoot.CFrame = root.CFrame * CFrame.new(0, 0, 3)
						end
					end
				end)

				-- View player
				local isViewing = false
				makeCSIconBtn(126439761728978, function(b)
					isViewing = not isViewing
					local targetPlayer = game:GetService("Players"):GetPlayerByUserId(tonumber(userId) or userId)
					if isViewing and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
						workspace.CurrentCamera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
						b.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
					else
						isViewing = false
						if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
							workspace.CurrentCamera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
						end
						b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
					end
				end)

				-- Hide player
				local isHidden = false
				makeCSIconBtn(86206257834504, function(b)
					isHidden = not isHidden
					local targetPlayer = game:GetService("Players"):GetPlayerByUserId(tonumber(userId) or userId)
					if isHidden then
						if hidePlayer and targetPlayer then hidePlayer(targetPlayer) end
						b.Image = "rbxthumb://type=Asset&id=100086900641425&w=420&h=420"
						b.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
					else
						if unhidePlayer and targetPlayer then unhidePlayer(targetPlayer) end
						b.Image = "rbxthumb://type=Asset&id=86206257834504&w=420&h=420"
						b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
					end
				end)

				-- Mute player
				local isMuted = false
				makeCSIconBtn(126302766179822, function(b)
					isMuted = not isMuted
					if setPlayerVoiceMuted then setPlayerVoiceMuted(tonumber(userId) or userId, isMuted) end
					if isMuted then
						b.Image = "rbxthumb://type=Asset&id=116911812027848&w=420&h=420"
						b.BackgroundColor3 = Color3.fromRGB(180, 90, 30)
					else
						b.Image = "rbxthumb://type=Asset&id=126302766179822&w=420&h=420"
						b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
					end
				end)

				-- Track/locate player
				makeCSIconBtn(77913721129068, function(b)
					local targetPlayer = game:GetService("Players"):GetPlayerByUserId(tonumber(userId) or userId)
					if targetPlayer then
						local tName = targetPlayer.Name
						locatedPlayers[tName] = not locatedPlayers[tName] or nil
						local isLoc = locatedPlayers[tName] == true
						createHighlight(targetPlayer)
						local highlight = espContainer:FindFirstChild(tName)
						if highlight then highlight.Enabled = isLoc or siriusValues.actions[7].enabled end
						b.BackgroundColor3 = isLoc and Color3.fromRGB(0, 140, 200) or Color3.fromRGB(22, 22, 26)
						queueNotification("Locate Player", (isLoc and "Tracking " or "Stopped tracking ") .. tName)
					else
						queueNotification("Locate Player", "Player not in this server")
					end
				end)

				headerBtn.MouseButton1Click:Connect(function()
					isExpanded = not isExpanded
					local targetHeight = isExpanded and 114 or 56
					tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, -10, 0, targetHeight),
						BackgroundColor3 = isExpanded and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(15, 15, 15)
					}):Play()
				end)
			end

			local function fetchCurrentServerUsers()
				if csRefreshing then return end
				csRefreshing = true
				csStatusRow("Loading current server users...")
				task.spawn(function()
					local data = fetchGlobalUsersPayload()
					if not data then
						csStatusRow("Failed to fetch current server data.")
						csRefreshing = false
						return
					end

					local currentJobId = tostring(game.JobId)
					local foundUsers = nil
					for placeId, jobs in pairs(data.servers) do
						if type(jobs) == "table" then
							for jobId, users in pairs(jobs) do
								if tostring(jobId) == currentJobId and type(users) == "table" then
									foundUsers = normalizeUserList(users)
									break
								end
							end
						end
						if foundUsers then break end
					end

					for _, c in ipairs(CurrentServerScroll:GetChildren()) do
						if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
					end

					if not foundUsers or #foundUsers == 0 then
						csStatusRow("No Slate users detected in this server.")
						csRefreshing = false
						return
					end

					local header = Instance.new("TextLabel", CurrentServerScroll)
					header.Size = UDim2.new(1, -6, 0, 18)
					header.LayoutOrder = 0
					header.BackgroundTransparency = 1
					header.Text = tostring(#foundUsers) .. " Slate user" .. (#foundUsers == 1 and "" or "s") .. " in this server"
					header.TextColor3 = Color3.fromRGB(110, 110, 115)
					header.Font = Enum.Font.BuilderSans
					header.TextSize = 11
					header.TextXAlignment = Enum.TextXAlignment.Left

					for i, uid in ipairs(foundUsers) do
						buildCurrentServerCard(uid, i)
					end
					csRefreshing = false
				end)
			end
			_G.refreshCurrentServer = fetchCurrentServerUsers
		end

		local function styleSubNavBtn(btn, text)
			btn.Size = UDim2.new(0.33, -4, 1, 0)
			btn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
			btn.Text = text
			btn.TextColor3 = Color3.fromRGB(150, 150, 160)
			btn.Font = Enum.Font.BuilderSansBold
			btn.TextSize = 12
			btn.AutoButtonColor = false
			local corner = Instance.new("UICorner", btn)
			corner.CornerRadius = UDim.new(0, 6)
			local stroke = Instance.new("UIStroke", btn)
			stroke.Color = Color3.fromRGB(38, 38, 44)
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			return stroke
		end

		btn1 = Instance.new("TextButton", subNav)
		stroke1 = styleSubNavBtn(btn1, "Server Players")

		btn2 = Instance.new("TextButton", subNav)
		stroke2 = styleSubNavBtn(btn2, "Current Server")

		btn3 = Instance.new("TextButton", subNav)
		stroke3 = styleSubNavBtn(btn3, "Global Servers")

		local currentSubTab = 1
		local function selectSubTab(tabIndex)
			currentSubTab = tabIndex
			PlayersScroll.Visible = (tabIndex == 1)
			CurrentServerScroll.Visible = (tabIndex == 2)
			GlobalServersScroll.Visible = (tabIndex == 3)

			local btns = { {btn = btn1, strk = stroke1, idx = 1}, {btn = btn2, strk = stroke2, idx = 2}, {btn = btn3, strk = stroke3, idx = 3} }
			for _, b in ipairs(btns) do
				local isActive = (b.idx == tabIndex)
				tweenService:Create(b.btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = isActive and Color3.fromRGB(32, 32, 38) or Color3.fromRGB(16, 16, 20),
					TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)
				}):Play()
				tweenService:Create(b.strk, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Color = isActive and Color3.fromRGB(65, 65, 78) or Color3.fromRGB(30, 30, 36)
				}):Play()
			end
		end

		local function attachHover(btn, strk, idx)
			btn.MouseEnter:Connect(function()
				if currentSubTab ~= idx then
					tweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundColor3 = Color3.fromRGB(24, 24, 30),
						TextColor3 = Color3.fromRGB(200, 200, 210)
					}):Play()
					tweenService:Create(strk, TweenInfo.new(0.15), {
						Color = Color3.fromRGB(48, 48, 58)
					}):Play()
				end
			end)
			btn.MouseLeave:Connect(function()
				if currentSubTab ~= idx then
					tweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundColor3 = Color3.fromRGB(16, 16, 20),
						TextColor3 = Color3.fromRGB(140, 140, 150)
					}):Play()
					tweenService:Create(strk, TweenInfo.new(0.15), {
						Color = Color3.fromRGB(30, 30, 36)
					}):Play()
				end
			end)
		end
		attachHover(btn1, stroke1, 1)
		attachHover(btn2, stroke2, 2)
		attachHover(btn3, stroke3, 3)

		selectSubTab(1)
		btn1.MouseButton1Click:Connect(function() selectSubTab(1) end)
		btn2.MouseButton1Click:Connect(function()
			selectSubTab(2)
			if _G.refreshCurrentServer then _G.refreshCurrentServer() end
		end)
		btn3.MouseButton1Click:Connect(function()
			selectSubTab(3)
			if _G.refreshGlobalServers then _G.refreshGlobalServers() end
		end)
		end
		_init_block_8821()
	end

	do
		local function _init_block_8954()
		local SP_W, SP_H = 340, 435
		SpotifyWindow = Instance.new("Frame", G2L["1"])
		end
		_init_block_8954()
	end
	do
		local function _init_block_8958()
		SpotifyWindow.Name = "SlateMusicPlayerFloating"
		SpotifyWindow.BorderSizePixel = 0
		SpotifyWindow.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
		SpotifyWindow.Size = UDim2.new(0, 340, 0, 435)
		SpotifyWindow.Position = UDim2.new(0.5, -170, 0.5, -217)
		SpotifyWindow.Visible = false
		SpotifyWindow.Active = true
		SpotifyWindow.ClipsDescendants = true
		Instance.new("UICorner", SpotifyWindow).CornerRadius = UDim.new(0, 16)
		local SpotifyStroke = Instance.new("UIStroke", SpotifyWindow)
		SpotifyStroke.Thickness = 0.99
		SpotifyStroke.Color = Color3.fromRGB(32, 32, 34)
		createSlateBackdrop(SpotifyWindow, 16, { zIndex = 0, intensity = 0.9 })

		AlbumCover = Instance.new("ImageLabel", SpotifyWindow)
		AlbumCover.Name = "AlbumCover"
		AlbumCover.Size = UDim2.new(1, 0, 1, 0)
		AlbumCover.Position = UDim2.new(0, 0, 0, 0)
		AlbumCover.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
		AlbumCover.BorderSizePixel = 0
		AlbumCover.Image = "rbxassetid://73264766715941"
		AlbumCover.ScaleType = Enum.ScaleType.Crop
		AlbumCover.ZIndex = 2
		Instance.new("UICorner", AlbumCover).CornerRadius = UDim.new(0, 16)

		local scrimFrame = Instance.new("Frame", SpotifyWindow)
		scrimFrame.Name = "Scrim"
		scrimFrame.Size = UDim2.new(1, 0, 1, 0)
		scrimFrame.Position = UDim2.new(0, 0, 0, 0)
		scrimFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
		scrimFrame.BorderSizePixel = 0
		scrimFrame.ZIndex = 3
		Instance.new("UICorner", scrimFrame).CornerRadius = UDim.new(0, 16)
		local scrimGrad = Instance.new("UIGradient", scrimFrame)
		scrimGrad.Rotation = 90
		scrimGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.48, 0.9),
			NumberSequenceKeypoint.new(0.78, 0.12),
			NumberSequenceKeypoint.new(1, 0),
		})

		BackgroundCover = Instance.new("ImageLabel", SpotifyWindow)
		BackgroundCover.Name = "BackgroundCover"
		BackgroundCover.Size = UDim2.new(1, 0, 1, 0)
		BackgroundCover.Position = UDim2.new(0, 0, 0, 0)
		BackgroundCover.BackgroundTransparency = 1
		BackgroundCover.Image = "rbxassetid://73264766715941"
		BackgroundCover.ScaleType = Enum.ScaleType.Crop
		BackgroundCover.ImageTransparency = 0.55
		BackgroundCover.ZIndex = 1
		Instance.new("UICorner", BackgroundCover).CornerRadius = UDim.new(0, 16)

		local ContentY = 270
		local SIDE = 18

		local SpotifyCloseBtn = Instance.new("TextButton", SpotifyWindow)
		SpotifyCloseBtn.Name = "CloseBtn"
		SpotifyCloseBtn.Size = UDim2.new(0, 24, 0, 24)
		SpotifyCloseBtn.Position = UDim2.new(1, -32, 0, 12)
		SpotifyCloseBtn.BackgroundTransparency = 1
		SpotifyCloseBtn.Text = "×"
		SpotifyCloseBtn.TextSize = 18
		SpotifyCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		SpotifyCloseBtn.Font = Enum.Font.GothamBold
		SpotifyCloseBtn.ZIndex = 10
		SpotifyCloseBtn.BorderSizePixel = 0
		SpotifyCloseBtn.MouseButton1Click:Connect(function() SpotifyWindow.Visible = false end)

		SongLabel = Instance.new("TextLabel", SpotifyWindow)
		SongLabel.Size = UDim2.new(0.64, 0, 0, 22)
		SongLabel.Position = UDim2.new(0, SIDE, 0, ContentY + 6)
		SongLabel.BackgroundTransparency = 1
		SongLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		SongLabel.TextSize = 16.5
		SongLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		SongLabel.Text = "No Track Playing"
		SongLabel.TextXAlignment = Enum.TextXAlignment.Left
		SongLabel.TextTruncate = Enum.TextTruncate.AtEnd
		SongLabel.ZIndex = 5

		ArtistLabel = Instance.new("TextLabel", SpotifyWindow)
		ArtistLabel.Size = UDim2.new(0.64, 0, 0, 18)
		ArtistLabel.Position = UDim2.new(0, SIDE, 0, ContentY + 30)
		ArtistLabel.BackgroundTransparency = 1
		ArtistLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
		ArtistLabel.TextSize = 13
		ArtistLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		ArtistLabel.Text = "Search & play any song for free"
		ArtistLabel.TextXAlignment = Enum.TextXAlignment.Left
		ArtistLabel.TextTruncate = Enum.TextTruncate.AtEnd
		ArtistLabel.ZIndex = 5

		local SubVolArea = Instance.new("Frame", SpotifyWindow)
		SubVolArea.Name = "SubVolArea"
		SubVolArea.Size = UDim2.new(0, 95, 0, 16)
		SubVolArea.Position = UDim2.new(1, -SIDE - 95, 0, ContentY + 30)
		SubVolArea.BackgroundTransparency = 1
		SubVolArea.ZIndex = 5

		local subVolIcon = Instance.new("ImageLabel", SubVolArea)
		subVolIcon.Size = UDim2.new(0, 14, 0, 14)
		subVolIcon.Position = UDim2.new(0, 0, 0.5, -7)
		subVolIcon.BackgroundTransparency = 1
		subVolIcon.Image = "rbxthumb://type=Asset&id=113463212610691&w=150&h=150"
		subVolIcon.ImageColor3 = Color3.fromRGB(140, 140, 150)
		subVolIcon.ZIndex = 5

		local subVolTrack = Instance.new("Frame", SubVolArea)
		subVolTrack.Size = UDim2.new(0, 72, 0, 6)
		subVolTrack.Position = UDim2.new(0, 20, 0.5, -4)
		subVolTrack.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
		subVolTrack.BorderSizePixel = 0
		subVolTrack.ZIndex = 5
		Instance.new("UICorner", subVolTrack).CornerRadius = UDim.new(1, 0)

		local subVolFill = Instance.new("Frame", subVolTrack)
		subVolFill.Size = UDim2.new(0.75, 0, 1, 0)
		subVolFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		subVolFill.BorderSizePixel = 0
		subVolFill.ZIndex = 5
		Instance.new("UICorner", subVolFill).CornerRadius = UDim.new(1, 0)

		local subVolGrad = Instance.new("UIGradient", subVolFill)
		subVolGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 34)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 48, 50)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 160, 165))
		})

		local subVolKnob = Instance.new("Frame", subVolFill)
		subVolKnob.Size = UDim2.new(0, 14, 0, 14)
		subVolKnob.AnchorPoint = Vector2.new(0.5, 0.5)
		subVolKnob.Position = UDim2.new(1, 0, 0.5, 0)
		subVolKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		subVolKnob.BackgroundTransparency = 0
		subVolKnob.BorderSizePixel = 0
		subVolKnob.ZIndex = 7
		Instance.new("UICorner", subVolKnob).CornerRadius = UDim.new(1, 0)
		local subVolStroke = Instance.new("UIStroke", subVolKnob)
		subVolStroke.Color = Color3.fromRGB(160, 160, 165)
		subVolStroke.Transparency = 0.35
		subVolStroke.Thickness = 1.4

		local subVolClickBtn = Instance.new("TextButton", subVolTrack)
		subVolClickBtn.Size = UDim2.new(1, 0, 4, 0)
		subVolClickBtn.Position = UDim2.new(0, 0, -1.5, 0)
		subVolClickBtn.BackgroundTransparency = 1
		subVolClickBtn.Text = ""
		subVolClickBtn.ZIndex = 8

		local isDraggingSubVol = false
		local function updateSubVol(input)
			local frac = math.clamp((input.Position.X - subVolTrack.AbsolutePosition.X) / subVolTrack.AbsoluteSize.X, 0, 1)
			tweenService:Create(subVolFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(frac, 0, 1, 0)}):Play()
			if _G.SlateSyncVolFill then
				tweenService:Create(_G.SlateSyncVolFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(frac, 0, 1, 0)}):Play()
			end
			if _G.SlateMusicSetVolume then _G.SlateMusicSetVolume(frac) end
		end

		subVolClickBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDraggingSubVol = true
				tweenService:Create(subVolKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 0.45}):Play()
				tweenService:Create(subVolStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.1, Thickness = 1.8}):Play()
				updateSubVol(input)
			end
		end)
		userInputService.InputChanged:Connect(function(input)
			if isDraggingSubVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateSubVol(input)
			end
		end)
		userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if isDraggingSubVol then
					isDraggingSubVol = false
					tweenService:Create(subVolKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0}):Play()
					tweenService:Create(subVolStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.35, Thickness = 1.4}):Play()
				end
			end
		end)

		_G.SlateSyncSubVolFill = subVolFill

		local PROG_Y = ContentY + 56
		local ProgressFrame = Instance.new("Frame", SpotifyWindow)
		ProgressFrame.Name = "ProgressFrame"
		ProgressFrame.Size = UDim2.new(1, -SIDE*2, 0, 8)
		ProgressFrame.Position = UDim2.new(0, SIDE, 0, PROG_Y)
		ProgressFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
		ProgressFrame.BorderSizePixel = 0
		ProgressFrame.ZIndex = 5
		Instance.new("UICorner", ProgressFrame).CornerRadius = UDim.new(1, 0)

		ProgressBarFill = Instance.new("Frame", ProgressFrame)
		ProgressBarFill.Name = "Fill"
		ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
		ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ProgressBarFill.BorderSizePixel = 0
		ProgressBarFill.ZIndex = 5
		Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(1, 0)

		local subProgGrad = Instance.new("UIGradient", ProgressBarFill)
		subProgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 34)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 48, 50)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 160, 165))
		})

		local subProgKnob = Instance.new("Frame", ProgressBarFill)
		subProgKnob.Size = UDim2.new(0, 18, 0, 18)
		subProgKnob.AnchorPoint = Vector2.new(0.5, 0.5)
		subProgKnob.Position = UDim2.new(1, 0, 0.5, 0)
		subProgKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		subProgKnob.BackgroundTransparency = 0
		subProgKnob.BorderSizePixel = 0
		subProgKnob.ZIndex = 7
		Instance.new("UICorner", subProgKnob).CornerRadius = UDim.new(1, 0)
		local subProgStroke = Instance.new("UIStroke", subProgKnob)
		subProgStroke.Color = Color3.fromRGB(160, 160, 165)
		subProgStroke.Transparency = 0.35
		subProgStroke.Thickness = 1.4

		local subProgClickBtn = Instance.new("TextButton", ProgressFrame)
		subProgClickBtn.Size = UDim2.new(1, 0, 4, 0)
		subProgClickBtn.Position = UDim2.new(0, 0, 0.5, -8)
		subProgClickBtn.BackgroundTransparency = 1
		subProgClickBtn.Text = ""
		subProgClickBtn.ZIndex = 8

		local isScrubbingSub = false
		local function updateSubScrub(input)
			local absPos = ProgressFrame.AbsolutePosition
			local absSize = ProgressFrame.AbsoluteSize
			local pct = math.clamp((input.Position.X - absPos.X) / math.max(absSize.X, 1), 0, 1)
			tweenService:Create(ProgressBarFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
			if _G.SlateDeckProgFill then
				tweenService:Create(_G.SlateDeckProgFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
			end
			local total = _G.SlateMusicTotalDuration or 0
			if total > 0 then
				local curSec = pct * total
				local m = math.floor(curSec / 60)
				local s = math.floor(curSec % 60)
				local str = string.format("%d:%02d", m, s)
				if TimeCurrent then TimeCurrent.Text = str end
				if _G.SlateDeckTimeCurrent then _G.SlateDeckTimeCurrent.Text = str end
			end
			return pct
		end

		subProgClickBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isScrubbingSub = true
				_G.SlateIsScrubbing = true
				tweenService:Create(subProgKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 0.45}):Play()
				tweenService:Create(subProgStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.1, Thickness = 1.8}):Play()
				local pct = updateSubScrub(input)
				local total = _G.SlateMusicTotalDuration or 0
				if total > 0 and _G.SlateMusicSeek then _G.SlateMusicSeek(pct * total) end
			end
		end)
		userInputService.InputChanged:Connect(function(input)
			if isScrubbingSub and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateSubScrub(input)
			end
		end)
		userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if isScrubbingSub then
					local pct = updateSubScrub(input)
					isScrubbingSub = false
					_G.SlateIsScrubbing = false
					tweenService:Create(subProgKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0}):Play()
					tweenService:Create(subProgStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.35, Thickness = 1.4}):Play()
					local total = _G.SlateMusicTotalDuration or 0
					if total > 0 and _G.SlateMusicSeek then _G.SlateMusicSeek(pct * total) end
				end
			end
		end)

		TimeCurrent = Instance.new("TextLabel", SpotifyWindow)
		TimeCurrent.Size = UDim2.new(0, 36, 0, 12)
		TimeCurrent.Position = UDim2.new(0, SIDE, 0, PROG_Y + 6)
		TimeCurrent.BackgroundTransparency = 1
		TimeCurrent.TextColor3 = Color3.fromRGB(140, 140, 150)
		TimeCurrent.Text = "0:00"
		TimeCurrent.TextSize = 9.5
		TimeCurrent.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		TimeCurrent.TextXAlignment = Enum.TextXAlignment.Left
		TimeCurrent.ZIndex = 5

		TimeLength = Instance.new("TextLabel", SpotifyWindow)
		TimeLength.Size = UDim2.new(0, 36, 0, 12)
		TimeLength.Position = UDim2.new(1, -SIDE - 36, 0, PROG_Y + 6)
		TimeLength.BackgroundTransparency = 1
		TimeLength.TextColor3 = Color3.fromRGB(140, 140, 150)
		TimeLength.Text = "0:00"
		TimeLength.TextSize = 9.5
		TimeLength.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		TimeLength.TextXAlignment = Enum.TextXAlignment.Right
		TimeLength.ZIndex = 5

		local CTRL_Y = PROG_Y + 26
		local ControlPanel = Instance.new("Frame", SpotifyWindow)
		ControlPanel.Size = UDim2.new(1, -SIDE*2, 0, 44)
		ControlPanel.Position = UDim2.new(0, SIDE, 0, CTRL_Y)
		ControlPanel.BackgroundTransparency = 1
		ControlPanel.ZIndex = 5

		local function makeCtrlBtn(name, imageId, pos, sz)
			local s = sz or UDim2.new(0, 24, 0, 24)
			local btn = Instance.new("ImageButton", ControlPanel)
			btn.Name = name
			btn.Size = s
			btn.Position = pos
			btn.BackgroundTransparency = 1
			btn.Image = "rbxthumb://type=Asset&id=" .. tostring(imageId) .. "&w=150&h=150"
			btn.ZIndex = 10
			return btn
		end

		ShuffleBtn = Instance.new("ImageButton", ControlPanel)
		ShuffleBtn.Name = "Shuffle"
		ShuffleBtn.Size = UDim2.new(0, 20, 0, 20)
		ShuffleBtn.Position = UDim2.new(0, 0, 0.5, -10)
		ShuffleBtn.BackgroundTransparency = 1
		ShuffleBtn.Image = "rbxthumb://type=Asset&id=94650983879976&w=150&h=150"
		ShuffleBtn.ImageColor3 = Color3.fromRGB(110, 110, 120)
		ShuffleBtn.Active = true
		ShuffleBtn.ZIndex = 10
		_G.SlateShuffleBtn = ShuffleBtn

		local subShuffleDot = Instance.new("Frame", ShuffleBtn)
		subShuffleDot.Size = UDim2.new(0, 4, 0, 4)
		subShuffleDot.Position = UDim2.new(0.5, -2, 1, 2)
		subShuffleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		subShuffleDot.BorderSizePixel = 0
		subShuffleDot.ZIndex = 11
		subShuffleDot.Visible = false
		Instance.new("UICorner", subShuffleDot).CornerRadius = UDim.new(1, 0)
		_G.SlateSubShuffleDot = subShuffleDot

		SpotifyBackBtn = makeCtrlBtn("Back",  71548511105097,  UDim2.new(0, 48,  0.5, -12), UDim2.new(0, 24, 0, 24))
		SpotifyPlayBtn = makeCtrlBtn("Play",  72060836325473,  UDim2.new(0.5, -19, 0.5, -19), UDim2.new(0, 38, 0, 38))
		SpotifyNextBtn = makeCtrlBtn("Next",  139048122674967, UDim2.new(1, -72,  0.5, -12), UDim2.new(0, 24, 0, 24))
		SpotifyPlayBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
		SpotifyPlayBtn.ZIndex = 10

		RepeatBtn = Instance.new("ImageButton", ControlPanel)
		RepeatBtn.Name = "Repeat"
		RepeatBtn.Size = UDim2.new(0, 20, 0, 20)
		RepeatBtn.Position = UDim2.new(1, -20, 0.5, -10)
		RepeatBtn.BackgroundTransparency = 1
		RepeatBtn.Image = "rbxthumb://type=Asset&id=138997712866797&w=150&h=150"
		RepeatBtn.ImageColor3 = Color3.fromRGB(110, 110, 120)
		RepeatBtn.Active = true
		RepeatBtn.ZIndex = 10

		local subRepeatBadge = Instance.new("TextLabel", RepeatBtn)
		subRepeatBadge.Size = UDim2.new(1, 0, 1, 0)
		subRepeatBadge.BackgroundTransparency = 1
		subRepeatBadge.Text = "1"
		subRepeatBadge.Font = Enum.Font.GothamBold
		subRepeatBadge.TextSize = 7.5
		subRepeatBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		subRepeatBadge.ZIndex = 11
		subRepeatBadge.Visible = false
		_G.SlateSubRepeatBadge = subRepeatBadge

		makeDraggable(SpotifyWindow, SpotifyWindow)
		end
		_init_block_8958()
	end

	do
		local function _init_block_9424()
		local _memAssetCache = {}
		local function fetchMediaUrl(url)
			if not url or url == "" then return nil end
			if _memAssetCache[url] then return _memAssetCache[url] end
			local reqFunc = http_request or request or (syn and syn.request) or (http and http.request)
			if reqFunc then
				local ok, res = pcall(reqFunc, { Url = url, Method = "GET" })
				if ok and res and res.Body then
					_memAssetCache[url] = res.Body
					return res.Body
				end
			end
			if game.HttpGet then
				local ok, res = pcall(game.HttpGet, game, url)
				if ok and res then
					_memAssetCache[url] = res
					return res
				end
			end
			return nil
		end

		MusicTab = createTabFrame("MusicTab")
		addLabel(MusicTab, "Music Player", UDim2.new(0, 300, 0, 32), UDim2.new(0.03, 0, 0.052, 0), true)

		local SpIcons = {

			Home = "rbxthumb://type=Asset&id=131020769964098&w=150&h=150",
			Search = "rbxthumb://type=Asset&id=109780006242898&w=150&h=150",
			Library = "rbxthumb://type=Asset&id=75917296332880&w=150&h=150",

			StarFilled = "rbxthumb://type=Asset&id=134278442967616&w=150&h=150",
			StarOutline = "rbxthumb://type=Asset&id=93715138313453&w=150&h=150",
			Plus = "rbxthumb://type=Asset&id=86021845470735&w=150&h=150",
			DeleteTrack = "rbxthumb://type=Asset&id=128430541943949&w=150&h=150",
			Volume = "rbxthumb://type=Asset&id=113463212610691&w=150&h=150",
			SpotifyLogo = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150",

			Play = "rbxthumb://type=Asset&id=72060836325473&w=150&h=150",
			Pause = "rbxthumb://type=Asset&id=128672888655850&w=150&h=150",
			Prev = "rbxthumb://type=Asset&id=71548511105097&w=150&h=150",
			Next = "rbxthumb://type=Asset&id=139048122674967&w=150&h=150",
			Volume = "rbxthumb://type=Asset&id=113463212610691&w=150&h=150",
			Shuffle = "rbxthumb://type=Asset&id=94650983879976&w=150&h=150",
			Repeat = "rbxthumb://type=Asset&id=138997712866797&w=150&h=150",
			Popout = "rbxthumb://type=Asset&id=95181728682391&w=150&h=150"
		}

		local function formatCompactCount(n)
			n = tonumber(n) or 0
			if n >= 1000000 then
				return (string.format("%.1fM", n / 1000000):gsub("%.0M$", "M"))
			elseif n >= 100000 then
				return string.format("%dK", math.floor(n / 1000))
			elseif n >= 1000 then
				return (string.format("%.1fK", n / 1000):gsub("%.0K$", "K"))
			end
			return tostring(math.floor(n))
		end

		local createSongCard, openArtistView, closeArtistView

		local SpotifyNav = Instance.new("Frame", MusicTab)
		SpotifyNav.Name = "SpotifySubNav"
		SpotifyNav.Size = UDim2.new(0.92, 0, 0, 26)
		SpotifyNav.Position = UDim2.new(0.04, 0, 0.18, 0)
		SpotifyNav.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		SpotifyNav.BorderSizePixel = 0
		Instance.new("UICorner", SpotifyNav).CornerRadius = UDim.new(0, 7)
		local snStroke = Instance.new("UIStroke", SpotifyNav)
		snStroke.Color = Color3.fromRGB(30, 30, 36)
		snStroke.Thickness = 0.8
		local snLayout = Instance.new("UIListLayout", SpotifyNav)
		snLayout.FillDirection = Enum.FillDirection.Horizontal
		snLayout.Padding = UDim.new(0, 0)

		local function createNavTab(name, title, iconId, isDefault)
			local btn = Instance.new("TextButton", SpotifyNav)
			btn.Name = name .. "TabBtn"
			btn.Size = UDim2.new(0.3333, 0, 1, 0)
			btn.BackgroundColor3 = isDefault and Color3.fromRGB(34, 34, 40) or Color3.fromRGB(15, 15, 18)
			btn.BackgroundTransparency = isDefault and 0 or 1
			btn.BorderSizePixel = 0
			btn.Text = "      " .. title
			btn.TextColor3 = isDefault and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 11
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

			local icon = Instance.new("ImageLabel", btn)
			icon.Size = UDim2.new(0, 14, 0, 14)
			icon.Position = UDim2.new(0.2, -7, 0.5, -7)
			icon.BackgroundTransparency = 1
			icon.Image = iconId
			icon.ImageColor3 = isDefault and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)

			return btn, icon
		end

		local homeTabBtn, homeIcon = createNavTab("Home", "Home", SpIcons.Home, true)
		local searchTabBtn, searchIcon = createNavTab("Search", "Search", SpIcons.Search, false)
		local libraryTabBtn, libIcon = createNavTab("Library", "Your Library", SpIcons.Library, false)

		local ContentContainer = Instance.new("Frame", MusicTab)
		ContentContainer.Name = "ContentContainer"
		ContentContainer.Size = UDim2.new(0.92, 0, 0, 232)
		ContentContainer.Position = UDim2.new(0.04, 0, 0.264, 0)
		ContentContainer.BackgroundTransparency = 1
		ContentContainer.BorderSizePixel = 0

		local PlaylistDrawer = Instance.new("Frame", ContentContainer)
		PlaylistDrawer.Name = "PlaylistDrawer"
		PlaylistDrawer.Size = UDim2.new(1, 0, 1, 0)
		PlaylistDrawer.Position = UDim2.new(0, 0, 0, 0)
		PlaylistDrawer.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
		PlaylistDrawer.BackgroundTransparency = 0.02
		PlaylistDrawer.BorderSizePixel = 0
		PlaylistDrawer.ZIndex = 25
		PlaylistDrawer.Visible = false
		Instance.new("UICorner", PlaylistDrawer).CornerRadius = UDim.new(0, 8)
		local pdStroke = Instance.new("UIStroke", PlaylistDrawer)
		pdStroke.Color = Color3.fromRGB(32, 32, 40)
		pdStroke.Thickness = 0.8

		local pdHeader = Instance.new("Frame", PlaylistDrawer)
		pdHeader.Size = UDim2.new(1, 0, 0, 36)
		pdHeader.BackgroundTransparency = 1
		pdHeader.ZIndex = 26

		local pdTitle = Instance.new("TextLabel", pdHeader)
		pdTitle.Size = UDim2.new(0.7, 0, 0, 16)
		pdTitle.Position = UDim2.new(0, 12, 0, 4)
		pdTitle.BackgroundTransparency = 1
		pdTitle.Text = "Add to Playlist"
		pdTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		pdTitle.Font = Enum.Font.GothamBold
		pdTitle.TextSize = 12
		pdTitle.TextXAlignment = Enum.TextXAlignment.Left
		pdTitle.ZIndex = 26

		local pdSub = Instance.new("TextLabel", pdHeader)
		pdSub.Size = UDim2.new(0.7, 0, 0, 12)
		pdSub.Position = UDim2.new(0, 12, 0, 20)
		pdSub.BackgroundTransparency = 1
		pdSub.TextColor3 = Color3.fromRGB(130, 130, 140)
		pdSub.Font = Enum.Font.Gotham
		pdSub.TextSize = 10
		pdSub.TextXAlignment = Enum.TextXAlignment.Left
		pdSub.TextTruncate = Enum.TextTruncate.AtEnd
		pdSub.Text = "Choose a playlist"
		pdSub.ZIndex = 26

		local pdClose = Instance.new("TextButton", pdHeader)
		pdClose.Size = UDim2.new(0, 24, 0, 24)
		pdClose.Position = UDim2.new(1, -30, 0.5, -12)
		pdClose.BackgroundTransparency = 1
		pdClose.Text = "×"
		pdClose.TextColor3 = Color3.fromRGB(150, 150, 160)
		pdClose.Font = Enum.Font.GothamBold
		pdClose.TextSize = 16
		pdClose.ZIndex = 26
		pdClose.MouseButton1Click:Connect(function()
			PlaylistDrawer.Visible = false
		end)

		local pdScroll = Instance.new("ScrollingFrame", PlaylistDrawer)
		pdScroll.Size = UDim2.new(1, -16, 1, -44)
		pdScroll.Position = UDim2.new(0, 8, 0, 40)
		pdScroll.BackgroundTransparency = 1
		pdScroll.BorderSizePixel = 0
		pdScroll.ScrollBarThickness = 0
		pdScroll.ScrollBarImageTransparency = 1
		pdScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		pdScroll.ZIndex = 26
		local pdLayout = Instance.new("UIListLayout", pdScroll)
		pdLayout.Padding = UDim.new(0, 5)

		local function openPlaylistPicker(track)
			if not track then return end
			pdSub.Text = tostring(track.title or "Select Playlist")

			for _, child in ipairs(pdScroll:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
			end

			local playlists = _G.SlateMusicGetPlaylists and _G.SlateMusicGetPlaylists() or {}
			for plName, list in pairs(playlists) do
				local itemBtn = Instance.new("TextButton", pdScroll)
				itemBtn.Size = UDim2.new(1, -4, 0, 36)
				itemBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
				itemBtn.BorderSizePixel = 0
				itemBtn.Text = ""
				itemBtn.ZIndex = 27
				Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)

				local icon = Instance.new("ImageLabel", itemBtn)
				icon.Size = UDim2.new(0, 16, 0, 16)
				icon.Position = UDim2.new(0, 10, 0.5, -8)
				icon.BackgroundTransparency = 1
				icon.Image = (plName == "Favorites") and SpIcons.StarFilled or SpIcons.Library
				icon.ImageColor3 = (plName == "Favorites") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 180, 190)
				icon.ZIndex = 28

				local lbl = Instance.new("TextLabel", itemBtn)
				lbl.Size = UDim2.new(0.6, 0, 0, 16)
				lbl.Position = UDim2.new(0, 34, 0.5, -8)
				lbl.BackgroundTransparency = 1
				lbl.Text = plName
				lbl.TextColor3 = Color3.fromRGB(240, 240, 245)
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 11.5
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 28

				local countLbl = Instance.new("TextLabel", itemBtn)
				countLbl.Size = UDim2.new(0.3, 0, 0, 14)
				countLbl.Position = UDim2.new(1, -70, 0.5, -7)
				countLbl.BackgroundTransparency = 1
				countLbl.Text = tostring(#list) .. " tracks"
				countLbl.TextColor3 = Color3.fromRGB(110, 110, 120)
				countLbl.Font = Enum.Font.Gotham
				countLbl.TextSize = 10
				countLbl.TextXAlignment = Enum.TextXAlignment.Right
				countLbl.ZIndex = 28

				itemBtn.MouseEnter:Connect(function()
					tweenService:Create(itemBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
				end)
				itemBtn.MouseLeave:Connect(function()
					tweenService:Create(itemBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
				end)

				itemBtn.MouseButton1Click:Connect(function()
					if _G.SlateMusicAddToPlaylist then
						local added = _G.SlateMusicAddToPlaylist(plName, track)
						queueNotification("Playlist", added and ("Added to " .. plName) or ("Already in " .. plName), 2)
					end
					PlaylistDrawer.Visible = false
				end)
			end

			PlaylistDrawer.Visible = true
		end

		local EqPanel = Instance.new("Frame", ContentContainer)
		EqPanel.Name = "EqualizerPanel"
		EqPanel.Size = UDim2.new(1, 0, 1, 0)
		EqPanel.Position = UDim2.new(0, 0, 0, 0)
		EqPanel.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
		EqPanel.BackgroundTransparency = 0.02
		EqPanel.BorderSizePixel = 0
		EqPanel.ZIndex = 30
		EqPanel.Visible = false
		Instance.new("UICorner", EqPanel).CornerRadius = UDim.new(0, 8)
		local eqPanelStroke = Instance.new("UIStroke", EqPanel)
		eqPanelStroke.Color = Color3.fromRGB(32, 32, 40)
		eqPanelStroke.Thickness = 0.8

		local eqTitle = Instance.new("TextLabel", EqPanel)
		eqTitle.Size = UDim2.new(0.6, 0, 0, 16)
		eqTitle.Position = UDim2.new(0, 12, 0, 8)
		eqTitle.BackgroundTransparency = 1
		eqTitle.Text = "Equalizer"
		eqTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		eqTitle.Font = Enum.Font.GothamBold
		eqTitle.TextSize = 12.5
		eqTitle.TextXAlignment = Enum.TextXAlignment.Left
		eqTitle.ZIndex = 31

		local eqSub = Instance.new("TextLabel", EqPanel)
		eqSub.Size = UDim2.new(0.6, 0, 0, 12)
		eqSub.Position = UDim2.new(0, 12, 0, 24)
		eqSub.BackgroundTransparency = 1
		eqSub.Text = "Off"
		eqSub.TextColor3 = Color3.fromRGB(130, 130, 140)
		eqSub.Font = Enum.Font.Gotham
		eqSub.TextSize = 10
		eqSub.TextXAlignment = Enum.TextXAlignment.Left
		eqSub.ZIndex = 31

		local eqClose = Instance.new("TextButton", EqPanel)
		eqClose.Size = UDim2.new(0, 24, 0, 24)
		eqClose.Position = UDim2.new(1, -30, 0, 6)
		eqClose.BackgroundTransparency = 1
		eqClose.Text = "×"
		eqClose.TextColor3 = Color3.fromRGB(150, 150, 160)
		eqClose.Font = Enum.Font.GothamBold
		eqClose.TextSize = 16
		eqClose.ZIndex = 31
		eqClose.MouseButton1Click:Connect(function()
			EqPanel.Visible = false
		end)

		local eqSwitch = Instance.new("TextButton", EqPanel)
		eqSwitch.Name = "EqSwitch"
		eqSwitch.Size = UDim2.new(0, 34, 0, 18)
		eqSwitch.Position = UDim2.new(1, -70, 0, 9)
		eqSwitch.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
		eqSwitch.BorderSizePixel = 0
		eqSwitch.Text = ""
		eqSwitch.AutoButtonColor = false
		eqSwitch.ZIndex = 31
		Instance.new("UICorner", eqSwitch).CornerRadius = UDim.new(1, 0)

		local eqSwitchKnob = Instance.new("Frame", eqSwitch)
		eqSwitchKnob.Size = UDim2.new(0, 14, 0, 14)
		eqSwitchKnob.Position = UDim2.new(0, 2, 0.5, -7)
		eqSwitchKnob.BackgroundColor3 = Color3.fromRGB(120, 120, 132)
		eqSwitchKnob.BorderSizePixel = 0
		eqSwitchKnob.ZIndex = 32
		Instance.new("UICorner", eqSwitchKnob).CornerRadius = UDim.new(1, 0)

		local eqPresetsLbl = Instance.new("TextLabel", EqPanel)
		eqPresetsLbl.Size = UDim2.new(1, -24, 0, 12)
		eqPresetsLbl.Position = UDim2.new(0, 12, 0, 44)
		eqPresetsLbl.BackgroundTransparency = 1
		eqPresetsLbl.Text = "PRESETS"
		eqPresetsLbl.TextColor3 = Color3.fromRGB(100, 100, 112)
		eqPresetsLbl.Font = Enum.Font.GothamBold
		eqPresetsLbl.TextSize = 9
		eqPresetsLbl.TextXAlignment = Enum.TextXAlignment.Left
		eqPresetsLbl.ZIndex = 31

		local eqPresetGrid = Instance.new("Frame", EqPanel)
		eqPresetGrid.Name = "PresetGrid"
		eqPresetGrid.Size = UDim2.new(1, -24, 0, 48)
		eqPresetGrid.Position = UDim2.new(0, 12, 0, 60)
		eqPresetGrid.BackgroundTransparency = 1
		eqPresetGrid.ZIndex = 31
		local eqGridLayout = Instance.new("UIGridLayout", eqPresetGrid)
		eqGridLayout.CellSize = UDim2.new(0.245, -4, 0, 21)
		eqGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
		eqGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local eqPresetButtons = {}

		local eqSliderRefs = {}

		local function createEqSlider(bandKey, labelText, yPos)
			local row = Instance.new("Frame", EqPanel)
			row.Name = "EqBand_" .. bandKey
			row.Size = UDim2.new(1, -24, 0, 20)
			row.Position = UDim2.new(0, 12, 0, yPos)
			row.BackgroundTransparency = 1
			row.ZIndex = 31

			local nameLbl = Instance.new("TextLabel", row)
			nameLbl.Size = UDim2.new(0, 38, 1, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = labelText
			nameLbl.TextColor3 = Color3.fromRGB(170, 170, 182)
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 10
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.ZIndex = 32

			local track = Instance.new("Frame", row)
			track.Size = UDim2.new(1, -86, 0, 6)
			track.Position = UDim2.new(0, 40, 0.5, -4)
			track.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
			track.BorderSizePixel = 0
			track.ZIndex = 31
			Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

			local centerMark = Instance.new("Frame", track)
			centerMark.Size = UDim2.new(0, 1, 1, 4)
			centerMark.Position = UDim2.new(0.5, 0, 0, -2)
			centerMark.BackgroundColor3 = Color3.fromRGB(70, 70, 82)
			centerMark.BorderSizePixel = 0
			centerMark.ZIndex = 32

			local fill = Instance.new("Frame", track)
			fill.Size = UDim2.new(0.5, 0, 1, 0)
			fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			fill.BorderSizePixel = 0
			fill.ZIndex = 32
			Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

			local fillGrad = Instance.new("UIGradient", fill)
			fillGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 34)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 48, 50)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 160, 165))
			})

			local knob = Instance.new("Frame", fill)
			knob.Size = UDim2.new(0, 13, 0, 13)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.new(1, 0, 0.5, 0)
			knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knob.BorderSizePixel = 0
			knob.ZIndex = 33
			Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

			local valLbl = Instance.new("TextLabel", row)
			valLbl.Size = UDim2.new(0, 42, 1, 0)
			valLbl.Position = UDim2.new(1, -42, 0, 0)
			valLbl.BackgroundTransparency = 1
			valLbl.Text = "0.0 dB"
			valLbl.TextColor3 = Color3.fromRGB(140, 140, 152)
			valLbl.Font = Enum.Font.Gotham
			valLbl.TextSize = 9.5
			valLbl.TextXAlignment = Enum.TextXAlignment.Right
			valLbl.ZIndex = 32

			local clickBtn = Instance.new("TextButton", track)
			clickBtn.Size = UDim2.new(1, 0, 4, 0)
			clickBtn.Position = UDim2.new(0, 0, -1.5, 0)
			clickBtn.BackgroundTransparency = 1
			clickBtn.Text = ""
			clickBtn.ZIndex = 34

			local MIN_DB, MAX_DB = -20, 10
			local dragging = false

			local function fracToDb(frac)
				return MIN_DB + (frac * (MAX_DB - MIN_DB))
			end

			local function applyFromInput(input)
				local frac = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
				local db = fracToDb(frac)
				fill.Size = UDim2.new(frac, 0, 1, 0)
				valLbl.Text = string.format("%+.1f dB", db)
				if _G.SlateMusicSetEqBand then _G.SlateMusicSetEqBand(bandKey, db) end
			end

			clickBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					tweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 16, 0, 16)}):Play()
					applyFromInput(input)
				end
			end)
			userInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					applyFromInput(input)
				end
			end)
			userInputService.InputEnded:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					dragging = false
					tweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 13, 0, 13)}):Play()
				end
			end)

			eqSliderRefs[bandKey] = {
				fill = fill,
				label = valLbl,
				isDragging = function() return dragging end,
				setDb = function(db)
					db = math.clamp(tonumber(db) or 0, MIN_DB, MAX_DB)
					local frac = (db - MIN_DB) / (MAX_DB - MIN_DB)
					fill.Size = UDim2.new(frac, 0, 1, 0)
					valLbl.Text = string.format("%+.1f dB", db)
				end
			}
			return row
		end

		createEqSlider("low", "Bass", 118)
		createEqSlider("mid", "Mids", 142)
		createEqSlider("high", "Treble", 166)

		local eqResetBtn = Instance.new("TextButton", EqPanel)
		eqResetBtn.Size = UDim2.new(0, 72, 0, 22)
		eqResetBtn.Position = UDim2.new(1, -84, 1, -30)
		eqResetBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
		eqResetBtn.BorderSizePixel = 0
		eqResetBtn.Text = "Reset"
		eqResetBtn.TextColor3 = Color3.fromRGB(190, 190, 200)
		eqResetBtn.Font = Enum.Font.GothamBold
		eqResetBtn.TextSize = 10.5
		eqResetBtn.AutoButtonColor = false
		eqResetBtn.ZIndex = 31
		Instance.new("UICorner", eqResetBtn).CornerRadius = UDim.new(0, 6)
		local eqResetStroke = Instance.new("UIStroke", eqResetBtn)
		eqResetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		eqResetStroke.Color = Color3.fromRGB(44, 44, 54)
		eqResetStroke.Thickness = 0.8

		local eqHint = Instance.new("TextLabel", EqPanel)
		eqHint.Size = UDim2.new(1, -108, 0, 22)
		eqHint.Position = UDim2.new(0, 12, 1, -30)
		eqHint.BackgroundTransparency = 1
		eqHint.Text = "Applies live to the current track and is saved between sessions."
		eqHint.TextColor3 = Color3.fromRGB(95, 95, 108)
		eqHint.Font = Enum.Font.Gotham
		eqHint.TextSize = 9.5
		eqHint.TextXAlignment = Enum.TextXAlignment.Left
		eqHint.TextTruncate = Enum.TextTruncate.AtEnd
		eqHint.ZIndex = 31

		local lastEqEnabled, lastEqPreset = nil, nil
		_G.SlateSyncEqUI = function()
			local st = _G.SlateMusicGetEq and _G.SlateMusicGetEq() or nil
			if not st then return end
			if _G.SlateBuildEqPresetChips then _G.SlateBuildEqPresetChips() end

			if st.enabled ~= lastEqEnabled or st.preset ~= lastEqPreset then
				eqSub.Text = st.enabled and ("On  ·  " .. tostring(st.preset)) or "Off"
				eqSub.TextColor3 = st.enabled and Color3.fromRGB(180, 180, 195) or Color3.fromRGB(130, 130, 140)

				if st.enabled ~= lastEqEnabled then
					tweenService:Create(eqSwitch, TweenInfo.new(0.15), {
						BackgroundColor3 = st.enabled and Color3.fromRGB(70, 70, 86) or Color3.fromRGB(34, 34, 42)
					}):Play()
					tweenService:Create(eqSwitchKnob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = st.enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
						BackgroundColor3 = st.enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 132)
					}):Play()
				end

				for name, btn in pairs(eqPresetButtons) do
					local active = st.enabled and (name == st.preset)
					btn.BackgroundColor3 = active and Color3.fromRGB(42, 42, 52) or Color3.fromRGB(20, 20, 25)
					btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 162)
				end

				lastEqEnabled, lastEqPreset = st.enabled, st.preset
			end

			for bandKey, ref in pairs(eqSliderRefs) do
				if not ref.isDragging() then
					ref.setDb(st[bandKey] or 0)
				end
			end
		end

		eqSwitch.MouseButton1Click:Connect(function()
			if _G.SlateMusicToggleEq then _G.SlateMusicToggleEq() end
			if _G.SlateSyncEqUI then _G.SlateSyncEqUI() end
		end)

		eqResetBtn.MouseEnter:Connect(function()
			tweenService:Create(eqResetBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(34, 34, 42)}):Play()
		end)
		eqResetBtn.MouseLeave:Connect(function()
			tweenService:Create(eqResetBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
		end)
		eqResetBtn.MouseButton1Click:Connect(function()
			if _G.SlateMusicResetEq then _G.SlateMusicResetEq() end
			if _G.SlateSyncEqUI then _G.SlateSyncEqUI() end
			queueNotification("Equalizer", "Reset to Flat", 2)
		end)

		local eqPresetsBuilt = false
		local function buildEqPresetChips()
			if eqPresetsBuilt then return end
			local presets = (_G.SlateMusicGetEqPresets and _G.SlateMusicGetEqPresets()) or nil
			if not presets or #presets == 0 then return end
			eqPresetsBuilt = true

			for i, preset in ipairs(presets) do
				local chip = Instance.new("TextButton", eqPresetGrid)
				chip.Name = "EqPreset_" .. tostring(preset.name):gsub("%s", "")
				chip.LayoutOrder = i
				chip.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
				chip.BorderSizePixel = 0
				chip.Text = preset.name
				chip.TextColor3 = Color3.fromRGB(150, 150, 162)
				chip.Font = Enum.Font.GothamBold
				chip.TextSize = 9.5
				chip.TextTruncate = Enum.TextTruncate.AtEnd
				chip.AutoButtonColor = false
				chip.ZIndex = 32
				Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 5)
				local chipStroke = Instance.new("UIStroke", chip)
				chipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				chipStroke.Color = Color3.fromRGB(38, 38, 48)
				chipStroke.Thickness = 0.8

				chip.MouseButton1Click:Connect(function()
					if _G.SlateMusicSetEqPreset then _G.SlateMusicSetEqPreset(preset.name) end
					if _G.SlateSyncEqUI then _G.SlateSyncEqUI() end
					queueNotification("Equalizer", "Preset: " .. preset.name, 2)
				end)

				eqPresetButtons[preset.name] = chip
			end
		end

		local eqOpenBtn = Instance.new("TextButton", MusicTab)
		eqOpenBtn.Name = "EqualizerBtn"
		eqOpenBtn.Size = UDim2.new(0, 52, 0, 22)
		eqOpenBtn.Position = UDim2.new(0.96, -52, 0, 50)
		eqOpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		eqOpenBtn.BorderSizePixel = 0
		eqOpenBtn.Text = "EQ"
		eqOpenBtn.TextColor3 = Color3.fromRGB(170, 170, 182)
		eqOpenBtn.Font = Enum.Font.GothamBold
		eqOpenBtn.TextSize = 10.5
		eqOpenBtn.AutoButtonColor = false
		eqOpenBtn.ZIndex = 5
		Instance.new("UICorner", eqOpenBtn).CornerRadius = UDim.new(0, 6)
		local eqOpenStroke = Instance.new("UIStroke", eqOpenBtn)
		eqOpenStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		eqOpenStroke.Color = Color3.fromRGB(40, 40, 50)
		eqOpenStroke.Thickness = 0.8

		local eqActiveDot = Instance.new("Frame", eqOpenBtn)
		eqActiveDot.Size = UDim2.new(0, 4, 0, 4)
		eqActiveDot.Position = UDim2.new(1, -8, 0, 4)
		eqActiveDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		eqActiveDot.BorderSizePixel = 0
		eqActiveDot.ZIndex = 6
		eqActiveDot.Visible = false
		Instance.new("UICorner", eqActiveDot).CornerRadius = UDim.new(1, 0)

		eqOpenBtn.MouseEnter:Connect(function()
			tweenService:Create(eqOpenBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 40)}):Play()
		end)
		eqOpenBtn.MouseLeave:Connect(function()
			tweenService:Create(eqOpenBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play()
		end)
		_G.SlateBuildEqPresetChips = buildEqPresetChips

		eqOpenBtn.MouseButton1Click:Connect(function()
			EqPanel.Visible = not EqPanel.Visible
			if EqPanel.Visible then
				PlaylistDrawer.Visible = false
				buildEqPresetChips()
				if _G.SlateSyncEqUI then _G.SlateSyncEqUI() end
			end
		end)

		do
			local baseSyncEq = _G.SlateSyncEqUI
			_G.SlateSyncEqUI = function()
				baseSyncEq()
				local st = _G.SlateMusicGetEq and _G.SlateMusicGetEq() or nil
				eqActiveDot.Visible = (st ~= nil and st.enabled == true)
				eqOpenBtn.TextColor3 = (st and st.enabled) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 182)
			end
		end

		task.defer(function()
			if _G.SlateSyncEqUI then pcall(_G.SlateSyncEqUI) end
		end)

		local HomeView = Instance.new("ScrollingFrame", ContentContainer)
		HomeView.Name = "HomeView"
		HomeView.Size = UDim2.new(1, 0, 1, 0)
		HomeView.BackgroundTransparency = 1
		HomeView.BorderSizePixel = 0
		HomeView.ScrollBarThickness = 0
		HomeView.ScrollBarImageTransparency = 1
		HomeView.AutomaticCanvasSize = Enum.AutomaticSize.Y
		HomeView.Visible = true

		local homeLayout = Instance.new("UIListLayout", HomeView)
		homeLayout.Padding = UDim.new(0, 12)
		homeLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local homePad = Instance.new("UIPadding", HomeView)
		homePad.PaddingTop = UDim.new(0, 2)
		homePad.PaddingBottom = UDim.new(0, 14)

		local function createSectionHeader(titleText, order)
			local lbl = Instance.new("TextLabel", HomeView)
			lbl.Size = UDim2.new(1, 0, 0, 20)
			lbl.BackgroundTransparency = 1
			lbl.Text = titleText
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 12.5
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.LayoutOrder = order
			return lbl
		end

		local function renderGridSection(itemsList, parentFrame)
			for _, pl in ipairs(itemsList) do
				local card = Instance.new("Frame", parentFrame)
				card.Name = "PlCard_" .. pl.name
				card.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
				card.BorderSizePixel = 0
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
				local cStrk = Instance.new("UIStroke", card)
				cStrk.Color = Color3.fromRGB(30, 30, 38)
				cStrk.Thickness = 0.8

				local thumb = Instance.new("ImageLabel", card)
				thumb.Size = UDim2.new(0, 44, 1, 0)
				thumb.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
				thumb.BorderSizePixel = 0
				thumb.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
				thumb.ScaleType = Enum.ScaleType.Crop
				Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 6)

				if pl.cover and pl.cover ~= "" then
					task.spawn(function()
						local thumbFile = "slate/music/thumbs/" .. pl.id .. ".png"
						if not (isfile and isfile(thumbFile)) then
							local imgData = fetchMediaUrl(pl.cover)
							if imgData and writefile then pcall(writefile, thumbFile, imgData) end
						end
						if isfile and isfile(thumbFile) then
							local assetUri = nil
							if getcustomasset then pcall(function() assetUri = getcustomasset(thumbFile) end)
							elseif getsynasset then pcall(function() assetUri = getsynasset(thumbFile) end) end
							if assetUri then
								thumb.ImageTransparency = 1
								thumb.Image = assetUri
								tweenService:Create(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
							end
						end
					end)
				end

				local title = Instance.new("TextLabel", card)
				title.Size = UDim2.new(1, -50, 1, 0)
				title.Position = UDim2.new(0, 48, 0, 0)
				title.BackgroundTransparency = 1
				title.Text = pl.name
				title.TextColor3 = Color3.fromRGB(255, 255, 255)
				title.Font = Enum.Font.GothamBold
				title.TextSize = 10.5
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.TextTruncate = Enum.TextTruncate.AtEnd

				local clickBtn = Instance.new("TextButton", card)
				clickBtn.Size = UDim2.new(1, 0, 1, 0)
				clickBtn.BackgroundTransparency = 1
				clickBtn.Text = ""

				clickBtn.MouseEnter:Connect(function()
					tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
				end)
				clickBtn.MouseLeave:Connect(function()
					tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
				end)

				clickBtn.MouseButton1Click:Connect(function()
					if _G.SlateSwitchSpotifyTab then _G.SlateSwitchSpotifyTab("Search") end
					if MusicSearchBar then
						MusicSearchBar.Text = pl.query or pl.name
						if _G.SlateMusicSearch then _G.SlateMusicSearch(pl.query or pl.name) end
					end
				end)
			end
		end

		createSectionHeader("Featured Playlists & Mixes", 1)

		local GridFrame = Instance.new("Frame", HomeView)
		GridFrame.Name = "GridFrame"
		GridFrame.Size = UDim2.new(1, 0, 0, 0)
		GridFrame.AutomaticSize = Enum.AutomaticSize.Y
		GridFrame.BackgroundTransparency = 1
		GridFrame.LayoutOrder = 2
		local gridLayout = Instance.new("UIGridLayout", GridFrame)
		gridLayout.CellSize = UDim2.new(0.316, 0, 0, 42)
		gridLayout.CellPadding = UDim2.new(0.024, 0, 0, 7)

		local featuredPlaylists = {
			{ id = "pl_tophits", name = "Today's Top Hits", query = "Today's Top Hits Pop", cover = "https://i1.sndcdn.com/artworks-cxpyPVAtzudIxBap-LPzVCw-t500x500.jpg" },
			{ id = "pl_rap", name = "RapCaviar", query = "RapCaviar Hip Hop", cover = "https://i1.sndcdn.com/artworks-RgU6PINju75rJGNL-eaywPg-t500x500.jpg" },
			{ id = "pl_lofi", name = "Lo-Fi Chill Beats", query = "Lofi Hip Hop Chill", cover = "https://i1.sndcdn.com/artworks-000321524016-jw118f-t500x500.jpg" },
			{ id = "pl_global", name = "Global Top 50", query = "Global Top 50 Songs", cover = "https://i1.sndcdn.com/artworks-7XqODHPzgTJiyNSs-ejdq6g-t500x500.jpg" },
			{ id = "pl_phonk", name = "Phonk Drift", query = "Phonk Drift Music", cover = "https://i1.sndcdn.com/avatars-r1MyjV8jiDJu87pQ-zmlnSw-t500x500.jpg" },
			{ id = "pl_gaming", name = "Gaming Energy", query = "Gaming EDM Bass", cover = "https://i1.sndcdn.com/artworks-mJqxe0wUE1sA8XuE-AiPCTQ-t500x500.jpg" }
		}
		renderGridSection(featuredPlaylists, GridFrame)

		createSectionHeader("Popular Podcasts & Shows", 3)

		local PodGrid = Instance.new("Frame", HomeView)
		PodGrid.Name = "PodGrid"
		PodGrid.Size = UDim2.new(1, 0, 0, 0)
		PodGrid.AutomaticSize = Enum.AutomaticSize.Y
		PodGrid.BackgroundTransparency = 1
		PodGrid.LayoutOrder = 4
		local podLayout = Instance.new("UIGridLayout", PodGrid)
		podLayout.CellSize = UDim2.new(0.316, 0, 0, 42)
		podLayout.CellPadding = UDim2.new(0.024, 0, 0, 7)

		local popularPodcasts = {
			{ id = "pod_rogan", name = "The Joe Rogan Experience", query = "Joe Rogan podcast", cover = "https://i1.sndcdn.com/artworks-000492193527-i2g7o9-t500x500.jpg" },
			{ id = "pod_huberman", name = "Huberman Lab", query = "Huberman Lab podcast", cover = "https://i1.sndcdn.com/artworks-s38N1yU2eA0H-0-t500x500.jpg" },
			{ id = "pod_lex", name = "Lex Fridman", query = "Lex Fridman podcast", cover = "https://i1.sndcdn.com/artworks-000673909774-v7y23t-t500x500.jpg" },
			{ id = "pod_mkbhd", name = "Waveform (MKBHD)", query = "Waveform MKBHD", cover = "https://i1.sndcdn.com/artworks-v6QvV0nK9V0A-0-t500x500.jpg" },
			{ id = "pod_chd", name = "Call Her Daddy", query = "Call Her Daddy", cover = "https://i1.sndcdn.com/artworks-000574892301-j7e2la-t500x500.jpg" },
			{ id = "pod_crime", name = "True Crime Garage", query = "True Crime Garage", cover = "https://i1.sndcdn.com/artworks-000185938492-7i4g0s-t500x500.jpg" }
		}
		renderGridSection(popularPodcasts, PodGrid)

		createSectionHeader("Trending Tracks (1-Click Play)", 5)

		local TrendingFrame = Instance.new("Frame", HomeView)
		TrendingFrame.Name = "TrendingFrame"
		TrendingFrame.Size = UDim2.new(1, 0, 0, 0)
		TrendingFrame.AutomaticSize = Enum.AutomaticSize.Y
		TrendingFrame.BackgroundTransparency = 1
		TrendingFrame.LayoutOrder = 6
		local trendLayout = Instance.new("UIListLayout", TrendingFrame)
		trendLayout.Padding = UDim.new(0, 4)

		local trendingSongs = {
			{ id = "tr_kendrick", title = "Not Like Us", artist = "Kendrick Lamar", duration = 274, query = "Kendrick Lamar Not Like Us", cover = "https://i1.sndcdn.com/artworks-r1MyjV8jiDJu87pQ-zmlnSw-t500x500.jpg" },
			{ id = "tr_dontoliver", title = "Bandit", artist = "Don Toliver", duration = 158, query = "Don Toliver Bandit", cover = "https://i1.sndcdn.com/artworks-7XqODHPzgTJiyNSs-ejdq6g-t500x500.jpg" },
			{ id = "tr_fein", title = "FE!N", artist = "Travis Scott ft. Playboi Carti", duration = 191, query = "Travis Scott FEIN", cover = "https://i1.sndcdn.com/artworks-mJqxe0wUE1sA8XuE-AiPCTQ-t500x500.jpg" },
			{ id = "tr_gunna", title = "fukumean", artist = "Gunna", duration = 125, query = "Gunna fukumean", cover = "https://i1.sndcdn.com/artworks-RgU6PINju75rJGNL-eaywPg-t500x500.jpg" }
		}

		for idx, trk in ipairs(trendingSongs) do
			local card = Instance.new("Frame", TrendingFrame)
			card.Size = UDim2.new(1, -4, 0, 40)
			card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
			card.BorderSizePixel = 0
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

			local thumb = Instance.new("ImageLabel", card)
			thumb.Size = UDim2.new(0, 30, 0, 30)
			thumb.Position = UDim2.new(0, 5, 0.5, -15)
			thumb.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
			thumb.BorderSizePixel = 0
			thumb.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
			thumb.ScaleType = Enum.ScaleType.Crop
			Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 5)

			local sTitle = Instance.new("TextLabel", card)
			sTitle.Size = UDim2.new(0.6, 0, 0, 15)
			sTitle.Position = UDim2.new(0, 42, 0, 4)
			sTitle.BackgroundTransparency = 1
			sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			sTitle.Font = Enum.Font.GothamBold
			sTitle.TextSize = 11
			sTitle.TextXAlignment = Enum.TextXAlignment.Left
			sTitle.TextTruncate = Enum.TextTruncate.AtEnd
			sTitle.Text = trk.title

			local sArtist = Instance.new("TextLabel", card)
			sArtist.Size = UDim2.new(0.6, 0, 0, 13)
			sArtist.Position = UDim2.new(0, 42, 0, 19)
			sArtist.BackgroundTransparency = 1
			sArtist.TextColor3 = Color3.fromRGB(130, 130, 140)
			sArtist.Font = Enum.Font.Gotham
			sArtist.TextSize = 10
			sArtist.TextXAlignment = Enum.TextXAlignment.Left
			sArtist.TextTruncate = Enum.TextTruncate.AtEnd
			sArtist.Text = trk.artist

			local durLbl = Instance.new("TextLabel", card)
			durLbl.Size = UDim2.new(0, 36, 1, 0)
			durLbl.Position = UDim2.new(1, -78, 0, 0)
			durLbl.BackgroundTransparency = 1
			durLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
			durLbl.Font = Enum.Font.Gotham
			durLbl.TextSize = 10
			durLbl.TextXAlignment = Enum.TextXAlignment.Right
			local m = math.floor(trk.duration / 60)
			local s = trk.duration % 60
			durLbl.Text = string.format("%d:%02d", m, s)

			local cardBtn = Instance.new("TextButton", card)
			cardBtn.Size = UDim2.new(1, 0, 1, 0)
			cardBtn.BackgroundTransparency = 1
			cardBtn.Text = ""

			cardBtn.MouseEnter:Connect(function()
				tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
			end)
			cardBtn.MouseLeave:Connect(function()
				tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(16, 16, 20)}):Play()
			end)
			cardBtn.MouseButton1Click:Connect(function()
				if _G.SlateMusicPlayTrack then
					_G.SlateMusicPlayTrack(trk, trendingSongs, idx)
				end
			end)
		end

		local SearchView = Instance.new("Frame", ContentContainer)
		SearchView.Name = "SearchView"
		SearchView.Size = UDim2.new(1, 0, 1, 0)
		SearchView.BackgroundTransparency = 1
		SearchView.BorderSizePixel = 0
		SearchView.Visible = false

		local SearchContainer = Instance.new("Frame", SearchView)
		SearchContainer.Name = "SearchContainer"
		SearchContainer.Size = UDim2.new(1, 0, 0, 32)
		SearchContainer.Position = UDim2.new(0, 0, 0, 0)
		SearchContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		SearchContainer.BorderSizePixel = 0
		Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 8)
		local scStroke = Instance.new("UIStroke", SearchContainer)
		scStroke.Color = Color3.fromRGB(36, 36, 46)
		scStroke.Thickness = 0.9

		local sIcon = Instance.new("ImageLabel", SearchContainer)
		sIcon.Size = UDim2.new(0, 14, 0, 14)
		sIcon.Position = UDim2.new(0, 10, 0.5, -7)
		sIcon.BackgroundTransparency = 1
		sIcon.Image = SpIcons.Search
		sIcon.ImageColor3 = Color3.fromRGB(130, 130, 145)

		local MusicSearchBar = Instance.new("TextBox", SearchContainer)
		MusicSearchBar.Name = "MusicSearchBar"
		MusicSearchBar.PlaceholderText = "What do you want to play?"
		MusicSearchBar.PlaceholderColor3 = Color3.fromRGB(110, 110, 125)
		MusicSearchBar.BorderSizePixel = 0
		MusicSearchBar.TextSize = 12
		MusicSearchBar.ClearTextOnFocus = false
		MusicSearchBar.Text = ""
		MusicSearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
		MusicSearchBar.BackgroundTransparency = 1
		MusicSearchBar.Size = UDim2.new(1, -132, 1, 0)
		MusicSearchBar.Position = UDim2.new(0, 32, 0, 0)
		MusicSearchBar.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		MusicSearchBar.TextXAlignment = Enum.TextXAlignment.Left

		local SortModes = {
			{ key = "best",  label = "Best Match" },
			{ key = "likes", label = "Most Liked" },
			{ key = "plays", label = "Most Played" }
		}
		local sortModeIndex = 1

		local MusicSortBtn = Instance.new("TextButton", SearchContainer)
		MusicSortBtn.Name = "MusicSortBtn"
		MusicSortBtn.Size = UDim2.new(0, 88, 0, 22)
		MusicSortBtn.Position = UDim2.new(1, -96, 0.5, -11)
		MusicSortBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
		MusicSortBtn.BorderSizePixel = 0
		MusicSortBtn.Text = "Best Match"
		MusicSortBtn.TextColor3 = Color3.fromRGB(175, 175, 188)
		MusicSortBtn.Font = Enum.Font.GothamBold
		MusicSortBtn.TextSize = 10
		MusicSortBtn.AutoButtonColor = false
		Instance.new("UICorner", MusicSortBtn).CornerRadius = UDim.new(0, 6)
		local sortBtnStroke = Instance.new("UIStroke", MusicSortBtn)
		sortBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		sortBtnStroke.Color = Color3.fromRGB(44, 44, 54)
		sortBtnStroke.Thickness = 0.8

		MusicSortBtn.MouseEnter:Connect(function()
			tweenService:Create(MusicSortBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
		end)
		MusicSortBtn.MouseLeave:Connect(function()
			tweenService:Create(MusicSortBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 32)}):Play()
		end)

		local ResultsScroll = Instance.new("ScrollingFrame", SearchView)
		ResultsScroll.Name = "ResultsScroll"
		ResultsScroll.Size = UDim2.new(1, 0, 1, -38)
		ResultsScroll.Position = UDim2.new(0, 0, 0, 38)
		ResultsScroll.BackgroundTransparency = 1
		ResultsScroll.BorderSizePixel = 0
		ResultsScroll.ScrollBarThickness = 0
		ResultsScroll.ScrollBarImageTransparency = 1
		ResultsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		local resLayout = Instance.new("UIListLayout", ResultsScroll)
		resLayout.Padding = UDim.new(0, 4)
		resLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local ArtistSection = Instance.new("Frame", ResultsScroll)
		ArtistSection.Name = "ArtistSection"
		ArtistSection.Size = UDim2.new(1, 0, 0, 0)
		ArtistSection.AutomaticSize = Enum.AutomaticSize.Y
		ArtistSection.BackgroundTransparency = 1
		ArtistSection.BorderSizePixel = 0
		ArtistSection.LayoutOrder = 1
		local artistSecLayout = Instance.new("UIListLayout", ArtistSection)
		artistSecLayout.Padding = UDim.new(0, 4)
		artistSecLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local SongSection = Instance.new("Frame", ResultsScroll)
		SongSection.Name = "SongSection"
		SongSection.Size = UDim2.new(1, 0, 0, 0)
		SongSection.AutomaticSize = Enum.AutomaticSize.Y
		SongSection.BackgroundTransparency = 1
		SongSection.BorderSizePixel = 0
		SongSection.LayoutOrder = 2
		local songSecLayout = Instance.new("UIListLayout", SongSection)
		songSecLayout.Padding = UDim.new(0, 4)
		songSecLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local ArtistView = Instance.new("Frame", ContentContainer)
		ArtistView.Name = "ArtistView"
		ArtistView.Size = UDim2.new(1, 0, 1, 0)
		ArtistView.BackgroundTransparency = 1
		ArtistView.BorderSizePixel = 0
		ArtistView.Visible = false

		local avHeader = Instance.new("Frame", ArtistView)
		avHeader.Name = "ArtistHeader"
		avHeader.Size = UDim2.new(1, 0, 0, 58)
		avHeader.BackgroundTransparency = 1

		local avBackBtn = Instance.new("TextButton", avHeader)
		avBackBtn.Size = UDim2.new(0, 22, 0, 22)
		avBackBtn.Position = UDim2.new(0, 0, 0, 2)
		avBackBtn.BackgroundTransparency = 1
		avBackBtn.Text = "‹"
		avBackBtn.TextColor3 = Color3.fromRGB(190, 190, 200)
		avBackBtn.Font = Enum.Font.GothamBold
		avBackBtn.TextSize = 20

		local avAvatar = Instance.new("ImageLabel", avHeader)
		avAvatar.Name = "ArtistAvatar"
		avAvatar.Size = UDim2.new(0, 46, 0, 46)
		avAvatar.Position = UDim2.new(0, 26, 0, 4)
		avAvatar.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
		avAvatar.BorderSizePixel = 0
		avAvatar.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
		avAvatar.ScaleType = Enum.ScaleType.Crop
		Instance.new("UICorner", avAvatar).CornerRadius = UDim.new(1, 0)

		local avName = Instance.new("TextLabel", avHeader)
		avName.Size = UDim2.new(1, -220, 0, 18)
		avName.Position = UDim2.new(0, 80, 0, 10)
		avName.BackgroundTransparency = 1
		avName.Text = "Artist"
		avName.TextColor3 = Color3.fromRGB(255, 255, 255)
		avName.Font = Enum.Font.GothamBold
		avName.TextSize = 14
		avName.TextXAlignment = Enum.TextXAlignment.Left
		avName.TextTruncate = Enum.TextTruncate.AtEnd

		local avVerified = Instance.new("ImageLabel", avHeader)
		avVerified.Name = "VerifiedTick"
		avVerified.Size = UDim2.new(0, 12, 0, 12)
		avVerified.Position = UDim2.new(0, 80, 0, 13)
		avVerified.BackgroundTransparency = 1
		avVerified.Image = SpIcons.StarFilled
		avVerified.ImageColor3 = Color3.fromRGB(90, 170, 255)
		avVerified.Visible = false

		local avMeta = Instance.new("TextLabel", avHeader)
		avMeta.Size = UDim2.new(1, -220, 0, 14)
		avMeta.Position = UDim2.new(0, 80, 0, 30)
		avMeta.BackgroundTransparency = 1
		avMeta.Text = ""
		avMeta.TextColor3 = Color3.fromRGB(135, 135, 148)
		avMeta.Font = Enum.Font.Gotham
		avMeta.TextSize = 10.5
		avMeta.TextXAlignment = Enum.TextXAlignment.Left
		avMeta.TextTruncate = Enum.TextTruncate.AtEnd

		local avPlayAllBtn = Instance.new("TextButton", avHeader)
		avPlayAllBtn.Size = UDim2.new(0, 74, 0, 24)
		avPlayAllBtn.Position = UDim2.new(1, -82, 0, 16)
		avPlayAllBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
		avPlayAllBtn.BorderSizePixel = 0
		avPlayAllBtn.Text = "Play All"
		avPlayAllBtn.TextColor3 = Color3.fromRGB(15, 15, 18)
		avPlayAllBtn.Font = Enum.Font.GothamBold
		avPlayAllBtn.TextSize = 11
		avPlayAllBtn.AutoButtonColor = false
		Instance.new("UICorner", avPlayAllBtn).CornerRadius = UDim.new(1, 0)

		local avShuffleBtn = Instance.new("ImageButton", avHeader)
		avShuffleBtn.Size = UDim2.new(0, 18, 0, 18)
		avShuffleBtn.Position = UDim2.new(1, -108, 0, 19)
		avShuffleBtn.BackgroundTransparency = 1
		avShuffleBtn.Image = SpIcons.Shuffle
		avShuffleBtn.ImageColor3 = Color3.fromRGB(140, 140, 152)

		local avTracksScroll = Instance.new("ScrollingFrame", ArtistView)
		avTracksScroll.Name = "ArtistTracks"
		avTracksScroll.Size = UDim2.new(1, 0, 1, -62)
		avTracksScroll.Position = UDim2.new(0, 0, 0, 62)
		avTracksScroll.BackgroundTransparency = 1
		avTracksScroll.BorderSizePixel = 0
		avTracksScroll.ScrollBarThickness = 0
		avTracksScroll.ScrollBarImageTransparency = 1
		avTracksScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		local avTracksLayout = Instance.new("UIListLayout", avTracksScroll)
		avTracksLayout.Padding = UDim.new(0, 4)
		avTracksLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local currentArtistTracks = {}
		local artistLoadGen = 0

		closeArtistView = function()
			ArtistView.Visible = false
			SearchView.Visible = true
		end

		avBackBtn.MouseButton1Click:Connect(function()
			closeArtistView()
		end)

		avPlayAllBtn.MouseEnter:Connect(function()
			tweenService:Create(avPlayAllBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end)
		avPlayAllBtn.MouseLeave:Connect(function()
			tweenService:Create(avPlayAllBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(240, 240, 245)}):Play()
		end)
		avPlayAllBtn.MouseButton1Click:Connect(function()
			if #currentArtistTracks > 0 and _G.SlateMusicPlayTrack then
				_G.SlateMusicPlayTrack(currentArtistTracks[1], currentArtistTracks, 1)
			end
		end)

		avShuffleBtn.MouseEnter:Connect(function()
			tweenService:Create(avShuffleBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end)
		avShuffleBtn.MouseLeave:Connect(function()
			tweenService:Create(avShuffleBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(140, 140, 152)}):Play()
		end)
		avShuffleBtn.MouseButton1Click:Connect(function()
			if #currentArtistTracks > 0 and _G.SlateMusicPlayTrack then
				local pick = math.random(1, #currentArtistTracks)
				if not (_G.SlateMusicIsShuffleOn and _G.SlateMusicIsShuffleOn()) and _G.SlateMusicToggleShuffle then
					_G.SlateMusicToggleShuffle()
				end
				_G.SlateMusicPlayTrack(currentArtistTracks[pick], currentArtistTracks, pick)
			end
		end)

		openArtistView = function(artist)
			if not artist then return end
			currentArtistTracks = {}
			artistLoadGen = artistLoadGen + 1
			local thisLoad = artistLoadGen

			SearchView.Visible = false
			ArtistView.Visible = true

			avName.Text = tostring(artist.name or "Artist")
			avVerified.Visible = artist.verified == true

			avName.Position = artist.verified and UDim2.new(0, 96, 0, 10) or UDim2.new(0, 80, 0, 10)

			local metaBits = {}
			if (artist.followers or 0) > 0 then
				table.insert(metaBits, formatCompactCount(artist.followers) .. " followers")
			end
			if (artist.trackCount or 0) > 0 then
				table.insert(metaBits, formatCompactCount(artist.trackCount) .. " tracks")
			end
			if artist.city and artist.city ~= "" then table.insert(metaBits, tostring(artist.city)) end
			avMeta.Text = table.concat(metaBits, "  ·  ")

			avAvatar.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
			if artist.avatarUrl and artist.avatarUrl ~= "" then
				task.spawn(function()
					local safeId = "artist_" .. tostring(artist.id):gsub("[^%w%-_]", "_")
					local avatarFile = "slate/music/thumbs/" .. safeId .. ".png"
					if not (isfile and isfile(avatarFile)) then
						local imgData = fetchMediaUrl(artist.avatarUrl)
						if imgData and writefile then pcall(writefile, avatarFile, imgData) end
					end
					if isfile and isfile(avatarFile) and thisLoad == artistLoadGen then
						local assetUri = nil
						if getcustomasset then pcall(function() assetUri = getcustomasset(avatarFile) end)
						elseif getsynasset then pcall(function() assetUri = getsynasset(avatarFile) end) end
						if assetUri then avAvatar.Image = assetUri end
					end
				end)
			end

			for _, child in ipairs(avTracksScroll:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
			end

			local loadingLbl = Instance.new("TextLabel", avTracksScroll)
			loadingLbl.Size = UDim2.new(1, 0, 0, 40)
			loadingLbl.BackgroundTransparency = 1
			loadingLbl.Text = "Loading tracks..."
			loadingLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
			loadingLbl.Font = Enum.Font.GothamMedium
			loadingLbl.TextSize = 11.5

			if not _G.SlateMusicGetArtistTracks then return end
			_G.SlateMusicGetArtistTracks(artist, function(tracks)
				if thisLoad ~= artistLoadGen then return end
				currentArtistTracks = tracks or {}

				for _, child in ipairs(avTracksScroll:GetChildren()) do
					if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
				end

				if #currentArtistTracks == 0 then
					local emptyLbl = Instance.new("TextLabel", avTracksScroll)
					emptyLbl.Size = UDim2.new(1, 0, 0, 40)
					emptyLbl.BackgroundTransparency = 1
					emptyLbl.Text = "This artist has no playable tracks."
					emptyLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
					emptyLbl.Font = Enum.Font.GothamMedium
					emptyLbl.TextSize = 11.5
					return
				end

				for idx, trk in ipairs(currentArtistTracks) do
					createSongCard(avTracksScroll, trk, idx, currentArtistTracks)
				end
			end)
		end

		local LibraryView = Instance.new("Frame", ContentContainer)
		LibraryView.Name = "LibraryView"
		LibraryView.Size = UDim2.new(1, 0, 1, 0)
		LibraryView.BackgroundTransparency = 1
		LibraryView.BorderSizePixel = 0
		LibraryView.Visible = false

		local LibraryOverview = Instance.new("ScrollingFrame", LibraryView)
		LibraryOverview.Name = "LibraryOverview"
		LibraryOverview.Size = UDim2.new(1, 0, 1, 0)
		LibraryOverview.BackgroundTransparency = 1
		LibraryOverview.BorderSizePixel = 0
		LibraryOverview.ScrollBarThickness = 0
		LibraryOverview.ScrollBarImageTransparency = 1
		LibraryOverview.AutomaticCanvasSize = Enum.AutomaticSize.Y
		LibraryOverview.Visible = true

		local libLayout = Instance.new("UIListLayout", LibraryOverview)
		libLayout.Padding = UDim.new(0, 8)
		libLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local libPad = Instance.new("UIPadding", LibraryOverview)
		libPad.PaddingTop = UDim.new(0, 4)
		libPad.PaddingLeft = UDim.new(0, 2)
		libPad.PaddingRight = UDim.new(0, 2)

		local libHeader = Instance.new("Frame", LibraryOverview)
		libHeader.Size = UDim2.new(1, 0, 0, 28)
		libHeader.BackgroundTransparency = 1
		libHeader.LayoutOrder = 1

		local libTitle = Instance.new("TextLabel", libHeader)
		libTitle.Size = UDim2.new(0.32, 0, 1, 0)
		libTitle.Position = UDim2.new(0, 0, 0, 0)
		libTitle.BackgroundTransparency = 1
		libTitle.Text = "Your Playlists"
		libTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		libTitle.Font = Enum.Font.GothamBold
		libTitle.TextSize = 13
		libTitle.TextXAlignment = Enum.TextXAlignment.Left

		local importSpotifyBtn = Instance.new("TextButton", libHeader)
		importSpotifyBtn.Size = UDim2.new(0, 106, 0, 24)
		importSpotifyBtn.Position = UDim2.new(1, -204, 0.5, -12)
		importSpotifyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		importSpotifyBtn.BorderSizePixel = 0
		importSpotifyBtn.Text = "Import Spotify"
		importSpotifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		importSpotifyBtn.Font = Enum.Font.GothamBold
		importSpotifyBtn.TextSize = 10.5
		Instance.new("UICorner", importSpotifyBtn).CornerRadius = UDim.new(0, 6)

		local newPlBtn = Instance.new("TextButton", libHeader)
		newPlBtn.Size = UDim2.new(0, 92, 0, 24)
		newPlBtn.Position = UDim2.new(1, -92, 0.5, -12)
		newPlBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		newPlBtn.BorderSizePixel = 0
		newPlBtn.Text = "+ New Playlist"
		newPlBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		newPlBtn.Font = Enum.Font.GothamBold
		newPlBtn.TextSize = 10.5
		Instance.new("UICorner", newPlBtn).CornerRadius = UDim.new(0, 6)

		local CreatePlBar = Instance.new("Frame", LibraryOverview)
		CreatePlBar.Name = "CreatePlBar"
		CreatePlBar.Size = UDim2.new(1, -4, 0, 34)
		CreatePlBar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
		CreatePlBar.BorderSizePixel = 0
		CreatePlBar.Visible = false
		CreatePlBar.LayoutOrder = 2
		Instance.new("UICorner", CreatePlBar).CornerRadius = UDim.new(0, 6)

		local plNameBox = Instance.new("TextBox", CreatePlBar)
		plNameBox.Size = UDim2.new(1, -130, 1, 0)
		plNameBox.Position = UDim2.new(0, 10, 0, 0)
		plNameBox.BackgroundTransparency = 1
		plNameBox.PlaceholderText = "Enter playlist name..."
		plNameBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
		plNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		plNameBox.TextSize = 11.5
		plNameBox.Font = Enum.Font.Gotham
		plNameBox.TextXAlignment = Enum.TextXAlignment.Left
		plNameBox.Text = ""

		local confirmPlBtn = Instance.new("TextButton", CreatePlBar)
		confirmPlBtn.Size = UDim2.new(0, 56, 0, 24)
		confirmPlBtn.Position = UDim2.new(1, -120, 0.5, -12)
		confirmPlBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		confirmPlBtn.BorderSizePixel = 0
		confirmPlBtn.Text = "Create"
		confirmPlBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		confirmPlBtn.Font = Enum.Font.GothamBold
		confirmPlBtn.TextSize = 10.5
		Instance.new("UICorner", confirmPlBtn).CornerRadius = UDim.new(0, 4)

		local cancelPlBtn = Instance.new("TextButton", CreatePlBar)
		cancelPlBtn.Size = UDim2.new(0, 50, 0, 24)
		cancelPlBtn.Position = UDim2.new(1, -58, 0.5, -12)
		cancelPlBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
		cancelPlBtn.BorderSizePixel = 0
		cancelPlBtn.Text = "Cancel"
		cancelPlBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		cancelPlBtn.Font = Enum.Font.GothamMedium
		cancelPlBtn.TextSize = 10.5
		Instance.new("UICorner", cancelPlBtn).CornerRadius = UDim.new(0, 4)

		local ImportSpotifyBar = Instance.new("Frame", LibraryOverview)
		ImportSpotifyBar.Name = "ImportSpotifyBar"
		ImportSpotifyBar.Size = UDim2.new(1, -4, 0, 34)
		ImportSpotifyBar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
		ImportSpotifyBar.BorderSizePixel = 0
		ImportSpotifyBar.Visible = false
		ImportSpotifyBar.LayoutOrder = 2
		Instance.new("UICorner", ImportSpotifyBar).CornerRadius = UDim.new(0, 6)
		local isbStroke = Instance.new("UIStroke", ImportSpotifyBar)
		isbStroke.Color = Color3.fromRGB(34, 34, 42)
		isbStroke.Thickness = 0.8

		local spotUrlBox = Instance.new("TextBox", ImportSpotifyBar)
		spotUrlBox.Size = UDim2.new(1, -145, 1, 0)
		spotUrlBox.Position = UDim2.new(0, 10, 0, 0)
		spotUrlBox.BackgroundTransparency = 1
		spotUrlBox.PlaceholderText = "Paste Spotify Playlist or Album URL..."
		spotUrlBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
		spotUrlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		spotUrlBox.TextSize = 11
		spotUrlBox.Font = Enum.Font.Gotham
		spotUrlBox.TextXAlignment = Enum.TextXAlignment.Left
		spotUrlBox.Text = ""

		local startImportBtn = Instance.new("TextButton", ImportSpotifyBar)
		startImportBtn.Size = UDim2.new(0, 68, 0, 24)
		startImportBtn.Position = UDim2.new(1, -132, 0.5, -12)
		startImportBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		startImportBtn.BorderSizePixel = 0
		startImportBtn.Text = "Import"
		startImportBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		startImportBtn.Font = Enum.Font.GothamBold
		startImportBtn.TextSize = 10.5
		Instance.new("UICorner", startImportBtn).CornerRadius = UDim.new(0, 4)

		local cancelImportBtn = Instance.new("TextButton", ImportSpotifyBar)
		cancelImportBtn.Size = UDim2.new(0, 52, 0, 24)
		cancelImportBtn.Position = UDim2.new(1, -58, 0.5, -12)
		cancelImportBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
		cancelImportBtn.BorderSizePixel = 0
		cancelImportBtn.Text = "Cancel"
		cancelImportBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		cancelImportBtn.Font = Enum.Font.GothamMedium
		cancelImportBtn.TextSize = 10.5
		Instance.new("UICorner", cancelImportBtn).CornerRadius = UDim.new(0, 4)

		local function handleCreatePlaylist()
			local name = plNameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
			if name ~= "" then
				if _G.SlateMusicCreatePlaylist then
					_G.SlateMusicCreatePlaylist(name)
				else
					SlateMusic.playlists[name] = SlateMusic.playlists[name] or {}
					SlateMusic.savePlaylists()
				end
				CreatePlBar.Visible = false
				plNameBox.Text = ""
				queueNotification("Playlist Created", "Created playlist '" .. name .. "'", 2.5)
				if refreshLibraryView then refreshLibraryView() end
			end
		end

		confirmPlBtn.MouseButton1Click:Connect(handleCreatePlaylist)
		plNameBox.FocusLost:Connect(function(enterPressed)
			if enterPressed then handleCreatePlaylist() end
		end)

		newPlBtn.MouseButton1Click:Connect(function()
			ImportSpotifyBar.Visible = false
			CreatePlBar.Visible = not CreatePlBar.Visible
			if CreatePlBar.Visible then plNameBox:CaptureFocus() end
		end)
		cancelPlBtn.MouseButton1Click:Connect(function()
			CreatePlBar.Visible = false
			plNameBox.Text = ""
		end)

		importSpotifyBtn.MouseButton1Click:Connect(function()
			CreatePlBar.Visible = false
			ImportSpotifyBar.Visible = not ImportSpotifyBar.Visible
			if ImportSpotifyBar.Visible then spotUrlBox:CaptureFocus() end
		end)
		cancelImportBtn.MouseButton1Click:Connect(function()
			ImportSpotifyBar.Visible = false
			spotUrlBox.Text = ""
		end)

		startImportBtn.MouseButton1Click:Connect(function()
			local url = spotUrlBox.Text
			if url and url ~= "" and _G.SlateMusicImportSpotify then
				startImportBtn.Text = "Importing..."
				startImportBtn.Active = false
				queueNotification("Spotify Importer", "Connecting to Spotify & fetching tracks...", 2.5)

				_G.SlateMusicImportSpotify(url, function(status)
					startImportBtn.Text = "Importing..."
					queueNotification("Spotify Import", status, 1.8)
				end, function(success, msg, createdPlName)
					startImportBtn.Text = "Import"
					startImportBtn.Active = true
					if success then
						ImportSpotifyBar.Visible = false
						spotUrlBox.Text = ""
						queueNotification("Spotify Import Complete", msg, 4)
						if refreshLibraryView then refreshLibraryView() end
						if createdPlName and openPlaylistView then openPlaylistView(createdPlName) end
					else
						queueNotification("Import Error", msg, 3)
					end
				end)
			end
		end)

		local LibListFrame = Instance.new("Frame", LibraryOverview)
		LibListFrame.Name = "LibListFrame"
		LibListFrame.Size = UDim2.new(1, 0, 0, 0)
		LibListFrame.AutomaticSize = Enum.AutomaticSize.Y
		LibListFrame.BackgroundTransparency = 1
		LibListFrame.LayoutOrder = 3
		local libListLayout = Instance.new("UIListLayout", LibListFrame)
		libListLayout.Padding = UDim.new(0, 6)

		local PlaylistDetailView = Instance.new("Frame", LibraryView)
		PlaylistDetailView.Name = "PlaylistDetailView"
		PlaylistDetailView.Size = UDim2.new(1, 0, 1, 0)
		PlaylistDetailView.BackgroundTransparency = 1
		PlaylistDetailView.BorderSizePixel = 0
		PlaylistDetailView.Visible = false

		local plDetailHeader = Instance.new("Frame", PlaylistDetailView)
		plDetailHeader.Size = UDim2.new(1, 0, 0, 32)
		plDetailHeader.BackgroundTransparency = 1

		local plBackBtn = Instance.new("TextButton", plDetailHeader)
		plBackBtn.Size = UDim2.new(0, 70, 0, 24)
		plBackBtn.Position = UDim2.new(0, 0, 0.5, -12)
		plBackBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
		plBackBtn.BorderSizePixel = 0
		plBackBtn.Text = "← Back"
		plBackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		plBackBtn.Font = Enum.Font.GothamBold
		plBackBtn.TextSize = 10.5
		Instance.new("UICorner", plBackBtn).CornerRadius = UDim.new(0, 6)

		local plDetailTitle = Instance.new("TextLabel", plDetailHeader)
		plDetailTitle.Size = UDim2.new(0.5, 0, 1, 0)
		plDetailTitle.Position = UDim2.new(0, 80, 0, 0)
		plDetailTitle.BackgroundTransparency = 1
		plDetailTitle.Text = "Playlist Name"
		plDetailTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		plDetailTitle.Font = Enum.Font.GothamBold
		plDetailTitle.TextSize = 13
		plDetailTitle.TextXAlignment = Enum.TextXAlignment.Left

		local plPlayAllBtn = Instance.new("TextButton", plDetailHeader)
		plPlayAllBtn.Size = UDim2.new(0, 74, 0, 24)
		plPlayAllBtn.Position = UDim2.new(1, -74, 0.5, -12)
		plPlayAllBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		plPlayAllBtn.BorderSizePixel = 0
		plPlayAllBtn.Text = "Play All"
		plPlayAllBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		plPlayAllBtn.Font = Enum.Font.GothamBold
		plPlayAllBtn.TextSize = 10.5
		Instance.new("UICorner", plPlayAllBtn).CornerRadius = UDim.new(0, 6)

		local PlSongsScroll = Instance.new("ScrollingFrame", PlaylistDetailView)
		PlSongsScroll.Name = "PlSongsScroll"
		PlSongsScroll.Size = UDim2.new(1, 0, 1, -38)
		PlSongsScroll.Position = UDim2.new(0, 0, 0, 38)
		PlSongsScroll.BackgroundTransparency = 1
		PlSongsScroll.BorderSizePixel = 0
		PlSongsScroll.ScrollBarThickness = 0
		PlSongsScroll.ScrollBarImageTransparency = 1
		PlSongsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		local plSongsLayout = Instance.new("UIListLayout", PlSongsScroll)
		plSongsLayout.Padding = UDim.new(0, 4)

		local currentOpenPlaylist = nil

		local function openPlaylistView(plName)
			currentOpenPlaylist = plName
			LibraryOverview.Visible = false
			PlaylistDetailView.Visible = true
			plDetailTitle.Text = plName

			for _, child in ipairs(PlSongsScroll:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
			end

			local playlists = _G.SlateMusicGetPlaylists and _G.SlateMusicGetPlaylists() or {}
			local trackList = playlists[plName] or {}

			plPlayAllBtn.MouseButton1Click:Connect(function()
				if #trackList > 0 and _G.SlateMusicPlayTrack then
					_G.SlateMusicPlayTrack(trackList[1], trackList, 1)
				end
			end)

			if #trackList == 0 then
				local empty = Instance.new("TextLabel", PlSongsScroll)
				empty.Size = UDim2.new(1, 0, 0, 50)
				empty.BackgroundTransparency = 1
				empty.Text = "No songs in this playlist yet. Add songs from Search!"
				empty.TextColor3 = Color3.fromRGB(120, 120, 130)
				empty.Font = Enum.Font.GothamMedium
				empty.TextSize = 11.5
				return
			end

			for idx, trk in ipairs(trackList) do
				local card = Instance.new("Frame", PlSongsScroll)
				card.Size = UDim2.new(1, -4, 0, 42)
				card.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
				card.BorderSizePixel = 0
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

				local sTitle = Instance.new("TextLabel", card)
				sTitle.Size = UDim2.new(0.55, 0, 0, 16)
				sTitle.Position = UDim2.new(0, 12, 0, 6)
				sTitle.BackgroundTransparency = 1
				sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
				sTitle.Font = Enum.Font.GothamBold
				sTitle.TextSize = 12
				sTitle.TextXAlignment = Enum.TextXAlignment.Left
				sTitle.TextTruncate = Enum.TextTruncate.AtEnd
				sTitle.Text = trk.title

				local sArtist = Instance.new("TextLabel", card)
				sArtist.Size = UDim2.new(0.55, 0, 0, 14)
				sArtist.Position = UDim2.new(0, 12, 0, 22)
				sArtist.BackgroundTransparency = 1
				sArtist.TextColor3 = Color3.fromRGB(140, 140, 150)
				sArtist.Font = Enum.Font.Gotham
				sArtist.TextSize = 10.5
				sArtist.TextXAlignment = Enum.TextXAlignment.Left
				sArtist.TextTruncate = Enum.TextTruncate.AtEnd
				sArtist.Text = trk.artist

				local rmBtn = Instance.new("ImageButton", card)
				rmBtn.Name = "DeleteTrackBtn"
				rmBtn.Size = UDim2.new(0, 20, 0, 20)
				rmBtn.Position = UDim2.new(1, -26, 0.5, -10)
				rmBtn.ZIndex = 5

				local cardClickBtn = Instance.new("TextButton", card)
				cardClickBtn.Size = UDim2.new(1, -34, 1, 0)
				cardClickBtn.Position = UDim2.new(0, 0, 0, 0)
				cardClickBtn.BackgroundTransparency = 1
				cardClickBtn.Text = ""
				cardClickBtn.ZIndex = 3

				cardClickBtn.MouseEnter:Connect(function()
					tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
				end)
				cardClickBtn.MouseLeave:Connect(function()
					tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(14, 14, 16)}):Play()
				end)
				cardClickBtn.MouseButton1Click:Connect(function()
					if _G.SlateMusicPlayTrack then _G.SlateMusicPlayTrack(trk, trackList, idx) end
				end)
				rmBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
				rmBtn.BackgroundTransparency = 1
				rmBtn.BorderSizePixel = 0
				rmBtn.Image = SpIcons.DeleteTrack
				rmBtn.ImageColor3 = Color3.fromRGB(130, 130, 140)
				Instance.new("UICorner", rmBtn).CornerRadius = UDim.new(0, 4)

				rmBtn.MouseEnter:Connect(function()
					tweenService:Create(rmBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0, ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				end)
				rmBtn.MouseLeave:Connect(function()
					tweenService:Create(rmBtn, TweenInfo.new(0.12), {BackgroundTransparency = 1, ImageColor3 = Color3.fromRGB(130, 130, 140)}):Play()
				end)

				rmBtn.MouseButton1Click:Connect(function()
					if _G.SlateMusicRemoveFromPlaylist then
						_G.SlateMusicRemoveFromPlaylist(plName, trk.id)
					end
					for _, c in ipairs(card:GetDescendants()) do
						if c:IsA("TextLabel") then
							tweenService:Create(c, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
						elseif c:IsA("ImageLabel") or c:IsA("ImageButton") then
							tweenService:Create(c, TweenInfo.new(0.12), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
						end
					end
					tweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -4, 0, 0)
					}):Play()
					task.delay(0.16, function()
						card:Destroy()
					end)
				end)
			end
		end

		plBackBtn.MouseButton1Click:Connect(function()
			PlaylistDetailView.Visible = false
			LibraryOverview.Visible = true
		end)

		local function refreshLibraryView()
			for _, child in ipairs(LibListFrame:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			local playlists = (_G.SlateMusicGetPlaylists and _G.SlateMusicGetPlaylists()) or SlateMusic.playlists or {["Favorites"] = {}}

			local function loadThumbInto(imgObj, cUrl, safeIdKey)
				if not cUrl or cUrl == "" then return end
				task.spawn(function()
					local thumbFile = "slate/music/thumbs/" .. safeIdKey .. ".png"
					if not (isfile and isfile(thumbFile)) then
						local imgData = fetchMediaUrl(cUrl)
						if imgData and writefile then pcall(writefile, thumbFile, imgData) end
					end
					if isfile and isfile(thumbFile) then
						local assetUri = nil
						if getcustomasset then pcall(function() assetUri = getcustomasset(thumbFile) end)
						elseif getsynasset then pcall(function() assetUri = getsynasset(thumbFile) end) end
						if assetUri then
							imgObj.ImageTransparency = 1
							imgObj.Image = assetUri
							tweenService:Create(imgObj, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()
						end
					end
				end)
			end

			for plName, trackList in pairs(playlists) do
				local card = Instance.new("Frame", LibListFrame)
				card.Size = UDim2.new(1, -4, 0, 46)
				card.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
				card.BorderSizePixel = 0
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

				local thumbContainer = Instance.new("Frame", card)
				thumbContainer.Size = UDim2.new(0, 34, 0, 34)
				thumbContainer.Position = UDim2.new(0, 6, 0.5, -17)
				thumbContainer.BackgroundColor3 = (plName == "Favorites") and Color3.fromRGB(32, 32, 34) or Color3.fromRGB(24, 24, 30)
				thumbContainer.BorderSizePixel = 0
				thumbContainer.ClipsDescendants = true
				Instance.new("UICorner", thumbContainer).CornerRadius = UDim.new(0, 5)

				if plName == "Favorites" then
					local starIcon = Instance.new("ImageLabel", thumbContainer)
					starIcon.Size = UDim2.new(0, 18, 0, 18)
					starIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
					starIcon.BackgroundTransparency = 1
					starIcon.Image = SpIcons.StarFilled
					starIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				else

					local customCover = SlateMusic and SlateMusic.playlistMeta and SlateMusic.playlistMeta[plName] and SlateMusic.playlistMeta[plName].cover
					if customCover and customCover ~= "" then
						local singleImg = Instance.new("ImageLabel", thumbContainer)
						singleImg.Size = UDim2.new(1, 0, 1, 0)
						singleImg.BackgroundTransparency = 1
						singleImg.ScaleType = Enum.ScaleType.Crop
						loadThumbInto(singleImg, customCover, "pl_spot_" .. tostring(plName):gsub("[^%w%-_]", "_"))
					elseif #trackList >= 4 then

						local gridBox = Instance.new("Frame", thumbContainer)
						gridBox.Size = UDim2.new(1, 0, 1, 0)
						gridBox.BackgroundTransparency = 1
						local gLayout = Instance.new("UIGridLayout", gridBox)
						gLayout.CellSize = UDim2.new(0.5, 0, 0.5, 0)
						gLayout.CellPadding = UDim2.new(0, 0, 0, 0)

						for gIdx = 1, 4 do
							local trkItem = trackList[gIdx]
							local subImg = Instance.new("ImageLabel", gridBox)
							subImg.Size = UDim2.new(1, 0, 1, 0)
							subImg.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
							subImg.BorderSizePixel = 0
							subImg.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
							subImg.ScaleType = Enum.ScaleType.Crop
							if trkItem and trkItem.coverUrl and trkItem.coverUrl ~= "" then
								loadThumbInto(subImg, trkItem.coverUrl, "grid_" .. tostring(trkItem.id or gIdx):gsub("[^%w%-_]", "_"))
							end
						end
					elseif #trackList >= 1 then

						local trkItem = trackList[1]
						local singleImg = Instance.new("ImageLabel", thumbContainer)
						singleImg.Size = UDim2.new(1, 0, 1, 0)
						singleImg.BackgroundTransparency = 1
						singleImg.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
						singleImg.ScaleType = Enum.ScaleType.Crop
						if trkItem and trkItem.coverUrl and trkItem.coverUrl ~= "" then
							loadThumbInto(singleImg, trkItem.coverUrl, "single_" .. tostring(trkItem.id):gsub("[^%w%-_]", "_"))
						end
					else

						local emptyIcon = Instance.new("ImageLabel", thumbContainer)
						emptyIcon.Size = UDim2.new(0, 18, 0, 18)
						emptyIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
						emptyIcon.BackgroundTransparency = 1
						emptyIcon.Image = SpIcons.Library
						emptyIcon.ImageColor3 = Color3.fromRGB(150, 150, 160)
					end
				end

				local sTitle = Instance.new("TextLabel", card)
				sTitle.Size = UDim2.new(0.5, 0, 0, 16)
				sTitle.Position = UDim2.new(0, 48, 0, 7)
				sTitle.BackgroundTransparency = 1
				sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
				sTitle.Font = Enum.Font.GothamBold
				sTitle.TextSize = 12
				sTitle.TextXAlignment = Enum.TextXAlignment.Left
				sTitle.TextTruncate = Enum.TextTruncate.AtEnd
				sTitle.Text = plName

				local sCount = Instance.new("TextLabel", card)
				sCount.Size = UDim2.new(0.5, 0, 0, 14)
				sCount.Position = UDim2.new(0, 48, 0, 23)
				sCount.BackgroundTransparency = 1
				sCount.TextColor3 = Color3.fromRGB(130, 130, 140)
				sCount.Font = Enum.Font.Gotham
				sCount.TextSize = 10.5
				sCount.TextXAlignment = Enum.TextXAlignment.Left
				sCount.Text = tostring(#trackList) .. " tracks • Click to view"

				local cardClickBtn = Instance.new("TextButton", card)
				cardClickBtn.Size = UDim2.new(1, (plName ~= "Favorites") and -38 or 0, 1, 0)
				cardClickBtn.Position = UDim2.new(0, 0, 0, 0)
				cardClickBtn.BackgroundTransparency = 1
				cardClickBtn.Text = ""
				cardClickBtn.ZIndex = 3

				cardClickBtn.MouseEnter:Connect(function()
					tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
				end)
				cardClickBtn.MouseLeave:Connect(function()
					tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(15, 15, 18)}):Play()
				end)
				cardClickBtn.MouseButton1Click:Connect(function()
					openPlaylistView(plName)
				end)

				if plName ~= "Favorites" then
					local delPlBtn = Instance.new("ImageButton", card)
					delPlBtn.Name = "DeletePlaylistBtn"
					delPlBtn.Size = UDim2.new(0, 24, 0, 24)
					delPlBtn.Position = UDim2.new(1, -30, 0.5, -12)
					delPlBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
					delPlBtn.BackgroundTransparency = 1
					delPlBtn.BorderSizePixel = 0
					delPlBtn.Image = SpIcons.DeleteTrack
					delPlBtn.ImageColor3 = Color3.fromRGB(140, 140, 150)
					delPlBtn.Active = true
					delPlBtn.ZIndex = 10
					Instance.new("UICorner", delPlBtn).CornerRadius = UDim.new(0, 5)

					delPlBtn.MouseEnter:Connect(function()
						tweenService:Create(delPlBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0, ImageColor3 = Color3.fromRGB(110, 110, 115)}):Play()
					end)
					delPlBtn.MouseLeave:Connect(function()
						tweenService:Create(delPlBtn, TweenInfo.new(0.12), {BackgroundTransparency = 1, ImageColor3 = Color3.fromRGB(140, 140, 150)}):Play()
					end)
					delPlBtn.MouseButton1Click:Connect(function()
						if _G.SlateMusicDeletePlaylist then
							_G.SlateMusicDeletePlaylist(plName)
						end
						queueNotification("Playlist Deleted", "Deleted playlist '" .. tostring(plName) .. "'", 2)
						for _, c in ipairs(card:GetDescendants()) do
							if c:IsA("TextLabel") then
								tweenService:Create(c, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
							elseif c:IsA("ImageLabel") or c:IsA("ImageButton") then
								tweenService:Create(c, TweenInfo.new(0.1), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
							end
						end
						tweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -4, 0, 0)
						}):Play()
						task.delay(0.16, function()
							card:Destroy()
						end)
					end)
				end
			end
		end

		local function switchSpotifyTab(tabName)
			homeTabBtn.BackgroundColor3 = (tabName == "Home") and Color3.fromRGB(34, 34, 40) or Color3.fromRGB(15, 15, 18)
			homeTabBtn.BackgroundTransparency = (tabName == "Home") and 0 or 1
			homeTabBtn.TextColor3 = (tabName == "Home") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)
			homeIcon.ImageColor3 = (tabName == "Home") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)

			searchTabBtn.BackgroundColor3 = (tabName == "Search") and Color3.fromRGB(34, 34, 40) or Color3.fromRGB(15, 15, 18)
			searchTabBtn.BackgroundTransparency = (tabName == "Search") and 0 or 1
			searchTabBtn.TextColor3 = (tabName == "Search") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)
			searchIcon.ImageColor3 = (tabName == "Search") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)

			libraryTabBtn.BackgroundColor3 = (tabName == "Library") and Color3.fromRGB(34, 34, 40) or Color3.fromRGB(15, 15, 18)
			libraryTabBtn.BackgroundTransparency = (tabName == "Library") and 0 or 1
			libraryTabBtn.TextColor3 = (tabName == "Library") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)
			libIcon.ImageColor3 = (tabName == "Library") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150)

			HomeView.Visible = (tabName == "Home")
			SearchView.Visible = (tabName == "Search")
			LibraryView.Visible = (tabName == "Library")
			EqPanel.Visible = false
			ArtistView.Visible = false

			if tabName == "Library" then
				LibraryOverview.Visible = true
				PlaylistDetailView.Visible = false
				refreshLibraryView()
			end
		end

		_G.SlateSwitchSpotifyTab = switchSpotifyTab

		homeTabBtn.MouseButton1Click:Connect(function() switchSpotifyTab("Home") end)
		searchTabBtn.MouseButton1Click:Connect(function() switchSpotifyTab("Search") end)
		libraryTabBtn.MouseButton1Click:Connect(function() switchSpotifyTab("Library") end)

		local Deck = Instance.new("Frame", MusicTab)
		Deck.Name = "NowPlayingDeck"
		Deck.Size = UDim2.new(0.92, 0, 0, 48)
		Deck.Position = UDim2.new(0.04, 0, 0.835, 0)
		Deck.BackgroundTransparency = 1
		Deck.BorderSizePixel = 0

		art = Instance.new("ImageLabel", Deck)
		art.Name = "DeckCover"
		art.Size = UDim2.new(0, 46, 0, 46)
		art.Position = UDim2.new(0, 4, 0.5, -23)
		art.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
		art.BorderSizePixel = 0
		art.Image = "rbxassetid://76273968889626"
		art.ScaleType = Enum.ScaleType.Fit
		Instance.new("UICorner", art).CornerRadius = UDim.new(0, 6)

		uiSongLabel = Instance.new("TextLabel", Deck)
		uiSongLabel.Size = UDim2.new(0, 140, 0, 18)
		uiSongLabel.Position = UDim2.new(0, 58, 0, 14)
		uiSongLabel.BackgroundTransparency = 1
		uiSongLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		uiSongLabel.TextSize = 12.5
		uiSongLabel.Font = Enum.Font.GothamBold
		uiSongLabel.TextXAlignment = Enum.TextXAlignment.Left
		uiSongLabel.TextTruncate = Enum.TextTruncate.AtEnd
		uiSongLabel.Text = "No Track Playing"

		uiArtistLabel = Instance.new("TextLabel", Deck)
		uiArtistLabel.Size = UDim2.new(0, 140, 0, 14)
		uiArtistLabel.Position = UDim2.new(0, 58, 0, 34)
		uiArtistLabel.BackgroundTransparency = 1
		uiArtistLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
		uiArtistLabel.TextSize = 10.5
		uiArtistLabel.Font = Enum.Font.Gotham
		uiArtistLabel.TextXAlignment = Enum.TextXAlignment.Left
		uiArtistLabel.TextTruncate = Enum.TextTruncate.AtEnd
		uiArtistLabel.Text = "Music Player"

		local deckControls = Instance.new("Frame", Deck)
		deckControls.Size = UDim2.new(0, 180, 0, 26)
		deckControls.Position = UDim2.new(0.5, -90, 0, 4)
		deckControls.BackgroundTransparency = 1

		local uiShuffle = Instance.new("ImageButton", deckControls)
		uiShuffle.Size = UDim2.new(0, 16, 0, 16)
		uiShuffle.Position = UDim2.new(0, 10, 0.5, -8)
		uiShuffle.BackgroundTransparency = 1
		uiShuffle.Image = SpIcons.Shuffle
		uiShuffle.ImageColor3 = Color3.fromRGB(110, 110, 120)
		uiShuffle.Active = true
		uiShuffle.ZIndex = 10

		local deckShuffleDot = Instance.new("Frame", uiShuffle)
		deckShuffleDot.Size = UDim2.new(0, 3.5, 0, 3.5)
		deckShuffleDot.Position = UDim2.new(0.5, -2, 1, 2)
		deckShuffleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		deckShuffleDot.BorderSizePixel = 0
		deckShuffleDot.ZIndex = 11
		deckShuffleDot.Visible = false
		Instance.new("UICorner", deckShuffleDot).CornerRadius = UDim.new(1, 0)
		_G.SlateDeckShuffleDot = deckShuffleDot

		local uiBack = Instance.new("ImageButton", deckControls)
		uiBack.Size = UDim2.new(0, 20, 0, 20)
		uiBack.Position = UDim2.new(0, 42, 0.5, -10)
		uiBack.BackgroundTransparency = 1
		uiBack.Image = SpIcons.Prev
		uiBack.ImageColor3 = Color3.fromRGB(160, 160, 175)

		uiPlay = Instance.new("ImageButton", deckControls)
		uiPlay.Size = UDim2.new(0, 28, 0, 28)
		uiPlay.Position = UDim2.new(0.5, -14, 0.5, -14)
		uiPlay.BackgroundTransparency = 1
		uiPlay.Image = SpIcons.Play
		uiPlay.ImageColor3 = Color3.fromRGB(255, 255, 255)

		local uiNext = Instance.new("ImageButton", deckControls)
		uiNext.Size = UDim2.new(0, 20, 0, 20)
		uiNext.Position = UDim2.new(1, -62, 0.5, -10)
		uiNext.BackgroundTransparency = 1
		uiNext.Image = SpIcons.Next
		uiNext.ImageColor3 = Color3.fromRGB(160, 160, 175)

		local uiRepeat = Instance.new("ImageButton", deckControls)
		uiRepeat.Size = UDim2.new(0, 16, 0, 16)
		uiRepeat.Position = UDim2.new(1, -26, 0.5, -8)
		uiRepeat.BackgroundTransparency = 1
		uiRepeat.Image = SpIcons.Repeat
		uiRepeat.ImageColor3 = Color3.fromRGB(110, 110, 120)

		local isShuffleActive = false
		local isRepeatActive = false

		local ScrubberArea = Instance.new("Frame", Deck)
		ScrubberArea.Size = UDim2.new(0, 260, 0, 16)
		ScrubberArea.Position = UDim2.new(0.5, -130, 0, 39)
		ScrubberArea.BackgroundTransparency = 1

		local uiTimeCurrent = Instance.new("TextLabel", ScrubberArea)
		uiTimeCurrent.Size = UDim2.new(0, 28, 1, 0)
		uiTimeCurrent.Position = UDim2.new(0, 0, 0, 0)
		uiTimeCurrent.BackgroundTransparency = 1
		uiTimeCurrent.TextColor3 = Color3.fromRGB(130, 130, 140)
		uiTimeCurrent.TextSize = 9.5
		uiTimeCurrent.Font = Enum.Font.Gotham
		uiTimeCurrent.TextXAlignment = Enum.TextXAlignment.Right
		uiTimeCurrent.Text = "0:00"
		_G.SlateDeckTimeCurrent = uiTimeCurrent

		local uiProgBg = Instance.new("Frame", ScrubberArea)
		uiProgBg.Size = UDim2.new(1, -66, 0, 8)
		uiProgBg.Position = UDim2.new(0, 33, 0.5, -4)
		uiProgBg.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
		uiProgBg.BorderSizePixel = 0
		Instance.new("UICorner", uiProgBg).CornerRadius = UDim.new(1, 0)

		uiProgFill = Instance.new("Frame", uiProgBg)
		uiProgFill.Size = UDim2.new(0, 0, 1, 0)
		uiProgFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		uiProgFill.BorderSizePixel = 0
		Instance.new("UICorner", uiProgFill).CornerRadius = UDim.new(1, 0)
		_G.SlateDeckProgFill = uiProgFill

		local deckProgGrad = Instance.new("UIGradient", uiProgFill)
		deckProgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 34)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 48, 50)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 160, 165))
		})

		local deckProgKnob = Instance.new("Frame", uiProgFill)
		deckProgKnob.Size = UDim2.new(0, 18, 0, 18)
		deckProgKnob.AnchorPoint = Vector2.new(0.5, 0.5)
		deckProgKnob.Position = UDim2.new(1, 0, 0.5, 0)
		deckProgKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		deckProgKnob.BackgroundTransparency = 0
		deckProgKnob.BorderSizePixel = 0
		deckProgKnob.ZIndex = 6
		Instance.new("UICorner", deckProgKnob).CornerRadius = UDim.new(1, 0)
		local deckProgStroke = Instance.new("UIStroke", deckProgKnob)
		deckProgStroke.Color = Color3.fromRGB(160, 160, 165)
		deckProgStroke.Transparency = 0.35
		deckProgStroke.Thickness = 1.4

		local deckProgClickBtn = Instance.new("TextButton", uiProgBg)
		deckProgClickBtn.Size = UDim2.new(1, 0, 4, 0)
		deckProgClickBtn.Position = UDim2.new(0, 0, 0.5, -8)
		deckProgClickBtn.BackgroundTransparency = 1
		deckProgClickBtn.Text = ""
		deckProgClickBtn.ZIndex = 7

		local isScrubbingDeck = false
		local function updateDeckScrub(input)
			local absPos = uiProgBg.AbsolutePosition
			local absSize = uiProgBg.AbsoluteSize
			local pct = math.clamp((input.Position.X - absPos.X) / math.max(absSize.X, 1), 0, 1)
			tweenService:Create(uiProgFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
			if ProgressBarFill then
				tweenService:Create(ProgressBarFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
			end
			local total = _G.SlateMusicTotalDuration or 0
			if total > 0 then
				local curSec = pct * total
				local m = math.floor(curSec / 60)
				local s = math.floor(curSec % 60)
				local str = string.format("%d:%02d", m, s)
				if _G.SlateDeckTimeCurrent then _G.SlateDeckTimeCurrent.Text = str end
				if TimeCurrent then TimeCurrent.Text = str end
			end
			return pct
		end

		deckProgClickBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isScrubbingDeck = true
				_G.SlateIsScrubbing = true
				tweenService:Create(deckProgKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 0.45}):Play()
				tweenService:Create(deckProgStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.1, Thickness = 1.8}):Play()
				local pct = updateDeckScrub(input)
				local total = _G.SlateMusicTotalDuration or 0
				if total > 0 and _G.SlateMusicSeek then _G.SlateMusicSeek(pct * total) end
			end
		end)
		userInputService.InputChanged:Connect(function(input)
			if isScrubbingDeck and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateDeckScrub(input)
			end
		end)
		userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if isScrubbingDeck then
					local pct = updateDeckScrub(input)
					isScrubbingDeck = false
					_G.SlateIsScrubbing = false
					tweenService:Create(deckProgKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0}):Play()
					tweenService:Create(deckProgStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.35, Thickness = 1.4}):Play()
					local total = _G.SlateMusicTotalDuration or 0
					if total > 0 and _G.SlateMusicSeek then _G.SlateMusicSeek(pct * total) end
				end
			end
		end)

		local uiTimeLength = Instance.new("TextLabel", ScrubberArea)
		uiTimeLength.Size = UDim2.new(0, 28, 1, 0)
		uiTimeLength.Position = UDim2.new(1, -28, 0, 0)
		uiTimeLength.BackgroundTransparency = 1
		uiTimeLength.TextColor3 = Color3.fromRGB(130, 130, 140)
		uiTimeLength.TextSize = 9.5
		uiTimeLength.Font = Enum.Font.Gotham
		uiTimeLength.TextXAlignment = Enum.TextXAlignment.Left
		uiTimeLength.Text = "0:00"
		_G.SlateDeckTimeLength = uiTimeLength

		local VolArea = Instance.new("Frame", Deck)
		VolArea.Name = "VolArea"
		VolArea.Size = UDim2.new(0, 92, 0, 18)
		VolArea.Position = UDim2.new(1, -132, 0.5, -9)
		VolArea.BackgroundTransparency = 1

		local volIcon = Instance.new("ImageLabel", VolArea)
		volIcon.Size = UDim2.new(0, 14, 0, 14)
		volIcon.Position = UDim2.new(0, 0, 0.5, -7)
		volIcon.BackgroundTransparency = 1
		volIcon.Image = "rbxthumb://type=Asset&id=113463212610691&w=150&h=150"
		volIcon.ImageColor3 = Color3.fromRGB(140, 140, 150)

		local volTrack = Instance.new("Frame", VolArea)
		volTrack.Size = UDim2.new(0, 68, 0, 8)
		volTrack.Position = UDim2.new(0, 20, 0.5, -4)
		volTrack.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
		volTrack.BorderSizePixel = 0
		Instance.new("UICorner", volTrack).CornerRadius = UDim.new(1, 0)

		local volFill = Instance.new("Frame", volTrack)
		volFill.Size = UDim2.new(0.75, 0, 1, 0)
		volFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		volFill.BorderSizePixel = 0
		Instance.new("UICorner", volFill).CornerRadius = UDim.new(1, 0)
		_G.SlateSyncVolFill = volFill

		local volGrad = Instance.new("UIGradient", volFill)
		volGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 34)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 48, 50)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 160, 165))
		})

		local volKnob = Instance.new("Frame", volFill)
		volKnob.Size = UDim2.new(0, 14, 0, 14)
		volKnob.AnchorPoint = Vector2.new(0.5, 0.5)
		volKnob.Position = UDim2.new(1, 0, 0.5, 0)
		volKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		volKnob.BackgroundTransparency = 0
		volKnob.BorderSizePixel = 0
		Instance.new("UICorner", volKnob).CornerRadius = UDim.new(1, 0)
		local volStroke = Instance.new("UIStroke", volKnob)
		volStroke.Color = Color3.fromRGB(160, 160, 165)
		volStroke.Transparency = 0.35
		volStroke.Thickness = 1.4

		local volClickBtn = Instance.new("TextButton", volTrack)
		volClickBtn.Size = UDim2.new(1, 0, 4, 0)
		volClickBtn.Position = UDim2.new(0, 0, -1.5, 0)
		volClickBtn.BackgroundTransparency = 1
		volClickBtn.Text = ""

		local isDraggingVol = false
		local function updateVol(input)
			local frac = math.clamp((input.Position.X - volTrack.AbsolutePosition.X) / volTrack.AbsoluteSize.X, 0, 1)
			tweenService:Create(volFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(frac, 0, 1, 0)}):Play()
			if _G.SlateSyncSubVolFill then
				tweenService:Create(_G.SlateSyncSubVolFill, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(frac, 0, 1, 0)}):Play()
			end
			if _G.SlateMusicSetVolume then _G.SlateMusicSetVolume(frac) end
		end

		volClickBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDraggingVol = true
				tweenService:Create(volKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 0.45}):Play()
				tweenService:Create(volStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.1, Thickness = 1.8}):Play()
				updateVol(input)
			end
		end)
		userInputService.InputChanged:Connect(function(input)
			if isDraggingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateVol(input)
			end
		end)
		userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if isDraggingVol then
					isDraggingVol = false
					tweenService:Create(volKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0}):Play()
					tweenService:Create(volStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.35, Thickness = 1.4}):Play()
				end
			end
		end)

		_G.SlateSyncRepeatUI = function(mode)
			local col = (mode == "off") and Color3.fromRGB(110, 110, 120) or Color3.fromRGB(255, 255, 255)
			local isOne = (mode == "one")

			if uiRepeat then
				uiRepeat.Image = "rbxthumb://type=Asset&id=138997712866797&w=150&h=150"
				uiRepeat.ImageColor3 = col
			end
			if RepeatBtn then
				RepeatBtn.Image = "rbxthumb://type=Asset&id=138997712866797&w=150&h=150"
				RepeatBtn.ImageColor3 = col
			end
			if _G.SlateSubRepeatBadge then _G.SlateSubRepeatBadge.Visible = isOne end
			if _G.SlateDeckRepeatBadge then _G.SlateDeckRepeatBadge.Visible = isOne end
		end

		_G.SlateSyncShuffleUI = function(active)
			local col = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120)
			if uiShuffle then uiShuffle.ImageColor3 = col end
			if ShuffleBtn then ShuffleBtn.ImageColor3 = col end
			if _G.SlateShuffleBtn then _G.SlateShuffleBtn.ImageColor3 = col end
			if _G.SlateSubShuffleDot then _G.SlateSubShuffleDot.Visible = active end
			if _G.SlateDeckShuffleDot then _G.SlateDeckShuffleDot.Visible = active end
		end

		local popoutBtn = Instance.new("ImageButton", Deck)
		popoutBtn.Size = UDim2.new(0, 22, 0, 22)
		popoutBtn.Position = UDim2.new(1, -28, 0.5, -11)
		popoutBtn.BackgroundTransparency = 1
		popoutBtn.Image = SpIcons.Popout
		popoutBtn.ImageColor3 = Color3.fromRGB(150, 150, 160)
		popoutBtn.MouseEnter:Connect(function()
			tweenService:Create(popoutBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end)
		popoutBtn.MouseLeave:Connect(function()
			tweenService:Create(popoutBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(150, 150, 160)}):Play()
		end)
		popoutBtn.MouseButton1Click:Connect(function()
			SpotifyWindow.Visible = not SpotifyWindow.Visible
		end)

		uiPlay.MouseButton1Click:Connect(function()
			if _G.SlateMusicTogglePlay then _G.SlateMusicTogglePlay() end
		end)
		SpotifyPlayBtn.MouseButton1Click:Connect(function()
			if _G.SlateMusicTogglePlay then _G.SlateMusicTogglePlay() end
		end)
		uiBack.MouseButton1Click:Connect(function()
			if _G.SlateMusicPrev then _G.SlateMusicPrev() end
		end)
		SpotifyBackBtn.MouseButton1Click:Connect(function()
			if _G.SlateMusicPrev then _G.SlateMusicPrev() end
		end)
		uiNext.MouseButton1Click:Connect(function()
			if _G.SlateMusicNext then _G.SlateMusicNext() end
		end)
		SpotifyNextBtn.MouseButton1Click:Connect(function()
			if _G.SlateMusicNext then _G.SlateMusicNext() end
		end)

		uiShuffle.MouseButton1Click:Connect(function()
			if _G.SlateMusicToggleShuffle then _G.SlateMusicToggleShuffle() end
		end)
		ShuffleBtn.MouseButton1Click:Connect(function()
			if _G.SlateMusicToggleShuffle then _G.SlateMusicToggleShuffle() end
		end)

		uiRepeat.MouseButton1Click:Connect(function()
			if _G.SlateMusicToggleRepeat then _G.SlateMusicToggleRepeat() end
		end)
		RepeatBtn.MouseButton1Click:Connect(function()
			if _G.SlateMusicToggleRepeat then _G.SlateMusicToggleRepeat() end
		end)

		local currentSearchGen = 0
		local lastSearchQuery = ""
		local searchTimerThread = nil

		local function performLiveSearch(q)
			q = (q or ""):gsub("^%s+", ""):gsub("%s+$", "")
			if q == lastSearchQuery then return end
			lastSearchQuery = q

			if q == "" then
				for _, section in ipairs({ ArtistSection, SongSection }) do
					for _, child in ipairs(section:GetChildren()) do
						if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
					end
				end
				return
			end

			currentSearchGen = currentSearchGen + 1
			local thisGen = currentSearchGen

			if _G.SlateMusicSearchArtists then
				_G.SlateMusicSearchArtists(q, function(artists)
					if thisGen == currentSearchGen and _G.SlateRenderMusicArtists then
						_G.SlateRenderMusicArtists(artists, thisGen)
					end
				end)
			end

			if _G.SlateMusicSearch then
				_G.SlateMusicSearch(q, function(tracks)
					if thisGen == currentSearchGen and _G.SlateRenderMusicResults then
						_G.SlateRenderMusicResults(tracks, thisGen)
					end
				end)
			end
		end

		MusicSearchBar.FocusLost:Connect(function()
			performLiveSearch(MusicSearchBar.Text)
		end)

		MusicSortBtn.MouseButton1Click:Connect(function()
			sortModeIndex = (sortModeIndex % #SortModes) + 1
			local mode = SortModes[sortModeIndex]
			MusicSortBtn.Text = mode.label
			if _G.SlateMusicSetSearchSort then _G.SlateMusicSetSearchSort(mode.key) end

			local existing = _G.SlateMusicGetLastResults and _G.SlateMusicGetLastResults() or nil
			if existing and #existing > 0 and _G.SlateRenderMusicResults then
				_G.SlateRenderMusicResults(existing, currentSearchGen)
			end
		end)

		MusicSearchBar:GetPropertyChangedSignal("Text"):Connect(function()
			local txt = MusicSearchBar.Text
			if searchTimerThread then
				task.cancel(searchTimerThread)
				searchTimerThread = nil
			end
			searchTimerThread = task.delay(0.35, function()
				performLiveSearch(txt)
			end)
		end)

		createSongCard = (function(parent, trk, idx, list)
				local ok = pcall(function()
					local safeId = tostring(trk.id or idx):gsub("[^%w%-_]", "_")
					local card = Instance.new("Frame", parent)
					card.Name = "SongCard_" .. safeId
					card.Size = UDim2.new(1, -6, 0, 44)
					card.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
					card.BackgroundTransparency = 1
					card.BorderSizePixel = 0
					Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

					task.spawn(function()
						task.wait(math.min(idx * 0.015, 0.2))
						if card and card.Parent then
							tweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
						end
					end)

					local thumb = Instance.new("ImageLabel", card)
					thumb.Size = UDim2.new(0, 34, 0, 34)
					thumb.Position = UDim2.new(0, 6, 0.5, -17)
					thumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
					thumb.BorderSizePixel = 0
					thumb.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
					thumb.ScaleType = Enum.ScaleType.Crop
					Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 5)

					if trk.coverUrl and trk.coverUrl ~= "" then
						task.spawn(function()
							local thumbFile = "slate/music/thumbs/" .. safeId .. ".png"
							if not (isfile and isfile(thumbFile)) then
								local imgData = fetchMediaUrl(trk.coverUrl)
								if imgData and writefile then
									pcall(writefile, thumbFile, imgData)
								end
							end
							if isfile and isfile(thumbFile) then
								local assetUri = nil
								if getcustomasset then
									pcall(function() assetUri = getcustomasset(thumbFile) end)
								elseif getsynasset then
									pcall(function() assetUri = getsynasset(thumbFile) end)
								end
								if assetUri then
									thumb.ImageTransparency = 1
									thumb.Image = assetUri
									tweenService:Create(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
								end
							end
						end)
					end

					local sTitle = Instance.new("TextLabel", card)
					sTitle.Size = UDim2.new(1, -272, 0, 16)
					sTitle.Position = UDim2.new(0, 48, 0, 6)
					sTitle.BackgroundTransparency = 1
					sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
					sTitle.Font = Enum.Font.GothamBold
					sTitle.TextSize = 12
					sTitle.TextXAlignment = Enum.TextXAlignment.Left
					sTitle.TextTruncate = Enum.TextTruncate.AtEnd
					sTitle.Text = tostring(trk.title or "Unknown Title")

					local sArtist = Instance.new("TextLabel", card)
					sArtist.Size = UDim2.new(1, -272, 0, 14)
					sArtist.Position = UDim2.new(0, 48, 0, 22)
					sArtist.BackgroundTransparency = 1
					sArtist.TextColor3 = Color3.fromRGB(140, 140, 150)
					sArtist.Font = Enum.Font.Gotham
					sArtist.TextSize = 10.5
					sArtist.TextXAlignment = Enum.TextXAlignment.Left
					sArtist.TextTruncate = Enum.TextTruncate.AtEnd
					sArtist.Text = tostring(trk.artist or "SoundCloud Artist")

					local likeCount = tonumber(trk.likes) or 0
					if likeCount > 0 then
						local likesLbl = Instance.new("TextLabel", card)
						likesLbl.Name = "LikesLabel"
						likesLbl.Size = UDim2.new(0, 66, 1, 0)
						likesLbl.Position = UDim2.new(1, -212, 0, 0)
						likesLbl.BackgroundTransparency = 1
						likesLbl.TextColor3 = Color3.fromRGB(115, 115, 128)
						likesLbl.Font = Enum.Font.Gotham
						likesLbl.TextSize = 10
						likesLbl.TextXAlignment = Enum.TextXAlignment.Right
						likesLbl.Text = formatCompactCount(likeCount) .. " likes"
					end

					if trk.isGoPlus or trk.isOfficial then
						local goBadge = Instance.new("Frame", card)
						goBadge.Size = UDim2.new(0, 46, 0, 14)
						goBadge.Position = UDim2.new(1, -142, 0.5, -7)
						goBadge.BackgroundColor3 = trk.isGoPlus and Color3.fromRGB(40, 34, 22) or Color3.fromRGB(28, 28, 36)
						goBadge.BorderSizePixel = 0
						Instance.new("UICorner", goBadge).CornerRadius = UDim.new(0, 4)
						local gbStroke = Instance.new("UIStroke", goBadge)
						gbStroke.Color = trk.isGoPlus and Color3.fromRGB(150, 120, 55) or Color3.fromRGB(65, 65, 80)
						gbStroke.Thickness = 0.85
						local gbText = Instance.new("TextLabel", goBadge)
						gbText.Size = UDim2.new(1, 0, 1, 0)
						gbText.BackgroundTransparency = 1
						gbText.Text = trk.isGoPlus and "GO+" or "OFFICIAL"
						gbText.TextColor3 = trk.isGoPlus and Color3.fromRGB(255, 245, 210) or Color3.fromRGB(215, 215, 228)
						gbText.Font = Enum.Font.GothamBold
						gbText.TextSize = 8.5
					end

					local durLbl = Instance.new("TextLabel", card)
					durLbl.Size = UDim2.new(0, 36, 1, 0)
					durLbl.Position = UDim2.new(1, -94, 0, 0)
					durLbl.BackgroundTransparency = 1
					durLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
					durLbl.Font = Enum.Font.Gotham
					durLbl.TextSize = 10.5
					durLbl.TextXAlignment = Enum.TextXAlignment.Right
					local totalSec = tonumber(trk.duration) or 180
					local m = math.floor(totalSec / 60)
					local s = totalSec % 60
					durLbl.Text = string.format("%d:%02d", m, s)

					local isFav = (_G.SlateMusicIsFavorite and _G.SlateMusicIsFavorite(trk))
					local favBtn = Instance.new("ImageButton", card)
					favBtn.Name = "FavBtn"
					favBtn.Size = UDim2.new(0, 18, 0, 18)
					favBtn.Position = UDim2.new(1, -52, 0.5, -9)
					favBtn.BackgroundTransparency = 1
					favBtn.Image = isFav and SpIcons.StarFilled or SpIcons.StarOutline
					favBtn.ImageColor3 = isFav and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120)
					favBtn.ZIndex = 5

					favBtn.MouseButton1Click:Connect(function()
						if _G.SlateMusicToggleFavorite then
							local active = _G.SlateMusicToggleFavorite(trk)
							favBtn.Image = active and SpIcons.StarFilled or SpIcons.StarOutline
							tweenService:Create(favBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
								ImageColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120)
							}):Play()
							queueNotification("Favorites", active and ("Added to Favorites") or ("Removed from Favorites"), 2)
						end
					end)

					local addPlBtn = Instance.new("ImageButton", card)
					addPlBtn.Name = "AddPlBtn"
					addPlBtn.Size = UDim2.new(0, 18, 0, 18)
					addPlBtn.Position = UDim2.new(1, -26, 0.5, -9)
					addPlBtn.BackgroundTransparency = 1
					addPlBtn.Image = SpIcons.Plus
					addPlBtn.ImageColor3 = Color3.fromRGB(130, 130, 140)
					addPlBtn.ZIndex = 5

					addPlBtn.MouseEnter:Connect(function()
						tweenService:Create(addPlBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
					end)
					addPlBtn.MouseLeave:Connect(function()
						tweenService:Create(addPlBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(130, 130, 140)}):Play()
					end)
					addPlBtn.MouseButton1Click:Connect(function()
						openPlaylistPicker(trk)
					end)

					local cardClickBtn = Instance.new("TextButton", card)
					cardClickBtn.Size = UDim2.new(1, -98, 1, 0)
					cardClickBtn.Position = UDim2.new(0, 0, 0, 0)
					cardClickBtn.BackgroundTransparency = 1
					cardClickBtn.Text = ""
					cardClickBtn.ZIndex = 3

					cardClickBtn.MouseEnter:Connect(function()
						tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
					end)
					cardClickBtn.MouseLeave:Connect(function()
						tweenService:Create(card, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(14, 14, 16)}):Play()
					end)

					cardClickBtn.MouseButton1Click:Connect(function()
						if _G.SlateMusicPlayTrack then _G.SlateMusicPlayTrack(trk, list, idx) end
					end)
				end)
				return ok
		end)

		_G.SlateRenderMusicArtists = (function(artists, genId)
			if genId and genId ~= currentSearchGen then return end

			for _, child in ipairs(ArtistSection:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
			end

			if not artists or #artists == 0 then return end

			local header = Instance.new("TextLabel", ArtistSection)
			header.Name = "ArtistsHeader"
			header.Size = UDim2.new(1, -6, 0, 18)
			header.LayoutOrder = 0
			header.BackgroundTransparency = 1
			header.Text = "ARTISTS"
			header.TextColor3 = Color3.fromRGB(100, 100, 112)
			header.Font = Enum.Font.GothamBold
			header.TextSize = 9
			header.TextXAlignment = Enum.TextXAlignment.Left

			for idx, artist in ipairs(artists) do
				pcall(function()
					local safeId = "artist_" .. tostring(artist.id):gsub("[^%w%-_]", "_")
					local row = Instance.new("Frame", ArtistSection)
					row.Name = "ArtistRow_" .. safeId
					row.Size = UDim2.new(1, -6, 0, 44)
					row.LayoutOrder = idx
					row.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
					row.BackgroundTransparency = 1
					row.BorderSizePixel = 0
					Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

					task.spawn(function()
						task.wait(math.min(idx * 0.015, 0.12))
						if row and row.Parent then
							tweenService:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
						end
					end)

					local avatar = Instance.new("ImageLabel", row)
					avatar.Size = UDim2.new(0, 34, 0, 34)
					avatar.Position = UDim2.new(0, 6, 0.5, -17)
					avatar.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
					avatar.BorderSizePixel = 0
					avatar.Image = "rbxthumb://type=Asset&id=77166898472490&w=150&h=150"
					avatar.ScaleType = Enum.ScaleType.Crop
					Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

					if artist.avatarUrl and artist.avatarUrl ~= "" then
						task.spawn(function()
							local avatarFile = "slate/music/thumbs/" .. safeId .. ".png"
							if not (isfile and isfile(avatarFile)) then
								local imgData = fetchMediaUrl(artist.avatarUrl)
								if imgData and writefile then pcall(writefile, avatarFile, imgData) end
							end
							if isfile and isfile(avatarFile) then
								local assetUri = nil
								if getcustomasset then pcall(function() assetUri = getcustomasset(avatarFile) end)
								elseif getsynasset then pcall(function() assetUri = getsynasset(avatarFile) end) end
								if assetUri and avatar and avatar.Parent then
									avatar.ImageTransparency = 1
									avatar.Image = assetUri
									tweenService:Create(avatar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
								end
							end
						end)
					end

					local nameLbl = Instance.new("TextLabel", row)
					nameLbl.Size = UDim2.new(1, -220, 0, 16)
					nameLbl.Position = UDim2.new(0, 48, 0, 6)
					nameLbl.BackgroundTransparency = 1
					nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
					nameLbl.Font = Enum.Font.GothamBold
					nameLbl.TextSize = 12
					nameLbl.TextXAlignment = Enum.TextXAlignment.Left
					nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
					nameLbl.Text = tostring(artist.name or "Artist")

					local subLbl = Instance.new("TextLabel", row)
					subLbl.Size = UDim2.new(1, -220, 0, 14)
					subLbl.Position = UDim2.new(0, 48, 0, 22)
					subLbl.BackgroundTransparency = 1
					subLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
					subLbl.Font = Enum.Font.Gotham
					subLbl.TextSize = 10.5
					subLbl.TextXAlignment = Enum.TextXAlignment.Left
					subLbl.TextTruncate = Enum.TextTruncate.AtEnd
					local bits = { "Artist" }
					if (artist.followers or 0) > 0 then
						table.insert(bits, formatCompactCount(artist.followers) .. " followers")
					end
					subLbl.Text = table.concat(bits, "  ·  ")

					if artist.verified then
						local vBadge = Instance.new("Frame", row)
						vBadge.Size = UDim2.new(0, 58, 0, 14)
						vBadge.Position = UDim2.new(1, -142, 0.5, -7)
						vBadge.BackgroundColor3 = Color3.fromRGB(20, 30, 44)
						vBadge.BorderSizePixel = 0
						Instance.new("UICorner", vBadge).CornerRadius = UDim.new(0, 4)
						local vStroke = Instance.new("UIStroke", vBadge)
						vStroke.Color = Color3.fromRGB(52, 96, 148)
						vStroke.Thickness = 0.85
						local vText = Instance.new("TextLabel", vBadge)
						vText.Size = UDim2.new(1, 0, 1, 0)
						vText.BackgroundTransparency = 1
						vText.Text = "VERIFIED"
						vText.TextColor3 = Color3.fromRGB(150, 200, 255)
						vText.Font = Enum.Font.GothamBold
						vText.TextSize = 8.5
					end

					local viewLbl = Instance.new("TextLabel", row)
					viewLbl.Size = UDim2.new(0, 72, 1, 0)
					viewLbl.Position = UDim2.new(1, -78, 0, 0)
					viewLbl.BackgroundTransparency = 1
					viewLbl.TextColor3 = Color3.fromRGB(120, 120, 132)
					viewLbl.Font = Enum.Font.GothamBold
					viewLbl.TextSize = 10
					viewLbl.TextXAlignment = Enum.TextXAlignment.Right
					viewLbl.Text = "View  ›"

					local rowBtn = Instance.new("TextButton", row)
					rowBtn.Size = UDim2.new(1, 0, 1, 0)
					rowBtn.BackgroundTransparency = 1
					rowBtn.Text = ""
					rowBtn.ZIndex = 3

					rowBtn.MouseEnter:Connect(function()
						tweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
						tweenService:Create(viewLbl, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
					end)
					rowBtn.MouseLeave:Connect(function()
						tweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(14, 14, 16)}):Play()
						tweenService:Create(viewLbl, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(120, 120, 132)}):Play()
					end)
					rowBtn.MouseButton1Click:Connect(function()
						if openArtistView then openArtistView(artist) end
					end)
				end)
			end

			local spacer = Instance.new("Frame", ArtistSection)
			spacer.Name = "ArtistSpacer"
			spacer.Size = UDim2.new(1, 0, 0, 10)
			spacer.LayoutOrder = 999
			spacer.BackgroundTransparency = 1
			spacer.BorderSizePixel = 0

			local songsHeader = Instance.new("TextLabel", ArtistSection)
			songsHeader.Name = "SongsHeader"
			songsHeader.Size = UDim2.new(1, -6, 0, 18)
			songsHeader.LayoutOrder = 1000
			songsHeader.BackgroundTransparency = 1
			songsHeader.Text = "SONGS"
			songsHeader.TextColor3 = Color3.fromRGB(100, 100, 112)
			songsHeader.Font = Enum.Font.GothamBold
			songsHeader.TextSize = 9
			songsHeader.TextXAlignment = Enum.TextXAlignment.Left
		end)

		_G.SlateRenderMusicResults = (function(tracks, genId)
			if genId and genId ~= currentSearchGen then return end

			for _, child in ipairs(SongSection:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
			end

			if not tracks or #tracks == 0 then
				local emptyLbl = Instance.new("TextLabel", SongSection)
				emptyLbl.Size = UDim2.new(1, 0, 0, 50)
				emptyLbl.BackgroundTransparency = 1
				emptyLbl.Text = "No tracks found. Try searching for a song or artist!"
				emptyLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
				emptyLbl.Font = Enum.Font.GothamMedium
				emptyLbl.TextSize = 12
				return
			end

			for idx, trk in ipairs(tracks) do
				createSongCard(SongSection, trk, idx, tracks)
			end
		end)
		end
		pcall(_init_block_9424)
	end

	do
		local function initFacebang()

			FacebangWindow = Instance.new("Frame", G2L["1"])
			FacebangWindow.Name = "FacebangControls"
			FacebangWindow.Size = UDim2.new(0, 260, 0, 216)
			FacebangWindow.Position = UDim2.new(0.02, 0, 0.72, 0)
			FacebangWindow.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
			FacebangWindow.BorderSizePixel = 0
			FacebangWindow.ZIndex = 1
			FacebangWindow.Visible = false
			local FacebangCorner = Instance.new("UICorner", FacebangWindow)
			FacebangCorner.CornerRadius = UDim.new(0, 12)
			local FacebangStroke = Instance.new("UIStroke", FacebangWindow)
			FacebangStroke.Thickness = 0.99
			FacebangStroke.Color = Color3.fromRGB(40, 40, 42)

			createSlateBackdrop(FacebangWindow, 12, { zIndex = 0, rotation = 44 })

			local FacebangLogo = Instance.new("ImageLabel", FacebangWindow)
			FacebangLogo.Size = UDim2.new(0, 20, 0, 20)
			FacebangLogo.Position = UDim2.new(0, 12, 0, 12)
			FacebangLogo.Image = "rbxassetid://106790631609801"
			FacebangLogo.BackgroundTransparency = 1
			FacebangLogo.ScaleType = Enum.ScaleType.Fit
			FacebangLogo.ZIndex = 2

			local FacebangTitle = Instance.new("TextLabel", FacebangWindow)
			FacebangTitle.Size = UDim2.new(0.6, 0, 0, 20)
			FacebangTitle.Position = UDim2.new(0, 38, 0, 12)
			FacebangTitle.BackgroundTransparency = 1
			FacebangTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			FacebangTitle.Text = "Facebang Controls"
			FacebangTitle.TextSize = 13
			FacebangTitle.Font = Enum.Font.BuilderSansBold
			FacebangTitle.TextXAlignment = Enum.TextXAlignment.Left
			FacebangTitle.ZIndex = 2

			local FacebangCloseBtn = Instance.new("TextButton", FacebangWindow)
			FacebangCloseBtn.Name = "CloseBtn"
			FacebangCloseBtn.Size = UDim2.new(0, 20, 0, 20)
			FacebangCloseBtn.Position = UDim2.new(1, -28, 0, 12)
			FacebangCloseBtn.BackgroundTransparency = 1
			FacebangCloseBtn.Text = "×"
			FacebangCloseBtn.TextSize = 16
			FacebangCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			FacebangCloseBtn.Font = Enum.Font.GothamBold
			FacebangCloseBtn.ZIndex = 2
			FacebangCloseBtn.MouseButton1Click:Connect(function()
				FacebangWindow.Visible = false
			end)
			FacebangCloseBtn.MouseEnter:Connect(function() FacebangCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200) end)
			FacebangCloseBtn.MouseLeave:Connect(function() FacebangCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)

			local FBContentFrame = Instance.new("Frame", FacebangWindow)
			FBContentFrame.Name = "ContentFrame"
			FBContentFrame.Size = UDim2.new(1, -24, 1, -54)
			FBContentFrame.Position = UDim2.new(0, 12, 0, 44)
			FBContentFrame.BackgroundTransparency = 1
			FBContentFrame.ZIndex = 2
			local FBContentLayout = Instance.new("UIListLayout", FBContentFrame)
			FBContentLayout.Padding = UDim.new(0, 10)
			FBContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

			local function createFacebangSlider(name, minVal, maxVal, default, callback)
				local sliderFrame = Instance.new("Frame", FBContentFrame)
				sliderFrame.Size = UDim2.new(1, 0, 0, 35)
				sliderFrame.BackgroundTransparency = 1
				local label = Instance.new("TextLabel", sliderFrame)
				label.Size = UDim2.new(1, 0, 0, 14)
				label.BackgroundTransparency = 1
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.Text = name .. " (" .. tostring(default) .. ")"
				label.TextSize = 11
				label.Font = Enum.Font.BuilderSans
				label.TextXAlignment = Enum.TextXAlignment.Left

				local track = Instance.new("Frame", sliderFrame)
				track.Size = UDim2.new(1, 0, 0, 7)
				track.Position = UDim2.new(0, 0, 0, 21)
				track.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
				track.BorderSizePixel = 0
				track.Active = true
				Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

				local fill = Instance.new("Frame", track)
				fill.Size = UDim2.new(0.5, 0, 1, 0)
				fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				fill.BorderSizePixel = 0
				Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

				local fillGrad = Instance.new("UIGradient", fill)
				fillGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 34)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 48, 50)),
					ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 160, 165))
				})

				local knob = Instance.new("Frame", fill)
				knob.Size = UDim2.new(0, 14, 0, 14)
				knob.AnchorPoint = Vector2.new(0.5, 0.5)
				knob.Position = UDim2.new(1, 0, 0.5, 0)
				knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				knob.BackgroundTransparency = 0
				knob.BorderSizePixel = 0
				Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
				local knobStroke = Instance.new("UIStroke", knob)
				knobStroke.Color = Color3.fromRGB(160, 160, 165)
				knobStroke.Transparency = 0.35
				knobStroke.Thickness = 1.4

				local currentVal = default
				local function updateSliderVal(percent)
					percent = math.clamp(percent, 0, 1)
					local v = minVal + percent * (maxVal - minVal)
					v = math.floor(v * 10) / 10
					currentVal = v
					label.Text = name .. " (" .. tostring(currentVal) .. ")"
					tweenService:Create(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
					callback(v)
				end
				updateSliderVal((default - minVal) / (maxVal - minVal))
				local btn = Instance.new("TextButton", track)
				btn.Size = UDim2.new(1, 0, 2, 0)
				btn.Position = UDim2.new(0, 0, -0.5, 0)
				btn.BackgroundTransparency = 1
				btn.Text = ""
				btn.Active = true
				btn.ZIndex = 5
				local dragging = false
				local function updateFromInput(input)
					local offset = input.Position.X - track.AbsolutePosition.X
					updateSliderVal(offset / track.AbsoluteSize.X)
				end
				btn.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						tweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 0.45}):Play()
						tweenService:Create(knobStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.1, Thickness = 1.8}):Play()
						updateFromInput(input)
					end
				end)
				userInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						updateFromInput(input)
					end
				end)
				userInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						if dragging then
							dragging = false
							tweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0}):Play()
							tweenService:Create(knobStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.35, Thickness = 1.4}):Play()
						end
					end
				end)
			end
			_G._OnyxFaceBangSpeed = _G._OnyxFaceBangSpeed or 24
			_G._OnyxFaceBangDistance = _G._OnyxFaceBangDistance or 6
			_G._OnyxFaceBangHeight = _G._OnyxFaceBangHeight or 1
			createFacebangSlider("Speed", 0.1, 60, _G._OnyxFaceBangSpeed, function(v) _G._OnyxFaceBangSpeed = v end)
			createFacebangSlider("Distance", 1, 20, _G._OnyxFaceBangDistance, function(v) _G._OnyxFaceBangDistance = v end)
			local FBStartBtn = Instance.new("TextButton", FBContentFrame)
			FBStartBtn.Size = UDim2.new(1, 0, 0, 36)
			FBStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			FBStartBtn.TextSize = 12
			FBStartBtn.Font = Enum.Font.BuilderSansBold
			Instance.new("UICorner", FBStartBtn).CornerRadius = UDim.new(0, 8)
			local fbBtnBorder = Instance.new("Frame", FBStartBtn)
			fbBtnBorder.Name = "BorderFrame"
			fbBtnBorder.Size = UDim2.new(1, 0, 1, 0)
			fbBtnBorder.BackgroundTransparency = 1
			local fbBtnBorderCorner = Instance.new("UICorner", fbBtnBorder)
			fbBtnBorderCorner.CornerRadius = UDim.new(0, 8)
			local fbBtnStroke = Instance.new("UIStroke", fbBtnBorder)
			fbBtnStroke.Color = Color3.fromRGB(40, 40, 42)
			fbBtnStroke.Thickness = 0.99
			local function updateFBStatus()
				FBStartBtn.Text = FaceBangEnabled and "STOP FACEBANG" or "START (Z)"
				FBStartBtn.BackgroundColor3 = FaceBangEnabled and Color3.fromRGB(150, 40, 40) or Color3.fromRGB(20, 20, 20)
			end
			updateFBStatus()
			FBStartBtn.MouseButton1Click:Connect(function()
				if FaceBangEnabled then
					StopFaceBang()
				else
					local t = GetNearestPlayer()
					if t then StartFaceBang(t) end
				end
				updateFBStatus()
			end)
			userInputService.InputBegan:Connect(function(input, gp)
				if gp or userInputService:GetFocusedTextBox() then return end
				if input.KeyCode == Enum.KeyCode.Z and FacebangWindow.Visible then
					if FaceBangEnabled then
						StopFaceBang()
					else
						local t = GetNearestPlayer()
						if t then StartFaceBang(t) end
					end
					updateFBStatus()
				end
			end)
			makeDraggable(FacebangWindow, FacebangWindow)
		end
		initFacebang()
	end

Tempus = (function()
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
		if ok and h then return h end
	end
	if type(get_hidden_gui) == "function" then
		local ok, h = pcall(get_hidden_gui)
		if ok and h then return h end
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

local function protectGui(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif type(protectgui) == "function" then
			protectgui(gui)
		end
	end)
end

local ICON_URL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"
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
	if type(getcustomasset) == "function" then return getcustomasset end
	if type(getsynasset) == "function" then return getsynasset end
	if syn and type(syn.getcustomasset) == "function" then
		return function(p) return syn.getcustomasset(p) end
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
	if not getAsset or type(writefile) ~= "function" then return nil end
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
local TICK_FILE = "tempus_tick_v1.png"
local LOGO_FILE = "tempus_logo_v2.png"

local Theme = {
	Accent      = Color3.fromRGB(210, 210, 218),
	AccentDark  = Color3.fromRGB(20, 20, 23),
	HeaderFade  = Color3.fromRGB(12, 12, 14),
	WindowBg    = Color3.fromRGB(9,  9,  11),
	ChromeBg    = Color3.fromRGB(4,  4,  5),
	PanelBg     = Color3.fromRGB(15, 15, 17),
	ControlBg   = Color3.fromRGB(22, 22, 25),
	ControlBorder = Color3.fromRGB(42, 42, 46),
	Track       = Color3.fromRGB(26, 26, 29),
	TextWhite   = Color3.fromRGB(235, 235, 238),
	TextBright  = Color3.fromRGB(195, 195, 200),
	TextMid     = Color3.fromRGB(128, 128, 135),
	TextDim     = Color3.fromRGB(76,  76,  84),
	Check       = Color3.fromRGB(9,   9,   11),
	FillA       = Color3.fromRGB(200, 200, 210),
	FillB       = Color3.fromRGB(120, 120, 135),
}

local WIN_W = 600
local WIN_H = 550
local TOPBAR_H = 56
local FOOTER_H = 30
local MARGIN = 16
local COL_GAP = 14
local COL_W = math.floor((WIN_W - MARGIN * 2 - COL_GAP) / 2)
local HEAD_H = 26
local ROW_H = 26
local TEXT = 13

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function tween(obj, props, dur, style, dir)
	if not obj then return end
	local t = TweenService:Create(obj, TweenInfo.new(dur or 0.16, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function make(class, props, children)
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
	LPS_ATTRIBUTES(INLINE())
	if not keyCode then return "None" end
	local pretty = {
		LeftShift = "LShift", RightShift = "RShift",
		LeftControl = "LCtrl", RightControl = "RCtrl",
		LeftAlt = "LAlt", RightAlt = "RAlt",
		KeypadZero = "Num 0", KeypadOne = "Num 1", KeypadTwo = "Num 2",
		KeypadThree = "Num 3", KeypadFour = "Num 4", KeypadFive = "Num 5",
		KeypadSix = "Num 6", KeypadSeven = "Num 7", KeypadEight = "Num 8",
		KeypadNine = "Num 9",
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
			if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
			if not isfolder(CONFIG_FOLDER .. "/configs") then makefolder(CONFIG_FOLDER .. "/configs") end
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
				if g.Name == "SlateEspGui" then g:Destroy() end
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
			pcall(function() c:Disconnect() end)
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
		Position = UDim2.new(0, math.max(20, math.floor((vp.X - WIN_W) / 2)), 0, math.max(20, math.floor((vp.Y - WIN_H) / 2))),
		Size = UDim2.new(0, WIN_W, 0, WIN_H),
		BackgroundColor3 = Theme.WindowBg,
		BorderSizePixel = 0,
		Visible = false,
		Parent = screen,
	})
	corner(win, 8)
	stroke(win, Color3.fromRGB(36, 36, 40), 0.35)

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
		Text = "×",
		Font = FONT_BOLD,
		TextSize = 16,
		TextColor3 = Theme.TextDim,
		AutoButtonColor = false,
		ZIndex = 2,
		Parent = topbar,
	})
	corner(closeBtn, 4)
	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(38, 38, 42), TextColor3 = Theme.TextWhite }, 0.1)
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
				pcall(function() tw:Cancel() end)
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
		if activeTab == t then return end
		closeOverlay()
		switchGen = switchGen + 1
		local gen = switchGen
		local old = activeTab
		local oi, ni = 0, 0
		for i, tb in ipairs(tabs) do
			if tb == old then oi = i end
			if tb == t then ni = i end
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
		t.ActiveTweens[#t.ActiveTweens + 1] = tween(t.Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)

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
					if switchGen ~= gen or not t.ActiveTweens then return end
					for _, e in ipairs(entries) do
						t.ActiveTweens[#t.ActiveTweens + 1] = tween(e.inst, { [e.prop] = e.value }, 0.2, Enum.EasingStyle.Quad)
					end
				end)
			end
		end
		local loose = byGroup[t.Page]
		if loose then
			for _, e in ipairs(loose) do
				t.ActiveTweens[#t.ActiveTweens + 1] = tween(e.inst, { [e.prop] = e.value }, 0.18, Enum.EasingStyle.Quad)
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
		local _iconMap = { crosshair="⊕", eye="◎", circle="●", search="⊙", globe="◉", settings="⚙", grid="⊞", shield="◈", wrench="⚒" }
		local isImage = false
		local imageId = nil
		local iconChar = ""
		if topts.icon then
			local str = tostring(topts.icon)
			if string.match(str, "^%d+$") or string.find(str, "rbxassetid://") == 1 or string.find(str, "rbxthumb://") == 1 then
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
		navX = navX + (hasIcon and 20 or 0) + math.max(40, navLbl.TextBounds.X ~= 0 and navLbl.TextBounds.X or (#name * 7)) + 26

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
					if gr.Side == "left" then nl = nl + 1 else nr = nr + 1 end
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
			corner(box, 3)

			local head = make("Frame", {
				Name = "Head",
				Size = UDim2.new(1, 0, 0, HEAD_H),
				BackgroundColor3 = Theme.AccentDark,
				BorderSizePixel = 0,
				Parent = box,
			})
			corner(head, 3)
			make("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,    Color3.fromRGB(32, 32, 36)),
					ColorSequenceKeypoint.new(0.6,  Color3.fromRGB(22, 22, 25)),
					ColorSequenceKeypoint.new(1,    Color3.fromRGB(14, 14, 16)),
				}),
				Parent = head,
			})
			local stripesAsset = remoteImage(STRIPES_FILE)
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
			local headTitle = make("TextLabel", {
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

			local row = baseRow(22)
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, -60, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = o.text or "Toggle",
				TextSize = TEXT,
				TextColor3 = Theme.TextMid,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			registerSearch(o.text or "Toggle", row)

			local boxBtn = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 15, 0, 15),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(boxBtn, 3)
			local boxStroke = stroke(boxBtn, Theme.ControlBorder, 0)
			local check = make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 11, 0, 11),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.Check,
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = boxBtn,
			})
			applyIcon(check, resolveIcon("check"))

			local swatch
			if hasColor then
				swatch = make("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -21, 0.5, 0),
					Size = UDim2.new(0, 24, 0, 14),
					BackgroundColor3 = Color3.fromHSV(ch, cs, cv),
					BorderSizePixel = 0,
					Parent = row,
				})
				corner(swatch, 2)
				stroke(swatch, Theme.ControlBorder, 0.2)
			end

			local function paint()
				if state then
					tween(boxBtn, { BackgroundColor3 = Theme.Accent }, 0.14)
					tween(boxStroke, { Color = Theme.Accent }, 0.14)
					tween(check, { ImageTransparency = 0 }, 0.14)
					tween(lbl, { TextColor3 = Theme.TextBright }, 0.14)
				else
					tween(boxBtn, { BackgroundColor3 = Theme.ControlBg }, 0.14)
					tween(boxStroke, { Color = Theme.ControlBorder }, 0.14)
					tween(check, { ImageTransparency = 1 }, 0.14)
					tween(lbl, { TextColor3 = Theme.TextMid }, 0.14)
				end
			end
			paint()

			local function currentColor()
				return Color3.fromHSV(ch, cs, cv)
			end

			local function push(silent)
				if o.flag then Tempus.Flags[o.flag] = state end
				if hasColor and o.colorFlag then Tempus.Flags[o.colorFlag] = currentColor() end
				if not silent and o.callback then
					task.spawn(o.callback, state)
				end
			end

			local function set(v, silent)
				v = v and true or false
				if v == state then return end
				state = v
				paint()
				push(silent)
			end

			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if swatch then
						local x, y = input.Position.X, input.Position.Y
						local sp, ss = swatch.AbsolutePosition, swatch.AbsoluteSize
						if x >= sp.X and x <= sp.X + ss.X and y >= sp.Y and y <= sp.Y + ss.Y then
							return
						end
					end
					set(not state)
				end
			end)
			row.MouseEnter:Connect(function()
				if not state then
					tween(lbl, { TextColor3 = Theme.TextBright }, 0.1)
				end
			end)
			row.MouseLeave:Connect(function()
				if not state then
					tween(lbl, { TextColor3 = Theme.TextMid }, 0.1)
				end
			end)

			if swatch then
				swatch.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						openHuePopup(swatch, function() return ch end, function(h)
							ch, cs, cv = h, 1, 1
							swatch.BackgroundColor3 = currentColor()
							if o.colorFlag then Tempus.Flags[o.colorFlag] = currentColor() end
							if o.colorCallback then
								task.spawn(o.colorCallback, currentColor())
							end
						end)
					end
				end)
			end

			push(true)
			bindFlag(o.flag, function(v) set(v, false) end, function() return state end)
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
				Get = function() return state end,
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
				if o.flag then Tempus.Flags[o.flag] = key and key.Name or "None" end
			end

			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if keybindListenCancel then keybindListenCancel() end
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
				if listening and not processed and input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode ~= Enum.KeyCode.Escape then
						key = input.KeyCode
					else
						key = nil
					end
					keybindListenCancel = nil
					stopListening()
					task.defer(function() anyListening = false end)
					if o.flag then Tempus.Flags[o.flag] = key and key.Name or "None" end
					if o.changed then
						task.spawn(o.changed, key)
					end
					return
				end
				if processed or listening or anyListening then return end
				if key and input.KeyCode == key then
					if mode == "Hold" then
						held = true
						push(true)
					else
						push(true)
					end
				end
			end))
			trackConn(UserInputService.InputEnded:Connect(function(input)
				if mode == "Hold" and key and input.KeyCode == key and held then
					held = false
					push(false)
				end
			end))

			if o.flag then Tempus.Flags[o.flag] = key and key.Name or "None" end
			bindFlag(o.flag, function(v)
				if type(v) == "string" and v ~= "None" then
					local ok, kc = pcall(function() return Enum.KeyCode[v] end)
					applyKey(ok and kc or nil)
				else
					applyKey(nil)
				end
			end, function() return key and key.Name or "None" end)

			return {
				Row = row,
				Set = applyKey,
				Get = function() return key end,
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

			local row = baseRow(34)
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, -90, 0, 18),
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
				Size = UDim2.new(0, 86, 0, 18),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = "",
				TextSize = TEXT,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})

			local rail = make("Frame", {
				Position = UDim2.new(0, 0, 0, 20),
				Size = UDim2.new(1, 0, 0, 12),
				BackgroundColor3 = Theme.Track,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(rail, 2)
			local fill = make("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = rail,
			})
			fill.BackgroundColor3 = Theme.Accent
			corner(fill, 2)

			local function fmt(v)
				local s
				if decimals > 0 then
					s = string.format("%." .. decimals .. "f", v)
				else
					s = tostring(math.floor(v + 0.5))
				end
				return s .. (o.suffix or "")
			end

			local function paint()
				local alpha = (max > min) and (value - min) / (max - min) or 0
				valueLbl.Text = fmt(value)
				fill.Size = UDim2.new(alpha, 0, 1, 0)
			end

			local function set(v, silent)
				v = math.clamp(v, min, max)
				v = min + math.floor((v - min) / step + 0.5) * step
				v = math.clamp(v, min, max)
				if v == value then
					paint()
					return
				end
				value = v
				paint()
				if o.flag then Tempus.Flags[o.flag] = value end
				if not silent and o.callback then
					task.spawn(o.callback, value)
				end
			end

			local dragging = false
			local function fromX(x)
				local a = math.clamp((x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
				set(min + a * (max - min))
				fill.Size = UDim2.new(a, 0, 1, 0)
			end
			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					fromX(input.Position.X)
				end
			end)
			trackConn(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if dragging then
						dragging = false
						paint()
					end
				end
			end))
			trackConn(UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					fromX(input.Position.X)
				end
			end))

			paint()
			if o.flag then Tempus.Flags[o.flag] = value end
			bindFlag(o.flag, function(v) set(v, false) end, function() return value end)

			return {
				Row = row,
				Set = set,
				Get = function() return value end,
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
						if selectedSet[opt] then parts[#parts + 1] = opt end
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
				if o.flag then Tempus.Flags[o.flag] = current() end
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
					for _, x in ipairs(v) do selectedSet[x] = true end
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
						for _, x in ipairs(v) do selectedSet[x] = true end
					elseif not multi then
						selected = v
					end
					paintValue()
					push(false)
				end,
				Get = current,
				Refresh = function(newOptions)
					options = newOptions or options
					local changed = false
					if multi then
						local keep = {}
						for _, opt in ipairs(options) do
							if selectedSet[opt] then keep[opt] = true end
						end
						for opt in pairs(selectedSet) do
							if not keep[opt] then changed = true end
						end
						selectedSet = keep
					elseif selected ~= nil then
						local found = false
						for _, opt in ipairs(options) do
							if opt == selected then
								found = true
								break
							end
						end
						if not found then
							selected = options[1]
							changed = true
						end
					end
					paintValue()
					if changed then push(false) end
				end,
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
				if o.flag then Tempus.Flags[o.flag] = color() end
				if not silent and o.callback then
					task.spawn(o.callback, color())
				end
			end

			swatch.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					openHuePopup(swatch, function() return ch end, function(h)
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

		function group.Textbox(o)
			o = o or {}
			local row = baseRow(26)
			if o.text then
				make("TextLabel", {
					Size = UDim2.new(1, -130, 1, 0),
					BackgroundTransparency = 1,
					Font = FONT_MED,
					Text = o.text,
					TextSize = TEXT,
					TextColor3 = Theme.TextBright,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				registerSearch(o.text, row)
			end
			local boxW = o.text and 112 or 0
			local box = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = o.text and UDim2.new(0, boxW, 0, 22) or UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(box, 3)
			local boxStroke = stroke(box, Theme.ControlBorder, 0.3)
			local input = make("TextBox", {
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -12, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = o.default or "",
				PlaceholderText = o.placeholder or "",
				PlaceholderColor3 = Theme.TextDim,
				TextSize = 12,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Parent = box,
			})

			local function setText(t, silent)
				input.Text = tostring(t == nil and "" or t)
				if o.flag then Tempus.Flags[o.flag] = input.Text end
				if not silent and o.callback then
					task.spawn(o.callback, input.Text, false)
				end
			end

			input.Focused:Connect(function()
				tween(boxStroke, { Color = Theme.Accent, Transparency = 0.1 }, 0.1)
			end)
			input.FocusLost:Connect(function(enter)
				tween(boxStroke, { Color = Theme.ControlBorder, Transparency = 0.3 }, 0.12)
				if o.flag then Tempus.Flags[o.flag] = input.Text end
				if o.callback then
					task.spawn(o.callback, input.Text, enter)
				end
			end)

			if o.flag then Tempus.Flags[o.flag] = input.Text end
			bindFlag(o.flag, function(v) setText(v, false) end, function() return input.Text end)

			return {
				Row = row,
				Set = function(t) setText(t) end,
				Get = function() return input.Text end,
			}
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
				pcall(function() moveConn:Disconnect() end)
				pcall(function() upConn:Disconnect() end)
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
			if string.find(string.lower(e.text), q, 1, true) or string.find(string.lower(e.group.Name), q, 1, true) then
				hits[#hits + 1] = e
				if #hits >= 8 then break end
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
		if v == menuVisible then return end
		if os.clock() < fadeLock then return end
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
		if processed or anyListening then return end
		if menuKey and input.KeyCode == menuKey then
			self.ToggleMenu()
		end
	end))

	local function encodeValue(v)
		if typeof(v) == "Color3" then
			return { __color = { v.R, v.G, v.B } }
		end
		return v
	end

	local function decodeValue(v)
		if type(v) == "table" and v.__color then
			return Color3.new(v.__color[1], v.__color[2], v.__color[3])
		end
		return v
	end

	function self.SaveConfig(cfgName)
		if not canFile() or not HttpService then return false end
		cfgName = (cfgName == nil or cfgName == "") and "default" or tostring(cfgName)
		ensureFolder()
		local out = {}
		for flag, v in pairs(Tempus.Flags) do
			out[flag] = encodeValue(v)
		end
		local ok = pcall(function()
			writefile(CONFIG_FOLDER .. "/configs/" .. cfgName .. ".json", HttpService:JSONEncode(out))
		end)
		return ok
	end

	function self.LoadConfig(cfgName)
		if not canFile() or not HttpService then return false end
		cfgName = (cfgName == nil or cfgName == "") and "default" or tostring(cfgName)
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FOLDER .. "/configs/" .. cfgName .. ".json"))
		end)
		if not ok or type(data) ~= "table" then return false end
		for flag, v in pairs(data) do
			local entry = flagBinds[flag]
			if entry then
				pcall(entry.set, decodeValue(v))
			else
				Tempus.Flags[flag] = decodeValue(v)
			end
		end
		return true
	end

	function self.ListConfigs()
		local names = {}
		if type(listfiles) ~= "function" then return names end
		ensureFolder()
		pcall(function()
			for _, f in ipairs(listfiles(CONFIG_FOLDER .. "/configs")) do
				local n = string.match(f, "([^/\\]+)%.json$")
				if n then names[#names + 1] = n end
			end
		end)
		return names
	end

	self.Flags = Tempus.Flags
	self.Window = win

	return self
end

return Tempus
end)()

	do
		local function initEspMenu()

			EspConfig = {
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

			local hasDrawing = false
			pcall(function()
				local probe = Drawing.new("Line")
				probe:Remove()
				hasDrawing = true
			end)

			local tags, boxes, bars, skels, tracers = {}, {}, {}, {}, {}

			local SKELETON_R15 = {
				{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
				{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
				{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
				{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
				{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
			}
			local SKELETON_R6 = {
				{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
				{"Torso","Left Leg"},{"Torso","Right Leg"},
			}

			local function espAction()
				return siriusValues and siriusValues.actions and siriusValues.actions[7]
			end
			local function espOn()
				local a = espAction()
				return (a and a.enabled) == true
			end

			local function distanceTo(char)
				local myChar = localPlayer.Character
				local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not (myRoot and root) then return nil end
				return (root.Position - myRoot.Position).Magnitude
			end

			local function sameTeam(player)
				if not player.Team or not localPlayer.Team then return false end
				return player.Team == localPlayer.Team
			end

			local function colourFor(player)
				if EspConfig.teamColor and player.Team and player.TeamColor then
					return player.TeamColor.Color
				end
				return EspConfig.color
			end

			local function dropTag(n)   if tags[n]  then pcall(function() tags[n]:Destroy() end)  tags[n]  = nil end end
			local function dropBox(n)
				if boxes[n] then
					for _, ln in ipairs(boxes[n]) do pcall(function() ln:Remove() end) end
					boxes[n] = nil
				end
			end
			local function dropBar(n)   if bars[n]  then pcall(function() bars[n].gui:Destroy() end) bars[n] = nil end end
			local function dropSkel(n)
				if skels[n] then
					for _, ln in ipairs(skels[n]) do pcall(function() ln:Remove() end) end
					skels[n] = nil
				end
			end
			local function dropTracer(n)
				if tracers[n] then pcall(function() tracers[n]:Remove() end) tracers[n] = nil end
			end
			local function dropAll(n)
				dropTag(n) dropBox(n) dropBar(n) dropSkel(n) dropTracer(n)
			end

			local function updateTag(player, char, col)
				if not (EspConfig.names or EspConfig.distance) then dropTag(player.Name) return end
				local head = char and char:FindFirstChild("Head")
				if not head then dropTag(player.Name) return end

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
					if EspConfig.names then parts[#parts + 1] = player.DisplayName end
					if EspConfig.distance then
						local d = distanceTo(char)
						if d then parts[#parts + 1] = tostring(math.floor(d)) .. "m" end
					end
					lbl.Text = table.concat(parts, "  ")
					lbl.TextColor3 = col
				end
			end

			local function updateBar(player, char)
				if not EspConfig.health then dropBar(player.Name) return end
				local head = char and char:FindFirstChild("Head")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not (head and hum) then dropBar(player.Name) return end

				local rec = bars[player.Name]
				if not rec or not rec.gui.Parent then
					local gui = Instance.new("BillboardGui")
					gui.Name = "SlateEspHealth"
					gui.Size = UDim2.new(0, 4, 0, 46)
					gui.StudsOffset = Vector3.new(-2.4, 0.3, 0)
					gui.AlwaysOnTop = true
					gui.Parent = espContainer
					local bg = Instance.new("Frame", gui)
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
					rec = { gui = gui, fg = fg }
					bars[player.Name] = rec
				end
				rec.gui.Adornee = head
				local frac = 0
				if hum.MaxHealth > 0 then frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1) end
				rec.fg.Size = UDim2.new(1, 0, frac, 0)

				rec.fg.BackgroundColor3 = Color3.fromRGB(214, 64, 82):Lerp(Color3.fromRGB(104, 214, 122), frac)
			end

			local function newLine()
				local ln = Drawing.new("Line")
				ln.Thickness = 1
				ln.Transparency = 1
				return ln
			end

			local function hideBox(n)
				if boxes[n] then for _, ln in ipairs(boxes[n]) do ln.Visible = false end end
			end

			local function updateBox(player, char, col)
				if not (hasDrawing and EspConfig.box) then dropBox(player.Name) return end
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root then hideBox(player.Name) return end
				local head = char:FindFirstChild("Head")

				local cam = workspace.CurrentCamera

				local topWorld = (head and head.Position or root.Position) + Vector3.new(0, 1.5, 0)
				local botWorld = root.Position - Vector3.new(0, 3.2, 0)
				local top, tv = cam:WorldToViewportPoint(topWorld)
				local bot, bv = cam:WorldToViewportPoint(botWorld)
				if not (tv and bv) then hideBox(player.Name) return end

				local y1, y2 = math.min(top.Y, bot.Y), math.max(top.Y, bot.Y)
				local h = y2 - y1
				if h < 4 then hideBox(player.Name) return end
				local w = h * 0.62
				local cx = (top.X + bot.X) / 2
				local x1, x2 = cx - w / 2, cx + w / 2

				local seg = math.clamp(math.min(w, h) * 0.3, 3, 26)

				local set = boxes[player.Name]
				if not set or #set < 8 then
					dropBox(player.Name)
					set = {}
					for i = 1, 8 do set[i] = newLine() end
					boxes[player.Name] = set
				end

				local pts = {
					{ x1, y1, x1 + seg, y1 }, { x1, y1, x1, y1 + seg },
					{ x2, y1, x2 - seg, y1 }, { x2, y1, x2, y1 + seg },
					{ x1, y2, x1 + seg, y2 }, { x1, y2, x1, y2 - seg },
					{ x2, y2, x2 - seg, y2 }, { x2, y2, x2, y2 - seg },
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
				if skels[n] then for _, ln in ipairs(skels[n]) do ln.Visible = false end end
			end
			local function hideTracer(n)
				if tracers[n] then tracers[n].Visible = false end
			end

			local function updateSkeleton(player, char, col)
				if not (hasDrawing and EspConfig.skeleton) then dropSkel(player.Name) return end
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not hum then hideSkel(player.Name) return end

				local pairsList = (hum.RigType == Enum.HumanoidRigType.R15) and SKELETON_R15 or SKELETON_R6
				local set = skels[player.Name]
				if not set or #set < #pairsList then
					dropSkel(player.Name)
					set = {}
					for _ = 1, #pairsList do set[#set + 1] = newLine() end
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
				if not (hasDrawing and EspConfig.tracers) then dropTracer(player.Name) return end
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root then hideTracer(player.Name) return end

				local ln = tracers[player.Name]
				if not ln then ln = newLine() tracers[player.Name] = ln end

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
			EspRefresh = (function()
				local on = espOn()
				if not on and not espWasOn and next(locatedPlayers) == nil then return end
				espWasOn = on
				for _, player in ipairs(players:GetPlayers()) do
					if player ~= localPlayer then
						local name = player.Name
						local char = player.Character
						local hl = espContainer:FindFirstChild(name)

						local show = on
						if show and EspConfig.teamCheck and sameTeam(player) then show = false end
						if show and EspConfig.maxDistance > 0 then
							local d = distanceTo(char)
							if d and d > EspConfig.maxDistance then show = false end
						end

						if locatedPlayers[name] == true then show = true end

						local col = colourFor(player)

						if hl and hl:IsA("Highlight") then
							hl.Enabled = show
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
					for _, player in ipairs(players:GetPlayers()) do dropAll(player.Name) end
				end
			end)

			players.PlayerRemoving:Connect(function(p) dropAll(p.Name) end)

			task.spawn(function()
				while task.wait(0.35) do pcall(EspRefresh) end
			end)

			runService.RenderStepped:Connect((function()
				LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
				if not (hasDrawing and espOn()) then return end
				if not (EspConfig.box or EspConfig.skeleton or EspConfig.tracers) then return end
				for _, player in ipairs(players:GetPlayers()) do
					if player ~= localPlayer then
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
			end))

			AimConfig = {
				enabled        = false,
				mode           = "Hold",
				key            = Enum.UserInputType.MouseButton2,
				smoothing      = true,
				smoothAmount   = 0.18,
				smoothAmountX  = 0.18,
				smoothAmountY  = 0.18,
				perAxisSmooth  = false,
				fov            = 120,
				fovStyle       = "Circle",
				showFov        = true,
				fovFollow      = true,
				targetPart     = "Head",
				wallCheck      = true,
				sticky         = true,
				predict        = false,
				predictAmount  = 0.135,
				projectile     = 0,
				priority       = "Crosshair",
				maxTurn        = 0,
				rage           = false,
				aimDelay       = 0,
				silentAim      = false,
				triggerbot     = false,
				triggerbotDelay = 0.05,
				aimTeamCheck   = false,
				aimKnockedCheck = false,
				aimWeaponCheck  = false,
			}

			local guiService = game:GetService("GuiService")

			local PART_FALLBACK = {"HumanoidRootPart", "UpperTorso", "Torso", "Head"}

			local AIM_PARTS = {
				"Head", "UpperTorso", "HumanoidRootPart", "Torso",
				"LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
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

			local function keyName()
				local k = AimConfig.key
				if k == nil then return "None" end
				if isMouseKey(k) then
					local map = {MouseButton1 = "Mouse 1", MouseButton2 = "Mouse 2", MouseButton3 = "Mouse 3"}
					return map[k.Name] or k.Name
				end
				return k.Name
			end

			local function keyDown(k)
				if k == nil then return false end
				local ok, down = pcall(function()
					if isMouseKey(k) then return userInputService:IsMouseButtonPressed(k) end
					return userInputService:IsKeyDown(k)
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
					local m = userInputService:GetMouseLocation()
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
				if player == localPlayer then return false end
				local char = player.Character
				if not char then return false end
				local hum = char:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then return false end
				if AimConfig.aimTeamCheck and sameTeam(player) then return false end
				if AimConfig.aimKnockedCheck and hum.Health < hum.MaxHealth * 0.15 then return false end
				if AimConfig.aimWeaponCheck then
					local lc = localPlayer.Character
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

				local ignore = {char, cam}
				if localPlayer.Character then ignore[#ignore + 1] = localPlayer.Character end
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

				local names = AimConfig.targetPart == "Nearest" and AIM_PARTS or nil
				local candidates = {}

				if names then
					for _, n in ipairs(names) do
						local part, d = project(n)
						if part then candidates[#candidates + 1] = {part = part, dist = d} end
					end
					table.sort(candidates, function(a, b) return a.dist < b.dist end)
				else

					local part, d = project(AimConfig.targetPart)
					if part then candidates[#candidates + 1] = {part = part, dist = d} end
					for _, n in ipairs(PART_FALLBACK) do
						if n ~= AimConfig.targetPart then
							part, d = project(n)
							if part then candidates[#candidates + 1] = {part = part, dist = d} end
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
					if part and d <= radius then
						return lockedTarget, part
					end
				end

				local bestPlayer, bestPart, bestScore
				for _, player in ipairs(players:GetPlayers()) do
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

			userInputService.InputBegan:Connect(function(input, gp)
				if gp or userInputService:GetFocusedTextBox() then return end
				if AimConfig.mode == "Toggle" and inputMatches(input) then
					toggleActive = not toggleActive
					if not toggleActive then lockedTarget = nil end
				end
			end)

			local AIM_BIND = "SlateAimlock"
			local aimPriority = Enum.RenderPriority.Camera.Value + 1

			local _aimDelayUntil = 0
			local _triggerbotConn = nil

			local function doSilentAim(part)
				local cam = workspace.CurrentCamera
				if not (cam and part) then return end
				local aimPos = aimPointOf(part)
				local _, onScreen = cam:WorldToViewportPoint(aimPos)
				if not onScreen then return end
				pcall(function()
					local ray = cam:ScreenPointToRay(
						cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
					local dir = (aimPos - ray.Origin).Unit
					local fakeOrigin = aimPos - dir * ray.Direction.Magnitude
					userInputService:SetMouseRayOffset(fakeOrigin - ray.Origin)
				end)
			end

			local stepAim = (function(dt)
				updateFovCircle()
				if not aimActive() then
					lockedTarget = nil
					_aimDelayUntil = 0
					pcall(function() userInputService:SetMouseRayOffset(Vector3.new(0,0,0)) end)
					return
				end
				local cam = workspace.CurrentCamera
				if not cam then return end

				local target, part = pickTarget()
				if not (target and part) then
					_aimDelayUntil = 0
					pcall(function() userInputService:SetMouseRayOffset(Vector3.new(0,0,0)) end)
					return
				end

				if AimConfig.aimDelay > 0 then
					if _aimDelayUntil == 0 then
						_aimDelayUntil = tick() + AimConfig.aimDelay
					end
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
					local nowX = now:Lerp(goal, ax)
					local nowY = now:Lerp(goal, ay)
					local lv = Vector3.new(nowX.LookVector.X, nowY.LookVector.Y, nowX.LookVector.Z).Unit
					blended = CFrame.new(now.Position) * CFrame.fromMatrix(Vector3.new(), lv:Cross(now.RightVector), lv:Cross(now.RightVector):Cross(lv))
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
			end)

			local function startTriggerbot()
				if _triggerbotConn then _triggerbotConn:Disconnect() end
				_triggerbotConn = runService.Heartbeat:Connect(function()
					if not (AimConfig.enabled and AimConfig.triggerbot) then return end
					local target, _ = pickTarget()
					if not target then return end
					task.delay(AimConfig.triggerbotDelay, function()
						local uis = userInputService
						local inp = InputObject.new and InputObject.new() or nil
						pcall(function()
							uis:SendMouseButtonEvent(
								uis:GetMouseLocation().X,
								uis:GetMouseLocation().Y,
								0, true, game, 0)
							task.wait(0.05)
							uis:SendMouseButtonEvent(
								uis:GetMouseLocation().X,
								uis:GetMouseLocation().Y,
								0, false, game, 0)
						end)
					end)
				end)
			end
			startTriggerbot()

			pcall(function() runService:UnbindFromRenderStep(AIM_BIND) end)
			runService:BindToRenderStep(AIM_BIND, aimPriority, stepAim)

			local PANEL_W, PANEL_H = 598, 452
			local COL_W, COL_GAP, MARGIN, HEAD_H = 136, 10, 12, 50
			EspWindow = Instance.new("Frame", G2L["1"])
			EspWindow.Name = "EspMenu"
			EspWindow.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
			EspWindow.Position = UDim2.new(0.03, 0, 0.12, 0)
			EspWindow.BackgroundColor3 = Color3.fromRGB(11, 4, 20)
			EspWindow.BorderSizePixel = 0
			EspWindow.Visible = false
			Instance.new("UICorner", EspWindow).CornerRadius = UDim.new(0, 14)
			local espStroke = Instance.new("UIStroke", EspWindow)
			espStroke.Thickness = 0.99
			espStroke.Color = Color3.fromRGB(62, 34, 96)
			espStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			createSlateBackdrop(EspWindow, 14, { zIndex = 0, rotation = 28 })

			local espLogo = Instance.new("ImageLabel", EspWindow)
			espLogo.Size = UDim2.new(0, 20, 0, 20)
			espLogo.Position = UDim2.new(0, MARGIN, 0, 15)
			espLogo.Image = "rbxassetid://106790631609801"
			espLogo.BackgroundTransparency = 1
			espLogo.ScaleType = Enum.ScaleType.Fit
			espLogo.ZIndex = 2

			local espTitle = Instance.new("TextLabel", EspWindow)
			espTitle.Size = UDim2.new(0, 240, 0, 20)
			espTitle.Position = UDim2.new(0, MARGIN + 28, 0, 15)
			espTitle.BackgroundTransparency = 1
			espTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			espTitle.Text = "ESP & AIMLOCK"
			espTitle.TextSize = 13
			espTitle.Font = Enum.Font.BuilderSansBold
			espTitle.TextXAlignment = Enum.TextXAlignment.Left
			espTitle.ZIndex = 2

			local espClose = Instance.new("TextButton", EspWindow)
			espClose.Size = UDim2.new(0, 22, 0, 22)
			espClose.Position = UDim2.new(1, -32, 0, 14)
			espClose.BackgroundTransparency = 1
			espClose.Text = "×"
			espClose.TextColor3 = Color3.fromRGB(150, 140, 165)
			espClose.TextSize = 16
			espClose.Font = Enum.Font.BuilderSansBold
			espClose.ZIndex = 3
			espClose.MouseEnter:Connect(function() espClose.TextColor3 = Color3.fromRGB(255, 255, 255) end)
			espClose.MouseLeave:Connect(function() espClose.TextColor3 = Color3.fromRGB(150, 140, 165) end)
			espClose.MouseButton1Click:Connect(function() EspWindow.Visible = false end)

			local espRule = Instance.new("Frame", EspWindow)
			espRule.BorderSizePixel = 0
			espRule.BackgroundColor3 = Color3.fromRGB(62, 34, 96)
			espRule.BackgroundTransparency = 0.45
			espRule.Size = UDim2.new(1, -(MARGIN * 2), 0, 1)
			espRule.Position = UDim2.new(0, MARGIN, 0, 46)
			espRule.ZIndex = 2

			local body, order
			local rows = {}
			local colCount = 0

			local function newColumn(title)
				local x = MARGIN + colCount * (COL_W + COL_GAP)
				colCount = colCount + 1

				if colCount > 1 then
					local gutter = Instance.new("Frame", EspWindow)
					gutter.BorderSizePixel = 0
					gutter.BackgroundColor3 = Color3.fromRGB(62, 34, 96)
					gutter.BackgroundTransparency = 0.7
					gutter.Size = UDim2.new(0, 1, 1, -(HEAD_H + 20))
					gutter.Position = UDim2.new(0, x - (COL_GAP / 2), 0, HEAD_H + 4)
					gutter.ZIndex = 2
				end

				local col = Instance.new("ScrollingFrame", EspWindow)
				col.Name = title .. "Column"
				col.BackgroundTransparency = 1
				col.BorderSizePixel = 0
				col.ScrollBarThickness = 2
				col.ScrollBarImageColor3 = Color3.fromRGB(148, 40, 206)
				col.ScrollBarImageTransparency = 0.5
				col.AutomaticCanvasSize = Enum.AutomaticSize.Y
				col.CanvasSize = UDim2.new()
				col.Size = UDim2.new(0, COL_W, 1, -(HEAD_H + 14))
				col.Position = UDim2.new(0, x, 0, HEAD_H)
				col.ZIndex = 2
				local lay = Instance.new("UIListLayout", col)
				lay.Padding = UDim.new(0, 2)
				lay.SortOrder = Enum.SortOrder.LayoutOrder

				body, order = col, 0
				return col
			end

			local function addHeading(text)
				order = order + 1
				local h = Instance.new("TextLabel", body)
				h.LayoutOrder = order
				h.Size = UDim2.new(1, -8, 0, 20)
				h.BackgroundTransparency = 1
				h.Text = string.upper(text)
				h.TextColor3 = Color3.fromRGB(110, 110, 115)
				h.Font = Enum.Font.BuilderSansBold
				h.TextSize = 9
				h.TextXAlignment = Enum.TextXAlignment.Left
				h.ZIndex = 3
				local pad = Instance.new("UIPadding", h)
				pad.PaddingLeft = UDim.new(0, 6)
				pad.PaddingTop = UDim.new(0, 8)
			end

			local PILL_W, PILL_H, KNOB, PILL_PAD = 32, 18, 12, 3
			local function addToggle(text, get, set, disabled, note)
				order = order + 1
				local row = Instance.new("TextButton", body)
				row.LayoutOrder = order
				row.Size = UDim2.new(1, -8, 0, 26)
				row.BackgroundTransparency = 1
				row.Text = ""
				row.ZIndex = 3

				local lbl = Instance.new("TextLabel", row)
				lbl.Size = UDim2.new(1, -(PILL_W + 18), 1, 0)
				lbl.Position = UDim2.new(0, 6, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = text
				lbl.TextColor3 = Color3.fromRGB(198, 190, 216)
				lbl.Font = Enum.Font.BuilderSans
				lbl.TextSize = 11
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextTruncate = Enum.TextTruncate.AtEnd
				lbl.ZIndex = 4

				local pill = Instance.new("Frame", row)
				pill.AnchorPoint = Vector2.new(1, 0.5)
				pill.Size = UDim2.new(0, PILL_W, 0, PILL_H)
				pill.Position = UDim2.new(1, -6, 0.5, 0)
				pill.BackgroundColor3 = Color3.fromRGB(38, 24, 56)
				pill.BorderSizePixel = 0
				pill.ZIndex = 4
				Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

				local knob = Instance.new("Frame", pill)
				knob.AnchorPoint = Vector2.new(0.5, 0.5)
				knob.Size = UDim2.new(0, KNOB, 0, KNOB)
				knob.Position = UDim2.new(0, PILL_PAD + KNOB / 2, 0.5, 0)
				knob.BackgroundColor3 = Color3.fromRGB(128, 120, 146)
				knob.BorderSizePixel = 0
				knob.ZIndex = 5
				Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

				local off = UDim2.new(0, PILL_PAD + KNOB / 2, 0.5, 0)
				local on  = UDim2.new(0, PILL_W - PILL_PAD - KNOB / 2, 0.5, 0)

				local function paint()
					local isOn = get() and true or false
					local dim = disabled and disabled()
					tweenService:Create(pill, TweenInfo.new(0.15), {
						BackgroundColor3 = (isOn and not dim) and Color3.fromRGB(148, 40, 206)
							or Color3.fromRGB(38, 24, 56)
					}):Play()
					tweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = isOn and on or off,
						BackgroundColor3 = (isOn and not dim) and Color3.fromRGB(255, 255, 255)
							or Color3.fromRGB(128, 120, 146),
					}):Play()
					lbl.TextColor3 = dim and Color3.fromRGB(104, 96, 122)
						or (isOn and Color3.fromRGB(236, 230, 246) or Color3.fromRGB(158, 150, 178))
					lbl.Text = (dim and note) and (text .. "  ·  " .. note) or text
				end

				row.MouseButton1Click:Connect(function()
					if disabled and disabled() then return end
					set(not get())
					paint()
					pcall(EspRefresh)
				end)

				rows[#rows + 1] = paint
				paint()
			end

			local function addSlider(text, minV, maxV, get, set, fmt)
				order = order + 1
				local wrap = Instance.new("Frame", body)
				wrap.LayoutOrder = order
				wrap.Size = UDim2.new(1, -8, 0, 38)
				wrap.BackgroundTransparency = 1
				wrap.ZIndex = 3

				local lbl = Instance.new("TextLabel", wrap)
				lbl.Size = UDim2.new(1, -62, 0, 16)
				lbl.Position = UDim2.new(0, 6, 0, 3)
				lbl.BackgroundTransparency = 1
				lbl.Text = text
				lbl.TextColor3 = Color3.fromRGB(160, 160, 165)
				lbl.Font = Enum.Font.BuilderSans
				lbl.TextSize = 11.5
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 4

				local val = Instance.new("TextLabel", wrap)
				val.Size = UDim2.new(0, 50, 0, 16)
				val.Position = UDim2.new(1, -56, 0, 3)
				val.BackgroundTransparency = 1
				val.TextColor3 = Color3.fromRGB(224, 200, 255)
				val.Font = Enum.Font.BuilderSansBold
				val.TextSize = 11.5
				val.TextXAlignment = Enum.TextXAlignment.Right
				val.Text = fmt(get())
				val.ZIndex = 4

				local track = Instance.new("Frame", wrap)

				track.Size = UDim2.new(1, -16, 0, 8)
				track.Position = UDim2.new(0, 8, 0, 23)
				track.BackgroundColor3 = Color3.fromRGB(26, 18, 40)
				track.BorderSizePixel = 0
				track.ZIndex = 4
				Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

				local fill = Instance.new("Frame", track)
				fill.Size = UDim2.new((get() - minV) / (maxV - minV), 0, 1, 0)
				fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				fill.BorderSizePixel = 0
				fill.ZIndex = 5
				Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

				local grad = Instance.new("UIGradient", fill)
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.0, Color3.fromRGB(84, 24, 126)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(148, 40, 206)),
					ColorSequenceKeypoint.new(1.0, Color3.fromRGB(206, 140, 248))
				})

				local knob = Instance.new("Frame", fill)
				knob.Size = UDim2.new(0, 12, 0, 12)
				knob.AnchorPoint = Vector2.new(0.5, 0.5)
				knob.Position = UDim2.new(1, 0, 0.5, 0)
				knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				knob.BorderSizePixel = 0
				knob.ZIndex = 6
				Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
				local kStroke = Instance.new("UIStroke", knob)
				kStroke.Color = Color3.fromRGB(206, 140, 248)
				kStroke.Transparency = 0.35
				kStroke.Thickness = 1.4

				local hit = Instance.new("TextButton", track)
				hit.Size = UDim2.new(1, 0, 4, 0)
				hit.Position = UDim2.new(0, 0, -1.5, 0)
				hit.BackgroundTransparency = 1
				hit.Text = ""
				hit.ZIndex = 7

				local dragging = false
				local function apply(input)
					local frac = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
					local v = minV + frac * (maxV - minV)
					set(v)
					fill.Size = UDim2.new(frac, 0, 1, 0)
					val.Text = fmt(v)
					pcall(EspRefresh)
				end
				hit.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						tweenService:Create(knob, TweenInfo.new(0.18), {Size = UDim2.new(0, 15, 0, 15)}):Play()
						tweenService:Create(kStroke, TweenInfo.new(0.18), {Transparency = 0.1, Thickness = 1.8}):Play()
						apply(input)
					end
				end)
				userInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						apply(input)
					end
				end)
				userInputService.InputEnded:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
						dragging = false
						tweenService:Create(knob, TweenInfo.new(0.18), {Size = UDim2.new(0, 12, 0, 12)}):Play()
						tweenService:Create(kStroke, TweenInfo.new(0.18), {Transparency = 0.35, Thickness = 1.4}):Play()
					end
				end)
			end

			local noDrawing = function() return not hasDrawing end

			newColumn("ESP")
			addHeading("ESP")
			addToggle("Enabled", espOn, function(v)
				local a = espAction()
				if a then a.enabled = v pcall(a.callback, v) end
			end)

			addHeading("Highlight")
			addToggle("Fill", function() return EspConfig.fill end, function(v) EspConfig.fill = v end)
			addToggle("Outline", function() return EspConfig.outline end, function(v) EspConfig.outline = v end)
			addToggle("Corner box", function() return EspConfig.box end,
				function(v) EspConfig.box = v end, noDrawing, "unsupported")
			addSlider("Opacity", 0, 1,
				function() return 1 - EspConfig.fillTransparency end,
				function(v) EspConfig.fillTransparency = 1 - v end,
				function(v) return tostring(math.floor(v * 100 + 0.5)) .. "%" end)

			addHeading("Overlay")
			addToggle("Names", function() return EspConfig.names end, function(v) EspConfig.names = v end)
			addToggle("Distance", function() return EspConfig.distance end, function(v) EspConfig.distance = v end)
			addToggle("Health bar", function() return EspConfig.health end, function(v) EspConfig.health = v end)
			addToggle("Skeleton", function() return EspConfig.skeleton end,
				function(v) EspConfig.skeleton = v end, noDrawing, "unsupported")
			addToggle("Tracers", function() return EspConfig.tracers end,
				function(v) EspConfig.tracers = v end, noDrawing, "unsupported")

			newColumn("Filters")
			addHeading("Filters")
			addToggle("Team check", function() return EspConfig.teamCheck end, function(v) EspConfig.teamCheck = v end)
			addToggle("Team colours", function() return EspConfig.teamColor end, function(v) EspConfig.teamColor = v end)
			addSlider("Max dist", 0, 2000,
				function() return EspConfig.maxDistance end,
				function(v) EspConfig.maxDistance = math.floor(v) end,
				function(v) return v < 1 and "Unlimited" or (tostring(math.floor(v)) .. "m") end)

			local function addChoice(text, options, get, set)
				order = order + 1
				local wrap = Instance.new("Frame", body)
				wrap.LayoutOrder = order
				wrap.Size = UDim2.new(1, -8, 0, 40)
				wrap.BackgroundTransparency = 1
				wrap.ZIndex = 3

				local lbl = Instance.new("TextLabel", wrap)
				lbl.Size = UDim2.new(1, -12, 0, 16)
				lbl.Position = UDim2.new(0, 6, 0, 3)
				lbl.BackgroundTransparency = 1
				lbl.Text = text
				lbl.TextColor3 = Color3.fromRGB(160, 160, 165)
				lbl.Font = Enum.Font.BuilderSans
				lbl.TextSize = 11.5
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 4

				local strip = Instance.new("Frame", wrap)
				strip.Size = UDim2.new(1, -12, 0, 22)
				strip.Position = UDim2.new(0, 6, 0, 22)
				strip.BackgroundColor3 = Color3.fromRGB(26, 18, 40)
				strip.BorderSizePixel = 0
				strip.ZIndex = 4
				Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 6)
				local grid = Instance.new("UIListLayout", strip)
				grid.FillDirection = Enum.FillDirection.Horizontal
				grid.SortOrder = Enum.SortOrder.LayoutOrder
				grid.Padding = UDim.new(0, 0)

				local buttons = {}
				local function repaint()
					local cur = get()
					for opt, btn in pairs(buttons) do
						local on = opt == cur
						btn.BackgroundTransparency = on and 0 or 1
						btn.BackgroundColor3 = Color3.fromRGB(148, 40, 206)
						btn.TextColor3 = on and Color3.fromRGB(255, 255, 255)
							or Color3.fromRGB(150, 142, 172)
					end
				end

				for i, opt in ipairs(options) do
					local btn = Instance.new("TextButton", strip)
					btn.LayoutOrder = i
					btn.Size = UDim2.new(1 / #options, 0, 1, 0)
					btn.BorderSizePixel = 0
					btn.BackgroundTransparency = 1
					btn.Text = opt
					btn.Font = Enum.Font.BuilderSansBold
					btn.TextSize = 9.5
					btn.ZIndex = 5
					Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
					btn.MouseButton1Click:Connect(function()
						set(opt)
						repaint()
					end)
					buttons[opt] = btn
				end

				rows[#rows + 1] = repaint
				repaint()
			end

			local capturing = nil
			local function addKeybind(text, get, set)
				order = order + 1
				local row = Instance.new("Frame", body)
				row.LayoutOrder = order
				row.Size = UDim2.new(1, -8, 0, 26)
				row.BackgroundTransparency = 1
				row.ZIndex = 3

				local lbl = Instance.new("TextLabel", row)
				lbl.Size = UDim2.new(1, -86, 1, 0)
				lbl.Position = UDim2.new(0, 6, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = text
				lbl.TextColor3 = Color3.fromRGB(198, 190, 216)
				lbl.Font = Enum.Font.BuilderSans
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 4

				local btn = Instance.new("TextButton", row)
				btn.AnchorPoint = Vector2.new(1, 0.5)
				btn.Size = UDim2.new(0, 72, 0, 22)
				btn.Position = UDim2.new(1, -6, 0.5, 0)
				btn.BackgroundColor3 = Color3.fromRGB(38, 24, 56)
				btn.BorderSizePixel = 0
				btn.Font = Enum.Font.BuilderSansBold
				btn.TextSize = 10.5
				btn.TextColor3 = Color3.fromRGB(224, 200, 255)
				btn.TextStrokeTransparency = 1
				btn.AutoButtonColor = false
				btn.ZIndex = 4
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

				local function repaint()
					btn.Text = (capturing == btn) and "Press a key…" or get()
					btn.BackgroundColor3 = (capturing == btn) and Color3.fromRGB(148, 40, 206)
						or Color3.fromRGB(38, 24, 56)
				end

				btn.MouseButton1Click:Connect(function()
					if capturing == btn then
						capturing = nil
					elseif get() ~= "None" then
						set(nil)
						capturing = nil
					else
						capturing = btn
					end
					repaint()
				end)

				userInputService.InputBegan:Connect(function(input, gp)
					if capturing ~= btn then return end

					if input.UserInputType == Enum.UserInputType.MouseButton1 then return end
					if input.KeyCode == Enum.KeyCode.Escape then
						set(nil)
					elseif input.UserInputType == Enum.UserInputType.MouseButton2
						or input.UserInputType == Enum.UserInputType.MouseButton3 then
						set(input.UserInputType)
					elseif input.KeyCode ~= Enum.KeyCode.Unknown then
						set(input.KeyCode)
					else
						return
					end
					capturing = nil
					repaint()
				end)

				rows[#rows + 1] = repaint
				repaint()
			end

			local rageOn = function() return AimConfig.rage end

			addHeading("Aimlock")
			addToggle("Enabled", function() return AimConfig.enabled end,
				function(v) AimConfig.enabled = v if not v then toggleActive = false end end)
			addChoice("Activation", {"Hold", "Toggle", "Always"},
				function() return AimConfig.mode end,
				function(v) AimConfig.mode = v toggleActive = false end)
			addKeybind("Aim key", keyName, function(k) AimConfig.key = k toggleActive = false end)
			addChoice("Target part", {"Head", "Root", "Nearest"},
				function() return AimConfig.targetPart == "HumanoidRootPart" and "Root" or AimConfig.targetPart end,
				function(v) AimConfig.targetPart = (v == "Root") and "HumanoidRootPart" or v end)

			newColumn("Soft aim")
			addHeading("Soft aim")
			addToggle("Smoothing", function() return AimConfig.smoothing end,
				function(v) AimConfig.smoothing = v end, rageOn, "rage overrides")
			addSlider("Speed", 0.02, 1,
				function() return AimConfig.smoothAmount end,
				function(v) AimConfig.smoothAmount = v end,
				function(v) return string.format("%.2f", v) end)
			addSlider("FOV radius", 20, 600,
				function() return AimConfig.fov end,
				function(v) AimConfig.fov = math.floor(v) end,
				function(v) return tostring(math.floor(v)) .. "px" end)
			addToggle("FOV circle", function() return AimConfig.showFov end,
				function(v) AimConfig.showFov = v end, noDrawing, "unsupported")
			addToggle("Follow cursor", function() return AimConfig.fovFollow end,
				function(v) AimConfig.fovFollow = v end)

			addHeading("Behaviour")
			addToggle("Wall check", function() return AimConfig.wallCheck end,
				function(v) AimConfig.wallCheck = v end, rageOn, "rage overrides")
			addToggle("Sticky target", function() return AimConfig.sticky end,
				function(v) AimConfig.sticky = v end)
			addToggle("Prediction", function() return AimConfig.predict end,
				function(v) AimConfig.predict = v end)
			addSlider("Strength", 0, 0.5,
				function() return AimConfig.predictAmount end,
				function(v) AimConfig.predictAmount = v end,
				function(v) return string.format("%.3f", v) end)

			addHeading("Rage")
			addToggle("Rage aimbot", rageOn,
				function(v) AimConfig.rage = v end, nil, nil)

			local CONFIG_DIR = "slate/espconfigs"
			local hasFiles = (writefile and readfile and isfile and isfolder and makefolder) and true or false

			local function ensureConfigDir()
				if not hasFiles then return false end
				local ok = pcall(function()
					if not isfolder("slate") then makefolder("slate") end
					if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
				end)
				return ok
			end

			local function encodeConfig()
				local esp, aim = {}, {}
				for k, v in pairs(EspConfig) do
					if typeof(v) == "Color3" then
						esp[k] = {__c3 = true, r = v.R, g = v.G, b = v.B}
					else
						esp[k] = v
					end
				end
				for k, v in pairs(AimConfig) do
					if typeof(v) == "EnumItem" then
						aim[k] = {__key = true, mouse = (v.EnumType == Enum.UserInputType), name = v.Name}
					else
						aim[k] = v
					end
				end
				return httpService:JSONEncode({esp = esp, aim = aim})
			end

			local function decodeInto(target, saved)
				if type(saved) ~= "table" then return end
				for k, v in pairs(saved) do
					if target[k] ~= nil or type(v) ~= "table" then
						if type(v) == "table" and v.__c3 then
							target[k] = Color3.new(v.r or 0, v.g or 0, v.b or 0)
						elseif type(v) == "table" and v.__key then
							local ok, item = pcall(function()
								return v.mouse and Enum.UserInputType[v.name] or Enum.KeyCode[v.name]
							end)
							target[k] = ok and item or nil
						else
							target[k] = v
						end
					end
				end
			end

			local function listConfigs()
				if not hasFiles or not listfiles then return {} end
				local out = {}
				pcall(function()
					if not isfolder(CONFIG_DIR) then return end
					for _, full in ipairs(listfiles(CONFIG_DIR)) do
						local name = tostring(full):match("([^/\\]+)%.json$")
						if name then out[#out + 1] = name end
					end
				end)
				table.sort(out)
				return out
			end

			local function saveConfig(name)
				if not ensureConfigDir() then
					queueNotification("Configs", "This executor has no file system.")
					return false
				end
				name = tostring(name or ""):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
				if name == "" then
					queueNotification("Configs", "Give the config a name first.")
					return false
				end
				local ok = pcall(writefile, CONFIG_DIR .. "/" .. name .. ".json", encodeConfig())
				queueNotification("Configs", ok and ("Saved '" .. name .. "'") or "Save failed.")
				return ok
			end

			local function loadConfig(name)
				if not hasFiles then return false end
				local path = CONFIG_DIR .. "/" .. name .. ".json"
				local ok, body = pcall(readfile, path)
				if not ok or not body then
					queueNotification("Configs", "Could not read '" .. name .. "'")
					return false
				end
				local decoded, data = pcall(function() return httpService:JSONDecode(body) end)
				if not decoded or type(data) ~= "table" then
					queueNotification("Configs", "'" .. name .. "' is not valid JSON.")
					return false
				end
				decodeInto(EspConfig, data.esp)
				decodeInto(AimConfig, data.aim)

				for _, paint in ipairs(rows) do pcall(paint) end
				pcall(EspRefresh)
				queueNotification("Configs", "Loaded '" .. name .. "'")
				return true
			end

			local function deleteConfig(name)

				local remove = delfile or deletefile
				if not hasFiles or not remove then return false end
				local ok = pcall(remove, CONFIG_DIR .. "/" .. name .. ".json")
				queueNotification("Configs", ok and ("Deleted '" .. name .. "'") or "Delete failed.")
				return ok
			end

			newColumn("Targeting")
			addHeading("Targeting")
			addChoice("Priority", {"Crosshair", "Distance", "Health"},
				function() return AimConfig.priority end,
				function(v) AimConfig.priority = v end)
			addSlider("Projectile", 0, 1500,
				function() return AimConfig.projectile end,
				function(v) AimConfig.projectile = math.floor(v) end,
				function(v) return v < 1 and "Hitscan" or (tostring(math.floor(v)) .. " s/s") end)
			addSlider("Max turn", 0, 1440,
				function() return AimConfig.maxTurn end,
				function(v) AimConfig.maxTurn = math.floor(v) end,
				function(v) return v < 1 and "Uncapped" or (tostring(math.floor(v)) .. "d/s") end)

			addHeading("Configs")

			local cfgName
			do
				order = order + 1
				local wrap = Instance.new("Frame", body)
				wrap.LayoutOrder = order
				wrap.Size = UDim2.new(1, -8, 0, 30)
				wrap.BackgroundTransparency = 1
				wrap.ZIndex = 3

				cfgName = Instance.new("TextBox", wrap)
				cfgName.Size = UDim2.new(1, -12, 0, 26)
				cfgName.Position = UDim2.new(0, 6, 0, 2)
				cfgName.BackgroundColor3 = Color3.fromRGB(26, 18, 40)
				cfgName.BorderSizePixel = 0
				cfgName.Text = ""
				cfgName.PlaceholderText = "config name"
				cfgName.PlaceholderColor3 = Color3.fromRGB(104, 96, 122)
				cfgName.TextColor3 = Color3.fromRGB(236, 230, 246)
				cfgName.Font = Enum.Font.BuilderSans
				cfgName.TextSize = 11.5
				cfgName.TextXAlignment = Enum.TextXAlignment.Left
				cfgName.ClearTextOnFocus = false
				cfgName.ZIndex = 4
				Instance.new("UICorner", cfgName).CornerRadius = UDim.new(0, 6)
				Instance.new("UIPadding", cfgName).PaddingLeft = UDim.new(0, 8)
			end

			local renderConfigList

			local function addCfgButton(text, onClick)
				order = order + 1

				local wrap = Instance.new("Frame", body)
				wrap.LayoutOrder = order
				wrap.Size = UDim2.new(1, -8, 0, 30)
				wrap.BackgroundTransparency = 1
				wrap.ZIndex = 3

				local btn = Instance.new("TextButton", wrap)
				btn.Size = UDim2.new(1, -12, 0, 26)
				btn.Position = UDim2.new(0, 6, 0, 2)
				btn.BackgroundColor3 = Color3.fromRGB(148, 40, 206)
				btn.BackgroundTransparency = 0.15
				btn.BorderSizePixel = 0
				btn.Text = text
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.Font = Enum.Font.BuilderSansBold
				btn.TextSize = 11
				btn.AutoButtonColor = false
				btn.ZIndex = 4
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
				btn.MouseEnter:Connect(function()
					tweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play()
				end)
				btn.MouseLeave:Connect(function()
					tweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0.15}):Play()
				end)
				btn.MouseButton1Click:Connect(onClick)
				return btn
			end

			addCfgButton("Save current", function()
				if saveConfig(cfgName.Text) then
					cfgName.Text = ""
					renderConfigList()
				end
			end)

			addHeading("Saved")
			order = order + 1
			local cfgList = Instance.new("Frame", body)
			cfgList.Name = "ConfigList"
			cfgList.LayoutOrder = order
			cfgList.Size = UDim2.new(1, -8, 0, 0)
			cfgList.AutomaticSize = Enum.AutomaticSize.Y
			cfgList.BackgroundTransparency = 1
			cfgList.ZIndex = 3
			local cfgLayout = Instance.new("UIListLayout", cfgList)
			cfgLayout.Padding = UDim.new(0, 3)
			cfgLayout.SortOrder = Enum.SortOrder.LayoutOrder

			local cfgPad = Instance.new("UIPadding", cfgList)
			cfgPad.PaddingLeft = UDim.new(0, 6)

			renderConfigList = function()
				for _, ch in ipairs(cfgList:GetChildren()) do
					if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
				end
				local names = listConfigs()
				if #names == 0 then
					local empty = Instance.new("TextLabel", cfgList)
					empty.Size = UDim2.new(1, -6, 0, 22)
					empty.BackgroundTransparency = 1
					empty.Text = hasFiles and "No configs yet." or "No file system."
					empty.TextColor3 = Color3.fromRGB(104, 96, 122)
					empty.Font = Enum.Font.BuilderSans
					empty.TextSize = 11
					empty.TextXAlignment = Enum.TextXAlignment.Left
					empty.ZIndex = 4
					return
				end
				for i, name in ipairs(names) do
					local rowF = Instance.new("Frame", cfgList)
					rowF.LayoutOrder = i
					rowF.Size = UDim2.new(1, -6, 0, 26)
					rowF.BackgroundColor3 = Color3.fromRGB(26, 18, 40)
					rowF.BorderSizePixel = 0
					rowF.ZIndex = 4
					Instance.new("UICorner", rowF).CornerRadius = UDim.new(0, 6)

					local hit = Instance.new("TextButton", rowF)
					hit.Size = UDim2.new(1, -26, 1, 0)
					hit.BackgroundTransparency = 1
					hit.Text = name
					hit.TextColor3 = Color3.fromRGB(198, 190, 216)
					hit.Font = Enum.Font.BuilderSans
					hit.TextSize = 11
					hit.TextXAlignment = Enum.TextXAlignment.Left
					hit.TextTruncate = Enum.TextTruncate.AtEnd
					hit.ZIndex = 5
					Instance.new("UIPadding", hit).PaddingLeft = UDim.new(0, 8)
					hit.MouseEnter:Connect(function() hit.TextColor3 = Color3.fromRGB(255, 255, 255) end)
					hit.MouseLeave:Connect(function() hit.TextColor3 = Color3.fromRGB(198, 190, 216) end)
					hit.MouseButton1Click:Connect(function() loadConfig(name) end)

					local del = Instance.new("TextButton", rowF)
					del.Size = UDim2.new(0, 22, 1, 0)
					del.Position = UDim2.new(1, -24, 0, 0)
					del.BackgroundTransparency = 1
					del.Text = "×"
					del.TextColor3 = Color3.fromRGB(130, 100, 120)
					del.Font = Enum.Font.BuilderSansBold
					del.TextSize = 14
					del.ZIndex = 5
					del.MouseEnter:Connect(function() del.TextColor3 = Color3.fromRGB(230, 90, 110) end)
					del.MouseLeave:Connect(function() del.TextColor3 = Color3.fromRGB(130, 100, 120) end)
					del.MouseButton1Click:Connect(function()
						if deleteConfig(name) then renderConfigList() end
					end)
				end
			end
			renderConfigList()

			local ORB = 52
			local ORB_SLOP = 6

			local espOrb = Instance.new("Frame", G2L["1"])
			espOrb.Name = "EspOrb"
			espOrb.Size = UDim2.new(0, ORB, 0, ORB)
			espOrb.Position = UDim2.new(0.03, 0, 0.12, 0)
			espOrb.BackgroundColor3 = Color3.fromRGB(11, 4, 20)
			espOrb.BorderSizePixel = 0
			espOrb.Visible = false
			espOrb.ZIndex = 6
			espOrb.Active = true
			Instance.new("UICorner", espOrb).CornerRadius = UDim.new(1, 0)
			local orbStroke = Instance.new("UIStroke", espOrb)
			orbStroke.Thickness = 0.99
			orbStroke.Color = Color3.fromRGB(40, 40, 42)
			orbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			createSlateBackdrop(espOrb, ORB / 2, { zIndex = 0, rotation = 28 })

			local orbIcon = Instance.new("ImageLabel", espOrb)
			orbIcon.Name = "Icon"
			orbIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			orbIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			orbIcon.Size = UDim2.new(0, 30, 0, 30)
			orbIcon.BackgroundTransparency = 1
			orbIcon.ScaleType = Enum.ScaleType.Fit

			orbIcon.Image = "rbxthumb://type=Asset&id=126439761728978&w=420&h=420"
			orbIcon.ZIndex = 7

			local function toOffset(pos)
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
				return UDim2.new(0, pos.X.Scale * vp.X + pos.X.Offset,
				                 0, pos.Y.Scale * vp.Y + pos.Y.Offset)
			end

			local function clampToViewport(pos, w, h)
				local cam = workspace.CurrentCamera
				local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
				local flat = toOffset(pos)
				return UDim2.new(0, math.clamp(flat.X.Offset, 0, math.max(0, vp.X - w)),
				                 0, math.clamp(flat.Y.Offset, 0, math.max(0, vp.Y - h)))
			end

			local function espMinimise()

				espOrb.Position = clampToViewport(EspWindow.Position, ORB, ORB)
				EspWindow.Visible = false
				espOrb.Visible = true
			end

			local function espRestore()
				EspWindow.Position = clampToViewport(espOrb.Position, PANEL_W, PANEL_H)
				espOrb.Visible = false
				EspWindow.Visible = true
			end

			_G.SlateEspRestore = espRestore
			_G.SlateEspIsMinimised = function() return espOrb.Visible end

			local orbDragging, orbMoved = false, false
			local orbGrab, orbFrom

			espOrb.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch then return end
				orbDragging, orbMoved = true, false
				orbGrab = input.Position
				orbFrom = toOffset(espOrb.Position)
			end)

			userInputService.InputChanged:Connect(function(input)
				if not orbDragging then return end
				if input.UserInputType ~= Enum.UserInputType.MouseMovement
					and input.UserInputType ~= Enum.UserInputType.Touch then return end
				local dx, dy = input.Position.X - orbGrab.X, input.Position.Y - orbGrab.Y
				if not orbMoved and (math.abs(dx) > ORB_SLOP or math.abs(dy) > ORB_SLOP) then
					orbMoved = true
				end
				if orbMoved then
					espOrb.Position = clampToViewport(
						UDim2.new(0, orbFrom.X.Offset + dx, 0, orbFrom.Y.Offset + dy), ORB, ORB)
				end
			end)

			userInputService.InputEnded:Connect(function(input)
				if not orbDragging then return end
				if input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch then return end
				orbDragging = false

				if not orbMoved then espRestore() end
			end)

			espOrb.MouseEnter:Connect(function()
				tweenService:Create(orbStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(148, 40, 206)}):Play()
			end)
			espOrb.MouseLeave:Connect(function()
				tweenService:Create(orbStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(62, 34, 96)}):Play()
			end)

			local espMin = Instance.new("TextButton", EspWindow)
			espMin.Name = "MinimiseButton"
			espMin.Size = UDim2.new(0, 22, 0, 22)
			espMin.Position = UDim2.new(1, -58, 0, 14)
			espMin.BackgroundTransparency = 1
			espMin.Text = "–"
			espMin.TextColor3 = Color3.fromRGB(150, 140, 165)
			espMin.TextSize = 16
			espMin.Font = Enum.Font.BuilderSansBold
			espMin.ZIndex = 3
			espMin.MouseEnter:Connect(function() espMin.TextColor3 = Color3.fromRGB(255, 255, 255) end)
			espMin.MouseLeave:Connect(function() espMin.TextColor3 = Color3.fromRGB(150, 140, 165) end)
			espMin.MouseButton1Click:Connect(espMinimise)

			makeDraggable(EspWindow, EspWindow)

			task.spawn(function()
				while task.wait(0.5) do
					if EspWindow.Visible then
						for _, paint in ipairs(rows) do pcall(paint) end
					end
				end
			end)
		end
		initEspMenu()
	end

	do
		local function _init_block_9891()
		SettingsTab = createTabFrame("SettingsTab")
		SettingsTitle = addLabel(SettingsTab, "Settings & Config", UDim2.new(0, 300, 0, 32), UDim2.new(0.03, 0, 0.05, 0), true)
		SettingsBackBtn = Instance.new("ImageButton", SettingsTab)
		SettingsBackBtn.Name = "SettingsBackBtn"
		SettingsBackBtn.BorderSizePixel = 0
		SettingsBackBtn.BackgroundTransparency = 1
		SettingsBackBtn.Image = "rbxthumb://type=Asset&id=76888261650966&w=150&h=150"
		SettingsBackBtn.ImageColor3 = Color3.fromRGB(180, 180, 195)
		SettingsBackBtn.Size = UDim2.new(0, 28, 0, 28)
		SettingsBackBtn.Position = UDim2.new(1, -55, 0, 21)
		SettingsBackBtn.ZIndex = 10
		SettingsBackBtn.Visible = false
		SettingsBackBtn.MouseEnter:Connect(function()
			tweenService:Create(SettingsBackBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end)
		SettingsBackBtn.MouseLeave:Connect(function()
			tweenService:Create(SettingsBackBtn, TweenInfo.new(0.12), {ImageColor3 = Color3.fromRGB(180, 180, 195)}):Play()
		end)
		SettingsCategories = Instance.new("Frame", SettingsTab)
		SettingsCategories.BorderSizePixel = 0
		SettingsCategories.BackgroundTransparency = 1
		SettingsCategories.Size = UDim2.new(0.94, 0, 0.75, 0)
		SettingsCategories.Position = UDim2.new(0.03, 0, 0.18, 0)
		local SettingsCatLayout = Instance.new("UIGridLayout", SettingsCategories)
		SettingsCatLayout.CellSize = UDim2.new(0, 185, 0, 80)
		SettingsCatLayout.CellPadding = UDim2.new(0, 12, 0, 12)
		SettingsCatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		SettingsCatLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		SettingsOptionsFrame = Instance.new("ScrollingFrame", SettingsTab)
		SettingsOptionsFrame.BorderSizePixel = 0
		SettingsOptionsFrame.BackgroundTransparency = 1
		SettingsOptionsFrame.Size = UDim2.new(0.94, 0, 0.75, 0)
		SettingsOptionsFrame.Position = UDim2.new(0.03, 0, 0.18, 0)
		SettingsOptionsFrame.ScrollBarThickness = 4
		SettingsOptionsFrame.ScrollBarImageTransparency = 1
		SettingsOptionsFrame.ScrollBarImageColor3 = Color3.fromRGB(82, 82, 82)
		SettingsOptionsFrame.Visible = false
		SettingsOptionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y;
		local SettingsOptionsPadding = Instance.new("UIPadding", SettingsOptionsFrame)
		SettingsOptionsPadding.PaddingLeft = UDim.new(0, 5)
		SettingsOptionsPadding.PaddingRight = UDim.new(0, 5)
		SettingsOptionsPadding.PaddingTop = UDim.new(0, 5)
		SettingsOptionsPadding.PaddingBottom = UDim.new(0, 5)
		local SettingsOptionsLayout = Instance.new("UIListLayout", SettingsOptionsFrame)
		SettingsOptionsLayout.Padding = UDim.new(0, 10)
		end
		pcall(_init_block_9891)
	end

	ResetCustomsBtn = Instance.new("ImageButton", CharacterTab)
	ResetCustomsBtn.Name = "ResetCustomsBtn"
	ResetCustomsBtn.Size = UDim2.new(0, 24, 0, 24)
	ResetCustomsBtn.Position = UDim2.new(0.92, 0, 0.06, 0)
	ResetCustomsBtn.Image = "rbxassetid://4400696294"
	ResetCustomsBtn.BackgroundTransparency = 1
	ResetCustomsBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)

	makeDraggable(G2L["2"]:FindFirstChild("HeaderBar") or G2L["2"], G2L["2"])

	;(function()
		if not KS.validated then return end
		local aeConfig = {}
		local aeFile = "slate/autoexec_cmds.json"
		pcall(function()
			if isfile(aeFile) then
				aeConfig = httpService:JSONDecode(readfile(aeFile)) or {}
			end
		end)
		task.spawn(function()
			task.wait(6)
			for name, active in pairs(aeConfig) do
				if active then
					pcall(execCmd, name)
				end
			end
		end)
	end)()
end

function startAntiFling()
	if antiFlingConn then antiFlingConn:Disconnect() end
	local _antiFlingAccum = 0
	antiFlingConn = runService.Heartbeat:Connect((function(dt)
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if not AntiFlingEnabled then return end
		_antiFlingAccum = _antiFlingAccum + dt
		if _antiFlingAccum < 0.5 then return end
		_antiFlingAccum = 0
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		for _, otherPlr in ipairs(players:GetPlayers()) do
			if otherPlr ~= localPlayer and otherPlr.Character then
				local otherHrp = otherPlr.Character:FindFirstChild("HumanoidRootPart")
				if otherHrp and (otherHrp.Position - hrp.Position).Magnitude < 40 then
					for _, p in ipairs(otherPlr.Character:GetDescendants()) do
						if p:IsA("BasePart") then
							p.CanCollide = false
							p.Velocity = Vector3.zero
							p.AssemblyAngularVelocity = Vector3.zero
						end
					end
				end
			end
		end
	end))
end

siriusValues = {
	siriusFolder = "slate",
	settingsFile = "settings.srs",
	administratorRoles = {"mod", "admin", "staff", "dev", "founder", "owner", "supervis", "manager", "management", "executive", "president", "chairman", "chairwoman", "chairperson", "director"},
	nameGeneration = {
		adjectives = {"Cool", "Awesome", "Epic", "Ninja", "Super", "Mystic", "Swift", "Golden", "Diamond", "Silver", "Mint", "Roblox", "Amazing"},
		nouns = {"Player", "Gamer", "Master", "Legend", "Hero", "Ninja", "Wizard", "Champion", "Warrior", "Sorcerer"}
	},
	transparencyProperties = {
		UIStroke = {'Transparency'},
		Frame = {'BackgroundTransparency'},
		TextButton = {'BackgroundTransparency', 'TextTransparency'},
		TextLabel = {'BackgroundTransparency', 'TextTransparency'},
		TextBox = {'BackgroundTransparency', 'TextTransparency'},
		ImageLabel = {'BackgroundTransparency', 'ImageTransparency'},
		ImageButton = {'BackgroundTransparency', 'ImageTransparency'},
		ScrollingFrame = {'BackgroundTransparency', 'ScrollBarImageTransparency'}
	},
	actions = {
		{
			name = "Noclip",
			enabled = false,
			callback = function() end
		},
		{
			name = "Flight",
			enabled = false,
			callback = function(value)
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum.PlatformStand = value end
			end
		},
		{
			name = "Refresh",
			enabled = false,
			callback = function()
				task.spawn(function()
					local char = localPlayer.Character
					if char then
						local cf = char:GetPivot()
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
						char = localPlayer.CharacterAdded:Wait()
						task.defer(char.PivotTo, char, cf)
					end
				end)
			end
		},
		{
			name = "Respawn",
			enabled = false,
			callback = function()
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
			end
		},
		{
			name = "Invulnerability",
			enabled = false,
			callback = function() end
		},
		{
			name = "Fling",
			enabled = false,
			callback = function(value)
				local character = localPlayer.Character
				local primaryPart = character and character.PrimaryPart
				if primaryPart then
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Massless = value
							part.CustomPhysicalProperties = PhysicalProperties.new(value and math.huge or 0.7, 0.3, 0.5)
						end
					end
					primaryPart.Anchored = true
					primaryPart.AssemblyLinearVelocity = Vector3.zero
					primaryPart.AssemblyAngularVelocity = Vector3.zero
					if movers[3] then movers[3].Parent = value and primaryPart or nil end
					task.delay(0.5, function() primaryPart.Anchored = false end)
				end
			end
		},
		{
			name = "ESP",
			enabled = false,
			callback = function(value)
				for _, highlight in ipairs(espContainer:GetChildren()) do
					highlight.Enabled = value or locatedPlayers[highlight.Name] == true
				end
			end
		},
		{
			name = "Night / Day",
			enabled = false,
			callback = function(value)
				tweenService:Create(lighting, TweenInfo.new(0.5), {ClockTime = value and 12 or 24}):Play()
			end
		},
		{
			name = "Global Audio",
			enabled = false,
			callback = function(value)
				if value then
					oldVolume = gameSettings.MasterVolume
					gameSettings.MasterVolume = 0
				else
					gameSettings.MasterVolume = oldVolume
				end
			end
		},
		{
			name = "Visibility",
			enabled = false,
			callback = function() end
		},
		{
			name = "Facebang Panel",
			enabled = false,
			callback = function(value)
				FacebangWindow.Visible = value
			end
		},
		{
			name = "Anti-Fling",
			enabled = false,
			callback = function(value)
				AntiFlingEnabled = value
				if value then
					startAntiFling()
				else
					if antiFlingConn then
						antiFlingConn:Disconnect()
						antiFlingConn = nil
					end
				end
			end
		},
		{
			name = "Anti Net Pause",
			enabled = false,
			callback = function(value)
				_G.AntiNetPauseEnabled = value
				if value then
					local ok, rblxGui = pcall(function() return game:GetService("CoreGui").RobloxGui end)
					if ok and rblxGui then
						_antiNetPauseConn = rblxGui.ChildAdded:Connect(function(obj)
							if obj.Name == "CoreScripts/NetworkPause" then
								pcall(function() obj:Destroy() end)
							end
						end)
						pcall(function() rblxGui["CoreScripts/NetworkPause"]:Destroy() end)
					end
				else
					if _antiNetPauseConn then
						_antiNetPauseConn:Disconnect()
						_antiNetPauseConn = nil
					end
				end
			end
		},
		{
			name = "Platform Stand",
			enabled = false,
			callback = function(value)
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum.PlatformStand = value end
			end
		},
		{
			name = "Trip Character",
			enabled = false,
			callback = function(value)
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum.Sit = true end
			end
		},
		{
			name = "Invisible Sit",
			enabled = false,
			callback = function(value)
				_G._invSitEnabled = value
				local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Sit = value
					if value then
						pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
					else
						pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
					end
				end
			end
		},
		{
			name = "Zero Gravity",
			enabled = false,
			callback = function(value)
				workspace.Gravity = value and 0 or 196.2
			end
		},
		{
			name = "Infinite Zoom",
			enabled = false,
			callback = function(value)
				_infZoomEnabled = value
				localPlayer.CameraMaxZoomDistance = value and 9e9 or 128
				localPlayer.CameraMinZoomDistance = 0.5
			end
		},
		{
			name = "Godmode",
			enabled = false,
			callback = function(value)
				local cmd = nil
				for _, c in ipairs(onyxCommands) do
					if c.name == "god" then cmd = c; break end
				end
				if cmd then cmd.callback(value) end
			end
		},
		{
			name = "BTools",
			enabled = false,
			callback = function()
				local cmd = nil
				for _, c in ipairs(onyxCommands) do
					if c.name == "btools" then cmd = c; break end
				end
				if cmd then cmd.callback() end
			end
		},
		{
			name = "Infinite Jump",
			enabled = false,
			callback = function(value)
				local cmd = nil
				for _, c in ipairs(onyxCommands) do
					if c.name == "infjump" then cmd = c; break end
				end
				if cmd then cmd.callback(value) end
			end
		},
		{
			name = "Walk on Air",
			enabled = false,
			callback = function(value)
				local cmd = nil
				for _, c in ipairs(onyxCommands) do
					if c.name == "walkonair" then cmd = c; break end
				end
				if cmd then cmd.callback(value) end
			end
		},
		{
			name = "Walk on Walls",
			enabled = false,
			callback = function(value)
				local cmd = nil
				for _, c in ipairs(onyxCommands) do
					if c.name == "walkwall" then cmd = c; break end
				end
				if cmd then cmd.callback(value) end
			end
		},
		{
			name = "Click Teleport",
			enabled = false,
			callback = function(value)
				local cmd = nil
				for _, c in ipairs(onyxCommands) do
					if c.name == "clicktp" then cmd = c; break end
				end
				if cmd then cmd.callback(value) end
			end
		},
		{
			name = "Teleport Tool",
			enabled = false,
			callback = function(value)
				local cmd = nil
				for _, c in ipairs(onyxCommands) do
					if c.name == "tptool" then cmd = c; break end
				end
				if cmd then cmd.callback(value) end
			end
		}
	},
	sliders = {
		{
			name = "Player Speed",
			values = {0, 300},
			default = 16,
			value = 16,
			callback = function(value)
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum.WalkSpeed = value end
			end
		},
		{
			name = "Jump Power",
			values = {0, 350},
			default = 50,
			value = 50,
			callback = function(value)
				local char = localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					if hum.UseJumpPower then
						hum.JumpPower = value
					else
						hum.JumpHeight = value
					end
				end
			end
		},
		{
			name = "Flight Speed",
			values = {1, 25},
			default = 3,
			value = 3,
			callback = function(value) end
		},
		{
			name = "Field of View",
			values = {45, 120},
			default = 70,
			value = 70,
			callback = function(value)
				tweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {FieldOfView = value}):Play()
			end
		}
	}
}
_G.siriusValues = siriusValues
function loadSettings()
	if not readfile or not isfile("slate/settings.srs") then return end
	local success, content = pcall(readfile, "slate/settings.srs")
	if not success or not content then return end
	local successDec, data = pcall(httpService.JSONDecode, httpService, content)
	if not successDec or not data then return end
	for _, category in ipairs(siriusSettings) do
		for i, setting in ipairs(category.categorySettings) do
			if data[setting.id] ~= nil then
				if (setting.id == "spotifyclientid" or setting.id == "spotifyclientsecret" or setting.id == "spotifyrefreshtoken" or setting.id == "spotifyoauthtoken") and (data[setting.id] == "" or data[setting.id] == nil) and (setting.current ~= "" and setting.current ~= nil) then

				else
					setting.current = data[setting.id]
				end
			end
		end
	end
	for _, slider in ipairs(siriusValues.sliders) do
		local k = "slider_" .. slider.name
		if data[k] ~= nil then
			slider.value = data[k]
		end
	end
	local tokenSet = checkSetting("spotifyoauthtoken")
	if tokenSet and tokenSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_token.txt", tokenSet.current)
	end
	local refreshSet = checkSetting("spotifyrefreshtoken")
	if refreshSet and refreshSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_refresh_token.txt", refreshSet.current)
	end
	local clientidSet = checkSetting("spotifyclientid")
	if clientidSet and clientidSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_client_id.txt", clientidSet.current)
	end
	local clientsecretSet = checkSetting("spotifyclientsecret")
	if clientsecretSet and clientsecretSet.current ~= "" then
		pcall(writefile, "slate/music/spotify_client_secret.txt", clientsecretSet.current)
	end
	local mainSet   = checkSetting("maincolor")
	local accentSet = checkSetting("accentcolor")
	local themeSet  = checkSetting("activetheme")
	if mainSet   then mainSet.current   = "#0C0C0E" end
	if accentSet then accentSet.current = "#FFFFFF"  end
	if themeSet  then themeSet.current  = "Monochrome" end
	pcall(function() _G.updateAllCustomBackgrounds() end)
end

task.spawn(loadSettings)
pcall(function()
	local mainSet = checkSetting("maincolor")
	local accentSet = checkSetting("accentcolor")
	if mainSet and accentSet then

		applyTheme(mainSet.current, accentSet.current)
	end
end)

activeTab = G2L["6"]
activeTab.GroupTransparency = 0
activeTab.Visible = true

local function _init_block_10563()
	G2L["30"].MouseEnter:Connect(function()
		if smartBarOpen or _G.isShowingOwnerNotification or _G._slateCmdBarOpen or _G.isShowingIslandNotif then return end
		openSmartBar()
	end)

	G2L["30"].MouseLeave:Connect(function()
		if smartBarOpen and not _G._slateCmdBarOpen then
			task.delay(0.4, function()
				if smartBarOpen and not _G._slateCmdBarOpen and (os.clock() - _smartBarOpenedAt >= 0.5) and not isMouseInSmartBarArea() then
					closeSmartBar()
				end
			end)
		end
	end)

	G2L["30"].InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if smartBarOpen then closeSmartBar() else openSmartBar() end
		end
	end)

	DockLogo.MouseLeave:Connect(function()
		if smartBarOpen and not _G._slateCmdBarOpen then
			task.delay(0.4, function()
				if smartBarOpen and not _G._slateCmdBarOpen and (os.clock() - _smartBarOpenedAt >= 0.5) and not isMouseInSmartBarArea() then
					closeSmartBar()
				end
			end)
		end
	end)

	DockLogo.MouseButton1Click:Connect(function()
		SlateUiSound.click()
		if G2L["2"].Visible and G2L["2"].GroupTransparency < 0.1 then
			local fade = tweenService:Create(G2L["2"], TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
			fade.Completed:Connect(function()
				G2L["2"].Visible = false
			end)
			fade:Play()
			hideBlurOverlay()
		else
			G2L["2"].Visible = true
			G2L["2"].GroupTransparency = 1
			tweenService:Create(G2L["2"], TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
			showBlurOverlay()
		end
	end)

	MainCloseBtn.MouseButton1Click:Connect(function()
		SlateUiSound.click()
		if G2L["2"].Visible then
			local fade = tweenService:Create(G2L["2"], TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
			fade.Completed:Connect(function()
				G2L["2"].Visible = false
			end)
			fade:Play()
			hideBlurOverlay()
		end
	end)
	end
	_init_block_10563()

function rejoin()
	queueNotification("Rejoining Session", "Attempting rejoin...")
	if #players:GetPlayers() <= 1 then
		teleportService:Teleport(placeId, localPlayer)
	else
		teleportService:TeleportToPlaceInstance(placeId, jobId, localPlayer)
	end
end
function serverhop()
	local servers = {}
	pcall(function()
		local data = httpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")).data
		for _, v in ipairs(data) do
			if v.playing and v.playing < v.maxPlayers and v.id ~= jobId then
				table.insert(servers, v.id)
			end
		end
	end)
	if #servers > 0 then
		queueNotification("Serverhop", "Teleporting to next server...")
		teleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)])
	else
		queueNotification("Serverhop Error", "No suitable servers found.")
	end
end

do
	local function _init_block_chat()
	local SlateChat = {}
	_G.SlateChat = SlateChat

	SlateChat.ROOM = _G.SlateChatRoom or "global"
	SlateChat.IMG_DIR = "slate/imgcache"
	SlateChat.MAX_LEN = 300
	SlateChat.SEND_COOLDOWN = 0.7

	local ACCENT      = Color3.fromRGB(255, 255, 255)
	local ACCENT_LIT  = Color3.fromRGB(200, 200, 205)
	local BUBBLE_THEM = Color3.fromRGB(28, 28, 32)

	local function contrastText(c)
		local lum = 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
		return (lum > 0.55) and Color3.fromRGB(12, 12, 14) or Color3.fromRGB(238, 238, 242)
	end
	local ACCENT_TEXT = contrastText(ACCENT)

	local WIN_W, WIN_H = 340, 400
	local PAD        = 12
	local AVATAR     = 26
	local GAP        = 8
	local BUB_PADX   = 9
	local BUB_PADY   = 6
	local BUB_MAXW   = 220
	local META_SIZE  = 10
	local BODY_SIZE  = 12.5
	local META_H     = 13
	local META_GAP   = 2
	local GROUP_WINDOW = 300
	local IMG_W, IMG_H = 160, 110

	local httpSvc  = httpService or game:GetService("HttpService")
	local textSvc  = game:GetService("TextService")
	local lp = localPlayer

	local function notify(title, body)
		if type(queueNotification) == "function" then pcall(queueNotification, title, body) end
	end

	local function urlEncode(str)
		return (tostring(str):gsub("[^%w%-%._~]", function(c)
			return string.format("%%%02X", string.byte(c))
		end))
	end

	local function hashString(str)
		local h = 5381
		for i = 1, #str do
			h = (h * 33 + string.byte(str, i)) % 4294967296
		end
		return string.format("%08x%d", h, #str)
	end

	local function isRobloxAsset(url)
		if not url then return nil end
		return url:match("^rbxassetid://(%d+)")
			or url:match("^%s*(%d+)%s*$")
			or url:match("roblox%.com/.-[%?&]id=(%d+)")
			or url:match("roblox%.com/library/(%d+)")
			or url:match("roblox%.com/catalog/(%d+)")
	end

	local _memImages = {}
	local _memErrors = {}
	local reqFunc = http_request or request or (syn and syn.request) or (http and http.request)

	local function httpFetch(url)
		local status
		if reqFunc then
			local ok, res = pcall(reqFunc, { Url = url, Method = "GET" })
			if ok and res then
				status = res.StatusCode
				if res.Body and (status == nil or status == 200) then
					return res.Body, status
				end
			end
		end
		local ok, res = pcall(game.HttpGet, game, url)
		if ok and res then return res, 200 end
		return nil, status
	end

	local function httpFetchTimed(url, timeout)
		local done, result, status = false, nil, nil
		task.spawn(function()
			result, status = httpFetch(url)
			done = true
		end)
		local waited = 0
		timeout = timeout or 8
		while not done and waited < timeout do
			task.wait(0.05)
			waited = waited + 0.05
		end
		if not done then return nil, true, nil end
		return result, false, status
	end

	local function customAsset(path)
		local uri
		if getcustomasset then pcall(function() uri = getcustomasset(path) end)
		elseif getsynasset then pcall(function() uri = getsynasset(path) end) end
		return uri
	end

	local function ensureImgDir()
		if not (makefolder and isfolder) then return false end
		pcall(function()
			if not isfolder("slate") then makefolder("slate") end
			if not isfolder(SlateChat.IMG_DIR) then makefolder(SlateChat.IMG_DIR) end
		end)
		local ok, res = pcall(isfolder, SlateChat.IMG_DIR)
		return ok and res
	end

	local _inflight = {}
	local _memMeta  = {}
	local runSvc    = game:GetService("RunService")

	local function backendBase()
		local b = _G.SlateBackendBase or getgenv().BACKEND_URL or _G.BACKEND_URL or "https://api.onyxv2.lol"
		return (tostring(b):gsub("/$", ""))
	end

	local function headerLookup(headers, name)
		if type(headers) ~= "table" then return nil end
		local want = name:lower()
		for k, v in pairs(headers) do
			if tostring(k):lower() == want then return v end
		end
		return nil
	end

	local function httpFetchFull(url, timeout)
		local done, body, headers, status = false, nil, nil, nil
		task.spawn(function()
			if reqFunc then
				local ok, res = pcall(reqFunc, { Url = url, Method = "GET" })
				if ok and res then
					status  = res.StatusCode
					headers = res.Headers or res.headers
					if res.Body and (status == nil or status == 200) then
						body = res.Body
					end
				end
			end
			if not body then
				local ok, res = pcall(game.HttpGet, game, url)
				if ok and res then body, status = res, 200 end
			end
			done = true
		end)

		local waited = 0
		timeout = timeout or 10
		while not done and waited < timeout do
			task.wait(0.05)
			waited = waited + 0.05
		end
		if not done then return nil, nil, nil, true end
		return body, headers, status, false
	end

	local function writeMeta(path, meta)
		pcall(writefile, path, table.concat({
			meta.animated and "1" or "0",
			tostring(meta.frameCount or 1),
			tostring(meta.frameW or IMG_W),
			tostring(meta.frameH or IMG_H),
			tostring(meta.delay or 80),
			tostring(meta.perRow or 4),
		}, "|"))
	end

	local function readMeta(path)
		if not (isfile and isfile(path)) then return nil end
		local ok, raw = pcall(readfile, path)
		if not ok or not raw then return nil end
		local parts = {}
		for piece in tostring(raw):gmatch("[^|]+") do parts[#parts + 1] = piece end
		if #parts < 6 then return nil end
		return {
			animated   = parts[1] == "1",
			frameCount = tonumber(parts[2]) or 1,
			frameW     = tonumber(parts[3]) or IMG_W,
			frameH     = tonumber(parts[4]) or IMG_H,
			delay      = tonumber(parts[5]) or 80,
			perRow     = tonumber(parts[6]) or 4,
		}
	end

	local function loadMedia(url)
		local cached = _memImages[url]
		if cached ~= nil then
			return cached or nil, _memMeta[url], _memErrors[url]
		end

		if _inflight[url] then
			local waited = 0
			while _inflight[url] and waited < 25 do
				task.wait(0.05)
				waited = waited + 0.05
			end
			return _memImages[url] or nil, _memMeta[url], _memErrors[url]
		end
		_inflight[url] = true

		local assetId = isRobloxAsset(url)
		if assetId then
			local uri = "rbxassetid://" .. assetId
			_memImages[url] = uri
			_inflight[url] = nil
			return uri, nil
		end

		local function finish(uri, meta, err)
			_inflight[url] = nil
			return uri, meta, err
		end

		if not (writefile and isfile) then
			return finish(nil, nil, "executor has no writefile")
		end
		if not (getcustomasset or getsynasset) then
			return finish(nil, nil, "executor has no getcustomasset")
		end
		if not ensureImgDir() then
			return finish(nil, nil, "couldn't create " .. SlateChat.IMG_DIR)
		end

		local base     = SlateChat.IMG_DIR .. "/" .. hashString(url)
		local pngPath  = base .. ".png"
		local metaPath = base .. ".meta"

		if isfile(pngPath) then
			local uri = customAsset(pngPath)
			if uri then
				local meta = readMeta(metaPath)
				_memImages[url] = uri
				_memMeta[url] = meta
				return finish(uri, meta)
			end
		end

		local enc = urlEncode(url)
		local endpoint = backendBase() .. "/spritesheet/media?url=" .. enc
			.. "&w=" .. tostring(IMG_W) .. "&h=" .. tostring(IMG_H) .. "&frames=20"

		local lowerUrl = url:lower()
		local isGif    = lowerUrl:find("%.gif") ~= nil

		local attempts = {
			{ name = "slate", url = endpoint, timeout = isGif and 30 or 15 },
		}
		if isGif then
			attempts[#attempts + 1] = { name = "slate-retry", url = endpoint, timeout = 20 }
		else

			attempts[#attempts + 1] = { name = "direct", url = url, timeout = 12 }
		end

		local function looksLikeImage(b)
			if not b or #b < 128 then return false end
			local b1, b2, b3, b4 = string.byte(b, 1, 4)
			if b1 == 137 and b2 == 80 and b3 == 78 and b4 == 71 then return true end
			if b1 == 255 and b2 == 216 then return true end
			if b1 == 82 and b2 == 73 and b3 == 70 and b4 == 70 then return true end
			return false
		end

		local errs = {}
		for _, src in ipairs(attempts) do
			local body, headers, status, timedOut = httpFetchFull(src.url, src.timeout or 12)
			local why
			if timedOut then
				why = "timed out"
			elseif not body or #body < 128 then
				if status and status ~= 200 then
					why = "HTTP " .. tostring(status)
				elseif body then
					why = "said: " .. body:gsub("%s+", " "):sub(1, 70)
				else
					why = "no response"
				end
			elseif not looksLikeImage(body) then
				if body:sub(1, 3) == "GIF" then
					why = "raw GIF (needs spritesheet backend)"
				else
					why = "said: " .. body:gsub("%s+", " "):sub(1, 70)
				end
			else
				if pcall(writefile, pngPath, body) then
					local uri = customAsset(pngPath)
					if uri then
						local meta
						if headerLookup(headers, "X-Animated") == "1" then
							meta = {
								animated   = true,
								frameCount = tonumber(headerLookup(headers, "X-Frame-Count")) or 1,
								frameW     = tonumber(headerLookup(headers, "X-Frame-Width")) or IMG_W,
								frameH     = tonumber(headerLookup(headers, "X-Frame-Height")) or IMG_H,
								delay      = tonumber(headerLookup(headers, "X-Frame-Delay")) or 80,
								perRow     = tonumber(headerLookup(headers, "X-Frames-Per-Row")) or 4,
							}
							if meta.frameCount < 2 then meta = nil end
						end
						writeMeta(metaPath, meta or { animated = false })
						_memImages[url] = uri
						_memMeta[url] = meta
						return finish(uri, meta)
					end
					why = "getcustomasset rejected the file"
				else
					why = "couldn't write " .. pngPath
				end
			end
			errs[#errs + 1] = src.name .. ": " .. why
		end

		local lastErr = (#errs > 0) and table.concat(errs, " | ") or "download failed"
		_memErrors[url] = lastErr
		return finish(nil, nil, lastErr)
	end

	local function applyImage(imageLabel, url)
		task.spawn(function()
			local bubble = imageLabel.Parent
			local uri, meta, err = loadMedia(url)
			if not imageLabel.Parent then return end

			local spin = bubble and bubble:FindFirstChild("Loading")
			if not uri then
				if spin then
					spin.Text = url
					spin.TextColor3 = Color3.fromRGB(150, 146, 168)
					spin.TextSize = 9
				end
				warn("[Slate Chat] image failed (" .. tostring(err) .. "): " .. tostring(url))
				return
			end

			if spin then spin.Visible = false end
			imageLabel.ScaleType = Enum.ScaleType.Stretch
			imageLabel.Image = uri
			imageLabel.ImageTransparency = 1
			tweenService:Create(imageLabel, TweenInfo.new(0.15), {ImageTransparency = 0}):Play()

			if not (meta and meta.animated and meta.frameCount > 1) then return end

			local fw, fh   = meta.frameW, meta.frameH
			local perRow   = math.max(1, meta.perRow)
			local count    = meta.frameCount
			local interval = math.max(0.016, (meta.delay or 80) / 1000)

			imageLabel.ImageRectSize = Vector2.new(fw, fh)
			imageLabel.ImageRectOffset = Vector2.new(0, 0)

			local idx, acc = 0, 0
			local conn
			conn = runSvc.Heartbeat:Connect(function(dt)
				if not imageLabel.Parent then
					conn:Disconnect()
					return
				end
				if not imageLabel.Visible then return end
				acc = acc + dt
				if acc < interval then return end
				acc = acc % interval
				idx = (idx + 1) % count
				imageLabel.ImageRectOffset = Vector2.new(
					(idx % perRow) * fw,
					math.floor(idx / perRow) * fh
				)
			end)
		end)
	end
	SlateChat.applyImage = applyImage

	local ChatContent, ChatWindow = createStandaloneWindow("SlateChatWindow", "Slate Chat", UDim2.new(0, WIN_W, 0, WIN_H))
	SlateChat.window = ChatWindow

	for _, d in ipairs(ChatWindow:GetChildren()) do
		if d:IsA("UIStroke") then d:Destroy() end
	end

	local CONTENT_H = WIN_H - 40
	local INPUT_H   = 30
	local INPUT_Y   = CONTENT_H - PAD - INPUT_H
	local SCROLL_Y  = 26
	local SCROLL_H  = INPUT_Y - SCROLL_Y - 10

	local statusDot = Instance.new("Frame", ChatContent)
	statusDot.Name = "StatusDot"
	statusDot.Size = UDim2.new(0, 6, 0, 6)
	statusDot.Position = UDim2.new(0, PAD + 1, 0, 10)
	statusDot.BackgroundColor3 = Color3.fromRGB(200, 160, 60)
	statusDot.BorderSizePixel = 0
	Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

	local statusLbl = Instance.new("TextLabel", ChatContent)
	statusLbl.Name = "StatusLabel"
	statusLbl.BackgroundTransparency = 1
	statusLbl.Size = UDim2.new(1, -(PAD * 2 + 14), 0, 12)
	statusLbl.Position = UDim2.new(0, PAD + 13, 0, 7)
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.TextSize = 10
	statusLbl.Font = Enum.Font.GothamMedium
	statusLbl.TextColor3 = Color3.fromRGB(150, 150, 162)
	statusLbl.Text = "Waiting for the Slate socket..."

	local msgScroll = Instance.new("ScrollingFrame", ChatContent)
	msgScroll.Name = "MessageScroll"
	msgScroll.BorderSizePixel = 0
	msgScroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	msgScroll.BackgroundTransparency = 0.82
	msgScroll.Size = UDim2.new(1, -PAD * 2, 0, SCROLL_H)
	msgScroll.Position = UDim2.new(0, PAD, 0, SCROLL_Y)
	msgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	msgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	msgScroll.ClipsDescendants = true
	msgScroll.ScrollBarThickness = 2
	msgScroll.ScrollBarImageTransparency = 1
	msgScroll.ScrollBarImageColor3 = Color3.fromRGB(110, 110, 115)
	Instance.new("UICorner", msgScroll).CornerRadius = UDim.new(0, 8)

	local msgPad = Instance.new("UIPadding", msgScroll)
	msgPad.PaddingLeft = UDim.new(0, 8)
	msgPad.PaddingRight = UDim.new(0, 8)
	msgPad.PaddingTop = UDim.new(0, 8)
	msgPad.PaddingBottom = UDim.new(0, 8)

	local msgLayout = Instance.new("UIListLayout", msgScroll)
	msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
	msgLayout.Padding = UDim.new(0, 4)

	local emptyLbl = Instance.new("TextLabel", ChatContent)
	emptyLbl.Name = "EmptyLabel"
	emptyLbl.BackgroundTransparency = 1
	emptyLbl.Size = UDim2.new(1, -PAD * 2, 0, 16)
	emptyLbl.Position = UDim2.new(0, PAD, 0, SCROLL_Y + SCROLL_H / 2 - 8)
	emptyLbl.TextSize = 11
	emptyLbl.Font = Enum.Font.Gotham
	emptyLbl.TextColor3 = Color3.fromRGB(110, 110, 122)
	emptyLbl.Text = "No messages yet - say hi to everyone on Slate."

	local inputBar = Instance.new("Frame", ChatContent)
	inputBar.Name = "InputBar"
	inputBar.Size = UDim2.new(1, -PAD * 2, 0, INPUT_H)
	inputBar.Position = UDim2.new(0, PAD, 0, INPUT_Y)
	inputBar.BackgroundTransparency = 1

	local sendBtn = Instance.new("TextButton", inputBar)
	sendBtn.Name = "SendButton"
	sendBtn.Size = UDim2.new(0, 52, 1, 0)
	sendBtn.AnchorPoint = Vector2.new(1, 0)
	sendBtn.Position = UDim2.new(1, 0, 0, 0)
	sendBtn.BackgroundColor3 = ACCENT
	sendBtn.BorderSizePixel = 0
	sendBtn.Text = "Send"
	sendBtn.TextSize = 12
	sendBtn.Font = Enum.Font.GothamBold
	sendBtn.TextColor3 = ACCENT_TEXT
	sendBtn.AutoButtonColor = false
	Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 7)

	local inputBox = Instance.new("TextBox", inputBar)
	inputBox.Name = "MessageBox"
	inputBox.Size = UDim2.new(1, -58, 1, 0)
	inputBox.Position = UDim2.new(0, 0, 0, 0)
	inputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.BackgroundTransparency = 0.72
	inputBox.BorderSizePixel = 0
	inputBox.ClearTextOnFocus = false
	inputBox.Text = ""
	inputBox.PlaceholderText = "  Message everyone on Slate..."
	inputBox.PlaceholderColor3 = Color3.fromRGB(125, 125, 130)
	inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	inputBox.TextSize = 12
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.Font = Enum.Font.Gotham
	inputBox.TextTruncate = Enum.TextTruncate.AtEnd
	Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 7)
	local inPad = Instance.new("UIPadding", inputBox)
	inPad.PaddingLeft = UDim.new(0, 8)
	inPad.PaddingRight = UDim.new(0, 8)

	local rowOrder = 0
	local renderedIds = {}
	local messageCount = 0
	local lastSender, lastStamp = nil, 0

	local function measure(text, size, font, maxWidth)
		local ok, b = pcall(function()
			return textSvc:GetTextSize(text, size, font, Vector2.new(maxWidth, 100000))
		end)
		if ok and b then
			return math.ceil(b.X) + 2, math.ceil(b.Y)
		end
		return maxWidth, math.ceil(size * 1.3)
	end

	local function scrollToBottom()
		task.defer(function()
			task.wait()
			pcall(function()
				local canvasY = msgScroll.AbsoluteCanvasSize.Y
				local viewY   = msgScroll.AbsoluteWindowSize.Y
				msgScroll.CanvasPosition = Vector2.new(0, math.max(0, canvasY - viewY))
			end)
		end)
	end

	local function trimHistory()
		if messageCount <= 100 then return end
		local kids = {}
		for _, c in ipairs(msgScroll:GetChildren()) do
			if c:IsA("Frame") and c.Name == "MsgRow" then kids[#kids + 1] = c end
		end
		table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		for i = 1, #kids - 100 do
			kids[i]:Destroy()
			messageCount = messageCount - 1
		end
	end

	local function addMessage(msg)
		if type(msg) ~= "table" then return end

		if msg.messages ~= nil or msg.system then return end
		if not (msg.text and msg.text ~= "") and not ((msg.kind == "image" or msg.kind == "gif") and msg.url) then return end
		if msg.id and renderedIds[msg.id] then return end
		if msg.id then renderedIds[msg.id] = true end

		local isSelf  = tostring(msg.userId) == tostring(lp.UserId)
		local isImage = (msg.kind == "image" or msg.kind == "gif") and msg.url
		local stamp   = tonumber(msg.ts) or os.time()

		local senderKey = tostring(msg.userId)
		local grouped = (lastSender == senderKey) and (stamp - lastStamp) < GROUP_WINDOW
		lastSender, lastStamp = senderKey, stamp

		emptyLbl.Visible = false
		rowOrder = rowOrder + 1
		messageCount = messageCount + 1

		local innerMax = BUB_MAXW - BUB_PADX * 2

		local bodyW, bodyH, bodyText = 0, 0, nil
		if isImage then
			bodyW, bodyH = IMG_W, IMG_H
		else
			bodyText = tostring(msg.text or "")
			bodyW, bodyH = measure(bodyText, BODY_SIZE, Enum.Font.Gotham, innerMax)
		end

		local innerW  = math.min(bodyW, innerMax)
		local bubbleW, bubbleH
		if isImage then

			bubbleW, bubbleH = IMG_W, IMG_H
		else
			bubbleW = innerW + BUB_PADX * 2
			bubbleH = bodyH + BUB_PADY * 2
		end

		local metaBlock = grouped and 0 or (META_H + META_GAP)
		local rowH = metaBlock + bubbleH
		if not grouped then rowH = math.max(rowH, AVATAR) end

		local row = Instance.new("Frame")
		row.Name = "MsgRow"
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, rowH)
		row.LayoutOrder = rowOrder

		local inset = AVATAR + GAP

		if not grouped then
			local avatar = Instance.new("ImageLabel", row)
			avatar.Name = "Avatar"
			avatar.Size = UDim2.new(0, AVATAR, 0, AVATAR)
			avatar.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
			avatar.BorderSizePixel = 0
			avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(msg.userId or 1) .. "&w=48&h=48"
			Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
			if isSelf then
				avatar.AnchorPoint = Vector2.new(1, 0)
				avatar.Position = UDim2.new(1, 0, 0, 0)
			else
				avatar.Position = UDim2.new(0, 0, 0, 0)
			end

			local display  = tostring(msg.display or msg.name or "Unknown")
			local timeText = os.date("%I:%M %p", stamp)

			local nameW = measure(display, META_SIZE, Enum.Font.GothamBold, 130)
			local timeW = measure(timeText, META_SIZE - 1, Enum.Font.Gotham, 80)
			nameW = math.min(nameW, 130)

			local meta = Instance.new("Frame", row)
			meta.Name = "Meta"
			meta.BackgroundTransparency = 1
			meta.Size = UDim2.new(0, nameW + 6 + timeW, 0, META_H)
			if isSelf then
				meta.AnchorPoint = Vector2.new(1, 0)
				meta.Position = UDim2.new(1, -inset, 0, 0)
			else
				meta.Position = UDim2.new(0, inset, 0, 0)
			end

			local nameLbl = Instance.new("TextLabel", meta)
			nameLbl.Name = "Display"
			nameLbl.BackgroundTransparency = 1
			nameLbl.Size = UDim2.new(0, nameW, 1, 0)
			nameLbl.Position = UDim2.new(0, 0, 0, 0)
			nameLbl.TextSize = META_SIZE
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextColor3 = isSelf and Color3.fromRGB(200, 200, 205) or Color3.fromRGB(160, 160, 165)
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			nameLbl.TextStrokeTransparency = 1
			nameLbl.Text = display

			local timeLbl = Instance.new("TextLabel", meta)
			timeLbl.Name = "Time"
			timeLbl.BackgroundTransparency = 1
			timeLbl.Size = UDim2.new(0, timeW, 1, 0)
			timeLbl.Position = UDim2.new(0, nameW + 6, 0, 0)
			timeLbl.TextSize = META_SIZE - 1
			timeLbl.Font = Enum.Font.Gotham
			timeLbl.TextColor3 = Color3.fromRGB(120, 120, 126)
			timeLbl.TextXAlignment = Enum.TextXAlignment.Left
			timeLbl.TextStrokeTransparency = 1
			timeLbl.Text = timeText
		end

		local bubble = Instance.new("Frame", row)
		bubble.Name = "Bubble"

		bubble.BackgroundColor3 = isImage and Color3.fromRGB(20, 20, 24)
			or (isSelf and ACCENT or BUBBLE_THEM)
		bubble.BorderSizePixel = 0
		bubble.Size = UDim2.new(0, bubbleW, 0, bubbleH)
		bubble.ClipsDescendants = true
		if isSelf then
			bubble.AnchorPoint = Vector2.new(1, 0)
			bubble.Position = UDim2.new(1, -inset, 0, metaBlock)
		else
			bubble.Position = UDim2.new(0, inset, 0, metaBlock)
		end
		Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 8)

		if isImage then

			local img = Instance.new("ImageLabel", bubble)
			img.Name = "Image"
			img.BackgroundTransparency = 1
			img.Size = UDim2.new(1, 0, 1, 0)
			img.ScaleType = Enum.ScaleType.Crop
			img.Image = ""

			Instance.new("UICorner", img).CornerRadius = UDim.new(0, 8)

			local loading = Instance.new("TextLabel", bubble)
			loading.Name = "Loading"
			loading.BackgroundTransparency = 1
			loading.Size = UDim2.new(1, -10, 1, 0)
			loading.Position = UDim2.new(0, 5, 0, 0)
			loading.Text = "Loading image..."
			loading.TextSize = 10
			loading.TextWrapped = true
			loading.Font = Enum.Font.Gotham
			loading.TextColor3 = Color3.fromRGB(125, 125, 130)

			applyImage(img, msg.url)
		else
			local body = Instance.new("TextLabel", bubble)
			body.Name = "Body"
			body.BackgroundTransparency = 1
			body.Size = UDim2.new(0, innerW, 0, bodyH)
			body.Position = UDim2.new(0, BUB_PADX, 0, BUB_PADY)
			body.TextWrapped = true
			body.TextSize = BODY_SIZE
			body.Font = Enum.Font.Gotham
			body.TextColor3 = isSelf and ACCENT_TEXT or Color3.fromRGB(238, 238, 242)
			body.TextXAlignment = isSelf and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
			body.TextYAlignment = Enum.TextYAlignment.Top
			body.TextStrokeTransparency = 1
			body.Text = bodyText
		end

		row.Parent = msgScroll
		trimHistory()
		scrollToBottom()
	end
	SlateChat.addMessage = addMessage

	local function addSystemMessage(text)
		emptyLbl.Visible = false
		rowOrder = rowOrder + 1
		messageCount = messageCount + 1
		lastSender = nil

		local innerMax = msgScroll.AbsoluteSize.X - 20
		if innerMax < 100 then innerMax = 300 end
		local _, h = measure(text, 10.5, Enum.Font.GothamMedium, innerMax)

		local row = Instance.new("Frame")
		row.Name = "MsgRow"
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, h + 4)
		row.LayoutOrder = rowOrder

		local lbl = Instance.new("TextLabel", row)
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.TextWrapped = true
		lbl.TextSize = 10.5
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextColor3 = Color3.fromRGB(110, 110, 115)
		lbl.TextXAlignment = Enum.TextXAlignment.Center
		lbl.TextYAlignment = Enum.TextYAlignment.Top
		lbl.Text = text

		row.Parent = msgScroll
		trimHistory()
		scrollToBottom()
	end
	SlateChat.addSystemMessage = addSystemMessage

	local boundSocket = nil

	local function setStatus(text, color)
		statusLbl.Text = text
		tweenService:Create(statusDot, TweenInfo.new(0.25), {BackgroundColor3 = color}):Play()
	end

	local function handlePayload(raw)
		local ok, msg = pcall(function() return httpSvc:JSONDecode(raw) end)
		if not ok or type(msg) ~= "table" then return end
		if msg.type ~= "chat" then return end

		local d = msg.data
		if type(d) ~= "table" then return end

		if type(d.messages) == "table" then
			for _, m in ipairs(d.messages) do pcall(addMessage, m) end
			return
		end
		if d.system then
			addSystemMessage(tostring(d.text or ""))
			return
		end
		if d.room and d.room ~= SlateChat.ROOM then return end

		pcall(addMessage, d)
	end

	task.spawn(function()
		while true do
			local sock = _G.SlateActiveWS
			if sock ~= boundSocket then
				boundSocket = sock
				if sock then
					setStatus("Connected to Slate Chat", Color3.fromRGB(70, 200, 110))
					pcall(function()
						sock.OnMessage:Connect(function(raw)
							pcall(handlePayload, tostring(raw))
						end)
					end)

					pcall(function()
						sock:Send(httpSvc:JSONEncode({
							type      = "identify",
							username  = lp.Name:lower(),
							userId    = lp.UserId,
							jobId     = game.JobId,
							placeId   = game.PlaceId,
							subscribe = "nametags,owners,announcements,commands,heartbeat,dms,chat",
						}))
					end)
					pcall(function()
						sock:Send(httpSvc:JSONEncode({
							type = "chat_join",
							data = {
								room = SlateChat.ROOM,
								userId = lp.UserId,
								name = lp.Name,
								display = lp.DisplayName,
								placeId = game.PlaceId,
							},
						}))
					end)

					pcall(function()
						sock:Send(httpSvc:JSONEncode({
							type = "chat_history",
							data = { room = SlateChat.ROOM, limit = 50 },
						}))
					end)
				else
					setStatus("Waiting for the Slate socket...", Color3.fromRGB(200, 160, 60))
				end
			elseif not sock then
				setStatus("Slate socket offline", Color3.fromRGB(200, 90, 70))
			end
			task.wait(2)
		end
	end)

	local lastSend = 0

	local function sendPayload(payload)
		local now = os.clock()
		if now - lastSend < SlateChat.SEND_COOLDOWN then
			notify("Slate Chat", "Slow down a little.")
			return false
		end
		lastSend = now

		payload.room    = SlateChat.ROOM
		payload.userId  = lp.UserId
		payload.name    = lp.Name
		payload.display = lp.DisplayName
		payload.ts      = os.time()
		payload.id      = tostring(lp.UserId) .. "-" .. tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))

		pcall(addMessage, payload)

		local sock = _G.SlateActiveWS
		if not sock then
			addSystemMessage("The Slate socket isn't connected - that message only showed for you.")
			return false
		end

		local ok = pcall(function()
			sock:Send(httpSvc:JSONEncode({ type = "chat", data = payload }))
		end)
		if not ok then

			_G.SlateActiveWS = nil
			addSystemMessage("Send failed - the socket dropped.")
			return false
		end
		return true
	end
	SlateChat.sendPayload = sendPayload

	local function isImageLink(s)
		return s:match("^https?://%S+$") ~= nil
	end

	local function sendText()
		local text = inputBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" then return end
		if #text > SlateChat.MAX_LEN then text = text:sub(1, SlateChat.MAX_LEN) end
		inputBox.Text = ""

		if isImageLink(text) or isRobloxAsset(text) then
			sendPayload({ kind = "image", url = text, text = "" })
		else
			sendPayload({ kind = "text", text = text })
		end
	end

	sendBtn.MouseButton1Click:Connect(sendText)
	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then sendText() end
	end)
	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		if #inputBox.Text > SlateChat.MAX_LEN then
			inputBox.Text = inputBox.Text:sub(1, SlateChat.MAX_LEN)
		end
	end)

	sendBtn.MouseEnter:Connect(function()
		tweenService:Create(sendBtn, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT_LIT}):Play()
	end)
	sendBtn.MouseLeave:Connect(function()
		tweenService:Create(sendBtn, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT}):Play()
	end)

	local function openChat()
		if not (ChatWindow.Visible and ChatWindow.GroupTransparency < 0.1) then
			toggleWindow(ChatWindow)
		end
		task.delay(0.05, function() pcall(function() inputBox:CaptureFocus() end) end)
	end

	SlateChat.open   = openChat
	SlateChat.toggle = function() toggleWindow(ChatWindow) end
	SlateChat.close  = function()
		if ChatWindow.Visible then toggleWindow(ChatWindow) end
	end

	_G.SlateToggleChat = SlateChat.toggle
	_G.SlateOpenChat   = openChat

	end
	local okChat, errChat = pcall(_init_block_chat)
	if not okChat then
		warn("[Slate] Chat failed to initialise: " .. tostring(errChat))
	end
end

	HomeBtn.MouseButton1Click:Connect(function() switchTab(G2L["6"]) end)

	CharacterBtn.MouseButton1Click:Connect(function() switchTab(CharacterTab) end)
	CommandsBtn.MouseButton1Click:Connect(function() switchTab(CommandsTab) end)
	PlayersBtn.MouseButton1Click:Connect(function() switchTab(PlayersTab) end)
	MusicBtn.MouseButton1Click:Connect(function()
		switchTab(MusicTab)
	end)
	SettingsBtn.MouseButton1Click:Connect(function() switchTab(SettingsTab) end)
	if CloudBtn then
		CloudBtn.MouseButton1Click:Connect(function() SlateCloud.openTab() end)
	end

	pcall(SlateNav.build)
	pcall(SlateNav.paint)

do
	local function _init_block_10673()
	local container = CharacterTab:FindFirstChild("ActionsContainer") or CharacterTab:FindFirstChildOfClass("Frame")
	if container then
		for _, act in ipairs(siriusValues.actions) do
			local actFrame = Instance.new("Frame")
			actFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			actFrame.BorderSizePixel = 0
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(60, 60, 60)
			stroke.Parent = actFrame
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = actFrame
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -2, 1, -2)
			btn.Position = UDim2.new(0, 1, 0, 1)
			btn.BackgroundTransparency = 1
			btn.Text = act.name
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 13
			btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			btn.Parent = actFrame
			btn.MouseButton1Click:Connect(function()
				local oneShot = act.name == "Refresh" or act.name == "Respawn" or act.name == "Trip Character"
				if oneShot then
					act.callback(true)
				else
					act.enabled = not act.enabled
					act.callback(act.enabled)
					actFrame.BackgroundColor3 = act.enabled and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(30, 30, 30)
				end
			end)
			actFrame.Parent = container
		end
	end

	local rightCont = CharacterTab:FindFirstChild("RightContainer")
	if rightCont then
		local function updateSlider(slider, val, triggerCallback)
			local fraction = math.clamp((val - slider.values[1]) / (slider.values[2] - slider.values[1]), 0, 1)
			local sobj = sliderObjects[slider.name]
			if sobj then
				sobj.fill.Size = UDim2.new(fraction, 0, 1, 0)
				sobj.lbl.Text = slider.name:sub(1,1):upper() .. slider.name:sub(2) .. " (" .. tostring(val) .. ")"
				slider.value = val
				if triggerCallback then
					slider.callback(val)
				end
			end
		end
		for _, slider in ipairs(siriusValues.sliders) do
			local slideFrame = Instance.new("Frame")
			slideFrame.Size = UDim2.new(1, 0, 0, 45)
			slideFrame.BackgroundTransparency = 1
			slideFrame.Parent = rightCont
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 20)
			lbl.BackgroundTransparency = 1
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			lbl.TextSize = 13
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			lbl.Text = slider.name:sub(1,1):upper() .. slider.name:sub(2) .. " (" .. tostring(slider.default) .. ")"
			lbl.Parent = slideFrame
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(1, 0, 0, 7)
			bar.Position = UDim2.new(0, 0, 0.60, 0)
			bar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
			bar.BorderSizePixel = 0
			bar.Parent = slideFrame
			local barCorner = Instance.new("UICorner", bar)
			barCorner.CornerRadius = UDim.new(1, 0)

			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(0.5, 0, 1, 0)
			fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			fill.BorderSizePixel = 0
			fill.Parent = bar
			local fillCorner = Instance.new("UICorner", fill)
			fillCorner.CornerRadius = UDim.new(1, 0)

			local fillGrad = Instance.new("UIGradient", fill)
			fillGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(32, 32, 34)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 48, 50)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 160, 165))
			})

			local knob = Instance.new("Frame", fill)
			knob.Size = UDim2.new(0, 14, 0, 14)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.new(1, 0, 0.5, 0)
			knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knob.BackgroundTransparency = 0
			knob.BorderSizePixel = 0
			local knobCorner = Instance.new("UICorner", knob)
			knobCorner.CornerRadius = UDim.new(1, 0)
			local knobStroke = Instance.new("UIStroke", knob)
			knobStroke.Color = Color3.fromRGB(160, 160, 165)
			knobStroke.Transparency = 0.35
			knobStroke.Thickness = 1.4

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 4, 0)
			btn.Position = UDim2.new(0, 0, -1.5, 0)
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.Active = true
			btn.Parent = bar
			sliderObjects[slider.name] = {fill = fill, lbl = lbl}
			local function update(input)
				local fraction = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				tweenService:Create(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(fraction, 0, 1, 0)}):Play()
				local val = slider.values[1] + math.round(fraction * (slider.values[2] - slider.values[1]))
				lbl.Text = slider.name:sub(1,1):upper() .. slider.name:sub(2) .. " (" .. tostring(val) .. ")"
				slider.value = val
				slider.callback(val)
			end
			local sliding = false
			btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					tweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 0.45}):Play()
					tweenService:Create(knobStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.1, Thickness = 1.8}):Play()
					update(input)
				end
			end)
			userInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					update(input)
				end
			end)
			userInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if sliding then
						sliding = false
						tweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0}):Play()
						tweenService:Create(knobStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.35, Thickness = 1.4}):Play()
						saveSettings()
					end
				end
			end)
			updateSlider(slider, slider.value or slider.default, false)
		end
		local function resetSliders()
			for _, slider in ipairs(siriusValues.sliders) do
				updateSlider(slider, slider.default, true)
			end
			saveSettings()
			queueNotification("Reset Customizations", "Successfully reset all character customizations.")
		end
		ResetCustomsBtn.MouseEnter:Connect(function()
			tweenService:Create(ResetCustomsBtn, TweenInfo.new(0.3), {ImageTransparency = 0.3}):Play()
		end)
		ResetCustomsBtn.MouseLeave:Connect(function()
			tweenService:Create(ResetCustomsBtn, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
		end)
		ResetCustomsBtn.MouseButton1Click:Connect(function()
			resetSliders()
			tweenService:Create(ResetCustomsBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Rotation = ResetCustomsBtn.Rotation + 360}):Play()
		end)
	end
	end
	_init_block_10673()
end

do
	local function _init_block_10813()
	local rightCont = CharacterTab:FindFirstChild("RightContainer")
	if rightCont then
		local function createButton(txt, callback, color)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -2, 0, 33)
			btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 13
			btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			btn.Text = txt
			btn.Parent = rightCont
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 5)
			corner.Parent = btn
			local btnBorder = Instance.new("Frame", btn)
			btnBorder.Name = "BorderFrame"
			btnBorder.Size = UDim2.new(1, 0, 1, 0)
			btnBorder.BackgroundTransparency = 1
			local btnBorderCorner = Instance.new("UICorner", btnBorder)
			btnBorderCorner.CornerRadius = UDim.new(0, 5)
			local stroke = Instance.new("UIStroke", btnBorder)
			stroke.Color = Color3.fromRGB(40, 40, 42)
			stroke.Thickness = 0.99
			btn.MouseButton1Click:Connect(callback)
		end
		createButton("Rejoin Server", rejoin, Color3.fromRGB(152, 90, 20))
		createButton("Serverhop", serverhop, Color3.fromRGB(20, 100, 150))
	end
	end
	_init_block_10813()
end

-- Fix all existing UIStrokes before parenting, then hook future ones
for _, desc in ipairs(G2L["1"]:GetDescendants()) do
	if desc:IsA("UIStroke") then
		local p = desc.Parent
		if p and (p:IsA("TextBox") or p:IsA("TextLabel") or p:IsA("TextButton")) then
			desc.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end
	end
end
G2L["1"].DescendantAdded:Connect(function(desc)
	if desc:IsA("UIStroke") then
		local p = desc.Parent
		if p and (p:IsA("TextBox") or p:IsA("TextLabel") or p:IsA("TextButton")) then
			desc.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end
	end
end)

-- Parent the fully-built UI tree to the GUI host in one shot
G2L["1"].Parent = gethui and gethui() or coreGui;

function GetPlayer(UserDisplay)
	if not UserDisplay or UserDisplay == "" then return nil end
	local searchTerm = UserDisplay:lower()
	local exactMatch = nil
	local partialMatches = {}
	for _, v in ipairs(players:GetPlayers()) do
		local nameLower = v.Name:lower()
		local displayNameLower = v.DisplayName:lower()
		if nameLower == searchTerm or displayNameLower == searchTerm then
			exactMatch = v
			break
		end
		if nameLower:find(searchTerm, 1, true) or displayNameLower:find(searchTerm, 1, true) then
			table.insert(partialMatches, v)
		end
	end
	if exactMatch then return exactMatch end
	if #partialMatches > 0 then return partialMatches[1] end
	return nil
end
function TeleportTO(player)
	pcall(function()
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local targetChar = player.Character
		local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		if hrp and targetHRP then
			local yRot = select(2, hrp.CFrame:ToEulerAnglesYXZ())
			hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, yRot, 0)
		end
	end)
end
function updateFriendsList()
	local FriendsCount = G2L["10"]
	local scroll = G2L["11"]
	local template = G2L["12"]
	if not FriendsCount or not scroll or not template then return end
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "FriendButtonTemplate" then
			child:Destroy()
		end
	end
	task.spawn(function()
		local function joinFriend(userId, displayName)
			queueNotification("Teleporting", "Locating " .. displayName .. "...")
			local reqFunc = request or http_request or (syn and syn.request)
			if reqFunc then
				local success, res = pcall(reqFunc, {
					Url = "https://presence.roblox.com/v1/presence/users",
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json"
					},
					Body = httpService:JSONEncode({ userIds = { tonumber(userId) } })
				})
				if success and res and res.StatusCode == 200 then
					local decodeOk, payload = pcall(httpService.JSONDecode, httpService, res.Body)
					if decodeOk and payload and payload.userPresences and payload.userPresences[1] then
						local presence = payload.userPresences[1]
						local pType = presence.userPresenceType
						if (pType == 2 or pType == 3) and presence.placeId and presence.placeId ~= 0 then
							local instId = presence.gameId
							if instId and instId ~= "" then
								pcall(function()
									teleportService:TeleportToPlaceInstance(presence.placeId, instId, localPlayer)
								end)
							else
								pcall(function()
									teleportService:Teleport(presence.placeId, localPlayer)
								end)
							end
							return
						end
					end
				end
			end
			queueNotification("Teleport Error", displayName .. " is not in a joinable game.")
		end

		local friendsMap = {}
		local allFriends = {}
		local successFriends, page = pcall(players.GetFriendsAsync, players, localPlayer.UserId)
		if successFriends and page then
			repeat
				local current = page:GetCurrentPage()
				for _, f in ipairs(current) do
					table.insert(allFriends, f)
					friendsMap[tostring(f.Id)] = f
				end
				if not page.IsFinished then
					pcall(page.AdvanceToNextPageAsync, page)
				end
			until page.IsFinished
		end

		local onlineFriends = {}
		local successOnline, result = pcall(function()
			return localPlayer:GetFriendsOnlineAsync(200)
		end)
		if successOnline and result then
			for _, friend in ipairs(result) do
				table.insert(onlineFriends, {
					userId = friend.VisitorId,
					username = friend.UserName,
					displayName = friend.DisplayName,
					presence = {
						UserPresenceType = friend.LocationType,
						placeId = friend.PlaceId,
						gameId = friend.GameId,
						lastLocation = friend.LastLocation
					}
				})
			end
		end

		FriendsCount.Text = tostring(#onlineFriends) .. " Friends Online"

		local rendered = {}
		for _, friend in ipairs(onlineFriends) do
			rendered[tostring(friend.userId)] = true
			local friendCard = template:Clone()
			friendCard.Name = friend.username
			friendCard.Visible = true
			local lbl = friendCard:FindFirstChild("PlayerNameLabel")
			if lbl then
				lbl.Text = friend.displayName .. " (@" .. friend.username .. ")"
			end
			local thumbFrame = friendCard:FindFirstChild("FriendThumbnail")
			if thumbFrame then
				local img = Instance.new("ImageLabel", thumbFrame)
				img.Size = UDim2.new(1, 0, 1, 0)
				img.BackgroundTransparency = 1
				img.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. friend.userId .. "&width=150&height=150&format=png"
				Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
			end
			local presence = friend.presence
			local pType = presence.UserPresenceType or presence.userPresenceType

			if (pType == 2 or pType == "InGame" or pType == 3 or pType == "InStudio") and presence.placeId and presence.placeId ~= 0 then
				local joinBtn = Instance.new("TextButton", friendCard)
				joinBtn.Size = UDim2.new(0, 62, 0, 26)
				joinBtn.Position = UDim2.new(1, -93, 0.5, -13)
				joinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
				joinBtn.BorderSizePixel = 0
				joinBtn.AutoButtonColor = false
				joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				joinBtn.Text = "Join"
				joinBtn.TextSize = 12
				joinBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
				Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)
				local jStroke = Instance.new("UIStroke", joinBtn)
				jStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				jStroke.Color = Color3.fromRGB(40, 40, 42)
				jStroke.Transparency = 0.5
				joinBtn.MouseEnter:Connect(function()
					tweenService:Create(joinBtn, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(36, 36, 40)}):Play()
					tweenService:Create(jStroke, TweenInfo.new(0.14), {Transparency = 0.15}):Play()
				end)
				joinBtn.MouseLeave:Connect(function()
					tweenService:Create(joinBtn, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(24, 24, 27)}):Play()
					tweenService:Create(jStroke, TweenInfo.new(0.14), {Transparency = 0.5}):Play()
				end)
				joinBtn.MouseButton1Click:Connect(function()
					queueNotification("Teleporting", "Joining " .. friend.displayName)
					local instId = presence.gameInstanceId or presence.gameId
					if instId and instId ~= "" then
						pcall(function()
							teleportService:TeleportToPlaceInstance(presence.placeId, instId, localPlayer)
						end)
					else
						pcall(function()
							teleportService:Teleport(presence.placeId, localPlayer)
						end)
					end
				end)
			else
				local joinBtn = Instance.new("TextButton", friendCard)
				joinBtn.Size = UDim2.new(0, 62, 0, 26)
				joinBtn.Position = UDim2.new(1, -93, 0.5, -13)
				joinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
				joinBtn.BorderSizePixel = 0
				joinBtn.AutoButtonColor = false
				joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				joinBtn.Text = "Join"
				joinBtn.TextSize = 12
				joinBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
				Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)
				local jStroke = Instance.new("UIStroke", joinBtn)
				jStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				jStroke.Color = Color3.fromRGB(40, 40, 42)
				jStroke.Transparency = 0.5
				joinBtn.MouseEnter:Connect(function()
					tweenService:Create(joinBtn, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(36, 36, 40)}):Play()
					tweenService:Create(jStroke, TweenInfo.new(0.14), {Transparency = 0.15}):Play()
				end)
				joinBtn.MouseLeave:Connect(function()
					tweenService:Create(joinBtn, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(24, 24, 27)}):Play()
					tweenService:Create(jStroke, TweenInfo.new(0.14), {Transparency = 0.5}):Play()
				end)
				joinBtn.MouseButton1Click:Connect(function()
					joinFriend(friend.userId, friend.displayName)
				end)
			end
			local dot = Instance.new("Frame", friendCard)
			dot.Size = UDim2.new(0, 8, 0, 8)
			dot.Position = UDim2.new(1, -20, 0.5, -4)
			local dotColor = Color3.fromRGB(255, 255, 255)
			if pType == 2 or pType == "InGame" then
				dotColor = Color3.fromRGB(200, 200, 205)
			elseif pType == 3 or pType == "InStudio" then
				dotColor = Color3.fromRGB(240, 170, 70)
			elseif pType == 1 or pType == "Online" then
				dotColor = Color3.fromRGB(24, 24, 27)
			end
			dot.BackgroundColor3 = dotColor
			Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
			friendCard.Parent = scroll
		end

		for _, friend in ipairs(allFriends) do
			local fIdStr = tostring(friend.Id)
			if not rendered[fIdStr] then
				local friendCard = template:Clone()
				friendCard.Name = friend.Username
				friendCard.Visible = true
				local lbl = friendCard:FindFirstChild("PlayerNameLabel")
				if lbl then
					lbl.Text = friend.DisplayName .. " (@" .. friend.Username .. ")"
				end
				local thumbFrame = friendCard:FindFirstChild("FriendThumbnail")
				if thumbFrame then
					local img = Instance.new("ImageLabel", thumbFrame)
					img.Size = UDim2.new(1, 0, 1, 0)
					img.BackgroundTransparency = 1
					img.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. friend.Id .. "&width=150&height=150&format=png"
					Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
				end
				local joinBtn = Instance.new("TextButton", friendCard)
				joinBtn.Size = UDim2.new(0, 62, 0, 26)
				joinBtn.Position = UDim2.new(1, -93, 0.5, -13)
				joinBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
				joinBtn.BorderSizePixel = 0
				joinBtn.AutoButtonColor = false
				joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				joinBtn.Text = "Join"
				joinBtn.TextSize = 12
				joinBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
				Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)
				local jStroke = Instance.new("UIStroke", joinBtn)
				jStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				jStroke.Color = Color3.fromRGB(40, 40, 42)
				jStroke.Transparency = 0.5
				joinBtn.MouseEnter:Connect(function()
					tweenService:Create(joinBtn, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(36, 36, 40)}):Play()
					tweenService:Create(jStroke, TweenInfo.new(0.14), {Transparency = 0.15}):Play()
				end)
				joinBtn.MouseLeave:Connect(function()
					tweenService:Create(joinBtn, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(24, 24, 27)}):Play()
					tweenService:Create(jStroke, TweenInfo.new(0.14), {Transparency = 0.5}):Play()
				end)
				joinBtn.MouseButton1Click:Connect(function()
					joinFriend(friend.Id, friend.DisplayName)
				end)

				local dot = Instance.new("Frame", friendCard)
				dot.Size = UDim2.new(0, 8, 0, 8)
				dot.Position = UDim2.new(1, -20, 0.5, -4)
				dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
				friendCard.Parent = scroll
			end
		end
	end)
end
updateFriendsList()

do
	local refreshBtn = G2L["c"] and G2L["c"]:FindFirstChild("RefreshBtn")
	if refreshBtn then
		refreshBtn.MouseEnter:Connect(function()
			tweenService:Create(refreshBtn, TweenInfo.new(0.3), {ImageTransparency = 0.3}):Play()
		end)
		refreshBtn.MouseLeave:Connect(function()
			tweenService:Create(refreshBtn, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
		end)
		refreshBtn.MouseButton1Click:Connect(function()
			tweenService:Create(refreshBtn, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Rotation = refreshBtn.Rotation + 360}):Play()
			updateFriendsList()
		end)
	end
	local searchBar = G2L["19"]
	local scroll = G2L["11"]
	if searchBar and scroll then
		searchBar:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBar.Text:lower()
			for _, child in ipairs(scroll:GetChildren()) do
				if child:IsA("Frame") and child.Name ~= "FriendButtonTemplate" then
					if query == "" or child.Name:lower():find(query) then
						child.Visible = true
					else
						child.Visible = false
					end
				end
			end
		end)
	end
	local copyBtn = G2L["2c"]
	if copyBtn then
		copyBtn.MouseButton1Click:Connect(function()
			if setclipboard then
				setclipboard("https://discord.gg/sl8")
				queueNotification("Clipboard", "Discord link copied!")
			end
		end)
	end
end

function createHighlight(player)
	if player == localPlayer then return end
	local highlight = espContainer:FindFirstChild(player.Name)
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = player.Name
		highlight.FillColor = Color3.fromRGB(255, 255, 255)
		highlight.OutlineColor = Color3.fromRGB(30, 125, 185)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0

		highlight.Enabled = false
		highlight.Parent = espContainer
	end
	local char = player.Character
	if char then
		highlight.Adornee = char
	end

	if not EspConfig then
		highlight.Enabled = siriusValues.actions[7].enabled or locatedPlayers[player.Name] == true
	end
end
function hookPlayerESP(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		local highlight = espContainer:FindFirstChild(player.Name)
		if highlight then highlight.Adornee = char end
	end)
end
for _, p in ipairs(players:GetPlayers()) do
	hookPlayerESP(p)
end
players.PlayerAdded:Connect(hookPlayerESP)

task.spawn(function()
	while true do
		for _, player in ipairs(players:GetPlayers()) do
			if player ~= localPlayer then createHighlight(player) end
		end
		task.wait(1.5)
	end
end)

do
local updateEmptyPlayerState
function createPlayerListCard(player)
	local scroll = PlayersScroll or (PlayersTab and PlayersTab:FindFirstChild("PlayersScroll")) or (PlayersTab and PlayersTab:FindFirstChildOfClass("ScrollingFrame"))
	if not scroll then return end

	local isExpanded = false
	local frame = Instance.new("Frame", scroll)
	frame.Name = player.Name
	frame.Size = UDim2.new(1, -10, 0, 56)
	frame.ClipsDescendants = true
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	frame.BorderSizePixel = 0

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(28, 28, 28)
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	frame.MouseEnter:Connect(function()
		if not isExpanded then
			tweenService:Create(frame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
			tweenService:Create(stroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(45, 45, 45)}):Play()
		end
	end)
	frame.MouseLeave:Connect(function()
		if not isExpanded then
			tweenService:Create(frame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(15, 15, 15)}):Play()
			tweenService:Create(stroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(28, 28, 28)}):Play()
		end
	end)

	local headerBtn = Instance.new("TextButton", frame)
	headerBtn.Size = UDim2.new(1, 0, 0, 56)
	headerBtn.BackgroundTransparency = 1
	headerBtn.Text = ""

	local thumbFrame = Instance.new("Frame", frame)
	thumbFrame.Name = "FriendThumbnail"
	thumbFrame.Size = UDim2.new(0, 38, 0, 38)
	thumbFrame.Position = UDim2.new(0, 10, 0, 9)
	thumbFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	thumbFrame.BorderSizePixel = 0

	Instance.new("UICorner", thumbFrame).CornerRadius = UDim.new(1, 0)
	local tStroke = Instance.new("UIStroke", thumbFrame)
	tStroke.Color = Color3.fromRGB(32, 32, 32)
	tStroke.Thickness = 1.2

	local img = Instance.new("ImageLabel", thumbFrame)
	img.Size = UDim2.new(1, 0, 1, 0)
	img.BackgroundTransparency = 1
	img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)

	local title = Instance.new("TextLabel", frame)
	title.Name = "PlayerNameLabel"
	title.Size = UDim2.new(1, -120, 0, 18)
	title.Position = UDim2.new(0, 58, 0, 11)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = player.DisplayName

	local sub = Instance.new("TextLabel", frame)
	sub.Size = UDim2.new(1, -120, 0, 14)
	sub.Position = UDim2.new(0, 58, 0, 29)
	sub.BackgroundTransparency = 1
	sub.TextColor3 = Color3.fromRGB(120, 120, 120)
	sub.Font = Enum.Font.SourceSans
	sub.TextSize = 11
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.TextTruncate = Enum.TextTruncate.AtEnd
	sub.Text = "@" .. player.Name .. " • Click to toggle actions"

	local actionsContainer = Instance.new("Frame", frame)
	actionsContainer.Name = "ExpandedActions"
	actionsContainer.Size = UDim2.new(1, -20, 0, 48)
	actionsContainer.Position = UDim2.new(0, 10, 0, 58)
	actionsContainer.BackgroundTransparency = 1

	local aLayout = Instance.new("UIListLayout", actionsContainer)
	aLayout.FillDirection = Enum.FillDirection.Horizontal
	aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	aLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	aLayout.Padding = UDim.new(0, 12)

	local function makeIconBtn(iconId, toolTip, callback)
		local b = Instance.new("ImageButton", actionsContainer)
		b.Size = UDim2.new(0, 40, 0, 40)
		b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		b.Image = "rbxthumb://type=Asset&id=" .. tostring(iconId) .. "&w=420&h=420"
		b.ImageColor3 = Color3.fromRGB(240, 240, 245)
		b.ScaleType = Enum.ScaleType.Fit

		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		local s = Instance.new("UIStroke", b)
		s.Thickness = 1
		s.Color = Color3.fromRGB(45, 45, 52)

		b.MouseEnter:Connect(function()
			tweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
			tweenService:Create(s, TweenInfo.new(0.12), {Color = Color3.fromRGB(70, 70, 80)}):Play()
		end)
		b.MouseLeave:Connect(function()
			tweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}):Play()
			tweenService:Create(s, TweenInfo.new(0.12), {Color = Color3.fromRGB(45, 45, 52)}):Play()
		end)

		b.MouseButton1Click:Connect(function() callback(b) end)
		return b
	end

	makeIconBtn(102819382107866, "Teleport", function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root and myRoot then
			myRoot.CFrame = root.CFrame * CFrame.new(0, 0, 3)
		end
	end)

	local isViewing = false
	makeIconBtn(126439761728978, "View", function(b)
		isViewing = not isViewing
		if isViewing then
			if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
				workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
				b.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
			end
		else
			if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
				workspace.CurrentCamera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
			end
			b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		end
	end)

	local isHidden = false
	local hideBtn = makeIconBtn(86206257834504, "Hide", function(b)
		isHidden = not isHidden
		if isHidden then
			if hidePlayer then hidePlayer(player) end
			b.Image = "rbxthumb://type=Asset&id=100086900641425&w=420&h=420"
			b.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		else
			if unhidePlayer then unhidePlayer(player) end
			b.Image = "rbxthumb://type=Asset&id=86206257834504&w=420&h=420"
			b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		end
	end)

	local isMuted = false
	local muteBtn = makeIconBtn(126302766179822, "Mute", function(b)
		isMuted = not isMuted
		if setPlayerVoiceMuted then
			setPlayerVoiceMuted(player.UserId, isMuted)
		end
		if isMuted then
			b.Image = "rbxthumb://type=Asset&id=116911812027848&w=420&h=420"
			b.BackgroundColor3 = Color3.fromRGB(180, 90, 30)
		else
			b.Image = "rbxthumb://type=Asset&id=126302766179822&w=420&h=420"
			b.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		end
	end)

	makeIconBtn(77913721129068, "Track", function(b)
		locatedPlayers[player.Name] = not locatedPlayers[player.Name] or nil
		local isLoc = locatedPlayers[player.Name] == true
		createHighlight(player)
		local highlight = espContainer:FindFirstChild(player.Name)
		if highlight then highlight.Enabled = isLoc or siriusValues.actions[7].enabled end
		b.BackgroundColor3 = isLoc and Color3.fromRGB(0, 140, 200) or Color3.fromRGB(22, 22, 26)
		queueNotification("Locate Player", (isLoc and "Tracking " or "Stopped tracking ") .. player.DisplayName)
	end)

	headerBtn.MouseButton1Click:Connect(function()
		isExpanded = not isExpanded
		local targetHeight = isExpanded and 114 or 56
		tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -10, 0, targetHeight),
			BackgroundColor3 = isExpanded and Color3.fromRGB(20, 20, 22) or Color3.fromRGB(15, 15, 15)
		}):Play()
	end)
	updateEmptyPlayerState()
end

updateEmptyPlayerState = function()
	local scroll = PlayersScroll or (PlayersTab and PlayersTab:FindFirstChild("PlayersScroll")) or (PlayersTab and PlayersTab:FindFirstChildOfClass("ScrollingFrame"))
	if not scroll then return end
	local emptyLbl = scroll:FindFirstChild("EmptyPlayersLabel")
	local cardCount = 0
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "EmptyPlayersLabel" then
			cardCount = cardCount + 1
		end
	end
	if cardCount == 0 then
		if not emptyLbl then
			emptyLbl = Instance.new("TextLabel")
			emptyLbl.Name = "EmptyPlayersLabel"
			emptyLbl.Size = UDim2.new(1, -10, 0, 50)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "No other players in server."
			emptyLbl.TextColor3 = Color3.fromRGB(130, 130, 135)
			emptyLbl.Font = Enum.Font.SourceSans
			emptyLbl.TextSize = 13
			emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
			emptyLbl.Parent = scroll
		end
		emptyLbl.Visible = true
	else
		if emptyLbl then
			emptyLbl.Visible = false
		end
	end
end

function removePlayerCard(player)
	local scroll = PlayersScroll or (PlayersTab and PlayersTab:FindFirstChild("PlayersScroll")) or (PlayersTab and PlayersTab:FindFirstChildOfClass("ScrollingFrame"))
	if not scroll then return end
	local card = scroll:FindFirstChild(player.Name)
	if card then card:Destroy() end
	updateEmptyPlayerState()
end

local function onPlayerAddedToList(player)
	if player ~= localPlayer then
		createPlayerListCard(player)
		updateEmptyPlayerState()
	end
end

for _, p in ipairs(players:GetPlayers()) do
	if p ~= localPlayer then createPlayerListCard(p) end
end
updateEmptyPlayerState()

players.PlayerAdded:Connect(onPlayerAddedToList)
players.PlayerRemoving:Connect(removePlayerCard)

end
function refreshSpotifyToken()
	local refreshSet = checkSetting("spotifyrefreshtoken")

	if not refreshSet or refreshSet.current == "" then
		return false
	end
	local reqFunc = http_request or request or (syn and syn.request)
	if not reqFunc then return false end

	local reqBody = "grant_type=refresh_token&refresh_token=" .. refreshSet.current
	local clientidSet    = checkSetting("spotifyclientid")
	local clientsecretSet = checkSetting("spotifyclientsecret")
	if clientidSet and clientidSet.current ~= "" then
		reqBody = reqBody .. "&client_id=" .. clientidSet.current
	end
	if clientsecretSet and clientsecretSet.current ~= "" then
		reqBody = reqBody .. "&client_secret=" .. clientsecretSet.current
	end
	local success, res = pcall(reqFunc, {
		Url = "https://accounts.spotify.com/api/token",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/x-www-form-urlencoded"
		},
		Body = reqBody
	})
	if success and res and res.StatusCode == 200 then
		local ok, data = pcall(httpService.JSONDecode, httpService, res.Body)
		if ok and data and data.access_token then
			local tokenSetting = checkSetting("spotifyoauthtoken")
			if tokenSetting then
				tokenSetting.current = data.access_token

				if data.refresh_token and data.refresh_token ~= "" and refreshSet then
					refreshSet.current = data.refresh_token
				end
				saveSettings()
				return true
			end
		end
	end
	return false
end

local SlateMusic = {
	currentTrack = nil,
	isPlaying = false,
	queue = {},
	queueIndex = 1,
	sound = nil,
	volume = 0.75,
	repeatMode = "off",
	isLooping = false,
	isShuffle = false,
	currentProgress = 0,
	totalDuration = 0,
	lastCoverUrl = "",
	clientId = "UMY1dzQ68n2QbCuypNe8JOivmV2FO2Ep",
	clientSecret = "yPVntADVmZcCNqlKO4bShRgaWTj5slPe",
	fallbackClientId = "iZIs9mchVcX5lhVR1KfMrUpUqbmWhbmA",
	customApiKey = "",

	eq = nil,
	eqEnabled = false,
	eqPreset = "Flat",
	eqBands = { low = 0, mid = 0, high = 0 },

	searchSort = "best",
	playlists = {
		["Favorites"] = {}
	}
}

SlateMusic.eqPresets = {
	{ name = "Flat",       low = 0,   mid = 0,   high = 0 },
	{ name = "Bass Boost", low = 8,   mid = -2,  high = -3 },
	{ name = "Deep Bass",  low = 10,  mid = -6,  high = -8 },
	{ name = "Vocal",      low = -6,  mid = 6,   high = 1 },
	{ name = "Treble",     low = -5,  mid = -1,  high = 8 },
	{ name = "Loudness",   low = 7,   mid = -4,  high = 6 },
	{ name = "Soft",       low = 2,   mid = -3,  high = -6 },
	{ name = "Radio",      low = -14, mid = 8,   high = -10 },
}

function SlateMusic.ensureFolders()
	pcall(function()
		if makefolder then
			if not (isfolder and isfolder("slate")) then pcall(makefolder, "slate") end
			if not (isfolder and isfolder("slate/music")) then pcall(makefolder, "slate/music") end
			if not (isfolder and isfolder("slate/music/cache")) then pcall(makefolder, "slate/music/cache") end
			if not (isfolder and isfolder("slate/music/thumbs")) then pcall(makefolder, "slate/music/thumbs") end
		end
	end)
end

function SlateMusic.loadPlaylists()
	pcall(function()
		SlateMusic.ensureFolders()
		local file = "slate/music/playlists.json"
		if isfile and isfile(file) then
			local content = readfile(file)
			if content and content ~= "" then
				local ok, data = pcall(function() return httpService:JSONDecode(content) end)
				if ok and type(data) == "table" then
					SlateMusic.playlists = data
				end
			end
		end
		if not SlateMusic.playlists["Favorites"] then
			SlateMusic.playlists["Favorites"] = {}
		end
		if SlateMusic.playlists["Liked Songs"] then
			for _, trk in ipairs(SlateMusic.playlists["Liked Songs"]) do
				local exists = false
				for _, fav in ipairs(SlateMusic.playlists["Favorites"]) do
					if fav.id == trk.id then exists = true; break end
				end
				if not exists then table.insert(SlateMusic.playlists["Favorites"], trk) end
			end
			SlateMusic.playlists["Liked Songs"] = nil
			SlateMusic.savePlaylists()
		end
	end)
end

local _savePlaylistsDebounce = false
SlateMusic.savePlaylists = (function()
	if _savePlaylistsDebounce then return end
	_savePlaylistsDebounce = true
	task.delay(0.3, function()
		_savePlaylistsDebounce = false
		task.spawn(function()
			pcall(function()
				SlateMusic.ensureFolders()
				local file = "slate/music/playlists.json"
				if writefile then
					local ok, jsonStr = pcall(httpService.JSONEncode, httpService, SlateMusic.playlists)
					if ok and jsonStr then
						writefile(file, jsonStr)
					end
				end
			end)
		end)
	end)
end)

function SlateMusic.getEqPreset(name)
	for _, p in ipairs(SlateMusic.eqPresets) do
		if p.name == name then return p end
	end
	return nil
end

function SlateMusic.loadEq()
	pcall(function()
		SlateMusic.ensureFolders()
		local file = "slate/music/equalizer.json"
		if isfile and isfile(file) then
			local content = readfile(file)
			if content and content ~= "" then
				local ok, data = pcall(function() return httpService:JSONDecode(content) end)
				if ok and type(data) == "table" then
					SlateMusic.eqEnabled = data.enabled == true
					SlateMusic.eqPreset = data.preset or "Flat"
					if type(data.bands) == "table" then
						SlateMusic.eqBands = {
							low = tonumber(data.bands.low) or 0,
							mid = tonumber(data.bands.mid) or 0,
							high = tonumber(data.bands.high) or 0
						}
					end
				end
			end
		end
	end)
end

local _saveEqDebounce = false
SlateMusic.saveEq = (function()
	if _saveEqDebounce then return end
	_saveEqDebounce = true
	task.delay(0.3, function()
		_saveEqDebounce = false
		pcall(function()
			SlateMusic.ensureFolders()
			if writefile then
				local ok, jsonStr = pcall(httpService.JSONEncode, httpService, {
					enabled = SlateMusic.eqEnabled,
					preset = SlateMusic.eqPreset,
					bands = SlateMusic.eqBands
				})
				if ok and jsonStr then writefile("slate/music/equalizer.json", jsonStr) end
			end
		end)
	end)
end)

SlateMusic.applyEq = (function()
	local snd = SlateMusic.sound
	if not snd then return end
	pcall(function()
		local fx = SlateMusic.eq
		if not fx or not fx.Parent then
			fx = snd:FindFirstChild("SlateMusicEQ")
			if not fx then
				fx = Instance.new("EqualizerSoundEffect")
				fx.Name = "SlateMusicEQ"
				fx.Parent = snd
			end
			SlateMusic.eq = fx
		end
		local b = SlateMusic.eqBands or { low = 0, mid = 0, high = 0 }
		if SlateMusic.eqEnabled then
			fx.LowGain = math.clamp(tonumber(b.low) or 0, -80, 10)
			fx.MidGain = math.clamp(tonumber(b.mid) or 0, -80, 10)
			fx.HighGain = math.clamp(tonumber(b.high) or 0, -80, 10)
			fx.Enabled = true
		else
			fx.LowGain = 0
			fx.MidGain = 0
			fx.HighGain = 0
			fx.Enabled = false
		end
	end)
	if _G.SlateSyncEqUI then pcall(_G.SlateSyncEqUI) end
end)

SlateMusic.setEqPreset = (function(name)
	local preset = SlateMusic.getEqPreset(name)
	if not preset then return false end
	SlateMusic.eqPreset = preset.name
	SlateMusic.eqBands = { low = preset.low, mid = preset.mid, high = preset.high }
	if preset.name ~= "Flat" then SlateMusic.eqEnabled = true end
	SlateMusic.applyEq()
	SlateMusic.saveEq()
	return true
end)

SlateMusic.setEqBand = (function(band, value)
	if band ~= "low" and band ~= "mid" and band ~= "high" then return end
	SlateMusic.eqBands = SlateMusic.eqBands or { low = 0, mid = 0, high = 0 }
	SlateMusic.eqBands[band] = math.clamp(tonumber(value) or 0, -80, 10)
	SlateMusic.eqPreset = "Custom"
	SlateMusic.eqEnabled = true
	SlateMusic.applyEq()
	SlateMusic.saveEq()
end)

SlateMusic.toggleEq = (function()
	SlateMusic.eqEnabled = not SlateMusic.eqEnabled
	SlateMusic.applyEq()
	SlateMusic.saveEq()
	queueNotification("Equalizer", SlateMusic.eqEnabled and ("Equalizer: On (" .. tostring(SlateMusic.eqPreset) .. ")") or "Equalizer: Off", 2)
	return SlateMusic.eqEnabled
end)

SlateMusic.resetEq = (function()
	SlateMusic.eqPreset = "Flat"
	SlateMusic.eqBands = { low = 0, mid = 0, high = 0 }
	SlateMusic.eqEnabled = false
	SlateMusic.applyEq()
	SlateMusic.saveEq()
end)

SlateMusic.init = (function()
	if not SlateMusic.sound then
		local s = game:GetService("SoundService"):FindFirstChild("SlateMusicAudio")
		if not s then
			s = Instance.new("Sound")
			s.Name = "SlateMusicAudio"
			s.Volume = SlateMusic.volume
			s.Looped = false
			s.Parent = game:GetService("SoundService")
		end
		SlateMusic.sound = s

		SlateMusic.loadEq()
		SlateMusic.applyEq()

		s.Ended:Connect(function()
			if SlateMusic.repeatMode == "one" then
				pcall(function()
					s:Stop()
					s.TimePosition = 0
					s.Volume = SlateMusic.volume
					s:Play()
				end)
				SlateMusic.isPlaying = true
				SlateMusic.updatePlayButtons(true)
				if _G.SlateSetSpotifyPlaying then _G.SlateSetSpotifyPlaying(true) end
			else
				SlateMusic.next()
			end
		end)
	end

	SlateMusic.ensureFolders()
	SlateMusic.loadPlaylists()
end)

task.spawn(function()
	SlateMusic.init()
end)

function SlateMusic.toggleFavorite(track)
	if not track or not track.id then return false end
	local list = SlateMusic.playlists["Favorites"] or {}
	local foundIdx = nil
	for i, t in ipairs(list) do
		if t.id == track.id then
			foundIdx = i
			break
		end
	end
	if foundIdx then
		table.remove(list, foundIdx)
		SlateMusic.playlists["Favorites"] = list
		SlateMusic.savePlaylists()
		return false
	else
		table.insert(list, track)
		SlateMusic.playlists["Favorites"] = list
		SlateMusic.savePlaylists()
		return true
	end
end

function SlateMusic.isFavorite(track)
	if not track or not track.id then return false end
	local list = SlateMusic.playlists["Favorites"] or {}
	for _, t in ipairs(list) do
		if t.id == track.id then return true end
	end
	return false
end

SlateMusic.urlEncode = (function(str)
	if not str then return "" end
	str = tostring(str)
	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w %-%_%.%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	str = str:gsub(" ", "+")
	return str
end)

SlateMusic.fetchUrl = (function(url)
	local reqFunc = http_request or request or (syn and syn.request) or (http and http.request)
	if reqFunc then
		local ok, res = pcall(reqFunc, { Url = url, Method = "GET" })
		if ok and res and res.Body then return res.Body end
	end
	if game.HttpGet then
		local ok, res = pcall(game.HttpGet, game, url)
		if ok and res then return res end
	end
	return nil
end)

function SlateMusic.isGoPlusItem(item)
	if not item then return false end
	local mm = item.monetization_model
	if mm == "SUB_HIGH_TIER" or mm == "SUB_MID_TIER" then return true end
	if item.policy == "SNIP" then return true end
	if item.media and item.media.transcodings then
		for _, tc in ipairs(item.media.transcodings) do
			if tc.snipped == true then return true end
			if tc.url and tostring(tc.url):find("/preview/", 1, true) then return true end
		end
	end
	return false
end

function SlateMusic.popularityScore(likes, plays, reposts)
	likes = tonumber(likes) or 0
	plays = tonumber(plays) or 0
	reposts = tonumber(reposts) or 0
	local score = 0
	if likes > 0 then score = score + (math.log10(likes + 1) * 130) end
	if plays > 0 then score = score + (math.log10(plays + 1) * 45) end
	if reposts > 0 then score = score + (math.log10(reposts + 1) * 15) end
	return score
end

function SlateMusic.buildTrackFromItem(item, qLower, queryHasRemix)
	if not item or not item.id or not item.title then return nil end

	local cover = item.artwork_url or (item.user and item.user.avatar_url) or ""
	if cover ~= "" then
		cover = cover:gsub("%-large", "-t500x500")
	end
	local artistName = (item.user and (item.user.username or item.user.full_name)) or "SoundCloud Artist"

	local durMs = item.duration or 180000
	if item.full_duration and item.full_duration > durMs then durMs = item.full_duration end
	local durSec = math.floor(durMs / 1000)

	local isGoPlus = SlateMusic.isGoPlusItem(item)
	local isPublisher = (item.publisher_metadata ~= nil and (item.publisher_metadata.isrc ~= nil or item.publisher_metadata.album_title ~= nil or item.publisher_metadata.artist ~= nil or item.publisher_metadata.p_line ~= nil))
	local isVerified = (item.user and (item.user.verified == true or (item.user.badges and item.user.badges.verified == true)))
	local isOfficial = isGoPlus or isPublisher or isVerified or (item.label_name ~= nil and item.label_name ~= "")

	local likes = tonumber(item.likes_count or item.favoritings_count) or 0
	local plays = tonumber(item.playback_count) or 0
	local reposts = tonumber(item.reposts_count) or 0

	local rankScore = 0
	if isGoPlus then rankScore = rankScore + 220 end
	if isPublisher then rankScore = rankScore + 200 end
	if isVerified then rankScore = rankScore + 150 end
	if item.label_name and item.label_name ~= "" then rankScore = rankScore + 100 end

	rankScore = rankScore + SlateMusic.popularityScore(likes, plays, reposts)

	local tTitle = (item.title or ""):lower()
	if tTitle == qLower then
		rankScore = rankScore + 300
	elseif tTitle:find(qLower, 1, true) == 1 then
		rankScore = rankScore + 150
	elseif tTitle:find(qLower, 1, true) then
		rankScore = rankScore + 80
	end

	if not queryHasRemix then
		local badTags = { "remix", "slowed", "sped up", "nightcore", "8d audio", "bass boosted", "bootleg", "type beat" }
		for _, tag in ipairs(badTags) do
			if tTitle:find(tag, 1, true) and not qLower:find(tag, 1, true) then
				rankScore = rankScore - 400
				break
			end
		end
	end

	return {
		id = "sc_" .. tostring(item.id):gsub("[^%w%-_]", "_"),
		title = item.title,
		artist = artistName,
		duration = durSec,
		coverUrl = cover,
		transcodings = item.media and item.media.transcodings,
		isGoPlus = isGoPlus,
		isOfficial = isOfficial,
		isSnippet = isGoPlus,
		likes = likes,
		plays = plays,
		reposts = reposts,
		rankScore = rankScore
	}
end

function SlateMusic.sortTracks(tracks, mode)
	mode = mode or SlateMusic.searchSort or "best"
	if mode == "likes" then
		table.sort(tracks, function(a, b)
			local al, bl = (a.likes or 0), (b.likes or 0)
			if al == bl then return (a.rankScore or 0) > (b.rankScore or 0) end
			return al > bl
		end)
	elseif mode == "plays" then
		table.sort(tracks, function(a, b)
			local ap, bp = (a.plays or 0), (b.plays or 0)
			if ap == bp then return (a.rankScore or 0) > (b.rankScore or 0) end
			return ap > bp
		end)
	else
		table.sort(tracks, function(a, b)
			local ar, br = (a.rankScore or 0), (b.rankScore or 0)
			if ar == br then return (a.likes or 0) > (b.likes or 0) end
			return ar > br
		end)
	end
	return tracks
end

function SlateMusic.buildArtistFromItem(item, qLower)
	if not item or not item.id then return nil end
	local name = item.username or item.full_name
	if not name or name == "" then return nil end

	local avatar = item.avatar_url or ""
	if avatar ~= "" then
		avatar = avatar:gsub("%-large", "-t200x200")
	end

	local followers = tonumber(item.followers_count) or 0
	local trackCount = tonumber(item.track_count) or 0
	local isVerified = (item.verified == true) or (item.badges and item.badges.verified == true) or false

	local rankScore = 0
	if isVerified then rankScore = rankScore + 2000 end
	if trackCount <= 0 then
		rankScore = rankScore - 3000
	else
		rankScore = rankScore + (math.log10(trackCount + 1) * 50)
	end
	if followers > 0 then rankScore = rankScore + (math.log10(followers + 1) * 380) end

	local nLower = name:lower()
	if qLower and qLower ~= "" then
		if nLower == qLower then
			rankScore = rankScore + 1500
		elseif nLower:find(qLower, 1, true) == 1 then
			rankScore = rankScore + 400
		elseif nLower:find(qLower, 1, true) then
			rankScore = rankScore + 200
		end
	end

	return {
		id = item.id,
		name = name,
		avatarUrl = avatar,
		followers = followers,
		trackCount = trackCount,
		verified = isVerified,
		city = item.city,
		country = item.country_code,
		permalink = item.permalink_url,
		rankScore = rankScore
	}
end

function SlateMusic.searchArtists(query, callback)
	task.spawn(function()
		SlateMusic.init()
		local encoded = SlateMusic.urlEncode(query)
		local qLower = (query or ""):lower()
		local artists = {}
		local seen = {}

		local url = "https://api-v2.soundcloud.com/search/users?q=" .. encoded .. "&client_id=" .. SlateMusic.clientId .. "&limit=20"
		local rawJson = SlateMusic.fetchUrl(url)
		if rawJson then
			local ok, data = pcall(httpService.JSONDecode, httpService, rawJson)
			if ok and data and data.collection then
				for _, item in ipairs(data.collection) do
					local a = SlateMusic.buildArtistFromItem(item, qLower)

					if a and a.trackCount > 0 and not seen[a.id] then
						seen[a.id] = true
						table.insert(artists, a)
					end
				end
			end
		end

		table.sort(artists, function(x, y)
			local xr, yr = (x.rankScore or 0), (y.rankScore or 0)
			if xr == yr then return (x.followers or 0) > (y.followers or 0) end
			return xr > yr
		end)

		while #artists > 5 do table.remove(artists) end

		SlateMusic.lastArtists = artists
		if callback then callback(artists) end
	end)
end

function SlateMusic.getArtistTracks(artist, callback)
	task.spawn(function()
		SlateMusic.init()
		local artistId = (type(artist) == "table") and artist.id or artist
		if not artistId then
			if callback then callback({}) end
			return
		end

		local nameLower = ((type(artist) == "table" and artist.name) or ""):lower()
		local tracks = {}
		local seen = {}

		local endpoints = {
			"https://api-v2.soundcloud.com/users/" .. tostring(artistId) .. "/toptracks?client_id=" .. SlateMusic.clientId .. "&limit=50",
			"https://api-v2.soundcloud.com/users/" .. tostring(artistId) .. "/tracks?client_id=" .. SlateMusic.clientId .. "&limit=50"
		}

		for _, url in ipairs(endpoints) do
			local rawJson = SlateMusic.fetchUrl(url)
			if rawJson then
				local ok, data = pcall(httpService.JSONDecode, httpService, rawJson)
				local collection = nil
				if ok and data then
					collection = data.collection or (data[1] and data) or nil
				end
				if collection then
					for _, item in ipairs(collection) do
						local trk = SlateMusic.buildTrackFromItem(item, nameLower, true)
						if trk and not seen[trk.id] then
							seen[trk.id] = true
							table.insert(tracks, trk)
						end
					end
				end
			end
		end

		SlateMusic.sortTracks(tracks, "best")
		while #tracks > 60 do table.remove(tracks) end

		SlateMusic.lastArtistTracks = tracks
		if callback then callback(tracks) end
	end)
end

function SlateMusic.search(query, callback)
	task.spawn(function()
		SlateMusic.init()
		local encoded = SlateMusic.urlEncode(query)
		local tracks = {}
		local seen = {}
		local qLower = query:lower()
		local queryHasRemix = qLower:find("remix") or qLower:find("slowed") or qLower:find("sped up") or qLower:find("nightcore")

		local endpoints = {
			"https://api-v2.soundcloud.com/search/tracks?q=" .. encoded .. "&client_id=" .. SlateMusic.clientId .. "&limit=50",
			"https://api-v2.soundcloud.com/search/tracks?q=" .. encoded .. "&client_id=" .. SlateMusic.clientId .. "&limit=25&filter.content_tier=SUB_HIGH_TIER"
		}

		for _, scUrl in ipairs(endpoints) do
			local rawJson = SlateMusic.fetchUrl(scUrl)
			if rawJson then
				local ok, data = pcall(httpService.JSONDecode, httpService, rawJson)
				if ok and data and data.collection then
					for _, item in ipairs(data.collection) do
						local trk = SlateMusic.buildTrackFromItem(item, qLower, queryHasRemix)
						if trk and not seen[trk.id] then
							seen[trk.id] = true
							table.insert(tracks, trk)
						end
					end
				end
			end
		end

		SlateMusic.sortTracks(tracks, SlateMusic.searchSort)
		SlateMusic.lastQuery = query

		if #tracks == 0 then
			local dzUrl = "https://api.deezer.com/search?q=" .. encoded .. "&limit=30"
			local dzRaw = SlateMusic.fetchUrl(dzUrl)
			if dzRaw then
				local ok, data = pcall(httpService.JSONDecode, httpService, dzRaw)
				if ok and data and data.data then
					for _, item in ipairs(data.data) do
						local safeId = "dz_" .. tostring(item.id):gsub("[^%w%-_]", "_")
						if not seen[safeId] then
							seen[safeId] = true
							local cover = (item.album and item.album.cover_big) or (item.artist and item.artist.picture_big) or ""
							table.insert(tracks, {
								id = safeId,
								title = item.title,
								artist = (item.artist and item.artist.name) or "Artist",
								duration = tonumber(item.duration) or 180,
								coverUrl = cover,
								streamUrl = item.preview,
								rankScore = tonumber(item.rank) or 0
							})
						end
					end
				end
				SlateMusic.sortTracks(tracks, "best")
			end
		end

		SlateMusic.lastResults = tracks

		if callback then
			callback(tracks)
		end
	end)
end

function SlateMusic.setSearchSort(mode)
	if mode ~= "best" and mode ~= "likes" and mode ~= "plays" then return SlateMusic.searchSort end
	SlateMusic.searchSort = mode
	if SlateMusic.lastResults then
		SlateMusic.sortTracks(SlateMusic.lastResults, mode)
	end
	return SlateMusic.searchSort
end

function SlateMusic.resolveSoundCloudStream(transcodings, queryFallback)
	if transcodings then
		for _, tc in ipairs(transcodings) do
			if tc.format and tc.format.protocol and tc.format.protocol == "progressive" and tc.url then
				local clientIds = { SlateMusic.clientId, SlateMusic.fallbackClientId, "2t9loNUAakJJioAMMRbtugDuNmUQFdHf" }
				for _, cid in ipairs(clientIds) do
					local resolveUrl = tc.url .. "?client_id=" .. cid
					local raw = SlateMusic.fetchUrl(resolveUrl)
					if raw then
						local ok, data = pcall(httpService.JSONDecode, httpService, raw)
						if ok and data and data.url then
							local u = data.url:lower()
							if not u:find("preview") and not u:find("snippet") and not u:find("cf-preview-media") then
								return data.url
							end
						end
					end
				end
			end
		end
	end

	if queryFallback and queryFallback ~= "" then
		local encoded = SlateMusic.urlEncode(queryFallback)
		local scUrl = "https://api-v2.soundcloud.com/search/tracks?q=" .. encoded .. "&client_id=" .. SlateMusic.clientId .. "&limit=15"
		local rawJson = SlateMusic.fetchUrl(scUrl)
		if rawJson then
			local ok, scData = pcall(httpService.JSONDecode, httpService, rawJson)
			if ok and scData and scData.collection then
				for _, item in ipairs(scData.collection) do
					local dur = (item.duration or 0) / 1000

					if dur > 45 and not SlateMusic.isGoPlusItem(item) and item.media and item.media.transcodings then
						for _, tc in ipairs(item.media.transcodings) do
							if tc.format and tc.format.protocol == "progressive" and tc.url then
								local rUrl = tc.url .. "?client_id=" .. SlateMusic.clientId
								local rRaw = SlateMusic.fetchUrl(rUrl)
								if rRaw then
									local ok2, rData = pcall(httpService.JSONDecode, httpService, rRaw)
									if ok2 and rData and rData.url then
										local u = rData.url:lower()
										if not u:find("preview") and not u:find("snippet") and not u:find("cf-preview-media") then
											return rData.url
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

	return nil
end

function SlateMusic.setCoverImages(assetUri)
	pcall(function()
		if AlbumCover then AlbumCover.Image = assetUri end
		if BackgroundCover then BackgroundCover.Image = assetUri end
		if IslandAlbumCover then
			IslandAlbumCover.Image = assetUri
			IslandAlbumCover.ImageTransparency = 0
		end
		if art then art.Image = assetUri end
	end)
end

function SlateMusic.updatePlayButtons(playing)
	local playIcon = playing and "rbxthumb://type=Asset&id=128672888655850&w=150&h=150" or "rbxthumb://type=Asset&id=72060836325473&w=150&h=150"
	pcall(function()
		if uiPlay then uiPlay.Image = playIcon end
		if SpotifyPlayBtn then SpotifyPlayBtn.Image = playIcon end
	end)
end

SlateMusic.play = (function(track, queueList, index)
	if not track then return end
	SlateMusic.init()
	SlateMusic.currentTrack = track
	if queueList then
		SlateMusic.queue = queueList
		SlateMusic.queueIndex = index or 1
	end

	SlateMusic.isPlaying = true
	SlateMusic.totalDuration = track.duration or 180
	SlateMusic.currentProgress = 0

	if _G.SlateSetSpotifyPlaying then _G.SlateSetSpotifyPlaying(true) end

	local trackTitle = track.title or "Track"
	local trackArtist = track.artist or "Artist"
	pcall(function()
		if SongLabel then SongLabel.Text = trackTitle end
		if ArtistLabel then ArtistLabel.Text = trackArtist end
		if uiSongLabel then uiSongLabel.Text = trackTitle end
		if uiArtistLabel then uiArtistLabel.Text = trackArtist end
	end)

	local coverUri = track.coverUrl or track.cover or track.artwork_url or ""
	local safeId = tostring(track.id or trackTitle):gsub("[^%w%-_]", "_")
	local cachedFile = "slate/music/thumbs/" .. safeId .. ".png"

	local immediateAsset = nil
	if isfile and isfile(cachedFile) then
		if getcustomasset then pcall(function() immediateAsset = getcustomasset(cachedFile) end)
		elseif getsynasset then pcall(function() immediateAsset = getsynasset(cachedFile) end) end
	end

	if immediateAsset then
		SlateMusic.setCoverImages(immediateAsset)
	else
		SlateMusic.setCoverImages("rbxthumb://type=Asset&id=77166898472490&w=150&h=150")
	end

	SlateMusic.updatePlayButtons(true)

	task.spawn(function()
		local safeId = tostring(track.id):gsub("[^%w%-_]", "_")
		local finalStreamUrl = track.streamUrl
		local songQuery = (track.title or "") .. " " .. (track.artist or "")
		if (not finalStreamUrl or finalStreamUrl:find("preview")) and (track.transcodings or songQuery ~= "") then

			local resolvable = (not track.isSnippet) and track.transcodings or nil
			local fullUrl = SlateMusic.resolveSoundCloudStream(resolvable, songQuery)
			if fullUrl then finalStreamUrl = fullUrl end
		end

		if finalStreamUrl then
			track.streamUrl = finalStreamUrl
			SlateMusic.ensureFolders()
			local cacheFile = "slate/music/cache/" .. safeId .. ".mp3"

			if isfile and isfile(cacheFile) and readfile then
				local okRead, prevData = pcall(readfile, cacheFile)
				if okRead and prevData and #prevData < 150000 then
					if delfile then pcall(delfile, cacheFile) end
				end
			end

			if not (isfile and isfile(cacheFile)) then
				local audioData = SlateMusic.fetchUrl(finalStreamUrl)
				if audioData and writefile and #audioData > 150000 then
					pcall(writefile, cacheFile, audioData)
				end
			end

			local playedLocally = false
			if isfile and isfile(cacheFile) then
				local assetUri = nil
				if getcustomasset then pcall(function() assetUri = getcustomasset(cacheFile) end)
				elseif getsynasset then pcall(function() assetUri = getsynasset(cacheFile) end) end
				if assetUri then
					SlateMusic.sound.SoundId = assetUri
					SlateMusic.sound.TimePosition = 0
					SlateMusic.sound.Volume = SlateMusic.volume
					SlateMusic.sound:Play()
					playedLocally = true
				end
			end

			if not playedLocally then
				SlateMusic.sound.SoundId = finalStreamUrl
				SlateMusic.sound.TimePosition = 0
				SlateMusic.sound.Volume = SlateMusic.volume
				SlateMusic.sound:Play()
			end
		end

		local coverUri = track.coverUrl or track.cover or track.artwork_url or ""
		if coverUri ~= "" then
			local coverFile = "slate/music/thumbs/" .. safeId .. ".png"
			if not (isfile and isfile(coverFile)) then
				local imgData = SlateMusic.fetchUrl(coverUri)
				if imgData and writefile then pcall(writefile, coverFile, imgData) end
			end
			if isfile and isfile(coverFile) then
				local artAsset = nil
				if getcustomasset then pcall(function() artAsset = getcustomasset(coverFile) end)
				elseif getsynasset then pcall(function() artAsset = getsynasset(coverFile) end) end
				if artAsset then
					SlateMusic.setCoverImages(artAsset)
				end
			end
		end

		queueNotification("Now Playing", track.title .. " — " .. track.artist, 3)
	end)
end)

SlateMusic.toggleRepeat = (function()
	if SlateMusic.repeatMode == "off" then
		SlateMusic.repeatMode = "all"
		SlateMusic.isLooping = false
		queueNotification("Repeat", "Repeat: All (Queue)", 2)
	elseif SlateMusic.repeatMode == "all" then
		SlateMusic.repeatMode = "one"
		SlateMusic.isLooping = true
		queueNotification("Repeat", "Repeat: One (Current Song)", 2)
	else
		SlateMusic.repeatMode = "off"
		SlateMusic.isLooping = false
		queueNotification("Repeat", "Repeat: Off", 2)
	end
	if _G.SlateSyncRepeatUI then _G.SlateSyncRepeatUI(SlateMusic.repeatMode) end
	return SlateMusic.repeatMode
end)

SlateMusic.toggleShuffle = (function()
	SlateMusic.isShuffle = not SlateMusic.isShuffle
	queueNotification("Shuffle", SlateMusic.isShuffle and "Shuffle: On" or "Shuffle: Off", 2)
	if _G.SlateSyncShuffleUI then _G.SlateSyncShuffleUI(SlateMusic.isShuffle) end
	return SlateMusic.isShuffle
end)

SlateMusic.togglePlay = (function()
	SlateMusic.init()
	if not SlateMusic.sound or not SlateMusic.currentTrack then return end
	if SlateMusic.isPlaying then
		SlateMusic.sound:Pause()
		SlateMusic.isPlaying = false
	else
		SlateMusic.sound:Resume()
		SlateMusic.isPlaying = true
	end
	if _G.SlateSetSpotifyPlaying then _G.SlateSetSpotifyPlaying(SlateMusic.isPlaying) end
	SlateMusic.updatePlayButtons(SlateMusic.isPlaying)
end)

SlateMusic.next = (function()
	if #SlateMusic.queue == 0 then return end
	if SlateMusic.isShuffle and #SlateMusic.queue > 1 then
		local newIdx = SlateMusic.queueIndex
		local attempts = 0
		while newIdx == SlateMusic.queueIndex and attempts < 10 do
			newIdx = math.random(1, #SlateMusic.queue)
			attempts = attempts + 1
		end
		SlateMusic.queueIndex = newIdx
	else
		SlateMusic.queueIndex = SlateMusic.queueIndex + 1
		if SlateMusic.queueIndex > #SlateMusic.queue then
			SlateMusic.queueIndex = 1
		end
	end
	local nextTrk = SlateMusic.queue[SlateMusic.queueIndex]
	if nextTrk then SlateMusic.play(nextTrk) end
end)

SlateMusic.prev = (function()
	if #SlateMusic.queue == 0 then return end
	SlateMusic.queueIndex = SlateMusic.queueIndex - 1
	if SlateMusic.queueIndex < 1 then
		SlateMusic.queueIndex = #SlateMusic.queue
	end
	local prevTrk = SlateMusic.queue[SlateMusic.queueIndex]
	if prevTrk then SlateMusic.play(prevTrk) end
end)

SlateMusic.seek = (function(posSec)
	if SlateMusic.sound and SlateMusic.currentTrack then
		SlateMusic.sound.TimePosition = math.clamp(posSec, 0, SlateMusic.sound.TimeLength > 0 and SlateMusic.sound.TimeLength or SlateMusic.totalDuration)
	end
end)

SlateMusic.setVolume = (function(v)
	SlateMusic.volume = math.clamp(v, 0, 1)
	if SlateMusic.sound then
		SlateMusic.sound.Volume = SlateMusic.volume
	end
end)

function SlateMusic.importSpotifyPlaylist(spotifyUrl, progressCallback, completionCallback)
	task.spawn(function()
		SlateMusic.init()
		local plId = spotifyUrl:match("playlist/([%w]+)") or spotifyUrl:match("playlist:([%w]+)")
		local albumId = spotifyUrl:match("album/([%w]+)") or spotifyUrl:match("album:([%w]+)")
		local isAlbum = (albumId ~= nil and plId == nil)
		local targetId = albumId or plId

		if not targetId then
			if completionCallback then completionCallback(false, "Invalid Spotify URL. Must contain /playlist/ID or /album/ID") end
			return
		end

		if progressCallback then progressCallback("Connecting to Spotify...") end

		local plName = isAlbum and "Spotify Album" or "Spotify Playlist"
		local coverUrl = ""
		local rawTrackList = {}

		pcall(function()
			local tokenRes = SlateMusic.fetchUrl("https://open.spotify.com/get_access_token?reason=transport&productType=web_player")
			if tokenRes then
				local okTok, tokData = pcall(httpService.JSONDecode, httpService, tokenRes)
				if okTok and tokData and tokData.accessToken then
					local token = tokData.accessToken
					local reqFunc = http_request or request or (syn and syn.request) or (http and http.request)

					local metaUrl = isAlbum and ("https://api.spotify.com/v1/albums/" .. targetId) or ("https://api.spotify.com/v1/playlists/" .. targetId .. "?fields=name,images")
					if reqFunc then
						local mRes = reqFunc({
							Url = metaUrl,
							Method = "GET",
							Headers = { ["Authorization"] = "Bearer " .. token }
						})
						if mRes and mRes.Body then
							local okM, mData = pcall(httpService.JSONDecode, httpService, mRes.Body)
							if okM and mData then
								if mData.name then plName = mData.name end
								if mData.images and #mData.images > 0 and mData.images[1].url then
									coverUrl = mData.images[1].url
								end
							end
						end
					end

					local offset = 0
					local hasMore = true
					while hasMore and offset < 1000 do
						local pageUrl = isAlbum and ("https://api.spotify.com/v1/albums/" .. targetId .. "/tracks?offset=" .. tostring(offset) .. "&limit=50")
							or ("https://api.spotify.com/v1/playlists/" .. targetId .. "/tracks?offset=" .. tostring(offset) .. "&limit=100&fields=items(track(name,artists(name),duration_ms,album(images))),total,next")

						if reqFunc then
							local pRes = reqFunc({
								Url = pageUrl,
								Method = "GET",
								Headers = { ["Authorization"] = "Bearer " .. token }
							})
							if pRes and pRes.Body then
								local okP, pData = pcall(httpService.JSONDecode, httpService, pRes.Body)
								if okP and pData and pData.items and #pData.items > 0 then
									for _, item in ipairs(pData.items) do
										local trkObj = isAlbum and item or item.track
										if trkObj and trkObj.name then
											local aNames = {}
											if trkObj.artists then
												for _, art in ipairs(trkObj.artists) do
													if art.name then table.insert(aNames, art.name) end
												end
											end
											local aStr = table.concat(aNames, ", ")
											if aStr == "" then aStr = "Artist" end
											local tCover = (trkObj.album and trkObj.album.images and #trkObj.album.images > 0 and trkObj.album.images[1].url) or coverUrl
											table.insert(rawTrackList, {
												title = trkObj.name,
												subtitle = aStr,
												duration = trkObj.duration_ms or 180000,
												cover = tCover
											})
										end
									end
									if pData.next and #pData.items >= (isAlbum and 50 or 100) then
										offset = offset + (isAlbum and 50 or 100)
										if progressCallback then
											progressCallback(string.format("Fetched %d Spotify track names...", #rawTrackList))
										end
									else
										hasMore = false
									end
								else
									hasMore = false
								end
							else
								hasMore = false
							end
						else
							hasMore = false
						end
						task.wait(0.05)
					end
				end
			end
		end)

		if #rawTrackList == 0 then
			local embedUrl = isAlbum and ("https://open.spotify.com/embed/album/" .. targetId) or ("https://open.spotify.com/embed/playlist/" .. targetId)
			local html = SlateMusic.fetchUrl(embedUrl)
			if html and html ~= "" then
				local jsonStr = html:match('<script id="__NEXT_DATA__" type="application/json">(.-)</script>')
				if jsonStr then
					local ok, nextData = pcall(httpService.JSONDecode, httpService, jsonStr)
					if ok and nextData then
						local entity = nextData.props and nextData.props.pageProps and nextData.props.pageProps.state and nextData.props.pageProps.state.data and nextData.props.pageProps.state.data.entity
						if entity then
							plName = entity.name or plName
							if entity.coverArt and entity.coverArt.sources and #entity.coverArt.sources > 0 then
								coverUrl = entity.coverArt.sources[1].url or coverUrl
							end
							local embedTracks = entity.trackList or {}
							for _, t in ipairs(embedTracks) do
								table.insert(rawTrackList, t)
							end
						end
					end
				end
			end
		end

		if #rawTrackList == 0 then
			if completionCallback then completionCallback(false, "Could not load Spotify playlist data.") end
			return
		end

		SlateMusic.playlists[plName] = {}
		if not SlateMusic.playlistMeta then SlateMusic.playlistMeta = {} end
		SlateMusic.playlistMeta[plName] = { cover = coverUrl }

		local totalTracks = #rawTrackList
		local importedCount = 0

		for i = 1, totalTracks do
			local trk = rawTrackList[i]
			if trk then
				local q = (trk.title or "") .. " " .. (trk.subtitle or "")
				if progressCallback and (i % 5 == 1 or i == totalTracks) then
					progressCallback(string.format("Importing (%d/%d): %s", i, totalTracks, trk.title or ""))
				end

				local cleanTitle = (trk.title or ""):gsub("%s*%(feat%..-%)$", ""):gsub("%s*%[feat%..-%]$", ""):gsub("%s*-%s*Remastered%s*%d*", ""):gsub("%s*-%s*Bonus Track", ""):gsub("%s*-%s*Single Version", "")
				local cleanArtist = (trk.subtitle or ""):gsub(",.*", "")
				local searchQ = cleanTitle .. " " .. cleanArtist

				local encoded = SlateMusic.urlEncode(searchQ)
				local scUrl = "https://api-v2.soundcloud.com/search/tracks?q=" .. encoded .. "&client_id=" .. SlateMusic.clientId .. "&limit=15"
				local rawJson = SlateMusic.fetchUrl(scUrl)
				if rawJson then
					local ok2, scData = pcall(httpService.JSONDecode, httpService, rawJson)
					if ok2 and scData and scData.collection and #scData.collection > 0 then
						local bestItem = nil
						local bestScore = -9999
						local targetDurSec = math.floor((trk.duration or 180000) / 1000)
						local sTitleLower = cleanTitle:lower()
						local sArtistLower = cleanArtist:lower()

						local disallowedWords = { "remix", "slowed", "reverb", "sped up", "nightcore", "type beat", "instrumental", "karaoke", "cover", "bootleg", "mashup", "tribute", "flip", "vip edit", "bass boosted", "8d audio", "parody", "leak", "stem" }

						for _, item in ipairs(scData.collection) do
							local tTitle = (item.title or ""):lower()
							local uName = (item.user and item.user.username or ""):lower()
							local iDurSec = math.floor((item.duration or 0) / 1000)
							local isDisqualified = false

							if not sTitleLower:find("remix", 1, true) then
								for _, badWord in ipairs(disallowedWords) do
									if tTitle:find(badWord, 1, true) and not sTitleLower:find(badWord, 1, true) then
										isDisqualified = true
										break
									end
								end
							end

							if SlateMusic.isGoPlusItem(item) then isDisqualified = true end

							if not isDisqualified and iDurSec > 45 then
								local isPublisher = (item.publisher_metadata ~= nil and (item.publisher_metadata.isrc ~= nil or item.publisher_metadata.album_title ~= nil or item.publisher_metadata.artist ~= nil or item.publisher_metadata.p_line ~= nil))
								local isVerified = (item.user and (item.user.verified == true or (item.user.badges and item.user.badges.verified == true)))

								local score = 0

								if isPublisher then score = score + 300 end
								if isVerified then score = score + 200 end
								if item.label_name and item.label_name ~= "" then score = score + 80 end

								score = score + (SlateMusic.popularityScore(item.likes_count, item.playback_count, item.reposts_count) * 0.5)

								if tTitle:find(sTitleLower, 1, true) then score = score + 60 end
								if uName:find(sArtistLower, 1, true) then
									score = score + 50
								elseif tTitle:find(sArtistLower, 1, true) then
									score = score + 25
								end

								local diff = math.abs(iDurSec - targetDurSec)
								if diff <= 6 then
									score = score + 40
								elseif diff <= 15 then
									score = score + 20
								elseif diff > 60 then
									score = score - 30
								end

								if score > bestScore then
									bestScore = score
									bestItem = item
								end
							end
						end

						local item = bestItem or scData.collection[1]
						local cUrl = trk.cover or coverUrl or item.artwork_url
						if cUrl ~= "" then cUrl = cUrl:gsub("-large", "-t500x500") end
						local safeId = "sc_" .. tostring(item.id):gsub("[^%w%-_]", "_")

						table.insert(SlateMusic.playlists[plName], {
							id = safeId,
							title = trk.title or item.title,
							artist = trk.subtitle or (item.user and item.user.username) or "Artist",
							duration = math.floor((item.duration or trk.duration or 180000) / 1000),
							coverUrl = cUrl,
							transcodings = item.media and item.media.transcodings
						})
						importedCount = importedCount + 1
					else
						table.insert(SlateMusic.playlists[plName], {
							id = "spot_" .. tostring(i),
							title = trk.title or ("Track " .. tostring(i)),
							artist = trk.subtitle or "Artist",
							duration = math.floor((trk.duration or 180000) / 1000),
							coverUrl = trk.cover or coverUrl
						})
						importedCount = importedCount + 1
					end
				else
					table.insert(SlateMusic.playlists[plName], {
						id = "spot_" .. tostring(i),
						title = trk.title or ("Track " .. tostring(i)),
						artist = trk.subtitle or "Artist",
						duration = math.floor((trk.duration or 180000) / 1000),
						coverUrl = trk.cover or coverUrl
					})
					importedCount = importedCount + 1
				end
				task.wait(0.02)
			end
		end

		SlateMusic.savePlaylists()
		if completionCallback then
			completionCallback(true, string.format("Imported '%s' with %d tracks!", plName, importedCount), plName)
		end
	end)
end

_G.SlateMusicImportSpotify = function(url, progressCb, compCb)
	SlateMusic.importSpotifyPlaylist(url, progressCb, compCb)
end

_G.SlateMusicSearch = function(query, callback)
	SlateMusic.search(query, function(results)
		if callback then
			callback(results)
		elseif _G.SlateRenderMusicResults then
			_G.SlateRenderMusicResults(results)

			if _G.SlateMusicSearchArtists and _G.SlateRenderMusicArtists then
				_G.SlateMusicSearchArtists(query, function(artists)
					_G.SlateRenderMusicArtists(artists)
				end)
			end
		end
	end)
end

_G.SlateMusicPlayTrack = function(trk, list, idx)
	SlateMusic.play(trk, list, idx)
end

_G.SlateMusicTogglePlay = function()
	SlateMusic.togglePlay()
end

_G.SlateMusicToggleRepeat = function()
	return SlateMusic.toggleRepeat()
end

_G.SlateMusicIsShuffleOn = function()
	return SlateMusic.isShuffle == true
end
_G.SlateMusicToggleShuffle = function()
	return SlateMusic.toggleShuffle()
end

_G.SlateMusicNext = function()
	SlateMusic.next()
end

_G.SlateMusicPrev = function()
	SlateMusic.prev()
end

_G.SlateMusicToggleFavorite = function(track)
	return SlateMusic.toggleFavorite(track)
end

_G.SlateMusicIsFavorite = function(track)
	return SlateMusic.isFavorite(track)
end

_G.SlateMusicLoadPlaylists = function()
	SlateMusic.loadPlaylists()
end

_G.SlateMusicGetPlaylists = function()
	return SlateMusic.playlists
end

_G.SlateMusicCreatePlaylist = function(name)
	if not name or name == "" then return end
	SlateMusic.playlists[name] = SlateMusic.playlists[name] or {}
	SlateMusic.savePlaylists()
end

_G.SlateMusicDeletePlaylist = function(name)
	if not name or name == "Favorites" then return end
	SlateMusic.playlists[name] = nil
	if SlateMusic.playlistMeta then SlateMusic.playlistMeta[name] = nil end
	SlateMusic.savePlaylists()
end

_G.SlateMusicRemoveFromPlaylist = function(playlistName, trackId)
	if not playlistName or not SlateMusic.playlists[playlistName] then return end
	local list = SlateMusic.playlists[playlistName]
	for i, trk in ipairs(list) do
		if trk.id == trackId then
			table.remove(list, i)
			break
		end
	end
	SlateMusic.playlists[playlistName] = list
	SlateMusic.savePlaylists()
end

_G.SlateMusicAddToPlaylist = function(playlistName, track)
	if not playlistName or not track or not SlateMusic.playlists[playlistName] then return false end
	for _, trk in ipairs(SlateMusic.playlists[playlistName]) do
		if trk.id == track.id then return false end
	end
	table.insert(SlateMusic.playlists[playlistName], track)
	SlateMusic.savePlaylists()
	return true
end

_G.SlateMusicSeek = function(posSec)
	SlateMusic.seek(posSec)
end

_G.SlateMusicSetVolume = function(vol)
	SlateMusic.setVolume(vol)
end

_G.SlateMusicGetEq = function()
	local b = SlateMusic.eqBands or { low = 0, mid = 0, high = 0 }
	return {
		enabled = SlateMusic.eqEnabled,
		preset = SlateMusic.eqPreset,
		low = b.low or 0,
		mid = b.mid or 0,
		high = b.high or 0
	}
end
_G.SlateMusicGetEqPresets = function()
	return SlateMusic.eqPresets
end
_G.SlateMusicSetEqPreset = function(name)
	return SlateMusic.setEqPreset(name)
end
_G.SlateMusicSetEqBand = function(band, value)
	SlateMusic.setEqBand(band, value)
end
_G.SlateMusicToggleEq = function()
	return SlateMusic.toggleEq()
end
_G.SlateMusicResetEq = function()
	SlateMusic.resetEq()
end

_G.SlateMusicSearchArtists = function(query, callback)
	SlateMusic.searchArtists(query, callback)
end
_G.SlateMusicGetArtistTracks = function(artist, callback)
	SlateMusic.getArtistTracks(artist, callback)
end

_G.SlateMusicGetSearchSort = function()
	return SlateMusic.searchSort or "best"
end
_G.SlateMusicSetSearchSort = function(mode)
	return SlateMusic.setSearchSort(mode)
end
_G.SlateMusicGetLastResults = function()
	return SlateMusic.lastResults or {}
end

local _formatMusicSec = (function(sec)
	local s = math.floor(sec or 0)
	local m = math.floor(s / 60)
	s = s % 60
	return string.format("%d:%02d", m, s)
end)

task.spawn(function()
	local lastCurStr = ""
	local lastTotStr = ""
	while true do
		task.wait(0.25)
		if SlateMusic.sound and SlateMusic.currentTrack and SlateMusic.isPlaying then
			pcall(function()
				local cur = SlateMusic.sound.TimePosition
				local total = SlateMusic.sound.TimeLength > 0 and SlateMusic.sound.TimeLength or SlateMusic.totalDuration
				local pct = math.clamp(cur / math.max(total, 1), 0, 1)

				_G.SlateMusicTotalDuration = total
				if not _G.SlateIsScrubbing then
					if uiProgFill then
						tweenService:Create(uiProgFill, TweenInfo.new(0.24, Enum.EasingStyle.Linear), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
					end
					if ProgressBarFill then
						tweenService:Create(ProgressBarFill, TweenInfo.new(0.24, Enum.EasingStyle.Linear), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
					end
				end

				local curStr = _formatMusicSec(cur)
				local totStr = _formatMusicSec(total)

				if curStr ~= lastCurStr then
					lastCurStr = curStr
					if TimeCurrent then TimeCurrent.Text = curStr end
					if _G.SlateDeckTimeCurrent then _G.SlateDeckTimeCurrent.Text = curStr end
				end
				if totStr ~= lastTotStr then
					lastTotStr = totStr
					if TimeLength then TimeLength.Text = totStr end
					if _G.SlateDeckTimeLength then _G.SlateDeckTimeLength.Text = totStr end
				end

				if total > 5 and cur >= (total - 0.4) and not SlateMusic._trackTransitioning then
					SlateMusic._trackTransitioning = true
					task.delay(0.5, function() SlateMusic._trackTransitioning = false end)
					if SlateMusic.repeatMode == "one" then
						pcall(function()
							SlateMusic.sound:Stop()
							SlateMusic.sound.TimePosition = 0
							SlateMusic.sound.Volume = SlateMusic.volume
							SlateMusic.sound:Play()
						end)
						SlateMusic.isPlaying = true
						SlateMusic.updatePlayButtons(true)
						if _G.SlateSetSpotifyPlaying then _G.SlateSetSpotifyPlaying(true) end
					else
						SlateMusic.next()
					end
				end
			end)
		end
	end
end)

do
local zeroDelayDescendantAdded = nil
local zeroDelayDescendantRemoving = nil
local zeroDelayPartsCache = {}
do
	local execName = ""
	pcall(function()
		local fn = (function()
			return identifyexecutor or getexecutorname or getexecutorlabel or (getgenv and getgenv().identifyexecutor) or (getgenv and getgenv().getexecutorname) or (getgenv and getgenv().getexecutorlabel) or nil
		end)()
		if type(fn) == "function" then
			local ok, r = pcall(fn)
			if ok and type(r) == "string" then execName = r:lower() end
		end
	end)
	if execName:match("xeno") then
		canUsePhysicsRep = false
	elseif sethiddenproperty then
		local ok = pcall(function()
			local char = localPlayer.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					sethiddenproperty(hrp, "PhysicsRepRootPart", hrp)
				end
			end
		end)
		canUsePhysicsRep = ok
	end
end
function StopZeroDelayCleanup()
	if sethiddenproperty and canUsePhysicsRep then
		pcall(function()
			if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
				sethiddenproperty(localPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
			end
		end)
	end
	pcall(function()
		local char = localPlayer.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.AutoRotate    = true
			hum.Sit           = false
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.AssemblyLinearVelocity  = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
	end)
end
function StopZeroDelay()
	if not ZeroDelayEnabled then return end
	ZeroDelayEnabled = false
	zeroDelayMode    = nil
	if zeroDelayThread then
		zeroDelayThread:Disconnect()
		zeroDelayThread = nil
	end
	if zeroDelayConnection then
		zeroDelayConnection:Disconnect()
		zeroDelayConnection = nil
	end
	if zeroDelayDescendantAdded then
		zeroDelayDescendantAdded:Disconnect()
		zeroDelayDescendantAdded = nil
	end
	if zeroDelayDescendantRemoving then
		zeroDelayDescendantRemoving:Disconnect()
		zeroDelayDescendantRemoving = nil
	end
	table.clear(zeroDelayPartsCache)
	zeroDelayTargetPlayer = nil
	StopZeroDelayCleanup()
	queueNotification("Zero Delay", "Stopped")
end
function StartZeroDelay(targetPlayer, mode)
	if not targetPlayer then
		queueNotification("Error", "No target player selected")
		return
	end
	if ZeroDelayEnabled then StopZeroDelay() end
	local char = localPlayer.Character
	if not char then queueNotification("Error", "Character not loaded") return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then queueNotification("Error", "Humanoid/HRP not found") return end
	zeroDelayTargetPlayer = targetPlayer
	ZeroDelayEnabled      = true
	zeroDelayMode         = mode
	hum.PlatformStand = false
	hum.AutoRotate    = false
	hum.Sit           = true
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Seated) end)

	local function updatePartsCache()
		table.clear(zeroDelayPartsCache)
		local localChar = localPlayer.Character
		if localChar then
			local localHRP = localChar:FindFirstChild("HumanoidRootPart")
			for _, part in ipairs(localChar:GetDescendants()) do
				if part:IsA("BasePart") and part ~= localHRP then
					table.insert(zeroDelayPartsCache, part)
				end
			end
		end
	end
	updatePartsCache()
	zeroDelayDescendantAdded = char.DescendantAdded:Connect(updatePartsCache)
	zeroDelayDescendantRemoving = char.DescendantRemoving:Connect(updatePartsCache)

	zeroDelayThread = runService.PreSimulation:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if not ZeroDelayEnabled then return end
		local localChar = localPlayer.Character
		if not localChar then StopZeroDelay(); return end
		local localHRP = localChar:FindFirstChild("HumanoidRootPart")
		local localHum = localChar:FindFirstChildOfClass("Humanoid")
		if not localHRP or not localHum then return end
		if localHum.MoveDirection.Magnitude > 0 or localHum.Jump then
			StopZeroDelay()
			return
		end
		local target = zeroDelayTargetPlayer
		if not target then StopZeroDelay(); return end
		local targetChar = target.Character
		if not targetChar then return end
		local targetHRP  = targetChar:FindFirstChild("HumanoidRootPart")
		local targetHead = targetChar:FindFirstChild("Head")
		if not targetHRP then return end
		if sethiddenproperty and canUsePhysicsRep then
			local physAnchor
			if mode == "headsit" then
				physAnchor = targetHead or targetHRP
			elseif mode == "drag" then
				physAnchor = targetChar:FindFirstChild("RightHand") or targetChar:FindFirstChild("Right Arm") or targetHRP
			else
				physAnchor = targetHRP
			end
			pcall(sethiddenproperty, localHRP, "PhysicsRepRootPart", physAnchor)
		end
		local finalCF
		if mode == "headsit" then
			finalCF = (targetHead or targetHRP).CFrame * CFrame.new(0, 2.5, 0)
		elseif mode == "backpack" then
			local tRot = targetHRP.CFrame.Rotation
			finalCF = CFrame.new(targetHRP.Position - tRot.LookVector * 1.5 + Vector3.new(0, 0.3, 0)) * tRot * CFrame.Angles(0, math.pi, 0)
		elseif mode == "doggy" then
			local tRot = targetHRP.CFrame.Rotation
			finalCF = CFrame.new(targetHRP.Position + tRot * Vector3.new(0, -0.3, -1.5)) * tRot
		elseif mode == "stand" then
			finalCF = targetHRP.CFrame * CFrame.new(-3, 1, 0)
		elseif mode == "drag" then
			local targetArm = targetChar:FindFirstChild("RightHand") or targetChar:FindFirstChild("Right Arm") or targetHRP
			finalCF = targetArm.CFrame * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
		else
			finalCF = targetHRP.CFrame
		end
		localHRP.CFrame                  = finalCF
		localHRP.AssemblyLinearVelocity  = Vector3.zero
		localHRP.AssemblyAngularVelocity = Vector3.zero
		pcall(function()
			for _, part in ipairs(zeroDelayPartsCache) do
				if part.Parent then
					if part.AssemblyLinearVelocity  ~= Vector3.zero then part.AssemblyLinearVelocity  = Vector3.zero end
					if part.AssemblyAngularVelocity ~= Vector3.zero then part.AssemblyAngularVelocity = Vector3.zero end
				end
			end
		end)
		if localHum.Sit           ~= true  then localHum.Sit           = true  end
		if localHum.AutoRotate    ~= false then localHum.AutoRotate    = false end
		if localHum.PlatformStand ~= false then localHum.PlatformStand = false end
		if localHum:GetState() ~= Enum.HumanoidStateType.Seated then
			pcall(function() localHum:ChangeState(Enum.HumanoidStateType.Seated) end)
		end
	end))
	if zeroDelayConnection then zeroDelayConnection:Disconnect() end
	zeroDelayConnection = localPlayer.CharacterAdded:Connect(function()
		if ZeroDelayEnabled then
			task.wait(0.6)
			StartZeroDelay(zeroDelayTargetPlayer, zeroDelayMode)
		end
	end)
	queueNotification("Zero Delay", mode:upper() .. " started -> " .. targetPlayer.DisplayName)
end
end

do
local _fbOscTime = 0
local _fbZDThread = nil
local _fbZDConn = nil
local _fbDescendantAdded = nil
local _fbDescendantRemoving = nil
local _fbPartsCache = {}
_G._OnyxFaceBangDistance = 6
_G._OnyxFaceBangSpeed = 24
_G._OnyxFaceBangHeight = 1
GetNearestPlayer = function()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local best, bestDist = nil, math.huge
	for _, p in ipairs(players:GetPlayers()) do
		if p ~= localPlayer and p.Character then
			local ph = p.Character:FindFirstChild("HumanoidRootPart")
			if ph then
				local d = (hrp.Position - ph.Position).Magnitude
				if d < bestDist then bestDist = d; best = p end
			end
		end
	end
	return best
end
StopFaceBang = function()
	FaceBangEnabled = false
	_fbOscTime = 0
	if _fbZDThread then pcall(function() _fbZDThread:Disconnect() end) _fbZDThread = nil end
	if _fbZDConn then pcall(function() _fbZDConn:Disconnect() end) _fbZDConn = nil end
	if _fbDescendantAdded then pcall(function() _fbDescendantAdded:Disconnect() end) _fbDescendantAdded = nil end
	if _fbDescendantRemoving then pcall(function() _fbDescendantRemoving:Disconnect() end) _fbDescendantRemoving = nil end
	table.clear(_fbPartsCache)
	pcall(function()
		local c = localPlayer.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.AutoRotate = true
			hum.Sit = false
		end
		local h = c and c:FindFirstChild("HumanoidRootPart")
		if h then
			h.AssemblyLinearVelocity = Vector3.zero
			h.AssemblyAngularVelocity = Vector3.zero
		end
	end)
	if sethiddenproperty then
		pcall(function()
			local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then sethiddenproperty(hrp, "PhysicsRepRootPart", nil) end
		end)
	end
	queueNotification("Face Bang", "Stopped")
end
StartFaceBang = function(targetPlayer)
	if not targetPlayer then return end
	local lpName = localPlayer.Name
	local tName = targetPlayer.Name
	if workspace:FindFirstChild("Crucifix_" .. lpName) or workspace:FindFirstChild("Gallows_" .. lpName) then
		queueNotification("Face Bang", "Cannot facebang while crucified or hung!")
		return
	end
	if workspace:FindFirstChild("Crucifix_" .. tName) or workspace:FindFirstChild("Gallows_" .. tName) then
		queueNotification("Face Bang", "Cannot facebang a crucified or hung player!")
		return
	end
	if FaceBangEnabled then StopFaceBang() end
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	FaceBangEnabled = true
	_fbOscTime = 0
	hum.PlatformStand = true
	hum.AutoRotate = false
	hum.Sit = false

	local function updateFbPartsCache()
		table.clear(_fbPartsCache)
		local lc = localPlayer.Character
		if lc then
			local lh = lc:FindFirstChild("HumanoidRootPart")
			for _, part in ipairs(lc:GetDescendants()) do
				if part:IsA("BasePart") and part ~= lh then
					table.insert(_fbPartsCache, part)
				end
			end
		end
	end
	updateFbPartsCache()
	_fbDescendantAdded = char.DescendantAdded:Connect(updateFbPartsCache)
	_fbDescendantRemoving = char.DescendantRemoving:Connect(updateFbPartsCache)

	_fbZDThread = runService.PreSimulation:Connect((function(dt)
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if not FaceBangEnabled then return end
		if not userInputService.WindowFocused then return end
		local curLpName = localPlayer.Name
		local curTName = targetPlayer.Name
		if workspace:FindFirstChild("Crucifix_" .. curLpName) or workspace:FindFirstChild("Gallows_" .. curLpName) or
		   workspace:FindFirstChild("Crucifix_" .. curTName) or workspace:FindFirstChild("Gallows_" .. curTName) then
			StopFaceBang()
			return
		end
		local lc = localPlayer.Character
		local lh = lc and lc:FindFirstChild("HumanoidRootPart")
		local lhum = lc and lc:FindFirstChildOfClass("Humanoid")
		if not lh or not lhum then StopFaceBang() return end
		local tc = targetPlayer.Character
		local tHead = tc and tc:FindFirstChild("Head")
		local tHRP = tc and tc:FindFirstChild("HumanoidRootPart")
		if not tHead or not tHRP then return end
		if sethiddenproperty and canUsePhysicsRep then
			pcall(sethiddenproperty, lh, "PhysicsRepRootPart", tHead)
		end
		local speed = _G._OnyxFaceBangSpeed or 24
		local distance = _G._OnyxFaceBangDistance or 6
		_fbOscTime = _fbOscTime + (speed / 1.5) * dt
		local t = (math.sin(_fbOscTime) + 1) / 2
		local heightOff = _G._OnyxFaceBangHeight or 1
		local headPos = tHead.Position + Vector3.new(0, heightOff, 0)
		local lookDir = tHead.CFrame.LookVector
		local minDist = 0.5
		local finalPos = headPos + lookDir * (minDist + t * distance)
		lh.CFrame = CFrame.lookAt(finalPos, headPos, Vector3.new(0, 1, 0))
		lh.AssemblyLinearVelocity = Vector3.zero
		lh.AssemblyAngularVelocity = Vector3.zero
		pcall(function()
			for _, part in ipairs(_fbPartsCache) do
				if part.Parent then
					if part.AssemblyLinearVelocity  ~= Vector3.zero then part.AssemblyLinearVelocity  = Vector3.zero end
					if part.AssemblyAngularVelocity ~= Vector3.zero then part.AssemblyAngularVelocity = Vector3.zero end
				end
			end
		end)
		lhum.PlatformStand = true
		lhum.AutoRotate = false
	end))
	_fbZDConn = localPlayer.CharacterAdded:Connect(function()
		if FaceBangEnabled then
			task.wait(0.6)
			StartFaceBang(targetPlayer)
		end
	end)
	queueNotification("Face Bang", "Started on " .. targetPlayer.DisplayName)
end

end

hiddenPlayers = {}
hiddenConnections = {}
local hiddenRenderSteppedConn = nil

local function setPlayerVoiceMuted(userId, muteState)
	pcall(function()
		local vci = game:GetService("VoiceChatInternal")
		if vci then
			if vci.SubscribePause then
				vci:SubscribePause(userId, muteState)
			end
			if vci.SetUserMuted then
				vci:SetUserMuted(userId, muteState)
			end
		end
	end)
	local p = players:GetPlayerByUserId(userId)
	if p and p.Character then
		for _, desc in ipairs(p.Character:GetDescendants()) do
			if desc:IsA("Sound") then
				desc.Volume = muteState and 0 or 1
			elseif desc:IsA("AudioEmitter") or desc:IsA("AudioPlayer") or desc:IsA("AudioDeviceInput") then
				pcall(function() desc.Volume = muteState and 0 or 1 end)
				pcall(function() desc.Muted = muteState end)
			end
		end
	end
end
do

local function isAdorneeOfChar(adornee, char)
	if not adornee or not char then return false end
	return adornee == char or adornee:IsDescendantOf(char)
end

local function suppressBubblesForChar(char)
	if not char then return end
	local coreGui = gethui and gethui() or game:GetService("CoreGui")
	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	local searchContainers = {coreGui, playerGui, workspace, char}

	for _, container in ipairs(searchContainers) do
		if container then
			pcall(function()
				for _, desc in ipairs(container:GetDescendants()) do
					if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
						if isAdorneeOfChar(desc.Adornee, char) or desc:IsDescendantOf(char) then
							desc.Enabled = false
							desc.Size = UDim2.new(0, 0, 0, 0)
							desc.MaxDistance = 0
							desc.AlwaysOnTop = false
						end
					end
				end
			end)
		end
	end
end

local function restoreBubblesForChar(char)
	if not char then return end
	local coreGui = gethui and gethui() or game:GetService("CoreGui")
	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	local searchContainers = {coreGui, playerGui, workspace, char}

	for _, container in ipairs(searchContainers) do
		if container then
			pcall(function()
				for _, desc in ipairs(container:GetDescendants()) do
					if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
						if isAdorneeOfChar(desc.Adornee, char) or desc:IsDescendantOf(char) then
							desc.Enabled = true
							desc.MaxDistance = 100
						end
					end
				end
			end)
		end
	end
end

local function applyHideToCharacter(char)
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
			part.Transparency = 1
			part.CastShadow = false
		elseif part:IsA("Decal") or part:IsA("Texture") then
			part.Transparency = 1
		elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") or part:IsA("Highlight") or part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") or part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
			part.Enabled = false
			if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
				part.Size = UDim2.new(0, 0, 0, 0)
				part.MaxDistance = 0
			end
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.LocalTransparencyModifier = 1
				handle.Transparency = 1
			end
		elseif part:IsA("Sound") or part:IsA("AudioEmitter") or part:IsA("AudioPlayer") or part:IsA("AudioDeviceInput") then
			pcall(function() part.Volume = 0 end)
			pcall(function() part.Muted = true end)
		end
	end
	suppressBubblesForChar(char)
end

local function applyUnhideToCharacter(char)
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0
			if part.Name == "HumanoidRootPart" then
				part.Transparency = 1
			else
				part.Transparency = 0
			end
			part.CastShadow = true
		elseif part:IsA("Decal") or part:IsA("Texture") then
			part.Transparency = 0
		elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") or part:IsA("Highlight") or part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") or part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
			part.Enabled = true
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.LocalTransparencyModifier = 0
				handle.Transparency = 0
			end
		elseif part:IsA("Sound") or part:IsA("AudioEmitter") or part:IsA("AudioPlayer") or part:IsA("AudioDeviceInput") then
			pcall(function() part.Volume = 1 end)
			pcall(function() part.Muted = false end)
		end
	end
	restoreBubblesForChar(char)
end

do
local hiddenPartCache = setmetatable({}, {__mode = "k"})
end
do
local hideScanAccum = 0

local function ensureHideLoop()
	if not hiddenRenderSteppedConn then
		hiddenRenderSteppedConn = runService.RenderStepped:Connect((function(dt)
			LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
			local hasAny = false
			hideScanAccum = hideScanAccum + (dt or 0)
			local rescan = hideScanAccum >= 0.5
			if rescan then hideScanAccum = 0 end
			for userId in pairs(hiddenPlayers) do
				hasAny = true
				local p = players:GetPlayerByUserId(userId)
				local char = p and p.Character
				if char then
					local entry = hiddenPartCache[char]
					if not entry or rescan then
						entry = {parts = {}, faces = {}}
						for _, desc in ipairs(char:GetDescendants()) do
							if desc:IsA("BasePart") then
								entry.parts[#entry.parts + 1] = desc
							elseif desc:IsA("Decal") or desc:IsA("Texture") then
								entry.faces[#entry.faces + 1] = desc
							elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("Highlight") then
								desc.Enabled = false
							end
						end
						hiddenPartCache[char] = entry
						suppressBubblesForChar(char)
					end

					local parts = entry.parts
					for i = 1, #parts do
						local d = parts[i]
						if d.Parent then
							d.LocalTransparencyModifier = 1
							d.Transparency = 1
						end
					end
					local faces = entry.faces
					for i = 1, #faces do
						local d = faces[i]
						if d.Parent then d.Transparency = 1 end
					end
				end
			end
			if not hasAny then
				if hiddenRenderSteppedConn then
					pcall(function() hiddenRenderSteppedConn:Disconnect() end)
					hiddenRenderSteppedConn = nil
				end
			end
		end))
	end
end

function hidePlayer(target)
	if not target or target == localPlayer then return end
	hiddenPlayers[target.UserId] = true

	setPlayerVoiceMuted(target.UserId, true)

	if target.Character then
		applyHideToCharacter(target.Character)
	end

	ensureHideLoop()

	if not hiddenConnections[target.UserId] then
		hiddenConnections[target.UserId] = {}
	end

	local conns = hiddenConnections[target.UserId]
	if target.Character then
		local descConn = target.Character.DescendantAdded:Connect(function(desc)
			if hiddenPlayers[target.UserId] then
				task.defer(function()
					if desc:IsA("BasePart") then
						desc.LocalTransparencyModifier = 1
						desc.Transparency = 1
					elseif desc:IsA("Decal") or desc:IsA("Texture") then
						desc.Transparency = 1
					elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("Highlight") or desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") then
						desc.Enabled = false
						if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
							desc.Size = UDim2.new(0, 0, 0, 0)
							desc.MaxDistance = 0
						end
					elseif desc:IsA("Sound") or desc:IsA("AudioEmitter") or desc:IsA("AudioPlayer") or desc:IsA("AudioDeviceInput") then
						pcall(function() desc.Volume = 0 end)
						pcall(function() desc.Muted = true end)
					end
				end)
			end
		end)
		table.insert(conns, descConn)
	end

	local charAddedConn = target.CharacterAdded:Connect(function(newChar)
		if hiddenPlayers[target.UserId] then
			task.wait(0.2)
			applyHideToCharacter(newChar)
			setPlayerVoiceMuted(target.UserId, true)
			local descConn = newChar.DescendantAdded:Connect(function(desc)
				if hiddenPlayers[target.UserId] then
					task.defer(function()
						if desc:IsA("BasePart") then
							desc.LocalTransparencyModifier = 1
							desc.Transparency = 1
						elseif desc:IsA("Decal") or desc:IsA("Texture") then
							desc.Transparency = 1
						elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("Highlight") or desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") then
							desc.Enabled = false
							if desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
								desc.Size = UDim2.new(0, 0, 0, 0)
								desc.MaxDistance = 0
							end
						elseif desc:IsA("Sound") or desc:IsA("AudioEmitter") or desc:IsA("AudioPlayer") or desc:IsA("AudioDeviceInput") then
							pcall(function() desc.Volume = 0 end)
							pcall(function() desc.Muted = true end)
						end
					end)
				end
			end)
			table.insert(conns, descConn)
		end
	end)
	table.insert(conns, charAddedConn)

	queueNotification("Hide", "Hidden " .. target.DisplayName .. " (@" .. target.Name .. ") [VC Muted + Chat Hidden]", 3)
end

function unhidePlayer(target)
	if not target then return end
	hiddenPlayers[target.UserId] = nil

	setPlayerVoiceMuted(target.UserId, false)

	if target.Character then
		applyUnhideToCharacter(target.Character)
	end

	if hiddenConnections[target.UserId] then
		for _, conn in ipairs(hiddenConnections[target.UserId]) do
			pcall(function() conn:Disconnect() end)
		end
		hiddenConnections[target.UserId] = nil
	end

	queueNotification("Unhide", "Unhidden " .. target.DisplayName .. " (@" .. target.Name .. ")", 3)
end
end
end

do
local FindBaseplate = function()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Part") and obj.Name:lower():find("baseplate") then
			return obj
		end
	end
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") or obj:IsA("Folder") then
			for _, child in ipairs(obj:GetChildren()) do
				if child:IsA("Part") and child.Name:lower():find("baseplate") then
					return child
				end
			end
		end
	end
	local best, bestScore = nil, 0
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Part") and obj.Anchored and obj.CanCollide then
			local sz = obj.Size
			if sz.Y < 5 and sz.X > 50 and sz.Z > 50 then
				local score = sz.X * sz.Z
				if score > bestScore and math.abs(obj.Position.Y) < 10 then
					bestScore = score; best = obj
				end
			end
		end
	end
	return best
end
local CreateBaseplateClone = function(cf, original)
	local clone = Instance.new("Part")
	clone.Size = original.Size
	clone.CFrame = cf
	clone.Material = original.Material
	clone.BrickColor = original.BrickColor
	clone.Color = original.Color
	clone.Transparency = (_G.InfiniteBaseplateState == 2) and 1 or original.Transparency
	clone.Reflectance = original.Reflectance
	clone.TopSurface = original.TopSurface
	clone.BottomSurface = original.BottomSurface
	clone.Anchored = true
	clone.CanCollide = (_G.InfiniteBaseplateState ~= 2)
	clone.Parent = workspace
	local originalTexture = original:FindFirstChildOfClass("Texture")
	if originalTexture then
		local newTexture = originalTexture:Clone()
		newTexture.Parent = clone
	end
	return clone
end
_G.baseplateClones = _G.baseplateClones or {}
local UpdateBaseplates = function()
	if not _G.InfiniteBaseplateEnabled or not _G.originalBaseplate then return end
	local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local playerPos = hrp.Position
	local sizeX, sizeZ = _G.originalBaseplate.Size.X, _G.originalBaseplate.Size.Z
	local localPos = _G.originalBaseplate.CFrame:PointToObjectSpace(playerPos)
	local gridX = math.floor(localPos.X / sizeX + 0.5) * sizeX
	local gridZ = math.floor(localPos.Z / sizeZ + 0.5) * sizeZ
	local renderRadius = 4
	local neededCFs = {}
	for x = -renderRadius, renderRadius do
		for z = -renderRadius, renderRadius do
			table.insert(neededCFs, _G.originalBaseplate.CFrame * CFrame.new(x * sizeX + gridX, 0, z * sizeZ + gridZ))
		end
	end
	for i = #_G.baseplateClones, 1, -1 do
		local clone = _G.baseplateClones[i]
		if clone and clone.Parent then
			local dist = (clone.CFrame.Position - playerPos).Magnitude
			if dist > math.max(sizeX, sizeZ) * (renderRadius + 2) then
				clone:Destroy()
				table.remove(_G.baseplateClones, i)
			end
		else
			table.remove(_G.baseplateClones, i)
		end
	end
	for _, cf in pairs(neededCFs) do
		local exists = (_G.originalBaseplate.CFrame.Position - cf.Position).Magnitude < 1
		if not exists then
			for _, clone in pairs(_G.baseplateClones) do
				if (clone.CFrame.Position - cf.Position).Magnitude < 1 then
					exists = true
					break
				end
			end
		end
		if not exists then
			table.insert(_G.baseplateClones, CreateBaseplateClone(cf, _G.originalBaseplate))
		end
	end
end
task.spawn(function()
	local _bpAccum = 0
	runService.Heartbeat:Connect((function(dt)
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		if not _G.InfiniteBaseplateEnabled then return end
		_bpAccum = _bpAccum + dt
		if _bpAccum < 0.5 then return end
		_bpAccum = 0
		UpdateBaseplates()
	end))
end)
function toggleInfiniteBaseplate()
	_G.InfiniteBaseplateState = ((_G.InfiniteBaseplateState or 0) + 1) % 3
	if _G.InfiniteBaseplateState == 1 then
		_G.InfiniteBaseplateEnabled = true
		_G.originalBaseplate = FindBaseplate()
		if _G.originalBaseplate then
			queueNotification("Infinite Baseplate", "Enabled (Grid Mode)")
			UpdateBaseplates()
		else
			_G.InfiniteBaseplateState = 0
			_G.InfiniteBaseplateEnabled = false
			queueNotification("Error", "No baseplate found in workspace")
		end
	elseif _G.InfiniteBaseplateState == 2 then
		_G.InfiniteBaseplateEnabled = true
		queueNotification("Infinite Baseplate", "Invisible baseplate active")
		for _, clone in pairs(_G.baseplateClones) do
			if clone and clone.Parent then
				clone.Transparency = 1
				for _, child in ipairs(clone:GetChildren()) do
					if child:IsA("Texture") or child:IsA("Decal") then child:Destroy() end
				end
			end
		end
	else
		_G.InfiniteBaseplateEnabled = false
		queueNotification("Infinite Baseplate", "Disabled")
		for _, clone in pairs(_G.baseplateClones) do
			if clone and clone.Parent then clone:Destroy() end
		end
		_G.baseplateClones = {}
	end
end
end

_G.ClickTeleportEnabled = false
do
	userInputService.InputBegan:Connect(function(input, gp)
		if gp or userInputService:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.F and _G.ClickTeleportEnabled then
			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local ok, mouse = pcall(function() return localPlayer:GetMouse() end)
				if ok and mouse and mouse.Target then
					local pos = mouse.Hit.Position
					local yRot = select(2, hrp.CFrame:ToEulerAnglesYXZ())
					hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, yRot, 0)
				end
			end
		end
	end)
end

do
local TeleportToolConn = nil
_G.TeleportToolEnabled = false
function updateTeleportToolState(state)
	local bp = localPlayer:FindFirstChildOfClass("Backpack")
	local char = localPlayer.Character
	local existingTool = (bp and bp:FindFirstChild("Teleport Tool")) or (char and char:FindFirstChild("Teleport Tool"))
	if existingTool then existingTool:Destroy() end
	if TeleportToolConn then TeleportToolConn:Disconnect() TeleportToolConn = nil end
	if state then
		local tool = Instance.new("Tool")
		tool.Name = "Teleport Tool"
		tool.RequiresHandle = false
		TeleportToolConn = tool.Activated:Connect(function()
			local character = localPlayer.Character; if not character then return end
			local hrp = character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
			local ok, mouse = pcall(function() return localPlayer:GetMouse() end)
			if ok and mouse then
				local pos = mouse.Hit.Position
				local yRot = select(2, hrp.CFrame:ToEulerAnglesYXZ())
				hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, yRot, 0)
			end
		end)
		if bp then tool.Parent = bp end
	end
end
localPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	if _G.TeleportToolEnabled then updateTeleportToolState(true) end
end)
end

do
local _walkWallConn, _walkWallGyro, _walkWallVel, _wwAttach0 = nil, nil, nil, nil
function _startWalkWall()
	local char = localPlayer.Character; if not char then return end
	local hum  = char:FindFirstChildOfClass("Humanoid")
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	hum.AutoRotate    = false
	hum.PlatformStand = true
	local att0 = Instance.new("Attachment"); att0.Name = "WWAtt"; att0.Parent = hrp
	_wwAttach0 = att0
	local ao = Instance.new("AlignOrientation"); ao.Name = "WWOrient"
	ao.Attachment0       = att0
	ao.MaxTorque         = 4e5
	ao.MaxAngularVelocity = 1e5
	ao.Responsiveness    = 60
	ao.RigidityEnabled   = false
	ao.PrimaryAxisOnly   = false
	ao.Parent = hrp
	_walkWallGyro = ao
	local lv = Instance.new("LinearVelocity"); lv.Name = "WWVel"
	lv.Attachment0     = att0
	lv.MaxForce        = 4e5
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.VectorVelocity  = Vector3.zero
	lv.RelativeTo      = Enum.ActuatorRelativeTo.World
	lv.Parent          = hrp
	_walkWallVel       = lv
	local _wwRayParams = RaycastParams.new()
	_wwRayParams.FilterType = Enum.RaycastFilterType.Exclude
	local _wwFilterTable = {char}
	_wwRayParams.FilterDescendantsInstances = _wwFilterTable
	local _downVec = Vector3.new(0, -1, 0)
	local _wwDirs = table.create(6)
	_walkWallConn = runService.Stepped:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		local c = localPlayer.Character; if not c then return end
		local h = c:FindFirstChildOfClass("Humanoid")
		local r = c:FindFirstChild("HumanoidRootPart")
		if not h or not r then return end
		_wwFilterTable[1] = c
		_wwRayParams.FilterDescendantsInstances = _wwFilterTable
		local cf = r.CFrame
		_wwDirs[1] = -cf.UpVector
		_wwDirs[2] = _downVec
		_wwDirs[3] = cf.RightVector
		_wwDirs[4] = -cf.RightVector
		_wwDirs[5] = cf.LookVector
		_wwDirs[6] = -cf.LookVector
		local bestN, bestD = nil, math.huge
		for i = 1, 6 do
			local res = workspace:Raycast(r.Position, _wwDirs[i] * 6, _wwRayParams)
			if res and res.Distance < bestD then
				bestD = res.Distance; bestN = res.Normal
			end
		end
		if bestN then
			local up   = bestN
			local cam  = workspace.CurrentCamera
			local look = cam.CFrame.LookVector
			look = look - up * look:Dot(up)
			if look.Magnitude < 0.01 then
				look = cam.CFrame.RightVector - up * cam.CFrame.RightVector:Dot(up)
			end
			if look.Magnitude > 0.01 then
				look = look.Unit
				local right = look:Cross(up)
				ao.CFrame = CFrame.fromMatrix(r.Position, right, up)
				local mv = Vector3.zero
				if userInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + look  end
				if userInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - look  end
				if userInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - right end
				if userInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + right end
				local stick = -bestN * ((bestD - 3.5) * 10)
				lv.VectorVelocity = mv.Magnitude > 0.01
					and mv.Unit * h.WalkSpeed + stick
					or  stick
			end
		else
			lv.VectorVelocity = Vector3.zero
		end
	end))
end
function _stopWalkWall()
	if _walkWallConn then _walkWallConn:Disconnect(); _walkWallConn = nil end
	if _walkWallGyro  then pcall(function() _walkWallGyro:Destroy()  end); _walkWallGyro  = nil end
	if _walkWallVel   then pcall(function() _walkWallVel:Destroy()   end); _walkWallVel   = nil end
	if _wwAttach0     then pcall(function() _wwAttach0:Destroy()     end); _wwAttach0     = nil end
	local char = localPlayer.Character; if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.AutoRotate = true; hum.PlatformStand = false end
end
end

do
function _startNoclip()
	local char = localPlayer.Character; if not char then return end
	for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
	_noclipConn = runService.Stepped:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		local c=localPlayer.Character; if not c then return end
		for _, p in ipairs(c:GetChildren()) do if p:IsA("BasePart") then p.CanCollide=false end end
	end))
end
function _stopNoclip()
	if _noclipConn then _noclipConn:Disconnect(); _noclipConn=nil end
	local char=localPlayer.Character; if not char then return end
	for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end
end
end

do
local _jerkTool = nil
_G.OnyxDoJerk = function()
	if _jerkTool and _jerkTool.Parent then
		pcall(function() _jerkTool:Destroy() end)
		_jerkTool = nil
		queueNotification("Jerk", "Tool removed")
		return
	end
	local char     = localPlayer.Character
	local hum      = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local bp       = localPlayer:FindFirstChildOfClass("Backpack")
	if not hum or not bp then queueNotification("Jerk", "Character not ready"); return end
	local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
	local tool = Instance.new("Tool")
	tool.Name = "Jerk Off"; tool.ToolTip = "Classic."
	tool.RequiresHandle = false; tool.Parent = bp
	_jerkTool = tool
	local jorkin = false; local track = nil
	local function stopJerk() jorkin=false; if track then pcall(function() track:Stop() end); track=nil end end
	tool.Equipped:Connect(function()   jorkin = true  end)
	tool.Unequipped:Connect(stopJerk)
	hum.Died:Connect(function() stopJerk(); if _jerkTool==tool then _jerkTool=nil end end)
	tool.AncestryChanged:Connect(function() if not tool.Parent and _jerkTool==tool then stopJerk(); _jerkTool=nil end end)
	task.spawn(function()
		local anim = Instance.new("Animation")
		anim.AnimationId = isR15 and "rbxassetid://698251653" or "rbxassetid://72042024"
		local ok
		while tool and tool.Parent do
			if not jorkin then
				if track then
					pcall(function() track:Stop() end)
				end
				task.wait(0.1)
			else
				if not track then
					if animator then ok, track = pcall(function() return animator:LoadAnimation(anim) end) end
					if not ok or not track then ok, track = pcall(function() return hum:LoadAnimation(anim) end) end
				end
				if track then
					pcall(function()
						track:Play()
						track:AdjustSpeed(isR15 and 0.7 or 0.65)
						track.TimePosition = 0.6
					end)
					task.wait(0.05)
					local targetTime = isR15 and 0.7 or 0.65
					while jorkin and track and track.TimePosition < targetTime do
						task.wait(0.02)
					end
					pcall(function() if track then track:Stop() end end)
				else
					task.wait(0.2)
				end
			end
		end
		if track then
			pcall(function() track:Stop() end)
		end
		pcall(function() anim:Destroy() end)
	end)
	queueNotification("Jerk", "Tool added - equip to jerk")
end
end

IY = {}
_IY_Players_Raw = game:GetService("Players")
_IY_Players = setmetatable({}, {
    __index = function(self, key)
        if typeof(key) == "Instance" and key:IsA("Player") then
            return key
        end
        if type(key) == "number" then
            return _IY_Players_Raw:GetPlayers()[key]
        end
        local ok, val = pcall(function() return _IY_Players_Raw[key] end)
        if ok and val ~= nil then return val end
        if type(key) == "string" then
            return _IY_Players_Raw:FindFirstChild(key)
        end
        return nil
    end,
    __tostring = function() return "Players" end
})
_IY_lp          = _IY_Players_Raw.LocalPlayer
_IY_camera      = workspace.CurrentCamera
_IY_UIS         = game:GetService("UserInputService")
_IY_RunService  = game:GetService("RunService")
_IY_TweenSvc    = tweenService
_IY_HttpSvc     = game:GetService("HttpService")

_IY_toClipboard, _IY_notify, _IY_getRoot, _IY_FindInTable, _IY_getPlayersByName, _IY_getPlayer, _IY_splitArgs, getstring, isNumber, r15, tools, getRoot, vtype, _IY_Loops, _IY_breakLoops, _IY_waypoints, _IY_saveWaypoints, _IY_WP_FILE, _IY_tweenSpeed, _IY_freecamActive, _IY_freecamConn, _IY_freecamCF, _IY_antiVoidConn, _IY_antiVoidY, _IY_spinConn, _IY_walltpConn, bringT, walkto, vnoclipParts, execCmd = nil

bringT = {}
vnoclipParts = {}
walkto = false

execCmd = (function(cmdStr, speaker, store)
    if _IY_execCmd then
        return _IY_execCmd(cmdStr, speaker, store)
    end
end)

_IY_toClipboard = (function(txt)
    local fn = setclipboard or toclipboard or set_clipboard
    if fn then pcall(fn, tostring(txt)) end
    queueNotification("Clipboard", "Copied: " .. tostring(txt):sub(1,40))
end)

_IY_notify = (function(title, body)
	local disableAll = checkSetting and checkSetting("disableallnotifs")
	if disableAll and disableAll.current then return end
    queueNotification(tostring(title), tostring(body))
end)

_IY_getRoot = (function(char)
    if not char then return nil end
    if typeof(char) == "Instance" and char:IsA("Player") then
        char = char.Character
    end
    if not char then return nil end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.RootPart or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end)

_IY_FindInTable = (function(tbl, val)
    if not tbl then return false end
    for _, v in pairs(tbl) do if v == val then return true end end
    return false
end)

_IY_getPlayersByName = (function(name)
    local name_l = tostring(name or ""):lower()
    local found = {}
    for _, v in ipairs(_IY_Players_Raw:GetPlayers()) do
        if v.Name:lower():sub(1, #name_l) == name_l or
           v.DisplayName:lower():sub(1, #name_l) == name_l then
            table.insert(found, v)
        end
    end
    return found
end)

_IY_getPlayer = (function(arg, speaker)
    local spk = speaker or _IY_lp
    if not arg or arg == "" then return {spk} end
    local arg_l = tostring(arg):lower()
    if arg_l == "all"    then return _IY_Players_Raw:GetPlayers() end
    if arg_l == "others" then
        local r = {}
        for _, v in ipairs(_IY_Players_Raw:GetPlayers()) do
            if v ~= spk then table.insert(r, v) end
        end
        return r
    end
    if arg_l == "me" then return {spk} end
    if arg_l == "random" then
        local plrs = _IY_Players_Raw:GetPlayers()
        return {#plrs > 0 and plrs[math.random(1, #plrs)] or spk}
    end
    return _IY_getPlayersByName(arg)
end)

_IY_splitArgs = (function(str)
    local t = {}
    if type(str) ~= "string" then str = str ~= nil and tostring(str) or "" end
    for word in str:gmatch("%S+") do table.insert(t, word) end
    return t
end)

if not getstring then
	getstring = (function(begin, args)
		return table.concat(args or {}, " ", begin)
	end)
end
if not isNumber then
	isNumber = (function(str)
		if tonumber(str) ~= nil or str == "inf" then
			return true
		end
		return false
	end)
end
if not r15 then
	r15 = (function(plr)
		local char = plr and plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		return hum and hum.RigType == Enum.HumanoidRigType.R15
	end)
end
if not tools then
	tools = (function(plr)
		if not plr then return false end
		local bp = plr:FindFirstChildOfClass("Backpack")
		local ch = plr.Character
		if (bp and bp:FindFirstChildOfClass("Tool")) or (ch and ch:FindFirstChildOfClass("Tool")) then
			return true
		end
		return false
	end)
end
if not getRoot then
	getRoot = (function(char)
		if not char then return nil end
		local hum = char:FindFirstChildOfClass("Humanoid")
		return hum and hum.RootPart or char:FindFirstChild("HumanoidRootPart")
	end)
end
if not vtype then
	vtype = (function(o, t)
		if o == nil then return false end
		if type(o) == "userdata" then return typeof(o) == t end
		return type(o) == t
	end)
end
pcall(function()
    _G._IY_getPlayer = _IY_getPlayer
    _G._IY_splitArgs = _IY_splitArgs
    _G._IY_getRoot = _IY_getRoot
    _G._IY_Players = _IY_Players
    _G._IY_lp = _IY_lp
    _G.isNumber = isNumber
    _G.r15 = r15
    _G.tools = tools
    _G.getRoot = getRoot
    _G.vtype = vtype
    _G.getstring = getstring
    _G._IY_FindInTable = _IY_FindInTable
    if getgenv then
        local g = getgenv()
        g._IY_getPlayer = _IY_getPlayer
        g._IY_splitArgs = _IY_splitArgs
        g._IY_getRoot = _IY_getRoot
        g._IY_Players = _IY_Players
        g._IY_lp = _IY_lp
        g.isNumber = isNumber
        g.r15 = r15
        g.tools = tools
        g.getRoot = getRoot
        g.vtype = vtype
        g.getstring = getstring
        g._IY_FindInTable = _IY_FindInTable
    end
end)

_IY_Loops = {}
function _IY_breakLoops()
    for k, conn in pairs(_IY_Loops) do
        pcall(function() conn:Disconnect() end)
        _IY_Loops[k] = nil
    end
end

_IY_waypoints = {}
_IY_WP_FILE   = "slate/iy_waypoints.json"
pcall(function()
    if isfile and isfile(_IY_WP_FILE) then
        local ok, d = pcall(function()
            return httpService:JSONDecode(readfile(_IY_WP_FILE))
        end)
        if ok and type(d) == "table" then _IY_waypoints = d end
    end
end)
function _IY_saveWaypoints()
    pcall(function()
        if writefile then
            writefile(_IY_WP_FILE, httpService:JSONEncode(_IY_waypoints))
        end
    end)
end

_IY_tweenSpeed = 1

_IY_freecamActive = false
_IY_freecamConn   = nil
_IY_freecamCF     = CFrame.new()

_IY_antiVoidConn = nil
_IY_antiVoidY    = nil

_IY_spinConn = nil

_IY_walltpConn = nil

_IY_autoclickConn = nil

_IY_stareConn = nil
_IY_stareTarget = nil

_IY_loopGotoConn = nil
_IY_loopGotoTarget = nil

_IY_loopBringConn = nil
_IY_loopBringTarget = nil

_IY_walkFlingConn = nil
_IY_walkFlingTarget = nil

_IY_flyFlingConn = nil

_IY_reachConn = nil

_IY_flingConn = nil

_IY_chamsHighlights = {}

_IY_locateBillboard = nil
_IY_locateConn = nil

_IY_tpWalkConn = nil

_IY_loopOofConn = nil

_IY_spawnPoint = nil

_IY_hoverNameGui = nil
_IY_hoverNameConn = nil

function _IY_getChar()
    return _IY_lp.Character
end

_IY_ctrlLockConn = nil

_IY_spasmConn = nil

_IY_listenToPlayer = nil
_IY_listenConn = nil

_IY_loopXrayConn = nil

_IY_loopFBConn = nil

_IY_noRotateConn = nil

_IY_guiDeleteConns = {}

_IY_noBguiConn = nil
_IY_noBguiLoopConn = nil

_IY_droppableConns = {}

_IY_frozenParts = {}

_IY_loopSpeedConn = nil
_IY_loopJPConn    = nil

_IY_tpWalkActive = false

_IY_alignKeyConn = nil

_IY_autoKeyConn = nil
_IY_autoKeyLoop = false


-- Commands loaded from SlateCommands.lua (spawned to avoid blocking)
task.spawn(function()
	_awaitPrefetch("commands", 5)
	local _cmdOk, _cmdErr = pcall(function()
		loadstring(_prefetchedScripts.commands or game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/commands.lua")))()
	end)
	if not _cmdOk then
		warn("[Slate] commands.lua failed to load: " .. tostring(_cmdErr))
	end
end)


local ffActiveRings = {}
local ffLocalOn = false
local ffLastToggle = 0
local FF_TEXT = "Deflector"
local FF_RADIUS = 25
local FF_KILL_RADIUS = 10
local FF_SEGMENTS = 80
local FF_TEXT_SEGMENTS = 4

local function ffBuildRing(parent, radius, segments, color)
	local parts = {}
	local segAngle = (2 * math.pi) / segments
	local segLength = 2 * radius * math.sin(segAngle / 2) * 1.15
	for i = 1, segments do
		local angle = segAngle * (i - 1)
		local seg = Instance.new("Part")
		seg.Name = "RingSegment"
		seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.CanTouch = false
		seg.Size = Vector3.new(segLength, 15, 0.05)
		seg.Material = Enum.Material.Neon
		seg.Color = color
		seg.Transparency = 0.82
		seg.CastShadow = false
		seg.Parent = parent

		if i % 2 == 0 then
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Color = ColorSequence.new(color)
			pe.LightEmission = 0.8
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.4),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Rate = 25
			pe.Lifetime = NumberRange.new(1, 3)
			pe.Speed = NumberRange.new(0.5, 1)
			pe.EmissionDirection = Enum.NormalId.Front
			pe.Parent = seg

			local pe2 = pe:Clone()
			pe2.EmissionDirection = Enum.NormalId.Back
			pe2.Parent = seg
		end

		table.insert(parts, { part = seg, angle = angle })
	end
	return parts
end

local function ffCreateTextSlab(parent, segAngle)
	local slabLength = 2 * FF_RADIUS * math.sin(segAngle / 2) * 1.05
	local part = Instance.new("Part")
	part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
	part.Size = Vector3.new(slabLength, 15, 0.05)
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 1
	part.CastShadow = false
	part.Parent = parent

	local sgFront = Instance.new("SurfaceGui")
	sgFront.Face = Enum.NormalId.Front; sgFront.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sgFront.PixelsPerStud = 50; sgFront.LightInfluence = 0; sgFront.AlwaysOnTop = false
	sgFront.Parent = part

	local lblFront = Instance.new("TextLabel")
	lblFront.Size = UDim2.new(1, 0, 1, 0)
	lblFront.BackgroundTransparency = 1
	lblFront.Text = FF_TEXT
	lblFront.TextColor3 = Color3.fromRGB(160, 160, 165)
	lblFront.TextStrokeTransparency = 0.2
	lblFront.TextStrokeColor3 = Color3.fromRGB(40, 40, 44)
	lblFront.TextScaled = true
	lblFront.Font = Enum.Font.GothamBold
	lblFront.TextXAlignment = Enum.TextXAlignment.Center
	lblFront.TextYAlignment = Enum.TextYAlignment.Center
	lblFront.Parent = sgFront

	local sgBack = Instance.new("SurfaceGui")
	sgBack.Face = Enum.NormalId.Back; sgBack.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sgBack.PixelsPerStud = 50; sgBack.LightInfluence = 0; sgBack.AlwaysOnTop = false
	sgBack.Parent = part

	local lblBack = lblFront:Clone()
	lblBack.Parent = sgBack

	return part
end

local function ffGetGroundPos(root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		root.Parent,
		workspace:FindFirstChild("DeflectorRing_" .. root.Parent.Name),
	}
	local result = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -15, 0), params)
	if result then return result.Position.Y + 0.08 end
	return root.Position.Y - 2.92
end

local function ffRemoveRingForPlayer(userId)
	local ring = ffActiveRings[userId]
	if not ring then return end
	if ring.conn then ring.conn:Disconnect() end
	if ring.folder then ring.folder:Destroy() end
	ffActiveRings[userId] = nil
end

local function ffSpawnRingForPlayer(player)
	if ffActiveRings[player.UserId] then return end

	task.spawn(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if not root then return end
		if ffActiveRings[player.UserId] then return end

		local folder = Instance.new("Folder")
		folder.Name = "DeflectorRing_" .. player.Name
		folder.Parent = workspace

		local ringParts  = ffBuildRing(folder, FF_RADIUS, FF_SEGMENTS, Color3.fromRGB(160, 160, 165))
		local textSlabs  = {}
		local textSegAngle = (2 * math.pi) / FF_TEXT_SEGMENTS
		for i = 1, FF_TEXT_SEGMENTS do
			local slab = ffCreateTextSlab(folder, textSegAngle)
			table.insert(textSlabs, { part = slab, index = i })
		end

		local groundY = 0

		local conn = runService.RenderStepped:Connect(function()
			local c = player.Character
			if not c then return end
			local r = c:FindFirstChild("HumanoidRootPart")
			if not r then return end

			local cx = r.Position.X
			local cz = r.Position.Z
			local targetY = ffGetGroundPos(r)

			if groundY == 0 then
				groundY = targetY
			else
				groundY = groundY + (targetY - groundY) * 0.25
			end

			local segAngle = (2 * math.pi) / #ringParts
			for i, data in ipairs(ringParts) do
				local angle = segAngle * (i - 1)
				local x = math.cos(angle) * FF_RADIUS
				local z = math.sin(angle) * FF_RADIUS
				data.part.CFrame = CFrame.new(cx + x, groundY + 7.5, cz + z)
					* CFrame.Angles(0, -angle - math.pi / 2, 0)
			end

			for i, data in ipairs(textSlabs) do
				local angle = textSegAngle * (i - 1)
				local x = math.cos(angle) * FF_RADIUS
				local z = math.sin(angle) * FF_RADIUS
				data.part.CFrame = CFrame.new(cx + x, groundY + 7.5, cz + z)
					* CFrame.Angles(0, -angle - math.pi / 2, 0)
			end
		end)

		ffActiveRings[player.UserId] = { folder = folder, conn = conn }
	end)
end

runService.RenderStepped:Connect(function()
	if next(ffActiveRings) == nil then return end
	local lp = players.LocalPlayer
	if not lp then return end

	local localChar = lp.Character
	local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
	local localHum  = localChar and localChar:FindFirstChildOfClass("Humanoid")
	if not localRoot or not localHum or localHum.Health <= 0 then return end

	for userId, ringInfo in pairs(ffActiveRings) do
		if userId == lp.UserId then continue end
		local owner = players:GetPlayerByUserId(userId)
		if not owner then continue end
		local ownerChar = owner.Character
		local ownerRoot = ownerChar and ownerChar:FindFirstChild("HumanoidRootPart")
		if not ownerRoot then continue end

		local diff = localRoot.Position - ownerRoot.Position
		local horizontalDist = Vector2.new(diff.X, diff.Z).Magnitude
		local heightDiff = diff.Y

		if heightDiff < -25 or heightDiff > 500 then continue end

		if horizontalDist <= FF_RADIUS then
			if heightDiff > 15 or horizontalDist <= FF_KILL_RADIUS then
				localHum.Health = 0
			else
				local dir = Vector3.new(diff.X, 0, diff.Z).Unit
				localRoot.CFrame = localRoot.CFrame + dir * 15
				localRoot.AssemblyLinearVelocity = (dir * 200) + Vector3.new(0, 10, 0)
			end
		end
	end
end)

local function toggleForcefield(player)
	player = player or players.LocalPlayer
	if not player then return end
	if tick() - ffLastToggle < 0.5 then return end
	ffLastToggle = tick()

	if ffActiveRings[player.UserId] then
		ffLocalOn = false
		ffRemoveRingForPlayer(player.UserId)
		notify("Forcefield", "Forcefield disabled", 2)
	else
		ffLocalOn = true
		ffSpawnRingForPlayer(player)
		notify("Forcefield", "Forcefield enabled", 2)
	end
end

addcmd("ff", {"forcefield", "deflector", "unff"}, function(args, speaker)
	toggleForcefield(speaker or players.LocalPlayer)
end)
if IsOnMobile then
	local QuickCapture = Instance.new("TextButton")
	local UICorner = Instance.new("UICorner")
	QuickCapture.Name = randomString()
	QuickCapture.Parent = PARENT
	QuickCapture.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	QuickCapture.BackgroundTransparency = 0.14
	QuickCapture.Position = UDim2.new(0.489, 0, 0, 0)
	QuickCapture.Size = UDim2.new(0, 32, 0, 33)
	QuickCapture.Font = Enum.Font.SourceSansBold
	QuickCapture.Text = "IY"
	QuickCapture.TextColor3 = Color3.fromRGB(255, 255, 255)
	QuickCapture.TextSize = 20
	QuickCapture.TextWrapped = true
	QuickCapture.ZIndex = 10
	QuickCapture.Draggable = true
	UICorner.Name = randomString()
	UICorner.CornerRadius = UDim.new(0.5, 0)
	UICorner.Parent = QuickCapture
	QuickCapture.MouseButton1Click:Connect(function()
		Cmdbar:CaptureFocus()
		maximizeHolder()
	end)
	table.insert(shade1, QuickCapture)
	table.insert(text1, QuickCapture)
end
pcall(function() Scale.Scale = math.max(Holder.AbsoluteSize.X / 1920, guiScale) end)
Scale.Parent = ScaledHolder
ScaledHolder.Size = UDim2.fromScale(1 / Scale.Scale, 1 / Scale.Scale)
Scale:GetPropertyChangedSignal("Scale"):Connect(function()
	ScaledHolder.Size = UDim2.fromScale(1 / Scale.Scale, 1 / Scale.Scale)
	for _, v in ScaledHolder:GetDescendants() do
		if v:IsA("GuiObject") and v.Visible then
			v.Visible = false
			v.Visible = true
		end
	end
end)
updateColors(currentShade1,shade1)
updateColors(currentShade2,shade2)
updateColors(currentShade3,shade3)
updateColors(currentText1,text1)
updateColors(currentText2,text2)
updateColors(currentScroll,scroll)
if PluginsTable ~= nil or PluginsTable ~= {} then
	FindPlugins(PluginsTable)
end
eventEditor.RegisterEvent("OnExecute")
eventEditor.RegisterEvent("OnSpawn",{
	{Type="Player",Name="Player Filter ($1)"}
})
eventEditor.RegisterEvent("OnDied",{
	{Type="Player",Name="Player Filter ($1)"}
})
eventEditor.RegisterEvent("OnDamage",{
	{Type="Player",Name="Player Filter ($1)"},
	{Type="Number",Name="Below Health ($2)"}
})
eventEditor.RegisterEvent("OnKilled",{
	{Type="Player",Name="Victim Player ($1)"},
	{Type="Player",Name="Killer Player ($2)",Default = 1}
})
eventEditor.RegisterEvent("OnJoin",{
	{Type="Player",Name="Player Filter ($1)",Default = 1}
})
eventEditor.RegisterEvent("OnLeave",{
	{Type="Player",Name="Player Filter ($1)",Default = 1}
})
eventEditor.RegisterEvent("OnChatted",{
	{Type="Player",Name="Player Filter ($1)",Default = 1},
	{Type="String",Name="Message Filter ($2)"}
})
function hookCharEvents(plr,instant)
	task.spawn(function()
		local char = plr.Character
		if not char then return end
		local humanoid = char:WaitForChild("Humanoid",10)
		if not humanoid then return end
		local oldHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(health)
			local change = math.abs(oldHealth - health)
			if oldHealth > health then
				eventEditor.FireEvent("OnDamage",plr.Name,tonumber(health))
			end
			oldHealth = health
		end)
		humanoid.Died:Connect(function()
			eventEditor.FireEvent("OnDied",plr.Name)
			local killedBy = humanoid:FindFirstChild("creator")
			if killedBy and killedBy.Value and killedBy.Value.Parent then
				eventEditor.FireEvent("OnKilled",plr.Name,killedBy.Name)
			end
		end)
	end)
end
players.PlayerAdded:Connect(function(plr)
	eventEditor.FireEvent("OnJoin",plr.Name)
	if isLegacyChat and ChatLog then ChatLog(plr) end
	plr.CharacterAdded:Connect(function() eventEditor.FireEvent("OnSpawn",tostring(plr)) hookCharEvents(plr) end)
	if JoinLog then JoinLog(plr) end
	if isLegacyChat and ChatLog then ChatLog(plr) end
	if ESPenabled then
		repeat wait(1) until plr.Character and getRoot(plr.Character)
		ESP(plr)
	end
	if CHMSenabled then
		repeat wait(1) until plr.Character and getRoot(plr.Character)
		CHMS(plr)
	end

	pcall(function()
		plr.CharacterAdded:Connect(function() eventEditor.FireEvent("OnSpawn",tostring(plr)) hookCharEvents(plr) end)
		hookCharEvents(plr)
	end)
end)

_G.SlateChatConnections = _G.SlateChatConnections or {}
if not isLegacyChat then
	local conn = TextChatService.MessageReceived:Connect(function(message)
		if not message or not message.TextSource then return end
		local player = players:GetPlayerByUserId(message.TextSource.UserId)
		if not player then return end
		pcall(function()
			if logsEnabled == true then
				CreateLabel(player, message.Text)
			end
			eventEditor.FireEvent("OnChatted", player.Name, message.Text)
			sendChatWebhook(player, message.Text)
		end)
	end)
	table.insert(_G.SlateChatConnections, conn)
end
for _,plr in pairs(players:GetPlayers()) do
	pcall(function()
		plr.CharacterAdded:Connect(function() eventEditor.FireEvent("OnSpawn",tostring(plr)) hookCharEvents(plr) end)
		hookCharEvents(plr)
	end)
end

if spawnCmds and #spawnCmds > 0 then
	for i,v in pairs(spawnCmds) do
		eventEditor.AddCmd("OnSpawn",{v.COMMAND or "",{0},v.DELAY or 0})
	end
	updatesaves()
end
if loadedEventData then eventEditor.LoadData(loadedEventData) end
eventEditor.Refresh()
eventEditor.FireEvent("OnExecute")
if aliases and #aliases > 0 then
	local cmdMap = {}
	for i,v in pairs(cmds) do
		cmdMap[v.NAME:lower()] = v
		for _,alias in pairs(v.ALIAS) do
			cmdMap[alias:lower()] = v
		end
	end
	for i = 1, #aliases do
		local cmd = string.lower(aliases[i].CMD)
		local alias = string.lower(aliases[i].ALIAS)
		if cmdMap[cmd] then
			customAlias[alias] = cmdMap[cmd]
		end
	end
	refreshaliases()
end
IYMouse.Move:Connect(checkTT)
CaptureService.CaptureBegan:Connect(function()
	PARENT.Enabled = false
end)
CaptureService.CaptureEnded:Connect(function()
	task.delay(0.1, function()
		PARENT.Enabled = true
	end)
end)
task.spawn(function()
	local success, latestVersionInfo = pcall(function()
		local versionJson = game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/version"))
		return HttpService:JSONDecode(versionJson)
	end)
	if success then
		if currentVersion ~= latestVersionInfo.Version then
		end
		if latestVersionInfo.Announcement and latestVersionInfo.Announcement ~= "" then
			local AnnGUI = Instance.new("Frame")
			local background = Instance.new("Frame")
			local TextBox = Instance.new("TextLabel")
			local shadow = Instance.new("Frame")
			local PopupText = Instance.new("TextLabel")
			local Exit = Instance.new("TextButton")
			local ExitImage = Instance.new("ImageLabel")
			AnnGUI.Name = randomString()
			AnnGUI.Parent = ScaledHolder
			AnnGUI.Active = true
			AnnGUI.BackgroundTransparency = 1
			AnnGUI.Position = UDim2.new(0.5, -180, 0, -500)
			AnnGUI.Size = UDim2.new(0, 360, 0, 20)
			AnnGUI.ZIndex = 10
			background.Name = "background"
			background.Parent = AnnGUI
			background.Active = true
			background.BackgroundColor3 = currentShade1
			background.BorderSizePixel = 0
			background.Position = UDim2.new(0, 0, 0, 20)
			background.Size = UDim2.new(0, 360, 0, 150)
			background.ZIndex = 10
			TextBox.Parent = background
			TextBox.BackgroundTransparency = 1
			TextBox.Position = UDim2.new(0, 5, 0, 5)
			TextBox.Size = UDim2.new(0, 350, 0, 140)
			TextBox.Font = Enum.Font.SourceSans
			TextBox.TextSize = 18
			TextBox.TextWrapped = true
			TextBox.Text = latestVersionInfo.Announcement
			TextBox.TextColor3 = currentText1
			TextBox.TextXAlignment = Enum.TextXAlignment.Left
			TextBox.TextYAlignment = Enum.TextYAlignment.Top
			TextBox.ZIndex = 10
			shadow.Name = "shadow"
			shadow.Parent = AnnGUI
			shadow.BackgroundColor3 = currentShade2
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
			PopupText.Text = "Server Announcement"
			PopupText.TextColor3 = currentText1
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
			task.wait(1)
			AnnGUI:TweenPosition(UDim2.new(0.5, -180, 0, 150), "InOut", "Quart", 0.5, true, nil)
			Exit.MouseButton1Click:Connect(function()
				AnnGUI:TweenPosition(UDim2.new(0.5, -180, 0, -500), "InOut", "Quart", 0.5, true, nil)
				task.wait(0.6)
				AnnGUI:Destroy()
			end)
		end
	end
end)
task.spawn(function()
    task.wait()
    pcall(function()
        Credits:TweenPosition(UDim2.new(0, 0, 0.9, 0), "Out", "Quart", 0.2)
        Logo:TweenSizeAndPosition(UDim2.new(0, 175, 0, 175), UDim2.new(0, 37, 0, 45), "Out", "Quart", 0.3)
        task.wait(1)
        local OutInfo = TweenInfo.new(1.6809, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)
        TweenService:Create(Logo, OutInfo, {ImageTransparency = 1}):Play()
        TweenService:Create(IntroBackground, OutInfo, {BackgroundTransparency = 1}):Play()
        Credits:TweenPosition(UDim2.new(0, 0, 0.9, 30), "Out", "Quart", 0.2)
        task.wait(0.2)
    end)
    Logo:Destroy()
    Credits:Destroy()
    IntroBackground:Destroy()
    minimizeHolder()
end);

(function()

local iyCmdDetailsCache = {}
local clientCommandsSet = {}

if CMDs then
	for _, iyInfo in ipairs(CMDs) do
		if iyInfo.NAME and iyInfo.DESC then
			local infoName = iyInfo.NAME:lower()
			local cleanName = infoName:gsub("%s*[%[<].*", "")
			local isClient = infoName:find("%(client%)") or iyInfo.DESC:lower():find("%(client%)") or iyInfo.DESC:lower():find("client")
			local args = iyInfo.NAME:match("[%[<].*")

			for part in cleanName:gmatch("[^/]+") do
				part = part:match("^%s*(.-)%s*$")
				iyCmdDetailsCache[part] = {desc = iyInfo.DESC, args = args}
				if isClient then
					clientCommandsSet[part] = true
				end
			end
		end
	end
end

function getIYCmdDetails(iyName)
	local details = iyCmdDetailsCache[iyName:lower()]
	if details then
		return details.desc, details.args
	end
	return "No description available", nil
end

function isClientCommand(iyName)
	local nameLower = iyName:lower()
	if nameLower:find("client") or nameLower:find("%(client%)") then
		return true
	end
	return clientCommandsSet[nameLower] or false
end
if cmds then
	local registeredNamesSet = {}
	for _, slateCmd in ipairs(onyxCommands) do
		if slateCmd.name then
			registeredNamesSet[slateCmd.name:lower()] = true
		end
	end

	for _, iyCmd in ipairs(cmds) do
		if iyCmd.NAME then
			local lowerName = iyCmd.NAME:lower()
			if not isClientCommand(iyCmd.NAME) then
				local exists = registeredNamesSet[lowerName]
				if not exists and iyCmd.ALIAS then
					for _, alias in ipairs(iyCmd.ALIAS) do
						if registeredNamesSet[alias:lower()] then
							exists = true
							break
						end
					end
				end
				if not exists then
					local desc, args = getIYCmdDetails(iyCmd.NAME)
					table.insert(onyxCommands, {
						name = iyCmd.NAME,
						desc = desc,
						args = args,
						callback = function(arg)
							if execCmd then
								execCmd(iyCmd.NAME .. " " .. arg)
							end
						end
					})
					registeredNamesSet[lowerName] = true
					if iyCmd.ALIAS then
						for _, alias in ipairs(iyCmd.ALIAS) do
							local lowerAlias = alias:lower()
							registeredNamesSet[lowerAlias] = true
							if not onyxAliases[lowerAlias] then
								onyxAliases[lowerAlias] = iyCmd.NAME
							end
						end
					end
				end
			end
		end
	end
end
end)();
(function()
do

if not randomString then
    function randomString()
        local length = math.random(10, 20)
        local array = {}
        for i = 1, length do
            array[i] = string.char(math.random(32, 126))
        end
        return table.concat(array)
    end
end
CFspeed = 50
Floating = false
floatName = randomString()
allow_rj = true
local espParts = {}
local partEspTrigger = nil
function partAdded(part)
	if #espParts > 0 then
		if _IY_FindInTable(espParts,part.Name:lower()) then
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
promptNewRig = function(_IY_lp, rig)
	local humanoid = _IY_lp.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		AvatarEditorService:PromptSaveAvatar(humanoid.HumanoidDescription, Enum.HumanoidRigType[rig])
		local result = AvatarEditorService.PromptSaveAvatarCompleted:Wait()
		if result == Enum.AvatarPromptResult.Success then
			_IY_execCmd("reset")
		end
	end
end
oofing = false
local infJump
infJumpDebounce = false
local flyjump
local HumanModCons = {}
walkflinging = false
function attach(_IY_lp,target)
	if tools(_IY_lp) then
		local char = _IY_lp.Character
		local tchar = target.Character
		local hum = _IY_lp.Character:FindFirstChildOfClass("Humanoid")
		local hrp = _IY_getRoot(_IY_lp.Character)
		local hrp2 = _IY_getRoot(target.Character)
		hum.Name = "1"
		local newHum = hum:Clone()
		newHum.Parent = char
		newHum.Name = "Humanoid"
		wait()
		hum:Destroy()
		workspace.CurrentCamera.CameraSubject = char
		newHum.DisplayDistanceType = "None"
		local tool = _IY_lp:FindFirstChildOfClass("Backpack"):FindFirstChildOfClass("Tool") or _IY_lp.Character:FindFirstChildOfClass("Tool")
		tool.Parent = char
		hrp.CFrame = hrp2.CFrame * CFrame.new(0, 0, 0) * CFrame.new(math.random(-100, 100)/200,math.random(-100, 100)/200,math.random(-100, 100)/200)
		local n = 0
		repeat
			wait(.1)
			n = n + 1
			hrp.CFrame = hrp2.CFrame
		until (tool.Parent ~= char or not hrp or not hrp2 or not hrp.Parent or not hrp2.Parent or n > 250) and n > 2
	else
		_IY_notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
function kill(_IY_lp,target,fast)
	if tools(_IY_lp) then
		if target ~= nil then
			local NormPos = _IY_getRoot(_IY_lp.Character).CFrame
			if not fast then
				refresh(_IY_lp)
				wait()
				repeat wait() until _IY_lp.Character ~= nil and _IY_getRoot(_IY_lp.Character)
				wait(0.3)
			end
			local hrp = _IY_getRoot(_IY_lp.Character)
			attach(_IY_lp,target)
			repeat
				wait()
				hrp.CFrame = CFrame.new(999999, workspace.FallenPartsDestroyHeight + 5,999999)
			until not _IY_getRoot(target.Character) or not _IY_getRoot(_IY_lp.Character)
			local char = _IY_lp.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		_IY_notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
tpwalkStack = 0
function bring(_IY_lp,target,fast)
	if tools(_IY_lp) then
		if target ~= nil then
			local NormPos = _IY_getRoot(_IY_lp.Character).CFrame
			if not fast then
				refresh(_IY_lp)
				wait()
				repeat wait() until _IY_lp.Character ~= nil and _IY_getRoot(_IY_lp.Character)
				wait(0.3)
			end
			local hrp = _IY_getRoot(_IY_lp.Character)
			attach(_IY_lp,target)
			repeat
				wait()
				hrp.CFrame = NormPos
			until not _IY_getRoot(target.Character) or not _IY_getRoot(_IY_lp.Character)
			local char = _IY_lp.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		_IY_notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
function teleport(_IY_lp,target,target2,fast)
	if tools(_IY_lp) then
		if target ~= nil then
			local NormPos = _IY_getRoot(_IY_lp.Character).CFrame
			if not fast then
				refresh(_IY_lp)
				wait()
				repeat wait() until _IY_lp.Character ~= nil and _IY_getRoot(_IY_lp.Character)
				wait(0.3)
			end
			local hrp = _IY_getRoot(_IY_lp.Character)
			local hrp2 = _IY_getRoot(target2.Character)
			attach(_IY_lp,target)
			repeat
				wait()
				hrp.CFrame = hrp2.CFrame
			until not _IY_getRoot(target.Character) or not _IY_getRoot(_IY_lp.Character)
			wait(1)
			local char = _IY_lp.CharacterAdded:Wait()
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			while not humanoid:IsA("Humanoid") do
				humanoid = char:FindFirstChildOfClass("Humanoid") or char.ChildAdded:Wait()
			end
			humanoid.RootPart.CFrame = NormPos
		end
	else
		_IY_notify('Tool Required','You need to have an item in your inventory to use this command')
	end
end
local walltpTouch = nil
antivoidWasEnabled = false

local favCommandsConfig = {}
local favIconId = "rbxthumb://type=Asset&id=134278442967616&w=150&h=150"
local unfavIconId = "rbxthumb://type=Asset&id=93715138313453&w=150&h=150"

function loadFavoriteCommands()
	pcall(function()
		if not readfile then return end
		local ok, content = pcall(readfile, "slate/fav_commands.json")
		if not ok or not content or content == "" then return end
		local dok, data = pcall(httpService.JSONDecode, httpService, content)
		if dok and type(data) == "table" then
			favCommandsConfig = data
		end
	end)
end

function saveFavoriteCommands()
	pcall(function()
		if not writefile then return end
		if makefolder and not (isfolder and isfolder("slate")) then
			pcall(makefolder, "slate")
		end
		writefile("slate/fav_commands.json", httpService:JSONEncode(favCommandsConfig))
	end)
end

function loadAutoexecConfig()
	pcall(function()
		if not readfile then return end
		local ok, content = pcall(readfile, "slate/autoexec.json")
		if not ok or not content or content == "" then return end
		local dok, data = pcall(httpService.JSONDecode, httpService, content)
		if dok and type(data) == "table" then
			autoexecConfig = data
		end
	end)
end

function saveAutoexecConfig()
	pcall(function()
		if not writefile then return end
		if makefolder and not (isfolder and isfolder("slate")) then
			pcall(makefolder, "slate")
		end
		writefile("slate/autoexec.json", httpService:JSONEncode(autoexecConfig))
	end)
end

function runAutoexecCommands()
	task.spawn(function()
		task.wait(1.5)
		local _realNotif = queueNotification
		queueNotification = function() end
		for _, cmd in ipairs(onyxCommands) do
			if (cmd.isToggle or cmd.autoexecable) and autoexecConfig[cmd.name] == true then
				pcall(function()
					if cmd.isToggle then
						cmd.callback(true)
					else
						cmd.callback("")
					end
				end)
			end
		end
		queueNotification = _realNotif
	end)
end

do
local commandCards = {}
local commandsLoaded = false
local currentCommandsCategory = "all"

function renderCommands(query, animate)
	local scroll = CommandsTab:FindFirstChild("ScriptsScroll") or CommandsTab:FindFirstChildOfClass("ScrollingFrame")
	if not scroll then return end
	local searchBar = CommandsTab:FindFirstChild("ScriptsSearchBar")
	query = (query or (searchBar and searchBar.Text or "")):lower()

	if not commandsLoaded then
		commandsLoaded = true
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
		end
		commandCards = {}

		for idx, cmd in ipairs(onyxCommands) do
			local card = Instance.new("TextButton")
			card.Name = "CmdCard_" .. cmd.name
			card.Size = UDim2.new(1, -10, 0, 48)
			card.Position = UDim2.new(0, 5, 0, 5 + (idx - 1) * 54)
			card.BackgroundTransparency = 1
			card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
			card.BorderSizePixel = 0
			card.Text = ""
			card.AutoButtonColor = false
			card.Parent = scroll
			card:SetAttribute("CmdName", cmd.name)
			card:SetAttribute("CmdDesc", cmd.desc)
			card:SetAttribute("OriginalIndex", idx)

			local corner = Instance.new("UICorner", card)
			corner.CornerRadius = UDim.new(0, 6)

			local function updateCardVisual()
				local active = cmd.isToggle and cmd.getState()
				if active then
					card.BackgroundTransparency = 0.6
					card.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
				else
					card.BackgroundTransparency = 1
					card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
				end
			end
			updateCardVisual()

			card.MouseEnter:Connect(function()
				local active = cmd.isToggle and cmd.getState()
				tweenService:Create(card, TweenInfo.new(0.12), {
					BackgroundColor3 = active and Color3.fromRGB(44, 44, 52) or Color3.fromRGB(20, 20, 25),
					BackgroundTransparency = active and 0.4 or 0.7
				}):Play()
			end)
			card.MouseLeave:Connect(function()
				local active = cmd.isToggle and cmd.getState()
				tweenService:Create(card, TweenInfo.new(0.12), {
					BackgroundColor3 = active and Color3.fromRGB(34, 34, 40) or Color3.fromRGB(20, 20, 25),
					BackgroundTransparency = active and 0.6 or 1
				}):Play()
			end)

			local favBtn = Instance.new("ImageButton", card)
			favBtn.Name = "FavBtn"
			favBtn.Size = UDim2.new(0, 18, 0, 18)
			favBtn.Position = UDim2.new(0, 10, 0.5, -9)
			favBtn.BackgroundTransparency = 1
			favBtn.ScaleType = Enum.ScaleType.Fit

			local isFav = (favCommandsConfig[cmd.name] == true)
			favBtn.Image = isFav and favIconId or unfavIconId
			favBtn.ImageColor3 = isFav and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 125)

			favBtn.MouseButton1Click:Connect(function()
				if favCommandsConfig[cmd.name] then
					favCommandsConfig[cmd.name] = nil
				else
					favCommandsConfig[cmd.name] = true
				end
				saveFavoriteCommands()
				local newFav = (favCommandsConfig[cmd.name] == true)
				favBtn.Image = newFav and favIconId or unfavIconId
				local targetColor = newFav and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 125)
				tweenService:Create(favBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = targetColor}):Play()
				renderCommands(nil, true)
			end)

			local title = Instance.new("TextLabel", card)
			title.Size = UDim2.new(0.48, -38, 0, 18)
			title.Position = UDim2.new(0, 36, 0, 6)
			title.BackgroundTransparency = 1
			title.TextColor3 = Color3.fromRGB(255, 255, 255)
			title.TextSize = 12
			title.TextStrokeTransparency = 1
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			title.Text = "." .. cmd.name .. (cmd.args and (" " .. cmd.args) or "")
			title.TextTruncate = Enum.TextTruncate.AtEnd

			local desc = Instance.new("TextLabel", card)
			desc.Size = UDim2.new(0.48, -38, 0, 16)
			desc.Position = UDim2.new(0, 36, 0, 24)
			desc.BackgroundTransparency = 1
			desc.TextColor3 = Color3.fromRGB(140, 140, 145)
			desc.TextSize = 10
			desc.TextStrokeTransparency = 1
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
			desc.Text = cmd.desc
			desc.TextTruncate = Enum.TextTruncate.AtEnd

			local argBox
			if cmd.args then
				argBox = Instance.new("TextBox", card)
				argBox.BorderSizePixel = 0
				argBox.Size = UDim2.new(0, 130, 0, 26)
				argBox.Position = UDim2.new(1, -140, 0.5, -13)
				argBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
				argBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				argBox.TextSize = 10
				argBox.TextStrokeTransparency = 1
				argBox.PlaceholderText = cmd.args
				argBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 95)
				argBox.Text = ""
				argBox.ClearTextOnFocus = false
				argBox.ClipsDescendants = true
				argBox.TextTruncate = Enum.TextTruncate.AtEnd
				Instance.new("UICorner", argBox).CornerRadius = UDim.new(0, 5)
				local pad = Instance.new("UIPadding", argBox)
				pad.PaddingLeft = UDim.new(0, 6)
				pad.PaddingRight = UDim.new(0, 6)
			end

			local hasAutoBtn = (cmd.isToggle or cmd.autoexecable) and not cmd.args
			local bindX = -56
			if cmd.args then
				bindX = -192
			elseif hasAutoBtn then
				bindX = -116
			end

			local bindBtn = Instance.new("TextButton", card)
			bindBtn.Name = "BindBtn"
			bindBtn.Size = UDim2.new(0, 46, 0, 26)
			bindBtn.Position = UDim2.new(1, bindX, 0.5, -13)
			bindBtn.BorderSizePixel = 0
			bindBtn.AutoButtonColor = false
			bindBtn.TextSize = 10
			bindBtn.TextStrokeTransparency = 1
			bindBtn.TextTruncate = Enum.TextTruncate.AtEnd
			bindBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 5)

			local listening, cancelCapture = false, nil

			local function paintBind()
				bindBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
				if listening then
					bindBtn.Text = "..."
					bindBtn.TextColor3 = Color3.fromRGB(130, 130, 140)
					return
				end
				local key = SlateBinds.keyFor(cmd.name)
				if key then
					bindBtn.Text = key
					bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					bindBtn.Text = "Bind"
					bindBtn.TextColor3 = Color3.fromRGB(130, 130, 140)
				end
			end
			paintBind()
			SlateBinds.onChanged(paintBind)

			bindBtn.MouseEnter:Connect(function()
				if not listening then
					tweenService:Create(bindBtn, TweenInfo.new(0.12), {
						BackgroundColor3 = Color3.fromRGB(30, 30, 36)
					}):Play()
				end
			end)
			bindBtn.MouseLeave:Connect(function()
				if not listening then paintBind() end
			end)

			bindBtn.MouseButton1Click:Connect(function()
				if listening then
					if cancelCapture then cancelCapture() end
					listening = false
					paintBind()
					return
				end

				local bound = SlateBinds.keyFor(cmd.name)
				if bound then
					SlateBinds.clear(bound)
					queueNotification("Keybind", "Unbound ." .. cmd.name, 2)
					paintBind()
					return
				end

				listening = true
				paintBind()
				cancelCapture = SlateBinds.captureKey(function(keyName, action)
					listening = false
					if action == "clear" then
						local existing = SlateBinds.keyFor(cmd.name)
						if existing then
							SlateBinds.clear(existing)
							queueNotification("Keybind", "Cleared bind for ." .. cmd.name, 2)
						end
					elseif action == "set" and keyName then
						local existing = SlateBinds.keyFor(cmd.name)
						if existing and existing ~= keyName then SlateBinds.clear(existing) end

						local full = cmd.name
						local argText = argBox and argBox.Text or ""
						argText = argText:gsub("^%s+", ""):gsub("%s+$", "")
						if argText ~= "" then full = full .. " " .. argText end
						SlateBinds.set(keyName, full)
						queueNotification("Keybind", keyName .. "  ->  ." .. full, 2)
					end
					paintBind()
				end)
			end)

			if (cmd.isToggle or cmd.autoexecable) and not cmd.args then
				local autoBtn = Instance.new("TextButton", card)
				autoBtn.Size = UDim2.new(0, 54, 0, 26)
				autoBtn.Position = UDim2.new(1, -64, 0.5, -13)
				autoBtn.BorderSizePixel = 0
				autoBtn.Text = "Auto exc"
				autoBtn.TextSize = 9
				autoBtn.TextStrokeTransparency = 1
				autoBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
				Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 5)

				local function updateAutoBtn()
					local isAuto = autoexecConfig[cmd.name] == true
					autoBtn.BackgroundColor3 = isAuto and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(18, 18, 22)
					autoBtn.TextColor3 = isAuto and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(140, 140, 145)
				end
				updateAutoBtn()
				autoBtn.MouseButton1Click:Connect(function()
					if (cmd.isToggle or cmd.autoexecable) and autoexecConfig[cmd.name] == true then
						autoexecConfig[cmd.name] = nil
					else
						autoexecConfig[cmd.name] = true
					end
					saveAutoexecConfig()
					updateAutoBtn()
				end)
			end

			card.MouseButton1Click:Connect(function()
				if cmd.isToggle then
					local newState = not cmd.getState()
					cmd.callback(newState)
					updateCardVisual()
				else
					local argText = argBox and argBox.Text or ""
					cmd.callback(argText)
				end
			end)

			table.insert(commandCards, {
				card = card,
				name = cmd.name,
				desc = cmd.desc,
				favBtn = favBtn,
				originalIndex = idx
			})
		end
	end

	local visibleItems = {}
	local hiddenItems = {}

	for _, item in ipairs(commandCards) do
		local isFav = (favCommandsConfig[item.name] == true)
		if item.favBtn then
			item.favBtn.Image = isFav and favIconId or unfavIconId
			local targetColor = isFav and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 125)
			item.favBtn.ImageColor3 = targetColor
		end

		local matchesQuery = (query == "" or item.name:lower():find(query, 1, true) or item.desc:lower():find(query, 1, true))

		if currentCommandsCategory == "favorites" then
			if isFav and matchesQuery then
				table.insert(visibleItems, item)
			else
				table.insert(hiddenItems, item)
			end
		else
			if matchesQuery then
				table.insert(visibleItems, item)
			else
				table.insert(hiddenItems, item)
			end
		end
	end

	table.sort(visibleItems, function(a, b)
		local aFav = (favCommandsConfig[a.name] == true)
		local bFav = (favCommandsConfig[b.name] == true)
		if aFav ~= bFav then
			return aFav
		end
		return a.originalIndex < b.originalIndex
	end)

	local stepY = 54
	for slotIdx, item in ipairs(visibleItems) do
		local targetPos = UDim2.new(0, 5, 0, 5 + (slotIdx - 1) * stepY)
		if not item.card.Visible then
			item.card.Position = targetPos
			item.card.Visible = true
		elseif animate and item.card.Position ~= targetPos then
			tweenService:Create(item.card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
		else
			item.card.Position = targetPos
			item.card.Visible = true
		end
	end

	for _, item in ipairs(hiddenItems) do
		item.card.Visible = false
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(265, 10 + #visibleItems * stepY))

	local emptyFavLabel = scroll:FindFirstChild("EmptyFavLabel")
	if currentCommandsCategory == "favorites" and #visibleItems == 0 then
		if not emptyFavLabel then
			emptyFavLabel = Instance.new("TextLabel", scroll)
			emptyFavLabel.Name = "EmptyFavLabel"
			emptyFavLabel.Size = UDim2.new(1, -10, 0, 50)
			emptyFavLabel.Position = UDim2.new(0, 5, 0, 20)
			emptyFavLabel.BackgroundTransparency = 1
			emptyFavLabel.Text = "No favorite commands yet — click the star on any command to pin it here!"
			emptyFavLabel.TextColor3 = Color3.fromRGB(120, 120, 125)
			emptyFavLabel.TextStrokeTransparency = 1
			emptyFavLabel.Font = Enum.Font.GothamMedium
			emptyFavLabel.TextSize = 12
		end
		emptyFavLabel.Visible = true
	elseif emptyFavLabel then
		emptyFavLabel.Visible = false
	end
end

loadFavoriteCommands()
loadAutoexecConfig()
renderCommands("")
runAutoexecCommands()

local searchBar = CommandsTab:FindFirstChild("ScriptsSearchBar")
if searchBar then
	searchBar:GetPropertyChangedSignal("Text"):Connect(function()
		renderCommands(searchBar.Text, false)
	end)
end

local cmdSubNav = CommandsTab:FindFirstChild("CmdSubNav")
if cmdSubNav then
	local allBtn = cmdSubNav:FindFirstChild("AllCmdsNavBtn")
	local favBtn = cmdSubNav:FindFirstChild("FavCmdsNavBtn")

	local function switchCmdTab(tabName)
		currentCommandsCategory = tabName
		if tabName == "all" then
			if allBtn then
				allBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 34)
				allBtn.BackgroundTransparency = 0
				allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
			if favBtn then
				favBtn.BackgroundTransparency = 1
				favBtn.TextColor3 = Color3.fromRGB(140, 140, 145)
			end
		else
			if favBtn then
				favBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 34)
				favBtn.BackgroundTransparency = 0
				favBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
			if allBtn then
				allBtn.BackgroundTransparency = 1
				allBtn.TextColor3 = Color3.fromRGB(140, 140, 145)
			end
		end
		renderCommands(nil, true)
	end

	if allBtn then
		allBtn.MouseButton1Click:Connect(function() switchCmdTab("all") end)
	end
	if favBtn then
		favBtn.MouseButton1Click:Connect(function() switchCmdTab("favorites") end)
	end
end
end

do
	localPlayer.Chatted:Connect(function(msg)
		if msg:sub(1,1) == "." then
			local split = msg:sub(2):split(" ")
			local cmdName = split[1]:lower()
			local arg = table.concat(split, " ", 2)
			cmdName = onyxAliases[cmdName] or cmdName
			for _, cmd in ipairs(onyxCommands) do
				if cmd.name == cmdName then
					if cmd.isToggle then
						local newState = not cmd.getState()
						cmd.callback(newState)
					else
						cmd.callback(arg)
					end
					break
				end
			end
		end
	end)
end
end
end)();

do

local function buildThemesTab(category)
	local ROW_H  = 54
	local CTL_H  = 28
	local INSET  = 14
	local EDGE   = 14
	local GAP    = 8
	local SW     = 28
	local HEX_W  = 112
	local BTN_W  = 64

	local CLUSTER = SW + GAP + HEX_W + GAP + BTN_W

	local FONT_R = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	local FONT_B = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

	local function settingVal(id)
		local st = checkSetting(id)
		return st and st.current or nil
	end

	local ACCENT = hexToColor3(settingVal("accentcolor") or "#FFFFFF")
	local CARD   = Color3.fromRGB(18, 16, 24)
	local FIELD  = Color3.fromRGB(28, 25, 37)
	local STROKE = ACCENT:Lerp(Color3.fromRGB(20, 20, 24), 0.72)
	local TEXT   = Color3.fromRGB(236, 233, 243)
	local DIM    = Color3.fromRGB(160, 160, 165)
	local FAINT  = Color3.fromRGB(110, 110, 115)

	local order = 0
	local function nextOrder()
		order = order + 1
		return order
	end

	local function header(text)
		local lbl = Instance.new("TextLabel", SettingsOptionsFrame)
		lbl.Size = UDim2.new(1, -12, 0, 26)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = FAINT
		lbl.TextSize = 10
		lbl.FontFace = FONT_B
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Bottom
		lbl.LayoutOrder = nextOrder()

		Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, INSET)
		return lbl
	end

	local function row(title)
		local frame = Instance.new("Frame", SettingsOptionsFrame)
		frame.Size = UDim2.new(1, -12, 0, ROW_H)
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		frame.LayoutOrder = nextOrder()
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		local st = Instance.new("UIStroke", frame)
		st.Color = STROKE
		st.Thickness = 1
		pcall(function() st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)

		local lbl = Instance.new("TextLabel", frame)
		lbl.Position = UDim2.new(0, INSET, 0, 0)
		lbl.Size = UDim2.new(1, -(INSET + CLUSTER + EDGE + GAP), 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = TEXT
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.FontFace = FONT_B
		return frame
	end

	local function field(parent, width, xFromRight)
		local box = Instance.new("TextBox", parent)
		box.Size = UDim2.new(0, width, 0, CTL_H)
		box.Position = UDim2.new(1, -xFromRight, 0.5, -CTL_H / 2)
		box.BackgroundColor3 = FIELD
		box.BorderSizePixel = 0
		box.TextColor3 = TEXT
		box.PlaceholderColor3 = FAINT
		box.TextSize = 11
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.ClearTextOnFocus = false
		box.TextTruncate = Enum.TextTruncate.AtEnd
		box.FontFace = FONT_R
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
		local bs = Instance.new("UIStroke", box)
		bs.Color = STROKE
		bs.Thickness = 1
		local pad = Instance.new("UIPadding", box)
		pad.PaddingLeft = UDim.new(0, 9)
		pad.PaddingRight = UDim.new(0, 9)
		box.Focused:Connect(function()
			tweenService:Create(bs, TweenInfo.new(0.14), {Color = ACCENT}):Play()
		end)
		box.FocusLost:Connect(function()
			tweenService:Create(bs, TweenInfo.new(0.14), {Color = STROKE}):Play()
		end)
		return box
	end

	local function button(parent, text, width, xFromRight)
		local btn = Instance.new("TextButton", parent)
		btn.Size = UDim2.new(0, width, 0, CTL_H)
		btn.Position = UDim2.new(1, -xFromRight, 0.5, -CTL_H / 2)
		btn.BackgroundColor3 = ACCENT
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Text = text
		do
			local _l = 0.2126 * ACCENT.R + 0.7152 * ACCENT.G + 0.0722 * ACCENT.B
			btn.TextColor3 = (_l > 0.55) and Color3.fromRGB(12, 12, 14) or Color3.fromRGB(238, 238, 242)
		end
		btn.TextSize = 11
		btn.FontFace = FONT_B
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseEnter:Connect(function()
			tweenService:Create(btn, TweenInfo.new(0.14),
				{BackgroundColor3 = ACCENT:Lerp(Color3.new(1, 1, 1), 0.18)}):Play()
		end)
		btn.MouseLeave:Connect(function()
			tweenService:Create(btn, TweenInfo.new(0.14), {BackgroundColor3 = ACCENT}):Play()
		end)
		return btn
	end

	header("COLOURS")

	local function colourRow(title, id)
		local st = checkSetting(id)
		if not st then return end
		local frame = row(title)

		local swatch = Instance.new("Frame", frame)
		swatch.Size = UDim2.new(0, SW, 0, SW)
		swatch.Position = UDim2.new(1, -(EDGE + CLUSTER), 0.5, -SW / 2)
		swatch.BackgroundColor3 = hexToColor3(st.current)
		swatch.BorderSizePixel = 0
		Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 6)
		local ss = Instance.new("UIStroke", swatch)
		ss.Color = STROKE
		ss.Thickness = 1

		local hex = field(frame, HEX_W, EDGE + BTN_W + GAP + HEX_W)
		hex.Text = tostring(st.current or "#FFFFFF")

		local apply = button(frame, "Apply", BTN_W, EDGE + BTN_W)

		local function commit()
			local v = hex.Text
			if not v:match("^#?%x%x%x%x%x%x$") then
				hex.Text = tostring(st.current or "#FFFFFF")
				return
			end
			if v:sub(1, 1) ~= "#" then v = "#" .. v end
			st.current = v
			hex.Text = v
			swatch.BackgroundColor3 = hexToColor3(v)
			local ms, as = checkSetting("maincolor"), checkSetting("accentcolor")
			if ms and as then applyTheme(ms.current, as.current) end
			saveSettings()

			if id == "accentcolor" then openCategory(category) end
		end
		apply.MouseButton1Click:Connect(commit)
		hex.FocusLost:Connect(function(enter) if enter then commit() end end)
	end

	colourRow("Main background", "maincolor")
	colourRow("Accent", "accentcolor")

	header("THEME")

	local activeSt = checkSetting("activetheme")
	do
		local frame = row("Active theme")

		local chip = Instance.new("Frame", frame)
		chip.Size = UDim2.new(0, CLUSTER, 0, CTL_H)
		chip.Position = UDim2.new(1, -(EDGE + CLUSTER), 0.5, -CTL_H / 2)
		chip.BackgroundColor3 = FIELD
		chip.BorderSizePixel = 0
		Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 6)
		local cs = Instance.new("UIStroke", chip)
		cs.Color = STROKE
		cs.Thickness = 1

		local dot = Instance.new("Frame", chip)
		dot.Size = UDim2.new(0, 8, 0, 8)
		dot.Position = UDim2.new(0, 10, 0.5, -4)
		dot.BackgroundColor3 = ACCENT
		dot.BorderSizePixel = 0
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

		local name = Instance.new("TextLabel", chip)
		name.Position = UDim2.new(0, 24, 0, 0)
		name.Size = UDim2.new(1, -34, 1, 0)
		name.BackgroundTransparency = 1
		name.Text = tostring((activeSt and activeSt.current) or "Custom")
		name.TextColor3 = TEXT
		name.TextSize = 11
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.FontFace = FONT_R
	end

	local bgSt = checkSetting("custombackgroundid")
	if bgSt then
		local frame = row("Custom background image")
		local box = field(frame, CLUSTER, EDGE + CLUSTER)
		box.Text = tostring(bgSt.current or "")
		box.PlaceholderText = "Asset ID, or blank for none"
		box.FocusLost:Connect(function()
			bgSt.current = box.Text
			saveSettings()
		end)
	end

	header("PRESETS")

	local PER_ROW, CARD_H, CARD_GAP = 5, 58, 10
	local rows = math.ceil(#slatePresetThemes / PER_ROW)

	local grid = Instance.new("Frame", SettingsOptionsFrame)
	grid.Size = UDim2.new(1, -12, 0, rows * (CARD_H + CARD_GAP) - CARD_GAP)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.LayoutOrder = nextOrder()
	local gl = Instance.new("UIGridLayout", grid)

	gl.CellSize = UDim2.new(0.2, -8, 0, CARD_H)
	gl.CellPadding = UDim2.new(0, CARD_GAP, 0, CARD_GAP)
	gl.SortOrder = Enum.SortOrder.LayoutOrder

	for i, theme in ipairs(slatePresetThemes) do
		local isActive = activeSt and activeSt.current == theme.name
		local cmain, cacc = hexToColor3(theme.main), hexToColor3(theme.accent)

		local card = Instance.new("TextButton", grid)
		card.LayoutOrder = i
		card.BackgroundColor3 = cmain
		card.BorderSizePixel = 0
		card.AutoButtonColor = false
		card.Text = ""
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		local grad = Instance.new("UIGradient", card)
		grad.Rotation = 32
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, cmain),
			ColorSequenceKeypoint.new(0.55, cacc:Lerp(cmain, 0.74)),
			ColorSequenceKeypoint.new(1.0, cacc:Lerp(cmain, 0.34)),
		})

		local cst = Instance.new("UIStroke", card)
		cst.Thickness = isActive and 1.6 or 1
		cst.Color = isActive and cacc or STROKE

		local dot = Instance.new("Frame", card)
		dot.Size = UDim2.new(0, 10, 0, 10)
		dot.Position = UDim2.new(0, 9, 0, 9)
		dot.BackgroundColor3 = cacc
		dot.BorderSizePixel = 0
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

		local nm = Instance.new("TextLabel", card)
		nm.Position = UDim2.new(0, 9, 1, -22)
		nm.Size = UDim2.new(1, -18, 0, 14)
		nm.BackgroundTransparency = 1
		nm.Text = theme.name
		nm.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(214, 209, 226)
		nm.TextSize = 10
		nm.TextXAlignment = Enum.TextXAlignment.Left
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.FontFace = FONT_B

		if isActive then
			local tick = Instance.new("TextLabel", card)
			tick.AnchorPoint = Vector2.new(1, 0)
			tick.Position = UDim2.new(1, -8, 0, 6)
			tick.Size = UDim2.new(0, 14, 0, 14)
			tick.BackgroundTransparency = 1
			tick.Text = "\u{2713}"
			tick.TextColor3 = cacc
			tick.TextSize = 13
			tick.FontFace = FONT_B
		end

		card.MouseEnter:Connect(function()
			tweenService:Create(cst, TweenInfo.new(0.15), {Color = cacc}):Play()
		end)
		card.MouseLeave:Connect(function()
			if not isActive then
				tweenService:Create(cst, TweenInfo.new(0.15), {Color = STROKE}):Play()
			end
		end)
		card.MouseButton1Click:Connect(function()
			applyTheme(theme.main, theme.accent)
			if activeSt then activeSt.current = theme.name end
			local ms, as = checkSetting("maincolor"), checkSetting("accentcolor")
			if ms then ms.current = theme.main end
			if as then as.current = theme.accent end
			saveSettings()
			openCategory(category)
		end)
	end
end

function openCategory(category)
	for _, child in ipairs(SettingsOptionsFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	SettingsCategories.Visible = false
	SettingsOptionsFrame.Visible = true
	SettingsBackBtn.Visible = true
	SettingsTitle.Text = category.name
	local layout = SettingsOptionsFrame:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.SortOrder = Enum.SortOrder.LayoutOrder
	end

	if category.name == "Themes" then
		buildThemesTab(category)
		return
	end

	for i, setting in ipairs(category.categorySettings) do
		if setting.id == "spotifyoauthtoken" or setting.id == "spotifyrefreshtoken" or setting.id == "spotifyclientid" or setting.id == "spotifyclientsecret" then
			continue
		end
		local frame = Instance.new("Frame", SettingsOptionsFrame)
		frame.Size = UDim2.new(1, -12, 0, 48)
		frame.LayoutOrder = i
		frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
		frame.BorderSizePixel = 0
		local corner = Instance.new("UICorner", frame)
		corner.CornerRadius = UDim.new(0, 8)
		local frameStroke = Instance.new("UIStroke", frame)
		frameStroke.Color = Color3.fromRGB(32, 32, 34)
		frameStroke.Thickness = 1
		pcall(function() frameStroke.ApplyType = "Border" end)

		local lbl = Instance.new("TextLabel", frame)
		lbl.Size = UDim2.new(0.55, 0, 1, 0)
		lbl.Position = UDim2.new(0, 14, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(230, 230, 235)
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		lbl.Text = setting.name

		if setting.settingType == "Boolean" then
			local toggle = Instance.new("TextButton", frame)
			toggle.Size = UDim2.new(0, 52, 0, 26)
			toggle.Position = UDim2.new(1, -66, 0.5, -13)
			toggle.BackgroundColor3 = setting.current and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(32, 32, 38)
			toggle.TextColor3 = setting.current and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
			toggle.Text = setting.current and "ON" or "OFF"
			toggle.TextSize = 9
			toggle.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

			local toggleStroke = Instance.new("UIStroke", toggle)
			toggleStroke.Color = setting.current and Color3.fromRGB(80, 80, 85) or Color3.fromRGB(48, 48, 56)
			toggleStroke.Thickness = 1
			toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			toggle.MouseButton1Click:Connect(function()
				setting.current = not setting.current
				toggle.BackgroundColor3 = setting.current and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(32, 32, 38)
				toggleStroke.Color = setting.current and Color3.fromRGB(80, 80, 85) or Color3.fromRGB(48, 48, 56)
				toggle.TextColor3 = setting.current and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
				toggle.Text = setting.current and "ON" or "OFF"
				saveSettings()

				pcall(function()
					if setting.id == "muffleunfocused" then
						if not setting.current then

							gameSettings.MasterVolume = oldVolume or 1
						end
					elseif setting.id == "fpsunfocused" then
						if not setting.current and setfpscap then
							local fpscapSet = checkSetting("fpscap")
							local targetCap = (fpscapSet and tonumber(fpscapSet.current)) or 240
							setfpscap(targetCap)
						end
					elseif setting.id == "disableallnotifs" then
						if setting.current then
							table.clear(islandNotificationQueue)
							_G.isShowingIslandNotif = false
							_G.isShowingOwnerNotification = false
							if G2L and G2L["30"] then
								for _, child in ipairs(G2L["30"]:GetChildren()) do
									if child.Name == "IslandNotifyFrame" or child.Name == "OwnerNotify" then
										pcall(function() child:Destroy() end)
									end
								end
							end
							if not smartBarOpen and IslandGroup then
								IslandGroup.Visible = true
								if updateIslandLayout then updateIslandLayout() end
							end
						end
					elseif setting.id == "antikick" then
						if setting.current then execCmd("clientantikick") end
					elseif setting.id == "antiidle" then
						if setting.current then execCmd("antiafk") end
					end
				end)
			end)
		elseif setting.settingType == "Input" or setting.settingType == "Number" then
			local box = Instance.new("TextBox", frame)
			box.BorderSizePixel = 0
			box.Size = UDim2.new(0, 220, 0, 26)
			box.Position = UDim2.new(1, -234, 0.5, -13)
			box.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
			box.TextColor3 = Color3.fromRGB(220, 220, 230)
			box.TextSize = 11
			box.Text = tostring(setting.current)
			box.ClipsDescendants = true
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.ClearTextOnFocus = false
			box.TextTruncate = Enum.TextTruncate.AtEnd
			box.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

			local boxPadding = Instance.new("UIPadding", box)
			boxPadding.PaddingLeft = UDim.new(0, 8)
			boxPadding.PaddingRight = UDim.new(0, 8)

			box.Focused:Connect(function()
				if box.Text == "No Webhook" then
					box.Text = ""
				end
			end)

			box.FocusLost:Connect(function()
				if setting.settingType == "Number" then
					setting.current = tonumber(box.Text) or setting.current
				else
					setting.current = box.Text
				end
				if setting.current == "" and setting.id:find("url") then
					setting.current = "No Webhook"
				end
				box.Text = tostring(setting.current)
				saveSettings()
			end)
		elseif setting.settingType == "Key" then
			local bindBtn = Instance.new("TextButton", frame)
			bindBtn.Size = UDim2.new(0, 80, 0, 26)
			bindBtn.Position = UDim2.new(1, -94, 0.5, -13)
			bindBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
			bindBtn.TextColor3 = Color3.fromRGB(210, 210, 220)
			bindBtn.Text = setting.current or "None"
			bindBtn.TextSize = 10
			bindBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 6)

			local bindStroke = Instance.new("UIStroke", bindBtn)
			bindStroke.Color = Color3.fromRGB(42, 42, 50)
			bindStroke.Thickness = 1
			bindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			bindBtn.MouseButton1Click:Connect(function()
				if setting.current and setting.current ~= "None" then
					setting.current = nil
					bindBtn.Text = "None"
					saveSettings()
				else
					bindBtn.Text = "..."
					local conn
					conn = userInputService.InputBegan:Connect(function(input)
						if input.KeyCode ~= Enum.KeyCode.Unknown then
							local key = string.split(tostring(input.KeyCode), ".")[3]
							setting.current = key
							bindBtn.Text = key
							conn:Disconnect()
							saveSettings()
						end
					end)
				end
			end)
	elseif setting.settingType == "Color" then
		frame.Size = UDim2.new(1, -12, 0, 52)
		local swatch = Instance.new("Frame", frame)
		swatch.Size = UDim2.new(0, 24, 0, 24)
		swatch.Position = UDim2.new(1, -265, 0.5, -12)
		swatch.BackgroundColor3 = hexToColor3(setting.current)
		swatch.BorderSizePixel = 0
		Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 5)
		local swStroke = Instance.new("UIStroke", swatch)
		swStroke.Color = Color3.fromRGB(70, 70, 90); swStroke.Thickness = 1
		local hexBox = Instance.new("TextBox", frame)
		hexBox.Size = UDim2.new(0, 95, 0, 26)
		hexBox.Position = UDim2.new(1, -160, 0.5, -13)
		hexBox.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
		hexBox.TextColor3 = Color3.fromRGB(220, 220, 230)
		hexBox.TextSize = 11
		hexBox.Text = tostring(setting.current or "#FFFFFF")
		hexBox.ClearTextOnFocus = false
		hexBox.TextXAlignment = Enum.TextXAlignment.Left
		hexBox.BorderSizePixel = 0
		hexBox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 6)
		Instance.new("UIPadding", hexBox).PaddingLeft = UDim.new(0, 7)
		local applyColorBtn = Instance.new("TextButton", frame)
		applyColorBtn.Size = UDim2.new(0, 55, 0, 26)
		applyColorBtn.Position = UDim2.new(1, -57, 0.5, -13)
		applyColorBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
		applyColorBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
		applyColorBtn.Text = "Apply"
		applyColorBtn.TextSize = 10
		applyColorBtn.BorderSizePixel = 0
		applyColorBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		Instance.new("UICorner", applyColorBtn).CornerRadius = UDim.new(0, 6)
		local function doApplyColor()
			local hex = hexBox.Text
			if not hex:match("^#?%x%x%x%x%x%x$") then return end
			if hex:sub(1,1) ~= "#" then hex = "#" .. hex end
			setting.current = hex
			swatch.BackgroundColor3 = hexToColor3(hex)
			local ms = checkSetting("maincolor")
			local as2 = checkSetting("accentcolor")
			if ms and as2 then applyTheme(ms.current, as2.current) end
			saveSettings()
		end
		applyColorBtn.MouseButton1Click:Connect(doApplyColor)
		hexBox.FocusLost:Connect(function(e) if e then doApplyColor() end end)
	elseif setting.settingType == "Hidden" then
		frame.Visible = false
		frame.Size = UDim2.new(0, 0, 0, 0)
	end
	end
end
SettingsBackBtn.MouseButton1Click:Connect(function()
	SettingsCategories.Visible = true
	SettingsOptionsFrame.Visible = false
	SettingsBackBtn.Visible = false
	SettingsTitle.Text = "Settings & Config"
end)
for _, cat in ipairs(siriusSettings) do
	local card = Instance.new("Frame", SettingsCategories)
	card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	card.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", card)
	stroke.Color = Color3.fromRGB(42, 42, 50)
	stroke.Thickness = 1
	local corner = Instance.new("UICorner", card)
	corner.CornerRadius = UDim.new(0, 8)
	local btn = Instance.new("TextButton", card)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = cat.name
	btn.TextColor3 = Color3.fromRGB(240, 240, 245)
	btn.TextSize = 13
	btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

	btn.MouseEnter:Connect(function()
		tweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(26, 26, 32)}):Play()
		tweenService:Create(stroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(65, 65, 75)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		tweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(16, 16, 20)}):Play()
		tweenService:Create(stroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(42, 42, 50)}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		openCategory(cat)
	end)
end
end

do
	runService.Heartbeat:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		local character = localPlayer.Character
		local primaryPart = character and character.PrimaryPart
		if primaryPart then
			movers = movers or {}
			local bodyVelocity, bodyGyro = (unpack or table.unpack)(movers)
			if bodyVelocity then
				local alive = bodyVelocity.Parent ~= nil
				if not alive then movers = {} bodyVelocity, bodyGyro = nil, nil end
			end
			if not bodyVelocity then
				bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.one * 9e9
				bodyGyro = Instance.new("BodyGyro")
				bodyGyro.MaxTorque = Vector3.one * 9e9
				bodyGyro.P = 9e4
				local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
				bodyAngularVelocity.AngularVelocity = Vector3.yAxis * 9e9
				bodyAngularVelocity.MaxTorque = Vector3.yAxis * 9e9
				bodyAngularVelocity.P = 9e9
				movers = {bodyVelocity, bodyGyro, bodyAngularVelocity}
			end
			if siriusValues.actions[2].enabled then
				local camCFrame = camera.CFrame
				local velocity = Vector3.zero
				local rotation = camCFrame.Rotation
				if userInputService:IsKeyDown(Enum.KeyCode.W) then velocity += camCFrame.LookVector end
				if userInputService:IsKeyDown(Enum.KeyCode.S) then velocity -= camCFrame.LookVector end
				if userInputService:IsKeyDown(Enum.KeyCode.D) then velocity += camCFrame.RightVector end
				if userInputService:IsKeyDown(Enum.KeyCode.A) then velocity -= camCFrame.RightVector end
				if userInputService:IsKeyDown(Enum.KeyCode.Space) then velocity += Vector3.yAxis end
				if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then velocity -= Vector3.yAxis end
				bodyVelocity.Velocity = velocity * siriusValues.sliders[3].value * 45
				bodyVelocity.Parent = primaryPart
				bodyGyro.CFrame = rotation
				bodyGyro.Parent = primaryPart
			else
				bodyVelocity.Parent = nil
				bodyGyro.Parent = nil
			end
		end
	end))

	local _noclipPartsCache = {}
	local _noclipCacheChar = nil
	local _noclipCacheConns = {}
	local function _rebuildNoclipCache()
		table.clear(_noclipPartsCache)
		local ch = localPlayer.Character
		_noclipCacheChar = ch
		if ch then
			for _, part in ipairs(ch:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(_noclipPartsCache, part)
				end
			end
		end
	end
	local function _ensureNoclipCache()
		local ch = localPlayer.Character
		if ch ~= _noclipCacheChar then
			for _, c in ipairs(_noclipCacheConns) do pcall(function() c:Disconnect() end) end
			table.clear(_noclipCacheConns)
			_rebuildNoclipCache()
			if ch then
				table.insert(_noclipCacheConns, ch.DescendantAdded:Connect(function(d)
					if d:IsA("BasePart") then table.insert(_noclipPartsCache, d) end
				end))
				table.insert(_noclipCacheConns, ch.DescendantRemoving:Connect(function(d)
					if d:IsA("BasePart") then
						local idx = table.find(_noclipPartsCache, d)
						if idx then table.remove(_noclipPartsCache, idx) end
					end
				end))
			end
		end
	end
	local wasActiveStepped = false
	runService.Stepped:Connect((function()
		LPS_ATTRIBUTES(VM(NONE), TRANSFORM(CONTROL_FLOW))
		local character = localPlayer.Character
		if not character then return end
		local noclip = siriusValues.actions[1].enabled or (_noclipConn ~= nil)
		local fling = siriusValues.actions[6].enabled
		local active = noclip or fling
		if active then
			wasActiveStepped = true
			_ensureNoclipCache()
			for _, part in ipairs(_noclipPartsCache) do
				if part.Parent then
					if noclipDefaults[part] == nil then noclipDefaults[part] = part.CanCollide end
					part.CanCollide = false
				end
			end
		elseif wasActiveStepped then
			wasActiveStepped = false
			for _, part in ipairs(_noclipPartsCache) do
				if part.Parent and noclipDefaults[part] ~= nil then
					part.CanCollide = noclipDefaults[part]
				end
			end
		end
	end))
end

do
	userInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		local smartbarSetting = checkSetting("smartbar")
		if smartbarSetting and smartbarSetting.current and smartbarSetting.current ~= "" and smartbarSetting.current ~= "None" then
			pcall(function()
				if input.KeyCode == Enum.KeyCode[smartbarSetting.current] then
					SlateUiSound.click()
					toggleMainWindow()
				end
			end)
		end

		for _, category in ipairs(siriusSettings) do
			for i, setting in ipairs(category.categorySettings) do
				if setting.settingType == "Key" and setting.id ~= "smartbar" and setting.id ~= "cmdbar" then
					if setting.current and setting.current ~= "" and setting.current ~= "None" then
						pcall(function()
							if input.KeyCode == Enum.KeyCode[setting.current] then
								for _, act in ipairs(siriusValues.actions) do
									if act.name:lower() == setting.name:lower() or (setting.name == "ESP" and act.name == "ESP") or (setting.name == "Night and Day" and act.name == "Night / Day") then
										act.enabled = not act.enabled
										act.callback(act.enabled)
										local actContainer = CharacterTab:FindFirstChild("ActionsContainer") or CharacterTab:FindFirstChildOfClass("Frame")
										if actContainer then
											for _, child in ipairs(actContainer:GetChildren()) do
												if child:IsA("Frame") and child:FindFirstChildOfClass("TextButton") and child:FindFirstChildOfClass("TextButton").Text:lower() == act.name:lower() then
													child.BackgroundColor3 = act.enabled and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(30, 30, 30)
												end
											end
										end
										queueNotification("Hotkey Triggered", act.name .. " is now " .. (act.enabled and "Enabled" or "Disabled"))
									end
								end
							end
						end)
					end
				end
			end
		end
	end)
end

localPlayer.Idled:Connect(function()
	local antiIdleSetting = checkSetting("antiidle")
	if antiIdleSetting and antiIdleSetting.current then

	end
end)

function spyChat(msgData)
	local chatspySetting = checkSetting("chatspy")
	if chatspySetting and chatspySetting.current and msgData then
		local sender = msgData.FromCreator
		local message = msgData.Message
		if sender ~= localPlayer.Name then
			pcall(function()
				starterGui:SetCore("ChatMakeSystemMessage", {
					Text = "[Spy] [" .. sender .. "]: " .. message,
					Color = Color3.fromRGB(230, 200, 15),
					Font = Enum.Font.SourceSansBold
				})
			end)
		end
	end
end
if getMessage then getMessage.OnClientEvent:Connect(spyChat) end

function logToWebhook(url, payload)
	local reqFunc = http_request or request or (syn and syn.request)
	if reqFunc and url and url ~= "No Webhook" then
		pcall(reqFunc, {
			Url = url,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = httpService:JSONEncode(payload)
		})
	end
end

task.spawn(function()
	_G.SlateChatConnections = _G.SlateChatConnections or {}
	local function onChatMessage(player, messageText)
		local logSetting = checkSetting("logmsg")
		local logUrlSetting = checkSetting("logmsgurl")
		if logSetting and logSetting.current and logUrlSetting and logUrlSetting.current ~= "" and logUrlSetting.current ~= "No Webhook" then
			local function formatUsername(plr)
				if not plr then return "Unknown" end
				local disp = plr.DisplayName or plr.Name or "Unknown"
				local name = plr.Name or "Unknown"
				if disp ~= name then
					return string.format("%s (@%s)", disp, name)
				end
				return name
			end

			local avatar = "https://files.catbox.moe/i968v2.jpg"
			local username = "System"
			if player then
				local id = player.UserId
				avatar = avatarcache and avatarcache[id]
				if not avatar then
					local reqFunc = http_request or request or (syn and syn.request)
					if reqFunc then
						pcall(function()
							local res = reqFunc({
								Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. id .. "&size=420x420&format=Png&isCircular=false",
								Method = "GET"
							})
							if res and res.Body then
								local d = httpService:JSONDecode(res.Body)["data"]
								avatar = d and d[1].state == "Completed" and d[1].imageUrl or "https://files.catbox.moe/i968v2.jpg"
								if avatarcache then
									avatarcache[id] = avatar
								end
							end
						end)
					end
				end
				username = formatUsername(player)
			end
			logToWebhook(logUrlSetting.current, {
				content = messageText,
				avatar_url = avatar,
				username = username,
				allowed_mentions = {parse = {}}
			})
		end
	end

	if isLegacyChat then
		local conn1 = players.PlayerAdded:Connect(function(plr)
			local conn2 = plr.Chatted:Connect(function(msg)
				onChatMessage(plr, msg)
			end)
			table.insert(_G.SlateChatConnections, conn2)
		end)
		table.insert(_G.SlateChatConnections, conn1)

		for _, p in ipairs(players:GetPlayers()) do
			local conn3 = p.Chatted:Connect(function(msg)
				onChatMessage(p, msg)
			end)
			table.insert(_G.SlateChatConnections, conn3)
		end
	else
		local hasTCS, tcs = pcall(game.GetService, game, "TextChatService")
		if hasTCS and tcs then
			pcall(function()
				local conn4 = tcs.MessageReceived:Connect(function(message)
					if message.TextSource then
						local player = players:GetPlayerByUserId(message.TextSource.UserId)
						if player then
							onChatMessage(player, message.Text)
						end
					end
				end)
				table.insert(_G.SlateChatConnections, conn4)
			end)
		end
	end
end)

task.spawn(function()
	while true do
		local shieldSetting = checkSetting("spatialshield")
		local thresholdSetting = checkSetting("spatialshieldthreshold")
		if shieldSetting and shieldSetting.current and localPlayer.Character then
			local myRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if myRoot then
				local threshold = thresholdSetting and thresholdSetting.current or 300
				for _, player in ipairs(players:GetPlayers()) do
					if player ~= localPlayer and player.Character then
						local root = player.Character:FindFirstChild("HumanoidRootPart")
						if root then
							local dist = (myRoot.Position - root.Position).Magnitude
							if dist < 35 then
								if root.AssemblyAngularVelocity.Magnitude > threshold or root.AssemblyLinearVelocity.Magnitude > threshold then
									root.AssemblyLinearVelocity = Vector3.zero
									root.AssemblyAngularVelocity = Vector3.zero
									for _, part in ipairs(player.Character:GetDescendants()) do
										if part:IsA("BasePart") then
											part.CanCollide = false
										end
									end
								end
							end
						end
					end
				end
			end
		end
		task.wait(0.1)
	end
end)

players.PlayerAdded:Connect(function(player)
	local friendSetting = checkSetting("friendnotifs")
	local isFriend = false
	pcall(function() isFriend = player:IsFriendsWith(localPlayer.UserId) end)
	if friendSetting and friendSetting.current and isFriend then
		queueNotification("Friend Joined", player.DisplayName .. " joined the game.")
	end
	local logJoinSetting = checkSetting("logplrjoinleave")
	local logJoinUrlSetting = checkSetting("logplrjoinleaveurl")
	if logJoinSetting and logJoinSetting.current and logJoinUrlSetting and logJoinUrlSetting.current ~= "No Webhook" then
		logToWebhook(logJoinUrlSetting.current, {content = player.Name .. " has joined the server."})
	end
end)
players.PlayerRemoving:Connect(function(player)
	local friendSetting = checkSetting("friendnotifs")
	local isFriend = false
	pcall(function() isFriend = player:IsFriendsWith(localPlayer.UserId) end)
	if friendSetting and friendSetting.current and isFriend then
		queueNotification("Friend Left", player.DisplayName .. " left the game.")
	end
	local logJoinSetting = checkSetting("logplrjoinleave")
	local logJoinUrlSetting = checkSetting("logplrjoinleaveurl")
	if logJoinSetting and logJoinSetting.current and logJoinUrlSetting and logJoinUrlSetting.current ~= "No Webhook" then
		logToWebhook(logJoinUrlSetting.current, {content = player.Name .. " has left the server."})
	end
end)

do
	local approvedDomains = {}
	local function getDomain(url)
		local domain = string.match(url, "^https?://([^/]+)")
		return domain or url
	end

	local function promptSecurity(url)
		local domain = getDomain(url)
		if approvedDomains[domain] then
			return true
		end

		local event = Instance.new("BindableEvent")
		local promptFrame = Instance.new("Frame", G2L["1"])
		promptFrame.Name = "SecurityPrompt"
		promptFrame.Size = UDim2.new(0, 320, 0, 150)
		promptFrame.Position = UDim2.new(0.5, -160, 0.5, -75)
		promptFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		promptFrame.BorderSizePixel = 0

		local corner = Instance.new("UICorner", promptFrame)
		corner.CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke", promptFrame)
		stroke.Color = Color3.fromRGB(20, 20, 20)
		stroke.Thickness = 1
		pcall(function() stroke.ApplyType = "Border" end)

		local title = Instance.new("TextLabel", promptFrame)
		title.Size = UDim2.new(1, -40, 0, 20)
		title.Position = UDim2.new(0, 20, 0, 20)
		title.BackgroundTransparency = 1
		title.Text = "HTTP Authorization"
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 15
		title.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		title.TextXAlignment = Enum.TextXAlignment.Left

		local desc = Instance.new("TextLabel", promptFrame)
		desc.Size = UDim2.new(1, -40, 0, 45)
		desc.Position = UDim2.new(0, 20, 0, 45)
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Color3.fromRGB(150, 150, 150)
		desc.Text = "http request detected, authorize if trusted.\n" .. tostring(domain)
		desc.TextSize = 12
		desc.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left

		local function createButton(text, bgCol, textCol, pos, size)
			local btn = Instance.new("TextButton", promptFrame)
			btn.Size = size
			btn.Position = pos
			btn.BackgroundColor3 = bgCol
			btn.TextColor3 = textCol
			btn.Text = text
			btn.TextSize = 12
			btn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

			btn.MouseEnter:Connect(function()
				tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 24)}):Play()
			end)
			btn.MouseLeave:Connect(function()
				tweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = bgCol}):Play()
			end)
			return btn
		end

		local denyBtn = createButton("Deny", Color3.fromRGB(15, 15, 15), Color3.fromRGB(110, 110, 115), UDim2.new(0, 20, 1, -48), UDim2.new(0, 75, 0, 28))
		local allowBtn = createButton("Allow", Color3.fromRGB(15, 15, 15), Color3.fromRGB(255, 255, 255), UDim2.new(0, 105, 1, -48), UDim2.new(0, 85, 0, 28))
		local alwaysBtn = createButton("Always", Color3.fromRGB(15, 15, 15), Color3.fromRGB(255, 255, 255), UDim2.new(0, 198, 1, -48), UDim2.new(0, 102, 0, 28))

		makeDraggable(promptFrame, promptFrame)

		denyBtn.MouseButton1Click:Connect(function()
			event:Fire(false)
			promptFrame:Destroy()
		end)
		allowBtn.MouseButton1Click:Connect(function()
			event:Fire(true)
			promptFrame:Destroy()
		end)
		alwaysBtn.MouseButton1Click:Connect(function()
			approvedDomains[domain] = true
			event:Fire(true)
			promptFrame:Destroy()
		end)

		local result = event.Event:Wait()
		event:Destroy()
		return result
	end

	local originalRequest = http_request or request or (syn and syn.request)
	if originalRequest then
		local wrappedRequest = function(options)
			local interceptSetting = checkSetting("httpinterception")
			if interceptSetting and interceptSetting.current and options and options.Url then
				local urlLower = string.lower(options.Url)
				local domain = getDomain(options.Url)

				local safeDomains = {
					"roblox.com",
					"onyxv2.lol",
					"githubusercontent.com",
					"github.com",
					"raw.githubusercontent.com",
					"spotify.com",
					"discord.com",
					"discord.gg",
					"127.0.0.1",
					"i.postimg.cc",
					"postimg.cc",
					"files.catbox.moe",
					"catbox.moe",
					"ib2.dev",
					"scripts.ib2.dev",
					"roproxy.com",
					"catalog.roproxy.com",
					"i.imgur.com",

					"soundcloud.com",
					"api-v2.soundcloud.com",
					"api.soundcloud.com",
					"sndcdn.com",
					"a-v2.sndcdn.com",
					"i1.sndcdn.com",
					"i2.sndcdn.com",
					"i3.sndcdn.com",
					"i4.sndcdn.com",
					"cf-media.sndcdn.com",
					"cf-hls-media.sndcdn.com",
					"soundcloud.cloud",
					"media-streaming.soundcloud.cloud",
					"playback.media-streaming.soundcloud.cloud",

					"deezer.com",
					"api.deezer.com",
					"dzcdn.net",
					"cdns-images.dzcdn.net",
					"apple.com",
					"itunes.apple.com",
					"mzstatic.com",

					"tenor.com",
					"media.tenor.com",
					"c.tenor.com",
					"giphy.com",
					"media.giphy.com",
					"postimg.cc",
					"i.postimg.cc",
					"postimages.org",
                    "gallery.yopriceville.com",
					"sl8ght.xyz"
				}
				local isSafe = false
				for _, sd in ipairs(safeDomains) do
					if string.find(urlLower, sd) then
						isSafe = true
						break
					end
				end

				if not isSafe then
					local allowed = promptSecurity(options.Url)
					if not allowed then
						queueNotification("HTTP Intercepted", "Blocked request to: " .. tostring(domain))
						return {StatusCode = 403, Body = "Blocked by user HTTP Interception"}
					end
				end
			end
			return originalRequest(options)
		end
		if http_request then http_request = wrappedRequest end
		if request then request = wrappedRequest end
		if syn and syn.request then syn.request = wrappedRequest end
	end
end

do
	local originalClipboard = setclipboard or toclipboard
	if originalClipboard then
		local wrappedClipboard = function(text)
			local clipSetting = checkSetting("clipinterception")
			if clipSetting and clipSetting.current then
				queueNotification("Clipboard Modified", "Copy intercepted: " .. string.sub(text, 1, 30) .. "...")
			end
			originalClipboard(text)
		end
		if setclipboard then setclipboard = wrappedClipboard end
		if toclipboard then toclipboard = wrappedClipboard end
	end
end

local oldVolume = 1
userInputService.WindowFocusReleased:Connect(function()
	local muffleSetting = checkSetting("muffleunfocused")
	if muffleSetting and muffleSetting.current then
		pcall(function()
			oldVolume = gameSettings.MasterVolume or 1
			gameSettings.MasterVolume = oldVolume * 0.1
		end)
	end
	local fpsUnfocusedSetting = checkSetting("fpsunfocused")
	if fpsUnfocusedSetting and fpsUnfocusedSetting.current and setfpscap then
		pcall(setfpscap, 20)
	end
end)
userInputService.WindowFocused:Connect(function()
	local muffleSetting = checkSetting("muffleunfocused")
	if muffleSetting and muffleSetting.current then
		pcall(function()
			gameSettings.MasterVolume = oldVolume or 1
		end)
	end

	local fpsUnfocusedSetting = checkSetting("fpsunfocused")
	if fpsUnfocusedSetting and fpsUnfocusedSetting.current and setfpscap then
		local fpscapSetting = checkSetting("fpscap")
		local targetCap = (fpscapSetting and tonumber(fpscapSetting.current)) or 240
		pcall(setfpscap, targetCap)
	end
end)

do
	local fpscapSetting = checkSetting("fpscap")
	if fpscapSetting and fpscapSetting.current and setfpscap then

	end
end

task.spawn(function()
	_awaitPrefetch("client", 5)
	loadstring(_prefetchedScripts.client or game:HttpGet(LPS_ENCSTR("https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/client.lua")))()
end)

function sanitizeBorderFrames(parent)

end
G2L["1"].DescendantAdded:Connect(function(desc)
	if desc:IsA("Frame") and desc.Name == "BorderFrame" then
		desc.BorderSizePixel = 0
	end
end)

function playHoverSound()

end
function hookHoverSound(parent)

end

task.spawn(function()
	if G2L and G2L["2"] then
		G2L["2"].Visible = false
	end
	G2L["30"].Visible = true
	_G.SlateRealIslandReady = true
	closeSmartBar()
	queueNotification("Slate", "Backend connected")
end)

task.spawn(function()
local SHOW_UI_ON_EXECUTE = false

local players         = game:GetService("Players")
local tweenService    = tweenService
local userInputSvc    = game:GetService("UserInputService")
local httpService     = game:GetService("HttpService")
local runService      = game:GetService("RunService")
local marketplaceService = game:GetService("MarketplaceService")
local localPlr        = players.LocalPlayer
local panelHost       = (gethui and gethui()) or game:GetService("CoreGui")

local C = {
    bg      = Color3.fromRGB(12, 12, 14),
    panel   = Color3.fromRGB(16, 16, 16),
    card    = Color3.fromRGB(22, 22, 22),
    input   = Color3.fromRGB(14, 14, 14),
    border  = Color3.fromRGB(34, 34, 34),
    text    = Color3.fromRGB(255, 255, 255),
    sub     = Color3.fromRGB(150, 150, 150),
    accent  = Color3.fromRGB(255, 255, 255),
    danger  = Color3.fromRGB(255, 255, 255),
    success = Color3.fromRGB(240, 240, 240),
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
    return tweenService:Create(obj, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
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
    if type(writefile) ~= "function" or (type(getcustomasset) ~= "function" and type(getsynasset) ~= "function") then
        return "rbxassetid://18055627255"
    end
    if makefolder and not isfolder("slate/cache") then
        if not isfolder("slate") then pcall(makefolder, "slate") end
        pcall(makefolder, "slate/cache")
    end
    local cleanName = "slate/cache/slate_cache_" .. tostring(url):gsub("[^%a%d]", "_") .. ".png"
    local get_asset = getcustomasset or getsynasset
    local is_file = isfile or function(path) return pcall(readfile, path) end
    if is_file(cleanName) then
        local ok, asset = pcall(get_asset, cleanName)
        if ok then return asset end
    end
    local success, content = pcall(function() return game:HttpGet(url) end)
    if success and content and content ~= "" then
        pcall(writefile, cleanName, content)
        local ok, asset = pcall(get_asset, cleanName)
        if ok then return asset end
    end
    return "rbxassetid://18055627255"
end

local function resolveImageId(idStr)
    if not idStr or idStr == 0 or idStr == "0" or idStr == "" then return "rbxassetid://18055627255" end
    local str = tostring(idStr)
    if str:find("http://") or str:find("https://") then
        return downloadExternalImage(str)
    end
    if str:find("rbxassetid://") or str:find("rbxthumb://") or str:find("rbxasset://") then
        local numericId = str:match("%d+$")
        if numericId then
            local num = tonumber(numericId)
            local ok, info = pcall(function() return marketplaceService:GetProductInfo(num) end)
            if ok and info and info.AssetTypeId == 13 then
                return "rbxthumb://type=Asset&id=" .. numericId .. "&w=150&h=150"
            end
        end
        return str
    end
    local numericId = str:match("%d+")
    if numericId then
        local num = tonumber(numericId)
        local ok, info = pcall(function() return marketplaceService:GetProductInfo(num) end)
        if ok and info and info.AssetTypeId == 13 then
            return "rbxthumb://type=Asset&id=" .. numericId .. "&w=150&h=150"
        end
        return "rbxassetid://" .. numericId
    end
    return str
end

local function resolveAnimationId(rawId)
    local idStr = tostring(rawId):gsub("%.0$", ""):match("%d+") or tostring(rawId)
    local ok, obj = pcall(function() return game:GetObjects("rbxassetid://" .. idStr) end)
    if ok and obj and #obj > 0 and obj[1] then
        local animObj = obj[1]
        if not animObj:IsA("Animation") then
            animObj = animObj:FindFirstChildOfClass("Animation") or animObj:FindFirstChildWhichIsA("Animation", true)
        end
        if animObj and animObj:IsA("Animation") and animObj.AnimationId ~= "" and animObj.AnimationId ~= "rbxassetid://0" then
            local realId = animObj.AnimationId:match("%d+")
            if realId then return realId, animObj end
        end
    end
    return idStr, nil
end

local PackCustomImages = {
    ["Vampire"]   = "https://i.postimg.cc/85gFFGxp/vampirepack.webp",
    ["Ghost"]     = "https://i.postimg.cc/rm2ddT7X/ghostpack.webp",
    ["Robot"]     = "https://i.postimg.cc/nzfssxNZ/robotpack.webp",
    ["Zombie"]    = "https://i.postimg.cc/KzhKKbCc/zombiepaack.webp",
    ["Ninja"]     = "https://i.postimg.cc/9MH442sh/ninjapack.webp",
    ["Pirate"]    = "https://i.postimg.cc/SsbXX4H4/piratepack.webp",
    ["Mage"]      = "https://i.postimg.cc/d1c77FgK/magepack.webp",
    ["Knight"]    = "https://i.postimg.cc/TwvyyxBv/knightpack.webp",
    ["Superhero"] = "https://i.postimg.cc/d1c77FgJ/superheropack.webp",
    ["Cartoony"]  = "https://i.postimg.cc/TwvyyxFS/cartoonyreal.webp",
    ["Toy"]       = "https://i.postimg.cc/j5YWWTmG/cartoonpack.webp",
    ["Astronaut"] = "https://i.postimg.cc/RFx33myY/Astronautpack.webp",
    ["Sneaky"]    = "https://i.postimg.cc/76rCC4jw/sneakyanimpack.webp",
    ["Default"]   = "https://i.postimg.cc/mDWcc4JK/defaultanimpack.webp",
}

local OriginalAnimations = {
    ["Idle"] = {
        ["2016 Animation (mm2)"] = {"387947158", "387947464"},
        ["(UGC) Oh Really?"] = {"98004748982532", "98004748982532"},
        ["Astronaut"] = {"891621366", "891633237"},
        ["Adidas Community"] = {"122257458498464", "102357151005774"},
        ["Bold"] = {"16738333868", "16738334710"},
        ["(UGC) Slasher"] = {"140051337061095", "140051337061095"},
        ["(UGC) Retro"] = {"80479383912838", "80479383912838"},
        ["(UGC) Magician"] = {"139433213852503", "139433213852503"},
        ["(UGC) John Doe"] = {"72526127498800", "72526127498800"},
        ["(UGC) Noli"] = {"139360856809483", "139360856809483"},
        ["(UGC) Coolkid"] = {"95203125292023", "95203125292023"},
        ["(UGC) Survivor Injured"] = {"73905365652295", "73905365652295"},
        ["(UGC) Retro Zombie"] = {"90806086002292", "90806086002292"},
        ["(UGC) 1x1x1x1"] = {"76780522821306", "76780522821306"},
        ["Borock"] = {"3293641938", "3293642554"},
        ["Bubbly"] = {"910004836", "910009958"},
        ["Cartoony"] = {"742637544", "742638445"},
        ["Confident"] = {"1069977950", "1069987858"},
        ["Catwalk Glam"] = {"133806214992291", "94970088341563"},
        ["Cowboy"] = {"1014390418", "1014398616"},
        ["Drooling Zombie"] = {"3489171152", "3489171152"},
        ["Elder"] = {"10921101664", "10921102574"},
        ["Ghost"] = {"616006778", "616008087"},
        ["Knight"] = {"657595757", "657568135"},
        ["Levitation"] = {"616006778", "616008087"},
        ["Mage"] = {"707742142", "707855907"},
        ["MrToilet"] = {"4417977954", "4417978624"},
        ["Ninja"] = {"656117400", "656118341"},
        ["NFL"] = {"92080889861410", "74451233229259"},
        ["OldSchool"] = {"10921230744", "10921232093"},
        ["Patrol"] = {"1149612882", "1150842221"},
        ["Pirate"] = {"750781874", "750782770"},
        ["Default Retarget"] = {"95884606664820", "95884606664820"},
        ["Very Long"] = {"18307781743", "18307781743"},
        ["Sway"] = {"560832030", "560833564"},
        ["Popstar"] = {"1212900985", "1150842221"},
        ["Princess"] = {"941003647", "941013098"},
        ["R6"] = {"12521158637", "12521162526"},
        ["R15 Reanimated"] = {"4211217646", "4211218409"},
        ["Realistic"] = {"17172918855", "17173014241"},
        ["Robot"] = {"616088211", "616089559"},
        ["Sneaky"] = {"1132473842", "1132477671"},
        ["Sports (Adidas)"] = {"18537376492", "18537371272"},
        ["Soldier"] = {"3972151362", "3972151362"},
        ["Stylish"] = {"616136790", "616138447"},
        ["Stylized Female"] = {"4708191566", "4708192150"},
        ["Superhero"] = {"10921288909", "10921290167"},
        ["Toy"] = {"782841498", "782845736"},
        ["Udzal"] = {"3303162274", "3303162549"},
        ["Vampire"] = {"1083445855", "1083450166"},
        ["Werewolf"] = {"1083195517", "1083214717"},
        ["Wicked (Popular)"] = {"118832222982049", "76049494037641"},
        ["No Boundaries (Walmart)"] = {"18747067405", "18747063918"},
        ["Zombie"] = {"616158929", "616160636"},
        ["(UGC) Zombie"] = {"77672872857991", "77672872857991"},
        ["(UGC) TailWag"] = {"129026910898635", "129026910898635"},
        ["[VOTE] warming up"] = {"83573330053643", "83573330053643"},
        ["cesus"] = {"115879733952840", "115879733952840"},
        ["[VOTE] Float"] = {"110375749767299", "110375749767299"},
        ["UGC Oneleft"] = {"121217497452435", "121217497452435"},
        ["AuraFarming"] = {"138665010911335", "138665010911335"},
        ["[VOTE] Mech Float"] = {"74447366032908", "74447366032908"},
        ["Badware"] = {"140131631438778", "140131631438778"},
        ["Wicked \"Dancing Through Life\""] = {"92849173543269", "132238900951109"},
        ["Unboxed By Amazon"] = {"98281136301627", "138183121662404"}
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
        ["Wicked \"Dancing Through Life\""] = "73718308412641",
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
        ["Cowboy"] = "1014421541"
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
        ["Wicked \"Dancing Through Life\""] = "135515454877967",
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
        ["Cowboy"] = "1014401683"
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
        ["Wicked \"Dancing Through Life\""] = "78508480717326",
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
        ["[UGC] happy"] = "72388373557525"
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
        ["Wicked \"Dancing Through Life\""] = "78147885297412",
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
        ["Cowboy"] = "1014384571"
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
        ["Wicked \"Dancing Through Life\""] = "129183123083281",
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
        ["Stylish"] = "10921281964"
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
        ["Wicked \"Dancing Through Life\""] = "110657013921774",
        ["Elder"] = "10921108971",
        ["Bubbly"] = "910028158",
        ["Robot"] = "10921253142",
        ["[VOTE] Aura"] = "80645586378736",
        ["Vampire"] = "10921324408",
        ["Stylish"] = "10921281000",
        ["Toy"] = "10921309319",
        ["SuperHero"] = "10921295495",
        ["Princess"] = "941018893",
        ["Confident"] = "1070009914"
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
        ["Wicked \"Dancing Through Life\""] = "129447497744818",
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
        ["[VOTE] Rope"] = "134977367563514"
    }
}

local PACK_NAMES = {"Vampire", "Ghost", "Robot", "Zombie", "Ninja", "Pirate", "Mage", "Knight", "Superhero", "Cartoony", "Toy", "Astronaut", "Sneaky", "Default"}

local EMOTES = {
    {id="3360689775",name="Salute"},{id="5915779043",name="Applaud"},
    {id="3360692915",name="Tilt"},{id="3823158750",name="Godlike"},
    {id="5230661597",name="Bored"},{id="4689362868",name="Sleep"},
    {id="3576717965",name="Shy"},{id="5104377791",name="Hero Landing"},
    {id="5917570207",name="Floss Dance"},{id="3716636630",name="Monkey"},
    {id="4646306583",name="Curtsy"},{id="4849502101",name="Sad"},
    {id="3576968026",name="Shrug"},{id="3576686446",name="Hello"},
    {id="3360686498",name="Stadium"},{id="4940597758",name="Cower"},
    {id="4102315500",name="Haha"},{id="3934986896",name="Dizzy"},
    {id="4849499887",name="Happy"},{id="79752538807060",name="Griddy"},
    {id="4849497510",name="Power Blast"},{id="3576823880",name="Pointing"},
    {id="93511411593120",name="/e fly"},{id="114899970878842",name="R15 Death"},
    {id="132074413582912",name="California Girl"},{id="93105950995997",name="Caramelldansen"},
    {id="70615023659736",name="Floating"},{id="78620443286892",name="Cute Laying"},
    {id="130998336536045",name="Gangnam Style"},{id="75528418031928",name="Rambunctious"},
}

local emoteFavorites = {}
local emoteKeybinds  = {}
local listeningEmoteId = nil
local listeningKeyBtn = nil

local function loadEmoteState()
    pcall(function()
        if isfile and readfile and isfile("slate/emotes_favs.json") then
            local ok, decoded = pcall(function() return httpService:JSONDecode(readfile("slate/emotes_favs.json")) end)
            if ok and type(decoded) == "table" then emoteFavorites = decoded end
        end
        if isfile and readfile and isfile("slate/emotes_binds.json") then
            local ok, decoded = pcall(function() return httpService:JSONDecode(readfile("slate/emotes_binds.json")) end)
            if ok and type(decoded) == "table" then emoteKeybinds = decoded end
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

local function _addEmoteBatch(batch)
    if #batch == 0 then return end
    for _, em in ipairs(batch) do
        local key = tostring(em.id)
        if not _emoteIdSet[key] then
            _emoteIdSet[key] = true
            table.insert(EMOTES, em)
        end
    end
end

local _rawCatalog = nil

task.spawn(function()
    task.wait(0.1)

    local cachePath = "slate/emotecache.json"
    local cacheLoaded = false

    if isfile and readfile and isfile(cachePath) then
        local okRead, content = pcall(readfile, cachePath)
        if okRead and content and content ~= "" then
            local okDec, decoded = pcall(function() return httpService:JSONDecode(content) end)
            if okDec and type(decoded) == "table" then
                _rawCatalog = (type(decoded.data) == "table" and decoded.data) or decoded
                if type(decoded.totalItems) == "number" then
                    _G._rawCatalogTotalItems = decoded.totalItems
                else
                    _G._rawCatalogTotalItems = #_rawCatalog
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
            local okH, body = pcall(function() return game:HttpGet(jsonUrl) end)
            if okH and body then
                okJson = true
                resJson = { StatusCode = 200, Body = body }
            end
        end

        if okJson and resJson and resJson.StatusCode == 200 and resJson.Body then
            local okDec, decoded = pcall(function() return httpService:JSONDecode(resJson.Body) end)
            if okDec and type(decoded) == "table" then
                _rawCatalog = (type(decoded.data) == "table" and decoded.data) or decoded
                if type(decoded.totalItems) == "number" then
                    _G._rawCatalogTotalItems = decoded.totalItems
                else
                    _G._rawCatalogTotalItems = #_rawCatalog
                end

                pcall(function()
                    if not isfolder("slate") then makefolder("slate") end
                    writefile(cachePath, resJson.Body)
                end)

                _refreshEmoteUI()
            end
        end
    end

    local userId = localPlr.UserId
    local aes = pcall(function() return game:GetService("AvatarEditorService") end) and game:GetService("AvatarEditorService")
    if aes then
        local ok, pages = pcall(function()
            return aes:GetInventoryPages(Enum.AvatarAssetType.Emote, 100, nil)
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
                    if pages.IsFinished then break end
                    pages:AdvanceToNextPageAsync()
                end
            end)
            if #batch > 0 then _addEmoteBatch(batch) end
        end
    end

    _inventoryLoaded = true
    _refreshEmoteUI()
end)

local function saveEmoteState()
    pcall(function()
        if not isfolder("slate") then makefolder("slate") end
        writefile("slate/emotes_favs.json", httpService:JSONEncode(emoteFavorites))
        writefile("slate/emotes_binds.json", httpService:JSONEncode(emoteKeybinds))
    end)
end

userInputSvc.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if listeningKeyBtn and listeningEmoteId then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local kc = input.KeyCode
            if kc ~= Enum.KeyCode.Unknown and kc ~= Enum.KeyCode.Escape then
                for otherId, otherKey in pairs(emoteKeybinds) do
                    if otherKey == kc.Name and otherId ~= listeningEmoteId then
                        emoteKeybinds[otherId] = nil
                    end
                end
                emoteKeybinds[listeningEmoteId] = kc.Name
                listeningKeyBtn.Text = kc.Name
                listeningKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                saveEmoteState()
            elseif kc == Enum.KeyCode.Escape then
                emoteKeybinds[listeningEmoteId] = nil
                listeningKeyBtn.Text = "+"
                listeningKeyBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                saveEmoteState()
            end
        end
        listeningKeyBtn = nil
        listeningEmoteId = nil
        return
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        for eId, keyName in pairs(emoteKeybinds) do
            if input.KeyCode.Name == keyName then
                for _, em in ipairs(EMOTES) do
                    if tostring(em.id) == tostring(eId) then
                        task.spawn(playEmote, em.id, em.name)
                        break
                    end
                end
            end
        end
    end
end)

local function freezeChar()
    pcall(function()
        local char = localPlr.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and not p.Anchored then p.Anchored = true end
        end
    end)
end

local function unfreezeChar()
    pcall(function()
        local char = localPlr.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Anchored then p.Anchored = false end
        end
    end)
end

local function stopAllTracks(hum)
    pcall(function()
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
        end
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
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
    local char = localPlr.Character; if not char then return end
    local Animate = char:FindFirstChild("Animate"); if not Animate then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end

    freezeChar()
    task.wait(0.1)

    pcall(function()
    local base = "http://www.roblox.com/asset/?id="
    stopAllTracks(hum)

    if OriginalAnimations.Walk[packageName] == nil and OriginalAnimations.Idle[packageName] then
        local packageId = OriginalAnimations.Idle[packageName][1]
        local ok, objList = pcall(function() return game:GetObjects("rbxassetid://" .. packageId) end)
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
                    if id1 then Animate.idle.Animation1.AnimationId = base .. id1 end
                end
                local anim2 = sourceIdle:FindFirstChild("Animation2")
                if anim2 and anim2:IsA("Animation") then
                    local id2 = anim2.AnimationId:match("%d+")
                    if id2 then Animate.idle.Animation2.AnimationId = base .. id2 end
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
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        animator:Destroy()
    end
    if hum then
        Instance.new("Animator", hum)
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
    end
end

local function refreshState(stateType)
    pcall(function()
        local char = localPlr.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
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

local function setAnimation(animationType, animationId)
    if type(animationId) ~= "table" and type(animationId) ~= "string" and type(animationId) ~= "number" then return end
    local char = localPlr.Character; if not char then return end
    local Animate = char:FindFirstChild("Animate"); if not Animate then return end

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
            if Animate:FindFirstChild("walk") then Animate.walk.WalkAnim.AnimationId = base .. tostring(animationId) end
            refreshState("freefall")
        elseif animationType == "Run" then
            if Animate:FindFirstChild("run") then Animate.run.RunAnim.AnimationId = base .. tostring(animationId) end
            refreshState("freefall")
        elseif animationType == "Jump" then
            if Animate:FindFirstChild("jump") then Animate.jump.JumpAnim.AnimationId = base .. tostring(animationId) end
            refreshState("freefall")
        elseif animationType == "Fall" then
            if Animate:FindFirstChild("fall") then Animate.fall.FallAnim.AnimationId = base .. tostring(animationId) end
            refreshState("freefall")
        elseif animationType == "Swim" then
            if Animate:FindFirstChild("swim") then Animate.swim.Swim.AnimationId = base .. tostring(animationId) end
            refreshState("swim")
        elseif animationType == "SwimIdle" then
            if Animate:FindFirstChild("swimidle") then Animate.swimidle.SwimIdle.AnimationId = base .. tostring(animationId) end
            refreshState("swim")
        elseif animationType == "Climb" then
            if Animate:FindFirstChild("climb") then Animate.climb.ClimbAnim.AnimationId = base .. tostring(animationId) end
            refreshState("climb")
        end
    end)

    if not success then
        warn("Failed to set animation:", err)
    end

    task.wait(0.1)
    unfreezeChar()
end

local currentEmoteTrack, selectedEmoteId = nil, nil
local emoteSpeed = 1.0
local nowPlayingLbl = nil

local function stopEmote()
    if currentEmoteTrack then pcall(function() currentEmoteTrack:Stop(0) end); currentEmoteTrack=nil end
    selectedEmoteId=nil
    if nowPlayingLbl then nowPlayingLbl.Text="No emote playing" end
    local char=localPlr.Character; if not char then return end
    local animate=char:FindFirstChild("Animate")
    if animate then pcall(function() animate.Disabled=false end) end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
end

local function playEmote(emoteId, emoteName)
    local idStr=tostring(emoteId):gsub("%.0$","")
    if selectedEmoteId and tostring(selectedEmoteId):gsub("%.0$","")==idStr then stopEmote(); return end
    if currentEmoteTrack then pcall(function() currentEmoteTrack:Stop(0) end); currentEmoteTrack=nil end
    selectedEmoteId=emoteId
    if nowPlayingLbl then nowPlayingLbl.Text="♪  "..emoteName end
    task.spawn(function()
        local char=localPlr.Character; if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if hum.RigType~=Enum.HumanoidRigType.R15 then
            selectedEmoteId=nil; if nowPlayingLbl then nowPlayingLbl.Text="R15 required!" end; return
        end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero end) end
        local animate=char:FindFirstChild("Animate")
        if animate then pcall(function() animate.Disabled=true end) end
        task.wait(0.05)
        local animator=hum:FindFirstChildOfClass("Animator")
        if not animator then
            if animate then pcall(function() animate.Disabled=false end) end
            selectedEmoteId=nil; if nowPlayingLbl then nowPlayingLbl.Text="No emote playing" end; return
        end
        for _,t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
        if tostring(selectedEmoteId):gsub("%.0$","")~=idStr then return end

        local anim
        local realId, animObj = resolveAnimationId(idStr)
        if animObj then
            anim = animObj
            pcall(function() anim.Parent = workspace end)
        else
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. realId
        end

        local loadOk, track = pcall(function() return animator:LoadAnimation(anim) end)
        pcall(function() if anim and anim.Parent==workspace then anim:Destroy() end end)
        if not loadOk or not track then
            if animate then pcall(function() animate.Disabled=false end) end
            selectedEmoteId=nil; if nowPlayingLbl then nowPlayingLbl.Text="Failed to load emote" end; return
        end
        if tostring(selectedEmoteId):gsub("%.0$","")~=idStr then pcall(function() track:Stop(0) end); return end
        track.Priority=Enum.AnimationPriority.Action4; track.Looped=true
        track:Play(0,1,emoteSpeed); currentEmoteTrack=track
        local mc,sc
        mc=hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
            if currentEmoteTrack==track and hum.MoveDirection.Magnitude>0.1 then
                stopEmote(); if mc then mc:Disconnect() end; if sc then sc:Disconnect() end
            end
        end)
        sc=hum.StateChanged:Connect(function(_,state)
            if currentEmoteTrack==track and (state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall) then
                stopEmote(); if mc then mc:Disconnect() end; if sc then sc:Disconnect() end
            end
        end)
        track.Stopped:Connect(function()
            if mc then mc:Disconnect() end; if sc then sc:Disconnect() end
            if currentEmoteTrack==track then
                currentEmoteTrack=nil; selectedEmoteId=nil
                if nowPlayingLbl then nowPlayingLbl.Text="No emote playing" end
                if animate then pcall(function() animate.Disabled=false end) end
            end
        end)
    end)
end

local function makeDraggable(topbar, main)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    userInputSvc.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local sg = Instance.new("ScreenGui")
sg.Name = "SlateEmoteAnimGUI"; sg.ResetOnSpawn = false
sg.Enabled = (SHOW_UI_ON_EXECUTE == true); sg.Parent = panelHost
pcall(function() if _G.updateAllCustomBackgrounds then _G.updateAllCustomBackgrounds() end end)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 440)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -220)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 1
mainFrame.Parent = sg
cr(12, mainFrame)
stk(0.99, C.border, mainFrame)

local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, 0, 0, 44)
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = mainFrame

local headerLogo = Instance.new("ImageLabel", headerFrame)
headerLogo.Name = "SlateLogo"
headerLogo.Image = "rbxassetid://106790631609801"
headerLogo.ScaleType = Enum.ScaleType.Fit
headerLogo.Size = UDim2.new(0, 22, 0, 22)
headerLogo.Position = UDim2.new(0, 12, 0.5, -11)
headerLogo.BackgroundTransparency = 1
headerLogo.ZIndex = 5

local titleLabel = lbl(headerFrame, "Emotes & Animations", 13, Enum.Font.BuilderSansBold, C.text)
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 40, 0, 0)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -30, 0.5, -12)
closeButton.BackgroundTransparency = 1
closeButton.Text = "×"
closeButton.TextColor3 = C.text
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = headerFrame
closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = Color3.fromRGB(200, 200, 200) end)
closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = C.text end)
closeButton.MouseButton1Click:Connect(function() sg.Enabled = false end)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 24, 0, 24)
minimizeButton.Position = UDim2.new(1, -58, 0.5, -12)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Text = "−"
minimizeButton.TextColor3 = C.text
minimizeButton.TextSize = 16
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = headerFrame
minimizeButton.MouseEnter:Connect(function() minimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200) end)
minimizeButton.MouseLeave:Connect(function() minimizeButton.TextColor3 = C.text end)

local isMinimized = false
makeDraggable(headerFrame, mainFrame)

local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size = UDim2.new(1, -24, 0, 26)
tabBar.Position = UDim2.new(0, 12, 0, 50)
tabBar.BackgroundTransparency = 1

local listLayoutSettings = Instance.new("UIListLayout", tabBar)
listLayoutSettings.FillDirection = Enum.FillDirection.Horizontal
listLayoutSettings.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayoutSettings.Padding = UDim.new(0, 14)
listLayoutSettings.SortOrder = Enum.SortOrder.LayoutOrder

local tabBtns = {}
local pages = {}

local emotesCategoryBtn, favsCategoryBtn

local function createCategoryBtn(tabName, text, widthPx, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, widthPx, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(140, 140, 140)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.BorderSizePixel = 0
    btn.LayoutOrder = layoutOrder
    btn.Parent = tabBar
    btn:SetAttribute("tn", tabName)

    local activeBar = Instance.new("Frame", btn)
    activeBar.Name = "ActiveBar"
    activeBar.Size = UDim2.new(1, 0, 0, 2)
    activeBar.Position = UDim2.new(0, 0, 1, -2)
    activeBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    activeBar.BorderSizePixel = 0
    activeBar.Visible = false

    table.insert(tabBtns, btn)
    return btn
end

emotesCategoryBtn = createCategoryBtn("Emotes", "Emotes (" .. #EMOTES .. ")", 95, 1)
favsCategoryBtn   = createCategoryBtn("Favorites", "Favorites (0)", 75, 2)
local packsTabBtn  = createCategoryBtn("Packs", "Packs", 35, 3)
local customTabBtn = createCategoryBtn("Custom", "Custom", 45, 4)

local function updateTabCounts()
    local favCount = 0
    for key, val in pairs(emoteFavorites) do
        if val then favCount = favCount + 1 end
    end
    local totalEmotes = _G._rawCatalogTotalItems or (_rawCatalog and #_rawCatalog) or #EMOTES
    emotesCategoryBtn.Text = "Emotes (" .. totalEmotes .. ")"
    favsCategoryBtn.Text = "Favorites (" .. favCount .. ")"
end

local playingStatusBar = Instance.new("Frame", mainFrame)
playingStatusBar.Size = UDim2.new(1, -24, 0, 26)
playingStatusBar.Position = UDim2.new(0, 12, 0, 82)
playingStatusBar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
cr(6, playingStatusBar); stk(0.99, Color3.fromRGB(30, 30, 30), playingStatusBar)

nowPlayingLbl = lbl(playingStatusBar, "No emote playing", 10, Enum.Font.GothamMedium, Color3.fromRGB(180, 180, 180))
nowPlayingLbl.Size = UDim2.new(1, -65, 1, 0)
nowPlayingLbl.Position = UDim2.new(0, 10, 0, 0)
nowPlayingLbl.TextTruncate = Enum.TextTruncate.AtEnd

local stopBtn = Instance.new("TextButton", playingStatusBar)
stopBtn.Size = UDim2.new(0, 48, 0, 18)
stopBtn.Position = UDim2.new(1, -54, 0.5, -9)
stopBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
stopBtn.Text = "Stop"
stopBtn.TextColor3 = Color3.fromRGB(110, 110, 115)
stopBtn.TextSize = 9
stopBtn.Font = Enum.Font.GothamBold
cr(4, stopBtn); stk(0.99, Color3.fromRGB(60, 30, 30), stopBtn)
stopBtn.MouseButton1Click:Connect(stopEmote)

local searchBox = Instance.new("TextBox", mainFrame)
searchBox.PlaceholderText = "Search animations & emotes..."
searchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
searchBox.Size = UDim2.new(1, -24, 0, 26)
searchBox.Position = UDim2.new(0, 12, 0, 114)
searchBox.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
searchBox.TextColor3 = Color3.fromRGB(240, 240, 240)
searchBox.ClearTextOnFocus = false
searchBox.TextSize = 11
searchBox.Text = ""
searchBox.Font = Enum.Font.GothamMedium
searchBox.BorderSizePixel = 0
cr(6, searchBox); stk(0.99, Color3.fromRGB(30, 30, 30), searchBox)
local sPadding = Instance.new("UIPadding", searchBox); sPadding.PaddingLeft = UDim.new(0, 8)

local scrollContainer = Instance.new("ScrollingFrame", mainFrame)
scrollContainer.Size = UDim2.new(1, -24, 1, -188)
scrollContainer.Position = UDim2.new(0, 12, 0, 146)
scrollContainer.BackgroundTransparency = 1
scrollContainer.BorderSizePixel = 0
scrollContainer.ScrollBarThickness = 3
scrollContainer.ScrollBarImageTransparency = 0.5
scrollContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
local scrollPadding = Instance.new("UIPadding", scrollContainer)
scrollPadding.PaddingLeft = UDim.new(0, 2); scrollPadding.PaddingRight = UDim.new(0, 8)
scrollPadding.PaddingTop = UDim.new(0, 2); scrollPadding.PaddingBottom = UDim.new(0, 4)

local spdBar = Instance.new("Frame", mainFrame)
spdBar.Size = UDim2.new(1, -24, 0, 30)
spdBar.Position = UDim2.new(0, 12, 1, -36)
spdBar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
spdBar.BorderSizePixel = 0
cr(6, spdBar); stk(0.99, Color3.fromRGB(30, 30, 30), spdBar)

local spdLbl = lbl(spdBar, "Speed: 1.0x", 10, Enum.Font.GothamMedium, C.sub)
spdLbl.Size = UDim2.new(0, 75, 1, 0)
spdLbl.Position = UDim2.new(0, 8, 0, 0)
spdLbl.TextTruncate = Enum.TextTruncate.None

local sTrackBtn = Instance.new("TextButton", spdBar)
sTrackBtn.Name = "SliderTrackBtn"
sTrackBtn.Size = UDim2.new(1, -95, 0, 16)
sTrackBtn.Position = UDim2.new(0, 85, 0.5, -8)
sTrackBtn.BackgroundTransparency = 1
sTrackBtn.Text = ""
sTrackBtn.AutoButtonColor = false

local sTrack = Instance.new("Frame", sTrackBtn)
sTrack.Size = UDim2.new(1, 0, 0, 6)
sTrack.Position = UDim2.new(0, 0, 0.5, -3)
sTrack.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
sTrack.BorderSizePixel = 0; cr(3, sTrack)
local sTrackStk = stk(0.99, Color3.fromRGB(40, 40, 45), sTrack)

local sFill = Instance.new("Frame", sTrack)
local defaultRel = math.clamp((1.0 - 0.1) / (3.0 - 0.1), 0, 1)
sFill.Size = UDim2.new(defaultRel, 0, 1, 0)
sFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sFill.BorderSizePixel = 0; cr(3, sFill)

local sFillGrad = Instance.new("UIGradient", sFill)
sFillGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(80, 80, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 140, 150)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(220, 220, 230))
})

local sThumb = Instance.new("Frame", sTrack)
sThumb.Size = UDim2.new(0, 14, 0, 14)
sThumb.AnchorPoint = Vector2.new(0.5, 0.5)
sThumb.Position = UDim2.new(defaultRel, 0, 0.5, 0)
sThumb.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
sThumb.BorderSizePixel = 0; cr(7, sThumb)
local sThumbStroke = Instance.new("UIStroke", sThumb)
sThumbStroke.Color = Color3.fromRGB(160, 160, 165)
sThumbStroke.Transparency = 0.2
sThumbStroke.Thickness = 1.2

do
    local sDrag = false
    local function updateSliderFromInput(i)
        local posX = i.Position.X
        local trackAbsPos = sTrack.AbsolutePosition.X
        local trackAbsSize = sTrack.AbsoluteSize.X
        if trackAbsSize <= 0 then return end
        local rel = math.clamp((posX - trackAbsPos) / trackAbsSize, 0, 1)
        emoteSpeed = math.max(0.1, math.floor((0.1 + rel * 2.9) * 10 + 0.5) / 10)
        sFill.Size = UDim2.new(rel, 0, 1, 0)
        sThumb.Position = UDim2.new(rel, 0, 0.5, 0)
        spdLbl.Text = string.format("Speed: %.1fx", emoteSpeed)
        if currentEmoteTrack then pcall(function() currentEmoteTrack:AdjustSpeed(emoteSpeed) end) end
    end

    local function startDrag(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sDrag = true
            updateSliderFromInput(i)
            tweenService:Create(sThumb, TweenInfo.new(0.12), {Size = UDim2.new(0, 16, 0, 16)}):Play()
        end
    end

    sTrackBtn.InputBegan:Connect(startDrag)
    sThumb.InputBegan:Connect(startDrag)

    userInputSvc.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if sDrag then
                sDrag = false
                tweenService:Create(sThumb, TweenInfo.new(0.12), {Size = UDim2.new(0, 14, 0, 14)}):Play()
            end
        end
    end)

    userInputSvc.InputChanged:Connect(function(i)
        if sDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updateSliderFromInput(i)
        end
    end)
end

minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local twInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if isMinimized then
        tweenService:Create(mainFrame, twInfo, { Size = UDim2.new(0, 320, 0, 44) }):Play()
        minimizeButton.Text = "+"
        tabBar.Visible = false
        playingStatusBar.Visible = false
        searchBox.Visible = false
        scrollContainer.Visible = false
        spdBar.Visible = false
    else
        tweenService:Create(mainFrame, twInfo, { Size = UDim2.new(0, 320, 0, 440) }):Play()
        minimizeButton.Text = "−"
        tabBar.Visible = true
        playingStatusBar.Visible = true
        searchBox.Visible = true
        scrollContainer.Visible = true
        spdBar.Visible = true
    end
end)

local function renderEmoteRow(container, em, idx, onStateChanged)
    local row = Instance.new("Frame", container)
    row.Size = UDim2.new(1, -8, 0, 32); row.LayoutOrder = idx
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 18); row.BorderSizePixel = 0; cr(6, row)
    local rStk = stk(0.99, Color3.fromRGB(28, 28, 28), row)

    local plateBtn = Instance.new("TextButton", row)
    plateBtn.Size = UDim2.new(1, 0, 1, 0)
    plateBtn.BackgroundTransparency = 1
    plateBtn.Text = ""
    plateBtn.ZIndex = 1

    plateBtn.MouseEnter:Connect(function()
        tweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 28)}):Play()
    end)
    plateBtn.MouseLeave:Connect(function()
        tweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(18, 18, 18)}):Play()
    end)
    plateBtn.MouseButton1Click:Connect(function()
        playEmote(em.id, em.name)
    end)

    local fIcon = "rbxthumb://type=Asset&id=105536176972318&w=150&h=150"
    local uIcon = "rbxthumb://type=Asset&id=108960170332502&w=150&h=150"
    local kIcon = "rbxthumb://type=Asset&id=124657808272985&w=150&h=150"

    local nl = lbl(row, em.name, 11, Enum.Font.GothamMedium, C.text)
    nl.Size = UDim2.new(1, -95, 1, 0); nl.Position = UDim2.new(0, 12, 0, 0)
    nl.TextTruncate = Enum.TextTruncate.AtEnd
    nl.ClipsDescendants = true
    nl.ZIndex = 2

    local bindBtn = Instance.new("ImageButton", row)
    bindBtn.Size = UDim2.new(0, 30, 0, 20); bindBtn.Position = UDim2.new(1, -66, 0.5, -10)
    bindBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
    bindBtn.ScaleType = Enum.ScaleType.Fit
    bindBtn.ZIndex = 3
    cr(4, bindBtn); stk(0.99, Color3.fromRGB(45, 45, 45), bindBtn)

    local bindTxt = Instance.new("TextLabel", bindBtn)
    bindTxt.Size = UDim2.new(1, 0, 1, 0); bindTxt.BackgroundTransparency = 1
    bindTxt.TextColor3 = Color3.fromRGB(255, 255, 255); bindTxt.TextSize = 8
    bindTxt.Font = Enum.Font.GothamBold; bindTxt.Visible = false
    bindTxt.ZIndex = 4

    local function updateEmoteBindDisplay()
        local currentBind = emoteKeybinds[tostring(em.id)]
        if currentBind then
            bindBtn.Image = ""
            bindTxt.Text = currentBind:sub(1, 3)
            bindTxt.Visible = true
        else
            bindBtn.Image = kIcon
            bindTxt.Visible = false
        end
    end
    updateEmoteBindDisplay()

    bindBtn.MouseButton1Click:Connect(function()
        listeningEmoteId = tostring(em.id)
        listeningKeyBtn = bindTxt
        bindBtn.Image = ""
        bindTxt.Text = "..."
        bindTxt.TextColor3 = Color3.fromRGB(255, 200, 50)
        bindTxt.Visible = true
    end)

    local favBtn = Instance.new("ImageButton", row)
    favBtn.Size = UDim2.new(0, 20, 0, 20); favBtn.Position = UDim2.new(1, -28, 0.5, -10)
    favBtn.BackgroundTransparency = 1; favBtn.ScaleType = Enum.ScaleType.Fit
    favBtn.ZIndex = 3
    local isFav = emoteFavorites[tostring(em.id)] == true
    favBtn.Image = isFav and fIcon or uIcon

    favBtn.MouseButton1Click:Connect(function()
        local key = tostring(em.id)
        if emoteFavorites[key] then
            emoteFavorites[key] = nil
            favBtn.Image = uIcon
        else
            emoteFavorites[key] = true
            favBtn.Image = fIcon
        end
        saveEmoteState()
        updateTabCounts()
        if onStateChanged then onStateChanged() end
    end)
end

local buildFavsList
do
    local p = Instance.new("Frame", scrollContainer)
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.Visible = true; pages["Emotes"] = p
    local listL = Instance.new("UIListLayout", p)
    listL.Padding = UDim.new(0, 5); listL.SortOrder = Enum.SortOrder.LayoutOrder

    local currentRenderToken = 0
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
                        if filter == "" or name:lower():find(filter, 1, true) then
                            table.insert(filteredSource, { id = id, name = name })
                        end
                    end
                end
            end
        else
            for _, em in ipairs(EMOTES) do
                if filter == "" or em.name:lower():find(filter, 1, true) then
                    table.insert(filteredSource, em)
                end
            end
        end
    end

    local function renderMoreRows(batchSize)
        batchSize = batchSize or 30
        local target = math.min(#filteredSource, loadedIndex + batchSize)
        for i = loadedIndex + 1, target do
            loadedIndex = i
            renderEmoteRow(p, filteredSource[i], loadedIndex, function()
                if buildFavsList then buildFavsList(searchBox.Text) end
            end)
        end
    end

    local function buildEmotesList(filter)
        currentRenderToken = currentRenderToken + 1
        for _, c in ipairs(p:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        loadedIndex = 0
        prepareSource(filter)
        renderMoreRows(40)
        updateTabCounts()
    end

    scrollContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if pages["Emotes"].Visible and filteredSource then
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
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() buildEmotesList(searchBox.Text) end)
end

do
    local p = Instance.new("Frame", scrollContainer)
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.Visible = false; pages["Favorites"] = p
    local listL = Instance.new("UIListLayout", p)
    listL.Padding = UDim.new(0, 5); listL.SortOrder = Enum.SortOrder.LayoutOrder

    buildFavsList = function(filter)
        for _, c in ipairs(p:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local idx = 0
        for _, em in ipairs(EMOTES) do
            if emoteFavorites[tostring(em.id)] then
                if not filter or filter == "" or em.name:lower():find(filter:lower(), 1, true) then
                    idx = idx + 1
                    renderEmoteRow(p, em, idx, function()
                        buildFavsList(filter)
                    end)
                end
            end
        end
        if idx == 0 then
            local noFavsLbl = Instance.new("TextLabel", p)
            noFavsLbl.Size = UDim2.new(1, 0, 0, 32)
            noFavsLbl.BackgroundTransparency = 1
            noFavsLbl.Text = "No favorites yet — star an emote!"
            noFavsLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
            noFavsLbl.TextSize = 11
            noFavsLbl.Font = Enum.Font.GothamMedium
        end
        updateTabCounts()
    end
    buildFavsList("")
end

do
    local p = Instance.new("Frame", scrollContainer)
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.Visible = false; pages["Packs"] = p
    local listL = Instance.new("UIListLayout", p)
    listL.Padding = UDim.new(0, 6); listL.SortOrder = Enum.SortOrder.LayoutOrder

    local function rebuildPacksList(filter)
        for _, child in ipairs(p:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        filter = (filter or ""):lower()
        local idx = 0

        for _, packName in ipairs(PACK_NAMES) do
            local packTitle = packName .. " Pack"
            if filter == "" or packTitle:lower():find(filter, 1, true) then
                idx = idx + 1
                local row = Instance.new("Frame", p)
                row.Size = UDim2.new(1, -8, 0, 46); row.LayoutOrder = idx
                row.BackgroundColor3 = Color3.fromRGB(18, 18, 18); row.BorderSizePixel = 0; cr(6, row)
                local rStk = stk(0.99, Color3.fromRGB(28, 28, 28), row)

                local imgFrame = Instance.new("Frame", row)
                imgFrame.Size = UDim2.new(0, 36, 0, 36); imgFrame.Position = UDim2.new(0, 5, 0.5, -18)
                imgFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10); cr(4, imgFrame); stk(0.99, Color3.fromRGB(28, 28, 28), imgFrame)

                local packImg = Instance.new("ImageLabel", imgFrame)
                packImg.Size = UDim2.new(1, 0, 1, 0); packImg.BackgroundTransparency = 1
                packImg.ScaleType = Enum.ScaleType.Crop; cr(4, packImg)
                task.spawn(function()
                    packImg.Image = resolveImageId(PackCustomImages[packName] or "https://i.postimg.cc/mDWcc4JK/defaultanimpack.webp")
                end)

                local nl = lbl(row, packTitle, 11, Enum.Font.GothamBold, C.text)
                nl.Size = UDim2.new(1, -115, 1, 0); nl.Position = UDim2.new(0, 48, 0, 0)

                local applyBtn = Instance.new("TextButton", row)
                applyBtn.Size = UDim2.new(0, 55, 0, 22); applyBtn.Position = UDim2.new(1, -62, 0.5, -11)
                applyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); applyBtn.Text = "Apply"
                applyBtn.TextColor3 = C.text; applyBtn.Font = Enum.Font.GothamBold; applyBtn.TextSize = 10
                cr(4, applyBtn); stk(0.99, Color3.fromRGB(45, 45, 45), applyBtn)

                applyBtn.MouseEnter:Connect(function() applyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45) end)
                applyBtn.MouseLeave:Connect(function() applyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end)
                applyBtn.MouseButton1Click:Connect(function()
                    task.spawn(applyOnyxPackage, packName)
                    tw(applyBtn, {BackgroundColor3 = C.success, TextColor3 = Color3.fromRGB(0, 0, 0)}):Play()
                    task.delay(0.8, function()
                        tw(applyBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = C.text}):Play()
                    end)
                end)
            end
        end

        if filter == "" then
            idx = idx + 1
            local divFrame = Instance.new("Frame", p)
            divFrame.Size = UDim2.new(1, 0, 0, 24); divFrame.LayoutOrder = idx
            divFrame.BackgroundTransparency = 1
            local divLbl = lbl(divFrame, "— Individual Animations —", 10, Enum.Font.GothamBold, Color3.fromRGB(120, 120, 120), Enum.TextXAlignment.Center)
            divLbl.Size = UDim2.new(1, 0, 1, 0)
        end

        local typeOrder = {"Idle", "Walk", "Run", "Jump", "Fall", "Swim", "SwimIdle", "Climb"}
        for _, animType in ipairs(typeOrder) do
            local anims = OriginalAnimations[animType]
            if anims then
                for name, animData in pairs(anims) do
                    local combinedName = name .. " (" .. animType .. ")"
                    if filter == "" or combinedName:lower():find(filter, 1, true) then
                        idx = idx + 1
                        local row = Instance.new("Frame", p)
                        row.Size = UDim2.new(1, -8, 0, 32); row.LayoutOrder = idx
                        row.BackgroundColor3 = Color3.fromRGB(18, 18, 18); row.BorderSizePixel = 0; cr(6, row)
                        local rStk = stk(0.99, Color3.fromRGB(28, 28, 28), row)

                        local nl = lbl(row, combinedName, 11, Enum.Font.GothamMedium, C.text)
                        nl.Size = UDim2.new(1, -65, 1, 0); nl.Position = UDim2.new(0, 10, 0, 0)
                        nl.TextTruncate = Enum.TextTruncate.AtEnd

                        local applyBtn = Instance.new("TextButton", row)
                        applyBtn.Size = UDim2.new(0, 48, 0, 20); applyBtn.Position = UDim2.new(1, -54, 0.5, -10)
                        applyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); applyBtn.Text = "Apply"
                        applyBtn.TextColor3 = C.text; applyBtn.Font = Enum.Font.GothamBold; applyBtn.TextSize = 9
                        cr(4, applyBtn); stk(0.99, Color3.fromRGB(45, 45, 45), applyBtn)

                        applyBtn.MouseEnter:Connect(function() applyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45) end)
                        applyBtn.MouseLeave:Connect(function() applyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end)
                        applyBtn.MouseButton1Click:Connect(function()
                            task.spawn(setAnimation, animType, animData)
                            tw(applyBtn, {BackgroundColor3 = C.success, TextColor3 = Color3.fromRGB(0, 0, 0)}):Play()
                            task.delay(0.8, function()
                                tw(applyBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = C.text}):Play()
                            end)
                        end)
                    end
                end
            end
        end
    end

    rebuildPacksList("")
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if pages["Packs"].Visible then rebuildPacksList(searchBox.Text) end
    end)
end

do
    local p = Instance.new("Frame", scrollContainer)
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.Visible = false; pages["Custom"] = p
    local listL = Instance.new("UIListLayout", p)
    listL.Padding = UDim.new(0, 5); listL.SortOrder = Enum.SortOrder.LayoutOrder

    for idx, slotName in ipairs({"Idle", "Walk", "Run", "Jump", "Fall", "Swim", "SwimIdle", "Climb"}) do
        local row = Instance.new("Frame", p); row.Size = UDim2.new(1, -4, 0, 32); row.LayoutOrder = idx
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 18); row.BorderSizePixel = 0; cr(6, row); stk(0.99, Color3.fromRGB(28, 28, 28), row)

        local sLbl = lbl(row, slotName, 11, Enum.Font.GothamBold, C.text); sLbl.Size = UDim2.new(0, 55, 1, 0); sLbl.Position = UDim2.new(0, 8, 0, 0)

        local idBox = Instance.new("TextBox", row); idBox.Size = UDim2.new(1, -118, 0, 22); idBox.Position = UDim2.new(0, 65, 0.5, -11)
        idBox.BackgroundColor3 = C.input; idBox.Text = ""; idBox.PlaceholderText = slotName == "Idle" and "ID 1, ID 2..." or "Animation ID..."
        idBox.TextColor3 = C.text; idBox.PlaceholderColor3 = C.sub
        idBox.Font = Enum.Font.Gotham; idBox.TextSize = 10; cr(4, idBox); stk(0.99, C.border, idBox)
        local ibp = Instance.new("UIPadding", idBox); ibp.PaddingLeft = UDim.new(0, 6)

        local setBtn = Instance.new("TextButton", row); setBtn.Size = UDim2.new(0, 42, 0, 22); setBtn.Position = UDim2.new(1, -48, 0.5, -11)
        setBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); setBtn.Text = "Set"
        setBtn.TextColor3 = C.text; setBtn.Font = Enum.Font.GothamBold; setBtn.TextSize = 10
        cr(4, setBtn); stk(0.99, Color3.fromRGB(45, 45, 45), setBtn)

        setBtn.MouseButton1Click:Connect(function()
            local text = idBox.Text
            if slotName == "Idle" then
                local ids = {}
                for num in text:gmatch("%d+") do table.insert(ids, num) end
                if #ids > 0 then
                    task.spawn(setAnimation, "Idle", ids)
                end
            else
                local raw = text:match("%d+")
                if raw then
                    task.spawn(setAnimation, slotName, raw)
                end
            end
            tw(setBtn, {BackgroundColor3 = C.success, TextColor3 = Color3.fromRGB(0, 0, 0)}):Play()
            task.delay(0.6, function()
                tw(setBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = C.text}):Play()
            end)
        end)
    end

    local rRow = Instance.new("Frame", p); rRow.Size = UDim2.new(1, -4, 0, 32); rRow.BackgroundTransparency = 1; rRow.LayoutOrder = 99
    local rBtn = Instance.new("TextButton", rRow); rBtn.Size = UDim2.new(1, 0, 1, 0)
    rBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20); rBtn.BorderSizePixel = 0
    rBtn.Text = "Reset All Custom Animations"; rBtn.TextColor3 = Color3.fromRGB(110, 110, 115); rBtn.Font = Enum.Font.GothamBold; rBtn.TextSize = 10
    cr(5, rBtn); stk(0.99, Color3.fromRGB(60, 30, 30), rBtn)
    rBtn.MouseButton1Click:Connect(function()
        local char = localPlr.Character; if not char then return end
        local Animate = char:FindFirstChild("Animate"); if not Animate then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        pcall(function()
            freezeChar(); task.wait(0.05); stopAllTracks(hum)
            resetIdle(Animate)
            if Animate:FindFirstChild("walk")  then Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end
            if Animate:FindFirstChild("run")   then Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end
            if Animate:FindFirstChild("jump")  then Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end
            if Animate:FindFirstChild("fall")  then Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end
            if Animate:FindFirstChild("climb") then Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end
            unfreezeChar()
            Animate.Disabled = true; task.wait(0.05); Animate.Disabled = false
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end)
    end)
end

local function switchTab(tabName)
    for _, pg in pairs(pages) do pg.Visible = false end
    if pages[tabName] then pages[tabName].Visible = true end
    for _, btn in ipairs(tabBtns) do
        local active = btn:GetAttribute("tn") == tabName
        btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 140)
        local bar = btn:FindFirstChild("ActiveBar")
        if bar then bar.Visible = active end
    end
end

for _, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function()
        switchTab(btn:GetAttribute("tn"))
    end)
end

switchTab("Emotes")
updateTabCounts()

_G.ToggleSlateEmoteMenu = function()
    if sg then
        sg.Enabled = not sg.Enabled
    end
end
end)

SlateEspMenu = {}

function SlateEspMenu.espAction()
	local v = _G.siriusValues or siriusValues
	return v and v.actions and v.actions[7]
end

function SlateEspMenu.setEsp(on)
	local act = SlateEspMenu.espAction()
	if not act then return end
	act.enabled = on and true or false
	pcall(act.callback, act.enabled)
end

function SlateEspMenu.espEnabled()
	local act = SlateEspMenu.espAction()
	return (act and act.enabled) == true
end

function SlateEspMenu.refresh()
	pcall(function() if EspRefresh then EspRefresh() end end)
end

function SlateEspMenu.build()
	if SlateEspMenu.ui then return SlateEspMenu.ui end
	if not Tempus then return nil end
	if not (EspConfig and AimConfig) then return nil end

	local UI = Tempus.Window({
		title = "SLATE",
		keybind = nil,
		footerText = "Slate",
	})
	SlateEspMenu.ui = UI

	local Aimbot = UI.Tab("Aimbot", { icon = "126439761728978" })

	local Aim = Aimbot.Group("Aim", { side = "left", info = "Main aimlock toggles" })
	Aim.Toggle({
		text = "Aimlock", default = AimConfig.enabled,
		callback = function(v) AimConfig.enabled = v end,
	})
	Aim.Toggle({
		text = "Silent Aim", default = AimConfig.silentAim,
		callback = function(v) AimConfig.silentAim = v end,
	})
	Aim.Keybind({
		text = "Aim Key", default = AimConfig.key,
		changed = function(kc) AimConfig.key = kc end,
	})
	Aim.Toggle({
		text = "Field of View", default = AimConfig.showFov,
		callback = function(v) AimConfig.showFov = v end,
	})
	Aim.Slider({
		text = "FOV Size", min = 0, max = 500, default = AimConfig.fov, step = 1,
		callback = function(v) AimConfig.fov = v end,
	})
	Aim.Dropdown({
		text = "FOV Style", options = { "Circle", "Square", "Dot" },
		default = AimConfig.fovStyle,
		callback = function(v) AimConfig.fovStyle = v end,
	})
	Aim.Toggle({
		text = "FOV Follows Cursor", default = AimConfig.fovFollow,
		callback = function(v) AimConfig.fovFollow = v end,
	})

	local Configure = Aimbot.Group("Configure", { side = "left", info = "How the aim behaves" })
	Configure.Dropdown({
		text = "Aimbot Type", options = { "Hold", "Toggle", "Always" },
		default = AimConfig.mode,
		callback = function(v) AimConfig.mode = v end,
	})
	Configure.Dropdown({
		text = "Hitbox", options = { "Head", "Root", "Nearest" },
		default = AimConfig.targetPart,
		callback = function(v) AimConfig.targetPart = v end,
	})
	Configure.Dropdown({
		text = "Priority", options = { "Crosshair", "Distance", "Health" },
		default = AimConfig.priority,
		callback = function(v) AimConfig.priority = v end,
	})
	Configure.Slider({
		text = "Aim Delay (s)", min = 0, max = 1, default = AimConfig.aimDelay, step = 0.01,
		callback = function(v) AimConfig.aimDelay = v end,
	})

	local Trig = Aimbot.Group("Triggerbot", { side = "right", info = "Auto-fire when target is in FOV" })
	Trig.Toggle({
		text = "Triggerbot", default = AimConfig.triggerbot,
		callback = function(v) AimConfig.triggerbot = v end,
	})
	Trig.Slider({
		text = "Trigger Delay (s)", min = 0, max = 0.5, default = AimConfig.triggerbotDelay, step = 0.01,
		callback = function(v) AimConfig.triggerbotDelay = v end,
	})

	local Pred = Aimbot.Group("Prediction & Smoothing", { side = "right" })
	Pred.Toggle({
		text = "Smoothing", default = AimConfig.smoothing,
		callback = function(v) AimConfig.smoothing = v end,
	})
	Pred.Toggle({
		text = "Per-Axis Smoothing", default = AimConfig.perAxisSmooth,
		callback = function(v) AimConfig.perAxisSmooth = v end,
	})
	Pred.Slider({
		text = "Smoothing Amount", min = 0, max = 1, default = AimConfig.smoothAmount, step = 0.01,
		callback = function(v) AimConfig.smoothAmount = v end,
	})
	Pred.Slider({
		text = "Smoothing X", min = 0, max = 1, default = AimConfig.smoothAmountX, step = 0.01,
		callback = function(v) AimConfig.smoothAmountX = v end,
	})
	Pred.Slider({
		text = "Smoothing Y", min = 0, max = 1, default = AimConfig.smoothAmountY, step = 0.01,
		callback = function(v) AimConfig.smoothAmountY = v end,
	})
	Pred.Toggle({
		text = "Prediction", default = AimConfig.predict,
		callback = function(v) AimConfig.predict = v end,
	})
	Pred.Slider({
		text = "Prediction Amount", min = 0, max = 0.5, default = AimConfig.predictAmount, step = 0.005,
		callback = function(v) AimConfig.predictAmount = v end,
	})
	Pred.Slider({
		text = "Projectile Speed", min = 0, max = 1500, default = AimConfig.projectile, step = 1,
		callback = function(v) AimConfig.projectile = math.floor(v) end,
	})

	local AimSet = Aimbot.Group("Settings", { side = "right", info = "Target selection and limits" })
	AimSet.Toggle({
		text = "Wall Check", default = AimConfig.wallCheck,
		callback = function(v) AimConfig.wallCheck = v end,
	})
	AimSet.Toggle({
		text = "Team Check", default = AimConfig.aimTeamCheck,
		callback = function(v) AimConfig.aimTeamCheck = v end,
	})
	AimSet.Toggle({
		text = "Skip Knocked", default = AimConfig.aimKnockedCheck,
		callback = function(v) AimConfig.aimKnockedCheck = v end,
	})
	AimSet.Toggle({
		text = "Weapon Check", default = AimConfig.aimWeaponCheck,
		callback = function(v) AimConfig.aimWeaponCheck = v end,
	})
	AimSet.Toggle({
		text = "Sticky Target", default = AimConfig.sticky,
		callback = function(v) AimConfig.sticky = v end,
	})
	AimSet.Slider({
		text = "Max Turn", min = 0, max = 1440, default = AimConfig.maxTurn, step = 1,
		callback = function(v) AimConfig.maxTurn = math.floor(v) end,
	})
	AimSet.Toggle({
		text = "Rage Aimbot", default = AimConfig.rage,
		callback = function(v) AimConfig.rage = v end,
	})

	local Visual = UI.Tab("Visual", { icon = "100086900641425" })

	local ESP = Visual.Group("ESP", { side = "left", info = "Player ESP" })
	ESP.Toggle({
		text = "Enabled", default = SlateEspMenu.espEnabled(),
		callback = function(v) SlateEspMenu.setEsp(v) SlateEspMenu.refresh() end,
	})
	ESP.Toggle({
		text = "Fill", default = EspConfig.fill,
		color = EspConfig.color,
		callback = function(v) EspConfig.fill = v SlateEspMenu.refresh() end,
		colorCallback = function(c) EspConfig.color = c SlateEspMenu.refresh() end,
	})
	ESP.Slider({
		text = "Fill Transparency", min = 0, max = 1, default = EspConfig.fillTransparency, step = 0.01,
		callback = function(v) EspConfig.fillTransparency = v SlateEspMenu.refresh() end,
	})
	ESP.Toggle({
		text = "Outline", default = EspConfig.outline,
		callback = function(v) EspConfig.outline = v SlateEspMenu.refresh() end,
	})
	ESP.Toggle({
		text = "Corner Box", default = EspConfig.box,
		callback = function(v) EspConfig.box = v SlateEspMenu.refresh() end,
	})
	ESP.Slider({
		text = "Max Distance", min = 0, max = 5000, default = EspConfig.maxDistance, step = 10,
		callback = function(v) EspConfig.maxDistance = math.floor(v) SlateEspMenu.refresh() end,
	})

	local Overlay = Visual.Group("Overlay", { side = "left", info = "What is drawn on each player" })
	Overlay.Toggle({
		text = "Names", default = EspConfig.names,
		callback = function(v) EspConfig.names = v SlateEspMenu.refresh() end,
	})
	Overlay.Toggle({
		text = "Distance", default = EspConfig.distance,
		callback = function(v) EspConfig.distance = v SlateEspMenu.refresh() end,
	})
	Overlay.Toggle({
		text = "Health Bar", default = EspConfig.health,
		callback = function(v) EspConfig.health = v SlateEspMenu.refresh() end,
	})
	Overlay.Toggle({
		text = "Skeleton", default = EspConfig.skeleton,
		callback = function(v) EspConfig.skeleton = v SlateEspMenu.refresh() end,
	})
	Overlay.Toggle({
		text = "Tracers", default = EspConfig.tracers,
		callback = function(v) EspConfig.tracers = v SlateEspMenu.refresh() end,
	})

	local Filters = Visual.Group("Filters", { side = "right", info = "Who gets drawn" })
	Filters.Toggle({
		text = "Team Check", default = EspConfig.teamCheck,
		callback = function(v) EspConfig.teamCheck = v SlateEspMenu.refresh() end,
	})
	Filters.Toggle({
		text = "Team Colours", default = EspConfig.teamColor,
		callback = function(v) EspConfig.teamColor = v SlateEspMenu.refresh() end,
	})
	Filters.Color({
		text = "ESP Colour", default = EspConfig.color,
		callback = function(c) EspConfig.color = c SlateEspMenu.refresh() end,
	})

	local Menu = Visual.Group("Menu", { side = "right" })
	Menu.Keybind({
		text = "Menu Key", default = Enum.KeyCode.Insert,
		changed = function(kc) UI.SetMenuKey(kc) end,
	})
	Menu.Button({
		text = "Close", callback = function() UI.SetMenuVisible(false) end,
	})

	local Misc = UI.Tab("Misc", { icon = "100428338507079" })

	local Movement = Misc.Group("Movement", { side = "left", info = "Character movement tweaks" })
	Movement.Toggle({
		text = "Noclip",
		default = (Clip == false),
		callback = function(v)
			if v then execCmd("noclip") else execCmd("clip") end
		end,
	})
	Movement.Toggle({
		text = "Flight",
		default = FLYING == true,
		callback = function(v)
			if v then execCmd("fly") else execCmd("unfly") end
		end,
	})
	Movement.Toggle({
		text = "Infinite Jump",
		default = false,
		callback = function(v)
			if v then execCmd("infjump") else execCmd("uninfjump") end
		end,
	})
	Movement.Toggle({
		text = "Anti AFK",
		default = false,
		callback = function(v)
			if v then execCmd("antiafk") end
		end,
	})

	local World = Misc.Group("World", { side = "left", info = "Lighting and environment" })
	World.Toggle({
		text = "Fullbright",
		default = false,
		callback = function(v)
			if v then execCmd("loopfullbright") else execCmd("unloopfullbright") end
		end,
	})
	World.Toggle({
		text = "No Fog",
		default = false,
		callback = function(v)
			if v then execCmd("nofog") end
		end,
	})
	World.Button({
		text = "Set Day",
		callback = function() execCmd("day") end,
	})
	World.Button({
		text = "Set Night",
		callback = function() execCmd("night") end,
	})

	return UI
end

function SlateEspMenu.toggle()
	local UI = SlateEspMenu.build()
	if not UI then
		if queueNotification then
			queueNotification("ESP", "The ESP menu is still loading.")
		end
		return
	end
	UI.ToggleMenu()
end

_G.SlateToggleEspMenu = SlateEspMenu.toggle

print(string.format("main loaded in %.4fs", os.clock() - _slateLoadStart))
