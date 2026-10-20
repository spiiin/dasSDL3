options gen2
require ../examples/gpu_port_bgfx/example_27_sky/sky_app.das as sky
require ../examples/gpu_port_bgfx/example_22_rsm/rsm_app.das as rsm
require bgfx_capture
require daslib/defer
[export]
def main(smoke : bool) : int {
 let result=sdl_scope(){
  with_sdl(SDL_INIT_VIDEO) |> sdl_use
  let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(),true,"") |> sdl_use
  var output : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(1280u,720u,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
  sky::with_resources(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r){
   var settings=sky::Settings(paused=true)
   with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){sky::draw(device,command,r,output,1280u,720u,12.0,settings) |> sdl_try;return native_gpu_submit(command)} |> sdl_try
   let bytes <- read_image(device,output,1280u,720u,"sky-noon") |> sdl_try
   return sdl_ok()
  } |> sdl_try
  return rsm::with_resources(device,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r){
   var settings=rsm::Settings(paused=true)
   with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){rsm::draw(device,command,r,output,1280u,720u,0.0,settings) |> sdl_try;return native_gpu_submit(command)} |> sdl_try
   let bytes <- read_image(device,output,1280u,720u,"rsm-default") |> sdl_try
   return sdl_ok()
  }
 }
 if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
 return 0
}
