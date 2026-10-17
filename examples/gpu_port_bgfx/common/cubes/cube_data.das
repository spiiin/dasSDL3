options gen2
module cube_data shared public
require math

// Interleaved position, normal, tangent/sign, UV, RGBA (16 floats).
def cube_vertices() {
    let normals <- array(float3(0, 0, -1), float3(0, 0, 1), float3(-1, 0, 0), float3(1, 0, 0), float3(0, 1, 0), float3(0, -1, 0))
    let tangents <- array(float3(1, 0, 0), float3(-1, 0, 0), float3(0, 0, -1), float3(0, 0, 1), float3(1, 0, 0), float3(1, 0, 0))
    var vertices : array<float>
    for (face in 0 .. 6) {
        let n = normals[face]; let t = tangents[face]; let b = cross(n, t)
        for (corner in 0 .. 4) {
            let uv = float2(float(corner & 1), float(corner >> 1))
            let p = n + t * (uv.x * 2.0 - 1.0) + b * (uv.y * 2.0 - 1.0)
            let fields <- array<float>(p.x, p.y, p.z, n.x, n.y, n.z, t.x, t.y, t.z, 1.0, uv.x, uv.y,
                (p.x + 1.0) * 0.5, (1.0 - p.y) * 0.5, (1.0 - p.z) * 0.5, 1.0)
            for (value in fields) { push(vertices, value) }
        }
    }
    return <- vertices
}

def cube_indices() {
    var indices : array<uint8>
    for (face in 0u .. 6u) {
        let corners <- array<uint>(0u, 1u, 2u, 1u, 3u, 2u)
        for (corner in corners) {
            let index = face * 4u + corner
            for (byte in 0u .. 4u) { push(indices, uint8((index >> (byte * 8u)) & 255u)) }
        }
    }
    return <- indices
}

def update_instances(var values : array<float>; side : int; time : float; bump : bool) {
    clear(values)
    for (y in 0 .. side) {
        for (x in 0 .. side) {
            let ax = time * (bump ? 0.023 : 1.0) + float(x) * 0.21
            let ay = time * (bump ? 0.03 : 1.0) + float(y) * 0.37
            let sx = sin(ax); let cx = cos(ax); let sy = sin(ay); let cy = cos(ay)
            let base = bump ? -3.0 : -float(side - 1) * 1.5
            let row <- array<float>(cy, sx * sy, -cx * sy, 0.0, 0.0, cx, sx, 0.0, sy, -sx * cy, cx * cy, 0.0,
                base + float(x) * 3.0, base + float(y) * 3.0, 0.0, 1.0,
                sin(time + float(x) / 11.0) * 0.5 + 0.5, cos(time + float(y) / 11.0) * 0.5 + 0.5, sin(time * 3.0) * 0.5 + 0.5, 1.0)
            for (value in row) { push(values, value) }
        }
    }
}
