--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     TOXIN UI LIBRARY                         ║
    ║        Modern, Lightweight & Custom Roblox Luau UI           ║
    ╚══════════════════════════════════════════════════════════════╝
    
    [Örnek Kullanım / Example Usage]
    
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))() -- veya yerel modül
    
    local Window = Library:CreateWindow({
        Title = "Toxin Premium",
        Subtitle = "v2.1",
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 255, 128),
        Size = UDim2.fromOffset(620, 420)
    })
    
    local MainTab = Window:CreateTab("Main", "rbxassetid://6031075931")
    local SettingsTab = Window:CreateTab("Settings", "rbxassetid://6031075931")
    
    local AimSection = MainTab:CreateSection("Combat Settings")
    
    AimSection:CreateToggle({
        Title = "Silent Aim",
        Default = false,
        Callback = function(state)
            print("Silent Aim:", state)
        end
    })
    
    AimSection:CreateSlider({
        Title = "FOV Radius",
        Min = 10,
        Max = 500,
        Default = 120,
        Decimals = 0,
        Callback = function(value)
            print("FOV:", value)
        end
    })
    
    AimSection:CreateDropdown({
        Title = "Target Hitbox",
        Options = {"Head", "Torso", "HumanoidRootPart", "Random"},
        Default = "Head",
        Callback = function(selected)
            print("Hitbox:", selected)
        end
    })
    
    local ConfigSection = SettingsTab:CreateSection("Preferences")
    
    ConfigSection:CreateTextbox({
        Title = "Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Default = "",
        Callback = function(text)
            print("Webhook set to:", text)
        end
    })
    
    ConfigSection:CreateKeybind({
        Title = "Toggle UI Key",
        Default = Enum.KeyCode.RightControl,
        Callback = function(key)
            print("New Keybind:", key.Name)
        end
    })
    
    ConfigSection:CreateColorPicker({
        Title = "Accent Color",
        Default = Color3.fromRGB(0, 255, 128),
        Callback = function(color)
            Window:SetAccent(color)
        end
    })
    
    ConfigSection:CreateButton({
        Title = "Destroy UI",
        Callback = function()
            Window:Destroy()
        end
    })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI Parent Koruması
local function getSafeGuiParent()
    local success, parent = pcall(function()
        return CoreGui
    end)
    if success and parent then
        return parent
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Yardımcı Animasyon Motoru
local function tween(object, info, properties)
    local tweenObj = TweenService:Create(object, info, properties)
    tweenObj:Play()
    return tweenObj
end

-- Tema Renk Sabitleri
local THEMES = {
    Dark = {
        Background = Color3.fromRGB(15, 15, 15),     -- #0F0F0F
        Sidebar = Color3.fromRGB(20, 20, 20),        -- #141414
        Card = Color3.fromRGB(25, 25, 25),           -- #191919
        Element = Color3.fromRGB(32, 32, 32),        -- #202020
        ElementHover = Color3.fromRGB(38, 38, 38),   -- #262626
        Border = Color3.fromRGB(42, 42, 42),         -- İnce Çerçeve
        TextPrimary = Color3.fromRGB(245, 245, 245),
        TextSecondary = Color3.fromRGB(160, 160, 160),
        TextMuted = Color3.fromRGB(100, 100, 100)
    }
}

local Library = {}
Library.__index = Library

-- Sürüklenebilir Pencere Mantığı (Mobil & PC Uyumlu)
local function makeDraggable(topbar, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local endPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            tween(mainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = endPos})
        end
    end)
end

