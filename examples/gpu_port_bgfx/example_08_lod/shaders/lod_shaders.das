options gen2
module lod_shaders shared public
// bgfx 12-lod: Milos Tosic, BSD-2-Clause. Knight-tour screen-door transition.
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct LodTransform {
    model, view_projection : float4x4
}
struct LodFade {
    stipple : float4
}
var @uniform @set = 1 @binding = 0 transform : LodTransform
var @uniform @set = 3 @binding = 0 fade : LodFade
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 uv : float2
var @out @location = 0 v_normal : float3
var @out @location = 1 v_uv : float2
var @in @location = 0 f_normal : float3
var @in @location = 1 f_uv : float2
var @set = 2 @binding = 0 albedo : sampler2D
var @out @location = 0 output_color : float4
[vertex_shader(name="lod_vertex")]
def tree_vs {
    gl_Position = transform.view_projection * transform.model * float4(position, 1.0)
    v_normal = (transform.model * float4(normal, 0.0)).xyz
    v_uv = uv
}
[fragment_shader(name="lod_fragment")]
def tree_fs {
    let rank = fixed_array(0, 17, 12, 11, 10, 23, 6, 27, 13, 20, 15, 30, 3, 26, 9, 24, 16, 1, 18, 29, 22, 7, 28, 5, 19, 14, 31, 2, 21, 4, 25, 8)
    let at = (int(gl_FragCoord.y) & 3) * 8 + (int(gl_FragCoord.x) & 7)
    let threshold = float(rank[at]) / 32.0
    if ((fade.stipple.y < 0.5 && threshold >= fade.stipple.x) || (fade.stipple.y > 0.5 && threshold < fade.stipple.x)) {
        discard()
    }
    let color = texture(albedo, f_uv)
    if (color.a < 0.5) {
        discard()
    }
    let lit = 0.2 + 0.8 * max(0.0, dot(normalize(f_normal), normalize(float3(-0.4, 0.7, -1.0))))
    output_color = float4(pow(pow(color.rgb, float3(2.2)) * lit, float3(1.0 / 2.2)), 1.0)
}
