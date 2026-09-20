options gen2
require dassdl3/sdl3_audio_boost

// Based on SDL 3.2.18 examples/audio/03-load-wav (public-domain code).
// Original quiet tone asset; no callbacks from the audio thread into daScript.
var example_failed = false

[export]
def main(smoke : bool) : int {
    let scope_ok_0 = with_sdl(SDL_INIT_AUDIO) {
        let scope_ok_1 = with_wav("{SDL_GetBasePath()}assets/tone.wav") $(wav : SDL_Wav?) {
            let spec = unwrap_or(wav_spec(wav), default<SDL_AudioSpec>)
            print("WAV: {spec.freq} Hz, {spec.channels} channel(s), {unwrap_or(wav_size(wav),0u)} bytes\n")
            let scope_ok_2 = with_playback(spec) $(stream : SDL_AudioStream?) {
                var operation_result_1 <- stream |> queue_wav(wav)
                if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                var operation_result_2 <- stream |> flush_audio()
                if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                var operation_result_3 <- stream |> resume_audio()
                if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
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
            if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    print("Audio stream and WAV released.\n")
    return example_failed ? 1 : 0
}
