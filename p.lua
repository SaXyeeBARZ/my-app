--!nocheck
--[[
    YVONE HUB | BLACK EDITION
    Drawn icons (no emoji) / Auto Farm panel / Bottom nav
    For your own Roblox experience.
]]

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==============================================================
-- MAP DETECTION (unsupported maps are kicked)
--==============================================================

local OPAH_IDS = {
    [101051454784523] = true,
    [91246277860636] = true,
}

-- Atok 1 (drawer map)
local ATOK_IDS = {
    [104798140293332] = true,
    [88236825351515] = true,
}

-- Atok 2 (tape / pita map)
local ATOK_TAPE_IDS = {
    [118060380845440] = true,
}

local function MatchId(set)
    local placeId = tostring(game.PlaceId)
    local gameId = tostring(game.GameId)

    for k, v in pairs(set) do
        if tostring(k) == placeId or tostring(k) == gameId then
            return true
        end
    end
    return false
end

local MapMode, MapLabel = nil, nil
local AtokTape = false
local IsOpahMap = false

if MatchId(OPAH_IDS) then
    MapMode, MapLabel = "Opah", "Opah"
    IsOpahMap = true
elseif MatchId(ATOK_IDS) then
    MapMode, MapLabel = "Atok", "Atok"
elseif MatchId(ATOK_TAPE_IDS) then
    MapMode, MapLabel = "Atok", "Atok 2"
    AtokTape = true
end

if not MapMode then
    pcall(function()
        Player:Kick("YVONE HUB: map ini tidak didukung oleh script.")
    end)
    return
end

local IsAtok = MapMode == "Atok"

-- Atok 1: fixed safe zone position
local ATOK_SAFE_POS = Vector3.new(-265.1, 17.3, 135.2)

-- Atok 2: safe zone = where you spawned when the script started
local SpawnCFrame
if AtokTape then
    task.spawn(function()
        local char = Player.Character or Player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root and not SpawnCFrame then
            SpawnCFrame = root.CFrame
        end
    end)
end

local SAFE_KEYS = { "safezone" }

local function NameHasSafe(name)
    local n = string.lower(name)
    for _, k in ipairs(SAFE_KEYS) do
        if string.find(n, k, 1, true) then return true end
    end
    return false
end

-- Access level (chosen on the launch screen)
local VIP_PASSWORD = "911"
local IsVip = false

for _, name in ipairs({ "YvoneHub", "YvoneLoading", "YvoneWarning" }) do
    local old = PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

--==============================================================
-- VIP KEY VERIFICATION (raw GitHub read only, no HWID binding)
--==============================================================

local VIP_KEYS_URL = "https://raw.githubusercontent.com/SaXyeeBARZ/xxxcrotx-functionx/refs/heads/main/key.json"

local function GetRequestFns()
    local list = {}
    local function add(fn)
        if type(fn) == "function" then table.insert(list, fn) end
    end
    pcall(function() add(request) end)
    pcall(function() add(http_request) end)
    pcall(function() add(syn and syn.request) end)
    pcall(function() add(http and http.request) end)
    pcall(function() add(_G and _G.request) end)
    return list
end

local function FetchOnce(url)
    for _, fn in ipairs(GetRequestFns()) do
        local ok, res = pcall(fn, { Url = url, Method = "GET" })
        if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
            if type(res.StatusCode) == "number" then
                if res.StatusCode >= 200 and res.StatusCode < 300 then
                    return res.Body
                end
            else
                return res.Body
            end
        end
    end

    local ok, body = pcall(function()
        return game:GetService("HttpService"):GetAsync(url, true)
    end)
    if ok and type(body) == "string" and #body > 0 then
        return body
    end

    return nil
end

local function HttpGet(baseUrl)
    local variants = { baseUrl }

    local simplified = string.gsub(baseUrl, "/refs/heads/", "/")
    if simplified ~= baseUrl then
        table.insert(variants, simplified)
    end

    local ts = tostring(os.time())

    for _, url in ipairs(variants) do
        local sep = string.find(url, "?", 1, true) and "&" or "?"

        local body = FetchOnce(url .. sep .. "t=" .. ts)
        if body then return body end

        body = FetchOnce(url)
        if body then return body end
    end

    return nil
end

local function JsonDecode(str)
    local ok, res = pcall(function()
        return game:GetService("HttpService"):JSONDecode(str)
    end)
    if ok then return res end
    return nil
end

local function VerifyVIP(key)
    key = tostring(key or ""):gsub("%s+", ""):upper()
    if #key == 0 then
        return false, nil, "Key kosong."
    end

    if key == VIP_PASSWORD then
        return true, "vip", nil
    end

    local body = HttpGet(VIP_KEYS_URL)
    if not body then
        return false, nil, "Gagal menghubungi server key."
    end

    local data = JsonDecode(body)
    if type(data) ~= "table" then
        return false, nil, "Format key tidak valid."
    end

    local entry = data[key]
    if entry == nil then
        return false, nil, "Key tidak ditemukan."
    end

    return true, "vip", nil
end

--==============================================================
-- THEME
--==============================================================

local C = {
    Bg = Color3.fromRGB(8, 9, 12),
    Panel = Color3.fromRGB(15, 16, 20),
    Side = Color3.fromRGB(11, 12, 15),
    Card = Color3.fromRGB(21, 22, 27),
    Card2 = Color3.fromRGB(33, 34, 41),
    Stroke = Color3.fromRGB(62, 64, 74),
    White = Color3.fromRGB(246, 247, 250),
    Gray = Color3.fromRGB(165, 168, 178),
    Muted = Color3.fromRGB(110, 113, 123),
    Green = Color3.fromRGB(34, 208, 120),
    Red = Color3.fromRGB(235, 80, 85),
    Yellow = Color3.fromRGB(255, 206, 64),
}

local FONT = Enum.Font.Gotham
local BOLD = Enum.Font.GothamBold
local BLACK = Enum.Font.GothamBlack

--==============================================================
-- STATE
--==============================================================

local State = {
    Launched = false,
    Closing = false,
    CurrentTab = "Home",

    ESP_Opah = false,
    ESP_Item = false,
    ESP_Name = true,
    ESP_Box = true,
    ESP_Distance = true,
    ESP_Drawer = false,

    AutoFarm = false,
    PreviousESP = nil,

    Speed = 16,
    FlySpeed = 50,
    FlyHeight = 100,
    Noclip = false,
    Fly = false,

    Animations = true,
    ShowStats = true,

    VisitedPositions = {}
}

local Connections = {}
local ESPObjects = {}
local OriginalCollision = {}
local Scales = {}
local FlySwitches = {}

local MainGui, LoadingGui, WarnGui, MainWindow, FlyPanel, FarmPanel, OpenButton, StatsHolder
local FlyVelocity, FlyOrientation, FlyAttachment, FlyConnection
local NoclipConnection, CachedSafeZone
local FarmStatusText, FarmStatusDot
local FlyHold = false

local MAX_DISTANCE = 1000
local SCAN_INTERVAL = 3
local UPDATE_INTERVAL = 0.25
local OPAH_CANCEL_RADIUS = 16

local function Track(c) table.insert(Connections, c) return c end

local function Disconnect(c)
    if c then pcall(function() c:Disconnect() end) end
end

local function DisconnectAll()
    for _, c in ipairs(Connections) do Disconnect(c) end
    table.clear(Connections)
end

--==============================================================
-- UI HELPERS
--==============================================================

local function New(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = o end
    return o
end

local function Round(p, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 10), Parent = p })
end

local function Stroke(p, color, th, tr)
    return New("UIStroke", {
        Color = color or C.Stroke,
        Thickness = th or 1,
        Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = p,
    })
end

local function Grad(p, c0, c1, rot)
    return New("UIGradient", {
        Color = ColorSequence.new(c0, c1),
        Rotation = rot or 90,
        Parent = p,
    })
end

local function Panelize(f, radius, strokeTr)
    f.BackgroundColor3 = C.White
    Round(f, radius or 12)
    Stroke(f, C.Stroke, 1, strokeTr or 0.45)
    Grad(f, Color3.fromRGB(36, 37, 44), Color3.fromRGB(19, 20, 25), 90)
end

local function Tween(o, d, props)
    if not o or not o.Parent then return end
    if not State.Animations then
        for k, v in pairs(props) do o[k] = v end
        return
    end
    TweenService:Create(o, TweenInfo.new(d or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function Text(parent, text, pos, size, ts, color, font, align)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Position = pos,
        Size = size,
        TextSize = ts or 12,
        TextColor3 = color or C.White,
        Font = font or FONT,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent,
    })
end

--==============================================================
-- DRAWN ICONS
--==============================================================

