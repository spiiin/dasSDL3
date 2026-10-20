"""Pixel contracts and optional unchanged C-reference comparisons for Forge 15-20."""
import argparse, hashlib, json, os, subprocess, tempfile
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--runner',required=True)
    p.add_argument('--driver',default='vulkan')
    p.add_argument('--original-bin',type=Path)
    p.add_argument('--aot',action='store_true')
    a=p.parse_args()
    assets=ROOT/'examples/gpu_port_forge/assets'
    manifest=json.loads((assets/'advanced_sources.json').read_text())
    for name,digest in manifest['outputs'].items():
        assert hashlib.sha256((assets/name).read_bytes()).hexdigest()==digest,name
    with tempfile.TemporaryDirectory(prefix='forge-advanced-') as folder:
        out=Path(folder)
        env=dict(os.environ,SDL_GPU_DRIVER=a.driver,SDL_ASSERT='abort',DASSDL3_FORGE_ADVANCED_CAPTURE=folder)
        def run(args):
            result=subprocess.run(args,env=env,capture_output=True,text=True,timeout=150)
            assert result.returncode==0,result.stdout+result.stderr
            assert not any(x in result.stdout+result.stderr for x in ['VUID-','Validation Error','D3D12 ERROR','D3D12 CORRUPTION']),result.stdout+result.stderr
            return result
        args=[a.runner,str(ROOT/'tests/forge_advanced_pixels.das')]
        if not a.aot:args+=['--smoke-test']
        print(run(args).stdout)
        captures={}
        def rgba(name):
            if name not in captures:
                captures[name]=np.frombuffer((out/(name+'.rgba')).read_bytes(),dtype=np.uint8).reshape(720,1280,4)
            return captures[name]
        for i in range(3):
            depth=rgba(f'forge_15_cascade_{i}')
            assert np.max(depth[:,:,:3])-np.min(depth[:,:,:3])>16,('empty cascade',i)
            assert np.all(depth[:,:,0]==depth[:,:,1]) and np.all(depth[:,:,0]==depth[:,:,2])
        for first,second in [('forge_17_default','forge_17_flat'),('forge_19_changed','forge_19_moving'),('forge_20_default','forge_20_mode_1'),('forge_20_mode_1','forge_20_mode_2')]:
            different=np.count_nonzero(np.any(rgba(first)!=rgba(second),axis=2))
            assert different>100,(first,second,different)
        # Independent pixel oracle: the three fog equations, evaluated on ground
        # rays for the original camera. Invert sRGB before comparing visibility.
        eye=np.array([-6.,5.,6.]);yaw,pitch=np.deg2rad([-40.,-25.])
        forward=np.array([-np.sin(yaw)*np.cos(pitch),np.sin(pitch),-np.cos(yaw)*np.cos(pitch)])
        right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
        def linear(rgb):
            v=rgb/255.;return np.where(v<=.04045,v/12.92,((v+.055)/1.055)**2.4)
        clear=linear(rgba('forge_20_changed')[:,:,:3].astype(float))
        # Conservative occluder boxes, intersected along the entire ray rather
        # than only its ground endpoint (a raised box can hide distant ground).
        bounds=[(np.array([-2.,0.,-3.]),np.array([2.,5.,3.]))]
        for i in range(12):
            j=i if i<8 else (i-8)*2
            center=np.array([5*np.cos(j*np.pi/4),.5 if i<8 else 1.5,5*np.sin(j*np.pi/4)])
            bounds.append((center-[.72,.51,.72],center+[.72,.51,.72]))
        def occluded(ray,ground_t):
            for lo,hi in bounds:
                a=(lo-eye)/ray;b=(hi-eye)/ray
                enter=max(float(np.minimum(a,b).max()),0.)
                leave=float(np.maximum(a,b).min())
                if enter<=leave and enter<ground_t:return True
            return False
        samples=0
        for y in range(500,710,23):
            for x in range(30,1250,47):
                ray=forward+right*((2*(x+.5)/1280-1)*(1280/720)/np.sqrt(3))+up*((1-2*(y+.5)/720)/np.sqrt(3))
                if ray[1]>=0:continue
                ground_t=-eye[1]/ray[1]
                if occluded(ray,ground_t):continue
                point=eye+ray*ground_t;distance=np.linalg.norm(point-eye)
                for mode,name in enumerate(['forge_20_default','forge_20_mode_1','forge_20_mode_2']):
                    factor=np.clip((18-distance)/16,0,1) if mode==0 else np.exp(-(.12*distance) if mode==1 else -(.08*distance)**2)
                    expected=.5*(1-factor)+clear[y,x]*factor
                    actual=linear(rgba(name)[y,x,:3].astype(float))
                    assert np.max(np.abs(expected-actual))<.012,(mode,x,y,expected,actual)
                samples+=1
        assert samples>50,samples
        print(f'Fog CPU ray/distance oracle: {samples} ground pixels x 3 modes PASS')
        if a.original_bin:
            for lesson in range(15,21):
                exe=a.original_bin/(f'original_{lesson}'+('.exe' if os.name=='nt' else ''))
                run([str(exe),'--screenshot',str(out/f'original_{lesson}.bmp'),'--capture-frame','5'])
                original=np.asarray(Image.open(out/f'original_{lesson}.bmp').convert('RGB'),dtype=np.int16)
                port=rgba(f'forge_{lesson}_default')[:,:,:3].astype(np.int16)
                difference=np.abs(original-port);mean=float(difference.mean());close=float((difference<=2).mean())
                # C debug circle advances wall time; allow that moving line only.
                limit,ratio=(.8,.995) if lesson==19 else ((.08,.9985) if lesson==15 else (.03,.9995))
                assert mean<limit and close>ratio,(lesson,mean,close)
                print(f'Forge {lesson} {a.driver}: original C vs DSL MAE={mean:.5f}/255; {close:.6%} within 2/255')
if __name__=='__main__':main()
