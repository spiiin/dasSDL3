options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_boost
require dassdl3/sdl3_pixels_boost
require daslib/defer

def with_number(id : int; fail : int; var trace : string&;
        blk : block<(number : int) : $Result<auto(T); SdlError>>) {
    trace += "acquire{id};"
    if (id == fail) { return err(SdlError(operation="acquire",message="{id}"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { trace += "release{id};" }
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) { result = blk(id) }
        else { result <- blk(id) }
    }
    return <- result
}

def run(fail : int; body_error : bool; var trace : string&) : $Result<int; SdlError> {
    return sdl_scope() {
        let first : int = with_number(1,fail,trace) |> sdl_use
        trace += "between;"
        let second : int = with_number(first+1,fail,trace) |> sdl_use
        let third : int = sdl_use(with_number(second+1,fail,trace))
        trace += "body;"
        if (body_error) { return err(SdlError(operation="body",message="early"),type<int>) }
        return ok(first+second+third,type<SdlError>)
    }
}

def with_mutable(blk : block<(var value : int&) : $Result<auto(T); SdlError>>) {
    var value = 7
    var result = blk(value)
    verify(value == 9)
    return <- result
}

def moving(var trace : string&) {
    return <- sdl_scope() {
        let first : int = sdl_use(with_number(1,0,trace))
        let second : int = sdl_use(with_number(2,0,trace))
        var values <- array<int>(first,second)
        return <- move_ok(values,type<SdlError>)
    }
}

[export]
def main(smoke : bool) : int {
    var trace = ""
    let good = run(0,false,trace)
    verify(is_ok(good) && unwrap(good) == 6)
    verify(trace == "acquire1;between;acquire2;acquire3;body;release3;release2;release1;")
    trace = ""
    let failed = run(2,false,trace)
    verify(is_err(failed) && unwrap_err(failed).operation == "acquire")
    verify(trace == "acquire1;between;acquire2;release1;")
    trace = ""
    let first_failed = run(1,false,trace)
    verify(is_err(first_failed) && trace == "acquire1;")
    trace = ""
    let early = run(0,true,trace)
    verify(is_err(early) && unwrap_err(early).operation == "body")
    verify(trace == "acquire1;between;acquire2;acquire3;body;release3;release2;release1;")
    trace = ""
    var moved <- moving(trace)
    verify(is_ok(moved) && length(moved._value) == 2 && moved._value[1] == 2)
    verify(trace == "acquire1;acquire2;release2;release1;")
    let mutated = sdl_scope() {
        var value : int& = sdl_use(with_mutable())
        value = 9
        return sdl_ok()
    }
    verify(is_ok(mutated))
    let native = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = sdl_use(with_window("scope",32,32,SDL_WINDOW_HIDDEN))
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        renderer |> clear() |> sdl_try
        return sdl_scope() {
            let texture : SDL_Texture? = sdl_use(renderer |> with_target_texture(8,8))
            let size = texture_size(texture) |> sdl_try
            verify(size == float2(8.0))
            return sdl_ok()
        }
    }
    verify(is_ok(native))
    print("sdl_scope: sequential acquisition, reverse cleanup, partial failure, early return, move and native scopes PASS\n")
    return 0
}
