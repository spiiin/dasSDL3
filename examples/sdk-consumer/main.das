options gen2
require dassdl3/sdl3_audio_boost
require dassdl3/sdl3_scope
[export]
def main(smoke : bool) : int {
    let spec = audio_spec(SDL_AUDIO_S16LE, 2, 48000)
    let result = sdl_scope() {
        let stream : SDL_AudioStream? = with_audio_stream(spec, spec) |> sdl_use
        var pcm <- array<uint8>(0, 4, 0, 8)
        stream |> put_audio(pcm) |> sdl_try
        stream |> flush_audio() |> sdl_try
        var output : array<uint8>
        resize(output, 4)
        let count = stream |> read_audio(output) |> sdl_try
        if (count != 4 || output[1] != 4 || output[3] != 8) {
            return err(SdlError(operation = "PCM roundtrip", message = "Unexpected samples"), type<SdlUnit>)
        }
        return sdl_ok()
    }
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    print("Installed SDK: PCM roundtrip and deferred cleanup passed.\n")
    return 0
}
