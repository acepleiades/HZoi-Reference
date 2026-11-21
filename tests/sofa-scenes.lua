-- Exercise current authored sofa data, rather than the small historical catalog fixture.
package.path='modkit/SceneZOI_93C44199/workspace/lua/B1/?.lua;'..package.path
local J=require('SceneZOI.Json');local V=require('SceneZOI.DataValidation')
local S=require('SceneZOI.SceneData')
local packs=J.decode(TEST_SCENE_PACKS)
local docs={}
for _,owner in ipairs({'scenezoi','hzoi'})do
 local data=V.copy(assert(packs[owner]));data.data_files=nil;data.expression_files=nil
 docs[#docs+1]={owner=owner,source=owner,data=data}
end
local graph=S.compile(docs);assert(#graph.warnings==0,table.concat(graph.warnings,';'))
local nodes=graph.nodes
local core=assert(nodes['scenezoi.sofa_idle'])
local idle=assert(nodes['hzoi.sofa_idle'])
assert(core.starting_hub and core.hub=='sofa.pair')
assert(not idle.starting_hub and #core.navigation==1 and core.navigation[1].target==idle.id)
assert(#idle.navigation==4 and idle.navigation[1].target==core.id)
assert(not core.outfits and not idle.outfits,'Idle entry must not undress characters')
local counterparts={idle='hzoi.standing_idle',handjob='hzoi.standing_hand_job',fellatio='hzoi.male_standing_female_kneeling_fellatio',rear='hzoi.standing_rear'}
local function contains(values,want)for _,value in ipairs(values or {})do if value==want then return true end end;return false end
local function action(node,kind,performer)
 for _,value in ipairs(node.actions or {})do if value.type==kind and value.performer==performer then return value end end
end
for name,original_id in pairs(counterparts)do
 local node=assert(nodes['hzoi.sofa_'..name]);local original=assert(nodes[original_id])
 assert(node.fps==60 and node.duration==(name=='idle'and 4 or 10))
 assert(node.furniture.kind=='sofa.pair' and node.furniture.surface_height_cm==44)
 assert(V.equal(node.furniture,core.furniture)and V.equal(node.participants,core.participants))
 for _,field in ipairs({'expressions','voices','sfx','outfits','tasks','task_completion_sounds','task_completion_voices','movement_timing','completion_responses'})do
  assert(V.equal(node[field],original[field]),node.id..' must preserve counterpart '..field)
 end
 if name~='idle'then
  assert(#node.navigation==1 and node.navigation[1].target==idle.id)
  assert(node.movement_timing.cycles_per_second==1 and node.movement_timing.peak_phase==.5,
   'A ten-second clip contains one-second cycles, peaking at frame 30 of each 60-frame cycle')
 end
end
for _,id in ipairs({'hzoi.sofa_idle','hzoi.sofa_handjob'})do
 local node=nodes[id]
 assert(contains(node.tags,'eye_contact')and contains(node.participant_tags.female,'hzoi.on_partner_right'))
 for role,other in pairs({male='female',female='male'})do
  assert(V.equal(node.gaze[role],{participant=other,component='head',bones={'FACIAL_L_Eye','FACIAL_R_Eye'}}))
 end
end
assert(#idle.actions==1 and action(idle,'hug','male').target=='female','The female is not authoring a second embrace')
assert(contains(idle.participant_tags.male,'hzoi.arm_over_partner_right_shoulder'))
local hand=nodes['hzoi.sofa_handjob']
assert(action(hand,'handjob','female').target=='male'and action(hand,'holding_waist','male').target=='female')
assert(contains(hand.participant_tags.female,'hzoi.right_hand_on_partner_penis'))
local oral=nodes['hzoi.sofa_fellatio']
assert(#oral.actions==1 and action(oral,'fellatio','female').target=='male','No unrequested hand action')
assert(contains(oral.participant_tags.male,'sitting')and contains(oral.participant_tags.female,'kneeling'))
assert(contains(oral.participant_tags.female,'hzoi.on_floor')and contains(oral.participant_tags.female,'hzoi.on_partner_left'))
assert(V.equal(oral.gaze.male,{participant='female',component='body',bones={'head'}}))
assert(V.equal(oral.gaze.female,{participant='male',component='body',bones={'pelvis'}}))
local rear=nodes['hzoi.sofa_rear']
local performers={}
for _,value in ipairs(rear.actions)do if value.type=='vaginal_sex'then
 assert(value.actor=='male'and value.target=='female','Performer changes movement, not anatomical roles')
 assert(not performers[value.performer]);performers[value.performer]=true
end end
assert(performers.male and performers.female,'Both participants actively move')
assert(not contains(rear.tags,'eye_contact')and contains(rear.participant_tags.female,'facing_away'))
assert(contains(rear.participant_tags.female,'hzoi.hand_over_partner_hand'))
assert(contains(rear.participant_tags.male,'hzoi.hand_on_partner_lower_body')and contains(rear.participant_tags.male,'hzoi.hand_on_partner_left_thigh'))
for role,other in pairs({male='female',female='male'})do
 assert(contains(rear.participant_tags[role],'sitting')and contains(rear.participant_tags[role],'hzoi.bouncing'))
 assert(V.equal(rear.gaze[role],{participant=other,component='body',bones={'head'}}))
end
local function read(path)local f=assert(io.open(path,'rb'));local raw=f:read('*a');f:close();return J.decode(raw)end
local mapping=read(TEST_CONTENT_ROOT..'/packs/hzoi/profiles/region_attachment.json').node_animations
assert(mapping[core.id]==mapping[idle.id])
for name in pairs(counterparts)do
 local clip=name=='rear'and'rear_sex'or name
 assert(mapping['hzoi.sofa_'..name]=='/HZoi_660649D8/Animations/HZoi_sofa_'..clip..'_MA.HZoi_sofa_'..clip..'_MA')
end
local localization=read(TEST_CONTENT_ROOT..'/packs/hzoi/localization/text.json')
local languages=0
for locale,value in pairs(localization.translations)do
 languages=languages+1
 for name in pairs(counterparts)do
  assert(value.labels['scene.hzoi.sofa_'..name],locale..' scene label')
  assert(value.labels['navigation.hzoi.sofa_'..name..'.'..(name=='idle'and'neutral'or'idle')],locale..' Return label')
 end
end
assert(languages==15)
print('Sofa content passed: hub navigation, furniture, exact counterpart effects, one-second peak, gaze, distinct movement performers, anatomy tracks and all 15 locales.')
