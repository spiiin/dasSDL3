options gen2
// Adapted from bgfx 28-wireframe. Copyright 2016 Dario Manesku.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module wireframe_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4 }
struct Style { params : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 style : Style
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 barycentric : float2
var @out @location = 0 v_normal : float3
var @out @location = 1 v_bc : float3
var @in @location = 0 nrm : float3
var @in @location = 1 bc : float3
var @out @location = 0 color : float4
[vertex_shader(name="wireframe_vertex")]
def vertex_main {
    gl_Position = transform.vp * transform.model * float4(position, 1.0)
    v_normal = (transform.model * float4(normal, 0.0)).xyz
    v_bc = float3(barycentric, 1.0 - barycentric.x - barycentric.y)
}
[fragment_shader(name="wireframe_fragment")]
def fragment_main {
    let fw = abs(dFdx(bc)) + abs(dFdy(bc))
    let val = smoothstep(float3(0.0), fw * style.params.x, bc)
    let edge = min(val.x, min(val.y, val.z))
    let light = 0.2 + 0.8 * max(dot(normalize(nrm), normalize(float3(-0.5, 0.8, -0.6))), 0.0)
    let surface = float3(0.32, 0.55, 0.8) * light
    if (style.params.y > 1.5 && edge > 0.98) { discard() }
    color = float4(style.params.y < 0.5 ? surface : lerp(float3(0.95, 0.8, 0.25), surface, edge), 1.0)
}
