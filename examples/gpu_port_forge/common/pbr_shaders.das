options gen2
module pbr_shaders shared public
require spirv/spirv_shader
require advanced_shaders public
struct PbrParams {base,eye,light,emissive,material,surface,config : float4}
var @uniform @set=3 @binding=0 pbr : PbrParams
var @set=2 @binding=0 base_map : sampler2D
var @set=2 @binding=1 normal_texture : sampler2D
var @set=2 @binding=2 mr_map : sampler2D
var @set=2 @binding=3 ao_map : sampler2D
var @set=2 @binding=4 emissive_map : sampler2D
var @set=2 @binding=5 shadow_map : sampler2D
[vertex_shader(name="forge_pbr_vertex")]
def pbr_vs {
 base_vertex();let n=normalize(o_normal);let v=(av.model*float4(a_tangent.xyz,0.0)).xyz;let t=normalize(v-n*dot(n,v))
 o_tangent=t;o_bitangent=cross(n,t)*a_tangent.w;o_light0=av.light0*float4(o_world,1.0)
}
def pbr_shadow : float {
 let pos=i_light0.xyz/i_light0.w;let uv=float2(pos.x*0.5+0.5,0.5-pos.y*0.5);if(uv.x<0.0 || uv.y<0.0 || uv.x>1.0 || uv.y>1.0){return 1.0}
 var s=0.0;for(y in -1..2){for(x in -1..2){s+=pos.z-0.005<=textureLod(shadow_map,uv+float2(float(x),float(y))/2048.0,0.0).r ? 1.0 : 0.0}};return s/9.0
}
[fragment_shader(name="forge_pbr_fragment")]
def pbr_fs {
 let base=texture(base_map,i_uv)*pbr.base;if(pbr.surface.w>0.0 && base.a<pbr.surface.w){discard()}
 let rg=(texture(normal_texture,i_uv).rg*2.0-float2(1))*pbr.material.z
 let mapped=normalize(float3(rg,sqrt(clamp(1.0-dot(rg,rg),0.0,1.0))))
 let n=normalize(normalize(i_tangent)*mapped.x+normalize(i_bitangent)*mapped.y+normalize(i_normal)*mapped.z)
 let mr=texture(mr_map,i_uv).bg;let metallic=mr.x*pbr.material.x;let roughness=max(mr.y*pbr.material.y,0.04)
 let ao=1.0+pbr.material.w*(texture(ao_map,i_uv).r-1.0);let emissive=texture(emissive_map,i_uv).rgb*pbr.emissive.rgb
 let l=normalize(pbr.light.xyz);let v=normalize(pbr.eye.xyz-i_world);let h=normalize(l+v)
 let nl=max(dot(n,l),0.0);let nv=max(dot(n,v),0.001);let nh=max(dot(n,h),0.0);let vh=max(dot(v,h),0.0)
 let shadow=pbr_shadow();var rgb=float3(0)
 if(pbr.config.x>0.5){
  let f0=float3(0.04)*(1.0-metallic)+base.rgb*metallic;let fresnel=f0+(float3(1)-f0)*pow(clamp(1.0-vh,0.0,1.0),5.0)
  let alpha=roughness*roughness;let alpha2=alpha*alpha;let denominator=nh*nh*(alpha2-1.0)+1.0
  let distribution=alpha2/max(3.14159265359*denominator*denominator,0.0001);let k=(roughness+1.0)*(roughness+1.0)/8.0
  let geometry=(nv/(nv*(1.0-k)+k))*(nl/(nl*(1.0-k)+k))
  let specular=distribution*geometry*fresnel/(4.0*nv*nl+0.0001);let diffuse=(float3(1)-fresnel)*(1.0-metallic)*base.rgb/3.14159265359
  rgb=pbr.surface.x*base.rgb*ao+(diffuse+specular)*nl*shadow+emissive
 }else{
  let diffuse=base.rgb*(1.0-metallic*0.7);let smoothness=1.0-roughness;let exponent=pbr.surface.y*max(smoothness,0.04)
  let specular=pbr.surface.z*smoothness*pow(nh,exponent)*(float3(1)*(1.0-metallic)+base.rgb*metallic)
  rgb=pbr.surface.x*diffuse*ao+shadow*(nl*diffuse+specular)+emissive
 };result_color=float4(rgb,base.a)
}
