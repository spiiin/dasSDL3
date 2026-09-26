options gen2
require daslib/defer
module sdl3_audio_boost shared public
require dassdl3/sdl3_boost public

def public load_wav(path : string) {
    var wav = SDL_LoadWavOwned(path)
    var value = wav
    if (value == null) { return err(sdl_error("load_wav"), type<SDL_Wav?>) }
    return <- move_ok(value, type<SdlError>)
}
def public destroy_wav(wav : SDL_Wav?) { SDL_DestroyWav(wav) }
def public wav_spec(wav : SDL_Wav?) {
    if (wav == null) { SDL_SetErrorText("wav_spec: null WAV"); return err(sdl_error("wav_spec"), type<SDL_AudioSpec>) }
    return ok(SDL_WavSpec(wav), type<SdlError>)
}
def public wav_size(wav : SDL_Wav?) {
    if (wav == null) { SDL_SetErrorText("wav_size: null WAV"); return err(sdl_error("wav_size"), type<uint>) }
    return ok(SDL_WavSize(wav), type<SdlError>)
}
def public audio_format(spec : SDL_AudioSpec) : uint { return SDL_AudioSpecFormat(spec) }
def public audio_spec(format : uint; channels, frequency : int) {
    return SDL_MakeAudioSpec(format, channels, frequency)
}
def public with_wav(path : string; blk : block<(wav : SDL_Wav?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var wav = SDL_LoadWavOwned(path)
    if (wav == null) { return err(sdl_error("with_wav"), type<TT>) }
    {
        defer() { SDL_DestroyWav(wav) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(wav) } else { scope_result <- blk(wav) }
    }

    return <- scope_result
}
def public create_audio_stream(src, dst : SDL_AudioSpec) {
    var stream = SDL_CreateAudioStreamRef(src, dst)
    var value = stream
    if (value == null) { return err(sdl_error("create_audio_stream"), type<SDL_AudioStream?>) }
    return <- move_ok(value, type<SdlError>)
}
def public open_playback(spec : SDL_AudioSpec) {
    var stream = SDL_OpenPlaybackStream(spec)
    var value = stream
    if (value == null) { return err(sdl_error("open_playback"), type<SDL_AudioStream?>) }
    return <- move_ok(value, type<SdlError>)
}
def public destroy_audio_stream(stream : SDL_AudioStream?) {
    if (stream != null) { SDL_DestroyAudioStream(stream) }
}
def private with_owned_audio_stream(stream : SDL_AudioStream?;
                                    blk : block<(stream : SDL_AudioStream?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    if (stream == null) { return err(sdl_error("with_owned_audio_stream"), type<TT>) }
    {
        defer() { SDL_DestroyAudioStream(stream) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(stream) } else { scope_result <- blk(stream) }
    }

    return <- scope_result
}
def public with_audio_stream(src, dst : SDL_AudioSpec;
                             blk : block<(stream : SDL_AudioStream?) : $Result<auto(TT); SdlError> >) {
    var stream = SDL_CreateAudioStreamRef(src, dst)
    return <- with_owned_audio_stream(stream, blk)
}
def public with_playback(spec : SDL_AudioSpec;
                         blk : block<(stream : SDL_AudioStream?) : $Result<auto(TT); SdlError> >) {
    var stream = SDL_OpenPlaybackStream(spec)
    return <- with_owned_audio_stream(stream, blk)
}
def public queue_wav(stream : SDL_AudioStream?; wav : SDL_Wav?) {
    return sdl_status(SDL_QueueWav(stream, wav), "queue_wav")
}
def public put_audio(stream : SDL_AudioStream?; bytes : array<uint8>) {
    return sdl_status(SDL_PutAudioBytes(stream, bytes), "put_audio")
}
def public read_audio(stream : SDL_AudioStream?; var bytes : array<uint8>) {
    let read = SDL_GetAudioBytes(stream, bytes)
    let value = read
    if (value < 0) { return err(sdl_error("read_audio"), type<int>) }
    return ok(value, type<SdlError>)
}
def public queued_audio(stream : SDL_AudioStream?) {
    let size = SDL_GetAudioStreamQueued(stream)
    let value = size
    if (value < 0) { return err(sdl_error("queued_audio"), type<int>) }
    return ok(value, type<SdlError>)
}
def public available_audio(stream : SDL_AudioStream?) {
    let size = SDL_GetAudioStreamAvailable(stream)
    let value = size
    if (value < 0) { return err(sdl_error("available_audio"), type<int>) }
    return ok(value, type<SdlError>)
}
def public flush_audio(stream : SDL_AudioStream?) {
    return sdl_status(SDL_FlushAudioStream(stream), "flush_audio")
}
def public clear_audio(stream : SDL_AudioStream?) {
    return sdl_status(SDL_ClearAudioStream(stream), "clear_audio")
}
def public resume_audio(stream : SDL_AudioStream?) {
    return sdl_status(SDL_ResumeAudioStreamDevice(stream), "resume_audio")
}
def public pause_audio(stream : SDL_AudioStream?) {
    return sdl_status(SDL_PauseAudioStreamDevice(stream), "pause_audio")
}
