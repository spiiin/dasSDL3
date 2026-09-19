# Несколько lit objects в одном render pass

`examples/16_gpu_scene.das` рисует три экземпляра текстурированного куба с разными
model matrices. Один вызов `gpu_draw_lit_scene` получает swapchain texture,
один раз очищает color/depth, записывает все draw-команды и отправляет один кадр.
Используются существующие `lit.*` шейдеры, без нового shader ABI.

## Управление примером 16

| Ввод | Действие |
| --- | --- |
| Стрелки | Поворот камеры вокруг центра сцены |
| Колесо | Приближение/отдаление, distance 3..12 |
| Space | Пауза/продолжение вращения кубов |
| Enter | Прямой/обратный порядок draw-команд |
| Backspace | Сброс камеры, анимации, паузы и порядка |
| Escape / закрытие окна | Выход с освобождением ресурсов |

Поставьте анимацию на паузу и переключайте Enter: видимые поверхности должны
сохраниться благодаря общему depth buffer. Состояние паузы и порядка показано
в заголовке окна; подсказки также выводятся в консоль. Окно можно изменять в
размере; camera aspect и depth attachment обновляются автоматически.

Скорость анимации задаётся в радианах/секунду через SDL_GetTicks, а не количеством
отрисованных кадров. Delta ограничена 0.1 секунды, чтобы после задержки окна
не было большого скачка. Pitch камеры ограничен, чтобы исключить вырожденную
ось look-at. Переключатели игнорируют key-up и auto-repeat.

Smoke использует фиксированный шаг 1/60, поворот/zoom камеры и тот же обработчик
команд для pause/resume/order/reset, проверяя изменения состояния и остановку
угла при паузе. Он не эмулирует физическую клавиатуру/мышь; интерактивный ввод
использует существующие SDL event/state adapters. Завершение — после 60
успешно отправленных кадров.

После добавления управления пример отдельно прошёл baseline, CppGenBind и strict
AOT на Vulkan/D3D12 (6/6), а также основной runner и ранее собранный LLVM-free
consumer на обоих backend (ещё 4 запуска по 60 кадров). Полные наборы ниже
относятся к реализации GPU scene; для изменения только примера они повторно
не запускались. Физическое управление мышью/клавиатурой вручную не проверялось.

```daslang
require dassdl3/sdl3_gpu_scene_boost
device |> with_gpu_lit_scene(window) $(scene) {
    var draws : GpuLitDrawList
    draws |> gpu_scene_add(mesh_a, model_a, light_direction, 0.2)
    draws |> gpu_scene_add(mesh_b, model_b, light_direction, 0.2)
    device |> gpu_draw_lit_scene(window, scene, draws, camera)
}
```

## Список объектов

`GpuLitDrawList` хранит значения: mesh IDs, четыре float4 столбца model на объект
и float4(direction.xyz,ambient). `gpu_scene_add` копирует matrix/light,
`gpu_scene_clear` очищает список с сохранением возможности повторного заполнения.
Список можно переиспользовать между кадрами. Он не владеет mesh и не продлевает
его жизнь: owning mesh scopes должны охватывать вызов draw. Выпущенный mesh ID
отклоняется при следующем draw, даже если список был корректен на прошлом кадре.

Лимит — 1024 объекта. Повтор одного mesh ID допустим: каждый объект имеет свои
uniforms. Это обычные последовательные draw calls, не hardware instancing.
Пустой список выполняет clear/present, а не no-op. Фон пока фиксирован: black,
alpha1; depth clear1, LESS/write. При равной глубине выигрывает первый draw.

До command acquisition проверяются **все** объекты: длины массивов, ненулевое
хранилище непустых массивов, stale/cross-kind/foreign IDs, color/depth formats,
finite camera/model, affine invertible model, normal matrix и light parameters.
MVP вычисляется как camera*model; overflow при приведении к float отвергается.
Invalid последний объект отвергает целый список, не рисуя первые объекты.
Проверка — не rollback: ошибка submit/device loss после acquisition не означает
отмену уже отправленной работы.

Native preflight копирует uniforms в временный draw packet и разрешает mesh IDs
в указатели только на длительность вызова. После preflight, внутри recording,
нет script callbacks, повторных проверок с panic и изменений registries. После
вызова не сохраняются ссылки на script arrays. Все операции выполняются на main
thread. Raw device/window pointers по-прежнему требуют правильного lifetime.

## Владение depth и кадром

Scene ID использует общий монотонный GPU ID counter и отдельный registry.
Scene владеет только cached depth texture; mesh buffers/textures/pipelines
остаются у mesh owners. Объекты, используемые только в scene, не создают своих
индивидуальных depth textures. Scope cleanup работает при return/panic с
сохранением ошибки. Device shutdown очищает оставленные scene IDs этого device.

Depth создаётся по фактическому размеру acquired swapchain. Resize сначала
создаёт новый target, затем освобождает старый через SDL deferred release.
При allocation failure старый target сохраняется. Scene не привязана к адресу
окна; другое claimed window того же device с совместимым format допустимо.
Подробности бюджета texture, cycling и depth formats — в `gpu-3d.md`.

Общий `SDL_GPUFrameWithTarget` сохраняет правила: NULL drawable → cancel/skip;
после получения texture отказ depth preparation → submit, никогда cancel.
Пустой список также проходит этот путь. Следующий draw может восстановить target.

## Проверки

`tests/gpu_scene.das`/`gpu_scene_probe.h` сравнивают >3000 пикселей с CPU
projection/depth/light reference. Два разных mesh с красной/зелёной текстурами
перекрываются; проверяются оба порядка, разные per-object uniforms, обычная и
перспективная camera, повтор одного mesh, один объект и пустой список. Цвета
сравниваются с tolerance1 вне узких полос вдоль рёбер; непустая сцена требует
>80 covered pixels. Readback ждёт GPU fence.

Mock acquisition доказывает, что invalid последний ID/model/light, несовпадение
длин, nonfinite camera, несовместимый format и stale/foreign/cross-kind IDs
не доходят до backend. NULL drawable проходит cancel/skip без изменения depth
cache. Лимит 1024 принимается,
1025 отклоняется. Дополнительно: реальное resize, injected depth allocation
failure после acquisition и следующий успешный кадр, return/panic, double
release, два real devices, shutdown B с последующим draw A, удаление одного
mesh и повторное использование scene, orphan scene cleanup при shutdown.

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/16_gpu_scene.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
ctest --test-dir build/ninja -R gpu_scene --output-on-failure
```

Флаг layer — process-local обход FPS Monitor из `gpu-multidevice.md`, validation
сохраняется. Обычная сборка использует сохранённые shaders без LLVM/DXC.

Проверено 19 сентября 2026 на Windows/MSVC: основной набор **56/56**,
parity/strict AOT **121/121**, без SKIP. Consumer build с BUILD_TESTING=OFF,
генераторами OFF и отключённым Clang/LLVM/Python discovery отрисовал по 60 кадров
на Vulkan и Direct3D 12. В полных тестовых логах не найдено `VUID-` или
`Validation Error`. Использован только process-local обход FPS Monitor;
другие драйверы и платформы этим результатом не покрыты.

Это ограниченный lit-scene API. Произвольные layouts/materials, смешение разных
shader ABI в списке, render graph, несколько passes/load-store policies,
blending/transparency sorting, hardware instancing, MSAA и device-loss recovery
не реализованы. Нельзя считать этот этап полным render-pass builder.
