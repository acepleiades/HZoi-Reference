"""Import only silent HZoi reference WAVs into fresh SoundWave packages.

SCENEZOI_MOD_PROJECT: existing ModKit mod directory (including SourceAssets/).
SCENEZOI_AUDIO_REPORT: writable JSON report. SCENEZOI_AUDIO_LIMIT optionally
limits a capability check. Existing SoundWave assets are refused before importing.
All input samples are verified silent. Playback uses PCM and MAX sample rate.
"""
import hashlib
import json
import os
from pathlib import Path
import unreal
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from reference_audio import validate_inventory

root=Path(os.environ.get('HZOI_REFERENCE_ROOT',str(Path(__file__).resolve().parents[1])))
project=Path(os.environ['SCENEZOI_MOD_PROJECT']).resolve()
report_path=Path(os.environ['SCENEZOI_AUDIO_REPORT'])
inventory=json.loads((root/'audio-inventory.json').read_text(encoding='utf-8'))
entries=inventory['assets']
limit=int(os.environ.get('SCENEZOI_AUDIO_LIMIT','0'))
if limit:entries=entries[:limit]
report={'ok':False,'in_progress':True,'engine':unreal.SystemLibrary.get_engine_version(),
        'expected':len(entries),'codec':'PCM','sample_rate_quality':'MAX','assets':[]}
def write():report_path.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def verify_and_save(entry,asset,imported):
    assert isinstance(asset,unreal.SoundWave),'Expected a SoundWave: '+entry['asset']
    source=(project/entry['source']).resolve()
    actual_sources=asset.get_editor_property('asset_import_data').extract_filenames()
    assert len(actual_sources)==1 and Path(actual_sources[0]).resolve()==source,'Asset source mismatch: '+entry['asset']
    asset.set_sound_asset_compression_type(unreal.SoundAssetCompressionType.PCM)
    asset.set_editor_property('sample_rate_quality',unreal.SoundwaveSampleRateSettings.MAX)
    asset.set_editor_property('looping',False)
    group=unreal.SoundGroup.SOUNDGROUP_VOICE if entry['category']=='voice' else unreal.SoundGroup.SOUNDGROUP_EFFECTS
    asset.set_editor_property('sound_group',group)
    assert asset.get_sound_asset_compression_type()==unreal.SoundAssetCompressionType.PCM
    assert asset.get_editor_property('sample_rate_quality')==unreal.SoundwaveSampleRateSettings.MAX
    assert asset.get_editor_property('imported_sample_rate')==entry['sample_rate'],'Sample-rate mismatch: '+entry['asset']
    assert asset.get_editor_property('num_channels')==entry['channels'],'Channel mismatch: '+entry['asset']
    duration=float(asset.get_editor_property('duration'))
    assert abs(duration-entry['duration_seconds'])<=max(.0001,2/entry['sample_rate']),'Duration mismatch: '+entry['asset']
    assert unreal.EditorAssetLibrary.save_loaded_asset(asset),'Save failed: '+entry['asset']
    report['assets'].append({'asset':asset.get_path_name(),'category':entry['category'],'source':entry['source'],
        'source_sha256':entry['sha256'],'imported':imported,'compression':str(asset.get_sound_asset_compression_type()),
        'sample_rate':asset.get_editor_property('imported_sample_rate'),'channels':asset.get_editor_property('num_channels'),
        'duration_seconds':duration,'sample_rate_quality':str(asset.get_editor_property('sample_rate_quality'))})
try:
    assert bool(inventory['assets']) and inventory['owner']=='HZoi'
    validate_inventory(inventory,project)
    # Preflight the entire library before the first mutation. A zero-volume or
    # cached original SoundWave can retain recoverable audio and must not be reused.
    for entry in inventory['assets']:
        assert not unreal.EditorAssetLibrary.does_asset_exist(entry['asset'].split('.')[0]),'Use a fresh separate audio destination: '+entry['asset']
    for entry in entries:
        source=(project/entry['source']).resolve()
        assert source.is_relative_to(project/'SourceAssets/HZoi/Audio') and source.suffix.lower()=='.wav'
        assert hashlib.sha256(source.read_bytes()).hexdigest()==entry['sha256'],'Source changed: '+str(source)
        assert entry['asset'].startswith('/HZoi_660649D8/Audio/')
    # Process-local factory default only; no project/Engine config is changed.
    unreal.get_default_object(unreal.SoundWave).set_sound_asset_compression_type(unreal.SoundAssetCompressionType.PCM,False)
    tools=unreal.AssetToolsHelpers.get_asset_tools()
    for start in range(0,len(entries),24):
        batch=entries[start:start+24];tasks=[];new=set()
        for entry in batch:
            package,name=entry['asset'].split('.')
            task=unreal.AssetImportTask();factory=unreal.SoundFactory()
            factory.set_editor_property('auto_create_cue',False)
            task.set_editor_property('filename',str(project/entry['source']))
            task.set_editor_property('destination_path',package.rsplit('/',1)[0])
            task.set_editor_property('destination_name',name)
            task.set_editor_property('automated',True)
            task.set_editor_property('replace_existing',False)
            task.set_editor_property('save',False)
            task.set_editor_property('factory',factory)
            tasks.append(task);new.add(entry['asset'])
        if tasks:tools.import_asset_tasks(tasks)
        for entry in batch:
            asset=unreal.load_asset(entry['asset'])
            verify_and_save(entry,asset,entry['asset']in new)
        write()
        unreal.log('HZoi audio: '+str(len(report['assets']))+'/'+str(len(entries))+' validated and saved as PCM')
    report.update(ok=True,in_progress=False)
    write()
except Exception as error:
    report.update(in_progress=False,error=str(error));write();raise
