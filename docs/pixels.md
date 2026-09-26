# Пиксельные буферы, streaming texture и render target

SDL 3.2.18, Windows x64/MSVC, закреплённый daScript. Публичный модуль:
`require dassdl3/sdl3_pixels_boost`; он переэкспортирует базовый boost.
Нативные адаптеры находятся в `src/sdl3_pixels.h`.

## Буферный контракт

`array<uint8>` принадлежит скрипту. Каждый пиксель — четыре последовательных
байта R, G, B, A; используется SDL_PIXELFORMAT_RGBA32, а не числовое значение
RGBA8888. Pitch задаётся в байтах, должен быть не меньше width * 4.
Размеры положительные. Требуется `(height - 1) * pitch + width * 4` байт:
padding после последней строки не нужен. Проверки используют 64-битную
арифметику и отклоняют результат больше INT_MAX до обращения к буферу.
`rgba8_buffer_size(width, height, pitch)` возвращает этот минимальный размер.
Пустой массив не является изображением и отклоняется. Лишние байты разрешены.

`with_streaming_texture(renderer, width, height)` создаёт RGBA32 streaming
texture. `texture |> upload_rgba8(bytes, pitch)` проверяет формат, access,
размеры и массив, затем выполняет native lock → копирование всех строк →
unlock. Между lock/unlock нет script callback, указатель никуда не сохраняется.
RAII выполняет unlock при любом нативном выходе после успешной блокировки.
Повторное использование массива после upload безопасно; содержимое прежнего
lock не читается. Это API копирования, не zero-copy mapping.

Не предлагается блок `with_locked_pixels`: возвращать borrowed slice пока
нет необходимости и доказанного запрета на его сохранение. Panic подготовки
пикселей происходит до lock; upload возвращает результат после unlock.
Проверено повторное обновление той же текстуры после отказа на неверном буфере.

## Render target и readback

`renderer |> with_target_texture(width, height) $(texture) { ... }` владеет
RGBA32 target texture. Внутри её времени жизни:

```das
let result = renderer |> with_render_target(texture) {
    let cleared = renderer |> clear(uint4(20u, 40u, 80u, 255u))
    if (is_err(cleared)) { return cleared }
    return renderer |> with_read_pixels() $(surface : SDL_Surface?) {
        return surface_size(surface) |> and_then() $(size : int2) {
            var bytes : array<uint8>
            let capacity = rgba8_buffer_size(size.x, size.y, size.x * 4)
            if (is_err(capacity)) { return err(unwrap_err(capacity),type<SdlUnit>) }
            bytes |> resize(unwrap(capacity))
            return surface |> copy_surface_rgba8(bytes, size.x * 4)
        }
    }
}
```

`with_render_target` запоминает прежнюю цель, включая null (окно), и
восстанавливает её через defer на обычном/раннем выходе. Ошибка переключения
возвращает Err и не вызывает блок. Ошибка восстановления заменяет успешный
Result тела; первичная ошибка тела сохраняется. SDL хранит viewport, clip,
scale и logical presentation отдельно для каждой цели. Draw color и blend
state эти helpers не сохраняют.

`with_read_pixels` владеет новой SDL_Surface и уничтожает её на всех путях
выхода из блока. Читается текущий viewport; размера viewport может не хватать
для всей текстуры при пользовательском clipping. Для окна читать до present.
`surface_size` возвращает Result<int2,SdlError>. `copy_surface_rgba8` конвертирует поверхность
в RGBA32, блокирует временную поверхность и копирует строки в готовый массив.
Padding массива остаётся неизменным, временная поверхность всегда освобождается.
Полученная копия живёт независимо от SDL_Surface и render target.
Readback синхронный и дорогой; пример выполняет его один раз. HDR, палитры,
YUV, произвольные форматы и частичные texture updates этим этапом не заявлены.

Все операции renderer/texture/readback выполняются в основном потоке.
SDL_Surface и SDL_Texture остаются opaque. Указатели из блоков нельзя сохранять,
уничтожать вручную или использовать после завершения scope. Обе цели должны
оставаться живы до восстановления; target scope заканчивается до уничтожения
текстуры и renderer. Unique-owner защиты от нарушений raw API пока нет.

## Примеры и проверки

- `examples/05_streaming_texture.das`: движущаяся зелёная полоса на CPU, upload,
  отображение текстуры. Сценарий взят из public-domain примера SDL
  release-3.2.18 `examples/renderer/07-streaming-textures/streaming-textures.c`.
  Это адаптация с собственным staging array и PollEvent, не точный порт C
  callback/LockTextureToSurface API. Исходник C изучен; отдельно не запускался.
- `examples/06_render_target.das`: собственный пример offscreen render → readback
  с проверкой RGB → отображение target texture.
- Оба примера без unsafe; интерактивно работают до Escape/закрытия окна,
  `--smoke-test` выполняет 60 кадров в скрытом окне.
- `tests/pixels.das`: точный RGB/alpha roundtrip изображения 3×2, разные pitch
  upload/readback, отсутствие обязательного padding последней строки,
  сохранность padding и копии после уничтожения ресурсов, неверные размеры,
  переполнение без огромных аллокаций, короткий/пустой массив, неверный access,
  повторный upload, nested target, normal/early cleanup и результат ошибки SDL.
  SDL property callbacks подтверждают порядок уничтожения поверхности и текстуры
  до teardown renderer. Stale pointers для теста не разыменовываются.

Сценарии и boost компилируются и исполняются в interpreter/строгом AOT.
Текущие сводные проверки: [gpu raw tests](gpu-raw-tests.md).
Region uploads и другие форматы renderer остаются отдельной работой.

Источники контрактов: [SDL_LockTexture](https://wiki.libsdl.org/SDL3/SDL_LockTexture),
[SDL_SetRenderTarget](https://wiki.libsdl.org/SDL3/SDL_SetRenderTarget),
[SDL_RenderReadPixels](https://wiki.libsdl.org/SDL3/SDL_RenderReadPixels);
реализация сверена с локальными заголовками 3.2.18.
