# HZoi expression sets

Read the [expression definitions](../packs/hzoi/expressions/) when you want to
add a face to your own scene. Each scene selects a context for a role. SceneZOI
looks it up in the Zoi's chosen set. A set can use the game's native clips.

| Set | Appearance body | Idle examples | Pleasure examples |
| --- | --- | --- | --- |
| Pleasure face (default) | Female | Calm, Touched | Sensual, Enchanting, Calm, Touched |
| Downer | Female | Normal, Bored | Bored, Tired, Preoccupied, Immersed |
| Grinning face | Female | Confident, Joyful | Confident, Giggling, Funny, Joyful |
| Troubled face | Female | Preoccupied, Uneasy | Embarassed, Uneasy, Nervous, Worried |
| Confident (default) | Male | Confident, Joyful | Confident, Joyful, Calm |

The native identifier is spelled `Embarassed`. Translate labels in the
[localization catalog](../packs/hzoi/localization/text.json) and keep native
identifiers as written.

The Kiss context uses stock facial kissing clips at 4.5 seconds. The
[standing/kneeling scene](../packs/hzoi/scenes/03_male_standing_female_kneeling_fellatio.json)
shows how to add a named pose, `scenezoi.open_o`, alongside the Pleasure
context. Use a pose when you want control over a specific part of the face.
[SceneZOI expression authoring](https://github.com/acepleiades/SceneZOI/blob/main/docs/expressions.md)
