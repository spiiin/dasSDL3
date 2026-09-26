options gen2
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_scope

def alias_value(fail : bool) : $SdlResult<int> {
    if (fail) { return err(SdlError(operation="alias",message="failed"),type<int>) }
    return ok(42,type<SdlError>)
}
def alias_status(fail : bool) : SdlStatus {
    let value = alias_value(fail) |> sdl_try
    verify(value == 42)
    return sdl_ok()
}
def alias_array : $SdlResult<array<int>> {
    var values <- array(7,9)
    return <- move_ok(values,type<SdlError>)
}

[export]
def main(smoke : bool) : int {
    let canonical : $Result<int; SdlError> = alias_value(false)
    let aliased : $SdlResult<int> = canonical
    verify(unwrap(aliased) == 42)
    verify(is_ok(alias_status(false)))
    let alias_error = alias_status(true)
    verify(is_err(alias_error) && unwrap_err(alias_error).operation == "alias")
    var alias_values <- alias_array()
    var owned_values <- move_unwrap(alias_values)
    verify(length(owned_values) == 2 && owned_values[1] == 9)
    let value = ok(42, type<SdlError>)
    verify(is_ok(value) && unwrap(value) == 42)
    var optional = none(type<SDL_Texture?>)
    var nested : $SdlResult<$Option<SDL_Texture?>> <- move_ok(optional, type<SdlError>)
    verify(is_ok(nested))
    var extracted_option <- move_unwrap(nested)
    verify(is_none(extracted_option))
    var values : array<int>
    push(values, 7)
    var moved <- move_ok(values, type<SdlError>)
    verify(length(values) == 0)
    var extracted <- move_unwrap(moved)
    verify(length(extracted) == 1 && extracted[0] == 7)
    let string_result = ok("owned script string", type<SdlError>)
    verify(is_ok(string_result) && unwrap(string_result) == "owned script string")
    let nested_error = err(SdlError(operation="test", message="nested error"), type<$Option<int> >)
    verify(is_err(nested_error) && unwrap_err(nested_error).message == "nested error")
    let failed = texture_size(null)
    verify(is_err(failed))
    let saved = unwrap_err(failed)
    SDL_SetErrorText("overwritten")
    verify(saved.operation == "texture_size" && saved.message != "" && saved.message != "overwritten")
    let key = "DASSDL3_RESULT_PRIVATE_HINT"
    SDL_ResetHint(key)
    verify(is_none(hint_string(key)))
    verify(SDL_SetHint(key, ""))
    let empty = hint_string(key)
    verify(is_some(empty) && unwrap(empty) == "")
    verify(SDL_SetHint(key, "copied"))
    let text = hint_string(key)
    verify(SDL_ResetHint(key))
    verify(unwrap(text) == "copied")
    let scope = with_sdl(SDL_INIT_VIDEO) {
        return with_window("Result", 32, 32, SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            var pointer = SDL_CreateWindow("pointer", 8, 8, SDL_WINDOW_HIDDEN)
            var pointer_result <- move_ok(pointer, type<SdlError>)
            verify(is_ok(pointer_result))
            var unwrapped_pointer : SDL_Window? = move_unwrap(pointer_result)
            verify(unwrapped_pointer != null)
            SDL_DestroyWindow(unwrapped_pointer)
            var pointer2 = SDL_CreateWindow("nested pointer", 8, 8, SDL_WINDOW_HIDDEN)
            var optional_pointer <- move_some(pointer2)
            var nested_pointer <- move_ok(optional_pointer, type<SdlError>)
            var unwrapped_option <- move_unwrap(nested_pointer)
            verify(is_some(unwrapped_option))
            var extracted_window = move_unwrap(unwrapped_option)
            verify(extracted_window != null)
            SDL_DestroyWindow(extracted_window)
            SDL_SetErrorText("stale error is not failure")
            verify(is_ok(set_title(window, "Updated")))
            return ok(123, type<SdlError>)
        }
    }
    verify(is_ok(scope) && unwrap(scope) == 123 && SDL_WasInit(0u) == 0u)
    var called = false
    let missing = with_bmp("dassdl3-no-such-file.bmp") $(surface : SDL_Surface?) { called = true
        return sdl_ok()
    }
    verify(is_err(missing) && !called)
    let body_error = with_sdl(0u) {
        SDL_SetErrorText("body failed")
        return err(sdl_error("body"), type<int>)
    }
    verify(is_err(body_error) && unwrap_err(body_error).message == "body failed" && SDL_WasInit(0u) == 0u)
    let path = "{SDL_GetBasePath()}assets/checker.bmp"
    let rendering = with_sdl(SDL_INIT_VIDEO) {
        return with_window("Result texture", 32, 32, SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            return with_renderer(window) $(renderer : SDL_Renderer?) {
                for (mode in range(2)) {
                    SDLTestReset()
                    let texture_result = with_texture(renderer, path) $(texture : SDL_Texture?) {
                        verify(SDLTestWatchTexture(texture))
                        let size = texture_size(texture)
                        verify(is_ok(size) && unwrap(size) == float2(128.0, 128.0))
                        verify(is_ok(clear(renderer)))
                        verify(is_ok(draw_texture(renderer, texture)))
                        verify(is_ok(present(renderer)))
                        if (mode == 1) {
                            SDL_SetErrorText("texture body failed")
                            return err(sdl_error("texture body"), type<SdlUnit>)
                        }
                        return sdl_ok()
                    }
                    verify(SDLTestCleanupTrace() == 2)
                    verify(is_err(texture_result) == (mode == 1))
                    if (mode == 1) { verify(unwrap_err(texture_result).message == "texture body failed") }
                }
                return sdl_ok()
            }
        }
    }
    verify(is_ok(rendering))
    SDLTestReset()
    var array_result <- with_bmp(path) $(surface : SDL_Surface?) {
        verify(SDLTestWatchSurface(surface))
        var data : array<int>
        push(data, 99)
        return <- move_ok(data, type<SdlError>)
    }
    verify(SDLTestCleanupTrace() == 1 && is_ok(array_result))
    var data <- move_unwrap(array_result)
    verify(length(data) == 1 && data[0] == 99)
    var failed_scope_called = false
    let invalid_renderer = with_renderer(null) $(renderer : SDL_Renderer?) {
        failed_scope_called = true
        return ok(1, type<SdlError>)
    }
    verify(is_err(invalid_renderer) && !failed_scope_called)
    verify(SDL_SetHintWithPriority("SDL_AUDIO_DRIVER", "dassdl3-no-driver", SDL_HintPriority.HINT_OVERRIDE))
    let invalid_init = with_sdl(SDL_INIT_AUDIO) {
        failed_scope_called = true
        return ok(1, type<SdlError>)
    }
    verify(is_err(invalid_init) && !failed_scope_called && SDL_WasInit(0u) == 0u)
    verify(SDL_ResetHint("SDL_AUDIO_DRIVER"))
    var texture_called = false
    let partial = with_texture(null, path) $(texture : SDL_Texture?) { texture_called = true
        return sdl_ok()
    }
    verify(is_err(partial) && !texture_called)
    verify(unwrap_err(partial).operation == "SDL_CreateTextureFromSurface" && unwrap_err(partial).message != "")
    verify(is_err(set_title(null, "invalid")))
    verify(is_err(clear(null)) && is_err(draw_texture(null, null)) && is_err(present(null)))
    let status = with_sdl(SDL_INIT_VIDEO) {
        let window_status = with_window("status", 16, 16, SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            let renderer_status = with_renderer(window) $(renderer : SDL_Renderer?) {
                let texture_status = with_texture(renderer, path) $(texture : SDL_Texture?) {
                    verify(is_ok(texture_size(texture)))
                    return sdl_ok()
                }
                verify(is_ok(texture_status))

                return sdl_ok()
            }
            verify(is_ok(renderer_status))

            return sdl_ok()
        }
        verify(is_ok(window_status))

        return sdl_ok()
    }
    verify(is_ok(status) && SDL_WasInit(0u) == 0u)
    let unit = with_sdl(0u) { return sdl_ok()
    }
    verify(is_ok(unit))
    return 0
}
