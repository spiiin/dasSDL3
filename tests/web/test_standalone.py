"""Real-browser standalone AOT checks (no script sources in runtime FS)."""
import argparse
from io import BytesIO
from PIL import Image
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--url', default='http://127.0.0.1:8766')
parser.add_argument('--browser', choices=['edge', 'firefox'], default='edge')
a = parser.parse_args()
with sync_playwright() as pw:
    browser = pw.firefox.launch(headless=True) if a.browser == 'firefox' else pw.chromium.launch(channel='msedge', headless=True)
    def open_page(query=''):
        page = browser.new_page(viewport={'width': 1100, 'height': 1000})
        page.goto(a.url + '/index.html' + query)
        page.wait_for_function("document.querySelector('#status').textContent!=='Loading runtime…'", timeout=120000)
        assert page.locator('#status').inner_text() == 'Ready', page.locator('#output').inner_text()
        # Runtime has no compiler inputs. Downloadable source is only an HTTP document.
        assert page.evaluate("!runtime.FS.analyzePath('/daslib').exists && !runtime.FS.analyzePath('/repo').exists && !runtime.FS.analyzePath('/examples').exists")
        page.locator('#start').click()
        return page
    def ended(page, failed=False):
        page.wait_for_function("['Stopped','Failed'].includes(document.querySelector('#status').textContent)", timeout=30000)
        output = page.locator('#output').inner_text()
        assert page.locator('#status').inner_text() == ('Failed' if failed else 'Stopped'), output
        assert 'wasm32 standalone AOT' in output, output
        return output
    page = open_page()
    page.wait_for_function("document.querySelector('#output').textContent.includes('Rendered 60 frames.') || document.querySelector('#status').textContent==='Failed'", timeout=30000)
    assert page.locator('#status').inner_text() == 'Running', page.locator('#output').inner_text()
    image = Image.open(BytesIO(page.locator('canvas').screenshot())).convert('RGB')
    assert sum(n for n, c in image.getcolors(image.width * image.height) if c == (70, 200, 160)) > 1000
    page.locator('canvas').focus()
    page.keyboard.press('Escape')
    assert ended(page).count('Lifecycle released') == 1
    # Restart after finish, then restart while running, each creates a fresh module.
    for active_restart in (False, True):
        page.locator('#restart').click()
        page.wait_for_function("document.querySelector('#status').textContent==='Ready'", timeout=120000)
        page.locator('#start').click()
        page.wait_for_function("document.querySelector('#output').textContent.includes('Rendered 60 frames.')", timeout=30000)
        if active_restart:
            page.locator('#stop').click()
            assert ended(page).count('Lifecycle released') == 1
    page.close()
    print(a.browser + ' pixels / Escape / Stop / Restart PASS', flush=True)
    page = open_page('?app=gc')
    output = ended(page)
    assert 'GC frames=400' in output and 'GC roots and bounded heap PASS' in output, output
    page.close()
    print(a.browser + ' GC 400 frames / roots / heap PASS', flush=True)
    page = open_page('?app=sdl_gc')
    output = ended(page)
    assert 'SDL GC frames=400' in output and 'SDL resources and GC roots PASS' in output, output
    page.close()
    print(a.browser + ' live SDL resources with GC PASS', flush=True)
    page = open_page('?app=faults&mode=6')
    output = ended(page, True)
    assert output.count('CLEANED') == 1 and 'create_renderer' in output, output
    page.close()
    print(a.browser + ' partial SDL initialization cleanup PASS', flush=True)
    for mode, marker in [(1, 'init probe'), (2, 'update probe'), (3, 'shutdown probe'), (4, 'CLEANED'), (5, 'event probe')]:
        page = open_page('?app=faults&mode=' + str(mode))
        output = ended(page, True)
        assert marker in output and output.count('CLEANED') == 1, output
        page.close()
        print(a.browser + ' fault ' + str(mode) + ' cleanup/status PASS', flush=True)
    browser.close()
