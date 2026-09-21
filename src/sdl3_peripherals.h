#pragma once
#include "sdl3_video.h"
#include <cwchar>

// Native pointer lifetimes and SDL thread rules apply. These helpers do not retain script storage.
inline bool SDL_GetTouchDevicesCopy(das::TArray<uint64_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;auto * p=SDL_GetTouchDevices(&count);
    return sdl3_video::copy_array(p,count,out,ctx,at);
}
inline bool SDL_GetSensorsCopy(das::TArray<uint32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;auto * p=SDL_GetSensors(&count);
    return sdl3_video::copy_array(p,count,out,ctx,at);
}
inline bool SDL_GetHapticsCopy(das::TArray<uint32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;auto * p=SDL_GetHaptics(&count);
    return sdl3_video::copy_array(p,count,out,ctx,at);
}
inline bool SDL_GetTouchFingersCopy(uint64_t id,das::TArray<SDL_Finger> & out,das::Context * ctx,das::LineInfoArg * at) {
    das::builtin_array_resize(out,0,sizeof(SDL_Finger),ctx,at);
    int count=0;auto ** p=SDL_GetTouchFingers(id,&count);
    std::unique_ptr<SDL_Finger *,decltype(&SDL_free)> owner(p,SDL_free);
    if(!p)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(SDL_Finger))return SDL_SetError("Too many touch fingers");
    das::builtin_array_resize(out,count,sizeof(SDL_Finger),ctx,at);
    auto * dest=reinterpret_cast<SDL_Finger *>(out.data);
    for(int i=0;i<count;++i)dest[i]=*p[i];
    return true;
}
inline bool SDL_GetSensorDataArray(SDL_Sensor * sensor,das::TArray<float> & out) {
    if(out.size>INT_MAX)return SDL_SetError("Sensor data exceeds native count range");
    return SDL_GetSensorData(sensor,reinterpret_cast<float *>(out.data),int(out.size));
}
inline bool SDL_HapticEffectSupportedRef(SDL_Haptic * h,const SDL_HapticEffect & e) {return SDL_HapticEffectSupported(h,&e);}
inline int SDL_CreateHapticEffectRef(SDL_Haptic * h,const SDL_HapticEffect & e) {return SDL_CreateHapticEffect(h,&e);}
inline bool SDL_UpdateHapticEffectRef(SDL_Haptic * h,int id,const SDL_HapticEffect & e) {return SDL_UpdateHapticEffect(h,id,&e);}
inline SDL_hid_device_info * SDL_HidNext(SDL_hid_device_info * info) {return info?info->next:nullptr;}
inline char * SDL_HidWideString(const uint16_t * text,das::Context * ctx,das::LineInfoArg * at) {
    static_assert(sizeof(wchar_t)==sizeof(uint16_t),"Windows UTF-16 contract");
    if(!text)return sdl3_init_hints::copy("",ctx,at);
    auto * wide=reinterpret_cast<const wchar_t *>(text);
    char * utf8=SDL_iconv_string("UTF-8","WCHAR_T",reinterpret_cast<const char *>(wide),(std::wcslen(wide)+1)*sizeof(wchar_t));
    std::unique_ptr<char,decltype(&SDL_free)> owner(utf8,SDL_free);
    return sdl3_init_hints::copy(utf8?utf8:"",ctx,at);
}
inline char * SDL_HidInfoString(SDL_hid_device_info * info,int field,das::Context * ctx,das::LineInfoArg * at) {
    if(!info)return sdl3_init_hints::copy("",ctx,at);
    if(field==0)return sdl3_init_hints::copy(info->path?info->path:"",ctx,at);
    auto * text=field==1?info->serial_number:field==2?info->manufacturer_string:info->product_string;
    return SDL_HidWideString(reinterpret_cast<const uint16_t *>(text),ctx,at);
}
inline SDL_HapticEffect SDL_MakeHapticConstantEffect(const SDL_HapticConstant & value) { SDL_HapticEffect out{};out.constant=value;out.type=SDL_HAPTIC_CONSTANT;return out;}
inline SDL_HapticEffect SDL_MakeHapticPeriodicEffect(const SDL_HapticPeriodic & value) { SDL_HapticEffect out{};out.periodic=value;return out;}
inline SDL_HapticEffect SDL_MakeHapticConditionEffect(const SDL_HapticCondition & value) { SDL_HapticEffect out{};out.condition=value;return out;}
inline SDL_HapticEffect SDL_MakeHapticRampEffect(const SDL_HapticRamp & value) { SDL_HapticEffect out{};out.ramp=value;out.type=SDL_HAPTIC_RAMP;return out;}
inline SDL_HapticEffect SDL_MakeHapticLeftRightEffect(const SDL_HapticLeftRight & value) { SDL_HapticEffect out{};out.leftright=value;out.type=SDL_HAPTIC_LEFTRIGHT;return out;}
inline SDL_HapticEffect SDL_MakeHapticCustomEffect(const SDL_HapticCustom & value) { SDL_HapticEffect out{};out.custom=value;out.type=SDL_HAPTIC_CUSTOM;return out;}
inline int SDL_hid_writeArray(SDL_hid_device * d,const das::TArray<uint8_t> & data) { if(data.size==0 || data.size>INT_MAX){SDL_SetError("HID buffer must contain 1..INT_MAX bytes");return -1;} return SDL_hid_write(d,reinterpret_cast<const unsigned char *>(data.data),data.size); }
inline int SDL_hid_readArray(SDL_hid_device * d,das::TArray<uint8_t> & data) { if(data.size==0 || data.size>INT_MAX){SDL_SetError("HID buffer must contain 1..INT_MAX bytes");return -1;} return SDL_hid_read(d,reinterpret_cast<unsigned char *>(data.data),data.size); }
inline int SDL_hid_send_feature_reportArray(SDL_hid_device * d,const das::TArray<uint8_t> & data) { if(data.size==0 || data.size>INT_MAX){SDL_SetError("HID buffer must contain 1..INT_MAX bytes");return -1;} return SDL_hid_send_feature_report(d,reinterpret_cast<const unsigned char *>(data.data),data.size); }
inline int SDL_hid_get_feature_reportArray(SDL_hid_device * d,das::TArray<uint8_t> & data) { if(data.size==0 || data.size>INT_MAX){SDL_SetError("HID buffer must contain 1..INT_MAX bytes");return -1;} return SDL_hid_get_feature_report(d,reinterpret_cast<unsigned char *>(data.data),data.size); }
inline int SDL_hid_get_input_reportArray(SDL_hid_device * d,das::TArray<uint8_t> & data) { if(data.size==0 || data.size>INT_MAX){SDL_SetError("HID buffer must contain 1..INT_MAX bytes");return -1;} return SDL_hid_get_input_report(d,reinterpret_cast<unsigned char *>(data.data),data.size); }
inline int SDL_hid_get_report_descriptorArray(SDL_hid_device * d,das::TArray<uint8_t> & data) { if(data.size==0 || data.size>INT_MAX){SDL_SetError("HID buffer must contain 1..INT_MAX bytes");return -1;} return SDL_hid_get_report_descriptor(d,reinterpret_cast<unsigned char *>(data.data),data.size); }
inline int SDL_hid_read_timeoutArray(SDL_hid_device * d,das::TArray<uint8_t> & data,int ms) {if(data.size==0 || data.size>INT_MAX){SDL_SetError("HID buffer must contain 1..INT_MAX bytes");return -1;}return SDL_hid_read_timeout(d,reinterpret_cast<unsigned char *>(data.data),data.size,ms);}

