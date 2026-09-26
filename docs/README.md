# Documentation

Setup, API contracts and supported profiles. Subsystem guides describe lifetime,
error and platform limitations.

## Getting started

- [dasSDL3](../README.md)
- [Examples](../examples/README.md)
- [Installed core SDK](sdk.md)
- [dasSDL3 Web examples](../web/README.md)
- [Remaining work](full-binding-roadmap.md)

## Conventions

- [Boost modules](sdl3-boost.md)
- [SDL results and deferred ownership](error-handling.md)
- [`sdl_try`: early return for SDL Results](sdl-try.md)
- [`sdl_scope` and `sdl_use`: linear scoped acquisition](sdl-scope.md)
- [Boost API ergonomics](api-ergonomics.md)
- [Аудит контрактов boost-слоя](boost-contract-audit.md)
- [SDL binding boundary](gpu-api-boundary.md)

## Generation and coverage

- [Покрытие SDL3](api-coverage.md)
- [Реестр API: первый рабочий профиль](api-inventory.md)
- [dasClangBind: установка и проверка Windows x64](clangbind-setup.md)
- [Сохранённые привязки CppGenBind](clangbind-production.md)
- [CppGenBind / baseline parity](clangbind-parity.md)
- [Генерация типов и строгий AOT](clangbind-types-aot.md)
- [SDL record-field accessibility audit](record-field-accessibility.md)
- [Script accessibility audit (SDL 3.4.16, Windows x64)](script-accessibility.md)
- [Stdinc: script priorities (SDL 3.4.16)](stdinc-policy.md)
- [Remaining non-Stdinc functions: script priorities](remaining-api-policy.md)

## Windows, rendering and pixels

- [Video discovery and window queries](video-discovery.md)
- [Window creation, ownership and state](window-state.md)
- [Fullscreen, window surfaces and remaining window operations](window-io.md)
- [Rect, Clipboard and window hit testing](rect-clipboard-hittest.md)
- [Geometry: проверяемые массивы вершин и индексов](geometry.md)
- [Пиксельные буферы, streaming texture и render target](pixels.md)
- [Complete native Surface and Pixels function declarations](surface-pixels.md)
- [Surface state](surface-state.md)
- [Texture creation and state](texture-state.md)
- [Texture byte state, updates and locks](texture-transfer.md)
- [Software renderer and primitives](renderer-primitives.md)
- [Renderer state](renderer-state.md)
- [Renderer queries and logical presentation](renderer-presentation.md)
- [Renderer YUV planes, color and custom blend](renderer-yuv-blend.md)
- [Renderer creation, drawing and readback](renderer-operations.md)
- [Renderer raw geometry, events and native interop](renderer-final-api.md)
- [SDL 3.4 Surface and Renderer](render-surface-34.md)
- [GL / EGL integration](gl-egl.md)
- [Vulkan / Metal window interop](vulkan-metal.md)

## Input and events

- [Ввод: события, состояние и текст](input.md)
- [Owned event variants](event-variants.md)
- [Event queue](event-queue.md)
- [Events callbacks](event-callbacks.md)
- [IME candidates, clipboard MIME lists and user pointers](event-list-payloads.md)
- [Keyboard and mouse (SDL 3.4.16)](keyboard-mouse.md)
- [Joystick and gamepad](joystick-gamepad.md)
- [Touch, Pen, Sensor, Haptic and HIDAPI](peripherals.md)
- [Common API and display/render/pinch events](common-api.md)

## Audio and camera

- [Аудио: WAV и потоки](audio.md)
- [Audio device discovery and logical ownership](audio-devices.md)
- [Audio stream controls](audio-stream-controls.md)
- [Audio callbacks, WAV IO and conversion](audio-final-api.md)
- [Camera](camera.md)

## Files and platform

- [Filesystem (P4)](filesystem.md)
- [IOStream (P4)](iostream.md)
- [Storage (P4)](storage.md)
- [AsyncIO](asyncio.md)
- [Hints and initialization](init-hints.md)
- [SDL Properties](properties.md)
- [Error, logging and time bindings](diagnostics-time.md)
- [Native callbacks: Hints, Timer, Log, Init and Properties](native-callbacks.md)
- [Synchronization (P7)](synchronization.md)
- [Thread/TLS and Atomic](thread-atomic.md)
- [Process and LoadSO (P7)](process-loadso.md)
- [System, Power, Locale, Dialog and Tray (P7)](platform-services.md)
- [CPU information](cpuinfo.md)
- [Remaining SDL 3.4 additions](sdl-34-remaining.md)

## SDL GPU

- [ASTC transfer infrastructure and capability limitation](gpu-astc.md)
- [GPU Result factories](gpu-factories.md)
- [GPU format queries and color transfers](gpu-formats.md)
- [Typed checked GPU handles](gpu-handles.md)
- [GPU packages 33–35: color targets, mipmaps and scaled blits](gpu-image.md)
- [Несколько SDL GPU devices и Vulkan layers](gpu-multidevice.md)
- [Direct native GPU API](gpu-native-api.md)
- [Native GPU adapters and scopes](gpu-native-boost.md)
- [Native command buffers and fences](gpu-native-fences.md)
- [GPU pipeline descriptors](gpu-pipeline-types.md)
- [Standalone graphics pipelines](gpu-pipelines.md)
- [Direct raw GPU execution tests](gpu-raw-tests.md)
- [Direct SDL GPU command buffers and render passes](gpu-recording.md)
- [Checked standalone GPU samplers](gpu-samplers.md)
- [Standalone GPU shader resources](gpu-shaders.md)
- [Checked GPU swapchain settings](gpu-swapchain.md)
- [RGBA8 GPU texture transfers](gpu-texture-transfer.md)
- [GPU packages 26–29](gpu-texture-types.md)
- [GPU data buffers and asynchronous readback](gpu-transfer.md)
- [Generated GPU types](gpu-types.md)
- [Checked 3D texture transfers](gpu-volume.md)

## Optional libraries

- [Library integration examples](../examples/libraries/README.md)
- [SDL_image](sdl-image.md)
- [SDL_ttf](sdl-ttf.md)
- [SDL_net](sdl-net.md)
- [SDL_mixer](sdl-mixer.md)
- [SDL_sound](sdl-sound.md)
- [SDL_shadercross](sdl-shadercross.md)
