options gen2
require imgui/imgui_playwright
require daslib/clargs

[export]
def main {
    let args <- get_command_line_arguments()
    let output = find_flag_raw_value(args, "--output-root") |> unwrap_or(".")
    var probe = ImguiApp(base_url = "http://127.0.0.1:9090", transport <- live_api_transport("http://127.0.0.1:9090"))
    verify(wait_until_ready(probe, 3.0)) // Attach only; never spawn the GLFW host.
    let status = post_command(probe, "record_status", null)
    verify(status != null && status?["frames"] != null && !(status?["active"] ?? true))
    let no_modules : array<string>
    with_recording_app("03_widgets_recording.das", "sdl-widgets.apng", 20, 20, no_modules, ".", output) $(app) {
        var snap = wait_for_render(app, "MAIN/SPEED", 10.0)
        let before = widget_payload_field(snap, "MAIN/SPEED", "value") ?? -1.0
        let before_json = write_json(widget_payload_field(snap, "MAIN/SPEED", "value"))
        let clicks = widget_payload_field(snap, "MAIN/INCREMENT", "click_count") ?? -1
        hold_content(app, 500u)
        let bounds = snap?["globals"]?["MAIN/SPEED"]?["bbox"]
        let width = (bounds?["z"] ?? 0.0) - (bounds?["x"] ?? 0.0)
        drag(app, "MAIN/SPEED", width * (before < 0.5 ? 0.2 : -0.2), 0.0, 12)
        record_check(app, "drag completed", wait_for_mouse_idle(app, 10.0))
        record_check_changed(app, "MAIN/SPEED", "value", before_json)
        click(app, "MAIN/INCREMENT")
        record_check_value(app, "MAIN/INCREMENT", "click_count", clicks + 1)
        hold_content(app, 500u)
    }
    print("SDL upstream recording PASS\n")
}
