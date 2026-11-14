options gen2
require dassdl3/sdl3_boost

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
