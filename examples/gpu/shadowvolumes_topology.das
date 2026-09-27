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
