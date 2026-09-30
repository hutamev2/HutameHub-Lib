--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    HUTAME HUB LIBRARY                        ║
    ║        Informant-inspired · Two-Column · Precision         ║
    ╚══════════════════════════════════════════════════════════════╝

    loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))()
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────
local function tw(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), props):Play()
end

local function safeParent()
    local ok, cg = pcall(function() return CoreGui end)
    return (ok and cg) or LocalPlayer:WaitForChild("PlayerGui")
end

local function ripple(btn, accent)
    local rip = Instance.new("Frame")
    rip.Size = UDim2.new(0,0,0,0)
    rip.AnchorPoint = Vector2.new(0.5,0.5)
    rip.Position = UDim2.new(0.5,0,0.5,0)
    rip.BackgroundColor3 = accent
    rip.BackgroundTransparency = 0.6
    rip.BorderSizePixel = 0
    rip.ZIndex = btn.ZIndex + 10
    rip.Parent = btn
    Instance.new("UICorner", rip).CornerRadius = UDim.new(1,0)
    tw(rip, 0.35, {Size = UDim2.new(0,120,0,120), BackgroundTransparency = 1})
    game:GetService("Debris"):AddItem(rip, 0.4)
end

-- ─────────────────────────────────────────────
-- Theme
-- ─────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(22, 22, 31),
    Surface     = Color3.fromRGB(24, 25, 37),
    Card        = Color3.fromRGB(22, 22, 31),
    Element     = Color3.fromRGB(29, 30, 43),
    ElementHov  = Color3.fromRGB(39, 40, 56),
    Border      = Color3.fromRGB(50, 50, 61),
    BorderLight = Color3.fromRGB(69, 69, 83),
    Text        = Color3.fromRGB(235, 235, 235),
    TextDim     = Color3.fromRGB(195, 195, 202),
    TextMute    = Color3.fromRGB(145, 145, 158),
    Accent      = Color3.fromRGB(103, 89, 179),
    AccentDim   = Color3.fromRGB(65, 57, 111),
    White       = Color3.fromRGB(245, 245, 245),
    Black       = Color3.fromRGB(10, 10, 13),
}

-- Lists participate in section layout instead of floating over following rows.
local function dropdownLayout(container, list, config)
    local visibleItems = math.clamp(math.floor(tonumber(config.MaxVisibleItems) or 6), 1, 20)
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.ScrollBarThickness = 4
    list.ScrollBarImageColor3 = T.TextDim
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.None
    container.ZIndex = 2
    return function(opened, count)
        -- 20px rows, 1px gaps, 3px top and bottom padding.
        local contentHeight = 6 + count * 20 + math.max(0, count - 1)
        local viewportHeight = math.min(contentHeight, 6 + visibleItems * 20 + visibleItems - 1)
        list.CanvasSize = UDim2.fromOffset(0, contentHeight)
        list.Size = UDim2.new(1, 0, 0, viewportHeight)
        list.Visible = opened
        list.CanvasPosition = Vector2.new(0, math.clamp(list.CanvasPosition.Y, 0, math.max(0, contentHeight - viewportHeight)))
        container.Size = UDim2.new(1, 0, 0, opened and (24 + viewportHeight) or 22)
    end
end

-- ─────────────────────────────────────────────
-- Library
-- ─────────────────────────────────────────────
local Library = {}
Library.__index = Library

