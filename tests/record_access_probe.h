#pragma once
#include <SDL3/SDL.h>
#include <array>
namespace sdl3_record_test {
inline int cookie=0;
inline int calls[8]{};
inline bool good=true;
inline void count(void *data,int i) {good=good && data==&cookie;++calls[i];}
inline void SDLCALL update(void *p) {count(p,0);}
inline void SDLCALL player(void *p,int i) {if(i==7) count(p,1);}
inline bool SDLCALL rumble(void *p,Uint16 a,Uint16 b) {if(a==123 && b==456) count(p,2);return true;}
inline bool SDLCALL triggers(void *p,Uint16 a,Uint16 b) {if(a==123 && b==456) count(p,3);return true;}
inline bool SDLCALL led(void *p,Uint8 r,Uint8 g,Uint8 b) {good=good && r==12 && g==34 && b==56;count(p,4);return true;}
inline bool SDLCALL effect(void *p,const void *data,int n) {good=good && n==3 && static_cast<const Uint8 *>(data)[0]==42;count(p,5);return true;}
inline bool SDLCALL sensor(void *p,bool enabled) {if(enabled) count(p,6);return true;}
inline void SDLCALL cleanup(void *p) {count(p,7);}
inline std::array<Uint8,512> bytes{};
}
inline void *SDLTestRecordCookie() {return &sdl3_record_test::cookie;}
inline void *SDLTestRecordCallback(int i) {
 using namespace sdl3_record_test;
 switch(i) {
 case 0:return reinterpret_cast<void *>(update);case 1:return reinterpret_cast<void *>(player);
 case 2:return reinterpret_cast<void *>(rumble);case 3:return reinterpret_cast<void *>(triggers);
 case 4:return reinterpret_cast<void *>(led);case 5:return reinterpret_cast<void *>(effect);
 case 6:return reinterpret_cast<void *>(sensor);case 7:return reinterpret_cast<void *>(cleanup);
 default:return nullptr;
 }
}
inline int SDLTestRecordCount(int i) {return i>=0 && i<8 ? sdl3_record_test::calls[i] : -1;}
inline bool SDLTestRecordGood() {return sdl3_record_test::good;}
inline SDL_Surface *SDLTestRecordSurface(SDL_PixelFormat format,int w,int h,int pitch) {
 sdl3_record_test::bytes.fill(0xA5);
 if(format==SDL_PIXELFORMAT_P010) {
   // Pinned SDL cannot allocate P010 in CalculateYUVSize, but cameras can supply it.
   auto *s=SDL_CreateSurfaceFrom(1,1,SDL_PIXELFORMAT_RGBA32,sdl3_record_test::bytes.data(),4);
   if(s) {s->w=w;s->h=h;s->pitch=pitch;s->format=format;} return s;
 }
 return SDL_CreateSurfaceFrom(w,h,format,sdl3_record_test::bytes.data(),pitch);
}
inline int SDLTestRecordByte(int offset) {return offset>=0 && offset<512 ? sdl3_record_test::bytes[offset] : -1;}
inline bool SDLTestRecordLocked(SDL_Surface *s) {return s && (s->flags & SDL_SURFACE_LOCKED)!=0;}
inline bool SDLTestRecordOptions(const SDL_GPUVulkanOptions &o) {
 return o.vulkan_api_version==4194304u && !o.feature_list && !o.vulkan_10_physical_device_features &&
        o.device_extension_count==0 && !o.device_extension_names && o.instance_extension_count==0 && !o.instance_extension_names;
}
