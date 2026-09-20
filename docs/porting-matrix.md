# Примеры и следующие сценарии

Текущий список файлов — [examples/README.md](../examples/README.md).
Удалённые примеры 09–22 и 36 не восстанавливаются как engine API; номера
сохранены, чтобы прежние ссылки не указывали на другой сценарий.

## Уже поддержано

| Примеры | Контракт |
| --- | --- |
| 01–04 | daScript runner, окно/renderer, ввод, BMP/texture |
| 05–08 | Streaming pixels, render target/readback, geometry, queued audio |
| 23–29 | Checked buffer/texture transfers, formats, BC/cube, drivers/names |
| 30–35 | Swapchain settings, color targets, mipmaps/blit |
| 37–43 | GPU descriptors, volumes, guarded ASTC, sampler/shader/pipeline ownership |
| 44–47 | Checked direct recording/vertex/index/sampling, native fences |
| 48–50 | Public native graphics/swapchain, compute/CPU reference, byte transfers |

GPU demos используют собственные assets и не объявляются буквальными портами
SDL_gpu_examples. Положительный ASTC roundtrip пока не подтверждён.
Результаты и backend исключения — [GPU validation](gpu-native-validation.md).

## Очередь по новым контрактам SDL

| Очередь | Сценарий | Проверка |
| --- | --- | --- |
| P1 | Собственный Properties example | Типы/defaults, копии UTF-8, owned/borrowed IDs, lock/cleanup |
| P1 | Hints и Init | Приоритеты, восстановление изменённых hints, subsystems, ошибки |
| P2 | renderer rotating/scaling/color-mods, viewport/cliprect | Фиксированные кадры, state restore, CPU pixels |
| P3 | joystick/gamepad polling/events | Virtual/synthetic и physical отдельно, hotplug/no-device |
| P4 | IOStream/Storage/AsyncIO | Roundtrip временных данных, EOF/short read, lifetime до completion |
| P5 | audio multiple-streams/callback, camera read-and-draw | Dummy/offline отдельно от hardware, thread и frame release |
| Позже | Clipboard/Locale/Power, pen, demos/snake | Восстановление внешнего состояния, replay, отсутствие устройства |

Для upstream-порта закрепить revision/path/license, проверить совместимость
с SDL 3.2.18, запустить C-оригинал на том же backend и затем короткий public
пример плюс regression test. Сайт SDL может содержать более новые API.
Примеры выбираются по пробелам API, а не как повод добавлять сцены/материалы.

Источники исследованной очереди: [SDL examples](https://examples.libsdl.org/SDL3/),
[SDL_gpu_examples](https://github.com/TheSpydog/SDL_gpu_examples).
Для GPU полезны CopyAndReadback, TriangleMSAA, BasicCompute/ComputeUniforms,
InstancedIndexed; соответствующие операции уже имеют локальные тесты.
Bloom/ToneMapping и sprite batching допустимы как application examples после
подтверждения нового контракта, но не как новые публичные объекты обвязки.

## Языковые и shader проверки

Проверять trailing blocks/ref outputs, ранний return/defer, массивы и копии,
SDL enum/flags/record ABI, отсутствие script pointer retention и строгий AOT.
Result/Option и variants — изученные варианты, не обязательный слой вокруг
каждого SDL вызова. Никакого нового recover-механизма для ресурсных wrappers.

[dasBGFX idioms](bgfx-idioms.md) сохраняет источники и примеры triangle/image,
render-to-texture, compute/readback, TTF и ImGui. Для SDL ждать fence, не BGFX
frame-id. Будущий DSL должен дать те же layout и GPU pixels, что external shaders.
