options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_init_boost
require daslib/defer

def counted(var calls : int&; fail : bool) {
    calls++
    if (fail) { return err(SdlError(operation="counted", message="original"), type<int>) }
    return ok(42, type<SdlError>)
}

def propagate(var calls, cleanup : int&; fail : bool) : $Result<SdlUnit; SdlError> {
    defer() {
        cleanup++
        SDL_SetErrorText("cleanup overwrote SDL error")
    }
    let v = counted(calls, fail) |> sdl_try
    verify(v == 42)
    sdl_ok() |> sdl_try
    return sdl_ok()
}

def values {
    let constant = ok(7, type<SdlError>)
    let v = constant |> sdl_try
    var text = ok("owned string", type<SdlError>) |> sdl_try
    var input : array<int>
    push(input, v)
    var result <- move_ok(input, type<SdlError>)
    let extracted <- result |> sdl_try
    verify(length(result._value) == 0)
    verify(length(extracted) == 1 && extracted[0] == 7 && text == "owned string")
    let optional = ok(none(type<int>), type<SdlError>) |> sdl_try
    verify(is_none(optional))
    let pending = ok(false, type<SdlError>) |> sdl_try
    verify(!pending)
    return sdl_ok()
}

def array_failure : $Result<array<int>; SdlError> {
    err(SdlError(operation="array", message="failure"), type<float2>) |> sdl_try
    var empty : array<int>
    return <- move_ok(empty, type<SdlError>)
}

def branch_loop(var calls : int&) {
    if (false) { counted(calls, true) |> sdl_try }
    for (i in range(3)) {
        let value = counted(calls, i == 1) |> sdl_try
        verify(value == 42)
    }
    return sdl_ok()
}

def nested(var reached : bool&) {
    let inner = with_sdl(SDL_INIT_VIDEO) {
        return with_window("sdl_try cleanup", 8, 8, SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            var borrowed = SDL_GetWindowFromID(SDL_GetWindowID(window))
            let ptr = move_ok(borrowed, type<SdlError>) |> sdl_try
            verify(ptr == window)
            set_title(window, "updated") |> sdl_try
            texture_size(null) |> sdl_try
            verify(false)
            return ok(123, type<SdlError>)
        }
    }
    reached = true
    verify(is_err(inner) && unwrap_err(inner).operation == "texture_size")
    verify(SDL_WasInit(0u) == 0u)
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    var calls = 0
    var cleanup = 0
    let failed = propagate(calls, cleanup, true)
    verify(is_err(failed) && calls == 1 && cleanup == 1)
    verify(unwrap_err(failed).operation == "counted" && unwrap_err(failed).message == "original")
    let passed = propagate(calls, cleanup, false)
    verify(is_ok(passed) && calls == 2 && cleanup == 2)
    verify(is_ok(values()))
    var array_error <- array_failure()
    verify(is_err(array_error) && unwrap_err(array_error).operation == "array")
    calls = 0
    verify(is_err(branch_loop(calls)) && calls == 2)
    var reached = false
    verify(is_ok(nested(reached)) && reached)
    print("sdl_try: values, moves, once-only evaluation, early returns and cleanup passed\n")
    return 0
}
