options gen2
require dassdl3/sdl3_audio_boost
require dassdl3/sdl3_scope
require daslib/safe_addr
[export]
def main(smoke : bool) : int {
    // Native size_t output pointers must also compile with the installed AOT SDK.
    unsafe {
        var bytes : uint8[3]
        bytes[0] = uint8(1); bytes[1] = uint8(2); bytes[2] = uint8(3)
        var size = 99ul
        let input = SDL_IOFromConstMem(safe_addr(bytes[0]), 3ul)
        verify(input != null)
        let loaded = SDL_LoadFile_IO(input, safe_addr(size), true)
        verify(loaded != null && size == 3ul)
        SDL_free(loaded)
        size = 99ul
        verify(SDL_LoadFile("missing-sdk-file-{SDL_GetTicksNS()}", safe_addr(size)) == null && size == 0ul)
    }
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
