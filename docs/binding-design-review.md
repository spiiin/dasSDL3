# Аудит идиом и выбор генератора

19 сентября 2026. Предложения ниже ещё не являются новым публичным API.
Предыдущие проверенные решения сохранены в `bgfx-idioms.md`, `sdl3-boost.md`,
`input.md`, `audio.md`. Общий план — `full-binding-roadmap.md`.

## Что исследовано

- Наши `tools/bindings.json`, `generate_bindings.py`, `src/module_sdl3.cpp`,
  scope/input/audio adapters, boost и таблица покрытия.
- daScript commit `35bf260c0d8a79b94c64005bd3d2435adcf7e261`:
  `daslib/result.das`, `option.das`, `safe_addr.das`,
  `shader_lingua_franca.das`, `shader_block_layout.das`;
  `tests/option`, `tests/bare_block`, `tests/language/variants.das`,
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
| Trailing block, `tests/bare_block/test_assumed_pipe.das` и `test_piped_default_padding.das` | `with_sdl() { ... }`, `with_window(...) $(window) { ... }`, receiver-first pipes | Сохранять этот уже принятый синтаксис; `$()` не нужен лишь блоку без аргументов |
| `daslib/result.das`, `tests/option/test_result*.das` | `try_*` возвращает стандартный Result с собственной копией SDL error; map/and_then | Фабрики ok/err копируют; move_ok/move_err для movable values. Не копировать owning handle случайно |
| `daslib/option.das`, non-copyable tests | Нет события/устройства, minimized swapchain — штатный empty result | Отсутствие и SDL error различать; для fallible lookup может понадобиться Result с Option внутри |
| Tagged variants, `tests/language/variants.das` | Высокоуровневое событие с key/mouse/text/drop payload и unknown fallback | Данные должны принадлежать событию; union и временные `char*` нельзя просто клонировать |
| `var inscope`, finalize, move; `inscope_return_inscope.das` | Рассмотреть ресурсные wrappers и композицию owners | У нас panic пропускает defer/finally: существующие catch-cleanup-rethrow scopes сохранять |
| `tests/language/container_finalize.das` | Явное освобождение owning элементов при удалении/очистке коллекций | Пользовательский finalize не вызывается автоматически erase/clear/shrink/pop по исследованному контракту; array<Handle> сам по себе не RAII |
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
доказательством безопасности на нашем interpreter. Подтверждённый workaround
в `sdl3_scopes.h` для восстановления block arguments после panic сохраняется.

## Что взять из Rust sdl3

У Rust полезны separation sys/high-level, scoped locks, typed data,
конструкторы с defaults, Result/Option и выраженные связи родителей/детей.
[TextureCreator](https://docs.rs/sdl3/0.20.0/sdl3/render/struct.TextureCreator.html)
ограничивает жизнь текстуры и связь с renderer. В daScript предлагается
проверяемый owner token с invalidation; это runtime-контроль, не Rust borrow checker.

Аудит [GPU pass.rs](https://github.com/vhspace/sdl3-rs/blob/0ffa35e5f6d68b3bcc56bb724af0ad5e538af6f4/src/sdl3/gpu/pass.rs):
nullable успешный swapchain acquisition оформлен как Option, submit потребляет
wrapper. Эти идеи подходят. Но cancel принимает mutable reference, а generic
uniform upload использует размер T: наш слой должен отдельно инвалидировать
handle, проверять результат отмены и упаковывать layout. Не копировать эти
реализации как готовое доказательство корректности.

В [render.rs](https://github.com/vhspace/sdl3-rs/blob/0ffa35e5f6d68b3bcc56bb724af0ad5e538af6f4/src/sdl3/render.rs)
lock даёт callback с slice/pitch; это хорошая форма API. В просмотренном пути
unlock стоит после callback, поэтому устойчивость к unwind не следует из самой
формы closure. Для нашего panic нужен уже проверенный механизм scope cleanup.

[IOStream](https://github.com/vhspace/sdl3-rs/blob/0ffa35e5f6d68b3bcc56bb724af0ad5e538af6f4/src/sdl3/iostream.rs)
привязывает memory stream к заимствованным bytes. Для первого das API проще
копировать память в owner либо удерживать специальный buffer object до close.
Режим borrow без копии предоставлять только с доказанным сроком жизни.

## ADR: Python + Clang или dasClangBind?

| Критерий | Текущий генератор | dasClangBind / CppGenBind |
| --- | --- | --- |
| Уже работает | 50 функций, allowlist, structs/opaque handles, api.json, freshness test | 50 функций; самостоятельные policy annotations/константы; прежние interpreter/AOT-сценарии. 33 теста, локальный обход pinned AOT recover (см. clangbind-types-aot.md) |
| Комплексность типов | Нужны расширения enum/flags/macros/platform census, callbacks policy, AOT | Есть инфраструктура aliases/enums/structs/preprocessor и AOT, hooks и разбиение функций по TU |
| Среда | Python stdlib + Clang 16.0.5 в текущей проверенной конфигурации | Закреплённый CMake ищет Clang 22.1, libclang и корректную CRT-конфигурацию |
| Семантика SDL | Ручная policy нужна | Ручная policy всё равно нужна; AST не знает ownership и thread affinity |
| Стоимость сейчас | Мало инфраструктурных изменений, но расширяем собственный backend | Выше начальная стоимость, ниже дублирование возможностей daScript binding toolchain при успешном эксперименте |

В `modules/dasClangBind/cbind/cbind_boost.das` есть CppGenBind;
`bind/bind_bgfx.das` показывает настройку aliases, исключение variadic/callback
деклараций, разбиение функций. Его решения вроде isArgByValue нельзя применять
ко всем SDL-типам без ABI проверки. Генерация native binding не создаёт boost
автоматически и не делает callback безопасным.

**Решение после эксперимента:** CppGenBind выбран по умолчанию для MSVC Windows
x64 и текущих 50 функций. Сохранённые snapshots поддерживают обычную сборку
без LLVM (clangbind-production.md). Старый backend пока остаётся baseline
для parity и fallback для других платформ. Это ограниченное принятие текущего
профиля; следующие условия сохраняются для расширения ABI/GPU и платформ.

Эксперимент ограничить тремя репрезентативными группами:

1. SDL_rect.h: простые POD, ref/out, inline/function macros.
2. SDL_pixels.h: enums, aliases, bit constants, formats и указатели.
3. Выборка SDL_gpu.h: nested create-info, fixed arrays, pointer+count,
   opaque resources; отдельно callback typedef из другого заголовка.

Условия принятия: воспроизведены существующие 50 exports и примеры; корректны
ABI assertions и AOT consumer; генерация повторяется без diff; неподдержанные
конструкции диагностируются; policy и platform guards сохраняются; обычная
сборка не требует LLVM. Сравнить размер diff, время и сложность overrides.

При выполнении условий перенести единственный источник generated raw на
dasClangBind и убрать старый backend после проверки эквивалентности. На время
эксперимента можно сравнивать outputs в отдельной папке, но не регистрировать
одни exports двумя генераторами. Если toolchain/ABI/AOT блокируют переход,
продолжить Python Clang backend с тем же census/policy и закрыть конкретные
пробелы. Массовое расширение вручную не выбирать ни в одном варианте.
