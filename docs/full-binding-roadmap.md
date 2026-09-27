# Remaining work

Current coverage: [API inventory](api-coverage.md), [Stdinc policy](stdinc-policy.md)
and [remaining API decisions](remaining-api-policy.md). Identified Windows
record-field gaps are closed; see [record access](record-field-accessibility.md).

- Linux/macOS builds, platform-specific header inventories and runtime tests.
  Metal success paths need Apple hardware.
- Physical audio, camera, HID, haptic and controller tests. Dummy and virtual-device
  tests do not establish hardware compatibility.
- Additional GPU formats/hardware, including positive ASTC transfers, with pixel/byte
  oracles and validation enabled.
- [Web](../web/README.md): platform census, Safari and a validated wasm32 AOT path.
  Desktop AOT offsets are not wasm32 ABI metadata. Threads and SDL GPU/WebGPU
  are not supported by the current profile.
- [SDK](sdk.md) profiles beyond Windows x64 MSVC Release, with matching ABI and
  external consumer tests.
- Examples that expose missing SDL contracts. [Shader DSL](shader-dsl.md) supports graphics, texture sampling, std140 packing and
  compute/graphics storage resources with explicit access metadata and std430 packing.
  The six GPU application examples use DSL shaders; Metal validation remains.

Additional Stdinc wrappers require a concrete script use case. Generated declarations
alone do not imply runtime or hardware validation.
