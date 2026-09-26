# GPU Result factories

Checked resource creation now has explicit `create_gpu_*`, `load_gpu_shader`,
`acquire_gpu_command_buffer` and `request_gpu_*_readback` factories. Each calls
one existing checked adapter and returns `Result<its distinct handle,SdlError>`.
The operation field identifies that adapter, such as `SDL_CreateGPUCheckedGraphicsPipeline`.
No resource owner or renderer object is introduced.

```daslang
pipeline = device |> create_gpu_graphics_pipeline(vertex,fragment,info,buffers,attributes,colors) |> sdl_try
target = device |> create_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) |> sdl_try
command = device |> acquire_gpu_command_buffer() |> sdl_try
```

`checked_handle_result(handle, operation)` is the shared conversion in
`sdl3_gpu_result`, re-exported by GPU boost. Ten private `is_invalid_gpu_handle`
overloads accept the [distinct checked GPU types](gpu-handles.md); unsupported
types fail overload resolution at compile time. Zero produces Err;
nonzero preserves the exact type, even with a stale SDL error string. Error text
is copied immediately. Ordinary numbers, bool predicates and native pointers
are rejected; optional swapchain absence must not be converted to an error.
This helper does not prove that a nonzero manually constructed handle is live.

| Module | Factories |
| --- | --- |
| `sdl3_gpu_transfer_boost` | `create_gpu_buffer`, `request_gpu_buffer_readback` |
| `sdl3_gpu_buffers_boost` | `create_gpu_vertex_buffer`, `create_gpu_index_buffer` |
| `sdl3_gpu_texture_transfer_boost` | `create_gpu_transfer_texture`, `create_gpu_color_texture`, `request_gpu_texture_readback` |
| `sdl3_gpu_image_boost` | `create_gpu_color_target_texture` |
| `sdl3_gpu_volume_boost` | `create_gpu_volume`, `request_gpu_volume_readback` |
| `sdl3_gpu_shader_boost` | `create_gpu_shader`, `load_gpu_shader` |
| `sdl3_gpu_sampler_boost` | `create_gpu_sampler` |
| `sdl3_gpu_pipeline_boost` | `create_gpu_graphics_pipeline` |
| `sdl3_gpu_recording_boost` | `acquire_gpu_command_buffer` |

The existing `gpu_begin_render_pass` also uses the common conversion. Checked
`with_*` resource scopes delegate acquisition to the factories, then preserve
their normal cleanup and body-result rules. Acquisition errors now name the
underlying checked SDL adapter rather than the scope helper. GPU device scope
error names are unchanged, preserving unavailable-device smoke-test handling.

For the native-pointer examples, `sdl3_gpu_native_boost` additionally provides
`create_native_gpu_device`, `create_native_gpu_buffer`,
`create_native_gpu_transfer_buffer`, `load_native_gpu_shader`,
`load_native_gpu_compute_pipeline`, `create_native_gpu_graphics_pipeline` and
`acquire_native_gpu_command_buffer`. Their Results retain native pointer types
and SDL ownership. A private null-to-error helper is used only for these
non-optional acquisitions. Swapchain continues to return Result<Option<...>>.

## Ownership and early return

Use a matching `defer` after successful acquisition, or a `with_*` scope. A Result
does not release a resource. Example 44 predeclares zero handles and has a single
cleanup block; its assignments use `sdl_try`. On Err, assignment is skipped and
earlier handles are still available to cleanup. Examples 47–50 retain their
native cleanup scopes and use the native Result factories. Submission still
consumes a command even on failure; `native_gpu_submit_fence` clears its ref
argument before returning Err. Do not replace that with a non-consuming helper.

See [sdl_try placements](sdl-try.md). Assignment is supported only for a variable
target, not an index or field expression. The macro performs no panic or catch.

`tests/gpu_factories.das` checks all ten nominal types, preserved success under a
stale error, copied errors after later SDL calls and factory error operation names.
`tests/sdl3_try.das` checks failed/successful and moving assignments with defer.
GPU scope/pixel/readback tests exercise the factories through existing owners;
compile-negative handle tests reject numbers and pointers passed to the helper.