-- ==============================================================================
-- 1. WINDOW OLUŞTURMA
-- ==============================================================================
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Toxin Hub"
    local subtitle = config.Subtitle or "UI"
    local accentColor = config.Accent or Color3.fromRGB(0, 255, 128)
    local theme = THEMES[config.Theme or "Dark"] or THEMES.Dark
    local windowSize = config.Size or UDim2.fromOffset(640, 430)

    local Window = {
        Theme = theme,
        Accent = accentColor,
        Tabs = {},
        ActiveTab = nil,
        AccentSubscribers = {}
    }
    setmetatable(Window, {__index = self})

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ToxinLib_" .. tostring(math.random(1000, 9999))
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = getSafeGuiParent()
    Window.ScreenGui = screenGui

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = windowSize
    mainFrame.Position = UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2)
    mainFrame.BackgroundColor3 = theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = screenGui
    Window.MainFrame = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = theme.Border
    mainStroke.Thickness = 1
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame

    -- Accent Glow Line (Pencerenin üstündeki ince vurgu çizgisi)
    local accentLine = Instance.new("Frame")
    accentLine.Name = "AccentLine"
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BackgroundColor3 = accentColor
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 5
    accentLine.Parent = mainFrame

    local lineCorner = Instance.new("UICorner")
    lineCorner.CornerRadius = UDim.new(0, 8)
    lineCorner.Parent = accentLine

    Window:RegisterAccent(function(col)
        accentLine.BackgroundColor3 = col
    end)

    -- Topbar (Başlık ve Sürükleme alanı)
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 42)
    topbar.BackgroundColor3 = theme.Background
    topbar.BorderSizePixel = 0
    topbar.Parent = mainFrame

    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 8)
    topCorner.Parent = topbar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -90, 1, 0)
    titleLabel.Position = UDim2.new(0, 16, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = theme.TextPrimary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.RichText = true
    titleLabel.Text = string.format('<b>%s</b> <font color="#%s">%s</font>', title, accentColor:ToHex(), subtitle)
    titleLabel.Parent = topbar

    Window:RegisterAccent(function(col)
        titleLabel.Text = string.format('<b>%s</b> <font color="#%s">%s</font>', title, col:ToHex(), subtitle)
    end)

    -- Kontrol Butonları (Minimize & Kapatma)
    local controlsHolder = Instance.new("Frame")
    controlsHolder.Name = "Controls"
    controlsHolder.Size = UDim2.new(0, 60, 1, 0)
    controlsHolder.Position = UDim2.new(1, -65, 0, 0)
    controlsHolder.BackgroundTransparency = 1
    controlsHolder.Parent = topbar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -26, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = theme.TextSecondary
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = controlsHolder

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 50, 50), TextColor3 = Color3.new(1, 1, 1)})
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = theme.TextSecondary})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)

    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinBtn"
    minBtn.Size = UDim2.new(0, 24, 0, 24)
    minBtn.Position = UDim2.new(1, -54, 0.5, -12)
    minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    minBtn.Text = "—"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 11
    minBtn.TextColor3 = theme.TextSecondary
    minBtn.BorderSizePixel = 0
    minBtn.Parent = controlsHolder

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 5)
    minCorner.Parent = minBtn

    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            tween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset, 0, 42)
            })
            Window.Container.Visible = false
            Window.Sidebar.Visible = false
        else
            tween(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = windowSize
            })
            task.delay(0.15, function()
                if not isMinimized then
                    Window.Container.Visible = true
                    Window.Sidebar.Visible = true
                end
            end)
        end
    end)

    makeDraggable(topbar, mainFrame)

    -- Sol Sidebar (Menü Sekmeleri İçin)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 150, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    Window.Sidebar = sidebar

    local sideCorner = Instance.new("UICorner")
    sideCorner.CornerRadius = UDim.new(0, 8)
    sideCorner.Parent = sidebar

    local sideBorder = Instance.new("Frame")
    sideBorder.Name = "BorderRight"
    sideBorder.Size = UDim2.new(0, 1, 1, 0)
    sideBorder.Position = UDim2.new(1, -1, 0, 0)
    sideBorder.BackgroundColor3 = theme.Border
    sideBorder.BorderSizePixel = 0
    sideBorder.Parent = sidebar

    local tabList = Instance.new("ScrollingFrame")
    tabList.Name = "TabList"
    tabList.Size = UDim2.new(1, -10, 1, -16)
    tabList.Position = UDim2.new(0, 5, 0, 8)
    tabList.BackgroundTransparency = 1
    tabList.ScrollBarThickness = 2
    tabList.ScrollBarImageColor3 = theme.Border
    tabList.BorderSizePixel = 0
    tabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabList.Parent = sidebar
    Window.TabList = tabList

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 5)
    tabListLayout.Parent = tabList

    -- Sağ Ana İçerik Alanı (Content Area)
    local container = Instance.new("Frame")
    container.Name = "ContentContainer"
    container.Size = UDim2.new(1, -155, 1, -48)
    container.Position = UDim2.new(0, 153, 0, 46)
    container.BackgroundTransparency = 1
    container.Parent = mainFrame
    Window.Container = container

    -- Toggle UI Tuşu (Varsayılan: Sağ Shift / RightControl)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.RightShift) then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    return Window
