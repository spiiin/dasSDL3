options gen2
module texture_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public

var @out @location = 0 vertex_uv : float2
[vertex_shader(name="texture_vertex")]
def texture_vs {
    let positions = fixed_array(float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0))
    let pos = positions[gl_VertexIndex]
    gl_Position = float4(pos, 0.0, 1.0)
    vertex_uv = float2(pos.x + 1.0, 1.0 - pos.y) * 0.5
}

struct TextureTint { color : float4 }
var @uniform @set = 3 @binding = 0 tint : TextureTint
var @set = 2 @binding = 0 checker : sampler2D
var @in @location = 0 fragment_uv : float2
var @out @location = 0 output_color : float4
[fragment_shader(name="texture_fragment")]
def texture_fs {
    output_color = texture(checker, fragment_uv) * tint.color
}
