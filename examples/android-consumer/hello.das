options gen2
require sdl3

[export]
def check_platform() : bool {
    return SDL_GetPlatform() == "Android" && SDL_GetVersion() == 3004016
}
