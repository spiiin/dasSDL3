// Adapted from bgfx 41-tess. Copyright 2019 Daniel Gavin. BSD-2-Clause.
// Based on implicit subdivision by Jad Khoury, Jonathan Dupuy and Christophe Riccio.
options gen2
module tess_shaders shared public
require dassdl3/sdl3_shader_access
require math public
struct Config { vp : float4x4; eye, settings, flags : float4 }
var @uniform @set = 2 @binding = 0 config : Config
var @uniform @set = 1 @binding = 0 camera : Config
var @uniform @set = 3 @binding = 0 shading : Config
var @set = 0 @binding = 0 heights : sampler2D
var @set = 2 @binding = 0 slopes : sampler2D
var @ssbo @readonly @set = 0 @binding = 1 nodes_in : array<uint2>
var @ssbo @set = 1 @binding = 0 nodes_out : array<uint2>
var @ssbo @set = 1 @binding = 1 visible : array<uint2>
var @ssbo @set = 1 @binding = 2 counts : array<uint>
var @ssbo @set = 1 @binding = 0 reset_counts : array<uint>
var @ssbo @set = 1 @binding = 1 dispatch_args : array<uint>
var @in @location = 0 barycentric : float2
var @in @location = 1 node : uint2
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
struct Triangle { a, b, c : float2 }
def level(key : uint) : uint { var k = key; var n = 0u; while (k > 1u) { k = k >> 1u; n++ }; return n }
def triangle(primitive, key : uint) : Triangle {
    var t = Triangle(a = float2(-1.0, -1.0), b = float2(1.0, -1.0), c = float2(-1.0, 1.0)); if (primitive != 0u) { t = Triangle(a = float2(1.0, 1.0), b = float2(-1.0, 1.0), c = float2(1.0, -1.0)) }
    var bit = int(level(key)) - 1
    while (bit >= 0) { let midpoint = (t.b + t.c) * 0.5; if (((key >> uint(bit)) & 1u) == 0u) { t.b = t.a } else { t.c = t.a }; t.a = midpoint; bit-- }
    return t
}
def world(p : float2; height : float) : float3 { return float3(p.x, height, -p.y) }
def height_at(p : float2) : float { return textureLod(heights, p * 0.5 + float2(0.5), 0.0).x * 0.45 }
def lod(t : Triangle) : uint { let p = (t.b + t.c) * 0.5; let z = length(world(p, height_at(config.eye.xy)) - config.eye.xyz); return uint(clamp(-2.0 * log2(max(z * config.settings.x, 0.000001)), 0.0, 19.0)) }
def write_node(p, k : uint) { let i = atomicAdd(counts[0], 1u); if (i < 1048576u) { nodes_out[i] = uint2(p, k) } }
[compute_shader(local_size_x=32, name="tess_lod"), sdl_shader_access(name="tess_lod")]
def update {
    let id = gl_GlobalInvocationID.x; if (id >= counts[2]) { return }
    let n = nodes_in[id]; let t = triangle(n.x, n.y); let depth = level(n.y)
    let target = config.flags.x > 0.5 ? depth : lod(t); let parent = config.flags.x > 0.5 ? depth : lod(triangle(n.x, n.y >> 1u))
    if (depth < target && depth < 19u) { write_node(n.x, n.y << 1u); write_node(n.x, (n.y << 1u) | 1u) }
    elif (depth < parent + 1u) { write_node(n.x, n.y) } elif (n.y == 1u) { write_node(n.x, 1u) } elif ((n.y & 1u) == 0u) { write_node(n.x, n.y >> 1u) }
    let lo = min(t.a, min(t.b, t.c)); let hi = max(t.a, max(t.b, t.c))
    var left = true; var right = true; var bottom = true; var top = true; var near = true; var far = true
    for (i in range(8)) { let p = config.vp * float4(world(float2((i & 1) == 0 ? lo.x : hi.x, (i & 2) == 0 ? lo.y : hi.y), (i & 4) == 0 ? 0.0 : 0.45), 1.0)
        left = left && p.x < -p.w; right = right && p.x > p.w; bottom = bottom && p.y < -p.w; top = top && p.y > p.w; near = near && p.z < 0.0; far = far && p.z > p.w
    }
    if (config.flags.y < 0.5 || !(left || right || bottom || top || near || far)) { let i = atomicAdd(counts[1], 1u); if (i < 1048576u) { visible[i] = n } }
}
// First 3 words are counters; words 3..7 indexed draw; 8..10 next dispatch.
[compute_shader(local_size_x=1, name="tess_commands"), sdl_shader_access(name="tess_commands")]
def commands { let n = min(reset_counts[0], 1048576u); let count = min(reset_counts[1], 1048576u); reset_counts[2] = n; reset_counts[0] = 0u; reset_counts[1] = 0u; reset_counts[3] = uint(config.settings.y); reset_counts[4] = count; reset_counts[5] = 0u; reset_counts[6] = 0u; reset_counts[7] = 0u; dispatch_args[0] = n / 32u + 1u; dispatch_args[1] = 1u; dispatch_args[2] = 1u }
[vertex_shader(name="tess_vertex")]
def vertex { let t = triangle(node.x, node.y); let p = t.a + barycentric.x * (t.b - t.a) + barycentric.y * (t.c - t.a); gl_Position = camera.vp * float4(world(p, height_at(p)), 1.0); v_uv = p * 0.5 + float2(0.5) }
[fragment_shader(name="tess_fragment")]
def fragment { let dx = float2(1.0 / 4096.0, 0.0); let dy = dx.yx; let s = float2(texture(slopes, uv + dx).x - texture(slopes, uv - dx).x, texture(slopes, uv + dy).x - texture(slopes, uv - dy).x) * (2048.0 * 0.45); let n = normalize(float3(-s, 1.0)); color = float4(shading.flags.z > 0.5 ? n * 0.5 + float3(0.5) : float3(clamp(n.z, 0.0, 1.0) / 3.14159), 1.0) }
