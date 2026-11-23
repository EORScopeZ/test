if not LPS_OBFUSCATED then
	local attribute = function() end
	LPS_ATTRIBUTES = attribute
	VM = attribute
	NONE = attribute
	LPS_ENCSTR = function(v) return v end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local env = getgenv and getgenv() or _G
local server = string.gsub(string.gsub(env.LumenServer or LPS_ENCSTR("https://lum3n.lol"), "/+$", ""), "/ws$", "")
local origin = string.match(server, "^(https://[^/]+)") or server
local gif = server .. LPS_ENCSTR("/gif")
local moderate = server .. LPS_ENCSTR("/moderate")
local api = server .. LPS_ENCSTR("/nametag")
local socket = string.gsub(server, "^http", "ws") .. LPS_ENCSTR("/ws")
local proxy = LPS_ENCSTR("https://wsrv.nl/?url=")

local request = http and http.request or http_request or request
local custom = getcustomasset or get_custom_asset

local white = Color3.new(1, 1, 1)
local root = "Lumen/client"
local glyphs = { "!", "@", "#", "$", "%", "&", "*", "?", "/", "X", "Z", "0", "1" }

local default = {
	name_text = "Lumen User",
	tag_color = "#0f0f0f",
	name_color = "#ffffff",
	outline_color = "#ffffff",
	glow_color = "#5c5c5c",
	image_url = "https://i.postimg.cc/MZ0LKbL3/image.jpg",
	icon_image = "https://i.postimg.cc/L5zRmLS5/Untitled-design-(1)-Photoroom.png",
	nametag_shape = "squircle",
	font = "GothamBold",
	size_preset = "medium",
	tag_anim = "glow-pulse",
	stroke_thickness = 3,
	bg_type = "image",
	text_gradient_enabled = true,
	text_gradient_dir = "to right",
	text_gradient_stops = { { color = "#ffffff", pos = 0 }, { color = "#000000", pos = 100 } },
	text_gradient_anim_enabled = true,
	text_gradient_speed = 3,
	stroke_gradient_enabled = true,
	stroke_gradient_dir = "to right",
	stroke_gradient_stops = { { color = "#000000", pos = 0 }, { color = "#ffffff", pos = 100 } },
	stroke_gradient_anim_enabled = true,
}

local shapes = {
	pill = { scale = 0.5, offset = 0, thickness = 1.5, alpha = 0.68 },
	squircle = { scale = 0, offset = 13, thickness = 1.5, alpha = 0.65 },
	docked = { scale = 0, offset = 12, thickness = 1.5, alpha = 0.68 },
	chamfer = { scale = 0, offset = 4, thickness = 1.6, alpha = 0.45 },
	glass = { scale = 0, offset = 16, thickness = 1.25, alpha = 0, bg = 0.4, glass = true },
}

local sizes = {
	small = { height = 40, disc = 32, title = 12, name = 10, min = 110, lift = 2 },
	medium = { height = 48, disc = 40, title = 14, name = 11, min = 136, lift = 2.2 },
	large = { height = 58, disc = 48, title = 17, name = 13, min = 160, lift = 2.5 },
}

local assets = {}
local failed = {}
local sheets = {}
local verdicts = {}
local busy = 0

local function enabled()
	local flag = rawget(_G, "tag")
	if flag == nil then
		flag = env.tag
	end
	return flag ~= false and not (type(flag) == "string" and string.lower(flag) == "false")
end

local function resolve(name)
	name = string.lower(tostring(name or ""))
	if name == "square" then
		return "squircle"
	end
	return if shapes[name] then name else "pill"
end

local function hex(value)
	local r, g, b = string.match(tostring(value or ""), "^#(%x%x)(%x%x)(%x%x)")
	if r then
		return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
	end
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function round(n)
	return math.floor(n + 0.5)
end

local function make(class, props)
	local inst = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	inst.Parent = props.Parent
	return inst
end

local function decode(body)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
	return ok and data or nil
end

local function fetch(url, method, body)
	while busy >= 6 do
		task.wait(0.02)
	end
	busy += 1
	local ok, status, data = false, 0, ""
	if request then
		local success, res = pcall(request, {
			Url = url,
			Method = method or "GET",
			Headers = if body then { ["Content-Type"] = "application/json" } else nil,
			Body = body,
		})
		if success and type(res) == "table" then
			ok, status, data = true, res.StatusCode or res.Status or 0, res.Body or ""
		end
	else
		local success, res = pcall(game.HttpGetAsync, game, url)
		if success then
			ok, status, data = true, 200, res
		end
	end
	busy -= 1
	return ok, status, data
end

local function sniff(body)
	if string.sub(body, 1, 8) == "\137PNG\r\n\26\n" then
		return "png"
	elseif string.sub(body, 1, 3) == "\255\216\255" then
		return "jpg"
	end
end

local function hash(s)
	local a, b = 5381, 52711
	for i = 1, #s do
		local c = string.byte(s, i)
		a = (a * 33 + c) % 4294967296
		b = (b * 31 + c) % 4294967296
	end
	return string.format("%08x%08x", a, b)
end

local function basename(path)
	return string.match(string.gsub(path, "\\", "/"), "([^/]+)$") or path
end

local function ensure(path)
	if not (makefolder and isfolder) then
		return false
	end
	local current
	for part in string.gmatch(path, "[^/]+") do
		current = if current then current .. "/" .. part else part
		local ok, exists = pcall(isfolder, current)
		if not (ok and exists) then
			pcall(makefolder, current)
		end
	end
	local ok, exists = pcall(isfolder, path)
	return ok and exists
end

local function dir(id)
	return root .. "/" .. tostring(id)
end

local function slot(id, kind, key)
	return kind .. "image_" .. tostring(id) .. "_" .. hash(key)
end

local function mount(path)
	if not assets[path] then
		local ok, asset = pcall(custom, path)
		assets[path] = ok and asset or nil
	end
	return assets[path]
end

