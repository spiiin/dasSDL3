options gen2
module uniform_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public

struct VertexParams { transform : float4x4 }
var @uniform @set = 1 @binding = 0 vertex_params : VertexParams
[vertex_shader(name="uniform_vertex")]
def uniform_vs {
    let positions = fixed_array(float2(-0.8, -0.8), float2(0.8, -0.8), float2(0.0, 0.8))
    gl_Position = vertex_params.transform * float4(positions[gl_VertexIndex], 0.0, 1.0)
}

struct ColorBias { rg : float2; blue : float }
struct UniformParams {
    gain : float
    tint : float3
    alpha : float
    weights : float[2]
    bias : ColorBias
    basis : float3x3
}
var @uniform @set = 3 @binding = 0 params : UniformParams
var @out @location = 0 output_color : float4
[fragment_shader(name="uniform_fragment")]
def uniform_fs {
    let color = params.tint * params.gain + float3(params.weights[0] + params.bias.rg.x, params.weights[1] + params.bias.rg.y, params.bias.blue)
    output_color = float4(params.basis * color, params.alpha)
}

def public example_uniforms(second : bool) : UniformParams {
    var value = UniformParams(gain = 0.5, tint = float3(0.2, 0.4, 0.6), alpha = 1.0, bias = ColorBias(rg = float2(0.05, 0.1), blue = 0.45))
    value.weights[0] = 0.1; value.weights[1] = 0.2
    value.basis[0] = float3(1.0, 0.0, 0.0)
    value.basis[1] = float3(0.0, 1.0, 0.0)
    value.basis[2] = float3(0.0, 0.0, 1.0)
    if (second) {
        value.basis[0] = float3(0.0, 0.0, 1.0)
        value.basis[2] = float3(1.0, 0.0, 0.0)
    }
    return value
}

def public example_vertex_uniforms() : VertexParams {
    var value : VertexParams
    value.transform[0] = float4(1.0, 0.0, 0.0, 0.0)
    value.transform[1] = float4(0.0, 1.0, 0.0, 0.0)
    value.transform[2] = float4(0.0, 0.0, 1.0, 0.0)
    value.transform[3] = float4(0.0, 0.0, 0.0, 1.0)
    return value
}
