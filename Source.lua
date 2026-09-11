--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    HUTAME HUB LIBRARY                        ║
    ║      Private Hub Style · Two-Column · Compact · v2 UI        ║
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
local function tw(obj, t, props, style, dir)
    TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
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
    tw(rip, 0.4, {Size = UDim2.new(0,140,0,140), BackgroundTransparency = 1})
    game:GetService("Debris"):AddItem(rip, 0.45)
end

-- drop-shadow helper: 9-slice shadow image behind any frame
local SHADOW_ID = "rbxassetid://5554236805"
local function addShadow(parent, alpha, size)
    local shadow = Instance.new("ImageLabel")
    shadow.Name              = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image             = SHADOW_ID
    shadow.ImageColor3       = Color3.new(0,0,0)
    shadow.ImageTransparency = alpha or 0.45
    shadow.ScaleType         = Enum.ScaleType.Slice
    shadow.SliceCenter       = Rect.new(23,23,277,277)
    shadow.Size              = UDim2.new(1, size or 34, 1, size or 34)
    shadow.Position          = UDim2.new(0.5,0,0.5,0)
    shadow.AnchorPoint       = Vector2.new(0.5,0.5)
    shadow.ZIndex            = (parent.ZIndex or 1) - 1
    shadow.Parent            = parent
    return shadow
end

-- ─────────────────────────────────────────────
-- Theme
-- ─────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(15, 15, 17),    -- window bg
    Surface     = Color3.fromRGB(20, 20, 23),    -- topbar / tab bar
    Card        = Color3.fromRGB(24, 24, 27),    -- section card
    Element     = Color3.fromRGB(30, 30, 34),    -- element bg
    ElementHov  = Color3.fromRGB(38, 38, 43),    -- hover
    Border      = Color3.fromRGB(40, 40, 45),
    BorderLight = Color3.fromRGB(58, 58, 64),    -- active tab underline
    Text        = Color3.fromRGB(230, 230, 232), -- primary text
    TextDim     = Color3.fromRGB(150, 150, 156), -- secondary text
    TextMute    = Color3.fromRGB(92, 92, 98),    -- muted
    Accent      = Color3.fromRGB(220, 50, 50),   -- accent (changeable)
    AccentDim   = Color3.fromRGB(140, 30, 30),
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

    T.Accent    = self.Accent
    T.AccentDim = Color3.fromRGB(
        math.floor(self.Accent.R*255*0.55),
        math.floor(self.Accent.G*255*0.55),
        math.floor(self.Accent.B*255*0.55)
    )

    self:_build()

    -- ── Loading Screen / Splash ───────────────────────────────────────────
    if config.LoadingScreen ~= false then
        local splashTitle    = self.Title
        local splashSubtitle = self.Version
        local loadDur        = config.LoadingDuration or 1.6
        local sg             = self.ScreenGui
        local mf             = self.MainFrame

        local splash = Instance.new("Frame", sg)
        splash.Name             = "Splash"
        splash.Size             = UDim2.new(1,0,1,0)
        splash.BackgroundColor3 = T.BG
        splash.BorderSizePixel  = 0
        splash.ZIndex           = 100

        local lsCard = Instance.new("Frame", splash)
        lsCard.Size              = UDim2.fromOffset(300, 168)
        lsCard.Position          = UDim2.new(0.5,-150,0.5,-84)
        lsCard.BackgroundColor3  = T.Surface
        lsCard.BorderSizePixel   = 0
        lsCard.ZIndex            = 101
        Instance.new("UICorner", lsCard).CornerRadius = UDim.new(0,12)
        addShadow(lsCard, 0.55, 60).ZIndex = 100
        local lsStroke = Instance.new("UIStroke", lsCard)
        lsStroke.Color = T.Border; lsStroke.Thickness = 1; lsStroke.ZIndex = 101

        local lsAccent = Instance.new("Frame", lsCard)
        lsAccent.Size             = UDim2.new(1,0,0,3)
        lsAccent.BackgroundColor3 = self.Accent
        lsAccent.BorderSizePixel  = 0; lsAccent.ZIndex = 102
        Instance.new("UICorner", lsAccent).CornerRadius = UDim.new(0,12)
        self:_onAccent(function(c) lsAccent.BackgroundColor3 = c end)

        local lsLogo = Instance.new("Frame", lsCard)
        lsLogo.Size             = UDim2.fromOffset(40,40)
        lsLogo.Position         = UDim2.new(0.5,-20,0,26)
        lsLogo.BackgroundColor3 = self.Accent
        lsLogo.BorderSizePixel  = 0; lsLogo.ZIndex = 102
        Instance.new("UICorner", lsLogo).CornerRadius = UDim.new(0,10)
        self:_onAccent(function(c) lsLogo.BackgroundColor3 = c end)
        local lsLogoLbl = Instance.new("TextLabel", lsLogo)
        lsLogoLbl.Size=UDim2.new(1,0,1,0); lsLogoLbl.BackgroundTransparency=1
        lsLogoLbl.Font=Enum.Font.GothamBlack; lsLogoLbl.TextSize=19
        lsLogoLbl.TextColor3=T.Black; lsLogoLbl.Text=string.sub(splashTitle,1,1)
        lsLogoLbl.ZIndex=103

        local lsTitleLbl = Instance.new("TextLabel", lsCard)
        lsTitleLbl.Size=UDim2.new(1,0,0,20); lsTitleLbl.Position=UDim2.fromOffset(0,74)
        lsTitleLbl.BackgroundTransparency=1; lsTitleLbl.Font=Enum.Font.GothamBold
        lsTitleLbl.TextSize=16; lsTitleLbl.TextColor3=T.White
        lsTitleLbl.Text=splashTitle; lsTitleLbl.ZIndex=102

        local lsSubLbl = Instance.new("TextLabel", lsCard)
        lsSubLbl.Size=UDim2.new(1,0,0,16); lsSubLbl.Position=UDim2.fromOffset(0,96)
        lsSubLbl.BackgroundTransparency=1; lsSubLbl.Font=Enum.Font.Gotham
        lsSubLbl.TextSize=11; lsSubLbl.TextColor3=T.TextDim
        lsSubLbl.Text=splashSubtitle; lsSubLbl.ZIndex=102

        local lsTrack = Instance.new("Frame", lsCard)
        lsTrack.Size=UDim2.new(1,-48,0,4); lsTrack.Position=UDim2.new(0,24,1,-24)
        lsTrack.BackgroundColor3=T.Element; lsTrack.BorderSizePixel=0; lsTrack.ZIndex=102
        Instance.new("UICorner", lsTrack).CornerRadius = UDim.new(1,0)

        local lsFill = Instance.new("Frame", lsTrack)
        lsFill.Size=UDim2.new(0,0,1,0); lsFill.BackgroundColor3=self.Accent
        lsFill.BorderSizePixel=0; lsFill.ZIndex=103
        Instance.new("UICorner", lsFill).CornerRadius = UDim.new(1,0)
        self:_onAccent(function(c) lsFill.BackgroundColor3 = c end)

        local lsStatus = Instance.new("TextLabel", lsCard)
        lsStatus.Size=UDim2.new(1,0,0,12); lsStatus.Position=UDim2.new(0,0,1,-42)
        lsStatus.BackgroundTransparency=1; lsStatus.Font=Enum.Font.Gotham
        lsStatus.TextSize=10; lsStatus.TextColor3=T.TextMute
        lsStatus.Text="Loading..."; lsStatus.ZIndex=102

        mf.Visible = false

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
            for _, d in ipairs(splash:GetDescendants()) do
                if d:IsA("TextLabel") then tw(d, 0.35, {TextTransparency=1}) end
                if d:IsA("Frame") or d:IsA("ImageLabel") then pcall(function() tw(d,0.35,{BackgroundTransparency=1, ImageTransparency=1}) end) end
            end
            tw(splash, 0.35, {BackgroundTransparency=1})
            task.wait(0.4)
            splash:Destroy()
            mf.Visible = true
            mf.Size = UDim2.fromOffset(mf.Size.X.Offset, mf.Size.Y.Offset - 8)
            tw(mf, 0.28, {Size = UDim2.fromOffset(700, 460)}, Enum.EasingStyle.Back)
        end)
    end

    return self
