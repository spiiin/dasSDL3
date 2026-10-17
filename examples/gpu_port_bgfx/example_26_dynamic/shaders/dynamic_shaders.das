// Adapted from bgfx 35-dynamic. Copyright 2011-2026 Branimir Karadzic.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module dynamic_shaders shared public
require dassdl3/sdl3_shader_access
require math public

struct Transform { model, vp : float4x4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @in @location = 0 position : float3
var @in @location = 1 vertex_color : float3
var @out @location = 0 v_color : float3
var @in @location = 0 rgb : float3
var @out @location = 0 color : float4
[vertex_shader(name="dynamic_vertex")]
def vertex_main { gl_Position = transform.vp * transform.model * float4(position, 1.0); v_color = vertex_color }
[fragment_shader(name="dynamic_fragment")]
def fragment_main { color = float4(rgb, 1.0) }
