#pragma once
#include "daScript/daScript.h"
#include "daScript/simulate/aot_builtin.h"
#include <SDL3/SDL.h>
#include <limits>
#include <memory>

// Only native allocation occurs under SDL's property lock/callback. Script
// allocation starts after SDL has unlocked; no script block crosses the C ABI.
inline char * SDL_GetStringPropertyCopy(SDL_PropertiesID props,const char * name,
        const char * fallback,das::Context * context,das::LineInfoArg * at) {
    if (!SDL_LockProperties(props)) return nullptr;
    char * copy=nullptr;
    // SDL 3.2.18 CopyProperties shallow-copies numeric string_storage. Avoid
    // populating that cache: produce the same scalar spelling in owned storage.
    switch(SDL_GetPropertyType(props,name)) {
    case SDL_PROPERTY_TYPE_NUMBER:
        SDL_asprintf(&copy,"%" SDL_PRIs64,SDL_GetNumberProperty(props,name,0)); break;
    case SDL_PROPERTY_TYPE_FLOAT:
        SDL_asprintf(&copy,"%f",double(SDL_GetFloatProperty(props,name,0))); break;
    default: {
        const char * value=SDL_GetStringProperty(props,name,fallback);
        copy=value ? SDL_strdup(value) : nullptr;
        break;
    }
    }
    SDL_UnlockProperties(props);
    std::unique_ptr<char,decltype(&SDL_free)> owned(copy,SDL_free);
    if (!copy) return nullptr;
    const size_t length=SDL_strlen(copy);
    if (length>std::numeric_limits<uint32_t>::max()) {
        SDL_SetError("Property string exceeds daScript string length"); return nullptr;
    }
    return context->allocateString(copy,uint32_t(length),at);
}
namespace sdl3_properties {
struct NameNode { NameNode * next; char * name; };
struct Names {
    NameNode * head=nullptr;
    int count=0;
    bool failed=false;
    ~Names() { while(head) { auto * n=head;head=n->next;SDL_free(n->name);SDL_free(n); } }
};
inline void SDLCALL collect(void * userdata,SDL_PropertiesID,const char * name) {
    auto & state=*static_cast<Names *>(userdata);
    if(state.failed)return;
    if(state.count==std::numeric_limits<int>::max() || SDL_strlen(name)>std::numeric_limits<uint32_t>::max()) {
        state.failed=true;return;
    }
    auto * node=static_cast<NameNode *>(SDL_malloc(sizeof(NameNode)));
    if(!node) { state.failed=true;return; }
    node->name=SDL_strdup(name);
    if(!node->name) { SDL_free(node);state.failed=true;return; }
    node->next=state.head;state.head=node;++state.count;
}
}
inline bool SDL_GetPropertyNamesCopy(SDL_PropertiesID props,das::TArray<char *> & output,
        das::Context * context,das::LineInfoArg * at) {
    das::builtin_array_resize(output,0,sizeof(char *),context,at);
    sdl3_properties::Names names;
    if(!SDL_EnumerateProperties(props,sdl3_properties::collect,&names))return false;
    if(names.failed)return SDL_SetError("Property names: allocation or size limit failure");
    das::builtin_array_resize(output,names.count,sizeof(char *),context,at);
    auto ** values=reinterpret_cast<char **>(output.data);
    int index=0;
    for(auto * node=names.head;node;node=node->next)
        values[index++]=context->allocateString(node->name,uint32_t(SDL_strlen(node->name)),at);
    return true;
}
