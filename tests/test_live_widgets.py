"""Real upstream live host, dynamic SDL module and JSON-RPC stdio round trips."""
import argparse
import json
import os
from pathlib import Path
import queue
import socket
import subprocess
import tempfile
import threading
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--host", required=True)
parser.add_argument("--module", required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
source = (root / "examples/live/01_widgets.das").read_text()
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
with tempfile.TemporaryDirectory(prefix="dassdl3-live-") as folder:
    script = Path(folder) / "main.das"
    script.write_text(source)
    env = dict(os.environ, SDL_RENDER_DRIVER="software")
    process = subprocess.Popen([args.host, "-dasroot", str(root / "third_party/daScript"),
        "-load_module", args.module, "-no-module-cache", str(script), "--live-port", str(port)],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, encoding="utf-8", errors="replace", bufsize=1, env=env, cwd=root)
    messages = queue.Queue()
    output = []
    def read(stream):
        for line in stream:
            output.append(line)
            try:
                value = json.loads(line)
                if isinstance(value, dict) and "id" in value:
                    messages.put(value)
            except ValueError:
                pass
    readers = [threading.Thread(target=read, args=(stream,), daemon=True)
               for stream in (process.stdout, process.stderr)]
    for reader in readers:
        reader.start()
    counter = 0
    def call(method, params=None, timeout=45):
        global counter
        counter += 1
        process.stdin.write(json.dumps(dict(jsonrpc="2.0", id=counter, method=method, params=params or {})) + "\n")
        process.stdin.flush()
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                response = messages.get(timeout=0.2)
                if response.get("id") == counter:
                    assert "error" not in response, response
                    return response["result"]
            except queue.Empty:
                assert process.poll() is None, "Host exited: " + "".join(output[-35:])
        raise AssertionError("RPC timeout: " + method + "\n" + "".join(output[-40:]))
    def until(method, predicate, timeout=40):
        deadline = time.monotonic() + timeout
        last = None
        while time.monotonic() < deadline:
            last = call(method)
            if predicate(last):
                return last
            time.sleep(0.08)
        raise AssertionError((method, last, "".join(output[-30:])))
    try:
        deadline = time.monotonic() + 60
        while "SDL live acquired=1" not in "".join(output):
            assert "initial compile FAILED" not in "".join(output) and process.poll() is None and time.monotonic() < deadline, "".join(output[-40:])
            time.sleep(0.1)
        ready = until("demo_state", lambda s: s["ticks"] > 2)
        assert ready["acquisitions"] == 1, ready
        snapshot = call("imgui_snapshot")
        assert "MAIN/INCREMENT" in json.dumps(snapshot) and "MAIN/SPEED" in json.dumps(snapshot), snapshot
        assert call("demo_increment") == 1
        call("imgui_force_set", {"target": "MAIN/SPEED", "value": 0.75})
        print("startup / widget telemetry / command transport PASS", flush=True)
        script.write_text(source.replace("revision = 1", "revision = 2"))
        call("reload")
        state = until("demo_state", lambda s: s["revision"] == 2 and s["ticks"] > ready["ticks"])
        assert state["edits"] == 1 and state["acquisitions"] == 1, state
        assert state["speed"] == 0.75, state
        print("reload: script changed, widget/app state and native resources preserved PASS", flush=True)
        script.write_text(source + "\nthis is deliberately invalid syntax !!!\n")
        call("reload")
        until("status", lambda s: s["has_error"] and s["paused"])
        assert call("last_error"), "Missing compiler diagnostic"
        assert "SDL live released" not in "".join(output)
        print("failed compilation: diagnostic + paused old context, no resource release PASS", flush=True)
        script.write_text(source.replace("revision = 1", "revision = 3"))
        call("reload")
        state = until("demo_state", lambda s: s["revision"] == 3)
        assert state["edits"] == 1 and state["acquisitions"] == 1, state
        until("status", lambda s: not s["has_error"] and not s["paused"])
        print("recovery after failed reload PASS", flush=True)
        call("set_user_control", {"enabled": False})
        call("imgui_click", {"target": "MAIN/INCREMENT"})
        clicked = until("demo_state", lambda s: s["clicks"] == 1)
        time.sleep(0.2)
        assert call("demo_state")["clicks"] == 1
        print("post-reload synthetic click: one action, no duplicate hook PASS", flush=True)
        call("reload_full")
        state = until("demo_state", lambda s: s["edits"] == 0)
        assert state["acquisitions"] == 1, state
        print("full reload: app defaults reset, native resources retained PASS", flush=True)
        script.write_text(source + "\ninvalid_final_reload !!!\n")
        call("reload")
        until("status", lambda s: s["has_error"] and s["paused"])
        call("shutdown")
        process.stdin.close()  # release upstream blocking stdio reader on EOF
        assert process.wait(timeout=20) == 0
        for reader in readers:
            reader.join(timeout=2)
        log = "".join(output)
        assert log.count("SDL live released=1 acquired=1") == 1, log[-3000:]
        print("final shutdown: resources released exactly once PASS", flush=True)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait(timeout=10)
        for reader in readers:
            reader.join(timeout=2)
        (root / "build/live-widgets-test.log").write_text("".join(output), encoding="utf-8")
