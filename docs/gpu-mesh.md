> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# SDL GPU: vertex buffer и TexturedQuad

`examples/11_gpu_textured_quad.das` объединяет первый vertex buffer с sampled
texture. `require dassdl3/sdl3_gpu_mesh_boost` предоставляет
`with_gpu_textured_mesh(device, window, vertices, pixels, width, height,
vertex_file, fragment_file, format) $(mesh) { ... }` и
`device |> gpu_draw_textured_mesh(window, mesh)`.

Mesh — immutable пакет vertex buffer + RGBA8 texture + nearest clamp sampler +
pipeline с проверяемым монотонным uint64 ID. Конкретный layout: `array<float4>`,
компоненты x/y — координаты NDC, z/w — UV 0..1; stride 16, два float2 attributes
locations 0/1. Проверяются конечность всех компонентов, кратность числа вершин
трём, непустые массивы, точный размер RGBA8 `width*height*4`. Ограничения: до
1048576 вершин, до 8192 на каждую сторону, до 16 MiB пикселей. Умножения сначала
проверяются в uint64; источник может быть освобождён сразу после создания.

Нативный upload копирует оба массива в transfer buffer, выполняет copy pass,
submit и освобождает staging resource через SDL deferred release. Перед возвратом
нет retained script pointer. Texture upload offset выравнивается на 512 байт;
SDL D3D12 сам переупаковывает строки с pitch, не кратным 256. Draw на том же
устройстве упорядочен после upload. Mapping/command/pass никогда не выдаются
скрипту. Draw использует общий SDL_GPUFrame с прежними правилами submit/cancel.

Scope освобождает ресурсы при return/panic, сохраняя текст исходной ошибки.
Device cleanup registry удаляет также оставленные mesh IDs; после release,
двойного release и передачи чужого device операции отклоняются. Регистры pipeline
и mesh используют общий монотонный счётчик ID: число другого типа не совпадёт
с действующим ID в другом регистре и будет отвергнуто до native GPU операции.
Raw device/window pointers всё ещё требуют правильного времени жизни.

Шейдеры — только доверенные offline assets: main entry, vertex attributes
locations 0/1, fragment sampler 0, никаких uniforms/storage/depth/blending.
HLSL texture/sampler register t0/s0 space2 соответствует SDL SPIR-V fragment set2;
для SPIR-V обязательны `vk::combinedImageSampler` attributes на обеих декларациях,
иначе DXC создаёт два отдельных descriptor вместо ожидаемого SDL combined binding.
DXIL использует те же исходники без этих attributes. Не добавлять Vulkan Y-inversion.

```powershell
python tools/build_triangle_shaders.py --mesh
python tools/build_triangle_shaders.py --mesh --check
./build/ninja/bin/dasSDL3_runner.exe examples/11_gpu_textured_quad.das
```

Обычная сборка копирует готовые SPIR-V/DXIL и не требует DXC/LLVM. Manifest
содержит SHA-256 файлов, контракт и версию компилятора; это не shader reflection.

`tests/gpu_mesh.das` проверяет размеры без больших выделений, недопустимый UV,
отсутствующие шейдеры и cleanup частичного shader создания, return/panic,
stale/foreign ID, реальные кадры. Test-only native readback сравнивает более
3000 пикселей RGBA8 с четырьмя ожидаемыми цветными квадрантами и чёрным фоном;
CPU массивы очищены до draw/readback. Проверки предназначены для interpreter и
строгого AOT, Vulkan и Direct3D 12; недоступный backend даёт SKIP 77.
Два реальных устройства рисуют и читают свои mesh; после уничтожения второго
первое снова проходит pixel reference. Foreign release отклоняется в обе стороны;
shutdown намеренно оставленных IDs не затрагивает ресурсы другого устройства.

Это ограниченный graphics-сценарий: ещё нет отдельного публичного buffer/texture
builder, dynamic updates, arbitrary vertex layouts, mipmaps,
uniforms, общего resource reflection и device-loss recovery. Readback остаётся
test-only и не считается публичным API. Не называть этот этап полным GPU binding.

Дополнение: immutable UINT32 index buffer и indexed draw реализованы отдельной
фабрикой и scope, описанными в `gpu-indexed-mesh.md`. Обычный mesh сохраняет
свой sequential triangle-list контракт.

Проверено 2026-09-19 на Windows x64/MSVC: основной набор 36/36, parity/strict AOT
81/81, без SKIP. Consumer с BUILD_TESTING=OFF, отключёнными генераторами и
Clang/LLVM/Python discovery собран и отправил по 60 кадров на Vulkan и D3D12.
В Vulkan тестах этой машины исключён FPS Monitor layer; debug mode сохранён.
Причина и настройка — `gpu-multidevice.md`. SPIR-V/DXIL повторно скомпилированы
с `--mesh --check`, SPIR-V проверен spirv-val, manifest integrity проходит.
