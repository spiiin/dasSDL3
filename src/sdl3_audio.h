#pragma once
#include <SDL3/SDL.h>
#include "daScript/daScript.h"
#include <climits>
#include <new>

// An opaque owned WAV buffer, not a copyable script value.
struct SDL_Wav {
    SDL_AudioSpec spec{};
    Uint8 * data = nullptr;
    Uint32 size = 0;
};
#ifdef DASSDL3_TESTING
inline int SDL_TestLiveWavs = 0;
#endif
inline SDL_Wav * SDL_LoadWavOwned(const char * path) {
    auto * wav = new (std::nothrow) SDL_Wav;
    if (!wav) { SDL_OutOfMemory(); return nullptr; }
    if (!SDL_LoadWAV(path, &wav->spec, &wav->data, &wav->size)) {
        // SDL_LoadWAV already frees failed output; its pinned failure out-pointer may be stale.
        delete wav;
        return nullptr;
    }
#ifdef DASSDL3_TESTING
    ++SDL_TestLiveWavs;
#endif
    return wav;
}
inline void SDL_DestroyWav(SDL_Wav * wav) {
    if (!wav) return;
    SDL_free(wav->data);
    delete wav;
#ifdef DASSDL3_TESTING
    --SDL_TestLiveWavs;
#endif
}
inline SDL_AudioSpec SDL_WavSpec(const SDL_Wav * wav) { return wav ? wav->spec : SDL_AudioSpec{}; }
inline uint32_t SDL_WavSize(const SDL_Wav * wav) { return wav ? wav->size : 0; }
inline uint32_t SDL_AudioSpecFormat(const SDL_AudioSpec & spec) { return uint32_t(spec.format); }
inline SDL_AudioSpec SDL_MakeAudioSpec(uint32_t format, int channels, int freq) {
    return {static_cast<SDL_AudioFormat>(format), channels, freq};
}
inline SDL_AudioStream * SDL_CreateAudioStreamRef(const SDL_AudioSpec & src, const SDL_AudioSpec & dst) {
    return SDL_CreateAudioStream(&src, &dst);
}
inline SDL_AudioStream * SDL_OpenPlaybackStream(const SDL_AudioSpec & spec) {
    return SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, nullptr, nullptr);
}
inline bool SDL_QueueWav(SDL_AudioStream * stream, const SDL_Wav * wav) {
    if (!wav) return SDL_SetError("queue_wav: null WAV");
    if (wav->size > INT_MAX) return SDL_SetError("queue_wav: WAV exceeds INT_MAX bytes");
    SDL_AudioSpec src{};
    if (!SDL_GetAudioStreamFormat(stream, &src, nullptr)) return false;
    if (src.format != wav->spec.format || src.channels != wav->spec.channels || src.freq != wav->spec.freq)
        return SDL_SetError("queue_wav: WAV format does not match stream input");
    return SDL_PutAudioStreamData(stream, wav->data, int(wav->size));
}
inline bool SDL_PutAudioBytes(SDL_AudioStream * stream, const das::TArray<uint8_t> & bytes) {
    if (!stream) return SDL_SetError("put_audio: null stream");
    if (bytes.size > INT_MAX) return SDL_SetError("put_audio: array exceeds INT_MAX bytes");
    if (!bytes.size) return true;
    return SDL_PutAudioStreamData(stream, bytes.data, int(bytes.size));
}
inline int SDL_GetAudioBytes(SDL_AudioStream * stream, das::TArray<uint8_t> & bytes) {
    if (!stream) { SDL_SetError("read_audio: null stream"); return -1; }
    if (bytes.size > INT_MAX) { SDL_SetError("read_audio: array exceeds INT_MAX bytes"); return -1; }
    if (!bytes.size) return 0;
    return SDL_GetAudioStreamData(stream, bytes.data, int(bytes.size));
}
