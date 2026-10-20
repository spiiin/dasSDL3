options gen2
module screen_shaders shared public
require spirv/spirv_shader
require advanced_shaders public
struct ScreenView { view,projection,inverse_projection : float4x4 }
struct ScreenParams { config,size : float4; samples : float4[64]; noise : float4[16] }
var @uniform @set=3 @binding=1 screen_view : ScreenView
var @uniform @set=3 @binding=0 screen : ScreenParams
var @out @location=1 normal_out : float4
var @out @location=2 world_out : float4
var @set=2 @binding=0 scene_image : sampler2D
var @set=2 @binding=1 depth_image : sampler2D
var @set=2 @binding=2 normal_image : sampler2D
var @set=2 @binding=3 world_image : sampler2D
var @set=2 @binding=4 debug_depth : sampler2D
var @set=2 @binding=1 effect_image : sampler2D
var @set=2 @binding=0 ao_depth : sampler2D
var @set=2 @binding=1 ao_normal : sampler2D
def single_shadow : float {
 let p=i_light0.xyz/i_light0.w;let uv=float2(p.x*0.5+0.5,0.5-p.y*0.5)
 if(uv.x<0.0 || uv.x>1.0 || uv.y<0.0 || uv.y>1.0){return 1.0}
 var sum=0.0;for(y in 0..2){for(x in 0..2){sum+=p.z-0.002<=textureLod(cascade0,uv+float2(float(x)-0.5,float(y)-0.5)/2048.0,0.0).r ? 1.0 : 0.0}};return sum/4.0
}
[fragment_shader(name="forge_gbuffer_fragment")]
def gbuffer_fs {
 let c=sampled_surface();let n=normalize(i_normal);let l=normalize(float3(0.5,0.8,0.5));let h=normalize(l+normalize(af.eye.xyz-i_world))
 let lit=c.rgb*0.15+(c.rgb*max(dot(n,l),0.0)+float3(0.3*pow(max(dot(n,h),0.0),64.0)))*float3(1.0,0.95,0.9)*0.8*single_shadow()
 result_color=float4(lit,c.a);normal_out=float4(normalize((screen_view.view*float4(n,0.0)).xyz),1.0);world_out=float4(i_world,af.controls.w>0.0 ? 0.9 : 0.0)
}
def reconstruct(uv : float2; depth : float) : float3 {
 let p=screen_view.inverse_projection*float4(uv.x*2.0-1.0,1.0-uv.y*2.0,depth,1.0);return p.xyz/p.w
}
def project_uv(p : float3) : float2 {let c=screen_view.projection*float4(p,1.0);return float2(c.x/c.w*0.5+0.5,0.5-c.y/c.w*0.5)}
def outside(uv : float2) : bool {return uv.x<0.0 || uv.y<0.0 || uv.x>1.0 || uv.y>1.0}
def ign(p : float2) : float {return fract(52.9829189*fract(dot(p,float2(0.06711056,0.00583715))))}
[fragment_shader(name="forge_ssao_fragment")]
def ssao_fs {
 let depth=textureLod(ao_depth,i_uv,0.0).r
 if(depth>=1.0){result_color=float4(1);return}
 let n=normalize(textureLod(ao_normal,i_uv,0.0).xyz);let pos=reconstruct(i_uv,depth)
 let index=(int(gl_FragCoord.x)%4)+(int(gl_FragCoord.y)%4)*4;var random=screen.noise[index].xyz
 if(screen.config.z>0.5){let a=ign(gl_FragCoord.xy)*6.28318530718;random=float3(random.x*cos(a)-random.y*sin(a),random.x*sin(a)+random.y*cos(a),0.0)}
 let tangent=normalize(random-n*dot(random,n));let bitangent=cross(n,tangent);var sum=0.0
 for(i in 0..64){let v=screen.samples[i].xyz;let p=pos+(tangent*v.x+bitangent*v.y+n*v.z)*screen.config.x;let sample_uv=project_uv(p)
  let stored=reconstruct(sample_uv,textureLod(ao_depth,sample_uv,0.0).r)
  sum+=(stored.z>=p.z+screen.config.y ? 1.0 : 0.0)*smoothstep(0.0,1.0,screen.config.x/abs(pos.z-stored.z))
 };result_color=float4(float3(1.0-sum/64.0),1.0)
}
[fragment_shader(name="forge_ssao_blur_fragment")]
def blur_fs {
 var sum=0.0;for(x in -2..2){for(y in -2..2){sum+=textureLod(scene_image,i_uv+float2(float(x)+0.5,float(y)+0.5)/screen.size.xy,0.0).r}}
 result_color=float4(float3(sum/16.0),1.0)
}
[fragment_shader(name="forge_ssao_composite_fragment")]
def ao_composite_fs {
 let c=texture(scene_image,i_uv).rgb;let ao=texture(effect_image,i_uv).r
 var value=screen.config.x<0.5 ? float3(ao) : (screen.config.x<1.5 ? c*ao : c)
 if(screen.config.y>0.5){value+=float3((ign(gl_FragCoord.xy)-0.5)/255.0)};result_color=float4(value,1.0)
}
[fragment_shader(name="forge_ssr_fragment")]
def ssr_fs {
 let reflectivity=textureLod(world_image,i_uv,0.0).a
 if(reflectivity<0.01){result_color=float4(0);return}
 let pos=reconstruct(i_uv,textureLod(depth_image,i_uv,0.0).r);let n=normalize(textureLod(normal_image,i_uv,0.0).xyz)
 let dir=reflect(normalize(pos),n);let jitter=ign(gl_FragCoord.xy)*screen.config.x;var ray=pos+dir*jitter;var prev=pos;var travel=jitter;var hit=false
 for(i in 0..128){prev=ray;ray+=dir*screen.config.x;travel+=screen.config.x;if(travel>screen.config.y){break};let uv=project_uv(ray);if(outside(uv)){break};if(travel<0.3){continue}
  let stored=reconstruct(uv,textureLod(depth_image,uv,0.0).r);let delta=ray.z-stored.z;if(delta<0.0 && delta> -screen.config.z){hit=true;break}
 }
 if(!hit){result_color=float4(0);return}
 var lo=prev;var hi=ray
 for(i in 0..8){let mid=(lo+hi)*0.5;let uv=project_uv(mid);if(outside(uv)){break};let stored=reconstruct(uv,textureLod(depth_image,uv,0.0).r);if(mid.z<stored.z){hi=mid}else{lo=mid}}
 let uv=project_uv(hi);if(outside(uv)){result_color=float4(0);return}
 let edge=min(uv,float2(1)-uv);let fade=smoothstep(0.0,0.1,min(edge.x,edge.y))*(1.0-clamp(travel/screen.config.y,0.0,1.0))
 let facing=1.0-smoothstep(0.0,0.25,dot(dir,normalize(textureLod(normal_image,uv,0.0).xyz)))
 result_color=float4(textureLod(scene_image,uv,0.0).rgb,fade*facing*reflectivity)
}
[fragment_shader(name="forge_ssr_composite_fragment")]
def ssr_composite_fs {
 let c=texture(scene_image,i_uv).rgb;let reflected=texture(effect_image,i_uv)
 if(screen.config.x<0.5){let t=reflected.a*screen.config.y;result_color=float4(c*(1.0-t)+reflected.rgb*t,1.0)}
 elif(screen.config.x<1.5){result_color=float4(reflected.rgb*reflected.a,1.0)}
 elif(screen.config.x<2.5){result_color=float4(texture(normal_image,i_uv).xyz*0.5+float3(0.5),1.0)}
 elif(screen.config.x<3.5){let d=texture(debug_depth,i_uv).r;let z=0.1*100.0/(100.0-d*99.9);result_color=float4(float3(clamp(z/100.0,0.0,1.0)),1.0)}
 elif(screen.config.x<4.5){result_color=float4(fract(texture(world_image,i_uv).xyz*0.1),1.0)}
 else{result_color=float4(c,1.0)}
}
