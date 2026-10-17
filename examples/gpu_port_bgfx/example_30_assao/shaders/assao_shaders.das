// Adapted from bgfx 39-assao. Copyright 2018 Attila Kocsis.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module assao_shaders shared public
require dassdl3/sdl3_shader_access
require math public

struct Transform { model, view, vp : float4x4; material : float4 }
struct Config { size : uint4; params : float4; quality : float4; tuning : float4; controls : float4; lighting, appearance, camera, effect, temporal : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @uniform @set = 2 @binding = 0 config : Config
var @uniform @set = 3 @binding = 0 display : Config
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @out @location = 0 v_position : float3
var @out @location = 1 v_normal : float3
var @in @location = 0 point : float3
var @in @location = 1 nrm : float3
var @out @location = 0 out_position : float4
var @out @location = 1 out_normal : float4
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
var @set = 0 @binding = 0 positions_tex : sampler2D
var @set = 0 @binding = 1 normals_tex : sampler2D
// Per-entry-point aliases keep SDL storage bindings dense.
var @ssbo @set = 1 @binding = 0 points : array<float4>
var @ssbo @set = 1 @binding = 1 normals : array<float4>
var @ssbo @set = 1 @binding = 2 importance : array<float>
var @ssbo @set = 1 @binding = 3 ao : array<float4>
var @ssbo @set = 1 @binding = 4 depths : array<float>
var @ssbo @set = 1 @binding = 5 base : array<float4>
var @ssbo @set = 1 @binding = 6 counter : array<uint>
var @ssbo @set = 1 @binding = 1 mip_depths : array<float>
var @ssbo @set = 1 @binding = 0 ao_input : array<float4>
var @ssbo @set = 1 @binding = 1 ao_output : array<float4>
var @ssbo @set = 1 @binding = 1 importance_output : array<float>
var @ssbo @set = 1 @binding = 0 importance_input : array<float>
var @ssbo @set = 1 @binding = 2 load_counter : array<uint>
var @ssbo @set = 1 @binding = 0 clear_counter : array<uint>
var @ssbo @set = 1 @binding = 1 applied : array<float>
var @set = 2 @binding = 0 normal_image : sampler2D
var @set = 2 @binding = 1 albedo_image : sampler2D
var @ssbo @readonly @set = 2 @binding = 2 final_ao : array<float>
var @in @location = 2 texcoord : float2
var @out @location = 2 v_material : float3
var @in @location = 2 surface_material : float3
var @out @location = 2 out_albedo : float4
var @set = 2 @binding = 0 ground_image : sampler2D
[vertex_shader(name="assao_geometry")]
def geometry { v_material = float3(texcoord * 16.0, transform.material.x); let p = transform.model * float4(position, 1.0); gl_Position = transform.vp * p; v_position = (transform.view * p).xyz; v_normal = normalize((transform.view * transform.model * float4(normal, 0.0)).xyz) }
[fragment_shader(name="assao_gbuffer")]
def gbuffer { out_position = float4(point, 1.0); out_normal = float4(normalize(nrm), 1.0); out_albedo = surface_material.z > 0.5 ? texture(ground_image, surface_material.xy) : float4(192.0 / 255.0) }
def half_coord(id : uint) : uint2 { let area = config.size.z * config.size.w; let local = id % area; return uint2(local % config.size.z, local / config.size.z) }
[compute_shader(local_size_x=64, name="assao_prepare"), sdl_shader_access(name="assao_prepare")]
def prepare {
 let id = gl_GlobalInvocationID.x; let area = config.size.z * config.size.w; if (id >= area * 4u) { return }
 let q = half_coord(id); let layer = id / area; let p = q * 2u + uint2(layer % 2u, layer / 2u)
 if (p.x >= config.size.x || p.y >= config.size.y) { points[id] = float4(0.0); normals[id] = float4(0.0); return }
 let tc = (float2(float(p.x), float(p.y)) + float2(0.5)) / float2(float(config.size.x), float(config.size.y))
 points[id] = textureLod(positions_tex, tc, 0.0); normals[id] = textureLod(normals_tex, tc, 0.0)
 if (config.controls.x > 0.5 && points[id].w > 0.5) {
  let center = points[id].xyz; let step = 1.0 / float2(config.size.xy)
  let lp = textureLod(positions_tex, tc - float2(step.x, 0.0), 0.0).xyz
  let rp = textureLod(positions_tex, tc + float2(step.x, 0.0), 0.0).xyz
  let tp = textureLod(positions_tex, tc - float2(0.0, step.y), 0.0).xyz
  let bp = textureLod(positions_tex, tc + float2(0.0, step.y), 0.0).xyz
  let dz = float4(lp.z, rp.z, tp.z, bp.z) - float4(center.z)
  let e = clamp(float4(1.3) - min(abs(dz), abs(dz + dz.yxwz)) / max(center.z * 0.04, 0.0001), float4(0.0), float4(1.0))
  let l = (lp - center) / max(length(lp - center), 0.00001); let rr = (rp - center) / max(length(rp - center), 0.00001)
  let t = (tp - center) / max(length(tp - center), 0.00001); let b = (bp - center) / max(length(bp - center), 0.00001)
  normals[id] = float4(normalize(float3(0.0, 0.0, -0.0005) + cross(l, t) * e.x * e.z + cross(t, rr) * e.z * e.y + cross(rr, b) * e.y * e.w + cross(b, l) * e.w * e.x), 1.0)
 }
}

def mip_size(level : uint) : uint2 { return max(uint2(config.size.z, config.size.w) >> int(level), uint2(1u)) }
def mip_offset(level : uint) : uint { var offset = 0u; for (i in range(0, int(level))) { let d = mip_size(uint(i)); offset += d.x * d.y * 4u }; return offset }
def quarter_size() : uint2 { return (uint2(config.size.z, config.size.w) + uint2(1u)) / 2u }
def half_index(q : int2; layer : uint) : uint {
 let at = clamp(q, int2(0), int2(int(config.size.z) - 1, int(config.size.w) - 1))
 return layer * config.size.z * config.size.w + uint(at.y) * config.size.z + uint(at.x)
}
def radius_at(distance : float) : float {
 let near_limit = config.params.x * 1.2 / config.camera.y * (config.quality.x <= 0.0 ? 1.5 : 1.0)
 return config.params.x * (config.quality.x < 0.0 ? 0.8 : 1.0) * (clamp(distance / near_limit, 0.0, 1.0) * 0.8 + 0.2)
}
// Four parity layers, then three edge-aware depth mip levels.
[compute_shader(local_size_x=64, name="assao_depth_mip"), sdl_shader_access(name="assao_depth_mip")]
def depth_mip {
 let id = gl_GlobalInvocationID.x; let level = uint(config.quality.w); let dims = mip_size(level); let area = dims.x * dims.y
 if (id >= area * 4u) { return }
 if (level == 0u) { mip_depths[id] = points[id].w > 0.5 ? points[id].z : 10000.0; return }
 let src = mip_size(level - 1u); let layer = id / area; let q = uint2(id % dims.x, (id % area) / dims.x) * 2u
 var values = float4(0.0)
 for (ii in range(0, 4)) { let i = uint(ii); let at = min(q + uint2(i % 2u, i / 2u), src - uint2(1u)); values[int(i)] = mip_depths[mip_offset(level - 1u) + layer * src.x * src.y + at.y * src.x + at.x] }
 let closest = min(min(values.x, values.y), min(values.z, values.w)); let radius = radius_at(abs(closest))
 let delta = values - float4(closest); let weights = clamp(float4(1.0) - delta * delta / (radius * radius), float4(0.0), float4(1.0))
 mip_depths[mip_offset(level) + id] = dot(weights, values) / dot(weights, float4(1.0))
}
def pack_edges(edges : float4) : float {
 let v = uint4(round(clamp(edges, float4(0.0), float4(1.0)) * 3.05))
 return float((v.x << 6u) | (v.y << 4u) | (v.z << 2u) | v.w) / 255.0
}
def unpack_edges(packed : float) : float4 {
 let v = uint(packed * 255.5)
 return clamp(float4(float((v >> 6u) & 3u), float((v >> 4u) & 3u), float((v >> 2u) & 3u), float(v & 3u)) / 3.0 + float4(config.tuning.y), float4(0.0), float4(1.0))
}
def obscurance(n, delta : float3; radius : float) : float {
 let d2 = dot(delta, delta)
 return max(dot(n, delta) / sqrt(max(d2, 0.000001)) - config.effect.z, 0.0) * max(1.0 - d2 / (radius * radius), 0.0)
}
def sample_importance(tc : float2) : float {
 let dims = quarter_size(); let p = tc * float2(dims) - float2(0.5); let at = int2(floor(p)); let f = fract(p); var result = 0.0
 for (i in 0..4) { let d = int2(i % 2, i / 2); let q = clamp(at + d, int2(0), int2(dims) - int2(1)); let w = (d.x == 0 ? 1.0 - f.x : f.x) * (d.y == 0 ? 1.0 - f.y : f.y); result += importance[uint(q.y) * dims.x + uint(q.x)] * w }; return result
}
[compute_shader(local_size_x=64, name="assao_generate"), sdl_shader_access(name="assao_generate")]
def generate {
 let id = gl_GlobalInvocationID.x; let area = config.size.z * config.size.w; if (id >= area * 4u) { return }
 let layer = id / area; let q = half_coord(id); let p = points[id]; let quality = int(config.quality.x); let adaptive_base = config.params.w == 1.0
 if (p.w < 0.5 || (quality < 0 && layer != 0u && layer != 3u)) { ao[id] = float4(adaptive_base ? 0.0 : 1.0, 1.0, 0.0, 0.0); return }
 let n = normals[id].xyz; let radius = radius_at(length(p.xyz)); let center = p.xyz * 0.9992
 let projected = 0.85 * radius / (p.z * 4.0 * config.camera.y / float(config.size.y))
 let sp = fixed_array(0, 1, 4, 3, 2); let b = float(sp[int((q.x + q.y * 2u) % 5u)]); let angle = (float(layer) + b / 5.0) * 1.570796327 + config.temporal.x
 let scale = 1.0 + (float(layer) - 1.5 + (b - 2.0) / 5.0) * 0.07
 let cs = cos(angle) * scale * config.temporal.y; let sn = sin(angle) * scale * config.temporal.y
 var edges = float4(1.0); var detail = 0.0; var dz = float4(0.0)
 for (i in 0..4) {
  let d = i < 2 ? int2(i == 0 ? -1 : 1, 0) : int2(0, i == 2 ? -1 : 1)
  let j = half_index(int2(q) + d, layer); dz[i] = points[j].z - p.z
 }
 if (quality >= 1 && !adaptive_base) {
  edges = clamp(float4(1.3) - min(abs(dz), abs(dz + dz.yxwz)) / max(p.z * 0.04, 0.0001), float4(0.0), float4(1.0))
  for (i in 0..4) {
   let d = i < 2 ? int2(i == 0 ? -1 : 1, 0) : int2(0, i == 2 ? -1 : 1); let j = half_index(int2(q) + d, layer)
   detail += obscurance(n, points[j].xyz - center, radius * 0.5) * edges[i] * config.tuning.x
   if (quality >= 2) { edges[i] *= clamp(dot(n, normals[j].xyz) + 0.5, 0.0, 1.0) }
  }
 }
 var taps = quality <= 0 ? 3 : (quality == 1 ? 5 : 12); var first = 0; var total = detail; var weights = 0.0; var additional = 0.0
 if (adaptive_base) { taps = 5; total = 0.0 }
 if (quality == 3 && !adaptive_base) {
  let tc = (float2(q) + float2(0.5)) / float2(config.size.zw); var imp = sample_importance(tc)
  total *= 5.0 / 32.0 + imp * 27.0 / 32.0
  let dims = quarter_size(); let average = float(counter[0]) * 9.0 / (float(dims.x * dims.y) * 255.0)
  imp *= clamp(config.quality.z / max(average, 0.00001), 0.0, 1.0)
  additional = 27.0 * imp + 0.5; taps = min(32, 5 + int(additional)); first = 5
  weights = base[id].z * 20.0; total += base[id].x * weights
 }
 let pattern = fixed_array(float4(0.78488064, 0.56661671, 1.500000, -0.126083), float4(0.26022232, -0.29575172, 1.500000, -1.064030), float4(0.10459357, 0.08372527, 1.110000, -2.730563), float4(-0.68286800, 0.04963045, 1.090000, -0.498827), float4(-0.13570161, -0.64190155, 1.250000, -0.532765), float4(-0.26193795, -0.08205118, 0.670000, -1.783245), float4(-0.61177456, 0.66664219, 0.710000, -0.044234), float4(0.43675563, 0.25119025, 0.610000, -1.167283), float4(0.07884444, 0.86618668, 0.640000, -0.459002), float4(-0.12790935, -0.29869005, 0.600000, -1.729424), float4(-0.04031125, 0.02413622, 0.600000, -4.792042), float4(0.16201244, -0.52851415, 0.790000, -1.067055), float4(-0.70991218, 0.47301072, 0.640000, -0.335236), float4(0.03277707, -0.22349690, 0.600000, -1.982384), float4(0.68921727, 0.36800742, 0.630000, -0.266718), float4(0.29251814, 0.37775412, 0.610000, -1.422520), float4(-0.12224089, 0.96582592, 0.600000, -0.426142), float4(0.11071457, -0.16131058, 0.600000, -2.165947), float4(0.46562141, -0.59747696, 0.600000, -0.189760), float4(-0.51548797, 0.11804193, 0.600000, -1.246800), float4(0.89141309, -0.42090443, 0.600000, 0.028192), float4(-0.32402530, -0.01591529, 0.600000, -1.543018), float4(0.60771245, 0.41635221, 0.600000, -0.605411), float4(0.02379565, -0.08239821, 0.600000, -3.809046), float4(0.48951152, -0.23657045, 0.600000, -1.189011), float4(-0.17611565, -0.81696892, 0.600000, -0.513724), float4(-0.33930185, -0.20732205, 0.600000, -1.698047), float4(-0.91974425, 0.05403209, 0.600000, 0.062246), float4(-0.15064627, -0.14949332, 0.600000, -1.896062), float4(0.53180975, -0.35210401, 0.600000, -0.758838), float4(0.41487166, 0.81442589, 0.600000, -0.505648), float4(-0.24106961, -0.32721516, 0.600000, -1.665244))
 for (i in 0..32) { if (i < first) { continue }; if (i >= taps) { break }
  let sample = pattern[i]; let off = float2(sample.x * cs - sample.y * sn, -sample.x * sn - sample.y * cs) * projected
  var weight_mod = 1.0; if (quality == 3 && !adaptive_base) { additional -= 1.0; weight_mod = clamp(additional / 3.0, 0.0, 1.0) }
  for (sign in 0..2) {
   let delta = int2(round(off * (sign == 0 ? 1.0 : -1.0))); let at = clamp(int2(q) + delta, int2(0), int2(config.size.zw) - int2(1))
   var target = points[half_index(at, layer)]
   if (quality >= 2) {
    let level = uint(clamp(floor(sample.w + log2(max(projected, 0.001)) - 4.3 + 0.5), 0.0, 3.0)); let dims = mip_size(level); let mc = min(uint2(at) >> int(level), dims - uint2(1u))
    let z = depths[mip_offset(level) + layer * dims.x * dims.y + mc.y * dims.x + mc.x]
    let pixel = float2(at * 2 + int2(int(layer % 2u), int(layer / 2u))) + float2(0.5); let tc = pixel / float2(config.size.xy)
    target = float4((tc.x * 2.0 - 1.0) * config.camera.x * z, (1.0 - tc.y * 2.0) * config.camera.y * z, z, 1.0)
   }
   let v = target.xyz - center; var weight = sample.z * weight_mod
   if (quality >= 1) { weight *= 0.6 * clamp(v.z / radius + 2.0, 0.0, 1.0) + 0.4 }
   total += obscurance(n, v, radius) * weight; weights += weight
  }
 }
 if (adaptive_base) { ao[id] = float4(total / max(weights, 0.00001), 1.0, weights / 20.0, 5.0); return }
 let edge_fade = clamp((1.0 - edges.x - edges.y) * 0.35, 0.0, 1.0) + clamp((1.0 - edges.z - edges.w) * 0.35, 0.0, 1.0)
 let fade = clamp((config.tuning.w - p.z) / (config.tuning.w - config.tuning.z), 0.0, 1.0) * (quality >= 1 ? clamp(1.0 - edge_fade, 0.0, 1.0) : 1.0)
 let value = pow(clamp(1.0 - min(config.params.y * total / max(weights, 0.00001), config.effect.y) * fade, 0.0, 1.0), config.effect.x)
 ao[id] = float4(value, pack_edges(edges), weights, float(taps))
}
[compute_shader(local_size_x=64, name="assao_importance"), sdl_shader_access(name="assao_importance")]
def importance_map {
 let id = gl_GlobalInvocationID.x; let dims = quarter_size(); if (id >= dims.x * dims.y) { return }
 let q = int2(int(id % dims.x), int(id / dims.x)) * 2; var lo = 1.0; var hi = 0.0
 for (li in range(0, 4)) { let layer = uint(li); for (i in 0..4) {
  let value = pow(clamp(1.0 - config.params.y * ao_input[half_index(q + int2(i % 2, i / 2), layer)].x, 0.0, 1.0), config.effect.x)
  lo = min(lo, value); hi = max(hi, value)
 } }; importance_output[id] = pow(clamp((hi - lo) * 2.0, 0.0, 1.0), 0.8)
}
def importance_at(p : float2) : float {
 let dims = quarter_size(); let at = int2(floor(p)); let f = fract(p); var result = 0.0
 for (i in 0..4) { let d = int2(i % 2, i / 2); let q = clamp(at + d, int2(0), int2(dims) - int2(1)); result += importance_input[uint(q.y) * dims.x + uint(q.x)] * (d.x == 0 ? 1.0 - f.x : f.x) * (d.y == 0 ? 1.0 - f.y : f.y) }; return result
}
[compute_shader(local_size_x=64, name="assao_importance_smooth"), sdl_shader_access(name="assao_importance_smooth")]
def importance_smooth {
 let id = gl_GlobalInvocationID.x; let dims = quarter_size(); if (id >= dims.x * dims.y) { return }; let q = uint2(id % dims.x, id / dims.x)
 let offsets = fixed_array(float2(-1.5, -0.5), float2(0.5, -1.5), float2(1.5, 0.5), float2(-0.5, 1.5)); var sum = 0.0
 for (i in 0..4) { let d = offsets[i]; sum += importance_at(float2(q) + (config.quality.w > 0.5 ? d.yx : d)) }; let value = clamp(sum * 0.25, 0.0, 1.0); importance_output[id] = value
 if (config.quality.w > 0.5 && q.x % 3u == 0u && q.y % 3u == 0u) { atomicAdd(load_counter[0], uint(value * 255.0 + 0.5)) }
}
[compute_shader(local_size_x=64, name="assao_clear_counter"), sdl_shader_access(name="assao_clear_counter")]
def clear_load_counter { if (gl_GlobalInvocationID.x == 0u) { clear_counter[0] = 0u } }
def sample_ao(p : float2; layer : uint) : float {
 let at = int2(floor(p)); let f = fract(p); var result = 0.0
 for (i in 0..4) { let d = int2(i % 2, i / 2); result += ao_input[half_index(at + d, layer)].x * (d.x == 0 ? 1.0 - f.x : f.x) * (d.y == 0 ? 1.0 - f.y : f.y) }; return result
}
[compute_shader(local_size_x=64, name="assao_blur"), sdl_shader_access(name="assao_blur")]
def blur {
 let id = gl_GlobalInvocationID.x; let area = config.size.z * config.size.w; if (id >= area * 4u) { return }; let q = half_coord(id); let layer = id / area; let center = ao_input[id]; var sum = 0.0; var weight = 0.0
 if (config.quality.x <= 0.0) {
  let offsets = fixed_array(float2(-1.5, -0.5), float2(0.5, -1.5), float2(-0.5, 1.5), float2(1.5, 0.5)); sum = center.x; weight = 5.0
  for (i in 0..4) { sum += sample_ao(float2(q) + offsets[i], layer) }
 } else {
  let wide = config.quality.y > 1.5; weight = wide ? 0.8 : 0.5; sum = center.x * weight; let edges = unpack_edges(center.y)
  for (i in 0..4) { let d = (i < 2 ? int2(i == 0 ? -1 : 1, 0) : int2(0, i == 2 ? -1 : 1)) * (wide ? 2 : 1); let neighbor = ao_input[half_index(int2(q) + d, layer)]
   var w = edges[i]; if (wide) { let e = unpack_edges(neighbor.y); w *= e[i ^ 1] }; sum += neighbor.x * w; weight += w
  }
 }; ao_output[id] = float4(clamp(sum / weight, 0.0, 1.0), center.yzw)
}
// Edge-aware four-layer reconstruction, with separate Low and Lowest paths.
[compute_shader(local_size_x=64, name="assao_apply"), sdl_shader_access(name="assao_apply")]
def apply {
 let id = gl_GlobalInvocationID.x; if (id >= config.size.x * config.size.y) { return }; let p = uint2(id % config.size.x, id / config.size.x); let mx = p.x % 2u; let my = p.y % 2u; let layer = mx + my * 2u
 var value = 0.0
 if (config.quality.x <= 0.0) {
  let q = (float2(p) + float2(0.5)) / float2(config.size.xy) * float2(config.size.zw) - float2(0.5)
  if (config.quality.x < 0.0) { value = (sample_ao(q, 0u) + sample_ao(q, 3u)) * 0.5 }
  else { for (ii in range(0, 4)) { let i = uint(ii); value += sample_ao(q, i) * 0.25 } }
 } else {
  let center = ao_input[half_index(int2(p / 2u), layer)]; let e = unpack_edges(center.y); let dx = e.y - e.x; let dy = e.w - e.z
  let h = (float2(p) + float2(float(mx) + dx - 0.5, 0.5 - float(my))) * 0.5 - float2(0.5)
  let v = (float2(p) + float2(0.5 - float(mx), float(my) - 0.5 + dy)) * 0.5 - float2(0.5)
  let d = (float2(p) + float2(float(mx) - 0.5 + dx, float(my) - 0.5 + dy)) * 0.5 - float2(0.5)
  let wh = (e.x + e.y) * 0.5; let wv = (e.z + e.w) * 0.5; let wd = (wh + wv) * 0.5
  value = (center.x + sample_ao(h, (1u - mx) + my * 2u) * wh + sample_ao(v, mx + (1u - my) * 2u) * wv + sample_ao(d, (1u - mx) + (1u - my) * 2u) * wd) / (1.0 + wh + wv + wd)
 }; applied[id] = pow(clamp(value, 0.0, 1.0), 1.0 / 2.2)
}
[vertex_shader(name="assao_screen")]
def screen { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); v_uv = t; gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0) }
[fragment_shader(name="assao_combine"), sdl_shader_access(name="assao_combine")]
def combine {
 let p = uint2(uint(gl_FragCoord.x), uint(gl_FragCoord.y)) + uint2(uint(display.camera.z));
 let tc = (uv * (float2(display.size.xy) - float2(display.camera.z * 2.0)) + float2(display.camera.z)) / float2(display.size.xy); let layer = (p.x % 2u) + (p.y % 2u) * 2u; let id = p.y * display.size.x + p.x
 let occlusion = display.params.z > 0.5 && display.params.z < 1.5 ? 1.0 : final_ao[id]
 let n = texture(normal_image, tc); if (n.w < 0.5) { color = float4(0.0, 0.0, 0.0, 1.0); return }
 let lit = 0.3 + 1.2 * max(dot(n.xyz, display.lighting.xyz), 0.0)
 var rgb = texture(albedo_image, tc).xyz * lit * occlusion
 if (display.appearance.x < 0.5) { rgb = float3(occlusion) }
 if (display.params.z > 1.5 && display.params.z < 2.5) { rgb = float3(occlusion) }
 color = float4(rgb, 1.0)
}
