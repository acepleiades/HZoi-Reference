"""Filter the reference package and retain scoped notices and credits."""
import argparse,shutil,subprocess,sys
from pathlib import Path
from _framework import framework
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(add_help=False)
p.add_argument('--framework',type=Path)
p.add_argument('package',type=Path)
p.add_argument('output',type=Path)
p.add_argument('--modkit-root',type=Path,required=True)
a,rest=p.parse_known_args()
notices=('CREDITS.txt','HZOI-ANIMATION-LICENSE.txt','ANIMATION-RIGHTS.json','GPL-3.0-only.txt')
for name in notices:
 if not (root/name).is_file():raise FileNotFoundError('Reference distribution notice missing: '+name)
subprocess.run([sys.executable,str(framework(a.framework)/'tools/filter_package.py'),str(a.package),str(a.output),
                '--modkit-root',str(a.modkit_root),*rest,'--plugin','HZoi_660649D8','--inventory',str(root/'asset-inventory.json')],check=True)
# Distribution documentation lives beside the manifest; it is not a native asset,
# data declaration, UI resource, or executable content-pack module.
# These notices describe the separate player motion and preserve prior rights.
# They do not put generated reference-pose clips under that motion license.
for name in notices:
 shutil.copy2(root/name,a.output/name)
 assert (a.output/name).read_bytes()==(root/name).read_bytes()
print('Included scoped original-motion notices, GPL text and CREDITS.txt')
