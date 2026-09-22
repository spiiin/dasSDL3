options gen2
require dassdl3/sdl3_audio_stream_controls
require dassdl3/sdl3_scope
require daslib/safe_addr
require math

[export]
def main(smoke : bool) : int {
    let stereo=audio_spec(SDL_AUDIO_F32,2,48000)
    let mono=audio_spec(SDL_AUDIO_F32,1,48000)
    let tested=with_audio_stream(stereo,stereo) $(stream) {
        let props=SDL_GetAudioStreamProperties(stream)
        verify(props!=0u && unwrap(audio_stream_properties(stream))==props)
        verify(SDL_SetNumberProperty(props,"test",42l) && SDL_GetNumberProperty(props,"test",0l)==42l)
        var src,dst : SDL_AudioSpec
        audio_stream_formats(stream,src,dst) |> sdl_try
        verify(src.channels==2 && dst.channels==2)
        let formats=audio_stream_formats(stream) |> sdl_try
        verify(formats.source.channels==2 && formats.destination.channels==2)
        unsafe {verify(SDL_SetAudioStreamFormat(stream,addr(stereo),addr(stereo)))}
        verify(SDL_GetAudioStreamGain(stream)==1.0 && SDL_GetAudioStreamFrequencyRatio(stream)==1.0)
        verify(!SDL_SetAudioStreamFrequencyRatio(stream,0.0) && !SDL_SetAudioStreamFrequencyRatio(stream,101.0))
        verify(!SDL_SetAudioStreamGain(stream,-0.5))
        verify(SDL_LockAudioStream(stream) && SDL_LockAudioStream(stream))
        verify(SDL_UnlockAudioStream(stream) && SDL_UnlockAudioStream(stream))
        var mapping <- array<int>(1,0)
        unsafe {verify(SDL_SetAudioStreamInputChannelMap(stream,addr(mapping[0]),2))}
        var count=0
        unsafe {
            let raw=SDL_GetAudioStreamInputChannelMap(stream,addr(count))
            verify(raw!=null && count==2 && raw[0]==1 && raw[1]==0)
            SDL_free(raw)
        }
        mapping[0]=0;mapping[1]=1
        var pcm <- array<float>(0.25,0.75,-0.5,0.125)
        unsafe {verify(SDL_PutAudioStreamData(stream,addr(pcm[0]),16))}
        // Input map belongs to queued data. Resetting now must not change it.
        reset_audio_stream_input_channel_map(stream,2) |> sdl_try
        verify(SDL_SetAudioStreamGain(stream,0.5))
        verify(unwrap(audio_stream_gain(stream))==0.5)
        verify(SDL_FlushAudioStream(stream))
        var out : array<float>
        resize(out,4)
        unsafe {verify(SDL_GetAudioStreamData(stream,addr(out[0]),16)==16)}
        verify(out[0]==0.375 && out[1]==0.125 && out[2]==0.0625 && out[3]==-0.25)
        set_audio_stream_gain(stream,1.0) |> sdl_try
        unsafe {verify(SDL_PutAudioStreamData(stream,addr(pcm[0]),16))}
        var muted <- array<int>(-1,0)
        unsafe {verify(SDL_SetAudioStreamOutputChannelMap(stream,addr(muted[0]),2))}
        unsafe {
            let raw=SDL_GetAudioStreamOutputChannelMap(stream,addr(count))
            verify(raw!=null && count==2 && raw[0]==-1 && raw[1]==0)
            SDL_free(raw)
        }

        verify(SDL_FlushAudioStream(stream))
        unsafe {verify(SDL_GetAudioStreamData(stream,addr(out[0]),16)==16)}
        verify(out[0]==0.0 && out[1]==0.25 && out[2]==0.0 && out[3]==-0.5)
        reset_audio_stream_output_channel_map(stream,2) |> sdl_try
        // Pinned raw getters crash on a default (null) map; never query it.
        var wrong <- array<int>(0)
        verify(is_err(set_audio_stream_input_channel_map(stream,wrong)))
        wrong <- array<int>(2,0)
        verify(is_err(set_audio_stream_output_channel_map(stream,wrong)))
        var empty : array<int>
        verify(is_err(set_audio_stream_input_channel_map(stream,empty)))
        verify(is_err(reset_audio_stream_output_channel_map(stream,1)))
        set_audio_stream_input_channel_map(stream,mapping) |> sdl_try
        set_audio_stream_output_channel_map(stream,mapping) |> sdl_try

        // Old queued input retains its format after the input format changes.
        unsafe {verify(SDL_PutAudioStreamData(stream,addr(pcm[0]),8))}
        set_audio_stream_input_format(stream,mono) |> sdl_try
        var single=0.5
        unsafe {verify(SDL_PutAudioStreamData(stream,addr(single),4))}
        verify(SDL_FlushAudioStream(stream))
        unsafe {verify(SDL_GetAudioStreamData(stream,addr(out[0]),16)==16)}
        verify(out[0]==0.25 && out[1]==0.75 && out[2]==0.5 && out[3]==0.5)
        set_audio_stream_output_format(stream,mono) |> sdl_try
        audio_stream_formats(stream,src,dst) |> sdl_try
        verify(src.channels==1 && dst.channels==1)
        set_audio_stream_formats(stream,stereo,stereo) |> sdl_try
        var many : array<float>
        resize(many,512)
        for(i in 0..length(many)) {many[i]=0.25}
        verify(SDL_SetAudioStreamFrequencyRatio(stream,2.0))
        verify(unwrap(audio_stream_frequency_ratio(stream))==2.0)
        unsafe {verify(SDL_PutAudioStreamData(stream,addr(many[0]),2048))}
        verify(SDL_FlushAudioStream(stream))
        verify(SDL_GetAudioStreamAvailable(stream)==1024)
        var resampled : array<float>
        resize(resampled,256)
        unsafe {verify(SDL_GetAudioStreamData(stream,addr(resampled[0]),1024)==1024)}
        verify(abs(resampled[100]-0.25)<0.001)
        set_audio_stream_frequency_ratio(stream,1.0) |> sdl_try
        let failed=with_audio_stream_lock(stream) {return err(SdlError(operation="body",message="early"),type<SdlUnit>)}
        verify(is_err(failed) && unwrap_err(failed).operation=="body")
        verify(SDLTestAudioStreamLockFromThread(stream))
        var moved <- with_audio_stream_lock(stream) {var values <- array<int>(7,8);return <- move_ok(values,type<SdlError>)}
        verify(is_ok(moved))
        var values <- move_unwrap(moved)
        verify(values[0]==7 && SDLTestAudioStreamLockFromThread(stream))
        lock_audio_stream(stream) |> sdl_try
        unlock_audio_stream(stream) |> sdl_try
        return sdl_ok()
    }
    verify(is_ok(tested))
    verify(is_err(audio_stream_properties(null)))
    verify(is_err(audio_stream_gain(null)) && is_err(audio_stream_frequency_ratio(null)))
    verify(is_err(set_audio_stream_input_channel_map(null,array<int>(0))))
    var called=false
    let invalid=with_audio_stream_lock(null) {called=true;return sdl_ok()}
    verify(is_err(invalid) && !called)
    let bound=sdl_scope() {
        with_sdl(SDL_INIT_AUDIO) |> sdl_use
        let device : uint = with_audio_device(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK) |> sdl_use
        let stream : SDL_AudioStream? = with_audio_stream(stereo,stereo) |> sdl_use
        device |> pause_audio_device() |> sdl_try
        device |> bind_audio_stream(stream) |> sdl_try
        var before_src,before_dst,after_src,after_dst : SDL_AudioSpec
        audio_stream_formats(stream,before_src,before_dst) |> sdl_try
        set_audio_stream_output_format(stream,mono) |> sdl_try
        audio_stream_formats(stream,after_src,after_dst) |> sdl_try
        verify(after_dst.channels==before_dst.channels && after_dst.freq==before_dst.freq)
        return sdl_ok()
    }
    verify(is_ok(bound))
    print("Audio stream controls: PCM maps, gain, ratio, format history and deferred unlock passed.\n")
    return 0
}
