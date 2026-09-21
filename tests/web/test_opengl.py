"""Real WebGL 2 pixels, lifecycle and shader-failure tests for SDL GL examples."""
import argparse
from pathlib import Path
from io import BytesIO
from PIL import Image
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--url',default='http://127.0.0.1:8765')
p.add_argument('--browser',choices=['edge','firefox'],default='edge')
p.add_argument('--output',type=Path,default=Path('build/web/screenshots'))
a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
with sync_playwright() as pw:
    browser=pw.firefox.launch(headless=True) if a.browser=='firefox' else pw.chromium.launch(channel='msedge',headless=True)
    for name,fault in [('01_clear',None),('02_triangle',None),('02_triangle','vertex'),('02_triangle','fragment'),('02_triangle','link'),('01_clear','context')]:
        page=browser.new_page(viewport={'width':1100,'height':1000})
        errors=[];page.on('pageerror',lambda error:errors.append(str(error)))
        page.add_init_script("""window.glProbe={shaders:0,deletedShaders:0,programs:0,deletedPrograms:0,draws:0};
            for(const [method,key] of Object.entries({createShader:'shaders',deleteShader:'deletedShaders',createProgram:'programs',deleteProgram:'deletedPrograms',drawArrays:'draws'})){
                const original=WebGL2RenderingContext.prototype[method];
                WebGL2RenderingContext.prototype[method]=function(...args){const result=original.apply(this,args);if(!method.startsWith('create')||result)glProbe[key]++;return result;};
            }""")
        if fault=='context': page.add_init_script("""const original=HTMLCanvasElement.prototype.getContext;HTMLCanvasElement.prototype.getContext=function(kind,...args){return kind==='webgl2'?null:original.call(this,kind,...args)};""")
        page.goto(a.url+'/opengl/'+name+'.html')
        page.wait_for_function("document.querySelector('#status').textContent!=='Loading runtime…'",timeout=120000)
        assert page.locator('#status').inner_text()=='Ready',page.locator('#output').inner_text()
        if fault in ['vertex','fragment','link']:
            path='/examples/opengl/'+name+'.das'
            source=page.evaluate('(path)=>runtime.FS.readFile(path,{encoding:"utf8"})',path)
            if fault=='vertex': source=source.replace('gl_Position=vec4(position,0.0,1.0);','invalid_vertex_shader;')
            if fault=='fragment': source=source.replace('outputColor=vec4(color,1.0);','invalid_fragment_shader;')
            if fault=='link': source=source.replace('in vec3 color;','in vec4 color;').replace('outputColor=vec4(color,1.0);','outputColor=color;')
            page.evaluate('([path,source])=>runtime.FS.writeFile(path,source)',[path,source])
        page.locator('#start').click()
        page.wait_for_function("document.querySelector('#status').textContent==='Failed'||document.querySelector('#output').textContent.includes('Rendered 60 frames.')",timeout=30000)
        output=page.locator('#output').inner_text()
        if fault:
            assert page.locator('#status').inner_text()=='Failed',output
            assert ('SDL_GL_CreateContext' if fault=='context' else 'glLinkProgram' if fault=='link' else 'glCompileShader') in output,output
        else:
            assert page.locator('#status').inner_text()=='Running',output
            assert 'WebGL 2' in output,output
            shot=page.locator('canvas').screenshot()
            im=Image.open(BytesIO(shot)).convert('RGB')
            colors=im.getcolors(im.width*im.height)
            if name=='01_clear': assert sum(n for n,c in colors if c==(70,200,160))>10000
            else:
                for channel in range(3):
                    assert sum(n for n,c in colors if c[channel]>160 and all(c[channel]>c[i]*1.5 for i in range(3) if i!=channel))>500,'Missing RGB corner'
                assert page.evaluate('glProbe.draws')>=60
            page.screenshot(path=str(a.output/(a.browser+'-gl-'+name+'.png')))
            page.set_viewport_size({'width':720,'height':950})
            page.wait_for_function("document.querySelector('canvas').width>0 && document.querySelector('canvas').width<750")
            page.locator('#stop').click()
            page.wait_for_function("document.querySelector('#status').textContent==='Stopped'")
        assert page.locator('#output').inner_text().count('Session released')==1
        stats=page.evaluate('glProbe')
        assert stats['shaders']==stats['deletedShaders'],stats
        assert stats['programs']==stats['deletedPrograms'],stats
        assert not errors,errors
        if not fault:
            page.locator('#restart').click()
            page.wait_for_function("document.querySelector('#status').textContent==='Ready'",timeout=120000)
            page.locator('#start').click()
            page.wait_for_function("document.querySelector('#output').textContent.includes('Rendered 60 frames.')",timeout=30000)
            page.locator('#stop').click()
            page.wait_for_function("document.querySelector('#status').textContent==='Stopped'")
            stats=page.evaluate('glProbe')
            assert stats['shaders']==stats['deletedShaders'] and stats['programs']==stats['deletedPrograms'],stats
        print(a.browser,name,fault or 'pixels/resize/restart','PASS',flush=True)
        page.close()
    browser.close()
