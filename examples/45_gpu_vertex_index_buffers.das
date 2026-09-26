options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_recording_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : SdlStatus {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/vertex_color"
    let vi = gpu_shader("{base}.vert.{extension}",format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    let fi = gpu_shader("{base}.frag.{extension}",format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return sdl_scope() {
        let vertex : GpuShaderHandle = device |> with_gpu_shader_file(vi) |> sdl_use
        let fragment : GpuShaderHandle = device |> with_gpu_shader_file(fi) |> sdl_use
        return create_pipeline(device, vertex, fragment)
    }
}

def draw_and_check(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle; vb : GpuBufferHandle; ib : GpuIndexBufferHandle; target : GpuTextureHandle) : SdlStatus {
    var black = SDL_FColor(a = 1.0)
    var buffers <- array<GpuBufferHandle>(vb)
    var offsets <- array<uint>(0u)
    sdl_scope() {
        let command : GpuCommandBufferHandle = device |> with_gpu_command_buffer() |> sdl_use
        let render_pass = device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black) |> sdl_try
        device |> gpu_bind_pipeline(render_pass,pipeline) |> sdl_try
        device |> gpu_bind_vertex_buffers(render_pass,0u,buffers,offsets) |> sdl_try
        device |> gpu_bind_index_buffer(render_pass,ib) |> sdl_try
        device |> gpu_draw_indexed_primitives(render_pass,3u) |> sdl_try
        device |> gpu_end_render_pass(render_pass) |> sdl_try
        device |> gpu_submit_command_buffer(command) |> sdl_try

        return sdl_ok()
    } |> sdl_try
    var pixels : array<uint8>
    resize(pixels,64*64*4)
    sdl_scope() {
        let ticket : GpuReadbackHandle = device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,64u,64u)) |> sdl_use
        device |> gpu_wait_readback(ticket) |> sdl_try
        device |> gpu_readback_bytes(ticket,pixels) |> sdl_try

        return sdl_ok()
    } |> sdl_try
    let center = (32*64+32)*4
    verify(int(pixels[center]) > 40 && int(pixels[center+1]) > 100 && int(pixels[center+2]) > 40)
    verify(pixels[0] == uint8(0) && pixels[3] == uint8(255))
    print("Vertex/index buffers + readback: {SDL_GetGPUDeviceDriver(device)}\n")

    return sdl_ok()
}

def render_buffers(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle) : SdlStatus {
    var vertices <- array<float>(-0.75,-0.75,1.0,0.0,0.0, 0.0,0.75,0.0,1.0,0.0, 0.75,-0.75,0.0,0.0,1.0)
    var indices <- array<uint>(0u,1u,2u)
    return sdl_scope() {
        let vb : GpuBufferHandle = device |> with_gpu_vertex_buffer(vertices) |> sdl_use
        let ib : GpuIndexBufferHandle = device |> with_gpu_index_buffer(indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) |> sdl_use
        let target : GpuTextureHandle = device |> with_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) |> sdl_use
        return draw_and_check(device, pipeline, vb, ib, target)
    }
}

def create_pipeline(device : SDL_GPUDevice?; vertex : GpuShaderHandle; fragment : GpuShaderHandle) : SdlStatus {
    var description <- gpu_pipeline(vertex,fragment)
    description |> vertex_buffer(0u,20u)
    description |> vertex_attribute(0u,0u,SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2,0u)
    description |> vertex_attribute(1u,0u,SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3,8u)
    description |> color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    return sdl_scope() {
        let pipeline : GpuPipelineHandle = device |> with_gpu_graphics_pipeline(description) |> sdl_use
        return render_buffers(device, pipeline)
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        return run_gpu_example(device, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
