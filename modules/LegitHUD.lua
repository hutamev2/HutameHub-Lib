-- Spectre's passive HUD. Only local player/tool signals are observed.
local Module = {}
local DEFAULT = {Style="Cross",Size=7,Gap=4,Thickness=1,Dot=false,Outline=true,Color="FFFFFF",OffsetX=0,OffsetY=0}
local LIMITS = {Size={2,24},Gap={0,20},Thickness={1,5},OffsetX={-100,100},OffsetY={-100,100}}
function Module.profile(raw)
    raw = type(raw)=="table" and raw or {}
    local out = {}
    for key,value in pairs(DEFAULT) do out[key]=value end
    if raw.Style=="Cross" or raw.Style=="Dot" or raw.Style=="T" or raw.Style=="Circle" then out.Style=raw.Style end
    for key,bounds in pairs(LIMITS) do
        local n=tonumber(raw[key])
        if n and n==n and math.abs(n)<math.huge then out[key]=math.floor(math.max(bounds[1],math.min(bounds[2],n))) end
    end
    for _,key in ipairs({"Dot","Outline"}) do if type(raw[key])=="boolean" then out[key]=raw[key] end end
    if type(raw.Color)=="string" and raw.Color:match("^%x%x%x%x%x%x$") then out.Color=raw.Color:upper() end
    return out
end

-- Hysteresis and cooldown prevent notifications on every value event.
function Module.alert(state,value,threshold,now,eligible)
    if not eligible or value==nil then state.low=false; return false end
    if value>threshold+5 then state.low=false end
    if value<=threshold and not state.low then
        state.low=true
        if now-(state.last or -100)>8 then state.last=now; return true end
    end
    return false
end

