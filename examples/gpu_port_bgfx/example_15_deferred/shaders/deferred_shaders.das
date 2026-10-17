options gen2
module deferred_shaders shared public
// bgfx 21-deferred, Branimir Karadzic; BSD-2-Clause, ../LICENSE-bgfx.txt.
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4 }
struct Light { inverse_vp : float4x4; position_radius, color_inner, eye, controls : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 light : Light
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 texcoord : float2
var @out @location = 0 v_uv : float2
var @out @location = 1 v_normal : float3
var @out @location = 2 v_tangent : float3
var @in @location = 0 uv : float2
var @in @location = 1 nrm : float3
var @in @location = 2 tangent : float3
var @out @location = 0 color : float4
var @out @location = 1 encoded_normal : float4
var @set = 2 @binding = 0 source0 : sampler2D
var @set = 2 @binding = 1 source1 : sampler2D
[vertex_shader(name="deferred_vertex")]
def mesh_vs {
    gl_Position = transform.vp * transform.model * float4(position, 1.0)
    v_uv = texcoord; v_normal = (transform.model * float4(normal, 0.0)).xyz
    let t = abs(normal.y) > 0.5 ? float3(1.0, 0.0, 0.0) : normalize(cross(float3(0.0, 1.0, 0.0), normal))
    v_tangent = (transform.model * float4(t, 0.0)).xyz
}
[vertex_shader(name="deferred_fullscreen")]
def screen_vs {
    let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2))
    gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0); v_uv = t
}
[fragment_shader(name="deferred_geometry")]
def geometry_fs {
    let n = normalize(nrm); let t = normalize(tangent); let b = normalize(cross(n, t))
    let xy = texture(source1, uv).xy * 2.0 - float2(1.0)
    let bump = float3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))))
    let mapped = normalize(t * bump.x + b * bump.y + n * bump.z)
    color = texture(source0, uv)
    encoded_normal = float4(mapped * 0.5 + float3(0.5), 1.0)
}
[fragment_shader(name="deferred_light")]
def light_fs {
    let depth = textureLod(source1, uv, 0.0).r
    let p = light.inverse_vp * float4(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0, depth, 1.0)
    let world = p.xyz / p.w
    let n = normalize(textureLod(source0, uv, 0.0).xyz * 2.0 - float3(1.0))
    let delta = light.position_radius.xyz - world
    let distance = length(delta)
    let attenuation = 1.0 - smoothstep(light.color_inner.w, 1.0, distance / light.position_radius.w)
    let diffuse = max(dot(n, delta / max(distance, 0.0001)), 0.0)
    let rgb = light.color_inner.xyz * diffuse * attenuation
    color = float4(depth >= 1.0 ? float3(0.0) : pow(rgb, float3(1.0 / 2.2)), 0.0)
}
[fragment_shader(name="deferred_resolve")]
def resolve_fs {
    let albedo = textureLod(source0, uv, 0.0).rgb
    let illumination = textureLod(source1, uv, 0.0).rgb
    color = float4(albedo * (illumination), 1.0)
}
[fragment_shader(name="deferred_debug")]
def debug_fs { color = float4(textureLod(source0, uv, 0.0).rgb, 1.0) }
