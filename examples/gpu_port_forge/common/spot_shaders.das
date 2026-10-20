options gen2
module spot_shaders shared public
require spirv/spirv_shader
require advanced_shaders public
var @set=2 @binding=2 gobo : sampler2D
def spot_shadow(projected : float3) : float {
 var sum=0.0;let uv=float2(projected.x*0.5+0.5,0.5-projected.y*0.5)
 for(y in 0..2){for(x in 0..2){let offset=float2(float(x)-0.5,float(y)-0.5)/1024.0;sum+=projected.z-0.002<=textureLod(cascade0,uv+offset,0.0).r ? 1.0 : 0.0}}
 return sum*0.25
}
[fragment_shader(name="forge_spot_fragment")]
def spot_fs {
 let c=sampled_surface();let n=normalize(i_normal);let v=normalize(af.eye.xyz-i_world)
 if(af.controls.z>0.5){result_color=float4(c.rgb*35.0,c.a);return}
 let fill=normalize(float3(-0.3,0.8,-0.2));let fh=normalize(fill+v)
 var sum=c.rgb*0.05+(c.rgb*max(dot(n,fill),0.0)+float3(0.5*pow(max(dot(n,fh),0.0),64.0)))*0.05
 let delta=i_world-af.light.xyz;let d=length(delta);let l=-delta/d;let cone=smoothstep(cos(0.5235987756),cos(0.3490658504),dot(delta/d,normalize(-af.light.xyz)))
 let p=i_light0.xyz/i_light0.w;let uv=float2(p.x*0.5+0.5,0.5-p.y*0.5)
 let bounds=uv.x>=0.0 && uv.x<=1.0 && uv.y>=0.0 && uv.y<=1.0 ? 1.0 : 0.0
 let mask=textureLod(gobo,uv,0.0).r;let shadow=af.shadow.z>0.5 ? spot_shadow(p) : 1.0;let h=normalize(l+v)
 sum+=(c.rgb*max(dot(n,l),0.0)+float3(0.5*pow(max(dot(n,h),0.0),64.0)))*float3(1.0,0.95,0.8)*cone*mask*shadow*bounds*5.0/(1.0+0.09*d+0.032*d*d)
 result_color=float4(sum,c.a)
}