function Module.new(window, options)
    assert(type(window.SetCrosshair)=="function", "Legit HUD requires the updated Drawing library")
    options=options or {}
    local players=game:GetService("Players")
    local run=game:GetService("RunService")
    local http=game:GetService("HttpService")
    local player=players.LocalPlayer
    local state={connections={},characterConnections={},toolConnections={},profiles={Default=Module.profile()},
        settings={crosshair=true,weaponOnly=false,hud=true,healthAlert=true,armorAlert=true,healthThreshold=30,armorThreshold=25,fps=200},
        editing="Default",healthAlarm={},armorAlarm={},samples={},sampleIndex=0,stats={},destroyed=false}
    local path="scripts/spectre_crosshair_"..tostring(player.UserId)..".json"
    local ok,saved=pcall(function() return http:JSONDecode(readfile(path)) end)
    if ok and type(saved)=="table" and saved.version==1 and type(saved.profiles)=="table" then
        for name,profile in pairs(saved.profiles) do
            if type(name)=="string" and #name<=100 then state.profiles[name]=Module.profile(profile) end
        end
    end
    local function disconnect(list)
        for _,connection in ipairs(list) do connection:Disconnect() end
        table.clear(list)
    end
    local function connect(list,signal,fn) list[#list+1]=signal:Connect(fn) end
    local tab=window:CreateTab("Legit")
    local editor=tab:CreateSection("Crosshair","left")
    local profiles=tab:CreateSection("Silah Profilleri","left")
    local alerts=tab:CreateSection("Mermi / Can / Zirh","right")
    local performance=tab:CreateSection("Akicilik","right")
    local controls,profileSelect,statsLabel={},nil,nil
    local syncing=false
    local function profileForWeapon()
        return state.profiles[state.weaponName] or state.profiles.Default
    end
    local function refresh()
        if state.destroyed then return end
        local preview=window.MainFrame.Visible and window.ActiveTab==tab
        local p=preview and state.profiles[state.editing] or profileForWeapon()
        p=p or state.profiles.Default
        if state.lastColor~=p.Color then state.lastColor=p.Color; state.color=Color3.fromHex(p.Color) end
        local alive=state.health==nil or state.health>0
        window:SetCrosshair({Visible=state.settings.crosshair and alive and (preview or not state.settings.weaponOnly or state.weaponName~=nil),
            Preview=preview,Style=p.Style,Size=p.Size,Gap=p.Gap,Thickness=p.Thickness,Dot=p.Dot,Outline=p.Outline,Color=state.color,OffsetX=p.OffsetX,OffsetY=p.OffsetY})
        window:SetStatusHUD({Visible=state.settings.hud and alive,Weapon=state.weaponName,Ammo=state.ammo,
            Health=state.health,Armor=state.armor,
            LowHealth=state.settings.healthAlert and state.health~=nil and state.health<=state.settings.healthThreshold,
            LowArmor=state.settings.armorAlert and state.hadArmor and state.armor~=nil and state.armor<=state.settings.armorThreshold})
    end
    local function notify(text) window:Notify({Title="Spectre HUD",Text=text,Duration=3}) end
    local function evaluateAlerts()
        local alive=state.health~=nil and state.health>0
        if Module.alert(state.healthAlarm,state.health,state.settings.healthThreshold,os.clock(),alive and state.settings.healthAlert) then
            notify("Can dusuk: "..math.ceil(state.health))
        end
        if Module.alert(state.armorAlarm,state.armor,state.settings.armorThreshold,os.clock(),alive and state.settings.armorAlert and state.hadArmor) then
            notify("Zirh dusuk: "..math.ceil(state.armor))
        end
        refresh()
    end
    local known={Default=true}
    for name in pairs(state.profiles) do known[name]=true end
    local function refreshOptions()
        if not profileSelect then return end
        local names={}
        for name in pairs(known) do if name~="Default" then names[#names+1]=name end end
        table.sort(names); table.insert(names,1,"Default")
        profileSelect:Refresh(names)
    end
    local function selectProfile(name)
        if not known[name] then return end
        state.editing=name
        state.profiles[name]=state.profiles[name] or Module.profile(state.profiles.Default)
        syncing=true
        for key,control in pairs(controls) do
            local value=state.profiles[name][key]
            control:Set(key=="Color" and Color3.fromHex(value) or value)
        end
        syncing=false
        refresh()
    end
    local function edit(key,value)
        if syncing then return end
        state.profiles[state.editing][key]=value
        refresh()
    end
    local function toggle(section,title,key,default)
        return section:CreateToggle({Title=title,Default=default,ConfigKey="legit_"..key,Callback=function(value)
            state.settings[key]=value; refresh()
        end})
    end
    toggle(editor,"Crosshair", "crosshair",true)
    toggle(editor,"Yalniz silah eldeyken","weaponOnly",false)
    controls.Style=editor:CreateDropdown({Title="Sekil",Options={"Cross","Dot","T","Circle"},Default=state.profiles.Default.Style,Callback=function(v) edit("Style",v) end})
    for _,definition in ipairs({{"Size","Boyut",2,24},{"Gap","Bosluk",0,20},{"Thickness","Kalinlik",1,5},{"OffsetX","Yatay ofset",-100,100},{"OffsetY","Dikey ofset",-100,100}}) do
        local key=definition[1]
        controls[key]=editor:CreateSlider({Title=definition[2],Min=definition[3],Max=definition[4],Default=state.profiles.Default[key],Callback=function(v) edit(key,v) end})
    end
    controls.Color=editor:CreateColorPicker({Title="Renk (HEX)",Default=Color3.fromHex(state.profiles.Default.Color),Callback=function(v) edit("Color",v:ToHex()) end})
    for _,definition in ipairs({{"Dot","Merkez noktasi"},{"Outline","Siyah dis cizgi"}}) do
        local key=definition[1]
        controls[key]=editor:CreateToggle({Title=definition[2],Default=state.profiles.Default[key],Callback=function(v) edit(key,v) end})
    end
    profileSelect=profiles:CreateDropdown({Title="Duzenlenen profil",Options={"Default"},Default="Default",Callback=selectProfile})
    profiles:CreateLabel("Bu sekme acikken secili profil onizlenir. Oyun sirasinda eldeki silahin profili kullanilir.")
    profiles:CreateButton({Title="Eldeki silahi duzenle",Callback=function()
        if state.weaponName then profileSelect:Set(state.weaponName) else notify("Once bir silah kusan.") end
    end})
    profiles:CreateButton({Title="Silah profillerini kaydet",Callback=function()
        local success,err=pcall(function() writefile(path,http:JSONEncode({version=1,profiles=state.profiles})) end)
        notify(success and "Silah profilleri kaydedildi." or "Profil kaydedilemedi.")
        if not success then warn(err) end
    end})
    profiles:CreateButton({Title="Secili profili sifirla",Callback=function()
        state.profiles[state.editing]=Module.profile(); selectProfile(state.editing)
    end})
    toggle(alerts,"Mermi / durum HUD","hud",true)
    toggle(alerts,"Dusuk can uyarisi","healthAlert",true)
    toggle(alerts,"Dusuk zirh uyarisi","armorAlert",true)
    for _,definition in ipairs({{"healthThreshold","Can esigi",30},{"armorThreshold","Zirh esigi",25}}) do
        local key=definition[1]
        alerts:CreateSlider({Title=definition[2],Min=5,Max=100,Default=definition[3],ConfigKey="legit_"..key,Callback=function(v)
            state.settings[key]=v; refresh()
        end})
    end
    alerts:CreateLabel("Esik gecisinde tek uyari. Zirhsiz dogunca bildirim verilmez.")
    if type(getfpscap)=="function" then local success,value=pcall(getfpscap); if success then state.previousCap=value end end
    local function applyCap()
        local farm=options.IsFarming and options.IsFarming()
        if farm or type(setfpscap)~="function" then return end
        if state.appliedCap~=state.settings.fps or state.wasFarming then
            local success=pcall(setfpscap,state.settings.fps)
            if success then state.appliedCap=state.settings.fps end
        end
    end
    performance:CreateDropdown({Title="FPS hedefi",Options={"120","144","165","200","240","360"},Default="200",ConfigKey="legit_fps",Callback=function(v)
        local allowed={[120]=true,[144]=true,[165]=true,[200]=true,[240]=true,[360]=true}
        local value=tonumber(v); state.settings.fps=allowed[value] and value or 200; applyCap()
    end})
    statsLabel=performance:CreateLabel("Kare suresi olculuyor...")
    performance:CreateLabel("200 Hz: 5 ms/kare hedefi. Olcum 4 saniyede yenilenir. Farm modu kendi FPS sinirini kullanir.")
    refreshOptions(); selectProfile("Default"); applyCap()

    local character,humanoid,armorValue,tool,ammoValue
    local function readAmmo()
        state.ammo=ammoValue and tonumber(ammoValue.Value) or nil
        refresh()
    end
    local function bindTool(nextTool)
        local nextAmmo=nextTool and nextTool:FindFirstChild("Ammo")
        if nextTool==tool and nextAmmo==ammoValue then return end
        disconnect(state.toolConnections)
        tool,ammoValue=nextTool,nextAmmo
        state.weaponName=tool and ammoValue and tool.Name or nil
        if state.weaponName then known[state.weaponName]=true; refreshOptions() end
        if ammoValue and ammoValue:IsA("ValueBase") then connect(state.toolConnections,ammoValue.Changed,readAmmo) else ammoValue=nil end
        readAmmo()
    end
    local function scanTool()
        if character then
            for _,child in ipairs(character:GetChildren()) do
                if child:IsA("Tool") and child:FindFirstChild("Ammo") then bindTool(child); return end
            end
        end
        bindTool(nil)
    end
    local function discoverVitals()
        if not character then return end
        local nextHumanoid=character:FindFirstChildOfClass("Humanoid")
        if nextHumanoid and humanoid~=nextHumanoid then
            humanoid=nextHumanoid
            state.health=humanoid.Health
            connect(state.characterConnections,humanoid.HealthChanged,function(v) state.health=v; evaluateAlerts() end)
        end
        local effects=character:FindFirstChild("BodyEffects")
        local nextArmor=effects and effects:FindFirstChild("Armor")
        if nextArmor and nextArmor:IsA("ValueBase") and armorValue~=nextArmor then
            armorValue=nextArmor; state.armor=tonumber(armorValue.Value)
            state.hadArmor=state.hadArmor or (state.armor~=nil and state.armor>0)
            connect(state.characterConnections,armorValue.Changed,function(v)
                state.armor=tonumber(v); state.hadArmor=state.hadArmor or (state.armor~=nil and state.armor>0); evaluateAlerts()
            end)
        end
        refresh()
    end
    local function bindCharacter(nextCharacter)
        disconnect(state.characterConnections); bindTool(nil)
        character,humanoid,armorValue=nextCharacter,nil,nil
        state.health,state.armor,state.hadArmor=nil,nil,false
        state.healthAlarm,state.armorAlarm={},{}
        if character then
            connect(state.characterConnections,character.ChildAdded,function(child)
                if child:IsA("Tool") then scanTool() end
            end)
            connect(state.characterConnections,character.ChildRemoved,function(child)
                if child==tool then scanTool() end
            end)
            connect(state.characterConnections,character.DescendantAdded,function(child)
                if child.Name=="Ammo" then scanTool()
                elseif child.Name=="Armor" or child:IsA("Humanoid") then discoverVitals() end
            end)
            discoverVitals(); scanTool()
        end
        refresh()
    end
    connect(state.connections,player.CharacterAdded,bindCharacter)
    connect(state.connections,player.CharacterRemoving,function() bindCharacter(nil) end)
    bindCharacter(player.Character)
    local backpack=player:FindFirstChildOfClass("Backpack")
    local function discoverWeapon(child)
        if child:IsA("Tool") and child:FindFirstChild("Ammo") then known[child.Name]=true; refreshOptions() end
    end
    if backpack then
        for _,child in ipairs(backpack:GetChildren()) do discoverWeapon(child) end
        connect(state.connections,backpack.ChildAdded,discoverWeapon)
    end
    -- The only per-frame work is one sample assignment; no rendering or tree walk.
    connect(state.connections,run.RenderStepped,function(dt)
        state.sampleIndex=state.sampleIndex%1200+1
        state.samples[state.sampleIndex]=dt
    end)
    local lastPreview,lastFarm
    task.spawn(function()
        local nextStats=os.clock()+4
        while not state.destroyed do
            local preview=window.MainFrame.Visible and window.ActiveTab==tab
            if preview~=lastPreview then lastPreview=preview; refresh() end
            local farm=options.IsFarming and options.IsFarming() or false
            if farm~=lastFarm then state.wasFarming=lastFarm; applyCap(); state.wasFarming=nil; lastFarm=farm end
            if os.clock()>=nextStats then
                nextStats=os.clock()+4
                local sorted,total={},0
                for _,dt in ipairs(state.samples) do sorted[#sorted+1]=dt; total=total+dt end
                if #sorted>0 and total>0 then
                    table.sort(sorted)
                    state.stats={fps=#sorted/total,p95=sorted[math.max(1,math.ceil(#sorted*.95))]*1000,samples=#sorted}
                    statsLabel:Set(string.format("FPS %.0f | p95 %.1f ms",state.stats.fps,state.stats.p95))
                end
                table.clear(state.samples); state.sampleIndex=0
            end
            task.wait(.2)
        end
    end)
    function state:Destroy()
        if self.destroyed then return end
        self.destroyed=true
        disconnect(self.connections); disconnect(self.characterConnections); disconnect(self.toolConnections)
        window:SetCrosshair(nil); window:SetStatusHUD(nil)
        if self.previousCap~=nil and type(getfpscap)=="function" and type(setfpscap)=="function" then
            local success,current=pcall(getfpscap)
            if success and current==self.appliedCap then pcall(setfpscap,self.previousCap) end
        end
    end
    local originalDestroy=window.Destroy
    window.Destroy=function(self) state:Destroy(); return originalDestroy(self) end
    state.Refresh=refresh
    state.Tab=tab
    return state
end
return Module
