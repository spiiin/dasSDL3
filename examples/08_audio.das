options gen2
require dassdl3/sdl3_audio_boost

// Based on SDL 3.2.18 examples/audio/03-load-wav (public-domain code).
// Original quiet tone asset; no callbacks from the audio thread into daScript.
var example_failed = false

[export]
def main(smoke : bool) : int {
    let scope_ok_0 = with_sdl(SDL_INIT_AUDIO) {
        let scope_ok_1 = with_wav("{SDL_GetBasePath()}assets/tone.wav") $(wav) {
            let spec = wav_spec(wav)
            print("WAV: {spec.freq} Hz, {spec.channels} channel(s), {wav_size(wav)} bytes\n")
            let scope_ok_2 = with_playback(spec) $(stream) {
                if (!(stream |> queue_wav(wav))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                if (!(stream |> flush_audio())) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                if (!(stream |> resume_audio())) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                let start = SDL_GetTicks()
                while (queued_audio(stream) > 0 || available_audio(stream) > 0) {
                    if (SDL_GetTicks() - start > 5000ul) { panic("Audio playback timed out") }
                    SDL_Delay(10u)
                }
                // Queue-empty is not a hardware playback-complete signal.
                SDL_Delay(100u)
            }
            if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
        if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    print("Audio stream and WAV released.\n")
    return example_failed ? 1 : 0
}
