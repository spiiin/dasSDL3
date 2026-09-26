"""Pinned SDL 3.4 additions have generated declarations and direct script test calls."""
import json
import re
from pathlib import Path
r = Path(__file__).resolve().parents[1]
names = """SDL_CreateAnimatedCursor SDL_GetEventDescription SDL_GetPenDeviceType SDL_GetSystemPageSize
SDL_GetWindowProgressState SDL_GetWindowProgressValue SDL_PutAudioStreamDataNoCopy SDL_PutAudioStreamPlanarData
SDL_SetRelativeMouseTransform SDL_SetWindowFillDocument SDL_SetWindowProgressState SDL_SetWindowProgressValue SDL_hid_get_properties""".split()
selected = set(json.loads((r / "tools/bindings.json").read_text())["functions"])
source = "\n".join((r / f"tests/{n}.das").read_text() for n in ["sdl34_remaining", "sdl34_audio"])
source = re.sub(r"//[^\n]*|/\*.*?\*/", "", source, flags=re.S)
for name in names:
    assert name in selected, name
    assert re.search(r"\b" + re.escape(name) + r"\s*\(", source), name
print("SDL 3.4 remaining: 13/13 generated declarations have direct script calls.")
print("Limits: HID/pen invalid-device paths; mouse transform registration/removal, not injected OS motion.")
