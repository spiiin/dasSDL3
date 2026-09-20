# Покрытие SDL3

Целевая версия: SDL 3.2.18. Это список реализованных сценариев, а не заявление
о полном покрытии подсистем. `tools/bindings.json` задаёт точный перечень
экспортов; `src/generated/api.json` содержит полученные из Clang сигнатуры.
Сейчас генерируются 60 функций SDL. Ручные адаптеры перечислены отдельно.
В актуальной policy: 69 adapted и 1097 pending (1226 функций Windows-профиля).
[Текущий приоритет](gpu-roadmap.md): завершение P6 GPU API; Properties отложен;
увеличение числа GPU-примеров не является мерой полноты SDL3.

Первый автоматический реестр активного API Windows x64 и его ограничения:
`api-inventory.md`, `generated/api-windows-x64-msvc.md`. Он не заменяет
сценарную таблицу и не включает неактивные объявления других платформ.

| Подсистема / сценарий | Raw API | Идиоматичный слой | Проверка / оставшаяся работа |
| --- | --- | --- | --- |
| Инициализация, ошибки, время | GetVersion, Init, Quit, WasInit, GetError, GetTicks, Delay | sdl_init, with_sdl; ошибки операций превращаются в panic | bindings, boost; прочие подсистемы Init не покрыты |
| Окно и renderer | Create/DestroyWindow, Create/DestroyRenderer, GetWindowID, GetWindowFromID, GetRenderer, SetWindowTitle | create/destroy, with_window, with_renderer, set_title | square, boost; управление окнами пока частичное |
| События | PollEvent, PushEvent, PumpEvents; SDL_Event.event_type | poll_event, push_event, should_close(event[, window]), input_window_id | input: фильтрация union и адресация окон; остальные варианты union впереди |
| Простая отрисовка | SetRenderDrawColor, RenderClear, RenderFillRect, RenderPresent | set_color, clear, fill_rect, present | square, boost; остальные примитивы впереди |
| BMP / поверхности | LoadBMP, DestroySurface | load_bmp, destroy_surface, with_bmp | textures: нормальный/ранний выход, panic, ошибка создания текстуры; пиксельные буферы поверхности не раскрыты |
| Статические текстуры | CreateTextureFromSurface, DestroyTexture, GetTextureSize, RenderTexture | create_texture, load_texture, destroy_texture, texture_size, with_texture, draw_texture (3 перегрузки) | textures: размеры, чтение пикселей, освобождение до renderer, отсутствующий файл |
| Путь к ресурсам примера | GetBasePath | пример строит путь к assets рядом с exe | запуск не зависит от текущей папки; универсального файлового слоя ещё нет |
| Geometry | RenderGeometry; FPoint, FColor и Vertex с вложенными полями | vertex, draw_geometry(vertices[, indices][, texture]) | geometry: точные пиксели, indexed/sequential parity, пустые массивы, границы, NaN/Infinity, время жизни в interpreter/AOT |
| Streaming / render-target текстуры | Get/SetRenderTarget; создание/lock/readback через частичные адаптеры | with_streaming_texture, upload_rgba8, with_target_texture, with_render_target, with_read_pixels, surface_size, copy_surface_rgba8 | pixels: pitch, границы, RGBA roundtrip, cleanup и nested target в interpreter/AOT; region updates и прочие форматы впереди |
| Аудио | LoadWAV/free, Create/DestroyAudioStream, Put/GetAudioStreamData, GetAvailable/Queued/Format/Device, Flush/Clear, Pause/Resume/DevicePaused | with_wav, with_audio_stream, with_playback; queue_wav, put/read_audio и управление очередью | audio: PCM-копии, ресэмплинг, размеры, очистка и dummy; физическое устройство/микрофон/callbacks впереди |
| Клавиатура и мышь | GetKeyboardState, GetMouseState; Keyboard/Motion/Button/Wheel структуры | key_event, key_scancode, key_down, mouse_*_event, wheel_delta, mouse_state | input: Down/Up, repeat/mod, координаты, клики, FLIPPED, границы индекса; относительный режим/захват впереди |
| Текстовый ввод | StartTextInput, StopTextInput, TextInputActive, ClearComposition | text_input_event, text_editing_event, with_text_input | input: копии UTF-8 и вложенные сеансы при panic; реальная IME, кандидаты, область ввода ещё не проверены/не реализованы |
| Геймпады | Нет | Нет | Отдельный этап |
| Callbacks, потоки | Нет | Нет | Нужен контракт времени жизни замыканий и потока вызова |
| GPU ClearScreen | Create/DestroyGPUDevice, driver/formats, claim/release, wait idle; 6 команд кадра через частичный native adapter | with_gpu_device, try_with_gpu_device, with_gpu_window, gpu_clear | gpu_state, gpu, gpu_windows, gpu_clear: resize, minimize/restore, два окна и независимый cleanup; оставшиеся G0/G1 проверки в gpu-clear.md |
| GPU BasicTriangle | Shader/pipeline create/release, target format, bind и draw через 7 частичных adapters | with_gpu_vertex_id_pipeline, gpu_draw_triangle; checked uint64 IDs | gpu_triangle/gpu_devices: SPIR-V/Vulkan и DXIL/D3D12, CPU pixel reference, два реальных device и независимый cleanup; диагностика overlay в gpu-multidevice.md |
| Файловый IO, остальные подсистемы | Нет | Нет | Отдельные этапы |
| GPU TexturedQuad | Buffer/texture/sampler/transfer create/release, map/unmap, copy/upload, vertex/sampler bind через 16 частичных adapters | with_gpu_textured_mesh, gpu_draw_textured_mesh; immutable packed float4 NDC/UV + RGBA8, checked uint64 IDs | gpu_mesh: copied arrays, bounds, stale/foreign IDs, scopes, два устройства, >3000 reference pixels на Vulkan/D3D12; dynamic/general layouts впереди; docs/gpu-mesh.md |
| GPU IndexedQuad | BindGPUIndexBuffer, DrawGPUIndexedPrimitives через 2 частичных adapters | with_gpu_indexed_textured_mesh; immutable UINT32 indices, общий mesh draw/release | gpu_indexed_mesh: CPU reference, invalid/empty indices, copied arrays, cleanup, два устройства; UINT16/draw ranges впереди; instancing отдельным ABI ниже; docs/gpu-indexed-mesh.md |
| GPU TransformQuad | PushGPUVertexUniformData через частичный adapter | with_gpu_transform_mesh, gpu_draw_transform_mesh; translation/scale/angle, две float4 строки | gpu_transform: пять CPU pixel references, uniform ABI, invalid/stale/foreign checks, два devices, panic; matrices/fragment uniforms впереди; docs/gpu-transform.md |
| GPU 3D Cube | TextureSupportsFormat, cached depth texture, pipeline depth state, 64-byte MVP uniform; GetWindowSizeInPixels для aspect | with_gpu_3d_mesh, gpu_draw_3d_mesh, gpu_camera, gpu_window_aspect | gpu_3d: CPU projection/depth pixels, оба порядка треугольников, resize/cache failure, panic и два devices; общий scene/pass builder впереди; docs/gpu-3d.md |
| GPU LitCube | PushGPUFragmentUniformData через частичный adapter, textured depth pipeline | with_gpu_lit_mesh, gpu_draw_lit_mesh; affine inverse-transpose normals, Lambert light | gpu_lit: CPU UV/normal/lighting reference, nonuniform/negative scale, copied arrays, panic, resize и два devices; docs/gpu-lit.md |
| GPU LitScene | Существующие GPU adapters: один render pass, общий cached depth, bounded draw list | with_gpu_lit_scene, GpuLitDrawList, gpu_scene_add/clear, gpu_draw_lit_scene | gpu_scene: cross-object CPU depth pixels, per-object uniforms, atomic preflight, resize/failure, empty/repeated draws и два devices; docs/gpu-scene.md |
| GPU Instancing | Existing partial GPU adapters, second vertex buffer and instance count | GpuInstanceList; scoped copied 1..4096 models, one indexed draw | CPU pixels, depth/order, normal transforms, lifetime/preflight; docs/gpu-instancing.md |
| GPU Dynamic instances | Existing map/upload adapters with cycling | gpu_update_instances; full replacement, fixed count | 12 queued CPU-reference snapshots, rejected updates preserve data, failed-submit recovery and cleanup; docs/gpu-dynamic-instances.md |
| GPU Instance RGBA | Existing adapters, explicit stride128 color ABI | GpuColoredInstanceList; copied finite normalized RGBA, full cycled updates | Texture/light/alpha CPU pixels, invalid colors, incompatible updates, queued snapshots and cleanup; docs/gpu-instance-colors.md |
| GPU Material batches | Existing adapters, checked instance-buffer byte slices | GpuBatchList; exact mesh ID grouping, shared depth, 0..4096 objects / <=64 groups | Cross-group depth/texture pixels, queued variable groups, preflight, recovery and cleanup; docs/gpu-material-batches.md |
| GPU Frustum culling | No new SDL symbols; script math/filtering | GpuFrustum, gpu_sphere_visible, gpu_batch_add_visible | Clip-space oracle, affine sphere support, full/culled pixels on both backends, empty frame; docs/gpu-frustum-culling.md |
| GPU Shared resources | Existing SDL symbols, separate geometry/material adapters | with_gpu_geometry/material/shared_mesh; borrowed pair IDs | Buffer identity, pair coalescing, mixed draws, pending release, stale parents and CPU pixels; docs/gpu-shared-resources.md |

