# Working with the reference assets

For JSON examples, start with the [pack manifest](../packs/hzoi.json) and the
[scene files](../packs/hzoi/scenes/). You can build a new pack using your own
assets with [SceneZOI's authoring tools](https://github.com/acepleiades/SceneZOI/blob/main/docs/authoring.md).

## Build and test the example

Clone [SceneZOI](https://github.com/acepleiades/SceneZOI) next to this checkout,
or provide its path with `--framework`. On Windows, run from HZoi Reference:

```powershell
python tools/check_reference.py
python tools/build.py --framework "C:/dev/SceneZOI"
```

The first command checks the included rest-pose animation packages against
their native validation report and verifies every audio sample is silent.
The build stages the pack JSON under the ModKit overlay by default.
Use `--project` to choose a separate working project. Neither command needs
native imports.

### Run the reference checks

Use the SceneZOI 1.3.12 source or a compatible newer checkout to verify
the task handoff behavior described in this edition.

```powershell
python tools/test.py --framework "C:/dev/SceneZOI" --modkit-root "C:/Path/To/inZOIModKit"
```

This runs the silence checks, framework regressions, and reference catalog,
scene, voice, and completion-effect checks using ModKit's Lua library. Use
your own media or the player pack to verify animation contact and sound in
game; this reference has no original motion or recordings. Check optional
tracks with and without their separate library installed. The older
full-session fixture is in `tests/legacy/` for historical comparison.

If Git on Windows reports a filename is too long, clone into a shorter path,
such as `C:/dev/HZoi-Reference`. Git for Windows also supports
`git -c core.longpaths=true clone <URL>`.

## Native audio import

Use a separate ModKit-registered project for this example. The native package ID
is `HZoi_660649D8`, the same ID used by the player and production projects.
The overlay includes 22 rest-pose animation placeholders and 10 supporting
native assets. See the [animation inventory](animations.md) for their timing.

1. Copy the overlay's `Content` and `SourceAssets` into the separate working
   project. Preserve the asset paths so the supplied JSON can find them.
2. Start with no `Content/Audio` folder in that working project. The importer
   verifies the WAV buffers and requires fresh SoundWaves to keep recoverable
   copies of the original audio out of the reference.
3. Set the project and report paths below and run the commandlet. It recreates
   the SoundWave paths using PCM audio and maximum sample-rate quality.

```powershell
$modkitRoot = "C:/Path/To/inZOIModKit"
$referenceRoot = (Get-Location).Path
$env:SCENEZOI_MOD_PROJECT = "C:/Path/To/Separate/Mods/HZoi_660649D8"
$env:SCENEZOI_AUDIO_REPORT = "C:/Path/To/Reports/silent-audio.json"

& "$modkitRoot/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" `
  "$modkitRoot/inZOIModKit/inZOIModKit.uproject" `
  -run=pythonscript "-script=$referenceRoot/tools/import_audio.py" -unattended -nop4
```

Keep generated `Content/Audio` local. The checked-in
[audio inventory](../audio-inventory.json) records timing, formats, object paths
and hashes for the silent sources. Run the safety check on the source checkout
before sharing it. For a new pack with its own anatomy attachment, use the
[standalone authoring kit](standalone-anatomy.md).

## Regenerate the animation placeholders

The included AnimSequences are newly generated assets. Their skeleton,
frame rate and duration match the original HZoi tracks, but they have no
bone motion, curves or notifies. Do not copy production animation packages
and erase their visible tracks: old animation data or import metadata may
remain in the package.

Use a separate ModKit project registered as `HZoi_660649D8`, with the
supporting attachment skeleton available at its original path. Start with
no `Content/Animations` folder in that working project. Do not point this
command at the production HZoi project or the installed player pack.

```powershell
$modkitRoot = "C:/Path/To/inZOIModKit"
$referenceRoot = (Get-Location).Path
$env:HZOI_REFERENCE_PROJECT = "C:/Path/To/Separate/Mods/HZoi_660649D8"
$env:HZOI_REFERENCE_ANIMATION_REPORT = "C:/Path/To/Reports/animation-placeholder-validation.json"

& "$modkitRoot/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" `
  "$modkitRoot/inZOIModKit/inZOIModKit.uproject" `
  -run=pythonscript "-script=$referenceRoot/tools/generate_animation_placeholders.py" -unattended -nop4
```

The generator reads [the placeholder manifest](../animation-placeholders.json),
creates fresh AnimSequences, and verifies their skeletons, timing and empty
animation data. It refuses existing motion assets; an already-generated
placeholder is reused only after its marker, timing and empty data are verified. The old
`tools/import_animations.py` entry point uses this same generator; it does
not import production FBX files.

When updating this reference, copy only the newly generated animation
packages and their successful validation report into the checkout, update
`reference-assets.json` to the verified hashes, then run
`python tools/check_reference.py`. Keep the 10 supporting asset hashes
unchanged unless you intentionally update one of those assets. Never copy
FBX, Maya or Blender production sources, original animation packages,
original SoundWaves, or backup archives into this repository or its history.
