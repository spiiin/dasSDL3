options gen2
require dassdl3/sdl3_gpu_recording_boost
require dassdl3/sdl3_gpu_volume_boost
require dassdl3/sdl3_try

def check_handle(value : auto(T)) {
    SDL_SetErrorText("old error")
    let good = checked_handle_result(value,"test")
    verify(is_ok(good) && unwrap(good) == value)
    let bad = checked_handle_result(default<T>,"failed factory")
    SDL_SetErrorText("later error")
    verify(is_err(bad) && unwrap_err(bad).operation == "failed factory" && unwrap_err(bad).message == "old error")
}
[export]
def main(smoke : bool) : int {
    check_handle(GpuBufferHandle(0xfedcba9876543210ul))
    check_handle(GpuIndexBufferHandle(1ul))
    check_handle(GpuTextureHandle(1ul))
    check_handle(GpuVolumeHandle(1ul))
    check_handle(GpuReadbackHandle(1ul))
    check_handle(GpuShaderHandle(1ul))
    check_handle(GpuSamplerHandle(1ul))
    check_handle(GpuPipelineHandle(1ul))
    check_handle(GpuCommandBufferHandle(1ul))
    check_handle(GpuRenderPassHandle(1ul))
    var bytes : array<uint8>
    let buffer = create_gpu_buffer(null,bytes,SDL_GPU_BUFFERUSAGE_VERTEX)
    verify(is_err(buffer) && unwrap_err(buffer).operation == "SDL_CreateGPUDataBuffer")
    let command = acquire_gpu_command_buffer(null)
    verify(is_err(command) && unwrap_err(command).operation == "SDL_AcquireGPUCommandBufferChecked")
    let texture = create_gpu_color_target_texture(null,1u,1u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM)
    verify(is_err(texture) && unwrap_err(texture).operation == "SDL_CreateGPUColorTargetTexture")
    print("Checked handle Result factories: exact types and immediate error snapshots PASS\n")
    return 0
}
