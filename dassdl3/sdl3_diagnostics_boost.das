options gen2
module sdl3_diagnostics_boost shared public
require dassdl3/sdl3_boost public

def public error_string : string { return SDL_GetErrorCopy() }
def public set_error(text : string) : bool { return SDL_SetErrorText(text) }
def public log_message(category : int; priority : SDL_LogPriority; text : string) {
    SDL_LogMessageText(category,priority,text)
}
def public current_time(var ticks : int64&) : bool { return SDL_GetCurrentTimeRef(ticks) }
def public time_to_date(ticks : int64; var date : SDL_DateTime; local_time : bool=false) : bool {
    return SDL_TimeToDateTimeRef(ticks,date,local_time)
}
def public date_to_time(date : SDL_DateTime; var ticks : int64&) : bool {
    return SDL_DateTimeToTimeRef(date,ticks)
}
