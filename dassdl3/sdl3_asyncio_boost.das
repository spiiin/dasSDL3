options gen2
module sdl3_asyncio_boost shared public
require dassdl3/sdl3_result public
require daslib/option public
require daslib/defer

def public open_async_io(path, mode : string) {
    var io = SDL_AsyncIOFromFile(path, mode)
    if (io == null) {return err(sdl_error("SDL_AsyncIOFromFile"), type<SDL_AsyncIO?>)}
    return <- move_ok(io, type<SdlError>)
}
def public async_io_size(io : SDL_AsyncIO?) {
    let size = SDL_GetAsyncIOSize(io)
    if (size < 0l) {return err(sdl_error("SDL_GetAsyncIOSize"), type<int64>)}
    return ok(size, type<SdlError>)
}
// Pointers must remain valid and buffers must not move until completion or queue drain.
def public read_async_io(io : SDL_AsyncIO?; buffer : void?; offset, size : uint64; queue : SDL_AsyncIOQueue?; userdata : void?) {
    return sdl_status(SDL_ReadAsyncIO(io, buffer, offset, size, queue, userdata), "SDL_ReadAsyncIO")
}
def public write_async_io(io : SDL_AsyncIO?; buffer : void?; offset, size : uint64; queue : SDL_AsyncIOQueue?; userdata : void?) {
    return sdl_status(SDL_WriteAsyncIO(io, buffer, offset, size, queue, userdata), "SDL_WriteAsyncIO")
}
// Successful submission consumes io immediately; completion remains on the queue.
def public close_async_io(var io : SDL_AsyncIO?&; flush : bool; queue : SDL_AsyncIOQueue?; userdata : void?) {
    return sdl_status(SDL_CloseAsyncIORef(io, flush, queue, userdata), "SDL_CloseAsyncIO")
}
def public create_async_io_queue() {
    var queue = SDL_CreateAsyncIOQueue()
    if (queue == null) {return err(sdl_error("SDL_CreateAsyncIOQueue"), type<SDL_AsyncIOQueue?>)}
    return <- move_ok(queue, type<SdlError>)
}
// None includes empty, timeout, signal and spurious wake. A task FAILURE stays an outcome.
def public get_async_io_result(queue : SDL_AsyncIOQueue?) {
    var outcome : SDL_AsyncIOOutcome
    if (!SDL_GetAsyncIOResultRef(queue, outcome)) {return none(type<SDL_AsyncIOOutcome>)}
    return some(outcome)
}
def public wait_async_io_result(queue : SDL_AsyncIOQueue?; timeout_ms : int) {
    var outcome : SDL_AsyncIOOutcome
    if (!SDL_WaitAsyncIOResultRef(queue, outcome, timeout_ms)) {return none(type<SDL_AsyncIOOutcome>)}
    return some(outcome)
}
def public load_file_async(path : string; queue : SDL_AsyncIOQueue?; userdata : void?) {
    return sdl_status(SDL_LoadFileAsync(path, queue, userdata), "SDL_LoadFileAsync")
}
// Consumes one original LoadFileAsync outcome, including failure/cancellation buffers.
def public take_async_file_bytes(var outcome : SDL_AsyncIOOutcome&) {
    var bytes : array<uint8>
    if (!SDL_TakeAsyncFileBytes(outcome, bytes)) {return err(sdl_error("SDL_TakeAsyncFileBytes"), type<array<uint8>>)}
    return <- move_ok(bytes, type<SdlError>)
}
// No other thread may be waiting when this scope ends. Drain does not close arbitrary io.
def public with_async_io_queue(body : block<(queue : SDL_AsyncIOQueue?) : $Result<auto(TT); SdlError>>) {
    let queue = SDL_CreateAsyncIOQueue()
    if (queue == null) {return err(sdl_error("SDL_CreateAsyncIOQueue"), type<TT>)}
    {
        defer() {SDL_DestroyAsyncIOQueue(queue)}
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) {return body(queue)}
        else {return <- body(queue)}
    }
}
