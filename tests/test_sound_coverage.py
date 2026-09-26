"""Check the complete pinned MIX export list against snapshots and raw test sites."""
import re
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/'src/libraries/generated/sound_functions.inc').read_text()
names=set(re.findall(r'BIND\((Sound_\w+)\)',s)) | set(re.findall(r'lib,"(Sound_\w+)"',s))
assert len(names)==17, len(names)
t=(r/'tests/sound.das').read_text()
missing=sorted(n for n in names if not re.search(r'\b'+n+r'\s*\(',t))
assert not missing,missing
print('17/17 SDL_sound exports have direct raw test call sites.')
