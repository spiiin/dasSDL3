options gen2
require daslib/defer
module sdl3_audio_boost shared public
require dassdl3/sdl3_boost public

def public load_wav(path : string) {
    var wav = SDL_LoadWavOwned(path)
    return wav
}
def public destroy_wav(wav : SDL_Wav?) { SDL_DestroyWav(wav) }
def public wav_spec(wav : SDL_Wav?) {
    return SDL_WavSpec(wav)
}
def public wav_size(wav : SDL_Wav?) : uint {
    return SDL_WavSize(wav)
}
def public audio_format(spec : SDL_AudioSpec) : uint { return SDL_AudioSpecFormat(spec) }
def public audio_spec(format : uint; channels, frequency : int) {
    return SDL_MakeAudioSpec(format, channels, frequency)
}
def public with_wav(path : string; blk : block<(wav : SDL_Wav?) : void>) {
    var wav = load_wav(path)
    if (wav == null) { return false }
    {
        defer() { SDL_DestroyWav(wav) }
        blk(wav)
        return true
    }
}
def public create_audio_stream(src, dst : SDL_AudioSpec) {
    var stream = SDL_CreateAudioStreamRef(src, dst)
    return stream
}
def public open_playback(spec : SDL_AudioSpec) {
    var stream = SDL_OpenPlaybackStream(spec)
    return stream
}
def public destroy_audio_stream(stream : SDL_AudioStream?) {
    if (stream != null) { SDL_DestroyAudioStream(stream) }
}
def private with_owned_audio_stream(stream : SDL_AudioStream?;
                                   blk : block<(stream : SDL_AudioStream?) : void>) {
    if (stream == null) { return false }
    {
        defer() { SDL_DestroyAudioStream(stream) }
        blk(stream)
        return true
    }
}
def public with_audio_stream(src, dst : SDL_AudioSpec;
                             blk : block<(stream : SDL_AudioStream?) : void>) {
    var stream = create_audio_stream(src, dst)
    return with_owned_audio_stream(stream, blk)
}
def public with_playback(spec : SDL_AudioSpec;
                         blk : block<(stream : SDL_AudioStream?) : void>) {
    var stream = open_playback(spec)
    return with_owned_audio_stream(stream, blk)
}
def public queue_wav(stream : SDL_AudioStream?; wav : SDL_Wav?) {
    return SDL_QueueWav(stream, wav)
}
def public put_audio(stream : SDL_AudioStream?; bytes : array<uint8>) {
    return SDL_PutAudioBytes(stream, bytes)
}
def public read_audio(stream : SDL_AudioStream?; var bytes : array<uint8>) : int {
    let read = SDL_GetAudioBytes(stream, bytes)
    return read
}
def public queued_audio(stream : SDL_AudioStream?) : int {
    let size = SDL_GetAudioStreamQueued(stream)
    return size
}
def public available_audio(stream : SDL_AudioStream?) : int {
    let size = SDL_GetAudioStreamAvailable(stream)
    return size
}
def public flush_audio(stream : SDL_AudioStream?) {
    return SDL_FlushAudioStream(stream)
}
def public clear_audio(stream : SDL_AudioStream?) {
    return SDL_ClearAudioStream(stream)
}
def public resume_audio(stream : SDL_AudioStream?) {
    return SDL_ResumeAudioStreamDevice(stream)
}
def public pause_audio(stream : SDL_AudioStream?) {
    return SDL_PauseAudioStreamDevice(stream)
}
