"""Guard the pinned P7 declaration/test-call census, alongside runtime CTests."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = {
    "Mutex": (28, "synchronization"),
    "Thread": (12, "thread_atomic"),
    "Atomic": (15, "thread_atomic"),
    "Process": (9, "process_loadso"),
    "SharedObject": (3, "process_loadso"),
    "System": (13, "platform_services"),
    "Power": (1, "platform_services"),
    "Locale": (1, "platform_services"),
    "Dialog": (4, "platform_services"),
    "Tray": (23, "platform_services"),
}

inventory = json.loads((ROOT / "docs/generated/api-windows-x64-msvc.json").read_text())
selected = set(json.loads((ROOT / "tools/bindings.json").read_text())["functions"])
total = 0
for category, (expected, script) in CATEGORIES.items():
    functions = [row for row in inventory["symbols"]
                 if row.get("kind") == "function" and row.get("category") == category]
    assert len(functions) == expected, (category, len(functions), expected)
    source = (ROOT / f"tests/{script}.das").read_text()
    source = re.sub(r"//[^\n]*|/\*.*?\*/", "", source, flags=re.S)
    for function in functions:
        name = function["name"]
        assert name in selected and function["raw_status"] == "generated", name
        assert re.search(r"\b" + re.escape(name) + r"\s*\(", source), (name, script)
    total += expected
print(f"P7: {total}/{total} active Windows declarations generated with direct test call sites.")
print("Runtime limits: Dialog invalid-filter/null-callback paths; X11 stub on Windows.")
