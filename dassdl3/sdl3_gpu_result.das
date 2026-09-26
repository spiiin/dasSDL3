options gen2
module sdl3_gpu_result shared public
require dassdl3/sdl3_result public

// Only checked GPU IDs use zero as their failure sentinel. This is not a
// generic conversion for numbers, predicates or optional native pointers.
def private is_invalid_gpu_handle(handle : GpuBufferHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuIndexBufferHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuTextureHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuVolumeHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuReadbackHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuShaderHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuSamplerHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuPipelineHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuCommandBufferHandle) : bool { return *handle == 0ul }
def private is_invalid_gpu_handle(handle : GpuRenderPassHandle) : bool { return *handle == 0ul }

def public checked_handle_result(handle : auto(T); operation : string) {
    if (is_invalid_gpu_handle(handle)) {
        return err(sdl_error(operation), type<T -const>)
    }
    return ok(handle, type<SdlError>)
}
