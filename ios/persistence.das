options gen2
require dassdl3/sdl3_filesystem_boost
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_try

def check_save(write : bool) : SdlStatus {
    let directory = pref_path("dasSDL3", "iPhone Smoke") |> sdl_try
    let path = "{directory}restart-check.bin"
    var expected <- array<uint8>(0, 17, 255, 42, 128, 0, 73)
    if (write) {
        return save_file(path, expected)
    }
    // The read phase never creates or repairs the file.
    var actual <- load_file(path) |> sdl_try
    if (length(actual) != length(expected)) {
        return err(SdlError(operation = "restart check", message = "Wrong file length"), type<SdlUnit>)
    }
    for (index in range(length(expected))) {
        if (actual[index] != expected[index]) {
            return err(SdlError(operation = "restart check", message = "Saved bytes differ"), type<SdlUnit>)
        }
    }
    return sdl_ok()
}

[export]
def main(write : bool) : int {
    let result = check_save(write)
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
