options gen2
module shadowvolumes_geometry shared public
require port_geometry public
// Closed finite volumes for a manifold, consistently wound triangle mesh.
// Edge mode removes internal walls; face mode keeps cancelling triangle prisms.
def shadow_volume(mesh : Geometry; model : float4x4; light : float3; edges : bool) : Geometry {
    var out : Geometry
    var points : array<float3>
    var far_points : array<float3>
    var lit : array<bool>
    for (i in 0 .. length(mesh.indices)) {
        let p = model * float4(position_at(mesh, mesh.indices[i]), 1.0)
        push(points, p.xyz / p.w)
        push(far_points, p.xyz / p.w + normalize(p.xyz / p.w - light) * 30.0)
    }
    for (i in 0 .. length(points) / 3) {
        let a = points[i * 3]
        let b = points[i * 3 + 1]
        let c = points[i * 3 + 2]
        push(lit, dot(cross(b - a, c - a), light - a) > 0.0)
    }
    for (i in 0 .. length(lit)) {
        if (!lit[i]) {
            continue
        }
        let base = i * 3
        triangle(out, points[base], points[base + 1], points[base + 2])
        triangle(out, far_points[base + 2], far_points[base + 1], far_points[base])
        for (e in 0 .. 3) {
            let a = base + e
            let b = base + (e + 1) % 3
            var internal = false
            if (edges) {
                for (j in 0 .. length(lit)) {
                    if (j == i || !lit[j]) {
                        continue
                    }
                    for (k in 0 .. 3) {
                        if (points[j * 3 + k] == points[b] && points[j * 3 + (k + 1) % 3] == points[a]) {
                            internal = true
                        }
                    }
                }
            }
            if (!internal) {
                triangle(out, points[b], points[a], far_points[a])
                triangle(out, points[b], far_points[a], far_points[b])
            }
        }
    }
    return <- out
}
