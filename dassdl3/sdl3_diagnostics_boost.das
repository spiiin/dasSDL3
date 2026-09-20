options gen2
module sdl3_diagnostics_boost shared public
require dassdl3/sdl3_boost public

def public error_string : string { return SDL_GetErrorCopy() }
def public set_error(text : string) : SdlError {
    SDL_SetErrorText(text)
    return sdl_error("set_error")
}
def public log_message(category : int; priority : SDL_LogPriority; text : string) {
    SDL_LogMessageText(category,priority,text)
}
def public current_time(var ticks : int64&) { return sdl_status(SDL_GetCurrentTimeRef(ticks), "current_time") }
def public time_to_date(ticks : int64; var date : SDL_DateTime; local_time : bool=false) {
    return sdl_status(SDL_TimeToDateTimeRef(ticks,date,local_time), "time_to_date")
}
def public date_to_time(date : SDL_DateTime; var ticks : int64&) {
    return sdl_status(SDL_DateTimeToTimeRef(date,ticks), "date_to_time")
}

def public current_time() {
    var ticks : int64
    let status = current_time(ticks)
    if (is_err(status)) { return err(unwrap_err(status),type<int64>) }
    var value = ticks
    return <- move_ok(value,type<SdlError>)
}

def public date_to_time(date : SDL_DateTime) {
    var ticks : int64
    let status = date_to_time(date,ticks)
    if (is_err(status)) { return err(unwrap_err(status),type<int64>) }
    var value = ticks
    return <- move_ok(value,type<SdlError>)
}

def public time_to_date(ticks : int64; local_time : bool = false) {
    var date : SDL_DateTime
    let status = time_to_date(ticks,date,local_time)
    if (is_err(status)) { return err(unwrap_err(status),type<SDL_DateTime>) }
    return ok(date,type<SdlError>)
}
