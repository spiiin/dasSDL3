options gen2
require dassdl3/sdl3_events
require daslib/match

def check(e : SdlEvent) : uint {
    match (e) {
        if (SdlEvent(finger_down = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.touch_id == 0xf123456789abcdeful && v.finger_id == 0xe123456789abcdeful && v.window_id == 42u && v.position == float2(-0.25, 1.25) && v.delta == float2(-0.5, 0.75) && v.pressure == 0.5); return SDL_EVENT_FINGER_DOWN}
        if (SdlEvent(finger_up = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.touch_id == 0xf123456789abcdeful && v.finger_id == 0xe123456789abcdeful && v.window_id == 42u && v.position == float2(-0.25, 1.25) && v.delta == float2(-0.5, 0.75) && v.pressure == 0.5); return SDL_EVENT_FINGER_UP}
        if (SdlEvent(finger_motion = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.touch_id == 0xf123456789abcdeful && v.finger_id == 0xe123456789abcdeful && v.window_id == 42u && v.position == float2(-0.25, 1.25) && v.delta == float2(-0.5, 0.75) && v.pressure == 0.5); return SDL_EVENT_FINGER_MOTION}
        if (SdlEvent(finger_canceled = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.touch_id == 0xf123456789abcdeful && v.finger_id == 0xe123456789abcdeful && v.window_id == 42u && v.position == float2(-0.25, 1.25) && v.delta == float2(-0.5, 0.75) && v.pressure == 0.5); return SDL_EVENT_FINGER_CANCELED}
        if (SdlEvent(pen_proximity_in = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u); verify(v.pen_state == (SDL_PEN_INPUT_DOWN | SDL_PEN_INPUT_ERASER_TIP)); return SDL_EVENT_PEN_PROXIMITY_IN}
        if (SdlEvent(pen_proximity_out = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u); verify(v.pen_state == (SDL_PEN_INPUT_DOWN | SDL_PEN_INPUT_ERASER_TIP)); return SDL_EVENT_PEN_PROXIMITY_OUT}
        if (SdlEvent(pen_motion = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u && v.pen_state == (SDL_PEN_INPUT_DOWN | SDL_PEN_INPUT_ERASER_TIP) && v.position == float2(12.5, -2.5)); return SDL_EVENT_PEN_MOTION}
        if (SdlEvent(pen_down = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u && v.pen_state == SDL_PEN_INPUT_ERASER_TIP && v.position == float2(12.5, -2.5) && v.eraser); return SDL_EVENT_PEN_DOWN}
        if (SdlEvent(pen_up = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u && v.pen_state == SDL_PEN_INPUT_ERASER_TIP && v.position == float2(12.5, -2.5) && v.eraser); return SDL_EVENT_PEN_UP}
        if (SdlEvent(pen_button_down = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u && v.pen_state == SDL_PEN_INPUT_BUTTON_2 && v.position == float2(12.5, -2.5) && v.button == uint8(2)); return SDL_EVENT_PEN_BUTTON_DOWN}
        if (SdlEvent(pen_button_up = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u && v.pen_state == SDL_PEN_INPUT_BUTTON_2 && v.position == float2(12.5, -2.5) && v.button == uint8(2)); return SDL_EVENT_PEN_BUTTON_UP}
        if (SdlEvent(pen_axis = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.window_id == 42u && v.which == 0xf1234567u && v.pen_state == SDL_PEN_INPUT_DOWN && v.position == float2(12.5, -2.5) && v.axis == SDL_PenAxis.PEN_AXIS_XTILT && v.value == -45.0); return SDL_EVENT_PEN_AXIS}
        if (SdlEvent(sensor_update = $v(v))) {verify(v.timestamp == 0xfedcba9876543210ul); verify(v.which == 0xf1234567u && v.data[0] == -1.25 && v.data[1] == 2.5 && v.data[2] == 3.75 && v.data[3] == -4.0 && v.data[4] == 5.0 && v.data[5] == 6.5 && v.sensor_timestamp == 0x123456789abcdef0ul); return SDL_EVENT_SENSOR_UPDATE}
        if (_) {verify(false); return 0u}
    }
}

