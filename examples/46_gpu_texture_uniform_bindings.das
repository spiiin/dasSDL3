options gen2
require dassdl3/sdl3_gpu_recording_boost

def render_quad(device : SDL_GPUDevice?; pipeline, target, vb, ib, vertex_texture, texture, sampler : uint64) {
    var black : SDL_FColor
    black.a = 1.0
    var buffers <- array<uint64>(vb)
    var offsets <- array<uint>(0u)
    var vertex_images <- array<uint64>(vertex_texture)
    var fragment_images <- array<uint64>(texture)
    var samplers <- array<uint64>(sampler)
    var transform <- array<float4>(float4(0.75,0.0,0.0,0.125),float4(0.0,0.75,0.0,-0.125))
    var tint <- array<float4>(float4(1.0,0.5,1.0,1.0))
    let scope_ok_0 = device |> with_gpu_command_buffer() $(command : uint64) {
        var operation_result_1 <- device |> gpu_push_uniform(command,SDL_GPUShaderStage.SHADERSTAGE_VERTEX,0u,transform)
        if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
        var operation_result_2 <- device |> gpu_push_uniform(command,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,0u,tint)
        if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
        let render_pass = unwrap_or(device |> gpu_begin_render_pass(command,target,uint2(0u),SDL_GPULoadOp.LOADOP_CLEAR,black), 0ul)
        var operation_result_3 <- device |> gpu_bind_pipeline(render_pass,pipeline)
        if (is_err(operation_result_3)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_3).message}\n"); return err(unwrap_err(operation_result_3),type<SdlUnit>) }
        var operation_result_4 <- device |> gpu_bind_vertex_buffers(render_pass,0u,buffers,offsets)
        if (is_err(operation_result_4)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_4).message}\n"); return err(unwrap_err(operation_result_4),type<SdlUnit>) }
        var operation_result_5 <- device |> gpu_bind_index_buffer(render_pass,ib)
        if (is_err(operation_result_5)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_5).message}\n"); return err(unwrap_err(operation_result_5),type<SdlUnit>) }
        var operation_result_6 <- device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_VERTEX,vertex_images,samplers)
        if (is_err(operation_result_6)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_6).message}\n"); return err(unwrap_err(operation_result_6),type<SdlUnit>) }
        var operation_result_7 <- device |> gpu_bind_samplers(render_pass,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,fragment_images,samplers)
        if (is_err(operation_result_7)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_7).message}\n"); return err(unwrap_err(operation_result_7),type<SdlUnit>) }
        // Two triangles, two direct draw calls in one real SDL render render_pass.
        var operation_result_8 <- device |> gpu_draw_indexed_primitives(render_pass,3u)
        if (is_err(operation_result_8)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_8).message}\n"); return err(unwrap_err(operation_result_8),type<SdlUnit>) }
        var operation_result_9 <- device |> gpu_draw_indexed_primitives(render_pass,3u,1u,3u)
        if (is_err(operation_result_9)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_9).message}\n"); return err(unwrap_err(operation_result_9),type<SdlUnit>) }
        var operation_result_10 <- device |> gpu_end_render_pass(render_pass)
        if (is_err(operation_result_10)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_10).message}\n"); return err(unwrap_err(operation_result_10),type<SdlUnit>) }
        var operation_result_11 <- device |> gpu_submit_command_buffer(command)
        if (is_err(operation_result_11)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_11).message}\n"); return err(unwrap_err(operation_result_11),type<SdlUnit>) }

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    var bytes : array<uint8>
    resize(bytes,64*64*4)
    let scope_ok_1 = device |> with_gpu_texture_readback(target,uint2(0u),uint4(0u,0u,64u,64u)) $(ticket : uint64) {
        var operation_result_12 <- device |> gpu_wait_readback(ticket)
        if (is_err(operation_result_12)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_12).message}\n"); return err(unwrap_err(operation_result_12),type<SdlUnit>) }
        var operation_result_13 <- device |> gpu_readback_bytes(ticket,bytes)
        if (is_err(operation_result_13)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_13).message}\n"); return err(unwrap_err(operation_result_13),type<SdlUnit>) }

        return sdl_ok()
    }
    if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") }
    verify(int(bytes[(24*64+24)*4]) == 128)
    verify(int(bytes[(24*64+48)*4+1]) >= 127 && int(bytes[(24*64+48)*4+1]) <= 128)
    verify(bytes[0] == uint8(0) && bytes[3] == uint8(255))
}

