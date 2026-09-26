# План полной привязки SDL3

> Current core pin: SDL 3.4.16. See [migration and coverage changes](sdl-3.4-upgrade.md); older 3.2.18 counts below describe the original baseline.

Актуализирован 22 сентября 2026. База: SDL 3.2.18, daScript
`35bf260c0d8a79b94c64005bd3d2435adcf7e261`, Windows x64/MSVC.
Текущее покрытие — [api-coverage.md](api-coverage.md); точные декларации и
платформенные guards — [реестр заголовков](generated/api-windows-x64-msvc.md).
Категории wiki помогают навигации, но не заменяют закреплённые заголовки.

## Принятая архитектура

1. Генерируемые SDL имена, сигнатуры, enums/flags и выбранные поля структур.
2. Адаптеры только для ref/out, массивов, строк, union tags и времени жизни.
3. Небольшие daScript defaults, pipes и `with_*` с `daslib/defer`.

Raw сохраняет SDL bool/null/zero/sentinel. Boost возвращает Result/Option и копирует ошибку до cleanup; см. [контракт](error-handling.md).
Не добавлять panic, try/recover или native catch-мосты. Указатели копируются
как aliases; scopes не обеспечивают borrow checker. Контракты:
[ошибки и defer](error-handling.md), [граница API](gpu-api-boundary.md).
Mesh/material/scene/batching/планы не входят в публичную привязку.
Checked GPU ID имеют отдельные `distinct`-типы поверх `uint64` в native
адаптерах и boost; [контракты и миграция](gpu-handles.md). Это проверка вида
ресурса при компиляции, а не новый слой владения. Raw SDL-указатели сохранены.

CppGenBind — основной backend Windows x64; Python/Clang остаётся baseline
и fallback. Добавлять декларации через policy и генератор, не вручную в snapshots.
Обычный consumer использует сохранённый C++ без LLVM и shader compiler.

## Завершённый GPU этап

Все 92 активные Windows GPU функции доступны. Добавлены создание shader/pipeline
из данных daScript, transfers, native defer scopes, graphics/compute/swapchain,
MRT/MSAA/depth/stencil и примеры 48–50. Есть CPU byte/pixel oracles и
interpreter/AOT/consumer проверки. [Результаты и исключения](gpu-native-validation.md).
Это не сертификация Metal, других ОС и всех аппаратных форматов.

## Очередь

Текущий проход по P7 завершён для активных Windows-деклараций.
Первый раздел: [Synchronization](synchronization.md), 28/28 функций SDL_mutex.h;
Thread/TLS (12/12) и Atomic (15/15): [контракты](thread-atomic.md);
Process/LoadSO (9/9 + 3/3): [контракты](process-loadso.md).
System/Power/Locale/Dialog/Tray: [ещё 42 raw функции](platform-services.md).
P7: все 109 активных Windows-деклараций подключены; проверка интерактивных Dialog
и остальных платформ остаётся отдельной. Следующий раздел деклараций — P8.
Локальная проверка 22 сентября: P7 interpreter/census 10/10; основные gates 7/7;
baseline/CppGenBind/AOT и metadata 29/29. После исправления Process-примера и
добавления argv с пробелами/кавычками его шесть backend/AOT проверок повторены успешно.
Consumer собран с выключенными LLVM/Clang/Python; примеры 81–85 прошли, включая
исправленный пример 83. Production-конфигурация восстановлена, freshness прошёл.
[Web / Emscripten и HTML-примеры](web-roadmap.md) остаются отдельным продолжением. Первый Web bootstrap собран: 65 SDL raw-функций, десять
HTML-страниц на SDL Renderer/WebGL и штатном dasOpenGL, проверки Edge/Firefox. Полный профиль,
остальные примеры и AOT остаются в web-roadmap; SDL_GPU не поддерживается этим backend.

