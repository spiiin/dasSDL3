options gen2
module plasma_shaders shared public
// Altered DSL port of forge-gpu 11/plasma.comp.hlsl (Zlib).
require spirv/spirv_shader
require spirv/spirv_builtins public
require dassdl3/sdl3_shader_access
require math public
struct PlasmaParams { time : float; width, height : uint; padding : float }
var @uniform @set=2 @binding=0 plasma : PlasmaParams
var @writeonly @set=1 @binding=0 output_tex : image2D

def plasma_palette(t : float) : float3 {
    let segment=fract(t)*4.0;let index=int(segment);let f=fract(segment);let s=f*f*(3.0-2.0*f)
    let cyan=float3(0.063,0.533,0.871);let orange=float3(0.761,0.161,0.024)
    let green=float3(0.122,0.471,0.129);let purple=float3(0.395,0.055,0.481)
    if(index==0){return cyan*(1.0-s)+orange*s}
    if(index==1){return orange*(1.0-s)+green*s}
    if(index==2){return green*(1.0-s)+purple*s}
    return purple*(1.0-s)+cyan*s
}
def plasma_color(uv : float2; time : float) : float3 {
    let p=(uv-float2(0.5))*2.0;let r=length(p)
    let v=sin(p.x*3.0+time*1.2)+sin(p.y*4.0+time*0.8)+sin((p.x+p.y)*2.5+time*1.5)+sin(r*5.0-time*2.0)+sin(atan2(p.y,p.x)*3.0+r*4.0+time)
    let c=plasma_palette(v/10.0+0.5+time*0.1);let vignette=1.0-smoothstep(0.5,1.2,r)
    return float3(0.012,0.024,0.059)*(1.0-vignette)+c*vignette
}
[compute_shader(local_size_x=8,local_size_y=8,name="plasma_compute"),sdl_shader_access(name="plasma_compute")]
def plasma_cs {
    let id=gl_GlobalInvocationID
    if(id.x>=plasma.width || id.y>=plasma.height){return}
    let uv=float2(float(id.x)/float(plasma.width),float(id.y)/float(plasma.height))
    imageStore(output_tex,int2(int(id.x),int(id.y)),float4(plasma_color(uv,plasma.time),1.0))
}
