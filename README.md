# HZoi Reference

A reference-only HZoi snapshot for authors creating content for
[SceneZOI](https://github.com/acepleiades/SceneZOI). HZoi contains sexual animations
and associated scene data. This is a useful example of authoring adult content
without putting content-pack-specific code into the framework.

The private development repository and player release are separate. This copy
contains no previous Git history and no original proprietary audio. It is not a
ready-to-install player release.

## What you can study

- [One scene per JSON file](packs/hzoi/scenes/): roles, synchronized body and
  attachment tracks, navigation, outfits, gaze, expressions, voices and SFX.
- [The pack manifest](packs/hzoi.json): automatic scene collection, shared sound
  sets and a navigation extension into SceneZOI's neutral hub.
- [Tags and actions](packs/hzoi/scenes/04_standing_rear.json): scene/role metadata,
  directed actions and actor/target/performer assignments.
- [Scene tasks](packs/hzoi/tasks/excitement.json): progress, completion sounds,
  voice responses and procedural responses. See [task notes](docs/scene-tasks.md).
- [Expression sets](packs/hzoi/expressions/) and [voice declarations](packs/hzoi/voices/):
  optional libraries supplied by a content pack, not hardcoded framework defaults.
- [Coverage, body and material profiles](packs/hzoi/profiles/): conditional male
  anatomy activation, retained attachments and declared body-region compatibility.
- [Localization](packs/hzoi/localization/text.json): 15-language display labels
  through the same native declaration transport.
- Owned native animation, mesh, skeleton, material and texture assets under
  [the ModKit source overlay](modkit/HZoi_660649D8/Content/).

The four authored standing scenes are idle, handjob, male-standing/female-kneeling
fellatio and rear sex. HZoi also supplies an attachment animation for the neutral
bed hubs owned by SceneZOI. See [the animation inventory](docs/animations.md).

## Audio is muted

**All 702 included audio files are silent replacements because the original
recordings are proprietary.** They retain the original asset names, frame counts,
channels, sample rates and durations, so the declarations still demonstrate clip
selection, spatial playback, sequencing and completion responses.

Silent PCM WAVs live under
`modkit/HZoi_660649D8/SourceAssets/HZoi/Audio/`.
[audio-inventory.json](audio-inventory.json) records their replacement hashes.
Original recordings and original SoundWave `.uasset` packages are not included.
The [audio import tool](tools/import_audio.py) can generate fresh SoundWave assets
from these silent inputs; it verifies silence before importing and refuses to
reuse pre-existing audio packages. Playback volume settings are unchanged—the
audio samples themselves are silent. See [asset setup](docs/reference-assets.md).

## Framework and content boundaries

SceneZOI owns playback, placement, participants, outfits, expressions, gaze,
audio engines, tasks, transitions, furniture and cleanup. HZoi contributes inert
JSON and assets; its installed package contains no executable code. The Python
tools here are developer commands. A gameplay add-on would use SceneZOI's public
API separately. HZoi Gameplay is not included.

SceneZOI works independently of this pack. Authors can study these patterns while
using their own scene IDs, assets, content and permissions.

## Use the anatomy mesh in your own animation pack

The separate [anatomy authoring kit and walkthrough](docs/standalone-anatomy.md)
show how to bring the same mesh into your own ModKit project. The kit includes
Blender rigs, importable assets and a SceneZOI JSON example. Your finished pack
owns its mesh and animation tracks and needs only SceneZOI as a mod dependency.

## Body-region profile

The current example uses body-profile schema 2, requiring the generic section
support in the matching SceneZOI source. It declares section/coverage bit 17 and
the pack-owned patch resources. Body mesh/material names are not allowlisted:
stock-compatible replacements preserving that mapping are handled automatically.
Moving the region or changing skin/skeleton conventions requires separate work.
See SceneZOI's current body-profile contract when adapting this example.

## Developer checks

Clone the public SceneZOI repository beside this checkout, or pass `--framework`:

```powershell
python tools/check_reference.py
python tools/build.py --framework "C:/Path/To/SceneZOI"
python tools/test.py --framework "C:/Path/To/SceneZOI" --modkit-root "C:/Path/To/inZOIModKit"
```

The JSON build stages 34 HZoi declarations. It does not import assets or install
anything. Native assets and silent audio setup are described in
[reference-assets.md](docs/reference-assets.md). The original Maya/FBX production
sources are not included; the thirteen imported animation assets are included.
Historical FBX hashes describe provenance, not files required to read the JSON.

This overlay retains HZoi's existing native package ID and scene IDs so its
references remain readable. Do not register it alongside another project with
the same ID or overwrite the original HZoi working project/player installation.
Use a separate working environment when examining the full native example.

## Rights and attribution

**No repository-wide license is provided. This repository is for reference only.**
Its availability does not grant a general right to redistribute or relicense the
included animations, meshes, textures, audio-related metadata or developer files.
Third-party material remains subject to its own applicable license.

**Genital mesh attribution:** “Free Blender Model - The Vagrant by Ryan Reos”
subject to its own license.

See [CREDITS.txt](CREDITS.txt) for attribution. The original proprietary audio is
absent; its source credits are retained for context. SceneZOI's GPLv3 license is
separate and does not license this repository or its assets.

[validation.json](validation.json) records what was checked for this reference.
This snapshot has not been installed or visually/audibly tested as a player mod.
