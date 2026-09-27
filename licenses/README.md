# Distribution notices

dasSDL3's original code is MIT licensed; see the adjacent project LICENSE.
Third-party code, generated SDL declarations, adapted examples and assets retain
their respective notices. The project license does not replace those notices.

This directory is the notice set for the pinned Windows x64 core and ImGui
daspkg profiles. Both profiles ship the entire set for simplicity; inclusion of
a notice does not mean that its component is linked into every executable.

| Component | License / selection | Scope |
|---|---|---|
| SDL 3.4.16 | zlib; bundled notices in SDL/ (including Khronos MIT/Apache-2.0) | Core |
| SDL's HIDAPI | BSD alternative selected | Core |
| SDL's stb_image | MIT alternative selected | Core |
| daScript (pinned revision in manifest.json) | BSD-3-Clause | Runtime, scripts, bindings |
| fmt, fast_float, Luau | MIT (fast_float: MIT alternative) | daScript |
| uriparser, dag_noise, vecmath | BSD-3-Clause | daScript |
| wyhash | Unlicense | daScript |
| Dear ImGui and MD4C | MIT | GUI only |
| clip / dasClipboard | MIT / daScript license | GUI only |
| FreeType 2.14.3 | FreeType License (FTL) selected; included component notices | GUI only |

The GUI distribution is based in part on the work of the FreeType Team.
Portions of this software are copyright (C) 2026 The FreeType Project
(https://freetype.org). All rights reserved.

The reference FreeType build disables external zlib, PNG, BZip2, Brotli and
HarfBuzz; bundled gzip and contributed driver/header notices are retained.
ImGui/ includes separate notices for bundled stb implementations (MIT alternative)
and the ProggyClean/ProggyForever default fonts (MIT).
The daScript upstream notices list other tools/modules too; those are not all
included in these profiles.

## Provenance and maintenance

manifest.json records the upstream-relative source path, pinned version, whether
a text is an exact comment excerpt, and SHA-256 of each copied notice. Whole
license files retain their original bytes; extracted comments retain their text.
Sources: https://github.com/GaijinEntertainment/daScript,
https://github.com/libsdl-org/SDL, https://freetype.org.
Update these snapshots when dependencies or enabled native features change.
Do not generate licenses from the machine's installed SDK during consumer builds.

The package release hook includes LICENSE and this complete directory in
modules/dasSDL3. Transfer them along with the binaries. Install/relocation/release
tests compare every shipped notice against this checked-in set.

## Other repository content and profiles

Adapted bgfx examples retain examples/gpu/LICENSE-bgfx.txt; the Special Elite font
retains examples/gpu/assets/SpecialElite-LICENSE.txt. SDL examples identify their
public-domain origin in source. These examples/assets are not shipped by the
core/GUI consumer demos. Keep their notices when distributing them.

SDL_image, SDL_ttf, SDL_mixer, SDL_net, SDL_sound, shadercross, live/HTTP,
widgets-v2 and their optional native dependencies are outside these two package
profiles. Their distributions need the notices matching their enabled features;
this directory is not a license inventory for those future distributions.
Build-only tools (LLVM, PUGIXML used by the package CLI, compilers) are not
redistributed in the standalone application. A custom SDK/module build may
require additional notices.