function Library.new(config)
    config = config or {}
    local self = setmetatable({}, Library)

    self.Title       = config.Title    or "HutameHub"
    self.Version     = config.Version  or "v2.3"
    self.Accent      = config.Accent   or T.Accent
    self.ToggleKey   = config.ToggleKey or Enum.KeyCode.RightControl
    self.Tabs        = {}
    self.ActiveTab   = nil
    self._accentSubs = {}

    -- accent helper
    T.Accent    = self.Accent
    T.AccentDim = Color3.fromRGB(
        math.floor(self.Accent.R*255*0.6),
        math.floor(self.Accent.G*255*0.6),
        math.floor(self.Accent.B*255*0.6)
    )

    self:_build()

    -- ── Persistent Snow Effect on main UI ────────────────────────────────
    -- Optional atmosphere. Enable with SnowEffect = true.
    self._stopUISnow = nil
    if config.SnowEffect == true then
        -- Snow canvas sits behind everything inside MainFrame (ZIndex 1)
        local snowCanvas = Instance.new("Frame", self.MainFrame)
        snowCanvas.Name              = "SnowCanvas"
        snowCanvas.Size              = UDim2.new(1, 0, 1, 0)
        snowCanvas.BackgroundTransparency = 1
        snowCanvas.BorderSizePixel   = 0
        snowCanvas.ZIndex            = 1
        snowCanvas.ClipsDescendants  = true

        local flakes      = {}
        local connections = {}
        local active      = true
        local CHARS       = {"•", "·", "✦", "∗", "❄"}
        local MAX_FLAKES  = 40   -- lighter than splash (UI is interactive)

        local function spawnUIFlake(startY)
            if not active or #flakes >= MAX_FLAKES then return end
            local size   = math.random(4, 9)
            local dur    = math.random(50, 90) / 10   -- 5–9 s (slow, ambient)
            local flake  = Instance.new("TextLabel", snowCanvas)
            flake.BackgroundTransparency = 1
            flake.Font       = Enum.Font.Code
            flake.TextSize   = size
            flake.Text       = CHARS[math.random(#CHARS)]
            flake.ZIndex     = 1
            -- 80% white-ish, 20% accent-tinted
            flake.TextColor3 = math.random() > 0.8
                and Color3.fromRGB(
                    math.floor(self.Accent.R*255),
                    math.floor(self.Accent.G*255),
                    math.floor(self.Accent.B*255))
                or Color3.fromRGB(180, 190, 210)
            flake.TextTransparency = math.random(3, 7) / 10  -- 0.3–0.7 subtle
            local sx = math.random(1, 98) / 100
            local sy = startY or -0.04
            flake.Size     = UDim2.fromOffset(size, size)
            flake.Position = UDim2.new(sx, 0, sy, 0)
            table.insert(flakes, flake)
            local driftX = (math.random() - 0.5) * 0.06
            local fallDur = startY and ((1 - startY) * math.random(50, 90) / 10) or dur
            local tInfo   = TweenInfo.new(fallDur, Enum.EasingStyle.Linear)
            local t = TweenService:Create(flake, tInfo, {
                Position         = UDim2.new(sx + driftX, 0, 1.04, 0),
                TextTransparency = 0.9,
            })
            t:Play()
            t.Completed:Connect(function()
                if flake and flake.Parent then flake:Destroy() end
                for i, f in ipairs(flakes) do
                    if f == flake then table.remove(flakes, i) break end
                end
            end)
        end

        -- Pre-populate with flakes at random heights so it doesn't start empty
        for i = 1, 14 do
            task.delay(i * 0.08, function()
                if active then spawnUIFlake(math.random(0, 95) / 100) end
            end)
        end

        -- Continuous spawn loop (slower cadence than splash)
        local conn = RunService.Heartbeat:Connect(function()
            if active and math.random() < 0.045 then spawnUIFlake(nil) end
        end)
        table.insert(connections, conn)

        -- Keep accent color in sync
        self:_onAccent(function(c)
            -- new flakes will pick up the new color automatically
        end)

        -- Store stop function for Destroy
        self._stopUISnow = function()
            active = false
            for _, c in ipairs(connections) do c:Disconnect() end
            connections = {}
            for _, f in ipairs(flakes) do
                if f and f.Parent then
                    TweenService:Create(f, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                    game:GetService("Debris"):AddItem(f, 0.35)
                end
            end
            flakes = {}
        end
    end

    -- ── Loading Screen / Splash ───────────────────────────────────────────
    -- Full-screen animated splash shown before the main window appears.
    -- Opt out by passing LoadingScreen = false in config.
    if config.LoadingScreen ~= false then
        local splashTitle    = self.Title
        local splashSubtitle = self.Version
        local loadDur        = config.LoadingDuration or 1.8
        local sg             = self.ScreenGui
        local mf             = self.MainFrame

        local splash = Instance.new("Frame", sg)
        splash.Name             = "Splash"
        splash.Size             = UDim2.new(1,0,1,0)
        splash.BackgroundColor3 = T.BG
        splash.BorderSizePixel  = 0
        splash.ZIndex           = 100

        -- center card
        local lsCard = Instance.new("Frame", splash)
        lsCard.Size              = UDim2.fromOffset(280, 160)
        lsCard.Position          = UDim2.new(0.5,-140,0.5,-80)
        lsCard.BackgroundColor3  = T.Surface
        lsCard.BorderSizePixel   = 0
        lsCard.ZIndex            = 101
        Instance.new("UICorner", lsCard).CornerRadius = UDim.new(0,0)
        local lsStroke = Instance.new("UIStroke", lsCard)
        lsStroke.Color = T.Border; lsStroke.Thickness = 1; -- UIStroke inherits its parent stacking order

        -- accent top bar
        local lsAccent = Instance.new("Frame", lsCard)
        lsAccent.Size             = UDim2.new(1,0,0,2)
        lsAccent.BackgroundColor3 = self.Accent
        lsAccent.BorderSizePixel  = 0; lsAccent.ZIndex = 102
        Instance.new("UICorner", lsAccent).CornerRadius = UDim.new(0,0)
        self:_onAccent(function(c) lsAccent.BackgroundColor3 = c end)

        -- logo box
        local lsLogo = Instance.new("Frame", lsCard)
        lsLogo.Size             = UDim2.fromOffset(36,36)
        lsLogo.Position         = UDim2.new(0.5,-18,0,22)
        lsLogo.BackgroundColor3 = self.Accent
        lsLogo.BorderSizePixel  = 0; lsLogo.ZIndex = 102
        Instance.new("UICorner", lsLogo).CornerRadius = UDim.new(0,0)
        self:_onAccent(function(c) lsLogo.BackgroundColor3 = c end)
        local lsLogoLbl = Instance.new("TextLabel", lsLogo)
        lsLogoLbl.Size=UDim2.new(1,0,1,0); lsLogoLbl.BackgroundTransparency=1
        lsLogoLbl.Font=Enum.Font.Code; lsLogoLbl.TextSize=18
        lsLogoLbl.TextColor3=T.Black; lsLogoLbl.Text=string.sub(splashTitle,1,1)
        lsLogoLbl.ZIndex=103

        -- title / subtitle
        local lsTitleLbl = Instance.new("TextLabel", lsCard)
        lsTitleLbl.Size=UDim2.new(1,0,0,20); lsTitleLbl.Position=UDim2.fromOffset(0,66)
        lsTitleLbl.BackgroundTransparency=1; lsTitleLbl.Font=Enum.Font.Code
        lsTitleLbl.TextSize=15; lsTitleLbl.TextColor3=T.White
        lsTitleLbl.Text=splashTitle; lsTitleLbl.ZIndex=102

        local lsSubLbl = Instance.new("TextLabel", lsCard)
        lsSubLbl.Size=UDim2.new(1,0,0,16); lsSubLbl.Position=UDim2.fromOffset(0,88)
        lsSubLbl.BackgroundTransparency=1; lsSubLbl.Font=Enum.Font.Code
        lsSubLbl.TextSize=11; lsSubLbl.TextColor3=T.TextDim
        lsSubLbl.Text=splashSubtitle; lsSubLbl.ZIndex=102

        -- progress track
        local lsTrack = Instance.new("Frame", lsCard)
        lsTrack.Size=UDim2.new(1,-40,0,3); lsTrack.Position=UDim2.new(0,20,1,-18)
        lsTrack.BackgroundColor3=T.Element; lsTrack.BorderSizePixel=0; lsTrack.ZIndex=102
        Instance.new("UICorner", lsTrack).CornerRadius = UDim.new(1,0)

        local lsFill = Instance.new("Frame", lsTrack)
        lsFill.Size=UDim2.new(0,0,1,0); lsFill.BackgroundColor3=self.Accent
        lsFill.BorderSizePixel=0; lsFill.ZIndex=103
        Instance.new("UICorner", lsFill).CornerRadius = UDim.new(1,0)
        self:_onAccent(function(c) lsFill.BackgroundColor3 = c end)

        -- status label
        local lsStatus = Instance.new("TextLabel", lsCard)
        lsStatus.Size=UDim2.new(1,0,0,12); lsStatus.Position=UDim2.new(0,0,1,-34)
        lsStatus.BackgroundTransparency=1; lsStatus.Font=Enum.Font.Code
        lsStatus.TextSize=10; lsStatus.TextColor3=T.TextMute
        lsStatus.Text="Loading..."; lsStatus.ZIndex=102

        mf.Visible = false   -- hide main window until splash done

        -- ── Snow effect ── (defined inline so it can access TweenService/RunService upvalues)
        local function createSnowEffect(snowParent, accentColor)
            local flakes      = {}
            local connections = {}
            local active      = true
            local CHARS       = {"•", "·", "✦", "∗", "❄", "·"}
            local MAX_FLAKES  = 55

            local function spawnFlake(startY)
                if not active or #flakes >= MAX_FLAKES then return end
                local size     = math.random(5, 11)
                local duration = math.random(35, 70) / 10
                local flake    = Instance.new("TextLabel", snowParent)
                flake.BackgroundTransparency = 1
                flake.Font       = Enum.Font.Code
                flake.TextSize   = size
                flake.Text       = CHARS[math.random(#CHARS)]
                flake.ZIndex     = 50
                flake.TextColor3 = math.random() > 0.7
                    and Color3.fromRGB(
                        math.floor(accentColor.R*255),
                        math.floor(accentColor.G*255),
                        math.floor(accentColor.B*255))
                    or Color3.fromRGB(200, 210, 230)
                flake.TextTransparency = math.random(2, 6) / 10
                local sx = math.random(2, 96) / 100
                local sy = startY or -0.05
                flake.Size     = UDim2.fromOffset(size, size)
                flake.Position = UDim2.new(sx, 0, sy, 0)
                table.insert(flakes, flake)
                local driftX   = (math.random() - 0.5) * 0.08
                local fallDur  = startY and ((1 - startY) * math.random(35,65)/10) or duration
                local tInfo    = TweenInfo.new(fallDur, Enum.EasingStyle.Linear)
                local t = TweenService:Create(flake, tInfo, {
                    Position         = UDim2.new(sx + driftX, 0, 1.05, 0),
                    TextTransparency = 0.85,
                })
                t:Play()
                t.Completed:Connect(function()
                    if flake and flake.Parent then flake:Destroy() end
                    for i, f in ipairs(flakes) do
                        if f == flake then table.remove(flakes, i) break end
                    end
                end)
            end

            -- Pre-populate
            for i = 1, 18 do
                task.delay(i * 0.05, function()
                    if active then spawnFlake(math.random(0, 90) / 100) end
                end)
            end

            -- Continuous spawn loop
            local conn = RunService.Heartbeat:Connect(function()
                if active and math.random() < 0.08 then spawnFlake(nil) end
            end)
            table.insert(connections, conn)

            return function()  -- stop()
                active = false
                for _, c in ipairs(connections) do c:Disconnect() end
                connections = {}
                for _, f in ipairs(flakes) do
                    if f and f.Parent then
                        TweenService:Create(f, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
                        game:GetService("Debris"):AddItem(f, 0.45)
                    end
                end
                flakes = {}
            end
        end

        -- ── Snow effect on splash background ─────
        local stopSnow = createSnowEffect(splash, self.Accent)

        local steps = {
            {pct=0.30, label="Initializing...",    t=loadDur*0.25},
            {pct=0.60, label="Loading elements...",t=loadDur*0.25},
            {pct=0.85, label="Applying theme...",  t=loadDur*0.20},
            {pct=1.00, label="Ready!",             t=loadDur*0.20},
        }

        task.spawn(function()
            for _, step in ipairs(steps) do
                task.wait(step.t)
                lsStatus.Text = step.label
                tw(lsFill, step.t + 0.05, {Size = UDim2.new(step.pct,0,1,0)})
            end
            task.wait(0.25)
            -- stop snow before fade out
            stopSnow()
            -- fade out
            for _, d in ipairs(splash:GetDescendants()) do
                if d:IsA("TextLabel") then tw(d, 0.35, {TextTransparency=1}) end
                if d:IsA("Frame")     then pcall(function() tw(d,0.35,{BackgroundTransparency=1}) end) end
            end
            tw(splash, 0.35, {BackgroundTransparency=1})
            task.wait(0.4)
            splash:Destroy()
            mf.Visible = true
        end)
    end

    return self
end

function Library:_onAccent(fn) table.insert(self._accentSubs, fn) end
function Library:SetAccent(col)
    self.Accent = col
    T.Accent    = col
    T.AccentDim = Color3.fromRGB(
        math.floor(col.R*255*0.6),
        math.floor(col.G*255*0.6),
        math.floor(col.B*255*0.6)
    )
    for _, fn in ipairs(self._accentSubs) do pcall(fn, col) end
end

function Library:_build()
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name            = "HutameHub_" .. math.random(1000,9999)
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn    = false
    sg.IgnoreGuiInset  = true
    sg.Parent          = safeParent()
    self.ScreenGui     = sg
    sg.Name            = "HutameHub_" .. math.random(1000,9999)
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn    = false
    sg.IgnoreGuiInset  = true
    sg.Parent          = safeParent()
    self.ScreenGui     = sg

    -- ── Main Frame ──────────────────────────────
    local mf = Instance.new("Frame")
    mf.Name              = "MainFrame"
    mf.Size              = UDim2.fromOffset(600, 540)
    mf.Position          = UDim2.new(0.5,-300, 0.5,-270)
    mf.BackgroundColor3  = T.BG
    mf.BorderSizePixel   = 0
    mf.ClipsDescendants  = false
    mf.Parent            = sg
    Instance.new("UICorner", mf).CornerRadius = UDim.new(0,0)
    local mfStroke = Instance.new("UIStroke", mf)
    mfStroke.Color     = T.Black
    mfStroke.Thickness = 2
    local innerBorder = Instance.new("Frame", mf)
    innerBorder.Name = "InsetBorder"
    innerBorder.Position = UDim2.fromOffset(4, 4)
    innerBorder.Size = UDim2.new(1, -8, 1, -8)
    innerBorder.BackgroundTransparency = 1
    innerBorder.BorderSizePixel = 0
    local innerStroke = Instance.new("UIStroke", innerBorder)
    innerStroke.Color = T.BorderLight
    innerStroke.Thickness = 1
    self.MainFrame = mf

    -- ── Top accent line ──────────────────────────
    local acLine = Instance.new("Frame", mf)
    acLine.Name             = "AccentLine"
    acLine.Size             = UDim2.new(1,-12,0,1)
    acLine.Position         = UDim2.fromOffset(6,7)
    acLine.BackgroundColor3 = self.Accent
    acLine.BorderSizePixel  = 0
    acLine.ZIndex           = 4
    Instance.new("UICorner", acLine).CornerRadius = UDim.new(0,0)
    self:_onAccent(function(c) acLine.BackgroundColor3 = c end)

    -- ── Topbar ──────────────────────────────────
    local topbar = Instance.new("Frame", mf)
    topbar.Name            = "Topbar"
    topbar.Size            = UDim2.new(1,-12,0,32)
    topbar.Position        = UDim2.fromOffset(6,8)
    topbar.BackgroundColor3= T.Surface
    topbar.BorderSizePixel = 0
    topbar.ZIndex          = 3

    -- brand
    local brand = Instance.new("TextLabel", topbar)
    brand.Size               = UDim2.new(1,-170,1,0)
    brand.Position           = UDim2.fromOffset(10,0)
    brand.BackgroundTransparency = 1
    brand.Font               = Enum.Font.Code
    brand.TextSize           = 13
    brand.TextColor3         = T.White
    brand.TextXAlignment     = Enum.TextXAlignment.Left
    brand.RichText           = true
    brand.Text               = string.format(
        '<font color="#%s">%s</font>  <font color="#%s">%s</font>',
        self.Accent:ToHex(), self.Title,
        T.TextDim:ToHex(), self.Version
    )
    self._titleLabel = brand
    self:_onAccent(function(c)
        brand.Text = string.format(
            '<font color="#%s">%s</font>  <font color="#%s">%s</font>',
            c:ToHex(), self.Title, T.TextDim:ToHex(), self.Version
        )
    end)

    -- right side: controls holder (fixed width, right-anchored)
    local ctrlHolder = Instance.new("Frame", topbar)
    ctrlHolder.Name                = "CtrlHolder"
    ctrlHolder.Size                = UDim2.fromOffset(62, 36)
    ctrlHolder.Position            = UDim2.new(1, -62, 0, 0)
    ctrlHolder.BackgroundTransparency = 1
    ctrlHolder.BorderSizePixel     = 0

    -- user info sits just left of ctrlHolder
    local userLbl = Instance.new("TextLabel", topbar)
    userLbl.Size                 = UDim2.new(0, 90, 1, 0)
    userLbl.Position             = UDim2.new(1, -164, 0, 0)
    userLbl.BackgroundTransparency = 1
    userLbl.Font                 = Enum.Font.Code
    userLbl.TextSize             = 11
    userLbl.TextColor3           = T.TextDim
    userLbl.TextXAlignment       = Enum.TextXAlignment.Right
    userLbl.Text                 = LocalPlayer.Name

    -- close & minimize (parented to ctrlHolder, positioned from left)
    local function mkCtrl(char, xPos, hoverCol, onClick)
        local btn = Instance.new("TextButton", ctrlHolder)
        btn.Size               = UDim2.fromOffset(24, 24)
        btn.Position           = UDim2.new(0, xPos, 0.5, -12)
        btn.BackgroundColor3   = T.Element
        btn.BorderSizePixel    = 0
        btn.Font               = Enum.Font.Code
        btn.TextSize           = 12
        btn.TextColor3         = T.TextDim
        btn.Text               = char
        btn.AutoButtonColor    = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,0)
        btn.MouseEnter:Connect(function() tw(btn,0.15,{BackgroundColor3=hoverCol, TextColor3=T.White}) end)
        btn.MouseLeave:Connect(function() tw(btn,0.15,{BackgroundColor3=T.Element, TextColor3=T.TextDim}) end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end
    -- Hide the whole window, exactly like ToggleKey / Minus.
    mkCtrl("—", 4, T.ElementHov, function() mf.Visible = not mf.Visible end)
    mkCtrl("✕", 32, Color3.fromRGB(200,40,40), function() self:Destroy() end)

    -- drag
    local dragging, dragStart, startPos = false, nil, nil
    topbar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = mf.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    topbar.InputChanged:Connect(function(i)
        if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            if dragging then
                local d = i.Position - dragStart
                mf.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
            end
        end
    end)

    -- ── Tab Bar (horizontal) ─────────────────────
    local tabBar = Instance.new("Frame", mf)
    tabBar.Name            = "TabBar"
    tabBar.Size            = UDim2.new(1,-20,0,30)
    tabBar.Position        = UDim2.fromOffset(10,44)
    tabBar.BackgroundColor3= T.Surface
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex          = 3
    local tabBarStroke = Instance.new("UIStroke", tabBar)
    tabBarStroke.Color     = T.Border
    tabBarStroke.Thickness = 1
    tabBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local tabList = Instance.new("Frame", tabBar)
    tabList.Name               = "TabList"
    tabList.Size               = UDim2.new(1,-50,1,0)
    tabList.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabList)
    tabLayout.FillDirection    = Enum.FillDirection.Horizontal
    tabLayout.SortOrder        = Enum.SortOrder.LayoutOrder
    tabLayout.Padding          = UDim.new(0,3)
    self.TabBar  = tabBar
    self.TabList = tabList

    -- ── Body (content area below tabbar) ─────────
    local body = Instance.new("Frame", mf)
    body.Name            = "Body"
    body.Size            = UDim2.new(1,-12,1,-84)
    body.Position        = UDim2.fromOffset(6,78)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true
    self._body = body

    -- Minus is an additional shortcut; keep the configured ToggleKey working.
    self._toggleConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or self._listeningForKey or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == self.ToggleKey or input.KeyCode == Enum.KeyCode.Minus then
            mf.Visible = not mf.Visible
        end
    end)
end

-- ─────────────────────────────────────────────
-- CreateTab
-- ─────────────────────────────────────────────
function Library:CreateTab(name)
    local Tab = { Name = name, _lib = self, _cols = {}, Active = false }

    -- tab button
    local btn = Instance.new("TextButton", self.TabList)
    btn.Name               = "Tab_"..name
    btn.Size               = UDim2.new(0,0,1,0)
    btn.AutomaticSize      = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 0
    btn.BackgroundColor3 = T.BG
    btn.BorderSizePixel    = 0
    btn.Font               = Enum.Font.Code
    btn.TextSize           = 12
    btn.TextColor3         = T.TextDim
    btn.Text               = "  "..name.."  "
    btn.AutoButtonColor    = false
    btn.ClipsDescendants   = false
    local tabStroke = Instance.new("UIStroke", btn)
    tabStroke.Color = T.Border
    tabStroke.Thickness = 1
    tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- active underline
    local uline = Instance.new("Frame", btn)
    uline.Name             = "Underline"
    uline.Size             = UDim2.new(1,0,0,2)
    uline.Position         = UDim2.new(0,0,1,-2)
    uline.BackgroundColor3 = self.Accent
    uline.BackgroundTransparency = 1
    uline.BorderSizePixel  = 0
    self:_onAccent(function(c) if Tab.Active then uline.BackgroundColor3 = c end end)

    -- ── Tab Badge ──────────────────────────────
    local badge = Instance.new("Frame", btn)
    badge.Name              = "Badge"
    badge.Size              = UDim2.fromOffset(16, 16)
    badge.Position          = UDim2.new(1, -8, 0, 8)
    badge.AnchorPoint       = Vector2.new(0.5, 0.5)
    badge.BackgroundColor3  = T.Accent
    badge.BorderSizePixel   = 0
    badge.Visible           = false
    badge.ZIndex            = 10
    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
    local badgeLbl = Instance.new("TextLabel", badge)
    badgeLbl.Size                 = UDim2.new(1,0,1,0)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Font                 = Enum.Font.Code
    badgeLbl.TextSize             = 9
    badgeLbl.TextColor3           = Color3.new(1,1,1)
    badgeLbl.Text                 = ""
    badgeLbl.ZIndex               = 11
    Tab._badge    = badge
    Tab._badgeLbl = badgeLbl
    self:_onAccent(function(c) badge.BackgroundColor3 = c end)

    function Tab:SetBadge(n)
        if n and n > 0 then
            badgeLbl.Text  = n > 99 and "99+" or tostring(n)
            badge.Visible  = true
        else
            badge.Visible  = false
            badgeLbl.Text  = ""
        end
    end
    function Tab:ClearBadge() Tab:SetBadge(0) end

    -- content page (two columns inside)
    local page = Instance.new("Frame", self._body)
    page.Name                  = "Page_"..name
    page.Size                  = UDim2.new(1,0,1,0)
    page.BackgroundTransparency= 1
    page.Visible               = false
    page.ClipsDescendants      = true

    -- left column scroll
    local leftScroll = Instance.new("ScrollingFrame", page)
    leftScroll.Name                = "LeftCol"
    leftScroll.Size                = UDim2.new(0.5,-1,1,0)
    leftScroll.BackgroundTransparency = 1
    leftScroll.ScrollBarThickness  = 2
    leftScroll.ScrollBarImageColor3= T.Border
    leftScroll.BorderSizePixel     = 0
    leftScroll.CanvasSize          = UDim2.new(0,0,0,0)
    leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local lPad = Instance.new("UIPadding", leftScroll)
    lPad.PaddingTop    = UDim.new(0,8)
    lPad.PaddingBottom = UDim.new(0,8)
    lPad.PaddingLeft   = UDim.new(0,8)
    lPad.PaddingRight  = UDim.new(0,4)
    local lLayout = Instance.new("UIListLayout", leftScroll)
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lLayout.Padding   = UDim.new(0,6)

    -- divider between columns
    local div = Instance.new("Frame", page)
    div.Name             = "ColDivider"
    div.Size             = UDim2.new(0,1,1,0)
    div.Position         = UDim2.new(0.5,0,0,0)
    div.BackgroundColor3 = T.BG
    div.BorderSizePixel  = 0

    -- right column scroll
    local rightScroll = Instance.new("ScrollingFrame", page)
    rightScroll.Name                = "RightCol"
    rightScroll.Size                = UDim2.new(0.5,-1,1,0)
    rightScroll.Position            = UDim2.new(0.5,1,0,0)
    rightScroll.BackgroundTransparency = 1
    rightScroll.ScrollBarThickness  = 2
    rightScroll.ScrollBarImageColor3= T.Border
    rightScroll.BorderSizePixel     = 0
    rightScroll.CanvasSize          = UDim2.new(0,0,0,0)
    rightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local rPad = Instance.new("UIPadding", rightScroll)
    rPad.PaddingTop    = UDim.new(0,8)
    rPad.PaddingBottom = UDim.new(0,8)
    rPad.PaddingLeft   = UDim.new(0,4)
    rPad.PaddingRight  = UDim.new(0,8)
    local rLayout = Instance.new("UIListLayout", rightScroll)
    rLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rLayout.Padding   = UDim.new(0,6)

    -- ── Mobile Layout ─────────────────────────────
    local function applyMobileLayout(isMobile)
        if isMobile then
            leftScroll.Size     = UDim2.new(1,0,1,0)
            rightScroll.Visible = false
            div.Visible         = false
            for _, child in ipairs(rightScroll:GetChildren()) do
                if child:IsA("Frame") and child.Name:sub(1,4)=="Sec_" then
                    child.Parent = leftScroll
                end
            end
        else
            leftScroll.Size     = UDim2.new(0.5,-1,1,0)
            rightScroll.Visible = true
            div.Visible         = true
        end
    end

    local cam = workspace.CurrentCamera
    local function checkMobile()
        applyMobileLayout(cam.ViewportSize.X < 600)
    end
    checkMobile()
    cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if page.Visible then checkMobile() end
    end)

    Tab._page      = page
    Tab._left      = leftScroll
    Tab._right     = rightScroll
    Tab._btn       = btn
    Tab._uline     = uline
    Tab._checkMobile = checkMobile

    function Tab:Activate()
        for _, t in ipairs(self._lib.Tabs) do t:Deactivate() end
        Tab.Active     = true
        page.Visible   = true
        tw(btn,   0.15, {TextColor3 = T.White, BackgroundColor3 = T.Surface})
        tw(uline, 0.15, {BackgroundTransparency = 0, BackgroundColor3 = self._lib.Accent})
        self._lib.ActiveTab = Tab
        Tab._checkMobile()
    end

    function Tab:Deactivate()
        Tab.Active   = false
        page.Visible = false
        tw(btn,   0.15, {TextColor3 = T.TextMute, BackgroundColor3 = T.BG})
        tw(uline, 0.15, {BackgroundTransparency = 1})
    end

    btn.MouseButton1Click:Connect(function() Tab:Activate() end)
    btn.MouseEnter:Connect(function() if not Tab.Active then tw(btn,0.1,{TextColor3=T.Text}) end end)
    btn.MouseLeave:Connect(function() if not Tab.Active then tw(btn,0.1,{TextColor3=T.TextDim}) end end)

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then Tab:Activate() end

    -- CreateSection helper (attached to tab)
    -- col: "left" (default) or "right"
    function Tab:CreateSection(title, col)
        return Library._createSection(self._lib, title, col == "right" and self._right or self._left)
    end

    return Tab
end

-- ─────────────────────────────────────────────
-- Section
-- ─────────────────────────────────────────────
function Library:_createSection(title, parent)
    local Section = { _lib = self, _parent = parent }

    local card = Instance.new("Frame", parent)
    card.Name              = "Sec_"..title
    card.Size              = UDim2.new(1,0,0,0)
    card.AutomaticSize     = Enum.AutomaticSize.Y
    card.BackgroundColor3  = T.Card
    card.BorderSizePixel   = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,0)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color     = T.Border
    cardStroke.Thickness = 1
    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop    = UDim.new(0,6)
    pad.PaddingBottom = UDim.new(0,8)
    pad.PaddingLeft   = UDim.new(0,8)
    pad.PaddingRight  = UDim.new(0,8)
    local layout = Instance.new("UIListLayout", card)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0,5)

    -- section header (clickable for collapse)
    local hdrBtn = Instance.new("TextButton", card)
    hdrBtn.Name                = "Header"
    hdrBtn.Size                = UDim2.new(1,0,0,18)
    hdrBtn.BackgroundTransparency = 1
    hdrBtn.BorderSizePixel     = 0
    hdrBtn.Text                = ""
    hdrBtn.AutoButtonColor     = false
    hdrBtn.LayoutOrder         = 0
    local headerLine = Instance.new("Frame", hdrBtn)
    headerLine.Name = "AccentRule"
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0.5, 0)
    headerLine.BackgroundColor3 = self.Accent
    headerLine.BorderSizePixel = 0
    self:_onAccent(function(color) headerLine.BackgroundColor3 = color end)

    local hdr = Instance.new("TextLabel", hdrBtn)
    hdr.Size                  = UDim2.fromOffset(math.min(#title * 7 + 20, 230), 18)
    hdr.Position              = UDim2.fromOffset(7, 0)
    hdr.BackgroundColor3      = T.Card
    hdr.Font                  = Enum.Font.Code
    hdr.TextSize               = 12
    hdr.TextColor3             = T.Text
    hdr.TextXAlignment         = Enum.TextXAlignment.Left
    hdr.Text                   = title

    -- collapse arrow
    local colArrow = Instance.new("TextLabel", hdrBtn)
    colArrow.Size                  = UDim2.fromOffset(14,18)
    colArrow.Position              = UDim2.new(1,-14,0,0)
    colArrow.BackgroundColor3      = T.Card
    colArrow.Font                  = Enum.Font.Code
    colArrow.TextSize              = 8
    colArrow.TextColor3            = T.TextMute
    colArrow.Text                  = "▲"

    -- separator under header
    local sep = Instance.new("Frame", card)
    sep.Name             = "HeaderSep"
    sep.Size             = UDim2.new(1,0,0,1)
    sep.BackgroundColor3 = T.Border
    sep.BorderSizePixel  = 0
    sep.LayoutOrder      = 1

    -- One cancellable size tween; no delayed AutomaticSize switch to race clicks.
    local collapsed = false
    local sizeTween
    card.AutomaticSize = Enum.AutomaticSize.None
    card.ClipsDescendants = true
    local collapsedHeight = 6 + 18 + 5 + 1 + 8
    local function resizeSection(animate)
        local target = collapsed and collapsedHeight
            or math.max(collapsedHeight, layout.AbsoluteContentSize.Y + 14)
        if sizeTween then sizeTween:Cancel(); sizeTween = nil end
        if animate then
            sizeTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(1,0,0,target)})
            sizeTween:Play()
        else
            card.Size = UDim2.new(1,0,0,target)
        end
    end
    local function setCollapsed(val)
        if collapsed == val then return end
        collapsed = val
        card:SetAttribute("Collapsed", val)
        if not val then
            for _, child in ipairs(card:GetChildren()) do
                if child:IsA("GuiObject") and child ~= hdrBtn and child ~= sep then
                    child.Visible = child:GetAttribute("ConditionVisible") ~= false
                end
            end
        end
        tw(colArrow, 0.2, {Rotation = val and 180 or 0})
        resizeSection(true)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not collapsed then resizeSection(true) end
    end)
    card.Destroying:Connect(function() if sizeTween then sizeTween:Cancel() end end)
    resizeSection(false)
    hdrBtn.MouseButton1Click:Connect(function() setCollapsed(not collapsed) end)
    hdrBtn.MouseEnter:Connect(function() tw(hdr,0.1,{TextColor3=T.TextDim}) end)
    hdrBtn.MouseLeave:Connect(function() tw(hdr,0.1,{TextColor3=T.Text}) end)

    function Section:Collapse() setCollapsed(true) end
    function Section:Expand()   setCollapsed(false) end

    Section._card   = card
    Section._lib    = self
    Section._order  = 2

    local function nextOrder()
        Section._order = Section._order + 1
        return Section._order
    end

    -- ── Toggle (Checkbox style) ──────────────────
    function Section:CreateToggle(config)
        local ttl      = config.Title    or "Toggle"
        local state    = config.Default  or false
        local cb       = config.Callback or function() end
        local bindKey  = config.Keybind  or nil   -- e.g. Enum.KeyCode.F
        local Toggle   = {State = state}

        local row = Instance.new("TextButton", card)
        row.Name               = "Toggle_"..ttl
        row.Size               = UDim2.new(1,0,0,22)
        row.BackgroundTransparency = 1
        row.Text               = ""
        row.AutoButtonColor    = false
        row.LayoutOrder        = nextOrder()

        -- checkbox box
        local box = Instance.new("Frame", row)
        box.Size             = UDim2.fromOffset(13,13)
        box.Position         = UDim2.new(0,0,0.5,-6)
        box.BackgroundColor3 = state and self._lib.Accent or T.Element
        box.BorderSizePixel  = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,0)
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color     = state and self._lib.Accent or T.BorderLight
        boxStroke.Thickness = 1

        -- checkmark tick
        local tick = Instance.new("TextLabel", box)
        tick.Size                  = UDim2.new(1,0,1,0)
        tick.BackgroundTransparency= 1
        tick.Font                  = Enum.Font.Code
        tick.TextSize              = 9
        tick.TextColor3            = T.White
        tick.Text                  = "✓"
        tick.BackgroundTransparency= 1
        tick.Visible               = state

        -- label
        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(1,-24,1,0)
        lbl.Position              = UDim2.fromOffset(20,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Code
        lbl.TextSize              = 12
        lbl.TextColor3            = state and T.Text or T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        -- value label right (optional, e.g. "None")
        local valLbl = Instance.new("TextLabel", row)
        valLbl.Size                  = UDim2.new(0,50,1,0)
        valLbl.Position              = UDim2.new(1,-50,0,0)
        valLbl.BackgroundTransparency= 1
        valLbl.Font                  = Enum.Font.Code
        valLbl.TextSize              = 10
        valLbl.TextColor3            = T.TextMute
        valLbl.TextXAlignment        = Enum.TextXAlignment.Right
        valLbl.Text                  = ""

        self._lib:_onAccent(function(c)
            if Toggle.State then
                box.BackgroundColor3 = c
                boxStroke.Color      = c
            end
        end)

        function Toggle:Set(val)
            Toggle.State         = val
            tick.Visible         = val
            box.BackgroundColor3 = val and self._lib.Accent or T.Element
            boxStroke.Color      = val and self._lib.Accent or T.BorderLight
            tw(lbl, 0.1, {TextColor3 = val and T.Text or T.TextDim})
            pcall(cb, val)
        end

        -- make Set accessible via lib accent
        Toggle._lib = self._lib

        row.MouseButton1Click:Connect(function() Toggle:Set(not Toggle.State) end)
        row.MouseEnter:Connect(function() tw(lbl,0.1,{TextColor3=T.Text}) end)
        row.MouseLeave:Connect(function() if not Toggle.State then tw(lbl,0.1,{TextColor3=T.TextDim}) end end)

        -- ── Keybind Toggle Bind ──────────────────
        if bindKey then
            valLbl.Text      = "["..bindKey.Name.."]"
            valLbl.TextColor3= T.TextMute
            UserInputService.InputBegan:Connect(function(input, gp)
                if not gp and not self._lib._listeningForKey and not UserInputService:GetFocusedTextBox() and row.Parent:GetAttribute("Collapsed") ~= true and row.Visible and row:GetAttribute("ConditionEnabled") ~= false and input.KeyCode == bindKey then
                    Toggle:Set(not Toggle.State)
                end
            end)
        end

        return Toggle
    end

    -- ── Slider ───────────────────────────────────
    function Section:CreateSlider(config)
        local ttl      = config.Title    or "Slider"
        local min      = config.Min      or 0
        local max      = config.Max      or 100
        local default  = math.clamp(config.Default or min, min, max)
        local decs     = config.Decimals or 0
        local suffix   = config.Suffix   or ""
        local cb       = config.Callback or function() end
        local Slider   = {Value = default}

        local container = Instance.new("Frame", card)
        container.Name             = "Slider_"..ttl
        container.Size             = UDim2.new(1,0,0,32)
        container.BackgroundTransparency = 1
        container.LayoutOrder      = nextOrder()

        -- header row
        local headerRow = Instance.new("Frame", container)
        headerRow.Size             = UDim2.new(1,0,0,14)
        headerRow.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", headerRow)
        lbl.Size                  = UDim2.new(1,-60,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Code
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local valLbl = Instance.new("TextLabel", headerRow)
        valLbl.Size                  = UDim2.new(0,60,1,0)
        valLbl.Position              = UDim2.new(1,-60,0,0)
        valLbl.BackgroundTransparency= 1
        valLbl.Font                  = Enum.Font.Code
        valLbl.TextSize              = 11
        valLbl.TextColor3            = T.Text
        valLbl.TextXAlignment        = Enum.TextXAlignment.Right
        valLbl.Text                  = string.format("%."..decs.."f/%d%s", default, max, suffix)

        -- track
        local trackHolder = Instance.new("TextButton", container)
        trackHolder.Size             = UDim2.new(1,0,0,8)
        trackHolder.Position         = UDim2.fromOffset(0,18)
        trackHolder.BackgroundColor3 = T.Element
        trackHolder.BorderSizePixel  = 0
        trackHolder.Text             = ""
        trackHolder.AutoButtonColor  = false

        local fill = Instance.new("Frame", trackHolder)
        fill.Size             = UDim2.new((default-min)/(max-min),0,1,0)
        fill.BackgroundColor3 = self._lib.Accent
        fill.BorderSizePixel  = 0

        local knob = Instance.new("Frame", fill)
        knob.Size             = UDim2.fromOffset(8,8)
        knob.Position         = UDim2.new(1,-4,0.5,-4)
        knob.BackgroundColor3 = T.White
        knob.BorderSizePixel  = 0
        knob.Visible = false

        self._lib:_onAccent(function(c) fill.BackgroundColor3 = c end)

        local function update(input)
            local px = input.Position.X - trackHolder.AbsolutePosition.X
            local pct = math.clamp(px / trackHolder.AbsoluteSize.X, 0, 1)
            local raw = min + (max - min) * pct
            local val = tonumber(string.format("%."..decs.."f", raw))
            Slider.Value   = val
            valLbl.Text    = string.format("%."..decs.."f/%d%s", val, max, suffix)
            tw(fill, 0.04, {Size = UDim2.new(pct,0,1,0)})
            pcall(cb, val)
        end

        function Slider:Set(val)
            val          = math.clamp(val, min, max)
            Slider.Value = val
            valLbl.Text  = string.format("%."..decs.."f/%d%s", val, max, suffix)
            local pct    = (val-min)/(max-min)
            tw(fill, 0.12, {Size = UDim2.new(pct,0,1,0)})
            pcall(cb, val)
        end

        local drag = false
        trackHolder.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                drag = true; update(i)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i) end
        end)

        return Slider
    end

    -- ── Dropdown ─────────────────────────────────
    function Section:CreateDropdown(config)
        local ttl      = config.Title    or "Dropdown"
        local opts     = config.Options  or {}
        local sel      = config.Default  or opts[1] or ""
        local cb       = config.Callback or function() end
        local Dropdown = {Selected = sel, Opened = false, Options = opts}

        local container = Instance.new("Frame", card)
        container.Name             = "DD_"..ttl
        container.Size             = UDim2.new(1,0,0,22)
        container.AutomaticSize    = Enum.AutomaticSize.None
        container.BackgroundTransparency = 1
        container.ClipsDescendants = false
        container.LayoutOrder      = nextOrder()

        local header = Instance.new("TextButton", container)
        header.Size              = UDim2.new(1,0,0,22)
        header.BackgroundColor3  = T.Element
        header.BorderSizePixel   = 0
        header.Text              = ""
        header.AutoButtonColor   = false
        header.ZIndex            = 3
        Instance.new("UICorner", header).CornerRadius = UDim.new(0,0)
        local hStroke = Instance.new("UIStroke", header)
        hStroke.Color     = T.Border
        hStroke.Thickness = 1

        local hLbl = Instance.new("TextLabel", header)
        hLbl.Size                  = UDim2.new(0.55,0,1,0)
        hLbl.Position              = UDim2.fromOffset(7,0)
        hLbl.BackgroundTransparency= 1
        hLbl.Font                  = Enum.Font.Code
        hLbl.TextSize              = 11
        hLbl.TextColor3            = T.TextDim
        hLbl.TextXAlignment        = Enum.TextXAlignment.Left
        hLbl.Text                  = ttl

        local valLbl = Instance.new("TextLabel", header)
        valLbl.Size                  = UDim2.new(0.4,-20,1,0)
        valLbl.Position              = UDim2.new(0.55,0,0,0)
        valLbl.BackgroundTransparency= 1
        valLbl.Font                  = Enum.Font.Code
        valLbl.TextSize              = 11
        valLbl.TextColor3            = T.Text
        valLbl.TextXAlignment        = Enum.TextXAlignment.Right
        valLbl.Text                  = tostring(sel)

        local arrow = Instance.new("TextLabel", header)
        arrow.Size                  = UDim2.fromOffset(14,22)
        arrow.Position              = UDim2.new(1,-16,0,0)
        arrow.BackgroundTransparency= 1
        arrow.Font                  = Enum.Font.Code
        arrow.TextSize              = 8
        arrow.TextColor3            = T.TextMute
        arrow.Text                  = "▼"

        -- In-flow list panel: reserves height before the next control.
        local listFrame = Instance.new("ScrollingFrame", container)
        listFrame.Name             = "List"
        listFrame.Size             = UDim2.new(1,0,0,0)
        listFrame.Position         = UDim2.fromOffset(0,24)
        listFrame.BackgroundColor3 = T.Element
        listFrame.BorderSizePixel  = 0
        listFrame.ClipsDescendants = true
        listFrame.ZIndex           = 10
        listFrame.Visible          = false
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0,0)
        local lStroke = Instance.new("UIStroke", listFrame)
        lStroke.Color     = T.BorderLight
        lStroke.Thickness = 1
        -- Stroke follows the list panel stacking order
        local listLayout = Instance.new("UIListLayout", listFrame)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding   = UDim.new(0,1)
        local listPad = Instance.new("UIPadding", listFrame)
        listPad.PaddingTop    = UDim.new(0,3)
        listPad.PaddingBottom = UDim.new(0,3)

        local updateLayout = dropdownLayout(container, listFrame, config)
        local function buildList()
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(Dropdown.Options) do
                local ob = Instance.new("TextButton", listFrame)
                ob.Size              = UDim2.new(1,-6,0,20)
                ob.BackgroundColor3  = opt==Dropdown.Selected and self._lib.Accent or T.Element
                ob.BackgroundTransparency = opt==Dropdown.Selected and 0.3 or 0.95
                ob.BorderSizePixel   = 0
                ob.Font              = Enum.Font.Code
                ob.TextSize          = 11
                ob.TextColor3        = opt==Dropdown.Selected and T.White or T.TextDim
                ob.TextXAlignment    = Enum.TextXAlignment.Left
                ob.Text              = "  "..tostring(opt)
                ob.AutoButtonColor   = false
                ob.ZIndex            = 11
                local oc = Instance.new("UICorner", ob)
                oc.CornerRadius = UDim.new(0,0)
                ob.MouseEnter:Connect(function() if opt~=Dropdown.Selected then tw(ob,0.1,{BackgroundTransparency=0.7, TextColor3=T.Text}) end end)
                ob.MouseLeave:Connect(function() if opt~=Dropdown.Selected then tw(ob,0.1,{BackgroundTransparency=0.95, TextColor3=T.TextDim}) end end)
                ob.MouseButton1Click:Connect(function()
                    Dropdown:Set(opt)
                    Dropdown:Close()
                end)
            end
            updateLayout(Dropdown.Opened, #Dropdown.Options)
        end

        function Dropdown:Open()
            Dropdown.Opened = true
            listFrame.Visible = true
            buildList()
            tw(arrow, 0.15, {Rotation=180})
            tw(hStroke, 0.15, {Color = self._lib and self._lib.Accent or T.Accent})
        end
        Dropdown._lib = self._lib

        function Dropdown:Close()
            Dropdown.Opened = false
            tw(arrow, 0.15, {Rotation=0})
            tw(hStroke, 0.15, {Color=T.Border})
            updateLayout(false, #Dropdown.Options)
        end

        function Dropdown:Set(opt)
            Dropdown.Selected = opt
            valLbl.Text = tostring(opt)
            buildList()
            pcall(cb, opt)
        end

        function Dropdown:Refresh(newOpts)
            Dropdown.Options = newOpts or {}
            buildList()
        end

        header.MouseButton1Click:Connect(function()
            if Dropdown.Opened then Dropdown:Close() else Dropdown:Open() end
        end)

        return Dropdown
    end

    -- ── Textbox ──────────────────────────────────
    function Section:CreateTextbox(config)
        local ttl   = config.Title       or "Textbox"
        local ph    = config.Placeholder or "..."
        local def   = config.Default     or ""
        local cb    = config.Callback    or function() end
        local tip   = config.Tooltip     or nil
        local Tb    = {Text = def}

        local row = Instance.new("Frame", card)
        row.Name              = "TB_"..ttl
        row.Size              = UDim2.new(1,0,0,22)
        row.BackgroundTransparency = 1
        row.LayoutOrder       = nextOrder()

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(0.42,0,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Code
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local inputFrame = Instance.new("Frame", row)
        inputFrame.Size            = UDim2.new(0.58,-2,1,-2)
        inputFrame.Position        = UDim2.new(0.42,2,0,1)
        inputFrame.BackgroundColor3= T.Element
        inputFrame.BorderSizePixel = 0
        Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0,0)
        local ifStroke = Instance.new("UIStroke", inputFrame)
        ifStroke.Color     = T.Border
        ifStroke.Thickness = 1

        local input = Instance.new("TextBox", inputFrame)
        input.Size                 = UDim2.new(1,-8,1,0)
        input.Position             = UDim2.fromOffset(4,0)
        input.BackgroundTransparency= 1
        input.Font                 = Enum.Font.Code
        input.TextSize             = 11
        input.TextColor3           = T.Text
        input.PlaceholderColor3    = T.TextMute
        input.PlaceholderText      = ph
        input.Text                 = def
        input.ClearTextOnFocus     = false

        input.Focused:Connect(function()    tw(ifStroke,0.15,{Color=self._lib.Accent}) end)
        input.FocusLost:Connect(function(enter)
            tw(ifStroke,0.15,{Color=T.Border})
            Tb.Text = input.Text
            pcall(cb, input.Text, enter)
        end)

        function Tb:Set(txt) input.Text=txt; Tb.Text=txt end

        if tip then self._lib:_attachTooltip(row, tip) end

        return Tb
    end

    -- ── Keybind ──────────────────────────────────
    function Section:CreateKeybind(config)
        local ttl   = config.Title    or "Keybind"
        local defK  = config.Default  or Enum.KeyCode.None
        local cb    = config.Callback or function() end
        local tip   = config.Tooltip  or nil
        local Kb    = {Key=defK, Listening=false}

        local row = Instance.new("Frame", card)
        row.Name              = "KB_"..ttl
        row.Size              = UDim2.new(1,0,0,22)
        row.BackgroundTransparency = 1
        row.LayoutOrder       = nextOrder()

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(1,-80,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Code
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local kBtn = Instance.new("TextButton", row)
        kBtn.Size              = UDim2.fromOffset(72,18)
        kBtn.Position          = UDim2.new(1,-72,0.5,-9)
        kBtn.BackgroundColor3  = T.Element
        kBtn.BorderSizePixel   = 0
        kBtn.Font              = Enum.Font.Code
        kBtn.TextSize          = 10
        kBtn.TextColor3        = T.TextDim
        kBtn.Text              = "["..defK.Name.."]"
        kBtn.AutoButtonColor   = false
        Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0,0)
        local kbStroke = Instance.new("UIStroke", kBtn)
        kbStroke.Color     = T.Border
        kbStroke.Thickness = 1

        kBtn.MouseButton1Click:Connect(function()
            if Kb.Listening then return end
            Kb.Listening = true
            self._lib._listeningForKey = true
            kBtn.Text    = "[...]"
            tw(kbStroke,0.15,{Color=self._lib.Accent})
            local conn
            conn = UserInputService.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Keyboard then
                    local k = i.KeyCode==Enum.KeyCode.Backspace and Enum.KeyCode.None or i.KeyCode
                    Kb.Key        = k
                    kBtn.Text     = "["..k.Name.."]"
                    Kb.Listening  = false
                    self._lib._listeningForKey = false
                    tw(kbStroke,0.15,{Color=T.Border})
                    conn:Disconnect()
                    pcall(cb, k)
                end
            end)
            table.insert(self._lib._extraConnections, conn)
        end)

        function Kb:Set(k) Kb.Key=k; kBtn.Text="["..k.Name.."]" end

        if tip then self._lib:_attachTooltip(row, tip) end

        return Kb
    end

    -- ── ColorPicker (compact swatch row) ─────────
    function Section:CreateColorPicker(config)
        local ttl   = config.Title    or "Color"
        local defC  = config.Default  or Color3.fromRGB(255,255,255)
        local cb    = config.Callback or function() end
        local tip   = config.Tooltip  or nil
        local CP    = {Color=defC, Opened=false}
        local r,g,b = math.floor(defC.R*255), math.floor(defC.G*255), math.floor(defC.B*255)

        local container = Instance.new("Frame", card)
        container.Name             = "CP_"..ttl
        container.Size             = UDim2.new(1,0,0,22)
        container.AutomaticSize    = Enum.AutomaticSize.None
        container.BackgroundTransparency = 1
        container.ClipsDescendants = true
        container.LayoutOrder      = nextOrder()

        local header = Instance.new("TextButton", container)
        header.Size              = UDim2.new(1,0,0,22)
        header.BackgroundTransparency = 1
        header.Text              = ""
        header.AutoButtonColor   = false

        local lbl = Instance.new("TextLabel", header)
        lbl.Size                  = UDim2.new(1,-36,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Code
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local preview = Instance.new("Frame", header)
        preview.Size             = UDim2.fromOffset(24,14)
        preview.Position         = UDim2.new(1,-26,0.5,-7)
        preview.BackgroundColor3 = defC
        preview.BorderSizePixel  = 0
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0,0)
        local prevStroke = Instance.new("UIStroke", preview)
        prevStroke.Color     = T.BorderLight
        prevStroke.Thickness = 1

        -- RGB panel
        local panel = Instance.new("Frame", container)
        panel.Size             = UDim2.new(1,0,0,70)
        panel.Position         = UDim2.fromOffset(0,24)
        panel.BackgroundColor3 = T.Element
        panel.BorderSizePixel  = 0
        panel.Visible          = false
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0,0)
        local panelStroke = Instance.new("UIStroke", panel)
        panelStroke.Color     = T.Border
        panelStroke.Thickness = 1
        local panPad = Instance.new("UIPadding", panel)
        panPad.PaddingLeft=UDim.new(0,6); panPad.PaddingRight=UDim.new(0,6)
        panPad.PaddingTop=UDim.new(0,4); panPad.PaddingBottom=UDim.new(0,4)
        local panLayout = Instance.new("UIListLayout", panel)
        panLayout.SortOrder = Enum.SortOrder.LayoutOrder
        panLayout.Padding   = UDim.new(0,4)

        local channels = {
            {name="R", color=Color3.fromRGB(220,50,50),  val=r},
            {name="G", color=Color3.fromRGB(50,200,80),  val=g},
            {name="B", color=Color3.fromRGB(50,130,255), val=b},
        }
        local vals = {r,g,b}

        for i, ch in ipairs(channels) do
            local row2 = Instance.new("Frame", panel)
            row2.Size              = UDim2.new(1,0,0,16)
            row2.BackgroundTransparency = 1
            row2.LayoutOrder       = i

            local chLbl = Instance.new("TextLabel", row2)
            chLbl.Size                  = UDim2.fromOffset(10,16)
            chLbl.BackgroundTransparency= 1
            chLbl.Font                  = Enum.Font.Code
            chLbl.TextSize              = 10
            chLbl.TextColor3            = ch.color
            chLbl.Text                  = ch.name

            local tr = Instance.new("TextButton", row2)
            tr.Size              = UDim2.new(1,-46,0,5)
            tr.Position          = UDim2.new(0,14,0.5,-2)
            tr.BackgroundColor3  = T.Card
            tr.BorderSizePixel   = 0
            tr.Text              = ""
            tr.AutoButtonColor   = false
            Instance.new("UICorner", tr).CornerRadius = UDim.new(1,0)

            local fl = Instance.new("Frame", tr)
            fl.Size             = UDim2.new(ch.val/255,0,1,0)
            fl.BackgroundColor3 = ch.color
            fl.BorderSizePixel  = 0
            Instance.new("UICorner", fl).CornerRadius = UDim.new(1,0)

            local numLbl = Instance.new("TextLabel", row2)
            numLbl.Size                  = UDim2.fromOffset(26,16)
            numLbl.Position              = UDim2.new(1,-26,0,0)
            numLbl.BackgroundTransparency= 1
            numLbl.Font                  = Enum.Font.Code
            numLbl.TextSize              = 10
            numLbl.TextColor3            = T.TextDim
            numLbl.TextXAlignment        = Enum.TextXAlignment.Right
            numLbl.Text                  = tostring(ch.val)

            local function notify()
                local col = Color3.fromRGB(vals[1],vals[2],vals[3])
                CP.Color = col
                preview.BackgroundColor3 = col
                pcall(cb, col)
            end

            local dragC = false
            local function upd(inp)
                local px  = inp.Position.X - tr.AbsolutePosition.X
                local pct = math.clamp(px/tr.AbsoluteSize.X, 0, 1)
                local v   = math.floor(pct*255)
                vals[i]   = v
                fl.Size   = UDim2.new(pct,0,1,0)
                numLbl.Text = tostring(v)
                notify()
            end

            tr.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    dragC=true; upd(inp)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragC=false end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragC and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then upd(inp) end
            end)

            ch._fill   = fl
            ch._numLbl = numLbl
        end

        function CP:Toggle()
            CP.Opened = not CP.Opened
            panel.Visible = CP.Opened
            container.Size = UDim2.new(1,0,0, CP.Opened and 96 or 22)
        end

        function CP:Set(col)
            CP.Color = col
            vals[1]=math.floor(col.R*255); vals[2]=math.floor(col.G*255); vals[3]=math.floor(col.B*255)
            preview.BackgroundColor3 = col
            for i, ch in ipairs(channels) do
                ch._fill.Size = UDim2.new(vals[i]/255,0,1,0)
                ch._numLbl.Text = tostring(vals[i])
            end
            pcall(cb, col)
        end

        header.MouseButton1Click:Connect(function() CP:Toggle() end)

        if tip then self._lib:_attachTooltip(header, tip) end

        return CP
    end

    -- ── Button ───────────────────────────────────
    function Section:CreateButton(config)
        local ttl   = config.Title    or "Button"
        local cb    = config.Callback or function() end
        local desc  = config.Desc     or ""
        local tip   = config.Tooltip  or nil

        local btn = Instance.new("TextButton", card)
        btn.Name              = "Btn_"..ttl
        btn.Size              = UDim2.new(1,0,0,22)
        btn.BackgroundColor3  = T.Element
        btn.BorderSizePixel   = 0
        btn.Font              = Enum.Font.Code
        btn.TextSize          = 12
        btn.TextColor3        = T.Text
        btn.Text              = ttl
        btn.AutoButtonColor   = false
        btn.ClipsDescendants  = true
        btn.LayoutOrder       = nextOrder()
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,0)
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color     = T.Border
        bStroke.Thickness = 1

        btn.MouseEnter:Connect(function() tw(btn,0.1,{BackgroundColor3=T.ElementHov}) end)
        btn.MouseLeave:Connect(function() tw(btn,0.1,{BackgroundColor3=T.Element}) end)
        btn.MouseButton1Down:Connect(function()
            tw(btn,0.08,{BackgroundColor3=self._lib.Accent, TextColor3=T.Black})
            ripple(btn, self._lib.Accent)
        end)
        btn.MouseButton1Up:Connect(function()
            tw(btn,0.15,{BackgroundColor3=T.Element, TextColor3=T.Text})
        end)
        btn.MouseButton1Click:Connect(function() pcall(cb) end)

        if tip then self._lib:_attachTooltip(btn, tip) end

        return btn
    end

    -- ── Label (static text) ───────────────────────
    function Section:CreateLabel(text, col)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size                  = UDim2.new(1,0,0,16)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Code
        lbl.TextSize              = 11
        lbl.TextColor3            = col or T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = text
        lbl.TextWrapped           = true
        lbl.LayoutOrder           = nextOrder()
        return lbl
    end

    -- ── Separator ────────────────────────────────
    function Section:CreateSeparator()
        local sep2 = Instance.new("Frame", card)
        sep2.Size             = UDim2.new(1,0,0,1)
        sep2.BackgroundColor3 = T.Border
        sep2.BorderSizePixel  = 0
        sep2.LayoutOrder      = nextOrder()
    end

    return Section
