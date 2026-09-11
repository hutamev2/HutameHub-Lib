--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    HUTAME HUB LIBRARY                        ║
    ║         Private Hub Style · Two-Column · Compact             ║
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
    BG          = Color3.fromRGB(13, 13, 13),    -- #0D0D0D  window bg
    Surface     = Color3.fromRGB(18, 18, 18),    -- #121212  topbar / tab bar
    Card        = Color3.fromRGB(22, 22, 22),    -- #161616  section card
    Element     = Color3.fromRGB(28, 28, 28),    -- #1C1C1C  element bg
    ElementHov  = Color3.fromRGB(34, 34, 34),    -- #222222  hover
    Border      = Color3.fromRGB(38, 38, 38),    -- #262626
    BorderLight = Color3.fromRGB(52, 52, 52),    -- #343434  active tab underline
    Text        = Color3.fromRGB(220, 220, 220), -- primary text
    TextDim     = Color3.fromRGB(130, 130, 130), -- secondary text
    TextMute    = Color3.fromRGB(70, 70, 70),    -- muted
    Accent      = Color3.fromRGB(220, 50, 50),   -- red accent (changeable)
    AccentDim   = Color3.fromRGB(140, 30, 30),   -- darker accent
    White       = Color3.new(1,1,1),
    Black       = Color3.new(0,0,0),
}

-- ─────────────────────────────────────────────
-- Library
-- ─────────────────────────────────────────────
local Library = {}
Library.__index = Library

