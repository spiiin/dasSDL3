from pathlib import Path
import argparse,os,json,subprocess,time

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description='Windows desktop check: visible SDL windows and WASAPI audio. Close each window with Escape to advance.')
parser.add_argument('--runner',type=Path,default=root/'build/ninja/bin/dasSDL3_libraries_runner.exe')
parser.add_argument('--output',type=Path,default=root/'build/ninja/lazyfoo-desktop')
parser.add_argument('--lesson',type=int,choices=range(1,21))
parser.add_argument('--timeout',type=float,default=180)
args=parser.parse_args()
if os.name!='nt':parser.error('This check selects Windows video and WASAPI audio.')
if args.timeout<=0:parser.error('--timeout must be positive')
out=args.output
out.mkdir(parents=True,exist_ok=True)
out.mkdir(exist_ok=True)
env=os.environ.copy()
for key in ['SDL_VIDEO_DRIVER','SDL_VIDEODRIVER','SDL_AUDIO_DRIVER','SDL_AUDIODRIVER','SDL_RENDER_DRIVER','DASSDL3_LAZYFOO_CAPTURE','DASSDL3_LAZYFOO_TEST_CLIPBOARD']:
    env.pop(key,None)
env['SDL_VIDEO_DRIVER']='windows'
env['SDL_AUDIO_DRIVER']='wasapi'
env['SDL_ASSERT']='abort'
records=[]
for script in sorted((root/'examples/sdl_port_lazyfoo').glob('[0-9][0-9]_*.das')):
    if args.lesson is not None and int(script.name[:2])!=args.lesson:continue
    logfile=out/(script.stem+'.log')
    with logfile.open('wb') as output:
        process=subprocess.Popen([str(args.runner.resolve()),str(script)],env=env,stdout=output,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        (out/'current.json').write_text(json.dumps(dict(script=script.name,pid=process.pid,started=time.time())))
        print('OPEN',script.name,process.pid,flush=True)
        try:code=process.wait(timeout=args.timeout)
        except subprocess.TimeoutExpired:
            process.terminate();process.wait(timeout=10);raise RuntimeError(f'UI verification timed out: {script.name}')
    log=logfile.read_text(errors='replace')
    assert code==0 and 'Lesson completed; scopes released.' in log,(script.name,code,log)
    records.append(dict(script=script.name,exit_code=code))
    print('CLOSED',script.name,code,flush=True)
    time.sleep(.5)
(out/'results.json').write_text(json.dumps(dict(video_driver='windows',audio_driver='wasapi',renderer='automatic',mode='interactive, no smoke-test flag',cases=records),indent=2))
print(f'All {len(records)} visible desktop examples exited cleanly.',flush=True)
