--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    HUTAME  LIBRARY  v3.0                         ║
    ║          Modern · Clean · Instance-based · TweenService          ║
    ║                                                                  ║
    ║  Bileşenler: Window, Tab, Section, Toggle, Slider, Dropdown,     ║
    ║  MultiDropdown, Textbox, Keybind, ColorPicker (HSV), Button,     ║
    ║  Label, Separator, Notification, Watermark, Config Save/Load     ║
    ║                                                                  ║
    ║  Kullanım:                                                       ║
    ║    loadstring(game:HttpGet(                                      ║
    ║      "https://raw.githubusercontent.com/hutamev2/                ║
    ║       HutameHub-Lib/main/Source.lua"))()                         ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════════════
-- § 1  SERVICES & LOCALS
-- ══════════════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local floor, clamp = math.floor, math.clamp
local c3rgb, c3hsv = Color3.fromRGB, Color3.fromHSV

-- ══════════════════════════════════════════════════════════════════════
-- § 2  THEME PRESETS
-- ══════════════════════════════════════════════════════════════════════
local Presets = {}

Presets.Midnight = {
    BG          = c3rgb(14,  12,  26),
    Surface     = c3rgb(20,  17,  36),
    Card        = c3rgb(26,  22,  45),
    Element     = c3rgb(36,  30,  58),
    ElementHov  = c3rgb(50,  41,  78),
    Border      = c3rgb(58,  48,  84),
    BorderLight = c3rgb(95,  78, 130),
    Text        = c3rgb(230, 222, 252),
    TextDim     = c3rgb(178, 166, 208),
    TextMute    = c3rgb(130, 118, 162),
    Accent      = c3rgb(138,  82, 226),
    AccentDim   = c3rgb( 83,  49, 136),
    White       = c3rgb(248, 242, 255),
    Black       = c3rgb(  8,   6,  18),
}

Presets.Ocean = {
    BG          = c3rgb( 10,  18,  30),
    Surface     = c3rgb( 14,  24,  42),
    Card        = c3rgb( 18,  30,  52),
    Element     = c3rgb( 26,  44,  72),
    ElementHov  = c3rgb( 36,  58,  92),
    Border      = c3rgb( 44,  70, 100),
    BorderLight = c3rgb( 72, 112, 160),
    Text        = c3rgb(212, 228, 248),
    TextDim     = c3rgb(160, 184, 214),
    TextMute    = c3rgb(110, 138, 172),
    Accent      = c3rgb( 56, 160, 230),
    AccentDim   = c3rgb( 34,  96, 138),
    White       = c3rgb(236, 246, 255),
    Black       = c3rgb(  6,  12,  22),
}

Presets.Crimson = {
    BG          = c3rgb( 22,  10,  12),
    Surface     = c3rgb( 32,  14,  16),
    Card        = c3rgb( 40,  18,  20),
    Element     = c3rgb( 56,  26,  28),
    ElementHov  = c3rgb( 72,  36,  38),
    Border      = c3rgb( 88,  46,  48),
    BorderLight = c3rgb(140,  70,  74),
    Text        = c3rgb(252, 220, 222),
    TextDim     = c3rgb(210, 168, 170),
    TextMute    = c3rgb(160, 118, 120),
    Accent      = c3rgb(220,  44,  56),
    AccentDim   = c3rgb(132,  26,  34),
    White       = c3rgb(255, 240, 240),
    Black       = c3rgb( 16,   6,   6),
}

Presets.Emerald = {
    BG          = c3rgb( 10,  22,  16),
    Surface     = c3rgb( 14,  30,  22),
    Card        = c3rgb( 18,  38,  28),
    Element     = c3rgb( 26,  54,  38),
    ElementHov  = c3rgb( 36,  70,  50),
    Border      = c3rgb( 46,  86,  62),
    BorderLight = c3rgb( 74, 136,  96),
    Text        = c3rgb(210, 248, 228),
    TextDim     = c3rgb(158, 206, 178),
    TextMute    = c3rgb(108, 158, 130),
    Accent      = c3rgb( 48, 200, 120),
    AccentDim   = c3rgb( 28, 120,  72),
    White       = c3rgb(236, 255, 244),
    Black       = c3rgb(  6,  16,  10),
}

Presets.Sakura = {
    BG          = c3rgb( 26,  12,  22),
    Surface     = c3rgb( 36,  16,  30),
    Card        = c3rgb( 46,  20,  38),
    Element     = c3rgb( 62,  28,  52),
    ElementHov  = c3rgb( 80,  38,  68),
    Border      = c3rgb( 96,  50,  82),
    BorderLight = c3rgb(152,  84, 130),
    Text        = c3rgb(252, 220, 244),
    TextDim     = c3rgb(210, 170, 200),
    TextMute    = c3rgb(160, 120, 150),
    Accent      = c3rgb(230,  88, 170),
    AccentDim   = c3rgb(138,  52, 102),
    White       = c3rgb(255, 240, 252),
    Black       = c3rgb( 18,   8,  16),
}

-- ══════════════════════════════════════════════════════════════════════
-- § 3  UTILITY
-- ══════════════════════════════════════════════════════════════════════
local function safeParent()
    local ok, cg = pcall(function() return CoreGui end)
    if ok and cg then
        local ok2 = pcall(function()
            local s = Instance.new("ScreenGui")
            s.Parent = cg
            s:Destroy()
        end)
        if ok2 then return cg end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function tw(obj, dur, props, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(dur, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function ripple(btn, col)
    local r = Instance.new("Frame", btn)
    r.Size                   = UDim2.fromOffset(0, 0)
    r.AnchorPoint            = Vector2.new(0.5, 0.5)
    r.Position               = UDim2.new(0.5, 0, 0.5, 0)
    r.BackgroundColor3       = col
    r.BackgroundTransparency = 0.55
    r.BorderSizePixel        = 0
    r.ZIndex                 = btn.ZIndex + 10
    Instance.new("UICorner", r).CornerRadius = UDim.new(1, 0)
    tw(r, 0.38, {Size = UDim2.fromOffset(130, 130), BackgroundTransparency = 1})
    game:GetService("Debris"):AddItem(r, 0.42)
end

local function bevel(frame)
    local g       = Instance.new("UIGradient", frame)
    g.Rotation    = 90
    g.Color       = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 185, 205)),
    })
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.88),
        NumberSequenceKeypoint.new(1, 0.95),
    })
end

local function hsvToColor3(h, s, v)
    return c3hsv(clamp(h, 0, 1), clamp(s, 0, 1), clamp(v, 0, 1))
end

-- ══════════════════════════════════════════════════════════════════════
-- § 4  LIBRARY CORE
-- ══════════════════════════════════════════════════════════════════════
local Library   = {}
Library.__index = Library

function Library.new(config)
    config          = config or {}
    local self      = setmetatable({}, Library)

    self.Flags      = {}
    self.Tabs       = {}
    self.ActiveTab  = nil
    self._accentSubs    = {}
    self._extraConns    = {}
    self._configElems   = {}
    self._listeningForKey = false

    self.Title      = config.Title   or "HutameHub"
    self.Version    = config.Version or "v3.0"
    self.ToggleKey  = config.ToggleKey or Enum.KeyCode.RightControl

    -- Theme
    local presetName = type(config.Theme) == "string" and config.Theme or "Midnight"
    local preset     = Presets[presetName] or Presets.Midnight
    self.T           = {}
    for k, v in pairs(preset) do self.T[k] = v end
    if config.Accent then
        self.T.Accent = config.Accent
        self.T.AccentDim = c3rgb(
            floor(config.Accent.R * 255 * 0.58),
            floor(config.Accent.G * 255 * 0.58),
            floor(config.Accent.B * 255 * 0.58)
        )
    end

    self:_buildGUI()
    return self
end

function Library:_onAccent(fn)
    table.insert(self._accentSubs, fn)
end

function Library:SetAccent(col)
    self.T.Accent    = col
    self.T.AccentDim = c3rgb(
        floor(col.R * 255 * 0.58),
        floor(col.G * 255 * 0.58),
        floor(col.B * 255 * 0.58)
    )
    for _, fn in ipairs(self._accentSubs) do pcall(fn, col) end
end

function Library:SetTheme(themeNameOrTable)
    local src = type(themeNameOrTable) == "string"
        and (Presets[themeNameOrTable] or Presets.Midnight)
        or themeNameOrTable
    for k, v in pairs(src) do self.T[k] = v end
    self:SetAccent(self.T.Accent)
end