function Library.new(config)
    config = config or {}
    local self = setmetatable({}, Library)

    self.Title       = config.Title    or "HutameHub"
    self.Version     = config.Version  or "v1.0"
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

    -- ── Main Frame ──────────────────────────────
    local mf = Instance.new("Frame")
    mf.Name              = "MainFrame"
    mf.Size              = UDim2.fromOffset(700, 460)
    mf.Position          = UDim2.new(0.5,-350, 0.5,-230)
    mf.BackgroundColor3  = T.BG
    mf.BorderSizePixel   = 0
    mf.ClipsDescendants  = false
    mf.Parent            = sg
    Instance.new("UICorner", mf).CornerRadius = UDim.new(0,6)
    local mfStroke = Instance.new("UIStroke", mf)
    mfStroke.Color     = T.Border
    mfStroke.Thickness = 1
    self.MainFrame = mf

    -- ── Top accent line ──────────────────────────
    local acLine = Instance.new("Frame", mf)
    acLine.Name             = "AccentLine"
    acLine.Size             = UDim2.new(1,0,0,2)
    acLine.BackgroundColor3 = self.Accent
    acLine.BorderSizePixel  = 0
    acLine.ZIndex           = 4
    Instance.new("UICorner", acLine).CornerRadius = UDim.new(0,6)
    self:_onAccent(function(c) acLine.BackgroundColor3 = c end)

    -- ── Topbar ──────────────────────────────────
    local topbar = Instance.new("Frame", mf)
    topbar.Name            = "Topbar"
    topbar.Size            = UDim2.new(1,0,0,36)
    topbar.Position        = UDim2.fromOffset(0,2)
    topbar.BackgroundColor3= T.Surface
    topbar.BorderSizePixel = 0
    topbar.ZIndex          = 3

    -- brand
    local brand = Instance.new("TextLabel", topbar)
    brand.Size               = UDim2.new(0,200,1,0)
    brand.Position           = UDim2.fromOffset(10,0)
    brand.BackgroundTransparency = 1
    brand.Font               = Enum.Font.GothamBold
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

    -- user info (right side)
    local userLbl = Instance.new("TextLabel", topbar)
    userLbl.Size                 = UDim2.new(0,200,1,0)
    userLbl.Position             = UDim2.new(1,-210,0,0)
    userLbl.BackgroundTransparency = 1
    userLbl.Font                 = Enum.Font.Gotham
    userLbl.TextSize             = 11
    userLbl.TextColor3           = T.TextDim
    userLbl.TextXAlignment       = Enum.TextXAlignment.Right
    userLbl.Text                 = LocalPlayer.Name

    -- close & minimize
    local function mkCtrl(char, xOff, hoverCol, onClick)
        local btn = Instance.new("TextButton", topbar)
        btn.Size               = UDim2.fromOffset(24,24)
        btn.Position           = UDim2.new(1,xOff, 0.5,-12)
        btn.BackgroundColor3   = T.Element
        btn.BorderSizePixel    = 0
        btn.Font               = Enum.Font.GothamBold
        btn.TextSize           = 12
        btn.TextColor3         = T.TextDim
        btn.Text               = char
        btn.AutoButtonColor    = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        btn.MouseEnter:Connect(function() tw(btn,0.15,{BackgroundColor3=hoverCol, TextColor3=T.White}) end)
        btn.MouseLeave:Connect(function() tw(btn,0.15,{BackgroundColor3=T.Element, TextColor3=T.TextDim}) end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end
    mkCtrl("✕", -8,  Color3.fromRGB(200,40,40),  function() self:Destroy() end)
    mkCtrl("—", -36, T.ElementHov, function()
        local body = self._body
        if body then
            body.Visible = not body.Visible
        end
    end)

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
    tabBar.Size            = UDim2.new(1,0,0,30)
    tabBar.Position        = UDim2.fromOffset(0,38)
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
    tabLayout.Padding          = UDim.new(0,0)
    self.TabBar  = tabBar
    self.TabList = tabList

    -- ── Body (content area below tabbar) ─────────
    local body = Instance.new("Frame", mf)
    body.Name            = "Body"
    body.Size            = UDim2.new(1,0,1,-68)
    body.Position        = UDim2.fromOffset(0,68)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true
    self._body = body

    -- toggle key
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == self.ToggleKey then
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
    btn.Size               = UDim2.new(0,0,1,0)   -- auto width
    btn.AutomaticSize      = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel    = 0
    btn.Font               = Enum.Font.GothamMedium
    btn.TextSize           = 12
    btn.TextColor3         = T.TextDim
    btn.Text               = "  "..name.."  "
    btn.AutoButtonColor    = false

    -- active underline
    local uline = Instance.new("Frame", btn)
    uline.Name             = "Underline"
    uline.Size             = UDim2.new(1,0,0,2)
    uline.Position         = UDim2.new(0,0,1,-2)
    uline.BackgroundColor3 = self.Accent
    uline.BackgroundTransparency = 1
    uline.BorderSizePixel  = 0
    self:_onAccent(function(c) if Tab.Active then uline.BackgroundColor3 = c end end)

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
    div.Size             = UDim2.new(0,1,1,0)
    div.Position         = UDim2.new(0.5,0,0,0)
    div.BackgroundColor3 = T.Border
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

    Tab._page      = page
    Tab._left      = leftScroll
    Tab._right     = rightScroll
    Tab._btn       = btn
    Tab._uline     = uline

    function Tab:Activate()
        for _, t in ipairs(self._lib.Tabs) do t:Deactivate() end
        Tab.Active     = true
        page.Visible   = true
        tw(btn,   0.15, {TextColor3 = T.White})
        tw(uline, 0.15, {BackgroundTransparency = 0, BackgroundColor3 = self._lib.Accent})
        self._lib.ActiveTab = Tab
    end

    function Tab:Deactivate()
        Tab.Active   = false
        page.Visible = false
        tw(btn,   0.15, {TextColor3 = T.TextDim})
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
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,4)
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
    layout.Padding   = UDim.new(0,3)

    -- section header
    local hdr = Instance.new("TextLabel", card)
    hdr.Size                  = UDim2.new(1,0,0,16)
    hdr.BackgroundTransparency= 1
    hdr.Font                  = Enum.Font.GothamBold
    hdr.TextSize               = 10
    hdr.TextColor3             = T.TextMute
    hdr.TextXAlignment         = Enum.TextXAlignment.Left
    hdr.Text                   = string.upper(title)
    hdr.LayoutOrder            = 0

    -- separator under header
    local sep = Instance.new("Frame", card)
    sep.Size             = UDim2.new(1,0,0,1)
    sep.BackgroundColor3 = T.Border
    sep.BorderSizePixel  = 0
    sep.LayoutOrder      = 1

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
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,3)
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color     = state and self._lib.Accent or T.BorderLight
        boxStroke.Thickness = 1

        -- checkmark tick
        local tick = Instance.new("TextLabel", box)
        tick.Size                  = UDim2.new(1,0,1,0)
        tick.BackgroundTransparency= 1
        tick.Font                  = Enum.Font.GothamBold
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
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = state and T.Text or T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        -- value label right (optional, e.g. "None")
        local valLbl = Instance.new("TextLabel", row)
        valLbl.Size                  = UDim2.new(0,50,1,0)
        valLbl.Position              = UDim2.new(1,-50,0,0)
        valLbl.BackgroundTransparency= 1
        valLbl.Font                  = Enum.Font.Gotham
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
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local valLbl = Instance.new("TextLabel", headerRow)
        valLbl.Size                  = UDim2.new(0,60,1,0)
        valLbl.Position              = UDim2.new(1,-60,0,0)
        valLbl.BackgroundTransparency= 1
        valLbl.Font                  = Enum.Font.GothamBold
        valLbl.TextSize              = 11
        valLbl.TextColor3            = T.Text
        valLbl.TextXAlignment        = Enum.TextXAlignment.Right
        valLbl.Text                  = string.format("%."..decs.."f/%d%s", default, max, suffix)

        -- track
        local trackHolder = Instance.new("TextButton", container)
        trackHolder.Size             = UDim2.new(1,0,0,6)
        trackHolder.Position         = UDim2.fromOffset(0,18)
        trackHolder.BackgroundColor3 = T.Element
        trackHolder.BorderSizePixel  = 0
        trackHolder.Text             = ""
        trackHolder.AutoButtonColor  = false
        Instance.new("UICorner", trackHolder).CornerRadius = UDim.new(1,0)

        local fill = Instance.new("Frame", trackHolder)
        fill.Size             = UDim2.new((default-min)/(max-min),0,1,0)
        fill.BackgroundColor3 = self._lib.Accent
        fill.BorderSizePixel  = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

        local knob = Instance.new("Frame", fill)
        knob.Size             = UDim2.fromOffset(8,8)
        knob.Position         = UDim2.new(1,-4,0.5,-4)
        knob.BackgroundColor3 = T.White
        knob.BorderSizePixel  = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

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
        Instance.new("UICorner", header).CornerRadius = UDim.new(0,3)
        local hStroke = Instance.new("UIStroke", header)
        hStroke.Color     = T.Border
        hStroke.Thickness = 1

        local hLbl = Instance.new("TextLabel", header)
        hLbl.Size                  = UDim2.new(0.55,0,1,0)
        hLbl.Position              = UDim2.fromOffset(7,0)
        hLbl.BackgroundTransparency= 1
        hLbl.Font                  = Enum.Font.Gotham
        hLbl.TextSize              = 11
        hLbl.TextColor3            = T.TextDim
        hLbl.TextXAlignment        = Enum.TextXAlignment.Left
        hLbl.Text                  = ttl

        local valLbl = Instance.new("TextLabel", header)
        valLbl.Size                  = UDim2.new(0.4,-20,1,0)
        valLbl.Position              = UDim2.new(0.55,0,0,0)
        valLbl.BackgroundTransparency= 1
        valLbl.Font                  = Enum.Font.GothamMedium
        valLbl.TextSize              = 11
        valLbl.TextColor3            = T.Text
        valLbl.TextXAlignment        = Enum.TextXAlignment.Right
        valLbl.Text                  = tostring(sel)

        local arrow = Instance.new("TextLabel", header)
        arrow.Size                  = UDim2.fromOffset(14,22)
        arrow.Position              = UDim2.new(1,-16,0,0)
        arrow.BackgroundTransparency= 1
        arrow.Font                  = Enum.Font.GothamBold
        arrow.TextSize              = 8
        arrow.TextColor3            = T.TextMute
        arrow.Text                  = "▼"

        -- dropdown list panel (floats above other content)
        local listFrame = Instance.new("Frame", container)
        listFrame.Name             = "List"
        listFrame.Size             = UDim2.new(1,0,0,0)
        listFrame.Position         = UDim2.fromOffset(0,24)
        listFrame.BackgroundColor3 = T.Element
        listFrame.BorderSizePixel  = 0
        listFrame.ClipsDescendants = true
        listFrame.ZIndex           = 10
        listFrame.Visible          = false
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0,3)
        local lStroke = Instance.new("UIStroke", listFrame)
        lStroke.Color     = T.BorderLight
        lStroke.Thickness = 1
        lStroke.ZIndex    = 10
        local listLayout = Instance.new("UIListLayout", listFrame)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding   = UDim.new(0,1)
        local listPad = Instance.new("UIPadding", listFrame)
        listPad.PaddingTop    = UDim.new(0,3)
        listPad.PaddingBottom = UDim.new(0,3)

        local function buildList()
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(Dropdown.Options) do
                local ob = Instance.new("TextButton", listFrame)
                ob.Size              = UDim2.new(1,0,0,20)
                ob.BackgroundColor3  = opt==Dropdown.Selected and self._lib.Accent or T.Element
                ob.BackgroundTransparency = opt==Dropdown.Selected and 0.3 or 0.95
                ob.BorderSizePixel   = 0
                ob.Font              = Enum.Font.Gotham
                ob.TextSize          = 11
                ob.TextColor3        = opt==Dropdown.Selected and T.White or T.TextDim
                ob.TextXAlignment    = Enum.TextXAlignment.Left
                ob.Text              = "  "..tostring(opt)
                ob.AutoButtonColor   = false
                ob.ZIndex            = 11
                local oc = Instance.new("UICorner", ob)
                oc.CornerRadius = UDim.new(0,2)
                ob.MouseEnter:Connect(function() if opt~=Dropdown.Selected then tw(ob,0.1,{BackgroundTransparency=0.7, TextColor3=T.Text}) end end)
                ob.MouseLeave:Connect(function() if opt~=Dropdown.Selected then tw(ob,0.1,{BackgroundTransparency=0.95, TextColor3=T.TextDim}) end end)
                ob.MouseButton1Click:Connect(function()
                    Dropdown:Set(opt)
                    Dropdown:Close()
                end)
            end
            listFrame.Size = UDim2.new(1,0,0, listLayout.AbsoluteContentSize.Y + 6)
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
            task.delay(0.15, function() if not Dropdown.Opened then listFrame.Visible=false end end)
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
        local Tb    = {Text = def}

        local row = Instance.new("Frame", card)
        row.Name              = "TB_"..ttl
        row.Size              = UDim2.new(1,0,0,22)
        row.BackgroundTransparency = 1
        row.LayoutOrder       = nextOrder()

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(0.42,0,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local inputFrame = Instance.new("Frame", row)
        inputFrame.Size            = UDim2.new(0.58,-2,1,-2)
        inputFrame.Position        = UDim2.new(0.42,2,0,1)
        inputFrame.BackgroundColor3= T.Element
        inputFrame.BorderSizePixel = 0
        Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0,3)
        local ifStroke = Instance.new("UIStroke", inputFrame)
        ifStroke.Color     = T.Border
        ifStroke.Thickness = 1

        local input = Instance.new("TextBox", inputFrame)
        input.Size                 = UDim2.new(1,-8,1,0)
        input.Position             = UDim2.fromOffset(4,0)
        input.BackgroundTransparency= 1
        input.Font                 = Enum.Font.Gotham
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

        return Tb
    end

    -- ── Keybind ──────────────────────────────────
    function Section:CreateKeybind(config)
        local ttl   = config.Title    or "Keybind"
        local defK  = config.Default  or Enum.KeyCode.None
        local cb    = config.Callback or function() end
        local Kb    = {Key=defK, Listening=false}

        local row = Instance.new("Frame", card)
        row.Name              = "KB_"..ttl
        row.Size              = UDim2.new(1,0,0,22)
        row.BackgroundTransparency = 1
        row.LayoutOrder       = nextOrder()

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(1,-80,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local kBtn = Instance.new("TextButton", row)
        kBtn.Size              = UDim2.fromOffset(72,18)
        kBtn.Position          = UDim2.new(1,-72,0.5,-9)
        kBtn.BackgroundColor3  = T.Element
        kBtn.BorderSizePixel   = 0
        kBtn.Font              = Enum.Font.GothamBold
        kBtn.TextSize          = 10
        kBtn.TextColor3        = T.TextDim
        kBtn.Text              = "["..defK.Name.."]"
        kBtn.AutoButtonColor   = false
        Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0,3)
        local kbStroke = Instance.new("UIStroke", kBtn)
        kbStroke.Color     = T.Border
        kbStroke.Thickness = 1

        kBtn.MouseButton1Click:Connect(function()
            if Kb.Listening then return end
            Kb.Listening = true
            kBtn.Text    = "[...]"
            tw(kbStroke,0.15,{Color=self._lib.Accent})
            local conn
            conn = UserInputService.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Keyboard then
                    local k = i.KeyCode==Enum.KeyCode.Backspace and Enum.KeyCode.None or i.KeyCode
                    Kb.Key        = k
                    kBtn.Text     = "["..k.Name.."]"
                    Kb.Listening  = false
                    tw(kbStroke,0.15,{Color=T.Border})
                    conn:Disconnect()
                    pcall(cb, k)
                end
            end)
        end)

        function Kb:Set(k) Kb.Key=k; kBtn.Text="["..k.Name.."]" end

        return Kb
    end

    -- ── ColorPicker (compact swatch row) ─────────
    function Section:CreateColorPicker(config)
        local ttl   = config.Title    or "Color"
        local defC  = config.Default  or Color3.fromRGB(255,255,255)
        local cb    = config.Callback or function() end
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
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local preview = Instance.new("Frame", header)
        preview.Size             = UDim2.fromOffset(24,14)
        preview.Position         = UDim2.new(1,-26,0.5,-7)
        preview.BackgroundColor3 = defC
        preview.BorderSizePixel  = 0
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0,3)
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
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0,3)
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
            chLbl.Font                  = Enum.Font.GothamBold
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
            numLbl.Font                  = Enum.Font.Gotham
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

        return CP
    end

    -- ── Button ───────────────────────────────────
    function Section:CreateButton(config)
        local ttl   = config.Title    or "Button"
        local cb    = config.Callback or function() end
        local desc  = config.Desc     or ""

        local btn = Instance.new("TextButton", card)
        btn.Name              = "Btn_"..ttl
        btn.Size              = UDim2.new(1,0,0,22)
        btn.BackgroundColor3  = T.Element
        btn.BorderSizePixel   = 0
        btn.Font              = Enum.Font.GothamMedium
        btn.TextSize          = 12
        btn.TextColor3        = T.Text
        btn.Text              = ttl
        btn.AutoButtonColor   = false
        btn.ClipsDescendants  = true
        btn.LayoutOrder       = nextOrder()
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,3)
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

        return btn
    end

    -- ── Label (static text) ───────────────────────
    function Section:CreateLabel(text, col)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size                  = UDim2.new(1,0,0,16)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Gotham
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
-- Window-level helpers
-- ─────────────────────────────────────────────
function Library:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

function Library:SetTitle(title, version)
    self.Title   = title   or self.Title
    self.Version = version or self.Version
end

return Library
