import re
from pathlib import Path
r=Path(__file__).resolve().parents[1]
names=set(re.findall(r'BIND\((SDL_ShaderCross_\w+)\)',(r/'src/libraries/generated/shadercross_functions.inc').read_text()))
assert len(names)==15
calls=(r/'tests/shadercross_native.cpp').read_text()
assert all(re.search(r'\b'+n+r'\s*\(',calls) for n in names)
print('15/15 raw APIs have native execution sites; DXBC conditional on runtime availability.')
