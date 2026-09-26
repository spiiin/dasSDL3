options gen2
require daslib/defer
module sdl3_init_boost shared public
require dassdl3/sdl3_boost public

// Balances exactly one successful SDL subsystem acquisition.
// The callback must not consume this reference via Quit/QuitSubSystem.
def public with_sdl_subsystems(flags : uint; blk : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    if (!SDL_InitSubSystem(flags)) { return err(sdl_error("with_sdl_subsystems"), type<TT>) }
    { defer() { SDL_QuitSubSystem(flags) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk() } else { scope_result <- blk() } }

    return <- scope_result
}
def public hint_string(name : string) {
    var value : string
    if (!SDL_GetHintOptionalCopy(name, value)) { return none(type<string>) }
    return some(value)
}
def public app_metadata_string(name : string) {
    var value : string
    let state = SDL_GetAppMetadataOptionalCopy(name, value)
    if (state < 0) {return err(sdl_error("SDL_GetAppMetadataProperty"), type<$Option<string> >)}
    return ok(state == 0 ? none(type<string>) : some(value), type<SdlError>)
}
