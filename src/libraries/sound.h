#pragma once
#include "daScript/daScript.h"
#include "daScript/simulate/bind_enum.h"
#include <SDL3_sound/SDL_sound.h>
#include "generated/sound_casts.inc"
static_assert(SDL_SOUND_VERSION == 3002000,"Review bindings when updating SDL_sound");
// Public sample fields are read-only in SDL_sound: lend opaque handles, copy metadata.
inline uint32_t Sound_GetSampleFlags(const Sound_Sample* sample) { return uint32_t(sample->flags); }
inline uint32_t Sound_GetSampleBufferSize(const Sound_Sample* sample) { return sample->buffer_size; }
inline void Sound_GetSampleActualRef(const Sound_Sample* sample, SDL_AudioSpec& spec) { spec=sample->actual; }
inline void Sound_GetSampleDesiredRef(const Sound_Sample* sample, SDL_AudioSpec& spec) { spec=sample->desired; }
inline const Sound_DecoderInfo* Sound_GetSampleDecoder(const Sound_Sample* sample) { return sample->decoder; }
inline char* Sound_GetDecoderDescriptionCopy(const Sound_DecoderInfo* decoder,das::Context* ctx,das::LineInfoArg* at) {
    return ctx->allocateString(decoder->description,at);
}
inline char* Sound_GetErrorCopy(das::Context* ctx,das::LineInfoArg* at) {
    const char* error=Sound_GetError(); return error ? ctx->allocateString(error,at) : nullptr;
}
inline Sound_Sample* Sound_NewSampleFromFileRef(const char* path,const SDL_AudioSpec& spec,uint32_t size) {
    return Sound_NewSampleFromFile(path,&spec,size);
}
inline bool Sound_CopySampleBytes(const Sound_Sample* sample,uint32_t count,das::TArray<uint8_t>& bytes,das::Context* ctx,das::LineInfoArg* at) {
    if (!sample || count>sample->buffer_size || (count && !sample->buffer)) return SDL_InvalidParamError("sample/count");
    das::builtin_array_resize(bytes,count,1,ctx,at);
    if(count) std::memcpy(bytes.data,sample->buffer,count);
    return true;
}

inline bool Sound_ValidateSampleRequest(const SDL_AudioSpec& spec,uint32_t size) {
    const int bits=SDL_AUDIO_BITSIZE(spec.format);
    if (spec.channels<1 || spec.channels>255 || spec.freq<1 || (bits!=8 && bits!=16 && bits!=32))
        return SDL_SetError("Invalid PCM output specification");
    const uint32_t frame=uint32_t(bits/8)*uint32_t(spec.channels);
    if (!size || size>INT_MAX || size%frame) return SDL_SetError("Buffer must contain whole output frames and fit INT_MAX");
    return true;
}
inline uint32_t Sound_GetDecoderCount() {
    auto decoders=Sound_AvailableDecoders(); uint32_t count=0;
    if(decoders) while(decoders[count]) ++count;
    return count;
}
inline const Sound_DecoderInfo* Sound_GetDecoderAt(uint32_t index) {
    return index<Sound_GetDecoderCount() ? Sound_AvailableDecoders()[index] : nullptr;
}
inline char* Sound_GetDecoderAuthorCopy(const Sound_DecoderInfo* decoder,das::Context* ctx,das::LineInfoArg* at) {
    return ctx->allocateString(decoder->author,at);
}
inline char* Sound_GetDecoderUrlCopy(const Sound_DecoderInfo* decoder,das::Context* ctx,das::LineInfoArg* at) {
    return ctx->allocateString(decoder->url,at);
}
inline char* Sound_GetDecoderExtensionCopy(const Sound_DecoderInfo* decoder,uint32_t index,das::Context* ctx,das::LineInfoArg* at) {
    const char** extensions=decoder->extensions;
    for(uint32_t i=0; extensions[i]; ++i) if(i==index) return ctx->allocateString(extensions[i],at);
    return nullptr;
}
