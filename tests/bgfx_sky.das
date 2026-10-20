options gen2
require ../examples/gpu_port_bgfx/example_27_sky/sky_app.das as demo
require bgfx_multipass_checks
require bgfx_buffer_checks
require daslib/defer

def render(device : SDL_GPUDevice?; var r : demo::Resources; settings : demo::Settings; name : string; time : float = 0.6; width : uint = 640u; height : uint = 480u) {
 return sdl_scope() {
  var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
  sdl_scope() {
   var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
   demo::draw(device, command, r, output, width, height, time, settings) |> sdl_try
   return native_gpu_submit(command)
  } |> sdl_try
  return read_image(device, output, width, height, name)
 }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
 return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
 verify(length(demo::sun_direction(12.0,50.0,5)-float3(0.450541,-0.892755,0.0))<0.0001,"Sun controller differs from bx quaternion convention")
 verify(length(demo::sky_luminance(12.0)-float3(0.972385,1.0,1.798389))<0.000001,"Sky table differs from upstream")
 verify(abs(demo::sun_luminance(6.0).y-6.4946965)<0.00001,"Sun interpolation differs from upstream")
 verify(r.grid.count==5766u,"Expected the upstream 32x32 sky grid")
 var settings = demo::Settings(prevent_banding=false)
 let clear <- render(device, r, settings, "sky-clear") |> sdl_try; visible(clear)
 settings.mode = 1
 let hazy <- render(device, r, settings, "sky-hazy") |> sdl_try; visible(hazy); verify(changed(clear, hazy) > 10000, "Turbidity has no effect")
 settings.mode = 0
 let moved <- render(device, r, settings, "sky-sunset", 12.0) |> sdl_try; verify(changed(clear, moved) > 10000, "Sun direction has no effect")
 settings.mode = 2
 let dither <- render(device, r, settings, "sky-dither") |> sdl_try; verify(changed(clear, dither, 0) > 100, "Dithering has no effect")
 settings.mode = 0; settings.landscape = false
 let sky_only <- render(device, r, settings, "sky-no-landscape") |> sdl_try
 verify(changed(clear, sky_only) > 10000, "Landscape missing")
 settings.landscape = true; settings.lightmap = false
 let unoccluded <- render(device, r, settings, "sky-no-lightmap") |> sdl_try
 verify(changed(clear, unoccluded) > 1000, "Landscape lightmap missing")
 verify(r.mesh.count == 7680u, "Original landscape mesh not loaded")
 settings.lightmap=true;settings.month=0
 let winter <- render(device,r,settings,"sky-winter",12.0) |> sdl_try
 settings.month=5;settings.latitude=0.0
 let equator <- render(device,r,settings,"sky-equator",12.0) |> sdl_try
 verify(changed(winter,equator)>10000,"Calendar/latitude has no effect")
 let odd <- render(device, r, settings, "sky-odd", 0.6, 641u, 479u) |> sdl_try; visible(odd)
 return sdl_ok()
 }
}
[export]
def main(unused : bool) : int {
 let result = sdl_scope() {
  with_sdl(SDL_INIT_VIDEO) |> sdl_use
  let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
  return check(device)
 }
 if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
 print("sky: GPU regression PASS\n"); return 0
}
