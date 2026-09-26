#pragma once
#include "daScript/daScript.h"
#include <SDL3_mixer/SDL_mixer.h>
static_assert(SDL_MIXER_VERSION == 3002004,"Review SDL_mixer bindings on upgrade");
// Callbacks are native C addresses, never retained daScript blocks/contexts.
inline bool MIX_SetTrackStoppedCallbackAddress(MIX_Track* owner,void* callback,void* userdata) {
    return MIX_SetTrackStoppedCallback(owner,reinterpret_cast<MIX_TrackStoppedCallback>(callback),userdata);
}
inline bool MIX_SetTrackRawCallbackAddress(MIX_Track* owner,void* callback,void* userdata) {
    return MIX_SetTrackRawCallback(owner,reinterpret_cast<MIX_TrackMixCallback>(callback),userdata);
}
inline bool MIX_SetTrackCookedCallbackAddress(MIX_Track* owner,void* callback,void* userdata) {
    return MIX_SetTrackCookedCallback(owner,reinterpret_cast<MIX_TrackMixCallback>(callback),userdata);
}
inline bool MIX_SetGroupPostMixCallbackAddress(MIX_Group* owner,void* callback,void* userdata) {
    return MIX_SetGroupPostMixCallback(owner,reinterpret_cast<MIX_GroupMixCallback>(callback),userdata);
}
inline bool MIX_SetPostMixCallbackAddress(MIX_Mixer* owner,void* callback,void* userdata) {
    return MIX_SetPostMixCallback(owner,reinterpret_cast<MIX_PostMixCallback>(callback),userdata);
}
inline MIX_Mixer* MIX_CreateMixerRef(const SDL_AudioSpec& spec) { return MIX_CreateMixer(&spec); }
inline MIX_Mixer* MIX_CreateMixerDeviceRef(uint32_t device,const SDL_AudioSpec& spec) { return MIX_CreateMixerDevice(device,&spec); }
inline bool MIX_GetMixerFormatRef(MIX_Mixer* mixer,SDL_AudioSpec& spec) { return MIX_GetMixerFormat(mixer,&spec); }
inline bool MIX_GetAudioFormatRef(MIX_Audio* audio,SDL_AudioSpec& spec) { return MIX_GetAudioFormat(audio,&spec); }
inline bool MIX_GetAudioDecoderFormatRef(MIX_AudioDecoder* decoder,SDL_AudioSpec& spec) { return MIX_GetAudioDecoderFormat(decoder,&spec); }
inline bool MIX_GetTrack3DPositionRef(MIX_Track* track,MIX_Point3D& position) { return MIX_GetTrack3DPosition(track,&position); }
inline bool MIX_SetTrack3DPositionRef(MIX_Track* track,const MIX_Point3D& position) { return MIX_SetTrack3DPosition(track,&position); }
inline bool MIX_SetTrackStereoRef(MIX_Track* track,const MIX_StereoGains& gains) { return MIX_SetTrackStereo(track,&gains); }
inline MIX_Audio* MIX_LoadRawAudioBytes(MIX_Mixer* mixer,const das::TArray<uint8_t>& bytes,const SDL_AudioSpec& spec) {
    if(spec.channels<=0 || spec.channels>255 || spec.freq<=0) { SDL_SetError("Invalid PCM format"); return nullptr; }
    const int frame=SDL_AUDIO_FRAMESIZE(spec);
    if(frame<=0 || bytes.size%frame) { SDL_SetError("PCM must contain whole sample frames"); return nullptr; }
    const uint8_t empty=0;
    return MIX_LoadRawAudio(mixer,bytes.size ? bytes.data : (const char*)&empty,bytes.size,&spec);
}
inline MIX_Audio* MIX_LoadRawAudioFloats(MIX_Mixer* mixer,const das::TArray<float>& samples,int channels,int frequency) {
    if(channels<=0 || channels>255 || frequency<=0 || samples.size%channels || samples.size>INT_MAX/sizeof(float)) {
        SDL_SetError("Invalid interleaved float PCM format or count"); return nullptr;
    }
    SDL_AudioSpec spec{SDL_AUDIO_F32,channels,frequency};
    const float empty=0;
    return MIX_LoadRawAudio(mixer,samples.size ? samples.data : (const char*)&empty,size_t(samples.size)*sizeof(float),&spec);
}
inline int MIX_GenerateBytes(MIX_Mixer* mixer,das::TArray<uint8_t>& bytes) {
    SDL_AudioSpec spec{};
    if(!MIX_GetMixerFormat(mixer,&spec)) return -1;
    const int frame=SDL_AUDIO_FRAMESIZE(spec);
    if(bytes.size>INT_MAX || frame<=0 || bytes.size%frame) { SDL_SetError("Output must contain whole sample frames and fit INT_MAX"); return -1; }
    uint8_t empty=0;
    return MIX_Generate(mixer,bytes.size ? bytes.data : (char*)&empty,int(bytes.size));
}
inline int MIX_GenerateFloats(MIX_Mixer* mixer,das::TArray<float>& samples) {
    SDL_AudioSpec spec{};
    if(!MIX_GetMixerFormat(mixer,&spec)) return -1;
    if(spec.format!=SDL_AUDIO_F32 || spec.channels<=0 || samples.size%spec.channels || samples.size>INT_MAX/sizeof(float)) {
        SDL_SetError("Output requires native F32, whole interleaved frames and an int byte count"); return -1;
    }
    float empty=0;
    // Return bytes, just like MIX_Generate (including a successful zero).
    return MIX_Generate(mixer,samples.size ? samples.data : (char*)&empty,int(samples.size*sizeof(float)));
}
inline int MIX_DecodeAudioBytes(MIX_AudioDecoder* decoder,das::TArray<uint8_t>& bytes,const SDL_AudioSpec& spec) {
    if(spec.channels<=0 || spec.channels>255 || spec.freq<=0) { SDL_SetError("Invalid decode format"); return -1; }
    const int frame=SDL_AUDIO_FRAMESIZE(spec);
    if(bytes.size>INT_MAX || frame<=0 || bytes.size%frame) { SDL_SetError("Decode output must contain whole sample frames and fit INT_MAX"); return -1; }
    uint8_t empty=0;
    return MIX_DecodeAudio(decoder,bytes.size ? bytes.data : (char*)&empty,int(bytes.size),&spec);
}
