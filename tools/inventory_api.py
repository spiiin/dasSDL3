"""Inventory the active SDL API of an explicit target profile using Clang.

AST declarations and preprocessor definitions are separate kinds. This is not
a cross-platform census: inactive declarations remain outside the denominator.
Every input header is hashed and listed, including unobserved/excluded headers.
No absolute paths or timestamps are stored in generated output.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
KINDS = {"FunctionDecl": "function", "RecordDecl": "record",
         "EnumDecl": "enum", "EnumConstantDecl": "enumerator",
         "TypedefDecl": "typedef"}


def public_name(name):
    return bool(re.fullmatch(r"(?:SDL_\w+|SDLK_\w+|KMOD_\w+|[US]int(?:8|16|32|64))", name))


def run(command, source):
    result = subprocess.run(command, input=source, capture_output=True,
                            text=True, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout


def header_name(filename, include):
    if not filename or filename.startswith("<"):
        return None
    try:
        return Path(filename).resolve().relative_to(include / "SDL3").as_posix()
    except ValueError:
        return None


def macro_inventory(text, include):
    """Honor line markers and #undef; preserve function-like macro spelling."""
    current, line = None, 0
    macros, observed = {}, set()
    for raw in text.splitlines():
        marker = re.match(r'^# (\d+) "([^"]+)"', raw)
        if marker:
            line = int(marker[1])
            current = header_name(marker[2].replace("\\\\", "\\"), include)
            if current:
                observed.add(current)
            continue
        define = re.match(r"#define (\w+)(.*)", raw)
        undef = re.match(r"#undef (\w+)", raw)
        if undef:
            macros.pop(undef[1], None)
        if define:
            name, tail = define.groups()
            # Include guards aren't API. Other compiler macros are classified by policy.
            if public_name(name) and not name.endswith("_h_"):
                macros[name] = {"name": name, "kind": "macro", "header": current,
                                "line": line, "definition": tail.strip(),
                                "function_like": tail.startswith("(")}
        line += 1
    return [v for v in macros.values() if v["header"]], observed


def ast_inventory(tree, include, contents):
    symbols = {}
    last_file = None

    def visit(node, inherited=None):
        nonlocal last_file
        loc = node.get("loc", {})
        loc = loc.get("expansionLoc", loc)
        # Clang elides repeated source-file names in JSON locations.
        if "file" in loc:
            last_file = loc["file"]
        filename = loc.get("file", inherited or last_file)
        header = header_name(filename, include)
        kind, name = KINDS.get(node.get("kind")), node.get("name", "")
        if header and kind and public_name(name) and not node.get("isImplicit"):
            offset = loc.get("offset", 0)
            line = loc.get("line") or contents[header][:offset].count(b"\n") + 1
            item = {"name": name, "kind": kind, "header": header, "line": line}
            if "type" in node:
                item["c_type"] = node["type"]["qualType"]
            if kind == "function":
                item["variadic"] = bool(node.get("variadic"))
                item["arguments"] = [
                    {"name": child.get("name", ""), "c_type": child["type"]["qualType"]}
                    for child in node.get("inner", []) if child.get("kind") == "ParmVarDecl"]
            if kind == "record":
                item["complete"] = bool(node.get("completeDefinition"))
                item["tag"] = node.get("tagUsed", "struct")
                item["fields"] = [
                    {"name": child.get("name", ""), "c_type": child["type"]["qualType"]}
                    for child in node.get("inner", []) if child.get("kind") == "FieldDecl"]
            if kind == "typedef":
                item["callback"] = "(*" in item["c_type"] or "(__attribute__" in item["c_type"] and "*" in item["c_type"]
            key = (kind, name)
            if key not in symbols or item.get("complete"):
                symbols[key] = item
        # Body expressions and parameter declarations cannot declare public SDL API.
        for child in node.get("inner", []):
            if child.get("kind") in (*KINDS, "LinkageSpecDecl"):
                visit(child, filename)

    for node in tree.get("inner", []):
        visit(node)
    return list(symbols.values())


