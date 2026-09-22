options gen2
require dassdl3/sdl3_audio_devices_boost
require dassdl3/sdl3_scope
require daslib/safe_addr
require daslib/defer

[export]
def main(smoke : bool) : int {
    verify(SDL_GetNumAudioDrivers()>0)
    verify(length(SDL_GetAudioDriver(0))>0)
    verify(is_some(audio_driver(0)) && is_none(audio_driver(-1)))
    verify(is_none(current_audio_driver()))
    let result=with_sdl(SDL_INIT_AUDIO) {
        verify(SDL_GetCurrentAudioDriver()=="dummy")
        verify(unwrap(current_audio_driver())=="dummy")
        var count=0
        unsafe {
            let playback=SDL_GetAudioPlaybackDevices(addr(count))
            verify(playback!=null && count>0)
            SDL_free(playback)
            let recording=SDL_GetAudioRecordingDevices(addr(count))
            verify(recording!=null && count>0)
            SDL_free(recording)
        }
        var output <- audio_playback_devices() |> sdl_try
        var input <- audio_recording_devices() |> sdl_try
        verify(length(output)>0 && length(input)>0)
        verify(SDL_IsAudioDevicePhysical(output[0]) && SDL_IsAudioDevicePlayback(output[0]))
        verify(SDL_IsAudioDevicePhysical(input[0]) && !SDL_IsAudioDevicePlayback(input[0]))
        verify(length(SDL_GetAudioDeviceName(output[0]))>0)
        let saved_name=audio_device_name(output[0]) |> sdl_try
        verify(is_err(audio_device_name(0u)))
        var frames=0
        var spec : SDL_AudioSpec
        unsafe {verify(SDL_GetAudioDeviceFormat(output[0],addr(spec),addr(frames)))}
        verify(spec.channels>0 && spec.freq>0 && frames>0)
        unsafe {let mapping=SDL_GetAudioDeviceChannelMap(output[0],addr(count));SDL_free(mapping)}
        SDL_SetErrorText("stale")
        var optional_map <- audio_device_channel_map(output[0]) |> sdl_try
        verify(is_none(optional_map))
        let preferred=audio_device_format(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,frames) |> sdl_try
        verify(preferred.channels>0)
        verify(is_err(audio_device_format(0u,frames)))
        let format=audio_device_format(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK) |> sdl_try
        verify(format.spec.freq==preferred.freq && format.sample_frames>0)
        verify(is_err(open_audio_device(0u)))
        let first=SDL_OpenAudioDevice(output[0],null)
        verify(first!=0u && !SDL_IsAudioDevicePhysical(first) && SDL_IsAudioDevicePlayback(first))
        {
            defer() {SDL_CloseAudioDevice(first)}
            verify(SDL_PauseAudioDevice(first) && SDL_AudioDevicePaused(first))
            verify(SDL_ResumeAudioDevice(first) && !SDL_AudioDevicePaused(first))
            verify(SDL_SetAudioDeviceGain(first,0.25) && SDL_GetAudioDeviceGain(first)==0.25)
            verify(!SDL_SetAudioDeviceGain(first,-1.0))
            let gain=audio_device_gain(first) |> sdl_try
            verify(gain==0.25 && is_err(audio_device_gain(0u)))
            set_audio_device_gain(first,0.5) |> sdl_try
            pause_audio_device(first) |> sdl_try
            verify(audio_device_paused(first))
            let pcm=audio_spec(SDL_AUDIO_S16LE,1,22050)
            var second=open_audio_device(first,pcm) |> sdl_try
            verify(second!=first && second!=0u)
            close_audio_device(second)
            verify(second==0u)
            {
                var a=SDL_CreateAudioStreamRef(pcm,pcm)
                var b=SDL_CreateAudioStreamRef(pcm,pcm)
                verify(a!=null && b!=null)
                {
                    defer() {SDL_DestroyAudioStream(b);SDL_DestroyAudioStream(a)}
                    verify(SDL_BindAudioStream(first,a) && SDL_GetAudioStreamDevice(a)==first)
                    SDL_UnbindAudioStream(a)
                    verify(SDL_GetAudioStreamDevice(a)==0u)
                    var streams <- array<SDL_AudioStream?>(a,b)
                    unsafe {verify(SDL_BindAudioStreams(first,addr(streams[0]),2))}
                    verify(SDL_GetAudioStreamDevice(a)==first && SDL_GetAudioStreamDevice(b)==first)
                    unsafe {SDL_UnbindAudioStreams(addr(streams[0]),2)}
                    verify(SDL_GetAudioStreamDevice(a)==0u && SDL_GetAudioStreamDevice(b)==0u)
                    bind_audio_streams(first,streams) |> sdl_try
                    unbind_audio_streams(streams) |> sdl_try
                    bind_audio_stream(first,a) |> sdl_try
                    unbind_audio_stream(a)
                    // Closing a device unbinds, but keeps the stream alive.
                    var temporary=open_audio_device(first) |> sdl_try
                    bind_audio_stream(temporary,a) |> sdl_try
                    close_audio_device(temporary)
                    verify(SDL_GetAudioStreamDevice(a)==0u)
                    verify(SDL_GetAudioStreamAvailable(a)==0)
                }
            }
            resume_audio_device(first) |> sdl_try
            verify(!audio_device_paused(first))
        }
        verify(length(saved_name)>0)
        var closed_id=0u
        let failed_scope=with_audio_device(output[0],spec) $(id) {
            closed_id=id
            return err(SdlError(operation="body",message="early exit"),type<SdlUnit>)
        }
        verify(is_err(failed_scope) && unwrap_err(failed_scope).operation=="body")
        verify(SDL_GetAudioDeviceGain(closed_id)<0.0)
        var moved <- with_audio_device(output[0]) $(id) {
            closed_id=id
            return <- audio_playback_devices()
        }
        verify(is_ok(moved) && SDL_GetAudioDeviceGain(closed_id)<0.0)
        var copied_ids <- move_unwrap(moved)
        verify(length(copied_ids)>0)
        var called=false
        let rejected=with_audio_device(0u) $(id) {called=true;return sdl_ok()}
        verify(is_err(rejected) && !called)
        // Recording test is dummy-only: never opens a real microphone.
        return sdl_scope() {
            let device : uint = with_audio_device(SDL_AUDIO_DEVICE_DEFAULT_RECORDING) |> sdl_use
            verify(!SDL_IsAudioDevicePlayback(device))
            var recording_frames=0
            let native=audio_device_format(device,recording_frames) |> sdl_try
            let pcm=audio_spec(SDL_AUDIO_S16LE,1,22050)
            let stream : SDL_AudioStream? = with_audio_stream(native,pcm) |> sdl_use
            device |> bind_audio_stream(stream) |> sdl_try
            device |> resume_audio_device() |> sdl_try
            let deadline=SDL_GetTicks()+3000ul
            while(SDL_GetAudioStreamAvailable(stream)<32 && SDL_GetTicks()<deadline) {SDL_Delay(5u)}
            var bytes : array<uint8>
            resize(bytes,32)
            let received=read_audio(stream,bytes) |> sdl_try
            verify(received==32)
            for(value in bytes) {verify(value==0)}
            return sdl_ok()
        }
    }
    verify(is_ok(result))
    verify(is_none(current_audio_driver()))
    print("Audio devices: discovery, logical ownership, stream binding and dummy recording passed.\n")
    return 0
}
