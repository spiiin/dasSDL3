# Textured 3D и направленный свет

`examples/15_gpu_lit_cube.das` добавляет к камере/depth из примера 14 текстуру,
нормали граней и Lambert lighting. Куб имеет 24 вершины: UV и нормали разрываются
на границах граней. Пример не содержит unsafe/address операций.

```daslang
require dassdl3/sdl3_gpu_lit_boost
device |> with_gpu_lit_mesh(window, positions, normals, uv, indices, pixels,
        width, height, vertex_file, fragment_file, format) $(mesh) {
    device |> gpu_draw_lit_mesh(window, mesh, camera, model, float3(0.4,0.8,1.0), 0.2)
}
```

## Данные и владение

Positions/normals — `array<float4>` одинаковой непустой длины; position.w=1,
normal.w=0. Конечные нормали с squared length >=1e-12 нормализуются при upload.
UV — `array<float2>` той же длины, конечные значения в 0..1. UINT32 indices —
непустой triangle list, все индексы проверяются до GPU allocation.
Packed vertex ABI: stride48, position offset0, normal offset16, UV offset32,
locations0/1/2. Padding обнулён. До 349525 вершин и 4194303 индексов.

RGBA8 pixels имеют точный размер width*height*4, до 8192 на сторону и до 16 MiB.
Texture — R8G8B8A8_UNORM, nearest/clamp, один mip. Цвета считаются линейными;
автоматического sRGB decode нет. Нет blending/alpha test: RGB умножается на
освещение, alpha texel сохраняется, depth пишется и для прозрачного texel.

Все массивы копируются в native staging до возврата фабрики. Texture offset
выравнивается на 512 bytes; SDL обрабатывает D3D12 row alignment. CPU-массивы можно
сразу очистить. Pipeline, vertex/index buffers, texture, sampler и cached depth
владеются одним ID. Отдельный registry использует общий монотонный GPU ID counter;
stale/cross-kind/foreign IDs отклоняются. Return/panic и shutdown устройства
освобождают его ресурсы, не затрагивая другое устройство. Общие depth/resize и
submit-after-acquisition контракты описаны в `gpu-3d.md`.

## Матрицы и свет

Boost вычисляет MVP = camera*model. Model должна быть конечной affine matrix:
последняя строка (0,0,0,1). Native adapter строит inverse-transpose верхней 3x3,
сохраняя направление нормалей при rotation, shear, nonuniform/negative scale.
Перед вычислением 3x3 делится на максимальный абсолютный элемент; determinant
по модулю меньше 1e-8 отклоняется. Поэтому некоторые плохо обусловленные, хотя
математически обратимые матрицы тоже отклоняются. Normal matrix масштабируется
общим положительным множителем, чтобы её элементы не превосходили 1.
Singular/projective/nonfinite model отклоняется до command acquisition.

Vertex slot0 — 112 bytes: четыре float4 столбца MVP (offsets0/16/32/48),
три padded float4 столбца normal matrix (64/80/96). HLSL b0/space1, SPIR-V
set1/binding0. Fragment sampler0 — t0/s0 space2, combined sampler set2/binding0.
Fragment slot0 — 16 bytes, float4(direction.xyz,ambient), b0/space3,
set3/binding0. Shader assets доверенные; manifest фиксирует ABI и хеши,
но не является общей shader reflection.

Light direction направлен **к источнику** в мировых координатах; конечный вектор
с squared length >=1e-12 нормализуется в native adapter. Ambient в 0..1.
Fragment normal нормализуется после перспективной интерполяции; нулевая normal
даёт только ambient. Формула RGB: texture * (ambient + (1-ambient)*max(dot(N,L),0)).
Lighting односторонний; culling выключен, нормали обратных граней автоматически
не переворачиваются. Vulkan Y-inversion не добавлять.

## Проверки

`tests/gpu_lit.das` и `gpu_lit_probe.h`: два перекрывающихся треугольника в обоих
порядках, CPU projection/depth, perspective-correct UV и четыре texel цвета/alpha.
CPU normal matrix независимо вычисляется Gauss-Jordan inversion. Проверяются
identity/camera, rotation с nonuniform scale, negative scale, ambient 0/1 и смена
направления света. Сравнение >2800 пикселей, >80 covered pixels, tolerance1;
полосы около рёбер и границ texel исключены. GPU readback ждёт fence.

Есть invalid indices/positions/normals/UV/sizes/matrix/light, missing shaders,
partial shader cleanup, return/panic с сохранением сообщения, stale/cross-kind и
двусторонний foreign release, resize, два real devices и draw A после shutdown B,
очистка исходных массивов до повторного draw, orphan ID cleanup. Depth allocation
failure и submit/cancel проверяются существующим общим набором `gpu_3d`.

```powershell
python tools/build_triangle_shaders.py --lit --check
./build/ninja/bin/dasSDL3_runner.exe examples/15_gpu_lit_cube.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
ctest --test-dir build/ninja -R gpu_lit --output-on-failure
```

Флаг отключает конфликтующий FPS Monitor layer только в процессе; validation
остаётся включённой. Обычная сборка использует готовые SPIR-V/DXIL.

Проверено 19 сентября 2026 на Windows/MSVC: основной набор **52/52**,
parity/strict AOT **113/113**, без SKIP. Consumer build с BUILD_TESTING=OFF,
генераторами OFF и отключённым Clang/LLVM/Python discovery отрисовал по 60 кадров
на Vulkan и Direct3D 12. Offline shader check и spirv-val прошли; SPIR-V offsets
и descriptor sets сверены через spirv-dis. В сохранённых полных тестовых логах
нет `VUID-`/`Validation Error`. Это проверка текущей машины, не других платформ.

Single-mesh draw остаётся доступным. Несколько lit meshes в одном pass с общим
depth добавлены в `gpu-scene.md`. Общий scene/pass builder, отдельные material
resources, mipmaps/sRGB, normal maps, multiple lights, shadows/PBR, instancing,
device-loss и Metal/Linux пока не реализованы. Shader DSL остаётся отдельным этапом.

Сверено с pinned SDL 3.2.18 и официальными контрактами
[shader bindings](https://wiki.libsdl.org/SDL3/SDL_CreateGPUShader) и
[fragment uniforms/std140](https://wiki.libsdl.org/SDL3/SDL_PushGPUFragmentUniformData).
