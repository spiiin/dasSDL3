options gen2
module advanced_shaders shared public
// Altered shader DSL ports of forge-gpu lessons 15-20 (Zlib).
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct AdvancedVertex { model,vp,light0,light1,light2 : float4x4 }
struct AdvancedFragment {
    base,light,eye,ambient,diffuse,specular : float4
    fog_color,fog,controls,splits,shadow : float4
}
var @uniform @set=1 @binding=0 av : AdvancedVertex
var @uniform @set=3 @binding=0 af : AdvancedFragment
var @in @location=0 a_position : float3
var @in @location=1 a_normal : float3
var @in @location=2 a_uv : float2
var @in @location=3 a_tangent : float4
var @out @location=0 o_uv : float2
var @out @location=1 o_normal : float3
var @out @location=2 o_world : float3
var @out @location=3 o_light0 : float4
var @out @location=4 o_light1 : float4
var @out @location=5 o_light2 : float4
var @out @location=6 o_tangent : float3
var @out @location=7 o_bitangent : float3
var @in @location=0 i_uv : float2
var @in @location=1 i_normal : float3
var @in @location=2 i_world : float3
var @in @location=3 i_light0 : float4
var @in @location=4 i_light1 : float4
var @in @location=5 i_light2 : float4
var @in @location=6 i_tangent : float3
var @in @location=7 i_bitangent : float3
var @out @location=0 result_color : float4
var @set=2 @binding=0 albedo : sampler2D
var @set=2 @binding=1 normal_map : sampler2D
var @set=2 @binding=1 cascade0 : sampler2D
var @set=2 @binding=2 cascade1 : sampler2D
var @set=2 @binding=3 cascade2 : sampler2D

def base_vertex {
    let world=av.model*float4(a_position,1.0)
    gl_Position=av.vp*world
    o_world=world.xyz; o_uv=a_uv
    o_normal=cross(av.model[1].xyz,av.model[2].xyz)*a_normal.x+cross(av.model[2].xyz,av.model[0].xyz)*a_normal.y+cross(av.model[0].xyz,av.model[1].xyz)*a_normal.z
}
[vertex_shader(name="advanced_vertex")]
def advanced_vs { base_vertex() }
[vertex_shader(name="cascade_vertex")]
def cascade_vs {
    base_vertex()
    let world=float4(o_world,1.0)
    o_light0=av.light0*world; o_light1=av.light1*world; o_light2=av.light2*world
}
[vertex_shader(name="advanced_grid_vertex")]
def advanced_grid_vs { let world=av.model*float4(a_position,1.0);o_world=world.xyz;gl_Position=av.vp*world }
[vertex_shader(name="normal_vertex")]
def normal_vs {
    base_vertex()
    let n=normalize(o_normal)
    let transformed=av.model*float4(a_tangent.xyz,0.0)
    let t=normalize(transformed.xyz-n*dot(n,transformed.xyz))
    o_normal=n; o_tangent=t; o_bitangent=cross(n,t)*a_tangent.w
}
[vertex_shader(name="shadow_vertex")]
def shadow_vs { gl_Position=av.vp*av.model*float4(a_position,1.0) }
[fragment_shader(name="shadow_fragment")]
def shadow_fs { }

