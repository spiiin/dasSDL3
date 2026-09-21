#pragma once
#include "sdl3_audio_stream_controls.h"
inline bool SDL_SetAudioStreamGetCallbackAddress(SDL_AudioStream * stream,void * callback,void * userdata) {return SDL_SetAudioStreamGetCallback(stream,reinterpret_cast<SDL_AudioStreamCallback>(callback),userdata);}
inline bool SDL_SetAudioStreamPutCallbackAddress(SDL_AudioStream * stream,void * callback,void * userdata) {return SDL_SetAudioStreamPutCallback(stream,reinterpret_cast<SDL_AudioStreamCallback>(callback),userdata);}
inline bool SDL_SetAudioPostmixCallbackAddress(uint32_t device,void * callback,void * userdata) {return SDL_SetAudioPostmixCallback(device,reinterpret_cast<SDL_AudioPostmixCallback>(callback),userdata);}
inline SDL_AudioStream * SDL_OpenAudioDeviceStreamAddress(uint32_t device,const SDL_AudioSpec * spec,void * callback,void * userdata) {return SDL_OpenAudioDeviceStream(device,spec,reinterpret_cast<SDL_AudioStreamCallback>(callback),userdata);}
inline SDL_AudioStream * SDL_OpenAudioDeviceStreamRef(uint32_t device,const SDL_AudioSpec & spec,void * callback,void * userdata) {return SDL_OpenAudioDeviceStreamAddress(device,&spec,callback,userdata);}
inline bool SDL_LoadWAV_IOCopy(SDL_IOStream * io,SDL_AudioSpec & spec,das::TArray<uint8_t> & bytes,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(bytes,0,1,ctx,at);spec={};
    Uint8 * data=nullptr;Uint32 count=0;
    const bool loaded=SDL_LoadWAV_IO(io,false,&spec,&data,&count);
    // SDL already releases failed WAV output; never free a failure out-pointer.
    if(!loaded)return false;
    std::unique_ptr<Uint8,decltype(&SDL_free)> owned(data,SDL_free);
    if(count>INT_MAX)return SDL_SetError("WAV exceeds script array range");
    das::builtin_array_resize(bytes,int(count),1,ctx,at);
    if(count)SDL_memcpy(bytes.data,data,count);
    return true;
}
inline bool SDL_MixAudioArray(das::TArray<uint8_t> & dst,const das::TArray<uint8_t> & src,SDL_AudioFormat format,uint32_t count,float volume) {
    if(!(volume>=0.0f && volume<=1.0f))return SDL_SetError("Mix volume must be finite and in [0,1]");
    if(count>dst.size || count>src.size)return SDL_SetError("Mix exceeds array capacity");
    const int sample_size=SDL_AUDIO_BYTESIZE(format);
    if(sample_size && count%uint32_t(sample_size))return SDL_SetError("Mix contains a partial sample");
    Uint8 empty=0;
    return SDL_MixAudio(count?reinterpret_cast<Uint8 *>(dst.data):&empty,count?reinterpret_cast<const Uint8 *>(src.data):&empty,format,count,volume);
}
inline bool SDL_ConvertAudioSamplesArray(const SDL_AudioSpec & src_spec,const das::TArray<uint8_t> & src,const SDL_AudioSpec & dst_spec,das::TArray<uint8_t> & dst,das::Context * ctx,das::LineInfoArg * at) {
    if(&src==&dst)return SDL_SetError("Conversion input and output must be different arrays");
    das::builtin_array_resize(dst,0,1,ctx,at);
    if(src.size>INT_MAX)return SDL_SetError("Audio input exceeds INT_MAX bytes");
    const int64_t frame=int64_t(src_spec.channels)*SDL_AUDIO_BYTESIZE(src_spec.format);
    if(frame>0 && int64_t(src.size)%frame)return SDL_SetError("Audio input contains a partial frame");
    Uint8 empty=0;Uint8 * data=nullptr;int count=0;
    const bool converted=SDL_ConvertAudioSamples(&src_spec,src.size?reinterpret_cast<const Uint8 *>(src.data):&empty,int(src.size),&dst_spec,&data,&count);
    std::unique_ptr<Uint8,decltype(&SDL_free)> owned(data,SDL_free);
    if(!converted)return false;
    if(count<0 || (count && !data))return SDL_SetError("Invalid converted audio buffer");
    das::builtin_array_resize(dst,count,1,ctx,at);
    if(count)SDL_memcpy(dst.data,data,size_t(count));
    return true;
}
