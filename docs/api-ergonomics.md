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
