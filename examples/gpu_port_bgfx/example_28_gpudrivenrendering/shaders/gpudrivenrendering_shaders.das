// Adapted from bgfx 37-gpudrivenrendering. Copyright 2018 Kostas Anagnostou.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module gpudrivenrendering_shaders shared public
require dassdl3/sdl3_shader_access
require math public

struct Camera { vp : float4x4; config : float4 }
struct Pyramid { level : uint4; viewport : float4 }
var @uniform @set = 1 @binding = 0 camera : Camera
var @uniform @set = 2 @binding = 0 query : Camera
var @uniform @set = 2 @binding = 0 pyramid : Pyramid
var @set = 0 @binding = 0 depths : sampler2D
var @ssbo @set = 1 @binding = 0 hiz : array<float>
var @ssbo @set = 1 @binding = 1 predicates : array<uint>
var @ssbo @set = 1 @binding = 0 scan_predicates : array<uint>
var @ssbo @set = 1 @binding = 1 compacted : array<uint>
var @ssbo @set = 1 @binding = 2 commands : array<uint>
var @workgroup scan : uint[1024]
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 3 instance_id : uint
var @out @location = 0 v_color : float3
var @in @location = 0 rgb : float3
var @out @location = 0 color : float4
def center(id : uint) : float3 { return float3((float(id % 32u) - 15.5) * 1.4, (float(id / 32u) - 15.5) * 1.4, 0.0) }
[vertex_shader(name="gdr_vertex")]
def vertex_main { let p = position * 0.5 + center(instance_id); gl_Position = camera.vp * float4(p, 1.0); v_color = float3(0.2, 0.6, 0.9) * (0.3 + 0.7 * max(dot(normal, normalize(float3(-0.4, 0.8, -0.6))), 0.0)) }
[vertex_shader(name="gdr_occluder")]
def occluder_main { let p = position * float3(8.0, 24.0, 0.7) + float3(0.0, 0.0, -6.0); gl_Position = camera.vp * float4(p, 1.0); v_color = float3(0.55, 0.3, 0.16) * (0.3 + 0.7 * max(dot(normal, normalize(float3(-0.4, 0.8, -0.6))), 0.0)) }
[fragment_shader(name="gdr_fragment")]
def fragment_main { color = float4(rgb, 1.0) }
[compute_shader(local_size_x=64, name="gdr_copy"), sdl_shader_access(name="gdr_copy")]
def copy_depth {
 let id = gl_GlobalInvocationID.x; if (id >= 16384u) { return }
 let cell = uint2(id % 128u, id / 128u); let size = pyramid.viewport.xy
 let lo = int2(floor(float2(float(cell.x), float(cell.y)) * size / 128.0)); let hi = int2(ceil(float2(float(cell.x + 1u), float(cell.y + 1u)) * size / 128.0))
 var z = 0.0
 for (y in range(lo.y, hi.y)) { for (x in range(lo.x, hi.x)) { z = max(z, textureLod(depths, (float2(float(x), float(y)) + float2(0.5)) / size, 0.0).x) } }
 hiz[id] = z
}
[compute_shader(local_size_x=64, name="gdr_reduce"), sdl_shader_access(name="gdr_reduce")]
def reduce_depth {
 let id = gl_GlobalInvocationID.x; let width = pyramid.level.x; if (id >= width * width) { return }
 let x = (id % width) * 2u; let y = (id / width) * 2u; let at = pyramid.level.y + y * width * 2u + x
 hiz[pyramid.level.z + id] = max(max(hiz[at], hiz[at + 1u]), max(hiz[at + width * 2u], hiz[at + width * 2u + 1u]))
}
[compute_shader(local_size_x=64, name="gdr_cull"), sdl_shader_access(name="gdr_cull")]
def cull {
 let id = gl_GlobalInvocationID.x; let c = center(id); var lo = float2(1.0); var hi = float2(-1.0); var nearest = 1.0; var safe = true
 for (i in 0..8) { let corner = c + float3((i & 1) != 0 ? 0.5 : -0.5, (i & 2) != 0 ? 0.5 : -0.5, (i & 4) != 0 ? 0.5 : -0.5); let p = query.vp * float4(corner, 1.0)
  if (p.w <= 0.0 || p.z <= 0.0) { safe = false } else { let ndc = p.xyz / p.w; lo = min(lo, ndc.xy); hi = max(hi, ndc.xy); nearest = min(nearest, ndc.z) }
 }
 var visible = true
 if (safe && query.config.z < 0.5) {
  if (hi.x < -1.0 || hi.y < -1.0 || lo.x > 1.0 || lo.y > 1.0 || nearest > 1.0) { visible = false }
  else {
   let low = clamp(float2(lo.x * 0.5 + 0.5, 0.5 - hi.y * 0.5), float2(0.0), float2(1.0)); let high = clamp(float2(hi.x * 0.5 + 0.5, 0.5 - lo.y * 0.5), float2(0.0), float2(1.0))
   var width = 128u; var offset = 0u
   // Select a conservative level whose rectangle covers at most 3x3 cells.
   for (i in 0..7) { if (max((high.x - low.x) * float(width), (high.y - low.y) * float(width)) <= 2.0) { break }; offset += width * width; width /= 2u }
   let p0 = clamp(int2(floor(low * float(width))), int2(0), int2(int(width) - 1)); let p1 = clamp(int2(floor(high * float(width))), int2(0), int2(int(width) - 1))
   var z = 0.0
   for (y in range(p0.y, p1.y + 1)) { for (x in range(p0.x, p1.x + 1)) { z = max(z, hiz[offset + uint(y) * width + uint(x)]) } }
   visible = z + 0.00001 >= nearest
  }
 }
 predicates[id] = visible ? 1u : 0u
}
[compute_shader(local_size_x=512, name="gdr_compact"), sdl_shader_access(name="gdr_compact")]
def compact {
 let a = gl_LocalInvocationID.x * 2u; let b = a + 1u; scan[a] = scan_predicates[a]; scan[b] = scan_predicates[b]; barrier()
 var stride = 1u
 while (stride < 1024u) {
  let va = scan[a] + (a >= stride ? scan[a - stride] : 0u); let vb = scan[b] + (b >= stride ? scan[b - stride] : 0u)
  barrier(); scan[a] = va; scan[b] = vb; barrier(); stride *= 2u
 }
 if (scan_predicates[a] != 0u) { compacted[scan[a] - 1u] = a }; if (scan_predicates[b] != 0u) { compacted[scan[b] - 1u] = b }
 if (a == 0u) { commands[0] = 36u; commands[1] = scan[1023]; commands[2] = 0u; commands[3] = 0u; commands[4] = 0u }
}
