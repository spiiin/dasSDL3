options gen2
require daslib/defer
module sdl3_peripherals_boost shared public
require dassdl3/sdl3_init_boost public

def public touch_devices() {
    var values : array<uint64>
    if(!SDL_GetTouchDevicesCopy(values)) {return err(sdl_error("SDL_GetTouchDevicesCopy"),type<array<uint64>>)}
    return <- move_ok(values,type<SdlError>)
}
def public touch_fingers(id : uint64) {
    var values : array<SDL_Finger>
    if(!SDL_GetTouchFingersCopy(id,values)) {return err(sdl_error("SDL_GetTouchFingersCopy"),type<array<SDL_Finger>>)}
    return <- move_ok(values,type<SdlError>)
}
def public sensors() {
    var values : array<uint>
    if(!SDL_GetSensorsCopy(values)) {return err(sdl_error("SDL_GetSensorsCopy"),type<array<uint>>)}
    return <- move_ok(values,type<SdlError>)
}
def public haptics() {
    var values : array<uint>
    if(!SDL_GetHapticsCopy(values)) {return err(sdl_error("SDL_GetHapticsCopy"),type<array<uint>>)}
    return <- move_ok(values,type<SdlError>)
}
def public open_sensor(id : uint) {
    var value=SDL_OpenSensor(id)
    if(value==null) {return err(sdl_error("SDL_OpenSensor"),type<SDL_Sensor?>)}
    return <- move_ok(value,type<SdlError>)
}
def public with_sensor(id : uint; body : block<(device : SDL_Sensor?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let device=SDL_OpenSensor(id)
    if(device==null) {return err(sdl_error("SDL_OpenSensor"),type<TT>)}
    {
        defer() {SDL_CloseSensor(device)}
        static_if(typeinfo can_copy(type<$Result<TT; SdlError>>)) {scope_result=body(device)}
        else {scope_result <- body(device)}
    }
    return <- scope_result
}
def public open_haptic(id : uint) {
    var value=SDL_OpenHaptic(id)
    if(value==null) {return err(sdl_error("SDL_OpenHaptic"),type<SDL_Haptic?>)}
    return <- move_ok(value,type<SdlError>)
}
def public with_haptic(id : uint; body : block<(device : SDL_Haptic?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let device=SDL_OpenHaptic(id)
    if(device==null) {return err(sdl_error("SDL_OpenHaptic"),type<TT>)}
    {
        defer() {SDL_CloseHaptic(device)}
        static_if(typeinfo can_copy(type<$Result<TT; SdlError>>)) {scope_result=body(device)}
        else {scope_result <- body(device)}
    }
    return <- scope_result
}
def public touch_device_name(device : uint64) {
    var text : string
    if(!SDL_GetTouchDeviceNameCopy(device,text)) {return err(sdl_error("SDL_GetTouchDeviceNameCopy"),type<string>)}
    return ok(text,type<SdlError>)
}
def public sensor_name(device : SDL_Sensor?) {
    var text : string
    if(!SDL_GetSensorNameCopy(device,text)) {return err(sdl_error("SDL_GetSensorNameCopy"),type<string>)}
    return ok(text,type<SdlError>)
}
def public haptic_name(device : SDL_Haptic?) {
    var text : string
    if(!SDL_GetHapticNameCopy(device,text)) {return err(sdl_error("SDL_GetHapticNameCopy"),type<string>)}
    return ok(text,type<SdlError>)
}
def public sensor_data(device : SDL_Sensor?; var data : array<float>) {return sdl_status(SDL_GetSensorDataArray(device,data),"SDL_GetSensorData")}
// Unsupported is a normal predicate result; do not interpret stale SDL errors.
def public haptic_effect_supported(device : SDL_Haptic?; effect : SDL_HapticEffect) : bool {return SDL_HapticEffectSupportedRef(device,effect)}
def public create_haptic_effect(device : SDL_Haptic?; effect : SDL_HapticEffect) {
    let id=SDL_CreateHapticEffectRef(device,effect)
    if(id<0) {return err(sdl_error("SDL_CreateHapticEffect"),type<int>)}
    return ok(id,type<SdlError>)
}
def public with_haptic_effect(device : SDL_Haptic?; effect : SDL_HapticEffect; body : block<(id : int) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let id=SDL_CreateHapticEffectRef(device,effect)
    if(id<0) {return err(sdl_error("SDL_CreateHapticEffect"),type<TT>)}
    {
        defer() {SDL_DestroyHapticEffect(device,id)}
        static_if(typeinfo can_copy(type<$Result<TT; SdlError>>)) {scope_result=body(id)}
        else {scope_result <- body(id)}
    }
    return <- scope_result
}
def public update_haptic_effect(device : SDL_Haptic?; id : int; effect : SDL_HapticEffect) {return sdl_status(SDL_UpdateHapticEffectRef(device,id,effect),"SDL_UpdateHapticEffect")}
def public run_haptic_effect(device : SDL_Haptic?; id : int; iterations : uint) {return sdl_status(SDL_RunHapticEffect(device,id,iterations),"SDL_RunHapticEffect")}
def public stop_haptic_effect(device : SDL_Haptic?; id : int) {return sdl_status(SDL_StopHapticEffect(device,id),"SDL_StopHapticEffect")}

struct HidDeviceInfo {
    path, serial_number, manufacturer, product : string
    vendor_id, product_id, release_number, usage_page, usage : uint16
    interface_number, interface_class, interface_subclass, interface_protocol : int
    bus_type : SDL_hid_bus_type
}
def public hid_device_info(info : SDL_hid_device_info?) : $Option<HidDeviceInfo> {
    var raw : SDL_hid_device_info
    if(!SDL_HidInfoCopy(info,raw)) {return none(type<HidDeviceInfo>)}
    return some(HidDeviceInfo(path=SDL_HidInfoString(info,0),serial_number=SDL_HidInfoString(info,1),
        manufacturer=SDL_HidInfoString(info,2),product=SDL_HidInfoString(info,3),vendor_id=raw.vendor_id,
        product_id=raw.product_id,release_number=raw.release_number,usage_page=raw.usage_page,usage=raw.usage,
        interface_number=raw.interface_number,interface_class=raw.interface_class,
        interface_subclass=raw.interface_subclass,interface_protocol=raw.interface_protocol,bus_type=raw.bus_type))
}
// SDL_hid_enumerate cannot distinguish an empty list from failure in its return value.
def public hid_devices(vendor : uint=0u; product : uint=0u) {
    var values : array<HidDeviceInfo>
    var head=SDL_hid_enumerate(vendor,product)
    {
        defer() {SDL_hid_free_enumeration(head)}
        var item=head
        while(item!=null) {
            let value=hid_device_info(item)
            if(is_some(value)) {push(values,unwrap(value))}
            item=SDL_HidNext(item)
        }
    }
    return <- values
}
def public with_hid(body : block<() : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    if(SDL_hid_init()!=0) {return err(sdl_error("SDL_hid_init"),type<TT>)}
    {
        defer() {if(SDL_hid_exit()!=0 && is_ok(scope_result)) {scope_result <- err(sdl_error("SDL_hid_exit"),type<TT>)}}
        static_if(typeinfo can_copy(type<$Result<TT; SdlError>>)) {scope_result=body()}
        else {scope_result <- body()}
    }
    return <- scope_result
}
def public open_hid(path : string) {
    var device=SDL_hid_open_path(path)
    if(device==null) {return err(sdl_error("SDL_hid_open_path"),type<SDL_hid_device?>)}
    return <- move_ok(device,type<SdlError>)
}
def public with_hid_device(path : string; body : block<(device : SDL_hid_device?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    var device=SDL_hid_open_path(path)
    if(device==null) {return err(sdl_error("SDL_hid_open_path"),type<TT>)}
    {
        defer() {if(SDL_hid_close(device)!=0 && is_ok(scope_result)) {scope_result <- err(sdl_error("SDL_hid_close"),type<TT>)}}
        static_if(typeinfo can_copy(type<$Result<TT; SdlError>>)) {scope_result=body(device)}
        else {scope_result <- body(device)}
    }
    return <- scope_result
}
def public hid_write(device : SDL_hid_device?; data : array<uint8>) {
    let count=SDL_hid_writeArray(device,data)
    if(count<0) {return err(sdl_error("SDL_hid_write"),type<int>)}
    return ok(count,type<SdlError>)
}
def public hid_read(device : SDL_hid_device?; var data : array<uint8>) {
    let count=SDL_hid_readArray(device,data)
    if(count<0) {return err(sdl_error("SDL_hid_read"),type<int>)}
    return ok(count,type<SdlError>)
}
def public hid_send_feature_report(device : SDL_hid_device?; data : array<uint8>) {
    let count=SDL_hid_send_feature_reportArray(device,data)
    if(count<0) {return err(sdl_error("SDL_hid_send_feature_report"),type<int>)}
    return ok(count,type<SdlError>)
}
def public hid_get_feature_report(device : SDL_hid_device?; var data : array<uint8>) {
    let count=SDL_hid_get_feature_reportArray(device,data)
    if(count<0) {return err(sdl_error("SDL_hid_get_feature_report"),type<int>)}
    return ok(count,type<SdlError>)
}
def public hid_get_input_report(device : SDL_hid_device?; var data : array<uint8>) {
    let count=SDL_hid_get_input_reportArray(device,data)
    if(count<0) {return err(sdl_error("SDL_hid_get_input_report"),type<int>)}
    return ok(count,type<SdlError>)
}
def public hid_get_report_descriptor(device : SDL_hid_device?; var data : array<uint8>) {
    let count=SDL_hid_get_report_descriptorArray(device,data)
    if(count<0) {return err(sdl_error("SDL_hid_get_report_descriptor"),type<int>)}
    return ok(count,type<SdlError>)
}
def public hid_read_timeout(device : SDL_hid_device?; var data : array<uint8>; milliseconds : int) {
    let count=SDL_hid_read_timeoutArray(device,data,milliseconds)
    if(count<0) {return err(sdl_error("SDL_hid_read_timeout"),type<int>)}
    return ok(count,type<SdlError>)
}