def exclusion(header, policy):
    if header in policy["excluded_headers"]:
        return policy["excluded_headers"][header]
    for prefix, reason in policy["excluded_header_prefixes"].items():
        if header.startswith(prefix):
            return reason
    return None


def annotate(symbols, spec, policy, categories):
    seen = set()
    for item in symbols:
        name, kind = item["name"], item["kind"]
        key = f"{kind}:{name}"
        seen.add(key)
        item["id"] = key
        item["category"] = categories[item["header"]]
        item["raw_status"] = "pending"
        item["boost_status"] = "unreviewed"
        reason = exclusion(item["header"], policy)
        if reason:
            item.update(raw_status="excluded", reason=reason)
        elif kind == "function" and name in spec["functions"]:
            item["raw_status"] = "generated"
        elif kind in ("macro", "enumerator") and name in spec["constants"]:
            item["raw_status"] = "generated"
        elif kind in ("enum", "typedef") and name in spec.get("enums", {}):
            item["raw_status"] = "generated"
        elif kind == "enumerator" and any(name in members for members in spec.get("enums", {}).values()):
            item["raw_status"] = "generated"
        elif kind in ("record", "typedef") and name in spec["opaque_types"]:
            item["raw_status"] = "opaque"
        elif kind in ("record", "typedef") and name in spec["structs"]:
            item["raw_status"] = "partial"
            item["exposed_fields"] = spec["structs"][name]
        override = policy["symbols"].get(key, {})
        allowed = {"raw_status", "boost_status", "reason", "adapter", "tests", "contract"}
        if set(override) - allowed:
            raise RuntimeError(f"Unknown policy fields for {key}: {set(override) - allowed}")
        if override.get("raw_status") not in (None, "adapted", "pending", "excluded"):
            raise RuntimeError(f"Policy cannot claim generated coverage: {key}")
        if override.get("raw_status") in ("adapted", "excluded") and not override.get("reason"):
            raise RuntimeError(f"Policy requires reason: {key}")
        item.update(override)
    unknown = set(policy["symbols"]) - seen
    if unknown:
        raise RuntimeError(f"Policy symbols absent from this profile: {sorted(unknown)}")
    missing = set(spec["functions"]) - {s["name"] for s in symbols if s["kind"] == "function"}
    if missing:
        raise RuntimeError(f"Generated functions absent from census: {sorted(missing)}")
    constants = {s["name"] for s in symbols if s["kind"] in ("macro", "enumerator")}
    types = {s["name"] for s in symbols if s["kind"] in ("record", "typedef", "enum")}
    if set(spec["constants"]) - constants:
        raise RuntimeError(f"Generated constants absent from census: {sorted(set(spec['constants']) - constants)}")
    required_types = (set(spec["opaque_types"]) | set(spec["structs"]) | set(spec.get("enums", {}))) - set(policy.get("project_types", {}))
    if required_types - types:
        raise RuntimeError(f"Generated types absent from census: {sorted(required_types - types)}")
    return sorted(symbols, key=lambda item: item["id"])


