options gen2
require dassdl3/sdl3_filesystem_boost
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_try

def check(write : bool) : SdlStatus {
    let wav <- load_file("assets/tone.wav") |> sdl_try
    if (length(wav) < 12 || wav[0] != 82 || wav[1] != 73 || wav[2] != 70 || wav[3] != 70 ||
        wav[8] != 87 || wav[9] != 65 || wav[10] != 86 || wav[11] != 69) {
        return err(SdlError(operation = "read APK asset", message = "Expected RIFF/WAVE"), type<SdlUnit>)
    }
    let directory = pref_path("dasSDL3", "Android Smoke") |> sdl_try
    let path = "{directory}restart.bin"
    var expected <- array<uint8>(0, 17, 255, 42, 128, 0, 73)
    if (write) { return save_file(path, expected) }
    let bytes <- load_file(path) |> sdl_try
    if (length(bytes) != length(expected)) {
        return err(SdlError(operation = "read preferences", message = "Size mismatch"), type<SdlUnit>)
    }
    for (i in range(length(bytes))) {
        if (bytes[i] != expected[i]) {
            return err(SdlError(operation = "read preferences", message = "Byte mismatch"), type<SdlUnit>)
        }
    }
    return sdl_ok()
}

[export]
def main(write : bool) : int {
    let result = check(write)
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
