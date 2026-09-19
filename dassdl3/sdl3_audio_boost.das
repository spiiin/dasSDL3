options gen2
module sdl3_audio_boost shared public
require dassdl3/sdl3_boost public
require daslib/rtti
require daslib/strings_boost

def private check_audio(ok : bool; operation : string) {
    if (!ok) { panic("{operation}: {SDL_GetError()}") }
}
def public load_wav(path : string) {
    var wav = SDL_LoadWavOwned(path)
    if (wav == null) { panic("SDL_LoadWAV({path}): {SDL_GetError()}") }
    return wav
}
def public destroy_wav(wav : SDL_Wav?) { SDL_DestroyWav(wav) }
def public wav_spec(wav : SDL_Wav?) {
    verify(wav != null, "wav_spec: null WAV")
    return SDL_WavSpec(wav)
}
def public wav_size(wav : SDL_Wav?) : uint {
    verify(wav != null, "wav_size: null WAV")
    return SDL_WavSize(wav)
}
def public audio_format(spec : SDL_AudioSpec) : uint { return SDL_AudioSpecFormat(spec) }
def public audio_spec(format : uint; channels, frequency : int) {
    return SDL_MakeAudioSpec(format, channels, frequency)
}
def public with_wav(path : string; blk : block<(wav : SDL_Wav?) : void>) {
    var wav = load_wav(path)
    var failed = false
    var error = ""
    try { SDL_InvokeWav(blk, wav) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    destroy_wav(wav)
    if (failed) { panic(error) }
}
def public create_audio_stream(src, dst : SDL_AudioSpec) {
    var stream = SDL_CreateAudioStreamRef(src, dst)
    if (stream == null) { panic("SDL_CreateAudioStream: {SDL_GetError()}") }
    return stream
}
def public open_playback(spec : SDL_AudioSpec) {
    var stream = SDL_OpenPlaybackStream(spec)
    if (stream == null) { panic("SDL_OpenAudioDeviceStream: {SDL_GetError()}") }
    return stream
}
def public destroy_audio_stream(stream : SDL_AudioStream?) {
    if (stream != null) { SDL_DestroyAudioStream(stream) }
}
def private with_owned_audio_stream(stream : SDL_AudioStream?;
                                   blk : block<(stream : SDL_AudioStream?) : void>) {
    var failed = false
    var error = ""
    try { SDL_InvokeAudioStream(blk, stream) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    destroy_audio_stream(stream)
    if (failed) { panic(error) }
}
def public with_audio_stream(src, dst : SDL_AudioSpec;
                             blk : block<(stream : SDL_AudioStream?) : void>) {
    var stream = create_audio_stream(src, dst)
    with_owned_audio_stream(stream, blk)
}
def public with_playback(spec : SDL_AudioSpec;
                         blk : block<(stream : SDL_AudioStream?) : void>) {
    var stream = open_playback(spec)
    with_owned_audio_stream(stream, blk)
}
def public queue_wav(stream : SDL_AudioStream?; wav : SDL_Wav?) {
    check_audio(SDL_QueueWav(stream, wav), "queue_wav")
}
def public put_audio(stream : SDL_AudioStream?; bytes : array<uint8>) {
    check_audio(SDL_PutAudioBytes(stream, bytes), "put_audio")
}
def public read_audio(stream : SDL_AudioStream?; var bytes : array<uint8>) : int {
    let read = SDL_GetAudioBytes(stream, bytes)
    if (read < 0) { panic("read_audio: {SDL_GetError()}") }
    return read
}
def public queued_audio(stream : SDL_AudioStream?) : int {
    let size = SDL_GetAudioStreamQueued(stream)
    if (size < 0) { panic("SDL_GetAudioStreamQueued: {SDL_GetError()}") }
    return size
}
def public available_audio(stream : SDL_AudioStream?) : int {
    let size = SDL_GetAudioStreamAvailable(stream)
    if (size < 0) { panic("SDL_GetAudioStreamAvailable: {SDL_GetError()}") }
    return size
}
def public flush_audio(stream : SDL_AudioStream?) {
    check_audio(SDL_FlushAudioStream(stream), "SDL_FlushAudioStream")
}
def public clear_audio(stream : SDL_AudioStream?) {
    check_audio(SDL_ClearAudioStream(stream), "SDL_ClearAudioStream")
}
def public resume_audio(stream : SDL_AudioStream?) {
    check_audio(SDL_ResumeAudioStreamDevice(stream), "SDL_ResumeAudioStreamDevice")
}
def public pause_audio(stream : SDL_AudioStream?) {
    check_audio(SDL_PauseAudioStreamDevice(stream), "SDL_PauseAudioStreamDevice")
}
