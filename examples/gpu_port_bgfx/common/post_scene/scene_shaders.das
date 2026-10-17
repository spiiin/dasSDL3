// Scene shaders adapted from bgfx 43-denoise, 44-sss and 45-bokeh.
// Copyright 2021 elven cache. BSD-2-Clause; see group LICENSE-bgfx.txt.
options gen2
module scene_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Transform { model, vp, previous_vp : float4x4; eye, tint, light, screen : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 material : Transform
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 texcoord : float2
var @out @location = 0 v_world : float3
var @out @location = 1 v_normal : float3
var @out @location = 2 v_uv : float2
var @out @location = 3 v_previous : float4
var @in @location = 0 world : float3
var @in @location = 1 nrm : float3
var @in @location = 2 uv : float2
var @in @location = 3 previous : float4
var @out @location = 0 color : float4
var @out @location = 1 normal_out : float4
var @out @location = 2 velocity : float4
var @set = 2 @binding = 0 diffuse_image : sampler2D
var @set = 2 @binding = 1 normal_image : sampler2D
[vertex_shader(name="post_scene_vertex")]
def vertex {
    let p = transform.model * float4(position, 1.0)
    gl_Position = transform.vp * p
    v_world = p.xyz; v_normal = normalize((transform.model * float4(normal, 0.0)).xyz)
    v_uv = texcoord; v_previous = transform.screen.z > 0.5 ? float4(normalize(transform.eye.xyz - p.xyz), 0.0) : transform.previous_vp * p
}
def bumped(map : float3) : float3 {
    let n = normalize(nrm)
    let dp1 = dFdx(world); let dp2 = dFdy(world)
    let duv1 = dFdx(uv); let duv2 = dFdy(uv)
    let p2 = cross(dp2, n); let p1 = cross(n, dp1)
    let t = p2 * duv1.x + p1 * duv2.x
    let b = p2 * duv1.y + p1 * duv2.y
    let scale = 1.0 / sqrt(max(max(dot(t, t), dot(b, b)), 1e-15))
    return normalize(t * (scale * map.x) + b * (scale * map.y) + n * map.z)
}
[fragment_shader(name="post_scene_gbuffer")]
def gbuffer {
    let albedo = texture(diffuse_image, uv).xyz
    let xy = texture(normal_image, uv).yx * 2.0 - float2(1.0)
    let map = float3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))))
    let roughness = map.z * lerp(0.9, 1.0, pow(albedo.y, 2.2)) * 0.6 + 0.2
    color = material.tint.w > 1.5 ? float4(material.tint.xyz, 0.0) : float4(albedo, 1.0)
    normal_out = float4(bumped(map), roughness)
    let prev = previous.xy / previous.w * float2(0.5, -0.5) + float2(0.5)
    velocity = float4(gl_FragCoord.xy / material.screen.xy - prev, 0.0, 0.0)
}
[fragment_shader(name="post_scene_forward")]
def forward {
    let xy = -(texture(normal_image, uv).yx * 2.0 - float2(1.0))
    let map = float3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))))
    var n = bumped(map)
    var albedo = pow(texture(diffuse_image, uv).xyz, float3(2.2)) * material.tint.xyz
    if (material.tint.w > 0.5) {
        let cell = int2(abs(floor(world.xz - float2(0.002))))
        albedo = pow(material.tint.xyz, float3(2.2)) * (cell.x % 2 == cell.y % 2 ? 0.75 : 1.25)
        n = normalize(nrm)
    }
    let light = normalize(material.light.xyz - world)
    let view = previous.xyz
    let specular = 5.0 * pow(max(dot(n, normalize(view + light)), 0.0), 256.0)
    color = float4(albedo * (0.1 + max(dot(n, light), 0.0)) + float3(specular), 1.0)
}
