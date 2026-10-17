// Port of bgfx 45-bokeh, Copyright 2021 elven cache. BSD-2-Clause.
options gen2
module bokeh_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Config { size, focus, shape : float4 }
var @uniform @set = 3 @binding = 0 config : Config
var @set = 2 @binding = 0 image0 : sampler2D
var @set = 2 @binding = 1 image1 : sampler2D
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
[vertex_shader(name="bokeh_screen")]
def screen { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); v_uv = t; gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0) }
def depth(tc : float2) : float { return textureLod(image1, tc, 0.0).x }
def coc(z : float) : float { return clamp((1.0 / config.focus.y - 1.0 / z) * config.focus.z, -1.0, 1.0) }
def gamma(c : float3) : float3 { return pow(max(c, float3(0.0)), float3(1.0 / 2.2)) }
[fragment_shader(name="bokeh_downsample")]
def downsample { color = float4(texture(image0, uv).xyz, coc(depth(uv)) * config.focus.x) }
def sample_color(tc : float2; packed : bool) : float4 { let c = textureLod(image0, tc, 0.0); return float4(c.xyz, packed ? c.w : coc(depth(tc)) * config.focus.x) }
def filter(packed : bool) : float4 {
    let center = sample_color(uv, packed)
    var sum = center.xyz; var total = 1.0; var total_size = 0.0
    var theta = fract(sin(dot(gl_FragCoord.xy + float2(314.0, 159.0) * config.size.z, float2(12.9898, 78.233))) * 43758.5453123) * 6.2831853
    var radius = config.focus.w
    while (radius < config.focus.x) {
        let shape = config.shape.x <= 1.0 ? 1.0 : abs(fract(theta * config.shape.x / 6.2831853 + config.shape.w) - 0.5) * config.shape.z + config.shape.y
        let tc = uv + float2(cos(theta), sin(theta)) * radius * shape / config.size.xy
        let s = sample_color(tc, packed); var size = abs(s.w)
        if (s.w > center.w) { size = clamp(size, 0.0, abs(center.w) * 2.0) }
        let m = smoothstep(radius - 0.5, radius + 0.5, size)
        sum += lerp(sum / total, s.xyz, m); total_size += size; total += 1.0
        theta += 2.39996323; radius += config.focus.w / radius
    }
    return float4(sum / total, total_size / max(total - 1.0, 0.00001))
}
[fragment_shader(name="bokeh_single")]
def single { color = float4(gamma(filter(false).xyz), 1.0) }
[fragment_shader(name="bokeh_half")]
def half { color = filter(true) }
[fragment_shader(name="bokeh_combine")]
def combine { let blurred = texture(image1, uv); color = float4(gamma(lerp(texture(image0, uv).xyz, blurred.xyz, clamp(blurred.w - 1.0, 0.0, 1.0))), 1.0) }
[fragment_shader(name="bokeh_copy")]
def copy { color = float4(gamma(texture(image0, uv).xyz), 1.0) }
[fragment_shader(name="bokeh_debug")]
def debug { let c = gamma(texture(image0, uv).xyz); let gray = float3(dot(c, float3(0.33, 0.34, 0.33))); let amount = coc(depth(uv)); let tint = amount < 0.0 ? float3(187.0, 61.0, 7.0) / 255.0 : float3(11.0, 89.0, 138.0) / 255.0; color = float4(lerp(gray, gray * tint, abs(amount)), 1.0) }

[fragment_shader(name="bokeh_depth")]
def linear_depth { color = float4(1.0 / max(100.0 - texture(image0, uv).x * 99.99, 0.00001)) }
