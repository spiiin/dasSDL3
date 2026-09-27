options gen2
module cube_shaders shared public
// Adapted from bgfx; Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: ../LICENSE-bgfx.txt.
require math
require spirv/spirv_shader
require spirv/spirv_builtins public

struct Frame { value : float4 }
var @uniform @set = 1 @binding = 0 frame : Frame
var @in @location = 0 position : float3
var @in @location = 1 color : float4
var @in @location = 2 m0 : float4
var @in @location = 3 m1 : float4
var @in @location = 4 m2 : float4
var @in @location = 5 m3 : float4
var @in @location = 6 tint : float4
var @out @location = 0 v_color : float4
var @in @location = 0 f_color : float4
var @out @location = 0 output_color : float4
[vertex_shader(name="instancing_vertex")]
def instancing_vs {
    var p = (m0 * position.x + m1 * position.y + m2 * position.z + m3).xyz; p.z += frame.value.z
    gl_Position = float4(p.x * 1.7320508 / frame.value.y, p.y * 1.7320508, p.z * 100.0 / 99.9 - 10.0 / 99.9, p.z)
    v_color = color * tint
}
[fragment_shader(name="instancing_fragment")]
def instancing_fs {output_color = f_color}
var @in @location = 1 normal : float3
var @in @location = 2 tangent : float4
var @in @location = 3 uv : float2
var @in @location = 4 bm0 : float4
var @in @location = 5 bm1 : float4
var @in @location = 6 bm2 : float4
var @in @location = 7 bm3 : float4
var @out @location = 0 v_world : float3
var @out @location = 1 v_normal : float3
var @out @location = 2 v_tangent : float3
var @out @location = 3 v_bitangent : float3
var @out @location = 4 v_uv : float2
var @out @flat @location = 5 v_frame : float4
var @in @location = 0 f_world : float3
var @in @location = 1 f_normal : float3
var @in @location = 2 f_tangent : float3
var @in @location = 3 f_bitangent : float3
var @in @location = 4 f_uv : float2
var @in @flat @location = 5 f_frame : float4
var @set = 2 @binding = 0 color_tex : sampler2D
var @set = 2 @binding = 1 normal_tex : sampler2D
[vertex_shader(name="bump_vertex")]
def bump_vs {
    var p = (bm0 * position.x + bm1 * position.y + bm2 * position.z + bm3).xyz; v_world = p; p.z += frame.value.z
    gl_Position = float4(p.x * 1.7320508 / frame.value.y, p.y * 1.7320508, p.z * 100.0 / 99.9 - 10.0 / 99.9, p.z)
    v_normal = bm0.xyz * normal.x + bm1.xyz * normal.y + bm2.xyz * normal.z
    v_tangent = bm0.xyz * tangent.x + bm1.xyz * tangent.y + bm2.xyz * tangent.z
    v_bitangent = cross(v_normal, v_tangent) * tangent.w; v_uv = uv; v_frame = frame.value
}
[fragment_shader(name="bump_fragment")]
def bump_fs {
    let xy = (texture(normal_tex, f_uv).xy * 2.0 - float2(1.0)) * f_frame.w
    let n = float3(xy, sqrt(clamp(1.0 - dot(xy, xy), 0.0, 1.0))); var lighting = float3(0.0)
    let colors = fixed_array(float3(1.0, 0.7, 0.2), float3(0.7, 0.2, 1.0), float3(0.2, 1.0, 0.7), float3(1.0, 0.4, 0.2))
    for (i in 0 .. 4) {
        let index = float(i)
        let lp = float3(sin(f_frame.x * (0.1 + index * 0.17) + index * 1.5707963 * 1.37) * 3.0, cos(f_frame.x * (0.2 + index * 0.29) + index * 1.5707963 * 1.49) * 3.0, -2.5) - f_world
        let attenuation = 1.0 - smoothstep(0.8, 1.0, length(lp) / 3.0); let l = normalize(lp)
        let local = float3(dot(l, f_tangent), dot(l, f_bitangent), dot(l, f_normal))
        lighting += colors[i] * clamp(dot(local, n), 0.0, 1.0) * attenuation
    }
    let albedo = pow(texture(color_tex, f_uv).rgb, float3(2.2))
    output_color = float4(pow(max(float3(0.05), lighting) * albedo, float3(1.0 / 2.2)), 1.0)
}
