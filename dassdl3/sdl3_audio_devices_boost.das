options gen2
module sdl3_audio_devices_boost shared public
require dassdl3/sdl3_audio_boost public
require daslib/option public
require daslib/defer

def public audio_playback_devices() {
    var ids : array<uint>
    if (!SDL_GetAudioPlaybackDevicesCopy(ids)) {return err(sdl_error("SDL_GetAudioPlaybackDevices"), type<array<uint>>)}
    return <- move_ok(ids, type<SdlError>)
}
def public audio_recording_devices() {
    var ids : array<uint>
    if (!SDL_GetAudioRecordingDevicesCopy(ids)) {return err(sdl_error("SDL_GetAudioRecordingDevices"), type<array<uint>>)}
    return <- move_ok(ids, type<SdlError>)
}
def public audio_driver(index : int) {
    if (index < 0 || index >= SDL_GetNumAudioDrivers()) {return none(type<string>)}
    return some(SDL_GetAudioDriverCopy(index))
}
def public current_audio_driver() {
    let name = SDL_GetCurrentAudioDriverCopy()
    if (length(name) == 0) {return none(type<string>)}
    return some(name)
}
def public audio_device_name(device : uint) {
    var name : string
    if (!SDL_GetAudioDeviceNameCopy(device, name)) {return err(sdl_error("SDL_GetAudioDeviceName"), type<string>)}
    return ok(name, type<SdlError>)
}
def public audio_device_format(device : uint; var sample_frames : int&) {
    var spec : SDL_AudioSpec
    if (!SDL_GetAudioDeviceFormatRef(device, spec, sample_frames)) {return err(sdl_error("SDL_GetAudioDeviceFormat"), type<SDL_AudioSpec>)}
    return ok(spec, type<SdlError>)
}
// None preserves native null, including its documented default-map meaning.
// SDL cannot distinguish default from invalid device / allocation failure here.
def public audio_device_channel_map(device : uint) {
    var values : array<int>
    let status = SDL_GetAudioDeviceChannelMapCopy(device, values)
    if (status < 0) {return err(sdl_error("SDL_GetAudioDeviceChannelMapCopy"), type<$Option<array<int>>>)}
    var value : $Option<array<int>>
    if (status > 0) {value <- move_some(values)}
    return <- move_ok(value, type<SdlError>)
}
def public open_audio_device(device : uint) {
    let id = SDL_OpenAudioDevice(device, null)
    if (id == 0u) {return err(sdl_error("SDL_OpenAudioDevice"), type<uint>)}
    return ok(id, type<SdlError>)
}
def public open_audio_device(device : uint; spec : SDL_AudioSpec) {
    let id = SDL_OpenAudioDeviceRef(device, spec)
    if (id == 0u) {return err(sdl_error("SDL_OpenAudioDevice"), type<uint>)}
    return ok(id, type<SdlError>)
}
def public close_audio_device(var device : uint&) {SDL_CloseAudioDevice(device); device = 0u}
def public pause_audio_device(device : uint) {return sdl_status(SDL_PauseAudioDevice(device), "SDL_PauseAudioDevice")}
def public resume_audio_device(device : uint) {return sdl_status(SDL_ResumeAudioDevice(device), "SDL_ResumeAudioDevice")}
// SDL's bool predicates are not error sentinels or device-validity checks.
def public audio_device_paused(device : uint) : bool {return SDL_AudioDevicePaused(device)}
def public audio_device_gain(device : uint) {
    let gain = SDL_GetAudioDeviceGain(device)
    if (gain < 0.0) {return err(sdl_error("SDL_GetAudioDeviceGain"), type<float>)}
    return ok(gain, type<SdlError>)
}
def public set_audio_device_gain(device : uint; gain : float) {return sdl_status(SDL_SetAudioDeviceGain(device, gain), "SDL_SetAudioDeviceGain")}
def public bind_audio_stream(device : uint; stream : SDL_AudioStream?) {return sdl_status(SDL_BindAudioStream(device, stream), "SDL_BindAudioStream")}
def public bind_audio_streams(device : uint; streams : array<SDL_AudioStream?>) {return sdl_status(SDL_BindAudioStreamsArray(device, streams), "SDL_BindAudioStreams")}
def public unbind_audio_stream(stream : SDL_AudioStream?) {SDL_UnbindAudioStream(stream)}
def public unbind_audio_streams(streams : array<SDL_AudioStream?>) {return sdl_status(SDL_UnbindAudioStreamsArray(streams), "SDL_UnbindAudioStreamsArray")}
// Device close unbinds streams; it does not destroy them. Do not close borrowed id.
def public with_audio_device(device : uint; body : block<(id : uint) : $Result<auto(TT); SdlError>>) {
    let id = SDL_OpenAudioDevice(device, null)
    if (id == 0u) {return err(sdl_error("SDL_OpenAudioDevice"), type<TT>)}
    {
        defer() {SDL_CloseAudioDevice(id)}
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) {return body(id)}
        else {return <- body(id)}
    }
}
def public with_audio_device(device : uint; spec : SDL_AudioSpec; body : block<(id : uint) : $Result<auto(TT); SdlError>>) {
    let id = SDL_OpenAudioDeviceRef(device, spec)
    if (id == 0u) {return err(sdl_error("SDL_OpenAudioDevice"), type<TT>)}
    {
        defer() {SDL_CloseAudioDevice(id)}
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) {return body(id)}
        else {return <- body(id)}
    }
}

struct AudioDeviceFormat { spec : SDL_AudioSpec; sample_frames : int }
def public audio_device_format(device : uint) {
    var value : AudioDeviceFormat
    let status = audio_device_format(device, value.sample_frames)
    if (is_err(status)) { return err(unwrap_err(status), type<AudioDeviceFormat>) }
    value.spec = unwrap(status)
    return ok(value, type<SdlError>)
}
