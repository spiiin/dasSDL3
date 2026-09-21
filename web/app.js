"use strict";
const examples={
  "01_hello":["01 · Hello","daScript and SDL3 inside WebAssembly. This example exits after printing its message."],
  "02_square":["02 · Moving square","Animation advances one browser frame at a time."],
  "03_input":["03 · Keyboard & mouse","Click the canvas, then press a key to move the square. Mouse clicks are logged."],
  "04_textures":["04 · Textures","A BMP loaded from the packaged filesystem, drawn at two sizes."],
  "05_streaming":["05 · Streaming texture", "CPU RGBA pixels uploaded each frame."],
  "06_target":["06 · Render target", "Draw offscreen, restore the window target, then display the texture."],
  "07_geometry":["07 · Geometry", "An indexed triangle submitted through SDL RenderGeometry."],
  "08_audio":["08 · Audio", "Start plays a quiet 440 Hz tone. Stop releases audio. Browser sound permission may be required."] ,
  "opengl/01_clear":["OpenGL 01 · Clear", "A WebGL 2 context created by SDL. Direct glClear draws a mint-green canvas."],
  "opengl/02_triangle":["OpenGL 02 · Triangle", "GLSL ES 3.00 shaders, interpolated vertex colors and a time uniform. Requires WebGL 2."]
};
const leaf=location.pathname.split('/').pop().replace(/\.html$/,'');
const key=(location.pathname.includes('/opengl/')?'opengl/':'')+leaf;
const selected=examples[key];
const $=id=>document.getElementById(id);
let runtime, running=false, ended=false, restartAfterStop=false;
let sourceUrl;
function log(text){$('output').textContent+=String(text)+'\n';$('output').scrollTop=$('output').scrollHeight;}
function failed(error){log(error);$('status').textContent='Failed';$('start').disabled=true;$('stop').disabled=true;$('restart').disabled=false;}
if(!selected){failed('Unknown example');}else{
  document.title=selected[0]+' · dasSDL3';$('title').textContent=selected[0];$('description').textContent=selected[1];
  createDasSDL3({canvas:$('canvas'),print:log,printErr:log,onAbort:failed,
    onSessionEnd(code){running=false;ended=true;$('status').textContent=code?'Failed':'Stopped';$('stop').disabled=true;$('restart').disabled=false;if(restartAfterStop)location.reload();}
  }).then(module=>{
    runtime=module;
    const text=module.FS.readFile('/examples/'+key+'.das',{encoding:'utf8'});
    $('code').textContent=text;sourceUrl=URL.createObjectURL(new Blob([text],{type:'text/plain'}));$('source').href=sourceUrl;$('source').download=key+'.das';
    $('status').textContent='Ready';$('start').disabled=false;
  }).catch(failed);
}
$('start').onclick=()=>{
  if(!runtime || running || ended)return;
  running=true;$('start').disabled=true;$('stop').disabled=false;$('restart').disabled=false;$('status').textContent='Running';$('canvas').focus();
  try{runtime.callMain(['/examples/'+key+'.das']);}catch(error){if(error!=='unwind')failed(error);}
};
$('stop').onclick=()=>{if(running){$('status').textContent='Stopping…';runtime._web_stop();}};
$('restart').onclick=()=>{if(running){restartAfterStop=true;runtime._web_stop();}else{location.reload();}};
window.addEventListener('beforeunload',()=>{if(sourceUrl)URL.revokeObjectURL(sourceUrl);});
