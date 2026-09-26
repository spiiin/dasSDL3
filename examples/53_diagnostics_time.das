options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_diagnostics_boost
def show_time : SdlStatus {
    var ticks = 0l
    var utc : SDL_DateTime
    current_time(ticks) |> sdl_try
    time_to_date(ticks, utc) |> sdl_try
    log_message(
        int(SDL_LogCategory.LOG_CATEGORY_APPLICATION),
        SDL_LogPriority.LOG_PRIORITY_INFO,
        "UTC: {utc.year}-{utc.month}-{utc.day}, literal percent: 100%")
    let start = SDL_GetPerformanceCounter()
    SDL_Delay(1u)
    let elapsed = SDL_GetPerformanceCounter() - start
    print("Elapsed counter ticks: {elapsed}; frequency: {SDL_GetPerformanceFrequency()}\n")
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = show_time()
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