local function MakeIcon(name, parent, size, color, pos, anchor)
    color = color or C.White

    local box = New("Frame", {
        Name = "Icon_" .. name,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Position = pos or UDim2.new(),
        AnchorPoint = anchor or Vector2.zero,
        Parent = parent,
    })

    local th = math.max(1.6, size * 0.085)

    local function Line(x1, y1, x2, y2, t)
        local dx, dy = x2 - x1, y2 - y1
        local thick = t or th
        local bar = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale((x1 + x2) / 2, (y1 + y2) / 2),
            Size = UDim2.new(math.sqrt(dx * dx + dy * dy), thick, 0, thick),
            Rotation = math.deg(math.atan2(dy, dx)),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = box,
        })
        New("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bar })
    end

    local function Circle(cx, cy, d, fill, t)
        local c = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(cx, cy),
            Size = UDim2.fromScale(d, d),
            BackgroundColor3 = color,
            BackgroundTransparency = fill and 0 or 1,
            BorderSizePixel = 0,
            Parent = box,
        })
        New("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = c })
        if not fill then
            New("UIStroke", {
                Color = color,
                Thickness = t or th,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = c,
            })
        end
    end

    local function Rect(x, y, w, h, r, fill, t)
        local f = New("Frame", {
            Position = UDim2.fromScale(x, y),
            Size = UDim2.fromScale(w, h),
            BackgroundColor3 = color,
            BackgroundTransparency = fill and 0 or 1,
            BorderSizePixel = 0,
            Parent = box,
        })
        New("UICorner", { CornerRadius = UDim.new(r or 0, 0), Parent = f })
        if not fill then
            New("UIStroke", {
                Color = color,
                Thickness = t or th,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = f,
            })
        end
    end

    local I = {}

    I.home = function()
        Line(0.5, 0.14, 0.1, 0.48)
        Line(0.5, 0.14, 0.9, 0.48)
        Line(0.2, 0.4, 0.2, 0.86)
        Line(0.8, 0.4, 0.8, 0.86)
        Line(0.2, 0.86, 0.8, 0.86)
        Rect(0.43, 0.56, 0.14, 0.3, 0.2, true)
    end

    I.eye = function()
        Rect(0.06, 0.26, 0.88, 0.48, 0.5, false)
        Circle(0.5, 0.5, 0.26, true)
    end

    I.move = function()
        Line(0.18, 0.25, 0.48, 0.5)
        Line(0.48, 0.5, 0.18, 0.75)
        Line(0.5, 0.25, 0.8, 0.5)
        Line(0.8, 0.5, 0.5, 0.75)
    end

    I.cube = function()
        Line(0.5, 0.08, 0.86, 0.28)
        Line(0.86, 0.28, 0.86, 0.72)
        Line(0.86, 0.72, 0.5, 0.92)
        Line(0.5, 0.92, 0.14, 0.72)
        Line(0.14, 0.72, 0.14, 0.28)
        Line(0.14, 0.28, 0.5, 0.08)
        Line(0.14, 0.28, 0.5, 0.48)
        Line(0.86, 0.28, 0.5, 0.48)
        Line(0.5, 0.48, 0.5, 0.92)
    end

    I.gear = function()
        Circle(0.5, 0.5, 0.52, false)
        Circle(0.5, 0.5, 0.16, true)
        for k = 0, 7 do
            local a = k * math.pi / 4
            Line(0.5 + 0.28 * math.cos(a), 0.5 + 0.28 * math.sin(a),
                0.5 + 0.43 * math.cos(a), 0.5 + 0.43 * math.sin(a), th * 1.5)
        end
    end

    I.monitor = function()
        Rect(0.1, 0.18, 0.8, 0.54, 0.12, false)
        Line(0.5, 0.74, 0.5, 0.86)
        Line(0.3, 0.88, 0.7, 0.88)
    end

    I.info = function()
        Circle(0.5, 0.5, 0.84, false)
        Circle(0.5, 0.3, 0.11, true)
        Line(0.5, 0.46, 0.5, 0.72)
    end

    I.crown = function()
        Line(0.14, 0.8, 0.86, 0.8)
        Line(0.14, 0.8, 0.1, 0.3)
        Line(0.1, 0.3, 0.34, 0.52)
        Line(0.34, 0.52, 0.5, 0.2)
        Line(0.5, 0.2, 0.66, 0.52)
        Line(0.66, 0.52, 0.9, 0.3)
        Line(0.9, 0.3, 0.86, 0.8)
        Rect(0.16, 0.62, 0.68, 0.16, 0.2, true)
        Circle(0.1, 0.28, 0.14, true)
        Circle(0.5, 0.17, 0.14, true)
        Circle(0.9, 0.28, 0.14, true)
    end

    I.bolt = function()
        Line(0.6, 0.08, 0.28, 0.55)
        Line(0.28, 0.55, 0.52, 0.55)
        Line(0.52, 0.55, 0.4, 0.92)
        Line(0.4, 0.92, 0.74, 0.42)
        Line(0.74, 0.42, 0.5, 0.42)
        Line(0.5, 0.42, 0.6, 0.08)
    end

    I.plane = function()
        Line(0.1, 0.45, 0.92, 0.1)
        Line(0.92, 0.1, 0.5, 0.9)
        Line(0.5, 0.9, 0.42, 0.58)
        Line(0.42, 0.58, 0.1, 0.45)
        Line(0.42, 0.58, 0.92, 0.1)
    end

    I.pin = function()
        Circle(0.5, 0.36, 0.5, false)
        Circle(0.5, 0.36, 0.14, true)
        Line(0.28, 0.54, 0.5, 0.92)
        Line(0.72, 0.54, 0.5, 0.92)
    end

    I.person = function()
        Circle(0.5, 0.3, 0.32, true)
        Rect(0.2, 0.54, 0.6, 0.34, 0.45, true)
    end

    I.gamepad = function()
        Rect(0.06, 0.26, 0.88, 0.5, 0.45, false)
        Line(0.27, 0.4, 0.27, 0.62)
        Line(0.16, 0.51, 0.38, 0.51)
        Circle(0.66, 0.44, 0.11, true)
        Circle(0.78, 0.57, 0.11, true)
    end

    I.check = function()
        Line(0.2, 0.52, 0.42, 0.74)
        Line(0.42, 0.74, 0.82, 0.28)
    end

    I.close = function()
        Line(0.22, 0.22, 0.78, 0.78)
        Line(0.78, 0.22, 0.22, 0.78)
    end

    I.arrow = function()
        Line(0.14, 0.5, 0.84, 0.5)
        Line(0.84, 0.5, 0.58, 0.24)
        Line(0.84, 0.5, 0.58, 0.76)
    end

    I.chev = function()
        Line(0.36, 0.2, 0.66, 0.5)
        Line(0.66, 0.5, 0.36, 0.8)
    end

    I.pointer = function()
        Line(0.28, 0.1, 0.28, 0.78)
        Line(0.28, 0.1, 0.8, 0.58)
        Line(0.28, 0.78, 0.45, 0.62)
        Line(0.45, 0.62, 0.8, 0.58)
    end

    I.key = function()
        Circle(0.28, 0.5, 0.38, false)
        Line(0.47, 0.5, 0.92, 0.5)
        Line(0.74, 0.5, 0.74, 0.7)
        Line(0.88, 0.5, 0.88, 0.66)
    end

    I.note = function()
        Rect(0.2, 0.1, 0.6, 0.8, 0.12, false)
        Line(0.33, 0.32, 0.67, 0.32)
        Line(0.33, 0.5, 0.67, 0.5)
        Line(0.33, 0.68, 0.54, 0.68)
    end

    I.tape = function()
        Circle(0.44, 0.5, 0.68, false)
        Circle(0.44, 0.5, 0.24, false)
        Line(0.44, 0.84, 0.9, 0.84)
        Line(0.9, 0.84, 0.9, 0.66)
    end

    I.drawer = function()
        Rect(0.12, 0.16, 0.76, 0.68, 0.1, false)
        Line(0.12, 0.5, 0.88, 0.5)
        Rect(0.4, 0.28, 0.2, 0.08, 0.5, true)
        Rect(0.4, 0.64, 0.2, 0.08, 0.5, true)
    end

    I.shield = function()
        Line(0.5, 0.08, 0.84, 0.2)
        Line(0.84, 0.2, 0.84, 0.5)
        Line(0.84, 0.5, 0.5, 0.92)
        Line(0.5, 0.92, 0.16, 0.5)
        Line(0.16, 0.5, 0.16, 0.2)
        Line(0.16, 0.2, 0.5, 0.08)
        Line(0.34, 0.48, 0.46, 0.6)
        Line(0.46, 0.6, 0.68, 0.34)
    end

    I.warn = function()
        Line(0.5, 0.2, 0.5, 0.6)
        Circle(0.5, 0.8, 0.13, true)
    end

    I.dot = function()
        Circle(0.5, 0.5, 0.7, true)
    end

    local builder = I[name]
    if builder then builder() end

    return box
end

local function SetIconColor(box, color)
    for _, d in ipairs(box:GetDescendants()) do
        if d:IsA("UIStroke") then
            d.Color = color
        elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
            d.BackgroundColor3 = color
        end
    end
end

local CENTER = Vector2.new(0.5, 0.5)
local CENTER_POS = UDim2.fromScale(0.5, 0.5)

local function HubMark(parent, y, ts)
    Text(parent, "H   U   B", UDim2.fromOffset(0, y), UDim2.new(1, 0, 0, ts + 6), ts, C.White, BOLD, Enum.TextXAlignment.Center)
    local off = ts * 3.2
    local cy = y + (ts + 6) / 2
    for _, side in ipairs({ -1, 1 }) do
        local l = New("Frame", {
            AnchorPoint = Vector2.new(side == -1 and 1 or 0, 0.5),
            Position = UDim2.new(0.5, side * off, 0, cy),
            Size = UDim2.fromOffset(ts * 1.4, 2),
            BackgroundColor3 = C.White,
            BorderSizePixel = 0,
            Parent = parent,
        })
        Round(l, 1)
    end
end

local function AddScale(frame)
    local s = New("UIScale", { Scale = 1, Parent = frame })
    table.insert(Scales, s)
    return s
end

local function ApplyScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local v = cam.ViewportSize
    local sc = math.clamp(math.min(v.X / 980, v.Y / 640, 1), 0.5, 1)
    for _, s in ipairs(Scales) do
        if s.Parent then s.Scale = sc end
    end
end

local function MakeDraggable(handle, target, scaleObj)
    local dragging = false
    local startInput, startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input.Position
            startPosition = target.Position
        end
    end)

    Track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local sc = scaleObj and scaleObj.Scale or 1
            local dx = (input.Position.X - startInput.X) / sc
            local dy = (input.Position.Y - startInput.Y) / sc
            target.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + dx,
                startPosition.Y.Scale, startPosition.Y.Offset + dy
            )
        end
    end))

    Track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local function Btn(parent, text, size, pos, cb, primary)
    local b = New("TextButton", {
        Size = size,
        Position = pos,
        BackgroundColor3 = primary and C.White or C.Card,
        Text = text,
        TextColor3 = primary and C.Bg or C.White,
        Font = BOLD,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent,
    })
    Round(b, 10)
    Stroke(b, C.Stroke, 1, 0.4)
    b.MouseEnter:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = primary and C.Gray or C.Card2 })
    end)
    b.MouseLeave:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = primary and C.White or C.Card })
    end)
    b.MouseButton1Click:Connect(function()
        if cb then cb() end
    end)
    return b
end

--==============================================================
-- TOASTS
--==============================================================

local function Notify(title, message, kind)
    if not MainGui or not MainGui.Parent then return end
    local isErr = kind == "err"
    local col = isErr and C.Red or C.Green

    local t = New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Size = UDim2.fromOffset(262, 58),
        Position = UDim2.new(1, 290, 1, -120),
        BackgroundColor3 = C.Panel,
        ZIndex = 200,
        Parent = MainGui,
    })
    Round(t, 12)
    Stroke(t, C.Stroke, 1)

    local ic = New("Frame", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(12, 16),
        BackgroundColor3 = col,
        Parent = t,
    })
    Round(ic, 13)
    MakeIcon(isErr and "warn" or "check", ic, 14, C.White, CENTER_POS, CENTER)

    Text(t, title, UDim2.fromOffset(48, 9), UDim2.new(1, -80, 0, 20), 13, C.White, BOLD)
    Text(t, message, UDim2.fromOffset(48, 29), UDim2.new(1, -80, 0, 18), 10, C.Gray)
    MakeIcon("close", t, 10, C.Gray, UDim2.new(1, -22, 0, 10))

    Tween(t, 0.3, { Position = UDim2.new(1, -14, 1, -120) })

    task.delay(2.8, function()
        if t.Parent then
            Tween(t, 0.25, { Position = UDim2.new(1, 290, 1, -120) })
            task.wait(0.3)
            if t.Parent then t:Destroy() end
        end
    end)
end

local function TopToast(title, message)
    if not MainGui or not MainGui.Parent then return end

    local t = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.fromOffset(340, 66),
        Position = UDim2.new(0.5, 0, 0, -90),
        BackgroundColor3 = C.Panel,
        ZIndex = 200,
        Parent = MainGui,
    })
    Round(t, 16)
    Stroke(t, C.Stroke, 1.3)

    local ic = New("Frame", {
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.fromOffset(14, 13),
        BackgroundColor3 = C.Gray,
        Parent = t,
    })
    Round(ic, 20)
    MakeIcon("check", ic, 22, C.White, CENTER_POS, CENTER)

    Text(t, title, UDim2.fromOffset(70, 10), UDim2.new(1, -80, 0, 24), 16, C.White, BOLD)
    Text(t, message, UDim2.fromOffset(70, 33), UDim2.new(1, -80, 0, 22), 14, C.White)

    Tween(t, 0.4, { Position = UDim2.new(0.5, 0, 0, 18) })

    task.delay(3.5, function()
        if t.Parent then
            Tween(t, 0.3, { Position = UDim2.new(0.5, 0, 0, -90) })
            task.wait(0.35)
            if t.Parent then t:Destroy() end
        end
    end)
end

--==============================================================
-- CHARACTER HELPERS
--==============================================================

local function Character() return Player.Character end

local function Root()
    local c = Character()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Humanoid()
    local c = Character()
    return c and c:FindFirstChildOfClass("Humanoid")
end

--==============================================================
-- LOADING SCREEN
--==============================================================

LoadingGui = New("ScreenGui", {
    Name = "YvoneLoading",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 300,
    Parent = PlayerGui,
})

local LoadBg = New("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.Bg,
    Parent = LoadingGui,
})

local LoadCard = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(400, 260),
    BackgroundColor3 = C.White,
    Parent = LoadBg,
})
Round(LoadCard, 20)
Stroke(LoadCard, C.Stroke, 1.4)
Grad(LoadCard, Color3.fromRGB(24, 25, 30), Color3.fromRGB(10, 11, 14), 120)

local LogoY = Text(LoadCard, "YVONE", UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 60), 44, C.White, BLACK, Enum.TextXAlignment.Center)
Grad(LogoY, C.White, Color3.fromRGB(125, 128, 138), 90)
HubMark(LoadCard, 84, 13)

local LoadStatus = Text(LoadCard, "Initializing interface...", UDim2.fromOffset(25, 128), UDim2.new(1, -50, 0, 20), 11, C.Gray)

local LoadBar = New("Frame", {
    Size = UDim2.new(1, -50, 0, 6),
    Position = UDim2.fromOffset(25, 160),
    BackgroundColor3 = C.Stroke,
    Parent = LoadCard,
})
Round(LoadBar, 3)

local LoadFill = New("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.White,
    Parent = LoadBar,
})
Round(LoadFill, 3)

local LoadingReady = false
local OnLoadingDone

local LoadScale = New("UIScale", { Parent = LoadCard })
local function FitLoadScale()
    local cam = Workspace.CurrentCamera
    local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
    LoadScale.Scale = math.clamp(math.min(vs.X / 500, vs.Y / 400, 1), 0.55, 1)
end
FitLoadScale()

