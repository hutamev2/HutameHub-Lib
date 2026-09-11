--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    HUTAME HUB LIBRARY                        ║
    ║  Private Hub · Gold Theme · Sidebar · Two-Column · v3.0      ║
    ╚══════════════════════════════════════════════════════════════╝
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))()
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────
local function tw(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), props):Play()
end

local function safeParent()
    local ok, cg = pcall(function() return CoreGui end)
    return (ok and cg) or LocalPlayer:WaitForChild("PlayerGui")
end

local function ripple(btn, accent)
    local rip = Instance.new("Frame", btn)
    rip.Size = UDim2.fromOffset(0,0)
    rip.AnchorPoint = Vector2.new(0.5,0.5)
    rip.Position = UDim2.new(0.5,0,0.5,0)
    rip.BackgroundColor3 = accent
    rip.BackgroundTransparency = 0.65
    rip.BorderSizePixel = 0
    rip.ZIndex = btn.ZIndex + 5
    Instance.new("UICorner", rip).CornerRadius = UDim.new(1,0)
    tw(rip, 0.38, {Size=UDim2.fromOffset(130,130), BackgroundTransparency=1})
    game:GetService("Debris"):AddItem(rip, 0.4)
end

-- ─────────────────────────────────────────────────────────────────
-- Theme  (koyu kahve/siyah + altın accent — resimdeki gibi)
-- ─────────────────────────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(18, 16, 13),
    Surface     = Color3.fromRGB(23, 20, 15),
    Card        = Color3.fromRGB(26, 23, 17),
    Sidebar     = Color3.fromRGB(20, 18, 12),
    Element     = Color3.fromRGB(32, 28, 20),
    ElementHov  = Color3.fromRGB(42, 37, 26),
    Border      = Color3.fromRGB(50, 44, 30),
    BorderLight = Color3.fromRGB(70, 62, 40),
    Text        = Color3.fromRGB(220, 205, 170),
    TextDim     = Color3.fromRGB(148, 132, 95),
    TextMute    = Color3.fromRGB(88, 78, 54),
    Accent      = Color3.fromRGB(200, 168, 68),
    AccentDim   = Color3.fromRGB(120, 100, 40),
    AccentText  = Color3.fromRGB(14, 12, 6),
    White       = Color3.new(1,1,1),
    Black       = Color3.new(0,0,0),
}

-- ─────────────────────────────────────────────────────────────────
-- Library
-- ─────────────────────────────────────────────────────────────────
local Library = {}
Library.__index = Library

function Library.new(config)
    config = config or {}
    local self = setmetatable({}, Library)
    self.Title       = config.Title       or "HutameHub"
    self.Version     = config.Version     or "v1.0"
    self.Accent      = config.Accent      or T.Accent
    self.ToggleKey   = config.ToggleKey   or Enum.KeyCode.RightControl
    self.Tabs        = {}
    self.ActiveTab   = nil
    self._accentSubs = {}
    self._configElements = {}

    T.Accent    = self.Accent
    T.AccentDim = Color3.fromRGB(
        math.floor(self.Accent.R*255*0.55),
        math.floor(self.Accent.G*255*0.55),
        math.floor(self.Accent.B*255*0.55)
    )

    self:_build()

    -- Loading Screen
    if config.LoadingScreen ~= false then
        local loadDur = config.LoadingDuration or 1.6
        local sg = self.ScreenGui
        local mf = self.MainFrame

        local splash = Instance.new("Frame", sg)
        splash.Name="Splash"; splash.Size=UDim2.new(1,0,1,0)
        splash.BackgroundColor3=T.BG; splash.BorderSizePixel=0; splash.ZIndex=100

        local card = Instance.new("Frame", splash)
        card.Size=UDim2.fromOffset(280,160); card.Position=UDim2.new(0.5,-140,0.5,-80)
        card.BackgroundColor3=T.Surface; card.BorderSizePixel=0; card.ZIndex=101
        Instance.new("UICorner", card).CornerRadius=UDim.new(0,8)
        local cStroke=Instance.new("UIStroke",card); cStroke.Color=T.Border; cStroke.Thickness=1; cStroke.ZIndex=101

        local acTop=Instance.new("Frame",card); acTop.Size=UDim2.new(1,0,0,2)
        acTop.BackgroundColor3=self.Accent; acTop.BorderSizePixel=0; acTop.ZIndex=102
        Instance.new("UICorner",acTop).CornerRadius=UDim.new(0,8)
        self:_onAccent(function(c) acTop.BackgroundColor3=c end)

        local logoBox=Instance.new("Frame",card); logoBox.Size=UDim2.fromOffset(36,36)
        logoBox.Position=UDim2.new(0.5,-18,0,20); logoBox.BackgroundColor3=self.Accent
        logoBox.BorderSizePixel=0; logoBox.ZIndex=102
        Instance.new("UICorner",logoBox).CornerRadius=UDim.new(0,8)
        self:_onAccent(function(c) logoBox.BackgroundColor3=c end)
        local ll=Instance.new("TextLabel",logoBox); ll.Size=UDim2.new(1,0,1,0)
        ll.BackgroundTransparency=1; ll.Font=Enum.Font.GothamBold; ll.TextSize=18
        ll.TextColor3=T.AccentText; ll.Text=string.sub(self.Title,1,1); ll.ZIndex=103

        local tl=Instance.new("TextLabel",card); tl.Size=UDim2.new(1,0,0,20)
        tl.Position=UDim2.fromOffset(0,64); tl.BackgroundTransparency=1
        tl.Font=Enum.Font.GothamBold; tl.TextSize=15; tl.TextColor3=T.Text; tl.Text=self.Title; tl.ZIndex=102

        local sl=Instance.new("TextLabel",card); sl.Size=UDim2.new(1,0,0,16)
        sl.Position=UDim2.fromOffset(0,86); sl.BackgroundTransparency=1
        sl.Font=Enum.Font.Gotham; sl.TextSize=11; sl.TextColor3=T.TextDim; sl.Text=self.Version; sl.ZIndex=102

        local track=Instance.new("Frame",card); track.Size=UDim2.new(1,-40,0,3)
        track.Position=UDim2.new(0,20,1,-18); track.BackgroundColor3=T.Element
        track.BorderSizePixel=0; track.ZIndex=102
        Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
        local fill=Instance.new("Frame",track); fill.Size=UDim2.new(0,0,1,0)
        fill.BackgroundColor3=self.Accent; fill.BorderSizePixel=0; fill.ZIndex=103
        Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
        self:_onAccent(function(c) fill.BackgroundColor3=c end)

        local stLbl=Instance.new("TextLabel",card); stLbl.Size=UDim2.new(1,0,0,12)
        stLbl.Position=UDim2.new(0,0,1,-34); stLbl.BackgroundTransparency=1
        stLbl.Font=Enum.Font.Gotham; stLbl.TextSize=10; stLbl.TextColor3=T.TextMute
        stLbl.Text="Loading..."; stLbl.ZIndex=102

        mf.Visible = false

        task.spawn(function()
            local steps={
                {pct=0.30,label="Initializing...",   t=loadDur*0.25},
                {pct=0.60,label="Loading elements...",t=loadDur*0.25},
                {pct=0.85,label="Applying theme...", t=loadDur*0.20},
                {pct=1.00,label="Ready!",            t=loadDur*0.20},
            }
            for _,s in ipairs(steps) do
                task.wait(s.t); stLbl.Text=s.label
                tw(fill, s.t+0.05, {Size=UDim2.new(s.pct,0,1,0)})
            end
            task.wait(0.25)
            for _,d in ipairs(splash:GetDescendants()) do
                if d:IsA("TextLabel") then tw(d,0.3,{TextTransparency=1}) end
                if d:IsA("Frame") then pcall(function() tw(d,0.3,{BackgroundTransparency=1}) end) end
            end
            tw(splash,0.3,{BackgroundTransparency=1})
            task.wait(0.35); splash:Destroy(); mf.Visible=true
        end)
    end

    return self
end

function Library:_onAccent(fn) table.insert(self._accentSubs, fn) end

function Library:SetAccent(col)
    self.Accent = col; T.Accent = col
    T.AccentDim = Color3.fromRGB(
        math.floor(col.R*255*0.55),
        math.floor(col.G*255*0.55),
        math.floor(col.B*255*0.55)
    )
    for _,fn in ipairs(self._accentSubs) do pcall(fn,col) end
end

function Library:_regElement(key, getter, setter)
    self._configElements[key] = {get=getter, set=setter}
end

