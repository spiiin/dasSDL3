options gen2
module atlas_shaders shared public
require hdr_shaders public
require screen_shaders
require spirv/spirv_shader
[fragment_shader(name="forge_atlas_fragment")]
def atlas_fs {
 let uv=af.fog.xy+i_uv*af.fog.zw
 let c=texture(albedo,uv).rgb;let n=normalize(i_normal);let l=normalize(af.light.xyz);let h=normalize(l+normalize(af.eye.xyz-i_world))
 result_color=float4(c*af.ambient.rgb+(c*max(dot(n,l),0.0)+af.specular.rgb*pow(max(dot(n,h),0.0),af.specular.w))*single_shadow(),1.0)
}
