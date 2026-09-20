options gen2
require daslib/defer
module sdl3_init_boost shared public
require dassdl3/sdl3_boost public

// Balances exactly one successful SDL subsystem acquisition.
// The callback must not consume this reference via Quit/QuitSubSystem.
def public with_sdl_subsystems(flags : uint; blk : block<() : void>) : bool {
    if(!SDL_InitSubSystem(flags)) { return false }
    { defer() { SDL_QuitSubSystem(flags) }; blk(); return true }
}
def public hint_string(name : string) : string {
    return SDL_GetHintCopy(name)
}
def public app_metadata_string(name : string) : string {
    return SDL_GetAppMetadataPropertyCopy(name)
}
