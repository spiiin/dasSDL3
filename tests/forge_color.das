options gen2
require ../examples/gpu_port_forge/common/scene_app.das
require dassdl3/sdl3_init_boost
require daslib/defer

def color_capture(device : SDL_GPUDevice?; lesson : int; srgb : bool) {
    let format=srgb ? SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB : SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM
    var bytes : array<uint8>
    with_scene(device,format,lesson) $(var scene){
        return sdl_scope(){
            var target : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(1280u,720u,format,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){
                render_scene(device,command,scene,target,1280u,720u,0.0,defaults(lesson)) |> sdl_try
                return native_gpu_submit(command)
            } |> sdl_try
            bytes <- read_image(device,target,1280u,720u) |> sdl_try
            return sdl_ok()
        }
    } |> sdl_try
    return <- move_ok(bytes,type<SdlError>)
}
def encode_srgb(linear : float) : float {
    if(linear<=0.0031308){return linear*12.92}
    return 1.055*pow(linear,1.0/2.4)-0.055
}
[export]
def main(smoke : bool) : int {
    let result=sdl_scope(){
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
        // Check the actual window setup as well as offscreen transfer encoding.
        with_window("Forge sRGB contract",64,64,SDL_WINDOW_HIDDEN) $(window){
            sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"Claim sRGB test window") |> sdl_try
            {
                defer(){SDL_ReleaseWindowFromGPUDevice(device,window)}
                configure_forge_swapchain(device,window) |> sdl_try
                if(SDL_WindowSupportsGPUSwapchainComposition(device,window,SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR_LINEAR)){
                    let format=SDL_GetGPUSwapchainTextureFormat(device,window)
                    if(format!=SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB && format!=SDL_GPUTextureFormat.TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB){return failure("sRGB swapchain","SDR_LINEAR setup did not select an sRGB format")}
                }
                return sdl_ok()
            }
        } |> sdl_try
        let folder=hint_string("DASSDL3_FORGE_COLOR_CAPTURE") |> unwrap_or("")
        let tag=hint_string("DASSDL3_FORGE_COLOR_TAG") |> unwrap_or("port")
        for(lesson in fixed_array(10,14)){
            let linear <- color_capture(device,lesson,false) |> sdl_try
            let encoded <- color_capture(device,lesson,true) |> sdl_try
            if(folder!=""){
                save_file("{folder}/{tag}_{lesson}_linear.rgba",linear) |> sdl_try
                save_file("{folder}/{tag}_{lesson}_srgb.rgba",encoded) |> sdl_try
            }
            var wrong=0
            for(i in 0..1280*720){for(c in 0..3){
                let value=float(uint(linear[i*4+c]))
                let low=encode_srgb(max(0.0,(value-0.5)/255.0))*255.0-1.5
                let high=encode_srgb(min(1.0,(value+0.5)/255.0))*255.0+1.5
                let actual=float(uint(encoded[i*4+c]))
                if(actual<low || actual>high){wrong++}
            }}
            if(wrong!=0){return failure("sRGB regression","{wrong} color channels differ from the sRGB transfer function")}
            print("Forge {lesson}: linear/sRGB output transfer PASS.\n")
        }
        return sdl_ok()
    }
    if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
