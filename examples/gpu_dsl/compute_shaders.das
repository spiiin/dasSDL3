options gen2
module compute_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public

// Read and write the same storage buffer. SDL requires RW resources in set 1.
var @ssbo @set = 1 @binding = 0 values : array<uint>
struct ComputeParams { count : uint; factor : uint; bias : uint }
var @uniform @set = 2 @binding = 0 params : ComputeParams

[compute_shader(local_size_x=64, name="buffer_compute")]
def transform_values {
    let i = gl_GlobalInvocationID.x
    if (i < params.count) {values[i] = values[i] * params.factor + params.bias}
}
