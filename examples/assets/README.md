# Example assets

checker.bmp is project-authored: 128x128, 24-bit BMP, teal/navy checker squares
and a gold border used by texture tests. Example 04 adapts the public-domain
SDL release-3.2.18 renderer/06-textures example with a scoped PollEvent loop.

tone.wav is an original quiet 440 Hz, 0.4-second PCM16 mono signal at 22050 Hz,
with fades. Recreate with tools/make_audio_fixture.py; no upstream music included.
CMake copies runtime assets beside the executable under assets; paths use
SDL_GetBasePath, not the current working directory.

## Offline GPU shaders

All HLSL and SPIR-V/DXIL assets here are project-authored. Consumers use committed
binaries and require no shader compiler.

| Prefix | Use | Builder option |
| --- | --- | --- |
| triangle | Vertex-ID triangle, native example 48 and tests | build_triangle_shaders.py default |
| mesh | Position/UV sampling fixtures; name is an asset, not a public mesh API | --mesh |
| vertex_color | Vertex/instance layouts, example 45 | --vertex-color |
| bindings | Stage textures/uniforms, example 46 | --bindings |
| native.comp | Compute output/CPU reference, example 49 | build_native_gpu_shaders.py |
| attachments | MRT/depth/stencil/MSAA pixel tests | build_native_gpu_shaders.py |

Builders accept --dxc, --spirv-val and --check. Manifests record source/binary
hashes; triangle-family manifests also record DXC version. Use the matching
compiler for byte-for-byte reproduction. Descriptor metadata/layout must match
the shader; the binding does not reflect or validate arbitrary bytecode.
