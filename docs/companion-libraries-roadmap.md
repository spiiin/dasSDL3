# Дополнительные библиотеки SDL

> Current core pin: SDL 3.4.16. See [migration and coverage changes](sdl-3.4-upgrade.md); older 3.2.18 counts below describe the original baseline.

19 сентября 2026. Это отдельные опциональные модули, не часть полноты core SDL.
Список взят из [SDL Libraries](https://wiki.libsdl.org/SDL3/Libraries).
Имена модулей и CMake options ниже — план, кроме отмеченных реализованных частей.

23 сентября: начата интеграция существующего daScript ImGui. Опция
`DASSDL3_WITH_IMGUI`, модуль `imgui_sdl3`, scoped-helper `with_imgui` и
[пример в examples/libraries](../examples/libraries/README.md) подключают
официальные SDL3 + SDLRenderer3 backends. Остальные backend'ы и дополнительные
библиотеки остаются в плане; core SDL coverage от этого не меняется.

## Версии сначала

24 сентября: SDL_image 3.2.4 подключён через `DASSDL3_WITH_IMAGE` без обновления
core SDL. Все 59 raw-деклараций, Result/defer scopes и пример `02_image` добавлены;
PNG/JPEG/alpha/GIF/IO проверены. Внешние AVIF/JXL/TIFF/WebP codecs выключены.
Точные границы и оставшиеся проверки: [SDL_image](sdl-image.md).

26 сентября: SDL_ttf 3.2.2 подключён через `DASSDL3_WITH_TTF`: 117 raw API,
Font/TextEngine/Text scopes, UTF-8, metrics и пример `03_ttf`.
HarfBuzz 10.4.0, арабский shaping и пример `04_ttf_shaping` добавлены.
GPU alpha-atlas drawing добавлен в `05_ttf_gpu` (Vulkan/Direct3D12).
PlutoSVG, paragraph bidi, GPU SDF/color/fill shaders и web остаются отдельными пунктами.
Контракты и границы: [SDL_ttf](sdl-ttf.md).

На момент первоначального исследования core был SDL 3.2.18. Прочитанные 19 сентября CMakeLists.txt веток main:
SDL_image требует SDL 3.4.0, SDL_mixer — 3.4.0, SDL_ttf — 3.2.6,
SDL_net — 3.0.0. Это требования просмотренных main snapshots, **не выбранные
версии релизов** и не обещание совместимости любых будущих commits.
SDL_sound main ищет SDL3 без указанного рядом численного минимума.

Источники: [image CMake](https://github.com/libsdl-org/SDL_image/blob/main/CMakeLists.txt),
[mixer CMake](https://github.com/libsdl-org/SDL_mixer/blob/main/CMakeLists.txt),
[ttf CMake](https://github.com/libsdl-org/SDL_ttf/blob/main/CMakeLists.txt),
[net CMake](https://github.com/libsdl-org/SDL_net/blob/main/CMakeLists.txt),
[sound CMake](https://github.com/icculus/SDL_sound/blob/main/CMakeLists.txt).

Первое действие — выбрать конкретные release tags/commits, проверить их
минимальные SDL/compiler требования, codec options и собрать matrix.
Для старого core можно выбрать совместимый старший релиз дополнения либо
обновить core отдельным шагом с регрессией. Не подключать main через FetchContent.

## План модулей

| Приоритет | Библиотека | Привязка и идиоматичный слой | Приёмочная проверка |
| --- | --- | --- | --- |
| L1 | SDL_image | `sdl3_image`: loaders для path/IO, surface/texture, format options; возврат в существующие owners | PNG/JPEG с alpha и без, повреждённые bytes, missing file; closeio ownership; пиксели и cleanup |
| L1 | SDL_ttf | `sdl3_ttf`: font owner, UTF-8, metrics/shaping; сначала surface/renderer engine, GPU engine после проверки версии и native GPU integration | Несколько шрифтов/размеров, перенос строк, non-Latin/combining text, text editing; font/engine/text lifetimes |
| G/S | SDL_shadercross | Build tool сначала; runtime binding опционально | Один asset в поддерживаемых backend formats, reflection/layout, ошибка shader compile и стабильный cache |
| L2 | SDL_mixer | `sdl3_mixer`: mixer/audio/track/group/decoder owners, load/play/stop/seek; управляемые подписки | Несколько дорожек, looping, fade, seek, completion и shutdown; offline/dummy отдельно от физического вывода |
| L2 | SDL_net | `sdl3_net`: address resolver, client/server, stream/datagram; явные state/results, bytes API | Loopback, partial read, disconnect, DNS failure, pending/cancel lifecycle, datagram bounds |
| L3 | SDL_sound | Опциональный decoder-модуль, если нужен более узкий decode-only путь | Decode chunk/rewind/EOF/error, передача PCM в core audio stream, освобождение input и sample |
| L3 | Dear ImGui | Переиспользовать daScript imgui; SDL3 events/platform + SDLRenderer3 либо SDLGPU3 backend | Mouse/keyboard/text, DPI, resize, capture routing; lifecycle context/backend/device |
| L3 | RmlUI | Отдельный C++ module, interface adapters для system/file/render/events | Один UI document, fonts/textures, event subscriptions, shutdown без удержанных script callbacks |
| L3 | SDL_gfx | Отдельный SDL3-compatible fork, primitives/surface transforms/filter arrays | Build compatibility, geometry/alpha/rotozoom, bounds и format tests |
| L3 | ControllerImage | Иконки кнопок через gamepad identification + image/render слой | Известный/неизвестный gamepad, fallback, переключение устройства, масштабирование и atlas cleanup |

### Существенные различия с SDL2

[SDL_mixer API](https://wiki.libsdl.org/SDL3_mixer/CategoryAPI) использует семейство
`MIX_*` с mixer/track/audio/group. Не строить обвязку по SDL2 примерам
`Mix_Chunk`/`Mix_Music` и старой модели channels.

[SDL_ttf API](https://wiki.libsdl.org/SDL3_ttf/CategoryAPI) включает Font, Text и
TextEngine, в том числе renderer/surface/GPU engines. План должен охватывать
эту модель, а не ограничиваться однократным render-string-to-surface.

[SDL_net API](https://wiki.libsdl.org/SDL3_net/CategoryAPI) включает асинхронное
разрешение адресов и статусы соединения. WAITING — не ошибка и не причина
безусловно блокировать render loop. Script adapter должен предоставлять
poll/update либо доставку completion на разрешённый поток.

В [Dear ImGui backends](https://github.com/ocornut/imgui/tree/master/backends)
есть SDL3 platform, SDLRenderer3 и SDLGPU3 реализации. Выбрать и закрепить
совместимые версии вместе с уже имеющимся daScript imgui binding; не создавать
вторую конкурирующую привязку всего ImGui ради SDL.

Ссылка wiki на SDL_gfx ведёт на [SDL3_gfx fork](https://github.com/sabdul-khabir/SDL3_gfx).
Проверить его сборку на выбранном SDL самостоятельно: отсутствие рабочей gfx
feature в другой языковой привязке не доказывает отсутствие SDL3 реализации.
RmlUI — C++ интерфейсы, поэтому механический генератор C API SDL не покроет
интеграцию автоматически.

## Сборка и общий контракт

Для каждого модуля — отдельная опция `DASSDL3_WITH_*`, выключенная по умолчанию
до стабильного тестирования. Поддержать find_package и закреплённый vendored
вариант. Выбранный SDL target общий для всех модулей: не собирать несколько
несовместимых копий SDL внутри одного приложения. Проверять static/shared,
CRT, runtime DLL packaging и codecs; shader toolchain не тащить в core.

Повторно использовать доступные Surface/Texture/Audio/IOStream scopes,
но соблюдать deleter каждой библиотеки. Init/refcount/shutdown модулей описать
явно. Callbacks не вызывают общий script Context из произвольного worker thread.
Сохраняемый IO/byte buffer живёт до decoder/async operation, а closeio-параметр
должен быть явным решением о передаче владения.

Для каждого дополнения: отдельный census, 1–2 примера, contract tests,
version/license/asset manifest и CI только при включённой опции. Интеграционный
пример: PNG sprite + TTF label + mixer sound; GPU-вариант после стабилизации
GPU layer. Net и UI не должны становиться зависимостями простого окна.

## SDL_net implementation

SDL_net 3.2.0 is now optional via `DASSDL3_WITH_NET`: all 34 raw exports, Result/Option boost, bounded byte adapters and loopback example/test. See [contracts and validation](sdl-net.md). Remote DNS/IPv6, other OSes and web remain follow-ups; no protocol framework was added.

## SDL_mixer implementation

SDL_mixer 3.2.4 is optional via `DASSDL3_WITH_MIXER`, using SDL 3.4.16. All 94 raw
exports, owner scopes, bounded PCM adapters and example 07 are implemented.
Native callbacks remain C addresses; script-thread subscriptions are not added.
See [contracts, codec profile and verification](sdl-mixer.md). Web, external codec
profiles, shared builds and physical-device validation remain separate work.

## SDL_sound implementation

SDL_sound 3.2.0 is optional via `DASSDL3_WITH_SOUND`: all 17 raw exports,
read-only sample metadata, Result/defer helpers and example 08 (decoder -> SDL
playback stream). See [contracts and verification](sdl-sound.md). Built-in decoder
symbols are isolated to coexist with SDL_mixer. Web, non-WAV codec fixtures,
real nonblocking IO and upstream allocation-failure IO ownership remain follow-ups.

## SDL_shadercross implementation

Pinned commit `1ff05bec573988a98ef9e0260b4da44f512b8367` is available through
`DASSDL3_WITH_SHADERCROSS`: offline CLI/incremental asset target, 15 raw functions,
owned reflection and Result helpers. The existing native SDL GPU API owns created
shader/compute objects. No shader DSL or new pipeline abstraction was introduced.
See [contracts and verification](sdl-shadercross.md). Metal execution, web, broader
resource-layout/define/include fixtures and shared/cross-platform packaging remain
follow-ups. Compiler binaries do not become a core SDL dependency.
