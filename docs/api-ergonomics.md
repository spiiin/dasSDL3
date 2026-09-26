# Boost API ergonomics

The raw SDL declarations and ownership rules are unchanged. These improvements
use pinned daScript language features, standard Result/Option and existing scopes.

## Named initialization

Use `SDL_Rect(x=8,y=8,w=16,h=16)` or `SDL_Rect(w=32,h=32)`.
Unspecified POD fields are zero. Prefer named fields to positional constructors;
format large GPU descriptors over several lines. Keep later assignments when they
actually change state or depend on the object being initialized.

## Temporary RGBA32 pixels

Import `dassdl3/sdl3_pixel_views`; example 61 is a gradient using rows:

```das
with_texture_pixels_rgba8(texture,SDL_Rect(w=32,h=32)) $(pixels) {
    for(y in 0 .. pixels.height) {
        pixels |> with_row(y) $(var row : array<uint>#) {
            for(x in 0 .. length(row)) {
                row[x]=rgba8(uint(x*8),uint(y*8),180u,255u)
            }
            return sdl_ok()
        } |> sdl_try
    }
    return sdl_ok()
} |> sdl_try
```

`SdlPixelView#` exposes width, height and byte pitch, but no pixel pointer. Access
is synchronous and zero-copy; the existing texture scope unlocks after the block.
The annotation disallows copying, moving **and cloning** the view. `#` alone
would not prevent cloning a managed structure. Ordinary safe code cannot retain
the view or move the borrowed row/byte array into owned storage. Explicit array
cloning is allowed: it creates independently owned data. Unsafe pointer extraction
can bypass these language guarantees and is outside this contract.

- `set_pixel(pixels,x,y,uint4(...))` returns Result and validates coordinates and
  all components (0..255). It writes RGBA bytes directly.
- `with_row` lends `array<uint>#` of exactly `width` elements. `rgba8` returns one
  four-byte packed uint in native RGBA32 byte order; it takes the low eight bits
  of each component. A uint4 is only a color argument, never a pixel layout.
- `with_pixels` lends `array<uint8>#`. Its extent is
  `(height-1)*pitch + width*4`, including intermediate row padding but excluding
  trailing padding after the last row. Rows begin at `y*pitch`.
- Texture locks are write-only: initialize the entire locked rectangle; old texels
  are not guaranteed readable. Only RGBA32 is accepted; there is no conversion.
- Row indices follow normal daScript array bounds checks. Use `set_pixel` when a
  coordinate error must be returned as Result. Application panic still skips
  defer in the pinned runtime; these wrappers add no panic/recover bridge.

`with_surface_pixels_rgba8` applies the same idiom to a live RGBA32 surface and
pairs SDL_LockSurface/UnlockSurface. `with_locked_surface_pixels_rgba8` is for a
surface already locked by its owner (e.g. a texture); it neither locks nor owns it.
Keep the surface/texture alive and do not unlock/destroy it in the callback.

This pattern suits synchronous surface memory and mapped GPU transfer memory.
GPU mapping additionally requires capacity and GPU completion proofs, so existing
GPU byte-transfer adapters are retained. It does not make async IO buffers, queued
audio or retained native callback data safe: those require their existing lifetime
contracts. Camera frames may use the surface view only inside the frame lifetime
and only if their format is RGBA32; most camera formats need other layouts.

## Lazy events

`for(event in poll_events())` consumes one owned SdlEvent at a time. Break leaves
later events queued; iteration ends on None, not on a stale SDL error. Owned text
and list payloads use the existing decoder. Like SDL_PollEvent, polling belongs
on the SDL main thread and must finish before SDL teardown. There is no snapshot
allocation, though the daScript generator has a coroutine frame.

There is deliberately no wait_events that silently ends on a wait error. Use
`wait_event()` / `wait_event_timeout()` and explicitly propagate Result. A future
waiting iterator should yield Result values and define cancellation separately.

## Descriptions instead of positional argument lists

- `WindowOptions`: title, size, flags, position. `with_window(settings)` owns the
  created window. Advanced SDL properties remain available through
  `with_window_properties`; no hidden property merging or flag translation.
- `GpuShaderOptions`: path, entrypoint (main), and the native shader `info`
  containing format, stage and resource counts. `with_gpu_shader_file` consumes
  the description synchronously; shader code must still match those counts.
