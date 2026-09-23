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

local advancedNew = Library.new
function Library.new(config)
    config = config or {}
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
    self._conditions={}; self._resetControls={}; self._controlRows={}; self._bindings={}
    advancedDestroy(self)
end

return Library