def generate(clang, include, profile_name, policy, spec):
    profile = policy["profiles"][profile_name]
    contents = {path.name: path.read_bytes() for path in sorted((include / "SDL3").glob("*.h"))}
    version_text = contents["SDL_version.h"].decode("utf-8")
    version = ".".join(re.search(rf"#define SDL_{part}_VERSION\s+(\d+)", version_text)[1]
                       for part in ("MAJOR", "MINOR", "MICRO"))
    if version != policy["sdl_version"]:
        raise RuntimeError(f"Expected SDL {policy['sdl_version']}, found {version}")
    source = "".join(f"#include <SDL3/{name}>\n" for name in profile["entry_headers"])
    base = [clang, "-x", "c", "-std=c11", "--target=" + profile["target"],
            "-Wno-pragma-pack", "-I", str(include)] + ["-D" + d for d in profile["defines"]]
    ast = json.loads(run(base + ["-fsyntax-only", "-Xclang", "-ast-dump=json", "-"], source))
    macros, observed = macro_inventory(run(base + ["-E", "-dD", "-"], source), include)
    categories = {}
    for name, data in contents.items():
        match = re.search(r"# Category(\w+)", data.decode("utf-8"))
        categories[name] = match[1] if match else name.removeprefix("SDL_").removesuffix(".h")
    symbols = annotate(ast_inventory(ast, include, contents) + macros, spec, policy, categories)
    headers = [{"header": name, "sha256": hashlib.sha256(data).hexdigest(),
                "category": categories[name], "observed": name in observed,
                "status": "excluded" if exclusion(name, policy) else "observed" if name in observed else "unobserved",
                "reason": exclusion(name, policy)} for name, data in contents.items()]
    compiler = run([clang, "--version"], "").splitlines()[0]
    return {"schema_version": 1, "sdl_version": version, "profile": profile_name,
            "compiler": compiler, "target": profile["target"], "defines": profile["defines"],
            "entry_headers": profile["entry_headers"],
            "project_types": policy.get("project_types", {}),
            "scope": "Active declarations/macros only; inactive platform branches are NOT counted. Record and typedef entries are distinct declarations.",
            "headers": headers, "symbols": symbols}


def report(data):
    symbols = data["symbols"]
    functions = [s for s in symbols if s["kind"] == "function" and s["raw_status"] != "excluded"]
    generated = sum(s["raw_status"] == "generated" for s in functions)
    lines = ["# SDL API inventory (generated)", "", f"SDL {data['sdl_version']}; profile `{data['profile']}`.",
             "", data["scope"], "", f"Generated functions: **{generated}/{len(functions)}** active non-excluded functions.",
             "Adapted coverage and boost coverage are not inferred from function names.", "",
             "| Category | Functions | Generated | Adapted | Pending |", "| --- | ---: | ---: | ---: | ---: |"]
    for category in sorted({s["category"] for s in functions}):
        group = [s for s in functions if s["category"] == category]
        lines.append(f"| {category} | {len(group)} | {sum(s['raw_status'] == 'generated' for s in group)} | {sum(s['raw_status'] == 'adapted' for s in group)} | {sum(s['raw_status'] == 'pending' for s in group)} |")
    lines += ["", "Declaration counts (including explicitly excluded scaffolding):", ""]
    lines += [f"- {kind}: {count}" for kind, count in sorted(Counter(s["kind"] for s in symbols).items())]
    lines += ["", "Unobserved, non-excluded headers (must be reviewed, not silently ignored):", ""]
    lines += [f"- `{h['header']}`" for h in data["headers"] if h["status"] == "unobserved"] or ["- None. Inactive branches inside observed headers still require other profiles."]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--clang", default="clang")
    parser.add_argument("--sdl-include", type=Path, required=True)
    parser.add_argument("--profile", default="windows-x64-msvc")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "docs/generated")
    args = parser.parse_args()
    policy = json.loads((ROOT / "tools/api-policy.json").read_text(encoding="utf-8"))
    spec = json.loads((ROOT / "tools/bindings.json").read_text(encoding="utf-8"))
    data = generate(args.clang, args.sdl_include.resolve(), args.profile, policy, spec)
    files = {args.output_dir / f"api-{args.profile}.json": json.dumps(data, indent=2, ensure_ascii=False) + "\n",
             args.output_dir / f"api-{args.profile}.md": report(data)}
    for path, content in files.items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                raise RuntimeError(f"Stale inventory: {path}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
    print(f"SDL {data['sdl_version']}: {len(data['symbols'])} declarations/macros; {len(data['headers'])} headers; "
          + ("inventory is up to date" if args.check else "inventory written"))


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, KeyError) as error:
        sys.exit(str(error))
