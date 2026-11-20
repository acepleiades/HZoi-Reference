# Working on HZoi Reference

Read the [README](README.md) and [setup and checks](docs/reference-assets.md).
This is the public authoring edition of HZoi. Keep it separate from the private
HZoi project and the installed player pack. Prefer the framework's public
contracts and tests when checking SceneZOI behavior.

- Preserve credits, the separate third-party mesh license and the absence of a
  repository-wide license.
- Keep original recordings and original SoundWave packages out of the checkout,
  generated output and Git history. The source WAVs are silence. Import only
  from those WAVs, and keep generated SoundWaves out of Git.
- Keep original animation packages and authoring sources out of the checkout,
  generated output and Git history. The 22 AnimSequences are freshly generated
  skeleton-reference-pose placeholders with no motion tracks, curves or notifies.
  Regenerate only through `tools/generate_animation_placeholders.py` in a separate
  ModKit project. Never copy or reimport production animation packages here.
- Keep one scene per JSON file under `packs/hzoi/scenes/`. HZoi contributes
  JSON and assets. Runtime logic belongs in SceneZOI.
- Run `python tools/check_reference.py` before sharing changes. Use
  `tools/build.py` for declaration changes and
  [the reference tests](docs/reference-assets.md#run-the-reference-checks)
  against SceneZOI 1.3.9 or newer.

Preserve working changes. Commit, push, publish or install only when asked.
