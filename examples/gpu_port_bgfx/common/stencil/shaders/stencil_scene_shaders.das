options gen2
module stencil_scene_shaders shared public
// bgfx 13-stencil, Dario Manesku (BSD-2-Clause). Application-local lighting.
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, view_projection : float4x4 }
struct Lighting {
    color, eye, controls, material : float4
    // Each scene supplies its bgfx material coefficients and fog constants.
    coefficients : float4
    fog : float4
    positions : float4[5]
    colors : float4[5]
}
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 lighting : Lighting
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 uv : float2
var @out @location = 0 v_world : float3
var @out @location = 1 v_normal : float3
var @out @location = 2 v_uv : float2
var @in @location = 0 f_world : float3
var @in @location = 1 f_normal : float3
var @in @location = 2 f_uv : float2
var @set = 2 @binding = 0 albedo : sampler2D
var @out @location = 0 output_color : float4
[vertex_shader(name="stencil_scene_vertex")]
def scene_vs {
    let world = transform.model * float4(position, 1.0)
    gl_Position = transform.view_projection * world
    v_world = world.xyz / world.w
    v_normal = (transform.model * float4(normal, 0.0)).xyz
    v_uv = uv
}
[fragment_shader(name="stencil_scene_fragment")]
def scene_fs {
    let texel = texture(albedo, f_uv)
    let base = lighting.material.x > 0.5 ? texel.rgb : lighting.color.rgb
    if (lighting.material.y > 1.5) {
        output_color = float4(0.0, 0.0, 0.0, 1.0)
    } elif (lighting.material.y > 0.5) {
        output_color = float4(texel.rgb * lighting.color.rgb, 1.0)
    } else {
        let linear = pow(base, float3(2.2))
        let n = normalize(f_normal)
        let v = normalize(lighting.eye.xyz - f_world)
        var sum = float3(0.0)
        for (i in 0 .. 5) {
            if (float(i) >= lighting.controls.z && float(i) < lighting.controls.z + lighting.controls.w) {
                let to_light = lighting.positions[i].xyz - f_world
                let l = normalize(to_light)
                let nl = dot(n, l)
                let spec = nl > 0.0 ? pow(max(0.0, dot(2.0 * nl * n - l, v)), lighting.coefficients.z) : 0.0
                let distance = max(length(to_light), lighting.positions[i].w)
                sum += (max(0.0, nl) * lighting.coefficients.y + spec * lighting.material.z) * lighting.colors[i].rgb * (lighting.coefficients.w / (distance * distance))
            }
        }
        let ambient = pow(linear * lighting.coefficients.x, float3(1.0 / 2.2)) * lighting.controls.x
        let diffuse = pow(max(sum * linear, float3(0.0)), float3(1.0 / 2.2)) * lighting.controls.y
        let distance_to_eye = length(lighting.eye.xyz - f_world)
        let fog_factor = exp(-lighting.fog.w * lighting.fog.w * distance_to_eye * distance_to_eye)
        output_color = float4(clamp((ambient + diffuse) * fog_factor + lighting.fog.xyz * (1.0 - fog_factor), float3(0.0), float3(1.0)), lighting.color.a)
    }
}
