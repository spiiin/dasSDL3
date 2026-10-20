options gen2
module indirect_shaders shared public
require dassdl3/sdl3_shader_access
require advanced_shaders public
struct IndirectObject {c0,c1,c2,c3,color,bounds : float4;draw : uint4}
struct CullParams {planes : float4[6];config : uint4}
var @ssbo @readonly @set=0 @binding=0 object_data : array<IndirectObject>
var @ssbo @writeonly @set=1 @binding=0 commands : array<uint>
var @ssbo @writeonly @set=1 @binding=1 visibility : array<uint>
var @uniform @set=2 @binding=0 cull : CullParams
var @in @location=3 object_id : uint
def object_transform(p : float4) : float4 {let obj=object_data[object_id];return obj.c0*p.x+obj.c1*p.y+obj.c2*p.z+obj.c3*p.w}
[compute_shader(local_size_x=64,name="forge_frustum_compute"),sdl_shader_access(name="forge_frustum_compute")]
def cull_cs {
 let id=gl_GlobalInvocationID.x;if(id>=cull.config.x){return};let obj=object_data[id];var visible=true
 if(cull.config.y!=0u){for(i in 0..6){let plane=cull.planes[i];if(dot(obj.bounds.xyz,plane.xyz)+plane.w< -obj.bounds.w){visible=false}}}
 commands[id*5u]=obj.draw.x;commands[id*5u+1u]=visible ? 1u : 0u;commands[id*5u+2u]=obj.draw.y;commands[id*5u+3u]=obj.draw.z;commands[id*5u+4u]=id;visibility[id]=visible ? 1u : 0u
}
[vertex_shader(name="forge_indirect_vertex"),sdl_shader_access(name="forge_indirect_vertex")]
def indirect_vs {
 let world=object_transform(float4(a_position,1.0));gl_Position=av.vp*world;o_world=world.xyz;o_uv=a_uv
 let obj=object_data[object_id];o_normal=cross(obj.c1.xyz,obj.c2.xyz)*a_normal.x+cross(obj.c2.xyz,obj.c0.xyz)*a_normal.y+cross(obj.c0.xyz,obj.c1.xyz)*a_normal.z;o_light0=av.light0*world
}
[vertex_shader(name="forge_indirect_shadow_vertex"),sdl_shader_access(name="forge_indirect_shadow_vertex")]
def indirect_shadow_vs {gl_Position=av.vp*object_transform(float4(a_position,1.0))}
