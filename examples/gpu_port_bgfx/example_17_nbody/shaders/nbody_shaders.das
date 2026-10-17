options gen2
// Adapted from bgfx 24-nbody. Copyright 2014 Stanlo Slasinski.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module nbody_shaders shared public
require dassdl3/sdl3_shader_access
require math public
// Four ping-pong buffers, 512 threads and a shared tile, as in bgfx 24-nbody.
var @ssbo @set = 1 @binding = 0 previous : array<float4>
var @ssbo @set = 1 @binding = 1 current : array<float4>
var @ssbo @set = 1 @binding = 2 out_previous : array<float4>
var @ssbo @set = 1 @binding = 3 out_current : array<float4>
var @workgroup tile : float4[512]
struct Simulation { count : uint; shape : uint; seed : uint; pad : uint; params : float4 }
var @uniform @set = 2 @binding = 0 sim : Simulation
// Deterministic integer hash, used only by the initialization dispatch.
def random_value(key : uint) : float {
    var h = key * 747796405u + 2891336453u
    h = ((h >> ((h >> 28u) + 4u)) ^ h) * 277803737u
    return float((h ^ (h >> 22u)) & 0x00ffffffu) / 16777216.0
}
def sphere(id : uint) : float3 {
    let y = random_value(id + sim.seed) * 2.0 - 1.0
    let a = random_value(id * 3u + sim.seed) * 6.2831853
    let radius = sqrt(max(1.0 - y * y, 0.0))
    return float3(cos(a) * radius, y, sin(a) * radius)
}
[compute_shader(local_size_x=512, name="nbody_init"), sdl_shader_access(name="nbody_init")]
def initialize {
    let id = gl_GlobalInvocationID.x
    var p = sphere(id) * 20.0
    if (sim.shape == 1u) { p = float3(random_value(id * 3u), random_value(id * 3u + 1u), random_value(id * 3u + 2u)) * 40.0 - float3(20.0) }
    if (sim.shape == 2u) { let a = random_value(id) * 6.2831853; p = float3(cos(a), 0.0, sin(a)) * 20.0 + sphere(id + 127u) * 3.0 }
    current[id] = float4(p, 0.0); previous[id] = float4(p - sphere(id + 17u) * 0.02, 0.0)
}
[compute_shader(local_size_x=512, name="nbody_update"), sdl_shader_access(name="nbody_update")]
def update {
    let id = gl_GlobalInvocationID.x; let local_id = gl_LocalInvocationID.x
    let p = current[id].xyz; let prev = previous[id].xyz
    var acceleration = float3(0.0)
    for (j in range(0, int(sim.count / 512u))) {
        tile[local_id] = current[uint(j) * 512u + local_id]
        barrier()
        for (i in 0..512) {
            let d = tile[i].xyz - p; let d2 = dot(d, d)
            acceleration += d * (sim.params.x * sim.params.x / (sqrt(d2 * d2 * d2) + 0.1))
        }
        barrier() // Do not overwrite a tile while another invocation still reads it.
    }
    acceleration += (prev - p) * sim.params.y
    let mag = length(acceleration); let color_value = pow(min(mag / 3.0, 1.0), 0.25)
    if (mag > 0.0) { acceleration *= min(mag, sim.params.z) / mag }
    out_previous[id] = float4(p, 0.0)
    out_current[id] = float4(p * 2.0 - prev + acceleration * sim.params.w, color_value)
}
struct Camera { vp : float4x4; right, up : float4 }
var @uniform @set = 1 @binding = 0 camera : Camera
var @in @location = 0 particle : float4
var @out @location = 0 v_uv : float2
var @out @location = 1 v_energy : float
var @in @location = 0 uv : float2
var @in @location = 1 energy : float
var @out @location = 0 color : float4
[vertex_shader(name="nbody_vertex")]
def particle_vs {
    let corners = fixed_array(float2(-1.0, -1.0), float2(1.0, -1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, 1.0), float2(-1.0, 1.0))
    let c = corners[gl_VertexIndex]
    gl_Position = camera.vp * float4(particle.xyz + (camera.right.xyz * c.x + camera.up.xyz * c.y) * 0.2, 1.0)
    v_uv = c; v_energy = particle.w
}
[fragment_shader(name="nbody_fragment")]
def particle_fs {
    let a = max(0.0, 1.0 - dot(uv, uv)); let rgb = lerp(float3(0.12, 0.35, 1.0), float3(1.0, 0.3, 0.05), energy)
    color = float4(rgb * a * a, 1.0)
}