end

function Library:RegisterAccent(callback)
    table.insert(self.AccentSubscribers, callback)
end

function Library:SetAccent(color)
    self.Accent = color
    for _, callback in ipairs(self.AccentSubscribers) do
        pcall(callback, color)
    end
end

function Library:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- ==============================================================================
-- 2. TAB (SEKME) OLUŞTURMA
-- ==============================================================================
function Library:CreateTab(name, iconId)
    local Tab = {
        Name = name,
        Window = self,
        Sections = {},
        Active = false
    }

    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "TabBtn_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 34)
    tabBtn.BackgroundColor3 = self.Theme.Card
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = self.TabList

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = tabBtn

    -- Sol Kenar Gösterge Çizgisi (Aktifken renklenir)
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 18)
    indicator.Position = UDim2.new(0, 4, 0.5, -9)
    indicator.BackgroundColor3 = self.Accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    indicator.Parent = tabBtn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    self:RegisterAccent(function(col)
        if Tab.Active then
            indicator.BackgroundColor3 = col
        end
    end)

    -- Tab İkonu (Varsa)
    local offsetLabel = 14
    if iconId then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Position = UDim2.new(0, 12, 0.5, -8)
        icon.BackgroundTransparency = 1
        icon.Image = iconId
        icon.ImageColor3 = self.Theme.TextSecondary
        icon.Parent = tabBtn
        Tab.Icon = icon
        offsetLabel = 34
    end

    local tabText = Instance.new("TextLabel")
    tabText.Name = "Title"
    tabText.Size = UDim2.new(1, -offsetLabel - 5, 1, 0)
    tabText.Position = UDim2.new(0, offsetLabel, 0, 0)
    tabText.BackgroundTransparency = 1
    tabText.Font = Enum.Font.GothamMedium
    tabText.TextSize = 13
    tabText.TextColor3 = self.Theme.TextSecondary
    tabText.TextXAlignment = Enum.TextXAlignment.Left
    tabText.Text = name
    tabText.Parent = tabBtn

    -- Tab İçerik Sayfası (Scrolling Frame)
    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, -4, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = self.Theme.Border
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = self.Container
    Tab.Page = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 4)
    pagePadding.PaddingBottom = UDim.new(0, 10)
    pagePadding.PaddingLeft = UDim.new(0, 6)
    pagePadding.PaddingRight = UDim.new(0, 6)
    pagePadding.Parent = page

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 10)
    pageLayout.Parent = page

    -- Aktifleştirme Fonksiyonu
    function Tab:Activate()
        for _, otherTab in pairs(self.Window.Tabs) do
            otherTab:Deactivate()
        end
        Tab.Active = true
        page.Visible = true
        tween(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0, BackgroundColor3 = self.Window.Theme.Card})
        tween(indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0, BackgroundColor3 = self.Window.Accent})
        tween(tabText, TweenInfo.new(0.2), {TextColor3 = self.Window.Theme.TextPrimary})
        if Tab.Icon then
            tween(Tab.Icon, TweenInfo.new(0.2), {ImageColor3 = self.Window.Accent})
        end
        self.Window.ActiveTab = Tab
    end

    function Tab:Deactivate()
        Tab.Active = false
        page.Visible = false
        tween(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        tween(indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        tween(tabText, TweenInfo.new(0.2), {TextColor3 = self.Window.Theme.TextSecondary})
        if Tab.Icon then
            tween(Tab.Icon, TweenInfo.new(0.2), {ImageColor3 = self.Window.Theme.TextSecondary})
        end
    end

    tabBtn.MouseButton1Click:Connect(function()
        Tab:Activate()
    end)

    tabBtn.MouseEnter:Connect(function()
        if not Tab.Active then
            tween(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5, BackgroundColor3 = self.Theme.Card})
            tween(tabText, TweenInfo.new(0.2), {TextColor3 = self.Theme.TextPrimary})
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if not Tab.Active then
            tween(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            tween(tabText, TweenInfo.new(0.2), {TextColor3 = self.Theme.TextSecondary})
        end
    end)

    table.insert(self.Tabs, Tab)

    -- İlk eklenen sekme otomatik olarak aktif olur
    if #self.Tabs == 1 then
        Tab:Activate()
    end

    return setmetatable(Tab, {__index = Tab})
end

-- ==============================================================================
-- 3. SECTION (KATEGORİ / BÖLÜM) OLUŞTURMA
-- ==============================================================================
function Library:CreateSection(title)
    local Section = {
        Title = title,
        Tab = self,
        Window = self.Window or self
    }

    local sectionCard = Instance.new("Frame")
    sectionCard.Name = "Section_" .. title
    sectionCard.Size = UDim2.new(1, 0, 0, 0)
    sectionCard.AutomaticSize = Enum.AutomaticSize.Y
    sectionCard.BackgroundColor3 = Section.Window.Theme.Card
    sectionCard.BorderSizePixel = 0
    sectionCard.Parent = self.Page
    Section.Card = sectionCard

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = sectionCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Section.Window.Theme.Border
    cardStroke.Thickness = 1
    cardStroke.Parent = sectionCard

    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingTop = UDim.new(0, 10)
    cardPadding.PaddingBottom = UDim.new(0, 10)
    cardPadding.PaddingLeft = UDim.new(0, 12)
    cardPadding.PaddingRight = UDim.new(0, 12)
    cardPadding.Parent = sectionCard

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Padding = UDim.new(0, 8)
    cardLayout.Parent = sectionCard

    -- Section Başlığı
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 18)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 12
    header.TextColor3 = Section.Window.Theme.TextSecondary
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = string.upper(title)
    header.Parent = sectionCard

    return setmetatable(Section, {__index = Section})
end

-- ==============================================================================
-- 4. TOGGLE (AÇ / KAPA BUTONU)
-- ==============================================================================
function Library:CreateToggle(config)
    if type(config) == "string" then
        config = {Title = config}
    end
    local title = config.Title or "Toggle"
    local state = config.Default or false
    local callback = config.Callback or function() end
    local Window = self.Window

    local Toggle = {State = state}

    local container = Instance.new("TextButton")
    container.Name = "Toggle_" .. title
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Window.Theme.Element
    container.BorderSizePixel = 0
    container.Text = ""
    container.AutoButtonColor = false
    container.Parent = self.Card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Window.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Window.Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = title
    label.Parent = container

    -- Toggle Switch Pill (Arka plan kapsülü)
    local pill = Instance.new("Frame")
    pill.Name = "Pill"
    pill.Size = UDim2.new(0, 36, 0, 18)
    pill.Position = UDim2.new(1, -46, 0.5, -9)
    pill.BackgroundColor3 = state and Window.Accent or Color3.fromRGB(45, 45, 45)
    pill.BorderSizePixel = 0
    pill.Parent = container

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pill

    -- Kayan Yuvarlak Düğme (Knob)
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    function Toggle:Set(val)
        Toggle.State = val
        local targetPillColor = val and Window.Accent or Color3.fromRGB(45, 45, 45)
        local targetKnobPos = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)

        tween(pill, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundColor3 = targetPillColor})
        tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Position = targetKnobPos})

        pcall(callback, Toggle.State)
    end

    container.MouseButton1Click:Connect(function()
        Toggle:Set(not Toggle.State)
    end)

    container.MouseEnter:Connect(function()
        tween(container, TweenInfo.new(0.15), {BackgroundColor3 = Window.Theme.ElementHover})
    end)
    container.MouseLeave:Connect(function()
        tween(container, TweenInfo.new(0.15), {BackgroundColor3 = Window.Theme.Element})
    end)

    Window:RegisterAccent(function(col)
        if Toggle.State then
            pill.BackgroundColor3 = col
        end
    end)

    return Toggle
