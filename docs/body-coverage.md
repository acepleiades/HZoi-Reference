# Fit male genitals to another body

HZoi attaches its mesh for male genitals separately from the Zoi's body. It hides
body region 17 to remove the body's own male genitals, then shows a skin patch
underneath the attachment. That patch must close the body's cutout in motion as
well as in the reference pose.

Update SceneZOI and HZoi together to use this fitted-patch selection.

The stock coverage patch fits the stock body and Supponpon. ZoiBits keeps the
same region convention but needs a different fit. HZoi selects its fitted patch
through [body_layout.json](../packs/hzoi/profiles/body_layout.json):

```json
{
  "schema_version": 2,
  "id": "hzoi.body_layout",
  "section": 17,
  "coverage_bit": 17,
  "full_coverage_exception": true,
  "patch_mesh": "/HZoi_660649D8/Compatibility/StockCoveragePatch.StockCoveragePatch",
  "patch_mesh_overrides": {
    "/NaturalSkin_B5AE5C0D/Mesh/SKM_Male_Base_NS.SKM_Male_Base_NS": "/HZoi_660649D8/Compatibility/ZoiBitsMaleCoveragePatch.ZoiBitsMaleCoveragePatch"
  },
  "patch_material_slot": "shader_body_shader18",
  "morph": "Body_Muscle"
}
```

## Which patch will SceneZOI use?

SceneZOI reads the Zoi's actual rendered body mesh after unmerging. A full object
path matching a key in `patch_mesh_overrides` selects that patch. Anything else
uses `patch_mesh`, the stock default in this profile. The ZoiBits path starts with
`NaturalSkin`, which is why matching the mod's visible name or folder is unreliable.

This does not install, select or require ZoiBits. It only supplies a fit when that
body is already in use. Clothing and body rebuilds cause SceneZOI to check the
rendered mesh again. Different Zois can use different patches in the same scene.
The anatomy attachment, its selected variant and its animation tracks stay the
same; this choice only changes the skin underneath.

ZoiBits Male v3 and v4 use this same body asset path. The selection does not
depend on a version number: later updates that keep that path also select the
fitted patch. The current fit was checked against v4. A later change to the
cutout or skinning can still require refitting; automatic selection does not
guarantee that every future body shape will fit.

If an exact match names a patch that is missing or cannot load, SceneZOI reports
a preparation failure. It does not silently use the
stock shape instead. Check the observed body and selected patch in the player's
`scenezoi_runtime` diagnostics when troubleshooting.

## I want to support another body

1. Inspect the body with its replacement region hidden. Match a coverage patch
   to the actual cutout. Having the same section number does not mean it has
   the same shape.
2. Match the outer edge's bone weights and supported morph deltas to the body.
   A patch that looks closed while standing can pull away when a leg bends if
   its seam follows different bones or muscle deformation.
3. Import the patch with the profile's section, material-slot and morph layout.
   Every override uses the same `section`, `patch_material_slot` and `morph` as
   the default patch. A body with a different region layout needs its own
   compatible profile, not just another mesh path here.
4. Add the body's exact object path and your patch's object path to
   `patch_mesh_overrides`. Use the path reported by the game or **Copy Reference**
   in ModKit, without the surrounding `SkeletalMesh'...'` wrapper.
5. Test the fit in the poses where it matters: raised knees, spread legs,
   crouching, hip twists and the full animation cycle. Check every rendered LOD
   and the body's available shape settings. Then test undressing, redressing,
   navigation, a body change and Exit. Check the stock fallback too.

## The patch fits, but I can still see its edge

A patch can close every gap and still look like a separate piece under light.
Match how the surface curves away from the body's edge, not just where the edge
vertices meet. A dent or a sudden change in slope can show when the camera moves.

Keep the body's UV seams and separate normal/tangent values at each face corner.
Preserve tangent handedness too: it controls which way the bitangent points.
Do not weld texture charts just because vertices share a 3D position; even
coincident corners can need different shading values.

Preserve those authored normals and tangents during export and import.
Automatically recomputing tangents for the patch can make its normal map react
to light differently from the body, even when its edge positions and UVs match.

First check a neutral grey material with light at a shallow angle to spot dents
or a hard join. Then use the actual skin material, move the camera and light,
and play the animations. Check the join in motion and at every LOD.

The patches belong to the content pack. SceneZOI supplies the selection and
cleanup behavior; it cannot infer a watertight replacement for arbitrary body
geometry. Each body that changes the cutout's shape or deformation needs a fit
that has been checked against that body.

For the framework contract, see
[coverage and material profiles](https://github.com/acepleiades/SceneZOI/blob/main/docs/package-split.md#fit-a-coverage-patch-to-another-body).
For help comparing a new body or collaborating on a shared patch, ask in the
[OStim/SceneZOI Community Discord server](https://discord.gg/RECvhVaRcU).