end

-- ─────────────────────────────────────────────
-- Tooltip helper
-- ─────────────────────────────────────────────
-- Usage: Library:_attachTooltip(guiObject, "Tooltip text")
-- Creates a floating tooltip that fades in after a short hover delay.
-- The tooltip is parented to ScreenGui so it floats above everything.
function Library:_attachTooltip(target, text)
    if not text or text == "" then return end
    local sg = self.ScreenGui

    -- Shared tooltip frame (one per Hub, reused across all elements)
    if not self._tooltipFrame then
        local ttFrame = Instance.new("Frame")
        ttFrame.Name              = "TooltipFrame"
        ttFrame.Size              = UDim2.fromOffset(0, 24)
        ttFrame.AutomaticSize     = Enum.AutomaticSize.X
        ttFrame.BackgroundColor3  = Color3.fromRGB(10, 10, 10)
        ttFrame.BackgroundTransparency = 1  -- starts invisible
        ttFrame.BorderSizePixel   = 0
        ttFrame.ZIndex            = 9999
        ttFrame.Visible           = false
        ttFrame.Parent            = sg
        Instance.new("UICorner", ttFrame).CornerRadius = UDim.new(0,0)
        local ttStroke = Instance.new("UIStroke", ttFrame)
        ttStroke.Color     = T.BorderLight
        ttStroke.Thickness = 1
        local ttPad = Instance.new("UIPadding", ttFrame)
        ttPad.PaddingLeft   = UDim.new(0, 8)
        ttPad.PaddingRight  = UDim.new(0, 8)
        ttPad.PaddingTop    = UDim.new(0, 0)
        ttPad.PaddingBottom = UDim.new(0, 0)
        -- accent top bar (1px)
        local ttAccent = Instance.new("Frame", ttFrame)
        ttAccent.Name             = "AccentBar"
        ttAccent.Size             = UDim2.new(1, 0, 0, 1)
        ttAccent.BackgroundColor3 = self.Accent
        ttAccent.BorderSizePixel  = 0
        ttAccent.ZIndex           = 10000
        Instance.new("UICorner", ttAccent).CornerRadius = UDim.new(0,0)
        self:_onAccent(function(c) ttAccent.BackgroundColor3 = c end)

        local ttLabel = Instance.new("TextLabel", ttFrame)
        ttLabel.Name                 = "Label"
        ttLabel.Size                 = UDim2.new(1, 0, 1, 0)
        ttLabel.BackgroundTransparency = 1
        ttLabel.Font                 = Enum.Font.Code
        ttLabel.TextSize             = 11
        ttLabel.TextColor3           = T.TextDim
        ttLabel.TextTransparency     = 1  -- starts invisible
        ttLabel.TextXAlignment       = Enum.TextXAlignment.Left
        ttLabel.ZIndex               = 10000
        ttLabel.AutomaticSize        = Enum.AutomaticSize.X
        ttLabel.Text                 = ""

        self._tooltipFrame  = ttFrame
        self._tooltipLabel  = ttLabel
        self._tooltipAccent = ttAccent
        self._tooltipActive = false
    end

    local ttFrame  = self._tooltipFrame
    local ttLabel  = self._tooltipLabel
    local ttAccent = self._tooltipAccent

    local hoverThread = nil

    -- Follow mouse
    local moveConn

    local function showTooltip()
        ttLabel.Text    = text
        ttFrame.Visible = true
        -- Fade in
        tw(ttFrame, 0.18, {BackgroundTransparency = 0.12})
        tw(ttLabel, 0.18, {TextTransparency = 0})
        tw(ttAccent, 0.18, {BackgroundTransparency = 0})
        -- Start following mouse
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                local mx = i.Position.X
                local my = i.Position.Y
                -- Keep tooltip on screen
                local sw = sg.AbsoluteSize.X
                local tw2 = ttFrame.AbsoluteSize.X
                local ox = mx + 14
                if ox + tw2 > sw then ox = mx - tw2 - 8 end
                ttFrame.Position = UDim2.fromOffset(ox, my - 30)
            end
        end)
    end

    local function hideTooltip()
        if hoverThread then
            task.cancel(hoverThread)
            hoverThread = nil
        end
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end
        -- Fade out
        tw(ttFrame, 0.12, {BackgroundTransparency = 1})
        tw(ttLabel, 0.12, {TextTransparency = 1})
        tw(ttAccent, 0.12, {BackgroundTransparency = 1})
        task.delay(0.15, function()
            if ttFrame.BackgroundTransparency >= 0.99 then
                ttFrame.Visible = false
            end
        end)
    end

    target.MouseEnter:Connect(function()
        hoverThread = task.delay(0.4, showTooltip)
    end)

    target.MouseLeave:Connect(hideTooltip)
