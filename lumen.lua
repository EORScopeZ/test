local bckend = "https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/"
local lumen = "main.lua"


local scripts = {
    [13772394625] = "bb.lua", -- bladeball
}

local current = game.PlaceId
local scriptid = scripts[current]

if scriptid then

    loadstring(game:HttpGet(bckend .. scriptid))()
else

    loadstring(game:HttpGet(bckend .. lumen))()
end
