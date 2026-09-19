# Аудит покрытия и следующая вертикаль

**Текущий приоритет пользователя:** вернуться к P6 и завершать GPU API.
Предложенная ниже очередь с Properties отложена. Ближайший блок —
публичные transfers/readback, затем command/pass state, graphics и compute;
см. [GPU-план](gpu-roadmap.md).


Аудит 19 сентября 2026, после примера 22. Это решение об очереди привязки SDL3,
а не продолжение разработки собственного графического движка. API Properties
в этой итерации ещё не реализован.

## Источники и метод

Источник сигнатур — локальные заголовки закреплённой SDL 3.2.18, а не текущая
wiki. Повторно запущены inventory_api.py и генераторы saved snapshots; реестр
содержит 85 headers, 4671 декларацию/макрос, профиль windows-x64-msvc. Проверены
bindings.json, api-policy.json, регистрация native adapters, соответствующие
boost-модули и тесты. Для кандидата Properties прочитан SDL_properties.h,
включая CopyProperties, string lifetime, enumeration callback и locking.

Полная таблица категорий: [generated inventory](generated/api-windows-x64-msvc.md).
Список всех оставшихся имён и сигнатур: [JSON inventory](generated/api-windows-x64-msvc.json).
Это Windows-профиль активных веток заголовков, не объединение Linux/macOS/mobile.
Наличие всех headers в профиле не доказывает проверку всех платформенных веток.

## Состояние

- 1226 активных функций: **60 generated, 43 adapted, 1123 pending**.
- 53 категории; в 39 категориях ни одной функции ещё не отмечено generated/adapted.
- 92 enum declarations остаются pending; это не противоречит 21 отдельно
  экспортированной enum-константе. Общая поддержка enum-типов не реализована:
  текущий clangbind_parity.das пропускает parse_Enum.
- 159 record declarations: 10 partial, 6 opaque, 143 pending. Одноимённые typedef
  считаются отдельно и не должны удваивать число пользовательских типов.
- 47 выбранных констант: 21 enumerator и 26 macro. Это не все SDL flags/constants.

Generated означает наличие raw export, adapted — документированный ограниченный
путь через native adapter. Ни то ни другое не означает полный boost-контракт
или полную подсистему. 103/1226 нельзя представлять как процент готовности
библиотеки: функции имеют разный объём, ещё нужны типы, ABI, ownership, callbacks,
платформы и упаковка. SDLTest* и код примеров в публичное покрытие не входят.

| Категория | Функций | Generated | Adapted | Pending |
| --- | ---: | ---: | ---: | ---: |
| Properties | 21 | 0 | 0 | 21 |
| Hints | 8 | 0 | 0 | 8 |
| Init | 10 | 3 | 0 | 7 |
| IOStream | 48 | 0 | 0 | 48 |
| Video | 109 | 5 | 1 | 103 |
| Render | 89 | 14 | 4 | 71 |
| Events | 19 | 3 | 0 | 16 |
| Gamepad | 73 | 0 | 0 | 73 |
| Joystick | 58 | 0 | 0 | 58 |
| Audio | 56 | 14 | 1 | 41 |
| GPU | 92 | 7 | 34 | 51 |
| Surface | 58 | 2 | 3 | 53 |

## Что обнаружено в учёте

До аудита было 42 adapted / 1124 pending. SDL_OpenAudioDeviceStream уже доступен
как SDL_OpenPlaybackStream и with_playback: src/sdl3_audio.h, регистрация в
module_sdl3.cpp, tests/audio.das и docs/audio.md. Исправлена только policy:
**default playback, null callback/userdata**, без capture/произвольных callbacks.
Поэтому Audio теперь 14 generated / 1 adapted / 41 pending. Это исправление
учёта существующей функциональности, не новая привязка.

Не повышены статусы функций, которые только встречаются внутри реализации:

- IOFromFile/GetIOSize/ReadIO/CloseIO обслуживают загрузчик shader assets;
  пользовательского IOStream API от этого не появляется.
- GetWindowProperties/GetPointerProperty/SetPointerProperty/ClearProperty
  обслуживают внутреннюю связь окна с GPU device.
