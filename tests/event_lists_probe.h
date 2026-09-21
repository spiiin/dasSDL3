#pragma once
#include <SDL3/SDL.h>
#include <climits>
namespace sdl3_test {
inline char candidate_text[64];
inline char mime_text[64];
inline const char * candidates[3];
inline const char * mime_types[3];
inline int user_tokens[2]={123,456};
inline void reset_event_lists() {
    SDL_strlcpy(candidate_text,u8"\u65e5\u672c \U0001f30d",sizeof(candidate_text));
    SDL_strlcpy(mime_text,"application/x-dassdl3",sizeof(mime_text));
    candidates[0]=candidate_text;candidates[1]="second";candidates[2]=nullptr;
    mime_types[0]="text/plain;charset=utf-8";mime_types[1]=mime_text;mime_types[2]=nullptr;
}
inline void mutate_event_lists() {
    SDL_strlcpy(candidate_text,"changed",sizeof(candidate_text));
    SDL_strlcpy(mime_text,"changed",sizeof(mime_text));
    candidates[1]="changed pointer";mime_types[0]="changed pointer";
}
inline SDL_Event list_event(uint32_t type,int mode) {
    SDL_Event e{};e.type=type;e.common.timestamp=0xfedcba9876543210ull;
    const char * const * strings=type==SDL_EVENT_TEXT_EDITING_CANDIDATES?candidates:mime_types;
    int count=3;
    if(mode==1){strings=nullptr;count=0;}
    if(mode==2){strings=reinterpret_cast<const char * const *>(uintptr_t(1));count=-1;}
    if(mode==3){strings=nullptr;count=3;}
    if(mode==4){strings=reinterpret_cast<const char * const *>(uintptr_t(1));count=INT_MAX;}
    if(type==SDL_EVENT_TEXT_EDITING_CANDIDATES) {
        e.edit_candidates.windowID=42;e.edit_candidates.candidates=strings;
        e.edit_candidates.num_candidates=count;e.edit_candidates.selected_candidate=mode==1?-1:2;
        e.edit_candidates.horizontal=mode!=1;
    } else {
        e.clipboard.mime_types=const_cast<const char **>(strings);e.clipboard.num_mime_types=count;
        e.clipboard.owner=mode!=1;
    }
    return e;
}
inline void * user_pointer(int index) {return index==0?&user_tokens[0]:&user_tokens[1];}
inline bool user_pointers_alive() {return user_tokens[0]==123 && user_tokens[1]==456;}
}
