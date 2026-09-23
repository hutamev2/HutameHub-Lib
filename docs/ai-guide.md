# HutameHub: AI coding guide

Give an AI this URL when asking it to build a Roblox Luau UI:
`https://hutamev2.github.io/HutameHub-Lib/ai-guide.md`

This is a compact, self-contained guide to the current public API in `Source.lua` (v2.3). Generate HutameHub code using these exact method and property names. The library uses Roblox `Instance` objects, `Color3`, `Enum.KeyCode` and client-side UI services. Run the code in a Roblox client environment that supports the loader shown below.

## Copyable complete example

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"
))()

local Hub = Library.new({
    Title = "My Hub",
    Version = "v2.3",
    Accent = Color3.fromRGB(103, 89, 179),
    ToggleKey = Enum.KeyCode.RightControl,
    MobileToggle = true,
    SnowEffect = false,
})

local Main = Hub:CreateTab("Main")
local Settings = Hub:CreateTab("Settings")
local Controls = Main:CreateSection("Controls", "left")
local Actions = Main:CreateSection("Actions", "right")
local Preferences = Settings:CreateSection("Preferences", "left")

local Enabled = Controls:CreateToggle({
    Title = "Enabled", Default = false, ConfigKey = "enabled",
    Callback = function(value) print("Enabled:", value) end,
})

local Speed = Controls:CreateSlider({
    Title = "Speed", Min = 0, Max = 100, Default = 25,
    Decimals = 0, Suffix = "%", ConfigKey = "speed",
    EnabledWhen = function() return Enabled.State end,
    Callback = function(value) print("Speed:", value) end,
})

local Mode = Controls:CreateDropdown({
    Title = "Mode", Options = {"Normal", "Fast", "Safe"},
    Default = "Normal", MaxVisibleItems = 3, ConfigKey = "mode",
    Callback = function(value) print("Mode:", value) end,
})

Controls:CreateMultiDropdown({
    Title = "Targets", Options = {"A", "B", "C"},
    Default = {"A"}, ConfigKey = "targets",
    Callback = function(values) print(table.concat(values, ", ")) end,
})

Preferences:CreateTextbox({
    Title = "Nickname", Default = "Player", Placeholder = "Enter a name",
    ConfigKey = "nickname",
    Callback = function(text, enterPressed) print(text, enterPressed) end,
})

Preferences:CreateKeybind({
    Title = "Action key", Default = Enum.KeyCode.F, ConfigKey = "action_key",
    Callback = function(key) print("New binding:", key.Name) end,
})

Preferences:CreateColorPicker({
    Title = "Accent", Default = Color3.fromRGB(103, 89, 179),
    ConfigKey = "accent",
    Callback = function(color) Hub:SetAccent(color) end,
})

Actions:CreateButton({
    Title = "Notify",
    Callback = function()
        Hub:Notify({Title = "Ready", Text = "UI is working", Type = "success"})
    end,
})
Actions:CreateLabel("RightControl or Minus shows and hides the window.")
Actions:CreateSeparator()
Actions:CreateButton({
    Title = "Reset values",
    Callback = function()
        Hub:Confirm({
            Title = "Reset values", Text = "Restore all defaults?",
            OnConfirm = function() Hub:ResetValues() end,
        })
    end,
})

