options gen2
module ftex_assets shared public
require forge_support public
require daslib/defer
struct FtexInfo {format,width,height,levels : uint;payload : uint64}
def ftex_info(bytes : array<uint8>) {
 if(length(bytes)<32 || word(bytes,0)!=0x58455446u || word(bytes,4)!=1u){return err(SdlError(operation="FTEX",message="Invalid file header"),type<FtexInfo>)}
 var info=FtexInfo(format=word(bytes,8),width=word(bytes,12),height=word(bytes,16),levels=word(bytes,20))
 if(info.format<1u || info.format>3u || info.width==0u || info.width>16384u || info.height==0u || info.height>16384u || info.levels==0u || info.levels>32u || uint64(32u+info.levels*16u)>uint64(length(bytes))){return err(SdlError(operation="FTEX",message="Invalid dimensions/format"),type<FtexInfo>)}
 var extent=max(info.width,info.height);var maximum=1u;while(extent>1u){extent/=2u;maximum++};if(info.levels>maximum){return err(SdlError(operation="FTEX",message="Too many mip levels"),type<FtexInfo>)}
 var w=info.width;var h=info.height;var previous=uint64(32u+info.levels*16u)
 for(level in 0u..info.levels){let at=32+int(level)*16;let offset=word(bytes,at);let size=word(bytes,at+4);let expected=uint64((w+3u)/4u)*uint64((h+3u)/4u)*16ul
  if(word(bytes,at+8)!=w || word(bytes,at+12)!=h || uint64(size)!=expected || uint64(offset)<previous || uint64(offset)+uint64(size)>uint64(length(bytes))){return err(SdlError(operation="FTEX",message="Truncated/overlapping mip block data"),type<FtexInfo>)}
  previous=uint64(offset)+uint64(size);info.payload+=expected;w=max(1u,w/2u);h=max(1u,h/2u)
 };return ok(info,type<SdlError>)
}
def load_ftex(device : SDL_GPUDevice?;name : string) {
 let bytes <- load_file(asset(name)) |> sdl_try;let meta=ftex_info(bytes) |> sdl_try
 let format=meta.format==1u ? SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB : (meta.format==2u ? SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM : SDL_GPUTextureFormat.TEXTUREFORMAT_BC5_RG_UNORM)
 if(!SDL_GPUTextureSupportsFormat(device,format,SDL_GPUTextureType.TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER)){return err(SdlError(operation=name,message="Required BC7/BC5 sampling format is unsupported"),type<SDL_GPUTexture?>)}
 var info=gpu_texture(meta.width,meta.height,format,SDL_GPU_TEXTUREUSAGE_SAMPLER);info.num_levels=meta.levels
 var texture=SDL_CreateGPUTextureRef(device,info);if(texture==null){return err(sdl_error("Create compressed texture"),type<SDL_GPUTexture?>)}
 var success=false;defer(){if(!success){SDL_ReleaseGPUTexture(device,texture)}}
 for(level in 0u..meta.levels){let at=32+int(level)*16;let offset=word(bytes,at);let w=word(bytes,at+8);let h=word(bytes,at+12);let blocks_x=(w+3u)/4u;let blocks_y=(h+3u)/4u;let row=(blocks_x*16u+255u)&~255u;let count=row*blocks_y
  var padded : array<uint8>;resize(padded,int(count));for(y in 0u..blocks_y){for(x in 0u..blocks_x*16u){padded[int(y*row+x)]=bytes[int(offset+y*blocks_x*16u+x)]}}
  sdl_scope(){
   var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage=SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD,size=count)) |> sdl_use
   sdl_status(SDL_WriteGPUTransferBufferBytes(device,transfer,count,0u,padded,false),"Write compressed blocks") |> sdl_try
   return with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&){with_native_gpu_copy_pass(command) $(var pass_){
    SDL_UploadToGPUTextureRef(pass_,SDL_GPUTextureTransferInfo(transfer_buffer=transfer,pixels_per_row=row/16u*4u,rows_per_layer=blocks_y*4u),SDL_GPUTextureRegion(texture=texture,mip_level=level,w=w,h=h,d=1u),false);return sdl_ok()
   } |> sdl_try;return native_gpu_submit(command)}
  } |> sdl_try
 };success=true;return <- move_ok(texture,type<SdlError>)
}