task.spawn(function()
    local steps = {
        "Initializing interface...",
        "Preparing dashboard...",
        "Loading visual components...",
        "Preparing mobile controls...",
        "Finalizing configuration...",
    }
    for i, s in ipairs(steps) do
        if not LoadingGui.Parent then return end
        LoadStatus.Text = s
        Tween(LoadFill, 0.35, { Size = UDim2.new(i / #steps, 0, 1, 0) })
        task.wait(0.4)
    end
    LoadStatus.Text = "All systems ready."
    task.wait(0.3)
    LoadingReady = true
    if OnLoadingDone then OnLoadingDone() end
end)

--==============================================================
-- ESP ENGINE
--==============================================================

local function GetCategory(name)
    local n = string.lower(name)

    if string.find(n, "safezone") or string.find(n, "keypad") or string.find(n, "chair") then
        return nil
    end
    if string.find(n, "opah") then
        return "OPAH", C.Red
    end
    if string.find(n, "key") then
        if string.find(n, "red") then return "RED KEY", C.Red
        elseif string.find(n, "blue") then return "BLUE KEY", Color3.fromRGB(105, 165, 235)
        elseif string.find(n, "green") then return "GREEN KEY", C.Green
        elseif string.find(n, "yellow") then return "YELLOW KEY", C.Yellow end
        return "KEY", C.White
    end
    if string.find(n, "note") or string.find(n, "passcode") then
        return "PASSCODE NOTE", C.Yellow
    end
    return nil
end

local function IsDrawerName(inst)
    return (inst:IsA("Model") or inst:IsA("BasePart"))
        and string.find(string.lower(inst.Name), "drawer", 1, true) ~= nil
end

local function IsDrawerModel(inst)
    return inst:IsA("Model") and string.find(string.lower(inst.Name), "drawer", 1, true) ~= nil
end

local function HasDrawerModelDescendant(model)
    for _, d in ipairs(model:GetDescendants()) do
        if IsDrawerModel(d) then return true end
    end
    return false
end

local function DrawerModelAncestor(inst)
    local n = inst.Parent
    while n and n ~= Workspace do
        if IsDrawerModel(n) then return n end
        n = n.Parent
    end
    return nil
end

local function IsDrawerTarget(inst)
    if not IsDrawerName(inst) then return false end
    if inst:IsA("Model") then
        return not HasDrawerModelDescendant(inst)
    end
    local m = DrawerModelAncestor(inst)
    if m and not HasDrawerModelDescendant(m) then return false end
    return true
end

local function IsTapeName(inst)
    if not (inst:IsA("Model") or inst:IsA("BasePart") or inst:IsA("Tool")) then
        return false
    end
    local spaced = string.gsub(inst.Name, "(%l)(%u)", "%1 %2")
    for word in string.gmatch(string.lower(spaced), "%a+") do
        if word == "pita" or word == "tape" or word == "pitas" or word == "tapes" then
            return true
        end
    end
    return false
end

local function HasTapeDescendant(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if IsTapeName(d) then return true end
    end
    return false
end

local function GetPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") or inst:IsA("Tool") then
        if inst:IsA("Model") then
            local rootPart = inst:FindFirstChild("HumanoidRootPart") or inst.PrimaryPart
            if rootPart and rootPart:IsA("BasePart") then return rootPart end
        end
        return inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function Classify(inst)
    if IsAtok then
        if IsDrawerTarget(inst) then
            return "DRAWER", C.Yellow
        end
        return nil
    end
    return GetCategory(inst.Name)
end

local function CategoryEnabled(cat)
    if cat == "DRAWER" then return State.ESP_Drawer end
    if cat == "OPAH" then return State.ESP_Opah end
    return State.ESP_Item
end

local function RemoveESP(inst)
    local data = ESPObjects[inst]
    if not data then return end
    for _, o in pairs(data) do
        if typeof(o) == "Instance" then
            pcall(function() o:Destroy() end)
        end
    end
    ESPObjects[inst] = nil
end

local function ClearESP()
    for inst in pairs(ESPObjects) do RemoveESP(inst) end
end

local function CreateESP(inst)
    if not inst or not inst.Parent or ESPObjects[inst] then return end

    local category, color = Classify(inst)
    if not category or not CategoryEnabled(category) then return end

    local display = category

    local part = GetPart(inst)
    if not part then return end

    local hl = Instance.new("Highlight")
    hl.Name = "YvoneHighlight"
    hl.Adornee = inst
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.8
    hl.OutlineTransparency = 0.15
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Name = "YvoneLabel"
    bb.Adornee = part
    bb.Size = UDim2.fromOffset(170, 30)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = MAX_DISTANCE
    bb.Parent = PlayerGui

    local label = New("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        TextColor3 = color,
        TextStrokeTransparency = 0.2,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        Font = BOLD,
        TextSize = 12,
        Parent = bb,
    })

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "YvoneBox"
    box.Adornee = part
    box.Size = part.Size
    box.AlwaysOnTop = true
    box.Color3 = color
    box.Transparency = 0.8
    box.ZIndex = 5
    box.Parent = Workspace

    ESPObjects[inst] = {
        Highlight = hl,
        Billboard = bb,
        Label = label,
        Box = box,
        Category = category,
        Display = display,
        Part = part,
    }
end

local function ApplyESPFlags()
    for inst, data in pairs(ESPObjects) do
        if not CategoryEnabled(data.Category) then
            RemoveESP(inst)
        end
    end
end

local function ScanESP()
    if not (State.ESP_Opah or State.ESP_Item or State.ESP_Drawer) then return end
    local root = Root()
    if not root then return end
    local char = Character()

    for _, inst in ipairs(Workspace:GetDescendants()) do
        if not ESPObjects[inst] and not (char and inst:IsDescendantOf(char)) then
            local cat = Classify(inst)
            if cat and CategoryEnabled(cat) then
                local part = GetPart(inst)
                if part and (root.Position - part.Position).Magnitude <= MAX_DISTANCE then
                    CreateESP(inst)
                end
            end
        end
    end
end

local function RefreshESP()
    ClearESP()
    ScanESP()
end

local HIGHLIGHT_LIMIT = 24

local function UpdateESP()
    local root = Root()
    if not root then return end

    local ranked = {}

    for inst, data in pairs(ESPObjects) do
        if not inst.Parent then
            RemoveESP(inst)
        else
            local part = data.Part
            if not part or not part.Parent then
                part = GetPart(inst)
                data.Part = part
                if part then
                    data.Billboard.Adornee = part
                    data.Box.Adornee = part
                    data.Box.Size = part.Size
                end
            end

            if not part then
                RemoveESP(inst)
            else
                local dist = (root.Position - part.Position).Magnitude
                if dist > MAX_DISTANCE then
                    RemoveESP(inst)
                else
                    data.Dist = dist
                    data.Billboard.Enabled = State.ESP_Name
                    data.Box.Visible = State.ESP_Box

                    local shown = data.Display or data.Category
                    if State.ESP_Distance then
                        data.Label.Text = string.format("%s  [%dm]", shown, math.floor(dist * 0.28))
                    else
                        data.Label.Text = shown
                    end

                    table.insert(ranked, data)
                end
            end
        end
    end

    table.sort(ranked, function(a, b)
        local da = (a.Category == "OPAH") and -1 or a.Dist
        local db = (b.Category == "OPAH") and -1 or b.Dist
        return da < db
    end)

    for i, data in ipairs(ranked) do
        data.Highlight.Enabled = i <= HIGHLIGHT_LIMIT
    end
end

--==============================================================
-- TARGETS / TELEPORT / AUTO TELEPORT
--==============================================================

local TargetCache = { Key = {}, Note = {}, Drawer = {}, Tape = {}, Time = 0 }

local function ZoneInfo(inst)
    if inst:IsA("BasePart") then return inst.CFrame, inst.Size end
    local ok, cf, size = pcall(function() return inst:GetBoundingBox() end)
    if ok then return cf, size end
    return nil
end

local function IsZoneInstance(inst)
    if not (inst:IsA("BasePart") or (IsAtok and inst:IsA("Model"))) then return false end
    return NameHasSafe(inst.Name)
end

local function InSafeZone(part, zones)
    local node = part
    while node and node ~= Workspace do
        if NameHasSafe(node.Name) then return true end
        node = node.Parent
    end

    for _, zone in ipairs(zones) do
        local rel = zone.CFrame:PointToObjectSpace(part.Position)
        local half = zone.Size / 2
        if math.abs(rel.X) <= half.X + 2
            and math.abs(rel.Y) <= half.Y + 6
            and math.abs(rel.Z) <= half.Z + 2 then
            return true
        end
    end
    return false
end

local function RefreshTargets()
    if os.clock() - TargetCache.Time < 2 then return end
    TargetCache.Time = os.clock()
    TargetCache.Key = {}
    TargetCache.Note = {}
    TargetCache.Drawer = {}
    TargetCache.Tape = {}

    local char = Character()
    local zones = {}
    local found = {}

    for _, inst in ipairs(Workspace:GetDescendants()) do
        if IsZoneInstance(inst) then
            local cf, size = ZoneInfo(inst)
            if cf then table.insert(zones, { CFrame = cf, Size = size }) end
        end

        if not (char and inst:IsDescendantOf(char)) then
            if IsAtok then
                if AtokTape then
                    if IsTapeName(inst) and not (inst:IsA("Model") and HasTapeDescendant(inst)) then
                        local part = GetPart(inst)
                        if part then
                            table.insert(found, { Part = part, Cat = "TAPE" })
                        end
                    end
                elseif IsDrawerTarget(inst) then
                    local part = GetPart(inst)
                    if part then
                        table.insert(found, { Part = part, Cat = "DRAWER" })
                    end
                end
            else
                local cat = GetCategory(inst.Name)
                if cat and cat ~= "OPAH" then
                    local part = GetPart(inst)
                    if part then
                        table.insert(found, { Part = part, Cat = cat })
                    end
                end
            end
        end
    end

    for _, item in ipairs(found) do
        if not InSafeZone(item.Part, zones) then
            if item.Cat == "DRAWER" or item.Cat == "TAPE" then
                local list = (item.Cat == "DRAWER") and TargetCache.Drawer or TargetCache.Tape
                local duplicate = false
                for _, other in ipairs(list) do
                    if (other.Position - item.Part.Position).Magnitude < 1.5 then
                        duplicate = true
                        break
                    end
                end
                if not duplicate then
                    table.insert(list, item.Part)
                end
            elseif string.find(item.Cat, "KEY") then
                table.insert(TargetCache.Key, item.Part)
            elseif string.find(item.Cat, "NOTE") then
                table.insert(TargetCache.Note, item.Part)
            end
        end
    end
end

local function FindNearest(kind)
    RefreshTargets()
    local root = Root()
    if not root then return nil end

    local list
    if kind == "key" then
        list = TargetCache.Key
    elseif kind == "tape" then
        list = TargetCache.Tape
    else
        list = TargetCache.Note
    end
    local best
    local shortest = math.huge

    for _, part in ipairs(list) do
        if part.Parent then
            local d = (root.Position - part.Position).Magnitude
            if d < shortest then
                shortest = d
                best = part
            end
        end
    end
    return best
end

local function PickUnvisited(list, findNearest)
    if not list or #list == 0 then return nil end

    local unvisited = {}
    for _, part in ipairs(list) do
        if part.Parent then
            local isVisited = false
            for _, vPos in ipairs(State.VisitedPositions) do
                if (part.Position - vPos).Magnitude < 15 then
                    isVisited = true
                    break
                end
            end

            if not isVisited then
                table.insert(unvisited, part)
            end
        end
    end

    if #unvisited == 0 then
        table.clear(State.VisitedPositions)
        for _, part in ipairs(list) do
            if part.Parent then table.insert(unvisited, part) end
        end
        if #unvisited == 0 then return nil end
    end

    local pick
    if findNearest then
        local root = Root()
        if root then
            local shortest = math.huge
            for _, part in ipairs(unvisited) do
                local d = (root.Position - part.Position).Magnitude
                if d < shortest then
                    shortest = d
                    pick = part
                end
            end
        else
            pick = unvisited[1]
        end
    else
        pick = unvisited[math.random(#unvisited)]
    end

    if pick then
        table.insert(State.VisitedPositions, pick.Position)
        if #State.VisitedPositions > 100 then
            table.remove(State.VisitedPositions, 1)
        end
    end

    return pick
end

local TeleportLoadingActive = false

local function TeleportLoading(label)
    if IsVip then return true end
    if TeleportLoadingActive then return false end
    TeleportLoadingActive = true

    local gui = New("ScreenGui", {
        Name = "YvoneTeleport",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 450,
        Parent = PlayerGui,
    })

    local dim = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Active = true,
        Parent = gui,
    })

    local card = New("Frame", {
        AnchorPoint = CENTER,
        Position = CENTER_POS,
        Size = UDim2.fromOffset(300, 190),
        BackgroundColor3 = C.White,
        Parent = dim,
    })
    Round(card, 18)
    Stroke(card, C.Stroke, 1.4, 0.15)
    Grad(card, Color3.fromRGB(28, 29, 36), Color3.fromRGB(10, 11, 14), 120)

    local cam = Workspace.CurrentCamera
    local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
    New("UIScale", { Scale = math.clamp(math.min(vs.X / 420, vs.Y / 260, 1), 0.6, 1), Parent = card })

    local ring = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 22),
        Size = UDim2.fromOffset(44, 44),
        BackgroundTransparency = 1,
        Parent = card,
    })
    Round(ring, 22)
    Stroke(ring, C.Stroke, 3, 0.3)

    local orbit = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = ring,
    })
    local dot = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = C.White,
        BorderSizePixel = 0,
        Parent = orbit,
    })
    Round(dot, 5)

    Text(card, "Teleporting...", UDim2.fromOffset(0, 78), UDim2.new(1, 0, 0, 22), 16, C.White, BOLD, Enum.TextXAlignment.Center)
    Text(card, "Destination: " .. (label or "Target"), UDim2.fromOffset(0, 100), UDim2.new(1, 0, 0, 18), 11, C.Gray, FONT, Enum.TextXAlignment.Center)

    local barBg = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 130),
        Size = UDim2.fromOffset(240, 6),
        BackgroundColor3 = C.Stroke,
        BorderSizePixel = 0,
        Parent = card,
    })
    Round(barBg, 3)
    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.White,
        BorderSizePixel = 0,
        Parent = barBg,
    })
    Round(fill, 3)
    local pct = Text(card, "0%", UDim2.fromOffset(0, 140), UDim2.new(1, 0, 0, 18), 11, C.White, BOLD, Enum.TextXAlignment.Center)
    Text(card, "Free access - VIP teleports instantly", UDim2.fromOffset(0, 164), UDim2.new(1, 0, 0, 16), 9, C.Muted, FONT, Enum.TextXAlignment.Center)

    local started = os.clock()
    local duration = 2
    local ok = true

    while true do
        local t = (os.clock() - started) / duration
        if t >= 1 then break end
        if State.Closing or not gui.Parent then
            ok = false
            break
        end
        fill.Size = UDim2.new(t, 0, 1, 0)
        pct.Text = math.floor(t * 100) .. "%"
        orbit.Rotation = (os.clock() * 420) % 360
        RunService.RenderStepped:Wait()
    end

    gui:Destroy()
    TeleportLoadingActive = false
    return ok
