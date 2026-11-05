-- Run from the project staging root or repository test runner.
local root = TEST_ROOT or "modkit/SceneZOI_93C44199/workspace/lua/"
package.path = root .. "B1/?.lua;" .. root .. "B2/?.lua;" .. package.path
assert(loadfile(TEST_CONTENT_ROOT.."/tests/support/profiles.lua"))()
package.loaded["SceneZOI.Gaze"] = {
    prepare=function() return true end, ready=function() return true end,
    enter=function() end, sample=function() end, guard=function() end,
    leave_node=function() end, restore=function() end, status=function() return "test_gaze" end,
}
package.loaded["SceneZOI.ExpressionNative"]={
    body=function(p)return p.body end,bind=function()return true end,
    play=function(o,clip)o.clip=clip end,hold=function()end,stop=function(o)o.clip=nil end,
}
package.loaded["SceneZOI.FacialPose"]={sample=function()end,guard=function()end,restore=function()end}
local fixture=assert(loadfile(TEST_CONTENT_ROOT.."/tests/fixtures/catalog.lua"))()
for _,node in pairs(fixture.nodes)do for _,role in pairs(node.participants)do role.body_age="Adult";role.growth_steps={"Youth","Adult","Old","Elderly"}end end
fixture.profiles={rules={}}
package.loaded["SceneZOI.GeneratedCatalog"]=fixture
local Catalog=require("SceneZOI.Catalog");Catalog.value=fixture;Catalog.refresh=function()return fixture end
package.loaded["SceneZOI.DataFiles"]={refresh=function()return {by_kind={},warnings={}}end,get=function()return {by_kind={},warnings={}}end,documents=function()return {}end}
local Protocol = require("SceneZOI.Protocol")
local Container=assert(loadfile("tests/support/containers.lua"))()
local cfg, actors, owners, bindings = {}, {}, {}, {}
local runtime, participant
local heartbeat, drop_ready, drop_release, sample_failure, read_failure = 0, false, false, false, false
local drop_outfit_reply=false
local drop_inventory=false
local client_restore_failure = false
local anatomy_ready, anatomy_available, anatomy_cleanup_failure = true, true, false
local anatomy_created, anatomy_destroyed = 0, 0
local anatomy_by_actor = {}
local fail_attachment_actor
local anatomy_current
local anatomy_animation_available, anatomy_sample_failure = true, false
local pending_body_ticks,body_readiness_calls=0,0
local anatomy_wraps, anatomy_samples = 0, 0
local game_scale, controlled_id = 1, "20524"
local toast_failure=false
local autosave_enabled=true
local counts = {toasts=0,cancel = 0, starts = 0, releases = 0, holds = 0, guards = 0}
UE = {
    FVector = function(x,y,z) return {X=x,Y=y,Z=z} end,
    FRotator = function(p,y,r) return {Pitch=p,Yaw=y,Roll=r} end,
    UAnimSequence = {StaticClass=function()return "sequence"end},
    UObject = {Load = function(path)
        return {IsA=function()return true end,GetPlayLength=function() return path:find("idle", 1, true) and 3 or 10 end}
    end},
}
package.loaded["SceneZOI.Native"] = {
    capture = function(actor) assert(not actor.playing); return {actor=actor,mesh=actor.mesh} end,
    desired_transform = function(_,anchor) return anchor end,
    rebind = function() end,
    stop_track = function(record) record.actor.playing=false end,
    enter = function(record) record.changed=true; record.actor.playing=true; counts.starts=counts.starts+1 end,
    hold = function(record)
        assert(record.actor.playing,"Navigation exposed the default idle during preparation")
        counts.holds=counts.holds+1
        return true
    end,
    sample = function(record,position)
        if sample_failure then sample_failure=false; error("Injected animation error") end
        record.actor.scene_position=position
    end,
    restore = function(record)
        if client_restore_failure then client_restore_failure=false;error("Injected client restore error") end
        record.actor.playing=false;record.changed=false
    end,
    release_input = function() counts.releases=counts.releases+1 end,
}
local appearance_ready = true
local real_appearance = require("SceneZOI.Appearance")
package.loaded["SceneZOI.Appearance"] = {
    capture=real_appearance.capture,
    status=function(current) return real_appearance.status and real_appearance.status(current) or "test_appearance" end,
    ready=function(current) return appearance_ready and real_appearance.ready(current) end,
}
local real_attachment=require("SceneZOI.Attachment")
package.loaded["SceneZOI.Attachment"] = {
    begin_outfit=real_attachment.begin_outfit,
    guard=function(current) if current.attachment then counts.guards=counts.guards+1;real_attachment.guard(current) end end,
    status=function() return "test_ready_state" end,
    load=function(node)
        if not node.attachment then return end
        assert(anatomy_available, "Attachment asset unavailable")
        assert(anatomy_animation_available, "Attachment animation unavailable")
        return {}, {}, node.attachment.animation
    end,
    prepare=function(current,actor)
        if not current.node.attachment then return end
        if pending_body_ticks>0 then pending_body_ticks=pending_body_ticks-1;return false end
        if actor==fail_attachment_actor then error("Injected second-owner attachment failure") end
        if current.attachment then return true end
        current.attachment={frames=0,animation=current.attachment_animation,hidden=true,actor=actor,hide_calls=0}
        current.attachment.component={bHiddenInGame=true,SetHiddenInGame=function(self,value)
            current.attachment.hidden=value;self.bHiddenInGame=value
            if value then current.attachment.hide_calls=current.attachment.hide_calls+1 end
        end}
        anatomy_current=current.attachment;anatomy_by_actor[actor]=current.attachment;anatomy_created=anatomy_created+1
    end,
    change_animation=function(current)
        assert(current.attachment==anatomy_by_actor[current.attachment.actor],"The physical component must survive a node change")
        if current.attachment.animation~=current.attachment_animation then
            current.attachment.animation=current.attachment_animation
            current.attachment.frames=0
        end
    end,
    enter=function(current)
        for _,p in ipairs(current.participants) do assert(p.actor.playing) end
        current.attachment.animation=current.attachment_animation
        current.outfit_visibility_hold=nil
        current.attachment.component:SetHiddenInGame(current.hide_attachment==true)
    end,
    ready=function(current)
        assert(pending_body_ticks==0,"Attachment readiness inspected an unfinished body rebuild")
        body_readiness_calls=body_readiness_calls+1
        if not current.node.attachment then return true end
        if not current.attachment or not anatomy_ready then return false end
        current.attachment.frames=current.attachment.frames+1
        return current.attachment.frames>=3
    end,
    sample=function(current,position)
        if not current.node.attachment then return end
        if anatomy_sample_failure then anatomy_sample_failure=false;error("Injected attachment seek failure") end
        for _,p in ipairs(current.participants) do assert(p.actor.scene_position==position,"Tracks must share the clock") end
        local attachment=current.attachment
        if attachment.position and position<attachment.position then anatomy_wraps=anatomy_wraps+1 end
        attachment.position=position;anatomy_samples=anatomy_samples+1
    end,
    restore=function(current)
        if anatomy_cleanup_failure then anatomy_cleanup_failure=false;error("Injected attachment cleanup failure") end
        if current.attachment then anatomy_by_actor[current.attachment.actor]=nil;anatomy_destroyed=anatomy_destroyed+1;current.attachment=nil end
    end,
}

