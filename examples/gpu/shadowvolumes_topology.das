options gen2
module shadowvolumes_topology shared public
require port_geometry public
require mesh_data
struct ClosedMesh {
    geometry : Geometry
    neighbours : array<int>
}
def load_closed_mesh(name : string) : $Result<ClosedMesh; SdlError> {
    var mesh : ClosedMesh
    var geometry <- load_geometry("{SDL_GetBasePath()}assets/bgfx/{name}.msh") |> sdl_try
    mesh.geometry <- geometry
    let bytes <- load_file("{SDL_GetBasePath()}assets/bgfx/{name}.adj") |> sdl_try
    let count = length(mesh.geometry.indices)
    if (length(bytes) != 8 + count * 4 || mesh_u32(bytes, 0) != 0x31415653u || mesh_u32(bytes, 4) != uint(count)) {
        return err(SdlError(operation = name, message = "Invalid adjacency header"), type<ClosedMesh>)
    }
    for (i in 0 .. count) {
        let face = int(mesh_u32(bytes, 8 + i * 4))
        if (face < 0 || face >= count / 3) { return err(SdlError(operation = name, message = "Invalid adjacent face"), type<ClosedMesh>) }
        push(mesh.neighbours, face)
    }
    return <- move_ok(mesh, type<SdlError>)
}
def closed_cube() : ClosedMesh {
    var mesh : ClosedMesh
    mesh.geometry <- cube_geometry()
    let uv = fixed_array(float2(0.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0), float2(1.0, 1.0), float2(1.0, 0.0))
    for (i in 0 .. 36) {
        mesh.geometry.vertices[i * 8 + 6] = uv[i % 6].x; mesh.geometry.vertices[i * 8 + 7] = uv[i % 6].y
        let a = position_at(mesh.geometry, uint(i)); let b = position_at(mesh.geometry, uint(i / 3 * 3 + (i + 1) % 3))
        var neighbour = -1
        for (j in 0 .. 36) {
            if (position_at(mesh.geometry, uint(j)) == b && position_at(mesh.geometry, uint(j / 3 * 3 + (j + 1) % 3)) == a) { neighbour = j / 3 }
        }
        push(mesh.neighbours, neighbour)
    }
    return <- mesh
}
def volume_triangle(var out : array<float>; a, b, c : float3) {
    for (p in fixed_array(a, b, c)) {
        for (v in fixed_array(p.x, p.y, p.z, 0.0, 1.0, 0.0, 0.0, 0.0)) { push(out, v) }
    }
}
// Cached adjacency makes silhouette extraction linear in triangle count.
def append_volume(var out : array<float>; mesh : ClosedMesh; model : float4x4; light : float3; silhouette : bool; distance : float) {
    var points, far_points : array<float3>
    var lit : array<bool>
    for (i in 0 .. length(mesh.geometry.vertices) / 8) {
        let world = model * float4(position_at(mesh.geometry, uint(i)), 1.0)
        let p = world.xyz / world.w
        push(points, p); push(far_points, p + normalize(p - light) * distance)
    }
    for (i in 0 .. length(mesh.geometry.indices) / 3) {
        let a = points[mesh.geometry.indices[i * 3]]; let b = points[mesh.geometry.indices[i * 3 + 1]]; let c = points[mesh.geometry.indices[i * 3 + 2]]
        push(lit, dot(cross(b - a, c - a), light - a) > 0.0)
    }
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        let a = mesh.geometry.indices[i * 3]; let b = mesh.geometry.indices[i * 3 + 1]; let c = mesh.geometry.indices[i * 3 + 2]
        volume_triangle(out, points[a], points[b], points[c])
        volume_triangle(out, far_points[c], far_points[b], far_points[a])
        for (e in 0 .. 3) {
            if (silhouette && lit[mesh.neighbours[i * 3 + e]]) { continue }
            let u = mesh.geometry.indices[i * 3 + e]; let v = mesh.geometry.indices[i * 3 + (e + 1) % 3]
            volume_triangle(out, points[v], points[u], far_points[u])
            volume_triangle(out, points[v], far_points[u], far_points[v])
        }
    }
}