local function purge(id, kind, keep)
	if not (listfiles and delfile and isfolder) then
		return
	end
	local path = dir(id)
	local ok, exists = pcall(isfolder, path)
	if not (ok and exists) then
		return
	end
	local listed, files = pcall(listfiles, path)
	if not listed or type(files) ~= "table" then
		return
	end
	local prefix = kind and kind .. "image_"
	for _, file in files do
		local name = basename(file)
		local ours = if prefix then string.sub(name, 1, #prefix) == prefix else string.find(name, "^%a+image_") ~= nil
		if ours and not (keep and string.sub(name, 1, #keep) == keep) then
			pcall(delfile, file)
			assets[path .. "/" .. name] = nil
		end
	end
end

local function wipe(id)
	purge(id)
	if delfolder and isfolder then
		local path = dir(id)
		local ok, exists = pcall(isfolder, path)
		if ok and exists then
			pcall(delfolder, path)
		end
	end
end

local function cached(id, kind, key)
	if not (isfile and custom) then
		return
	end
	local name = slot(id, kind, key)
	for _, ext in { "png", "jpg" } do
		local path = dir(id) .. "/" .. name .. "." .. ext
		local ok, exists = pcall(isfile, path)
		local asset = ok and exists and mount(path)
		if asset then
			purge(id, kind, name)
			return asset
		end
	end
end

local function download(url, width, id, kind, key)
	if not url or url == "" then
		return
	end
	if string.match(url, "^%d+$") then
		return "rbxassetid://" .. url
	end
	if not string.match(url, "^https?://") then
		return url
	end
	if not (writefile and custom) then
		return
	end
	local hit = cached(id, kind, key)
	if hit then
		return hit
	end
	local name = slot(id, kind, key)
	if failed[name] and os.clock() - failed[name] < 30 then
		return
	end
	local sources = { url }
	if width < 1024 then
		table.insert(sources, proxy .. HttpService:UrlEncode(url) .. "&w=" .. width .. "&output=png")
	end
	for _, source in sources do
		local ok, status, body = fetch(source)
		local ext = ok and status == 200 and sniff(body)
		if ext and ensure(dir(id)) then
			local path = dir(id) .. "/" .. name .. "." .. ext
			if pcall(writefile, path, body) then
				purge(id, kind, name)
				local asset = mount(path)
				if asset then
					failed[name] = nil
					return asset
				end
			end
		end
	end
	failed[name] = os.clock()
end

local function animated(src)
	local bare = string.lower(string.match(src, "^([^%?#]*)") or "")
	return string.match(bare, "^https://") ~= nil and string.match(bare, "%.gif$") ~= nil
end

local function convert(src, kind)
	local key = kind .. "|" .. src
	if sheets[key] then
		return sheets[key]
	end
	local ok, status, body = fetch(gif .. "?kind=" .. kind .. "&url=" .. HttpService:UrlEncode(src))
	local data = ok and status == 200 and decode(body)
	if type(data) ~= "table" or type(data.sheet) ~= "string" or not tonumber(data.frames) then
		return
	end
	data.image = origin .. data.sheet
	sheets[key] = data
	return data
end

local function allowed(src)
	if not string.match(src, "^https://") or string.sub(src, 1, #origin + 1) == origin .. "/" then
		return true
	end
	if verdicts[src] == nil then
		local ok, status, body = fetch(moderate, "POST", HttpService:JSONEncode({ url = src }))
		local res = ok and status == 200 and decode(body)
		verdicts[src] = not (type(res) == "table" and res.safe == false)
	end
	return verdicts[src]
end

local function stops(list)
	local out = {}
	if type(list) ~= "table" then
		return out
	end
	for _, stop in list do
		local color = hex(stop.color)
		if color then
			table.insert(out, { pos = math.clamp((tonumber(stop.pos) or 0) / 100, 0, 1), color = color })
		end
	end
	table.sort(out, function(a, b)
		return a.pos < b.pos
	end)
	return out
end

local function sequence(list, loop)
	local points = stops(list)
	if #points < 2 then
		return
	end
	if loop then
		local mirrored = {}
		for _, p in points do
			table.insert(mirrored, { pos = p.pos / 2, color = p.color })
		end
		for i = #points, 1, -1 do
			table.insert(mirrored, { pos = 1 - points[i].pos / 2, color = points[i].color })
		end
		points = mirrored
	end
	if points[1].pos > 0 then
		table.insert(points, 1, { pos = 0, color = points[1].color })
	end
	if points[#points].pos < 1 then
		table.insert(points, { pos = 1, color = points[#points].color })
	end
	local keys, prev = {}, 0
	for i, p in points do
		local pos = if i == 1 then 0 elseif i == #points then 1 else math.clamp(p.pos, prev + 0.001, 1 - 0.001 * (#points - i))
		table.insert(keys, ColorSequenceKeypoint.new(pos, p.color))
		prev = pos
	end
	return ColorSequence.new(keys)
end

local function rotation(direction)
	direction = string.lower(tostring(direction or "to right"))
	local bottom, top = string.find(direction, "bottom") ~= nil, string.find(direction, "top") ~= nil
	local left, right = string.find(direction, "left") ~= nil, string.find(direction, "right") ~= nil
	if bottom and right then
		return 45
	elseif bottom and left then
		return 135
	elseif top and left then
		return 225
	elseif top and right then
		return 315
	elseif bottom then
		return 90
	elseif left then
		return 180
	elseif top then
		return 270
	end
	return 0
end

local function strip(cfg, prefix)
	local url = cfg[prefix .. "spritesheet_url"]
	if url and url ~= "" and (tonumber(cfg[prefix .. "frame_count"]) or 0) > 0 then
		return {
			url = url,
			w = cfg[prefix .. "frame_width"],
			h = cfg[prefix .. "frame_height"],
			frames = cfg[prefix .. "frame_count"],
			cols = cfg[prefix .. "frames_per_row"],
			delay = cfg[prefix .. "frame_delay"],
		}
	end
end

local function choose(value, list, fallback)
	for _, v in list do
		if v == value then
			return value
		end
	end
	return fallback
end

local radii = { circle = 0.5, rounded = 0.28, none = 0 }
local badges = {
	small = { h = 14, t = 9, i = 8, p = 6 },
	medium = { h = 16, t = 10, i = 10, p = 7 },
	large = { h = 18, t = 11, i = 11, p = 8 },
}
local legacy = {
	playfair = "playfair-display",
	playfairdisplay = "playfair-display",
	bungee = "bungee",
	pressstart2p = "press-start-2p",
	righteous = "righteous",
	orbitron = "orbitron",
	silkscreen = "silkscreen",
	syne = "syne",
	outfit = "outfit",
	bebasneue = "bebas-neue",
	poppins = "poppins",
}
local swarm = { used = 0, cap = 120 }

local function clamp(v, lo, hi, fallback)
	return math.clamp(tonumber(v) or fallback, lo, hi)
end

local function styled(cfg)
	local raw = if type(cfg.style) == "table" then cfg.style else {}
	local icon = if type(raw.icon) == "table" then raw.icon else {}
	local ring = if type(icon.ring) == "table" then icon.ring else {}
	local sub = if type(raw.subtitle) == "table" then raw.subtitle else {}
	local badge = if type(raw.badge) == "table" then raw.badge else {}
	local font = if type(raw.font) == "table" then raw.font else {}
	local fx = if type(raw.fx) == "table" then raw.fx else {}
	local motion = if type(raw.motion) == "table" then raw.motion else {}
	local mtext = if type(motion.text) == "table" then motion.text else {}
	local mout = if type(motion.outline) == "table" then motion.outline else {}
	local mglow = if type(motion.glow) == "table" then motion.glow else {}
	local side = choose(icon.side, { "left", "right", "hidden", "custom" }, "left")
	local spots = if type(raw.layout) == "table" then raw.layout else {}
	local function spot(key, fx, fy)
		local v = if type(spots[key]) == "table" then spots[key] else {}
		return { x = clamp(v.x, 0, 1, fx), y = clamp(v.y, 0, 1, fy) }
	end
	local shape = choose(icon.shape, { "circle", "rounded", "none" }, "circle")
	local line = choose(sub.mode, { "username", "display", "custom", "hidden" }, "username")
	local text = string.upper(if type(badge.text) == "string" then string.sub(badge.text, 1, 48) else "")
	local kind = choose(fx.kind, { "none", "sparkles", "embers", "snow", "custom" }, "none")
	local image = if type(fx.image) == "string" and string.match(fx.image, "^https://") then fx.image else ""
	if kind == "custom" and image == "" then
		kind = "none"
	end
	local place = "below"
	return {
		side = side,
		spots = if side == "custom"
			then { icon = spot("icon", 0.13, 0.5), title = spot("title", 0.56, 0.34), line = spot("line", 0.46, 0.68), badge = spot("badge", 0.8, 0.68) }
			else nil,
		shape = shape,
		scale = clamp(icon.scale, 0.6, if shape == "none" then 1.1 else 1.2, 1),
		ring = if ring.on == true and side ~= "hidden"
			then {
				width = clamp(ring.width, 1, 3.5, 2),
				color = hex(ring.color) or white,
				colors = sequence(ring.stops),
				rotation = rotation(ring.dir),
			}
			else nil,
		line = line,
		text = if type(sub.text) == "string" then string.sub(sub.text, 1, 160) else "",
		tint = hex(sub.color),
		size = clamp(sub.scale, 0.8, 1.15, 1),
		opacity = clamp(sub.opacity, 0.6, 1, 1),
		badge = if badge.on == true and text ~= ""
			then {
				text = text,
				icon = if type(badge.icon) == "string" and string.match(badge.icon, "^[a-z]+$") then badge.icon else "",
				fg = hex(badge.fg) or white,
				bg = hex(badge.bg) or Color3.fromRGB(139, 92, 246),
				solid = badge.fill ~= "soft",
				grad = clamp(badge.grad, 0, 1, 0.45),
				angle = (tonumber(badge.angle) or 90) % 360,
				place = place,
			}
			else nil,
		font = if font.src == "library" and type(font.id) == "string" and string.match(font.id, "^[a-z0-9%-]+$")
			then { url = origin .. "/tag/fonts/" .. font.id .. ".ttf", key = font.id }
			elseif font.src == "upload" and type(font.url) == "string" and string.match(font.url, "^https://[^/]+/u/%x+%.[ot]tf$")
			then { url = font.url, key = "u" .. hash(font.url) }
			else nil,
		fx = if kind ~= "none"
			then {
				kind = kind,
				image = image,
				color = hex(fx.color) or white,
				density = math.floor(clamp(fx.density, 2, 16, 8)),
				speed = clamp(fx.speed, 0.25, 3, 1),
				size = clamp(fx.size, 0.5, 2, 1),
			}
			else nil,
		pace = clamp(mtext.speed, 0.25, 3, 1),
		ease = choose(mtext.ease, { "smooth", "linear", "snappy" }, "smooth"),
		outline = clamp(mout.speed, 0.25, 3, 1),
		glowSize = clamp(mglow.size, 6, 30, 14),
		glowStrength = clamp(mglow.strength, 0.1, 1, 0.7),
		glowSpeed = clamp(mglow.speed, 0.25, 3, 1),
		glowDepth = clamp(mglow.depth, 0, 1, 0.45),
	}
end

local function fontSource(cfg, st)
	if st.font then
		return st.font
	end
	local name = tostring(cfg.font or "")
	if name == "" or pcall(function()
		return Enum.Font[name]
	end) then
		return nil
	end
	local id = legacy[string.lower(name)]
	return if id then { url = origin .. "/tag/fonts/" .. id .. ".ttf", key = id } else nil
end

local faces, loading = {}, {}
local function family(source)
	local key = source.key
	if faces[key] ~= nil then
		return faces[key] or nil
	end
	if loading[key] then
		local started = os.clock()
		while loading[key] and os.clock() - started < 20 do
			task.wait(0.05)
		end
		return faces[key] or nil
	end
	loading[key] = true
	local ok, face = pcall(function()
		assert(writefile and isfile and custom, "file api missing")
		local folder = root .. "/fonts"
		assert(ensure(folder), "no folder")
		local path
		for _, ext in { "ttf", "otf" } do
			local candidate = folder .. "/" .. key .. "." .. ext
			local found, exists = pcall(isfile, candidate)
			if found and exists then
				path = candidate
			end
		end
		if not path then
			local got, status, body = fetch(source.url)
			local head = got and status == 200 and string.sub(body, 1, 4)
			assert(head == "\0\1\0\0" or head == "true" or head == "OTTO", "not a font")
			path = folder .. "/" .. key .. (if head == "OTTO" then ".otf" else ".ttf")
			writefile(path, body)
		end
		local manifest = folder .. "/" .. key .. ".json"
		writefile(manifest, HttpService:JSONEncode({
			name = key,
			faces = { { name = "Regular", weight = 400, style = "normal", assetId = custom(path) } },
		}))
		return Font.new(custom(manifest), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end)
	faces[key] = ok and face or false
	loading[key] = nil
	return faces[key] or nil
end

local function bounds(text, face, px)
	local ok, v = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = face
		params.Size = px
		params.Width = 2000
		return TextService:GetTextBoundsAsync(params).X
	end)
	return if ok and v > 0 then v else nil
end

local function textWidth(text, px, font)
	local ok, v = pcall(function()
		return TextService:GetTextSize(text, px, font, Vector2.new(2000, 60)).X
	end)
	return if ok then v else 0
end

local function chipSize(badge, preset)
	local m = badges[preset] or badges.medium
	local tw = math.ceil(textWidth(badge.text, m.t, Enum.Font.GothamBold))
	local icon = if badge.icon ~= "" then m.i else 0
	return { w = m.p * 2 + icon + (if icon > 0 then 4 else 0) + tw, h = m.h, px = m.t, icon = icon, tw = tw, pad = m.p }
end

local function glowTo(shadow, transparency)
	shadow.Transparency = math.clamp(transparency, 0, 1)
end

local function curve(x, ease)
	if ease == "linear" then
		return math.asin(math.clamp(x, -1, 1)) * 2 / math.pi
	elseif ease == "snappy" then
		return math.sign(x) * math.sqrt(math.abs(x))
	end
	return x
end

local function ramp(list, loop)
	local points = stops(list)
	if #points < 2 then
		return nil
	end
	if loop then
		local mirrored = {}
		for _, p in points do
			table.insert(mirrored, { pos = p.pos / 2, color = p.color })
		end
		for i = #points, 1, -1 do
			table.insert(mirrored, { pos = 1 - points[i].pos / 2, color = points[i].color })
		end
		points = mirrored
	end
	return points
end

local function sample(points, u)
	u = math.clamp(u, 0, 1)
	local prev = points[1]
	if u <= prev.pos then
		return prev.color
	end
	for i = 2, #points do
		local p = points[i]
		if u <= p.pos then
			local span = p.pos - prev.pos
			return if span > 0 then prev.color:Lerp(p.color, (u - prev.pos) / span) else p.color
		end
		prev = p
	end
	return prev.color
end

local function slice(points, a, b)
	local keys = { ColorSequenceKeypoint.new(0, sample(points, a)) }
	if b > a then
		for _, p in points do
			local k = (p.pos - a) / (b - a)
			if k > 0.001 and k < 0.999 then
				table.insert(keys, ColorSequenceKeypoint.new(k, p.color))
			end
		end
	end
	table.insert(keys, ColorSequenceKeypoint.new(1, sample(points, b)))
	return ColorSequence.new(keys)
end

local function particle(kind, i, t, speed, mul)
	local function r(k)
		local v = math.sin(i * 12.9898 + k * 78.233) * 43758.5453
		return v - math.floor(v)
	end
	local base = if kind == "embers" then 1.6 + r(1) * 1.4 elseif kind == "snow" then 2.4 + r(1) * 1.6 else 1.4 + r(1) * 1.2
	local life = base / speed
	local clock = t + r(2) * life
	local cycle = math.floor(clock / life)
	local p = (clock - cycle * life) / life
	local function q(k)
		local v = math.sin((i + cycle * 7.13) * 12.9898 + k * 78.233) * 43758.5453
		return v - math.floor(v)
	end
	local wave = math.sin(p * math.pi)
	if kind == "embers" then
		return q(3), 1 - p * 1.25, math.sin(p * math.pi * 2 + i) * 4, (3 + r(5) * 2.5) * mul, wave * 0.9, 1
	elseif kind == "snow" then
		return q(3), -0.15 + p * 1.3, math.sin(p * math.pi * 2 + i) * 5, (3 + r(5) * 2) * mul, math.min(1, wave * 1.4) * 0.85, 1
	end
	return -0.04 + q(3) * 1.08, -0.15 + q(4) * 1.3, 0, (if kind == "custom" then 10 + r(5) * 4 else 7 + r(5) * 5) * mul, wave, wave
end

local container
local function holder()
	if container and container.Parent then
		return container
	end
	local core = game:GetService("CoreGui")
	local function visible(inst)
		if typeof(inst) ~= "Instance" then
			return false
		end
		local ok, inside = pcall(function()
			return inst == core or inst:IsDescendantOf(core)
		end)
		return ok and inside
	end
	local ok, found = pcall(gethui)
	if ok and visible(found) then
		container = found
		return found
	end
	ok, found = pcall(function()
		return core:FindFirstChild("LumenNametags") or make("Folder", { Name = "LumenNametags", Parent = core })
	end)
	if ok and visible(found) then
		container = found
		return found
	end
	local gui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if gui then
		ok, found = pcall(function()
			return gui:FindFirstChild("LumenNametags") or make("ScreenGui", { Name = "LumenNametags", ResetOnSpawn = false, Parent = gui })
		end)
		if ok and found then
			container = found
			return found
		end
	end
end

local Tag = {}
Tag.__index = Tag

function Tag.new(player, lumen)
	local self = setmetatable({
		player = player,
		lumen = lumen,
		token = 0,
		shrink = 0,
		goal = 0,
		clock = 0,
		anims = {},
		grads = {},
	}, Tag)
	self.beat = RunService.Heartbeat:Connect(function(dt)
		self:step(dt)
	end)
	self.respawn = player.CharacterAdded:Connect(function()
		task.wait(0.1)
		self:build()
	end)
	if lumen then
		self:lookup()
	end
	return self
end

function Tag:lookup()
	if self.loading or self.own ~= nil then
		return
	end
	self.loading = true
	task.spawn(function()
		local player = self.player
		local url = api .. "?user=" .. HttpService:UrlEncode(tostring(player.UserId)) .. "&username=" .. HttpService:UrlEncode(player.Name)
		local data
		for try = 1, 3 do
			local ok, status, body = fetch(url)
			data = ok and status == 200 and decode(body)
			if data then
				break
			end
			if try < 3 then
				task.wait(try * 2)
			end
		end
		self.loading = false
		if self.dead then
			return
		end
		if type(data) == "table" and type(data.tag) == "table" then
			self.misses = 0
			self.own = data.tag
			if self.lumen then
				self:apply(data.tag)
			end
		elseif type(data) == "table" then
			self.misses = 0
			self.own = false
			if self.lumen and not self.config then
				self:apply(default)
			end
		else
			self.misses = (self.misses or 0) + 1
			if self.lumen and not self.config and self.misses >= 2 then
				self:apply(default)
			end
			task.delay(math.min(60, 4 * 2 ^ math.min(self.misses, 4)), function()
				if not self.dead and self.own == nil then
					self:lookup()
				end
			end)
		end
	end)
end

function Tag:apply(cfg)
	local config = {}
	for k, v in cfg do
		if v ~= "" then
			config[k] = v
		end
	end
	config.nametag_shape = resolve(config.nametag_shape)
	self.config = config
	local source = fontSource(config, styled(config))
	local known = source and faces[source.key]
	self.face = if known then known else nil
	self.faceWidth = nil
	if self.face then
		self.faceWidth = bounds(config.name_text or "", self.face, (sizes[string.lower(tostring(config.size_preset))] or sizes.medium).title)
	end
	self:build()
	if source and known == nil then
		task.spawn(function()
			local face = family(source)
			if face and self.config == config and not self.dead then
				self.face = face
				self.faceWidth = bounds(config.name_text or "", face, (sizes[string.lower(tostring(config.size_preset))] or sizes.medium).title)
				self:build()
			end
		end)
	end
end

function Tag:clear()
	self.own = false
	task.spawn(wipe, self.player.UserId)
	if self.lumen then
		self:apply(default)
	else
		self.config = nil
		self:build()
	end
end

function Tag:toggle(on)
	if self.lumen == on then
		return
	end
	self.lumen = on
	if not on then
		if self.config then
			self.config = nil
			self:build()
		end
	elseif self.own then
		self:apply(self.own)
	elseif self.own == false then
		if not self.config then
			self:apply(default)
		end
	else
		self:lookup()
	end
end

function Tag:head()
	local character = self.player.Character
	return character and character.Parent and character:FindFirstChild("Head")
end

function Tag:animate(img, meta)
	if not meta then
		self.anims[img] = nil
		img.ImageRectSize = Vector2.zero
		img.ImageRectOffset = Vector2.zero
		return
	end
	local w, h = tonumber(meta.w) or 0, tonumber(meta.h) or 0
	local frames = math.max(1, tonumber(meta.frames) or 1)
	local cols = math.max(1, tonumber(meta.cols) or 1)
	local scale = 1024 / math.max(cols * w, math.ceil(frames / cols) * h)
	if scale < 1 then
		w *= scale
		h *= scale
	end
	local pad = if w > 8 and h > 8 then 1 else 0
	local ms = tonumber(meta.delay) or 100
	if ms < 20 then
		ms = 100
	end
	img.ImageRectSize = Vector2.new(w - pad * 2, h - pad * 2)
	img.ImageRectOffset = Vector2.new(pad, pad)
	self.anims[img] = {
		frames = frames,
		cols = cols,
		w = w,
		h = h,
		pad = pad,
		delay = math.max(0.04, ms / 1000),
		frame = 0,
		elapsed = 0,
	}
end

function Tag:avatar(img)
	local token = self.token
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, self.player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		if ok and token == self.token and img.Parent then
			img.ScaleType = Enum.ScaleType.Crop
			img.Image = url
		end
	end)
end

function Tag:image(img, src, kind, sheet, otherwise)
	local token = self.token
	local id = self.player.UserId
	task.spawn(function()
		local function alive()
			return token == self.token and img.Parent ~= nil
		end
		local function fail()
			if otherwise and alive() then
				otherwise()
			end
		end
		local function film(url, meta)
			local cols = math.max(1, tonumber(meta.cols) or 1)
			local rows = math.ceil(math.max(1, tonumber(meta.frames) or 1) / cols)
			local big = math.max(cols * (tonumber(meta.w) or 0), rows * (tonumber(meta.h) or 0)) > 1024
			local asset
			for try = 1, 3 do
				asset = download(url, 1024, id, kind, "sheet:" .. url)
				if not asset and big and alive() then
					local fit = proxy .. HttpService:UrlEncode(url) .. "&w=1024&h=1024&fit=inside&output=png"
					asset = download(fit, 1024, id, kind, "s1024:" .. url)
				end
				if asset or not alive() then
					break
				end
				task.wait(try * 2)
			end
			if asset and alive() then
				img.Image = asset
				img.ScaleType = if kind == "icon" then Enum.ScaleType.Fit else Enum.ScaleType.Crop
				self:animate(img, meta)
				return true
			end
			return false
		end
		if sheet and film(sheet.url, sheet) then
			return
		end
		if not src or src == "" then
			return fail()
		end
		if animated(src) then
			local meta = convert(src, kind)
			if not (meta and film(meta.image, meta)) then
				fail()
			end
			return
		end
		local asset = cached(id, kind, src)
		if not asset and allowed(src) then
			asset = download(src, if kind == "bg" then 512 else 128, id, kind, src)
		end
		if asset and alive() then
			img.Image = asset
			img.ScaleType = if img:GetAttribute("fit") then Enum.ScaleType.Fit else Enum.ScaleType.Crop
			self:animate(img, nil)
		else
			fail()
		end
	end)
end

function Tag:line(st)
	if st.line == "hidden" then
		return ""
	elseif st.line == "custom" then
		return st.text
	elseif st.line == "display" then
		return self.player.DisplayName
	end
	return "@" .. self.player.Name
end

function Tag:measure(cfg, size, font, st, disc, gap)
	local text = cfg.name_text or ""
	local title = if self.face and self.faceWidth then self.faceWidth else textWidth(text, size.title, font)
	if title <= 0 then
		title = (utf8.len(text) or #text) * size.title * 0.28
	end
	local line = self:line(st)
	local px = math.min(round(size.name * st.size), size.title - 2)
	local sub = if line ~= "" then textWidth(line, px, Enum.Font.Gotham) else 0
	local chip = st.badge and chipSize(st.badge, string.lower(tostring(cfg.size_preset)))
	local a, b = if self.face and self.faceWidth then title else math.max(title, (utf8.len(text) or #text) * size.title * 0.28), sub
	if chip and st.badge.place == "after" then
		a += chip.w + 6
	elseif chip and st.badge.place == "below" then
		b = (if sub > 0 then sub + 6 else 0) + chip.w
	end
	local lead = if st.side == "hidden" then 18 else disc + gap + 10
	return {
		width = math.clamp(math.max(a, b) + lead + 26, size.min, 360),
		title = title,
		sub = sub,
		line = line,
		px = px,
		chip = chip,
	}
end

function Tag:chip(spec, chip, parent, position, z)
	local fades = {}
	local function fade(inst, prop)
		table.insert(fades, { inst = inst, prop = prop, base = inst[prop] })
		return inst
	end
	local s = spec.grad or 0.45
	local shaded = s > 0.01
	local dark = Color3.fromRGB(9, 9, 13)
	local fillColor = if spec.solid then spec.bg else dark:Lerp(spec.bg, 0.28 + s * 0.34)
	local frame = fade(make("Frame", {
		Position = position,
		Size = UDim2.fromOffset(chip.w, chip.h),
		BackgroundColor3 = if shaded then white else fillColor,
		BackgroundTransparency = if spec.solid then 0 else 0.22,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = parent,
	}), "BackgroundTransparency")
	make("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = frame })
	if shaded then
		local seq = if spec.solid
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, spec.bg:Lerp(white, s * 0.34)),
				ColorSequenceKeypoint.new(0.52, spec.bg),
				ColorSequenceKeypoint.new(1, spec.bg:Lerp(Color3.new(0, 0, 0), s * 0.42)),
			})
			else ColorSequence.new(fillColor, dark:Lerp(spec.bg, math.max(0.12, 0.28 - s * 0.14)))
		make("UIGradient", { Color = seq, Rotation = spec.angle or 90, Parent = frame })
	end
	fade(make("UIStroke", {
		Color = spec.bg:Lerp(white, if spec.solid then 0.48 else 0.2),
		Transparency = if spec.solid then 0.64 else 0.42,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame,
	}), "Transparency")
	if chip.icon > 0 then
		local glyph = fade(make("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(chip.pad, (chip.h - chip.icon) // 2),
			Size = UDim2.fromOffset(chip.icon, chip.icon),
			ImageColor3 = spec.fg,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = z + 1,
			Parent = frame,
		}), "ImageTransparency")
		glyph:SetAttribute("fit", true)
		self:image(glyph, origin .. "/tag/badge-" .. spec.icon .. ".png", "badge", nil)
	end
	fade(make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(chip.pad + chip.icon + (if chip.icon > 0 then 4 else 0), 0),
		Size = UDim2.new(0, chip.tw + 2, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = spec.text,
		TextSize = chip.px,
		TextColor3 = spec.fg,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = z + 1,
		Parent = frame,
	}), "TextTransparency")
	return { frame = frame, fades = fades }
end

function Tag:build()
	LPS_ATTRIBUTES(VM(NONE))
	self.token += 1
	if self.gui then
		self.gui:Destroy()
		self.gui = nil
	end
	table.clear(self.anims)
	table.clear(self.grads)
	self.glow = nil
	swarm.used -= self.fxCount or 0
	self.fxCount = 0
	self.particles = nil
	local cfg = self.config
	local head = self:head()
	if not cfg or not head or self.dead then
		return
	end

	local kind = cfg.nametag_shape
	local style = shapes[kind]
	local size = sizes[string.lower(tostring(cfg.size_preset))] or sizes.medium
	local font = Enum.Font.GothamBold
	pcall(function()
		if cfg.font and cfg.font ~= "" then
			font = Enum.Font[cfg.font]
		end
	end)
	local st = styled(cfg)
	if st.ring then
		st.ring.width = math.min(st.ring.width, math.max(2, math.floor(size.disc * 0.16) / 2))
	end
	local ringWidth = if st.ring then math.ceil(st.ring.width) else 0
	local dsz = math.min(size.height - 4 - ringWidth * 2, round(size.disc * st.scale))
	local gap = math.max(4, ringWidth + 2)
	local metrics = self:measure(cfg, size, font, st, dsz, gap)
	local width, height = metrics.width, size.height

	local gui = make("BillboardGui", {
		Name = "LumenNametag",
		AlwaysOnTop = true,
		Active = true,
		LightInfluence = 0,
		Size = UDim2.fromOffset(width, height),
		StudsOffsetWorldSpace = Vector3.new(0, size.lift, 0),
		ResetOnSpawn = false,
		Adornee = head,
	})
	local parent = holder()
	if not (parent and pcall(function()
		gui.Parent = parent
	end) and gui.Parent == parent) then
		gui.Parent = head
	end
	self.gui = gui
	self.shown = nil

	if self.player ~= Players.LocalPlayer then
		local button = make("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 20,
			Parent = gui,
		})
		button.MouseButton1Click:Connect(function()
			local mine = Players.LocalPlayer.Character
			local from = mine and mine:FindFirstChild("HumanoidRootPart")
			local theirs = self.player.Character
			local to = theirs and theirs:FindFirstChild("HumanoidRootPart")
			if from and to then
				from.CFrame = to.CFrame * CFrame.new(0, 0, 4)
			end
		end)
	end

	local radius = UDim.new(style.scale, style.offset)
	local accent = hex(cfg.outline_color) or white
	local glow = hex(cfg.glow_color)
	local thickness = tonumber(cfg.stroke_thickness) or 0
	self.pulse = cfg.tag_anim == "glow-pulse"
	self.glowBase = 1 - st.glowStrength
	self.glowDepth = st.glowDepth
	self.glowSpeed = st.glowSpeed
	self.pace = st.pace
	self.ease = st.ease


	local alpha = math.max(style.bg or 0, tonumber(cfg.bg_transparency) or 0)
	local base = hex(cfg.tag_color) or Color3.fromRGB(15, 15, 15)
	local card = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = if style.glass then white else base,
		BackgroundTransparency = alpha,
		ZIndex = 1,
		Parent = gui,
	})
	local corners = { make("UICorner", { CornerRadius = radius, Parent = card }) }
	if glow or self.pulse then
		local size = math.max(4, st.glowSize)
		local host = make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = base,
			BackgroundTransparency = 0.99,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = gui,
		})
		table.insert(corners, make("UICorner", { CornerRadius = radius, Parent = host }))
		local spread = round(size * 4 / 7)
		local made, shadow = pcall(make, "UIShadow", {
			Color = glow or accent,
			BlurRadius = UDim.new(0, round(size * 9 / 7)),
			Spread = UDim2.fromOffset(spread, spread),
			Offset = UDim2.fromOffset(0, 0),
			ShowBehindParent = false,
			ZIndex = -1,
			Transparency = 1,
			Parent = host,
		})
		if made and shadow then
			self.glow = shadow
			glowTo(shadow, self.glowBase)
		else
			host:Destroy()
		end
	end
	if style.glass then
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, base:Lerp(white, 0.22)),
				ColorSequenceKeypoint.new(0.55, base),
				ColorSequenceKeypoint.new(1, base:Lerp(Color3.new(0, 0, 0), 0.15)),
			}),
			Parent = card,
		})
	end

	if cfg.bg_type == "gradient" then
		local colors = sequence(cfg.bg_gradient_stops)
		if colors then
			card.BackgroundTransparency = 1
			local fill = make("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = white,
				BackgroundTransparency = alpha,
				BorderSizePixel = 0,
				ZIndex = 1,
				Parent = card,
			})
			table.insert(corners, make("UICorner", { CornerRadius = radius, Parent = fill }))
			make("UIGradient", { Color = colors, Rotation = rotation(cfg.bg_gradient_dir), Parent = fill })
		end
	end

	local bg = make("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Crop,
		ImageTransparency = math.min(if style.glass then 0.6 else 0.85, alpha),
		ZIndex = 2,
		Parent = card,
	})
	table.insert(corners, make("UICorner", { CornerRadius = radius, Parent = bg }))
	local sheen
	if style.glass then
		sheen = make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = white,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = bg,
		})
		table.insert(corners, make("UICorner", { CornerRadius = radius, Parent = sheen }))
		make("UIGradient", {
			Rotation = 25,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(0.35, 0.93),
				NumberSequenceKeypoint.new(0.65, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = sheen,
		})
	end
	local id = self.player.UserId
	local pictured = cfg.bg_type == nil or cfg.bg_type == "image"
	if not pictured or not cfg.image_url or cfg.image_url == "" then
		task.spawn(purge, id, "bg")
	end
	if pictured then
		self:image(bg, cfg.image_url, "bg", strip(cfg, ""))
	end

	local disc = make("Frame", {
		Position = UDim2.fromOffset(gap, (height - dsz) // 2),
		Size = UDim2.fromOffset(dsz, dsz),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = card,
	})
	local discCorner = make("UICorner", { CornerRadius = UDim.new(radii[st.shape], 0), Parent = disc })
	local ringStroke
	if st.ring then
		ringStroke = make("UIStroke", {
			Color = if st.ring.colors then white else st.ring.color,
			Thickness = st.ring.width,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = disc,
		})
		if st.ring.colors then
			make("UIGradient", { Color = st.ring.colors, Rotation = st.ring.rotation, Parent = ringStroke })
		end
	end
	local icon = make("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 4,
		Parent = disc,
	})
	local iconCorner = make("UICorner", { CornerRadius = UDim.new(radii[st.shape], 0), Parent = icon })
	if st.shape == "none" then
		icon:SetAttribute("fit", true)
		icon.ScaleType = Enum.ScaleType.Fit
	end
	local sheet = strip(cfg, "icon_")
	if (cfg.icon_image and cfg.icon_image ~= "") or sheet then
		self:image(icon, cfg.icon_image, "icon", sheet, function()
			self:avatar(icon)
		end)
	else
		task.spawn(purge, id, "icon")
		self:avatar(icon)
	end

	local hidden = st.side == "hidden"
	local custom = st.spots
	local x = if st.side == "left" or custom then dsz + gap + (if kind == "chamfer" then 14 else 10) elseif hidden then 18 else 14
	local inset = if st.side == "right" then dsz + gap + 10 elseif hidden then 18 else 10
	local chip = metrics.chip
	local px = metrics.px
	local rows = metrics.line ~= "" or (chip ~= nil and st.badge.place == "below")
	local y = if rows then (height - (size.title + px + 8)) // 2 else (height - (size.title + 4)) // 2
	local room = width - x - inset
	local inline = chip ~= nil and st.badge.place == "after"
	local titleWidth = if inline then math.max(0, math.min(math.ceil(metrics.title) + 2, room - chip.w - 6)) else nil
	local moving = cfg.text_gradient_anim_enabled == true
	local colors = cfg.text_gradient_enabled == true and sequence(cfg.text_gradient_stops, moving) or nil

	local title = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = if titleWidth then UDim2.fromOffset(titleWidth, size.title + 4) else UDim2.new(1, -(x + inset), 0, size.title + 4),
		Font = font,
		Text = cfg.name_text or "",
		TextSize = size.title,
		TextColor3 = if colors then white else (hex(cfg.name_color) or white),
		TextXAlignment = if hidden then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = card,
	})
	if self.face then
		title.FontFace = self.face
	end
	if colors then
		local angle = rotation(cfg.text_gradient_dir)
		local gradient = make("UIGradient", { Color = colors, Rotation = angle, Parent = title })
		if moving then
			table.insert(self.grads, {
				gradient = gradient,
				vertical = angle == 90 or angle == 270,
				speed = (tonumber(cfg.text_gradient_speed) or 3) * 0.25,
				t = 0,
				text = true,
			})
		end
	end

	local under = chip ~= nil and st.badge.place == "below"
	local lineWidth = if under then math.max(0, math.min(math.ceil(metrics.sub) + 2, room - chip.w - 6)) else nil
	local lineX = x
	if hidden and under then
		local group = (if metrics.line ~= "" then lineWidth + 6 else 0) + chip.w
		lineX = math.max(x, (width - group) // 2)
	end
	local label = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(lineX, y + size.title + 4),
		Size = if lineWidth then UDim2.fromOffset(lineWidth, px + 4) else UDim2.new(1, -(x + inset), 0, px + 4),
		Font = Enum.Font.Gotham,
		Text = metrics.line,
		TextSize = px,
		TextColor3 = st.tint or Color3.fromRGB(215, 215, 222),
		TextTransparency = 1 - st.opacity,
		TextXAlignment = if hidden and not under then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = card,
	})

	local detail
	if kind == "chamfer" and st.side == "left" and st.shape ~= "none" then
		detail = make("Frame", {
			Position = UDim2.fromOffset(dsz + gap + 4, 6),
			Size = UDim2.fromOffset(2, height - 12),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.3,
			ZIndex = 5,
			Parent = card,
		})
	end
	if detail then
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = detail })
	end

	local ring = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = card,
	})
	table.insert(corners, make("UICorner", { CornerRadius = radius, Parent = ring }))
	local spinning = cfg.stroke_gradient_anim_enabled == true
	local edge = cfg.stroke_gradient_enabled == true and sequence(cfg.stroke_gradient_stops, spinning) or nil
	local stroke = make("UIStroke", {
		Color = if edge then white else accent,
		Thickness = if thickness > 0 then thickness else style.thickness,
		Transparency = if thickness > 0 or edge then 0 else style.alpha,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = ring,
	})
	if style.glass and not edge and thickness <= 0 then
		make("UIGradient", {
			Rotation = 45,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.38),
				NumberSequenceKeypoint.new(0.42, 0.84),
				NumberSequenceKeypoint.new(0.62, 0.92),
				NumberSequenceKeypoint.new(1, 0.66),
			}),
			Parent = stroke,
		})
	end
	if edge then
		local angle = rotation(cfg.stroke_gradient_dir)
		local gradient = make("UIGradient", { Color = edge, Rotation = angle, Parent = stroke })
		if spinning then
			table.insert(self.grads, { gradient = gradient, vertical = angle == 90 or angle == 270, speed = 0.75 * st.outline, t = 0 })
		end
	end

	local chips = {}
	if chip then
		local place = st.badge.place
		local spot
		if place == "after" then
			spot = UDim2.fromOffset(x + titleWidth + 6, y + (size.title + 4 - chip.h) // 2 + 1)
		elseif place == "below" then
			spot = UDim2.fromOffset(lineX + (if metrics.line ~= "" then lineWidth + 6 else 0), y + size.title + 4 + (px + 4 - chip.h) // 2 + 1)
		else
			spot = UDim2.new(1, -(10 + chip.w), 0, -(chip.h // 2))
		end
		table.insert(chips, self:chip(st.badge, chip, card, spot, if place == "corner" then 12 else 6))
	else
		task.spawn(purge, id, "badge")
	end

	if st.fx then
		local count = math.min(st.fx.density, swarm.cap - swarm.used)
		if count > 0 then
			swarm.used += count
			self.fxCount = count
			local nodes = {}
			for _ = 1, count do
				table.insert(nodes, make("ImageLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(0, 0),
					ImageColor3 = if st.fx.kind == "custom" then white else st.fx.color,
					ImageTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 2,
					Parent = card,
				}))
			end
			self.particles = { kind = st.fx.kind, speed = st.fx.speed, size = st.fx.size, nodes = nodes }
			local src = if st.fx.kind == "custom" then st.fx.image else origin .. "/tag/fx-" .. (if st.fx.kind == "sparkles" then "sparkle" else "dot") .. ".png"
			local token = self.token
			task.spawn(function()
				local asset = cached(id, "fx", src)
				if not asset and allowed(src) then
					asset = download(src, 64, id, "fx", src)
				end
				if asset and token == self.token then
					for _, node in nodes do
						node.Image = asset
					end
				end
			end)
		end
	else
		task.spawn(purge, id, "fx")
	end

	local discAt = Vector2.new(if st.side == "right" then width - gap - dsz else gap, (height - dsz) // 2)
	if custom then
		local function place(inst, w, h, at)
			local cx = math.clamp(at.x * width, w / 2 + 4, math.max(w / 2 + 4, width - w / 2 - 4))
			local cy = math.clamp(at.y * height, h / 2 + 2, math.max(h / 2 + 2, height - h / 2 - 2))
			local pos = Vector2.new(round(cx - w / 2), round(cy - h / 2))
			if inst then
				inst.Position = UDim2.fromOffset(pos.X, pos.Y)
			end
			return pos
		end
		discAt = place(nil, dsz, dsz, custom.icon)
		local tw = math.min(math.ceil(metrics.title) + 2, width - 8)
		title.Size = UDim2.fromOffset(tw, size.title + 4)
		place(title, tw, size.title + 4, custom.title)
		y = title.Position.Y.Offset
		if metrics.line ~= "" then
			local lw = math.min(math.ceil(metrics.sub) + 2, width - 8)
			label.Size = UDim2.fromOffset(lw, px + 4)
			place(label, lw, px + 4, custom.line)
		end
		if chip and chips[1] then
			place(chips[1].frame, chip.w, chip.h, custom.badge)
		end
	end

	local effect = string.lower(tostring(cfg.text_anim or "none"))
	if cfg.glitch_anim == true and effect == "none" then
		effect = "glitch"
	end
	self.effect = effect
	self.text = cfg.name_text or ""
	self.tinted = colors ~= nil
	self.letters = if effect == "wave" and self.text ~= "" then self:spell(title, cfg, colors, moving) else nil
	self.title = title
	self.label = label
	self.y = y
	self.parts = {
		width = width,
		height = height,
		size = dsz,
		gap = gap,
		side = st.side,
		at = discAt,
		sheen = sheen,
		radius = radii[st.shape],
		style = style,
		disc = disc,
		corners = corners,
		detail = detail,
		discCorner = discCorner,
		iconCorner = iconCorner,
		ring = ringStroke,
		chips = chips,
		dim = 1 - st.opacity,
	}
	self.shrink = if self:distance() > 30 then 1 else 0
	self.goal = self.shrink
	self:layout(self.shrink)
end

function Tag:spell(title, cfg, colors, moving)
	local pad = 4
	local box = make("Frame", {
		BackgroundTransparency = 1,
		Position = title.Position - UDim2.fromOffset(0, pad),
		Size = title.Size + UDim2.fromOffset(0, pad * 2),
		ClipsDescendants = true,
		ZIndex = title.ZIndex,
		Parent = title.Parent,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = if title.TextXAlignment == Enum.TextXAlignment.Center then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 0),
		Parent = box,
	})
	local angle = rotation(cfg.text_gradient_dir)
	local vertical = angle == 90 or angle == 270
	local points = colors and ramp(cfg.text_gradient_stops, moving)
	local glyphs = {}
	local i = 0
	for _, code in utf8.codes(self.text) do
		i += 1
		local cell = make("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, title.Size.Y.Offset),
			LayoutOrder = i,
			ZIndex = title.ZIndex,
			Parent = box,
		})
		local label = make("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			FontFace = title.FontFace,
			Text = utf8.char(code),
			TextSize = title.TextSize,
			TextColor3 = if points then sample(points, 0.5) else title.TextColor3,
			ZIndex = title.ZIndex,
			Parent = cell,
		})
		if points and vertical then
			label.TextColor3 = white
			local gradient = make("UIGradient", { Color = colors, Rotation = angle, Parent = label })
			if moving then
				table.insert(self.grads, { gradient = gradient, vertical = true, speed = (tonumber(cfg.text_gradient_speed) or 3) * 0.25, t = 0 })
			end
		end
		table.insert(glyphs, { cell = cell, label = label })
	end
	title.TextTransparency = 1
	return {
		box = box,
		glyphs = glyphs,
		points = if points and not vertical then points else nil,
		moving = moving,
		reversed = angle > 90 and angle < 270,
		angle = angle,
		speed = (tonumber(cfg.text_gradient_speed) or 3) * 0.25,
		t = 0,
	}
end

function Tag:distance()
	local camera = workspace.CurrentCamera
	local gui = self.gui
	if not (camera and gui and gui.Adornee) then
		return math.huge
	end
	local ok, d = pcall(function()
		return (camera.CFrame.Position - gui.Adornee.Position).Magnitude
	end)
	return if ok then d else math.huge
end

function Tag:layout(t)
	local parts = self.parts
	if not parts or not self.gui then
		return
	end
	local style = parts.style
	self.gui.Size = UDim2.fromOffset(round(lerp(parts.width, parts.height, t)), parts.height)
	local hidden = parts.side == "hidden"
	local d = round(lerp(if hidden then 0 else parts.size, parts.height, t))
	local from = if hidden then parts.width / 2 else parts.at.X
	local fromY = if hidden then parts.height / 2 else parts.at.Y
	parts.disc.Size = UDim2.fromOffset(d, d)
	parts.disc.Position = UDim2.fromOffset(round(lerp(from, 0, t)), round(lerp(fromY, (parts.height - d) / 2, t)))
	parts.disc.Visible = not hidden or d > 1
	local curve = UDim.new(lerp(parts.radius, 0.5, t), 0)
	parts.discCorner.CornerRadius = curve
	parts.iconCorner.CornerRadius = curve
	if parts.ring then
		local start = parts.ring:GetAttribute("base") or 0
		parts.ring.Transparency = start + (1 - start) * math.clamp(t * 2.4, 0, 1)
	end
	if parts.sheen then
		parts.sheen.BackgroundTransparency = math.clamp(t * 2, 0, 1)
	end
	if self.glow and not self.pulse then
		glowTo(self.glow, lerp(self.glowBase or 0.3, 1, math.clamp(t * 1.6, 0, 1)))
	end
	local radius = UDim.new(lerp(style.scale, 0.5, t), round(lerp(style.offset, 0, t)))
	for _, corner in parts.corners do
		corner.CornerRadius = radius
	end
	local fade = math.clamp(t * 2.4, 0, 1)
	local visible = fade < 0.95
	self.fade = fade
	self.title.TextTransparency = if self.letters then 1 else fade
	self.title.Visible = visible
	if self.letters then
		self.letters.box.Visible = visible
		for _, g in self.letters.glyphs do
			g.label.TextTransparency = fade
		end
	end
	self.label.TextTransparency = 1 - (1 - parts.dim) * (1 - fade)
	self.label.Visible = visible
	if parts.detail then
		parts.detail.Visible = visible
	end
	for _, c in parts.chips do
		c.frame.Visible = visible
		for _, f in c.fades do
			f.inst[f.prop] = f.base + (1 - f.base) * fade
		end
	end
	if self.particles then
		for _, node in self.particles.nodes do
			node.Visible = t < 0.05
		end
	end
end

function Tag:step(dt)
	LPS_ATTRIBUTES(VM(NONE))
	dt = math.clamp(dt, 0.0001, 0.1)
	local gui = self.gui
	if not gui or not gui.Parent then
		if self.config and self:head() then
			self:build()
		end
		return
	end

	local shown = enabled()
	if shown ~= self.shown then
		self.shown = shown
		gui.Enabled = shown
	end
	if not shown then
		return
	end

	local head = self:head()
	if not head then
		return
	end
	if gui.Adornee ~= head then
		gui.Adornee = head
	end
	local distance = self:distance()
	if self.goal == 0 and distance > 30 then
		self.goal = 1
	elseif self.goal == 1 and distance < 25 then
		self.goal = 0
	end
	if self.shrink ~= self.goal then
		local gap = self.goal - self.shrink
		self.shrink = if math.abs(gap) > 0.002 then self.shrink + gap * (1 - math.exp(-dt * 10)) else self.goal
		self:layout(self.shrink)
	end

	self.clock += dt
	self.look = (self.look or 0) - dt
	if self.look <= 0 then
		self.look = 0.2
		local ok, seen = pcall(function()
			local camera = workspace.CurrentCamera
			local point = camera:WorldToViewportPoint(head.Position)
			local view = camera.ViewportSize
			return point.Z > 0 and point.X > -260 and point.Y > -260 and point.X < view.X + 260 and point.Y < view.Y + 260
		end)
		self.onScreen = not ok or seen
	end
	for img, anim in self.anims do
		anim.elapsed += dt
		if anim.elapsed >= anim.delay then
			local steps = math.floor(anim.elapsed / anim.delay)
			anim.elapsed -= steps * anim.delay
			anim.frame = (anim.frame + steps) % anim.frames
			img.ImageRectOffset = Vector2.new((anim.frame % anim.cols) * anim.w + anim.pad, (anim.frame // anim.cols) * anim.h + anim.pad)
		end
	end

	if self.onScreen == false then
		return
	end
	local collapsed = self.shrink >= 0.999

	for _, g in self.grads do
		g.t = (g.t + dt * g.speed) % 2
		if not (collapsed and g.text) then
			g.gradient.Offset = if g.vertical then Vector2.new(0, g.t - 1) else Vector2.new(g.t - 1, 0)
		end
	end

	local t = self.clock

	if self.glow and self.pulse and not collapsed then
		local pulse = math.min(1, (self.glowBase or 0.3) + (math.sin(t * 3 * (self.glowSpeed or 1)) * 0.5 + 0.5) * (self.glowDepth or 0.45))
		glowTo(self.glow, lerp(pulse, 1, math.clamp(self.shrink * 1.6, 0, 1)))
	end

	local swarmed = self.particles
	if swarmed and self.shrink < 0.05 then
		for i, node in swarmed.nodes do
			local px, py, sway, size, alpha, scale = particle(swarmed.kind, i - 1, t, swarmed.speed, swarmed.size)
			local side = math.max(0, size * scale)
			node.Position = UDim2.new(px, sway, py, 0)
			node.Size = UDim2.fromOffset(side, side)
			node.ImageTransparency = 1 - math.clamp(alpha, 0, 1)
		end
	end

	local pace, ease = self.pace or 1, self.ease or "smooth"
	local label, effect, text = self.title, self.effect, self.text
	if effect == "none" or effect == "" or collapsed then
		return
	end
	if effect == "glitch" then
		if not self.next or t >= self.next then
			self.next = t + 0.08 / pace
			if math.random() < 0.4 then
				local chars = {}
				for _, code in utf8.codes(text) do
					local char = utf8.char(code)
					if char ~= " " and math.random() < 0.2 then
						char = glyphs[math.random(#glyphs)]
					end
					table.insert(chars, char)
				end
				label.Text = table.concat(chars)
			else
				label.Text = text
			end
		end
	elseif effect == "pulse" then
		local scale = self.scaler
		if not scale or scale.Parent ~= label then
			scale = label:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = label })
			self.scaler = scale
		end
		scale.Scale = 1 + curve(math.sin(t * 5 * pace), ease) * 0.08
	elseif effect == "wave" and self.letters then
		local letters = self.letters
		local phase = t * 5 * pace
		local h = letters.h
		if not h or h <= 0 then
			h = letters.glyphs[1].cell.AbsoluteSize.Y
			letters.h = h
		end
		for i, g in letters.glyphs do
			local dy = curve(math.sin(phase - (i - 1) * 0.55), ease) * 2.5
			g.label.Position = UDim2.fromScale(0, if h > 0 then dy / h else 0)
		end
		local points = letters.points
		local width = self.title.AbsoluteSize.X
		if points and width > 0 then
			local left = self.title.AbsolutePosition.X
			if letters.moving then
				letters.t = (letters.t + dt * letters.speed) % 2
				local shift = letters.t - 1
				if letters.w ~= width and letters.glyphs[#letters.glyphs].label.AbsoluteSize.X > 0 then
					letters.w = width
					for _, g in letters.glyphs do
						local u = (g.label.AbsolutePosition.X + g.label.AbsoluteSize.X / 2 - left) / width
						g.u = if letters.reversed then 1 - u else u
					end
				end
				for _, g in letters.glyphs do
					if g.u then
						g.label.TextColor3 = sample(points, g.u - shift)
					end
				end
			elseif not letters.ready and letters.glyphs[#letters.glyphs].label.AbsoluteSize.X > 0 then
				letters.ready = true
				for _, g in letters.glyphs do
					local u0 = (g.label.AbsolutePosition.X - left) / width
					local u1 = u0 + g.label.AbsoluteSize.X / width
					if letters.reversed then
						u0, u1 = 1 - u1, 1 - u0
					end
					make("UIGradient", { Color = slice(points, u0, u1), Rotation = letters.angle, Parent = g.label })
					g.label.TextColor3 = white
				end
			end
		end
	elseif effect == "bounce" or effect == "wave" then
		label.Position = UDim2.fromOffset(label.Position.X.Offset, self.y + round(curve(math.sin(t * 5 * pace), ease) * 2.5))
	elseif effect == "flicker" then
		label.TextTransparency = math.max(self.fade or 0, if math.random() < math.min(0.5, 0.12 * pace) then 0.6 else 0)
	elseif effect == "rainbow" then
		if not self.tinted then
			label.TextColor3 = Color3.fromHSV((t * 0.25 * pace) % 1, 0.8, 1)
		end
	elseif effect == "typewriter" then
		local length = utf8.len(text) or #text
		if length > 0 then
			local progress = (t * pace) % (length / 6 + 2)
			local count = math.clamp(math.floor(progress * 6), 0, length)
			local cursor = if progress < length / 6 and math.floor(t * 3 * pace) % 2 == 0 then "_" else ""
			local cut = if count >= length then #text else (utf8.offset(text, count + 1) or (#text + 1)) - 1
			label.Text = string.sub(text, 1, cut) .. cursor
		end
	end
end

function Tag:destroy()
	self.dead = true
	self.token += 1
	swarm.used -= self.fxCount or 0
	self.fxCount = 0
	self.beat:Disconnect()
	self.respawn:Disconnect()
	if self.gui then
		self.gui:Destroy()
		self.gui = nil
	end
end

local function listen(handler)
	local connect = WebSocket and WebSocket.connect
	if not connect then
		return function() end
	end
	local alive, current = true, nil
	local place = ""
	task.spawn(function()
		pcall(function()
			place = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
		end)
	end)
	task.spawn(function()
		local failures = 0
		while alive do
			local ok, ws = pcall(connect, socket)
			if ok and ws then
				current, failures = ws, 0
				local closed = false
				pcall(function()
					ws.OnClose:Connect(function()
						closed = true
					end)
				end)
				pcall(function()
					ws.OnMessage:Connect(function(raw)
						local data = decode(raw)
						if type(data) == "table" then
							pcall(handler, data)
						end
					end)
				end)
				local me = Players.LocalPlayer
				pcall(function()
					ws:Send(HttpService:JSONEncode({
						t = "hello",
						id = tostring(me.UserId),
						name = me.Name,
						display = me.DisplayName,
						place = tostring(game.PlaceId),
						job = game.JobId,
						game = place,
						ver = "nametag",
						share = true,
						tag = {},
					}))
				end)
				while alive and not closed do
					task.wait(1)
				end
				current = nil
			else
				failures += 1
			end
			if alive then
				task.wait(math.min(5 * math.max(failures, 1), 30))
			end
		end
	end)
	local function stop()
		alive = false
		if current then
			pcall(current.Close, current)
		end
	end
	local function send(data)
		if current then
			return pcall(current.Send, current, HttpService:JSONEncode(data))
		end
		return false
	end
	return stop, send
end

local ownerids = { [10012699579] = true }

local dragAnim
local function getDragAnimation()
	if dragAnim then
		return dragAnim
	end
	local anim
	local ok, objs = pcall(function()
		return game:GetObjects("rbxassetid://10714360343")
	end)
	if ok and objs and objs[1] then
		local o = objs[1]
		if not o:IsA("Animation") then
			o = o:FindFirstChildOfClass("Animation") or o:FindFirstChildWhichIsA("Animation", true)
		end
		if o and o:IsA("Animation") and o.AnimationId ~= "" and o.AnimationId ~= "rbxassetid://0" then
			anim = o
		end
	end
	if not anim then
		anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://10714360343"
	end
	dragAnim = anim
	return anim
end

local zdelayPart, zdelayBlank
local function zdelayBind(rootPart, target)
	if not rootPart or typeof(sethiddenproperty) ~= "function" then
		return false
	end
	if not zdelayPart then
		zdelayPart = Instance.new("Part")
	end
	if zdelayBlank == nil then
		zdelayBlank = false
		if typeof(gethiddenproperty) == "function" then
			local ok, val = pcall(gethiddenproperty, zdelayPart, "PhysicsRepRootRef")
			if ok and typeof(val) == "InstanceHandle" then
				zdelayBlank = val
			end
		end
	end
	if zdelayBlank then
		local handle = zdelayBlank
		if target then
			local ok, h = pcall(function()
				zdelayPart:SetAttribute("r", target)
				return zdelayPart:GetAttribute("r")
			end)
			handle = if ok and typeof(h) == "InstanceHandle" then h else nil
		end
		if handle and pcall(sethiddenproperty, rootPart, "PhysicsRepRootRef", handle) then
			return true
		end
	end
	return (pcall(sethiddenproperty, rootPart, "PhysicsRepRootPart", target))
end

local dragState = {
	target = nil,
	token = 0,
	conns = {},
	collide = {},
	track = nil,
	trackChar = nil,
}

local function dragStop()
	dragState.token += 1
	dragState.target = nil
	for _, conn in dragState.conns do
		pcall(conn.Disconnect, conn)
	end
	table.clear(dragState.conns)
	if dragState.track then
		pcall(function()
			dragState.track:Stop()
			dragState.track:Destroy()
		end)
		dragState.track = nil
	end
	dragState.trackChar = nil
	for part, saved in dragState.collide do
		pcall(function()
			if part.Parent then
				part.CanCollide = if part.Name == "HumanoidRootPart" then false else saved[1]
				part.CanQuery = saved[2]
				part.CanTouch = saved[3]
			end
		end)
	end
	table.clear(dragState.collide)
	local me = Players.LocalPlayer
	local char = me and me.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local mine = char and char:FindFirstChild("HumanoidRootPart")
	if mine then
		zdelayBind(mine, nil)
		mine.AssemblyLinearVelocity = Vector3.zero
		mine.AssemblyAngularVelocity = Vector3.zero
	end
	if hum then
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			hum.PlatformStand = false
			hum.AutoRotate = true
			hum.Sit = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end

local function dragBody(char)
	if not char then
		return
	end
	for _, part in char:GetDescendants() do
		if part:IsA("BasePart") then
			if not dragState.collide[part] then
				dragState.collide[part] = { part.CanCollide, part.CanQuery, part.CanTouch }
			end
			pcall(function()
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
			end)
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			hum.PlatformStand = false
			hum.AutoRotate = false
			hum.Jump = false
			if hum.SeatPart then
				hum.Sit = false
			elseif not hum.Sit then
				hum.Sit = true
				hum:ChangeState(Enum.HumanoidStateType.Seated)
			end
		end)
	end
end

local function dragPose(token)
	if dragState.token ~= token then
		return
	end
	local me = Players.LocalPlayer
	local char = me and me.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	pcall(function()
		if dragState.track then
			dragState.track:Stop()
			dragState.track:Destroy()
			dragState.track = nil
		end
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = hum
		end
		local tr = animator:LoadAnimation(getDragAnimation())
		tr.Priority = Enum.AnimationPriority.Action4
		tr.Looped = true
		tr:Play(0.1, 100, 0)
		dragState.track = tr
		dragState.trackChar = char
		task.spawn(function()
			local waited = 0
			while tr.Length == 0 and waited < 5 and dragState.track == tr and dragState.token == token do
				waited += task.wait()
			end
			if dragState.track == tr and dragState.token == token then
				tr.TimePosition = 0.5
			end
		end)
	end)
end

local function dragStart(target)
	local me = Players.LocalPlayer
	if not target or not target.Parent or target == me then
		return
	end
	dragStop()
	dragState.token += 1
	local token = dragState.token
	dragState.target = target

	local function mineRoot()
		local c = me.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local function theirRoot()
		local c = target.Character
		return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head"))
	end

	local function place()
		local tc = target.Character
		local troot = tc and tc:FindFirstChild("HumanoidRootPart")
		if not troot then
			return nil
		end
		local arm = tc:FindFirstChild("RightHand") or tc:FindFirstChild("Right Arm") or troot
		return arm.CFrame * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
	end

	local function apply()
		if dragState.token ~= token then
			return false
		end
		if not target.Parent then
			dragStop()
			return false
		end
		local char = me.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local mine = char and char:FindFirstChild("HumanoidRootPart")
		if not (hum and hum.Health > 0) then
			return false
		end
		local cf = place()
		if mine and cf then
			mine.CFrame = cf
			mine.AssemblyLinearVelocity = Vector3.zero
			mine.AssemblyAngularVelocity = Vector3.zero
		end
		if hum.PlatformStand then
			hum.PlatformStand = false
		end
		if hum.AutoRotate then
			hum.AutoRotate = false
		end
		if hum.Jump then
			hum.Jump = false
		end
		if hum.SeatPart then
			hum.Sit = false
		elseif hum.Sit ~= true then
			hum.Sit = true
			hum:ChangeState(Enum.HumanoidStateType.Seated)
		end
		return true
	end

	table.insert(dragState.conns, RunService.Heartbeat:Connect(function()
		if not apply() then
			return
		end
		local mine, theirs = mineRoot(), theirRoot()
		if mine and mine.Parent and theirs then
			zdelayBind(mine, theirs)
		end
	end))
	table.insert(dragState.conns, RunService.PreSimulation:Connect(apply))
	table.insert(dragState.conns, RunService.RenderStepped:Connect(apply))
	table.insert(dragState.conns, me.CharacterAdded:Connect(function(char)
		if dragState.token ~= token then
			return
		end
		table.clear(dragState.collide)
		dragState.track = nil
		dragState.trackChar = nil
		task.spawn(function()
			char:WaitForChild("HumanoidRootPart", 10)
			char:WaitForChild("Humanoid", 10)
			if dragState.token ~= token or me.Character ~= char then
				return
			end
			dragBody(char)
			dragPose(token)
			task.wait(0.6)
			if dragState.token ~= token or me.Character ~= char then
				return
			end
			dragBody(char)
			dragPose(token)
		end)
	end))

	dragBody(me.Character)
	dragPose(token)

	task.spawn(function()
		while dragState.token == token do
			task.wait(0.5)
			if dragState.token ~= token then
				break
			end
			if not target.Parent then
				dragStop()
				break
			end
			local char = me.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if char and hum and hum.Health > 0 then
				dragBody(char)
				if not dragState.track or not dragState.track.IsPlaying or dragState.trackChar ~= char then
					dragPose(token)
				end
			end
		end
	end)
end

local frights = { "9565121852", "13812091235", "5182578556", "99181901800612", "13193479764", "12527364300", "136342594291398", "10970697149", "121616559982446" }
local screams = { "5710016194", "161964303", "126552929107766", "84131007103998", "123124825019861", "81987511375108" }

local function body()
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
end

local function sound(id, volume)
	local s = make("Sound", { SoundId = "rbxassetid://" .. id, Volume = volume, Parent = SoundService })
	s:Play()
	Debris:AddItem(s, 12)
end

local function screen()
	return make("ScreenGui", { IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1000000, Parent = holder() })
end

local function overlay(image, audio, volume, hold)
	local gui = screen()
	local picture = make("ImageLabel", {
		Image = "rbxassetid://" .. image,
		ScaleType = Enum.ScaleType.Fit,
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	sound(audio, volume)
	task.delay(hold, function()
		TweenService:Create(picture, TweenInfo.new(0.4), { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.4)
		gui:Destroy()
	end)
	return picture
end

local hazed, calm = 0, nil

local function haze(strength, duration, colors)
	hazed += 1
	local token = hazed
	calm = calm or workspace.CurrentCamera.FieldOfView
	local blur = make("BlurEffect", { Size = 0, Parent = Lighting })
	local tint = if colors then make("ColorCorrectionEffect", { Saturation = 0.6, Parent = Lighting }) else nil
	local start = os.clock()
	RunService:UnbindFromRenderStep("lumenhaze")
	RunService:BindToRenderStep("lumenhaze", Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - start
		local fade = math.clamp(math.min(t, duration - t), 0, 1) * strength
		local camera = workspace.CurrentCamera
		camera.CFrame *= CFrame.Angles(math.sin(t * 1.3) * 0.03 * fade, math.sin(t * 0.8) * 0.05 * fade, math.sin(t * 1.1) * 0.1 * fade)
		camera.FieldOfView = calm + math.sin(t * 2.2) * 7 * fade
		blur.Size = 5 * fade
		if tint then
			tint.TintColor = Color3.fromHSV(t * 0.2 % 1, 0.35 * fade, 1)
		end
	end)
	task.delay(duration, function()
		blur:Destroy()
		if tint then
			tint:Destroy()
		end
		if hazed == token then
			RunService:UnbindFromRenderStep("lumenhaze")
			workspace.CurrentCamera.FieldOfView = calm
			calm = nil
		end
	end)
end

local function sober()
	hazed += 1
	RunService:UnbindFromRenderStep("lumenhaze")
	if calm then
		workspace.CurrentCamera.FieldOfView = calm
		calm = nil
	end
end

local poses = {
	RightShoulder = CFrame.Angles(0, 0, math.pi / 2),
	LeftShoulder = CFrame.Angles(0, 0, -math.pi / 2),
	["Right Shoulder"] = CFrame.Angles(-math.pi / 2, 0, 0),
	["Left Shoulder"] = CFrame.Angles(-math.pi / 2, 0, 0),
	RightElbow = CFrame.identity,
	LeftElbow = CFrame.identity,
}

local function limp(char, on)
	local animate = char:FindFirstChild("Animate")
	if animate then
		animate.Disabled = on
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	hum.PlatformStand = on
	if not on then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		return
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
end

local function pin(player, place, spread)
	local own = player == Players.LocalPlayer
	local rig, motors = nil, {}
	local function step()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		if rig ~= char then
			rig = char
			table.clear(motors)
			if own then
				limp(char, true)
			end
		end
		if spread and next(motors) == nil then
			for name, pose in poses do
				local motor = char:FindFirstChild(name, true)
				if motor and motor:IsA("Motor6D") then
					motors[motor] = pose
				end
			end
		end
		for motor, pose in motors do
			motor.Transform = pose
		end
		if own then
			root.CFrame = place()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
	local conns = { RunService.Stepped:Connect(step), RunService.Heartbeat:Connect(step) }
	return function()
		for _, conn in conns do
			conn:Disconnect()
		end
		for motor in motors do
			motor.Transform = CFrame.identity
		end
		if own and player.Character then
			limp(player.Character, false)
		end
	end
end

local function wood(model, size, cf)
	return make("Part", {
		Size = size,
		CFrame = cf,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(86, 54, 30),
		Parent = model,
	})
end

local function ground(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -60, 0), params)
	local look = root.CFrame.LookVector
	local y = if hit then hit.Position.Y else root.Position.Y - 3
	return string.format("%.2f %.2f %.2f %.3f", root.Position.X, y, root.Position.Z, math.atan2(-look.X, -look.Z))
end

local function site(arg)
	local x, y, z, yaw = string.match(arg or "", "^(%S+) (%S+) (%S+) (%S+)$")
	x, y, z, yaw = tonumber(x), tonumber(y), tonumber(z), tonumber(yaw)
	return if x and y and z and yaw then CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0) else nil
end

local scenes = {}

function scenes.crucify(player, arg)
	local base = site(arg)
	if not base then
		return nil
	end
	local model = make("Model", { Name = "LumenCross" })
	local foot = wood(model, Vector3.new(3.5, 0.6, 3.5), base * CFrame.new(0, 0.3, 0))
	local post = wood(model, Vector3.new(1.2, 11, 1.2), base * CFrame.new(0, 6.1, 0))
	wood(model, Vector3.new(7.5, 1.2, 1.2), base * CFrame.new(0, 8.6, 0))
	make("Fire", { Size = 8, Heat = 6, Parent = foot })
	make("PointLight", { Color = Color3.fromRGB(255, 130, 40), Range = 20, Brightness = 2, Parent = post })
	model.Parent = workspace
	local place = base * CFrame.new(0, 7.8, -1.1)
	local undo = pin(player, function()
		return place
	end, true)
	return function()
		undo()
		model:Destroy()
	end
end

function scenes.hang(player, arg)
	local base = site(arg)
	if not base then
		return nil
	end
	local model = make("Model", { Name = "LumenGallows" })
	wood(model, Vector3.new(1, 12, 1), base * CFrame.new(-3, 6, 0))
	wood(model, Vector3.new(1, 12, 1), base * CFrame.new(3, 6, 0))
	wood(model, Vector3.new(7, 1, 1), base * CFrame.new(0, 12.5, 0))
	local rope = wood(model, Vector3.new(0.25, 3, 0.25), base * CFrame.new(0, 10.5, 0))
	rope.Material = Enum.Material.Fabric
	rope.Color = Color3.fromRGB(176, 156, 118)
	model.Parent = workspace
	local start = os.clock()
	local undo = pin(player, function()
		local swing = math.sin((os.clock() - start) * 1.4) * 0.06
		return base * CFrame.new(0, 12, 0) * CFrame.Angles(swing, 0, swing * 0.5) * CFrame.new(0, -5.1, 0)
	end, false)
	return function()
		undo()
		model:Destroy()
	end
end

local function cell(player, arg, color, material)
	local base = site(arg)
	if not base then
		return nil
	end
	local model = make("Model", { Name = "LumenCell" })
	local function bar(size, cf)
		make("Part", {
			Size = size,
			CFrame = base * cf,
			Anchored = true,
			CanQuery = false,
			CanTouch = false,
			Material = material,
			Color = color,
			Parent = model,
		})
	end
	bar(Vector3.new(8, 0.4, 8), CFrame.new(0, 0.2, 0))
	bar(Vector3.new(8, 0.4, 8), CFrame.new(0, 9.2, 0))
	for i = -3.5, 3.5 do
		bar(Vector3.new(0.25, 9, 0.25), CFrame.new(i, 4.6, -3.9))
		bar(Vector3.new(0.25, 9, 0.25), CFrame.new(i, 4.6, 3.9))
		bar(Vector3.new(0.25, 9, 0.25), CFrame.new(-3.9, 4.6, i))
		bar(Vector3.new(0.25, 9, 0.25), CFrame.new(3.9, 4.6, i))
	end
	model.Parent = workspace
	if player == Players.LocalPlayer then
		local _, root = body()
		if root then
			root.CFrame = base * CFrame.new(0, 3, 0)
		end
	end
	return model
end

local fonts = {
	Gotham = Enum.Font.GothamBlack,
	Fredoka = Enum.Font.FredokaOne,
	Bangers = Enum.Font.Bangers,
	Marker = Enum.Font.PermanentMarker,
	Arcade = Enum.Font.Arcade,
	Creepster = Enum.Font.Creepster,
}
local scales = { Small = 0.75, Medium = 1, Large = 1.4 }

local function label(player, spec)
	local scale = scales[spec.s] or 1
	local color = Color3.fromHex(if type(spec.c) == "string" and string.match(spec.c, "^#?%x%x%x%x%x%x$") then spec.c else "ffffff")
	local style = spec.b or "Plain"
	local gui = make("BillboardGui", {
		Name = "LumenSign",
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 45,
		ResetOnSpawn = false,
		Size = UDim2.fromOffset(math.round(300 * scale), math.round(64 * scale)),
		StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0),
		Parent = holder(),
	})
	local card = make("CanvasGroup", {
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundTransparency = if style == "Card" then 0.25 else 1,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	if style == "Card" then
		make("UICorner", { CornerRadius = UDim.new(0, math.round(14 * scale)), Parent = card })
		make("UIStroke", { Color = color, Transparency = 0.5, Thickness = 1.5, Parent = card })
	end
	local words = make("TextLabel", {
		Text = spec.t,
		Font = fonts[spec.f] or Enum.Font.GothamBlack,
		TextScaled = true,
		TextWrapped = true,
		TextColor3 = color,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.05, 0.1),
		Size = UDim2.fromScale(0.9, 0.8),
		Parent = card,
	})
	make("UIStroke", {
		Color = if style == "Glow" then color else Color3.new(),
		Thickness = if style == "Glow" then 3 else 1.5,
		Transparency = if style == "Glow" then 0.55 else 0.3,
		Parent = words,
	})
	local function follow(char)
		gui.Adornee = char:WaitForChild("Head", 10)
	end
	local conns = {
		player.CharacterAdded:Connect(follow),
		RunService.RenderStepped:Connect(function()
			local head = gui.Adornee
			if head then
				local far = (workspace.CurrentCamera.CFrame.Position - head.Position).Magnitude
				card.GroupTransparency = math.clamp((far - 30) / 15, 0, 1)
			end
		end),
	}
	if player.Character then
		task.spawn(follow, player.Character)
	end
	return function()
		for _, conn in conns do
			conn:Disconnect()
		end
		gui:Destroy()
	end
end

function scenes.cage(player, arg)
	local model = cell(player, arg, Color3.fromRGB(120, 200, 255), Enum.Material.Neon)
	return model and function()
		model:Destroy()
	end
end

function scenes.jail(player, arg)
	local model = cell(player, arg, Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
	if not model then
		return nil
	end
	local unlabel = label(player, { t = "JAILED", c = "ff5050", f = "Gotham", s = "Medium", b = "Card" })
	return function()
		unlabel()
		model:Destroy()
	end
end

function scenes.sign(player, arg)
	local spec = decode(arg or "")
	if type(spec) ~= "table" then
		spec = { t = arg }
	end
	if type(spec.t) ~= "string" or spec.t == "" then
		return nil
	end
	return label(player, spec)
end

function scenes.smite(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local model = make("Model", { Name = "LumenBolt" })
	local from = root.Position + Vector3.new(math.random(-4, 4), 120, math.random(-4, 4))
	local last
	for i = 1, 8 do
		local to = from + (root.Position - from) / (9 - i)
		if i < 8 then
			to += Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
		end
		local length = (to - from).Magnitude
		last = make("Part", {
			Size = Vector3.new(0.6, 0.6, length),
			CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2),
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(190, 220, 255),
			Parent = model,
		})
		from = to
	end
	make("PointLight", { Brightness = 8, Range = 40, Color = Color3.fromRGB(190, 220, 255), Parent = last })
	model.Parent = workspace
	for _, part in model:GetChildren() do
		TweenService:Create(part, TweenInfo.new(0.6), { Transparency = 1 }):Play()
	end
	Debris:AddItem(model, 0.7)
	if player == Players.LocalPlayer then
		local hum = body()
		if hum then
			hum.Health = 0
		end
	end
	return nil
end

local placed = { crucify = true, hang = true, cage = true, jail = true }
local held = {}

local function release(id, kind)
	local slot = held[id]
	local entry = slot and slot[kind]
	if entry then
		slot[kind] = nil
		if entry.undo then
			pcall(entry.undo)
		end
	end
end

local function clear(id)
	for kind in held[id] or {} do
		release(id, kind)
	end
	held[id] = nil
end

local function stage(player, kind, arg)
	local id = player.UserId
	local slot = held[id]
	if arg ~= "off" and slot and slot[kind] and slot[kind].arg == arg then
		return
	end
	release(id, kind)
	if arg == "off" then
		return
	end
	slot = held[id] or {}
	held[id] = slot
	local entry = { arg = arg }
	slot[kind] = entry
	local ok, undo = pcall(scenes[kind], player, arg)
	undo = if ok then undo else nil
	if slot[kind] ~= entry then
		if undo then
			pcall(undo)
		end
	elseif undo then
		entry.undo = undo
	else
		slot[kind] = nil
	end
end

local looped
local commands = {}

function commands.kill()
	local hum = body()
	if hum then
		hum.Health = 0
	end
end

function commands.sit()
	local hum = body()
	if hum then
		hum.Sit = true
	end
end

function commands.jump()
	local hum = body()
	if hum then
		hum.Sit = false
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

function commands.bring(from)
	local _, root = body()
	local char = from.Character
	local them = char and char:FindFirstChild("HumanoidRootPart")
	if root and them then
		root.CFrame = them.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0)
	end
end

function commands.freeze(_, arg)
	local _, root = body()
	if root then
		root.Anchored = arg ~= "off"
	end
end

function commands.stun(_, arg)
	local hum = body()
	if hum then
		hum.PlatformStand = arg ~= "off"
	end
end

function commands.fling()
	local _, root = body()
	if not root then
		return
	end
	local angle = math.random() * math.pi * 2
	local anchor = make("Attachment", { Parent = root })
	make("LinearVelocity", {
		Attachment0 = anchor,
		MaxForce = math.huge,
		RelativeTo = Enum.ActuatorRelativeTo.World,
		VectorVelocity = Vector3.new(math.cos(angle) * 140, 150, math.sin(angle) * 140),
		Parent = anchor,
	})
	root.AssemblyAngularVelocity = Vector3.new(math.random(-30, 30), math.random(-30, 30), math.random(-30, 30))
	Debris:AddItem(anchor, 0.25)
end

function commands.trip()
	local hum, root = body()
	if not (hum and root) then
		return
	end
	local ahead = root.CFrame.LookVector
	hum.PlatformStand = true
	root.CFrame *= CFrame.Angles(-math.pi / 2, 0, 0)
	root.AssemblyLinearVelocity = ahead * 14 + Vector3.new(0, 6, 0)
	task.delay(2, function()
		if hum.Parent then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

function commands.loopkill(_, arg)
	if looped then
		looped:Disconnect()
		looped = nil
	end
	if arg == "off" then
		return
	end
	looped = Players.LocalPlayer.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.Health = 0
		end
	end)
	commands.kill()
end

function commands.flashbang()
	local picture = overlay("11088883735", "129172304986568", 10, 4)
	task.delay(1, function()
		picture.Image = ""
		picture.BackgroundColor3 = white
		picture.BackgroundTransparency = 0
		TweenService:Create(picture, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	end)
end

function commands.jumpscare()
	local picture = overlay(frights[math.random(#frights)], screams[math.random(#screams)], 10, 2.5)
	picture.ScaleType = Enum.ScaleType.Stretch
end

function commands.panini()
	overlay("106404414030833", "6770036737", 1, 1.8).BackgroundTransparency = 0
end

function commands.drunk()
	haze(1, 15, false)
end

function commands.high()
	haze(1.6, 20, true)
end

function commands.drag(from, arg)
	if arg == "off" then
		if dragState.target == from then
			dragStop()
		end
	elseif dragState.target ~= from then
		dragStart(from)
	end
end

function commands.kick(_, reason)
	Players.LocalPlayer:Kick(reason or "")
end

function commands.chat(_, text)
	if not text or text == "" then
		return
	end
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general then
			general:SendAsync(text)
		end
	else
		local remote = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
		if remote then
			remote:FireServer(text, "All")
		end
	end
end

local blurred

function commands.blur(_, arg)
	if blurred then
		blurred:Destroy()
		blurred = nil
	end
	local size = tonumber(arg)
	if size and size > 0 then
		blurred = make("BlurEffect", { Size = math.clamp(size, 1, 56), Parent = Lighting })
	end
end

function commands.whisper()
	local part = make("Part", {
		Size = Vector3.one,
		CFrame = workspace.CurrentCamera.CFrame * CFrame.new(math.random(-3, 3), 0, 4),
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Parent = workspace,
	})
	make("Sound", { SoundId = "rbxassetid://157636218", Volume = 4, RollOffMinDistance = 2, RollOffMaxDistance = 40, Parent = part }):Play()
	Debris:AddItem(part, 12)
end

function commands.fakekick(_, reason)
	local _, root = body()
	local was = root and root.Anchored
	if root then
		root.Anchored = true
	end
	local gui = screen()
	local blur = make("BlurEffect", { Size = 0, Parent = Lighting })
	local shade = make("Frame", { BackgroundColor3 = Color3.new(), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui })
	local card = make("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 226),
		BackgroundColor3 = Color3.fromRGB(57, 59, 61),
		GroupTransparency = 1,
		Parent = gui,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
	make("UIScale", { Scale = math.clamp(workspace.CurrentCamera.ViewportSize.Y / 720, 0.7, 1.4), Parent = card })
	make("TextLabel", {
		Text = "Disconnected",
		FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
		TextSize = 24,
		TextColor3 = white,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = card,
	})
	make("Frame", { BorderSizePixel = 0, BackgroundColor3 = white, BackgroundTransparency = 0.8, Position = UDim2.fromOffset(20, 60), Size = UDim2.new(1, -40, 0, 1), Parent = card })
	make("TextLabel", {
		Text = "You were kicked from this experience: " .. (reason or "You have been banned for exploiting.") .. "\n(Error Code: 267)",
		FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
		TextSize = 17,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(213, 213, 214),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 72),
		Size = UDim2.new(1, -40, 0, 76),
		Parent = card,
	})
	local leave = make("TextButton", {
		Text = "Leave",
		FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
		TextSize = 18,
		TextColor3 = Color3.fromRGB(57, 59, 61),
		AutoButtonColor = false,
		BackgroundColor3 = white,
		Position = UDim2.new(0, 20, 1, -56),
		Size = UDim2.new(1, -40, 0, 36),
		Parent = card,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = leave })
	local fade = TweenInfo.new(0.25)
	TweenService:Create(blur, fade, { Size = 24 }):Play()
	TweenService:Create(shade, fade, { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(card, fade, { GroupTransparency = 0 }):Play()
	leave.MouseEnter:Connect(function()
		leave.BackgroundColor3 = Color3.fromRGB(220, 220, 222)
	end)
	leave.MouseLeave:Connect(function()
		leave.BackgroundColor3 = white
	end)
	local function close()
		if not gui.Parent then
			return
		end
		gui:Destroy()
		blur:Destroy()
		if root then
			root.Anchored = was
		end
	end
	leave.MouseButton1Click:Connect(close)
	task.delay(10, close)
end

function commands.bluescreen()
	local gui = screen()
	local back = make("Frame", { BackgroundColor3 = Color3.fromRGB(0, 120, 215), Size = UDim2.fromScale(1, 1), Parent = gui })
	local function line(text, size, y)
		return make("TextLabel", {
			Text = text,
			Font = Enum.Font.Arial,
			TextSize = size,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = white,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.12, y),
			Size = UDim2.new(0.76, 0, 0, size * 3),
			Parent = back,
		})
	end
	line(":(", 120, 0.16)
	line("Your PC ran into a problem and needs to restart. We're just collecting some error info, and then we'll restart for you.", 26, 0.42)
	local progress = line("0% complete", 26, 0.58)
	for i = 0, 100, 4 do
		progress.Text = i .. "% complete"
		task.wait(0.2)
	end
	gui:Destroy()
end

local function start()
	local tags = {}
	local lumen = {}
	local me = Players.LocalPlayer

	local function add(player)
		if not tags[player] then
			tags[player] = Tag.new(player, player == me or lumen[tostring(player.UserId)] == true)
		end
	end

	local function mark(id, on)
		id = tostring(id or "")
		if id == "" then
			return
		end
		lumen[id] = on or nil
		for player, tag in tags do
			if player ~= me and tostring(player.UserId) == id then
				tag:toggle(on)
			end
		end
	end

	for _, player in Players:GetPlayers() do
		add(player)
	end

	local peers = {}
	local owner = { users = peers, me = ownerids[me.UserId] == true }

	local function changed()
		if owner.changed then
			pcall(owner.changed)
		end
	end

	local stop, send = listen(function(msg)
		if msg.t == "welcome" and type(msg.peers) == "table" then
			table.clear(peers)
			for _, peer in msg.peers do
				peers[tostring(peer.id)] = peer
				mark(peer.id, true)
			end
			changed()
		elseif msg.t == "join" and type(msg.peer) == "table" then
			peers[tostring(msg.peer.id)] = msg.peer
			mark(msg.peer.id, true)
			changed()
			if owner.me then
				for id, slot in held do
					for kind, entry in slot do
						send({ t = "cmd", cmd = kind, id = tostring(id), arg = entry.arg, all = true })
					end
				end
			end
		elseif msg.t == "leave" then
			peers[tostring(msg.id)] = nil
			mark(msg.id, false)
			changed()
		elseif msg.t == "cmd" then
			local from = tonumber(msg.from)
			local caller = from and ownerids[from] and Players:GetPlayerByUserId(from)
			local arg = if type(msg.arg) == "string" then msg.arg else nil
			if caller and scenes[msg.cmd] then
				local target = Players:GetPlayerByUserId(tonumber(msg.id) or 0)
				if target then
					task.spawn(stage, target, msg.cmd, arg)
				end
			elseif caller and commands[msg.cmd] then
				task.spawn(pcall, commands[msg.cmd], caller, arg)
			end
		elseif msg.t == "kick" then
			me:Kick(type(msg.reason) == "string" and msg.reason ~= "" and msg.reason or "Kicked")
		elseif msg.t == "nametag" then
			local id = msg.id and tostring(msg.id)
			local name = type(msg.username) == "string" and string.lower(msg.username)
			for player, tag in tags do
				if (id and tostring(player.UserId) == id) or (name and string.lower(player.Name) == name) then
					if type(msg.tag) == "table" then
						tag.own = msg.tag
						tag:apply(msg.tag)
					else
						tag:clear()
					end
				end
			end
		end
	end)

	function owner.send(cmd, id, arg)
		if not owner.me then
			return false
		end
		if not scenes[cmd] then
			return send({ t = "cmd", cmd = cmd, id = tostring(id), arg = arg })
		end
		local target = Players:GetPlayerByUserId(tonumber(id) or 0)
		if not target then
			return false
		end
		if arg == nil and placed[cmd] then
			arg = ground(target)
			if not arg then
				return false
			end
		end
		task.spawn(stage, target, cmd, arg)
		return send({ t = "cmd", cmd = cmd, id = tostring(id), arg = arg, all = true })
	end
	_G.LumenOwner = owner

	local joined = Players.PlayerAdded:Connect(add)
	local left = Players.PlayerRemoving:Connect(function(player)
		clear(player.UserId)
		if tags[player] then
			tags[player]:destroy()
			tags[player] = nil
		end
	end)

	return function()
		stop()
		dragStop()
		sober()
		commands.blur()
		if looped then
			looped:Disconnect()
			looped = nil
		end
		for id in held do
			clear(id)
		end
		_G.LumenOwner = nil
		joined:Disconnect()
		left:Disconnect()
		for _, tag in tags do
			tag:destroy()
		end
		table.clear(tags)
	end
end

if env.LumenNametagStop then
	pcall(env.LumenNametagStop)
end
env.LumenNametagStop = start()

return Tag
