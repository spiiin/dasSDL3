options gen2
module forge_support shared public
// Application-local operations for these five ports. No public renderer framework.
require ../../gpu_dsl/backend_support.das public
require dassdl3/sdl3_scope public
require dassdl3/sdl3_gpu_native_boost public
require dassdl3/sdl3_gpu_pipeline_boost public
require dassdl3/sdl3_gpu_sampler_boost public
require dassdl3/sdl3_shader_uniforms public
require dassdl3/sdl3_pixels_boost public
require dassdl3/sdl3_iostream_boost public
require dassdl3/sdl3_events public
require dassdl3/sdl3_init_boost
require daslib/math_boost public
require daslib/math_bits
require daslib/defer
require math public

def asset(name : string) : string {return "{SDL_GetBasePath()}assets/forge/{name}"}
def failure(operation,message : string) : SdlStatus {return err(SdlError(operation=operation,message=message),type<SdlUnit>)}
def identity_matrix : float4x4 {var m : float4x4;identity(m);return m}
def model_matrix(position : float3; scale : float3; angle : float=0.0) : float4x4 {
    let c=cos(angle);let s=sin(angle)
    var m : float4x4
    m[0]=float4(c*scale.x,0.0,s*scale.x,0.0);m[1]=float4(0.0,scale.y,0.0,0.0)
    m[2]=float4(-s*scale.z,0.0,c*scale.z,0.0);m[3]=float4(position,1.0);return m
}
def camera_matrix(width,height : uint; eye,at : float3) : float4x4 {
    let q=200.0/199.9;var p : float4x4
    p[0].x=1.7320508*float(height)/float(width);p[1].y=1.7320508
    p[2]=float4(0.0,0.0,q,1.0);p[3].z=-0.1*q
    return p*look_at_lh(eye,at,float3(0.0,1.0,0.0))
}
def texture(device : SDL_GPUDevice?; width,height : uint; usage : uint; cube : bool=false; srgb : bool=false) {
    var info=gpu_texture(width,height,srgb ? SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB : SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM,usage)
    if(cube){info <- info |> texture_shape(SDL_GPUTextureType.TEXTURETYPE_CUBE,6u)}
    var t=SDL_CreateGPUTextureRef(device,info)
    if(t==null){return err(sdl_error("SDL_CreateGPUTexture"),type<SDL_GPUTexture?>)}
    return <- move_ok(t,type<SdlError>)
}
def upload_bytes(device : SDL_GPUDevice?; var buffer : SDL_GPUBuffer?; bytes : array<uint8>) : SdlStatus {
    let size=uint(length(bytes))
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=size)) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device,transfer,size,0u,bytes,false),"SDL_WriteGPUTransferBufferBytes") |> sdl_try
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var copy_pass) {
            SDL_UploadToGPUBufferRef(copy_pass,SDL_GPUTransferBufferLocation(transfer_buffer=transfer),SDL_GPUBufferRegion(buffer=buffer,size=size),false)
            return sdl_ok()
        } |> sdl_try
        return native_gpu_submit(command)
    }
}
struct MeshBuffers { vb,ib : SDL_GPUBuffer?; count : uint }
def release(device : SDL_GPUDevice?; var mesh : MeshBuffers) {
    if(mesh.vb!=null){SDL_ReleaseGPUBuffer(device,mesh.vb);mesh.vb=null}
    if(mesh.ib!=null){SDL_ReleaseGPUBuffer(device,mesh.ib);mesh.ib=null}
}
def word(bytes : array<uint8>; i : int) : uint {return uint(bytes[i])|(uint(bytes[i+1])<<8)|(uint(bytes[i+2])<<16)|(uint(bytes[i+3])<<24)}
def load_mesh(device : SDL_GPUDevice?; name : string) {
    let bytes <- load_file(asset("{name}.fgm")) |> sdl_try
    if(length(bytes)<16 || word(bytes,0)!=0x314d4746u || word(bytes,12)!=32u){return err(SdlError(operation=name,message="Invalid FGM1 header"),type<MeshBuffers>)}
    let nv=word(bytes,4);let ni=word(bytes,8)
    if(nv==0u || nv>1000000u || ni==0u || ni>3000000u || ni%3u!=0u || uint(length(bytes))!=16u+nv*32u+ni*4u){return err(SdlError(operation=name,message="Invalid FGM1 counts"),type<MeshBuffers>)}
    for(i in 0u..ni){if(word(bytes,16+int(nv*32u+i*4u))>=nv){return err(SdlError(operation=name,message="Invalid index"),type<MeshBuffers>)}}
    var result : MeshBuffers;var success=false
    defer(){if(!success){release(device,result)}}
    var vb=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_VERTEX,size=nv*32u)) |> sdl_try;result.vb=vb
    var ib=device |> create_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage=SDL_GPU_BUFFERUSAGE_INDEX,size=ni*4u)) |> sdl_try;result.ib=ib;result.count=ni
    var data : array<uint8>;resize(data,int(nv*32u))
    for(i in 0..length(data)){data[i]=bytes[16+i]}
    upload_bytes(device,result.vb,data) |> sdl_try
    resize(data,int(ni*4u));for(i in 0..length(data)){data[i]=bytes[16+int(nv*32u)+i]}
    upload_bytes(device,result.ib,data) |> sdl_try
    success=true;return <- move_ok(result,type<SdlError>)
}
def upload_png(device : SDL_GPUDevice?; var target : SDL_GPUTexture?; file : string; layer : uint=0u) : SdlStatus {
    let surface=SDL_LoadPNG(asset(file))
    if(surface==null){return err(sdl_error("SDL_LoadPNG"),type<SdlUnit>)}
    {
        defer(){SDL_DestroySurface(surface)}
        let size=surface_size(surface) |> sdl_try
        // D3D12 buffer-to-image row pitches are multiples of 256 bytes.
        let row=(uint(size.x)+63u)&~63u;let count=row*uint(size.y)*4u
        var bytes : array<uint8>;resize(bytes,int(count))
        copy_surface_rgba8(surface,bytes,int(row*4u)) |> sdl_try
        return sdl_scope() {
            var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=count)) |> sdl_use
            sdl_status(SDL_WriteGPUTransferBufferBytes(device,transfer,count,0u,bytes,false),"Upload image bytes") |> sdl_try
            var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
            with_native_gpu_copy_pass(command) $(var copy_pass) {
                SDL_UploadToGPUTextureRef(copy_pass,SDL_GPUTextureTransferInfo(transfer_buffer=transfer,pixels_per_row=row,rows_per_layer=uint(size.y)),SDL_GPUTextureRegion(texture=target,layer=layer,w=uint(size.x),h=uint(size.y),d=1u),false)
                return sdl_ok()
            } |> sdl_try
            return native_gpu_submit(command)
        }
    }
}
def load_texture(device : SDL_GPUDevice?; name : string; cube : bool=false) {
    let probe=SDL_LoadPNG(asset(cube ? "sky_px.png" : "{name}.png"))
    if(probe==null){return err(sdl_error("SDL_LoadPNG"),type<SDL_GPUTexture?>)}
    var size : int2
    {defer(){SDL_DestroySurface(probe)};size=surface_size(probe) |> sdl_try}
    var t=texture(device,uint(size.x),uint(size.y),SDL_GPU_TEXTUREUSAGE_SAMPLER,cube,true) |> sdl_try
    var success=false;defer(){if(!success){SDL_ReleaseGPUTexture(device,t)}}
    if(cube){let faces=fixed_array("px","nx","py","ny","pz","nz");for(i in 0..6){upload_png(device,t,"sky_{faces[i]}.png",uint(i)) |> sdl_try}}
    else{upload_png(device,t,"{name}.png") |> sdl_try}
    success=true;return <- move_ok(t,type<SdlError>)
}
def pipeline(device : SDL_GPUDevice?; vs,vr,fs,fr : array<uint>; format : SDL_GPUTextureFormat; geometry : bool=true; instances : bool=false; depth : bool=true) {
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(vs,vr) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(fs,fr) |> sdl_use
        var info=SDL_GPUGraphicsPipelineCreateInfo(vertex_shader=vertex,fragment_shader=fragment,primitive_type=SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST,rasterizer_state=SDL_GPURasterizerState(enable_depth_clip=true))
        if(depth){info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS) |> depth_write(true)}
        var buffers : array<SDL_GPUVertexBufferDescription>;var attributes : array<SDL_GPUVertexAttribute>
        if(geometry){
            buffers <- array(SDL_GPUVertexBufferDescription(pitch=32u))
            attributes <- array(SDL_GPUVertexAttribute(format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=1u,offset=12u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),SDL_GPUVertexAttribute(location=2u,offset=24u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))
            if(instances){
                push(buffers,SDL_GPUVertexBufferDescription(slot=1u,pitch=64u,input_rate=SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
                for(i in 0u..4u){push(attributes,SDL_GPUVertexAttribute(location=3u+i,buffer_slot=1u,offset=i*16u,format=SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))}
            }
        }
        let colors <- array(gpu_color_target(format))
        return <- device |> create_native_gpu_graphics_pipeline(info,buffers,attributes,colors)
    }
}
def attachment(var t : SDL_GPUTexture?; load : bool=false) {return SDL_GPUColorTargetInfo(texture=t,clear_color=SDL_FColor(r=0.012,g=0.024,b=0.059,a=1.0),load_op=load ? SDL_GPULoadOp.LOADOP_LOAD : SDL_GPULoadOp.LOADOP_CLEAR,store_op=SDL_GPUStoreOp.STOREOP_STORE)}
def bind_images(pass_ : SDL_GPURenderPass?; var images : array<SDL_GPUTexture?>; var sampler : SDL_GPUSampler?) : SdlStatus {
    var bindings : array<SDL_GPUTextureSamplerBinding>;for(image in images){push(bindings,SDL_GPUTextureSamplerBinding(texture=image,sampler=sampler))}
    return sdl_status(SDL_BindGPUFragmentSamplersArray(pass_,0u,bindings),"SDL_BindGPUFragmentSamplersArray")
}
def draw_mesh(pass_ : SDL_GPURenderPass?; var mesh : MeshBuffers; count : uint=1u; var instances : SDL_GPUBuffer?=null) : SdlStatus {
    var buffers <- array(SDL_GPUBufferBinding(buffer=mesh.vb));if(instances!=null){push(buffers,SDL_GPUBufferBinding(buffer=instances))}
    sdl_status(SDL_BindGPUVertexBuffersArray(pass_,0u,buffers),"SDL_BindGPUVertexBuffersArray") |> sdl_try
    SDL_BindGPUIndexBufferRef(pass_,SDL_GPUBufferBinding(buffer=mesh.ib),SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
    SDL_DrawGPUIndexedPrimitives(pass_,mesh.count,count,0u,0,0u);return sdl_ok()
}
def read_image(device : SDL_GPUDevice?; var target : SDL_GPUTexture?; width,height : uint) {
    let row=(width+63u)&~63u;let size=row*height*4u
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD,size=size)) |> sdl_use
        with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
            with_native_gpu_copy_pass(command) $(var copy_pass) {
                SDL_DownloadFromGPUTextureRef(copy_pass,SDL_GPUTextureRegion(texture=target,w=width,h=height,d=1u),SDL_GPUTextureTransferInfo(transfer_buffer=transfer,pixels_per_row=row,rows_per_layer=height))
                return sdl_ok()
            } |> sdl_try
            var fence=native_gpu_submit_fence(command) |> sdl_try
            {defer(){SDL_ReleaseGPUFence(device,fence)};let fences <- array(fence);return sdl_status(SDL_WaitForGPUFencesArray(device,true,fences),"Wait readback")}
        } |> sdl_try
        var padded,bytes : array<uint8>;resize(padded,int(size));resize(bytes,int(width*height*4u))
        sdl_status(SDL_ReadGPUTransferBufferBytes(device,transfer,size,0u,padded),"Read readback") |> sdl_try
        for(y in 0u..height){for(x in 0u..width*4u){bytes[int(y*width*4u+x)]=padded[int(y*row*4u+x)]}}
        return <- move_ok(bytes,type<SdlError>)
    }
}
