# SDL_image

Optional module `sdl3_image`, boost import `dassdl3/sdl3_image_boost`, build option
`DASSDL3_WITH_IMAGE=ON` (default OFF). Independent of `DASSDL3_WITH_IMGUI`; either
or both libraries can be linked into `dasSDL3_libraries_runner`.

## Version and codec profile

SDL_image **3.2.4** is pinned by archive URL and SHA256 in the root CMakeLists.
It requires SDL >= 3.2.6 and works with this project's SDL 3.2.18. Unlike SDL2_image,
this version has no `IMG_Init` / `IMG_Quit` calls. See the pinned
[CMake configuration](https://github.com/libsdl-org/SDL_image/blob/release-3.2.4/CMakeLists.txt)
and [header](https://github.com/libsdl-org/SDL_image/blob/release-3.2.4/include/SDL3_image/SDL_image.h).

The reproducible profile uses built-in decoders and stb for PNG/JPEG, with PNG/JPEG
writing enabled. BMP, ICO/CUR, GIF, LBM, PCX, PNG, JPEG, PNM, QOI, SVG, TGA, XCF,
XPM and XV are compiled in. This is a build inventory, not a runtime test of every
format. AVIF, JPEG XL, TIFF and WebP are explicitly disabled to avoid external codec
dependencies. Their raw declarations remain visible; declaration availability
does not imply codec support. System WIC/ImageIO backends are disabled for the
same deterministic profile. There is no new runtime DLL dependency.

## API and ownership

All **59 exported functions** of the pinned header have native signatures, plus
the `IMG_Animation` structure. `tools/generate_image_bindings.py` records the
unconditional function-name census; `DAS_BIND_FUN` infers signatures from C++.
The saved snapshot is consumed without Python/Clang/LLVM. Do not edit
`src/libraries/generated/image_functions.inc` by hand. Regenerate/check with:

```powershell
python tools/generate_image_bindings.py <SDL_image-source>/include/SDL3_image/SDL_image.h --check
```

This small header export inventory is separate from the core SDL dasclang
generator. Header version/count changes require review, not silently adding names.

| Boost functions | Result and ownership |
| --- | --- |
| `load_image(path)` / `load_image(io, kind="")` | `Result<SDL_Surface?, SdlError>`; caller destroys successful surface |
| `load_image_texture(renderer, path/io)` | Owned SDL texture; IO overload accepts optional type hint |
| `load_image_animation(path/io)` | Owned `IMG_Animation?`; IO overload accepts optional type hint |
| `with_image`, `with_image_texture`, `with_image_animation` | Path/IO scopes; return body's Result, defer matching destroy/free |
| `save_image_png/jpg/avif(surface, path/io)` | `Result<SdlUnit, SdlError>`; AVIF reports failure in this profile |
| `image_animation_frame(animation, index)` | Checked index, **borrowed** surface; animation must outlive use |
| `image_animation_delay(animation, index)` | Checked index, delay in milliseconds |

Factories transfer ownership only by convention: pointer results are not linear
types. Prefer scopes. Do not free animation frames independently. Raw animation
fields (`w`, `h`, `count`, `frames`, `delays`) preserve native memory/lifetime rules.
Raw XPM array loaders likewise require valid caller-owned pointer arrays; no safe
array adapter is claimed for them.

Every boost IO overload borrows the stream (`closeio=false`). Nest it in `with_io`
or `with_io_file`; this avoids closing a stream twice. Raw `IMG_*_IO` retains the
original `closeio` parameter and consumes the stream when true, including failed
loads. Type-specific loaders without a closeio parameter borrow the stream.
Format predicates remain bool: false is not converted to an SDL error.

Errors are copied immediately on null/false, before resource cleanup. Success
ignores stale SDL error strings. Result errors and early returns run defer;
arbitrary application panic is not a cleanup guarantee.

## Example and verification

[02_image.das](../examples/libraries/02_image.das) loads a transparent PNG and an
SVG as textures using `sdl_scope`, `sdl_use` and `sdl_try`. Assets are procedural
fixtures from this project, with no external artwork. See
[library example instructions](../examples/libraries/README.md).

Local Windows checks:

- PNG path/IO/type-hinted loading: exact RGBA pixels, including alpha; PNG save/load
  through files and dynamic streams; JPEG save/load with lossy tolerance and opaque alpha.
- Texture loading from path/IO, dimensions, rendered alpha over a black background.
- GIF animation from path/IO, two frame colors, 50/90 ms delays and bounds errors.
- Missing/corrupt files, stale error on success, copied error after ClearError,
  skipped body on failed creation and preserved body error.
- Native close callbacks observed across **24 script calls**: six general/typed
  surface/texture/animation loaders, good/bad input, closeio true/false.
- Example and functional tests pass with legacy/CppGenBind SDL registrations and
  AOT with fallback disabled. Raw close-callback fixture is interpreter-tested.
- An image-only consumer (`DASSDL3_WITH_IMGUI=OFF`) builds and passes the example
  and functional tests with LLVM/Clang/Python discovery and generators disabled.

`tests/clangbind_parity` enables these checks with `DASSDL3_TEST_IMAGE=ON` and
`SDL_IMAGE_INCLUDE=<source>/include`; build `image_aot_runner`, `baseline_runner`,
`cppgenbind_runner`. The main library must be built first.

Not claimed: runtime coverage of all 59 functions/all image formats, external
codecs, animation WebP, browser builds, GPU texture upload or hostile-input fuzzing.
