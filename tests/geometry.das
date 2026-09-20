options gen2
require dassdl3/sdl3_geometry_boost
require dassdl3/sdl3_pixels_boost
require daslib/rtti
require daslib/strings_boost

def read_geometry_image(renderer : SDL_Renderer?; var bytes : array<uint8>) {
    let scope_ok_0 = renderer |> with_read_pixels() $(surface) {
        var query_result_1 : int2
        verify(surface_size(surface,query_result_1))
        let size = query_result_1
        bytes |> resize(rgba8_buffer_size(size.x, size.y, size.x * 4))
        surface |> copy_surface_rgba8(bytes, size.x * 4)
    }
    verify(scope_ok_0)
}
def pixel(bytes : array<uint8>; x, y : int) : uint4 {
    let i = (y * 64 + x) * 4
    return uint4(uint(bytes[i]), uint(bytes[i+1]), uint(bytes[i+2]), uint(bytes[i+3]))
}

[export]
def main(smoke : bool) : int {
    verify(smoke)
    let scope_ok_1 = with_sdl() {
        let scope_ok_2 = with_window("geometry contracts", 64, 64, SDL_WINDOW_HIDDEN) $(window) {
            let scope_ok_3 = window |> with_renderer() $(renderer) {
                verify(SDLTestGeometryCounts(renderer))
                let scope_ok_4 = renderer |> with_target_texture(64, 64) $(target) {
                    let scope_ok_5 = renderer |> with_render_target(target) {
                        var vertices : array<SDL_Vertex>
                        var indices : array<int>
                        var bytes : array<uint8>
                        renderer |> clear(uint4(0u, 0u, 0u, 255u))
                        renderer |> draw_geometry(vertices)
                        renderer |> draw_geometry(vertices, indices)
                        vertices |> resize(3)
                        vertices[0] = vertex(float2(8.0, 8.0), float4(0.0, 1.0, 0.0, 1.0))
                        vertices[1] = vertex(float2(56.0, 8.0), float4(0.0, 1.0, 0.0, 1.0))
                        vertices[2] = vertex(float2(8.0, 56.0), float4(0.0, 1.0, 0.0, 1.0))
                        // Empty indexed list must not render the sequential triangle.
                        renderer |> draw_geometry(vertices, indices)
                        read_geometry_image(renderer, bytes)
                        verify(pixel(bytes, 16, 16) == uint4(0u, 0u, 0u, 255u))
                        renderer |> draw_geometry(vertices)
                        read_geometry_image(renderer, bytes)
                        verify(pixel(bytes, 16, 16) == uint4(0u, 255u, 0u, 255u))
                        verify(pixel(bytes, 50, 50) == uint4(0u, 0u, 0u, 255u))
                        vertices |> resize(4)
                        vertices[3] = vertex(float2(56.0, 56.0), float4(0.0, 1.0, 0.0, 1.0))
                        indices |> resize(6)
                        indices[0] = 0; indices[1] = 1; indices[2] = 2
                        indices[3] = 2; indices[4] = 1; indices[5] = 3
                        renderer |> clear(uint4(0u, 0u, 0u, 255u))
                        renderer |> draw_geometry(vertices, indices)
                        vertices[0].position.x = 63.0
                        indices[0] = 3
                        var indexed_image : array<uint8>
                        read_geometry_image(renderer, indexed_image)
                        verify(pixel(indexed_image, 16, 16) == uint4(0u, 255u, 0u, 255u))
                        verify(pixel(indexed_image, 48, 48) == uint4(0u, 255u, 0u, 255u))
                        vertices[0].position.x = 8.0
                        indices[0] = 0
                        var sequential : array<SDL_Vertex>
                        sequential |> resize(6)
                        for (i in 0 .. 6) { sequential[i] = vertices[indices[i]] }
                        renderer |> clear(uint4(0u, 0u, 0u, 255u))
                        renderer |> draw_geometry(sequential)
                        read_geometry_image(renderer, bytes)
                        for (i in 0 .. length(bytes)) { verify(bytes[i] == indexed_image[i]) }
                        // Reject every bad draw before rendering, then continue with the same renderer.
                        verify(!SDL_RenderGeometryVertices(renderer, null, vertices)) // four vertices
                        indices[0] = -1
                        verify(!SDL_RenderGeometryIndices(renderer, null, vertices, indices))
                        var caught = false
                        { let operation_ok = renderer |> draw_geometry(vertices, indices)
caught = !operation_ok }
                        verify(caught)
                        indices[0] = 4
                        verify(!SDL_RenderGeometryIndices(renderer, null, vertices, indices))
                        indices[0] = 0
                        indices |> resize(5)
                        verify(!SDL_RenderGeometryIndices(renderer, null, vertices, indices))
                        indices |> resize(6)
                        indices[5] = 3
                        vertices[0].color.r = 1.1
                        verify(!SDL_RenderGeometryIndices(renderer, null, vertices, indices))
                        vertices[0].color.r = 0.0
                        vertices[0].tex_coord.x = -0.1
                        verify(!SDL_RenderGeometryIndices(renderer, null, vertices, indices))
                        vertices[0].tex_coord.x = 0.0
                        for (field in 0 .. 3) {
                            vertices[0] = SDLTestNonfiniteVertex(field)
                            verify(!SDL_RenderGeometryIndices(renderer, null, vertices, indices))
                        }
                        vertices[0] = sequential[0]
                        read_geometry_image(renderer, bytes)
                        for (i in 0 .. length(bytes)) { verify(bytes[i] == indexed_image[i], "rejected draw changed target") }
                        // Texture sampling + vertex color modulation, then release arrays before readback.
                        let scope_ok_6 = renderer |> with_streaming_texture(2, 2) $(texture) {
                            var texels : array<uint8>
                            texels |> resize(16)
                            for (i in 0 .. 4) {
                                texels[i*4] = uint8(31); texels[i*4+1] = uint8(95)
                                texels[i*4+2] = uint8(191); texels[i*4+3] = uint8(255)
                                vertices[i].color.r = 1.0; vertices[i].color.g = 1.0
                                vertices[i].color.b = 1.0; vertices[i].color.a = 1.0
                            }
                            vertices[1].tex_coord.x = 1.0
                            vertices[2].tex_coord.y = 1.0
                            vertices[3].tex_coord.x = 1.0; vertices[3].tex_coord.y = 1.0
                            texture |> upload_rgba8(texels, 8)
                            renderer |> draw_geometry(vertices, indices, texture)
                            vertices |> resize(0)
                            indices |> resize(0)
                            read_geometry_image(renderer, bytes)
                            verify(pixel(bytes, 32, 32) == uint4(31u, 95u, 191u, 255u))
                        }
                        verify(scope_ok_6)
                        indices |> resize(3)
                        verify(!SDL_RenderGeometryIndices(renderer, null, vertices, indices))
                        verify(!SDL_RenderGeometryVertices(null, null, vertices))
                    }
                    verify(scope_ok_5)
                    verify(SDL_GetRenderTarget(renderer) == null)
                }
                verify(scope_ok_4)
                renderer |> clear()
                renderer |> present()
            }
            verify(scope_ok_3)
        }
        verify(scope_ok_2)
    }
    verify(scope_ok_1)
    print("Geometry: indexed/sequential pixels, texture, array lifetime and bounds OK\n")
    return 0
}
