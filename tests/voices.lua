package.path='modkit/SceneZOI_93C44199/workspace/lua/B1/?.lua;'..package.path
local J=require('SceneZOI.Json');local D=require('SceneZOI.VoiceData');local Scene=require('SceneZOI.SceneData')
local function read(path)local f=assert(io.open(path,'rb'));local raw=f:read('*a');f:close();return J.decode(raw)end
local pack=read(TEST_CONTENT_ROOT..'/packs/hzoi.json');local source={by_kind={}}
for _,entry in ipairs(pack.data_files)do source.by_kind[entry.kind]=source.by_kind[entry.kind]or {};table.insert(source.by_kind[entry.kind],{source=entry.file,data=read(TEST_CONTENT_ROOT..'/packs/'..entry.file)})end
local data=D.compile(source);assert(#data.warnings==0,table.concat(data.warnings,'; '))
local count=0;for _ in pairs(data.sets)do count=count+1 end;assert(count==16 and data.defaults.female=='hzoi.mature'and not data.defaults.male)
for _,c in ipairs({'breath','kiss','sex','fellatio'})do
 assert(data.contexts[c]);for _,a in ipairs({'hzoi.cute','hzoi.mature','hzoi.downer'})do
  local found=false;for _,s in pairs(data.sets)do if s.context==c and s.archetype==a then found=true end end;assert(found,a..' lacks '..c)
 end
end
local inventory=read(TEST_CONTENT_ROOT..'/audio-inventory.json');local assets={}
for _,a in ipairs(inventory.assets)do assets[a.asset]=a end
for _,set in pairs(data.sets)do
 for _,path in ipairs(set.clips)do
  local a=assert(assets[path],path);assert(a.category=='voice');local lower=a.source:lower()
  assert(not lower:find('orgasm',1,true)and not lower:find('climax',1,true)and not lower:find('finish',1,true),'Tier 4 clip used in continuous voices')
 end
end
local packs=J.decode(TEST_SCENE_PACKS);packs.hzoi.expression_files=nil;packs.hzoi.data_files=nil;packs.scenezoi.expression_files=nil;packs.scenezoi.data_files=nil
local graph=Scene.compile({{source='hzoi',data=packs.hzoi},{source='core',data=packs.scenezoi}})
assert(#graph.warnings==0,table.concat(graph.warnings,'; '))
assert(not graph.nodes['hzoi.standing_idle'].voices and not graph.nodes['scenezoi.standing_idle'].voices)
assert(graph.nodes['hzoi.standing_hand_job'].voices.female.context=='breath')
local renamed=assert(graph.nodes['hzoi.male_standing_female_kneeling_fellatio']);assert(renamed.label=='Male Standing Female Kneeling Fellatio'and renamed.voices.female.context=='fellatio')
assert(not graph.nodes['hzoi.standing_kneeling']);assert(graph.nodes['hzoi.standing_rear'].voices.female.context=='sex')
local found=false;for _,edge in ipairs(graph.nodes['hzoi.standing_idle'].navigation)do if edge.target==renamed.id then found=true;assert(edge.label==renamed.label)end end;assert(found)
print('HZoi voices passed: 3 archetypes/16 sets, exact owned normal audio, no Tier 4 clips, four complete contexts, Mature/silent-male defaults, silent hubs and all requested scene bindings/renamed navigation.')


local response_sets=0
for _,set in pairs(data.sets)do
 local groups=set.responses or {}
 if set.context=='sex'then assert(groups.orgasm and groups.male_climax_reaction);response_sets=response_sets+1
 elseif set.context=='fellatio'then assert(groups.fellatio_finish);response_sets=response_sets+1
 else assert(not next(groups))end
 for _,group in pairs(groups)do for _,path in ipairs(group.clips)do assert(assets[path]and assets[path].category=='voice','Response must use existing imported voice asset')end end
end
assert(response_sets==10)
local rear=graph.nodes['hzoi.standing_rear'].task_completion_voices
assert(rear.male.excitement[1].participant=='female'and rear.male.excitement[1].response=='male_climax_reaction')
assert(rear.female.excitement[1].participant=='female'and rear.female.excitement[1].response=='orgasm')
assert(rear.male.excitement[1].priority>rear.female.excitement[1].priority,'Female reaction to male completion must outrank her own line')
local finish=renamed.task_completion_voices.male.excitement[1]
assert(finish.participant=='female'and finish.context=='fellatio'and finish.response=='fellatio_finish'and finish.fade_out==.25)
assert(not graph.nodes['hzoi.standing_hand_job'].task_completion_voices and not graph.nodes['hzoi.standing_idle'].task_completion_voices)
print('HZoi voice responses passed: ten existing sets, owned completion/partner/finish clips, female speaker in all bindings, reaction priority, unchanged normal clips and unchanged four-context personality UI.')
