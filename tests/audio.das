options gen2
require dassdl3/sdl3_audio_boost
require daslib/rtti
require daslib/strings_boost

[export]
def main(smoke : bool) : int {
    verify(smoke)
    let path = "{SDL_GetBasePath()}assets/tone.wav"
    let src = audio_spec(SDL_AUDIO_S16LE, 1, 22050)
    let scope_ok_0 = with_sdl(SDL_INIT_AUDIO) {
        verify(SDL_WasInit(SDL_INIT_AUDIO) != 0u && SDL_WasInit(SDL_INIT_VIDEO) == 0u)
        // No device is attached here. Read back the stream after freeing the WAV.
        let scope_ok_1 = with_audio_stream(src, src) $(stream : SDL_AudioStream?) {
            verify(SDL_GetAudioStreamDevice(stream) == 0u)
            let scope_ok_2 = with_wav(path) $(wav : SDL_Wav?) {
                let spec = unwrap_or(wav_spec(wav), default<SDL_AudioSpec>)
                verify(audio_format(spec) == SDL_AUDIO_S16LE && spec.channels == 1 && spec.freq == 22050)
                verify(unwrap_or(wav_size(wav), 0u) == 17640u && SDLTestLiveWavs() == 1)
                is_ok(stream |> queue_wav(wav))

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_2)
            verify(SDLTestLiveWavs() == 0, "WAV survived its scope")
            verify(unwrap_or(queued_audio(stream), -1) == 17640)
            is_ok(stream |> flush_audio())
            verify(unwrap_or(available_audio(stream), -1) == 17640)
            var bytes : array<uint8>
            verify(unwrap_or(read_audio(stream, bytes), -1) == 0)
            is_ok(stream |> put_audio(bytes))
            verify(unwrap_or(queued_audio(stream), -1) == 17640)
            bytes |> resize(17640)
            verify(unwrap_or(read_audio(stream, bytes), -1) == 17640)
            verify(SDLTestMatchesWav(path, bytes), "queued WAV did not retain an independent copy")
            verify(unwrap_or(available_audio(stream), -1) == 0 && unwrap_or(queued_audio(stream), -1) == 0)
            is_ok(stream |> put_audio(bytes))
            bytes[0] = uint8(99)
            is_ok(stream |> flush_audio())
            verify(unwrap_or(read_audio(stream, bytes), -1) == 17640)
            verify(SDLTestMatchesWav(path, bytes), "put_audio retained script array memory")
            is_ok(stream |> put_audio(bytes))
            var small : array<uint8>
            small |> resize(4)
            verify(unwrap_or(read_audio(stream, small), -1) == 4)
            verify(unwrap_or(available_audio(stream), -1) == 17636, "read_audio ignored buffer capacity")
            is_ok(stream |> clear_audio())
            verify(unwrap_or(queued_audio(stream), -1) == 0 && unwrap_or(available_audio(stream), -1) == 0)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_1)
        // Conversion from PCM16 mono 22050 Hz to float stereo 44100 Hz.
        let dst = audio_spec(SDL_AUDIO_F32, 2, 44100)
        let scope_ok_3 = with_audio_stream(src, dst) $(stream : SDL_AudioStream?) {
            let scope_ok_4 = with_wav(path) $(wav : SDL_Wav?) { is_ok(stream |> queue_wav(wav))
                return sdl_ok()
            } |> is_ok
            verify(scope_ok_4)
            is_ok(stream |> flush_audio())
            let size = unwrap_or(available_audio(stream), -1)
            verify(size == 141120, "resampled frame count mismatch")
            var bytes : array<uint8>
            bytes |> resize(size)
            verify(unwrap_or(read_audio(stream, bytes), -1) == size)
            verify(SDLTestStereoFloatSignal(bytes), "invalid resampled stereo signal")

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_3)
        // Recover before SDL_Quit, observe actual stream cleanup and WAV ownership.
        for (mode in range(4)) {
            let before = SDLTestDestroyedAudioStreams()
            var caught = false
            var error = ""
            {
                let scope_ok_5 = with_wav(path) $(wav : SDL_Wav?) {
                    let scope_ok_6 = with_audio_stream(src, src) $(stream : SDL_AudioStream?) {
                        verify(SDLTestWatchAudio(stream))
                        if (mode == 1) { return sdl_ok() }
                        if (mode == 2) { caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok() }
                        if (mode == 3) {
                            let scope_ok_7 = with_audio_stream(dst, dst) $(wrong : SDL_AudioStream?) { caught = !(is_ok(wrong |> queue_wav(wav)))
                                return sdl_ok()
                            } |> is_ok
                            verify(scope_ok_7)
                        }
                        is_ok(stream |> queue_wav(wav))

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_6)
                    verify(SDLTestDestroyedAudioStreams() == before + 1)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_5)
            }
            verify(caught == (mode >= 2))

            verify(SDLTestLiveWavs() == 0 && SDLTestDestroyedAudioStreams() == before + 1)
        }
        var entered = false
        var caught = false
        { let operation_ok = with_wav("{path}.missing") $(wav : SDL_Wav?) { entered = true
            return sdl_ok()
        } |> is_ok
caught = !operation_ok }
        verify(caught && !entered && SDLTestLiveWavs() == 0)
        caught = false
        { let operation_ok = with_wav("{SDL_GetBasePath()}assets/checker.bmp") $(wav : SDL_Wav?) { entered = true
            return sdl_ok()
        } |> is_ok
caught = !operation_ok }
        verify(caught && !entered && SDLTestLiveWavs() == 0, "invalid WAV accepted")
        caught = false
        {
            let scope_ok_8 = with_wav(path) $(wav : SDL_Wav?) {
                let invalid = audio_spec(0u, 0, 0)
                let acquired = with_audio_stream(invalid, src) $(stream : SDL_AudioStream?) { entered = true
                    return sdl_ok()
                } |> is_ok
                caught = !acquired

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_8)
        }
        verify(caught && !entered && SDLTestLiveWavs() == 0)
        // Device path: CTest selects the dummy backend, so no speakers are needed.
        var device = 0u
        let before = SDLTestDestroyedAudioStreams()
        let scope_ok_9 = with_playback(src) $(stream : SDL_AudioStream?) {
            verify(SDLTestWatchAudio(stream))
            device = SDL_GetAudioStreamDevice(stream)
            verify(device != 0u && SDL_AudioStreamDevicePaused(stream))
            let scope_ok_10 = with_wav(path) $(wav : SDL_Wav?) { is_ok(stream |> queue_wav(wav))
                return sdl_ok()
            } |> is_ok
            verify(scope_ok_10)
            is_ok(stream |> flush_audio())
            is_ok(stream |> resume_audio())
            let start = SDL_GetTicks()
            while (unwrap_or(queued_audio(stream), -1) > 0 || unwrap_or(available_audio(stream), -1) > 0) {
                verify(SDL_GetTicks() - start < 5000ul, "dummy audio did not drain")
                SDL_Delay(10u)
            }
            is_ok(stream |> pause_audio())
            verify(SDL_AudioStreamDevicePaused(stream))

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_9)
        verify(SDLTestDestroyedAudioStreams() == before + 1 && SDLTestDeviceClosed(device))
        verify(SDLTestLiveWavs() == 0 && SDL_WasInit(SDL_INIT_AUDIO) != 0u)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    verify(SDL_WasInit(SDL_INIT_AUDIO) == 0u)
    print("Audio: PCM copies, conversion, queues, scope errors and dummy device cleanup: OK\n")
    return 0
}
