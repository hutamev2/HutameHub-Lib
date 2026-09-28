-- Experimental Drawing preview. No game automation.
-- Keep this visible, save an OBS Replay clip, and compare the actual recording.
local source
if type(isfile) == "function" and isfile("scripts/hutamehub_streamproof_source.lua") then
    source = readfile("scripts/hutamehub_streamproof_source.lua")
else
    source = game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua")
end
local Library = assert(loadstring(source))()
local environment = getgenv()
if environment.HutameDrawingPreview then environment.HutameDrawingPreview:Destroy() end
local hub = Library.new({Title="HutameHub Drawing",Version="Preview",Streamproof=true,
    ToggleKey=Enum.KeyCode.End})
environment.HutameDrawingPreview = hub
local tab = hub:CreateTab("Preview")
local controls = tab:CreateSection("Drawing controls", "left")
controls:CreateToggle({Title="Toggle",Default=false,ConfigKey="preview_toggle"})
controls:CreateSlider({Title="Slider",Min=0,Max=100,Default=25,Decimals=0})
controls:CreateDropdown({Title="Dropdown",Options={"A","B","C","D","E","F","G","H"},MaxVisibleItems=3})
controls:CreateMultiDropdown({Title="Multi",Options={"A","B","C"},Default={"A"}})
controls:CreateTextbox({Title="Text",Default="Preview"})
controls:CreateKeybind({Title="Key",Default=Enum.KeyCode.F})
controls:CreateColorPicker({Title="Accent HEX",Default=hub.Accent,Callback=function(color) hub:SetAccent(color) end})
local actions = tab:CreateSection("Capture check", "right")
actions:CreateLabel("Visible here; check the actual Replay clip.")
actions:CreateButton({Title="Drawing notification",Callback=function()
    hub:Notify({Title="Drawing test",Text="Check this message in the Replay clip",Duration=8})
end})
actions:CreateButton({Title="Confirm dialog",Callback=function()
    hub:Confirm({Title="Drawing dialog",Text="This is a UI preview only."})
end})
actions:CreateButton({Title="Destroy preview",Callback=function() hub:Destroy() end})
hub:CreateKeybindList({Title="DRAWING KEYBINDS"})
hub:SetWatermark({Format="HutameHub Drawing | {fps} fps",Position="TopRight"})
return "Drawing preview ready. End toggles the main window."
