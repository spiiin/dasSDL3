#pragma once
#include "daScript/daScript.h"
#include "daScript/simulate/bind_enum.h"
#include <SDL3_ttf/SDL_ttf.h>
#include "generated/ttf_casts.inc"
static_assert(SDL_TTF_VERSION == 3002002,"Review bindings when updating SDL_ttf");

inline bool TTF_GetStringSizeRef(TTF_Font* font,const char* text,das::int2& size) {
    return TTF_GetStringSize(font,text,0,&size.x,&size.y);
}
inline bool TTF_GetTextSizeRef(TTF_Text* text,das::int2& size) {
    return TTF_GetTextSize(text,&size.x,&size.y);
}
inline bool TTF_GetGlyphMetricsRef(TTF_Font* font,uint32_t ch,das::int4& bounds,int& advance) {
    return TTF_GetGlyphMetrics(font,ch,&bounds.x,&bounds.y,&bounds.z,&bounds.w,&advance);
}

// Native SDL_Color is passed by value; daScript evaluates managed records as addresses.
namespace das {
template <> struct cast_arg<SDL_Color> {
    static SDL_Color to(Context& context, SimNode* node) {
        return *reinterpret_cast<const SDL_Color*>(node->evalPtr(context));
    }
};
}

// NULL draw data also means an empty/whitespace-only text. Disambiguate only
// this operation by clearing the thread-local error before calling SDL_ttf.
inline bool TTF_GetGPUTextDrawDataRef(TTF_Text* text, TTF_GPUAtlasDrawSequence*& out) {
    out=nullptr;
    if (!text || !TTF_GetTextEngine(text)) return SDL_InvalidParamError("text");
    SDL_ClearError();
    out=TTF_GetGPUTextDrawData(text);
    return out || !*SDL_GetError();
}

// The source must be a live sequence returned by SDL_ttf. CPU arrays are copied;
// atlas/next are borrowed. No script address is retained by SDL_ttf.
inline bool TTF_CopyGPUAtlasDrawSequence(const TTF_GPUAtlasDrawSequence* source,
    das::TArray<das::float2>& xy, das::TArray<das::float2>& uv, das::TArray<int32_t>& indices,
    SDL_GPUTexture*& atlas, TTF_ImageType& image_type, TTF_GPUAtlasDrawSequence*& next,
    das::Context* context, das::LineInfoArg* at) {
    das::builtin_array_resize(xy,0,sizeof(das::float2),context,at);
    das::builtin_array_resize(uv,0,sizeof(das::float2),context,at);
    das::builtin_array_resize(indices,0,sizeof(int32_t),context,at);
    atlas=nullptr; next=nullptr; image_type=TTF_IMAGE_INVALID;
    if (!source) return SDL_InvalidParamError("sequence");
    const int nv=source->num_vertices, ni=source->num_indices;
    if (nv<0 || ni<0 || nv>INT_MAX/int(sizeof(das::float2)) || ni>INT_MAX/int(sizeof(int32_t)) ||
        (nv && !source->xy) || (ni && !source->indices) || (nv && source->atlas_texture && !source->uv))
        return SDL_SetError("Invalid GPU text sequence arrays");
    for (int i=0;i<ni;++i)
        if (source->indices[i]<0 || source->indices[i]>=nv)
            return SDL_SetError("GPU text sequence index out of bounds");
    das::builtin_array_resize(xy,nv,sizeof(das::float2),context,at);
    das::builtin_array_resize(uv,source->uv ? nv : 0,sizeof(das::float2),context,at);
    das::builtin_array_resize(indices,ni,sizeof(int32_t),context,at);
    auto positions=reinterpret_cast<das::float2*>(xy.data);
    auto texcoords=reinterpret_cast<das::float2*>(uv.data);
    for (int i=0;i<nv;++i) {
        positions[i]={source->xy[i].x,source->xy[i].y};
        if (source->uv) texcoords[i]={source->uv[i].x,source->uv[i].y};
    }
    if (ni) std::memcpy(indices.data,source->indices,size_t(ni)*sizeof(int32_t));
    atlas=source->atlas_texture; image_type=source->image_type; next=source->next;
    return true;
}
