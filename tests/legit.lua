local Module=dofile("modules/LegitHUD.lua")
local p=Module.profile({Size=900,Gap=-4,Thickness=0/0,Color="no",Style="bad",Outline=false})
assert(p.Size==24 and p.Gap==0 and p.Thickness==1 and p.Color=="FFFFFF" and p.Style=="Cross" and not p.Outline)
local alarm={}
assert(not Module.alert(alarm,0,25,1,false),"Unarmored spawn must be quiet")
assert(Module.alert(alarm,20,25,2,true))
assert(not Module.alert(alarm,19,25,20,true),"Low values must not spam")
assert(not Module.alert(alarm,27,25,21,true),"Hysteresis must not rearm at threshold")
assert(not Module.alert(alarm,40,25,22,true))
assert(Module.alert(alarm,20,25,23,true))

table.clear=function(t) for k in pairs(t) do t[k]=nil end end
local signals={}
local function signal()
    local s={handlers={}}
    function s:Connect(fn)
        local c={Connected=true,fn=fn}
        function c:Disconnect() self.Connected=false end
        self.handlers[#self.handlers+1]=c; return c
    end
    function s:Fire(...)
        for _,c in ipairs(self.handlers) do if c.Connected then c.fn(...) end end
    end
    signals[#signals+1]=s; return s
end
local function node(class,name,children)
    local n={ClassName=class,Name=name,children=children or {},ChildAdded=signal(),ChildRemoved=signal(),DescendantAdded=signal(),Changed=signal(),HealthChanged=signal()}
    for _,child in ipairs(n.children) do child.Parent=n end
    function n:IsA(kind) return kind==self.ClassName or kind=="ValueBase" and self.ClassName=="IntValue" end
    function n:GetChildren() return self.children end
    function n:FindFirstChild(name) for _,child in ipairs(self.children) do if child.Name==name then return child end end end
    function n:FindFirstChildOfClass(kind) for _,child in ipairs(self.children) do if child:IsA(kind) then return child end end end
    return n
end
local hp=node("Humanoid","Humanoid"); hp.Health=100
local armor=node("IntValue","Armor"); armor.Value=0
local ammo=node("IntValue","Ammo"); ammo.Value=6
local gun=node("Tool","[Revolver]",{ammo})
local char=node("Model","Character",{hp,node("Folder","BodyEffects",{armor}),gun})
local player=node("Player","Player",{node("Backpack","Backpack")}); player.UserId=123; player.Character=char
player.CharacterAdded=signal(); player.CharacterRemoving=signal()
local render=signal()
local stored={}
local http={JSONDecode=function(_,v) return v end,JSONEncode=function(_,v) return v end}
game={GetService=function(_,name) return ({Players={LocalPlayer=player},RunService={RenderStepped=render},HttpService=http})[name] end}
readfile=function(path) assert(stored[path]); return stored[path] end
writefile=function(path,value) stored[path]=value end
Color3={fromHex=function(hex) return {ToHex=function() return hex end} end}
task={spawn=function(fn) end,wait=function() end}
warn=function() end
local fps=144
getfpscap=function() return fps end
setfpscap=function(value) fps=value end
local window={MainFrame={Visible=false},controls={},notes={}}
function window:SetCrosshair(value) self.cross=value end
function window:SetStatusHUD(value) self.hud=value end
function window:Notify(value) self.notes[#self.notes+1]=value end
function window:Destroy() self.dead=true end
function window:CreateTab(name)
    local tab={Name=name}
    function tab:CreateSection()
        return setmetatable({}, {__index=function(_,method)
            return function(_,options)
                if method=="CreateLabel" then return {Text=options,Set=function(self,text) self.Text=text end} end
                local control={Options=options.Options,Value=options.Default,Callback=options.Callback}
                function control:Set(value) self.Value=value; if self.Callback then self.Callback(value) end end
                function control:Refresh(values) self.Options=values end
                window.controls[options.Title]=control
                return control
            end
        end})
    end
    return tab
end
local state=Module.new(window)
assert(fps==200 and window.hud.Ammo==6 and window.hud.Health==100 and window.hud.Armor==0)
assert(#window.notes==0,"Initial empty armor must not alert")
ammo.Value=5; ammo.Changed:Fire(5); assert(window.hud.Ammo==5)
hp.Health=20; hp.HealthChanged:Fire(20); assert(window.hud.LowHealth and #window.notes==1)
hp.HealthChanged:Fire(19); assert(#window.notes==1)
armor.Value=100; armor.Changed:Fire(100)
armor.Value=10; armor.Changed:Fire(10); assert(window.hud.LowArmor and #window.notes==2)
state.profiles["[Revolver]"]=Module.profile({Style="Dot",Size=3}); state.Refresh()
assert(window.cross.Style=="Dot" and window.cross.Size==3,"Equipped weapon must select its own profile")
window.controls["Silah profillerini kaydet"].Callback()
assert(stored["scripts/spectre_crosshair_123.json"].profiles["[Revolver]"].Size==3)
table.remove(char.children,3); gun.Parent=nil; char.ChildRemoved:Fire(gun)
assert(window.hud.Ammo==nil and window.cross.Style=="Cross","Unequip must restore default and clear ammo")
ammo.Value=0; ammo.Changed:Fire(0); assert(window.hud.Ammo==nil,"Unequipped gun listeners must be disconnected")
player.CharacterRemoving:Fire()
hp.HealthChanged:Fire(1); assert(window.hud.Health==nil,"Old character listeners must be disconnected")
window:Destroy()
assert(state.destroyed and window.dead and window.cross==nil and window.hud==nil and fps==144)
for _,s in ipairs(signals) do for _,c in ipairs(s.handlers) do assert(not c.Connected,"Connection leak") end end
print("PASS: HUD profile validation, weapon selection, event updates, alert hysteresis, account storage, cleanup and FPS restoration")
