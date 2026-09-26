options gen2
module sdl3_ttf_boost shared public
require sdl3_ttf public
require dassdl3/sdl3_result public
require daslib/defer

// Font IO is borrowed until CloseFont; engine and font must outlive every text.
// Scope blocks borrow resources and must not destroy or retain them.
def public with_ttf(blk : block<() : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    if (!TTF_Init()) { return err(sdl_error("TTF_Init"),type<TtfScopeValue>) }
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { TTF_Quit() }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk() }
        else { result <- blk() }
    }
    return <- result
}

def public open_font(path : string; size : float) {
    var value = TTF_OpenFont(path,size)
    if (value == null) { return err(sdl_error("TTF_OpenFont"),type<TTF_Font?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_font(path : string; size : float; blk : block<(value : TTF_Font?) : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    var loaded = open_font(path,size)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TtfScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { TTF_CloseFont(value) }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public open_font(io : SDL_IOStream?; size : float) {
    var value = TTF_OpenFontIO(io,false,size)
    if (value == null) { return err(sdl_error("TTF_OpenFontIO"),type<TTF_Font?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_font(io : SDL_IOStream?; size : float; blk : block<(value : TTF_Font?) : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    var loaded = open_font(io,size)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TtfScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { TTF_CloseFont(value) }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_renderer_text_engine(renderer : SDL_Renderer?) {
    var value = TTF_CreateRendererTextEngine(renderer)
    if (value == null) { return err(sdl_error("TTF_CreateRendererTextEngine"),type<TTF_TextEngine?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_renderer_text_engine(renderer : SDL_Renderer?; blk : block<(value : TTF_TextEngine?) : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    var loaded = create_renderer_text_engine(renderer)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TtfScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { TTF_DestroyRendererTextEngine(value) }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_surface_text_engine() {
    var value = TTF_CreateSurfaceTextEngine()
    if (value == null) { return err(sdl_error("TTF_CreateSurfaceTextEngine"),type<TTF_TextEngine?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_surface_text_engine(blk : block<(value : TTF_TextEngine?) : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    var loaded = create_surface_text_engine()
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TtfScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { TTF_DestroySurfaceTextEngine(value) }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_gpu_text_engine(device : SDL_GPUDevice?) {
    var value = TTF_CreateGPUTextEngine(device)
    if (value == null) { return err(sdl_error("TTF_CreateGPUTextEngine"),type<TTF_TextEngine?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_gpu_text_engine(device : SDL_GPUDevice?; blk : block<(value : TTF_TextEngine?) : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    var loaded = create_gpu_text_engine(device)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TtfScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { TTF_DestroyGPUTextEngine(value) }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public create_text(engine : TTF_TextEngine?; font : TTF_Font?; text : string) {
    var value = TTF_CreateText(engine,font,text,0ul)
    if (value == null) { return err(sdl_error("TTF_CreateText"),type<TTF_Text?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_text(engine : TTF_TextEngine?; font : TTF_Font?; text : string; blk : block<(value : TTF_Text?) : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    var loaded = create_text(engine,font,text)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TtfScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { TTF_DestroyText(value) }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public render_text_surface(font : TTF_Font?; text : string; color : SDL_Color) {
    var native_color = color
    var value = TTF_RenderText_Blended(font,text,0ul,native_color)
    if (value == null) { return err(sdl_error("TTF_RenderText_Blended"),type<SDL_Surface?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_text_surface(font : TTF_Font?; text : string; color : SDL_Color; blk : block<(value : SDL_Surface?) : $Result<auto(TtfScopeValue); SdlError>>) : $Result<TtfScopeValue; SdlError> {
    var loaded = render_text_surface(font,text,color)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TtfScopeValue>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TtfScopeValue; SdlError>
    {
        defer() { SDL_DestroySurface(value) }
        static_if (typeinfo can_copy(type<$Result<TtfScopeValue; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public text_size(text : TTF_Text?) {
    var size : int2
    if (!TTF_GetTextSizeRef(text,size)) { return err(sdl_error("TTF_GetTextSize"),type<int2>) }
    return ok(size,type<SdlError>)
}

def public string_size(font : TTF_Font?; text : string) {
    var size : int2
    if (!TTF_GetStringSizeRef(font,text,size)) { return err(sdl_error("TTF_GetStringSize"),type<int2>) }
    return ok(size,type<SdlError>)
}

def public set_text(text : TTF_Text?; value : string) {
    return sdl_status(TTF_SetTextString(text,value,0ul),"TTF_SetTextString")
}

def public draw_text(text : TTF_Text?; x,y : float) {
    return sdl_status(TTF_DrawRendererText(text,x,y),"TTF_DrawRendererText")
}

def public draw_text(text : TTF_Text?; x,y : int; surface : SDL_Surface?) {
    return sdl_status(TTF_DrawSurfaceText(text,x,y,surface),"TTF_DrawSurfaceText")
}

def public set_text_color(text : TTF_Text?; color : uint4) {
    return sdl_status(TTF_SetTextColor(text,uint8(color.x),uint8(color.y),uint8(color.z),uint8(color.w)),"TTF_SetTextColor")
}

struct FontGlyphMetrics {
    bounds : int4
    advance : int
}

def public glyph_metrics(font : TTF_Font?; codepoint : uint) {
    var metrics : FontGlyphMetrics
    if (!TTF_GetGlyphMetricsRef(font,codepoint,metrics.bounds,metrics.advance)) {
        return err(sdl_error("TTF_GetGlyphMetrics"),type<FontGlyphMetrics>)
    }
    return ok(metrics,type<SdlError>)
}

def public set_font_direction(font : TTF_Font?; direction : TTF_Direction) {
    return sdl_status(TTF_SetFontDirection(font,direction),"TTF_SetFontDirection")
}

def public set_text_direction(text : TTF_Text?; direction : TTF_Direction) {
    return sdl_status(TTF_SetTextDirection(text,direction),"TTF_SetTextDirection")
}

def public set_font_script(font : TTF_Font?; script : string) {
    return sdl_status(TTF_SetFontScript(font,TTF_StringToTag(script)),"TTF_SetFontScript")
}

def public set_text_script(text : TTF_Text?; script : string) {
    return sdl_status(TTF_SetTextScript(text,TTF_StringToTag(script)),"TTF_SetTextScript")
}

def public set_font_language(font : TTF_Font?; language : string) {
    return sdl_status(TTF_SetFontLanguage(font,language),"TTF_SetFontLanguage")
}

// Direct copy of one native draw sequence. The atlas is still borrowed, not owned.
// Reacquire after text/font changes; submit draws before mutating/destroying them.
struct TtfGpuDrawSequence {
    xy : array<float2>
    uv : array<float2>
    indices : array<int>
    atlas_texture : SDL_GPUTexture?
    image_type : TTF_ImageType
}

def public gpu_text_draw_data(text : TTF_Text?) {
    var result : array<TtfGpuDrawSequence>
    var cursor : TTF_GPUAtlasDrawSequence?
    if (!TTF_GetGPUTextDrawDataRef(text,cursor)) {
        return err(sdl_error("TTF_GetGPUTextDrawData"),type<array<TtfGpuDrawSequence>>)
    }
    while (cursor != null) {
        var item : TtfGpuDrawSequence
        var next : TTF_GPUAtlasDrawSequence?
        if (!TTF_CopyGPUAtlasDrawSequence(cursor,item.xy,item.uv,item.indices,item.atlas_texture,item.image_type,next)) {
            return err(sdl_error("TTF_CopyGPUAtlasDrawSequence"),type<array<TtfGpuDrawSequence>>)
        }
        emplace(result,item)
        cursor = next
    }
    return <- move_ok(result,type<SdlError>)
}
