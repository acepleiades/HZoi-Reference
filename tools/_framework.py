import os
from pathlib import Path
def framework(value=None):
 root=Path(value or os.environ.get('SCENEZOI_REPO',str(Path(__file__).resolve().parents[2]/'SceneZOI'))).resolve()
 if not(root/'tools/build_catalog.py').is_file():raise RuntimeError('Point --framework or SCENEZOI_REPO to the SceneZOI source repository')
 return root
