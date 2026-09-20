options gen2
require dassdl3/sdl3_gpu_commands_boost
require daslib/rtti
require daslib/strings_boost

// Historical implementation, only for a repeatable comparison. Never import
// this benchmark into production wrappers; those contain no try/recover.
def old_plan_scope(device : SDL_GPUDevice?; blk : block<(plan : uint64) : void>) {
    let id = SDL_CreateGPUCommandPlan(device)
    if (id == 0ul) { panic("GPU plan create: {SDL_GetError()}") }
    var failed = false
    var error = ""
    try { SDL_InvokeGPUHandle(blk,id) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let released = SDL_ReleaseGPUCommandPlan(device,id)
    if (!released && failed) { panic("{error}; {SDL_GetError()}") }
    if (failed) { panic(error) }
    if (!released) { panic("GPU plan release: {SDL_GetError()}") }
}

[export]
def main(smoke : bool) : int {
    with_sdl() {
        with_gpu_device() $(device) {
            for (trial in 0 .. 4) {
                let old_start = SDL_GetTicks()
                for (i in 0 .. 2000000) { device |> old_plan_scope() $(plan) { } }
                let old_ms = int(SDL_GetTicks()-old_start)
                let new_start = SDL_GetTicks()
                for (i in 0 .. 2000000) { device |> with_gpu_command_plan() $(plan) { } }
                let new_ms = int(SDL_GetTicks()-new_start)
                print("trial {trial}: old={old_ms} ms, native cleanup={new_ms} ms / 2000000 scopes\n")
            }
        }
    }
    return 0
}
