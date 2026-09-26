options gen2
require dassdl3/sdl3_vulkan_metal
require dassdl3/sdl3_boost
[export]
def main(smoke : bool) : int {
    // Do not call raw GetInstanceExtensions here: the pinned SDL getter requires a loaded backend.
    verify(SDL_WasInit(SDL_INIT_VIDEO)==0u)
    verify(is_err(vulkan_instance_extensions()))
    verify(SDL_SetHintWithPriority(SDL_HINT_VIDEO_DRIVER,"dummy",SDL_HintPriority.HINT_OVERRIDE))
    verify(SDL_Init(SDL_INIT_VIDEO))
    verify(!SDL_Vulkan_LoadLibrary("dasSDL3-missing-vulkan-library.dll"))
    verify(SDL_Vulkan_GetVkGetInstanceProcAddr()==null)
    var entered=false
    let failed=with_vulkan_library("") {entered=true;return sdl_ok()}
    verify(is_err(failed) && !entered)
    verify(is_err(vulkan_instance_extensions()))
    var surface : VkSurfaceKHR_T? = null
    unsafe {verify(!SDL_Vulkan_CreateSurface(null,null,null,addr(surface)))}
    verify(surface==null)
    SDL_Vulkan_DestroySurface(null,null,null)
    verify(!SDL_Vulkan_GetPresentationSupport(null,null,0u))
    let scoped=with_vulkan_surface(null,null) $(value) {entered=true;return sdl_ok()}
    verify(is_err(scoped) && !entered)
    verify(is_err(create_vulkan_surface(null,null)))
    destroy_vulkan_surface(null,surface)
    verify(surface==null)
    let window=SDL_CreateWindow("Metal unavailable",16,16,SDL_WINDOW_HIDDEN)
    verify(window!=null)
    verify(SDL_Metal_CreateView(window)==null)
    verify(SDL_Metal_GetLayer(null)==null)
    SDL_Metal_DestroyView(null)
    verify(is_err(create_metal_view(window)))
    verify(is_err(metal_layer(null)))
    let metal=with_metal_view(window) $(view) {entered=true;return sdl_ok()}
    verify(is_err(metal) && !entered)
    SDL_DestroyWindow(window)
    SDL_Vulkan_UnloadLibrary()
    SDL_Quit()
    print("Vulkan/Metal: unavailable-backend errors and skipped scopes passed.\n")
    return 0
}
