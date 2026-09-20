# dasSDL3

Привязки SDL3 к daScript / daslang. Публичный API следует объектам и операциям SDL;
mesh/material/scene/batching и планы удалены из библиотеки.

[Граница API](docs/gpu-api-boundary.md) · [Примеры](examples/README.md) · [GPU roadmap](docs/gpu-roadmap.md).

## План развития

Исследование от 19 сентября 2026 и план полной привязки:

- [Основной план и этапы покрытия](docs/full-binding-roadmap.md).
- [Аудит идиом daScript/dasBGFX/Rust и выбор генератора](docs/binding-design-review.md).
- [SDL GPU, shadercross и DSL](docs/gpu-roadmap.md).
- [Дополнительные библиотеки SDL](docs/companion-libraries-roadmap.md).
- [Примеры для портирования и проверки](docs/porting-matrix.md).

Эти документы описывают будущую работу; реализованное покрытие отдельно
зафиксировано в [api-coverage.md](docs/api-coverage.md).
Первый рабочий [реестр API Windows x64](docs/api-inventory.md) содержит
воспроизводимый снимок закреплённых заголовков и отдельные проверки учёта.

## Зависимости

- daScript: сабмодуль `third_party/daScript`, коммит
  `35bf260c0d8a79b94c64005bd3d2435adcf7e261` (0.6.4).
- SDL: `release-3.2.18`, загружается CMake FetchContent.
- CMake 3.24+, Git, компилятор C++17. Проверено на Windows x64,
  MSVC 19.38, Ninja и CMake 3.31.6.
- Только для повторной генерации: Python 3 и Clang. Проверено с Clang 16.0.5.
  Python-пакеты устанавливать не нужно.

При клонировании проекта используйте `git clone --recurse-submodules`.
В существующей копии: `git submodule update --init --recursive`.
У зафиксированного коммита daScript файл `.gitmodules` пуст: вложенных
сабмодулей сейчас нет.

## Сборка и запуск

Из **Developer PowerShell / x64 Native Tools Command Prompt for VS 2022**,
в корне проекта (Ninja должен быть доступен):

```powershell
cmake -S . -B build/ninja -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/ninja --target daslang_static dasSDL3_runner --parallel 6
./third_party/daScript/bin/daslang_static.exe examples/01_hello.das
./build/ninja/bin/dasSDL3_runner.exe examples/02_square.das
```

Альтернатива с генератором Visual Studio:

```powershell
cmake -S . -B build/vs -A x64
cmake --build build/vs --config Release --target daslang_static dasSDL3_runner --parallel 6
./build/vs/bin/Release/dasSDL3_runner.exe examples/02_square.das
```

В этой рабочей копии уже собран `build/ninja/bin/dasSDL3_runner.exe`.
При настройке использована существующая копия SDL из C++ примера:

```powershell
cmake -S . -B build/ninja -DFETCHCONTENT_SOURCE_DIR_SDL3=C:/src/dasSDL3/test-app/build/_deps/sdl3-src
```

Это локальная оптимизация загрузки; новая копия проекта самостоятельно
скачивает SDL, когда этот параметр не задан. Оригинальный `test-app` остаётся
отдельным C++ примером.

SDL и daScript линкуются статически. Копировать SDL3.dll не нужно.
Runner использует `daslib` из исходников daScript; каталог исходников нужен
при запуске. Путь к нему записывается в runner во время сборки. Для переноса
в другую папку пересоберите runner; упаковка отдельного дистрибутива пока
не реализована.

## Устройство привязки

Низкоуровневый модуль подключается через `require sdl3`. Пример использует
`require dassdl3/sdl3_boost`: проверяемые операции и блоки владения ресурсами
без `unsafe` и ручного получения адресов. Runner регистрирует модуль,
компилирует `.das` и вызывает `[export] def main(smoke : bool) : int`.
Возвращаемое значение становится кодом завершения процесса; ошибки
компиляции, неверная сигнатура main и исключения дают ненулевой код.

