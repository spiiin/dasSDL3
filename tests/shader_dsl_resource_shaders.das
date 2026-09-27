options gen2
module shader_dsl_resource_shaders shared public
require dassdl3/sdl3_shader_access
var @ssbo @readonly @set = 0 @binding = 0 input_values : array<uint>
var @ssbo @set = 1 @binding = 0 output_values : array<uint>
[compute_shader(local_size_x=8, name="readonly_compute"), sdl_shader_access(name="readonly_compute")]
def readonly_cs {
    let i = gl_GlobalInvocationID.x
    output_values[i] = input_values[i] * 3u + 7u
}

struct StorageItem { rgb : float3; scale : float; extras : uint[2] }
var @set = 0 @binding = 0 cs_sample : sampler2D
var @readonly @set = 0 @binding = 1 cs_image : image2D
var @ssbo @readonly @set = 0 @binding = 2 cs_input : array<StorageItem>
var @writeonly @set = 1 @binding = 0 cs_output_image : image2D
var @ssbo @set = 1 @binding = 1 cs_output : array<StorageItem>
[compute_shader(local_size_x=4, local_size_y=4, name="resource_compute"), sdl_shader_access(name="resource_compute")]
def resources_cs {
    let x = gl_GlobalInvocationID.x; let y = gl_GlobalInvocationID.y; let i = y * 8u + x
    let sampled = textureLod(cs_sample, (float2(float(x), float(y)) + float2(0.5)) / 8.0, 0.0)
    let dims = imageSize(cs_image)
    let loaded = imageLoad(cs_image, int2(int(x) % dims.x, int(y) % dims.y))
    let color = sampled.xyz * 0.5 + loaded.xyz * 0.25 + cs_input[i].rgb * cs_input[i].scale
    imageStore(cs_output_image, int2(int(x), int(y)), float4(color, 1.0))
    cs_output[i].rgb = color
    cs_output[i].scale = cs_input[i].scale * 2.0
    cs_output[i].extras[0] = cs_input[i].extras[0] + 3u
    cs_output[i].extras[1] = cs_input[i].extras[1] + 7u
}

var @set = 0 @binding = 0 vs_sample : sampler2D
var @readonly @set = 0 @binding = 1 vs_image : image2D
var @ssbo @readonly @set = 0 @binding = 2 vs_input : array<StorageItem>
var @out @location = 0 vertex_contribution : float3
[vertex_shader(name="resource_vertex"), sdl_shader_access(name="resource_vertex")]
def resources_vs {
    let positions = fixed_array(float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0))
    gl_Position = float4(positions[gl_VertexIndex], 0.0, 1.0)
    vertex_contribution = textureLod(vs_sample, float2(0.25), 0.0).xyz * 0.125 + imageLoad(vs_image, int2(0)).xyz * 0.25 + vs_input[0].rgb * 0.125
}
var @set = 2 @binding = 0 fs_sample : sampler2D
var @readonly @set = 2 @binding = 1 fs_image : image2D
var @ssbo @readonly @set = 2 @binding = 2 fs_input : array<StorageItem>
var @in @location = 0 fragment_contribution : float3
var @out @location = 0 fragment_color : float4
[fragment_shader(name="resource_fragment"), sdl_shader_access(name="resource_fragment")]
def resources_fs {
    let coord = int2(gl_FragCoord.xy)
    let i = uint(coord.y * 8 + coord.x)
    let color = fragment_contribution * 0.25 + textureLod(fs_sample, gl_FragCoord.xy / 8.0, 0.0).xyz * 0.125 + imageLoad(fs_image, coord).xyz * 0.25 + fs_input[i].rgb * 0.25
    fragment_color = float4(color, 1.0)
}

var @set = 1 @binding = 0 rw_image : image2D
[compute_shader(local_size_x=4, local_size_y=4, name="rmw_compute"), sdl_shader_access(name="rmw_compute")]
def rmw_cs {
    let coord = int2(gl_GlobalInvocationID.xy)
    let old = imageLoad(rw_image, coord)
    imageStore(rw_image, coord, old.zyxw)
}
