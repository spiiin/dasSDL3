options gen2
module mesh_data shared public
require dassdl3/sdl3_iostream_boost public
require dassdl3/sdl3_try

// Example-local MSH1 format. No native pointers or arbitrary struct deserialization.
struct MeshData {
    vertices : array<uint8>
    indices : array<uint8>
    vertex_count, index_count : uint
}

def mesh_u32(bytes : array<uint8>; offset : int) : uint {
    return uint(bytes[offset]) | (uint(bytes[offset+1])<<8) | (uint(bytes[offset+2])<<16) | (uint(bytes[offset+3])<<24)
}

def mesh_error(message : string) {
    return err(SdlError(operation="MSH1",message=message),type<MeshData>)
}

def decode_mesh(bytes : array<uint8>) {
    if (length(bytes)<16) { return <- mesh_error("Truncated header") }
    if (mesh_u32(bytes,0)!=0x3148534du || mesh_u32(bytes,12)!=24u) { return <- mesh_error("Invalid magic or vertex stride") }
    let nv=mesh_u32(bytes,4); let ni=mesh_u32(bytes,8)
    // Bounds precede multiplication and allocation; this format is deliberately small.
    if (nv==0u || nv>1000000u || ni==0u || ni>3000000u || ni%3u!=0u) { return <- mesh_error("Invalid mesh counts") }
    let vertex_bytes=int(nv*24u); let index_bytes=int(ni*4u)
    if (length(bytes)!=16+vertex_bytes+index_bytes) { return <- mesh_error("Unexpected payload size") }
    for (i in 0 .. vertex_bytes/4) {
        if ((mesh_u32(bytes,16+i*4)&0x7f800000u)==0x7f800000u) { return <- mesh_error("Non-finite vertex") }
    }
    for (i in 0 .. int(ni)) {
        if (mesh_u32(bytes,16+vertex_bytes+i*4)>=nv) { return <- mesh_error("Index outside vertex buffer") }
    }
    var mesh=MeshData(vertex_count=nv,index_count=ni)
    resize(mesh.vertices,vertex_bytes); resize(mesh.indices,index_bytes)
    for (i in 0 .. vertex_bytes) { mesh.vertices[i]=bytes[16+i] }
    for (i in 0 .. index_bytes) { mesh.indices[i]=bytes[16+vertex_bytes+i] }
    return <- move_ok(mesh,type<SdlError>)
}

def load_mesh(path : string) {
    let bytes <- load_file(path) |> sdl_try
    return <- decode_mesh(bytes)
}
