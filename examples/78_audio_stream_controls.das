options gen2
require dassdl3/sdl3_audio_stream_controls
require dassdl3/sdl3_scope

def example() : $Result<SdlUnit; SdlError> {
    let pcm=audio_spec(SDL_AUDIO_S16LE,2,48000)
    return sdl_scope() {
        let stream : SDL_AudioStream? = with_audio_stream(pcm,pcm) |> sdl_use
        stream |> with_audio_stream_lock() |> sdl_use
        stream |> set_audio_stream_input_channel_map(array<int>(1,0)) |> sdl_try
        var configured <- stream |> audio_stream_input_channel_map() |> sdl_try
        if(is_some(configured)) {
            var channels <- move_unwrap(configured)
            print("Input mapping: {channels[0]}, {channels[1]}\n")
        }
        stream |> set_audio_stream_gain(0.5) |> sdl_try
        stream |> set_audio_stream_frequency_ratio(1.0) |> sdl_try
        // Two stereo PCM16 frames: (1024,2048), (-1024,-2048).
        var bytes <- array<uint8>(0,4,0,8,0,252,0,248)
        stream |> put_audio(bytes) |> sdl_try
        stream |> flush_audio() |> sdl_try
        var output : array<uint8>
        resize(output,8)
        let count=stream |> read_audio(output) |> sdl_try
        print("Swapped stereo channels and applied half gain: {count} bytes.\n")
        for(value in output) {print("  {uint(value)}\n")}
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result=example()
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
