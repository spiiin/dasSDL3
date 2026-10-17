options gen2
module bunny_shaders shared public
// Adapted from bgfx; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
require math
require spirv/spirv_shader
require spirv/spirv_builtins public

struct Frame { value : float4 }
var @uniform @set = 1 @binding = 0 frame : Frame
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_pos : float3
var @out @location = 1 v_view : float3
var @out @location = 2 v_normal : float3
var @out @location = 3 v_color : float4
var @out @flat @location = 4 v_time : float
var @in @location = 0 f_pos : float3
var @in @location = 1 f_view : float3
var @in @location = 2 f_normal : float3
var @in @location = 3 f_color : float4
var @in @flat @location = 4 f_time : float
var @out @location = 0 output_color : float4

def rotate(p : float3) : float3 {
    let s = sin(frame.value.x * 0.37); let c = cos(frame.value.x * 0.37)
    return float3(c * p.x - s * p.z, p.y, s * p.x + c * p.z)
}
[vertex_shader(name="mesh_vertex")]
def vertex_main {
    let f = frame.value
    let sx = sin(position.x * 32.0 + f.x * 4.0) * 0.5 + 0.5
    let cy = cos(position.y * 32.0 + f.x * 4.0) * 0.5 + 0.5
    let displacement = float3(sx, cy, sx * cy)
    let p = rotate(position + normal * displacement * 0.06) + float3(0.0, -1.0, 2.5)
    let q = f.w / (f.w - f.z)
    gl_Position = float4(p.x * 1.73205080757 / f.y, p.y * 1.73205080757, p.z * q - f.z * q, p.z)
    v_pos = gl_Position.xyz; v_view = p; v_normal = rotate(normal)
    v_color = float4(float3(length(displacement) * 0.4 + 0.6), 1.0); v_time = f.x
}
[fragment_shader(name="mesh_fragment")]
def fragment_main {
    let light = float3(0.0, 0.0, -1.0); let n = normalize(f_normal); let view = normalize(f_view)
    let ndotl = dot(n, light); let rdotv = dot(light - 2.0 * ndotl * n, view)
    let diff = max(0.0, ndotl); let spec = step(0.0, ndotl) * max(0.0, rdotv)
    let fres = max(0.2 + 0.8 * pow(1.0 - ndotl, 5.0), 0.0)
    let index = ((sin(f_pos.x * 3.0 + f_time) * 0.3 + 0.7) + (cos(f_pos.y * 3.0 + f_time) * 0.4 + 0.6) + (cos(f_pos.z * 3.0 + f_time) * 0.2 + 0.8)) * 3.14159265359
    let color = (sin(index * float3(8.0, 4.0, 2.0)) * 0.4 + float3(0.6)) * f_color.xyz
    output_color = float4(pow(float3(0.07, 0.06, 0.08) + color * diff + float3(fres * pow(spec, 128.0)), float3(1.0 / 2.2)), 1.0)
}
