# Geometry: проверяемые массивы вершин и индексов

Профиль: SDL 3.2.18, Windows x64/MSVC, закреплённый daScript.
`require dassdl3/sdl3_geometry_boost` переэкспортирует базовый boost.
Raw SDL_RenderGeometry также доступен; проверки ниже относятся к helpers.

```das
var vertices : array<SDL_Vertex>
vertices |> resize(3)
vertices[0] = vertex(float2(100.0, 20.0), float4(1.0, 0.0, 0.0, 1.0))
vertices[1] = vertex(float2(180.0, 160.0), float4(0.0, 1.0, 0.0, 1.0))
vertices[2] = vertex(float2(20.0, 160.0), float4(0.0, 0.0, 1.0, 1.0))
renderer |> draw_geometry(vertices)
let indices <- array<int>(0, 1, 2)
renderer |> draw_geometry(vertices, indices)
```

Для текстуры передайте последним аргументом SDL_Texture? и задайте UV третьим
аргументом `vertex(position, rgba, uv)`. Отсутствие текстуры означает null.
Позиции — пиксельные float2; RGBA — float4 в 0..1 (в отличие от uint4 0..255
для clear/set_color); UV — float2 в 0..1, по умолчанию (0, 0).
Color/alpha берутся из вершин; SDL texture color/alpha modulation игнорируется
этим SDL API. Helpers не меняют blend mode, viewport или render target.

## ABI и копии

Генерируются SDL_FPoint (x/y), SDL_FColor (r/g/b/a), SDL_Vertex
(position/color/tex_coord). Это три managed POD-аннотации; вложенные поля
доступны напрямую. CppGenBind проверяет sizeof/alignof/offsetof, а parity
сравнивает метаданные с прежним backend. SDL_Vertex передаётся как настоящий
массив SDL_Vertex, без reinterpret float-vector layouts или выдуманного stride.
`vertex` возвращает полностью инициализированную структуру через native factory.

Массивы принадлежат скрипту, адреса заимствуются только на время вызова SDL.
SDL формирует свою очередь команд; пользовательские указатели адаптер не
сохраняет. Массивы разрешено изменять/освобождать после возврата. Текстура
должна принадлежать renderer и оставаться живой по контракту SDL; stale handles
и raw уничтожение ресурсов не защищены системой уникального владения.
Вызовы выполняются в основном потоке.

## Проверки до SDL

Адаптеры в `src/sdl3_geometry.h` проверяют:

- Ненулевой renderer, в том числе для пустой команды.
- Счётчики до преобразования uint32 → int: предел INT_MAX/sizeof(SDL_Vertex)
  и для вершин, и для индексов, включая размер концептуально развёрнутых вершин.
  Это ограничение нашего API, не гарантия успешной аллокации внутри SDL/драйвера.
- Без индексов количество вершин кратно трём. С индексами кратно трём
  количество индексов; количество вершин может быть любым.
- Каждый индекс неотрицателен и меньше числа вершин; непустая команда требует
  реального хранилища. Все проверки выполняются до передачи указателей SDL.
- Все позиции конечны, все цвета и UV конечны и находятся в 0..1, включая
  непосредственно изменённые и неиспользуемые вершины непустой команды.
  HDR-цвета и UV wrapping в этом helper пока намеренно не представлены.

Пустой последовательный массив — no-op. Пустой индексированный массив —
no-op даже при непустых вершинах; он не переключается на sequential draw.
Для no-op содержимое вершин и текстура не проверяются, счётчики проверяются.
Повторные индексы и вырожденные треугольники разрешены. Отказ native adapter
возвращает false + SDL_GetError, boost превращает его в panic. После локального
recover renderer можно продолжать использовать. Ошибки от самого SDL также
передаются вызывающему коду.

## Пример и тесты

`examples/07_geometry.das`: анимированный цветной треугольник и индексированный
текстурированный прямоугольник, собственный checker.bmp. Сценарий адаптирован
из public-domain `SDL release-3.2.18/examples/renderer/10-geometry/geometry.c`;
callback loop заменён PollEvent и ресурсными scopes. Пример без unsafe;
`--smoke-test` выполняет 60 кадров в скрытом окне.

Исходный C-пример тоже собран с той же локальной SDL static library и выполнен
60 кадров. Проверочный wrapper скрывает окно и отправляет Quit после 60 present;
вместо upstream sample.bmp использован собственный checker.bmp. Исходники
сабмодуля и SDL не изменялись.

`tests/geometry.das` проверяет точные пиксели плоского треугольника,
побайтовое совпадение indexed/sequential quad, textured draw, сохранность
команды после изменения массивов, пустые команды, неверные индексы/счётчики,
неполные треугольники, цвет/UV вне диапазона, NaN/Infinity, неизменность target
после отклонённой команды и продолжение после panic с исходным сообщением.
Test-only `geometry_probe.h` передаёт переполненные счётчики с пустыми указателями
в настоящий адаптер: отказ происходит до чтения памяти, без огромной аллокации.
Тестовые exports отсутствуют в BUILD_TESTING=OFF.

Эти же сценарий и пример включены в strict AOT; сам geometry boost также
компилируется в AOT. Это SDL renderer geometry, ещё не SDL GPU pipeline.

Проверено 2026-09-19: 20/20 основных CTest и 48/48 parity/AOT-проверок.
Geometry-пример дополнительно выполнил 60 кадров в consumer с BUILD_TESTING=OFF,
отключёнными генераторами и LLVM/ClangBind. Поиск Clang, LLVM и Python3 также
отключён; использованы сохранённые привязки. C++ ABI assertions и проверка
свежести генерации проходят. Теперь в allowlist 53 функции, 10 записей,
49 полей, 6 opaque-типов и 42 константы. Другие ОС и GPU API не проверялись.

Следующий этап: GPU ClearScreen → BasicTriangle с готовыми shader binaries,
с отдельными контрактами command buffers, swapchain и pipeline lifetime.

Справка: [SDL_RenderGeometry](https://wiki.libsdl.org/SDL3/SDL_RenderGeometry).
Версии и ограничение UV сверены с закреплёнными заголовками/реализацией 3.2.18.