// AOT storage bridge only: the exported raw functions retain their native signatures.
inline SDL_hid_device * SDL_hid_openWide(uint16_t vendor,uint16_t product,const uint16_t * serial) {return SDL_hid_open(vendor,product,reinterpret_cast<const wchar_t *>(serial));}
inline int SDL_hid_get_manufacturer_stringWide(SDL_hid_device * d,uint16_t * text,size_t count) {return SDL_hid_get_manufacturer_string(d,reinterpret_cast<wchar_t *>(text),count);}
inline int SDL_hid_get_product_stringWide(SDL_hid_device * d,uint16_t * text,size_t count) {return SDL_hid_get_product_string(d,reinterpret_cast<wchar_t *>(text),count);}
inline int SDL_hid_get_serial_number_stringWide(SDL_hid_device * d,uint16_t * text,size_t count) {return SDL_hid_get_serial_number_string(d,reinterpret_cast<wchar_t *>(text),count);}
inline int SDL_hid_get_indexed_stringWide(SDL_hid_device * d,int index,uint16_t * text,size_t count) {return SDL_hid_get_indexed_string(d,index,reinterpret_cast<wchar_t *>(text),count);}
inline bool SDL_HidInfoCopy(SDL_hid_device_info * source,SDL_hid_device_info & out) {out={};if(!source)return false;out=*source;return true;}
inline bool SDL_GetTouchDeviceNameCopy(uint64_t device,char *& out,das::Context * ctx,das::LineInfoArg * at) {auto * text=SDL_GetTouchDeviceName(device);out=sdl3_init_hints::copy(text,ctx,at);return text!=nullptr;}
inline bool SDL_GetSensorNameCopy(SDL_Sensor * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {auto * text=SDL_GetSensorName(device);out=sdl3_init_hints::copy(text,ctx,at);return text!=nullptr;}
inline bool SDL_GetHapticNameCopy(SDL_Haptic * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {auto * text=SDL_GetHapticName(device);out=sdl3_init_hints::copy(text,ctx,at);return text!=nullptr;}
