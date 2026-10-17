options gen2
module pixelformats_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Config { values : float4 }
var @uniform @set = 3 @binding = 0 config : Config
var @set = 2 @binding = 0 source : sampler2D
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
[vertex_shader(name="pixelformats_screen")]
def vertex {let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); v_uv = t; gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0)}
[fragment_shader(name="pixelformats_preview")]
def fragment {let c = texture(source, uv); let xy = floor(uv * config.values.zw / 16.0 + float2(config.values.y)); let alternate = int(xy.x + xy.y) & 1; let bg = alternate == 0 ? float3(0.35) : float3(0.65); color = float4(config.values.x > 0.0 ? lerp(bg, c.xyz, c.w) : c.xyz, 1.0)}