inzoi = {
    UB1System={Get=function() return {GetTimeManager=function() return {GetTimeScale=function() return game_scale end} end} end},
    EB1BodyAgeType={Adult=1}, EB1GenderType={Male=1,Female=2}, EB2ComponentType={Autonomy=1,Appearance=2,Interaction=3},
    EB1GrowthStep={Youth=32,Adult=64,Old=128,Elderly=256}, EB1ChangeOutfitReason={Invalid=0,Script=2},
    FB1StyleSetting=Container.style,
    FB1GarmentDescription=function() return {} end,
    FB1AccessoryDescription=function() return {} end,
    FB1PrintedAccessoryDescription=function() return {PrintedAccessoryData=Container.map()} end,
    cli={execute=function(command)
        local key=command:match("key=([^ ]+)")
        if command:match("^uimod.cfg_load") then
            if read_failure then read_failure=false; error("Injected config read error") end
            return true,"",cfg[key] and ('{"value":"'..cfg[key]..'"}') or nil
        elseif command:match("^uimod.cfg_save") then cfg[key]=command:match("value=(.*)"); return true,""
        elseif command:match('^toast.show') then
            counts.toasts=counts.toasts+1
            if toast_failure then toast_failure=false;error('Injected optional toast failure')end
            return true,''
        elseif command=='gameplay.get_settings'then return true,'',require('SceneZOI.Json').encode({auto_save_enabled=autosave_enabled and '1'or '0',auto_save_interval='15'})
        elseif command:match('^gameplay.set_autosave')then
            assert(not command:find('interval',1,true),'Do not change the autosave interval')
            autosave_enabled=command:match('enable=(%w+)')=='true';return true,''
        elseif command=="entity.get_possessed" then return true,"",'{"entity_id":'..controlled_id..'}'
        elseif command:match("^autonomy.set_enable") then
            local owner=owners[command:match("entity_id=(%d+)")]
            local option=owner.AutonomyOption.AutonomyEnable
            option.Value=command:match("enable=(%w+)")=="true";option.bFollowParent=false
            return true,""
        elseif command:match("^interaction.clear_queue") then
            owners[command:match("entity_id=(%d+)")].queued=0
            return true,""
        elseif command:match("^interaction.cancel") then
            counts.cancel=counts.cancel+1
            owners[command:match("entity_id=(%d+)")].task_ticks=2
            return true,""
        end
        error("Unexpected CLI: "..command)
    end},
    message={
        send_to_sim=function(id,kind,content)
            local key=tostring(id.Value)
            participant.on_lua_message(bindings[key],owners[key],kind,content)
        end,
        send_to_client=function(id,kind,content)
            if kind=="SceneZOI.Event" then return end
            if kind=="SceneZOI.Save" then runtime.save_reply(actors[tostring(id.Value)],content);return end
            if drop_ready and content:find("|ready|") then drop_ready=false;return end
            if drop_release and content:find("|released|") then drop_release=false;return end
            if drop_outfit_reply and content:find("|outfit|1|",1,true) then drop_outfit_reply=false;return end
            if drop_inventory and content:find("|outfit|",1,true) then drop_inventory=false;return end
            runtime.reply(actors[tostring(id.Value)],content)
        end,
    },
}
for _,id in ipairs({"20522","20524","20530","20532"}) do
    local actor={playing=false,mesh={K2_GetComponentToWorld=function() return {} end}}
    local instance={}
    function actor.mesh:GetAnimInstance() return instance end
    -- Rendering/layout is exercised by the framework's body and clothing-mask tests.
    function actor.mesh:GetSkeletalMeshAsset() return nil end
    actor.Mesh=actor.mesh
    local garments={Top={GarmentId="original_shirt",BodyFlags=0},Bottom={GarmentId="original_pants",BodyFlags=1 << 17},
        InnerTop={GarmentId=id=="20524" and "original_bra" or "None"},
        InnerUnder={GarmentId="original_underwear",BodyFlags=1 << 17}}
    Container.map(garments)
    local originals,original_flags={},{}
    for slot, garment in pairs(garments) do
        if type(garment)=="table" then originals[slot]=garment.GarmentId;original_flags[slot]=garment.BodyFlags end
    end
    local accessories=Container.map({Glasses={AccessoryId="original_glasses",AccessoryMeshId="glasses_mesh",VectorParameters={Tint="blue"}},
        Bag={AccessoryId="original_bag",AccessoryMeshId="bag_mesh",SocketNames={"hand_r"}}})
    local printed=Container.array()
    printed:Add({PrintedAccessoryName="canvas_props",PrintedAccessoryData=Container.map({hand_l={PrintedAccessoryId="canvas_bag",SaveData={scale=1.2}},
        head={PrintedAccessoryId="canvas_hat",SaveData={scale=.8}}})})
    local original_accessories,original_printed=Container.copy(accessories),Container.copy(printed)
    actor.AppearanceComponent={AppearanceSetting={Body={bUseMeshMerge=true},FinalBody={bUseMeshMerge=false},
        FinalStyle={Outfit={Garments=garments,Accessories=accessories,PrintedAccessories=printed}}}}
    function actor:GetEntityId() return {Value=tonumber(id)} end
    function actor:K2_GetActorLocation() return UE.FVector(0,0,0) end
    function actor:K2_GetActorRotation() return UE.FRotator(0,0,0) end
    actors[id]=actor
    local owner={AutonomyOption={AutonomyEnable={Value=true,bFollowParent=true}},collision=true,task_ticks=0}
    function owner:GetFirstName() return id=="20522" and "Jonovan" or "Wonyoung" end
    function owner:GetLastName() return "Jang" end
    function owner:GetEntityId() return {Value=tonumber(id)} end
    function owner:IsPossess() return id==controlled_id end
    function owner:GetBodyAgeType() return 1 end
    function owner:GetGenderType() return self.bio_gender or ((id=="20522" or id=="20530") and 1 or 2) end
    function owner:GetGrowthStep() return self.growth or 32 end
    function owner:GetAutonomyOption() return self.AutonomyOption end
    function owner:GetLocation() return UE.FVector(0,0,0) end
    function owner:GetRotation() return UE.FRotator(0,0,0) end
    function owner:IsCollisionEnabled() return self.collision end
    function owner:SetCollisionEnabled(value) self.collision=value end
    function owner:IsPlayingInteraction() return self.task_ticks>0 end
    function owner:SetLocationAndRotationOnlySimul() end
    function owner:IsAutonomyEnable() return self.AutonomyOption.AutonomyEnable.Value end
    function owner:RefreshAutonomyOptionCache()
        if self.restore_failure and self.AutonomyOption.AutonomyEnable.Value then
            self.restore_failure=false;error("Injected autonomy restore error")
        end
    end
    local appearance={active="None"}
    function appearance:GetActiveCostumeIdByReason() return self.active end
    function appearance:GetAppearanceSetting()
        local setting=actor.AppearanceComponent.AppearanceSetting
        return {Gender=(id=="20522" or id=="20530") and 1 or 2,Body=setting.Body,FinalBody=setting.FinalBody,Outfit={ActiveStyleList={}},FinalStyle=setting.FinalStyle}
    end
    function appearance:SetAppearanceSetting(setting)
        actor.AppearanceComponent.AppearanceSetting.Body=setting.Body
        actor.AppearanceComponent.AppearanceSetting.FinalBody=setting.FinalBody
    end
    function appearance:RefreshAppearance() end
    function appearance:EmplaceActiveOutfit(style,costume)
        assert(style.Reason==2,"The native style must carry its own Script reason")
        self.active=costume;owner.undressed=true
        if style.Outfit.Garments.Top then assert(style.Outfit.Garments.Top.GarmentId=="None" or style.Outfit.Garments.Top.GarmentId=="original_shirt") end
        assert(not style.Outfit.Garments.Hat and not style.Outfit.Garments.Ring)
        for slot, garment in pairs(style.Outfit.Garments) do
            if type(garment)=="table" then garments[slot]={GarmentId=garment.GarmentId,BodyFlags=garment.BodyFlags} end
        end
        for slot, description in pairs(style.Outfit.Accessories:ToTable()) do accessories:Add(slot,description) end
        if #style.Outfit.PrintedAccessories>0 then
            actor.AppearanceComponent.AppearanceSetting.FinalStyle.Outfit.PrintedAccessories=Container.array()
            for _,description in ipairs(style.Outfit.PrintedAccessories) do actor.AppearanceComponent.AppearanceSetting.FinalStyle.Outfit.PrintedAccessories:Add(description) end
        end
        -- Mirror UpdateFinalUnderwear: final appearance normalizes BOTH underwear slots.
        if style.Outfit.Garments.InnerUnder and style.Outfit.Garments.InnerUnder.GarmentId=="None" then garments.InnerUnder={GarmentId=(id=="20522" or id=="20530") and "M_InnUnder01_001" or "W_InnUnder01_001"} end
        if id=="20524" and style.Outfit.Garments.InnerTop and style.Outfit.Garments.InnerTop.GarmentId=="None" then garments.InnerTop={GarmentId="W_InnTop01_001"} end
        if owner.normalize_on_top and id=="20524" then
            garments.InnerTop=garments.Top.GarmentId=="None" and {GarmentId="W_InnTop03_001"} or nil
        end
    end
    function appearance:RemoveCostumeByCostumeId(costume)
        assert(costume=="SceneZOI_Demo_Outfit")
        self.active="None";owner.undressed=false
        for key,value in pairs(original_accessories) do accessories:Add(key,value) end
        local fresh=Container.array();for _,description in ipairs(original_printed) do fresh:Add(description) end
        actor.AppearanceComponent.AppearanceSetting.FinalStyle.Outfit.PrintedAccessories=fresh
        for slot, value in pairs(garments) do if type(value)=="table" then garments[slot]={GarmentId=originals[slot] or "None",BodyFlags=original_flags[slot]} end end
        if owner.normalize_on_top and id=="20524" then garments.InnerTop=nil end
    end
    function owner:GetComponent(kind)
        if kind==2 then return appearance end
        if kind==3 then return {IsQueueEmpty=function()return (self.queued or 0)==0 end,
            GetCurrentInteractionQueueId=function()return self.task_id or 1 end}end
        return {OnAutonomyOptionChanged=function() end,SendAutonomyEnablePacket=function() end}
    end
    owners[id],bindings[id]=owner,{}
end
runtime=require("SceneZOI.Runtime")
participant=assert(loadfile(root.."B2/Zoi/SceneZOI.lua"))()
for id,actor in pairs(actors) do runtime.register(actor);participant.on_begin(bindings[id],owners[id]) end
runtime.boot()
local function step(n,sequence,with_heartbeat)
    for _=1,n do
        if with_heartbeat~=false then
            heartbeat=heartbeat+1
            cfg.heartbeat=Protocol.pack("test",sequence,"heartbeat",heartbeat)
        end
        if cfg.save_snapshot then
            local saved=require('SceneZOI.Json').decode(assert(Protocol.decode(cfg.save_snapshot)))
            cfg.save_ready=Protocol.pack(saved.client,saved.sequence,'ready',saved.token)
        end
        runtime.tick(0.2)
        for id,owner in pairs(owners) do
            if owner.task_ticks>0 and owner.task_ticks<99 then owner.task_ticks=owner.task_ticks-1 end
            participant.on_tick(bindings[id],owner,0.2)
        end
    end
end
local function request(sequence,action,node,assigned)
    local roster=assigned or controlled_id=="20524" and "female:20524+male:20522" or "male:20522+female:20524"
    cfg.request=Protocol.pack("test",sequence,action,controlled_id,node or "scenezoi.standing_idle",roster)
end
local function expect(sequence,phase,code)
    assert(cfg.state==Protocol.pack("test",sequence,phase,code or "ok"),"Unexpected state: "..tostring(cfg.state).." "..tostring(cfg.last_error))
end
local function restored()
    assert(autosave_enabled,'Exit must restore originally enabled autosave')
    for id,owner in pairs(owners) do
        assert(not owner.undressed,"Prototype clothing layer leaked")
        assert(not bindings[id].lease,"Participant lease leaked")
        assert(not actors[id].playing,"Animation player leaked")
        local garments=actors[id].AppearanceComponent.AppearanceSetting.FinalStyle.Outfit.Garments
        assert(garments.Top.GarmentId=="original_shirt" and garments.Bottom.GarmentId=="original_pants")
        if id=="20524" then
            if owner.normalize_on_top then assert(not garments.InnerTop,"The initially absent underwear layer was not restored")
            else assert(garments.InnerTop.GarmentId=="original_bra","Female original outfit was not restored") end
        end
        assert(owner.collision and owner.AutonomyOption.AutonomyEnable.Value and owner.AutonomyOption.AutonomyEnable.bFollowParent,
            "Original collision/autonomy options were not restored")
    end
    assert(anatomy_created==anatomy_destroyed,"Prototype component leaked")
end

local function navigation(sequence, count, option, revision)
    cfg.navigation=Protocol.pack("test",sequence,"navigate",count,option,revision)
end
local function node_state(sequence, revision, node, count, code)
    assert(cfg.navigation_state==Protocol.pack("test",sequence,revision,node,count,code or "ok"),
        "Unexpected navigation state: "..tostring(cfg.navigation_state))
end
-- Preserve the baseline's duplicate/retry/task/autonomy/focus behavior on a fully neutral node.
for sequence=1,20 do
    if sequence==2 then owners["20522"].task_ticks=99 end
    if sequence==3 then drop_ready=true end
    request(sequence,"start");step(12,sequence);expect(sequence,"playing")
    node_state(sequence,1,"scenezoi.standing_idle",0)
    assert(anatomy_created==0 and not owners["20522"].undressed and not owners["20524"].undressed,
        "Neutral hub must work without attachments or outfit changes")
    local starts=counts.starts
    step(10,sequence);assert(counts.starts==starts,"Duplicate Start replayed")
    if sequence==4 then drop_release=true end
    if sequence==5 then owners["20522"].restore_failure=true end
    if sequence==6 then client_restore_failure=true end
    request(sequence,"exit");step(12,sequence);expect(sequence,"idle");restored()
    request(sequence,"start");step(2,sequence);expect(sequence,"idle");restored()