P3 API: [очередь событий](event-queue.md) и [callbacks](event-callbacks.md) подключены — 19/19
raw-функций Events. Есть ожидание/таймаут, пакетные peek/take, подсчёт, фильтрация
по диапазону и регистрация пользовательских типов. [SdlEvent](event-variants.md)
содержит 53 варианта: ввод, окна, Quit, drop, user metadata, Joystick/Gamepad и Touch/Pen/Sensor;
строки копируются. Остальные payloads пока Unknown. [Keyboard/Mouse](keyboard-mouse.md)
подключены: 24/24 и 22/22 raw-функций. [Joystick/Gamepad](joystick-gamepad.md) — 58/58 и 73/73 raw-функций, с явными
ограничениями virtual balls/sensor queue. [Touch/Pen/Sensor/Haptic/HIDAPI](peripherals.md) подключены: 71 raw-функция и 13 event-тегов;
Pen — только события в SDL 3.2.18. IME candidates, clipboard MIME arrays и raw user-pointer adapters подключены;
[контракт и move-only SdlEvent](event-list-payloads.md). Явный остаток P3: payloads
keyboard/mouse device hotplug, native virtual callbacks, строковые имена properties
Joystick/Gamepad и проверка оборудования.
По решению пользователя остаток P3 отложен. P4 начат с полного раздела
[Filesystem](filesystem.md): 11/11 raw, copied paths/lists и Result helpers.
[IOStream](iostream.md): 46 raw, fixed-text IOprintf, IOvprintf остаётся pending.
[Storage](storage.md): 17/17 raw, native callbacks, array/copy adapters и defer scopes.
[AsyncIO](asyncio.md): 11/11 raw, outcome refs, owned file results и queue defer.
P5: [Audio devices](audio-devices.md), 21 raw API и dummy recording.
[Audio stream controls](audio-stream-controls.md): ещё 12 raw API; Audio now 56/56 после [native callbacks и WAV/conversion](audio-final-api.md).
Camera: [15/15 raw](camera.md), dummy discovery/error contracts; далее P7. Аппаратные проверки и дефекты pinned SDL перечислены в Audio/Camera contracts. IOvprintf остаётся отдельным va_list исключением P4. Retained callbacks
принимают нативные адреса; script-блок доступен только синхронному FilterEvents.

| Этап | Объём | Критерий |
| --- | --- | --- |
| P1, остаток | Properties/Hints/Init/Error/Log/Timer callbacks, va_list и строковые макросы | Базовые пакеты реализованы; retained callbacks требуют отдельных контрактов |
| P2, функции подключены | Video/display/window без GL/EGL, Render, Surface/Pixels/Blend/Rect, Clipboard | Rect 18/18, Clipboard 11/11, hit-test; RenderDebugTextFormat — fixed-text adapter. Платформенная валидация ограничена |
| P3 | Events, Keyboard/Mouse, Joystick/Gamepad, Touch/Pen/Sensor/Haptic/HIDAPI | Union tags, owned payload, hotplug, device IDs, отсутствие оборудования |
| P4, основной API подключён | Filesystem 11/11; IOStream 46 raw + text adapter (IOvprintf pending); Storage 17/17; AsyncIO 11/11 | EOF/short read/error, retained buffers, completion/cancellation, shutdown |
| P5, raw подключён | Audio 56/56; Camera 15/15 | Copy/borrow, release frames, callbacks, реальные устройства отдельно от dummy |
| P6, сопровождение | GPU другие платформы и backend ограничения | Платформенные сборки, ABI и output tests; отдельный план ниже |
| P7, raw подключён | 109/109 активных Windows функций: Threads/synchronization, Process/LoadSO, Power/Dialog/Tray/Locale/System | Native callbacks, defer, Result/Option; интерактивные Dialog и другие OS отдельно |
| P8 | Platform/CPUInfo/Stdinc/GUID, macros/inlines, GL/Vulkan/Metal integration (включая 20 GL/EGL функций Video, явно перенесённых из P2) | Явные exclusions, calling convention и startup host bridges |

P0 продолжается поперёк очереди: Linux/macOS census и реальные сборки,
ABI/flags/macros, install/export и запуск вне дерева исходников. Сборка без LLVM
не доказывает переносимость установленного пакета. Обновление SDL — отдельный
version diff, не незаметное переключение FetchContent на main.

## Properties: реализованный пакет и остаток

