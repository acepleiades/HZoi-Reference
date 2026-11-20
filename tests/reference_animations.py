"""Publication guards for neutral animation data, paths, timing and native proof."""
import copy
import hashlib
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from reference_animations import POSE, SKELETONS, validate_manifest, validate_native_report


class ReferenceAnimationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name)
        self.path = 'Animations/Example_F.uasset'
        asset = self.project / 'Content' / self.path
        asset.parent.mkdir(parents=True)
        asset.write_bytes(b'package verified by the native placeholder generator')
        self.entry = {'asset': self.path, 'object_path': '/HZoi_660649D8/Animations/Example_F.Example_F', 'skeleton': SKELETONS['body'],
                      'duration_seconds': 3.0, 'fps': 60, 'number_of_frames': 180}
        self.manifest = {'schema_version': 1, 'pose': POSE, 'assets': [self.entry]}
        self.imports = [{'source': 'Example_F.fbx',
                         'destination': '/HZoi_660649D8/Animations/Example_F.Example_F', 'skeleton': 'body'}]
        self.inventory = [{'filename': 'Example_F.fbx', 'takes': [{'duration_seconds': 3.0}]}]
        result = {**self.entry, 'sha256': hashlib.sha256(asset.read_bytes()).hexdigest(),
                  'bone_track_count': 0, 'curve_count': 0, 'notify_count': 0}
        self.report = {'success': True, 'pose': POSE, 'assets': [result]}

    def entries(self):
        return validate_manifest(self.manifest, self.imports, self.inventory)

    def test_verified_rest_pose_package(self):
        self.assertEqual(validate_native_report(self.entries(), self.report, self.project), 1)

    def test_changed_package_requires_native_verification_again(self):
        (self.project / 'Content' / self.path).write_bytes(b'replaced with an unverified animation package')
        with self.assertRaisesRegex(ValueError, 'differs from native validation'):
            validate_native_report(self.entries(), self.report, self.project)

    def test_motion_curves_notifies_and_missing_evidence_rejected(self):
        for key in ('bone_track_count', 'curve_count', 'notify_count'):
            for value in (1, None, False):
                with self.subTest(key=key, value=value):
                    report = copy.deepcopy(self.report)
                    report['assets'][0][key] = value
                    with self.assertRaisesRegex(ValueError, 'contains animation data'):
                        validate_native_report(self.entries(), report, self.project)

    def test_failed_native_generation_is_not_publication_proof(self):
        self.report['success'] = False
        with self.assertRaisesRegex(ValueError, 'successful native'):
            validate_native_report(self.entries(), self.report, self.project)

    def test_paths_cannot_escape_animation_folder(self):
        for path in ('../outside.uasset', '/Animations/Example.uasset', 'Content/Animations/Example.uasset', 'Animations/../outside.uasset'):
            self.entry['asset'] = path
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, 'inside Content/Animations'):
                self.entries()

    def test_wrong_skeleton_and_original_timing_rejected(self):
        self.entry['skeleton'] = SKELETONS['attachment']
        with self.assertRaisesRegex(ValueError, 'skeleton differs'):
            self.entries()
        self.entry['skeleton'] = SKELETONS['body']
        self.entry['duration_seconds'], self.entry['number_of_frames'] = 4, 240
        with self.assertRaisesRegex(ValueError, 'duration differs'):
            self.entries()

    def test_missing_and_duplicate_assets_rejected(self):
        self.manifest['assets'] = []
        with self.assertRaisesRegex(ValueError, 'Missing animation placeholder'):
            self.entries()
        self.manifest['assets'] = [self.entry, self.entry]
        with self.assertRaisesRegex(ValueError, 'Duplicate placeholder'):
            self.entries()

    def test_fbx_import_entrypoint_refuses_production_source_environment(self):
        env = dict(os.environ, SCENEZOI_EXPORT_DIR='C:/NoOriginalMotionAllowed')
        process = subprocess.run([sys.executable, str(ROOT / 'tools/import_animations.py')],
                                 env=env, text=True, capture_output=True)
        self.assertNotEqual(process.returncode, 0)
        self.assertIn('does not import original FBX motion', process.stderr)


if __name__ == '__main__':
    unittest.main()
