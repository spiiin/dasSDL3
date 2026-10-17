options gen2
module raymarch_shaders shared public
// Adapted from bgfx; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
require math
require spirv/spirv_shader
require spirv/spirv_builtins public

struct Frame { value : float4 }
var @uniform @set = 1 @binding = 0 frame : Frame
var @out @location = 0 v_eye : float3
var @out @location = 1 v_at : float3
var @out @location = 2 v_light : float3
var @out @location = 3 v_color : float4
var @in @location = 0 f_eye : float3
var @in @location = 1 f_at : float3
var @in @location = 2 f_light : float3
var @in @location = 3 f_color : float4
var @out @location = 0 output_color : float4

def inverse_rotation(p : float3) : float3 {
    let t = frame.value.x
    let sx = sin(t); let cx = cos(t); let sy = sin(t * 0.37); let cy = cos(t * 0.37)
    return float3(cy * p.x + sy * p.z, sx * sy * p.x + cx * p.y - sx * cy * p.z, -cx * sy * p.x + sx * p.y + cx * cy * p.z)
}
[vertex_shader(name="raymarch_vertex")]
def vertex_main {
    let corners = fixed_array(float2(-1.0, -1.0), float2(1.0, 1.0), float2(1.0, -1.0), float2(-1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0))
    let colors = fixed_array(float4(1.0, 0.0, 0.0, 1.0), float4(0.0, 0.0, 1.0, 1.0), float4(0.0, 1.0, 0.0, 1.0), float4(1.0, 0.0, 0.0, 1.0), float4(1.0, 1.0, 1.0, 1.0), float4(0.0, 0.0, 1.0, 1.0))
    let uv = corners[gl_VertexIndex]; let f = frame.value
    gl_Position = float4(uv.x, -uv.y, 0.0, 1.0)
    let slope = float2(uv.x * f.y, -uv.y) * 0.57735026919
    v_eye = inverse_rotation(float3(slope * f.z, -15.0 + f.z))
    v_at = inverse_rotation(float3(slope * f.w, -15.0 + f.w))
    v_light = inverse_rotation(normalize(float3(-0.4, -0.5, -1.0))); v_color = colors[gl_VertexIndex]
}
def scene_distance(p : float3) : float {
    var d = length(max(abs(p) - float3(2.5), float3(0.0))) - 0.5
    d = min(d, length(p + float3(4.0, 0.0, 0.0)) - 1.0); d = min(d, length(p - float3(4.0, 0.0, 0.0)) - 1.0)
    d = min(d, length(p + float3(0.0, 4.0, 0.0)) - 1.0); d = min(d, length(p - float3(0.0, 4.0, 0.0)) - 1.0)
    d = min(d, length(p + float3(0.0, 0.0, 4.0)) - 1.0); return min(d, length(p - float3(0.0, 0.0, 4.0)) - 1.0)
}
def normal_at(p : float3) : float3 {
    let e = float2(0.002, 0.0)
    return normalize(float3(scene_distance(p + e.xyy) - scene_distance(p - e.xyy), scene_distance(p + e.yxy) - scene_distance(p - e.yxy), scene_distance(p + e.yyx) - scene_distance(p - e.yyx)))
}
def occlusion(p, n : float3) : float {
    var occ = 0.0
    for (i in 1 .. 4) {let s = float(i) * 0.2; occ += (s - scene_distance(p + n * s)) / exp2(float(i))}
    return 1.0 - occ
}
[fragment_shader(name="raymarch_fragment")]
def fragment_main {
    let maxd = length(f_at - f_eye); let dir = normalize(f_at - f_eye); var t = 0.0
    for (i in 0 .. 64) {let d = scene_distance(f_eye + dir * t); if (d > 0.001){t += d}; if (t >= maxd){break}}
    output_color = f_color; gl_FragDepth = 1.0
    if (t > 0.5 && t < maxd){
        let p = f_eye + dir * t; let n = normal_at(p); let ndotl = dot(n, f_light)
        let rdotv = dot(f_light - 2.0 * ndotl * n, dir)
        let diff = max(0.0, ndotl); let spec = step(0.0, ndotl) * max(0.0, rdotv)
        let fres = max(0.2 + 0.8 * pow(1.0 - ndotl, 5.0), 0.0)
        var value = (0.9 * diff + pow(spec, 128.0) * fres) * occlusion(p, n)
        value = pow(max(value, 0.0), 1.0 / 2.2); output_color = float4(value, value, value, 1.0); gl_FragDepth = t / maxd
    }
}
