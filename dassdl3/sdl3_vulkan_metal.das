options gen2
require daslib/defer
module sdl3_vulkan_metal shared public
require dassdl3/sdl3_result public

def public vulkan_instance_extensions() {
    var names : array<string>
    if (!SDL_Vulkan_GetInstanceExtensionsCopy(names)) {return err(sdl_error("SDL_Vulkan_GetInstanceExtensions"), type<array<string>>)}
    return <- move_ok(names, type<SdlError>)
}
def public with_vulkan_library(path : string; body : block<() : $Result<auto(T); SdlError>>) {
    let loaded = empty(path) ? SDL_Vulkan_LoadLibraryDefault() : SDL_Vulkan_LoadLibrary(path)
    if (!loaded) {return err(sdl_error("SDL_Vulkan_LoadLibrary"), type<T>)}
    {
        defer() {SDL_Vulkan_UnloadLibrary()}
        return <- body()
    }
}
def public create_vulkan_surface(window : SDL_Window?; instance : VkInstance_T?; allocator : VkAllocationCallbacks const? = null) {
    var surface : VkSurfaceKHR_T? = null
    if (!SDL_Vulkan_CreateSurfaceRef(window, instance, allocator, surface)) {return err(sdl_error("SDL_Vulkan_CreateSurface"), type<VkSurfaceKHR_T?>)}
    return <- move_ok(surface, type<SdlError>)
}
// Void SDL destruction has no error result. Instance/allocator must match creation.
def public destroy_vulkan_surface(instance : VkInstance_T?; var surface : VkSurfaceKHR_T?&; allocator : VkAllocationCallbacks const? = null) {
    SDL_Vulkan_DestroySurfaceRef(instance, surface, allocator)
}
def public with_vulkan_surface(window : SDL_Window?; instance : VkInstance_T?; allocator : VkAllocationCallbacks const?;
                               body : block<(surface : VkSurfaceKHR_T?) : $Result<auto(T); SdlError>>) {
    var surface : VkSurfaceKHR_T? = null
    if (!SDL_Vulkan_CreateSurfaceRef(window, instance, allocator, surface)) {return err(sdl_error("SDL_Vulkan_CreateSurface"), type<T>)}
    {
        defer() {SDL_Vulkan_DestroySurface(instance, surface, allocator)}
        return <- body(surface)
    }
}
def public with_vulkan_surface(window : SDL_Window?; instance : VkInstance_T?;
                               body : block<(surface : VkSurfaceKHR_T?) : $Result<auto(T); SdlError>>) {
    return <- with_vulkan_surface(window, instance, null, body)
}
def public create_metal_view(window : SDL_Window?) {
    var view = SDL_Metal_CreateView(window)
    if (view == null) {return err(sdl_error("SDL_Metal_CreateView"), type<void?>)}
    return <- move_ok(view, type<SdlError>)
}
def public metal_layer(view : void?) {
    var layer = SDL_Metal_GetLayer(view)
    if (layer == null) {return err(sdl_error("SDL_Metal_GetLayer"), type<void?>)}
    return <- move_ok(layer, type<SdlError>)
}
def public with_metal_view(window : SDL_Window?; body : block<(view : void?) : $Result<auto(T); SdlError>>) {
    let view = SDL_Metal_CreateView(window)
    if (view == null) {return err(sdl_error("SDL_Metal_CreateView"), type<T>)}
    {
        defer() {SDL_Metal_DestroyView(view)}
        return <- body(view)
    }
}
