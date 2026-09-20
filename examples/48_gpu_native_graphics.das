options gen2
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

def draw_frames(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : bool {
    let spirv=(SDL_GetGPUShaderFormats(device)&SDL_GPU_SHADERFORMAT_SPIRV)!=0u
    let ext=spirv ? "spv" : "dxil"
    let base="{SDL_GetBasePath()}assets/shaders/triangle"
    var shader : SDL_GPUShaderCreateInfo
    shader.format=spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    shader.stage=SDL_GPUShaderStage.SHADERSTAGE_VERTEX
    var vertex=SDL_LoadGPUShaderFile(device,shader,"{base}.vert.{ext}","main")
    if (vertex==null) { return false }
    {
        defer() { SDL_ReleaseGPUShader(device,vertex) }
        shader.stage=SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT
        var fragment=SDL_LoadGPUShaderFile(device,shader,"{base}.frag.{ext}","main")
        if (fragment==null) { return false }
        {
            defer() { SDL_ReleaseGPUShader(device,fragment) }
            var info : SDL_GPUGraphicsPipelineCreateInfo
            info.vertex_shader=vertex; info.fragment_shader=fragment
            info.primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST
            info.rasterizer_state.enable_depth_clip=true
            var buffers : array<SDL_GPUVertexBufferDescription>
            var attributes : array<SDL_GPUVertexAttribute>
            var colors : array<SDL_GPUColorTargetDescription>; resize(colors,1)
            colors[0].format=SDL_GetGPUSwapchainTextureFormat(device,window)
            let pipeline=SDL_CreateGPUGraphicsPipelineArrays(device,info,buffers,attributes,colors)
            if (pipeline==null) { return false }
            {
                defer() { SDL_ReleaseGPUGraphicsPipeline(device,pipeline) }
                var success=true
                var frame=0
                while (frame<(smoke ? 3 : 180)) {
                    let acquired=with_native_gpu_swapchain(device,window) $(command; var texture; width,height) {
                        var targets : array<SDL_GPUColorTargetInfo>; resize(targets,1)
                        targets[0].texture=texture; targets[0].load_op=SDL_GPULoadOp.LOADOP_CLEAR
                        targets[0].store_op=SDL_GPUStoreOp.STOREOP_STORE
                        targets[0].clear_color.r=0.05; targets[0].clear_color.b=0.15; targets[0].clear_color.a=1.0
                        let begun=with_native_gpu_render_pass(command,targets) $(render_pass : SDL_GPURenderPass?) {
                            SDL_BindGPUGraphicsPipeline(render_pass,pipeline)
                            SDL_DrawGPUPrimitives(render_pass,3u,1u,0u,0u)

                            return sdl_ok()
                        }
                        if (is_err(begun)) { success=false ; return err(unwrap_err(begun),type<SdlUnit>) }

                        return sdl_ok()
                    }
                    if (!is_ok(acquired) || !success) { return false }
                    SDL_PumpEvents(); SDL_Delay(16u); frame++
                }
                return SDL_WaitForGPUIdle(device)
            }
        }
    }
}

[export]
def main(smoke : bool) : int {
    var success=false
    let initialized=with_sdl() {
        let opened=with_window("Native SDL GPU triangle",640,480,0ul) $(window : SDL_Window?) {
            let created=with_native_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
                if (!SDL_ClaimWindowForGPUDevice(device,window)) {return err(sdl_error("48_gpu_native_graphics"),type<SdlUnit>)}
                { defer() { SDL_ReleaseWindowFromGPUDevice(device,window) }; success=draw_frames(device,window,smoke) }

                return sdl_ok()
            }
            if (is_err(created)) { print("GPU device: {unwrap_err(created).message}\n") ; return err(unwrap_err(created),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(opened)) { print("Window: {unwrap_err(opened).message}\n") ; return err(unwrap_err(opened),type<SdlUnit>) }

        return sdl_ok()
    }
    if (!is_ok(initialized) || !success) { print("Native graphics: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n"); return 1 }
    print("Native graphics PASS\n"); return 0
}
