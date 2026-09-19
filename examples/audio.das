options gen2
require dassdl3/sdl3_audio_boost

// Based on SDL 3.2.18 examples/audio/03-load-wav (public-domain code).
// Original quiet tone asset; no callbacks from the audio thread into daScript.
[export]
def main(smoke : bool) : int {
    with_sdl(SDL_INIT_AUDIO) {
        with_wav("{SDL_GetBasePath()}assets/tone.wav") $(wav) {
            let spec = wav_spec(wav)
            print("WAV: {spec.freq} Hz, {spec.channels} channel(s), {wav_size(wav)} bytes\n")
            with_playback(spec) $(stream) {
                stream |> queue_wav(wav)
                stream |> flush_audio()
                stream |> resume_audio()
                let start = SDL_GetTicks()
                while (queued_audio(stream) > 0 || available_audio(stream) > 0) {
                    if (SDL_GetTicks() - start > 5000ul) { panic("Audio playback timed out") }
                    SDL_Delay(10u)
                }
                // Queue-empty is not a hardware playback-complete signal.
                SDL_Delay(100u)
            }
        }
    }
    print("Audio stream and WAV released.\n")
    return 0
}
