-- Headless behavioral tests. Run: fengari tests/features.lua
-- Roblox rendering/input delivery are intentionally outside this harness.
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
local encoded, serial = {}, 0
local http = {}
function http:JSONEncode(value)
    serial = serial + 1; local token = "json:" .. serial
    encoded[token] = copy(value); return token
end
function http:JSONDecode(token) assert(encoded[token], "Invalid JSON"); return copy(encoded[token]) end
Color3 = {fromRGB=function() return {} end, new=function() return {} end}
Enum = {KeyCode={Minus={Name="Minus"}, RightControl={Name="RightControl"}, F={Name="F"}, None={Name="None"}}}
game = {GetService=function(_, name) return name == "HttpService" and http or {} end}
warn = function() end
local files = {}
writefile = function(path, data) files[path] = data end
readfile = function(path) assert(files[path], "Missing file"); return files[path] end
delfile = function(path) assert(files[path], "Missing file"); files[path] = nil end
local Library = dofile("Source.lua")
local notices = {}
local hub = setmetatable({ToggleKey=Enum.KeyCode.RightControl}, {__index=Library})
hub.Notify = function(_, notice) table.insert(notices, notice) end
local value = "first"
hub:_regElement("text", function() return value end, function(v) value = v end)
assert(not pcall(function() hub:_regElement("text", function() end, function() end) end))
assert(hub:SaveProfile("work")); value = "changed"
assert(hub:LoadProfile("work")); assert(value == "first")
assert(hub:SetDefaultProfile("work")); value = "changed"
assert(hub:LoadDefaultProfile()); assert(value == "first")
assert(hub:RenameProfile("work", "renamed"))
assert(hub:ListProfiles()[1] == "renamed")
assert(hub:LoadDefaultProfile())
assert(hub:SaveProfile("occupied"))
assert(not hub:RenameProfile("renamed", "occupied"))
assert(not hub:SaveProfile("../bad"))
assert(not hub:SetDefaultProfile("missing"))
assert(hub:DeleteProfile("renamed")); assert(not hub:LoadDefaultProfile())
local writer = writefile; writefile = nil
assert(not hub:SaveProfile("unsupported")); writefile = writer
local reset = 0
hub._resetControls = {{Reset=function() reset=reset+1 end}, {Reset=function() reset=reset+1 end}}
hub:ResetValues(); assert(reset == 2)
local attrs, parentAttrs = {}, {}
local row = {BackgroundTransparency=1, Parent={GetAttribute=function(_, key) return parentAttrs[key] end}}
function row:SetAttribute(key, item) attrs[key] = item end
function row:GetDescendants() return {} end
local control, enabled = {}, false
hub._controlRows = {[control]=row}
hub:SetCondition(control, function() return enabled end, "hide")
assert(row.Visible == false)
enabled = true; hub:RefreshConditions(); assert(row.Visible == true)
parentAttrs.Collapsed=true; hub:RefreshConditions(); assert(row.Visible == false)
hub:SetCondition(control, function() return enabled end, "disable")
assert(row.Interactable == true)
enabled=false; hub:RefreshConditions(); assert(row.Interactable == false)
hub._bindings={{title="Action", get=function() return Enum.KeyCode.Minus end}}
hub:_checkBindings(); assert(notices[#notices].Title == "Key conflict")
local count = #notices; hub:_checkBindings(); assert(#notices == count)
hub._bindings={}; hub:_checkBindings()
hub._bindings={{title="Action", get=function() return Enum.KeyCode.Minus end}}
hub:_checkBindings(); assert(#notices == count+1)
print("PASS: profile lifecycle, storage failure, reset, conditions, binding warnings")

-- Minimal GUI nodes to exercise modal action dispatch (not rendering).
UDim2={fromScale=function() return {} end, fromOffset=function() return {} end, new=function() return {} end}
Vector2={new=function() return {} end}; Enum.Font={Code="Code"}
Instance={new=function(class, parent)
    local object={ClassName=class, children={}}
    object.Activated={Connect=function(event, fn) event.fire=fn end}
    function object:Destroy() self.destroyed=true end
    if parent then table.insert(parent.children,object) end
    return object
end}
hub.ScreenGui={children={}}
hub.Accent={}
local accepted, cancelled=0,0
local handle=hub:Confirm({OnConfirm=function() accepted=accepted+1 end, OnCancel=function() cancelled=cancelled+1 end})
handle.Cancel(); handle.Cancel()
assert(accepted==0 and cancelled==1)
hub:Confirm({OnConfirm=function() accepted=accepted+1 end})
local panel=hub._confirm.children[1]
local confirmButton=panel.children[#panel.children]
confirmButton.Activated.fire(); confirmButton.Activated.fire()
assert(accepted==1 and hub._confirm==nil)
print("PASS: confirmation cancel and exactly-once acceptance")
