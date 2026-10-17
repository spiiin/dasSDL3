options gen2
// Adapted from bgfx 27-terrain. Copyright 2015 Andrew Mac.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module terrain_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Camera { vp : float4x4; config : float4 }
var @uniform @set = 1 @binding = 0 camera : Camera
var @set = 0 @binding = 0 heightmap : sampler2D
var @in @location = 0 position : float3
var @in @location = 2 texcoord : float2
var @out @location = 0 v_color : float3
var @in @location = 0 rgb : float3
var @out @location = 0 color : float4
[vertex_shader(name="terrain_vertex")]
def vertex_main {
    var p = position
    if (camera.config.x < 0.5) { p.y = textureLod(heightmap, texcoord, 0.0).x * 24.0 }
    gl_Position = camera.vp * float4(p, 1.0)
    v_color = float3(texcoord, p.y / 12.0)
}
[fragment_shader(name="terrain_fragment")]
def fragment_main { color = float4(rgb, 1.0) }
