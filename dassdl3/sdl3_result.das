options gen2
options rtti // SdlResult typemacro uses ast_typedecl, including standalone AOT.
module sdl3_result shared public
require sdl3 public
require daslib/result public
require daslib/typemacro_boost


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

// Public spellings of the standard Result; no additional storage or ownership.
typedef public SdlStatus = $Result<SdlUnit; SdlError>

[typemacro_function]
def public SdlResult(macroArgument, passArgument : TypeDeclPtr; T : TypeDeclPtr) : TypeDeclPtr {
    // Start with the canonical Result layout, replacing only its value type.
    var resultType <- typeinfo ast_typedecl(type<$Result<int; SdlError>>)
    resultType.argTypes[1] = clone_type(T)
    return <- resultType
}

def public sdl_ok() : SdlStatus { return ok(SdlUnit(), type<SdlError>) }
// Call only after an SDL return value established failure, before any cleanup.
def public sdl_error(operation : string) : SdlError {
    return SdlError(operation = operation, message = SDL_GetErrorCopy())
}

// Only for SDL contracts where false explicitly denotes failure.
def public sdl_status(success : bool; operation : string) : SdlStatus {
    if (!success) { return err(sdl_error(operation), type<SdlUnit>) }
    return sdl_ok()
}
