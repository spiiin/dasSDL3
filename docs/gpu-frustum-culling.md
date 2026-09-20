> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# CPU frustum culling for material batches

Example 21 draws a 48 x 48 grid (2304 cubes). C toggles culling, Space pauses the
camera/object animation, Escape exits. Window title reports total objects,
conservative visible candidates, submitted instances and nonempty material draws.
Culling OFF still calculates visibility for comparison, but submits all objects;
this is a visual comparison, not an isolated performance benchmark. Smoke mode
runs 60 frames, half with culling ON and half OFF, and checks submitted counts.

## Script API

`require dassdl3/sdl3_gpu_culling_boost` re-exports the batch module and adds:

- `gpu_frustum(camera) : GpuFrustum`: six inward clip planes, rebuilt whenever
  camera/view/projection/aspect changes. Camera uses column-major float4x4 and
  SDL's -w..w XY / 0..w depth convention, without Vulkan Y inversion.
- `gpu_sphere_visible(frustum,model,local_sphere) : bool`: conservative test.
  `local_sphere.xyz` is the local-space center and `.w` is its nonnegative radius.
- `gpu_batch_add_visible(list,frustum,mesh,model,local_sphere,color=float4(1.0))`:
  append a visible object to GpuBatchList and return true; otherwise return false.

```daslang
let frustum = gpu_frustum(camera)
gpu_batch_clear(list)
list |> gpu_batch_add_visible(frustum,mesh,model,float4(0.0,0.0,0.0,1.732051))
device |> gpu_draw_batches(window,scene,list,camera,float3(0.4,0.8,1.0))
```

The radius above encloses a local cube [-1,1]^3. Bounds are supplied by the
caller and must enclose all actual geometry, including any vertex displacement.
There is no automatic mesh-bound extraction or occlusion culling. Culling
creates no GPU resources and retains no arrays/handles. Existing batch ownership,
4096 submitted objects / 64 groups, cycling and shared-depth contracts remain.
Only retained objects are packed/uploaded. If none remain, the batch draw clears
and presents the frame normally.

This is a visibility query, not validation of a GPU mesh. Culled IDs/colors are
not submitted or checked by the native renderer; scopes must still keep referenced
resources alive. Visible models/colors/IDs are validated by gpu_draw_batches.
Finite affine models, including collapsed transforms, are geometrically valid for
the query; the renderer separately rejects singular/ill-conditioned lit models.
Default GpuFrustum is uninitialized: obtain it with gpu_frustum, do not edit planes.

## Geometry and numerical behavior

For a world plane p and affine model M, compute q = transpose(M) * p.
For local center c and radius r, the maximum signed plane value of the transformed
sphere is dot(q, float4(c,1)) + r * length(q.xyz). Reject only if this is strictly
negative beyond a relative floating-point margin. This uses the ellipsoid's
support in each plane direction and handles nonuniform/negative scale, rotation,
shear and a nonzero local center without underestimating radius. A largest-column
scale approximation is not sufficient under shear.

All six planes are tested: row3 +/- row0, row3 +/- row1, row2, row3-row2. The near
plane is row2, not row3+row2 (OpenGL depth). Plane normalization is unnecessary.
Tangency and near-boundary uncertainty stay visible. Finite intermediate overflow
keeps an object visible; invalid/nonfinite inputs panic. Camera extraction rejects
nonfinite or zero-normal planes: infinite-far projections are not supported by
this initial helper. A sphere passing all six tests can still be outside a corner;
false positives are allowed, since they only cost extra rendering.

Filtering preserves object order. The batch renderer still groups by first mesh
appearance; removing an early object can change group order. As in example 20,
opaque depth-separated surfaces are supported, but coplanar depth ties have no
order-invariant image guarantee. Transparency sorting/blending remain separate work.

## Verification

`tests/gpu_culling_math.das` runs without a GPU and checks six-plane tangency,
near depth zero, separation, nonuniform/reflected/sheared models, offset centers,
289 points against direct homogeneous clipping for a rotated perspective camera,
append/no-append behavior, invalid inputs and conservative overflow handling.

`tests/gpu_culling.das` compares full and culled offscreen RGBA readbacks byte for
byte on each backend. Both submissions are queued before waiting, so filtering
also changes the active instance-buffer size while earlier work can be pending.
Fixtures include partially clipped geometry, near/far crossing triangles,
nonuniform scale/reflection/shear, multiple materials, perspective/aspect changes,
all objects outside and empty input. Nonempty fixtures must contain colored pixels;
empty fixtures must clear to opaque black. Test-only readback is not public API.

From the repository root:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\21_gpu_frustum_culling.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

The process-only layer filter addresses this machine's FPS Monitor conflict;
see [gpu-multidevice.md](gpu-multidevice.md). Add --smoke-test for the 60-frame run.
Shaders and generated SDL snapshots are unchanged: this feature is script math
and filtering above the existing native batch path.

## Verified on 2026-09-19

- Main CTest suite: 74/74 passed.
- Baseline/CppGenBind/strict-AOT suite: 159/159 passed, including math and
  real GPU culling comparisons on Vulkan and D3D12.
- Example 21: 60 frames on each backend in the main runner, strict AOT
  (`main AOT=yes; fallback disabled`) and LLVM-free consumer build.
- Generator-enabled configuration restored; 7/7 targeted ClangBind probe,
  snapshot freshness and culling tests passed again.
- Full test/example logs contain no `VUID-` or `Validation Error`.
  Only the known overlay was filtered per process; validation was not disabled.
- `git diff --check` passed. SDL API coverage counts and shader assets unchanged.