Settings:SetBadge(1)
-- Create every control before loading a saved default profile:
-- local ok, err = Hub:LoadDefaultProfile()
```

## Structure and window options

`Library.new(options)` returns a Hub. Options: `Title: string?`, `Version: string?`, `Accent: Color3?`, `ToggleKey: Enum.KeyCode?`, `LoadingScreen: boolean?`, `LoadingDuration: number?`, `SnowEffect: boolean?`, `MobileToggle: boolean?`. Defaults include `Title = "HutameHub"`, `Version = "v2.3"`, purple `Accent`, RightControl, loading screen on and main-window snow off. `MobileToggle` is automatic on touch devices; `true` also shows it on desktop and `false` disables it.

Build in this order: `Hub:CreateTab("Name")` → `Tab:CreateSection("Name", "left" or "right")` → `Section:Create...({Title = "Label", ...})`. The side defaults to left. Each tab has two columns; a narrow viewport stacks sections into one column. Long dropdown lists scroll inside the section; opening one grows the section and pushes later controls down. `Section:Collapse()` / `Section:Expand()` animate its height.

`ToggleKey`, the Minus keyboard key, and the `—` button beside `✕` show/hide the **whole window**. After hiding with `—`, use the key or mobile toggle to show it. The `✕` button destroys the UI. Textbox focus prevents keyboard toggle shortcuts. `Hub:Destroy()` removes the UI.

## Controls: exact names and callbacks

All option-table controls use `Title`, never `Name`. `Tooltip`, `VisibleWhen = function() return boolean end`, and `EnabledWhen = function() return boolean end` are available on option-table controls. Value controls also accept a unique `ConfigKey` for save/load. `CreateButton` has no saved value.

| Method | Important options | Callback arguments | Returned handle |
| --- | --- | --- | --- |
| `Section:CreateToggle({...})` | `Title`, `Default: boolean`, optional `Keybind: Enum.KeyCode` | `(value: boolean)` | `.State`, `:Set(boolean)`, `:Reset()` |
| `Section:CreateSlider({...})` | `Title`, `Min`, `Max`, `Default`, `Decimals`, `Suffix` | `(value: number)` | `.Value`, `:Set(number)`, `:Reset()` |
| `Section:CreateDropdown({...})` | `Title`, `Options: {string}`, `Default: string`, `MaxVisibleItems` | `(value: string)` | `.Selected`, `:Set(string)`, `:Refresh(options)`, `:Open()`, `:Close()`, `:Reset()` |
| `Section:CreateMultiDropdown({...})` | `Title`, `Options: {string}`, `Default: {string}`, `MaxShow`, `MaxVisibleItems` | `(values: {string})` | `:GetSelected()`, `:Set(values)`, `:Refresh(options)`, `:Open()`, `:Close()`, `:Reset()` |
| `Section:CreateTextbox({...})` | `Title`, `Default`, `Placeholder` | `(text: string, enterPressed: boolean)` on focus loss | `.Text`, `:Set(string)`, `:Reset()` |
| `Section:CreateKeybind({...})` | `Title`, `Default: Enum.KeyCode` | `(key: Enum.KeyCode)` when binding changes | `.Key`, `:Set(Enum.KeyCode)`, `:Reset()` |
| `Section:CreateColorPicker({...})` | `Title`, `Default: Color3` | `(color: Color3)` | `.Color`, `:Set(Color3)`, `:Toggle()`, `:Reset()` |
| `Section:CreateButton({...})` | `Title`, `Callback = function() ... end` | no arguments | Roblox `TextButton` |

Also available: `Section:CreateLabel(text, color?)` returns a `TextLabel`; `Section:CreateSeparator()` adds a divider. `Tab:SetBadge(number)` and `Tab:ClearBadge()` manage the tab counter. `Tab:Activate()` switches to a tab. `Hub:SetAccent(Color3)` changes the accent; `Hub:SetTitle(title, version?)` changes the window heading.

## Profiles, conditions and dialogs

Give each saved value control a distinct `ConfigKey`. `Hub:SaveProfile(name)`, `Hub:LoadProfile(name)`, `Hub:RenameProfile(oldName, newName)`, `Hub:DeleteProfile(name)`, `Hub:SetDefaultProfile(name)`, and `Hub:LoadDefaultProfile()` return `ok, err`. `Hub:ListProfiles()` returns sorted names. Call `LoadDefaultProfile()` **after** creating every control. Profile storage needs `readfile`/`writefile`; rename and delete also need `delfile`. Names use 1–48 letters, digits, `_` or `-`. The older `Hub:SaveConfig(name)` and `Hub:LoadConfig(name)` remain available.

`control:Reset()` restores one value control; `Hub:ResetValues()` restores all value controls to construction defaults. `Hub:SetCondition(control, predicate, "hide" or "disable")` attaches a condition to an existing control. `VisibleWhen`/`EnabledWhen` can be set during construction. Call `Hub:RefreshConditions()` when an external variable changes. A disabled control blocks user input, but code may still call `:Set()`.

`Hub:Confirm({Title, Text, ConfirmText, CancelText, OnConfirm, OnCancel})` displays a confirmation dialog; only confirmation calls `OnConfirm`. `Hub:Notify({Title, Text, Type, Duration})` shows a toast. `Type` is `"info"`, `"success"`, `"warning"` or `"error"`. For an optional overlay, `Hub:SetWatermark({Format, Position, BgAlpha})`, `Hub:UpdateWatermark(format)`, and `Hub:RemoveWatermark()` are available.

## Avoid these mistakes

- Use `Library.new({...})`, not `Library:CreateWindow(...)` or `Library.newWindow(...)`.
- Use `Title` in control options, not `Name` or `Text`. Tab and section titles are positional strings.
- Do not call `Tab:CreateToggle(...)`; create a section first, then call `Section:CreateToggle(...)`.
- Do not confuse a toggle's optional `Keybind` (pressing it toggles state) with `CreateKeybind` (selects a key and reports binding changes).
- `Textbox:Set()` and `Keybind:Set()` do not invoke their user callbacks. Other setters may invoke callbacks; use handles and test accordingly.
- `CreateButton` returns a `TextButton`, while value controls return handles. Do not assume all constructors return the same type.
- Do not claim Roblox visual/touch behavior was tested from this guide alone. The repository's headless tests cover selected logic; run the UI in a client to verify appearance and interaction.

Further reading: [source](https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua), [Luau types](https://hutamev2.github.io/HutameHub-Lib/examples/types.luau), [feature details](https://hutamev2.github.io/HutameHub-Lib/features.md), [full test example](https://hutamev2.github.io/HutameHub-Lib/examples/ui-test.lua).
