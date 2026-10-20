options gen2
require ../examples/gpu_port_forge/common/advanced_app.das
require dassdl3/sdl3_init_boost
require daslib/defer

def advanced_capture(device : SDL_GPUDevice?; var scene : AdvancedScene; var target : SDL_GPUTexture?; settings : AdvancedSettings; time : float=0.0) {
    with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){
        render_advanced(device,command,scene,target,1280u,720u,time,settings) |> sdl_try
        return native_gpu_submit(command)
    } |> sdl_try
    return <- read_image(device,target,1280u,720u)
}
def save_advanced(name : string; bytes : array<uint8>) : SdlStatus {
    let folder=hint_string("DASSDL3_FORGE_ADVANCED_CAPTURE") |> unwrap_or("")
    if(folder!=""){return save_file("{folder}/{name}.rgba",bytes)}
    return sdl_ok()
}
def advanced_contract(device : SDL_GPUDevice?; lesson : int) : SdlStatus {
    return with_advanced(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,lesson) $(var scene){
        return sdl_scope(){
            var target : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(1280u,720u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var settings=advanced_defaults(lesson)
            let first <- advanced_capture(device,scene,target,settings) |> sdl_try
            save_advanced("forge_{lesson}_default",first) |> sdl_try
            settings.effect=false
            if(lesson==17){settings.normal_mode=1.0}
            let second <- advanced_capture(device,scene,target,settings) |> sdl_try
            save_advanced("forge_{lesson}_changed",second) |> sdl_try
            var changed=0;var visible=0
            for(i in 0..1280*720){
                let j=i*4
                if(abs(int(first[j])-int(second[j]))+abs(int(first[j+1])-int(second[j+1]))+abs(int(first[j+2])-int(second[j+2]))>6){changed++}
                if(first[j]!=first[0] || first[j+1]!=first[1] || first[j+2]!=first[2]){visible++}
            }
            if(changed<24 || visible<1000){return failure("Forge {lesson}","Effect or geometry missing: {changed} changed, {visible} visible pixels")}
            if(lesson==15){
                for(i in 0..3){settings.preview=i;let image <- advanced_capture(device,scene,target,settings) |> sdl_try;save_advanced("forge_15_cascade_{i}",image) |> sdl_try}
            }
            if(lesson==17){settings.normal_mode=0.0;let flat <- advanced_capture(device,scene,target,settings) |> sdl_try;save_advanced("forge_17_flat",flat) |> sdl_try}
            if(lesson==19){let moving <- advanced_capture(device,scene,target,settings,1.0) |> sdl_try;save_advanced("forge_19_moving",moving) |> sdl_try}
            if(lesson==20){for(mode in 1..3){settings.effect=true;settings.fog_mode=float(mode);let image <- advanced_capture(device,scene,target,settings) |> sdl_try;save_advanced("forge_20_mode_{mode}",image) |> sdl_try}}
            print("Forge {lesson}: {visible} visible, {changed} effect pixels PASS.\n")
            return sdl_ok()
        }
    }
}
[export]
def main(smoke : bool) : int {
    let result=sdl_scope(){
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
        for(lesson in 15..21){advanced_contract(device,lesson) |> sdl_try}
        return sdl_ok()
    }
    if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
