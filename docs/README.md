# Документация dasSDL3

- [SDL_ttf](sdl-ttf.md): Font/TextEngine/Text, UTF-8, ownership, dependencies and tests.

- [SDL_image](sdl-image.md): PNG/JPEG, surface/texture/animation, IO ownership и тесты.

- [ImGui + SDL3 и примеры дополнительных библиотек](../examples/libraries/README.md).

## Начать

- [Сборка и запуск](../README.md), [примеры](../examples/README.md).
- [Покрытие](api-coverage.md), [реестр](api-inventory.md), [следующие этапы](full-binding-roadmap.md).
- [Граница публичного API](gpu-api-boundary.md), [ошибки и defer](error-handling.md).

## Генерация и идиомы

- [Установка dasClangBind](clangbind-setup.md), [production snapshots](clangbind-production.md).
- [Parity](clangbind-parity.md), [типы и AOT](clangbind-types-aot.md).
- [dasBGFX idioms](bgfx-idioms.md), [design review](binding-design-review.md), [boost](sdl3-boost.md).
- [sdl_scope / sdl_use](sdl-scope.md): линейная запись scoped-вызовов; [sdl_try](sdl-try.md): ранний возврат ошибки.

## API

- [Boost API ergonomics](api-ergonomics.md): named initialization, temporary pixel views, event iteration, descriptions and compound returns.


- [Platform services (P7)](platform-services.md): System/Power/Locale, Tray ownership and native Dialog callbacks.

- [Process and LoadSO](process-loadso.md): child output/status, ownership and native export lifetime.

- [Thread/TLS and Atomic](thread-atomic.md): native callbacks, join/detach, TLS lifetime and atomic references.

- [Synchronization (P7)](synchronization.md): Mutex/RWLock/Semaphore/Condition, InitState и границы потоков.

- [Properties](properties.md): values, copied strings/names and defer ownership.

- [Ввод](input.md), [аудио](audio.md), [пиксели](pixels.md), [geometry](geometry.md).
- [Event variants](event-variants.md): `SdlEvent`, pattern matching и собственный текст.
- [Event queue](event-queue.md): raw Events 14/19, ожидание, batch peek/take, drop/user payloads.
- GPU: [native API](gpu-native-api.md), [native boost](gpu-native-boost.md),
  [результаты](gpu-native-validation.md), [raw tests](gpu-raw-tests.md).
- Checked GPU subset: [distinct handles](gpu-handles.md), [recording](gpu-recording.md), [buffers](gpu-transfer.md),
  [Result factories](gpu-factories.md),
  [textures](gpu-texture-transfer.md), [formats](gpu-formats.md), [BC/cube](gpu-texture-types.md),
  [volumes](gpu-volume.md), [ASTC](gpu-astc.md), [image operations](gpu-image.md),
  [swapchain settings](gpu-swapchain.md), [shaders](gpu-shaders.md),
  [samplers](gpu-samplers.md), [pipelines](gpu-pipelines.md).
- [Multi-device layer conflict](gpu-multidevice.md).

## Отдельные направления

- [GPU maintenance и shader DSL](gpu-roadmap.md).
- [Порты примеров](porting-matrix.md), [SDL companion libraries](companion-libraries-roadmap.md).

Документы удалённого engine API убраны; история остаётся в Git.
Актуальные числа покрытия находятся в api-coverage и generated census,
результаты последнего GPU этапа — в gpu-native-validation.

- [Hints/Init](init-hints.md): priorities, copied strings and subsystem defer scopes.

- [Error/log/time](diagnostics-time.md): literal messages, clocks and calendar conversions.

- [Video discovery](video-discovery.md): drivers, display modes and window query lifetimes.

- [Window state](window-state.md): creation, parent/child ownership and state changes.

- [Window fullscreen/surface/IO](window-io.md): borrowed surfaces, ICC and capability limits.

- [Software renderer/primitives](renderer-primitives.md): surface lifetime and CPU pixel checks.

- [Renderer state](renderer-state.md): viewport, clipping, scale and target output.

- [Renderer queries/presentation](renderer-presentation.md): names, logical modes and window coordinates.

- [Texture creation/state](texture-state.md): native access modes, properties, modulation and filtering.

- [Texture bytes/transfer](texture-transfer.md): byte modulation, blending, region updates and borrowed locks.

- [Renderer YUV/color/blend](renderer-yuv-blend.md): plane arrays, renderer color and custom composition.

- [Renderer operations](renderer-operations.md): creation, transformed drawing, readback, VSync and debug text.

- [Renderer final APIs](renderer-final-api.md): raw geometry, event conversion, fixed-text format and native interop limits.

- [Surface state](surface-state.md): properties, colorspace, RLE, color key, modulation, blending and clipping.

- [Surface and Pixels](surface-pixels.md): full native function inventory, palette/image lifetimes, blits, buffers and BMP IO.

- [Rect, Clipboard and hit tests](rect-clipboard-hittest.md): geometry refs, copied clipboard data, native callbacks and lexical script callback lifetime.

Result/Option boost API: [contracts and migration plan](result-option-plan.md).
Early-return syntax: [`sdl_try` macro and example](sdl-try.md).

- [Events callback contracts](event-callbacks.md): native addresses and synchronous script filtering.

- [Keyboard/mouse](keyboard-mouse.md): copied state/names, text input and cursor ownership.

- [Joystick/gamepad](joystick-gamepad.md): virtual tests, ownership and pinned backend limits.

- [Touch/Pen/Sensor/Haptic/HIDAPI](peripherals.md): raw functions, owned metadata, effects and report buffers.

- [IME/MIME event lists and user pointers](event-list-payloads.md): copied lists, move-only events, borrowed raw data.

- [Filesystem](filesystem.md): paths, copied directory lists, native callbacks and Result contracts.

- [IOStream](iostream.md): byte transfers, endian values, native callbacks and stream ownership.

- [Storage](storage.md): file/title/user/custom storage, native callbacks and ownership.
- [AsyncIO](asyncio.md): submission, completion, stable buffers and queue shutdown.
- [Audio devices](audio-devices.md): discovery, logical ownership, stream binding and dummy capture.
- [Audio stream controls](audio-stream-controls.md): format, gain, ratio, channel maps, pinned getter defect and deferred unlock.
- [Audio final API](audio-final-api.md): native callbacks, WAV IO, PCM mixing and conversion.

- [Camera](camera.md): 15 raw APIs, borrowed frames and dummy-only validation.

- [Web / Emscripten и HTML-примеры](web-roadmap.md): десять HTML-примеров на SDL Renderer и штатном dasOpenGL проверены в Edge/Firefox; текущий приоритет — P7.

- [SDL_net](sdl-net.md): optional SDL_net 3.2.0, 34 raw functions, TCP/UDP and async address resolution.

- [SDL 3.4.16 upgrade](sdl-3.4-upgrade.md): migration, validation and new API queue.

- [SDL_mixer](sdl-mixer.md): optional 3.2.4, 94 raw functions, offline/device mixing and resource scopes.

- [SDL_sound](sdl-sound.md): optional decoding, PCM ownership, errors and scopes.

- [SDL_shadercross](sdl-shadercross.md): pinned shader compiler, owned reflection, DXC deployment and offline assets.
