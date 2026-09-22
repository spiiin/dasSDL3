options gen2
require dassdl3/sdl3_thread_atomic

// Atomics operate on stable storage; copying the struct is not an atomic read.
// Creating workers requires native C callbacks, not daScript blocks.
[export]
def main(smoke : bool) : int {
    var counter : SDL_AtomicInt
    let previous=atomic_add(counter,5)
    let exchanged=atomic_compare_exchange(counter,5,10)
    let current=atomic_get(counter)
    print("Counter: {previous} -> {current}; exchanged: {exchanged}\n")
    var flags : SDL_AtomicU32
    atomic_set(flags,0x80000000u)
    print("Flags: {atomic_get(flags)}\n")
    return 0
}
