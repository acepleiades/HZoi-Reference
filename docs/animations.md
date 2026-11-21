# HZoi animation inventory

The reference includes 34 rest-pose AnimSequence placeholders at HZoi's
animation paths. They use the same skeletons, frame rates and durations as
the player pack, but contain no bone animation tracks, curves or notifies.
Unreal holds the skeleton's reference pose throughout each placeholder.
The original motion and FBX sources are not included.

In the scene declarations, F and M tracks target the characters. MA tracks
target the attached mesh independently on the same scene clock. The table
shows the paths and timing retained for those examples, not playable HZoi motion.

| Source stem | Tracks | Duration |
| --- | --- | --- |
| `HZOI_Standing_idle` | F, M, MA | 3 s |
| `HZOI_Standing_hand_job` | F, M, MA | 10 s |
| `HZOI_Male_standing_female_kneeling_fellatio` | F, M, MA | 10 s |
| `HZOI_Standing_rear_sex` | F, M, MA | 10 s |
| `HZoi_bed_idle` | MA | 4 s |
| `HZoi_bed_fellatio` | F, M, MA | 10 s |
| `HZoi_bed_female_mounted_sex_kissing` | F, M, MA | 10 s |
| `HZoi_bed_handjob` | F, M, MA | 10 s |
| `HZoi_sofa_idle` | F, M, MA | 4 s |
| `HZoi_sofa_handjob` | F, M, MA | 10 s |
| `HZoi_sofa_fellatio` | F, M, MA | 10 s |
| `HZoi_sofa_rear_sex` | F, M, MA | 10 s |

The [import plan](../imports.json) maps source filenames to the native
object paths used by the scene JSON. The
[animation inventory](../animation-inventory.json) gives the original
timing, frame ranges, and bone data. The
[placeholder manifest](../animation-placeholders.json) records the actual
reference skeleton and timing for each replacement. The
[native validation report](../animation-placeholder-validation.json) records
the verified empty animation data and hashes of the generated packages.
These inventories can guide exports from your own animation rig.

The HZoi bed idle nodes reuse the framework's neutral bed body tracks.
The single-bed and queen-bed branches share compatible HZoi animation assets.
The AAL scenes reference a separate library supplied by the player.
The sofa branch uses `sofa.pair` and a 44 cm authored support plane. Its
activity tracks contain one-second cycles at 60 fps, with the movement peak
at frame 30 of each cycle. The full clip lasts ten seconds; it is not one
ten-second movement cycle.
[Placement and optional-track examples](authoring-walkthrough.md)

Use the [placeholder generation steps](reference-assets.md#regenerate-the-animation-placeholders)
to recreate these assets in a separate ModKit project. For motion, contact,
attachment alignment and procedural effects, test with your own clips or
the HZoi player pack. A successful placeholder load does not validate those details.
