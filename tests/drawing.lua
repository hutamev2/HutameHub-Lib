-- Drawing state/lifecycle tests; does not establish OBS capture exclusion.
local function signal()
    local s = {handlers = {}}
    function s:Connect(fn)
        local connection = {Connected = true}
        function connection:Disconnect() self.Connected = false end
        table.insert(self.handlers, {fn = fn, connection = connection})
        return connection
    end
    function s:Fire(...)
        for _, h in ipairs(self.handlers) do if h.connection.Connected then h.fn(...) end end
    end
    return s
end
local function vector(x,y) return {X=x or 0,Y=y or 0} end
Vector2 = {new = vector}
UDim2 = {fromOffset = function(x,y) return {X={Scale=0,Offset=x},Y={Scale=0,Offset=y}} end}
local function color(hex) return {ToHex=function() return hex or "ffffff" end} end
Color3 = {fromRGB = function() return color() end, fromHex=color}
Enum = setmetatable({}, {__index=function(t,k)
    local g=setmetatable({}, {__index=function(group,n)
        local value={Name=n}; rawset(group,n,value); return value
    end}); rawset(t,k,g); return g
end})
math.clamp = function(v,lo,hi) return math.max(lo,math.min(hi,v)) end
table.clear = function(t) for k in pairs(t) do t[k]=nil end end
local input = {InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),mouse=vector()}
function input:GetMouseLocation() return self.mouse end
function input:IsKeyDown() return false end
local run={RenderStepped=signal()}
local encoded,serial={},0
local http={}
function http:JSONEncode(v) serial=serial+1; local token="json:"..serial; encoded[token]=v; return token end
function http:JSONDecode(v) assert(encoded[v]~=nil); return encoded[v] end
game={GetService=function(_,name)
    return ({UserInputService=input,RunService=run,HttpService=http})[name] or {}
end}
workspace={CurrentCamera={ViewportSize=vector(1280,720)}}
Instance={new=function() error("Drawing mode created a Roblox Instance") end}
warn=function() end
local files={}
writefile=function(path,value) files[path]=value end
readfile=function(path) assert(files[path]); return files[path] end
local objects={}
Drawing={Fonts={Plex=2},new=function(kind)
    local object={Kind=kind,Removed=false}
    function object:Remove() assert(not self.Removed,"Double removal"); self.Removed=true end
    table.insert(objects,object); return object
end}
local Library=dofile("Source.lua")
local hub=Library.new({Title="Test",Renderer="Drawing"})
-- Fast game frames must not multiply UI work.
local realClock, tick = os.clock, 1
os.clock=function() return tick end
local originalRender, renders = hub._render, 0
hub._render=function(self) renders=renders+1; originalRender(self) end
run.RenderStepped:Fire()
tick=1.001; run.RenderStepped:Fire()
assert(renders==1,"Idle rendering must be capped")
tick=1.04; run.RenderStepped:Fire()
assert(renders==2)
hub._capture={}
tick=1.06; run.RenderStepped:Fire()
assert(renders==3,"Active input must retain 60 Hz responsiveness")
hub._capture=nil; hub._render=originalRender; os.clock=realClock
local section=hub:CreateTab("Main"):CreateSection("Controls")
local changes=0
local toggle=section:CreateToggle({Title="Toggle",Default=false,ConfigKey="toggle",Callback=function() changes=changes+1 end})
local slider=section:CreateSlider({Title="Slider",Default=5,Min=0,Max=10,Decimals=1,ConfigKey="slider"})
local dropdown=section:CreateDropdown({Title="Dropdown",Options={"A","B"},ConfigKey="dropdown"})
local textbox=section:CreateTextbox({Title="Text",Default="hello",ConfigKey="text"})
local key=section:CreateKeybind({Title="Key",Default=Enum.KeyCode.F,ConfigKey="key"})
local multi=section:CreateMultiDropdown({Title="Multi",Options={"A","B"},Default={"A"},ConfigKey="multi"})
local picker=section:CreateColorPicker({Title="Color",Default=color("123abc"),ConfigKey="color"})
hub:_render()
assert(#objects>0)
input.mouse=vector(hub._position.X+150,hub._position.Y+70)
input.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,KeyCode=Enum.KeyCode.Unknown},false)
assert(toggle.State and changes==1,"Toggle hit testing failed")
slider:Set(12); assert(slider.Value==10)
slider:Set(3.26); assert(slider.Value==3.3)
assert(hub:SaveProfile("drawing"))
toggle:Set(false); slider:Set(0); dropdown:Set("B"); textbox:Set("changed"); key:Set(Enum.KeyCode.G)
multi:Set({"B"}); picker:Set(color("ffffff"))
assert(hub:LoadProfile("drawing"))
assert(toggle.State==true and slider.Value==3.3 and dropdown.Selected=="A")
assert(textbox.Text=="hello" and key.Key==Enum.KeyCode.F)
assert(multi:GetSelected()[1]=="A" and picker.Color:ToHex()=="123abc")
local enabled=false
hub:SetCondition(slider,function() return enabled end,"disable")
assert(slider.Enabled==false)
enabled=true; hub:RefreshConditions(); assert(slider.Enabled==true)
dropdown:Open(); hub:_render()
local option
for _, object in ipairs(objects) do
    if not object.Removed and object.Visible and object.Kind == "Text" and object.Text == "B" then option=object end
