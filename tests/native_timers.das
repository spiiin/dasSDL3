options gen2
require sdl3

[export]
def main(smoke : bool) : int {
    verify(SDL_Init(SDL_INIT_EVENTS))
    let data=SDLTestCallbackData(false)
    let ms=SDL_AddTimer(2u,SDLTestCallbackAddress(4),data)
    let ns=SDL_AddTimerNS(2000000ul,SDLTestCallbackAddress(5),data)
    verify(ms!=0u && ns!=0u)
    let deadline=SDL_GetTicks()+5000ul
    while((SDLTestCallbackCount(4)<2 || SDLTestCallbackCount(5)<2) && SDL_GetTicks()<deadline) {SDL_Delay(1u)}
    // One timer thread: reaching held_timer proves both previous callbacks returned.
    let held=SDL_AddTimer(1u,SDLTestCallbackAddress(6),data)
    verify(held!=0u)
    let held_deadline=SDL_GetTicks()+5000ul
    while(SDLTestCallbackCount(6)==0 && SDL_GetTicks()<held_deadline) {SDL_Delay(1u)}
    let entered=SDLTestCallbackCount(6)==1
    let removed=SDL_RemoveTimer(held) // Must return while callback is still blocked.
    let left_before_release=SDLTestTimerRelease()
    verify(entered && removed && !left_before_release)
    SDL_Quit() // Joins the timer thread; static userdata remains valid until here.
    verify(SDLTestCallbackCount(4)==2 && SDLTestCallbackCount(5)==2)
    verify(SDLTestCallbackCount(6)==1 && SDLTestTimerRelease())
    verify(SDLTestCallbackCheck())
    print("Native timers: ms/ns rescheduling and in-flight cancellation passed\n")
    return 0
}
