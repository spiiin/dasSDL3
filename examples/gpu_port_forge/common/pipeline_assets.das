options gen2
module pipeline_assets shared public
// Actual source FMSH v2/v3 reader and glTF 2.0 path used by lesson 39.
require animation_data public
require raw_bytes public
require daslib/json_boost
require strings
require daslib/defer
struct PipelineInfo {vertices,stride,lods,flags,submeshes : uint;vertex_offset,index_offset : int}
def pipeline_info(bytes : array<uint8>) {
 if(length(bytes)<32 || word(bytes,0)!=0x48534d46u || (word(bytes,4)!=2u && word(bytes,4)!=3u)){return err(SdlError(operation="FMSH",message="Invalid header"),type<PipelineInfo>)}
 var p=PipelineInfo(vertices=word(bytes,8),stride=word(bytes,12),lods=word(bytes,16),flags=word(bytes,20),submeshes=word(bytes,24))
 if(p.vertices==0u || p.vertices>1000000u || (p.stride!=32u && p.stride!=48u && p.stride!=56u && p.stride!=72u) || p.lods==0u || p.lods>16u || p.submeshes==0u || p.submeshes>1024u){return err(SdlError(operation="FMSH",message="Invalid counts/stride"),type<PipelineInfo>)}
 let end=32ul+uint64(p.lods)*(4ul+uint64(p.submeshes)*12ul)+uint64(p.vertices)*uint64(p.stride)
 if(end>uint64(length(bytes))){return err(SdlError(operation="FMSH",message="Truncated vertex table"),type<PipelineInfo>)}
 p.vertex_offset=32+int(p.lods*(4u+p.submeshes*12u));p.index_offset=int(end);return ok(p,type<SdlError>)
}
def mesh_from_bytes(device : SDL_GPUDevice?;vertices,indices : array<uint8>;count : uint) {
 var mesh=MeshBuffers(count=count);var success=false;defer(){if(!success){release(device,mesh)}}
 var vb=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=uint(length(vertices)))) |> sdl_try;mesh.vb=vb
 var ib=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_INDEX,size=uint(length(indices)))) |> sdl_try;mesh.ib=ib
 upload_bytes(device,mesh.vb,vertices) |> sdl_try;upload_bytes(device,mesh.ib,indices) |> sdl_try;success=true;return <- move_ok(mesh,type<SdlError>)
}
def load_pipeline_mesh(device : SDL_GPUDevice?;name : string;lod : uint=0u;submesh : uint=0u) {
 let bytes <- load_file(asset(name)) |> sdl_try;let info=pipeline_info(bytes) |> sdl_try
 if(lod>=info.lods || submesh>=info.submeshes){return err(SdlError(operation=name,message="LOD/submesh out of range"),type<MeshBuffers>)}
 let at=32+int(lod*(4u+info.submeshes*12u)+4u+submesh*12u);let count=word(bytes,at);let offset=word(bytes,at+4)
 if(count==0u || count>3000000u || count%3u!=0u || offset%4u!=0u || uint64(info.index_offset)+uint64(offset)+uint64(count)*4ul>uint64(length(bytes))){return err(SdlError(operation=name,message="Invalid index section"),type<MeshBuffers>)}
 var vertices,indices : array<uint8>;resize(vertices,int(info.vertices*32u));resize(indices,int(count*4u))
 for(i in 0u..info.vertices){for(j in 0..32){vertices[int(i*32u)+j]=bytes[info.vertex_offset+int(i*info.stride)+j]}}
 for(i in 0u..count){let ix=word(bytes,info.index_offset+int(offset+i*4u));if(ix>=info.vertices){return err(SdlError(operation=name,message="Index exceeds vertex count"),type<MeshBuffers>)};for(j in 0u..4u){indices[int(i*4u+j)]=uint8(ix>>(j*8u))}}
 return <- mesh_from_bytes(device,vertices,indices,count)
}
struct RawBuffer {uri : string;byteLength : int}
struct RawView {buffer,byteOffset,byteLength,byteStride : int}
struct RawAccessor {bufferView,byteOffset,componentType,count : int}
struct RawPrimitive {attributes : table<string;int>;indices : int}
struct RawMesh {primitives : array<RawPrimitive>}
struct RawNode {matrix : array<float>;rotation,translation,scale : array<float>}
struct RawGltf {buffers : array<RawBuffer>;bufferViews : array<RawView>;accessors : array<RawAccessor>;meshes : array<RawMesh>;nodes : array<RawNode>}
struct RawGpuMesh {mesh : MeshBuffers;model : float4x4}
def raw_offset(g : RawGltf;accessor,element,components : int;bytes : array<uint8>) {
 if(accessor<0 || accessor>=length(g.accessors)){return err(SdlError(operation="glTF",message="Accessor out of range"),type<int>)}
 let a=g.accessors[accessor];if(a.bufferView<0 || a.bufferView>=length(g.bufferViews) || element<0 || element>=a.count){return err(SdlError(operation="glTF",message="Invalid buffer view/element"),type<int>)}
 let v=g.bufferViews[a.bufferView];let size=a.componentType==5126 || a.componentType==5125 ? 4 : 2;let stride=v.byteStride>0 ? v.byteStride : components*size
 let at=int64(v.byteOffset)+int64(a.byteOffset)+int64(element)*int64(stride)
 if(v.buffer!=0 || at<0l || at+int64(components*size)>int64(length(bytes))){return err(SdlError(operation="glTF",message="Truncated accessor"),type<int>)};return ok(int(at),type<SdlError>)
}
def load_raw_gltf(device : SDL_GPUDevice?;folder,file : string) {
 let json_bytes <- load_file(asset("{folder}/{file}")) |> sdl_try;var error : string;var value=read_json(string(json_bytes),error)
 if(value==null){return err(SdlError(operation=file,message=error),type<RawGpuMesh>)}
 {defer(){unsafe{delete value}}
  let g <- from_JV(value,type<RawGltf>)
  if(length(g.buffers)!=1 || length(g.meshes)!=1 || length(g.meshes[0].primitives)!=1){return err(SdlError(operation=file,message="This raw comparison loader requires one buffer, one mesh and one triangle primitive"),type<RawGpuMesh>)}
  let bytes <- load_file(asset("{folder}/{g.buffers[0].uri}")) |> sdl_try
  let primitive & = unsafe(g.meshes[0].primitives[0]);let pos=primitive.attributes?["POSITION"] ?? -1;let norm=primitive.attributes?["NORMAL"] ?? -1;let uv=primitive.attributes?["TEXCOORD_0"] ?? -1
  if(pos<0 || norm<0 || uv<0 || pos>=length(g.accessors) || norm>=length(g.accessors) || uv>=length(g.accessors) || primitive.indices<0 || primitive.indices>=length(g.accessors)){return err(SdlError(operation=file,message="Missing vertex/index attributes"),type<RawGpuMesh>)}
  let nv=g.accessors[pos].count;let ni=g.accessors[primitive.indices].count
  if(nv<=0 || nv>1000000 || ni<=0 || ni>3000000 || ni%3!=0 || g.accessors[pos].componentType!=5126 || g.accessors[norm].componentType!=5126 || g.accessors[uv].componentType!=5126){return err(SdlError(operation=file,message="Unsupported counts/components"),type<RawGpuMesh>)}
  var vertices : array<float>;var indices : array<uint>
  for(i in 0..nv){let a=raw_offset(g,pos,i,3,bytes) |> sdl_try;let n=raw_offset(g,norm,i,3,bytes) |> sdl_try;let t=raw_offset(g,uv,i,2,bytes) |> sdl_try
   for(j in 0..3){push(vertices,read_float(bytes,a+j*4))};for(j in 0..3){push(vertices,read_float(bytes,n+j*4))};for(j in 0..2){push(vertices,read_float(bytes,t+j*4))}
  }
  let component=g.accessors[primitive.indices].componentType;if(component!=5123 && component!=5125){return err(SdlError(operation=file,message="Unsupported index type"),type<RawGpuMesh>)}
  for(i in 0..ni){let at=raw_offset(g,primitive.indices,i,1,bytes) |> sdl_try;let ix=component==5125 ? word(bytes,at) : uint(bytes[at])|(uint(bytes[at+1])<<8);if(ix>=uint(nv)){return err(SdlError(operation=file,message="Invalid vertex index"),type<RawGpuMesh>)};push(indices,ix)}
  let vertex_bytes <- packed_floats(vertices);let index_bytes <- packed_uints(indices);var mesh=mesh_from_bytes(device,vertex_bytes,index_bytes,uint(ni)) |> sdl_try
  var model=identity_matrix()
  // Both reference assets use a single mesh under a root transform.
  if(length(g.nodes)>0){let node & = unsafe(g.nodes[0]);if(length(node.matrix)==16){for(c in 0..4){model[c]=float4(node.matrix[c*4],node.matrix[c*4+1],node.matrix[c*4+2],node.matrix[c*4+3])}}
   else{let rotation=length(node.rotation)==4 ? float4(node.rotation[0],node.rotation[1],node.rotation[2],node.rotation[3]) : float4(0,0,0,1);model=trs_matrix(float3(0),rotation,float3(1))}
  };var result=RawGpuMesh(mesh=mesh,model=model);return <- move_ok(result,type<SdlError>)
 }
}
