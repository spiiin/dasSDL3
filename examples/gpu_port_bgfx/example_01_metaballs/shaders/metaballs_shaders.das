options gen2
module metaballs_shaders shared public
// Adapted from bgfx; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
require math
require spirv/spirv_shader
require spirv/spirv_builtins public

struct Transform { rotation : float4; projection : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 color : float3
var @out @location = 0 v_normal : float3
var @out @location = 1 v_color : float3
var @in @location = 0 f_normal : float3
var @in @location = 1 f_color : float3
var @out @location = 0 output_color : float4

def rotate(v : float3) : float3 {
    let r = transform.rotation
    let x = float3(v.x, v.y * r.y - v.z * r.x, v.y * r.x + v.z * r.y)
    return float3(x.x * r.w + x.z * r.z, x.y, -x.x * r.z + x.z * r.w)
}
[vertex_shader(name="metaballs_vertex")]
def vertex_main {
    var p = rotate(position); p.z += 50.0
    let proj = transform.projection
    gl_Position = float4(p.x * proj.x, p.y * proj.y, p.z * proj.z + proj.w, p.z)
    v_normal = rotate(normal); v_color = color
}
[fragment_shader(name="metaballs_fragment")]
def fragment_main {
    let light = clamp(dot(normalize(f_normal), float3(0.0, 0.0, -1.0)), 0.0, 1.0)
    let spec = pow(light, 30.0)
    output_color = float4(pow(pow(clamp(f_color, float3(0.0), float3(1.0)), float3(2.2)) * light + float3(spec), float3(1.0 / 2.2)), 1.0)
}
