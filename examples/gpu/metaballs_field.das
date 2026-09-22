options gen2
module metaballs_field shared public
// Adapted from bgfx examples/02-metaballs (BSD-2-Clause; LICENSE-bgfx.txt).
require math
require metaballs_tables

struct GridPoint {
    value : float
    normal : float3
}
let CORNERS = fixed_array(int3(0,1,1),int3(1,1,1),int3(1,1,0),int3(0,1,0),
    int3(0,0,1),int3(1,0,1),int3(1,0,0),int3(0,0,0))
let EDGE_END = fixed_array(1,2,3,0,5,6,7,4,4,5,6,7)

def safe_normal(v : float3) : float3 {
    let squared = dot(v,v)
    return squared > 0.00000001 ? v / sqrt(squared) : float3(0.0,0.0,-1.0)
}

def update_field(var grid : array<GridPoint>; n : int; time : float) {
    var spheres : float4[16]
    for (i in 0 .. 16) {
        let f = float(i)
        spheres[i] = float4(sin(time*f*0.21+f*0.37)*8.0,
            sin(time*f*0.37+f*0.67)*8.0, cos(time*f*0.11+f*0.13)*8.0,
            1.0/(3.0+(sin(time*f*0.13)*0.5+0.5)*0.9))
    }
    resize(grid,n*n*n)
    let step = 32.0/float(n)
    for (z in 0 .. n) {
        for (y in 0 .. n) {
            for (x in 0 .. n) {
                let p = float3(float(x),float(y),float(z))*step - float3(16.0)
                var field = -1.0
                for (sphere in spheres) {
                    let delta = sphere.xyz-p
                    // Equivalent to bgfx's dist/prod recurrence, without overflow or 0/0.
                    field += 1.0/max(dot(delta,delta)*sphere.w*sphere.w,0.000001)
                }
                grid[(z*n+y)*n+x].value = field
            }
        }
    }
    for (z in 0 .. n) {
        for (y in 0 .. n) {
            for (x in 0 .. n) {
                let i = (z*n+y)*n+x
                let dx = grid[i-(x>0 ? 1 : 0)].value-grid[i+(x<n-1 ? 1 : 0)].value
                let dy = grid[i-(y>0 ? n : 0)].value-grid[i+(y<n-1 ? n : 0)].value
                let dz = grid[i-(z>0 ? n*n : 0)].value-grid[i+(z<n-1 ? n*n : 0)].value
                grid[i].normal = safe_normal(float3(dx,dy,dz))
            }
        }
    }
}

def append_vertex(var vertices : array<float>; p, normal, color : float3) {
    push(vertices,p.x); push(vertices,p.y); push(vertices,p.z)
    push(vertices,normal.x); push(vertices,normal.y); push(vertices,normal.z)
    push(vertices,color.x); push(vertices,color.y); push(vertices,color.z)
}

def triangulate(grid : array<GridPoint>; n : int; iso : float; var vertices : array<float>) {
    clear(vertices)
    let step = 32.0/float(n)
    var samples : int[8]
    var positions, normals : float3[12]
    for (z in 0 .. n-1) {
        for (y in 0 .. n-1) {
            for (x in 0 .. n-1) {
                var configuration = 0
                for (corner in 0 .. 8) {
                    let c = CORNERS[corner]+int3(x,y,z)
                    samples[corner] = (c.z*n+c.y)*n+c.x
                    if (grid[samples[corner]].value < iso) { configuration |= 1 << corner }
                }
                if (configuration==0 || configuration==255) { continue }
                for (edge in 0 .. 12) {
                    let a = edge & 7
                    let b = EDGE_END[edge]
                    if (((configuration >> a) & 1)==((configuration >> b) & 1)) { continue }
                    let v0 = grid[samples[a]].value
                    let v1 = grid[samples[b]].value
                    let t = (abs(iso-v1)<0.00001 ? 1.0 :
                        (abs(iso-v0)<0.00001 || abs(v0-v1)<0.00001 ? 0.0 : (iso-v0)/(v1-v0)))
                    let ca = CORNERS[a]; let cb = CORNERS[b]
                    positions[edge] = (float3(float(ca.x),float(ca.y),float(ca.z)) +
                        float3(float(cb.x-ca.x),float(cb.y-ca.y),float(cb.z-ca.z))*t)
                    normals[edge] = grid[samples[a]].normal*(1.0-t)+grid[samples[b]].normal*t
                }
                for (i in 0 .. 15) {
                    let edge = TRIANGLES[configuration*16+i]
                    if (edge<0) { break }
                    let lattice = float3(float(x),float(y),float(z))+positions[edge]
                    append_vertex(vertices,lattice*step-float3(16.0),normals[edge],lattice/float(n-1))
                }
            }
        }
    }
}
