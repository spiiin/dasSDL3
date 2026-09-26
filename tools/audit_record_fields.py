"""Audit named, complete SDL records against direct fields and reviewed adapter policy."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
STATUSES = {"adapted", "native_callback", "partial", "pending", "host_only", "internal", "tag"}


def audit(data, spec, policy, root=ROOT):
    if policy["sdl_version"] != data["sdl_version"] or policy["profile"] != data["profile"]:
        raise RuntimeError("Record policy pin/profile mismatch")
    decisions = {}
    registration = (root / "src/module_sdl3.cpp").read_text(encoding="utf-8")
    for group in policy["groups"]:
        if group["status"] not in STATUSES or not group.get("reason") or not group.get("sources"):
            raise RuntimeError("Invalid field decision: " + group["record"])
        for source in group["sources"]:
            if not (root / source).is_file():
                raise RuntimeError("Missing field evidence: " + source)
        entries = group.get("entry_points", [])
        if group["status"] in {"adapted", "native_callback", "partial"} and not entries:
            raise RuntimeError("Adapter decision requires entry points: " + group["record"])
        for entry in entries:
            if entry not in spec["functions"] and ('"' + entry + '"') not in registration:
                raise RuntimeError("Adapter is not registered: " + entry)
        for field in group["fields"]:
            key = group["record"] + "." + field
            if key in decisions:
                raise RuntimeError("Duplicate field decision: " + key)
            decisions[key] = {k: group[k] for k in ("status", "reason", "sources", "entry_points")}
    rows, records = [], []
    for record in data["symbols"]:
        if record["kind"] != "record" or not record.get("complete"):
            continue
        records.append(record["name"])
        direct = set(spec["structs"].get(record["name"], []))
        native = {f["name"] for f in record["fields"]}
        if direct - native:
            raise RuntimeError("Bound field missing from native record: " + record["name"])
        for field in record["fields"]:
            key = record["name"] + "." + field["name"]
            if field["name"] in direct:
                decision = {"status": "direct"}
            else:
                if key not in decisions:
                    raise RuntimeError("Unreviewed field: " + key)
                decision = decisions.pop(key)
            # Anonymous union spelling contains a machine-local absolute header path.
            c_type = re.sub(r"at [^)]*[\\/](SDL_[A-Za-z0-9_]+\.h:\d+:\d+)", r"at \1", field["c_type"])
            rows.append({"record": record["name"], "field": field["name"], "c_type": c_type,
                         "callback": "(*" in field["c_type"], **decision})
    if decisions:
        raise RuntimeError("Stale field decisions: " + ", ".join(sorted(decisions)))
    rows.sort(key=lambda x: (x["record"], x["field"]))
    return {"sdl_version": data["sdl_version"], "profile": data["profile"],
            "record_count": len(records), "field_count": len(rows),
            "counts": dict(sorted(Counter(x["status"] for x in rows).items())), "fields": rows}


def report(data):
    rows = data["fields"]
    lines = ["# SDL record field accessibility (generated)", "",
             f"SDL {data['sdl_version']}; {data['profile']}; {data['record_count']} named complete native records, {data['field_count']} top-level fields.", "",
             "Direct means listed in bindings.json; other decisions are explicit in tools/record-field-policy.json.",
             "Adapter evidence is static registration/source verification, not a new runtime guarantee.",
             "Opaque forward declarations, nested anonymous-union interiors, project records and other platforms are outside this census.", "",
             "| Status | Fields |", "| --- | ---: |"]
    lines += [f"| {key} | {value} |" for key, value in data["counts"].items()]
    lines += ["", "## Callback slots", "", "| Field | Status | Entry point / decision |", "| --- | --- | --- |"]
    for row in rows:
        if row["callback"]:
            evidence = ", ".join(row.get("entry_points", [])) or row.get("reason", "direct")
            lines.append(f"| `{row['record']}.{row['field']}` | {row['status']} | {evidence} |")
    lines += ["", "## All non-direct fields", "", "| Field | Status | Reason |", "| --- | --- | --- |"]
    for row in rows:
        if row["status"] != "direct":
            lines.append(f"| `{row['record']}.{row['field']}` | {row['status']} | {row['reason']} |")
    return "\n".join(lines) + "\n"


def generate(root=ROOT):
    load = lambda p: json.loads((root / p).read_text(encoding="utf-8"))
    return audit(load("docs/generated/api-windows-x64-msvc.json"), load("tools/bindings.json"),
                 load("tools/record-field-policy.json"), root)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = generate()
    outputs = {"record-fields-windows-x64-msvc.json": json.dumps(data, indent=2) + "\n",
               "record-fields-windows-x64-msvc.md": report(data)}
    for name, text in outputs.items():
        path = ROOT / "docs/generated" / name
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != text:
                raise RuntimeError("Stale record field audit: " + str(path))
        else:
            path.write_text(text, encoding="utf-8", newline="\n")
    print(f"Record fields: {data['record_count']} records, {data['field_count']} fields; {data['counts']}")


if __name__ == "__main__":
    main()
