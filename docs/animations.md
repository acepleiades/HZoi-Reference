# HZoi animation inventory

HZoi owns four standing sets, each with F/M body tracks and an MA attachment track, plus a four-second bed attachment track: 13 animation imports in total. SceneZOI independently owns four neutral body animation imports (standing F/M and bed F/M). Neither repository's import plan includes the other's owned packages.

| Source stem | Tracks | Inclusive frames at 60 fps | Samples | Duration |
| --- | --- | --- | --- | --- |
| HZOI_Standing_idle | F, M, MA | 0–180 | 181 | 3 s |
| HZOI_Standing_hand_job | F, M, MA | 0–600 | 601 | 10 s |
| HZOI_Male_standing_female_kneeling_fellatio | F, M, MA | 0–600 | 601 | 10 s |
| HZOI_Standing_rear_sex | F, M, MA | 0–600 | 601 | 10 s |
| HZoi bed idle MA | MA | 0–240 | 241 | 4 s |

[animation-inventory.json](../animation-inventory.json) records historical FBX filenames, source hashes, take timing and bone data; [imports.json](../imports.json) is the 13-entry HZoi import plan. F/M exports contain 80 body bones and MA seven attachment bones; FBX wrapper/runtime skeleton entries are separate. Source FBX files are not included; all thirteen imported animation assets are included. The 725-package asset inventory describes 23 included native assets and 702 SoundWaves that can be generated from the supplied silent WAVs.

Standing navigation is Standing Idle Hub → HZoi Standing Idle → an authored activity, with returns through HZoi idle to the framework hub. Hubs do not force clothing changes: they preserve current session outfits, including manual edits or earlier removals. Male-only activities remove male clothing; rear activity removes both participants' clothing. Exit restores original session-entry appearance through SceneZOI cleanup.

Exposure-driven attachment activation uses resolved garment coverage and compatibility, including already exposed bodies and manual edits at neutral hubs. Each participant owns their own resources. Retained components and original body snapshots survive navigation, and tracks use the shared participant clock. The bed attachment maps optionally to neutral single/queen hubs; HZoi adds no bed scene. Ground-level bed clips use authored support plane 0 cm; the current framework profiles target 68 cm standard beds and 20 cm futons.

See [reference assets](reference-assets.md) for the native overlay and silent audio setup. Run `tools/build.py` and `tools/test.py` for declarative/content checks. `tools/import_animations.py` illustrates the production import process but requires the original FBX inputs, which are not supplied. Developer tools do not ship in an installed content pack. See [validation.json](../validation.json) for this reference's checks and acceptance limits.
