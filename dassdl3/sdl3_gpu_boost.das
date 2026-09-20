options gen2
module sdl3_gpu_boost shared public
require dassdl3/sdl3_boost public

// ClearScreen needs no shader binary. Future shader creation must check device formats.
let public GPU_CLEAR_FORMATS = (SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXBC |
    SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_MSL | SDL_GPU_SHADERFORMAT_METALLIB)

def public try_with_gpu_device(formats : uint; debug : bool; driver : string;
                              blk : block<(device : SDL_GPUDevice?) : void>) : bool {
    let device = SDL_CreateGPUDeviceScoped(formats, debug, driver)
    if (device == null) { return false }
    SDL_ScopeGPUDevice(device,blk)
    return true
}

def public with_gpu_device(blk : block<(device : SDL_GPUDevice?) : void>) {
    if (!try_with_gpu_device(GPU_CLEAR_FORMATS, true, "", blk)) {
        panic("SDL_CreateGPUDevice: {SDL_GetError()}")
    }
}

// Window and device must outlive this scope. No renderer may use the same window.
def public with_gpu_window(device : SDL_GPUDevice?; window : SDL_Window?; blk : block<() : void>) {
    if (!SDL_ClaimGPUWindowScoped(device, window)) { panic("GPU claim: {SDL_GetError()}") }
    SDL_ScopeGPUWindow(device,window,blk)
}

// True means submitted; false means no drawable swapchain (e.g. minimized).
// Output size is zero on skip/error. No script code executes during recording.
def public gpu_clear(device : SDL_GPUDevice?; window : SDL_Window?; rgba : float4; var size : uint2&) : bool {
    var width, height : uint
    let status = SDL_ClearGPUWindow(device, window, rgba.x, rgba.y, rgba.z, rgba.w, width, height)
    size = uint2(width, height)
    if (status < 0) { panic("GPU clear: {SDL_GetError()}") }
    return status == 1
}

def public gpu_clear(device : SDL_GPUDevice?; window : SDL_Window?; rgba : float4) : bool {
    var size : uint2
    return gpu_clear(device, window, rgba, size)
}

// Trusted offline-validated main-entry shaders: no vertex input or resource bindings.
// Pipeline IDs are checked and invalidated on release and scoped device destruction.
def public with_gpu_vertex_id_pipeline(device : SDL_GPUDevice?; window : SDL_Window?;
        vertex_file, fragment_file : string; format : uint; blk : block<(pipeline : uint64) : void>) {
    let pipeline = SDL_CreateGPUVertexIDPipeline(device, window, vertex_file, fragment_file, format)
    if (pipeline == 0ul) { panic("GPU pipeline: {SDL_GetError()}") }
    SDL_ScopeReleaseGPUVertexIDPipeline(device,pipeline,blk)
}

def public gpu_draw_triangle(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : uint64) : bool {
    var width, height : uint
    let status = SDL_DrawGPUVertexIDTriangle(device, window, pipeline, width, height)
    if (status < 0) { panic("GPU triangle: {SDL_GetError()}") }
    return status == 1
}
