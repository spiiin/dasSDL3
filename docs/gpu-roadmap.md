# SDL GPU и шейдеры: отдельный план

19 сентября 2026. Реализован ограниченный ClearScreen: device/window scopes
и закрытая native clear-команда. Контракт — `gpu-clear.md`; G0/G1 ещё частичны.
Добавлен ограниченный BasicTriangle с готовыми SPIR-V/DXIL и проверяемыми
pipeline IDs: `gpu-triangle.md`. Добавлен TexturedQuad с immutable vertex buffer,
RGBA8 upload и sampler: `gpu-mesh.md`; несколько устройств проверяются отдельно
(`gpu-multidevice.md`). Общая модель command/pass handles, произвольные layouts,
index buffers, dynamic updates, compute и DSL ещё не реализованы; G2/G3 частичны.
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
