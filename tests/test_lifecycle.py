# Host lifecycle ordering, cleanup and legacy-main regression.
import subprocess
import sys
import tempfile
from pathlib import Path
runner = str(Path(sys.argv[1]).resolve())
cases = [
    ('imported_update', 'require ./imported.das\n[export]\ndef main(smoke : bool) : int { return 7 }', 7, '', []),
    ('imported_shutdown', 'require ./imported.das\n[export]\ndef update() : bool { return false }', 0, '', []),
    ('private_update', 'def update() : bool { return false }\n[export]\ndef main(smoke : bool) : int { return update() ? 3 : 7 }', 7, '', []),
    ('normal', '''var ticks = 0
[export]
def init() { print("INIT\\n") }
[export]
def update() : bool { ticks++; return ticks < 3 }
[export]
def shutdown() { print("QUIT {ticks}\\n") }
[export]
def main(smoke : bool) : int { panic("main must not run"); return 9 }
''', 0, 'INIT\nQUIT 3', []),
    ('legacy', '[export]\ndef main(smoke : bool) : int { return smoke ? 7 : 8 }', 7, '', ['--smoke-test']),
    ('partial_init', '''[export]
def init() { panic("init probe") }
[export]
def update() : bool { panic("update must not run"); return false }
[export]
def shutdown() { print("CLEANED\\n") }
''', 1, 'CLEANED', []),
    ('update_failure', '''[export]
def update() : bool { panic("update probe"); return true }
[export]
def shutdown() { print("CLEANED\\n") }
''', 1, 'CLEANED', []),
    ('cleanup_failure', '''[export]
def update() : bool { return false }
[export]
def shutdown() { panic("shutdown probe") }
''', 1, 'Lifecycle exception in shutdown', []),
    ('invalid_signature', '''[export]
def init(value : int) { print("MUST_NOT_RUN") }
[export]
def update() : bool { return false }
[export]
def shutdown() { print("MUST_NOT_RUN") }
''', 1, 'Invalid or ambiguous lifecycle entry', []),
    ('result_error_code', '''[export]
def update() : bool { return false }
[export]
def shutdown() { print("CLEANED\\n") }
[export]
def exit_code() : int { return 5 }
''', 5, 'CLEANED', []),
    ('int_update', '''var ticks = 0
[export]
def update() : int { ticks++; return ticks == 1 ? -1 : 0 }
[export]
def shutdown() { print("QUIT {ticks}\\n") }
''', 0, 'QUIT 2', []),
    ('smoke_void', '''var ticks = 0
[export]
def update() { ticks++ }
[export]
def shutdown() { print("QUIT {ticks}\\n") }
''', 0, 'QUIT 60', ['--smoke-test']),
    ('invalid_update', '[export]\ndef update(value : int) : bool { return false }', 1, 'Invalid or ambiguous lifecycle entry', []),
]
with tempfile.TemporaryDirectory(prefix='dassdl3-lifecycle-') as directory:
    (Path(directory) / 'imported.das').write_text('options gen2\nmodule imported\n[export]\ndef update(value : int) : bool { return false }\n[export]\ndef shutdown() { panic("MUST_NOT_RUN") }', encoding='utf-8')
    for name, source, code, expected, args in cases:
        path = Path(directory) / (name + '.das')
        path.write_text('options gen2\n' + source, encoding='utf-8')
        result = subprocess.run([runner, str(path), *args], capture_output=True, text=True, timeout=20)
        output = result.stdout + result.stderr
        assert result.returncode == code and expected in output, (name, result.returncode, output)
        assert 'MUST_NOT_RUN' not in output, (name, output)
        if expected == 'CLEANED': assert output.count('CLEANED') == 1, output
        print(name + ' PASS')
