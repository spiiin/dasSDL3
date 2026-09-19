# SDL GPU и шейдеры: отдельный план

## Текущий приоритет: завершить P6

По явному выбору пользователя P6 продолжается раньше Properties/P1.
Состояние после пакетов 26–29: **92 функции GPU: 7 generated, 50 adapted,
35 pending** в закреплённом Windows-профиле. Adapted означает ограниченный
контракт, а не завершённую функцию со всеми вариантами параметров.
Пример 23 и [gpu-transfer.md](gpu-transfer.md) добавляют публичные byte buffers,
копирование диапазонов и асинхронные readback tickets с fence. Это часть G3;
Пример 24 добавляет RGBA8 2D/array texture upload/copy/download с mip/layer
регионами и pitch; контракт — [gpu-texture-transfer.md](gpu-texture-transfer.md).
3D/ASTC transfers и произвольные command/pass handles ещё впереди.

Автоматический батч 24 (7 шагов):

- [x] Owned RGBA8 2D/array textures с инициализированными mip/layer.
- [x] Проверки regions, pitch, размеров и переполнений.
- [x] Копирующий upload с ограниченным cycling.
- [x] Texture-to-texture region copy между независимыми ресурсами.
- [x] Асинхронный texture readback через общий fence ticket.
- [x] Пример 24 и CPU pixel/reference/lifetime регрессии.
- [x] Interpreter, strict AOT, Vulkan/D3D12 и LLVM-free consumer.

Авторизация пользователя: продолжать P6 батчами по 5–10 шагов без запроса
нового подтверждения после каждого шага/батча. Сохранять проверки и явно
отмечать ограничения; не считать ограниченный срез полной подсистемой.

Батч 25: запросы размера блока/изображения и поддержки формата/sample count,
121 новая генерируемая константа, несжатые цветовые transfers с 1/2/4/8/16 bytes
per texel, совместимость RGBA8, пример и проверки — [gpu-formats.md](gpu-formats.md).
На этапе 25 BC/ASTC/depth были доступны только для queries. Типизированные enum
annotations не объявляются реализованными наличием enum-констант.

Пакеты 26–29: BC transfers, cubemap/cube arrays, driver/shader support queries,
checked resource names. Общий прогон после четырёх пакетов — новый согласованный
порядок работы. Контракты и ограничения: [gpu-texture-types.md](gpu-texture-types.md).
Обычные 2D/array color transfers и RGBA8 scopes сохраняются.

Очередь закрытия P6:

1. **Остаток G3:** добавить 3D/ASTC transfers;
   general transfer descriptors/mapping. Срезы примеров 23–29 уже покрывают
   buffer/texture snapshots, несжатые цветовые и BC форматы, format/sample queries,
   mip/layer/cube regions, pitch, overflow и completion на Vulkan/D3D12.
2. **G0/G1/G2 — общие ресурсы и запись:** checked command/pass handles,
   устройства-владельцы, invalidation после end/submit/cancel, отдельный borrow
   swapchain, shader/pipeline/create-info ABI, layouts, sampler/texture/buffer
   bindings. Существующие fixed mesh helpers остаются удобными фасадами.
3. **G4 — graphics completeness:** viewport/scissor/blend/stencil, независимые
   color/depth targets, render-to-texture, MSAA/resolve, mipmaps/blit, UINT16
   и произвольные draw ranges, indirect draw с проверкой bounds/stride.
4. **G5 — compute:** shader resource layout, storage buffers/textures, direct и
   indirect dispatch, uniform blocks; integer compute с точным CPU reference
   и публичным readback на обоих backend. DSL не является условием этой части.
5. **G6 — остаток:** properties-based device,
   swapchain modes/frames-in-flight, debug labels/groups; явно ограничить
   main-thread API либо отдельно доказать разрешённую многопоточную запись.
6. **Приёмка P6:** разобрать все 92 функции и используемые типы/flags, указать
   полные/ограниченные/платформенные контракты. Ноль pending сам по себе
   недостаточен: нужны общие bindings, state/ownership/failure tests,
   interpreter/strict AOT/LLVM-free builds, Vulkan и D3D12; Linux/Metal остаются
   непроверенными до реального запуска. S1–S3 shader toolchain/DSL отдельно.

Неподключённые функции сгруппированы для последующих проходов:

