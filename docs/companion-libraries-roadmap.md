# Дополнительные библиотеки SDL

19 сентября 2026. Это отдельные опциональные модули, не часть полноты core SDL.
Список взят из [SDL Libraries](https://wiki.libsdl.org/SDL3/Libraries).
Предлагаемые имена модулей и CMake options ниже ещё не реализованы.

## Версии сначала

Текущий core — SDL 3.2.18. Прочитанные 19 сентября CMakeLists.txt веток main:
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
| L1 | SDL_ttf | `sdl3_ttf`: font owner, UTF-8, metrics/shaping; сначала surface/renderer engine, GPU engine после G2–G4 | Несколько шрифтов/размеров, перенос строк, non-Latin/combining text, text editing; font/engine/text lifetimes |
| G/S | SDL_shadercross | Build tool сначала; runtime binding опционально | Один asset в поддерживаемых backend formats, reflection/layout, ошибка shader compile и стабильный cache |
| L2 | SDL_mixer | `sdl3_mixer`: mixer/audio/track/group/decoder owners, load/play/stop/seek; управляемые подписки | Несколько дорожек, looping, fade, seek, completion и shutdown; offline/dummy отдельно от физического вывода |
| L2 | SDL_net | `sdl3_net`: address resolver, client/server, stream/datagram; Result/Option для state, bytes API | Loopback, partial read, disconnect, DNS failure, pending/cancel lifecycle, datagram bounds |
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

Повторно использовать owners Surface/Texture/IOStream/Audio и SdlError из core,
но соблюдать deleter каждой библиотеки. Init/refcount/shutdown модулей описать
явно. Callbacks не вызывают общий script Context из произвольного worker thread.
Сохраняемый IO/byte buffer живёт до decoder/async operation, а closeio-параметр
должен быть явным решением о передаче владения.

Для каждого дополнения: отдельный census, 1–2 примера, contract tests,
version/license/asset manifest и CI только при включённой опции. Интеграционный
пример: PNG sprite + TTF label + mixer sound; GPU-вариант после стабилизации
GPU layer. Net и UI не должны становиться зависимостями простого окна.
