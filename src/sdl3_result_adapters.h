#pragma once
#include "sdl3_init_hints.h"
#include "sdl3_properties.h"
#include "sdl3_gpu_shader.h"
#include <memory>
// Presence is determined before script copying, since script empty strings may be null.
inline int SDL_GetAppMetadataOptionalCopy(const char * name,char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;
    const char * valid[]={SDL_PROP_APP_METADATA_NAME_STRING,SDL_PROP_APP_METADATA_VERSION_STRING,
        SDL_PROP_APP_METADATA_IDENTIFIER_STRING,SDL_PROP_APP_METADATA_CREATOR_STRING,
        SDL_PROP_APP_METADATA_COPYRIGHT_STRING,SDL_PROP_APP_METADATA_URL_STRING,SDL_PROP_APP_METADATA_TYPE_STRING};
    bool known=false;for(const char * key:valid)if(name && SDL_strcmp(name,key)==0){known=true;break;}
    if(!known){SDL_SetError("Invalid app metadata property name");return -1;}
    const char * text=SDL_GetAppMetadataProperty(name);value=sdl3_init_hints::copy(text,ctx,at);return text ? 1 : 0;
}
inline bool SDL_GetDisplayNameValue(SDL_DisplayID display, char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;
    auto * text=SDL_GetDisplayName(display);
    if(!text)return false;value=sdl3_init_hints::copy(text,ctx,at);return true;
}
inline bool SDL_GetWindowTitleValue(SDL_Window * window, char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;if(!SDL_GetWindowID(window))return false;
    auto * text=SDL_GetWindowTitle(window);
    if(!text)return false;value=sdl3_init_hints::copy(text,ctx,at);return true;
}
inline bool SDL_GetRenderDriverValue(int index, char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;
    auto * text=SDL_GetRenderDriver(index);
    if(!text)return false;value=sdl3_init_hints::copy(text,ctx,at);return true;
}
inline bool SDL_GetRendererNameValue(SDL_Renderer * renderer, char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;
    auto * text=SDL_GetRendererName(renderer);
    if(!text)return false;value=sdl3_init_hints::copy(text,ctx,at);return true;
}
inline bool SDL_GetClipboardTextValue(char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;
    auto * text=SDL_GetClipboardText();
    std::unique_ptr<char,decltype(&SDL_free)> owner(text,SDL_free);
    if(!text)return false;value=sdl3_init_hints::copy(text,ctx,at);return true;
}
inline bool SDL_GetPrimarySelectionTextValue(char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;
    auto * text=SDL_GetPrimarySelectionText();
    std::unique_ptr<char,decltype(&SDL_free)> owner(text,SDL_free);
    if(!text)return false;value=sdl3_init_hints::copy(text,ctx,at);return true;
}
inline bool SDL_GetGPUShaderEntryPointValue(SDL_GPUDevice * device,uint64_t shader,char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=SDL_GetGPUCheckedShaderEntryPoint(device,shader,ctx,at);return value!=nullptr;
}
inline bool SDL_GetPropertyStringValue(SDL_PropertiesID props,const char * name,const char * fallback,char * & value,das::Context * ctx,das::LineInfoArg * at) {
    value=nullptr;
    if(!SDL_LockProperties(props))return false;
    char * text=nullptr;
    switch(SDL_GetPropertyType(props,name)) {
    case SDL_PROPERTY_TYPE_NUMBER:SDL_asprintf(&text,"%" SDL_PRIs64,SDL_GetNumberProperty(props,name,0));break;
    case SDL_PROPERTY_TYPE_FLOAT:SDL_asprintf(&text,"%f",double(SDL_GetFloatProperty(props,name,0)));break;
    default:{const char * source=SDL_GetStringProperty(props,name,fallback ? fallback : "");text=SDL_strdup(source ? source : "");break;}
    }
    SDL_UnlockProperties(props);
    std::unique_ptr<char,decltype(&SDL_free)> owner(text,SDL_free);
    if(!text)return SDL_SetError("Property string allocation failed");
    value=sdl3_init_hints::copy(text,ctx,at);return true;
}
