options gen2
require dassdl3/sdl3_peripherals_boost
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl_subsystems(SDL_INIT_VIDEO|SDL_INIT_SENSOR|SDL_INIT_HAPTIC) |> sdl_use
        with_hid() |> sdl_use
        let touch <- touch_devices() |> sdl_try
        let sensor <- sensors() |> sdl_try
        let haptic <- haptics() |> sdl_try
        let hid <- hid_devices()
        print("Touch devices: {length(touch)}; sensors: {length(sensor)}; haptics: {length(haptic)}; HID interfaces: {length(hid)}\n")
        for(device in hid) {print("HID {uint(device.vendor_id)}:{uint(device.product_id)} {device.manufacturer} {device.product}\n")}
        return sdl_ok()
    }
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    print("Enumeration finished; HID session and SDL subsystems released.\n")
    return 0
}
