options gen2
require dassdl3/sdl3_boost
require daslib/rtti
require daslib/strings_boost

[export]
def main(smoke : bool) : int {
    verify(smoke)
    let path = "{SDL_GetBasePath()}assets/checker.bmp"
    with_sdl() {
        with_window("texture tests", 128, 128, SDL_WINDOW_HIDDEN) $(window) {
            window |> with_renderer() $(renderer) {
                // Surface destruction is observed before renderer / SDL cleanup.
                for (mode in range(4)) {
                    SDLTestReset()
                    var caught = false
                    var error = ""
                    try {
                        with_bmp(path) $(surface) {
                            verify(SDLTestWatchSurface(surface))
                            if (mode == 1) { return }
                            if (mode == 2) { panic("surface panic") }
                            if (mode == 3) { create_texture(null, surface) }
                            var texture = create_texture(renderer, surface)
                            destroy_texture(texture)
                        }
                    } recover {
                        caught = true
                        error := rtrim(this_context().last_exception)
                    }
                    verify(caught == (mode >= 2))
                    verify(SDLTestCleanupTrace() == 1, "surface not destroyed exactly once")
                    if (mode == 2) { verify(error == "surface panic") }
                    if (SDL_GetRenderer(window) != renderer) { panic("renderer changed after surface mode {mode}") }
                    renderer |> clear()
                }
                for (mode in range(3)) {
                    SDLTestReset()
                    var caught = false
                    var error = ""
                    try {
                        renderer |> with_texture(path) $(texture) {
                            verify(SDLTestWatchTexture(texture))
                            let size = texture_size(texture)
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
                            if (mode == 2) { panic("texture panic") }
                        }
                    } recover {
                        caught = true
                        error := rtrim(this_context().last_exception)
                    }
                    if (caught && mode != 2) { panic("texture mode {mode}: {error}") }
                    verify(caught == (mode == 2))
                    verify(SDLTestCleanupTrace() == 2, "texture survived its scope")
                    verify(SDL_GetRenderer(window) != null, "renderer destroyed before texture")
                    if (mode == 2) { verify(error == "texture panic") }
                }
                var called = false
                var caught = false
                try {
                    renderer |> with_texture("{path}.missing") $(texture) { called = true }
                } recover { caught = true }
                verify(caught && !called, "missing BMP invoked callback")
                // A failed operation must leave the renderer usable.
                renderer |> clear()
                renderer |> present()
            }
        }
    }
    verify(SDL_WasInit(SDL_INIT_VIDEO) == 0u)
    print("Textures: pixels, sizes, scopes, early return, panic and load failure: OK\n")
    return 0
}
