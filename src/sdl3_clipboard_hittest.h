#pragma once
#include "sdl3_callback_types.h"
#include "sdl3_pixels.h"
#include "daScript/simulate/aot.h"
#include "daScript/simulate/aot_builtin.h"
#include <atomic>
#include <new>
#include <string>
namespace sdl3_clipboard {
struct Payload {
    std::atomic<int> refs{2}; // Caller + SDL; a backend error may leave SDL's reference retained.
    char * mime=nullptr;void * data=nullptr;size_t size=0;
    ~Payload(){SDL_free(mime);SDL_free(data);}
};
inline void release(Payload * p){if(p->refs.fetch_sub(1)==1)delete p;}
inline const void * SDLCALL provide(void * userdata,const char * mime,size_t * size) {
    auto * p=static_cast<Payload *>(userdata);if(size)*size=0;
    if(!mime || SDL_strcmp(mime,p->mime)!=0)return nullptr;
    if(size)*size=p->size;return p->data;
}
inline void SDLCALL cleanup(void * userdata){release(static_cast<Payload *>(userdata));}
inline char * copy_text(char * text,das::Context * ctx,das::LineInfoArg * at){std::unique_ptr<char,decltype(&SDL_free)> owner(text,SDL_free);return text ? ctx->allocateString(text,at) : nullptr;}
}
inline bool SDL_SetClipboardDataCopy(const char * mime,const das::TArray<uint8_t> & bytes) {
    if(!SDL_IsMainThread() || !(SDL_WasInit(SDL_INIT_VIDEO)&SDL_INIT_VIDEO))return SDL_SetError("Clipboard requires initialized video on main thread");
    if(!mime || !*mime || !bytes.data || !bytes.size)return SDL_SetError("Clipboard expects a mime type and nonempty bytes");
    auto * p=new(std::nothrow) sdl3_clipboard::Payload;if(!p)return SDL_SetError("Clipboard allocation failed");
    p->mime=SDL_strdup(mime);p->data=SDL_malloc(bytes.size);p->size=bytes.size;
    if(!p->mime || !p->data){delete p;return SDL_SetError("Clipboard allocation failed");}
    SDL_memcpy(p->data,bytes.data,bytes.size);const char * types[]={p->mime};
    // With validation above, SDL takes ownership before every remaining failure path.
    bool ok=SDL_SetClipboardData(sdl3_clipboard::provide,sdl3_clipboard::cleanup,p,types,1);
    sdl3_clipboard::release(p);return ok;
}
inline char * SDL_GetClipboardTextCopy(das::Context * ctx,das::LineInfoArg * at){return sdl3_clipboard::copy_text(SDL_GetClipboardText(),ctx,at);}
inline char * SDL_GetPrimarySelectionTextCopy(das::Context * ctx,das::LineInfoArg * at){return sdl3_clipboard::copy_text(SDL_GetPrimarySelectionText(),ctx,at);}
inline bool SDL_GetClipboardDataCopy(const char * mime,das::TArray<uint8_t> & bytes,das::Context * ctx,das::LineInfoArg * at) {
    size_t size=0;std::unique_ptr<void,decltype(&SDL_free)> data(SDL_GetClipboardData(mime,&size),SDL_free);
    das::builtin_array_resize(bytes,0,1,ctx,at);
    if(!data)return false;if(size>INT_MAX)return SDL_SetError("Clipboard exceeds array limit");
    das::builtin_array_resize(bytes,uint32_t(size),1,ctx,at);if(size)SDL_memcpy(bytes.data,data.get(),size);return true;
}
inline bool SDL_GetClipboardMimeTypesCopy(das::TArray<char *> & types,das::Context * ctx,das::LineInfoArg * at) {
    size_t count=0;std::unique_ptr<char *,decltype(&SDL_free)> data(SDL_GetClipboardMimeTypes(&count),SDL_free);
    das::builtin_array_resize(types,0,sizeof(char *),ctx,at);
    if(!data)return false;if(count>INT_MAX/sizeof(char *))return SDL_SetError("Clipboard mime list exceeds array limit");
    das::builtin_array_resize(types,uint32_t(count),sizeof(char *),ctx,at);auto ** out=reinterpret_cast<char **>(types.data);
    for(size_t i=0;i<count;++i)out[i]=ctx->allocateString(data.get()[i],at);return true;
}
namespace sdl3_hittest {
inline const char * key="dassdl3.callback.hit-test";
inline void SDLCALL window_gone(void * userdata,void *){static_cast<SDL_HitTestBinding *>(userdata)->window=nullptr;}
inline SDL_HitTestResult SDLCALL invoke(SDL_Window * window,const SDL_Point * point,void * userdata) {
    auto * state=static_cast<SDL_HitTestBinding *>(userdata);
    if(!state || !point || state->active || !SDL_IsMainThread())return SDL_HITTEST_NORMAL;
    state->active=true;
    auto result=das::das_invoke<SDL_HitTestResult>::invoke<SDL_Window *,int,int>(state->context,state->at,state->callback,window,point->x,point->y);
    state->active=false;return result>=SDL_HITTEST_NORMAL && result<=SDL_HITTEST_RESIZE_LEFT ? result : SDL_HITTEST_NORMAL;
}
}
inline SDL_HitTestBinding * SDL_SetWindowHitTestBlock(SDL_Window * window,const das::TBlock<SDL_HitTestResult,SDL_Window * const,const int,const int> & callback,das::Context * ctx,das::LineInfoArg * at) {
    if(!SDL_IsMainThread()){SDL_SetError("Hit test requires main thread");return nullptr;}
    const auto props=SDL_GetWindowProperties(window);if(!props)return nullptr;
    if(SDL_HasProperty(props,sdl3_hittest::key)){SDL_SetError("Hit test scope already active");return nullptr;}
    auto * state=new(std::nothrow) SDL_HitTestBinding;if(!state){SDL_SetError("Hit test allocation failed");return nullptr;}
    state->window=window;state->callback=callback;state->context=ctx;state->at=at;
    if(!SDL_SetPointerPropertyWithCleanup(props,sdl3_hittest::key,state,sdl3_hittest::window_gone,state)){delete state;return nullptr;}
    if(!SDL_SetWindowHitTest(window,sdl3_hittest::invoke,state)){
        const std::string error=SDL_GetError();
        SDL_SetWindowHitTest(window,nullptr,nullptr);SDL_ClearProperty(props,sdl3_hittest::key);delete state;SDL_SetError("%s",error.c_str());return nullptr;
    }
    return state;
}
inline void SDL_ClearWindowHitTestBlock(SDL_HitTestBinding * state) {
    if(!state)return;
    if(state->window){auto * window=state->window;SDL_SetWindowHitTest(window,nullptr,nullptr);SDL_ClearProperty(SDL_GetWindowProperties(window),sdl3_hittest::key);}
    delete state;
}

