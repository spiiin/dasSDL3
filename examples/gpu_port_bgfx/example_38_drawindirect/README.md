# 48-drawindirect port

[Original bgfx example](https://github.com/bkaradzic/bgfx/tree/7e3060ccb97959dcda3f091b96d82515197028e0/examples/48-drawindirect). See `../LICENSE-bgfx.txt` and `../upstream/ports47-49.json`.

Original alternating cube/tetrahedron grid, vertex colors, camera, rotations and color animation. A DSL compute shader writes 20-byte SDL indexed-indirect commands and 80-byte per-instance matrices/colors; one `SDL_DrawGPUIndexedPrimitivesIndirect` API call submits 1–6561 objects. There is no CPU transform generation, indirect readback or per-object draw loop.

The ImGui panel changes grid size (1–81), vertex/index buffer modes and pause. Static uses offset zero; padded uses a nonzero binding offset; cycled uploads the same static geometry each frame with SDL cycling. These demonstrate the original static/dynamic/transient base-offset cases without pretending SDL has bgfx's pooled transient allocator. Vertex colors use float3 instead of packed UNORM bytes and indices use uint32; scene values are unchanged.

**SDL has no indirect-count-buffer draw API.** The draw count comes from the CPU grid setting, as in upstream's non-count mode. All command contents and instance data remain GPU generated. The panel states the limitation rather than providing a CPU-readback approximation. Geometry selection is derived from object parity in compute, equivalent to upstream's immutable alternating object list.

Regressions inspect GPU-written arguments (index count, first index, vertex offset, first instance), render the 81×81 limit and require identical pixels for all nine vertex/index buffer mode combinations.

Run from the repository root (ImGui-enabled libraries runner):

```powershell
./build/ninja/bin/dasSDL3_libraries_runner.exe examples/gpu_port_bgfx/example_38_drawindirect/main.das
```

Add `--smoke-test` for a bounded launch. Verified: interpreter regression and ImGui smoke launches on Windows Vulkan/D3D12; strict AOT regression and main entry point on Vulkan (fallback disabled); deterministic DSL compilation and SPIRV-Tools validation. CMake registers the regressions. Other platforms require separate verification.
