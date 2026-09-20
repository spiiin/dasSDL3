# Реестр API: первый рабочий профиль

> Current declaration coverage: all 92 active Windows GPU functions are generated.
> See [native GPU API](gpu-native-api.md). Runtime/AOT validation of the expanded
> surface is pending; earlier gaps below describe the previous checked subset.

Реализован 19 сентября 2026 для SDL 3.2.18, Clang 16.0.5,
target `x86_64-pc-windows-msvc`, C11. Это первый результат P0,
а не завершение всей инфраструктуры или межплатформенного census.

`tools/inventory_api.py` извлекает объявления через JSON AST Clang и активные
макросы через preprocessor с source line markers. `tools/api-policy.json`
задаёт версию, профиль, entry headers, исключения и место для ручных контрактов.
`tools/bindings.json` остаётся источником фактически генерируемых экспортов.

Результаты: [сводка](generated/api-windows-x64-msvc.md) и
[машинный реестр](generated/api-windows-x64-msvc.json). Снимок содержит hashes
всех 85 заголовков, исходные позиции, категории из header comments, сигнатуры,
поля records, callback typedefs и определения макросов без вычисления их
значений. Это census, не ещё один генератор native bindings и не ABI validator.

Сейчас 1226 активных функций, включая static inline и platform-visible
декларации: 145 generated, 8 adapted, 1073 pending. Adapted включает
семь Render/Surface и одну Audio функцию; каждая имеет ограниченный
контракт. Аудит после примера 22 исправил ранее неучтённый default-playback
adapter OpenAudioDeviceStream. Внутренние вызовы SDL и test-only helpers не
считаются автоматически публичными привязками. См. `binding-coverage-audit.md`.
Это не число всех экспортов SDL DLL и не процент готовности boost.
Structs с выбранными полями отмечены partial, opaque handles — opaque.
Собственный wrapper SDL_Wav вынесен в policy `project_types` с местом
объявления и причиной; он не увеличивает число типов самой SDL.
Record и одноимённый typedef считаются разными декларациями; суммарное число
записей нельзя трактовать как число уникальных пользовательских имён.

Кроме SDL.h явно включены main (без реализации startup), Vulkan, Metal и
revision. SDL2 aliases, test library, bundled GL/EGL и compiler scaffolding
имеют явные причины исключения. Каждый заголовок имеет observed/excluded/
unobserved статус. Observed не означает, что активны все ветки его `#if`.
Новые неохваченные headers видны в отчёте, а не молча считаются покрытыми.

## Запуск

```powershell
python tools/inventory_api.py --clang <path-to-clang> --sdl-include <SDL-source>/include
python tools/inventory_api.py --clang <path-to-clang> --sdl-include <SDL-source>/include --check
python -B tests/test_api_inventory.py --clang <path-to-clang>
```

`--output-dir` позволяет сравнивать экспериментальный снимок вне репозитория.
В файл не попадают абсолютные пути и timestamps; фиксируется версия Clang.
Изменение compiler/version/headers требует осмысленного обновления snapshot.
Сравнивать `--check` нужно тем же toolchain. В CMake добавлены два теста
`sdl3_api_inventory` и `sdl3_api_inventory_contracts` для Windows при наличии
Python/Clang; существующий общий фильтр `^(sdl3_|bindings_up_to_date)` их включает
после повторной конфигурации сборки.

## Ручная policy

Ключ записи — `kind:name`, например `function:SDL_OpenAudioDeviceStream`.
Допустимы `raw_status`, `boost_status`, `reason`, `adapter`, `tests`, `contract`.
Generated coverage выводится только из bindings.json, policy не может его
присвоить. Для adapted/excluded требуется причина; неизвестные ключи и имена
символов приводят к ошибке. Исчезновение существующего generated function
также приводит к ошибке вместо тихого уменьшения denominator.

`contract` предназначен для allocator/deleter, parent, nullable, borrow/copy,
pointer/count units, lifetime и thread/callback/error rules. Пока это расширяемые
метаданные: полная схема контрактов и валидация adapter/test paths впереди.
Boost status остаётся unreviewed до отдельного аудита конкретного символа.

## Что проверено и что дальше

Четыре теста с настоящим Clang на небольших искусственных заголовках проверяют
active platform branch, locations/categories, function pointers, variadics,
fixed arrays, uint64 macro spelling, #undef, повторные declarations,
детерминизм, неверную версию, пропавший export и ошибочную policy.
Дополнительно у 1226 функций настоящего SDL сверено имя с исходной строкой.

Локальная проверка: 11 существующих CTest-сценариев и 2 новых прошли.
После исправления доступа основная сборка повторно сконфигурирована;
все 13 тестов повторно прошли непосредственно из build/ninja.
`--check` отдельно подтвердил точное соответствие снимка повторной генерации.

Следом: отдельные Linux/macOS profiles и объединённый реестр доступности;
неактивные платформенные guards и версии появления; явный аудит manual adapters;
вычисленные enum/constant values и ABI assertions; dasClangBind/AOT эксперимент.
Не называть текущий снимок «полной SDL на всех платформах».

## Готовность dasClangBind

В проверенном каталоге MSVC LLVM установлен Clang 16.0.5, есть libclang.dll и
libclang.lib. Наш pinned `modules/dasClangBind/CMakeLists.txt` ищет Clang 22.1.
Наличие libclang 16 не удовлетворяет этому условию. Теперь полный SDK 22.1.5
установлен отдельно в C:/src/libclang, dasClangBind собран и загружен.
Разбор SDL.h и upstream-тест препроцессора прошли; подробности и команды
в [clangbind-setup.md](clangbind-setup.md). CppGenBind теперь штатный backend Windows x64 (saved snapshots).
Теперь отдельная выборка rect/pixels/GPU сгенерирована, собрана и проверена
в interpreter/AOT: [clangbind-experiment.md](clangbind-experiment.md).
Эквивалентность 50 functions и interpreter-сценариев проверена отдельно:
[clangbind-parity.md](clangbind-parity.md). Затем выполнены самостоятельная
генерация текущих аннотаций/констант и [ресурсный AOT](clangbind-types-aot.md).
Штатный backend уже выбран; впереди расширение platform/ABI coverage.
Работающий Python backend и публичные bindings в этой итерации сохранены.
