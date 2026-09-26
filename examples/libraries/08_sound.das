options gen2
require dassdl3/sdl3_sound_boost
require dassdl3/sdl3_audio_boost
require dassdl3/sdl3_scope

// SDL_sound decodes; SDL's audio stream plays copied PCM.
def play_sample(sample : Sound_Sample?) {
    return sdl_scope() {
        let stream : SDL_AudioStream? = with_playback(sound_output_format(sample)) |> sdl_use
        var bytes : array<uint8>
        var total=0u
        while(true) {
            let state=sample |> decode_sound(bytes) |> sdl_try
            if(state.bytes_read!=0u) {stream |> put_audio(bytes) |> sdl_try}
            total+=state.bytes_read
            if(state.eof) {break}
            if(state.again) {SDL_Delay(1u)}
        }
        stream |> flush_audio() |> sdl_try
        stream |> resume_audio() |> sdl_try
        let deadline=SDL_GetTicks()+3000ul
        while(true) {
            let queued=stream |> queued_audio() |> sdl_try
            if(queued==0) {break}
            if(SDL_GetTicks()>deadline) {return err(SdlError(operation="play_sample",message="Playback timed out"),type<SdlUnit>)}
            SDL_Delay(10u)
        }
        // Let the device consume its last submitted buffer.
        SDL_Delay(100u)
        print("SDL_sound decoded and queued {int(total)} PCM bytes.\n")
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl(SDL_INIT_AUDIO) |> sdl_use
        with_sound() |> sdl_use
        let spec=SDL_AudioSpec(format=SDL_AudioFormat.AUDIO_S16,channels=1,freq=48000)
        let sample : Sound_Sample? = with_sound_sample("{SDL_GetBasePath()}assets/libraries/mixer-tone.wav",spec,1024u) |> sdl_use
        return play_sample(sample)
    }
    if(is_err(result)) {
        let error=unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
