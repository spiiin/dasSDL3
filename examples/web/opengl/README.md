# SDL + daScript OpenGL in the browser

These examples use the existing **dasOpenGL** module from the pinned daScript
submodule (`require opengl`, native target `libDasModuleOpenGL`). There is no
second GL binding in dasSDL3. SDL creates the window and an OpenGL ES 3.0 context;
Emscripten maps the GL calls to WebGL 2. The examples do not create SDL_Renderer.

Build and serve as described in [Web README](../../../web/README.md), then open:

- `/opengl/01_clear.html`: direct glViewport/glClear; a mint-green canvas.
- `/opengl/02_triangle.html`: explicit shader compilation/linking, an animated
  triangle with red/green/blue corners and interpolated colors. GLSL ES 3.00
  uses gl_VertexID for three vertices and a time uniform; no vertex buffer yet.

Start launches the script; Stop/Escape destroys program, context and window.
Restart reloads the WASM session. Each frame queries the drawable pixel size
for glViewport, so browser resize and pixel scaling are handled.

SDL functions use the existing Result/sdl_try contract. Shader compile/link
errors return SdlError with a copied GL log. The example calls the existing raw
OpenGL functions and uses standard safe_addr for synchronous local out parameters
and the shader-source string. No script unsafe blocks or additional C++ GL
adapters are needed. Log buffers are freshly allocated strings sized from the
GL_INFO_LOG_LENGTH query; the reported log is copied before cleanup.
Shader objects are deleted through nested defer scopes after acquisition;
the program survives across frames and is deleted before SDL_GL_DestroyContext.
No panic-based shader helpers are used.

Only the WebGL 2 / GLES 3.0 subset is exercised. Upstream dasOpenGL also exposes
compatibility stubs for some desktop-only operations: their presence is not
proof of Web support. SDL_GPU/WebGPU and full desktop GL/EGL (P8) remain separate.
Automatic WebGL context-loss recovery is not implemented; reload the page.

Validation: `tests/web/test_opengl.py` checks real canvas RGB pixels, resize,
Stop/Restart, vertex/fragment compile failures, link failure and context creation
failure. JS test instrumentation counts native WebGL shader/program creation and
deletion, including failure paths. Run with `--browser edge` or `--browser firefox`.

Local result (2026-09-22): all 6 scenarios passed in Edge and Firefox.