end
cfg.focus=Protocol.pack("test",20,"closed");step(2,20)
assert(counts.releases==1);step(2,20);assert(counts.releases==1)
assert(counts.cancel==1)

request(21,"start");step(12,21);expect(21,"playing")
local male_lease=bindings["20522"].lease
local original_location=male_lease.entry_location
-- Entering HZoi's idle loads no anatomy and does not change either outfit.
anatomy_available=false
navigation(21,1,"hzoi.enter",1);step(12,21)
expect(21,"playing");node_state(21,2,"hzoi.standing_idle",1)
assert(not owners["20522"].undressed and not owners["20524"].undressed and anatomy_created==0)
-- Missing resources leave this clothed idle and the session snapshot intact.
navigation(21,2,"standing_hand_job",2);step(3,21)
expect(21,"playing");node_state(21,2,"hzoi.standing_idle",2,"navigation_error")
assert(not owners["20522"].undressed and anatomy_created==0)
anatomy_available=true;anatomy_animation_available=false
navigation(21,3,"standing_hand_job",2);step(3,21)
expect(21,"playing");node_state(21,2,"hzoi.standing_idle",3,"navigation_error")
anatomy_animation_available=true
local starts=counts.starts
anatomy_ready=false
navigation(21,4,"standing_hand_job",2);step(8,21);expect(21,"preparing")
runtime.reply(actors["20522"],Protocol.pack(male_lease.token,"ready","male",2))
assert(counts.starts==starts,"A stale readiness reply started the new scene")
assert(owners["20522"].undressed and not owners["20524"].undressed)
anatomy_ready=true;step(5,21);expect(21,"playing");node_state(21,3,"hzoi.standing_hand_job",4)
local retained=anatomy_current
assert(anatomy_created==1 and anatomy_destroyed==0)
assert(bindings["20522"].lease==male_lease and male_lease.entry_location==original_location,
    "Navigation replaced the session restoration state")