В закреплённом SDL_properties.h **21 функция**, не 15 из старого плана.
Реализованы 19 generated функций, copied enumeration и defer scopes. Retained
cleanup-callback остаётся pending; ограничения и найденная ошибка кэша SDL —
в [properties.md](properties.md). Hints/Init: 12 новых raw функций, copies и subsystem scopes реализованы;
[контракт и оставшиеся callbacks](init-hints.md). Error/log/time также реализован: [контракты и остаток](diagnostics-time.md).
Video discovery: 31 raw запроса и copy/ref adapters реализованы,
[контракты](video-discovery.md). Создание и состояние окон также реализованы: [контракты](window-state.md).
Fullscreen/surfaces и прочие оконные операции реализованы с ограничениями
[window-io.md](window-io.md). Video: 89/109; оставшиеся 20 GL/EGL функций явно перенесены в P8. Hit-test, Rect и Clipboard подключены; [контракт](rect-clipboard-hittest.md). P7 подключён в Windows census; следующий основной раздел — P8; исключение IOvprintf и остаток P3 перечислены выше. Миграция [Result/Option boost API](result-option-plan.md) завершена и локально проверена. P2 не переоткрывается; GL/EGL остаётся в P8.
Software renderer/primitives: ещё 10 raw функций; [контракт](renderer-primitives.md).
Состояние Renderer (viewport/clip/scale/output): 10 raw функций и ref adapters; [контракт](renderer-state.md).
Renderer queries/logical presentation: 10 raw функций, все режимы и преобразование координат; [контракт](renderer-presentation.md).
Создание и состояние текстур: 10 raw функций, float modulation, scale mode и scopes; [контракт](texture-state.md).
Byte modulation/blend modes и texture updates/locking: 10 raw функций, RGBA32 region updates и surface-lock scope; [контракт](texture-transfer.md).
YUV/NV, renderer color/blend и custom blend composition: 10 raw функций; [контракт](renderer-yuv-blend.md).
Renderer creation/draw/readback/VSync/debug: 10 raw функций и scopes; [контракт](renderer-operations.md).
Render: 88 generated / 1 adapted / 0 pending. [GeometryRaw/events/interop](renderer-final-api.md); DebugTextFormat ограничен fixed-text адаптером, положительные Metal/Vulkan interop сценарии не проверены. Surface state: 16 raw функций, ref-адаптеры и пиксельные тесты; [контракт](surface-state.md). Все 58 Surface и 11 Pixels функций имеют raw-привязки, включая palettes/alternate images, внешнюю память, blit и BMP IO; [контракт](surface-pixels.md). Проверка относится к закреплённому Windows-профилю; не означает все форматы и межплатформенные сценарии. Пакеты формируются по связанному поведению, без фиксированного числа функций.
Ниже сохраняются критерии пакета; callback-пункт 5 остаётся открытым.

1. Генерация 19 сигнатур без callbacks, SDL_PropertyType и SDL_PropertiesID;
   сверка raw status с реестром. Raw pointer properties остаются низкоуровневыми.
2. Строковые/числовые/float/bool getters/setters, Has/Type/Clear/Copy;
   строковый boost возвращает копию, defaults сохраняются.
3. Owned Create/Destroy scope и Lock/Unlock defer scope. GlobalProperties и
   property IDs объектов — borrowed, не уничтожаются общим owner helper.
4. EnumerateProperties: синхронно собрать копии имён через native callback,
   затем предоставить script array; не вызывать произвольный script из C callback.
5. SetPointerPropertyWithCleanup: сначала явный контракт ownership/thread/replacement;
   не сохранять script block без rooting и teardown. Если bridge не готов,
   оставить это видимым исключением, не засчитывать Properties как полную.
6. Тесты типов/defaults/UTF-8/копий, replacement/clear, lock и раннего выхода,
   borrowed IDs, cleanup exactly once; короткий public пример без unsafe.
7. Генерация/freshness/ABI, interpreter и AOT, no-LLVM consumer; обновить policy
   и покрытие по реально доступным контрактам, затем переходить к Hints/Init.

## Общий порядок пакета

Реестр → generated raw → необходимые адаптеры → тонкий boost → пример →
проверки нормального пути, ошибок, владения и результата → обновление документации.
Группировать независимые функции, проверять пакет вместе; после исправления
повторять затронутые проверки. Не запускать consumer configure параллельно
clangbind: они меняют общую конфигурацию модулей daScript.

Retained callbacks требуют rooting, unsubscribe и разрешённого потока;
аудио/timer/worker callbacks не вызывают общий Context. AppInit/Iterate/Event/Quit
потребуют отдельного host runner bridge. Не обещать cleanup после panic приложения.

Отдельные направления: [GPU и shader DSL](gpu-roadmap.md),
[дополнительные библиотеки](companion-libraries-roadmap.md),
[порты и сценарии](porting-matrix.md), [идиомы и генератор](binding-design-review.md).
