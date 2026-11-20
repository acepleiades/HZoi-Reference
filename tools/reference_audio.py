"""Checks shared by reference validation and Unreal's silent audio importer."""
import hashlib
import wave
from pathlib import Path


def validate_silent_source(project, entry):
    project = Path(project).resolve()
    path = (project / entry['source']).resolve()
    if not path.is_relative_to(project / 'SourceAssets/HZoi/Audio') or path.suffix.lower() != '.wav':
        raise ValueError('Silent source must stay inside SourceAssets/HZoi/Audio')
    if path.stat().st_size != entry['bytes']:
        raise ValueError('Silent WAV size differs from inventory: ' + entry['source'])
    with path.open('rb') as stream:
        digest = hashlib.sha256()
        for block in iter(lambda: stream.read(1024 * 1024), b''): digest.update(block)
    if digest.hexdigest() != entry['sha256']:
        raise ValueError('Silent WAV hash differs from inventory: ' + entry['source'])
    with wave.open(str(path), 'rb') as audio:
        expected = (entry['channels'], entry['source_bits'] // 8,
                    entry['sample_rate'], entry['frames'])
        actual = (audio.getnchannels(), audio.getsampwidth(),
                  audio.getframerate(), audio.getnframes())
        if actual != expected or audio.getcomptype() != 'NONE':
            raise ValueError('Silent WAV format/timing differs from inventory: ' + entry['source'])
        if abs(entry['duration_seconds'] - entry['frames'] / entry['sample_rate']) > .000001:
            raise ValueError('Silent WAV duration differs from inventory: ' + entry['source'])
        silence = 128 if audio.getsampwidth() == 1 else 0
        while data := audio.readframes(65536):
            if data.count(silence) != len(data):
                raise ValueError('Non-silent audio sample: ' + entry['source'])
    return path


def validate_inventory(inventory, project):
    if not (inventory.get('reference_only') is True
            and inventory.get('audio_muted') is True
            and inventory.get('original_sources_preserved') is False):
        raise ValueError('Expected an explicitly muted reference inventory')
    sources, assets = set(), set()
    for entry in inventory['assets']:
        if entry['source'] in sources or entry['asset'] in assets:
            raise ValueError('Duplicate silent source or SoundWave path')
        sources.add(entry['source']); assets.add(entry['asset'])
        if not entry['asset'].startswith('/HZoi_660649D8/Audio/'):
            raise ValueError('Unexpected SoundWave owner')
        validate_silent_source(project, entry)
    if not assets:
        raise ValueError('Missing silent audio inventory')
    return len(assets)
