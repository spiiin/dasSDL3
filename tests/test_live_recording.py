"""Upstream with_recording_app -> SDL readback -> upstream streaming APNG writer."""
import argparse
import json
import os
from pathlib import Path
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import time
import urllib.request
import zlib

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--upstream-port", action="store_true", help="Test proposed port overload on a disposable module copy")
parser.add_argument("--visual-aids", action="store_true", help="Test backend-independent upstream visual overlays")
args = parser.parse_args()
if args.visual_aids: args.upstream_port = True
root = Path(__file__).resolve().parents[1]
das = root / "third_party/daScript"
output = root / ("build/live-visual-aids" if args.visual_aids else "build/live-recording-port" if args.upstream_port else "build/live-recording")
assets = output / "doc/source/_static/tutorials"
assets.mkdir(parents=True, exist_ok=True)
# Upstream with_recording_app attaches to a fixed port. Never reuse somebody else's app.
with socket.socket() as probe:
    probe.bind(("127.0.0.1", 0 if args.upstream_port else 9090))
    port = probe.getsockname()[1]

def http(path, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(f"http://127.0.0.1:{port}" + path, data=data, headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=5) as response:
        return json.load(response)

def command(name, args=None):
    return http("/command", {"name":name,"args":args or {}})

def validate(path, minimum=20, animated=True):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos, expected_sequence = 8, 0
    streams, controls = [], []
    while pos < len(data):
        size = struct.unpack_from(">I",data,pos)[0]
        kind = data[pos+4:pos+8]; payload = data[pos+8:pos+8+size]
        crc = struct.unpack_from(">I",data,pos+8+size)[0]
        assert zlib.crc32(kind+payload) == crc
        pos += size+12
        if kind == b"IHDR":
            header = payload
            w,h,depth,color,_,_,_ = struct.unpack(">IIBBBBB",payload)
            assert (w,h,depth,color) == (800,600,8,6)
        if kind == b"acTL": count,loops = struct.unpack(">II",payload)
        if kind in (b"fcTL",b"fdAT"):
            seq = struct.unpack_from(">I",payload)[0]
            assert seq == expected_sequence; expected_sequence += 1
        if kind == b"fcTL":
            controls.append(struct.unpack(">IIIIIHHBB",payload))
            streams.append(bytearray())
        if kind == b"IDAT": streams[-1].extend(payload)
        if kind == b"fdAT": streams[-1].extend(payload[4:])
        if kind == b"IEND": break
    assert pos == len(data) and kind == b"IEND"
    assert count == len(streams) and count >= minimum, count
    hashes = set()
    yellow = magenta = 0
    def chunk(kind,payload):
        return struct.pack(">I",len(payload))+kind+payload+struct.pack(">I",zlib.crc32(kind+payload))
    for i,(packed,ctl) in enumerate(zip(streams,controls)):
        _,fw,fh,x,y,n,d,dispose,blend = ctl
        assert (fw,fh,x,y) == (800,600,0,0)
        assert abs(n/(d or 100)-0.05) < 0.001
        raw = zlib.decompress(packed)
        assert len(raw) == 600*(800*4+1)
        assert all(raw[y*(800*4+1)] == 0 for y in range(600))
        hashes.add(zlib.crc32(raw))
        if args.visual_aids and animated:
            pixels = b"".join(raw[y*3201+1:(y+1)*3201] for y in range(600))
            yellow = max(yellow, sum(pixels[i]>200 and pixels[i+1]>200 and pixels[i+2]<80 for i in range(0,len(pixels),4)))
            magenta = max(magenta, sum(pixels[i]>150 and pixels[i+1]<100 and pixels[i+2]>150 for i in range(0,len(pixels),4)))
        if animated and i in (0,len(streams)-1):
            image = data[:8]+chunk(b"IHDR",header)+chunk(b"IDAT",bytes(packed))+chunk(b"IEND",b"")
            (output/("first.png" if i==0 else "last.png")).write_bytes(image)
    if animated: assert len(hashes) > 5, len(hashes)
    if args.visual_aids and animated:
        assert yellow > 100 and magenta > 20, (yellow,magenta)
        print(f"Visual pixels: highlight={yellow}, trail={magenta} PASS",flush=True)
    print(f"APNG CRC, {count} frames, 20 fps, {len(hashes)} distinct frames PASS",flush=True)
    return count

with tempfile.TemporaryDirectory(prefix="sdl-record-") as folder:
    for name in ("03_widgets_recording.das","sdl_recording.das","frame_recovery.das","loopback_http.das"):
        shutil.copyfile(root/"examples/live"/name,Path(folder)/name)
    driver_path = root/"examples/live/record_widgets.das"
    if args.upstream_port:
        relative = Path("modules/dasImgui/widgets/imgui_playwright.das")
        target = output/"upstream"/relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(das/relative, target)
        subprocess.run(["git", "apply", "--check", "--directory="+str((output/"upstream").relative_to(root)).replace("\\","/"),
            str(root/"patches/upstream/imgui-recording-port.patch")], cwd=root, check=True)
        subprocess.run(["git", "apply", "--directory="+str((output/"upstream").relative_to(root)).replace("\\","/"),
            str(root/"patches/upstream/imgui-recording-port.patch")], cwd=root, check=True)
        shutil.copyfile(target,Path(folder)/"imgui_playwright.das")
        driver = driver_path.read_text().replace("require imgui/imgui_playwright", "require ./imgui_playwright.das")
        driver = driver.replace("127.0.0.1:9090", f"127.0.0.1:{port}")
        driver = driver.replace('no_modules, ".", output)', f'no_modules, ".", output, {port})')
        driver_path = Path(folder)/"record_driver.das"
        driver_path.write_text(driver)
    if args.visual_aids:
        relative = Path("modules/dasImgui/widgets/imgui_visual_aids.das")
        target = output/"upstream"/relative
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(das/relative,target)
        subprocess.run(["git","apply","--directory="+(output/"upstream").relative_to(root).as_posix(),
            str(root/"patches/upstream/imgui-visual-aids-backend.patch")],cwd=root,check=True)
        shutil.copyfile(target,Path(folder)/"imgui_visual_aids.das")
        app_script = Path(folder)/"03_widgets_recording.das"
        app_script.write_text(app_script.read_text().replace("require ./sdl_recording.das", "require ./sdl_recording.das\nrequire ./imgui_visual_aids.das"))
        adapter = Path(folder)/"sdl_recording.das"
        adapter.write_text(adapter.read_text().split("// Upstream visual_aids imports")[0])
        driver=driver_path.read_text()
        overlay = '        record_check(app, "highlight accepted", post_command(app, "imgui_highlight", JV((target = "MAIN/SPEED", frames = 180)))?["ok"] ?? false)\n'
        overlay += '        record_check(app, "trail accepted", post_command(app, "imgui_mouse_trail", JV((enabled = true, color = 4294902015u)))?["ok"] ?? false)\n'
        overlay += '        record_check(app, "caption accepted", post_command(app, "imgui_narrate", JV((text = "SDL drag and click", target = "MAIN/SPEED", frames = 180)))?["ok"] ?? false)\n'
        driver_path.write_text(driver.replace("        hold_content(app, 500u)", overlay+"        hold_content(app, 500u)",1))
    log = (output/"app.log").open("w",encoding="utf-8")
    app = subprocess.Popen([str(root/"build/ninja/live/dasSDL3_live.exe"),"-dasroot",str(das),
        "-load_module",str(root/"build/ninja/live/module"),"-load_module",str(root/"build/live-http/dasHV"),
        "-load_module",str(root/"build/live-http/dasStbImage"),"-no-module-cache",
        str(Path(folder)/"03_widgets_recording.das"),"--live-port",str(port)],cwd=folder,
        stdout=log,stderr=log,env=dict(os.environ,SDL_RENDER_DRIVER="software"))
    try:
        deadline=time.monotonic()+35
        while True:
            assert "initial compile FAILED" not in (output/"app.log").read_text(), (output/"app.log").read_text()
            assert app.poll() is None, (output/"app.log").read_text()
            try:
                state=command("demo_state")
                if state.get("ticks",0)>2: break
            except (OSError,ValueError): pass
            assert time.monotonic()<deadline, (output/"app.log").read_text()
            time.sleep(.1)
        driver=subprocess.run([str(das/"bin/daslang.exe"),"-dasroot",str(das),"-load_module",
            str(root/"build/live-http/dasHV"),"-ignore-manifest",str(driver_path),
            "--","--output-root",str(output)],cwd=folder,capture_output=True,text=True,timeout=80)
        (output/"driver.log").write_text(driver.stdout+driver.stderr,encoding="utf-8")
        assert driver.returncode==0 and "recording PASS" in driver.stdout, driver.stdout+driver.stderr
        after=command("demo_state")
        assert after["clicks"]==state["clicks"]+1 and abs(after["speed"]-state["speed"])>.05
        status=command("record_status")
        assert not status["active"] and not status["error"],status
        count=validate(assets/"sdl-widgets.apng")
        assert count==status["frames"],status
        assert "error" in command("record_start", {"fps":0})
        assert "error" in command("record_start", {"file":str(output/"missing/fail.apng")})
        assert not command("record_status")["active"]
        # A frame cap closes and patches the APNG without an explicit stop.
        capped=output/"capped.apng"
        # A separate client starts capture and fails before record_stop.
        # HTTP is stateless: the recorder must finish through its frame cap.
        start_payload=json.dumps({"name":"record_start","args":{"file":str(capped),"fps":20,"max_seconds":1}})
        client_code = "import sys,urllib.request; req=urllib.request.Request(sys.argv[1],data=sys.argv[2].encode(),headers={'Content-Type':'application/json'}); print(urllib.request.urlopen(req,timeout=5).read().decode(),flush=True); sys.exit(7)"
        abandoned=subprocess.run([sys.executable,"-c",client_code,f"http://127.0.0.1:{port}/command",start_payload],capture_output=True,text=True,timeout=10)
        assert abandoned.returncode==7 and "error" not in json.loads(abandoned.stdout),abandoned.stdout+abandoned.stderr
        assert "error" in command("record_start", {"file":str(output/"duplicate.apng")})
        deadline=time.monotonic()+15
        while command("record_status")["active"]:
            assert time.monotonic()<deadline
            time.sleep(.1)
        assert validate(capped,20,False)==20
        # Reload must finalize an active writer before replacing its script context.
        interrupted=output/"reload.apng"
        command("record_start", {"file":str(interrupted),"fps":20,"max_seconds":10})
        deadline=time.monotonic()+15
        while command("record_status")["frames"]<3:
            assert time.monotonic()<deadline
            time.sleep(.1)
        generation=http("/status")["generation"]
        http("/reload",{})
        while http("/status")["generation"]<=generation:
            assert time.monotonic()<deadline
            time.sleep(.1)
        assert not command("record_status")["active"]
        validate(interrupted,3,False)
        print("Invalid/duplicate start, failed client frame cap and reload finalization PASS",flush=True)
        final_capture=output/"shutdown.apng"
        assert "error" not in command("record_start", {"file":str(final_capture),"fps":20,"max_seconds":10})
        deadline=time.monotonic()+15
        while command("record_status")["frames"]<3:
            assert time.monotonic()<deadline
            time.sleep(.1)
        http("/shutdown",{})
        assert app.wait(timeout=15)==0
        validate(final_capture,3,False)
        print("Active recording finalized by application shutdown PASS",flush=True)
    finally:
        if app.poll() is None: app.kill();app.wait(timeout=10)
        log.close()
    text=(output/"app.log").read_text()
    assert text.count("SDL live released=1 acquired=1")==1 and "leaked" not in text,text[-2000:]
    print("Upstream recording + SDL cleanup PASS",flush=True)
