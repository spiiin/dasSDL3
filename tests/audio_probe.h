#pragma once
#include <cmath>
#include <cstring>
namespace sdl3_test {
inline int audio_destroyed = 0;
inline int audio_tag = 1;
inline void SDLCALL audio_cleanup(void *, void *) { ++audio_destroyed; }
inline int live_wavs() { return SDL_TestLiveWavs; }
inline int destroyed_streams() { return audio_destroyed; }
inline bool watch_audio(SDL_AudioStream * stream) {
    return SDL_SetPointerPropertyWithCleanup(SDL_GetAudioStreamProperties(stream),
        "dassdl3.test.audio", &audio_tag, audio_cleanup, nullptr);
}
inline bool matches_wav(const char * path, const das::TArray<uint8_t> & bytes) {
    SDL_AudioSpec spec{}; Uint8 * data = nullptr; Uint32 size = 0;
    if (!SDL_LoadWAV(path, &spec, &data, &size)) return false;
    bool matches = bytes.size == size && std::memcmp(bytes.data, data, size) == 0;
    SDL_free(data);
    return matches;
}
inline bool stereo_float_signal(const das::TArray<uint8_t> & bytes) {
    if (!bytes.size || bytes.size % 8) return false;
    float peak = 0;
    for (uint32_t offset = 0; offset < bytes.size; offset += 8) {
        float pair[2]; std::memcpy(pair, bytes.data + offset, 8);
        if (!std::isfinite(pair[0]) || pair[0] != pair[1] || std::abs(pair[0]) > 0.14f) return false;
        peak = std::max(peak, std::abs(pair[0]));
    }
    return peak > 0.10f;
}
inline bool device_closed(uint32_t id) { return SDL_GetAudioDeviceName(id) == nullptr; }
}
