"""Temporary pixel views must not escape through copy/move/address in safe script."""
from pathlib import Path
import subprocess, sys, tempfile
cases = [
    ("var saved : SdlPixelView", "saved := pixels", "clone"),
    ("var saved : SdlPixelView", "saved=pixels", "can't be copied"),
    ("var saved : SdlPixelView", "saved <- pixels", "move"),
    ("var saved : array<uint8>", "with_pixels(pixels) $(var bytes : array<uint8>#) { saved <- bytes; return sdl_ok() }", "can't move temporary"),
    ("var saved : array<uint>", "with_row(pixels,0) $(var row : array<uint>#) { saved <- row; return sdl_ok() }", "can't move temporary"),
]
with tempfile.TemporaryDirectory(prefix="sdl-pixel-escape-") as folder:
    for i,(decl,body,diagnostic) in enumerate(cases):
        path=Path(folder)/f"escape_{i}.das"
        path.write_text("options gen2\nrequire dassdl3/sdl3_pixel_views\n"+decl+"\n[export]\ndef main(smoke : bool) : int {\nwith_texture_pixels_rgba8(null,SDL_Rect(w=1,h=1)) $(pixels) {\n"+body+"\nreturn sdl_ok()\n}\nreturn 0\n}\n",encoding="utf-8")
        result=subprocess.run([sys.argv[1],str(path),"--smoke-test"],capture_output=True,text=True,timeout=30)
        output=result.stdout+result.stderr
        if result.returncode==0 or diagnostic not in output:
            raise SystemExit(f"Expected {diagnostic}: {body}\n{output}")
print("Pixel view, row and byte-array escape rejected")

with tempfile.TemporaryDirectory(prefix="sdl-surface-plane-escape-") as folder:
    path=Path(folder)/"escape.das"
    path.write_text("options gen2\nrequire dassdl3/sdl3_record_access\nvar saved : array<uint8>\n[export]\ndef main(smoke : bool) : int {\nwith_surface_bytes(null,0) $(var bytes : array<uint8>#; layout : int4) {saved <- bytes;return sdl_ok()}\nreturn 0\n}\n",encoding="utf-8")
    result=subprocess.run([sys.argv[1],str(path),"--smoke-test"],capture_output=True,text=True,timeout=30)
    if result.returncode==0 or "can't move temporary" not in result.stdout+result.stderr:
        raise SystemExit("Surface plane escaped or failed for the wrong reason: " + result.stdout+result.stderr)
print("General surface byte-array escape rejected")
