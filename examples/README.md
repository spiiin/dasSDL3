# Examples

- [Optional library integrations](libraries/README.md): daScript ImGui with SDL3;
  uses the separate `dasSDL3_libraries_runner` host.

Scoped acquisition uses [sdl_scope/sdl_use](../docs/sdl-scope.md) with receiver-first
pipes; Result operations use `sdl_try`. `results/01_results.das` keeps explicit
Result checks for comparison. Scopes with multiple callback parameters retain
their trailing blocks.

- [67_event_variants.das](67_event_variants.das): owned event variants, `match`, text and IME composition.
- [68_event_queue.das](68_event_queue.das): timed waiting, non-consuming peek, custom event types and copied drop text.

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

## Result/Option API

[results/01_results.das](results/01_results.das) uses standard daScript Result/Option,
canonical Result-returning scopes and deferred cleanup. This separate sequence preserves
existing example numbers. It renders the BMP texture and propagates failures as
values; `--smoke-test` renders three frames. Contracts and language caveats:
[error handling](../docs/error-handling.md).

[results/02_sdl_try.das](results/02_sdl_try.das) shows the same application with
[`sdl_try`](../docs/sdl-try.md). Numbered examples now use this macro for sequential
Result operations; `01_results` intentionally retains explicit checks and
`and_then` for comparison. Raw SDL checks and deliberate Option defaults remain.

[results/03_poll_events.das](results/03_poll_events.das) uses lazy
`for (event in poll_events())` and `should_close(event, window)` with owned events.
Escape or the close button exits; `--smoke-test` renders three frames.

## Structure of Result-based examples

Keep acquisition callbacks short and return nested scope Results directly.
Rendering loops, pipeline setup, uploads and readback checks are ordinary named
functions in the example, returning `Result<SdlUnit,SdlError>`. They synchronously
borrow their arguments; the calling `with_*` or explicit `defer` retains ownership.

- Report an operation error once in `main`; forward its owned SdlError through helpers.
- Import `dassdl3/sdl3_try` for sequential commands: `renderer |> clear() |> sdl_try`
  or `let size = texture_size(texture) |> sdl_try`. Put it only in statements or
  single-variable initializers inside Result-returning helpers/blocks. Arrays use
  move initializers; keep `return sdl_ok()` for successful void-like work.
- Handle Option and successful false values separately. Do not turn Result errors
  into placeholder values with `unwrap_or`. An explicit `is_err` remains appropriate
  when reporting an error in `main` or deliberately recovering from it.
- Split at meaningful stages rather than introducing shared example frameworks or
  compound public resource types. See [45](45_gpu_vertex_index_buffers.das),
  [46](46_gpu_texture_uniform_bindings.das) and [48](48_gpu_native_graphics.das).
- Never use a borrowed handle in an `and_then` after its owning scope has returned.
  Mutable native handles and scalar output references retain their explicit `var`.
- Unsupported GPU creation can produce smoke-test exit 77. A failure after creating
  the device is an error, not an unavailable-device skip.

Local validation of the helper-extraction refactor (2026-09-21, Windows x64/MSVC): 45 changed
examples, 70 main smoke tests, 102 legacy/CppGenBind tests and 95 strict AOT tests
passed, including Vulkan/D3D12 where applicable. Targeted error checks cover failed
video initialization, unavailable GPU creation and missing shader after successful
device creation; the latter remains an error (exit 1), never a smoke skip.
Examples 45 and 46 now have at most three nested resource scopes in one function,
compared with nine before extraction. Public SDL/boost declarations are unchanged.

The subsequent `sdl_try` migration changed 45 numbered examples. All 69 main smoke
checks, 102 legacy/CppGenBind checks and 93 strict AOT checks passed, covering every
changed example and Vulkan/D3D12 where applicable. Error-path checks preserved
initialization failures, GPU-unavailable smoke skips and post-creation failures;
an injected texture-size failure propagated through the macro with exit 1.
The LLVM-free consumer ran the textures and diagnostics examples and the macro's
runtime contracts. The macro and public binding signatures needed no changes.

- [69_event_filter.das](69_event_filter.das): synchronous queue predicate, borrowed event and Result.

- [70_keyboard_mouse.das](70_keyboard_mouse.das): keyboard/mouse discovery, typed scancodes and text input.

- [71_virtual_gamepad.das](71_virtual_gamepad.das): scoped virtual joystick/gamepad without hardware; typed axis/button event matching.

- [72_peripherals.das](72_peripherals.das): device enumeration with scoped SDL/HID sessions; no hardware output.


- [73_filesystem.das](73_filesystem.das): read-only directory enumeration, glob and path metadata with Result/sdl_try.

- [74_iostream.das](74_iostream.das): dynamic stream, byte roundtrip and EOF with sdl_scope/sdl_try.

