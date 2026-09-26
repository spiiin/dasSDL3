# CppGenBind / baseline parity

Windows x64/MSVC, SDL 3.2.18, pinned daScript, libclang 22.1.5.
CppGenBind is the production default; the separate tests/clangbind_parity project
compares it with Python/Clang baseline and executes scripts in both interpreters
and strict AOT. Current results: [gpu raw tests](gpu-raw-tests.md).

## Contract

Selection and aliases come from tools/bindings.json. run_clangbind_parity.py
checks C signatures/argument names and deterministic generation in two clean
folders. Types/constants are independently emitted from libclang and policy;
native adapters and script boost are shared. Missing/extra/duplicate exports
or parse errors fail generation before publication.

The same module_sdl3.cpp is compiled into separate baseline and cppgenbind
executables; only one sdl3 module is registered in each process. Generated
registration/type include overrides choose the corresponding backend.
Native metadata compares qualifiers, arguments, side effects/unsafe flags,
record sizes/alignments/fields, enums and constant widths/values.

Runtime cases cover results, acquisition failure, normal/early cleanup and
independent CPU pixels/bytes. GPU tests explicitly select Vulkan and D3D12.
Audio dummy checks do not certify audible output. Missing-AOT rejection and
negative generator/type/API-boundary cases remain part of the suite.

## Нюансы libclang

- Старый JSON AST включает `__attribute__((cdecl))` в signature; libclang 22
  не печатает его для текущей цели. Перед нормализацией генератор отдельно
  проверяет calling convention (C/Win64), целевая платформа явно закреплена.
  Другие calling conventions не принимаются молча.
- `_Bool` из C11 преобразуется в C++ `bool` через hook CppGenBind. Имена и
  public types проверены уже после компиляции native регистраций.
- Полный обход системных AST в upstream AnyGenBind наткнулся на узел без
  исходного файла: преобразование пустого CXString вызвало native crash.
  Для этой задачи нужен только top-level FunctionDecl; собственный обход
  выбирает именно такие объявления, а их регистрацию выполняет CppGenBind.
  Исходники daScript не менялись. Это не доказательство исправности общего
  генератора для произвольных системных AST.
- Скрипт-wrapper проверяет код процесса и diagnostics: нулевой exit code
  upstream генератора сам по себе не означает корректного результата.

## Повторный запуск

После сборки основного проекта и dasClangBind, из x64 Native Tools Command
Prompt Visual Studio в корне репозитория:

```bat
cmake -S tests/clangbind_parity -B build/clangbind-parity -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_SDK=C:/src/libclang -DSDL_INCLUDE=C:/src/dasSDL3/test-app/build/_deps/sdl3-src/include
cmake --build build/clangbind-parity --parallel 6
ctest --test-dir build/clangbind-parity --output-on-failure
```

MAIN_BUILD по умолчанию build/ninja основного проекта; SDL_INCLUDE должен
соответствовать его закреплённой SDL 3.2.18. Можно задать другой MAIN_BUILD
или вынести каталог `-B` за пределы репозитория. Проверенный запуск использовал
рабочую папку Codex. Результат signature comparison — generated/parity-api.json.


## Operational limits

Do not overlap no-LLVM consumer configure with clangbind builds/tests: daScript
module configuration is shared. Restore generator configuration before gates.
Do not edit scripts while their old AOT binary is under test; regenerate/rebuild
before running changed scripts. Other platforms require separate profiles/builds.
See [AOT details](clangbind-types-aot.md) and [production generation](clangbind-production.md).
