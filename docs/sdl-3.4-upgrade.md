# SDL 3.4.16 upgrade

The desktop, C++ test app and web source pins move from SDL 3.2.18 to
[SDL 3.4.16](https://github.com/libsdl-org/SDL/releases/tag/release-3.4.16).
The daScript pin is unchanged. Optional image 3.2.4, ttf 3.2.2 and net 3.2.0
remain pinned. SDL_mixer is a subsequent integration; its stable 3.2.x needs
SDL >= 3.4.0 and uses the new audio stream APIs.

## Binding changes

- Regenerated legacy Clang-AST and CppGenBind snapshots against the same headers.
- Existing enums include the new values (pixel-art scaling, combined flips,
  GameCube gamepad type and sensor count).
- `SDL_GetCameraPermissionState` and boost `camera_permission_state` now return
  `SDL_CameraPermissionState` with DENIED/PENDING/APPROVED values. Callers compare
  enum values rather than integers. The underlying numeric values remain -1/0/1.
- SDL_HapticEffectID is an int typedef; haptic ABI remains the same.
- Clipboard MIME pointer constness and RGB/RGBA argument names follow new headers.
- Three new GPU queries (device properties and pixel/texture format conversions)
  and SDL_AddAtomicU32 have bindings and direct runtime test calls.
- GPU raw test matrix expands to 95 functions; Atomic to 16. D3D12 debug group
  calls are exercised again: upstream now uses PIX and may no-op without the
  runtime DLL. Executing them does not demonstrate capture labels are visible.
- Web's separate wasm32 snapshot is regenerated against the updated headers.

## Existing workarounds

Window-shape removal with NULL was fixed upstream; the test now expects success.
Global keyboard/mouse ID 0 now has a name. Invalid postmix device IDs now return
an error, and failed texture scale-mode queries initialize to INVALID. Tests
follow these upstream contracts. Swapchain body-result tests use a visible
window: hidden Vulkan windows may legitimately return successful None.
The short-write SDL_SaveFile_IO loop and missing virtual joystick ball count are
still present in the inspected 3.4.16 sources; their regression oracles remain.
The default audio channel-map getter crash is fixed upstream; new raw tests
check NULL/default maps without an error. Copied boost getters remain a follow-up.
The Emscripten backend creates an empty recording object when opening playback.
After playback closes that placeholder prevents AudioContext.close. The web host
closes a remaining context only after full SDL_Quit; tests retain their strict
Stop/partial-init cleanup checks. Upstream sources are unchanged.
Other historical version-specific notes remain historical until tested; this
upgrade does not automatically delete defensive adapters or promise fixes.

## Coverage

Windows inventory: 965 generated, 14 adapted, 284 pending out of 1263 active
non-excluded functions. Header update adds 37 functions; four are included in
this migration, and the remaining 33 need their own API/lifetime/runtime work.
This is not a claim of full SDL 3.4 coverage. Pending additions:

- `SDL_CreateAnimatedCursor`
- `SDL_CreateGPURenderState`
- `SDL_CreateGPURenderer`
- `SDL_DestroyGPURenderState`
- `SDL_GetDefaultTextureScaleMode`
- `SDL_GetEventDescription`
- `SDL_GetGPURendererDevice`
- `SDL_GetPenDeviceType`
- `SDL_GetRenderTextureAddressMode`
- `SDL_GetSystemPageSize`
- `SDL_GetTexturePalette`
- `SDL_GetWindowProgressState`
- `SDL_GetWindowProgressValue`
- `SDL_LoadPNG`
- `SDL_LoadPNG_IO`
- `SDL_LoadSurface`
- `SDL_LoadSurface_IO`
- `SDL_PutAudioStreamDataNoCopy`
- `SDL_PutAudioStreamPlanarData`
- `SDL_RenderTexture9GridTiled`
- `SDL_RotateSurface`
- `SDL_SavePNG`
- `SDL_SavePNG_IO`
- `SDL_SetDefaultTextureScaleMode`
- `SDL_SetGPURenderState`
- `SDL_SetGPURenderStateFragmentUniforms`
- `SDL_SetRelativeMouseTransform`
- `SDL_SetRenderTextureAddressMode`
- `SDL_SetTexturePalette`
- `SDL_SetWindowFillDocument`
- `SDL_SetWindowProgressState`
- `SDL_SetWindowProgressValue`
- `SDL_hid_get_properties`

## Validation

- Main project CTest: 236/236 passed across the initial run and targeted reruns
  after adapting version-specific expectations. Includes Vulkan/D3D12 raw GPU
  execution and the enabled ImGui/image/ttf/net packages. Extra upstream
  daScript standalone targets were not built and are outside this project count.
- C++ test-app Release build passed with the new source override.
- Legacy Clang-AST, CppGenBind snapshot and wasm32 generation freshness passed.
- Legacy/CppGenBind/AOT CTest: 661/661 passed (660 runtime/metadata/negative tests
  plus the generator error test after restoring the desktop Clang module).
- No-LLVM consumer: generator/LLVM/Clang/Python discovery disabled; saved snapshot
  build and runtime version/events checks passed, as did NET test/example.
- Web Release build: Emscripten 5.0.3, existing -O1 link profile. Edge and Firefox
  each passed 15 Renderer/audio/lifecycle/failure scenarios and six OpenGL
  scenarios: 42 total. Physical audio output, Safari and web AOT are unverified.
- Documentation links, whitespace checks and inventory freshness passed.

Validation was performed on Windows x64 on 2026-09-26. This is compatibility
validation for the existing bindings, not execution coverage of all 1263 SDL
functions or all platform branches. New raw calls have test receipts; added
pixel-art/GameCube enum values alone do not certify hardware behavior.

## Existing build directories

An old `FETCHCONTENT_SOURCE_DIR_SDL3` cache entry overrides the release tag.
Clear that override (`cmake -U FETCHCONTENT_SOURCE_DIR_SDL3 ...`) or point it to
an actual 3.4.16 source tree before rebuilding. Do this for desktop, test-app and
web separately. Do not reuse 3.2.18 include paths when regenerating/parity testing.
The compiled binding has an exact SDL_VERSION guard to reject mismatched headers.
