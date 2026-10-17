// Adapted from bgfx 33-pom; see the example README and group LICENSE-bgfx.txt.
options gen2
module pom_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4; eye, light : float4 }
struct Material { config : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 material : Material
var @in @location = 0 position : float3
var @in @location = 2 texcoord : float2
var @out @location = 0 v_uv : float2
var @out @location = 1 v_view : float3
var @out @location = 2 v_light : float3
var @in @location = 0 uv : float2
var @in @location = 1 view_dir : float3
var @in @location = 2 light_dir : float3
var @set = 2 @binding = 0 albedo : sampler2D
var @set = 2 @binding = 1 normals : sampler2D
var @set = 2 @binding = 2 heights : sampler2D
var @out @location = 0 color : float4
[vertex_shader(name="pom_vertex")]
def vertex_main {
    let p = transform.model * float4(position, 1.0)
    let t = (transform.model * float4(1.0, 0.0, 0.0, 0.0)).xyz; let b = (transform.model * float4(0.0, -1.0, 0.0, 0.0)).xyz; let n = (transform.model * float4(0.0, 0.0, -1.0, 0.0)).xyz
    let v = transform.eye.xyz - p.xyz; let l = transform.light.xyz - p.xyz
    v_view = float3(dot(v, t), dot(v, b), dot(v, n)); v_light = float3(dot(l, t), dot(l, b), dot(l, n))
    v_uv = texcoord; gl_Position = transform.vp * p
}
[fragment_shader(name="pom_fragment")]
def fragment_main {
    let mode = material.config.x; let scale = material.config.y; let steps = material.config.z
    let view = normalize(view_dir); var coord = uv
    // Base-level explicit sampling is defined inside divergent ray marching.
    // Shipped maps contain one mip; this does not depend on implicit derivatives.
    if (mode > 1.5) {
        let delta = view.xy * (scale / max(view.z, 0.05))
        if (mode < 2.5) { coord -= delta * textureLod(heights, coord, 0.0).x }
        else {
            let step = delta / steps; let layer = 1.0 / steps; var depth = 0.0; var sampled = textureLod(heights, coord, 0.0).x
            for (i in 0..32) { if (depth >= sampled) { break }; coord -= step; depth += layer; sampled = textureLod(heights, coord, 0.0).x }
            if (mode > 3.5) {
                let next = sampled - depth; let prev = textureLod(heights, coord + step, 0.0).x - depth + layer
                let weight = next / min(next - prev, -0.00001); coord = lerp(coord, coord + step, clamp(weight, 0.0, 1.0))
            }
        }
    }
    if (coord.x < 0.0 || coord.y < 0.0 || coord.x > 1.0 || coord.y > 1.0) { discard() }
    var n = float3(0.0, 0.0, 1.0)
    if (mode > 0.5) { let xy = textureLod(normals, coord, 0.0).xy * 2.0 - float2(1.0); n = float3(xy, sqrt(max(1.0 - dot(xy, xy), 0.0))) }
    let rgb = textureLod(albedo, coord, 0.0).xyz
    color = float4(rgb * (0.3 + max(dot(normalize(light_dir), n), 0.0)), 1.0)
}
