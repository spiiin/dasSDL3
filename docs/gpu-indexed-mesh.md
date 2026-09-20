> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# SDL GPU: indexed mesh

Следующий шаг после TexturedQuad: `examples/12_gpu_indexed_quad.das` хранит
четыре вершины float4(NDC x,y,u,v) и шесть uint32 индексов (0,1,2,0,2,3).
Используются прежние доверенные SPIR-V/DXIL mesh shaders и RGBA8 texture.

```daslang
device |> with_gpu_indexed_textured_mesh(window, vertices, indices, pixels,
        width, height, vertex_file, fragment_file, format) $(mesh) {
    device |> gpu_draw_textured_mesh(window, mesh)
}
```

Новый adapter `SDL_CreateGPUIndexedTexturedMesh` создаёт immutable mesh в том же
registry. Старые release/draw и device cleanup работают для обоих видов mesh.
Scoped API ловит panic, освобождает пакет ресурсов и сохраняет исходную ошибку.
Нельзя вручную освобождать mesh внутри owning scope.

Все три массива синхронно копируются в staging storage до возврата из создания.
Скрипт может сразу очистить их. Vertex/index buffers загружаются в одном native
copy pass; staging release использует отложенное освобождение SDL. Texture offset
остаётся кратным 512. Общий размер ограничен 48 MiB плюс padding, арифметика
выполняется после проверки отдельных лимитов. Нет retained script pointers.

Контракт индексов:

- `array<uint>` соответствует UINT32 index buffer; UINT16 пока не поддержан.
- От 3 до 4194303 индексов, количество кратно трём (не более 16 MiB).
- Каждый индекс строго меньше количества вершин, проверяется до GPU allocation.
- Пустой index array отвергается при создании; fallback к sequential draw нет.
- Для indexed mesh число вершин не обязано быть кратно трём; лимит 1048576.
- Одна instance, first_index/vertex_offset/first_instance равны нулю.

Нативный путь использует [SDL_BindGPUIndexBuffer](https://wiki.libsdl.org/SDL3/SDL_BindGPUIndexBuffer)
и [SDL_DrawGPUIndexedPrimitives](https://wiki.libsdl.org/SDL3/SDL_DrawGPUIndexedPrimitives).
Сигнатуры и доступность сверены с закреплённым SDL 3.2.18. Произвольные layouts,
динамические обновления, диапазоны draw, instancing и UINT16 остаются отдельными
этапами; это не универсальный публичный buffer builder.

`tests/gpu_indexed_mesh.das` использует тот же независимый CPU pixel reference,
что и sequential mesh (>3000 RGBA8 pixels), и проверяет invalid/empty/incomplete
indices, stale/foreign IDs, копирование всех массивов, normal/early/panic cleanup,
два устройства и readback A после shutdown B. Interpreter и strict AOT имеют
явные Vulkan/D3D12 проверки. Недоступный первый backend — SKIP77, ошибка после
его создания — failure. Readback пока только test fixture.

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/12_gpu_indexed_quad.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
ctest --test-dir build/ninja -R gpu_indexed --output-on-failure
```

Флаг layer нужен при описанном в `gpu-multidevice.md` конфликте FPS Monitor;
он не меняет системные настройки и не отключает Khronos validation.

Проверено 2026-09-19, Windows x64/MSVC: основной набор 40/40, generator parity
и strict AOT 89/89, без SKIP, включая явные Vulkan/D3D12 indexed tests.
Consumer с BUILD_TESTING=OFF, генераторами OFF и отключённым поиском
Clang/LLVM/Python собран и отправил по 60 кадров IndexedQuad на обоих backend.
В тестовом окружении Vulkan исключён конфликтующий FPS Monitor layer.