| Группа | Pending SDL functions (без префикса SDL_) |
| --- | --- |
| Texture data и format helpers | BlitGPUTexture, GenerateMipmapsForGPUTexture |
| Compute | CreateGPUComputePipeline, ReleaseGPUComputePipeline, BeginGPUComputePass, EndGPUComputePass, BindGPUComputePipeline, BindGPUComputeSamplers, BindGPUComputeStorageBuffers, BindGPUComputeStorageTextures, PushGPUComputeUniformData, DispatchGPUCompute, DispatchGPUComputeIndirect |
| Graphics state и bindings | BindGPUVertexSamplers, BindGPUVertexStorageBuffers, BindGPUVertexStorageTextures, BindGPUFragmentStorageBuffers, BindGPUFragmentStorageTextures, SetGPUViewport, SetGPUScissor, SetGPUBlendConstants, SetGPUStencilReference, DrawGPUPrimitivesIndirect, DrawGPUIndexedPrimitivesIndirect |
| Device/window | AcquireGPUSwapchainTexture, WaitForGPUSwapchain, SetGPUSwapchainParameters, SetGPUAllowedFramesInFlight, WindowSupportsGPUPresentMode, WindowSupportsGPUSwapchainComposition, CreateGPUDeviceWithProperties, GPUSupportsProperties |
| Debug | InsertGPUDebugLabel, PushGPUDebugGroup, PopGPUDebugGroup |

Следующие разделы сохраняют подробный исходный план G0–G6/S1–S3 и историю
реализованных срезов. Ни один этап не закрывается только числом примеров.


19 сентября 2026. Реализован ограниченный ClearScreen: device/window scopes
и закрытая native clear-команда. Контракт — `gpu-clear.md`; G0/G1 ещё частичны.
Добавлен ограниченный BasicTriangle с готовыми SPIR-V/DXIL и проверяемыми
pipeline IDs: `gpu-triangle.md`. Добавлен TexturedQuad с immutable vertex buffer,
RGBA8 upload и sampler: `gpu-mesh.md`; несколько устройств проверяются отдельно
(`gpu-multidevice.md`). Общая модель command/pass handles, произвольные layouts,
general geometry updates, compute и DSL ещё не реализованы; G2/G3 частичны.
Immutable UINT32 index buffers добавлены в `gpu-indexed-mesh.md`; произвольные
draw ranges и UINT16 остаются следующими расширениями G2; immutable instancing — пример 17.
Vertex uniforms для 2D transforms добавлены с фиксированным 32-byte ABI:
`gpu-transform.md`. Общие layouts и произвольные uniform blocks ещё впереди.
Добавлен фиксированный 3D color-vertex ABI с float4x4 MVP, стандартной RH camera
и depth target, обновляемым при resize: `gpu-3d.md`. Textured 3D и Lambert light
с inverse-transpose normals и fixed fragment uniform добавлены в `gpu-lit.md`.
Несколько lit draw в одном pass с общей глубиной реализованы в `gpu-scene.md`.
G4 начат; MSAA, general layouts и произвольные pass builders ещё впереди.
Оконные сценарии G1 проверены на Vulkan: resize, два claimed окна,
minimize/restore и независимый cleanup при panic. Свёрнутое окно в этом backend
продолжало получать drawable; NULL-путь проверен отдельно через mock.
Основной roadmap — `full-binding-roadmap.md`, примеры — `porting-matrix.md`.

## Порядок

Сначала SDL GPU с готовыми шейдерами, затем offline shader pipeline,
после этого ограниченный DSL на существующих средствах daScript.
Renderer API и GPU API оставить отдельными модулями: не скрывать device,
pipeline и synchronization за существующим простым renderer.

| Этап | Реализация | Условие перехода дальше |
| --- | --- | --- |
| G0: модель | Инвентаризация SDL_gpu.h, типы/flags/create-info, устройства и поддерживаемые shader formats | ABI/layout checks, обработка отсутствия backend, device ownership |
| G1: кадр | Claim/release window, acquire command buffer, swapchain, clear, submit | ClearScreen, resize/minimize/restore, два окна, нормальное закрытие и ошибки |
| G2: graphics | Готовые vertex/fragment binaries, pipeline, vertex/index/texture/sampler, render pass | Triangle и TexturedQuad; правильный format, layout, alpha; negative state tests |
| G3: данные | Transfer buffers, map/unmap, copy pass, upload/download, fence | CopyAndReadback с точным сравнением bytes; bounds/pitch/alignment и completion |
| G4: сложная графика | Depth, MSAA/resolve, render-to-texture, mipmaps, instancing, indirect draw | Resize attachments, читаемый результат offscreen, cycling/resource reuse |
| G5: compute | Compute pipelines, storage buffers/textures, dispatch, indirect dispatch | CPU reference для integer compute, uniform layout, readback после fence |
| G6: полнота | Оставшиеся функции, feature queries/debug names, многопоточная запись где разрешена | Реестр SDL_gpu.h без неразобранных символов; backend matrix и документация |
| S1–S3: шейдеры | Offline shadercross → typed bindings → DSL | Независимые контрольные точки ниже |

## Command buffer — объект с состоянием