-- ─────────────────────────────────────────────────────────────────
-- Build  (pencere iskeletini inşa et)
-- ─────────────────────────────────────────────────────────────────
function Library:_build()
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name="HutameHub_"..math.random(1000,9999)
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
    sg.Parent=safeParent(); self.ScreenGui=sg

    -- Ana çerçeve
    local mf = Instance.new("Frame", sg)
    mf.Name="MainFrame"; mf.Size=UDim2.fromOffset(780,500)
    mf.Position=UDim2.new(0.5,-390,0.5,-250)
    mf.BackgroundColor3=T.BG; mf.BorderSizePixel=0
    mf.ClipsDescendants=true
    Instance.new("UICorner",mf).CornerRadius=UDim.new(0,6)
    local mfStroke=Instance.new("UIStroke",mf)
    mfStroke.Color=T.Border; mfStroke.Thickness=1
    self.MainFrame=mf

    -- ── Sol Sidebar (120px) ──────────────────────
    local sb = Instance.new("Frame", mf)
    sb.Name="Sidebar"; sb.Size=UDim2.new(0,120,1,0)
    sb.BackgroundColor3=T.Sidebar; sb.BorderSizePixel=0; sb.ZIndex=3

    -- sidebar sağ border çizgisi
    local sbLine=Instance.new("Frame",sb)
    sbLine.Size=UDim2.new(0,1,1,0); sbLine.Position=UDim2.new(1,-1,0,0)
    sbLine.BackgroundColor3=T.Border; sbLine.BorderSizePixel=0; sbLine.ZIndex=4

    -- logo alanı (üst 60px)
    local sbTop=Instance.new("Frame",sb)
    sbTop.Size=UDim2.new(1,0,0,60); sbTop.BackgroundColor3=T.BG; sbTop.BorderSizePixel=0; sbTop.ZIndex=4
    local sbTopLine=Instance.new("Frame",sbTop)
    sbTopLine.Size=UDim2.new(1,0,0,1); sbTopLine.Position=UDim2.new(0,0,1,-1)
    sbTopLine.BackgroundColor3=T.Border; sbTopLine.BorderSizePixel=0; sbTopLine.ZIndex=5

    local sbIcon=Instance.new("Frame",sbTop)
    sbIcon.Size=UDim2.fromOffset(28,28); sbIcon.Position=UDim2.new(0.5,-14,0,10)
    sbIcon.BackgroundColor3=self.Accent; sbIcon.BorderSizePixel=0; sbIcon.ZIndex=5
    Instance.new("UICorner",sbIcon).CornerRadius=UDim.new(0,6)
    self:_onAccent(function(c) sbIcon.BackgroundColor3=c end)
    local sbIconLbl=Instance.new("TextLabel",sbIcon)
    sbIconLbl.Size=UDim2.new(1,0,1,0); sbIconLbl.BackgroundTransparency=1
    sbIconLbl.Font=Enum.Font.GothamBold; sbIconLbl.TextSize=13
    sbIconLbl.TextColor3=T.AccentText; sbIconLbl.Text=string.sub(self.Title,1,1); sbIconLbl.ZIndex=6

    local sbNameLbl=Instance.new("TextLabel",sbTop)
    sbNameLbl.Size=UDim2.new(1,0,0,12); sbNameLbl.Position=UDim2.fromOffset(0,42)
    sbNameLbl.BackgroundTransparency=1; sbNameLbl.Font=Enum.Font.GothamBold
    sbNameLbl.TextSize=8; sbNameLbl.TextColor3=T.TextMute; sbNameLbl.Text=string.upper(self.Title); sbNameLbl.ZIndex=5

    -- sidebar nav listesi
    local sbNav=Instance.new("Frame",sb)
    sbNav.Name="SbNav"; sbNav.Size=UDim2.new(1,0,1,-100)
    sbNav.Position=UDim2.fromOffset(0,61); sbNav.BackgroundTransparency=1; sbNav.ZIndex=4
    local sbNavLayout=Instance.new("UIListLayout",sbNav)
    sbNavLayout.SortOrder=Enum.SortOrder.LayoutOrder; sbNavLayout.Padding=UDim.new(0,1)
    local sbNavPad=Instance.new("UIPadding",sbNav)
    sbNavPad.PaddingTop=UDim.new(0,8); sbNavPad.PaddingLeft=UDim.new(0,6); sbNavPad.PaddingRight=UDim.new(0,6)
    self._sbNav=sbNav

    -- sidebar alt kullanıcı şeridi
    local sbBot=Instance.new("Frame",sb)
    sbBot.Size=UDim2.new(1,0,0,40); sbBot.Position=UDim2.new(0,0,1,-40)
    sbBot.BackgroundColor3=T.BG; sbBot.BorderSizePixel=0; sbBot.ZIndex=4
    local sbBotLine=Instance.new("Frame",sbBot)
    sbBotLine.Size=UDim2.new(1,0,0,1); sbBotLine.BackgroundColor3=T.Border; sbBotLine.BorderSizePixel=0; sbBotLine.ZIndex=5
    local sbUserLbl=Instance.new("TextLabel",sbBot)
    sbUserLbl.Size=UDim2.new(1,-10,1,0); sbUserLbl.Position=UDim2.fromOffset(8,0)
    sbUserLbl.BackgroundTransparency=1; sbUserLbl.Font=Enum.Font.Gotham
    sbUserLbl.TextSize=10; sbUserLbl.TextColor3=T.TextMute
    sbUserLbl.TextXAlignment=Enum.TextXAlignment.Left; sbUserLbl.Text=LocalPlayer.Name; sbUserLbl.ZIndex=5

    -- ── Sağ alan ─────────────────────────────────
    local ra=Instance.new("Frame",mf)
    ra.Name="RightArea"; ra.Size=UDim2.new(1,-120,1,0)
    ra.Position=UDim2.fromOffset(120,0)
    ra.BackgroundTransparency=1; ra.BorderSizePixel=0; ra.ZIndex=2

    -- topbar
    local topbar=Instance.new("Frame",ra)
    topbar.Name="Topbar"; topbar.Size=UDim2.new(1,0,0,36)
    topbar.BackgroundColor3=T.BG; topbar.BorderSizePixel=0; topbar.ZIndex=3
    local tbLine=Instance.new("Frame",topbar)
    tbLine.Size=UDim2.new(1,0,0,1); tbLine.Position=UDim2.new(0,0,1,-1)
    tbLine.BackgroundColor3=T.Border; tbLine.BorderSizePixel=0; tbLine.ZIndex=4

    -- versiyon (sol)
    local verLbl=Instance.new("TextLabel",topbar)
    verLbl.Size=UDim2.new(0,80,1,0); verLbl.Position=UDim2.fromOffset(10,0)
    verLbl.BackgroundTransparency=1; verLbl.Font=Enum.Font.Gotham
    verLbl.TextSize=10; verLbl.TextColor3=T.TextMute
    verLbl.TextXAlignment=Enum.TextXAlignment.Left; verLbl.Text=self.Version; verLbl.ZIndex=4

    -- kullanıcı (sağ)
    local userLbl=Instance.new("TextLabel",topbar)
    userLbl.Size=UDim2.new(0,160,1,0); userLbl.Position=UDim2.new(1,-230,0,0)
    userLbl.BackgroundTransparency=1; userLbl.Font=Enum.Font.GothamMedium
    userLbl.TextSize=11; userLbl.TextColor3=T.TextDim
    userLbl.TextXAlignment=Enum.TextXAlignment.Right; userLbl.Text=LocalPlayer.Name; userLbl.ZIndex=4

    -- kontrol butonları
    local ctrlH=Instance.new("Frame",topbar)
    ctrlH.Name="CtrlHolder"; ctrlH.Size=UDim2.fromOffset(64,36)
    ctrlH.Position=UDim2.new(1,-64,0,0); ctrlH.BackgroundTransparency=1; ctrlH.BorderSizePixel=0

    local function mkCtrl(char, xPos, hoverCol, onClick)
        local btn=Instance.new("TextButton",ctrlH)
        btn.Size=UDim2.fromOffset(24,22); btn.Position=UDim2.new(0,xPos,0.5,-11)
        btn.BackgroundColor3=T.Element; btn.BorderSizePixel=0
        btn.Font=Enum.Font.GothamBold; btn.TextSize=11
        btn.TextColor3=T.TextDim; btn.Text=char; btn.AutoButtonColor=false
        local s=Instance.new("UIStroke",btn); s.Color=T.Border; s.Thickness=1
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
        btn.MouseEnter:Connect(function() tw(btn,0.12,{BackgroundColor3=hoverCol,TextColor3=T.Text}) end)
        btn.MouseLeave:Connect(function() tw(btn,0.12,{BackgroundColor3=T.Element,TextColor3=T.TextDim}) end)
        btn.MouseButton1Click:Connect(onClick); return btn
    end
    mkCtrl("—",4,  T.ElementHov,              function() if self._body then self._body.Visible=not self._body.Visible end end)
    mkCtrl("✕",34, Color3.fromRGB(190,42,42), function() self:Destroy() end)

    -- sürükleme
    local dragging,dragStart,startPos=false,nil,nil
    topbar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=i.Position; startPos=mf.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    topbar.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-dragStart
            mf.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)

    -- tab bar
    local tabBar=Instance.new("Frame",ra)
    tabBar.Name="TabBar"; tabBar.Size=UDim2.new(1,0,0,28)
    tabBar.Position=UDim2.fromOffset(0,36)
    tabBar.BackgroundColor3=T.Surface; tabBar.BorderSizePixel=0; tabBar.ZIndex=3
    local tbBarLine=Instance.new("Frame",tabBar)
    tbBarLine.Size=UDim2.new(1,0,0,1); tbBarLine.Position=UDim2.new(0,0,1,-1)
    tbBarLine.BackgroundColor3=T.BorderLight; tbBarLine.BorderSizePixel=0; tbBarLine.ZIndex=4

    local tabList=Instance.new("Frame",tabBar)
    tabList.Name="TabList"; tabList.Size=UDim2.new(1,0,1,0)
    tabList.BackgroundTransparency=1
    local tabLayout=Instance.new("UIListLayout",tabList)
    tabLayout.FillDirection=Enum.FillDirection.Horizontal
    tabLayout.SortOrder=Enum.SortOrder.LayoutOrder
    tabLayout.Padding=UDim.new(0,0)
    tabLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    self.TabBar=tabBar; self.TabList=tabList

    -- içerik alanı
    local body=Instance.new("Frame",ra)
    body.Name="Body"; body.Size=UDim2.new(1,-12,1,-72)
    body.Position=UDim2.fromOffset(6,66)
    body.BackgroundTransparency=1; body.ClipsDescendants=true
    self._body=body

    -- gizle/göster
    UserInputService.InputBegan:Connect(function(inp,gp)
        if not gp and inp.KeyCode==self.ToggleKey then mf.Visible=not mf.Visible end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- CreateTab
-- ─────────────────────────────────────────────────────────────────
function Library:CreateTab(name)
    local Tab={Name=name,_lib=self,Active=false}

    -- sidebar nav butonu
    local sbBtn=Instance.new("TextButton",self._sbNav)
    sbBtn.Name="SbBtn_"..name; sbBtn.Size=UDim2.new(1,0,0,26)
    sbBtn.BackgroundColor3=T.Element; sbBtn.BackgroundTransparency=1
    sbBtn.BorderSizePixel=0; sbBtn.Font=Enum.Font.GothamMedium
    sbBtn.TextSize=12; sbBtn.TextColor3=T.TextDim
    sbBtn.TextXAlignment=Enum.TextXAlignment.Left; sbBtn.Text="  "..name
    sbBtn.AutoButtonColor=false; sbBtn.LayoutOrder=#self.Tabs+1
    Instance.new("UICorner",sbBtn).CornerRadius=UDim.new(0,4)

    -- aktif sol çizgi göstergesi
    local sbInd=Instance.new("Frame",sbBtn)
    sbInd.Size=UDim2.fromOffset(3,16); sbInd.Position=UDim2.new(0,0,0.5,-8)
    sbInd.BackgroundColor3=self.Accent; sbInd.BorderSizePixel=0
    sbInd.BackgroundTransparency=1; sbInd.ZIndex=5
    Instance.new("UICorner",sbInd).CornerRadius=UDim.new(1,0)
    self:_onAccent(function(c) if Tab.Active then sbInd.BackgroundColor3=c end end)

    -- tab bar butonu (yatay bar)
    local btn=Instance.new("TextButton",self.TabList)
    btn.Name="Tab_"..name; btn.Size=UDim2.new(0,0,1,0)
    btn.AutomaticSize=Enum.AutomaticSize.X
    btn.BackgroundTransparency=1; btn.BorderSizePixel=0
    btn.Font=Enum.Font.GothamMedium; btn.TextSize=12
    btn.TextColor3=T.TextDim; btn.Text="  "..name.."  "
    btn.AutoButtonColor=false

    local uline=Instance.new("Frame",btn)
    uline.Size=UDim2.new(1,0,0,2); uline.Position=UDim2.new(0,0,1,-2)
    uline.BackgroundColor3=self.Accent; uline.BackgroundTransparency=1; uline.BorderSizePixel=0
    self:_onAccent(function(c) if Tab.Active then uline.BackgroundColor3=c end end)

    -- badge
    local badge=Instance.new("Frame",btn)
    badge.Size=UDim2.fromOffset(15,15); badge.Position=UDim2.new(1,-3,0,-4)
    badge.AnchorPoint=Vector2.new(0.5,0.5); badge.BackgroundColor3=self.Accent
    badge.BorderSizePixel=0; badge.Visible=false; badge.ZIndex=10
    Instance.new("UICorner",badge).CornerRadius=UDim.new(1,0)
    self:_onAccent(function(c) badge.BackgroundColor3=c end)
    local badgeLbl=Instance.new("TextLabel",badge)
    badgeLbl.Size=UDim2.new(1,0,1,0); badgeLbl.BackgroundTransparency=1
    badgeLbl.Font=Enum.Font.GothamBold; badgeLbl.TextSize=8
    badgeLbl.TextColor3=T.AccentText; badgeLbl.Text=""; badgeLbl.ZIndex=11

    function Tab:SetBadge(n)
        if n and n>0 then badgeLbl.Text=n>99 and "99+" or tostring(n); badge.Visible=true
        else badge.Visible=false; badgeLbl.Text="" end
    end
    function Tab:ClearBadge() Tab:SetBadge(0) end

    -- sayfa (iki kolon)
    local page=Instance.new("Frame",self._body)
    page.Name="Page_"..name; page.Size=UDim2.new(1,0,1,0)
    page.BackgroundTransparency=1; page.Visible=false; page.ClipsDescendants=true

    local leftScroll=Instance.new("ScrollingFrame",page)
    leftScroll.Name="LeftCol"; leftScroll.Size=UDim2.new(0.5,-4,1,0)
    leftScroll.BackgroundTransparency=1; leftScroll.ScrollBarThickness=3
    leftScroll.ScrollBarImageColor3=T.BorderLight; leftScroll.BorderSizePixel=0
    leftScroll.CanvasSize=UDim2.new(0,0,0,0); leftScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    local lPad=Instance.new("UIPadding",leftScroll)
    lPad.PaddingTop=UDim.new(0,6); lPad.PaddingBottom=UDim.new(0,6)
    lPad.PaddingLeft=UDim.new(0,0); lPad.PaddingRight=UDim.new(0,2)
    local lLayout=Instance.new("UIListLayout",leftScroll)
    lLayout.SortOrder=Enum.SortOrder.LayoutOrder; lLayout.Padding=UDim.new(0,6)

    local rightScroll=Instance.new("ScrollingFrame",page)
    rightScroll.Name="RightCol"; rightScroll.Size=UDim2.new(0.5,-4,1,0)
    rightScroll.Position=UDim2.new(0.5,8,0,0)
    rightScroll.BackgroundTransparency=1; rightScroll.ScrollBarThickness=3
    rightScroll.ScrollBarImageColor3=T.BorderLight; rightScroll.BorderSizePixel=0
    rightScroll.CanvasSize=UDim2.new(0,0,0,0); rightScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    local rPad=Instance.new("UIPadding",rightScroll)
    rPad.PaddingTop=UDim.new(0,6); rPad.PaddingBottom=UDim.new(0,6)
    rPad.PaddingLeft=UDim.new(0,2); rPad.PaddingRight=UDim.new(0,0)
    local rLayout=Instance.new("UIListLayout",rightScroll)
    rLayout.SortOrder=Enum.SortOrder.LayoutOrder; rLayout.Padding=UDim.new(0,6)

    -- mobile layout
    local cam=workspace.CurrentCamera
    local function checkMobile()
        local mobile=cam.ViewportSize.X<600
        if mobile then
            leftScroll.Size=UDim2.new(1,0,1,0); rightScroll.Visible=false
            for _,c in ipairs(rightScroll:GetChildren()) do
                if c:IsA("Frame") and c.Name:sub(1,4)=="Sec_" then c.Parent=leftScroll end
            end
        else
            leftScroll.Size=UDim2.new(0.5,-4,1,0); rightScroll.Visible=true
        end
    end
    checkMobile()
    cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if page.Visible then checkMobile() end
    end)

    Tab._page=page; Tab._left=leftScroll; Tab._right=rightScroll
    Tab._btn=btn; Tab._sbBtn=sbBtn; Tab._uline=uline
    Tab._checkMobile=checkMobile

    function Tab:Activate()
        for _,t in ipairs(self._lib.Tabs) do t:Deactivate() end
        Tab.Active=true; page.Visible=true
        -- tab bar butonu
        tw(btn,0.15,{TextColor3=T.Accent})
        tw(uline,0.15,{BackgroundTransparency=0,BackgroundColor3=self._lib.Accent})
        -- sidebar butonu
        tw(sbBtn,0.15,{BackgroundTransparency=0.75,BackgroundColor3=self._lib.Accent,TextColor3=T.Text})
        tw(sbInd,0.15,{BackgroundTransparency=0})
        self._lib.ActiveTab=Tab; Tab._checkMobile()
    end

    function Tab:Deactivate()
        Tab.Active=false; page.Visible=false
        tw(btn,0.15,{TextColor3=T.TextDim})
        tw(uline,0.15,{BackgroundTransparency=1})
        tw(sbBtn,0.15,{BackgroundTransparency=1,TextColor3=T.TextDim})
        tw(sbInd,0.15,{BackgroundTransparency=1})
    end

    btn.MouseButton1Click:Connect(function() Tab:Activate() end)
    sbBtn.MouseButton1Click:Connect(function() Tab:Activate() end)
    btn.MouseEnter:Connect(function() if not Tab.Active then tw(btn,0.1,{TextColor3=T.Text}) end end)
    btn.MouseLeave:Connect(function() if not Tab.Active then tw(btn,0.1,{TextColor3=T.TextDim}) end end)
    sbBtn.MouseEnter:Connect(function() if not Tab.Active then tw(sbBtn,0.1,{BackgroundTransparency=0.9,TextColor3=T.Text,BackgroundColor3=T.Element}) end end)
    sbBtn.MouseLeave:Connect(function() if not Tab.Active then tw(sbBtn,0.1,{BackgroundTransparency=1,TextColor3=T.TextDim}) end end)

    table.insert(self.Tabs,Tab)
    if #self.Tabs==1 then Tab:Activate() end

    function Tab:CreateSection(title, col)
        return Library._createSection(self._lib, title, col=="right" and self._right or self._left)
    end

    return Tab
