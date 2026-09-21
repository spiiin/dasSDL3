#pragma once
#include "sdl3_audio.h"
#include "sdl3_video.h"
inline bool SDL_GetAudioPlaybackDevicesCopy(das::TArray<uint32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;auto * values=SDL_GetAudioPlaybackDevices(&count);return sdl3_video::copy_array(values,count,out,ctx,at);
}
inline bool SDL_GetAudioRecordingDevicesCopy(das::TArray<uint32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;auto * values=SDL_GetAudioRecordingDevices(&count);return sdl3_video::copy_array(values,count,out,ctx,at);
}
inline char * SDL_GetAudioDriverCopy(int index,das::Context * ctx,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetAudioDriver(index),ctx,at);}
inline char * SDL_GetCurrentAudioDriverCopy(das::Context * ctx,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetCurrentAudioDriver(),ctx,at);}
inline bool SDL_GetAudioDeviceNameCopy(uint32_t device,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * name=SDL_GetAudioDeviceName(device);out=sdl3_init_hints::copy(name,ctx,at);return name!=nullptr;
}
inline bool SDL_GetAudioDeviceFormatRef(uint32_t device,SDL_AudioSpec & spec,int & frames) {return SDL_GetAudioDeviceFormat(device,&spec,&frames);}
inline uint32_t SDL_OpenAudioDeviceRef(uint32_t device,const SDL_AudioSpec & spec) {return SDL_OpenAudioDevice(device,&spec);}
// 0 preserves SDL's ambiguous null (default map, invalid device or allocation failure).
inline int SDL_GetAudioDeviceChannelMapCopy(uint32_t device,das::TArray<int32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(int32_t),ctx,at);
    int count=0;auto * values=SDL_GetAudioDeviceChannelMap(device,&count);
    if(!values)return 0;
    return sdl3_video::copy_array(values,count,out,ctx,at)?1:-1;
}
inline bool SDL_BindAudioStreamsArray(uint32_t device,const das::TArray<SDL_AudioStream *> & streams) {
    if(streams.size>INT_MAX || (streams.size && !streams.data))return SDL_SetError("Invalid audio stream array");
    return SDL_BindAudioStreams(device,reinterpret_cast<SDL_AudioStream *const *>(streams.data),int(streams.size));
}
inline bool SDL_UnbindAudioStreamsArray(const das::TArray<SDL_AudioStream *> & streams) {
    if(streams.size>INT_MAX || (streams.size && !streams.data))return SDL_SetError("Invalid audio stream array");
    SDL_UnbindAudioStreams(reinterpret_cast<SDL_AudioStream *const *>(streams.data),int(streams.size));return true;
}
