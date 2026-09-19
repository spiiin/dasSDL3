options gen2
require dassdl3/sdl3_gpu_culling_boost

def rejects(action : block) {
    var caught = false
    try { action() } recover { caught = true }
    verify(caught)
}

[export]
def main(smoke : bool) : int {
    var unit : float4x4
    identity(unit)
    let frustum = gpu_frustum(unit)
    verify(gpu_sphere_visible(frustum,unit,float4(0.0,0.0,0.5,0.0)))
    // Exactly tangent spheres survive all six clip planes, including z=0 near.
    for (axis in 0 .. 3) {
        for (side in 0 .. 2) {
            var center = float3(0.0,0.0,0.5)
            center[axis] = side == 0 ? -1.5 : 1.5
            if (axis == 2 && side == 0) { center.z = -0.5 }
            verify(gpu_sphere_visible(frustum,unit,float4(center,0.5)))
            center[axis] += side == 0 ? -0.01 : 0.01
            verify(!gpu_sphere_visible(frustum,unit,float4(center,0.5)))
        }
    }
    var model = unit
    model[0] = float4(-0.1,0.0,0.0,0.0)
    model[1] = float4(0.0,2.0,0.0,0.0)
    model[2] = float4(0.0,0.0,0.2,0.0)
    model[3] = float4(1.09,0.0,0.5,1.0)
    verify(gpu_sphere_visible(frustum,model,float4(0.0,0.0,0.0,1.0)))
    model[3].x = 1.2
    verify(!gpu_sphere_visible(frustum,model,float4(0.0,0.0,0.0,1.0)))
    // Shear: x support sqrt(3), greater than the largest column length sqrt(2).
    model = unit
    model[1].x = 1.0
    model[2].x = 1.0
    model[3] = float4(2.6,0.0,0.5,1.0)
    verify(gpu_sphere_visible(frustum,model,float4(0.0,0.0,0.0,1.0)))
    model[3].x = 2.8
    verify(!gpu_sphere_visible(frustum,model,float4(0.0,0.0,0.0,1.0)))
    // Nonzero local center and reflection must both be transformed.
    model = unit
    model[0].x = -1.0
    model[3] = float4(2.0,0.0,0.5,1.0)
    verify(gpu_sphere_visible(frustum,model,float4(1.0,0.0,0.0,0.2)))
    verify(!gpu_sphere_visible(frustum,model,float4(-1.0,0.0,0.0,0.2)))
    // Compare point spheres with direct homogeneous clipping for a rotated camera.
    let camera = gpu_camera(float3(3.0,2.0,5.0),float3(0.0),float3(0.0,1.0,0.0),1.1,1.4,0.3,12.0)
    let rotated = gpu_frustum(camera)
    for (z in -8 .. 9) {
        for (x in -8 .. 9) {
            let point = float4(float(x)*0.73,0.17,float(z)*0.61,1.0)
            let clip = camera * point
            let inside = clip.x >= -clip.w && clip.x <= clip.w && clip.y >= -clip.w && clip.y <= clip.w && clip.z >= 0.0 && clip.z <= clip.w
            verify(gpu_sphere_visible(rotated,unit,float4(point.xyz,0.0)) == inside)
        }
    }
    var list : GpuBatchList
    verify(list |> gpu_batch_add_visible(frustum,42ul,unit,float4(0.0,0.0,0.5,0.1)))
    verify(!(list |> gpu_batch_add_visible(frustum,99ul,unit,float4(4.0,0.0,0.5,0.1))))
    verify(length(list.meshes) == 1 && list.meshes[0] == 42ul && length(list.model_columns) == 4)
    verify(list.colors[0] == float4(1.0))
    var blank = GpuFrustum()
    rejects() { gpu_sphere_visible(blank,unit,float4(0.0)) }
    rejects() { gpu_sphere_visible(frustum,unit,float4(0.0,0.0,0.0,-1.0)) }
    var invalid = unit
    invalid[0].w = 0.1
    rejects() { gpu_sphere_visible(frustum,invalid,float4(0.0)) }
    invalid[0].x = sqrt(-1.0)
    rejects() { gpu_frustum(invalid) }
    rejects() { gpu_sphere_visible(frustum,invalid,float4(0.0)) }
    rejects() { gpu_sphere_visible(frustum,unit,float4(0.0,0.0,0.0,sqrt(-1.0))) }
    var zero : float4x4
    rejects() { gpu_frustum(zero) }
    // Overflow is uncertain: keep the object rather than falsely rejecting it.
    model = unit
    model[0].x = 1.0e30
    model[3].x = 1.0e30
    verify(gpu_sphere_visible(frustum,model,float4(0.0,0.0,0.0,1.0)))
    print("Frustum planes, tangency, affine sphere support, clip oracle and invalid inputs PASS\n")
    return 0
}
