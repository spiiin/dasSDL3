# CppGenBind: проверенная выборка и AOT

19 сентября 2026. SDL 3.2.18, daScript commit
`35bf260c0d8a79b94c64005bd3d2435adcf7e261`, libclang 22.1.5,
Windows x64, MSVC 19.38, Release /MD.

Эксперимент подтвердил генерацию, компиляцию и исполнение небольшой выборки.
Это сохраняемый минимальный compiler/ABI regression, не текущий план миграции.
Production уже использует CppGenBind на Windows x64; полная действующая parity
проверка описана в clangbind-parity.md. Другие платформы не сертифицированы.

## Состав

`tools/clangbind_generate.das` — подкласс CppGenBind с явной выборкой.
Генерируются 20 файлов, три функции (SDL_GetRectIntersectionFloat,
SDL_PointInRect, SDL_GetPixelFormatName), девять структур (Point/FPoint,
Rect/FRect, GUID, GPUViewport, GPUVertexBufferDescription, GPUVertexAttribute,
GPUVertexInputState) и три enum (PixelFormat, GPUVertexInputRate,
GPUVertexElementFormat). SDL_PointInRect проверяет также static inline путь.

Отдельный модуль называется `sdl3_probe`; он не регистрируется вместе с
production `sdl3`. Generated C++ находится только в каталоге экспериментальной
сборки. Код генератора и тестового consumer хранится в tools и tests/clangbind.
Текущие src/generated, Python production backend и публичные boost API сохранены.

`tools/run_clangbind_generation.py` запускает das-генератор в двух чистых
временных папках, побайтово сравнивает все outputs и проверяет наличие выбранных
функций/структур. Только затем копирует результат в выходную папку. Это orchestration
и validation, не второй backend генерации C++. Ошибки libclang в логе считаются
ошибками даже при нулевом exit code CppGenBind; отсутствующий SDK отвергается.
Ошибка открытия output-файла завершает das-генератор вместо вывода C++ в stdout.

## Результаты

- Две генерации дали одинаковые 20 файлов, включая comments с путями.
- Сгенерированный C++ собран без ручных правок и без изменений daScript.
- Interpreter consumer: `main AOT=no`, smoke PASS.
- AOT consumer: `main AOT=yes`, smoke PASS, `fail_on_no_aot=true`.
- Consumer без скомпилированных AOT stubs получает именно
  `AOT link failed on main`. Негативный тест проверяет сообщение и код возврата,
  поэтому случайная ошибка загрузки DLL не считается успехом.
- Ошибочные SDK path и заголовок с #error отвергаются до публикации output.
- Все четыре CTest-сценария отдельной экспериментальной сборки прошли.

Smoke проверяет значения пересечения прямоугольников, inline point-in-rect,
значение RGBA8888 и имя формата, запись/чтение GPU viewport, крайние элементы
GUID.data[16], GPU enum и чтение descriptor через pointer+count.
Native static_assert проверяют sizeof/alignof/offsetof выбранных POD, GUID и
GPU vertex input state. Это ограниченные Windows x64 assertions, не полный
ABI-аудит библиотеки. GPU устройство и настоящий pipeline здесь не создаются.

## Обнаруженные нюансы

1. Для этой версии SDL и Clang 22 разбор SDL.h как C++ столкнулся с
   определением builtin `_m_prefetch` в SDL_endian.h. Использован корректный
   для SDL C API режим C11; системные guards не отключались.
2. В C11 canonical spelling содержит `const struct SDL_FRect`. Фильтр
   выбранных структур нормализует `const` и `struct`, иначе функции с такими
   аргументами пропускаются.
3. C11 `_Bool` в сигнатуре надо вывести как C++ `bool`. Исправлено hook
   functionPtrSpelling, generated файлы не редактируются. Замена применима
   только к текущей ограниченной выборке; перед масштабированием нужен аудит
   остальных spelling/typedef/default-argument путей.
4. Для GPU enum нужны явные enum_prefix, иначе имена элементов остаются с
   полным SDL_GPU_ префиксом. Это выбор нового модуля, не переименование
   существующего публичного API.
5. AOT include должен предоставлять bind_enum.h до generated enum declarations.
   Это делает отдельный probe_aot.h из native glue.
6. Присвоение pointer-to-const поля GPUVertexInputState напрямую из script
   отвергается текущей generated annotation. В тесте native fixture
   probe_set_vertex_buffer заполняет поле; script читает данные через него.
   Descriptor живёт дольше input. Fixture не является безопасным публичным
   builder и не обещает lifetime-контроль. Для production нужен scoped builder
   с массивами и явным временем заимствования, а не снятие const-проверок.

## Повторный запуск

Сначала собрать SDK/daScript по [clangbind-setup.md](clangbind-setup.md).
Из x64 Native Tools Command Prompt Visual Studio, в корне репозитория:

```bat
cmake -S tests/clangbind -B build/clangbind-experiment -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_SDK=C:/src/libclang -DSDL_INCLUDE=C:/src/dasSDL3/test-app/build/_deps/sdl3-src/include
cmake --build build/clangbind-experiment --parallel 6
ctest --test-dir build/clangbind-experiment --output-on-failure
```

SDL_INCLUDE указывает каталог с SDL3/SDL.h. MAIN_BUILD по умолчанию build/ninja
основного проекта; оттуда используется SDL3-static.lib. Его можно переопределить
через `-DMAIN_BUILD=...`. Путь `-B` может быть за пределами репозитория.
Проверенный запуск использовал доступную для записи рабочую папку Codex,
поскольку shell не смог создать новый каталог под C:/src/dasSDL3/build.

CMake сначала генерирует native модуль, затем через него вызывает daslang -aot,
компилирует emitted C++ в consumer и запускает interpreter/AOT/negative tests.
Вспомогательные runtime DLL копируются к consumer; global PATH не меняется.
Эксперимент рассчитан на Ninja Release Windows x64, не на все конфигурации MSVC.

## Применение

Сохранять минимальный interpreter/AOT/missing-AOT regression при обновлении
compiler SDK. Расширение production API идёт через общую policy и полный
[parity-проект](clangbind-parity.md), не через увеличение этой маленькой выборки.