end

local function TeleportCF(cf, label)
    if not TeleportLoading(label) then return false end
    local r = Root()
    if not r then return false end
    r.AssemblyLinearVelocity = Vector3.zero
    r.CFrame = cf
    return true
end

local function PlaceAt(pos, label)
    return TeleportCF(CFrame.new(pos + Vector3.new(0, 4, 0)), label)
end

-- Instant teleport (tanpa overlay 2 detik) — dipakai safe zone
local function TeleportCFInstant(cf)
    local r = Root()
    if not r then return false end
    r.AssemblyLinearVelocity = Vector3.zero
    r.CFrame = cf
    return true
end

local function PlaceAtInstant(pos)
    return TeleportCFInstant(CFrame.new(pos + Vector3.new(0, 4, 0)))
end

-- true kalau ada objek bernama "opah" dalam radius tertentu dari player.
-- HANYA berlaku di map Opah — di map Atok selalu false.
local function IsNearOpah(radius)
    if not IsOpahMap then return false end
    local root = Root()
    if not root then return false end
    local pos = root.Position
    local char = Character()
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if (inst:IsA("Model") or inst:IsA("BasePart")) then
            if string.find(string.lower(inst.Name), "opah", 1, true) then
                if not (char and inst:IsDescendantOf(char)) then
                    local part = GetPart(inst)
                    if part and part.Parent then
                        if (part.Position - pos).Magnitude <= radius then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function ZonePos(inst)
    if inst:IsA("BasePart") then return inst.Position end
    return inst:GetPivot().Position
end

local function SafePosition()
    if CachedSafeZone and CachedSafeZone.Parent then
        return ZonePos(CachedSafeZone)
    end
    CachedSafeZone = nil

    local best, bestRank
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") or (IsAtok and o:IsA("Model")) then
            local n = string.lower(o.Name)
            for rank, k in ipairs(SAFE_KEYS) do
                if string.find(n, k, 1, true) then
                    if not bestRank or rank < bestRank then
                        best = o
                        bestRank = rank
                    end
                    break
                end
            end
        end
    end

    CachedSafeZone = best
    if best then return ZonePos(best) end
    return nil
end

local function TeleportSafe()
    if TeleportLoadingActive then return end

    local root = Root()
    if not root then Notify("Teleport", "Character belum siap.", "err") return end

    if IsAtok then
        if AtokTape then
            if not SpawnCFrame then
                Notify("Teleport", "Posisi spawn belum tersimpan.", "err")
                return
            end
            if TeleportCFInstant(SpawnCFrame) then
                Notify("Teleport", "Teleported to your spawn.")
            end
        else
            if TeleportCFInstant(CFrame.new(ATOK_SAFE_POS)) then
                Notify("Teleport", "Teleported to Safe Zone.")
            end
        end
        return
    end

    local pos = SafePosition()
    if not pos then Notify("Teleport", "Safe Zone tidak ditemukan.", "err") return end
    if PlaceAtInstant(pos) then
        Notify("Teleport", "Teleported to Safe Zone.")
    end
end

local function SetFarmStatus(text, color)
    if FarmStatusText and FarmStatusText.Parent then
        FarmStatusText.Text = text
    end
    if FarmStatusDot and FarmStatusDot.Parent then
        Tween(FarmStatusDot, 0.2, { BackgroundColor3 = color or C.Gray })
    end
end

local TeleportBusy = false

local function RefreshNow()
    TargetCache.Time = 0
    RefreshTargets()
end

local function Rescan()
    if not IsVip then RefreshNow() end
end

local function PlaceNow(pos)
    local r = Root()
    if not r then return false end
    r.AssemblyLinearVelocity = Vector3.zero
    r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    return true
end

local function RunFarm(fn)
    if TeleportBusy or TeleportLoadingActive then return end
    TeleportBusy = true
    local ok, err = pcall(fn)
    if not ok then warn("[YVONE] " .. tostring(err)) end
    task.delay(0.6, function() TeleportBusy = false end)
end

local function TeleportItem(kind)
    if TeleportLoadingActive then return end
    if not Root() then Notify("Teleport", "Character belum siap.", "err") return end

    if IsNearOpah(OPAH_CANCEL_RADIUS) then
        Notify("Quick Action", "Opah terlalu dekat, teleport dibatalkan.", "err")
        return
    end

    RefreshNow()
    local first = (kind == "key") and TargetCache.Key or TargetCache.Note
    if #first == 0 then
        Notify("Quick Action", "Target belum ditemukan.", "err")
        return
    end

    if not TeleportLoading((kind == "key") and "Key" or "Note") then return end

    Rescan()
    local list = (kind == "key") and TargetCache.Key or TargetCache.Note
    local target = PickUnvisited(list, true)

    if target and PlaceNow(target.Position) then
        Notify("Quick Action", "Target ditemukan.")
    else
        Notify("Quick Action", "Target belum ditemukan.", "err")
    end
end

local function SmartTeleport()
    RunFarm(function()
        if not Root() then
            SetFarmStatus("Waiting for character", C.Gray)
            Notify("Teleport", "Character belum siap.", "err")
            return
        end

        if IsNearOpah(OPAH_CANCEL_RADIUS) then
            SetFarmStatus("Opah terlalu dekat", C.Yellow)
            return
        end

        RefreshNow()
        if #TargetCache.Key == 0 and #TargetCache.Note == 0 then
            SetFarmStatus("No key or note found", C.Yellow)
            return
        end

        if not TeleportLoading("Key / Note") then
            SetFarmStatus("Teleport cancelled", C.Gray)
            return
        end

        Rescan()
        local target = PickUnvisited(TargetCache.Key, true)
        local label = "Key"

        if not target then
            target = PickUnvisited(TargetCache.Note, true)
            label = "Note"
        end

        if target and PlaceNow(target.Position) then
            SetFarmStatus("Teleported to " .. label, C.Green)
        else
            SetFarmStatus("No key or note found", C.Yellow)
        end
    end)
end

