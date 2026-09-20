# Идиомы dasBGFX для будущего слоя sdl3_boost

Повторный аудит 19 сентября 2026: `binding-design-review.md` дополняет этот
обзор проверкой Result/Option, variants, поведения finalize в контейнерах,
dasVulkan, dasSpirv и Rust sdl3. План применения shader-идиом — `gpu-roadmap.md`.

Исследованы локальные исходники dasBGFX, коммит
`a569838d35a2a584946e784d5e013fb2f08ec4c1`, включая examples/01–08,
hello_bgfx.das, readback.das и модули bgfx_boost, bgfx_boost_internal,
bgfx_gen, bgfx_ttf. Механизмы safe_addr и defer дополнительно сверены
с daScript `35bf260c0d8a79b94c64005bd3d2435adcf7e261`.

Это обзор исходников, а не результат запуска примеров dasBGFX.
Предложения для SDL3 ниже ещё не реализованы и отделены от наблюдений.

**Результат последующего внедрения:** слой SDL3 уже реализован; его актуальное
описание — в `sdl3-boost.md`. На закреплённом daScript тест показал, что panic
пропускает defer/finally, хотя обычный и ранний return выполняют defer.
Поэтому для ресурсов используем блоки with_sdl/with_window/with_renderer
с нативной защитой вызова, очисткой и повторной передачей ошибки.
Ранее использовавшийся внешний script try/recover удалён по запросу пользователя;
см. native-scopes.md: одна нативная граница на ресурсный блок.
safe_addr также отвергает ссылочные аргументы обёрток как "not a local value";
для трёх синхронных вызовов выбраны нативные адаптеры по ссылке.
Рекомендации ниже сохраняют контекст первоначального исследования.

## 1. Нативная привязка + публичный boost-модуль

В примерах достаточно `require dasbgfx/bgfx_boost`.
Сам bgfx_boost объявляет `module bgfx_boost shared public` и
`require bgfx public`: низкоуровневый API переэкспортирован рядом
с удобными функциями. Макросы вынесены в bgfx_boost_internal,
геометрия и шрифты — в отдельные модули.

Для SDL3: сохранить `require sdl3` и добавить
`require dassdl3/sdl3_boost`. Это слой удобства; само наличие boost-модуля
не запрещает пользователю обращаться к низкоуровневым функциям.

[Источник: bgfx_boost.das](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L6)

## 2. safe_addr для синхронных вызовов C API

Пример непосредственно из triangle:

```das
var pd : bgfx_platform_data_s
pd.nwh = glfwGetNativeWindow(window)
bgfx_set_platform_data(safe_addr(pd))
```

Аналогично передаются layout и выходные параметры размеров окна.
В текущем daScript safe_addr проверяет допустимость адресуемого выражения
и возвращает временный указатель с квалификатором `#`. Внутри реализации
есть unsafe, но вызывающему коду писать его не нужно.

Для SDL3 это кандидат на `SDL_PollEvent(safe_addr(event))` и
`SDL_RenderFillRect(renderer, safe_addr(rect))`. До внедрения нужно проверить
совместимость временных указателей с нашими нативными сигнатурами.
Макрос не заставляет C-библиотеку соблюдать время жизни: он подходит здесь
именно потому, что эти функции не сохраняют переданный указатель.