Ручные адаптеры: PollEventRef, PushEventRef, RenderFillRectRef,
GetTextureSizeRef, RenderTextureToRect, RenderTextureRects. Они используют
адреса только во время синхронного вызова. Также есть фабрики MakeEvent,
MakeKeyEvent, MakeFRect и проверки EventIsQuit/EventIsEscape (префикс SDL_).
Адаптеры ввода описаны в `input.md`: ReadKey/Mouse/Text, KeyScancode,
MouseWheelFlipped, InputWindowID, IsScancodeDown, GetMouseStateRef.
Служебные SDL_InvokeScope и SDL_InvokeWindow/Renderer/Surface/Texture восстанавливают аргументы
блоков интерпретатора при panic; это синхронный механизм для with_* нашего
boost-слоя, а не привязка асинхронных callbacks SDL.

Тестовые SDLTest* экспортируются только при BUILD_TESTING=ON и не являются
публичной обвязкой SDL. Cleanup callbacks на SDL properties фиксируют
уничтожение поверхности/текстуры до очистки renderer; stale pointers не читаются.
RenderReadPixels теперь также доступен через публичный адаптер SDL_ReadPixelsOwned
и scoped helper; ReadSurfacePixel остаётся только внутри тестового C++ адаптера.

При расширении обновлять эту таблицу, спецификацию генератора, boost-слой и
проверку соответствующего сценария. AOT проверен отдельным parity-проектом;
пока не проверены JIT, другие ОС,
другие версии SDL, уникальное владение и защита от висячих указателей.

