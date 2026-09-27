options gen2
module stencil_shaders shared public
// Scene shaders for bgfx 13-stencil / 14-shadowvolumes adaptations.
// Dario Manesku, BSD-2-Clause; see ../LICENSE-bgfx.txt.
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct SceneTransform {
    model, view_projection : float4x4
}
struct SceneLighting {
    color, light, shade : float4
}
var @uniform @set = 1 @binding = 0 transform : SceneTransform
var @uniform @set = 3 @binding = 0 lighting : SceneLighting
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_world : float3
var @out @location = 1 v_normal : float3
var @in @location = 0 f_world : float3
var @in @location = 1 f_normal : float3
var @out @location = 0 output_color : float4
[vertex_shader(name="stencil_vertex")]
def scene_vs {
    let world = transform.model * float4(position, 1.0)
    gl_Position = transform.view_projection * world
    v_world = world.xyz / world.w
    v_normal = (transform.model * float4(normal, 0.0)).xyz
}
[fragment_shader(name="stencil_fragment")]
def scene_fs {
    let diffuse = max(0.0, dot(normalize(f_normal), normalize(lighting.light.xyz - f_world)))
    output_color = float4(lighting.color.rgb * (lighting.shade.x + lighting.shade.y * diffuse), lighting.color.a)
}
