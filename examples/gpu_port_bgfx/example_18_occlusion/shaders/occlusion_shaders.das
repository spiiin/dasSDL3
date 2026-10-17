options gen2
// Adapted from bgfx 26-occlusion. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module occlusion_shaders shared public
require dassdl3/sdl3_shader_access
require math public
struct Camera { vp : float4x4; config : float4 }
var @uniform @set = 1 @binding = 0 camera : Camera
var @uniform @set = 2 @binding = 0 query : Camera
var @set = 0 @binding = 0 depths : sampler2D
var @ssbo @set = 1 @binding = 0 commands : array<uint>
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_color : float3
var @in @location = 0 rgb : float3
var @out @location = 0 color : float4
def center(id : uint) : float3 { return float3(float(id % 11u) - 5.0, float(id / 11u) - 5.0, 0.0) * 2.5 }
[vertex_shader(name="occlusion_vertex")]
def vertex_main {
    var p = position * 0.7 + center(uint(gl_InstanceIndex))
    var base = float3(0.2, 0.55, 0.9)
    if (camera.config.x > 0.5) { p = position * float3(6.0, 10.0, 0.7) + float3(0.0, 0.0, -6.0); base = float3(0.55, 0.3, 0.16) }
    gl_Position = camera.vp * float4(p, 1.0)
    v_color = base * (0.3 + 0.7 * max(dot(normal, normalize(float3(-0.4, 0.8, -0.6))), 0.0))
}
[fragment_shader(name="occlusion_fragment")]
def fragment_main { color = float4(rgb, 1.0) }
// SDL has no query/conditional-render API. Conservative full-resolution depth
// rectangle test produces indexed indirect commands entirely on the GPU.
[compute_shader(local_size_x=64, name="occlusion_query"), sdl_shader_access(name="occlusion_query")]
def cull {
    let id = gl_GlobalInvocationID.x
    if (id < 121u) {
        let c = center(id); var lo = float2(1.0); var hi = float2(-1.0); var nearest = 1.0; var safe = true
        for (i in 0..8) {
            let corner = c + float3((i & 1) != 0 ? 0.7 : -0.7, (i & 2) != 0 ? 0.7 : -0.7, (i & 4) != 0 ? 0.7 : -0.7)
            let clip = query.vp * float4(corner, 1.0)
            if (clip.w <= 0.0 || clip.z <= 0.0) { safe = false }
            else { let ndc = clip.xyz / clip.w; lo = min(lo, ndc.xy); hi = max(hi, ndc.xy); nearest = min(nearest, ndc.z) }
        }
        let size = query.config.xy
        let p0 = int2(floor(float2(lo.x * 0.5 + 0.5, 0.5 - hi.y * 0.5) * size)) - int2(1)
        let p1 = int2(ceil(float2(hi.x * 0.5 + 0.5, 0.5 - lo.y * 0.5) * size)) + int2(1)
        var visible = !safe || query.config.z > 0.5 || p0.x < 0 || p0.y < 0 || p1.x >= int(size.x) || p1.y >= int(size.y)
        if (!visible) {
            for (y in range(p0.y, p1.y + 1)) {
                for (x in range(p0.x, p1.x + 1)) {
                    let z = textureLod(depths, (float2(float(x), float(y)) + float2(0.5)) / size, 0.0).x
                    if (z + 0.00001 >= nearest) { visible = true; break }
                }
                if (visible) { break }
            }
        }
        commands[id * 5u] = 36u; commands[id * 5u + 1u] = visible ? 1u : 0u
        commands[id * 5u + 2u] = 0u; commands[id * 5u + 3u] = 0u; commands[id * 5u + 4u] = id
    }
}
