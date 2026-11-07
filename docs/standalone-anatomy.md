# Use the HZoi anatomy mesh with SceneZOI

Download **HZoi_MaleAnatomy_v1.2.zip** from the
[public Blender rigs post](https://www.patreon.com/skyrimaceanimations/posts/inzoi-blender-172792014).
The ZIP contains editable ModKit assets, the male and female Blender rigs,
both exporters, source files and a JSON template. Start with the ZIP's
`README.md` for the import settings and step-by-step instructions.

## Build in your own ModKit project

1. Create your own mod. Stage the ZIP's `Content/HZoiMaleAnatomy` folder under
   the base ModKit project's Content, then move the entire folder into your
   mod's Content in the editor. Save it and verify the skeletal mesh, skeleton,
   materials, textures and stock coverage patch resolve. Use **Copy Reference**
   for your mod's object paths.
2. Export each Zoi and the anatomy as separate FBX tracks with the same frame
   range and rate. Import the Zoi tracks against `SK_Base` and the anatomy track
   against your mod's `HZoi_MaleAnatomy_Skeleton`. The anatomy exporter holds
   the pelvis fixed so SceneZOI can bind it to the Zoi's animated pelvis.
3. Adapt the ZIP's `Example/packs` files. Replace the sample IDs and paths with
   your own. The example attaches only in its scene and registers a
   `body_profile` and a `material_profile`. Together they drive clothing
   coverage, the stock region patch and appearance matching. Set the scene's
   duration and fps from the imported tracks.
4. Stage the JSON with the
   [SceneZOI catalog builder](https://github.com/acepleiades/SceneZOI/blob/main/docs/authoring.md#files-and-native-project).
   Declare `SceneZOI_93C44199` in your native manifest's `dependencies` and
   filter the package to your own inventory. Use your mod's paths for the
   attachment and clips. The authoring ZIP and HZoi are unnecessary at runtime.
5. Test with HZoi disabled. Check entry from the standing hub, playback,
   covering clothing, skin and hair matching, navigation and Exit restoration.
   Test stock first, then any body replacers you intend to support.

## Compare with HZoi's profiles

HZoi uses a pack-wide [coverage attachment](../packs/hzoi/profiles/region_attachment.json)
with per-scene animation mappings, including framework hubs. The ZIP uses a
scene-local attachment to scope it to the new pack's example scene. SceneZOI
currently allows one replacement region owner per participant. Enabling HZoi
alongside another replacement can overlap its global coverage rule.

The [body profile](../packs/hzoi/profiles/body_layout.json) shows schema 2 with
section and coverage bit 17. The stock patch's material slot is
`shader_body_shader18`. The [material profile](../packs/hzoi/profiles/skin_hair.json)
maps the source body and hair appearance to `Penis_001` and `Pubes_001`.
Keep those names when using the supplied assets. A body replacer needs to
preserve the section and coverage convention to use the same profile.

**Genital mesh attribution:** “Free Blender Model - The Vagrant by Ryan Reos”.
The original asset is subject to its own license. See the
[reference repository's rights and attribution](../README.md#rights-and-attribution)
and the ZIP's `CREDITS.md`.
