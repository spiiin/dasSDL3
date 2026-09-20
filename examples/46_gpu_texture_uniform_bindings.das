options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_recording_boost

def render_quad(device : SDL_GPUDevice?; pipeline, target, vb, ib, vertex_texture, texture, sampler : uint64) : $Result<SdlUnit; SdlError> {
    var black : SDL_FColor
    black.a = 1.0
    var buffers <- array<uint64>(vb)
    var offsets <- array<uint>(0u)
    var vertex_images <- array<uint64>(vertex_texture)
    var fragment_images <- array<uint64>(texture)
    var samplers <- array<uint64>(sampler)
    var transform <- array<float4>(float4(0.75,0.0,0.0,0.125),float4(0.0,0.75,0.0,-0.125))
    var tint <- array<float4>(float4(1.0,0.5,1.0,1.0))
    device |> with_gpu_command_buffer() $(command : uint64) {
        device |> gpu_push_uniform(command,SDL_GPUShaderStage.SHADERSTAGE_VERTEX,0u,transform) |> sdl_try
        device |> gpu_push_uniform(command,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,0u,tint) |> sdl_try
        let render_pass = device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black) |> sdl_try
        device |> gpu_bind_pipeline(render_pass,pipeline) |> sdl_try
        device |> gpu_bind_vertex_buffers(render_pass,0u,buffers,offsets) |> sdl_try
        device |> gpu_bind_index_buffer(render_pass,ib) |> sdl_try
        device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_VERTEX,vertex_images,samplers) |> sdl_try
        device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,fragment_images,samplers) |> sdl_try
        // Two triangles, two direct draw calls in one real SDL render render_pass.
        device |> gpu_draw_indexed_primitives(render_pass,3u) |> sdl_try
        device |> gpu_draw_indexed_primitives(render_pass,3u,1u,3u) |> sdl_try
        device |> gpu_end_render_pass(render_pass) |> sdl_try
        device |> gpu_submit_command_buffer(command) |> sdl_try

        return sdl_ok()
    } |> sdl_try
    var bytes : array<uint8>
    resize(bytes,64*64*4)
    device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,64u,64u)) $(ticket : uint64) {
        device |> gpu_wait_readback(ticket) |> sdl_try
        device |> gpu_readback_bytes(ticket,bytes) |> sdl_try

        return sdl_ok()
    } |> sdl_try
    verify(int(bytes[(24*64+24)*4]) == 128)
    verify(int(bytes[(24*64+48)*4+1]) >= 127 && int(bytes[(24*64+48)*4+1]) <= 128)
    verify(bytes[0] == uint8(0) && bytes[3] == uint8(255))
    return sdl_ok()
}

def run(device : SDL_GPUDevice?; linear : bool) : $Result<SdlUnit; SdlError> {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/bindings"
    var vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    var fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    vi.num_samplers = 1u; vi.num_uniform_buffers = 1u
    fi.num_samplers = 1u; fi.num_uniform_buffers = 1u
    return device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex : uint64) {
        return device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment : uint64) {
            return create_pipeline(device, vertex, fragment, linear)
        }
    }
}

def upload_textures(device : SDL_GPUDevice?; pipeline, vb, ib, vertex_texture : uint64; linear : bool) : $Result<SdlUnit; SdlError> {
    var vertex_color <- array<uint8>(uint8(128),uint8(255),uint8(128),uint8(255))
    device |> gpu_upload_texture(vertex_texture,uint2(0u),uint4(0u,0u,1u,1u),vertex_color,4u) |> sdl_try
    return device |> with_gpu_rgba_texture(2u,2u) $(texture : uint64) {
        var image <- array<uint8>(uint8(255),uint8(0),uint8(0),uint8(255), uint8(0),uint8(255),uint8(0),uint8(255),
            uint8(0),uint8(0),uint8(255),uint8(255), uint8(255),uint8(255),uint8(255),uint8(255))
        device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,2u,2u),image,8u) |> sdl_try
        let filter_mode = linear ? SDL_GPUFilter.FILTER_LINEAR : SDL_GPUFilter.FILTER_NEAREST
        return device |> with_gpu_sampler(gpu_sampler_info(filter_mode)) $(sampler : uint64) {
            return device |> with_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : uint64) {
                return render_quad(device,pipeline,target,vb,ib,vertex_texture,texture,sampler)
            }
        }
    }
}

def render_buffers(device : SDL_GPUDevice?; pipeline : uint64; linear : bool) : $Result<SdlUnit; SdlError> {
    var vertices <- array<float>(-0.75,0.75,0.0,0.0, 0.75,0.75,1.0,0.0, 0.75,-0.75,1.0,1.0, -0.75,-0.75,0.0,1.0)
    var indices <- array<uint>(0u,1u,2u,0u,2u,3u)
    return device |> with_gpu_vertex_buffer(vertices) $(vb : uint64) {
        return device |> with_gpu_index_buffer(indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) $(ib : uint64) {
            return device |> with_gpu_rgba_texture(1u,1u) $(vertex_texture : uint64) {
                return upload_textures(device, pipeline, vb, ib, vertex_texture, linear)
            }
        }
    }
}

def create_pipeline(device : SDL_GPUDevice?; vertex, fragment : uint64; linear : bool) : $Result<SdlUnit; SdlError> {
    var layouts : array<SDL_GPUVertexBufferDescription>
    resize(layouts,1); layouts[0].pitch = 16u
    var attributes : array<SDL_GPUVertexAttribute>
    resize(attributes,2)
    attributes[0].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
    attributes[1].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
    attributes[1].location = 1u; attributes[1].offset = 8u
    var colors : array<SDL_GPUColorTargetDescription>
    push(colors,gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    return device |> with_gpu_graphics_pipeline(vertex,fragment,gpu_graphics_pipeline_info(),layouts,attributes,colors) $(pipeline : uint64) {
        return render_buffers(device, pipeline, linear)
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            run(device,false) |> sdl_try
            print("Texture/sampler and uniform bindings: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        }
    }
    if (is_err(result)) {
        let error=unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
