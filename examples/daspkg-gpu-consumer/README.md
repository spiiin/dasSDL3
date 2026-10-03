# Standalone Mac GPU consumer

This entry point is staged by `tools/build_macos_gpu_bundle.py`; it is not a
source-tree runner example. The builder copies unchanged examples 46 and 86,
their application-local backend helper and three saved MSL files into a
disposable daspkg project, then runs the pinned SDK's standalone release tool.

The app first runs example 46's texture/sampler/uniform/readback pixel oracle.
It then opens example 86's animated SDL GPU Renderer window. Escape or closing
the window exits; `--smoke` stops after four frames. GPU setup failure fails
the app. The entry point also verifies SDL subsystem cleanup.

Use the matching native dynamic SDK and core package module from the
[Mac package setup](../../docs/macos.md). LLVM is required only to build:

```sh
python3 tools/build_macos_gpu_bundle.py \
  --module build/macos-package/module/dasSDL3.shared_module \
  --das-root third_party/daScript --llvm-dir lib \
  --work build/gpu-release
# Structure/signature/relocation checks; no display needed:
python3 tests/test_macos_gpu_bundle.py --bundle build/gpu-release/out/sdl3_gpu_demo.app
# Ordinary Terminal in a GUI login session:
python3 tests/test_macos_gpu_bundle.py --bundle build/gpu-release/out/sdl3_gpu_demo.app --run
```

`--work` must be new or empty. The test copies the app to a directory with
spaces and runs it from an empty working directory with SDK/compiler search
paths removed. Saved MSL assets and notices live in `Contents/Resources`;
native dependencies live in `Contents/MacOS`. No script sources, shader
compiler or LLVM runtime are shipped. Signing is ad-hoc for local execution.

Native arm64/macOS 15.3.1 validation passed the pixel oracle, window rendering,
cleanup, dependency/asset audit and strict signature check after relocation.
