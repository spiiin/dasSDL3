// Adapted from bgfx 30-picking; see the example README and group LICENSE-bgfx.txt.
options gen2
module picking_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4; object : float4 }
var @uniform @set = 1 @binding = 0 transform : Transform
var @out @location = 0 v_normal : float3
var @out @location = 1 v_object : float4
var @in @location = 0 position : float3
var @in @location = 1 normal : float3
var @in @location = 0 nrm : float3
var @in @location = 1 item : float4
var @out @location = 0 color : float4
[vertex_shader(name="picking_vertex")]
def vertex_main { gl_Position = transform.vp * transform.model * float4(position, 1.0); v_normal = (transform.model * float4(normal, 0.0)).xyz; v_object = transform.object }
var @out @location = 0 v_id : float
var @in @location = 0 object_id : float
[vertex_shader(name="picking_id_vertex")]
def id_vertex { gl_Position = transform.vp * transform.model * float4(position, 1.0); v_id = transform.object.x }
[fragment_shader(name="picking_id")]
def id_main { color = float4(object_id / 255.0, 0.0, 0.0, 1.0) }
[fragment_shader(name="picking_shaded")]
def shaded_main {
    let id = item.x; let base = float3(0.3 + 0.5 * abs(sin(id)), 0.3 + 0.5 * abs(sin(id * 2.1)), 0.3 + 0.5 * abs(sin(id * 3.7)))
    let light = 0.2 + 0.8 * max(dot(normalize(nrm), normalize(float3(-0.4, 0.8, -0.6))), 0.0)
    color = float4(item.y > 0.5 ? float3(1.0, 0.8, 0.1) * light : base * light, 1.0)
}
