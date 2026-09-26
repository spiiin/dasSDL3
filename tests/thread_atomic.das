options gen2
require dassdl3/sdl3_thread_atomic
require daslib/safe_addr

// Test-only addresses refer to native C functions, never script code.
def atomics {
    var lock=0
    verify(SDL_TryLockSpinlock(safe_addr(lock)))
    verify(!SDL_TryLockSpinlock(safe_addr(lock)))
    SDL_UnlockSpinlock(safe_addr(lock))
    SDL_LockSpinlock(safe_addr(lock));SDL_UnlockSpinlock(safe_addr(lock))
    SDL_MemoryBarrierReleaseFunction();SDL_MemoryBarrierAcquireFunction()
    var i : SDL_AtomicInt
    verify(SDL_SetAtomicInt(safe_addr(i),10)==0)
    verify(SDL_AddAtomicInt(safe_addr(i),3)==10)
    verify(!SDL_CompareAndSwapAtomicInt(safe_addr(i),10,20))
    verify(SDL_CompareAndSwapAtomicInt(safe_addr(i),13,20))
    verify(SDL_GetAtomicInt(safe_addr(i))==20)
    verify(atomic_set(i,1)==20 && atomic_add(i,2)==1 && atomic_get(i)==3)
    verify(atomic_compare_exchange(i,3,4))
    var u : SDL_AtomicU32
    verify(SDL_SetAtomicU32(safe_addr(u),0xffffffffu)==0u)
    verify(!SDL_CompareAndSwapAtomicU32(safe_addr(u),1u,2u))
    verify(SDL_CompareAndSwapAtomicU32(safe_addr(u),0xffffffffu,9u))
    verify(SDL_GetAtomicU32(safe_addr(u))==9u)
    verify(SDL_AddAtomicU32(safe_addr(u),2)==9u)
    verify(SDL_AddAtomicU32(safe_addr(u),-2)==11u)
    verify(atomic_set(u,2u)==9u && atomic_get(u)==2u && atomic_compare_exchange(u,2u,3u))
    var ptr : void?
    let marker=SDLTestThreadAddress(2)
    verify(SDL_SetAtomicPointer(safe_addr(ptr),marker)==null)
    verify(SDL_GetAtomicPointer(safe_addr(ptr))==marker)
    verify(!SDL_CompareAndSwapAtomicPointer(safe_addr(ptr),null,marker))
    verify(SDL_CompareAndSwapAtomicPointer(safe_addr(ptr),marker,null))
    verify(atomic_set(ptr,marker)==null && atomic_get(ptr)==marker)
    verify(atomic_compare_exchange(ptr,marker,null))
    verify(SDL_TryLockSpinlockRef(lock));SDL_UnlockSpinlockRef(lock)
    SDL_LockSpinlockRef(lock);SDL_UnlockSpinlockRef(lock)
}
def threads {
    verify(SDL_GetCurrentThreadID()!=0ul)
    // Priority can be denied by platform policy; a failed call must report it.
    let priority=SDL_SetCurrentThreadPriority(SDL_ThreadPriority.THREAD_PRIORITY_NORMAL)
    if(!priority) {verify(SDL_GetError()!="")}
    SDLTestThreadReset()
    var count : SDL_AtomicInt
    var thread=SDL_CreateThreadRuntime(SDLTestThreadAddress(0),"raw-worker",safe_addr(count),SDLTestThreadAddress(3),SDLTestThreadAddress(4))
    verify(thread!=null)
    let ready_deadline=SDL_GetTicks()+5000ul
    while(!SDLTestThreadReady() && SDL_GetTicks()<ready_deadline) {SDL_Delay(1u)}
    verify(SDLTestThreadReady())
    verify(SDL_GetThreadID(thread)!=0ul && SDL_GetThreadID(thread)!=SDL_GetCurrentThreadID())
    verify(SDL_GetThreadName(thread)=="raw-worker")
    verify(SDL_GetThreadState(thread)==SDL_ThreadState.THREAD_ALIVE)
    SDLTestThreadRelease()
    for(n in range(10000)) {SDL_AddAtomicInt(safe_addr(count),1)}
    var status=0
    SDL_WaitThread(thread,safe_addr(status))
    verify(status==37 && atomic_get(count)==20000 && SDLTestThreadCleanupCount()==1)
    SDLTestThreadReset()
    let props=SDL_CreateProperties()
    verify(SDL_SetPointerProperty(props,"SDL.thread.create.entry_function",SDLTestThreadAddress(0)))
    verify(SDL_SetStringProperty(props,"SDL.thread.create.name","props-worker"))
    thread=SDL_CreateThreadWithPropertiesRuntime(props,SDLTestThreadAddress(3),SDLTestThreadAddress(4))
    SDL_DestroyProperties(props)
    verify(thread!=null)
    SDLTestThreadRelease();SDL_WaitThread(thread,null)
    verify(SDLTestThreadCleanupCount()==1)
    SDLTestThreadReset()
    var created <- create_thread(SDLTestThreadAddress(0),"detached")
    verify(is_ok(created));thread=move_unwrap(created)
    SDL_DetachThread(thread);thread=null
    SDLTestThreadRelease()
    let deadline=SDL_GetTicks()+5000ul
    while(SDLTestThreadCleanupCount()==0 && SDL_GetTicks()<deadline) {SDL_Delay(1u)}
    verify(SDLTestThreadCleanupCount()==1)
    SDLTestThreadReset()
    var scoped <- with_thread(SDLTestThreadAddress(0),"scoped",null) $(borrowed) {
        verify(SDL_GetThreadState(borrowed)==SDL_ThreadState.THREAD_ALIVE)
        SDLTestThreadRelease()
        return err(SdlError(operation="body",message="preserved after join"),type<SdlUnit>)
    }
    verify(is_err(scoped) && unwrap_err(scoped).operation=="body" && SDLTestThreadCleanupCount()==1)
    SDLTestThreadReset()
    var joined <- create_thread(SDLTestThreadAddress(0),"joined")
    verify(is_ok(joined));thread=move_unwrap(joined)
    SDLTestThreadRelease();verify(join_thread(thread)==37 && thread==null)
    SDLTestThreadReset()
    let props2=SDL_CreateProperties()
    verify(SDL_SetPointerProperty(props2,"SDL.thread.create.entry_function",SDLTestThreadAddress(0)))
    var from_props <- create_thread(props2)
    SDL_DestroyProperties(props2)
    verify(is_ok(from_props));thread=move_unwrap(from_props)
    detach_thread(thread);verify(thread==null)
    SDLTestThreadRelease()
    let detach_deadline=SDL_GetTicks()+5000ul
    while(SDLTestThreadCleanupCount()==0 && SDL_GetTicks()<detach_deadline) {SDL_Delay(1u)}
    verify(SDLTestThreadCleanupCount()==1)
    SDLTestThreadFinish()
    var invalid <- create_thread(null,"invalid")
    verify(is_err(invalid) && unwrap_err(invalid).message!="")
}
def tls {
    var id : SDL_AtomicInt // SDL_TLSID alias, stable local storage throughout use.
    verify(SDL_GetTLS(safe_addr(id))==null)
    let marker=SDLTestThreadAddress(2)
    verify(SDL_SetTLS(safe_addr(id),marker,null))
    verify(SDL_GetTLS(safe_addr(id))==marker)
    var copied=get_tls(id)
    verify(is_some(copied) && unwrap(copied).address==marker)
    verify(is_ok(set_tls(id,null)))
    verify(is_none(get_tls(id)))
    // Manual cleanup on the current thread; do not invoke inside an unrelated TLS owner.
    verify(SDL_SetTLS(safe_addr(id),marker,SDLTestThreadAddress(1)))
    let before=SDLTestThreadCleanupCount()
    SDL_CleanupTLS()
    verify(SDLTestThreadCleanupCount()==before+1 && is_none(get_tls(id)))
}
[export]
def main(smoke : bool) : int {
    atomics();threads();tls()
    print("Thread/TLS and Atomic contracts passed.\n")
    return 0
}