end

function Library:_onAccent(fn) table.insert(self._accentSubs, fn) end
function Library:SetAccent(col)
    self.Accent = col
    T.Accent    = col
    T.AccentDim = Color3.fromRGB(
        math.floor(col.R*255*0.55),
        math.floor(col.G*255*0.55),
        math.floor(col.B*255*0.55)
    )
    for _, fn in ipairs(self._accentSubs) do pcall(fn, col) end
end

function Library:_build()
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
    Instance.new("UICorner", mf).CornerRadius = UDim.new(0,10)
    addShadow(mf, 0.4, 70)
    local mfStroke = Instance.new("UIStroke", mf)
    mfStroke.Color     = T.Border
    mfStroke.Thickness = 1
    self.MainFrame = mf

    -- ── Topbar ──────────────────────────────────
    local topbar = Instance.new("Frame", mf)
    topbar.Name            = "Topbar"
    topbar.Size            = UDim2.new(1,0,0,44)
    topbar.Position        = UDim2.fromOffset(0,0)
    topbar.BackgroundColor3= T.Surface
    topbar.BorderSizePixel = 0
    topbar.ZIndex          = 3
    local tbCorner = Instance.new("UICorner", topbar)
    tbCorner.CornerRadius = UDim.new(0,10)
    local tbMask = Instance.new("Frame", topbar) -- squares off the bottom corners
    tbMask.Size = UDim2.new(1,0,0,10)
    tbMask.Position = UDim2.new(0,0,1,-10)
    tbMask.BackgroundColor3 = T.Surface
    tbMask.BorderSizePixel = 0
    tbMask.ZIndex = 3

    -- accent glow strip under topbar
    local acLine = Instance.new("Frame", mf)
    acLine.Name             = "AccentLine"
    acLine.Size             = UDim2.new(1,0,0,2)
    acLine.Position         = UDim2.fromOffset(0,44)
    acLine.BackgroundColor3 = self.Accent
    acLine.BorderSizePixel  = 0
    acLine.ZIndex           = 4
    self:_onAccent(function(c) acLine.BackgroundColor3 = c end)

    -- logo chip
    local logoChip = Instance.new("Frame", topbar)
    logoChip.Size             = UDim2.fromOffset(26,26)
    logoChip.Position         = UDim2.fromOffset(10,9)
    logoChip.BackgroundColor3 = self.Accent
    logoChip.BorderSizePixel  = 0
    Instance.new("UICorner", logoChip).CornerRadius = UDim.new(0,7)
    self:_onAccent(function(c) logoChip.BackgroundColor3 = c end)
    local logoLbl = Instance.new("TextLabel", logoChip)
    logoLbl.Size = UDim2.new(1,0,1,0); logoLbl.BackgroundTransparency = 1
    logoLbl.Font = Enum.Font.GothamBlack; logoLbl.TextSize = 13
    logoLbl.TextColor3 = T.Black; logoLbl.Text = string.sub(self.Title,1,1)

    -- brand
    local brand = Instance.new("TextLabel", topbar)
    brand.Size               = UDim2.new(0,220,0,16)
    brand.Position           = UDim2.fromOffset(44,7)
    brand.BackgroundTransparency = 1
    brand.Font               = Enum.Font.GothamBold
    brand.TextSize           = 14
    brand.TextColor3         = T.White
    brand.TextXAlignment     = Enum.TextXAlignment.Left
    brand.Text               = self.Title

    local brandSub = Instance.new("TextLabel", topbar)
    brandSub.Size               = UDim2.new(0,220,0,14)
    brandSub.Position           = UDim2.fromOffset(44,23)
    brandSub.BackgroundTransparency = 1
    brandSub.Font               = Enum.Font.Gotham
    brandSub.TextSize           = 10
    brandSub.TextColor3         = T.TextMute
    brandSub.TextXAlignment     = Enum.TextXAlignment.Left
    brandSub.Text               = self.Version .. " · " .. LocalPlayer.Name

    -- right side controls
    local ctrlHolder = Instance.new("Frame", topbar)
    ctrlHolder.Name                = "CtrlHolder"
    ctrlHolder.Size                = UDim2.fromOffset(64, 44)
    ctrlHolder.Position            = UDim2.new(1, -64, 0, 0)
    ctrlHolder.BackgroundTransparency = 1
    ctrlHolder.BorderSizePixel     = 0

    local function mkCtrl(char, xPos, hoverCol, onClick)
        local btn = Instance.new("TextButton", ctrlHolder)
        btn.Size               = UDim2.fromOffset(26, 26)
        btn.Position           = UDim2.new(0, xPos, 0.5, -13)
        btn.BackgroundColor3   = T.Element
        btn.BorderSizePixel    = 0
        btn.Font               = Enum.Font.GothamBold
        btn.TextSize           = 12
        btn.TextColor3         = T.TextDim
        btn.Text               = char
        btn.AutoButtonColor    = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
        btn.MouseEnter:Connect(function() tw(btn,0.15,{BackgroundColor3=hoverCol, TextColor3=T.White}) end)
        btn.MouseLeave:Connect(function() tw(btn,0.15,{BackgroundColor3=T.Element, TextColor3=T.TextDim}) end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end
    mkCtrl("—", 4,  T.ElementHov,              function() if self._body then self._body.Visible = not self._body.Visible end end)
    mkCtrl("✕", 34, Color3.fromRGB(210,45,45), function() self:Destroy() end)

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

    -- ── Tab Bar (pill-style) ─────────────────────
    local tabBar = Instance.new("Frame", mf)
    tabBar.Name            = "TabBar"
    tabBar.Size            = UDim2.new(1,-16,0,34)
    tabBar.Position        = UDim2.fromOffset(8,52)
    tabBar.BackgroundColor3= T.Surface
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex          = 3
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0,8)

    local tabList = Instance.new("Frame", tabBar)
    tabList.Name               = "TabList"
    tabList.Size               = UDim2.new(1,-8,1,0)
    tabList.Position           = UDim2.fromOffset(4,0)
    tabList.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabList)
    tabLayout.FillDirection    = Enum.FillDirection.Horizontal
    tabLayout.SortOrder        = Enum.SortOrder.LayoutOrder
    tabLayout.Padding          = UDim.new(0,4)
    tabLayout.VerticalAlignment= Enum.VerticalAlignment.Center
    self.TabBar  = tabBar
    self.TabList = tabList

    -- ── Body (content area below tabbar) ─────────
    local body = Instance.new("Frame", mf)
    body.Name            = "Body"
    body.Size            = UDim2.new(1,-16,1,-96)
    body.Position        = UDim2.fromOffset(8,94)
    body.BackgroundTransparency = 1
    body.ClipsDescendants = true
    self._body = body

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

    -- tab button (pill)
    local btn = Instance.new("TextButton", self.TabList)
    btn.Name               = "Tab_"..name
    btn.Size               = UDim2.new(0,0,1,-6)
    btn.Position            = UDim2.fromOffset(0,3)
    btn.AutomaticSize      = Enum.AutomaticSize.X
    btn.BackgroundColor3   = T.Element
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel    = 0
    btn.Font               = Enum.Font.GothamMedium
    btn.TextSize           = 12
    btn.TextColor3         = T.TextDim
    btn.Text               = "  "..name.."  "
    btn.AutoButtonColor    = false
    btn.ClipsDescendants   = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    self:_onAccent(function(c) if Tab.Active then btn.BackgroundColor3 = c end end)

    -- ── Tab Badge ──────────────────────────────
    local badge = Instance.new("Frame", btn)
    badge.Name              = "Badge"
    badge.Size              = UDim2.fromOffset(16, 16)
    badge.Position          = UDim2.new(1, -4, 0, -4)
    badge.AnchorPoint       = Vector2.new(0.5, 0.5)
    badge.BackgroundColor3  = T.Accent
    badge.BorderSizePixel   = 0
    badge.Visible           = false
    badge.ZIndex            = 10
    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
    local badgeLbl = Instance.new("TextLabel", badge)
    badgeLbl.Size                 = UDim2.new(1,0,1,0)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Font                 = Enum.Font.GothamBold
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

    local leftScroll = Instance.new("ScrollingFrame", page)
    leftScroll.Name                = "LeftCol"
    leftScroll.Size                = UDim2.new(0.5,-4,1,0)
    leftScroll.BackgroundTransparency = 1
    leftScroll.ScrollBarThickness  = 3
    leftScroll.ScrollBarImageColor3= T.BorderLight
    leftScroll.BorderSizePixel     = 0
    leftScroll.CanvasSize          = UDim2.new(0,0,0,0)
    leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local lLayout = Instance.new("UIListLayout", leftScroll)
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lLayout.Padding   = UDim.new(0,8)

    local rightScroll = Instance.new("ScrollingFrame", page)
    rightScroll.Name                = "RightCol"
    rightScroll.Size                = UDim2.new(0.5,-4,1,0)
    rightScroll.Position            = UDim2.new(0.5,8,0,0)
    rightScroll.BackgroundTransparency = 1
    rightScroll.ScrollBarThickness  = 3
    rightScroll.ScrollBarImageColor3= T.BorderLight
    rightScroll.BorderSizePixel     = 0
    rightScroll.CanvasSize          = UDim2.new(0,0,0,0)
    rightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local rLayout = Instance.new("UIListLayout", rightScroll)
    rLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rLayout.Padding   = UDim.new(0,8)

    -- ── Mobile Layout ─────────────────────────────
    local function applyMobileLayout(isMobile)
        if isMobile then
            leftScroll.Size     = UDim2.new(1,0,1,0)
            rightScroll.Visible = false
            for _, child in ipairs(rightScroll:GetChildren()) do
                if child:IsA("Frame") and child.Name:sub(1,4)=="Sec_" then
                    child.Parent = leftScroll
                end
            end
        else
            leftScroll.Size     = UDim2.new(0.5,-4,1,0)
            rightScroll.Visible = true
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
    Tab._checkMobile = checkMobile

    function Tab:Activate()
        for _, t in ipairs(self._lib.Tabs) do t:Deactivate() end
        Tab.Active     = true
        page.Visible   = true
        tw(btn, 0.18, {TextColor3 = T.Black, BackgroundTransparency = 0, BackgroundColor3 = self._lib.Accent})
        self._lib.ActiveTab = Tab
        Tab._checkMobile()
    end

    function Tab:Deactivate()
        Tab.Active   = false
        page.Visible = false
        tw(btn, 0.18, {TextColor3 = T.TextDim, BackgroundTransparency = 1})
    end

    btn.MouseButton1Click:Connect(function() Tab:Activate() end)
    btn.MouseEnter:Connect(function() if not Tab.Active then tw(btn,0.1,{TextColor3=T.Text, BackgroundTransparency=0.85, BackgroundColor3=T.Element}) end end)
    btn.MouseLeave:Connect(function() if not Tab.Active then tw(btn,0.1,{TextColor3=T.TextDim, BackgroundTransparency=1}) end end)

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then Tab:Activate() end

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
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color     = T.Border
    cardStroke.Thickness = 1
    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop    = UDim.new(0,10)
    pad.PaddingBottom = UDim.new(0,12)
    pad.PaddingLeft   = UDim.new(0,12)
    pad.PaddingRight  = UDim.new(0,12)
    local layout = Instance.new("UIListLayout", card)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0,8)

    -- section header (clickable for collapse)
    local hdrBtn = Instance.new("TextButton", card)
    hdrBtn.Name                = "Header"
    hdrBtn.Size                = UDim2.new(1,0,0,20)
    hdrBtn.BackgroundTransparency = 1
    hdrBtn.BorderSizePixel     = 0
    hdrBtn.Text                = ""
    hdrBtn.AutoButtonColor     = false
    hdrBtn.LayoutOrder         = 0

    -- small accent tick before title
    local hdrTick = Instance.new("Frame", hdrBtn)
    hdrTick.Size             = UDim2.fromOffset(3,12)
    hdrTick.Position         = UDim2.new(0,0,0.5,-6)
    hdrTick.BackgroundColor3 = self.Accent
    hdrTick.BorderSizePixel  = 0
    Instance.new("UICorner", hdrTick).CornerRadius = UDim.new(1,0)
    self:_onAccent(function(c) hdrTick.BackgroundColor3 = c end)

    local hdr = Instance.new("TextLabel", hdrBtn)
    hdr.Size                  = UDim2.new(1,-30,1,0)
    hdr.Position              = UDim2.fromOffset(10,0)
    hdr.BackgroundTransparency= 1
    hdr.Font                  = Enum.Font.GothamBold
    hdr.TextSize               = 11
    hdr.TextColor3             = T.TextDim
    hdr.TextXAlignment         = Enum.TextXAlignment.Left
    hdr.Text                   = string.upper(title)

    local colArrow = Instance.new("TextLabel", hdrBtn)
    colArrow.Size                  = UDim2.fromOffset(14,20)
    colArrow.Position              = UDim2.new(1,-14,0,0)
    colArrow.BackgroundTransparency= 1
    colArrow.Font                  = Enum.Font.GothamBold
    colArrow.TextSize              = 8
    colArrow.TextColor3            = T.TextMute
    colArrow.Text                  = "▲"

    local sep = Instance.new("Frame", card)
    sep.Name             = "HeaderSep"
    sep.Size             = UDim2.new(1,0,0,1)
    sep.BackgroundColor3 = T.Border
    sep.BorderSizePixel  = 0
    sep.LayoutOrder      = 1

    -- ── Collapse logic ───────────────────────────
    local collapsed = false
    local function setCollapsed(val)
        collapsed = val
        colArrow.Text = val and "▼" or "▲"
        for _, child in ipairs(card:GetChildren()) do
            if child ~= hdrBtn and child ~= sep
               and not child:IsA("UIListLayout")
               and not child:IsA("UIPadding")
               and not child:IsA("UIStroke")
               and not child:IsA("UICorner") then
                child.Visible = not val
            end
        end
        if val then
            card.AutomaticSize = Enum.AutomaticSize.None
            tw(card, 0.2, {Size = UDim2.new(1,0,0,34)})
        else
            task.delay(0.21, function()
                card.AutomaticSize = Enum.AutomaticSize.Y
                card.Size = UDim2.new(1,0,0,0)
            end)
        end
    end

    hdrBtn.MouseButton1Click:Connect(function() setCollapsed(not collapsed) end)
    hdrBtn.MouseEnter:Connect(function() tw(hdr,0.1,{TextColor3=T.Text}) end)
    hdrBtn.MouseLeave:Connect(function() tw(hdr,0.1,{TextColor3=T.TextDim}) end)

    function Section:Collapse() setCollapsed(true) end
    function Section:Expand()   setCollapsed(false) end

    Section._card   = card
    Section._lib    = self
    Section._order  = 2

    local function nextOrder()
        Section._order = Section._order + 1
        return Section._order
    end

    -- ── Toggle (switch style) ─────────────────────
    function Section:CreateToggle(config)
        local ttl      = config.Title    or "Toggle"
        local state    = config.Default  or false
        local cb       = config.Callback or function() end
        local bindKey  = config.Keybind  or nil
        local Toggle   = {State = state}

        local row = Instance.new("TextButton", card)
        row.Name               = "Toggle_"..ttl
        row.Size               = UDim2.new(1,0,0,24)
        row.BackgroundTransparency = 1
        row.Text               = ""
        row.AutoButtonColor    = false
        row.LayoutOrder        = nextOrder()

        -- switch track
        local track = Instance.new("Frame", row)
        track.Size             = UDim2.fromOffset(32,18)
        track.Position         = UDim2.new(0,0,0.5,-9)
        track.BackgroundColor3 = state and self._lib.Accent or T.Element
        track.BorderSizePixel  = 0
        Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
        local trackStroke = Instance.new("UIStroke", track)
        trackStroke.Color     = state and self._lib.Accent or T.BorderLight
        trackStroke.Thickness = 1

        local knob = Instance.new("Frame", track)
        knob.Size             = UDim2.fromOffset(14,14)
        knob.Position         = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        knob.BackgroundColor3 = T.White
        knob.BorderSizePixel  = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

        -- label
        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(1,-90,1,0)
        lbl.Position              = UDim2.fromOffset(42,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = state and T.Text or T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local valLbl = Instance.new("TextLabel", row)
        valLbl.Size                  = UDim2.new(0,44,1,0)
        valLbl.Position              = UDim2.new(1,-44,0,0)
        valLbl.BackgroundTransparency= 1
        valLbl.Font                  = Enum.Font.Gotham
        valLbl.TextSize              = 10
        valLbl.TextColor3            = T.TextMute
        valLbl.TextXAlignment        = Enum.TextXAlignment.Right
        valLbl.Text                  = ""

        self._lib:_onAccent(function(c)
            if Toggle.State then
                track.BackgroundColor3 = c
                trackStroke.Color      = c
            end
        end)

        function Toggle:Set(val)
            Toggle.State         = val
            tw(track, 0.15, {BackgroundColor3 = val and self._lib.Accent or T.Element})
            tw(trackStroke, 0.15, {Color = val and self._lib.Accent or T.BorderLight})
            tw(knob, 0.15, {Position = val and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)})
            tw(lbl, 0.1, {TextColor3 = val and T.Text or T.TextDim})
            pcall(cb, val)
        end
        Toggle._lib = self._lib

        row.MouseButton1Click:Connect(function() Toggle:Set(not Toggle.State) end)
        row.MouseEnter:Connect(function() tw(lbl,0.1,{TextColor3=T.Text}) end)
        row.MouseLeave:Connect(function() if not Toggle.State then tw(lbl,0.1,{TextColor3=T.TextDim}) end end)

        if bindKey then
            valLbl.Text      = "["..bindKey.Name.."]"
            valLbl.TextColor3= T.TextMute
            UserInputService.InputBegan:Connect(function(input, gp)
                if not gp and input.KeyCode == bindKey then
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
        container.Size             = UDim2.new(1,0,0,36)
        container.BackgroundTransparency = 1
        container.LayoutOrder      = nextOrder()

        local headerRow = Instance.new("Frame", container)
        headerRow.Size             = UDim2.new(1,0,0,16)
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

        local trackHolder = Instance.new("TextButton", container)
        trackHolder.Size             = UDim2.new(1,0,0,7)
        trackHolder.Position         = UDim2.fromOffset(0,22)
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
        knob.Size             = UDim2.fromOffset(12,12)
        knob.Position         = UDim2.new(1,-6,0.5,-6)
        knob.BackgroundColor3 = T.White
        knob.BorderSizePixel  = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        local knobStroke = Instance.new("UIStroke", knob)
        knobStroke.Thickness = 2
        knobStroke.Color = self._lib.Accent
        self._lib:_onAccent(function(c) fill.BackgroundColor3 = c; knobStroke.Color = c end)

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
        container.Size             = UDim2.new(1,0,0,26)
        container.AutomaticSize    = Enum.AutomaticSize.None
        container.BackgroundTransparency = 1
        container.ClipsDescendants = false
        container.LayoutOrder      = nextOrder()

        local header = Instance.new("TextButton", container)
        header.Size              = UDim2.new(1,0,0,26)
        header.BackgroundColor3  = T.Element
        header.BorderSizePixel   = 0
        header.Text              = ""
        header.AutoButtonColor   = false
        header.ZIndex            = 3
        Instance.new("UICorner", header).CornerRadius = UDim.new(0,6)
        local hStroke = Instance.new("UIStroke", header)
        hStroke.Color     = T.Border
        hStroke.Thickness = 1

        local hLbl = Instance.new("TextLabel", header)
        hLbl.Size                  = UDim2.new(0.55,0,1,0)
        hLbl.Position              = UDim2.fromOffset(10,0)
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
        arrow.Size                  = UDim2.fromOffset(18,26)
        arrow.Position              = UDim2.new(1,-20,0,0)
        arrow.BackgroundTransparency= 1
        arrow.Font                  = Enum.Font.GothamBold
        arrow.TextSize              = 8
        arrow.TextColor3            = T.TextMute
        arrow.Text                  = "▼"

        local listFrame = Instance.new("Frame", container)
        listFrame.Name             = "List"
        listFrame.Size             = UDim2.new(1,0,0,0)
        listFrame.Position         = UDim2.fromOffset(0,30)
        listFrame.BackgroundColor3 = T.Element
        listFrame.BorderSizePixel  = 0
        listFrame.ClipsDescendants = true
        listFrame.ZIndex           = 10
        listFrame.Visible          = false
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0,6)
        addShadow(listFrame, 0.6, 24).ZIndex = 9
        local lStroke = Instance.new("UIStroke", listFrame)
        lStroke.Color     = T.BorderLight
        lStroke.Thickness = 1
        lStroke.ZIndex    = 10
        local listLayout = Instance.new("UIListLayout", listFrame)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding   = UDim.new(0,2)
        local listPad = Instance.new("UIPadding", listFrame)
        listPad.PaddingTop    = UDim.new(0,4)
        listPad.PaddingBottom = UDim.new(0,4)
        listPad.PaddingLeft   = UDim.new(0,4)
        listPad.PaddingRight  = UDim.new(0,4)

        local function buildList()
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(Dropdown.Options) do
                local ob = Instance.new("TextButton", listFrame)
                ob.Size              = UDim2.new(1,0,0,22)
                ob.BackgroundColor3  = opt==Dropdown.Selected and self._lib.Accent or T.Element
                ob.BackgroundTransparency = opt==Dropdown.Selected and 0.25 or 1
                ob.BorderSizePixel   = 0
                ob.Font              = Enum.Font.Gotham
                ob.TextSize          = 11
                ob.TextColor3        = opt==Dropdown.Selected and T.White or T.TextDim
                ob.TextXAlignment    = Enum.TextXAlignment.Left
                ob.Text              = "  "..tostring(opt)
                ob.AutoButtonColor   = false
                ob.ZIndex            = 11
                Instance.new("UICorner", ob).CornerRadius = UDim.new(0,5)
                ob.MouseEnter:Connect(function() if opt~=Dropdown.Selected then tw(ob,0.1,{BackgroundTransparency=0.85, TextColor3=T.Text}) end end)
                ob.MouseLeave:Connect(function() if opt~=Dropdown.Selected then tw(ob,0.1,{BackgroundTransparency=1, TextColor3=T.TextDim}) end end)
                ob.MouseButton1Click:Connect(function()
                    Dropdown:Set(opt)
                    Dropdown:Close()
                end)
            end
            listFrame.Size = UDim2.new(1,0,0, listLayout.AbsoluteContentSize.Y + 8)
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
        row.Size              = UDim2.new(1,0,0,26)
        row.BackgroundTransparency = 1
        row.LayoutOrder       = nextOrder()

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(0.4,0,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local inputFrame = Instance.new("Frame", row)
        inputFrame.Size            = UDim2.new(0.6,-4,1,0)
        inputFrame.Position        = UDim2.new(0.4,4,0,0)
        inputFrame.BackgroundColor3= T.Element
        inputFrame.BorderSizePixel = 0
        Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0,6)
        local ifStroke = Instance.new("UIStroke", inputFrame)
        ifStroke.Color     = T.Border
        ifStroke.Thickness = 1

        local input = Instance.new("TextBox", inputFrame)
        input.Size                 = UDim2.new(1,-16,1,0)
        input.Position             = UDim2.fromOffset(8,0)
        input.BackgroundTransparency= 1
        input.Font                 = Enum.Font.Gotham
        input.TextSize             = 11
        input.TextColor3           = T.Text
        input.PlaceholderColor3    = T.TextMute
        input.PlaceholderText      = ph
        input.Text                 = def
        input.ClearTextOnFocus     = false
        input.TextXAlignment       = Enum.TextXAlignment.Left

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
        row.Size              = UDim2.new(1,0,0,26)
        row.BackgroundTransparency = 1
        row.LayoutOrder       = nextOrder()

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                  = UDim2.new(1,-84,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local kBtn = Instance.new("TextButton", row)
        kBtn.Size              = UDim2.fromOffset(76,22)
        kBtn.Position          = UDim2.new(1,-76,0.5,-11)
        kBtn.BackgroundColor3  = T.Element
        kBtn.BorderSizePixel   = 0
        kBtn.Font              = Enum.Font.GothamBold
        kBtn.TextSize          = 10
        kBtn.TextColor3        = T.TextDim
        kBtn.Text              = "["..defK.Name.."]"
        kBtn.AutoButtonColor   = false
        Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0,6)
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
        container.Size             = UDim2.new(1,0,0,26)
        container.AutomaticSize    = Enum.AutomaticSize.None
        container.BackgroundTransparency = 1
        container.ClipsDescendants = true
        container.LayoutOrder      = nextOrder()

        local header = Instance.new("TextButton", container)
        header.Size              = UDim2.new(1,0,0,26)
        header.BackgroundTransparency = 1
        header.Text              = ""
        header.AutoButtonColor   = false

        local lbl = Instance.new("TextLabel", header)
        lbl.Size                  = UDim2.new(1,-40,1,0)
        lbl.BackgroundTransparency= 1
        lbl.Font                  = Enum.Font.Gotham
        lbl.TextSize              = 12
        lbl.TextColor3            = T.TextDim
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Text                  = ttl

        local preview = Instance.new("Frame", header)
        preview.Size             = UDim2.fromOffset(28,16)
        preview.Position         = UDim2.new(1,-30,0.5,-8)
        preview.BackgroundColor3 = defC
        preview.BorderSizePixel  = 0
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0,5)
        local prevStroke = Instance.new("UIStroke", preview)
        prevStroke.Color     = T.BorderLight
        prevStroke.Thickness = 1

        local panel = Instance.new("Frame", container)
        panel.Size             = UDim2.new(1,0,0,78)
        panel.Position         = UDim2.fromOffset(0,30)
        panel.BackgroundColor3 = T.Element
        panel.BorderSizePixel  = 0
        panel.Visible          = false
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0,6)
        local panelStroke = Instance.new("UIStroke", panel)
        panelStroke.Color     = T.Border
        panelStroke.Thickness = 1
        local panPad = Instance.new("UIPadding", panel)
        panPad.PaddingLeft=UDim.new(0,8); panPad.PaddingRight=UDim.new(0,8)
        panPad.PaddingTop=UDim.new(0,6); panPad.PaddingBottom=UDim.new(0,6)
        local panLayout = Instance.new("UIListLayout", panel)
        panLayout.SortOrder = Enum.SortOrder.LayoutOrder
        panLayout.Padding   = UDim.new(0,5)

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
            container.Size = UDim2.new(1,0,0, CP.Opened and 112 or 26)
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

        local btn = Instance.new("TextButton", card)
        btn.Name              = "Btn_"..ttl
        btn.Size              = UDim2.new(1,0,0,26)
        btn.BackgroundColor3  = T.Element
        btn.BorderSizePixel   = 0
        btn.Font              = Enum.Font.GothamMedium
        btn.TextSize          = 12
        btn.TextColor3        = T.Text
        btn.Text              = ttl
        btn.AutoButtonColor   = false
        btn.ClipsDescendants  = true
        btn.LayoutOrder       = nextOrder()
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
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
    if self._wmConn  then self._wmConn:Disconnect() end
