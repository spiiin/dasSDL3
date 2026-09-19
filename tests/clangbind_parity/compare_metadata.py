"""Compare the registered script-facing function contract of both backends."""
import difflib
import subprocess
import sys

outputs = [subprocess.run([exe], check=True, capture_output=True, text=True).stdout for exe in sys.argv[1:]]
if len(outputs) != 2 or not outputs[0].strip():
    raise SystemExit('Expected two nonempty metadata dumps')
if outputs[0] != outputs[1]:
    raise SystemExit(''.join(difflib.unified_diff(outputs[0].splitlines(True), outputs[1].splitlines(True),
                                              fromfile='baseline', tofile='CppGenBind')))
print(f'Registered signatures, names, side effects and unsafe flags match ({len(outputs[0].splitlines())} functions)')