- `tools/bindings.json` — список экспортируемых функций, типов и констант.
- `tools/generate_bindings.py` — анализ заголовков настоящим Clang AST.
- `src/generated/` — сгенерированные регистрации и описание сигнатур.
- `src/sdl3_adapters.h` — ручные фабрики значений и работа с событиями.
- `src/sdl3_scopes.h` — восстановление аргументов блоков при исключениях.
- `src/module_sdl3.cpp` — модуль и подключение ручных адаптеров.
- `dassdl3/sdl3_boost.das` — идиоматичный слой daScript.
- `examples/02_square.das` — цикл событий и вся логика отрисовки на daScript.
- `examples/04_textures.das` — BMP, текстуры, масштабирование и обрезка изображения.
- `examples/03_input.das` — мышь, клавиатура, текстовый ввод и композиция IME.
- `docs/input.md` — API ввода, время жизни текста и ограничения проверок.
- `examples/08_audio.das` — WAV и воспроизведение через аудиопоток.
- `dassdl3/sdl3_audio_boost.das`, `docs/audio.md` — аудиообёртки и их контракты.
- `docs/api-coverage.md` — покрытие подсистем и оставшаяся работа.
- `docs/bgfx-idioms.md` — изученные идиомы dasBGFX с источниками.
- `docs/sdl3-boost.md` — принятые решения, ограничения и результаты проверок.
- `AGENTS.md` — указатель на эти знания для следующих сессий в проекте.

Подход изучен на `dasBGFX/src/dasBGFX.cpp`, `dasBGFX.main.cpp` и
`daScript/modules/dasClangBind/bind/bind_bgfx.das`: генерируемые регистрации
отделены от ручных дополнений; аргументы Uint8/Uint16 доступны как uint.
Здесь используется небольшой Python-генератор поверх JSON AST Clang,
а не сам `CppGenBind`: текущему dasClangBind нужен LLVM/Clang 22.1,
а установленный Clang 16 уже достаточен для разбора SDL. Это не полная
автоматическая привязка всего API SDL.

SDL_Window и SDL_Renderer доступны как непрозрачные указатели. В примере
время жизни задают блоки:

```das
with_sdl() {
    with_window("Hello", 800, 600, SDL_WINDOW_RESIZABLE) $(window) {
        window |> with_renderer() $(renderer) {
            renderer |> clear()
            renderer |> present()
        }
    }
}
```

Блоки освобождают renderer, затем окно, затем вызывают SDL_Quit. Очистка выполняется через
`defer` при обычном и раннем выходе. Ошибки SDL возвращаются как bool/null/zero,
без panic и перехвата. `with_*` возвращает false при неудачном создании и не
вызывает блок. Произвольный panic приложения по-прежнему обходит defer;
см. [контракт ошибок](docs/error-handling.md).
Ссылочные адаптеры C++ позволяют poll_event/push_event/fill_rect работать
без unsafe в скриптовом слое. Цвет задаётся uint4 RGBA в диапазоне 0..255.

Указатели внутри блоков заимствованы: их нельзя сохранять для последующего
использования или вручную уничтожать. Уникальное владение системой типов
не обеспечивается. Используйте один внешний with_sdl; вложенные независимые
SDL-сессии этим слоем не поддерживаются.

SDL_Event сохраняет настоящий размер и выравнивание C union. Наружу
экспортируется поле `event_type` (C-поле `type` — ключевое слово daScript).
`SDL_EventIsEscape` читает key только для SDL_EVENT_KEY_DOWN.
`SDL_MakeEvent` обнуляет union; `SDL_MakeKeyEvent` нужен для формирования
и проверки событий клавиатуры. `SDL_MakeFRect` создаёт прямоугольник.

Пустая строка имени renderer выбирает драйвер по умолчанию. Цветовые
компоненты передаются как uint в диапазоне 0..255. Строку SDL_GetError
следует использовать сразу: это сообщение из внутреннего буфера SDL.
Callbacks, varargs, остальные устройства и универсальные владеющие типы
пока не входят в эту версию. AOT и JIT не проверялись.

