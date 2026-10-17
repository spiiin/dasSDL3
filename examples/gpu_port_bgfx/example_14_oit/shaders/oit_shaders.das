options gen2
module oit_shaders shared public
// bgfx 19-oit weighted blended transparency, Branimir Karadzic, BSD-2-Clause.
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4 }
struct Material { color : float4; mode : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 material : Material
var @in @location = 0 position : float3
var @out @location = 0 v_depth : float2
var @in @location = 0 depth : float2
var @out @location = 2 v_uv : float2
var @in @location = 2 uv : float2
var @out @location = 0 color : float4
var @out @location = 1 reveal : float4
var @set = 2 @binding = 0 accum : sampler2D
var @set = 2 @binding = 1 opacity : sampler2D
[vertex_shader(name="oit_vertex")]
def mesh_vs {
    gl_Position = transform.vp * transform.model * float4(position, 1.0)
    v_depth = gl_Position.zw
}
[vertex_shader(name="oit_fullscreen")]
def screen_vs {
    let id = gl_VertexIndex
    let t = float2(float((id << 1) & 2), float(id & 2))
    gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0); v_uv = t
}
[fragment_shader(name="oit_weighted")]
def weighted_fs {
    let alpha = material.color.a
    let z = depth.x / depth.y
    let weight = alpha * clamp(0.03 / (0.00001 + pow(z / 200.0, 5.0)), 0.01, 3000.0)
    color = float4(material.color.rgb * alpha, alpha) * weight
    reveal = float4(alpha)
}
[fragment_shader(name="oit_separate")]
def separate_fs {
    let alpha = material.color.a
    let z = depth.x / depth.y
    let weight = alpha * clamp(0.03 / (0.00001 + pow(z / 200.0, 5.0)), 0.01, 3000.0)
    color = float4(material.color.rgb * weight, alpha)
    // Alpha is accumulated with ZERO/INV_SRC_ALPHA, RGB is weighted additive.
    reveal = float4(weight)
}
[fragment_shader(name="oit_alpha")]
def alpha_fs { color = material.color }
[fragment_shader(name="oit_resolve")]
def resolve_fs {
    let a = textureLod(accum, uv, 0.0)
    let b = textureLod(opacity, uv, 0.0).r
    let transmittance = material.mode.x > 0.5 ? a.a : b
    let divisor = material.mode.x > 0.5 ? b : a.a
    color = float4(a.rgb / clamp(divisor, 0.0001, 50000.0) * (1.0 - transmittance) + float3(0.08, 0.1, 0.15) * transmittance, 1.0)
}
