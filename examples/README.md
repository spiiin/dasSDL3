# Порядок изучения примеров

| Пример | Тема |
| --- | --- |
| `01_hello.das` | Запуск daScript |
| `02_square.das` | Окно, события и простая отрисовка |
| `03_input.das` | Клавиатура, мышь и текстовый ввод |
| `04_textures.das` | BMP и статические текстуры |
| `05_streaming_texture.das` | Обновление текстуры из массива пикселей |
| `06_render_target.das` | Отрисовка в текстуру и чтение пикселей |
| `07_geometry.das` | Вершины, индексы и текстурированная геометрия |
| `08_audio.das` | WAV и аудиопоток; независимая тема |
| `09_gpu_clear.das` | SDL GPU: устройство, окно и кадр |
| `10_gpu_triangle.das` | SDL GPU: готовые шейдеры и pipeline |
| `11_gpu_textured_quad.das` | SDL GPU: vertex buffer, RGBA8 texture и sampler |
| `12_gpu_indexed_quad.das` | SDL GPU: index buffer; четыре вершины и шесть индексов |
| `13_gpu_transform_quad.das` | SDL GPU: vertex uniforms; перенос, масштаб и поворот |
| `14_gpu_cube.das` | SDL GPU: 3D-камера, MVP-матрица и depth buffer |
| `15_gpu_lit_cube.das` | SDL GPU: текстура, нормали, направленный свет и nonuniform scale |
| `16_gpu_scene.das` | SDL GPU: общий depth, orbit-камера, пауза и смена порядка draw; стрелки/колесо, Space, Enter, Backspace |
| `17_gpu_instancing.das` | SDL GPU: 64 куба одним indexed draw, буфер экземпляров, вращающаяся камера |
| `18_gpu_dynamic_instances.das` | SDL GPU: независимая анимация кубов, обновление instance buffer и cycling |
| `19_gpu_instance_colors.das` | SDL GPU: индивидуальный RGBA, анимация цвета и умножение на текстуру |
| `20_gpu_material_batches.das` | SDL GPU: группировка по mesh/material, 64 объекта и две текстуры за два draw call |
| `21_gpu_frustum_culling.das` | SDL GPU: 2304 куба, frustum culling, счётчики, C — переключение, Space — пауза |
| `22_gpu_shared_geometry.das` | SDL GPU: одна геометрия, два материала, общие буферы и frustum culling |
| `23_gpu_copy_readback.das` | SDL GPU: копирование буферов, асинхронный readback, fence и точная проверка байтов; без окна |
| `24_gpu_texture_transfers.das` | SDL GPU: RGBA8 upload с pitch, копирование области в mip/layer, асинхронный readback; без окна |
| `25_gpu_formats.das` | SDL GPU: format queries, размер BC-блоков, R8 texture upload/readback |
| `26_gpu_bc_blocks.das` | SDL GPU: BC1 encoded block upload/readback, без CPU-сжатия |
| `27_gpu_cube_faces.das` | SDL GPU: независимые upload/readback шести граней cubemap |
| `28_gpu_driver_discovery.das` | SDL GPU: compiled drivers и запрос поддержки shader formats |
| `29_gpu_resource_names.das` | SDL GPU: имена checked buffer/texture ресурсов для отладки |
| `30_gpu_swapchain_capabilities.das` | SDL GPU: поддержка present modes/compositions и текущий формат swapchain |
| `31_gpu_present_modes.das` | SDL GPU: переключение поддерживаемых режимов представления между кадрами |
| `32_gpu_frame_latency.das` | SDL GPU: 1–3 кадра в полёте и ожидание доступности swapchain |
| `33_gpu_color_targets.das` | SDL GPU: initialized SAMPLER/COLOR_TARGET textures и readback |
| `34_gpu_mipmaps.das` | SDL GPU: генерация mip-цепочки с CPU average reference |
| `35_gpu_scaled_blit.das` | SDL GPU: nearest blit 2x2 → 4x4 с побайтной проверкой |
| `36_gpu_command_plan.das` | SDL GPU: зависимые копии одним submit, labels/groups и readback |

Из корня проекта:

```powershell
./third_party/daScript/bin/daslang_static.exe examples/01_hello.das
./build/ninja/bin/dasSDL3_runner.exe examples/02_square.das
```

Остальные примеры запускаются тем же runner. Для ограниченного автоматического
запуска добавьте `--smoke-test`. GPU-примерам нужен поддерживаемый backend;
они используют отдельный от SDL_Renderer API.
