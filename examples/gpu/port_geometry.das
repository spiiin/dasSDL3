options gen2
module port_geometry shared public
// Geometry and matrix utilities local to the application examples.
require bgfx_support public
require mesh_data
require daslib/math_boost public
require daslib/math_bits
require daslib/defer
require math public
struct Geometry {
    vertices : array<float>
    indices : array<uint>
}
struct GeometryBuffers {
    vb, ib : SDL_GPUBuffer?
    count : uint
}
def release(device : SDL_GPUDevice?; var g : GeometryBuffers) {
    if (g.vb != null) {
        SDL_ReleaseGPUBuffer(device, g.vb)
    }
    if (g.ib != null) {
        SDL_ReleaseGPUBuffer(device, g.ib)
    }
}
def vertex(var g : Geometry; p, n : float3; uv : float2 = float2(0.0)) {
    for (x in fixed_array(p.x, p.y, p.z, n.x, n.y, n.z, uv.x, uv.y)) {
        push(g.vertices, x)
    }
}
def triangle(var g : Geometry; a, b, c : float3) {
    let first = uint(length(g.vertices) / 8)
    let n = normalize(cross(b - a, c - a))
    vertex(g, a, n)
    vertex(g, b, n)
    vertex(g, c, n)
    push(g.indices, first)
    push(g.indices, first + 1u)
    push(g.indices, first + 2u)
}
def cube_geometry() : Geometry {
    var g : Geometry
    let p = fixed_array(float3(-1.0, -1.0, -1.0), float3(1.0, -1.0, -1.0), float3(1.0, 1.0, -1.0), float3(-1.0, 1.0, -1.0), float3(-1.0, -1.0, 1.0), float3(1.0, -1.0, 1.0), float3(1.0, 1.0, 1.0), float3(-1.0, 1.0, 1.0))
    let ids = fixed_array(0, 3, 2, 0, 2, 1, 4, 5, 6, 4, 6, 7, 0, 4, 7, 0, 7, 3, 1, 2, 6, 1, 6, 5, 0, 1, 5, 0, 5, 4, 3, 7, 6, 3, 6, 2)
    for (i in 0 .. 12) {
        triangle(g, p[ids[i * 3]], p[ids[i * 3 + 1]], p[ids[i * 3 + 2]])
    }
    return <- g
}
def plane_geometry(half_size : float) : Geometry {
    var g : Geometry
    let a = float3(-half_size, 0.0, -half_size)
    let b = float3(-half_size, 0.0, half_size)
    let c = float3(half_size, 0.0, half_size)
    let d = float3(half_size, 0.0, -half_size)
    triangle(g, a, b, c)
    triangle(g, a, c, d)
    return <- g
}
def load_geometry(path : string) : $Result<Geometry; SdlError> {
    let data <- load_file(path) |> sdl_try
    if (length(data) < 16) {
        return err(SdlError(operation = path, message = "Truncated mesh"), type<Geometry>)
    }
    let magic = mesh_u32(data, 0)
    let nv = mesh_u32(data, 4)
    let ni = mesh_u32(data, 8)
    let stride = mesh_u32(data, 12)
    if ((magic != 0x3148534du && magic != 0x3248534du) || (stride != 24u && stride != 32u) || nv == 0u || nv > 1000000u || ni == 0u || ni > 3000000u || ni % 3u != 0u || uint64(length(data)) != 16ul + uint64(nv) * uint64(stride) + uint64(ni) * 4ul) {
        return err(SdlError(operation = path, message = "Invalid mesh header"), type<Geometry>)
    }
    var g : Geometry
    for (i in 0 .. int(nv)) {
        for (j in 0 .. 8) {
            var value = 0.0
            if (j < int(stride / 4u)) {
                let word = mesh_u32(data, 16 + i * int(stride) + j * 4)
                if ((word & 0x7f800000u) == 0x7f800000u) {
                    return err(SdlError(operation = path, message = "Nonfinite vertex"), type<Geometry>)
                }
                value = uint_bits_to_float(word)
            }
            push(g.vertices, value)
        }
    }
    for (i in 0 .. int(ni)) {
        let index = mesh_u32(data, 16 + int(nv * stride) + i * 4)
        if (index >= nv) {
            return err(SdlError(operation = path, message = "Invalid index"), type<Geometry>)
        }
        push(g.indices, index)
    }
    return <- move_ok(g, type<SdlError>)
}
def upload_geometry(device : SDL_GPUDevice?; g : Geometry) : $Result<GeometryBuffers; SdlError> {
    var r : GeometryBuffers
    var success = false
    defer() {
        if (!success) {
            release(device, r)
        }
    }
    var vb = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = uint(length(g.vertices)) * 4u)) |> sdl_try
    r.vb = vb
    var ib = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_INDEX, size = uint(length(g.indices)) * 4u)) |> sdl_try
    r.ib = ib
    r.count = uint(length(g.indices))
    var bytes : array<uint8>
    let divisors = fixed_array(1u, 256u, 65536u, 16777216u)
    for (value in g.vertices) {
        let word = float_bits_to_uint(value)
        for (b in 0 .. 4) {
            push(bytes, uint8((word / divisors[b]) & 255u))
        }
    }
    upload_bytes(device, r.vb, bytes) |> sdl_try
    clear(bytes)
    for (value in g.indices) {
        for (b in 0 .. 4) {
            push(bytes, uint8((value / divisors[b]) & 255u))
        }
    }
    upload_bytes(device, r.ib, bytes) |> sdl_try
    success = true
    return <- move_ok(r, type<SdlError>)
}
def draw_geometry(pass_ : SDL_GPURenderPass?; var g : GeometryBuffers) : SdlStatus {
    let buffers <- array(SDL_GPUBufferBinding(buffer = g.vb))
    sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, buffers), "SDL_BindGPUVertexBuffersArray") |> sdl_try
    SDL_BindGPUIndexBufferRef(pass_, SDL_GPUBufferBinding(buffer = g.ib), SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
    SDL_DrawGPUIndexedPrimitives(pass_, g.count, 1u, 0u, 0, 0u)
    return sdl_ok()
}
def identity_matrix : float4x4 {
    var m : float4x4
    identity(m)
    return m
}
def model_matrix(position : float3; scale : float3; angle : float = 0.0) : float4x4 {
    var m : float4x4
    let s = sin(angle)
    let c = cos(angle)
    m[0] = float4(c * scale.x, 0.0, s * scale.x, 0.0)
    m[1] = float4(0.0, scale.y, 0.0, 0.0)
    m[2] = float4(-s * scale.z, 0.0, c * scale.z, 0.0)
    m[3] = float4(position, 1.0)
    return m
}
def camera_matrix(width, height : uint; eye, at : float3) : float4x4 {
    var p : float4x4
    let f = 1.7320508
    let q = 100.0 / 99.9
    p[0] = float4(f * float(height) / float(width), 0.0, 0.0, 0.0)
    p[1] = float4(0.0, f, 0.0, 0.0)
    p[2] = float4(0.0, 0.0, q, 1.0)
    p[3] = float4(0.0, 0.0, -0.1 * q, 0.0)
    return p * look_at_lh(eye, at, float3(0.0, 1.0, 0.0))
}
def position_at(g : Geometry; index : uint) : float3 {
    let i = int(index) * 8
    return float3(g.vertices[i], g.vertices[i + 1], g.vertices[i + 2])
}
