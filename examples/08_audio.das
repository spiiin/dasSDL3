options gen2
require dassdl3/sdl3_audio_boost

// Based on SDL 3.2.18 examples/audio/03-load-wav (public-domain code).
// Original quiet tone asset; no callbacks from the audio thread into daScript.

def play_audio(wav : SDL_Wav?; stream : SDL_AudioStream?) : $Result<SdlUnit; SdlError> {
    var queue_wav_result <- stream |> queue_wav(wav)
    if (is_err(queue_wav_result)) { return queue_wav_result }
    var flush_audio_result <- stream |> flush_audio()
    if (is_err(flush_audio_result)) { return flush_audio_result }
    var resume_audio_result <- stream |> resume_audio()
    if (is_err(resume_audio_result)) { return resume_audio_result }
    let start = SDL_GetTicks()
    while (true) {
        let pending=queued_audio(stream)
        if (is_err(pending)) {return err(unwrap_err(pending),type<SdlUnit>)}
        let available=available_audio(stream)
        if (is_err(available)) {return err(unwrap_err(available),type<SdlUnit>)}
        if (unwrap(pending)==0 && unwrap(available)==0) {break}
        if (SDL_GetTicks() - start > 5000ul) { return err(SdlError(operation="audio playback",message="Playback timed out"),type<SdlUnit>) }
        SDL_Delay(10u)
    }
    // Queue-empty is not a hardware playback-complete signal.
    SDL_Delay(100u)

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl(SDL_INIT_AUDIO) {
        return with_wav("{SDL_GetBasePath()}assets/tone.wav") $(wav : SDL_Wav?) {
            let spec = unwrap_or(wav_spec(wav), default<SDL_AudioSpec>)
            print("WAV: {spec.freq} Hz, {spec.channels} channel(s), {unwrap_or(wav_size(wav),0u)} bytes\n")
            return with_playback(spec) $(stream : SDL_AudioStream?) {
                return play_audio(wav, stream)
            }
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Audio stream and WAV released.\n")
    return 0
}
