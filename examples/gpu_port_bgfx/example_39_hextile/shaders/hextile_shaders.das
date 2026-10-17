// Adapted from bgfx 49-hextile, Preetish Kakkar; algorithm by Morten Mikkelsen.
options gen2
module hextile_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Camera { vp : float4x4 }
struct Config { values : float4 }
var @uniform @set = 1 @binding = 0 camera : Camera
var @uniform @set = 3 @binding = 0 settings : Config
var @set = 2 @binding = 0 source : sampler2D
var @in @location = 0 position : float3
var @out @location = 0 world : float3
var @in @location = 0 point : float3
var @out @location = 0 color : float4
[vertex_shader(name="hextile_vertex")]
def vertex { world = position * 30.0; gl_Position = camera.vp * float4(world, 1.0) }
def hash(p : float2) : float2 { return fract(sin(float2(127.1 * p.x + 269.5 * p.y, 311.7 * p.x + 183.3 * p.y)) * 43758.5453) }
def rotate(p : float2; angle : float) : float2 { let c = cos(angle); let s = sin(angle); return float2(c * p.x - s * p.y, s * p.x + c * p.y) }
def sample_tile(uv, vertex : float2; lod : float) : float4 {
 var a = abs(vertex.x * vertex.y) + abs(vertex.x + vertex.y) + 3.14159265
 if (a < 0.0){a += 6.2831853}; if (a > 3.14159265){a -= 6.2831853}
 a *= settings.values.z
 let center = float2(vertex.x, 0.5 * vertex.x + vertex.y / 1.15470054) / 3.4641016
 return textureLod(source, rotate(uv - center, a) + center + hash(vertex), lod)
}
[fragment_shader(name="hextile_fragment")]
def fragment {
 let uv = point.xz * (0.05 * settings.values.y)
 // Isotropic explicit LOD from continuous UV derivatives, before randomized offsets.
 // Rotation preserves their lengths. No derivative is taken across a tile discontinuity.
 let dx = dFdx(uv) * 2048.0; let dy = dFdy(uv) * 2048.0
 let lod = max(0.0, 0.5 * log2(max(dot(dx, dx), dot(dy, dy))))
 if (settings.values.w > 0.0){ color = textureLod(source, uv, lod); return }
 let scaled = uv * 3.4641016; let skew = float2(scaled.x, -0.57735027 * scaled.x + 1.15470054 * scaled.y)
 let base = floor(skew); let f = fract(skew); let z = 1.0 - f.x - f.y
 let s = z <= 0.0 ? 1.0 : 0.0; let s2 = 2.0 * s - 1.0
 let weights = float3(-z * s2, s - f.y * s2, s - f.x * s2)
 let v1 = base + float2(s); let v2 = base + float2(s, 1.0 - s); let v3 = base + float2(1.0 - s, s)
 let c1 = sample_tile(uv, v1, lod); let c2 = sample_tile(uv, v2, lod); let c3 = sample_tile(uv, v3, lod)
 let luminance = float3(0.299, 0.587, 0.114)
 var w = lerp(float3(1.0), float3(dot(c1.xyz, luminance), dot(c2.xyz, luminance), dot(c3.xyz, luminance)), 0.6) * pow(weights, float3(7.0))
 w /= w.x + w.y + w.z
 let k = log(0.3) / log(0.5); let stepw = 2.0 * step(float3(0.5), w); let m = 2.0 * (float3(1.0) - stepw)
 w = 0.5 * stepw + 0.25 * m * pow(max(float3(0.0), stepw + w * m), float3(k)); w /= w.x + w.y + w.z
 color = w.x * c1 + w.y * c2 + w.z * c3
 if (settings.values.x > 0.0){
  var a = (v1.x - v1.y) - 3.0 * floor((v1.x - v1.y) / 3.0); if (a < 0.0){a += 3.0}
  let hi = a < 2.0 ? a + 1.0 : 0.0; let lo = a > 0.0 ? a - 1.0 : 2.0
  let b = v1.x < v3.x ? lo : hi; let c = v1.x < v3.x ? hi : lo
  color = float4(c == 0.0 ? w.z : (b == 0.0 ? w.y : w.x), c == 1.0 ? w.z : (b == 1.0 ? w.y : w.x), c == 2.0 ? w.z : (b == 2.0 ? w.y : w.x), 1.0)
 }
}
