"""Shared lifecycle in the real wasm interpreter; run after building web/."""
import argparse
import ast
import re
from io import BytesIO
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--url', default='http://127.0.0.1:8765')
parser.add_argument('--browser', choices=['edge', 'firefox'], default='edge')
a = parser.parse_args()
root = Path(__file__).resolve().parents[2]
# Reuse the exact desktop contract fixtures without executing their CLI runner.
tree = ast.parse((root / 'tests/test_lifecycle.py').read_text())
cases = next(ast.literal_eval(node.value) for node in tree.body
             if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'cases' for t in node.targets))
with sync_playwright() as pw:
    browser = pw.firefox.launch(headless=True) if a.browser == 'firefox' else pw.chromium.launch(channel='msedge', headless=True)
    def open_page(source=None):
        page = browser.new_page(viewport={'width': 1100, 'height': 1000})
        page.goto(a.url + '/09_lifecycle.html')
        page.wait_for_function("document.querySelector('#status').textContent !== 'Loading runtime…'", timeout=120000)
        assert page.locator('#status').inner_text() == 'Ready', page.locator('#output').inner_text()
        if source is not None:
            page.evaluate("source => runtime.FS.writeFile(scriptPath, source)", source)
            page.evaluate("runtime.FS.writeFile('/examples/lifecycle/imported.das', 'options gen2\\nmodule imported\\n[export]\\ndef update(value : int) : bool { return false }\\n[export]\\ndef shutdown() { panic(\"MUST_NOT_RUN\") }')")
        page.locator('#start').click()
        return page
    def ended(page, code=0):
        page.wait_for_function("['Stopped','Failed'].includes(document.querySelector('#status').textContent)", timeout=30000)
        output = page.locator('#output').inner_text()
        assert page.locator('#status').inner_text() == ('Failed' if code else 'Stopped'), output
        return output
    page = open_page()
    page.wait_for_function("document.querySelector('#output').textContent.includes('Rendered 60 frames.') || document.querySelector('#status').textContent==='Failed'", timeout=30000)
    assert page.locator('#status').inner_text() == 'Running', page.locator('#output').inner_text()
    image = Image.open(BytesIO(page.locator('canvas').screenshot())).convert('RGB')
    assert sum(count for count, color in image.getcolors(image.width * image.height) if color == (70, 200, 160)) > 1000
    page.locator('canvas').focus()
    page.keyboard.press('Escape')
    assert ended(page).count('Lifecycle released') == 1
    page.locator('#restart').click()
    page.wait_for_function("document.querySelector('#status').textContent==='Ready'", timeout=120000)
    page.locator('#start').click()
    page.wait_for_function("document.querySelector('#output').textContent.includes('Rendered 60 frames.')", timeout=30000)
    page.locator('#stop').click()
    assert ended(page).count('Lifecycle released') == 1
    page.close()
    print('shared square pixels / Escape / Stop / Restart PASS', flush=True)
    for name, source, code, expected, args in cases:
        if name in ('private_update', 'legacy', 'smoke_void', 'imported_update'):
            continue
        page = open_page('options gen2\n' + source)
        output = ended(page, code)
        assert expected in output and 'MUST_NOT_RUN' not in output, (name, output)
        if expected == 'CLEANED': assert output.count('CLEANED') == 1, output
        page.close()
        print(name + ' PASS', flush=True)
    page = open_page('options gen2\nvar ticks = 0\n[export]\ndef update() { ticks++; if (ticks == 3) { print("VOID READY\\n") } }\n[export]\ndef shutdown() { print("VOID CLEANED\\n") }')
    page.wait_for_function("document.querySelector('#output').textContent.includes('VOID READY')", timeout=30000)
    page.locator('#stop').click()
    assert ended(page).count('VOID CLEANED') == 1
    page.close()
    print('void update host Stop PASS', flush=True)
    page = open_page((root / 'tests/lifecycle_gc.das').read_text())
    output = ended(page)
    assert 'GC frames=400' in output and 'GC roots and bounded heap PASS' in output, output
    page.close()
    print('400 ticks: GC roots and bounded heap PASS', flush=True)
    for name, source, marker in [
        ('invalid_event', 'def app_event() : int { return 0 }', 'Invalid Web lifecycle app_event'),
        ('event_exception', 'def app_event(event : SDL_Event) : int { panic("event probe"); return 0 }', 'Script exception:'),
    ]:
        text = (root / 'examples/lifecycle/01_square.das').read_text()
        text, count = re.subn(r'def app_event\(event : SDL_Event\) : int \{.*?\n\}', source, text, flags=re.S)
        assert count == 1
        page = open_page(text)
        output = ended(page, 1)
        assert marker in output, output
        assert output.count('Lifecycle released') == (0 if name == 'invalid_event' else 1), output
        page.close()
        print(name + ' PASS', flush=True)
    browser.close()
