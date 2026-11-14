options gen2
require dassdl3/sdl3_boost
require strings

var finger_id = 0ul
var touch_id = 0ul
var moved = false
var typed = ""

[export]
def input_event(window : SDL_Window?; event : SDL_Event) : int {
    var touch : SDL_TouchFingerEvent
    if (SDL_ReadTouchFingerEvent(event, touch)) {
        if (touch.windowID != SDL_GetWindowID(window) ||
            SDL_GetTouchDeviceType(touch.touchID) != SDL_TouchDeviceType.TOUCH_DEVICE_DIRECT) {
            return 0
        }
        if (event.event_type == SDL_EVENT_FINGER_DOWN && finger_id == 0ul) {
            if (touch.fingerID == 0ul || !(touch.x >= 0.0 && touch.x <= 1.0 && touch.y >= 0.0 && touch.y <= 1.0)) {
                return -1
            }
            finger_id = touch.fingerID
            touch_id = touch.touchID
            moved = false
            print("iPhone direct touch down\n")
        } elif (touch.fingerID == finger_id && touch.touchID == touch_id) {
            if (event.event_type == SDL_EVENT_FINGER_MOTION && (touch.dx != 0.0 || touch.dy != 0.0) && !moved) {
                moved = true
                print("iPhone direct touch motion\n")
            } elif (event.event_type == SDL_EVENT_FINGER_UP || event.event_type == SDL_EVENT_FINGER_CANCELED) {
                finger_id = 0ul
                if (event.event_type == SDL_EVENT_FINGER_UP && moved) {
                    print("iPhone direct touch down, motion and up PASS\n")
                    return 1
                }
            }
        }
    }
    var text = ""
    if (input_window_id(event) == SDL_GetWindowID(window) && is_some(text_input_event(event, text))) {
        typed := "{typed}{text}"
        if (typed == "42") { return 2 }
        if (typed != "4") { typed = "" }
    }
    return 0
}

// Require the younger contact to move only after the first one has ended.
var second_finger_id = 0ul
var first_released = false
var second_moved = false

def reset_multi_touch() {
    finger_id = 0ul
    second_finger_id = 0ul
    touch_id = 0ul
    first_released = false
    second_moved = false
}

[export]
def multi_input_event(window : SDL_Window?; event : SDL_Event) : int {
    let window_id = SDL_GetWindowID(window)
    var touch : SDL_TouchFingerEvent
    if (SDL_ReadTouchFingerEvent(event, touch)) {
        if (touch.windowID != window_id || touch.fingerID == 0ul ||
            SDL_GetTouchDeviceType(touch.touchID) != SDL_TouchDeviceType.TOUCH_DEVICE_DIRECT) {
            return 0
        }
        if (finger_id == 0ul && event.event_type == SDL_EVENT_FINGER_DOWN) {
            finger_id = touch.fingerID
            touch_id = touch.touchID
            return 0
        }
        if (touch.touchID != touch_id) { return 0 }
        if (event.event_type == SDL_EVENT_FINGER_CANCELED) {
            reset_multi_touch()
        } elif (event.event_type == SDL_EVENT_FINGER_DOWN && touch.fingerID != finger_id && second_finger_id == 0ul) {
            second_finger_id = touch.fingerID
            print("iPhone distinct simultaneous contacts\n")
        } elif (event.event_type == SDL_EVENT_FINGER_UP && touch.fingerID == finger_id) {
            if (second_finger_id == 0ul) { reset_multi_touch() }
            else { first_released = true }
        } elif (touch.fingerID == second_finger_id) {
            if (event.event_type == SDL_EVENT_FINGER_MOTION && first_released &&
                (touch.dx != 0.0 || touch.dy != 0.0)) {
                second_moved = true
            } elif (event.event_type == SDL_EVENT_FINGER_UP) {
                let passed = second_moved
                reset_multi_touch()
                if (passed) {
                    print("iPhone multitouch PASS: second contact moved after first released\n")
                    return 1
                }
            }
        }
    }
    var text = ""
    if (input_window_id(event) == window_id && is_some(text_input_event(event, text))) {
        let expected = "Привет 👋"
        let alternate = "café"
        typed := "{typed}{text}"
        if (typed == expected || typed == alternate) {
            print("iPhone exact UTF-8 input PASS: {typed}\n")
            return 2
        }
        if (!starts_with(expected, typed) && !starts_with(alternate, typed)) {
            typed := (starts_with(expected, text) || starts_with(alternate, text)) ? text : ""
        }
    }
    return 0
}
