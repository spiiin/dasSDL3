options gen2
module sdl_recording
require dassdl3/sdl3_boost
require dassdl3/sdl3_renderer_state_boost
require dassdl3/sdl3_pixels_boost
require dassdl3/sdl3_try
require sdl3_live_demo
require live/live_commands
require live_host
require daslib/json_boost
require stbimage
require imgui

var writer : void?
var frames = 0
var dimensions : int2
var rate = 20
var cap = 400
var filename : string
var previous_level = 0
var failure : string

[live_command(description = "Finalize SDL APNG capture")]
def record_stop(input : JsonValue?) : JsonValue? {
    if (writer == null) { return JV((error = "not recording")) }
    let dropped = stbi_apng_dropped(writer)
    let saved = stbi_apng_end(writer) != 0
    writer = null
    stbi_write_set_png_compression_level(previous_level)
    set_fixed_dt(0.0)
    return JV((saved = filename, frames = frames, dropped = dropped, duration_s = float(frames) / float(rate), ok = saved && empty(failure), error = failure))
}

[live_command(description = "Start SDL APNG: file, fps and max_seconds in 1..60")]
def record_start(input : JsonValue?) : JsonValue? {
    if (writer != null) { return JV((error = "already recording")) }
    let path = input?["file"] ?? "record.apng"
    let fps = input?["fps"] ?? 20
    let seconds = input?["max_seconds"] ?? 20
    if (fps < 1 || fps > 60 || seconds < 1 || seconds > 60) { return JV((error = "fps and max_seconds must be in 1..60")) }
    let result = render_output_size(demo_renderer())
    if (is_err(result)) { return JV((error = unwrap_err(result).message)) }
    let size = unwrap(result)
    if (size.x <= 0 || size.y <= 0 || int64(size.x) * int64(size.y) > 16777216l) { return JV((error = "invalid framebuffer")) }
    let acquired = stbi_apng_begin(path, size.x, size.y, 4)
    if (acquired == null) { return JV((error = "cannot open recording file")) }
    writer = acquired
    filename = path
    dimensions = size
    rate = fps
    cap = fps * seconds
    frames = 0
    failure = ""
    previous_level = stbi_write_get_png_compression_level()
    stbi_write_set_png_compression_level(4)
    set_fixed_dt(1.0 / float(rate))
    return JV((file = filename, fps = rate, width = size.x, height = size.y, max_seconds = seconds))
}

[live_command(description = "SDL captured-frame counter")]
def record_status(input : JsonValue?) : JsonValue? {
    return JV((active = writer != null, file = filename, frames = frames, elapsed_s = float(frames) / float(rate), fps = rate, width = dimensions.x, height = dimensions.y, dropped = 0, error = failure))
}

def public recording_shutdown() {
    if (writer != null) { record_stop(null) }
}

def public recording_frame(renderer : SDL_Renderer?) {
    if (writer == null) { return }
    let result = renderer |> with_read_pixels() $(surface : SDL_Surface?) {
        let size = surface_size(surface) |> sdl_try
        if (size != dimensions) { return err(SdlError(operation = "recording", message = "framebuffer resized"), type<SdlUnit>) }
        var pixels : array<uint8>
        resize(pixels, size.x * size.y * 4)
        copy_surface_rgba8(surface, pixels, size.x * 4) |> sdl_try
        // Upstream writer expects bottom-up input and flips it to top-down.
        for (y in 0 .. size.y / 2) {
            for (x in 0 .. size.x * 4) {
                let a = y * size.x * 4 + x
                let b = (size.y - 1 - y) * size.x * 4 + x
                let value = pixels[a]
                pixels[a] = pixels[b]
                pixels[b] = value
            }
        }
        if (stbi_apng_frame(writer, unsafe(addr(pixels[0])), size.x * 4, int(1000.0 / float(rate) + 0.5)) == 0) {
            return err(SdlError(operation = "recording", message = "APNG encode failed"), type<SdlUnit>)
        }
        return sdl_ok()
    }
    if (is_err(result)) {
        failure = unwrap_err(result).message
        recording_shutdown()
        return
    }
    frames++
    if (frames >= cap) { recording_shutdown() }
}


// Upstream visual_aids imports the GLFW host. Use ImGui's backend-independent
// software cursor for SDL recordings instead; mouse trails are not implemented.
[live_command(description = "Draw the ImGui software cursor in SDL recordings")]
def imgui_cursor_sprite(input : JsonValue?) : JsonValue? {
    var io & = unsafe(GetIO())
    io.MouseDrawCursor = input?["enabled"] ?? false
    return JV((enabled = io.MouseDrawCursor))
}
