#pragma once
#include "sdl3_video.h"

namespace das {
template <> struct cast_arg<SDL_GUID> {
    static SDL_GUID to(Context & context,SimNode * node) {
        return *reinterpret_cast<const SDL_GUID *>(node->evalPtr(context));
    }
};
}

inline SDL_VirtualJoystickDesc SDL_MakeVirtualJoystickDesc() {
    SDL_VirtualJoystickDesc value{}; value.version=sizeof(value); return value;
}
inline SDL_JoystickID SDL_AttachVirtualJoystickArrays(const SDL_VirtualJoystickDesc & source,const char * name,
        const das::TArray<SDL_VirtualJoystickTouchpadDesc> & touchpads,
        const das::TArray<SDL_VirtualJoystickSensorDesc> & sensors) {
    if(touchpads.size>UINT16_MAX || sensors.size>UINT16_MAX) {SDL_SetError("Too many virtual touchpads or sensors");return 0;}
    // Pinned virtual Update loops use Uint8 indices; 256 would wrap forever.
    if(source.naxes>255 || source.nbuttons>255 || source.nballs>255 || source.nhats>255) {
        SDL_SetError("SDL 3.2.18 virtual control counts must not exceed 255");return 0;
    }
    auto desc=source;desc.name=name;
    desc.ntouchpads=uint16_t(touchpads.size);desc.nsensors=uint16_t(sensors.size);
    desc.touchpads=reinterpret_cast<const SDL_VirtualJoystickTouchpadDesc *>(touchpads.data);
    desc.sensors=reinterpret_cast<const SDL_VirtualJoystickSensorDesc *>(sensors.data);
    return SDL_AttachVirtualJoystick(&desc);
}
inline bool SDL_GetJoysticksCopy(das::TArray<uint32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int n=0;auto * p=SDL_GetJoysticks(&n);return sdl3_video::copy_array(p,n,out,ctx,at);
}
inline bool SDL_GetGamepadsCopy(das::TArray<uint32_t> & out,das::Context * ctx,das::LineInfoArg * at) {
    int n=0;auto * p=SDL_GetGamepads(&n);return sdl3_video::copy_array(p,n,out,ctx,at);
}
inline char * SDL_GUIDString(const SDL_GUID & guid,das::Context * ctx,das::LineInfoArg * at) {
    char text[33];SDL_GUIDToString(guid,text,sizeof(text));return sdl3_init_hints::copy(text,ctx,at);
}
inline void SDL_GetJoystickGUIDInfoRef(const SDL_GUID & guid,uint32_t & vendor,uint32_t & product,uint32_t & version,uint32_t & crc) {
    uint16_t v=0,p=0,r=0,c=0;SDL_GetJoystickGUIDInfo(guid,&v,&p,&r,&c);vendor=v;product=p;version=r;crc=c;
}
inline bool SDL_GetJoystickAxisInitialStateRef(SDL_Joystick * j,int axis,int32_t & state) {
    if(axis<0){state=0;return SDL_SetError("Negative joystick axis");}
    int16_t value=0;bool known=SDL_GetJoystickAxisInitialState(j,axis,&value);state=value;return known;
}
inline bool SDL_GetJoystickBallRef(SDL_Joystick * j,int ball,int32_t & x,int32_t & y) {x=y=0;if(ball<0)return SDL_SetError("Negative joystick ball");return SDL_GetJoystickBall(j,ball,&x,&y);}
inline SDL_PowerState SDL_GetJoystickPowerInfoRef(SDL_Joystick * j,int32_t & percent) {return SDL_GetJoystickPowerInfo(j,&percent);}
inline SDL_PowerState SDL_GetGamepadPowerInfoRef(SDL_Gamepad * g,int32_t & percent) {return SDL_GetGamepadPowerInfo(g,&percent);}
inline bool SDL_GetGamepadTouchpadFingerRef(SDL_Gamepad * g,int pad,int finger,bool & down,float & x,float & y,float & pressure) {
    down=false;x=y=pressure=0;return SDL_GetGamepadTouchpadFinger(g,pad,finger,&down,&x,&y,&pressure);
}
inline bool SDL_GetGamepadSensorDataArray(SDL_Gamepad * g,SDL_SensorType type,das::TArray<float> & data) {
    if(!data.size || !data.data || data.size>INT_MAX) return SDL_SetError("Sensor array requires positive native count and valid storage");
    return SDL_GetGamepadSensorData(g,type,reinterpret_cast<float *>(data.data),int(data.size));
}
inline bool SDL_SendJoystickVirtualSensorDataArray(SDL_Joystick * j,SDL_SensorType type,uint64_t timestamp,const das::TArray<float> & data) {
    if(!data.size || !data.data || data.size>INT_MAX) return SDL_SetError("Sensor array requires positive native count and valid storage");
    return SDL_SendJoystickVirtualSensorData(j,type,timestamp,reinterpret_cast<const float *>(data.data),int(data.size));
}
inline bool SDL_SendJoystickEffectArray(SDL_Joystick * j,const das::TArray<uint8_t> & data) {
    if(data.size>INT_MAX) return SDL_SetError("Effect exceeds native byte count limit");
    return SDL_SendJoystickEffect(j,data.data,int(data.size));
}
inline bool SDL_SendGamepadEffectArray(SDL_Gamepad * g,const das::TArray<uint8_t> & data) {
    if(data.size>INT_MAX) return SDL_SetError("Effect exceeds native byte count limit");
    return SDL_SendGamepadEffect(g,data.data,int(data.size));
}
inline bool SDL_GetGamepadBindingsCopy(SDL_Gamepad * g,das::TArray<SDL_GamepadBinding> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;auto ** p=SDL_GetGamepadBindings(g,&count);
    std::unique_ptr<SDL_GamepadBinding *,decltype(&SDL_free)> owned(p,SDL_free);
    das::builtin_array_resize(out,0,sizeof(SDL_GamepadBinding),ctx,at);
    if(!p)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(SDL_GamepadBinding))return SDL_SetError("Too many gamepad bindings");
    das::builtin_array_resize(out,count,sizeof(SDL_GamepadBinding),ctx,at);
    auto * dest=reinterpret_cast<SDL_GamepadBinding *>(out.data);
    for(int i=0;i<count;++i)dest[i]=*p[i];
    return true;
}
// Read only the active native union alternative: index, minimum/mask, maximum.
inline das::int3 SDL_GamepadBindingInput(const SDL_GamepadBinding & b) {
    switch(b.input_type) {
    case SDL_GAMEPAD_BINDTYPE_BUTTON:return {b.input.button,0,0};
    case SDL_GAMEPAD_BINDTYPE_AXIS:return {b.input.axis.axis,b.input.axis.axis_min,b.input.axis.axis_max};
    case SDL_GAMEPAD_BINDTYPE_HAT:return {b.input.hat.hat,b.input.hat.hat_mask,0};
    default:return {};
    }
}
inline das::int3 SDL_GamepadBindingOutput(const SDL_GamepadBinding & b) {
    switch(b.output_type) {
    case SDL_GAMEPAD_BINDTYPE_BUTTON:return {int(b.output.button),0,0};
    case SDL_GAMEPAD_BINDTYPE_AXIS:return {int(b.output.axis.axis),b.output.axis.axis_min,b.output.axis.axis_max};
    default:return {};
    }
}
inline bool SDL_GetGamepadMappingsCopy(das::TArray<char *> & out,das::Context * ctx,das::LineInfoArg * at) {
    int count=0;char ** p=SDL_GetGamepadMappings(&count);
    std::unique_ptr<char *,decltype(&SDL_free)> owned(p,SDL_free);
    das::builtin_array_resize(out,0,sizeof(char *),ctx,at);
    if(!p)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(char *))return SDL_SetError("Too many gamepad mappings");
    das::builtin_array_resize(out,count,sizeof(char *),ctx,at);
    auto ** dest=reinterpret_cast<char **>(out.data);
    for(int i=0;i<count;++i)dest[i]=sdl3_init_hints::copy(p[i],ctx,at);
    return true;
}
inline bool SDL_GetGamepadMappingValue(SDL_Gamepad * g,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    std::unique_ptr<char,decltype(&SDL_free)> owned(SDL_GetGamepadMapping(g),SDL_free);
    out=sdl3_init_hints::copy(owned.get(),ctx,at);return owned!=nullptr;
}

