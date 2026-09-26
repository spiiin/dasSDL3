# Аудит контрактов boost-слоя

Срез: SDL 3.4.16, 2026-09-26. Проверены формы публичного API в `dassdl3`,
возвращаемые значения, изменяемые параметры и границы владения. Это аудит
исходников, а не подтверждение исполнения каждого вызова на каждом устройстве.
`[nodiscard]` в этом проходе не добавляется.

## Воспроизводимый индекс

[Индекс объявлений](generated/boost-api.csv) содержит 919 явных `def public`
(770 имён, включая перегрузки и публичные macro helpers) в 69 файлах.
Сканируются все 70 `.das` файлов каталога; файл без таких объявлений не даёт строк.
Индекс не включает raw C++ exports, неявные экспорты и методы с другой формой
объявления. Числа нельзя сравнивать с количеством SDL-функций.

Обновление: `python tools/audit_boost_api.py`; проверка:
`python tools/audit_boost_api.py --check`.
CSV хранит исходную сигнатуру, ссылку на строку, наличие `var`, маркеры Result/Option
в теле и `defer`. Это лексические факты, НЕ выведенный компилятором тип:
делегирующая функция может возвращать Result без локального `ok`, а маркер может
находиться во вложенном блоке. `var` внутри callback тоже попадает в признак.

## Результат проверки

| Область | Контракт и решение |
| --- | --- |
| Window / renderer / texture / surface | Fallible операции возвращают Result. У обычных запросов размеров, цветов, scale/blend и других ref-запросов есть value-returning перегрузки. Сохранять ref-перегрузки допустимо; новые примеры должны предпочитать возвращаемое значение. |
| Audio / keyboard / gamepad | Составные `AudioDeviceFormat`, `WavData`, mouse/key/touchpad результаты уже убирают отдельные output variables. Не добавлять дублирующие result-алиасы. |
| IO | `IoTransfer { transferred; status : Result<SDL_IOStatus,SdlError> }` сохраняет частичную передачу при Err. Не заменять на `Result<count>` с потерей счётчика. EOF/NOT_READY являются состояниями. |
| Events | Polling возвращает Option; timeout — Result<Option>. Owned decoder копирует поддержанные текстовые/list payloads. Raw event/peep версии продолжают заимствовать pointer payloads. `push_event` — намеренный acceptance bool. |
| Properties / metadata | Отсутствие и пустая строка не равны ошибке. Borrowed property group ID нельзя уничтожать как созданную через `with_properties` группу. |
| Camera / process / net | `acquire_camera_frame`, `wait_process`, `accept_client` используют Result<Option>. Camera permission — enum, network readiness — Result<bool>, где false значит pending. |
| Async IO | Завершение задачи возвращается как outcome; failure самой задачи не теряется внутри Option. Buffer/userdata должны жить до завершения. Успешная постановка close потребляет IO. |
| Checked GPU | Distinct handle types, Result, runtime kind/device/liveness checks. End/submit/cancel потребляют ID. Пустой readback/support=false не превращаются в Err. |
| Native GPU | Result проверяет ошибку операции/адаптера, но не доказывает живость произвольного указателя. Ref-consuming helpers обнуляют переданную переменную, не её копии. Swapchain None сохраняется; приобретённая texture требует submit даже при Err тела. |
| Scopes | Acquisition failure пропускает тело; вложенный cleanup вводится после acquisition. Ошибка тела приоритетнее ошибки cleanup. Обычный Result не гарантирует cleanup после произвольного panic. |
| Pixel views | Managed view запрещает copy/move/clone; borrowed row может быть явно скопирован в независимый массив. Это более сильная гарантия, чем обычный scope с native pointer. |
| Thread / synchronization / callbacks | Atomics и try-lock возвращают значения/предикаты, не Result ошибок. Retained callbacks — native C ABI и host-owned state, не script closure на чужом потоке. |
| Companion libraries | Image/mixer/shadercross копируют собственные данные; net сохраняет pending и partial counts; TTF draw arrays принадлежат скрипту, atlas texture остаётся borrowed. SDL_sound имеет собственный error helper, его нельзя механически заменить SDL_GetError. |
| Builders | Возвращают descriptor по значению, не ресурс. Pipeline arrays перемещаются; владение shader/device не передаётся. Уже существующий nodiscard не изменён. |