def run(device : SDL_GPUDevice?; linear : bool) {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/bindings"
    var vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    var fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    vi.num_samplers = 1u; vi.num_uniform_buffers = 1u
    fi.num_samplers = 1u; fi.num_uniform_buffers = 1u
    let scope_ok_2 = device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex : uint64) {
        let scope_ok_3 = device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment : uint64) {
            var layouts : array<SDL_GPUVertexBufferDescription>
            resize(layouts,1); layouts[0].pitch = 16u
            var attributes : array<SDL_GPUVertexAttribute>
            resize(attributes,2)
            attributes[0].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
            attributes[1].format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2
            attributes[1].location = 1u; attributes[1].offset = 8u
            var colors : array<SDL_GPUColorTargetDescription>
            push(colors,gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
            let scope_ok_4 = device |> with_gpu_graphics_pipeline(vertex,fragment,gpu_graphics_pipeline_info(),layouts,attributes,colors) $(pipeline : uint64) {
                var vertices <- array<float>(-0.75,0.75,0.0,0.0, 0.75,0.75,1.0,0.0, 0.75,-0.75,1.0,1.0, -0.75,-0.75,0.0,1.0)
                var indices <- array<uint>(0u,1u,2u,0u,2u,3u)
                let scope_ok_5 = device |> with_gpu_vertex_buffer(vertices) $(vb : uint64) {
                    let scope_ok_6 = device |> with_gpu_index_buffer(indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) $(ib : uint64) {
                        let scope_ok_7 = device |> with_gpu_rgba_texture(1u,1u) $(vertex_texture : uint64) {
                            var vertex_color <- array<uint8>(uint8(128),uint8(255),uint8(128),uint8(255))
                            var operation_result_14 <- device |> gpu_upload_texture(vertex_texture,uint2(0u),uint4(0u,0u,1u,1u),vertex_color,4u)
                            if (is_err(operation_result_14)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_14).message}\n"); return err(unwrap_err(operation_result_14),type<SdlUnit>) }
                            let scope_ok_8 = device |> with_gpu_rgba_texture(2u,2u) $(texture : uint64) {
                                var image <- array<uint8>(uint8(255),uint8(0),uint8(0),uint8(255), uint8(0),uint8(255),uint8(0),uint8(255),
                                    uint8(0),uint8(0),uint8(255),uint8(255), uint8(255),uint8(255),uint8(255),uint8(255))
                                var operation_result_15 <- device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,2u,2u),image,8u)
                                if (is_err(operation_result_15)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_15).message}\n"); return err(unwrap_err(operation_result_15),type<SdlUnit>) }
                                let filter_mode = linear ? SDL_GPUFilter.FILTER_LINEAR : SDL_GPUFilter.FILTER_NEAREST
                                let scope_ok_9 = device |> with_gpu_sampler(gpu_sampler_info(filter_mode)) $(sampler : uint64) {
                                    let scope_ok_10 = device |> with_gpu_color_target_texture(64u,64u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target : uint64) {
                                        render_quad(device,pipeline,target,vb,ib,vertex_texture,texture,sampler)

                                        return sdl_ok()
                                    }
                                    if (is_err(scope_ok_10)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_10).message}\n") ; return err(unwrap_err(scope_ok_10),type<SdlUnit>) }

                                    return sdl_ok()
                                }
                                if (is_err(scope_ok_9)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_9).message}\n") ; return err(unwrap_err(scope_ok_9),type<SdlUnit>) }

                                return sdl_ok()
                            }
                            if (is_err(scope_ok_8)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_8).message}\n") ; return err(unwrap_err(scope_ok_8),type<SdlUnit>) }

                            return sdl_ok()
                        }
                        if (is_err(scope_ok_7)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_7).message}\n") ; return err(unwrap_err(scope_ok_7),type<SdlUnit>) }

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
    if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") }
}

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_11 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            run(device,false)
            print("Texture/sampler and uniform bindings: {SDL_GetGPUDeviceDriver(device)}\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_11)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_11).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
