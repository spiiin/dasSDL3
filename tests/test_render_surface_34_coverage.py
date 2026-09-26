"""New SDL 3.4 Render/Surface raw declarations have direct script call sites."""
import json
import re
from pathlib import Path
root = Path(__file__).resolve().parents[1]
names = """SDL_LoadSurface SDL_LoadSurface_IO SDL_LoadPNG SDL_LoadPNG_IO SDL_SavePNG SDL_SavePNG_IO SDL_RotateSurface
SDL_CreateGPURenderer SDL_GetGPURendererDevice SDL_SetTexturePalette SDL_GetTexturePalette SDL_RenderTexture9GridTiled
SDL_SetRenderTextureAddressMode SDL_GetRenderTextureAddressMode SDL_SetDefaultTextureScaleMode SDL_GetDefaultTextureScaleMode
SDL_CreateGPURenderState SDL_SetGPURenderStateFragmentUniforms SDL_SetGPURenderState SDL_DestroyGPURenderState""".split()
selected = set(json.loads((root / "tools/bindings.json").read_text())["functions"])
source = "\n".join((root / f"tests/{name}.das").read_text() for name in ["render_surface_34", "gpu_renderer_34"])
source = re.sub(r"//[^\n]*|/\*.*?\*/", "", source, flags=re.S)
for name in names:
    assert name in selected, name
    assert re.search(r"\b" + re.escape(name) + r"\s*\(", source), name
print("SDL 3.4 Render/Surface: 20/20 generated functions have direct daScript test calls.")
