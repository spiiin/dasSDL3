"""Prove missing AOT fails specifically at linking, not for unrelated reasons."""
import subprocess
import sys

result = subprocess.run(sys.argv[1:], capture_output=True, text=True, errors='replace')
output = result.stdout + result.stderr
if result.returncode not in (1, 2) or 'AOT link failed on main' not in output:
    raise SystemExit(f'Expected a missing-AOT diagnostic, got {result.returncode}:\n{output}')
print('Missing AOT correctly rejected; interpreter fallback is disabled')