-- ══════════════════════════════════════════════════════════════════════
-- § 5  GUI BUILD
-- ══════════════════════════════════════════════════════════════════════
function Library:_buildGUI()
    local T = self.T

    local sg = Instance.new("ScreenGui")
    sg.Name           = "HutameLib_" .. math.random(1000, 9999)
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    if syn and syn.protect_gui then pcall(syn.protect_gui, sg)
    elseif protect_gui then pcall(protect_gui, sg) end
    sg.Parent     = safeParent()
    self.ScreenGui = sg

    -- MainFrame
    local mf = Instance.new("Frame", sg)
    mf.Name              = "MainFrame"
    mf.Size              = UDim2.fromOffset(720, 470)
    mf.Position          = UDim2.new(0.5, -360, 0.5, -235)
    mf.BackgroundColor3  = T.BG
    mf.BorderSizePixel   = 0
    mf.ClipsDescendants  = false
    Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 6)
    local mfStroke = Instance.new("UIStroke", mf)
    mfStroke.Color     = T.Black; mfStroke.Thickness = 2
    local innerB = Instance.new("Frame", mf)
    innerB.Size = UDim2.new(1, -6, 1, -6)
    innerB.Position = UDim2.fromOffset(3, 3)
    innerB.BackgroundTransparency = 1
    innerB.BorderSizePixel = 0
    Instance.new("UICorner", innerB).CornerRadius = UDim.new(0, 5)
    local innerStroke = Instance.new("UIStroke", innerB)
    innerStroke.Color = T.BorderLight; innerStroke.Thickness = 1
    self.MainFrame = mf

    -- Fade in
    mf.BackgroundTransparency = 1
    tw(mf, 0.35, {BackgroundTransparency = 0})

    -- Accent bar
    local acBar = Instance.new("Frame", mf)
    acBar.Name  = "AccentBar"
    acBar.Size  = UDim2.new(1, -12, 0, 2)
    acBar.Position = UDim2.fromOffset(6, 6)
    acBar.BackgroundColor3 = T.Accent
    acBar.BorderSizePixel  = 0; acBar.ZIndex = 5
    Instance.new("UICorner", acBar).CornerRadius = UDim.new(0, 1)
    self:_onAccent(function(c) acBar.BackgroundColor3 = c end)

    -- Topbar
    local topbar = Instance.new("Frame", mf)
    topbar.Name  = "Topbar"
    topbar.Size  = UDim2.new(1, -12, 0, 34)
    topbar.Position = UDim2.fromOffset(6, 10)
    topbar.BackgroundColor3 = T.Surface
    topbar.BorderSizePixel  = 0; topbar.ZIndex = 4
    Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 4)

    local brand = Instance.new("TextLabel", topbar)
    brand.Size  = UDim2.new(1, -170, 1, 0)
    brand.Position = UDim2.fromOffset(12, 0)
    brand.BackgroundTransparency = 1
    brand.Font     = Enum.Font.GothamBold
    brand.TextSize = 14
    brand.TextColor3 = T.White
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.RichText = true; brand.ZIndex = 5

    local function updateBrand()
        brand.Text = string.format(
            '<font color="#%s">%s</font>  <font color="#%s" size="11">%s</font>',
            self.T.Accent:ToHex(), self.Title,
            self.T.TextDim:ToHex(), self.Version
        )
    end
    updateBrand()
    self:_onAccent(function() updateBrand() end)

    local userLbl = Instance.new("TextLabel", topbar)
    userLbl.Size  = UDim2.fromOffset(100, 34)
    userLbl.Position = UDim2.new(1, -168, 0, 0)
    userLbl.BackgroundTransparency = 1
    userLbl.Font     = Enum.Font.Gotham
    userLbl.TextSize = 11
    userLbl.TextColor3 = T.TextMute
    userLbl.TextXAlignment = Enum.TextXAlignment.Right
    userLbl.ZIndex = 5
    userLbl.Text   = LocalPlayer.Name

    local ctrlHolder = Instance.new("Frame", topbar)
    ctrlHolder.Size  = UDim2.fromOffset(60, 34)
    ctrlHolder.Position = UDim2.new(1, -60, 0, 0)
    ctrlHolder.BackgroundTransparency = 1; ctrlHolder.ZIndex = 6

    local function mkCtrl(char, xOff, hColor, onClick)
        local b = Instance.new("TextButton", ctrlHolder)
        b.Size  = UDim2.fromOffset(22, 22)
        b.Position = UDim2.new(0, xOff, 0.5, -11)
        b.BackgroundColor3 = T.Element
        b.BorderSizePixel  = 0
        b.Font     = Enum.Font.Gotham
        b.TextSize = 11
        b.TextColor3 = T.TextDim
        b.Text     = char
        b.AutoButtonColor = false; b.ZIndex = 6
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseEnter:Connect(function() tw(b, 0.12, {BackgroundColor3 = hColor, TextColor3 = T.White}) end)
        b.MouseLeave:Connect(function() tw(b, 0.12, {BackgroundColor3 = T.Element, TextColor3 = T.TextDim}) end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end
    mkCtrl("—", 4,  T.ElementHov, function()
        if self._body then self._body.Visible = not self._body.Visible end
    end)
    mkCtrl("✕", 30, c3rgb(200, 44, 44), function() self:Destroy() end)

    -- Drag
    local dragging, dragStart, mfStart = false, nil, nil
    topbar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; mfStart = mf.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            mf.Position = UDim2.new(mfStart.X.Scale, mfStart.X.Offset + d.X, mfStart.Y.Scale, mfStart.Y.Offset + d.Y)
        end
    end)

    -- TabBar
    local tabBar = Instance.new("Frame", mf)
    tabBar.Name  = "TabBar"
    tabBar.Size  = UDim2.new(1, -12, 0, 30)
    tabBar.Position = UDim2.fromOffset(6, 48)
    tabBar.BackgroundColor3 = T.Surface
    tabBar.BorderSizePixel  = 0; tabBar.ZIndex = 4
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 4)
    local tabBarStroke = Instance.new("UIStroke", tabBar)
    tabBarStroke.Color = T.Border; tabBarStroke.Thickness = 1
    tabBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local tabList = Instance.new("Frame", tabBar)
    tabList.Size  = UDim2.new(1, -6, 1, 0)
    tabList.Position = UDim2.fromOffset(3, 0)
    tabList.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabList)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    tabLayout.Padding       = UDim.new(0, 2)
    self.TabBar  = tabBar
    self.TabList = tabList

    -- Body
    local body = Instance.new("Frame", mf)
    body.Name  = "Body"
    body.Size  = UDim2.new(1, -12, 1, -86)
    body.Position = UDim2.fromOffset(6, 82)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true; body.ZIndex = 2
    self._body = body

    -- Toggle key
    local toggleConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or self._listeningForKey or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == self.ToggleKey then
            mf.Visible = not mf.Visible
        end
    end)
    table.insert(self._extraConns, toggleConn)
end

-- ══════════════════════════════════════════════════════════════════════
-- § 6  TAB
-- ══════════════════════════════════════════════════════════════════════
function Library:CreateTab(name, icon)
    local T   = self.T
    local Tab = {Name = name, Active = false, _lib = self}

    local btn = Instance.new("TextButton", self.TabList)
    btn.Name  = "Tab_" .. name
    btn.AutomaticSize   = Enum.AutomaticSize.X
    btn.Size  = UDim2.new(0, 0, 1, 0)
    btn.BackgroundColor3 = T.Element
    btn.BorderSizePixel  = 0
    btn.Font     = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.TextColor3 = T.TextDim
    btn.Text     = (icon and (icon .. "  ") or "") .. name
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true; btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local btnPad = Instance.new("UIPadding", btn)
    btnPad.PaddingLeft  = UDim.new(0, 10)
    btnPad.PaddingRight = UDim.new(0, 10)

    local uline = Instance.new("Frame", btn)
    uline.Name  = "Underline"
    uline.Size  = UDim2.new(1, 0, 0, 2)
    uline.Position = UDim2.new(0, 0, 1, -2)
    uline.BackgroundColor3 = T.Accent
    uline.BackgroundTransparency = 1
    uline.BorderSizePixel  = 0; uline.ZIndex = 6
    self:_onAccent(function(c) if Tab.Active then uline.BackgroundColor3 = c end end)

    -- Page
    local page = Instance.new("Frame", self._body)
    page.Name  = "Page_" .. name
    page.Size  = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ClipsDescendants = true

    -- Left column
    local leftScroll = Instance.new("ScrollingFrame", page)
    leftScroll.Name  = "LeftCol"
    leftScroll.Size  = UDim2.new(0.5, -2, 1, 0)
    leftScroll.BackgroundTransparency = 1
    leftScroll.ScrollBarThickness     = 2
    leftScroll.ScrollBarImageColor3   = T.Border
    leftScroll.BorderSizePixel        = 0
    leftScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    leftScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    local lPad = Instance.new("UIPadding", leftScroll)
    lPad.PaddingTop    = UDim.new(0, 8); lPad.PaddingBottom = UDim.new(0, 8)
    lPad.PaddingLeft   = UDim.new(0, 8); lPad.PaddingRight  = UDim.new(0, 4)
    local lLayout = Instance.new("UIListLayout", leftScroll)
    lLayout.SortOrder  = Enum.SortOrder.LayoutOrder
    lLayout.Padding    = UDim.new(0, 6)

    -- Divider
    local div = Instance.new("Frame", page)
    div.Size  = UDim2.new(0, 1, 1, 0)
    div.Position = UDim2.new(0.5, 0, 0, 0)
    div.BackgroundColor3 = T.Border
    div.BorderSizePixel  = 0

    -- Right column
    local rightScroll = Instance.new("ScrollingFrame", page)
    rightScroll.Name  = "RightCol"
    rightScroll.Size  = UDim2.new(0.5, -2, 1, 0)
    rightScroll.Position = UDim2.new(0.5, 2, 0, 0)
    rightScroll.BackgroundTransparency = 1
    rightScroll.ScrollBarThickness     = 2
    rightScroll.ScrollBarImageColor3   = T.Border
    rightScroll.BorderSizePixel        = 0
    rightScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    rightScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    local rPad = Instance.new("UIPadding", rightScroll)
    rPad.PaddingTop    = UDim.new(0, 8); rPad.PaddingBottom = UDim.new(0, 8)
    rPad.PaddingLeft   = UDim.new(0, 4); rPad.PaddingRight  = UDim.new(0, 8)
    local rLayout = Instance.new("UIListLayout", rightScroll)
    rLayout.SortOrder  = Enum.SortOrder.LayoutOrder
    rLayout.Padding    = UDim.new(0, 6)

    Tab._page  = page
    Tab._left  = leftScroll
    Tab._right = rightScroll
    Tab._btn   = btn
    Tab._uline = uline

    function Tab:Activate()
        for _, t in ipairs(self._lib.Tabs) do
            if t ~= Tab then t:Deactivate() end
        end
        Tab.Active   = true
        page.Visible = true
        tw(btn,   0.15, {TextColor3 = self._lib.T.Accent, BackgroundColor3 = self._lib.T.Card})
        tw(uline, 0.15, {BackgroundTransparency = 0, BackgroundColor3 = self._lib.T.Accent})
        self._lib.ActiveTab = Tab
    end

    function Tab:Deactivate()
        Tab.Active   = false
        page.Visible = false
        tw(btn,   0.15, {TextColor3 = T.TextDim, BackgroundColor3 = T.Element})
        tw(uline, 0.15, {BackgroundTransparency = 1})
    end

    btn.MouseButton1Click:Connect(function() Tab:Activate() end)
    btn.MouseEnter:Connect(function() if not Tab.Active then tw(btn, 0.1, {TextColor3 = T.Text}) end end)
    btn.MouseLeave:Connect(function() if not Tab.Active then tw(btn, 0.1, {TextColor3 = T.TextDim}) end end)

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then Tab:Activate() end

    function Tab:CreateSection(title, col)
        local parent = (col == "right") and self._right or self._left
        return self._lib:_buildSection(title, parent)
    end

    return Tab
end

