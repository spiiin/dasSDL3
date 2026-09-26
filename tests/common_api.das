options gen2
require dassdl3/sdl3_common_boost
require daslib/safe_addr
[export]
def main(smoke : bool) : int {
    verify(SDL_GetPlatform() == "Windows" && platform_name() == "Windows")
    verify(length(SDL_GetRevision()) > 0 && sdl_revision() == SDL_GetRevision())
    let text = "00112233445566778899aabbccddeeff"
    var guid = SDL_StringToGUID("00112233445566778899AABBCCDDEEFF")
    verify(guid_string(guid) == text)
    let buffer = SDLTestGUIDBuffer()
    SDL_GUIDToString(guid, buffer, 33)
    verify(buffer == text)
    let saved = guid_string(guid)
    SDL_GUIDToString(guid, buffer, 5)
    verify(buffer == "0011" && saved == text)
    SDL_GUIDToString(guid, buffer, 0)
    verify(buffer == "0011")
    verify(guid_string(guid_from_string("abc")) == "ab000000000000000000000000000000")
    verify(guid_string(guid_from_string("zz")) == "00000000000000000000000000000000")
    verify(guid_string(guid_from_string("")) == "00000000000000000000000000000000")
    verify(guid_string(guid_from_string("{text}ffff")) == text)
    verify(!SDLTestOpenURLNull())
    verify(is_err(open_url("")))
    // Never allow this test to select a real message box backend.
    verify(SDL_WasInit(SDL_INIT_VIDEO) == 0u)
    verify(SDL_SetHintWithPriority(SDL_HINT_VIDEO_DRIVER, "dassdl3-no-message-box", SDL_HintPriority.HINT_OVERRIDE))
    verify(!SDL_ShowMessageBox(null, null))
    var invalid = SDL_MessageBoxData(numbuttons = -1)
    unsafe {verify(!SDL_ShowMessageBox(addr(invalid), null))}
    verify(!SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, "Test", "No backend", null))
    var buttons <- array<SDL_MessageBoxButtonData>(SDL_MessageBoxButtonData(buttonID = 42, text = "OK", flags = SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT))
    var result = show_message_box(SDL_MESSAGEBOX_INFORMATION, "Test", "No backend", buttons)
    verify(is_err(result))
    SDL_ClearError()
    verify(length(unwrap_err(result).message) > 0 && unwrap_err(result).operation == "SDL_ShowMessageBox")
    var colors : SDL_MessageBoxColorScheme
    colors.colors[0] = SDL_MessageBoxColor(r = uint8(12), g = uint8(34), b = uint8(56))
    verify(colors.colors[0].g == uint8(34))
    verify(is_err(show_message_box(SDL_MESSAGEBOX_INFORMATION, "Test", "Colors", buttons, colors)))
    verify(is_err(show_simple_message_box(SDL_MESSAGEBOX_INFORMATION, "Test", "No backend")))
    buttons[0].buttonID = -1
    result = show_message_box(SDL_MESSAGEBOX_INFORMATION, "Test", "Reserved ID", buttons)
    verify(is_err(result) && unwrap_err(result).message == "Button ID -1 is reserved for closing the message box")
    print("Common API: GUID, platform/revision and noninteractive failure paths passed.\n")
    return 0
}
