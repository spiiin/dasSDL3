# Stdinc: script priorities (SDL 3.4.16)

All 169 pending Windows Stdinc functions have an explicit `script_disposition`
in tools/api-policy.json. This is a priority decision, not an implementation or
an assertion that SDL and daScript semantics are identical. Raw status remains
pending. See [current coverage](api-coverage.md) for library-wide totals and
[the remaining non-Stdinc decisions](remaining-api-policy.md) for the other 19 entries.
No denominator reduction or automatic exclusion by name prefix is used.
The [generated inventory](generated/api-windows-x64-msvc.md) lists every function
and its decision; JSON retains the per-function reason and contract.

| Decision | Count | Action |
| --- | ---: | --- |
| stdlib | 122 | Prefer existing language/standard-library facilities; outside the ordinary binding backlog unless exact SDL semantics are needed |
| native_interop | 15 | Bind only for a concrete native buffer, allocation or ownership scenario |
| host_only | 6 | Native allocator configuration and unsafe process environment; no arbitrary script callbacks |
| deferred | 16 | Useful SDL-specific APIs; add when an application scenario justifies them |
| c_abi_only | 10 | C variadic/va_list functions and compiler overflow entry points; not part of ordinary script API |

## Standard-library overlap

The 122 entries cover math, C-string operations and parsing, character predicates,
sorting/searching, UTF-8 helpers and random generation. Existing sources:

- [math bindings](../third_party/daScript/src/builtin/module_builtin_math.cpp):
  sin, sqrt and related floating-point operations.
- [string bindings](../third_party/daScript/src/builtin/module_builtin_string.cpp):
  searching and numeric conversions; language interpolation replaces common formatting.
- [array algorithms](../third_party/daScript/daslib/algorithm.das): sorting/searching.
- [UTF-8 utilities](../third_party/daScript/daslib/utf8_utils.das): encoding,
  decoding, validation and length.
- [random utilities](../third_party/daScript/daslib/random.das): explicit generator state.

These are alternatives for a task, not drop-in replacements for each SDL call.
C end pointers, base/range handling, writable char buffers, locale/case rules,
malformed UTF-8 behavior, floating-point rounding and RNG sequences can differ.
If a port requires exact SDL behavior, revisit its individual decision and add
tests for that contract. Never rewrite an existing raw SDL call to a different
algorithm merely because this table labels it stdlib.

## Native memory and host configuration

The 15 interop entries are malloc/calloc/realloc, aligned allocation/free,
memcmp/memcpy/memmove/memset/memset4, strdup/strndup/wcsdup and the two public
checked-size operations. They are not replacements for owned daScript arrays.
SDL_free is already generated and remains available. Allocations released by SDL
must use the compatible allocator; aligned memory needs SDL_aligned_free.
An adapter must establish capacity, ownership and synchronous versus retained
access. Strings belonging to daScript are not writable C buffers or SDL allocations.
No-copy audio remains native-retained storage, not a captured script array.

The six host-only entries are GetMemoryFunctions, GetOriginalMemoryFunctions,
SetMemoryFunctions and getenv_unsafe/setenv_unsafe/unsetenv_unsafe. Allocator
callbacks are native function pointers; their installation and lifetime must obey
SDL initialization/allocation rules. No script Context is bridged onto arbitrary
native threads. Unsafe environment mutation is not a default boost convenience.

## Useful deferred APIs

The 16 entries are seven SDL_Environment lifecycle/query/update operations,
SDL_getenv, GetNumAllocations, three CRC/Murmur hashes and four iconv operations.
SDL_Environment is the first candidate when process-launch configuration or an
independent environment snapshot is needed. Its owned versus borrowed instances
and copied strings/arrays require explicit contracts. Hash functions matter when
matching SDL's algorithm, seed and bytes; iconv matters for non-UTF encodings.
Allocation counts are diagnostic, not a promise that every live allocation is a leak.
None is a blocker for the existing application examples or installed SDK.

## C-specific entry points

Eight asprintf/snprintf/sscanf/swprintf and va_list variants are omitted from the
ordinary script queue. Existing fixed-text adapters in other SDL categories stay.
The two *_check_overflow_builtin entry points are compiler-specific alternatives
to the public checked-size APIs; they do not warrant a second script interface.

The classifier validates decision values and requires a reason and contract.
Tests ensure all pending Stdinc entries are reviewed, SDL_free remains generated,
and classification does not alter raw counts. Future header upgrades must review
new functions rather than silently inheriting a prefix-wide exclusion.
