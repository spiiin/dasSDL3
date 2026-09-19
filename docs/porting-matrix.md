# Примеры, туториалы и проверки для портирования

GPU TexturedQuad реализован как собственный ограниченный сценарий:
`examples/11_gpu_textured_quad.das`, `gpu-mesh.md`. Vertex buffer, RGBA8 upload,
sampler и pixel reference проверены на Vulkan/D3D12 в interpreter и strict AOT.
Это не буквальный порт upstream-примера; assets и shaders созданы в проекте.
Его indexed вариант — `12_gpu_indexed_quad.das`, контракт в `gpu-indexed-mesh.md`.
`13_gpu_transform_quad.das` добавляет собственный 2D vertex-uniform сценарий;
проверки transforms и layout описаны в `gpu-transform.md`.
`14_gpu_cube.das` — собственный 3D color/depth сценарий со стандартными матрицами
daScript; pixel reference и порядок треугольников проверяются в `gpu-3d.md`.
`15_gpu_lit_cube.das` добавляет собственные texture/normal/light shaders;
CPU reference перспективных UV и Lambert lighting описан в `gpu-lit.md`.
`16_gpu_scene.das` переиспользует lit mesh для трёх объектов в одном pass;
`gpu-scene.md` описывает общий depth, draw list и cross-object pixel reference.

Geometry также реализован: цветной triangle, indexed textured quad, точные
pixel/array проверки в interpreter/AOT — `geometry.md`. Исходный C geometry
пример собран и выполнен с smoke-wrapper на 60 кадров и нашим checker.bmp.

Обновление: streaming_texture и собственный render_target/readback уже
реализованы; contracts и 42 interpreter/AOT-проверки — в `pixels.md`.
Первый lock API использует owned staging array и синхронный native upload;
borrowed pixel block пока отложен. C-исходник streaming изучен, отдельно не запускался.

19 сентября 2026. Это очередь будущих портов. Уже работающие square/textures/
input/audio описаны в `api-coverage.md`; приведённые ниже upstream-примеры
изучены как источники сценариев, но не объявляются запущенными в dasSDL3.

## Как портировать

Для каждого порта фиксировать upstream repo/revision/path, используемый SDL
релиз и лицензию assets. Сначала версия C на том же backend, затем daScript raw
при необходимости диагностики, затем короткий boost-пример без unsafe.
Хранить конечный boost-пример и regression test; не обязательно поддерживать
три пользовательские версии каждого demo постоянно.

