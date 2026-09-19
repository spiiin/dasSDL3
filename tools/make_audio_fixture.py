"""Create the original quiet WAV fixture (mono PCM16, 22050 Hz, 0.4 seconds)."""
import math
from pathlib import Path
import struct
import wave

path = Path(__file__).resolve().parents[1] / 'examples/assets/tone.wav'
rate = 22050
count = 8820
samples = []
for i in range(count):
    envelope = min(1.0, i / 441, (count - 1 - i) / 441)
    samples.append(round(32767 * 0.12 * envelope * math.sin(2 * math.pi * 440 * i / rate)))
with wave.open(str(path), 'wb') as out:
    out.setparams((1, 2, rate, count, 'NONE', 'not compressed'))
    out.writeframes(struct.pack('<' + 'h' * count, *samples))
print(path)