def grid_surface : float3 {
    let uv=i_world.xz
    let fw=fwidth(uv)
    let distance=abs(fract(uv-float2(0.5))-float2(0.5))
    var mask=0.0
    if(af.controls.w!=15.0){
        let d=distance/fw; mask=1.0-clamp(min(d.x,d.y),0.0,1.0)
    }else{
        let aa=float2(1.0)-smoothstep(float2(0.02),float2(0.02)+fw,distance);mask=max(aa.x,aa.y)
    }
    mask*=1.0-smoothstep(0.3,0.5,max(fw.x,fw.y))
    let d=af.controls.w==15.0 ? length(i_world-af.eye.xyz) : length(i_world.xz-af.eye.xz)
    mask*=1.0-smoothstep(20.0,40.0,d)
    return af.diffuse.rgb*(1.0-mask)+af.base.rgb*mask
}
def sampled_surface : float4 {
    var c=af.base
    if(af.controls.x>0.5){c*=texture(albedo,i_uv)}
    if(af.controls.w>0.0){c=float4(grid_surface(),1.0)}
    return c
}
def lighting(n,surface : float3; shadow : float=1.0) : float3 {
    let l=normalize(af.light.xyz); let v=normalize(af.eye.xyz-i_world);let h=normalize(l+v)
    return af.ambient.rgb*surface+shadow*(max(dot(n,l),0.0)*surface+af.specular.rgb*pow(max(dot(n,h),0.0),af.specular.w))
}
[fragment_shader(name="blend_fragment")]
def blend_fs {
    let c=sampled_surface()
    if(af.controls.y==1.0 && c.a<af.shadow.w){discard()}
    result_color=float4(lighting(normalize(i_normal),c.rgb),c.a)
}
[fragment_shader(name="normal_fragment")]
def normal_fs {
    let c=sampled_surface();var n=normalize(i_normal)
    if(af.controls.z<0.5){n=normalize(cross(dFdx(i_world),dFdy(i_world)))}
    elif(af.controls.z>1.5 && af.shadow.z>0.5){
        let map=texture(normal_map,i_uv).rgb*2.0-float3(1.0)
        n=normalize(normalize(i_tangent)*map.x+normalize(i_bitangent)*map.y+n*map.z)
    }
    result_color=float4(lighting(n,c.rgb),c.a)
}
def material_lighting : float3 {
    var surface=af.diffuse.rgb
    if(af.controls.x>0.5){surface*=texture(albedo,i_uv).rgb}
    let n=normalize(i_normal);let l=normalize(af.light.xyz);let v=normalize(af.eye.xyz-i_world);let h=normalize(l+v)
    return af.ambient.rgb+max(dot(n,l),0.0)*surface+af.specular.rgb*pow(max(dot(n,h),0.0),af.specular.w)
}
[fragment_shader(name="material_fragment")]
def material_fs { result_color=float4(material_lighting(),1.0) }
def fog_factor : float {
    if(af.fog.w<0.0){return 1.0}
    let d=length(af.eye.xyz-i_world)
    if(af.fog.w<0.5){return clamp((af.fog.y-d)/(af.fog.y-af.fog.x),0.0,1.0)}
    let v=af.fog.z*d
    return exp(af.fog.w<1.5 ? -v : -v*v)
}
[fragment_shader(name="fog_fragment")]
def fog_fs {
    let c=af.controls.w>0.0 ? lighting(float3(0,1,0),grid_surface()) : material_lighting()
    let factor=fog_factor()
    result_color=float4(af.fog_color.rgb*(1.0-factor)+c*factor,1.0)
}
[fragment_shader(name="advanced_grid_fragment")]
def advanced_grid_fs {result_color=float4(lighting(float3(0,1,0),grid_surface()),1.0)}
def pcf0( projected : float4) : float {
    let p=projected.xyz/projected.w;let uv=float2(p.x*0.5+0.5,0.5-p.y*0.5)
    var total=0.0
    for(y in -1..2){for(x in -1..2){
        let depth=textureLod(cascade0,uv+float2(float(x),float(y))*af.shadow.x,0.0).r
        total+=depth>=p.z-af.shadow.y ? 1.0 : 0.0
    }}
    return total/9.0
}
def pcf1( projected : float4) : float {
    let p=projected.xyz/projected.w;let uv=float2(p.x*0.5+0.5,0.5-p.y*0.5)
    var total=0.0
    for(y in -1..2){for(x in -1..2){
        let depth=textureLod(cascade1,uv+float2(float(x),float(y))*af.shadow.x,0.0).r
        total+=depth>=p.z-af.shadow.y ? 1.0 : 0.0
    }}
    return total/9.0
}
def pcf2( projected : float4) : float {
    let p=projected.xyz/projected.w;let uv=float2(p.x*0.5+0.5,0.5-p.y*0.5)
    var total=0.0
    for(y in -1..2){for(x in -1..2){
        let depth=textureLod(cascade2,uv+float2(float(x),float(y))*af.shadow.x,0.0).r
        total+=depth>=p.z-af.shadow.y ? 1.0 : 0.0
    }}
    return total/9.0
}
[fragment_shader(name="cascade_fragment")]
def cascade_fs {
    let c=sampled_surface();let distance=length(af.eye.xyz-i_world);var shadow=1.0
    if(af.shadow.z>0.5){
        if(distance<af.splits.x){shadow=pcf0(i_light0)}
        elif(distance<af.splits.y){shadow=pcf1(i_light1)}
        elif(distance<af.splits.z){shadow=pcf2(i_light2)}
    }
    result_color=float4(lighting(normalize(i_normal),c.rgb,shadow),c.a)
}
var @in @location=1 line_color : float4
var @out @location=0 line_out : float4
var @in @location=0 line_in : float4
[vertex_shader(name="debug_line_vertex")]
def line_vs {gl_Position=av.vp*float4(a_position,1.0);line_out=line_color}
[fragment_shader(name="debug_line_fragment")]
def line_fs {result_color=line_in}
[vertex_shader(name="depth_preview_vertex")]
def preview_vs {
    let t=float2(float((gl_VertexIndex<<1)&2),float(gl_VertexIndex&2))
    gl_Position=float4(t.x*2.0-1.0,1.0-t.y*2.0,0.0,1.0);o_uv=t
}
[fragment_shader(name="depth_preview_fragment")]
def preview_fs {result_color=float4(float3(texture(albedo,i_uv).r),1.0)}
