options gen2
module sdl3_gpu_3d_boost shared public
require dassdl3/sdl3_gpu_boost public
require daslib/math_boost public
require math public
require daslib/rtti
require daslib/strings_boost

// position=float4(x,y,z,1), color=float4(R,G,B,A), indices=UINT32 triangle list.
def public with_gpu_3d_mesh(device : SDL_GPUDevice?; window : SDL_Window?;
        positions, colors : array<float4>; indices : array<uint>;
        vertex_file, fragment_file : string; format : uint; blk : block<(mesh : uint64) : void>) {
    let mesh = SDL_CreateGPU3DMesh(device,window,positions,colors,indices,vertex_file,fragment_file,format)
    if (mesh == 0ul) { panic("GPU 3D mesh: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk,mesh) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPU3DMesh(device,mesh)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU 3D release: {SDL_GetError()}") }
}

def public gpu_draw_3d_mesh(device : SDL_GPUDevice?; window : SDL_Window?; mesh : uint64; mvp : float4x4) : bool {
    let status = SDL_DrawGPU3DMesh(device,window,mesh,mvp[0],mvp[1],mvp[2],mvp[3])
    if (status < 0) { panic("GPU 3D draw: {SDL_GetError()}") }
    return status == 1
}

def public gpu_window_aspect(window : SDL_Window?) : float {
    let aspect = SDL_GPU3DWindowAspect(window)
    if (aspect <= 0.0) { panic("GPU camera: {SDL_GetError()}") }
    return aspect
}

// Right-handed camera looking toward target, depth 0..1. Angles are radians.
def gpu_finite3(v : float3) : bool {
    return is_finite(v.x) && is_finite(v.y) && is_finite(v.z)
}

def public gpu_camera(eye, target, up : float3; fovy, aspect, near_plane, far_plane : float) : float4x4 {
    if (!(is_finite(fovy) && is_finite(aspect) && is_finite(near_plane) && is_finite(far_plane)
            && fovy > 0.0 && fovy < 3.14159265 && aspect > 0.0
            && near_plane > 0.0 && far_plane > near_plane)) {
        panic("GPU camera: invalid perspective parameters")
    }
    if (!(gpu_finite3(eye) && gpu_finite3(target) && gpu_finite3(up))) { panic("GPU camera: finite vectors required") }
    let direction = eye - target
    let side = cross(up,direction)
    if (!(is_finite(dot(direction,direction)) && is_finite(dot(side,side))
            && dot(direction,direction) > 1.0e-12 && dot(side,side) > 1.0e-12)) {
        panic("GPU camera: degenerate view axes")
    }
    return perspective_rh_0_to_1(fovy,aspect,near_plane,far_plane) * look_at_rh(eye,target,up)
}
