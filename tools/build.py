"""Stage HZoi declarations with SceneZOI's generic authoring tools."""
import argparse,subprocess,sys
from pathlib import Path
from _framework import framework
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--framework',type=Path);p.add_argument('--project',type=Path,default=root/'modkit/HZoi_660649D8');a=p.parse_args()
subprocess.run([sys.executable,str(root/'tools/check_reference.py')],check=True)
subprocess.run([sys.executable,str(framework(a.framework)/'tools/build_catalog.py'),'--packs',str(root/'packs/hzoi.json'),'--project',str(a.project)],check=True)
