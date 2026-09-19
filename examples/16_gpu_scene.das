options gen2
require dassdl3/sdl3_gpu_scene_boost

struct SceneDemo {
    yaw : float = 0.54
    pitch : float = 0.33
    distance : float = 6.0
    angle : float = 0.0
    paused : bool = false
    reverse_order : bool = false
}

def scene_key(var state : SceneDemo; key : SDL_KeyboardEvent) : bool {
    if (!key.down || key.repeat) { return false }
    if (key.key == 32u) { // SDLK_SPACE: SDL keycodes for printable keys use ASCII.
        state.paused = !state.paused
    } elif (key.key == SDLK_RETURN) {
        state.reverse_order = !state.reverse_order
    } elif (key.key == SDLK_BACKSPACE) {
        state = SceneDemo()
    } else { return false }
    return true
}

def scene_step(var state : SceneDemo; dt : float; orbit : float2; zoom : float) {
    let elapsed = clamp(dt,0.0,0.1) // Do not jump after a suspended or dragged window.
    if (!state.paused) {
        state.angle += elapsed * 0.8
        if (state.angle > 6.2831853) { state.angle -= 6.2831853 }
    }
    state.yaw += orbit.x * elapsed * 1.4
    if (state.yaw > 3.14159265) { state.yaw -= 6.2831853 }
    if (state.yaw < -3.14159265) { state.yaw += 6.2831853 }
    state.pitch = clamp(state.pitch + orbit.y * elapsed, -0.9, 1.2)
    state.distance = clamp(state.distance - zoom * 0.5, 3.0, 12.0)
}