Аудио: `docs/audio.md`. OpenAudioDeviceStream пока доступен через ручной
адаптер без callback. SDL_Wav — собственный непрозрачный тип владения,
а не структура SDL. Формат SDL_AudioSpec читается через audio_format.

Пакеты 26–29: typed transfers расширены на BC и cube/array, а пять новых
публичных SDL-контрактов покрывают compiled-driver enumeration, shader-support
query и naming checked buffer/texture IDs. После этого этапа: 7 generated, 50 adapted,
35 pending. Границы и проверка: [gpu-texture-types.md](gpu-texture-types.md).

Пакеты 30–32: пять новых частичных GPU-контрактов для swapchain capability
queries, configuration, frames-in-flight и availability wait; существующий
GetGPUSwapchainTextureFormat теперь доступен как checked uint query. После этого этапа
GPU census: 7 generated / 55 adapted / 30 pending. См. `gpu-swapchain.md`.

Пакеты 33–35: initialized color-target textures и два новых частичных SDL
контракта — GenerateMipmapsForGPUTexture, BlitGPUTexture. Проверяются CPU pixel
references, регионы, mip/layer и lifetime. Текущий GPU census:
7 generated / 57 adapted / 28 pending; [gpu-image.md](gpu-image.md).

Command-plan batch (9 steps): borrowed checked resource IDs, mixed operations
and one native submission; labels and balanced groups add three partial SDL
contracts. Current GPU census: 7 generated / 60 adapted / 25 pending.
D3D12 groups explicitly unsupported on pinned SDL; labels supported on both
backends. General command/pass API remains pending; see gpu-command-plans.md.
