# Покрытие SDL3

> Current declaration coverage: all 92 active Windows GPU functions are generated.
> See [native GPU API](gpu-native-api.md). Runtime/AOT validation of the expanded
> surface is pending; earlier gaps below describe the previous checked subset.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

Baseline: SDL 3.2.18, Windows x64/MSVC. Generated: 145; adapted: 8;
pending: 1073 of 1226 functions. GPU: 92 generated / 0 adapted / 0 pending.
`adapted` means a documented partial adapter, not full raw API coverage.
See [API boundary](gpu-api-boundary.md) and the generated header census.

| Подсистема / сценарий | Raw API | Идиоматичный слой | Проверка / оставшаяся работа |
| --- | --- | --- | --- |
| Инициализация, ошибки, время | GetVersion, Init, Quit, WasInit, GetError, GetTicks, Delay | sdl_init, with_sdl; ошибки возвращаются как bool/null/zero | bindings, boost; прочие подсистемы Init не покрыты |
| Окно и renderer | Create/DestroyWindow, Create/DestroyRenderer, GetWindowID, GetWindowFromID, GetRenderer, SetWindowTitle | create/destroy, with_window, with_renderer, set_title | square, boost; управление окнами пока частичное |
| События | PollEvent, PushEvent, PumpEvents; SDL_Event.event_type | poll_event, push_event, should_close(event[, window]), input_window_id | input: фильтрация union и адресация окон; остальные варианты union впереди |
| Простая отрисовка | SetRenderDrawColor, RenderClear, RenderFillRect, RenderPresent | set_color, clear, fill_rect, present | square, boost; остальные примитивы впереди |
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
| GPU device/window | Creation, claim/release, driver/capability/configuration queries | Scoped lifetime helpers | Ownership tests; direct swapchain acquisition remains pending |
| GPU resource data | Bounded buffers/textures/volumes, upload/copy/readback, format queries | Array and ownership adapters | Transfer/format/volume/ASTC tests; no public copy-pass handles yet |
| GPU shaders/pipelines/samplers | Independent SDL objects and generated descriptors | Descriptor defaults and scopes | Creation/lifetime/layout tests; shader ABI remains trusted |
| GPU recording | Direct command buffer/render pass, bind/state/uniform/draw/submit | Checked handles and one command owner scope | gpu_recording; examples 44–46; offscreen single-color/sample-1 subset |

Removed: mesh/material/scene/batching/culling, fixed triangle/mesh renderer and
command/render plans, including their public native exports and boost modules.
Six previously adapted functions returned to pending: debug label/group push/pop,
copy-pass begin/end and WaitAndAcquireGPUSwapchainTexture. Internal uses do not
establish a public direct binding. Retired engine tests/examples are not counted
as coverage. Independent pixel/lifetime tests remain.
