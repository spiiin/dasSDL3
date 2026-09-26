options gen2
require ../examples/gpu/metaballs_field.das
require ../examples/gpu/metaballs_tables.das
require math

[export]
def main(smoke : bool) : int {
    // Every table row emits complete triangles on edges whose signs differ.
    for (configuration in 0 .. 256) {
        var count = 0
        for (i in 0 .. 16) {
            let edge = TRIANGLES[configuration * 16 + i]
            if (edge < 0) { break }
            verify(edge < 12)
            verify(((configuration >> (edge & 7)) & 1) != ((configuration >> EDGE_END[edge]) & 1))
            count++
        }
        verify(count <= 15 && count % 3 == 0)
    }
    // Independent analytic sphere oracle: radius 6 on a unit-spaced grid.
    var grid : array<GridPoint>
    resize(grid, 32 * 32 * 32)
    for (z in 0 .. 32) {
        for (y in 0 .. 32) {
            for (x in 0 .. 32) {
                let p = float3(float(x - 16), float(y - 16), float(z - 16))
                grid[(z * 32 + y) * 32 + x] = GridPoint(value = 36.0 - dot(p, p), normal = safe_normal(p))
            }
        }
    }
    var vertices : array<float>
    triangulate(grid, 32, 0.0, vertices)
    verify(length(vertices) > 1000 && length(vertices) % 27 == 0)
    for (i in 0 .. length(vertices) / 9) {
        let p = float3(vertices[i * 9], vertices[i * 9 + 1], vertices[i * 9 + 2])
        let normal = float3(vertices[i * 9 + 3], vertices[i * 9 + 4], vertices[i * 9 + 5])
        verify(abs(sqrt(dot(p, p)) - 6.0) < 0.03)
        verify(dot(p, normal) > 5.8)
    }
    triangulate(grid, 32, 1000.0, vertices)
    verify(length(vertices) == 0)
    update_field(grid, 8, 0.0)
    let first = grid[0].value
    update_field(grid, 8, 1.0)
    verify(abs(first - grid[0].value) > 0.00001)
    triangulate(grid, 8, 0.75, vertices)
    verify(length(vertices) > 0 && length(vertices) % 27 == 0)
    print("Metaballs table, analytic sphere, empty surface and animated field PASS\n")
    return 0
}
