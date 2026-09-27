options gen2
module fontsdf_shaders shared public
// SDF text rendering adapted from bgfx 11-fontsdf (Jeremie Roy, BSD-2-Clause).
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct TextTransform {
    viewport : float4
    origin : float4
}
struct TextStyle {
    effects : float4
    color : float4
    outline : float4
    shadow : float4
}
var @uniform @set = 1 @binding = 0 transform : TextTransform
var @uniform @set = 3 @binding = 0 style : TextStyle
var @in @location = 0 position : float2
var @in @location = 1 uv : float2
var @in @location = 2 bounds : float4
var @out @location = 1 v_bounds : float4
var @in @location = 1 f_bounds : float4
var @out @location = 0 v_uv : float2
var @in @location = 0 f_uv : float2
var @set = 2 @binding = 0 atlas : sampler2D
var @out @location = 0 output_color : float4
[vertex_shader(name="fontsdf_vertex")]
def text_vs {
    let t = transform.viewport
    let p = float2(position.x, -position.y) * t.z
    let screen = float2(p.x * cos(t.w) - p.y * sin(t.w), p.x * sin(t.w) + p.y * cos(t.w)) + transform.origin.xy
    gl_Position = float4(screen.x * 2.0 / t.x - 1.0, 1.0 - screen.y * 2.0 / t.y, 0.0, 1.0)
    v_uv = uv
    v_bounds = bounds
}
[fragment_shader(name="fontsdf_fragment")]
def text_fs {
    // Clamp to this glyph's texel centers, not to the whole shared atlas.
    let half_texel = float2(0.5) / float2(textureSize(atlas, 0))
    let lower = f_bounds.xy + half_texel
    let upper = max(lower, f_bounds.zw - half_texel)
    let d = texture(atlas, clamp(f_uv, lower, upper)).a
    let edge = max(fwidth(d) * 0.65, 0.002)
    let fill = smoothstep(0.5 - edge, 0.5 + edge, d)
    let outer = smoothstep(0.5 - style.effects.x - edge, 0.5 - style.effects.x + edge, d)
    let offset = dFdx(f_uv) * style.effects.z + dFdy(f_uv) * style.effects.w
    let shadow_uv = f_uv - offset
    let shadow_d = texture(atlas, clamp(shadow_uv, lower, upper)).a
    let inside = shadow_uv.x >= f_bounds.x && shadow_uv.y >= f_bounds.y && shadow_uv.x <= f_bounds.z && shadow_uv.y <= f_bounds.w
    let shade = smoothstep(0.5 - edge * (1.0 + style.effects.y), 0.5 + edge * (1.0 + style.effects.y), shadow_d) * style.shadow.a * (inside ? 1.0 : 0.0)
    let a = fill * style.color.a
    let b = max(outer - fill, 0.0) * style.outline.a
    let c = shade * (1.0 - a - b)
    output_color = float4(style.color.rgb * a + style.outline.rgb * b + style.shadow.rgb * c, a + b + c)
}
