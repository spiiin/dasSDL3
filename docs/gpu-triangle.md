# SDL GPU BasicTriangle

Первый ограниченный graphics-сценарий для SDL 3.2.18. Он использует собственные
HLSL vertex/fragment shaders, готовые SPIR-V/DXIL и vertex ID (0,1,2).
Vertex/index buffers, uniforms, samplers и текстуры пока не подключены.
Это реализация сценария BasicTriangle, не буквальный порт чужого примера.

## Запуск и idiomatic API

```powershell
./build/ninja/bin/dasSDL3_runner.exe examples/gpu_triangle.das
```

Escape закрывает окно; `--smoke-test` требует 60 отправленных кадров.
Пример выбирает SPIR-V или DXIL по SDL_GetGPUShaderFormats. Файлы ищутся
в assets/shaders рядом с exe, независимо от текущей папки.

`require dassdl3/sdl3_gpu_boost` добавляет:

```daslang
device |> with_gpu_vertex_id_pipeline(window, vertex_file, fragment_file, format) $(pipeline) {
    device |> gpu_draw_triangle(window, pipeline)
}
```

Scope pipeline должен находиться внутри device/window claim scopes.
`gpu_draw_triangle` очищает фон в чёрный, рисует ровно 3 вершины, 1 instance,
без offsets, и отправляет кадр. false — нет drawable, ошибки — panic.
Pipeline: trianglelist, fill, no culling/blending/depth, sample count 1,
один color target формата swapchain. Формат проверяется перед каждым кадром.

Внутри C++ используется тот же state machine SDL_GPUFrame, что и для clear.
Между begin/end исполняются только native bind/draw; script callback отсутствует.
После acquisition swapchain нет cancel, после submit нет повторного обращения
к command buffer. Правила ошибок — `gpu-clear.md`.

## Владение

Script pipeline — uint64 ID, а не адрес. Main-thread registry хранит device,
native pipeline и format. IDs монотонны и не переиспользуются. Release удаляет
ID; stale/double release и чужой device отклоняются до GPU API. Device scope
при shutdown освобождает также оставленные вручную pipeline IDs.
Pipeline release передаёт SDL отложенное освобождение pending GPU work.

Файлы shader читаются синхронно (лимит 16 MiB), shader objects живут только
во время создания pipeline и освобождаются RAII при успехе и частичном отказе.
Scope cleanup сохраняет исходный panic. Код не обещает восстановление после
произвольного C++ bad_alloc или device loss.

Разрешены только **доверенные, offline-проверенные** шейдеры с entrypoint main,
нулевыми resource counts и отсутствием vertex inputs кроме vertex ID. Проверка
magic/размера файла не является reflection или полной валидацией shader ABI.
Произвольный shader с uniforms/неверной stage нельзя передавать этому helper.
Общий shader/pipeline builder будет отдельным этапом.

## Ограничение нескольких устройств

При эксперименте с двумя одновременно активными Vulkan GPU devices на этой
машине следующий draw первого падал после destruction второго. Это воспроизвелось
и в native helper без вложенного daScript callback. Первопричина в SDL/драйвере
не установлена; daScript submodule и SDL source не менялись.

Поэтому scoped API сейчас допускает **одно активное GPU-устройство**. Повторное
создание возвращает false в try_with_gpu_device; with_gpu_device выдаёт panic.
Несколько окон одного device проверены и поддерживаются. Это временная граница
проверенной реализации, а не утверждение, что SDL запрещает несколько устройств.
Не смешивать raw Create/DestroyGPUDevice с scoped ownership. Device/window
указатели ещё копируемы и не имеют защиты от use-after-free, в отличие от IDs.
Foreign-device registry guard проверен синтетическим чужим identity без его
передачи SDL; работу двух реальных устройств тест больше не заявляет.

## Offline assets

Исходники и бинарники: examples/assets/shaders/triangle.*.
tools/build_triangle_shaders.py генерирует SPIR-V и DXIL через DXC,
затем запускает spirv-val для SPIR-V. Manifest содержит SHA-256 исходников,
бинарников и версию DXC; tests/test_triangle_assets.py проверяет целостность
без shader compiler. Это manifest фиксированного контракта, не reflection.

```powershell
python tools/build_triangle_shaders.py
python tools/build_triangle_shaders.py --check
```

Проверенная цепочка: Vulkan SDK 1.3.296.0, DXC 1.8.0.4739 (d9a5e97d0),
profiles vs_6_0 / ps_6_0, -E main -O3; SPIR-V target vulkan1.0.
Обычная CMake/consumer-сборка только копирует бинарники и не требует DXC/LLVM.

Не добавлять -fvk-invert-y: SDL Vulkan сам переворачивает viewport.
Fragment input сохраняет SV_Position перед TEXCOORD0, чтобы DXIL stage
signatures согласовались с vertex output. Оба случая выявлены runtime-тестами.

## Проверки

tests/gpu_triangle.das проверяет отсутствующий/неподходящий shader файл,
недопустимый format, отказ после создания обоих shader objects (injection),
ранний return, panic, освобождённый ID, guard второго устройства, cleanup
при shutdown и отсутствие live shaders/pipelines до SDL_Quit.

Native test fixture рисует в 64×64 RGBA8_UNORM texture, скачивает её в transfer
buffer, ждёт fence и только затем читает mapping. Более 3000 пикселей сравниваются
с CPU barycentric reference: RGB interpolation и чёрный фон, alpha=255,
допуск 3/255; полоса около рёбер исключена из-за правил rasterization.
Readback пока test-only и не учитывается как публичное покрытие GPU API.

Vulkan/SPIR-V и Direct3D 12/DXIL проверяются отдельными CTest с SDL_GPU_DRIVER
только в окружении соответствующего процесса. Нет backend — SKIP 77;
ошибки shader/pipeline/readback не превращаются в SKIP. Те же контракты
включены в строгий AOT и parity двух генераторов.

Не проверены другие ОС/Metal, универсальный shader ABI, graphics buffers,
texture/sampler bindings, device loss и отсутствие всех validation diagnostics.
Debug mode не доказывает доступность validation layer. G2 завершён частично;
следующий graphics-сценарий — vertex buffers и TexturedQuad, до DSL ещё далеко.

Результаты Windows x64/MSVC 19.38: основной набор 29/29, parity/AOT 68/68,
без SKIP, включая явные Vulkan и Direct3D 12 pixel-reference tests.
Повторная offline-компиляция `--check` и SPIR-V validation прошли.
