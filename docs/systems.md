# Core Systems

The library includes several global systems managed through the `Hub` instance.

## Config System

The JSON-based config system allows saving and loading of all UI elements that were created with a `ConfigKey` parameter.

```lua
-- Save all current states to a file named 'my_legit_config.json'
Hub:SaveConfig("my_legit_config")

-- Load them back
Hub:LoadConfig("my_legit_config")

-- Returns an array of saved config names
local configs = Hub:ListConfigs()
```

## Flags System

`Hub.Flags` is a real-time synchronized dictionary. If you assigned `Flag = "AimbotEnabled"` to a Toggle, you can read it anywhere in your loop:

```lua
RunService.RenderStepped:Connect(function()
    if Hub.Flags.AimbotEnabled then
        -- Aimbot logic
    end
end)
```

## Notifications

Notifications (Toasts) pop up smoothly on the screen.

```lua
Hub:Notify({
    Title = "Configuration Loaded",
    Text = "Successfully loaded your legit config.",
    Type = "success", -- Can be "info", "success", "warning", "error"
    Duration = 5
})
```

## Watermark HUD

A draggable/fixed watermark HUD for your script. Supports dynamic placeholders: `{fps}`, `{ping}`, `{time}`, `{player}`.

```lua
Hub:SetWatermark({
    Format = "HutameHub | {fps} FPS | {ping}ms | {player}",
    Position = "TopRight", -- TopLeft, TopRight, BottomLeft, BottomRight
    BgAlpha = 0.5
})

-- Update it dynamically
Hub:UpdateWatermark("HutameHub | Loading...")

-- Remove it
Hub:RemoveWatermark()
```
