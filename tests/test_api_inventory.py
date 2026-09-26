"""Contract tests with real Clang, using a tiny synthetic SDL header tree."""
import argparse
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
module_spec = importlib.util.spec_from_file_location("inventory", ROOT / "tools/inventory_api.py")
inventory = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(inventory)
CLANG = "clang"


class InventoryContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.include = Path(self.temp.name)
        headers = self.include / "SDL3"
        headers.mkdir()
        (headers / "SDL_version.h").write_text(
            "#define SDL_MAJOR_VERSION 3\n#define SDL_MINOR_VERSION 2\n#define SDL_MICRO_VERSION 18\n")
        (headers / "SDL_detail.h").write_text("""
// # CategoryGPU
#define SDL_HIGH_BIT (1ULL << 63)
#define SDL_SUM(a,b) ((a)+(b))
#define SDL_REMOVED 1
#undef SDL_REMOVED
typedef struct SDL_Buffer { int length; float data[4]; } SDL_Buffer;
typedef void (*SDL_Notify)(void *user, int status);
typedef unsigned long long Uint64;
enum SDL_Mode { SDL_MODE_A=0, SDL_MODE_B=4 };
int SDL_Second(SDL_Buffer *buffer);
#if defined(_WIN32)
int SDL_Windows(void);
#else
int SDL_OtherPlatform(void);
#endif
""")
        (headers / "SDL.h").write_text("""
// # CategoryInit
#include <SDL3/SDL_version.h>
#include <SDL3/SDL_detail.h>
int SDL_First(int n);
int SDL_First(int n);
int SDL_LogLike(const char *format, ...);
int unrelated_function(void);
""")
        (headers / "SDL_unseen.h").write_text("int SDL_Unseen(void);\n")
        self.policy = {"sdl_version": "3.2.18", "profiles": {"test": {
            "target": "x86_64-pc-windows-msvc", "defines": [], "entry_headers": ["SDL.h"]}},
            "excluded_headers": {}, "excluded_header_prefixes": {}, "symbols": {}}
        self.spec = {"functions": ["SDL_First"], "constants": {"SDL_HIGH_BIT": "uint64_t"},
                     "opaque_types": ["SDL_ProjectOwner"], "structs": {"SDL_Buffer": ["length"]}}
        self.policy["project_types"] = {"SDL_ProjectOwner": {
            "native_header": "src/owner.h", "reason": "Project wrapper, not part of SDL"}}

    def generate(self):
        return inventory.generate(CLANG, self.include, "test", self.policy, self.spec)

    def test_active_api_and_locations(self):
        data = self.generate()
        symbols = {s["id"]: s for s in data["symbols"]}
        self.assertEqual(symbols["function:SDL_First"]["header"], "SDL.h")
        self.assertEqual(symbols["function:SDL_Second"]["category"], "GPU")
        self.assertEqual(symbols["function:SDL_First"]["raw_status"], "generated")
        self.assertEqual(symbols["record:SDL_Buffer"]["raw_status"], "partial")
        self.assertTrue(symbols["typedef:SDL_Notify"]["callback"])
        self.assertTrue(symbols["function:SDL_LogLike"]["variadic"])
        self.assertIn("function:SDL_Windows", symbols)
        self.assertNotIn("function:SDL_OtherPlatform", symbols)
        self.assertNotIn("function:unrelated_function", symbols)
        self.assertNotIn("record:SDL_ProjectOwner", symbols)
        self.assertIn("SDL_ProjectOwner", data["project_types"])
        self.assertNotIn("macro:SDL_REMOVED", symbols)
        self.assertTrue(symbols["macro:SDL_SUM"]["function_like"])
        self.assertEqual(symbols["macro:SDL_HIGH_BIT"]["definition"], "(1ULL << 63)")
        self.assertEqual(symbols["record:SDL_Buffer"]["fields"][1]["c_type"], "float[4]")
        self.assertEqual(len([s for s in data["symbols"] if s["id"] == "function:SDL_First"]), 1)
        self.assertNotIn(str(self.include), json.dumps(data))
        for symbol in data["symbols"]:
            lines = (self.include / "SDL3" / symbol["header"]).read_text().splitlines()
            self.assertIn(symbol["name"], lines[symbol["line"] - 1])
        unseen = next(h for h in data["headers"] if h["header"] == "SDL_unseen.h")
        self.assertEqual(unseen["status"], "unobserved")
        self.assertEqual(data, self.generate())

    def test_native_vulkan_types_are_header_declarations(self):
        header = self.include / "SDL3/SDL_vulkan.h"
        header.write_text("// # CategoryVulkan\n"
                          "typedef struct VkInstance_T *VkInstance;\n"
                          "struct VkAllocationCallbacks;\n"
                          "int VkUnrelatedFunction(void);\n")
        self.policy["profiles"]["test"]["entry_headers"].append("SDL_vulkan.h")
        self.spec["opaque_types"].extend(["VkInstance_T", "VkAllocationCallbacks"])
        symbols = {s["id"]: s for s in self.generate()["symbols"]}
        self.assertEqual(symbols["record:VkInstance_T"]["raw_status"], "opaque")
        self.assertEqual(symbols["record:VkAllocationCallbacks"]["category"], "Vulkan")
        self.assertEqual(symbols["typedef:VkInstance"]["header"], "SDL_vulkan.h")
        self.assertNotIn("function:VkUnrelatedFunction", symbols)

    def test_wrong_release_rejected(self):
        self.policy["sdl_version"] = "3.4.0"
        with self.assertRaisesRegex(RuntimeError, "Expected SDL"):
            self.generate()

    def test_removed_export_fails_instead_of_inflating_coverage(self):
        original = copy.deepcopy(self.spec)
        for kind in ("functions", "constants", "opaque_types"):
            with self.subTest(kind=kind):
                self.spec = copy.deepcopy(original)
                if kind == "constants":
                    self.spec[kind]["SDL_Missing"] = "int"
                else:
                    self.spec[kind].append("SDL_Missing")
                with self.assertRaisesRegex(RuntimeError, "absent from census"):
                    self.generate()

    def test_unknown_or_unjustified_policy_rejected(self):
        data = self.generate()
        categories = {h["header"]: h["category"] for h in data["headers"]}
        for key, override in [("function:SDL_Gone", {"raw_status": "pending"}),
                              ("function:SDL_First", {"raw_status": "excluded"}),
                              ("function:SDL_First", {"raw_status": "generated"}),
                              ("function:SDL_First", {"typo": True})]:
            with self.subTest(key=key, override=override):
                self.policy["symbols"] = {key: override}
                with self.assertRaises(RuntimeError):
                    inventory.annotate(copy.deepcopy(data["symbols"]), self.spec, self.policy, categories)

    def test_script_disposition_validation_and_coverage(self):
        data = self.generate()
        categories = {h["header"]: h["category"] for h in data["headers"]}
        decision = {"script_disposition": "stdlib", "reason": "Language alternative",
                    "contract": "docs/stdinc-policy.md"}
        before = {s["id"]: s["raw_status"] for s in data["symbols"]}
        self.policy["symbols"] = {"function:SDL_Second": decision}
        reviewed = inventory.annotate(copy.deepcopy(data["symbols"]), self.spec, self.policy, categories)
        self.assertEqual(before, {s["id"]: s["raw_status"] for s in reviewed})
        text = inventory.report({**data, "symbols": reviewed})
        self.assertIn("| stdlib | 1 |", text)
        for invalid in ({**decision, "script_disposition": "typo"},
                        {k: v for k, v in decision.items() if k != "reason"},
                        {k: v for k, v in decision.items() if k != "contract"}):
            self.policy["symbols"] = {"function:SDL_Second": invalid}
            with self.assertRaises(RuntimeError):
                inventory.annotate(copy.deepcopy(data["symbols"]), self.spec, self.policy, categories)
        self.policy["symbols"] = {"macro:SDL_HIGH_BIT": decision}
        with self.assertRaises(RuntimeError):
            inventory.annotate(copy.deepcopy(data["symbols"]), self.spec, self.policy, categories)

    def test_pinned_stdinc_review_is_complete(self):
        data = json.loads((ROOT / "docs/generated/api-windows-x64-msvc.json").read_text(encoding="utf-8"))
        policy = json.loads((ROOT / "tools/api-policy.json").read_text(encoding="utf-8"))
        pending = [s for s in data["symbols"] if s["kind"] == "function"
                   and s["category"] == "Stdinc" and s["raw_status"] == "pending"]
        self.assertEqual(len(pending), 169)
        spec = json.loads((ROOT / "tools/bindings.json").read_text(encoding="utf-8"))
        without_review = copy.deepcopy(policy)
        for symbol in pending:
            del without_review["symbols"][symbol["id"]]
        categories = {h["header"]: h["category"] for h in data["headers"]}
        before = inventory.annotate(copy.deepcopy(data["symbols"]), spec, without_review, categories)
        self.assertEqual({s["id"]: s["raw_status"] for s in data["symbols"]},
                         {s["id"]: s["raw_status"] for s in before})
        for symbol in pending:
            decision = policy["symbols"][symbol["id"]]
            self.assertIn(decision["script_disposition"],
                          {"stdlib", "native_interop", "host_only", "deferred", "c_abi_only"})
            self.assertEqual(decision["raw_status"], "pending")
            self.assertTrue(decision["reason"])
            self.assertTrue((ROOT / decision["contract"]).is_file())
        free = next(s for s in data["symbols"] if s["id"] == "function:SDL_free")
        self.assertEqual(free["raw_status"], "generated")


    def test_pinned_non_stdinc_review_is_complete_without_hiding_coverage(self):
        data = json.loads((ROOT / "docs/generated/api-windows-x64-msvc.json").read_text(encoding="utf-8"))
        policy = json.loads((ROOT / "tools/api-policy.json").read_text(encoding="utf-8"))
        spec = json.loads((ROOT / "tools/bindings.json").read_text(encoding="utf-8"))
        expected = {
            "host_only": {
                "SDL_main", "SDL_SetMainReady", "SDL_RunApp", "SDL_EnterAppMainCallbacks",
                "SDL_RegisterApp", "SDL_UnregisterApp", "SDL_GDKSuspendComplete",
                "SDL_ReportAssertion", "SDL_SetAssertionHandler", "SDL_GetAssertionHandler",
                "SDL_GetDefaultAssertionHandler", "SDL_GetAssertionReport", "SDL_ResetAssertionReport",
            },
            "stdlib": {"SDL_MostSignificantBitIndex32", "SDL_HasExactlyOneBitSet32"},
            "deferred": {"SDL_SwapFloat"},
            "c_abi_only": {"SDL_SetErrorV", "SDL_LogMessageV", "SDL_IOvprintf"},
        }
        pending = [s for s in data["symbols"] if s["kind"] == "function"
                   and s["category"] != "Stdinc" and s["raw_status"] == "pending"]
        self.assertEqual({s["name"] for s in pending}, set.union(*expected.values()))
        without_review = copy.deepcopy(policy)
        for symbol in pending:
            decision = policy["symbols"][symbol["id"]]
            self.assertIn(symbol["name"], expected[decision["script_disposition"]])
            self.assertEqual(symbol["script_disposition"], decision["script_disposition"])
            self.assertEqual(decision["raw_status"], "pending")
            self.assertTrue(decision["reason"])
            self.assertTrue((ROOT / decision["contract"]).is_file())
            del without_review["symbols"][symbol["id"]]
        categories = {h["header"]: h["category"] for h in data["headers"]}
        before = inventory.annotate(copy.deepcopy(data["symbols"]), spec, without_review, categories)
        self.assertEqual({s["id"]: s["raw_status"] for s in data["symbols"]},
                         {s["id"]: s["raw_status"] for s in before})
        # A future pending declaration must be reviewed instead of silently entering the backlog.
        all_pending = [s for s in data["symbols"] if s["kind"] == "function" and s["raw_status"] == "pending"]
        self.assertEqual(len(all_pending), 188)
        self.assertTrue(all(s.get("script_disposition") for s in all_pending))


    def test_record_field_audit_snapshot_and_callback_slots(self):
        module = importlib.util.spec_from_file_location("field_audit", ROOT / "tools/audit_record_fields.py")
        field_audit = importlib.util.module_from_spec(module)
        module.loader.exec_module(field_audit)
        actual = field_audit.generate()
        saved = json.loads((ROOT / "docs/generated/record-fields-windows-x64-msvc.json").read_text(encoding="utf-8"))
        self.assertEqual(actual, saved)
        self.assertEqual(field_audit.report(actual),
                         (ROOT / "docs/generated/record-fields-windows-x64-msvc.md").read_text(encoding="utf-8"))
        callbacks = [f for f in actual["fields"] if f["callback"]]
        self.assertEqual(len(callbacks), 25)
        self.assertEqual(sum(f["status"] == "native_callback" for f in callbacks), 25)
        missing = {f["field"] for f in callbacks if f["record"] == "SDL_VirtualJoystickDesc"}
        self.assertEqual(missing, {"Update", "SetPlayerIndex", "Rumble", "RumbleTriggers",
                                   "SetLED", "SendEffect", "SetSensorsEnabled", "Cleanup"})
        vulkan = [f for f in actual["fields"] if f["record"] == "SDL_GPUVulkanOptions"]
        self.assertEqual(len(vulkan), 7)
        self.assertTrue(all(f["status"] == "direct" for f in vulkan))
        self.assertFalse(any(f["status"] in {"pending", "partial"} for f in actual["fields"]))

    def test_record_field_audit_rejects_silent_drift_and_missing_adapters(self):
        module = importlib.util.spec_from_file_location("field_audit", ROOT / "tools/audit_record_fields.py")
        field_audit = importlib.util.module_from_spec(module)
        module.loader.exec_module(field_audit)
        data = json.loads((ROOT / "docs/generated/api-windows-x64-msvc.json").read_text(encoding="utf-8"))
        spec = json.loads((ROOT / "tools/bindings.json").read_text(encoding="utf-8"))
        policy = json.loads((ROOT / "tools/record-field-policy.json").read_text(encoding="utf-8"))
        changed = copy.deepcopy(data)
        record = next(s for s in changed["symbols"] if s["kind"] == "record" and s["name"] == "SDL_IOStreamInterface")
        record["fields"].append({"name": "future_callback", "c_type": "void (*)(void *)"})
        with self.assertRaisesRegex(RuntimeError, "Unreviewed field"):
            field_audit.audit(changed, spec, policy)
        changed_policy = copy.deepcopy(policy)
        changed_policy["groups"].append(copy.deepcopy(changed_policy["groups"][0]))
        with self.assertRaisesRegex(RuntimeError, "Duplicate field decision"):
            field_audit.audit(data, spec, changed_policy)
        changed_policy = copy.deepcopy(policy)
        group = next(g for g in changed_policy["groups"] if g["status"] == "native_callback")
        group["entry_points"] = ["SDL_NonexistentCallbackSetter"]
        with self.assertRaisesRegex(RuntimeError, "Adapter is not registered"):
            field_audit.audit(data, spec, changed_policy)
        changed_spec = copy.deepcopy(spec)
        changed_spec["structs"]["SDL_IOStreamInterface"].append("close")
        with self.assertRaisesRegex(RuntimeError, "Stale field decisions"):
            field_audit.audit(data, changed_spec, policy)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--clang", default="clang")
    args, remaining = parser.parse_known_args()
    CLANG = args.clang
    unittest.main(argv=[__file__] + remaining)