end

-- ─────────────────────────────────────────────
-- Window-level helpers
-- ─────────────────────────────────────────────
function Library:Destroy()
    if self._toggleConn then
        self._toggleConn:Disconnect()
        self._toggleConn = nil
    end
    if self._stopUISnow then self._stopUISnow() end
    if self.ScreenGui then self.ScreenGui:Destroy() end
    if self._wmConn  then self._wmConn:Disconnect() end
end

function Library:SetTitle(title, version)
    self.Title   = title   or self.Title
    self.Version = version or self.Version
    if self._titleLabel then
        self._titleLabel.Text = string.format(
            '<font color="#%s">%s</font>  <font color="#%s">%s</font>',
            self.Accent:ToHex(), self.Title,
            T.TextDim:ToHex(), self.Version
        )
    end
end

-- ==============================================================================
-- MULTI-SELECT DROPDOWN  (Section:CreateMultiDropdown)
-- ==============================================================================
-- Injected into every Section via _createSection — added as a standalone
-- function that sections call.  We monkey-patch it onto the Section metatable
-- by hooking _createSection's return value below.
local function _buildMultiDropdown(Section, card, nextOrder, config)
    local ttl     = config.Title    or "MultiDropdown"
    local opts    = config.Options  or {}
    local defs    = config.Default  or {}        -- table of pre-selected strings
    local maxShow = config.MaxShow  or 2          -- how many labels shown inline
    local cb      = config.Callback or function() end
    local Window  = Section._lib

    -- selected set
    local selected = {}
    for _, v in ipairs(defs) do selected[v] = true end

    local MDD = {Selected = selected, Opened = false, Options = opts}

    -- summary label builder
    local function summary()
        local keys = {}
        for k in pairs(selected) do table.insert(keys, k) end
        table.sort(keys)
        if #keys == 0 then return "None" end
        if #keys <= maxShow then return table.concat(keys, ", ") end
        return keys[1]..", +"..tostring(#keys - 1)
    end

    local container = Instance.new("Frame", card)
    container.Name             = "MDD_"..ttl
    container.Size             = UDim2.new(1,0,0,22)
    container.AutomaticSize    = Enum.AutomaticSize.None
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.LayoutOrder      = nextOrder()

    local header = Instance.new("TextButton", container)
    header.Size              = UDim2.new(1,0,0,22)
    header.BackgroundColor3  = T.Element
    header.BorderSizePixel   = 0
    header.Text              = ""
    header.AutoButtonColor   = false
    header.ZIndex            = 3
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,0)
    local hStroke = Instance.new("UIStroke", header)
    hStroke.Color = T.Border; hStroke.Thickness = 1

    local hLbl = Instance.new("TextLabel", header)
    hLbl.Size = UDim2.new(0.48,0,1,0); hLbl.Position = UDim2.fromOffset(7,0)
    hLbl.BackgroundTransparency=1; hLbl.Font=Enum.Font.Code
    hLbl.TextSize=11; hLbl.TextColor3=T.TextDim
    hLbl.TextXAlignment=Enum.TextXAlignment.Left; hLbl.Text=ttl

    local valLbl = Instance.new("TextLabel", header)
    valLbl.Size = UDim2.new(0.46,-20,1,0); valLbl.Position = UDim2.new(0.48,0,0,0)
    valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.Code
    valLbl.TextSize=10; valLbl.TextColor3=T.Text
    valLbl.TextXAlignment=Enum.TextXAlignment.Right
    valLbl.TextTruncate=Enum.TextTruncate.AtEnd
    valLbl.Text = summary()

    local arrow = Instance.new("TextLabel", header)
    arrow.Size=UDim2.fromOffset(14,22); arrow.Position=UDim2.new(1,-16,0,0)
    arrow.BackgroundTransparency=1; arrow.Font=Enum.Font.Code
    arrow.TextSize=8; arrow.TextColor3=T.TextMute; arrow.Text="▼"

    -- dropdown list
    local listFrame = Instance.new("ScrollingFrame", container)
    listFrame.Name="List"; listFrame.Size=UDim2.new(1,0,0,0)
    listFrame.Position=UDim2.fromOffset(0,24)
    listFrame.BackgroundColor3=T.Element; listFrame.BorderSizePixel=0
    listFrame.ClipsDescendants=true; listFrame.ZIndex=10; listFrame.Visible=false
    Instance.new("UICorner", listFrame).CornerRadius=UDim.new(0,3)
    local lStroke=Instance.new("UIStroke",listFrame)
    lStroke.Color=T.BorderLight; lStroke.Thickness=1
    local listLayout=Instance.new("UIListLayout",listFrame)
    listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,1)
    local lPad=Instance.new("UIPadding",listFrame)
    lPad.PaddingTop=UDim.new(0,3); lPad.PaddingBottom=UDim.new(0,3)

    local updateLayout = dropdownLayout(container, listFrame, config)
    local function buildList()
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(MDD.Options) do
            local isSel = selected[opt] == true
            local ob = Instance.new("TextButton", listFrame)
            ob.Size=UDim2.new(1,-6,0,20); ob.BorderSizePixel=0
            ob.BackgroundColor3 = isSel and Window.Accent or T.Element
            ob.BackgroundTransparency = isSel and 0.3 or 0.95
            ob.Font=Enum.Font.Code; ob.TextSize=11
            ob.TextColor3 = isSel and T.White or T.TextDim
            ob.TextXAlignment=Enum.TextXAlignment.Left
            ob.Text="  "..tostring(opt); ob.AutoButtonColor=false; ob.ZIndex=11
            Instance.new("UICorner",ob).CornerRadius=UDim.new(0,2)

            -- checkmark on right
            local ck=Instance.new("TextLabel",ob)
            ck.Size=UDim2.fromOffset(16,20); ck.Position=UDim2.new(1,-18,0,0)
            ck.BackgroundTransparency=1; ck.Font=Enum.Font.Code
            ck.TextSize=10; ck.ZIndex=12
            ck.TextColor3=Window.Accent; ck.Text=isSel and "✓" or ""

            ob.MouseEnter:Connect(function()
                if not selected[opt] then tw(ob,0.1,{BackgroundTransparency=0.7,TextColor3=T.Text}) end
            end)
            ob.MouseLeave:Connect(function()
                if not selected[opt] then tw(ob,0.1,{BackgroundTransparency=0.95,TextColor3=T.TextDim}) end
            end)
            ob.MouseButton1Click:Connect(function()
                if selected[opt] then
                    selected[opt] = nil
                else
                    selected[opt] = true
                end
                valLbl.Text = summary()
                buildList()
                -- collect ordered list
                local res={}; for k in pairs(selected) do table.insert(res,k) end
                pcall(cb, res)
            end)
        end
        updateLayout(MDD.Opened, #MDD.Options)
    end

    function MDD:Open()
        MDD.Opened=true; listFrame.Visible=true; buildList()
        tw(arrow,0.15,{Rotation=180})
        tw(hStroke,0.15,{Color=Window.Accent})
    end
    function MDD:Close()
        MDD.Opened=false
        tw(arrow,0.15,{Rotation=0}); tw(hStroke,0.15,{Color=T.Border})
        updateLayout(false, #MDD.Options)
    end
    function MDD:Set(tbl)   -- tbl = {"Head","Torso"}
        selected={}; for _,v in ipairs(tbl) do selected[v]=true end
        valLbl.Text=summary(); buildList()
        local res={}; for k in pairs(selected) do table.insert(res,k) end
        pcall(cb,res)
    end
    function MDD:GetSelected()
        local res={}; for k in pairs(selected) do table.insert(res,k) end
        return res
    end
    function MDD:Refresh(newOpts)
        MDD.Options=newOpts or {}; buildList()
    end

    header.MouseButton1Click:Connect(function()
        if MDD.Opened then MDD:Close() else MDD:Open() end
    end)

    return MDD
end

-- ==============================================================================
-- NOTIFICATION SYSTEM  (Hub:Notify)
-- ==============================================================================
function Library:_initNotify()
    if self._notifyReady then return end
    self._notifyReady  = true
    self._notifyQueue  = {}
    self._notifyActive = 0

    -- container pinned to bottom-right of screen
    local holder = Instance.new("Frame", self.ScreenGui)
    holder.Name              = "NotifyHolder"
    holder.Size              = UDim2.fromOffset(260, 600)
    holder.Position          = UDim2.new(1,-268, 1,-8)
    holder.AnchorPoint       = Vector2.new(0, 1)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel   = 0
    local hLayout = Instance.new("UIListLayout", holder)
    hLayout.SortOrder        = Enum.SortOrder.LayoutOrder
    hLayout.VerticalAlignment= Enum.VerticalAlignment.Bottom
    hLayout.Padding          = UDim.new(0,6)
    self._notifyHolder = holder
end

function Library:Notify(config)
    self:_initNotify()
    config = config or {}
    local title    = config.Title    or "Notification"
    local text     = config.Text     or ""
    local duration = config.Duration or 3
    local ntype    = config.Type     or "info"   -- "info" | "success" | "error" | "warning"

    local typeColors = {
        info    = self.Accent,
        success = Color3.fromRGB(34, 197, 94),
        error   = Color3.fromRGB(220, 50, 50),
        warning = Color3.fromRGB(245, 158, 11),
    }
    local accent = typeColors[ntype] or self.Accent

    local TOAST_H = text ~= "" and 52 or 34

    local toast = Instance.new("Frame", self._notifyHolder)
    toast.Name              = "Toast"
    toast.Size              = UDim2.fromOffset(0, TOAST_H)   -- width animates in
    toast.BackgroundColor3  = T.Card
    toast.BorderSizePixel   = 0
    toast.ClipsDescendants  = true
    toast.LayoutOrder       = os.clock() * 1000
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0,0)
    local tStroke = Instance.new("UIStroke", toast)
    tStroke.Color = T.Border; tStroke.Thickness = 1

    -- left accent bar
    local bar = Instance.new("Frame", toast)
    bar.Size=UDim2.new(0,3,1,0); bar.BackgroundColor3=accent; bar.BorderSizePixel=0
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,5)

    -- icon
    local icons = {info="ℹ", success="✓", error="✕", warning="⚠"}
    local iconLbl = Instance.new("TextLabel", toast)
    iconLbl.Size=UDim2.fromOffset(20,TOAST_H); iconLbl.Position=UDim2.fromOffset(10,0)
    iconLbl.BackgroundTransparency=1; iconLbl.Font=Enum.Font.Code
    iconLbl.TextSize=13; iconLbl.TextColor3=accent; iconLbl.Text=icons[ntype] or "ℹ"

    -- title
    local titleLbl = Instance.new("TextLabel", toast)
    titleLbl.Size=UDim2.new(1,-50,0,TOAST_H); titleLbl.Position=UDim2.fromOffset(32,0)
    titleLbl.BackgroundTransparency=1; titleLbl.Font=Enum.Font.Code
    titleLbl.TextSize=12; titleLbl.TextColor3=T.Text
    titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    titleLbl.Text=title

    if text ~= "" then
        titleLbl.Size=UDim2.new(1,-50,0,20)
        local bodyLbl = Instance.new("TextLabel", toast)
        bodyLbl.Size=UDim2.new(1,-50,0,16); bodyLbl.Position=UDim2.fromOffset(32,20)
        bodyLbl.BackgroundTransparency=1; bodyLbl.Font=Enum.Font.Code
        bodyLbl.TextSize=11; bodyLbl.TextColor3=T.TextDim
        bodyLbl.TextXAlignment=Enum.TextXAlignment.Left
        bodyLbl.TextTruncate=Enum.TextTruncate.AtEnd
        bodyLbl.Text=text
    end

    -- close button
    local closeBtn = Instance.new("TextButton", toast)
    closeBtn.Size=UDim2.fromOffset(16,16); closeBtn.Position=UDim2.new(1,-20,0,9)
    closeBtn.BackgroundTransparency=1; closeBtn.Font=Enum.Font.Code
    closeBtn.TextSize=10; closeBtn.TextColor3=T.TextMute; closeBtn.Text="✕"
    closeBtn.AutoButtonColor=false
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3=T.Text end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3=T.TextMute end)

    -- progress bar
    local prog = Instance.new("Frame", toast)
    prog.Size=UDim2.new(1,0,0,2); prog.Position=UDim2.new(0,0,1,-2)
    prog.BackgroundColor3=accent; prog.BackgroundTransparency=0.5; prog.BorderSizePixel=0

    -- animate in
    tw(toast, 0.25, {Size=UDim2.fromOffset(258, TOAST_H)})

    -- progress drain
    tw(prog, duration, {Size=UDim2.new(0,0,0,2)})

    local function dismiss()
        tw(toast, 0.2, {BackgroundTransparency=1, Size=UDim2.fromOffset(258,0)})
        task.delay(0.25, function() pcall(function() toast:Destroy() end) end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    task.delay(duration, function()
        if toast and toast.Parent then dismiss() end
    end)
end

-- ==============================================================================
-- CONFIG SAVE / LOAD  (Hub:SaveConfig / Hub:LoadConfig)
-- ==============================================================================
-- Serialization: lightweight key=value store (no JSON dependency)
-- Elements register themselves with Hub:_regElement(key, getter, setter)

function Library:_regElement(key, getter, setter)
    if not self._configElements then self._configElements = {} end
    assert(not self._configElements[key], "Duplicate ConfigKey: " .. key)
    self._configElements[key] = {get=getter, set=setter, default=getter()}
end

local function _serialize(tbl)
    -- Produces "key\31value\30key\31value" (unit separator / record separator)
    local parts = {}
    for k, v in pairs(tbl) do
        table.insert(parts, tostring(k).."\31"..tostring(v))
    end
    return table.concat(parts, "\30")
end

local function _deserialize(str)
    local tbl = {}
    if not str or str=="" then return tbl end
    for entry in (str.."\30"):gmatch("(.-)\30") do
        local k,v = entry:match("^(.-)\31(.*)$")
        if k then tbl[k]=v end
    end
    return tbl
end

function Library:SaveConfig(name)
    if not self._configElements then
        self:Notify({Title="Config", Text="No elements registered.", Type="warning", Duration=2})
        return
    end
    name = (name or "default"):gsub("[^%w_%-]","_")
    local data = {}
    for key, elem in pairs(self._configElements) do
        local ok, val = pcall(elem.get)
        if ok then data[key] = val end
    end
    local encoded = _serialize(data)
    local fname = "HutameHub_"..name..".cfg"
    local ok = pcall(writefile, fname, encoded)
    if ok then
        self:Notify({Title="Config Saved", Text=fname, Type="success", Duration=2.5})
    else
        self:Notify({Title="Config Error", Text="writefile not available.", Type="error", Duration=3})
    end
end

function Library:LoadConfig(name)
    name = (name or "default"):gsub("[^%w_%-]","_")
    local fname = "HutameHub_"..name..".cfg"
    local ok, content = pcall(readfile, fname)
    if not ok or not content then
        self:Notify({Title="Config Error", Text=fname.." not found.", Type="error", Duration=3})
        return
    end
    local data = _deserialize(content)
    local loaded = 0
    if self._configElements then
        for key, elem in pairs(self._configElements) do
            if data[key] ~= nil then
                local restored = pcall(elem.set, data[key])
                if restored then loaded = loaded + 1 end
            end
        end
    end
    self:Notify({Title="Config Loaded", Text=loaded.." values restored.", Type="success", Duration=2.5})
end

-- Auto-register Toggle, Slider, Dropdown, MultiDropdown
-- Patch _createSection to wrap CreateToggle / CreateSlider / CreateDropdown
local _origCreateSection = Library._createSection
function Library:_createSection(title, parent)
    local sec = _origCreateSection(self, title, parent)
    local hub = self

    -- patch CreateToggle to auto-register + Tooltip
    local _origToggle = sec.CreateToggle
    sec.CreateToggle = function(s, config)
        local t = _origToggle(s, config)
        if config.ConfigKey then
            hub:_regElement(config.ConfigKey,
                function() return tostring(t.State) end,
                function(v) t:Set(v=="true") end)
        end
        -- Tooltip support: attach to the row frame (parent of the checkbox)
        if config.Tooltip then
            local row = sec._card:FindFirstChild("Toggle_"..(config.Title or "Toggle"))
            if row then hub:_attachTooltip(row, config.Tooltip) end
        end
        return t
    end

    -- patch CreateSlider + Tooltip
    local _origSlider = sec.CreateSlider
    sec.CreateSlider = function(s, config)
        local sl = _origSlider(s, config)
        if config.ConfigKey then
            hub:_regElement(config.ConfigKey,
                function() return tostring(sl.Value) end,
                function(v) sl:Set(tonumber(v) or sl.Value) end)
        end
        if config.Tooltip then
            local cont = sec._card:FindFirstChild("Slider_"..(config.Title or "Slider"))
            if cont then hub:_attachTooltip(cont, config.Tooltip) end
        end
        return sl
    end

    -- patch CreateDropdown + Tooltip
    local _origDD = sec.CreateDropdown
    sec.CreateDropdown = function(s, config)
        local dd = _origDD(s, config)
        if config.ConfigKey then
            hub:_regElement(config.ConfigKey,
                function() return tostring(dd.Selected) end,
                function(v) dd:Set(v) end)
        end
        if config.Tooltip then
            local cont = sec._card:FindFirstChild("DD_"..(config.Title or "Dropdown"))
            if cont then hub:_attachTooltip(cont, config.Tooltip) end
        end
        return dd
    end

    -- inject CreateMultiDropdown
    local _nxtOrd = sec._order  -- captured closure won't drift
    function sec:CreateMultiDropdown(config)
        return _buildMultiDropdown(self, self._card, function()
            self._order = self._order + 1; return self._order
        end, config)
    end

    -- patch CreateMultiDropdown config key + Tooltip
    local _origMDD = sec.CreateMultiDropdown
    sec.CreateMultiDropdown = function(s, config)
        local mdd = _origMDD(s, config)
        if config.ConfigKey then
            hub:_regElement(config.ConfigKey,
                function()
                    local res=mdd:GetSelected(); table.sort(res)
                    return table.concat(res,",")
                end,
                function(v)
                    local tbl={}
                    if v and v~="" then
                        for part in (v..","):gmatch("(.-),") do table.insert(tbl,part) end
                    end
                    mdd:Set(tbl)
                end)
        end
        if config.Tooltip then
            local cont = sec._card:FindFirstChild("MDD_"..(config.Title or "MultiDropdown"))
            if cont then hub:_attachTooltip(cont, config.Tooltip) end
        end
        return mdd
    end

    return sec
end

-- ==============================================================================
-- WATERMARK  (Hub:SetWatermark / Hub:UpdateWatermark / Hub:RemoveWatermark)
-- ==============================================================================
-- Supports placeholders: {player}  {fps}  {ping}  {time}

function Library:SetWatermark(config)
    config = config or {}
    local fmt      = config.Format   or "{player}  |  {fps} fps"
    local pos      = config.Position or "TopRight"   -- TopLeft | TopRight | BottomLeft | BottomRight
    local bgAlpha  = config.BgAlpha  or 0.45

    if self._wmFrame then self._wmFrame:Destroy() end

    local wm = Instance.new("Frame", self.ScreenGui)
    wm.Name             = "Watermark"
    wm.Size             = UDim2.fromOffset(0, 22)
    wm.AutomaticSize    = Enum.AutomaticSize.X
    wm.BackgroundColor3 = T.Surface
    wm.BackgroundTransparency = bgAlpha
    wm.BorderSizePixel  = 0
    Instance.new("UICorner", wm).CornerRadius = UDim.new(0,0)
    local wmStroke = Instance.new("UIStroke", wm)
    wmStroke.Color = T.Border; wmStroke.Thickness = 1
    local wmPad = Instance.new("UIPadding", wm)
    wmPad.PaddingLeft=UDim.new(0,9); wmPad.PaddingRight=UDim.new(0,9)
    wmPad.PaddingTop=UDim.new(0,0); wmPad.PaddingBottom=UDim.new(0,0)

    -- position
    local anchors = {
        TopLeft     = {UDim2.fromOffset(10,10),    Vector2.new(0,0)},
        TopRight    = {UDim2.new(1,-10,0,10),      Vector2.new(1,0)},
        BottomLeft  = {UDim2.new(0,10,1,-10),      Vector2.new(0,1)},
        BottomRight = {UDim2.new(1,-10,1,-10),     Vector2.new(1,1)},
    }
    local posData = anchors[pos] or anchors.TopRight
    wm.Position    = posData[1]
    wm.AnchorPoint = posData[2]

    local lbl = Instance.new("TextLabel", wm)
    lbl.Size                 = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency= 1
    lbl.Font                 = Enum.Font.Code
    lbl.TextSize             = 11
    lbl.TextColor3           = T.Text
    lbl.RichText             = true
    lbl.AutomaticSize        = Enum.AutomaticSize.X
    lbl.Text                 = fmt

    self:_onAccent(function(c) wmStroke.Color = c end)

    self._wmFrame = wm
    self._wmFmt   = fmt

    -- FPS tracker
    local fps, lastTick, frames = 60, os.clock(), 0
    local fpsConn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastTick >= 0.5 then
            fps = math.floor(frames / (now - lastTick) + 0.5)
            frames = 0; lastTick = now
        end
    end)

    -- update loop
    local function buildText(f)
        local h = math.floor(os.clock() / 3600 % 24)
        local m = math.floor(os.clock() / 60 % 60)
        local s = math.floor(os.clock() % 60)
        local timeStr = string.format("%02d:%02d:%02d", h, m, s)

        -- ping via Stats service (may not be available in all contexts)
        local ping = 0
        pcall(function()
            ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        end)

        local result = f
            :gsub("{player}", LocalPlayer.Name)
            :gsub("{fps}",    tostring(fps))
            :gsub("{ping}",   tostring(math.floor(ping)))
            :gsub("{time}",   timeStr)
            :gsub("{game}",   tostring(game.Name))

        -- color fps: green ≥50, yellow ≥30, red <30
        local fpsColHex = fps >= 50 and "7ee787" or fps >= 30 and "f5c542" or "ff7b72"
        result = result:gsub(tostring(fps).." fps",
            string.format('<font color="#%s">%d fps</font>', fpsColHex, fps))

        return result
    end

    local wmConn = RunService.Heartbeat:Connect(function()
        if not wm or not wm.Parent then return end
        lbl.Text = buildText(self._wmFmt or fmt)
    end)

    -- store connections for cleanup
    if self._wmConn  then self._wmConn:Disconnect() end
    if self._fpsConn then self._fpsConn:Disconnect() end
    self._wmConn  = wmConn
    self._fpsConn = fpsConn
