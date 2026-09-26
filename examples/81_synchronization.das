options gen2
require dassdl3/sdl3_synchronization
require dassdl3/sdl3_scope

// Synchronous lock scopes. SDL primitives do not make one daScript Context safe
// to run concurrently; this example creates no worker calling script code.
[export]
def main(smoke : bool) : int {
    var counter = 0
    let result = sdl_scope() {
        let mutex : SDL_Mutex? = with_mutex() |> sdl_use
        let sem : SDL_Semaphore? = with_semaphore(1u) |> sdl_use
        mutex |> with_mutex_lock() {
            counter++
            return sdl_ok()
        } |> sdl_try
        let first = try_wait_semaphore(sem)
        let second = wait_semaphore(sem, 0)
        print("Counter: {counter}; token acquired: {first}; empty queue: {!second}\n")
        SDL_SignalSemaphore(sem)
        return sdl_ok()
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Mutex and semaphore released.\n")
    return 0
}
