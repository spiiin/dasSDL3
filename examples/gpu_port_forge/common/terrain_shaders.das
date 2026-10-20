options gen2
module terrain_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require dassdl3/sdl3_shader_access
require advanced_shaders public
struct TerrainView {vp,light : float4x4;terrain,tile,morph : float4}
struct TerrainLight {eye,light,settings : float4}
struct PlantView {vp,light : float4x4;eye,wind,mode : float4}
struct PlantInstance {position,color,extra : float4}
var @uniform @set=1 @binding=0 terrain_view : TerrainView
var @uniform @set=3 @binding=0 terrain_light : TerrainLight
var @uniform @set=1 @binding=0 plant_view : PlantView
struct PlantColor {value : float4}
var @uniform @set=3 @binding=0 plant_color : PlantColor
var @set=0 @binding=0 height_vertex : sampler2D
var @set=2 @binding=0 height_fragment : sampler2D
var @set=2 @binding=1 terrain_shadow : sampler2D
var @set=2 @binding=0 plant_atlas : sampler2D
var @ssbo @readonly @set=0 @binding=0 plants : array<PlantInstance>
var @out @location=8 instance_color : float4
var @in @location=8 in_color : float4

def terrain_world : float4 {
 var uv=a_uv;var xz=a_position.xz*terrain_view.terrain.x
 if(terrain_view.tile.w>0.0){xz=a_position.xz*terrain_view.tile.z*0.5+terrain_view.tile.xy;uv=(xz+float2(terrain_view.terrain.x))/(2.0*terrain_view.terrain.x)
  let snapped=round(uv/terrain_view.morph.y)*terrain_view.morph.y;uv=uv*(1.0-terrain_view.morph.x)+snapped*terrain_view.morph.x;xz=uv*(2.0*terrain_view.terrain.x)-float2(terrain_view.terrain.x)
 };return float4(xz.x,textureLod(height_vertex,uv,0.0).r*terrain_view.terrain.y,xz.y,1.0)
}
[vertex_shader(name="forge_terrain_vertex")]
def terrain_vs {let world=terrain_world();gl_Position=terrain_view.vp*world;o_world=world.xyz;o_uv=(world.xz+float2(terrain_view.terrain.x))/(2.0*terrain_view.terrain.x);o_light0=terrain_view.light*world}
[vertex_shader(name="forge_terrain_shadow_vertex")]
def terrain_shadow_vs {gl_Position=terrain_view.vp*terrain_world()}
def terrain_pcf : float {
 let p=i_light0.xyz/i_light0.w;let uv=float2(p.x*.5+.5,.5-p.y*.5);if(min(uv.x,uv.y)<0.0 || max(uv.x,uv.y)>1.0){return 1.0}
 var result=0.0;for(y in 0..2){for(x in 0..2){result+=p.z-.002<=textureLod(terrain_shadow,uv+float2(float(x)-.5,float(y)-.5)/2048.0,0.0).r ? 1.0 : 0.0}};return result*.25
}
[fragment_shader(name="forge_terrain_fragment")]
def terrain_fs {
 let dx=(texture(height_fragment,i_uv+float2(1.0/256.0,0.0)).r-texture(height_fragment,i_uv-float2(1.0/256.0,0.0)).r)*terrain_light.settings.x*256.0/(4.0*terrain_light.settings.y)
 let dz=(texture(height_fragment,i_uv+float2(0.0,1.0/256.0)).r-texture(height_fragment,i_uv-float2(0.0,1.0/256.0)).r)*terrain_light.settings.x*256.0/(4.0*terrain_light.settings.y)
 let n=normalize(float3(-dx,1.0,-dz));let slope=1.0-n.y;let h=texture(height_fragment,i_uv).r
 let detail=i_world.xz*.8;let variation=fract(sin(dot(detail,float2(12.9898,78.233)))*43758.5453)-.5
 let rock=smoothstep(.3,.45,slope);var c=(float3(.22,.38,.15)+float3(variation*.06))*(1.0-rock)+(float3(.40,.35,.30)+float3(variation*.08))*rock
 let dirt=smoothstep(0.0,.15,slope)*(1.0-smoothstep(.3,.5,slope))*(1.0-smoothstep(.3,.5,h))*.5;c=c*(1.0-dirt)+float3(.35,.25,.18)*dirt
 let snow=smoothstep(terrain_light.settings.z,terrain_light.settings.z+.1,h)*(1.0-rock);c=c*(1.0-snow)+float3(.90,.92,.95)*snow
 let l=normalize(terrain_light.light.xyz);let shadow=terrain_pcf();let half_=normalize(l+normalize(terrain_light.eye.xyz-i_world));var lit=c*(.15+max(dot(n,l),0.0)*shadow)+float3(pow(max(dot(n,half_),0.0),32.0)*.2*rock*shadow)
 let fog=(1.0-exp(-length(i_world-terrain_light.eye.xyz)*.008))*.6;lit=lit*(1.0-fog)+float3(.55,.62,.75)*fog;result_color=float4(lit,1.0)
}

