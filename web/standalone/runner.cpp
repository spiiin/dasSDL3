#include "app.das.h"
#include "daScript/ast/ast.h"
#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <emscripten.h>
#include <memory>
#include <type_traits>
#include <cstdio>
#include <cstdlib>
namespace {
using App = das::ctx_app::Standalone;
struct Session {
    das::daScriptEnvironment environment;
    das::daScriptEnvironmentGuard guard{&environment,nullptr};
    std::unique_ptr<App> app;
    bool started=false;
};
bool stopRequested=false;
template<class T, class = void> struct HasEvent : std::false_type {};
template<class T> struct HasEvent<T,std::void_t<decltype(std::declval<T &>().app_event(std::declval<const SDL_Event &>()))>> : std::true_type {};
template<class T, class = void> struct HasExit : std::false_type {};
template<class T> struct HasExit<T,std::void_t<decltype(std::declval<T &>().exit_code())>> : std::true_type {};
template<class F> bool invoke(Session & s, const char * name, F && call) {
    try {
        if (s.app) s.app->restart();
        call();
        return true;
    } catch (const std::exception & e) {
        fprintf(stderr,"Lifecycle exception in %s: %s\n",name,e.what());
        return false;
    }
}
template<class T> int event(T & app, const SDL_Event & e) {
    if constexpr (HasEvent<T>::value) return app.app_event(e);
    return e.type==SDL_EVENT_QUIT ? 1 : 0;
}
template<class T> int exitCode(T & app) {
    if constexpr (HasExit<T>::value) return app.exit_code();
    return 0;
}
}
extern "C" EMSCRIPTEN_KEEPALIVE void web_stop() { stopRequested=true; }
SDL_AppResult SDL_AppInit(void ** state,int argc,char ** argv) {
    stopRequested=false;
    auto * s=new Session(); *state=s;
    return invoke(*s,"init",[&] {
        s->app=std::make_unique<App>();
        puts("wasm32 standalone AOT; no compiler, no interpreter fallback");
#ifdef DASSDL3_FAULT_FIXTURE
        s->app->configure(argc>1 ? std::atoi(argv[1]) : 0);
#endif
        s->started=true;
        s->app->init();
    }) ? SDL_APP_CONTINUE : SDL_APP_FAILURE;
}
SDL_AppResult SDL_AppIterate(void * state) {
    if (stopRequested) return SDL_APP_SUCCESS;
    auto & s=*static_cast<Session *>(state);
    bool running=false;
    if (!invoke(s,"update",[&] { running=s.app->update(); })) return SDL_APP_FAILURE;
    if (!running) return SDL_APP_SUCCESS;
    // No script frame remains here: retain globals, collect temporary arrays/strings.
    if (!invoke(s,"collect",[&] { s.app->collectHeapIfMostlyFree(); })) return SDL_APP_FAILURE;
    return SDL_APP_CONTINUE;
}
SDL_AppResult SDL_AppEvent(void * state,SDL_Event * e) {
    auto & s=*static_cast<Session *>(state);
    int code=0;
    if (!invoke(s,"app_event",[&] { code=event(*s.app,*e); })) return SDL_APP_FAILURE;
    return code<0 ? SDL_APP_FAILURE : code>0 ? SDL_APP_SUCCESS : SDL_APP_CONTINUE;
}
void SDL_AppQuit(void * state,SDL_AppResult result) {
    auto * s=static_cast<Session *>(state);
    if (s && s->started) {
        if (!invoke(*s,"shutdown",[&] { s->app->shutdown(); })) result=SDL_APP_FAILURE;
        int code=0;
        if (!invoke(*s,"exit_code",[&] { code=exitCode(*s->app); }) || code!=0) result=SDL_APP_FAILURE;
    }
    delete s;
    SDL_Quit();
    das::clearGlobalAotLibrary();
    EM_ASM({ Module.onSessionEnd?.($0); },result==SDL_APP_FAILURE ? 1 : 0);
}
