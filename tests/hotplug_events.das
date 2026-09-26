options gen2
require dassdl3/sdl3_events
require daslib/match

def check(event : SdlEvent) : uint {
    match (event) {
        if (SdlEvent(keyboard_added = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_KEYBOARD_ADDED
        }
        if (SdlEvent(keyboard_removed = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_KEYBOARD_REMOVED
        }
        if (SdlEvent(mouse_added = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_MOUSE_ADDED
        }
        if (SdlEvent(mouse_removed = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_MOUSE_REMOVED
        }
        if (SdlEvent(audio_device_added = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.recording)
            return SDL_EVENT_AUDIO_DEVICE_ADDED
        }
        if (SdlEvent(audio_device_removed = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.recording)
            return SDL_EVENT_AUDIO_DEVICE_REMOVED
        }
        if (SdlEvent(audio_device_format_changed = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.recording)
            return SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED
        }
        if (SdlEvent(camera_device_added = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_CAMERA_DEVICE_ADDED
        }
        if (SdlEvent(camera_device_removed = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_CAMERA_DEVICE_REMOVED
        }
        if (SdlEvent(camera_device_approved = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_CAMERA_DEVICE_APPROVED
        }
        if (SdlEvent(camera_device_denied = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            return SDL_EVENT_CAMERA_DEVICE_DENIED
        }
        if (_) {return 0u}
    }
    return 0u
}
[export]
def main(smoke : bool) : int {
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_KEYBOARD_ADDED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_KEYBOARD_ADDED)
    }
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_KEYBOARD_REMOVED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_KEYBOARD_REMOVED)
    }
    var wrong_keyboard : SDL_KeyboardDeviceEvent
    wrong_keyboard.which = 9u
    verify(!SDL_ReadKeyboardDeviceEvent(SDL_MakeEvent(), wrong_keyboard))
    verify(wrong_keyboard.which == 0u && wrong_keyboard.timestamp == 0ul)
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_MOUSE_ADDED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_MOUSE_ADDED)
    }
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_MOUSE_REMOVED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_MOUSE_REMOVED)
    }
    var wrong_mouse : SDL_MouseDeviceEvent
    wrong_mouse.which = 9u
    verify(!SDL_ReadMouseDeviceEvent(SDL_MakeEvent(), wrong_mouse))
    verify(wrong_mouse.which == 0u && wrong_mouse.timestamp == 0ul)
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_AUDIO_DEVICE_ADDED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_AUDIO_DEVICE_ADDED)
    }
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_AUDIO_DEVICE_REMOVED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_AUDIO_DEVICE_REMOVED)
    }
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED)
    }
    var wrong_audio : SDL_AudioDeviceEvent
    wrong_audio.which = 9u
    verify(!SDL_ReadAudioDeviceEvent(SDL_MakeEvent(), wrong_audio))
    verify(wrong_audio.which == 0u && wrong_audio.timestamp == 0ul)
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_CAMERA_DEVICE_ADDED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_CAMERA_DEVICE_ADDED)
    }
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_CAMERA_DEVICE_REMOVED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_CAMERA_DEVICE_REMOVED)
    }
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_CAMERA_DEVICE_APPROVED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_CAMERA_DEVICE_APPROVED)
    }
    {
        var raw = SDLTestHotplugEvent(SDL_EVENT_CAMERA_DEVICE_DENIED)
        var value <- decode_event(raw)
        raw = SDL_MakeEvent()
        verify(check(value) == SDL_EVENT_CAMERA_DEVICE_DENIED)
    }
    var wrong_camera : SDL_CameraDeviceEvent
    wrong_camera.which = 9u
    verify(!SDL_ReadCameraDeviceEvent(SDL_MakeEvent(), wrong_camera))
    verify(wrong_camera.which == 0u && wrong_camera.timestamp == 0ul)
    print("Owned hotplug payloads and inactive-union rejection passed.\n")
    return 0
}