starts=counts.starts;step(12,21);assert(counts.starts==starts,"Navigation retry repeated the node change")
step(55,21);assert(anatomy_wraps>0 and anatomy_samples>0)
local revision, command = 3, 4
local function go(option, target)
    command=command+1;navigation(21,command,option,revision);step(12,21)
    revision=revision+1;expect(21,"playing");node_state(21,revision,target,command)
    assert(anatomy_current==retained and anatomy_created==1 and anatomy_destroyed==0,
        "Navigation recreated or destroyed the retained anatomy")
    assert(owners["20522"].undressed,"The male was redressed on a node change")
    if target=="hzoi.standing_idle" or target=="scenezoi.standing_idle" then
        assert(retained.animation:find("HZOI_Standing_idle_MA",1,true),"A hub must use the idle anatomy track")
        assert(#runtime.snapshot().tracks==3,"Retained anatomy must share the hub clock")
    end
end
go("idle","hzoi.standing_idle")
go("neutral","scenezoi.standing_idle")
assert(not owners["20524"].undressed,"Handjob must leave the female outfit unchanged")
go("hzoi.enter","hzoi.standing_idle")
go("standing_kneeling","hzoi.standing_kneeling")
assert(not owners["20524"].undressed,"Blowjob must leave the female outfit unchanged")
go("idle","hzoi.standing_idle")
go("standing_rear","hzoi.standing_rear")
assert(owners["20524"].undressed,"Rear sex must also undress the female")
go("idle","hzoi.standing_idle")
go("standing_hand_job","hzoi.standing_hand_job")
assert(owners["20524"].undressed,"A scene without a female directive must preserve her current outfit state")
go("idle","hzoi.standing_idle")
go("neutral","scenezoi.standing_idle")
assert(owners["20524"].undressed and male_lease.entry_location==original_location)
command=command+1;navigation(21,command,"hzoi.enter",1);step(4,21)
node_state(21,revision,"scenezoi.standing_idle",command,"stale_navigation")
request(21,"exit");step(12,21);expect(21,"idle");restored()
assert(anatomy_created==1 and anatomy_destroyed==1,"The retained component must be removed once at session end")

-- Exit wins while the first attachment is still preparing.
request(22,"start","hzoi.standing_idle");step(12,22)
anatomy_ready=false;navigation(22,1,"standing_hand_job",1);step(4,22);expect(22,"preparing")
request(22,"exit");step(12,22);expect(22,"idle");restored();anatomy_ready=true
-- Appearance readiness is independent of optional attachment readiness.
appearance_ready=false;request(23,"start");step(12,23);expect(23,"preparing")
request(23,"exit");step(12,23);expect(23,"idle");restored();appearance_ready=true
request(24,"start");step(12,24);step(40,24,false);expect(24,"error","ui_disconnected");restored()
owners["20522"].growth=16
request(25,"start","hzoi.standing_idle");step(12,25);expect(25,"error","eligibility");restored()
owners["20522"].growth=nil
request(26,"start","hzoi.standing_hand_job");step(12,26);expect(26,"playing")
anatomy_cleanup_failure=true;request(26,"exit");step(1,26);expect(26,"exiting")
step(12,26);expect(26,"idle");restored()
-- Game pause freezes animation time, while speed commands and Exit remain live.
request(27,"start","hzoi.standing_hand_job");step(12,27);expect(27,"playing")
local snapshot=runtime.snapshot()
assert(snapshot.participants[1].control=="controlled" and snapshot.participants[1].body=="female")
assert(snapshot.participants[2].control=="npc" and #snapshot.tracks==3)
local before=actors["20522"].scene_position
game_scale=0;step(20,27);expect(27,"playing")
assert(actors["20522"].scene_position==before and actors["20524"].scene_position==before)
cfg.playback=Protocol.pack("test",27,"speed",1,4);step(3,27)
assert(runtime.snapshot().speed_index==4 and runtime.snapshot().effective_speed==0)
assert(actors["20522"].scene_position==before)
game_scale=2
step(1,27)
local expected=(before+.2*2*2.00)%10
assert(math.abs(actors["20522"].scene_position-expected)<0.000001)
assert(actors["20524"].scene_position==actors["20522"].scene_position)
navigation(27,1,"idle",1);step(12,27);expect(27,"playing")
assert(runtime.snapshot().speed_index==4,"A node change reset the session speed")
game_scale=0;request(27,"exit");step(12,27);expect(27,"idle");restored()
-- A paused UI disconnect still follows the existing watchdog cleanup path.
request(28,"start");step(12,28);expect(28,"playing")
step(40,28,false);expect(28,"error","ui_disconnected");restored()
-- Swapping which body the player controls must not change track ownership.
game_scale=1;controlled_id="20522"
request(29,"start");step(12,29);expect(29,"playing")
snapshot=runtime.snapshot()
assert(snapshot.participants[1].control=="controlled" and snapshot.participants[1].body=="male")
assert(snapshot.participants[2].control=="npc" and snapshot.participants[2].body=="female")
request(29,"exit");step(12,29);expect(29,"idle");restored()
local Events=require("SceneZOI.Events")
local history=Events.history()
assert(history[#history].name=="session_ended")
local speed_events=0
local handle=Events.subscribe("playback_speed_changed",function(event)
    speed_events=speed_events+1
    event.node_id="mutated_observer_copy"
end)
request(30,"start");step(12,30)
cfg.playback=Protocol.pack("test",30,"speed",1,3);step(4,30)
assert(speed_events==1 and runtime.snapshot().node_id=="scenezoi.standing_idle")
step(4,30);assert(speed_events==1,"Retried speed command emitted duplicate notifications")
cfg.playback=Protocol.pack("test",30,"speed",0,1);step(2,30)
assert(runtime.snapshot().speed_index==3,"Old speed command was applied")
cfg.playback=Protocol.pack("test",29,"speed",99,4);step(2,30)
assert(runtime.snapshot().speed_index==3,"Another session changed the speed")
request(30,"exit");step(12,30);restored()
Events.unsubscribe(handle)
local cancel_handle=Events.subscribe("node_entered",function() runtime.stop("ok") end)
request(31,"start");step(12,31);expect(31,"idle");restored()
Events.unsubscribe(cancel_handle)
print("Tier 1 integration passed: paused Exit/watchdog, multiplied game/scene rates, speed persistence, controlled male/female binding, shared attachment time and lifecycle notifications.")
print("Demo session tests passed: neutral independence, all four sets, session snapshots, node revisions, stale/duplicate navigation, asset failures, shared clock, early Exit, outfit restoration, heartbeat and retry regressions.")

-- A readiness timeout must identify appearance, retain the cause and still restore.
appearance_ready=false
request(32,"start");step(45,32);expect(32,"error","appearance_timeout");restored()
assert(cfg.last_error and cfg.last_error:find("appearance_timeout",1,true),"Timeout cause was lost during cleanup")
appearance_ready=true
print("Rear-scene integration uses the real appearance barrier with normalized female underwear; stage-specific timeouts preserve diagnostics and cleanup.")
-- Direct rear entry from clothed idles must also start all three tracks.
request(33,"start");step(12,33);expect(33,"playing")
navigation(33,1,"hzoi.enter",1);step(12,33)
navigation(33,2,"standing_rear",2);step(12,33);expect(33,"playing")
assert(owners["20522"].undressed and owners["20524"].undressed and #runtime.snapshot().tracks==3)
navigation(33,3,"idle",3);step(12,33);expect(33,"playing")
assert(owners["20522"].undressed and owners["20524"].undressed)
request(33,"exit");step(12,33);expect(33,"idle");restored()
print("Direct rear entry regression passed for controlled male/NPC female; male-already-undressed navigation also passed with the other control direction.")

-- A malformed self-target request is rejected before participant capture/leases.
local started=counts.starts
cfg.request=Protocol.pack("test",34,"start",controlled_id,"scenezoi.standing_idle","male:"..controlled_id.."+female:"..controlled_id)
step(12,34);expect(34,"error","entry_error");restored()
assert(counts.starts==started and not runtime.snapshot())
local input_releases=counts.releases
runtime.authorize_rejected_focus(actors[controlled_id],"picker.one")
cfg.focus=Protocol.pack("test",34,"rejected",controlled_id,"picker.one")
step(2,34);assert(counts.releases==input_releases+1,"A rejected entry must release native input without a session")
runtime.authorize_rejected_focus(actors[controlled_id],"picker.two")
step(2,34);assert(counts.releases==input_releases+1,"An old notice must not consume a newer picker authorization")
cfg.focus=Protocol.pack("test",34,"rejected",controlled_id,"picker.two")
step(2,34);assert(counts.releases==input_releases+2,"Repeated notices need independent focus acknowledgements")
step(2,34);assert(counts.releases==input_releases+2,"Duplicate cancellation must not repeatedly steal focus")
owners["20522"].bio_gender=2;owners["20524"].bio_gender=1
request(35,"start");step(12,35);expect(35,"playing")
assert(runtime.snapshot().participants[1].body=="male","Track binding must use appearance body rather than bio gender")
request(35,"exit");step(12,35);expect(35,"idle");restored()
print("Malformed self-target request rejected without acquiring participants; the following valid session still starts and exits.")

-- Delay outfit and attachment preparation across multiple ticks: neither body
-- may drop its old pose, and the new attachment must not appear ahead of them.
request(36,"start","hzoi.standing_idle");step(12,36);expect(36,"playing")
local held_position=actors["20522"].scene_position
local held_starts=counts.starts
appearance_ready=false
navigation(36,1,"standing_hand_job",1);step(4,36);expect(36,"preparing")
assert(actors["20522"].playing and actors["20524"].playing and counts.starts==held_starts)
assert(actors["20522"].scene_position==held_position and actors["20524"].scene_position==held_position)
game_scale=0;cfg.playback=Protocol.pack("test",36,"speed",1,3)
step(3,36);assert(runtime.snapshot().speed_index==3 and runtime.snapshot().effective_speed==0)
appearance_ready=true;anatomy_ready=false
step(6,36);expect(36,"preparing")
assert(anatomy_current.hidden and counts.starts==held_starts,"Incoming attachment was exposed before the body handoff")
assert(actors["20522"].scene_position==held_position and actors["20524"].scene_position==held_position)
anatomy_ready=true;step(6,36);expect(36,"playing")
assert(not anatomy_current.hidden and anatomy_current.position==0 and actors["20522"].scene_position==0)
assert(counts.starts==held_starts+2 and counts.holds>0)

-- A retained component must keep the outgoing animation and exact shared pose
-- until all target readiness checks pass, then switch once alongside both bodies.
game_scale=1;step(3,36)
local outgoing_animation=anatomy_current.animation
local outgoing_position=anatomy_current.position
anatomy_ready=false
navigation(36,2,"idle",2);step(6,36);expect(36,"preparing")
assert(anatomy_current.animation==outgoing_animation and anatomy_current.position==outgoing_position)
assert(not anatomy_current.hidden and actors["20522"].scene_position==outgoing_position)
request(36,"exit");step(12,36);expect(36,"idle");restored();anatomy_ready=true

-- Timeout recovery must also retire a held outgoing montage and allow re-entry.
request(37,"start","hzoi.standing_idle");step(12,37)
appearance_ready=false;navigation(37,1,"standing_rear",1)
step(45,37);expect(37,"error","appearance_timeout");restored();appearance_ready=true
request(38,"start");step(12,38);expect(38,"playing")
request(38,"exit");step(12,38);expect(38,"idle");restored()
print("Navigation hold regression passed: delayed appearance/attachments retain paired outgoing poses, synchronized handoff, pause/speed changes, retained attachment, early Exit, timeout and re-entry.")

local function piece(id,kind,key)
    for _,item in ipairs(bindings[id].lease.wardrobe.items) do if item.kind==kind and item.key==key then return item.id end end
    error("Starting piece not found")
end
local function manual(sequence,count,id,item,enabled,revision)
    cfg.outfit=Protocol.pack("test",sequence,"outfit",count,id,item,enabled and 1 or 0,revision)
end
-- Manual accessories never alter the starting inventory or participant identity.
request(39,"start","hzoi.standing_idle");step(12,39);expect(39,"playing")
local bag=piece("20524","accessory","Bag")
local female_style=actors["20524"].AppearanceComponent.AppearanceSetting.FinalStyle.Outfit
local before_manual=counts.starts
manual(39,1,"20524",bag,false,1);step(12,39);expect(39,"playing")
assert(female_style.Accessories:Find("Bag").AccessoryId=="None" and counts.starts==before_manual,
    "Manual outfit update must retain the current node/player")
local ack=Protocol.unpack(cfg.outfit_state);assert(ack[4]=="1" and ack[5]=="ok")
local version=bindings["20524"].lease.wardrobe.version
step(10,39);assert(bindings["20524"].lease.wardrobe.version==version,"Retried manual request applied twice")
navigation(39,1,"standing_hand_job",1);step(12,39);expect(39,"playing")
assert(female_style.Accessories:Find("Bag").AccessoryId=="None","Navigation restored a manually removed bag")
local attachment=anatomy_current
game_scale=0
local held=actors["20522"].scene_position
manual(39,2,"20522",piece("20522","garment","Bottom"),true,2);step(12,39);expect(39,"playing")
assert(actors["20522"].AppearanceComponent.AppearanceSetting.FinalStyle.Outfit.Garments.Bottom.GarmentId=="original_pants")
assert(attachment==anatomy_current and attachment.hidden,"Lower-body clothing must hide, not destroy, the retained attachment")
assert(actors["20522"].scene_position==held and actors["20524"].scene_position==held,"Outfit update reset the paused node clock")
manual(39,3,"20522",piece("20522","garment","Bottom"),false,2);step(12,39);expect(39,"playing")
assert(not attachment.hidden and attachment==anatomy_current)
manual(39,4,"20524",bag,true,2);step(12,39);expect(39,"playing")
assert(female_style.Accessories:Find("Bag").AccessoryTransformData==nil or female_style.Accessories:Find("Bag").SocketNames[1]=="hand_r")
assert(female_style.Accessories:Find("Bag").AccessoryId=="original_bag")
local printed=piece("20524","printed","1/hand_l")
manual(39,5,"20524",printed,false,2);step(12,39);expect(39,"playing")
assert(not female_style.PrintedAccessories[1].PrintedAccessoryData:Find("hand_l") and female_style.PrintedAccessories[1].PrintedAccessoryData:Find("head"))
manual(39,6,"20524",printed,true,2);step(12,39);expect(39,"playing")
assert(female_style.PrintedAccessories[1].PrintedAccessoryData:Find("hand_l").SaveData.scale==1.2)
manual(39,7,"99999",bag,false,2);step(3,39);expect(39,"playing")
ack=Protocol.unpack(cfg.outfit_state);assert(ack[4]=="7" and ack[5]=="outfit_invalid")
manual(39,8,"20524",bag,false,1);step(3,39)
ack=Protocol.unpack(cfg.outfit_state);assert(ack[4]=="8" and ack[5]=="outfit_stale")
appearance_ready=false
manual(39,9,"20524",bag,false,2);step(3,39);expect(39,"preparing")
request(39,"exit");step(12,39);expect(39,"idle");restored();appearance_ready=true;game_scale=1
assert(female_style.Accessories:Find("Bag").AccessoryId=="original_bag" and female_style.PrintedAccessories[1].PrintedAccessoryData:Find("hand_l"))
request(40,"start");step(12,40);expect(40,"playing")
appearance_ready=false
manual(40,1,"20524",piece("20524","accessory","Bag"),false,1);step(45,40)
expect(40,"error","outfit_timeout");restored();appearance_ready=true
request(41,"start");step(12,41);expect(41,"playing");request(41,"exit");step(12,41);restored()
print("Manual outfit integration passed: both participants, regular/printed accessories, node and clock retention, conditional attachment visibility, retries, invalid/stale commands, early Exit, timeout and re-entry.")

request(42,"start","hzoi.standing_hand_job");step(12,42);expect(42,"playing")
local retained_manual=anatomy_current
drop_outfit_reply=true
manual(42,1,"20522",piece("20522","garment","Bottom"),true,1);step(12,42);expect(42,"playing")
assert(bindings["20522"].lease.wardrobe.version==1 and retained_manual.hidden)
navigation(42,1,"idle",1);step(12,42);expect(42,"playing")
navigation(42,2,"neutral",2);step(12,42);expect(42,"playing")
assert(anatomy_current==retained_manual and retained_manual.hidden and actors["20522"].AppearanceComponent.AppearanceSetting.FinalStyle.Outfit.Garments.Bottom.GarmentId=="original_pants")
manual(42,2,"20522",piece("20522","garment","Bottom"),false,3);step(12,42);expect(42,"playing")
assert(anatomy_current==retained_manual and not retained_manual.hidden)
manual(42,3,"20522",piece("20522","garment","Top"),true,3);step(12,42);expect(42,"playing")
assert(not retained_manual.hidden,"An upper-body garment must not hide a lower-body attachment")
request(42,"exit");step(12,42);expect(42,"idle");restored()
print("Clothed retained navigation passed: lost outfit acknowledgement retries once, hubs retain a hidden component, undressing reveals it again and upper-body clothing leaves it visible.")

-- Reproduce the author's normalizer result, including rapid absolute requests.
owners["20524"].normalize_on_top=true
local normalized=actors["20524"].AppearanceComponent.AppearanceSetting.FinalStyle.Outfit.Garments
normalized.InnerTop=nil;drop_inventory=true
request(43,"start");step(12,43);expect(43,"playing")
local top=piece("20524","garment","Top")
local original_starts=counts.starts
for count=1,20 do
    manual(43,count,"20524",top,count%2==0,1)
    step(6,43);expect(43,"playing")
    assert(normalized.Top.GarmentId==(count%2==0 and "original_shirt" or "None"))
    if count%2==1 then assert(normalized.InnerTop.GarmentId=="W_InnTop03_001") else assert(not normalized.InnerTop) end
end
-- Bursts before the next poll coalesce to the latest absolute request.
manual(43,21,"20524",top,false,1);manual(43,22,"20524",top,true,1);manual(43,23,"20524",top,false,1)
step(6,43);expect(43,"playing");assert(Protocol.unpack(cfg.outfit_state)[4]=="23")
-- New requests while appearance settles must wait, then apply the latest intent.
appearance_ready=false;manual(43,24,"20524",top,true,1);step(1,43);expect(43,"preparing")
manual(43,25,"20524",top,false,1);manual(43,26,"20524",top,true,1);step(3,43)
appearance_ready=true;step(12,43);expect(43,"playing")
assert(Protocol.unpack(cfg.outfit_state)[4]=="26" and normalized.Top.GarmentId=="original_shirt")
assert(counts.starts==original_starts,"Rapid outfit edits restarted the scene players")
drop_inventory=true;navigation(43,1,"hzoi.enter",1);step(12,43);expect(43,"playing")
request(43,"exit");step(12,43);expect(43,"idle");restored()
owners["20524"].normalize_on_top=false;normalized.InnerTop={GarmentId="original_bra"}
print("Rapid outfit regression passed: 20 off/on changes, coalesced bursts, requests during a delayed rebuild, game-added underwear, lost resolved metadata, preserved scene players and exact restoration.")

-- Retained anatomy and body skin matching must wait for each body rebuild.
request(44,"start","hzoi.standing_hand_job");step(12,44);expect(44,"playing")
navigation(44,1,"idle",1);step(12,44);expect(44,"playing")
local retained_rebuild=anatomy_current
local ready_before=body_readiness_calls
pending_body_ticks=8
manual(44,1,"20522",piece("20522","garment","Bottom"),true,2)
step(6,44);expect(44,"preparing")
assert(pending_body_ticks>0 and body_readiness_calls==ready_before,
    "A false prepare result must block all dependent readiness checks")
assert(anatomy_current==retained_rebuild)
step(12,44);expect(44,"playing")
assert(anatomy_current==retained_rebuild and retained_rebuild.hidden)
pending_body_ticks=6
manual(44,2,"20522",piece("20522","garment","Bottom"),false,2)
step(12,44);expect(44,"playing")
assert(anatomy_current==retained_rebuild and not retained_rebuild.hidden)
pending_body_ticks=20
manual(44,3,"20522",piece("20522","garment","Bottom"),true,2);step(5,44);expect(44,"preparing")
request(44,"exit");step(12,44);expect(44,"idle");restored();pending_body_ticks=0
print("Retained body rebuild regression passed: male lower-body switches at the idle hub wait before skin/attachment readiness, retain the component and permit early Exit.")

-- First activation must work at either clothed hub without visiting an adult node.
for sequence,node in pairs({[45]="scenezoi.standing_idle",[46]="hzoi.standing_idle"}) do
    local created_before=anatomy_created
    request(sequence,"start",node);step(12,sequence);expect(sequence,"playing")
    assert(anatomy_created==created_before and #runtime.snapshot().tracks==2)
    local starts=counts.starts
    manual(sequence,1,"20522",piece("20522","garment","Top"),false,1);step(12,sequence)
    assert(anatomy_created==created_before,"Unrelated upper-body changes activated anatomy")
    manual(sequence,2,"20522",piece("20522","garment","Bottom"),false,1);step(12,sequence)
    assert(anatomy_created==created_before,"Remaining underwear must still cover the region")
    game_scale=0
    local held=actors["20522"].scene_position
    manual(sequence,3,"20522",piece("20522","garment","InnerUnder"),false,1);step(12,sequence);expect(sequence,"playing")
    assert(anatomy_created==created_before+1 and not anatomy_current.hidden and #runtime.snapshot().tracks==3)
    assert(anatomy_current.animation:find("HZOI_Standing_idle_MA",1,true))
    assert(anatomy_current.position==held and counts.starts==starts,"First manual activation restarted playback or lost the held clock")
    local first_manual=anatomy_current
    manual(sequence,4,"20522",piece("20522","garment","InnerUnder"),true,1);step(12,sequence)
    assert(first_manual==anatomy_current and first_manual.hidden)
    manual(sequence,5,"20522",piece("20522","garment","InnerUnder"),false,1);step(12,sequence)
    assert(first_manual==anatomy_current and not first_manual.hidden)
    game_scale=1
    navigation(sequence,1,node=="scenezoi.standing_idle" and "hzoi.enter" or "neutral",1)
    step(12,sequence);expect(sequence,"playing")
    assert(first_manual==anatomy_current and not first_manual.hidden)
    request(sequence,"exit");step(12,sequence);expect(sequence,"idle");restored()
end
-- An unused conditional resource must remain optional when only a shirt is removed.
request(47,"start");step(12,47);anatomy_available=false
manual(47,1,"20522",piece("20522","garment","Top"),false,1);step(12,47);expect(47,"playing")
manual(47,2,"20522",piece("20522","garment","Bottom"),false,1);step(12,47);expect(47,"playing")
manual(47,3,"20522",piece("20522","garment","InnerUnder"),false,1);step(12,47);expect(47,"error","runtime_error")
restored();anatomy_available=true
-- Exit also wins during the first manual activation and its hidden warm-up.
request(48,"start");step(12,48)
manual(48,1,"20522",piece("20522","garment","Bottom"),false,1);step(12,48)
anatomy_ready=false
manual(48,2,"20522",piece("20522","garment","InnerUnder"),false,1);step(6,48);expect(48,"preparing")
assert(anatomy_current.hidden)
request(48,"exit");step(12,48);expect(48,"idle");restored();anatomy_ready=true
print("First manual activation passed: both hubs, actual coverage layers, optional unloaded assets, held clock/body players, track publication, retention and early Exit.")

request(49,"start","hzoi.standing_hand_job");step(12,49);expect(49,"playing")
local guard_before=counts.guards
appearance_ready=false
manual(49,1,"20522",piece("20522","garment","Bottom"),true,1);step(6,49);expect(49,"preparing")
local male_setting=actors["20522"].AppearanceComponent.AppearanceSetting
assert(counts.guards>guard_before,"Visual coverage guard waited for the appearance barrier")
assert(bindings["20522"].lease.body_merge and not male_setting.Body.bUseMeshMerge and not male_setting.FinalBody.bUseMeshMerge)
appearance_ready=true;step(12,49);expect(49,"playing")
manual(49,2,"20522",piece("20522","garment","Top"),true,1);step(12,49);expect(49,"playing")
assert(not male_setting.Body.bUseMeshMerge and anatomy_current.hidden)
request(49,"exit");step(12,49);expect(49,"idle");restored()
assert(male_setting.Body.bUseMeshMerge and not male_setting.FinalBody.bUseMeshMerge)
print("Outfit visual handoff passed: pre-refresh unmerged source, guard during delayed appearance, pants retained across upper-body edits and exact merge restoration.")

request(50,"start","hzoi.standing_hand_job");step(12,50);expect(50,"playing")
local exposed=anatomy_current
local hide_calls=exposed.hide_calls
local starts=counts.starts
game_scale=0
local held=exposed.position
appearance_ready=false
manual(50,1,"20522",piece("20522","garment","Top"),true,1);step(6,50);expect(50,"preparing")
assert(not exposed.hidden and exposed.hide_calls==hide_calls and exposed.position==held,
    "A non-covering outfit update hid or moved the exposed attachment during preparation")
appearance_ready=true;anatomy_ready=false;step(6,50);expect(50,"preparing")
assert(not exposed.hidden and exposed.hide_calls==hide_calls,"Material readiness must not blank a retained exposed component")
anatomy_ready=true;step(12,50);expect(50,"playing")
for count=2,20 do
    manual(50,count,"20522",piece("20522","garment","Top"),count%2==1,1);step(12,50);expect(50,"playing")
    assert(not exposed.hidden and exposed.hide_calls==hide_calls and exposed.position==held and anatomy_current==exposed)
end
assert(exposed.kept_visible_edits==20 and counts.starts==starts)
manual(50,21,"20522",piece("20522","accessory","Bag"),false,1);step(12,50)
assert(not exposed.hidden and exposed.hide_calls==hide_calls)
manual(50,22,"20522",piece("20522","garment","Bottom"),true,1);step(1,50)
assert(exposed.hidden,"Covering clothing must still hide before its appearance rebuild")
step(12,50);expect(50,"playing");assert(exposed.hidden)
manual(50,23,"20522",piece("20522","garment","Bottom"),false,1);step(12,50)
assert(not exposed.hidden and anatomy_current==exposed)
request(50,"exit");step(12,50);expect(50,"idle");restored();game_scale=1
print("Exposed attachment continuity passed: 20 upper edits, accessory removal, delayed appearance/materials, held paused pose, no hide calls/restarts, and preserved covering-clothing handoff.")

-- Synthetic rosters exist only in this isolated test, never in the shipped catalog.
local function clone(value)
    if type(value)~="table" then return value end
    local result={};for key,v in pairs(value) do result[key]=clone(v) end;return result
end
local catalog=require("SceneZOI.GeneratedCatalog").nodes
for _,combo in ipairs({"mm","ff","mff","mmf"}) do
    local roles=combo=="mm" and {male="male",male2="male"} or combo=="ff" and {female="female",female2="female"} or
        combo=="mff" and {male="male",female="female",female2="female"} or {male="male",male2="male",female="female"}
    local prefix="hzoi.regression_"..combo
    for _,kind in ipairs({"idle","rear"}) do
        local source=catalog[kind=="idle" and "hzoi.standing_idle" or "hzoi.standing_rear"]
        local node=clone(source);node.id=prefix.."_"..kind;node.hub=nil
        node.participants={};node.tracks={};node.attachments={};node.outfits={};node.gaze={}
        node.anchor_participant=roles.male and "male" or "female"
        node.navigation={{id=kind=="idle" and "rear" or "idle",target=prefix..(kind=="idle" and "_rear" or "_idle")}}
        for role,body in pairs(roles) do
            node.participants[role]={body=body};node.tracks[role]=source.tracks[body]
            if source.outfits and source.outfits[body] then node.outfits[role]=clone(source.outfits[body]) end
            if body=="male" then
                local spec=clone(source.attachments.male_anatomy);spec.participant=role
                spec.retained_tracks={[prefix.."_idle"]=catalog["hzoi.standing_idle"].attachments.male_anatomy.animation}
                node.attachments[role.."_anatomy"]=spec
            end
        end
        catalog[node.id]=node
    end
end
-- Fixed membership with repeated body types: two independent male resources.
for _,combo in ipairs({"mff","mmf"}) do
    for _,controlled in ipairs({"20522","20524"}) do
        controlled_id=controlled
        local seq=combo=="mff" and (controlled=="20522" and 51 or 52) or (controlled=="20522" and 53 or 54)
        local extra=combo=="mff" and "female2:20532" or "male2:20530"
        local roster="male:20522+female:20524+"..extra
        local hub="hzoi.regression_"..combo.."_idle"
        request(seq,"start",hub,roster);step(12,seq);expect(seq,"playing")
        assert(#runtime.snapshot().participants==3 and #runtime.snapshot().tracks==3)
        navigation(seq,1,"rear",1);step(12,seq);expect(seq,"playing")
        local snap=runtime.snapshot();assert(#snap.participants==3 and #snap.tracks==(combo=="mmf" and 5 or 4))
        local first=anatomy_by_actor[actors["20522"]]
        local second=combo=="mmf" and anatomy_by_actor[actors["20530"]]
        assert(first and not first.hidden)
        if second then assert(second~=first and not second.hidden) end
        local bodies={};for _,p in ipairs(snap.participants)do bodies[p.role]=p.id end
        game_scale=0;local held=first.position;step(10,seq);assert(first.position==held)
        cfg.playback=Protocol.pack("test",seq,"speed",1,4);step(3,seq)
        manual(seq,1,"20522",piece("20522","garment","Bottom"),true,2);step(12,seq);expect(seq,"playing")
        assert(first.hidden and (not second or not second.hidden),"One owner's covering outfit affected another attachment")
        assert(first.position==held and (not second or second.position==held))
        game_scale=1
        navigation(seq,2,"idle",2);step(12,seq);expect(seq,"playing")
        for _,p in ipairs(runtime.snapshot().participants) do assert(bodies[p.role]==p.id,"Navigation reassigned the fixed roster") end
        assert(anatomy_by_actor[actors["20522"]]==first)
        if second then assert(anatomy_by_actor[actors["20530"]]==second and not second.hidden) end
        request(seq,"exit");step(12,seq);expect(seq,"idle");restored()
    end
end
controlled_id="20522"
fail_attachment_actor=actors["20530"]
request(55,"start","hzoi.regression_mmf_rear","male:20522+female:20524+male2:20530")
step(12,55);expect(55,"error","runtime_error");fail_attachment_actor=nil;restored()
request(56,"start","hzoi.regression_mff_idle","male:20522+female:20524+female2:20532");step(12,56);expect(56,"playing")
runtime.unregister(actors["20532"]);step(12,56);expect(56,"error","participant_unloaded");restored();runtime.register(actors["20532"])
print("Group lifecycle passed: MFF/MMF, controlled male/female, fixed identities, synchronized plural attachments, isolated outfit changes, retained resources, second-owner failure and whole-session exit on unload.")

for _,combo in ipairs({"mm","ff"}) do
    controlled_id=combo=="mm" and "20522" or "20524"
    local seq=combo=="mm" and 57 or 58
    local roster=combo=="mm" and "male:20522+male2:20530" or "female:20524+female2:20532"
    local hub="hzoi.regression_"..combo.."_idle"
    request(seq,"start",hub,roster);step(12,seq);expect(seq,"playing")
    navigation(seq,1,"rear",1);step(12,seq);expect(seq,"playing")
    assert(#runtime.snapshot().participants==2 and #runtime.snapshot().tracks==(combo=="mm" and 4 or 2))
    if combo=="mm" then
        assert(anatomy_by_actor[actors["20522"]]~=anatomy_by_actor[actors["20530"]])
        manual(seq,1,"20522",piece("20522","garment","Bottom"),true,2);step(12,seq)
        assert(anatomy_by_actor[actors["20522"]].hidden and not anatomy_by_actor[actors["20530"]].hidden)
    end
    request(seq,"exit");step(12,seq);expect(seq,"idle");restored()
end
print("Same-body pairs passed: MM with independent anatomy/coverage, FF without attachments, and original outfits restored.")

local audio_native=require("SceneZOI.SoundNative")
local audio_original={};for k,v in pairs(audio_native)do audio_original[k]=v end
local completion_plays=0
audio_native.load=function(path)return {path=path,duration=.5}end
audio_native.position=function(bindings,source)
 if bindings.completed then assert(source[1].component=="body"and source[1].bones[1]=="pelvis")end
 return {X=1,Y=2,Z=3}
end
audio_native.create=function(v,actor) v.component={};v.owner=actor end
audio_native.play=function(v,clip,point,rate)
 v.stopped=false;v.requested=rate;v.rate=rate
 if clip.path=="/Neutral/Completion.Completion"then completion_plays=completion_plays+1;assert(tostring(v.owner:GetEntityId())=="20522")end
end
audio_native.move=function()end;audio_native.pause=function(v,p)v.paused=p end
audio_native.tune=function(v,r,p)v.rate=r;v.requested=r;v.paused=p end
audio_native.stop=function(v)v.remaining=nil;v.stopped=true end
audio_native.destroy=function(v)audio_native.stop(v);v.component=nil end

-- Generic task engine through the real runtime/navigation/clock and UI bridge.
fixture.tasks={definitions={test_charge={schema_version=1,id="test_charge",label="Charge",maximum=3,initial=0,decay=1,completion_event="test_ready",on_completion={{type="play_sound",when={body="male"},clip="/Neutral/Completion.Completion",source={component="body",bones={"pelvis"}}}}}}}
fixture.nodes["hzoi.standing_rear"].tasks={male={test_charge={rate=1}},female={test_charge={rate=.5,cap_percent=50}}}
local task_events={}
local Events=require("SceneZOI.Events")
local task_handle=Events.subscribe_task("test_ready",function(e)task_events[#task_events+1]=e end)
controlled_id="20522";game_scale=1
request(59,"start","hzoi.standing_rear");step(12,59);expect(59,"playing")
local before=runtime.snapshot().task_progress["20522"].test_charge.value
assert(before>0)
game_scale=0;step(10,59);assert(runtime.snapshot().task_progress["20522"].test_charge.value==before,"Game pause must pause tasks")
game_scale=1;cfg.playback=Protocol.pack("test",59,"speed",1,4);step(3,59)
local after=runtime.snapshot().task_progress["20522"].test_charge.value
assert(math.abs(after-before-.6)<.00001,"Scene speed must not multiply per-game-second task rates")
step(40,59);assert(#task_events>=2,"Runtime must emit repeated task completions");assert(completion_plays==#task_events,"One sound per male completion through the real runtime callback")
local e=task_events[1];assert(e.name=="task_completed"and e.node_id=="hzoi.standing_rear"and e.participant_id=="20522"and e.task.id=="test_charge"and e.task.completion_event=="test_ready"and e.task.completed)
assert(runtime.snapshot().task_progress["20524"].test_charge.value==1.5)
local frame=Protocol.unpack(cfg.task_state);local display=require("SceneZOI.Json").decode(Protocol.decode(frame[5]));assert(#display.rows==2 and display.rows[2].participant_name)
navigation(59,1,"idle",1);step(12,59);expect(59,"playing")
step(30,59);assert(runtime.snapshot().task_progress["20524"].test_charge.value==0,"Idle decays session progress")
frame=Protocol.unpack(cfg.task_state);display=require("SceneZOI.Json").decode(Protocol.decode(frame[5]));assert(#display.rows==0)
request(59,"exit");step(12,59);expect(59,"idle");restored();Events.unsubscribe(task_handle)
request(60,"start","hzoi.standing_idle");step(12,60);expect(60,"playing");assert(runtime.snapshot().task_progress["20522"].test_charge.value==0,"New sessions must not inherit old progress")
request(60,"exit");step(12,60);expect(60,"idle");restored()
print("Task runtime integration passed: game-time rates, speed independence, pause, repeated filtered completion events, payloads/UI frames, idle decay and fresh-session reset.")

for k,v in pairs(audio_original)do audio_native[k]=v end

-- Synthetic one-shot nodes exercise the real Runtime with the existing native adapter harness.
local transition=clone(fixture.nodes["hzoi.standing_hand_job"])
transition.id="hzoi.regression_transition";transition.kind="transition";transition.destination="hzoi.standing_rear";transition.navigation={}
transition.tasks={male={charge={rate=100}},female={charge={rate=-100}}}
fixture.nodes[transition.id]=transition
fixture.tasks={definitions={charge={id="charge",label="Charge",maximum=90,initial=10,decay=2},omitted={id="omitted",label="Omitted",maximum=90,initial=10,decay=2}}}
fixture.nodes["hzoi.standing_rear"].tasks={male={charge={rate=1}},female={charge={rate=1}}}
local transitions=0
local th=Events.subscribe("transition_completed",function(e)
 assert(e.node_kind=="transition"and e.node_id==transition.id and e.destination=="hzoi.standing_rear")
 transitions=transitions+1
end)
local function frozen_tasks()
 for _,values in pairs(runtime.snapshot().task_progress)do
  assert(values.charge.value==10 and values.omitted.value==10 and values.charge.completions==0,"Every task must freeze during transitions")
 end
end
controlled_id="20522";game_scale=1
request(61,"start",transition.id);step(12,61);expect(61,"playing");frozen_tasks()
local previous_position=actors["20522"].scene_position
navigation(61,1,"anything",1);step(1,61);assert(cfg.navigation_state:find("navigation_locked",1,true)and runtime.snapshot().node_id==transition.id)
previous_position=actors["20522"].scene_position
game_scale=0;step(10,61);assert(actors["20522"].scene_position==previous_position);frozen_tasks()
cfg.playback=Protocol.pack("test",61,"speed",1,4);step(2,61);assert(runtime.snapshot().speed_index==4 and actors["20522"].scene_position==previous_position)
game_scale=2;step(1,61);assert(math.abs(actors["20522"].scene_position-previous_position-.8)<.000001,"Live native and scene speed changes must multiply remaining time")
local samples=0
while runtime.snapshot().node_id==transition.id do
 previous_position=actors["20522"].scene_position;step(1,61);samples=samples+1
 assert(actors["20522"].scene_position>=previous_position and actors["20522"].scene_position<10,"Transition must never wrap to zero or seek native end")
 frozen_tasks();assert(samples<30)
end
assert(transitions==1 and runtime.snapshot().node_id=="hzoi.standing_rear"and runtime.snapshot().phase=="preparing")
local final_position=actors["20522"].scene_position;assert(final_position>9.99 and actors["20524"].scene_position==final_position)
appearance_ready=false;local before_starts=counts.starts;step(3,61)
assert(counts.starts==before_starts and actors["20522"].scene_position==final_position and actors["20524"].scene_position==final_position,"Hold the final pose while the destination prepares")
frozen_tasks();appearance_ready=true;step(12,61);expect(61,"playing")
assert(runtime.snapshot().speed_index==4 and runtime.snapshot().revision==2 and transitions==1)
assert(runtime.snapshot().task_progress["20522"].charge.value>10 and runtime.snapshot().task_progress["20524"].charge.value>10,"Tasks resume only after arrival")
step(8,61);assert(transitions==1,"A completed transition cannot repeatedly auto-navigate")
request(61,"exit");step(12,61);expect(61,"idle");restored()
game_scale=1;request(62,"start",transition.id);step(12,62);expect(62,"playing")
request(62,"exit");step(20,62);expect(62,"idle");restored();assert(transitions==1,"Early Exit cancels automatic destination")
local previous_loader=UE.UObject.Load
UE.UObject.Load=function(path)if path==fixture.nodes["hzoi.standing_rear"].tracks.male then return nil end;return previous_loader(path)end
game_scale=4;request(63,"start",transition.id);step(60,63);expect(63,"error","transition_destination_error");restored();UE.UObject.Load=previous_loader;game_scale=1
assert(transitions==2,"Destination load failure still records only one finished transition")
Events.unsubscribe(th)
print("Transition runtime passed: manual navigation lock, both speed controls changed mid-clip, pause, clamped non-looping body/attachment samples, frozen task gains/decay, held final pose, one automatic handoff, retained speed/roster, early Exit and destination failure cleanup.")

-- Completion routing uses actual participant IDs/roles and the existing node handoff.
local routed=clone(fixture.nodes["hzoi.standing_rear"]);routed.id="hzoi.regression_task_route"
local routed_transition=clone(transition);routed_transition.id="hzoi.regression_task_finish";routed_transition.destination="hzoi.standing_idle"
routed.task_completion_routes={male={charge=routed_transition.id}}
routed.tasks={male={charge={rate=1}},female={charge={rate=1}}}
routed_transition.tasks={male={charge={rate=100}},female={charge={rate=-100}}}
fixture.nodes[routed.id]=routed;fixture.nodes[routed_transition.id]=routed_transition
fixture.tasks={definitions={charge={id="charge",label="Charge",maximum=2,initial=0,decay=1}}}
local route_events,completed={},{}
local route_handle=Events.subscribe("task_route_selected",function(e)route_events[#route_events+1]=e end)
local completion_handle=Events.subscribe("task_completed",function(e)completed[#completed+1]=e end)
controlled_id="20524";game_scale=1
request(64,"start",routed.id);step(30,64)
assert(runtime.snapshot().node_id==routed_transition.id and #route_events==1 and #completed==2,"Every simultaneous completion must commit before the one male route")
assert(route_events[1].task_route.participant_id=="20522"and route_events[1].task_route.participant_role=="male"and route_events[1].task_route.task_id=="charge")
assert(route_events[1].node_id==routed.id and route_events[1].task_route.target==routed_transition.id)
for _,values in pairs(runtime.snapshot().task_progress)do assert(values.charge.value==0 and values.charge.completions==1)end
cfg.playback=Protocol.pack("test",64,"speed",1,4);game_scale=2
step(35,64);expect(64,"playing");assert(runtime.snapshot().node_id=="hzoi.standing_idle"and #route_events==1 and #completed==2)
assert(runtime.snapshot().speed_index==4,"Completion route and transition arrival preserve speed")
request(64,"exit");step(12,64);expect(64,"idle");restored();game_scale=1
-- Female completion cannot use the male role's route; exact task keys also matter.
routed.tasks={male={charge={rate=0}},female={charge={rate=1}}}
request(65,"start",routed.id);step(35,65);expect(65,"playing");assert(runtime.snapshot().node_id==routed.id and #route_events==1)
request(65,"exit");step(12,65);expect(65,"idle");restored()
-- Failed optional routing leaves completed/reset task state and the current loop intact.
routed.tasks={male={charge={rate=1}},female={charge={rate=0}}}
local loader_before=UE.UObject.Load
UE.UObject.Load=function(path)if path==routed_transition.tracks.male then return nil end;return loader_before(path)end
request(66,"start",routed.id);step(25,66);expect(66,"playing");assert(runtime.snapshot().node_id==routed.id and #route_events==1)
assert(cfg.navigation_state:find("task_route_error",1,true));assert(runtime.snapshot().task_progress["20522"].charge.completions>=1)
request(66,"exit");step(12,66);expect(66,"idle");restored();UE.UObject.Load=loader_before
-- The same completion routing can target an ordinary loop, with no transition required.
routed.task_completion_routes.male.charge="hzoi.standing_idle"
request(67,"start",routed.id);step(30,67);expect(67,"playing")
assert(runtime.snapshot().node_id=="hzoi.standing_idle"and #route_events==2 and route_events[2].task_route.target=="hzoi.standing_idle")
request(67,"exit");step(12,67);expect(67,"idle");restored()
Events.unsubscribe(route_handle);Events.unsubscribe(completion_handle)
print("Task route runtime passed: male completion routes the whole roster, simultaneous female completion preserved, no female-role substitution, transition tasks frozen, automatic idle arrival, speed retained and optional destination failure leaves loop usable.")


-- Completion responses through the real runtime; native bone application is covered separately.
local BoneEffects=require('SceneZOI.BoneOscillation');local original_apply,original_restore=BoneEffects.apply,BoneEffects.restore
local shakes_applied,shakes_released={},{}
BoneEffects.apply=function(o)shakes_applied[o.participant.id]=true end
BoneEffects.restore=function(o)shakes_released[o.participant.id]=true end
local response_node=clone(fixture.nodes['hzoi.standing_rear']);response_node.id='hzoi.regression_response'
response_node.tasks={male={charge={rate=1}},female={charge={rate=1}}}
response_node.movement_timing={cycles_per_second=1,peak_phase=.5}
response_node.completion_responses={}
for _,role in ipairs({'male','female'})do
 response_node.completion_responses[role]={charge={enabled=true,slowdown={repeats=2},shake={duration=6,bones={{bone='joint',child='tip'}}}}}
end
fixture.nodes[response_node.id]=response_node
fixture.tasks={definitions={charge={id='charge',label='Charge',maximum=4,initial=0,decay=1}}}
game_scale=1;request(68,'start',response_node.id);step(12,68);expect(68,'playing')
-- Run exactly until the first simultaneous completion.
local n=0
while runtime.snapshot().task_progress['20522'].charge.completions==0 do step(1,68);n=n+1;assert(n<30)end
local snap=runtime.snapshot();assert(snap.completion_effects.starts==2 and #snap.completion_effects.shaking_participants==2)
assert(snap.completion_effects.stage~='none' and snap.completion_effects.source=='20524|charge','Deterministic role arbitration; both completions retained')
local pos=actors['20522'].scene_position;game_scale=0;step(10,68)
assert(actors['20522'].scene_position==pos and actors['20524'].scene_position==pos,'Pause freezes paired slowed bodies')
cfg.playback=Protocol.pack('test',68,'speed',1,4);step(2,68)
assert(runtime.snapshot().speed_index==4 and actors['20522'].scene_position==pos)
game_scale=1;step(5,68);snap=runtime.snapshot()
assert(snap.effective_speed<2 and shakes_applied['20522']and shakes_applied['20524'],'Slowdown and per-participant overlays run through native scene sampling')
assert(actors['20522'].scene_position==actors['20524'].scene_position,'Bodies remain synchronized')
local attachment=anatomy_by_actor[actors['20522']];assert(math.abs(attachment.position-actors['20522'].scene_position)<1e-6,'Attachment follows the same slowed clock')
assert(snap.task_progress['20522'].charge.value>0,'Tasks continue on game time independent of slowdown')
navigation(68,1,'idle',1);step(12,68);expect(68,'playing');snap=runtime.snapshot()
assert(snap.completion_effects.stage=='none'and #snap.completion_effects.shaking_participants==0 and snap.speed_index==4)
assert(shakes_released['20522']and shakes_released['20524'],'Navigation releases both overlays')
request(68,'exit');step(12,68);expect(68,'idle');restored()
-- Any selected authored route takes priority over every procedural response in that completion batch.
response_node.task_completion_routes={male={charge='hzoi.standing_idle'}}
request(69,'start',response_node.id);step(40,69);expect(69,'playing');snap=runtime.snapshot()
assert(snap.node_id=='hzoi.standing_idle'and snap.completion_effects.starts==0,'Authored route bypasses procedural responses')
request(69,'exit');step(12,69);expect(69,'idle');restored()
BoneEffects.apply,BoneEffects.restore=original_apply,original_restore
print('Completion response runtime passed: actual task completions, paired body/attachment slowdown, game pause and user speed changes, independent overlays, continuing task clock, navigation/Exit cleanup and authored-route priority.')


-- Generic task-to-speaker response wiring through real Runtime (spatial native calls mocked).
local NativeVoice=require('SceneZOI.SoundNative');local saved_native={};for k,v in pairs(NativeVoice)do saved_native[k]=v end
local VoiceEngine=require('SceneZOI.Voices');local saved_selected=VoiceEngine.selected
local assigned=true;local spoken={}
local response_set={id='test.voice',archetype='test',body='female',context='test_context',volume=.8,responses={answer={clips={'/Test/Answer.Answer'}},complete={clips={'/Test/Complete.Complete'}}}}
VoiceEngine.selected=function(ctx,p,context)
 if context=='test_context'then if assigned and p.id=='20524'then return response_set end;return nil end
 return saved_selected(ctx,p,context)
end
NativeVoice.load=function(path)return {path=path,duration=1}end
NativeVoice.position=function()return {X=1,Y=2,Z=3}end
NativeVoice.create=function(v,actor)v.component={};v.actor=actor end
NativeVoice.move=function()end
NativeVoice.volume=function()end
NativeVoice.rate=function(scale)return math.max(1,math.min(2,scale))end
NativeVoice.tune=function(v,scale,pause)v.rate=NativeVoice.rate(scale);v.requested=scale;v.paused=pause end
NativeVoice.pause=function(v,pause)v.paused=pause end
NativeVoice.play=function(v,clip,_,scale)NativeVoice.tune(v,scale,false);v.stopped=false;spoken[#spoken+1]={speaker=Protocol.id(v.actor:GetEntityId()),clip=clip.path}end
NativeVoice.stop=function(v)v.remaining=nil;v.stopped=true end
NativeVoice.destroy=function(v)NativeVoice.stop(v);v.component=nil end
local voice_node=clone(fixture.nodes['hzoi.standing_rear']);voice_node.id='hzoi.regression_voice_response'
voice_node.tasks={male={charge={rate=1}},female={charge={rate=1}}};voice_node.task_completion_routes=nil
voice_node.task_completion_voices={male={charge={{participant='female',context='test_context',response='answer',priority=20}}},female={charge={{participant='female',context='test_context',response='complete',priority=10}}}}
fixture.nodes[voice_node.id]=voice_node
fixture.tasks={definitions={charge={id='charge',label='Charge',maximum=90,initial=89.8,decay=0}}}
game_scale=1;request(70,'start',voice_node.id);step(20,70);expect(70,'playing')
assert(#spoken==1 and spoken[1].speaker=='20524'and spoken[1].clip=='/Test/Answer.Answer','Male completion must make the female speak; partner response wins simultaneous completion: '..require('SceneZOI.Json').encode(spoken))
request(70,'exit');step(12,70);expect(70,'idle');restored()
voice_node.tasks.male.charge.rate=0
request(71,'start',voice_node.id);step(20,71);expect(71,'playing')
assert(#spoken==2 and spoken[2].speaker=='20524'and spoken[2].clip=='/Test/Complete.Complete','Female-only completion uses own response')
request(71,'exit');step(12,71);expect(71,'idle');restored()
assigned=false;request(72,'start',voice_node.id);step(20,72);expect(72,'playing');assert(#spoken==2,'No assigned voice must stay silent')
request(72,'exit');step(12,72);expect(72,'idle');restored()
VoiceEngine.selected=saved_selected;for k,v in pairs(saved_native)do NativeVoice[k]=v end
print('Voice response runtime passed: actual task callbacks, female speaker for own/partner events, partner priority at simultaneous completion, silent assignment, navigation and Exit.')

-- Furniture acquisition wraps the real session lifecycle before any participant mutation.
local F=require('SceneZOI.Furniture');local saved_prepare,saved_valid=F.prepare,F.valid
local anchor={bed=true};local valid=true;local deny=false;local hold_acquire=false;local hold_release=false;local messages={}
F.prepare=function(id,node)assert(id=='50'and node.furniture.kind=='bed.single');return {id=id,profile={id='test.bed'},anchor=anchor}end
F.valid=function()return valid end
local native_send=inzoi.message.send_to_sim
inzoi.message.send_to_sim=function(entity,kind,content)
 if kind~='SceneZOI.Furniture'then return native_send(entity,kind,content)end
 local f=Protocol.unpack(content);messages[#messages+1]=f
 if f[3]=='acquire'and hold_acquire or f[3]=='release'and hold_release then return end
 local result=f[3]=='release'and 'released'or deny and 'busy'or 'held'
 runtime.furniture_reply(actors[Protocol.id(entity)],{f[1],f[2],result})
end
local bednode=clone(fixture.nodes['scenezoi.standing_idle']);bednode.id='scenezoi.regression_bed_idle';bednode.furniture={kind='bed.single',surface_height_cm=45};bednode.navigation={};fixture.nodes[bednode.id]=bednode
local function bedstart(seq)
 request(seq,'start',bednode.id);cfg.request=cfg.request..'|50'
end
hold_acquire=true;bedstart(80);step(2,80);expect(80,'preparing');for _,binding in pairs(bindings)do assert(not binding.lease or not binding.lease.committed,'Participant mutation must wait for furniture reservation')end
hold_acquire=false;step(20,80);expect(80,'playing');assert(runtime.snapshot().node_id==bednode.id)
hold_release=true;request(80,'exit');step(3,80);expect(80,'exiting');hold_release=false;step(12,80);expect(80,'idle');restored()
deny=true;bedstart(81);step(12,81);expect(81,'error','furniture_unavailable');restored();deny=false
bedstart(82);step(20,82);expect(82,'playing');valid=false;step(12,82);expect(82,'error','furniture_changed');restored();valid=true
bedstart(83);step(20,83);expect(83,'playing');request(83,'exit');step(12,83);expect(83,'idle');restored()
F.prepare,F.valid=saved_prepare,saved_valid;inzoi.message.send_to_sim=native_send
print('Furniture runtime passed: reserve-before-participants, delayed acknowledgement, release barrier, occupied failure, moved/deleted furniture cancellation, exact restoration and repeat entry.')

-- Graceful spectator-distance exit and authoritative busy rejection.
local old_statics=UE.UGameplayStatics
UE.UGameplayStatics={GetPlayerController=function()return {GetCharacterEntityId=function()return {Value=tonumber(controlled_id)}end}end}
local range_limit=require('SceneZOI.Config').controller_max_distance_cm
local distant=0;local previous_location=actors['20530'].K2_GetActorLocation
actors['20530'].K2_GetActorLocation=function()return UE.FVector(distant,0,0)end
controlled_id='20524';request(84,'start');step(12,84);expect(84,'playing')
local active_request=cfg.request;cfg.request=Protocol.pack('other',1,'start','20530','scenezoi.standing_idle','male:20530+female:20532')
step(3,84);expect(84,'playing');assert(runtime.snapshot().id:match('^test%.84%.'))
assert(counts.toasts==1,'Repeated foreign Start must toast only once')
toast_failure=true;cfg.request=Protocol.pack('other',2,'start','20530','scenezoi.standing_idle','male:20530+female:20532')
step(3,84);expect(84,'playing');assert(runtime.snapshot().id:match('^test%.84%.'),'Optional toast failure must not end the active session')
cfg.request=active_request
controlled_id='20530';distant=range_limit-1;step(12,84);expect(84,'playing')
distant=range_limit+100;step(2,84);expect(84,'playing')
controlled_id='20522';step(2,84);expect(84,'playing')
controlled_id='20530';step(12,84);expect(84,'idle','controller_too_far');restored()
assert(cfg.last_exit==Protocol.pack('test',84,'controller_too_far','controller_too_far'),'Retain the explicit automatic-exit result')
controlled_id='20524';request(85,'start');step(12,85);expect(85,'playing');request(85,'exit');step(12,85);expect(85,'idle');restored()
actors['20530'].K2_GetActorLocation=previous_location;UE.UGameplayStatics=old_statics
print('Graceful runtime exits passed: authoritative busy status preservation, nearby/control swaps, delayed spectator distance, full cleanup and repeat entry.')


-- The SDK save command follows the normal cleanup barrier, including furniture.
request(86,'start');step(12,86);expect(86,'playing')
request(86,'save');step(12,86);expect(86,'idle','saving');restored()
assert(cfg.last_exit==Protocol.pack('test',86,'saving','saving'))
request(87,'start');step(12,87);expect(87,'playing');request(87,'exit');step(12,87);expect(87,'idle');restored()
request(88,'start');step(1,88);request(88,'save');step(12,88);expect(88,'idle','saving');restored()
print('SDK save runtime passed: snapshot acknowledgement, preparing/playing save exits, exact cleanup and repeat entry.')

assert(autosave_enabled,'Forced saving exits must still restore the temporary autosave lease')
print('Autosave runtime integration passed: normal/error/repeated/forced-save exits restore enabled state without changing the interval.')

-- Exercise the public start adapter and the real runtime, not only the search predicate.
local PublicAPI=require('SceneZOI.AddonAPI');local Meta=require('SceneZOI.Metadata')
local api_old_statics=UE.UGameplayStatics
UE.UGameplayStatics={GetPlayerController=function()return {GetCharacterEntityId=function()return {Value=tonumber(controlled_id)}end}end}
local Json=require('SceneZOI.Json');local source={by_kind={}}
for kind,file in pairs({tag_dictionary='tags',action_dictionary='actions'})do
 local f=assert(io.open('packs/scenezoi/metadata/'..file..'.json','rb'));local raw=f:read('*a');f:close()
 source.by_kind[kind]={{owner='scenezoi',source=file,data=Json.decode(raw)}}
end
fixture.metadata=Meta.compile(source)
local neutral=clone(fixture.nodes['scenezoi.standing_idle']);neutral.id='scenezoi.api_general';neutral.starting_hub=true
neutral.actions={{type='hug',actor='male',target='female'},{type='hug',actor='female',target='male'}}
neutral=Meta.resolve_scene(fixture.metadata,neutral)
local explicit=clone(neutral);explicit.id='scenezoi.api_explicit';explicit.starting_hub=false;explicit.content_rating='EXPLICIT';explicit.actions={{type='handjob',actor='female',target='male',performer='female'}}
neutral.navigation={{id='api.to_explicit',target=explicit.id}};explicit.navigation={{id='api.to_general',target=neutral.id}}
fixture.nodes[neutral.id]=neutral;fixture.nodes[explicit.id]=explicit
local Traits=require('SceneZOI.Traits');local original_capture=Traits.capture
Traits.capture=function(actor)local id=Protocol.id(actor:GetEntityId());return {id=id,body=id=='20522'and'male'or'female',body_age='Adult',growth_step='Youth'}end
local previous_send=inzoi.message.send_to_sim;local responses,public_events={},{}
inzoi.message.send_to_sim=function(id,kind,content)
 if kind=='SceneZOI.API.Response'then responses[#responses+1]=Json.decode(content);return end
 if kind=='SceneZOI.API.Event'then public_events[#public_events+1]=Json.decode(content).event;return end
 if kind=='SceneZOI.API.Depart'then PublicAPI.departure_reply(actors[Protocol.id(id)],content..'|ok');return end
 return previous_send(id,kind,content)
end
controlled_id='20524'
local function api(id,op,args,addon)
 PublicAPI.receive(actors['20524'],Json.encode({api_version=1,addon_id=addon or 'regression.addon',client_id='regression.client',request_id=id,operation=op,arguments=args}))
 return responses[#responses]
end
local r=api('start','start_at_hub',{initiator='20524',participants={'20524','20522'},session_restrictions={allowed_content_ratings={'GENERAL'}}})
assert(r.ok and r.result.scene_id==neutral.id);PublicAPI.tick(.5);PublicAPI.tick(.5)
local pending=Json.decode(assert(Protocol.decode(cfg.api_start)))
cfg.request=Protocol.pack('test',89,'start','20524',pending.entry.node,'female:20524+male:20522','none',pending.token)
step(12,89);expect(89,'playing')
local snap=runtime.snapshot();assert(snap.addon_id=='regression.addon'and snap.content_rating=='GENERAL')
assert(#Catalog.get(neutral.id,snap).navigation==0,'Restricted destinations must be omitted from navigation')
r=api('blocked','navigate_to_scene',{session_id=snap.id,scene_id=explicit.id});assert(not r.ok and r.code=='scene_restricted')
assert(runtime.snapshot().node_id==neutral.id,'Blocked API navigation must preserve playback')
cfg.navigation=Protocol.pack('test',89,'navigate',1,'api.to_explicit',snap.revision);step(3,89)
assert(runtime.snapshot().node_id==neutral.id,'Direct UI mailbox requests cannot bypass the same restriction')
r=api('foreign','stop_session',{session_id=snap.id},'foreign.addon');assert(not r.ok and runtime.snapshot())
r=api('stop','stop_session',{session_id=snap.id});assert(r.ok);step(12,89);expect(89,'idle');restored()
local started,ended=false,false
for _,event in ipairs(public_events)do if event.name=='session_started'then started=true elseif event.name=='session_ended'then ended=true end end
assert(started and ended,'Separate add-on subscribers receive both lifecycle boundaries')
Traits.capture=original_capture;inzoi.message.send_to_sim=previous_send;UE.UGameplayStatics=api_old_statics
print('Public API real-runtime restrictions passed: accepted start/save acknowledgement, filtered navigation, blocked API and UI routes, foreign-owner refusal, lifecycle events and complete Exit restoration.')
