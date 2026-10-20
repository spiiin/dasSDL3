"""Run all independent SDL3 tutorial-topic programs, verify pixels and AOT parity."""
import argparse, hashlib, json, os, subprocess
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--runner',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--aot',action='store_true')
    ap.add_argument('--reference',type=Path)
    ap.add_argument('--driver',default='software')
    args=ap.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    env=os.environ.copy();env.update(SDL_RENDER_DRIVER=args.driver,SDL_AUDIO_DRIVER='dummy',SDL_VIDEO_DRIVER='dummy',SDL_ASSERT='abort')
    records=[]
    source=ROOT/'examples/sdl_port_lazyfoo'
    manifest=json.loads((source/'inventory.json').read_text())
    for name,digest in manifest['assets'].items():
        assert hashlib.sha256((source/name).read_bytes()).hexdigest()==digest,name
    assert len(manifest['lessons'])==21 and manifest['lessons'][0]['entry'] is None
    scripts=sorted((ROOT/'examples/sdl_port_lazyfoo').glob('[0-9][0-9]_*.das'))
    assert len(scripts)==20
    scripts.append(ROOT/'tests/lazyfoo_contracts.das')
    for script in scripts:
        capture=(args.output/(script.stem+'.bmp')).resolve()
        if capture.exists():capture.unlink()
        env['DASSDL3_LAZYFOO_CAPTURE']=str(capture)
        env['DASSDL3_LAZYFOO_TEST_CLIPBOARD']='1' if script.name.startswith('17_') else '0'
        command=[str(args.runner.resolve()),str(script)] + ([] if args.aot else ['--smoke-test'])
        process=subprocess.run(command,capture_output=True,text=True,env=env,timeout=75)
        log=process.stdout+process.stderr
        (args.output/(script.stem+'.log')).write_bytes(log.encode())
        assert process.returncode==0,(script.name,process.returncode,log[-2500:])
        assert not any(x in log for x in ['VUID-','Validation Error','D3D12 ERROR','D3D12 CORRUPTION'])
        if args.aot:assert 'main AOT=yes; fallback disabled' in log,(script,log)
        if script.stem=='lazyfoo_contracts':
            assert 'contracts passed.' in log
        else:
            assert 'Frames: 12' in log and 'Lesson completed; scopes released.' in log
            image=Image.open(capture).convert('RGB');assert image.size==(640,480)
            colors=image.getcolors(640*480);assert colors and len(colors)>1
            number=int(script.name[:2])
            palette={rgb:count for count,rgb in colors}
            # Independent numerical oracles for image loading, keying, modulation,
            # event-driven button state, time-based motion and clipped animation.
            if number==1:assert image.getpixel((320,240))==(60,190,240)
            if number==2:
                for color in [(255,190,55),(85,215,140),(65,160,245),(220,105,215)]:assert palette.get(color,0)>500
            if number==3:assert image.getpixel((304,224))==(70,220,160)
            if number==6:assert image.getpixel((320,240))==(255,190,55)
            if number==4:
                assert image.getpixel((64,150))==(40,130,100)
                assert palette.get((255,0,255),0)==0
            if number==5:assert palette.get((85,215,140),0)>10000
            if number==7:
                assert image.getpixel((90,160))==(230,230,210)
                red,green,blue=image.getpixel((128,234))
                assert 234<=red<=240 and 188<=green<=195 and 155<=blue<=162
            if number==9:assert image.getpixel((120,130))==(80,220,140)
            if number==14:assert palette.get((85,215,140),0)>5000
            if number in (13,16,18,20):assert palette.get((255,190,55),0)>=900
            if number in (13,20):assert image.getpixel((330,250))==(255,190,55)
            if number==16:
                assert image.getpixel((300,250))==(255,190,55)
                assert image.getpixel((340,180))==(210,90,100)
            if number==18:assert image.getpixel((325,245))==(255,190,55)
            if args.reference:
                reference=Image.open(args.reference/capture.name).convert('RGB')
                assert reference.tobytes()==image.tobytes(),f'{script.name}: interpreter/AOT pixels differ'
        records.append(dict(script=str(script.relative_to(ROOT)),exit_code=process.returncode,aot=args.aot,pixels=capture.name if capture.exists() else None))
        print('PASS',script.name,flush=True)
    (args.output/'results.json').write_text(json.dumps(dict(driver=args.driver,aot=args.aot,cases=records),indent=2)+'\n')
    print(f'{len(records)} programs passed, including 20 pixel captures.')
if __name__=='__main__':main()
