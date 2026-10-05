"""MCP initialize/tools/list/tools/call -> upstream adapter -> loopback HTTP -> SDL."""
import argparse
import json
import os
from pathlib import Path
import queue
import shutil
import struct
import sys
import zlib
import socket
import subprocess
import tempfile
import threading
import time
import urllib.request

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--host", required=True)
p.add_argument("--module", required=True)
p.add_argument("--http-module", required=True)
p.add_argument("--daslang", required=True)
p.add_argument("--watch", action="store_true", help="Reload only through upstream file watching")
p.add_argument("--gui", action="store_true", help="Capture and verify rendered GUI before/after automatic reload")
p.add_argument("--playwright", action="store_true", help="Run upstream daScript playwright driver against the SDL app")
a = p.parse_args()
if a.playwright: a.gui = True
if a.gui: a.watch = True
root = Path(__file__).resolve().parents[1]
das = root / "third_party/daScript"
logs = {"app": [], "mcp": []}
processes = []
readers = []
responses = queue.Queue()
invalid_stdout = []
def launch(label, args):
    proc = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, encoding="utf-8", errors="replace", bufsize=1,
        cwd=folder, env=dict(os.environ, SDL_RENDER_DRIVER="software"))
    processes.append(proc)
    def read(stream):
        for line in stream:
            logs[label].append(line)
            if label == "mcp" and stream is proc.stdout:
                try:
                    obj = json.loads(line)
                    if isinstance(obj, dict) and "id" in obj: responses.put(obj)
                except ValueError:
                    if line.strip(): invalid_stdout.append(line)
    for stream in (proc.stdout, proc.stderr):
        thread = threading.Thread(target=read, args=(stream,), daemon=True)
        thread.start()
        readers.append(thread)
    return proc
counter = 0
def rpc(method, params):
    global counter
    assert not invalid_stdout, invalid_stdout
    counter += 1
    mcp.stdin.write(json.dumps(dict(jsonrpc="2.0", id=counter, method=method, params=params)) + "\n")
    mcp.stdin.flush()
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        try:
            reply = responses.get(timeout=0.2)
            if reply.get("id") == counter:
                assert "error" not in reply, reply
                return reply["result"]
        except queue.Empty:
            assert mcp.poll() is None, "".join(logs["mcp"][-35:])
    raise AssertionError("MCP timeout: " + method + "\n" + "".join(logs["mcp"][-40:]))
def tool(name, args=None, error=False):
    result = rpc("tools/call", {"name": name, "arguments": dict(args or {}, port=str(port))})
    assert bool(result.get("isError", False)) == error, result
    text = "".join(item.get("text", "") for item in result["content"])
    try: return json.loads(text)
    except ValueError: return text

def command(name, args=None):
    return tool("live_command", {"name": name, "args": json.dumps(args or {})})
def until(fn, pred):
    deadline = time.monotonic() + 45
    while time.monotonic() < deadline:
        value = fn()
        if pred(value): return value
        time.sleep(0.1)
    raise AssertionError(value)

def reload_script():
    if not a.watch:
        tool("live_reload")

write_number = 0
def write_script(text):
    global write_number
    write_number += 1
    # Different lengths exercise stat-based polling even within one mtime second.
    # Atomic replacement models editors that save through a temporary file.
    staged = script.with_suffix(".saving")
    staged.write_text(text + "\n// save " + "x" * write_number + "\n")
    staged.replace(script)

