> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# SDL GPU ClearScreen

Первый ограниченный GPU-сценарий для SDL 3.2.18. Он отделён от SDL_Renderer:
`require dassdl3/sdl3_gpu_boost`. Реализация — `src/sdl3_gpu.h`.

```daslang
with_sdl() {
    with_gpu_device() $(device) {
        with_window("GPU", 640, 480, SDL_WINDOW_RESIZABLE) $(window) {
            device |> with_gpu_window(window) {
                device |> gpu_clear(window, float4(0.1, 0.2, 0.4, 1.0))
            }
        }
    }
}
```

Полный цикл событий — `examples/09_gpu_clear.das`. Запуск из корня:
`./build/ninja/bin/dasSDL3_runner.exe examples/09_gpu_clear.das`.
`--smoke-test` требует 60 отправленных кадров. При отсутствии GPU backend
он возвращает 77, который CTest показывает как SKIP, а не успешную GPU-проверку.
Ошибка claim/recording/submit после создания устройства остаётся ошибкой теста.

## Владение и ошибки

- Все операции выполняются в основном потоке, где создано окно.
- Устройство и окно должны жить дольше `with_gpu_window`. Release claim
  выполняется до DestroyWindow, а DestroyGPUDevice — до SDL_Quit.
- Scoped API поддерживает несколько активных GPU devices; registry и cleanup
  разделены по device. Диагностика Vulkan overlay — `gpu-multidevice.md`.
- `try_with_gpu_device(formats, debug, driver, block)` возвращает false только
  при ошибке создания устройства. Пустой driver выбирает автоматически.
  `with_gpu_device` использует debug mode и набор GPU_CLEAR_FORMATS.
  Этот набор достаточен для clear без шейдеров; он не доказывает, что будущий
  shader binary поддерживается выбранным устройством.
- Scope ловит panic, освобождает ресурс и повторяет исходную ошибку.
  Перед release/destroy выполняется WaitForGPUIdle. Если ожидание не удалось,
  очистка всё равно продолжается, её диагностика добавляется к исходной ошибке.
- Повторный scoped claim и окно с SDL_Renderer отклоняются. Нельзя смешивать
  raw claim/release/destroy с активными scopes.
- Указатели устройства/окна всё ещё копируемы. Scopes не обеспечивают линейное
  владение и не защищают от сохранённого после закрытия указателя. Общие
  GPU handles с generation/state checks — следующий отдельный этап.

## Кадр

`gpu_clear(device, window, rgba[, size])` принимает конечные компоненты 0..1.
Возвращает true после успешного submit, false при отсутствии drawable texture.
Размер в пикселях возвращается только при успешной отправке, иначе обнуляется.
Ошибки превращаются в panic. Present mode остаётся стандартным SDL (VSYNC).

Command buffer, render pass и borrowed swapchain texture остаются внутри C++.
Во время записи нет script callbacks. `SDL_GPUClearFrame<API>` реализует
одну и ту же последовательность для настоящего backend и тестового mock:

1. Acquire command buffer. При ошибке завершать нечего.
2. WaitAndAcquire swapchain. Успех с NULL — cancel и пропуск кадра.
3. После ненулевой texture cancel запрещён, даже если acquisition сообщил
   ошибку: закреплённый SDL_gpu.c выставляет флаг по выходному указателю.
4. Clear/store render pass, end, submit. При ошибке begin — submit без pass.
5. Submit потребляет command buffer независимо от результата; повторных
   submit/cancel нет. При ошибке acquisition/begin сохраняется её сообщение,
   а ошибка finalization добавляется к нему.

Контракты SDL: [acquisition](https://wiki.libsdl.org/SDL3/SDL_WaitAndAcquireGPUSwapchainTexture),
[cancel](https://wiki.libsdl.org/SDL3/SDL_CancelGPUCommandBuffer),
[submit](https://wiki.libsdl.org/SDL3/SDL_SubmitGPUCommandBuffer).
Это закрытая операция clear, не универсальный `with_frame` с rollback.

## Проверки и границы

`tests/gpu_state.das` вызывает production state machine с mock backend:
10 последовательностей успеха/отказа, пропуск drawable, отсутствие cancel после
acquisition, single submit, сохранение двух ошибок, размеры и invalid colors.
GPU не требуется; fake handles никогда не передаются настоящему SDL.

`tests/gpu.das` проверяет реальные scopes: invalid driver, normal/early return,
panic/reclaim, resize с последующим кадром, unclaimed window и конфликт renderer.
Счётчики проверяют cleanup до SDL_Quit. Все GPU scripts включены в
interpreter parity обоих генераторов и строгий AOT.

`tests/gpu_windows.das` проверяет два одновременно claimed окна на одном device.
В двух циклах второе окно сворачивается, первое продолжает отправлять кадры,
затем второе восстанавливается и меняет размер. После normal и panic cleanup
внутреннего окна внешнее продолжает рисовать; счётчик claim меняется 2 → 1 → 0.
Minimize/restore подтверждаются фактическим SDL_WINDOW_MINIMIZED после SyncWindow
и ограниченного ожидания с PumpEvents. Отказ оконной системы даёт SKIP 77;
ошибка SDL или отрисовки остаётся ошибкой теста.

Сворачивание не гарантирует NULL swapchain: pinned SDL_gpu.h говорит «can».
На проверенном Vulkan оба свёрнутых кадра успешно отправлены (2 submitted,
0 skipped). Тест принимает оба допустимых исхода, проверяя соответствующие
размеры; реальный NULL в этом запуске не наблюдался. Его путь проверяет mock.

Не доказаны device loss на реальном железе, pixel readback и отсутствие
диагностик validation layers; другие GPU backends пока не проверены.
Debug mode само по себе не гарантирует, что validation layer установлен.
Сценарии окна G1 проверены на Vulkan. Общая модель command/pass handles ещё
отсутствует: G0/G1 roadmap остаются частичными. BasicTriangle с готовыми
shader binaries и проверяемыми pipeline IDs добавлен в `gpu-triangle.md`.
DSL остаётся поздним этапом.

После добавления Triangle проверено на Windows x64/MSVC 19.38: основной набор 29/29, parity/AOT 68/68,
без пропусков. GPU backend при прямом запуске — Vulkan, 60 кадров 640×480.
Снимки обоих генераторов: 60 функций, 10 records, 49 полей, 7 opaque types,
47 констант. Это покрытие выборки, а не всего SDL GPU.
Consumer с BUILD_TESTING=OFF, генераторами/Clang/LLVM/Python discovery OFF
также собран из сохранённых снимков и отправил 60 кадров через Vulkan.
