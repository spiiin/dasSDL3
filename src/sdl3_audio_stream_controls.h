#pragma once
#include "sdl3_audio_devices.h"
inline bool SDL_GetAudioStreamFormatsRef(SDL_AudioStream * stream,SDL_AudioSpec & src,SDL_AudioSpec & dst) {return SDL_GetAudioStreamFormat(stream,&src,&dst);}
inline bool SDL_SetAudioStreamFormatsRef(SDL_AudioStream * stream,const SDL_AudioSpec & src,const SDL_AudioSpec & dst) {return SDL_SetAudioStreamFormat(stream,&src,&dst);}
inline bool SDL_SetAudioStreamInputFormatRef(SDL_AudioStream * stream,const SDL_AudioSpec & src) {return SDL_SetAudioStreamFormat(stream,&src,nullptr);}
inline bool SDL_SetAudioStreamOutputFormatRef(SDL_AudioStream * stream,const SDL_AudioSpec & dst) {return SDL_SetAudioStreamFormat(stream,nullptr,&dst);}
inline bool SDL_SetAudioStreamInputChannelMapArray(SDL_AudioStream * stream,const das::TArray<int32_t> & map) {
    if(!stream)return SDL_SetError("Null audio stream");
    if(map.size>INT_MAX || (map.size && !map.data))return SDL_SetError("Invalid audio channel map array");
    // Empty arrays are not implicit reset: explicit reset carries the channel count.
    int empty=0;
    return SDL_SetAudioStreamInputChannelMap(stream,map.size?reinterpret_cast<const int *>(map.data):&empty,int(map.size));
}
inline bool SDL_ResetAudioStreamInputChannelMap(SDL_AudioStream * stream,int channels) {
    if(!stream)return SDL_SetError("Null audio stream");
    return SDL_SetAudioStreamInputChannelMap(stream,nullptr,channels);
}
inline bool SDL_SetAudioStreamOutputChannelMapArray(SDL_AudioStream * stream,const das::TArray<int32_t> & map) {
    if(!stream)return SDL_SetError("Null audio stream");
    if(map.size>INT_MAX || (map.size && !map.data))return SDL_SetError("Invalid audio channel map array");
    // Empty arrays are not implicit reset: explicit reset carries the channel count.
    int empty=0;
    return SDL_SetAudioStreamOutputChannelMap(stream,map.size?reinterpret_cast<const int *>(map.data):&empty,int(map.size));
}
inline bool SDL_ResetAudioStreamOutputChannelMap(SDL_AudioStream * stream,int channels) {
    if(!stream)return SDL_SetError("Null audio stream");
    return SDL_SetAudioStreamOutputChannelMap(stream,nullptr,channels);
}

// -1 error, 0 default map, 1 owned copy. SDL_malloc reports OOM in SDL 3.4.
// Clear stale errors immediately before the ambiguous native getter; inspect only
// its null result. Native getters copy under their stream lock.
namespace sdl3_audio_maps {
inline int copy(SDL_AudioStream * stream, bool input, das::TArray<int32_t> & out,
        das::Context * ctx, das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(int32_t),ctx,at);
    if (!stream) { SDL_SetError("Null audio stream"); return -1; }
    int count=0;
    SDL_ClearError();
    int * values=input ? SDL_GetAudioStreamInputChannelMap(stream,&count)
                       : SDL_GetAudioStreamOutputChannelMap(stream,&count);
    if (!values) return SDL_GetError()[0] ? -1 : 0;
    return sdl3_video::copy_array(values,count,out,ctx,at) ? 1 : -1;
}
}
inline int SDL_GetAudioStreamInputChannelMapCopy(SDL_AudioStream * stream,
        das::TArray<int32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    return sdl3_audio_maps::copy(stream,true,out,ctx,at);
}
inline int SDL_GetAudioStreamOutputChannelMapCopy(SDL_AudioStream * stream,
        das::TArray<int32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    return sdl3_audio_maps::copy(stream,false,out,ctx,at);
}
