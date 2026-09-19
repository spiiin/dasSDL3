options gen2
module sdl3_gpu_culling_boost shared public
require dassdl3/sdl3_gpu_batches_boost public

// Inward planes for -w <= x,y <= w and 0 <= z <= w. Rebuild when camera changes.
struct public GpuFrustum {
    planes : float4[6]
    initialized : bool = false
}

def cull_finite(v : float4) : bool {
    return is_finite(v.x) && is_finite(v.y) && is_finite(v.z) && is_finite(v.w)
}

def public gpu_frustum(camera : float4x4) : GpuFrustum {
    for (c in 0 .. 4) {
        if (!cull_finite(camera[c])) { panic("GPU culling: finite camera required") }
    }
    let x = float4(camera[0].x,camera[1].x,camera[2].x,camera[3].x)
    let y = float4(camera[0].y,camera[1].y,camera[2].y,camera[3].y)
    let z = float4(camera[0].z,camera[1].z,camera[2].z,camera[3].z)
    let w = float4(camera[0].w,camera[1].w,camera[2].w,camera[3].w)
    var result = GpuFrustum()
    result.planes[0] = w+x
    result.planes[1] = w-x
    result.planes[2] = w+y
    result.planes[3] = w-y
    result.planes[4] = z
    result.planes[5] = w-z
    for (plane in result.planes) {
        if (!cull_finite(plane) || max(abs(plane.x),max(abs(plane.y),abs(plane.z))) == 0.0) {
            panic("GPU culling: finite nondegenerate frustum planes required")
        }
    }
    result.initialized = true
    return result
}

// local_sphere = local-space center.xyz and radius.w; caller encloses all geometry.
// This is a conservative visibility query, not a mesh/resource validation API.
def public gpu_sphere_visible(frustum : GpuFrustum; model : float4x4; local_sphere : float4) : bool {
    if (!frustum.initialized) { panic("GPU culling: initialize frustum with gpu_frustum") }
    if (!cull_finite(local_sphere) || local_sphere.w < 0.0) { panic("GPU culling: finite sphere and nonnegative radius required") }
    for (c in 0 .. 4) {
        if (!cull_finite(model[c])) { panic("GPU culling: finite model required") }
    }
    if (model[0].w != 0.0 || model[1].w != 0.0 || model[2].w != 0.0 || model[3].w != 1.0) {
        panic("GPU culling: affine model required")
    }
    let center = float4(local_sphere.xyz,1.0)
    var visible = true
    for (plane in frustum.planes) {
        if (!cull_finite(plane)) { panic("GPU culling: invalid frustum plane") }
        // M^T * plane: support of the transformed sphere, including shear/reflection.
        let local = float4(dot(plane,model[0]),dot(plane,model[1]),dot(plane,model[2]),dot(plane,model[3]))
        let extent = local_sphere.w * sqrt(dot(local.xyz,local.xyz))
        let distance = dot(local,center)
        let tolerance = 1.0e-5 * (1.0 + dot(abs(local),abs(center)) + extent)
        // Finite inputs can overflow intermediate arithmetic. Retain uncertain objects.
        if (!(cull_finite(local) && is_finite(extent) && is_finite(distance) && is_finite(tolerance))) { return true }
        if (distance + extent < -tolerance) { visible = false }
    }
    return visible
}

def public gpu_batch_add_visible(var list : GpuBatchList; frustum : GpuFrustum; mesh : uint64;
        model : float4x4; local_sphere : float4; color : float4 = float4(1.0)) : bool {
    if (!gpu_sphere_visible(frustum,model,local_sphere)) { return false }
    list |> gpu_batch_add(mesh,model,color)
    return true
}
