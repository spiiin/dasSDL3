options gen2
require sdl3
require daslib/defer

// An SDL-provided C callback can be saved/restored without a script callback bridge.
// For custom callbacks the native host must supply a C address and own userdata.
[export]
def main(smoke : bool) : int {
    var previous : void?; var userdata : void?
    SDL_GetLogOutputFunctionRef(previous,userdata)
    {
        defer() {SDL_SetLogOutputFunction(previous,userdata)}
        SDL_SetLogOutputFunction(SDL_GetDefaultLogOutputFunction(),null)
        SDL_LogInfoText(int(SDL_LogCategory.LOG_CATEGORY_APPLICATION),"Using SDL's native log output (100% literal text)")
    }
    print("Previous native log callback and userdata restored.\n")
    return 0
}
