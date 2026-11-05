# HZoi voices

**All audio in this reference is silent because the original recordings are
proprietary.** Clip names, durations and declarations remain useful examples;
they do not provide the original recordings. See [reference assets](reference-assets.md).

HZoi contributes `voice_archetype`, `voice_context` and `voice_set` declarations
under [`packs/hzoi/voices/`](../packs/hzoi/voices/). SceneZOI owns playback, the
personality UI and persistent preferences. No content-pack scripts are required.

There are three female archetypes, four contexts and sixteen sets. The table
identifies the original source libraries for attribution, not included audio.

| Archetype | Breath | Kiss | Fellatio | Sex |
| --- | --- | --- | --- | --- |
| Cute | Shinonoi Rin | Shinonoi Rin | Megu Hiiragi | Echioto A1, A2, B1, B2, B3 |
| Mature (female default) | Shinonoi Rin | Shinonoi Rin | Megu Hiiragi | Megu Hiiragi |
| Downer | Shinonoi Rin | Shinonoi Rin | Megu Hiiragi | Megu Hiiragi |

Changing archetype selects compatible context defaults. Users can choose None
per context or None (silent) as their archetype. HZoi supplies no male voice set;
the framework supports sets for either body type. Display labels are localized.

| Scene | Female voice context |
| --- | --- |
| HZoi Standing Idle | None |
| Standing Handjob | Breath |
| Male Standing Female Kneeling Fellatio | Fellatio |
| Standing Rear Sex | Sex |

The neutral framework hub also supplies no voice instruction. Every HZoi set
uses `gap: 0`, so continuous random playback has no additional authored pause.
Authored volumes remain in the data (Sex 0.8, Fellatio 0.45); silent samples,
rather than zero playback volume, prevent disclosure of proprietary recordings.

## Completion voice responses

Ten Sex/Fellatio sets include named response groups excluded from continuous
playback. Scene bindings demonstrate independent completing and speaking roles:

- Fellatio: male excitement completion selects a female `fellatio_finish` response.
- Rear sex: female completion selects her own `orgasm` response; male completion
  selects her `male_climax_reaction` response. Both use the female speaker.
- The male-completion reaction has priority 20, versus 10 for her own completion.
  It suppresses or preempts the lower-priority response instead of queuing it.

Continuous voice fades over 0.25 audio seconds before a response and resumes
afterward. Silent personality selections stay silent. Handjob and idle have no
completion voice bindings.

See [SceneZOI voice authoring](https://github.com/acepleiades/SceneZOI/blob/main/docs/voices.md)
for the schema and ownership rules. Native import and audible playback of this
muted reference have not been tested.