## Пример с текстурами

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/04_textures.das
./build/ninja/bin/dasSDL3_runner.exe examples/04_textures.das --smoke-test
```

Основа — public-domain пример SDL 3.2.18 `examples/renderer/06-textures`.
Используется собственный BMP из `examples/assets`; CMake копирует его рядом
с runner в `bin/assets`. Путь определяется через SDL_GetBasePath и не зависит
от текущей папки. Обычный запуск работает до Escape/закрытия окна;
smoke-test отрисовывает 60 кадров в скрытом окне.

`with_bmp(path) $(surface) { ... }` владеет поверхностью. `create_texture`
копирует её пиксели, не забирая владение. `renderer |> with_texture(path)
$(texture) { ... }` загружает BMP, сразу освобождает временную поверхность,
а текстуру уничтожает при выходе из блока, до renderer. `texture_size`
возвращает float2. Перегрузки `draw_texture` рисуют всю текстуру, масштабируют
её в dst или переносят фрагмент src в dst. Пример не требует unsafe.

Тест текстур проверяет пиксели, размеры, реальные вызовы освобождения ресурсов,
ранний выход и ошибку загрузки. Сборки с BUILD_TESTING=ON содержат
служебные SDLTest*; это не часть публичного API.

## Пример с вводом

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/03_input.das
./build/ninja/bin/dasSDL3_runner.exe examples/03_input.das --smoke-test
```

Мышь перемещает квадрат, левый клик меняет цвет, колесо меняет размер;
стрелки двигают квадрат. Введённый текст и незавершённая композиция IME
отображаются в заголовке окна. Backspace очищает весь текст, Escape завершает
пример. Для шрифтов внутри сцены потребуется отдельный этап.

`key_event`, `mouse_motion_event`, `mouse_button_event`, `mouse_wheel_event`
проверяют тип union и копируют данные в отдельную структуру. `text_input_event`
и `text_editing_event` копируют UTF-8 в память daScript. `with_text_input(window)
{ ... }` управляет сеансом ввода; `should_close(event, window)` учитывает окно.
Подробные контракты и покрытие — в `docs/input.md`.

## Пример с аудио

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/08_audio.das
ctest --test-dir build/ninja -R '^sdl3_audio' --output-on-failure
```

Пример один раз проигрывает собственный тихий сигнал 440 Гц из WAV.
Используется `require dassdl3/sdl3_audio_boost`, одна сессия
`with_sdl(SDL_INIT_AUDIO)`, блоки `with_wav` и `with_playback`.
Поток сначала на паузе: после queue_wav/flush_audio нужен resume_audio.
Скрипт не вызывается из фонового аудиопотока. Для преобразования без устройства
есть with_audio_stream(src, dst), для массивов uint8 — put_audio/read_audio.

CTest выбирает dummy-драйвер в окружении аудиотестов и не требует колонок.
Прямой запуск использует устройство по умолчанию. Подробности владения,
размеров буферов и ограничения определения конца воспроизведения — в docs/audio.md.

## Geometry

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/07_geometry.das
ctest --test-dir build/ninja -R '^sdl3_geometry' --output-on-failure
```

`require dassdl3/sdl3_geometry_boost` добавляет `vertex` и `draw_geometry`
для массивов вершин и индексов. Пример показывает цветной треугольник и
текстурированный прямоугольник; `--smoke-test` ограничивает его 60 кадрами.
[Контракты geometry](docs/geometry.md).

