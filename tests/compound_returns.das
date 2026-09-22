options gen2
require dassdl3/sdl3_audio_final
require dassdl3/sdl3_keyboard_mouse_boost
require dassdl3/sdl3_joystick_gamepad_boost
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_audio_devices_boost
require dassdl3/sdl3_audio_stream_controls
[export]
def main(smoke : bool) : int {
    verify(is_err(audio_device_format(0u)))
    verify(is_err(audio_stream_formats(null)))
    verify(is_err(load_wav_io(null)))
    verify(is_err(gamepad_touchpad_finger(null,0,0)))
    verify(is_err(text_input_area(null)))
    var bytes : array<uint8>;resize(bytes,4)
    let input=read_io(null,bytes,4ul)
    verify(is_err(input.status) && input.transferred==0ul)
    let output=write_io(null,bytes,4ul)
    verify(is_err(output.status) && output.transferred==0ul)
    let mouse=mouse_state()
    let global_mouse=global_mouse_state()
    let delta=relative_mouse_state()
    let key=scancode_from_key(SDLK_A)
    return 0
}
