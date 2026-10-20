options gen2
module stencil_shaders shared public
require spirv/spirv_shader
require advanced_shaders public
[fragment_shader(name="forge_flat_fragment")]
def flat_fs {result_color=af.base}
[fragment_shader(name="forge_ghost_fragment")]
def ghost_fs {let rim=pow(1.0-abs(dot(normalize(i_normal),normalize(af.eye.xyz-i_world))),2.0);result_color=float4(af.base.rgb*rim,af.base.a*rim)}
[fragment_shader(name="forge_id_fragment")]
def id_fs {let id=uint(af.controls.x);result_color=float4(float(id&255u)/255.0,float((id>>8u)&255u)/255.0,float((id>>16u)&255u)/255.0,1.0)}

// Emit only the two varyings consumed by the ghost fragment shader.
[vertex_shader(name="forge_ghost_vertex")]
def ghost_vs {let world=av.model*float4(a_position,1.0);gl_Position=av.vp*world;o_world=world.xyz;o_normal=(av.model*float4(a_normal,0.0)).xyz}
