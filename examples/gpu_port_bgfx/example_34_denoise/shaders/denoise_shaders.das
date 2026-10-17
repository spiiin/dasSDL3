// Port of bgfx 43-denoise. Copyright 2021 elven cache. BSD-2-Clause.
options gen2
module denoise_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Config { size, noise, spatial, temporal : float4 }
var @uniform @set = 3 @binding = 0 config : Config
var @set = 2 @binding = 0 image0 : sampler2D
var @set = 2 @binding = 1 image1 : sampler2D
var @set = 2 @binding = 2 image2 : sampler2D
var @set = 2 @binding = 3 image3 : sampler2D
var @set = 2 @binding = 4 image4 : sampler2D
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
[vertex_shader(name="denoise_screen")]
def screen { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); v_uv = t; gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0) }
[fragment_shader(name="denoise_noisy")]
def noisy {
    let n = normalize(texture(image0, uv).xyz); let ndl = max(dot(n, normalize(float3(-0.2, 1.0, -0.2))), 0.0)
    var mask = 1.0
    if (config.noise.x > 1.5) { mask = fract(sin(dot(gl_FragCoord.xy + float2(314.0, 159.0) * config.size.z, float2(12.9898, 78.233))) * 43758.5453123) > 0.5 ? 1.0 : 0.0 }
    elif (config.noise.x > 0.5) { let p = int2(gl_FragCoord.xy); mask = ((p.x & 1) + ((p.y & 1) << 1)) == int(config.size.z) % 4 ? 1.0 : 0.0 }
    color = float4(float3((0.99 * ndl + 0.01 + 5.0 * pow(ndl, 513.0)) * mask), 1.0)
}
[fragment_shader(name="denoise_temporal")]
def history {
    let current = texture(image0, uv); let n = texture(image1, uv).xyz
    let prev = uv - texture(image2, uv).xy
    let px = prev * config.size.xy - float2(0.5); let base = floor(px); let f = fract(px)
    var sum = float3(0.0); var total = 0.0
    for (y in range(2)) { for (x in range(2)) {
        let tc = (base + float2(float(x), float(y)) + float2(0.5)) / config.size.xy
        let weight = (x == 0 ? 1.0 - f.x : f.x) * (y == 0 ? 1.0 - f.y : f.y)
        if (tc.x >= 0.0 && tc.y >= 0.0 && tc.x <= 1.0 && tc.y <= 1.0 && dot(n, textureLod(image4, tc, 0.0).xyz) >= 0.70710678) { sum += textureLod(image3, tc, 0.0).xyz * weight; total += weight }
    } }
    color = float4(total > 0.0 ? lerp(current.xyz, sum / max(total, 0.00001), 0.8) : current.xyz, 1.0)
}
def kernel(i : int; radius : int) : float { let a = abs(i); return radius == 1 ? (a == 0 ? 2.0 : 1.0) : (a == 0 ? 6.0 : a == 1 ? 4.0 : 1.0) }
[fragment_shader(name="denoise_spatial")]
def spatial {
    let n = texture(image1, uv).xyz; let z = texture(image2, uv).x; let radius = int(config.spatial.w)
    var sum = float3(0.0); var total = 0.0
    for (y in range(-radius, radius + 1)) { for (x in range(-radius, radius + 1)) {
        let tc = uv + float2(float(x), float(y)) * config.spatial.z / config.size.xy
        let w = kernel(x, radius) * kernel(y, radius) * pow(clamp(dot(n, textureLod(image1, tc, 0.0).xyz), 0.0, 1.0), config.spatial.y) * exp(-abs(z - textureLod(image2, tc, 0.0).x) / max(0.00001, config.spatial.x * config.spatial.x))
        sum += textureLod(image0, tc, 0.0).xyz * w; total += w
    } }
    color = float4(sum / max(total, 0.00001), 1.0)
}
[fragment_shader(name="denoise_apply")]
def apply { color = float4(pow(max(texture(image0, uv).xyz * pow(texture(image1, uv).xyz, float3(2.2)), float3(0.0)), float3(1.0 / 2.2)), 1.0) }
[fragment_shader(name="denoise_copy")]
def copy { color = texture(image0, uv) }
def mitchell(x : float; b, c : float) : float {
    if (x < 1.0) { return ((12.0 - 9.0 * b - 6.0 * c) * x * x * x + (-18.0 + 12.0 * b + 6.0 * c) * x * x + 6.0 - 2.0 * b) / 6.0 }
    return ((-b - 6.0 * c) * x * x * x + (6.0 * b + 30.0 * c) * x * x + (-12.0 * b - 48.0 * c) * x + 8.0 * b + 24.0 * c) / 6.0
}
[fragment_shader(name="denoise_txaa")]
def txaa {
    let center = texture(image0, uv).xyz
    var mean = float3(0.0); var m2 = float3(0.0); var closest = 1.0; var velocity = float2(0.0)
    for (y in range(-1, 2)) { for (x in range(-1, 2)) {
        let tc = uv + float2(float(x), float(y)) / config.size.xy; let c = textureLod(image0, tc, 0.0).xyz; mean += c; m2 += c * c
        let z = textureLod(image3, tc, 0.0).x; if (z < closest) { closest = z; velocity = textureLod(image2, tc, 0.0).xy }
    } }
    mean /= 9.0; m2 /= 9.0; let sigma = max(sqrt(max(m2 - mean * mean, float3(0.0))) * 1.4, float3(0.00001))
    let previous_uv = uv - velocity + config.noise.yz / config.size.xy; let old = texture(image1, previous_uv).xyz
    let diff = old - mean; let unit = abs(diff / sigma); let clipped = mean + diff / max(1.0, max(unit.x, max(unit.y, unit.z)))
    let luma = float3(0.3, 0.6, 0.1); let l0 = dot(center, luma); let l1 = dot(clipped, luma); let d = 1.0 - abs(l0 - l1) / max(max(l0, l1), 0.2); let r = d * d
    var current = center
    if (config.temporal.z > 0.5) { var sum = float3(0.0); var weights = 0.0; let b = lerp(1.5, 1.0 / 3.0, r); let c = lerp(-0.25, 1.0 / 3.0, r)
        for (y in range(-1, 2)) { for (x in range(-1, 2)) { let w = mitchell(length(float2(float(x), float(y))), b, c); sum += textureLod(image0, uv + float2(float(x), float(y)) / config.size.xy, 0.0).xyz * w; weights += w } }; current = sum / max(weights, 0.00001)
    }
    let valid = previous_uv.x >= 0.0 && previous_uv.y >= 0.0 && previous_uv.x <= 1.0 && previous_uv.y <= 1.0
    color = float4(valid ? lerp(current, clipped, lerp(config.temporal.x, config.temporal.y, r)) : current, 1.0)
}
