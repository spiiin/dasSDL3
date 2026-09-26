# Library example assets

The following image fixtures were created for this project; no third-party artwork.

- `alpha.png`: 32x32 RGBA8, every row has 16 pixels `(220,40,70,255)` then
  16 pixels `(30,190,240,96)`. Standard PNG chunks, zlib-compressed filter-0 rows.
- `sample.svg`: 32x32 rectangle, fill `#dc2846`.
- `two_frames.gif`: GIF89a, 1x1 red then green, delays 50 and 90 milliseconds.
- `invalid.bin`: deliberately invalid image data for failure tests.

JPEG and PNG output fixtures are generated in each test executable's directory
with unique names, checked and removed by defer. They are not repository assets.

## Font

`JetBrainsMono-Regular.ttf` is copied unchanged from the pinned daScript
`modules/dasImgui/font` directory; it does not require enabling ImGui.
Copyright 2020 The JetBrains Mono Project Authors. SIL Open Font License 1.1,
see `OFL.txt` and `AUTHORS.txt` in this directory. The font is not modified.

## Shaping font

`Amiri-Regular.ttf` is unmodified from [Amiri 1.003](https://github.com/aliftype/amiri/releases/tag/1.003),
Copyright 2010–2022 The Amiri Project Authors. License: `Amiri-OFL.txt` (SIL OFL 1.1).
Source release asset: `https://github.com/aliftype/amiri/releases/download/1.003/Amiri-1.003.zip`.
Archive SHA256: `81af0aff7d2086d8af24cea7202f7546130997982534691373485cd96744d05e`.
Font SHA256: `cd2550c0f4c05eb341bf97958211aaa39382bca96577ba3a67d4a3b4912c43c0`.
Used by example 04 and shaping tests; the font supplies Arabic and Latin glyphs.

## Mixer PCM fixture

`mixer-tone.wav` was generated for this project, without third-party audio:
4800 mono samples, 48 kHz, PCM16 little endian. Sample i is
`int(2500 * sin(i * 2 * pi * 440 / 48000))`. It tests WAV loading and decoding;
the public example uses MIX_CreateSineWaveAudio instead of loading this file.
