options gen2
module texture_payload shared public
require ./multipass_support.das public
require ./mesh_data.das
// Offline container: dimensions, mip count and 256-byte-pitched, 512-byte-aligned levels.
def load_texture_payload(device : SDL_GPUDevice?; file : string; format : SDL_GPUTextureFormat) : $Result<SDL_GPUTexture?; SdlError> {
 let bytes <- load_file("{SDL_GetBasePath()}assets/bgfx/{file}") |> sdl_try
 if (length(bytes) < 16) { return err(SdlError(operation = file, message = "Truncated texture"), type<SDL_GPUTexture?>) }
 let w = mesh_u32(bytes, 0); let h = mesh_u32(bytes, 4); let levels = mesh_u32(bytes, 8)
 var info = gpu_texture(w, h, format, SDL_GPU_TEXTUREUSAGE_SAMPLER); info.num_levels = levels
 var tex = SDL_CreateGPUTextureRef(device, info)
 if (tex == null){return err(sdl_error("SDL_CreateGPUTexture"), type<SDL_GPUTexture?>)}
 let status = sdl_scope() {
  var transfer : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(size = uint(length(bytes)))) |> sdl_use
  sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, uint(length(bytes)), 0u, bytes, false), "Texture payload") |> sdl_try
  var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
  with_native_gpu_copy_pass(command) $(var pass_) {
   var mip_width = w; var mip_height = h
   for (level in 0u..levels) {
    let at = 16 + int(level) * 16
    SDL_UploadToGPUTextureRef(pass_, SDL_GPUTextureTransferInfo(transfer_buffer = transfer, offset = mesh_u32(bytes, at), pixels_per_row = mesh_u32(bytes, at + 4), rows_per_layer = mesh_u32(bytes, at + 8)), SDL_GPUTextureRegion(texture = tex, mip_level = level, w = mip_width, h = mip_height, d = 1u), false)
    mip_width = max(1u, mip_width / 2u); mip_height = max(1u, mip_height / 2u)
   }
   return sdl_ok()
  } |> sdl_try
  return native_gpu_submit(command)
 }
 if (is_err(status)) { SDL_ReleaseGPUTexture(device, tex); return err(unwrap_err(status), type<SDL_GPUTexture?>) }
 return <- move_ok(tex, type<SdlError>)
}
