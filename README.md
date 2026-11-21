# HZoi Reference

**Looking for the mod?** [Download the free HZoi player ZIP](https://www.patreon.com/skyrimaceanimations/posts/scenezoi-hzoi-174452155). [Get SceneZOI](https://acepleiades.github.io/SceneZOI/).

This is HZoi's authoring edition. Use a SceneZOI build with sofa furniture
support. It contains all 18 standing, bed and sofa scene definitions, the supporting pack data,
34 rest-pose animation placeholders, the 10 supporting ModKit assets, and
silent replacements for all 702 proprietary audio sources. The original
animation motion and recordings are not included.

## Learn from the pack

- Follow the [authoring walkthrough](docs/authoring-walkthrough.md) from a
  working loop to furniture, character voices, and task completion. It
  explains why each feature is used and what to test in your own pack.
- Open the [pack manifest](packs/hzoi.json) and [scene files](packs/hzoi/scenes/).
  Each scene has its own file. The manifest adds paths from SceneZOI’s
  standing, single-bed, queen-bed and sofa hubs.
- Use the [queen-bed hub](packs/hzoi/scenes/05_queen_bed_idle.json) for furniture
  and the [optional queen-bed scene](packs/hzoi/scenes/09_queen_bed_aal_frontal.json)
  for conditional animation tracks. That scene references Ace Animations
  Library (AAL), a separate library distributed independently.
- Compare the [sofa idle](packs/hzoi/scenes/10_sofa_idle.json) and
  [sofa activity](packs/hzoi/scenes/13_sofa_rear.json) for a 44 cm authored
  support plane, role-specific gaze, and two participants performing the same action.
- For more detail, see [voices](docs/voices.md), [expressions](docs/expressions.md),
  [shared scene tasks and definition precedence](docs/scene-tasks.md), and the
  [animation inventory](docs/animations.md).

For your own pack’s starting files and schema, use the
[SceneZOI authoring guide](https://github.com/acepleiades/SceneZOI/blob/main/docs/authoring.md).
HZoi supplies data and media. SceneZOI handles playback, effects, and cleanup.

## Build or inspect the example

You can read the JSON directly. Follow the
[setup and checks](docs/reference-assets.md) to build or open the assets in
ModKit. Use a separate project environment because the reference uses the
same native ID as the player pack. The WAV files keep the original formats
and durations. The importer builds fresh SoundWaves from those silent files.
The animation placeholders keep the original paths, skeletons, frame rates,
and durations, but hold the skeleton's reference pose throughout. They let
you inspect declarations and test asset loading; use your own animations or
the player pack to review motion and contact.

## Rights and attribution

The separately distributed original HZoi motion has an
[animation-only license](HZOI-ANIMATION-LICENSE.txt) for SceneZOI and genuine
GPL-compliant forks. Its [rights inventory](ANIMATION-RIGHTS.json) preserves
existing GPL grants and keeps third-party assets separate. Read the
[reuse guide](docs/animation-rights.md). The rest-pose placeholders in this
repository contain none of that motion and are outside those restrictions.

This repository has no repository-wide license. For your own mod, use assets
you made or have permission to distribute. The framework is GPL-licensed in
its own repository. The anatomy mesh is credited to
**Free Blender Model - The Vagrant by Ryan Reos** and remains subject to its
own license. See [credits](CREDITS.txt).

The original voices and sound effects are proprietary. Obtain a license from
their creators to redistribute them or reference the installed player pack
as a dependency. [Using HZoi resources through a dependency](https://github.com/acepleiades/SceneZOI/blob/main/docs/authoring.md#reuse-hzoi-resources-through-a-dependency)
