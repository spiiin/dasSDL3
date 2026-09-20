options gen2
require daslib/defer
module sdl3_properties_boost shared public
require dassdl3/sdl3_boost public

// Only groups created here are owned. Global/object property IDs are borrowed.
def public with_properties(blk : block<(props : uint) : void>) : bool {
    let props=SDL_CreateProperties()
    if(props==0u) { return false }
    { defer() { SDL_DestroyProperties(props) }; blk(props); return true }
}
def public with_properties_lock(props : uint; blk : block<() : void>) : bool {
    if(!SDL_LockProperties(props)) { return false }
    { defer() { SDL_UnlockProperties(props) }; blk(); return true }
}
def public property_string(props : uint; name : string; fallback : string="") : string {
    return SDL_GetStringPropertyCopy(props,name,fallback)
}
def public property_names(props : uint; var names : array<string>) : bool {
    return SDL_GetPropertyNamesCopy(props,names)
}
