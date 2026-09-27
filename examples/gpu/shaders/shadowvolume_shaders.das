options gen2
module shadowvolume_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct VolumeTransform {
    view_projection : float4x4
    light_distance : float4
}
var @uniform @set = 1 @binding = 0 transform : VolumeTransform
var @in @location = 0 position : float4
var @out @location = 0 output_color : float4
[vertex_shader(name="volume_vertex")]
def volume_vs {
    var world = position.xyz
    if (position.w > 0.5) {
        world += normalize(world - transform.light_distance.xyz) * transform.light_distance.w
    }
    gl_Position = transform.view_projection * float4(world, 1.0)
}
[fragment_shader(name="volume_fragment")]
def volume_fs {
    output_color = float4(0.1, 0.8, 0.2, 0.1)
}
