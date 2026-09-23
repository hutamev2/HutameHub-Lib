# Profiles and control utilities

All examples use the existing `Library.new()` / `Hub:CreateTab()` API.
See [the complete interactive test](examples/ui-test.lua) for a profile manager,
confirmation dialogs, conditional controls and reset buttons.

## Profiles

Give value controls a unique `ConfigKey`. Toggle, Slider, Dropdown,
MultiDropdown, Textbox, Keybind and ColorPicker are supported. Buttons are not values.

| Hub method | Behavior |
| --- | --- |
| `SaveProfile(name)` | Create or overwrite a profile with current registered values |
| `LoadProfile(name)` | Restore registered values and refresh conditions |
| `ListProfiles()` | Return sorted names saved through SaveProfile |
| `RenameProfile(oldName, newName)` | Rename without overwriting another profile |
| `DeleteProfile(name)` | Delete the profile and clear its default selection if needed |
| `SetDefaultProfile(name)` | Remember a profile; pass nil to clear |
| `LoadDefaultProfile()` | Restore it; call after creating every control |

Mutating profile methods and load methods return `ok, error`. Names contain 1–48
letters, digits, underscores or hyphens. Storage requires `readfile` / `writefile`;
rename and delete additionally require `delfile`. Profiles use `HutameHub_NAME.cfg`
and `HutameHub_profiles.json` in the environment's filesystem. Existing
SaveConfig/LoadConfig remain available; old files can be loaded by name but are
not automatically indexed. Profile loading may partially restore values if a setter fails.

## Reset

Every value control has `control:Reset()`. `Hub:ResetValues()` resets all value
controls, including those without ConfigKey, to their creation defaults. Setters
keep their existing callback semantics: Textbox and Keybind Set do not call the
user callback, while conditions and conflict checks still update. Saved profiles
are unchanged until explicitly saved again.

## Conditional controls

```lua
local Enabled = Section:CreateToggle({Title="Advanced", Default=false})
local Amount = Section:CreateSlider({Title="Amount", Min=0, Max=100,
    VisibleWhen=function() return Enabled.State end})
Section:CreateButton({Title="Apply",
    EnabledWhen=function() return Enabled.State end,
    Callback=function() print("Applied") end})
-- Alternative for an existing control:
Hub:SetCondition(Amount, function() return Enabled.State end, "hide")
```

Available on the eight config-table control constructors (including Button).
Use `hide` or `disable`. Conditions reevaluate after control callbacks, Set,
reset and profile loading. Call `Hub:RefreshConditions()` when external state
changes. Predicates should only read state. Disabled controls block user input;
programmatic Set remains available. Hidden controls retain their value.

## Confirmation

```lua
Hub:Confirm({Title="Reset values", Text="Restore defaults?",
    ConfirmText="Reset", CancelText="Keep values",
    OnConfirm=function() Hub:ResetValues() end,
    OnCancel=function() print("Cancelled") end})
```

Only Confirm runs OnConfirm. The returned handle has `Cancel()`. A new dialog
replaces the previous one. Profile deletion and reset methods are direct API
operations: wrap them in Confirm as the interactive example does.

## Mobile toggle and key conflicts

`Library.new({MobileToggle=true})` shows a draggable 48×48 HH button. Omit the
option to show it on touch devices only; false disables it. Tap to hide/show the
main window; drag without toggling. RightControl/custom ToggleKey and Minus still work.

Duplicate bindings display a warning naming both actions. Checks include toggle
Keybinds, key selector controls, the window ToggleKey and Minus. None is ignored.
Warnings do not change bindings or block assignment.

## Validation

`tests/features.lua` covers profile lifecycle, storage errors, reset dispatch,
condition state and conflict warning deduplication using a headless Lua harness.
Roblox visual layout, actual touch delivery and modal focus require client testing.
