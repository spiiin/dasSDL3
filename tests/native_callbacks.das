options gen2
require sdl3
require daslib/defer

[export]
def main(smoke : bool) : int {
    let data = SDLTestCallbackData(false)
    let value = SDLTestCallbackData(true)
    let hint = SDLTestCallbackAddress(0)
    verify(SDL_SetHint("DASSDL3_CALLBACK_TEST", "first"))
    verify(!SDL_AddHintCallback("DASSDL3_CALLBACK_TEST", null, data))
    verify(SDL_AddHintCallback("DASSDL3_CALLBACK_TEST", hint, data))
    verify(SDLTestCallbackCount(0) == 1)
    verify(SDL_AddHintCallback("DASSDL3_CALLBACK_TEST", hint, data))
    verify(SDLTestCallbackCount(0) == 2)
    SDL_RemoveHintCallback("DASSDL3_CALLBACK_TEST", hint, value)// Wrong triple does not remove.
    verify(SDL_SetHint("DASSDL3_CALLBACK_TEST", "second"))
    verify(SDLTestCallbackCount(0) == 3)
    SDL_RemoveHintCallback("DASSDL3_CALLBACK_TEST", hint, data)
    verify(SDL_SetHint("DASSDL3_CALLBACK_TEST", "third"))
    verify(SDLTestCallbackCount(0) == 3)
    SDL_ResetHint("DASSDL3_CALLBACK_TEST")

    var previous : void?; var previous_data : void ?
    unsafe {SDL_GetLogOutputFunction(addr(previous), addr(previous_data))}
    let original_priority = SDL_GetLogPriority(int(SDL_LogCategory.LOG_CATEGORY_APPLICATION))
    {
        defer() {
            SDL_SetLogOutputFunction(previous, previous_data)
            SDL_SetLogPriority(int(SDL_LogCategory.LOG_CATEGORY_APPLICATION), original_priority)
        }
        let logger = SDLTestCallbackAddress(1)
        SDL_SetLogPriority(int(SDL_LogCategory.LOG_CATEGORY_APPLICATION), SDL_LogPriority.LOG_PRIORITY_ERROR)
        SDL_SetLogOutputFunction(logger, data)
        var output : void?; var userdata : void ?
        SDL_GetLogOutputFunctionRef(output, userdata)
        verify(output == logger && userdata == data)
        SDL_LogErrorText(int(SDL_LogCategory.LOG_CATEGORY_APPLICATION), "native callback 100%")
        verify(SDLTestCallbackCount(1) == 1)
        SDL_SetLogOutputFunction(null, null)// Disabled output is valid.
        SDL_LogErrorText(int(SDL_LogCategory.LOG_CATEGORY_APPLICATION), "not delivered")
        verify(SDLTestCallbackCount(1) == 1)
        SDL_SetLogOutputFunction(SDL_GetDefaultLogOutputFunction(), null)
        SDL_GetLogOutputFunctionRef(output, userdata)
        verify(output != null && output == SDL_GetDefaultLogOutputFunction() && userdata == null)
    }
    var restored : void?; var restored_data : void ?
    SDL_GetLogOutputFunctionRef(restored, restored_data)
    verify(restored == previous && restored_data == previous_data)

    let cleanup = SDLTestCallbackAddress(2)
    verify(!SDL_SetPointerPropertyWithCleanup(0u, "owned", value, cleanup, data))
    verify(SDLTestCallbackCount(2) == 1)// Failure already released ownership.
    let props = SDL_CreateProperties()
    let copy = SDL_CreateProperties()
    verify(props != 0u && copy != 0u)
    verify(SDL_SetPointerPropertyWithCleanup(props, "owned", value, cleanup, data))
    verify(SDL_CopyProperties(props, copy))
    verify(!SDL_HasProperty(copy, "owned"))
    SDL_DestroyProperties(copy)
    verify(SDL_SetPointerPropertyWithCleanup(props, "owned", value, cleanup, data))
    verify(SDLTestCallbackCount(2) == 2)// Replacement.
    verify(SDL_ClearProperty(props, "owned"))
    verify(SDLTestCallbackCount(2) == 3)
    verify(SDL_SetPointerPropertyWithCleanup(props, "owned", null, cleanup, data))
    verify(SDLTestCallbackCount(2) == 4)// NULL value also calls cleanup.
    verify(SDL_SetPointerPropertyWithCleanup(props, "owned", value, cleanup, data))
    SDL_DestroyProperties(props)
    verify(SDLTestCallbackCount(2) == 5)

    verify(SDL_Init(SDL_INIT_EVENTS))
    verify(SDL_RunOnMainThread(SDLTestCallbackAddress(3), data, true))
    verify(SDL_RunOnMainThread(SDLTestCallbackAddress(3), data, false))
    verify(SDLTestCallbackCount(3) == 2)
    for (wait in fixed_array(false, true)) {
        let before = SDLTestCallbackCount(3)
        verify(SDLTestStartMainWorker(wait))
        let deadline = SDL_GetTicks() + 5000ul
        while ((!SDLTestMainWorkerDone() || SDLTestCallbackCount(3) == before) && SDL_GetTicks() < deadline) {
            SDL_PumpEvents()
            SDL_Delay(1u)
        }
        verify(SDLTestMainWorkerDone() && SDLTestCallbackCount(3) == before + 1)
        SDLTestJoinMainWorker()
    }
    verify(SDLTestCallbackCheck())
    SDL_Quit()
    print("Native callbacks: hints, log, cleanup and main-thread dispatch passed\n")
    return 0
}
