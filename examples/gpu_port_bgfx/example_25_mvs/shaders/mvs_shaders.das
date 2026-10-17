// Adapted from bgfx 34-mvs; see the example README and group LICENSE-bgfx.txt.
options gen2
module mvs_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4; tint : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @in @location = 0 position : float3
var @in @location = 1 vertex_color : float4
var @out @location = 0 v_color : float4
var @in @location = 0 rgb : float4
var @out @location = 0 color : float4
[vertex_shader(name="mvs_vertex")]
def vertex_main { gl_Position = transform.vp * transform.model * float4(position, 1.0); v_color = vertex_color * transform.tint }
[fragment_shader(name="mvs_fragment")]
def fragment_main { color = rgb }
