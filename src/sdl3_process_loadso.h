#pragma once
#include "sdl3_filesystem.h"
#include <vector>
inline void * SDL_LoadFunctionAddress(SDL_SharedObject * object,const char * name) {return reinterpret_cast<void *>(SDL_LoadFunction(object,name));}
inline SDL_Process * SDL_CreateProcessArray(const das::TArray<char *> & args,bool pipe_stdio) {
    if(!args.size) {SDL_SetError("Process arguments must contain an executable");return nullptr;}
    const auto * values=reinterpret_cast<char * const *>(args.data);
    std::vector<const char *> argv;argv.reserve(size_t(args.size)+1);
    for(uint32_t i=0;i<args.size;++i)argv.push_back(values[i]?values[i]:"");
    argv.push_back(nullptr);return SDL_CreateProcess(argv.data(),pipe_stdio);
}
inline bool SDL_ReadProcessCopy(SDL_Process * process,das::TArray<uint8_t> & bytes,int & exitcode,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(bytes,0,1,ctx,at);
    size_t count=0;std::unique_ptr<void,decltype(&SDL_free)> data(SDL_ReadProcess(process,&count,&exitcode),SDL_free);
    if(!data)return false;
    if(count>INT_MAX)return SDL_SetError("Process output exceeds script array range");
    das::builtin_array_resize(bytes,int(count),1,ctx,at);
    if(count)SDL_memcpy(bytes.data,data.get(),count);
    return true;
}
// SDL has one false sentinel for pending and failure. Clear only for this probe.
inline int SDL_WaitProcessStateRef(SDL_Process * process,bool block,int & exitcode) {
    SDL_ClearError();
    if(SDL_WaitProcess(process,block,&exitcode))return 1;
    if(*SDL_GetError())return -1;
    if(block) {SDL_SetError("Blocking process wait did not complete");return -1;}
    return 0;
}
