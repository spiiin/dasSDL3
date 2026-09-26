options gen2
module sdl3_render_surface_34_boost shared public
require dassdl3/sdl3_surface_pixels_boost public
require dassdl3/sdl3_renderer_final_boost public
require daslib/option public
require daslib/defer

struct RenderTextureAddressModes {
    u, v : SDL_TextureAddressMode
}
def public default_texture_scale_mode(renderer : SDL_Renderer?) {
    var mode : SDL_ScaleMode
    if(!SDL_GetDefaultTextureScaleModeRef(renderer,mode)) { return err(sdl_error("SDL_GetDefaultTextureScaleMode"),type<SDL_ScaleMode>) }
    return ok(mode,type<SdlError>)
}
def public render_texture_address_mode(renderer : SDL_Renderer?) {
    var modes : RenderTextureAddressModes
    if(!SDL_GetRenderTextureAddressModeRef(renderer,modes.u,modes.v)) { return err(sdl_error("SDL_GetRenderTextureAddressMode"),type<RenderTextureAddressModes>) }
    return ok(modes,type<SdlError>)
}
def public set_default_texture_scale_mode(renderer : SDL_Renderer?; mode : SDL_ScaleMode) {
    return sdl_status(SDL_SetDefaultTextureScaleMode(renderer,mode),"SDL_SetDefaultTextureScaleMode")
}
def public set_render_texture_address_mode(renderer : SDL_Renderer?; u,v : SDL_TextureAddressMode) {
    return sdl_status(SDL_SetRenderTextureAddressMode(renderer,u,v),"SDL_SetRenderTextureAddressMode")
}
def public set_texture_palette(texture : SDL_Texture?; palette : SDL_Palette?) {
    return sdl_status(SDL_SetTexturePalette(texture,palette),"SDL_SetTexturePalette")
}
// Borrowed palette: a valid non-indexed texture normally has no palette.
// Preserve errors for invalid textures rather than treating every NULL as None.
def public texture_palette(texture : SDL_Texture?) {
    SDL_ClearError()
    var palette=SDL_GetTexturePalette(texture)
    if(palette!=null) { var value <- move_some(palette); return <- move_ok(value,type<SdlError>) }
    if(length(SDL_GetError())!=0) { return err(sdl_error("SDL_GetTexturePalette"),type<$Option<SDL_Palette?>>) }
    var value=none(type<SDL_Palette?>); return <- move_ok(value,type<SdlError>)
}
def public save_png(surface : SDL_Surface?; path : string) { return sdl_status(SDL_SavePNG(surface,path),"SDL_SavePNG") }
// IO remains caller-owned. Raw SDL_SavePNG_IO exposes consuming closeio.
def public save_png(surface : SDL_Surface?; io : SDL_IOStream?) { return sdl_status(SDL_SavePNG_IO(surface,io,false),"SDL_SavePNG_IO") }
def public render_texture_9grid_tiled(renderer : SDL_Renderer?; texture : SDL_Texture?; src : SDL_FRect;
    left,right,top,bottom,scale : float; dst : SDL_FRect; tile_scale : float) {
    return sdl_status(SDL_RenderTexture9GridTiledRefs(renderer,texture,src,left,right,top,bottom,scale,dst,tile_scale),"SDL_RenderTexture9GridTiled")
}
def public set_gpu_render_state(renderer : SDL_Renderer?; state : SDL_GPURenderState?) {
    return sdl_status(SDL_SetGPURenderState(renderer,state),"SDL_SetGPURenderState")
}
def public set_gpu_render_state_fragment_uniforms(state : SDL_GPURenderState?; slot : uint; data : array<uint8>) {
    return sdl_status(SDL_SetGPURenderStateFragmentUniformBytes(state,slot,data),"SDL_SetGPURenderStateFragmentUniforms")
}
def public set_gpu_render_state_fragment_uniforms(state : SDL_GPURenderState?; slot : uint; data : array<float>) {
    return sdl_status(SDL_SetGPURenderStateFragmentUniformFloats(state,slot,data),"SDL_SetGPURenderStateFragmentUniforms")
}

def public with_loaded_surface(path : string; body : block<(resource : SDL_Surface?) : $Result<auto(T); SdlError>>) {
    let resource=SDL_LoadSurface(path)
    if(resource==null) { return err(sdl_error("SDL_LoadSurface"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { SDL_DestroySurface(resource) }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) { result=body(resource) }
        else { result <- body(resource) }
    }
    return <- result
}

def public with_loaded_surface(io : SDL_IOStream?; body : block<(resource : SDL_Surface?) : $Result<auto(T); SdlError>>) {
    let resource=SDL_LoadSurface_IO(io,false)
    if(resource==null) { return err(sdl_error("SDL_LoadSurface_IO"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { SDL_DestroySurface(resource) }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) { result=body(resource) }
        else { result <- body(resource) }
    }
    return <- result
}

def public with_png(path : string; body : block<(resource : SDL_Surface?) : $Result<auto(T); SdlError>>) {
    let resource=SDL_LoadPNG(path)
    if(resource==null) { return err(sdl_error("SDL_LoadPNG"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { SDL_DestroySurface(resource) }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) { result=body(resource) }
        else { result <- body(resource) }
    }
    return <- result
}

def public with_png(io : SDL_IOStream?; body : block<(resource : SDL_Surface?) : $Result<auto(T); SdlError>>) {
    let resource=SDL_LoadPNG_IO(io,false)
    if(resource==null) { return err(sdl_error("SDL_LoadPNG_IO"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { SDL_DestroySurface(resource) }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) { result=body(resource) }
        else { result <- body(resource) }
    }
    return <- result
}

def public with_rotated_surface(source : SDL_Surface?; angle : float; body : block<(resource : SDL_Surface?) : $Result<auto(T); SdlError>>) {
    let resource=SDL_RotateSurface(source,angle)
    if(resource==null) { return err(sdl_error("SDL_RotateSurface"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { SDL_DestroySurface(resource) }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) { result=body(resource) }
        else { result <- body(resource) }
    }
    return <- result
}

def public with_gpu_renderer(device : SDL_GPUDevice?; window : SDL_Window?; body : block<(resource : SDL_Renderer?) : $Result<auto(T); SdlError>>) {
    let resource=SDL_CreateGPURenderer(device,window)
    if(resource==null) { return err(sdl_error("SDL_CreateGPURenderer"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { SDL_DestroyRenderer(resource) }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) { result=body(resource) }
        else { result <- body(resource) }
    }
    return <- result
}

def public with_gpu_render_state(renderer : SDL_Renderer?; shader : SDL_GPUShader?; samplers : array<SDL_GPUTextureSamplerBinding>; textures : array<SDL_GPUTexture?>; buffers : array<SDL_GPUBuffer?>; props : uint; body : block<(resource : SDL_GPURenderState?) : $Result<auto(T); SdlError>>) {
    let resource=SDL_CreateGPURenderStateArrays(renderer,shader,samplers,textures,buffers,props)
    if(resource==null) { return err(sdl_error("SDL_CreateGPURenderStateArrays"),type<T>) }
    var result : $Result<T; SdlError>
    {
        defer() { SDL_SetGPURenderState(renderer,null); SDL_DestroyGPURenderState(resource) }
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) { result=body(resource) }
        else { result <- body(resource) }
    }
    return <- result
}
