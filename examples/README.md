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

Из корня проекта:

```powershell
./third_party/daScript/bin/daslang_static.exe examples/01_hello.das
./build/ninja/bin/dasSDL3_runner.exe examples/02_square.das
```

Остальные примеры запускаются тем же runner. Для ограниченного автоматического
запуска добавьте `--smoke-test`. GPU-примерам нужен поддерживаемый backend;
они используют отдельный от SDL_Renderer API.
