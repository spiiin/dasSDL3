"use strict";
const $=id=>document.getElementById(id);
const params=new URLSearchParams(location.search);
const name=params.get('app') || 'square';
let runtime, running=false, ended=false, restarting=false;
function log(text){$('output').textContent+=String(text)+'\n';}
function failed(error){log(error);$('status').textContent='Failed';$('start').disabled=true;$('stop').disabled=true;$('restart').disabled=false;}
if (!['square','gc','sdl_gc','faults'].includes(name)) { failed('Unknown application'); }
else {
    const loader=document.createElement('script');
    loader.src=name+'.js';
    loader.onerror=()=>failed('Cannot load application');
    loader.onload=()=>createStandalone({canvas:$('canvas'),print:log,printErr:log,onAbort:failed,
        onSessionEnd(code){running=false;ended=true;$('status').textContent=code?'Failed':'Stopped';$('stop').disabled=true;$('restart').disabled=false;if(restarting)location.reload();}
    }).then(module=>{runtime=module;$('status').textContent='Ready';$('start').disabled=false;}).catch(failed);
    document.head.appendChild(loader);
}
$('start').onclick=()=>{
    if (!runtime || running || ended) return;
    running=true;$('status').textContent='Running';$('start').disabled=true;$('stop').disabled=false;$('restart').disabled=false;$('canvas').focus();
    try { runtime.callMain([params.get('mode') || '0']); } catch(error) { if(error!=='unwind')failed(error); }
};
$('stop').onclick=()=>{if(running){$('status').textContent='Stopping…';runtime._web_stop();}};
$('restart').onclick=()=>{if(running){restarting=true;runtime._web_stop();}else location.reload();};
