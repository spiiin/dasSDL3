# Web / Emscripten: план платформы и HTML-примеров

Обновлено 22 сентября 2026. Web-профиль: wasm32 interpreter,
65 SDL raw-функций и десять HTML-примеров (Hello, square, input, textures, streaming,
render target, geometry, audio и два OpenGL-примера).
OpenGL использует штатный libDasModuleOpenGL из pinned daScript, SDL создаёт
ES 3.0 контекст. Отдельной GL-привязки в dasSDL3 нет. См. [OpenGL-примеры](../examples/web/opengl/README.md). Все восемь страниц проверены в Edge и Firefox: по 15 сценариев
с pixel/input/resize/cleanup, ошибками и ненулевым PCM на выходе Web Audio.
Физический звук и Safari не проверены; подробности — в web/README.md. См. [запуск и ограничения](../web/README.md). Это текущий приоритет по запросу пользователя; P7 временно
отложен. SDL остаётся 3.2.18, daScript — 35bf260c0d8a79b94c64005bd3d2435adcf7e261.
Рабочий entry point — web/build.cmd, результат — build/web/site. Ниже полный
план; выполненный bootstrap не означает завершение всех W0–W8.

## Целевой результат

Статическая галерея HTML-страниц: index, отдельная страница каждого примера,
canvas, Start/Stop/Restart, состояние загрузки и текст ошибки, ссылка на .das.
Первый комплект использует общий кэшируемый JS/WASM runtime и упакованные
скрипты/ресурсы. Каждая страница получает отдельный экземпляр приложения.
Сервер исполняет только раздачу файлов; C++ и daScript работают в браузере.
Это комплект HTML + JS + WASM + при необходимости .data, не один автономный HTML.
Локальный запуск — HTTP/localhost; публикация — статический HTTPS-хостинг.
Публикация не входит в текущий запрос на исследование.

## Найдено в репозитории

- [daScript web README](../third_party/daScript/web/README.md) и
  [web CMake](../third_party/daScript/web/CMakeLists.txt) уже содержат wasm
  interpreter, SIMD, exception flags, виртуальную FS и сборку стандартной
  библиотеки. Upstream playground добавляет GLFW/OpenGL/audio: весь его frontend
  и графический стек для dasSDL3 копировать не требуется.
- В cross-job [upstream workflow](../third_party/daScript/.github/workflows/wasm_build.yml)
  закреплён emsdk 5.0.3; рядом описана проблема 5.0.7. Совместимость 5.0.3 проверена
  первой сборкой и браузерными тестами dasSDL3.
  SDK 5.0.3 установлен в C:/src/emsdk для первой сборки; активация выполняется
  через emsdk_env.bat для текущего shell.
- Наш [CMake](../CMakeLists.txt) включает native daScript напрямую, без web flags.
  [src CMake](../src/CMakeLists.txt) ограничивает CppGenBind snapshots Windows x64.
  [runner](../src/runner.cpp) вызывает script main один раз, держит Context на
  стеке и использует пути исходного дерева хоста.
- [CppGenBind generator](../tools/clangbind_parity.das) фиксирует Windows target;
  [Python generator](../tools/generate_bindings.py) теперь принимает явные
  target/sysroot/spec/output. Bootstrap использует tools/bindings-web.json и
  web/generated; CppGenBind и полный inventory для wasm ещё впереди.
- [HID adapters](../src/sdl3_peripherals.h) требуют 16-bit wchar_t без platform
  guard. Это конкретный блокер компиляции общего module_sdl3.cpp на wasm;
  нужны переносимые преобразования либо явное ограничение профиля/экспортов.
- В pinned SDL Emscripten backend подключает SDL Renderer GLES2/WebGL, audio,
  joystick и camera. В src/gpu/SDL_gpu.c перечислены Metal/Vulkan/D3D12,
  но нет WebGPU backend. SDL_GPU-примеры не станут браузерными автоматически.
- Upstream eval_main_loop вызывает emscripten_set_main_loop_arg с
  simulate_infinite_loop=true и сохраняет состояние на всё время программы.
  Отмена loop не возвращает выполнение к обычному коду после него. Поэтому
  это не готовая замена desktop while внутри наших with_* с обещанием cleanup.

## Принятый стартовый профиль

Предлагается wasm32-emscripten, один поток, SDL Renderer/WebGL, daScript
interpreter внутри WASM. Нативные биндинги статически линкуются в runtime;
Clang/dasclang нужны только на машине сборки для генерации, не в браузере.
LLVM/JIT, memory64 и pthreads не требуются первому комплекту.

