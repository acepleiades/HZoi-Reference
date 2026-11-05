"""Run in Unreal Python; imports HZoi's 13 tracks, never the framework copies.
Set SCENEZOI_REPO when the framework checkout is not the sibling SceneZOI.
SCENEZOI_EXPORT_DIR, SCENEZOI_IMPORT_REPORT and optional SCENEZOI_REIMPORT_SOURCES
retain the existing production import workflow. This script never ships in game.
"""
import json,os,runpy
from pathlib import Path
root=Path(__file__).resolve().parents[1]
framework=Path(os.environ.get('SCENEZOI_REPO',str(root.parent/'SceneZOI')))
os.environ['SCENEZOI_SOURCE_ROOT']=str(root)
os.environ['SCENEZOI_SKELETONS']=json.dumps({'body':'/Game/Characters/Skeletons/SK_Base','attachment':'/HZoi_660649D8/Attachments/HZoi_MaleAnatomy_Skeleton'})
runpy.run_path(str(framework/'tools/import_animations.py'),run_name='__main__')
