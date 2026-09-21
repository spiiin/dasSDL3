#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
struct StorageState {SDL_Storage * backing=nullptr;unsigned mask=0;int closes=0;int polls=0;bool fail=false;};
inline StorageState storage_state;
inline void * storage_reset(const char * root,bool fail) {storage_state={};storage_state.backing=SDL_OpenFileStorage(root);storage_state.fail=fail;return &storage_state;}
inline bool SDLCALL storage_close(void * p) {auto & s=*static_cast<StorageState *>(p);s.mask|=1;++s.closes;SDL_CloseStorage(s.backing);s.backing=nullptr;return !s.fail || SDL_SetError("storage close failure");}
inline bool SDLCALL storage_ready(void * p) {auto & s=*static_cast<StorageState *>(p);s.mask|=2;return ++s.polls>1;}
inline bool SDLCALL storage_enumerate(void * p,const char * path,SDL_EnumerateDirectoryCallback cb,void * data) {auto & s=*static_cast<StorageState *>(p);s.mask|=4;return SDL_EnumerateStorageDirectory(s.backing,path,cb,data);}
inline bool SDLCALL storage_info(void * p,const char * path,SDL_PathInfo * out) {auto & s=*static_cast<StorageState *>(p);s.mask|=8;return SDL_GetStoragePathInfo(s.backing,path,out);}
inline bool SDLCALL storage_read_file(void * p,const char * path,void * data,Uint64 n) {auto & s=*static_cast<StorageState *>(p);s.mask|=16;return SDL_ReadStorageFile(s.backing,path,data,n);}
inline bool SDLCALL storage_write_file(void * p,const char * path,const void * data,Uint64 n) {auto & s=*static_cast<StorageState *>(p);s.mask|=32;return SDL_WriteStorageFile(s.backing,path,data,n);}
inline bool SDLCALL storage_mkdir(void * p,const char * path) {auto & s=*static_cast<StorageState *>(p);s.mask|=64;return SDL_CreateStorageDirectory(s.backing,path);}
inline bool SDLCALL storage_remove(void * p,const char * path) {auto & s=*static_cast<StorageState *>(p);s.mask|=128;return SDL_RemoveStoragePath(s.backing,path);}
inline bool SDLCALL storage_rename(void * p,const char * a,const char * b) {auto & s=*static_cast<StorageState *>(p);s.mask|=256;return SDL_RenameStoragePath(s.backing,a,b);}
inline bool SDLCALL storage_copy(void * p,const char * a,const char * b) {auto & s=*static_cast<StorageState *>(p);s.mask|=512;return SDL_CopyStorageFile(s.backing,a,b);}
inline Uint64 SDLCALL storage_space_remaining(void * p) {auto & s=*static_cast<StorageState *>(p);s.mask|=1024;return 0;}
inline unsigned storage_mask() {return storage_state.mask;}
inline int storage_closes() {return storage_state.closes;}
inline void * storage_callback(int index) {
 switch(index) {
case 0:return reinterpret_cast<void *>(storage_close);
case 1:return reinterpret_cast<void *>(storage_ready);
case 2:return reinterpret_cast<void *>(storage_enumerate);
case 3:return reinterpret_cast<void *>(storage_info);
case 4:return reinterpret_cast<void *>(storage_read_file);
case 5:return reinterpret_cast<void *>(storage_write_file);
case 6:return reinterpret_cast<void *>(storage_mkdir);
case 7:return reinterpret_cast<void *>(storage_remove);
case 8:return reinterpret_cast<void *>(storage_rename);
case 9:return reinterpret_cast<void *>(storage_copy);
case 10:return reinterpret_cast<void *>(storage_space_remaining);
default:return nullptr;
 }
}
}
