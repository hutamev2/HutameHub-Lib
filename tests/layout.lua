-- Headless geometry and transition regression tests; no Roblox rendering claims.
local function signal()
    local s={handlers={}}
    function s:Connect(fn) table.insert(self.handlers,fn); return {Disconnect=function() end} end
    function s:Fire(...) for _, fn in ipairs(self.handlers) do fn(...) end end
    return s
end
local function pair(x,y) return {X=x or 0,Y=y or 0} end
Vector2={new=pair}
UDim={new=function(scale,offset) return {Scale=scale,Offset=offset} end}
UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
Enum=setmetatable({}, {__index=function(t,k)
    local group=setmetatable({}, {__index=function(g,n) local v={Name=n}; rawset(g,n,v); return v end})
    rawset(t,k,group); return group
end})
local function color() return {ToHex=function() return "ffffff" end} end
Color3={new=color,fromRGB=color}; ColorSequence={new=function() return {} end}
TweenInfo={new=function() return {} end}
math.clamp=function(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local tweens={}
local tweenService={Create=function(_,object,info,props)
    local tween={object=object,props=props}
    function tween:Cancel() self.cancelled=true end
    function tween:Play() self.started=true end
    table.insert(tweens,tween); return tween
end}
local function finishTweens()
    local pending=tweens; tweens={}
    for _, tween in ipairs(pending) do
        if tween.started and not tween.cancelled then
            for key,value in pairs(tween.props) do tween.object[key]=value end
        end
    end
end
game={GetService=function(_,name) return name=="TweenService" and tweenService or {} end}
warn=function() end
local gui={Frame=true,TextButton=true,TextLabel=true,ScrollingFrame=true,TextBox=true}
local events={MouseButton1Click=true,MouseEnter=true,MouseLeave=true,Destroying=true}
local function changed(parent)
    if not parent then return end
    for _, child in ipairs(parent.children) do
        if child.class=="UIListLayout" and child.signals.AbsoluteContentSize then
            child.signals.AbsoluteContentSize:Fire()
        end
    end
end
local methods={}
function methods:GetChildren() local out={}; for _,c in ipairs(self.children) do table.insert(out,c) end; return out end
function methods:IsA(class) return self.class==class or (class=="GuiObject" and gui[self.class]) end
function methods:GetAttribute(key) return self.attributes[key] end
function methods:SetAttribute(key,value) self.attributes[key]=value end
function methods:GetPropertyChangedSignal(key) self.signals[key]=self.signals[key] or signal(); return self.signals[key] end
function methods:FindFirstChild(name) for _,c in ipairs(self.children) do if c.Name==name then return c end end end
function methods:Destroy()
    self.Destroying:Fire()
    if self.Parent then
        for i,c in ipairs(self.Parent.children) do if c==self then table.remove(self.Parent.children,i); break end end
        changed(self.Parent)
    end
end
local mt={__index=function(self,key)
    if methods[key] then return methods[key] end
    if events[key] then self.signals[key]=self.signals[key] or signal(); return self.signals[key] end
    if key=="AbsoluteContentSize" then
        local height,count=0,0
        for _,c in ipairs(self.Parent.children) do
            if c:IsA("GuiObject") and c.Visible then height=height+c.Size.Y.Offset; count=count+1 end
        end
        return pair(0,height+math.max(0,count-1)*(self.Padding and self.Padding.Offset or 0))
    end
    if key=="Visible" and self.props[key]==nil then return true end
    if key=="CanvasPosition" then return self.props[key] or pair(0,0) end
    if key=="Size" then return self.props[key] or UDim2.fromOffset(0,0) end
    if key=="BackgroundTransparency" then return self.props[key] or 0 end
    return self.props[key]
end,__newindex=function(self,key,value)
    self.props[key]=value
    if key=="Parent" then table.insert(value.children,self) end
    if key=="Parent" or key=="Size" or key=="Visible" then changed(self.Parent) end
end}
Instance={new=function(class,parent)
    local obj=setmetatable({class=class,props={},children={},attributes={},signals={}},mt)
    if parent then obj.Parent=parent end
    return obj
end}
local Library=dofile("Source.lua")
local hub=setmetatable({_accentSubs={},ToggleKey=Enum.KeyCode.RightControl,Accent=color()}, {__index=Library})
local section=hub:_createSection("Regression",Instance.new("Frame"))
local dd=section:CreateDropdown({Title="Single",Options={"A","B","C"},MaxVisibleItems=2})
local card=section._card
local row=card:FindFirstChild("DD_Single")
local list=row:FindFirstChild("List")
local following=Instance.new("TextButton",card); following.Size=UDim2.fromOffset(100,22)
finishTweens(); local closedHeight=card.Size.Y.Offset
dd:Open(); finishTweens()
assert(row.Size.Y.Offset==71 and list.Size.Y.Offset==47 and list.CanvasSize.Y.Offset==68)
assert(card.Size.Y.Offset==closedHeight+49, "Section must reserve dropdown height")
dd:Refresh({"Only"}); finishTweens()
assert(row.Size.Y.Offset==50 and list.CanvasSize.Y.Offset==26)
dd:Close(); finishTweens(); assert(row.Size.Y.Offset==22 and not list.Visible)
assert(card.Size.Y.Offset==closedHeight)
dd:Open(); dd:Close(); dd:Open(); finishTweens(); assert(list.Visible and row.Size.Y.Offset==50)
local multi=section:CreateMultiDropdown({Title="Multi",Options={"A","B"}})
local multiRow=card:FindFirstChild("MDD_Multi")
multi:Open(); finishTweens(); assert(multiRow.Size.Y.Offset==71)
multi:Refresh({}); finishTweens(); assert(multiRow.Size.Y.Offset==30)
multi:Close(); finishTweens(); assert(multiRow.Size.Y.Offset==22)
local expanded=card.Size.Y.Offset
section:Collapse(); finishTweens(); assert(card.Size.Y.Offset==38)
section:Expand(); section:Collapse(); section:Expand(); finishTweens()
assert(card.Size.Y.Offset==expanded and card:GetAttribute("Collapsed")==false)
section:Collapse(); dd:Refresh({"A","B","C","D"}); section:Expand(); finishTweens()
assert(row.Size.Y.Offset==71 and card.Size.Y.Offset>expanded)
print("PASS: dropdown flow height, capped scrolling, refresh, multi-select, rapid section reversal")
