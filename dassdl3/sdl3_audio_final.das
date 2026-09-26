options gen2
module sdl3_audio_final shared public
require dassdl3/sdl3_audio_stream_controls public
require daslib/defer

def public audio_spec(format : SDL_AudioFormat; channels, frequency : int) {return SDL_MakeAudioSpec(uint(format), channels, frequency)}
def public audio_format_name(format : SDL_AudioFormat) : string {return SDL_GetAudioFormatName(format)}
def public audio_silence_value(format : SDL_AudioFormat) : int {return SDL_GetSilenceValueForFormat(format)}
// Native C addresses and native userdata only; never script blocks or movable script storage.
def public set_audio_stream_get_callback(stream : SDL_AudioStream?; callback, userdata : void?) {return sdl_status(SDL_SetAudioStreamGetCallback(stream, callback, userdata), "SDL_SetAudioStreamGetCallback")}
def public set_audio_stream_put_callback(stream : SDL_AudioStream?; callback, userdata : void?) {return sdl_status(SDL_SetAudioStreamPutCallback(stream, callback, userdata), "SDL_SetAudioStreamPutCallback")}
def public set_audio_postmix_callback(device : uint; callback, userdata : void?) {return sdl_status(SDL_SetAudioPostmixCallback(device, callback, userdata), "SDL_SetAudioPostmixCallback")}
def public open_audio_device_stream(device : uint; spec : SDL_AudioSpec; callback : void? = null; userdata : void? = null) {
    var stream = SDL_OpenAudioDeviceStreamRef(device, spec, callback, userdata)
    if (stream == null) {return err(sdl_error("SDL_OpenAudioDeviceStream"), type<SDL_AudioStream?>)}
    return <- move_ok(stream, type<SdlError>)
}
def public with_audio_device_stream(device : uint; spec : SDL_AudioSpec; callback, userdata : void?; body : block<(stream : SDL_AudioStream?) : $Result<auto(TT); SdlError>>) {
    let stream = SDL_OpenAudioDeviceStreamRef(device, spec, callback, userdata)
    if (stream == null) {return err(sdl_error("SDL_OpenAudioDeviceStream"), type<TT>)}
    {
        defer() {SDL_DestroyAudioStream(stream)}
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) {return body(stream)}
        else {return <- body(stream)}
    }
}
// Borrows io; use with_io for explicit fallible close, or raw closeio=true for transfer.
def public load_wav_io(io : SDL_IOStream?; var spec : SDL_AudioSpec&) {
    var bytes : array<uint8>
    if (!SDL_LoadWAV_IOCopy(io, spec, bytes)) {return err(sdl_error("SDL_LoadWAV_IO"), type<array<uint8>>)}
    return <- move_ok(bytes, type<SdlError>)
}
def public mix_audio(var dst : array<uint8>; src : array<uint8>; format : SDL_AudioFormat; count : uint; volume : float = 1.0) {return sdl_status(SDL_MixAudioArray(dst, src, format, count, volume), "SDL_MixAudio")}
def public convert_audio_samples(src_spec : SDL_AudioSpec; bytes : array<uint8>; dst_spec : SDL_AudioSpec) {
    var converted : array<uint8>
    if (!SDL_ConvertAudioSamplesArray(src_spec, bytes, dst_spec, converted)) {return err(sdl_error("SDL_ConvertAudioSamples"), type<array<uint8>>)}
    return <- move_ok(converted, type<SdlError>)
}

struct WavData { spec : SDL_AudioSpec; bytes : array<uint8> }
def public load_wav_io(io : SDL_IOStream?) {
    var value : WavData
    var status <- load_wav_io(io, value.spec)
    if (is_err(status)) { return err(unwrap_err(status), type<WavData>) }
    value.bytes <- move_unwrap(status)
    return <- move_ok(value, type<SdlError>)
}
