# Покрытие SDL3

Целевая версия: SDL 3.2.18. Это список реализованных сценариев, а не заявление
о полном покрытии подсистем. `tools/bindings.json` задаёт точный перечень
экспортов; `src/generated/api.json` содержит полученные из Clang сигнатуры.
Сейчас генерируются 50 функций SDL. Ручные адаптеры перечислены отдельно.

| Подсистема / сценарий | Raw API | Идиоматичный слой | Проверка / оставшаяся работа |
| --- | --- | --- | --- |
| Инициализация, ошибки, время | GetVersion, Init, Quit, WasInit, GetError, GetTicks, Delay | sdl_init, with_sdl; ошибки операций превращаются в panic | bindings, boost; прочие подсистемы Init не покрыты |
| Окно и renderer | Create/DestroyWindow, Create/DestroyRenderer, GetWindowID, GetWindowFromID, GetRenderer, SetWindowTitle | create/destroy, with_window, with_renderer, set_title | square, boost; управление окнами пока частичное |
| События | PollEvent, PushEvent, PumpEvents; SDL_Event.event_type | poll_event, push_event, should_close(event[, window]), input_window_id | input: фильтрация union и адресация окон; остальные варианты union впереди |
| Простая отрисовка | SetRenderDrawColor, RenderClear, RenderFillRect, RenderPresent | set_color, clear, fill_rect, present | square, boost; остальные примитивы впереди |
| BMP / поверхности | LoadBMP, DestroySurface | load_bmp, destroy_surface, with_bmp | textures: нормальный/ранний выход, panic, ошибка создания текстуры; пиксельные буферы поверхности не раскрыты |
| Статические текстуры | CreateTextureFromSurface, DestroyTexture, GetTextureSize, RenderTexture | create_texture, load_texture, destroy_texture, texture_size, with_texture, draw_texture (3 перегрузки) | textures: размеры, чтение пикселей, освобождение до renderer, отсутствующий файл |
| Путь к ресурсам примера | GetBasePath | пример строит путь к assets рядом с exe | запуск не зависит от текущей папки; универсального файлового слоя ещё нет |
| Streaming / render-target текстуры | Нет | Нет | Lock/Unlock, UpdateTexture, форматы и буферы требуют следующего этапа |
| Аудио | LoadWAV/free, Create/DestroyAudioStream, Put/GetAudioStreamData, GetAvailable/Queued/Format/Device, Flush/Clear, Pause/Resume/DevicePaused | with_wav, with_audio_stream, with_playback; queue_wav, put/read_audio и управление очередью | audio: PCM-копии, ресэмплинг, размеры, очистка и dummy; физическое устройство/микрофон/callbacks впереди |
| Клавиатура и мышь | GetKeyboardState, GetMouseState; Keyboard/Motion/Button/Wheel структуры | key_event, key_scancode, key_down, mouse_*_event, wheel_delta, mouse_state | input: Down/Up, repeat/mod, координаты, клики, FLIPPED, границы индекса; относительный режим/захват впереди |
| Текстовый ввод | StartTextInput, StopTextInput, TextInputActive, ClearComposition | text_input_event, text_editing_event, with_text_input | input: копии UTF-8 и вложенные сеансы при panic; реальная IME, кандидаты, область ввода ещё не проверены/не реализованы |
| Геймпады | Нет | Нет | Отдельный этап |
| Callbacks, потоки | Нет | Нет | Нужен контракт времени жизни замыканий и потока вызова |
| GPU, файловый IO, остальные подсистемы | Нет | Нет | Отдельные этапы |

Ручные адаптеры: PollEventRef, PushEventRef, RenderFillRectRef,
GetTextureSizeRef, RenderTextureToRect, RenderTextureRects. Они используют
адреса только во время синхронного вызова. Также есть фабрики MakeEvent,
MakeKeyEvent, MakeFRect и проверки EventIsQuit/EventIsEscape (префикс SDL_).
Адаптеры ввода описаны в `input.md`: ReadKey/Mouse/Text, KeyScancode,
MouseWheelFlipped, InputWindowID, IsScancodeDown, GetMouseStateRef.
Служебные SDL_InvokeScope и SDL_InvokeWindow/Renderer/Surface/Texture восстанавливают аргументы
блоков интерпретатора при panic; это синхронный механизм для with_* нашего
boost-слоя, а не привязка асинхронных callbacks SDL.

Тестовые SDLTest* экспортируются только при BUILD_TESTING=ON и не являются
публичной обвязкой SDL. Cleanup callbacks на SDL properties фиксируют
уничтожение поверхности/текстуры до очистки renderer; stale pointers не читаются.
Проверка пикселей использует RenderReadPixels/ReadSurfacePixel только внутри
тестового C++ адаптера, не добавляя эти API в публичную привязку.

При расширении обновлять эту таблицу, спецификацию генератора, boost-слой и
проверку соответствующего сценария. Пока не проверены AOT/JIT, другие ОС,
другие версии SDL, уникальное владение и защита от висячих указателей.

Аудио: `docs/audio.md`. OpenAudioDeviceStream пока доступен через ручной
адаптер без callback. SDL_Wav — собственный непрозрачный тип владения,
а не структура SDL. Формат SDL_AudioSpec читается через audio_format.