end

-- ==============================================================================
-- 5. SLIDER (KAYDIRICI)
-- ==============================================================================
function Library:CreateSlider(config)
    local title = config.Title or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = math.clamp(config.Default or min, min, max)
    local decimals = config.Decimals or 0
    local callback = config.Callback or function() end
    local Window = self.Window

    local Slider = {Value = default}

    local container = Instance.new("Frame")
    container.Name = "Slider_" .. title
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundColor3 = Window.Theme.Element
    container.BorderSizePixel = 0
    container.Parent = self.Card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Window.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -70, 0, 22)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Window.Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = title
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 60, 0, 22)
    valueLabel.Position = UDim2.new(1, -70, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 12
    valueLabel.TextColor3 = Window.Accent
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Text = string.format("%." .. decimals .. "f", default)
    valueLabel.Parent = container

    Window:RegisterAccent(function(col)
        valueLabel.TextColor3 = col
    end)

    -- Slider Track (Ray)
    local track = Instance.new("TextButton")
    track.Name = "Track"
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    -- Fill Bar (Dolu kısım)
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    local initialPercent = (default - min) / (max - min)
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = Window.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Handle / Knob (Tutamaç)
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(1, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = fill

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    Window:RegisterAccent(function(col)
        fill.BackgroundColor3 = col
    end)

    local function update(input)
        local posX = input.Position.X - track.AbsolutePosition.X
        local percent = math.clamp(posX / track.AbsoluteSize.X, 0, 1)
        local rawVal = min + (max - min) * percent
        local formattedVal = tonumber(string.format("%." .. decimals .. "f", rawVal))

        Slider.Value = formattedVal
        valueLabel.Text = tostring(formattedVal)
        tween(fill, TweenInfo.new(0.05), {Size = UDim2.new(percent, 0, 1, 0)})

        pcall(callback, formattedVal)
    end

    function Slider:Set(val)
        val = math.clamp(val, min, max)
        Slider.Value = val
        valueLabel.Text = string.format("%." .. decimals .. "f", val)
        local percent = (val - min) / (max - min)
        tween(fill, TweenInfo.new(0.15), {Size = UDim2.new(percent, 0, 1, 0)})
        pcall(callback, val)
    end

    local dragging = false

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    return Slider
end

-- ==============================================================================
-- 6. DROPDOWN (AÇILIR MENÜ)
-- ==============================================================================
function Library:CreateDropdown(config)
    local title = config.Title or "Dropdown"
    local options = config.Options or {}
    local selected = config.Default or (options[1] or "None")
    local callback = config.Callback or function() end
    local Window = self.Window

    local Dropdown = {
        Selected = selected,
        Opened = false,
        Options = options
    }

    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.AutomaticSize = Enum.AutomaticSize.None
    container.BackgroundColor3 = Window.Theme.Element
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = self.Card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Window.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = container

    -- Header Button
    local headerBtn = Instance.new("TextButton")
    headerBtn.Name = "Header"
    headerBtn.Size = UDim2.new(1, 0, 0, 36)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""
    headerBtn.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Window.Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = title
    label.Parent = headerBtn

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0.5, -35, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 12
    valueLabel.TextColor3 = Window.Theme.TextSecondary
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Text = tostring(selected)
    valueLabel.Parent = headerBtn

    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -26, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 11
    arrow.TextColor3 = Window.Theme.TextSecondary
    arrow.Text = "▼"
    arrow.Parent = headerBtn

    -- Seçenek Listesi
    local optionsHolder = Instance.new("Frame")
    optionsHolder.Name = "OptionsHolder"
    optionsHolder.Size = UDim2.new(1, -16, 0, 0)
    optionsHolder.Position = UDim2.new(0, 8, 0, 38)
    optionsHolder.BackgroundTransparency = 1
    optionsHolder.Parent = container

    local optLayout = Instance.new("UIListLayout")
    optLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optLayout.Padding = UDim.new(0, 4)
    optLayout.Parent = optionsHolder

    local function refreshOptions()
        for _, child in ipairs(optionsHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, opt in ipairs(Dropdown.Options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Name = "Option_" .. tostring(opt)
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.BackgroundColor3 = (opt == Dropdown.Selected) and Window.Accent or Color3.fromRGB(38, 38, 38)
            optBtn.BackgroundTransparency = (opt == Dropdown.Selected) and 0.2 or 0.6
            optBtn.BorderSizePixel = 0
            optBtn.Font = Enum.Font.GothamMedium
            optBtn.TextSize = 12
            optBtn.TextColor3 = (opt == Dropdown.Selected) and Color3.new(1, 1, 1) or Window.Theme.TextSecondary
            optBtn.Text = "  " .. tostring(opt)
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.Parent = optionsHolder

            local optCorner = Instance.new("UICorner")
            optCorner.CornerRadius = UDim.new(0, 4)
            optCorner.Parent = optBtn

            optBtn.MouseButton1Click:Connect(function()
                Dropdown:Set(opt)
                Dropdown:Toggle()
            end)
        end
    end

    function Dropdown:Toggle()
        Dropdown.Opened = not Dropdown.Opened
        local targetHeight = Dropdown.Opened and (42 + (#Dropdown.Options * 30)) or 36
        local arrowRot = Dropdown.Opened and 180 or 0

        tween(arrow, TweenInfo.new(0.2), {Rotation = arrowRot})
        tween(container, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetHeight)
        })
    end

    function Dropdown:Set(opt)
        Dropdown.Selected = opt
        valueLabel.Text = tostring(opt)
        refreshOptions()
        pcall(callback, opt)
    end

    function Dropdown:Refresh(newOptions)
        Dropdown.Options = newOptions or {}
        refreshOptions()
    end

    headerBtn.MouseButton1Click:Connect(function()
        Dropdown:Toggle()
    end)

    refreshOptions()
    return Dropdown
end

-- ==============================================================================
-- 7. TEXTBOX (METİN KUTUSU)
-- ==============================================================================
function Library:CreateTextbox(config)
    local title = config.Title or "Textbox"
    local placeholder = config.Placeholder or "Metin girin..."
    local default = config.Default or ""
    local callback = config.Callback or function() end
    local Window = self.Window

    local Textbox = {Text = default}

    local container = Instance.new("Frame")
    container.Name = "Textbox_" .. title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = Window.Theme.Element
    container.BorderSizePixel = 0
    container.Parent = self.Card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Window.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Window.Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = title
    label.Parent = container

    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "BoxFrame"
    boxFrame.Size = UDim2.new(0.55, 0, 0, 24)
    boxFrame.Position = UDim2.new(0.45, -5, 0.5, -12)
    boxFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    boxFrame.BorderSizePixel = 0
    boxFrame.Parent = container

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = boxFrame

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Window.Theme.Border
    boxStroke.Thickness = 1
    boxStroke.Parent = boxFrame

    local inputBox = Instance.new("TextBox")
    inputBox.Name = "Input"
    inputBox.Size = UDim2.new(1, -12, 1, 0)
    inputBox.Position = UDim2.new(0, 6, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 12
    inputBox.TextColor3 = Window.Theme.TextPrimary
    inputBox.PlaceholderColor3 = Window.Theme.TextMuted
    inputBox.PlaceholderText = placeholder
    inputBox.Text = default
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = boxFrame

    inputBox.Focused:Connect(function()
        tween(boxStroke, TweenInfo.new(0.2), {Color = Window.Accent})
    end)

    inputBox.FocusLost:Connect(function(enterPressed)
        tween(boxStroke, TweenInfo.new(0.2), {Color = Window.Theme.Border})
        Textbox.Text = inputBox.Text
        pcall(callback, inputBox.Text, enterPressed)
    end)

    function Textbox:Set(txt)
        inputBox.Text = txt
        Textbox.Text = txt
        pcall(callback, txt, false)
    end

    return Textbox
end

-- ==============================================================================
-- 8. KEYBIND (TUŞ ATAMA)
-- ==============================================================================
function Library:CreateKeybind(config)
    local title = config.Title or "Keybind"
    local defaultKey = config.Default or Enum.KeyCode.None
    local callback = config.Callback or function() end
    local Window = self.Window

    local Keybind = {
        Key = defaultKey,
        Listening = false
    }

    local container = Instance.new("Frame")
    container.Name = "Keybind_" .. title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = Window.Theme.Element
    container.BorderSizePixel = 0
    container.Parent = self.Card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Window.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Window.Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = title
    label.Parent = container

    local bindBtn = Instance.new("TextButton")
    bindBtn.Name = "BindBtn"
    bindBtn.Size = UDim2.new(0, 75, 0, 22)
    bindBtn.Position = UDim2.new(1, -85, 0.5, -11)
    bindBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    bindBtn.BorderSizePixel = 0
    bindBtn.Font = Enum.Font.GothamBold
    bindBtn.TextSize = 11
    bindBtn.TextColor3 = Window.Theme.TextSecondary
    bindBtn.Text = string.format("[ %s ]", defaultKey.Name or "None")
    bindBtn.Parent = container

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = bindBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Window.Theme.Border
    btnStroke.Thickness = 1
    btnStroke.Parent = bindBtn

    bindBtn.MouseButton1Click:Connect(function()
        if Keybind.Listening then return end
        Keybind.Listening = true
        bindBtn.Text = "[ ... ]"
        tween(btnStroke, TweenInfo.new(0.2), {Color = Window.Accent})
        tween(bindBtn, TweenInfo.new(0.2), {TextColor3 = Window.Accent})

        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local chosenKey = input.KeyCode
                if chosenKey == Enum.KeyCode.Backspace then
                    chosenKey = Enum.KeyCode.None
                end
                Keybind.Key = chosenKey
                bindBtn.Text = string.format("[ %s ]", chosenKey.Name)
                Keybind.Listening = false
                tween(btnStroke, TweenInfo.new(0.2), {Color = Window.Theme.Border})
                tween(bindBtn, TweenInfo.new(0.2), {TextColor3 = Window.Theme.TextSecondary})
                connection:Disconnect()
                pcall(callback, chosenKey)
            end
        end)
    end)

    function Keybind:Set(key)
        Keybind.Key = key
        bindBtn.Text = string.format("[ %s ]", key.Name)
        pcall(callback, key)
    end

    return Keybind
end

-- ==============================================================================
-- 9. COLOR PICKER (RENK SEÇİCİ)
-- ==============================================================================
function Library:CreateColorPicker(config)
    local title = config.Title or "Color Picker"
    local defaultColor = config.Default or Color3.fromRGB(255, 255, 255)
    local callback = config.Callback or function() end
    local Window = self.Window

    local ColorPicker = {
        Color = defaultColor,
        Opened = false
    }

    local container = Instance.new("Frame")
    container.Name = "ColorPicker_" .. title
    container.Size = UDim2.new(1, 0, 0, 36)
    container.AutomaticSize = Enum.AutomaticSize.None
    container.BackgroundColor3 = Window.Theme.Element
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = self.Card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Window.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = container

    -- Üst Bar
    local headerBtn = Instance.new("TextButton")
    headerBtn.Name = "Header"
    headerBtn.Size = UDim2.new(1, 0, 0, 36)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""
    headerBtn.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = Window.Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = title
    label.Parent = headerBtn

    -- Renk Önizleme Kutusu
    local previewBox = Instance.new("Frame")
    previewBox.Name = "Preview"
    previewBox.Size = UDim2.new(0, 24, 0, 18)
    previewBox.Position = UDim2.new(1, -38, 0.5, -9)
    previewBox.BackgroundColor3 = defaultColor
    previewBox.BorderSizePixel = 0
    previewBox.Parent = headerBtn

    local prevCorner = Instance.new("UICorner")
    prevCorner.CornerRadius = UDim.new(0, 4)
    prevCorner.Parent = previewBox

    local prevStroke = Instance.new("UIStroke")
    prevStroke.Color = Window.Theme.Border
    prevStroke.Thickness = 1
    prevStroke.Parent = previewBox

    -- RGB Kaydırıcılar Paneli
    local slidersHolder = Instance.new("Frame")
    slidersHolder.Name = "SlidersHolder"
    slidersHolder.Size = UDim2.new(1, -20, 0, 95)
    slidersHolder.Position = UDim2.new(0, 10, 0, 40)
    slidersHolder.BackgroundTransparency = 1
    slidersHolder.Parent = container

    local function createChannelSlider(channelName, channelColor, defaultVal, yPos, onChange)
        local cTrack = Instance.new("TextButton")
        cTrack.Name = channelName .. "Track"
        cTrack.Size = UDim2.new(1, -40, 0, 18)
        cTrack.Position = UDim2.new(0, 0, 0, yPos)
        cTrack.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        cTrack.BorderSizePixel = 0
        cTrack.Text = ""
        cTrack.AutoButtonColor = false
        cTrack.Parent = slidersHolder

        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 4)
        tCorner.Parent = cTrack

        local cFill = Instance.new("Frame")
        cFill.Name = "Fill"
        cFill.Size = UDim2.new(defaultVal / 255, 0, 1, 0)
        cFill.BackgroundColor3 = channelColor
        cFill.BorderSizePixel = 0
        cFill.Parent = cTrack

        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(0, 4)
        fCorner.Parent = cFill

        local cLabel = Instance.new("TextLabel")
        cLabel.Size = UDim2.new(0, 35, 0, 18)
        cLabel.Position = UDim2.new(1, -35, 0, yPos)
        cLabel.BackgroundTransparency = 1
        cLabel.Font = Enum.Font.GothamBold
        cLabel.TextSize = 11
        cLabel.TextColor3 = Window.Theme.TextSecondary
        cLabel.Text = tostring(math.floor(defaultVal))
        cLabel.Parent = slidersHolder

        local dragging = false
        local function update(input)
            local posX = input.Position.X - cTrack.AbsolutePosition.X
            local pct = math.clamp(posX / cTrack.AbsoluteSize.X, 0, 1)
            local val = math.floor(pct * 255)
            cFill.Size = UDim2.new(pct, 0, 1, 0)
            cLabel.Text = tostring(val)
            onChange(val)
        end

        cTrack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)

        return {
            Set = function(v)
                cFill.Size = UDim2.new(v / 255, 0, 1, 0)
                cLabel.Text = tostring(math.floor(v))
            end
        }
    end

    local rVal = math.floor(defaultColor.R * 255)
    local gVal = math.floor(defaultColor.G * 255)
    local bVal = math.floor(defaultColor.B * 255)

    local function notifyColor()
        local col = Color3.fromRGB(rVal, gVal, bVal)
        ColorPicker.Color = col
        previewBox.BackgroundColor3 = col
        pcall(callback, col)
    end

    local rSlider = createChannelSlider("R", Color3.fromRGB(255, 70, 70), rVal, 0, function(v)
        rVal = v
        notifyColor()
    end)
    local gSlider = createChannelSlider("G", Color3.fromRGB(70, 255, 70), gVal, 26, function(v)
        gVal = v
        notifyColor()
    end)
    local bSlider = createChannelSlider("B", Color3.fromRGB(70, 140, 255), bVal, 52, function(v)
        bVal = v
        notifyColor()
    end)

    function ColorPicker:Toggle()
        ColorPicker.Opened = not ColorPicker.Opened
        local targetHeight = ColorPicker.Opened and 125 or 36
        tween(container, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetHeight)
        })
    end

    function ColorPicker:Set(col)
        ColorPicker.Color = col
        rVal = math.floor(col.R * 255)
        gVal = math.floor(col.G * 255)
        bVal = math.floor(col.B * 255)
        rSlider.Set(rVal)
        gSlider.Set(gVal)
        bSlider.Set(bVal)
        previewBox.BackgroundColor3 = col
        pcall(callback, col)
    end

    headerBtn.MouseButton1Click:Connect(function()
        ColorPicker:Toggle()
    end)

    return ColorPicker
end

-- ==============================================================================
-- 10. BUTTON (STANDART ETKİLEŞİMLİ BUTON)
-- ==============================================================================
function Library:CreateButton(config)
    local title = config.Title or "Button"
    local callback = config.Callback or function() end
    local Window = self.Window

    local btn = Instance.new("TextButton")
    btn.Name = "Button_" .. title
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Window.Theme.Element
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextColor3 = Window.Theme.TextPrimary
    btn.Text = title
    btn.AutoButtonColor = false
    btn.Parent = self.Card

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Window.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Window.Theme.ElementHover})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Window.Theme.Element})
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, 30)})
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 32)})
    end)
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    return btn
end

return Library
