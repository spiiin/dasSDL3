#pragma once
#include "sdl3_filesystem.h"
// Pinned Windows SDL dereferences a documented nullable tooltip.
inline SDL_Tray * SDL_CreateTrayText(SDL_Surface * icon,const char * tooltip) {return SDL_CreateTray(icon,tooltip?tooltip:"");}
inline SDL_DialogFileFilter SDL_MakeDialogFileFilter(const char * name,const char * pattern) {return {name,pattern};}
#if defined(SDL_PLATFORM_WINDOWS)
inline void SDL_SetWindowsMessageHookAddress(void * callback,void * userdata) {SDL_SetWindowsMessageHook(reinterpret_cast<SDL_WindowsMessageHook>(callback),userdata);}
#endif
inline void SDL_SetX11EventHookAddress(void * callback,void * userdata) {SDL_SetX11EventHook(reinterpret_cast<SDL_X11EventHook>(callback),userdata);}
inline void SDL_SetTrayEntryCallbackAddress(SDL_TrayEntry * entry,void * callback,void * userdata) {SDL_SetTrayEntryCallback(entry,reinterpret_cast<SDL_TrayCallback>(callback),userdata);}
inline void SDL_ShowOpenFileDialogAddress(void * callback,void * userdata,SDL_Window * window,const SDL_DialogFileFilter * filters,int count,const char * location,bool many) {SDL_ShowOpenFileDialog(reinterpret_cast<SDL_DialogFileCallback>(callback),userdata,window,filters,count,location,many);}
inline void SDL_ShowSaveFileDialogAddress(void * callback,void * userdata,SDL_Window * window,const SDL_DialogFileFilter * filters,int count,const char * location) {SDL_ShowSaveFileDialog(reinterpret_cast<SDL_DialogFileCallback>(callback),userdata,window,filters,count,location);}
inline void SDL_ShowOpenFolderDialogAddress(void * callback,void * userdata,SDL_Window * window,const char * location,bool many) {SDL_ShowOpenFolderDialog(reinterpret_cast<SDL_DialogFileCallback>(callback),userdata,window,location,many);}
inline void SDL_ShowFileDialogWithPropertiesAddress(SDL_FileDialogType type,void * callback,void * userdata,uint32_t props) {SDL_ShowFileDialogWithProperties(type,reinterpret_cast<SDL_DialogFileCallback>(callback),userdata,props);}
inline SDL_PowerState SDL_GetPowerInfoRef(int & seconds,int & percent) {return SDL_GetPowerInfo(&seconds,&percent);}
#if defined(SDL_PLATFORM_WINDOWS)
inline bool SDL_GetDXGIOutputInfoRef(uint32_t display,int & adapter,int & output) {return SDL_GetDXGIOutputInfo(display,&adapter,&output);}
#endif
inline bool SDL_GetPreferredLocalesCopy(das::TArray<SDL_Locale> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(SDL_Locale),ctx,at);int count=0;
    std::unique_ptr<SDL_Locale *,decltype(&SDL_free)> owned(SDL_GetPreferredLocales(&count),SDL_free);
    if(!owned)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(SDL_Locale))return SDL_SetError("Locale count exceeds script array range");
    das::builtin_array_resize(out,count,sizeof(SDL_Locale),ctx,at);
    auto * values=reinterpret_cast<SDL_Locale *>(out.data);
    for(int i=0;i<count;++i) {
        values[i].language=sdl3_init_hints::copy(owned.get()[i]->language,ctx,at);
        values[i].country=owned.get()[i]->country?sdl3_init_hints::copy(owned.get()[i]->country,ctx,at):nullptr;
    }
    return true;
}
inline bool SDL_GetTrayEntriesCopy(SDL_TrayMenu * menu,das::TArray<SDL_TrayEntry *> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(SDL_TrayEntry *),ctx,at);int count=0;
    if(!menu)return SDL_SetError("Null tray menu");
    const auto ** entries=SDL_GetTrayEntries(menu,&count);
    // A freshly created native menu may have no backing array yet.
    if(!entries && count)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(SDL_TrayEntry *))return SDL_SetError("Tray entry count exceeds script array range");
    das::builtin_array_resize(out,count,sizeof(SDL_TrayEntry *),ctx,at);
    auto ** values=reinterpret_cast<SDL_TrayEntry **>(out.data);
    for(int i=0;i<count;++i)values[i]=const_cast<SDL_TrayEntry *>(entries[i]);
    return true;
}
inline char * SDL_GetTrayEntryLabelCopy(SDL_TrayEntry * entry,das::Context * ctx,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetTrayEntryLabel(entry),ctx,at);}
