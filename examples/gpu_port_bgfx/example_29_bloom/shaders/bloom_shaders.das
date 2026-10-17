// Adapted from bgfx 38-bloom. Copyright 2018 Eric Arnebäck.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module bloom_shaders shared public
require dassdl3/sdl3_shader_access
require math public

struct Transform { model, vp : float4x4; tint : float4 }
struct Filter { pixel : float4; config : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 filter : Filter
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_color : float3
var @in @location = 0 rgb : float3
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
var @set = 2 @binding = 0 source : sampler2D
var @set = 2 @binding = 1 bloom : sampler2D
[vertex_shader(name="bloom_geometry")]
def geometry { gl_Position = transform.vp * transform.model * float4(position, 1.0); v_color = transform.tint.xyz * (0.3 + 0.7 * max(dot(normal, normalize(float3(-0.4, 0.8, -0.6))), 0.0)) }
[fragment_shader(name="bloom_emissive")]
def emissive { color = float4(rgb, 1.0) }
[vertex_shader(name="bloom_screen")]
def screen { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); v_uv = t; gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0) }
[fragment_shader(name="bloom_downsample")]
def downsample {
 let p = filter.pixel.xy; var sum = texture(source, uv) * 0.125
 for (y in 0..2) { for (x in 0..2) { sum += texture(source, uv + float2(float(x * 2 - 1), float(y * 2 - 1)) * p * 0.5) * 0.125 } }
 sum += (texture(source, uv + float2(p.x, 0.0)) + texture(source, uv - float2(p.x, 0.0)) + texture(source, uv + float2(0.0, p.y)) + texture(source, uv - float2(0.0, p.y))) * 0.0625
 for (y in 0..2) { for (x in 0..2) { sum += texture(source, uv + float2(float(x * 2 - 1), float(y * 2 - 1)) * p) * 0.03125 } }
 color = sum
}
[fragment_shader(name="bloom_upsample")]
def upsample {
 let p = filter.pixel.xy; var sum = texture(source, uv) * 0.25
 sum += (texture(source, uv + float2(p.x, 0.0)) + texture(source, uv - float2(p.x, 0.0)) + texture(source, uv + float2(0.0, p.y)) + texture(source, uv - float2(0.0, p.y))) * 0.125
 for (y in 0..2) { for (x in 0..2) { sum += texture(source, uv + float2(float(x * 2 - 1), float(y * 2 - 1)) * p) * 0.0625 } }
 color = float4(sum.xyz + texture(bloom, uv).xyz, 1.0)
}
[fragment_shader(name="bloom_combine")]
def combine {
 let original = texture(source, uv).xyz; let glow = texture(bloom, uv).xyz
 var hdr = original + glow * filter.config.x
 if (filter.config.y > 1.5) { hdr = glow }
 color = float4(float3(1.0) - exp(-hdr), 1.0)
}
