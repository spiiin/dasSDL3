options gen2
require dassdl3/sdl3_mixer_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_init_boost

// SDL_mixer owns tracks and audio; the example adds no scheduling layer.
def play_chord(mixer : MIX_Mixer?; smoke : bool) {
    return sdl_scope() {
        let low : MIX_Audio? = mixer |> with_mix_sine_audio(440, 0.08, 350l) |> sdl_use
        let high : MIX_Audio? = mixer |> with_mix_sine_audio(660, 0.08, 350l) |> sdl_use
        let first : MIX_Track? = mixer |> with_mix_track() |> sdl_use
        let second : MIX_Track? = mixer |> with_mix_track() |> sdl_use
        first |> set_mix_audio(low) |> sdl_try
        second |> set_mix_audio(high) |> sdl_try
        first |> play_mix_track() |> sdl_try
        second |> play_mix_track() |> sdl_try
        let deadline = SDL_GetTicks() + 2000ul
        while (MIX_TrackPlaying(first) || MIX_TrackPlaying(second)) {
            if (SDL_GetTicks() > deadline) {
                return err(SdlError(operation = "play_chord", message = "Playback timed out"), type<SdlUnit>)
            }
            SDL_Delay(10u)
        }
        print("Two tracks completed; track/audio scopes release their owners.\n")
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl_subsystems(SDL_INIT_AUDIO) |> sdl_use
        with_mixer_system() |> sdl_use
        let format = SDL_AudioSpec(format = SDL_AudioFormat.AUDIO_F32, channels = 2, freq = 48000)
        let mixer : MIX_Mixer? = with_mixer_device(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, format) |> sdl_use
        return play_chord(mixer, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
