options gen2
module sdl3_result shared public
require sdl3 public
require daslib/result public

struct SdlError {
    operation : string
    message : string
}
// Unit carries no success flag: that belongs to the standard Result container.
// One storage byte keeps Option<Unit> layout identical in interpreter and C++ AOT.
// This is padding, not an additional success flag.
struct SdlUnit {
    _storage : uint8
}

def public sdl_ok() { return ok(SdlUnit(), type<SdlError>) }
// Call only after an SDL return value established failure, before any cleanup.
def public sdl_error(operation : string) : SdlError {
    return SdlError(operation = operation, message = SDL_GetErrorCopy())
}

// Only for SDL contracts where false explicitly denotes failure.
def public sdl_status(success : bool; operation : string) {
    if (!success) { return err(sdl_error(operation), type<SdlUnit>) }
    return sdl_ok()
}
