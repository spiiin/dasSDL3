# Shader DSL

Author shaders in daScript using the existing dasSpirv annotations and builtins.
The compiler emits SPIR-V and reflection while compiling the script. The SDL layer
validates resource layout and passes the generated code to existing SDL factories.
No native Vulkan module, GLSL/HLSL source file or external compiler is required for
the direct SPIR-V path.

## Authoring

```das
require spirv/spirv_shader
require spirv/spirv_builtins

struct Tint { color : float4 }
var @uniform @set=3 @binding=0 tint : Tint
var @out @location=0 output_color : float4

[fragment_shader(name="fragment")]
def fragment_main {
    output_color=tint.color
}
```

The annotation produces `fragment : array<uint>` and `fragment_reflect : array<uint>`.
The entry point is `main`. Use the two arrays from the same compilation together.
See [shader source](../examples/gpu_dsl/dsl_shaders.das) for vertex outputs, fragment
inputs and a uniform block, and [runnable triangle](../examples/gpu_dsl/01_triangle.das).

```das
require dassdl3/sdl3_shader_dsl
require dassdl3/sdl3_scope

// Inside sdl_scope; device outlives the shader.
var shader : SDL_GPUShader? = device |> with_gpu_dsl_shader(fragment,fragment_reflect) |> sdl_use
```

`gpu_dsl_shader_info` returns SDL_GPUShaderCreateInfo with stage/resource counts
from reflection. `gpu_dsl_spirv_bytes` makes an owned little-endian byte copy.
`with_gpu_dsl_shader` delegates lifetime management to the existing native shader
scope. Resources, commands, passes and pipelines remain ordinary SDL objects.
There is no per-frame shader compilation or new renderer abstraction.

## Resource contract

The access-aware factories support uniform blocks, combined samplers, storage
buffers and storage textures, with these SDL sets:

| Stage | Readonly resources | Read/write resources | Uniforms |
| --- | ---: | ---: | ---: |
| Vertex | 0 | — | 1 |
| Fragment | 2 | — | 3 |
| Compute | 0 | 1 | 2 |

