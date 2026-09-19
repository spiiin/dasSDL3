# Генерация типов/констант и AOT ресурсов

19 сентября 2026. Проверенный профиль: Windows x64, MSVC 19.38, Release /MD,
SDL 3.2.18, daScript `35bf260c0d8a79b94c64005bd3d2435adcf7e261`, libclang 22.1.5.
Это продолжение [проверки 50 функций](clangbind-parity.md).

## Самостоятельная генерация текущего API

Эксперимент больше не читает production sdl3_types.inc и не копирует
регистрации типов/констант из production sdl3_functions.inc.

Единственный источник отбора и публичных имён — tools/bindings.json.
tools/api-policy.json отдельно отмечает SDL_Wav как собственный wrapper,
а не тип SDL. Python передаёт policy генератору и проверяет результат;
C++ функций создаёт CppGenBind, а SDL-специфичный emitter в том же das-скрипте
создаёт ограниченные аннотации полей и opaque types по данным libclang.
Общий struct emitter CppGenBind не используется для раскрытия всех полей:
нужно сохранить установленный контракт SDL_Event и SDL_AudioSpec.

Генерируются:

- 50 raw-функций, как на предыдущем этапе;
- 13 аннотаций: 7 структур/union и 6 opaque types, включая проектный SDL_Wav;
- ровно 40 выбранных полей с прежними именами, включая event_type;
- 42 константы с явной шириной int32/uint32/uint64 из policy.

Константы вычисляются libclang через типизированные декларации во временном
C-заголовке. Generated C++ содержит вычисленные значения и static_assert,
сверяющий их с теми же SDL-макросами/enum. Для 7 records и 40 полей добавлены
sizeof/alignof/offsetof assertions по данным Clang. Это профильные проверки
Windows x64, а не обещание межплатформенного ABI.

Ошибки парсинга, исчезновение поля/типа/функции, неподдержанные bitfields и
нецелочисленные вычисления не допускают публикации output. Набор полей и
констант проверяется против policy. Две генерации в разных выходных каталогах
должны дать одинаковый результат. Снимки основного backend не изменены.

Native metadata старого и нового модулей совпали: 104 функции (raw + adapters
+ test helpers), 13 типов, 40 полей и 42 константы. Сравниваются квалификаторы
типов, имена аргументов, side effects/unsafe flags, размеры/выравнивание,
copy/constructor flags, имена/смещения/типы полей, ширина и значения констант.

## AOT consumer

tests/clangbind_parity/aot_tool.cpp вызывает pinned daslib/aot_cpp::run_aot.
Единый FileAccess монтирует dassdl3 и для компиляции скриптов, и для инструмента.
Boost-модули sdl3_boost и sdl3_audio_boost генерируются отдельными единицами
компиляции: генерации только main-примеров недостаточно для их AOT-функций.

parity_aot_runner включает скомпилированный AOT-код, задаёт
`aot=true`, `fail_on_no_aot=true` и дополнительно проверяет `main->aot`.
Runner без AOT-кода обязан завершиться именно с `AOT link failed on main`;
проверка не принимает произвольный сбой DLL/запуска за ожидаемую ошибку.

Проверяются существующие bindings/boost/textures/input/audio tests и четыре
примера square/textures/input/audio. Это те же scripts, включая panic,
ранний выход, частичную инициализацию, вложенные scopes и освобождение ресурсов.
Audio использует dummy-драйвер только в окружении соответствующего теста.
JIT, аппаратный GPU и слышимый аудиовывод здесь не проверяются.

Итог: **33/33 CTest прошли** (57,74 с). Это 10 сценариев на каждом из двух
interpreter backend, те же 10 в строгом AOT, сравнение metadata, отрицательная
проверка отсутствующего AOT и проверка ошибок генерации с четырьмя fixtures.

## Обход ошибки pinned AOT runtime

В third_party/daScript/src/simulate/simulate_exceptions.cpp функция
das_try_recover вызывает catch_block **до** переноса exception в last_exception
и очистки exception. Interpreter SimNode_TryCatch делает это до вызова recover.
Поэтому изначально обычные AOT-примеры проходили, но четыре теста с panic
теряли исходное сообщение, хотя выполняли cleanup.

Локальный tests/clangbind_parity/aot_recover.h восстанавливает interpreter-order:
runWithCatch восстанавливает stack/ABI, затем очищаются stopFlags, текущая
ошибка становится last_exception, exception очищается и вызывается recover.
Паника самого recover выходит в наружный handler. Исходники daScript не менялись.

В aot_tool.cpp есть явное преобразование сгенерированных вызовов
`das_try_recover(__context__,` в `das::SDL_AotTryRecover(__context__,`.
Оно применяется при генерации, без ручного редактирования generated C++ и
без глобального macro override runtime. Если spelling вызова изменится,
генерация останавливается для пересмотра обхода. Это привязка к pinned compiler,
а не универсальный fix daScript. При обновлении upstream её нужно проверить
и удалить после исправления runtime.

Отдельный recover.das проверяет текущий last_exception, повторный panic в
recover и переход в наружный recover. Он запускается на обоих interpreter
backend и в строгом AOT. Существующий SDL_InvokeProtected для восстановления
block arguments также сохранён.

## Запуск

Используется прежний standalone CMake-проект, теперь с AOT targets.
Из x64 Native Tools Command Prompt в корне репозитория:

```bat
cmake -S tests/clangbind_parity -B build/clangbind-parity -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_SDK=C:/src/libclang -DSDL_INCLUDE=C:/src/dasSDL3/test-app/build/_deps/sdl3-src/include
cmake --build build/clangbind-parity --parallel 6
ctest --test-dir build/clangbind-parity --output-on-failure
```

MAIN_BUILD по умолчанию build/ninja; его static SDL и собранный daScript должны
соответствовать указанным версиям. Каталог -B можно вынести из репозитория.
Generated output включает parity_types.inc, parity_functions.inc,
parity-contract.tsv и parity-api.json; AOT .cpp также остаются внутри сборки.

Основной CMake по-прежнему выбирает Python backend. Макросы альтернативных
include и AOT-header задаются только экспериментальным target. Следующий шаг —
оформить этот проверенный backend как штатную опцию, обеспечить проверяемые
generated snapshots и сборку consumer без LLVM. Перед широким расширением
остаются platform policy, nested GPU create-info и новые ownership contracts.
