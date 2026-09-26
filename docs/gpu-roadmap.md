# P6: complete direct SDL GPU bindings

> Current core pin: SDL 3.4.16. See [migration and coverage changes](sdl-3.4-upgrade.md); older 3.2.18 counts below describe the original baseline.

> Current declaration coverage: all 95 active Windows GPU functions are generated.
> The five native-adapter follow-up steps are implemented and locally validated
> on Vulkan/D3D12 (Windows x64). See [native guide](gpu-native-boost.md) and
> [results and remaining limits](gpu-native-validation.md). This is not a
> cross-platform completion claim.

The binding follows SDL objects and operations. Renderer plans, meshes, materials,
scenes and batching have been removed: see gpu-api-boundary.md. This replaces the
previous implementation chronology. Do not expand an engine layer to close an API gap.

## Current baseline

SDL 3.4.16; Windows x64/MSVC. All 95 active Windows GPU declarations are
available. Raw execution covers all 95 on Vulkan and D3D12. The upstream PIX
implementation removes the old debug-group exclusion (labels may no-op without
WinPixRuntime). See sdl-3.4-upgrade.md for upgrade validation.

Completed follow-up:
1. Shader/compute bytecode and file inputs; graphics pipeline descriptor arrays.
2. Bounded byte-array transfer access, synchronous map/copy/unmap without escaping views.
3. Native resource/pass/command defer scopes and swapchain submission cleanup.
4. MRT, depth/stencil, MSAA/resolve, load/store/cycle, slots/offsets/first-instance
   checked against CPU pixel and byte references.
5. Public graphics/compute/transfer examples 48–50, interpreter/AOT parity and
   no-LLVM consumer verification.

The older checked-ID API remains separate from native SDL pointers. Native handles
require the caller to obey SDL ownership, device, thread and synchronization rules.
See gpu-native-boost.md; no registry or framework objects were added.

The next library-wide vertical is P1 Properties, followed by Hints/Init,
Video/Render and IOStream/Events. Keep GPU backend limitations visible; Metal,
other operating systems and platform-specific declarations need their own tests.
A shader DSL and companion libraries remain separate projects in the roadmap.

## Remaining GPU work

1. Add actual Linux/macOS/Metal profiles, builds and output tests; handle
   platform-only declarations explicitly rather than counting Windows as all SDL.
2. Validate positive ASTC transfers on supported hardware and additional format/
   attachment combinations. Unsupported results remain explicit limitations.
3. When updating SDL, recheck D3D12 debug-group metadata/depth sample queries,
   Vulkan combined buffer usage and fence retirement before removing workarounds.
4. Preserve raw call receipts, ABI/metadata parity, CPU pixel/byte oracles and
   native adapter lifetime tests as regression gates for future generator changes.
5. Integrate GPU property-based construction after the general Properties layer
   has a documented owned/borrowed/callback contract.

## Verification rules

Keep GPU resources scoped to their device. Checked IDs validate provenance; native
pointers require valid/live/same-device handles as caller preconditions. No script per-call try/recover. Preserve script defer ownership and the asynchronous fence-retirement rule. Keep
validation enabled; machine-specific Vulkan layer filtering is opt-in only.

Tests and examples should demonstrate SDL operations directly. Application code
such as matrices or lighting belongs in the example. A shader DSL, reflection,
SDL_shadercross and SDL companion libraries are separate follow-ups after their
underlying SDL access is complete. No scene/material/batching API is planned here.

## Optional shader tooling / DSL

This is separate work, not a prerequisite for using the native SDL GPU API.
1. Keep offline HLSL/SPIR-V/DXIL assets reproducible and versioned. Add a pinned
   SDL_shadercross tool only after checking its SDL/toolchain requirements.
2. Define resource metadata and byte layout for uniforms/storage/vertex inputs;
   compare actual shader reflection with SDL stage counts and register conventions.
3. Prototype a small daScript annotated-function DSL using pinned shader_lingua_franca,
   shader_block_layout and dasSpirv/dasGlsl as research inputs. Do not alter raw SDL.
4. Cover vertex/fragment first, compute next; unsupported language constructs must
   fail with source diagnostics. Validate emitted SPIR-V and backend conversions.
5. Compare DSL and external shaders with the same CPU pixel/byte tests on each
   supported backend, including arrays, matrices, alignment and resource bindings.
   Cache keys include compiler/version/options; runtime compiler dependency is optional.

No scene/material/mesh framework is needed to implement or test this tooling.
