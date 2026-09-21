#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
struct IOState {int mode=0;int closes=0;int writes=0;int reads=0;size_t used=0;uint8_t captured[32]={};};
inline IOState io_state;
inline void * io_reset(int mode) {io_state={};io_state.mode=mode;return &io_state;}
inline Sint64 SDLCALL io_size(void *) {return 8;}
inline Sint64 SDLCALL io_seek(void *,Sint64 offset,SDL_IOWhence) {return offset;}
inline size_t SDLCALL io_read(void * ptr,void * bytes,size_t size,SDL_IOStatus * status) {
    auto & state=*static_cast<IOState *>(ptr);
    if(state.mode==4 && state.reads++>0) {*status=SDL_IO_STATUS_ERROR;SDL_SetError("fixture terminal read failure");return 0;}
    const size_t count=state.mode ? SDL_min(size,size_t(2)) : size;
    SDL_memset(bytes,42,count);
    if(state.mode==1)*status=SDL_IO_STATUS_NOT_READY;
    if(state.mode==2) {*status=SDL_IO_STATUS_ERROR;SDL_SetError("fixture transfer failure");}
    return count;
}
inline size_t SDLCALL io_write(void * ptr,const void * bytes,size_t size,SDL_IOStatus * status) {
    auto & state=*static_cast<IOState *>(ptr);++state.writes;
    const size_t count=state.mode ? SDL_min(size,size_t(2)) : size;
    if(state.used+count<=sizeof(state.captured)) {SDL_memcpy(state.captured+state.used,bytes,count);state.used+=count;}
    if(state.mode==1)*status=SDL_IO_STATUS_NOT_READY;
    if(state.mode==2) {*status=SDL_IO_STATUS_ERROR;SDL_SetError("fixture transfer failure");}
    return count;
}
inline bool SDLCALL io_flush(void * ptr,SDL_IOStatus * status) {
    auto & state=*static_cast<IOState *>(ptr);
    if(state.mode==1) {*status=SDL_IO_STATUS_NOT_READY;return false;}
    if(state.mode==2) {*status=SDL_IO_STATUS_ERROR;return SDL_SetError("fixture flush failure");}
    return true;
}
inline bool SDLCALL io_close(void * ptr) {
    auto & state=*static_cast<IOState *>(ptr);++state.closes;
    return state.mode!=2 || SDL_SetError("fixture close failure");
}
inline void * io_callback(int index) {
    switch(index) {
    case 0:return reinterpret_cast<void *>(io_size);case 1:return reinterpret_cast<void *>(io_seek);
    case 2:return reinterpret_cast<void *>(io_read);case 3:return reinterpret_cast<void *>(io_write);
    case 4:return reinterpret_cast<void *>(io_flush);case 5:return reinterpret_cast<void *>(io_close);
    default:return nullptr;
    }
}
inline int io_closes() {return io_state.closes;}
inline bool io_pinned_short_save() {
    const uint8_t expected[]={0,1,2,3,2,3};
    return io_state.used==6 && SDL_memcmp(io_state.captured,expected,6)==0;
}
}
