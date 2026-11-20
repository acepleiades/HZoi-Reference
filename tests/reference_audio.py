"""Publication guard regressions: silence is sample data, not playback volume."""
import hashlib
import json
import sys
import tempfile
import unittest
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from reference_audio import validate_inventory, validate_silent_source


class SilentAudioTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name)

    def entry(self, bits=16, samples=None):
        source = 'SourceAssets/HZoi/Audio/test.wav'
        path = self.project / source; path.parent.mkdir(parents=True, exist_ok=True)
        samples = samples if samples is not None else (b'\x80' if bits == 8 else b'\x00') * (32 * bits // 8)
        with wave.open(str(path), 'wb') as audio:
            audio.setnchannels(1); audio.setsampwidth(bits // 8)
            audio.setframerate(8000); audio.writeframes(samples)
        return {'source': source, 'asset': '/HZoi_660649D8/Audio/SW_test.SW_test',
                'source_bits': bits, 'channels': 1, 'sample_rate': 8000,
                'frames': 32, 'duration_seconds': 32 / 8000,
                'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}

    def test_valid_silence_and_formats(self):
        for bits in (8, 16, 24, 32):
            validate_silent_source(self.project, self.entry(bits))

    def test_nonzero_sample_rejected_even_with_correct_hash(self):
        entry = self.entry(samples=b'\x01\x00' + b'\x00' * 62)
        with self.assertRaisesRegex(ValueError, 'Non-silent'): validate_silent_source(self.project, entry)

    def test_unsigned_eight_bit_zero_is_not_silence(self):
        with self.assertRaisesRegex(ValueError, 'Non-silent'):
            validate_silent_source(self.project, self.entry(8, b'\x00' * 32))

    def test_format_and_timing_mismatch(self):
        entry = self.entry(); entry['frames'] += 1
        with self.assertRaisesRegex(ValueError, 'format/timing'): validate_silent_source(self.project, entry)

    def test_changed_source_hash(self):
        entry = self.entry(); entry['sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'hash'): validate_silent_source(self.project, entry)

    def test_path_escape(self):
        entry = self.entry(); entry['source'] = '../outside.wav'
        with self.assertRaisesRegex(ValueError, 'inside'): validate_silent_source(self.project, entry)

    def test_private_inventory_and_duplicate_rejected(self):
        entry = self.entry()
        with self.assertRaisesRegex(ValueError, 'muted reference'):
            validate_inventory({'assets': [entry]}, self.project)
        data = {'reference_only': True, 'audio_muted': True, 'original_sources_preserved': False, 'assets': [entry, entry]}
        with self.assertRaisesRegex(ValueError, 'Duplicate'): validate_inventory(data, self.project)


if __name__ == '__main__': unittest.main()