end

function Library:SetTitle(title, version)
    self.Title   = title   or self.Title
    self.Version = version or self.Version
end

-- ==============================================================================
-- MULTI-SELECT DROPDOWN  (Section:CreateMultiDropdown)
-- ==============================================================================
local function _buildMultiDropdown(Section, card, nextOrder, config)
    local ttl     = config.Title    or "MultiDropdown"
    local opts    = config.Options  or {}
    local defs    = config.Default  or {}
    local maxShow = config.MaxShow  or 2
    local cb      = config.Callback or function() end
    local Window  = Section._lib

    local selected = {}
    for _, v in ipairs(defs) do selected[v] = true end

    local MDD = {Selected = selected, Opened = false, Options = opts}

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
    container.Size             = UDim2.new(1,0,0,26)
    container.AutomaticSize    = Enum.AutomaticSize.None
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.LayoutOrder      = nextOrder()

    local header = Instance.new("TextButton", container)
    header.Size              = UDim2.new(1,0,0,26)
    header.BackgroundColor3  = T.Element
    header.BorderSizePixel   = 0
    header.Text              = ""
    header.AutoButtonColor   = false
    header.ZIndex            = 3
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,6)
    local hStroke = Instance.new("UIStroke", header)
    hStroke.Color = T.Border; hStroke.Thickness = 1

    local hLbl = Instance.new("TextLabel", header)
    hLbl.Size = UDim2.new(0.48,0,1,0); hLbl.Position = UDim2.fromOffset(10,0)
    hLbl.BackgroundTransparency=1; hLbl.Font=Enum.Font.Gotham
    hLbl.TextSize=11; hLbl.TextColor3=T.TextDim
    hLbl.TextXAlignment=Enum.TextXAlignment.Left; hLbl.Text=ttl

    local valLbl = Instance.new("TextLabel", header)
    valLbl.Size = UDim2.new(0.46,-20,1,0); valLbl.Position = UDim2.new(0.48,0,0,0)
    valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.GothamMedium
    valLbl.TextSize=10; valLbl.TextColor3=T.Text
    valLbl.TextXAlignment=Enum.TextXAlignment.Right
    valLbl.TextTruncate=Enum.TextTruncate.AtEnd
    valLbl.Text = summary()

    local arrow = Instance.new("TextLabel", header)
    arrow.Size=UDim2.fromOffset(18,26); arrow.Position=UDim2.new(1,-20,0,0)
    arrow.BackgroundTransparency=1; arrow.Font=Enum.Font.GothamBold
    arrow.TextSize=8; arrow.TextColor3=T.TextMute; arrow.Text="▼"

    local listFrame = Instance.new("Frame", container)
    listFrame.Name="List"; listFrame.Size=UDim2.new(1,0,0,0)
    listFrame.Position=UDim2.fromOffset(0,30)
    listFrame.BackgroundColor3=T.Element; listFrame.BorderSizePixel=0
    listFrame.ClipsDescendants=true; listFrame.ZIndex=10; listFrame.Visible=false
    Instance.new("UICorner", listFrame).CornerRadius=UDim.new(0,6)
    addShadow(listFrame, 0.6, 24).ZIndex = 9
    local lStroke=Instance.new("UIStroke",listFrame)
    lStroke.Color=T.BorderLight; lStroke.Thickness=1; lStroke.ZIndex=10
    local listLayout=Instance.new("UIListLayout",listFrame)
    listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,2)
    local lPad=Instance.new("UIPadding",listFrame)
    lPad.PaddingTop=UDim.new(0,4); lPad.PaddingBottom=UDim.new(0,4)
    lPad.PaddingLeft=UDim.new(0,4); lPad.PaddingRight=UDim.new(0,4)

    local function buildList()
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(MDD.Options) do
            local isSel = selected[opt] == true
            local ob = Instance.new("TextButton", listFrame)
            ob.Size=UDim2.new(1,0,0,22); ob.BorderSizePixel=0
            ob.BackgroundColor3 = isSel and Window.Accent or T.Element
            ob.BackgroundTransparency = isSel and 0.25 or 1
            ob.Font=Enum.Font.Gotham; ob.TextSize=11
            ob.TextColor3 = isSel and T.White or T.TextDim
            ob.TextXAlignment=Enum.TextXAlignment.Left
            ob.Text="  "..tostring(opt); ob.AutoButtonColor=false; ob.ZIndex=11
            Instance.new("UICorner",ob).CornerRadius=UDim.new(0,5)

            local ck=Instance.new("TextLabel",ob)
            ck.Size=UDim2.fromOffset(18,22); ck.Position=UDim2.new(1,-20,0,0)
            ck.BackgroundTransparency=1; ck.Font=Enum.Font.GothamBold
            ck.TextSize=10; ck.ZIndex=12
            ck.TextColor3=Window.Accent; ck.Text=isSel and "✓" or ""

            ob.MouseEnter:Connect(function()
                if not selected[opt] then tw(ob,0.1,{BackgroundTransparency=0.85,TextColor3=T.Text}) end
            end)
            ob.MouseLeave:Connect(function()
                if not selected[opt] then tw(ob,0.1,{BackgroundTransparency=1,TextColor3=T.TextDim}) end
            end)
            ob.MouseButton1Click:Connect(function()
                if selected[opt] then
                    selected[opt] = nil
                else
                    selected[opt] = true
                end
                valLbl.Text = summary()
                buildList()
                local res={}; for k in pairs(selected) do table.insert(res,k) end
                pcall(cb, res)
            end)
        end
        listFrame.Size=UDim2.new(1,0,0, listLayout.AbsoluteContentSize.Y+8)
    end

    function MDD:Open()
        MDD.Opened=true; listFrame.Visible=true; buildList()
        tw(arrow,0.15,{Rotation=180})
        tw(hStroke,0.15,{Color=Window.Accent})
    end
    function MDD:Close()
        MDD.Opened=false
        tw(arrow,0.15,{Rotation=0}); tw(hStroke,0.15,{Color=T.Border})
        task.delay(0.15,function() if not MDD.Opened then listFrame.Visible=false end end)
    end
    function MDD:Set(tbl)
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
-- NOTIFICATION SYSTEM  (Hub:Notify)  — redesigned, proper spacing/proportions
-- ==============================================================================
function Library:_initNotify()
    if self._notifyReady then return end
    self._notifyReady  = true

    local holder = Instance.new("Frame", self.ScreenGui)
    holder.Name              = "NotifyHolder"
    holder.Size              = UDim2.fromOffset(300, 620)
    holder.Position          = UDim2.new(1,-20, 1,-20)
    holder.AnchorPoint       = Vector2.new(1, 1)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel   = 0
    local hLayout = Instance.new("UIListLayout", holder)
    hLayout.SortOrder        = Enum.SortOrder.LayoutOrder
    hLayout.VerticalAlignment= Enum.VerticalAlignment.Bottom
    hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    hLayout.Padding          = UDim.new(0,10)
    self._notifyHolder = holder
