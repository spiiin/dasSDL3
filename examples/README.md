# Examples

Run from the repository root with `./build/ninja/bin/dasSDL3_runner.exe examples/<file>.das`.
01 uses the standalone daslang runner. Examples 01–08 cover core SDL/renderer/input/audio.
23–35 cover resource transfers, queries and window configuration; 37–43 descriptors
and individual GPU resources; 44–46 direct SDL render-pass/buffer/texture operations.

09–22 and 36 were removed with the renderer framework. Numbers are intentionally
not reused. 44 was renamed from `44_gpu_render_plan.das` to `44_gpu_render_pass.das`.
30–32 query/configure swapchains without presenting frames. Direct swapchain
acquisition remains pending; do not infer it from these examples.

- [01_hello.das](01_hello.das)
- [02_square.das](02_square.das)
- [03_input.das](03_input.das)
- [04_textures.das](04_textures.das)
- [05_streaming_texture.das](05_streaming_texture.das)
- [06_render_target.das](06_render_target.das)
- [07_geometry.das](07_geometry.das)
- [08_audio.das](08_audio.das)
- [23_gpu_copy_readback.das](23_gpu_copy_readback.das)
- [24_gpu_texture_transfers.das](24_gpu_texture_transfers.das)
- [25_gpu_formats.das](25_gpu_formats.das)
- [26_gpu_bc_blocks.das](26_gpu_bc_blocks.das)
- [27_gpu_cube_faces.das](27_gpu_cube_faces.das)
- [28_gpu_driver_discovery.das](28_gpu_driver_discovery.das)
- [29_gpu_resource_names.das](29_gpu_resource_names.das)
- [30_gpu_swapchain_capabilities.das](30_gpu_swapchain_capabilities.das)
- [31_gpu_present_modes.das](31_gpu_present_modes.das)
- [32_gpu_frame_latency.das](32_gpu_frame_latency.das)
- [33_gpu_color_targets.das](33_gpu_color_targets.das)
- [34_gpu_mipmaps.das](34_gpu_mipmaps.das)
- [35_gpu_scaled_blit.das](35_gpu_scaled_blit.das)
- [37_gpu_descriptors.das](37_gpu_descriptors.das)
- [38_gpu_pipeline_descriptors.das](38_gpu_pipeline_descriptors.das)
- [39_gpu_volume_transfers.das](39_gpu_volume_transfers.das)
- [40_gpu_astc_blocks.das](40_gpu_astc_blocks.das)
- [41_gpu_samplers.das](41_gpu_samplers.das)
- [42_gpu_shaders.das](42_gpu_shaders.das)
- [43_gpu_graphics_pipeline.das](43_gpu_graphics_pipeline.das)
- [44_gpu_render_pass.das](44_gpu_render_pass.das)
- [45_gpu_vertex_index_buffers.das](45_gpu_vertex_index_buffers.das)
- [46_gpu_texture_uniform_bindings.das](46_gpu_texture_uniform_bindings.das)

- [47_gpu_native_fences.das](47_gpu_native_fences.das): native commands/fences, explicit results and defer.

- [48_gpu_native_graphics.das](48_gpu_native_graphics.das): native shader/pipeline creation and deferred swapchain presentation.
- [49_gpu_native_compute.das](49_gpu_native_compute.das): compute uniforms/storage buffer, fenced download and CPU reference.
- [50_gpu_native_transfer.das](50_gpu_native_transfer.das): byte-array upload/copy/download with offsets and cycling.

Examples 48–50 use public native modules without unsafe or private fixtures.
See [native GPU guide](../docs/gpu-native-boost.md) for ownership and execution.

- [51_properties.das](51_properties.das): typed properties, copied names/strings and owned group scope.

- [52_init_hints.das](52_init_hints.das): metadata and balanced subsystem initialization.

- [53_diagnostics_time.das](53_diagnostics_time.das): UTC date, logging and performance counter.

- [54_video_discovery.das](54_video_discovery.das): display modes and hidden window pixel size.

- [55_window_properties.das](55_window_properties.das): property-configured parent and nested popup scopes.

- [56_window_surface.das](56_window_surface.das): CPU color fills on a borrowed window surface.

- [57_software_renderer.das](57_software_renderer.das): software primitives on a borrowed window surface.

- [58_renderer_state.das](58_renderer_state.das): scaled viewport and clipping on a window surface.

- [59_renderer_presentation.das](59_renderer_presentation.das): letterboxed logical canvas and coordinate conversion.

- [60_texture_state.das](60_texture_state.das): streaming checker with color/alpha modulation.

- [61_texture_transfer.das](61_texture_transfer.das): scoped write-only surface lock and byte modulation.

- [62_renderer_yuv_blend.das](62_renderer_yuv_blend.das): planar YUV checker upload.

- [63_renderer_operations.das](63_renderer_operations.das): paired creation, rotated texture and debug text.

- [64_renderer_raw_geometry.das](64_renderer_raw_geometry.das): split position/color arrays and literal debug text.

- [65_surface_state.das](65_surface_state.das): clipped surface fill, color key and modulation captured by a texture.

- [66_surface_pixels.das](66_surface_pixels.das): per-pixel surface data and scaled tiling with direct SDL.
