options gen2
module planar_shaders shared public
require spirv/spirv_shader
require screen_shaders public
var @set=2 @binding=0 reflection_image : sampler2D
[fragment_shader(name="forge_planar_scene_fragment")]
def planar_scene_fs {
 let c=sampled_surface();let n=normalize(i_normal);let l=normalize(float3(0.4,0.7,0.5));let h=normalize(l+normalize(af.eye.xyz-i_world))
 result_color=float4(c.rgb*0.2+(c.rgb*max(dot(n,l),0.0)+float3(af.specular.x*pow(max(dot(n,h),0.0),af.specular.w)))*float3(1.0,0.95,0.85)*0.9*single_shadow(),c.a)
}
[vertex_shader(name="forge_water_vertex")]
def water_vs {let world=av.model*float4(a_position,1.0);gl_Position=av.vp*world;o_world=world.xyz}
[fragment_shader(name="forge_water_fragment")]
def water_fs {
 let uv=gl_FragCoord.xy/af.fog.xy;let reflection=texture(reflection_image,uv).rgb
 let v=normalize(af.eye.xyz-i_world);let fresnel=0.02+0.98*pow(1.0-max(v.y,0.0),5.0)
 let amount=af.shadow.z>0.5 ? fresnel : 0.0
 result_color=float4(float3(0.05,0.15,0.2)*(1.0-amount)+reflection*amount,0.6+0.4*fresnel)
}
