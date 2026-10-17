// Port of bgfx 42-bunnylod shaders. See ../README.md and group license.
options gen2
module bunnylod_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Transform { model, vp : float4x4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 world : float3
var @out @location = 1 tint : float3
var @in @location = 0 point : float3
var @in @location = 1 albedo : float3
var @out @location = 0 color : float4
[vertex_shader(name="bunnylod_vertex")]
def vertex {
    let p = transform.model * float4(position, 1.0)
    gl_Position = transform.vp * p
    world = p.xyz
    tint = normal
}
[fragment_shader(name="bunnylod_fragment")]
def fragment {
    // SDL uses a downward framebuffer Y; reverse the bgfx derivative cross order.
    let n = normalize(cross(dFdy(point), dFdx(point)))
    let diffuse = max(dot(n, float3(0.0, 0.0, 1.0)), 0.0)
    // bgfx's packed normalized normal attribute is decoded as color in this shader.
    color = float4(pow(pow(max(albedo, float3(0.0)), float3(2.2)) * diffuse + float3(pow(diffuse, 30.0)), float3(1.0 / 2.2)), 1.0)
}
