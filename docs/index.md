# Getting Started

Welcome to **HutameHub v3.0**, a modern, instance-based, TweenService-powered UI framework for Roblox Luau.

## Booting the Library

You can load the library into your script by requiring the remote GitHub source:

```lua
local HutameHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))()
```

This returns the `Library` class, which you can use to initialize your Hub window.

## Example Layout

Here is a quick snippet to get a basic script running:

```lua
local HutameHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))()

-- Create Window
local Hub = HutameHub.new({
    Title = "My Aimbot Script",
    Version = "v1.0",
    Theme = "Midnight"
})

-- Create Tab
local MainTab = Hub:CreateTab("Main", "rbxassetid://10723396662")

-- Create Section
local AimbotSection = MainTab:CreateSection("Aimbot Settings", "left")

-- Create Elements
AimbotSection:CreateToggle({
    Title = "Enable Aimbot",
    Flag = "Aimbot",
    Default = false
})

-- Load Config (Optional, but recommended)
Hub:LoadConfig("my_script_cfg")
```
