# Vulkan / Metal window interop

Pinned SDL 3.4.16, Windows x64/MSVC. Seven Vulkan and three Metal raw declarations
are generated from SDL_vulkan.h and SDL_metal.h. Generators now accept explicit
entry headers in bindings.json; the web profile still defaults to SDL.h.
This is SDL window interop, not a Vulkan or Metal rendering framework.

## Native boundary

VkInstance_T?, VkPhysicalDevice_T? and VkSurfaceKHR_T? are opaque native pointers
in the validated 64-bit profile. VkAllocationCallbacks is opaque: hosts supply a
valid native allocator pointer or NULL. No script callback or allocator bridge.
The 32-bit non-dispatchable handle ABI has not been implemented or validated.
SDL_MetalView and its layer retain SDL's void-pointer representation.

Create the Vulkan instance through a native Vulkan host/module, with the extensions
returned by SDL enabled. SDL does not create Vulkan devices, queues or swapchains
through these functions. The instance and physical device remain borrowed.
VkGetInstanceProcAddr is a native address with the Vulkan calling convention,
not a daScript function. Keep its loader loaded throughout use of Vulkan resources.
Do not assume handles from SDL_GPUDevice are Vulkan handles.

## Thin boost

`require dassdl3/sdl3_vulkan_metal`:

- `with_vulkan_library(path)` pairs one successful load reference with deferred
  unload; empty path invokes a native NULL/default path. Keep windows, instances,
  surfaces and all native function uses inside the loader lifetime.
- `vulkan_instance_extensions()` returns Result<array<string>>, copying both the
  borrowed pointer list and names into script-owned storage. Raw SDL storage must
  not be freed. The copy remains usable after SDL/loader teardown.
- The pinned raw SDL_Vulkan_GetInstanceExtensions directly dereferences the video
  backend without initialization/support guards. Call it only after successful
  Vulkan load/window creation. Boost checks GetVkGetInstanceProcAddr first, so
  uninitialized/dummy cases return Err instead of entering that unsafe raw getter.
- `create_vulkan_surface(window,instance,allocator=null)` returns Result<surface>.
  `with_vulkan_surface` lends it to a Result block and destroys in defer, including
  early Err and move-only payloads. The same instance/allocator must be used for
  destruction. They and the window must outlive the surface and its callbacks.
- `destroy_vulkan_surface` consumes a pointer reference. SDL destruction is void,
  so there is no invented Result/error indication. An invalid lifetime is still
  a caller bug; clearing the argument does not invalidate other aliases.
- SDL_Vulkan_GetPresentationSupport remains a raw bool: false means unsupported
  OR error. Do not reinterpret every false or stale SDL error as Result failure.
- `create_metal_view` and `metal_layer` return Result pointers. The layer is borrowed;
  `with_metal_view` destroys only the owned view, before its window is destroyed.
  Native Metal code assigns the MTLDevice and performs rendering. No automatic
  ownership of a Metal device/layer is introduced.

Use main-thread window operations. Do not destroy or retain resources borrowed by
scope callbacks. Defer covers normal/early returns, not arbitrary application panic.
A raw SDL create may convert an existing window from GL/Metal/Vulkan flags in this
pin; explicit dedicated windows with the documented flag remain the supported use.

Sources: [SDL Vulkan surface](https://wiki.libsdl.org/SDL3/SDL_Vulkan_CreateSurface)
and [SDL Metal view](https://wiki.libsdl.org/SDL3/SDL_Metal_CreateView), checked
against the local pinned source.

## Validation scope

`tests/vulkan_metal.das`: dummy/uninitialized loader failures, no-backend Metal
calls, skipped scopes and captured errors. It deliberately does not invoke the raw
extension getter without a loaded Vulkan backend.
`tests/vulkan_surface.das`: real native Vulkan instance using the SDL extension
list, physical device/queue, raw and scoped surfaces, SDL presentation predicate
compared with vkGetPhysicalDeviceSurfaceSupportKHR, early Err/moved array payloads,
copied extension lifetime after teardown, and a native counted allocator proving
raw destruction and early-Err scope cleanup release their allocations. Vulkan-only setup/query calls live
in a test fixture; all SDL calls under test stay in the script. Test Vulkan headers
come from the pinned daScript submodule, not a new production SDK dependency.
`examples/90_vulkan_extensions.das` prints required extensions without unsafe code.

Positive Metal view/layer behavior requires macOS/iOS and is not validated on
Windows. Custom Vulkan allocators are native-only (a counted Windows fixture is tested);
32-bit ABI, Linux/macOS and web remain unverified.
This package does not claim rendered Vulkan frames or a full native Vulkan binding.

## Local results (2026-09-26)

- Main package: 3/3; inventory and inventory contracts: 2/2 (7 unit contracts).
- Baseline / CppGenBind / strict AOT plus metadata: 10/10.
- Generator freshness, preprocessor and binding regression: 3/3; baseline
  regeneration also reproducible.
- Installed core SDK, separate consumer: 6/6 (extension discovery and unavailable
  backend checks in interpreter/AOT, plus no-fallback guards). No LLVM, Vulkan SDK
  or source-tree header dependency in the consumer.
- Documentation links and diff whitespace passed.

The core census is now 1035 generated, 13 adapted, 215 pending out of 1263 Windows
functions. Of these pending entries, 169 Stdinc functions remain intentionally
outside the current work priority; their status and denominator were not changed.
