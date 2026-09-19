options gen2
require sdl3_probe
require daslib/safe_addr
[export]
def main : int {
    var a : SDL_FRect
    a.x = 1.; a.y = 2.; a.w = 10.; a.h = 20.
    var b : SDL_FRect
    b.x = 5.; b.y = 6.; b.w = 12.; b.h = 30.
    var result : SDL_FRect
    unsafe {
        verify(SDL_GetRectIntersectionFloat(addr(a), addr(b), addr(result)))
    }
    verify(result.x == 5. && result.y == 6. && result.w == 6. && result.h == 16.)
    verify(uint(SDL_PixelFormat.RGBA8888) == 0x16462004u)
    verify(SDL_GetPixelFormatName(SDL_PixelFormat.RGBA8888) == "SDL_PIXELFORMAT_RGBA8888")
    var view : SDL_GPUViewport
    view.w = 640.; view.h = 480.; view.max_depth = 1.
    verify(view.w == 640. && view.max_depth == 1.)
    var guid : SDL_GUID
    guid.data[0] = 17u8
    guid.data[15] = 42u8
    verify(guid.data[0] == 17u8 && guid.data[15] == 42u8)
    var desc : SDL_GPUVertexBufferDescription
    desc.pitch = 12u
    desc.input_rate = SDL_GPUVertexInputRate.VERTEX
    var input : SDL_GPUVertexInputState
    input.num_vertex_buffers = 1u
    unsafe {
        probe_set_vertex_buffer(input, desc)
        verify(input.vertex_buffer_descriptions.pitch == 12u)
    }
    verify(input.num_vertex_buffers == 1u && input.num_vertex_attributes == 0u)
    var p : SDL_Point
    var r : SDL_Rect
    r.w = 10; r.h = 10
    unsafe { verify(SDL_PointInRect(addr(p), addr(r))) }
    print("CppGenBind smoke PASS\n")
    return 0
}
