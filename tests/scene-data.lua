package.path="modkit/SceneZOI_93C44199/workspace/lua/B1/?.lua;"..package.path
local J=require('SceneZOI.Json');local V=require('SceneZOI.DataValidation')
local function read(path)local f=assert(io.open(path,'rb'));local raw=f:read('*a');f:close();return J.decode(raw)end
local S=require('SceneZOI.SceneData');local P=require('SceneZOI.ProfileData')
local sources=J.decode(TEST_SCENE_PACKS);local core=sources.scenezoi;local content=sources.hzoi
core.expression_files=nil;core.data_files=nil;content.expression_files=nil;content.data_files=nil
local docs={{source='core',data=core},{source='content',data=content}}
local graph=S.compile(docs);assert(#graph.warnings==0,table.concat(graph.warnings,';'))
local count=0;for _ in pairs(graph.nodes)do count=count+1 end;assert(count==#core.nodes+#content.nodes)
assert(graph.nodes['scenezoi.standing_idle'].starting_hub)
assert(#graph.nodes['scenezoi.standing_idle'].navigation==1)
local neutral=S.compile({docs[1]});assert(#neutral.warnings==0 and #neutral.nodes['scenezoi.standing_idle'].navigation==0)
for _,size in ipairs({'queen','single'})do
 local prefix='hzoi.bed_'..size..'_'
 local stock=graph.nodes['scenezoi.bed_'..size..'_idle']
 local hub=assert(graph.nodes[prefix..'idle'])
 assert(#stock.navigation==1 and stock.navigation[1].target==hub.id and #hub.navigation==5)
 assert(not hub.starting_hub and V.equal(stock.tracks,hub.tracks))
 assert(hub.navigation[1].target==stock.id)
 for _,name in ipairs({'handjob','fellatio','female_mounted_sex_kissing'})do
  local node=assert(graph.nodes[prefix..name])
  assert(node.furniture.kind=='bed.'..size and #node.navigation==1 and node.navigation[1].target==hub.id)
 end
 local mounted=graph.nodes[prefix..'female_mounted_sex_kissing']
 assert(mounted.voices.female.context=='kiss' and mounted.expressions.female.context=='kiss' and mounted.expressions.male.context=='kiss')
 local penetration
 for _,a in ipairs(mounted.actions)do if a.type=='vaginal_sex' then penetration=a end end
 assert(penetration and penetration.actor=='male' and penetration.target=='female' and penetration.performer=='female')
 assert(mounted.sfx.kiss.sound_set=='hzoi.kiss' and mounted.sfx.contact.sound_set=='hzoi.piston' and mounted.sfx.contact.mode=='bone_distance')
end
for _,size in ipairs({'queen','single'})do
 local prefix='hzoi.bed_'..size..'_'
 local external=assert(graph.nodes[prefix..'aal_frontal'])
 assert(external.hide_if_tracks_missing and external.furniture.kind=='bed.'..size)
 assert(external.navigation[1].target==prefix..'idle')
 assert(external.tracks.male:match('^/Game/AAL/') and external.tracks.female:match('^/Game/AAL/'))
 assert(external.label=='Missionary' and V.equal(external.tags,{'eye_contact','missionary'}))
 assert(external.participant_tags.male[1]=='kneeling' and external.participant_tags.female[1]=='lying_on_back')
 assert(external.gaze.male.participant=='female' and external.gaze.female.participant=='male')
 local hold=external.actions[2]
 assert(hold.type=='holding_body' and hold.actor=='male' and hold.target=='female' and hold.performer=='male')
end
local broken=V.copy(content);broken.nodes[1].tracks.female='script()'
local bad=S.compile({docs[1],{source='broken',data=broken}});assert(#bad.warnings==1 and not bad.nodes['hzoi.standing_idle'])
local incompatible=V.copy(content);incompatible.nodes[1].participants.male.body='female'
local linked=S.compile({docs[1],{source='incompatible',data=incompatible}});assert(#linked.warnings>0 and #linked.nodes['scenezoi.standing_idle'].navigation==0)
local snapshot={by_kind={scene_pack=docs}}
for kind,file in pairs({tag_dictionary='tags',action_dictionary='actions'})do snapshot.by_kind[kind]={{owner='scenezoi',source=file,data=read('packs/scenezoi/metadata/'..file..'.json')}}end
snapshot.by_kind.body_profile={{owner='scenezoi',source='male_crotch',data=read('packs/scenezoi/profiles/male_crotch.json')}}
for kind,file in pairs({material_profile='skin_hair',coverage_attachment='region_attachment'})do snapshot.by_kind[kind]={{source=file,data=read(TEST_CONTENT_ROOT..'/packs/hzoi/profiles/'..file..'.json')}}end
local profiles=P.compile(snapshot);assert(#profiles.warnings==0 and profiles.rules['hzoi.region_attachment'])
for _,size in ipairs({'queen','single'})do
 assert(profiles.rules['hzoi.region_attachment'].node_animations['hzoi.bed_'..size..'_aal_frontal']:match('^/Game/AAL/'))
end
local body=profiles.body['scenezoi.male_crotch']
assert(body.schema_version==2 and body.section==17 and body.coverage_bit==17)
assert(body.patch_mesh=='/SceneZOI_93C44199/Compatibility/StockCoveragePatch.StockCoveragePatch')
assert(body.patch_mesh_overrides['/NaturalSkin_B5AE5C0D/Mesh/SKM_Male_Base_NS.SKM_Male_Base_NS']==
 '/SceneZOI_93C44199/Compatibility/ZoiBitsMaleCoveragePatch.ZoiBitsMaleCoveragePatch',
 'ZoiBits needs its fitted coverage patch without changing the stock-body default')
assert(not body.mesh_name and not body.material_slot and not body.compatible_layouts,'The body profile must not require a known replacer or slot name')
local function rejects_coverage(change,reason)
 local invalid=V.copy(snapshot)
 local rule=invalid.by_kind.coverage_attachment[1].data
 change(rule)
 local result=P.compile(invalid)
 assert(not result.rules[rule.id] and #result.warnings==1,result.warnings[1])
 assert(result.warnings[1]:find(reason,1,true),result.warnings[1])
end
rejects_coverage(function(rule)rule.section=5 end,'mismatched exposure profile')
rejects_coverage(function(rule)rule.attachment.body_profile='hzoi.missing' end,'mismatched exposure profile')
rejects_coverage(function(rule)rule.attachment.material_profile='hzoi.missing' end,'mismatched exposure profile')
rejects_coverage(function(rule)rule.attachment.retain_for_session='true' end,'Invalid boolean')
rejects_coverage(function(rule)rule.node_animations['scenezoi.standing_idle']='invalid track' end,'Invalid asset path')
local duplicate=V.copy(snapshot)
local competing=V.copy(duplicate.by_kind.coverage_attachment[1])
competing.source='competing_coverage_rule'
competing.data.attachment.socket='spine_01'
table.insert(duplicate.by_kind.coverage_attachment,competing)
local resolved=P.compile(duplicate)
assert(#resolved.warnings==1 and resolved.warnings[1]:find('Conflicting profile ID',1,true))
assert(resolved.rules['hzoi.region_attachment'].attachment.socket=='pelvis')
package.loaded['SceneZOI.DataFiles']={get=function()return snapshot end}
inzoi={cli={execute=function()return true end},EB1BodyAgeType={Adult=1}}
local Catalog=require('SceneZOI.Catalog')
local lengths={}
for id,scene in pairs(graph.nodes)do
 for _,path in pairs(scene.tracks)do lengths[path]=scene.duration end
 local path=profiles.rules['hzoi.region_attachment'].node_animations[id]
 if path then lengths[path]=scene.duration end
end
UE={UObject={Load=function(path)return {GetPlayLength=function()return lengths[path]or 10 end}end}}
local catalog=Catalog.refresh()
for _,size in ipairs({'queen','single'})do
 assert(catalog.nodes['hzoi.bed_'..size..'_aal_frontal'],'External scene did not resolve through its registered metadata')
end
local rule=profiles.rules['hzoi.region_attachment']
local function resolved_node(id)
 local value=Catalog.get(id)
 local people={}
 for role,requirements in pairs(value.participants)do
  people[#people+1]={id=tostring(#people+1),role=role,body=requirements.body,
   traits={body=requirements.body,body_age='Adult',growth_step='Adult'}}
 end
 -- A declaration-only preview has no actual age/stage. Resolve coverage only
 -- after representative native participant traits exist, as Runtime does.
 Catalog.resolve_appearance(value,people,{})
 return value
end
assert(not Catalog.get('scenezoi.standing_idle').attachments['hzoi.region_attachment.male'],
 'A no-roster preview must not claim to know an actual participant life stage')
for _,id in ipairs({'scenezoi.standing_idle','hzoi.standing_idle','hzoi.standing_hand_job','scenezoi.sofa_idle','hzoi.sofa_idle','hzoi.sofa_handjob','hzoi.sofa_fellatio','hzoi.sofa_rear'})do
 local attached=resolved_node(id).attachments
 local spec=assert(attached['hzoi.region_attachment.male'])
 assert(spec.participant=='male' and spec.body_profile=='scenezoi.male_crotch' and spec.material_profile=='hzoi.skin_hair')
 assert(spec.mesh==rule.attachment.mesh and spec.when_undressed and spec.retain_for_session)
 assert(spec.animation and spec.animation==rule.node_animations[id])
 assert(V.equal(spec.retained_tracks,rule.node_animations))
 assert(not attached['hzoi.region_attachment.female'])
 assert(not catalog.nodes[id].attachments,'Resolving coverage must leave the catalog unchanged')
end
local node=resolved_node('scenezoi.standing_idle')
local group=V.copy(node);group.participants={first={body='male'},second={body='male'},third={body='female'}};group.attachments=nil;group.id='test.mmf'
Catalog.value.nodes[group.id]=group
local multi=resolved_node(group.id);assert(multi.attachments['hzoi.region_attachment.first'] and multi.attachments['hzoi.region_attachment.second'])
assert(multi.attachments['hzoi.region_attachment.first']~=multi.attachments['hzoi.region_attachment.second'])
assert(multi.attachments['hzoi.region_attachment.first'].animation==nil,'Unknown nodes use a static attachment')
local packet=Catalog.simulation(node,{role='male'});assert(S.simulation(J.decode(J.encode(packet))).id==node.id)
assert(packet.cleanup_layers[1]=='SceneZOI_Prototype_MaleAnatomy')
Catalog.value.profiles={rules={}};assert(not next(resolved_node('scenezoi.standing_idle').attachments),'No content pack means no optional attachments')
local example={a='Japanese æ—¥æœ¬èªž \n \t " \\',b=J.array(),c={d=true},n=1.25,z=J.null}
assert(V.equal(J.decode(J.encode(example)),example))
local circular={};circular.self=circular;assert(not pcall(J.encode,circular));assert(not pcall(J.encode,{[1]=1,[3]=3}));assert(not pcall(J.encode,0/0))
local Choose=require('SceneZOI.StartingScenes')
local function person(id,body)return {id=id,body=body,body_age=1,growth_step='Youth'}end
local function hub(id,bodies)local roles={};for i,body in ipairs(bodies)do roles['role'..i]={body=body}end;return {id=id,starting_hub=true,participants=roles}end
local all={}
for _,combo in ipairs({'mf','mm','ff','mff','mmf','mmmm'})do
 local bodies={};for c in combo:gmatch('.')do bodies[#bodies+1]=c=='m'and'male'or'female'end
 all[combo]=hub(combo,bodies)
 local roster={};for i,body in ipairs(bodies)do roster[#roster+1]=person(tostring(i),body)end
 local chosen,n=Choose.choose(all,roster,function()return 1 end);assert(chosen and n>=1)
 local used={};for role,id in pairs(chosen.bindings)do assert(not used[id]);used[id]=true;assert(all[chosen.node].participants[role].body==roster[tonumber(id)].body)end
end
assert(not Choose.choose(neutral.nodes,{person('1','female'),person('2','female')}))
assert(not Choose.choose(neutral.nodes,{person('1','male'),person('2','female'),person('3','female')}))
local a=hub('a',{'male','female'});local b=V.copy(a);b.id='b'
for i=1,2 do local choice,n=Choose.choose({a=a,b=b},{person('2','female'),person('1','male')},function(size)assert(size==2);return i end);assert(choice.node==(i==1 and'a'or'b')and n==2)end
a.participants.role1.growth_steps={'Adult'};assert(not Choose.choose({a=a},{person('1','male'),person('2','female')}))
assert(not pcall(Choose.choose,{a=b},{person('1','male'),person('1','female')}))
print('Scene discovery, generic profiles, independent role attachments, validated simulation snapshots, JSON encoding and MF/MM/FF/MFF/MMF/4-role starting-scene matching passed.')
