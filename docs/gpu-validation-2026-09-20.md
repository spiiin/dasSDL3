# GPU binding validation, 2026-09-20

Windows x64/MSVC, pinned SDL 3.2.18 and daScript, Vulkan and D3D12.
The optional process-local RenderDoc Vulkan layer exclusion was used; SDL
validation remained enabled. No commits or upstream dependency edits were made.

## Results

- Production C++ build passed.
- Main project selection: 104 tests, initially 103 passed and one outdated
  field-visibility expectation failed. The corrected type test passed separately.
  The separate bindings_up_to_date check passed (105 project checks in total).
- Parity/AOT build completed all 164 build steps. The 260-test run initially
  had two skips for example 47's empty driver name and two failures after that
  script changed while its older AOT binary was still in use. Regenerating and
  rebuilding that example required three steps. All five affected example tests
  then passed, covering baseline, CppGenBind, default AOT and Vulkan/D3D12 AOT.
  All 260 distinct tests therefore have passing results after targeted reruns;
  this was not a second clean full-suite run.
- Standalone clangbind checks: 4/4 passed, including missing-AOT rejection.
- No-LLVM consumer configured and built with generators, LLVM and Clang disabled.
  Examples 46 and 47 passed on both backends, and removed-framework API rejection
  passed. Example 47 was repeated on both backends after its fix. Development
  build configuration was restored afterward.
- Whitespace/diff check passed.

## Changes from findings

The type test now accepts newly exposed writable descriptor fields instead of
expecting absent-field diagnostics. It still rejects incompatible enums/numeric
assignments and hidden padding. Const-pointee fields have explicit non-assignable
expectations; this limitation is documented in gpu-native-api.md.

Example 47 previously passed an empty driver name to raw SDL_CreateGPUDevice.
That is not SDL's null/default driver, so generic runs without SDL_GPU_DRIVER
could skip. The example now enumerates supported driver names. Explicit backend
selection in the environment still takes precedence in SDL.

## Coverage limits

Passing the existing suite is not runtime coverage of every newly generated
function. Direct native compute/copy/swapchain operations, all attachment modes,
the by-value color argument and new array adapters still need dedicated runtime
and AOT oracles. Const-pointer descriptor construction needs safe call-scoped
adapters. P6 is not complete merely because all 92 declarations are generated.
No cross-platform or warning-free D3D12 claim is made by this report.

Logs are in the task workspace `work/verify-*.log`: main, type-retest, freshness,
parity-build, parity, parity-rebuild, parity-retest, standalone, consumer,
fence-example and restore-build.