end

function Library:UpdateWatermark(newFmt)
    self._wmFmt = newFmt
end

function Library:RemoveWatermark()
    if self._wmFrame then self._wmFrame:Destroy(); self._wmFrame = nil end
    if self._wmConn  then self._wmConn:Disconnect();  self._wmConn  = nil end
    if self._fpsConn then self._fpsConn:Disconnect(); self._fpsConn = nil end
end

-- clean up watermark on destroy too
local _origDestroy = Library.Destroy
function Library:Destroy()
    _origDestroy(self)
    self:RemoveWatermark()
end

-- Profiles use a manifest so environments without listfiles remain supported.
local HttpService = game:GetService("HttpService")
local function profileName(name)
    assert(type(name) == "string" and name:match("^[%w_%-]+$") and #name <= 48,
        "Profile name: 1-48 letters, digits, underscores or hyphens")
    return name
end
local function profilePath(name) return "HutameHub_" .. profileName(name) .. ".cfg" end
local function readManifest()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile("HutameHub_profiles.json"))
    end)
    if ok and type(data) == "table" and type(data.names) == "table" then return data end
    return {names = {}}
end
local function writeManifest(data)
    writefile("HutameHub_profiles.json", HttpService:JSONEncode(data))
end

function Library:ListProfiles()
    local names = {}
    for name in pairs(readManifest().names) do table.insert(names, name) end
    table.sort(names)
    return names
end

function Library:SaveProfile(name)
    local ok, err = pcall(function()
        local path = profilePath(name)
        local values = {}
        for key, item in pairs(self._configElements or {}) do values[key] = item.get() end
        writefile(path, _serialize(values))
        local manifest = readManifest()
        manifest.names[name] = true
        writeManifest(manifest)
    end)
    self:Notify({Title="Profile", Text=ok and "Saved" or tostring(err), Type=ok and "success" or "error"})
    return ok, err
end

function Library:LoadProfile(name)
    local ok, err = pcall(function()
        local values = _deserialize(readfile(profilePath(name)))
        for key, item in pairs(self._configElements or {}) do
            if values[key] ~= nil then item.set(values[key]) end
        end
        self:RefreshConditions()
    end)
    self:Notify({Title="Profile", Text=ok and "Loaded" or tostring(err), Type=ok and "success" or "error"})
    return ok, err
end

function Library:RenameProfile(oldName, newName)
    local ok, err = pcall(function()
        profileName(oldName); profileName(newName)
        local manifest = readManifest()
        assert(manifest.names[oldName], "Unknown profile")
        assert(not manifest.names[newName], "Profile already exists")
        assert(type(delfile) == "function", "delfile unavailable")
        local exists = pcall(readfile, profilePath(newName))
        assert(not exists, "Destination file already exists")
        writefile(profilePath(newName), readfile(profilePath(oldName)))
        manifest.names[newName] = true; manifest.names[oldName] = nil
        if manifest.default == oldName then manifest.default = newName end
        writeManifest(manifest)
        delfile(profilePath(oldName))
    end)
    return ok, err
end

function Library:DeleteProfile(name)
    local ok, err = pcall(function()
        profileName(name)
        local manifest = readManifest()
        assert(manifest.names[name], "Unknown profile")
        delfile(profilePath(name))
        manifest.names[name] = nil
        if manifest.default == name then manifest.default = nil end
        writeManifest(manifest)
    end)
    return ok, err
end

function Library:SetDefaultProfile(name)
    local ok, err = pcall(function()
        local manifest = readManifest()
        if name ~= nil then profileName(name); assert(manifest.names[name], "Unknown profile") end
        manifest.default = name
        writeManifest(manifest)
    end)
    return ok, err
end

-- Call after all controls have been registered, never during window construction.
function Library:LoadDefaultProfile()
    local name = readManifest().default
    if not name then return false, "No default profile" end
    return self:LoadProfile(name)
end

function Library:ResetValues()
    for _, control in ipairs(self._resetControls or {}) do control:Reset() end
    self:RefreshConditions()
end

function Library:RefreshConditions()
    if self._refreshingConditions then return end
    self._refreshingConditions = true
    for _, rule in ipairs(self._conditions or {}) do
        local ok, value = pcall(rule.test)
        if not ok then warn("HutameHub condition: " .. tostring(value)) end
        local enabled = ok and not not value
        if rule.mode == "hide" then
            rule.row:SetAttribute("ConditionVisible", enabled)
            rule.row.Visible = enabled and rule.row.Parent:GetAttribute("Collapsed") ~= true
        else
            rule.row:SetAttribute("ConditionEnabled", enabled)
            rule.row.Interactable = enabled
            for _, child in ipairs(rule.row:GetDescendants()) do
                if child:IsA("GuiObject") then child.Interactable = enabled end
            end
            rule.row.BackgroundTransparency = enabled and rule.transparency or 0.65
        end
    end
    self._refreshingConditions = false
end

function Library:SetCondition(control, predicate, mode)
    assert(type(predicate) == "function", "Condition must be a function")
    assert(mode == nil or mode == "hide" or mode == "disable", "Mode: hide or disable")
    local row = (self._controlRows or {})[control]
    assert(row, "Control does not belong to this window")
    self._conditions = self._conditions or {}
    table.insert(self._conditions, {row=row, test=predicate, mode=mode or "hide", transparency=row.BackgroundTransparency})
    self:RefreshConditions()
end

function Library:_checkBindings()
    local used = {[self.ToggleKey]="Window toggle", [Enum.KeyCode.Minus]="Window toggle"}
    local collisions = {}
    for _, binding in ipairs(self._bindings or {}) do
        local key = binding.get()
        if key and key ~= Enum.KeyCode.None then
            if used[key] then table.insert(collisions, key.Name .. ": " .. used[key] .. " / " .. binding.title)
            else used[key] = binding.title end
        end
    end
    local signature = table.concat(collisions, "; ")
    if signature ~= "" and signature ~= self._lastBindingWarning then
        self:Notify({Title="Key conflict", Text=signature, Type="warning", Duration=5})
    end
    self._lastBindingWarning = signature
end

