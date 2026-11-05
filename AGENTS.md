# HZoi reference repository

This is a separate, audio-muted reference snapshot for SceneZOI content authors.
Read README.md and docs/reference-assets.md before changing it. The private HZoi
checkout, its native ModKit project and installed player packages are separate.
Never synchronize this reference over any of them or import their audio here.

The repository deliberately has no repository-wide license. It is for reference
only. Preserve the genital mesh attribution and its separate third-party license.
Do not add a LICENSE file or imply the framework's GPL covers these assets.

All included WAVs must contain digital silence, with inventory hashes and timing
matching. Original proprietary recordings and original SoundWave packages must
never enter this checkout, generated output, archives or Git history. Do not mute
by setting volume to zero: recoverable audio bytes would remain. Audio packages
must be freshly imported from the supplied silent WAVs; keep them ignored in Git.

HZoi contributes inert JSON and assets. Runtime behavior belongs to SceneZOI.
Developer tools and isolated tests are not installed content-pack scripts.
Scenes remain individual files under packs/hzoi/scenes/. Roles are independent
of body type and controller identity; do not add pack-specific framework code.

Use tools/build.py --framework <SceneZOI checkout> for declaration validation.
Use tools/test.py --framework <SceneZOI checkout> --modkit-root <ModKit root> for
reference-safety checks and the existing content integration regressions.
Run tools/check_reference.py before distributing or committing this reference.
Preserve uncommitted work. Do not commit, push, publish, install or modify a
separate native project unless explicitly requested.
