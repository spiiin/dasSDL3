# Procedural SDL_image fixtures

Created for this project; no third-party artwork.

- `alpha.png`: 32x32 RGBA8, every row has 16 pixels `(220,40,70,255)` then
  16 pixels `(30,190,240,96)`. Standard PNG chunks, zlib-compressed filter-0 rows.
- `sample.svg`: 32x32 rectangle, fill `#dc2846`.
- `two_frames.gif`: GIF89a, 1x1 red then green, delays 50 and 90 milliseconds.
- `invalid.bin`: deliberately invalid image data for failure tests.

JPEG and PNG output fixtures are generated in each test executable's directory
with unique names, checked and removed by defer. They are not repository assets.
