# SDL binding boundary

The library exposes SDL objects and operations. Public scene, mesh, material,
batching and rendering-plan frameworks are outside its scope. Application
algorithms belong in examples.

Allowed layers:

1. Generated SDL names, signatures, enums and structure fields.
2. Language adapters for references, arrays, strings, union tags and lifetimes.
3. Small defaults, pipes and with_* scopes using standard Result/Option and defer.

Raw SDL signatures and failure sentinels remain unchanged. No wrapper panic,
try/recover or native exception bridges. Native pointers retain SDL lifetime,
thread, device and synchronization preconditions. Checked GPU IDs are a separate
API; do not add a registry merely to expose a native SDL operation.

See [errors](error-handling.md), [native scopes](gpu-native-boost.md) and
[coverage](api-coverage.md). tests/test_gpu_api_boundary.py rejects removed
framework exports through negative compilation against the runner.
