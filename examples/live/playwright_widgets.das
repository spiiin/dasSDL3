options gen2
require imgui/imgui_playwright
require daslib/clargs
require math

// Uses upstream drag/click/reload against an already running SDL HTTP example.
// The drag is a synthetic mouse timeline, not force_set.
[export]
def main {
    let args <- get_command_line_arguments()
    let port = find_flag_raw_value(args, "--live-port") |> unwrap_or("9091")
    let url = "http://127.0.0.1:{port}"
    var app = ImguiApp(base_url = url, transport <- live_api_transport(url))
    verify(wait_until_ready(app, 10.0))
    var snap = wait_for_render(app, "MAIN/SPEED", 10.0)
    verify(snap != null)
    let before = widget_payload_field(snap, "MAIN/SPEED", "value") ?? -1.0
    let clicks = widget_payload_field(snap, "MAIN/INCREMENT", "click_count") ?? -1
    verify(before >= 0.0 && clicks >= 0)
    post_command(app, "set_user_control", JV((enabled = false)))
    // Upstream drag starts at bbox center, not the current slider handle.
    // Alternate destination according to the current value so reruns still move it.
    let bounds = snap?["globals"]?["MAIN/SPEED"]?["bbox"]
    let width = (bounds?["z"] ?? 0.0) - (bounds?["x"] ?? 0.0)
    verify(width > 0.0)
    let dx = width * (before < 0.5 ? 0.2 : -0.2)
    let dragged = drag(app, "MAIN/SPEED", dx, 0.0, 12)
    verify(dragged?["ok"] ?? false)
    verify(wait_for_mouse_idle(app, 10.0))
    var changed = snapshot(app)
    let after = widget_payload_field(changed, "MAIN/SPEED", "value") ?? -1.0
    verify(after >= 0.0 && abs(after - before) > 0.05)
    click(app, "MAIN/INCREMENT")
    verify(wait_for_int_value(app, "MAIN/INCREMENT", "click_count", clicks + 1))
    reload(app)
    var restored = wait_for_render(app, "MAIN/SPEED", 10.0)
    verify(restored != null)
    verify(abs((widget_payload_field(restored, "MAIN/SPEED", "value") ?? -1.0) - after) < 0.0001)
    verify(wait_for_int_value(app, "MAIN/INCREMENT", "click_count", clicks + 1))
    post_command(app, "set_user_control", JV((enabled = true)))
    print("SDL upstream playwright: mouse drag {before} -> {after}, click, reload/state PASS\n")
}
