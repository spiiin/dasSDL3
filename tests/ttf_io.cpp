#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <vector>
#include <algorithm>
#include <cstring>
#include <iostream>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
DECLARE_MODULE(Module_dasSDL3);
DECLARE_MODULE(Module_sdl3_ttf);

struct Stream {
    std::vector<unsigned char> bytes;
    Sint64 cursor = 0;
    int closes = 0;
};
static Sint64 SDLCALL size(void* ptr) { return static_cast<Stream*>(ptr)->bytes.size(); }
static Sint64 SDLCALL seek(void* ptr,Sint64 offset,SDL_IOWhence whence) {
    auto& s = *static_cast<Stream*>(ptr);
    auto next = offset + (whence == SDL_IO_SEEK_CUR ? s.cursor : whence == SDL_IO_SEEK_END ? Sint64(s.bytes.size()) : 0);
    if (next < 0 || next > Sint64(s.bytes.size())) return -1;
    return s.cursor = next;
}
static size_t SDLCALL read(void* ptr,void* data,size_t bytes,SDL_IOStatus* status) {
    auto& s = *static_cast<Stream*>(ptr);
    const auto count = std::min(bytes,s.bytes.size()-size_t(s.cursor));
    if (count) std::memcpy(data,s.bytes.data()+s.cursor,count);
    s.cursor += count;
    *status = count ? SDL_IO_STATUS_READY : SDL_IO_STATUS_EOF;
    return count;
}
static bool SDLCALL close(void* ptr) { ++static_cast<Stream*>(ptr)->closes; return true; }
static bool run() {
    using namespace das;
    TextPrinter out; ModuleGroup modules;
    auto program = compileDaScript(DASSDL3_TTF_IO_SCRIPT,make_smart<FsFileAccess>(),out,modules);
    if (program->failed()) {
        for (auto& e : program->errors) out << reportError(e.at,e.what,e.extra,e.fixme,e.cerr);
        return false;
    }
    Context context(program->getContextStackSize());
    if (!program->simulate(context,out)) return false;
    auto open = context.findFunction("open_font");
    auto dispose = context.findFunction("dispose_font");
    if (!open || !dispose) return false;
    for (bool valid : {false,true}) for (bool closeio : {false,true}) {
        size_t count = 0;
        auto data = static_cast<unsigned char*>(SDL_LoadFile(DASSDL3_TTF_FONT,&count));
        if (!data) return false;
        Stream stream;
        if (valid) stream.bytes.assign(data,data+count);
        else stream.bytes = {'b','a','d'};
        SDL_free(data);
        SDL_IOStreamInterface api;
        SDL_INIT_INTERFACE(&api);
        api.size=size; api.seek=seek; api.read=read; api.close=close;
        auto io=SDL_OpenIO(&api,&stream);
        if (!io) return false;
        vec4f args[] = {cast<SDL_IOStream*>::from(io),cast<bool>::from(closeio)};
        auto font=cast<TTF_Font*>::to(context.evalWithCatch(open,args));
        // Successful OpenFontIO retains the stream, even with closeio=true.
        bool passed=!context.getException() && bool(font)==valid && stream.closes==int(!valid && closeio);
        if (font) {
            vec4f fontArgs[] = {cast<TTF_Font*>::from(font)};
            passed=cast<bool>::to(context.evalWithCatch(dispose,fontArgs)) && !context.getException() && passed;
        }
        passed=stream.closes==int(closeio) && passed;
        if (!closeio) passed=SDL_CloseIO(io) && passed;
        if (!passed || stream.closes!=1) {
            std::cerr << "font IO lifetime mismatch: valid=" << valid << " closeio=" << closeio << '\n';
            return false;
        }
    }
    return true;
}
int main() {
    SDL_SetMainReady();
    if (!TTF_Init()) return 1;
    das::setDasRoot(DASSDL3_DAS_ROOT);
    NEED_ALL_DEFAULT_MODULES; NEED_MODULE(Module_dasSDL3); NEED_MODULE(Module_sdl3_ttf);
    das::Module::Initialize();
    const bool passed=run();
    das::Module::Shutdown(); TTF_Quit(); SDL_Quit();
    std::cout << "SDL_ttf: four raw retained-IO cases " << (passed ? "PASS" : "FAIL") << '\n';
    return passed ? 0 : 1;
}
