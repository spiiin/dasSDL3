options gen2
module sdl3_synchronization shared public
require dassdl3/sdl3_boost public
require daslib/defer

// Factories own one native primitive. Destroy only after every user has finished.
def public create_mutex() {
    var value=SDL_CreateMutex()
    if(value==null) {return err(sdl_error("SDL_CreateMutex"),type<SDL_Mutex?>)}
    return <- move_ok(value,type<SdlError>)
}
def public destroy_mutex(var value : SDL_Mutex?&) {SDL_DestroyMutex(value);value=null}
def public with_mutex(blk : block<(value : SDL_Mutex?) : $Result<auto(T); SdlError>>) {
    var value=SDL_CreateMutex()
    if(value==null) {return err(sdl_error("SDL_CreateMutex"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_DestroyMutex(value)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk(value)} else {result <- blk(value)}
    }
    return <- result
}

def public create_rwlock() {
    var value=SDL_CreateRWLock()
    if(value==null) {return err(sdl_error("SDL_CreateRWLock"),type<SDL_RWLock?>)}
    return <- move_ok(value,type<SdlError>)
}
def public destroy_rwlock(var value : SDL_RWLock?&) {SDL_DestroyRWLock(value);value=null}
def public with_rwlock(blk : block<(value : SDL_RWLock?) : $Result<auto(T); SdlError>>) {
    var value=SDL_CreateRWLock()
    if(value==null) {return err(sdl_error("SDL_CreateRWLock"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_DestroyRWLock(value)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk(value)} else {result <- blk(value)}
    }
    return <- result
}

def public create_semaphore(initial_value : uint = 0u) {
    var value=SDL_CreateSemaphore(initial_value)
    if(value==null) {return err(sdl_error("SDL_CreateSemaphore"),type<SDL_Semaphore?>)}
    return <- move_ok(value,type<SdlError>)
}
def public destroy_semaphore(var value : SDL_Semaphore?&) {SDL_DestroySemaphore(value);value=null}
def public with_semaphore(initial_value : uint = 0u; blk : block<(value : SDL_Semaphore?) : $Result<auto(T); SdlError>>) {
    var value=SDL_CreateSemaphore(initial_value)
    if(value==null) {return err(sdl_error("SDL_CreateSemaphore"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_DestroySemaphore(value)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk(value)} else {result <- blk(value)}
    }
    return <- result
}

def public create_condition() {
    var value=SDL_CreateCondition()
    if(value==null) {return err(sdl_error("SDL_CreateCondition"),type<SDL_Condition?>)}
    return <- move_ok(value,type<SdlError>)
}
def public destroy_condition(var value : SDL_Condition?&) {SDL_DestroyCondition(value);value=null}
def public with_condition(blk : block<(value : SDL_Condition?) : $Result<auto(T); SdlError>>) {
    var value=SDL_CreateCondition()
    if(value==null) {return err(sdl_error("SDL_CreateCondition"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_DestroyCondition(value)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk(value)} else {result <- blk(value)}
    }
    return <- result
}

// Synchronous scope only: enter and leave on the same thread; do not unlock in the body.
def public with_mutex_lock(value : SDL_Mutex?; blk : block<() : $Result<auto(T); SdlError>>) {
    if(value==null) {return err(SdlError(operation="with_mutex_lock",message="Null synchronization object"),type<T>)}
    SDL_LockMutex(value)
    var result : $Result<T; SdlError>
    {
        defer() {SDL_UnlockMutex(value)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk()} else {result <- blk()}
    }
    return <- result
}

// Synchronous scope only: enter and leave on the same thread; do not unlock in the body.
def public with_rwlock_read(value : SDL_RWLock?; blk : block<() : $Result<auto(T); SdlError>>) {
    if(value==null) {return err(SdlError(operation="with_rwlock_read",message="Null synchronization object"),type<T>)}
    SDL_LockRWLockForReading(value)
    var result : $Result<T; SdlError>
    {
        defer() {SDL_UnlockRWLock(value)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk()} else {result <- blk()}
    }
    return <- result
}

// Synchronous scope only: enter and leave on the same thread; do not unlock in the body.
def public with_rwlock_write(value : SDL_RWLock?; blk : block<() : $Result<auto(T); SdlError>>) {
    if(value==null) {return err(SdlError(operation="with_rwlock_write",message="Null synchronization object"),type<T>)}
    SDL_LockRWLockForWriting(value)
    var result : $Result<T; SdlError>
    {
        defer() {SDL_UnlockRWLock(value)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk()} else {result <- blk()}
    }
    return <- result
}

// false means busy/timeout; never inspect a stale SDL_GetError for these predicates.
def public try_lock_mutex(value : SDL_Mutex?) : bool {return SDL_TryLockMutex(value)}
def public try_lock_rwlock_read(value : SDL_RWLock?) : bool {return SDL_TryLockRWLockForReading(value)}
def public try_lock_rwlock_write(value : SDL_RWLock?) : bool {return SDL_TryLockRWLockForWriting(value)}
def public try_wait_semaphore(value : SDL_Semaphore?) : bool {return SDL_TryWaitSemaphore(value)}
def public wait_semaphore(value : SDL_Semaphore?; timeout_ms : int) : bool {return SDL_WaitSemaphoreTimeout(value,timeout_ms)}
def public wait_condition(value : SDL_Condition?; mutex : SDL_Mutex?; timeout_ms : int) : bool {return SDL_WaitConditionTimeout(value,mutex,timeout_ms)}
// A successful claim must always be completed with set_initialized on this state.
def public should_init(var state : SDL_InitState&) : bool {return SDL_ShouldInitRef(state)}
def public should_quit(var state : SDL_InitState&) : bool {return SDL_ShouldQuitRef(state)}
def public set_initialized(var state : SDL_InitState&; initialized : bool) {SDL_SetInitializedRef(state,initialized)}
