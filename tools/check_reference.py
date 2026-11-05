"""Fail closed if original audio or unexpected payload enters the reference."""
import hashlib
import json
from pathlib import Path
from reference_audio import validate_inventory

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = 'HZoi_660649D8'


def check():
    project = ROOT / 'modkit' / PLUGIN
    audio = json.loads((ROOT / 'audio-inventory.json').read_text(encoding='utf-8'))
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
    assert len(expected_assets) == 23
    actual_assets = {p.relative_to(project / 'Content').as_posix()
                     for p in (project / 'Content').rglob('*.uasset')}
    assert actual_assets == expected_assets, 'Only the 23 non-audio native assets may be present'
    hashes = json.loads((ROOT / 'reference-assets.json').read_text(encoding='utf-8'))
    assert set(hashes) == expected_assets
    for rel, expected in hashes.items():
        assert hashlib.sha256((project / 'Content' / rel).read_bytes()).hexdigest() == expected, 'Native asset changed: ' + rel
    assert not any(p.suffix.lower() in {'.lua', '.js', '.py', '.dll'}
                   for p in project.rglob('*') if p.is_file()), 'Content pack must remain code-free'
    readme = (ROOT / 'README.md').read_text(encoding='utf-8')
    credits = (ROOT / 'CREDITS.txt').read_text(encoding='utf-8')
    assert 'Free Blender Model - The Vagrant by Ryan Reos' in readme and 'Free Blender Model - The Vagrant by Ryan Reos' in credits
    return {'passed': True, 'silent_wavs': count, 'non_audio_native_assets': len(expected_assets),
            'original_soundwave_packages_present': False, 'repository_license_file_present': False}


if __name__ == '__main__':
    print(json.dumps(check(), indent=2))