end

function Library:Notify(config)
    self:_initNotify()
    config = config or {}
    local title    = config.Title    or "Notification"
    local text     = config.Text     or ""
    local duration = config.Duration or 3.5
    local ntype    = config.Type     or "info"   -- "info" | "success" | "error" | "warning"

    local typeColors = {
        info    = self.Accent,
        success = Color3.fromRGB(34, 197, 94),
        error   = Color3.fromRGB(230, 60, 60),
        warning = Color3.fromRGB(245, 158, 11),
    }
    local accent = typeColors[ntype] or self.Accent

    local hasBody = text ~= ""
    local TOAST_W = 280
    local TOAST_H = hasBody and 64 or 46
    local PAD     = 14

    local toast = Instance.new("Frame")
    toast.Name              = "Toast"
    toast.Size              = UDim2.fromOffset(0, TOAST_H)   -- width animates in
    toast.BackgroundColor3  = T.Card
    toast.BorderSizePixel   = 0
    toast.ClipsDescendants  = true
    toast.LayoutOrder       = -math.floor(os.clock() * 1000)
    toast.Parent            = self._notifyHolder
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0,10)
    addShadow(toast, 0.45, 30)
    local tStroke = Instance.new("UIStroke", toast)
    tStroke.Color = T.Border; tStroke.Thickness = 1

    -- left accent bar (full height, rounded to match card)
    local bar = Instance.new("Frame", toast)
    bar.Size=UDim2.new(0,4,1,0); bar.BackgroundColor3=accent; bar.BorderSizePixel=0

    -- icon in a soft circular chip
    local iconChip = Instance.new("Frame", toast)
    iconChip.Size              = UDim2.fromOffset(28,28)
    iconChip.Position          = UDim2.new(0, PAD, 0.5, -14)
    iconChip.BackgroundColor3  = accent
    iconChip.BackgroundTransparency = 0.82
    iconChip.BorderSizePixel   = 0
    Instance.new("UICorner", iconChip).CornerRadius = UDim.new(1,0)
    local icons = {info="ℹ", success="✓", error="✕", warning="!"}
    local iconLbl = Instance.new("TextLabel", iconChip)
    iconLbl.Size=UDim2.new(1,0,1,0)
    iconLbl.BackgroundTransparency=1; iconLbl.Font=Enum.Font.GothamBold
    iconLbl.TextSize=14; iconLbl.TextColor3=accent; iconLbl.Text=icons[ntype] or "ℹ"

    local textX = PAD + 28 + 10   -- after icon chip + gap

    -- title
    local titleLbl = Instance.new("TextLabel", toast)
    titleLbl.BackgroundTransparency=1; titleLbl.Font=Enum.Font.GothamBold
    titleLbl.TextSize=13; titleLbl.TextColor3=T.Text
    titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.Text=title

    if hasBody then
        titleLbl.Size     = UDim2.new(1, -textX-30, 0, 16)
        titleLbl.Position = UDim2.new(0, textX, 0, 12)
        local bodyLbl = Instance.new("TextLabel", toast)
        bodyLbl.Size=UDim2.new(1,-textX-30,0,16)
        bodyLbl.Position=UDim2.new(0, textX, 0, 32)
        bodyLbl.BackgroundTransparency=1; bodyLbl.Font=Enum.Font.Gotham
        bodyLbl.TextSize=11.5; bodyLbl.TextColor3=T.TextDim
        bodyLbl.TextXAlignment=Enum.TextXAlignment.Left
        bodyLbl.TextTruncate=Enum.TextTruncate.AtEnd
        bodyLbl.Text=text
    else
        titleLbl.Size     = UDim2.new(1, -textX-30, 1, 0)
        titleLbl.Position = UDim2.new(0, textX, 0, 0)
    end

    -- close button
    local closeBtn = Instance.new("TextButton", toast)
    closeBtn.Size=UDim2.fromOffset(20,20); closeBtn.Position=UDim2.new(1,-28,0,PAD-2)
    closeBtn.BackgroundTransparency=1; closeBtn.Font=Enum.Font.GothamBold
    closeBtn.TextSize=11; closeBtn.TextColor3=T.TextMute; closeBtn.Text="✕"
    closeBtn.AutoButtonColor=false
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3=T.Text end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3=T.TextMute end)

    -- progress bar (bottom, inset, rounded)
    local progTrack = Instance.new("Frame", toast)
    progTrack.Size=UDim2.new(1,-8,0,3); progTrack.Position=UDim2.new(0,4,1,-6)
    progTrack.BackgroundColor3=T.Element; progTrack.BorderSizePixel=0
    Instance.new("UICorner", progTrack).CornerRadius = UDim.new(1,0)
    local prog = Instance.new("Frame", progTrack)
    prog.Size=UDim2.new(1,0,1,0); prog.BackgroundColor3=accent; prog.BorderSizePixel=0
    Instance.new("UICorner", prog).CornerRadius = UDim.new(1,0)

    -- animate in (slide + grow width)
    tw(toast, 0.28, {Size=UDim2.fromOffset(TOAST_W, TOAST_H)}, Enum.EasingStyle.Back)
    tw(prog, duration, {Size=UDim2.new(0,0,1,0)})

    local function dismiss()
        tw(toast, 0.2, {BackgroundTransparency=1, Size=UDim2.fromOffset(TOAST_W,0)})
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
function Library:_regElement(key, getter, setter)
    if not self._configElements then self._configElements = {} end
    self._configElements[key] = {get=getter, set=setter}
