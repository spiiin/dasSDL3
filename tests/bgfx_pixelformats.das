options gen2
require ../examples/gpu_port_bgfx/example_37_pixelformats/pixelformats_app.das as demo
require bgfx_multipass_checks

def check(device : SDL_GPUDevice?) : SdlStatus {return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r){
 var count = 0
 for (sample in 0..4){var s = demo::Settings(sample = sample, alpha = false)
  sdl_scope(){var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; demo::draw_previews(command, r, s, 0.0) |> sdl_try; return native_gpu_submit(command)} |> sdl_try
  for (e in r.entries){if (e.supported && e.description.set_index == sample){let image <- read_image(device, e.preview, e.description.width, e.description.height, "pf-{sample}-{e.description.name}") |> sdl_try; if (e.description.name != "A8_UNORM"){visible(image)}; if (sample == 0 && e.description.name != "A8_UNORM") {
       let red = (228 * 256 + 8) * 4; verify(uint(image[red]) > 250u && uint(image[red + 1]) < 3u && uint(image[red + 2]) < 3u, "Red channel packing differs")
       let green = (228 * 256 + 24) * 4; verify(uint(image[green]) < 3u && uint(image[green + 2]) < 3u, "Green leaks into another channel")
       if (e.description.name != "R8_UNORM" && e.description.name != "R8_SNORM" && e.description.name != "R16_UNORM" && e.description.name != "R16_SNORM" && e.description.name != "R16_FLOAT" && e.description.name != "R32_FLOAT"){verify(uint(image[green + 1]) > 250u, "Green channel missing")}
      }; count++}}
 }
 verify(count >= 90, "Too few supported desktop formats")
 var index = 0; for (i in range(length(r.entries))){if (r.entries[i].description.set_index == 0 && r.entries[i].description.name == "R8G8B8A8_UNORM"){index = i}}
 var tex = r.entries[index].preview; let noalpha <- read_image(device, tex, 256u, 256u, "pf-noalpha") |> sdl_try
 var s = demo::Settings(alpha = true)
 sdl_scope(){var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; demo::draw_previews(command, r, s, 0.0) |> sdl_try; return native_gpu_submit(command)} |> sdl_try
 let alpha <- read_image(device, tex, 256u, 256u, "pf-alpha") |> sdl_try; verify(changed(alpha, noalpha) > 10000)
 return sdl_ok()}}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
