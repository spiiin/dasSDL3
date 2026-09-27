options gen2
require dassdl3/sdl3_shader_uniforms
require math

struct Inner { x : int; y : uint }
struct Params {
    a : float
    b : float3
    c : float
    values : float[2]
    m : float3x3
    inner : Inner[2]
    signed_value : int64
    unsigned_value : uint64
}
var calls = 0
def make_params() : Params {
    calls++
    var p = Params(a = 1.0, b = float3(2.0, 3.0, 4.0), c = 5.0, signed_value = -2l, unsigned_value = 0x1122334455667788ul)
    p.values[0] = 6.0; p.values[1] = 7.0
    p.m[0] = float3(8.0, 9.0, 10.0)
    p.m[1] = float3(11.0, 12.0, 13.0)
    p.m[2] = float3(14.0, 15.0, 16.0)
    p.inner[0] = Inner(x = -1, y = 0x12345678u)
    p.inner[1] = Inner(x = -2, y = 0x87654321u)
    return p
}
def check(bytes : array<uint8>) {
    // Independent std140 golden: scalar; vec3+scalar; array stride16; mat3 column stride16;
    // nested struct array stride16; two 64-bit scalars. Includes every padding byte.
    let words = fixed_array(
        0x3f800000u, 0u, 0u, 0u,
        0x40000000u, 0x40400000u, 0x40800000u, 0x40a00000u,
        0x40c00000u, 0u, 0u, 0u, 0x40e00000u, 0u, 0u, 0u,
        0x41000000u, 0x41100000u, 0x41200000u, 0u,
        0x41300000u, 0x41400000u, 0x41500000u, 0u,
        0x41600000u, 0x41700000u, 0x41800000u, 0u,
        0xffffffffu, 0x12345678u, 0u, 0u,
        0xfffffffeu, 0x87654321u, 0u, 0u,
        0xfffffffeu, 0xffffffffu, 0x55667788u, 0x11223344u)
    verify(length(bytes) == 160)
    for (i in 0 .. 40) {
        var word = words[i]
        for (b in 0 .. 4) { verify(bytes[i * 4 + b] == uint8(word % 256u)); word /= 256u }
    }
}
struct Matrices { a : float3x4; b : float4x4 }
[export]
def main(smoke : bool) : int {
    var bytes <- gpu_dsl_uniform_bytes(make_params())
    verify(calls == 1); check(bytes)
    for (i in 0 .. length(bytes)) {bytes[i] = uint8(255)}
    pack_gpu_dsl_uniform(make_params(), bytes)
    verify(calls == 2); check(bytes)
    var matrices : Matrices
    for (c in 0 .. 4) {matrices.a[c] = float3(1.0); matrices.b[c] = float4(2.0)}
    pack_gpu_dsl_uniform(matrices, bytes)
    verify(length(bytes) == 128)
    for (i in 0 .. 32) {
        let word = i < 16 ? (i % 4 == 3 ? 0u : 0x3f800000u) : 0x40000000u
        verify(bytes[i * 4] == uint8(0) && bytes[i * 4 + 1] == uint8(0))
        verify(bytes[i * 4 + 2] == uint8((word / 65536u) % 256u) && bytes[i * 4 + 3] == uint8(word / 16777216u))
    }
    verify(is_err(push_gpu_dsl_vertex_uniform(null, 0u, make_params())))
    verify(is_err(push_gpu_dsl_fragment_uniform(null, 4u, make_params())))
    verify(is_err(push_gpu_dsl_compute_uniform(null, 0u, make_params())))
    print("Uniform std140 bytes PASS\n")
    return 0
}