def capture_gui(label):
    ticket = command("gui_capture")
    until(lambda: command("gui_capture_status"), lambda n: n >= ticket)
    data = (Path(folder) / "capture.bmp").read_bytes()
    assert data[:2] == b"BM"
    offset = struct.unpack_from("<I", data, 10)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    bits = struct.unpack_from("<H", data, 28)[0]
    compression = struct.unpack_from("<I", data, 30)[0]
    assert width == 800 and abs(height) == 600 and bits in (24, 32), (width, height, bits)
    assert compression in (0, 3), compression
    if compression == 3:
        assert struct.unpack_from("<III", data, 54) == (0xFF0000, 0xFF00, 0xFF)
    pitch = ((width * bits + 31) // 32) * 4
    rows = []
    for y in range(abs(height)):
        source_y = abs(height) - 1 - y if height > 0 else y
        row = data[offset + source_y * pitch:offset + (source_y + 1) * pitch]
        rows.append(bytes(c for x in range(width) for c in row[x * (bits // 8):x * (bits // 8) + 3][::-1]))
    artifact = root / "build/live-gui"
    artifact.mkdir(exist_ok=True)
    def chunk(kind, payload):
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, abs(height), 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(b"".join(b"\0" + row for row in rows))) + chunk(b"IEND", b"")
    (artifact / (label + ".png")).write_bytes(png)
    return rows

def changed_pixels(left, right, box):
    x0, y0, x1, y1 = map(int, box)
    assert 0 <= x0 < x1 <= 800 and 0 <= y0 < y1 <= 600, box
    return sum(left[y][x*3:x*3+3] != right[y][x*3:x*3+3] for y in range(y0,y1) for x in range(x0,x1))

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
with tempfile.TemporaryDirectory(prefix="dassdl3-mcp-") as folder:
    script = Path(folder) / "main.das"
    source = (root / "examples/live/02_widgets_http.das").read_text()
    if not a.watch:
        source = source.replace("require live/live_watch_boost\n", "")
    source = source.replace("speed = SPEED.value", "speed = SPEED.value, style_alpha = GetStyle().Alpha, recovery_assert = GetIO().ConfigErrorRecoveryEnableAssert")
    if a.gui:
        source = source.replace("require ./frame_recovery.das", "require ./frame_recovery.das\nrequire ./live_gui_capture.das")
        source = source.replace("    renderer |> present()", "    capture_test_frame(renderer) |> sdl_try\n    renderer |> present()")
        shutil.copyfile(root / "tests/live_gui_capture.das", Path(folder) / "live_gui_capture.das")
    write_script(source)
    shutil.copyfile(root / "examples/live/loopback_http.das", Path(folder) / "loopback_http.das")
    shutil.copyfile(root / "examples/live/frame_recovery.das", Path(folder) / "frame_recovery.das")
    try:
        app = launch("app", [str(Path(a.host).resolve()), "-dasroot", str(das),
            "-load_module", str(Path(a.module).resolve()), "-load_module", str(Path(a.http_module).resolve()),
            "-no-module-cache", str(script), "--live-port", str(port)])
        deadline = time.monotonic() + 45
        while "SDL live acquired=1" not in "".join(logs["app"]):
            assert app.poll() is None and time.monotonic() < deadline and "initial compile FAILED" not in "".join(logs["app"]), "".join(logs["app"][-40:])
            time.sleep(0.1)
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/status", timeout=5) as response:
            assert response.status == 200
        if sys.platform == "darwin":
            listeners = subprocess.check_output(
                ["/usr/sbin/lsof", "-nP", "-a", "-p", str(app.pid), "-iTCP", "-sTCP:LISTEN", "-Fn"], text=True)
            addresses = {line[1:] for line in listeners.splitlines()
                         if line.startswith("n") and line.endswith(":" + str(port))}
        else:
            listeners = subprocess.check_output(["netstat", "-ano", "-p", "tcp"], text=True)
            addresses = {parts[1] for line in listeners.splitlines()
                         if len(parts := line.split()) >= 5 and parts[-1] == str(app.pid)
                         and parts[1].endswith(":" + str(port)) and parts[3] == "LISTENING"}
        assert addresses == {f"127.0.0.1:{port}"}, addresses
        print("HTTP listener bound only to 127.0.0.1 PASS", flush=True)
        mcp = launch("mcp", [str(Path(a.daslang).resolve()), "-dasroot", str(das),
            "-load_module", str(Path(a.http_module).resolve()), "-ignore-manifest", str(das / "utils/mcp/main.das")])
        initialized = rpc("initialize", {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "SDL test", "version": "1"}})
        assert "tools" in initialized["capabilities"], initialized
        mcp.stdin.write('{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
        mcp.stdin.flush()
        names = {v["name"] for v in rpc("tools/list", {})["tools"]}
        assert {"live_status", "live_error", "live_reload", "live_command", "live_shutdown"} <= names, names
        print("MCP initialize + upstream tool discovery PASS", flush=True)
        state = command("demo_state")
        baseline_alpha = state["style_alpha"]
        baseline_assert = state["recovery_assert"]
        assert state["acquisitions"] == 1
        assert "MAIN/SPEED" in json.dumps(command("imgui_snapshot"))
        if a.gui:
            before_image = capture_gui("01-before")
            snap = command("imgui_snapshot")
            box = snap["globals"]["MAIN/SPEED"]["bbox"]
            slider_box = [box[k] for k in ("x", "y", "z", "w")]
        command("imgui_force_set", {"target": "MAIN/SPEED", "value": 0.75})
        until(lambda: command("demo_state"), lambda s: s["speed"] == 0.75)
        command("set_user_control", {"enabled": False})
        command("imgui_click", {"target": "MAIN/INCREMENT"})
        until(lambda: command("demo_state"), lambda s: s["clicks"] == 1)
        if a.gui:
            changed_image = capture_gui("02-after-actions")
            assert changed_pixels(before_image, changed_image, slider_box) > 50
        batch = tool("live_commands", {"commands": json.dumps([
            {"name": "demo_state"}, 7, {"name": "demo_state"}])})
        assert batch[0]["clicks"] == 1 and "error" in batch[1] and batch[2]["clicks"] == 1, batch
        print("MCP -> HTTP -> SDL query, value, click and batch isolation PASS", flush=True)
        if a.watch:
            watched = command("cmd_watch_status")
            assert watched["has_agent"], watched
            assert any(Path(f["path"]).name == "frame_recovery.das" for f in watched["files"]), watched
            generation = tool("live_status")["generation"]
            dependency = Path(folder) / "frame_recovery.das"
            dependency.write_text(dependency.read_text() + "\n// dependency edit\n")
            until(lambda: tool("live_status"), lambda s: s["generation"] > generation and not s["has_error"])
            state = command("demo_state")
            assert state["acquisitions"] == 1 and state["speed"] == 0.75 and state["clicks"] == 1, state
            print("Automatic imported-file reload preserves state PASS", flush=True)
        generation = tool("live_status")["generation"]
        updated = source.replace("revision = 1", "revision = 2")
        if a.gui:
            updated = updated.replace("Save this script to reload automatically; Reload also works.", "Reload verified: state preserved.")
        write_script(updated)
        reload_script()
        until(lambda: tool("live_status"), lambda s: s["generation"] > generation)
        state = command("demo_state")
        assert state["revision"] == 2 and state["acquisitions"] == 1 and state["speed"] == 0.75 and state["clicks"] == 1, state
        print("MCP reload preserves native resources and widget state PASS", flush=True)
        if a.gui:
            reloaded_image = capture_gui("03-after-reload")
            assert changed_pixels(changed_image, reloaded_image, slider_box) == 0
            assert changed_pixels(changed_image, reloaded_image, (28,47,500,60)) > 100
            assert "Reload verified: state preserved." in json.dumps(command("imgui_snapshot"))
            print("GUI scenario: changed slider pixels, preserved slider image, new rendered text PASS", flush=True)
        if a.playwright:
            previous = command("demo_state")
            previous_image = reloaded_image
            for run in range(2):
                driven = subprocess.run([str(Path(a.daslang).resolve()), "-dasroot", str(das),
                    "-load_module", str(Path(a.http_module).resolve()), "-ignore-manifest",
                    str(root / "examples/live/playwright_widgets.das"), "--", "--live-port", str(port)],
                    cwd=folder, capture_output=True, text=True, encoding="utf-8", timeout=60)
                log = root / "build/live-playwright-driver.log"
                with log.open("w" if run == 0 else "a", encoding="utf-8") as out:
                    out.write(driven.stdout + driven.stderr)
                assert driven.returncode == 0 and "reload/state PASS" in driven.stdout, driven.stdout + driven.stderr
                print(driven.stdout.strip(), flush=True)
                state = command("demo_state")
                assert state["clicks"] == previous["clicks"] + 1 and state["acquisitions"] == 1, state
                assert abs(state["speed"] - previous["speed"]) > 0.05, state
                playwright_image = capture_gui("04-upstream-playwright" if run == 0 else "05-playwright-repeat")
                assert changed_pixels(previous_image, playwright_image, slider_box) > 50
                previous, previous_image = state, playwright_image
        write_script(source + "\ninvalid_mcp_reload !!!\n")
        reload_script()
        until(lambda: tool("live_status"), lambda s: s["has_error"] and s["paused"])
        assert tool("live_error")
        tool("live_command", {"name": "demo_state"}, error=True)
        print("MCP diagnostics + rejected command on compile failure PASS", flush=True)
        write_script(source.replace("revision = 1", "revision = 3"))
        reload_script()
        until(lambda: tool("live_status"), lambda s: not s["has_error"] and not s["paused"])
        assert command("demo_state")["revision"] == 3
        # Fault injection is confined to temporary scripts, never the interactive example.
        for phase, anchor in (("init", "    apply_daslang_theme()"),
                              ("update", "    let result = frame()"),
                              ("open_window", "        button(INCREMENT.PUBLIC"),
                              ("raw_stack", "        button(INCREMENT.PUBLIC")):
            marker = "SDL_RUNTIME_PROBE_" + phase
            assert source.count(anchor) == 1
            broken = source.replace(anchor, '    panic("' + marker + '")\n' + anchor)
            if phase == "raw_stack":
                broken = "options _allow_imgui_legacy = true\n" + broken
                broken = broken.replace('    panic("' + marker, '    unsafe { Begin("Fault window") }\n    PushStyleVar(ImGuiStyleVar.Alpha, 0.25)\n    panic("' + marker)
            write_script(broken)
            reload_script()
            until(lambda: tool("live_status"), lambda s: s["has_error"] and s["paused"])
            assert marker in str(tool("live_error"))
            tool("live_command", {"name": "demo_state"}, error=True)
            write_script(source.replace("revision = 1", "revision = 4"))
            reload_script()
            until(lambda: tool("live_status"), lambda s: not s["has_error"] and not s["paused"])
            recovered = command("demo_state")
            assert recovered["revision"] == 4 and recovered["acquisitions"] == 1, recovered
            assert recovered["style_alpha"] == baseline_alpha and recovered["recovery_assert"] == baseline_assert, recovered
            tick = recovered["ticks"]
            until(lambda: command("demo_state"), lambda s: s["ticks"] > tick)
            assert "MAIN/SPEED" in json.dumps(command("imgui_snapshot"))
            print("MCP runtime " + phase + " diagnostics, rejection and recovery PASS", flush=True)
        tool("live_shutdown")
        assert app.wait(timeout=20) == 0
        mcp.stdin.close()
        assert mcp.wait(timeout=15) == 0
        for reader in readers: reader.join(timeout=2)
        assert "".join(logs["app"]).count("SDL live released=1 acquired=1") == 1
        assert "".join(logs["app"]).count("SDL live interrupted frame discarded") == 2
        assert not invalid_stdout, invalid_stdout
        assert "leaked" not in "".join(logs["app"]), "".join(logs["app"][-20:])
        print("MCP recovery + shutdown, no reported transport leaks PASS", flush=True)
    finally:
        for proc in processes:
            if proc.poll() is None: proc.kill()
            proc.wait(timeout=10)
        for reader in readers: reader.join(timeout=2)
        for name, lines in logs.items():
            (root / f"build/live-mcp-{'gui-' if a.gui else 'watch-' if a.watch else ''}{name}.log").write_text("".join(lines), encoding="utf-8")
