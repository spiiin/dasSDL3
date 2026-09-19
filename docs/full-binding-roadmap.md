# План полной привязки SDL3 к daScript

Исследование: 19 сентября 2026. Это план, а не перечень реализованных функций.
Текущее состояние — в `api-coverage.md`; идиомы и выбор генератора — в
`binding-design-review.md`; GPU — в `gpu-roadmap.md`; дополнения — в
`companion-libraries-roadmap.md`; примеры и проверки — в `porting-matrix.md`.

Ход реализации: первый снимок API для Windows x64, policy и проверки уже
добавлены; см. `api-inventory.md`. Межплатформенный census и эксперимент
dasClangBind ещё впереди; P0 пока завершён не полностью.

## Решение

Переходить к систематическому покрытию уже можно. Продолжать добавлять только
функции, понадобившиеся очередному примеру, недостаточно: так останутся
неучтёнными типы, макросы, callbacks и платформенные варианты.

Следующий этап: реестр всего API выбранного релиза и ограниченный эксперимент
с **dasClangBind / CppGenBind**. После его проверки — массовая генерация raw API
по подсистемам, поверх неё проверяемые native adapters и идиоматичный boost.
Примеры остаются проверкой контрактов, а не единственным источником backlog.
Существующий Python-генератор уже использует Clang AST; речь идёт о выборе
инфраструктуры генерации, а не о переходе от текстового парсинга к Clang.

## База и значение слова «полная»

Сейчас закреплены SDL **3.2.18** и daScript
**35bf260c0d8a79b94c64005bd3d2435adcf7e261**. Генерируются 50 SDL-функций;
плюс существуют ручные адаптеры. Работают сценарии окна, renderer, BMP,
клавиатуры/мыши/текста, WAV и audio streams. Это ещё не полные подсистемы.

