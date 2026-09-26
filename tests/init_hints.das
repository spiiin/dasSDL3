options gen2
require dassdl3/sdl3_init_boost
[export]
def main(smoke : bool) : int {
    let key = "DASSDL3_TEST_PRIVATE_HINT"
    verify(SDL_SetAppMetadata("dasSDL3 test", "1.0", "org.dassdl3.test"))
    verify(SDL_GetAppMetadataProperty("SDL.app.metadata.name") == "dasSDL3 test")
    verify(SDL_SetAppMetadataProperty("SDL.app.metadata.creator", "Автор"))
    let saved = unwrap_or(unwrap_or(app_metadata_string("SDL.app.metadata.creator"), none(type<string>)), "")
    verify(SDL_ClearAppMetadataProperty("SDL.app.metadata.creator"))
    verify(saved == "Автор")
    verify(!SDL_SetAppMetadataProperty("not.a.metadata.key", "value"))
    verify(SDL_Init(0u))
    verify(SDL_IsMainThread())
    verify(!SDL_ResetHint(key))
    verify(SDL_GetHintBoolean(key, true))
    verify(SDL_SetHintWithPriority(key, "Привет", SDL_HintPriority.HINT_DEFAULT))
    let copy = unwrap_or(hint_string(key), "")
    verify(SDL_SetHint(key, "true"))
    verify(SDL_GetHint(key) == "true" && SDL_GetHintBoolean(key, false))
    verify(!SDL_SetHintWithPriority(key, "false", SDL_HintPriority.HINT_DEFAULT))
    verify(SDL_SetHintWithPriority(key, "false", SDL_HintPriority.HINT_OVERRIDE))
    verify(!SDL_SetHint(key, "true") && !SDL_GetHintBoolean(key, true))
    verify(copy == "Привет")
    verify(SDL_ResetHint(key))
    verify(SDL_SetHint(key, "1"))
    SDL_ResetHints()
    verify(!SDL_GetHintBoolean(key, false))
    verify(SDL_WasInit(SDL_INIT_EVENTS) == 0u)
    verify(SDL_InitSubSystem(SDL_INIT_EVENTS))
    let nested = with_sdl_subsystems(SDL_INIT_EVENTS) {
        verify(SDL_WasInit(SDL_INIT_EVENTS) == SDL_INIT_EVENTS)
        return sdl_ok()
    } |> is_ok
    verify(nested && SDL_WasInit(SDL_INIT_EVENTS) == SDL_INIT_EVENTS)
    SDL_QuitSubSystem(SDL_INIT_EVENTS)
    verify(SDL_WasInit(SDL_INIT_EVENTS) == 0u)
    verify(SDL_SetHintWithPriority("SDL_AUDIO_DRIVER", "dassdl3_missing_driver", SDL_HintPriority.HINT_OVERRIDE))
    var called = false
    let failed = with_sdl_subsystems(SDL_INIT_EVENTS | SDL_INIT_AUDIO) { called = true
        return sdl_ok()
    } |> is_ok
    verify(!failed && !called && SDL_WasInit(0u) == 0u)
    verify(SDL_ResetHint("SDL_AUDIO_DRIVER"))
    SDL_Quit()
    return 0
}
