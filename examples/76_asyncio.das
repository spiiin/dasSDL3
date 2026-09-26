options gen2
require dassdl3/sdl3_asyncio_boost
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_scope
require daslib/defer

def example() : SdlStatus {
    let path = "asyncio-example-{SDL_GetTicksNS()}.bin"
    defer() {SDL_RemovePath(path)}
    var expected <- array<uint8>(10, 20, 30, 40)
    save_file(path, expected) |> sdl_try
    return sdl_scope() {
        let queue : SDL_AsyncIOQueue? = with_async_io_queue() |> sdl_use
        load_file_async(path, queue, null) |> sdl_try
        let deadline = SDL_GetTicks() + 5000ul
        while (SDL_GetTicks() < deadline) {
            var completion <- queue |> wait_async_io_result(100)
            if (is_none(completion)) {continue}
            var outcome = move_unwrap(completion)
            // Consumes the SDL buffer on success, failure or cancellation.
            let bytes <- take_async_file_bytes(outcome) |> sdl_try
            print("Asynchronously loaded {length(bytes)} bytes:\n")
            for (value in bytes) {print("  {uint(value)}\n")}
            return sdl_ok()
        }
        return err(SdlError(operation = "example", message = "Async load deadline expired"), type<SdlUnit>)
    }
}
[export]
def main(smoke : bool) : int {
    let result = example()
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    return 0
}
