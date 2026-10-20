options gen2
module decal_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct DecalParams {inverse_vp,inverse_model,inverse_view,light_vp : float4x4;color,eye,size : float4}
var @uniform @set=3 @binding=0 decal : DecalParams
var @set=2 @binding=0 depth_image : sampler2D
var @set=2 @binding=1 normal_image : sampler2D
var @set=2 @binding=2 shadow_image : sampler2D
var @out @location=0 output_color : float4
def shape_alpha(uv : float2;shape : int) : float {
 let p=uv*2.0-float2(1);let d=length(p)
 if(shape==0){return 1.0-smoothstep(0.7,0.8,d)}
 if(shape==1){let x=abs(p.x)*1.1;let y=-p.y*1.1+0.3;return 1.0-smoothstep(-0.05,0.05,x*x+y*y-x*sqrt(abs(y))-0.5)}
 if(shape==2){let r=0.3+0.5*abs(cos(atan2(p.y,p.x)*2.5));return 1.0-smoothstep(r-0.05,r+0.05,d)}
 if(shape==3){return (int(uv.x*4.0)+int(uv.y*4.0))%2==0 ? 1.0-smoothstep(0.75,0.85,d) : 0.0}
 if(shape==4){return max(0.0,smoothstep(0.45,0.55,d)-smoothstep(0.7,0.8,d))}
 if(shape==5){return 1.0-smoothstep(0.65,0.75,abs(p.x)+abs(p.y))}
 if(shape==6){return abs(p.x)<0.2 || abs(p.y)<0.2 ? 1.0-smoothstep(0.7,0.8,d) : 0.0}
 let y=p.y+0.3;return 1.0-smoothstep(-0.03,0.03,max(abs(p.x)-(0.8-y*0.8),max(y-0.8,-y-0.3)))
}
[fragment_shader(name="forge_decal_fragment")]
def decal_fs {
 let uv=gl_FragCoord.xy/decal.size.xy;let depth=textureLod(depth_image,uv,0.0).r;if(depth>=0.9999){discard()}
 let h=decal.inverse_vp*float4(uv.x*2.0-1.0,1.0-uv.y*2.0,depth,1.0);let world=h.xyz/h.w
 let local=(decal.inverse_model*float4(world,1.0)).xyz
 if(abs(local.x)>0.5 || abs(local.y)>0.5 || abs(local.z)>0.5){discard()}
 let fade=(1.0-smoothstep(0.4,0.5,abs(local.x)))*(1.0-smoothstep(0.4,0.5,abs(local.y)))*(1.0-smoothstep(0.4,0.5,abs(local.z)))
 let alpha=shape_alpha(local.xz+float2(0.5),int(decal.size.z))*fade*decal.color.a;if(alpha<0.01){discard()}
 let n=normalize((decal.inverse_view*float4(textureLod(normal_image,uv,0.0).xyz,0.0)).xyz)
 let l=normalize(float3(0.5,0.8,0.5));let v=normalize(decal.eye.xyz-world);let half_=normalize(l+v)
 let projected=decal.light_vp*float4(world,1.0);let p=projected.xyz/projected.w;let shadow_uv=float2(p.x*0.5+0.5,0.5-p.y*0.5)
 var shadow=0.0;for(y in 0..2){for(x in 0..2){shadow+=p.z-0.005<=textureLod(shadow_image,shadow_uv+float2(float(x)-0.5,float(y)-0.5)/2048.0,0.0).r ? 0.25 : 0.0}}
 let lit=decal.color.rgb*0.15+(decal.color.rgb*max(dot(n,l),0.0)+float3(0.3*pow(max(dot(n,half_),0.0),64.0)))*float3(0.8,0.76,0.72)*shadow
 output_color=float4(lit,alpha)
}