// Reused CPU storage. Array arguments keep inner loops local in generated AOT.
// The reference append_volume above deliberately remains available to tests.
def write_volume_triangle(var out : array<float>; var cursor : int&; a, b, c : float4) {
    out[cursor] = a.x; out[cursor + 1] = a.y; out[cursor + 2] = a.z; out[cursor + 4] = 1.0
    out[cursor + 8] = b.x; out[cursor + 9] = b.y; out[cursor + 10] = b.z; out[cursor + 12] = 1.0
    out[cursor + 16] = c.x; out[cursor + 17] = c.y; out[cursor + 18] = c.z; out[cursor + 20] = 1.0
    out[cursor + 3] = 0.0; out[cursor + 5] = 0.0; out[cursor + 6] = 0.0; out[cursor + 7] = 0.0
    out[cursor + 11] = 0.0; out[cursor + 13] = 0.0; out[cursor + 14] = 0.0; out[cursor + 15] = 0.0
    out[cursor + 19] = 0.0; out[cursor + 21] = 0.0; out[cursor + 22] = 0.0; out[cursor + 23] = 0.0
    cursor += 24
}
def append_volume_reused(var out : array<float>; mesh : ClosedMesh; model : float4x4; light : float3; silhouette : bool; distance : float;
                         var points, far_points : array<float4>; var lit : array<bool>) {
    // Keep the fourth SIMD lane defined throughout the hot loop.
    let count = length(mesh.geometry.vertices) / 8
    resize(points, count); resize(far_points, count)
    for (i in 0 .. count) {
        let offset = i * 8
        // Avoid a cross-module script call for every input vertex.
        let world = model * float4(mesh.geometry.vertices[offset], mesh.geometry.vertices[offset + 1], mesh.geometry.vertices[offset + 2], 1.0)
        let p = world / world.w
        // xzy preserves the SSE4 dot3 accumulation order used by the reference.
        let direction = p - float4(light, 1.0)
        points[i] = p; far_points[i] = p + normalize(direction.xzyw).xzyw * distance
    }
    resize(lit, length(mesh.geometry.indices) / 3)
    for (i in 0 .. length(lit)) {
        let a = points[mesh.geometry.indices[i * 3]]; let b = points[mesh.geometry.indices[i * 3 + 1]]; let c = points[mesh.geometry.indices[i * 3 + 2]]
        let u = b - a; let v = c - a
        let normal = float4(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x, 0.0)
        lit[i] = dot(normal.xzyw, (float4(light, 1.0) - a).xzyw) > 0.0
    }
    // Count once, then resize once per object instead of pushing each scalar.
    var triangles = 0
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        triangles += 2
        for (e in 0 .. 3) { if (!silhouette || !lit[mesh.neighbours[i * 3 + e]]) { triangles += 2 } }
    }
    var cursor = length(out)
    // Write every field explicitly when filling the reused output stream.
    resize(out, cursor + triangles * 24)
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        let a = mesh.geometry.indices[i * 3]; let b = mesh.geometry.indices[i * 3 + 1]; let c = mesh.geometry.indices[i * 3 + 2]
        write_volume_triangle(out, cursor, points[a], points[b], points[c])
        write_volume_triangle(out, cursor, far_points[c], far_points[b], far_points[a])
        for (e in 0 .. 3) {
            if (silhouette && lit[mesh.neighbours[i * 3 + e]]) { continue }
            let u = mesh.geometry.indices[i * 3 + e]; let v = mesh.geometry.indices[i * 3 + (e + 1) % 3]
            write_volume_triangle(out, cursor, points[v], points[u], far_points[u])
            write_volume_triangle(out, cursor, points[v], far_points[u], far_points[v])
        }
    }
}

// Explicit little-endian uint32 index bytes, without borrowing unsafe memory.
def write_volume_indices(var out : array<uint8>; var cursor : int&; a, b, c : uint) {
    for (index in fixed_array(a, b, c)) {
        out[cursor] = uint8(index & 255u); out[cursor + 1] = uint8((index / 256u) & 255u)
        out[cursor + 2] = uint8((index / 65536u) & 255u); out[cursor + 3] = uint8(index / 16777216u)
        cursor += 4
    }
}

def append_volume_indexed(var vertices : array<float>; var out : array<uint8>; mesh : ClosedMesh; model : float4x4; light : float3; silhouette : bool;
                          var points : array<float4>; var lit : array<bool>) {
    // Keep the fourth SIMD lane defined throughout the hot loop.
    let count = length(mesh.geometry.vertices) / 8
    resize(points, count)
    let base = uint(length(vertices) / 4)
    let vertex_start = length(vertices)
    resize(vertices, vertex_start + count * 8)
    for (i in 0 .. count) {
        let offset = i * 8
        // Avoid a cross-module script call for every input vertex.
        let world = model * float4(mesh.geometry.vertices[offset], mesh.geometry.vertices[offset + 1], mesh.geometry.vertices[offset + 2], 1.0)
        let p = world / world.w
        points[i] = p
        // Two compact vertices per source position: near and extruded.
        let dst = vertex_start + i * 8
        vertices[dst] = p.x; vertices[dst + 1] = p.y; vertices[dst + 2] = p.z; vertices[dst + 3] = 0.0
        vertices[dst + 4] = p.x; vertices[dst + 5] = p.y; vertices[dst + 6] = p.z; vertices[dst + 7] = 1.0
    }
    resize(lit, length(mesh.geometry.indices) / 3)
    for (i in 0 .. length(lit)) {
        let a = points[mesh.geometry.indices[i * 3]]; let b = points[mesh.geometry.indices[i * 3 + 1]]; let c = points[mesh.geometry.indices[i * 3 + 2]]
        let u = b - a; let v = c - a
        let normal = float4(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x, 0.0)
        lit[i] = dot(normal.xzyw, (float4(light, 1.0) - a).xzyw) > 0.0
    }
    // Count once, then resize once per object instead of pushing each scalar.
    var triangles = 0
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        triangles += 2
        for (e in 0 .. 3) { if (!silhouette || !lit[mesh.neighbours[i * 3 + e]]) { triangles += 2 } }
    }
    var cursor = length(out)
    // Write every field explicitly when filling the reused output stream.
    resize(out, cursor + triangles * 12)
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        let a = mesh.geometry.indices[i * 3]; let b = mesh.geometry.indices[i * 3 + 1]; let c = mesh.geometry.indices[i * 3 + 2]
        write_volume_indices(out, cursor, base + a * 2u, base + b * 2u, base + c * 2u)
        write_volume_indices(out, cursor, base + c * 2u + 1u, base + b * 2u + 1u, base + a * 2u + 1u)
        for (e in 0 .. 3) {
            if (silhouette && lit[mesh.neighbours[i * 3 + e]]) { continue }
            let u = mesh.geometry.indices[i * 3 + e]; let v = mesh.geometry.indices[i * 3 + (e + 1) % 3]
            write_volume_indices(out, cursor, base + v * 2u, base + u * 2u, base + u * 2u + 1u)
            write_volume_indices(out, cursor, base + v * 2u, base + u * 2u + 1u, base + v * 2u + 1u)
        }
    }
}

