# Генерация типов и строгий AOT

CppGenBind functions и SDL-specific emitter используют libclang и общую policy
из tools/bindings.json. Выбранные annotations/opaque types, aliases, поля и
константы генерируются независимо от legacy snapshots. SDL_Event раскрывается
по явной policy, не как неограниченный union.

Constant expressions вычисляются во временном C header с явной шириной.
Generated C++ сверяет значения, sizeof/alignof/offsetof с компилятором.
Parse errors, changed/missing declarations, unsupported bitfields и неверные
числовые диапазоны отклоняются. Nested types регистрируются по зависимостям
полей. Набор GPU enum/record проверок описан в gpu-types.md.

## AOT consumer

Tests/clangbind_parity/aot_tool.cpp вызывает pinned daslib/aot_cpp::run_aot.
FileAccess монтирует dassdl3 одинаково для compiler и runtime. AOT создаётся для
сценариев и boost-модулей из AOT_SCRIPTS/AOT_MODULES в CMakeLists.txt.
parity_aot_runner задаёт aot=true, fail_on_no_aot=true и проверяет main->aot.
Отрицательный runner должен получить именно AOT link failed on main; произвольный
сбой DLL/старта не считается правильным результатом.

Те же public сценарии проверяются interpreter и AOT, включая GPU CPU oracles,
ошибки SDL и defer на раннем выходе. Эти тесты не устанавливают JIT поддержку.
Pinned emitter имеет проблему deeply nested inline-block/for capture: pixels test
использует явную while-переменную. Inlining/AOT остаются включены; upstream не менялся.

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
backend и в строгом AOT. Это только тестовый AOT compatibility shim для recover.das; SDL wrappers
не используют try/recover или SDL_InvokeProtected (он удалён).


## Сборка и проверка

Команды — [clangbind-parity.md](clangbind-parity.md). MAIN_BUILD/SDL_INCLUDE
должны соответствовать закреплённой SDL; vcvars64 и 6 parallel jobs.
Список тестов задаётся CMake, текущие результаты —
[gpu-native-validation.md](gpu-native-validation.md). Не использовать числа
первоначального 50-function эксперимента как текущее покрытие.
