// Adapted from bgfx 36-sky. Copyright 2017 Stanislav Pidhorskyi.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module sky_shaders shared public
require dassdl3/sdl3_shader_access
require math public

struct Sky { sun, zenith, config : float4; a, b, c, d, e : float4; right, up, forward, land : float4 }
var @uniform @set = 3 @binding = 0 sky : Sky
var @out @location = 0 v_uv : float2
var @in @location = 0 uv : float2
var @out @location = 0 color : float4
[vertex_shader(name="sky_vertex")]
def vertex_main { let id = gl_VertexIndex; let t = float2(float((id << 1) & 2), float(id & 2)); v_uv = t; gl_Position = float4(t.x * 2.0 - 1.0, 1.0 - t.y * 2.0, 0.0, 1.0) }
def perez(ct, cg : float) : float3 { return (float3(1.0) + sky.a.xyz * exp(sky.b.xyz / max(ct, 0.001))) * (float3(1.0) + sky.c.xyz * exp(sky.d.xyz * acos(clamp(cg, -0.9999, 0.9999))) + sky.e.xyz * cg * cg) }
[fragment_shader(name="sky_fragment")]
def fragment_main {
 let ray = normalize(sky.forward.xyz + sky.right.xyz * ((uv.x * 2.0 - 1.0) * sky.config.x / 1.7320508) + sky.up.xyz * ((1.0 - uv.y * 2.0) / 1.7320508))
 let sun = normalize(sky.sun.xyz); let cg = dot(ray, sun)
 let xyz = sky.zenith.xyz; let sum = xyz.x + xyz.y + xyz.z
 let xyY = float3(xyz.x / sum, xyz.y / sum, xyz.y) * perez(max(ray.y, 0.001), cg) / perez(1.0, sun.y)
 let X = xyY.x * xyY.z / xyY.y; let Y = xyY.z; let Z = (1.0 - xyY.x - xyY.y) * xyY.z / xyY.y
 var rgb = float3(3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z, -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z, 0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z) * sky.config.y
 let dist = 2.0 * (1.0 - cg); let disk = exp(-dist / 0.002) + (dist < 0.0004 ? 1.0 : 0.0)
 rgb += float3(min(disk * disk, 1.0))
 rgb = pow(max(rgb, float3(0.0)), float3(1.0 / 2.2))
 if (sky.config.z > 0.5) { let noise = fract(sin(dot(gl_FragCoord.xy, float2(12.9898, 78.233))) * 43758.5453); rgb += float3((noise - 0.5) / 255.0) }
 color = float4(rgb, 1.0)
}

struct Landscape { vp : float4x4 }
var @uniform @set = 1 @binding = 0 landscape : Landscape
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 2 texcoord : float2
var @out @location = 1 v_normal : float3
var @in @location = 1 surface_normal : float3
var @set = 2 @binding = 0 lightmap : sampler2D
[vertex_shader(name="sky_landscape_vertex")]
def landscape_vertex {
 gl_Position = landscape.vp * float4(position, 1.0); v_uv = texcoord; v_normal = normal
}
def xyz_rgb(xyz : float3) : float3 {
 return float3(dot(xyz, float3(3.2404542, -1.5371385, -0.4985314)), dot(xyz, float3(-0.9692660, 1.8760108, 0.0415560)), dot(xyz, float3(0.0556434, -0.2040259, 1.0572252)))
}
[fragment_shader(name="sky_landscape_fragment")]
def landscape_fragment {
 let n = normalize(surface_normal)
 let occlusion = sky.land.y > 0.5 ? pow(abs(texture(lightmap, uv).r), 2.2) : 1.0
 let direct = max(dot(n, normalize(sky.sun.xyz)), 0.0)
 let ambient = 1.0 + 0.5 * n.z
 let rgb = (direct * xyz_rgb(float3(13.067827, 13.467483, 12.745179)) + (ambient * xyz_rgb(sky.zenith.xyz) + float3(0.01)) * occlusion) * (0.5 * sky.config.y)
 let coord = gl_FragCoord.xy + float2(fract(sky.land.x) * 13.0)
 let noise = fract(52.9829189 * fract(dot(coord, float2(0.06711056, 0.00583715))))
 color = float4(pow(max(rgb, float3(0.0)), float3(1.0 / 2.2)) + float3((noise - 0.5) / 255.0), 1.0)
}
