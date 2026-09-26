options gen2
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_scope
require daslib/safe_addr
require daslib/defer

def acquire_test_io(iface : SDL_IOStreamInterface; mode : int) : SDL_IOStream? {
    var acquired <- open_io(iface, SDLTestIOReset(mode))
    verify(is_ok(acquired))
    return move_unwrap(acquired)
}

def interface() : SDL_IOStreamInterface {
    var iface = SDL_MakeIOStreamInterface()
    SDL_SetIOStreamInterfaceCallbacks(iface, SDLTestIOCallback(0), SDLTestIOCallback(1), SDLTestIOCallback(2), SDLTestIOCallback(3), SDLTestIOCallback(4), SDLTestIOCallback(5))
    return iface
}
[export]
def main(smoke : bool) : int {
    var bytes <- array<uint8>(0, 1, 2, 3, 4, 5, 6, 7)
    var count = 0ul
    let io = SDL_IOFromDynamicMem()
    verify(io != null && SDL_GetIOProperties(io) != 0u)
    verify(SDL_SetNumberProperty(SDL_GetIOProperties(io), SDL_PROP_IOSTREAM_DYNAMIC_CHUNKSIZE_NUMBER, 64l))
    verify(SDL_GetIOStatus(io) == SDL_IOStatus.IO_STATUS_READY)
    verify(SDL_GetIOSize(io) == 0l)
    unsafe { verify(SDL_WriteIO(io, addr(bytes[0]), 8ul) == 8ul) }
    verify(SDL_TellIO(io) == 8l)
    verify(SDL_SeekIO(io, -2l, SDL_IOWhence.IO_SEEK_END) == 6l)
    var output <- array<uint8>(99, 99, 99, 99)
    let short_read = read_io(io, output, 4ul, count)
    verify(is_ok(short_read) && count == 2ul && output[0] == 6 && output[1] == 7 && output[2] == 99)
    verify(is_ok(read_io(io, output, 4ul, count)) && count == 0ul && SDL_GetIOStatus(io) == SDL_IOStatus.IO_STATUS_EOF)
    verify(is_err(read_io(io, output, 5ul, count)) && count == 0ul)
    verify(is_ok(read_io(io, output, 0ul, count)) && count == 0ul)
    verify(SDL_IOprintfText(io, "100% ready") == 10ul)
    verify(SDL_FlushIO(io))
    verify(SDL_CloseIO(io))
    unsafe {
        let fixed = SDL_IOFromMem(addr(bytes[0]), 8ul)
        verify(fixed != null)
        var value = uint8(99)
        verify(SDL_ReadIO(fixed, addr(value), 1ul) == 1ul && value == 0)
        verify(SDL_CloseIO(fixed))
        let readonly = SDL_IOFromConstMem(addr(bytes[0]), 8ul)
        verify(SDL_WriteIO(readonly, addr(value), 1ul) == 0ul && SDL_GetIOStatus(readonly) == SDL_IOStatus.IO_STATUS_READONLY)
        verify(SDL_CloseIO(readonly))
    }
    let path = "iostream-test-{SDL_GetTicksNS()}.bin"
    {
        defer() {SDL_RemovePath(path)}
        unsafe {
            verify(SDL_SaveFile(path, addr(bytes[0]), 8ul))
            var size = 0ul
            let loaded = SDL_LoadFile(path, addr(size))
            verify(loaded != null && size == 8ul)
            SDL_free(loaded)
            let file = SDL_IOFromFile(path, "rb")
            let data = SDL_LoadFile_IO(file, addr(size), true)
            verify(data != null && size == 8ul)
            SDL_free(data)
            let target = SDL_IOFromFile(path, "wb")
            verify(SDL_SaveFile_IO(target, addr(bytes[0]), 8ul, true))
        }
        var loaded <- load_file(path) |> unwrap
        verify(length(loaded) == 8 && loaded[7] == 7)
        let scoped = with_io_file(path, "rb") $(stream : SDL_IOStream?) {
            verify(io_size(stream) |> unwrap == 8l)
            verify(tell_io(stream) |> unwrap == 0l)
            var values <- load_io(stream) |> sdl_try
            verify(length(values) == 8 && values[6] == 6)
            return sdl_ok()
        }
        verify(is_ok(scoped))
        var empty : array<uint8>
        verify(is_ok(save_file(path, empty)))
        var empty_loaded <- load_file(path) |> unwrap
        verify(length(empty_loaded) == 0)
        verify(is_err(load_file("{path}/missing")))
    }
    var iface = interface()
    let native = SDL_OpenIO(safe_addr(iface), SDLTestIOReset(0))
    verify(native != null)
    iface.version = 0u// SDL copies the interface; existing stream remains valid
    verify(SDL_GetIOSize(native) == 8l && SDL_SeekIO(native, 3l, SDL_IOWhence.IO_SEEK_SET) == 3l)
    verify(SDL_FlushIO(native) && SDL_CloseIO(native) && SDLTestIOCloses() == 1)
    verify(is_err(open_io(iface, SDLTestIOReset(0))))
    iface = interface()
    var pending = acquire_test_io(iface, 1)
    verify(read_io(pending, output, 4ul, count) |> unwrap == SDL_IOStatus.IO_STATUS_NOT_READY)
    verify(count == 2ul && output[0] == 42)
    verify(write_io(pending, bytes, 8ul, count) |> unwrap == SDL_IOStatus.IO_STATUS_NOT_READY)
    verify(count == 2ul)
    verify(is_ok(write_io(pending, bytes, 6ul, count, 2ul)) && count == 2ul)
    verify(is_err(write_io(pending, bytes, 1ul, count, 8ul)) && count == 0ul)
    verify(flush_io(pending) |> unwrap == false)
    verify(is_ok(close_io(pending)) && pending == null && SDLTestIOCloses() == 1)
    var failed = acquire_test_io(iface, 2)
    let compound = read_io(failed, output, 4ul)
    verify(is_err(compound.status) && compound.transferred == 2ul)
    let compound_write = write_io(failed, bytes, 8ul)
    verify(is_err(compound_write.status) && compound_write.transferred == 2ul)
    let partial = read_io(failed, output, 4ul, count)
    verify(is_err(partial) && count == 2ul)
    let saved = unwrap_err(partial)
    verify(is_err(write_io(failed, bytes, 8ul, count)) && count == 2ul)
    verify(is_err(flush_io(failed)))
    verify(is_err(close_io(failed)) && failed == null && SDLTestIOCloses() == 1)
    verify(saved.message == "fixture transfer failure")
    let close_failure = with_io(acquire_test_io(iface, 2)) $(stream : SDL_IOStream?) {return sdl_ok()}
    verify(is_err(close_failure) && unwrap_err(close_failure).operation == "SDL_CloseIO" && SDLTestIOCloses() == 1)
    let body_failure = with_io(acquire_test_io(iface, 2)) $(stream : SDL_IOStream?) {
        return err(SdlError(operation = "body", message = "primary"), type<SdlUnit>)
    }
    verify(is_err(body_failure) && unwrap_err(body_failure).operation == "body" && SDLTestIOCloses() == 1)
    let early = with_io(acquire_test_io(iface, 0)) $(stream : SDL_IOStream?) { return ok(7, type<SdlError>) }
    verify(unwrap(early) == 7 && SDLTestIOCloses() == 1)
    let move_result = with_io_dynamic() $(stream : SDL_IOStream?) {
        save_io(stream, bytes) |> sdl_try
        seek_io(stream, 0l) |> sdl_try
        return <- load_io(stream)
    }
    verify(is_ok(move_result) && length(unwrap(move_result)) == 8)
    // Pinned SDL 3.2.18 SaveFile_IO repeats the second chunk on three short writes.
    var terminal = acquire_test_io(iface, 4)
    verify(is_err(load_io(terminal)))
    verify(is_ok(close_io(terminal)))
    var skipped = false
    let missing = with_io_file("missing-directory/never.bin", "rb") $(stream : SDL_IOStream?) {skipped = true; return sdl_ok()}
    verify(is_err(missing) && !skipped)
    let chunks = acquire_test_io(iface, 3)
    unsafe {verify(SDL_SaveFile_IO(chunks, addr(bytes[0]), 6ul, true))}
    verify(SDLTestIOPinnedShortSave() && SDLTestIOCloses() == 1)
    print("IOStream: bytes, EOF/pending/error, file ownership and native callbacks passed.\n")
    return 0
}