local advancedSection = Library._createSection
function Library:_createSection(title, parent)
    local section = advancedSection(self, title, parent)
    local hub = self
    for _, name in ipairs({"Toggle", "Slider", "Dropdown", "MultiDropdown", "Textbox", "Keybind", "ColorPicker", "Button"}) do
        local kind = name
        local create = section["Create" .. kind]
        section["Create" .. kind] = function(sec, config)
            config = config or {}
            local options = {}
            for key, value in pairs(config) do options[key] = value end
            local callback = config.Callback
            options.Callback = function(...)
                if callback then
                    local ok, err = pcall(callback, ...)
                    if not ok then warn("HutameHub callback: " .. tostring(err)) end
                end
                hub:RefreshConditions()
                hub:_checkBindings()
            end
            local previous = {}
            for _, child in ipairs(sec._card:GetChildren()) do previous[child] = true end
            local control = create(sec, options)
            local row
            for _, child in ipairs(sec._card:GetChildren()) do
                if child:IsA("GuiObject") and not previous[child] then row = child; break end
            end
            hub._controlRows = hub._controlRows or {}
            hub._controlRows[control] = row
            if kind ~= "Button" then
                local property = ({Toggle="State", Slider="Value", Dropdown="Selected", Textbox="Text", Keybind="Key", ColorPicker="Color"})[kind]
                local default = kind == "MultiDropdown" and control:GetSelected() or control[property]
                local set = control.Set
                control.Set = function(c, value)
                    set(c, value)
                    hub:RefreshConditions(); hub:_checkBindings()
                end
                function control:Reset() self:Set(default) end
                hub._resetControls = hub._resetControls or {}
                table.insert(hub._resetControls, control)
                if kind == "MultiDropdown" and config.ConfigKey then
                    local item = hub._configElements[config.ConfigKey]
                    item.get = function() return HttpService:JSONEncode(control:GetSelected()) end
                    item.set = function(value)
                        local ok, selected = pcall(function() return HttpService:JSONDecode(value) end)
                        if ok and type(selected) == "table" then control:Set(selected)
                        else
                            local legacy = {}
                            for part in (value .. ","):gmatch("(.-),") do
                                if part ~= "" then table.insert(legacy, part) end
                            end
                            control:Set(legacy)
                        end
                    end
                end
                if config.ConfigKey and (kind == "Textbox" or kind == "Keybind" or kind == "ColorPicker") then
                    hub:_regElement(config.ConfigKey, function()
                        if kind == "Keybind" then return control.Key.Name end
                        if kind == "ColorPicker" then return control.Color:ToHex() end
                        return HttpService:JSONEncode(control.Text)
                    end, function(value)
                        if kind == "Keybind" then control:Set(Enum.KeyCode[value])
                        elseif kind == "ColorPicker" then control:Set(Color3.fromHex(value))
                        else control:Set(HttpService:JSONDecode(value)) end
                    end)
                end
            end
            if kind == "Keybind" or (kind == "Toggle" and config.Keybind) then
                hub._bindings = hub._bindings or {}
                table.insert(hub._bindings, {title=config.Title or kind, get=function()
                    return kind == "Keybind" and control.Key or config.Keybind
                end})
                hub:_checkBindings()
            end
            if config.VisibleWhen then hub:SetCondition(control, config.VisibleWhen, "hide") end
            if config.EnabledWhen then hub:SetCondition(control, config.EnabledWhen, "disable") end
            return control
        end
    end
    return section
end

function Library:Confirm(config)
    config = config or {}
    if self._cancelConfirm then self._cancelConfirm() end
    local overlay = Instance.new("TextButton", self.ScreenGui)
    overlay.Name="Confirmation"; overlay.Size=UDim2.fromScale(1,1)
    overlay.BackgroundColor3=T.Black; overlay.BackgroundTransparency=0.25
    overlay.Text=""; overlay.AutoButtonColor=false; overlay.Modal=true; overlay.ZIndex=200
    local panel = Instance.new("Frame", overlay)
    panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
    panel.Size=UDim2.new(0.85,0,0,180); panel.BackgroundColor3=T.Card; panel.ZIndex=201
    local limit=Instance.new("UISizeConstraint",panel); limit.MaxSize=Vector2.new(380,180)
    local label=Instance.new("TextLabel",panel)
    label.Position=UDim2.fromOffset(16,12); label.Size=UDim2.new(1,-32,0,105)
    label.BackgroundTransparency=1; label.TextColor3=T.Text; label.Font=Enum.Font.Code
    label.TextSize=15; label.TextWrapped=true; label.ZIndex=202
    label.Text=(config.Title or "Confirm") .. "\n\n" .. (config.Text or "Continue?")
    local settled=false
    local function finish(accepted)
        if settled then return end
        settled=true; overlay:Destroy(); self._confirm=nil; self._cancelConfirm=nil
        if accepted and config.OnConfirm then config.OnConfirm()
        elseif not accepted and config.OnCancel then config.OnCancel() end
    end
    for index, text in ipairs({config.CancelText or "Cancel", config.ConfirmText or "Confirm"}) do
        local accepted=index==2
        local button=Instance.new("TextButton",panel)
        button.Position=UDim2.new((index-1)*0.5,12,1,-48); button.Size=UDim2.new(0.5,-24,0,32)
        button.Text=text; button.Font=Enum.Font.Code; button.TextSize=14
        button.BackgroundColor3=accepted and self.Accent or T.Element
        button.TextColor3=accepted and T.Black or T.Text; button.ZIndex=202
        button.Activated:Connect(function() finish(accepted) end)
    end
    self._confirm=overlay
    self._cancelConfirm=function() finish(false) end
    return {Cancel=function() finish(false) end}
end

-- Floating keybind list. It stays visible when the main window is hidden.
function Library:RegisterKeybindDisplay(config)
    config = config or {}
    assert(type(config.Title) == "string", "Keybind display requires Title")
    assert(type(config.Key) == "function", "Keybind display requires Key getter")
    local entry = {
        title = config.Title,
        key = config.Key,
        active = type(config.Active) == "function" and config.Active or nil,
        visible = type(config.Visible) == "function" and config.Visible or nil,
    }
    self._keybindDisplays = self._keybindDisplays or {}
    table.insert(self._keybindDisplays, entry)
    return {
        Remove = function()
            for index, current in ipairs(self._keybindDisplays or {}) do
                if current == entry then table.remove(self._keybindDisplays, index); break end
            end
        end,
    }
end

