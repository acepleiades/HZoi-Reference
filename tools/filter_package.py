"""Filter HZoi's native package and include its human-readable audio credits."""
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
credits=root/'CREDITS.txt'
if not credits.is_file():raise FileNotFoundError('HZoi audio credits must be present before packaging')
subprocess.run([sys.executable,str(framework(a.framework)/'tools/filter_package.py'),str(a.package),str(a.output),
                '--modkit-root',str(a.modkit_root),*rest,'--plugin','HZoi_660649D8','--inventory',str(root/'asset-inventory.json')],check=True)
# Distribution documentation lives beside the manifest; it is not a native asset,
# data declaration, UI resource, or executable content-pack module.
shutil.copy2(credits,a.output/'CREDITS.txt')
assert (a.output/'CREDITS.txt').read_bytes()==credits.read_bytes()
print('Included audio attribution: CREDITS.txt')
