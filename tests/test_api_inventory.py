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


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--clang", default="clang")
    args, remaining = parser.parse_known_args()
    CLANG = args.clang
    unittest.main(argv=[__file__] + remaining)