- `GpuGraphicsPipelineOptions`: borrowed vertex/fragment handles, default
  `gpu_graphics_pipeline_info`, and owned arrays of buffers, attributes and color
  targets. Native `info` carries depth, rasterizer and multisample settings;
  color descriptors carry blending. The description owns no GPU resources.

The pinned daScript requires the structure name in these initializers:
`with_window(WindowOptions(title="Example",size=int2(640,480)))`.
`(title="Example",size=int2(640,480))` is a named tuple, not an inferred
WindowOptions; `auto(title="Example")` is not valid syntax. Named function
arguments (`with_window([title=...])`) refer to function parameters and do not
construct its `settings` parameter. Keep explicit option types without adding
a conversion macro solely to omit their names.

Initialization forms checked against the pinned compiler:

| Form | Use |
| --- | --- |
| `WindowOptions(title="Example")` | Preferred gen2 single value; preserves default size. |
| `struct<WindowOptions>(title="Example")` | Works, but longer for a single value. |
| `[[WindowOptions() title="Example"]]` | Legacy syntax, requires `options gen2=false`. |
| `[[WindowOptions title="Example"]]` | Rejected as unsafe: the structure has field initializers. |
| `array struct<WindowOptions>((title="One"), (title="Two"))` | Works in gen2; name the type once for multiple script structures. |

