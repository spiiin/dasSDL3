options gen2
require dassdl3/sdl3_diagnostics_boost
[export]
def main(smoke : bool) : int {
    verify(SDL_ClearError())
    verify(error_string() == "")
    verify(set_error("Ошибка %s %n 100%").message == "Ошибка %s %n 100%")
    let saved = error_string()
    verify(SDLTestThreadError())
    verify(SDL_GetError() == saved)
    verify(!SDL_OutOfMemory())
    verify(error_string() != "" && saved == "Ошибка %s %n 100%")
    verify(SDL_ClearError())
    SDLTestBeginLog()
    let cat = int(SDL_LogCategory.LOG_CATEGORY_APPLICATION)
    SDL_SetLogPriorities(SDL_LogPriority.LOG_PRIORITY_TRACE)
    verify(SDL_GetLogPriority(cat) == SDL_LogPriority.LOG_PRIORITY_TRACE)
    SDL_LogText("100%")
    SDL_LogTraceText(cat, "trace")
    SDL_LogVerboseText(cat, "verbose")
    SDL_LogDebugText(cat, "debug")
    SDL_LogInfoText(cat, "info")
    SDL_LogWarnText(cat, "warn")
    SDL_LogErrorText(cat, "error")
    SDL_LogCriticalText(cat, "critical")
    log_message(cat, SDL_LogPriority.LOG_PRIORITY_INFO, "Привет %s %n")
    verify(SDLTestLogMatches(9, "Привет %s %n"))
    SDL_SetLogPriority(cat, SDL_LogPriority.LOG_PRIORITY_ERROR)
    SDL_LogInfoText(cat, "filtered")
    verify(SDLTestLogMatches(9, "Привет %s %n"))
    verify(SDL_SetLogPriorityPrefix(SDL_LogPriority.LOG_PRIORITY_INFO, "[info]"))
    verify(!SDL_SetLogPriorityPrefix(SDL_LogPriority.LOG_PRIORITY_INVALID, "invalid"))
    SDL_ResetLogPriorities()
    verify(SDL_GetLogPriority(cat) == SDL_LogPriority.LOG_PRIORITY_INFO)
    SDLTestEndLog()
    let start = SDL_GetTicksNS()
    let counter = SDL_GetPerformanceCounter()
    verify(SDL_GetPerformanceFrequency() > 0ul)
    SDL_Delay(1u)
    SDL_DelayNS(1000000ul)
    SDL_DelayPrecise(1000000ul)
    verify(SDL_GetTicksNS() >= start + 3000000ul && SDL_GetPerformanceCounter() >= counter)
    verify(SDL_GetTicks() >= 1ul)
    let timer = SDLTestCreateDormantTimer()
    verify(timer != 0u && SDL_RemoveTimer(timer))
    verify(!SDL_RemoveTimer(timer) && !SDL_RemoveTimer(0u))
    var ticks = 0l
    verify(is_ok(current_time(ticks)) && ticks > 0l)
    var date : SDL_DateTime
    verify(is_ok(time_to_date(0l, date)))
    verify(date.year == 1970 && date.month == 1 && date.day == 1 && date.day_of_week == 4 && date.utc_offset == 0)
    verify(is_ok(date_to_time(date, ticks)) && ticks == 0l)
    verify(SDL_GetDaysInMonth(2000, 2) == 29 && SDL_GetDaysInMonth(1900, 2) == 28)
    verify(SDL_GetDaysInMonth(2000, 13) == -1)
    verify(SDL_GetDayOfYear(2000, 3, 1) == 60)
    verify(SDL_GetDayOfWeek(1970, 1, 1) == 4)
    date.year = 2024; date.month = 2; date.day = 29; date.hour = 12; date.nanosecond = 123456700
    verify(is_ok(date_to_time(date, ticks)))
    var low = 0u; var high = 0u
    SDL_TimeToWindowsRef(ticks, low, high)
    verify(SDL_TimeFromWindows(low, high) == ticks)
    var roundtrip : SDL_DateTime
    verify(is_ok(time_to_date(ticks, roundtrip)) && roundtrip.day == 29 && roundtrip.nanosecond == 123456700)
    date.month = 13
    verify(!is_ok(date_to_time(date, ticks)))
    var df = SDL_DateFormat.DATE_FORMAT_YYYYMMDD
    var tf = SDL_TimeFormat.TIME_FORMAT_24HR
    verify(SDL_GetDateTimeLocalePreferencesRef(df, tf))
    // Execute raw out-pointer signatures too; public example uses ref adapters.
    unsafe {
        verify(SDL_GetCurrentTime(addr(ticks)))
        verify(SDL_TimeToDateTime(0l, addr(date), false))
        verify(SDL_DateTimeToTime(addr(date), addr(ticks)) && ticks == 0l)
        SDL_TimeToWindows(ticks, addr(low), addr(high))
        verify(SDL_TimeFromWindows(low, high) == 0l)
        verify(SDL_GetDateTimeLocalePreferences(addr(df), addr(tf)))
    }
    return 0
}
