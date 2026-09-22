options gen2
require dassdl3/sdl3_surface_pixels_boost
require dassdl3/sdl3_rect_clipboard_boost
require dassdl3/sdl3_renderer_presentation_boost
require dassdl3/sdl3_init_boost
require dassdl3/sdl3_audio_boost
require daslib/defer
require dassdl3/sdl3_diagnostics_boost

[export]
def main(smoke : bool) : int {
    let now=current_time()
    verify(is_ok(now))
    let date=time_to_date(unwrap(now))
    verify(is_ok(date))
    verify(is_ok(date_to_time(unwrap(date))))
    verify(is_err(window_size(null)))
    verify(is_err(display_name(0u)))
    verify(is_err(window_title(null)))
    verify(is_err(renderer_name(null)))
    verify(is_err(render_driver(-1)))
    verify(is_err(app_metadata_string("unknown.property")))
    verify(is_err(wav_spec(null)) && is_err(wav_size(null)))
    verify(is_err(queued_audio(null)))
    let missing=app_metadata_string("SDL.app.metadata.creator")
    verify(is_ok(missing) && is_none(unwrap(missing)))
    let copied=with_sdl(0u) {
        defer() {SDL_SetErrorText("cleanup changed SDL error")}
        SDL_SetErrorText("original failure")
        return err(sdl_error("body"),type<int>)
    }
    verify(is_err(copied) && unwrap_err(copied).message=="original failure")
    verify(SDL_GetErrorCopy()!="original failure")
    let work=with_sdl(SDL_INIT_VIDEO) {
        return with_window("Result contracts",16,16,SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            SDL_SetErrorText("stale")
            verify(is_ok(set_title(window,"")))
            verify(is_ok(window_title(window)) && unwrap(window_title(window))=="")
            verify(unwrap(window_size(window))==int2(16,16))
            var owned_windows <- windows()
            verify(is_ok(owned_windows))
            var handles <- move_unwrap(owned_windows)
            verify(length(handles)==1 && handles[0]==window)
            return with_surface(2,2,SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
                SDL_SetErrorText("stale")
                let absent=surface_color_key(surface)
                verify(is_ok(absent) && is_none(unwrap(absent)))
                verify(SDL_SetSurfaceColorKey(surface,true,0u))
                let zero=surface_color_key(surface)
                verify(is_ok(zero) && is_some(unwrap(zero)) && unwrap(unwrap(zero))==0u)
                var rect = SDL_Rect(x = 8, y = 8, w = 1, h = 1)
                let clipped=set_surface_clip(surface,rect)
                verify(is_ok(clipped) && !unwrap(clipped))
                verify(is_err(set_surface_clip(null,rect)))
                verify(is_ok(reset_surface_clip(surface)))
                verify(SDL_WriteSurfacePixel(surface,0,0,1u,2u,3u,255u))
                verify(unwrap(read_surface_pixel(surface,0,0))==uint4(1u,2u,3u,255u))
                return sdl_ok()
            }
        }
    }
    verify(is_ok(work))
    return 0
}
