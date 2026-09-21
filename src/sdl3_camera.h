#pragma once
#include "sdl3_video.h"
inline bool SDL_GetCamerasCopy(das::TArray<uint32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;auto * values=SDL_GetCameras(&count);return sdl3_video::copy_array(values,count,out,ctx,at);
}
inline bool SDL_GetCameraSupportedFormatsCopy(uint32_t id,das::TArray<SDL_CameraSpec> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(SDL_CameraSpec),ctx,at);
    int count=0;auto ** values=SDL_GetCameraSupportedFormats(id,&count);
    std::unique_ptr<SDL_CameraSpec *,decltype(&SDL_free)> owned(values,SDL_free);
    if(!values)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(SDL_CameraSpec))return SDL_SetError("Camera formats exceed size limit");
    for(int i=0;i<count;++i)if(!values[i])return SDL_SetError("Null camera format entry");
    das::builtin_array_resize(out,count,sizeof(SDL_CameraSpec),ctx,at);
    auto * dest=reinterpret_cast<SDL_CameraSpec *>(out.data);
    for(int i=0;i<count;++i)dest[i]=*values[i];
    return true;
}
inline char * SDL_GetCameraDriverCopy(int index,das::Context * ctx,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetCameraDriver(index),ctx,at);}
inline char * SDL_GetCurrentCameraDriverCopy(das::Context * ctx,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetCurrentCameraDriver(),ctx,at);}
inline bool SDL_GetCameraNameCopy(uint32_t id,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * name=SDL_GetCameraName(id);out=sdl3_init_hints::copy(name,ctx,at);return name!=nullptr;
}
inline SDL_Camera * SDL_OpenCameraRef(uint32_t id,const SDL_CameraSpec & spec) {return SDL_OpenCamera(id,&spec);}
inline bool SDL_GetCameraFormatRef(SDL_Camera * camera,SDL_CameraSpec & spec) {spec={};return SDL_GetCameraFormat(camera,&spec);}
// -1 error, 0 pending/no frame, 1 acquired. Valid live camera required (no concurrent close).
// Clear thread-local error only for this documented ambiguous-null operation.
inline int SDL_AcquireCameraFrameRef(SDL_Camera * camera,SDL_Surface *& frame,uint64_t & timestamp) {
    frame=nullptr;timestamp=0;
    if(!camera){SDL_InvalidParamError("camera");return -1;}
    if(SDL_GetCameraPermissionState(camera)==0)return 0;
    SDL_ClearError();
    frame=SDL_AcquireCameraFrame(camera,&timestamp);
    if(frame)return 1;
    return *SDL_GetError() ? -1 : 0;
}
