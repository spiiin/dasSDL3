"""Recreate original project assets for the Lazy Foo topic examples. Requires Pillow."""
from pathlib import Path
import math, struct, wave
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[1]
assets=root/'examples/sdl_port_lazyfoo/assets'
assets.mkdir(parents=True,exist_ok=True)
im=Image.new('RGB',(128,32),(255,0,255));d=ImageDraw.Draw(im)
for i in range(4):
 x=i*32;d.ellipse((x+3,3,x+28,28),fill=[(255,190,55),(85,215,140),(65,160,245),(220,105,215)][i]);d.rectangle((x+8,9,x+11,13),fill='black');d.rectangle((x+20,9,x+23,13),fill='black');d.line((x+9,21-i,x+22,21+i),fill='black',width=2)
im.save(assets/'sprites.png'); im.save(assets/'sprites.bmp')
alpha=im.convert('RGBA')
alpha.putdata([(red,green,blue,0 if (red,green,blue)==(255,0,255) else 255) for red,green,blue in im.getdata()])
alpha.save(assets/'sprites-alpha.png')
with wave.open(str(assets/'melody.wav'),'wb') as w:
 w.setparams((1,2,22050,0,'NONE','not compressed'))
 w.writeframes(b''.join(struct.pack('<h',int(3500*math.sin(2*math.pi*[262,330,392,523][int(t/5512)%4]*t/22050)*min(1,(t%5512)/100,(5512-t%5512)/100))) for t in range(22050)))
