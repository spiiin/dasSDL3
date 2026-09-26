#pragma once
#include "sdl3_init_hints.h"
#include <SDL3/SDL_vulkan.h>
#include <SDL3/SDL_metal.h>
#include <climits>
// SDL's non-dispatchable surface is a pointer on the validated 64-bit target.
inline void * SDL_Vulkan_GetVkGetInstanceProcAddrAddress() { return reinterpret_cast<void *>(SDL_Vulkan_GetVkGetInstanceProcAddr()); }
inline bool SDL_Vulkan_LoadLibraryDefault() { return SDL_Vulkan_LoadLibrary(nullptr); }
inline bool SDL_Vulkan_CreateSurfaceRef(SDL_Window * window,VkInstance instance,const VkAllocationCallbacks * allocator,VkSurfaceKHR & surface) {
    surface={};
    return SDL_Vulkan_CreateSurface(window,instance,allocator,&surface);
}
inline void SDL_Vulkan_DestroySurfaceRef(VkInstance instance,VkSurfaceKHR & surface,const VkAllocationCallbacks * allocator) {
    SDL_Vulkan_DestroySurface(instance,surface,allocator);surface={};
}
inline bool SDL_Vulkan_GetInstanceExtensionsCopy(das::TArray<char *> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(char *),ctx,at);
    // The pinned raw getter dereferences the video backend without checking it.
    // A loaded Vulkan entry point establishes its documented loader precondition.
    if(!SDL_Vulkan_GetVkGetInstanceProcAddr()) return false;
    Uint32 count=0;const char * const * names=SDL_Vulkan_GetInstanceExtensions(&count);
    if(!names) return false;
    if(count>INT_MAX/sizeof(char *)) return SDL_SetError("Vulkan extension count exceeds script range");
    for(Uint32 i=0;i<count;++i)
        if(!names[i] || SDL_strlen(names[i])>UINT32_MAX) return SDL_SetError("Invalid Vulkan extension name");
    das::builtin_array_resize(out,int(count),sizeof(char *),ctx,at);
    auto ** values=reinterpret_cast<char **>(out.data);
    for(Uint32 i=0;i<count;++i) values[i]=sdl3_init_hints::copy(names[i],ctx,at);
    return true;
}
