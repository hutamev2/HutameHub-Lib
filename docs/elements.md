# UI Elements

All UI elements are created through a **Section** instance. Most elements take a table configuration.

## Common Properties
Almost all interactive elements (Toggle, Slider, etc.) support these properties:

| Property | Type | Description |
| --- | --- | --- |
| `Title` | `string` | The label/name of the element. |
| `Flag` | `string` | (Optional) Automatically links this element's value to `Hub.Flags[Flag]`. |
| `ConfigKey` | `string` | (Optional) Links this element to the JSON Save/Load Config system. |
| `Callback` | `function` | (Optional) Function triggered when the element's value changes. |

---

## Button
`Section:CreateButton(cfg)`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"Button"` | Text shown on the button. |
| `Callback` | `function` | `nil` | Function executed on click. |

```lua
Section:CreateButton({
    Title = "Kill All",
    Callback = function()
        print("Killed!")
    end
})
```

---

## Toggle
`Section:CreateToggle(cfg)`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"Toggle"` | Text description. |
| `Default` | `boolean` | `false` | Starting state of the checkbox. |

```lua
local AimbotToggle = Section:CreateToggle({
    Title = "Enable Aimbot",
    Flag = "Aimbot",
    Default = false,
    ConfigKey = "aimbot_toggle"
})
```

---

## Slider
`Section:CreateSlider(cfg)`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"Slider"` | Text description. |
| `Min` | `number` | `0` | Minimum slider value. |
| `Max` | `number` | `100` | Maximum slider value. |
| `Default` | `number` | `0` | Starting value. |
| `Decimals` | `number` | `0` | Precision scale. Default `0` means whole integers. |

```lua
Section:CreateSlider({
    Title = "FOV Radius",
    Min = 0,
    Max = 360,
    Default = 90,
    Flag = "FovRadius",
    ConfigKey = "fov_radius"
})
```

---

## Dropdown
`Section:CreateDropdown(cfg)`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"Dropdown"` | Text description. |
| `Options` | `table` | `{}` | List of string options. |
| `Default` | `string` | `nil` | Pre-selected option. |

```lua
Section:CreateDropdown({
    Title = "Hitbox",
    Options = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head",
    Flag = "AimbotHitbox"
})
```

---

## MultiDropdown
`Section:CreateMultiDropdown(cfg)`

Similar to Dropdown, but allows selecting multiple items.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Default` | `table` | `{}` | Array of pre-selected strings. |

```lua
Section:CreateMultiDropdown({
    Title = "ESP Types",
    Options = {"Players", "NPCs", "Items", "Vehicles"},
    Default = {"Players", "Items"},
    Flag = "EspFilters"
})
```

---

## Textbox
`Section:CreateTextbox(cfg)`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"Textbox"` | Text description. |
| `Placeholder` | `string` | `""` | Ghost text when empty. |
| `Default` | `string` | `""` | Starting text. |
| `ClearOnFocus`| `boolean`| `true` | Clears text when clicking. |

```lua
Section:CreateTextbox({
    Title = "Target Player",
    Placeholder = "Enter name...",
    Flag = "TargetName"
})
```

---

## ColorPicker (HSV)
`Section:CreateColorPicker(cfg)`

Creates a fully interactive HSV Color Picker.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"ColorPicker"` | Text description. |
| `Default` | `Color3` | `Color3.fromRGB(255,255,255)` | Starting color. |

```lua
Section:CreateColorPicker({
    Title = "Chams Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "ChamsColor"
})
```

---

## Keybind
`Section:CreateKeybind(cfg)`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"Keybind"` | Text description. |
| `Default` | `Enum.KeyCode` | `nil` | Starting key. |

```lua
Section:CreateKeybind({
    Title = "Fly Toggle Key",
    Default = Enum.KeyCode.F,
    Flag = "FlyKey"
})
```
