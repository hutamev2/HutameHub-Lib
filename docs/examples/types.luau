-- Paste these aliases above your loader in Roblox Studio / a Luau-aware editor.
-- This describes Source.lua; it does not perform runtime validation.
type ControlOptions = {
    Title: string?, Tooltip: string?, ConfigKey: string?,
    VisibleWhen: (() -> boolean)?, EnabledWhen: (() -> boolean)?,
}
type ToggleOptions = ControlOptions & {Default: boolean?, Keybind: Enum.KeyCode?, Callback: ((boolean) -> ())?}
type SliderOptions = ControlOptions & {Min: number?, Max: number?, Default: number?, Decimals: number?, Suffix: string?, Callback: ((number) -> ())?}
type DropdownOptions = ControlOptions & {Options: {string}?, Default: string?, MaxVisibleItems: number?, Callback: ((string) -> ())?}
type MultiDropdownOptions = ControlOptions & {Options: {string}?, Default: {string}?, MaxShow: number?, MaxVisibleItems: number?, Callback: (({string}) -> ())?}
type TextboxOptions = ControlOptions & {Default: string?, Placeholder: string?, Callback: ((string, boolean) -> ())?}
type KeybindOptions = ControlOptions & {Default: Enum.KeyCode?, Callback: ((Enum.KeyCode) -> ())?}
type ColorPickerOptions = ControlOptions & {Default: Color3?, Callback: ((Color3) -> ())?}
type ButtonOptions = {Title: string?, Tooltip: string?, Desc: string?, Callback: (() -> ())?, VisibleWhen: (() -> boolean)?, EnabledWhen: (() -> boolean)?}

