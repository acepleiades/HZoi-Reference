"""Generate reference-pose animation placeholders; never import production FBX."""
import os
import runpy
from pathlib import Path

if os.environ.get('SCENEZOI_EXPORT_DIR') or os.environ.get('SCENEZOI_REIMPORT_SOURCES'):
    raise ValueError('HZoi Reference does not import original FBX motion. Use generate_animation_placeholders.py in a separate project.')

runpy.run_path(str(Path(__file__).with_name('generate_animation_placeholders.py')), run_name='__main__')