end

local function _serialize(tbl)
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
                pcall(elem.set, data[key])
                loaded = loaded + 1
            end
        end
    end
    self:Notify({Title="Config Loaded", Text=loaded.." values restored.", Type="success", Duration=2.5})
end

local _origCreateSection = Library._createSection
function Library:_createSection(title, parent)
    local sec = _origCreateSection(self, title, parent)
    local hub = self

    local _origToggle = sec.CreateToggle
    sec.CreateToggle = function(s, config)
        local t = _origToggle(s, config)
        if config.ConfigKey then
            hub:_regElement(config.ConfigKey,
                function() return tostring(t.State) end,
                function(v) t:Set(v=="true") end)
        end
        return t
    end

    local _origSlider = sec.CreateSlider
    sec.CreateSlider = function(s, config)
        local sl = _origSlider(s, config)
        if config.ConfigKey then
            hub:_regElement(config.ConfigKey,
                function() return tostring(sl.Value) end,
                function(v) sl:Set(tonumber(v) or sl.Value) end)
        end
        return sl
    end

    local _origDD = sec.CreateDropdown
    sec.CreateDropdown = function(s, config)
        local dd = _origDD(s, config)
        if config.ConfigKey then
            hub:_regElement(config.ConfigKey,
                function() return tostring(dd.Selected) end,
                function(v) dd:Set(v) end)
        end
        return dd
    end

    function sec:CreateMultiDropdown(config)
        return _buildMultiDropdown(self, self._card, function()
            self._order = self._order + 1; return self._order
        end, config)
    end

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
        return mdd
    end

    return sec
