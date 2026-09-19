# SDL GPU: vertex uniforms и 2D transforms

`examples/13_gpu_transform_quad.das` анимирует indexed quad без обновления
vertex buffer. `require dassdl3/sdl3_gpu_transform_boost` добавляет
`with_gpu_transform_mesh` с теми же аргументами, что indexed mesh scope, и:

```daslang
device |> gpu_draw_transform_mesh(window, mesh, translation, scale, angle)
```

translation и scale — float2, angle — float в радианах. Порядок: масштаб,
поворот против часовой стрелки, перенос в NDC. Отрицательный scale отражает
объект; нулевой допускается и даёт вырожденную геометрию. Native adapter
отвергает NaN/Infinity в итоговых строках до command acquisition. Большие конечные
значения могут вывести геометрию за clip volume; API не нормализует их.

## Shader ABI

Новый доверенный vertex shader `transform.vert.*` содержит uniform slot 0:
два float4, rowX и rowY, offsets 0/16, всего 32 bytes. Native alignas(16) struct
имеет статические проверки размера и offset; daScript float4 копируются в него.
HLSL cbuffer b0,space1 соответствует SPIR-V set1,binding0. Disassembly проверен:
offsets 0/16. Формула shader: dot(rowX, float4(x,y,0,1)) и аналогично rowY.
z каждой строки должен быть нулём; translation находится в w. Нет неоднозначности
row-major/column-major матриц. Это фиксированный 2D ABI, не arbitrary uniform API.

[SDL_PushGPUVertexUniformData](https://wiki.libsdl.org/SDL3/SDL_PushGPUVertexUniformData)
требует std140; правила shader bindings описаны в
[SDL_CreateGPUShader](https://wiki.libsdl.org/SDL3/SDL_CreateGPUShader).
Сигнатуры сверены с закреплённым SDL 3.2.18. Shader create-info объявляет один
vertex uniform buffer. Fragment shader сохраняет один sampler и не имеет uniforms.

Native frame получает command buffer только внутри C++; push slot0 происходит
перед draw, каждый кадр передаются актуальные 32 bytes. Script callbacks и borrowed
uniform pointers не выдаются. Общие правила acquire/submit/cancel сохраняются.
Обычный draw отвергает transform mesh, transform draw отвергает обычный mesh.
Доверенные offline shader assets выбираются явно при создании; проверка file
magic не является reflection и не защищает от подмены shader с другим ABI.

Владение buffers/texture/sampler и cleanup при panic — как в `gpu-indexed-mesh.md`.
Стандартный mesh ABI и примеры 11/12 не меняются. Uniforms не сохраняются в mesh,
поэтому разные draw не разделяют изменяемую матрицу на стороне скрипта.

## Проверки

`tests/gpu_transform.das`: identity, перенос + неравномерный scale, 90° rotation,
произвольный rotation/scale и отражение. Test fixture читает 64x64 RGBA8 target
после fence; CPU через обратное преобразование определяет ожидаемый texel.
Для каждого случая сравнивается >3000 пикселей, кроме полос около границ.
Смена transforms между кадрами, очистка исходных arrays, два devices, stale/foreign
IDs, оба направления несовместимого shader ABI, invalid rows и panic cleanup
также покрыты. Vulkan/SPIR-V и D3D12/DXIL — отдельные interpreter/AOT tests.

```powershell
python tools/build_triangle_shaders.py --transform --check
./build/ninja/bin/dasSDL3_runner.exe examples/13_gpu_transform_quad.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

Фильтр FPS Monitor — локальный обход из `gpu-multidevice.md`. Обычная consumer
сборка копирует готовые binaries и не требует DXC/LLVM. Общие layouts/reflection,
3D matrices, fragment uniforms, dynamic buffers и DSL остаются следующими этапами.

Дополнение: фиксированный 3D MVP/color/depth сценарий реализован отдельно в
`gpu-3d.md`; этот 2D ABI остаётся прежним. Общий uniform/layout builder впереди.

Результат 2026-09-19, Windows x64/MSVC: основной набор 44/44, generator parity
и strict AOT 97/97, без SKIP. Consumer с BUILD_TESTING=OFF, генераторами OFF и
Clang/LLVM/Python discovery OFF собран и отправил по 60 кадров на Vulkan и D3D12.
Offline `--transform --check` и spirv-val прошли. В Vulkan test environment
отключён только конфликтующий FPS Monitor layer; debug mode сохранён.