local function TeleportDrawer(notify)
    RunFarm(function()
        if not Root() then
            SetFarmStatus("Waiting for character", C.Gray)
            if notify then Notify("Teleport", "Character belum siap.", "err") end
            return
        end

        if IsNearOpah(OPAH_CANCEL_RADIUS) then
            SetFarmStatus("Opah terlalu dekat", C.Yellow)
            if notify then Notify("Teleport", "Opah terlalu dekat, teleport dibatalkan.", "err") end
            return
        end

        RefreshNow()
        if #TargetCache.Drawer == 0 then
            SetFarmStatus("No drawer found", C.Yellow)
            if notify then Notify("Teleport", "Drawer tidak ditemukan.", "err") end
            return
        end

        if not TeleportLoading("Drawer") then
            SetFarmStatus("Teleport cancelled", C.Gray)
            return
        end

        Rescan()
        local list = {}
        for _, part in ipairs(TargetCache.Drawer) do
            if part.Parent then table.insert(list, part) end
        end

        local pick = PickUnvisited(list, false)

        if pick and PlaceNow(pick.Position) then
            SetFarmStatus(string.format("Random drawer (%d found)", #list), C.Green)
            if notify then Notify("Teleport", "Teleported to a random drawer.") end
        else
            SetFarmStatus("No drawer found", C.Yellow)
            if notify then Notify("Teleport", "Drawer tidak ditemukan.", "err") end
        end
    end)
end

local function TeleportTape(notify)
    RunFarm(function()
        if not Root() then
            SetFarmStatus("Waiting for character", C.Gray)
            if notify then Notify("Teleport", "Character belum siap.", "err") end
            return
        end

        if IsNearOpah(OPAH_CANCEL_RADIUS) then
            SetFarmStatus("Opah terlalu dekat", C.Yellow)
            if notify then Notify("Teleport", "Opah terlalu dekat, teleport dibatalkan.", "err") end
            return
        end

        RefreshNow()
        if #TargetCache.Tape == 0 then
            SetFarmStatus("No tape found", C.Yellow)
            if notify then Notify("Teleport", "Tape / pita tidak ditemukan.", "err") end
            return
        end

        if not TeleportLoading("Tape") then
            SetFarmStatus("Teleport cancelled", C.Gray)
            return
        end

        Rescan()
        local list = {}
        for _, part in ipairs(TargetCache.Tape) do
            if part.Parent then table.insert(list, part) end
        end

        local pick = PickUnvisited(list, false)

        if pick and PlaceNow(pick.Position) then
            SetFarmStatus(string.format("Random tape (%d found)", #list), C.Green)
            if notify then Notify("Teleport", "Teleported to a random tape.") end
        else
            SetFarmStatus("No tape found", C.Yellow)
            if notify then Notify("Teleport", "Tape / pita tidak ditemukan.", "err") end
        end
    end)
end

local function FarmTeleport()
    if IsAtok then
        if AtokTape then
            TeleportTape(false)
        else
            TeleportDrawer(false)
        end
    else
        SmartTeleport()
    end
end

--==============================================================
-- MOVEMENT
--==============================================================

local function UpdateSpeed()
    local h = Humanoid()
    if h then h.WalkSpeed = State.Speed end
end

local function RestoreCollision()
    for part, original in pairs(OriginalCollision) do
        if part and part.Parent then
            pcall(function() part.CanCollide = original end)
        end
    end
    table.clear(OriginalCollision)
end

local function ToggleNoclip(enabled)
    State.Noclip = enabled
    Disconnect(NoclipConnection)
    NoclipConnection = nil

    if not enabled then
        RestoreCollision()
        Notify("Noclip", "Noclip dinonaktifkan.")
        return
    end

    NoclipConnection = RunService.Stepped:Connect(function()
        local c = Character()
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                if OriginalCollision[p] == nil then
                    OriginalCollision[p] = p.CanCollide
                end
                p.CanCollide = false
            end
        end
    end)
    Notify("Noclip", "Noclip diaktifkan.")
end

local function ClearFly()
    Disconnect(FlyConnection)
    FlyConnection = nil
    if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
    if FlyOrientation then FlyOrientation:Destroy() FlyOrientation = nil end
    if FlyAttachment then FlyAttachment:Destroy() FlyAttachment = nil end
    FlyHold = false
end

local function SyncFlySwitches(v)
    for _, s in ipairs(FlySwitches) do s.Set(v, true) end
end

local function SetFly(enabled)
    State.Fly = enabled
    ClearFly()

    local hum = Humanoid()

    if not enabled then
        SyncFlySwitches(false)
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        Notify("Fly Mode", "Fly mode deactivated.")
        return
    end

    local root = Root()
    if not root or not hum then
        State.Fly = false
        SyncFlySwitches(false)
        Notify("Fly Mode", "Character belum siap.", "err")
        return
    end

    FlyAttachment = Instance.new("Attachment")
    FlyAttachment.Name = "YvoneFlyAttachment"
    FlyAttachment.Parent = root

    FlyVelocity = Instance.new("LinearVelocity")
    FlyVelocity.Name = "YvoneFlyVelocity"
    FlyVelocity.Attachment0 = FlyAttachment
    FlyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    FlyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    FlyVelocity.VectorVelocity = Vector3.zero
    FlyVelocity.MaxForce = math.huge
    FlyVelocity.Parent = root

    FlyOrientation = Instance.new("AlignOrientation")
    FlyOrientation.Name = "YvoneFlyOrientation"
    FlyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    FlyOrientation.Attachment0 = FlyAttachment
    FlyOrientation.MaxTorque = math.huge
    FlyOrientation.Responsiveness = 15
    FlyOrientation.Parent = root

    hum.PlatformStand = true
    SyncFlySwitches(true)
    if FlyPanel then FlyPanel.Visible = true end

    FlyConnection = RunService.RenderStepped:Connect(function()
        local r = Root()
        local h = Humanoid()
        local cam = Workspace.CurrentCamera
        if not State.Fly or not r or not h or not cam or not FlyVelocity then return end

        local look = cam.CFrame.LookVector
        local hv = State.FlyHeight / 100
        local dir

        if FlyHold then
            dir = Vector3.new(look.X, look.Y * hv, look.Z)
        else
            dir = h.MoveDirection
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, hv, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, hv, 0) end
        end

        if dir.Magnitude > 0.01 then
            FlyVelocity.VectorVelocity = dir.Unit * State.FlySpeed
        else
            FlyVelocity.VectorVelocity = Vector3.zero
        end

        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0.01 and FlyOrientation then
            FlyOrientation.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
        end
    end)

    Notify("Success!", "Fly mode activated.")
end

--==============================================================
-- MAIN INTERFACE
--==============================================================

local function Launch()
    if State.Launched then return end
    State.Launched = true

    if LoadingGui then LoadingGui:Destroy() end

    MainGui = New("ScreenGui", {
        Name = "YvoneHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        Parent = PlayerGui,
    })

    local BottomNav

    MainWindow = New("Frame", {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, -28),
        Size = UDim2.fromOffset(880, 500),
        BackgroundColor3 = C.White,
        ClipsDescendants = true,
        Parent = MainGui,
    })
    Round(MainWindow, 22)
    Stroke(MainWindow, C.Stroke, 1.5, 0.15)
    Grad(MainWindow, Color3.fromRGB(24, 25, 30), Color3.fromRGB(9, 10, 13), 135)
    local WindowScale = AddScale(MainWindow)

    local function SetUIVisible(v)
        MainWindow.Visible = v
        if BottomNav then BottomNav.Visible = v end
        if OpenButton then OpenButton.Visible = not v end
    end

    local Sidebar = New("Frame", {
        Size = UDim2.new(0, 170, 1, 0),
        BackgroundColor3 = C.Side,
        BorderSizePixel = 0,
        Parent = MainWindow,
    })
    Round(Sidebar, 22)
    New("Frame", {
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.fromOffset(130, 0),
        BackgroundColor3 = C.Side,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    New("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.fromOffset(170, 0),
        BackgroundColor3 = C.Stroke,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = MainWindow,
    })

    local Logo = Text(Sidebar, "Y", UDim2.fromOffset(0, 14), UDim2.new(1, 0, 0, 60), 56, C.White, BLACK, Enum.TextXAlignment.Center)
    Grad(Logo, C.White, Color3.fromRGB(120, 123, 133), 90)
    Text(Sidebar, "YVONE HUB", UDim2.fromOffset(0, 78), UDim2.new(1, 0, 0, 20), 15, C.White, BOLD, Enum.TextXAlignment.Center)
    Text(Sidebar, "BLACK EDITION", UDim2.fromOffset(0, 97), UDim2.new(1, 0, 0, 14), 10, C.Gray, FONT, Enum.TextXAlignment.Center)

    local Nav = New("Frame", {
        Size = UDim2.new(1, -20, 0, 280),
        Position = UDim2.fromOffset(10, 126),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Nav })

    local Footer = New("Frame", {
        Size = UDim2.new(1, -20, 0, 56),
        Position = UDim2.new(0, 10, 1, -66),
        Parent = Sidebar,
    })
    Panelize(Footer, 12, 0.4)
    MakeIcon(IsVip and "crown" or "person", Footer, 24, IsVip and C.Yellow or C.Gray, UDim2.fromOffset(12, 16))
    Text(Footer, "v2.0.0", UDim2.fromOffset(46, 10), UDim2.new(1, -50, 0, 18), 11, C.White, BOLD)
    Text(Footer, IsVip and "Premium Edition" or "Free Edition", UDim2.fromOffset(46, 28), UDim2.new(1, -50, 0, 16), 10, C.Gray)

    local Content = New("Frame", {
        Size = UDim2.new(1, -170, 1, 0),
        Position = UDim2.fromOffset(170, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = MainWindow,
    })

    local DragStrip = New("Frame", {
        Size = UDim2.new(1, 0, 0, 74),
        BackgroundTransparency = 1,
        Parent = Content,
    })
    MakeDraggable(DragStrip, MainWindow, WindowScale)

    local Title = Text(Content, "Welcome Back!", UDim2.fromOffset(24, 14), UDim2.new(1, -260, 0, 30), 24, C.White, BOLD)
    local Subtitle = Text(Content, "Control everything, your way.", UDim2.fromOffset(24, 44), UDim2.new(1, -260, 0, 20), 13, C.Gray)

    local Pill = New("Frame", {
        Size = UDim2.fromOffset(160, 40),
        Position = UDim2.new(1, -222, 0, 16),
        Parent = Content,
    })
    Panelize(Pill, 12, 0.5)
    local planColor = IsVip and C.Yellow or C.Gray
    Pill:FindFirstChildOfClass("UIStroke").Color = planColor
    Pill:FindFirstChildOfClass("UIStroke").Transparency = 0.65
    MakeIcon(IsVip and "crown" or "person", Pill, 22, planColor, UDim2.fromOffset(12, 9))
    Text(Pill, IsVip and "Premium User" or "Free User", UDim2.fromOffset(44, 0), UDim2.new(1, -48, 1, 0), 13, planColor, BOLD)

    local CloseBtn = New("TextButton", {
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -48, 0, 19),
        BackgroundColor3 = C.Card2,
        BackgroundTransparency = 0.35,
        Text = "",
        AutoButtonColor = false,
        Parent = Content,
    })
    Round(CloseBtn, 17)
    Stroke(CloseBtn, C.Stroke, 1, 0.5)
    local CloseIcon = MakeIcon("close", CloseBtn, 14, C.White, CENTER_POS, CENTER)
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, 0.12, { BackgroundColor3 = C.Red, BackgroundTransparency = 0 })
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, 0.12, { BackgroundColor3 = C.Card2, BackgroundTransparency = 0.35 })
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        SetUIVisible(false)
    end)

    local TabList = {
        { "Home", "home", "Welcome Back!", "Control everything, your way." },
        { "ESP", "eye", "ESP Settings", "Configure visual markers." },
        { "Movement", "move", "Movement", "Character movement configuration." },
        { "Utility", "cube", "Utility", "Quick actions and experience tools." },
        { "Settings", "gear", "Settings", "Personalize your workspace." },
        { "Interface", "monitor", "Interface", "Window appearance options." },
        { "System", "info", "System", "Information and unload." },
    }

    local Pages = {}
    local Tabs = {}
    local BottomTabs = {}

    for _, info in ipairs(TabList) do
        local page = New("ScrollingFrame", {
            Name = info[1],
            Size = UDim2.new(1, 0, 1, -76),
            Position = UDim2.fromOffset(0, 76),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = C.Gray,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            Visible = info[1] == "Home",
            Parent = Content,
        })
        if info[1] ~= "Home" then
            New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
                PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 16),
                Parent = page,
            })
        end
        Pages[info[1]] = page
    end

    local function SelectTab(name)
        State.CurrentTab = name

        for pageName, page in pairs(Pages) do
            page.Visible = pageName == name
        end

        for _, info in ipairs(TabList) do
            if info[1] == name then
                Title.Text = info[3]
                Subtitle.Text = info[4]
            end
        end

        for tabName, t in pairs(Tabs) do
            local sel = tabName == name
            Tween(t.Button, 0.15, { BackgroundTransparency = sel and 0 or 1 })
            t.Stroke.Transparency = sel and 0.3 or 1
            t.Bar.Visible = sel
            SetIconColor(t.Icon, sel and C.White or C.Gray)
            t.Label.TextColor3 = sel and C.White or C.Gray
            t.Label.Font = sel and BOLD or FONT
        end

        for tabName, b in pairs(BottomTabs) do
            local sel = tabName == name
            Tween(b.Button, 0.15, { BackgroundTransparency = sel and 0 or 1 })
            b.Bar.Visible = sel
            SetIconColor(b.Icon, sel and C.White or C.Gray)
        end
    end

    for i, info in ipairs(TabList) do
        local b = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = C.Card2,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = Nav,
        })
        Round(b, 10)
        local st = Stroke(b, C.White, 1, 1)
        local bar = New("Frame", {
            Size = UDim2.fromOffset(3, 22),
            Position = UDim2.fromOffset(0, 7),
            BackgroundColor3 = C.White,
            BorderSizePixel = 0,
            Visible = false,
            Parent = b,
        })
        Round(bar, 2)
        local icon = MakeIcon(info[2], b, 20, C.Gray, UDim2.fromOffset(14, 8))
        local label = Text(b, info[1], UDim2.fromOffset(46, 0), UDim2.new(1, -50, 1, 0), 13, C.Gray)

        Tabs[info[1]] = { Button = b, Stroke = st, Bar = bar, Icon = icon, Label = label }
        b.MouseButton1Click:Connect(function() SelectTab(info[1]) end)
    end

    local ON_POS = UDim2.new(1, -21, 0.5, -9)
    local OFF_POS = UDim2.new(0, 3, 0.5, -9)

    local function Switch(parent, pos, default, cb)
        local sw = New("Frame", {
            Size = UDim2.fromOffset(44, 24),
            Position = pos,
            BackgroundColor3 = default and C.Green or C.Stroke,
            Parent = parent,
        })
        Round(sw, 12)
        local dot = New("Frame", {
            Size = UDim2.fromOffset(18, 18),
            Position = default and ON_POS or OFF_POS,
            BackgroundColor3 = C.White,
            Parent = sw,
        })
        Round(dot, 9)
        local hit = New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Parent = sw,
        })

        local on = default
        local obj = {}

        function obj.Set(v, silent)
            on = v
            Tween(sw, 0.15, { BackgroundColor3 = on and C.Green or C.Stroke })
            Tween(dot, 0.15, { Position = on and ON_POS or OFF_POS })
            if cb and not silent then cb(on) end
        end

        function obj.Get() return on end

        hit.MouseButton1Click:Connect(function() obj.Set(not on) end)
        return obj
    end

    local function Toggle(page, title, desc, default, order, cb)
        local row = New("Frame", {
            Size = UDim2.new(1, 0, 0, 56),
            LayoutOrder = order,
            Parent = page,
        })
        Panelize(row, 12, 0.5)
        Text(row, title, UDim2.fromOffset(14, 8), UDim2.new(1, -90, 0, 20), 13, C.White, BOLD)
        Text(row, desc or "", UDim2.fromOffset(14, 29), UDim2.new(1, -90, 0, 18), 10, C.Gray)

        local obj = Switch(row, UDim2.new(1, -58, 0.5, -12), default, cb)

        local hit = New("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            Parent = row,
        })
        hit.MouseButton1Click:Connect(function() obj.Set(not obj.Get()) end)
        return obj
    end

    local function Action(page, title, order, cb)
        local b = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = C.Card,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = page,
        })
        Round(b, 12)
        Stroke(b, C.Stroke, 1, 0.5)
        Text(b, title, UDim2.fromOffset(14, 0), UDim2.new(1, -50, 1, 0), 12, C.White, BOLD)
        MakeIcon("chev", b, 16, C.Gray, UDim2.new(1, -30, 0.5, -8))
        b.MouseEnter:Connect(function() Tween(b, 0.12, { BackgroundColor3 = C.Card2 }) end)
        b.MouseLeave:Connect(function() Tween(b, 0.12, { BackgroundColor3 = C.Card }) end)
        b.MouseButton1Click:Connect(function() if cb then cb() end end)
        return b
    end

    local function InfoRow(page, title, value, order)
        local row = New("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            LayoutOrder = order,
            Parent = page,
        })
        Panelize(row, 12, 0.5)
        Text(row, title, UDim2.fromOffset(14, 0), UDim2.new(0.5, 0, 1, 0), 12, C.Gray, BOLD)
        Text(row, value, UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, -14, 1, 0), 12, C.White, BOLD, Enum.TextXAlignment.Right)
    end

    local function Slider(parent, title, min, max, default, order, cb, card)
        local pad = card and 14 or 0
        local top = card and 8 or 0

        local row = New("Frame", {
            Size = UDim2.new(1, 0, 0, card and 66 or 54),
            BackgroundTransparency = card and 0 or 1,
            LayoutOrder = order,
            Parent = parent,
        })
        if card then Panelize(row, 12, 0.5) end

        Text(row, title, UDim2.fromOffset(pad, top), UDim2.new(1, -90, 0, 28), 13, C.White, BOLD)

        local vbox = New("Frame", {
            Size = UDim2.fromOffset(60, 28),
            Position = UDim2.new(1, -pad - 60, 0, top),
            BackgroundColor3 = C.Card2,
            Parent = row,
        })
        Round(vbox, 8)
        Stroke(vbox, C.Stroke, 1, 0.5)
        local vlabel = Text(vbox, tostring(default), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 13, C.White, BOLD, Enum.TextXAlignment.Center)

        local bar = New("Frame", {
            Size = UDim2.new(1, -2 * pad, 0, 5),
            Position = UDim2.new(0, pad, 0, top + 40),
            BackgroundColor3 = C.Stroke,
            Parent = row,
        })
        Round(bar, 3)
        local fill = New("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = C.White,
            Parent = bar,
        })
        Round(fill, 3)
        local knob = New("Frame", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(0, -8, 0.5, -8),
            BackgroundColor3 = C.White,
            Parent = bar,
        })
        Round(knob, 8)
        local hit = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            Position = UDim2.new(0, 0, 0.5, -14),
            BackgroundTransparency = 1,
            Text = "",
            Parent = bar,
        })

        local function SetPercent(p, silent)
            p = math.clamp(p, 0, 1)
            local value = math.floor(min + (max - min) * p + 0.5)
            fill.Size = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, -8, 0.5, -8)
            vlabel.Text = tostring(value)
            if cb and not silent then cb(value) end
        end

        SetPercent((default - min) / (max - min), true)

        local dragging = false
        local function FromX(x)
            SetPercent((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1))
        end

        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                FromX(input.Position.X)
            end
        end)

        Track(UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                FromX(input.Position.X)
            end
        end))

        Track(UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        return { Set = function(v) SetPercent((v - min) / (max - min), true) end }
    end

    local AutoFarmSwitch
    local Home = Pages.Home

    local HomeInner = New("Frame", {
        Size = UDim2.new(1, -28, 0, 410),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Parent = Home,
    })

    local Banner = New("Frame", {
        Size = UDim2.new(1, 0, 0, 190),
        BackgroundColor3 = C.White,
        ClipsDescendants = true,
        Parent = HomeInner,
    })
    Round(Banner, 16)
    Stroke(Banner, C.Stroke, 1.2, 0.2)
    Grad(Banner, Color3.fromRGB(30, 31, 38), Color3.fromRGB(10, 11, 14), 120)

    local rng = Random.new(11)
    for _ = 1, 28 do
        local sz = rng:NextInteger(1, 2)
        local s = New("Frame", {
            Size = UDim2.fromOffset(sz, sz),
            Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber()),
            BackgroundColor3 = C.White,
            BackgroundTransparency = rng:NextNumber(0.4, 0.85),
            BorderSizePixel = 0,
            Parent = Banner,
        })
        Round(s, 2)
    end

    local function Swoosh(x, y, w, rot)
        local f = New("Frame", {
            Size = UDim2.fromOffset(w, 3),
            Position = UDim2.fromScale(x, y),
            Rotation = rot,
            BackgroundColor3 = C.White,
            BorderSizePixel = 0,
            Parent = Banner,
        })
        Round(f, 2)
        New("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.35),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = f,
        })
    end
    Swoosh(0.05, 0.28, 220, 24)
    Swoosh(0.68, 0.22, 260, -18)
    Swoosh(0.30, 0.78, 200, -14)

    local Wordmark = Text(Banner, "YVONE", UDim2.fromOffset(0, 30), UDim2.new(1, 0, 0, 76), 66, C.White, BLACK, Enum.TextXAlignment.Center)
    Grad(Wordmark, C.White, Color3.fromRGB(120, 123, 133), 90)
    HubMark(Banner, 104, 20)

    local BarBg = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.fromOffset(280, 6),
        Position = UDim2.new(0.5, -30, 0, 148),
        BackgroundColor3 = C.Stroke,
        Parent = Banner,
    })
    Round(BarBg, 3)
    local BarFill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.White,
        Parent = BarBg,
    })
    Round(BarFill, 3)

    local BarStatus = Text(Banner, "Loading modules...", UDim2.new(0.5, -170, 0, 158), UDim2.fromOffset(280, 20), 12, C.White, FONT, Enum.TextXAlignment.Center)
    local BarPercent = Text(Banner, "0%", UDim2.new(0.5, 126, 0, 158), UDim2.fromOffset(50, 20), 12, C.White, FONT, Enum.TextXAlignment.Center)

    task.spawn(function()
        for p = 0, 100, 2 do
            if not MainGui or not MainGui.Parent then return end
            BarFill.Size = UDim2.new(p / 100, 0, 1, 0)
            BarPercent.Text = p .. "%"
            task.wait(0.03)
        end
        BarStatus.Text = "All modules loaded"
    end)

    local function InfoCard(i, iconName, iconColor, title, value, sub, valueColor)
        local card = New("Frame", {
            Size = UDim2.new(1 / 3, -8, 0, 82),
            Position = UDim2.new((i - 1) / 3, (i - 1) * 4, 0, 204),
            Parent = HomeInner,
        })
        Panelize(card, 14, 0.45)

        local ic = New("Frame", {
            Size = UDim2.fromOffset(46, 46),
            Position = UDim2.fromOffset(14, 18),
            BackgroundColor3 = C.Card2,
            Parent = card,
        })
        Round(ic, 23)
        MakeIcon(iconName, ic, 22, iconColor, CENTER_POS, CENTER)

        Text(card, title, UDim2.fromOffset(72, 12), UDim2.new(1, -78, 0, 16), 12, C.Gray)
        Text(card, value, UDim2.fromOffset(72, 29), UDim2.new(1, -78, 0, 20), 15, valueColor or C.White, BOLD)
        Text(card, sub, UDim2.fromOffset(72, 51), UDim2.new(1, -78, 0, 16), 11, C.Gray)
    end

    InfoCard(1, "person", C.Gray, "Player Info", Player.DisplayName, "ID: " .. Player.UserId)
    InfoCard(2, "gamepad", C.Gray, "Game Info", MapLabel, "Map supported")
    InfoCard(3, "dot", C.Green, "Status", "Ready", "All systems online", C.Green)

    local Quick = New("Frame", {
        Size = UDim2.new(1, 0, 0, 104),
        Position = UDim2.fromOffset(0, 298),
        Parent = HomeInner,
    })
    Panelize(Quick, 14, 0.5)

    MakeIcon("bolt", Quick, 18, C.White, UDim2.fromOffset(14, 13))
    Text(Quick, "Quick Access", UDim2.fromOffset(40, 8), UDim2.fromOffset(200, 28), 15, C.White, BOLD)

    local SeeAll = New("TextButton", {
        Size = UDim2.fromOffset(86, 28),
        Position = UDim2.new(1, -98, 0, 8),
        BackgroundTransparency = 1,
        Text = "",
        Parent = Quick,
    })
    Text(SeeAll, "See All", UDim2.fromOffset(0, 0), UDim2.fromOffset(56, 28), 12, C.White, FONT, Enum.TextXAlignment.Right)
    MakeIcon("arrow", SeeAll, 14, C.White, UDim2.fromOffset(64, 7))
    SeeAll.MouseButton1Click:Connect(function() SelectTab("Utility") end)

    local QuickRow = New("Frame", {
        Size = UDim2.new(1, -24, 0, 44),
        Position = UDim2.fromOffset(12, 46),
        BackgroundTransparency = 1,
        Parent = Quick,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = QuickRow,
    })

    local function QuickBtn(i, iconName, label, cb)
        local b = New("TextButton", {
            Size = UDim2.new(0.25, -6, 1, 0),
            BackgroundColor3 = C.Card2,
            BackgroundTransparency = 0.35,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = QuickRow,
        })
        Round(b, 11)
        Stroke(b, C.Stroke, 1, 0.6)

        local inner = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = b,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = inner,
        })
        local ic = MakeIcon(iconName, inner, 18, C.White)
        ic.LayoutOrder = 1
        local lb = Text(inner, label, UDim2.new(), UDim2.fromOffset(0, 18), 12, C.White)
        lb.AutomaticSize = Enum.AutomaticSize.X
        lb.LayoutOrder = 2

        b.MouseEnter:Connect(function() Tween(b, 0.12, { BackgroundTransparency = 0 }) end)
        b.MouseLeave:Connect(function() Tween(b, 0.12, { BackgroundTransparency = 0.35 }) end)
        b.MouseButton1Click:Connect(function() if cb then cb() end end)
    end

    QuickBtn(1, "eye", "ESP Settings", function() SelectTab("ESP") end)
    QuickBtn(2, "plane", "Fly Mode", function()
        if FlyPanel.Visible then
            if State.Fly then SetFly(false) end
            FlyPanel.Visible = false
        else
            SetFly(true)
        end
    end)
    QuickBtn(3, "pin", "Teleport", TeleportSafe)
    QuickBtn(4, "cube", "AutoFarm", function()
        if AutoFarmSwitch then AutoFarmSwitch.Set(not AutoFarmSwitch.Get()) end
    end)

    local ESPPage = Pages.ESP

    local ESPOpahSwitch, ESPItemSwitch, ESPDrawerSwitch

    if IsAtok then
        ESPDrawerSwitch = Toggle(ESPPage, "ESP Drawer", "Highlight drawers.", State.ESP_Drawer, 1, function(v)
            State.ESP_Drawer = v
            ApplyESPFlags()
            ScanESP()
        end)
    else
        ESPOpahSwitch = Toggle(ESPPage, "ESP Opah", "Highlight the Opah character.", State.ESP_Opah, 1, function(v)
            State.ESP_Opah = v
            ApplyESPFlags()
            ScanESP()
        end)

        ESPItemSwitch = Toggle(ESPPage, "ESP Key / Note", "Find keys, notes and passcodes.", State.ESP_Item, 2, function(v)
            State.ESP_Item = v
            ApplyESPFlags()
            ScanESP()
        end)
    end

    Toggle(ESPPage, "Show Name", "Display the target label.", State.ESP_Name, 3, function(v)
        State.ESP_Name = v
        UpdateESP()
    end)

    Toggle(ESPPage, "Show Box", "Display the target bounding box.", State.ESP_Box, 4, function(v)
        State.ESP_Box = v
        UpdateESP()
    end)

    Toggle(ESPPage, "Show Distance", "Display approximate distance.", State.ESP_Distance, 5, function(v)
        State.ESP_Distance = v
        UpdateESP()
    end)

    Action(ESPPage, "REFRESH ESP", 6, function()
        RefreshESP()
        Notify("ESP", "ESP refreshed.")
    end)

    Action(ESPPage, "DISABLE ALL ESP", 7, function()
        State.ESP_Opah = false
        State.ESP_Item = false
        State.ESP_Drawer = false
        if ESPOpahSwitch then ESPOpahSwitch.Set(false, true) end
        if ESPItemSwitch then ESPItemSwitch.Set(false, true) end
        if ESPDrawerSwitch then ESPDrawerSwitch.Set(false, true) end
        ClearESP()
        Notify("ESP", "All ESP disabled.")
    end)

    local MovePage = Pages.Movement

    local WalkSlider = Slider(MovePage, "Walk Speed", 16, 100, State.Speed, 1, function(v)
        State.Speed = v
        UpdateSpeed()
    end, true)

    local NoclipSwitch = Toggle(MovePage, "Noclip", "Disable character part collision.", false, 2, ToggleNoclip)

    local MoveFlySwitch = Toggle(MovePage, "Fly Mode", "Enable flight controls.", false, 3, SetFly)
    table.insert(FlySwitches, MoveFlySwitch)

    Action(MovePage, "RESET WALK SPEED", 4, function()
        State.Speed = 16
        WalkSlider.Set(16)
        UpdateSpeed()
    end)

    local UtilPage = Pages.Utility

    AutoFarmSwitch = Toggle(UtilPage, "Auto Farm Mode", "Show the farm panel and item visibility.", false, 1, function(v)
        State.AutoFarm = v

        if v then
            State.PreviousESP = { Opah = State.ESP_Opah, Item = State.ESP_Item, Mob = State.ESP_Drawer }
            if IsAtok then
                State.ESP_Drawer = true
                if ESPDrawerSwitch then ESPDrawerSwitch.Set(true, true) end
            else
                State.ESP_Opah = true
                State.ESP_Item = true
                ESPOpahSwitch.Set(true, true)
                ESPItemSwitch.Set(true, true)
            end
            RefreshESP()

            if FarmPanel then FarmPanel.Visible = true end
            SetFarmStatus("Ready", C.Green)
            Notify("Auto Farm", "Farm panel opened.")
        else
            SetFarmStatus("Idle", C.Gray)

            if State.PreviousESP then
                State.ESP_Opah = State.PreviousESP.Opah
                State.ESP_Item = State.PreviousESP.Item
                State.ESP_Drawer = State.PreviousESP.Mob
                if ESPOpahSwitch then ESPOpahSwitch.Set(State.ESP_Opah, true) end
                if ESPItemSwitch then ESPItemSwitch.Set(State.ESP_Item, true) end
                if ESPDrawerSwitch then ESPDrawerSwitch.Set(State.ESP_Drawer, true) end
                ApplyESPFlags()
                ScanESP()
            end

            if FarmPanel then FarmPanel.Visible = false end
            Notify("Auto Farm", "Farm panel closed.")
        end
    end)

    Action(UtilPage, "TELEPORT TO SAFE ZONE", 2, TeleportSafe)
    if IsAtok then
        if AtokTape then
            Action(UtilPage, "TELEPORT TO TAPE / PITA", 3, function() TeleportTape(true) end)
        else
            Action(UtilPage, "TELEPORT TO RANDOM DRAWER", 3, function() TeleportDrawer(true) end)
        end
    else
        Action(UtilPage, "TELEPORT TO KEY", 3, function() TeleportItem("key") end)
        Action(UtilPage, "TELEPORT TO NOTE", 4, function() TeleportItem("note") end)
    end
    Action(UtilPage, "REFRESH TARGET SCAN", 5, function()
        RefreshESP()
        TargetCache.Time = 0
        Notify("Scanner", "Target scan completed.")
    end)

    local SettingsPage = Pages.Settings

    Toggle(SettingsPage, "UI Animations", "Enable smooth transitions.", true, 1, function(v)
        State.Animations = v
    end)

    Toggle(SettingsPage, "Show FPS / Ping", "Display the stats pills.", true, 2, function(v)
        State.ShowStats = v
        if StatsHolder then StatsHolder.Visible = v end
    end)

    Action(SettingsPage, "RESET WALK SPEED", 3, function()
        State.Speed = 16
        WalkSlider.Set(16)
        UpdateSpeed()
        Notify("Settings", "Walk speed reset.")
    end)

    local InterfacePage = Pages.Interface

    Slider(InterfacePage, "Window Opacity", 0, 60, 0, 1, function(v)
        MainWindow.BackgroundTransparency = v / 100
    end, true)

    Action(InterfacePage, "RESET WINDOW POSITION", 2, function()
        MainWindow.Position = UDim2.new(0.5, 0, 0.5, -28)
        Notify("Interface", "Window position reset.")
    end)

    local SystemPage = Pages.System

    InfoRow(SystemPage, "Version", "v2.0.0 Premium Edition", 1)
    InfoRow(SystemPage, "Platform", UIS.TouchEnabled and "Android / Touch" or "Desktop", 2)
    InfoRow(SystemPage, "Player ID", tostring(Player.UserId), 3)
    InfoRow(SystemPage, "Map", MapLabel, 4)
    InfoRow(SystemPage, "Place ID", tostring(game.PlaceId), 5)
    InfoRow(SystemPage, "Access", IsVip and "VIP" or "Free", 6)

    FlyPanel = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.fromOffset(268, 300),
        Position = UDim2.new(1, -14, 0.5, -70),
        Visible = false,
        Parent = MainGui,
    })
    Panelize(FlyPanel, 18, 0.15)
    AddScale(FlyPanel)
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
        Parent = FlyPanel,
    })
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = FlyPanel })

    local FlyHead = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = FlyPanel,
    })
    MakeIcon("plane", FlyHead, 22, C.Gray, UDim2.fromOffset(0, 6))
    Text(FlyHead, "Fly Mode", UDim2.fromOffset(34, 0), UDim2.fromOffset(110, 34), 16, C.White, BOLD)

    local PanelSwitch = Switch(FlyHead, UDim2.new(1, -68, 0.5, -12), false, SetFly)
    table.insert(FlySwitches, PanelSwitch)

    local PanelClose = New("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -22, 0, -4),
        BackgroundTransparency = 1,
        Text = "",
        Parent = FlyHead,
    })
    MakeIcon("close", PanelClose, 13, C.White, CENTER_POS, CENTER)
    PanelClose.MouseButton1Click:Connect(function()
        if State.Fly then SetFly(false) end
        FlyPanel.Visible = false
    end)

    local FlyDesc = Text(FlyPanel, "Fly freely in the game.", UDim2.new(), UDim2.new(1, 0, 0, 26), 13, C.Gray)
    FlyDesc.LayoutOrder = 2

    Slider(FlyPanel, "Speed", 20, 150, State.FlySpeed, 3, function(v) State.FlySpeed = v end, false)
    Slider(FlyPanel, "Height", 10, 200, State.FlyHeight, 4, function(v) State.FlyHeight = v end, false)

    local HoldBtn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = C.Card,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 5,
        Parent = FlyPanel,
    })
    Round(HoldBtn, 12)
    Stroke(HoldBtn, C.Stroke, 1, 0.3)

    local HoldInner = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = HoldBtn,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = HoldInner,
    })
    local holdIcon = MakeIcon("pointer", HoldInner, 28, C.Gray)
    holdIcon.LayoutOrder = 1
    local holdText = Text(HoldInner, "Tap & Hold\nto Fly", UDim2.new(), UDim2.fromOffset(90, 40), 14, C.Gray)
    holdText.LayoutOrder = 2

    HoldBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if State.Fly then
                FlyHold = true
                Tween(HoldBtn, 0.1, { BackgroundColor3 = C.Card2 })
                SetIconColor(holdIcon, C.White)
            else
                Notify("Fly Mode", "Aktifkan Fly Mode dulu.", "err")
            end
        end
    end)

    Track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            FlyHold = false
            Tween(HoldBtn, 0.1, { BackgroundColor3 = C.Card })
            SetIconColor(holdIcon, C.Gray)
        end
    end))

    FarmPanel = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(250, 270),
        Position = UDim2.new(0, 14, 0.5, -20),
        Visible = false,
        Parent = MainGui,
    })
    Round(FarmPanel, 18)
    Stroke(FarmPanel, C.Stroke, 1.4, 0.15)
    FarmPanel.BackgroundColor3 = C.White
    Grad(FarmPanel, Color3.fromRGB(28, 29, 36), Color3.fromRGB(10, 11, 14), 120)
    local FarmScale = AddScale(FarmPanel)

    local FarmHeader = New("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        Parent = FarmPanel,
    })
    MakeDraggable(FarmHeader, FarmPanel, FarmScale)

    local FarmIconBg = New("Frame", {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.fromOffset(16, 12),
        BackgroundColor3 = C.Card2,
        Parent = FarmHeader,
    })
    Round(FarmIconBg, 10)
    MakeIcon("cube", FarmIconBg, 18, C.White, CENTER_POS, CENTER)

    Text(FarmHeader, "Auto Farm", UDim2.fromOffset(58, 10), UDim2.fromOffset(120, 20), 15, C.White, BOLD)
    local activeDot = New("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.fromOffset(58, 36),
        BackgroundColor3 = C.Green,
        BorderSizePixel = 0,
        Parent = FarmHeader,
    })
    Round(activeDot, 3)
    Text(FarmHeader, "Mode active", UDim2.fromOffset(70, 29), UDim2.fromOffset(110, 20), 10, C.Gray)

    local FarmClose = New("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -40, 0, 14),
        BackgroundColor3 = C.Card2,
        BackgroundTransparency = 0.4,
        Text = "",
        AutoButtonColor = false,
        Parent = FarmHeader,
    })
    Round(FarmClose, 14)
    MakeIcon("close", FarmClose, 12, C.White, CENTER_POS, CENTER)
    FarmClose.MouseEnter:Connect(function() Tween(FarmClose, 0.12, { BackgroundColor3 = C.Red, BackgroundTransparency = 0 }) end)
    FarmClose.MouseLeave:Connect(function() Tween(FarmClose, 0.12, { BackgroundColor3 = C.Card2, BackgroundTransparency = 0.4 }) end)
    FarmClose.MouseButton1Click:Connect(function()
        if AutoFarmSwitch then AutoFarmSwitch.Set(false) end
    end)

    New("Frame", {
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.fromOffset(16, 56),
        BackgroundColor3 = C.Stroke,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = FarmPanel,
    })

    local StatusCard = New("Frame", {
        Size = UDim2.new(1, -32, 0, 46),
        Position = UDim2.fromOffset(16, 68),
        BackgroundColor3 = C.Card,
        Parent = FarmPanel,
    })
    Round(StatusCard, 12)
    Stroke(StatusCard, C.Stroke, 1, 0.5)
    Text(StatusCard, "STATUS", UDim2.fromOffset(32, 6), UDim2.new(1, -40, 0, 14), 9, C.Muted, BOLD)
    FarmStatusDot = New("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(14, 26),
        BackgroundColor3 = C.Gray,
        BorderSizePixel = 0,
        Parent = StatusCard,
    })
    Round(FarmStatusDot, 4)
    FarmStatusText = Text(StatusCard, "Idle", UDim2.fromOffset(32, 20), UDim2.new(1, -40, 0, 20), 12, C.White, BOLD)

    local AutoBtn = New("TextButton", {
        Size = UDim2.new(1, -32, 0, 58),
        Position = UDim2.fromOffset(16, 124),
        Text = "",
        AutoButtonColor = false,
        Parent = FarmPanel,
    })
    Panelize(AutoBtn, 12, 0.4)
    local farmIcon, farmTitle, farmSub = "key", "Auto Teleport", "Key first, then Note"
    if IsAtok and AtokTape then
        farmIcon, farmTitle, farmSub = "tape", "Teleport Tape", "Random pita / tape each click"
    elseif IsAtok then
        farmIcon, farmTitle, farmSub = "drawer", "Teleport Drawer", "Random drawer each click"
    end
    MakeIcon(farmIcon, AutoBtn, 22, C.Yellow, UDim2.fromOffset(14, 18))
    Text(AutoBtn, farmTitle, UDim2.fromOffset(46, 10), UDim2.new(1, -90, 0, 20), 13, C.White, BOLD)
    Text(AutoBtn, farmSub, UDim2.fromOffset(46, 30), UDim2.new(1, -90, 0, 18), 10, C.Gray)
    MakeIcon("arrow", AutoBtn, 16, C.Gray, UDim2.new(1, -32, 0.5, -8))
    AutoBtn.MouseEnter:Connect(function() Tween(AutoBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(205, 206, 212) }) end)
    AutoBtn.MouseLeave:Connect(function() Tween(AutoBtn, 0.12, { BackgroundColor3 = C.White }) end)
    AutoBtn.MouseButton1Click:Connect(FarmTeleport)

    local SafeBtn = New("TextButton", {
        Size = UDim2.new(1, -32, 0, 58),
        Position = UDim2.fromOffset(16, 192),
        BackgroundColor3 = C.White,
        Text = "",
        AutoButtonColor = false,
        Parent = FarmPanel,
    })
    Round(SafeBtn, 12)
    MakeIcon("shield", SafeBtn, 24, C.Bg, UDim2.fromOffset(14, 17))
    Text(SafeBtn, "Safe Zone", UDim2.fromOffset(48, 10), UDim2.new(1, -60, 0, 20), 13, C.Bg, BOLD)
    Text(SafeBtn, (IsAtok and (AtokTape and "Back to your spawn" or "Fixed Atok position")) or "Teleport to the safe area", UDim2.fromOffset(48, 30), UDim2.new(1, -60, 0, 18), 10, Color3.fromRGB(70, 72, 82))
    SafeBtn.MouseEnter:Connect(function() Tween(SafeBtn, 0.12, { BackgroundColor3 = C.Gray }) end)
    SafeBtn.MouseLeave:Connect(function() Tween(SafeBtn, 0.12, { BackgroundColor3 = C.White }) end)
    SafeBtn.MouseButton1Click:Connect(TeleportSafe)

    BottomNav = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.fromOffset(390, 64),
        Position = UDim2.new(0.5, 0, 1, -12),
        Parent = MainGui,
    })
    Panelize(BottomNav, 20, 0.15)
    AddScale(BottomNav)

    for i = 1, 5 do
        local info = TabList[i]
        local b = New("TextButton", {
            Size = UDim2.fromOffset(70, 52),
            Position = UDim2.fromOffset(10 + (i - 1) * 74, 6),
            BackgroundColor3 = C.Card2,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = BottomNav,
        })
        Round(b, 14)
        local icon = MakeIcon(info[2], b, 28, C.Gray, UDim2.new(0.5, 0, 0.5, -3), CENTER)
        local bar = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.fromOffset(40, 3),
            Position = UDim2.new(0.5, 0, 1, -1),
            BackgroundColor3 = C.White,
            BorderSizePixel = 0,
            Visible = false,
            Parent = b,
        })
        Round(bar, 2)
        BottomTabs[info[1]] = { Button = b, Bar = bar, Icon = icon }
        b.MouseButton1Click:Connect(function() SelectTab(info[1]) end)
    end

    StatsHolder = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(250, 34),
        Position = UDim2.new(1, -14, 0, 14),
        BackgroundTransparency = 1,
        Parent = MainGui,
    })
    AddScale(StatsHolder)

    local FpsPill = New("Frame", {
        Size = UDim2.fromOffset(98, 34),
        Position = UDim2.fromOffset(18, 0),
        BackgroundColor3 = C.Bg,
        BackgroundTransparency = 0.2,
        Parent = StatsHolder,
    })
    Round(FpsPill, 17)
    local FpsLabel = Text(FpsPill, "FPS: --", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 14, C.White, BOLD, Enum.TextXAlignment.Center)

    local PingPill = New("Frame", {
        Size = UDim2.fromOffset(124, 34),
        Position = UDim2.fromOffset(126, 0),
        BackgroundColor3 = C.Bg,
        BackgroundTransparency = 0.2,
        Parent = StatsHolder,
    })
    Round(PingPill, 17)
    local PingLabel = Text(PingPill, "Ping: --", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), 14, C.White, BOLD, Enum.TextXAlignment.Center)
    PingLabel.RichText = true

    local openCam = Workspace.CurrentCamera
    local openVS = openCam and openCam.ViewportSize or Vector2.new(1280, 720)

    OpenButton = New("TextButton", {
        Size = UDim2.fromOffset(64, 36),
        Position = UDim2.fromOffset(16, math.floor(openVS.Y / 2 - 18)),
        BackgroundColor3 = C.White,
        Text = "YVONE",
        TextColor3 = C.Bg,
        TextSize = 12,
        Font = BLACK,
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 50,
        Parent = MainGui,
    })
    Round(OpenButton, 8)
    Stroke(OpenButton, C.Stroke, 1.4, 0.2)
    OpenButton.MouseEnter:Connect(function() Tween(OpenButton, 0.12, { BackgroundColor3 = C.Gray }) end)
    OpenButton.MouseLeave:Connect(function() Tween(OpenButton, 0.12, { BackgroundColor3 = C.White }) end)

    local openActive, openMoved = false, false
    local openStart, openOrigin

    OpenButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            openActive = true
            openMoved = false
            openStart = input.Position
            openOrigin = Vector2.new(OpenButton.Position.X.Offset, OpenButton.Position.Y.Offset)
        end
    end)

    Track(UIS.InputChanged:Connect(function(input)
        if not openActive then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local dx = input.Position.X - openStart.X
        local dy = input.Position.Y - openStart.Y
        if math.abs(dx) + math.abs(dy) > 8 then openMoved = true end

        if openMoved then
            local cam = Workspace.CurrentCamera
            local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
            local nx = math.clamp(openOrigin.X + dx, 0, math.max(vs.X - OpenButton.AbsoluteSize.X, 0))
            local ny = math.clamp(openOrigin.Y + dy, 0, math.max(vs.Y - OpenButton.AbsoluteSize.Y, 0))
            OpenButton.Position = UDim2.fromOffset(nx, ny)
        end
    end))

    Track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            openActive = false
        end
    end))

    OpenButton.MouseButton1Click:Connect(function()
        if openMoved then
            openMoved = false
            return
        end
        SetUIVisible(true)
    end)

    local Modal = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.35,
        Visible = false,
        ZIndex = 300,
        Parent = MainGui,
    })

    local ModalBox = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(320, 170),
        BackgroundColor3 = C.Panel,
        ZIndex = 301,
        Parent = Modal,
    })
    Round(ModalBox, 16)
    Stroke(ModalBox, C.Stroke, 1.3)
    AddScale(ModalBox)

    Text(ModalBox, "Unload YVONE Hub?", UDim2.fromOffset(18, 18), UDim2.new(1, -36, 0, 26), 17, C.White, BOLD).ZIndex = 302
    Text(ModalBox, "This removes the interface and all active features.", UDim2.fromOffset(18, 50), UDim2.new(1, -36, 0, 30), 12, C.Gray).ZIndex = 302

    local function Cleanup()
        if State.Closing then return end
        State.Closing = true

        State.Fly = false
        State.Noclip = false
        State.AutoFarm = false

        ClearFly()
        local h = Humanoid()
        if h then h.PlatformStand = false end

        Disconnect(NoclipConnection)
        NoclipConnection = nil

        RestoreCollision()
        ClearESP()
        DisconnectAll()

        if WarnGui then WarnGui:Destroy() WarnGui = nil end
        if MainGui then MainGui:Destroy() end
    end

    local YesBtn = Btn(ModalBox, "YES, UNLOAD", UDim2.fromOffset(136, 40), UDim2.fromOffset(18, 112), Cleanup, true)
    YesBtn.ZIndex = 302
    local NoBtn = Btn(ModalBox, "CANCEL", UDim2.fromOffset(136, 40), UDim2.fromOffset(166, 112), function()
        Modal.Visible = false
    end)
    NoBtn.ZIndex = 302

    Action(SystemPage, "UNLOAD YVONE HUB", 7, function()
        Modal.Visible = true
    end)

    local frames = 0
    local fps = 0
    local fpsTimer = os.clock()

    Track(RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - fpsTimer >= 1 then
            fps = frames
            frames = 0
            fpsTimer = now
        end
    end))

    task.spawn(function()
        while MainGui and MainGui.Parent do
            task.wait(1)

            local ping = 0
            pcall(function() ping = math.floor(Player:GetNetworkPing() * 1000) end)

            local col = C.Green
            if ping >= 150 then col = C.Red elseif ping >= 80 then col = C.Yellow end

            FpsLabel.Text = "FPS: " .. fps
            PingLabel.Text = string.format(
                'Ping: <font color="rgb(%d,%d,%d)">%dms</font>',
                math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255), ping
            )

            if State.Speed ~= 16 then UpdateSpeed() end
        end
    end)

    task.spawn(function()
        while MainGui and MainGui.Parent do
            task.wait(UPDATE_INTERVAL)
            if State.ESP_Opah or State.ESP_Item or State.ESP_Drawer then UpdateESP() end
        end
    end)

    task.spawn(function()
        while MainGui and MainGui.Parent do
            task.wait(SCAN_INTERVAL)
            if State.ESP_Opah or State.ESP_Item or State.ESP_Drawer then ScanESP() end
        end
    end)

    Track(Workspace.DescendantAdded:Connect(function(inst)
        if not (State.ESP_Opah or State.ESP_Item or State.ESP_Drawer) then return end

        local nameOk
        if IsAtok then
            nameOk = IsDrawerName(inst)
        else
            nameOk = GetCategory(inst.Name) ~= nil
        end
        if not nameOk then return end

        task.delay(0.3, function()
            if not MainGui or not MainGui.Parent then return end
            if not inst.Parent or ESPObjects[inst] then return end

            local cat = Classify(inst)
            if not cat or not CategoryEnabled(cat) then return end

            local root = Root()
            local part = GetPart(inst)
            if root and part and (root.Position - part.Position).Magnitude <= MAX_DISTANCE then
                CreateESP(inst)
            end
        end)
    end))

    Track(Workspace.DescendantRemoving:Connect(function(inst)
        if ESPObjects[inst] then RemoveESP(inst) end
        if inst == CachedSafeZone then CachedSafeZone = nil end
    end))

    Track(Player.CharacterAdded:Connect(function()
        ClearESP()
        ClearFly()
        RestoreCollision()
        CachedSafeZone = nil
        TargetCache.Time = 0

        State.Fly = false
        State.Noclip = false
        SyncFlySwitches(false)
        NoclipSwitch.Set(false, true)
        Disconnect(NoclipConnection)
        NoclipConnection = nil

        task.wait(1)
        if not MainGui or not MainGui.Parent then return end

        UpdateSpeed()
        if State.ESP_Opah or State.ESP_Item or State.ESP_Drawer then RefreshESP() end
        Notify("Character", "Character successfully loaded.")
    end))

    ApplyScale()
    Track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(ApplyScale))
    if Workspace.CurrentCamera then
        Track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyScale))
    end

    SelectTab("Home")

    TopToast("YVONE Hub", "Welcome back!")
    Notify("Map detected", MapLabel .. " (" .. (IsVip and "VIP" or "Free") .. ")")

    if IsAtok then
        warn("[YVONE] Di map Atok tidak ada ESP Atok (mob). Hanya ESP Drawer yang tersedia.")

        WarnGui = New("ScreenGui", {
            Name = "YvoneWarning",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 500,
            Parent = PlayerGui,
        })

        local Warn = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.fromOffset(460, 84),
            Position = UDim2.new(0.5, 0, 0, 96),
            BackgroundColor3 = C.Panel,
            Parent = WarnGui,
        })
        Round(Warn, 16)
        Stroke(Warn, C.Yellow, 1.4, 0.2)
        AddScale(Warn)
        ApplyScale()

        local wi = New("Frame", {
            Size = UDim2.fromOffset(40, 40),
            Position = UDim2.fromOffset(14, 22),
            BackgroundColor3 = C.Yellow,
            Parent = Warn,
        })
        Round(wi, 20)
        MakeIcon("warn", wi, 22, C.Bg, CENTER_POS, CENTER)

        Text(Warn, "Peringatan", UDim2.fromOffset(66, 10), UDim2.new(1, -170, 0, 22), 15, C.Yellow, BOLD)
        local wmsg = Text(Warn, "Di map Atok tidak ada ESP Atok (mob). Hanya ESP Drawer yang tersedia.", UDim2.fromOffset(66, 34), UDim2.new(1, -170, 0, 42), 12, C.White)
        wmsg.TextWrapped = true
        wmsg.TextYAlignment = Enum.TextYAlignment.Top

        local HideBtn = New("TextButton", {
            Size = UDim2.fromOffset(76, 36),
            Position = UDim2.new(1, -90, 0.5, -18),
            BackgroundColor3 = C.Card2,
            Text = "Hide",
            TextColor3 = C.White,
            TextSize = 13,
            Font = BOLD,
            AutoButtonColor = false,
            Parent = Warn,
        })
        Round(HideBtn, 10)
        Stroke(HideBtn, C.Stroke, 1, 0.4)
        HideBtn.MouseEnter:Connect(function() Tween(HideBtn, 0.12, { BackgroundColor3 = C.Stroke }) end)
        HideBtn.MouseLeave:Connect(function() Tween(HideBtn, 0.12, { BackgroundColor3 = C.Card2 }) end)
        HideBtn.MouseButton1Click:Connect(function()
            if WarnGui then
                WarnGui:Destroy()
                WarnGui = nil
            end
        end)
    end
