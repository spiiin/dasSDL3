options gen2
options rtti
module loopback_http
require dashv/dashv_boost
require daslib/json_boost
require daslib/defer
require daslib/debugger
require daslib/clargs
require live_host
require strings

// Example transport: upstream live command bridge with an explicit loopback bind.
// The upstream live_api agent is intentionally not imported (it starts another server).
def private encode(var value : JsonValue?) : string {
    let result = write_json(value)
    delete_json(value)
    return result
}

def private guard(var resp : HttpResponse?) : http_status {
    if (empty(get_last_error())) { return http_status.OK }
    return resp |> JSON(encode(JV((error = get_last_error()))), http_status.SERVICE_UNAVAILABLE)
}

class private LoopbackServer : HvWebServer {
    def override onInit() {
        GET("/status") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            return resp |> JSON(encode(JV((fps = get_fps(), uptime = get_uptime(), paused = is_paused(),
                dt = get_dt(), has_error = !empty(get_last_error()), generation = get_reload_generation()))), http_status.OK)
        }
        GET("/error") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            return resp |> JSON(encode(empty(get_last_error()) ? JVNull() : JV(get_last_error())), http_status.OK)
        }
        POST("/command") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            let status = guard(resp)
            if (status != http_status.OK) { return status }
            if (empty(string(req.body))) { return resp |> JSON("null", http_status.BAD_REQUEST) }
            return resp |> JSON(dispatch_command(string(req.body)), http_status.OK)
        }
        POST("/commands") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            let status = guard(resp)
            if (status != http_status.OK) { return status }
            var error : string
            var input = read_json(string(req.body), error)
            if (input == null) { return resp |> JSON("null", http_status.BAD_REQUEST) }
            {
                defer() { delete_json(input) }
                if (!(input.value is _array)) { return resp |> JSON("null", http_status.BAD_REQUEST) }
                let items & = unsafe(input.value as _array)
                let result = build_string() $(var writer) {
                    write(writer, "[")
                    var first = true
                    for (item in items) {
                        if (!first) { write(writer, ",") }
                        first = false
                        let entry = unsafe(reinterpret<JsonValue?>(item))
                        if (entry == null || !(entry.value is _object) || empty(entry?.name ?? "")) {
                            write(writer, "\{\"error\":\"invalid command object\"}")
                        } else {
                            write(writer, dispatch_command(write_json(entry)))
                        }
                    }
                    write(writer, "]")
                }
                return resp |> JSON(result, http_status.OK)
            }
        }
        POST("/reload") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            request_reload(false)
            return resp |> JSON("true", http_status.OK)
        }
        POST("/reload/full") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            request_reload(true)
            return resp |> JSON("true", http_status.OK)
        }
        POST("/pause") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            let status = guard(resp)
            if (status != http_status.OK) { return status }
            set_paused(true)
            return resp |> JSON("true", http_status.OK)
        }
        POST("/unpause") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            let status = guard(resp)
            if (status != http_status.OK) { return status }
            set_paused(false)
            return resp |> JSON("true", http_status.OK)
        }
        POST("/shutdown") @(var req : HttpRequest?; var resp : HttpResponse?) : http_status {
            request_exit()
            return resp |> JSON("true", http_status.OK)
        }
    }
}

class private LoopbackAgent : DapiDebugAgent {
    server : LoopbackServer?
    def LoopbackAgent() {
        let args <- get_command_line_arguments()
        let port = to_int(find_flag_raw_value(args, "--live-port") |> unwrap_or("9090"))
        if (port < 1 || port > 65535) { panic("Invalid live port") }
        server = new LoopbackServer()
        server->init(port)
        if (!server->set_bind_host("127.0.0.1") || server->start() != 0) { panic("Cannot start loopback live server") }
    }
    def close() {
        if (server != null) {
            server->stop()
            server->cleanup()
            unsafe { delete server }
            server = null
        }
    }
    def operator delete() { close() }
    def override onUninstall(agent : DebugAgent?) { close() }
    def override onTick() {
        if (server != null) { server->tick() }
    }
}

def private install_agent(ctx : Context) {
    install_new_debug_agent(new LoopbackAgent(), "sdl_loopback_http")
}

[_macro]
def installing() {
    if (is_compiling_macros_in_module("loopback_http") && !is_in_completion()) {
        if (!is_in_debug_agent_creation() && is_live_mode() && !has_debug_agent_context("sdl_loopback_http")) {
            fork_debug_agent_context(@@install_agent)
        }
    }
}
