options gen2
require dassdl3/sdl3_peripherals_boost
require dassdl3/sdl3_scope

def raw_queries() {
    unsafe {
        var count : int
        let touch = SDL_GetTouchDevices(addr(count)); verify(touch != null && count >= 0); SDL_free(touch)
        verify(length(SDL_GetTouchDeviceName(0ul)) == 0)
        verify(SDL_GetTouchDeviceType(0ul) == SDL_TouchDeviceType.TOUCH_DEVICE_INVALID)
        let fingers = SDL_GetTouchFingers(0ul, addr(count)); verify(fingers == null); SDL_free(fingers)
        let sensors = SDL_GetSensors(addr(count)); verify(sensors != null && count >= 0); SDL_free(sensors)
        verify(length(SDL_GetSensorNameForID(0u)) == 0)
        verify(SDL_GetSensorTypeForID(0u) == SDL_SensorType.SENSOR_INVALID)
        verify(SDL_GetSensorNonPortableTypeForID(0u) == -1)
        verify(SDL_OpenSensor(0u) == null && SDL_GetSensorFromID(0u) == null)
        verify(SDL_GetSensorProperties(null) == 0u && length(SDL_GetSensorName(null)) == 0)
        verify(SDL_GetSensorType(null) == SDL_SensorType.SENSOR_INVALID)
        verify(SDL_GetSensorNonPortableType(null) == -1 && SDL_GetSensorID(null) == 0u)
        var data : float[6]
        verify(!SDL_GetSensorData(null, addr(data[0]), 6))
        SDL_CloseSensor(null); SDL_UpdateSensors()
        let haptics = SDL_GetHaptics(addr(count)); verify(haptics != null && count >= 0); SDL_free(haptics)
        verify(length(SDL_GetHapticNameForID(0u)) == 0 && SDL_OpenHaptic(0u) == null && SDL_GetHapticFromID(0u) == null)
        verify(SDL_GetHapticID(null) == 0u && length(SDL_GetHapticName(null)) == 0)
        SDL_IsMouseHaptic()
        let mouse = SDL_OpenHapticFromMouse()
        if (mouse != null) {SDL_CloseHaptic(mouse)}
        verify(!SDL_IsJoystickHaptic(null) && SDL_OpenHapticFromJoystick(null) == null)
        SDL_CloseHaptic(null)
        verify(SDL_GetMaxHapticEffects(null) == -1 && SDL_GetMaxHapticEffectsPlaying(null) == -1)
        verify(SDL_GetHapticFeatures(null) == 0u && SDL_GetNumHapticAxes(null) == -1)
        var effect : SDL_HapticEffect
        verify(!SDL_HapticEffectSupported(null, addr(effect)))
        verify(SDL_CreateHapticEffect(null, addr(effect)) == -1)
        verify(!SDL_UpdateHapticEffect(null, 0, addr(effect)))
        verify(!SDL_RunHapticEffect(null, 0, 1u) && !SDL_StopHapticEffect(null, 0))
        SDL_DestroyHapticEffect(null, 0)
        verify(!SDL_GetHapticEffectStatus(null, 0))
        verify(!SDL_SetHapticGain(null, 0) && !SDL_SetHapticAutocenter(null, 0))
        verify(!SDL_PauseHaptic(null) && !SDL_ResumeHaptic(null) && !SDL_StopHapticEffects(null))
        verify(!SDL_HapticRumbleSupported(null) && !SDL_InitHapticRumble(null))
        verify(!SDL_PlayHapticRumble(null, 0.0, 0u) && !SDL_StopHapticRumble(null))
        verify(SDL_hid_init() == 0)
        SDL_hid_device_change_count()
        let list = SDL_hid_enumerate(0u, 0u); SDL_hid_free_enumeration(list)
        var serial : uint16[2]; serial[0] = uint16(0xffff)
        let device = SDL_hid_open(65535u, 65535u, addr(serial[0]))
        if (device != null) {SDL_hid_close(device)}
        verify(SDL_hid_open_path("dasSDL3://no-such-hid-device") == null)
        var bytes : uint8[8]
        verify(SDL_hid_write(null, addr(bytes[0]), 8ul) == -1)
        verify(SDL_hid_read_timeout(null, addr(bytes[0]), 8ul, 0) == -1)
        verify(SDL_hid_read(null, addr(bytes[0]), 8ul) == -1)
        verify(SDL_hid_set_nonblocking(null, 1) == -1)
        verify(SDL_hid_send_feature_report(null, addr(bytes[0]), 8ul) == -1)
        verify(SDL_hid_get_feature_report(null, addr(bytes[0]), 8ul) == -1)
        verify(SDL_hid_get_input_report(null, addr(bytes[0]), 8ul) == -1)
        verify(SDL_hid_close(null) == -1)
        var wide : uint16[32]
        verify(SDL_hid_get_manufacturer_string(null, addr(wide[0]), 32ul) == -1)
        verify(SDL_hid_get_product_string(null, addr(wide[0]), 32ul) == -1)
        verify(SDL_hid_get_serial_number_string(null, addr(wide[0]), 32ul) == -1)
        verify(SDL_hid_get_indexed_string(null, 0, addr(wide[0]), 32ul) == -1)
        verify(SDL_hid_get_device_info(null) == null)
        verify(SDL_hid_get_report_descriptor(null, addr(bytes[0]), 8ul) == -1)
        SDL_hid_ble_scan(false)
        verify(SDL_hid_exit() == 0)
    }
}