Для подтверждения форм запросов использован поиск всех mutable signatures и
одноимённых перегрузок без выходных параметров, затем разобраны оставшиеся случаи.
Оставшиеся `var` без альтернативы относятся к in-place buffers (`read_audio`, HID,
net, mixer, storage, readback), consuming handles, atomics/state, event mutation
или builders. Само наличие `var` не является дефектом.

## Конкретные дальнейшие улучшения

1. **Закрыто в этом проходе: uniform stage symmetry.** Native float-array helpers
   теперь есть для vertex, fragment и compute. Подробности —
   [native GPU](gpu-native-boost.md#float-uploads-and-application-port).
2. **Метаданные boost coverage требуют отдельной нормализации.** `api-policy.json`
   уже содержит статусы, но это не завершённая таблица удобства каждого SDL symbol:
   встречаются `partial`, `available`, `scoped`, `checked-arrays`, `not_needed`,
   `pending` и отсутствующий статус. Некоторые причины устарели: например,
   InsertGPUDebugLabel/PushGPUDebugGroup/PopGPUDebugGroup всё ещё говорят о pending
   runtime validation, хотя вызовы есть в GPU raw/array tests. Прямому void-вызову
   не обязательно нужен boost helper. Не повышать статусы автоматически по
   совпадению имени в тесте. Следующий шаг — единая схема статусов и явная связь
   SDL symbol → overload → contract → test, с отдельной оценкой полноты проверки.
3. **Различать borrowed и owned ресурсы в справочнике каждого factory/query.**
   Особенно `windows()`, `event_window()`, camera frame, property IDs,
   `gpu_text_draw_data().atlas_texture`, function address. Result/Option не
   добавляют ownership. Это задача документации контрактов, не повод создавать
   native-pointer registry или обещать Rust borrow checking.
4. **IoTransfer convenience с offset.** Value-returning read/write перегрузки
   сейчас всегда используют offset=0; offset доступен в форме с out-count.
   Можно добавить offset к value-returning форме без потери partial counts.
   Это небольшое удобство, не ошибка текущего API.
5. **Error operation naming.** Есть SDL names (`SDL_CloseIO`), adapter names и
   boost names (`with_window`, `surface_clip`). Оба поля ошибки копируются, но
   поле operation не является нормализованным machine-readable error code.
   Следует документировать это; переименование нельзя выдавать за исправление
   error handling или выводить категории из текста сообщения.

Новых доказанных ошибок sentinel/cleanup в рассмотренных путях не обнаружено.
Это не сертификат безопасности всего native API: shader ABI, lifetimes, потоки,
ретенция указателей и ограничения платформ по-прежнему являются предусловиями.
Raw функции не переводятся в Result, а намеренные bool/enum/void не оборачиваются
в Result только ради единообразия.

## Связанные проверки

Существующие проверки контрактов: `tests/boost_result_contracts.das`,
`tests/compound_returns.das`, `tests/sdl3_result.das`, `tests/gpu_result_contracts.das`,
`tests/iostream.das`, `tests/asyncio.das`, `tests/camera.das`, `tests/net.das`,
`tests/callback_lifetimes.das`, `tests/pixel_views.das`.
Их наличие не означает, что все эти аппаратные сценарии заново выполнены этим аудитом.

Для новых uniforms используются `tests/gpu_native_array_operations.das`
(fragment pixel oracle и compute buffer oracle) и `tests/gpu_float_upload.das`
(null validation). Это проверки реальных данных, не только успешного создания.
Литеральные пути `tests` и файловые `docs/...` contracts из `api-policy.json`
проверены на существование: отсутствующих путей не найдено.

Проверки этого изменения (Windows): основной runner — Result/compound returns и
uniform-тесты на Vulkan/Direct3D12; parity — baseline, CppGenBind и strict AOT
без fallback. После последнего изменения теста AOT пересобран и GPU array suite
повторён. Проверены изменение массива после push, пустой массив, null command,
копия ошибки после SDL_ClearError и реальные GPU pixel/buffer результаты.
No-LLVM consumer собран с отключёнными LLVM/Clang/Python discovery и генераторами;
`gpu_float_upload.das` прошёл на Direct3D12. `gpu_native_array_operations.das`
требует SDLTest fixtures и не является consumer-тестом.

Оба snapshot generation check прошли. Обнаруженный старый input hash
`tools/clangbind_parity.das` в `src/generated/clangbind/profile.json` обновлён
штатным генератором через временный snapshot; остальные generated файлы совпали.
