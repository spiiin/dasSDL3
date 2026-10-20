options gen2
module particle_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require dassdl3/sdl3_shader_access
require math public
struct Particle {position,velocity,color,life : float4}
struct ParticleSim {physics : float4;emitter,extra : float4;frame : uint4}
struct ParticleView {vp : float4x4;right,up : float4}
var @ssbo @set=1 @binding=0 pool : array<Particle>
var @ssbo @set=1 @binding=1 budget : array<int>
var @ssbo @readonly @set=0 @binding=0 particle_data : array<Particle>
var @uniform @set=2 @binding=0 sim : ParticleSim
var @uniform @set=1 @binding=0 view_ : ParticleView
var @out @location=0 uv_out : float2
var @out @location=1 color_out : float4
var @in @location=0 uv_in : float2
var @in @location=1 color_in : float4
var @out @location=0 output_color : float4
var @set=2 @binding=0 atlas : sampler2D

def particle_hash(seed : uint) : uint {var s=(seed^61u)^(seed>>16u);s*=9u;s=s^(s>>4u);s*=0x27d4eb2du;s=s^(s>>15u);return s}
def spawn(id : uint) : Particle {
 var rng=particle_hash(id*1103515245u+sim.frame.x*12345u);var draws : float[8];for(i in 0..8){rng=particle_hash(rng);draws[i]=float(rng)/4294967296.0};var p : Particle;var pos=float3(0);var vel=float3(0);var size=0.15;var life=2.0;var color=float4(0.3,0.8,1.0,1.0)
 if(sim.emitter.x<0.5){vel=float3((-2.0+draws[0]*(2.0-(-2.0))),(5.0+draws[1]*(10.0-(5.0))),(-2.0+draws[2]*(2.0-(-2.0))));size=(0.08+draws[3]*(0.18-(0.08)));life=(2.0+draws[4]*(4.0-(2.0)))}
 elif(sim.emitter.x<1.5){pos=float3((-0.1+draws[5]*(0.1-(-0.1)))*sim.extra.x,0.0,(-0.1+draws[6]*(0.1-(-0.1)))*sim.extra.x);vel=float3((-0.2+draws[7]*(0.2-(-0.2)))*sim.extra.x,(1.5+draws[0]*(2.5-(1.5))),(-0.2+draws[1]*(0.2-(-0.2)))*sim.extra.x);size=(0.25+draws[2]*(0.45-(0.25)));life=(0.6+draws[3]*(1.2-(0.6)));color=float4(1.0,0.9,0.3,1.0)}
 else{pos=float3((-0.3+draws[4]*(0.3-(-0.3)))*sim.extra.y,0.2,(-0.3+draws[5]*(0.3-(-0.3)))*sim.extra.y);vel=float3((-0.15+draws[6]*(0.15-(-0.15)))*sim.extra.y,(1.2+draws[7]*(1.6-(1.2)))*sim.extra.x,(-0.15+draws[0]*(0.15-(-0.15)))*sim.extra.y);size=(0.3+draws[1]*(0.5-(0.3)));life=(4.0+draws[2]*(6.0-(4.0)));color=float4(0.55,0.53,0.5,0.5)}
 p.position=float4(pos,life);p.velocity=float4(vel,size);p.color=color;p.life=float4(life,sim.emitter.x,size,0.0);return p
}
[compute_shader(local_size_x=256,name="forge_particle_compute"),sdl_shader_access(name="forge_particle_compute")]
def particle_cs {
 let id=gl_GlobalInvocationID.x;if(id>=4096u){return};var p : Particle;p.position=pool[id].position;p.velocity=pool[id].velocity;p.color=pool[id].color;p.life=pool[id].life;let dt=sim.physics.x
 if(sim.frame.x==0u){p=spawn(id);var seed=particle_hash(id*7919u+42u);let fraction=float(particle_hash(seed))/4294967296.0;p.position=float4(p.position.xyz+p.velocity.xyz*(p.life.x*(1.0-fraction)),p.life.x*fraction);pool[id].position=p.position;pool[id].velocity=p.velocity;pool[id].color=p.color;pool[id].life=p.life;return}
 if(p.position.w<=0.0){let previous=atomicAdd(budget[0],-1);if(previous>0){p=spawn(id)}}
 else{
  if(p.life.y<0.5){p.velocity=float4((p.velocity.xyz+float3(0.0,sim.physics.y*dt,0.0))*max(1.0-sim.physics.z*dt,0.0),p.velocity.w)}elif(p.life.y<1.5){p.velocity=float4((p.velocity.xyz+float3(0.0,sim.physics.y*0.05*dt,0.0))*max(1.0-0.8*dt,0.0),p.velocity.w)}
  p.position=float4(p.position.xyz+p.velocity.xyz*dt,p.position.w-dt);let age=clamp(1.0-p.position.w/max(p.life.x,0.001),0.0,1.0)
  if(p.life.y<0.5){p.color=float4(float3(0.3,0.8,1.0)*(1.0-age*0.5)+float3(1.0)*age*0.5,1.0-smoothstep(0.6,1.0,age))}
  elif(p.life.y<1.5){var c=float3(0.6,0.1,0.0)*(1.0-(age-0.7)/0.3)+float3(0.05,0.02,0.01)*(age-0.7)/0.3
   if(age<0.3){c=float3(1.0,0.9,0.3)*(1.0-age/0.3)+float3(1.0,0.5,0.05)*(age/0.3)}elif(age<0.7){let t=(age-0.3)/0.4;c=float3(1.0,0.5,0.05)*(1.0-t)+float3(0.6,0.1,0.0)*t};p.color=float4(c,1.0-smoothstep(0.7,1.0,age))
  }else{p.color=float4(0.5,0.5,0.5,sim.extra.z*(1.0-smoothstep(0.3,1.0,age)));p.velocity=float4(p.velocity.xyz,p.life.z*(1.0+age*1.5))}
 };pool[id].position=p.position;pool[id].velocity=p.velocity;pool[id].color=p.color;pool[id].life=p.life
}
[vertex_shader(name="forge_particle_vertex"),sdl_shader_access(name="forge_particle_vertex")]
def particle_vs {
 let id=uint(gl_VertexIndex);let p=particle_data[id/6u];let k=id%6u
 let u=(k==0u || k==3u || k==5u) ? 0.0 : 1.0;let v=(k==0u || k==1u || k==3u) ? 0.0 : 1.0
 let world=p.position.xyz+(view_.right.xyz*(u-0.5)+view_.up.xyz*(v-0.5))*p.velocity.w
 gl_Position=p.position.w<=0.0 ? float4(0.0,0.0,0.0,1.0) : view_.vp*float4(world,1.0)
 let age=clamp(1.0-p.position.w/max(p.life.x,0.001),0.0,0.999);let frame=uint(age*16.0)
 uv_out=(float2(float(frame%4u),float(frame/4u))+float2(u,1.0-v))*0.25;color_out=p.color
}
[fragment_shader(name="forge_particle_fragment")]
def particle_fs {let texel=texture(atlas,uv_in);output_color=float4(texel.rgb*color_in.rgb,texel.a*color_in.a)}