- [75_storage.das](75_storage.das): read-only listing through file storage with sdl_scope/sdl_try.

- [76_asyncio.das](76_asyncio.das): asynchronous file loading with owned result bytes.

- [77_audio_devices.das](77_audio_devices.das): audio discovery and explicit device/stream binding.

- [78_audio_stream_controls.das](78_audio_stream_controls.das): in-memory stereo mapping and gain with scoped locking.

- [79_audio_conversion.das](79_audio_conversion.das): PCM mixing and complete-buffer format conversion.

- [80_camera.das](80_camera.das): discover cameras; normal run opens the first camera for one metadata-only frame, smoke only enumerates.

- [81_synchronization.das](81_synchronization.das): synchronous deferred mutex lock, semaphore token/timeout and scoped ownership.

Web: [сборка и запуск HTML-галереи](../web/README.md), исходники восьми SDL-страниц в web/ и двух [OpenGL-страниц](web/opengl/README.md) в web/opengl/. Desktop-нумерация сохранена.

82. [Atomic](82_atomic.das): atomic counter, compare-and-swap and unsigned flags.

83. [Process / LoadSO](83_process_loadso.das): Windows command output and scoped native library lookup.

84. [Platform services](84_platform_services.das): copied locales and optional battery information.
85. [Tray](85_tray.das): scoped tray, checkbox and submenu; five seconds, or immediate smoke test.

## GPU application ports

All ten ports use daScript shader DSL. Vulkan uses the core runner; D3D12 uses
the libraries runner with shadercross. See [backend commands](gpu/README.md#shader-dsl-and-backends).

[gpu/01_metaballs.das](gpu/01_metaballs.das) ports bgfx metaballs with CPU marching
cubes, dynamic vertex upload, depth and lighting. See [usage and API findings](gpu/README.md).

[gpu/03_mesh.das](gpu/03_mesh.das) ports bgfx mesh: Stanford bunny, static vertex/index
buffers, shader deformation, lighting and rendering at the current window resolution.

[gpu/04_instancing.das](gpu/04_instancing.das): an animated cube grid with instance
matrices/colors and a one-draw versus many-draw comparison.
[gpu/05_bump.das](gpu/05_bump.das): fieldstone normal mapping and four moving lights.
[gpu/06_hdr.das](gpu/06_hdr.das): Uffizi/bunny, FP16 rendering, luminance reduction,
bloom and tone mapping. Usage, controls and test details: [GPU examples](gpu/README.md).

88. [System info](88_system_info.das): platform, revision and copied GUID text; noninteractive.

89. [GL context](89_gl_context.das): hidden OpenGL window, context attributes and deferred cleanup.

90. [Vulkan extensions](90_vulkan_extensions.das): copied required instance extensions and scoped loader.

91. [CPU information](91_cpuinfo.das): logical cores, RAM, cache/page sizes, SIMD alignment and features; no SDL initialization.

93. [Surface bytes](93_surface_bytes.das): scoped RGB24 plane access, pitch-aware gradient and copied surface metadata.


## Formatting

Use the official `utils/das-fmt/dasfmt.das` from the pinned daScript checkout.
When a call or record initializer needs multiline arguments, start its arguments
on the next line, indent them four spaces relative to the call's line, and put
one argument per line. Keep compact calls on one line. Packed data-array tables
retain their logical rows. Example 43 demonstrates the style.

The formatter preserves these argument breaks and indentation; it does not
choose this layout automatically. After editing, run formatting and `--verify`.

## Lifecycle pilot

[lifecycle/01_square.das](lifecycle/01_square.das) exports init/update/shutdown
and lets desktop/Web hosts drive frames and conditional GC. The browser page
`09_lifecycle.html` packages this same source. Existing numbered
examples keep their main entry points. See [contract and next stages](../docs/lifecycle-and-live.md).

[lifecycle/02_imgui_widgets.das](lifecycle/02_imgui_widgets.das) runs upstream
v2 widgets with SDLRenderer3 and explicit lifecycle ownership. Desktop ImGui
profile only; see [integration audit](../docs/imgui-widgets-and-live.md).

## Shader DSL

[gpu_dsl](gpu_dsl/README.md) contains shaders written directly in daScript:
[triangle](gpu_dsl/01_triangle.das) and [texture sampling](gpu_dsl/02_texture.das).

## Native live pilot

[live/01_widgets.das](live/01_widgets.das) runs SDL widgets in the upstream
daslang-live host with preserved native resources and JSON-RPC commands.
See [build, run and reload checks](live/README.md).

GPU examples 07–10 adapt bgfx 11-fontsdf, 12-lod, 13-stencil and 14-shadowvolumes.
SDF requires the SDL_ttf libraries runner. See [GPU controls and requirements](gpu/README.md#07–10--bgfx-11–14).
