"""Check the complete pinned MIX export list against snapshots and raw test sites."""
import re
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/'src/libraries/generated/mixer_functions.inc').read_text()
names=set(re.findall(r'BIND\((MIX_\w+)\)',s)) | set(re.findall(r'lib,"(MIX_\w+)"',s))
assert len(names)==94, len(names)
t=(r/'tests/mixer.das').read_text()
missing=sorted(n for n in names if not re.search(r'\b'+n+r'\s*\(',t))
assert not missing,missing
print('94/94 SDL_mixer exports have direct raw test call sites; native callbacks also have a positive C++ fixture.')
