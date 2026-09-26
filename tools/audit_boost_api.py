"""Reproducible source index for the handwritten boost audit (not type inference)."""
import argparse
import csv
import io
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Preserve offsets/newlines while excluding braces and declarations in comments/strings.
IGNORED = re.compile(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"', re.S)
DECL = re.compile(r'^def public\s+([A-Za-z_]\w*)\b', re.M)


def declarations(path):
    source = path.read_text(encoding='utf-8')
    code = IGNORED.sub(lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), source)
    for match in DECL.finditer(code):
        start = code.index('{', match.end())
        depth, end = 1, start + 1
        while depth:
            if end >= len(code):
                raise ValueError(f'Unclosed declaration: {path}:{match[1]}')
            depth += (code[end] == '{') - (code[end] == '}')
            end += 1
        body = code[start:end]
        signature = ' '.join(source[match.start():start].split())
        markers = sorted(set(re.findall(r'\b(sdl_status|sdl_ok|err|ok|move_ok|some|none|move_some|checked_handle_result|native_gpu_pointer_result)\s*\(', body)))
        yield [path.relative_to(ROOT).as_posix(), str(source.count('\n', 0, match.start()) + 1),
               match[1], signature, str(bool(re.search(r'\bvar\b', code[match.end():start]))).lower(),
               ','.join(markers), str(bool(re.search(r'\bdefer\s*\(', body))).lower()]


def render():
    rows = [row for path in sorted((ROOT / 'dassdl3').glob('*.das')) for row in declarations(path)]
    output = io.StringIO(newline='')
    writer = csv.writer(output, lineterminator='\n')
    writer.writerow(['source', 'line', 'name', 'signature', 'mutable_in_signature', 'body_markers', 'defer_in_body'])
    writer.writerows(rows)
    return output.getvalue(), len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    content, count = render()
    target = ROOT / 'docs/generated/boost-api.csv'
    if args.check:
        if not target.exists() or target.read_text(encoding='utf-8') != content:
            raise SystemExit('Boost source index is stale; run python tools/audit_boost_api.py')
    else:
        target.write_text(content, encoding='utf-8', newline='\n')
    print(f'Boost source index: {count} explicit public declarations')


if __name__ == '__main__':
    main()
