#pragma once
#include "sdl3_joystick_gamepad.h"
#include <vector>
inline SDL_GUID SDL_StringToGUIDText(const char * text) { return SDL_StringToGUID(text ? text : ""); }
inline bool SDL_OpenURLText(const char * url) {
    if (!url || !*url) return SDL_SetError("Empty URL");
    return SDL_OpenURL(url);
}
inline bool SDL_ShowMessageBoxArray(uint32_t flags,const char * title,const char * message,
        const das::TArray<SDL_MessageBoxButtonData> & buttons,SDL_Window * window,
        const SDL_MessageBoxColorScheme * colors,int & selected) {
    selected=-1;
    if (buttons.size>INT_MAX || (buttons.size && !buttons.data)) return SDL_SetError("Invalid message box button array");
    auto * entries=reinterpret_cast<const SDL_MessageBoxButtonData *>(buttons.data);
    std::vector<SDL_MessageBoxButtonData> normalized;
    normalized.reserve(buttons.size);
    for (uint32_t i=0;i<buttons.size;++i) {
        if (entries[i].buttonID == -1) return SDL_SetError("Button ID -1 is reserved for closing the message box");
        normalized.push_back(entries[i]);
        if (!normalized.back().text) normalized.back().text="";
    }
    SDL_MessageBoxData data{flags,window,title,message,int(buttons.size),normalized.data(),colors};
    return SDL_ShowMessageBox(&data,&selected);
}
inline bool SDL_ShowMessageBoxColors(uint32_t flags,const char * title,const char * message,
        const das::TArray<SDL_MessageBoxButtonData> & buttons,SDL_Window * window,
        const SDL_MessageBoxColorScheme & colors,int & selected) {
    return SDL_ShowMessageBoxArray(flags,title,message,buttons,window,&colors,selected);
}
