#pragma once
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#endif
#include <SDL3/SDL.h>
#include <atomic>
namespace sdl3_test {
inline std::atomic<int> platform_hook_count{0},platform_tray_count{0},platform_dialog_count{0},platform_lifecycle_mask{0};
#ifdef _WIN32
inline bool SDLCALL platform_hook(void *,MSG * msg) {if(msg && msg->message==WM_APP+51)platform_hook_count++;return true;}
#endif
inline void SDLCALL platform_tray(void *,SDL_TrayEntry *) {platform_tray_count++;}
inline void SDLCALL platform_dialog(void *,const char * const * files,int filter) {if(!files && filter==-1 && *SDL_GetError())platform_dialog_count++;}
inline bool SDLCALL platform_lifecycle(void *,SDL_Event * event) {
    int bit=0;switch(event->type) {
    case SDL_EVENT_LOW_MEMORY:bit=1;break;case SDL_EVENT_TERMINATING:bit=2;break;
    case SDL_EVENT_WILL_ENTER_BACKGROUND:bit=4;break;case SDL_EVENT_DID_ENTER_BACKGROUND:bit=8;break;
    case SDL_EVENT_WILL_ENTER_FOREGROUND:bit=16;break;case SDL_EVENT_DID_ENTER_FOREGROUND:bit=32;break;
    default:break;
    }platform_lifecycle_mask.fetch_or(bit);return true;
}
inline void platform_reset() {platform_hook_count=0;platform_tray_count=0;platform_dialog_count=0;platform_lifecycle_mask=0;}
inline void * platform_callback(int kind) {switch(kind) {
#ifdef _WIN32
case 0:return reinterpret_cast<void *>(platform_hook);
#endif
case 1:return reinterpret_cast<void *>(platform_tray);case 2:return reinterpret_cast<void *>(platform_dialog);case 3:return reinterpret_cast<void *>(platform_lifecycle);default:return nullptr;}}
inline int platform_count(int kind) {switch(kind) {case 0:return platform_hook_count.load();case 1:return platform_tray_count.load();case 2:return platform_dialog_count.load();case 3:return platform_lifecycle_mask.load();default:return -1;}}
inline bool platform_post() {
#ifdef _WIN32
return PostThreadMessageW(GetCurrentThreadId(),WM_APP+51,0,0)!=0;
#else
return false;
#endif
}
}
