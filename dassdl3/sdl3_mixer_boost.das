options gen2
module sdl3_mixer_boost shared public
require sdl3_mixer public
require dassdl3/sdl3_result public
require daslib/defer

// All scopes lend their resource. Bodies must not retain/destroy borrowed owners.
def public with_mixer_system(blk : block<() : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    if (!MIX_Init()) { return err(sdl_error("MIX_Init"), type<MixValue>) }
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_Quit() }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk() }
        else { result <- blk() }
    }
    return <- result
}

def public create_mixer(spec : SDL_AudioSpec) {
    var value = MIX_CreateMixerRef(spec)
    if (value == null) { return err(sdl_error("MIX_CreateMixerRef"), type<MIX_Mixer?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mixer(spec : SDL_AudioSpec; blk : block<(value : MIX_Mixer?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mixer(spec)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyMixer(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mixer_device(device : uint; spec : SDL_AudioSpec) {
    var value = MIX_CreateMixerDeviceRef(device, spec)
    if (value == null) { return err(sdl_error("MIX_CreateMixerDeviceRef"), type<MIX_Mixer?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mixer_device(device : uint; spec : SDL_AudioSpec; blk : block<(value : MIX_Mixer?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mixer_device(device, spec)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyMixer(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mix_audio(mixer : MIX_Mixer?; path : string; predecode : bool) {
    var value = MIX_LoadAudio(mixer, path, predecode)
    if (value == null) { return err(sdl_error("MIX_LoadAudio"), type<MIX_Audio?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mix_audio(mixer : MIX_Mixer?; path : string; predecode : bool; blk : block<(value : MIX_Audio?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mix_audio(mixer, path, predecode)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyAudio(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mix_audio_io(mixer : MIX_Mixer?; io : SDL_IOStream?; predecode : bool) {
    var value = MIX_LoadAudio_IO(mixer, io, predecode, false)
    if (value == null) { return err(sdl_error("MIX_LoadAudio_IO"), type<MIX_Audio?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mix_audio_io(mixer : MIX_Mixer?; io : SDL_IOStream?; predecode : bool; blk : block<(value : MIX_Audio?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mix_audio_io(mixer, io, predecode)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyAudio(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mix_raw_audio(mixer : MIX_Mixer?; samples : array<float>; channels, frequency : int) {
    var value = MIX_LoadRawAudioFloats(mixer, samples, channels, frequency)
    if (value == null) { return err(sdl_error("MIX_LoadRawAudioFloats"), type<MIX_Audio?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mix_raw_audio(mixer : MIX_Mixer?; samples : array<float>; channels, frequency : int; blk : block<(value : MIX_Audio?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mix_raw_audio(mixer, samples, channels, frequency)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyAudio(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mix_sine_audio(mixer : MIX_Mixer?; hz : int; amplitude : float; milliseconds : int64) {
    var value = MIX_CreateSineWaveAudio(mixer, hz, amplitude, milliseconds)
    if (value == null) { return err(sdl_error("MIX_CreateSineWaveAudio"), type<MIX_Audio?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mix_sine_audio(mixer : MIX_Mixer?; hz : int; amplitude : float; milliseconds : int64; blk : block<(value : MIX_Audio?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mix_sine_audio(mixer, hz, amplitude, milliseconds)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyAudio(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mix_track(mixer : MIX_Mixer?) {
    var value = MIX_CreateTrack(mixer)
    if (value == null) { return err(sdl_error("MIX_CreateTrack"), type<MIX_Track?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mix_track(mixer : MIX_Mixer?; blk : block<(value : MIX_Track?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mix_track(mixer)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyTrack(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mix_group(mixer : MIX_Mixer?) {
    var value = MIX_CreateGroup(mixer)
    if (value == null) { return err(sdl_error("MIX_CreateGroup"), type<MIX_Group?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mix_group(mixer : MIX_Mixer?; blk : block<(value : MIX_Group?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mix_group(mixer)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyGroup(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_mix_decoder(path : string; props : uint) {
    var value = MIX_CreateAudioDecoder(path, props)
    if (value == null) { return err(sdl_error("MIX_CreateAudioDecoder"), type<MIX_AudioDecoder?>) }
    return <- move_ok(value, type<SdlError>)
}
def public with_mix_decoder(path : string; props : uint; blk : block<(value : MIX_AudioDecoder?) : $Result<auto(MixValue); SdlError>>) : $Result<MixValue; SdlError> {
    var loaded = create_mix_decoder(path, props)
    if (is_err(loaded)) { return err(unwrap_err(loaded), type<MixValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<MixValue; SdlError>
    {
        defer() { MIX_DestroyAudioDecoder(value) }
        static_if (typeinfo can_copy(type<$Result<MixValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public mix_format(mixer : MIX_Mixer?) {
    var value : SDL_AudioSpec
    if (!MIX_GetMixerFormatRef(mixer, value)) { return err(sdl_error("MIX_GetMixerFormatRef"), type<SDL_AudioSpec>) }
    return ok(value, type<SdlError>)
}

def public mix_audio_format(audio : MIX_Audio?) {
    var value : SDL_AudioSpec
    if (!MIX_GetAudioFormatRef(audio, value)) { return err(sdl_error("MIX_GetAudioFormatRef"), type<SDL_AudioSpec>) }
    return ok(value, type<SdlError>)
}

def public mix_decoder_format(decoder : MIX_AudioDecoder?) {
    var value : SDL_AudioSpec
    if (!MIX_GetAudioDecoderFormatRef(decoder, value)) { return err(sdl_error("MIX_GetAudioDecoderFormatRef"), type<SDL_AudioSpec>) }
    return ok(value, type<SdlError>)
}

def public mix_track_position(track : MIX_Track?) {
    var value : MIX_Point3D
    if (!MIX_GetTrack3DPositionRef(track, value)) { return err(sdl_error("MIX_GetTrack3DPositionRef"), type<MIX_Point3D>) }
    return ok(value, type<SdlError>)
}

def public set_mix_audio(track : MIX_Track?; audio : MIX_Audio?) { return sdl_status(MIX_SetTrackAudio(track, audio), "MIX_SetTrackAudio") }

def public play_mix_track(track : MIX_Track?; props : uint = 0u) { return sdl_status(MIX_PlayTrack(track, props), "MIX_PlayTrack") }

def public stop_mix_track(track : MIX_Track?; fade_frames : int64 = 0l) { return sdl_status(MIX_StopTrack(track, fade_frames), "MIX_StopTrack") }

def public pause_mix_track(track : MIX_Track?) { return sdl_status(MIX_PauseTrack(track), "MIX_PauseTrack") }

def public resume_mix_track(track : MIX_Track?) { return sdl_status(MIX_ResumeTrack(track), "MIX_ResumeTrack") }

def public set_mix_gain(track : MIX_Track?; gain : float) { return sdl_status(MIX_SetTrackGain(track, gain), "MIX_SetTrackGain") }

def public seek_mix_track(track : MIX_Track?; frames : int64) { return sdl_status(MIX_SetTrackPlaybackPosition(track, frames), "MIX_SetTrackPlaybackPosition") }

def public generate_mix_audio(mixer : MIX_Mixer?; var bytes : array<uint8>) {
    let count = MIX_GenerateBytes(mixer, bytes)
    if (count < 0) { return err(sdl_error("MIX_GenerateBytes"), type<int>) }
    return ok(count, type<SdlError>)
}

def public generate_mix_audio(mixer : MIX_Mixer?; var samples : array<float>) {
    let count = MIX_GenerateFloats(mixer, samples)
    if (count < 0) { return err(sdl_error("MIX_GenerateFloats"), type<int>) }
    return ok(count, type<SdlError>)
}

def public decode_mix_audio(decoder : MIX_AudioDecoder?; var bytes : array<uint8>; spec : SDL_AudioSpec) {
    let count = MIX_DecodeAudioBytes(decoder, bytes, spec)
    if (count < 0) { return err(sdl_error("MIX_DecodeAudioBytes"), type<int>) }
    return ok(count, type<SdlError>)
}
