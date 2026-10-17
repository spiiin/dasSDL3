// Adapted from bgfx 40-svt. BSD-2-Clause.
options gen2
module svt_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Config { vp : float4x4; settings : float4 }
var @uniform @set = 1 @binding = 0 camera : Config
var @uniform @set = 3 @binding = 0 config : Config
var @set = 2 @binding = 0 pages : sampler2D
var @set = 2 @binding = 1 atlas : sampler2D
var @in @location = 0 position : float3
var @in @location = 2 texcoord : float2
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
[vertex_shader(name="svt_vertex")]
def vertex { gl_Position = camera.vp * float4(position, 1.0); v_uv = texcoord }
def mip() : float { let dx = dFdx(uv * 8192.0); let dy = dFdy(uv * 8192.0); return max(0.5 * log2(max(max(dot(dx, dx), dot(dy, dy)), 0.00001)), 0.0) }
[fragment_shader(name="svt_feedback")]
def feedback { let level = clamp(floor(mip() - config.settings.x), 0.0, 6.0); let page = floor(clamp(uv, float2(0.0), float2(0.999999)) * 64.0 / exp2(level)); color = float4(page / 255.0, level / 255.0, 1.0) }
[fragment_shader(name="svt_fragment")]
def fragment {
    let level = clamp(floor(mip()), 0.0, 6.0); let count = 64.0 / exp2(level)
    let pixel = floor(clamp(uv, float2(0.0), float2(0.999999)) * count)
    let offset = 128.0 - 128.0 / exp2(level)
    let page = floor(textureLod(pages, (pixel + float2(0.5, offset + 0.5)) / float2(64.0, 127.0), 0.0).xyz * 255.0 + float3(0.5))
    let local = fract(uv * 64.0 / exp2(page.z)); let tc = (page.xy + (local * 128.0 + float2(1.0)) / 130.0) / 15.0
    var c = texture(atlas, tc).xyz
    if (config.settings.z > 0.5) { let tint = float3(fract(page.z * 0.37 + 0.2), fract(page.z * 0.61 + 0.4), fract(page.z * 0.83 + 0.6)); c = lerp(c, tint, 0.5) }
    if (config.settings.y > 0.5 && (local.x < 1.0 / 128.0 || local.y < 1.0 / 128.0 || local.x > 127.0 / 128.0 || local.y > 127.0 / 128.0)) { c = float3(1.0, 0.0, 0.0) }
    color = float4(c, 1.0)
}
