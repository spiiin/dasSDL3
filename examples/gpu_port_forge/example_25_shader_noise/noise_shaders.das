options gen2
module noise_shaders shared public
// Altered from forge-gpu lesson 25, Zlib / Rosy Game Studio.
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct NoiseParams { time : float; mode,dither : int; scale : float; resolution : float2; padding : float2 }
var @uniform @set=3 @binding=0 params : NoiseParams
var @out @location=0 out_uv : float2
var @in @location=0 uv : float2
var @out @location=0 color : float4
[vertex_shader(name="forge_noise_vertex")]
def noise_vs {
 let t=float2(float((gl_VertexIndex<<1)&2),float(gl_VertexIndex&2))
 gl_Position=float4(t.x*2.0-1.0,1.0-t.y*2.0,0.0,1.0);out_uv=t
}
def mix(a,b,t : float) : float {return a*(1.0-t)+b*t}
def mix(a,b : float3; t : float) : float3 {return a*(1.0-t)+b*t}
def wang_hash(value : uint) : uint {
 var seed=(value^61u)^(value>>16u);seed*=9u;seed=seed^(seed>>4u);seed*=0x27d4eb2du;return seed^(seed>>15u)
}
def hash_combine(seed,value : uint) : uint {return seed^(value+0x9e3779b9u+(seed<<6u)+(seed>>2u))}
def hash2d_uint(p : int2) : uint {return wang_hash(hash_combine(wang_hash(uint(p.x)),uint(p.y)))}
def hash2d(p : int2) : float {return float(hash2d_uint(p))/4294967296.0}
def value_noise(p : float2) : float {
 let i=int2(floor(p));let f=fract(p);let u=f*f*(float2(3)-2.0*f)
 return mix(mix(hash2d(i),hash2d(i+int2(1,0)),u.x),mix(hash2d(i+int2(0,1)),hash2d(i+int2(1,1)),u.x),u.y)
}
def grad2d(hash : uint; d : float2) : float {return ((hash&1u)!=0u ? -d.x : d.x)+((hash&2u)!=0u ? -d.y : d.y)}
def perlin2d(p : float2) : float {
 let i=int2(floor(p));let f=fract(p);let u=f*f*f*(f*(f*6.0-float2(15))+float2(10))
 return mix(mix(grad2d(hash2d_uint(i),f),grad2d(hash2d_uint(i+int2(1,0)),f-float2(1,0)),u.x),mix(grad2d(hash2d_uint(i+int2(0,1)),f-float2(0,1)),grad2d(hash2d_uint(i+int2(1,1)),f-float2(1)),u.x),u.y)
}
def fbm(p : float2) : float {
 var value=0.0;var amplitude=0.5;var frequency=1.0
 for(oct in 0..6){value+=amplitude*perlin2d(p*frequency);frequency*=2.0;amplitude*=0.5};return value
}
def domain_warp(p : float2) : float {
 let q=float2(fbm(p),fbm(p+float2(5.2,1.3)))
 let r=float2(fbm(p+4.0*q+float2(1.7,9.2)),fbm(p+4.0*q+float2(8.3,2.8)))
 return fbm(p+4.0*r)
}
def terrain_color(height : float) : float3 {
 let h=clamp(height+0.5,0.0,1.0);var c=float3(0.05,0.10,0.35)
 c=mix(c,float3(0.10,0.30,0.50),smoothstep(0.30,0.38,h));c=mix(c,float3(0.76,0.69,0.50),smoothstep(0.38,0.42,h))
 c=mix(c,float3(0.20,0.50,0.15),smoothstep(0.42,0.50,h));c=mix(c,float3(0.10,0.35,0.10),smoothstep(0.50,0.62,h))
 c=mix(c,float3(0.45,0.40,0.35),smoothstep(0.62,0.75,h));return mix(c,float3(0.90,0.92,0.95),smoothstep(0.75,0.85,h))
}
[fragment_shader(name="forge_noise_fragment")]
def noise_fs {
 let p=uv*params.scale*float2(params.resolution.x/params.resolution.y,1.0);let t=params.time;var c=float3(0)
 if(params.mode==0){c=float3(float(hash_combine(hash2d_uint(int2(floor(p))),uint(t*60.0)))/4294967296.0)}
 elif(params.mode==1){c=float3(value_noise(p+float2(t*0.3,t*0.2)))}
 elif(params.mode==2){c=float3(perlin2d(p+float2(t*0.3,t*0.2))*0.5+0.5)}
 elif(params.mode==3){c=float3(fbm(p+float2(t*0.1,t*0.08))*0.5+0.5)}
 elif(params.mode==4){let n=domain_warp(p+float2(t*0.05,t*0.03))*0.5+0.5;c=float3(n*n,n,sqrt(clamp(n,0.0,1.0)))}
 else{c=terrain_color(fbm(p*0.5+float2(t*0.02,t*0.01)))}
 if(params.dither!=0){c+=float3((fract(52.9829189*fract(dot(gl_FragCoord.xy,float2(0.06711056,0.00583715))))-0.5)/255.0)}
 color=float4(clamp(c,float3(0),float3(1)),1.0)
}
