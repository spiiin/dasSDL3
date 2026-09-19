options gen2
require dassdl3/sdl3_pixels_boost
require daslib/rtti
require daslib/strings_boost

[export]
def main(smoke : bool) : int {
    verify(smoke)
    verify(rgba8_buffer_size(3, 2, 16) == 28)
    verify(SDL_RGBA8BufferSize(0, 2, 16) == -1)
    verify(SDL_RGBA8BufferSize(3, -1, 16) == -1)
    verify(SDL_RGBA8BufferSize(3, 2, -1) == -1)
    verify(SDL_RGBA8BufferSize(3, 2, 11) == -1)
    verify(SDL_RGBA8BufferSize(2147483647, 1, 16) == -1)
    verify(SDL_RGBA8BufferSize(1, 2147483647, 2147483647) == -1)
    with_sdl() {
        with_window("pixels contracts", 64, 64, SDL_WINDOW_HIDDEN) $(window) {
            window |> with_renderer() $(renderer) {
                renderer |> with_target_texture(3, 2) $(outer) {
                    renderer |> with_render_target(outer) {
                        for (mode in 0 .. 3) {
                            SDLTestReset()
                            var caught = false
                            var error = ""
                            var copy : array<uint8>
                            copy |> resize(36)
                            for (i in 0 .. length(copy)) { copy[i] = uint8(201) }
                            try {
                                renderer |> with_target_texture(3, 2) $(target) {
                                    verify(SDLTestWatchTexture(target))
                                    renderer |> with_render_target(target) {
                                        renderer |> with_streaming_texture(3, 2) $(streaming) {
                                            var bytes : array<uint8>
                                            verify(!SDL_UploadRGBA8(streaming, bytes, 16))
                                            bytes |> resize(28)
                                            for (pixel in 0 .. 6) {
                                                let x = pixel % 3
                                                let y = pixel / 3
                                                let i = y * 16 + x * 4
                                                bytes[i] = uint8(10 + x * 50)
                                                bytes[i+1] = uint8(20 + y * 60)
                                                bytes[i+2] = uint8(30)
                                                bytes[i+3] = uint8(255)
                                            }
                                            verify(!SDL_UploadRGBA8(streaming, bytes, 11))
                                            verify(!SDL_UploadRGBA8(streaming, bytes, 17))
                                            verify(!SDL_UploadRGBA8(target, bytes, 16))
                                            streaming |> upload_rgba8(bytes, 16)
                                            // Repeat lock/unlock, then mutate the source before rendering.
                                            streaming |> upload_rgba8(bytes, 16)
                                            for (i in 0 .. length(bytes)) { bytes[i] = uint8(0) }
                                            renderer |> clear(uint4(0u, 0u, 0u, 255u))
                                            renderer |> draw_texture(streaming)
                                        }
                                        renderer |> with_read_pixels() $(surface) {
                                            verify(SDLTestWatchSurface(surface))
                                            verify(surface_size(surface) == int2(3, 2))
                                            var short_copy : array<uint8>
                                            short_copy |> resize(1)
                                            short_copy[0] = uint8(99)
                                            verify(!SDL_CopySurfaceRGBA8(surface, short_copy, 20))
                                            verify(short_copy[0] == uint8(99))
                                            surface |> copy_surface_rgba8(copy, 20)
                                            if (mode == 1) { return }
                                            if (mode == 2) { panic("pixels panic") }
                                        }
                                        verify(SDLTestCleanupTrace() == 1, "readback surface leaked")
                                        if (mode == 1) { return }
                                    }
                                    verify(SDL_GetRenderTarget(renderer) == outer)
                                    if (mode == 1) { return }
                                }
                            } recover {
                                caught = true
                                error := rtrim(this_context().last_exception)
                            }
                            if (caught && mode != 2) { panic(error) }
                            verify(caught == (mode == 2))
                            if (caught) { verify(error == "pixels panic", "panic message changed") }
                            verify(SDL_GetRenderTarget(renderer) == outer, "previous target not restored")
                            verify(SDLTestCleanupTrace() == 12, "surface/texture destruction order")
                            for (pixel in 0 .. 6) {
                                let x = pixel % 3
                                let y = pixel / 3
                                let i = y * 20 + x * 4
                                verify(copy[i] == uint8(10 + x * 50))
                                verify(copy[i+1] == uint8(20 + y * 60))
                                verify(copy[i+2] == uint8(30) && copy[i+3] == uint8(255))
                            }
                            for (i in 12 .. 20) { verify(copy[i] == uint8(201), "padding overwritten") }
                            var called = false
                            renderer |> with_streaming_texture(3, 2) $(streaming) {
                                var rejected = false
                                try { renderer |> with_render_target(streaming) { called = true } } recover { rejected = true }
                                verify(rejected && !called)
                            }
                            verify(SDL_GetRenderTarget(renderer) == outer)
                            renderer |> clear()
                        }
                    }
                    verify(SDL_GetRenderTarget(renderer) == null)
                }
                renderer |> clear()
                renderer |> present()
            }
        }
    }
    print("Pixels: pitched RGBA copies, readback, nested targets and panic cleanup OK\n")
    return 0
}
