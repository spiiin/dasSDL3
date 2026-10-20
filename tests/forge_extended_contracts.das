options gen2
options stack = 262144
require ../examples/gpu_port_forge/common/animation_data.das
require ../examples/gpu_port_forge/common/decal_app.das
require ../examples/gpu_port_forge/common/ui_app.das
require ../examples/gpu_port_forge/common/ftex_assets.das
require ../examples/gpu_port_forge/common/terrain_app.das
require ../examples/gpu_port_forge/common/indirect_shaders.das
require ../examples/gpu_port_forge/common/particle_shaders.das
require dassdl3/sdl3_shader_resources
require dassdl3/sdl3_shader_compute
require daslib/math_bits
require daslib/defer

def animation_contract {
 var linear=AnimChannel(components=1,times <- array(0.0,2.0),values <- array(2.0,6.0))
 verify(abs(channel_component(linear,0,0,1.0,.5)-4.0)<1e-5)
 linear.interpolation=1;verify(channel_component(linear,0,0,1.0,.5)==2.0)
 linear.interpolation=2;linear.values <- array(0.0,2.0,2.0,0.0,6.0,0.0)
 verify(abs(channel_component(linear,0,0,1.0,.5)-4.5)<1e-5)
 let q=animation_slerp(float4(0,0,0,1),float4(0,0,0,-1),.5);verify(length(q-float4(0,0,0,1))<1e-5)
 var data=AnimationData(nodes <- array(AnimNode(translation=float3(1,2,3)),AnimNode(parent=0,translation=float3(4,0,0))),order <- array(0,1))
 var pose : AnimationPose;evaluate_animation(data,pose,0.0);verify(length(pose.world[1][3]-float4(5,2,3,1))<1e-5)
}

def loaded_animation_contract : SdlStatus {
 for(name in fixed_array("cesiumman","brainstem","animated_truck","morph_cube","simple_morph")){
  let data <- read_animation(name) |> sdl_try;var a,b : AnimationPose;evaluate_animation(data,a,0.0);evaluate_animation(data,b,.5)
  verify(length(a.world)==length(data.nodes));var changed=false
  for(i in 0..length(a.world)){for(col in 0..4){let delta=length(a.world[i][col]-b.world[i][col]);verify(delta>=0.0 && delta<10000.0);if(delta>1e-5){changed=true}}}
  for(i in 0..length(a.weights)){for(j in 0..length(a.weights[i])){if(abs(a.weights[i][j]-b.weights[i][j])>1e-5){changed=true}}}
  verify(changed);for(skin in data.skins){verify(length(skin.joints)>0 && length(skin.joints)<=128)}
 };return sdl_ok()
}

def ftex_contract : SdlStatus {
 let valid <- load_file(asset("pbr_flat_normal.ftex")) |> sdl_try;let meta=ftex_info(valid) |> sdl_try
 verify(meta.format==3u && meta.width==4u && meta.height==4u && meta.levels==3u && meta.payload==48ul)
 var corrupt <- clone(valid);corrupt[0]=0u8;verify(is_err(ftex_info(corrupt)))
 corrupt <- clone(valid);resize(corrupt,length(corrupt)-1);verify(is_err(ftex_info(corrupt)))
 corrupt <- clone(valid);corrupt[32]=0u8;corrupt[33]=0u8;verify(is_err(ftex_info(corrupt)))
 var empty : array<uint8>;verify(is_err(ftex_info(empty)))
 return sdl_ok()
}

def terrain_contract : SdlStatus {
 var r=TerrainRender();let bytes <- load_file(asset("terrain_48.f32")) |> sdl_try;resize(r.heights,256*256)
 var lo=1.0;var hi=0.0;for(i in 0..length(r.heights)){r.heights[i]=read_float(bytes,i*4);lo=min(lo,r.heights[i]);hi=max(hi,r.heights[i])};verify(lo==0.0 && hi==1.0)
 let center=height_at(r,0.0,0.0);let expected=(r.heights[127*256+127]+r.heights[127*256+128]+r.heights[128*256+127]+r.heights[128*256+128])*.25*r.height_scale;verify(abs(center-expected)<1e-5)
 let trees <- tree_instances(r,48);verify(length(trees)>100 && length(trees)<=2000)
 for(tree in trees){verify(abs(tree.position.y-height_at(r,tree.position.x,tree.position.z))<1e-5);verify(slope_at(r,tree.position.x,tree.position.z)<=.4)}
 return sdl_ok()
}

[export]
def main(smoke : bool) : int {
 animation_contract()
 var seed=decal_hash(0xDECA1u);let first=decal_random(seed);let second=decal_random(seed);verify(first!=second)
 let volumes <- make_decal_volumes();verify(length(volumes)==87);verify(length(volumes[0].model[3]-volumes[1].model[3])>.01)
 var ui=UiBatch(down=true,mouse=float2(75,10));var slider=0.0;ui_slider(ui,float4(0,0,100,20),slider,0.0,1.0);verify(abs(slider-.75)<1e-5)
 let result=sdl_scope(){with_sdl() |> sdl_use;loaded_animation_contract() |> sdl_try;ftex_contract() |> sdl_try;terrain_contract() |> sdl_try
  let vertex=gpu_dsl_resource_info(forge_indirect_vertex_reflect,forge_indirect_vertex_access,1u) |> sdl_try;verify(vertex.num_readonly_storage_buffers==1u)
  let compute=gpu_dsl_compute_info(forge_particle_compute_reflect,forge_particle_compute_access) |> sdl_try;verify(compute.num_readwrite_storage_buffers==2u && compute.threadcount_x==256u)
  return sdl_ok()
 }
 if(is_err(result)){let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
 print("Forge extended: interpolation, hierarchy, real animation channels, FTEX bounds, terrain placement, scalar-reference UI/PRNG and shader contracts PASS.\n");return 0
}
