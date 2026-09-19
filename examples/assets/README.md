# Example asset

checker.bmp is an original 128 x 128, 24-bit uncompressed BMP fixture created
for this project: teal/navy 16-pixel checker squares and a 4-pixel gold border.
No external artwork or image library is required. The border is also used by
the texture integration test to verify rendered pixels.

CMake copies it to build/ninja/bin/assets/checker.bmp. The example resolves it
relative to SDL_GetBasePath(), not the current working directory.

04_textures.das adapts the public-domain SDL 3.2.18 example:
https://github.com/libsdl-org/SDL/blob/release-3.2.18/examples/renderer/06-textures/textures.c
It replaces callbacks with a scoped event loop and adds scaling and cropping.

Audio: tone.wav is an original quiet 440 Hz, 0.4-second PCM16 mono signal
at 22050 Hz with short fades. Recreate it with tools/make_audio_fixture.py.
No music from the upstream example is included. CMake copies it to bin/assets.

shaders/transform.* are project-authored HLSL and offline SPIR-V/DXIL assets for
example 13. The vertex shader uses two float4 uniform rows; the fragment shader
shares the mesh sampler ABI. Rebuild with tools/build_triangle_shaders.py
--transform; --check verifies deterministic output and SPIR-V validity.
transform-manifest.json records source/binary hashes and the DXC version.

shaders/scene3d.* are project-authored color-vertex shaders for example 14.
shaders/lit.* are project-authored textured Lambert shaders for example 15.
They use a 112-byte MVP/normal vertex uniform and 16-byte fragment light uniform;
`python tools/build_triangle_shaders.py --lit` regenerates binaries and manifest.
The vertex shader consumes four explicit MVP columns (64 bytes); the fragment
shader returns interpolated RGBA without samplers. Rebuild/check with
tools/build_triangle_shaders.py --scene3d [--check]. Depth state belongs to the
native pipeline. The manifest records DXC and source/binary hashes.

`shaders/instances.*` uses vertex stride48 + instance stride112 (4 model and
3 normal columns), camera uniform64, light uniform16 and one fragment sampler.
Regenerate with `python tools/build_triangle_shaders.py --instancing`; binaries
and hashes ship with the source, so consumer builds need no shader compiler.

`colored_instances.*` extends the instance vertex record to stride128 with RGBA
at offset112/location10. Build using `tools/build_triangle_shaders.py
--colored-instances`; uniform/sampler slots match `instances.*`. Alpha is
modulated into the output, with pipeline blending disabled.
