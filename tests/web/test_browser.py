"""Browser tests for the generated static site. pip install playwright pillow first."""
import argparse
from pathlib import Path
from io import BytesIO
from PIL import Image
from playwright.sync_api import sync_playwright

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--url',default='http://127.0.0.1:8765')
parser.add_argument('--browser',choices=['edge','chrome','firefox'],default='edge')
parser.add_argument('--output',type=Path,default=Path('build/web/screenshots'))
a=parser.parse_args();a.output.mkdir(parents=True,exist_ok=True)
with sync_playwright() as pw:
    browser=(pw.firefox.launch(headless=True) if a.browser=='firefox' else pw.chromium.launch(channel='msedge' if a.browser=='edge' else 'chrome',headless=True))
    def open_page(name):
        page=browser.new_page(viewport={'width':1100,'height':1000})
        errors=[]
        page.on('pageerror',lambda error:errors.append(str(error)))
        page.goto(a.url+'/'+name+'.html')
        page.wait_for_function("document.querySelector('#status').textContent !== 'Loading runtime…'",timeout=120000)
        assert page.locator('#status').inner_text()=='Ready', page.locator('#output').inner_text()
        return page,errors
    for name in ['01_hello','02_square','03_input','04_textures','05_streaming','06_target','07_geometry','08_audio']:
        page,errors=open_page(name)
        page.locator('#start').click()
        if name=='08_audio':
            page.wait_for_function("runtime.SDL3?.audio_playback?.scriptProcessorNode || document.querySelector('#status').textContent==='Failed'",timeout=30000)
            assert page.locator('#status').inner_text()=='Running',page.locator('#output').inner_text()
            page.evaluate("""()=>{
                window.audioProbe={peak:0,calls:0,context:runtime.SDL3.audioContext};
                const node=runtime.SDL3.audio_playback.scriptProcessorNode;
                const original=node.onaudioprocess;
                node.onaudioprocess=function(event){
                    original.call(this,event);
                    for(const value of event.outputBuffer.getChannelData(0))
                        audioProbe.peak=Math.max(audioProbe.peak,Math.abs(value));
                    audioProbe.calls++;
                };
            }""")
            page.wait_for_function("audioProbe.peak>0.01 && audioProbe.calls>2 && audioProbe.context.state==='running'",timeout=30000)
        if name=='01_hello':
            page.wait_for_function("document.querySelector('#status').textContent==='Stopped'",timeout=30000)
            assert 'Hello from daScript' in page.locator('#output').inner_text()
        else:
            page.wait_for_function("document.querySelector('#output').textContent.includes('Rendered 60 frames.') || document.querySelector('#status').textContent==='Failed'",timeout=30000)
            assert page.locator('#status').inner_text()=='Running',page.locator('#output').inner_text()
            # Screenshot pixels come from the real canvas, not app-reported success.
            shot=page.locator('canvas').screenshot()
            image=Image.open(BytesIO(shot)).convert('RGB')
            colors=image.getcolors(image.width*image.height)
            expected=(245,184,66) if name=='03_input' else (70,200,160)
            assert colors and sum(count for count,color in colors if color==expected)>1000,'Expected foreground pixels missing'
            dimensions=page.locator('canvas').evaluate('(c)=>({w:c.width,h:c.height})')
            assert abs(dimensions['w']/dimensions['h']-4/3)<0.02,dimensions
            if name=='03_input':
                page.locator('canvas').click()
                page.keyboard.press('a')
                page.wait_for_function("document.querySelector('#output').textContent.includes('Key:') && document.querySelector('#output').textContent.includes('Mouse click:')")
            if name=='05_streaming':
                # A second real frame must change the uploaded band, not just redraw a static texture.
                page.wait_for_timeout(150)
                assert page.locator('canvas').screenshot()!=shot,'Streaming texture did not change'
            page.screenshot(path=str(a.output/(a.browser+'-'+name+'.png')))
            if name=='02_square':
                page.set_viewport_size({'width':720,'height':950})
                page.wait_for_function("document.querySelector('canvas').width < 750 && document.querySelector('canvas').width > 0")
            page.locator('#stop').click()
            page.wait_for_function("document.querySelector('#status').textContent==='Stopped'",timeout=10000)
        if name=='08_audio':
            page.wait_for_function("audioProbe.context.state==='closed' && !runtime.SDL3.audio_playback")
        output=page.locator('#output').inner_text()
        assert output.count('Session released')==1,output
        assert not errors,errors
        if name in ['02_square','08_audio']:
            page.set_viewport_size({'width':720,'height':950})
            page.locator('#restart').click()
            page.wait_for_function("document.querySelector('#status').textContent==='Ready'",timeout=120000)
            page.locator('#start').click()
            page.wait_for_function("document.querySelector('#output').textContent.includes('Rendered 60 frames.')",timeout=30000)
            size=page.locator('canvas').evaluate('(c)=>({w:c.width,h:c.height})')
            assert size['w']<dimensions['w'] and abs(size['w']/size['h']-4/3)<0.02,size
            page.locator('#stop').click()
            page.wait_for_function("document.querySelector('#status').textContent==='Stopped'",timeout=10000)
            assert page.locator('#output').inner_text().count('Session released')==1
        print(a.browser,name,'PASS',flush=True)
        page.close()
    for fault in ['compile','init','frame','target','audio','streaming','geometry']:
        name={'init':'04_textures','target':'06_target','audio':'08_audio','streaming':'05_streaming','geometry':'07_geometry'}.get(fault,'02_square')
        page,errors=open_page(name)
        path='/examples/'+name+'.das'
        source=page.evaluate('(path)=>runtime.FS.readFile(path,{encoding:"utf8"})',path)
        if fault=='compile': source='this is not valid daScript'
        elif fault=='init': source=source.replace('/assets/checker.bmp','/assets/missing.bmp')
        elif fault=='target': source=source.replace('    destroy_texture(texture);texture=null','    print("Target restored: {SDL_GetRenderTarget(renderer)==null}\\n")\n    destroy_texture(texture);texture=null').replace('return sdl_ok()\n    } |> sdl_try','return err(SdlError(operation="target probe",message="expected"),type<SdlUnit>)\n    } |> sdl_try')
        elif fault=='streaming': source=source.replace('    texture |> upload_rgba8','    pixels |> resize(1)\n    texture |> upload_rgba8')
        elif fault=='geometry': source=source.replace('array<int>(0,1,2)','array<int>(0,1,9)')
        elif fault=='audio': source=source.replace('stream |> resume_audio() |> sdl_try','return err(SdlError(operation="audio probe",message="expected"),type<SdlUnit>)')
        else: source=source.replace('def draw_frame() : $Result<SdlUnit; SdlError> {','def draw_frame() : $Result<SdlUnit; SdlError> {\n    if(frames==2) {return err(SdlError(operation="frame probe",message="expected"),type<SdlUnit>)}')
        page.evaluate('([path,source])=>runtime.FS.writeFile(path,source)',[path,source])
        page.locator('#start').click()
        page.wait_for_function("document.querySelector('#status').textContent==='Failed'",timeout=30000)
        output=page.locator('#output').inner_text()
        assert output.count('Session released')==(0 if fault=='compile' else 1),output
        if fault=='streaming': assert 'upload_rgba8' in output,output
        if fault=='geometry': assert 'geometry: index out of bounds' in output,output
        if fault=='init': assert 'missing.bmp' in output,output
        if fault in ['target','audio']: assert fault+' probe: expected' in output,output
        if fault=='target': assert 'Target restored: true' in output,output
        if fault=='audio': assert page.evaluate('()=>!runtime.SDL3.audio_playback && !runtime.SDL3.audioContext')
        if fault=='frame': assert 'frame probe: expected' in output,output
        assert not errors,errors
        print(a.browser,fault,'error and cleanup PASS',flush=True)
        page.close()
    browser.close()