def plant_world : float4 {
 let instance=plants[gl_InstanceIndex];let pos=instance.position.xyz;let scale=instance.position.w;var local=a_position
 if(plant_view.mode.x>1.5){
  let t=a_position.y;let angle=instance.extra.x;let s=sin(angle);let c=cos(angle);local=float3(a_position.x*c,a_position.y,a_position.x*s)*float3(.06,instance.extra.z,.06)
  let phase=plant_view.wind.x*2.0+pos.x*.7+pos.z*.3;let bend=sin(phase)*plant_view.wind.y*t*t;let flutter=sin(phase*3.7+pos.x*2.3)*.15*t*t
  local=float3(local.x+.7071*(bend+flutter),local.y,local.z+.7071*(bend-flutter))
 }elif(plant_view.mode.x>.5){let toward=normalize(float3(plant_view.eye.x-pos.x,0.0,plant_view.eye.z-pos.z));let right=cross(float3(0.0,1.0,0.0),toward);local=right*a_position.x*1.1+float3(0.0,a_position.y*1.4,0.0)}
 return float4(pos+local*scale,1.0)
}
def plant_varyings {
 let instance=plants[gl_InstanceIndex];let world=plant_world();gl_Position=plant_view.vp*world;o_world=world.xyz;o_normal=a_normal;o_uv=a_uv;o_light0=plant_view.light*world;instance_color=instance.color
 if(plant_view.mode.x>.5 && plant_view.mode.x<1.5){let frame=instance.extra.y;o_uv=(float2((frame-floor(frame/4.0)*4.0),floor(frame/4.0))+a_uv)*float2(.25,.5)}
}
[vertex_shader(name="forge_plant_vertex"),sdl_shader_access(name="forge_plant_vertex")]
def plant_vs {let world=plant_world();gl_Position=plant_view.vp*world;o_normal=a_normal;instance_color=plants[gl_InstanceIndex].color}
[vertex_shader(name="forge_billboard_vertex"),sdl_shader_access(name="forge_billboard_vertex")]
def billboard_vs {
 gl_Position=plant_view.vp*plant_world();o_uv=a_uv;instance_color=plants[gl_InstanceIndex].color
 if(plant_view.mode.x>.5 && plant_view.mode.x<1.5){let frame=plants[gl_InstanceIndex].extra.y;o_uv=(float2(frame-floor(frame/4.0)*4.0,floor(frame/4.0))+a_uv)*float2(.25,.5)}
}
[vertex_shader(name="forge_grass_vertex"),sdl_shader_access(name="forge_grass_vertex")]
def grass_vs {let world=plant_world();gl_Position=plant_view.vp*world;o_world=world.xyz;o_uv=a_uv;instance_color=plants[gl_InstanceIndex].color}
[vertex_shader(name="forge_plant_shadow_vertex"),sdl_shader_access(name="forge_plant_shadow_vertex")]
def plant_shadow_vs {gl_Position=plant_view.vp*plant_world()}
[fragment_shader(name="forge_plant_fragment")]
def plant_fs {
 let color=plant_color.value.rgb*in_color.rgb;let dither=fract(52.9829189*fract(dot(gl_FragCoord.xy,float2(.06711056,.00583715))));if(dither>in_color.a){discard()}
 result_color=float4(color*(.3+.7*max(dot(normalize(i_normal),normalize(float3(.5,.8,.3))),0.0)),1.0)
}
[fragment_shader(name="forge_tree_billboard_fragment")]
def billboard_fs {let c=texture(plant_atlas,i_uv);let dither=fract(52.9829189*fract(dot(gl_FragCoord.xy,float2(.06711056,.00583715))));if(c.a<.5 || dither>in_color.a){discard()};result_color=float4(c.rgb*in_color.rgb,1.0)}
[fragment_shader(name="forge_grass_fragment")]
def grass_fs {
 let dither=fract(52.9829189*fract(dot(gl_FragCoord.xy,float2(.06711056,.00583715))));if(dither>in_color.a){discard()}
 let n=normalize(float3(sin(i_world.x),.2,cos(i_world.x)));let l=normalize(float3(.4,.8,.6));let diffuse=max(abs(dot(n,l)),.15);let shade=.35+.65*(1.0-i_uv.y);result_color=float4(in_color.rgb*(.15+diffuse)*shade,1.0)
}
