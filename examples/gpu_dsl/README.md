# GPU shader DSL examples

Shaders use daScript's existing dasSpirv annotations. The SDL adapter validates
reflection and creates ordinary SDL GPU shaders; see the [contract](../../docs/shader-dsl.md).

| Example | Demonstrates |
| --- | --- |
| [01_triangle.das](01_triangle.das) | Vertex/fragment stages, interpolated color and a fragment uniform |
| [02_texture.das](02_texture.das) | Combined image sampler, nearest filtering and uniform tint |
| [03_uniforms.das](03_uniforms.das) | Automatic std140 packing: vertex transform, arrays, nested structs and mat3 |
| [04_compute.das](04_compute.das) | Console example: storage buffer, two compute passes and checked readback |

Run from the repository root:

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_dsl/01_triangle.das
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_dsl/02_texture.das
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_dsl/03_uniforms.das
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_dsl/04_compute.das
```

Vulkan uses the core runner. Metal and D3D12 use the libraries runner with
`DASSDL3_WITH_SHADERCROSS=ON`. On macOS, configure the [companion profile](../../docs/macos.md)
and run:

```sh
SDL_GPU_DRIVER=metal ./build/macos-libraries/bin/dasSDL3_libraries_runner examples/gpu_dsl/01_triangle.das
SDL_GPU_DRIVER=metal ctest --test-dir build/macos-libraries -R '^macos_metal_dsl_example_' --output-on-failure
```

All four examples passed native Metal checks, including uniform and compute
readback. The Mac shadercross profile does not require DXC for SPIR-V to MSL.
Examples 01–03 finish after 180 frames; append `--smoke-test` for
three frames. Example 04 runs once, prints its verification result and exits.
The second displays red/green above blue/white, filling the window. The third
changes the triangle from blue to orange after 90 frames.

Shader sources: [dsl_shaders.das](dsl_shaders.das),
[texture_shaders.das](texture_shaders.das), [uniform_shaders.das](uniform_shaders.das),
and [compute_shaders.das](compute_shaders.das). The support files contain example
upload/draw/dispatch code shared with the readback tests.

`ctest --test-dir build/ninja -R '^shader_dsl_' --output-on-failure` checks reflection,
compiler output, rendered pixels and compute buffer contents. With shadercross enabled, the same SPIR-V is
also translated and tested on D3D12. The parity project additionally checks baseline,
CppGenBind and strict AOT on Windows. Native Metal interpreter execution is
validated; these four DSL examples do not yet have a Mac strict-AOT claim.
Browser execution remains unvalidated.