[Пример](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/examples/01_hello_triangle.das#L54),
[реализация safe_addr](https://github.com/GaijinEntertainment/daScript/blob/35bf260c0d8a79b94c64005bd3d2435adcf7e261/daslib/safe_addr.das)

## 3. defer сразу после успешного получения ресурса

В примерах после glfwInit ставится `defer` с glfwTerminate,
а после создания окна — второй `defer` с glfwDestroyWindow:

```das
defer <| $() {
    glfwDestroyWindow(window)
}
```

В текущем daScript макрос переносит блок в finally текущей области;
несколько defer выполняются в обратном порядке регистрации.
В SDL3 это позволяет записать освобождение рядом с созданием ресурса
и получить порядок renderer → window → SDL_Quit.

Ограничение образца: в рассмотренных графических примерах bgfx_shutdown
обычно вызывается в конце main явно. Не следует считать, что там уже
реализовано полное автоматическое освобождение всех GPU-ресурсов.

[Пример](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/examples/01_hello_triangle.das#L39),
[реализация defer](https://github.com/GaijinEntertainment/daScript/blob/35bf260c0d8a79b94c64005bd3d2435adcf7e261/daslib/defer.das)

## 4. Перегрузки принимают значения и контейнеры вместо pointer + size

bgfx_copy и bgfx_make_ref перегружены для динамических и фиксированных
массивов. Размер в байтах вычисляется внутри через length и typeinfo sizeof.
bgfx_any_uniform принимает float4, матрицы и их массивы, скрывая addr,
число элементов, поиск uniform и особенности транспонирования.

Для SDL3: обёртки `poll_event(var event)` и `fill_rect(renderer, rect)`
могут принимать ссылки/значения, оставляя адресацию внутри слоя.
Цвет удобно передавать отдельной структурой или вектором с явно выбранным
диапазоном компонентов.

Не копировать без проверки: bgfx_make_ref не копирует данные и не владеет
ими; обёртка не продлевает жизнь массива. В этих перегрузках используется
arr[0] без проверки пустого массива. Для новых SDL-обёрток необходимо
отдельно определять поведение пустых буферов и сохранения указателей.

[Контейнерные перегрузки](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L339),
[типизированные uniforms](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L105)

## 5. Настройка C-структур спрятана за функцией с разумными defaults

`bgfx_init(winw, winh, rt = COUNT, dbgfx = false)` создаёт и настраивает
bgfx_init_s, устанавливает разрешение/VSYNC и вызывает нативную перегрузку.
Пользователь не заполняет служебную структуру вручную.

Для SDL3: создание окна и renderer с общими defaults; необязательные
параметры остаются доступны. В отличие от этого конкретного bgfx_init,
новая обёртка должна обязательно проверять возвращаемый результат SDL.

[Источник](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L397)

## 6. Проверка ошибок внутри высокоуровневых операций

Создание шейдерной программы проверяет invalid handle и вызывает panic.
Загрузка изображения поддерживает canfail: либо возвращает invalid handle,
либо сообщает ошибку. Поиск uniform проверяет совместимость типа и размера.

Для SDL3 стоит выбрать последовательную политику: простые checked-функции
с сообщением из SDL_GetError и, при необходимости, отдельно обозначенные
try-функции. Cleanup при раннем return и panic нужно проверять тестами.
Следовать форме примера не означает гарантировать его поведение для всех
способов выхода без проверки на нашей версии daScript.

[Создание программы](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L179),
[загрузка изображения](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L367)

## 7. Pipe-синтаксис и перемещение составных результатов

В generated geometry:

```das
var sphere <- gen_sphere(32, 16, false) |> bgfx_create_geometry_fragment
```

В TTF:

```das
font |> bgfx_draw_quads(0u, hw_text, mvp)
```

Операция с объектом принимает его первым аргументом, что удобно для `|>`.
`<-` выражает перемещение значения. Внутри bgfx_gen встречаются
`return <- fragment`, `with (fragment)` и `finalize(var frag)` для пары
vertex/index buffers.

Для SDL3 уместны функции с renderer первым аргументом. Но перемещение
само по себе не делает ресурс уникальным: нужна отдельная политика копирования
и владения. В examples/07 переменные sphere/cube/cylinder не объявлены
inscope, поэтому этот файл не доказывает автоматический вызов finalize
на обычном выходе из области. Связку владельца ресурса с inscope следует
рассматривать как отдельное улучшение и тестировать.

[Пример](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/examples/07_hello_gen.das#L69),
[структура и finalize](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_gen.das#L20)

## 8. Блоки для ограниченного времени жизни ресурса

В загрузчике шейдеров используются вложенные `fopen(...) <| $(f) {...}`
и `fmap(f) <| $(data) {...}`. Работа с файлом и отображённой памятью
сосредоточена в переданном блоке; наружу возвращается уже готовый shader handle.

Для SDL3 подобный интерфейс with_window/with_renderer можно рассмотреть
позже, если нужен более строгий контроль области жизни. Это предложение:
сам dasBGFX не содержит таких обёрток для создания окна.

[Источник](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L318)

## 9. Аннотации и макросы генерируют повторяющийся код

`[bgfx_vertex_buffer]` на структуре позволяет получить vertex layout
через `bgfx_create_vertex_layout(type<Vertex>)`. Макрос обходит поля,
определяет семантику/формат и генерирует последовательность вызовов C API.

`[bgfx_vertex_program]`, `[bgfx_fragment_program]`, @uniform и
`bgfx_create_shader_program(@@vs_main, @@fs_main)` образуют shader DSL.
Внутренние макросы заменяют удобный вызов на вызов с сгенерированными данными.

Для текущего 2D-примера SDL3 такой механизм не требуется. Он может стать
полезен позже для описаний вершин или обработчиков событий, если обычных
типизированных функций будет недостаточно.

[Пользовательский код](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/examples/01_hello_triangle.das#L13),
[макросы](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost_internal.das#L61)

## 10. Операторы преобразования и адаптеры библиотек

Перегрузки clone в bgfx_boost позволяют писать `f_tex := texture`,
преобразуя texture handle в sampler2D. BGFXTTFApiAdapter реализует
общий интерфейс TTF через функции создания/удаления текстур BGFX;
unsafe-копирование пикселей остаётся в адаптере.

Для SDL3 эти приёмы полезны для будущих текстур и шрифтов. Нельзя переносить
clone на владеющую обёртку окна как простое копирование сырого указателя:
так появится риск двойного освобождения.

[clone](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_boost.das#L165),
[TTF-адаптер](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/dasbgfx/bgfx_ttf.das#L38)

## Дополнение: неявный последний блок в gen2

Это предложенное пользователем улучшение синтаксиса, проверенное в dasSDL3,
а не цитата из рассмотренных примеров dasBGFX. Последний аргумент-блок
можно передавать без `<|`. Если у блока нет параметров, не нужен и `$()`:

```das
with_sdl() {
    with_window("Hello", 800, 600, SDL_WINDOW_RESIZABLE) $(window) {
        window |> with_renderer() $(renderer) {
            renderer |> clear()
            renderer |> present()
        }
    }
}
```

Использовать этот стиль в новых примерах и обёртках. Для блока с параметрами
сохраняется `$(...)`; pipe `|>` совместим с этой формой. Изменяется только
синтаксис вызова, а не время жизни ресурсов или обработка ошибок.
Проверено на закреплённой версии daScript тестами `sdl3_example` и `sdl3_boost`.
Исторические фрагменты dasBGFX выше сохранены в исходном синтаксисе.

## Что перенести в первую очередь

1. Публичный sdl3_boost поверх существующего sdl3.
2. Проверяемые обёртки с аргументами по ссылке/значению; safe_addr внутри
   тех обёрток, где указатель нужен только на время вызова.
3. defer для окна, renderer и SDL_Quit, регистрируемый после успешного создания.
4. Renderer первым аргументом для удобного pipe-синтаксиса.
5. Проверки, что пример компилируется без unsafe, а ранний выход/ошибка
   освобождают ресурсы в правильном порядке.

Не переносить старые ослабления проверки указателей из bgfx_boost_internal
(`strict_smart_pointers = false`, `relaxed_pointer_const = true`).
Не представлять отсутствие слова unsafe как доказательство полной
безопасности: в compute/readback примерах оно остаётся явно, а часть
высокоуровневых обёрток скрывает обязанности вызывающего по времени жизни.

[Оставшийся unsafe в compute-примере](https://github.com/borisbat/dasBGFX/blob/a569838d35a2a584946e784d5e013fb2f08ec4c1/examples/05_hello_compute.das#L97)
