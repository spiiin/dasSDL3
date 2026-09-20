options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_recording_boost
require daslib/defer

// SDL errors return normally, so defer can release every acquired resource.
def render_triangle(device : SDL_GPUDevice?) : $Result<SdlUnit; SdlError> {
    var vertex, fragment, pipeline, target, command, ticket = 0ul
    defer() {
        if (ticket != 0ul) { SDL_ReleaseGPUReadback(device,ticket) }
        if (command != 0ul) { SDL_GPURecordingDiscard(device,command) }
        if (target != 0ul) { SDL_ReleaseGPUTransferTexture(device,target) }
        if (pipeline != 0ul) { SDL_ReleaseGPUCheckedGraphicsPipeline(device,pipeline) }
        if (fragment != 0ul) { SDL_ReleaseGPUCheckedShader(device,fragment) }
        if (vertex != 0ul) { SDL_ReleaseGPUCheckedShader(device,vertex) }
    }
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/triangle"
    vertex = SDL_LoadGPUCheckedShader(device,"{base}.vert.{extension}",gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX),"main")
    if (vertex == 0ul) { return err(sdl_error("render_triangle"),type<SdlUnit>) }
    fragment = SDL_LoadGPUCheckedShader(device,"{base}.frag.{extension}",gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT),"main")
    if (fragment == 0ul) { return err(sdl_error("render_triangle"),type<SdlUnit>) }
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    resize(colors,1)
    colors[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    pipeline = SDL_CreateGPUCheckedGraphicsPipeline(device,vertex,fragment,gpu_graphics_pipeline_info(),buffers,attributes,colors)
    if (pipeline == 0ul) { return err(sdl_error("render_triangle"),type<SdlUnit>) }
    target = SDL_CreateGPUColorTargetTexture(device,64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM)
    if (target == 0ul) { return err(sdl_error("render_triangle"),type<SdlUnit>) }
    command = SDL_AcquireGPUCommandBufferChecked(device)
    if (command == 0ul) { return err(sdl_error("render_triangle"),type<SdlUnit>) }
    var black : SDL_FColor
    black.a = 1.0
    let render_pass = gpu_begin_render_pass(device,command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black) |> sdl_try
    gpu_bind_pipeline(device,render_pass,pipeline) |> sdl_try
    gpu_draw_primitives(device,render_pass,3u) |> sdl_try
    gpu_end_render_pass(device,render_pass) |> sdl_try
    gpu_submit_command_buffer(device,command) |> sdl_try
    var pixels : array<uint8>
    resize(pixels,64*64*4)
    ticket = SDL_RequestGPUTextureReadback(device,target,uint2(0u),uint4(0u,0u,64u,64u))
    if (ticket == 0ul) { return err(sdl_error("render_triangle"),type<SdlUnit>) }
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
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return render_triangle(device)
        }
    }
    if (is_err(result)) {
        let error=unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
