options gen2
module edge_shaders shared public
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct EdgeParams {texel : float4;config : float4}
var @uniform @set=3 @binding=0 edge : EdgeParams
var @set=2 @binding=0 depth_image : sampler2D
var @set=2 @binding=1 normal_image : sampler2D
var @set=2 @binding=2 color_image : sampler2D
var @in @location=0 uv : float2
var @out @location=0 color : float4
[fragment_shader(name="forge_edge_fragment")]
def edge_fs {
 var gx=0.0;var gy=0.0;var nx=float3(0);var ny=float3(0);var sky=false
 for(y in -1..2){for(x in -1..2){let coord=uv+float2(float(x),float(y))*edge.texel.xy;let d=textureLod(depth_image,coord,0.0).r;let n=textureLod(normal_image,coord,0.0).rgb
  if((x==0 && y==0) || (x!=0 && y!=0)){sky=sky || d>=0.999}
  let wx=float(x)*(y==0 ? 2.0 : 1.0);let wy=float(y)*(x==0 ? 2.0 : 1.0);gx+=d*wx;gy+=d*wy;nx+=n*wx;ny+=n*wy
 }}
 let depth_edge=smoothstep(edge.config.x,edge.config.x*2.0,sqrt(gx*gx+gy*gy));let normal_edge=smoothstep(edge.config.y,edge.config.y*2.0,sqrt(dot(nx,nx)+dot(ny,ny)))
 var amount=edge.config.z<0.5 ? depth_edge : (edge.config.z<1.5 ? normal_edge : max(depth_edge,normal_edge));if(sky || edge.config.w<0.5){amount=0.0}
 color=float4(texture(color_image,uv).rgb*(1.0-amount),1.0)
}
