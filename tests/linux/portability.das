options gen2
require dassdl3/sdl3_platform_services
require daslib/safe_addr

[export]
def main(smoke : bool) : int {
    verify(!DASSDL3_WINDOWS)
    verify(typeinfo sizeof(type<SDL_HidChar>) == 4)
    var text : SDL_HidChar[5]
    text[0] = 0x65e5; text[1] = 0x672c; text[2] = 0x20; text[3] = 0x1f30d
    verify(SDL_HidWideString(safe_addr(text[0])) == "日本 🌍")
    verify(SDL_HidWideString(null) == "")
    var result <- dxgi_output(0u)
    verify(is_err(result))
    verify(unwrap_err(result).operation == "SDL_GetDXGIOutputInfo")
    print("Linux native-width HID Unicode and unsupported DXGI PASS\n")
    return 0
}
