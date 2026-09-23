-- HutameHub v2.3: manual UI feature test (Source.lua API)
-- Run in a client environment that supports the loader below.
-- Config tests additionally require writefile/readfile.
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"
))()

local Hub = Library.new({
    Title = "HutameHub UI Test",
    Version = "v2.3",
    Accent = Color3.fromRGB(103, 89, 179),
    ToggleKey = Enum.KeyCode.RightControl,
    MobileToggle = true, -- Also show the draggable 48px button on desktop for testing.
    LoadingScreen = true,
    LoadingDuration = 1.8,
    SnowEffect = false,
})

local function report(name, value)
    print("[UI Test] " .. name, value)
end

local Controls = Hub:CreateTab("Controls")
local Features = Hub:CreateTab("Features")
Features:SetBadge(3)
local Inputs = Controls:CreateSection("Inputs", "left")
local Selection = Controls:CreateSection("Selection", "right")
local Actions = Features:CreateSection("Actions", "left")
local Preview = Features:CreateSection("Collapse target", "right")
Preview:CreateLabel("Collapse and expand this section.")
Preview:CreateSeparator()
Preview:CreateLabel("Drag the top bar; resize the viewport.")

local Toggle = Inputs:CreateToggle({
    Title = "Test toggle", Default = false, Keybind = Enum.KeyCode.F,
    ConfigKey = "test_toggle", Tooltip = "Click or press F outside a textbox.",
    Callback = function(value) report("Toggle", value) end,
})
local Slider = Inputs:CreateSlider({
    Title = "Test slider", Min = 0, Max = 100, Default = 25,
    Decimals = 1, Suffix = "%", ConfigKey = "test_slider",
    Tooltip = "Drag with mouse or touch; watch Output.",
    Callback = function(value) report("Slider", value) end,
})
local Textbox = Inputs:CreateTextbox({
    Title = "Test text", Default = "Hello", Placeholder = "Type here", ConfigKey = "test_text",
    Tooltip = "Callback runs when focus is lost.",
    Callback = function(text, enterPressed)
        report("Text", text)
        report("Enter pressed", enterPressed)
    end,
})
local Keybind = Inputs:CreateKeybind({
    Title = "Select a key", Default = Enum.KeyCode.G, ConfigKey = "test_key",
    Tooltip = "Click then press a key; Backspace clears it.",
    -- This callback reports a NEW binding, not each key press.
    Callback = function(key) report("Selected key", key.Name) end,
})
local Color = Inputs:CreateColorPicker({
    Title = "Accent", Default = Color3.fromRGB(103, 89, 179), ConfigKey = "test_color",
    Tooltip = "Open the RGB sliders and change the accent.",
    Callback = function(value) Hub:SetAccent(value) end,
})
local Dropdown = Selection:CreateDropdown({
    Title = "Single choice", Options = {"Alpha", "Beta", "Gamma"},
    Default = "Alpha", ConfigKey = "test_dropdown",
    Tooltip = "Choose one item.",
    Callback = function(value) report("Dropdown", value) end,
})
local Multi = Selection:CreateMultiDropdown({
    Title = "Multiple choices", Options = {"Red", "Green", "Blue"},
    Default = {"Red"}, MaxShow = 2, ConfigKey = "test_multi",
    Tooltip = "Select several items; selection stays open.",
    Callback = function(values) report("Multi", table.concat(values, ", ")) end,
})

-- Helper belongs to this example, not the library.
local function button(section, title, callback)
    section:CreateButton({Title = title, Tooltip = title, Callback = function()
        local ok, err = pcall(callback)
        if not ok then warn("[UI Test] " .. title .. ": " .. tostring(err)) end
    end})
end

button(Inputs, "Set values from code", function()
    Toggle:Set(true)
    Slider:Set(75.5)
    Textbox:Set("Set() worked") -- Does not invoke the textbox callback.
    Keybind:Set(Enum.KeyCode.H) -- Does not invoke the keybind callback.
    Color:Set(Color3.fromRGB(80, 160, 255))
    report("Textbox.Text", Textbox.Text)
    report("Keybind.Key", Keybind.Key.Name)
end)
button(Inputs, "Toggle RGB panel", function() Color:Toggle() end)
button(Selection, "Set selections", function()
    Dropdown:Set("Beta")
    Multi:Set({"Green", "Blue"})
    report("GetSelected", table.concat(Multi:GetSelected(), ", "))
end)
button(Selection, "Refresh options", function()
    Dropdown:Refresh({"Alpha", "Beta", "Gamma", "Delta"})
    Multi:Refresh({"Red", "Green", "Blue", "Yellow"})
end)
button(Selection, "Open single choice", function() Dropdown:Open() end)
button(Selection, "Close single choice", function() Dropdown:Close() end)
button(Selection, "Open multiple choices", function() Multi:Open() end)
button(Selection, "Close multiple choices", function() Multi:Close() end)
button(Selection, "Go to Features", function() Features:Activate() end)

for _, kind in ipairs({"info", "success", "warning", "error"}) do
    local notificationType = kind
    button(Actions, "Notify: " .. notificationType, function()
        Hub:Notify({Title = "UI Test", Text = notificationType,
            Type = notificationType, Duration = 3})
    end)
