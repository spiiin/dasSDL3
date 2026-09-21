"""Raw callback arguments cannot reinterpret daScript blocks as C addresses."""
from pathlib import Path
import subprocess
import sys
import tempfile

with tempfile.TemporaryDirectory() as directory:
    for name in ("SDL_SetEventFilter", "SDL_AddEventWatch", "SDL_RemoveEventWatch", "SDL_FilterEvents"):
        script = Path(directory) / "callback_type.das"
        script.write_text('options gen2\nrequire sdl3\n[export]\ndef main {\n'
                          ' let callback = $() : bool { return true }\n'
                          f' {name}(callback,null)\n}}\n')
        result = subprocess.run([sys.argv[1], str(script)], capture_output=True,
                                text=True, timeout=30)
        output = result.stdout + result.stderr
        assert result.returncode != 0 and name in output, output
        assert "out of 0 total functions" not in output.lower(), output
        assert "block" in output.lower() and "void" in output.lower(), output
print("Raw Events callbacks reject script blocks")