-- ══════════════════════════════════════════════════════════════════════
-- § 7  SECTION
-- ══════════════════════════════════════════════════════════════════════
function Library:_buildSection(title, parent)
    local T       = self.T
    local Section = {_lib = self}

    local card = Instance.new("Frame", parent)
    card.Name  = "Sec_" .. title
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel  = 0
    card.Size  = UDim2.new(1, 0, 0, 40)
    card.ClipsDescendants = true
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local cStroke = Instance.new("UIStroke", card)
    cStroke.Color = T.Border; cStroke.Thickness = 1
    local cPad = Instance.new("UIPadding", card)
    cPad.PaddingTop    = UDim.new(0, 6); cPad.PaddingBottom = UDim.new(0, 8)
    cPad.PaddingLeft   = UDim.new(0, 8); cPad.PaddingRight  = UDim.new(0, 8)
    local cLayout = Instance.new("UIListLayout", card)
    cLayout.SortOrder  = Enum.SortOrder.LayoutOrder
    cLayout.Padding    = UDim.new(0, 4)

    -- Header
    local hdrBtn = Instance.new("TextButton", card)
    hdrBtn.Size  = UDim2.new(1, 0, 0, 18)
    hdrBtn.BackgroundTransparency = 1
    hdrBtn.BorderSizePixel = 0
    hdrBtn.Text  = ""; hdrBtn.AutoButtonColor = false
    hdrBtn.LayoutOrder = 0

    local hdrLabel = Instance.new("TextLabel", hdrBtn)
    hdrLabel.Size  = UDim2.new(1, -20, 1, 0)
    hdrLabel.BackgroundTransparency = 1
    hdrLabel.Font     = Enum.Font.GothamMedium
    hdrLabel.TextSize = 12
    hdrLabel.TextColor3 = T.TextDim
    hdrLabel.TextXAlignment = Enum.TextXAlignment.Left
    hdrLabel.Text = title

    local colArrow = Instance.new("TextLabel", hdrBtn)
    colArrow.Size  = UDim2.fromOffset(16, 18)
    colArrow.Position = UDim2.new(1, -16, 0, 0)
    colArrow.BackgroundTransparency = 1
    colArrow.Font     = Enum.Font.GothamBold
    colArrow.TextSize = 8
    colArrow.TextColor3 = T.TextMute
    colArrow.Text = "▲"

    local hSep = Instance.new("Frame", card)
    hSep.Size  = UDim2.new(1, 0, 0, 1)
    hSep.BackgroundColor3 = T.Border
    hSep.BorderSizePixel  = 0; hSep.LayoutOrder = 1

    local collapsed = false
    local sizeTween
    local HEADER_H  = 6 + 18 + 4 + 1 + 8

    local function doResize(animate)
        local target = collapsed
            and HEADER_H
            or  math.max(HEADER_H + 6, cLayout.AbsoluteContentSize.Y + 14)
        if sizeTween then sizeTween:Cancel(); sizeTween = nil end
        if animate then
            sizeTween = TweenService:Create(card,
                TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(1, 0, 0, target)})
            sizeTween:Play()
        else
            card.Size = UDim2.new(1, 0, 0, target)
        end
    end

    local function setCollapsed(val)
        if collapsed == val then return end
        collapsed = val
        if not val then
            for _, ch in ipairs(card:GetChildren()) do
                if ch:IsA("GuiObject") and ch ~= hdrBtn and ch ~= hSep then
                    ch.Visible = true
                end
            end
        end
        tw(colArrow, 0.2, {Rotation = val and 180 or 0})
        doResize(true)
    end

    cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not collapsed then doResize(false) end
    end)
    card.Destroying:Connect(function() if sizeTween then sizeTween:Cancel() end end)
    doResize(false)

    hdrBtn.MouseButton1Click:Connect(function() setCollapsed(not collapsed) end)
    hdrBtn.MouseEnter:Connect(function()  tw(hdrLabel, 0.1, {TextColor3 = T.Text}) end)
    hdrBtn.MouseLeave:Connect(function() tw(hdrLabel, 0.1, {TextColor3 = T.TextDim}) end)

    function Section:Collapse() setCollapsed(true) end
    function Section:Expand()   setCollapsed(false) end

    Section._card  = card
    Section._order = 2

    local function nextOrder()
        Section._order = Section._order + 1
        return Section._order
    end

    -- ────────────────────────────────────────────
    -- TOGGLE
    -- ────────────────────────────────────────────
    function Section:CreateToggle(cfg)
        cfg         = cfg or {}
        local ttl   = cfg.Title    or "Toggle"
        local flag  = cfg.Flag     or nil
        local state = cfg.Default  or false
        local cb    = cfg.Callback or function() end
        local bindK = cfg.Keybind  or nil
        local Toggle = {State = state}

        local row = Instance.new("TextButton", card)
        row.Name  = "Row_Toggle_" .. ttl
        row.Size  = UDim2.new(1, 0, 0, 24)
        row.BackgroundTransparency = 1
        row.Text  = ""; row.AutoButtonColor = false
        row.LayoutOrder = nextOrder()

        local box = Instance.new("Frame", row)
        box.Size  = UDim2.fromOffset(14, 14)
        box.Position = UDim2.new(0, 0, 0.5, -7)
        box.BackgroundColor3 = state and T.Accent or T.Element
        box.BorderSizePixel  = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)
        bevel(box)
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color = state and T.Accent or T.BorderLight
        boxStroke.Thickness = 1

        local tick = Instance.new("TextLabel", box)
        tick.Size  = UDim2.new(1, 0, 1, 0)
        tick.BackgroundTransparency = 1
        tick.Font     = Enum.Font.GothamBold
        tick.TextSize = 9
        tick.TextColor3 = T.White
        tick.Text    = "✓"; tick.Visible = state

        local lbl = Instance.new("TextLabel", row)
        lbl.Size  = UDim2.new(1, -66, 1, 0)
        lbl.Position = UDim2.fromOffset(22, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font     = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = state and T.Text or T.TextDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text   = ttl

        local bindHint = Instance.new("TextLabel", row)
        bindHint.Size  = UDim2.fromOffset(54, 24)
        bindHint.Position = UDim2.new(1, -54, 0, 0)
        bindHint.BackgroundTransparency = 1
        bindHint.Font     = Enum.Font.Gotham
        bindHint.TextSize = 10
        bindHint.TextColor3 = T.TextMute
        bindHint.TextXAlignment = Enum.TextXAlignment.Right
        bindHint.Text = bindK and ("[" .. bindK.Name .. "]") or ""

        self._lib:_onAccent(function(c)
            if Toggle.State then
                box.BackgroundColor3 = c
                boxStroke.Color      = c
            end
        end)

        if flag then self._lib.Flags[flag] = state end

        function Toggle:Set(val)
            Toggle.State         = val
            tick.Visible         = val
            box.BackgroundColor3 = val and self._lib.T.Accent or T.Element
            boxStroke.Color      = val and self._lib.T.Accent or T.BorderLight
            tw(lbl, 0.12, {TextColor3 = val and T.Text or T.TextDim})
            if flag then self._lib.Flags[flag] = val end
            pcall(cb, val)
        end
        Toggle._lib = self._lib

        row.MouseButton1Click:Connect(function() Toggle:Set(not Toggle.State) end)
        row.MouseEnter:Connect(function()  tw(lbl, 0.1, {TextColor3 = T.Text}) end)
        row.MouseLeave:Connect(function()
            if not Toggle.State then tw(lbl, 0.1, {TextColor3 = T.TextDim}) end
        end)

        if bindK then
            local conn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe or self._lib._listeningForKey or UserInputService:GetFocusedTextBox() then return end
                if input.KeyCode == bindK then Toggle:Set(not Toggle.State) end
            end)
            table.insert(self._lib._extraConns, conn)
        end

        if cfg.ConfigKey then
            self._lib:_regCfg(cfg.ConfigKey,
                function() return Toggle.State and "true" or "false" end,
                function(v) Toggle:Set(v == "true") end)
        end

        return Toggle
    end

    -- ────────────────────────────────────────────
    -- SLIDER
    -- ────────────────────────────────────────────
    function Section:CreateSlider(cfg)
        cfg          = cfg or {}
        local ttl    = cfg.Title    or "Slider"
        local flag   = cfg.Flag     or nil
        local min    = cfg.Min      or 0
        local max    = cfg.Max      or 100
        local default= clamp(cfg.Default or min, min, max)
        local decs   = cfg.Decimals or 0
        local suffix = cfg.Suffix   or ""
        local cb     = cfg.Callback or function() end
        local Slider = {Value = default}

        local container = Instance.new("Frame", card)
        container.Name  = "Row_Slider_" .. ttl
        container.Size  = UDim2.new(1, 0, 0, 36)
        container.BackgroundTransparency = 1
        container.LayoutOrder = nextOrder()

        local hRow = Instance.new("Frame", container)
        hRow.Size  = UDim2.new(1, 0, 0, 16)
        hRow.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", hRow)
        lbl.Size  = UDim2.new(1, -72, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font     = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = T.TextDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text   = ttl

        local valLbl = Instance.new("TextLabel", hRow)
        valLbl.Size  = UDim2.fromOffset(72, 16)
        valLbl.Position = UDim2.new(1, -72, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Font     = Enum.Font.GothamMedium
        valLbl.TextSize = 11
        valLbl.TextColor3 = T.Text
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Text = string.format("%." .. decs .. "f / %s%s", default, tostring(max), suffix)

        local track = Instance.new("TextButton", container)
        track.Size  = UDim2.new(1, 0, 0, 8)
        track.Position = UDim2.fromOffset(0, 20)
        track.BackgroundColor3 = T.Element
        track.BorderSizePixel  = 0
        track.Text  = ""; track.AutoButtonColor = false
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        bevel(track)

        local fill = Instance.new("Frame", track)
        fill.Size  = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = T.Accent
        fill.BorderSizePixel  = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        self._lib:_onAccent(function(c) fill.BackgroundColor3 = c end)

        local knob = Instance.new("Frame", fill)
        knob.Size  = UDim2.fromOffset(10, 10)
        knob.Position = UDim2.new(1, -5, 0.5, -5)
        knob.BackgroundColor3 = T.White
        knob.BorderSizePixel  = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        if flag then self._lib.Flags[flag] = default end

        local function doUpdate(input)
            local px  = input.Position.X - track.AbsolutePosition.X
            local pct = clamp(px / track.AbsoluteSize.X, 0, 1)
            local raw = min + (max - min) * pct
            local val = tonumber(string.format("%." .. decs .. "f", raw)) or default
            Slider.Value = val
            valLbl.Text  = string.format("%." .. decs .. "f / %s%s", val, tostring(max), suffix)
            tw(fill, 0.04, {Size = UDim2.new(pct, 0, 1, 0)})
            if flag then self._lib.Flags[flag] = val end
            pcall(cb, val)
        end

        function Slider:Set(val)
            val          = clamp(val, min, max)
            Slider.Value = val
            valLbl.Text  = string.format("%." .. decs .. "f / %s%s", val, tostring(max), suffix)
            local pct    = (val - min) / (max - min)
            tw(fill, 0.14, {Size = UDim2.new(pct, 0, 1, 0)})
            if flag then self._lib.Flags[flag] = val end
            pcall(cb, val)
        end
        Slider._lib = self._lib

        local drag = false
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag = true; doUpdate(i)
            end
        end)
        local c1 = UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
        end)
        local c2 = UserInputService.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                doUpdate(i)
            end
        end)
        table.insert(self._lib._extraConns, c1)
        table.insert(self._lib._extraConns, c2)

        track.MouseEnter:Connect(function() tw(knob, 0.1, {BackgroundColor3 = self._lib.T.Accent}) end)
        track.MouseLeave:Connect(function() tw(knob, 0.1, {BackgroundColor3 = T.White}) end)

        if cfg.ConfigKey then
            self._lib:_regCfg(cfg.ConfigKey,
                function() return tostring(Slider.Value) end,
                function(v) Slider:Set(tonumber(v) or default) end)
        end

        return Slider
    end

    -- ────────────────────────────────────────────
    -- DROPDOWN (single-select)
    -- ────────────────────────────────────────────
    function Section:CreateDropdown(cfg)
        cfg          = cfg or {}
        local ttl    = cfg.Title    or "Dropdown"
        local flag   = cfg.Flag     or nil
        local opts   = cfg.Options  or {}
        local sel    = cfg.Default  or opts[1] or ""
        local maxVis = cfg.MaxVisible or 5
        local cb     = cfg.Callback or function() end
        local Dropdown = {Selected = sel, Opened = false, Options = opts}

        local ITEM_H = 22

        local container = Instance.new("Frame", card)
        container.Name  = "Row_DD_" .. ttl
        container.Size  = UDim2.new(1, 0, 0, 24)
        container.BackgroundTransparency = 1
        container.ClipsDescendants = false
        container.LayoutOrder = nextOrder()

        local hdr = Instance.new("TextButton", container)
        hdr.Size  = UDim2.new(1, 0, 0, 24)
        hdr.BackgroundColor3 = T.Element
        hdr.BorderSizePixel  = 0
        hdr.Text  = ""; hdr.AutoButtonColor = false; hdr.ZIndex = 3
        Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 4)
        bevel(hdr)
        local hStroke = Instance.new("UIStroke", hdr)
        hStroke.Color = T.Border; hStroke.Thickness = 1

        local hLbl = Instance.new("TextLabel", hdr)
        hLbl.Size  = UDim2.new(0.5, 0, 1, 0)
        hLbl.Position = UDim2.fromOffset(8, 0)
        hLbl.BackgroundTransparency = 1
        hLbl.Font     = Enum.Font.Gotham; hLbl.TextSize = 11
        hLbl.TextColor3 = T.TextDim
        hLbl.TextXAlignment = Enum.TextXAlignment.Left; hLbl.Text = ttl

        local valLbl = Instance.new("TextLabel", hdr)
        valLbl.Size  = UDim2.new(0.44, -18, 1, 0)
        valLbl.Position = UDim2.new(0.5, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Font     = Enum.Font.GothamMedium; valLbl.TextSize = 11
        valLbl.TextColor3 = T.Text
        valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Text = tostring(sel)

        local arrow = Instance.new("TextLabel", hdr)
        arrow.Size  = UDim2.fromOffset(16, 24); arrow.Position = UDim2.new(1, -18, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Font     = Enum.Font.GothamBold; arrow.TextSize = 8
        arrow.TextColor3 = T.TextMute; arrow.Text = "▼"

        local listFrame = Instance.new("ScrollingFrame", container)
        listFrame.Size  = UDim2.new(1, 0, 0, 0)
        listFrame.Position = UDim2.fromOffset(0, 26)
        listFrame.BackgroundColor3 = T.Surface
        listFrame.BorderSizePixel  = 0
        listFrame.ClipsDescendants = true; listFrame.Visible = false; listFrame.ZIndex = 10
        listFrame.ScrollBarThickness = 2; listFrame.ScrollBarImageColor3 = T.Border
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)
        local lStroke = Instance.new("UIStroke", listFrame)
        lStroke.Color = T.BorderLight; lStroke.Thickness = 1
        local listLayout = Instance.new("UIListLayout", listFrame)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 1)
        local listPad = Instance.new("UIPadding", listFrame)
        listPad.PaddingTop = UDim.new(0, 2); listPad.PaddingBottom = UDim.new(0, 2)

        if flag then self._lib.Flags[flag] = sel end

        local function setLayout()
            local count = #Dropdown.Options
            local total = 4 + count * (ITEM_H + 1)
            local view  = math.min(total, 4 + maxVis * (ITEM_H + 1))
            listFrame.CanvasSize = UDim2.fromOffset(0, total)
            listFrame.Size       = UDim2.new(1, 0, 0, view)
            container.Size       = UDim2.new(1, 0, 0, Dropdown.Opened and (26 + view) or 24)
        end

        local function buildList()
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(Dropdown.Options) do
                local isSel = opt == Dropdown.Selected
                local ob    = Instance.new("TextButton", listFrame)
                ob.Size     = UDim2.new(1, -4, 0, ITEM_H)
                ob.BackgroundColor3 = isSel and self._lib.T.Accent or T.Element
                ob.BackgroundTransparency = isSel and 0.25 or 0.92
                ob.BorderSizePixel = 0
                ob.Font     = Enum.Font.Gotham; ob.TextSize = 11
                ob.TextColor3 = isSel and T.White or T.TextDim
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.Text     = "  " .. tostring(opt)
                ob.AutoButtonColor = false; ob.ZIndex = 11
                Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 3)
                ob.MouseEnter:Connect(function()
                    if not isSel then tw(ob, 0.1, {BackgroundTransparency = 0.7, TextColor3 = T.Text}) end
                end)
                ob.MouseLeave:Connect(function()
                    if not isSel then tw(ob, 0.1, {BackgroundTransparency = 0.92, TextColor3 = T.TextDim}) end
                end)
                ob.MouseButton1Click:Connect(function()
                    Dropdown:Set(opt)
                    Dropdown:Close()
                end)
            end
            setLayout()
        end

        function Dropdown:Open()
            Dropdown.Opened = true; listFrame.Visible = true; buildList()
            tw(arrow, 0.15, {Rotation = 180})
            tw(hStroke, 0.15, {Color = self._lib and self._lib.T.Accent or T.Accent})
        end
        Dropdown._lib = self._lib

        function Dropdown:Close()
            Dropdown.Opened = false
            tw(arrow, 0.15, {Rotation = 0}); tw(hStroke, 0.15, {Color = T.Border})
            listFrame.Visible = false; container.Size = UDim2.new(1, 0, 0, 24)
        end

        function Dropdown:Set(opt)
            Dropdown.Selected = opt; valLbl.Text = tostring(opt)
            if flag then self._lib.Flags[flag] = opt end
            buildList(); pcall(cb, opt)
        end

        function Dropdown:Refresh(newOpts)
            Dropdown.Options = newOpts or {}; buildList()
        end

        hdr.MouseButton1Click:Connect(function()
            if Dropdown.Opened then Dropdown:Close() else Dropdown:Open() end
        end)

        if cfg.ConfigKey then
            self._lib:_regCfg(cfg.ConfigKey,
                function() return tostring(Dropdown.Selected) end,
                function(v) Dropdown:Set(v) end)
        end

        return Dropdown
    end

    -- ────────────────────────────────────────────
    -- MULTI DROPDOWN
    -- ────────────────────────────────────────────
    function Section:CreateMultiDropdown(cfg)
        cfg          = cfg or {}
        local ttl    = cfg.Title    or "MultiDropdown"
        local flag   = cfg.Flag     or nil
        local opts   = cfg.Options  or {}
        local defs   = cfg.Default  or {}
        local maxShow = cfg.MaxShow or 2
        local maxVis = cfg.MaxVisible or 5
        local cb     = cfg.Callback or function() end
        local ITEM_H = 22

        local selected = {}
        for _, v in ipairs(defs) do selected[v] = true end
        local MDD = {Selected = selected, Opened = false, Options = opts}

        local function summary()
            local keys = {}
            for k in pairs(selected) do table.insert(keys, k) end
            table.sort(keys)
            if #keys == 0 then return "None" end
            if #keys <= maxShow then return table.concat(keys, ", ") end
            return keys[1] .. ", +" .. tostring(#keys - 1)
        end

        local function getList()
            local res = {}
            for k in pairs(selected) do table.insert(res, k) end
            return res
        end

        local container = Instance.new("Frame", card)
        container.Name  = "Row_MDD_" .. ttl
        container.Size  = UDim2.new(1, 0, 0, 24)
        container.BackgroundTransparency = 1
        container.ClipsDescendants = false
        container.LayoutOrder = nextOrder()

        local hdr = Instance.new("TextButton", container)
        hdr.Size  = UDim2.new(1, 0, 0, 24)
        hdr.BackgroundColor3 = T.Element; hdr.BorderSizePixel = 0
        hdr.Text  = ""; hdr.AutoButtonColor = false; hdr.ZIndex = 3
        Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 4); bevel(hdr)
        local hStroke = Instance.new("UIStroke", hdr)
        hStroke.Color = T.Border; hStroke.Thickness = 1

        local hLbl = Instance.new("TextLabel", hdr)
        hLbl.Size  = UDim2.new(0.46, 0, 1, 0); hLbl.Position = UDim2.fromOffset(8, 0)
        hLbl.BackgroundTransparency = 1; hLbl.Font = Enum.Font.Gotham; hLbl.TextSize = 11
        hLbl.TextColor3 = T.TextDim; hLbl.TextXAlignment = Enum.TextXAlignment.Left; hLbl.Text = ttl

        local valLbl = Instance.new("TextLabel", hdr)
        valLbl.Size  = UDim2.new(0.47, -18, 1, 0); valLbl.Position = UDim2.new(0.48, 0, 0, 0)
        valLbl.BackgroundTransparency = 1; valLbl.Font = Enum.Font.GothamMedium; valLbl.TextSize = 10
        valLbl.TextColor3 = T.Text; valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.TextTruncate = Enum.TextTruncate.AtEnd; valLbl.Text = summary()

        local arrow = Instance.new("TextLabel", hdr)
        arrow.Size  = UDim2.fromOffset(16, 24); arrow.Position = UDim2.new(1, -18, 0, 0)
        arrow.BackgroundTransparency = 1; arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 8
        arrow.TextColor3 = T.TextMute; arrow.Text = "▼"

        local listFrame = Instance.new("ScrollingFrame", container)
        listFrame.Size  = UDim2.new(1, 0, 0, 0); listFrame.Position = UDim2.fromOffset(0, 26)
        listFrame.BackgroundColor3 = T.Surface; listFrame.BorderSizePixel = 0
        listFrame.ClipsDescendants = true; listFrame.Visible = false; listFrame.ZIndex = 10
        listFrame.ScrollBarThickness = 2; listFrame.ScrollBarImageColor3 = T.Border
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)
        local lStroke = Instance.new("UIStroke", listFrame); lStroke.Color = T.BorderLight; lStroke.Thickness = 1
        local listLayout = Instance.new("UIListLayout", listFrame)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 1)
        local listPad = Instance.new("UIPadding", listFrame)
        listPad.PaddingTop = UDim.new(0, 2); listPad.PaddingBottom = UDim.new(0, 2)

        if flag then self._lib.Flags[flag] = getList() end

        local function setLayout()
            local count = #MDD.Options
            local total = 4 + count * (ITEM_H + 1)
            local view  = math.min(total, 4 + maxVis * (ITEM_H + 1))
            listFrame.CanvasSize = UDim2.fromOffset(0, total)
            listFrame.Size       = UDim2.new(1, 0, 0, view)
            container.Size       = UDim2.new(1, 0, 0, MDD.Opened and (26 + view) or 24)
        end

        local function buildList()
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(MDD.Options) do
                local isSel = selected[opt] == true
                local ob    = Instance.new("TextButton", listFrame)
                ob.Size     = UDim2.new(1, -4, 0, ITEM_H)
                ob.BackgroundColor3 = isSel and self._lib.T.Accent or T.Element
                ob.BackgroundTransparency = isSel and 0.25 or 0.92; ob.BorderSizePixel = 0
                ob.Font     = Enum.Font.Gotham; ob.TextSize = 11
                ob.TextColor3 = isSel and T.White or T.TextDim
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.Text     = "  " .. tostring(opt); ob.AutoButtonColor = false; ob.ZIndex = 11
                Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 3)
                local ck    = Instance.new("TextLabel", ob)
                ck.Size     = UDim2.fromOffset(18, ITEM_H); ck.Position = UDim2.new(1, -20, 0, 0)
                ck.BackgroundTransparency = 1; ck.Font = Enum.Font.GothamBold; ck.TextSize = 10; ck.ZIndex = 12
                ck.TextColor3 = self._lib.T.Accent; ck.Text = isSel and "✓" or ""
                ob.MouseEnter:Connect(function()
                    if not selected[opt] then tw(ob, 0.1, {BackgroundTransparency = 0.7, TextColor3 = T.Text}) end
                end)
                ob.MouseLeave:Connect(function()
                    if not selected[opt] then tw(ob, 0.1, {BackgroundTransparency = 0.92, TextColor3 = T.TextDim}) end
                end)
                ob.MouseButton1Click:Connect(function()
                    if selected[opt] then selected[opt] = nil else selected[opt] = true end
                    valLbl.Text = summary(); buildList()
                    local res = getList()
                    if flag then self._lib.Flags[flag] = res end
                    pcall(cb, res)
                end)
            end
            setLayout()
        end

        function MDD:Open()
            MDD.Opened = true; listFrame.Visible = true; buildList()
            tw(arrow, 0.15, {Rotation = 180})
            tw(hStroke, 0.15, {Color = self._lib and self._lib.T.Accent or T.Accent})
        end
        MDD._lib = self._lib

        function MDD:Close()
            MDD.Opened = false
            tw(arrow, 0.15, {Rotation = 0}); tw(hStroke, 0.15, {Color = T.Border})
            listFrame.Visible = false; container.Size = UDim2.new(1, 0, 0, 24)
        end

        function MDD:Set(tbl)
            selected = {}
            for _, v in ipairs(tbl) do selected[v] = true end
            valLbl.Text = summary(); buildList()
            local res = getList()
            if flag then self._lib.Flags[flag] = res end
            pcall(cb, res)
        end

        function MDD:GetSelected() return getList() end
        function MDD:Refresh(newOpts) MDD.Options = newOpts or {}; buildList() end

        hdr.MouseButton1Click:Connect(function()
            if MDD.Opened then MDD:Close() else MDD:Open() end
        end)

        if cfg.ConfigKey then
            self._lib:_regCfg(cfg.ConfigKey,
                function()
                    local r = getList(); table.sort(r)
                    return HttpService:JSONEncode(r)
                end,
                function(v)
                    local ok, t = pcall(function() return HttpService:JSONDecode(v) end)
                    MDD:Set((ok and type(t) == "table") and t or {})
                end)
        end

        return MDD
    end

    -- ────────────────────────────────────────────
    -- TEXTBOX
    -- ────────────────────────────────────────────
    function Section:CreateTextbox(cfg)
        cfg        = cfg or {}
        local ttl  = cfg.Title       or "Textbox"
        local flag = cfg.Flag        or nil
        local ph   = cfg.Placeholder or "Type here..."
        local def  = cfg.Default     or ""
        local numOnly = cfg.NumberOnly or false
        local cb   = cfg.Callback    or function() end
        local Tb   = {Text = def}

        local row  = Instance.new("Frame", card)
        row.Name   = "Row_TB_" .. ttl
        row.Size   = UDim2.new(1, 0, 0, 24)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextOrder()

        local lbl  = Instance.new("TextLabel", row)
        lbl.Size   = UDim2.new(0.42, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font   = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextColor3 = T.TextDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ttl

        local inputFrame = Instance.new("Frame", row)
        inputFrame.Size  = UDim2.new(0.58, -2, 1, -2)
        inputFrame.Position = UDim2.new(0.42, 2, 0, 1)
        inputFrame.BackgroundColor3 = T.Element; inputFrame.BorderSizePixel = 0
        Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 4); bevel(inputFrame)
        local ifStroke = Instance.new("UIStroke", inputFrame)
        ifStroke.Color = T.Border; ifStroke.Thickness = 1

        local input = Instance.new("TextBox", inputFrame)
        input.Size  = UDim2.new(1, -10, 1, 0); input.Position = UDim2.fromOffset(5, 0)
        input.BackgroundTransparency = 1
        input.Font  = Enum.Font.Gotham; input.TextSize = 11; input.TextColor3 = T.Text
        input.PlaceholderColor3 = T.TextMute; input.PlaceholderText = ph
        input.Text  = def; input.ClearTextOnFocus = false

        if flag then self._lib.Flags[flag] = def end

        input.Focused:Connect(function()  tw(ifStroke, 0.15, {Color = self._lib.T.Accent}) end)
        input.FocusLost:Connect(function(enter)
            tw(ifStroke, 0.15, {Color = T.Border})
            local txt = input.Text
            if numOnly then
                local n = tonumber(txt)
                txt = n and tostring(n) or Tb.Text; input.Text = txt
            end
            Tb.Text = txt
            if flag then self._lib.Flags[flag] = txt end
            pcall(cb, txt, enter)
        end)

        function Tb:Set(txt)
            input.Text = tostring(txt); Tb.Text = tostring(txt)
            if flag then self._lib.Flags[flag] = Tb.Text end
        end
        Tb._lib = self._lib

        if cfg.ConfigKey then
            self._lib:_regCfg(cfg.ConfigKey,
                function() return tostring(Tb.Text) end,
                function(v) Tb:Set(v) end)
        end

        return Tb
    end

    -- ────────────────────────────────────────────
    -- KEYBIND
    -- ────────────────────────────────────────────
    function Section:CreateKeybind(cfg)
        cfg        = cfg or {}
        local ttl  = cfg.Title    or "Keybind"
        local flag = cfg.Flag     or nil
        local defK = cfg.Default  or Enum.KeyCode.None
        local cb   = cfg.Callback or function() end
        local Kb   = {Key = defK, Listening = false}

        local row  = Instance.new("Frame", card)
        row.Name   = "Row_KB_" .. ttl
        row.Size   = UDim2.new(1, 0, 0, 24)
        row.BackgroundTransparency = 1
        row.LayoutOrder = nextOrder()

        local lbl  = Instance.new("TextLabel", row)
        lbl.Size   = UDim2.new(1, -82, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font   = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextColor3 = T.TextDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ttl

        local kBtn = Instance.new("TextButton", row)
        kBtn.Size  = UDim2.fromOffset(74, 20)
        kBtn.Position = UDim2.new(1, -74, 0.5, -10)
        kBtn.BackgroundColor3 = T.Element; kBtn.BorderSizePixel = 0
        kBtn.Font  = Enum.Font.GothamMedium; kBtn.TextSize = 10
        kBtn.TextColor3 = T.TextDim; kBtn.Text = "[" .. defK.Name .. "]"
        kBtn.AutoButtonColor = false
        Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0, 4)
        local kStroke = Instance.new("UIStroke", kBtn)
        kStroke.Color = T.Border; kStroke.Thickness = 1

        if flag then self._lib.Flags[flag] = defK end

        kBtn.MouseButton1Click:Connect(function()
            if Kb.Listening then return end
            Kb.Listening = true; self._lib._listeningForKey = true
            kBtn.Text = "[...]"; tw(kStroke, 0.15, {Color = self._lib.T.Accent})
            local conn
            conn = UserInputService.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    local k = i.KeyCode == Enum.KeyCode.Backspace and Enum.KeyCode.None or i.KeyCode
                    Kb.Key = k; kBtn.Text = "[" .. k.Name .. "]"
                    Kb.Listening = false; self._lib._listeningForKey = false
                    tw(kStroke, 0.15, {Color = T.Border}); conn:Disconnect()
                    if flag then self._lib.Flags[flag] = k end
                    pcall(cb, k)
                end
            end)
            table.insert(self._lib._extraConns, conn)
        end)

        function Kb:Set(k)
            Kb.Key = k; kBtn.Text = "[" .. k.Name .. "]"
            if flag then self._lib.Flags[flag] = k end
        end
        Kb._lib = self._lib

        if cfg.ConfigKey then
            self._lib:_regCfg(cfg.ConfigKey,
                function() return Kb.Key.Name end,
                function(v)
                    local ok, k = pcall(function() return Enum.KeyCode[v] end)
                    if ok and k then Kb:Set(k) end
                end)
        end

        return Kb
    end

    -- ────────────────────────────────────────────
    -- COLORPICKER (HSV)
    -- ────────────────────────────────────────────
    function Section:CreateColorPicker(cfg)
        cfg        = cfg or {}
        local ttl  = cfg.Title    or "Color"
        local flag = cfg.Flag     or nil
        local defC = cfg.Default  or c3rgb(255, 100, 100)
        local cb   = cfg.Callback or function() end

        local h0, s0, v0 = Color3.toHSV(defC)
        local CH         = {hue = h0, sat = s0, val = v0}
        local CP         = {Color = defC, Opened = false}

        local container  = Instance.new("Frame", card)
        container.Name   = "Row_CP_" .. ttl
        container.Size   = UDim2.new(1, 0, 0, 24)
        container.BackgroundTransparency = 1
        container.ClipsDescendants = true
        container.LayoutOrder = nextOrder()

        local hdr = Instance.new("TextButton", container)
        hdr.Size  = UDim2.new(1, 0, 0, 24)
        hdr.BackgroundTransparency = 1; hdr.Text = ""; hdr.AutoButtonColor = false

        local lbl = Instance.new("TextLabel", hdr)
        lbl.Size  = UDim2.new(1, -42, 1, 0); lbl.BackgroundTransparency = 1
        lbl.Font  = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = T.TextDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = ttl

        local preview = Instance.new("Frame", hdr)
        preview.Size  = UDim2.fromOffset(28, 16); preview.Position = UDim2.new(1, -32, 0.5, -8)
        preview.BackgroundColor3 = defC; preview.BorderSizePixel = 0
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 3)
        local prevStroke = Instance.new("UIStroke", preview)
        prevStroke.Color = T.BorderLight; prevStroke.Thickness = 1

        local hexLbl = Instance.new("TextLabel", hdr)
        hexLbl.Size  = UDim2.fromOffset(60, 24); hexLbl.Position = UDim2.new(1, -100, 0, 0)
        hexLbl.BackgroundTransparency = 1; hexLbl.Font = Enum.Font.Gotham; hexLbl.TextSize = 10
        hexLbl.TextColor3 = T.TextMute; hexLbl.TextXAlignment = Enum.TextXAlignment.Right
        hexLbl.Text = "#" .. defC:ToHex():upper()

        local PANEL_H    = 130
        local panel      = Instance.new("Frame", container)
        panel.Size       = UDim2.new(1, 0, 0, PANEL_H)
        panel.Position   = UDim2.fromOffset(0, 26)
        panel.BackgroundColor3 = T.Element; panel.BorderSizePixel = 0; panel.Visible = false
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 4)
        local panStroke  = Instance.new("UIStroke", panel)
        panStroke.Color  = T.Border; panStroke.Thickness = 1
        local panPad     = Instance.new("UIPadding", panel)
        panPad.PaddingLeft=UDim.new(0,6); panPad.PaddingRight=UDim.new(0,6)
        panPad.PaddingTop=UDim.new(0,6); panPad.PaddingBottom=UDim.new(0,6)

        local SV_SIZE    = 98

        -- SV square
        local svFrame    = Instance.new("TextButton", panel)
        svFrame.Name     = "SV"
        svFrame.Size     = UDim2.fromOffset(SV_SIZE, SV_SIZE)
        svFrame.BackgroundColor3 = hsvToColor3(h0, 1, 1)
        svFrame.BorderSizePixel  = 0; svFrame.Text = ""; svFrame.AutoButtonColor = false
        Instance.new("UICorner", svFrame).CornerRadius = UDim.new(0, 3)

        -- White (saturation) gradient
        local gWhite     = Instance.new("UIGradient", svFrame)
        gWhite.Color     = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1))
        gWhite.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })

        -- Black (value) overlay
        local blackOverlay = Instance.new("Frame", svFrame)
        blackOverlay.Size  = UDim2.new(1, 0, 1, 0)
        blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0); blackOverlay.BorderSizePixel = 0
        Instance.new("UICorner", blackOverlay).CornerRadius = UDim.new(0, 3)
        local gBlack     = Instance.new("UIGradient", blackOverlay)
        gBlack.Color     = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
        gBlack.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        gBlack.Rotation  = 90

        -- SV cursor dot
        local svCursor   = Instance.new("Frame", svFrame)
        svCursor.Size    = UDim2.fromOffset(8, 8)
        svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        svCursor.Position = UDim2.new(s0, 0, 1 - v0, 0)
        svCursor.BackgroundColor3 = Color3.new(1, 1, 1); svCursor.BorderSizePixel = 0; svCursor.ZIndex = 5
        Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)
        local svCursorStroke = Instance.new("UIStroke", svCursor)
        svCursorStroke.Color = Color3.new(0, 0, 0); svCursorStroke.Thickness = 1

        -- Hue bar
        local hueBar     = Instance.new("TextButton", panel)
        hueBar.Name      = "HueBar"
        hueBar.Size      = UDim2.new(1, -(SV_SIZE + 8), 0, SV_SIZE)
        hueBar.Position  = UDim2.fromOffset(SV_SIZE + 8, 0)
        hueBar.BackgroundColor3 = Color3.new(1, 1, 1); hueBar.BorderSizePixel = 0
        hueBar.Text      = ""; hueBar.AutoButtonColor = false
        Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 3)

        local hueGrad    = Instance.new("UIGradient", hueBar)
        hueGrad.Rotation = 90
        local hueKps     = {}
        for i = 0, 6 do
            hueKps[i+1] = ColorSequenceKeypoint.new(i/6, hsvToColor3(i/6, 1, 1))
        end
        hueGrad.Color    = ColorSequence.new(hueKps)

        local hueCursor  = Instance.new("Frame", hueBar)
        hueCursor.Size   = UDim2.new(1, 4, 0, 4)
        hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        hueCursor.Position = UDim2.new(0.5, 0, h0, 0)
        hueCursor.BackgroundColor3 = Color3.new(1, 1, 1); hueCursor.BorderSizePixel = 0; hueCursor.ZIndex = 5
        Instance.new("UICorner", hueCursor).CornerRadius = UDim.new(0, 2)
        local hueCursorStroke = Instance.new("UIStroke", hueCursor)
        hueCursorStroke.Color = Color3.new(0, 0, 0); hueCursorStroke.Thickness = 1

        -- Hex input row
        local hexRow     = Instance.new("Frame", panel)
        hexRow.Size      = UDim2.new(1, 0, 0, 20)
        hexRow.Position  = UDim2.fromOffset(0, SV_SIZE + 6)
        hexRow.BackgroundTransparency = 1

        local hexInputF  = Instance.new("Frame", hexRow)
        hexInputF.Size   = UDim2.new(1, 0, 1, 0)
        hexInputF.BackgroundColor3 = T.Card; hexInputF.BorderSizePixel = 0
        Instance.new("UICorner", hexInputF).CornerRadius = UDim.new(0, 3)
        local hexStroke  = Instance.new("UIStroke", hexInputF)
        hexStroke.Color  = T.Border; hexStroke.Thickness = 1

        local hexInput   = Instance.new("TextBox", hexInputF)
        hexInput.Size    = UDim2.new(1, -8, 1, 0); hexInput.Position = UDim2.fromOffset(4, 0)
        hexInput.BackgroundTransparency = 1; hexInput.Font = Enum.Font.Gotham; hexInput.TextSize = 10
        hexInput.TextColor3 = T.Text; hexInput.PlaceholderColor3 = T.TextMute
        hexInput.PlaceholderText = "#RRGGBB"
        hexInput.Text    = "#" .. defC:ToHex():upper()
        hexInput.ClearTextOnFocus = false

        if flag then self._lib.Flags[flag] = defC end

        local function applyHSV()
            local col = hsvToColor3(CH.hue, CH.sat, CH.val)
            CP.Color  = col
            preview.BackgroundColor3 = col
            hexLbl.Text  = "#" .. col:ToHex():upper()
            hexInput.Text = "#" .. col:ToHex():upper()
            svFrame.BackgroundColor3 = hsvToColor3(CH.hue, 1, 1)
            svCursor.Position  = UDim2.new(CH.sat, 0, 1 - CH.val, 0)
            hueCursor.Position = UDim2.new(0.5, 0, CH.hue, 0)
            if flag then self._lib.Flags[flag] = col end
            pcall(cb, col)
        end

        -- SV drag
        local svDrag = false
        svFrame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                svDrag = true
                CH.sat = clamp((i.Position.X - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1)
                CH.val = 1 - clamp((i.Position.Y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1)
                applyHSV()
            end
        end)
        local sC1 = UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then svDrag = false end
        end)
        local sC2 = UserInputService.InputChanged:Connect(function(i)
            if svDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                CH.sat = clamp((i.Position.X - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1)
                CH.val = 1 - clamp((i.Position.Y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1)
                applyHSV()
            end
        end)
        table.insert(self._lib._extraConns, sC1); table.insert(self._lib._extraConns, sC2)

        -- Hue drag
        local hueDrag = false
        hueBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                hueDrag = true
                CH.hue = clamp((i.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                applyHSV()
            end
        end)
        local hC1 = UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then hueDrag = false end
        end)
        local hC2 = UserInputService.InputChanged:Connect(function(i)
            if hueDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                CH.hue = clamp((i.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                applyHSV()
            end
        end)
        table.insert(self._lib._extraConns, hC1); table.insert(self._lib._extraConns, hC2)

        -- Hex input
        hexInput.Focused:Connect(function()  tw(hexStroke, 0.15, {Color = self._lib.T.Accent}) end)
        hexInput.FocusLost:Connect(function()
            tw(hexStroke, 0.15, {Color = T.Border})
            local txt = hexInput.Text:gsub("#", "")
            if #txt == 6 then
                local ok, col = pcall(function() return Color3.fromHex(txt) end)
                if ok and col then
                    CH.hue, CH.sat, CH.val = Color3.toHSV(col)
                    applyHSV()
                end
            end
        end)

        function CP:Toggle()
            CP.Opened = not CP.Opened
            panel.Visible = CP.Opened
            container.Size = UDim2.new(1, 0, 0, CP.Opened and (26 + PANEL_H) or 24)
        end

        function CP:Set(col)
            CP.Color = col
            CH.hue, CH.sat, CH.val = Color3.toHSV(col)
            applyHSV()
        end

        hdr.MouseButton1Click:Connect(function() CP:Toggle() end)
        CP._lib = self._lib

        if cfg.ConfigKey then
            self._lib:_regCfg(cfg.ConfigKey,
                function() return CP.Color:ToHex() end,
                function(v)
                    local ok, col = pcall(function() return Color3.fromHex(v) end)
                    if ok and col then CP:Set(col) end
                end)
        end

        return CP
    end

    -- ────────────────────────────────────────────
    -- BUTTON
    -- ────────────────────────────────────────────
    function Section:CreateButton(cfg)
        cfg        = cfg or {}
        local ttl  = cfg.Title    or "Button"
        local cb   = cfg.Callback or function() end
        local desc = cfg.Desc     or ""

        local btn  = Instance.new("TextButton", card)
        btn.Name   = "Row_Btn_" .. ttl
        btn.Size   = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = T.Element; btn.BorderSizePixel = 0
        btn.Font   = Enum.Font.GothamMedium; btn.TextSize = 12
        btn.TextColor3 = T.Text; btn.Text = ttl
        btn.AutoButtonColor = false; btn.ClipsDescendants = true
        btn.LayoutOrder = nextOrder()
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); bevel(btn)
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = T.Border; bStroke.Thickness = 1

        if desc ~= "" then
            local descLbl = Instance.new("TextLabel", btn)
            descLbl.Size  = UDim2.new(1, -8, 1, 0); descLbl.Position = UDim2.fromOffset(4, 0)
            descLbl.BackgroundTransparency = 1; descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 10
            descLbl.TextColor3 = T.TextMute; descLbl.TextXAlignment = Enum.TextXAlignment.Right
            descLbl.Text = desc
        end

        btn.MouseEnter:Connect(function()  tw(btn, 0.12, {BackgroundColor3 = T.ElementHov}) end)
        btn.MouseLeave:Connect(function()  tw(btn, 0.12, {BackgroundColor3 = T.Element}) end)
        btn.MouseButton1Down:Connect(function()
            tw(btn, 0.08, {BackgroundColor3 = self._lib.T.Accent, TextColor3 = self._lib.T.Black})
            ripple(btn, self._lib.T.Accent)
        end)
        btn.MouseButton1Up:Connect(function() tw(btn, 0.18, {BackgroundColor3 = T.Element, TextColor3 = T.Text}) end)
        btn.MouseButton1Click:Connect(function() pcall(cb) end)

        return btn
    end

    -- ────────────────────────────────────────────
    -- LABEL
    -- ────────────────────────────────────────────
    function Section:CreateLabel(text, col, richText)
        local lbl  = Instance.new("TextLabel", card)
        lbl.Name   = "Label"
        lbl.Size   = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.BackgroundTransparency = 1
        lbl.Font   = Enum.Font.Gotham; lbl.TextSize = 11
        lbl.TextColor3 = col or T.TextDim
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true; lbl.RichText = richText or false
        lbl.Text   = text; lbl.LayoutOrder = nextOrder()
        function lbl:SetText(t)  lbl.Text = t end
        function lbl:SetColor(c) lbl.TextColor3 = c end
        return lbl
    end

    -- ────────────────────────────────────────────
    -- SEPARATOR
    -- ────────────────────────────────────────────
    function Section:CreateSeparator(label)
        if label and label ~= "" then
            local row  = Instance.new("Frame", card)
            row.Name   = "Sep_" .. label; row.Size = UDim2.new(1, 0, 0, 14)
            row.BackgroundTransparency = 1; row.LayoutOrder = nextOrder()
            local line = Instance.new("Frame", row)
            line.Size  = UDim2.new(1, 0, 0, 1); line.Position = UDim2.new(0, 0, 0.5, 0)
            line.BackgroundColor3 = T.Border; line.BorderSizePixel = 0
            local sepLbl = Instance.new("TextLabel", row)
            sepLbl.Size  = UDim2.fromOffset(0, 14)
            sepLbl.AutomaticSize = Enum.AutomaticSize.X
            sepLbl.AnchorPoint   = Vector2.new(0.5, 0); sepLbl.Position = UDim2.new(0.5, 0, 0, 0)
            sepLbl.BackgroundColor3 = T.Card; sepLbl.BorderSizePixel = 0
            local sP = Instance.new("UIPadding", sepLbl)
            sP.PaddingLeft = UDim.new(0, 6); sP.PaddingRight = UDim.new(0, 6)
            sepLbl.Font  = Enum.Font.Gotham; sepLbl.TextSize = 9
            sepLbl.TextColor3 = T.TextMute; sepLbl.Text = label
        else
            local sep  = Instance.new("Frame", card)
            sep.Name   = "Sep"; sep.Size = UDim2.new(1, 0, 0, 1)
            sep.BackgroundColor3 = T.Border; sep.BorderSizePixel = 0
            sep.LayoutOrder = nextOrder()
        end
    end

    return Section
end

-- ══════════════════════════════════════════════════════════════════════
-- § 8  CONFIG
-- ══════════════════════════════════════════════════════════════════════
function Library:_regCfg(key, getter, setter)
    if self._configElems[key] then warn("[HutameLib] Duplicate ConfigKey: " .. key); return end
    self._configElems[key] = {get = getter, set = setter}
end

function Library:SaveConfig(name)
    name = (name or "default"):gsub("[^%w_%-]", "_")
    local data = {}
    for k, elem in pairs(self._configElems) do
        local ok, v = pcall(elem.get)
        if ok then data[k] = v end
    end
    local ok, err = pcall(writefile, "HutameLib_" .. name .. ".json", HttpService:JSONEncode(data))
    if ok then
        self:Notify({Title = "✓ Saved", Text = "HutameLib_" .. name .. ".json", Type = "success", Duration = 2.5})
    else
        self:Notify({Title = "Config Error", Text = tostring(err), Type = "error", Duration = 3})
    end
end

function Library:LoadConfig(name)
    name = (name or "default"):gsub("[^%w_%-]", "_")
    local fname = "HutameLib_" .. name .. ".json"
    local ok, content = pcall(readfile, fname)
    if not ok then self:Notify({Title = "Config Error", Text = fname .. " not found.", Type = "error", Duration = 3}); return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or type(data) ~= "table" then self:Notify({Title = "Config Error", Text = "Bad format.", Type = "error", Duration = 3}); return end
    local loaded = 0
    for k, elem in pairs(self._configElems) do
        if data[k] ~= nil then
            if pcall(elem.set, data[k]) then loaded = loaded + 1 end
        end
    end
    self:Notify({Title = "✓ Loaded", Text = loaded .. " values restored.", Type = "success", Duration = 2.5})
end

function Library:ListConfigs()
    local results = {}
    if type(listfiles) == "function" then
        local ok, files = pcall(listfiles, "")
        if ok then
            for _, f in ipairs(files) do
                local n = f:match("^HutameLib_(.+)%.json$")
                if n then table.insert(results, n) end
            end
        end
    end
    return results
end

-- ══════════════════════════════════════════════════════════════════════
-- § 9  NOTIFICATION
-- ══════════════════════════════════════════════════════════════════════
function Library:_ensureNotifyHolder()
    if self._notifyHolder then return end
    local holder = Instance.new("Frame", self.ScreenGui)
    holder.Name  = "NotifyHolder"
    holder.Size  = UDim2.fromOffset(268, 700)
    holder.Position = UDim2.new(1, -276, 1, -12)
    holder.AnchorPoint = Vector2.new(0, 1)
    holder.BackgroundTransparency = 1; holder.BorderSizePixel = 0
    local hl = Instance.new("UIListLayout", holder)
    hl.SortOrder = Enum.SortOrder.LayoutOrder
    hl.VerticalAlignment = Enum.VerticalAlignment.Bottom
    hl.Padding = UDim.new(0, 6)
    self._notifyHolder = holder
end

function Library:Notify(cfg)
    self:_ensureNotifyHolder()
    cfg = cfg or {}
    local title    = cfg.Title    or "Notification"
    local text     = cfg.Text     or ""
    local duration = cfg.Duration or 3
    local ntype    = cfg.Type     or "info"
    local T        = self.T

    local typeData = {
        info    = {col = self.T.Accent,         icon = "ℹ"},
        success = {col = c3rgb(46, 200, 100),   icon = "✓"},
        error   = {col = c3rgb(220, 48, 56),    icon = "✕"},
        warning = {col = c3rgb(240, 162, 26),   icon = "⚠"},
    }
    local td      = typeData[ntype] or typeData.info
    local TOAST_H = text ~= "" and 56 or 36

    local toast   = Instance.new("Frame", self._notifyHolder)
    toast.Name    = "Toast"
    toast.Size    = UDim2.fromOffset(0, TOAST_H)
    toast.BackgroundColor3 = T.Card; toast.BorderSizePixel = 0
    toast.ClipsDescendants = true; toast.LayoutOrder = os.clock() * 1000
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 6)
    local tStroke = Instance.new("UIStroke", toast)
    tStroke.Color = T.Border; tStroke.Thickness = 1

    local acBar   = Instance.new("Frame", toast)
    acBar.Size    = UDim2.new(0, 3, 1, 0); acBar.BackgroundColor3 = td.col; acBar.BorderSizePixel = 0
    Instance.new("UICorner", acBar).CornerRadius = UDim.new(0, 3)

    local iconLbl = Instance.new("TextLabel", toast)
    iconLbl.Size  = UDim2.fromOffset(22, TOAST_H); iconLbl.Position = UDim2.fromOffset(8, 0)
    iconLbl.BackgroundTransparency = 1; iconLbl.Font = Enum.Font.GothamBold; iconLbl.TextSize = 14
    iconLbl.TextColor3 = td.col; iconLbl.Text = td.icon

    local titleLbl = Instance.new("TextLabel", toast)
    titleLbl.Size  = UDim2.new(1, -56, 0, TOAST_H); titleLbl.Position = UDim2.fromOffset(32, 0)
    titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.GothamMedium; titleLbl.TextSize = 12
    titleLbl.TextColor3 = T.Text; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Text = title

    if text ~= "" then
        titleLbl.Size = UDim2.new(1, -56, 0, 22)
        local bodyLbl = Instance.new("TextLabel", toast)
        bodyLbl.Size  = UDim2.new(1, -56, 0, 18); bodyLbl.Position = UDim2.fromOffset(32, 22)
        bodyLbl.BackgroundTransparency = 1; bodyLbl.Font = Enum.Font.Gotham; bodyLbl.TextSize = 10
        bodyLbl.TextColor3 = T.TextDim; bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
        bodyLbl.TextTruncate = Enum.TextTruncate.AtEnd; bodyLbl.Text = text
    end

    local closeBtn = Instance.new("TextButton", toast)
    closeBtn.Size  = UDim2.fromOffset(18, 18); closeBtn.Position = UDim2.new(1, -22, 0, 9)
    closeBtn.BackgroundTransparency = 1; closeBtn.Font = Enum.Font.Gotham; closeBtn.TextSize = 10
    closeBtn.TextColor3 = T.TextMute; closeBtn.Text = "✕"; closeBtn.AutoButtonColor = false
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = T.Text end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = T.TextMute end)

    local prog    = Instance.new("Frame", toast)
    prog.Size     = UDim2.new(1, 0, 0, 2); prog.Position = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3 = td.col; prog.BackgroundTransparency = 0.4; prog.BorderSizePixel = 0

    tw(toast, 0.28, {Size = UDim2.fromOffset(266, TOAST_H)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tw(prog,  duration, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed then return end; dismissed = true
        tw(toast, 0.2, {Size = UDim2.fromOffset(266, 0), BackgroundTransparency = 1})
        task.delay(0.25, function()
            if toast and toast.Parent then toast:Destroy() end
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    task.delay(duration, function()
        if toast and toast.Parent then dismiss() end
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- § 10  WATERMARK
-- ══════════════════════════════════════════════════════════════════════
function Library:SetWatermark(cfg)
    cfg = cfg or {}
    local fmt     = cfg.Format   or "{player}  |  {fps} fps  |  {ping} ms"
    local pos     = cfg.Position or "TopRight"
    local bgAlpha = cfg.BgAlpha  or 0.5

    self:RemoveWatermark()

    local T    = self.T
    local wm   = Instance.new("Frame", self.ScreenGui)
    wm.Name    = "Watermark"
    wm.Size    = UDim2.fromOffset(0, 24); wm.AutomaticSize = Enum.AutomaticSize.X
    wm.BackgroundColor3 = T.Surface; wm.BackgroundTransparency = bgAlpha
    wm.BorderSizePixel  = 0; wm.ZIndex = 50
    Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 4)
    local wmStroke = Instance.new("UIStroke", wm)
    wmStroke.Color = T.Border; wmStroke.Thickness = 1
    self:_onAccent(function(c) wmStroke.Color = c end)
    local wmPad = Instance.new("UIPadding", wm)
    wmPad.PaddingLeft = UDim.new(0, 10); wmPad.PaddingRight = UDim.new(0, 10)

    local posMap = {
        TopLeft     = {UDim2.fromOffset(10, 10),     Vector2.new(0, 0)},
        TopRight    = {UDim2.new(1, -10, 0, 10),     Vector2.new(1, 0)},
        BottomLeft  = {UDim2.new(0, 10, 1, -10),     Vector2.new(0, 1)},
        BottomRight = {UDim2.new(1, -10, 1, -10),    Vector2.new(1, 1)},
    }
    local pd = posMap[pos] or posMap.TopRight
    wm.Position = pd[1]; wm.AnchorPoint = pd[2]

    local lbl  = Instance.new("TextLabel", wm)
    lbl.Size   = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font   = Enum.Font.GothamMedium; lbl.TextSize = 11; lbl.TextColor3 = T.Text
    lbl.RichText = true; lbl.AutomaticSize = Enum.AutomaticSize.X; lbl.Text = fmt

    local fps, lastT, frames = 60, os.clock(), 0
    local fpsC = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastT >= 0.5 then
            fps = floor(frames / (now - lastT) + 0.5)
            frames = 0; lastT = now
        end
    end)

    local function getPing()
        local ok, v = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        return ok and floor(v) or 0
    end

    local wmConn = RunService.Heartbeat:Connect(function()
        if not wm or not wm.Parent then return end
        local now = os.clock()
        local h   = floor(now / 3600 % 24)
        local m   = floor(now / 60 % 60)
        local s   = floor(now % 60)
        local fpsHex = fps >= 50 and "7bdd8b" or fps >= 30 and "f5c542" or "ff7472"
        lbl.Text = (self._wmFmt or fmt)
            :gsub("{player}", LocalPlayer.Name)
            :gsub("{fps}",    string.format('<font color="#%s">%d</font>', fpsHex, fps))
            :gsub("{ping}",   tostring(getPing()))
            :gsub("{time}",   string.format("%02d:%02d:%02d", h, m, s))
            :gsub("{game}",   tostring(game.Name))
    end)

    self._wmFrame = wm; self._wmFmt = fmt
    self._wmConn  = wmConn; self._wmFpsC = fpsC
end

function Library:UpdateWatermark(newFmt) self._wmFmt = newFmt end

function Library:RemoveWatermark()
    if self._wmFrame then self._wmFrame:Destroy(); self._wmFrame = nil end
    if self._wmConn  then self._wmConn:Disconnect();  self._wmConn  = nil end
    if self._wmFpsC  then self._wmFpsC:Disconnect();  self._wmFpsC  = nil end
end

-- ══════════════════════════════════════════════════════════════════════
-- § 11  DESTROY
-- ══════════════════════════════════════════════════════════════════════
function Library:Destroy()
    self:RemoveWatermark()
    for _, c in ipairs(self._extraConns) do pcall(function() c:Disconnect() end) end
    self._extraConns = {}
    if self.ScreenGui then self.ScreenGui:Destroy(); self.ScreenGui = nil end
end

-- ══════════════════════════════════════════════════════════════════════
-- § 12  RETURN
-- ══════════════════════════════════════════════════════════════════════
return Library


--[[
========================================================================
  HUTAME LIBRARY v3.0 — KULLANIM ÖRNEĞİ
  (Bu bloğu ayrı bir script olarak çalıştırın)
========================================================================

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"
))()

-- 1. Pencere
local Hub = Library.new({
    Title      = "MyHub",
    Version    = "v1.0.0",
    Theme      = "Midnight",   -- Midnight | Ocean | Crimson | Emerald | Sakura
    Accent     = Color3.fromRGB(138, 82, 226),
    ToggleKey  = Enum.KeyCode.RightControl,
})

-- 2. Watermark
Hub:SetWatermark({
    Format   = "MyHub  |  {player}  |  {fps} fps  |  {ping} ms",
    Position = "TopRight",
})

-- 3. Tab & Section
local CombatTab = Hub:CreateTab("⚔ Combat")
local VisualTab = Hub:CreateTab("👁 Visuals")

local AimbotSec = CombatTab:CreateSection("Aimbot",  "left")
local EspSec    = VisualTab:CreateSection("ESP",     "left")
local MiscSec   = VisualTab:CreateSection("Misc",    "right")

-- 4. Toggle
local aimToggle = AimbotSec:CreateToggle({
    Title     = "Enable Aimbot",
    Flag      = "AimbotEnabled",
    Default   = false,
    Keybind   = Enum.KeyCode.C,
    ConfigKey = "aimbot_enable",
    Callback  = function(val) print("Aimbot:", val) end,
})

-- 5. Slider
local fovSlider = AimbotSec:CreateSlider({
    Title     = "FOV",
    Flag      = "AimbotFOV",
    Min       = 10, Max = 360, Default = 90,
    Suffix    = "°",
    ConfigKey = "aimbot_fov",
    Callback  = function(val) print("FOV:", val) end,
})

-- 6. Dropdown
local boneDD = AimbotSec:CreateDropdown({
    Title     = "Target Bone",
    Flag      = "AimbotBone",
    Options   = {"Head", "Torso", "UpperTorso", "HumanoidRootPart"},
    Default   = "Head",
    ConfigKey = "aimbot_bone",
    Callback  = function(sel) print("Bone:", sel) end,
})

-- 7. MultiDropdown
local teamMDD = AimbotSec:CreateMultiDropdown({
    Title     = "Ignore Teams",
    Flag      = "IgnoreTeams",
    Options   = {"Red", "Blue", "Green", "Yellow"},
    Default   = {"Red"},
    ConfigKey = "ignore_teams",
    Callback  = function(sel) print("Ignored:", table.concat(sel, ", ")) end,
})

-- 8. Textbox
local filterTb = AimbotSec:CreateTextbox({
    Title       = "Username Filter",
    Flag        = "UsernameFilter",
    Placeholder = "Enter username...",
    ConfigKey   = "username_filter",
    Callback    = function(txt, enter) if enter then print("Filter:", txt) end end,
})

-- 9. Keybind
local aimKey = AimbotSec:CreateKeybind({
    Title     = "Aimbot Key",
    Flag      = "AimbotKey",
    Default   = Enum.KeyCode.Q,
    ConfigKey = "aimbot_key",
    Callback  = function(key) print("Key:", key.Name) end,
})

-- 10. ColorPicker (HSV!)
local espColor = EspSec:CreateColorPicker({
    Title     = "ESP Color",
    Flag      = "EspColor",
    Default   = Color3.fromRGB(255, 80, 80),
    ConfigKey = "esp_color",
    Callback  = function(col) print("Color:", col:ToHex()) end,
})

-- 11. Separator + Label
EspSec:CreateSeparator("Actions")
EspSec:CreateLabel("Double-click ESP Color to open the HSV picker.", nil, false)

-- 12. Button
EspSec:CreateButton({
    Title    = "Refresh ESP",
    Desc     = "Reloads all",
    Callback = function()
        Hub:Notify({Title = "ESP Refreshed", Type = "success", Duration = 2})
    end,
})

-- 13. Config
MiscSec:CreateButton({Title = "Save Config",  Callback = function() Hub:SaveConfig("myconfig") end})
MiscSec:CreateButton({Title = "Load Config",  Callback = function() Hub:LoadConfig("myconfig") end})

-- 14. Flags
-- Hub.Flags.AimbotEnabled  → boolean
-- Hub.Flags.AimbotFOV      → number
-- Hub.Flags.AimbotBone     → string
-- Hub.Flags.IgnoreTeams    → table
-- Hub.Flags.EspColor       → Color3

-- 15. Notifications
Hub:Notify({ Title = "Info",    Type = "info",    Duration = 3 })
Hub:Notify({ Title = "Success", Type = "success", Duration = 2 })
Hub:Notify({ Title = "Warning", Type = "warning", Duration = 4 })
Hub:Notify({ Title = "Error",   Type = "error",   Duration = 5 })

-- 16. Theme switching
Hub:SetTheme("Ocean")                          -- preset
Hub:SetTheme({Accent = Color3.fromRGB(255,200,0)}) -- partial custom

-- 17. Destroy
-- Hub:Destroy()
]]