end

-- ==============================================================================
-- WATERMARK  (Hub:SetWatermark / Hub:UpdateWatermark / Hub:RemoveWatermark)
-- ==============================================================================
function Library:SetWatermark(config)
    config = config or {}
    local fmt      = config.Format   or "{player}  |  {fps} fps"
    local pos      = config.Position or "TopRight"
    local bgAlpha  = config.BgAlpha  or 0.35

    if self._wmFrame then self._wmFrame:Destroy() end

    local wm = Instance.new("Frame", self.ScreenGui)
    wm.Name             = "Watermark"
    wm.Size             = UDim2.fromOffset(0, 26)
    wm.AutomaticSize    = Enum.AutomaticSize.X
    wm.BackgroundColor3 = T.Surface
    wm.BackgroundTransparency = bgAlpha
    wm.BorderSizePixel  = 0
    Instance.new("UICorner", wm).CornerRadius = UDim.new(0,7)
    addShadow(wm, 0.65, 16)
    local wmStroke = Instance.new("UIStroke", wm)
    wmStroke.Color = T.Border; wmStroke.Thickness = 1
    local wmPad = Instance.new("UIPadding", wm)
    wmPad.PaddingLeft=UDim.new(0,11); wmPad.PaddingRight=UDim.new(0,11)

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
    lbl.Font                 = Enum.Font.GothamBold
    lbl.TextSize             = 11
    lbl.TextColor3           = T.Text
    lbl.RichText             = true
    lbl.AutomaticSize        = Enum.AutomaticSize.X
    lbl.Text                 = fmt

    self:_onAccent(function(c) wmStroke.Color = c end)

    self._wmFrame = wm
    self._wmFmt   = fmt

    local fps, lastTick, frames = 60, os.clock(), 0
    local fpsConn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastTick >= 0.5 then
            fps = math.floor(frames / (now - lastTick) + 0.5)
            frames = 0; lastTick = now
        end
    end)

    local function buildText(f)
        local h = math.floor(os.clock() / 3600 % 24)
        local m = math.floor(os.clock() / 60 % 60)
        local s = math.floor(os.clock() % 60)
        local timeStr = string.format("%02d:%02d:%02d", h, m, s)

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

        local fpsColHex = fps >= 50 and "7ee787" or fps >= 30 and "f5c542" or "ff7b72"
        result = result:gsub(tostring(fps).." fps",
            string.format('<font color="#%s">%d fps</font>', fpsColHex, fps))

        return result
    end

    local wmConn = RunService.Heartbeat:Connect(function()
        if not wm or not wm.Parent then return end
        lbl.Text = buildText(self._wmFmt or fmt)
    end)

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

local _origDestroy = Library.Destroy
function Library:Destroy()
    _origDestroy(self)
    self:RemoveWatermark()
end

return Library