#include "libraries/sound.h"
#include <cstdio>
#include <cmath>
#include <algorithm>
#define CHECK(x) do {if(!(x)) {std::fprintf(stderr,"Failed: %s\n",#x);return 1;}} while(0)
struct Input { SDL_IOStream* inner; int closes=0;size_t limit=0; };
static Sint64 SDLCALL size(void* p) { return SDL_GetIOSize(static_cast<Input*>(p)->inner); }
static Sint64 SDLCALL seek(void* p,Sint64 n,SDL_IOWhence w) { return SDL_SeekIO(static_cast<Input*>(p)->inner,n,w); }
static size_t SDLCALL read(void* p,void* data,size_t n,SDL_IOStatus* status) {
    auto in=static_cast<Input*>(p);if(in->limit) n=std::min(n,in->limit);
    auto io=in->inner; auto got=SDL_ReadIO(io,data,n);*status=SDL_GetIOStatus(io);return got;
}
static bool SDLCALL close(void* p) {auto in=static_cast<Input*>(p);++in->closes;return SDL_CloseIO(in->inner);}
static SDL_IOStream* input(Input& in) {
    in.inner=SDL_IOFromFile(DASSDL3_SOUND_WAV,"rb");
    SDL_IOStreamInterface f;SDL_INIT_INTERFACE(&f);f.size=size;f.seek=seek;f.read=read;f.close=close;
    return in.inner ? SDL_OpenIO(&f,&in) : nullptr;
}
int main() {
    CHECK(Sound_Init());
    Input in{}; auto io=input(in);CHECK(io);
    auto sample=Sound_NewSample(io,"WAV",nullptr,1024);CHECK(sample);
    CHECK(in.closes==0);
    in.limit=64; CHECK(Sound_Decode(sample)==64);
    CHECK((sample->flags&SOUND_SAMPLEFLAG_EAGAIN)!=0 && (sample->flags&SOUND_SAMPLEFLAG_EOF)==0);
    in.limit=0;CHECK(Sound_Rewind(sample));
    SDL_AudioSpec floating{SDL_AUDIO_F32,1,48000};
    CHECK(Sound_SetDesiredFormat(sample,&floating));
    CHECK(Sound_DecodeAll(sample)==4800*sizeof(float));
    auto pcm=static_cast<const float*>(sample->buffer);
    for(int i=0;i<4800;++i) {
        auto expected=static_cast<int>(2500.0*std::sin(i*2.0*3.141592653589793*440.0/48000.0))/32768.0f;
        CHECK(std::abs(pcm[i]-expected)<0.00004f);
    }
    Sound_FreeSample(sample);CHECK(in.closes==1);
    Input retained{};auto rio=input(retained);CHECK(rio);
    CHECK(Sound_NewSample(rio,"WAV",nullptr,1024));
    CHECK(Sound_Quit());CHECK(retained.closes==1);
    // Before initialization, NewSample rejects without consuming the stream.
    Input rejected{};auto bad=input(rejected);CHECK(bad);
    CHECK(!Sound_NewSample(bad,"WAV",nullptr,1024));CHECK(rejected.closes==0);
    CHECK(SDL_CloseIO(bad));CHECK(rejected.closes==1);
    SDL_Quit();std::puts("SDL_sound IO and session ownership: PASS");return 0;
}
