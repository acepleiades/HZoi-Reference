"""Create fresh rest-pose AnimSequences; never load or edit original motion assets.

Run with ModKit's UnrealEditor-Cmd Python commandlet in a disposable project.
HZOI_REFERENCE_PROJECT must name that project's isolated HZoi_660649D8 plugin.
HZOI_REFERENCE_ANIMATION_REPORT selects the native validation report output.
"""
import hashlib
import json
import os
import sys
from pathlib import Path

import unreal

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = 'HZoi_660649D8'


def inspect(asset, entry):
    model = asset.get_editor_property('controller').get_model_interface()
    assert model is not None, 'Missing animation data model'
    rate = model.get_frame_rate()
    counts = {
        'bone_track_count': model.get_num_bone_tracks(),
        'curve_count': model.get_number_of_float_curves() + model.get_number_of_transform_curves(),
        'notify_count': len(unreal.AnimationLibrary.get_animation_notify_events(asset)),
    }
    assert all(value == 0 for value in counts.values()), 'Motion, curve or notify data found'
    assert asset.get_editor_property('skeleton').get_path_name() == entry['skeleton']
    assert rate.numerator == entry['fps'] and rate.denominator == 1
    assert model.get_number_of_frames() == entry['number_of_frames']
    assert abs(asset.get_editor_property('sequence_length') - entry['duration_seconds']) < 0.0001
    return dict(entry, **counts)


def main():
    project = Path(os.environ['HZOI_REFERENCE_PROJECT']).resolve()
    native_host = Path(unreal.Paths.convert_relative_path_to_full(unreal.Paths.project_dir())).resolve()
    assert project == native_host / 'Mods' / PLUGIN, 'Use the explicitly selected isolated plugin only'
    assert project != ROOT / 'modkit' / PLUGIN, 'Never generate into the reference source checkout'
    assert not (project / 'Content/Audio').exists(), 'Use a separate clean reference project'
    report_path = Path(os.environ['HZOI_REFERENCE_ANIMATION_REPORT']).resolve()
    plan = json.loads((ROOT / 'animation-placeholders.json').read_text(encoding='utf-8'))
    sys.path.insert(0, str(ROOT / 'tools'))
    from reference_animations import validate_manifest
    imports = json.loads((ROOT / 'imports.json').read_text(encoding='utf-8'))
    inventory = json.loads((ROOT / 'animation-inventory.json').read_text(encoding='utf-8'))
    # Every declared import needs one fresh, correctly timed placeholder; additions
    # are checked against the current source inventory, not a frozen asset count.
    validate_manifest(plan, imports, inventory)
    assets = []
    report = {'success': False, 'pose': plan['pose'], 'assets': assets}
    try:
        tools = unreal.AssetToolsHelpers.get_asset_tools()
        for entry in plan['assets']:
            assert entry['asset'].startswith('Animations/') and '..' not in Path(entry['asset']).parts
            package, name = entry['object_path'].split('.')
            assert package == '/' + PLUGIN + '/' + entry['asset'].removesuffix('.uasset')
            assert name == Path(entry['asset']).stem
            filename = project / 'Content' / entry['asset']
            if filename.exists():
                # Only an already-verified empty placeholder can be reused. Never
                # turn a production clip into a stub by resaving its old package.
                asset = unreal.load_asset(entry['object_path'])
                assert isinstance(asset, unreal.AnimSequence)
                assert unreal.EditorAssetLibrary.get_metadata_tag(asset, 'HZoiReferencePose') == 'skeleton_reference_pose', 'Existing destination is not a generated placeholder'
                result = inspect(asset, entry)
            else:
                skeleton = unreal.load_asset(entry['skeleton'])
                assert isinstance(skeleton, unreal.Skeleton), 'Required reference skeleton missing'
                factory = unreal.AnimSequenceFactory()
                factory.set_editor_property('target_skeleton', skeleton)
                asset = tools.create_asset(name, package.rsplit('/', 1)[0], unreal.AnimSequence, factory)
                assert isinstance(asset, unreal.AnimSequence), 'Could not create fresh animation'
                controller = asset.get_editor_property('controller')
                controller.open_bracket('Create reference-pose placeholder', False)
                controller.set_frame_rate(unreal.FrameRate(entry['fps'], 1), False)
                controller.set_number_of_frames(unreal.FrameNumber(entry['number_of_frames']), False)
                controller.close_bracket(False)
                unreal.EditorAssetLibrary.set_metadata_tag(asset, 'HZoiReferencePose', 'skeleton_reference_pose')
                result = inspect(asset, entry)
                assert unreal.EditorAssetLibrary.save_loaded_asset(asset, False), 'Could not save placeholder'
            assert filename.is_file(), 'Asset was not saved inside the selected plugin'
            result['sha256'] = hashlib.sha256(filename.read_bytes()).hexdigest()
            assets.append(result)
            report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        report['success'] = True
        report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    except Exception as exc:
        report['error'] = str(exc)
        report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        raise


if __name__ == '__main__':
    main()