Официальный [tutorial index](https://wiki.libsdl.org/SDL3/Tutorials) рекомендует
небольшие [SDL3 examples](https://examples.libsdl.org/SDL3/). Для нашего baseline
приоритет — соответствующие исходники в `SDL release-3.2.18/examples`.
Текущий сайт может использовать более новые функции. Исходники и version
contracts полезнее видеозаписи для воспроизводимого порта.
В локальном 3.2.18 input examples пока представлены joystick polling/events;
gamepad-примеры текущего сайта требуют отдельной проверки совместимости.

## Core SDL: матрица сценариев

| Очередь | Источник / сценарий | Что раскрывает | Проверка результата |
| --- | --- | --- | --- |
| E1 | renderer/streaming-textures | Lock/unlock, pitch, writable pixels, panic cleanup | Детерминированный рисунок, размеры и пиксели, unlock на раннем выходе/ошибке |
| E1 | renderer/geometry | Arrays vertices/indices, пустые массивы, POD layout | Сравнение image, неверный index/размер отсечён адаптером |
| E1 | renderer/read-pixels + собственный target-texture вариант | GPU→surface, pixels ownership, смена render target | Размер/формат/контрольные пиксели, восстановление target и порядок destroy |
| E2 | renderer/rotating-textures, scaling-textures, color-mods, viewport, cliprect | Float rect, origin, modulation, state restore | Несколько фиксированных кадров; точность/tolerance определены заранее |
| E2 | input/gamepad-events и gamepad-polling; joystick варианты; rumble | Перечисление/горячее подключение, IDs, состояние и события | Synthetic/virtual device где поддержано + отдельный физический тест; no-device case |
| E2 | misc/clipboard, locale, power | UTF-8 и SDL-owned arrays/strings; штатно неизвестные значения | Копия/освобождение и fallback; тест clipboard восстанавливает исходное содержимое |
| E3 | storage/user | Readiness, sandboxed application storage, save/load | Временные данные, roundtrip, missing/corrupt data; не трогать реальные сохранения |
| E3 | asyncio/load-bitmaps | Retained buffers, completion queue и cancellation | Завершение/ошибка/shutdown до completion, input lifetime |
| E3 | audio/multiple-streams; simple-playback; load-wav | Mixing/conversion/queue lifecycle сверх текущего WAV smoke | CPU/dummy deterministic данные, bounded queue и завершение |
| E4 | audio/simple-playback-callback | Callback bridge и real-time ограничения | Native producer/queue, отсутствие script вызова на audio thread, stop race |
| E4 | camera/read-and-draw | Permissions, formats/pitch, borrowed frame release | Нет камеры/отказ, hot unplug, каждый acquired frame освобождён |
| E4 | pen/drawing-lines | Device data/pressure и событие со своим payload | Записанная последовательность + физический pen smoke отдельно |
| E5 | demos/snake | Интеграция loop/input/time/render и cleanup | Фиксированный seed/replay, ограниченный smoke режим |
| E5 | demos/bytepusher или infinite-monkeys | Более длительная интеграция audio/IO/render | Длительный запуск, bounded allocations, нормальное завершение |

Простые clear/points/lines/rectangles объединить в gallery и небольшие тесты,
а не растягивать отдельную итерацию на каждый примитив. Новые affine/blending/
planar-audio примеры включать только после проверки доступности в baseline.
Добавить собственные тесты IME/UTF-8/event payload: красивый demo их не заменяет.

## GPU

Добавлен собственный `examples/10_gpu_triangle.das`: vertex-ID BasicTriangle,
готовые SPIR-V/DXIL. `tests/gpu_triangle.das` проверяет CPU pixel reference,
pipeline ID lifetime и partial failure на Vulkan/Direct3D 12. G2 ещё частичен:
BasicVertexBuffer/TexturedQuad и shader resource bindings остаются впереди.

Добавлен собственный `examples/09_gpu_clear.das`: 60 clear/submit кадров в smoke,
scopes устройства/окна и resize в `tests/gpu.das`; ошибки записи кадра —
`tests/gpu_state.das`. Это реализация сценария, не буквальный порт upstream.
Minimize/restore и два одновременно claimed окна проверяются в
`tests/gpu_windows.das`, включая отрисовку внешнего окна после cleanup внутреннего.
На Vulkan подтверждены переходы состояния окна, но NULL drawable не наблюдался;
этот путь покрывает mock. Общие command/pass handles остаются до завершения G1.
Подробности — `gpu-clear.md`.

Источник: [SDL_gpu_examples](https://github.com/TheSpydog/SDL_gpu_examples).
Перед портом закрепить commit; названия ниже обнаружены в исследованном дереве.

| Порядок | Примеры | Проверяемый контракт |
| --- | --- | --- |
| 1 | ClearScreen, ClearScreenMultiWindow, WindowResize | Device/window/commandbuffer, minimize и swapchain lifetime |
| 2 | BasicTriangle, BasicVertexBuffer | Shader assets, vertex ABI, pipeline/pass state |
| 3 | TexturedQuad, TexturedAnimatedQuad | Transfer upload, texture/sampler, uniform packing |
| 4 | CopyAndReadback, CopyConsistency | Fence, completion, mapping bounds и точное сравнение данных |
| 5 | TriangleMSAA, GenerateMipmaps, DepthSampler | Attachments/resolve/mips/depth и resize |
| 6 | BasicCompute, ComputeUniforms, ComputeSampler | Dispatch, storage, slots/layout, CPU reference |
| 7 | InstancedIndexed, ComputeSpriteBatch | Bulk bindings, indirect/instancing и perf boundary |
| 8 | Bloom, ToneMapping | Несколько проходов, float formats, управление ресурсами |

Отдельный текстовый tutorial:
[Moonside: SDL GPU API Concepts — Sprite Batcher](https://moonside.games/posts/sdl-gpu-sprite-batcher/).
Он полезен после textured quad: atlas, storage-buffer данные экземпляров,
upload и явное разделение batch. В статье части host-кода — pseudocode;
портировать с проверкой against headers и полным example source, а не копировать
фрагменты как готовую программу. Измерять calls/copies/frame и CPU/GPU время,
не переносить опубликованный FPS на нашу машину как ожидаемый результат.

Startup tutorial: [SDL main functions](https://wiki.libsdl.org/SDL3/README-main-functions).
Отдельно портировать AppInit/Iterate/Event/Quit через native runner bridge;
проверить failure during init, event-driven quit и cleanup. Этот порт нужен
для дальнейшей mobile/web поддержки, хотя desktop PollEvent loop остаётся.

## dasBGFX: проверять идеи теми же сценами

В [исследованной ревизии dasBGFX](https://github.com/borisbat/dasBGFX/tree/a569838d35a2a584946e784d5e013fb2f08ec4c1/examples):

| Пример | Эквивалент / момент переноса |
| --- | --- |
| 01 triangle | G2 external shaders; повторить после DSL и сравнить результат |
| 02 image, 03 cube | Image module, sampler, transforms/depth; одновременно проверить matrix layout |
| 04 render-to-texture | G4 offscreen pass и resize attachments |
| 05 compute, readback | G5 CPU reference + fence; не переносить BGFX frame-id ожидание |
| 06 ttf | L1 font/text engine и UTF-8 |
| 07 geometry generation | Typed vertex buffers и move semantics, пустая геометрия |
| 08 imgui | L3 backend integration и event capture |

Критерий DSL: одна и та же сцена с external shader и daScript shader даёт
эквивалентные reflection/layout/output; меньше boilerplate без потери диагностики.

## Языковые регрессии, которые стоит адаптировать

Исходники — `third_party/daScript` на закреплённом commit:

- `tests/option/test_result*.das`, `test_option*.das`: error/absence, move-only payload;
- `tests/bare_block/test_assumed_pipe.das`, `test_piped_default_padding.das`:
  trailing blocks, pipes, defaults и результаты блока;
- `tests/language/variants.das`: полный dispatch typed events и unknown fallback;
- `container_finalize.das`, `inscope_return_inscope.das`: normal/early exit,
  explicit collection release; отдельно наш panic/nested recover regression;
- `tests/spirv`: emitted binary/reflection/layout; настоящий spirv-val при наличии
  инструмента, его отсутствие явно skip, а не проверка валидности;
- `modules/dasClangBind/tests/test_const_preproc.das`: constants/preprocessor
  плюс собственные enum/flags/struct ABI fixtures SDL.

Не требуется копировать весь чужой test suite. Нужны небольшие интеграционные
регрессии именно на границе язык↔SDL: исключение, контейнер, handle, callback,
buffer и AOT. Запуск upstream-тестов не заменяет проверку native adapter.

`17_gpu_instancing.das`: 64 copies of a lit cube in one indexed draw, separate
instance-rate model/normal buffer and orbiting camera. This is the bounded
InstancedIndexed learning step; ComputeSpriteBatch/indirect/dynamic updates remain.