def payloads() {
    var constant = SDL_HapticConstant(level = int16(-1234))
    let a = SDL_MakeHapticConstantEffect(constant); verify(SDLTestHapticPayload(a) == -1234)
    var periodic = SDL_HapticPeriodic(effect_type = uint16(SDL_HAPTIC_SINE), offset = int16(-2345))
    let b = SDL_MakeHapticPeriodicEffect(periodic); verify(SDLTestHapticPayload(b) == -2345)
    var condition = SDL_HapticCondition(effect_type = uint16(SDL_HAPTIC_SPRING)); condition.center[2] = int16(-3456)
    let c = SDL_MakeHapticConditionEffect(condition); verify(SDLTestHapticPayload(c) == -3456)
    var ramp = SDL_HapticRamp(start = int16(-4567))
    let d = SDL_MakeHapticRampEffect(ramp); verify(SDLTestHapticPayload(d) == -4567)
    var motors = SDL_HapticLeftRight(large_magnitude = uint16(60000))
    let e = SDL_MakeHapticLeftRightEffect(motors); verify(SDLTestHapticPayload(e) == 60000)
    var custom = SDL_HapticCustom(samples = uint16(17))
    let f = SDL_MakeHapticCustomEffect(custom); verify(SDLTestHapticPayload(f) == 17)
    verify(!haptic_effect_supported(null, a) && is_err(create_haptic_effect(null, a)))
    verify(is_err(update_haptic_effect(null, 0, a)) && is_err(run_haptic_effect(null, 0, 1u)) && is_err(stop_haptic_effect(null, 0)))
    var ran = false
    let failed = with_haptic_effect(null, a) $(id) {ran = true; return sdl_ok()}
    verify(is_err(failed) && !ran)
    let info = hid_device_info(SDLTestHidInfo())
    verify(is_some(info) && is_none(hid_device_info(null)))
    SDLTestMutateHidInfo()
    let copy = unwrap(info)
    verify(copy.path == "test://owned-path" && copy.serial_number == "日本 🌍" && copy.manufacturer == "日本 🌍" && copy.product == "日本 🌍")
    verify(copy.vendor_id == uint16(0xabcd) && copy.product_id == uint16(0x1234) && copy.release_number == uint16(0x2345))
    verify(copy.usage_page == uint16(0xff00) && copy.usage == uint16(7) && copy.interface_number == -1)
    verify(copy.interface_class == 3 && copy.interface_subclass == 1 && copy.interface_protocol == 2 && copy.bus_type == SDL_hid_bus_type.HID_API_BUS_USB)
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl_subsystems(SDL_INIT_VIDEO | SDL_INIT_SENSOR | SDL_INIT_HAPTIC | SDL_INIT_JOYSTICK) |> sdl_use
        raw_queries()
        payloads()
        verify(is_ok(touch_devices()) && is_ok(sensors()) && is_ok(haptics()))
        verify(is_err(touch_fingers(0ul)) && is_err(touch_device_name(0ul)))
        verify(is_err(open_sensor(0u)) && is_err(sensor_name(null)) && is_err(open_haptic(0u)) && is_err(haptic_name(null)))
        var floats <- array<float>(0.0, 0.0, 0.0)
        verify(is_err(sensor_data(null, floats)))
        var ran = false
        let sensor = with_sensor(0u) $(device) {ran = true; return sdl_ok()}
        let haptic = with_haptic(0u) $(device) {ran = true; return sdl_ok()}
        let hid = with_hid_device("dasSDL3://no-such-hid-device") $(device) {ran = true; return sdl_ok()}
        verify(!ran && is_err(sensor) && is_err(haptic) && is_err(hid))
        var empty : array<uint8>
        var buffer <- array<uint8>(uint8(0), uint8(0))
        verify(is_err(hid_write(null, empty)) && is_err(hid_read(null, buffer)))
        verify(is_err(hid_read_timeout(null, buffer, 0)) && is_err(hid_send_feature_report(null, buffer)))
        verify(is_err(hid_get_feature_report(null, buffer)) && is_err(hid_get_input_report(null, buffer)) && is_err(hid_get_report_descriptor(null, buffer)))
        let body_error = with_hid() {return err(SdlError(operation = "body", message = "preserve"), type<SdlUnit>)}
        verify(is_err(body_error) && unwrap_err(body_error).message == "preserve")
        return sdl_ok()
    }
    verify(is_ok(result))
    print("71 peripheral raw calls, copied HID Unicode, haptic unions and error scopes PASS; hardware I/O not exercised\n")
    return 0
}
