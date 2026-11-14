options gen2
require dassdl3/sdl3_storage_boost
require dassdl3/sdl3_try

def check_title() : SdlStatus {
    var default_path : string
    return with_title_storage(default_path, 0u) $(storage : SDL_Storage?) {
        if (!storage_ready(storage)) {
            return err(SdlError(operation = "Title storage", message = "Storage is not ready"), type<SdlUnit>)
        }
        let wav <- load_storage_file(storage, "assets/tone.wav") |> sdl_try
        if (length(wav) < 12 || wav[0] != 82 || wav[1] != 73 || wav[2] != 70 || wav[3] != 70 ||
            wav[8] != 87 || wav[9] != 65 || wav[10] != 86 || wav[11] != 69) {
            return err(SdlError(operation = "Title storage", message = "Expected bundled RIFF/WAVE data"), type<SdlUnit>)
        }
        var fixture <- array<uint8>(1)
        if (is_ok(write_storage_file(storage, "storage-test-forbidden.bin", fixture))) {
            return err(SdlError(operation = "Title storage", message = "Write unexpectedly succeeded"), type<SdlUnit>)
        }
        print("SDL title storage read the bundled WAV and rejected a write.\n")
        return sdl_ok()
    }
}

def check_user(write : bool) : SdlStatus {
    return with_user_storage("dasSDL3", "iPhone Storage Smoke", 0u) $(storage : SDL_Storage?) {
        if (!storage_ready(storage)) {
            return err(SdlError(operation = "User storage", message = "Storage is not ready"), type<SdlUnit>)
        }
        let path = "résumé.bin"
        var expected <- array<uint8>(0, 17, 255, 42, 128, 0, 73)
        if (write) { return write_storage_file(storage, path, expected) }
        let actual <- load_storage_file(storage, path) |> sdl_try
        if (length(actual) != length(expected)) {
            return err(SdlError(operation = "User storage", message = "Wrong saved file length"), type<SdlUnit>)
        }
        for (index in range(length(expected))) {
            if (actual[index] != expected[index]) {
                return err(SdlError(operation = "User storage", message = "Saved bytes differ"), type<SdlUnit>)
            }
        }
        return remove_storage_path(storage, path)
    }
}

def check_storage(write : bool) : SdlStatus {
    check_title() |> sdl_try
    return check_user(write)
}

[export]
def main(write : bool) : int {
    let result = check_storage(write)
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
