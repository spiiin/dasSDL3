options gen2
module hdr_shaders shared public
// Forge GPU 21-24 postprocessing. Zlib, Rosy Game Studio. No upstream binaries.
require spirv/spirv_shader
require advanced_shaders public
struct PostParams { config,texel : float4 }
var @uniform @set=3 @binding=0 post : PostParams
var @set=2 @binding=0 source : sampler2D
var @set=2 @binding=1 bloom_source : sampler2D

[vertex_shader(name="forge_post_vertex")]
def post_vs {
 let t=float2(float((gl_VertexIndex<<1)&2),float(gl_VertexIndex&2))
 gl_Position=float4(t.x*2.0-1.0,1.0-t.y*2.0,0.0,1.0);o_uv=t
}
def tone_map(hdr : float3; mode : float) : float3 {
 if(mode<0.5){return clamp(hdr,float3(0),float3(1))}
 if(mode<1.5){return hdr/(hdr+float3(1))}
 return clamp((hdr*(2.51*hdr+float3(0.03)))/(hdr*(2.43*hdr+float3(0.59))+float3(0.14)),float3(0),float3(1))
}
[fragment_shader(name="forge_tone_fragment")]
def tone_fs {result_color=float4(tone_map(texture(source,i_uv).rgb*post.config.x,post.config.y),1.0)}
[fragment_shader(name="forge_bloom_tone_fragment")]
def bloom_tone_fs {result_color=float4(tone_map((texture(source,i_uv).rgb+texture(bloom_source,i_uv).rgb*post.config.z)*post.config.x,post.config.y),1.0)}
def luma(c : float3) : float {return dot(c,float3(0.2126,0.7152,0.0722))}
def bloom_sample(offset : float2) : float3 {
 let c=texture(source,i_uv+offset*post.texel.xy).rgb
 if(post.config.y<0.5){return c}
 let lum=luma(c);return c*(max(lum-post.config.x,0.0)/max(lum,0.0001))
}
[fragment_shader(name="forge_bloom_down_fragment")]
def down_fs {
 let a=bloom_sample(float2(-2,-2));let b=bloom_sample(float2(0,-2));let c=bloom_sample(float2(2,-2))
 let d=bloom_sample(float2(-1,-1));let e=bloom_sample(float2(1,-1));let f=bloom_sample(float2(-2,0))
 let g=bloom_sample(float2(0));let h=bloom_sample(float2(2,0));let i=bloom_sample(float2(-1,1))
 let j=bloom_sample(float2(1,1));let k=bloom_sample(float2(-2,2));let l=bloom_sample(float2(0,2));let m=bloom_sample(float2(2,2))
 let tl=(a+b+f+g)*0.25;let tr=(b+c+g+h)*0.25;let bl=(f+g+k+l)*0.25;let br=(g+h+l+m)*0.25;let ct=(d+e+i+j)*0.25
 var weights=float4(0.125);var center=0.5
 if(post.config.y>0.5){weights/=float4(1.0+luma(tl),1.0+luma(tr),1.0+luma(bl),1.0+luma(br));center/=1.0+luma(ct)}
 let sum=weights.x+weights.y+weights.z+weights.w+center
 result_color=float4((tl*weights.x+tr*weights.y+bl*weights.z+br*weights.w+ct*center)/max(sum,0.0001),1.0)
}
[fragment_shader(name="forge_bloom_up_fragment")]
def up_fs {
 var sum=float3(0)
 for(y in -1..2){for(x in -1..2){let w=float((x==0 ? 2 : 1)*(y==0 ? 2 : 1))/16.0;sum+=texture(source,i_uv+float2(float(x),float(y))*post.texel.xy).rgb*w}}
 result_color=float4(sum,1.0)
}
[fragment_shader(name="forge_hdr_scene_fragment")]
def hdr_scene_fs {
 let c=sampled_surface();let n=normalize(i_normal);let v=normalize(af.eye.xyz-i_world)
 var light=normalize(af.light.xyz);var factor=af.fog.x
 if(af.fog.y>0.5){let delta=af.light.xyz-i_world;let d=length(delta);light=delta/d;factor/=1.0+0.09*d+0.032*d*d}
 var shadow=1.0
 if(af.shadow.z>0.5){let d=length(af.eye.xyz-i_world);if(d<af.splits.x){shadow=pcf0(i_light0)}elif(d<af.splits.y){shadow=pcf1(i_light1)}elif(d<af.splits.z){shadow=pcf2(i_light2)}}
 let h=normalize(light+v)
 result_color=float4(af.ambient.rgb*c.rgb+(c.rgb*max(dot(n,light),0.0)+af.specular.rgb*pow(max(dot(n,h),0.0),af.specular.w))*shadow*factor,c.a)
}
[fragment_shader(name="forge_emissive_fragment")]
def emissive_fs {result_color=af.base}