inline bool SDL_GetJoystickNameValue(SDL_Joystick * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * source=SDL_GetJoystickName(device);out=sdl3_init_hints::copy(source,ctx,at);return source!=nullptr;
}

inline bool SDL_GetJoystickPathValue(SDL_Joystick * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * source=SDL_GetJoystickPath(device);out=sdl3_init_hints::copy(source,ctx,at);return source!=nullptr;
}

inline bool SDL_GetJoystickSerialValue(SDL_Joystick * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * source=SDL_GetJoystickSerial(device);out=sdl3_init_hints::copy(source,ctx,at);return source!=nullptr;
}

inline bool SDL_GetGamepadNameValue(SDL_Gamepad * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * source=SDL_GetGamepadName(device);out=sdl3_init_hints::copy(source,ctx,at);return source!=nullptr;
}

inline bool SDL_GetGamepadPathValue(SDL_Gamepad * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * source=SDL_GetGamepadPath(device);out=sdl3_init_hints::copy(source,ctx,at);return source!=nullptr;
}

inline bool SDL_GetGamepadSerialValue(SDL_Gamepad * device,char *& out,das::Context * ctx,das::LineInfoArg * at) {
    const char * source=SDL_GetGamepadSerial(device);out=sdl3_init_hints::copy(source,ctx,at);return source!=nullptr;
}
