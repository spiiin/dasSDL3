options gen2
module scene_shaders shared public
// Altered DSL port of forge-gpu lessons 10, 12, 13 and 14 (Zlib).
require spirv/spirv_shader
require spirv/spirv_builtins public
require math public
struct Transform { model, vp : float4x4 }
struct Lighting { base_color, light_dir, eye_pos : float4; has_texture : uint; shininess : float; ambient : float; specular : float; reflectivity : float; padding : float3 }
struct GridParams { line_color, bg_color, light_dir, eye_pos : float4; spacing : float; line_width : float; fade_distance : float; ambient : float; shininess : float; specular : float; padding : float2 }
struct SkyParams { right, up, forward : float4 }
var @uniform @set=1 @binding=0 transform : Transform
var @uniform @set=3 @binding=0 lighting : Lighting
var @in @location=0 position : float3
var @in @location=1 normal : float3
var @in @location=2 texcoord : float2
var @in @location=3 model_c0 : float4
var @in @location=4 model_c1 : float4
var @in @location=5 model_c2 : float4
var @in @location=6 model_c3 : float4
var @out @location=0 v_uv : float2
var @out @location=1 v_normal : float3
var @out @location=2 v_world : float3
var @in @location=0 f_uv : float2
var @in @location=1 f_normal : float3
var @in @location=2 f_world : float3
var @out @location=0 color : float4
var @set=2 @binding=0 diffuse_tex : sampler2D
var @set=2 @binding=1 env_tex : samplerCube

def transformed_normal(c0,c1,c2,n : float3) : float3 {
    // Cofactor matrix = inverse transpose up to the determinant. Positive scales.
    return cross(c1,c2)*n.x + cross(c2,c0)*n.y + cross(c0,c1)*n.z
}
[vertex_shader(name="lit_vertex")]
def lit_vs {
    let wp = transform.model * float4(position,1.0)
    gl_Position = transform.vp * wp
    v_world = wp.xyz
    v_normal = transformed_normal(transform.model[0].xyz,transform.model[1].xyz,transform.model[2].xyz,normal)
    v_uv = texcoord
}
[vertex_shader(name="instanced_vertex")]
def instanced_vs {
    let wp = model_c0*position.x + model_c1*position.y + model_c2*position.z + model_c3
    gl_Position = transform.vp * wp
    v_world = wp.xyz; v_uv = texcoord
    v_normal = transformed_normal(model_c0.xyz,model_c1.xyz,model_c2.xyz,normal)
}
def surface_color : float4 {
    var c = lighting.base_color
    if (lighting.has_texture != 0u) { c *= texture(diffuse_tex,f_uv) }
    return c
}
def blinn(surface,n,v : float3) : float3 {
    let l=normalize(lighting.light_dir.xyz)
    let h=normalize(l+v)
    return (lighting.ambient+max(dot(n,l),0.0))*surface + float3(lighting.specular*pow(max(dot(n,h),0.0),lighting.shininess))
}
[fragment_shader(name="lit_fragment")]
def lit_fs {
    let c=surface_color()
    color=float4(blinn(c.rgb,normalize(f_normal),normalize(lighting.eye_pos.xyz-f_world)),c.a)
}
[fragment_shader(name="environment_fragment")]
def env_fs {
    let c=surface_color();let n=normalize(f_normal);let v=normalize(lighting.eye_pos.xyz-f_world)
    let reflected=texture(env_tex,reflect(-v,n)).rgb
    let mixed=c.rgb*(1.0-lighting.reflectivity)+reflected*lighting.reflectivity
    color=float4(blinn(mixed,n,v),c.a)
}
var @uniform @set=3 @binding=0 grid : GridParams
[fragment_shader(name="grid_fragment")]
def grid_fs {
    let uv=f_world.xz/grid.spacing
    let dist=abs(fract(uv-float2(0.5))-float2(0.5))
    let fw=fwidth(uv)
    let aa=float2(1.0)-smoothstep(float2(grid.line_width),float2(grid.line_width)+fw,dist)
    var mask=max(aa.x,aa.y)
    mask *= 1.0-smoothstep(0.3,0.5,max(fw.x,fw.y))
    mask *= 1.0-smoothstep(grid.fade_distance*0.5,grid.fade_distance,length(f_world-grid.eye_pos.xyz))
    let surface=grid.bg_color.rgb*(1.0-mask)+grid.line_color.rgb*mask
    let l=normalize(grid.light_dir.xyz);let v=normalize(grid.eye_pos.xyz-f_world);let h=normalize(l+v)
    color=float4((grid.ambient+max(l.y,0.0))*surface+float3(grid.specular*pow(max(h.y,0.0),grid.shininess)),1.0)
}
var @uniform @set=3 @binding=0 sky : SkyParams
var @set=2 @binding=0 sky_tex : samplerCube
[vertex_shader(name="fullscreen_vertex")]
def fullscreen_vs {
    let t=float2(float((gl_VertexIndex<<1)&2),float(gl_VertexIndex&2))
    gl_Position=float4(t.x*2.0-1.0,1.0-t.y*2.0,0.0,1.0);v_uv=t
}
[fragment_shader(name="sky_fragment")]
def sky_fs {
    let direction=sky.forward.xyz+sky.right.xyz*(f_uv.x*2.0-1.0)+sky.up.xyz*(1.0-f_uv.y*2.0)
    color=texture(sky_tex,direction)
}
var @set=2 @binding=0 screen_tex : sampler2D
[fragment_shader(name="fullscreen_fragment")]
def fullscreen_fs { color=texture(screen_tex,f_uv) }

[vertex_shader(name="grid_vertex")]
def grid_vs {
    let vertices=fixed_array(float2(-50.0,-50.0),float2(50.0,-50.0),float2(-50.0,50.0),float2(-50.0,50.0),float2(50.0,-50.0),float2(50.0,50.0))
    let xy=vertices[gl_VertexIndex];v_world=float3(xy.x,0.0,xy.y);gl_Position=transform.vp*float4(v_world,1.0)
}
