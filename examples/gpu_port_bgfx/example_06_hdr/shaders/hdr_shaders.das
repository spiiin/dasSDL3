options gen2
module hdr_shaders shared public
// Adapted from bgfx; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
require math
require spirv/spirv_shader
require spirv/spirv_builtins public

struct Frame { frame : float4; tone : float4; sampling : float4 }
var @uniform @set = 1 @binding = 0 uniforms : Frame
var @out @location = 0 v_uv : float2
var @out @flat @location = 1 v_frame : float4
var @out @flat @location = 2 v_tone : float4
var @out @flat @location = 3 v_sampling : float4
var @in @location = 0 f_uv : float2
var @in @flat @location = 1 f_frame : float4
var @in @flat @location = 2 f_tone : float4
var @in @flat @location = 3 f_sampling : float4
var @out @location = 0 output_color : float4
var @set = 2 @binding = 0 environment : samplerCube
var @set = 2 @binding = 0 source : sampler2D
var @set = 2 @binding = 1 luminance : sampler2D
var @set = 2 @binding = 2 bloom : sampler2D

def rotate_y(p : float3; t : float) : float3 {
    let s = sin(t); let c = cos(t); return float3(c * p.x - s * p.z, p.y, s * p.x + c * p.z)
}
def reinhard(x : float3; white : float) : float3 {return x * (float3(1.0) + x / white) / (float3(1.0) + x)}
def rgb_xyz(c : float3) : float3 {return float3(dot(c, float3(0.4124, 0.3576, 0.1805)), dot(c, float3(0.2126, 0.7152, 0.0722)), dot(c, float3(0.0193, 0.1192, 0.9505)))}
def xyz_rgb(c : float3) : float3 {return float3(dot(c, float3(3.2406, -1.5372, -0.4986)), dot(c, float3(-0.9689, 1.8758, 0.0415)), dot(c, float3(0.0557, -0.204, 1.057)))}
[vertex_shader(name="hdr_sky_vertex")]
def sky_vs {
    let id = gl_VertexIndex
    let uv = float2(float((id << 1) & 2), float(id & 2))
    gl_Position = float4(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0, 0.0, 1.0)
    v_uv = uv; v_frame = uniforms.frame
}
[vertex_shader(name="hdr_filter_vertex")]
def filter_vs {
    let id = gl_VertexIndex
    let uv = float2(float((id << 1) & 2), float(id & 2))
    gl_Position = float4(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0, 0.0, 1.0)
    v_uv = uv; v_sampling = uniforms.sampling
}
[vertex_shader(name="hdr_tone_vertex")]
def tone_vs {
    let id = gl_VertexIndex
    let uv = float2(float((id << 1) & 2), float(id & 2))
    gl_Position = float4(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0, 0.0, 1.0)
    v_uv = uv; v_tone = uniforms.tone; v_sampling = uniforms.sampling
}
[fragment_shader(name="hdr_sky_fragment")]
def sky_fs {
    let d = rotate_y(normalize(float3((f_uv.x * 2.0 - 1.0) * f_frame.y, 1.0 - f_uv.y * 2.0, 1.7320508)), f_frame.x)
    output_color = float4(max(float3(0.0), textureLod(environment, d, 0.0).rgb), 1.0)
}
[fragment_shader(name="hdr_lum_fragment")]
def lum_fs {
    var sum = 0.0
    for (y in -1 .. 2) {for (x in -1 .. 2) {sum += dot(textureLod(source, f_uv + float2(float(x), float(y)) * f_sampling.xy, 0.0).rgb, float3(0.2126, 0.7152, 0.0722))}}
    output_color = float4(sum / 9.0, 0.0, 0.0, 1.0)
}
[fragment_shader(name="hdr_avg_fragment")]
def avg_fs {
    var sum = 0.0
    for (y in 0 .. 4) {for (x in 0 .. 4) {sum += textureLod(source, f_uv + (float2(float(x), float(y)) - float2(1.5)) * f_sampling.xy, 0.0).r}}
    output_color = float4(sum / 16.0, 0.0, 0.0, 1.0)
}
[fragment_shader(name="hdr_bright_fragment")]
def bright_fs {
    var c = float3(0.0)
    for (y in -1 .. 2) {for (x in -1 .. 2) {c += textureLod(source, f_uv + float2(float(x), float(y)) * f_sampling.xy, 0.0).rgb}}
    c /= 9.0
    let lum = clamp(textureLod(luminance, float2(0.5), 0.0).r, 0.1, 0.7)
    c = max(float3(0.0), c - float3(f_tone.z)) * f_tone.x / (lum + 0.0001)
    output_color = float4(pow(reinhard(c, f_tone.y), float3(1.0 / 2.2)), 1.0)
}
[fragment_shader(name="hdr_blur_fragment")]
def blur_fs {
    let weights = fixed_array(1.0, 0.9, 0.55, 0.18, 0.1)
    var c = textureLod(source, f_uv, 0.0).rgb
    let delta = float2(0.0, f_sampling.y)
    for (i in 1 .. 5) {c += (textureLod(source, f_uv + float(i) * delta, 0.0).rgb + textureLod(source, f_uv - float(i) * delta, 0.0).rgb) * weights[i]}
    output_color = float4(c / 4.46, 1.0)
}
[fragment_shader(name="hdr_tone_fragment")]
def tone_fs {
    var rgb = textureLod(source, f_uv, 0.0).rgb
    let lum = clamp(textureLod(luminance, float2(0.5), 0.0).r, 0.1, 0.7)
    let xyz = rgb_xyz(rgb); let mapped = reinhard(float3(xyz.y * f_tone.x / (lum + 0.0001)), f_tone.y).x
    rgb = xyz_rgb(xyz * (mapped / max(xyz.y, 0.000001)))
    let weights = fixed_array(1.0, 0.9, 0.55, 0.18, 0.1)
    var blur = textureLod(bloom, f_uv, 0.0).rgb
    for (i in 1 .. 5) {let delta = float2(float(i) * f_sampling.x, 0.0); blur += (textureLod(bloom, f_uv + delta, 0.0).rgb + textureLod(bloom, f_uv - delta, 0.0).rgb) * weights[i]}
    output_color = float4(pow(max(float3(0.0), rgb + 0.6 * f_tone.w * blur / 4.46), float3(1.0 / 2.2)), 1.0)
}
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_clip : float3
var @out @location = 1 v_view : float3
var @out @location = 2 v_normal : float3
var @out @flat @location = 3 v_time : float
var @in @location = 0 f_clip : float3
var @in @location = 1 f_view : float3
var @in @location = 2 f_normal : float3
var @in @flat @location = 3 f_time : float
[vertex_shader(name="hdr_scene_vertex")]
def scene_vs {
    let p = rotate_y(position - float3(0.0, 1.0, 0.0), -uniforms.frame.x) + float3(0.0, 0.0, 2.5)
    gl_Position = float4(p.x * 1.7320508 / uniforms.frame.y, p.y * 1.7320508, p.z * 100.0 / 99.9 - 10.0 / 99.9, p.z)
    v_clip = gl_Position.xyz; v_view = p; v_normal = rotate_y(normal, -uniforms.frame.x); v_time = uniforms.frame.x
}
[fragment_shader(name="hdr_scene_fragment")]
def scene_fs {
    let n = normalize(f_normal); let view = normalize(f_view); let light = float3(0.0, 0.0, -1.0)
    let ndotl = dot(n, light); let spec = step(0.0, ndotl) * max(0.0, dot(light - 2.0 * ndotl * n, view))
    let fres = max(0.2 + 0.8 * pow(max(0.0, 1.0 - ndotl), 5.0), 0.0)
    let index = ((sin(f_clip.x * 3.0 + f_time) * 0.3 + 0.7) + (cos(f_clip.y * 3.0 + f_time) * 0.4 + 0.6) + (cos(f_clip.z * 3.0 + f_time) * 0.2 + 0.8)) * 3.14159265
    let color = (sin(index * float3(8.0, 4.0, 2.0)) * 0.4 + float3(0.6)) * max(float3(0.0), textureLod(environment, reflect(view, -n), 0.0).rgb)
    output_color = float4(color * max(0.0, ndotl) + float3(fres * pow(spec, 128.0)), 1.0)
}
