# Using HZoi animations

HZoi's original animation motion is for SceneZOI and genuine GPL-compliant
forks of SceneZOI. A different framework does not get permission to use that
motion just by reading the same JSON format.

Read [HZoi Original Animation License 1.0](../HZOI-ANIMATION-LICENSE.txt).
[ANIMATION-RIGHTS.json](../ANIMATION-RIGHTS.json) identifies the covered
tracks, the GPL-licensed motion excluded from these restrictions, and the
other materials outside this license. This is a restricted asset license,
not the GPL and not a license for every file in HZoi.

## Use HZoi as a dependency

For a gameplay integration, request playback through SceneZOI's API. For a
content pack, reference assets from the separately installed official HZoi
package. Manual scene selection is also permitted. Independent integration
code and other pack content keep their own applicable licenses.

A qualifying fork must actually derive from SceneZOI and comply with the GPL
requirements applicable to its covered code. Merely supporting the same schema,
using the GPL for an unrelated framework, or changing a program's name does
not make it a SceneZOI fork. GPL obligations depend on the circumstances;
private changes do not automatically have to be published on GitHub.

Use the [official HZoi download](https://www.patreon.com/skyrimaceanimations/posts/hzoi-public-174452155).
Do not copy the covered animations into your own download or publish altered,
retargeted or converted versions without separate written permission. Referencing
the official pack keeps users on one maintained set of animation assets.

Personal backups and private adjustments for authorized SceneZOI use are
permitted, including inspecting and previewing the motion in an animation
editor to prepare that use. This is not permission to use the animations in
a separate replacement framework, another game or an animation library.

## Keep the existing permissions separate

- **Standing body idles:** the female and male standing idle motion also
  distributed with SceneZOI remains under its existing GPL-3.0-only grants,
  including identical HZoi copies and earlier covered versions. The two entries
  in `excluded_animations` map those HZoi assets to their SceneZOI counterparts.
- **Sofa body idles:** the new female and male sofa idle motion is granted
  under GPL-3.0-only, including the identical HZoi copies. Those two entries
  are also listed in `excluded_animations`.
- **Framework bed body idles:** SceneZOI's female and male neutral bed tracks
  keep their existing GPL permissions. HZoi references them; they are not among
  its 34 owned animation tracks. The separate [GPL text](../GPL-3.0-only.txt)
  is provided for the GPL-licensed motion, not as a license for the whole pack.
- **Anatomy and other assets:** the Ryan Reos mesh and related third-party
  material, proprietary audio, game/engine references and optional AAL library
  keep their respective terms. [Credits](../CREDITS.txt) identify sources and
  do not grant new permissions to their work.
- **Code and declarations:** SceneZOI and its SDK retain their GPL license.
  The animation license does not license the JSON schema, scene declarations,
  documentation or tools, and does not prohibit independently written software.
- **Reference placeholders:** the rest-pose clips in HZoi Reference contain
  none of the original motion. Matching filenames do not put those placeholders
  under the original-animation restrictions.

No valid earlier grant or statutory right is withdrawn. New notices cannot
revoke permissions already granted for earlier copies. Other materials remain
subject to their own rights; there is no repository-wide license for HZoi.

This reference contains only generated rest poses and silent audio. The license
and inventory here describe the original motion in the separately distributed
player pack; they do not turn these placeholders into original HZoi animations.

## Build the player package

Every filtered player package must carry these files beside `mod_manifest.json`:

- `HZOI-ANIMATION-LICENSE.txt`
- `ANIMATION-RIGHTS.json`
- `GPL-3.0-only.txt`
- `CREDITS.txt`

The packaging checks require a complete, disjoint animation inventory and the
correct source hashes. A new animation must be classified before packaging;
the tool must not silently put a shared GPL or third-party work under the
restricted grant. Keep native asset data and protection metadata unchanged
when adding these distribution notices.
