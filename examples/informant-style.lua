-- HutameHub v2.3: compact Informant-inspired two-column layout.
-- Uses only HutameHub's public API; run in a Roblox client environment.
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"
))()

local Hub = Library.new({
    Title = "HutameHub",
    Version = "v2.3",
    Accent = Color3.fromRGB(103, 89, 179),
    ToggleKey = Enum.KeyCode.RightControl,
    SnowEffect = false,
})

local Main = Hub:CreateTab("Main")
local Visuals = Main:CreateSection("Visuals", "left")
local Actions = Main:CreateSection("Actions", "right")

Visuals:CreateToggle({
    Title = "Show overlay", Default = false,
    Callback = function(enabled) print("Overlay:", enabled) end,
})
Visuals:CreateSlider({
    Title = "Opacity", Min = 0, Max = 100, Default = 75, Suffix = "%",
    Callback = function(value) print("Opacity:", value) end,
})
Visuals:CreateDropdown({
    Title = "Style", Options = {"Classic", "Compact", "Minimal"},
    Default = "Compact", MaxVisibleItems = 3,
    Callback = function(value) print("Style:", value) end,
})
Actions:CreateButton({
    Title = "Show notification",
    Callback = function()
        Hub:Notify({Title = "HutameHub", Text = "Theme preview", Type = "info"})
    end,
})
Actions:CreateLabel("RightControl or Minus shows and hides the window.")

-- The same methods and property names work with any Accent Color3.
