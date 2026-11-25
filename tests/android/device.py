"""Run the installed dasSDL3 smoke APK on one ADB device."""
import argparse
import re
import subprocess
import time
import uuid
from pathlib import Path


PACKAGE = "org.dassdl3.smoke"
ACTIVITY = PACKAGE + "/.SmokeActivity"


class Device:
    def __init__(self, adb, serial):
        self.prefix = [adb, "-s", serial]
        self.marker = ""

    def adb(self, *args, timeout=20):
        return subprocess.check_output([*self.prefix, *args], text=True,
                                       encoding="utf-8", errors="replace", timeout=timeout).strip()

    def launch(self, mode):
        self.adb("shell", "am", "force-stop", PACKAGE)
        self.marker = uuid.uuid4().hex
        self.adb("shell", "log", "-t", "dasSDL3Launch", self.marker)
        arguments = ("--es", "mode", mode) if mode != "smoke" else ()
        result = self.adb("shell", "am", "start", "-W", "-n", ACTIVITY, *arguments)
        if "Status: ok" not in result:
            raise RuntimeError(result)

    def wait(self, pattern, timeout=60, *tags, accept=None):
        end = time.monotonic() + timeout
        log = ""
        while time.monotonic() < end:
            buf = self.adb("logcat", "-d", "-s", "dasSDL3Launch:I", "SDL/APP:I", "AndroidRuntime:E", "libc:F", *tags)
            _, marker, log = buf.rpartition(self.marker)
            if marker:
                for match in re.finditer(pattern, log):
                    if accept is not None and not accept(match):
                        continue
                    print(match.group(), flush=True)
                    return match
                if " FAIL" in log or "FATAL EXCEPTION" in log or "Fatal signal" in log:
                    raise RuntimeError(log[-6000:])
            time.sleep(0.5)
        raise RuntimeError(f"Timed out waiting for {pattern}\n{log[-6000:]}")

    def check_square(self, mode):
        self.launch(mode)
        first = self.wait(r"dasSDL3 Android square [^\n]+ frame=\d+ pixels=(\d+)x(\d+) resumes=0")
        width, height = map(int, first.groups())
        pid = self.adb("shell", "pidof", PACKAGE)
        saved = self.adb("shell", "wm", "user-rotation").split()
        if saved not in (["free"], ["lock", "0"], ["lock", "1"], ["lock", "2"], ["lock", "3"]):
            raise RuntimeError(f"Unrecognized rotation state: {saved}")
        try:
            self.adb("shell", "wm", "user-rotation", "lock", "1" if height > width else "0")
            # System bars and cutouts can reserve different pixels after rotation.
            self.wait(r"dasSDL3 Android square [^\n]+ pixels=(\d+)x(\d+) resumes=\d+",
                      accept=lambda m: (int(m[1]) > int(m[2])) != (width > height))
        finally:
            self.adb("shell", "wm", "user-rotation", *saved)
        self.adb("shell", "am", "start", "-W", "-a", "android.intent.action.MAIN",
                 "-c", "android.intent.category.HOME")
        self.wait(rf"\s{pid}\s+\d+ V SDL\s*:\s+onStop\(\)", 15, "SDL:V")
        self.adb("shell", "am", "start", "-W", "-n", ACTIVITY)
        self.wait(r"dasSDL3 Android square [^\n]+ resumes=[1-9]\d*")
        if self.adb("shell", "pidof", PACKAGE) != pid:
            raise RuntimeError("Activity returned in a different process")

    def check_live(self):
        # A dedicated test slot leaves a developer's live.das override intact.
        slot = "files/dassdl3-live-test.das"
        cleanup = f"run-as {PACKAGE} rm -f {slot}.tmp {slot}"
        self.adb("shell", cleanup)
        try:
            self.launch("live-test")
            first = self.wait(r"live initial generation=0 window=(\d+) rgb=24,96,64")
            window = first.group(1)
            pid = self.adb("shell", "pidof", PACKAGE)
            source = (Path(__file__).resolve().parents[2] / "android/live.das").read_bytes()
            for contents, status, generation, blue in (
                (source.replace(b"64u,", b"192u,"), "loaded", 1, 192),
                (b"this script contains a syntax error\n", "rejected", 1, 192),
                (source.replace(b"64u,", b"128u,"), "loaded", 2, 128),
            ):
                command = f"run-as {PACKAGE} sh -c 'cat > {slot}.tmp && mv {slot}.tmp {slot}'"
                subprocess.run([*self.prefix, "shell", "-T", command], input=contents,
                               check=True, timeout=20)
                self.wait(rf"live {status} generation={generation} window={window} rgb=24,96,{blue}")
                if self.adb("shell", "pidof", PACKAGE) != pid:
                    raise RuntimeError("Live reload restarted the process")
        finally:
            self.adb("shell", cleanup)

    def check_lock(self):
        self.launch("square-aot")
        self.wait(r"square strict AOT frame=\d+ pixels=\d+x\d+ resumes=0")
        pid = self.adb("shell", "pidof", PACKAGE)
        print("Lock the phone, then unlock it and return to the square.", flush=True)
        self.wait(rf"\s{pid}\s+\d+ V SDL\s*:\s+onStop\(\)", 180, "SDL:V")
        self.wait(r"square strict AOT frame=\d+ pixels=\d+x\d+ resumes=[1-9]\d*", 180)
        if self.adb("shell", "pidof", PACKAGE) != pid:
            raise RuntimeError("Lock and unlock restarted the process")

    def check_consumer(self, stage):
        stage = Path(stage).resolve()
        for name in ("android_consumer", "libSDL3.so", "libc++_shared.so", "app/hello.das"):
            if not (stage / name).is_file():
                raise RuntimeError(f"Missing {name} in the staged consumer")
        remote = "/data/local/tmp/dassdl3-consumer-" + uuid.uuid4().hex
        self.adb("shell", "mkdir", remote)
        try:
            self.adb("push", str(stage) + "/.", remote, timeout=120)
            self.adb("shell", "chmod", "700", remote + "/android_consumer")
            stdout = self.adb("shell", f"cd {remote} && LD_LIBRARY_PATH=. ./android_consumer", timeout=60)
            if "Independent Android strict AOT consumer PASS" not in stdout:
                raise RuntimeError(stdout)
            print(stdout, flush=True)
        finally:
            self.adb("shell", "rm", "-r", remote)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", required=True)
    parser.add_argument("--consumer-stage", default="build/android-consumer-stage")
    parser.add_argument("modes", nargs="+", choices=("square", "square-aot", "storage-write", "storage-read",
                                                     "vulkan", "vulkan-screen", "imgui", "imgui-v2", "live-test",
                                                     "imgui-input", "imgui-v2-input", "multitouch", "unicode-input", "lock", "smoke",
                                                     "image", "ttf", "net", "mixer", "sound", "sensors", "playback",
                                                     "camera", "microphone", "camera-denied", "microphone-denied", "consumer"))
    args = parser.parse_args()
    device = Device(args.adb, args.serial)
    for mode in args.modes:
        if mode in ("square", "square-aot"):
            device.check_square(mode)
        elif mode == "live-test":
            device.check_live()
        elif mode == "lock":
            device.check_lock()
        elif mode == "consumer":
            device.check_consumer(args.consumer_stage)
        elif mode == "vulkan-screen":
            device.launch(mode)
            device.wait(r"vulkan-screen first frame PASS driver=vulkan strict AOT")
        else:
            device.launch(mode)
            interactive = mode.endswith("-input") or mode.startswith(("camera", "microphone")) or mode in ("sensors", "multitouch")
            device.wait(rf"dasSDL3 Android {mode} PASS", 300 if interactive else 60)


if __name__ == "__main__":
    main()
