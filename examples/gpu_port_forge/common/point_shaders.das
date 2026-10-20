options gen2
module point_shaders shared public
require spirv/spirv_shader
require advanced_shaders public
struct PointParams { base,eye,material,grid : float4; positions : float4[4]; colors : float4[4]; shadow : float4 }
var @uniform @set=3 @binding=0 point : PointParams
var @set=2 @binding=1 point_shadow0 : samplerCube
var @set=2 @binding=2 point_shadow1 : samplerCube
var @set=2 @binding=3 point_shadow2 : samplerCube
var @set=2 @binding=4 point_shadow3 : samplerCube
// A dedicated dense interstage signature is also accepted by D3D12's linker.
var @out @location=0 radial_world_out : float3
var @in @location=0 radial_world_in : float3
[vertex_shader(name="forge_radial_shadow_vertex")]
def radial_vs {let world=av.model*float4(a_position,1.0);gl_Position=av.vp*world;radial_world_out=world.xyz}
[fragment_shader(name="forge_radial_shadow_fragment")]
def radial_fs {result_color=float4(length(radial_world_in-point.eye.xyz)/point.shadow.x,0.0,0.0,1.0)}
def point_visibility(index : int; direction : float3) : float {
 if(point.shadow.y<0.5){return 1.0}
 var stored=0.0
 if(index==0){stored=textureLod(point_shadow0,direction,0.0).r}
 elif(index==1){stored=textureLod(point_shadow1,direction,0.0).r}
 elif(index==2){stored=textureLod(point_shadow2,direction,0.0).r}
 else{stored=textureLod(point_shadow3,direction,0.0).r}
 return length(direction)/point.shadow.x-0.002>stored ? 0.0 : 1.0
}
[fragment_shader(name="forge_point_fragment")]
def point_fs {
 var surface=point.base
 if(point.eye.w>0.5){surface*=texture(albedo,i_uv)}
 if(point.grid.w>0.5){
  let coord=i_world.xz;let fw=fwidth(coord);let distance=abs(fract(coord-float2(0.5))-float2(0.5))
  let line=float2(1.0)-smoothstep(float2(0.02),float2(0.02)+fw,distance)
  let mask=max(line.x,line.y)*(1.0-smoothstep(0.3,0.5,max(fw.x,fw.y)))*(1.0-smoothstep(20.0,40.0,length(i_world-point.eye.xyz)))
  surface=float4(point.grid.xyz*(1.0-mask)+point.base.rgb*mask,1.0)
 }
 let n=normalize(i_normal);let v=normalize(point.eye.xyz-i_world);var sum=surface.rgb*point.material.x
 for(i in 0..4){let delta=point.positions[i].xyz-i_world;let d=length(delta);let l=delta/d;let h=normalize(l+v)
  sum+=(surface.rgb*max(dot(n,l),0.0)+float3(point.material.y*pow(max(dot(n,h),0.0),point.material.z)))*point_visibility(i,-delta)*point.positions[i].w*point.colors[i].rgb/(1.0+0.35*d+0.44*d*d)
 }
 result_color=float4(sum,surface.a)
}
