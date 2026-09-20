> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# Dynamic instance transforms

Example `18_gpu_dynamic_instances.das` independently animates the rotation,
height and nonuniform scale of 64 cubes, still using one indexed draw per frame.
Example 17 retains its upload-once behavior. Both use the same shaders and layout
documented in [gpu-instancing.md](gpu-instancing.md).

```das
device |> gpu_update_instances(mesh,instances)
device |> gpu_draw_instanced_mesh(window,mesh,camera,float3(0.4,0.8,1.0))
```

`SDL_UpdateGPUInstances` returns bool; the boost wrapper reports SDL errors by
panic. Calls are main-thread-only and require a live instanced mesh owned by
the device. The list replaces all transforms, and must contain exactly the
number of instances supplied at creation (1..4096). It does not resize buffers,
change geometry, textures or shaders, or expose mapped pointers. Matrices and
inverse-transpose normals are validated/prepared using the same code as creation.
Bad counts, stale/foreign/wrong-kind IDs, nonfinite/nonaffine/singular models fail
before any GPU allocation, mapping or command acquisition.

The mesh lazily owns an upload transfer buffer. Each update maps it with
`cycle=true`, copies the complete packed model/normal array, unmaps, records a
copy pass, and uploads the entire instance buffer with `cycle=true`. This is
required for both resources: previous commands may still read the staging data
or vertex data. Cycling invalidates subsequent contents, so partial updates are
not supported. Source arrays can be cleared or modified immediately on return.

The upload is submitted in its own command buffer before subsequent draws.
There is no explicit CPU fence/idle wait, and no script callback during recording.
A frame thus uses one upload submission and one drawing submission; optimizing
them into a single command buffer is future work. SDL determines when cycling
needs another backing allocation, so this is not an allocation-free guarantee.

See the pinned SDL 3.2.18 `SDL_gpu.h` cycling contract and
[SDL_MapGPUTransferBuffer](https://wiki.libsdl.org/SDL3/SDL_MapGPUTransferBuffer),
[SDL_UploadToGPUBuffer](https://wiki.libsdl.org/SDL3/SDL_UploadToGPUBuffer).

Validation, allocation, mapping or command-acquisition failures preserve existing
instance data. If submission fails after the destination has been cycled, the
mesh becomes unready: drawing is rejected before command acquisition until a
full update succeeds. Submission consumes the command even on failure. A failed
copy-pass start cancels its upload-only command (it never acquires a swapchain).
Device loss may require recreating the device; retry success is not guaranteed.

The upload buffer belongs to the mesh and is released on normal scope exit,
early return, panic, explicit mesh release or device-specific cleanup. SDL defers
physical resource destruction as needed for pending commands.

## Checks

`tests/gpu_instancing.das` covers changing transforms, invalid count and late
singular model preserving pixels, stale/foreign IDs, and updated resources during
panic and second-device destruction. Native tests submit twelve alternating
transform snapshots and their readbacks before any fence wait, then compare
every image against the independent CPU reference. This exercises the pending
submission contract; it does not assert how many frames the hardware keeps busy.
A test-only injected submission failure cancels an upload after recording and
checks draw rejection, followed by a successful update and pixel verification.

Run from the repository root:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\18_gpu_dynamic_instances.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

The process-only layer filter is for this machine's known FPS Monitor conflict;
see [gpu-multidevice.md](gpu-multidevice.md). Escape closes the example; resize is
supported. Smoke mode renders 60 frames with deterministic animation time.

## Verification on 2026-09-19

- Main suite: 61/61 passed; final rebuild followed by six targeted
  generator/instancing/example checks, all passed.
- Parity matrix: 132 checks covered across the full run and final rerun.
  Three strict-AOT checks initially rejected a stale generated test after the
  normal-transform fixture was strengthened. Regeneration/rebuild and all eight
  instancing parity checks passed, preserving strict no-fallback behavior.
- Example 18: 60 frames on Vulkan and D3D12 in the main runner, strict AOT
  (`main AOT=yes; fallback disabled`) and LLVM-free consumer build.
- Saved GPU test logs contain no `VUID-` or `Validation Error`; the known
  overlay layer was filtered only in test processes, not validation layers.
- Generator snapshots were regenerated from policy; shader sources/binaries
  were unchanged. `git diff --check` passed.
