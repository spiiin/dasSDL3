# API coverage

Baseline: SDL 3.4.16, Windows x64/MSVC.

| Function classification | Count |
| --- | ---: |
| Generated | 1062 |
| Adapted | 13 |
| Pending, individually classified | 188 |
| Total active functions | 1263 |

Adapted means a documented partial adapter, not an original raw signature.
The [generated inventory](generated/api-windows-x64-msvc.md) contains per-header
counts and [machine-readable declarations](generated/api-windows-x64-msvc.json).
Internal SDL calls and private test fixtures do not count as public bindings.

## Remaining function decisions

- [169 Stdinc functions](stdinc-policy.md): standard-library overlap, native/host
  responsibilities, deferred operations and C-only interfaces.
- [19 other functions](remaining-api-policy.md): 13 host-only, two language alternatives,
  one deferred and three va_list entry points.

These remain pending in the inventory; classification is not implementation.
They are not an instruction to wrap every libc or host operation.

## Script access

The [record audit](record-field-accessibility.md) covers 122 complete records and
840 fields: 586 direct, 84 adapted, 25 native callbacks, 38 event tags, 98 internal
and nine host-only. No pending/partial field entries remain in this profile.
Native callback addresses are not script closures; internal fields remain private.

[Script accessibility](script-accessibility.md) documents copied strings, channel
maps and event payloads. Subsystem contracts are indexed in [Documentation](README.md).

## Validation limits

All 95 active Windows GPU declarations are generated; [raw tests](gpu-raw-tests.md)
exercise them on Vulkan and D3D12 with pixel/byte oracles. This does not cover every
format, parameter combination, platform branch or physical device.

Interpreter, generator parity, strict AOT and [installed SDK](sdk.md) are separate
checks. The [web profile](../web/README.md) has its own limited inventory.
See [remaining work](full-binding-roadmap.md) for platform and hardware gaps.
