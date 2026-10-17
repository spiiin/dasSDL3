// Adapted from bgfx 32-particles; see the example README and group LICENSE-bgfx.txt.
options gen2
module particles_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Camera { vp : float4x4 }
struct Style { config : float4 }
var @uniform @set = 1 @binding = 0 camera : Camera
var @uniform @set = 3 @binding = 0 style : Style
var @in @location = 0 pos_scale : float4
var @in @location = 1 rgba : float4
var @out @location = 0 v_uv : float2
var @out @location = 1 v_color : float4
var @in @location = 0 uv : float2
var @in @location = 1 tint : float4
var @set = 2 @binding = 0 sprite : sampler2D
var @out @location = 0 color : float4
[vertex_shader(name="particles_vertex")]
def vertex_main {
    let corners = fixed_array(float2(-1.0, -1.0), float2(1.0, -1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, 1.0), float2(-1.0, 1.0))
    let c = corners[gl_VertexIndex]
    gl_Position = camera.vp * float4(pos_scale.xyz + float3(c * pos_scale.w, 0.0), 1.0)
    v_uv = c * 0.5 + float2(0.5); v_color = rgba
}
[fragment_shader(name="particles_fragment")]
def fragment_main {
    let a = texture(sprite, uv).x * tint.w
    color = float4(tint.xyz * a, a * (1.0 - style.config.x))
}
