options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_audio_boost

// Based on SDL 3.2.18 examples/audio/03-load-wav (public-domain code).
// Original quiet tone asset; no callbacks from the audio thread into daScript.

def play_audio(wav : SDL_Wav?; stream : SDL_AudioStream?) : $Result<SdlUnit; SdlError> {
    stream |> queue_wav(wav) |> sdl_try
    stream |> flush_audio() |> sdl_try
    stream |> resume_audio() |> sdl_try
    let start = SDL_GetTicks()
    while (true) {
        let pending = queued_audio(stream) |> sdl_try
        let available = available_audio(stream) |> sdl_try
        if (pending==0 && available==0) {break}
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
            let spec = wav_spec(wav) |> sdl_try
            let bytes = wav_size(wav) |> sdl_try
            print("WAV: {spec.freq} Hz, {spec.channels} channel(s), {bytes} bytes\n")
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
