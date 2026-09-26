options gen2
require dassdl3/sdl3_mixer_boost
require dassdl3/sdl3_scope
require daslib/safe_addr
require math

// Offline mixing has an exact PCM oracle, independent of speakers/timing.
def offline(mixer : MIX_Mixer?) {
    return sdl_scope() {
        var source : array<float>;resize(source,256)
        for (i in 0..256) {source[i]=0.25}
        let audio : MIX_Audio? = mixer |> with_mix_raw_audio(source,1,48000) |> sdl_use
        let track : MIX_Track? = mixer |> with_mix_track() |> sdl_use
        let other : MIX_Track? = mixer |> with_mix_track() |> sdl_use
        let grp : MIX_Group? = mixer |> with_mix_group() |> sdl_use
        source[0]=0.9 // MIX_LoadRawAudio copied the data.
        verify(MIX_GetTrackMixer(track)==mixer && MIX_GetGroupMixer(grp)==mixer)
        verify(MIX_GetMixerProperties(mixer)!=0u && MIX_GetAudioProperties(audio)!=0u)
        verify(MIX_GetTrackProperties(track)!=0u && MIX_GetGroupProperties(grp)!=0u)
        var fmt : SDL_AudioSpec
        unsafe {verify(MIX_GetMixerFormat(mixer,addr(fmt)) && MIX_GetAudioFormat(audio,addr(fmt)))}
        verify(fmt.channels==1 && fmt.freq==48000)
        verify(MIX_GetAudioDuration(audio)==256l)
        verify(MIX_AudioMSToFrames(audio,10l)==480l && MIX_AudioFramesToMS(audio,480l)==10l)
        verify(MIX_MSToFrames(48000,10l)==480l && MIX_FramesToMS(48000,480l)==10l)
        verify(MIX_SetTrackAudio(track,audio) && MIX_SetTrackAudio(other,audio))
        verify(MIX_GetTrackAudio(track)==audio && MIX_GetTrackAudioStream(track)==null)
        verify(MIX_TrackMSToFrames(track,10l)==480l && MIX_TrackFramesToMS(track,480l)==10l)
        verify(MIX_SetTrackGroup(track,grp))
        verify(MIX_TagTrack(track,"pair") && MIX_TagTrack(other,"pair"))
        unsafe {
            var count=0
            let tags=MIX_GetTrackTags(track,addr(count));verify(tags!=null && count==1);SDL_free(tags)
            let tracks=MIX_GetTaggedTracks(mixer,"pair",addr(count));verify(tracks!=null && count==2);SDL_free(tracks)
        }
        verify(MIX_SetMixerGain(mixer,0.5) && MIX_GetMixerGain(mixer)==0.5)
        verify(MIX_SetTrackGain(track,0.5) && MIX_GetTrackGain(track)==0.5)
        verify(MIX_SetTagGain(mixer,"pair",0.5))
        verify(MIX_SetMixerFrequencyRatio(mixer,1.0) && MIX_GetMixerFrequencyRatio(mixer)==1.0)
        verify(MIX_SetTrackFrequencyRatio(track,1.0) && MIX_GetTrackFrequencyRatio(track)==1.0)
        verify(MIX_PlayTag(mixer,"pair",0u))
        verify(MIX_PauseTag(mixer,"pair") && MIX_TrackPaused(track))
        verify(MIX_ResumeTag(mixer,"pair"))
        verify(MIX_PauseAllTracks(mixer) && MIX_ResumeAllTracks(mixer))
        verify(MIX_PauseTrack(track) && MIX_ResumeTrack(track))
        var output : array<float>;resize(output,512)
        let written=mixer |> generate_mix_audio(output) |> sdl_try
        verify(written==1024 && output[0]==0.125 && output[255]==0.125 && output[256]==0.0)
        verify(!MIX_TrackPlaying(track) && !MIX_TrackPaused(track))
        verify(MIX_StopTag(mixer,"pair",0l) && MIX_StopAllTracks(mixer,0l))
        MIX_UntagTrack(other,"pair")
        verify(MIX_PlayTrack(track,0u))
        verify(MIX_SetTrackLoops(track,1) && MIX_GetTrackLoops(track)==1)
        verify(MIX_SetTrackPlaybackPosition(track,32l) && MIX_GetTrackPlaybackPosition(track)==32l)
        verify(MIX_GetTrackRemaining(track)>=0l && MIX_GetTrackFadeFrames(track)==0l)
        verify(MIX_StopTrack(track,64l) && MIX_GetTrackFadeFrames(track)<0l)
        mixer |> generate_mix_audio(output) |> sdl_try
        verify(!MIX_TrackPlaying(track))
        SDL_SetErrorText("stale error must not turn success into Err")
        track |> play_mix_track() |> sdl_try
        verify(MIX_SetTrackLoops(track,1))
        mixer |> generate_mix_audio(output) |> sdl_try
        verify(output[0]==0.0625 && output[256]==0.0625 && output[511]==0.0625)
        track |> play_mix_track() |> sdl_try
        track |> pause_mix_track() |> sdl_try
        track |> resume_mix_track() |> sdl_try
        track |> seek_mix_track(0l) |> sdl_try
        track |> set_mix_gain(0.5) |> sdl_try
        track |> stop_mix_track() |> sdl_try
        var pos=MIX_Point3D(x=1.0,y=2.0,z=-3.0);var actual : MIX_Point3D
        var gains=MIX_StereoGains(left=0.25,right=0.75)
        unsafe {
            verify(MIX_SetTrack3DPosition(track,addr(pos)) && MIX_GetTrack3DPosition(track,addr(actual)))
            verify(actual.x==1.0 && actual.y==2.0 && actual.z == -3.0)
            verify(MIX_SetTrackStereo(track,addr(gains)) && MIX_SetTrackStereo(track,null))
            var map <- array<int>(0)
            verify(MIX_SetTrackOutputChannelMap(track,addr(map[0]),1))
            verify(MIX_SetTrackOutputChannelMap(track,null,1))
        }
        verify(MIX_SetTrackStoppedCallback(track,null,null) && MIX_SetTrackRawCallback(track,null,null))
        verify(MIX_SetTrackCookedCallback(track,null,null) && MIX_SetGroupPostMixCallback(grp,null,null))
        verify(MIX_SetPostMixCallback(mixer,null,null))
        verify(MIX_SetTrack3DPositionRef(track,pos))
        verify(unwrap(mix_track_position(track)).z == -3.0)
        verify(MIX_SetTrackStereoRef(track,gains) && MIX_SetTrackStereo(track,null))
        MIX_LockMixer(mixer);MIX_UnlockMixer(mixer)
        verify(MIX_PlayAudio(mixer,audio))
        unsafe { verify(MIX_Generate(mixer,addr(output[0]),2048)>=0) }
        var short : array<uint8>;resize(short,3)
        verify(is_err(generate_mix_audio(mixer,short)))
        var failed = with_mix_track(mixer) $(borrowed) {return err(SdlError(operation="body",message="kept"),type<SdlUnit>)}
        verify(is_err(failed) && unwrap_err(failed).message=="kept")
        var moved <- with_mix_group(mixer) $(borrowed) {var values <- array<int>(7);return <- move_ok(values,type<SdlError>)}
        verify(is_ok(moved));var values <- move_unwrap(moved);verify(values[0]==7)
        return sdl_ok()
    }
}