type ToggleControl = {State: boolean, Set: (self: ToggleControl, value: boolean) -> (), Reset: (self: ToggleControl) -> ()}
type SliderControl = {Value: number, Set: (self: SliderControl, value: number) -> (), Reset: (self: SliderControl) -> ()}
type DropdownControl = {
    Selected: string, Options: {string}, Opened: boolean,
    Set: (self: DropdownControl, value: string) -> (), Reset: (self: DropdownControl) -> (),
    Open: (self: DropdownControl) -> (), Close: (self: DropdownControl) -> (),
    Refresh: (self: DropdownControl, options: {string}?) -> (),
}
type MultiDropdownControl = {
    Options: {string}, Opened: boolean,
    Set: (self: MultiDropdownControl, values: {string}) -> (), Reset: (self: MultiDropdownControl) -> (),
    GetSelected: (self: MultiDropdownControl) -> {string},
    Open: (self: MultiDropdownControl) -> (), Close: (self: MultiDropdownControl) -> (),
    Refresh: (self: MultiDropdownControl, options: {string}?) -> (),
}
type TextboxControl = {Text: string, Set: (self: TextboxControl, text: string) -> (), Reset: (self: TextboxControl) -> ()}
type KeybindControl = {Key: Enum.KeyCode, Listening: boolean, Set: (self: KeybindControl, key: Enum.KeyCode) -> (), Reset: (self: KeybindControl) -> ()}
type ColorPickerControl = {Color: Color3, Opened: boolean, Set: (self: ColorPickerControl, color: Color3) -> (), Toggle: (self: ColorPickerControl) -> (), Reset: (self: ColorPickerControl) -> ()}
type HutameControl = ToggleControl | SliderControl | DropdownControl | MultiDropdownControl | TextboxControl | KeybindControl | ColorPickerControl | TextButton
type HutameSection = {
    CreateToggle: (self: HutameSection, options: ToggleOptions?) -> ToggleControl,
    CreateSlider: (self: HutameSection, options: SliderOptions?) -> SliderControl,
    CreateDropdown: (self: HutameSection, options: DropdownOptions?) -> DropdownControl,
    CreateMultiDropdown: (self: HutameSection, options: MultiDropdownOptions?) -> MultiDropdownControl,
    CreateTextbox: (self: HutameSection, options: TextboxOptions?) -> TextboxControl,
    CreateKeybind: (self: HutameSection, options: KeybindOptions?) -> KeybindControl,
    CreateColorPicker: (self: HutameSection, options: ColorPickerOptions?) -> ColorPickerControl,
    CreateButton: (self: HutameSection, options: ButtonOptions?) -> TextButton,
    CreateLabel: (self: HutameSection, text: string, color: Color3?) -> TextLabel,
    CreateSeparator: (self: HutameSection) -> (),
    Collapse: (self: HutameSection) -> (), Expand: (self: HutameSection) -> (),
}
type HutameTab = {
    Name: string, Active: boolean,
    CreateSection: (self: HutameTab, title: string, side: ("left" | "right")?) -> HutameSection,
    Activate: (self: HutameTab) -> (), Deactivate: (self: HutameTab) -> (),
    SetBadge: (self: HutameTab, count: number?) -> (), ClearBadge: (self: HutameTab) -> (),
}
type NotificationOptions = {Title: string?, Text: string?, Type: ("info" | "success" | "warning" | "error")?, Duration: number?}
type WatermarkOptions = {Format: string?, Position: ("TopLeft" | "TopRight" | "BottomLeft" | "BottomRight")?, BgAlpha: number?}
type ConfirmOptions = {Title: string?, Text: string?, ConfirmText: string?, CancelText: string?, OnConfirm: (() -> ())?, OnCancel: (() -> ())?}
type HutameWindow = {
    Title: string, Version: string, Accent: Color3, ToggleKey: Enum.KeyCode,
    CreateTab: (self: HutameWindow, title: string) -> HutameTab,
    SetAccent: (self: HutameWindow, color: Color3) -> (),
    SetTitle: (self: HutameWindow, title: string?, version: string?) -> (),
    Destroy: (self: HutameWindow) -> (), Notify: (self: HutameWindow, options: NotificationOptions?) -> (),
    SetWatermark: (self: HutameWindow, options: WatermarkOptions?) -> (),
    UpdateWatermark: (self: HutameWindow, format: string) -> (), RemoveWatermark: (self: HutameWindow) -> (),
    SaveConfig: (self: HutameWindow, name: string?) -> (), LoadConfig: (self: HutameWindow, name: string?) -> (),
    ListProfiles: (self: HutameWindow) -> {string},
    SaveProfile: (self: HutameWindow, name: string) -> (boolean, any),
    LoadProfile: (self: HutameWindow, name: string) -> (boolean, any),
    RenameProfile: (self: HutameWindow, oldName: string, newName: string) -> (boolean, any),
    DeleteProfile: (self: HutameWindow, name: string) -> (boolean, any),
    SetDefaultProfile: (self: HutameWindow, name: string?) -> (boolean, any),
    LoadDefaultProfile: (self: HutameWindow) -> (boolean, any),
    ResetValues: (self: HutameWindow) -> (), RefreshConditions: (self: HutameWindow) -> (),
    SetCondition: (self: HutameWindow, control: HutameControl, predicate: () -> boolean, mode: ("hide" | "disable")?) -> (),
    Confirm: (self: HutameWindow, options: ConfirmOptions?) -> {Cancel: () -> ()},
}
type WindowOptions = {Title: string?, Version: string?, Accent: Color3?, ToggleKey: Enum.KeyCode?, LoadingScreen: boolean?, LoadingDuration: number?, SnowEffect: boolean?, MobileToggle: boolean?}
type HutameLibrary = {new: (options: WindowOptions?) -> HutameWindow}

-- After these aliases, annotate your loader:
-- local Library: HutameLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))()
-- local Hub = Library.new({Title = "Typed Hub"})
-- local Section = Hub:CreateTab("Home"):CreateSection("Settings")
-- local Enabled = Section:CreateToggle({Title = "Enabled", Default = false})
-- Enabled:Set(true)