[Категории](https://wiki.libsdl.org/SDL3/APIByCategory) задают структуру работ,
[общий индекс](https://wiki.libsdl.org/SDL3/CategoryAPI) помогает искать пропуски.
Однако wiki обновляется: встречаются API новее 3.2.18. Источник истины для
сигнатур, доступности и численного покрытия — заголовки закреплённого SDL,
обработанные с параметрами целевой платформы. SDL_main и платформенные headers
проверять отдельно от SDL.h. Примеры с сайта также проверять по версии.

До расширения выбрать baseline: сохранить 3.2.18 для первой инвентаризации,
затем отдельным изменением проверить обновление на конкретный стабильный релиз,
совместимый с выбранными SDL_image/ttf/mixer. Не переключаться на main.
Новые версии добавлять через diff реестров, с повторной проверкой ABI и тестов.

Предлагаемый `tools/api-policy.json` должен дополнять автоматически полученный
реестр, а не дублировать вручную все C-сигнатуры. Для каждого символа хранить:

- категорию, заголовок, вид (function/type/enum/constant/macro/callback), версию и guards;
- raw-статус: generated / adapted / pending / excluded с причиной;
- boost-статус и публичное имя; ссылка на тест и документацию;
- владение, allocator/deleter, parent, nullable, transfer/borrow/copy;
- для буферов: count/bytes/stride, направление, срок жизни и возможность удержания;
- поток вызова, reentrancy, callback lifetime, способ передачи ошибки.

Полнота raw: все целевые символы учтены, поддерживаемые доступны, оставшиеся
исключения явно опубликованы. Полнота boost: для каждого пользовательского
сценария есть безопасный контракт, документация и проверка. Это разные метрики.
Исключённые variadic, platform-only или unsafe-only API нельзя засчитывать как
реализованные. Не выдавать покрытие Windows за покрытие всей SDL.

## Слои

| Слой | Ответственность |
| --- | --- |
| Generated raw `sdl3` | Близкие к C имена/сигнатуры, enums/flags, POD-layout, opaque handles, platform guards; низкоуровневые опасные операции явно обозначены |
| Native adapters | Ref/out, pointer+count, UTF-8 копии, union tags, checked conversions, callbacks, синхронные scope-вызовы и владение |
| daScript boost по подсистемам | `with_*`, pipes, defaults/builders, Result/Option, события-значения, удобные массивы и пути |
| Прикладные модули | Цикл приложения, sprite batcher, UI, shader assets; не смешивать их с механической привязкой |

Сохранить совместимость существующих import и примеров через фасад. Разделить
крупный C++ registration на категории; тестовые API отделить от публичного ABI.
Генерированные C++ файлы хранить в репозитории: LLVM нужен разработчику
генератора, а не каждому пользователю библиотеки.

## Очередь всех категорий

Ниже предложенная группировка работ; точный список символов появится в реестре.

| Этап | Категории / объём | Ключевой контракт и критерий готовности |
| --- | --- | --- |
| P0 — инфраструктура | Перечень API, version/platform guards, генератор, AOT smoke, error/ownership policy | Нет молча пропущенных деклараций; воспроизводимая генерация; действующие примеры сохранены |
| P1 — фундамент | Init/subsystems, main/app callbacks, hints, properties, error, log, assert, version; timer/time | Типизированные properties; подписки с отменой; копия ошибки сразу; app-state и shutdown даже после частичной инициализации |
| P2 — полноценное 2D | Video/display/window; render, pixels, blendmode, rect, surface; clipboard | Перечисления устройств/дисплеев с правильным free; DPI; streaming/target textures, pitch и lock/unlock; формат/alpha; parent lifetimes |
| P3 — ввод | Все варианты events, keyboard/keycode/scancode, mouse; joystick/gamepad/touch/pen/sensor/haptic/HIDAPI | Owned text/payload, unknown-event fallback, горячее подключение, device ID вместо index, штатное отсутствие устройства; IME и rumble |
| P4 — данные | Filesystem, storage, IOStream, AsyncIO | Короткое чтение/EOF/error; память удерживается до completion; cancellation/shutdown; path/UTF-8; storage readiness |
| P5 — звук и камера | Audio devices/streams/recording/format/mixing; camera devices/formats/frames | Copy/borrow разделены; callback bridge, frame release, отключение устройства; реальные и dummy проверки отдельно |
| P6 — GPU | Весь SDL_gpu.h, включая graphics/compute/transfers/fences | Состояния command/pass, borrowed swapchain, корректный readback; см. отдельный GPU-план |
| P7 — системные сервисы | Threads/mutex/condition/semaphore/RWLock/atomic; loadso/process; power, messagebox/dialog/tray, locale, system, misc | Нативная синхронизация не даёт права параллельно использовать один das Context; callbacks и cancellation; процессы и async ответы |
| P8 — платформенный и служебный остаток | Platform, CPUInfo, intrinsics, endian/bits, stdinc, GUID; GL/EGL/Vulkan/Metal integration | Разделить C-макросы/inline, обычные функции и platform-only типы; host bridges вместо фиктивного переноса startup macros в скрипт |
| После обновления baseline | Новые категории/символы wiki, в том числе OpenXR/notifications, если входят в выбранный релиз | Новый реестр, feature gates, отдельные платформенные проверки |

P4 memory/IO adapters нужны также P2/P5; фундамент P0/P1 нужен всем этапам.
Первую вертикаль GPU можно начать после P0 и владения окнами, не дожидаясь P7/P8.
Обёртки функций, дублирующих daslib, допустимы в raw для совместимости C API;
boost должен предпочитать стандартную библиотеку, когда семантика совпадает.

## Сквозные задачи, которые генератор не решит

1. **Владение.** Owned/borrowed handles, parent token/generation и invalidation;
   тесты копирования/перемещения и повторного destroy. Первоначально scoped API
   с документированными ограничениями, затем проверяемые handle wrappers.
   Нельзя обещать Rust lifetimes у копируемого daScript-указателя.
2. **Ошибки.** Скопированный `SdlError` с operation/message; ожидаемые ошибки
   через стандартный Result, штатное отсутствие через Option. Текущий panic API
   оставить удобным фасадом; cleanup сохраняет исходную ошибку.
3. **Буферы.** Пустые массивы без `arr[0]`, проверка переполнения размеров,
   alignment/pitch, явное различие bytes/elements, освобождение SDL_free.
4. **Callbacks.** Синхронные блоки отдельно от сохраняемых registrations.
   Для retained callback нужен rooted state, unsubscribe, защита от вызова после
   shutdown и запрет исключению выходить через C ABI. Audio/timer/worker
   callbacks не вызывают произвольный script block на общем Context: сначала
   native queue и доставка на допустимый поток; real-time путь без аллокаций.
5. **ABI.** Проверять sizeof/alignof/offsetof, fixed arrays, uint64 flags,
   enum underlying types, opaque pointers, calling convention, unions.
   Не открывать union без проверки discriminant.
6. **Startup.** Добавить отдельный runner bridge для AppInit/Iterate/Event/Quit;
   не смешивать AppEvent с собственным PollEvent в одном цикле. Desktop loop
   сохранить; mobile/web требуют отдельной сборки и lifecycle тестов.

## Проверка и выпуск

Для каждой подсистемы: diff реестра → raw → адаптер → boost → один показательный
пример → тест нормального пути, ошибки и времени жизни → обновление покрытия.
Проверять интерпретатор и AOT с начала расширения; JIT только если объявлен
поддерживаемым. Отдельно проверять public consumers с BUILD_TESTING=OFF.

В CI: generator --check, компиляция raw и ABI assertions, сценарные тесты;
Windows/MSVC сначала, затем Linux/Clang или GCC и macOS/Clang. Android/iOS/web
получают собственный статус. Hardware-тесты GPU/камеры/gamepad/microphone
явно skip при отсутствии устройства; skip не превращается в «проверено».
Ошибочные вызовы проверять через адаптер/подменяемый backend до обращения к
SDL, а не намеренно передавать освобождённые указатели в библиотеку.

Release gate: опубликован denominator и exclusions, все целевые категории
разобраны, адаптеры покрыты lifetime/error tests, примеры выполняются,
пакет запускается вне дерева исходников, версии/лицензии assets/dependencies
зафиксированы. Тесты должны проверять контракт, а не только наличие символа.

## Следующие конкретные изменения

Preflight dasClangBind выполнен: SDK 22.1.5 установлен, модуль собран,
SDL.h разбирается, проверка активной ветки препроцессора проходит.
Ограниченная выборка (3 функции, 9 структур) скомпилирована и проверена в
interpreter/строгом AOT, см. [clangbind-experiment.md](clangbind-experiment.md).
Прежние 50 exports и текущие interpreter-сценарии проверены в отдельном
[parity-проекте](clangbind-parity.md). Он сохраняет общие аннотации/константы;
генерация типов, расширение ABI и ресурсный AOT остаются открытыми.
Это не завершение gate выбора backend.

1. Зафиксировать полный census 3.2.18 и схему policy, не менять публичный API.
2. Проверить dasClangBind на SDL_rect.h / SDL_pixels.h и выбранных структурах
   SDL_gpu.h; восстановить те же 50 функций и собрать AOT smoke.
3. Принять решение о генераторе по условиям из design review; закрыть пробелы
   enum/flags/constants и воспроизводимости, затем выбрать обновление SDL.
4. Ввести общие memory/ref/error adapters; портировать streaming texture и
   render-target/readback — они дадут повторно используемые буферные контракты.
5. Начать GPU ClearScreen → BasicTriangle с готовыми shader binaries.
   SDL_image/ttf подключать отдельными опциями после фиксации version matrix.

Не начинать со всего набора C++ туториалов подряд и не делать shader DSL
условием запуска первого GPU-примера. Дальнейшую очерёдность уточнять по
результатам этих пяти изменений, сохраняя полный backlog.

Источник startup-контрактов: [SDL main functions](https://wiki.libsdl.org/SDL3/README-main-functions).
