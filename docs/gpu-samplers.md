# Checked standalone GPU samplers

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

Example 41 and `sdl3_gpu_sampler_boost` add independent sampler ownership above
the generated `SDL_GPUSamplerCreateInfo`, enums and raw create/release bindings.
They do not add a general render pass or change the samplers owned by mesh bundles.

```das
var info = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR,
    SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
info.enable_anisotropy = true
info.max_anisotropy = 4.0
device |> with_gpu_sampler(info) $(sampler) {
    var copied : SDL_GPUSamplerCreateInfo
    if (!gpu_sampler_descriptor(device,sampler,copied)) { return }
}
```

`gpu_sampler_info()` defaults to nearest filtering (including mip selection),
clamp-to-edge on all axes, LOD 0..1000, bias zero, no comparison or anisotropy.
The typed descriptor remains editable before creation. `with_gpu_sampler(device)`
uses these defaults. IDs are immutable resources; changing either the input or
the returned descriptor does not change the native sampler. Descriptor retrieval
returns the normalized creation request, not a query of driver implementation.

## Validation and limits

Creation, lookup and release require the main thread and a live scoped device.
Every enum is checked before SDL, including values constructed through raw code.
All floats must be finite. The checked subset accepts nonnegative min/max LOD
with min <= max <= 1000 and bias -2..2. Enabled anisotropy accepts 1..16 and requires
linear min/mag/mipmap filters. These are binding limits, not queried device limits;
SDL 3.2.18 exposes no sampler limit query. Metal ignores LOD bias in the SDL API.
Vulkan and D3D12 are the tested backends; Metal is not tested here.

Enabled comparison requires a non-INVALID compare operation. When comparison is
disabled its native operation is normalized to ALWAYS; disabled anisotropy is
normalized to 1 (any finite unused input is accepted). Properties must be zero:
extension properties are outside this checked contract. Padding is always zeroed
by field-wise copying. Creation failure returns zero at the native adapter layer
and false from the boost scope, without invoking the ownership block.

## Lifetime

The sampler registry shares monotonic IDs with other GPU resource kinds. Stale,
foreign-device and wrong-kind IDs fail before dereferencing a native resource.
`SDL_GetGPUCheckedSamplerInfo` clears its output on failure. The scope releases
on normal exit and early return using script defer;
ordinary operations have no try/recover. Do not manually release a scope-owned ID:
its eventual second release is an error. Copies of an ID do not extend lifetime.

Device cleanup also releases unclosed sampler IDs and affects only that device.
SDL owns deferred native destruction; release introduces no GPU idle wait. A small
C++ guard handles allocation failure while inserting a newly created sampler.
Raw pointer APIs retain their existing caller-owned contract.

## Verification and remaining work

`tests/gpu_sampler.das` covers nearest, linear, comparison and 16x anisotropic
creation, copied descriptors, normalized unused fields, invalid input before SDL,
wrong thread/kind/device/stale IDs, normal/early cleanup, nested error returns,
failed creation without callback and two-device cleanup. Native probes exercise
invalid enum values, nonfinite floats and hidden padding. Main and strict AOT
tests run on Vulkan and D3D12. Example 41 is also an LLVM-free consumer scenario.

These are creation/ownership tests, not sampling pixel tests. Public binding of
sampler IDs to general graphics/compute passes, format/filter compatibility,
comparison depth textures and shader declarations remain pending. Do not count
this resource layer as completion of those contracts or ASTC positive GPU tests.
The GPU census stays 13 generated / 54 adapted / 25 pending: sampler create/release
were already generated, and their boost policy remains partial due to limits.

Next: standalone shaders with owned bytecode and checked resource declarations,
then graphics pipeline creation with copied layouts, then bindings in native
command plans and pixel tests for standalone textures/samplers.

Validation run (2026-09-20): main CTest 142/142; parity/AOT suite 328 passed and
one skipped (`aot_gpu_instancing_direct3d12`, device creation unavailable, no
driver error printed by that existing test). Its separate repeat passed 1/1.
All new sampler tests passed without skips. Standalone dasClangBind gates 4/4.
Full GPU logs contain no Vulkan VUID or D3D12 validation errors. The initial
device-creation skip is unexplained; the successful repeat does not explain it.
The LLVM/libclang-free consumer built and ran example 41 on both backends.

Public render-plan sampling is covered by [shader bindings](gpu-shader-bindings.md):
RGBA8/BGRA8 Texture2D and noncomparison samplers; nearest/linear CPU pixel tests.