end

-- ─────────────────────────────────────────────────────────────────
-- Section
-- ─────────────────────────────────────────────────────────────────
function Library:_createSection(title, parent)
    local Section={_lib=self,_parent=parent}

    local card=Instance.new("Frame",parent)
    card.Name="Sec_"..title; card.Size=UDim2.new(1,0,0,0)
    card.AutomaticSize=Enum.AutomaticSize.Y; card.BackgroundColor3=T.Card
    card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,4)
    local cStroke=Instance.new("UIStroke",card); cStroke.Color=T.Border; cStroke.Thickness=1
    local pad=Instance.new("UIPadding",card)
    pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,8)
    pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8)
    local layout=Instance.new("UIListLayout",card)
    layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,4)

    -- başlık satırı (collapse destekli)
    local hdrBtn=Instance.new("TextButton",card)
    hdrBtn.Name="Header"; hdrBtn.Size=UDim2.new(1,0,0,18)
    hdrBtn.BackgroundTransparency=1; hdrBtn.BorderSizePixel=0
    hdrBtn.Text=""; hdrBtn.AutoButtonColor=false; hdrBtn.LayoutOrder=0

    local hdrTick=Instance.new("Frame",hdrBtn)
    hdrTick.Size=UDim2.fromOffset(2,11); hdrTick.Position=UDim2.new(0,0,0.5,-5)
    hdrTick.BackgroundColor3=self.Accent; hdrTick.BorderSizePixel=0
    Instance.new("UICorner",hdrTick).CornerRadius=UDim.new(1,0)
    self:_onAccent(function(c) hdrTick.BackgroundColor3=c end)

    local hdrLbl=Instance.new("TextLabel",hdrBtn)
    hdrLbl.Size=UDim2.new(1,-22,1,0); hdrLbl.Position=UDim2.fromOffset(8,0)
    hdrLbl.BackgroundTransparency=1; hdrLbl.Font=Enum.Font.GothamBold
    hdrLbl.TextSize=9; hdrLbl.TextColor3=T.TextMute
    hdrLbl.TextXAlignment=Enum.TextXAlignment.Left; hdrLbl.Text=string.upper(title)

    local colArrow=Instance.new("TextLabel",hdrBtn)
    colArrow.Size=UDim2.fromOffset(12,18); colArrow.Position=UDim2.new(1,-12,0,0)
    colArrow.BackgroundTransparency=1; colArrow.Font=Enum.Font.GothamBold
    colArrow.TextSize=7; colArrow.TextColor3=T.TextMute; colArrow.Text="▲"

    local sep=Instance.new("Frame",card)
    sep.Name="HeaderSep"; sep.Size=UDim2.new(1,0,0,1)
    sep.BackgroundColor3=T.Border; sep.BorderSizePixel=0; sep.LayoutOrder=1

    -- collapse
    local collapsed=false
    local function setCollapsed(val)
        collapsed=val; colArrow.Text=val and "▼" or "▲"
        for _,c in ipairs(card:GetChildren()) do
            if c~=hdrBtn and c~=sep and not c:IsA("UIListLayout")
               and not c:IsA("UIPadding") and not c:IsA("UIStroke") and not c:IsA("UICorner") then
                c.Visible=not val
            end
        end
        if val then
            card.AutomaticSize=Enum.AutomaticSize.None; tw(card,0.18,{Size=UDim2.new(1,0,0,30)})
        else
            task.delay(0.2,function() card.AutomaticSize=Enum.AutomaticSize.Y; card.Size=UDim2.new(1,0,0,0) end)
        end
    end

    hdrBtn.MouseButton1Click:Connect(function() setCollapsed(not collapsed) end)
    hdrBtn.MouseEnter:Connect(function() tw(hdrLbl,0.1,{TextColor3=T.TextDim}) end)
    hdrBtn.MouseLeave:Connect(function() tw(hdrLbl,0.1,{TextColor3=T.TextMute}) end)

    function Section:Collapse() setCollapsed(true) end
    function Section:Expand()   setCollapsed(false) end

    Section._card=card; Section._lib=self; Section._order=2
    local function nextOrder() Section._order=Section._order+1; return Section._order end

    -- ── Toggle ────────────────────────────────────
    function Section:CreateToggle(config)
        local ttl=config.Title or "Toggle"; local state=config.Default or false
        local cb=config.Callback or function()end; local bindKey=config.Keybind or nil
        local Toggle={State=state}

        local row=Instance.new("TextButton",card)
        row.Name="Toggle_"..ttl; row.Size=UDim2.new(1,0,0,22)
        row.BackgroundTransparency=1; row.Text=""; row.AutoButtonColor=false; row.LayoutOrder=nextOrder()

        -- küçük kare checkbox (resimdeki gibi)
        local box=Instance.new("Frame",row)
        box.Size=UDim2.fromOffset(12,12); box.Position=UDim2.new(0,0,0.5,-6)
        box.BackgroundColor3=state and self._lib.Accent or T.Element; box.BorderSizePixel=0
        Instance.new("UICorner",box).CornerRadius=UDim.new(0,2)
        local boxStroke=Instance.new("UIStroke",box)
        boxStroke.Color=state and self._lib.Accent or T.BorderLight; boxStroke.Thickness=1
        local tick=Instance.new("TextLabel",box)
        tick.Size=UDim2.new(1,0,1,0); tick.BackgroundTransparency=1
        tick.Font=Enum.Font.GothamBold; tick.TextSize=8
        tick.TextColor3=T.AccentText; tick.Text="✓"; tick.Visible=state

        local lbl=Instance.new("TextLabel",row)
        lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.fromOffset(18,0)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham
        lbl.TextSize=11; lbl.TextColor3=state and T.Text or T.TextDim
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=ttl

        local valLbl=Instance.new("TextLabel",row)
        valLbl.Size=UDim2.new(0,40,1,0); valLbl.Position=UDim2.new(1,-40,0,0)
        valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.Gotham
        valLbl.TextSize=9; valLbl.TextColor3=T.TextMute
        valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=""

        self._lib:_onAccent(function(c)
            if Toggle.State then box.BackgroundColor3=c; boxStroke.Color=c end
        end)

        function Toggle:Set(val)
            Toggle.State=val; tick.Visible=val
            box.BackgroundColor3=val and self._lib.Accent or T.Element
            boxStroke.Color=val and self._lib.Accent or T.BorderLight
            tw(lbl,0.1,{TextColor3=val and T.Text or T.TextDim}); pcall(cb,val)
        end
        Toggle._lib=self._lib

        row.MouseButton1Click:Connect(function() Toggle:Set(not Toggle.State) end)
        row.MouseEnter:Connect(function() tw(lbl,0.1,{TextColor3=T.Text}) end)
        row.MouseLeave:Connect(function() if not Toggle.State then tw(lbl,0.1,{TextColor3=T.TextDim}) end end)

        if bindKey then
            valLbl.Text="["..bindKey.Name.."]"
            UserInputService.InputBegan:Connect(function(inp,gp)
                if not gp and inp.KeyCode==bindKey then Toggle:Set(not Toggle.State) end
            end)
        end

        if config.ConfigKey then
            self._lib:_regElement(config.ConfigKey,
                function() return tostring(Toggle.State) end,
                function(v) Toggle:Set(v=="true") end)
        end
        return Toggle
    end

    -- ── Slider ────────────────────────────────────
    function Section:CreateSlider(config)
        local ttl=config.Title or "Slider"; local min=config.Min or 0; local max=config.Max or 100
        local def=math.clamp(config.Default or min,min,max); local decs=config.Decimals or 0
        local suffix=config.Suffix or ""; local cb=config.Callback or function()end
        local Slider={Value=def}

        local container=Instance.new("Frame",card)
        container.Name="Slider_"..ttl; container.Size=UDim2.new(1,0,0,30)
        container.BackgroundTransparency=1; container.LayoutOrder=nextOrder()

        local headerRow=Instance.new("Frame",container)
        headerRow.Size=UDim2.new(1,0,0,14); headerRow.BackgroundTransparency=1

        local lbl=Instance.new("TextLabel",headerRow)
        lbl.Size=UDim2.new(1,-55,1,0); lbl.BackgroundTransparency=1
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.TextDim
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=ttl

        local valLbl=Instance.new("TextLabel",headerRow)
        valLbl.Size=UDim2.new(0,55,1,0); valLbl.Position=UDim2.new(1,-55,0,0)
        valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.GothamBold
        valLbl.TextSize=10; valLbl.TextColor3=T.Text
        valLbl.TextXAlignment=Enum.TextXAlignment.Right
        valLbl.Text=string.format("%."..decs.."f/%d%s",def,max,suffix)

        local trackHolder=Instance.new("TextButton",container)
        trackHolder.Size=UDim2.new(1,0,0,5); trackHolder.Position=UDim2.fromOffset(0,18)
        trackHolder.BackgroundColor3=T.Element; trackHolder.BorderSizePixel=0
        trackHolder.Text=""; trackHolder.AutoButtonColor=false
        Instance.new("UICorner",trackHolder).CornerRadius=UDim.new(1,0)
        local tStroke=Instance.new("UIStroke",trackHolder); tStroke.Color=T.Border; tStroke.Thickness=1

        local fill=Instance.new("Frame",trackHolder)
        fill.Size=UDim2.new((def-min)/(max-min),0,1,0)
        fill.BackgroundColor3=self._lib.Accent; fill.BorderSizePixel=0
        Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
        self._lib:_onAccent(function(c) fill.BackgroundColor3=c end)

        local knob=Instance.new("Frame",fill)
        knob.Size=UDim2.fromOffset(7,7); knob.Position=UDim2.new(1,-3,0.5,-3)
        knob.BackgroundColor3=T.Text; knob.BorderSizePixel=0
        Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

        local function update(input)
            local px=input.Position.X-trackHolder.AbsolutePosition.X
            local pct=math.clamp(px/trackHolder.AbsoluteSize.X,0,1)
            local raw=min+(max-min)*pct
            local val=tonumber(string.format("%."..decs.."f",raw))
            Slider.Value=val; valLbl.Text=string.format("%."..decs.."f/%d%s",val,max,suffix)
            tw(fill,0.04,{Size=UDim2.new(pct,0,1,0)}); pcall(cb,val)
        end

        function Slider:Set(val)
            val=math.clamp(val,min,max); Slider.Value=val
            valLbl.Text=string.format("%."..decs.."f/%d%s",val,max,suffix)
            tw(fill,0.12,{Size=UDim2.new((val-min)/(max-min),0,1,0)}); pcall(cb,val)
        end

        local drag=false
        trackHolder.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; update(i) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i) end
        end)

        if config.ConfigKey then
            self._lib:_regElement(config.ConfigKey,
                function() return tostring(Slider.Value) end,
                function(v) Slider:Set(tonumber(v) or Slider.Value) end)
        end
        return Slider
    end

    -- ── Dropdown ──────────────────────────────────
    function Section:CreateDropdown(config)
        local ttl=config.Title or "Dropdown"; local opts=config.Options or {}
        local sel=config.Default or opts[1] or ""; local cb=config.Callback or function()end
        local DD={Selected=sel,Opened=false,Options=opts}

        local container=Instance.new("Frame",card)
        container.Name="DD_"..ttl; container.Size=UDim2.new(1,0,0,20)
        container.BackgroundTransparency=1; container.ClipsDescendants=false; container.LayoutOrder=nextOrder()

        local header=Instance.new("TextButton",container)
        header.Size=UDim2.new(1,0,0,20); header.BackgroundColor3=T.Element
        header.BorderSizePixel=0; header.Text=""; header.AutoButtonColor=false; header.ZIndex=3
        Instance.new("UICorner",header).CornerRadius=UDim.new(0,3)
        local hStroke=Instance.new("UIStroke",header); hStroke.Color=T.Border; hStroke.Thickness=1

        local hLbl=Instance.new("TextLabel",header)
        hLbl.Size=UDim2.new(0.5,0,1,0); hLbl.Position=UDim2.fromOffset(6,0)
        hLbl.BackgroundTransparency=1; hLbl.Font=Enum.Font.Gotham
        hLbl.TextSize=10; hLbl.TextColor3=T.TextDim
        hLbl.TextXAlignment=Enum.TextXAlignment.Left; hLbl.Text=ttl

        local valLbl=Instance.new("TextLabel",header)
        valLbl.Size=UDim2.new(0.44,-20,1,0); valLbl.Position=UDim2.new(0.5,0,0,0)
        valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.GothamMedium
        valLbl.TextSize=10; valLbl.TextColor3=T.Text
        valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(sel)
        valLbl.TextTruncate=Enum.TextTruncate.AtEnd

        local arrow=Instance.new("TextLabel",header)
        arrow.Size=UDim2.fromOffset(14,20); arrow.Position=UDim2.new(1,-16,0,0)
        arrow.BackgroundTransparency=1; arrow.Font=Enum.Font.GothamBold
        arrow.TextSize=7; arrow.TextColor3=T.TextMute; arrow.Text="▼"

        local listFrame=Instance.new("Frame",container)
        listFrame.Name="List"; listFrame.Size=UDim2.new(1,0,0,0)
        listFrame.Position=UDim2.fromOffset(0,22); listFrame.BackgroundColor3=T.Element
        listFrame.BorderSizePixel=0; listFrame.ClipsDescendants=true; listFrame.ZIndex=10; listFrame.Visible=false
        Instance.new("UICorner",listFrame).CornerRadius=UDim.new(0,3)
        local lStroke=Instance.new("UIStroke",listFrame); lStroke.Color=T.BorderLight; lStroke.Thickness=1; lStroke.ZIndex=10
        local listLayout=Instance.new("UIListLayout",listFrame); listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,1)
        local lPad2=Instance.new("UIPadding",listFrame); lPad2.PaddingTop=UDim.new(0,2); lPad2.PaddingBottom=UDim.new(0,2)

        local function buildList()
            for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,opt in ipairs(DD.Options) do
                local ob=Instance.new("TextButton",listFrame)
                ob.Size=UDim2.new(1,0,0,18); ob.BorderSizePixel=0
                ob.BackgroundColor3=opt==DD.Selected and self._lib.Accent or T.Element
                ob.BackgroundTransparency=opt==DD.Selected and 0.4 or 0.95
                ob.Font=Enum.Font.Gotham; ob.TextSize=10
                ob.TextColor3=opt==DD.Selected and T.Text or T.TextDim
                ob.TextXAlignment=Enum.TextXAlignment.Left; ob.Text="  "..tostring(opt)
                ob.AutoButtonColor=false; ob.ZIndex=11
                Instance.new("UICorner",ob).CornerRadius=UDim.new(0,2)
                ob.MouseEnter:Connect(function() if opt~=DD.Selected then tw(ob,0.1,{BackgroundTransparency=0.7,TextColor3=T.Text}) end end)
                ob.MouseLeave:Connect(function() if opt~=DD.Selected then tw(ob,0.1,{BackgroundTransparency=0.95,TextColor3=T.TextDim}) end end)
                ob.MouseButton1Click:Connect(function() DD:Set(opt); DD:Close() end)
            end
            listFrame.Size=UDim2.new(1,0,0,listLayout.AbsoluteContentSize.Y+4)
        end

        function DD:Open()
            DD.Opened=true; listFrame.Visible=true; buildList()
            tw(arrow,0.15,{Rotation=180}); tw(hStroke,0.15,{Color=self._lib and self._lib.Accent or T.Accent})
        end
        DD._lib=self._lib
        function DD:Close()
            DD.Opened=false; tw(arrow,0.15,{Rotation=0}); tw(hStroke,0.15,{Color=T.Border})
            task.delay(0.15,function() if not DD.Opened then listFrame.Visible=false end end)
        end
        function DD:Set(opt)
            DD.Selected=opt; valLbl.Text=tostring(opt); buildList(); pcall(cb,opt)
        end
        function DD:Refresh(newOpts) DD.Options=newOpts or {}; buildList() end

        header.MouseButton1Click:Connect(function() if DD.Opened then DD:Close() else DD:Open() end end)

        if config.ConfigKey then
            self._lib:_regElement(config.ConfigKey,
                function() return tostring(DD.Selected) end,
                function(v) DD:Set(v) end)
        end
        return DD
    end

    -- ── MultiDropdown ─────────────────────────────
    function Section:CreateMultiDropdown(config)
        local ttl=config.Title or "MultiDropdown"; local opts=config.Options or {}
        local defs=config.Default or {}; local maxShow=config.MaxShow or 2
        local cb=config.Callback or function()end
        local selected={}
        for _,v in ipairs(defs) do selected[v]=true end
        local MDD={Selected=selected,Opened=false,Options=opts}

        local function summary()
            local keys={}; for k in pairs(selected) do table.insert(keys,k) end; table.sort(keys)
            if #keys==0 then return "None" end
            if #keys<=maxShow then return table.concat(keys,", ") end
            return keys[1]..", +"..tostring(#keys-1)
        end

        local container=Instance.new("Frame",card)
        container.Name="MDD_"..ttl; container.Size=UDim2.new(1,0,0,20)
        container.BackgroundTransparency=1; container.ClipsDescendants=false; container.LayoutOrder=nextOrder()

        local header=Instance.new("TextButton",container)
        header.Size=UDim2.new(1,0,0,20); header.BackgroundColor3=T.Element
        header.BorderSizePixel=0; header.Text=""; header.AutoButtonColor=false; header.ZIndex=3
        Instance.new("UICorner",header).CornerRadius=UDim.new(0,3)
        local hStroke=Instance.new("UIStroke",header); hStroke.Color=T.Border; hStroke.Thickness=1

        local hLbl=Instance.new("TextLabel",header)
        hLbl.Size=UDim2.new(0.46,0,1,0); hLbl.Position=UDim2.fromOffset(6,0)
        hLbl.BackgroundTransparency=1; hLbl.Font=Enum.Font.Gotham; hLbl.TextSize=10
        hLbl.TextColor3=T.TextDim; hLbl.TextXAlignment=Enum.TextXAlignment.Left; hLbl.Text=ttl

        local valLbl=Instance.new("TextLabel",header)
        valLbl.Size=UDim2.new(0.44,-20,1,0); valLbl.Position=UDim2.new(0.48,0,0,0)
        valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.GothamMedium; valLbl.TextSize=10
        valLbl.TextColor3=T.Text; valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=summary()
        valLbl.TextTruncate=Enum.TextTruncate.AtEnd

        local arrow=Instance.new("TextLabel",header)
        arrow.Size=UDim2.fromOffset(14,20); arrow.Position=UDim2.new(1,-16,0,0)
        arrow.BackgroundTransparency=1; arrow.Font=Enum.Font.GothamBold
        arrow.TextSize=7; arrow.TextColor3=T.TextMute; arrow.Text="▼"

        local listFrame=Instance.new("Frame",container)
        listFrame.Name="List"; listFrame.Size=UDim2.new(1,0,0,0)
        listFrame.Position=UDim2.fromOffset(0,22); listFrame.BackgroundColor3=T.Element
        listFrame.BorderSizePixel=0; listFrame.ClipsDescendants=true; listFrame.ZIndex=10; listFrame.Visible=false
        Instance.new("UICorner",listFrame).CornerRadius=UDim.new(0,3)
        local lStroke=Instance.new("UIStroke",listFrame); lStroke.Color=T.BorderLight; lStroke.Thickness=1; lStroke.ZIndex=10
        local listLayout=Instance.new("UIListLayout",listFrame); listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,1)
        local lPad2=Instance.new("UIPadding",listFrame); lPad2.PaddingTop=UDim.new(0,2); lPad2.PaddingBottom=UDim.new(0,2)

        local function buildList()
            for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,opt in ipairs(MDD.Options) do
                local isSel=selected[opt]==true
                local ob=Instance.new("TextButton",listFrame)
                ob.Size=UDim2.new(1,0,0,18); ob.BorderSizePixel=0
                ob.BackgroundColor3=isSel and self._lib.Accent or T.Element
                ob.BackgroundTransparency=isSel and 0.4 or 0.95
                ob.Font=Enum.Font.Gotham; ob.TextSize=10
                ob.TextColor3=isSel and T.Text or T.TextDim
                ob.TextXAlignment=Enum.TextXAlignment.Left; ob.Text="  "..tostring(opt)
                ob.AutoButtonColor=false; ob.ZIndex=11
                Instance.new("UICorner",ob).CornerRadius=UDim.new(0,2)
                local ck=Instance.new("TextLabel",ob); ck.Size=UDim2.fromOffset(16,18)
                ck.Position=UDim2.new(1,-18,0,0); ck.BackgroundTransparency=1
                ck.Font=Enum.Font.GothamBold; ck.TextSize=9; ck.ZIndex=12
                ck.TextColor3=self._lib.Accent; ck.Text=isSel and "✓" or ""
                ob.MouseButton1Click:Connect(function()
                    if selected[opt] then selected[opt]=nil else selected[opt]=true end
                    valLbl.Text=summary(); buildList()
                    local res={}; for k in pairs(selected) do table.insert(res,k) end; pcall(cb,res)
                end)
            end
            listFrame.Size=UDim2.new(1,0,0,listLayout.AbsoluteContentSize.Y+4)
        end

        function MDD:Open() MDD.Opened=true; listFrame.Visible=true; buildList(); tw(arrow,0.15,{Rotation=180}); tw(hStroke,0.15,{Color=self._lib and self._lib.Accent or T.Accent}) end
        MDD._lib=self._lib
        function MDD:Close() MDD.Opened=false; tw(arrow,0.15,{Rotation=0}); tw(hStroke,0.15,{Color=T.Border}); task.delay(0.15,function() if not MDD.Opened then listFrame.Visible=false end end) end
        function MDD:Set(tbl) selected={}; for _,v in ipairs(tbl) do selected[v]=true end; valLbl.Text=summary(); buildList(); local r={}; for k in pairs(selected) do table.insert(r,k) end; pcall(cb,r) end
        function MDD:GetSelected() local r={}; for k in pairs(selected) do table.insert(r,k) end; return r end
        function MDD:Refresh(newOpts) MDD.Options=newOpts or {}; buildList() end

        header.MouseButton1Click:Connect(function() if MDD.Opened then MDD:Close() else MDD:Open() end end)

        if config.ConfigKey then
            self._lib:_regElement(config.ConfigKey,
                function() local r=MDD:GetSelected(); table.sort(r); return table.concat(r,",") end,
                function(v) local t={}; if v and v~="" then for p in (v..","):gmatch("(.-),") do table.insert(t,p) end end; MDD:Set(t) end)
        end
        return MDD
    end

    -- ── Textbox ───────────────────────────────────
    function Section:CreateTextbox(config)
        local ttl=config.Title or "Textbox"; local ph=config.Placeholder or "..."
        local def=config.Default or ""; local cb=config.Callback or function()end
        local Tb={Text=def}

        local row=Instance.new("Frame",card)
        row.Name="TB_"..ttl; row.Size=UDim2.new(1,0,0,20)
        row.BackgroundTransparency=1; row.LayoutOrder=nextOrder()

        local lbl=Instance.new("TextLabel",row)
        lbl.Size=UDim2.new(0.42,0,1,0); lbl.BackgroundTransparency=1
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.TextDim
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=ttl

        local iFrame=Instance.new("Frame",row)
        iFrame.Size=UDim2.new(0.58,-2,1,-2); iFrame.Position=UDim2.new(0.42,2,0,1)
        iFrame.BackgroundColor3=T.Element; iFrame.BorderSizePixel=0
        Instance.new("UICorner",iFrame).CornerRadius=UDim.new(0,3)
        local ifStroke=Instance.new("UIStroke",iFrame); ifStroke.Color=T.Border; ifStroke.Thickness=1

        local input=Instance.new("TextBox",iFrame)
        input.Size=UDim2.new(1,-6,1,0); input.Position=UDim2.fromOffset(3,0)
        input.BackgroundTransparency=1; input.Font=Enum.Font.Gotham; input.TextSize=10
        input.TextColor3=T.Text; input.PlaceholderColor3=T.TextMute; input.PlaceholderText=ph
        input.Text=def; input.ClearTextOnFocus=false

        input.Focused:Connect(function() tw(ifStroke,0.15,{Color=self._lib.Accent}) end)
        input.FocusLost:Connect(function(enter) tw(ifStroke,0.15,{Color=T.Border}); Tb.Text=input.Text; pcall(cb,input.Text,enter) end)

        function Tb:Set(txt) input.Text=txt; Tb.Text=txt end
        return Tb
    end

    -- ── Keybind ───────────────────────────────────
    function Section:CreateKeybind(config)
        local ttl=config.Title or "Keybind"; local defK=config.Default or Enum.KeyCode.None
        local cb=config.Callback or function()end; local Kb={Key=defK,Listening=false}

        local row=Instance.new("Frame",card)
        row.Name="KB_"..ttl; row.Size=UDim2.new(1,0,0,20)
        row.BackgroundTransparency=1; row.LayoutOrder=nextOrder()

        local lbl=Instance.new("TextLabel",row)
        lbl.Size=UDim2.new(1,-76,1,0); lbl.BackgroundTransparency=1
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.TextDim
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=ttl

        local kBtn=Instance.new("TextButton",row)
        kBtn.Size=UDim2.fromOffset(70,16); kBtn.Position=UDim2.new(1,-70,0.5,-8)
        kBtn.BackgroundColor3=T.Element; kBtn.BorderSizePixel=0
        kBtn.Font=Enum.Font.GothamBold; kBtn.TextSize=9
        kBtn.TextColor3=T.TextDim; kBtn.Text="["..defK.Name.."]"; kBtn.AutoButtonColor=false
        Instance.new("UICorner",kBtn).CornerRadius=UDim.new(0,3)
        local kbStroke=Instance.new("UIStroke",kBtn); kbStroke.Color=T.Border; kbStroke.Thickness=1

        kBtn.MouseButton1Click:Connect(function()
            if Kb.Listening then return end
            Kb.Listening=true; kBtn.Text="[...]"; tw(kbStroke,0.15,{Color=self._lib.Accent})
            local conn; conn=UserInputService.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Keyboard then
                    local k=i.KeyCode==Enum.KeyCode.Backspace and Enum.KeyCode.None or i.KeyCode
                    Kb.Key=k; kBtn.Text="["..k.Name.."]"; Kb.Listening=false
                    tw(kbStroke,0.15,{Color=T.Border}); conn:Disconnect(); pcall(cb,k)
                end
            end)
        end)
        function Kb:Set(k) Kb.Key=k; kBtn.Text="["..k.Name.."]" end
        return Kb
    end

    -- ── ColorPicker ───────────────────────────────
    function Section:CreateColorPicker(config)
        local ttl=config.Title or "Color"; local defC=config.Default or Color3.fromRGB(255,255,255)
        local cb=config.Callback or function()end
        local CP={Color=defC,Opened=false}
        local vals={math.floor(defC.R*255),math.floor(defC.G*255),math.floor(defC.B*255)}

        local container=Instance.new("Frame",card)
        container.Name="CP_"..ttl; container.Size=UDim2.new(1,0,0,20)
        container.BackgroundTransparency=1; container.ClipsDescendants=true; container.LayoutOrder=nextOrder()

        local header=Instance.new("TextButton",container)
        header.Size=UDim2.new(1,0,0,20); header.BackgroundTransparency=1
        header.Text=""; header.AutoButtonColor=false

        local lbl=Instance.new("TextLabel",header)
        lbl.Size=UDim2.new(1,-34,1,0); lbl.BackgroundTransparency=1
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.TextDim
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=ttl

        local preview=Instance.new("Frame",header)
        preview.Size=UDim2.fromOffset(22,13); preview.Position=UDim2.new(1,-24,0.5,-6)
        preview.BackgroundColor3=defC; preview.BorderSizePixel=0
        Instance.new("UICorner",preview).CornerRadius=UDim.new(0,3)
        local prevStroke=Instance.new("UIStroke",preview); prevStroke.Color=T.BorderLight; prevStroke.Thickness=1

        local panel=Instance.new("Frame",container)
        panel.Size=UDim2.new(1,0,0,66); panel.Position=UDim2.fromOffset(0,22)
        panel.BackgroundColor3=T.Element; panel.BorderSizePixel=0; panel.Visible=false
        Instance.new("UICorner",panel).CornerRadius=UDim.new(0,3)
        local panStroke=Instance.new("UIStroke",panel); panStroke.Color=T.Border; panStroke.Thickness=1
        local panPad=Instance.new("UIPadding",panel)
        panPad.PaddingLeft=UDim.new(0,6); panPad.PaddingRight=UDim.new(0,6)
        panPad.PaddingTop=UDim.new(0,4); panPad.PaddingBottom=UDim.new(0,4)
        local panLayout=Instance.new("UIListLayout",panel); panLayout.SortOrder=Enum.SortOrder.LayoutOrder; panLayout.Padding=UDim.new(0,4)

        local channels={{name="R",color=Color3.fromRGB(220,60,60),val=vals[1]},{name="G",color=Color3.fromRGB(60,200,80),val=vals[2]},{name="B",color=Color3.fromRGB(60,130,255),val=vals[3]}}
        for i,ch in ipairs(channels) do
            local row2=Instance.new("Frame",panel); row2.Size=UDim2.new(1,0,0,15); row2.BackgroundTransparency=1; row2.LayoutOrder=i
            local cLbl=Instance.new("TextLabel",row2); cLbl.Size=UDim2.fromOffset(10,15); cLbl.BackgroundTransparency=1
            cLbl.Font=Enum.Font.GothamBold; cLbl.TextSize=9; cLbl.TextColor3=ch.color; cLbl.Text=ch.name
            local tr=Instance.new("TextButton",row2); tr.Size=UDim2.new(1,-46,0,4); tr.Position=UDim2.new(0,14,0.5,-2)
            tr.BackgroundColor3=T.Card; tr.BorderSizePixel=0; tr.Text=""; tr.AutoButtonColor=false
            Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
            local fl=Instance.new("Frame",tr); fl.Size=UDim2.new(ch.val/255,0,1,0); fl.BackgroundColor3=ch.color; fl.BorderSizePixel=0
            Instance.new("UICorner",fl).CornerRadius=UDim.new(1,0)
            local nLbl=Instance.new("TextLabel",row2); nLbl.Size=UDim2.fromOffset(24,15); nLbl.Position=UDim2.new(1,-24,0,0)
            nLbl.BackgroundTransparency=1; nLbl.Font=Enum.Font.Gotham; nLbl.TextSize=9; nLbl.TextColor3=T.TextDim
            nLbl.TextXAlignment=Enum.TextXAlignment.Right; nLbl.Text=tostring(ch.val)
            local function notify() local col=Color3.fromRGB(vals[1],vals[2],vals[3]); CP.Color=col; preview.BackgroundColor3=col; pcall(cb,col) end
            local dragC=false
            local function upd(inp) local px=inp.Position.X-tr.AbsolutePosition.X; local pct=math.clamp(px/tr.AbsoluteSize.X,0,1); local v=math.floor(pct*255); vals[i]=v; fl.Size=UDim2.new(pct,0,1,0); nLbl.Text=tostring(v); notify() end
            tr.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragC=true; upd(inp) end end)
            UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragC=false end end)
            UserInputService.InputChanged:Connect(function(inp) if dragC and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then upd(inp) end end)
            ch._fill=fl; ch._nLbl=nLbl
        end

        function CP:Toggle() CP.Opened=not CP.Opened; panel.Visible=CP.Opened; container.Size=UDim2.new(1,0,0,CP.Opened and 90 or 20) end
        function CP:Set(col) CP.Color=col; vals[1]=math.floor(col.R*255); vals[2]=math.floor(col.G*255); vals[3]=math.floor(col.B*255); preview.BackgroundColor3=col; for i,ch in ipairs(channels) do ch._fill.Size=UDim2.new(vals[i]/255,0,1,0); ch._nLbl.Text=tostring(vals[i]) end; pcall(cb,col) end

        header.MouseButton1Click:Connect(function() CP:Toggle() end)
        return CP
    end

    -- ── Button ────────────────────────────────────
    function Section:CreateButton(config)
        local ttl=config.Title or "Button"; local cb=config.Callback or function()end

        local btn=Instance.new("TextButton",card)
        btn.Name="Btn_"..ttl; btn.Size=UDim2.new(1,0,0,22)
        btn.BackgroundColor3=T.Element; btn.BorderSizePixel=0
        btn.Font=Enum.Font.GothamMedium; btn.TextSize=11
        btn.TextColor3=T.Text; btn.Text=ttl; btn.AutoButtonColor=false
        btn.ClipsDescendants=true; btn.LayoutOrder=nextOrder()
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,3)
        local bStroke=Instance.new("UIStroke",btn); bStroke.Color=T.Border; bStroke.Thickness=1

        btn.MouseEnter:Connect(function() tw(btn,0.1,{BackgroundColor3=T.ElementHov,BorderSizePixel=0}) end)
        btn.MouseLeave:Connect(function() tw(btn,0.1,{BackgroundColor3=T.Element}) end)
        btn.MouseButton1Down:Connect(function() tw(btn,0.08,{BackgroundColor3=self._lib.Accent,TextColor3=T.AccentText}); ripple(btn,self._lib.Accent) end)
        btn.MouseButton1Up:Connect(function() tw(btn,0.15,{BackgroundColor3=T.Element,TextColor3=T.Text}) end)
        btn.MouseButton1Click:Connect(function() pcall(cb) end)
        return btn
    end

    -- ── Label ─────────────────────────────────────
    function Section:CreateLabel(text, col)
        local lbl=Instance.new("TextLabel",card)
        lbl.Size=UDim2.new(1,0,0,14); lbl.BackgroundTransparency=1
        lbl.Font=Enum.Font.Gotham; lbl.TextSize=10
        lbl.TextColor3=col or T.TextDim; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.Text=text; lbl.TextWrapped=true; lbl.LayoutOrder=nextOrder()
        return lbl
    end

    -- ── Separator ─────────────────────────────────
    function Section:CreateSeparator()
        local s=Instance.new("Frame",card); s.Size=UDim2.new(1,0,0,1)
        s.BackgroundColor3=T.Border; s.BorderSizePixel=0; s.LayoutOrder=nextOrder()
    end

    return Section
