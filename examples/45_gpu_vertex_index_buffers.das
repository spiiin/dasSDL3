options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_recording_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/vertex_color"
    let vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    let fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex : uint64) {
        return device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment : uint64) {
            return create_pipeline(device, vertex, fragment)
        }
    }
}

def draw_and_check(device : SDL_GPUDevice?; pipeline, vb, ib, target : uint64) : $Result<SdlUnit; SdlError> {
    var black : SDL_FColor
    black.a = 1.0
    var buffers <- array<uint64>(vb)
    var offsets <- array<uint>(0u)
    device |> with_gpu_command_buffer() $(command : uint64) {
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
    device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,64u,64u)) $(ticket : uint64) {
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

def render_buffers(device : SDL_GPUDevice?; pipeline : uint64) : $Result<SdlUnit; SdlError> {
    var vertices <- array<float>(-0.75,-0.75,1.0,0.0,0.0, 0.0,0.75,0.0,1.0,0.0, 0.75,-0.75,0.0,0.0,1.0)
    var indices <- array<uint>(0u,1u,2u)
    return device |> with_gpu_vertex_buffer(vertices) $(vb : uint64) {
        return device |> with_gpu_index_buffer(indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) $(ib : uint64) {
            return device |> with_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : uint64) {
                return draw_and_check(device, pipeline, vb, ib, target)
            }
        }
    }
}

def create_pipeline(device : SDL_GPUDevice?; vertex, fragment : uint64) : $Result<SdlUnit; SdlError> {
    var layouts : array<SDL_GPUVertexBufferDescription>
    resize(layouts,1); layouts[0].pitch = 20u
    var attributes : array<SDL_GPUVertexAttribute>
    resize(attributes,2)
    attributes[0].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
    attributes[1].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3
    attributes[1].location = 1u; attributes[1].offset = 8u
    var colors : array<SDL_GPUColorTargetDescription>
    push(colors,gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    return device |> with_gpu_graphics_pipeline(vertex,fragment,gpu_graphics_pipeline_info(),layouts,attributes,colors) $(pipeline : uint64) {
        return render_buffers(device, pipeline)
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
