options gen2
require dassdl3/sdl3_gpu_recording_boost
require dassdl3/sdl3_try
require daslib/defer

def propagate(fail : bool; var released : bool&) : $Result<GpuBufferHandle; SdlError> {
    defer() { released = true }
    let source = fail ? err(SdlError(operation="handle",message="expected"),type<GpuBufferHandle>) : ok(GpuBufferHandle(0xfedcba9876543210ul),type<SdlError>)
    let value = source |> sdl_try
    return ok(SDLTestGPUHandleEcho(value),type<SdlError>)
}

[export]
def main(smoke : bool) : int {
    var empty : GpuBufferHandle
    verify(*empty == 0ul)
    let bits = 0xfedcba9876543210ul
    let buffer = GpuBufferHandle(bits)
    verify(SDLTestGPUHandleEcho(buffer) == buffer)
    verify(*GpuIndexBufferHandle(bits) == bits)
    verify(*GpuTextureHandle(bits) == bits)
    verify(*GpuVolumeHandle(bits) == bits)
    verify(*GpuReadbackHandle(bits) == bits)
    verify(*GpuShaderHandle(bits) == bits)
    verify(*GpuSamplerHandle(bits) == bits)
    verify(*GpuPipelineHandle(bits) == bits)
    verify(*GpuCommandBufferHandle(bits) == bits)
    verify(*GpuRenderPassHandle(bits) == bits)
    var buffers <- array<GpuBufferHandle>(buffer,empty)
    verify(SDLTestGPUHandleEcho(buffers[0]) == buffer && *buffers[1] == 0ul)
    var released = false
    let success = propagate(false,released)
    verify(released && is_ok(success) && unwrap(success) == buffer)
    released = false
    let failure = propagate(true,released)
    verify(released && is_err(failure) && unwrap_err(failure).message == "expected")
    let optional = some(buffer)
    verify(is_some(optional) && unwrap(optional) == buffer)
    let nested = ok(optional,type<SdlError>)
    verify(unwrap(unwrap(nested)) == buffer)
    // Nominal typing is not ownership: a fabricated ID still fails native validation.
    verify(is_err(gpu_poll_readback(null,GpuReadbackHandle(bits))))
    print("Distinct GPU handles: uint64 ABI, arrays, Result/Option, sdl_try and defer PASS\n")
    return 0
}
