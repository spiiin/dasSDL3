"""Launch the SDL recording demo, run upstream recording, and close our own host."""
import argparse
import datetime
import json
from pathlib import Path
import socket
import struct
import subprocess
import sys
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
PORT = 9090  # Pinned upstream with_recording_app; no dependency patches here.

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="New/empty output directory (default: build/recordings/<timestamp>)")
    live_build = "build/macos-live" if sys.platform == "darwin" else "build/ninja"
    http_build = "build/macos-live-http" if sys.platform == "darwin" else "build/live-http"
    executable_suffix = "" if sys.platform == "darwin" else ".exe"
    parser.add_argument("--host", type=Path, default=ROOT / live_build / ("live/dasSDL3_live" + executable_suffix))
    parser.add_argument("--daslang", type=Path, default=ROOT / "third_party/daScript/bin" / ("daslang" + executable_suffix))
    parser.add_argument("--module", type=Path, default=ROOT / live_build / "live/module")
    parser.add_argument("--http-module", type=Path, default=ROOT / http_build / "dasHV")
    parser.add_argument("--stb-module", type=Path, default=ROOT / http_build / "dasStbImage")
    args = parser.parse_args()
    das = ROOT / "third_party/daScript"
    host = args.host.resolve()
    interpreter = args.daslang.resolve()
    modules = [args.module.resolve(), args.http_module.resolve(), args.stb_module.resolve()]
    required = [host, interpreter, modules[0]/"dasSDL3_live_module.shared_module",
                modules[1]/"dasModuleHV.shared_module", modules[2]/"dasModuleStbImage.shared_module"]
    missing = [str(p) for p in required if not p.is_file()]
    if missing:
        parser.exit(1, "Missing build files:\n" + "\n".join(missing) +
                    "\nBuild the native live host and live-http targets first; see examples/live/README.md.\n")
    try:
        with socket.socket() as probe:
            # macOS keeps recently closed connections in TIME_WAIT. The HTTP
            # server also reuses addresses; still reject an active listener.
            if sys.platform == "darwin":
                probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            probe.bind(("127.0.0.1", PORT))
    except OSError:
        parser.exit(1, "Port 9090 is occupied or unavailable. Close the app using it and retry. No existing process was stopped.\n")
    output = (args.output or ROOT/"build/recordings"/datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")).resolve()
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        parser.exit(1, f"Output must be a new or empty directory: {output}\n")
    assets = output/"doc/source/_static/tutorials"
    assets.mkdir(parents=True, exist_ok=True)
    app = None
    ready = False
    def http(path, body):
        req = urllib.request.Request(f"http://127.0.0.1:{PORT}"+path,
            data=json.dumps(body).encode(), headers={"Content-Type":"application/json"})
        with urllib.request.urlopen(req, timeout=5) as response:
            return json.load(response)
    def log_tail():
        return (output/"app.log").read_text(encoding="utf-8", errors="replace")[-5000:]
    try:
        with (output/"app.log").open("w", encoding="utf-8") as log:
            argv = [str(host), "-dasroot", str(das)]
            for module in modules: argv += ["-load_module",str(module)]
            argv += ["-no-module-cache",str(ROOT/"examples/live/03_widgets_recording.das"),"--live-port",str(PORT)]
            app = subprocess.Popen(argv, cwd=output, stdout=log, stderr=log)
            deadline = time.monotonic()+40
            while "SDL live acquired=1" not in log_tail():
                if app.poll() is not None or "initial compile FAILED" in log_tail():
                    raise RuntimeError("SDL host failed to start:\n"+log_tail())
                if time.monotonic()>deadline: raise RuntimeError("SDL startup timeout. See app.log.")
                time.sleep(.1)
            # Do not attach to an unrelated listener if another app raced our launch.
            if sys.platform == "darwin":
                listeners = subprocess.check_output(
                    ["/usr/sbin/lsof", "-nP", "-a", "-p", str(app.pid), "-iTCP", "-sTCP:LISTEN", "-Fn"], text=True)
                own = f"n127.0.0.1:{PORT}" in listeners.splitlines()
            else:
                listeners = subprocess.check_output(["netstat","-ano","-p","tcp"],text=True)
                own = any(len(p:=line.split())>=5 and p[1]==f"127.0.0.1:{PORT}" and p[3]=="LISTENING"
                          and p[-1]==str(app.pid) for line in listeners.splitlines())
            if not own: raise RuntimeError("Started host does not own the expected loopback listener. See app.log.")
            ready = True
            while True:
                if app.poll() is not None: raise RuntimeError("SDL host exited before recording.")
                state=http("/command",{"name":"demo_state"})
                if state.get("ticks",0)>2: break
                if time.monotonic()>deadline: raise RuntimeError("First frame timeout.")
                time.sleep(.1)
            print(f"Recording SDL on port {PORT}...",flush=True)
            with (output/"driver.log").open("w",encoding="utf-8") as driver_log:
                driver = subprocess.run([str(interpreter),"-dasroot",str(das),"-load_module",str(modules[1]),
                    "-ignore-manifest",str(ROOT/"examples/live/record_widgets.das"),"--","--output-root",str(output)],
                    cwd=output,stdout=driver_log,stderr=driver_log,timeout=90)
            if driver.returncode != 0: raise RuntimeError("Recording driver failed. See "+str(output/"driver.log"))
            status=http("/command",{"name":"record_status"})
            if status.get("active") or status.get("error") or status.get("frames",0)<=0:
                raise RuntimeError("Recording did not finish successfully: "+str(status))
            saved=assets/"sdl-widgets.apng"
            data=saved.read_bytes()
            if data[:8]!=b"\x89PNG\r\n\x1a\n" or data[-8:-4]!=b"IEND":
                raise RuntimeError("Incomplete APNG file.")
            # Ensure the writer patched acTL to the reported frame count.
            pos=8; count=None
            while pos+12<=len(data):
                size=struct.unpack_from(">I",data,pos)[0]
                if data[pos+4:pos+8]==b"acTL": count=struct.unpack_from(">I",data,pos+8)[0]
                pos+=size+12
            if count!=status["frames"]: raise RuntimeError("APNG frame-count mismatch.")
            destination=output/"sdl-widgets.apng"
            saved.replace(destination)
            print(f"Saved: {destination}\nFrames: {count}\nLogs: {output}",flush=True)
    finally:
        if app is not None and app.poll() is None:
            if ready:
                try:
                    http("/command",{"name":"record_stop"})
                    http("/shutdown",{})
                except (OSError, ValueError): pass
            try: app.wait(timeout=10)
            except subprocess.TimeoutExpired:
                app.kill()
                app.wait(timeout=5)
                print("Started host did not exit gracefully and was terminated; inspect app.log.",file=sys.stderr)
    if app.returncode != 0: raise RuntimeError(f"SDL host exited with code {app.returncode}. See app.log.")
    if log_tail().count("SDL live released=1 acquired=1") != 1:
        raise RuntimeError("Expected exactly-once SDL cleanup; inspect app.log.")
    return 0

if __name__ == "__main__":
    try: sys.exit(main())
    except KeyboardInterrupt:
        print("Recording interrupted.",file=sys.stderr)
        sys.exit(130)
    except (OSError, RuntimeError, subprocess.SubprocessError, ValueError) as error:
        print(f"Recording failed: {error}",file=sys.stderr)
        sys.exit(1)
