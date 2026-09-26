options gen2
require dassdl3/sdl3_record_access
require dassdl3/sdl3_try
require daslib/defer

def run() {
    var config=SDL_GPUVulkanOptions(vulkan_api_version=4194304u)
    verify(SDLTestRecordOptions(config))
    config.device_extension_count=3u;config.instance_extension_count=4u
    config.feature_list=SDLTestRecordCookie();config.vulkan_10_physical_device_features=SDLTestRecordCookie()
    unsafe {
        var names : string[1]
        config.device_extension_names=addr(names[0]);config.instance_extension_names=addr(names[0])
    }
    verify(config.device_extension_count==3u && config.instance_extension_count==4u && config.feature_list!=null && config.vulkan_10_physical_device_features!=null && config.device_extension_names!=null && config.instance_extension_names!=null)
    config=SDL_GPUVulkanOptions(vulkan_api_version=4194304u)
    let props=SDL_CreateProperties();verify(props!=0u)
    defer() {SDL_DestroyProperties(props)}
    verify(SDL_SetStringProperty(props,SDL_PROP_GPU_DEVICE_CREATE_NAME_STRING,"vulkan"))
    verify(SDL_SetBooleanProperty(props,SDL_PROP_GPU_DEVICE_CREATE_SHADERS_SPIRV_BOOLEAN,true))
    // Pinned SDL_CopyProperties would copy this internal cache pointer and double-free it.
    verify(SDL_SetNumberProperty(props,"dassdl3.cache_probe",7l))
    verify(SDL_GetStringProperty(props,"dassdl3.cache_probe","")=="7")
    var empty : array<string>
    let device=create_gpu_device_with_vulkan_options(props,config,empty,empty) |> sdl_try
    verify(SDL_GetGPUDeviceDriver(device)=="vulkan")
    verify(SDL_WaitForGPUIdle(device));SDL_DestroyGPUDevice(device)
    verify(!SDL_HasProperty(props,SDL_PROP_GPU_DEVICE_CREATE_VULKAN_OPTIONS_POINTER))
    // The exact original raw path can use a native-address property during creation.
    unsafe {verify(SDL_SetPointerProperty(props,SDL_PROP_GPU_DEVICE_CREATE_VULKAN_OPTIONS_POINTER,addr(config)))}
    let raw=SDL_CreateGPUDeviceWithProperties(props);verify(raw!=null)
    SDL_DestroyGPUDevice(raw)
    verify(SDL_ClearProperty(props,SDL_PROP_GPU_DEVICE_CREATE_VULKAN_OPTIONS_POINTER))
    var missing <- array<string>("VK_DASSDL3_nonexistent_extension")
    let bad_device=create_gpu_device_with_vulkan_options(props,config,missing,empty)
    verify(is_err(bad_device))
    let bad_instance=create_gpu_device_with_vulkan_options(props,config,empty,missing)
    verify(is_err(bad_instance))
    verify(SDLTestRecordOptions(config) && missing[0]=="VK_DASSDL3_nonexistent_extension")
    return sdl_ok()
}
[export]
def main(smoke : bool) : int {
    verify(SDL_Init(SDL_INIT_VIDEO))
    let result=run()
    SDL_Quit()
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    print("Vulkan config: native fields, device creation and missing-extension errors passed\n")
    return 0
}
