options gen2
require dassdl3/sdl3_shader_storage
struct Item { value : float3; factor : float; weights : uint[2] }
require math
struct Tiny { x : float; y : float2 }
struct Complex {
    first : float
    nested : Tiny
    values : float[3]
    vectors : float2[2]
    matrix : float3x3
    sub : Tiny[2]
}
def check_complex {
    var c = Complex(first = 1.0, nested = Tiny(x = 2.0, y = float2(4.0, 8.0)))
    c.values[0] = 16.0; c.values[1] = 32.0; c.values[2] = 64.0
    c.vectors[0] = float2(128.0, 256.0); c.vectors[1] = float2(512.0, 1024.0)
    for (i in 0 .. 3) {c.matrix[i] = float3(1.0, 2.0, 4.0)}
    c.sub[0] = Tiny(x = 8.0, y = float2(16.0, 32.0)); c.sub[1] = Tiny(x = 64.0, y = float2(128.0, 256.0))
    var items <- array(c)
    var bytes <- gpu_dsl_storage_bytes(items) |> move_unwrap
    let golden = fixed_array(
        0x3f800000u, 0u, 0x40000000u, 0u, 0x40800000u, 0x41000000u,
        0x41800000u, 0x42000000u, 0x42800000u, 0u,
        0x43000000u, 0x43800000u, 0x44000000u, 0x44800000u, 0u, 0u,
        0x3f800000u, 0x40000000u, 0x40800000u, 0u,
        0x3f800000u, 0x40000000u, 0x40800000u, 0u,
        0x3f800000u, 0x40000000u, 0x40800000u, 0u,
        0x41000000u, 0u, 0x41800000u, 0x42000000u,
        0x42800000u, 0u, 0x43000000u, 0x43800000u)
    verify(length(bytes) == 144)
    for (round in 0 .. 2) {
        for (i in 0 .. 36) {var word = golden[i]; for (b in 0 .. 4) {verify(bytes[i * 4 + b] == uint8(word % 256u)); word /= 256u}}
        for (i in 0 .. length(bytes)) {bytes[i] = uint8(255)}
        pack_gpu_dsl_storage(items, bytes) |> unwrap
    }
    var decoded : array<Complex>
    unpack_gpu_dsl_storage(bytes, decoded) |> unwrap
    verify(decoded[0].sub[1].y == float2(128.0, 256.0) && decoded[0].matrix[2] == float3(1.0, 2.0, 4.0))
    pop(bytes)
    verify(is_err(unpack_gpu_dsl_storage(bytes, decoded)) && length(decoded) == 1 && decoded[0].first == 1.0)
    clear(items)
    pack_gpu_dsl_storage(items, bytes) |> unwrap
    verify(empty(bytes))
    unpack_gpu_dsl_storage(bytes, decoded) |> unwrap
    verify(empty(decoded))
}
[export]
def main(smoke : bool) : int {
    check_complex()
    var items <- array(Item(value = float3(1.0, 2.0, 3.0), factor = 4.0), Item(value = float3(5.0, 6.0, 7.0), factor = 8.0))
    items[0].weights[0] = 9u; items[1].weights[1] = 10u
    var bytes <- gpu_dsl_storage_bytes(items) |> move_unwrap
    verify(length(bytes) == 64)
    var result : array<Item>
    unpack_gpu_dsl_storage(bytes, result) |> unwrap
    verify(length(result) == 2 && result[0].value == float3(1.0, 2.0, 3.0) && result[1].factor == 8.0 && result[0].weights[0] == 9u && result[1].weights[1] == 10u)
    print("std430 PASS\n")
    return 0
}
