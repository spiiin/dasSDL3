#pragma once
#include <vulkan/vulkan_core.h>
#include <SDL3/SDL.h>
#include <vector>
#include <algorithm>
#include <atomic>
namespace sdl3_vk_test {
inline std::atomic<int> allocations{0};
// Keep the allocation size so realloc can preserve data on every platform.
struct AllocationHeader { void * base; size_t size; };
inline void * VKAPI_PTR allocate(void *,size_t size,size_t alignment,VkSystemAllocationScope) {
    if (!alignment || (alignment & (alignment-1))) return nullptr;
    if (alignment-1 > SIZE_MAX-sizeof(AllocationHeader)) return nullptr;
    const size_t overhead=alignment-1+sizeof(AllocationHeader);
    if (size > SIZE_MAX-overhead) return nullptr;
    void * base=SDL_malloc(size+overhead);
    if (!base) return nullptr;
    const auto address=(reinterpret_cast<uintptr_t>(base)+sizeof(AllocationHeader)+alignment-1)&~(uintptr_t(alignment)-1);
    void * p=reinterpret_cast<void *>(address);
    AllocationHeader header{base,size};
    SDL_memcpy(static_cast<char *>(p)-sizeof(header),&header,sizeof(header));
    ++allocations;return p;
}
inline void VKAPI_PTR release(void *,void * p) {
    if(p) {
        AllocationHeader header;
        SDL_memcpy(&header,static_cast<char *>(p)-sizeof(header),sizeof(header));
        --allocations;SDL_free(header.base);
    }
}
inline void * VKAPI_PTR resize(void *,void * p,size_t size,size_t alignment,VkSystemAllocationScope scope) {
    if(!size) {release(nullptr,p);return nullptr;}
    if(!p) return allocate(nullptr,size,alignment,scope);
    AllocationHeader header;
    SDL_memcpy(&header,static_cast<char *>(p)-sizeof(header),sizeof(header));
    void * next=allocate(nullptr,size,alignment,scope);
    if(next) {SDL_memcpy(next,p,std::min(size,header.size));release(nullptr,p);}
    return next;
}
inline const VkAllocationCallbacks * allocator() {
    static const VkAllocationCallbacks callbacks{nullptr,allocate,resize,release,nullptr,nullptr};return &callbacks;
}
inline int live() {return allocations.load();}

inline PFN_vkGetInstanceProcAddr entry(void * address) {return reinterpret_cast<PFN_vkGetInstanceProcAddr>(address);}
inline VkInstance create(void * address,const das::TArray<char *> & names) {
    if(!address) {SDL_SetError("Missing vkGetInstanceProcAddr");return nullptr;}
    auto fn=reinterpret_cast<PFN_vkCreateInstance>(entry(address)(nullptr,"vkCreateInstance"));
    if(!fn) {SDL_SetError("Missing vkCreateInstance");return nullptr;}
    VkInstanceCreateInfo info{};info.sType=VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    info.enabledExtensionCount=names.size;info.ppEnabledExtensionNames=reinterpret_cast<const char * const *>(names.data);
    VkInstance instance=nullptr;VkResult result=fn(&info,nullptr,&instance);
    if(result!=VK_SUCCESS) {SDL_SetError("vkCreateInstance: %d",int(result));return nullptr;}
    return instance;
}
inline void destroy(VkInstance instance,void * address) {
    if(instance) reinterpret_cast<PFN_vkDestroyInstance>(entry(address)(instance,"vkDestroyInstance"))(instance,nullptr);
}
inline VkPhysicalDevice physical(VkInstance instance,void * address) {
    auto fn=reinterpret_cast<PFN_vkEnumeratePhysicalDevices>(entry(address)(instance,"vkEnumeratePhysicalDevices"));
    uint32_t count=0;if(fn(instance,&count,nullptr)!=VK_SUCCESS || !count) return nullptr;
    std::vector<VkPhysicalDevice> devices(count);
    if(fn(instance,&count,devices.data())!=VK_SUCCESS) return nullptr;
    return devices[0];
}
inline int queue(VkInstance instance,VkPhysicalDevice device,void * address) {
    auto fn=reinterpret_cast<PFN_vkGetPhysicalDeviceQueueFamilyProperties>(entry(address)(instance,"vkGetPhysicalDeviceQueueFamilyProperties"));
    uint32_t count=0;fn(device,&count,nullptr);std::vector<VkQueueFamilyProperties> props(count);fn(device,&count,props.data());
    for(uint32_t i=0;i<count;++i) if(props[i].queueCount && (props[i].queueFlags&VK_QUEUE_GRAPHICS_BIT)) return int(i);
    return -1;
}
inline int support(VkInstance instance,VkPhysicalDevice device,uint32_t queue,VkSurfaceKHR surface,void * address) {
    auto fn=reinterpret_cast<PFN_vkGetPhysicalDeviceSurfaceSupportKHR>(entry(address)(instance,"vkGetPhysicalDeviceSurfaceSupportKHR"));
    VkBool32 supported=0;return fn && fn(device,queue,surface,&supported)==VK_SUCCESS ? int(supported!=0) : -1;
}
}
