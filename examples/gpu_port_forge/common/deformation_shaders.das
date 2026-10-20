options gen2
module deformation_shaders shared public
require dassdl3/sdl3_shader_access
require spirv/spirv_builtins public
require screen_shaders public
struct SkinWeight {joints : uint4;weights : float4}
struct JointColumns {c0,c1,c2,c3 : float4}
struct SkinMatrices {joints : JointColumns[128]}
var @ssbo @readonly @set=0 @binding=0 skin_weights : array<SkinWeight>
var @uniform @set=1 @binding=1 skin : SkinMatrices
var @ssbo @readonly @set=0 @binding=0 pulled_data : array<float4>
var @ssbo @readonly @set=0 @binding=1 skin_storage : array<JointColumns>
var @ssbo @readonly @set=0 @binding=0 morph_delta : array<float4>
def joint_transform(index : uint;p : float4) : float4 {return skin.joints[index].c0*p.x+skin.joints[index].c1*p.y+skin.joints[index].c2*p.z+skin.joints[index].c3*p.w}
def storage_transform(index : uint;p : float4) : float4 {return skin_storage[index].c0*p.x+skin_storage[index].c1*p.y+skin_storage[index].c2*p.z+skin_storage[index].c3*p.w}
def apply_skin(p : float4) : float4 {let w=skin_weights[gl_VertexIndex];return joint_transform(w.joints.x,p)*w.weights.x+joint_transform(w.joints.y,p)*w.weights.y+joint_transform(w.joints.z,p)*w.weights.z+joint_transform(w.joints.w,p)*w.weights.w}
def apply_storage_skin(p : float4) : float4 {let w=skin_weights[gl_VertexIndex];return storage_transform(w.joints.x,p)*w.weights.x+storage_transform(w.joints.y,p)*w.weights.y+storage_transform(w.joints.z,p)*w.weights.z+storage_transform(w.joints.w,p)*w.weights.w}
def deform_vertex(position,normal : float3;uv : float2) {
 let world=av.model*float4(position,1.0);gl_Position=av.vp*world;o_world=world.xyz;o_normal=(av.model*float4(normal,0.0)).xyz;o_uv=uv;o_light0=av.light0*world
}
[vertex_shader(name="forge_skin_vertex"),sdl_shader_access(name="forge_skin_vertex")]
def skin_vs {deform_vertex(apply_skin(float4(a_position,1.0)).xyz,apply_skin(float4(a_normal,0.0)).xyz,a_uv)}
[vertex_shader(name="forge_skin_shadow_vertex"),sdl_shader_access(name="forge_skin_shadow_vertex")]
def skin_shadow_vs {gl_Position=av.vp*av.model*apply_skin(float4(a_position,1.0))}
[vertex_shader(name="forge_storage_skin_vertex"),sdl_shader_access(name="forge_storage_skin_vertex")]
def storage_skin_vs {deform_vertex(apply_storage_skin(float4(a_position,1.0)).xyz,apply_storage_skin(float4(a_normal,0.0)).xyz,a_uv)}
[vertex_shader(name="forge_storage_skin_shadow_vertex"),sdl_shader_access(name="forge_storage_skin_shadow_vertex")]
def storage_skin_shadow_vs {gl_Position=av.vp*av.model*apply_storage_skin(float4(a_position,1.0))}
[vertex_shader(name="forge_pulled_vertex"),sdl_shader_access(name="forge_pulled_vertex")]
def pulled_vs {let a=pulled_data[gl_VertexIndex*2];let b=pulled_data[gl_VertexIndex*2+1];deform_vertex(a.xyz,float3(a.w,b.x,b.y),b.zw)}
[vertex_shader(name="forge_pulled_shadow_vertex"),sdl_shader_access(name="forge_pulled_shadow_vertex")]
def pulled_shadow_vs {gl_Position=av.vp*av.model*float4(pulled_data[gl_VertexIndex*2].xyz,1.0)}
[vertex_shader(name="forge_morph_vertex"),sdl_shader_access(name="forge_morph_vertex")]
def morph_vs {deform_vertex(a_position+morph_delta[gl_VertexIndex*2].xyz,a_normal+morph_delta[gl_VertexIndex*2+1].xyz,a_uv)}
[vertex_shader(name="forge_morph_shadow_vertex"),sdl_shader_access(name="forge_morph_shadow_vertex")]
def morph_shadow_vs {gl_Position=av.vp*av.model*float4(a_position+morph_delta[gl_VertexIndex*2].xyz,1.0)}

[fragment_shader(name="forge_model_fragment")]
def model_fs {
 var c=sampled_surface();if(af.controls.z>0.0){c=texture(albedo,fract(i_world.xz/120.0*af.controls.z))};if(af.controls.y==1.0 && c.a<af.shadow.w){discard()}
 let n=normalize(i_normal);let l=normalize(af.light.xyz);let h=normalize(l+normalize(af.eye.xyz-i_world))
 result_color=float4(c.rgb*af.ambient.rgb+(c.rgb*max(dot(n,l),0.0)+af.specular.rgb*pow(max(dot(n,h),0.0),af.specular.w))*af.fog_color.rgb*single_shadow(),c.a)
}

[fragment_shader(name="forge_studio_fragment")]
def studio_fs {result_color=float4(float3(0.05,0.05,0.15)*(1.0-i_uv.y)+float3(0.15,0.15,0.25)*i_uv.y,1.0)}
