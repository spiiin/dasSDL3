#pragma once
#include <SDL3/SDL.h>
// Native C addresses, never script Func/Block objects.
inline void * SDL_GL_GetProcAddressAddress(const char * name) { return reinterpret_cast<void *>(SDL_GL_GetProcAddress(name)); }
inline void * SDL_EGL_GetProcAddressAddress(const char * name) { return reinterpret_cast<void *>(SDL_EGL_GetProcAddress(name)); }
inline void SDL_EGL_SetAttributeCallbacksAddress(void * platform,void * surface,void * context,void * data) {
    SDL_EGL_SetAttributeCallbacks(reinterpret_cast<SDL_EGLAttribArrayCallback>(platform),reinterpret_cast<SDL_EGLIntArrayCallback>(surface),reinterpret_cast<SDL_EGLIntArrayCallback>(context),data);
}
inline bool SDL_GL_LoadLibraryDefault() { return SDL_GL_LoadLibrary(nullptr); }
inline bool SDL_GL_GetAttributeRef(SDL_GLAttr attribute,int & value) { return SDL_GL_GetAttribute(attribute,&value); }
inline bool SDL_GL_GetSwapIntervalRef(int & value) { return SDL_GL_GetSwapInterval(&value); }
