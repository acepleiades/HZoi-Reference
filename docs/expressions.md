# HZoi expression sets

HZoi supplies five expression families through inert JSON in
[`packs/hzoi/expressions/`](../packs/hzoi/expressions/). SceneZOI owns expression
playback, personality preferences and facial-pose overrides.

| Set | Body | Idle | Pleasure |
| --- | --- | --- | --- |
| Pleasure face (default) | female | Calm, Touched | Sensual, Enchanting, Calm, Touched |
| Downer | female | Normal, Bored | Bored, Tired, Preoccupied, Immersed |
| Grinning face | female | Confident, Joyful | Confident, Giggling, Funny, Joyful |
| Troubled face | female | Preoccupied, Uneasy | Embarassed, Uneasy, Nervous, Worried |
| Confident (default) | male | Confident, Joyful | Confident, Joyful, Calm |

Display labels have translations in [the localization catalog](../packs/hzoi/localization/text.json).
The game spells its expression identifier `Embarassed`.

The Kiss context references the game's female/male facial kissing clips and holds
an explicit 4.5-second sample. Those stock game assets are dependencies, not
redistributed assets. No current body-animation scene is labeled as a kiss just
to exercise this context.

The fellatio scene demonstrates `facial_pose: "scenezoi.open_o"` alongside its
Pleasure expression context. Named facial poses belong to SceneZOI's generic
expression system; they are not HZoi-specific runtime behavior.

See [SceneZOI expressions](https://github.com/acepleiades/SceneZOI/blob/main/docs/expressions.md)
for the reusable authoring contracts. This reference's automated checks do not
constitute a new visual acceptance pass.
