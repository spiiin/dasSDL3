# Ввод: события, состояние и текст

Реализовано для SDL 3.2.18 и закреплённого интерпретатора daScript.
Подключение: `require dassdl3/sdl3_boost`. Пример: `examples/input.das`.

## События

```das
var event = SDL_MakeEvent()
var key : SDL_KeyboardEvent
var motion : SDL_MouseMotionEvent
var text = ""
while (poll_event(event)) {
    if (key_event(event, key)) {
        print("key={key.key}, scan={key_scancode(key)}, down={key.down}\n")
    }
    if (mouse_motion_event(event, motion)) {
        print("mouse={motion.x},{motion.y}\n")
    }
    if (text_input_event(event, text)) {
        print("text={text}\n")
    }
}
```

Каждый reader возвращает bool: true означает совпадение типа события.
При несовпадении выходные значения обнуляются (строка становится пустой).
Данные копируются, C union напрямую из скрипта не раскрывается.

| Обёртка | Выход | Семантика |
| --- | --- | --- |
| key_event | SDL_KeyboardEvent | Down/Up, keycode, modifiers, raw, repeat, windowID, which, timestamp |
| key_scancode | int | Физический scancode из уже скопированного KeyboardEvent |
| mouse_motion_event | SDL_MouseMotionEvent | Координаты окна x/y, относительное движение xrel/yrel, маска state |
| mouse_button_event | SDL_MouseButtonEvent | Down/Up, индекс button, число clicks, x/y |
| mouse_wheel_event | SDL_MouseWheelEvent | Исходные x/y, integer_x/y, положение mouse_x/y |
| wheel_delta | float2 | Меняет знак x/y, если SDL пометила колесо как FLIPPED |
| text_input_event | string& | Копия подтверждённого ввода UTF-8 |
| text_editing_event | string&, int&, int& | Копия незавершённой композиции IME, start/length в символах UTF-8 (не байтах), возможны -1 |

Поля button/clicks имеют uint8, mod/raw — uint16: для сравнения с uint-константами
используйте `uint(field)`. Enum-поля scancode/direction доступны через
`key_scancode`/`wheel_delta` (и нативный SDL_MouseWheelFlipped), а не как поля.
SDL_Event.event_type остаётся доступным для собственного dispatch.

Текст копируется в память daScript при чтении. Сохранённую строку можно
использовать после следующего poll/pump. Сам SDL_Event с указателем на текст
этой гарантии не даёт: декодируйте его сразу, до следующего обращения к очереди.
Сырые события с пользовательскими указателями должны соблюдать контракт SDL.
Keycode и scancode не превращаются в текст: для текста используйте TEXT_INPUT,
для композиции — TEXT_EDITING. Список кандидатов IME ещё не реализован.

## Окна и состояние

`input_window_id(event)` возвращает windowID для поддержанных событий ввода
и оконных событий, 0 для остальных. `should_close(event, window)` принимает
глобальный Quit, Escape и CloseRequested только соответствующего окна.
Исходная однопараметрическая версия сохраняет поведение Quit/любой Escape.
Это помощь в маршрутизации, а не готовый диспетчер всех окон.

`key_down(scancode)` читает текущее физическое состояние клавиши; отрицательный
или выходящий за границы scancode даёт false. `mouse_state(position)` записывает
float2 координат относительно окна с фокусом мыши и возвращает маску кнопок.
Перед запросами опрашивайте очередь либо вызывайте SDL_PumpEvents.
PushEvent добавляет сообщения в очередь, но не меняет физическое состояние ввода.
Все операции этого слоя выполняются на главном потоке.

## Время жизни текстового ввода

```das
with_text_input(window) {
    // Poll events, decode text, update UI.
}
```

Блок включает текстовый ввод, если он был выключен, и выключает свой сеанс
при обычном выходе, раннем return или panic. Уже активный сеанс считается
заимствованным и остаётся активным. Вложенные блоки поддерживаются; ручные
Start/Stop внутри блока нарушают этот контракт. Окно должно жить дольше блока.

При ошибке callback исходное сообщение сохраняется после попытки StopTextInput.
Ошибка Stop без ошибки callback передаётся отдельно. Нулевое окно отклоняется.
Для IME доступны низкоуровневые ClearComposition и события редактирования;
SetTextInputArea, экранная клавиатура, кандидаты и настройки ввода впереди.

## Проверки и ограничения

`sdl3_input` отправляет через очередь синтетические Down/Up, движение, клики,
колесо, UTF-8 текст и композицию. Проверяются поля, FLIPPED, неверные варианты
union с заведомо недопустимым указателем в неактивном поле, независимость копии
строки от исходного буфера, адресация CloseRequested, границы scancode,
выходные параметры мыши и очистка/заимствование текстовых сеансов при panic.
`sdl3_input_example` запускает 60 кадров в скрытом окне.

Автотесты не заменяют проверку конкретной раскладки/IME и физических устройств:
реальная композиция IME и ручной ввод на разных ОС пока не проверены.
Константы клавиш выбраны для текущих сценариев, это ещё не полный набор SDL.
AOT/JIT не проверены. Тестовые SDLTest* отсутствуют при BUILD_TESTING=OFF.
