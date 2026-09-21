options gen2
require dassdl3/sdl3_gpu_shader_boost
require dassdl3/sdl3_gpu_sampler_boost
require daslib/fio
require daslib/rtti
require strings

def load_bytes(path : string; var bytes : array<uint8>) {
    var read = -1
    fopen(path,"rb") $(file) {
        if (file != null) {
            resize(bytes,int(fstat(file).size))
            read = fread(file,bytes)
        }
    }
    verify(read > 0 && read == length(bytes))
}
def check_bytes(device : SDL_GPUDevice?; vertex, fragment : string; format : uint) {
    var bytes : array<uint8>
    var info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    verify(*SDL_CreateGPUCheckedShader(device,bytes,info,"main") == 0ul)
    resize(bytes,35)
    verify(*SDL_CreateGPUCheckedShader(device,bytes,info,"main") == 0ul)
    load_bytes(vertex,bytes)
    let vs = SDL_CreateGPUCheckedShader(device,bytes,info,"main")
    verify(*vs != 0ul)
    // Mutate and reallocate the caller's bytes before constructing the pipeline.
    for (i in 0 .. length(bytes)) { bytes[i] = uint8(0) }
    clear(bytes)
    load_bytes(fragment,bytes)
    info.stage = SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT
    let fs = SDL_CreateGPUCheckedShader(device,bytes,info,"main")
    verify(*fs != 0ul)
    clear(bytes)
    verify(SDLTest_shader_wrong_thread(device,*vs))
    let name = unwrap_or(gpu_shader_entrypoint(device,vs), "")
    if (!SDLTest_shader_pipeline_pixels(device,*vs,*fs)) { panic("Shader pixels: {SDL_GetError()}") }
    verify(name == "main" && !SDLTest_shader_exists(*vs) && !SDLTest_shader_exists(*fs))
    verify(!SDL_ReleaseGPUCheckedShader(device,vs))
    var out = info
    verify(!SDL_GetGPUCheckedShaderInfo(device,fs,out) && out.format == 0u)
    verify(SDLTest_shader_hidden_fields_clear(out))
}
def check_scopes(device : SDL_GPUDevice?; vertex : string; format : uint) {
    var info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    verify(*SDL_LoadGPUCheckedShader(device,"missing-shader-file",info,"main") == 0ul)
    verify(*SDL_LoadGPUCheckedShader(device,"",info,"main") == 0ul)
    verify(*SDL_LoadGPUCheckedShader(device,vertex,info,"bad entry") == 0ul)
    var invalid = info
    invalid.format = SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL
    verify(*SDL_LoadGPUCheckedShader(device,vertex,invalid,"main") == 0ul)
    invalid = info; invalid.num_uniform_buffers = 5u
    verify(*SDL_LoadGPUCheckedShader(device,vertex,invalid,"main") == 0ul)
    var stale : GpuShaderHandle
    var caught, invoked = false
    { let operation_ok = device |> with_gpu_shader_file(vertex,invalid) $(id : GpuShaderHandle) { invoked = true
        return sdl_ok()
    } |> is_ok
caught = !operation_ok }
    verify(caught && !invoked && SDLTest_shader_count(device) == 0u)
    let scope_ok_0 = device |> with_gpu_shader_file(vertex,info) $(outer : GpuShaderHandle) {
        info.format = 0u // Creation owns its value metadata.
        var query_result_1 : SDL_GPUShaderCreateInfo
        verify(is_ok(gpu_shader_descriptor(device,outer,query_result_1)))
        var copy = query_result_1
        verify(copy.format == format && SDLTest_shader_hidden_fields_clear(copy))
        copy.num_samplers = 16u
        var query_result_2 : SDL_GPUShaderCreateInfo
        verify(is_ok(gpu_shader_descriptor(device,outer,query_result_2)))
        verify(query_result_2.num_samplers == 0u)
        info.format = format
        caught = false
        {
            let scope_ok_1 = device |> with_gpu_shader_file(vertex,info) $(inner : GpuShaderHandle) { stale = inner; caught = !is_ok(set_title(null,"expected SDL failure")); return sdl_ok()
            } |> is_ok
            verify(scope_ok_1)
        }
        verify(caught && !SDLTest_shader_exists(*stale))
        var query_result_3 : SDL_GPUShaderCreateInfo
        verify(is_ok(gpu_shader_descriptor(device,outer,query_result_3)))
        verify(query_result_3.stage == SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
        var foreign : GpuShaderHandle
        let second = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(other : SDL_GPUDevice?) {
            verify(!SDL_ReleaseGPUCheckedShader(other,outer))
            foreign = SDL_LoadGPUCheckedShader(other,vertex,info,"main")
            verify(*foreign != 0ul)
            verify(!SDL_GetGPUCheckedShaderInfo(device,foreign,copy))

            return sdl_ok()
        } |> is_ok
        verify(second && !SDLTest_shader_exists(*foreign))
        verify(unwrap_or(gpu_shader_entrypoint(device,outer), "") == "main")
        let scope_ok_2 = device |> with_gpu_sampler() $(sampler : GpuSamplerHandle) {
            verify(!SDL_ReleaseGPUCheckedShader(device,GpuShaderHandle(*sampler)))
            verify(!SDL_ReleaseGPUCheckedSampler(device,GpuSamplerHandle(*outer)))

            return sdl_ok()
        } |> is_ok
        verify(scope_ok_2)

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    let scope_ok_3 = device |> with_gpu_shader_file(vertex,info) $(id : GpuShaderHandle) { stale = id; return sdl_ok()
    } |> is_ok
    verify(scope_ok_3)
    verify(!SDLTest_shader_exists(*stale) && SDLTest_shader_count(device) == 0u)
    var bytes : array<uint8>
    load_bytes(vertex,bytes)
    caught = false
    {
        let scope_ok_4 = device |> with_gpu_shader(bytes,info) $(id : GpuShaderHandle) { stale = id; caught = !is_ok(set_title(null,"expected SDL failure")); return sdl_ok()
        } |> is_ok
        verify(scope_ok_4)
    }
    verify(caught && !SDLTest_shader_exists(*stale) && SDLTest_shader_count(device) == 0u)
}
[export]
def main(smoke : bool) : int {
    verify(SDLTest_shader_invalid_metadata())
    var abi : SDL_GPUShaderCreateInfo
    SDLTest_shader_fill_info(abi)
    verify(abi.format == SDL_GPU_SHADERFORMAT_DXIL && abi.stage == SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    verify(abi.num_samplers == 1u && abi.num_storage_textures == 2u && abi.num_storage_buffers == 3u && abi.num_uniform_buffers == 4u && abi.props == 123u)
    abi.format = SDL_GPU_SHADERFORMAT_SPIRV; abi.stage = SDL_GPUShaderStage.SHADERSTAGE_VERTEX
    abi.num_samplers = 5u; abi.num_storage_textures = 6u; abi.num_storage_buffers = 7u; abi.num_uniform_buffers = 2u; abi.props = 456u
    verify(SDLTest_shader_check_info(abi))
    var available = false
    var abandoned : GpuShaderHandle
    let scope_ok_5 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders/triangle"
            check_bytes(device,"{base}.vert.{extension}","{base}.frag.{extension}",format)
            check_scopes(device,"{base}.vert.{extension}",format)
            // Real nonzero resource declarations, matching the trusted lit shader ABI.
            var info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            info.num_samplers = 1u; info.num_uniform_buffers = 1u
            let scope_ok_6 = device |> with_gpu_shader_file("{SDL_GetBasePath()}assets/shaders/lit.frag.{extension}",info) $(id : GpuShaderHandle) {
                var query_result_4 : SDL_GPUShaderCreateInfo
                verify(is_ok(gpu_shader_descriptor(device,id,query_result_4)))
                let copy = query_result_4
                verify(copy.num_samplers == 1u && copy.num_uniform_buffers == 1u)
                verify(copy.num_storage_buffers == 0u && copy.num_storage_textures == 0u && copy.props == 0u)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_6)
            info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            abandoned = SDL_LoadGPUCheckedShader(device,"{base}.vert.{extension}",info,"main")
            verify(*abandoned != 0ul)
            print("Shader copied bytecode, pipeline pixels, metadata and ownership PASS: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_5)
    verify(!SDLTest_shader_exists(*abandoned))
    return available ? 0 : 77
}
