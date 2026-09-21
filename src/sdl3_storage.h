#pragma once
#include "sdl3_filesystem.h"
inline bool SDL_EnumerateStorageDirectoryAddress(SDL_Storage * storage,const char * path,void * callback,void * userdata) {
    return SDL_EnumerateStorageDirectory(storage,path,reinterpret_cast<SDL_EnumerateDirectoryCallback>(callback),userdata);
}
inline SDL_StorageInterface SDL_MakeStorageInterface() {SDL_StorageInterface value;SDL_INIT_INTERFACE(&value);return value;}
inline void SDL_SetStorageInterface_close(SDL_StorageInterface & iface,void * address) {iface.close=reinterpret_cast<decltype(iface.close)>(address);}
inline void SDL_SetStorageInterface_ready(SDL_StorageInterface & iface,void * address) {iface.ready=reinterpret_cast<decltype(iface.ready)>(address);}
inline void SDL_SetStorageInterface_enumerate(SDL_StorageInterface & iface,void * address) {iface.enumerate=reinterpret_cast<decltype(iface.enumerate)>(address);}
inline void SDL_SetStorageInterface_info(SDL_StorageInterface & iface,void * address) {iface.info=reinterpret_cast<decltype(iface.info)>(address);}
inline void SDL_SetStorageInterface_read_file(SDL_StorageInterface & iface,void * address) {iface.read_file=reinterpret_cast<decltype(iface.read_file)>(address);}
inline void SDL_SetStorageInterface_write_file(SDL_StorageInterface & iface,void * address) {iface.write_file=reinterpret_cast<decltype(iface.write_file)>(address);}
inline void SDL_SetStorageInterface_mkdir(SDL_StorageInterface & iface,void * address) {iface.mkdir=reinterpret_cast<decltype(iface.mkdir)>(address);}
inline void SDL_SetStorageInterface_remove(SDL_StorageInterface & iface,void * address) {iface.remove=reinterpret_cast<decltype(iface.remove)>(address);}
inline void SDL_SetStorageInterface_rename(SDL_StorageInterface & iface,void * address) {iface.rename=reinterpret_cast<decltype(iface.rename)>(address);}
inline void SDL_SetStorageInterface_copy(SDL_StorageInterface & iface,void * address) {iface.copy=reinterpret_cast<decltype(iface.copy)>(address);}
inline void SDL_SetStorageInterface_space_remaining(SDL_StorageInterface & iface,void * address) {iface.space_remaining=reinterpret_cast<decltype(iface.space_remaining)>(address);}
inline SDL_Storage * SDL_OpenStorageRef(const SDL_StorageInterface & iface,void * userdata) {return SDL_OpenStorage(&iface,userdata);}
inline bool SDL_CloseStorageRef(SDL_Storage *& storage) {auto * owned=storage;storage=nullptr;return SDL_CloseStorage(owned);}
inline bool SDL_GetStorageFileSizeRef(SDL_Storage * storage,const char * path,uint64_t & length) {return SDL_GetStorageFileSize(storage,path,&length);}
inline bool SDL_GetStoragePathInfoRef(SDL_Storage * storage,const char * path,SDL_PathInfo & info) {return SDL_GetStoragePathInfo(storage,path,&info);}
inline bool SDL_ReadStorageFileArray(SDL_Storage * storage,const char * path,das::TArray<uint8_t> & bytes,uint64_t count) {
    if(count>bytes.size || (count && !bytes.data))return SDL_SetError("Storage read exceeds array capacity");
    char empty=0;return SDL_ReadStorageFile(storage,path,count?bytes.data:&empty,count);
}
inline bool SDL_WriteStorageFileArray(SDL_Storage * storage,const char * path,const das::TArray<uint8_t> & bytes,uint64_t count) {
    if(count>bytes.size || (count && !bytes.data))return SDL_SetError("Storage write exceeds array capacity");
    const char empty=0;return SDL_WriteStorageFile(storage,path,count?bytes.data:&empty,count);
}
inline bool SDL_LoadStorageFileCopy(SDL_Storage * storage,const char * path,das::TArray<uint8_t> & bytes,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(bytes,0,1,ctx,at);uint64_t count=0;
    if(!SDL_GetStorageFileSize(storage,path,&count))return false;
    if(count>INT_MAX)return SDL_SetError("Storage file exceeds script array range");
    das::builtin_array_resize(bytes,int(count),1,ctx,at);
    if(SDL_ReadStorageFileArray(storage,path,bytes,count))return true;
    das::builtin_array_resize(bytes,0,1,ctx,at);return false;
}
inline bool SDL_GlobStorageDirectoryCopy(SDL_Storage * storage,const char * path,const char * pattern,SDL_GlobFlags flags,
        das::TArray<char *> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(char *),ctx,at);
    int count=0;
    std::unique_ptr<char *,decltype(&SDL_free)> owned(SDL_GlobStorageDirectory(storage,path,pattern,flags,&count),SDL_free);
    if(!owned)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(char *))return SDL_SetError("Glob result exceeds script array range");
    for(int i=0;i<count;++i)
        if(SDL_strlen(owned.get()[i])>UINT32_MAX)return SDL_SetError("Glob string exceeds script range");
    das::builtin_array_resize(out,count,sizeof(char *),ctx,at);
    auto ** values=reinterpret_cast<char **>(out.data);
    for(int i=0;i<count;++i)values[i]=sdl3_init_hints::copy(owned.get()[i],ctx,at);
    return true;
}
inline bool SDL_EnumerateStorageDirectoryCopy(SDL_Storage * storage,const char * path,das::TArray<char *> & out,
        das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(char *),ctx,at);
    sdl3_properties::Names names;
    if(!SDL_EnumerateStorageDirectory(storage,path,sdl3_filesystem::collect,&names))return false;
    if(size_t(names.count)>size_t(INT_MAX)/sizeof(char *))return SDL_SetError("Directory exceeds script array range");
    das::builtin_array_resize(out,names.count,sizeof(char *),ctx,at);
    auto ** values=reinterpret_cast<char **>(out.data);
    int i=0;
    for(auto * n=names.head;n;n=n->next)values[i++]=sdl3_init_hints::copy(n->name,ctx,at);
    return true;
}
