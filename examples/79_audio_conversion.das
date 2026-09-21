options gen2
require dassdl3/sdl3_audio_final
require dassdl3/sdl3_scope

def example() : $Result<SdlUnit; SdlError> {
    let format=SDL_AudioFormat.AUDIO_S16LE
    let input=audio_spec(format,1,8000)
    let output=audio_spec(SDL_AudioFormat.AUDIO_F32,2,8000)
    var original <- array<uint8>(0,64,0,192)
    var mix <- array<uint8>(0,0,0,0)
    mix_audio(mix,original,format,4u,0.5) |> sdl_try
    let converted <- convert_audio_samples(input,mix,output) |> sdl_try
    print("Mixed {audio_format_name(format)} mono at half gain.\n")
    print("Converted to stereo {audio_format_name(output.format)}: {length(converted)} bytes.\n")
    return sdl_scope() {
        let stream : SDL_AudioStream? = with_audio_stream(output,output) |> sdl_use
        stream |> put_audio(converted) |> sdl_try
        stream |> flush_audio() |> sdl_try
        let available=stream |> available_audio() |> sdl_try
        print("Queued {available} bytes in an in-memory stream. No device opened.\n")
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result=example()
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
