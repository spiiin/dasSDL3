options gen2
require dassdl3/sdl3_gpu_recording_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders/vertex_color"
            let vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            let fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            let scope_ok_1 = device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex : uint64) {
                let scope_ok_2 = device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment : uint64) {
                    var layouts : array<SDL_GPUVertexBufferDescription>
                    resize(layouts,1); layouts[0].pitch = 20u
                    var attributes : array<SDL_GPUVertexAttribute>
                    resize(attributes,2)
                    attributes[0].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
                    attributes[1].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3
                    attributes[1].location = 1u; attributes[1].offset = 8u
                    var colors : array<SDL_GPUColorTargetDescription>
                    push(colors,gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
                    let scope_ok_3 = device |> with_gpu_graphics_pipeline(vertex,fragment,gpu_graphics_pipeline_info(),layouts,attributes,colors) $(pipeline : uint64) {
                        var vertices <- array<float>(-0.75,-0.75,1.0,0.0,0.0, 0.0,0.75,0.0,1.0,0.0, 0.75,-0.75,0.0,0.0,1.0)
                        var indices <- array<uint>(0u,1u,2u)
                        let scope_ok_4 = device |> with_gpu_vertex_buffer(vertices) $(vb : uint64) {
                            let scope_ok_5 = device |> with_gpu_index_buffer(indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) $(ib : uint64) {
                                let scope_ok_6 = device |> with_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : uint64) {
                                    var black : SDL_FColor
                                    black.a = 1.0
                                    var buffers <- array<uint64>(vb)
                                    var offsets <- array<uint>(0u)
                                    let scope_ok_7 = device |> with_gpu_command_buffer() $(command : uint64) {
                                        let render_pass = unwrap_or(device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black), 0ul)
                                        var operation_result_1 <- device |> gpu_bind_pipeline(render_pass,pipeline)
                                        if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                                        var operation_result_2 <- device |> gpu_bind_vertex_buffers(render_pass,0u,buffers,offsets)
                                        if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                                        var operation_result_3 <- device |> gpu_bind_index_buffer(render_pass,ib)
                                        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
                                        var operation_result_4 <- device |> gpu_draw_indexed_primitives(render_pass,3u)
                                        if (is_err(operation_result_4)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
                                        var operation_result_5 <- device |> gpu_end_render_pass(render_pass)
                                        if (is_err(operation_result_5)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_5).message}\n"); return err(unwrap_err(operation_result_5),type<SdlUnit>) }
                                        var operation_result_6 <- device |> gpu_submit_command_buffer(command)
                                        if (is_err(operation_result_6)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_6).message}\n"); return err(unwrap_err(operation_result_6),type<SdlUnit>) }

                                        return sdl_ok()
                                    }
                                    if (is_err(scope_ok_7)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_7).message}\n") ; return err(unwrap_err(scope_ok_7),type<SdlUnit>) }
                                    var pixels : array<uint8>
                                    resize(pixels,64*64*4)
                                    let scope_ok_8 = device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,64u,64u)) $(ticket : uint64) {
                                        var operation_result_7 <- device |> gpu_wait_readback(ticket)
                                        if (is_err(operation_result_7)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_7).message}\n"); return err(unwrap_err(operation_result_7),type<SdlUnit>) }
                                        var operation_result_8 <- device |> gpu_readback_bytes(ticket,pixels)
                                        if (is_err(operation_result_8)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_8).message}\n"); return err(unwrap_err(operation_result_8),type<SdlUnit>) }

                                        return sdl_ok()
                                    }
                                    if (is_err(scope_ok_8)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_8).message}\n") ; return err(unwrap_err(scope_ok_8),type<SdlUnit>) }
                                    let center = (32*64+32)*4
                                    verify(int(pixels[center]) > 40 && int(pixels[center+1]) > 100 && int(pixels[center+2]) > 40)
                                    verify(pixels[0] == uint8(0) && pixels[3] == uint8(255))
                                    print("Vertex/index buffers + readback: {SDL_GetGPUDeviceDriver(device)}\n")

                                    return sdl_ok()
                                }
                                if (is_err(scope_ok_6)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_6).message}\n") ; return err(unwrap_err(scope_ok_6),type<SdlUnit>) }

                                return sdl_ok()
                            }
                            if (is_err(scope_ok_5)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_5).message}\n") ; return err(unwrap_err(scope_ok_5),type<SdlUnit>) }

                            return sdl_ok()
                        }
                        if (is_err(scope_ok_4)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_4).message}\n") ; return err(unwrap_err(scope_ok_4),type<SdlUnit>) }

                        return sdl_ok()
                    }
                    if (is_err(scope_ok_3)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_3).message}\n") ; return err(unwrap_err(scope_ok_3),type<SdlUnit>) }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
