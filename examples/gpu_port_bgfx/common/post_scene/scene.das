// Original scene layouts from bgfx 43/44/45. Application-local, not binding API.
options gen2
module scene shared public
require ../imgui_gpu.das public
require ./scene_shaders.das as shaders
require daslib/defer
struct Camera { eye : float3 = float3(0.0, 1.5, 0.0); yaw : float = 0.01; pitch : float = -0.3 }
struct Model { mesh : int; position : float3; scale : float }
struct Scene { meshes : array<GeometryBuffers>; models : array<Model>; pipeline : SDL_GPUGraphicsPipeline ?; diffuse, bump, color, normal, velocity, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2; previous_vp, view, projection, vp : float4x4; initialized : bool; kind : int }

def mwc(var z, w : uint&) : uint { z = 36969u * (z & 65535u) + (z >> 16u); w = 18000u * (w & 65535u) + (w >> 16u); return (z << 16u) + w }

def clear_targets(device : SDL_GPUDevice?; var scene : Scene) {
    for (resource in fixed_array(scene.color, scene.normal, scene.velocity, scene.depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }
    scene.color = null; scene.normal = null; scene.velocity = null; scene.depth = null; scene.initialized = false
}

def with_scene(device : SDL_GPUDevice?; kind : int; body : block<(var scene : Scene) : SdlStatus>) : SdlStatus {
    var scene = Scene(kind = kind)
    defer() {
        clear_targets(device, scene)
        for (resource in scene.meshes) { release(device, resource) }
        for (resource in fixed_array(scene.diffuse, scene.bump)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }
        if (scene.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, scene.pipeline) }
        if (scene.sampler != null) { SDL_ReleaseGPUSampler(device, scene.sampler) }
    }
    for (name in fixed_array("assao-cube", "assao-column", "assao-tree", "assao-hollowcube", "post-bunny", "post-unit_sphere")) {
        let mesh <- load_geometry("{SDL_GetBasePath()}assets/bgfx/{name}.msh") |> sdl_try
        var buffers = upload_geometry(device, mesh) |> sdl_try; push(scene.meshes, buffers)
    }
    var z = 12345u; var w = 65435u
    for (i in range(100)) {
        let choice = int(mwc(z, w) % uint(kind == 44 ? 5 : 4))
        let index = kind == 44 ? fixed_array(5, 1, 2, 3, 4)[choice] : choice + 1
        let pos = float3((float(mwc(z, w) % 256u) - 128.0) / 20.0, 0.0, (float(mwc(z, w) % 256u) - 128.0) / 20.0)
        push(scene.models, Model(mesh = index, position = pos, scale = fixed_array(1.0, 0.05, 0.15, 0.25, 0.25, 0.25)[index]))
    }
    var image = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; scene.diffuse = image
    upload_texture(device, scene.diffuse, "fieldstone-rgba.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    image = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; scene.bump = image
    upload_texture(device, scene.bump, "fieldstone-n.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    scene.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT))
    if (scene.sampler == null) { return err(sdl_error("post scene sampler"), type<SdlUnit>) }
    var formats <- array(SDL_GPUColorTargetDescription(format = SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT))
    if (kind != 45) { push(formats, SDL_GPUColorTargetDescription(format = SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)); push(formats, SDL_GPUColorTargetDescription(format = SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)) }
    var pipeline = pass_pipeline(device, shaders::post_scene_vertex, shaders::post_scene_vertex_reflect, kind == 45 ? shaders::post_scene_forward : shaders::post_scene_gbuffer, kind == 45 ? shaders::post_scene_forward_reflect : shaders::post_scene_gbuffer_reflect, formats) |> sdl_try
    scene.pipeline = pipeline
    return body(scene)
}

def draw_model(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; var scene : Scene; index : int; model : float4x4; camera : Camera; tint : float4; light : float3) : SdlStatus {
    let data = shaders::Transform(model = model, vp = scene.vp, previous_vp = scene.previous_vp, eye = float4(camera.eye, 1.0), tint = tint, light = float4(light, 1.0), screen = float4(float2(scene.size), scene.kind == 45 ? 1.0 : 0.0, 0.0))
    push_gpu_dsl_vertex_uniform(command, 0u, data) |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, data) |> sdl_try
    return draw_geometry(pass_, scene.meshes[index])
}

def draw_scene(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var scene : Scene; width, height : uint; camera : Camera; time : float; light : float3; jitter : float2 = float2(0.0)) : SdlStatus {
    if (scene.size != uint2(width, height)) {
        clear_targets(device, scene)
        let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
        var image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; scene.color = image
        image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; scene.normal = image
        image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; scene.velocity = image
        image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; scene.depth = image
        scene.size = uint2(width, height)
    }
    let forward = float3(cos(camera.pitch) * sin(camera.yaw), sin(camera.pitch), cos(camera.pitch) * cos(camera.yaw))
    scene.view = look_at_lh(camera.eye, camera.eye + forward, float3(0.0, 1.0, 0.0))
    scene.projection = perspective(float(width) / float(height), 1.7320508, 0.01, 100.0)
    scene.projection[2].x += jitter.x * 2.0 / float(width); scene.projection[2].y -= jitter.y * 2.0 / float(height)
    scene.vp = scene.projection * scene.view
    if (!scene.initialized) { scene.previous_vp = scene.vp }
    var targets <- array(attachment(scene.color, scene.kind == 45 ? float4(127.0 / 255.0, 184.0 / 255.0, 1.0, 1.0) : float4(0.0)))
    if (scene.kind != 45) { push(targets, attachment(scene.normal)); push(targets, attachment(scene.velocity)) }
    var depth = depth_attachment(scene.depth); depth.store_op = SDL_GPUStoreOp.STOREOP_STORE
    with_native_gpu_render_pass(command, targets, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, scene.pipeline)
        var images <- array(scene.diffuse, scene.bump); bind_images(pass_, images, scene.sampler) |> sdl_try
        if (scene.kind == 45) {
            for (z in range(20)) {
                let a = z < 10 ? float3(72.0, 126.0, 149.0) / 255.0 : float3(235.0, 146.0, 251.0) / 255.0
                let b = z < 10 ? float3(235.0, 146.0, 251.0) / 255.0 : float3(199.0, 0.0, 57.0) / 255.0
                let tint = lerp(a, b, float(z % 10) / 10.0)
                for (x in range(6)) { let angle = time + float(z) * 6.2831853 / 20.0 + float(x) * 1.5707963 / 6.0
                    draw_model(command, pass_, scene, 3, model_matrix(float3(float(x) * 2.0 - 5.0, sin(angle), float(z) * 2.0 - 19.0), float3(0.3)), camera, float4(tint, 0.0), light) |> sdl_try
                }
            }
            draw_model(command, pass_, scene, 0, model_matrix(float3(0.0, -22.0, 0.0), float3(20.0)), camera, float4(0.5, 0.5, 0.5, 1.0), light) |> sdl_try
        } else {
            for (model in scene.models) { draw_model(command, pass_, scene, model.mesh, model_matrix(model.position, float3(model.scale)), camera, float4(1.0), light) |> sdl_try }
            draw_model(command, pass_, scene, 0, model_matrix(float3(0.0, -10.0, 0.0), float3(10.0)), camera, float4(1.0), light) |> sdl_try
            if (scene.kind == 44) { draw_model(command, pass_, scene, 5, model_matrix(light, float3(0.25)), camera, float4(1.0, 1.0, 1.0, 2.0), light) |> sdl_try }
        }
        return sdl_ok()
    } |> sdl_try
    scene.previous_vp = scene.vp; scene.initialized = true
    return sdl_ok()
}

def camera_event(event : SdlEvent; var camera : Camera) {
    if (event is key_down) { let key = (event as key_down).keycode
        let f = float3(sin(camera.yaw), 0.0, cos(camera.yaw)) * 0.2; let r = float3(f.z, 0.0, -f.x)
        if (key == SDLK_W) { camera.eye += f } elif (key == SDLK_S) { camera.eye -= f } elif (key == SDLK_A) { camera.eye -= r } elif (key == SDLK_D) { camera.eye += r }
        elif (key == SDLK_LEFT) { camera.yaw -= 0.05 } elif (key == SDLK_RIGHT) { camera.yaw += 0.05 } elif (key == SDLK_UP) { camera.pitch = min(1.4, camera.pitch + 0.05) } elif (key == SDLK_DOWN) { camera.pitch = max(-1.4, camera.pitch - 0.05) }
    }
}
