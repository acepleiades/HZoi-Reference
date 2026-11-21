"""Check that the public snapshot contains only its inventoried assets and silent WAVs."""
import hashlib
import json
from pathlib import Path
from reference_audio import validate_inventory
from reference_animations import validate_manifest, validate_native_report

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = 'HZoi_660649D8'


def check():
    project = ROOT / 'modkit' / PLUGIN
    audio = json.loads((ROOT / 'audio-inventory.json').read_text(encoding='utf-8'))
    # Muting playback leaves the samples recoverable. Verify the WAV bytes.
    count = validate_inventory(audio, project)
    assert count == 702, 'Reference must retain all 702 declared clips'
    files = [p for p in ROOT.rglob('*') if p.is_file()
             and not ({'.git', '__pycache__'} & set(p.relative_to(ROOT).parts))]
    assert not any(p.name.upper().startswith(('LICENSE', 'COPYING')) for p in files), 'No repository-wide license file is intended'
    forbidden = {'.mp3', '.flac', '.ogg', '.opus', '.aac', '.m4a', '.wma',
                 '.pak', '.ucas', '.utoc', '.zip', '.7z', '.rar', '.dll'}
    assert not any(p.suffix.lower() in forbidden for p in files), 'Unexpected media/archive/cooked payload'
    expected_wavs = {(project / e['source']).resolve() for e in audio['assets']}
    assert {p.resolve() for p in files if p.suffix.lower() == '.wav'} == expected_wavs, 'Unexpected or missing WAV'
    inventory = json.loads((ROOT / 'asset-inventory.json').read_text(encoding='utf-8'))['plugins'][PLUGIN]
    expected_assets = {name for name in inventory if not name.startswith('Audio/')}
    placeholders = json.loads((ROOT / 'animation-placeholders.json').read_text(encoding='utf-8'))
    native_report = json.loads((ROOT / 'animation-placeholder-validation.json').read_text(encoding='utf-8'))
    imports = json.loads((ROOT / 'imports.json').read_text(encoding='utf-8'))
    timing = json.loads((ROOT / 'animation-inventory.json').read_text(encoding='utf-8'))
    animation_assets = validate_manifest(placeholders, imports, timing)
    assert set(animation_assets) == {name for name in expected_assets if name.startswith('Animations/')}, 'Every animation must be a placeholder'
    animation_count = validate_native_report(animation_assets, native_report, project)
    assert not any(p.suffix.lower() in {'.fbx', '.ma', '.mb', '.blend', '.bvh', '.anim', '.hkx'} for p in files), 'Original animation/authoring sources must not be published'
    content = project / 'Content'
    actual_assets = {p.relative_to(content).as_posix()
                     for p in files if p.suffix.lower() == '.uasset'}
    assert actual_assets == expected_assets, 'Only inventoried non-audio native assets may be present'
    hashes = json.loads((ROOT / 'reference-assets.json').read_text(encoding='utf-8'))
    assert set(hashes) == expected_assets
    for rel, expected in hashes.items():
        assert hashlib.sha256((project / 'Content' / rel).read_bytes()).hexdigest() == expected, 'Native asset changed: ' + rel
    assert not any(p.suffix.lower() in {'.lua', '.js', '.py', '.dll'}
                   for p in project.rglob('*') if p.is_file()), 'Content pack must remain code-free'
    for name in ('HZOI-ANIMATION-LICENSE.txt', 'ANIMATION-RIGHTS.json', 'GPL-3.0-only.txt'):
        assert (ROOT / name).is_file(), 'Missing scoped distribution notice: ' + name
    rights = json.loads((ROOT / 'ANIMATION-RIGHTS.json').read_text(encoding='utf-8'))
    assert rights['license_id'] == 'HZoi-Original-Animations-1.0'
    excluded = {entry['source'] for entry in rights['excluded_animations']}
    assert excluded == {'HZOI_Standing_idle_F.fbx', 'HZOI_Standing_idle_M.fbx',
                        'HZoi_sofa_idle_F.fbx', 'HZoi_sofa_idle_M.fbx'}, 'Preserve standing and sofa body idle GPL grants'
    assert all(entry['license'] == 'GPL-3.0-only' for entry in rights['excluded_animations'])
    for entry in rights['covered_animations']:
        rel = entry['asset'].split('.')[0].split('/' + PLUGIN + '/', 1)[1] + '.uasset'
        assert hashes[rel] != entry['editor_asset_sha256'], 'Original motion package present instead of reference pose'
    readme = (ROOT / 'README.md').read_text(encoding='utf-8')
    credits = (ROOT / 'CREDITS.txt').read_text(encoding='utf-8')
    assert 'Free Blender Model - The Vagrant by Ryan Reos' in readme and 'Free Blender Model - The Vagrant by Ryan Reos' in credits
    return {'passed': True, 'silent_wavs': count, 'non_audio_native_assets': len(expected_assets),
            'rest_pose_animation_placeholders': animation_count,
            'supporting_native_assets': len(expected_assets) - animation_count,
            'original_animation_sources_present': False,
            'original_soundwave_packages_present': False, 'repository_wide_license_file_present': False, 'scoped_original_motion_notice_present': True}


if __name__ == '__main__':
    print(json.dumps(check(), indent=2))
