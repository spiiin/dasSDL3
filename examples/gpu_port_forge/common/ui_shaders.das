options gen2
module ui_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct UiProjection { matrix : float4x4 }
var @uniform @set=1 @binding=0 projection : UiProjection
var @in @location=0 position : float2
var @in @location=1 texcoord : float2
var @in @location=2 color_rg : float2
var @in @location=3 color_ba : float2
var @out @location=0 out_uv : float2
var @out @location=1 out_color : float4
var @in @location=0 uv : float2
var @in @location=1 vertex_color : float4
var @set=2 @binding=0 font_atlas : sampler2D
var @out @location=0 output_color : float4
[vertex_shader(name="forge_ui_vertex")]
def ui_vs {gl_Position=projection.matrix*float4(position,0.0,1.0);out_uv=texcoord;out_color=float4(color_rg,color_ba)}
def srgb_decode(c : float) : float {return c<=0.04045 ? c/12.92 : pow((c+0.055)/1.055,2.4)}
[fragment_shader(name="forge_ui_fragment")]
def ui_fs {output_color=float4(srgb_decode(vertex_color.r),srgb_decode(vertex_color.g),srgb_decode(vertex_color.b),vertex_color.a*texture(font_atlas,uv).r)}
