options gen2
require dassdl3/sdl3_gpu_recording_boost
require daslib/defer

// SDL errors return normally, so defer can release every acquired resource.
def render_triangle(device : SDL_GPUDevice?) : bool {
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
    if (vertex == 0ul) { return false }
    fragment = SDL_LoadGPUCheckedShader(device,"{base}.frag.{extension}",gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT),"main")
    if (fragment == 0ul) { return false }
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    resize(colors,1)
    colors[0] = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    pipeline = SDL_CreateGPUCheckedGraphicsPipeline(device,vertex,fragment,gpu_graphics_pipeline_info(),buffers,attributes,colors)
    if (pipeline == 0ul) { return false }
    target = SDL_CreateGPUColorTargetTexture(device,64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM)
    if (target == 0ul) { return false }
    command = SDL_AcquireGPUCommandBufferChecked(device)
    if (command == 0ul) { return false }
    var black : SDL_FColor
    black.a = 1.0
    let render_pass = unwrap_or(gpu_begin_render_pass(device,command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black), 0ul)
    if (render_pass == 0ul) { return false }
    var operation_result_1 <- gpu_bind_pipeline(device,render_pass,pipeline)
    if (is_err(operation_result_1)) { return false }
    var operation_result_2 <- gpu_draw_primitives(device,render_pass,3u)
    if (is_err(operation_result_2)) { return false }
    var operation_result_3 <- gpu_end_render_pass(device,render_pass)
    if (is_err(operation_result_3)) { return false }
    var operation_result_4 <- gpu_submit_command_buffer(device,command)
    if (is_err(operation_result_4)) { return false }
    var pixels : array<uint8>
    resize(pixels,64*64*4)
    ticket = SDL_RequestGPUTextureReadback(device,target,uint2(0u),uint4(0u,0u,64u,64u))
    if (ticket == 0ul) { return false }
    var operation_result_5 <- gpu_wait_readback(device,ticket)
    if (is_err(operation_result_5)) { return false }
    var operation_result_6 <- gpu_readback_bytes(device,ticket,pixels)
    if (is_err(operation_result_6)) { return false }
    let center = (32*64+32)*4
    if (int(pixels[center]) <= 40 || int(pixels[center+1]) <= 100 || int(pixels[center+2]) <= 40 ||
            pixels[0] != uint8(0) || pixels[3] != uint8(255)) {
        return SDL_SetErrorMessage("Triangle readback differs from expected pixels")
    }
    print("Direct render pass triangle + deferred cleanup: {SDL_GetGPUDeviceDriver(device)}\n")
    return true
}

[export]
def main(smoke : bool) : int {
    var operation_result_7 <- sdl_init()
    if (is_err(operation_result_7)) { print("SDL_Init: {unwrap_err(operation_result_7).message}\n"); return 1 }
    {
        defer() { SDL_Quit() }
        let device = SDL_CreateGPUDeviceScoped(GPU_SHADER_FORMATS,true,"")
        if (device == null) {
            print("SDL_CreateGPUDevice: {SDL_GetError()}\n")
            return smoke ? 77 : 1
        }
        {
            defer() { SDL_DestroyGPUDeviceScoped(device) }
            if (!render_triangle(device)) { print("SDL GPU: {SDL_GetError()}\n"); return 1 }
            return 0
        }
    }
}
