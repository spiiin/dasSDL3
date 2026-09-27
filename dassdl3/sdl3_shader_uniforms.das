options gen2
module sdl3_shader_uniforms shared public
require dassdl3/sdl3_shader_uniform_pack public
require dassdl3/sdl3_result public

// Own a fresh packed buffer, or use pack_gpu_dsl_uniform(value, bytes) to reuse one.
def public gpu_dsl_uniform_bytes(value : auto) : array<uint8> {
    var bytes : array<uint8>
    pack_gpu_dsl_uniform(value, bytes)
    return <- bytes
}

def public push_gpu_dsl_vertex_uniform(command : SDL_GPUCommandBuffer?; slot : uint; value : auto) {
    if (command == null || slot >= 4u) {
        return err(SdlError(operation = "push_gpu_dsl_uniform", message = "Expected a command buffer and uniform slot 0..3"), type<SdlUnit>)
    }
    var bytes <- gpu_dsl_uniform_bytes(value)
    return sdl_status(SDL_PushGPUVertexUniformDataArray(command, slot, bytes), "SDL_PushGPUVertexUniformData")
}

def public push_gpu_dsl_fragment_uniform(command : SDL_GPUCommandBuffer?; slot : uint; value : auto) {
    if (command == null || slot >= 4u) {
        return err(SdlError(operation = "push_gpu_dsl_uniform", message = "Expected a command buffer and uniform slot 0..3"), type<SdlUnit>)
    }
    var bytes <- gpu_dsl_uniform_bytes(value)
    return sdl_status(SDL_PushGPUFragmentUniformDataArray(command, slot, bytes), "SDL_PushGPUFragmentUniformData")
}

def public push_gpu_dsl_compute_uniform(command : SDL_GPUCommandBuffer?; slot : uint; value : auto) {
    if (command == null || slot >= 4u) {
        return err(SdlError(operation = "push_gpu_dsl_uniform", message = "Expected a command buffer and uniform slot 0..3"), type<SdlUnit>)
    }
    var bytes <- gpu_dsl_uniform_bytes(value)
    return sdl_status(SDL_PushGPUComputeUniformDataArray(command, slot, bytes), "SDL_PushGPUComputeUniformData")
}
