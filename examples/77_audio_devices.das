options gen2
require dassdl3/sdl3_audio_devices_boost
require dassdl3/sdl3_scope

def example() : SdlStatus {
    return sdl_scope() {
        with_sdl(SDL_INIT_AUDIO) |> sdl_use
        let devices <- audio_playback_devices() |> sdl_try
        for(id in devices) {
            let name=id |> audio_device_name() |> sdl_try
            print("Playback device {id}: {name}\n")
        }
        let recording <- audio_recording_devices() |> sdl_try
        print("Recording devices available: {length(recording)} (not opened).\n")
        let device : uint = with_audio_device(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK) |> sdl_use
        let format=device |> audio_device_format() |> sdl_try
        let spec=format.spec
        print("Logical device: {spec.freq} Hz, {spec.channels} channels, {format.sample_frames} frames per buffer.\n")
        let stream : SDL_AudioStream? = with_audio_stream(spec,spec) |> sdl_use
        device |> pause_audio_device() |> sdl_try
        device |> bind_audio_stream(stream) |> sdl_try
        device |> set_audio_device_gain(0.5) |> sdl_try
        let gain=device |> audio_device_gain() |> sdl_try
        print("Bound an empty stream; gain: {gain}. No audio queued.\n")
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result=example()
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
