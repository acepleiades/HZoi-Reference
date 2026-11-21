# Build a scene players can configure

Start with a working loop. Then decide what the characters should look at,
how they should sound, and what players should see when a task finishes.
These choices belong in the scene and its shared declarations. Gameplay mods
can start the same scene through the API and get the same authored behavior.
This checkout supplies rest-pose animation placeholders and silent audio.
Its JSON shows the real HZoi setup; use your own clips or the player pack
when checking motion, contact and sound.

## Match the furniture and the roster

Compare the [single-bed hub](../packs/hzoi/scenes/05_single_bed_idle.json) and
[queen-bed hub](../packs/hzoi/scenes/05_queen_bed_idle.json), then open the
[queen-bed activity](../packs/hzoi/scenes/08_queen_bed_female_mounted_sex_kissing.json).
Each scene declares its furniture kind and the support plane of its source
animation. The bed scenes use a 0 cm authored plane. SceneZOI places that plane at the
surface defined by the selected in-game furniture profile. Keep the furniture
kind and the participant roles consistent throughout each branch so players
can navigate and Exit without changing bed or losing their role bindings.

The [manifest](../packs/hzoi.json) adds paths from the framework hubs.
Separate single and queen nodes make their navigation explicit and let them
reuse the same tracks where the motion works on both. Test contact and
clearance in game on the actual furniture.
[Furniture profiles](https://github.com/acepleiades/SceneZOI/blob/main/docs/furniture.md)

## Describe a sofa scene accurately

The [sofa idle](../packs/hzoi/scenes/10_sofa_idle.json) starts from
`scenezoi.sofa_idle`, then links to three activities. Every node in this
branch uses `sofa.pair`, the same two participant roles, and a 44 cm authored
support plane. That is the seat height in the animation's reference scene;
it does not replace the selected sofa profile's measured height.

The scenes keep these details distinct:

| Scene | Contacts and gaze |
| --- | --- |
| [Idle](../packs/hzoi/scenes/10_sofa_idle.json) | The female sits on the male's right. He rests an arm over her right shoulder. Both look at the other's eyes; only the male performs the embrace. |
| [Handjob](../packs/hzoi/scenes/11_sofa_handjob.json) | The seating and eye contact remain. Her right hand performs the action; his hand holds her waist. |
| [Fellatio](../packs/hzoi/scenes/12_sofa_fellatio.json) | He sits; she kneels on the floor on his left. His gaze targets her head; hers targets his pelvis. |
| [Rear sex](../packs/hzoi/scenes/13_sofa_rear.json) | She sits on him facing away and both actively move. They look toward each other's head without an `eye_contact` tag. The hand-contact tags describe the lower body, left thigh and overlapping hands. |

For the last scene, two `vaginal_sex` action records share the same anatomical
`actor` and `target`, but use different `performer` values. This tells a
gameplay integration that both participants actively move. Reversing actor
and target would describe a different anatomical action. The additional
`hzoi.*` tags are defined in [the sofa dictionary](../packs/hzoi/metadata/sofa_tags.json),
so their meaning is explicit and does not conflict with another pack's tags.

Gaze chooses an eye target. It does not repair a head or body pose, so keep
head movement in the animation and test the result from several camera angles.
These reference assets stay in rest pose: their metadata describes the intended
player-pack scenes, not visible motion in the placeholders.

## Offer an optional animation library

The [queen-bed AAL scene](../packs/hzoi/scenes/09_queen_bed_aal_frontal.json)
and its [single-bed counterpart](../packs/hzoi/scenes/09_single_bed_aal_frontal.json)
reference external body tracks. The
[coverage attachment profile](../packs/hzoi/profiles/region_attachment.json)
maps the corresponding attachment track. With `hide_if_tracks_missing` enabled,
SceneZOI shows each scene and its menu link only when all required tracks load
and match the authored timing. A player without AAL can still use the rest
of HZoi. The reference keeps these paths so you can see the real setup.

Use this pattern whenever players can install a library separately. Test
both configurations after restarting the game. With the library mounted,
check the loop, attachment sync, and Exit. Without it, check the menu and
API search results.
[Optional animation tracks](https://github.com/acepleiades/SceneZOI/blob/main/docs/authoring.md#optional-animation-assets)

## Let each character keep their voice

The [standing rear scene](../packs/hzoi/scenes/04_standing_rear.json)
asks for the `sex` voice context. SceneZOI looks up that context in the
speaking Zoi’s selected set. The player can choose a different voice or
silence that context for the same Zoi across scenes and save files. The
[Mature set](../packs/hzoi/voices/set_megu_hiiragi_mature_sex.json) shows
how continuous clips and named one-shot reactions live together in one set.

Put breathing, speech, and vocal reactions through `voices` and
`task_completion_voices` so the character’s selection and the female or male
voice slider apply. Use `sfx` for contact sounds or props so players can
adjust them independently with the Sound Effects slider. A vocal clip sent
through a sound emitter follows the Sound Effects slider and bypasses
the character’s voice choice.

Give animated facial expressions a context for the same reason. The player’s
chosen expression set supplies the clip. Reserve a fixed facial pose for
places where the shape is part of the scene’s timing or contact.
[HZoi voice examples](voices.md) · [Expression examples](expressions.md)

## Give task completion a visible or audible result

Follow [SceneZOI’s shared Excitement task](https://github.com/acepleiades/SceneZOI/blob/main/packs/scenezoi/tasks/excitement.json) into the
[standing rear scene](../packs/hzoi/scenes/04_standing_rear.json). SceneZOI
defines the meter and completion event. The HZoi scene decides the rate and
cap for each role, then describes the response to reaching 100%. HZoi uses
SceneZOI’s shared definition under the [task provider rules](scene-tasks.md#how-scenezoi-resolves-shared-task-ids).

- `task_completion_sounds` plays a one-shot effect from the completing Zoi.
  It uses a shared sound set so several scenes can reference the same clip.
- `task_completion_voices` asks the selected voice set for a named response.
  The speaker can be the completing Zoi or the other role. HZoi gives the
  partner reaction priority when two lines would otherwise overlap.
- `movement_timing` marks an animation cycle and its peak phase.
  `completion_responses` uses that timing to slow the shared motion in sync
  and can shake the completing participant’s legs independently. In HZoi the
  male role starts the slowdown and either role can have its own shake.
  The sofa activities retain the standing scenes' timing: one cycle per
  second, peaking at phase `0.5` (frame 30 at 60 fps). A ten-second file
  contains ten cycles; use the cycle timing when synchronizing the response.

A meter can be useful on its own. Add a response when players need to feel
that something happened, and choose one that fits the action. Keep pack
effects on the scenes using them so another pack can share the task without
inheriting your sound or motion. On an autonomous scene, test whether the
desired response can finish before Exit and set a post-completion stay if
the authored presentation needs it.
[Task authoring](scene-tasks.md) · [Procedural completion controls](https://github.com/acepleiades/SceneZOI/blob/main/docs/completion-effects.md)

## Review a pack made with an AI agent

Give the agent the intended roles, contacts, furniture, voice contexts, and
what should happen at completion. Have it point to the corresponding JSON
in this reference and explain how each feature serves your scene. Ask it to
flag any behavior it left out so you can decide whether that was intentional.

Load the pack in game yourself. Change the character’s voice and volume,
then adjust Sound Effects separately. Watch both roles reach completion,
test any caps that should hold a role below 100%, and verify navigation and
Exit. Repeat with each optional library missing. The reference WAVs are
silent, so use your own recordings or the HZoi player pack for listening tests.
