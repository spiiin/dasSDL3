#pragma once
#include "sdl3_init_hints.h"
#include "sdl3_properties.h"

inline bool SDL_EnumerateDirectoryAddress(const char * path,void * callback,void * userdata) {
    return SDL_EnumerateDirectory(path,reinterpret_cast<SDL_EnumerateDirectoryCallback>(callback),userdata);
}
inline char * SDL_GetBasePathCopy(das::Context * ctx,das::LineInfoArg * at) {
    return sdl3_init_hints::copy(SDL_GetBasePath(),ctx,at);
}
inline char * SDL_GetUserFolderCopy(SDL_Folder folder,das::Context * ctx,das::LineInfoArg * at) {
    return sdl3_init_hints::copy(SDL_GetUserFolder(folder),ctx,at);
}
inline char * SDL_GetPrefPathCopy(const char * org,const char * app,das::Context * ctx,das::LineInfoArg * at) {
    std::unique_ptr<char,decltype(&SDL_free)> owned(SDL_GetPrefPath(org,app),SDL_free);
    return sdl3_init_hints::copy(owned.get(),ctx,at);
}
inline char * SDL_GetCurrentDirectoryCopy(das::Context * ctx,das::LineInfoArg * at) {
    std::unique_ptr<char,decltype(&SDL_free)> owned(SDL_GetCurrentDirectory(),SDL_free);
    return sdl3_init_hints::copy(owned.get(),ctx,at);
}
inline bool SDL_GetPathInfoRef(const char * path,SDL_PathInfo & info) {
    return SDL_GetPathInfo(path,&info);
}
inline bool SDL_GlobDirectoryCopy(const char * path,const char * pattern,SDL_GlobFlags flags,
        das::TArray<char *> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(char *),ctx,at);
    int count=0;
    std::unique_ptr<char *,decltype(&SDL_free)> owned(SDL_GlobDirectory(path,pattern,flags,&count),SDL_free);
    if(!owned)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(char *))return SDL_SetError("Glob result exceeds script array range");
    for(int i=0;i<count;++i)
        if(SDL_strlen(owned.get()[i])>UINT32_MAX)return SDL_SetError("Glob string exceeds script range");
    das::builtin_array_resize(out,count,sizeof(char *),ctx,at);
    auto ** values=reinterpret_cast<char **>(out.data);
    for(int i=0;i<count;++i)values[i]=sdl3_init_hints::copy(owned.get()[i],ctx,at);
    return true;
}
namespace sdl3_filesystem {
inline SDL_EnumerationResult SDLCALL collect(void * userdata,const char *,const char * name) {
    auto & names=*static_cast<sdl3_properties::Names *>(userdata);
    sdl3_properties::collect(&names,0,name);
    if(names.failed) { SDL_SetError("Directory names: allocation or size limit failure");return SDL_ENUM_FAILURE; }
    return SDL_ENUM_CONTINUE;
}
}
// Native callback collects names; script allocations occur after enumeration returns.
// The order is unspecified, as it is in SDL. No callbacks or native paths are retained.
inline bool SDL_EnumerateDirectoryCopy(const char * path,das::TArray<char *> & out,
        das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(char *),ctx,at);
    sdl3_properties::Names names;
    if(!SDL_EnumerateDirectory(path,sdl3_filesystem::collect,&names))return false;
    if(size_t(names.count)>size_t(INT_MAX)/sizeof(char *))return SDL_SetError("Directory exceeds script array range");
    das::builtin_array_resize(out,names.count,sizeof(char *),ctx,at);
    auto ** values=reinterpret_cast<char **>(out.data);
    int i=0;
    for(auto * n=names.head;n;n=n->next)values[i++]=sdl3_init_hints::copy(n->name,ctx,at);
    return true;
}
