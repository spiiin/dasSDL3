options gen2
// Adapted from bgfx 23-vectordisplay. Copyright 2014 Kai Jourdan.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module vectordisplay_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Params { values : float4 }
var @uniform @set = 1 @binding = 0 frame : Params
var @uniform @set = 3 @binding = 0 params : Params
var @in @location = 0 position : float3
var @in @location = 1 rgb : float3
var @in @location = 2 coord : float2
var @out @location = 0 v_uv : float2
var @out @location = 1 v_rgb : float3
var @in @location = 0 uv : float2
var @in @location = 1 line_rgb : float3
var @set = 2 @binding = 0 source : sampler2D
var @set = 2 @binding = 1 history : sampler2D
var @out @location = 0 color : float4
[vertex_shader(name="vectordisplay_vertex")]
def line_vs {
    var p = position.xy
    if (position.z > 0.5) { let a = frame.values.x; let c = p - float2(880.0, 480.0); p = float2(c.x * cos(a) - c.y * sin(a), c.x * sin(a) + c.y * cos(a)) + float2(880.0, 480.0) }
    gl_Position = float4(p.x / 640.0 - 1.0, 1.0 - p.y / 480.0, 0.0, 1.0); v_uv = coord; v_rgb = rgb
}
[fragment_shader(name="vectordisplay_line")]
def line_fs { let a = exp(-uv.y * uv.y * 5.0); color = float4(line_rgb * a, 1.0) }
[vertex_shader(name="vectordisplay_screen")]
def screen_vs { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0); v_uv = t }
[fragment_shader(name="vectordisplay_blur")]
def blur_fs {
    let weights = fixed_array(0.05, 0.09, 0.12, 0.15, 0.16, 0.15, 0.12, 0.09, 0.05)
    var sum = float4(0.0)
    for (i in 0..9) { sum += texture(source, uv + params.values.xy * float(i - 4)) * weights[i] }
    color = sum
}
[fragment_shader(name="vectordisplay_persist")]
def persist_fs { color = float4(texture(source, uv).rgb + texture(history, uv).rgb * params.values.z, 1.0) }
[fragment_shader(name="vectordisplay_compose")]
def compose_fs { color = float4(texture(source, uv).rgb + texture(history, uv).rgb * params.values.w, 1.0) }