end
button(Actions, "Collapse target", function() Preview:Collapse() end)
button(Actions, "Expand target", function() Preview:Expand() end)
button(Actions, "Badge = 7", function() Features:SetBadge(7) end)
button(Actions, "Clear badge", function() Features:ClearBadge() end)
button(Actions, "Show watermark", function()
    Hub:SetWatermark({Format = "{player} | {fps} fps | {ping} ms | {time}",
        Position = "BottomRight", BgAlpha = 0.45})
end)
button(Actions, "Update watermark", function()
    Hub:UpdateWatermark("{game} | {fps} fps")
end)
button(Actions, "Remove watermark", function() Hub:RemoveWatermark() end)
button(Actions, "Save test config", function() Hub:SaveConfig("ui_test") end)
button(Actions, "Load test config", function() Hub:LoadConfig("ui_test") end)
button(Actions, "Read current values", function()
    report("Toggle.State", Toggle.State)
    report("Slider.Value", Slider.Value)
    report("Dropdown.Selected", Dropdown.Selected)
    report("Multi:GetSelected()", table.concat(Multi:GetSelected(), ", "))
    report("Color.Color", Color.Color)
end)
button(Actions, "Back to Controls", function() Controls:Activate() end)
button(Actions, "Destroy UI (test last)", function() Hub:Destroy() end)

-- Save -> change controls -> Load -> inspect all seven registered value types.
local Profiles = Hub:CreateTab("Profiles")
local Manager = Profiles:CreateSection("Profile manager", "left")
local Conditional = Profiles:CreateSection("Conditions and reset", "right")
local ProfileName = Manager:CreateTextbox({Title="Profile name", Default="demo"})
local RenameTo = Manager:CreateTextbox({Title="Rename to", Default="demo_copy"})
local ProfileList = Manager:CreateDropdown({Title="Saved profiles", Options=Hub:ListProfiles(),
    Callback=function(name) ProfileName:Set(name) end})
local function refreshProfiles() ProfileList:Refresh(Hub:ListProfiles()) end
local function result(ok, err)
    if not ok then Hub:Notify({Title="Profile error", Text=tostring(err), Type="error"}) end
    refreshProfiles()
end
button(Manager, "Create / save profile", function()
    Hub:Confirm({Title="Save profile", Text="Save current values? An existing profile will be overwritten.",
        OnConfirm=function() result(Hub:SaveProfile(ProfileName.Text)) end})
end)
button(Manager, "Load selected profile", function() result(Hub:LoadProfile(ProfileName.Text)) end)
button(Manager, "Rename profile", function() result(Hub:RenameProfile(ProfileName.Text, RenameTo.Text)) end)
button(Manager, "Set default profile", function() result(Hub:SetDefaultProfile(ProfileName.Text)) end)
button(Manager, "Load default profile", function() result(Hub:LoadDefaultProfile()) end)
button(Manager, "Delete profile", function()
    local name = ProfileName.Text
    Hub:Confirm({Title="Delete profile", Text="Permanently delete " .. name .. "?",
        OnConfirm=function() result(Hub:DeleteProfile(name)) end})
end)
local Advanced = Conditional:CreateToggle({Title="Show advanced controls", Default=false})
Conditional:CreateSlider({Title="Conditional slider", Min=0, Max=100, Default=50,
    VisibleWhen=function() return Advanced.State end})
Conditional:CreateButton({Title="Enabled when toggle is on",
    EnabledWhen=function() return Advanced.State end,
    Callback=function() report("Conditional button", "clicked") end})
button(Conditional, "Reset slider only", function() Slider:Reset() end)
button(Conditional, "Reset all values", function()
    Hub:Confirm({Title="Reset values", Text="Restore every control to its creation default?",
        OnConfirm=function() Hub:ResetValues() end})
end)
Conditional:CreateLabel("Bind Select a key to F or Minus for a warning.")
-- For automatic startup restore, call Hub:LoadDefaultProfile() HERE after creation.
local LayoutTests = Hub:CreateTab("Layout")
local Flow = LayoutTests:CreateSection("Dropdown followed by button", "left")
local LongOptions = {}
for i = 1, 20 do LongOptions[i] = "Option " .. i end
local FlowDropdown = Flow:CreateDropdown({Title="Scrollable single", Options=LongOptions, MaxVisibleItems=4})
button(Flow, "Button below single list", function() report("Flow", "Single button clicked") end)
local FlowMulti = Flow:CreateMultiDropdown({Title="Scrollable multi", Options=LongOptions, MaxVisibleItems=4})
button(Flow, "Button below multi list", function() report("Flow", "Multi button clicked") end)
local LayoutActions = LayoutTests:CreateSection("Animation checks", "right")
button(LayoutActions, "Collapse left section", function() Flow:Collapse() end)
button(LayoutActions, "Expand left section", function() Flow:Expand() end)
button(LayoutActions, "Shorten open list", function() FlowDropdown:Refresh({"One", "Two"}) end)
button(LayoutActions, "Restore 20 options", function() FlowDropdown:Refresh(LongOptions) end)
-- Open both lists: buttons must move DOWN, and every item must be scrollable.
-- Close lists: section shrinks. Rapidly alternate Collapse/Expand: last click wins.
-- RightControl or Minus (-) hides/shows the entire window; F toggles the checkbox.
-- Type a minus in the textbox: the UI must stay visible while typing.
-- Hover a control for 0.4 seconds to inspect its tooltip.
-- To compare startup effects, change LoadingScreen/SnowEffect above and run
-- in a fresh session. SnowEffect controls main-window snow only.
