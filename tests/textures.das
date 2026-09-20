options gen2
require dassdl3/sdl3_boost
require daslib/rtti
require daslib/strings_boost

[export]
def main(smoke : bool) : int {
    verify(smoke)
    let path = "{SDL_GetBasePath()}assets/checker.bmp"
    let scope_ok_0 = with_sdl() {
        let scope_ok_1 = with_window("texture tests", 128, 128, SDL_WINDOW_HIDDEN) $(window) {
            let scope_ok_2 = window |> with_renderer() $(renderer) {
                // Surface destruction is observed before renderer / SDL cleanup.
                for (mode in range(4)) {
                    SDLTestReset()
                    var caught = false
                    var error = ""
                    {
                        let scope_ok_3 = with_bmp(path) $(surface) {
                            verify(SDLTestWatchSurface(surface))
                            if (mode == 1) { return }
                            if (mode == 2) { caught = !set_title(null,"expected SDL failure"); return }
                            if (mode == 3) { caught = create_texture(null, surface) == null; return }
                            var texture = create_texture(renderer, surface)
                            destroy_texture(texture)
                        }
                        verify(scope_ok_3)
                    }
                    verify(caught == (mode >= 2))
                    verify(SDLTestCleanupTrace() == 1, "surface not destroyed exactly once")

                    if (SDL_GetRenderer(window) != renderer) { panic("renderer changed after surface mode {mode}") }
                    renderer |> clear()
                }
                for (mode in range(3)) {
                    SDLTestReset()
                    var caught = false
                    var error = ""
                    {
                        let scope_ok_4 = renderer |> with_texture(path) $(texture) {
                            verify(SDLTestWatchTexture(texture))
                            var query_result_1 : float2
                            verify(texture_size(texture,query_result_1))
                            let size = query_result_1
                            verify(size.x == 128.0 && size.y == 128.0)
                            renderer |> clear()
                            renderer |> draw_texture(texture)
                            verify(SDLTestCheckCorner(renderer), "whole texture pixel mismatch")
                            let rect = SDL_MakeFRect(0.0, 0.0, 128.0, 128.0)
                            renderer |> clear()
                            renderer |> draw_texture(texture, rect)
                            verify(SDLTestCheckCorner(renderer), "destination rect pixel mismatch")
                            let crop = SDL_MakeFRect(0.0, 0.0, 64.0, 64.0)
                            renderer |> clear()
                            renderer |> draw_texture(texture, crop, rect)
                            verify(SDLTestCheckCorner(renderer), "source crop pixel mismatch")
                            renderer |> present()
                            if (mode == 1) { return }
                            if (mode == 2) { caught = !set_title(null,"expected SDL failure"); return }
                        }
                        verify(scope_ok_4)
                    }
                    if (caught && mode != 2) { panic("texture mode {mode}: {error}") }
                    verify(caught == (mode == 2))
                    verify(SDLTestCleanupTrace() == 2, "texture survived its scope")
                    verify(SDL_GetRenderer(window) != null, "renderer destroyed before texture")

                }
                var called = false
                var caught = false
                { let operation_ok = renderer |> with_texture("{path}.missing") $(texture) { called = true }
caught = !operation_ok }
                verify(caught && !called, "missing BMP invoked callback")
                // A failed operation must leave the renderer usable.
                renderer |> clear()
                renderer |> present()
            }
            verify(scope_ok_2)
        }
        verify(scope_ok_1)
    }
    verify(scope_ok_0)
    verify(SDL_WasInit(SDL_INIT_VIDEO) == 0u)
    print("Textures: pixels, sizes, scopes, early return, errors and load failure: OK\n")
    return 0
}
