options gen2
require dassdl3/sdl3_synchronization
require dassdl3/sdl3_scope
require daslib/safe_addr
require daslib/defer

// This executes every raw SDL_mutex.h function. Native helpers only supply the
// competing thread; they never call script code from that thread.
def raw_primitives {
    let mutex=SDL_CreateMutex()
    let rw=SDL_CreateRWLock()
    let sem=SDL_CreateSemaphore(1u)
    let cond=SDL_CreateCondition()
    verify(mutex!=null && rw!=null && sem!=null && cond!=null)
    SDL_LockMutex(mutex)
    verify(SDL_TryLockMutex(mutex)) // SDL mutexes are recursive.
    SDL_UnlockMutex(mutex)
    verify(!SDLTestMutexAvailable(mutex))
    SDL_UnlockMutex(mutex)
    verify(SDLTestMutexAvailable(mutex))
    SDLTestHoldStart(mutex,null,false)
    verify(!SDL_TryLockMutex(mutex) && !try_lock_mutex(mutex))
    SDLTestHoldStop()
    SDL_LockRWLockForReading(rw)
    verify(SDLTestRwlockAvailable(rw,false) && !SDLTestRwlockAvailable(rw,true))
    SDL_UnlockRWLock(rw)
    SDL_LockRWLockForWriting(rw)
    verify(!SDLTestRwlockAvailable(rw,false) && !SDLTestRwlockAvailable(rw,true))
    SDL_UnlockRWLock(rw)
    verify(SDL_TryLockRWLockForReading(rw));SDL_UnlockRWLock(rw)
    verify(SDL_TryLockRWLockForWriting(rw));SDL_UnlockRWLock(rw)
    SDLTestHoldStart(null,rw,true)
    verify(!SDL_TryLockRWLockForReading(rw) && !SDL_TryLockRWLockForWriting(rw))
    verify(!try_lock_rwlock_read(rw) && !try_lock_rwlock_write(rw))
    SDLTestHoldStop()
    verify(SDL_GetSemaphoreValue(sem)==1u)
    SDL_WaitSemaphore(sem)
    verify(SDL_GetSemaphoreValue(sem)==0u)
    SDL_SetErrorText("stale synchronization error")
    verify(!SDL_TryWaitSemaphore(sem) && !SDL_WaitSemaphoreTimeout(sem,0))
    verify(!try_wait_semaphore(sem) && !wait_semaphore(sem,1))
    verify(SDL_GetError()=="stale synchronization error")
    SDL_SignalSemaphore(sem)
    verify(SDL_TryWaitSemaphore(sem))
    SDLTestSemaphoreStart(sem)
    verify(SDL_WaitSemaphoreTimeout(sem,5000))
    SDLTestSyncJoin()
    SDLTestSemaphoreStart(sem)
    SDL_WaitSemaphore(sem)
    SDLTestSyncJoin()
    // Real waiter hand-off: the worker cannot signal until Wait releases mutex.
    SDL_LockMutex(mutex)
    SDLTestConditionStart(mutex,cond,false)
    while(!SDLTestConditionDone()) {SDL_WaitCondition(cond,mutex)}
    verify(!SDLTestMutexAvailable(mutex)) // Wait reacquired it.
    SDL_UnlockMutex(mutex)
    SDLTestSyncJoin()
    SDL_LockMutex(mutex)
    SDLTestConditionStart(mutex,cond,true)
    while(!SDLTestConditionDone()) {verify(SDL_WaitConditionTimeout(cond,mutex,5000))}
    verify(!SDLTestMutexAvailable(mutex))
    SDL_UnlockMutex(mutex)
    SDLTestSyncJoin()
    SDL_SignalCondition(cond)
    SDL_BroadcastCondition(cond)
    SDL_LockMutex(mutex)
    verify(!SDL_WaitConditionTimeout(cond,mutex,0))
    verify(!wait_condition(cond,mutex,1))
    verify(!SDLTestMutexAvailable(mutex))
    SDL_UnlockMutex(mutex)
    SDL_DestroyCondition(cond)
    SDL_DestroySemaphore(sem)
    SDL_DestroyRWLock(rw)
    SDL_DestroyMutex(mutex)
}
def init_state {
    var state : SDL_InitState
    verify(state.status.value==int(SDL_InitStatus.INIT_STATUS_UNINITIALIZED))
    verify(SDL_ShouldInit(safe_addr(state)))
    SDL_SetInitialized(safe_addr(state),false) // failed init can be retried.
    verify(SDL_ShouldInit(safe_addr(state)))
    SDL_SetInitialized(safe_addr(state),true)
    verify(!SDL_ShouldInit(safe_addr(state)))
    verify(SDL_ShouldQuit(safe_addr(state)))
    SDL_SetInitialized(safe_addr(state),false)
    verify(!SDL_ShouldQuit(safe_addr(state)))
    verify(should_init(state));set_initialized(state,true)
    verify(!should_init(state));verify(should_quit(state));set_initialized(state,false)
    verify(!should_quit(state))
}
def scope_contracts() : $Result<SdlUnit; SdlError> {
    let mutex=create_mutex() |> sdl_try
    let rw=create_rwlock() |> sdl_try
    {
        defer() {SDL_DestroyRWLock(rw);SDL_DestroyMutex(mutex)}
        let result=mutex |> with_mutex_lock() {
            verify(!SDLTestMutexAvailable(mutex))
            return err(SdlError(operation="body",message="original"),type<SdlUnit>)
        }
        verify(is_err(result) && unwrap_err(result).message=="original")
        verify(SDLTestMutexAvailable(mutex))
        let written=rw |> with_rwlock_write() {
            verify(!SDLTestRwlockAvailable(rw,false))
            return err(SdlError(operation="body",message="write failed"),type<int>)
        }
        verify(is_err(written) && SDLTestRwlockAvailable(rw,true))
        var values <- rw |> with_rwlock_read() {
            verify(!SDLTestRwlockAvailable(rw,true))
            var values <- array<int>(2,4,6)
            return <- move_ok(values,type<SdlError>)
        }
        verify(is_ok(values))
        var copied <- move_unwrap(values)
        verify(length(copied)==3 && copied[2]==6)
        verify(SDLTestRwlockAvailable(rw,true))
        let scalar=mutex |> with_mutex_lock() {return ok(42,type<SdlError>)}
        verify(unwrap(scalar)==42 && SDLTestMutexAvailable(mutex))
    }
    var called=false
    let no_mutex=with_mutex_lock(null) {called=true;return sdl_ok()}
    let no_read=with_rwlock_read(null) {called=true;return sdl_ok()}
    let no_write=with_rwlock_write(null) {called=true;return sdl_ok()}
    verify(!called && is_err(no_mutex) && is_err(no_read) && is_err(no_write))
    let owned=sdl_scope() {
        let m : SDL_Mutex? = with_mutex() |> sdl_use
        let r : SDL_RWLock? = with_rwlock() |> sdl_use
        let s : SDL_Semaphore? = with_semaphore(1u) |> sdl_use
        let c : SDL_Condition? = with_condition() |> sdl_use
        verify(m!=null && r!=null && c!=null && SDL_TryWaitSemaphore(s))
        return sdl_ok()
    }
    verify(is_ok(owned))
    var array_scope <- with_semaphore(0u) $(sem) {
        var values <- array<int>(7,8)
        return <- move_ok(values,type<SdlError>)
    }
    verify(is_ok(array_scope))
    var m=create_mutex() |> sdl_try
    var r=create_rwlock() |> sdl_try
    var s=create_semaphore() |> sdl_try
    var c=create_condition() |> sdl_try
    destroy_mutex(m);destroy_rwlock(r);destroy_semaphore(s);destroy_condition(c)
    verify(m==null && r==null && s==null && c==null)
    return sdl_ok()
}
[export]
def main(smoke : bool) : int {
    raw_primitives()
    init_state()
    verify(is_ok(scope_contracts()))
    print("Synchronization: raw API, contention, timeouts, init state and deferred unlock passed.\n")
    return 0
}
