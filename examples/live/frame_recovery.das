options gen2
module frame_recovery
require imgui
require daslib/defer

// Application-only teardown for a script fault after NewFrame and before Render.
// ImGui recovery is best-effort; it is not recovery from a native crash.
def public discard_interrupted_frame() {
    var io & = unsafe(GetIO())
    let recovery = io.ConfigErrorRecovery
    let assertions = io.ConfigErrorRecoveryEnableAssert
    let debug_log = io.ConfigErrorRecoveryEnableDebugLog
    let tooltip = io.ConfigErrorRecoveryEnableTooltip
    defer() {
        io.ConfigErrorRecovery = recovery
        io.ConfigErrorRecoveryEnableAssert = assertions
        io.ConfigErrorRecoveryEnableDebugLog = debug_log
        io.ConfigErrorRecoveryEnableTooltip = tooltip
    }
    io.ConfigErrorRecovery = true
    io.ConfigErrorRecoveryEnableAssert = false
    io.ConfigErrorRecoveryEnableDebugLog = true
    io.ConfigErrorRecoveryEnableTooltip = false
    EndFrame()
    print("SDL live interrupted frame discarded\n")
}
