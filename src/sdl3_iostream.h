#pragma once
#include "sdl3_init_hints.h"
#include "daScript/simulate/aot_builtin.h"
#include <memory>
#include <climits>

inline SDL_IOStreamInterface SDL_MakeIOStreamInterface() {
    SDL_IOStreamInterface value; SDL_INIT_INTERFACE(&value); return value;
}
// Addresses must point to native C functions matching the SDL interface signatures.
inline void SDL_SetIOStreamInterfaceCallbacks(SDL_IOStreamInterface & iface,void * size,void * seek,
        void * read,void * write,void * flush,void * close) {
    iface.size=reinterpret_cast<decltype(iface.size)>(size);
    iface.seek=reinterpret_cast<decltype(iface.seek)>(seek);
    iface.read=reinterpret_cast<decltype(iface.read)>(read);
    iface.write=reinterpret_cast<decltype(iface.write)>(write);
    iface.flush=reinterpret_cast<decltype(iface.flush)>(flush);
    iface.close=reinterpret_cast<decltype(iface.close)>(close);
}
inline SDL_IOStream * SDL_OpenIORef(const SDL_IOStreamInterface & iface,void * userdata) { return SDL_OpenIO(&iface,userdata); }
inline bool SDL_CloseIORef(SDL_IOStream *& io) { auto * owned=io;io=nullptr;return SDL_CloseIO(owned); }
inline size_t SDL_IOprintfText(SDL_IOStream * io,const char * text) { return SDL_IOprintf(io,"%s",text?text:""); }

