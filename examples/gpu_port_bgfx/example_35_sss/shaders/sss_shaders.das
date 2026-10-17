// Port of bgfx 44-sss, Copyright 2021 elven cache. BSD-2-Clause.
options gen2
module sss_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math
struct Config { view, projection : float4x4; size, light, settings, controls : float4 }
var @uniform @set = 3 @binding = 0 config : Config
var @set = 2 @binding = 0 image0 : sampler2D
var @set = 2 @binding = 1 image1 : sampler2D
var @set = 2 @binding = 2 image2 : sampler2D
var @set = 2 @binding = 3 image3 : sampler2D
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
[vertex_shader(name="sss_screen")]
def screen { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); v_uv = t; gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0) }
[fragment_shader(name="sss_depth")]
def depth { let z = texture(image0, uv).x; color = float4(1.0 / max(100.0 - z * 99.99, 0.00001)) }
def view_position(tc : float2; depth : float) : float3 { return float3((tc.x * 2.0 - 1.0) / config.projection[0].x, (1.0 - tc.y * 2.0) / config.projection[1].y, 1.0) * depth }
[fragment_shader(name="sss_shadow")]
def shadow {
    let z = texture(image0, uv).x
    let point = view_position(uv, z)
    var radius = config.settings.x
    if (config.controls.x > 0.5) { radius = abs(2.0 * radius * z / (config.size.x * config.projection[0].x)) }
    let steps = max(config.settings.y, 1.0)
    let delta = normalize(config.light.xyz - point) * (radius / steps)
    let noise = fract(sin(dot(gl_FragCoord.xy + float2(314.0, 159.0) * config.size.z, float2(12.9898, 78.233))) * 43758.5453123)
    var p = point + delta * (config.controls.y > 0.5 ? 0.5 + noise : 1.0)
    var hits = 0.0; var soft = 0.0; var first = steps
    for (i in range(int(steps))) {
        let clip = config.projection * float4(p, 1.0)
        let coord = clip.xy / clip.w * float2(0.5, -0.5) + float2(0.5)
        let difference = p.z - textureLod(image0, coord, 0.0).x
        if (difference > 0.0001 && difference < radius) { first = min(first, float(i)); hits += 1.0; soft += clamp(radius - difference, 0.0, 1.0) }
        p += delta
    }
    var result = hits > 0.0 ? 0.0 : 1.0
    if (config.settings.z > 0.5) { let occlusion = config.settings.z > 1.5 ? soft : hits; let attenuation = 1.0 - clamp(occlusion * (1.0 - first / steps), 0.0, 1.0); result = attenuation * attenuation }
    color = float4(result)
}
[fragment_shader(name="sss_combine")]
def combine {
    let albedo = texture(image0, uv)
    var result = pow(albedo.xyz, float3(2.2))
    if (albedo.w > 0.0) {
        let normal = texture(image1, uv)
        let n = normalize((config.view * float4(normal.xyz, 0.0)).xyz)
        let point = view_position(uv, texture(image2, uv).x)
        let light = config.light.xyz - point
        let diffuse = max(dot(n, normalize(light)), 0.0)
        let power = 62.0 * (1.0 - normal.w) + 2.0
        let shade = texture(image3, uv).x
        let amount = lerp(diffuse / (dot(light, light) + 0.00001), 5.0 * pow(diffuse, power), 0.04) * shade
        result = pow(max(result * amount, float3(0.0)), float3(1.0 / 2.2))
        if (config.controls.z > 0.5) { result = float3(shade) }
    }
    color = float4(result, 1.0)
}
