"""Uses the existing bgfx VS2022 projects and cached Release dependencies.
Build the generated audit-36-sky/audit-31-rsm.vcxproj in a developer shell.
2s warm-up, 5s measurement; 1280x720 Vulkan, no vsync or UI.
"""
from pathlib import Path
import hashlib
import argparse
p=argparse.ArgumentParser(description='Generate isolated Release bgfx sky/rsm benchmark projects; originals are untouched.')
p.add_argument('--bgfx',required=True,type=Path)
root=p.parse_args().bgfx.resolve()
tick=r'''    bool benchMeasuring=false;
    int benchFrames=0;
    double benchCpu=0,benchGpu=0,benchDraws=0,benchPrims=0;
    std::chrono::steady_clock::time_point benchStart{};
    bool benchTick() {
        const auto now=std::chrono::steady_clock::now();
        if (benchStart.time_since_epoch().count()==0) benchStart=now;
        const double seconds=std::chrono::duration<double>(now-benchStart).count();
        const auto* st=bgfx::getStats();
        if (!benchMeasuring && seconds>=2.0) {
            if (m_width!=1280 || m_height!=720 || st->width!=1280 || st->height!=720 || bgfx::getRendererType()!=bgfx::RendererType::Vulkan || m_reset!=0) {
                std::fprintf(stderr,"BENCH_INVALID size=%ux%u backbuffer=%ux%u reset=%u\n",m_width,m_height,st->width,st->height,m_reset); std::exit(2);
            }
            std::printf("BENCH_VERIFIED view=1280x720 backbuffer=1280x720 renderer=Vulkan reset=0 UI=off fixed_time=3\n");
            benchMeasuring=true; benchFrames=0; benchStart=now;
        } else if (benchMeasuring) {
            ++benchFrames;
            benchCpu+=double(st->cpuTimeEnd-st->cpuTimeBegin)*1000.0/double(st->cpuTimerFreq);
            if(st->gpuTimerFreq>0) benchGpu+=double(st->gpuTimeEnd-st->gpuTimeBegin)*1000.0/double(st->gpuTimerFreq);
            benchDraws+=st->numDraw; benchPrims+=st->numPrims[bgfx::Topology::TriList];
            if(seconds>=5.0) {
                std::printf("BENCH_RESULT bgfx frames=%d seconds=%.9f fps=%.3f ms=%.6f cpu_render_ms=%.6f gpu_ms=%.6f draws=%.1f triangles=%.1f\n",benchFrames,seconds,benchFrames/seconds,seconds*1000/benchFrames,benchCpu/benchFrames,benchGpu/benchFrames,benchDraws/benchFrames,benchPrims/benchFrames);
                return false;
            }
        }
        return true;
    }
'''
tick=tick.replace('            std::printf("BENCH_VERIFIED', '            if(const char* path=std::getenv("BGFX_AUDIT_CAPTURE")){bgfx::requestScreenShot(BGFX_INVALID_HANDLE,path);}\n            std::printf("BENCH_VERIFIED')
for folder,file in [('36-sky','sky.cpp'),('31-rsm','reflectiveshadowmap.cpp')]:
 path=root/'examples'/folder/file
 expected={'36-sky':'9dbe68572801a2f641970bbc74f1ce19aa53f12d6ae6fd16f373f60654237228','31-rsm':'31bd806caf962310729bb53e40ecd16c475aaf139d60daec843be1614303f7fb'}
 assert hashlib.sha256(path.read_bytes()).hexdigest()==expected[folder], 'Unexpected upstream revision'
 src=path.read_text();src='#include <chrono>\n#include <cstdio>\n#include <cstdlib>\n'+src
 src=src.replace('m_reset = BGFX_RESET_VSYNC;','m_reset = 0;').replace('m_reset  = BGFX_RESET_VSYNC;','m_reset  = 0;')
 start=src.index('\t\t\timguiBeginFrame(');end=src.index('imguiEndFrame();',start)+len('imguiEndFrame();')
 src=src[:start]+src[end:]
 src=src.replace('\tbool update() override',tick.replace('fixed_time=3','fixed_hour=12' if folder=='36-sky' else 'static_scene')+'\n\tbool update() override')
 src=src.replace('bgfx::frame();\n\n\t\t\treturn true;','bgfx::frame();\n\n\t\t\treturn benchTick();')
 if folder=='36-sky':src=src.replace('m_time = bx::mod(m_time, 24.0f);','m_time = 12.0f;')
 assert 'return benchTick();' in src
 (root/'.build'/('audit-'+folder+'.cpp')).write_text(src)
 proj=(root/'.build/projects/vs2022'/('example-'+folder+'.vcxproj')).read_text()
 proj=proj.replace('example-'+folder,'audit-'+folder).replace('..\\..\\..\\examples\\'+folder+'\\'+file,'..\\..\\audit-'+folder+'.cpp')
 (root/'.build/projects/vs2022'/('audit-'+folder+'.vcxproj')).write_text(proj)
