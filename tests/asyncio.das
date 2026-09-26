options gen2
require dassdl3/sdl3_asyncio_boost
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_scope
require daslib/safe_addr
require daslib/defer

def completed(queue : SDL_AsyncIOQueue?) : SDL_AsyncIOOutcome {
    let deadline = SDL_GetTicks() + 5000ul
    var outcome : SDL_AsyncIOOutcome
    while (SDL_GetTicks() < deadline) {
        unsafe {if (SDL_WaitAsyncIOResult(queue, addr(outcome), 100)) {return outcome}}
    }
    verify(false, "Async completion timed out")
    return outcome
}
[export]
def main(smoke : bool) : int {
    let path = "asyncio-test-{SDL_GetTicksNS()}.bin"
    defer() {SDL_RemovePath(path)}
    var source <- array<uint8>(11, 22, 33, 44)
    verify(is_ok(save_file(path, source)))
    verify(is_err(open_async_io(path, "a")))
    verify(is_err(open_async_io("missing-asyncio-{SDL_GetTicksNS()}", "r")))
    let queue = SDL_CreateAsyncIOQueue()
    verify(queue != null)
    {
        defer() {SDL_DestroyAsyncIOQueue(queue)}
        var outcome : SDL_AsyncIOOutcome
        SDL_SetErrorText("stale unrelated error")
        unsafe {verify(!SDL_GetAsyncIOResult(queue, addr(outcome)))}
        verify(is_none(get_async_io_result(queue)))
        verify(is_none(wait_async_io_result(queue, 1)))
        SDL_SignalAsyncIOQueue(queue)
        verify(is_none(wait_async_io_result(queue, 0)))
        let io = SDL_AsyncIOFromFile(path, "w+")
        verify(io != null && SDL_GetAsyncIOSize(io) == 0l)
        // These arrays remain unchanged and in this scope until the close completes.
        unsafe {verify(SDL_WriteAsyncIO(io, addr(source[0]), 0ul, 4ul, queue, addr(source[0])))}
        outcome = completed(queue)
        verify(outcome.task_type == SDL_AsyncIOTaskType.ASYNCIO_TASK_WRITE && outcome.result == SDL_AsyncIOResult.ASYNCIO_COMPLETE)
        verify(outcome.asyncio == io && outcome.bytes_requested == 4ul && outcome.bytes_transferred == 4ul && outcome.offset == 0ul)
        unsafe {verify(outcome.buffer == addr(source[0]) && outcome.userdata == addr(source[0]))}
        verify(is_ok(async_io_size(io)) && SDL_GetAsyncIOSize(io) == 4l)
        var target <- array<uint8>(99, 99, 99, 99, 99, 99, 99, 99)
        unsafe {verify(SDL_ReadAsyncIO(io, addr(target[0]), 1ul, 8ul, queue, null))}
        // Close may be submitted with outstanding work; its outcome must come last.
        verify(SDL_CloseAsyncIO(io, true, queue, null))
        outcome = completed(queue)
        verify(outcome.task_type == SDL_AsyncIOTaskType.ASYNCIO_TASK_READ)
        // Pinned generic backend can report FAILURE for a positive short read (READY IO status).
        verify(outcome.result == SDL_AsyncIOResult.ASYNCIO_COMPLETE || outcome.result == SDL_AsyncIOResult.ASYNCIO_FAILURE)
        print("Short read status: {outcome.result}, transferred: {outcome.bytes_transferred}\n")
        verify(outcome.offset == 1ul && outcome.bytes_requested == 8ul && outcome.bytes_transferred == 3ul)
        verify(target[0] == 22 && target[1] == 33 && target[2] == 44 && target[3] == 99)
        outcome = completed(queue)
        verify(outcome.task_type == SDL_AsyncIOTaskType.ASYNCIO_TASK_CLOSE && outcome.result == SDL_AsyncIOResult.ASYNCIO_COMPLETE)
        // io/outcome.asyncio must never be dereferenced after close submission.
        var reopened <- open_async_io(path, "r+")
        var owned = move_unwrap(reopened)
        let original = owned
        verify(is_err(close_async_io(owned, false, null, null)) && owned == original)
        verify(SDL_GetAsyncIOSize(owned) == 4l)
        unsafe {verify(is_ok(write_async_io(owned, addr(source[0]), 0ul, 4ul, queue, null)))}
        outcome = completed(queue)
        verify(outcome.result == SDL_AsyncIOResult.ASYNCIO_COMPLETE)
        unsafe {verify(is_ok(read_async_io(owned, addr(target[0]), 1ul, 3ul, queue, null)))}
        outcome = completed(queue)
        verify(outcome.result == SDL_AsyncIOResult.ASYNCIO_COMPLETE && outcome.bytes_transferred == 3ul)
        verify(target[0] == 22 && target[1] == 33 && target[2] == 44)
        unsafe {verify(is_ok(read_async_io(owned, addr(target[0]), 4ul, 1ul, queue, null)))}
        outcome = completed(queue)
        verify(outcome.result == SDL_AsyncIOResult.ASYNCIO_COMPLETE && outcome.bytes_transferred == 0ul)
        verify(is_ok(close_async_io(owned, false, queue, null)) && owned == null)
        verify(is_err(close_async_io(owned, false, queue, null)))
        outcome = completed(queue)
        verify(outcome.task_type == SDL_AsyncIOTaskType.ASYNCIO_TASK_CLOSE)
        verify(!SDL_LoadFileAsync("missing-asyncio-{SDL_GetTicksNS()}", queue, null))
        verify(SDL_LoadFileAsync(path, queue, null))
        outcome = completed(queue)
        verify(outcome.asyncio == null && outcome.task_type == SDL_AsyncIOTaskType.ASYNCIO_TASK_READ)
        var loaded <- take_async_file_bytes(outcome)
        verify(is_ok(loaded) && outcome.buffer == null)
        var bytes <- move_unwrap(loaded)
        verify(length(bytes) == 4 && bytes[0] == 11 && bytes[3] == 44)
        verify(is_err(take_async_file_bytes(outcome)))
        // Actual allocation, synthetic statuses: exercise consumption on both error branches.
        for (status in fixed_array(SDL_AsyncIOResult.ASYNCIO_FAILURE, SDL_AsyncIOResult.ASYNCIO_CANCELED)) {
            verify(is_ok(load_file_async(path, queue, null)))
            outcome = completed(queue)
            outcome.result = status
            SDL_SetErrorText("stale error must not become task error")
            var failed <- take_async_file_bytes(outcome)
            verify(is_err(failed) && outcome.buffer == null)
            verify(unwrap_err(failed).message != "stale error must not become task error")
        }
        verify(is_ok(load_file_async(path, queue, null)))
        outcome = completed(queue)
        outcome.bytes_transferred = outcome.bytes_requested + 1ul
        verify(is_err(take_async_file_bytes(outcome)) && outcome.buffer == null)
        // Queue drain owns unretrieved oneshot buffers, including this pending load.
        verify(is_ok(load_file_async(path, queue, null)))
    }
    var empty : array<uint8>
    verify(is_ok(save_file(path, empty)))
    var scoped <- sdl_scope() {
        let q : SDL_AsyncIOQueue? = with_async_io_queue() |> sdl_use
        load_file_async(path, q, null) |> sdl_try
        var result = completed(q)
        return <- take_async_file_bytes(result)
    }
    verify(is_ok(scoped))
    var empty_result <- move_unwrap(scoped)
    verify(length(empty_result) == 0)
    let propagated = with_async_io_queue() $(q) {
        verify(SDL_LoadFileAsync(path, q, null))
        return err(SdlError(operation = "body", message = "primary"), type<SdlUnit>)
    }
    verify(is_err(propagated) && unwrap_err(propagated).operation == "body")
    var no_outcome = SDL_AsyncIOOutcome(bytes_transferred = 99ul)
    verify(!SDL_GetAsyncIOResultRef(null, no_outcome) && no_outcome.bytes_transferred == 0ul)
    no_outcome.bytes_transferred = 99ul
    verify(!SDL_WaitAsyncIOResultRef(null, no_outcome, 0) && no_outcome.bytes_transferred == 0ul)
    var created <- create_async_io_queue()
    verify(is_ok(created))
    SDL_DestroyAsyncIOQueue(move_unwrap(created))
    print("AsyncIO: submission, raw completion, short reads, close order, owned file bytes and queue drain passed.\n")
    return 0
}
