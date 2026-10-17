options gen2
require ../examples/gpu_port_forge/common/scene_app.das
require ../examples/gpu_port_forge/example_11_compute_shaders/plasma_app.das
require dassdl3/sdl3_init_boost
require daslib/defer

def save_capture(name : string; bytes : array<uint8>) : SdlStatus {
    let folder=hint_string("DASSDL3_FORGE_CAPTURE") |> unwrap_or("")
    if(folder!=""){return save_file("{folder}/{name}.rgba",bytes)}
    return sdl_ok()
}
def capture_scene(device : SDL_GPUDevice?; var scene : Scene; var target : SDL_GPUTexture?; settings : Settings) {
    with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
        render_scene(device,command,scene,target,320u,240u,0.0,settings) |> sdl_try
        return native_gpu_submit(command)
    } |> sdl_try
    return <- read_image(device,target,320u,240u)
}
def check_scene(device : SDL_GPUDevice?; lesson : int) : SdlStatus {
    return with_scene(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,lesson) $(var scene) {
        return sdl_scope(){
            var target : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(320u,240u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var settings=defaults(lesson)
            let first <- capture_scene(device,scene,target,settings) |> sdl_try
            save_capture("forge_{lesson}_default",first) |> sdl_try
            if(lesson==10){settings.ambient=0.0;settings.specular=0.0}
            elif(lesson==12){settings.show_grid=false}
            elif(lesson==13){settings.box_count=1u;settings.duck_count=1u}
            else{settings.reflectivity=0.0}
            let second <- capture_scene(device,scene,target,settings) |> sdl_try
            save_capture("forge_{lesson}_changed",second) |> sdl_try
            var changed=0;var visible=0
            for(i in 0..320*240){
                let j=i*4
                if(abs(int(first[j])-int(second[j]))+abs(int(first[j+1])-int(second[j+1]))+abs(int(first[j+2])-int(second[j+2]))>6){changed++}
                if(uint(first[j])>20u || uint(first[j+1])>20u || uint(first[j+2])>25u){visible++}
            }
            if(changed<128 || visible<1000){return failure("Forge {lesson}","Insufficient visible/effect pixels: {visible}, {changed}")}
            if(lesson==12){
                settings.show_grid=true;settings.show_objects=false;settings.spacing=0.5
                let grid <- capture_scene(device,scene,target,settings) |> sdl_try;save_capture("forge_12_grid",grid) |> sdl_try
            }
            if(lesson==14){
                settings.show_objects=false;let sky <- capture_scene(device,scene,target,settings) |> sdl_try;save_capture("forge_14_sky",sky) |> sdl_try
            }
            print("Forge {lesson}: {visible} visible, {changed} changed pixels.\n")
            return sdl_ok()
        }
    }
}
def check_compute(device : SDL_GPUDevice?) : SdlStatus {
    return with_plasma_pipeline(device) $(var pipeline){
        return sdl_scope(){
            var image : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(264u,200u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE|SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
            for(round in 0..2){
                with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){
                    let targets <- array(SDL_GPUColorTargetInfo(texture=image,clear_color=SDL_FColor(r=1.0,b=1.0,a=1.0),load_op=SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE))
                    with_native_gpu_render_pass(command,targets) $(var pass_){return sdl_ok()} |> sdl_try
                    dispatch_plasma(command,pipeline,image,257u,193u,float(round)*1.25) |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let bytes <- read_image(device,image,264u,200u) |> sdl_try
                for(y in 0..200){for(x in 0..264){if(x>=257 || y>=193){let i=(y*264+x)*4;if(bytes[i]!=uint8(255) || bytes[i+1]!=uint8(0) || bytes[i+2]!=uint8(255) || bytes[i+3]!=uint8(255)){return failure("Plasma","Out-of-range compute write")}}}}
                save_capture("forge_11_{round}",bytes) |> sdl_try
            }
            print("Forge 11: non-multiple dispatch and untouched guard pixels PASS.\n")
            return sdl_ok()
        }
    }
}
[export]
def main(smoke : bool) : int {
    let result=sdl_scope(){
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(),true,"") |> sdl_use
        for(lesson in fixed_array(10,12,13,14)){check_scene(device,lesson) |> sdl_try}
        return check_compute(device)
    }
    if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    print("Forge five-lesson pixel contracts PASS\n");return 0
}