SIMD и конфигурацию исключений взять из закреплённого daScript web-порта и
проверить минимальные версии браузеров. Его runtime использует native Wasm EH;
это не повод добавлять panic/try/recover в SDL wrappers. Asyncify не включать
в базовый вариант: совместимость с этим EH-профилем и сохранение scoped cleanup
не доказаны. Непрерывный цикл с SDL_Delay заменить кадрами, возвращающими управление
браузеру. Нужный размер stack/heap, startup time и размер сжатого WASM измерить,
а не обещать заранее. Упаковка без compiler/runtime — отдельная AOT-оптимизация.

## Этапы и критерии готовности

| Этап | Работа | Критерий |
| --- | --- | --- |
| W0. Toolchain | Установить/активировать закреплённый emsdk, отдельный build/web; перенести необходимые daScript flags в наш build profile; собирать SDL 3.2.18 из исходников, не подменять системным SDL2/другой версией SDL3 | Минимальные daScript hello и native SDL canvas работают в браузере независимо друг от друга |
| W1. ABI и генерация | Добавить wasm32 profile, target/sysroot/defines в оба генератора и inventory; отдельные snapshots; разобрать wchar_t, pointer/size_t/long, alignment, union и native function-pointer casts | Биндинги компилируются; WASM-тест подтверждает размеры/поля/значения; Windows snapshots не изменены web-генерацией |
| W2. Host lifecycle | Отдельный web runner на SDL main callbacks, удержание Program/Context/ModuleGroup; экспортированные script init/frame/event/quit вызываются на одном потоке | Кадры не блокируют UI; Stop, ошибка init/frame, повторный Start завершают сессию корректно |
| W3. Runtime и файлы | Монтировать daslib, dassdl3, .das и assets в MEMFS по стабильным путям; убрать зависимость от C:/src; JS loader и общий shell | Require, макросы sdl_try/sdl_scope и BMP/WAV работают с HTTP; missing asset даёт видимую ошибку |
| W4. Первые HTML-примеры | Галерея и страницы 01–07 из списка ниже; общий runtime без редактора/JIT/worker pool | Изображение, ввод, resize и cleanup проверены в реальном браузере |
| W5. Audio и IO | Страница audio с пользовательским запуском; память/файлы из пакета, отдельный browser upload/download; позже IDBFS persistence | Аудио начинает работать после жеста; offline PCM проверен байтами; IO не притворяется доступом к диску хоста |
| W6. Browser validation | Автоматизация Chromium и Firefox; WebKit/Safari отдельная цель, ручная проверка Safari при доступности; HTTP tests и desktop regression | Нет console errors, canvas не пуст, Stop/Restart устойчивы, есть проверки входных событий и вывода |
| W7. Расширение | Gamepad, text input/IME, fullscreen/pointer lock, clipboard и camera с capability/permission checks | Неподдерживаемая возможность или отказ дают понятный результат; hardware-only проверки отдельно |
| W8. AOT и поставка | Target-correct AOT после interpreter baseline, оптимизация состава/размера, воспроизводимый архив/CI artifact с manifest | AOT/interpreter parity на wasm, нет native-layout offsets, комплект запускается на чистом статическом сервере |

В W1 сначала можно выделить Renderer/events/Result subset для smoke, затем
подключать остальные выбранные raw-функции по профилю. В inventory различать:
нет декларации на target / API с native unsupported stub / рабочая возможность /
нужен пользовательский жест или оборудование. Сам факт линковки не даёт
web runtime coverage. Desktop-тесты сохраняются отдельно от browser tests.

## Жизненный цикл и владение

SDL_AppInit / SDL_AppIterate / SDL_AppEvent / SDL_AppQuit — исходная концепция SDL,
а не новая модель сцены. Нужен узкий C++ host bridge к экспортированным функциям
скрипта. Окончательные script-сигнатуры определить прототипом W2, включая
Result успеха/ошибки и нормальный запрос остановки. Никаких script blocks,
захваченных с уже завершённого стека, и вызовов одного Context из разных потоков.

Ресурсы между кадрами принадлежат состоянию конкретного примера и освобождаются
в quit в обратном порядке. Частичный init также должен корректно завершаться;
ошибка кадра копируется до cleanup, quit вызывается ровно один раз. with_*/defer
сохраняются для ресурсов в пределах синхронного вызова. Нельзя создать окно в
with_window внутри init, выйти из блока и ожидать, что оно доживёт до frame.
Нельзя обещать выполнение finally после закрытия вкладки/аварии/panic.