end

-- ─────────────────────────────────────────────────────────────────
-- Config Save / Load
-- ─────────────────────────────────────────────────────────────────
local function _serialize(tbl)
    local parts={}; for k,v in pairs(tbl) do table.insert(parts,tostring(k).."\31"..tostring(v)) end
    return table.concat(parts,"\30")
end
local function _deserialize(str)
    local tbl={}; if not str or str=="" then return tbl end
    for entry in (str.."\30"):gmatch("(.-)\30") do
        local k,v=entry:match("^(.-)\31(.*)$"); if k then tbl[k]=v end
    end
    return tbl
end

function Library:SaveConfig(name)
    name=(name or "default"):gsub("[^%w_%-]","_")
    local data={}
    for key,elem in pairs(self._configElements) do
        local ok,val=pcall(elem.get); if ok then data[key]=val end
    end
    local fname="HutameHub_"..name..".cfg"
    local ok=pcall(writefile,fname,_serialize(data))
    if ok then self:Notify({Title="Config Saved",Text=fname,Type="success",Duration=2.5})
    else self:Notify({Title="Config Error",Text="writefile not available.",Type="error",Duration=3}) end
end

function Library:LoadConfig(name)
    name=(name or "default"):gsub("[^%w_%-]","_")
    local fname="HutameHub_"..name..".cfg"
    local ok,content=pcall(readfile,fname)
    if not ok or not content then self:Notify({Title="Config Error",Text=fname.." not found.",Type="error",Duration=3}); return end
    local data=_deserialize(content); local loaded=0
    for key,elem in pairs(self._configElements) do
        if data[key]~=nil then pcall(elem.set,data[key]); loaded=loaded+1 end
    end
    self:Notify({Title="Config Loaded",Text=loaded.." values restored.",Type="success",Duration=2.5})
