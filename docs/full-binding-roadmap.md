# План полной привязки SDL3

Актуализирован 20 сентября 2026. База: SDL 3.2.18, daScript
`35bf260c0d8a79b94c64005bd3d2435adcf7e261`, Windows x64/MSVC.
Текущее покрытие — [api-coverage.md](api-coverage.md); точные декларации и
платформенные guards — [реестр заголовков](generated/api-windows-x64-msvc.md).
Категории wiki помогают навигации, но не заменяют закреплённые заголовки.

## Принятая архитектура

1. Генерируемые SDL имена, сигнатуры, enums/flags и выбранные поля структур.
2. Адаптеры только для ref/out, массивов, строк, union tags и времени жизни.
3. Небольшие daScript defaults, pipes и `with_*` с `daslib/defer`.

Ошибки сохраняют SDL bool/null/zero/sentinel; читать SDL_GetError после отказа.
Не добавлять panic, try/recover или native catch-мосты. Указатели копируются
как aliases; scopes не обеспечивают borrow checker. Контракты:
[ошибки и defer](error-handling.md), [граница API](gpu-api-boundary.md).
Mesh/material/scene/batching/планы не входят в публичную привязку.

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

| Этап | Объём | Критерий |
| --- | --- | --- |
| P1, ближайший | Properties → Hints/Init → error/log/time | Копии строк, defaults, borrowed/owned IDs, синхронные и retained callbacks разделены |
| P2 | Video/display/window, Render, Surface/Pixels/Blend/Rect, Clipboard | Освобождение перечислений SDL, DPI, pitch/lock, parent lifetime, region updates |
| P3 | Events, Keyboard/Mouse, Joystick/Gamepad, Touch/Pen/Sensor/Haptic/HIDAPI | Union tags, owned payload, hotplug, device IDs, отсутствие оборудования |
| P4 | Filesystem, Storage, IOStream, AsyncIO | EOF/short read/error, retained buffers, completion/cancellation, shutdown |
| P5 | Audio/recording/mixing, Camera | Copy/borrow, release frames, callbacks, реальные устройства отдельно от dummy |
| P6, сопровождение | GPU другие платформы и backend ограничения | Платформенные сборки, ABI и output tests; отдельный план ниже |
| P7 | Threads/synchronization, Process/LoadSO, Power/Dialog/Tray/Locale/System | Context thread affinity, retained callbacks, отмена, shutdown |
| P8 | Platform/CPUInfo/Stdinc/GUID, macros/inlines, GL/Vulkan/Metal integration | Явные exclusions, calling convention и startup host bridges |

P0 продолжается поперёк очереди: Linux/macOS census и реальные сборки,
ABI/flags/macros, install/export и запуск вне дерева исходников. Сборка без LLVM
не доказывает переносимость установленного пакета. Обновление SDL — отдельный
version diff, не незаметное переключение FetchContent на main.

## Ближайший пакет: Properties

В закреплённом SDL_properties.h **21 функция**, не 15 из старого плана.

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
