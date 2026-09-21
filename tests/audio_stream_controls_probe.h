#pragma once
#include <thread>
namespace sdl3_test {
inline bool audio_stream_lock_from_thread(SDL_AudioStream * stream) {
    bool success=false;
    std::thread worker([&] {success=SDL_LockAudioStream(stream);if(success)success=SDL_UnlockAudioStream(stream);});
    worker.join();return success;
}
}
