"""Verify the manifest and native proof for fresh reference-pose AnimSequences."""
import hashlib
import math
from pathlib import Path, PurePosixPath

POSE = 'skeleton_reference_pose'
SKELETONS = {
    'body': '/Game/Characters/Skeletons/SK_Base.SK_Base',
    'attachment': '/HZoi_660649D8/Attachments/HZoi_MaleAnatomy_Skeleton.HZoi_MaleAnatomy_Skeleton',
}


def _asset_path(value):
    if not isinstance(value, str):
        raise ValueError('Placeholder asset path must be text')
    path = PurePosixPath(value)
    if path.is_absolute() or '\\' in value or '..' in path.parts or path.parts[:1] != ('Animations',) or path.suffix != '.uasset':
        raise ValueError('Placeholder asset must stay inside Content/Animations: ' + value)
    return value


def validate_manifest(manifest, imports, original_inventory):
    if manifest.get('schema_version') != 1 or manifest.get('pose') != POSE or not isinstance(manifest.get('assets'), list):
        raise ValueError('Expected skeleton-reference-pose placeholder manifest')
    entries = {}
    for entry in manifest['assets']:
        if not isinstance(entry, dict):
            raise ValueError('Placeholder entry must be an object')
        path = _asset_path(entry.get('asset'))
        if path in entries:
            raise ValueError('Duplicate placeholder asset: ' + path)
        seconds, fps, frames = entry.get('duration_seconds'), entry.get('fps'), entry.get('number_of_frames')
        if not isinstance(seconds, (int, float)) or isinstance(seconds, bool) or not math.isfinite(seconds) or seconds <= 0:
            raise ValueError('Invalid placeholder duration: ' + path)
        if fps != 60 or isinstance(fps, bool) or not isinstance(frames, int) or isinstance(frames, bool) or frames <= 0 or abs(frames - seconds * fps) > .0001:
            raise ValueError('Invalid placeholder frame timing: ' + path)
        if entry.get('skeleton') not in SKELETONS.values():
            raise ValueError('Unexpected placeholder skeleton: ' + path)
        object_path = '/HZoi_660649D8/' + path.removesuffix('.uasset') + '.' + PurePosixPath(path).stem
        if entry.get('object_path') != object_path:
            raise ValueError('Placeholder object path differs from its package: ' + path)
        entries[path] = entry
    original = {entry['filename']: entry for entry in original_inventory}
    expected = {}
    for item in imports:
        package, name = item['destination'].split('.')
        prefix = '/HZoi_660649D8/'
        if not package.startswith(prefix) or package.rsplit('/', 1)[-1] != name:
            raise ValueError('Unexpected reference animation destination')
        path = _asset_path(package[len(prefix):] + '.uasset')
        if path in expected:
            raise ValueError('Duplicate reference animation destination')
        expected[path] = item
        entry = entries.get(path)
        if entry is None:
            raise ValueError('Missing animation placeholder: ' + path)
        if entry['skeleton'] != SKELETONS[item['skeleton']]:
            raise ValueError('Placeholder skeleton differs from import plan: ' + path)
        if abs(entry['duration_seconds'] - original[item['source']]['takes'][0]['duration_seconds']) > .0001:
            raise ValueError('Placeholder duration differs from original timing: ' + path)
    if not entries or set(entries) != set(expected):
        raise ValueError('Placeholder assets differ from the animation import plan')
    return entries


def validate_native_report(manifest_entries, report, project):
    if report.get('success') is not True or report.get('pose') != POSE or not isinstance(report.get('assets'), list):
        raise ValueError('Expected a successful native placeholder validation report')
    results = {}
    for result in report['assets']:
        path = _asset_path(result.get('asset'))
        if path in results:
            raise ValueError('Duplicate native placeholder result: ' + path)
        results[path] = result
    if set(results) != set(manifest_entries):
        raise ValueError('Native placeholder results differ from the manifest')
    project = Path(project).resolve()
    for path, expected in manifest_entries.items():
        result = results[path]
        for key in ('skeleton', 'fps', 'number_of_frames'):
            if result.get(key) != expected[key]:
                raise ValueError('Native placeholder ' + key + ' mismatch: ' + path)
        duration = result.get('duration_seconds')
        if not isinstance(duration, (int, float)) or not math.isfinite(duration) or abs(duration - expected['duration_seconds']) > .0001:
            raise ValueError('Native placeholder duration mismatch: ' + path)
        for key in ('bone_track_count', 'curve_count', 'notify_count'):
            if result.get(key) != 0 or isinstance(result.get(key), bool):
                raise ValueError('Placeholder contains animation data (' + key + '): ' + path)
        file = project / 'Content' / path
        digest = hashlib.sha256(file.read_bytes()).hexdigest()
        if result.get('sha256') != digest:
            raise ValueError('Placeholder package differs from native validation: ' + path)
    return len(results)
