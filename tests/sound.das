options gen2
require dassdl3/sdl3_sound_boost
require dassdl3/sdl3_scope
require daslib/safe_addr
require math

[export]
def main(smoke : bool) : int {
    verify(Sound_Version() == 3002000)
    verify(Sound_Init() == 1)
    verify(Sound_Init() == 0)// Not a reference-counted session.
    let captured = sound_error("second init")
    verify(length(captured.message) > 0)
    verify(length(Sound_GetError()) == 0)
    Sound_ClearError()
    verify(Sound_AvailableDecoders() != null)
    verify(Sound_GetDecoderCount() > 0u)
    let decoder = Sound_GetDecoderAt(0u)
    verify(decoder != null && Sound_GetDecoderAt(9999u) == null)
    verify(length(Sound_GetDecoderAuthorCopy(decoder)) > 0)
    verify(length(Sound_GetDecoderUrlCopy(decoder)) > 0)
    verify(length(Sound_GetDecoderExtensionCopy(decoder, 0u)) > 0)
    verify(length(Sound_GetDecoderExtensionCopy(decoder, 9999u)) == 0)
    let path = "{SDL_GetBasePath()}assets/libraries/mixer-tone.wav"
    let sample = Sound_NewSampleFromFile(path, null, 1024u)
    verify(sample != null)
    verify(Sound_GetDuration(sample) == 100)
    let actual = sound_actual_format(sample)
    verify(actual.channels == 1 && actual.freq == 48000 && actual.format == SDL_AudioFormat.AUDIO_S16)
    verify(length(Sound_GetDecoderDescriptionCopy(Sound_GetSampleDecoder(sample))) > 0)
    verify(Sound_SetBufferSize(sample, 512u) == 1 && Sound_GetSampleBufferSize(sample) == 512u)
    verify(Sound_SetDesiredFormat(sample, null) == 1)
    verify(Sound_Decode(sample) == 512u)
    verify(Sound_Seek(sample, 0u) == 1)
    verify(Sound_Rewind(sample) == 1)
    verify(Sound_DecodeAll(sample) == 9600u)
    var bytes : array<uint8>
    verify(Sound_CopySampleBytes(sample, 9600u, bytes))
    Sound_FreeSample(sample)
    // Independent waveform oracle, not just a byte count.
    for (i in 0..4800) {
        var value = int(bytes[i * 2]) | (int(bytes[i * 2 + 1]) << 8)
        if (value >= 32768) {value -= 65536}
        let expected = int(2500.0 * sin(float(i) * 2.0 * 3.141592653589793 * 440.0 / 48000.0))
        verify(abs(value - expected) <= 1)
    }
    let io = SDL_IOFromFile(path, "rb")
    let from_io = Sound_NewSample(io, "WAV", null, 1024u)
    verify(from_io != null)
    Sound_FreeSample(from_io) // Also closes io.
    unsafe {
        let memory = Sound_NewSampleFromMem(addr(bytes[0]), uint(length(bytes)), "RAW", addr(actual), 1024u)
        verify(memory != null)
        verify(Sound_Decode(memory) > 0u)
        Sound_FreeSample(memory)
    }
    verify(Sound_NewSampleFromFile("missing-sound-file.wav", null, 1024u) == null)
    let error = sound_error("missing file")
    Sound_ClearError()
    verify(length(error.message) > 0 && length(captured.message) > 0)
    verify(Sound_Quit() == 1)
    var bad = create_sound_sample(path, actual, 0u)
    verify(is_err(bad))
    let scoped = sdl_scope() {
        with_sound() |> sdl_use
        let decoded : Sound_Sample? = with_sound_sample(path, actual, 1024u) |> sdl_use
        var owned <- with_sound_sample(path, actual, 1024u) $(copy_sample) {
            var chunk : array<uint8>
            decode_sound(copy_sample, chunk) |> sdl_try
            return <- move_ok(chunk, type<SdlError>)
        }
        verify(is_ok(owned))
        var owned_bytes <- move_unwrap(owned)
        verify(length(owned_bytes) == 1024)// The sample was already freed.
        var called = false
        let failed = with_sound_sample("missing-sound-file.wav", actual, 1024u) $(unused) {
            called = true
            return sdl_ok()
        }
        verify(is_err(failed) && !called)
        // A stale error must not contaminate successful decoding.
        verify(Sound_Init() == 0)
        var output : array<uint8>
        var total = 0u
        for (i in 0..20) {
            let state = decode_sound(decoded, output) |> sdl_try
            total += state.bytes_read
            if (state.eof) {break}
        }
        verify(total == 9600u)
        let eof = decode_sound(decoded, output) |> sdl_try
        verify(eof.eof && eof.bytes_read == 0u && length(output) == 0)
        rewind_sound(decoded) |> sdl_try
        seek_sound(decoded, 0u) |> sdl_try
        let first = decode_sound(decoded, output) |> sdl_try
        verify(first.bytes_read == 1024u)
        return err(SdlError(operation = "test", message = "early return"), type<SdlUnit>)
    }
    verify(is_err(scoped) && unwrap_err(scoped).message == "early return")
    verify(Sound_Init() == 1)// Scope released session, even on body Err.
    verify(Sound_Quit() == 1)
    SDL_Quit()
    print("SDL_sound raw exports, PCM oracle, EOF, seek and scopes passed.\n")
    return 0
}
