// Adapted from bgfx 48-drawindirect, Liam Twigger.
options gen2
module drawindirect_shaders shared public
require dassdl3/sdl3_shader_access
require math
struct Params { values : float4 }
struct Camera { vp : float4x4 }
var @uniform @set = 2 @binding = 0 params : Params
var @uniform @set = 1 @binding = 0 camera : Camera
var @ssbo @set = 1 @binding = 0 commands : array<uint>
var @ssbo @set = 1 @binding = 1 instances : array<float4>
var @in @location = 0 position : float3
var @in @location = 1 vertex_color : float3
var @in @location = 3 a : float4
var @in @location = 4 b : float4
var @in @location = 5 c : float4
var @in @location = 6 d : float4
var @in @location = 7 tint : float4
var @out @location = 0 rgb : float4
var @in @location = 0 rgba : float4
var @out @location = 0 color : float4
[compute_shader(local_size_x=64, name="drawindirect_build"), sdl_shader_access(name="drawindirect_build")]
def build {
 let k = gl_GlobalInvocationID.x; let side = uint(params.values.x); if (k >= side * side){return }
 let xx = float(k % side); let yy = float(k / side); let time = params.values.y
 let sx = sin(time + xx * 0.21); let cx = cos(time + xx * 0.21); let sy = sin(time + yy * 0.37); let cy = cos(time + yy * 0.37)
 instances[k * 5u] = float4(cy, 0.0, sy, 0.0); instances[k * 5u + 1u] = float4(sx * sy, cx, -sx * cy, 0.0); instances[k * 5u + 2u] = float4(-cx * sy, sx, cx * cy, 0.0)
 instances[k * 5u + 3u] = float4(-15.0 - (float(side) - 11.0) * 1.2 + xx * 3.0, -15.0 - (float(side) - 11.0) * 1.4 + yy * 3.0, max(0.0, (float(side) - 11.0) * 3.0), 1.0)
 instances[k * 5u + 4u] = float4(sin(time + xx / 11.0) * 0.5 + 0.5, cos(time + yy / 11.0) * 0.5 + 0.5, sin(time * 3.0) * 0.5 + 0.5, 1.0)
 let tetra = (k % 2u) != 0u
 commands[k * 5u] = tetra ? 12u : 36u; commands[k * 5u + 1u] = 1u; commands[k * 5u + 2u] = tetra ? 36u : 0u; commands[k * 5u + 3u] = tetra ? 8u : 0u; commands[k * 5u + 4u] = k
}
[vertex_shader(name="drawindirect_vertex")]
def vertex { gl_Position = camera.vp * (a * position.x + b * position.y + c * position.z + d); rgb = float4(vertex_color, 1.0) * tint }
[fragment_shader(name="drawindirect_fragment")]
def fragment {color = rgba}
