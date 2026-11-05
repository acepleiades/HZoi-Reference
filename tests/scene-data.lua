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
local broken=V.copy(content);broken.nodes[1].tracks.female='script()'
local bad=S.compile({docs[1],{source='broken',data=broken}});assert(#bad.warnings==1 and not bad.nodes['hzoi.standing_idle'])
local incompatible=V.copy(content);incompatible.nodes[1].participants.male.body='female'
local linked=S.compile({docs[1],{source='incompatible',data=incompatible}});assert(#linked.warnings>0 and #linked.nodes['scenezoi.standing_idle'].navigation==0)
local snapshot={by_kind={scene_pack=docs}}
for kind,file in pairs({tag_dictionary='tags',action_dictionary='actions'})do snapshot.by_kind[kind]={{owner='scenezoi',source=file,data=read('packs/scenezoi/metadata/'..file..'.json')}}end
for kind,file in pairs({body_profile='body_layout',material_profile='skin_hair',coverage_attachment='region_attachment'})do snapshot.by_kind[kind]={{source=file,data=read(TEST_CONTENT_ROOT..'/packs/hzoi/profiles/'..file..'.json')}}end
local profiles=P.compile(snapshot);assert(#profiles.warnings==0 and profiles.rules['hzoi.region_attachment'])
local invalid=V.copy(snapshot);invalid.by_kind.coverage_attachment[1].data.section=5
assert(not next(P.compile(invalid).rules))
package.loaded['SceneZOI.DataFiles']={get=function()return snapshot end}
inzoi={cli={execute=function()return true end},EB1BodyAgeType={Adult=1}}
local Catalog=require('SceneZOI.Catalog');Catalog.refresh()
local node=Catalog.get('scenezoi.standing_idle');local spec=assert(node.attachments['hzoi.region_attachment.male'])
assert(spec.participant=='male' and spec.body_profile=='hzoi.body_layout' and spec.when_undressed)
assert(not node.attachments['hzoi.region_attachment.female'])
local group=V.copy(node);group.participants={first={body='male'},second={body='male'},third={body='female'}};group.attachments=nil;group.id='test.mmf'
Catalog.value.nodes[group.id]=group
local multi=Catalog.get(group.id);assert(multi.attachments['hzoi.region_attachment.first'] and multi.attachments['hzoi.region_attachment.second'])
assert(multi.attachments['hzoi.region_attachment.first']~=multi.attachments['hzoi.region_attachment.second'])
assert(multi.attachments['hzoi.region_attachment.first'].animation==nil,'Unknown nodes use a static attachment')
local packet=Catalog.simulation(node,{role='male'});assert(S.simulation(J.decode(J.encode(packet))).id==node.id)
assert(packet.cleanup_layers[1]=='SceneZOI_Prototype_MaleAnatomy')
Catalog.value.profiles={rules={}};assert(not Catalog.get('scenezoi.standing_idle').attachments,'No content pack means no optional attachments')
local example={a='Japanese 日本語 \n \t " \\',b=J.array(),c={d=true},n=1.25,z=J.null}
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
