# Покрытие SDL3

Baseline: SDL 3.4.16, Windows x64/MSVC. Generated: 998; adapted: 14;
pending: 251 of 1263 functions. GPU: 95 generated / 0 adapted / 0 pending.
See [upgrade and new API queue](sdl-3.4-upgrade.md).
`adapted` means a documented partial adapter, not full raw API coverage.
See [API boundary](gpu-api-boundary.md) and the generated header census.

| Подсистема / сценарий | Raw API | Идиоматичный слой | Проверка / оставшаяся работа |
| --- | --- | --- | --- |
| Thread / Atomic / Process / LoadSO | 12/12 + 16/16 + 9/9 + 3/3 generated | Native callbacks, refs, owners, copied process output | [Threads](thread-atomic.md), [Processes](process-loadso.md) |
| System / Power / Locale / Dialog / Tray | 13/13 + 1/1 + 1/1 + 4/4 + 23/23 generated | Native callbacks; copied locales; tray scopes | [Platform contracts and validation limits](platform-services.md) |
| Synchronization (P7) | 28/28 generated | Result owners, deferred locks, bool try/timeouts, InitState refs | [Contracts and thread limits](synchronization.md) |
| Audio final API | 9 additional generated; Audio raw 58/58 | Native callback addresses, WAV IO and PCM arrays | [Contracts](audio-final-api.md); known map getter/postmix exceptions |
| Audio stream controls | 12 additional generated | Format refs, map setters, gain/ratio and deferred lock | [Contracts](audio-stream-controls.md); PCM and cross-thread unlock tests |
| Camera | 15/15 generated | Copied discovery, Result/Option frames and defer scopes | [Contracts and hardware limits](camera.md) |
| Audio devices | 21 additional generated; Audio total 58/58 | Copied discovery, logical scopes, binding and dummy recording | [Contracts](audio-devices.md); stream/callback/conversion connected; physical-device checks remain |
| AsyncIO | 11/11 generated | Submission Result, completion Option, copied file bytes and queue defer | [Lifetime contracts](asyncio.md); synthetic cancellation only |
| Storage | 17/17 generated | Native interfaces, copied lists/bytes, bounds and defer scopes | [Contracts](storage.md); positive user/cloud storage remains unverified |
| IOStream | 46 generated / 1 fixed-text adapted / 1 va_list pending | Bounded byte transfers, counts/status, scalar refs and defer scopes | [Contracts and pinned bulk IO limits](iostream.md) |
| Filesystem | 11/11 generated | Copied paths/lists and Result helpers | [Contracts](filesystem.md) |
| Rect/Clipboard/hit-test | 18 + 11 + 1 generated | Ref/copy and lexical callback scopes | [Contracts](rect-clipboard-hittest.md); GL/EGL moved to P8 |
| Surface/Pixels | Surface 65/65, Pixels 11/11 raw | Refs, packed arrays, copied pointer list, defer scopes | Native function execution, pixels and ownership; [contract](surface-pixels.md) |
| Surface state | 16 generated | Scalar/rect refs | State, key/modulation and clip pixels; [contract](surface-state.md) |
| Renderer final APIs | 5 generated, fixed-text variadic adapter | Geometry arrays, event refs | [Interop limitations](renderer-final-api.md) |
| Renderer operations | 10 новых generated; ReadPixels больше не adapted | Ref draw/readback/VSync, creation scopes | Spatial pixels, clipped readback, lifetime; [контракт](renderer-operations.md) |
| Renderer YUV/color/blend | 10 новых generated, blend enums | Bounded whole-texture plane arrays, scalar refs | Odd/padded YUV pixels, color and blend; [контракт](renderer-yuv-blend.md) |
| Texture bytes/transfer | 10 новых generated; lock/unlock больше не adapted | uint refs, checked RGBA32 update, borrowed surface lock | Padded region pixels, blending, unlock; [контракт](texture-transfer.md) |
| Texture creation/state | 10 новых generated; CreateTexture больше не adapted | Format/access + properties scopes, float/enum refs | Creation, modulation pixels; [контракт](texture-state.md) |
| Renderer queries/presentation | 10 новых generated, 5 enum values | Copied names, enum/scalar/rect refs | Modes, CPU pixels, coordinate conversion; [контракт](renderer-presentation.md) |
| Renderer state | 10 новых generated | Rect/scalar ref adapters, NULL reset | Full-image pixels, target-local state; [контракт](renderer-state.md) |
| Software renderer/primitives | 10 новых generated | Surface lifetime scope, array/ref adapters | CPU pixels каждого примитива; [контракт](renderer-primitives.md) |
| Window fullscreen/surface/IO | 25 Video + 3 Surface новых generated | Mode/ICC/rect/ref adapters; standalone surface defer | CPU pixels, surface lifecycle, native results; [ограничения](window-io.md) |
| Window state | 27 новых generated; Video суммарно 94/114 | Property/popup defer scopes, ref/out | Constraints, parent/child ownership, early return; [контракт](window-state.md) |
| Video discovery | 31 новых generated | Copied display/mode/window lists, strings, ref/out | Real display queries, hidden window, invalid IDs; [контракт](video-discovery.md) |
| Error/Log/Timer/Time | 22 новых generated и 10 fixed-text adapted | Error copy, ref/out time adapters | Thread errors, log filtering, UTC/FILETIME, timer removal; [контракт](diagnostics-time.md) |
| Hints/Init | 6/8 Hints и 9/10 Init generated; 3 callbacks pending | Copied getters, metadata clear, with_sdl_subsystems | Приоритеты, UTF-8, nested/early return, partial init rollback; [контракт](init-hints.md) |
| Properties | 19 из 21 generated; enumeration adapted; retained cleanup pending | with_properties, with_properties_lock, copied strings/names | Типы/defaults/UTF-8, early return, lock и native cleanup counters; [контракт](properties.md) |
| Базовая сессия SDL | GetVersion, Init, Quit, WasInit | sdl_init, with_sdl; boost возвращает Result, raw сохраняет SDL-контракт | bindings, boost; расширения Init и времени описаны выше |
| Окно и renderer | Create/DestroyWindow, Create/DestroyRenderer, GetWindowID, GetWindowFromID, GetRenderer, SetWindowTitle | create/destroy, with_window, with_renderer, set_title | square, boost; управление окнами пока частичное |
| Touch/Pen/Sensor/Haptic/HIDAPI | 4 + 1 + 14 + 31 + 23 generated | Owned device lists, HID UTF-8 metadata, arrays, effect refs and scopes; 13 event tags | [Contracts and hardware limits](peripherals.md) |
| Joystick/Gamepad | 58/58 + 73/73 generated | Copied lists/mappings, native GUID/binding readers, Result ownership scopes | [Contracts and pinned virtual-driver defects](joystick-gamepad.md); all 21 event tags projected; native callback fields remain |
| Keyboard/Mouse | 24/24 + 24/24 generated | Copied snapshots/names, Result cursor scopes, text input refs | [Contracts](keyboard-mouse.md); retained scancode names, layout/backend limits |
| События | 20/20 generated: очередь, ожидание, диапазоны, регистрация типов, окно события | Result/Option waits; owned peek/take; 64 SdlEvent вариантов, copied drop strings и user metadata | [Очередь](event-queue.md); [Callback contracts](event-callbacks.md); остальные payloads pending |

SDL 3.4 Render/Surface: **20 новых raw функций**, всего Surface 65/65,
Render 101 raw + 1 fixed-text adapter. [Контракты и проверки](render-surface-34.md).

Следующая очередь и критерии готовности: [план](full-binding-roadmap.md).
Pending не означает обязательную реализацию всех libc/SIMD/va_list функций:
169 записей Stdinc ещё требуют явной классификации, а не молчаливого исключения.

SDL 3.4 оставшиеся 13 дополнений подключены; [контракты и границы](sdl-34-remaining.md).

[Script accessibility audit](script-accessibility.md): 552 hint/property strings,
copied stream maps, device event payloads and four SDL 3.4 record fields.
