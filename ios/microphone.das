options gen2
require dassdl3/sdl3_audio_final
require math

var stream : SDL_AudioStream?
var samples : array<float>
var received_samples : int
var peak : float
var denial_deadline : uint64

[export]
def microphone_open(expect_denied : bool) : int {
    let driver = SDL_GetPlatform() == "Android" ? "AAudio" : "coreaudio"
    if (SDL_GetCurrentAudioDriverCopy() != driver) { return -1 }
    let spec = audio_spec(SDL_AUDIO_F32, 1, 24000)
    var opened <- open_audio_device_stream(SDL_AUDIO_DEVICE_DEFAULT_RECORDING, spec)
    if (is_err(opened)) {
        print("SDL_OpenAudioDeviceStream: {unwrap_err(opened).message}\n")
        return expect_denied ? 1 : -1
    }
    stream = move_unwrap(opened)
    let id = SDL_GetAudioStreamDevice(stream)
    if (id == 0u || SDL_IsAudioDevicePlayback(id)) { return -1 }
    if (!SDL_ResumeAudioStreamDevice(stream)) {
        print("SDL_ResumeAudioStreamDevice: {SDL_GetError()}\n")
        return expect_denied ? 1 : -1
    }
    resize(samples, 512)
    if (expect_denied) { denial_deadline = SDL_GetTicks() + 2000ul }
    print("SDL {driver} recording stream opened (mono, 24000 Hz).\n")
    return 0
}

[export]
def microphone_tick(expect_denied : bool) : int {
    var bytes = 0
    unsafe { bytes = SDL_GetAudioStreamData(stream, addr(samples[0]), 2048) }
    if (bytes < 0 || bytes % 4 != 0 || bytes > 2048) {
        print("SDL_GetAudioStreamData: {SDL_GetError()}\n")
        return -1
    }
    let count = bytes / 4
    for (index in range(count)) {
        let magnitude = abs(samples[index])
        if (!(magnitude <= 2.0)) { return -1 }
        peak = max(peak, magnitude)
    }
    received_samples += count
    if (expect_denied) {
        if (peak > 0.0001) {
            print("SDL delivered non-silent samples despite denied microphone access.\n")
            return -1
        }
        if (SDL_GetTicks() < denial_deadline) { return 0 }
    } elif (received_samples < 6000 || peak < 0.015) {
        return 0
    }
    print("SDL microphone samples={received_samples}, peak={peak}\n")
    return 1
}

[export]
def microphone_close() {
    if (stream != null) {
        SDL_DestroyAudioStream(stream)
        stream = null
    }
}
