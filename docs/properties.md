# SDL Properties

SDL 3.4.16: 20 generated functions and one partial enumeration adapter. Native
SDL_SetPointerPropertyWithCleanup is available; see [callback lifetime and failure cleanup](native-callbacks.md). SDL_PropertyType is a typed
enum; SDL_PropertiesID retains its Uint32 representation. No new ID registry.

`require dassdl3/sdl3_properties_boost` adds with_properties (owns only a newly
created group), with_properties_lock (borrows the group), property_string and
property_names. Errors preserve SDL results; scopes skip their block on failure
and use defer on ordinary/early return. No panic/catch cleanup bridge.
Global/object properties are borrowed: never pass them to SDL_DestroyProperties.
Copies of an ID do not extend its lifetime. Do not destroy an owner inside its block.

property_string copies under the SDL lock into native storage, unlocks, then
allocates a daScript string. Missing values preserve the supplied default. Pinned SDL implementation also
converts scalar types in getters (including number-to-string), despite narrower
header wording; the binding preserves this behavior. Query SDL_GetPropertyType
when exact type matters. Raw SDL_GetStringProperty returns SDL-owned storage; use the copy for
retention after mutation, destruction or concurrent access.
property_names clears the output, synchronously collects copied names through a
native callback, then fills a script array after SDL unlocks. No script code runs
in that callback. Order is unspecified; a snapshot does not freeze later values.
SDL allocation/size failure returns false; script runtime allocation faults are
not converted into SDL errors. Property groups must outlive concurrent users.

Raw pointer properties borrow arbitrary native memory. The binding does not
manage the pointee or make script-array retention safe. Cleanup callbacks accept
native C addresses only. The host must own their code and userdata until cleanup;
the setter also invokes cleanup on failure. No retained script block bridge is provided.

SDL_CopyProperties copies ordinary values, but skips pointer properties that
have cleanup callbacks. String copies and enumeration results survive source
mutation/destruction. Locks are recursive on one thread; keep scope short and
do not hand a shared daScript Context to native worker threads.

Example: examples/51_properties.das. Tests: tests/properties.das, both generator
interpreters and strict AOT; assertions cover values/defaults, 64-bit numbers,
UTF-8 copies, pointer roundtrip, enumeration, lock release from another native
thread, early return, replacement/clear/destruction counters and borrowed global ID.

## Pinned SDL copy/cache defect

SDL 3.2.18 caches numeric-to-string conversions in SDL_Property.string_storage.
Its CopyOneProperty copies that pointer without duplicating it. Calling raw
SDL_GetStringProperty on a number/float, then SDL_CopyProperties and destroying
both groups can double-free the cache. The integration test exposed heap
corruption (Windows 0xc0000374); the pinned SDL source was not changed.

SDL_GetStringPropertyCopy avoids creating that cache: while locked, numbers use
SDL_asprintf with SDL_PRIs64 and floats use the same %f spelling as SDL. Other
values retain SDL_GetStringProperty behavior. The test converts both scalar
kinds, copies the group and destroys both, checking the preserved string result.
Raw SDL_GetStringProperty/SDL_CopyProperties remain unmodified and retain this
upstream limitation. The adapter cannot repair caches previously created by raw
calls or other native code. Source inspection confirms the same defect remains in SDL 3.4.16.
SDL_CreateGPUDeviceWithVulkanOptions copies property values by type into a private
group, avoiding this cache; pointer values are borrowed without cleanup ownership.
Its regression test covers a pre-existing numeric string cache. Recheck on future upgrades.

## Validation — 2026-09-20

Windows x64/MSVC, pinned SDL/daScript:
- Production build passed; full main project selection 118/118 passed.
- Full baseline/CppGenBind/strict-AOT suite 320/320 passed with no skips.
  The new Properties test and example passed in all three modes (six cases).
- Snapshot freshness, inventory/contracts, preprocessor and API boundary: 6/6.
  Standalone clangbind interpreter/AOT/negative checks: 4/4.
- Consumer with BUILD_TESTING=OFF and generators/Clang/LLVM disabled built and
  ran example 51. Its Ninja graph contains no libclang/libLLVM links or binding
  generator commands. Removed-framework API rejection also passed.
- Production generator configuration restored after consumer; Properties 2/2
  and final infrastructure checks passed again. Documentation links and diff
  whitespace checks passed. Snapshots use LF via the generator, not manual edits.

Full logs are in the task workspace work/properties-main-full.log,
properties-parity-full.log, properties-consumer.log and properties-final-gates.log.
These results do not certify other platforms or retained script cleanup callbacks.