// An anchored plane preserves the reference dot(n, light-a) evaluation order.
// Collapsing it to dot(n,light)+d can change nearly coplanar face classification.
struct VolumeRange {
    vertex_base : uint
    face_start, face_count : int
}

def prepare_volume(var vertices : array<float>; var origins, normals : array<float4>; mesh : ClosedMesh; model : float4x4; var points : array<float4>) : VolumeRange {
    // Keep the fourth SIMD lane defined throughout the hot loop.
    let count = length(mesh.geometry.vertices) / 8
    resize(points, count)
    let base = uint(length(vertices) / 4)
    let face_start = length(origins)
    let face_count = length(mesh.geometry.indices) / 3
    let vertex_start = length(vertices)
    resize(vertices, vertex_start + count * 8)
    for (i in 0 .. count) {
        let offset = i * 8
        // Avoid a cross-module script call for every input vertex.
        let world = model * float4(mesh.geometry.vertices[offset], mesh.geometry.vertices[offset + 1], mesh.geometry.vertices[offset + 2], 1.0)
        let p = world / world.w
        points[i] = p
        // Two compact vertices per source position: near and extruded.
        let dst = vertex_start + i * 8
        vertices[dst] = p.x; vertices[dst + 1] = p.y; vertices[dst + 2] = p.z; vertices[dst + 3] = 0.0
        vertices[dst + 4] = p.x; vertices[dst + 5] = p.y; vertices[dst + 6] = p.z; vertices[dst + 7] = 1.0
    }
    resize(origins, face_start + face_count); resize(normals, face_start + face_count)
    for (i in 0 .. face_count) {
        let a = points[mesh.geometry.indices[i * 3]]; let b = points[mesh.geometry.indices[i * 3 + 1]]; let c = points[mesh.geometry.indices[i * 3 + 2]]
        let u = b - a; let v = c - a
        let normal = float4(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x, 0.0)
        origins[face_start + i] = a; normals[face_start + i] = normal
    }
    return VolumeRange(vertex_base = base, face_start = face_start, face_count = face_count)
}

def append_prepared_volume(var out : array<uint8>; mesh : ClosedMesh; span : VolumeRange; origins, normals : array<float4>; light : float3; silhouette : bool; var lit : array<bool>) {
    let base = span.vertex_base
    resize(lit, span.face_count)
    for (i in 0 .. span.face_count) {
        let face = span.face_start + i
        lit[i] = dot(normals[face].xzyw, (float4(light, 1.0) - origins[face]).xzyw) > 0.0
    }
    // Count once, then resize once per object instead of pushing each scalar.
    var triangles = 0
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        triangles += 2
        for (e in 0 .. 3) { if (!silhouette || !lit[mesh.neighbours[i * 3 + e]]) { triangles += 2 } }
    }
    var cursor = length(out)
    // Write every field explicitly when filling the reused output stream.
    resize(out, cursor + triangles * 12)
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        let a = mesh.geometry.indices[i * 3]; let b = mesh.geometry.indices[i * 3 + 1]; let c = mesh.geometry.indices[i * 3 + 2]
        write_volume_indices(out, cursor, base + a * 2u, base + b * 2u, base + c * 2u)
        write_volume_indices(out, cursor, base + c * 2u + 1u, base + b * 2u + 1u, base + a * 2u + 1u)
        for (e in 0 .. 3) {
            if (silhouette && lit[mesh.neighbours[i * 3 + e]]) { continue }
            let u = mesh.geometry.indices[i * 3 + e]; let v = mesh.geometry.indices[i * 3 + (e + 1) % 3]
            write_volume_indices(out, cursor, base + v * 2u, base + u * 2u, base + u * 2u + 1u)
            write_volume_indices(out, cursor, base + v * 2u, base + u * 2u + 1u, base + v * 2u + 1u)
        }
    }
}
