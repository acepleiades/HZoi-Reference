package.path='modkit/SceneZOI_93C44199/workspace/lua/B1/?.lua;'..package.path
local J=require('SceneZOI.Json');local D=require('SceneZOI.CompletionData')
local source=J.decode(TEST_SCENE_PACKS).hzoi
local count=0
for _,node in ipairs(source.nodes)do
 local activity=false
 for _,action in ipairs(node.actions or {})do
  if action.type=='handjob'or action.type=='fellatio'or action.type=='vaginal_sex'then activity=true end
 end
 if activity then
  local timing=assert(node.movement_timing,node.id..' is missing movement timing')
  assert(node.fps==60 and node.duration==10 and timing.cycles_per_second==1 and timing.peak_phase==.5,node.id)
  D.timing(timing,node.duration)
 else assert(not node.movement_timing,'Idle stays free of movement timing')end
 if node.tasks and next(node.tasks)then
  count=count+1
  assert(activity)
  D.responses(node.completion_responses,node.participants,node.kind)
  assert(not node.task_completion_routes,'Production scenes retain procedural responses, not test routes')
  for _,role in ipairs({'male','female'})do
   local effect=assert(node.completion_responses[role].excitement)
   assert(effect.enabled)
   if role=='male'then assert(effect.slowdown.repeats==2 and effect.slowdown.high_speed==.5 and effect.slowdown.low_speed==1/12)
   else assert(effect.slowdown==nil,'Female completion must never request slowdown')end
   local s=effect.shake
   assert(s.delay==.5 and s.frequency_hz==18 and s.amplitude_degrees==1.25 and #s.bones==6)
   if role=='male'then assert(s.duration==6 and s.bursts==3 and s.duty_cycle==.7)
   else assert(s.duration==3 and s.bursts==1 and s.duty_cycle==1)end
   assert(s.bones[1].weight==1 and s.bones[2].weight==.4 and s.bones[3].weight==.05)
   assert(s.bones[4].weight==-.8 and s.bones[5].weight==-.32 and s.bones[6].weight==-.04)
  end
  local E=require('SceneZOI.CompletionEffects');local Clock=require('SceneZOI.Clock')
  local people={male={id='male_owner',role='male'},female={id='female_owner',role='female'}}
  local session={node=node,duration=node.duration,clock=Clock.new(),bindings=people}
  local ctx={};E.prepare(ctx,session)
  local function completed(role)return {participant_id=people[role].id,participant_role=role,task={id='excitement',completed=true,completion_index=1}}end
  E.trigger(ctx,{completed('female')})
  assert(not ctx.motion and ctx.shakes.female_owner and E.multiplier(ctx,1,1)==1,'Real female-only content response must shake without slowdown')
  E.trigger(ctx,{completed('male')})
  assert(ctx.motion and ctx.source=='male_owner|excitement'and ctx.shakes.male_owner and ctx.shakes.female_owner,'Male completion starts shared slowdown without removing female shaking')
 else assert(not node.completion_responses,'Scenes without tasks stay free of completion responses')end
end
assert(count==14)
local nodes={}
for _,node in ipairs(source.nodes)do nodes[node.id]=node end
local rear=assert(nodes['hzoi.standing_rear'])
local V=require('SceneZOI.DataValidation')
for _,size in ipairs({'single','queen'})do
 local node=assert(nodes['hzoi.bed_'..size..'_aal_frontal'])
 assert(node.hide_if_tracks_missing)
 for _,field in ipairs({'tasks','completion_responses','task_completion_voices'})do
  assert(V.equal(node[field],rear[field]),node.id..' must match Standing Rear Sex for '..field)
 end
end
local file=assert(io.open('packs/scenezoi/tasks/excitement.json','rb'));local task=J.decode(file:read('*a'));file:close()
assert(task.id=='excitement' and task.completion_event=='orgasm','SceneZOI supplies the shared task')
assert(not task.on_completion,'Shared excitement definition has no pack sound')
local clip=source.sound_sets['hzoi.excitement_completion'].default.clips[1]
assert(clip:find('SW_ejaculation',1,true),'Owned completion sound remains in HZoi')
local count=0
for _,node in ipairs(source.nodes)do
 local role=node.tasks and node.tasks.male
 if role and role.excitement then
  local sound=assert(node.task_completion_sounds.male.excitement[1])
  assert(sound.sound_set=='hzoi.excitement_completion'and sound.source.bones[1]=='pelvis'and sound.volume==1)
  assert(not node.task_completion_sounds.female);count=count+1
 else assert(not node.task_completion_sounds) end
end
assert(count==14,'Every authored activity with a male excitement task registers the one-shot')
print('HZoi completion data passed: standing, bed and sofa cycle timing, male-only slowdown, female-only runtime response, both reference shaking profiles and unchanged male pelvis one-shot; idle and task caps preserved.')
