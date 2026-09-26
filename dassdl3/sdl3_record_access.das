options gen2
require daslib/defer
module sdl3_record_access shared public
require dassdl3/sdl3_boost public

struct public SurfaceInfo {
    flags : uint
    format : SDL_PixelFormat
    width, height, pitch : int
}
def public surface_info(surface : SDL_Surface?) {
    var flags : uint; var format : SDL_PixelFormat; var size : int3
    if (!SDL_GetSurfaceMetadata(surface, flags, format, size)) {return err(sdl_error("surface_info"), type<SurfaceInfo>)}
    return ok(SurfaceInfo(flags = flags, format = format, width = size.x, height = size.y, pitch = size.z), type<SdlError>)
}
def public palette_colors(palette : SDL_Palette?) {
    var colors : array<SDL_Color>
    if (!SDL_GetPaletteColorsCopy(palette, colors)) {return err(sdl_error("palette_colors"), type<array<SDL_Color>>)}
    return <- move_ok(colors, type<SdlError>)
}
// Layout is int4(row_bytes, rows, pitch, plane_count); storage order follows SDL's pixel format.
def public surface_plane_info(surface : SDL_Surface?; plane : int = 0) {
    var info : int4
    if (!SDL_GetSurfacePlaneInfo(surface, plane, info)) {return err(sdl_error("surface_plane_info"), type<int4>)}
    return ok(info, type<SdlError>)
}
def public with_surface_bytes(surface : SDL_Surface?; plane : int;
                              blk : block<(var bytes : array<uint8>#; layout : int4) : $Result<auto(T); SdlError>>) {
    if (!SDL_LockSurface(surface)) {return err(sdl_error("SDL_LockSurface"), type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_UnlockSurface(surface)}
        let success = SDL_WithSurfacePlaneBytes(surface, plane) $(var bytes : array<uint8>#; layout : int4) {
            static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(bytes, layout)}
            else {result <- blk(bytes, layout)}
        }
        if (!success) {return err(sdl_error("with_surface_bytes"), type<T>)}
    }
    return <- result
}
def public create_gpu_device_with_vulkan_options(props : uint; config : SDL_GPUVulkanOptions;
                                                 device_extensions, instance_extensions : array<string>) {
    var device = SDL_CreateGPUDeviceWithVulkanOptions(props, config, device_extensions, instance_extensions)
    if (device == null) {return err(sdl_error("SDL_CreateGPUDeviceWithProperties"), type<SDL_GPUDevice?>)}
    return <- move_ok(device, type<SdlError>)
}
