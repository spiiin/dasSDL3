# Example asset

checker.bmp is an original 128 x 128, 24-bit uncompressed BMP fixture created
for this project: teal/navy 16-pixel checker squares and a 4-pixel gold border.
No external artwork or image library is required. The border is also used by
the texture integration test to verify rendered pixels.

CMake copies it to build/ninja/bin/assets/checker.bmp. The example resolves it
relative to SDL_GetBasePath(), not the current working directory.

textures.das adapts the public-domain SDL 3.2.18 example:
https://github.com/libsdl-org/SDL/blob/release-3.2.18/examples/renderer/06-textures/textures.c
It replaces callbacks with a scoped event loop and adds scaling and cropping.

Audio: tone.wav is an original quiet 440 Hz, 0.4-second PCM16 mono signal
at 22050 Hz with short fades. Recreate it with tools/make_audio_fixture.py.
No music from the upstream example is included. CMake copies it to bin/assets.
