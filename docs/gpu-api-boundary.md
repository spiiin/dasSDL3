# SDL binding boundary

> Current declaration coverage: all 92 active Windows GPU functions are generated.
> See [native GPU API](gpu-native-api.md), [native scopes](gpu-native-boost.md)
> and [local runtime/AOT results](gpu-native-validation.md). The older checked
> subset and native pointer API have separate ownership contracts.

The library binds SDL. It does not define a rendering engine. This decision
supersedes the earlier choice to retain command plans as an optional public API.

## Removed

Public native exports, boost modules and implementations for meshes, materials,
scenes, scene draw lists, batching, culling, fixed mesh/triangle rendering and
command/render plans have been removed. They are not hidden behind a build flag
or kept as a second compatibility API. Their engine-specific examples/tests and
unused shader assets were removed too. Documents for removed APIs have been deleted.

Examples 44 and 45 now use direct SDL command-buffer/render-pass operations;
46 already used that path. Independent pixel oracles are private test fixtures.
No mesh object is required to test a graphics pipeline or draw a triangle.

## Allowed layers

1. Generated SDL declarations: SDL names, types, enums and structures, following
   the pinned headers. Raw and checked coverage must be distinguished.
2. Necessary language adapters: pointer/count to array, copied strings,
   output references, checked conversions and resource lifetime handling.
3. Small boost conveniences: defaults, `with_*` ownership and pipes. These must
   not introduce scene/material/mesh/plan objects or replace SDL command flow.
4. Example application code: camera, transforms, lighting or batching can be
   written in an example once the needed SDL API is accessible. It must not
   become a public binding object merely to make that example work.

The existing transfer/readback helpers are partial memory/lifetime adapters;
their internally created transfers/fences do not count as public access to all
of those SDL operations. Checked IDs identify individual native resources,
not geometry/material aggregates. Errors remain SDL result values. Ownership uses script defer and direct block
calls; all native catch/rethrow bridges are removed. See error-handling.md.

This cleanup does not make the remaining adapters complete or unrestricted.
Current format/count/layout restrictions, immutable CPU index shadows and
compound readback helpers must be recorded as limitations. Complete direct SDL
access takes priority over extending those helpers. No new public composite
GPU object should be added to work around an unbound SDL operation.

## Coverage correction and next work

The pinned Windows census is 164 generated / 9 adapted / 1053 pending of 1226.
GPU is 92 generated / 0 adapted / 0 pending of 92. Adapted is partial coverage.
Framework removal previously returned debug labels/groups, copy-pass begin/end
and blocking swapchain acquisition to pending. Those gaps are now closed by
direct generated exports, not by counting internal calls. Raw execution and
native adapter validation now have CPU pixel/byte oracles and interpreter/AOT
coverage on Vulkan/D3D12; see gpu-native-validation.md for exclusions. The SDL
version has not changed.

The native GPU follow-up is implemented; maintenance limits are in gpu-roadmap.md. Extend
generation where signatures allow it; add adapters only for explicit language
or lifetime requirements. Reflection/shader DSL and companion libraries remain
separate later work. Do not add engine features to increase a coverage count.

`tests/test_gpu_api_boundary.py` verifies that removed public names/modules stay
unavailable, including negative compilation against the actual runner.

## Verification

The boundary test runs negative compilation against development and consumer
runners. Current combined results: [gpu-native-validation.md](gpu-native-validation.md).
