# Window & Initialization

The main entry point for the library is the `Library.new` constructor.

## `Library.new(config)`

Creates the main UI window and initializes all core services.

### Parameters

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| `Title` | `string` | The text displayed in the top bar. | `"HutameHub"` |
| `Version` | `string` | The version text displayed next to the title. | `"v3.0"` |
| `Theme` | `string` \| `table` | Pre-built theme name or a custom color table. | `"Midnight"` |
| `Accent` | `Color3` | (Optional) Overrides the accent color of the selected theme. | `nil` |
| `ToggleKey` | `Enum.KeyCode` | The default key used to show/hide the UI. | `Enum.KeyCode.RightControl` |

### Example

```lua
local Hub = Library.new({
    Title = "Phantom Hub",
    Version = "v1.2.4",
    Theme = "Ocean",
    ToggleKey = Enum.KeyCode.F4
})
```

---

## Themes & Styling

HutameHub v3.0 comes with 5 beautifully crafted modern theme presets:

1. **Midnight** (Deep Purple / Navy) - *Default*
2. **Ocean** (Blue / Slate)
3. **Crimson** (Red / Dark Maroon)
4. **Emerald** (Green / Dark Forest)
5. **Sakura** (Pink / Deep Magenta)

### Changing the Theme Dynamically

You can swap out the entire theme or change individual colors on the fly using the Hub instance.

#### `Hub:SetTheme(themeNameOrTable)`

```lua
-- Switch to a built-in preset
Hub:SetTheme("Sakura")

-- Or provide a custom table
Hub:SetTheme({
    BG = Color3.fromRGB(10, 10, 10),
    Accent = Color3.fromRGB(255, 100, 100)
    -- Add other colors as needed...
})
```

#### `Hub:SetAccent(color)`

Changes only the `Accent` color of the current theme and smoothly tweens all UI elements utilizing it.

```lua
Hub:SetAccent(Color3.fromRGB(0, 255, 200))
```
