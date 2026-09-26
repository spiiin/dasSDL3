# Boost modules

`require sdl3` imports native declarations. `require dassdl3/sdl3_boost` re-exports
them with Result/Option operations, copied queries and resource scopes.

| Module | Purpose |
| --- | --- |
| sdl3_scope | Linear acquisition with sdl_scope / sdl_use |
| sdl3_try | Early error return |
| sdl3_events | Owned event variants and polling |
| sdl3_geometry_boost | Vertex/index array adapters |
| sdl3_pixels_boost | Texture buffers, render targets and readback |
| sdl3_record_access | Surface metadata/planes, palettes and Vulkan options |
| sdl3_audio_boost | WAV and audio streams |
| sdl3_gpu_native_boost | Native GPU resources and scopes |
| sdl3_gpu_boost | Checked GPU helpers with distinct handles |

Use one outer SDL lifetime and nested resource owners. Scope handles are borrowed;
do not retain them or destroy them manually. Errors are copied before cleanup.
Void scope work returns sdl_ok(); pending and absent states are distinct from errors.

See [errors](error-handling.md), [syntax](api-ergonomics.md), [scope macros](sdl-scope.md),
[sdl_try](sdl-try.md) and the [API index](README.md).
