# Scene tasks and completion effects

Use a task when a scene needs measurable progress, a cap for one role,
or an event another mod can use. HZoi uses
[SceneZOI’s shared Excitement definition](https://github.com/acepleiades/SceneZOI/blob/main/packs/scenezoi/tasks/excitement.json).
Use the same `excitement` ID in your scene to get the shared meter and the
`orgasm` completion event. Keep the rates, caps, and responses on the scene.
The standing handjob scene uses this `tasks` block.

```json
{
  "tasks": {
    "male": {"excitement": {"rate": 1, "cap_percent": 100}},
    "female": {"excitement": {"rate": 0.5, "cap_percent": 50}}
  }
}
```

## How SceneZOI resolves shared task IDs

SceneZOI checks for definitions in this order.

1. The current scene’s content pack, if it defines the task ID.
2. SceneZOI’s shared definition, if it has one.
3. The provider named by the scene in `task_providers`.
4. If no provider is named, the first pack ID alphabetically among the packs
   that define the task.

The pack ID is the internal identifier, independent of load order or the
mod that started the session. If the lookup reaches a named provider and it
is missing, the task is unavailable in that scene. When definitions disagree,
`scenezoi_runtime/mod_inventory.cfg` lists the providers and the fallback winner.

HZoi 1.3.2 relies on step 2 for `excitement`. A second pack can still use its
own definition in its own scenes. At a scene change, SceneZOI 1.3.12 keeps
each participant’s percentage and completion count and applies the
destination scene’s rules. [SceneZOI task provider rules](https://github.com/acepleiades/SceneZOI/blob/v1.3.12/docs/scene-tasks.md#choose-which-definition-a-scene-uses)

## Set progress for the scene

The [standing handjob scene](../packs/hzoi/scenes/02_standing_hand_job.json)
lets the male role complete Excitement and caps the female role at 50%.
[Standing Rear](../packs/hzoi/scenes/04_standing_rear.json) lets both roles
reach 100%. An idle scene omits the progression rule so accumulated progress
can decay. Use an explicit rate of zero if you want it held instead.

## Attach effects to the scene

[Standing Rear](../packs/hzoi/scenes/04_standing_rear.json) combines three
effects using the same task.

- The male role’s `task_completion_sounds` uses an HZoi
  [sound set](../packs/hzoi.json) and plays from the pelvis. Every HZoi
  activity scene that uses this cue references that set.
- The female role’s selected voice set handles both her own response and
  her reaction to the male completion. The partner reaction has higher
  priority when they coincide. See [voice responses](voices.md#voice-responses).
- `movement_timing` identifies a one-second cycle with a peak at frame 30
  in a 60 fps animation. The male role’s `completion_responses` slows that
  motion for two cycles. His leg shake lasts six seconds and her independent
  shake lasts three seconds. Her completion can shake her legs without
  restarting the shared motion.

The task resets and publishes its completion event independently of the
presentation. Putting effects on each scene lets other packs share the
meter without inheriting HZoi effects. Use a different task ID if a pack
needs to change what the shared task means.
[SceneZOI task schema](https://github.com/acepleiades/SceneZOI/blob/main/docs/scene-tasks.md)
