options gen2
require ./common/demo_support.das
require dassdl3/sdl3_mixer_boost
require dassdl3/sdl3_properties_boost
// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/15-sound-effects-and-music/index.php

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("15 sound effects and music",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_sdl_subsystems(SDL_INIT_AUDIO) |> sdl_use
        with_mixer_system() |> sdl_use
        let spec=SDL_AudioSpec(format=SDL_AudioFormat.AUDIO_F32,channels=2,freq=48000)
        let mixer : MIX_Mixer? = with_mixer_device(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,spec) |> sdl_use
        let music : MIX_Audio? = mixer |> with_mix_audio(asset("melody.wav"),false) |> sdl_use
        let effect : MIX_Audio? = mixer |> with_mix_sine_audio(880,0.08,120l) |> sdl_use
        let track : MIX_Track? = mixer |> with_mix_track() |> sdl_use
        let effect_track : MIX_Track? = mixer |> with_mix_track() |> sdl_use
        let props : uint = with_properties() |> sdl_use
        sdl_status(SDL_SetNumberProperty(props,MIX_PROP_PLAY_LOOPS_NUMBER,-1l),"SDL_SetNumberProperty") |> sdl_try
        track |> set_mix_audio(music) |> sdl_try
        effect_track |> set_mix_audio(effect) |> sdl_try
        var played=false
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(key_down=$v(key))) {
                    if(key.keycode==SDLK_SPACE){track |> play_mix_track(props) |> sdl_try;played=true}
                    if(key.keycode==SDLK_P){if(MIX_TrackPaused(track)){track |> resume_mix_track() |> sdl_try}else{track |> pause_mix_track() |> sdl_try}}
                    if(key.keycode==SDLK_S){track |> stop_mix_track() |> sdl_try}
                    if(key.keycode==SDLK_RETURN){effect_track |> play_mix_track() |> sdl_try}
                }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            renderer |> box(100.0,180.0,MIX_TrackPlaying(track) ? 440.0 : 40.0,80.0,uint4(80u,210u,140u,255u)) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(played && MIX_TrackPlaying(track))}
        track |> stop_mix_track() |> sdl_try
        effect_track |> stop_mix_track() |> sdl_try
        return sdl_ok()
    }
    return report(result)
}
