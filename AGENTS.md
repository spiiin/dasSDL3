# dasSDL3 project guide

Read `docs/bgfx-idioms.md` before designing or changing the daScript-facing API.
It records inspected dasBGFX/daScript revisions, source links, idioms and their
ownership limitations. Read `docs/sdl3-boost.md` for this project's API decisions
and verified behavior. Keep both documents current when behavior changes.
Track implemented scenarios and remaining subsystems in `docs/api-coverage.md`.
The first target-specific census is documented in `docs/api-inventory.md`.
LLVM SDK installation and the dasClangBind preflight are documented in
`docs/clangbind-setup.md`; passing this probe does not complete generator/AOT gates.
The bounded CppGenBind/interpreter/AOT experiment is in `docs/clangbind-experiment.md`.
Run its standalone `tests/clangbind` CMake project before expanding the selection;
50-function interpreter parity is now covered by `tests/clangbind_parity` and
`docs/clangbind-parity.md`. Its extension now generates type/constant policy
independently and runs resource AOT: read `docs/clangbind-types-aot.md`.
The pinned AOT try/recover ordering needs a local generator workaround; preserve
the negative missing-AOT test and panic-message regressions. Production snapshot
selection and LLVM-free source builds are described in `docs/clangbind-production.md`.
Install/export packaging is not yet provided. Do not
treat its borrowed pointer fixture as a safe public GPU builder.
Regenerate `docs/generated/api-*` with `tools/inventory_api.py`; do not edit
snapshots by hand. Keep inactive-platform and manual-adapter coverage explicit.
Audio contracts and testing limitations are in `docs/audio.md`.
Pixel buffer, streaming texture and render-target contracts are in `docs/pixels.md`.
Geometry arrays and nested SDL_Vertex ABI are documented in `docs/geometry.md`.
GPU ClearScreen contracts and unfinished gates are in `docs/gpu-clear.md`.
Triangle, checked pipeline IDs and shader asset ABI are documented in
`docs/gpu-triangle.md`. Multiple scoped devices and the FPS Monitor Vulkan layer
conflict are covered in `docs/gpu-multidevice.md`; do not restore a global
one-device limit or silently disable validation. Never add Vulkan shader
Y inversion: SDL already flips its viewport. Keep pixel-reference tests on
Vulkan and D3D12; test-only readback is not public GPU API coverage.
The immutable vertex-buffer/texture/sampler bundle is documented in
`docs/gpu-mesh.md`. Mesh and triangle IDs share one monotonic namespace
(`SDL_GPUNextPipeline`) to reject cross-kind aliases. Immutable UINT32 indexed
meshes are covered in `docs/gpu-indexed-mesh.md`. Validate every index before GPU
allocation; empty indices must never fall back to sequential drawing.
General layouts and dynamic updates remain unimplemented. Preserve device-specific
cleanup: destroying B must not release A's meshes or pipelines.
Vertex uniform transforms use a separate trusted shader ABI; see
`docs/gpu-transform.md`. Two float4 rows occupy exactly 32 bytes at offsets 0/16.
Keep plain and transform mesh draw contracts distinct, validate rows before
command acquisition, and preserve CPU pixel references for rotation/scale/translation.
3D color meshes, column-major float4x4 MVP and cached depth targets are covered
in `docs/gpu-3d.md`. Use math_boost perspective_rh_0_to_1, not its deprecated
perspective_rh/opengl variants. Depth dimensions come from acquired swapchain;
prepare failure must submit, never cancel. Preserve order-independent depth pixel
tests, resize/cache failure tests and device-specific depth cleanup.
Textured Lambert meshes use `sdl3_gpu_lit_boost`; see `docs/gpu-lit.md`.
Preserve stride48, 112-byte MVP/normal vertex uniform and 16-byte fragment light.
Use inverse-transpose normals for affine nonuniform/negative scale; reject
singular/nonfinite transforms before command acquisition. Keep independent
CPU normal/UV/lighting pixel references and the separate mesh registry.
Lit draw lists and scene-owned shared depth are documented in `docs/gpu-scene.md`.
Validate the entire bounded list before command acquisition; no script callbacks
while recording. Lists own values, not meshes; resolve IDs on every draw.
Empty lists clear/present. Preserve cross-object depth, per-object uniforms,
late-invalid-item rejection and scene/mesh independent cleanup tests.
Keep GPU scopes separate from SDL_Renderer. Never cancel after a non-null
swapchain texture; submit consumes the command even on failure. Keep recording
native-only until general GPU handle/state contracts are implemented and tested.
GPU window regressions live in tests/gpu_windows.das. Minimized does not imply
NULL swapchain; assert observed window state, accept submitted or skipped frames,
and report hardware observations separately from mock coverage.
Use `git --no-optional-locks status` for read-only inspection: automatic index
refresh can recreate .git/index as CodexSandboxOnline and break sandbox ACL setup.
Before expanding coverage, read `docs/full-binding-roadmap.md` and
`docs/binding-design-review.md` (research dated 2026-09-19). GPU/shader work is
planned in `docs/gpu-roadmap.md`, optional libraries in
`docs/companion-libraries-roadmap.md`, and example/contract selection in
`docs/porting-matrix.md`. Unchecked roadmap stages are not implemented API. Keep the current
generator until the documented dasClangBind feasibility gates pass. Count API
coverage against pinned headers, not the moving SDL wiki. Reuse standard
Result/Option and investigate existing dasSpirv/layout helpers before inventing
equivalents; source inspection alone does not establish runtime correctness.

