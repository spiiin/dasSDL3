// Adapted from bgfx 36-sky. Copyright 2017 Stanislav Pidhorskyi.
// See the example README and group LICENSE-bgfx.txt.
options gen2
module sky_shaders shared public
require dassdl3/sdl3_shader_access
require math public

struct Sky { sun, zenith, config : float4; a,b,c,d,e : float4; right,up,forward,land,sun_xyz : float4 }
var @uniform @set=3 @binding=0 sky : Sky
var @uniform @set=1 @binding=0 vertex_sky : Sky
var @in @location=0 grid_position : float3
var @out @location=0 sky_color : float3
var @out @location=1 sky_ray : float3
var @in @location=0 interpolated_color : float3
var @in @location=1 interpolated_ray : float3
var @out @location=0 color : float4
var @out @location=0 v_uv : float2
var @in @location=0 uv : float2

def perez(a,b,c,d,e : float3; ct,cg : float) : float3 {
 return (float3(1.0)+a*exp(b/max(ct,0.001)))*(float3(1.0)+c*exp(d*acos(clamp(cg,-0.9999,0.9999)))+e*cg*cg)
}
[vertex_shader(name="sky_vertex")]
def vertex_main {
 var ray=normalize(vertex_sky.forward.xyz+vertex_sky.right.xyz*(grid_position.x*vertex_sky.config.x/1.7320508)+vertex_sky.up.xyz*(grid_position.y/1.7320508))
 ray.y=abs(ray.y);sky_ray=ray;gl_Position=float4(grid_position.xy,1.0,1.0)
 let sun=normalize(vertex_sky.sun.xyz);let xyz=vertex_sky.zenith.xyz;let sum=xyz.x+xyz.y+xyz.z
 let xyY=float3(xyz.x/sum,xyz.y/sum,xyz.y)*perez(vertex_sky.a.xyz,vertex_sky.b.xyz,vertex_sky.c.xyz,vertex_sky.d.xyz,vertex_sky.e.xyz,max(ray.y,0.001),dot(ray,sun))/perez(vertex_sky.a.xyz,vertex_sky.b.xyz,vertex_sky.c.xyz,vertex_sky.d.xyz,vertex_sky.e.xyz,1.0,sun.y)
 let converted=float3(xyY.x*xyY.z/xyY.y,xyY.z,(1.0-xyY.x-xyY.y)*xyY.z/xyY.y)
 sky_color=xyz_rgb(converted*vertex_sky.config.y)
}
def gradient_noise : float {
 let coord=gl_FragCoord.xy+float2(fract(sky.land.x)*13.0)
 return (fract(52.9829189*fract(dot(coord,float2(0.06711056,0.00583715))))-0.5)/255.0
}
[fragment_shader(name="sky_fragment")]
def fragment_main {
 let cg=dot(normalize(interpolated_ray),normalize(sky.sun.xyz));let distance=2.0*(1.0-cg)
 let disk=exp(-distance/(3.0*0.02*0.02))+(distance<=0.02*0.02 ? 1.0 : 0.0)
 let rgb=pow(abs(interpolated_color+float3(min(disk*disk,1.0))),float3(1.0/2.2))
 color=float4(rgb+float3(sky.config.z>0.5 ? gradient_noise() : 0.0),1.0)
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
def luminance_rgb(xyz : float3) : float3 {
 return float3(dot(xyz, float3(3.240479, -1.53715, -0.49853)), dot(xyz, float3(-0.969256, 1.875991, 0.0415560)), dot(xyz, float3(0.055648, -0.204043, 1.057311)))
}
[fragment_shader(name="sky_landscape_fragment")]
def landscape_fragment {
 let n = normalize(surface_normal)
 let occlusion = sky.land.y > 0.5 ? pow(abs(texture(lightmap, uv).r), 2.2) : 1.0
 let direct = max(dot(n, normalize(sky.sun.xyz)), 0.0)
 let ambient = 1.0 + 0.5 * n.z
 let rgb = (direct * luminance_rgb(sky.sun_xyz.xyz) + (ambient * luminance_rgb(sky.zenith.xyz) + float3(0.01)) * occlusion) * (0.5 * sky.config.y)
 let coord = gl_FragCoord.xy + float2(fract(sky.land.x) * 13.0)
 let noise = fract(52.9829189 * fract(dot(coord, float2(0.06711056, 0.00583715))))
 color = float4(pow(abs(rgb), float3(1.0 / 2.2)) + float3((noise - 0.5) / 255.0), 1.0)
}
