options gen2
require dassdl3/sdl3_pixels_boost
require daslib/rtti
require daslib/strings_boost

[export]
def main(smoke : bool) : int {
    verify(smoke)
    verify(unwrap_or(rgba8_buffer_size(3, 2, 16), -1) == 28)
    verify(SDL_RGBA8BufferSize(0, 2, 16) == -1)
    verify(SDL_RGBA8BufferSize(3, -1, 16) == -1)
    verify(SDL_RGBA8BufferSize(3, 2, -1) == -1)
    verify(SDL_RGBA8BufferSize(3, 2, 11) == -1)
    verify(SDL_RGBA8BufferSize(2147483647, 1, 16) == -1)
    verify(SDL_RGBA8BufferSize(1, 2147483647, 2147483647) == -1)
    let scope_ok_0 = with_sdl() {
        let scope_ok_1 = with_window("pixels contracts", 64, 64, SDL_WINDOW_HIDDEN) $(window : SDL_Window?) {
            let scope_ok_2 = window |> with_renderer() $(renderer : SDL_Renderer?) {
                let scope_ok_3 = renderer |> with_target_texture(3, 2) $(outer : SDL_Texture?) {
                    let scope_ok_4 = renderer |> with_render_target(outer) {
                        // The pinned AOT emitter can hoist nested block functors
                        // before a for-iterator declaration after scope inlining.
                        var mode = 0
                        while (mode < 3) {
                            SDLTestReset()
                            var caught = false
                            var error = ""
                            var copy : array<uint8>
                            copy |> resize(36)
                            for (i in 0 .. length(copy)) { copy[i] = uint8(201) }
                            {
                                let scope_ok_5 = renderer |> with_target_texture(3, 2) $(target : SDL_Texture?) {
                                    verify(SDLTestWatchTexture(target))
                                    let scope_ok_6 = renderer |> with_render_target(target) {
                                        let scope_ok_7 = renderer |> with_streaming_texture(3, 2) $(streaming : SDL_Texture?) {
                                            var bytes : array<uint8>
                                            verify(!SDL_UploadRGBA8(streaming, bytes, 16))
                                            bytes |> resize(28)
                                            for (pixel in 0 .. 6) {
                                                let x = pixel % 3
                                                let y = pixel / 3
                                                let i = y * 16 + x * 4
                                                bytes[i] = uint8(10 + x * 50)
                                                bytes[i + 1] = uint8(20 + y * 60)
                                                bytes[i + 2] = uint8(30)
                                                bytes[i + 3] = uint8(255)
                                            }
                                            verify(!SDL_UploadRGBA8(streaming, bytes, 11))
                                            verify(!SDL_UploadRGBA8(streaming, bytes, 17))
                                            verify(!SDL_UploadRGBA8(target, bytes, 16))
                                            is_ok(streaming |> upload_rgba8(bytes, 16))
                                            // Repeat lock/unlock, then mutate the source before rendering.
                                            is_ok(streaming |> upload_rgba8(bytes, 16))
                                            for (i in 0 .. length(bytes)) { bytes[i] = uint8(0) }
                                            is_ok(renderer |> clear(uint4(0u, 0u, 0u, 255u)))
                                            is_ok(renderer |> draw_texture(streaming))

                                            return sdl_ok()
                                        } |> is_ok
                                        verify(scope_ok_7)
                                        let scope_ok_8 = renderer |> with_read_pixels() $(surface : SDL_Surface?) {
                                            verify(SDLTestWatchSurface(surface))
                                            var query_result_1 : int2
                                            verify(is_ok(surface_size(surface, query_result_1)))
                                            verify(query_result_1 == int2(3, 2))
                                            var short_copy : array<uint8>
                                            short_copy |> resize(1)
                                            short_copy[0] = uint8(99)
                                            verify(!SDL_CopySurfaceRGBA8(surface, short_copy, 20))
                                            verify(short_copy[0] == uint8(99))
                                            is_ok(surface |> copy_surface_rgba8(copy, 20))
                                            if (mode == 1) { return sdl_ok() }
                                            if (mode == 2) { caught = !is_ok(set_title(null, "expected SDL failure")); return sdl_ok() }

                                            return sdl_ok()
                                        } |> is_ok
                                        verify(scope_ok_8)
                                        verify(SDLTestCleanupTrace() == 1, "readback surface leaked")
                                        if (mode == 1) { return sdl_ok() }

                                        return sdl_ok()
                                    } |> is_ok
                                    verify(scope_ok_6)
                                    verify(SDL_GetRenderTarget(renderer) == outer)
                                    if (mode == 1) { return sdl_ok() }

                                    return sdl_ok()
                                } |> is_ok
                                verify(scope_ok_5)
                            }
                            if (caught && mode != 2) { panic(error) }
                            verify(caught == (mode == 2))

                            verify(SDL_GetRenderTarget(renderer) == outer, "previous target not restored")
                            verify(SDLTestCleanupTrace() == 12, "surface/texture destruction order")
                            for (pixel in 0 .. 6) {
                                let x = pixel % 3
                                let y = pixel / 3
                                let i = y * 20 + x * 4
                                verify(copy[i] == uint8(10 + x * 50))
                                verify(copy[i + 1] == uint8(20 + y * 60))
                                verify(copy[i + 2] == uint8(30) && copy[i + 3] == uint8(255))
                            }
                            for (i in 12 .. 20) { verify(copy[i] == uint8(201), "padding overwritten") }
                            var called = false
                            let scope_ok_9 = renderer |> with_streaming_texture(3, 2) $(streaming : SDL_Texture?) {
                                var rejected = false
                                { let operation_ok = renderer |> with_render_target(streaming) { called = true
                                    return sdl_ok()
                                } |> is_ok
rejected = !operation_ok }
                                verify(rejected && !called)

                                return sdl_ok()
                            } |> is_ok
                            verify(scope_ok_9)
                            verify(SDL_GetRenderTarget(renderer) == outer)
                            is_ok(renderer |> clear())
                            mode++
                        }

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_4)
                    verify(SDL_GetRenderTarget(renderer) == null)

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_3)
                is_ok(renderer |> clear())
                is_ok(renderer |> present())

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_2)

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_1)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    print("Pixels: pitched RGBA copies, readback, nested targets and deferred cleanup OK\n")
    return 0
}
