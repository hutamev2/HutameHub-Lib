# Tabs & Sections

HutameHub uses a modern two-column layout grid. You first create a **Tab**, and then place **Sections** inside it.

## `Hub:CreateTab(name, iconId)`

Creates a navigation tab in the sidebar.

| Parameter | Type | Description |
| --- | --- | --- |
| `name` | `string` | The display name of the tab. |
| `iconId` | `string` | (Optional) Roblox asset ID (e.g., `"rbxassetid://10723396662"`). |

**Returns:** `Tab` object.

```lua
local CombatTab = Hub:CreateTab("Combat", "rbxassetid://10723396662")
```

---

## `Tab:CreateSection(title, column)`

Creates a visual container inside a tab where you can place UI elements (Toggles, Sliders, etc.). Sections are collapsible.

| Parameter | Type | Description |
| --- | --- | --- |
| `title` | `string` | The header text of the section. |
| `column` | `string` | `"left"` or `"right"`. Dictates which column the section sits in. Default is `"left"`. |

**Returns:** `Section` object.

```lua
local AimbotSec = CombatTab:CreateSection("Aimbot", "left")
local ESPSec = CombatTab:CreateSection("Visuals ESP", "right")
```
