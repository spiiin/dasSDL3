options gen2
module dsl_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public

var @out @location = 0 vertex_color : float3
[vertex_shader(name="triangle_vertex")]
def triangle_vs {
    let positions = fixed_array(float2(-0.8, -0.8), float2(0.8, -0.8), float2(0.0, 0.8))
    gl_Position = float4(positions[gl_VertexIndex], 0.0, 1.0)
    vertex_color = float3(1.0, 1.0, 1.0)
}

struct Tint { color : float4 }
var @uniform @set = 3 @binding = 0 tint : Tint
var @in @location = 0 fragment_color : float3
var @out @location = 0 output_color : float4
[fragment_shader(name="triangle_fragment")]
def triangle_fs {
    output_color = float4(fragment_color, 1.0) * tint.color
}
