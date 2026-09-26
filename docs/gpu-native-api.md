# Direct native GPU API

SDL 3.4.16, Windows x64: all 95 active SDL_gpu.h functions are now selected
in tools/bindings.json. Both generator backends emit the original signatures.
The two GDK-only suspend/resume declarations are inactive in this profile and
are not included. Declaration coverage and runtime evidence are tracked
separately; local validation and remaining limits are linked below.

The surface includes device queries/properties, resource creation/release,
render/compute/copy passes, graphics and compute bindings, uniform uploads,
direct/indirect commands, transfers, blits/mipmaps, swapchain configuration and
acquisition, fences and debug names/groups. GPU descriptors expose all named
non-padding fields, including pointer/count fields previously omitted from
shader and pipeline descriptors. SDL_Rect and SDL_FlipMode are also available.

## Native ownership

These handles are SDL pointers, separate from the [checked distinct IDs](gpu-handles.md).
Follow SDL's device, thread, usage, pass and lifetime preconditions. A raw export
does not validate stale pointers, ownership or buffer sizes. Pointer fields in
descriptors borrow memory: keep their backing storage alive for the native call;
do not keep descriptors referring to expired script storage.

The pinned daScript annotation treats const-pointee descriptor fields such as
shader `code` and pipeline `color_target_descriptions` as non-assignable views.
They are exposed for inspection, but ordinary script assignment does not populate
them. Call-scoped creation adapters now populate them from script arrays without
retaining pointers: see [native boost](gpu-native-boost.md). `entrypoint` is represented as
a string (assigning a null pointer is a type error). Generated declaration
coverage must not be presented as unrestricted script descriptor construction.

Errors retain SDL bool/null results and SDL_GetError. Cleanup belongs in script
defer scopes entered after successful acquisition. There is no new catch bridge,
panic conversion, resource registry, command plan or implicit wait-idle.

Swapchain acquisition may succeed with a null texture (for example minimized
windows). Check both the boolean and texture. A non-null swapchain texture is
borrowed, write-only, usable only by its acquiring command buffer, and must not
be released. After acquiring it, submit that command buffer even on an ordinary
early return; cancellation is invalid. End any active pass before submission.
Submission/cancellation consume the command; do not subsequently use it.
See gpu-native-fences.md for the pinned unsignaled-fence release limitation.

## Language adapters

src/sdl3_gpu_native.h adds only call-boundary conversions:

- AcquireGPUSwapchainTextureRef and WaitAndAcquireGPUSwapchainTextureRef expose
  texture, width and height as output references with the original boolean result.
- BeginGPURenderPassArray and BeginGPUComputePassArray borrow descriptor arrays.
- BindGPU*Array covers vertex buffers and vertex/fragment/compute samplers,
  storage textures and storage buffers, with first_slot preserved.
- PushGPU{Vertex,Fragment,Compute}UniformDataArray accepts byte arrays; shader
  layout and SDL slot/size constraints remain caller responsibilities.
- WaitForGPUFencesArray is described separately in gpu-native-fences.md.

All array counts are checked before narrowing to uint32. Binding slot addition
is checked for overflow. Empty binding/uniform arrays are explicit no-ops;
begin-pass adapters forward empty arrays as null/count-zero. No array is retained
or copied and no resource ownership is transferred. A successful adapter boolean
for a void SDL function means the input shape was accepted and the call issued
(or an empty no-op); it does not report GPU execution success.

SDL_SetGPUBlendConstants takes SDL_FColor by value. Its interpreter cast_arg
copies the managed record from its evaluated address into SDL's native argument;
the original SDL function and AOT C++ signature remain unchanged.

## Tests and limits

[Raw GPU tests](gpu-raw-tests.md) exercise all 95 active Windows functions on
Vulkan and D3D12 through both generators and AOT. Pixel and byte oracles verify
GPU output. Debug labels may no-op without the platform capture runtime.

Native adapters have separate creation, transfer, MRT/MSAA/depth/stencil and
lifetime tests. Examples 48–50 use public modules without private fixtures or
script address expressions; see [native boost](gpu-native-boost.md).
This does not certify every parameter combination or other platform profile.
