options gen2
require ../examples/gpu/hdr_app.das as demo
require bgfx_capture
require daslib/defer
require math

def half_value(bytes : array<uint8>; offset : int) {
    let bits = uint(bytes[offset]) | (uint(bytes[offset + 1]) << 8u)
    let exponent = int((bits >> 10u) & 31u); let mantissa = float(bits & 1023u)
    if (exponent == 31) { return -1.0 }
    let magnitude = exponent == 0 ? mantissa * pow(2.0, -24.0) : (1.0 + mantissa / 1024.0) * pow(2.0, float(exponent - 15))
    return (bits & 32768u) != 0u ? -magnitude : magnitude
}

def brightness(bytes : array<uint8>) {
    var sum = 0ul
    for (i in 0 .. length(bytes) / 4) { sum += uint64(bytes[i * 4]) + uint64(bytes[i * 4 + 1]) + uint64(bytes[i * 4 + 2]) }
    return sum
}

def check(device : SDL_GPUDevice?) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        var targets : HdrTargets
        defer() { release_targets(device, targets) }
        var reference = 0u; var reference_brightness = 0ul
        for (frame in 0 .. 5) {
            let width = frame == 4 ? 800u : 640u; let height = frame == 4 ? 600u : 480u
            resize_targets(device, targets, width, height) |> sdl_try
            if (length(targets.luminance) != 5 || targets.size != uint2(width, height)) { return err(SdlError(operation = "HDR resize", message = "Missing targets"), type<SdlUnit>) }
            var settings = HdrSettings()
            if (frame == 1) { settings.bloom = false }
            if (frame == 2) { settings.middle_gray = 0.36 }
            let time = frame == 3 ? 2.0 : 0.6
            sdl_scope() {
                var output : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(width, height,
                    SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(command, r, targets, output, time, settings) |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let bytes <- read_image(device, output, width, height, "hdr-{frame}") |> sdl_try
                let hash = image_hash(bytes); let sum = brightness(bytes)
                if (sum < uint64(width * height) * 30ul || sum > uint64(width * height) * 750ul) { return err(SdlError(operation = "HDR output", message = "Black or clipped frame"), type<SdlUnit>) }
                if (frame == 0) { reference = hash; reference_brightness = sum }
                if (frame == 1 && (hash == reference || sum >= reference_brightness)) { return err(SdlError(operation = "HDR bloom", message = "Disabling bloom did not reduce brightness"), type<SdlUnit>) }
                if (frame == 2 && sum <= reference_brightness) { return err(SdlError(operation = "HDR exposure", message = "Exposure did not increase brightness"), type<SdlUnit>) }
                if (frame == 3 && hash == reference) { return err(SdlError(operation = "HDR animation", message = "Image did not change"), type<SdlUnit>) }
                print("HDR: frame {frame}, hash={hash}, brightness={sum}.\n")
                return sdl_ok()
            } |> sdl_try
            if (frame == 0) {
                let scene <- read_image(device, targets.scene, width, height, "hdr-linear", 8u) |> sdl_try
                var hdr_pixels = 0
                for (i in 0 .. int(width * height)) {
                    for (channel in 0 .. 3) {
                        let value = half_value(scene, i * 8 + channel * 2)
                        if (value < 0.0) { return err(SdlError(operation = "HDR scene", message = "Negative/nonfinite linear radiance"), type<SdlUnit>) }
                        if (value > 1.0) { hdr_pixels++ }
                    }
                }
                if (hdr_pixels < 100) { return err(SdlError(operation = "HDR scene", message = "No radiance above 1"), type<SdlUnit>) }
                let lum <- read_image(device, targets.luminance[4], 1u, 1u, "hdr-luminance", 8u) |> sdl_try
                let luminance = half_value(lum, 0)
                if (luminance <= 0.001 || luminance > 1000.0) { return err(SdlError(operation = "HDR luminance", message = "Invalid reduction"), type<SdlUnit>) }
                print("HDR linear: {hdr_pixels} channels above 1, reduced luminance={luminance}.\n")
            }
        }
        return sdl_ok()
    }
}

[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS, true, "") |> sdl_use
        return check(device)
    }
    if (is_err(result)) { let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    return 0
}