- Keep generated bindings in `src/generated/`; change `tools/bindings.json` or
  `tools/generate_bindings.py` (legacy) or `tools/clangbind_parity.das` and
  `tools/run_clangbind_parity.py --snapshot`, then regenerate. Never hand-edit generated files.
- Put script helpers in `dassdl3/sdl3_boost.das` and native adapters in
  `src/sdl3_adapters.h`. Keep the raw `sdl3` module available.
- Keep `examples/02_square.das` free of unsafe blocks and raw address operations.
  Use value/reference helpers and scoped cleanup. Do not weaken pointer checks
  to make code compile. Hidden unsafe operations are not an ownership guarantee.
- Prefer with_sdl/with_window/with_renderer for ownership scopes. In the pinned
  interpreter, panic skips defer/finally (verified); these helpers catch locally,
  clean up, then propagate the error. Do not replace them with defer-only cleanup.
  Verify renderer -> window -> SDL_Quit order on return, panic and partial init.
- Resource blocks invoke callbacks through `src/sdl3_scopes.h`. It restores
  interpreter block arguments after panic; plain invoke can corrupt an outer
  block's arguments when it catches a nested failure. Keep the nested-recovery
  regression in tests/textures.das and recheck this workaround on daScript updates.
- Texture scopes must end before their renderer. Surface-to-texture creation
  copies pixels and does not transfer surface ownership. Keep SDL_Surface and
  SDL_Texture opaque until a separately reviewed pixel-buffer API is available.
- Pixel helpers use `dassdl3/sdl3_pixels_boost.das` and `src/sdl3_pixels.h`.
  RGBA8 arrays are copied synchronously; no borrowed SDL pixel pointer escapes.
  Validate pitch and required byte count before locking; retain native unlock guards.
  Restore the previous render target before destroying target textures, also on panic.
  Keep pixel roundtrip/padding/overflow and nested target cleanup tests in interpreter/AOT.
- Prefer renderer-first functions for pipe syntax. State component ranges,
  null behavior, error policy, and whether data is borrowed or copied.
- Geometry lives in `src/sdl3_geometry.h` and `dassdl3/sdl3_geometry_boost.das`.
  Validate counts before narrowing, all indices before SDL, finite positions and
  normalized RGBA/UV. Empty indexed draws are no-ops, never sequential fallback.
  Preserve nested field ABI assertions, image parity and array lifetime tests in AOT.
- Input adapters live in `src/sdl3_input.h`. Read the event tag before its
  union member; clear outputs on a mismatch. Copy UTF-8 text into the daScript
  heap before the next SDL poll/pump. A copied raw SDL_Event does not own text.
- Scalar output parameters in daScript require explicit references:
  `var text : string&`, `var start : int&`, `var position : float2&`.
  `var` alone makes a mutable value parameter; managed structs are different.
- `with_text_input` preserves an existing session; only the scope that started
  it stops it. Keep polling, input state queries and window operations on the
  main thread. Synthetic PushEvent input does not update keyboard/mouse state.
- Audio helpers live in `dassdl3/sdl3_audio_boost.das` and `src/sdl3_audio.h`.
  WAV buffers belong to opaque SDL_Wav objects and use SDL_free. Audio stream
  queues copy data; array adapters must handle empty arrays and reject sizes
  above INT_MAX before casting. Never retain script array pointers or invoke
  script blocks from SDL's audio thread. Destroy device streams before SDL_Quit.
  Tests use SDL_AUDIO_DRIVER=dummy only in their process environment; do not
  change the user's normal backend or claim audible output was verified.
- Prefer implicit trailing blocks in gen2 code: `with_sdl() { ... }` for a
  zero-argument block and `with_window(...) $(window) { ... }` for a block
  with arguments. Omit `<|`; omit `$()` only for a zero-argument block.
  This also works with pipes: `window |> with_renderer() $(renderer) { ... }`.
  Verified by the example and boost lifetime tests on the pinned interpreter.
- daScript is a pinned submodule. Avoid editing its source to fix our bindings.
- Build instructions are in README.md. On this machine Ninja with vcvars64 works;
  MSBuild's SDK scan previously hit sandbox permissions. Build with 6 parallel
  jobs. Run the project's CTest filter rather than all upstream tests.
- Do not commit or publish unless asked. Preserve unrelated user changes.
- Keep example filenames numbered in learning order (01_, 02_, ...), documented
  in examples/README.md. Update CMake/AOT lists and documentation when renaming.

Immutable instancing uses sdl3_gpu_instancing_boost; see docs/gpu-instancing.md.
Keep per-vertex stride48 and per-instance stride112 (model4 + normal3 columns),
64-byte camera and 16-byte light uniforms. SDL instance_step_rate is reserved
and must be zero. Reject instanced IDs in ordinary lit/scene draws. Validate all
1..4096 models before allocation; copy arrays; keep one indexed draw per frame.
