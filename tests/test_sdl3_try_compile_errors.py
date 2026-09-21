"""Unsupported sdl_try placements must fail compilation, never run a fallback."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

CASES = {
    "nested": ('def run { let x = 1 + (ok(2, type<SdlError>) |> sdl_try); return sdl_ok() }', "sdl_try must be a standalone"),
    "indexed_assignment": ('def run { var x <- array<int>(0); x[0] = ok(2, type<SdlError>) |> sdl_try; return sdl_ok() }', "sdl_try must be a standalone"),
    "wrong_caller": ('def run : int { sdl_ok() |> sdl_try; return 0 }', "sdl_try requires an enclosing Result"),
    "wrong_caller_error": ('def run { sdl_ok() |> sdl_try; return ok(1, type<string>) }', "sdl_try requires an enclosing Result"),
    "wrong_error": ('def run { ok(2, type<string>) |> sdl_try; return sdl_ok() }', "no matching functions"),
    "option": ('def run { some(2) |> sdl_try; return sdl_ok() }', "no matching functions"),
    "finally": ('def run { defer() { sdl_ok() |> sdl_try }; return sdl_ok() }', "sdl_try must be a standalone"),
    "condition": ('def run { if (ok(true, type<SdlError>) |> sdl_try) { pass }; return sdl_ok() }', "sdl_try must be a standalone"),
    "address": ('def run { let fn = @@ <(value : $Result<int; SdlError>) : int> sdl_try; return sdl_ok() }', "taking its function address is forbidden"),
}

def main():
    runner = str(Path(sys.argv[1]).resolve())
    with tempfile.TemporaryDirectory(prefix="sdl3-try-errors-") as directory:
        for name, (body, diagnostic) in CASES.items():
            script = Path(directory) / f"{name}.das"
            script.write_text("options gen2\nrequire dassdl3/sdl3_try\nrequire daslib/defer\n" + body + '\n[export]\ndef main(smoke : bool) : int { run(); return 0 }\n', encoding="utf-8")
            completed = subprocess.run([runner, str(script), "--smoke-test"], capture_output=True, text=True, timeout=30, env={**os.environ, "SDL_VIDEODRIVER": "dummy"})
            output = completed.stdout + completed.stderr
            if completed.returncode == 0 or diagnostic not in output:
                raise AssertionError(f"{name}: expected compile rejection containing {diagnostic!r}; exit={completed.returncode}\n{output}")
            print(f"{name}: rejected")

if __name__ == "__main__":
    main()