In each readonly set, bindings are ordered **samplers, storage textures, storage
buffers**. Compute set 1 contains **storage textures, then storage buffers**.
Each set starts at zero without gaps. SDL bind-call slots remain local to their
resource kind. Counts are inferred and checked against the pinned SDL limits.
See [graphics](https://wiki.libsdl.org/SDL3/SDL_CreateGPUShader) and
[compute](https://wiki.libsdl.org/SDL3/SDL_CreateGPUComputePipeline) conventions.

Upstream reflection lacks access flags. Require `dassdl3/sdl3_shader_access` and
add a companion annotation to capture the reachable globals' explicit qualifiers:

```das
var @ssbo @readonly @set=0 @binding=0 source : array<uint>
var @ssbo @set=1 @binding=0 destination : array<uint>

[compute_shader(local_size_x=64, name="transform"), sdl_shader_access(name="transform")]
def transform_cs {
    let i = gl_GlobalInvocationID.x
    destination[i] = source[i] * 2u
}
```

The additional `transform_access : array<uint>` records set/binding and access.
Use the bytecode, reflection and access arrays from the same compilation:

```das
var pipeline : SDL_GPUComputePipeline? = device
    |> with_gpu_dsl_compute_pipeline(transform, transform_reflect, transform_access) |> sdl_use
```

Graphics uses the equivalent `with_gpu_dsl_shader(code, reflection, access)`;
shadercross factories accept the same arguments. The corresponding `*_info`
functions also accept access metadata. Old overloads without access retain their
restricted profiles (graphics uniforms/samplers; compute RW buffers/uniforms).

Readonly resources require `@readonly`; writable compute resources use default
read/write or `@writeonly`. `@maybe_readonly` is rejected by the companion annotation
because stage-dependent access must be explicit here. Metadata is sorted and
validated for missing/extra records, duplicate bindings, resource order and access
mismatches. Descriptor arrays, separate samplers/images, push constants and
unsupported stages are rejected before native creation.

**Readonly texture adaptation:** SDL implements these as sampled-image descriptors,
while dasSpirv emits `@readonly image2D` as storage images. The access-aware factories
use `gpu_dsl_storage_spirv` to convert the relevant image/pointer/load types and
`imageLoad`/`imageSize` instructions to sampled-image fetch/query with LOD zero.
It reuses the upstream SPIR-V instruction walker, preserves RW resources, and
runs once at shader creation. Both direct SPIR-V and shadercross use this step.
Non-MS scalar image descriptors are supported; descriptor arrays are rejected.

The adapter is not a general SPIR-V validator: arrays must come from the trusted
compiler, match each other, and match the application's texture formats and buffer
layouts. It does not validate interstage interfaces. Offline tests run SPIRV-Tools
on the adapted shaders. Do not pass untrusted bytecode to the driver.

## Storage structures (std430)

Require `dassdl3/sdl3_shader_storage` to pack an `array<struct>` for an SSBO or
unpack downloaded bytes. Offsets and strides use upstream `compute_block_layout`
with std430 rules, exactly as dasSpirv's SSBO emitter does. Native struct memory
is not assumed to match GPU layout.

```das
var bytes <- gpu_dsl_storage_bytes(records) |> sdl_try
pack_gpu_dsl_storage(records, bytes) |> sdl_try // reuse caller-owned byte storage
unpack_gpu_dsl_storage(bytes, records) |> sdl_try
```

Packing writes each leaf and zeros padding. Unpacking requires an exact multiple
of the inferred element stride; on a length error it returns Err before modifying
the destination. Empty arrays are valid. Array-size multiplication is checked.
The macros evaluate their arguments once and do layout work at compile time.

The packing profile supports 32-bit numeric scalar/vector fields, scalar
int64/uint64, float3x3/float3x4/float4x4, nested structs, and fixed arrays of numeric
scalars/vectors or structs. Sub-32-bit fields, managed values, bool, arrays of
matrices and multidimensional arrays are rejected. Element size is capped at
64 KiB and fixed field-array count at 4096 to bound layout arithmetic and generated
code. CPU packing support does not imply device support for 64-bit shader arithmetic.

## Uniform structures

Require `dassdl3/sdl3_shader_uniforms` to upload a struct using the same std140
layout as dasSpirv. SDL requires [std140 uniform data](https://wiki.libsdl.org/SDL3/SDL_PushGPUFragmentUniformData).
The adapter uses `daslib/shader_block_layout` at compile time and emits leaf copies;
it never uploads raw struct memory. Matrix columns, array strides, nested members
and padding are handled explicitly. Input expressions are evaluated once.

```das
command |> push_gpu_dsl_vertex_uniform(0u, vertex_params) |> sdl_try
command |> push_gpu_dsl_fragment_uniform(0u, params) |> sdl_try
```

The stage and slot are explicit; the struct must match the shader's declaration.
These functions do not infer the active shader or check a pipeline's layout.
They return `SdlStatus`, reject null commands and slots outside 0..3, and retain
SDL's command lifetime/thread preconditions. Successful status means the adapter
accepted the call; SDL's underlying push function returns void.

For inspection or repeated packing into caller-owned storage:

```das
var bytes <- gpu_dsl_uniform_bytes(params) // owned array<uint8>
pack_gpu_dsl_uniform(params, bytes)       // reuse storage; reset padding to zero
```

The convenience push functions use a fresh temporary buffer. For a hot loop,
reuse `bytes` and submit it with the existing `SDL_PushGPU*UniformDataArray` adapter.
No pointer into the struct or byte array is retained after the upload.

Supported shapes follow the pinned upstream layout: 32-bit int/uint/float scalars
and vectors, float3x3/float3x4/float4x4 matrices, nested structs, and fixed arrays
of scalar/vector/struct elements. Scalar int64/uint64 packing is tested on CPU;
it does not establish shader/backend support for 64-bit arithmetic. Bool, strings,
dynamic arrays, arrays of matrices and multidimensional arrays fail at compilation.
Blocks above 32 KiB are rejected, matching the pinned SDL uniform-buffer capacity.

[03_uniforms](../examples/gpu_dsl/03_uniforms.das) uses a vertex transform and a
fragment block containing float3+scalar, an array, a nested struct and a mat3.
The triangle changes from blue to orange after 90 frames. Its pixel test uploads
two values on Vulkan and D3D12. A separate CPU golden checks every byte, including
padding and repeated writes into a reused buffer, plus the other matrix shapes.

## Compute buffers

Require `dassdl3/sdl3_shader_compute`. `gpu_dsl_compute_info` derives resource
counts and workgroup dimensions from reflection and optional access metadata.
Upload structured uniforms with `push_gpu_dsl_compute_uniform`.

Use ordinary `with_native_gpu_compute_pass`, `SDL_BindGPUCompute*` calls and
`SDL_DispatchGPUCompute`; dispatch arguments are workgroup counts, not thread
counts. Resource usage, byte capacity, shader bounds checks and synchronization
remain explicit. RW texture reads require
`SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE`, not READ | WRITE.
Use separate resources when sampler/storage uses require incompatible native image
layouts; the tests deliberately use distinct sampler and readonly-storage textures.

Local dimensions must be positive, x/y <=1024, z <=64, product <=1024. Actual device
limits may be lower; valid reflection does not guarantee pipeline creation.
Specialization overrides are not exposed.

`with_gpu_dsl_compute_pipeline_cross` in the optional cross module translates the
same SPIR-V to D3D12 inside the caller's `with_shadercross` session.
[04_compute](../examples/gpu_dsl/04_compute.das) is a console example: it uploads
192 integers, dispatches two dependent read-modify-write passes over 131 values,
then waits for a fence and checks the entire downloaded buffer, including the
61 untouched tail values. This scenario is tested on Vulkan and D3D12.

## Backends

- **Vulkan:** direct SPIR-V via the core runner. The pinned emitter outputs SPIR-V
  1.3; offline validation uses the Vulkan 1.1 environment.
- **D3D12:** enable DASSDL3_WITH_SHADERCROSS, require sdl3_shader_dsl_cross and use
  with_gpu_dsl_shader_cross inside an application-owned with_shadercross session.
  The same SPIR-V is translated through shadercross/DXC; C function ownership is
  unchanged. This path requires the libraries runner and its compiler DLLs.
- **Metal/GLSL:** daScript has existing emitters, but this SDL adapter does not yet
  integrate them directly. Metal execution and browser use are not validated.

For shadercross details and deployment, see [shadercross](sdl-shadercross.md).
This layer adds no HLSL emitter to daScript.

## Run and test

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_dsl/01_triangle.das
ctest --test-dir build/ninja -R '^shader_dsl_' --output-on-failure
```

The example shows a blue triangle and exits after 180 frames (three with
--smoke-test). GPU tests render two different uniform colors, read back the center
and background pixels, and reject validation-layer errors. They cover Vulkan and
D3D12 translation. The [texture example](../examples/gpu_dsl/02_texture.das) samples
a 2x2 RGBA texture with nearest filtering and a uniform tint. Its tests compare all
64 pixels of an 8x8 render target against CPU expectations for two tints.
Resource tests additionally cover readonly and RW images/buffers, compute samplers,
vertex/fragment storage reads, std430 golden bytes and malformed metadata. The GPU
case checks every pixel of two 8x8 targets and all 64 output records on both drivers.
The examples and tests also run in baseline,
CppGenBind and strict AOT through tests/clangbind_parity/shader_dsl.cmake.

Compiler checks are independent of the SDL host:

```powershell
python tests/test_shader_dsl_compile.py --daslang third_party/daScript/bin/daslang.exe --spirv-val C:/VulkanSDK/<version>/Bin/spirv-val.exe
```

This checks deterministic bytecode, rejects a non-shader operation and runs
SPIRV-Tools when its path is supplied. Formatting/building a shader does not imply
support for every construct handled by the upstream compiler.

## SDK and next steps

The core SDK includes the pure-script dasSpirv module and its module descriptor.
For strict AOT list runtime shared modules explicitly, including the shader source
module, sdl3_shader_dsl, sdl3_shader_compute for compute, sdl3_shader_uniforms
for structured uniforms, sdl3_shader_storage for storage packing, their dependencies and
`dascript/modules/dasSpirv/spirv/spirv_reflect` and, for texture intrinsics,
`dascript/daslib/shader_lingua_franca`. Macro/compiler modules are not runtime
AOT dependencies. Access-aware factories additionally use sdl3_shader_resources,
sdl3_shader_storage_spirv and the upstream spirv_dis/spirv_builder/spirv_grammar
runtime modules. See [SDK](sdk.md).

Next: more demanding application examples and Metal validation.
Reuse dasSpirv, shader_block_layout and the existing GLSL/MSL emitters; do not
build a second shader parser or a scene/material layer.
