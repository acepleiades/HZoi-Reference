# Scene tasks

HZoi declares the `excitement` task in
[`packs/hzoi/tasks/excitement.json`](../packs/hzoi/tasks/excitement.json).
SceneZOI discovers its native `scene_task` declaration and supplies the reusable
engine. HZoi contains no executable task code.

Defaults are maximum **90**, initial **0**, decay **1 unit per game second**, and
completion event **`orgasm`**. Percentage is relative to the configured maximum.
The declaration supplies male blue (`#3185c3`) and female pink (`#df85ac`) indicators.

| Scene | Male role | Female role |
| --- | --- | --- |
| HZoi Standing Idle | Omitted: decay | Omitted: decay |
| Standing Handjob | +1/second, cap 100% | +0.5/second, cap 50% |
| Male Standing Female Kneeling Fellatio | +1/second, cap 100% | +0.5/second, cap 50% |
| Standing Rear Sex | +1/second, cap 100% | +1/second, cap 100% |

The framework hub also omits progression. Explicit zero holds the current value;
omission permits decay. Negative rates reduce progress. SceneZOI's user settings
can scale the authored rates by participant body type.

Completion resets that participant's value to zero and emits `task_completed`
with task ID `excitement` and completion event `orgasm`. Independent add-ons
should use SceneZOI's public API and events rather than framework-internal
dispatchers. Session progress survives navigation and is discarded at Exit;
it is not stored in the save.

## Completion sound and voices

The task's `on_completion` sound filters the completing participant's appearance
body to male and follows the body component's pelvis bone. Its six-second WAV is
**silent in this reference** because the original recording is proprietary.
The declaration demonstrates a local, independently owned one-shot with volume
1.0 and default attenuation. Female completions do not play it.

Fellatio maps male completion to the female speaker's finish group. Rear sex
maps female completion to her own response and male completion to her reaction,
with higher priority for the latter. See [voice bindings](voices.md#completion-voice-responses).

## Procedural completion responses

The three activity scenes declare movement timing of one cycle per second with
peak phase 0.5, and responses for each role. Only male completion requests the
shared scene slowdown; female completion requests her own leg shaking. These
resources are independently owned for cleanup. The 50% female cap in handjob
and fellatio prevents independent completion from zero in those scenes.

The authored slowdown spans two cycles, ranging from 0.5 to 1/12 speed, followed
by 0.4-second recovery. Shaking uses a 0.5-second delay, 18 Hz frequency and
1.25-degree base amplitude, weighted across thigh, calf, foot and ball bones.
Male profiles use three bursts across six seconds; female profiles use one
three-second burst. See the JSON for exact per-bone weights and duty cycle.

The idle scene has no progression or procedural response. None of the current
scenes adds an automatic completion route. See [task authoring](https://github.com/acepleiades/SceneZOI/blob/main/docs/scene-tasks.md)
and [completion effects](https://github.com/acepleiades/SceneZOI/blob/main/docs/completion-effects.md)
for generic schemas. Automated validation of this reference is separate from
native import and visual acceptance.
