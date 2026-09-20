# Документация dasSDL3

## Начать

- [Сборка и запуск](../README.md), [примеры](../examples/README.md).
- [Покрытие](api-coverage.md), [реестр](api-inventory.md), [следующие этапы](full-binding-roadmap.md).
- [Граница публичного API](gpu-api-boundary.md), [ошибки и defer](error-handling.md).

## Генерация и идиомы

- [Установка dasClangBind](clangbind-setup.md), [production snapshots](clangbind-production.md).
- [Parity](clangbind-parity.md), [типы и AOT](clangbind-types-aot.md).
- [dasBGFX idioms](bgfx-idioms.md), [design review](binding-design-review.md), [boost](sdl3-boost.md).

## API

- [Properties](properties.md): values, copied strings/names and defer ownership.

- [Ввод](input.md), [аудио](audio.md), [пиксели](pixels.md), [geometry](geometry.md).
- GPU: [native API](gpu-native-api.md), [native boost](gpu-native-boost.md),
  [результаты](gpu-native-validation.md), [raw tests](gpu-raw-tests.md).
- Checked GPU subset: [recording](gpu-recording.md), [buffers](gpu-transfer.md),
  [textures](gpu-texture-transfer.md), [formats](gpu-formats.md), [BC/cube](gpu-texture-types.md),
  [volumes](gpu-volume.md), [ASTC](gpu-astc.md), [image operations](gpu-image.md),
  [swapchain settings](gpu-swapchain.md), [shaders](gpu-shaders.md),
  [samplers](gpu-samplers.md), [pipelines](gpu-pipelines.md).
- [Multi-device layer conflict](gpu-multidevice.md).

## Отдельные направления

- [GPU maintenance и shader DSL](gpu-roadmap.md).
- [Порты примеров](porting-matrix.md), [SDL companion libraries](companion-libraries-roadmap.md).

Документы удалённого engine API убраны; история остаётся в Git.
Актуальные числа покрытия находятся в api-coverage и generated census,
результаты последнего GPU этапа — в gpu-native-validation.

- [Hints/Init](init-hints.md): priorities, copied strings and subsystem defer scopes.

- [Error/log/time](diagnostics-time.md): literal messages, clocks and calendar conversions.

- [Video discovery](video-discovery.md): drivers, display modes and window query lifetimes.

- [Window state](window-state.md): creation, parent/child ownership and state changes.

- [Window fullscreen/surface/IO](window-io.md): borrowed surfaces, ICC and capability limits.

- [Software renderer/primitives](renderer-primitives.md): surface lifetime and CPU pixel checks.

- [Renderer state](renderer-state.md): viewport, clipping, scale and target output.

- [Renderer queries/presentation](renderer-presentation.md): names, logical modes and window coordinates.

- [Texture creation/state](texture-state.md): native access modes, properties, modulation and filtering.

- [Texture bytes/transfer](texture-transfer.md): byte modulation, blending, region updates and borrowed locks.

- [Renderer YUV/color/blend](renderer-yuv-blend.md): plane arrays, renderer color and custom composition.

- [Renderer operations](renderer-operations.md): creation, transformed drawing, readback, VSync and debug text.

- [Renderer final APIs](renderer-final-api.md): raw geometry, event conversion, fixed-text format and native interop limits.
