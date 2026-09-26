options gen2
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_scope

def roundtrip() : SdlStatus {
    return sdl_scope() {
        let stream : SDL_IOStream? = with_io_dynamic() |> sdl_use
        var bytes <- array<uint8>(83,68,76,0,51)
        let write=stream |> write_io(bytes,uint64(length(bytes)))
        let written=write.status |> sdl_try
        print("Write: {write.transferred} bytes, status {written}\n")
        stream |> seek_io(0l) |> sdl_try
        var output : array<uint8>
        resize(output,16)
        let read=stream |> read_io(output,16ul)
        let status=read.status |> sdl_try
        print("Read: {read.transferred} bytes, status {status}; embedded zero: {output[3]}\n")
        let last=stream |> read_io(output,16ul)
        let end=last.status |> sdl_try
        print("Next read: {last.transferred} bytes, status {end}\n")
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result=roundtrip()
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    print("Stream closed.\n")
    return 0
}
