#pragma once
#include "sdl3_video.h"

namespace sdl3_event_lists {
inline bool copy(const char * const * values,int count,das::TArray<char *> & out,
                 das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(char *),ctx,at);
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(char *) || (count && !values))
        return SDL_SetError("Invalid event string list");
    for(int i=0;i<count;++i) {
        if(values[i] && SDL_strlen(values[i])>UINT32_MAX)return SDL_SetError("Event string exceeds script length range");
    }
    das::builtin_array_resize(out,count,sizeof(char *),ctx,at);
    auto ** dest=reinterpret_cast<char **>(out.data);
    for(int i=0;i<count;++i)dest[i]=sdl3_init_hints::copy(values[i]?values[i]:"",ctx,at);
    return true;
}
}
inline bool SDL_ReadTextEditingCandidatesEvent(const SDL_Event & event,SDL_TextEditingCandidatesEvent & out,
        das::TArray<char *> & candidates,das::Context * ctx,das::LineInfoArg * at) {
    out={};das::builtin_array_resize(candidates,0,sizeof(char *),ctx,at);
    if(event.type!=SDL_EVENT_TEXT_EDITING_CANDIDATES)return false;
    const auto & payload=event.edit_candidates;
    if(!sdl3_event_lists::copy(payload.candidates,payload.num_candidates,candidates,ctx,at))return false;
    out=payload;out.candidates=nullptr;return true;
}
inline bool SDL_ReadClipboardEvent(const SDL_Event & event,SDL_ClipboardEvent & out,
        das::TArray<char *> & mime_types,das::Context * ctx,das::LineInfoArg * at) {
    out={};das::builtin_array_resize(mime_types,0,sizeof(char *),ctx,at);
    if(event.type!=SDL_EVENT_CLIPBOARD_UPDATE)return false;
    const auto & payload=event.clipboard;
    if(!sdl3_event_lists::copy(payload.mime_types,payload.num_mime_types,mime_types,ctx,at))return false;
    out=payload;out.mime_types=nullptr;return true;
}
// Application pointers are borrowed tokens: never dereferenced, cloned or freed.
inline bool SDL_ReadUserEventData(const SDL_Event & event,void *& data1,void *& data2) {
    data1=data2=nullptr;
    if(event.type<SDL_EVENT_USER || event.type>=SDL_EVENT_LAST)return false;
    data1=event.user.data1;data2=event.user.data2;return true;
}
inline bool SDL_WriteUserEventData(SDL_Event & event,void * data1,void * data2) {
    if(event.type<SDL_EVENT_USER || event.type>=SDL_EVENT_LAST)return false;
    event.user.data1=data1;event.user.data2=data2;return true;
}
