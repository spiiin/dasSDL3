options gen2
require daslib/defer
module sdl3_properties_boost shared public
require dassdl3/sdl3_boost public

// Only groups created here are owned. Global/object property IDs are borrowed.
def public with_properties(blk : block<(props : uint) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let props = SDL_CreateProperties()
    if (props == 0u) { return err(sdl_error("with_properties"), type<TT>) }
    { defer() { SDL_DestroyProperties(props) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(props) } else { scope_result <- blk(props) } }

    return <- scope_result
}
def public with_properties_lock(props : uint; blk : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    if (!SDL_LockProperties(props)) { return err(sdl_error("with_properties_lock"), type<TT>) }
    { defer() { SDL_UnlockProperties(props) }; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk() } else { scope_result <- blk() } }

    return <- scope_result
}
def public property_string(props : uint; name : string; fallback : string = "") {
    var value : string
    if (!SDL_GetPropertyStringValue(props, name, fallback, value)) {return err(sdl_error("property_string"), type<string>)}
    return ok(value, type<SdlError>)
}
def public property_names(props : uint; var names : array<string>) {
    return sdl_status(SDL_GetPropertyNamesCopy(props, names), "property_names")
}

def public property_names(props : uint) {
    var names : array<string>
    let status = property_names(props, names)
    if (is_err(status)) { return err(unwrap_err(status), type<array<string>>) }
    var value <- names
    return <- move_ok(value, type<SdlError>)
}