end
assert(option, "Expanded dropdown option must be rendered")
input.mouse=vector(option.Position.X+2,option.Position.Y+2)
input.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,KeyCode=Enum.KeyCode.Unknown},false)
assert(dropdown.Selected=="B" and not dropdown.Opened,"Dropdown option hit area must match its drawing")
-- Scroll a long section: offscreen controls cannot intercept the title/sidebar.
for i=1,30 do section:CreateToggle({Title="Overflow "..i}) end
hub:_render()
assert(hub._scrollMax[1]>0)
hub._scroll[1]=hub._scrollMax[1]
hub:_render()
for _,area in ipairs(hub._hits) do
    if area[1]>=hub._position.X+132 and area[2]>=hub._position.Y+29 then
        assert(area[2]>=hub._position.Y+42 and area[2]+area[4]<=hub._position.Y+hub._height-35,"Clipped controls must stay inside content")
    end
end
hub._scroll[1]=0
dropdown:Close(); hub:_render()
hub._notice=nil
hub.MainFrame.Visible=false; hub:_render()
for _,object in ipairs(objects) do if not object.Removed then assert(not object.Visible) end end
-- HUD must survive menu hiding and export a circle understood by the helper.
hub:SetCrosshair({Style="Circle",Size=8,Gap=2,Thickness=2,Outline=true})
hub:SetStatusHUD({Weapon="Test gun",Ammo=6,Health=20,Armor=10,LowHealth=true,LowArmor=true})
hub._bridge={}; hub._lastPublish=-1; hub:_render()
local shapes=http:JSONDecode(hub._frameJson).shapes
local circles,warning=0,false
for _,shape in ipairs(shapes) do
    if shape.kind=="Circle" then circles=circles+1; assert(shape.radius==10 and shape.thickness) end
    if shape.kind=="Text" and shape.text:find("DUSUK CAN") then warning=true end
end
assert(circles==2 and warning,"Hidden-menu HUD and circle serialization failed")
hub._bridge=nil; hub:SetCrosshair(nil); hub:SetStatusHUD(nil)
hub:CreateKeybindList({Title="Keys"}); hub:_render()
local visible=0
for _,object in ipairs(objects) do if not object.Removed and object.Visible then visible=visible+1 end end
assert(visible>0,"Keybind panel must survive hidden main window")
hub:Destroy()
for _,object in ipairs(objects) do assert(object.Removed) end
for _,connection in ipairs(hub._connections) do assert(not connection.Connected) end
print("PASS: Drawing routing, hit testing, typed profiles, pool reuse, panels and cleanup")
