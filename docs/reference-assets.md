# Reference assets and silent audio

This checkout includes 23 non-audio `.uasset` packages from the
original native project: thirteen animation tracks, the male anatomy mesh and
skeleton, a stock-coverage patch, two materials and five textures. Their bytes
are preserved. References to stock Game/Engine assets are dependencies; those
assets are not redistributed here.

The 702 original SoundWave packages and the original WAVs are omitted. Each
inventory source path instead contains a freshly generated PCM WAV with the same
sample rate, channel count, sample width and frame count, containing only digital
silence. These can be imported to recreate the declared SoundWave paths without
including any recoverable original recording.

## JSON-only study

Use `tools/build.py` to validate and stage the 34 declarations. Native imports are
not required to read scene examples or run isolated data/lifecycle regressions.

## Native audio import

Use a separate native ModKit working environment with this source overlay. The
native package is `HZoi_660649D8`. Do not direct these steps at an original HZoi
project or a player installation. Register a working project through the ModKit's
supported workflow; a repository directory alone does not establish registration.

1. Copy the overlay's `Content`, `SourceAssets` and authoring metadata to that
   separate working project, preserving the declared asset paths.
2. Ensure `Content/Audio` is absent: no previous SoundWave packages may be reused.
3. Set `SCENEZOI_MOD_PROJECT` to that working project's directory and
   `SCENEZOI_AUDIO_REPORT` to a writable JSON report path.
4. Run `tools/import_audio.py` through ModKit's supported Unreal Python commandlet.
   The tool verifies every WAV's complete sample buffer is silent and imports
   fresh assets with the inventory's original object paths, PCM compression and
   MAX sample-rate quality. It refuses existing assets instead of trusting an
   asset that might still contain original audio.

The standard commandlet shape is:

```powershell
$env:SCENEZOI_MOD_PROJECT = "C:/Path/To/Separate/Mods/HZoi_660649D8"
$env:SCENEZOI_AUDIO_REPORT = "C:/Path/To/Reports/silent-audio.json"
& "$modkitRoot/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" `
  "$modkitRoot/inZOIModKit/inZOIModKit.uproject" `
  -run=pythonscript "-script=$referenceRoot/tools/import_audio.py" -unattended -nop4
```

`$modkitRoot` and `$referenceRoot` must point to your installations/checkouts. Run
this only in the separate working environment described above. The reference
preparation did not run this commandlet or register/install a native project.

The inventory continues to describe 725 eventual native asset packages: the 23
included packages and 702 silent SoundWaves generated locally. `Content/Audio`
is ignored in Git to prevent original or cached recording data from being added.
No cooked containers, local caches, production audio backups or private Git
objects belong in this repository. Run `tools/check_reference.py` before sharing.
