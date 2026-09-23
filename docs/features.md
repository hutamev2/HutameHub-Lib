# HutameHub v3.0 - Features and Utilities

The v3.0 release brings a massive overhaul to the HutameHub Library, removing spaghetti code and monkey-patching in favor of a clean, Object-Oriented (OOP) architecture.

All examples use the `Library.new()` / `Hub:CreateTab()` API.

## Configuration System

HutameHub now features a clean JSON-based configuration system. By providing a `ConfigKey` to any value-based control (Toggle, Slider, Dropdown, MultiDropdown, Textbox, Keybind, ColorPicker), its state is automatically tracked.

| Hub method | Behavior |
| --- | --- |
| `SaveConfig(name)` | Saves the current state of all controls with a ConfigKey to a `.json` file. |
| `LoadConfig(name)` | Loads and applies the saved state from the `.json` file. |
| `ListConfigs()` | Returns a table of all saved configuration names (requires `listfiles`). |

*Configurations are saved as `HutameLib_NAME.json` in your executor's workspace directory.*

## Flags System

No more storing control references just to read their values! Every value control can optionally accept a `Flag` string in its config table.
When set, the control's value is automatically synced to the `Hub.Flags` table.

```lua
local AimbotToggle = Section:CreateToggle({
    Title = "Enable Aimbot",
    Flag = "AimbotEnabled",
    Default = false
})

-- Later in your script, simply read:
if Hub.Flags.AimbotEnabled then
    -- Do aimbot logic
end
```

## Theme Engine

HutameHub v3.0 comes with 5 beautifully crafted modern theme presets built directly into the library:
- **Midnight** (Deep Purple / Navy) - *Default*
- **Ocean** (Blue / Slate)
- **Crimson** (Red / Dark Maroon)
- **Emerald** (Green / Dark Forest)
- **Sakura** (Pink / Deep Magenta)

You can set the theme when initializing the hub, or change it dynamically at runtime:

```lua
-- Change to a preset
Hub:SetTheme("Ocean")

-- Or provide a custom color table
Hub:SetTheme({
    Accent = Color3.fromRGB(255, 200, 0),
    BG = Color3.fromRGB(15, 15, 15)
})

-- Change only the accent color:
Hub:SetAccent(Color3.fromRGB(0, 255, 150))
```

## Notifications (Toasts)

The notification system uses `TweenService` for smooth transitions and features a progress drain bar.

```lua
Hub:Notify({
    Title = "Success",
    Text = "Your settings have been applied.",
    Type = "success", -- info, success, warning, error
    Duration = 3
})
```

## Watermark HUD

A live-updating watermark HUD that you can place in any corner of the screen. It supports dynamic placeholders for FPS, Ping, Time, and Player Name.

```lua
Hub:SetWatermark({
    Format = "MyHub | {player} | {fps} fps | {ping} ms",
    Position = "TopRight", -- TopLeft, TopRight, BottomLeft, BottomRight
    BgAlpha = 0.5
})

-- Update the text format later:
Hub:UpdateWatermark("New Format | {time}")

-- Remove it entirely:
Hub:RemoveWatermark()
```

## HSV Color Picker

The old RGB slider has been completely replaced by a professional **HSV Color Picker**. It features:
- A 2D Saturation/Value gradient square.
- A vertical Hue slider.
- A hexadecimal text input for pasting exact color codes.

```lua
Section:CreateColorPicker({
    Title = "ESP Color",
    Flag = "EspColor",
    Default = Color3.fromRGB(255, 80, 80),
    ConfigKey = "esp_color"
})
```
