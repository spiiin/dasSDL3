# Несколько SDL GPU devices и Vulkan layers

Исследование 2026-09-19, Windows x64, RTX 4080 Laptop, SDL 3.2.18.
Прежний запрет второго scoped device снят. Устройства регистрируются независимо;
при shutdown освобождаются только pipeline/mesh IDs соответствующего device.
Операции остаются на main thread, scopes заканчиваются до SDL_Quit.

## Причина наблюдавшегося падения

Native C++ repro без daScript создаёт A, рисует triangle, создаёт и уничтожает B,
затем снова рисует A и освобождает ресурсы. Сбой воспроизводится в Vulkan loader
при обычном наборе implicit layers. Это исключает вложенные script blocks как
необходимое условие сбоя.

На этой машине `C:/Program Files (x86)/FPS Monitor/tools/fpsmonvk64.json`
регистрирует `fpsmonvk64.dll` под именем **VK_LAYER_RENDERDOC_Capture** и описанием
**FPSMonitor layer**. Имя слоя само по себе не означает, что установлен RenderDoc.

| Native repro, debug=true кроме указанного | Результат |
| --- | --- |
| Обычный набор layers | Access violation; лог подтверждает загрузку FPS Monitor DLL |
| debug=false | PASS |
| Отключены все implicit layers | PASS, Khronos validation остаётся |
| Отключён только VK_LAYER_RENDERDOC_Capture | PASS, Khronos validation и OBS остаются |
| Отключён только OBS hook | Access violation |

Таким образом, установленный FPS Monitor layer является воспроизводимым условием
сбоя. Внутренняя ошибка его закрытой DLL не установлена; SDL и daScript source
не исправлялись. Обход конфликта — исключить этот слой в процессе приложения.
Системный registry, установка FPS Monitor и глобальное окружение не меняются.

## Запуск

```powershell
./build/ninja/bin/dasSDL3_runner.exe tests/gpu_devices.das --smoke-test --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
./build/ninja/bin/dasSDL3_runner.exe examples/11_gpu_textured_quad.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

Runner добавляет фильтр к существующему `VK_LOADER_LAYERS_DISABLE` до инициализации
SDL. Флаг можно повторять; без него поведение не меняется. Если на другой машине
под этим именем зарегистрирован RenderDoc, фильтр отключит именно его.

Для CTest обоих CMake-проектов есть необязательная cache-переменная:

```powershell
cmake -S . -B build/ninja -DDASSDL3_TEST_VULKAN_LAYERS_DISABLE=VK_LAYER_RENDERDOC_Capture
ctest --test-dir build/ninja -R gpu_devices --output-on-failure
```

По умолчанию фильтр пуст. Настройка действует на GPU test processes и сохраняет
их SDL_GPU_DRIVER. Фильтрация layers требует Vulkan loader с поддержкой этих
переменных (1.3.234+); здесь loader 1.4.304.0. См.
[Khronos Loader debugging](https://github.com/KhronosGroup/Vulkan-Loader/blob/main/docs/LoaderDebugging.md).
Не отключать validation вместо локализации конфликтующего overlay.

## Регрессия

`tests/gpu_devices.das` выполняет три цикла создания/уничтожения B при живом A,
рисует обоими, проверяет чужие/stale IDs и запрещает повторный claim окна.
Проверяет обычный, ранний и panic выход, счётчики ресурсов до SDL_Quit и draw A
после каждого shutdown B. Включён в interpreter, обе генерации и strict AOT;
Vulkan и Direct3D 12 имеют отдельные тесты. Отсутствующий первый backend — SKIP77;
ошибка второго устройства или rendering — failure.

Это проверка двух SDL logical devices на доступном GPU, не multi-adapter тест.
Сохранённые device/window pointers нельзя использовать после scope: копируемость
указателей и отсутствие generation ID для самих устройств остаются ограничением.

Результат: основной набор 36/36 и parity/strict AOT 81/81, без SKIP, включая
отдельные Vulkan/D3D12 multi-device tests. Mesh regression дополнительно
проверяет readback A после shutdown B и cleanup оставленных B mesh IDs.
