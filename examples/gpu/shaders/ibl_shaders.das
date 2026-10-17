options gen2
module ibl_shaders shared public
// bgfx 18-ibl, Dario Manesku. BSD-2-Clause, ../LICENSE-bgfx.txt.
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4 }
struct Material { eye, albedo, specular, parameters, light, light_color, toggles : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 material : Material
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_world : float3
var @out @location = 1 v_normal : float3
var @in @location = 0 world : float3
var @in @location = 1 nrm : float3
var @out @location = 2 v_uv : float2
var @in @location = 2 uv : float2
var @out @location = 0 color : float4
var @set = 2 @binding = 0 radiance : samplerCube
var @set = 2 @binding = 1 irradiance : samplerCube
[vertex_shader(name="ibl_vertex")]
def mesh_vs {
    let p = transform.model * float4(position, 1.0)
    gl_Position = transform.vp * p
    v_world = p.xyz; v_normal = (transform.model * float4(normal, 0.0)).xyz
}
[vertex_shader(name="ibl_fullscreen")]
def screen_vs {
    let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2))
    gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0); v_uv = t
}
def filmic(c : float3) : float3 {
    let x = max(float3(0.0), c - float3(0.004))
    return (x * (6.2 * x + float3(0.5))) / (x * (6.2 * x + float3(1.7)) + float3(0.06))
}
def rotate_environment(d : float3) : float3 {
    let s = sin(material.parameters.w); let c = cos(material.parameters.w)
    return float3(c * d.x - s * d.z, d.y, s * d.x + c * d.z)
}
[fragment_shader(name="ibl_fragment")]
def mesh_fs {
    let n = normalize(nrm); let v = normalize(material.eye.xyz - world); let l = normalize(material.light.xyz); let h = normalize(v + l)
    let nv = clamp(dot(n, v), 0.0, 1.0); let nl = max(dot(n, l), 0.0); let nh = max(dot(n, h), 0.0); let hv = max(dot(h, v), 0.0)
    let gloss = material.parameters.x; let reflectivity = material.parameters.y
    let refl = material.specular.w > 0.5 ? material.specular.xyz * reflectivity : (float3(0.04) * (1.0 - reflectivity) + material.albedo.xyz * reflectivity)
    let albedo = material.albedo.xyz * (1.0 - reflectivity)
    let direct_fresnel = refl + (float3(1.0) - refl) * pow(1.0 - hv, 5.0) * gloss
    let env_fresnel = refl + (float3(1.0) - refl) * pow(1.0 - nv, 5.0) * gloss
    let power = exp2(10.0 * gloss + 2.0)
    let direct = (material.toggles.x * albedo * (float3(1.0) - direct_fresnel) * nl + material.toggles.y * direct_fresnel * pow(nh, power) * nl * (power + 8.0) * 0.125) * material.light_color.xyz
    let mip = 1.0 + 5.0 * (1.0 - gloss)
    var r = rotate_environment(2.0 * nv * n - v)
    // cmft warp correction for the original prefiltered cubemap.
    let a = abs(r); let major = max(max(a.x, a.y), a.z); let scale = 1.0 - exp2(mip) / 256.0
    if (a.x < major) { r.x *= scale }; if (a.y < major) { r.y *= scale }; if (a.z < major) { r.z *= scale }
    let env = pow(max(textureLod(radiance, r, mip).rgb, float3(0.0)), float3(2.2))
    let irr = pow(max(textureLod(irradiance, rotate_environment(n), 0.0).rgb, float3(0.0)), float3(2.2))
    let indirect = material.toggles.z * albedo * irr + material.toggles.w * env_fresnel * env
    color = float4(filmic((direct + indirect) * exp2(material.parameters.z)), 1.0)
}
[fragment_shader(name="ibl_sky")]
def sky_fs {
    let d = rotate_environment(normalize(float3((uv.x * 2.0 - 1.0) * material.eye.w, 1.0 - uv.y * 2.0, 1.7320508)))
    let c = pow(max(textureLod(radiance, d, 0.0).rgb, float3(0.0)), float3(2.2))
    color = float4(filmic(c * exp2(material.parameters.z)), 1.0)
}