[export]
def main(smoke : bool) : int {
    var available = false
    var frames = 0
    with_sdl() {
        available = try_with_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let shaders = "{SDL_GetBasePath()}assets/shaders/lit"
            // Split vertices preserve sharp normals and UV seams at cube edges.
            var positions <- array<float4>(
                float4(1.0,-1.0,-1.0,1.0),float4(1.0,1.0,-1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(1.0,-1.0,1.0,1.0),
                float4(-1.0,-1.0,1.0,1.0),float4(-1.0,1.0,1.0,1.0),float4(-1.0,1.0,-1.0,1.0),float4(-1.0,-1.0,-1.0,1.0),
                float4(-1.0,1.0,-1.0,1.0),float4(-1.0,1.0,1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(1.0,1.0,-1.0,1.0),
                float4(-1.0,-1.0,1.0,1.0),float4(-1.0,-1.0,-1.0,1.0),float4(1.0,-1.0,-1.0,1.0),float4(1.0,-1.0,1.0,1.0),
                float4(-1.0,-1.0,1.0,1.0),float4(1.0,-1.0,1.0,1.0),float4(1.0,1.0,1.0,1.0),float4(-1.0,1.0,1.0,1.0),
                float4(1.0,-1.0,-1.0,1.0),float4(-1.0,-1.0,-1.0,1.0),float4(-1.0,1.0,-1.0,1.0),float4(1.0,1.0,-1.0,1.0))
            var normals <- array<float4>(
                float4(1.0,0.0,0.0,0.0),float4(1.0,0.0,0.0,0.0),float4(1.0,0.0,0.0,0.0),float4(1.0,0.0,0.0,0.0),
                float4(-1.0,0.0,0.0,0.0),float4(-1.0,0.0,0.0,0.0),float4(-1.0,0.0,0.0,0.0),float4(-1.0,0.0,0.0,0.0),
                float4(0.0,1.0,0.0,0.0),float4(0.0,1.0,0.0,0.0),float4(0.0,1.0,0.0,0.0),float4(0.0,1.0,0.0,0.0),
                float4(0.0,-1.0,0.0,0.0),float4(0.0,-1.0,0.0,0.0),float4(0.0,-1.0,0.0,0.0),float4(0.0,-1.0,0.0,0.0),
                float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),float4(0.0,0.0,1.0,0.0),
                float4(0.0,0.0,-1.0,0.0),float4(0.0,0.0,-1.0,0.0),float4(0.0,0.0,-1.0,0.0),float4(0.0,0.0,-1.0,0.0))
            var uv <- array<float2>(
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0),
                float2(0.0,1.0),float2(1.0,1.0),float2(1.0,0.0),float2(0.0,0.0))
            var indices <- array<uint>(
                0u,1u,2u,0u,2u,3u,
                4u,5u,6u,4u,6u,7u,
                8u,9u,10u,8u,10u,11u,
                12u,13u,14u,12u,14u,15u,
                16u,17u,18u,16u,18u,19u,
                20u,21u,22u,20u,22u,23u)
            var pixels : array<uint8>
            for (y in 0 .. 8) {
                for (x in 0 .. 8) {
                    let bright = ((x / 2 + y / 2) % 2) == 0
                    push(pixels,uint8(bright ? 240 : 40))
                    push(pixels,uint8(bright ? 180 : 80))
                    push(pixels,uint8(bright ? 70 : 180))
                    push(pixels,uint8(255))
                }
            }
            print("Arrows: orbit camera; wheel: zoom; Space: pause; Enter: reverse draw order; Backspace: reset; Esc: exit.\n")
            print("Pause, then reverse draw order: shared depth keeps the same visible surfaces.\n")
            with_window("SDL GPU scene",800,600,SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    device |> with_gpu_lit_mesh(window,positions,normals,uv,indices,pixels,8u,8u,"{shaders}.vert.{extension}","{shaders}.frag.{extension}",format) $(mesh) {
                        device |> with_gpu_lit_scene(window) $(scene) {
                            clear(positions)
                            clear(normals)
                            clear(uv)
                            clear(pixels)
                            clear(indices)
                            var draws : GpuLitDrawList
                            var event = SDL_MakeEvent()
                            var key : SDL_KeyboardEvent
                            var wheel : SDL_MouseWheelEvent
                            var state = SceneDemo()
                            var running = true
                            var attempts = 0
                            var previous = SDL_GetTicks()
                            var title_time = previous
                            var title_dirty = true
                            while (running) {
                                var zoom = 0.0
                                while (poll_event(event)) {
                                    if (should_close(event,window)) { running = false }
                                    if (input_window_id(event) != SDL_GetWindowID(window)) { continue }
                                    if (!smoke && key_event(event,key)) {
                                        if (scene_key(state,key)) { title_dirty = true }
                                    }
                                    if (!smoke && mouse_wheel_event(event,wheel)) { zoom += wheel_delta(wheel).y }
                                }
                                if (!running) { break }
                                let now = SDL_GetTicks()
                                let dt = smoke ? (1.0 / 60.0) : min(float(now-previous)/1000.0,0.1)
                                previous = now
                                var orbit = float2(0.0)
                                if (!smoke) {
                                    if (key_down(SDL_SCANCODE_LEFT)) { orbit.x -= 1.0 }
                                    if (key_down(SDL_SCANCODE_RIGHT)) { orbit.x += 1.0 }
                                    if (key_down(SDL_SCANCODE_UP)) { orbit.y += 1.0 }
                                    if (key_down(SDL_SCANCODE_DOWN)) { orbit.y -= 1.0 }
                                } elif (attempts < 10) {
                                    orbit = float2(0.6,0.3)
                                    zoom = 0.1
                                }
                                // Deterministic smoke exercises the same key handler without depending on physical input.
                                if (smoke && (attempts == 10 || attempts == 20 || attempts == 30 || attempts == 40)) {
                                    var action : SDL_KeyboardEvent
                                    action.down = true
                                    if (attempts == 10 || attempts == 20) {
                                        action.key = 32u
                                    } else { action.key = attempts == 30 ? SDLK_RETURN : SDLK_BACKSPACE }
                                    verify(scene_key(state,action))
                                    if (attempts == 10) { verify(state.paused) }
                                    if (attempts == 20) { verify(!state.paused) }
                                    if (attempts == 30) { verify(state.reverse_order) }
                                    if (attempts == 40) { verify(!state.reverse_order && state.angle == 0.0) }
                                    title_dirty = true
                                }
                                let old_angle = state.angle
                                scene_step(state,dt,orbit,zoom)
                                if (smoke && state.paused) { verify(state.angle == old_angle) }
                                if (title_dirty || now-title_time >= 250ul) {
                                    let motion = state.paused ? "paused" : "playing"
                                    let order = state.reverse_order ? "reverse" : "forward"
                                    window |> set_title("Scene | {motion} | draw order: {order} | arrows/wheel: camera | Space: pause | Enter: order | Backspace: reset | Esc")
                                    title_dirty = false
                                    title_time = now
                                }
                                let angle = state.angle
                                var model : float4x4
                                identity(model)
                                model[0] = float4(cos(angle)*1.2,0.0,-sin(angle)*1.2,0.0)
                                model[2] = float4(sin(angle),0.0,cos(angle),0.0)
                                let target = float3(0.0,0.0,0.4)
                                let eye = target + float3(sin(state.yaw)*cos(state.pitch),sin(state.pitch),cos(state.yaw)*cos(state.pitch))*state.distance
                                let camera = gpu_camera(eye,target,float3(0.0,1.0,0.0),1.0,gpu_window_aspect(window),0.1,100.0)
                                draws |> gpu_scene_clear()
                                for (order_index in 0 .. 3) {
                                    let i = state.reverse_order ? 2-order_index : order_index
                                    var object_model = model
                                    object_model[0] *= 0.65
                                    object_model[1] *= 0.65
                                    object_model[2] *= 0.65
                                    object_model[3] = float4((float(i)-1.0)*1.2,0.0,float(i)*0.4,1.0)
                                    draws |> gpu_scene_add(mesh,object_model,float3(0.4,0.8,1.0),0.2)
                                }
                                if (device |> gpu_draw_lit_scene(window,scene,draws,camera)) { frames++ }
                                if (smoke && frames == 60) { break }
                                attempts++
                                if (smoke && attempts >= 300) { panic("GPU scene: no drawable") }
                                SDL_Delay(16u)
                            }
                        }
                    }
                }
            }
            print("GPU scene: {SDL_GetGPUDeviceDriver(device)}, {frames} frames; depth/resources released.\n")
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU scene smoke interrupted") }
    return 0
}
