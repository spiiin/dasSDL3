options gen2
module sdl3_sound_boost shared public
require sdl3_sound public
require dassdl3/sdl3_result public
require daslib/defer

// Sound_GetError has its own thread-local, consuming error channel.
def public sound_error(operation : string) : SdlError {
    return SdlError(operation=operation,message=Sound_GetErrorCopy())
}
struct SoundDecodeState {
    bytes_read : uint
    eof : bool
    again : bool
}
def public sound_actual_format(sample : Sound_Sample?) {
    var spec : SDL_AudioSpec
    Sound_GetSampleActualRef(sample,spec)
    return spec
}
def public sound_output_format(sample : Sound_Sample?) {
    var spec : SDL_AudioSpec
    Sound_GetSampleDesiredRef(sample,spec)
    return spec
}
def public create_sound_sample(path : string; spec : SDL_AudioSpec; buffer_size : uint = 4096u) {
    if (!Sound_ValidateSampleRequest(spec,buffer_size)) {return err(sdl_error("create_sound_sample"),type<Sound_Sample?>)}
    var sample = Sound_NewSampleFromFileRef(path,spec,buffer_size)
    if (sample==null) {return err(sound_error("Sound_NewSampleFromFile"),type<Sound_Sample?>)}
    return <- move_ok(sample,type<SdlError>)
}
// bytes remains available even on decoder error (a partial final chunk).
// EOF is sticky; do not call raw Decode again after EOF.
def public decode_sound(sample : Sound_Sample?; var bytes : array<uint8>) {
    resize(bytes,0)
    if (sample==null) {return err(SdlError(operation="decode_sound",message="Null sample"),type<SoundDecodeState>)}
    let before=Sound_GetSampleFlags(sample)
    if ((before & uint(Sound_SampleFlags.SOUND_SAMPLEFLAG_ERROR))!=0u) {
        return err(SdlError(operation="Sound_Decode",message="Sample already has a decoder error; rewind or recreate it"),type<SoundDecodeState>)
    }
    if ((before & uint(Sound_SampleFlags.SOUND_SAMPLEFLAG_EOF))!=0u) {
        return ok(SoundDecodeState(eof=true),type<SdlError>)
    }
    let count=Sound_Decode(sample)
    let flags=Sound_GetSampleFlags(sample)
    let failed=(flags & uint(Sound_SampleFlags.SOUND_SAMPLEFLAG_ERROR))!=0u
    var error : SdlError
    if (failed) {error=sound_error("Sound_Decode")}
    if (!Sound_CopySampleBytes(sample,count,bytes)) {return err(sdl_error("Sound_CopySampleBytes"),type<SoundDecodeState>)}
    if (failed) {return err(error,type<SoundDecodeState>)}
    return ok(SoundDecodeState(bytes_read=count,eof=(flags & uint(Sound_SampleFlags.SOUND_SAMPLEFLAG_EOF))!=0u,
        again=(flags & uint(Sound_SampleFlags.SOUND_SAMPLEFLAG_EAGAIN))!=0u),type<SdlError>)
}
def public rewind_sound(sample : Sound_Sample?) {
    if(sample==null) {return err(SdlError(operation="Sound_Rewind",message="Null sample"),type<SdlUnit>)}
    if(Sound_Rewind(sample)==0) {return err(sound_error("Sound_Rewind"),type<SdlUnit>)}
    return sdl_ok()
}
def public seek_sound(sample : Sound_Sample?; milliseconds : uint) {
    if(sample==null) {return err(SdlError(operation="Sound_Seek",message="Null sample"),type<SdlUnit>)}
    if(Sound_Seek(sample,milliseconds)==0) {return err(sound_error("Sound_Seek"),type<SdlUnit>)}
    return sdl_ok()
}
def public with_sound(blk : block<() : $Result<auto(SoundValue); SdlError>>) : $Result<SoundValue; SdlError> {
    if(Sound_Init()==0) {return err(sound_error("Sound_Init"),type<SoundValue>)}
    var result : $Result<SoundValue; SdlError>
    {
        defer() { Sound_Quit() }
        static_if(typeinfo can_copy(type<$Result<SoundValue; SdlError>>)) { result=blk() }
        else {result <- blk()}
    }
    return <- result
}
def public with_sound_sample(path : string; spec : SDL_AudioSpec; buffer_size : uint;
    blk : block<(sample : Sound_Sample?) : $Result<auto(SoundValue); SdlError>>) : $Result<SoundValue; SdlError> {
    var loaded=create_sound_sample(path,spec,buffer_size)
    if(is_err(loaded)) {return err(unwrap_err(loaded),type<SoundValue>)}
    var sample <- move_unwrap(loaded)
    var result : $Result<SoundValue; SdlError>
    {
        defer() {Sound_FreeSample(sample)}
        static_if(typeinfo can_copy(type<$Result<SoundValue; SdlError>>)) { result=blk(sample) }
        else {result <- blk(sample)}
    }
    return <- result
}
