options gen2
module sdl3_thread_atomic shared public
require dassdl3/sdl3_boost public
require daslib/defer

// fn/destructor are native C addresses, never daScript blocks/functions.
def public create_thread(fn : void?; name : string; data : void? = null) {
    var value=SDL_CreateThreadNative(fn,name,data)
    if(value==null) {return err(sdl_error("SDL_CreateThread"),type<SDL_Thread?>)}
    return <- move_ok(value,type<SdlError>)
}
def public create_thread(props : uint) {
    var value=SDL_CreateThreadWithPropertiesNative(props)
    if(value==null) {return err(sdl_error("SDL_CreateThreadWithProperties"),type<SDL_Thread?>)}
    return <- move_ok(value,type<SdlError>)
}
// join/detach consume the owning pointer. A detached worker still owns its work.
def public join_thread(var thread : SDL_Thread?&) : int {let status=SDL_WaitThreadRef(thread);thread=null;return status}
def public detach_thread(var thread : SDL_Thread?&) {SDL_DetachThread(thread);thread=null}
def public with_thread(fn : void?; name : string; data : void?; blk : block<(thread : SDL_Thread?) : $Result<auto(T); SdlError>>) {
    let thread=SDL_CreateThreadNative(fn,name,data)
    if(thread==null) {return err(sdl_error("SDL_CreateThread"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_WaitThread(thread,null)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=blk(thread)} else {result <- blk(thread)}
    }
    return <- result
}
// SDL_TLSID is an alias of SDL_AtomicInt. Keep one zero-initialized, stable ID.
// Non-owning payload avoids the pinned compiler's generic void-pointer collision.
struct public SdlTlsValue {
    address : void?
}
def public get_tls(var id : SDL_AtomicInt&) {
    let value=SDL_GetTLSRef(id)
    if(value==null) {return none(type<SdlTlsValue>)}
    return some(SdlTlsValue(address=value))
}
def public set_tls(var id : SDL_AtomicInt&; value : void?; destructor : void? = null) {
    if(!SDL_SetTLSRef(id,value,destructor)) {return err(sdl_error("SDL_SetTLS"),type<SdlUnit>)}
    return sdl_ok()
}
def public atomic_get(var value : SDL_AtomicInt&) {return SDL_GetAtomicIntRef(value)}
def public atomic_get(var value : SDL_AtomicU32&) {return SDL_GetAtomicU32Ref(value)}
def public atomic_get(var value : void?&) {return SDL_GetAtomicPointerRef(value)}
def public atomic_set(var value : SDL_AtomicInt&; next : int) {return SDL_SetAtomicIntRef(value,next)}
def public atomic_set(var value : SDL_AtomicU32&; next : uint) {return SDL_SetAtomicU32Ref(value,next)}
def public atomic_set(var value : void?&; next : void?) {return SDL_SetAtomicPointerRef(value,next)}
def public atomic_add(var value : SDL_AtomicInt&; next : int) {return SDL_AddAtomicIntRef(value,next)}
def public atomic_compare_exchange(var value : SDL_AtomicInt&; expected : int; next : int) : bool {return SDL_CompareAndSwapAtomicIntRef(value,expected,next)}
def public atomic_compare_exchange(var value : SDL_AtomicU32&; expected : uint; next : uint) : bool {return SDL_CompareAndSwapAtomicU32Ref(value,expected,next)}
def public atomic_compare_exchange(var value : void?&; expected : void?; next : void?) : bool {return SDL_CompareAndSwapAtomicPointerRef(value,expected,next)}
