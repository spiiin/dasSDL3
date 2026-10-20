"""Compare unchanged original C capture output with the daScript DSL ports.
Requires Pillow/NumPy and a local FORGE_CAPTURE build of upstream 31f44fce.
"""
import argparse, os, subprocess, tempfile
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--original-bin',required=True,type=Path)
    parser.add_argument('--runner',required=True)
    parser.add_argument('--driver',default='vulkan')
    parser.add_argument('--aot',action='store_true')
    args=parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='forge-reference-') as directory:
        out=Path(directory)
        env=dict(os.environ,SDL_GPU_DRIVER=args.driver,SDL_ASSERT='abort',DASSDL3_FORGE_COLOR_CAPTURE=directory,DASSDL3_FORGE_COLOR_TAG='port')
        script=[args.runner,str(ROOT/'tests/forge_color.das')]
        if not args.aot:script.append('--smoke-test')
        process=subprocess.run(script,env=env,text=True,capture_output=True,timeout=120)
        assert process.returncode==0,process.stdout+process.stderr
        for lesson in [10,14]:
            exe=args.original_bin/('original_'+str(lesson)+('.exe' if os.name=='nt' else ''))
            process=subprocess.run([str(exe),'--screenshot',str(out/f'original_{lesson}.bmp'),'--capture-frame','5'],env=env,text=True,capture_output=True,timeout=60)
            assert process.returncode==0,process.stdout+process.stderr
            original=np.asarray(Image.open(out/f'original_{lesson}.bmp').convert('RGB'),dtype=np.int16)
            assert original.shape==(720,1280,3),original.shape
            port=np.frombuffer((out/f'port_{lesson}_srgb.rgba').read_bytes(),dtype=np.uint8).reshape((720,1280,4))[:,:,:3].astype(np.int16)
            difference=np.abs(original-port)
            mean=float(difference.mean());close=float((difference<=2).mean())
            # Allow raster edge/float rounding but reject color, camera and material regressions.
            assert mean<0.1 and close>0.9995,(lesson,mean,close)
            print(f'Forge {lesson} {args.driver}: original C vs DSL MAE={mean:.5f}/255; {close:.6%} channels within 2/255')
if __name__=='__main__':main()
