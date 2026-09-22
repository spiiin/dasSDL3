options gen2
require dassdl3/sdl3_process_loadso
require dassdl3/sdl3_scope
require dassdl3/sdl3_iostream_boost
require daslib/safe_addr

def raw_process {
    var args : string[3]
    args[0]=SDLTestProcessChildPath()
    let process=SDL_CreateProcess(safe_addr(args[0]),true)
    verify(process!=null)
    verify(SDL_GetProcessProperties(process)!=0u)
    verify(SDL_GetProcessInput(process)!=null && SDL_GetProcessOutput(process)!=null)
    var size=0ul
    var code=0
    let bytes=SDL_ReadProcess(process,safe_addr(size),safe_addr(code))
    verify(bytes!=null && size==10ul && code==7)
    SDL_free(bytes)
    verify(SDL_WaitProcess(process,false,safe_addr(code)) && code==7)
    SDL_DestroyProcess(process)
    args[1]="wait"
    let props=SDL_CreateProperties()
    verify(SDL_SetPointerProperty(props,"SDL.process.create.args",safe_addr(args[0])))
    let sleeper=SDL_CreateProcessWithProperties(props)
    SDL_DestroyProperties(props)
    verify(sleeper!=null)
    code=123
    SDL_SetErrorText("old error")
    verify(!SDL_WaitProcess(sleeper,false,safe_addr(code)) && code==123)
    var pending <- wait_process(sleeper)
    verify(is_ok(pending) && is_none(unwrap(pending)))
    verify(SDL_KillProcess(sleeper,true))
    verify(SDL_WaitProcess(sleeper,true,safe_addr(code)))
    SDL_DestroyProcess(sleeper)
}
def boost_process {
    var args <- array<string>(SDLTestProcessChildPath())
    var result <- with_process(args,true) $(process : SDL_Process?) {
        var output <- read_process(process)
        verify(is_ok(output))
        var data <- move_unwrap(output)
        verify(data.exit_code==7 && length(data.bytes)==10)
        verify(int(data.bytes[0])==112 && int(data.bytes[9])==107)
        return ok(data.exit_code,type<SdlError>)
    }
    verify(is_ok(result) && unwrap(result)==7)
    var quoted <- create_process(array<string>(SDLTestProcessChildPath(),"args","two words \"quoted\""))
    verify(is_ok(quoted));var quoted_child=move_unwrap(quoted)
    var quoted_output <- read_process(quoted_child)
    verify(is_ok(quoted_output));var quoted_data <- move_unwrap(quoted_output)
    verify(quoted_data.exit_code==7 && length(quoted_data.bytes)==7)
    destroy_process(quoted_child)
    var echo <- create_process(array<string>(SDLTestProcessChildPath(),"echo"))
    verify(is_ok(echo));var child=move_unwrap(echo)
    var input=SDL_GetProcessInput(child)
    var line <- array<uint8>(uint8(112),uint8(105),uint8(110),uint8(103),uint8(10))
    var sent=0ul
    verify(is_ok(write_io(input,line,5ul,sent)) && sent==5ul)
    verify(is_ok(close_io(input)) && input==null)
    verify(SDL_GetProcessInput(child)==null)
    var echoed <- read_process(child)
    verify(is_ok(echoed));var echo_data <- move_unwrap(echoed)
    verify(echo_data.exit_code==7 && length(echo_data.bytes)>=5 && int(echo_data.bytes[0])==112)
    destroy_process(child)
    var empty : array<string>
    var failed <- create_process(empty)
    verify(is_err(failed))
    let error=unwrap_err(failed)
    SDL_SetErrorText("overwritten")
    verify(error.message!="overwritten")
    var invalid_wait <- wait_process(null)
    verify(is_err(invalid_wait))
    var missing <- create_process(array<string>("dassdl3-missing-process-583c.exe"))
    verify(is_err(missing))
    var created <- create_process(array<string>(SDLTestProcessChildPath(),"wait"),false)
    verify(is_ok(created))
    var process=move_unwrap(created)
    verify(is_ok(kill_process(process,true)))
    var completed <- wait_process(process,true)
    verify(is_ok(completed) && is_some(unwrap(completed)))
    destroy_process(process);verify(process==null)
    let props=SDL_CreateProperties()
    var bad_props <- create_process(props)
    SDL_DestroyProperties(props)
    verify(is_err(bad_props))
    var no_output <- read_process(null)
    verify(is_err(no_output))
}
def libraries {
    let library=SDL_LoadObject(SDLTestProcessLibraryPath())
    verify(library!=null)
    let symbol_address=SDL_LoadFunction(library,"sdl3_test_library_value")
    verify(symbol_address!=null && SDLTestProcessLibraryCall(symbol_address)==42)
    verify(SDL_LoadFunction(library,"missing_export")==null)
    SDL_UnloadObject(library)
    var scope <- with_object(SDLTestProcessLibraryPath()) $(object) {
        var symbol <- load_function(object,"sdl3_test_library_value")
        verify(is_ok(symbol) && SDLTestProcessLibraryCall(unwrap(symbol).address)==42)
        return err(SdlError(operation="body",message="after unload"),type<SdlUnit>)
    }
    verify(is_err(scope) && unwrap_err(scope).operation=="body")
    var loaded <- load_object(SDLTestProcessLibraryPath())
    verify(is_ok(loaded));var object=move_unwrap(loaded)
    var absent <- load_function(object,"missing_export")
    verify(is_err(absent))
    unload_object(object);verify(object==null)
    var missing <- load_object("dassdl3-missing-library-583c.dll")
    verify(is_err(missing))
}
[export]
def main(smoke : bool) : int {
    raw_process();boost_process();libraries()
    print("Process and LoadSO contracts passed.\n")
    return 0
}
