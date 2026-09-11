-- HutameHub: manual UI feature test (Source.lua API)
-- Run in a client environment that supports the loader below.
-- Config tests additionally require writefile/readfile.
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"
))()

local Hub = Library.new({
    Title = "HutameHub UI Test",
    Version = "API test",
    Accent = Color3.fromRGB(220, 50, 50),
    ToggleKey = Enum.KeyCode.RightControl,
    LoadingScreen = true,
    LoadingDuration = 1.8,
    SnowEffect = true,
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
    Title = "Test text", Default = "Hello", Placeholder = "Type here",
    Tooltip = "Callback runs when focus is lost.",
    Callback = function(text, enterPressed)
        report("Text", text)
        report("Enter pressed", enterPressed)
    end,
})
local Keybind = Inputs:CreateKeybind({
    Title = "Select a key", Default = Enum.KeyCode.G,
    Tooltip = "Click then press a key; Backspace clears it.",
    -- This callback reports a NEW binding, not each key press.
    Callback = function(key) report("Selected key", key.Name) end,
})
local Color = Inputs:CreateColorPicker({
    Title = "Accent", Default = Color3.fromRGB(220, 50, 50),
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

-- Save -> change the four ConfigKey controls -> Load -> inspect restored values.
-- Textbox, Keybind and ColorPicker are not registered by Source.lua config save.
-- RightControl hides/shows the window; F toggles the test checkbox.
-- Hover a control for 0.4 seconds to inspect its tooltip.
-- To compare startup effects, change LoadingScreen/SnowEffect above and run
-- in a fresh session. SnowEffect controls main-window snow only.