end

--==============================================================
-- ACCESS SELECTION (FREE / VIP) + LAUNCH
--==============================================================

local function StartLaunch(vip)
    if State.Launched then return end
    IsVip = vip
    Tween(LoadCard, 0.2, { Size = UDim2.fromOffset(360, 240) })
    task.wait(0.2)
    Launch()
end

local function BuildAccessSelect()
    FitLoadScale()
    LoadStatus.Visible = false
    LoadBar.Visible = false
    Tween(LoadCard, 0.3, { Size = UDim2.fromOffset(440, 310) })

    local SelectView = New("Frame", {
        Size = UDim2.new(1, -40, 0, 170),
        Position = UDim2.fromOffset(20, 126),
        BackgroundTransparency = 1,
        Parent = LoadCard,
    })

    local PassView = New("Frame", {
        Size = UDim2.new(1, -40, 0, 170),
        Position = UDim2.fromOffset(20, 126),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = LoadCard,
    })

    Text(SelectView, "Choose your access", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 20), 12, C.Gray, BOLD, Enum.TextXAlignment.Center)

    local function OptionCard(side, iconName, iconColor, title, desc, tag, accent, onClick)
        local card = New("TextButton", {
            Size = UDim2.new(0.5, -6, 0, 136),
            Position = (side == 0) and UDim2.fromOffset(0, 28) or UDim2.new(0.5, 6, 0, 28),
            Text = "",
            AutoButtonColor = false,
            Parent = SelectView,
        })
        Panelize(card, 14, 0.35)
        local st = card:FindFirstChildOfClass("UIStroke")

        local ic = New("Frame", {
            Size = UDim2.fromOffset(44, 44),
            Position = UDim2.new(0.5, -22, 0, 14),
            BackgroundColor3 = C.Card2,
            Parent = card,
        })
        Round(ic, 22)
        MakeIcon(iconName, ic, 22, iconColor, CENTER_POS, CENTER)

        Text(card, title, UDim2.fromOffset(0, 64), UDim2.new(1, 0, 0, 20), 14, accent, BOLD, Enum.TextXAlignment.Center)

        local d = Text(card, desc, UDim2.fromOffset(10, 86), UDim2.new(1, -20, 0, 28), 10, C.Gray, FONT, Enum.TextXAlignment.Center)
        d.TextWrapped = true
        d.TextYAlignment = Enum.TextYAlignment.Top

        Text(card, tag, UDim2.fromOffset(0, 114), UDim2.new(1, 0, 0, 16), 9, accent, BOLD, Enum.TextXAlignment.Center)

        card.MouseEnter:Connect(function()
            Tween(st, 0.15, { Color = accent, Transparency = 0 })
        end)
        card.MouseLeave:Connect(function()
            Tween(st, 0.15, { Color = C.Stroke, Transparency = 0.35 })
        end)
        card.MouseButton1Click:Connect(onClick)
    end

    MakeIcon("crown", PassView, 20, C.Yellow, UDim2.new(0.5, -66, 0, 1))
    Text(PassView, "VIP Access", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 22), 16, C.Yellow, BOLD, Enum.TextXAlignment.Center)
    Text(PassView, "Enter the password for instant teleport", UDim2.fromOffset(0, 24), UDim2.new(1, 0, 0, 18), 11, C.Gray, FONT, Enum.TextXAlignment.Center)

    local box = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.fromOffset(0, 52),
        BackgroundColor3 = C.Card,
        Text = "",
        PlaceholderText = "Password",
        PlaceholderColor3 = C.Muted,
        TextColor3 = C.White,
        TextSize = 18,
        Font = BOLD,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = PassView,
    })
    Round(box, 10)
    local boxStroke = Stroke(box, C.Stroke, 1.2, 0.2)

    local msg = Text(PassView, "", UDim2.fromOffset(0, 98), UDim2.new(1, 0, 0, 18), 11, C.Red, BOLD, Enum.TextXAlignment.Center)

    local real = ""
    local masking = false
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if masking then return end
        masking = true
        local t = box.Text
        if #t > #real then
            real = real .. string.sub(t, #real + 1)
        elseif #t < #real then
            real = string.sub(real, 1, #t)
        end
        box.Text = string.rep("*", #real)
        masking = false
    end)

    local unlocking = false

    local function TryUnlock()
        if unlocking then return end
        unlocking = true

        local submittedKey = real

        msg.TextColor3 = C.Gray
        msg.Text = "Memeriksa key..."
        boxStroke.Color = C.Stroke

        task.spawn(function()
            local ok, _plan, reason = VerifyVIP(submittedKey)

            if ok then
                msg.TextColor3 = C.Green
                msg.Text = "Access granted"
                boxStroke.Color = C.Green
                task.wait(0.5)
                StartLaunch(true)
            else
                msg.TextColor3 = C.Red
                msg.Text = reason or "Key salah, coba lagi."
                boxStroke.Color = C.Red

                real = ""
                masking = true
                box.Text = ""
                masking = false

                for i = 1, 4 do
                    box.Position = UDim2.fromOffset((i % 2 == 0) and -6 or 6, 52)
                    task.wait(0.04)
                end
                box.Position = UDim2.fromOffset(0, 52)

                unlocking = false
            end
        end)
    end

    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then TryUnlock() end
    end)

    Btn(PassView, "BACK", UDim2.new(0.38, -6, 0, 40), UDim2.fromOffset(0, 124), function()
        if unlocking then return end
        real = ""
        masking = true
        box.Text = ""
        masking = false
        msg.Text = ""
        boxStroke.Color = C.Stroke
        PassView.Visible = false
        SelectView.Visible = true
    end)

    Btn(PassView, "UNLOCK VIP", UDim2.new(0.62, -6, 0, 40), UDim2.new(0.38, 6, 0, 124), TryUnlock, true)

    OptionCard(0, "person", C.Gray, "Free User", "All features, 2s wait on teleport", "NO PASSWORD", C.White, function()
        StartLaunch(false)
    end)

    OptionCard(1, "crown", C.Yellow, "VIP User", "All features, instant teleport", "PASSWORD REQUIRED", C.Yellow, function()
        SelectView.Visible = false
        PassView.Visible = true
        task.defer(function()
            pcall(function() box:CaptureFocus() end)
        end)
    end)
end

OnLoadingDone = BuildAccessSelect
if LoadingReady then BuildAccessSelect() end
