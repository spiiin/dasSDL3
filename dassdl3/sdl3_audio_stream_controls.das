options gen2
module sdl3_audio_stream_controls shared public
require dassdl3/sdl3_audio_devices_boost public
require daslib/defer

def public audio_stream_properties(stream : SDL_AudioStream?) {
    let id=SDL_GetAudioStreamProperties(stream)
    if(id==0u) {return err(sdl_error("SDL_GetAudioStreamProperties"),type<uint>)}
    return ok(id,type<SdlError>)
}
def public audio_stream_formats(stream : SDL_AudioStream?; var src,dst : SDL_AudioSpec&) {return sdl_status(SDL_GetAudioStreamFormatsRef(stream,src,dst),"SDL_GetAudioStreamFormat")}
def public set_audio_stream_formats(stream : SDL_AudioStream?; src,dst : SDL_AudioSpec) {return sdl_status(SDL_SetAudioStreamFormatsRef(stream,src,dst),"SDL_SetAudioStreamFormat")}
def public set_audio_stream_input_format(stream : SDL_AudioStream?; src : SDL_AudioSpec) {return sdl_status(SDL_SetAudioStreamInputFormatRef(stream,src),"SDL_SetAudioStreamFormat")}
def public set_audio_stream_output_format(stream : SDL_AudioStream?; dst : SDL_AudioSpec) {return sdl_status(SDL_SetAudioStreamOutputFormatRef(stream,dst),"SDL_SetAudioStreamFormat")}
def public audio_stream_frequency_ratio(stream : SDL_AudioStream?) {
    let value=SDL_GetAudioStreamFrequencyRatio(stream)
    if(value==0.0) {return err(sdl_error("SDL_GetAudioStreamFrequencyRatio"),type<float>)}
    return ok(value,type<SdlError>)
}
def public set_audio_stream_frequency_ratio(stream : SDL_AudioStream?; value : float) {return sdl_status(SDL_SetAudioStreamFrequencyRatio(stream,value),"SDL_SetAudioStreamFrequencyRatio")}
def public audio_stream_gain(stream : SDL_AudioStream?) {
    let value=SDL_GetAudioStreamGain(stream)
    if(value<0.0) {return err(sdl_error("SDL_GetAudioStreamGain"),type<float>)}
    return ok(value,type<SdlError>)
}
def public set_audio_stream_gain(stream : SDL_AudioStream?; value : float) {return sdl_status(SDL_SetAudioStreamGain(stream,value),"SDL_SetAudioStreamGain")}
def public set_audio_stream_input_channel_map(stream : SDL_AudioStream?; map : array<int>) {return sdl_status(SDL_SetAudioStreamInputChannelMapArray(stream,map),"SDL_SetAudioStreamInputChannelMap")}
def public reset_audio_stream_input_channel_map(stream : SDL_AudioStream?; channels : int) {return sdl_status(SDL_ResetAudioStreamInputChannelMap(stream,channels),"SDL_SetAudioStreamInputChannelMap")}
def public set_audio_stream_output_channel_map(stream : SDL_AudioStream?; map : array<int>) {return sdl_status(SDL_SetAudioStreamOutputChannelMapArray(stream,map),"SDL_SetAudioStreamOutputChannelMap")}
def public reset_audio_stream_output_channel_map(stream : SDL_AudioStream?; channels : int) {return sdl_status(SDL_ResetAudioStreamOutputChannelMap(stream,channels),"SDL_SetAudioStreamOutputChannelMap")}
def public lock_audio_stream(stream : SDL_AudioStream?) {return sdl_status(SDL_LockAudioStream(stream),"SDL_LockAudioStream")}
def public unlock_audio_stream(stream : SDL_AudioStream?) {return sdl_status(SDL_UnlockAudioStream(stream),"SDL_UnlockAudioStream")}
// Same thread, synchronous block. Never destroy stream or unlock this scope's lock inside body.
def public with_audio_stream_lock(stream : SDL_AudioStream?; body : block<() : $Result<auto(TT); SdlError>>) {
    if(!SDL_LockAudioStream(stream)) {return err(sdl_error("SDL_LockAudioStream"),type<TT>)}
    var result : $Result<TT; SdlError>
    {
        defer() {
            let unlocked=SDL_UnlockAudioStream(stream)
            if(!unlocked && is_ok(result)) {result <- err(sdl_error("SDL_UnlockAudioStream"),type<TT>)}
        }
        static_if(typeinfo can_copy(type<$Result<TT; SdlError>>)) {result=body()}
        else {result <- body()}
    }
    return <- result
}
