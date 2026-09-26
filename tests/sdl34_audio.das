options gen2
require dassdl3/sdl3_remaining_34_boost
require dassdl3/sdl3_audio_boost
require daslib/defer

def planar {
    var spec=SDL_AudioSpec(format=SDL_AudioFormat.AUDIO_F32,channels=2,freq=48000)
    let stream=SDL_CreateAudioStreamRef(spec,spec);verify(stream!=null)
    defer(){SDL_DestroyAudioStream(stream)}
    var samples <- array<float>(0.1,0.2,0.3,0.4, -0.1,-0.2,-0.3,-0.4)
    var output : array<float>;resize(output,8)
    unsafe {
        var planes <- array<void?>(addr(samples[0]),addr(samples[4]))
        verify(SDL_PutAudioStreamPlanarData(stream,addr(planes[0]),2,4))
        verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(output[0]),32)==32)
    }
    for(i in 0..4){verify(output[2*i]==samples[i] && output[2*i+1]==samples[i+4])}
    verify(is_ok(put_audio_planar(stream,samples,2,4)))
    for(value in samples){value=0.0}
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(output[0]),32)==32)}
    verify(output[0]==0.1 && output[1]==-0.1) // Input was copied before mutation.
    var mono <- array<float>(0.25,0.5)
    verify(is_ok(put_audio_planar(stream,mono,1,2)))
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(output[0]),16)==16)}
    verify(output[0]==0.25 && output[1]==0.0 && output[2]==0.5 && output[3]==0.0)
    var extra <- array<float>(0.1,0.2,0.8)
    verify(is_ok(put_audio_planar(stream,extra,3,1)))
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(output[0]),8)==8)}
    verify(output[0]==0.1 && output[1]==0.2)
    var empty : array<float>
    verify(is_ok(put_audio_planar(stream,empty,0,2)))
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(output[0]),16)==16)}
    for(i in 0..4){verify(output[i]==0.0)}
    verify(is_ok(put_audio_planar(stream,empty,0,0)))
    verify(is_err(put_audio_planar(stream,mono,2,2)))
    verify(is_err(put_audio_planar(stream,empty,0,2147483647)))
    verify(is_err(put_audio_planar(stream,empty,-1,0)))
    verify(is_err(put_audio_planar(null,mono,1,2)))
    spec.format=SDL_AudioFormat.AUDIO_S16
    verify(SDL_SetAudioStreamFormatsRef(stream,spec,spec))
    verify(is_err(put_audio_planar(stream,mono,1,2)))
    var pcm <- array<uint8>(1,0,2,0, 3,0,4,0)
    verify(is_ok(put_audio_planar(stream,pcm,2,2)))
    var interleaved : array<uint8>;resize(interleaved,8)
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(interleaved[0]),8)==8)}
    verify(interleaved[0]==uint8(1) && interleaved[2]==uint8(3) && interleaved[4]==uint8(2) && interleaved[6]==uint8(4))
    verify(is_err(put_audio_planar(stream,pcm,2,3)))
    var no_bytes : array<uint8>
    verify(is_err(put_audio_planar(stream,no_bytes,2147483647,2147483647)))
    spec.format=SDL_AudioFormat.AUDIO_U8;verify(SDL_SetAudioStreamFormatsRef(stream,spec,spec))
    verify(is_ok(put_audio_planar(stream,no_bytes,0,2)))
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(interleaved[0]),4)==4)}
    for(i in 0..4){verify(interleaved[i]==uint8(128))} // Unsigned PCM silence is not zero.
    spec.channels=1;verify(SDL_SetAudioStreamFormatsRef(stream,spec,spec))
    unsafe {
        var absent : void?
        verify(!SDL_PutAudioStreamPlanarData(stream,addr(absent),0,2)) // Pinned mono/null-plane defect.
    }
    verify(is_ok(put_audio_planar(stream,no_bytes,0,2)))
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(interleaved[0]),2)==2)}
    verify(interleaved[0]==uint8(128) && interleaved[1]==uint8(128))
    spec.format=SDL_AudioFormat.AUDIO_F32;verify(SDL_SetAudioStreamFormatsRef(stream,spec,spec))
    verify(is_ok(put_audio_planar(stream,empty,0,2)))
    unsafe{verify(SDL_FlushAudioStream(stream) && SDL_GetAudioStreamData(stream,addr(output[0]),8)==8)}
    verify(output[0]==0.0 && output[1]==0.0)
    verify(!SDL_PutAudioStreamPlanarData(null,null,0,0))
}
def no_copy {
    SDLTestRemaining34Reset()
    var spec=SDL_AudioSpec(format=SDL_AudioFormat.AUDIO_S16,channels=2,freq=48000)
    let stream=SDL_CreateAudioStreamRef(spec,spec);verify(stream!=null)
    // Each callback owns only SDL_malloc storage, never a script array or Context.
    for(kind in 0..3){
        let bytes=SDLTestRemaining34Allocate();verify(bytes!=null)
        verify(SDL_PutAudioStreamDataNoCopy(stream,bytes,64,SDLTestRemaining34Callback(false),null))
        verify(SDLTestRemaining34Count(false)==kind)
        if(kind==0){verify(SDL_FlushAudioStream(stream) && SDLTestRemaining34ConsumeWorker(stream))}
        elif(kind==1){verify(SDL_ClearAudioStream(stream))}
        else {SDL_DestroyAudioStream(stream)}
        verify(SDLTestRemaining34Count(false)==kind+1 && SDLTestRemaining34Count(true)==0)
    }
    let rejected=SDLTestRemaining34Allocate();verify(rejected!=null)
    verify(!SDL_PutAudioStreamDataNoCopy(null,rejected,64,SDLTestRemaining34Callback(false),null))
    verify(SDLTestRemaining34Count(false)==3);SDL_free(rejected)
    let empty_stream=SDL_CreateAudioStreamRef(spec,spec);verify(empty_stream!=null)
    let empty_buffer=SDLTestRemaining34Allocate();verify(empty_buffer!=null)
    verify(SDL_PutAudioStreamDataNoCopy(empty_stream,empty_buffer,0,SDLTestRemaining34Callback(false),null))
    verify(SDLTestRemaining34Count(false)==4) // Zero-length completion is synchronous.
    SDL_DestroyAudioStream(empty_stream)
    verify(SDLTestRemaining34Count(false)==4 && SDLTestRemaining34Count(true)==0)
}
[export]
def main(smoke : bool) : int {
    verify(SDL_Init(0u));defer(){SDL_Quit()}
    planar();no_copy()
    print("SDL 3.4 audio: planar interleaving/copies/silence/bounds; native no-copy completion on read/clear/destroy PASS\n")
    return 0
}
