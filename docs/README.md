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
