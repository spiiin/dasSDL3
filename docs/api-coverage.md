# Покрытие SDL3

Baseline: SDL 3.2.18, Windows x64/MSVC. Generated: 852; adapted: 14;
pending: 360 of 1226 functions. GPU: 92 generated / 0 adapted / 0 pending.
`adapted` means a documented partial adapter, not full raw API coverage.
See [API boundary](gpu-api-boundary.md) and the generated header census.

| Подсистема / сценарий | Raw API | Идиоматичный слой | Проверка / оставшаяся работа |
| --- | --- | --- | --- |
| Audio final API | 9 additional generated; Audio raw 56/56 | Native callback addresses, WAV IO and PCM arrays | [Contracts](audio-final-api.md); known map getter/postmix exceptions |
| Audio stream controls | 12 additional generated | Format refs, map setters, gain/ratio and deferred lock | [Contracts](audio-stream-controls.md); PCM and cross-thread unlock tests |
| Camera | 15/15 generated | Copied discovery, Result/Option frames and defer scopes | [Contracts and hardware limits](camera.md) |
| Audio devices | 21 additional generated; Audio total 56/56 | Copied discovery, logical scopes, binding and dummy recording | [Contracts](audio-devices.md); stream/callback/conversion connected; physical-device checks remain |
| AsyncIO | 11/11 generated | Submission Result, completion Option, copied file bytes and queue defer | [Lifetime contracts](asyncio.md); synthetic cancellation only |
| Storage | 17/17 generated | Native interfaces, copied lists/bytes, bounds and defer scopes | [Contracts](storage.md); positive user/cloud storage remains unverified |
| IOStream | 46 generated / 1 fixed-text adapted / 1 va_list pending | Bounded byte transfers, counts/status, scalar refs and defer scopes | [Contracts and pinned bulk IO limits](iostream.md) |
| Filesystem | 11/11 generated | Copied paths/lists and Result helpers | [Contracts](filesystem.md) |
| Rect/Clipboard/hit-test | 18 + 11 + 1 generated | Ref/copy and lexical callback scopes | [Contracts](rect-clipboard-hittest.md); GL/EGL moved to P8 |
| Surface/Pixels | Surface 58/58, Pixels 11/11 raw | Refs, packed arrays, copied pointer list, defer scopes | Native function execution, pixels and ownership; [contract](surface-pixels.md) |
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
| Window state | 27 новых generated; Video суммарно 89/109 | Property/popup defer scopes, ref/out | Constraints, parent/child ownership, early return; [контракт](window-state.md) |
| Video discovery | 31 новых generated | Copied display/mode/window lists, strings, ref/out | Real display queries, hidden window, invalid IDs; [контракт](video-discovery.md) |
| Error/Log/Timer/Time | 22 новых generated и 10 fixed-text adapted | Error copy, ref/out time adapters | Thread errors, log filtering, UTC/FILETIME, timer removal; [контракт](diagnostics-time.md) |
| Hints/Init | 6/8 Hints и 9/10 Init generated; 3 callbacks pending | Copied getters, metadata clear, with_sdl_subsystems | Приоритеты, UTF-8, nested/early return, partial init rollback; [контракт](init-hints.md) |
| Properties | 19 из 21 generated; enumeration adapted; retained cleanup pending | with_properties, with_properties_lock, copied strings/names | Типы/defaults/UTF-8, early return, lock и native cleanup counters; [контракт](properties.md) |
| Базовая сессия SDL | GetVersion, Init, Quit, WasInit | sdl_init, with_sdl; boost возвращает Result, raw сохраняет SDL-контракт | bindings, boost; расширения Init и времени описаны выше |
| Окно и renderer | Create/DestroyWindow, Create/DestroyRenderer, GetWindowID, GetWindowFromID, GetRenderer, SetWindowTitle | create/destroy, with_window, with_renderer, set_title | square, boost; управление окнами пока частичное |
| Touch/Pen/Sensor/Haptic/HIDAPI | 4 + 0 + 14 + 31 + 22 generated | Owned device lists, HID UTF-8 metadata, arrays, effect refs and scopes; 13 event tags | [Contracts and hardware limits](peripherals.md) |
| Joystick/Gamepad | 58/58 + 73/73 generated | Copied lists/mappings, native GUID/binding readers, Result ownership scopes | [Contracts and pinned virtual-driver defects](joystick-gamepad.md); all 21 event tags projected; native callback fields remain |
| Keyboard/Mouse | 24/24 + 22/22 generated | Copied snapshots/names, Result cursor scopes, text input refs | [Contracts](keyboard-mouse.md); retained scancode names, layout/backend limits |
| События | 19/19 generated: очередь, ожидание, диапазоны, регистрация типов, окно события | Result/Option waits; owned peek/take; 53 SdlEvent вариантов, copied drop strings и user metadata | [Очередь](event-queue.md); [Callback contracts](event-callbacks.md); остальные payloads pending |
| Простая отрисовка | SetRenderDrawColor, RenderClear, RenderFillRect, RenderPresent | set_color, clear, fill_rect, present | square, boost; остальные Render-функции перечислены выше |
| BMP / поверхности | LoadBMP, DestroySurface | load_bmp, destroy_surface, with_bmp | textures: нормальный/ранний выход, ошибка создания текстуры; пиксельные буферы поверхности не раскрыты |
| Статические текстуры | CreateTextureFromSurface, DestroyTexture, GetTextureSize, RenderTexture | create_texture, load_texture, destroy_texture, texture_size, with_texture, draw_texture (3 перегрузки) | textures: размеры, чтение пикселей, освобождение до renderer, отсутствующий файл |
| Путь к ресурсам примера | GetBasePath | пример строит путь к assets рядом с exe | запуск не зависит от текущей папки; универсального файлового слоя ещё нет |
| Geometry | RenderGeometry; FPoint, FColor и Vertex с вложенными полями | vertex, draw_geometry(vertices[, indices][, texture]) | geometry: точные пиксели, indexed/sequential parity, пустые массивы, границы, NaN/Infinity, время жизни в interpreter/AOT |
| Streaming / render-target текстуры | Get/SetRenderTarget; создание/lock/readback через частичные адаптеры | with_streaming_texture, upload_rgba8, with_target_texture, with_render_target, with_read_pixels, surface_size, copy_surface_rgba8 | pixels: pitch, границы, RGBA roundtrip, cleanup и nested target в interpreter/AOT; region updates и прочие форматы впереди |
| Аудио | LoadWAV/free, Create/DestroyAudioStream, Put/GetAudioStreamData, GetAvailable/Queued/Format/Device, Flush/Clear, Pause/Resume/DevicePaused | with_wav, with_audio_stream, with_playback; queue_wav, put/read_audio и управление очередью | audio: PCM-копии, ресэмплинг, размеры, очистка и dummy; физическое устройство/микрофон/callbacks впереди |
| Клавиатура и мышь | GetKeyboardState, GetMouseState; Keyboard/Motion/Button/Wheel структуры | key_event, key_scancode, key_down, mouse_*_event, wheel_delta, mouse_state | input: Down/Up, repeat/mod, координаты, клики, FLIPPED, границы индекса; относительный режим/захват впереди |
| Текстовый ввод | StartTextInput, StopTextInput, TextInputActive, ClearComposition | text_input_event, text_editing_event, with_text_input | input: копии UTF-8 и вложенные сеансы при раннем выходе; реальная IME, кандидаты, область ввода ещё не проверены/не реализованы |
| Геймпады | Нет | Нет | Отдельный этап |
| Callbacks, потоки | Нет | Нет | Нужен контракт времени жизни замыканий и потока вызова |
| Файловый IO, остальные подсистемы | Нет | Нет | Отдельные этапы |
| GPU native API | Все 92 функции SDL_gpu.h активного Windows профиля | Массивы/ref, creation data, native defer scopes | Raw: 92 Vulkan / 90 D3D12; debug-group исключения явные |
| GPU attachments/compute/transfers | Render/copy/compute, swapchain/fences, storage/samplers/uniforms | Public примеры 48–50 без unsafe | MRT/MSAA/depth/stencil, offsets/cycling, CPU pixel/byte references |
| GPU checked subset | Типизированные distinct IDs поверх uint64, ограниченные formats/layouts | Примеры 23–46 | Ограничения конкретного checked helper не ограничивают generated raw API |

Подробности: [native API](gpu-native-api.md), [scopes](gpu-native-boost.md),
[проверки](gpu-native-validation.md). Положительный ASTC roundtrip и другие
платформы не подтверждены. Генерация не доказывает все сочетания параметров.

Удалённые engine helpers и внутренние вызовы SDL не считаются покрытием.
Текущий раздел: [P3 Events/input](full-binding-roadmap.md); следующий пакет — оставшиеся Keyboard/Mouse.