namespace sdl3_iostream {
inline bool capacity(const das::TArray<uint8_t> & bytes,uint64_t count,uint64_t offset) {
    return (offset<=bytes.size && count<=bytes.size-offset && (!count || bytes.data)) || SDL_SetError("IO byte count exceeds array capacity");
}
inline bool copy(void * allocation,size_t size,das::TArray<uint8_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    std::unique_ptr<void,decltype(&SDL_free)> owned(allocation,SDL_free);
    if(!allocation)return false;
    if(size>INT_MAX)return SDL_SetError("IO file exceeds script array range");
    das::builtin_array_resize(out,int(size),1,ctx,at);
    if(size)SDL_memcpy(out.data,allocation,size);
    return true;
}
}
// Count is always written, including partial transfers on failure. EOF and NOT_READY are successful states.
inline bool SDL_ReadIOArray(SDL_IOStream * io,das::TArray<uint8_t> & bytes,uint64_t count,
        uint64_t & transferred,SDL_IOStatus & status,uint64_t offset) {
    transferred=0;status=SDL_IO_STATUS_ERROR;
    if(!sdl3_iostream::capacity(bytes,count,offset))return false;
    transferred=SDL_ReadIO(io,bytes.data ? bytes.data+size_t(offset) : nullptr,size_t(count));status=SDL_GetIOStatus(io);
    return status==SDL_IO_STATUS_READY || status==SDL_IO_STATUS_EOF || status==SDL_IO_STATUS_NOT_READY;
}
inline bool SDL_WriteIOArray(SDL_IOStream * io,const das::TArray<uint8_t> & bytes,uint64_t count,
        uint64_t & transferred,SDL_IOStatus & status,uint64_t offset) {
    transferred=0;status=SDL_IO_STATUS_ERROR;
    if(!sdl3_iostream::capacity(bytes,count,offset))return false;
    transferred=SDL_WriteIO(io,bytes.data ? bytes.data+size_t(offset) : nullptr,size_t(count));status=SDL_GetIOStatus(io);
    return status==SDL_IO_STATUS_READY || status==SDL_IO_STATUS_EOF || status==SDL_IO_STATUS_NOT_READY;
}
inline bool SDL_LoadFileCopy(const char * path,das::TArray<uint8_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,1,ctx,at);size_t size=0;
    void * data=SDL_LoadFile(path,&size);return sdl3_iostream::copy(data,size,out,ctx,at);
}
inline bool SDL_LoadFileIOCopy(SDL_IOStream * io,das::TArray<uint8_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,1,ctx,at);size_t size=0;
    void * data=SDL_LoadFile_IO(io,&size,false);
    if(data) {
        const auto status=SDL_GetIOStatus(io);
        if(status==SDL_IO_STATUS_ERROR || status==SDL_IO_STATUS_READONLY || status==SDL_IO_STATUS_WRITEONLY) {SDL_free(data);return false;}
    }
    return sdl3_iostream::copy(data,size,out,ctx,at);
}
inline bool SDL_SaveFileArray(const char * path,const das::TArray<uint8_t> & bytes) {
    const char empty=0;return SDL_SaveFile(path,bytes.size?bytes.data:&empty,bytes.size);
}
inline bool SDL_SaveFileIOArray(SDL_IOStream * io,const das::TArray<uint8_t> & bytes) {
    const char empty=0;return SDL_SaveFile_IO(io,bytes.size?bytes.data:&empty,bytes.size,false);
}
inline bool SDL_ReadU8Ref(SDL_IOStream * io,uint32_t & value) {Uint8 native=0;const bool ok=SDL_ReadU8(io,&native);value=native;return ok;}
inline bool SDL_ReadS8Ref(SDL_IOStream * io,Sint8 & value) {return SDL_ReadS8(io,&value);}
inline bool SDL_ReadU16LERef(SDL_IOStream * io,uint32_t & value) {Uint16 native=0;const bool ok=SDL_ReadU16LE(io,&native);value=native;return ok;}
inline bool SDL_ReadS16LERef(SDL_IOStream * io,Sint16 & value) {return SDL_ReadS16LE(io,&value);}
inline bool SDL_ReadU16BERef(SDL_IOStream * io,uint32_t & value) {Uint16 native=0;const bool ok=SDL_ReadU16BE(io,&native);value=native;return ok;}
inline bool SDL_ReadS16BERef(SDL_IOStream * io,Sint16 & value) {return SDL_ReadS16BE(io,&value);}
inline bool SDL_ReadU32LERef(SDL_IOStream * io,Uint32 & value) {return SDL_ReadU32LE(io,&value);}
inline bool SDL_ReadS32LERef(SDL_IOStream * io,Sint32 & value) {return SDL_ReadS32LE(io,&value);}
inline bool SDL_ReadU32BERef(SDL_IOStream * io,Uint32 & value) {return SDL_ReadU32BE(io,&value);}
inline bool SDL_ReadS32BERef(SDL_IOStream * io,Sint32 & value) {return SDL_ReadS32BE(io,&value);}
inline bool SDL_ReadU64LERef(SDL_IOStream * io,Uint64 & value) {return SDL_ReadU64LE(io,&value);}
inline bool SDL_ReadS64LERef(SDL_IOStream * io,Sint64 & value) {return SDL_ReadS64LE(io,&value);}
inline bool SDL_ReadU64BERef(SDL_IOStream * io,Uint64 & value) {return SDL_ReadU64BE(io,&value);}
inline bool SDL_ReadS64BERef(SDL_IOStream * io,Sint64 & value) {return SDL_ReadS64BE(io,&value);}

#ifdef __APPLE__
// AOT storage bridge: native size_t and script uint64 have equal width on Mac,
// but distinct C++ pointer types. Keep the raw interpreter signature unchanged.
inline void * SDL_LoadFileSize64(const char * path,uint64_t * size) {
    static_assert(sizeof(size_t)==sizeof(uint64_t));
    size_t native_size=size?size_t(*size):0;
    void * bytes=SDL_LoadFile(path,size?&native_size:nullptr);
    if(size)*size=uint64_t(native_size);
    return bytes;
}
inline void * SDL_LoadFile_IOSize64(SDL_IOStream * io,uint64_t * size,bool close_io) {
    static_assert(sizeof(size_t)==sizeof(uint64_t));
    size_t native_size=size?size_t(*size):0;
    void * bytes=SDL_LoadFile_IO(io,size?&native_size:nullptr,close_io);
    if(size)*size=uint64_t(native_size);
    return bytes;
}

#endif
