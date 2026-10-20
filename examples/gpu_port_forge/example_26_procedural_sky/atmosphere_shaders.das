options gen2
module atmosphere_shaders shared public
// Hillaire atmosphere from forge-gpu 26. Zlib / Rosy Game Studio.
require spirv/spirv_shader
require spirv/spirv_builtins public
require dassdl3/sdl3_shader_access
require math public
struct AtmosphereView { inverse : float4x4 }
struct AtmosphereParams { camera,sun,resolution : float4 }
var @uniform @set=1 @binding=0 view : AtmosphereView
var @uniform @set=3 @binding=0 sky : AtmosphereParams
var @set=2 @binding=0 transmittance : sampler2D
var @set=2 @binding=1 multiple_scatter : sampler2D
var @set=0 @binding=0 compute_transmittance : sampler2D
var @writeonly @set=1 @binding=0 lut_output : image2D
var @out @location=0 ray_out : float3
var @in @location=0 ray_in : float3
var @out @location=0 result : float4
def sphere_interval(ro,rd : float3; radius : float) : float2 {
 let a=dot(rd,rd);let b=2.0*dot(ro,rd);let c=dot(ro,ro)-radius*radius;let d=b*b-4.0*a*c
 if(d<0.0){return float2(1,-1)}
 return float2(-b-sqrt(d),-b+sqrt(d))/(2.0*a)
}
def extinction(pos : float3) : float3 {
 let altitude=length(pos)-6360.0
 return float3(5.802e-3,13.558e-3,33.1e-3)*exp(-altitude/8.0)+float3(4.440e-3*exp(-altitude/1.2))+float3(0.650e-3,1.881e-3,0.085e-3)*max(0.0,1.0-abs(altitude-25.0)/15.0)
}
def scattering(pos : float3) : float3 {
 let altitude=length(pos)-6360.0
 return float3(5.802e-3,13.558e-3,33.1e-3)*exp(-altitude/8.0)+float3(3.996e-3*exp(-altitude/1.2))
}
def trans_uv(height,cosine : float) : float2 {
 let h=sqrt(6460.0*6460.0-6360.0*6360.0);let rho=sqrt(max(0.0,height*height-6360.0*6360.0))
 let d=max(0.0,-height*cosine+sqrt(max(0.0,height*height*(cosine*cosine-1.0)+6460.0*6460.0)))
 let dmin=6460.0-height;let dmax=rho+h
 return clamp(float2(dmax>dmin ? (d-dmin)/(dmax-dmin) : 0.0,rho/h),float2(0),float2(1))
}
def earth_shadow(pos,sun : float3) : float {
 let hit=sphere_interval(pos,sun,6360.0);let visible=hit.x<=hit.y && hit.x>=0.0 ? 0.0 : 1.0
 return visible*clamp(dot(normalize(pos),sun)*10.0+0.1,0.0,1.0)
}
[compute_shader(local_size_x=8,local_size_y=8,name="forge_transmittance_compute"),sdl_shader_access(name="forge_transmittance_compute")]
def trans_cs {
 let id=gl_GlobalInvocationID;let uv=(float2(float(id.x),float(id.y))+float2(0.5))/float2(256,64)
 let h=sqrt(6460.0*6460.0-6360.0*6360.0);let rho=h*uv.y;let height=sqrt(rho*rho+6360.0*6360.0)
 let dmin=6460.0-height;let dmax=rho+h;let distance=dmin+uv.x*(dmax-dmin);let denominator=2.0*height*distance
 let cosine=denominator<1e-6 ? 1.0 : clamp((h*h-rho*rho-distance*distance)/denominator,-1.0,1.0)
 let ro=float3(0.0,height,0.0);let rd=float3(sqrt(max(0.0,1.0-cosine*cosine)),cosine,0.0)
 let hit=sphere_interval(ro,rd,6460.0);let start=max(hit.x,0.0);var end=hit.y
 let ground=sphere_interval(ro,rd,6360.0);if(ground.x<=ground.y && ground.x>0.0){end=min(end,ground.x)}
 let step=(end-start)/40.0;var optical=float3(0)
 for(i in 0..40){optical+=extinction(ro+rd*(start+(float(i)+0.5)*step))*step}
 imageStore(lut_output,int2(int(id.x),int(id.y)),float4(exp(-optical),1.0))
}
[compute_shader(local_size_x=8,local_size_y=8,name="forge_multiscatter_compute"),sdl_shader_access(name="forge_multiscatter_compute")]
def multiscatter_cs {
 let id=gl_GlobalInvocationID;let uv=(float2(float(id.x),float(id.y))+float2(0.5))/32.0
 let cosine=((uv.x-0.5/32.0)*(32.0/31.0))*2.0-1.0
 let height=6360.0+clamp((uv.y-0.5/32.0)*(32.0/31.0)*100.0,0.01,100.0)
 let sun=float3(sqrt(max(0.0,1.0-cosine*cosine)),cosine,0.0);let origin=float3(0.0,height,0.0)
 var radiance=float3(0);var multiple=float3(0)
 for(i in 0..8){for(j in 0..8){
  let theta=6.28318530718*(float(i)+0.5)/8.0;let phi=acos(1.0-2.0*(float(j)+0.5)/8.0)
  let direction=float3(sin(phi)*cos(theta),cos(phi),sin(phi)*sin(theta));let hit=sphere_interval(origin,direction,6460.0)
  let start=max(hit.x,0.0);var end=hit.y;let ground=sphere_interval(origin,direction,6360.0)
  if(ground.x<=ground.y && ground.x>=0.0){end=min(end,ground.x)}
  let step=(end-start)/20.0;var throughput=float3(1);var dir_l=float3(0);var dir_f=float3(0)
  for(k in 0..20){
   let pos=origin+direction*(start+(float(k)+0.5)*step);let ext=extinction(pos);let scatter=scattering(pos);let step_ext=exp(-ext*step)
   let integral=(float3(1)-step_ext)/max(ext,float3(1e-6));let sun_trans=textureLod(compute_transmittance,trans_uv(length(pos),dot(normalize(pos),sun)),0.0).rgb
   dir_l+=throughput*scatter*sun_trans*earth_shadow(pos,sun)*integral;dir_f+=throughput*scatter*integral;throughput*=step_ext
  }
  radiance+=dir_l/64.0;multiple+=dir_f/64.0
 }}
 imageStore(lut_output,int2(int(id.x),int(id.y)),float4(radiance/(float3(1)-clamp(multiple,float3(0),float3(0.99))),1.0))
}
[vertex_shader(name="forge_atmosphere_vertex")]
def atmosphere_vs {
 let t=float2(float((gl_VertexIndex<<1)&2),float(gl_VertexIndex&2));let ndc=float2(t.x*2.0-1.0,1.0-t.y*2.0)
 gl_Position=float4(ndc,0.0,1.0);let world=view.inverse*float4(ndc,1.0,1.0);ray_out=world.xyz/world.w
}
[fragment_shader(name="forge_atmosphere_fragment")]
def atmosphere_fs {
 let ro=sky.camera.xyz;let rd=normalize(ray_in);let sun=normalize(sky.sun.xyz);let hit=sphere_interval(ro,rd,6460.0)
 if(hit.x>hit.y){result=float4(0,0,0,1);return}
 let start=max(hit.x,0.0);var end=hit.y;let ground=sphere_interval(ro,rd,6360.0)
 if(ground.x<=ground.y && ground.x>0.0){end=min(end,ground.x)}
 let cosine=dot(rd,sun);let phase_r=3.0/(16.0*3.14159265359)*(1.0+cosine*cosine)
 let denominator=1.0+0.64-1.6*cosine;let phase_m=0.36/(4.0*3.14159265359*denominator*sqrt(denominator))
 let step=(end-start)/sky.sun.w;var radiance=float3(0);var throughput=float3(1)
 for(i in 0..32){
  let pos=ro+rd*(start+(float(i)+0.5)*step);let altitude=length(pos)-6360.0;let ext=extinction(pos)
  let sun_cos=dot(normalize(pos),sun);let st=textureLod(transmittance,trans_uv(length(pos),sun_cos),0.0).rgb
  let ms_uv=(float2(sun_cos*0.5+0.5,clamp(altitude/100.0,0.0,1.0))+float2(0.5/32.0))*(32.0/33.0)
  let ms=textureLod(multiple_scatter,ms_uv,0.0).rgb
  let source=(float3(5.802e-3,13.558e-3,33.1e-3)*exp(-altitude/8.0)*phase_r+float3(3.996e-3*exp(-altitude/1.2)*phase_m))*st*earth_shadow(pos,sun)*sky.camera.w+ms*scattering(pos)*sky.camera.w
  let step_ext=exp(-ext*step);radiance+=source*(float3(1)-step_ext)/max(ext,float3(1e-6))*throughput;throughput*=step_ext
 }
 let blocked=sphere_interval(ro,sun,6360.0)
 if(blocked.x>blocked.y || blocked.x<0.0){
  let angle=acos(clamp(dot(rd,sun),-1.0,1.0));let edge=smoothstep(0.014*1.2,0.014*0.9,angle);let r=angle/0.014
  radiance+=float3(sky.camera.w*10.0*(1.0-0.6*(1.0-sqrt(max(0.0,1.0-r*r))))*edge)*throughput
 }
 result=float4(radiance,1.0)
}
