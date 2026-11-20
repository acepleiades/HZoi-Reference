# Character voices and sound effects

A **voice context** is what the scene asks for. An **archetype** is a voice
personality. A **voice set** supplies that personality’s clips for a context
on a compatible body. The player’s choice belongs to the Zoi and follows the
same Zoi across scenes and save files.

| Archetype | Breath | Kiss | Fellatio | Sex |
| --- | --- | --- | --- | --- |
| Cute | Shinonoi Rin | Shinonoi Rin | Megu Hiiragi | Echioto A1, A2, B1, B2, B3 |
| Mature (female default) | Shinonoi Rin | Shinonoi Rin | Megu Hiiragi | Megu Hiiragi |
| Downer | Shinonoi Rin | Shinonoi Rin | Megu Hiiragi | Megu Hiiragi |

Follow the [Mature archetype](../packs/hzoi/voices/archetype_mature.json),
the [Sex context](../packs/hzoi/voices/context_sex.json), and
[one compatible set](../packs/hzoi/voices/set_megu_hiiragi_mature_sex.json).
In [Standing Rear](../packs/hzoi/scenes/04_standing_rear.json), the female
role requests `sex`, so SceneZOI plays clips from the set selected for her.
A player who chose None for that character or context still gets silence.

Use voice declarations for a Zoi’s vocal sounds so these choices and the
separate male and female voice volume controls apply. Use sound emitters
for contact sounds, props, and ambience. Those effects respond to the
Sound Effects slider, and they can be triggered by distance between bones
or repeated continuously according to the scene.

## Voice responses

[Standing Rear](../packs/hzoi/scenes/04_standing_rear.json) requests different
named response groups after the two participants complete Excitement. The
female Zoi speaks both lines. Her reaction to the partner’s completion has
priority if both events arrive together. SceneZOI fades her continuous
voice before a response, then resumes it afterward.

The [standing fellatio scene](../packs/hzoi/scenes/03_male_standing_female_kneeling_fellatio.json)
shows the completing role and responding speaker can be different. Configure
that through `task_completion_voices` and put the corresponding response
group in each set that provides it. Keep response-only clips out of the
continuous pool so they play when the event calls for them.

The reference WAVs are silent. For your own mod, listen on multiple voice
sets, check a None selection, and adjust the voice and effects sliders
separately before publishing.
[SceneZOI voice set guide](https://github.com/acepleiades/SceneZOI/blob/main/docs/voice-set-authoring.md)
