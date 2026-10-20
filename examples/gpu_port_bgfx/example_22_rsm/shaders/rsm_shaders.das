// Adapted from bgfx 31-rsm; see the example README and group LICENSE-bgfx.txt.
options gen2
module rsm_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4 }
struct Surface { tint, light : float4 }
struct Resolve { light_vp : float4x4; light, config : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 surface : Surface
var @uniform @set = 3 @binding = 0 resolve : Resolve
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_world : float3
var @out @location = 1 v_normal : float3
var @in @location = 0 world : float3
var @in @location = 1 nrm : float3
var @out @location = 0 out_position : float4
var @out @location = 1 out_normal : float4
var @out @location = 2 out_flux : float4
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
var @set = 2 @binding = 0 g_position : sampler2D
var @set = 2 @binding = 1 g_normal : sampler2D
var @set = 2 @binding = 2 g_albedo : sampler2D
var @set = 2 @binding = 3 r_position : sampler2D
var @set = 2 @binding = 4 r_normal : sampler2D
var @set = 2 @binding = 5 r_flux : sampler2D
var @set = 2 @binding = 6 shadow : sampler2D
[vertex_shader(name="rsm_vertex")]
def geometry_vs {
    let p = transform.model * float4(position, 1.0); gl_Position = transform.vp * p
    v_world = p.xyz; v_normal = normalize((transform.model * float4(normal, 0.0)).xyz)
}
[fragment_shader(name="rsm_gbuffer")]
def gbuffer_fs { out_position = float4(world, 1.0); out_normal = float4(normalize(nrm), 1.0); out_flux = surface.tint }
[fragment_shader(name="rsm_reflective")]
def reflective_fs {
    let n = normalize(nrm); let diffuse = max(dot(n, normalize(surface.light.xyz - world)), 0.0)
    out_position = float4(world, 1.0); out_normal = float4(n, 1.0); out_flux = float4(surface.tint.xyz * diffuse, 1.0)
}
[vertex_shader(name="rsm_screen")]
def screen_vs { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0); v_uv = t }
[fragment_shader(name="rsm_combine")]
def combine_fs {
    if (resolve.config.x > 1.5) { color = float4(texture(r_flux, uv).xyz, 1.0); return }
    let sample = texture(g_position, uv)
    if (sample.w < 0.5) { color = float4(0.02, 0.025, 0.04, 1.0); return }
    let p = sample.xyz; let n = normalize(texture(g_normal, uv).xyz); let albedo = texture(g_albedo, uv).xyz
    let q = resolve.light_vp * float4(p, 1.0); let coord = float2(q.x / q.w * 0.5 + 0.5, 0.5 - q.y / q.w * 0.5)
    var visibility = 0.0
    for (y in -1..2) { for (x in -1..2) {
        let d = textureLod(shadow, coord + float2(float(x), float(y)) / 256.0, 0.0).x
        visibility += q.z / q.w - 0.012 <= d ? 1.0 / 9.0 : 0.0
    } }
    let direct = max(dot(n, normalize(resolve.light.xyz - p)), 0.0) * visibility
    var indirect = float3(0.0)
    if (resolve.config.x < 0.5) {
        for (i in 0..64) {
            let tc = (float2(float(i % 8), float(i / 8)) + float2(0.5)) / 8.0
            let source = textureLod(r_position, tc, 0.0); let delta = source.xyz - p; let d2 = dot(delta, delta)
            if (source.w > 0.5 && d2 > 0.02 && d2 < resolve.config.z*resolve.config.z) {
                let dir = delta / sqrt(d2); let sender = textureLod(r_normal, tc, 0.0).xyz
                let weight = max(dot(n, dir), 0.0) * max(dot(sender, -dir), 0.0) / max(d2, 0.2)
                indirect += textureLod(r_flux, tc, 0.0).xyz * weight * (576.0 / 64.0 / 3.14159265)
            }
        }
    }
    let rgb = albedo * (resolve.config.x < 0.5 ? float3(direct)*(1.0-resolve.config.y)+indirect*resolve.config.y : float3(direct))
    color = float4(rgb, 1.0)
}
