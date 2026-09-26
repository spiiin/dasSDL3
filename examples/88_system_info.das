options gen2
require dassdl3/sdl3_common_boost
[export]
def main(smoke : bool) : int {
    print("Platform: {platform_name()}\nSDL revision: {sdl_revision()}\n")
    let guid=guid_from_string("00112233445566778899aabbccddeeff")
    print("GUID: {guid_string(guid)}\n")
    // Explicit user actions can call open_url() or show_message_box().
    // This example remains noninteractive, including smoke mode.
    return 0
}
