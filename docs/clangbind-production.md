# Сохранённые привязки CppGenBind

Основной CMake выбирает `DASSDL3_BINDING_BACKEND=clangbind` по умолчанию
для MSVC Windows x64. Для остальных конфигураций остаётся `python`.
Явный выбор неподдерживаемого CppGenBind-профиля завершается ошибкой.
Профиль: SDL 3.2.18, LLVM SDK 22.1.5, x86_64-pc-windows-msvc,
daScript из закреплённого сабмодуля. Это ещё не полная обвязка SDL.

`src/generated/clangbind/` содержит 50 функций, 7 записей с 40 полями,
6 opaque-типов и 42 константы. Ручные адаптеры и boost используются без изменений.
Размеры, выравнивание, смещения полей и значения констант проверяются
static_assert при компиляции. `profile.json` хранит хеши входной политики,
генератора и SDL-заголовков. Названия версий в профиле обозначают проверенный
toolchain; хеши заголовков позволяют обнаружить подмену исходных данных.

## Обычная сборка

Из x64 Native Tools Command Prompt, в корне проекта:

```bat
cmake -S . -B build/consumer -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DDAS_CLANG_BIND_DISABLED=ON -DDAS_LLVM_DISABLED=ON
cmake --build build/consumer --target dasSDL3_runner --parallel 6
build\consumer\bin\dasSDL3_runner.exe examples/square.das --smoke-test
```

`DASSDL3_ENABLE_GENERATORS` по умолчанию OFF: ни Python, ни Clang, ни LLVM
не нужны для привязок. SDL скачивается через FetchContent; для работы без сети
задайте `-DFETCHCONTENT_SOURCE_DIR_SDL3=<папка исходников SDL 3.2.18>`.
daScript должен уже присутствовать как сабмодуль. Наличие LLVM на машине не
мешает; потребитель его не ищет и не линкует.

Для прежнего backend укажите `-DDASSDL3_BINDING_BACKEND=python`.
Оба backend используют сохранённые файлы; имя python не означает запуск Python
при каждой сборке.

## Обновление привязок

Сначала подготовьте daslang с dasClangBind по `clangbind-setup.md`.

```bat
python tools/run_clangbind_parity.py --snapshot --daslang third_party/daScript/bin/daslang.exe --sdk C:/src/libclang --sdl-include test-app/build/_deps/sdl3-src/include --output src/generated/clangbind
python tools/run_clangbind_parity.py --snapshot --check --daslang third_party/daScript/bin/daslang.exe --sdk C:/src/libclang --sdl-include test-app/build/_deps/sdl3-src/include --output src/generated/clangbind
```

Режим snapshot работает независимо от старого api.json. Генерация дважды
выполняется во временных каталогах и проверяется на детерминированность.
`--check` ничего не записывает и завершается ошибкой при устаревшем файле.
Без `--snapshot` сохраняется прежняя проверка совпадения со старым backend.
Имя parity в инструменте оставлено для совместимости существующих тестов.

Для CMake-цели `generate_bindings` и CTest `bindings_up_to_date` задайте:

```bat
-DDASSDL3_ENABLE_GENERATORS=ON -DDASSDL3_GENERATOR_DASLANG=C:/src/dasSDL3/third_party/daScript/bin/daslang.exe -DDASSDL3_LLVM_SDK=C:/src/libclang
```

Для census по-прежнему используется отдельный `DASSDL3_CLANG_EXECUTABLE`:
сохранённый inventory получен Clang 16.0.5, не SDK 22.

Upstream daScript пишет библиотеки и shared modules в дерево исходников и
удаляет отключённые shared modules при конфигурации. Разные каталоги `-B`
не изолируют эти артефакты. Не запускайте параллельно developer и consumer
сборки одного checkout. После конфигурации с CLANG_BIND_DISABLED=ON нужно
пересобрать dasModuleClangBind в developer-конфигурации перед генерацией;
для постоянной изоляции используйте отдельные checkout зависимостей.

## Границы этапа

Обычный runner работает через interpreter. Строгий AOT с защитой try/recover
пока проверяется отдельным `tests/clangbind_parity`; основной CMake не обещает
готовую AOT-сборку приложения. Проверка LLVM-free относится к сборке из исходников
со снимками, а не к install/export SDK или переносимому бинарному пакету.
Следующие этапы: расширение allowlist, новые ownership-контракты, platform policy
и отдельная проверка вложенных GPU create-info.

## Проверено 2026-09-19

- Основная developer-сборка с CppGenBind: 15/15 CTest, включая freshness,
  inventory, libclang preflight и текущие SDL-сценарии.
- Отдельный parity-проект: 33/33, включая 10 строгих AOT-сценариев,
  оба interpreter backend, metadata и отрицательные проверки генерации/AOT.
- Чистая сборка из 451 шага с отключёнными генераторами, CLANG_BIND и LLVM:
  10/10 обычных SDL-тестов. Поиск Clang, LLVM и Python3 дополнительно запрещён
  через CMAKE_DISABLE_FIND_PACKAGE; build.ninja не содержит генератора привязок
  и ссылок на libclang/libLLVM.
- После переключения этой сборки на BUILD_TESTING=OFF пересобран runner и
  успешно выполнены square, textures, input и audio в smoke-режиме.
  Аудио проверено с dummy-драйвером, слышимое воспроизведение не проверялось.
- Свежие снимки проходят --check; намеренно испорченный снимок отклоняется,
  его содержимое остаётся неизменным. Снимки репозитория проходят --check.

Consumer собирался в отдельном каталоге из исходников; SDL взят из локального
checkout release-3.2.18. После проверки восстановлен developer dasClangBind,
который upstream удалил при отключении модуля.