Нужно различать: acquired; recording без pass; render/copy/compute pass;
swapchain acquired; submitted; cancelled. Pass принадлежит одному command
buffer; resource — одному device; borrow swapchain — одному кадру/command buffer.
После submit/cancel все соответствующие script handles инвалидируются.
Числовой id с generation либо native wrapper позволяет обнаружить устаревший
handle до вызова SDL. Обычный копируемый raw pointer этого не обеспечивает.

Особые контракты из SDL:

- [WaitAndAcquireGPUSwapchainTexture](https://wiki.libsdl.org/SDL3/SDL_WaitAndAcquireGPUSwapchainTexture)
  может успешно вернуть NULL: кадр пропускается, это не SDL error. Текстура
  принадлежит SDL; пользователь не освобождает её. Соблюдать требования к потоку.
- [CancelGPUCommandBuffer](https://wiki.libsdl.org/SDL3/SDL_CancelGPUCommandBuffer)
  нельзя вызывать после получения swapchain texture. Поэтому универсальное
  «на любом panic вызываем cancel» неверно.
- [SubmitGPUCommandBuffer](https://wiki.libsdl.org/SDL3/SDL_SubmitGPUCommandBuffer)
  завершает использование command buffer: повторный submit и доступ через
  сохранённую копию wrapper должны отсекаться нашим слоем.

Предлагаемый дизайн ошибок: подготовка ресурсов и fallible shader/pipeline
operations до swapchain acquisition; до acquisition — legal cancel при ошибке;
после acquisition — catch, закрытие активного pass и заранее определённый
допустимый путь завершения кадра с submit. Этот путь нужно доказать на выбранном
SDL/backend, включая сбой submit/device loss. До этого не обещать общий
`with_frame` с rollback и не разрешать произвольные переходы состояния.
Оригинальную ошибку сохранять; ошибка finalization не должна её молча заменять.

Рекомендуемые формы API (имена предварительные): `with_device`,
`with_render_pass`, `with_copy_pass`, `with_compute_pass`, `with_mapped_transfer`.
Синхронные block scopes используют проверенную catch-cleanup инфраструктуру.
Mapped view действует только внутри блока; безопасный базовый вариант принимает
array и копирует данные. Позже возможен проверяемый zero-copy view с generation.

## Буферы, ресурсы и параллельность

- Отделить vertex layout, storage layout и uniform layout: один `sizeof(T)`
  не доказывает совместимость. Проверять offsets, array/matrix stride, padding.
- Проверять format/usage/sample-count, dimensions/mips/layers, row pitch,
  buffer regions и переполнения. Copy должен учитывать тип формата и размер блока.
- Cycling и reuse сделать явной опцией с описанием, а не скрытым исправлением
  всех hazards. Fence/wait нужен для чтения завершённого download на CPU.
- Сохранять device до release зависимых объектов; отдельно отслеживать
  borrowed window/swapchain. Обработать shutdown при частично созданном наборе.
- Сначала main-thread recording. Возможную многопоточность разрешать по
  конкретным контрактам SDL и отдельным das Context, не по наличию SDL_Thread.
- Benchmark позднее: число native transitions, allocations и copies на draw.
  Добавить bulk APIs/instancing, сохраняя возможность явного управления batch.

## S1: переносимые shader assets без DSL

[SDL_shadercross](https://github.com/libsdl-org/SDL_shadercross) принимает
HLSL/SPIR-V и поддерживает преобразование в несколько backend-форматов.
Предлагается offline сборка: исходник → compiler/validator → binaries + reflection
manifest → runtime выбор по форматам device. Runtime-компиляцию оставить
дополнительным dev-модулем для hot reload; packaged app не обязан содержать DXC.

Зафиксировать версии shadercross, SPIRV-Cross, DXC и нужных SDK. Cache key:
исходник и includes, stage/entry, defines, target, версии инструментов и layout
policy. Manifest: stage, entrypoint, formats, resource counts, slots, uniforms,
vertex inputs, compute local size. Ошибки компилятора показывать с исходными
строками. Hot reload заменяет pipeline только после успешной сборки, старые
ресурсы освобождаются с учётом выполняющейся работы GPU.

Матрица сначала Windows D3D12/Vulkan; затем Linux Vulkan и macOS Metal.
Наличие файла SPIR-V не доказывает работу DXIL/MSL. На каждой доступной
платформе сравнить output и reflection; отсутствие hardware отметить отдельно.

## S2: типизированные данные и привязки

[SDL_CreateGPUShader](https://wiki.libsdl.org/SDL3/SDL_CreateGPUShader) задаёт
backend-specific порядок bindings. Для SPIR-V graphics используются разные
sets для vertex resources/uniforms и fragment resources/uniforms. Нельзя
просто взять default set=0 от произвольного Vulkan shader emitter. Compute
имеет собственные правила — внести их в отдельную stage policy.

[PushGPUVertexUniformData](https://wiki.libsdl.org/SDL3/SDL_PushGPUVertexUniformData)
требует std140. Генерировать CPU packer и проверять его против reflection;
тестовые типы: float3 рядом со scalar, массивы, bool representation, вложенные
структуры, матрицы и порядок строк/столбцов. Аналогично проверить storage buffers
по их конкретному контракту, не переносить host ABI автоматически.

Typed bindings сначала можно генерировать из reflection внешнего HLSL/SPIR-V.
Это даёт удобство без необходимости сразу писать собственный frontend.

## S3: DSL — адаптировать имеющийся frontend

В закреплённом daScript уже исследованы:

- `modules/dasSpirv/ARCHITECTURE.md`, `spirv/spirv_shader.das` и `.das_module`:
  AST→SPIR-V emitter, shader annotations, reflection и диагностика;
- `tests/spirv/_spirv_common.das`: compute shader `data[i] = i*i` с локальной
  группой 64; `test_reflect.das` и другие проверки emitted metadata;
- `daslib/shader_lingua_franca.das`: общий shader vocabulary для dasGlsl/dasSpirv;
- `daslib/shader_block_layout.das`: расчёт block layout;
- dasBGFX macros: выделение shader functions и derivation vertex/uniform metadata.

Поэтому сначала проверить цепочку **daScript shader subset → dasSpirv →
SDL binding/layout policy → shadercross → SDL GPU**. Не создавать новый язык
и новый компилятор с нуля. Это перспективный путь, а не уже проверенная
совместимость: emitter и его тесты прочитаны, SDL backend ещё не реализован.

Proof of concept: один integer compute shader и triangle vertex/fragment;
правильные descriptor sets, reflection counts, entrypoint, std140 и поведение
на двух backend. Использовать поддерживаемые настройки emitter; если их
недостаточно, изолированный adapter/patch с тестом, без произвольного правления
SPIR-V words. Любое обновление pinned daScript — отдельное решение.

Первый subset: scalar/vector/matrix, fixed structs, uniforms, textures/samplers,
ограниченные control flow и storage buffers. Запретить heap/strings, SDL calls,
рекурсию, исключения и unsupported stage features; сообщать ошибку компиляции,
не выполнять неподдержанный shader fragment на CPU молча. Mesh/ray tracing и
другие возможности emitter не становятся доступными через SDL автоматически.

Аннотации в стиле BGFX могут быть тонким SDL-specific фасадом; окончательный
синтаксис выбрать после PoC, не объявлять выдуманные annotations работающими.
Если dasSpirv не проходит backend/layout gates, оставить external HLSL/SPIR-V
и typed bindings полноценным поддерживаемым путём; DSL остаётся расширением.

## Обязательные GPU проверки

State tests до обращения к SDL: double submit, use-after-pass/end, чужой device,
stale mapped view, overflow и размер массива. Реальные GPU tests: clear/readback,
triangle, uploads/downloads, integer compute, uniforms, resize/minimize,
ошибка до/после acquisition, shutdown с pending work. Проверять validation
messages, а не только картинку. Integer данные сравнивать точно; float/image
использовать заданный tolerance и фиксированные assets/seeds.

G2/G4 instancing slice: example 17 uses immutable model/normal instance buffers
and one indexed draw for 64 lit cubes. Camera/light remain per-frame; instance
updates are extended by example 18. Indirect drawing and arbitrary layouts remain pending.
Contract and verification: [gpu-instancing.md](gpu-instancing.md).

Fixed-count full instance updates are implemented in example 18 and
`gpu-dynamic-instances.md`, with cycling and queued-snapshot pixel tests. General
dynamic geometry, resizing an existing mesh instance buffer and partial updates
remain future work; scene list counts can vary through example 20.

Example 19 adds per-instance RGBA in a separate stride128 layout, texture/light
modulation and dynamic full updates. Transparency blending/sorting, per-instance
textures remain future stages. See `gpu-instance-colors.md`.

Example 20 adds opaque grouping by exact colored mesh bundle ID, one indexed draw
per group, shared depth and cycled scene buffers for variable object counts.
See `gpu-material-batches.md`. Separate geometry/material ownership is added in
example 22. Deduplication, transparent sorting/blending and indirect draws remain future work.

Example 21 adds CPU frustum culling with local bounding spheres and exact affine
plane support before instance packing/upload. Visibility counters, ON/OFF mode,
clip-oracle math tests and full/culled pixel equality are in `gpu-frustum-culling.md`.
Occlusion culling, automatic bound extraction and GPU-driven culling remain future work.

Example 22 separates immutable geometry and colored-instance materials, with
lightweight borrowed bindings and pair-based batches. Existing mesh bundles stay
supported. See `gpu-shared-resources.md`. Content/pipeline deduplication, standalone
texture resources, arbitrary material state and transparency remain future work.