function Library:CreateKeybindList(config)
    config = config or {}
    if self._keybindListFrame then self._keybindListFrame:Destroy() end
    if self._keybindListConnection then self._keybindListConnection:Disconnect() end

    local frame = Instance.new("Frame", self.ScreenGui)
    frame.Name = "KeybindList"
    frame.Position = config.Position or UDim2.fromOffset(12, 180)
    frame.Size = UDim2.fromOffset(config.Width or 210, 30)
    frame.BackgroundColor3 = T.Card
    frame.BackgroundTransparency = config.Transparency or 0.08
    frame.BorderSizePixel = 0
    frame.ZIndex = 140
    frame.Visible = config.Visible ~= false
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = T.BorderLight; stroke.Thickness = 1
    local accent = Instance.new("Frame", frame)
    accent.Size = UDim2.new(1, 0, 0, 1); accent.BackgroundColor3 = self.Accent
    accent.BorderSizePixel = 0; accent.ZIndex = 142
    self:_onAccent(function(color) accent.BackgroundColor3 = color end)
    local title = Instance.new("TextLabel", frame)
    title.Position = UDim2.fromOffset(8, 4); title.Size = UDim2.new(1, -16, 0, 20)
    title.BackgroundTransparency = 1; title.Font = Enum.Font.Code; title.TextSize = 11
    title.TextColor3 = T.TextDim; title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = string.upper(config.Title or "KEYBINDS"); title.ZIndex = 142

    local labels, elapsed = {}, 1
    local function update()
        local rows = {}
        if config.IncludeWindowToggle ~= false then
            table.insert(rows, {title=self.Title, key=self.ToggleKey})
        end
        if config.IncludeControls ~= false then
            for _, binding in ipairs(self._bindings or {}) do
                table.insert(rows, {title=binding.title, key=binding.get()})
            end
        end
        for _, entry in ipairs(self._keybindDisplays or {}) do
            local okVisible, visible = true, true
            if entry.visible then okVisible, visible = pcall(entry.visible) end
            if okVisible and visible then
                local okKey, key = pcall(entry.key)
                local okActive, active = true, nil
                if entry.active then okActive, active = pcall(entry.active) end
                if okKey then table.insert(rows, {title=entry.title, key=key, active=okActive and active or nil}) end
            end
        end
        while #labels < #rows do
            local label = Instance.new("TextLabel", frame)
            label.BackgroundTransparency = 1; label.Font = Enum.Font.Code; label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left; label.ZIndex = 142
            table.insert(labels, label)
        end
        for index, label in ipairs(labels) do
            local row = rows[index]
            label.Visible = row ~= nil
            if row then
                local keyName = row.key and row.key.Name or tostring(row.key or "None")
                label.Position = UDim2.fromOffset(8, 25 + (index - 1) * 19)
                label.Size = UDim2.new(1, -16, 0, 18)
                label.Text = string.format("[%s]  %s%s", keyName, row.title,
                    row.active == nil and "" or (row.active and "  ACTIVE" or "  OFF"))
                label.TextColor3 = row.active == true and self.Accent or T.TextDim
            end
        end
        frame.Size = UDim2.fromOffset(config.Width or 210, 30 + #rows * 19)
    end
    update()
    self._keybindListConnection = RunService.Heartbeat:Connect(function(delta)
        elapsed = elapsed + delta
        if elapsed >= 0.1 then elapsed = 0; update() end
    end)
    self._keybindListFrame = frame
    return {
        SetVisible = function(_, visible) frame.Visible = not not visible end,
        Destroy = function()
            if self._keybindListConnection then self._keybindListConnection:Disconnect(); self._keybindListConnection=nil end
            if frame.Parent then frame:Destroy() end
            self._keybindListFrame = nil
        end,
    }
end

-- Drawing backend is activated only when Streamproof is explicitly requested.
-- Keep the normal ScreenGui path unchanged for existing consumers.
local DrawingBackend = (function()
    local Backend = {}
    Backend.__index = Backend

    local INPUT = game:GetService("UserInputService")
    local RUN = game:GetService("RunService")
    local WHITE = Color3.fromRGB(235, 235, 235)
    local DIM = Color3.fromRGB(150, 150, 150)
    local BG = Color3.fromRGB(13, 13, 13)
    local PANEL = Color3.fromRGB(22, 22, 22)
    local BORDER = Color3.fromRGB(48, 48, 48)
    local characters = {Zero="0", One="1", Two="2", Three="3", Four="4", Five="5",
        Six="6", Seven="7", Eight="8", Nine="9", Space=" ", Period=".", Minus="-"}

    local function hit(p, x, y, w, h)
        return p.X >= x and p.X <= x + w and p.Y >= y and p.Y <= y + h
    end

    function Backend.new(config)
        local bridge, requestFunction
        if config.Streamproof then
            requestFunction = request or http_request
            assert(type(requestFunction) == "function", "Streamproof requires the Madium request API")
            local ok, settings = pcall(function()
                return HttpService:JSONDecode(readfile(config.StreamproofConfig or "HutameHub_overlay.json"))
            end)
            assert(ok and type(settings) == "table", "Start tools/streamproof_overlay.py before enabling Streamproof")
            assert(type(settings.url) == "string" and settings.url:match("^http://127%.0%.0%.1:%d+$"), "Invalid local overlay address")
            local response = requestFunction({Url=settings.url.."/status",Method="GET",
                Headers={Authorization="Bearer "..settings.token}})
            assert(response.StatusCode == 200, "Local overlay unavailable")
            local status = HttpService:JSONDecode(response.Body)
            assert(status.captureExcluded == true and status.affinity == 17 and status.windowFound,
                "Local overlay did not confirm capture exclusion and the Roblox window")
            bridge = settings
        else
            assert(type(Drawing) == "table" and type(Drawing.new) == "function",
                "Drawing renderer requires the executor Drawing API")
        end
        local self = setmetatable({
            Title = config.Title or "HutameHub", Version = config.Version or "",
            Accent = config.Accent or Color3.fromRGB(235, 235, 235),
            ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl,
            Tabs = {}, ActiveTab = nil, _hits = {},
            _pool = {}, _kinds = {}, _kindPools = {}, _usedKinds = {}, _drawState = {},
            _connections = {}, _visible = true, _scroll = {0, 0}, _scrollMax = {0, 0},
            _position = Vector2.new(140, 110), _width = 760, _height = 560,
            _bindings = {}, _keybindDisplays = {},
            _bridge = bridge, _request = requestFunction,
        }, Backend)
        if workspace.CurrentCamera then
            local viewport = workspace.CurrentCamera.ViewportSize
            self._position = Vector2.new(math.max(0, (viewport.X - 760) / 2), math.max(0, (viewport.Y - 560) / 2))
        end
        self.MainFrame = setmetatable({}, {
            __index = function(_, key)
                if key == "Visible" then return self._visible end
            end,
            __newindex = function(_, key, value)
                if key == "Visible" then self._visible = not not value end
            end,
        })
        if bridge then
            task.spawn(function()
                while not self._destroyed do
                    if self._frameJson and (self._frameJson ~= self._sentFrameJson or
                        os.clock() - (self._lastSend or 0) >= 0.4) then
                        local frame = self._frameJson
                        local ok, response = pcall(requestFunction, {Url=bridge.url.."/frame",Method="POST",
                            Headers={Authorization="Bearer "..bridge.token,["Content-Type"]="application/json"},
                            Body=frame})
                        if not ok or response.StatusCode ~= 200 then
                            if not self._bridgeFailed then warn("HutameHub overlay connection failed") end
                            self._bridgeFailed = true
                        else
                            self._bridgeFailed = false
                            self._sentFrameJson, self._lastSend = frame, os.clock()
                        end
                    end
                    task.wait(1/30)
                end
            end)
        end
        self._connections[1] = RUN.RenderStepped:Connect(function()
            local now = os.clock()
            local interval = (self._drag or self._slider or self._capture) and 1/60 or 1/30
            if now - (self._lastRender or 0) >= interval then
                self._lastRender = now
                self:_render()
            end
        end)
        self._connections[2] = INPUT.InputBegan:Connect(function(input, processed)
            if (input.KeyCode == self.ToggleKey or input.KeyCode == Enum.KeyCode.Minus)
                and not processed and not self._capture then
                self._visible = not self._visible
                return
            end
            if self._capture then
                local capture = self._capture
                self._capture = nil
                if capture.kind == "key" then
                    capture.control.Listening = false
                    capture.control:Set(input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType)
                elseif capture.kind == "text" and input.KeyCode == Enum.KeyCode.Return then
                    capture.control:Set(capture.value)
                elseif capture.kind == "text" and input.KeyCode == Enum.KeyCode.Backspace then
                    capture.value = capture.value:sub(1, -2)
                    self._capture = capture
                elseif capture.kind == "text" and input.KeyCode == Enum.KeyCode.Escape then
                    capture.control:Set(capture.original)
                elseif capture.kind == "text" then
                    local char = input.KeyCode.Name
                    local shifted = INPUT:IsKeyDown(Enum.KeyCode.LeftShift) or INPUT:IsKeyDown(Enum.KeyCode.RightShift)
                    if char == "V" and type(getclipboard) == "function" and
                        (INPUT:IsKeyDown(Enum.KeyCode.LeftControl) or INPUT:IsKeyDown(Enum.KeyCode.RightControl)) then
                        local ok, pasted = pcall(getclipboard)
                        if ok and type(pasted) == "string" then capture.value = capture.value .. pasted end
                    elseif #char == 1 then
                        capture.value = capture.value .. (shifted and char or char:lower())
                    elseif characters[char] then
                        capture.value = capture.value .. (shifted and char == "Minus" and "_" or characters[char])
                    end
                    self._capture = capture
                end
                if not self._capture then self._releaseListening = true end
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and self._visible then
                local mouse = INPUT:GetMouseLocation()
                for i = #self._hits, 1, -1 do
                    local area = self._hits[i]
                    if hit(mouse, area[1], area[2], area[3], area[4]) then
                        area[5](mouse)
                        return
                    end
                end
            end
            if not processed then
                for _, binding in ipairs(self._bindings) do
                    if binding.key == input.KeyCode and binding.callback then
                        pcall(binding.callback, input.KeyCode)
                    end
                end
            end
        end)
        self._connections[3] = INPUT.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and self._drag then
                self._position = self._drag.origin + (INPUT:GetMouseLocation() - self._drag.mouse)
            elseif input.UserInputType == Enum.UserInputType.MouseMovement and self._slider then
                local s = self._slider
                s.control:Set(s.min + math.clamp((INPUT:GetMouseLocation().X - s.x) / s.width, 0, 1) * (s.max - s.min))
            elseif input.UserInputType == Enum.UserInputType.MouseWheel and self._visible then
                local mouse = INPUT:GetMouseLocation()
                for _, area in ipairs(self._dropdownAreas or {}) do
                    if hit(mouse, area.x, area.y, area.width, area.height) then
                        local control = area.control
                        control.OptionScroll = math.clamp((control.OptionScroll or 0) - input.Position.Z,
                            0, math.max(0, #control.Options - control.MaxVisibleItems))
                        return
                    end
                end
                local col = mouse.X < self._position.X + 132 + (self._width - 144) / 2 and 1 or 2
                if hit(mouse, self._position.X + 132, self._position.Y + 40,
                    self._width - 144, self._height - 64) then
                    self._scroll[col] = math.clamp(self._scroll[col] - input.Position.Z * 36, 0, self._scrollMax[col])
                end
            end
        end)
        self._connections[4] = INPUT.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self._drag = nil
                self._slider = nil
            end
        end)
        return self
    end

    function Backend:_primitive(kind)
        local used = (self._usedKinds[kind] or 0) + 1
        self._usedKinds[kind] = used
        local kindPool = self._kindPools[kind]
        if not kindPool then
            kindPool = {}
            self._kindPools[kind] = kindPool
        end
        local object = kindPool[used]
        if not object then
            if self._bridge then
                object = {Visible=false,Remove=function(item) item.Visible=false end}
            else object = Drawing.new(kind) end
            kindPool[used] = object
            self._pool[#self._pool + 1] = object
            self._kinds[#self._kinds + 1] = kind
        end
        self:_drawProperty(object, "Visible", true)
        return object
    end

    function Backend:_drawProperty(object, key, value)
        local state = self._drawState[object]
        if not state then
            state = {}
            self._drawState[object] = state
        end
        if state[key] ~= value then
            object[key] = value
            state[key] = value
        end
    end

    -- Conservative monospace measurements keep fields inside their own column.
    local function fit(value, width, size)
        local text = tostring(value or "")
        local count = math.max(0, math.floor(width / ((size or 13) * 0.63)))
        if #text <= count then return text end
        return text:sub(1, math.max(0, count - 3)) .. (count >= 3 and "..." or "")
    end

    local function wrap(value, width)
        local count = math.max(1, math.floor(width / 7.8))
        local lines, line = {}, ""
        for word in tostring(value or ""):gmatch("%S+") do
            if #line + #word + 1 > count and line ~= "" then
                lines[#lines + 1], line = line, ""
            end
            while #word > count do
                lines[#lines + 1], word = word:sub(1, count), word:sub(count + 1)
            end
            line = line == "" and word or line .. " " .. word
        end
        if line ~= "" or #lines == 0 then lines[#lines + 1] = line end
        return lines
    end

    function Backend:_box(x, y, w, h, color, z)
        if self._clip then
            local clip = self._clip
            local right, bottom = math.min(x + w, clip[1] + clip[3]), math.min(y + h, clip[2] + clip[4])
            x, y = math.max(x, clip[1]), math.max(y, clip[2])
            w, h = right - x, bottom - y
        end
        if w <= 0 or h <= 0 then return end
        local o = self:_primitive("Square")
        self:_drawProperty(o, "Position", Vector2.new(math.floor(x), math.floor(y)))
        self:_drawProperty(o, "Size", Vector2.new(math.floor(w), math.floor(h)))
        self:_drawProperty(o, "Color", color)
        self:_drawProperty(o, "Filled", true)
        self:_drawProperty(o, "Thickness", 0)
        self:_drawProperty(o, "Transparency", 1)
        self:_drawProperty(o, "ZIndex", z or 1)
    end

    function Backend:_text(value, x, y, color, size, z)
        size = size or 13
        if self._clip then
            local clip = self._clip
            if y < clip[2] or y + size + 2 > clip[2] + clip[4] or x < clip[1] then return end
            value = fit(value, clip[1] + clip[3] - x, size)
        end
        local o = self:_primitive("Text")
        self:_drawProperty(o, "Position", Vector2.new(math.floor(x), math.floor(y)))
        self:_drawProperty(o, "Text", tostring(value or ""))
        self:_drawProperty(o, "Color", color or WHITE)
        self:_drawProperty(o, "Size", size)
        self:_drawProperty(o, "Font", Drawing and Drawing.Fonts and Drawing.Fonts.Plex or 2)
        self:_drawProperty(o, "Outline", true)
        self:_drawProperty(o, "Transparency", 1)
        self:_drawProperty(o, "ZIndex", z or 2)
    end

    function Backend:_hit(x, y, w, h, callback)
        if self._clip then
            local clip = self._clip
            local right, bottom = math.min(x + w, clip[1] + clip[3]), math.min(y + h, clip[2] + clip[4])
            x, y = math.max(x, clip[1]), math.max(y, clip[2])
            w, h = right - x, bottom - y
        end
        if w > 0 and h > 0 then self._hits[#self._hits + 1] = {x, y, w, h, callback} end
    end

    function Backend:_hover(x, y, w, h)
        local mouse = INPUT:GetMouseLocation()
        if self._clip and not hit(mouse, self._clip[1], self._clip[2], self._clip[3], self._clip[4]) then return false end
        return hit(mouse, x, y, w, h)
    end

    function Backend:_field(x, y, w, h, hovered, z)
        z = z or 4
        self:_box(x, y, w, h, Color3.fromRGB(5, 5, 5), z)
        self:_box(x + 1, y + 1, w - 2, h - 2, hovered and DIM or BORDER, z)
        self:_box(x + 2, y + 2, w - 4, h - 4, Color3.fromRGB(25, 25, 25), z)
        self:_box(x + 2, y + 2, w - 4, 1, Color3.fromRGB(38, 38, 38), z)
    end

    function Backend:_labelLines(c, width)
        if c._wrappedText ~= c.Text or c._wrappedWidth ~= width then
            c._wrappedText, c._wrappedWidth = c.Text, width
            c._wrappedLines = wrap(c.Text, width)
        end
        return c._wrappedLines
    end

    function Backend:_controlHeight(c, width)
        if c.Visible == false then return 0 end
        if c.Kind == "label" then return tostring(c.Text or ""):match("%S") and (#self:_labelLines(c, width) * 17 + 5) or 0 end
        if c.Kind == "separator" then return 12 end
        if c.Kind == "dropdown" or c.Kind == "multi" then
            return 46 + (c.Opened and math.min(#c.Options, c.MaxVisibleItems) * 22 + 2 or 0)
        end
        if c.Kind == "textbox" then return 46 end
        if c.Kind == "slider" then return 38 end
        return 26
    end

    function Backend:_render()
        self:RefreshConditions()
        if self._releaseListening then
            self._listeningForKey = false
            self._releaseListening = nil
        end
        self._usedKinds = {}
        self._hits = {}
        self._dropdownAreas = {}
        if self._visible then
            local p, w, h = self._position, self._width, self._height
            local x, y = p.X, p.Y
            -- Nested one-pixel borders, compact title strip and inset content.
            self:_box(x - 3, y - 3, w + 6, h + 6, Color3.fromRGB(4, 4, 4))
            self:_box(x - 2, y - 2, w + 4, h + 4, BORDER)
            self:_box(x - 1, y - 1, w + 2, h + 2, Color3.fromRGB(9, 9, 9))
            self:_box(x, y, w, h, Color3.fromRGB(27, 27, 27))
            self:_box(x + 1, y + 1, w - 2, 1, DIM)
            self:_text(self.Title, x + 10, y + 9, WHITE, 13)
            self:_text("/ " .. self.Version, x + 20 + #self.Title * 8, y + 9, DIM, 12)
            self:_text("[" .. self.ToggleKey.Name .. "]", x + w - 84, y + 9, DIM, 12)
            self:_text("x", x + w - 20, y + 9, DIM, 13)
            self:_hit(x + w - 30, y + 3, 27, 24, function() self._visible = false end)
            self:_hit(x, y, w - 32, 29, function(mouse)
                self._drag = {origin = self._position, mouse = mouse}
            end)
            self:_box(x + 7, y + 29, w - 14, h - 52, Color3.fromRGB(5, 5, 5))
            self:_box(x + 8, y + 30, w - 16, h - 54, BORDER)
            self:_box(x + 9, y + 31, w - 18, h - 56, BG)
            self:_box(x + 121, y + 31, 1, h - 56, BORDER)
            for index, tab in ipairs(self.Tabs) do
                local ty, active = y + 43 + (index - 1) * 33, self.ActiveTab == tab
                local hovered = self:_hover(x + 15, ty, 101, 27)
                if active or hovered then
                    self:_box(x + 15, ty, 101, 27, active and Color3.fromRGB(34,34,34) or PANEL)
                    self:_box(x + 15, ty, 101, 1, BORDER)
                    if active then self:_box(x + 15, ty, 2, 27, WHITE) end
                end
                self:_text(tab.Name, x + 26, ty + 6, active and WHITE or DIM, 13)
                if (tab.Badge or 0) > 0 then self:_text(tostring(tab.Badge), x + 99, ty + 6, WHITE, 11) end
                self:_hit(x + 15, ty, 101, 27, function()
                    self.ActiveTab = tab
                    self._scroll = {0, 0}
                end)
            end
            self:_text(self.ActiveTab and self.ActiveTab.Name or "", x + 11, y + h - 17, DIM, 11)
            local state = self._bridge and (self._bridgeFailed and "overlay offline" or "streamproof") or "drawing"
            self:_text(state, x + w - #state * 7 - 12, y + h - 17, DIM, 11)
            if self.ActiveTab then
                local cw = math.floor((w - 158) / 2)
                local top, bottom = y + 42, y + h - 35
                for col = 1, 2 do
                    local sx = x + 132 + (col - 1) * (cw + 12)
                    local total = 0
                    for _, section in ipairs(self.ActiveTab.Sections) do
                        if section.Column == col then
                            local height = 30
                            if not section.Collapsed then
                                for _, c in ipairs(section.Controls) do height = height + self:_controlHeight(c, cw - 20) end
                            end
                            section._drawHeight = height
                            total = total + height + 12
                        end
                    end
                    self._scrollMax[col] = math.max(0, total - 12 - (bottom - top))
                    self._scroll[col] = math.clamp(self._scroll[col], 0, self._scrollMax[col])
                    local sy = top - self._scroll[col]
                    self._clip = {sx, top, cw, bottom - top}
                    for _, section in ipairs(self.ActiveTab.Sections) do
                        if section.Column == col then
                            local height = section._drawHeight
                            self:_box(sx, sy, cw, height, Color3.fromRGB(4,4,4), 2)
                            self:_box(sx + 1, sy + 1, cw - 2, height - 2, BORDER, 2)
                            self:_box(sx + 2, sy + 2, cw - 4, height - 4, PANEL, 2)
                            self:_box(sx + 3, sy + 3, cw - 6, 1, Color3.fromRGB(86,86,86), 3)
                            self:_box(sx + 9, sy, math.min(cw - 36, #section.Title * 8 + 8), 16, PANEL, 3)
                            self:_text(fit(section.Title, cw - 48, 13), sx + 13, sy, WHITE, 13, 4)
                            self:_text(section.Collapsed and "+" or "-", sx + cw - 20, sy + 4, DIM, 12, 4)
                            self:_hit(sx, sy, cw, 21, function() section.Collapsed = not section.Collapsed end)
                            local cy = sy + 23
                            if not section.Collapsed then
                                for _, c in ipairs(section.Controls) do
                                    c._column = col
                                    cy = self:_control(c, sx + 10, cy, cw - 20)
                                end
                            end
                            sy = sy + height + 12
                        end
                    end
                    self._clip = nil
                    if self._scrollMax[col] > 0 then
                        local track = bottom - top
                        local thumb = math.max(24, track * track / (track + self._scrollMax[col]))
                        self:_box(sx + cw + 2, top, 2, track, BORDER, 4)
                        self:_box(sx + cw + 2, top + (track - thumb) * self._scroll[col] / self._scrollMax[col], 2, thumb, DIM, 5)
                    end
                end
            end
        end
        self:_renderHUD()
        local panel = self._keybindPanel
        if panel and panel.Visible then
            local viewport = workspace.CurrentCamera.ViewportSize
            local px = viewport.X * panel.Position.X.Scale + panel.Position.X.Offset
            local py = viewport.Y * panel.Position.Y.Scale + panel.Position.Y.Offset
            local rows = {}
            if panel.IncludeWindowToggle then
                rows[#rows + 1] = {title = self.Title, key = self.ToggleKey}
            end
            if panel.IncludeControls then
                for _, binding in ipairs(self._bindings) do
                    rows[#rows + 1] = {title = binding.control.Title, key = binding.key}
                end
            end
            for _, entry in ipairs(self._keybindDisplays) do
                local okVisible, visible = true, true
                if entry.visible then okVisible, visible = pcall(entry.visible) end
                if okVisible and visible then
                    local okKey, key = pcall(entry.key)
                    local okActive, active = true, nil
                    if entry.active then okActive, active = pcall(entry.active) end
                    if okKey then
                        rows[#rows + 1] = {title = entry.title, key = key,
                            active = okActive and active or nil}
                    end
                end
            end
            self:_field(px, py, panel.Width, 30 + #rows * 19, false, 20)
            self:_box(px + 2, py + 2, panel.Width - 4, 1, DIM, 21)
            self:_text(panel.Title, px + 8, py + 5, WHITE, 12, 22)
            for index, row in ipairs(rows) do
                local keyName = row.key and row.key.Name or tostring(row.key or "None")
                local state = row.active == nil and "" or (row.active and " ACTIVE" or " OFF")
                self:_text("[" .. keyName .. "] " .. row.title .. state,
                    px + 8, py + 25 + (index - 1) * 19,
                    row.active == true and self.Accent or DIM, 11, 22)
            end
        end
        if self._notice and os.clock() < self._notice.untilTime then
            local viewport = workspace.CurrentCamera.ViewportSize
            local nx, ny = viewport.X - 300, viewport.Y - 86
            self:_field(nx, ny, 285, 65, false, 30)
            self:_box(nx + 2, ny + 2, 281, 1, DIM, 31)
            self:_text(self._notice.title, nx + 10, ny + 8, WHITE, 13, 32)
            self:_text(fit(self._notice.text, 265, 11), nx + 10, ny + 30, DIM, 11, 32)
        end
        if self._watermark then
            local config = self._watermark
            local viewport = workspace.CurrentCamera.ViewportSize
            local now = os.clock()
            self._fpsStart = self._fpsStart or now
            self._fpsFrames = (self._fpsFrames or 0) + 1
            if now - self._fpsStart >= 0.5 then
                self._fps = math.floor(self._fpsFrames / (now - self._fpsStart) + 0.5)
                self._fpsFrames, self._fpsStart = 0, now
                pcall(function() self._ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            end
            local text = (config.Format or "{player} | {fps} fps"):gsub("{player}", LocalPlayer and LocalPlayer.Name or "Player")
                :gsub("{game}", tostring(game.Name or "Roblox"))
                :gsub("{time}", os.date("%H:%M:%S"))
                :gsub("{fps}", tostring(self._fps or 60))
                :gsub("{ping}", tostring(self._ping or 0))
            local width = math.max(90, #text * 7 + 18)
            local bottom = config.Position == "BottomLeft" or config.Position == "BottomRight"
            local left = config.Position == "TopLeft" or config.Position == "BottomLeft"
            local wx, wy = left and 10 or viewport.X - width - 10, bottom and viewport.Y - 32 or 10
            self:_box(wx, wy, width, 22, BG, 20)
            self:_text(text, wx + 8, wy + 4, DIM, 11, 21)
        end
        if self._confirm then
            local viewport = workspace.CurrentCamera.ViewportSize
            local cx, cy = (viewport.X - 340) / 2, (viewport.Y - 135) / 2
            local config = self._confirm
            self._hits = {}
            self:_field(cx, cy, 340, 135, false, 40)
            self:_box(cx + 2, cy + 2, 336, 1, DIM, 41)
            self:_text(config.Title or "Confirm", cx + 12, cy + 12, WHITE, 14, 42)
            self:_text(config.Text or "", cx + 12, cy + 43, DIM, 12, 42)
            self:_field(cx + 12, cy + 95, 150, 27, self:_hover(cx + 12, cy + 95, 150, 27), 41)
            self:_field(cx + 178, cy + 95, 150, 27, self:_hover(cx + 178, cy + 95, 150, 27), 41)
            self:_text("Cancel", cx + 58, cy + 101, WHITE, 12, 42)
            self:_text("Confirm", cx + 222, cy + 101, WHITE, 12, 42)
            self:_hit(cx + 12, cy + 95, 150, 27, function()
                self._confirm = nil
                if config.OnCancel then pcall(config.OnCancel) end
            end)
            self:_hit(cx + 178, cy + 95, 150, 27, function()
                self._confirm = nil
                if config.OnConfirm then pcall(config.OnConfirm) end
            end)
        end
        for kind, kindPool in pairs(self._kindPools) do
            for i = (self._usedKinds[kind] or 0) + 1, #kindPool do
                self:_drawProperty(kindPool[i], "Visible", false)
            end
        end
        if self._bridge and os.clock() - (self._lastPublish or 0) >= 1/30 then
            local shapes = {}
            for index, object in ipairs(self._pool) do
                if object.Visible then
                    local shape = {kind=self._kinds[index],p={object.Position.X,object.Position.Y},
                        color=object.Color:ToHex(),z=object.ZIndex}
                    if shape.kind == "Square" then shape.s={object.Size.X,object.Size.Y}
                    elseif shape.kind == "Circle" then shape.radius=object.Radius; shape.thickness=object.Thickness
                    else shape.text=object.Text; shape.size=object.Size end
                    shapes[#shapes + 1] = shape
                end
            end
            self._frameJson = HttpService:JSONEncode({shapes=shapes})
            self._lastPublish = os.clock()
        end
    end

    -- HUD values are snapshots supplied by event listeners; no game tree scans here.
    function Backend:SetCrosshair(config) self._crosshair = config end
    function Backend:SetStatusHUD(config) self._statusHUD = config end

    function Backend:_renderHUD()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local cross = self._crosshair
        if cross and cross.Visible ~= false then
            local x, y = math.floor(viewport.X / 2 + (cross.OffsetX or 0)), math.floor(viewport.Y / 2 + (cross.OffsetY or 0))
            if cross.Preview and self._visible then
                x, y = self._position.X + self._width - 166, self._position.Y + self._height - 66
                self:_field(x-72,y-28,144,58,false,14)
                self:_text("Onizleme",x-30,y-23,DIM,11,15)
            end
            local size, gap = math.clamp(cross.Size or 7, 2, 24), math.clamp(cross.Gap or 4, 0, 20)
            local thick = math.clamp(cross.Thickness or 1, 1, 5)
            local color = cross.Color or WHITE
            local edge = Color3.fromRGB(1,1,1)
            local function bar(bx, by, bw, bh)
                if cross.Outline ~= false then self:_box(bx-1,by-1,bw+2,bh+2,edge,15) end
                self:_box(bx,by,bw,bh,color,16)
            end
            local style = cross.Style or "Cross"
            if style == "Circle" then
                local function circle(radius, thickness, ink, z)
                    local o = self:_primitive("Circle")
                    self:_drawProperty(o,"Position",Vector2.new(x,y))
                    self:_drawProperty(o,"Radius",radius)
                    self:_drawProperty(o,"Thickness",thickness)
                    self:_drawProperty(o,"Color",ink)
                    self:_drawProperty(o,"Filled",false)
                    self:_drawProperty(o,"NumSides",40)
                    self:_drawProperty(o,"Transparency",1)
                    self:_drawProperty(o,"ZIndex",z)
                end
                if cross.Outline ~= false then circle(size+gap,thick+2,edge,15) end
                circle(size+gap,thick,color,16)
            elseif style ~= "Dot" then
                local half = math.floor(thick/2)
                bar(x-gap-size,y-half,size,thick); bar(x+gap+1,y-half,size,thick)
                bar(x-half,y+gap+1,thick,size)
                if style ~= "T" then bar(x-half,y-gap-size,thick,size) end
            end
            if style == "Dot" or cross.Dot then
                local dotSize = style == "Dot" and math.min(size,8) or thick
                bar(x-math.floor(dotSize/2),y-math.floor(dotSize/2),dotSize,dotSize)
            end
        end
        local hud = self._statusHUD
        if hud and hud.Visible ~= false then
            local x, y = math.floor(viewport.X/2)-132, viewport.Y-104
            self:_field(x,y,264,70,false,17)
            self:_text(fit(hud.Weapon or "Silah yok",166,13),x+10,y+8,WHITE,13,18)
            local ammo = hud.Ammo ~= nil and tostring(hud.Ammo) or "--"
            self:_text(ammo,x+218,y+6,WHITE,17,18)
            local health = hud.Health ~= nil and tostring(math.ceil(hud.Health)) or "--"
            local armor = hud.Armor ~= nil and tostring(math.ceil(hud.Armor)) or "--"
            self:_text("HP "..health.."  |  ZIRH "..armor,x+10,y+32,DIM,12,18)
            local warnings = (hud.LowHealth and "DUSUK CAN  " or "") .. (hud.LowArmor and "DUSUK ZIRH" or "")
            self:_text(warnings,x+10,y+50,WHITE,11,18)
        end
    end

    function Backend:_control(c, x, y, width)
        local height = self:_controlHeight(c, width)
        if height == 0 then return y end
        local function click(hx, hy, hw, hh, callback)
            if c.Enabled ~= false then self:_hit(hx, hy, hw, hh, callback) end
        end
        local kind = c.Kind
        local ink = c.Enabled == false and DIM or WHITE
        if kind == "separator" then
            self:_box(x, y + 4, width, 1, Color3.fromRGB(6,6,6), 3)
            self:_box(x, y + 5, width, 1, BORDER, 3)
        elseif kind == "label" then
            for index, line in ipairs(self:_labelLines(c, width)) do
                self:_text(line, x, y + (index - 1) * 17, c.Color or DIM, 13, 4)
            end
        elseif kind == "toggle" then
            self:_field(x, y + 3, 14, 14, self:_hover(x, y, width, 22))
            if c.State then
                self:_box(x + 3, y + 6, 8, 8, self.Accent, 5)
                self:_box(x + 3, y + 6, 8, 1, WHITE, 5)
            end
            self:_text(fit(c.Title, width - 24, 13), x + 23, y + 2, c.State and ink or DIM, 13, 5)
            click(x, y, width, 22, function() c:Set(not c.State) end)
        elseif kind == "button" then
            self:_field(x, y, width, 22, self:_hover(x, y, width, 22))
            local title = fit(c.Title, width - 12, 13)
            self:_text(title, x + math.max(6, (width - #title * 7.8) / 2), y + 3, ink, 13, 5)
            click(x, y, width, 22, function() pcall(c.Callback) end)
        elseif kind == "slider" then
            local value = tostring(math.floor(c.Value * 100 + 0.5) / 100)
            self:_text(fit(c.Title, width - #value * 8 - 12, 13), x, y, ink, 13, 4)
            self:_text(value, x + width - #value * 8, y, DIM, 13, 4)
            self:_field(x, y + 19, width, 12, self:_hover(x, y + 17, width, 17))
            local ratio = (c.Value - c.Min) / math.max(0.0001, c.Max - c.Min)
            self:_box(x + 2, y + 21, (width - 4) * ratio, 8, DIM, 5)
            self:_box(x + 2, y + 21, (width - 4) * ratio, 1, WHITE, 5)
            click(x, y + 16, width, 18, function(mouse)
                self._slider = {control=c,min=c.Min,max=c.Max,x=x+2,width=width-4}
                c:Set(c.Min + math.clamp((mouse.X - x - 2) / (width - 4), 0, 1) * (c.Max - c.Min))
            end)
        elseif kind == "dropdown" or kind == "multi" then
            self:_text(fit(c.Title, width, 13), x, y, ink, 13, 4)
            self:_field(x, y + 18, width, 22, c.Opened or self:_hover(x, y + 18, width, 22))
            local selected = kind == "multi" and table.concat(c.Selected, ", ") or tostring(c.Selected or "Select")
            self:_text(fit(selected, width - 27, 13), x + 6, y + 21, ink, 13, 5)
            self:_text(c.Opened and "-" or "+", x + width - 16, y + 21, DIM, 13, 5)
            click(x, y + 18, width, 22, function()
                c.Opened = not c.Opened
                if c.Opened and c._column then
                    local overflow = y + self:_controlHeight(c, width) - (self._position.Y + self._height - 35)
                    if overflow > 0 then self._scroll[c._column] = self._scroll[c._column] + overflow end
                end
            end)
            if c.Opened then
                local count = math.min(c.MaxVisibleItems, #c.Options)
                c.OptionScroll = math.clamp(c.OptionScroll or 0, 0, math.max(0, #c.Options - count))
                local oy = y + 42
                local clip = self._clip
                local at, ab = math.max(oy, clip and clip[2] or oy), math.min(oy + count * 22, clip and clip[2] + clip[4] or oy + count * 22)
                if ab > at then self._dropdownAreas[#self._dropdownAreas + 1] = {x=x,y=at,width=width,height=ab-at,control=c} end
                for index = c.OptionScroll + 1, math.min(#c.Options, c.OptionScroll + count) do
                    local value = c.Options[index]
                    local rowY = oy + (index - c.OptionScroll - 1) * 22
                    local chosen = kind == "multi" and table.find(c.Selected, value) ~= nil or c.Selected == value
                    self:_box(x, rowY, width, 22, BORDER, 4)
                    self:_box(x + 1, rowY, width - 2, 22, self:_hover(x, rowY, width, 22) and Color3.fromRGB(39,39,39) or BG, 4)
                    if chosen then self:_box(x + 2, rowY + 4, 2, 14, self.Accent, 5) end
                    self:_text(fit(value, width - 18, 13), x + 8, rowY + 3, chosen and WHITE or DIM, 13, 5)
                    click(x, rowY, width, 22, function()
                        if kind == "multi" then
                            local values, found = {}, false
                            for _, chosenValue in ipairs(c.Selected) do
                                if chosenValue == value then found = true else values[#values + 1] = chosenValue end
                            end
                            if not found then values[#values + 1] = value end
                            c:Set(values)
                        else c:Set(value); c.Opened = false end
                    end)
                end
                if #c.Options > count then
                    local track = count * 22
                    self:_box(x + width - 3, oy + track * c.OptionScroll / #c.Options, 2, track * count / #c.Options, DIM, 6)
                end
            end
        elseif kind == "textbox" then
            local focused = self._capture and self._capture.control == c
            local value = focused and self._capture.value or c.Text
            self:_text(fit(c.Title, width, 13), x, y, ink, 13, 4)
            self:_field(x, y + 18, width, 22, focused or self:_hover(x, y + 18, width, 22))
            local shown = value == "" and c.Placeholder or value
            if focused then shown = value:sub(-math.floor((width - 24) / 8)) .. "|" end
            self:_text(fit(shown, width - 12, 13), x + 6, y + 21, focused and WHITE or DIM, 13, 5)
            click(x, y + 18, width, 22, function()
                self._listeningForKey = true
                self._capture = {kind="text",control=c,original=c.Text,value=c.Text}
            end)
        elseif kind == "keybind" then
            local key = c.Listening and "..." or (c.Key and c.Key.Name or "NONE")
            local kw = math.max(42, #key * 8 + 14)
            self:_text(fit(c.Title, width - kw - 8, 13), x, y + 3, ink, 13, 4)
            self:_field(x + width - kw, y, kw, 21, c.Listening or self:_hover(x + width - kw, y, kw, 21))
            self:_text(key, x + width - kw + 7, y + 3, DIM, 13, 5)
            click(x, y, width, 22, function()
                self._listeningForKey = true
                c.Listening = true
                self._capture = {kind="key",control=c}
            end)
        elseif kind == "color" then
            self:_text(fit(c.Title, width - 88, 13), x, y + 3, ink, 13, 4)
            self:_field(x + width - 24, y + 2, 24, 16, self:_hover(x, y, width, 22))
            self:_box(x + width - 22, y + 4, 20, 12, c.Color, 5)
            local value = self._capture and self._capture.color == c and self._capture.value or c.Color:ToHex()
            self:_text(value, x + width - 82, y + 3, DIM, 12, 5)
            click(x, y, width, 22, function() c:Toggle() end)
        end
        return y + height
    end

    function Backend:CreateTab(name)
        local tab = {Name = name, Sections = {}, _lib = self}
        function tab:SetBadge(value) self.Badge = value end
        function tab:ClearBadge() self.Badge = 0 end
        function tab:Activate() self._lib.ActiveTab = self end
        function tab:Deactivate() if self._lib.ActiveTab == self then self._lib.ActiveTab = nil end end
        function tab:CreateSection(title, column)
            local section = {Title = title, Column = column == "right" and 2 or 1, Controls = {}, _lib = self._lib}
            function section:Collapse() self.Collapsed = true end
            function section:Expand() self.Collapsed = false end
            self.Sections[#self.Sections + 1] = section
            local function add(kind, config)
                config = config or {}
                local c = {Kind = kind, Title = config.Title or kind, Callback = config.Callback or function() end,
                    Value = config.Default, State = config.Default == true,
                    Selected = config.Default or (config.Options and config.Options[1]) or "",
                    Text = tostring(config.Default or ""), Key = config.Default or Enum.KeyCode.None,
                    Min = config.Min or 0, Max = config.Max or 100,
                    MaxVisibleItems = math.clamp(math.floor(tonumber(config.MaxVisibleItems) or 6), 1, 20),
                    Options = config.Options or {}, Placeholder = config.Placeholder or ""}
                if kind == "slider" then c.Value = tonumber(config.Default) or c.Min end
                if kind == "multi" then c.Selected = config.Default or {} end
                if kind == "color" then c.Color = config.Default or Color3.fromRGB(255,255,255) end
                local initial = kind == "toggle" and c.State or kind == "dropdown" and c.Selected
                    or kind == "multi" and c.Selected or kind == "textbox" and c.Text
                    or kind == "keybind" and c.Key or kind == "color" and c.Color or c.Value
                function c:Set(value)
                    if self.Kind == "toggle" then self.State = not not value
                    elseif self.Kind == "dropdown" then self.Selected = value
                    elseif self.Kind == "textbox" then self.Text = tostring(value)
                    elseif self.Kind == "keybind" then self.Key = value
                    elseif self.Kind == "multi" then self.Selected = value or {}
                    elseif self.Kind == "color" then self.Color = value
                    elseif self.Kind == "slider" then
                        local decimals = math.clamp(tonumber(config.Decimals) or 0, 0, 6)
                        local factor = 10 ^ decimals
                        self.Value = math.floor(math.clamp(tonumber(value) or self.Min, self.Min, self.Max) * factor + 0.5) / factor
                        value = self.Value
                    else self.Value = value end
                    pcall(self.Callback, value)
                    section._lib:RefreshConditions()
                end
                function c:Reset() self:Set(initial) end
                function c:GetSelected()
                    local values = {}
                    for index,value in ipairs(self.Selected) do values[index] = value end
                    return values
                end
                function c:Refresh(options)
                    self.Options = options or {}
                    self.OptionScroll = 0
                end
                function c:Open() self.Opened = true end
                function c:Close() self.Opened = false end
                section.Controls[#section.Controls + 1] = c
                if config.ConfigKey then
                    section._lib._configElements = section._lib._configElements or {}
                    assert(not section._lib._configElements[config.ConfigKey], "Duplicate ConfigKey: " .. config.ConfigKey)
                    section._lib._configElements[config.ConfigKey] = {
                        get = function()
                            if kind == "toggle" then return c.State end
                            if kind == "dropdown" then return c.Selected end
                            if kind == "textbox" then return HttpService:JSONEncode(c.Text) end
                            if kind == "keybind" then return c.Key.Name end
                            if kind == "multi" then return HttpService:JSONEncode(c.Selected) end
                            if kind == "color" then return c.Color:ToHex() end
                            return c.Value
                        end,
                        set = function(value)
                            if kind == "toggle" then value = value == true or value == "true"
                            elseif kind == "slider" then value = tonumber(value)
                            elseif kind == "textbox" then value = HttpService:JSONDecode(value)
                            elseif kind == "keybind" then value = Enum.KeyCode[value] end
                            if kind == "multi" then value = HttpService:JSONDecode(value) end
                            if kind == "color" then value = Color3.fromHex(value) end
                            c:Set(value)
                        end,
                    }
                end
                section._lib._resetControls = section._lib._resetControls or {}
                table.insert(section._lib._resetControls, c)
                if config.VisibleWhen then section._lib:SetCondition(c, config.VisibleWhen, "hide") end
                if config.EnabledWhen then section._lib:SetCondition(c, config.EnabledWhen, "disable") end
                return c
            end
            function section:CreateToggle(config)
                local c = add("toggle", config)
                if config and config.Keybind then
                    self._lib._bindings[#self._lib._bindings + 1] = {
                        control=c, key=config.Keybind, callback=function() c:Set(not c.State) end}
                end
                return c
            end
            function section:CreateButton(config) return add("button", config) end
            function section:CreateSlider(config) return add("slider", config) end
            function section:CreateDropdown(config) return add("dropdown", config) end
            function section:CreateMultiDropdown(config) return add("multi", config) end
            function section:CreateColorPicker(config)
                local c = add("color", config)
                function c:Toggle()
                    local hub = section._lib
                    if self.Opened then
                        self.Opened = false
                        hub._capture = nil
                        hub._releaseListening = true
                        return
                    end
                    self.Opened = true
                    local proxy = {Set = function(_, value)
                        local ok, color = pcall(Color3.fromHex, value)
                        if ok then c:Set(color) end
                        c.Opened = false
                    end}
                    local value = self.Color:ToHex()
                    hub._listeningForKey = true
                    hub._capture = {kind="text", color=self, control=proxy, original=value, value=value}
                end
                return c
            end
            function section:CreateTextbox(config) return add("textbox", config) end
            function section:CreateKeybind(config)
                local c = add("keybind", config)
                self._lib._bindings[#self._lib._bindings + 1] = {control = c, key = c.Key,
                    callback = nil}
                local original = c.Set
                function c:Set(value)
                    original(self, value)
                    for _, b in ipairs(section._lib._bindings) do
                        if b.control == self then b.key = value end
                    end
                end
                return c
            end
            function section:CreateLabel(value, color)
                local c = add("label", {Title = value})
                c.Text, c.Color = value, color
                function c:Set(text) self.Text = tostring(text) end
                return c
            end
            function section:CreateSeparator() return add("separator", {}) end
            return section
        end
        self.Tabs[#self.Tabs + 1] = tab
        if not self.ActiveTab then self.ActiveTab = tab end
        return tab
    end

    function Backend:SetAccent(color) self.Accent = color end
    function Backend:SetWatermark(config) self._watermark = config or {} end
    function Backend:UpdateWatermark(format)
        if self._watermark then self._watermark.Format = format end
    end
    function Backend:RemoveWatermark() self._watermark = nil end
    function Backend:SetCondition(control, test, mode)
        self._conditions = self._conditions or {}
        table.insert(self._conditions, {control = control, test = test, mode = mode or "hide"})
        self:RefreshConditions()
    end
    function Backend:RefreshConditions()
        for _, condition in ipairs(self._conditions or {}) do
            local ok, value = pcall(condition.test)
            condition.control[condition.mode == "hide" and "Visible" or "Enabled"] = ok and not not value
        end
    end
    Backend.ResetValues = Library.ResetValues
    Backend.SaveConfig = Library.SaveConfig
    Backend.LoadConfig = Library.LoadConfig
    Backend.ListProfiles = Library.ListProfiles
    Backend.SaveProfile = Library.SaveProfile
    Backend.LoadProfile = Library.LoadProfile
    Backend.RenameProfile = Library.RenameProfile
    Backend.DeleteProfile = Library.DeleteProfile
    Backend.SetDefaultProfile = Library.SetDefaultProfile
    Backend.LoadDefaultProfile = Library.LoadDefaultProfile
    function Backend:SetTitle(title, version)
        self.Title = title or self.Title
        self.Version = version or self.Version
    end
    function Backend:RegisterKeybindDisplay(config)
        local entry = {title = config.Title, key = config.Key, active = config.Active, visible = config.Visible}
        self._keybindDisplays[#self._keybindDisplays + 1] = entry
        return {Remove = function()
            for index, value in ipairs(self._keybindDisplays) do
                if value == entry then table.remove(self._keybindDisplays, index); break end
            end
        end}
    end
    function Backend:CreateKeybindList(config)
        config = config or {}
        local panel = {Visible = config.Visible ~= false, Title = config.Title or "KEYBINDS",
            Position = config.Position or UDim2.fromOffset(12, 180), Width = config.Width or 210,
            IncludeControls = config.IncludeControls ~= false,
            IncludeWindowToggle = config.IncludeWindowToggle ~= false}
        self._keybindPanel = panel
        return {
            SetVisible = function(_, visible) panel.Visible = not not visible end,
            Destroy = function() if self._keybindPanel == panel then self._keybindPanel = nil end end,
        }
    end
    function Backend:Confirm(config)
        config = config or {}
        self._confirm = config
        return {Cancel = function() if self._confirm == config then self._confirm = nil end end}
    end
    function Backend:Notify(config)
        config = config or {}
        self._notice = {title = tostring(config.Title or self.Title),
            text = tostring(config.Text or ""), untilTime = os.clock() + (config.Duration or 4)}
    end
    function Backend:Destroy()
        self._destroyed = true
        if self._bridge then
            task.spawn(function()
                pcall(self._request, {Url=self._bridge.url.."/frame",Method="DELETE",
                    Headers={Authorization="Bearer "..self._bridge.token}})
            end)
        end
        for _, connection in ipairs(self._connections) do connection:Disconnect() end
        for _, object in ipairs(self._pool) do object:Remove() end
        table.clear(self._pool)
        table.clear(self._kinds)
        table.clear(self._kindPools)
        table.clear(self._usedKinds)
        table.clear(self._drawState)
        table.clear(self._hits)
        self._capture = nil
        self._visible = false
    end
    return Backend
end)()

local advancedNew = Library.new
function Library.new(config)
    config = config or {}
    if config.Streamproof or config.Renderer == "Drawing" then
        return DrawingBackend.new(config)
    end
    local hub = advancedNew(config)
    hub._extraConnections = {}
    if config.MobileToggle == true or (config.MobileToggle ~= false and UserInputService.TouchEnabled) then
        local button=Instance.new("TextButton",hub.ScreenGui)
        button.Name="MobileToggle"; button.Text="HH"; button.Size=UDim2.fromOffset(48,48)
        button.Position=UDim2.new(0,12,0.5,-24); button.BackgroundColor3=hub.Accent
        button.TextColor3=T.Black; button.Font=Enum.Font.Code; button.TextSize=18; button.ZIndex=150
        hub:_onAccent(function(color) button.BackgroundColor3=color end)
        local origin, position, pointer, moved
        button.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                origin=input.Position; position=button.AbsolutePosition; pointer=input; moved=false
            end
        end)
        table.insert(hub._extraConnections,UserInputService.InputChanged:Connect(function(input)
            if pointer and (input==pointer or input.UserInputType==Enum.UserInputType.MouseMovement) then
                local delta=input.Position-origin
                if delta.Magnitude>6 then moved=true end
                local viewport=workspace.CurrentCamera.ViewportSize
                button.Position=UDim2.fromOffset(math.clamp(position.X+delta.X,0,math.max(0,viewport.X-48)),math.clamp(position.Y+delta.Y,0,math.max(0,viewport.Y-48)))
            end
        end))
        table.insert(hub._extraConnections,UserInputService.InputEnded:Connect(function(input)
            if input==pointer then pointer=nil end
        end))
        button.Activated:Connect(function()
            if not moved then hub.MainFrame.Visible=not hub.MainFrame.Visible end
        end)
    end
    return hub
end

local advancedDestroy=Library.Destroy
function Library:Destroy()
    for _, connection in ipairs(self._extraConnections or {}) do connection:Disconnect() end
    if self._keybindListConnection then self._keybindListConnection:Disconnect() end
    self._conditions={}; self._resetControls={}; self._controlRows={}; self._bindings={}
    self._keybindDisplays={}; self._keybindListConnection=nil; self._keybindListFrame=nil
    advancedDestroy(self)
end

return Library
