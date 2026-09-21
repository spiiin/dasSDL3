options gen2
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_scope

def roundtrip() : $Result<SdlUnit; SdlError> {
    return sdl_scope() {
        let stream : SDL_IOStream? = with_io_dynamic() |> sdl_use
        var bytes <- array<uint8>(83,68,76,0,51)
        var transferred=0ul
        let written=stream |> write_io(bytes,uint64(length(bytes)),transferred) |> sdl_try
        print("Write: {transferred} bytes, status {written}\n")
        stream |> seek_io(0l) |> sdl_try
        var output : array<uint8>
        resize(output,16)
        let status=stream |> read_io(output,16ul,transferred) |> sdl_try
        print("Read: {transferred} bytes, status {status}; embedded zero: {output[3]}\n")
        let end=stream |> read_io(output,16ul,transferred) |> sdl_try
        print("Next read: {transferred} bytes, status {end}\n")
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
