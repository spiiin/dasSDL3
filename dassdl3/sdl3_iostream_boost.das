options gen2
module sdl3_iostream_boost shared public
require dassdl3/sdl3_result public
require daslib/defer

def public open_io_file(path,mode : string) {
    var io=SDL_IOFromFile(path,mode)
    if(io==null) { return err(sdl_error("SDL_IOFromFile"),type<SDL_IOStream?>) }
    return <- move_ok(io,type<SdlError>)
}
def public open_io_dynamic() {
    var io=SDL_IOFromDynamicMem()
    if(io==null) { return err(sdl_error("SDL_IOFromDynamicMem"),type<SDL_IOStream?>) }
    return <- move_ok(io,type<SdlError>)
}
def public open_io(iface : SDL_IOStreamInterface; userdata : void?) {
    var io=SDL_OpenIORef(iface,userdata)
    if(io==null) { return err(sdl_error("SDL_OpenIO"),type<SDL_IOStream?>) }
    return <- move_ok(io,type<SdlError>)
}
// Consumes the caller's pointer even when closing fails.
def public close_io(var io : SDL_IOStream?&) { return sdl_status(SDL_CloseIORef(io),"SDL_CloseIO") }
// Ok(false) means temporary NOT_READY, not successful flushing.
def public flush_io(io : SDL_IOStream?) {
    if(SDL_FlushIO(io)) { return ok(true,type<SdlError>) }
    let error=sdl_error("SDL_FlushIO")
    if(SDL_GetIOStatus(io)==SDL_IOStatus.IO_STATUS_NOT_READY) { return ok(false,type<SdlError>) }
    return err(error,type<bool>)
}
def public io_size(io : SDL_IOStream?) {
    let value=SDL_GetIOSize(io)
    if(value<0l) {return err(sdl_error("SDL_GetIOSize"),type<int64>)}
    return ok(value,type<SdlError>)
}
def public tell_io(io : SDL_IOStream?) {
    let value=SDL_TellIO(io)
    if(value<0l) {return err(sdl_error("SDL_TellIO"),type<int64>)}
    return ok(value,type<SdlError>)
}
def public seek_io(io : SDL_IOStream?; offset : int64; whence : SDL_IOWhence = SDL_IOWhence.IO_SEEK_SET) {
    let value=SDL_SeekIO(io,offset,whence)
    if(value<0l) {return err(sdl_error("SDL_SeekIO"),type<int64>)}
    return ok(value,type<SdlError>)
}
// transferred remains available on Err; READY, EOF and NOT_READY are returned as values.
def public read_io(io : SDL_IOStream?; var bytes : array<uint8>; count : uint64; var transferred : uint64&; offset : uint64 = 0ul) {
    var status : SDL_IOStatus
    if(!SDL_ReadIOArray(io,bytes,count,transferred,status,offset)) { return err(sdl_error("SDL_ReadIO"),type<SDL_IOStatus>) }
    return ok(status,type<SdlError>)
}
// transferred remains available on Err; READY, EOF and NOT_READY are returned as values.
def public write_io(io : SDL_IOStream?; bytes : array<uint8>; count : uint64; var transferred : uint64&; offset : uint64 = 0ul) {
    var status : SDL_IOStatus
    if(!SDL_WriteIOArray(io,bytes,count,transferred,status,offset)) { return err(sdl_error("SDL_WriteIO"),type<SDL_IOStatus>) }
    return ok(status,type<SdlError>)
}
def public load_file(path : string) {
    var bytes : array<uint8>
    if(!SDL_LoadFileCopy(path,bytes)) {return err(sdl_error("load_file"),type<array<uint8>>)}
    return <- move_ok(bytes,type<SdlError>)
}
def public load_io(io : SDL_IOStream?) {
    var bytes : array<uint8>
    if(!SDL_LoadFileIOCopy(io,bytes)) {return err(sdl_error("load_io"),type<array<uint8>>)}
    return <- move_ok(bytes,type<SdlError>)
}
def public save_file(path : string; bytes : array<uint8>) {return sdl_status(SDL_SaveFileArray(path,bytes),"SDL_SaveFile")}
def public save_io(io : SDL_IOStream?; bytes : array<uint8>) {return sdl_status(SDL_SaveFileIOArray(io,bytes),"SDL_SaveFile_IO")}
// Takes ownership of io. A successful body result is replaced only by a close failure.
def public with_io(io : SDL_IOStream?; body : block<(stream : SDL_IOStream?) : $Result<auto(TT); SdlError>>) {
    if(io==null) {return err(SdlError(operation="with_io",message="Null IOStream"),type<TT>)}
    var result : $Result<TT; SdlError>
    {
        defer() {
            let closed=SDL_CloseIO(io)
            if(!closed && is_ok(result)) { result <- err(sdl_error("SDL_CloseIO"),type<TT>) }
        }
        static_if(typeinfo can_copy(type<$Result<TT; SdlError>>)) {result=body(io)}
        else {result <- body(io)}
    }
    return <- result
}
def public with_io_file(path,mode : string; body : block<(stream : SDL_IOStream?) : $Result<auto(TT); SdlError>>) {
    var io=SDL_IOFromFile(path,mode)
    if(io==null) {return err(sdl_error("SDL_IOFromFile"),type<TT>)}
    return <- with_io(io,body)
}
def public with_io_dynamic(body : block<(stream : SDL_IOStream?) : $Result<auto(TT); SdlError>>) {
    var io=SDL_IOFromDynamicMem()
    if(io==null) {return err(sdl_error("SDL_IOFromDynamicMem"),type<TT>)}
    return <- with_io(io,body)
}

// Partial byte counts are observable even if status is Err.
struct IoTransfer { transferred : uint64; status : $Result<SDL_IOStatus;SdlError> }
def public read_io(io : SDL_IOStream?; var bytes : array<uint8>; count : uint64) : IoTransfer {
    var value : IoTransfer
    value.status=read_io(io,bytes,count,value.transferred,0ul)
    return value
}
def public write_io(io : SDL_IOStream?; bytes : array<uint8>; count : uint64) : IoTransfer {
    var value : IoTransfer
    value.status=write_io(io,bytes,count,value.transferred,0ul)
    return value
}