def loaders(mixer : MIX_Mixer?) {
    let path="{SDL_GetBasePath()}assets/libraries/mixer-tone.wav"
    let spec=SDL_AudioSpec(format=SDL_AudioFormat.AUDIO_F32,channels=1,freq=48000)
    unsafe {
        var samples <- array<float>(0.25,0.5,0.75,0.0)
        var raw=MIX_LoadRawAudio(mixer,addr(samples[0]),16ul,addr(spec));verify(raw!=null);MIX_DestroyAudio(raw)
        raw=MIX_LoadRawAudioNoCopy(mixer,addr(samples[0]),16ul,addr(spec),false);verify(raw!=null);MIX_DestroyAudio(raw)
        var io=SDL_IOFromConstMem(addr(samples[0]),16ul);verify(io!=null)
        raw=MIX_LoadRawAudio_IO(mixer,io,addr(spec),true);verify(raw!=null);MIX_DestroyAudio(raw)
        var size : uint64
        let bytes=SDL_LoadFile(path,addr(size));verify(bytes!=null)
        raw=MIX_LoadAudioNoCopy(mixer,bytes,size,true);verify(raw!=null);MIX_DestroyAudio(raw)
    }
    verify(unwrap(mix_format(mixer)).freq==48000)
    let scoped=with_mix_audio(mixer,path,false) $(a) {
        verify(unwrap(mix_audio_format(a)).channels==1)
        return sdl_ok()
    }
    verify(is_ok(scoped))
    let borrowed=SDL_IOFromFile(path,"rb");verify(borrowed!=null)
    verify(is_ok(with_mix_audio_io(mixer,borrowed,false) $(a) {return sdl_ok()}))
    verify(SDL_SeekIO(borrowed,0l,SDL_IOWhence.IO_SEEK_SET)==0l && SDL_CloseIO(borrowed))
    verify(is_ok(with_mix_decoder(path,0u) $(d) {verify(unwrap(mix_decoder_format(d)).channels==1);return sdl_ok()}))
    var silent : array<uint8>;resize(silent,16)
    let byte_audio=MIX_LoadRawAudioBytes(mixer,silent,spec);verify(byte_audio!=null);MIX_DestroyAudio(byte_audio)
    verify(is_ok(generate_mix_audio(mixer,silent)))
    var badspec=spec;badspec.channels=0
    verify(MIX_LoadRawAudioBytes(mixer,silent,badspec)==null)
    var called=false
    let failed=with_mix_track(null) $(t) {called=true;return sdl_ok()}
    verify(is_err(failed) && !called)
    var audio=MIX_LoadAudio(mixer,path,true);verify(audio!=null);MIX_DestroyAudio(audio)
    var io=SDL_IOFromFile(path,"rb");verify(io!=null)
    audio=MIX_LoadAudio_IO(mixer,io,false,true);verify(audio!=null);MIX_DestroyAudio(audio)
    let props=SDL_CreateProperties();verify(props!=0u)
    io=SDL_IOFromFile(path,"rb");verify(io!=null)
    verify(SDL_SetPointerProperty(props,MIX_PROP_AUDIO_LOAD_IOSTREAM_POINTER,io))
    verify(SDL_SetBooleanProperty(props,MIX_PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN,true))
    audio=MIX_LoadAudioWithProperties(props);verify(audio!=null);MIX_DestroyAudio(audio);SDL_DestroyProperties(props)
    audio=MIX_CreateSineWaveAudio(mixer,440,0.1,10l);verify(audio!=null);MIX_DestroyAudio(audio)
    var decoder=MIX_CreateAudioDecoder(path,0u);verify(decoder!=null)
    verify(MIX_GetAudioDecoderProperties(decoder)!=0u)
    var fmt : SDL_AudioSpec
    unsafe { verify(MIX_GetAudioDecoderFormat(decoder,addr(fmt))) }
    var buffer : array<uint8>;resize(buffer,8192)
    unsafe {verify(MIX_DecodeAudio(decoder,addr(buffer[0]),8192,addr(spec))>0)}
    MIX_DestroyAudioDecoder(decoder)
    io=SDL_IOFromFile(path,"rb");verify(io!=null)
    decoder=MIX_CreateAudioDecoder_IO(io,true,0u);verify(decoder!=null)
    var total=0
    for (i in 0..10) {let count=decode_mix_audio(decoder,buffer,spec) |> sdl_try;total+=count;if(count==0){break}}
    verify(total==4800*4)
    verify(unwrap(decode_mix_audio(decoder,buffer,spec))==0)
    MIX_DestroyAudioDecoder(decoder)
    let track=MIX_CreateTrack(mixer);verify(track!=null)
    io=SDL_IOFromFile(path,"rb");verify(io!=null);verify(MIX_SetTrackIOStream(track,io,true))
    unsafe {
        var samples <- array<float>(0.1,0.2)
        io=SDL_IOFromConstMem(addr(samples[0]),8ul);verify(io!=null)
        verify(MIX_SetTrackRawIOStream(track,io,addr(spec),true))
        verify(MIX_SetTrackAudio(track,null)) // Release the borrowed sample buffer before scope exit.
        let stream=SDL_CreateAudioStream(addr(spec),addr(spec));verify(stream!=null)
        verify(MIX_SetTrackAudioStream(track,stream) && MIX_GetTrackAudioStream(track)==stream)
        verify(MIX_SetTrackAudioStream(track,null));SDL_DestroyAudioStream(stream)
    }
    MIX_DestroyTrack(track)
    verify(is_err(create_mix_audio(mixer,"missing-mixer-file.wav",false)))
    return sdl_ok()
}
[export]
def main(smoke : bool) : int {
    verify(MIX_Version()==3002004 && MIX_Init())
    verify(MIX_GetNumAudioDecoders()>0 && MIX_GetAudioDecoder(0)!="")
    let spec=SDL_AudioSpec(format=SDL_AudioFormat.AUDIO_F32,channels=1,freq=48000)
    unsafe {
        let mixer=MIX_CreateMixer(addr(spec));verify(mixer!=null)
        verify(is_ok(offline(mixer)) && is_ok(loaders(mixer)))
        let extra=MIX_CreateGroup(mixer);verify(extra!=null);MIX_DestroyGroup(extra)
        MIX_DestroyMixer(mixer)
        verify(SDL_Init(SDL_INIT_AUDIO))
        let device=MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,addr(spec));verify(device!=null)
        MIX_DestroyMixer(device);SDL_Quit()
    }
    MIX_Quit()
    var moved <- with_mixer_system() {
        return with_mixer(spec) $(m) {
            var values <- array<int>(42)
            return <- move_ok(values,type<SdlError>)
        }
    }
    verify(is_ok(moved));var values <- move_unwrap(moved);verify(values[0]==42)
    print("SDL_mixer raw API, offline PCM, controls, decoders and scope contracts: PASS\n")
    return 0
}