- GetTextureProperties/GetNumberProperty нужны проверке render-target texture.
- IsMainThread, SetError, OutOfMemory и strlen — служебные операции адаптеров.
- GPU readback/fence functions в tests/* позволяют проверить кадр, но не являются
  публичным GPU download/fence API. Resize тестового окна также не равен
  предоставленному script API управления размером окна.

Это проверка различия public contract/internal implementation, не автоматическое
повышение статуса по поиску имени в C++. Для остальных raw exports по-прежнему
нужны отдельные ownership/boost-аудиты; текущие boost_status часто unreviewed.

## Выбор: P1 Properties

Следующая реализация — типизированные группы Properties. Причины:

1. Это фундамент общего плана P1, используемый SDL constructors с суффиксом
   WithProperties, а не новый сценарий только для нашего GPU renderer.
2. Сейчас категория не предоставлена пользователю вовсе (0/21).
3. Проверка не требует физического устройства, окна, GPU или доступа к clipboard.
4. Здесь можно проверить uint32 handle typedef, Sint64, float/bool, enum result,
   owned strings и синхронный callback без запуска retained callback bridge.

Первая ограниченная вертикаль — **15 функций**:

| Контракт | SDL functions |
| --- | --- |
| Создание/уничтожение | SDL_CreateProperties, SDL_DestroyProperties |
| Значения | SDL_SetStringProperty, SDL_SetNumberProperty, SDL_SetFloatProperty, SDL_SetBooleanProperty |
| Чтение | SDL_GetStringProperty, SDL_GetNumberProperty, SDL_GetFloatProperty, SDL_GetBooleanProperty |
| Инспекция/изменение | SDL_HasProperty, SDL_GetPropertyType, SDL_ClearProperty, SDL_CopyProperties |
| Снимок имён | SDL_EnumerateProperties |

Шесть функций вне первой вертикали: SDL_GetGlobalProperties, SDL_LockProperties,
SDL_UnlockProperties, SDL_SetPointerProperty, SDL_GetPointerProperty,
SDL_SetPointerPropertyWithCleanup. Global/заимствованные группы, произвольные
указатели и cleanup callbacks требуют отдельного контракта. Lock/unlock могут
использоваться внутри native string-copy, но это не готовая публичная блокировка
для произвольного script block; частичное использование учитывать явно.

### Порядок реализации

1. Проверить CppGenBind на выбранных сигнатурах и SDL_PropertiesID=Uint32;
   Sint64 не сужать до int. Закрыть enum/ABI gate для SDL_PropertyType и шести
   SDL_PROPERTY_TYPE_* констант. Не добавлять все enum/type declarations вслепую.
2. Простые сигнатуры генерировать из allowlist. Для borrowed const char* результата,
   lifecycle и callback сделать native adapters; не открывать void*/userdata
   ради удобства генерации. Saved snapshots остаются штатным consumer-путём,
   legacy generator — baseline для parity.
3. with_properties получает owned группу. Очистка через защищённый блок и
   try/recover, включая early return/panic; сначала определить границу между
   raw SDL ID и проверяемым boost handle. Не обещать защиту при смешивании
   raw destroy и owned scope без соответствующего механизма и теста.
4. Строка должна быть скопирована в память daScript до освобождения защиты SDL.
   Семантика отсутствующего/неверного типа и default соответствует SDL;
   пустая строка отличается от отсутствия. Не заменять SDL_CopyProperties
   обещанием глубокого клонирования произвольных native pointers.
5. EnumerateProperties выполняет только native сбор имён в snapshot, без
   вызова скрипта под внутренним SDL lock и без исключения через C ABI.
   Изменять свойства можно уже после возврата snapshot; порядок не гарантировать.
6. Один пример 23_properties.das: типизированная конфигурация, копирование,
   проверка типов и список ключей. Имя зарезервировано планом, файл ещё не создан.

### Критерии завершения

- string/bool/float/Sint64 roundtrip (включая значения вне int32), default,
  несовпадение типа, замена значения, clear и copy.
- Пустые/UTF-8 строки и сохранение скопированной строки после изменения/уничтожения
  property group; имена остаются валидны после изменения группы.
- Владение, ошибка создания, нормальный/ранний выход, panic; чужие/устаревшие ID
  проверяются там, где boost обещает такую защиту. Borrowed group нельзя уничтожать.
- Interpreter, legacy/CppGenBind parity, strict AOT без fallback, negative missing-AOT
  и consumer без LLVM. Обновлённые inventory/policy и отсутствие регрессий.
- Реальный прирост функций и ограничения приведены отдельно от числа примеров.

## Очередь после Properties

| Порядок | Блок | Основание и границы |
| --- | --- | --- |
| 1 | P1 Hints + Init/subsystems | Шесть Hints без Add/RemoveHintCallback; metadata, subsystem lifecycle и main-thread query. Сохранённые callbacks отдельным шагом, глобальное состояние тестировать в изолированном процессе. |
| 2 | P2 Video/Render | Display/window enumeration с копиями и SDL_free, window state/DPI, недостающие renderer операции. Связать WithProperties constructors с новым фундаментом. |
| 3 | P4 IOStream | Scoped file/dynamic-memory IO, copied byte arrays, short read/EOF/error, seek/close. Основа загрузчиков и дополнительных библиотек; raw memory borrowing и custom callbacks позже. |
| 4 | P3 Events + Gamepad/Joystick | Расширить tagged events и owned payload; enumerate/open/close/state, hotplug и обычное отсутствие устройства. Реальные аппаратные проверки не заменять одним успешным skip. |
| 5 | P6 GPU API | Вернуться к 51 pending: descriptors/state contracts, transfers/readback/fences и compute. Новые сценовые удобства — только когда проверяют новый контракт SDL. |

P0 идёт поперёк очереди: Linux/macOS profiles и real builds, enum/flags ABI,
install/export и запуск вне дерева исходников. Нынешний LLVM-free consumer build
не доказывает relocatable package. Callback bridge P1/P3/P5/P7 проектировать
отдельно: поток вызова, rooting, unsubscribe и запрет выброса через C ABI.
SDL_image/ttf/mixer и shader DSL остаются отдельными дорожными картами.

Дополнительное разделение GPU texture/sampler и загрузка моделей сейчас отложены:
они не заменяют работу по отсутствующим категориям основной SDL3.