The historical [initialization examples](https://spiiin.github.io/blog/1023396573/)
use the legacy syntax. Do not copy their bare declarations/default-skipping forms
into modern examples. `SDL_Rect(x=8,y=8,w=16,h=16)` is appropriate for a single
native value. Native handled types differ from script structures:
`array struct<SDL_Rect>(...)` is rejected by this compiler; use explicit element
constructors for those arrays. Prefer `var targets <- array(SDL_GPUColorTargetInfo(
texture=texture, clear_color=SDL_FColor(r=0.05,b=0.15,a=1.0)))` to resize followed
by element assignments. For formula-based values use an array comprehension,
for example `[for (i in 0 .. 3); SDL_FRect(x=float(i*45),w=35.0,h=65.0)]`.
Keep resize for output buffers, padded binary data and arrays reused across frames;
do not rebuild such buffers on every iteration just to shorten their declaration.

Examples 42, 43 and 61 show these forms. Shader format/stage and target format
remain explicit instead of guessing a backend. Existing small positional helpers
remain useful. No mesh/material/scene/plan abstraction is introduced.

## Compound returns and mutation

Prefer the no-output overloads for scalar/struct queries. Existing window,
renderer, surface and GPU queries already had most of them; new overloads fill
mouse state, key-to-scancode mapping, IME area, gamepad touchpad finger, audio device
format, audio stream formats and WAV-from-IO gaps. WAV bytes move with their spec.

`read_io(io,bytes,count)` and `write_io(io,bytes,count)` return IoTransfer:
`transferred` plus `status : Result<SDL_IOStatus,SdlError>`. Keeping status inside
the compound value preserves partial byte counts **even on error**. Inspect or
propagate `transfer.status`; do not assume every short read is a failure. The
legacy explicit count-reference overload is retained for compatibility and offset
control; the compound overload deliberately has only three arguments to avoid
ambiguity with the existing transferred-reference parameter.

Keep mutable caller buffers (`read_audio`, `mix_audio`, sensor/HID reads), in/out
state (atomic/TLS), transformed events and consuming handles (`close_io`). Raw
SDL out parameters are unchanged. Ref query overloads remain compatible, while
examples prefer returned values (58, 70, 74, 77).

## Consuming commands and passes

Checked recording IDs already reject repeat end/submit/cancel through their
registry. Native boost submit/cancel/submit_fence now reject a null command before
SDL. `native_gpu_end_copy_pass`, `native_gpu_end_render_pass` and
`native_gpu_end_compute_pass` end then clear the reference; a second call returns
an error. Native pass scopes lend mutable references and skip automatic end
if the body already consumed that reference:

```das
var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
```

This is not linear ownership: separately copied raw pointers can still be stale.
Do not consume a command with open passes or a borrowed swapchain command. Raw
SDL calls cannot update boost variables; use consuming helpers inside scopes.
No native-pointer registry or checked-ID bridge is introduced.

## Verification and references

Tests: `pixel_views.das`, `test_pixel_view_escape.py`, `event_queue.das`,
`compound_returns.das`, existing audio/input/IO tests and `gpu_native_adapters.das`.
Tests cover pixel bytes, cleanup after body error, temporary escape rejection,
iterator early break, partial IO errors and repeated command/pass consumption.
Interpreter, baseline/CppGenBind and AOT are checked separately; Web view exports
are not part of this native change.

References: [Rust API return values](https://rust-lang.github.io/api-guidelines/predictability.html#functions-do-not-take-out-parameters-c-no-out),
[EventPump](https://docs.rs/sdl3/latest/sdl3/struct.EventPump.html),
[WindowBuilder](https://docs.rs/sdl3/latest/sdl3/video/struct.WindowBuilder.html),
[public type aliases](https://deterministic.space/elegant-apis-in-rust.html#public-type-aliases).
The last article discusses aliases; aliases alone do not introduce error variants.

### Local validation (2026-09-22, Windows x64)

- Main regression selection: 140/140; later affected selection: 17/17.
- Baseline/CppGenBind/AOT selection: 107 cases resolved successfully. One new
  compound-return test initially had stale AOT output; adding its imported boost
  modules to CMake dependencies regenerated it, and its repeat passed. This was
  a dependency fix, not a disabled AOT check or interpreter fallback.
- Standalone clangbind smoke: interpreter and AOT 2/2, including the shortened
  managed-structure initializers.
- Consumer built with LLVM/Clang/Python package discovery disabled; all 54 boost
  modules import, pixel views/escape checks and examples 61, 67 and 74 pass.
- Production generator configuration restored; bindings freshness, documentation
  links and whitespace checks pass. Raw declaration coverage remains unchanged.

Pixel views are currently exported by the native module; adding them to the Web
profile and rebuilding its packaged scripts is a separate platform follow-up.

## Graphics pipeline builder

The mutating builder uses the existing GpuGraphicsPipelineOptions descriptor:

```daslang
var settings <- gpu_pipeline(vertex,fragment)
settings |> vertex_buffer(0u,20u)
settings |> vertex_attribute(0u,0u,SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3,0u)
settings |> vertex_attribute(1u,0u,SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2,12u)
settings |> color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
settings |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
settings |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS)
settings |> depth_write(true)
let pipeline : GpuPipelineHandle = device |> with_gpu_graphics_pipeline(settings) |> sdl_use
```

The final line belongs inside sdl_scope. Builder calls return void and mutate the
receiver; use separate pipe statements, not a chain of returned copies. Buffer,
attribute and color-target calls append; duplicate slots/locations are not silently
replaced. Validation stays in the existing creation path. Color targets also accept
a complete SDL_GPUColorTargetDescription for explicit blending. Depth setters only
change their named state: depth_target does not enable depth testing/writing;
depth_test(compare,false) disables testing; depth_write(false) disables writes.
Native descriptor fields remain directly editable. The descriptor owns its arrays,
not shaders or GPU resources. Shader inputs and pass attachments must match it.
Example 43 demonstrates acquisition. tests/gpu_pipeline.das exercises reordered
vertex/instance slots and depth state through real pipeline creation.

## Public SDL result type names

`SdlStatus` is a public typedef for `$Result<SdlUnit; SdlError>`.
`$SdlResult<T>` is a public type macro for `$Result<T; SdlError>`:

```daslang
def render_triangle(device : SDL_GPUDevice?) : SdlStatus { /* ... */ }
def load_value() : $SdlResult<int> { return ok(42,type<SdlError>) }
```

Both resolve to the standard Result type, with identical layout and ownership.
Existing ok/err, move_ok/move_err, is_ok/is_err, unwrap/move_unwrap and sdl_try
continue to work; no conversion is necessary. Keep type<SdlError> on constructors.
Use SdlStatus for success without a payload and $SdlResult<T> for a payload.
Nested $SdlResult<$Option<T>> still distinguishes absence from failure.
These aliases do not change checked GPU handle types or resource ownership.
The generic alias uses the pinned standard Result's canonical tuple layout;
tests/sdl3_result.das checks compatibility, move-only values and propagation.
Existing explicit Result signatures remain valid and can be migrated incrementally.

## GPU shader builder

The shader builder uses the existing GpuShaderOptions and scoped ownership:

```daslang
var description = gpu_shader(path,format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
description |> entrypoint("main")
description |> samplers(1u)
description |> uniform_buffers(1u)
let shader : GpuShaderHandle = device |> with_gpu_shader_file(description) |> sdl_use
```

The acquisition line belongs inside sdl_scope. The constructor defaults to entry
point main and zero resource counts. Setters return void and overwrite only their
named field; storage_buffers and storage_textures work the same way. They describe
trusted compiled shader code, not automatic reflection: counts must match its SDL
binding ABI. Validation and resource creation remain in with_gpu_shader_file.
The options own no GPU resources; native info fields remain directly editable.
Example 42 uses the constructor; tests/gpu_shader.das verifies nonzero sampler and
uniform counts using the lit shader, plus overwrite/reset of storage counts.

## GPU texture descriptor builder

The builder returns SDL_GPUTextureCreateInfo itself and is available from
sdl3_gpu_native_boost. It feeds native pointer creation/scopes, not checked IDs:

```daslang
var description = gpu_texture(256u,128u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,
    SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)
description |> texture_shape(SDL_GPUTextureType.TEXTURETYPE_2D_ARRAY,4u)
description |> mip_levels(5u)
let result = with_native_gpu_texture(device,description) $(var texture : SDL_GPUTexture?) {
    // Use texture while its device and this scope remain alive.
    return sdl_ok()
}
```

Defaults: 2D, one layer, one mip level, SAMPLECOUNT_1, zero properties.
texture_shape sets the type and SDL layer_count_or_depth together; the caller
supplies the appropriate array layer count, cube face count or volume depth.
mip_levels, sample_count and texture_usage overwrite their field and return void.
texture_usage replaces the entire mask; combine flags explicitly with bitwise OR.
All descriptor fields remain directly editable. No resource is owned by the
builder. It does not infer mip counts, clamp dimensions, check device support or
repair invalid combinations (for example MSAA with mipmaps). SDL validates creation;
query device capabilities when choosing optional formats or sample counts.
Example 37 shows defaults. tests/gpu_native_adapters.das uses the builder for real
MSAA render/resolve pixel checks and creation of a mipmapped two-layer texture.

## GPU sampler descriptor builder

Available from sdl3_gpu_sampler_boost; returns SDL_GPUSamplerCreateInfo:

```daslang
var description = gpu_sampler()
description |> filters(SDL_GPUFilter.FILTER_LINEAR)
description |> mipmap_mode(SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR)
description |> address_modes(SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
description |> anisotropy(4.0)
let sampler : GpuSamplerHandle = device |> with_gpu_sampler(description) |> sdl_use
```

The acquisition line belongs inside sdl_scope. Defaults are the existing
gpu_sampler_info defaults: nearest min/mag/mip filters, clamp on all axes,
LOD range 0..1000, zero bias, comparison and anisotropy disabled.
filters accepts one filter or separate min/mag filters and does not change mipmap
mode. address_modes accepts one mode or separate U/V/W modes. lod_range and
lod_bias set their named fields. anisotropy(maximum,enabled=true) and
comparison(operation,enabled=true) set both the value and enable flag;
pass false to disable. Each setter returns void and overwrites its fields.
No validation/clamping or capability inference occurs in setters. Existing
creation validation and checked descriptor normalization remain unchanged.
The descriptor also works with with_native_gpu_sampler; that scope returns a
native SDL_GPUSampler pointer rather than a checked GpuSamplerHandle.
Example 41 demonstrates the builder; gpu_sampler tests query real created
samplers for filter, axis, LOD, compare and anisotropy settings and retain their
existing ownership checks.

## GPU compute pipeline descriptor builder

Available from sdl3_gpu_native_boost; returns SDL_GPUComputePipelineCreateInfo:

```daslang
var description = gpu_compute_pipeline(format)
description |> threadgroup(4u,1u,1u)
description |> readwrite_storage_buffers(1u)
description |> uniform_buffers(1u)
let pipeline = device |> load_native_gpu_compute_pipeline(description,path,"main") |> sdl_try
```

Release this pipeline with SDL_ReleaseGPUComputePipeline, or pass the descriptor
to with_native_gpu_compute_pipeline_file/bytes for existing scoped ownership.
The constructor defaults to threadgroup 1x1x1, zero resource counts/properties and
no code pointer. Format is explicit. File/byte loaders supply code and entrypoint;
do not put borrowed script string or array pointers into the descriptor.
Setters return void and overwrite only their fields: threadgroup, samplers,
uniform_buffers, readonly_storage_textures, readonly_storage_buffers,
readwrite_storage_textures and readwrite_storage_buffers. Counts and threadgroup
must match the trusted compiled shader and SDL binding ABI; there is no reflection,
validation or clamping in the builder. threadgroup specifies shader local size,
not the number of groups passed to SDL_DispatchGPUCompute. Fields remain editable.
Example 49 verifies dispatch output by readback; native adapter tests cover both
file and byte loading with the same descriptor. Nonzero texture/sampler/readonly
resource combinations are not newly GPU-tested by this builder change.

## Graphics pipeline state builders

GpuGraphicsPipelineOptions and native SDL_GPUGraphicsPipelineCreateInfo both
accept topology(kind), rasterizer(SDL_GPURasterizerState), sample_count(count)
and multisampling(SDL_GPUMultisampleState). The state-object setters replace the
complete state, while sample_count changes only its named field. Explicitly set
enable_depth_clip when constructing a new rasterizer state; a zero-initialized
state does not inherit gpu_graphics_pipeline_info defaults.

Color targets accept blending(SDL_GPUColorTargetBlendState) and
color_write_mask(uint8_mask,enabled=true). Configure a target before appending it:

```daslang
var target = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
var blend = target.blend_state
blend.enable_blend = true
blend.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA
blend.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
target |> blending(blend)
description |> color_target(target)
```

blending replaces the entire blend state, including write-mask settings; ordering
therefore matters. color_target copies the descriptor, so later target edits do
not change an appended target. Setters return void and preserve existing creation
validation. MSAA must match pass attachments and device support. Complete SDL
state structs expose advanced fields without additional wrapper types.
Example 43 uses topology, back-face culling and sample count. gpu_pipeline tests
exercise blend/write-mask pixel results and supported MSAA pipeline creation.

## Example migration to builders and public aliases

The numbered desktop examples use SdlStatus for unit-valued SDL results.
Examples 43/45/46 use shader options; 45/46 use the graphics pipeline builder for
vertex layouts and color targets. Metaballs and SDL_ttf GPU text use gpu_texture
for their native texture defaults. Existing short helpers (such as sampler_info
with one filter) remain where a sequence of setters would be longer.
Example 44 retains explicit acquisition/release, illustrating direct resource
ownership. Native struct initializers remain useful examples of the underlying
SDL API. Builders must preserve descriptor defaults rather than silently change
filtering, LOD ranges or lifetime. Web examples retain explicit Result spellings
pending their separate wasm validation; their syntax remains supported.

## Shared shader options, depth/stencil, and window flags

Native shader loading now accepts the same GpuShaderOptions as checked loading:

```daslang
var shader = gpu_shader(path,format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
shader |> uniform_buffers(1u)
shader |> entrypoint("main")
let native = device |> load_native_gpu_shader(shader) |> sdl_try
```

Release native with SDL_ReleaseGPUShader, or use
with_native_gpu_shader_file(device,shader) for scoped ownership.
with_native_gpu_shader_bytes(device,bytes,shader) uses info/entrypoint and ignores
path. Options own their strings, never the shader; native pointers and checked
handles retain their different ownership contracts. sdl3_gpu_native_boost now
publicly requires sdl3_gpu_shader_boost; explicit SDK AOT MODULES must include
that transitive shared module when these helpers are used.

Both GpuGraphicsPipelineOptions and SDL_GPUGraphicsPipelineCreateInfo accept
complete depth_stencil(SDL_GPUDepthStencilState), depth_target, depth_test,
depth_write, stencil_test(bool=true), stencil_faces(front,back) or
stencil_faces(both), and stencil_masks(uint8_compare,uint8_write).
depth_stencil replaces the entire state; the other setters alter only named
fields. Face/mask setters do not enable stencil or select an attachment format.
Set stencil_test explicitly and provide a compatible depth/stencil target.
Stencil reference remains a dynamic command via SDL_SetGPUStencilReference.
Native/checked creation validation is unchanged; current builder tests verify
created pipeline descriptors, not a new stencil-specific pixel oracle.

WindowOptions gains window_options(title,int2_size), window_flags(mask,enabled=true)
and window_position(int2). Defaults remain resizable, 640x480 in the underlying
struct, undefined position. The constructor takes explicit size; flag toggles
preserve unrelated bits and false clears only the supplied mask. A full flags
replacement is still settings.flags = mask. Example 02 uses a conditional hidden
flag; tests/window_state.das verifies flags and actual window creation. Simple
one-line with_window calls and named struct initialization remain supported.
