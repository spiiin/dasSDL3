options gen2
require daslib/defer
require dassdl3/sdl3_vulkan_metal
require dassdl3/sdl3_boost
require dassdl3/sdl3_scope

def check_surface(window : SDL_Window?; instance : VkInstance_T?; address : void?) : $Result<SdlUnit; SdlError> {
    let device=SDLTestVkPhysical(instance,address)
    verify(device!=null)
    let queue=SDLTestVkQueue(instance,device,address)
    verify(queue>=0)
    let allocator=SDLTestVkAllocator()
    verify(SDLTestVkLive()==0)
    var raw : VkSurfaceKHR_T? = null
    unsafe {verify(SDL_Vulkan_CreateSurface(window,instance,allocator,addr(raw)))}
    verify(raw!=null && SDLTestVkLive()>0)
    let actual=SDLTestVkSupport(instance,device,uint(queue),raw,address)
    verify(actual>=0)
    verify(SDL_Vulkan_GetPresentationSupport(instance,device,uint(queue))==(actual!=0))
    SDL_Vulkan_DestroySurface(instance,raw,allocator)
    verify(SDLTestVkLive()==0)
    raw=null
    var surface=window |> create_vulkan_surface(instance) |> sdl_try
    verify(surface!=null)
    destroy_vulkan_surface(instance,surface)
    verify(surface==null)
    let early=window |> with_vulkan_surface(instance,allocator) $(value) {
        verify(value!=null && SDLTestVkLive()>0)
        return err(SdlError(operation="body",message="early exit"),type<SdlUnit>)
    }
    verify(is_err(early) && unwrap_err(early).message=="early exit" && SDLTestVkLive()==0)
    var moved <- window |> with_vulkan_surface(instance) $(value) {
        var result <- array<int>(actual,queue)
        return <- move_ok(result,type<SdlError>)
    }
    verify(is_ok(moved))
    var result <- move_unwrap(moved)
    verify(result[0]==actual && result[1]==queue)
    return sdl_ok()
}
def use_instance(window : SDL_Window?) : $Result<SdlUnit; SdlError> {
    var names <- vulkan_instance_extensions() |> sdl_try
    verify(length(names)>0)
    var count=0u
    // Only inspect the borrowed array while the loader and video backend are alive.
    unsafe {
        let native_names=SDL_Vulkan_GetInstanceExtensions(addr(count))
        verify(native_names!=null && count==uint(length(names)))
    }
    let address=SDL_Vulkan_GetVkGetInstanceProcAddr()
    verify(address!=null)
    let instance=SDLTestVkCreateInstance(address,names)
    if(instance==null) {return err(sdl_error("vkCreateInstance"),type<SdlUnit>)}
    {
        defer() {SDLTestVkDestroyInstance(instance,address)}
        return check_surface(window,instance,address)
    }
}
[export]
def main(smoke : bool) : int {
    var saved : array<string>
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        with_vulkan_library("") |> sdl_use
        saved <- vulkan_instance_extensions() |> sdl_try
        let window : SDL_Window? = with_window("Vulkan surface",64,64,SDL_WINDOW_VULKAN | SDL_WINDOW_HIDDEN) |> sdl_use
        return use_instance(window)
    }
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    verify(length(saved)>0 && length(saved[0])>0)
    print("Vulkan: native instance, SDL surfaces, presentation and copied extensions passed.\n")
    return 0
}