end

-- ─────────────────────────────────────────────────────────────────
-- Notification System
-- ─────────────────────────────────────────────────────────────────
function Library:_initNotify()
    if self._notifyReady then return end
    self._notifyReady=true
    local holder=Instance.new("Frame",self.ScreenGui)
    holder.Name="NotifyHolder"; holder.Size=UDim2.fromOffset(260,600)
    holder.Position=UDim2.new(1,-268,1,-8); holder.AnchorPoint=Vector2.new(0,1)
    holder.BackgroundTransparency=1; holder.BorderSizePixel=0
    local hLayout=Instance.new("UIListLayout",holder)
    hLayout.SortOrder=Enum.SortOrder.LayoutOrder; hLayout.VerticalAlignment=Enum.VerticalAlignment.Bottom; hLayout.Padding=UDim.new(0,6)
    self._notifyHolder=holder
end

function Library:Notify(config)
    self:_initNotify(); config=config or {}
    local title=config.Title or "Notification"; local text=config.Text or ""
    local duration=config.Duration or 3; local ntype=config.Type or "info"
    local typeColors={info=self.Accent,success=Color3.fromRGB(34,197,94),error=Color3.fromRGB(210,48,48),warning=Color3.fromRGB(240,160,30)}
    local accent=typeColors[ntype] or self.Accent
    local TOAST_H=text~="" and 50 or 34

    local toast=Instance.new("Frame",self._notifyHolder)
    toast.Name="Toast"; toast.Size=UDim2.fromOffset(0,TOAST_H)
    toast.BackgroundColor3=T.Card; toast.BorderSizePixel=0; toast.ClipsDescendants=true
    toast.LayoutOrder=os.clock()*1000
    Instance.new("UICorner",toast).CornerRadius=UDim.new(0,5)
    local tStroke=Instance.new("UIStroke",toast); tStroke.Color=T.Border; tStroke.Thickness=1

    local bar=Instance.new("Frame",toast); bar.Size=UDim2.new(0,3,1,0); bar.BackgroundColor3=accent; bar.BorderSizePixel=0
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,5)

    local icons={info="ℹ",success="✓",error="✕",warning="⚠"}
    local iconLbl=Instance.new("TextLabel",toast); iconLbl.Size=UDim2.fromOffset(20,TOAST_H); iconLbl.Position=UDim2.fromOffset(10,0)
    iconLbl.BackgroundTransparency=1; iconLbl.Font=Enum.Font.GothamBold; iconLbl.TextSize=12; iconLbl.TextColor3=accent; iconLbl.Text=icons[ntype] or "ℹ"

    local titleLbl=Instance.new("TextLabel",toast)
    titleLbl.Size=UDim2.new(1,-50,0,TOAST_H); titleLbl.Position=UDim2.fromOffset(32,0)
    titleLbl.BackgroundTransparency=1; titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextSize=11
    titleLbl.TextColor3=T.Text; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Text=title

    if text~="" then
        titleLbl.Size=UDim2.new(1,-50,0,20)
        local bodyLbl=Instance.new("TextLabel",toast); bodyLbl.Size=UDim2.new(1,-50,0,14); bodyLbl.Position=UDim2.fromOffset(32,20)
        bodyLbl.BackgroundTransparency=1; bodyLbl.Font=Enum.Font.Gotham; bodyLbl.TextSize=10
        bodyLbl.TextColor3=T.TextDim; bodyLbl.TextXAlignment=Enum.TextXAlignment.Left; bodyLbl.Text=text; bodyLbl.TextTruncate=Enum.TextTruncate.AtEnd
    end

    local closeBtn=Instance.new("TextButton",toast); closeBtn.Size=UDim2.fromOffset(14,14); closeBtn.Position=UDim2.new(1,-18,0,8)
    closeBtn.BackgroundTransparency=1; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=9
    closeBtn.TextColor3=T.TextMute; closeBtn.Text="✕"; closeBtn.AutoButtonColor=false
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3=T.Text end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3=T.TextMute end)

    local prog=Instance.new("Frame",toast); prog.Size=UDim2.new(1,0,0,2); prog.Position=UDim2.new(0,0,1,-2)
    prog.BackgroundColor3=accent; prog.BackgroundTransparency=0.5; prog.BorderSizePixel=0

    tw(toast,0.25,{Size=UDim2.fromOffset(258,TOAST_H)})
    tw(prog,duration,{Size=UDim2.new(0,0,0,2)})

    local function dismiss()
        tw(toast,0.2,{BackgroundTransparency=1,Size=UDim2.fromOffset(258,0)})
        task.delay(0.25,function() pcall(function() toast:Destroy() end) end)
    end
    closeBtn.MouseButton1Click:Connect(dismiss)
    task.delay(duration,function() if toast and toast.Parent then dismiss() end end)
