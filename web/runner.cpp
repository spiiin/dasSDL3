#include "daScript/daScript.h"
#include "daScript/misc/sysos.h"
#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <emscripten.h>
#include <memory>
MAKE_TYPE_FACTORY(SDL_Event, SDL_Event);
DECLARE_MODULE(Module_dasSDL3);
DECLARE_MODULE(Module_dasOpenGL);
using namespace das;
namespace {
struct Session {
    TextPrinter output;
    ModuleGroup modules;
    smart_ptr<FsFileAccess> access=make_smart<FsFileAccess>();
    ProgramPtr program;
    std::unique_ptr<Context> context;
    SimFunction * init=nullptr,*frame=nullptr,*event=nullptr,*quit=nullptr;
    bool initialized=false;
};
bool stopRequested=false;
SDL_AppResult invoke(Session & s,SimFunction * fn,vec4f * args=nullptr) {
    auto value=s.context->evalWithCatch(fn,args);
    if(const char * error=s.context->getException()) {
        s.output << "Script exception: " << error << "\n";return SDL_APP_FAILURE;
    }
    const int code=cast<int32_t>::to(value);
    return code<0 ? SDL_APP_FAILURE : code>0 ? SDL_APP_SUCCESS : SDL_APP_CONTINUE;
}
}
extern "C" EMSCRIPTEN_KEEPALIVE void web_stop() {stopRequested=true;}
SDL_AppResult SDL_AppInit(void ** appstate,int argc,char ** argv) {
    stopRequested=false;
    setDasRoot("/");
    NEED_ALL_DEFAULT_MODULES;
    NEED_MODULE(Module_dasSDL3);
    NEED_MODULE(Module_dasOpenGL);
    Module::Initialize();
    auto * s=new Session();*appstate=s;
    s->access->addFsRoot("dassdl3","/dassdl3");
    const char * path=argc>1 ? argv[1] : "/examples/02_square.das";
    s->program=compileDaScript(path,s->access,s->output,s->modules);
    if(s->program->failed()) {
        for(auto & e:s->program->errors)s->output << reportError(e.at,e.what,e.extra,e.fixme,e.cerr);
        return SDL_APP_FAILURE;
    }
    s->context=std::make_unique<Context>(s->program->getContextStackSize());
    if(!s->program->simulate(*s->context,s->output))return SDL_APP_FAILURE;
    s->init=s->context->findFunction("app_init");s->frame=s->context->findFunction("app_frame");
    s->event=s->context->findFunction("app_event");s->quit=s->context->findFunction("app_quit");
    if(!s->init || !s->frame || !s->event || !s->quit ||
       !verifyCall<int32_t>(s->init->debugInfo,s->modules) ||
       !verifyCall<int32_t>(s->frame->debugInfo,s->modules) ||
       !verifyCall<int32_t, const SDL_Event &>(s->event->debugInfo,s->modules) ||
       !verifyCall<void>(s->quit->debugInfo,s->modules)) {
        s->output << "Invalid Web entry points: app_init/frame/event/quit\n";return SDL_APP_FAILURE;
    }
    s->initialized=true;
    return invoke(*s,s->init);
}
SDL_AppResult SDL_AppIterate(void * state) {
    if(stopRequested)return SDL_APP_SUCCESS;
    auto & s=*static_cast<Session *>(state);return invoke(s,s.frame);
}
SDL_AppResult SDL_AppEvent(void * state,SDL_Event * event) {
    auto & s=*static_cast<Session *>(state);
    vec4f args[]={cast<const SDL_Event *>::from(event)};
    return invoke(s,s.event,args);
}
void SDL_AppQuit(void * state,SDL_AppResult result) {
    auto * s=static_cast<Session *>(state);
    if(s) {
        if(s->initialized) {
            s->context->restart();s->context->evalWithCatch(s->quit,nullptr);
            if(const char * e=s->context->getException()) {s->output << "Cleanup exception: " << e << "\n";result=SDL_APP_FAILURE;}
        }
        delete s;
    }
    SDL_Quit();Module::Shutdown();
    // SDL 3.4.16 creates an empty recording object when opening playback.
    // Its close path then leaves AudioContext running. After full SDL_Quit no
    // device may use this context; finish host cleanup without patching SDL.
    EM_ASM({
        const audio = Module['SDL3'];
        if (audio && audio.audioContext) {
            const context = audio.audioContext;
            audio.audioContext = undefined;
            if (context.state !== 'closed') { context.close(); }
        }
        Module.onSessionEnd?.($0);
    },result==SDL_APP_FAILURE ? 1 : 0);
}
