local L=game:GetService("Lighting")
local W=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local R=request or http_request or syn.request
local G=getcustomasset or getsynasset

local S=L:FindFirstChildOfClass("Sky") or Instance.new("Sky",L)
local F={"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}
local O={}
for _,p in ipairs(F) do O[p]=S[p] end

local U={
"https://i.postimg.cc/zf9Qy9SL/image.png",
"https://i.postimg.cc/hvn3rT5b/image.png",
"https://i.postimg.cc/dQRf0NhN/image.png"
}

local A={}
for i,u in ipairs(U) do
    local f="lap"..i..".png"
    if not isfile(f) then writefile(f,R({Url=u,Method="GET"}).Body) end
    A[i]=G(f)
end

local af="lapeace.mp3"
if not isfile(af) then
    writefile(af,R({Url="https://raw.githubusercontent.com/EORScopeZ/test/refs/heads/main/lapeace.mp3",Method="GET"}).Body)
end

local Z=Instance.new("Sound",game:GetService("SoundService"))
Z.Name="LaPeaceAudio"
Z.SoundId=G(af)
Z.Volume=1
Z.Looped=true

local CC=Instance.new("ColorCorrectionEffect",L)
local B=Instance.new("BloomEffect",L)
local SR=Instance.new("SunRaysEffect",L)

CC.Name="LaPeaceCC"
B.Name="LaPeaceBloom"
SR.Name="LaPeaceRays"

local P={
{.04,.12,.20,Color3.fromRGB(255,225,180),.28,24,.70,.06,.75},
{0,.04,-.04,Color3.fromRGB(238,225,210),.07,14,.95,.015,.60},
{-.01,.10,.12,Color3.fromRGB(255,205,150),.20,20,.80,.045,.70}
}

local T={
4.667,9.056,13.351,17.694,22.059,26.494,30.766,35.178,39.636,44.025,
48.321,52.756,57.144,61.463,65.875,70.147,74.629,78.994,83.313,87.679,
92.021,96.432,100.728,105.094,109.598,113.987,118.259,122.648,127.083,
131.402,135.697,140.086,144.567,148.933,153.252,157.640,162.075,166.394,
170.667,175.102,179.537,183.925,188.221,192.586,197.045,201.363,205.636,
210.048,214.506,218.895,223.190,227.556,232.014,236.333,240.628
}

local BP={}
local function scan()
    table.clear(BP)
    local seen={}
    for _,v in ipairs(W:GetDescendants()) do
        if v.Name:lower():find("baseplate",1,true) then
            if v:IsA("BasePart") then
                if not seen[v] then
                    seen[v]=true
                    BP[#BP+1]={v,v.LocalTransparencyModifier}
                end
            else
                for _,x in ipairs(v:GetDescendants()) do
                    if x:IsA("BasePart") and not seen[x] then
                        seen[x]=true
                        BP[#BP+1]={x,x.LocalTransparencyModifier}
                    end
                end
            end
        end
    end
end

local function hideBP()
    scan()
    for _,v in ipairs(BP) do
        if v[1] and v[1].Parent then
            v[1].LocalTransparencyModifier=1
        end
    end
end

local function restoreBP()
    for _,v in ipairs(BP) do
        if v[1] and v[1].Parent then
            v[1].LocalTransparencyModifier=v[2]
        end
    end
    table.clear(BP)
end

local on=false
local n=1
local k=1

local function set(i)
    for _,p in ipairs(F) do S[p]=A[i] end
    local x=P[i]
    CC.Brightness=x[1]
    CC.Contrast=x[2]
    CC.Saturation=x[3]
    CC.TintColor=x[4]
    B.Intensity=x[5]
    B.Size=x[6]
    B.Threshold=x[7]
    SR.Intensity=x[8]
    SR.Spread=x[9]
end

local function off()
    on=false
    Z:Stop()
    for _,p in ipairs(F) do S[p]=O[p] end
    CC.Enabled=false
    B.Enabled=false
    SR.Enabled=false
    restoreBP()
    n=1
    k=1
end

UIS.InputBegan:Connect(function(i,g)
    if g or i.KeyCode~=Enum.KeyCode.L then return end
    on=not on

    if not on then
        off()
        return
    end

    hideBP()
    n=1
    k=1
    Z.TimePosition=0
    Z:Play()
    CC.Enabled=true
    B.Enabled=true
    SR.Enabled=true
    set(1)
end)

RS.RenderStepped:Connect(function()
    if not on then return end
    local t=Z.TimePosition
    while k<=#T and t>=T[k] do
        n=n%#A+1
        k=k+1
        set(n)
    end
end)
