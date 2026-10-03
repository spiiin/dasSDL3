"""Reject interpreter fallback, and require the expected AOT-link diagnostic."""
import subprocess
import sys
p = subprocess.run(sys.argv[1:], capture_output=True, text=True)
output = p.stdout + p.stderr
if p.returncode not in (1, 2) or "error[50101]: AOT link failed" not in output or "Linux native-width HID Unicode and unsupported DXGI PASS" in output.splitlines():
    print(output)
    raise SystemExit("Expected an AOT-link failure without executing the script")
print("Missing AOT rejected; interpreter fallback disabled")
