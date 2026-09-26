options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_ttf_boost
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_properties_boost
require daslib/defer

def check_sequences(engine : TTF_TextEngine?; font : TTF_Font?) {
    var snapshot <- engine |> with_text(font,"Copied arrays") $(text : TTF_Text?) {
        return <- gpu_text_draw_data(text)
    } |> sdl_try
    verify(length(snapshot)>0 && length(snapshot[0].xy)>0) // CPU copy after DestroyText
    return engine |> with_text(font,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") $(text : TTF_Text?) {
        SDL_SetErrorMessage("stale error")
        var initial <- text |> gpu_text_draw_data() |> sdl_try
        verify(length(initial)>1) // deliberately small atlas: multiple pages
        var total=0
        for (item in initial) {
            verify(length(item.xy)==length(item.uv) && length(item.xy)>0)
            verify(item.atlas_texture!=null && item.image_type==TTF_ImageType.IMAGE_ALPHA)
            verify(length(item.indices)>0 && length(item.indices)%3==0)
            for (index in item.indices) { verify(index>=0 && index<length(item.xy)) }
            total += length(item.indices)
        }
        let point=initial[0].xy[0]
        text |> set_text("") |> sdl_try
        SDL_SetErrorMessage("another stale error")
        var empty <- text |> gpu_text_draw_data() |> sdl_try
        verify(length(empty)==0)
        verify(initial[0].xy[0]==point) // copied CPU arrays survive mutation
        text |> set_text("Updated") |> sdl_try
        var changed <- text |> gpu_text_draw_data() |> sdl_try
        var changed_count=0
        for (item in changed) { changed_count+=length(item.indices) }
        verify(changed_count>0 && changed_count<total)
        // Fill draw operations have no atlas and no UV storage. Preserve them.
        TTF_SetFontStyle(font,uint(TTF_STYLE_UNDERLINE))
        var decorated <- text |> gpu_text_draw_data() |> sdl_try
        var fills=0
        for (item in decorated) {
            if (item.atlas_texture==null) {
                verify(item.image_type==TTF_ImageType.IMAGE_INVALID && length(item.uv)==0 && length(item.xy)>0)
                fills++
            }
        }
        verify(fills>0)
        TTF_SetFontStyle(font,uint(TTF_STYLE_NORMAL))
        return sdl_ok()
    }
}

def check_bad_inputs(font : TTF_Font?) {
    var missing = gpu_text_draw_data(null)
    verify(is_err(missing))
    let saved=unwrap_err(missing)
    SDL_ClearError()
    verify(saved.operation=="TTF_GetGPUTextDrawData" && saved.message!="")
    with_surface_text_engine() $(engine : TTF_TextEngine?) {
        return engine |> with_text(font,"CPU engine") $(text : TTF_Text?) {
            verify(is_err(gpu_text_draw_data(text)))
            return sdl_ok()
        }
    } |> sdl_try
    // SDL_ttf 3.2.2 raw getter dereferences a null engine; boost rejects it first.
    with_text(null,font,"Measurement only") $(text : TTF_Text?) {
        verify(is_err(gpu_text_draw_data(text)))
        return sdl_ok()
    } |> sdl_try
    var xy,uv : array<float2>
    var indices : array<int>
    var atlas : SDL_GPUTexture?
    var next : TTF_GPUAtlasDrawSequence?
    var kind : TTF_ImageType
    verify(!TTF_CopyGPUAtlasDrawSequence(null,xy,uv,indices,atlas,kind,next))
    var invalid = TTF_GPUAtlasDrawSequence(num_vertices=-1)
    unsafe {
        verify(!TTF_CopyGPUAtlasDrawSequence(addr(invalid),xy,uv,indices,atlas,kind,next))
        var point = SDL_FPoint()
        var bad_index = 1
        invalid.num_vertices=1; invalid.num_indices=1
        invalid.xy=addr(point); invalid.indices=addr(bad_index)
        verify(!TTF_CopyGPUAtlasDrawSequence(addr(invalid),xy,uv,indices,atlas,kind,next))
    }
    verify(length(xy)==0 && length(uv)==0 && length(indices)==0 && atlas==null && next==null)
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        with_ttf() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/Amiri-Regular.ttf",32.0) |> sdl_use
        check_bad_inputs(font) |> sdl_try
        let failed = device |> with_gpu_text_engine() $(engine : TTF_TextEngine?) {
            return engine |> with_text(font,"Early return") $(text : TTF_Text?) {
                return err(SdlError(operation="test body",message="preserved"),type<SdlUnit>)
            }
        }
        verify(is_err(failed) && unwrap_err(failed).message=="preserved")
        return with_properties() $(props : uint) {
            unsafe { verify(SDL_SetPointerProperty(props,TTF_PROP_GPU_TEXT_ENGINE_DEVICE,reinterpret<void?>(device))) }
            verify(SDL_SetNumberProperty(props,TTF_PROP_GPU_TEXT_ENGINE_ATLAS_TEXTURE_SIZE,128l))
            var engine=TTF_CreateGPUTextEngineWithProperties(props)
            if (engine==null) { return err(sdl_error("TTF_CreateGPUTextEngineWithProperties"),type<SdlUnit>) }
            {
                defer() { TTF_DestroyGPUTextEngine(engine) }
                TTF_SetGPUTextEngineWinding(engine,TTF_GPUTextEngineWinding.GPU_TEXTENGINE_WINDING_COUNTER_CLOCKWISE)
                verify(TTF_GetGPUTextEngineWinding(engine)==TTF_GPUTextEngineWinding.GPU_TEXTENGINE_WINDING_COUNTER_CLOCKWISE)
                check_sequences(engine,font) |> sdl_try
                return sdl_status(SDL_WaitForGPUIdle(device),"SDL_WaitForGPUIdle")
            }
        }
    }
    if (is_err(result)) { let error=unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    print("GPU text arrays: multi-atlas, indices, empty/update, fills and invalid inputs PASS\n")
    return 0
}
