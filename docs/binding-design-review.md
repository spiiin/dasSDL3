# Аудит идиом и выбор генератора

Исследование 19 сентября; решения актуализированы 20 сентября 2026.
Result/Option и variants ниже — возможные приёмы, не новый обязательный API.
Предыдущие проверенные решения сохранены в `bgfx-idioms.md`, `sdl3-boost.md`,
`input.md`, `audio.md`. Общий план — `full-binding-roadmap.md`.

## Что исследовано

- Наши `tools/bindings.json`, `generate_bindings.py`, `src/module_sdl3.cpp`,
  scope/input/audio adapters, boost и таблица покрытия.
- daScript commit `35bf260c0d8a79b94c64005bd3d2435adcf7e261`:
  `daslib/result.das`, `option.das`, `safe_addr.das`,
  `shader_lingua_franca.das`, `shader_block_layout.das`;
  `tests/option`, `tests/bare_block`, `third_party/daScript/tests/language/variants.das`,
  `container_finalize.das`, `inscope_return_inscope.das`, `tests/spirv`;
  `modules/dasClangBind`, `dasVulkan`, `dasSpirv`, `dasGlsl`.
- [dasBGFX](https://github.com/borisbat/dasBGFX/tree/a569838d35a2a584946e784d5e013fb2f08ec4c1):
  примеры 01–08, readback; boost, внутренние shader macros, генерация привязки.
- [Rust sdl3 0.20.0](https://docs.rs/sdl3/0.20.0/sdl3/), исходники crate;
  `.cargo_vcs_info.json` указывает commit `0ffa35e5f6d68b3bcc56bb724af0ad5e538af6f4`.

Это аудит исходников, не утверждение о прохождении чужих test suites.
Дополнительно локально выполнена небольшая проверка стандартных `ok/err/map`
и `some/none` на собранном daslang_static: прошла. GPU compiler, dasClangBind
и все upstream language tests в рамках исследования не собирались/не запускались.

## Идиомы daScript

| Идиома и свидетельство | Применение в dasSDL3 | Ограничение / обязательная проверка |
| --- | --- | --- |
| Trailing block, `third_party/daScript/tests/bare_block/test_assumed_pipe.das` и `test_piped_default_padding.das` | `with_sdl() { ... }`, `with_window(...) $(window) { ... }`, receiver-first pipes | Сохранять этот уже принятый синтаксис; `$()` не нужен лишь блоку без аргументов |
| `daslib/result.das`, `tests/option/test_result*.das` | Возможный отдельный application layer; текущий boost сохраняет SDL results | Фабрики ok/err копируют; move_ok/move_err для movable values. Не копировать owning handle случайно |
| `daslib/option.das`, non-copyable tests | Нет события/устройства, minimized swapchain — штатный empty result | Текущий SDL contract различает результат операции и nullable output |
| Tagged variants, `third_party/daScript/tests/language/variants.das` | Высокоуровневое событие с key/mouse/text/drop payload и unknown fallback | Данные должны принадлежать событию; union и временные `char*` нельзя просто клонировать |
| `var inscope`, finalize, move; `inscope_return_inscope.das` | Рассмотреть ресурсные wrappers и композицию owners | Panic пропускает defer/finally; применять defer для обычных/ранних выходов, без catch-моста |
| `third_party/daScript/tests/language/container_finalize.das` | Явное освобождение owning элементов при удалении/очистке коллекций | Пользовательский finalize не вызывается автоматически erase/clear/shrink/pop по исследованному контракту; array<Handle> сам по себе не RAII |
| `safe_addr` и временные pointer types | Синхронные native ref adapters вместо адресов в пользовательском коде | safe_addr не доказывает lifetime, если C сохраняет pointer; scalar outputs требуют `T&` |
| Generic array adapters | geometry, аудио, IO, GPU buffers | Только разрешённые POD/форматы; пустой array, размер, stride, lifetime и copy/borrow проверять |
| Type annotations/macros | Vertex declaration, shader bindings, checked builders | Генерировать metadata и диагностику, не отключать strict type/pointer checks |

Для raw SDL flags сохранять точные биты и ширину, включая неизвестные будущие
значения. В boost можно дать named flags, defaults и builders. Не превращать
каждый bitmask в закрытый enum, теряющий комбинирование или uint64.

### Дополнительный образец: dasVulkan

В закреплённом daScript есть raw/boost-разделение в
`modules/dasVulkan/README.md` и `daslib/vulkan_boost.das`: owner wrappers,
array-поля вместо count+pointer и builders. Это полезнее для SDL GPU create-info,
чем перенос одного BGFX handle API. Но Vulkan генерируется из vk.xml, которого
для SDL нет; заимствуем архитектуру и тестовые сценарии, а не сам registry parser.
Проверки пустых массивов, lifetime и cleanup нельзя считать гарантированными
только потому, что похожий код присутствует в другом модуле.

## Повторный разбор dasBGFX

| Источник | Полезный приём | Что менять для SDL |
| --- | --- | --- |
| `01_hello_triangle.das` | Шейдеры из annotated functions; vertex layout из структуры; uniform binding | SDL pipeline и resource slots; строгий std140 packer вместо предположения о host layout |
| `02_hello_image.das`, `03_hello_cube.das` | Asset helper, texture/sampler, матрицы и depth | SDL_image отдельный модуль; lifetime shader/pipeline/device и конвенции координат проверить |
| `04_hello_render_to_texture.das` | Render-to-texture как отдельный сценарий | Attachment load/store, resize, format compatibility и resource cycling |
| `05_hello_compute.das`, `readback.das` | Compute annotations и явное ожидание результата GPU | SDL fences и transfer buffers; frame-id BGFX не переносить как фиксированную задержку кадров |
| `06_hello_ttf.das` | Текстовый сервис поверх renderer | Выбрать SDL_ttf text engine; текущий BGFX backend не является SDL_ttf binding |
| `07_hello_gen.das` | Типизированное построение геометрии и перенос данных | Проверить ownership коллекций; не полагаться на пользовательский finalize при erase |
| `08_hello_imgui.das` | UI отдельным модулем, события и renderer adapter | Переиспользовать daScript imgui, заменить platform/renderer backend на SDL3 |
| `bgfx_boost_internal.das` | AST-преобразования и metadata из аннотаций | Сохранить diagnostics; старые ослабления строгих проверок не копировать |
| `bgfx_boost.das` copy/make_ref | Array-oriented API вместо void* | `arr[0]` при пустом массиве и удержание памяти требуют собственного исправленного контракта |

Итого: переносить приёмы композиции, метаданных и маленьких законченных
примеров. Наличие defer, unsafe или make_ref в upstream-примере не является
доказательством безопасности на нашем interpreter. Нативный scope bridge удалён;
актуальный контракт — [error-handling.md](error-handling.md).

## Что взять из Rust sdl3

У Rust полезны separation sys/high-level, scoped locks, typed data,
конструкторы с defaults, Result/Option и выраженные связи родителей/детей.
[TextureCreator](https://docs.rs/sdl3/0.20.0/sdl3/render/struct.TextureCreator.html)
ограничивает жизнь текстуры и связь с renderer. В daScript документируем
borrowed lifetime и defer; новые owner registries ради имитации Rust не добавляем.

Аудит [GPU pass.rs](https://github.com/vhspace/sdl3-rs/blob/0ffa35e5f6d68b3bcc56bb724af0ad5e538af6f4/src/sdl3/gpu/pass.rs):
nullable успешный swapchain acquisition оформлен как Option, submit потребляет
wrapper. Эти идеи подходят. Но cancel принимает mutable reference, а generic
uniform upload использует размер T: наш слой должен отдельно инвалидировать
handle, проверять результат отмены и упаковывать layout. Не копировать эти
реализации как готовое доказательство корректности.

В [render.rs](https://github.com/vhspace/sdl3-rs/blob/0ffa35e5f6d68b3bcc56bb724af0ad5e538af6f4/src/sdl3/render.rs)
lock даёт callback с slice/pitch; это хорошая форма API. В просмотренном пути
unlock стоит после callback, поэтому устойчивость к unwind не следует из самой
формы closure. В нашей обвязке cleanup после произвольного panic не обещается.

[IOStream](https://github.com/vhspace/sdl3-rs/blob/0ffa35e5f6d68b3bcc56bb724af0ad5e538af6f4/src/sdl3/iostream.rs)
привязывает memory stream к заимствованным bytes. Для первого das API проще
копировать память в owner либо удерживать специальный buffer object до close.
Режим borrow без копии предоставлять только с доказанным сроком жизни.

## Решение о генераторе

CppGenBind/libclang 22.1.5 — production backend MSVC Windows x64. Python/Clang
остаётся baseline/fallback; оба используют один отбор tools/bindings.json.
Сохранённые snapshots позволяют сборку без LLVM. Нынешнее покрытие и проверки:
[api-coverage](api-coverage.md), [production](clangbind-production.md),
[parity/AOT](clangbind-types-aot.md).

При расширении: точный selected field set, enum/flags widths, qualifiers,
calling convention, deterministic output, ABI assertions, отрицательные tests
и реальные interpreter/AOT вызовы. SDL ownership/thread/allocator policy всё
равно ручная. Не заменять генерацию массовыми ручными регистрациями и не
регистрировать один raw export двумя backend одновременно.

Дальнейший выбор fallback зависит от проверок других платформ; автоматическое
удаление Python backend сейчас не запланировано. Callback typedef и raw pointer
сами по себе не разрешают сохранять или вызывать script closure через C ABI.
