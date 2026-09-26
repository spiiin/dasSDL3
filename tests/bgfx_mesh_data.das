options gen2
require ../examples/gpu/mesh_data.das

def put_u32(var bytes : array<uint8>; offset : int; value : uint) {
    for (j in 0 .. 4) { bytes[offset + j] = uint8((value >> uint(j * 8)) & 255u) }
}

[export]
def main(smoke : bool) : int {
    var bytes : array<uint8>
    verify(is_err(decode_mesh(bytes)))
    resize(bytes, 100)// Header + three zero-filled position/normal vertices + one triangle.
    put_u32(bytes, 0, 0x3148534du); put_u32(bytes, 4, 3u); put_u32(bytes, 8, 3u); put_u32(bytes, 12, 24u)
    put_u32(bytes, 92, 1u); put_u32(bytes, 96, 2u)
    var valid <- decode_mesh(bytes)
    verify(is_ok(valid))
    let mesh <- move_unwrap(valid)
    verify(mesh.vertex_count == 3u && mesh.index_count == 3u)
    verify(length(mesh.vertices) == 72 && length(mesh.indices) == 12 && mesh_u32(mesh.indices, 8) == 2u)
    put_u32(bytes, 96, 3u); verify(is_err(decode_mesh(bytes))); put_u32(bytes, 96, 2u)
    put_u32(bytes, 16, 0x7f800000u); verify(is_err(decode_mesh(bytes)))// Infinity.
    put_u32(bytes, 16, 0x7fc00001u); verify(is_err(decode_mesh(bytes)))// NaN.
    put_u32(bytes, 16, 0u)
    put_u32(bytes, 4, 0xffffffffu); verify(is_err(decode_mesh(bytes))); put_u32(bytes, 4, 3u)
    put_u32(bytes, 8, 2u); verify(is_err(decode_mesh(bytes))); put_u32(bytes, 8, 3u)
    put_u32(bytes, 12, 20u); verify(is_err(decode_mesh(bytes))); put_u32(bytes, 12, 24u)
    put_u32(bytes, 0, 0u); verify(is_err(decode_mesh(bytes))); put_u32(bytes, 0, 0x3148534du)
    resize(bytes, 99); verify(is_err(decode_mesh(bytes)))
    resize(bytes, 101); verify(is_err(decode_mesh(bytes)))
    verify(is_err(load_mesh("__missing_mesh_file__.msh")))
    print("MSH1 validation: PASS\n")
    return 0
}

