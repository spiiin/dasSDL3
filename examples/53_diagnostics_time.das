options gen2
require dassdl3/sdl3_diagnostics_boost
[export]
def main(smoke : bool) : int {
    var ticks=0l
    var utc : SDL_DateTime
    if(!is_ok(current_time(ticks)) || !is_ok(time_to_date(ticks,utc))) {
        print("{error_string()}\n"); return 1
    }
    log_message(int(SDL_LogCategory.LOG_CATEGORY_APPLICATION),SDL_LogPriority.LOG_PRIORITY_INFO,
        "UTC: {utc.year}-{utc.month}-{utc.day}, literal percent: 100%")
    let start=SDL_GetPerformanceCounter()
    SDL_Delay(1u)
    let elapsed=SDL_GetPerformanceCounter()-start
    print("Elapsed counter ticks: {elapsed}; frequency: {SDL_GetPerformanceFrequency()}\n")
    return 0
}
