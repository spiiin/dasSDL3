# Renderer raw geometry, events and native interop

Five native signatures finish the Render declaration inventory: RenderGeometryRaw,
ConvertEventToRenderCoordinates, GetRenderMetalLayer, GetRenderMetalCommandEncoder,
and AddVulkanRenderSemaphores. SDL_RenderDebugTextFormat is adapted with a fixed
`%s`; prepare strings in daScript. Arbitrary C varargs are not exposed.

The split-array geometry adapters borrow packed SDL_FPoint positions/UVs and
SDL_FColor colors for one call. They validate matching counts, triangle count,
and int32 indices. Empty indexed draws are no-ops. Arbitrary strides and 8/16-bit
indices remain available through raw SDL. No renderer/resource ownership changes.

Event conversion mutates a live SDL_Event exactly once. Mouse member writers set
the union tag; existing readers unpack it. Motion positions/deltas, button positions,
and wheel mouse positions are converted; wheel scroll amounts are unchanged.
Touch, pen and drop event conversion remains native and is not covered by these
mouse tests. Do not pass a null event pointer to the raw function.

Metal getters return borrowed native objects, with backend-specific lifetimes.
Vulkan semaphore interop requires valid native synchronization objects and caller
ownership. Software-renderer tests cover unsupported backend behavior only;
positive Metal and Vulkan synchronization tests require separate native harnesses.
Never test a real Vulkan backend with fabricated semaphore handles.

Tests: `tests/renderer_final_api.das`; public example: `64_renderer_raw_geometry.das`.
Local Windows validation (SDL 3.2.18): main suite 144/144; this package's
legacy/CppGenBind/AOT runtime tests plus metadata 7/7; generator/inventory/boundary
checks 6/6 and standalone generator tests 4/4. A consumer built without LLVM,
Python discovery or generators runs the test and example successfully.
The AOT runner was rebuilt; unrelated GPU parity runtime cases were not rerun.

The geometry pixel oracle covers untextured triangles, raw 8/16/32-bit indices,
sequential arrays, invalid indices/counts and empty indexed draws. Textured UV
arrays and arbitrary native strides need additional cases; positive native
Metal/Vulkan synchronization is not implied by declaration coverage.
