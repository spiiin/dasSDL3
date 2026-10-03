#include "daScript/daScript.h"
#include "../vulkan_interop_probe.h"
#include <limits>
int main() {
    using namespace sdl3_vk_test;
    for (size_t alignment : {size_t(1),size_t(8),size_t(64),size_t(4096)}) {
        void * p=allocate(nullptr,37,alignment,VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
        if(!p || reinterpret_cast<uintptr_t>(p)%alignment || live()!=1) return 1;
        SDL_memset(p,0x5a,37);
        void * failed=resize(nullptr,p,SIZE_MAX,alignment,VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
        if(failed || live()!=1) return 2;
        p=resize(nullptr,p,73,alignment,VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
        if(!p || reinterpret_cast<uintptr_t>(p)%alignment || live()!=1) return 3;
        for(size_t i=0;i<37;++i) if(static_cast<unsigned char *>(p)[i]!=0x5a) return 4;
        p=resize(nullptr,p,11,alignment,VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
        if(!p || reinterpret_cast<uintptr_t>(p)%alignment || live()!=1) return 5;
        for(size_t i=0;i<11;++i) if(static_cast<unsigned char *>(p)[i]!=0x5a) return 6;
        if(resize(nullptr,p,0,alignment,VK_SYSTEM_ALLOCATION_SCOPE_OBJECT) || live()) return 7;
    }
    return 0;
}
