#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline bool filesystem_file(const char * path,bool write) {
    const char expected[]="filesystem fixture\n";
    SDL_IOStream * io=SDL_IOFromFile(path,write?"wb":"rb");
    if(!io)return false;
    char actual[sizeof(expected)]={};
    bool result=write ? SDL_WriteIO(io,expected,sizeof(expected))==sizeof(expected)
        : SDL_ReadIO(io,actual,sizeof(actual))==sizeof(actual) && SDL_memcmp(actual,expected,sizeof(actual))==0;
    return SDL_CloseIO(io) && result;
}
inline int filesystem_calls=0;
inline SDL_EnumerationResult filesystem_action=SDL_ENUM_CONTINUE;
inline SDL_EnumerationResult SDLCALL filesystem_callback(void * userdata,const char * dirname,const char * fname) {
    if(userdata!=&filesystem_calls || !dirname || !fname || !*fname)return SDL_ENUM_FAILURE;
    ++filesystem_calls;
    if(filesystem_action==SDL_ENUM_FAILURE)SDL_SetError("fixture enumeration failure");
    return filesystem_action;
}
inline void * filesystem_callback_address(int action) {
    filesystem_calls=0;filesystem_action=SDL_EnumerationResult(action);
    return reinterpret_cast<void *>(filesystem_callback);
}
inline void * filesystem_userdata() {return &filesystem_calls;}
inline int filesystem_count() {return filesystem_calls;}
}