## Пиксели и render target

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/05_streaming_texture.das
./build/ninja/bin/dasSDL3_runner.exe examples/06_render_target.das
ctest --test-dir build/ninja -R '^sdl3_(pixels|streaming_example|target_example)$' --output-on-failure
```

`require dassdl3/sdl3_pixels_boost` добавляет RGBA8 upload из собственного массива,
scopes streaming/target texture и readback. Примеры не требуют unsafe; для
ограниченного запуска добавьте `--smoke-test`. [Контракты и проверки](docs/pixels.md).

## Повторная генерация

Установка LLVM SDK и проверка экспериментального dasClangBind описаны в
[docs/clangbind-setup.md](docs/clangbind-setup.md). Для MSVC Windows x64 теперь
по умолчанию используются сохранённые CppGenBind-привязки; обычная сборка не
требует LLVM/Python. [Выбор backend, генерация и consumer](docs/clangbind-production.md).
Ограниченная генерация CppGenBind и строгий AOT consumer проверены отдельно:
[результаты и команды](docs/clangbind-experiment.md).
Совместимость прежних 50 функций и текущих interpreter-примеров проверяется
отдельным [parity-проектом](docs/clangbind-parity.md). Теперь он также
[генерирует типы/константы и проверяет ресурсный AOT](docs/clangbind-types-aot.md).

Для прежнего backend (`-DDASSDL3_BINDING_BACKEND=python`) укажите папку,
в которой находится `SDL3/SDL.h`:

```powershell
python tools/generate_bindings.py --clang clang --sdl-include build/ninja/_deps/sdl3-src/include
python tools/generate_bindings.py --clang clang --sdl-include build/ninja/_deps/sdl3-src/include --check
```

При использовании локальной копии SDL укажите её `include` вместо пути выше.
Clang можно задать полным путём. При `-DDASSDL3_ENABLE_GENERATORS=ON`,
если CMake найдёт Python и Clang (либо
получит `-DDASSDL3_CLANG_EXECUTABLE=...`), будет доступна цель
`cmake --build build/ninja --target generate_bindings`.
После генерации пересоберите runner. Генератор не меняет ручные адаптеры.
Вывод генератора хранится в проекте, поэтому обычная сборка не требует Clang.

## Проверки

```powershell
ctest --test-dir build/ninja -R "^(sdl3_|bindings_up_to_date)" --output-on-failure
./build/ninja/bin/dasSDL3_runner.exe examples/02_square.das --smoke-test
```

Проверяются запуск daScript, версия SDL, чтение/изменение полей,
распознавание Escape и Quit, передача события через очередь SDL и
отрисовка 60 кадров в скрытом окне с освобождением ресурсов. При наличии
Clang дополнительно проверяется воспроизводимость генерации.
Отдельный тест boost проверяет очистку ресурсов при обычном/раннем выходе,
ошибке SDL, неудачном создании renderer и недопустимом цвете, а также сохранение
сообщения об ошибке. Состояние окна и renderer проверяется до SDL_Quit.

GPU buffer copy and asynchronous fence/readback example (no window):

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/23_gpu_copy_readback.das
```

Contract: [GPU transfers](docs/gpu-transfer.md).

Texture-region upload/copy/readback with mip/layer selection:

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/24_gpu_texture_transfers.das
```

[Texture transfer contract](docs/gpu-texture-transfer.md).

GPU format queries and R8 texture roundtrip:

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/25_gpu_formats.das
```

[Format contracts](docs/gpu-formats.md).

GPU API packages 26–29 add encoded BC transfers, cube faces, driver queries and
resource names. Contracts: [docs/gpu-texture-types.md](docs/gpu-texture-types.md).
From the repository root, for example:

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/26_gpu_bc_blocks.das
./build/ninja/bin/dasSDL3_runner.exe examples/27_gpu_cube_faces.das
```

Swapchain API examples 30–32 cover supported present modes/compositions,
configuration and frames-in-flight. [Contracts and tests](docs/gpu-swapchain.md).

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/31_gpu_present_modes.das
./build/ninja/bin/dasSDL3_runner.exe examples/32_gpu_frame_latency.das
```

GPU image examples 33–35 cover color-target texture ownership, generated mips
and scaled blits, with public readback. [Contracts and tests](docs/gpu-image.md).

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/34_gpu_mipmaps.das
./build/ninja/bin/dasSDL3_runner.exe examples/35_gpu_scaled_blit.das
```

GPU descriptors and independent resources: examples 37–43. Direct render passes,
vertex/index buffers and textures/uniforms: examples 44–46.

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/44_gpu_render_pass.das
./build/ninja/bin/dasSDL3_runner.exe examples/45_gpu_vertex_index_buffers.das
./build/ninja/bin/dasSDL3_runner.exe examples/46_gpu_texture_uniform_bindings.das
```

[Direct recording limits](docs/gpu-recording.md). GPU coverage is partial:
public copy/compute pass handles, swapchain acquisition and broad attachment/storage
contracts remain to be implemented. Examples 30–32 configure/query window properties;
they do not present frames after removal of the closed-frame renderer helper.

Native SDL GPU command/fence lifecycle: [example 47](examples/47_gpu_native_fences.das)
and [contract](docs/gpu-native-fences.md). Original SDL pointers/results, generated
signatures, borrowed fence-array adapter and explicit defer ownership.
