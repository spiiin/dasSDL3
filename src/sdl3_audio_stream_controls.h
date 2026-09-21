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
