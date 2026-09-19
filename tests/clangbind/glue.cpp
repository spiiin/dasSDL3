#include "daScript/daScript.h"
#include "dasSDL3Probe.h"
#include "probe_aot.h"
#include <SDL3/SDL.h>
#include <cstddef>
static_assert(sizeof(SDL_FRect)==16 && alignof(SDL_FRect)==4);
static_assert(offsetof(SDL_FRect,w)==8);
static_assert(sizeof(SDL_GPUViewport)==24 && offsetof(SDL_GPUViewport,min_depth)==16);
static_assert(SDL_PIXELFORMAT_RGBA8888==0x16462004u);
static_assert(sizeof(SDL_GUID) == 16 && alignof(SDL_GUID) == 1);
static_assert(sizeof(SDL_GPUVertexBufferDescription) == 16);
static_assert(offsetof(SDL_GPUVertexBufferDescription, input_rate) == 8);
static_assert(sizeof(SDL_GPUVertexInputState) == 32 && alignof(SDL_GPUVertexInputState) == 8);
static_assert(offsetof(SDL_GPUVertexInputState, vertex_attributes) == 16);
namespace das {
// Test fixture only: desc must outlive input. No production API is added.
void probe_set_vertex_buffer(SDL_GPUVertexInputState &input, const SDL_GPUVertexBufferDescription &desc) {
 input.vertex_buffer_descriptions=&desc; input.num_vertex_buffers=1;
}
void Module_dasSDL3Probe::initMain() {
 makeExtern<void(*)(SDL_GPUVertexInputState &,const SDL_GPUVertexBufferDescription &),probe_set_vertex_buffer,SimNode_ExtFuncCall>(lib,"probe_set_vertex_buffer","das::probe_set_vertex_buffer")->args({"input","desc"})->addToModule(*this,SideEffects::worstDefault);
 verifyAotReady();
}
ModuleAotType Module_dasSDL3Probe::aotRequire(TextWriter &tw) const {
 tw << "#include \"probe_aot.h\"\n";
 return ModuleAotType::cpp;
}
}