[export]
def main(smoke : bool) : int {
    let kinds <- array<uint>(SDL_EVENT_FINGER_DOWN, SDL_EVENT_FINGER_UP, SDL_EVENT_FINGER_MOTION, SDL_EVENT_FINGER_CANCELED, SDL_EVENT_PEN_PROXIMITY_IN, SDL_EVENT_PEN_PROXIMITY_OUT, SDL_EVENT_PEN_MOTION, SDL_EVENT_PEN_DOWN, SDL_EVENT_PEN_UP, SDL_EVENT_PEN_BUTTON_DOWN, SDL_EVENT_PEN_BUTTON_UP, SDL_EVENT_PEN_AXIS, SDL_EVENT_SENSOR_UPDATE)
    var saved : array<SdlEvent>
    for (kind in kinds) {var raw = SDLTestPeripheralEvent(kind); var decoded <- decode_event(raw); emplace(saved, decoded); raw = SDL_MakeEvent(); verify(check(saved[length(saved) - 1]) == kind)}
    var wrong = SDL_MakeEvent()
    wrong.event_type = SDL_EVENT_QUIT
    var outTouchFinger : SDL_TouchFingerEvent
    let rawTouchFinger = SDLTestPeripheralEvent(SDL_EVENT_FINGER_DOWN)
    verify(SDL_ReadTouchFingerEvent(rawTouchFinger, outTouchFinger))
    verify(!SDL_ReadTouchFingerEvent(wrong, outTouchFinger) && outTouchFinger.timestamp == 0ul)
    var outPenProximity : SDL_PenProximityEvent
    let rawPenProximity = SDLTestPeripheralEvent(SDL_EVENT_PEN_PROXIMITY_IN)
    verify(SDL_ReadPenProximityEvent(rawPenProximity, outPenProximity))
    verify(!SDL_ReadPenProximityEvent(wrong, outPenProximity) && outPenProximity.timestamp == 0ul)
    var outPenMotion : SDL_PenMotionEvent
    let rawPenMotion = SDLTestPeripheralEvent(SDL_EVENT_PEN_MOTION)
    verify(SDL_ReadPenMotionEvent(rawPenMotion, outPenMotion))
    verify(!SDL_ReadPenMotionEvent(wrong, outPenMotion) && outPenMotion.timestamp == 0ul)
    var outPenTouch : SDL_PenTouchEvent
    let rawPenTouch = SDLTestPeripheralEvent(SDL_EVENT_PEN_DOWN)
    verify(SDL_ReadPenTouchEvent(rawPenTouch, outPenTouch))
    verify(!SDL_ReadPenTouchEvent(wrong, outPenTouch) && outPenTouch.timestamp == 0ul)
    var outPenButton : SDL_PenButtonEvent
    let rawPenButton = SDLTestPeripheralEvent(SDL_EVENT_PEN_BUTTON_DOWN)
    verify(SDL_ReadPenButtonEvent(rawPenButton, outPenButton))
    verify(!SDL_ReadPenButtonEvent(wrong, outPenButton) && outPenButton.timestamp == 0ul)
    var outPenAxis : SDL_PenAxisEvent
    let rawPenAxis = SDLTestPeripheralEvent(SDL_EVENT_PEN_AXIS)
    verify(SDL_ReadPenAxisEvent(rawPenAxis, outPenAxis))
    verify(!SDL_ReadPenAxisEvent(wrong, outPenAxis) && outPenAxis.timestamp == 0ul)
    var outSensor : SDL_SensorEvent
    let rawSensor = SDLTestPeripheralEvent(SDL_EVENT_SENSOR_UPDATE)
    verify(SDL_ReadSensorEvent(rawSensor, outSensor))
    verify(!SDL_ReadSensorEvent(wrong, outSensor) && outSensor.timestamp == 0ul)
    let result = with_sdl() {
        while (is_some(poll_event())) { }
        for (kind in kinds) {var raw = SDLTestPeripheralEvent(kind); verify(push_event(raw))}
        for (kind in kinds) {var next <- poll_event(); verify(is_some(next) && check(unwrap(next)) == kind)}
        for (i in 0 .. length(kinds)) {verify(check(saved[i]) == kinds[i])}
        return sdl_ok()
    }
    verify(is_ok(result))
    print("All 13 touch/pen/sensor variants, active union copies and owned queue payloads PASS\n")
    return 0
}
