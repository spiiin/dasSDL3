options gen2
module shadowmap_shaders shared public
// bgfx 15/16, Dario Manesku, BSD-2-Clause (../LICENSE-bgfx.txt).
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4 }
struct ShadowFrame {
    m0, m1, m2, m3 : float4x4
    light, eye, forward, splits, controls, tint : float4
}
struct Filter { step : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 3 @binding = 0 frame : ShadowFrame
var @uniform @set = 3 @binding = 0 filtering : Filter
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 uv : float2
var @out @location = 0 v_world : float3
var @out @location = 1 v_normal : float3
var @out @location = 2 v_uv : float2
var @in @location = 0 world : float3
var @in @location = 1 nrm : float3
var @in @location = 2 texcoord : float2
var @out @location = 0 v_depth : float2
var @in @location = 0 depth_clip : float2
var @out @location = 0 output_color : float4
var @set = 2 @binding = 0 map0 : sampler2D
var @set = 2 @binding = 1 map1 : sampler2D
var @set = 2 @binding = 2 map2 : sampler2D
var @set = 2 @binding = 3 map3 : sampler2D
[vertex_shader(name="shadowmap_vertex")]
def mesh_vs {
    let w = transform.model * float4(position, 1.0)
    gl_Position = transform.vp * w
    v_world = w.xyz; v_normal = (transform.model * float4(normal, 0.0)).xyz; v_uv = uv
}
[vertex_shader(name="shadowmap_depth_vertex")]
def depth_vs {
    gl_Position = transform.vp * transform.model * float4(position, 1.0)
    v_depth = gl_Position.zw
}
[vertex_shader(name="shadowmap_fullscreen")]
def screen_vs {
    let id = gl_VertexIndex
    let uv0 = float2(float((id << 1) & 2), float(id & 2))
    gl_Position = float4(uv0.x * 2.0 - 1.0, 1.0 - uv0.y * 2.0, 0.0, 1.0)
    v_uv = uv0
}
def shadow_depth(z : float) : float {
    if (frame.forward.w < 0.5 || frame.light.w >= 2.0) { return z }
    let near = frame.light.w > 0.5 ? 0.5 : 1.0
    return near / (80.0 - z * (80.0 - near))
}
[fragment_shader(name="shadowmap_depth")]
def depth_fs {
    let d = shadow_depth(depth_clip.x / depth_clip.y)
    output_color = float4(d, d * d, exp(80.0 * (d - 1.0)), 1.0)
}
[fragment_shader(name="shadowmap_blur")]
def blur_fs {
    var value = float4(0.0)
    for (i in -4 .. 5) {
        let weight = exp(-float(i * i) / 8.0)
        value += textureLod(map0, texcoord + float(i) * filtering.step.xy, 0.0) * weight
    }
    output_color = value / 4.8980308
}
def sample_map(index : int; coord : float2) : float4 {
    if (index == 1) { return textureLod(map1, coord, 0.0) }
    if (index == 2) { return textureLod(map2, coord, 0.0) }
    if (index == 3) { return textureLod(map3, coord, 0.0) }
    return textureLod(map0, coord, 0.0)
}
def visibility(index : int; p : float4) : float {
    let ndc = p.xyz / p.w
    let xy = float2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5)
    if (p.w <= 0.0 || xy.x < 0.0 || xy.y < 0.0 || xy.x > 1.0 || xy.y > 1.0 || ndc.z < 0.0 || ndc.z > 1.0) { return 1.0 }
    let receiver_z = shadow_depth(ndc.z)
    let z = receiver_z - frame.controls.y
    // Receiver-plane depth bias: compensate PCF tap offsets on sloped surfaces.
    let dx = dFdx(float3(xy, receiver_z)); let dy = dFdy(float3(xy, receiver_z))
    let determinant = dx.x * dy.y - dx.y * dy.x
    var gradient = float2(0.0)
    if (abs(determinant) > 0.0000000001) { gradient = float2(dy.y * dx.z - dx.y * dy.z, dx.x * dy.z - dy.x * dx.z) / determinant }
    let moments = sample_map(index, xy)
    let mode = int(frame.controls.x)
    if (mode == 0) { return z <= moments.x ? 1.0 : 0.0 }
    if (mode == 3) {
        let variance = max(moments.y - moments.x * moments.x, 0.000002)
        let delta = z - moments.x
        return z <= moments.x ? 1.0 : clamp((variance / (variance + delta * delta) - 0.2) / 0.8, 0.0, 1.0)
    }
    if (mode == 4) { return clamp(moments.z * exp(80.0 * (1.0 - z)), 0.0, 1.0) }
    var radius = 1.0
    if (mode == 2) {
        var blockers = 0.0; var sum = 0.0
        for (y in -2 .. 3) { for (x in -2 .. 3) {
            let d = sample_map(index, xy + float2(float(x), float(y)) * frame.controls.z * 3.0).x
            if (d < z) { sum += d; blockers += 1.0 }
        } }
        if (blockers == 0.0) { return 1.0 }
        let average = sum / blockers
        radius = clamp((z - average) / max(average, 0.001) * 100.0, 1.0, 10.0)
    }
    var result = 0.0
    for (y in 0 .. 4) { for (x in 0 .. 4) {
        let coord = xy + (float2(float(x), float(y)) - float2(1.5)) * frame.controls.z * radius
        result += z + dot(gradient, coord - xy) <= sample_map(index, coord).x ? 1.0 : 0.0
    } }
    return result / 16.0
}
[fragment_shader(name="shadowmap_lighting")]
def light_fs {
    let kind = int(frame.light.w)
    var index = 0
    if (kind == 2) {
        let d = dot(world - frame.eye.xyz, frame.forward.xyz)
        index = d > frame.splits.x ? 1 : 0
        if (d > frame.splits.y) { index = 2 }
        if (d > frame.splits.z) { index = 3 }
    }
    if (kind == 1) {
        let d = world - frame.light.xyz
        let sides = float4(dot(d, float3(1.0, 1.0, 1.0)), dot(d, float3(-1.0, -1.0, 1.0)), dot(d, float3(-1.0, 1.0, -1.0)), dot(d, float3(1.0, -1.0, -1.0)))
        var best = sides.x
        if (sides.y > best) { best = sides.y; index = 1 }
        if (sides.z > best) { best = sides.z; index = 2 }
        if (sides.w > best) { index = 3 }
    }
    var p = frame.m0 * float4(world, 1.0)
    if (index == 1) { p = frame.m1 * float4(world, 1.0) }
    if (index == 2) { p = frame.m2 * float4(world, 1.0) }
    if (index == 3) { p = frame.m3 * float4(world, 1.0) }
    var vis = frame.controls.w > 0.5 ? visibility(index, p) : 1.0
    if (kind == 0) { vis *= smoothstep(0.7071068, 0.8660254, dot(normalize(-frame.light.xyz), normalize(world - frame.light.xyz))) }
    let n = normalize(nrm)
    let l = normalize(frame.light.xyz - (kind == 2 || kind == 3 ? float3(0.0) : world))
    let v = normalize(frame.eye.xyz - world)
    let diffuse = max(dot(n, l), 0.0)
    let spec = pow(max(dot(reflect(-l, n), v), 0.0), 32.0)
    let checker = mod(floor(world.x * 0.5) + floor(world.z * 0.5), 2.0)
    let albedo = frame.tint.xyz * (frame.tint.w > 0.5 ? 0.65 + checker * 0.25 : 1.0)
    output_color = float4(pow(max(albedo * (0.12 + vis * diffuse) + float3(vis * spec * 0.15), float3(0.0)), float3(1.0 / 2.2)), 1.0)
}
[fragment_shader(name="shadowmap_debug")]
def debug_fs {
    let value = textureLod(map0, texcoord, 0.0).x
    output_color = float4(value, value, value, 1.0)
}
