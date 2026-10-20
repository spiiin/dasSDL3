options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_mixer_boost

// Opt-in hardware test. Never add to the default dummy/CI test suite.
[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl(SDL_INIT_AUDIO) |> sdl_use
        let driver=SDL_GetCurrentAudioDriverCopy()
        verify(driver!="dummy" && driver!="disk" && driver!="")
        with_mixer_system() |> sdl_use
        let spec=SDL_AudioSpec(format=SDL_AudioFormat.AUDIO_F32,channels=2,freq=48000)
        let mixer : MIX_Mixer? = with_mixer_device(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,spec) |> sdl_use
        let audio : MIX_Audio? = mixer |> with_mix_sine_audio(440,0.03,1500l) |> sdl_use
        let track : MIX_Track? = mixer |> with_mix_track() |> sdl_use
        track |> set_mix_audio(audio) |> sdl_try
        track |> play_mix_track() |> sdl_try
        SDL_Delay(250u)
        let playing=MIX_GetTrackPlaybackPosition(track)
        verify(playing>0l && MIX_TrackPlaying(track))
        track |> pause_mix_track() |> sdl_try
        let paused=MIX_GetTrackPlaybackPosition(track)
        SDL_Delay(120u)
        verify(MIX_TrackPaused(track) && MIX_GetTrackPlaybackPosition(track)==paused)
        track |> resume_mix_track() |> sdl_try
        SDL_Delay(250u)
        let resumed=MIX_GetTrackPlaybackPosition(track)
        verify(resumed>paused && MIX_TrackPlaying(track))
        track |> stop_mix_track() |> sdl_try
        verify(!MIX_TrackPlaying(track))
        print("AUDIO={driver}; playback={playing}; paused={paused}; resumed={resumed}; stop verified\n")
        return sdl_ok()
    }
    if(is_err(result)) {
        let error=unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
