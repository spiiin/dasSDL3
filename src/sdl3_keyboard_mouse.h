#pragma once
#include "sdl3_video.h"

inline bool SDL_GetKeyboardsCopy(das::TArray<uint32_t> & out, das::Context * ctx, das::LineInfoArg * at) {
    int count=0; auto * ids=SDL_GetKeyboards(&count);
    return sdl3_video::copy_array(ids,count,out,ctx,at);
}
inline bool SDL_GetMiceCopy(das::TArray<uint32_t> & out, das::Context * ctx, das::LineInfoArg * at) {
    int count=0; auto * ids=SDL_GetMice(&count);
    return sdl3_video::copy_array(ids,count,out,ctx,at);
}
inline void SDL_GetKeyboardStateCopy(das::TArray<bool> & out, das::Context * ctx, das::LineInfoArg * at) {
    int count=0; const bool * keys=SDL_GetKeyboardState(&count);
    das::builtin_array_resize(out,count,sizeof(bool),ctx,at);
    if (count) SDL_memcpy(out.data,keys,size_t(count)*sizeof(bool));
}
inline bool SDL_GetKeyboardNameValue(uint32_t id,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * value=SDL_GetKeyboardNameForID(id); out=sdl3_init_hints::copy(value,ctx,at); return value!=nullptr;
}
inline bool SDL_GetMouseNameValue(uint32_t id,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * value=SDL_GetMouseNameForID(id); out=sdl3_init_hints::copy(value,ctx,at); return value!=nullptr;
}
inline char * SDL_GetKeyNameCopy(uint32_t key,das::Context * ctx,das::LineInfoArg * at) {
    return sdl3_init_hints::copy(SDL_GetKeyName(key),ctx,at);
}
inline char * SDL_GetScancodeNameCopy(SDL_Scancode code,das::Context * ctx,das::LineInfoArg * at) {
    return sdl3_init_hints::copy(SDL_GetScancodeName(code),ctx,at);
}
inline SDL_Scancode SDL_GetScancodeFromKeyRef(uint32_t key,uint32_t & mods) { SDL_Keymod native=0; const auto code=SDL_GetScancodeFromKey(key,&native); mods=native;return code;}
inline uint32_t SDL_GetGlobalMouseStateRef(float & x,float & y) {return SDL_GetGlobalMouseState(&x,&y);}
inline uint32_t SDL_GetRelativeMouseStateRef(float & x,float & y) {return SDL_GetRelativeMouseState(&x,&y);}
inline bool SDL_SetTextInputAreaRef(SDL_Window * window,const SDL_Rect & rect,int cursor) {return SDL_SetTextInputArea(window,&rect,cursor);}
inline bool SDL_GetTextInputAreaRef(SDL_Window * window,SDL_Rect & rect,int & cursor) {
    rect={};cursor=0;return SDL_GetTextInputArea(window,&rect,&cursor);
}
inline SDL_Cursor * SDL_CreateCursorArray(const das::TArray<uint8_t> & data,const das::TArray<uint8_t> & mask,
        int w,int h,int hot_x,int hot_y) {
    if (w<=0 || h<=0 || w%8 || hot_x<0 || hot_y<0 || hot_x>=w || hot_y>=h) {
        SDL_SetError("Invalid cursor dimensions or hotspot");return nullptr;
    }
    const uint64_t bytes=uint64_t(w/8)*uint64_t(h);
    if (bytes>data.size || bytes>mask.size || !data.data || !mask.data) {
        SDL_SetError("Cursor bitmap arrays are too small");return nullptr;
    }
    return SDL_CreateCursor(reinterpret_cast<const uint8_t *>(data.data),reinterpret_cast<const uint8_t *>(mask.data),w,h,hot_x,hot_y);
}