Не добавлять универсальный resource manager, scene или render plan. Если позже
понадобится линейный scoped-синтаксис на всю браузерную сессию, это отдельное
исследование continuation/Asyncify и cleanup, не скрытая смена семантики with_*.
Для Restart сначала остановить кадры и выполнить quit; при проблемах полной
повторной инициализации использовать новый WASM instance/перезагрузку страницы.

## Первый набор страниц

Пути предлагаются под examples/web/, существующая desktop-нумерация сохраняется.

| Страница | Основа | Что демонстрирует |
| --- | --- | --- |
| 01_hello.html | 01_hello.das, небольшой SDL init probe | WASM, вывод ошибок/лога, версия SDL; текущий hello имеет main без аргументов, runner contract нужно согласовать |
| 02_square.html | 02_square.das | Canvas, анимация по кадрам, Stop/Restart, resize/DPI |
| 03_input.html | 03_input.das и event variants | Клавиатура/мышь, focus, координаты canvas |
| 04_textures.html | 04_textures.das | BMP из пакета, crop/scale, обработка missing file |
| 05_streaming.html | 05_streaming_texture.das | Обновление texture bytes |
| 06_target.html | 06_render_target.das | Render-to-texture при поддержке backend, явное сообщение при отсутствии |
| 07_geometry.html | 07_geometry.das | SDL_RenderGeometry, indexed vertices и цвета |
| 08_audio.html | 08_audio.das и 79_audio_conversion.das | Пользовательский запуск воспроизведения и проверка PCM |

К каждой странице: исходник .das, краткое управление, прогресс загрузки,
видимая ошибка компиляции/SDL, кнопки запуска и остановки. Скриптовая логика
остаётся на daScript, JavaScript обслуживает загрузку, canvas и браузерные жесты.
Повторно используемые функции отрисовки можно вынести из desktop/web примеров,
не превращая их в публичный слой библиотеки. Список assets формируется manifest,
а не копированием всего дерева build/ или всех GPU shader assets.

## Ограничения и отложенные возможности

- GPU: SDL_Renderer может использовать WebGL; SDL_GPU в 3.2.18 не имеет WebGPU
  backend. Не заменять SDL_GPU собственным WebGPU engine. Обновление SDL или
  отдельная WebGPU-привязка требуют отдельного решения и исследования.
- Audio/fullscreen/pointer lock: учитывать user gesture; Start разрешать после
  загрузки runtime, чтобы нужный вызов не терял жест из-за асинхронной загрузки.
- Camera/clipboard: отдельные разрешения и требования браузерного контекста;
  не включать реальные устройства в автоматический smoke.
- Native filesystem/process/shared-library API не равны браузерным аналогам.
  MEMFS содержит пакет/загруженные файлы; persistence через IDBFS требует sync.
- Pthreads требуют отдельного артефакта, SharedArrayBuffer и COOP/COEP; не делать
  их обязательными для простого статического хостинга первой галереи.
- Host-generated AOT: Windows x64 ABI не равен wasm32. Upstream
  [build_wasm_host.sh](../third_party/daScript/web/build_wasm_host.sh) отдельно
  предупреждает о baked offsets и несовпадении stdlib/exception/pointer ABI.
  Нельзя просто скомпилировать нынешние Windows AOT snapshots через em++.
- Изолировать generated daScript config и outputs: web и native configure
  могут затрагивать общие файлы upstream. Отдельный build dir сам по себе
  не доказывает отсутствие коллизий; проверить до параллельных CI jobs.

## Проверки

Compile/load macro + Result/Option + distinct uint64 handle + out/ref/arrays;
SDL structs/union layouts на wasm; native callbacks и function-pointer signature
checks. Для первых страниц — кадр с pixel oracle/устойчивой областью screenshot,
несколько requestAnimationFrame, ввод, resize/DPI, missing asset, init/frame Err,
Stop/Restart и counters освобождения. Сначала Chromium/Firefox, затем отдельная
проверка WebKit/Safari; поддержка browser engine не выводится из native тестов.
Node подходит для CPU/ABI smoke, но не заменяет настоящий canvas/WebGL/audio.

## Источники

- [SDL Emscripten guide](https://wiki.libsdl.org/SDL3/README-emscripten)
- [Emscripten browser main loop](https://emscripten.org/docs/porting/emscripten-runtime-environment.html)
- [Asyncify/JSPI](https://emscripten.org/docs/porting/asyncify.html)
- [Pthreads и требования deployment](https://emscripten.org/docs/porting/pthreads.html)
- Pinned SDL: docs/README-emscripten.md, CMakeLists.txt (ветка EMSCRIPTEN),
  src/gpu/SDL_gpu.c; pinned daScript: web/CMakeLists.txt,
  src/builtin/module_builtin_runtime.cpp (eval_main_loop).
