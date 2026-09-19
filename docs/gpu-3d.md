# SDL GPU: 3D camera, MVP и depth buffer

`examples/14_gpu_cube.das` рисует вращающийся цветной indexed cube.
`require dassdl3/sdl3_gpu_3d_boost` предоставляет:

```daslang
device |> with_gpu_3d_mesh(window, positions, colors, indices, vertex_file, fragment_file, format) $(mesh) {
    let camera = gpu_camera(eye, target, up, fovy, gpu_window_aspect(window), near_plane, far_plane)
    device |> gpu_draw_3d_mesh(window, mesh, camera * model)
}
```

Это отдельный фиксированный color-vertex ABI. Textured mesh 11/12 и 2D transform
13 сохраняют свои контракты; 3D IDs используют отдельный registry и общий
монотонный счётчик с остальными GPU IDs. Cross-kind/stale/foreign IDs отклоняются.

## Данные и матрицы

- positions: `array<float4>`, конечные x/y/z, w строго 1.
- colors: `array<float4>` того же размера, RGBA в 0..1.
- indices: непустой UINT32 triangle list, каждый индекс меньше числа позиций.
- До 524288 вершин (16 MiB interleaved), до 4194303 индексов (16 MiB).
- Native upload копирует позиции/цвета в stride32: position offset0, color offset16.
  Все исходные массивы можно очистить после создания. Нет retained script pointers.

Используется стандартный `float4x4` из daScript. В `daslib/math_boost.das`
проверены `look_at_rh` и `perspective_rh_0_to_1`. В отличие от старых deprecated
perspective_rh/opengl helpers, последний устанавливает m[3][3]=0, обеспечивая
clip.w=-view.z. Наш тест проверяет near→0 и far→1 после perspective division.
daScript source не изменялся.

Для strict AOT стандартный `daslib/math_boost.das` отдельно включён в список
компилируемых модулей вместе с boost-обвязкой: одного `require` недостаточно для
AOT exports функций камеры. Interpreter fallback остаётся запрещённым.

`gpu_camera` — правая система координат, взгляд от eye к target, угол fovy в
радианах, диапазон глубины 0..1. Проверяются конечные параметры, 0<fovy<PI,
aspect>0, 0<near<far и невырожденные оси (squared length >1e-12).
Вершина проходит `projection * view * model * position`. Четыре **столбца** MVP
копируются в 64-byte uniform slot0: offsets 0,16,32,48, std140, HLSL b0/space1,
SPIR-V set1/binding0. Shader явно складывает columnN*position.component; скрытого
transpose нет. Матрица проверяется на NaN/Infinity до GPU command acquisition.
Конечные сингулярные матрицы допустимы и могут дать вырожденное изображение.

Vulkan Y-inversion не добавлять: SDL уже меняет viewport. Пример обновляет aspect
по физическим размерам окна; при нулевых размерах helper возвращает 1, а
отсутствующий swapchain drawable обрабатывается общим skip-путём.

## Depth и кадр

Перед pipeline creation `SDL_GPUTextureSupportsFormat` выбирает первый доступный
D32_FLOAT, D24_UNORM или D16_UNORM для DEPTH_STENCIL_TARGET. Depth test/write
включены, compare LESS, clear depth 1, stencil выключен, MSAA=1, culling/blending
выключены. Fragment shader выводит интерполированный цвет без lighting/textures.

Каждый mesh владеет одним cached depth target. После swapchain acquisition
native begin-функция получает фактические width/height; при несовпадении создаёт
новую texture, затем отдаёт старую на SDL deferred release. При отказе старый
target остаётся в registry. Лимит: по 8192 на сторону и 16777216 pixels суммарно
(до 64 MiB для D32). Clear/DONT_CARE store, cycle=true разрешают безопасное
использование backing texture при pending frames.

Отказ подготовки depth после получения swapchain texture идёт через общий
SDL_GPUFrameWithTarget: command **submit**, никогда cancel; исходная ошибка
сохраняется. Нет script callbacks во время recording. NULL drawable не создаёт
depth target. Resize и frame recording остаются на main thread.

Scoped release освобождает pipeline, buffers и depth; device shutdown убирает
оставленные raw IDs только этого device. Cleanup выполняется и при panic.
Raw device/window pointers по-прежнему нельзя использовать после owning scope.

## Проверки и границы

`tests/gpu_3d.das` и `tests/gpu_3d_probe.h` сравнивают >3000 RGBA8 pixels с CPU
projection/barycentric depth reference для identity, camera и camera*model.
Два перекрывающихся треугольника проверяются в обоих порядках: итоговое изображение
определяет глубина. В выборке обязательно >80 непустых пикселей; полосы около
рёбер исключены. CPU reference использует независимо заданную геометрию, поэтому
проверка продолжается после очистки script arrays. Readback ждёт GPU fence.

Дополнительно: настоящее resize окна и совпадение depth со swapchain, повторное
использование cache, injected allocation failure с сохранением старого target,
нулевые/огромные размеры, missing shaders/partial cleanup, invalid colors/indices/w,
ранний выход, panic, orphan IDs, два устройства и draw/readback A после shutdown B.
Mock отдельно подтверждает submit без cancel при отказе подготовки attachment.
Отсутствие первого GPU backend — SKIP77; ошибки pipeline/depth после создания
устройства остаются failures. Interpreter и strict AOT имеют Vulkan/D3D12 tests.

Это один opaque mesh за pass, без управления общей сценой и общего render-pass
builder. Textured geometry, normals и fixed fragment light uniform реализованы
отдельным ABI в `gpu-lit.md`. Depth sampling, MSAA, instancing, general uniforms,
device-loss recovery и Metal/Linux впереди.
Существующий RGBA8 texture adapter описан в `gpu-mesh.md`; 2D uniforms — в
`gpu-transform.md`. Подсистемы не считаются полностью покрытыми.

```powershell
python tools/build_triangle_shaders.py --scene3d --check
./build/ninja/bin/dasSDL3_runner.exe examples/14_gpu_cube.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
ctest --test-dir build/ninja -R gpu_3d --output-on-failure
```

Флаг layer — обход FPS Monitor из `gpu-multidevice.md`; validation сохраняется.
Обычная сборка копирует готовые SPIR-V/DXIL и не требует DXC/LLVM.

Проверено 19 сентября 2026 на Windows: основной набор 48/48, parity/strict AOT
105/105, включая реальные Vulkan и Direct3D 12. Consumer build с выключенными
генераторами, Clang/LLVM и Python discovery запустил пример по 60 кадров на обоих
backend. Shader assets прошли offline check и SPIR-V validation; в тестовых логах
не обнаружены `VUID-`/`Validation Error`. Для Vulkan использован только указанный
process-local обход FPS Monitor; это не проверка других драйверов или платформ.

Контракты сверены с заголовками SDL 3.2.18 и официальными справками
[depth target](https://wiki.libsdl.org/SDL3/SDL_GPUDepthStencilTargetInfo),
[format support](https://wiki.libsdl.org/SDL3/SDL_GPUTextureSupportsFormat),
[depth state](https://wiki.libsdl.org/SDL3/SDL_GPUDepthStencilState).
