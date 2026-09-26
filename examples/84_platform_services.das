options gen2
require dassdl3/sdl3_platform_services
require dassdl3/sdl3_try

[export]
def main(smoke : bool) : int {
    var locales <- preferred_locales()
    if (is_ok(locales)) {
        var values <- move_unwrap(locales)
        for (value in values) {print("Preferred language: {value.language}; country: {value.country}\n")}
    } else {
        let error = unwrap_err(locales); print("{error.operation}: {error.message}\n")
    }
    var power <- power_info()
    if (is_ok(power)) {
        let info = unwrap(power)
        print("Power state: {int(info.state)}; battery percentage known: {is_some(info.percent)}\n")
    }
    print("Tablet: {SDL_IsTablet()}; TV: {SDL_IsTV()}; sandbox: {int(SDL_GetSandbox())}\n")
    return 0
}
