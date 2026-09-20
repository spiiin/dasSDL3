# Standalone GPU shader resources

Example 42 and `sdl3_gpu_shader_boost` add checked shader IDs to the generated SDL
types. Raw SDL_CreateGPUShader and its native pointer-bearing descriptor are
also generated. The checked adapter copies selected metadata; its getter is
not a source of owned native bytecode. For script bytes/file construction with
native pointers use [native adapters](gpu-native-boost.md).

```das
let info = gpu_shader_info(SDL_GPU_SHADERFORMAT_SPIRV,
    SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
device |> with_gpu_shader_file("triangle.vert.spv",info) $(shader) {
    return gpu_shader_descriptor(device,shader)
}
```

`with_gpu_shader` takes `array<uint8>` instead of a path. Both helpers accept an
optional explicit entry point before the final block; the default is `main`.
`gpu_shader_info` initializes all resource counts and props to zero. Set counts
to match the offline shader's actual declarations and SDL register/set convention.
`gpu_shader_entrypoint` returns Result<string,SdlError> with an owned string; descriptor retrieval returns
a value copy and never exposes native pointers or bytecode storage.

## Input and lifetime contract

Only vertex/fragment SPIR-V and DXIL are accepted, with exactly one format bit
enabled on the scoped device. Compute pipelines, source compilation, MSL,
METALLIB, DXBC and extension properties remain outside this subset. Entry point
must be an ASCII identifier of 1..127 characters. Embedded NUL follows the native
C-string convention and terminates the name/path.

Bytecode is limited to 16 MiB. SPIR-V needs its magic, at least 20 bytes and size
divisible by four; DXIL needs the DXBC container magic and at least 32 bytes.
Files are bounded before allocation and incomplete reads fail. Array creation
copies into an aligned native buffer before SDL; file reads use that same aligned
storage. No pointer into a script array survives the synchronous create call.
SDL owns the resulting shader representation; temporary native bytes are released
after creation. Metadata is field-copied and unused native fields are zeroed.

Counts are bounded by pinned SDL_sysgpu.h: 16 samplers, 8 storage textures,
8 storage buffers and 4 uniform buffers per stage. These checks do NOT reflect
or validate executable shader contents, stage/entrypoint existence, resource
declarations or binding ABI. Supply trusted, offline-validated shader binaries
and matching metadata. Header acceptance must never be described as a shader
validator or safe execution of arbitrary bytecode.

All resource operations require the main thread and a live scoped device. IDs
share the monotonic GPU namespace; stale/wrong-kind/foreign-device IDs fail.
Creation failure returns zero natively and false from the boost scope without calling the
block. Descriptor output is cleared on failed lookup. Scope exit releases on
normal return and early return via script defer.
Ordinary operations have no try/recover. Device cleanup releases unclosed shader
IDs only for that device. C++ guards cover partial native creation/registry failure.
Raw/manual release inside an owning scope is unsupported and causes cleanup error.

## Verification scope

`tests/gpu_shader.das` exercises array and file input, source-array mutation,
metadata copies, real lit fragment sampler/uniform declarations, invalid input,
wrong thread/kind/device, stale IDs, error returns, early return and device
cleanup. Native invalid-enum probes complement script compile failures for hidden
pointers and wrong enum assignments. Limits are validation tests; nonzero storage
resource counts are not exercised by a real shader in this stage.

For trusted zero-resource triangle shaders, a native test helper builds a pipeline,
releases both standalone shaders, renders and compares pixels to the existing CPU
barycentric oracle. This proves bytecode ownership and shader/pipeline lifetime
on the tested Vulkan/D3D12 drivers. It is not public general pipeline coverage.
The shared oracle also retains the earlier triangle tests. Example 42 only loads
and inspects shaders; it does not render.

Latest combined verification: [gpu-native-validation.md](gpu-native-validation.md).
Current function census: [api-coverage.md](api-coverage.md).
This page describes the checked subset. Full native pointers/arrays and scopes
are documented in [gpu-native-boost.md](gpu-native-boost.md); IDs and native
handles are separate. Other platforms and all hardware formats are not certified.
