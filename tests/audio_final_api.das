options gen2
require dassdl3/sdl3_audio_final
require dassdl3/sdl3_scope
require daslib/safe_addr
require daslib/defer

def wav_bytes() {
    return <- array<uint8>(82,73,70,70,40,0,0,0,87,65,86,69,102,109,116,32,16,0,0,0,1,0,1,0,64,31,0,0,128,62,0,0,2,0,16,0,100,97,116,97,4,0,0,0,0,64,0,192)
}
[export]
def main(smoke : bool) : int {
    let s16=SDL_AudioFormat.AUDIO_S16LE
    let f32=SDL_AudioFormat.AUDIO_F32
    verify(SDL_GetAudioFormatName(s16)=="SDL_AUDIO_S16LE")
    verify(SDL_GetSilenceValueForFormat(SDL_AudioFormat.AUDIO_U8)==128)
    verify(audio_silence_value(f32)==0)
    verify(audio_format_name(SDL_AudioFormat.AUDIO_UNKNOWN)=="SDL_AUDIO_UNKNOWN")
    let src=audio_spec(s16,1,8000)
    let dst=audio_spec(f32,2,8000)
    verify(src.format==s16)
    var wav <- wav_bytes()
    var pcm <- array<uint8>(0,64,0,192)
    var spec : SDL_AudioSpec
    var raw : uint8?
    var count=0u
    unsafe {
        let io=SDL_IOFromConstMem(addr(wav[0]),uint64(length(wav)))
        verify(SDL_LoadWAV_IO(io,true,addr(spec),addr(raw),addr(count)))
        verify(count==4u && spec.channels==1 && spec.freq==8000 && spec.format==s16)
        for(i in 0..4) {verify(raw[i]==pcm[i])}
        SDL_free(raw)
        let borrowed=SDL_IOFromConstMem(addr(wav[0]),uint64(length(wav)))
        var loaded <- load_wav_io(borrowed,spec)
        verify(is_ok(loaded) && SDL_GetIOSize(borrowed)==48l)
        var owned <- move_unwrap(loaded)
        verify(SDL_CloseIO(borrowed))
        verify(length(owned)==4 && owned[1]==64)
        let invalid=SDL_IOFromConstMem(addr(pcm[0]),4ul)
        var rejected <- load_wav_io(invalid,spec)
        verify(is_err(rejected))
        verify(SDL_GetIOSize(invalid)==4l && SDL_CloseIO(invalid))
        let bad_owned=SDL_IOFromConstMem(addr(pcm[0]),4ul)
        verify(!SDL_LoadWAV_IO(bad_owned,true,addr(spec),addr(raw),addr(count)))
    }
    var expected <- array<uint8>(0,0,0,63,0,0,0,63,0,0,0,191,0,0,0,191)
    unsafe {
        var converted : uint8?
        var size=0
        verify(SDL_ConvertAudioSamples(addr(src),addr(pcm[0]),4,addr(dst),addr(converted),addr(size)))
        verify(size==16)
        for(i in 0..16) {verify(converted[i]==expected[i])}
        SDL_free(converted)
        var mixed <- array<uint8>(0,64,0,192)
        verify(SDL_MixAudio(addr(mixed[0]),addr(pcm[0]),s16,4u,1.0))
        verify(mixed[0]==255 && mixed[1]==127 && mixed[2]==0 && mixed[3]==128)
    }
    var result <- convert_audio_samples(src,pcm,dst)
    verify(is_ok(result))
    var converted <- move_unwrap(result)
    verify(length(converted)==16)
    for(i in 0..16) {verify(converted[i]==expected[i])}
    var mixed <- array<uint8>(0,0,0,0)
    verify(is_ok(mix_audio(mixed,pcm,s16,4u,0.5)))
    verify(mixed[1]==32 && mixed[3]==224)
    verify(is_err(mix_audio(mixed,pcm,s16,5u)))
    verify(is_err(mix_audio(mixed,pcm,s16,4u,2.0)))
    verify(is_err(mix_audio(mixed,pcm,s16,3u)))
    var partial <- array<uint8>(0,0,0)
    verify(is_err(convert_audio_samples(src,partial,dst)))
    verify(!SDL_ConvertAudioSamplesArray(src,pcm,dst,pcm) && length(pcm)==4)
    var empty : array<uint8>
    var converted_empty <- convert_audio_samples(src,empty,dst)
    verify(is_ok(converted_empty))
    var zero <- move_unwrap(converted_empty)
    verify(length(zero)==0)
    verify(is_ok(mix_audio(empty,empty,s16,0u)))
    verify(is_err(convert_audio_samples(audio_spec(0u,1,8000),pcm,dst)))
    let floatmono=audio_spec(f32,1,8000)
    SDLTestAudioFinalReset()
    let callbacks=with_audio_stream(floatmono,floatmono) $(stream) {
        verify(SDL_SetAudioStreamGetCallback(stream,SDLTestAudioFinalCallback(0),SDLTestAudioFinalData()))
        verify(SDL_SetAudioStreamPutCallback(stream,SDLTestAudioFinalCallback(1),SDLTestAudioFinalData()))
        verify(SDLTestAudioFinalReadOnThread(stream))
        verify(SDLTestAudioFinalCount(0)>0 && SDLTestAudioFinalCount(1)>0 && SDLTestAudioFinalCount(4)>0)
        set_audio_stream_get_callback(stream,null,null) |> sdl_try
        set_audio_stream_put_callback(stream,null,null) |> sdl_try
        let gets=SDLTestAudioFinalCount(0)
        let puts=SDLTestAudioFinalCount(1)
        var bytes <- array<uint8>(0,0,0,0)
        put_audio(stream,bytes) |> sdl_try
        read_audio(stream,bytes) |> sdl_try
        verify(SDLTestAudioFinalCount(0)==gets && SDLTestAudioFinalCount(1)==puts)
        return sdl_ok()
    }
    verify(is_ok(callbacks) && SDLTestAudioFinalCount(3)==0)
    verify(is_err(set_audio_stream_get_callback(null,null,null)))
    verify(is_err(set_audio_stream_put_callback(null,null,null)))
    let devices=with_sdl(SDL_INIT_AUDIO) {
        verify(SDL_GetCurrentAudioDriver()=="dummy")
        let before_playback=SDLTestAudioFinalCount(0)
        var stream : SDL_AudioStream?
        unsafe {stream=SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,addr(floatmono),SDLTestAudioFinalCallback(0),SDLTestAudioFinalData())}
        verify(stream!=null && SDL_AudioStreamDevicePaused(stream))
        let device=SDL_GetAudioStreamDevice(stream)
        verify(SDL_SetAudioPostmixCallback(device,SDLTestAudioFinalCallback(2),SDLTestAudioFinalData()))
        verify(SDL_ResumeAudioStreamDevice(stream))
        let deadline=SDL_GetTicks()+3000ul
        while(SDLTestAudioFinalCount(2)==0 && SDL_GetTicks()<deadline) {SDL_Delay(5u)}
        set_audio_postmix_callback(device,null,null) |> sdl_try
        set_audio_stream_get_callback(stream,null,null) |> sdl_try
        let posts=SDLTestAudioFinalCount(2)
        let gets=SDLTestAudioFinalCount(0)
        SDL_Delay(150u)
        verify(posts>0 && gets>before_playback && SDLTestAudioFinalCount(2)==posts && SDLTestAudioFinalCount(0)==gets)
        SDL_DestroyAudioStream(stream)
        verify(SDL_GetAudioDeviceGain(device)<0.0)
        // Pinned SDL returns true even for an invalid logical ID; preserve its return.
        verify(is_ok(set_audio_postmix_callback(0u,null,null)))
        let puts=SDLTestAudioFinalCount(1)
        let recording=with_audio_device_stream(SDL_AUDIO_DEVICE_DEFAULT_RECORDING,floatmono,SDLTestAudioFinalCallback(1),SDLTestAudioFinalData()) $(record_stream) {
            verify(SDL_ResumeAudioStreamDevice(record_stream))
            let until=SDL_GetTicks()+3000ul
            while(SDLTestAudioFinalCount(1)==puts && SDL_GetTicks()<until) {SDL_Delay(5u)}
            return sdl_ok()
        }
        verify(is_ok(recording) && SDLTestAudioFinalCount(1)>puts)
        var opened <- open_audio_device_stream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,floatmono)
        verify(is_ok(opened))
        SDL_DestroyAudioStream(move_unwrap(opened))
        verify(is_err(open_audio_device_stream(0u,floatmono)))
        return sdl_ok()
    }
    verify(is_ok(devices) && SDLTestAudioFinalCount(3)==0)
    print("Audio final API: WAV IO, PCM mixing/conversion, native callbacks and unregister barriers passed.\n")
    return 0
}