// SDL clears callback/userdata before asking its backend to disable hit-testing.
inline bool SDL_ClearWindowHitTestBlockChecked(SDL_HitTestBinding * state) {
    if(!state)return true;
    bool ok=true;std::string error;
    if(state->window){
        SDL_Window * window=state->window;
        ok=SDL_SetWindowHitTest(window,nullptr,nullptr);if(!ok)error=SDL_GetError();
        const bool cleared=SDL_ClearProperty(SDL_GetWindowProperties(window),sdl3_hittest::key);
        if(ok && !cleared){ok=false;error=SDL_GetError();}
    }
    delete state;
    if(!ok)SDL_SetError("%s",error.c_str());return ok;
}

// AOT uses daScript's native-address representation for C callback parameters.
inline bool SDL_SetWindowHitTestAddress(SDL_Window * window,void * callback,void * userdata) {
    return SDL_SetWindowHitTest(window,reinterpret_cast<SDL_HitTest>(callback),userdata);
}
inline bool SDL_SetClipboardDataAddress(void * callback,void * cleanup,void * userdata,const char * const * types,size_t count) {
    return SDL_SetClipboardData(reinterpret_cast<SDL_ClipboardDataCallback>(callback),reinterpret_cast<SDL_ClipboardCleanupCallback>(cleanup),userdata,const_cast<const char **>(types),count);
}
