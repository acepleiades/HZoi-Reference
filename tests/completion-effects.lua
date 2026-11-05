package.path='modkit/SceneZOI_93C44199/workspace/lua/B1/?.lua;'..package.path
local J=require('SceneZOI.Json');local D=require('SceneZOI.CompletionData')
local source=J.decode(TEST_SCENE_PACKS).hzoi
local count=0
for _,node in ipairs(source.nodes)do
 if node.tasks and next(node.tasks)then
  count=count+1;assert(node.movement_timing.cycles_per_second==1 and node.movement_timing.peak_phase==.5 and node.duration==10 and node.fps==60)
  D.timing(node.movement_timing,node.duration);D.responses(node.completion_responses,node.participants,node.kind)
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
 else assert(not node.movement_timing and not node.completion_responses,'Idle stays free of completion effects')end
end
assert(count==3)
local file=assert(io.open(TEST_CONTENT_ROOT..'/packs/hzoi/tasks/excitement.json','rb'));local task=J.decode(file:read('*a'));file:close()
assert(#task.on_completion==1 and task.on_completion[1].type=='play_sound'and task.on_completion[1].when.body=='male')
assert(task.on_completion[1].source.bones[1]=='pelvis'and task.on_completion[1].volume==1)
print('HZoi completion data passed: all three task scenes, one-second/frame-30 timing, male-only slowdown, female-only runtime response, both reference shaking profiles and unchanged male pelvis one-shot; idle and task caps preserved.')
