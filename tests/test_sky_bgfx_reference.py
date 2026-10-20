"""Check the fixed-noon Vulkan sky against a UI-free bgfx 36-sky capture."""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--reference',required=True,type=Path)
p.add_argument('--capture',required=True,type=Path)
a=p.parse_args()
original=np.asarray(Image.open(a.reference).convert('RGB'),dtype=np.int16)
assert original.shape==(720,1280,3),original.shape
port=np.frombuffer(a.capture.read_bytes(),dtype=np.uint8).reshape(720,1280,4)[:,:,:3].astype(np.int16)
difference=np.abs(original-port)
mean=float(difference.mean());close=float((difference<=2).mean())
assert mean<.03 and close>.9999,(mean,close)
print(f'Sky bgfx vs SDL DSL: MAE={mean:.6f}/255; {close:.6%} channels within 2/255 PASS')
