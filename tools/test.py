"""Run framework regressions and HZoi's external content integration tests."""
import argparse,subprocess,sys
from pathlib import Path
from _framework import framework
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--framework',type=Path);p.add_argument('--modkit-root',type=Path,required=True);a=p.parse_args()
subprocess.run([sys.executable,str(root/'tools/check_reference.py')],check=True)
subprocess.run([sys.executable,str(root/'tests/reference_audio.py')],check=True)
subprocess.run([sys.executable,str(framework(a.framework)/'tools/test.py'),'--modkit-root',str(a.modkit_root),'--content-root',str(root)],check=True)
