# dasClangBind: установка и проверка Windows x64

Проверено 19 сентября 2026 на pinned daScript
`35bf260c0d8a79b94c64005bd3d2435adcf7e261`, SDL 3.2.18 и MSVC 19.38.
LLVM SDK установлен в `C:/src/libclang`. Это инструментарий для эксперимента
с генерацией, а не замена рабочего Python backend.

## SDK

Upstream-инструкция: `third_party/daScript/skills/internal/clang_bind_build.md`.
Pinned CMake модуля требует Clang 22.1. Нужен полный SDK с include, lib и
`lib/cmake/clang/ClangConfig.cmake`; одного clang.exe/libclang.dll недостаточно.

Использован официальный архив
[clang+llvm-22.1.5-x86_64-pc-windows-msvc.tar.xz](https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.5/clang%2Bllvm-22.1.5-x86_64-pc-windows-msvc.tar.xz).
Размер: 861959516 байт. SHA256, сверенный с digest release asset:
`52c15696665ec3010e100261cb2919d40712dbf871c9a2886a2e60b665bcd2c6`.

Распаковать содержимое верхней папки архива в `C:/src/libclang`:
там должны лежать `bin/clang.exe`, `include/clang-c/Index.h`,
`lib/libclang.lib` и CMake configs. Не добавлять SDK в Git.

## Сборка

Из x64 Native Tools Command Prompt Visual Studio, в корне проекта:

```bat
cmake -S . -B build/ninja -DDAS_CLANG_BIND_DISABLED=OFF -DPATH_TO_LIBCLANG=C:/src/libclang
cmake --build build/ninja --target daslang dasModuleClangBind daslang_static dasSDL3_runner --parallel 6
```

Команды используют уже настроенную Ninja-сборку проекта. Для чистой сборки
сначала выполнить настройку из README, затем включить параметры выше.
Цель dasModuleClangBind копирует необходимые LLVM DLL в bin daScript.
Не заменять DASSDL3_CLANG_EXECUTABLE: сохранённые API snapshots и production
generator проверяются прежним Clang 16.0.5. SDK 22.1.5 используется libclang-модулем.

## Проверки

```powershell
./third_party/daScript/bin/daslang.exe tools/clangbind_probe.das -- test-app/build/_deps/sdl3-src/include C:/src/libclang
ctest --test-dir build/ninja -R "^(sdl3_|bindings_up_to_date)" --output-on-failure
```

В первой команде передать фактическую папку SDL include. CTest автоматически
берёт её из CMake. Два дополнительных теста регистрируются на Windows, когда
есть цели daslang/dasModuleClangBind и PATH_TO_LIBCLANG.

- `sdl3_clangbind_probe`: загрузка libclang 22.1.5, разбор SDL.h как C11 для
  x86_64-pc-windows-msvc, проверка diagnostics, SDL_FRect sizeof=16,
  SDL_PIXELFORMAT_RGBA8888, полноты GPU pipeline struct, callback function
  prototype и SDL_GUID.data[16]. Результат: 1212 функций, все проверки true,
  errors=0. Это не ABI-проверка скомпилированных bindings.
- `sdl3_clangbind_preprocessor`: upstream-тест CppGenBind на выбор активной
  ветки #else при генерации констант. Результат PASS.
- Все 13 прежних CTest-сценариев прошли непосредственно в build/ninja.

1212 функций из SDL.h не сравнивать с 1226 в census: census дополнительно
включает main, Vulkan, Metal и revision headers, использует другой Clang.
Проверка не утверждает полного покрытия API или поддержки иных платформ.

## После установки

CppGenBind уже выбран production backend Windows x64. Следующие команды —
[обновление snapshots](clangbind-production.md), [parity](clangbind-parity.md)
и [AOT](clangbind-types-aot.md). Проверки других платформ
остаются отдельной работой.

Не запускайте consumer configure одновременно с генерацией: shared modules и
конфигурация daScript общие для разных -B каталогов. После consumer восстановите
developer-конфигурацию и dasModuleClangBind перед preflight/freshness gates.