end

-- ─────────────────────────────────────────────────────────────────
-- Watermark
-- ─────────────────────────────────────────────────────────────────
function Library:SetWatermark(config)
    config=config or {}; local fmt=config.Format or "{player}  |  {fps} fps"
    local pos=config.Position or "TopRight"; local bgAlpha=config.BgAlpha or 0.45
    if self._wmFrame then self._wmFrame:Destroy() end

    local wm=Instance.new("Frame",self.ScreenGui); wm.Name="Watermark"
    wm.Size=UDim2.fromOffset(0,22); wm.AutomaticSize=Enum.AutomaticSize.X
    wm.BackgroundColor3=T.Surface; wm.BackgroundTransparency=bgAlpha; wm.BorderSizePixel=0
    Instance.new("UICorner",wm).CornerRadius=UDim.new(0,4)
    local wmStroke=Instance.new("UIStroke",wm); wmStroke.Color=T.Border; wmStroke.Thickness=1
    local wmPad=Instance.new("UIPadding",wm)
    wmPad.PaddingLeft=UDim.new(0,9); wmPad.PaddingRight=UDim.new(0,9)

    local anchors={TopLeft={UDim2.fromOffset(10,10),Vector2.new(0,0)},TopRight={UDim2.new(1,-10,0,10),Vector2.new(1,0)},BottomLeft={UDim2.new(0,10,1,-10),Vector2.new(0,1)},BottomRight={UDim2.new(1,-10,1,-10),Vector2.new(1,1)}}
    local pd=anchors[pos] or anchors.TopRight; wm.Position=pd[1]; wm.AnchorPoint=pd[2]

    local lbl=Instance.new("TextLabel",wm); lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11
    lbl.TextColor3=T.Text; lbl.RichText=true; lbl.AutomaticSize=Enum.AutomaticSize.X; lbl.Text=fmt

    self:_onAccent(function(c) wmStroke.Color=c end)
    self._wmFrame=wm; self._wmFmt=fmt

    local fps,lastTick,frames=60,os.clock(),0
    local fpsConn=RunService.RenderStepped:Connect(function()
        frames=frames+1; local now=os.clock()
        if now-lastTick>=0.5 then fps=math.floor(frames/(now-lastTick)+0.5); frames=0; lastTick=now end
    end)

    local wmConn=RunService.Heartbeat:Connect(function()
        if not wm or not wm.Parent then return end
        local h=math.floor(os.clock()/3600%24); local m=math.floor(os.clock()/60%60); local s=math.floor(os.clock()%60)
        local ping=0; pcall(function() ping=game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
        local r=self._wmFmt or fmt
        r=r:gsub("{player}",LocalPlayer.Name):gsub("{fps}",tostring(fps)):gsub("{ping}",tostring(math.floor(ping))):gsub("{time}",string.format("%02d:%02d:%02d",h,m,s)):gsub("{game}",tostring(game.Name))
        local fCol=fps>=50 and "7ee787" or fps>=30 and "f5c542" or "ff7b72"
        r=r:gsub(tostring(fps).." fps",string.format('<font color="#%s">%d fps</font>',fCol,fps))
        lbl.Text=r
    end)

    if self._wmConn then self._wmConn:Disconnect() end
    if self._fpsConn then self._fpsConn:Disconnect() end
    self._wmConn=wmConn; self._fpsConn=fpsConn
end

function Library:UpdateWatermark(newFmt) self._wmFmt=newFmt end
function Library:RemoveWatermark()
    if self._wmFrame then self._wmFrame:Destroy(); self._wmFrame=nil end
    if self._wmConn  then self._wmConn:Disconnect();  self._wmConn=nil end
    if self._fpsConn then self._fpsConn:Disconnect(); self._fpsConn=nil end
end

-- ─────────────────────────────────────────────────────────────────
-- Destroy
-- ─────────────────────────────────────────────────────────────────
function Library:Destroy()
    self:RemoveWatermark()
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

function Library:SetTitle(title, version)
    self.Title=title or self.Title; self.Version=version or self.Version
end

return Library
