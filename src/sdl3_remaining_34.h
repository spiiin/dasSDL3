#pragma once
#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#include <vector>
#include <climits>
inline bool SDL_PutAudioStreamDataNoCopyAddress(SDL_AudioStream* stream,const void* data,int length,void* callback,void* userdata) {
    return SDL_PutAudioStreamDataNoCopy(stream,data,length,reinterpret_cast<SDL_AudioStreamDataCompleteCallback>(callback),userdata);
}
inline bool SDL_SetRelativeMouseTransformAddress(void* callback,void* userdata) {
    return SDL_SetRelativeMouseTransform(reinterpret_cast<SDL_MouseMotionTransformCallback>(callback),userdata);
}
inline SDL_Cursor* SDL_CreateAnimatedCursorArray(const das::TArray<SDL_CursorFrameInfo>& frames,int x,int y) {
    if(!frames.size || frames.size>INT_MAX) {SDL_SetError("Animated cursor requires a nonempty bounded frame array");return nullptr;}
    return SDL_CreateAnimatedCursor(reinterpret_cast<SDL_CursorFrameInfo*>(frames.data),int(frames.size),x,y);
}
inline char* SDL_GetEventDescriptionCopy(const SDL_Event& event,das::Context* ctx,das::LineInfoArg* at) {
    const int length=SDL_GetEventDescription(&event,nullptr,0);
    if(length<0 || length==INT_MAX) {SDL_SetError("Event description exceeds buffer limits");return nullptr;}
    std::vector<char> data(size_t(length)+1);
    SDL_GetEventDescription(&event,data.data(),length+1);
    return ctx->allocateString(data.data(),at);
}
// Channel-major data; lock format validation together with the synchronous copy.
inline bool SDL_PutAudioStreamPlanarArray(SDL_AudioStream* stream,const void* data,uint64_t byte_count,
    int channels,int frames,bool float_input) {
    if(channels<0 || frames<0) return SDL_SetError("Planar channel and frame counts must not be negative");
    if(!SDL_LockAudioStream(stream)) return false;
    struct Unlock {SDL_AudioStream* stream;~Unlock(){SDL_UnlockAudioStream(stream);}} unlock{stream};
    SDL_AudioSpec input{};
    if(!SDL_GetAudioStreamFormat(stream,&input,nullptr)) return false;
    if(float_input && input.format!=SDL_AUDIO_F32) return SDL_SetError("Planar float input requires SDL_AUDIO_F32");
    const int width=SDL_AUDIO_BYTESIZE(input.format);
    if(width<=0 || input.channels<=0 || uint64_t(frames)*uint64_t(input.channels)*uint64_t(width)>INT_MAX)
        return SDL_SetError("Planar output byte count exceeds Sint32");
    // Validate with division before multiplication; arbitrary counts must not overflow.
    const uint64_t plane_bytes=uint64_t(frames)*uint64_t(width);
    if((plane_bytes && uint64_t(channels)>UINT64_MAX/plane_bytes) || uint64_t(channels)*plane_bytes!=byte_count)
        return SDL_SetError("Planar input byte size does not match channels * frames * sample size");
    if(frames==0) return true;
    const int count=SDL_min(channels,input.channels);
    // Pinned SDL mono fast path ignores num_channels and passes plane[0] straight
    // to PutAudioStreamData, which rejects nullptr instead of supplying silence.
    if(input.channels==1 && count==0) {
        std::vector<uint8_t> silence(size_t(plane_bytes),uint8_t(SDL_GetSilenceValueForFormat(input.format)));
        const void* mono=silence.data();
        return SDL_PutAudioStreamPlanarData(stream,&mono,1,frames);
    }
    std::vector<const void*> planes(size_t(count),nullptr);
    for(int i=0;i<count;++i) planes[i]=static_cast<const char*>(data)+size_t(i)*size_t(plane_bytes);
    const void* empty=nullptr;
    return SDL_PutAudioStreamPlanarData(stream,count ? planes.data() : &empty,count,frames);
}
inline bool SDL_PutAudioStreamPlanarFloats(SDL_AudioStream* stream,const das::TArray<float>& data,int channels,int frames) {
    return SDL_PutAudioStreamPlanarArray(stream,data.data,uint64_t(data.size)*sizeof(float),channels,frames,true);
}
inline bool SDL_PutAudioStreamPlanarBytes(SDL_AudioStream* stream,const das::TArray<uint8_t>& data,int channels,int frames) {
    return SDL_PutAudioStreamPlanarArray(stream,data.data,data.size,channels,frames,false);
}
