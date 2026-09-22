options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_recording_boost
require daslib/defer

// SDL errors return normally, so defer can release every acquired resource.
def render_triangle(device : SDL_GPUDevice?) : $Result<SdlUnit; SdlError> {
    var vertex : GpuShaderHandle
    var fragment : GpuShaderHandle
    var pipeline : GpuPipelineHandle
    var target : GpuTextureHandle
    var command : GpuCommandBufferHandle
    var ticket : GpuReadbackHandle
    defer() {
        if (*ticket != 0ul) { SDL_ReleaseGPUReadback(device,ticket) }
        if (*command != 0ul) { SDL_GPURecordingDiscard(device,command) }
        if (*target != 0ul) { SDL_ReleaseGPUTransferTexture(device,target) }
        if (*pipeline != 0ul) { SDL_ReleaseGPUCheckedGraphicsPipeline(device,pipeline) }
        if (*fragment != 0ul) { SDL_ReleaseGPUCheckedShader(device,fragment) }
        if (*vertex != 0ul) { SDL_ReleaseGPUCheckedShader(device,vertex) }
    }
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/triangle"
    vertex = device |> load_gpu_shader("{base}.vert.{extension}",gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX),"main") |> sdl_try
    fragment = device |> load_gpu_shader("{base}.frag.{extension}",gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT),"main") |> sdl_try
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    resize(colors,1)
    colors[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    pipeline = device |> create_gpu_graphics_pipeline(vertex,fragment,gpu_graphics_pipeline_info(),buffers,attributes,colors) |> sdl_try
    target = device |> create_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) |> sdl_try
    command = device |> acquire_gpu_command_buffer() |> sdl_try
    var black = SDL_FColor(a = 1.0)
    let render_pass = gpu_begin_render_pass(device,command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black) |> sdl_try
    gpu_bind_pipeline(device,render_pass,pipeline) |> sdl_try
    gpu_draw_primitives(device,render_pass,3u) |> sdl_try
    gpu_end_render_pass(device,render_pass) |> sdl_try
    gpu_submit_command_buffer(device,command) |> sdl_try
    var pixels : array<uint8>
    resize(pixels,64*64*4)
    ticket = device |> request_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,64u,64u)) |> sdl_try
    gpu_wait_readback(device,ticket) |> sdl_try
    gpu_readback_bytes(device,ticket,pixels) |> sdl_try
    let center = (32*64+32)*4
    if (int(pixels[center]) <= 40 || int(pixels[center+1]) <= 100 || int(pixels[center+2]) <= 40 ||
            pixels[0] != uint8(0) || pixels[3] != uint8(255)) {
        return err(SdlError(operation="render_triangle",message="Triangle readback differs from expected pixels"),type<SdlUnit>)
    }
    print("Direct render pass triangle + deferred cleanup: {SDL_GetGPUDeviceDriver(device)}\n")
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        return render_triangle(device)
    }
    if (is_err(result)) {
        let error=unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
